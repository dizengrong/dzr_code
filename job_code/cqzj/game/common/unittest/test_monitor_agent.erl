%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_monitor_agent
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------

-module(test_monitor_agent).

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

test_get_monitor_db_list()->
    os:cmd("/root/mysql_processlist  | grep -v root | wc -l").

test_get_monitor_sys_list()->
    ok.
test_get_moniotr_map_list()->
    ok.
test_get_moniotr_bc_list()->
    ok.