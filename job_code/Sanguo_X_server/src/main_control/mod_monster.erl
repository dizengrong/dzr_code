%%% ---------------------------------------------------------------------------
%%% @Author  : xwz
%%% @Description : outdoor monster management module
%%% @Created : 2011-1-17
%%% port for sanguo.
%%% currently one process control all of monsters, consider whether we need to use 
%%% separate process to control each scene to reduce latency
%%% ---------------------------------------------------------------------------

-module(mod_monster).
-behaviour(gen_server).

-include("common.hrl").

-export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([find_monster/2, battle_end/3, get_all_monster/1, fight_monster/3]).

-export([monster_move_in_scene/2]).

-export([player_enter/3,
		 player_move_check/4]).


-define(UNDEAD, 1).


%% ==============================================================================
%% External functions
%% ==============================================================================

fight_monster(Id, SceneId, MonsterId) ->
	gen_server:cast(mod_monster, {fight_monster, Id, SceneId, MonsterId}).

battle_end(_PS, BattleRes, {Id, SceneId, Monster}) ->
    IsMonWin = not BattleRes#battle_result.is_win,
	gen_server:cast(mod_monster, {battle_end, Id, SceneId, Monster, IsMonWin}).

get_all_monster(SceneId) ->
	case ets:lookup(?ETS_MONSTER, SceneId) of
		[] -> [];
		[MonsterScene] -> MonsterScene#monster_scene.alive
	end.

%% ==============================================================================
%% Server functions
%% ==============================================================================

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
	process_flag(trap_exit, true),
	ets:new(?ETS_MONSTER, [set, public, named_table, {keypos, #monster_scene.scene_id}]),
	init_monster_data(),
	init_timer(),
    {ok, null}.


handle_call(_Request, _From, _MonData) ->
    {reply, ok, _MonData}.


handle_cast({fight_monster, Id, SceneId, MonsterId}, _MonData) -> 
	%% first check the player status	
	?INFO(monster, "handle_cast fight_monster. MonsterId = ~w", [MonsterId]),
	
	{_Scene, X, Y}= scene:get_position(Id),
	
	case find_monster(SceneId, MonsterId) of
		{true, MonsterScene, Mon} ->
			?INFO(monster, "MonsterScene is ~w, mon is ~w",[MonsterScene,Mon]),
			Main_role = role_base:get_main_role_rec(Id),
			Level = Main_role#role.gd_roleLevel,
		
			if 
				Level < Mon#monster.level_limit -> 
					?ERR(todo, "add error return code");
				true->
					case (Mon#monster.state == ?MON_IDLE) andalso 
                            (util:check_distance(X, Y, Mon#monster.coord_x, Mon#monster.coord_y, 10)) of
                        true ->
                            %% this code is for testing
                        
                            Start = #battle_start {
                                mod      = pve,
                                type     = 0,       %% TODO: 写个真的值上去
                                att_id   = Id,
                                att_mer  = [],
                                monster  = Mon#monster.group_id,
                                maketeam = false,
                                caller   = monster,
                                callback = {mod_monster, battle_end, {Id, SceneId, Mon}}
                            },
            
                            ?INFO(battle, "battle starting... Start = ~w", [Start]),
                            battle:start(Start),
                        
                            NMon = Mon#monster{state = ?MON_IN_BATTLE},
                            %% we don't need to update undead monster.
                            if (Mon#monster.type =/= ?UNDEAD) ->
                                scene_monster:update_monster_state(SceneId, NMon),
                                update_monster(MonsterScene, MonsterId, NMon);		
                            true ->
                                ok
                            end;

                        false ->
                            ?INFO(monster, "false"),
                            ok %% can not start battle
                    end
			end;

		false ->
			%% can not start battle
			?INFO(monster, "Can not find monster in scene. Scene = ~w, MonsterId = ~w", [SceneId, MonsterId])
		end,

	{noreply, _MonData};

handle_cast({battle_end, _Id, SceneId, Monster, IsMonWin}, _MonData) ->
	?INFO(monster, "receive battle end"),
    MonsterId = Monster#monster.id,
    ?INFO(monster,"SceneId =~w,MonsterId =~w",[SceneId, MonsterId]),
	case find_monster(SceneId, MonsterId) of
		false -> 
		?INFO(monster,"cannot find Monster"),
		ok;
		{true, MonsterScene, Mon} ->
			if (Mon#monster.type =/= ?UNDEAD) ->
				if (IsMonWin == true) ->
					
					?INFO(monster, "monster is win."),
					NMon = Mon#monster{state = ?MON_IDLE},
					scene_monster:update_monster_state(SceneId, NMon),
					update_monster(MonsterScene, MonsterId, NMon);
	
				true -> %% monster is dead!!
					?INFO(monster, "monster is dead."),
					scene_monster:monster_leave(SceneId, [Mon]),
					NAlive = lists:keydelete(Mon#monster.id, #monster.id, MonsterScene#monster_scene.alive),
					NDead = 
						if (Mon#monster.type =/= refresh) ->
							[Mon#monster{state = ?MON_DEAD} | MonsterScene#monster_scene.dead];
						true ->
							MonsterScene#monster_scene.dead
						end,
						
					NMonsterScene = 
						MonsterScene#monster_scene{alive = NAlive, dead = NDead},
					
					ets:insert(?ETS_MONSTER, NMonsterScene)
				end;
			true -> %% monster is of type undead 
				ok
			end
	end,
	{noreply, _MonData};
						

handle_cast(_Msg, _MonData) ->
    {noreply, _MonData}.

handle_info(mon_revive, _MonData) ->
	List = ets:tab2list(?ETS_MONSTER),
	NList = monster_revive(List),
	lists:foreach(
	  	fun(MonScene) ->
			ets:insert(?ETS_MONSTER, MonScene)
		end, NList),
	{noreply, _MonData};

handle_info(mon_move, _MonData) ->
	List = ets:tab2list(?ETS_MONSTER),
	NList = monster_move(List),
	lists:foreach(
	  	fun(MonScene) ->
			ets:insert(?ETS_MONSTER, MonScene)
		end, NList),
	{noreply, _MonData};

handle_info({battle_end, Winner, Callback}, _MonData) ->
    {_, PlayerID, SceneID, Monster} = Callback,
    gen_server:cast(self(), {battle_end, PlayerID, SceneID, Monster, Winner =/= att}),
    {noreply, _MonData};

handle_info(_Info, MonData) ->
    {noreply, MonData}.

terminate(_Reason, _MonData) ->
	stop_timer(),
    ok.

code_change(_OldVsn, _MonData, _Extra) ->
	stop_timer(),
	init_timer(),
    {ok, null}.

%%===============================================================================
%% init function
%%===============================================================================
		
init_monster_data() ->
	Scenes = data_monster:get_all_scene(),
	ets:new(monsterPointSet, [set,public,named_table]),
	F = fun(Scene_id) ->
		Monsters = data_monster:get_scene_monster(Scene_id),
		G = fun(MonsterId, AliveList) ->
			Scene = data_scene:get(Scene_id),
			Monster = data_monster:get_monster(Scene_id, MonsterId),
			NMonster = 
				if 
				(Monster#monster.category == ?MON_MOVE_STILL) ->
						Monster;
				(Monster#monster.category == ?MON_MOVE_RADIUS) ->
					FullPath = ran_full_path(Monster#monster.coord_x,
								Monster#monster.coord_y,
								Monster#monster.radius, 
								Scene),
					Len      = length(FullPath),
					{X, Y}   = lists:nth(Len, FullPath),
					Path     = lists:nth(1, FullPath),
					Monster#monster {
						coord_x    = X,
						coord_y    = Y,
						full_path = FullPath,
						path       = [Path],
						path_index = 1
					};
				true -> %% moveable
					FullPath = Monster#monster.full_path,
					Len      = length(FullPath),
					{X, Y}   = lists:nth(Len, FullPath),
					Path     = lists:nth(1, FullPath),
					
					Monster#monster {
						coord_x    = X,
						coord_y    = Y,
						path       = [Path],
						path_index = 1
					}
				end,
			[NMonster | AliveList]
		end,
		AliveList = lists:foldl(G, [], Monsters),
		?INFO(monster, "MonScene = ~p", [#monster_scene{scene_id = Scene_id, alive = AliveList, dead = []}]),
		ets:insert(?ETS_MONSTER, #monster_scene{scene_id = Scene_id, alive = AliveList, dead = []})
	end,
	lists:foreach(F, Scenes).

init_timer() ->
	{ok, MoveTimer}    = timer:send_interval(4000,  self(), mon_move),
	{ok, ReviveTimer}  = timer:send_interval(10000, self(), mon_revive),
	{ok, RefreshTimer} = timer:send_interval(1000 * 60, self(), mon_refresh),
	
	put(move_timer, MoveTimer),
	put(revive_timer, ReviveTimer),
	put(refresh_timer, RefreshTimer).

stop_timer() ->
	timer:cancel(get(move_timer)),
	timer:cancel(get(revive_timer)),
	timer:cancel(get(refresh_timer)).

%%===============================================================================
%% Internal functions
%%===============================================================================

%% move functions
-spec monster_move(list()) -> list().
monster_move(List) ->
	monster_move(List, []).

monster_move([], List) ->
	List;

monster_move([MonsterScene = #monster_scene{scene_id = Scene, alive = Alive} | Rest], List) ->
	%% move each scene's monster one by one.
	NAlive = 
		monster_move_1(Scene, Alive, []),
	NMonsterScene = 
		MonsterScene#monster_scene{alive = NAlive},
	
	monster_move(Rest, [NMonsterScene | List]).

monster_move_1(_Scene, [], List) -> 
	List;

monster_move_1(Scene, [Monster = #monster{path = Path, path_index = Index, state = State,
	category = Cat, full_path = FullPath} | Rest], List) ->
	%% Cat == ?MON_MOVE_STILL | move
	Rand = util:rand(1,2),
	if 
		( Rand == 2) ->
			monster_move_1(Scene, Rest, [Monster | List]);
		(Cat == ?MON_MOVE_STILL) ->
			monster_move_1(Scene, Rest, [Monster | List]);
		(State =/= ?MON_IDLE) ->  
			monster_move_1(Scene, Rest, [Monster | List]);
		true ->
			Len = length(FullPath), %% Len must > 0 
			%% find the next path;
			NIndex = 
				if (Index < Len) ->
					Index + 1;
				true ->
					1
				end,

			%% do broadcasting here
			monster_move_in_scene(Scene, [Monster]),
			NPath = lists:nth(NIndex, FullPath),
			[{PathX, PathY}] = Path,
			NMonster = Monster#monster{coord_x = PathX, coord_y = PathY, path_index = NIndex, path = [NPath]},
	
			monster_move_1(Scene, Rest, [NMonster | List])
	end.

% ===================================================================================
% revive functions
% ===================================================================================
-spec monster_revive(list()) -> list().
monster_revive(List) ->
	monster_revive(List, []).

monster_revive([], List) ->
	List;

monster_revive([MonsterScene = #monster_scene{alive = Alive, 
	scene_id = Scene, dead = Dead} | Rest], List) ->
	
%% 	?INFO(monster, "=============================================="),
%% 	?INFO(monster, "before revive"),
%% 	?INFO(monster, "alive = ~wdead = ~w", [Alive, Dead]),
	Now = util:unixtime(),
	
	{NAlive, NDead} = 
		monster_revive_1(Scene, Now, Dead, Alive, []),
	
	NMonsterScene = 
		MonsterScene#monster_scene{alive = NAlive, dead = NDead},
	
%% 	?INFO(monster, "alive = ~wdead = ~w", [Alive, Dead]),
%% 	?INFO(monster, "after revive"),
%% 	?INFO(monster, "=============================================="),
	monster_revive(Rest, [NMonsterScene | List]).

monster_revive_1(_Scene, _Now, [], Alive, Dead) ->
	{Alive, Dead};
	
monster_revive_1(Scene, Now, [D = #monster{dead_time = Time} | Rest], Alive, Dead) ->
	%% TODO: cmp the time with Now to decide if let this monster revive.
	if (Now - Time >= 5000) ->
		%% revive it; and do boardcasting
		%% scene_monster:monster_enter(SceneId, _)
		case Scene of
			1100 -> ok; %% 原野村的怪物不要初始化  
			_ ->
				scene_monster:monster_enter(Scene, [D])
		end,
		monster_revive_1(Scene, Now, Rest, [D#monster{state = ?MON_IDLE} | Alive], Dead);
	true ->
		monster_revive_1(Scene, Now, Rest, Alive, [D | Dead])
	end.

-spec find_monster(SceneId :: integer(), MonsterId :: integer()) -> 
		  {true, MonScene :: #monster_scene{}, Mon :: #monster{} } | false. 

find_monster(SceneId, MonsterId) ->
	case find_scene(SceneId) of
		[] ->
		?INFO(monster,"cannot find Scene,SceneID = ~w",[SceneId]), 
		false;
		[MonScene] ->
			case lists:keysearch(MonsterId, #monster.id, MonScene#monster_scene.alive) of
				{value, Mon} -> {true, MonScene, Mon};
				false -> false
			end
	end.

update_monster(MonScene, MonsterId, Mon) ->
	NAliveList = 
		lists:keyreplace(MonsterId, #monster.id, MonScene#monster_scene.alive, Mon),
	NMonScene =
		MonScene#monster_scene{alive = NAliveList},
	ets:insert(?ETS_MONSTER, NMonScene).

-spec find_scene(SceneId :: integer()) -> list().
find_scene(SceneId) ->
	ets:lookup(?ETS_MONSTER, SceneId).
		
				
%%
%% API Functions
%%

%% ========================== Monster To Player ==============================
monster_move_in_scene(_SceneId, []) -> ok;
monster_move_in_scene(SceneId, [MonsterRec | Rest]) ->
	X0 = MonsterRec#monster.coord_x,
	Y0 = MonsterRec#monster.coord_y,
	{N, M, CellNum, _SceneType} = scene:get_cell_info(SceneId, X0, Y0),
	TabName1 = scene:get_scene_tab(0, SceneId),
	TabName = case is_list(TabName1) of
				  true ->TabName1;
			  	  false ->[TabName1]
			  end,
	{ok, MoveMsg} = pt_11:write(11401, MonsterRec),
	broadcast_move_to_player({N, M, CellNum}, MoveMsg, TabName),
	case MonsterRec#monster.path of
		[] -> ok;
		Path ->
			monster_move_check({X0, Y0}, lists:last(Path), MonsterRec, SceneId, TabName)
	end,
	monster_move_in_scene(SceneId, Rest),
	ok.

monster_move_check({X0, Y0}, {X1, Y1}, MonsterRec, SceneId, TabName) ->
	{N, M, OldCell, _SceneType} = scene:get_cell_info(SceneId, X0, Y0),
	{_N, _M, NewCell, _SceneType} = scene:get_cell_info(SceneId, X1, Y1),
	case scene_help:get_leave_and_enter_cells(OldCell, NewCell, N, M) of
		[] -> ok; %% in the same cell
		{LeaveCells, EnterCells} ->	 %% go to other cell
			monster_enter_help(MonsterRec, TabName, EnterCells),
			monster_leave_help(MonsterRec, TabName, LeaveCells)
	end.


monster_enter_help(MonsterRec, TabName, CellList) ->
	{ok, EnterMsg} = pt_11:write(11400, [MonsterRec]),
	[broadcast_monster_enter(MonsterRec#monster.id,Cell, EnterMsg, TabName) || Cell <- CellList].
	

monster_leave_help(MonsterRec, TabName, CellList) ->
	{ok, LeaveMsg} = pt_11:write(11402, [MonsterRec#monster.id]),
	[broadcast_monster_leave(MonsterRec#monster.id,Cell, LeaveMsg, TabName) || Cell <- CellList].


	
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

get_playerIds_by_Cell(CellNum,TabNameList)->
	Fun = fun(TabName, Acc) ->
		case ets:match(TabName, #player_cell{cell = CellNum,  player_id = '$1', _ = '_'}) of
			[] -> Acc;
			Matched -> lists:append(Acc, Matched)
		end
	end,
	lists:foldl(Fun, [], TabNameList).

broadcast_move_to_player({C, R, CellNum}, MoveMsg, TabName) ->
	Fun = fun(Cell, Acc) ->
		case get_playerIds_by_Cell(Cell,TabName) of
			[] -> Acc;
			Matched -> lists:append(Acc, Matched)
		end
	end,
	CellList = scene:get_near_cell(CellNum, C, R),
	PlayerIdList = lists:foldl(Fun, [], CellList),
	[lib_send:send(PlayerId, MoveMsg)||[PlayerId] <- PlayerIdList].

broadcast_monster_enter(_Id,Cell, EnterMsg, TabName) ->
	case get_playerIds_by_Cell(Cell,TabName) of
		[] -> none;		
		Matched ->
			[lib_send:send(SenderPid, EnterMsg) || [SenderPid] <- Matched]
	end.

broadcast_monster_enter2(PlayerCell, SceneId, CellList) ->
	case mod_monster:get_all_monster(SceneId) of
		[] -> ok;
		MonsterList ->
			FilterFun = fun(Monster) -> 
				X = Monster#monster.coord_x,
				Y = Monster#monster.coord_y,
				{_N, _M, CellNum, _SceneType} = scene:get_cell_info(SceneId, X, Y),
				lists:member(CellNum, CellList) 
			end,
			MonsterList1 = lists:filter(FilterFun, MonsterList),
			case MonsterList1 of
				[] -> ok;
				_ ->
					{ok, MonstersPacket} = pt_11:write(11400, MonsterList1),
					lib_send:send(PlayerCell#player_cell.player_id, MonstersPacket)
			end
	end.
	
broadcast_monster_leave(_Id,Cell, LeaveMsg, TabName) ->
	case get_playerIds_by_Cell(Cell,TabName) of
		[] -> ok;
		Matched ->
			[lib_send:send(SenderPid, LeaveMsg) || [SenderPid] <- Matched]
	end.

broadcast_monster_leave2(PlayerCell, SceneId, CellList) ->
	case mod_monster:get_all_monster(SceneId) of
		[] -> ok;
		MonsterList ->
			FilterFun = fun(Monster) -> 
				X = Monster#monster.coord_x,
				Y = Monster#monster.coord_y,
				{_N, _M, CellNum, _SceneType} = scene:get_cell_info(SceneId, X, Y),
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


ran_full_path(X,Y,R,Scene)->
	%%生成2~4个点
	%%todo, 检查是否能走
	%%todo，是否需要做校验不为0和不出界，判断不出界如何判断？
	Point_num = util:rand(2,4),
	F_rand_point = fun(X,Y,R,Scene)->
		Max_X = Scene#scene.column - 1,
		Max_Y = Scene#scene.row - 1,
		
		New_x = case (X-R + util:rand(0,R*2)) of 
			Nx when Nx< 0 -> 0;
			Nx when Nx > Max_X -> Max_X;
			Nx -> Nx
		end,
			
		New_y = case (Y-R + util:rand(0,R*2)) of 
			Ny when Ny< 0 -> 0;
			Ny when Ny > Max_Y -> Max_Y;
			Ny -> Ny
		end,
		?INFO(monster,"x, y is ~w, ~w",[New_x,New_y]),
		{X1,Y1} = case scene:can_move(Scene#scene.id,New_x, New_y) of
			true->
				{New_x, New_y};
			false->
				{X,Y}
		end,
				   
		case ets:lookup(monsterPointSet, {X1,Y1}) of 
			[]->
				ets:insert(monsterPointSet, {{X1,Y1}}),
				{X1,Y1};
			_->
				{X,Y}
		end
	end,

	Way_points = [F_rand_point(X,Y,R,Scene) || _Seq<-lists:seq(1, Point_num)],
	?INFO(monster,"way point is ~w", [Way_points]),
	Way_points.

	
	



				
				
