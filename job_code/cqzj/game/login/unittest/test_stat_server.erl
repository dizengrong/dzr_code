%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_hook_register
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------

-module(test_stat_server).

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

test_stat(RoleID)->
    DataRecord = #m_stat_button_tos{use_type=1,btn_key=1},
    Info = {1, ?STAT, ?STAT_BUTTON, DataRecord, RoleID, 1, 1},
    global:send(mgeel_stat_server, Info).


test_send(RoleID)->
    R2 = #m_stat_config_toc{is_open=true},
    common_misc:unicast(1,RoleID,?DEFAULT_UNIQUE,?STAT,?STAT_CONFIG,R2).

