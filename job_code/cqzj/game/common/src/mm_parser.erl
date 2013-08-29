%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mm_parser).

%%
%% Include files
%%

%%
%% Include files
%%
 
-compile(export_all).
-include("mm_parse_list.hrl").
-include("common_server.hrl").
-include("mm_define.hrl").

%%
%% API Functions
%%
-define (MM_PARSER, true).

-ifdef(MM_PARSER).
%%开发阶段使用，可以打开下面的注释，已方便调试
parse(_Mod,?SYSTEM_HEARTBEAT,_Rec)->
    ignore;
parse(_Mod,?MONSTER_WALK,_Rec)->
    ignore;
parse(_Mod,?ROLE2_ATTR_CHANGE,_Rec)->
    ignore;
parse(_Mod,?MAP_UPDATE_ACTOR_MAPINFO,_Rec)->
    ignore;
parse(_Mod,?TEAM_AUTO_LIST,_Rec)->
    ignore;
parse(?MOVE,_Method,_Rec)->
    ignore;
parse(_Mod,?ROLE2_ADD_EXP,_Rec)->
    ignore;
parse(_Mod,?ROLE2_HP,_Rec)->
    ignore;    
    
parse(Mod,Method,Rec)->
    {StrMod,StrMethod} = get_mm(Mod,Method),
    ?ERROR_MSG("[~w] - [~w],Rec=~w",[StrMod,StrMethod,Rec]).
-else.
parse(_Mod,_Method,_Rec)->
	ignore.
-endif.

get_mm(Mod,Method)-> 
    case Mod of
        -1 -> StrMod = toc;
        _ ->
            case lists:keyfind(Mod, 1, ?MM_PARSE_LIST) of
                {_,StrMod}->
                    ok;
                _ ->
                    StrMod = unKnownModule
            end
    end,
    case lists:keyfind(Method, 1, ?MM_PARSE_LIST) of
        {_,StrMethod}->
            ok;
        _ ->
            StrMethod = unKnownMethod
    end,
    {StrMod,StrMethod}.
    
    
    
    