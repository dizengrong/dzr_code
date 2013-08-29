%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_mod_activity
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------

-module(test_mod_newcomer).

%%
%% Include files
%%
 
 
-define( INFO(F,D),io:format(F, D) ).
-compile(export_all).
-include("common.hrl").

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%


test_activate_code(Code)->
    DataIn = #m_newcomer_activate_code_tos{code=Code},
    RoleID = 1,
    Msg = {0,?NEWCOMER,?NEWCOMER_ACTIVATE_CODE,DataIn,RoleID,pid,1},
    mgeer_role:absend(1,Msg),
    ok.