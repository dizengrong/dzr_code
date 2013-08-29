-module (mod_counter).

-include ("common.hrl").

-export ([get_counter/2, add_counter/2, add_counter/3,get_counter/3]).

-export([insert_counter_rec/2]).

%% -define(COUNTER_CACHE_REF, cache_util:get_register_name(counter)).

%% 参数Type为预定义好的计数类型，位于头文件counter.hrl中
-spec get_counter(player_id(), integer()) -> any().
get_counter(PlayerId, Type) ->
	case gen_cache:lookup(?COUNTER_CACHE_REF, {PlayerId, Type}) of
		[] -> 
			insert_counter_rec(PlayerId, Type),
			0;
		[T | _] -> 
			T1 = reset_if_other_day(T),
			T1#counter.gd_counter
	end.

get_counter(Id, Type, NType) ->
	?INFO(mod_counter,"Id, Type, NType:~w",[[Id, Type, NType]]),
	case gen_cache:lookup(?COUNTER_CACHE_REF, {Id, Type}) of
		[] -> 
			insert_counter_rec(Id, Type),
			0;
		[T | _] -> 
			T1 = reset_if_other_day(T, NType),
			T1#counter.gd_counter
	end.


%% 参数Type为预定义好的计数类型，位于头文件counter.hrl中
-spec add_counter(player_id(), integer()) -> any().
add_counter(PlayerId, Type) ->
	add_counter(PlayerId, Type, 1).

add_counter(PlayerId, Type, Times) ->
	%% 调用这个方法是确保数据库已有该type的计数器，并且确保次数能被重置
	get_counter(PlayerId, Type),
	gen_cache:update_counter(?COUNTER_CACHE_REF, {PlayerId, Type}, {#counter.gd_counter, Times}).

% gen_cache_lookup_cb(_IsFromDb, _Mapper, _Key, CounterRecList) ->
% 	case CounterRecList of
% 		[] -> false;
% 		_ ->
% 			NewCounterRecList = reset_if_other_day(CounterRecList, []),
% 			{true, NewCounterRecList}
% 	end.

reset_if_other_day(CounterRec) ->
	case util:check_other_day(CounterRec#counter.gd_updateTime) of
		false -> CounterRec1 = CounterRec;
		true ->
			CounterRec1 = #counter{
				key           = CounterRec#counter.key,
				gd_updateTime = util:unixtime()
			},
			gen_cache:update_record(?COUNTER_CACHE_REF, CounterRec1)
	end,
	CounterRec1.

reset_if_other_day(CounterRec, NType) ->
	?INFO(mod_counter,"CounterRec:~w, NType:~w",[CounterRec, NType]),
	case util:check_other_day(CounterRec#counter.gd_updateTime, NType) of
		false -> CounterRec1 = CounterRec;
		true ->
			CounterRec1 = #counter{
				key           = CounterRec#counter.key,
				gd_updateTime = util:unixtime()
			},
			gen_cache:update_record(?COUNTER_CACHE_REF, CounterRec1)
	end,
	CounterRec1.

insert_counter_rec(PlayerId, Type) ->
	CounterRec = #counter{
		key           = {PlayerId, Type},
		gd_updateTime = util:unixtime()
	},
	gen_cache:insert(?COUNTER_CACHE_REF, CounterRec).