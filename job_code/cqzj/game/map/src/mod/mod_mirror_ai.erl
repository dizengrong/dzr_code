%% Author: xierf
%% Created: 2012-5-22
%% Description: 镜像AI模块
-module(mod_mirror_ai).

%%
%% Include files
%%
-include("mgeem.hrl"). 
-include("mirror.hrl").

-define(IS_ALIVE(Actor), (
 (is_record(Actor, p_map_role) andalso Actor#p_map_role.state /= ?ROLE_STATE_DEAD) 
	 orelse (is_record(Actor, p_map_pet) andalso Actor#p_map_pet.state /= ?DEAD_STATE)
)).

%%
%% Exported Functions
%%
-export([loop_ms/2, 
		 add_ai_state/3, 
		 del_ai_state/2, 
		 add_stop_driver/2,
		 add_follow_driver/5, 
		 add_attack_driver/6, 
		 add_skill_driver/6,
		 add_prepare_driver/4]).

%%
%% API Functions
%%
loop_ms(NowTime, MapID) when ?IS_MIRROR_FB(MapID) ->
	[case get_ai_state(ActorType, ActorID) of
	 AiState when is_record(AiState, ai_state), AiState#ai_state.work_time =< NowTime ->
		 case mod_map_actor:get_actor_mapinfo(AiState#ai_state.enemy_id, role) of
		 EnemyMapInfo when ?IS_ALIVE(EnemyMapInfo) ->
			 case mod_map_actor:get_actor_mapinfo(ActorID, ActorType) of
			 ActorMapInfo when ?IS_ALIVE(ActorMapInfo) ->
				 NewAiState = drive(AiState#ai_state{work_time=NowTime+?WORK_TICK}, ActorMapInfo, NowTime),
				 set_ai_state(ActorType, ActorID, work(NowTime, NewAiState));
			 _ ->
				 ignore
			 end;
		 _ ->
			 ignore
		 end;
	 _ ->
		 ignore
	 end||{ActorType, ActorID} <- mod_mirror:mirrors()];

loop_ms(_, _) ->
	ignore.

add_ai_state(ActorType, ActorID, EnemyID) ->
	AiState = #ai_state{actor_type=ActorType, 
						actor_id=ActorID, 
						role_id=role_id(ActorType, ActorID), 
						enemy_id=EnemyID},
	set_ai_state(ActorType, ActorID, AiState).

del_ai_state(ActorType, ActorID) ->
	erase({ai_state, ActorType, ActorID}).

add_stop_driver(MirrorActorType, MirrorActorID) ->
	AiState = get_ai_state(MirrorActorType, MirrorActorID),
	StopDriver = #ai_driver{id=stop, interval=?WORK_TICK, time=common_tool:now2(), msg=stop},
	set_ai_state(MirrorActorType, MirrorActorID, AiState#ai_state{stop_driver=StopDriver}).

add_follow_driver(MirrorActorType, MirrorActorID, FollowActorType, FollowActorID, MinDistance) ->
	AiState = get_ai_state(MirrorActorType, MirrorActorID),
	Msg = {follow, FollowActorType, FollowActorID, MinDistance},
	FollowDriver = #ai_driver{id=follow, time=common_tool:now2(), interval=?WORK_TICK, msg=Msg},
	set_ai_state(MirrorActorType, MirrorActorID, AiState#ai_state{follow_driver=FollowDriver}).

add_attack_driver(MirrorActorType, MirrorActorID, TargetActorType, TargetActorID, AttackDistance, SkillID) ->
	AiState = get_ai_state(MirrorActorType, MirrorActorID),
	Msg = {attack, TargetActorType, TargetActorID, AttackDistance, SkillID},
	AttackDriver = #ai_driver{id=attack, time=common_tool:now2(), interval=?WORK_TICK, msg=Msg},
	set_ai_state(MirrorActorType, MirrorActorID, AiState#ai_state{attack_driver=AttackDriver}).

add_skill_driver(MirrorActorType, MirrorActorID, TargetActorType, TargetActorID, SkillID, SkillLevel) ->
	case mod_skill_manager:get_skill_info(SkillID) of
	{ok, #p_skill{attack_type=?ATTACK_TYPE_ACTIVE, effect_type=EffectType, distance=Distance}} ->
		{ok, #p_skill_level{cool_time=CD, consume_mp=RequireMP}} = mod_skill_manager:get_skill_level_info(SkillID, SkillLevel),
		AiState = get_ai_state(MirrorActorType, MirrorActorID),
		SkillType = cfg_mirror:skill_type(SkillID),
		case if
			 SkillType  == undefined ->
			 	 ignore;
			 EffectType == ?SKILL_EFFECT_TYPE_SELF;
			 EffectType == ?SKILL_EFFECT_TYPE_FRIEND;
			 EffectType == ?SKILL_EFFECT_TYPE_FRIEND_ROLE ->
				 {skill, new_skill_driver_index(AiState), SkillID, MirrorActorType, MirrorActorID, Distance, RequireMP, CD};
			 EffectType == ?SKILL_EFFECT_TYPE_ENEMY;
			 EffectType == ?SKILL_EFFECT_TYPE_ENEMY_ROLE ->
				 {skill, new_skill_driver_index(AiState), SkillID, TargetActorType, TargetActorID, Distance, RequireMP, CD};
			 EffectType == ?SKILL_EFFECT_TYPE_MASTER ->
				 {skill, new_skill_driver_index(AiState), SkillID, role, AiState#ai_state.role_id, Distance, RequireMP, CD};
			 true ->
				 ignore
			 end of
		ignore ->
			ignore;
		Msg ->
			DriverIndex = element(2, Msg),
			SkillDriver = #ai_driver{id={SkillID, SkillLevel}, time=common_tool:now2(), interval=?WORK_TICK, msg=Msg},
			set_ai_state(MirrorActorType, MirrorActorID, setelement(DriverIndex, AiState, SkillDriver))
		end;
	_ ->
		ignore
	end.

add_prepare_driver(MirrorActorType, MirrorActorID, SkillID, SkillLevel) ->
	cfg_mirror:skill_type(SkillID) =/= attack 
	andalso case mod_skill_manager:get_skill_info(SkillID) of
	{ok, #p_skill{attack_type=?ATTACK_TYPE_ACTIVE, effect_type=EffectType, distance=Distance}} ->
		{ok, #p_skill_level{cool_time=CD, consume_mp=RequireMP}} = mod_skill_manager:get_skill_level_info(SkillID, SkillLevel),
		AiState = get_ai_state(MirrorActorType, MirrorActorID),
		SkillType = cfg_mirror:skill_type(SkillID),
		case if
			 SkillType  == undefined ->
			 	 ignore;
			 EffectType == ?SKILL_EFFECT_TYPE_SELF;
			 EffectType == ?SKILL_EFFECT_TYPE_FRIEND_ROLE ->
				 {skill, new_skill_driver_index(AiState), SkillID, MirrorActorType, MirrorActorID, Distance, RequireMP, CD};
			 EffectType == ?SKILL_EFFECT_TYPE_MASTER ->
				 {skill, new_skill_driver_index(AiState), SkillID, role, AiState#ai_state.role_id, Distance, RequireMP, CD};
			 true ->
				 ignore
			 end of
		ignore ->
			ignore;
		Msg ->
			DriverIndex = element(2, Msg),
			SkillDriver = #ai_driver{id={SkillID, SkillLevel}, time=common_tool:now2(), interval=?WORK_TICK, msg=Msg},
			set_ai_state(MirrorActorType, MirrorActorID, setelement(DriverIndex, AiState, SkillDriver))
		end;
	_ ->
		ignore
	end.

%%
%% Local Functions
%%
get_ai_state(ActorType, ActorID) ->
	get({ai_state, ActorType, ActorID}).

set_ai_state(ActorType, ActorID, State) ->
	put({ai_state, ActorType, ActorID}, State).

work(NowTime, AiState = #ai_state{msgs=Msgs, active=true}) ->
	work(Msgs, NowTime, AiState#ai_state{msgs=[]});

work(_NowTime, AiState) ->
	AiState.

work([{_Priority, Msg}|RestMsgs], NowTime, AiState = #ai_state{active=true}) ->
	work(RestMsgs, NowTime, handle(Msg, NowTime, AiState));

work(_, _NowTime, AiState) ->
	AiState.

drive(AiState, ActorMapInfo, NowTime) ->
	drive(#ai_state.stop_driver, AiState, ActorMapInfo, NowTime).

drive(Index, AiState, ActorMapInfo, NowTime) when Index < #ai_state.skill15_driver ->
	case element(Index, AiState) of
	Driver when is_record(Driver, ai_driver), Driver#ai_driver.time < NowTime ->
		#ai_driver{id=DriverID, interval=DriveInterval, msg=Msg} = Driver,
		case mod_mirror_ai_pr:priority(DriverID, ActorMapInfo) of
		ignore ->
			drive(Index+1, AiState, ActorMapInfo, NowTime);
		Priority ->
			NewDriver = Driver#ai_driver{time=NowTime+DriveInterval},
			NewMessages = ordsets:add_element({Priority, Msg}, AiState#ai_state.msgs),
			NewAiState = setelement(Index, AiState#ai_state{active=true, msgs=NewMessages}, NewDriver),
			if
				Priority > 0 ->
					drive(Index+1, NewAiState, ActorMapInfo, NowTime);
				true ->
					NewAiState
			end
		end;
	_ ->
		drive(Index+1, AiState, ActorMapInfo, NowTime)
	end;

drive(_Index, AiState, _ActorMapInfo, _NowTime) ->
	AiState.

%%停止
handle(stop, Now, AiState) ->
	AiState#ai_state{active=false, work_time=Now+?WORK_TICK};

%%跟踪
handle({follow, role, FollowActorID, MinDinstance}, Now, AiState) ->
	#ai_state{actor_id=MirrorActorID, actor_type=role} = AiState,
	#p_map_role{move_speed=MoveSpeed, pos=MirrorPos} = mod_map_actor:get_actor_mapinfo(MirrorActorID, role),
	#p_pos{tx=MirrorTx, ty=MirrorTy} = MirrorPos,
	#p_pos{tx=FollowTx, ty=FollowTy} = mod_map_actor:get_actor_pos(FollowActorID, role),
	case in_distance({MirrorTx, MirrorTy}, {FollowTx, FollowTy}, MinDinstance) of
	true ->
		AiState;
	false ->
		{FirstTx, FirstTy, FirstDir} = get_first_walk_pos(MirrorPos, #p_pos{tx=FollowTx, ty=FollowTy}),
		MapState = mgeem_map:get_state(),
		DataIn1  = #m_move_walk_tos{pos=#p_pos{tx=FirstTx, ty=FirstTy, dir=FirstDir}},
		mod_move:handle({?DEFAULT_UNIQUE, ?MOVE, ?MOVE_WALK, DataIn1, MirrorActorID, mirror, undefined}, MapState),
		Path = [#p_map_tile{tx=MirrorTx, ty=MirrorTy},#p_map_tile{tx=FirstTx, ty=FirstTy}],
		DataIn2 = #m_move_walk_path_tos{walk_path=#p_walk_path{bpx=0, bpy=0, epx=0, epy=0, path=Path}},
		mod_move:handle({?DEFAULT_UNIQUE, ?MOVE, ?MOVE_WALK_PATH, DataIn2, MirrorActorID, mirror, undefined}, MapState),
		WalkInterval = mod_walk:get_move_speed_time(MoveSpeed+40, FirstDir),
		FollowDriver = AiState#ai_state.follow_driver,
		AiState#ai_state{active=false, work_time=Now+WalkInterval, follow_driver=FollowDriver#ai_driver{time=Now+WalkInterval}}
	end;

%%攻击
handle({attack, TargetActorType, TargetActorID, AttDistance, SkillID}, Now, AiState) ->
	#ai_state{actor_type=MirrorActorType, actor_id=MirrorActorID, role_id=MirrorRoleID} = AiState,
	MirrorMapInfo = mod_map_actor:get_actor_mapinfo(MirrorActorID, MirrorActorType),
	TargetMapInfo = mod_map_actor:get_actor_mapinfo(TargetActorID, TargetActorType),
	#p_pos{tx=MirrorTx, ty=MirrorTy} = pos(MirrorMapInfo),
	#p_pos{tx=TargetTx, ty=TargetTy} = pos(TargetMapInfo),
	case in_distance({MirrorTx, MirrorTy}, {TargetTx, TargetTy}, AttDistance) andalso is_visibile(TargetMapInfo) of
	true ->
		DataIn = #m_fight_attack_tos{
			tile        = #p_map_tile{tx=TargetTx,ty=TargetTy},
			skillid     = SkillID,
			target_id   = TargetActorID,
			target_type = actor_type_int(TargetActorType),
			src_type    = actor_type_int(MirrorActorType),
			dir         = common_misc:get_dir({MirrorTx, MirrorTy}, {TargetTx, TargetTy})
		},
		MapState = mgeem_map:get_state(),
		mof_fight_handler:handle({?DEFAULT_UNIQUE, ?FIGHT, ?FIGHT_ATTACK, DataIn, MirrorRoleID, mirror, undefined}, MapState),
		AttackInterval = round(1000000/attack_speed(MirrorActorType, MirrorActorID)),
		AttackDriver = AiState#ai_state.attack_driver,
		AiState#ai_state{active=false, work_time=Now+AttackInterval, attack_driver=AttackDriver#ai_driver{time=Now+AttackInterval}};
	false ->
		AiState
	end;

%%技能
handle({skill, DriverIndex, SkillID, TargetActorType, TargetActorID, Distance, RequireMP, CD}, Now, AiState) ->
	#ai_state{actor_type=MirrorActorType, actor_id=MirrorActorID, role_id=MirrorRoleID} = AiState,
	MirrorMapInfo = mod_map_actor:get_actor_mapinfo(MirrorActorID, MirrorActorType),
	TargetMapInfo = mod_map_actor:get_actor_mapinfo(TargetActorID, TargetActorType),
	#p_pos{tx=MirrorTx, ty=MirrorTy, dir=MirrorDir} = pos(MirrorMapInfo),
	#p_pos{tx=TargetTx, ty=TargetTy} = pos(TargetMapInfo),
	{ok, SkillLevel} = mod_skill:get_role_skill_level(MirrorActorID, SkillID),
	case in_distance({MirrorTx, MirrorTy}, {TargetTx, TargetTy}, Distance) andalso is_visibile(TargetMapInfo) of
	true ->
		case mp(MirrorMapInfo) >= RequireMP
				andalso nuqi(MirrorActorType, MirrorActorID) + cfg_role_nuqi:add_nuqi(SkillID,SkillLevel) > 0 of
		true ->
			DataIn = #m_fight_attack_tos{
				tile        = #p_map_tile{tx = TargetTx,ty = TargetTy},
				skillid     = SkillID,
				target_id   = TargetActorID,
				target_type = actor_type_int(TargetActorType),
				src_type    = actor_type_int(MirrorActorType),
				dir         = case {MirrorTx, MirrorTy} == {TargetTx, TargetTy} of
					true ->
					   MirrorDir;
					false ->
					   common_misc:get_dir({MirrorTx, MirrorTy}, {TargetTx, TargetTy})
				end
			},
			MapState=mgeem_map:get_state(),
			mof_fight_handler:handle({?DEFAULT_UNIQUE, ?FIGHT, ?FIGHT_ATTACK, DataIn, MirrorRoleID, mirror, undefined}, MapState),
			SkillDriver = element(DriverIndex, AiState),
			AttackInterval = round(1000000/attack_speed(MirrorActorType, MirrorActorID)),
			setelement(DriverIndex, AiState#ai_state{work_time=Now+AttackInterval, active=false}, SkillDriver#ai_driver{time=Now+CD});
		_ ->
			AiState
		end;
	false ->
		AiState
	end.

new_skill_driver_index(AiState) ->
	if
	AiState#ai_state.skill1_driver == undefined -> #ai_state.skill1_driver;
	AiState#ai_state.skill2_driver == undefined -> #ai_state.skill2_driver;
	AiState#ai_state.skill3_driver == undefined -> #ai_state.skill3_driver;
	AiState#ai_state.skill4_driver == undefined -> #ai_state.skill4_driver;
	AiState#ai_state.skill5_driver == undefined -> #ai_state.skill5_driver;
	AiState#ai_state.skill6_driver == undefined -> #ai_state.skill6_driver;
	AiState#ai_state.skill7_driver == undefined -> #ai_state.skill7_driver;
	AiState#ai_state.skill8_driver == undefined -> #ai_state.skill8_driver;
	AiState#ai_state.skill9_driver == undefined -> #ai_state.skill9_driver;
	AiState#ai_state.skill10_driver == undefined -> #ai_state.skill10_driver;
	AiState#ai_state.skill11_driver == undefined -> #ai_state.skill11_driver;
	AiState#ai_state.skill12_driver == undefined -> #ai_state.skill12_driver;
	AiState#ai_state.skill13_driver == undefined -> #ai_state.skill13_driver;
	AiState#ai_state.skill14_driver == undefined -> #ai_state.skill14_driver;
	AiState#ai_state.skill15_driver == undefined -> #ai_state.skill15_driver
	end.

get_first_walk_pos(FromPos, ToPos) ->
	{ok, WalkPath} = mod_walk:get_walk_path(FromPos, ToPos),
	lists:nth(2, WalkPath).

role_id(role, RoleID) -> 
	RoleID;
role_id(pet, PetID) -> 
	#p_map_pet{role_id=RoleID} = mod_map_actor:get_actor_mapinfo(PetID, pet),
	RoleID.

actor_type_int(role) -> 
	?TYPE_ROLE;
actor_type_int(pet) -> 
	?TYPE_PET.

attack_speed(role, RoleID) ->
	{ok, #p_role_base{attack_speed=AttackSpeed}} = mod_map_role:get_role_base(RoleID),
	AttackSpeed;
attack_speed(pet, PetID) ->
	#p_map_pet{attack_speed=AttackSpeed} = mod_map_pet:get_map_actor(PetID, pet),
	AttackSpeed.

mp(#p_map_role{mp=Mp}) ->
	Mp;
mp(_) ->
	undefined.

nuqi(role, RoleID) ->
	{ok, RoleFight} = mod_map_role:get_role_fight(RoleID),
	RoleFight#p_role_fight.nuqi;
nuqi(pet, _PetID) ->
	undefined.

pos(#p_map_role{pos=Pos}) ->
	Pos;
pos(#p_map_pet{pos=Pos}) ->
	Pos.

in_distance({MirrorTx, MirrorTy}, {TargetTx, TargetTy}, Distance) ->
	abs(MirrorTx-TargetTx) =< Distance andalso abs(MirrorTy-TargetTy) =< Distance.

is_visibile(#p_map_role{state_buffs=StateBuffs}) ->
	not lists:any(fun
		(#p_actor_buf{buff_type=Type}) ->
			case common_config_dyn:find(buff_type, Type) of
				[Atom] when Atom == hidden_to_other;
						  	Atom == hidden_not_move ->
				  true;
				_ ->
				  false
			end
	end, StateBuffs);

is_visibile(_PetMapInfo) ->
	true.
