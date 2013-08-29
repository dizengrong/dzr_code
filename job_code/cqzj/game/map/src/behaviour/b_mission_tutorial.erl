%%% -------------------------------------------------------------------
%%% Author  : xiaosheng
%%% Description :新手任务特殊模块 Behaviour
%%%
%%% Created : 2011-01-22
%%% -------------------------------------------------------------------
-module(b_mission_tutorial).
-include("mission.hrl").  

-export([behaviour_info/1]).
behaviour_info(callbacks) ->
    [{do, 3},
	 {api, 1},
	 {tutorial_complete, 1}];
behaviour_info(_Other) ->
    undefined.