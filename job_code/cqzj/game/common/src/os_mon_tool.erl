%% Author: xierongfeng
%% Created: 2013-3-15
%% Description:系统监测工具 
-module(os_mon_tool).

%%
%% Include files
%%
-include("common.hrl").

%%
%% Exported Functions
%%
-export([start/0, stop/0, init/1, handle_event/2, terminate/2]).

%%
%% API Functions
%%
start() ->
	application:start(os_mon),
	memsup:set_procmem_high_watermark(0.05),
	alarm_handler:add_alarm_handler(?MODULE).

stop() ->
	alarm_handler:delete_alarm_handler(?MODULE),
	application:stop(os_mon).

init([]) ->
	{ok, state}.

handle_event({set_alarm, {process_memory_high_watermark, Pid}}, State) ->
	spawn(fun() ->
		ProcessInfo = erlang:process_info(Pid),
		?ERROR_LOG("pid ~p use too much memory,~nprocess info: ~p", [Pid, ProcessInfo]),
		{dictionary, Dict} = lists:keyfind(dictionary,1,ProcessInfo),
		case lists:keyfind('$initial_call', 1, Dict) of
			{_, [mgeer_role|_]} ->
				lists:foreach(fun({K, V}) -> put(K, V) end, Dict),
				mod_map_role:persistent_role_detail(get(role_id)),
				erlang:exit(Pid, 'too much memory');
			_ ->
				ignore
		end
	end),
	{ok, State};
handle_event(_Event, State) ->
	{ok, State}.

terminate(_Arg, State) ->
	{ok, State}.

%%
%% Local Functions
%%

