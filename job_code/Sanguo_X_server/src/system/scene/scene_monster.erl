%% Author: dzr
%% Created: 2012-1-29
%% Description: 处理位于野外地图中的怪物的移动等操作
-module(scene_monster).

%%
%% Include files
%%
-include("common.hrl").
%%
%% Exported Functions
%%
-export([monster_move/2,
		 monster_enter/2,
		 monster_leave/2,
		 update_monster_state/2]).

-export([player_enter/3,
		 player_move_check/4]).

%%
%% API Functions
%%

%% ========================== Monster To Player ==============================
monster_move(_SceneId, []) -> ok;
monster_move(SceneId, [MonsterRec | Rest]) ->
	X0 = MonsterRec#monster.coord_x,
	Y0 = MonsterRec#monster.coord_y,
	{N, M, CellNum, _SceneType} = mod_scene:get_cell_info(SceneId, X0, Y0),
	TabName = mod_scene:get_scene_tab(0, SceneId, get),
	{ok, MoveMsg} = pt_11:write(11401, MonsterRec),
	%%?INFO(monster,"11401 bin is ~w",[MoveMsg]),
	broadcast_move_to_player({N, M, CellNum}, MoveMsg, TabName),
	case MonsterRec#monster.path of
		[] -> ok;
		Path ->
			monster_move_check({X0, Y0}, lists:last(Path), MonsterRec, SceneId, TabName)
	end,
	monster_move(SceneId, Rest),
	ok.

monster_move_check({X0, Y0}, {X1, Y1}, MonsterRec, SceneId, TabName) ->
	{N, M, OldCell, _SceneType} = mod_scene:get_cell_info(SceneId, X0, Y0),
	{_N, _M, NewCell, _SceneType} = mod_scene:get_cell_info(SceneId, X1, Y1),
	case scene_help:get_leave_and_enter_cells(OldCell, NewCell, N, M) of
		[] -> ok; %% in the same cell
		{LeaveCells, EnterCells} ->	 %% go to other cell
			monster_enter_help(MonsterRec, TabName, EnterCells),
			monster_leave_help(MonsterRec, TabName, LeaveCells)
	end.

monster_enter(_SceneId, []) -> ok;
monster_enter(SceneId, [MonsterRec | Rest]) ->
	X = MonsterRec#monster.coord_x,
	Y = MonsterRec#monster.coord_y,
	{N, M, CellNum, _SceneType} = mod_scene:get_cell_info(SceneId, X, Y),
	CellList = scene_help:get_move_broadcast_cell(CellNum, N, M),
	TabName = mod_scene:get_scene_tab(0, SceneId, get),
	monster_enter_help(MonsterRec, TabName, CellList),
%% 	{ok, EnterMsg} = pt_11:write(11400, [MonsterRec]),
%% 	[broadcast_monster_enter(Cell, EnterMsg, TabName) || Cell <- CellList],
	monster_enter(SceneId, Rest),
	ok.

monster_enter_help(MonsterRec, TabName, CellList) ->
	%%?INFO(monster,"monster rec is ~w",[MonsterRec]),
	{ok, EnterMsg} = pt_11:write(11400, [MonsterRec]),
	[broadcast_monster_enter(Cell, EnterMsg, TabName) || Cell <- CellList].
	

monster_leave(_SceneId, []) -> ok;
monster_leave(SceneId, [MonsterRec | Rest]) -> 
	X = MonsterRec#monster.coord_x,
	Y = MonsterRec#monster.coord_y,
	{N, M, CellNum, _SceneType} = mod_scene:get_cell_info(SceneId, X, Y),
	TabName = mod_scene:get_scene_tab(0, SceneId, get),
	CellList = scene_help:get_move_broadcast_cell(CellNum, N, M),
	monster_leave_help(MonsterRec, TabName, CellList),
%% 	{ok, LeaveMsg} = pt_11:write(11402, [MonsterRec#monster.id]),
%% 	[broadcast_monster_leave(Cell, LeaveMsg, TabName) || Cell <- CellList],
	monster_leave(SceneId, Rest),
	ok.
monster_leave_help(MonsterRec, TabName, CellList) ->
	{ok, LeaveMsg} = pt_11:write(11402, [MonsterRec#monster.id]),
	[broadcast_monster_leave(Cell, LeaveMsg, TabName) || Cell <- CellList].


update_monster_state(SceneId, MonsterRec) ->
	X = MonsterRec#monster.coord_x,
	Y = MonsterRec#monster.coord_y,
	{N, M, CellNum, _SceneType} = mod_scene:get_cell_info(SceneId, X, Y),
	TabName = mod_scene:get_scene_tab(0, SceneId, get),
	CellList = scene_help:get_move_broadcast_cell(CellNum, N, M),
	
	{ok, Packet} = pt_11:write(11403, MonsterRec),
	[broadcast_monster_state(Cell, Packet, TabName) || Cell <- CellList],
	case ets:match(TabName, #player_cell{player_id = '$1', _ = '_'}) of
		[] -> ok;
		Player_id ->
			scene_help:broadcast_monster_state(Player_id, Packet)
	end.
	
%% ============================= 华丽的分割线 ==================================


%% ========================== Player To Monster ==============================
player_enter(PlayerCell, SceneId, CellList) -> 
	?INFO(monster, "player_enter:"),
	broadcast_monster_enter2(PlayerCell, SceneId, CellList).

player_move_check(PlayerCell, LeaveCells, EnterCells, SceneId) -> 
	broadcast_monster_enter2(PlayerCell, SceneId, EnterCells),
	broadcast_monster_leave2(PlayerCell, SceneId, LeaveCells).
	
			

%%
%% Local Functions
%%
broadcast_move_to_player({C, R, CellNum}, MoveMsg, TabName) ->
	Fun = fun(Cell, Acc) ->
		case ets:match(TabName, #player_cell{cell = Cell,  player_id = '$1', _ = '_'}) of
			[] -> Acc;
			Matched -> lists:append(Acc, Matched)
		end
	end,
	CellList = scene_help:get_move_broadcast_cell(CellNum, C, R),
	Acc = lists:foldl(Fun, [], CellList),
	broadcast_move_help(Acc, MoveMsg).

broadcast_move_help([], _MoveMsg) -> ok;
broadcast_move_help([[Player_id] | Rest], MoveMsg) ->
	?INFO(monster,"player is ~w, rest ~w, move msg ~w",[Player_id,Rest,MoveMsg]),
	lib_send:send(Player_id, MoveMsg),
	broadcast_move_help(Rest, MoveMsg).

broadcast_monster_enter(Cell, EnterMsg, TabName) ->
	case ets:match_object(TabName, #player_cell{cell = Cell, _ = '_'}) of
		[] -> none;		
		Players ->
			Fun2 = fun(Sender) -> lib_send:send(Sender, EnterMsg) end,
			[Fun2(Player_id) || #player_cell{player_id = Player_id} <- Players]
	end.

broadcast_monster_enter2(PlayerCell, SceneId, CellList) ->
	case mod_monster:get_all_monster(SceneId) of
		[] -> ok;
		MonsterList ->
			FilterFun = fun(Monster) -> 
				X = Monster#monster.coord_x,
				Y = Monster#monster.coord_y,
				{_N, _M, CellNum, _SceneType} = mod_scene:get_cell_info(SceneId, X, Y),
				lists:member(CellNum, CellList) 
			end,
			MonsterList1 = lists:filter(FilterFun, MonsterList),
			?INFO(monster, "MonsterList1 is:~w", [MonsterList1]),
			case MonsterList1 of
				[] -> ok;
				_ ->
					{ok, MonstersPacket} = pt_11:write(11400, MonsterList1),
					?INFO(monster,"ready to send ~w for bin ~w", [PlayerCell#player_cell.player_id,MonstersPacket]),
					lib_send:send(PlayerCell#player_cell.player_id, MonstersPacket)
			end
	end.
	
broadcast_monster_leave(Cell, LeaveMsg, TabName) ->
	case ets:match(TabName, #player_cell{cell = Cell, player_id = '$1', _ = '_'}) of
		[] -> ok;
		Matched ->
			[lib_send:send(Sender_id, LeaveMsg) || [Sender_id] <- Matched]
	end.

broadcast_monster_leave2(PlayerCell, SceneId, CellList) ->
	case mod_monster:get_all_monster(SceneId) of
		[] -> ok;
		MonsterList ->
			FilterFun = fun(Monster) -> 
				X = Monster#monster.coord_x,
				Y = Monster#monster.coord_y,
				{_N, _M, CellNum, _SceneType} = mod_scene:get_cell_info(SceneId, X, Y),
				lists:member(CellNum, CellList) 
			end,
			MonsterList1 = lists:filter(FilterFun, MonsterList),
			case MonsterList1 of
				[] -> ok;
				_ ->
					MonsterIdList = [M#monster.id || M <- MonsterList1],
					{ok, MonstersPacket} = pt_11:write(11402, MonsterIdList),
					lib_send:send(PlayerCell#player_cell.player_id, MonstersPacket)
			end
	end.

broadcast_monster_state(Cell, Packet, TabName) ->
	case ets:match(TabName, #player_cell{cell = Cell, player_id = '$1', _ = '_'}) of
		[] -> ok;
		Player_id ->
			scene_help:broadcast_monster_state(Player_id, Packet)
	end.



