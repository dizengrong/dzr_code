%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     gm_service的单元测试
%%% @end
%%% Created : 2010-11-17
%%%-------------------------------------------------------------------
-module(test_gm_service).

%% --------------------------------------------------------------------
%% include_once files
%% --------------------------------------------------------------------
-define( INFO(F,D),io:format(F, D) ).
-compile(export_all).
-include("mgeeweb.hrl").


%%
%% Exported Functions
%%
-export([]).


%% ====================================================================
%% API Functions
%% ====================================================================

t_reply(ReplyId)->
    RoleId = 1,
    Content = "wuzen test",
    mod_gm_service:reply_letter(ReplyId,RoleId,Content).


t_role(AccountName,RoleName)->
    FactionID = 1,
    Sex = 1,
    mod_gm_service:create_gm_role(AccountName,RoleName,FactionID,Sex).

t_ban()->
    List = mod_chat_ban:list_user(),
    JSonList = [ mod_tool:transfer_to_json(Rec) ||Rec<-List ],
    JSonList.



