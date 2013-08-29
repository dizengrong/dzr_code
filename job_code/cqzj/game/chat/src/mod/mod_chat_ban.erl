%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     实现禁言的功能
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mod_chat_ban).


%% API
-export([ban_by_gm/4,ban_by_king/5,unban/1,list_user/0,auth_ban/1]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeec.hrl").

%%封禁类型(0:GM/神眼/后台;1国王/皇帝
-define(BAN_TYPE_GM,0).
-define(BAN_TYPE_KING,1).


%% ====================================================================
%% API Functions
%% ====================================================================

%%@doc 获取封禁玩家的列表
list_user()->
    Pattern = #r_ban_chat_user{_='_'},
    List = db:dirty_match_object(?DB_BAN_CHAT_USER,Pattern),
    List.

%%@doc 判断是否被封禁,true表示合法，{false,Message}表示禁言及其原因
auth_ban(RoleId)->
    Pattern = #r_ban_chat_user{role_id=RoleId,_='_'},
    case db:dirty_match_object(?DB_BAN_CHAT_USER,Pattern) of
        []-> true;
        [Record] -> 
            #r_ban_chat_user{time_end=TimeEnd} = Record,
            Now = common_tool:now(),
            case Now>TimeEnd of
                true->
                    true;
                false->
                    StrTimeEnd = common_tool:seconds_to_datetime_string(TimeEnd),
                    Msg = common_misc:format_lang(?_LANG_CHAT_ROLE_BANNED_ENDTIME,[StrTimeEnd]),
                    {false,Msg}
            end
    end.

%%@doc GM封禁玩家
%%@param  RoleId::integer()
%%@param  RoleName::string()
%%@param  Duration::integer(),封禁的时长,单位 分钟
%%@param  Reason::string()
ban_by_gm(RoleId,RoleName,Duration,Reason)->
    Type = ?BAN_TYPE_GM,
    ban(RoleId,RoleName,Duration,Reason,Type),
    common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT, ?BC_MSG_TYPE_CHAT_WORLD, Reason).

%%@doc 国王封禁玩家
ban_by_king(RoleId,RoleName,Duration,Reason,KingID)->
    case catch can_king_ban(KingID) of
        {true,RTimes} ->
            Type = ?BAN_TYPE_KING,
            ban(RoleId,RoleName,Duration,Reason,Type),
            Msg = common_misc:format_lang(?_LANG_CHAT_KING_BAN_BROADMSG,[RoleName,Duration]),
            {ok,Msg,RTimes};
        {false,ReasonMsg} ->
            {false,ReasonMsg};
        _Other ->
            {error,?_LANG_SYSTEM_ERROR}
    end.
   

%%@param  Duration::integer(),封禁的时长,单位 分钟
ban(RoleId,RoleName,Duration,Reason,Type)->
    TimeStart = common_tool:now(),
    TimeEnd = TimeStart+Duration*60,
    Record = #r_ban_chat_user{role_id=RoleId,role_name=RoleName,time_start=TimeStart,time_end=TimeEnd,
                                duration=Duration, reason=Reason,type=Type},
    db:dirty_write(?DB_BAN_CHAT_USER, Record).

%%@doc 解封
unban(RoleId)->
    db:dirty_delete(?DB_BAN_CHAT_USER, RoleId).

%%

can_king_ban(RoleID) ->
    case db:transaction(fun() -> gettime_byid(RoleID) end) of
        {atomic,NewIndex} ->
            if NewIndex<10 ->
                    {true,10-NewIndex};
               true ->
                    {false,?_LANG_CHAT_KING_BAN_COUNTS}
            end;        
        {aborted, _Error} ->
             {error,?_LANG_SYSTEM_ERROR}
    end.

gettime_byid(RoleID) ->
   {DateToday, _} = erlang:localtime(),
   case db:read(?DB_BAN_CONFIG_P,#bankey{type=?BAN_TYPE_KING,roleid=RoleID},read) of
         [] ->
 	    	Record = #r_ban_config{ban_key=#bankey{type=?BAN_TYPE_KING,roleid=RoleID},ban_times=1, todays=DateToday},
                db:write(?DB_BAN_CONFIG_P, Record,write),
 	        1;
         [#r_ban_config{todays=Date} = R] ->	
 		case DateToday =:= Date of
 			true ->
 				NewRecord = R#r_ban_config{ban_times = R#r_ban_config.ban_times + 1};
 			false ->
 				NewRecord = R#r_ban_config{ban_times=0, todays=DateToday}
 		end,
                 db:write(?DB_BAN_CONFIG_P, NewRecord, write),
                 NewRecord#r_ban_config.ban_times
     end.


