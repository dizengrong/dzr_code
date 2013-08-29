%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     GM的相关逻辑处理
%%% @end
%%% Created : 2010-11-17
%%%-------------------------------------------------------------------
-module(mod_gm_service).


%% --------------------------------------------------------------------
%% include_once files
%% --------------------------------------------------------------------
-include("mgeeweb.hrl").



%%
%% Exported Functions
%%
-export([reply_letter/3,create_gm_role/4]).
-export([handle/2]).
-export([]).


%% ====================================================================
%% API Functions
%% ====================================================================

handle(create_gm_role,QueryString)->
    AccountName = proplists:get_value("accname", QueryString),
    RoleName = proplists:get_value("rolename", QueryString),
    FactionID = mgeeweb_tool:get_int_param("faction", QueryString),
    Sex = mgeeweb_tool:get_int_param("sex", QueryString),
    create_gm_role(AccountName,RoleName,FactionID,Sex).

%%@doc GM回复玩家的投诉
reply_letter(ReplyId,RoleID,Content)->
    common_letter:send_letter_package({gm_reply_letter,ReplyId,RoleID,Content,[]}).

%%@doc 后台创建GM的角色
create_gm_role(AccountName,RoleName,FactionID,Sex)->
    case global:whereis_name(mgeel_gm_server) of
        undefined -> 
            {error,?_LANG_SYSTEM_ERROR};
        Pid ->
            try
                HeadID = Sex,   %% set the HeadID
                             
                Rec = gen_server:call(Pid, {create_gm_role,{AccountName,RoleName,FactionID,Sex,HeadID}}),
                #m_role_add_toc{succ=Succ,reason=Reason} = Rec,
                case Succ of
                    true-> ok;
                    false-> {error,Reason}
                end
            catch
                _:ExpReason->
                    ?ERROR_MSG("后台创建GM的角色失败，Reason=~w",[ExpReason]),
                    {error,common_tool:to_list(ExpReason)}
            end
            
    end. 


