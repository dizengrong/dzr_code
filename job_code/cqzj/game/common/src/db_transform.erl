-module(db_transform).
-export([do/3, do/4]).

do(Tab, Fun, NewAttrList, NewRecordName) -> 
	io:format("~n==========================~n"),
	Node = node(),
	IsRunning = mnesia:system_info(is_running),
	if
		IsRunning =:= no ->
			io:format("FALSE--Tab:~w Node:~w--> Mnesia not running in this node~n", [Tab, Node]),
			ignore;
		true ->
			Loaded = mnesia:table_info(Tab, load_node),
			if
				Loaded =/= unknown ->
					io:format("TRUE---Tab:~w Node:~w~n", [Tab, Node]),
					{atomic, ok} = mnesia:transform_table(Tab, Fun, NewAttrList, NewRecordName);
				true ->
					io:format("FALSE--Tab:~w Node:~w--> not loaded the table~n", [Tab, Node]),
					ignore
			end
	end.
	
do(Tab, Fun, NewAttrList) ->
	io:format("~n==========================~n"),
	Node = node(),
	IsRunning = mnesia:system_info(is_running),
	if
		IsRunning =:= no ->
			io:format("FALSE--Tab:~w Node:~w--> Mnesia not running in this node~n", [Tab, Node]),
			ignore;
		true ->
			Loaded = mnesia:table_info(Tab, load_node),
			if
				Loaded =/= unknown ->
					io:format("TRUE---Tab:~w Node:~w~n", [Tab, Node]),
					{atomic, ok} = mnesia:transform_table(Tab, Fun, NewAttrList);
				true ->
					io:format("FALSE--Tab:~w Node:~w--> not loaded the table~n", [Tab, Node]),
					ignore
			end
	end.