%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     json工具模块,使用mochijson2模块
%%% @end
%%% Created : 2010-11-19
%%%-------------------------------------------------------------------
-module(common_json2).

-define(STRUCT,struct).
-export([to_json/1,convert_to_struct/1]).

%% @doc主调用方法tuple -> json
%% @spec to_json(V::tuple())-> string() 
to_json(V) -> json_encode(prepare_for_json(V)).

convert_to_struct(RawData) ->
  lists:map(fun({BinKey, BinVal}) ->
      Key = common_tool:to_atom(BinKey),
      Val = common_tool:to_list(BinVal),
      {Key, Val}
    end, RawData).

prepare_for_json(Int) when is_integer(Int) -> Int;
prepare_for_json(Float) when is_float(Float) -> Float;
prepare_for_json(Atom) when is_atom(Atom) -> Atom;
prepare_for_json(Array) when is_list(Array) -> 
    %% case io_lib:printable_list(Array) of
	case io_lib:char_list(Array) of
		true ->
			erlang:list_to_binary(Array);
		false ->
			list_to_json(Array, [])
	end;
prepare_for_json(Tuple) when is_tuple(Tuple) -> 
	tuple_to_json(Tuple, erlang:size(Tuple), []);
prepare_for_json(V) -> V.

list_to_json([], Acc) -> lists:reverse(Acc);
list_to_json([{_Key, _Value}|_Rest] = List, Acc) -> {?STRUCT, proplist_to_json(List, Acc)};
list_to_json([H|Rest], Acc) -> list_to_json(Rest, [prepare_for_json(H)|Acc]).

proplist_to_json([], Acc) -> lists:reverse(Acc);
proplist_to_json([{Key, Value}|Rest], Acc) ->
	ValidKey    = prepare_for_json(Key),
	ValidValue  = prepare_for_json(Value),
	proplist_to_json(Rest, [{ValidKey, ValidValue}|Acc]).

tuple_to_json(_Tuple, 0, Acc) ->  {?STRUCT, [erlang:list_to_tuple(Acc)]};
tuple_to_json(Tuple, CurrPos, Acc) ->
	Ele = prepare_for_json(element(CurrPos, Tuple)),
	tuple_to_json(Tuple, CurrPos - 1, [Ele|Acc]).

json_encode(Value) -> mochijson2:encode(Value).
