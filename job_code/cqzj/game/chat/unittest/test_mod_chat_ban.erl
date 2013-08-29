%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     mod_chat_ban的单元测试
%%% @end
%%% Created : 2010-11-17
%%%-------------------------------------------------------------------
-module(test_mod_chat_ban).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-define( INFO(F,D),io:format(F, D) ).
-compile(export_all).
-include("mgeec.hrl").


%%
%% Exported Functions
%%
-export([]).


%% ====================================================================
%% API Functions
%% ====================================================================

t_broadcast()->
    Reason = "abccc",
    common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT, ?BC_MSG_TYPE_CHAT_WORLD, Reason).

t_list()->
    mod_chat_ban:list_user().

t_ban(RoleId,RoleName)->
    Duration = 14,
    Reason = "wuzesen test",
    mod_chat_ban:ban_by_gm(RoleId,RoleName,Duration,Reason).

t_unban(RoleID)->
    mod_chat_ban:unban(RoleID).

t_is_banned(RoleID)->
    mod_chat_ban:auth_ban(RoleID).



