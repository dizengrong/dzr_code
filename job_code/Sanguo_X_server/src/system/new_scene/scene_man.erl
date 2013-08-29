-module(scene_man).
-include("common.hrl").

-export([init_scene/0, init_player_position/1]).
-export([start_test/0, avl_test/0, avl_test_1/2, avl_test_2/1, avl_test_1/0, avl_test_2/0]).
-export([test_mask/1]).

-define(SPECIAL_MAPS, [?INIT_MAP]).
-define(ETS_ROOM_INDEX, ets_room_index).

%% module: scene_manager 
%% unlike module scene, this module can directly modify the scene data structure
%% and will do some global initialization and disposition

%====================================================================================
% init function
%====================================================================================
 
%% initialize scene info when player create an account
init_player_position(ID) ->
	{X, Y} = data_scene:get_default_xy(?INIT_MAP),
	Position = 
		#position {
			gd_accountID = ID,
			scene        = ?INIT_MAP, 
			x            = X,
			y            = Y, 
			access_map   = data_scene:get_init_access()
		},
	gen_cache:insert(?SCENE_CACHE_REF, Position),
	Position.

init_scene() ->
	%% ets_scene_info records the basic information of all the scene.
	%% the entry in this table is #scene_info
	ets:new(?ETS_SCENE_INFO, [public, named_table, set, {keypos, #scene_info.scene_id}]),
	ets:new(?ETS_MASK_INFO,  [public, named_table, set]),
	ets:new(?ETS_SCENE_ROOM, [public, named_table, set, {keypos, #scene_room.id}]),
	SceneList = data_scene:get_id_list(),	
	init_scene_table(SceneList).

init_scene_table([SceneID | Rest]) ->
	_SceneInfo = #scene {row = R, column = C, type = T} = data_scene:get(SceneID),
	SceneSpec  = [public, named_table, set, 
				 {keypos, #player_cell.player_id},
				 {write_concurrency, true}, 
				 {read_concurrency, true}], 

	%% here, we divide the map into logical grids, named cell
	%% cell is used for the vision handling
	%% see the following graph

	%=======|=======|=======|=========%
	% Cell1 | Cell2 | ***** | CellCol %
	%=======|=======|=======|=========%
	% C + 1 | C + 2 | ***** |  2 * C  %
	%=======|=======|=======|=========%
	% ***** | ***** | ***** |  *****  %
	%=======|=======|=======|=========%
	%(R-1)C+1 ***** | ***** |  R * C  %
	%=======|=======|=======|=========%

	CellRow = (R + ?CELL_HEIGHT - 1) div ?CELL_HEIGHT, %% ceil(R / ?CELL_HEIGHT)
	CellCol = (C + ?CELL_WIDTH  - 1) div ?CELL_WIDTH,  %% ceil(R / ?CELL_HEIGHT)

	ets:insert(?ETS_SCENE_INFO,
		#scene_info {scene_id = SceneID, cellcols = CellCol, cellrows = CellRow, 
			cols = C, rows = R, type = T}),

	case lists:member(SceneID, ?SPECIAL_MAPS) of %% there're no special scene here
		false ->
			%% normal map has the name map_xxxx
			SceneTab = erlang:list_to_atom("map_" ++ erlang:integer_to_list(SceneID)),
			ets:new(SceneTab, SceneSpec);
		true ->
			%% special map is a virtual room: it means there are more logicals scenes used a common sceneid  
			%% we put a num after the scene id to specified this virtual room  
			%% special map has the name map_xxxx_y
			Num = 20,
			F = fun(N) ->
					SceneTab = erlang:list_to_atom("map_" ++ 
					   		   erlang:integer_to_list(SceneID) ++ "_" ++
					   		   erlang:integer_to_list(N)),
					ets:new(SceneTab, SceneSpec)
				end,
			lists:foreach(F, lists:seq(1, Num))
	end,
	MaskTuple = list_to_tuple([SceneID | data_mask:get(SceneID)]),
	ets:insert(?ETS_MASK_INFO, MaskTuple),
	init_scene_table(Rest);

init_scene_table([]) -> ok.

%===========================================================================================================
%  performance test code 
% (1) using AVL tree to do the section seaching
% (2) using Hash Table to do the table seaching
% when the table is more larger, then more efficient 
%===========================================================================================================

-define(test_time, 100000).

%% which is faster?
start_test() ->
	ets:new(hash, [public, named_table, set]),
	ets:new(avl, [public, named_table, ordered_set]),
	
	lists:foreach(fun(N) -> ets:insert(hash, {N, data}) end, lists:seq(1, 1000)),
	lists:foreach(fun(N) -> ets:insert(avl,  {{1900, N}, data}) end, lists:seq(1, 1000)),

	hash_test(),
	avl_test().

%% is next faster than lookup when traversing?
avl_test() ->
	io:format("testing avl================================================~n"),
	T1 = util:longunixtime(),
	%% run 1 Million times
	lists:foreach(fun(_) -> avl_test_1() end, lists:seq(1, ?test_time)),
	T2  = util:longunixtime(),
	io:format("using time ~w msecs~n", [T2 - T1]).
	
%% 	T3 = util:unixtime(),
%% 	lists:foreach(fun(_) -> avl_test_2() end, lists:seq(1, ?test_time)),
%% 	T4 = util:unixtime(),
%% 	io:format("using time ~w secs~n", [T4 - T3]).


avl_test_1() ->
	List = avl_test_1({1900, 50}, []),
	lists:foreach(fun(N) -> ets:lookup(hash, N) end, List).

avl_test_1({1900, Key}, List) ->
	case ets:next(avl, {1900, Key}) of
		'$end_of_table' -> ok;
		{1900, NKey} ->
			if (NKey =< 80) ->
				avl_test_1({1900, NKey}, [NKey | List]);
			true ->
				List
			end
	end.

avl_test_2() ->
	avl_test_2({1900,1}).

avl_test_2(K = {1900, Key}) ->
    case ets:lookup(avl, K) of
		[] -> ok;
		_ -> avl_test_2({1900, Key + 1})
	end.

hash_test() ->
	io:format("testing hash================================================~n"),
	T1 = util:longunixtime(),
	lists:foreach(fun(_) -> hash_test_1() end, lists:seq(1, ?test_time)),
	T2 = util:longunixtime(),
	io:format("using time ~w msecs~n", [T2 - T1]).

%% 	T3 = util:unixtime(),
%% 	lists:foreach(fun(_) -> hash_test_2() end, lists:seq(1, ?test_time)),
%% 	T4 = util:unixtime(),
%% 	io:format("using time ~w secs~n", [T4 - T3]).
	

hash_test_1() ->
	[{Key, _}] = ets:lookup(hash, 1),
	hash_test_1(Key).

hash_test_1(Key) ->
	case ets:next(hash, Key) of
		'$end_of_table' -> ok;
		NKey -> 
			hash_test_1(NKey)
	end.

hash_test_2() ->
	hash_test_2(1).

hash_test_2(Key) ->
    case ets:lookup(hash, Key) of
		[] -> ok;
		_ -> hash_test_2(Key + 1)
	end.

%==================================================================================================
% mask test
%==================================================================================================

test_mask(SceneID) ->
	io:format("test mask================================================~n"),
	T1 = util:longunixtime(),
	lists:foreach(fun(_) -> scene:can_move(SceneID, 0, 0) end, lists:seq(1, 1000000)),
	T2 = util:longunixtime(),
	io:format("using time ~w msecs~n", [T2 - T1]),
	
	T3 = util:longunixtime(),
	lists:foreach(fun(_) -> ets:lookup_element(?ETS_MASK_INFO, SceneID, 2) end, lists:seq(1, 1000000)),
	T4 = util:longunixtime(),
	io:format("using time ~w msecs~n", [T4 - T3]).












