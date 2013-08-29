%% Author: dizengrong@gmail.com
%% Created: 2011-8-18
%% Description: TODO: Add description to lib_scene
-module(lib_scene).

%%=============================================================================
%% Include files
%%=============================================================================
-include("common.hrl").
%%=============================================================================
%% Exported Functions
%%=============================================================================
-export([player_enter/4, player_leave/4,
		 player_move/5, move_check/5, scene_jump/5,
		 check_npc/4,
		 go_to/7,
		 reset_location/6,
		 update_cell_data/6, update_cell_data/7, update_cell_data/8
		 ]).

%%=============================================================================
%% API FUNCTIONS   
%%=============================================================================	

%% return: true|false 
%% true表示成功，false表示失败
-spec go_to(player_id(), scene_id(), integer(), integer(), scene_id(), integer(), integer()) -> boolean().
go_to(PlayerId, NewSceneId, New_X, New_Y, OldSceneId, Old_X, Old_Y) ->
	case mod_scene:can_move(NewSceneId, New_X, New_Y) andalso jump_check(PlayerId, NewSceneId) of
		true ->
			case player_leave(PlayerId, OldSceneId, Old_X, Old_Y) of
				{false, can_ignore} ->
					send_jump_packet(PlayerId, NewSceneId, New_X, New_Y),
					true;
				{true, _SceneType} ->
					send_jump_packet(PlayerId, NewSceneId, New_X, New_Y),
					true
			end;
		false -> 
			?INFO(scene, "cannot go to a cannot move point:(~w, ~w, ~w)", [NewSceneId, New_X, New_Y]),
			false
	end.

send_jump_packet(PlayerId, SceneId, X, Y) ->
	{ok, Packet} = pt_11:write(11004, [SceneId, X, Y]),
	
	lib_send:send(PlayerId, Packet).

%% 跳转：先跳转，然后广播离开
%% 返回： 
%%		{false, ErrAtom} 表示跳转失败
%%		{true, Destination} 表示跳转成功
-spec scene_jump(player_id(), scene_id(), scene_id(), integer(), integer()) ->
	{true, Destination::tuple()} | {false, too_far}.
scene_jump(PlayerId, NewSceneId, OldSceneId, OldX, OldY) ->
	{FromX, FromY} = data_jump_point:get_from(OldSceneId, NewSceneId),

	Dist = util:distance(OldX, OldY, FromX, FromY),
	CanEnter = (Dist < (?CAN_JUMP_SCOPE)),
	case CanEnter andalso jump_check(PlayerId, NewSceneId) of
		true ->
			{ToX, ToY} = get_jump_dest_point(OldSceneId, NewSceneId),
			send_jump_packet(PlayerId, NewSceneId, ToX, ToY),
			player_leave(PlayerId, OldSceneId, OldX, OldY),
			{true, {NewSceneId, ToX, ToY}};
		false ->
			?INFO(scene,"Too far to jump to ~w", [NewSceneId]),
			{false, too_far}
	end.

get_jump_dest_point(OldSceneId, DestSceneId) ->
	SceneRec = data_scene:get(DestSceneId),
	case SceneRec#scene.type of
		?SCENE_DUNGEON ->
			data_scene:get_default_xy(DestSceneId);
		_ ->
			data_jump_point:get_to(OldSceneId, DestSceneId)
	end.

%% return: true | false
jump_check(_PlayerId, _DestSceneId) ->
	true.


%%=============================================================================
%% player move
%% parameter:
%%		Status: player_status record
%%		PosList: player's move path
player_move(PlayerId, PosList, SceneId, X, Y) ->
	SceneRecord = data_scene:get(SceneId),
	case SceneRecord#scene.type of
		?SCENE_CITY -> %% 城镇地图
			move_in_city(PlayerId, PosList, SceneId, X, Y);
		?SCENE_OUTDOOR -> %% 野外地图
			move_in_city(PlayerId, PosList, SceneId, X, Y);
		?SCENE_DUNGEON -> %% 副本地图
			move_in_dungeon(PlayerId, PosList, SceneId, X, Y);
		?SCENE_ARENA -> %% 竞技场地图
			move_in_city(PlayerId, PosList, SceneId, X, Y);
		?SCENE_ARENA2 -> %% BOSS竞技场地图
			move_in_city(PlayerId, PosList, SceneId, X, Y);
		?SCENE_MARSTOWER -> %% 英雄塔地图
			move_in_dungeon(PlayerId, PosList, SceneId, X, Y)
	end.
	

%% 处理在城镇中的移动	
move_in_city(PlayerId, PosList, SceneId, X0, Y0) ->
	?INFO(scene, "move path: ~w", [PosList]),
	
	{N, M, CellNum, _SceneType} = mod_scene:get_cell_info(SceneId, X0, Y0),
	TabName = mod_scene:get_scene_tab(PlayerId, SceneId, get),
	ets:update_element(TabName, PlayerId, {#player_cell.path, PosList}),
	{ok, MoveMsg} = pt_11:write(11000, [PlayerId, PosList]),
	%% do player move broadcast
	scene_help:broadcast_move({N, M, CellNum}, MoveMsg, TabName, PlayerId).

move_in_dungeon(PlayerId, PosList, SceneId, _X0, _Y0) ->
%% 	PlayerId = PS#player_status.id,
	case mod_team:get_team_state(PlayerId) of
		false -> ok;
		{true, PlayerId, MemberId} ->
			TabName = mod_scene:get_scene_tab(PlayerId, SceneId, get),
			case ets:lookup(TabName, MemberId) of
				[] -> 
					?ERR(scene, "Error in player ~w team state, his member: ~w", 
						  [PlayerId, MemberId]);
				[MemberLoc] ->
					{ok, Packet} = pt_11:write(11000, [PlayerId, PosList]),
					lib_send:send(MemberLoc#player_cell.send_pid, Packet),
					set_member_location(TabName, MemberId, PosList)
			end;
		{true, LeadId, PlayerId} ->
			?ERR(scene, "Team mate ~w can't move, his leader: ~w", [PlayerId, LeadId])
	end.

%% 将队长移动路径的最后一点设置为队员的当前坐标
set_member_location(TabName, MemberId, PosList) ->
	case PosList of
		[] -> ok;
		_ ->
			{NewX, NewY} = lists:last(PosList),
			UpdateElements = [{#player_cell.x, NewX}, {#player_cell.y, NewY}],
			ets:update_element(TabName, MemberId, UpdateElements)
	end.

%% 在城镇地图中重置玩家的坐标时需要广播其离去并进入的消息，X, Y 为重置的位置(in same scene)
%% 调用者需要确保是在城镇地图中重置坐标
%% 重要：在重置坐标时，玩家从格子A到格子B，当B正好是位于A附件时，玩家从A离开这个消息会向B中的玩家广播，
%% 而如果Cell记录是预先插入的话就造成了玩家自己被移除的局面了。。。因此先将其cell记录删除
%% 所以在这里和在move_check中，ets:insert(CellTab, NewPlayerLoc)都要最后更新
reset_location(PlayerId, PlayerSceneId, _PlayerX, _PlayerY, NewX, NewY) ->
	TabName = mod_scene:get_scene_tab(PlayerId, PlayerSceneId, get),
	[PlayerLoc] = ets:lookup(TabName, PlayerId),
	reset_location_help(PlayerLoc, PlayerSceneId, NewX, NewY, TabName),
	true.

reset_location_help(PlayerLoc, SceneId, X, Y, TabName) ->
	{N, M, NewCell, _SceneType} = mod_scene:get_cell_info(SceneId, X, Y),
	NewPlayerLoc = PlayerLoc#player_cell{
					cell = NewCell,
					x    = X, 
					y    = Y, 
					path = []},
	OldCellNum = PlayerLoc#player_cell.cell,
	{ok, LeaveMsg} = pt_11:write(11002, [PlayerLoc#player_cell.player_id]),
	ets:delete(TabName, PlayerLoc#player_cell.player_id),
	%% do player leave broadcast
	CellList1 = scene_help:get_move_broadcast_cell(OldCellNum, N, M),
	[scene_help:broadcast_leave(Cell, PlayerLoc, LeaveMsg, TabName) || Cell <- CellList1],

	{ok, EnterMsg} = pt_11:write(11001, [NewPlayerLoc]),
	CellList2 = scene_help:get_move_broadcast_cell(NewCell, N, M), 
	[scene_help:broadcast_enter(Cell, NewPlayerLoc, EnterMsg, TabName) || Cell <- CellList2],
	ets:insert(TabName, NewPlayerLoc).	%% 更新其坐标记录

%%=============================================================================
%% player move
%% parameter:
%%		PlayerStatus: player's player_status record
%%		CheckPoint: in type of {x, y}
%% 返回值：
%%		false：移动check失败
%%		true: 成功
move_check(PlayerId, CheckPoint, SceneId, X, Y) ->
	SceneRecord = data_scene:get(SceneId),
	case SceneRecord#scene.type of
		?SCENE_CITY ->	%% 城镇地图
			move_check_in_city(PlayerId, CheckPoint, SceneId, X, Y);	
		?SCENE_ARENA ->
			move_check_in_city(PlayerId, CheckPoint, SceneId, X, Y);	
		?SCENE_ARENA2 ->
			move_check_in_city(PlayerId, CheckPoint, SceneId, X, Y);
		?SCENE_OUTDOOR ->
			move_check_in_city(PlayerId, CheckPoint, SceneId, X, Y);
		?SCENE_DUNGEON ->
			{X1, Y1} = CheckPoint,
			Diff_X = util:abs(X1 - X),
			Diff_Y = util:abs(Y1 - Y),
			%% 移动掩码检测
			CanMoved = mod_scene:can_move(SceneId, X1, Y1),
			case CanMoved andalso (Diff_X < ?MAX_MOVE_LEN andalso Diff_Y < ?MAX_MOVE_LEN) of
				true ->
					move_check_in_dungeon(PlayerId, CheckPoint, SceneId);
				false ->
					move_check_failed(PlayerId, CheckPoint, CanMoved, SceneId, X, Y)
					
			end;
		?SCENE_MARSTOWER ->
			{X1, Y1} = CheckPoint,
			Diff_X = util:abs(X1 - X),
			Diff_Y = util:abs(Y1 - Y),
			%% 移动掩码检测
			CanMoved = mod_scene:can_move(SceneId, X1, Y1),
			case CanMoved andalso (Diff_X < ?MAX_MOVE_LEN andalso Diff_Y < ?MAX_MOVE_LEN) of
				true ->
					move_check_in_dungeon(PlayerId, CheckPoint, SceneId);
				false ->
					move_check_failed(PlayerId, CheckPoint, CanMoved, SceneId, X, Y)
					
			end
	end.

move_check_failed(_PlayerId, CheckPoint, CanMoved, SceneId, X, Y) ->
	{X1, Y1} = CheckPoint,
	?ERR(scene,"can't move from (~w, ~w) to (~w, ~w), CanMoved: ~w, Scene: ~w", 
		  [X, Y, X1, Y1, CanMoved, SceneId]),
	false.

move_check_in_city(PlayerId, {X1, Y1}, SceneId, X0, Y0) ->
	
	TabName = mod_scene:get_scene_tab(PlayerId, SceneId, get),
	case ets:lookup(TabName, PlayerId) of
		[] -> %% why???
			PS = mod_player:get_player_status(PlayerId),
			Report = ["lib_scene:move_check_in_city/5 error",
                      {player_status, PS}, {map_table_name, TabName},
                      {type, scene_error}, {what, error}, {trace, erlang:get_stacktrace()}],
			?ERR(scene, "lib_scene error!!! Report = ~w", [Report]),
			false;
		[PlayerLoc] ->
			case PlayerLoc#player_cell.path of
				[] -> %% 要check的点不在玩家的路径中
					?DEBUG(scene, "no path for check, But ok, just igonre it", []), 
					true;
				[{PathX1, PathY1} | RestPos] ->
					{N, M, OldCell, _SceneType} = mod_scene:get_cell_info(SceneId, X0, Y0),
					{_N, _M, NewCell, _SceneType} = mod_scene:get_cell_info(SceneId, X1, Y1),
					NewPlayerLoc = PlayerLoc#player_cell{cell = NewCell, x = X1, y = Y1, path = RestPos},
					Diff_X = util:abs(X1 - PathX1),
					Diff_Y = util:abs(Y1 - PathY1), 
					%% 移动掩码检测
					CanMoved = mod_scene:can_move(SceneId, X1, Y1),
					case CanMoved andalso util:abs(X1 - X0) < ?MAX_MOVE_LEN 
						 		  andalso util:abs(Y1 - Y0) < ?MAX_MOVE_LEN 
						 		  andalso Diff_Y =< ?MOVE_CHECK_SCOPE 
						 		  andalso Diff_X =< ?MOVE_CHECK_SCOPE of
						true ->
							case scene_help:get_leave_and_enter_cells(OldCell, NewCell, N, M) of
								[] -> ok;	%% in the same cell	
								{LeaveCells, EnterCells} ->	 %% go to other cell
									ets:delete(TabName, PlayerLoc#player_cell.player_id), %% 在广播时过滤掉自己？ 
									scene_help:broadcast_move_check(NewPlayerLoc, TabName, LeaveCells, EnterCells),
									scene_monster:player_move_check(NewPlayerLoc, LeaveCells, EnterCells, SceneId)
							end,
							ets:insert(TabName, NewPlayerLoc),	%% 更新其坐标记录
							true;
						false ->
							?ERR(scene, "~w move check failed! scene = ~w, (X0, Y0) = (~w, ~w), "
										"Path = ~w, CheckPoint = (~w, ~w)", 
								 [PlayerId, SceneId, X0, Y0, PlayerLoc#player_cell.path, X1, Y1]),							
							false
					end
			end
	end.

move_check_in_dungeon(_PlayerId, {_X1, _Y1}, SceneId) ->
	?INFO(scene, "check in dungeon scene:~w", [SceneId]),
	true.
	% StoryPid = PS#player_status.story_pid,
	% %% 每次队长来check时，也来设置队员的坐标，这个代价不值，
	% %%　可以在队长发送路径时设置路径的最后一个点为队员的坐标
	% %TabName = list_to_existing_atom("map_" ++ integer_to_list(SceneId)),
	% TabName = mod_scene:get_scene_tab(PS#player_status.id, SceneId, get),
	% [PlayerCell] = ets:lookup(TabName, PS#player_status.id),
	% case PlayerCell#player_cell.partner of
	% 	[1 | _] -> %% 只有队长才能在跳转副本中check的
	% 		case mod_story:check_process(SceneId, ?SCENE_DUNGEON, false, X1, Y1, StoryPid) of
	% 			{true, Type, ProcessId, MonsterId} ->
	% 				{true, {true, Type, ProcessId, MonsterId, ?SCENE_DUNGEON}};	
	% 			false ->
	% 				{true, false}
	% 		end;
	% 	_ ->
	% 		?ERR(scene, "check in dungeon scene:~w", [SceneId]),
	% 		{true, false}
	% end.
  


%% 检测玩家是否在某NPC的附件
%% 参数：NpcId：NPC的id，SceneId：玩家所在的场景，X：玩家的X坐标， Y：玩家的Y坐标
%% 返回true如果在NPC的附件，否则返回false
check_npc(NpcId, SceneId, X, Y) ->
	Scope = 4,
	case data_npc:get_location(NpcId) of
		{SceneId, NpcX, NpcY} ->
			(util:abs(NpcX - X) =< Scope andalso util:abs(NpcY - Y) =< Scope);
		_ ->
			?INFO(scene, "The npc: ~w is not in data_npc file", [NpcId]),
			false
	end.

%%=============================================================================
%% a player enter this scene
player_enter(PlayerId, SceneId, X, Y) ->
	SceneRecord = data_scene:get(SceneId),
	SceneType = SceneRecord#scene.type,
	case SceneType of
		?SCENE_CITY -> %% 城镇地图	
			enter_city(PlayerId, ?SCENE_CITY, SceneId, X, Y);
		?SCENE_OUTDOOR ->	%% 野外地图
			enter_city(PlayerId, ?SCENE_OUTDOOR, SceneId, X, Y);
		?SCENE_DUNGEON -> %% 副本地图
			enter_dungeon(PlayerId, SceneId, X, Y);
		?SCENE_ARENA -> %% 竞技场
			enter_city(PlayerId, ?SCENE_ARENA, SceneId, X, Y);
			% mod_online_arena:broadcast_arena_state(PlayerId);
		?SCENE_ARENA2 -> %% 竞技场
			enter_city(PlayerId, ?SCENE_ARENA2, SceneId, X, Y);
		?SCENE_MARSTOWER ->
			enter_marstower(PlayerId, SceneId, X, Y);
		_ -> ok
	end.

%% 进入城镇地图
enter_city(PlayerId, SceneType, SceneId, X, Y) ->
	{N, M, CellNum, _SceneType} = mod_scene:get_cell_info(SceneId, X, Y),
	
	PlayerLoc = get_player_cell_rec(PlayerId, CellNum, SceneType, SceneId, X, Y),
	{ok, EnterMsg} = pt_11:write(11001, [PlayerLoc]),
	CellList = scene_help:get_move_broadcast_cell(CellNum, N, M),
	
	
	TabName = mod_scene:get_scene_tab(PlayerId, SceneId, enter),
	[scene_help:broadcast_enter(Cell, PlayerLoc, EnterMsg, TabName) || Cell <- CellList],
	ets:insert(TabName, PlayerLoc),
	?INFO(scene,"Scene type is ~w",[SceneType]),
	case (SceneType == ?SCENE_OUTDOOR) orelse (SceneType == ?SCENE_CITY) of
	 	true ->
			?INFO(monster,"player enter ~w, ~w, ~w",[PlayerLoc, SceneId, CellList]),
	 		scene_monster:player_enter(PlayerLoc, SceneId, CellList);
	 	_ -> ok
	end.

%% 进入副本地图
enter_dungeon(PlayerId, SceneId, X, Y) ->	
	{_N, _M, CellNum, _SceneType} = mod_scene:get_cell_info(SceneId, X, Y),	
	PlayerLoc = get_player_cell_rec(PlayerId, CellNum, ?SCENE_DUNGEON, SceneId, X, Y),
	TabName = mod_scene:get_scene_tab(PlayerId, SceneId, enter),
	ets:insert(TabName, PlayerLoc),
	case mod_team:find_another_team_member(PlayerId) of
		false -> ok;
		MemberId ->
			case ets:lookup(TabName, MemberId) of
				[] -> %% partner还没进来
					?INFO(scene, "partner ~w not enter yet", [MemberId]);
				[MemberLoc] ->
					%% to self
					{ok, Packet1} = pt_11:write(11001, [MemberLoc]),
					lib_send:send(PlayerLoc#player_cell.send_pid, Packet1),
					%% to member
					{ok, Packet2} = pt_11:write(11001, [PlayerLoc]),
					lib_send:send(MemberLoc#player_cell.send_pid, Packet2)
			end
	end.

enter_marstower(PlayerId, SceneId, X, Y) ->	
	{_N, _M, CellNum, _SceneType} = mod_scene:get_cell_info(SceneId, X, Y),	
	PlayerLoc = get_player_cell_rec(PlayerId, CellNum, ?SCENE_MARSTOWER, SceneId, X, Y),
	TabName = mod_scene:get_scene_tab(PlayerId, SceneId, enter),
	ets:insert(TabName, PlayerLoc),
	case mod_team:find_another_team_member(PlayerId) of
		false -> ok;
		MemberId ->
			case ets:lookup(TabName, MemberId) of
				[] -> %% partner还没进来
					?INFO(scene, "partner ~w not enter yet", [MemberId]);
				[MemberLoc] ->
					%% to self
					{ok, Packet1} = pt_11:write(11001, [MemberLoc]),
					lib_send:send(PlayerLoc#player_cell.send_pid, Packet1),
					%% to member
					{ok, Packet2} = pt_11:write(11001, [PlayerLoc]),
					lib_send:send(MemberLoc#player_cell.send_pid, Packet2)
			end
	end.
%% 更新场景中玩家的数据
%% 参数FilterSelf为是否将通知过滤掉不给自己
update_cell_data(PlayerId, SceneId, X, Y, Packet, UpdateElements) ->
	update_cell_data(PlayerId, SceneId, X, Y, Packet, UpdateElements, false, true).
update_cell_data(PlayerId, SceneId, X, Y, Packet, UpdateElements, ClearPath) ->
	update_cell_data(PlayerId, SceneId, X, Y, Packet, UpdateElements, ClearPath, true).
update_cell_data(PlayerId, SceneId, X, Y, Packet, UpdateElements, ClearPath, FilterSelf) ->
	try
		TabName = mod_scene:get_scene_tab(PlayerId, SceneId, get),
		update_cell_data_help(TabName, PlayerId, UpdateElements, ClearPath),
		%% 广播给其他九宫格范围内的玩家
		{N, M, CellNum, _SceneType} = mod_scene:get_cell_info(SceneId, X, Y),	
		CellList = scene_help:get_move_broadcast_cell(CellNum, N, M),
		scene_help:broadcast_update(CellList, Packet, TabName, PlayerId, FilterSelf),
		?INFO(scene, "update player ~s's data: ~w, and do broadcast", 
			  [PlayerId, UpdateElements])
	catch
		Type:What -> ?EXCEPTION_LOG(Type, What, 'lib_scene:update_cell_data', 
									[PlayerId, Packet, UpdateElements, ClearPath])
	end.

update_cell_data_help(TabName, PlayerId, UpdateElements, ClearPath) ->
	case ClearPath of
		true ->
			ets:update_element(TabName, PlayerId, [{#player_cell.path, []} | UpdateElements]);
		_ ->
			ets:update_element(TabName, PlayerId, UpdateElements)
	end.


get_player_cell_rec(PlayerId, CellNum, _SceneType, SceneId, X, Y) ->
	AccountRec = player_db:get_account_rec(PlayerId),
	MainRoleRec = mod_role:get_main_role_rec(PlayerId),
	PS = mod_player:get_player_status(PlayerId),
	PlayerLoc = #player_cell{
		player_id      = PlayerId, 
		role_id        = AccountRec#account.gd_RoleID,
		scene_id       = SceneId,
		cell           = CellNum,
		nickname       = AccountRec#account.gd_RoleName,
		x              = X,
		y              = Y,
		
		title          = 0,
		level          = MainRoleRec#role.gd_roleLevel,
		role_rank      = AccountRec#account.gd_AccountRank,
		
		pet_data       = #pet{},

		send_pid       = PS#player_status.send_pid,
		move_queue_pid = PS#player_status.move_queue_pid
	},
	PlayerLoc.

%%=============================================================================
%% a player leave this scene and clear his scene data
-spec player_leave(player_id() , scene_id(), integer(), integer()) -> 
	{true, integer()} | {false, can_ignore}.
player_leave(PlayerId, SceneId, X, Y) ->
	SceneRecord = data_scene:get(SceneId),
	case SceneRecord#scene.type of 
		?SCENE_CITY -> %% 城镇地图 
			leave_city(PlayerId, SceneId, X, Y);
		?SCENE_OUTDOOR ->	%% 野外地图
			leave_city(PlayerId, SceneId, X, Y);
		?SCENE_DUNGEON -> %% 副本地图
			leave_dungeon(PlayerId, SceneId, X, Y);
		?SCENE_ARENA -> %% 竞技场地图
			leave_arena(PlayerId, SceneId, X, Y);
		?SCENE_ARENA2 -> %% BOSS竞技场地图
			leave_arena2(PlayerId, SceneId, X, Y);
		?SCENE_MARSTOWER -> %% 英雄塔地图
			leave_marstower(PlayerId,SceneId, X, Y)
	end.	

%% 离开竞技场
leave_arena(_PlayerId, _ArenaSceneId, _X, _Y) ->
	%% TO-DO: 离开竞技场的逻辑放到其他的做（应该是跳转）
	{true, ?SCENE_ARENA}.

%% 离开竞技场2(就是世界BOSS地图)		
leave_arena2(_PlayerId, _SceneId, _X, _Y) ->
	{true, ?SCENE_ARENA2}.

%% 玩家离开副本场景,调用方负责检测玩家是否在副本中			
leave_dungeon(PlayerId, SceneId, _X, _Y) ->
	mod_dungeon:leave(PlayerId, SceneId),
	TabName = mod_scene:get_scene_tab(PlayerId, SceneId, get),
	ets:delete(TabName, PlayerId),
	case mod_team:find_another_team_member(PlayerId) of
		false -> ok;
		MemberId ->
			case ets:lookup(TabName, MemberId) of
				[] -> 
					?ERR(scene, "Maybe player ~w team state is wrong, member: ~w", 
						 [PlayerId, MemberId]);
				[MemberLoc] ->
					%% to member
					{ok, Packet} = pt_11:write(11002, [PlayerId]),
					lib_send:send(MemberLoc#player_cell.send_pid, Packet)
			end
	end,
	{true, ?SCENE_DUNGEON}.

%% 离开城镇地图
leave_city(PlayerId, SceneId, X, Y) ->
	{N, M, CellNum, _SceneType} = mod_scene:get_cell_info(SceneId, X, Y),
	%% 这里使用try/catch的一个原因是，玩家跳转地图后又立马断开连接后就会出现，
	%% 这时就导致了没有调用mod_scene:get_scene_tab(PlayerId, SceneId, enter)，
	%% 从而有mod_scene:get_scene_tab返回none的情况出现
	%% 还有一个让人搞不清楚的错误：badarg
	try 
		case mod_scene:get_scene_tab(PlayerId, SceneId, leave) of
			none ->
				?DEBUG(scene, "Player ~w not in this scene?", [PlayerId]),
				{false, can_ignore};
			TabName ->
				?INFO(scene, "Player ~w get TabName: ~w", [PlayerId, TabName]),
				case ets:lookup(TabName, PlayerId) of
					[] -> 
						?DEBUG(scene, "Player ~w is not in the scene, "
								"but player_leave is called", [PlayerId]),
						{false, can_ignore};
					[PlayerLoc] ->	
						?INFO(scene,"player_leave: ~w ", [PlayerId]),
						ets:delete(TabName, PlayerId),
						{ok, LeaveMsg} = pt_11:write(11002, [PlayerId]),
						%% do player leave broadcast
						CellList = scene_help:get_move_broadcast_cell(CellNum, N, M),
						[scene_help:broadcast_leave(Cell, PlayerLoc, LeaveMsg, TabName) || Cell <- CellList],
						{true, ?SCENE_CITY}	
				end
		end
	catch
		Type:What ->
			?ERR(scene, "lib_scene error!!! Report = ~w", [[{my_message, "error in leave_city"},
									   {type, Type}, {what, What}, 
									   {stack, erlang:get_stacktrace()}]]),
			{false, can_ignore}
	end.
							

leave_marstower(PlayerId,SceneId, X, Y) ->
	{true, ?SCENE_MARSTOWER}.

		
	
	
