%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_cmm_activity).

%%
%% Include files
%%
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

test()->
    R1 = common_activity:get_activity_config(100001),
    ?INFO("R1=~w~n",[R1]),
    R2 = common_activity:get_activity_config(100002),
    ?INFO("R2=~w~n",[R2]),
    R3 = common_activity:get_activity_config(100003),
    ?INFO("R3=~w~n",[R3]),
    R4 = common_activity:get_activity_config(100004),
    ?INFO("R4=~w~n",[R4]),
    R5 = common_activity:get_activity_config(100005),
    ?INFO("R5=~w~n",[R5]),
    R6 = common_activity:get_activity_config(100006),
    ?INFO("R6=~w~n",[R6]),
    R11 = common_activity:get_activity_config_list(100011),
    ?INFO("R11=~w~n",[R11]),
    ok.

