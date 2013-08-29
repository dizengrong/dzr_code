%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_mod_activity
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------

-module(test_mod_activity).

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

tf()->
    RoleID = 1,
    DataIn={m_fight_attack_tos,{p_map_tile,131,16},71109001,2,7,1,7},
    Msg = {0,?FIGHT,?FIGHT_ATTACK,DataIn,RoleID,pid,1},
    common_misc:send_to_rolemap(1,Msg).

    

test_suite()->
    ok = test_today(1),
    ok.

test_today(RoleID)->
    DataIn = #m_activity_today_tos{},
    Msg = {0,?ACTIVITY,?ACTIVITY_TODAY,DataIn,RoleID,pid,1},
    common_misc:send_to_rolemap(1,Msg),
    ok.

test_today2()->
    Msg = {32736,?ACTIVITY,?ACTIVITY_TODAY,undefined,2,pid,6001},
    common_misc:send_to_rolemap(1,Msg),
    ok.