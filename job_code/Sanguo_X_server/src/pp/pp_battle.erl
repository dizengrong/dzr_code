
-module(pp_battle).

-include("common.hrl").
-export([handle/3]).

-define(BATTLE_DISTANCE, 6).		%% 打怪的最大检测距离

handle(20000, ID, _Data) ->
	Start = 
		#battle_start {
			mod      = pve,
			att_id   = ID,
			att_mer  = [],
			caller   = 0,
			callback = 0,  
			maketeam = false,
			monster  = 1
		},
	
	?INFO(battle, "battle starting..."),
	battle:start(Start);

handle(20001, ID, Cmd) ->
	?INFO(battle, "handleing Cmd 20001"),
	Ps = mod_player:get_player_status(ID),
	
	case Cmd of
		finish_play -> 
			gen_fsm:send_event(Ps#player_status.battle_pid, {finish_play, ID});
		SkillId ->
			gen_fsm:send_event(Ps#player_status.battle_pid, {set_cmd, ID, SkillId})
	end,
	?INFO(battle, "finish handling Cmd 20001");

handle(20008, ID, _) ->
	Ps = mod_player:get_player_status(ID),
	battle:quit_battle(Ps#player_status.battle_pid, ID);
	
handle(20100, PlayerId, MonsterUniqueId) ->
	{SceneId, _X, _Y} = scene:get_position(PlayerId),
	SceneRec = data_scene:get(SceneId),
	?INFO(battle,"^^^^^^^^^^^^SceneId = ~w",[SceneId]),
	case SceneRec#scene.type of
		?SCENE_DUNGEON -> 
			case battle_check(PlayerId, [{dungeon_process, MonsterUniqueId}]) of
				true -> 
					DungeonProcessRec = data_dungeon:process(MonsterUniqueId),
					BattleStartRec = #battle_start {
				        mod      = pve,
				        att_id   = PlayerId,
				        monster  = DungeonProcessRec#dungeon_process.monster_group_id,
				        callback = {mod_dungeon, battle_complete, [MonsterUniqueId]},
						maketeam = true
					},
					battle:start(BattleStartRec);
				false ->
					?ERR(battle, "battle check failed, MonsterUniqueId: ~w", [MonsterUniqueId])
			end;
		?SCENE_MARSTOWER ->
			case battle_check(PlayerId, [{marstower, MonsterUniqueId}]) of
				true ->
					MonsterINFO = data_monster:get_monster(SceneId,MonsterUniqueId),
					BattleStartRec = #battle_start {
				        mod      = pve,
				        att_id   = PlayerId,
				        monster  = MonsterINFO#monster.group_id,
						maketeam = false,
				        callback = {mod_marstower, battle_complete, [MonsterUniqueId]}
					},
					battle:start(BattleStartRec);
				false ->
					?ERR(battle, "battle check failed, MonsterUniqueId: ~w", [MonsterUniqueId])
			end;
		_ -> %% 在这里添加其他场景战斗的处理
			?ERR(battle, "If there no battle to process, remove it")
	end;

handle(_, _, _) ->
	ok.
	
%% 在这里添加你要做的战斗前的检测	
battle_check(PlayerId, Checklist) ->
	battle_check(PlayerId, Checklist, true).

battle_check(_PlayerId, [], Result) -> Result;

battle_check(PlayerId, [{dungeon_process, MonsterUniqueId} | Rest], Result) ->
	DungeonProcessRec = data_dungeon:process(MonsterUniqueId),
	{_SceneId, X, Y} = scene:get_position(PlayerId),
	DistanceCheck = ((erlang:abs(DungeonProcessRec#dungeon_process.x - X) =< ?BATTLE_DISTANCE) andalso
			 			(erlang:abs(DungeonProcessRec#dungeon_process.y - Y) =< ?BATTLE_DISTANCE)),
	Result1 = mod_dungeon:check_process(PlayerId, MonsterUniqueId),
	?INFO(battle,"DistanceCheck = ~w, Result1 = ~w",[DistanceCheck,Result1]),
	battle_check(PlayerId, Rest, (Result andalso Result1 andalso DistanceCheck));

battle_check(PlayerId,[{marstower, MonsterUniqueId}|Rest],Result) ->
	Result1 = mod_marstower:check_battle(PlayerId,MonsterUniqueId),
	battle_check(PlayerId, Rest, (Result andalso Result1)).










