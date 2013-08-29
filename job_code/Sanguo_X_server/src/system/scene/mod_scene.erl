%%% -------------------------------------------------------------------
%%% Author  : dizengrong@gmail.com
%%% Description :
%%%
%%% Created : 2011-8-16
%%% -------------------------------------------------------------------
-module(mod_scene).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").
%% -include("scene.hrl").

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% --------------------------------------------------------------------
%% External exports
-export([init_scene/0, start_link/1, get_cell_info/3, get_position/1,
		 can_move/3, get_a_move_point/1, get_scene_tab/3, init_position/1,
		 get_access_scene/1, player_enter/2, player_move/2, move_check/2,
		 scene_jump/2, go_to/4, go_to/2,
		 get_same_scene_id/1,
		 open_new_scene/2, reset_location/3, leave_scene/2,
		 update_scene_state/2, update_achieve_title/2, 
		 update_main_role_level/2, update_guild_info/3,
		 update_role_rank/2, update_wing_data/2, update_horse_data/2,
		 update_equip_data/2, update_monsters/1]).

%% internal export
-export([get_position2/1, get_access_scene2/1, player_enter2/1, player_move2/1,
		 move_check2/1, scene_jump2/1, go_to2/1, open_new_scene2/1,
		 reset_location2/1, update_scene_state2/1, update_achieve_title2/1,
		 update_main_role_level2/1, update_guild_info2/1, update_role_rank2/1,
		 update_wing_data2/1, update_horse_data2/1, update_equip_data2/1,
		 leave_scene2/1,update_monsters2/1]).

%========================================================================================================
% gen_server functions
%========================================================================================================
start_link({ID})->
	gen_server:start_link(?MODULE, ID, []).
	
init_position(ID)->
	{X, Y} = data_scene:get_default_xy(?SPECIAL_MAP),
	Position = 
		#position {
			gd_accountID = ID,
			scene        = ?SPECIAL_MAP, 
			x            = X,
			y            = Y, 
			access_map   = data_scene:get_init_access()
		},
	gen_cache:insert(?SCENE_CACHE_REF, Position).
 
init(ID) ->
	process_flag(trap_exit, true),
	?INFO(scene, "init mod scene for ~w", [ID]),
	put(id,ID),
	mod_player:update_module_pid(ID, ?MODULE, self()),
    {ok, ID}.

handle_call({request, Action, Args}, _From, State) ->
	Reply = ?MODULE:Action(Args),
	{reply, Reply, State};

handle_call({get_same_scene_id, ID}, _From, State) ->
	Reply = [],
	{reply, Reply, State};

handle_call(Msg, _From, State) ->
	?INFO(scene, "unknown Msg: ~w", [Msg]),
	{reply, ok, State}.

handle_cast({request, Action, Args}, State) ->
	?MODULE:Action(Args),
	{noreply, State};

%% pt 11016 scene jump
handle_cast({go_to, ID, DesSceneID, DesX, DesY}, State) ->
	[Pos] = gen_cache:lookup(?SCENE_CACHE_REF, ID),
	case check_access(ID, DesSceneID) of
		false ->
			?INFO(scene, "you have no access to scene ~w", [DesSceneID]);
		_ ->
			lock_move(),
			SceneID = Pos#position.scene,
			X       = Pos#position.x,
			Y       = Pos#position.y,
			
			case lib_scene:go_to(ID, DesSceneID, DesX, DesY, SceneID, X, Y) of
				true ->
					save_position(ID, DesSceneID, DesX, DesY);
				false ->
					?ERR(scene, "go_to ~w failed", [DesSceneID])
			end
	end,
	{noreply, State};

handle_cast(Msg, State) ->
	?INFO(scene, "unknown Msg: ~w", [Msg]),
	{noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% --------------------------------------------------------------------
terminate(_Reason, State) ->
	PlayerId = State,
	save_player_location(PlayerId),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% --------------------------------------------------------------------
code_change(_OldVsn,State,_Extra) ->
    {ok, State}.


%% 获取玩家的当前位置，返回{scene_id, x, y}
-spec get_position(player_id()) -> {scene_id(), integer(), integer()}.
get_position(PlayerId)->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:call(PS#player_status.scene_pid,
					{request, get_position2, [PlayerId]}).

get_access_scene(PlayerId)->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, get_access_scene2, [PlayerId]}).

%% 开启一个新的地图
-spec open_new_scene(player_id(), scene_id()) -> any().
open_new_scene(PlayerId, SceneId) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, open_new_scene2, [PlayerId, SceneId]}).

%% 场景中的玩家进入事件
player_enter(PlayerId, SceneId) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, player_enter2, [PlayerId, SceneId]}).

%% 场景中的移动
player_move(PlayerId, PosList) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, player_move2, [PlayerId, PosList]}).

%% 场景中的移动check
move_check(PlayerId, Pos) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, move_check2, [PlayerId, Pos]}).

%% 场景中的跳转
scene_jump(PlayerId, NewSceneId) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, scene_jump2, [PlayerId, NewSceneId]}).

%% 跳转到指定地图的默认点去
%% 而具体跳转到什么地图，是副本还是竞技场，以及进入的条件检测由
%% 上层的调用者处理
go_to(PlayerId, DestSceneId) ->
	{DestX, DestY} = data_scene:get_default_xy(DestSceneId),
	go_to(PlayerId, DestSceneId, DestX, DestY).

%% 直接跳转到指定的目的地
go_to(ID, SceneId, X, Y) ->
	Ps = mod_player:get_player_status(ID), 
	gen_server:cast(Ps#player_status.scene_pid, {go_to, ID, SceneId, X, Y}).

%% 离开像副本这样的地图
leave_scene(PlayerId, OldSceneId) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, leave_scene2, [PlayerId, OldSceneId]}).

%% 
%% 重置玩家的坐标，参数NewX和NewY为新的坐标
reset_location(PlayerId, NewX, NewY) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, reset_location2, [PlayerId, NewX, NewY]}).

%% 更新玩家在场景中的状态标识
%% 目前支持的状态标识有：
%%		0：行走（即无状态）
%%		1：战斗
-spec update_scene_state(player_id(), ssf()) -> any().
update_scene_state(PlayerId, StateFlag) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, update_scene_state2, [PlayerId, StateFlag]}).

%% 更新玩家的成就称号id
update_achieve_title(PlayerId, AchieveTitleId) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, update_achieve_title2, [PlayerId, AchieveTitleId]}).

%% 更新玩家的主角等级
update_main_role_level(PlayerId, MainRoleLv) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, update_main_role_level2, [PlayerId, MainRoleLv]}).

%% 更新玩家的公会信息
update_guild_info(PlayerId, GuildLv, GuildName) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, update_guild_info2, [PlayerId, GuildLv, GuildName]}).

%% 更新玩家的角色身份
update_role_rank(PlayerId, RoleRank) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, update_role_rank2, [PlayerId, RoleRank]}).

%% 更新玩家的翅膀数据
update_wing_data(PlayerId, WingData) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, update_wing_data2, [PlayerId, WingData]}).

%% 更新玩家的坐骑数据
update_horse_data(PlayerId, HorseData) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, update_horse_data2, [PlayerId, HorseData]}).

%% 更新玩家的装备数据
%% 武器：weapon，铠甲：kajia，披风：pifeng，鞋子：shoes，戒指：ring
%% 参数KeyValList为[{Type, Value}]，其中Type为上面定义的atom类型
%% 什么类型改变了就传递相应的key-value对
-spec update_equip_data(player_id(), [{atom(), integer()}]) -> any().
update_equip_data(PlayerId, KeyValList) ->
	PS = mod_player:get_player_status(PlayerId), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, update_equip_data2, [PlayerId, KeyValList]}).

%%更新11405
update_monsters(Id)->
	PS = mod_player:get_player_status(Id), 
	gen_server:cast(PS#player_status.scene_pid, 
					{request, update_monsters2, [Id]}).
	
 
get_position2([PlayerId]) ->
	[PositionRec] = gen_cache:lookup(?SCENE_CACHE_REF, PlayerId),
	%% TODO 地图在塔内，则移到外面
	{PositionRec#position.scene, PositionRec#position.x, PositionRec#position.y}.

get_access_scene2([PlayerId]) ->
	
	[PositionRec] = gen_cache:lookup(?SCENE_CACHE_REF, PlayerId), 
%% 	PS = mod_player:get_player_status(PlayerId),
	{ok, Packet} = pt_11:write(11012, PositionRec#position.access_map),
	lib_send:send(PlayerId, Packet).

player_enter2([PlayerId, SceneId]) ->
	?INFO(scene,"SceneId = ~w",[SceneId]),
	
	case get_position3(PlayerId) of
		{SceneId, X, Y} ->
			unlock_move(),
			%%发送11405,通知客户端有怪物
						SceneRec = data_scene:get(SceneId),
			?INFO(scene,"SCENE TYPE = ~w",[SceneRec#scene.type]),

			case SceneRec#scene.type of
				?SCENE_MARSTOWER ->
					?INFO(scene, "Notify the Client Monster_list!"),
					mod_marstower:sendMonsterList(PlayerId);
				_Else ->
					?INFO(scene, "Did not jump MARSTOWER!"),
					Monster_list = mod_monster:get_all_monster(SceneId),
					{ok,Bin} = pt_11:write(11405, Monster_list),
					lib_send:send(PlayerId,Bin)
			end,

			lib_scene:player_enter(PlayerId, SceneId, X, Y);
		_ ->
			?ERR(scene, "player ~w not in this scene ~w", [PlayerId, SceneId])
	end.

player_move2([PlayerId, PosList]) ->
	case move_lock_check() of
		true -> ok;
		_ -> 
			{SceneId, X, Y} = get_position3(PlayerId),
			lib_scene:player_move(PlayerId, PosList, SceneId, X, Y)
	end.

move_check2([PlayerId, {NewX, NewY} = Pos]) ->
	case move_lock_check() of
		true -> ok;
		_ ->
			{SceneId, X, Y} = get_position3(PlayerId),
			case lib_scene:move_check(PlayerId, Pos, SceneId, X, Y) of
				false -> 
					ok;
				true ->
					?INFO(scene, "player check from (~w,~w) to (~w,~w)", [X, Y, NewX, NewY]),
					save_position(PlayerId, SceneId, NewX, NewY)
			end
	end.

scene_jump2([PlayerId, NewSceneId]) ->
	[PositionRec] = gen_cache:lookup(?SCENE_CACHE_REF, PlayerId),
	case check_access(PlayerId, NewSceneId) of
		false ->
			?INFO(scene, "you have no access to scene ~w", [NewSceneId]);
		_ ->
			SceneId = PositionRec#position.scene,
			X = PositionRec#position.x,
			Y = PositionRec#position.y,
			case lib_scene:scene_jump(PlayerId, NewSceneId, SceneId, X, Y) of
				{true, {NewSceneId, ToX, ToY}} -> 
					save_position(PlayerId, NewSceneId, ToX, ToY),
					lock_move();
				{false, _} -> ok
			end
	end.

check_access(_PlayerId, _SceneId) ->
	true.
go_to2([PlayerId, DestSceneId, DestX, DestY]) ->
	[PositionRec] = gen_cache:lookup(?SCENE_CACHE_REF, PlayerId),
	case check_access(PlayerId, DestSceneId) of
		false ->
			?INFO(scene, "you have no access to scene ~w", [DestSceneId]);
		_ ->
			lock_move(),
			SceneId = PositionRec#position.scene,
			X = PositionRec#position.x,
			Y = PositionRec#position.y,
			case lib_scene:go_to(PlayerId, DestSceneId, DestX, DestY, SceneId, X, Y) of
				true ->
					save_position(PlayerId, DestSceneId, DestX, DestY);
				false ->
					?ERR(scene, "go_to ~w failed", [DestSceneId])
			end
	end.

leave_scene2([PlayerId, OldSceneId]) ->
	case get_position3(PlayerId) of
		{OldSceneId, X, Y} ->
			lock_move(),
			SceneRec = data_scene:get(OldSceneId),
			case SceneRec#scene.type of
				?SCENE_DUNGEON ->
					{DestSceneId, DestX, DestY} = data_jump_point:get_leave_dungeon(OldSceneId);
				?SCENE_MARSTOWER ->
					{DestSceneId, DestX, DestY} = data_jump_point:get_leave_tower(OldSceneId)
			end,
			?INFO(scene, "call leave_scene, DestSceneId: ~w", [DestSceneId]),
			case lib_scene:go_to(PlayerId, DestSceneId, DestX, DestY, OldSceneId, X, Y) of
				true ->
					save_position(PlayerId, DestSceneId, DestX, DestY);
				false ->
					?ERR(scene, "go_to ~w failed", [DestSceneId])
			end;
		{OtherSceneId, X2, Y2} ->
			?ERR(scene, "Player ~w not in scene ~w, but in (~w, ~w, ~w)",
				 [PlayerId, OldSceneId, OtherSceneId, X2, Y2])
	end.

save_player_location(PlayerId) ->
	lock_move(),
	{SceneId, X, Y} = get_position3(PlayerId),
	SceneRec = data_scene:get(SceneId),
	case SceneRec#scene.type of
		?SCENE_DUNGEON ->
			{DestSceneId, DestX, DestY} = data_jump_point:get_leave_dungeon(SceneId);
		_ ->
			DestSceneId = SceneId, DestX = X, DestY = Y
	end,
	save_position(PlayerId, DestSceneId, DestX, DestY),
	lib_scene:player_leave(PlayerId, SceneId, X, Y).

open_new_scene2([PlayerId, NewScene]) ->
	[PositionRec] = gen_cache:lookup(?SCENE_CACHE_REF, PlayerId), 
	case lists:member(NewScene, PositionRec#position.access_map) of
		true ->
			ok;
		false ->
			Updates = [{#position.access_map, [NewScene | PositionRec#position.access_map]}],
			gen_cache:update_element(?SCENE_CACHE_REF, PlayerId, Updates),
%% 			PS = mod_player:get_player_status(PlayerId),
			{ok, Packet} = pt_11:write(11013, [NewScene]),
			lib_send:send(PlayerId, Packet)
	end.

reset_location2([PlayerId, NewX, NewY]) ->
	{SceneId, X, Y} = get_position3(PlayerId),
	save_position(PlayerId, SceneId, NewX, NewY),
	lib_scene:reset_location(PlayerId, SceneId, X, Y, NewX, NewY).

update_scene_state2([PlayerId, StateFlag]) ->
	{ok, Packet} = pt_11:write(11051, {PlayerId, StateFlag, ""}),
	UpdateElements = [{#player_cell.state, StateFlag}],
	update_scene_data_help(PlayerId, Packet, UpdateElements).

update_achieve_title2([PlayerId, AchieveTitleId]) ->
	StringData = pt_11:write_cell_other_data([{title, AchieveTitleId}], ""),
	{ok, Packet} = pt_11:write(11050, StringData),
	UpdateElements = [{#player_cell.title, AchieveTitleId}],
	update_scene_data_help(PlayerId, Packet, UpdateElements).

update_main_role_level2([PlayerId, MainRoleLv]) ->
	StringData = pt_11:write_cell_other_data([{level, MainRoleLv}], ""),
	{ok, Packet} = pt_11:write(11050, StringData),
	UpdateElements = [{#player_cell.level, MainRoleLv}],
	update_scene_data_help(PlayerId, Packet, UpdateElements).

update_guild_info2([PlayerId, GuildLv, GuildName]) ->
	StringData = pt_11:write_cell_other_data([{guild_lv, GuildLv}, {guild_name, GuildName}], ""),
	{ok, Packet} = pt_11:write(11050, StringData),
	UpdateElements = [{#player_cell.guild_lv, GuildLv}, {#player_cell.guild_name, GuildName}],
	update_scene_data_help(PlayerId, Packet, UpdateElements).

update_role_rank2([PlayerId, RoleRank]) ->
	StringData = pt_11:write_cell_other_data([{role_rank, RoleRank}], ""),
	{ok, Packet} = pt_11:write(11050, StringData),
	UpdateElements = [{#player_cell.role_rank, RoleRank}],
	update_scene_data_help(PlayerId, Packet, UpdateElements).

update_wing_data2([PlayerId, Data]) ->
	{ok, Packet} = pt_11:write(11052, {PlayerId, [{wing, Data}]}),
	UpdateElements = [{#player_cell.wing_data, Data}],
	update_scene_data_help(PlayerId, Packet, UpdateElements).

update_horse_data2([PlayerId, Data]) ->
	{ok, Packet} = pt_11:write(11052, {PlayerId, [{horse, Data}]}),
	UpdateElements = [{#player_cell.horse_data, Data}],
	update_scene_data_help(PlayerId, Packet, UpdateElements).

update_equip_data2([PlayerId, KeyValList]) ->
	{ok, Packet} = pt_11:write(11052, {PlayerId, KeyValList}),
	Fun = fun({EquipType, Value}, Updates) ->
			T = case EquipType of
				weapon -> {#equip_info.weapon, Value};
				kaijia -> {#equip_info.kaijia, Value};
				pifeng -> {#equip_info.pifeng, Value};
				shoes  -> {#equip_info.shoes, Value};
				ring   -> {#equip_info.ring, Value}
			end,
			[T | Updates]
	end,
	UpdateElements = lists:foldl(Fun, [], KeyValList),
	update_scene_data_help(PlayerId, Packet, UpdateElements).

update_scene_data_help(PlayerId, Packet, UpdateElements) ->
	{SceneId, X, Y} = get_position3(PlayerId),
	lib_scene:update_cell_data(PlayerId, SceneId, X, Y, Packet, UpdateElements).


-spec get_same_scene_id(ID :: player_id()) -> [player_id()].
get_same_scene_id(ID) ->
	Ps = mod_player:get_player_status(ID),
	Spid = Ps#player_status.player_pid,
	gen_server:call(Spid, {get_same_scene_id, ID}).
	
%% ============================================================================
%% ============================================================================
%% ============================================================================

get_position3(PlayerId) ->
	[PositionRec] = gen_cache:lookup(?SCENE_CACHE_REF, PlayerId), 
	{PositionRec#position.scene, PositionRec#position.x, PositionRec#position.y}.

save_position(PlayerId, SceneId, NewX, NewY) ->
	Updates = [{#position.scene, SceneId}, {#position.x, NewX}, {#position.y, NewY}],
	gen_cache:update_element(?SCENE_CACHE_REF, PlayerId, Updates).

init_scene() ->
	SceneIdList = data_scene:get_id_list(),
	ets:new(scene_info, [public, set, named_table]),
	init_scene_help(SceneIdList),
	init_specail_scene(),
	
	init_scene_mask_help(SceneIdList).

%% 获取场景SceneId中一个可以走的点
get_a_move_point(SceneId) ->
	MaskTabName = list_to_atom("mask_" ++ integer_to_list(SceneId)),
	case ets:first(MaskTabName) of
		'$end_of_table' ->
			exit("SceneId " ++ integer_to_list(SceneId) ++ " has no mask data");
		MaskKey ->
			#mask_key{scene = _Scene, x = X, y = Y} = MaskKey,
			{X, Y}
	end.

get_cell_info(SceneId, X, Y) ->
	[{_, N, M, Type}] = ets:lookup(scene_info, SceneId),
	Cell = Y div ?CELL_HEIGHT * N + X div ?CELL_WIDTH + 1,
	{N, M, Cell, Type}.

%% 获取玩家所在场景的ets表名， 
%% 若PlayerId == 0， 则表明时怪物来获取表名，注意怪物不会在SPECIAL_MAP中的
get_scene_tab(PlayerId, SceneId, Action) ->
	case SceneId == ?SPECIAL_MAP of
		true ->
			case Action of
				get -> %% just get map tab id
					ets:lookup_element(room_index, PlayerId, 2);
				leave -> %% 玩家离开地图
					case ets:lookup(room_index, PlayerId) of
						[] -> 
							?INFO(scene, "player ~w not in 1100", [PlayerId]),
							none;
						[{_, MapTab, Index}] ->
							?INFO(scene, "player ~w, MapTab: ~w, Index: ~w", 
								  [PlayerId, MapTab, Index]),
							Tab = room_volume,
							ets:update_counter(Tab, Index, {2, -1}),
							ets:delete(room_index, PlayerId),
							?INFO(scene, "player ~w, returned", [PlayerId]),
							MapTab
					end;
				enter -> %% 玩家进入地图
					{Index, _Val} = get_next_virtual_room(1),
					Tab = room_volume,
					ets:update_counter(Tab, Index, {2, 1}),
					MapTab =list_to_existing_atom("map_" ++ integer_to_list(SceneId) 
										++ "_" ++ integer_to_list(Index)),
					ets:insert(room_index, {PlayerId, MapTab, Index}),
					MapTab
			end;
		_ -> 
			case lists:member(SceneId, data_scene:get_boss_scene()) of
				true ->
					case Action of
						get -> ets:lookup_element(room_index, PlayerId, 2);
						leave ->
							case ets:lookup(room_index, PlayerId) of
								[] -> 
									?ERR(scene, "player ~w not in boss map", [PlayerId]),
									none;
								[{_, MapTab, _Index}] ->
									ets:delete(room_index, PlayerId),
									MapTab
							end;
						enter ->
							Index = mod_boss:get_player_room(PlayerId),
							MapTab =list_to_atom("map_" ++ integer_to_list(SceneId) 
										++ "_" ++ integer_to_list(Index)),
							ets:insert(room_index, {PlayerId, MapTab, Index}),
							MapTab
					end;
				_false ->
					list_to_existing_atom("map_" ++ integer_to_list(SceneId))
			end
	end.

get_next_virtual_room(?SPECIAL_NUM) -> 
%% 	Tab = list_to_existing_atom("room_volume_" ++ integer_to_list(?SPECIAL_NUM)),
	Tab = room_volume,
	Val = ets:lookup_element(Tab, ?SPECIAL_NUM, 2),
	{?SPECIAL_NUM, Val};
get_next_virtual_room(Index) ->
%% 	Tab = list_to_existing_atom("room_volume_" ++ integer_to_list(Index)),
	Tab = room_volume,
	Val = ets:lookup_element(Tab, Index, 2),
	case Val < ?MAX_PLAYER_IN_ROOM of
		true -> {Index, Val};
		_ -> get_next_virtual_room(Index + 1)
	end.
	


init_scene_help([]) -> ok;
init_scene_help([SceneId | Rest]) ->
	SceneRecord = data_scene:get(SceneId),
	FilterCheck = (SceneRecord#scene.type == ?SCENE_CITY) orelse 
				  (SceneRecord#scene.type == ?SCENE_ARENA) orelse
				  (SceneRecord#scene.type == ?SCENE_OUTDOOR) orelse
				  (SceneRecord#scene.type == ?SCENE_DUNGEON) orelse
				  (SceneRecord#scene.type == ?SCENE_MARSTOWER),
	case FilterCheck andalso (SceneId /= ?SPECIAL_MAP) of
		true-> %% city
			TableName = list_to_atom("map_" ++ integer_to_list(SceneId)),
			ets:new(TableName, [{keypos,#player_cell.player_id},
					 			{write_concurrency, true}, 
					 			{read_concurrency, true}, 
					 			public, set, named_table]),
			
			CellClown = util:ceil_div(SceneRecord#scene.column, ?CELL_WIDTH),
			CellRow = util:ceil_div(SceneRecord#scene.row, ?CELL_HEIGHT),
			ets:insert(scene_info, {SceneId, CellClown, CellRow, SceneRecord#scene.type});
		_ ->
			ok
	end,
	init_scene_help(Rest).

init_specail_scene() ->
	%% 记录玩家位于哪个虚拟房间里，表字段： 玩家id	虚拟房间
	ets:new(room_index, [{write_concurrency, true}, 
								{read_concurrency, true}, 
			 			 		public, set, named_table]),
	%% 记录原野虚拟村的虚拟房间的人数，作为分配依据
	ets:new(room_volume, [{write_concurrency, true}, {read_concurrency, true}, 
			 			 public, set, named_table]),
	
	Fun = fun(SceneId, Num) ->
		SceneRecord = data_scene:get(SceneId),
		CellClown = util:ceil_div(SceneRecord#scene.column, ?CELL_WIDTH),
		CellRow = util:ceil_div(SceneRecord#scene.row, ?CELL_HEIGHT),
		ets:insert(scene_info, {SceneId, CellClown, CellRow, SceneRecord#scene.type}),
		init_specail_scene_help(SceneId, Num)
	end,

	%% FOR 原野虚拟村
	Fun(?SPECIAL_MAP, ?SPECIAL_NUM),
	
	%% FOR 世界BOSS
	BossSceneList = data_scene:get_boss_scene(),
	[Fun(S, data_system:get(2)) || S <- BossSceneList].
	

init_specail_scene_help(_SceneId, 0) -> ok;
init_specail_scene_help(SceneId, Num) ->
	TableName = list_to_atom("map_" ++ integer_to_list(SceneId) 
							++ "_" ++ integer_to_list(Num)),
	ets:new(TableName, [{keypos,#player_cell.player_id},
			 			{write_concurrency, true}, 
			 			{read_concurrency, true}, 
			 			public, set, named_table]),
	ets:insert(room_volume, {Num, 0}),
	init_specail_scene_help(SceneId, Num - 1).
	

init_scene_mask_help([]) -> ok;
init_scene_mask_help([SceneId | Rest]) ->
	SceneRecord = data_scene:get(SceneId),
	MaskTabName = list_to_atom("mask_" ++ integer_to_list(SceneId)),
	ets:new(MaskTabName, [public, set, named_table, 
						  {write_concurrency, true}, 
			 			  {read_concurrency, true}, 
						  {keypos,#scene_mask.key}]),
	%% load scene mask	
	Mask = data_mask:get(SceneId),
	load_mask(Mask, 0, 0, SceneRecord#scene.column, SceneRecord#scene.id, MaskTabName),
	init_scene_mask_help(Rest).
	
	
load_mask([], _, _, _, _, _) ->
    null;
%% paramter:
%% [H|T]: mask list, X: current x, Y: current y, Clown: how many clown of the scene  
load_mask([H|T], X, Y, Clown, Scene, MaskTabName) ->
	case H of 
        49 -> % 1 cannot move
			ok;
        _  -> % 0, 2 can move
            ets:insert(MaskTabName, 
					   #scene_mask{key = #mask_key{scene = Scene, x = X, y = Y}, 
								   can_move = true})
    end,
	if 
		X < Clown - 1 -> load_mask(T, X + 1, Y, Clown, Scene, MaskTabName);
		true -> load_mask(T, 0, Y + 1, Clown, Scene, MaskTabName)
	end.	
	
%% 移动掩码检测，若位于地图scene中的点（X， Y）可以移动的话则返回true，否则返回false
can_move(Scene, X, Y) ->
	MaskTabName = list_to_atom("mask_" ++ integer_to_list(Scene)),
	MaskKey = #mask_key{scene = Scene, x = X, y = Y},
	case ets:lookup(MaskTabName, MaskKey) of
		[] -> false;
		_  -> true
	end.
		
% load_mask_test(SceneId) ->
% 	SceneRecord = data_scene:get(SceneId),
% 	Mask = data_mask:get(SceneId),
% 	MaskTabName = list_to_atom("mask_" ++ integer_to_list(SceneId)),
% 	load_mask(Mask, 0, 0, SceneRecord#scene.clown, SceneRecord#scene.id, MaskTabName).
	
	
	


%% 这个锁定移动的原因是，当玩家跳转时，服务端就已经把玩家设置为在目的地图了，
%% 但客户端还没收到跳转包却还在移动，于是就出错了
%% 解决办法是在服务端成功跳转后，设置移动锁定，然后在玩家进入地图获取视野时解锁
lock_move() ->
	erlang:put(lock_move, true).
unlock_move() ->
	erlang:put(lock_move, false).
move_lock_check() ->
	case erlang:get(lock_move) of
		true -> true;
		_ -> false
	end.	

update_monsters2([Id])->
	case gen_cache:lookup(?SCENE_CACHE_REF, Id) of
		[PositionRec] ->
			?INFO(scene,"update monsters in position ~w", [PositionRec]),
			Monster_lists = mod_monster:get_all_monster(PositionRec#position.scene),
			{ok,Bin} = pt_11:write(11405, Monster_lists),
			lib_send:send(Id,Bin);
		[]->
			?INFO(scene, "no record, is it init at the first time")
	end.