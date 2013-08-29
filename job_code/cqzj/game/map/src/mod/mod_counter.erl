%% 计数器模块，用于记录每天需要重置的次数的统一处理
-module (mod_counter).
-include("mgeem.hrl").

-export ([get_counter/2, add_counter/2, add_counter/3]).
-export ([counter_init/2, counter_delete/1]).

counter_init(RoleID, RCounterRec) ->
	case RCounterRec of 
		false -> RCounterRec1 = #r_times_counter{update_time = common_tool:now()};
		_ 	  -> RCounterRec1 = RCounterRec
	end,
	set_role_counter_rec(RoleID, RCounterRec1).

counter_delete(RoleID) ->
	mod_role_tab:erase(RoleID, r_times_counter).

get_role_counter_rec(RoleID) ->
	RCounterRec = mod_role_tab:get(RoleID, r_times_counter),
	Now         = common_tool:now(),
	case common_tool:check_if_same_day(RCounterRec#r_times_counter.update_time, Now) of
		true -> 
			RCounterRec1 = RCounterRec;
		false -> 
			NewCounterList = reset_counter_list(RCounterRec#r_times_counter.counter_list),
			RCounterRec1 = RCounterRec#r_times_counter{update_time = Now, counter_list = NewCounterList},
			set_role_counter_rec(RoleID, RCounterRec1)
	end,
	RCounterRec1.

set_role_counter_rec(RoleID, RCounterRec) ->
	mod_role_tab:put(RoleID, r_times_counter, RCounterRec).

reset_counter_list(CounterList) ->
	[{CountType, 0} || {CountType, _Times} <- CounterList].
%% ============================================================================
%% ============================================================================
get_counter(RoleID, CountType) ->
	RCounterRec = get_role_counter_rec(RoleID),
	case lists:keyfind(CountType, 1, RCounterRec#r_times_counter.counter_list) of
		false ->
			insert_new_counter(RoleID, RCounterRec, CountType, 0),
			0;
		{_, Times} -> Times
	end.

add_counter(RoleID, CountType) ->
	add_counter(RoleID, CountType, 1).

add_counter(RoleID, CountType, AddTimes) ->
	RCounterRec = get_role_counter_rec(RoleID),
	case lists:keyfind(CountType, 1, RCounterRec#r_times_counter.counter_list) of
		false -> 
			insert_new_counter(RoleID, RCounterRec, CountType, AddTimes), 
			AddTimes;
		{_, Times} -> 
			insert_new_counter(RoleID, RCounterRec, CountType, AddTimes + Times),
			AddTimes + Times
	end.

insert_new_counter(RoleID, RCounterRec, CountType, Times) ->
	NewCounterList = lists:keystore(CountType, 1, RCounterRec#r_times_counter.counter_list,{CountType, Times}),
	RCounterRec1 = RCounterRec#r_times_counter{counter_list = NewCounterList},
	set_role_counter_rec(RoleID, RCounterRec1).
