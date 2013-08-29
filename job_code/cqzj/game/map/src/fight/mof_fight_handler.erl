%% Author: xierongfeng
%% Created: 2013-2-25
%% Description: 战斗模块入口
-module(mof_fight_handler).

%%
%% Include files
%%
-include("mgeem.hrl").

-define(_fight_attack, ?DEFAULT_UNIQUE, ?FIGHT, ?FIGHT_ATTACK).

%%
%% Exported Functions
%%
-export([handle/2, handle_result/6, handle_already_dead/2]).

%%
%% API Functions
%%
handle({_Unique, ?FIGHT, ?FIGHT_ATTACK, DataIn, RoleID, _PID, _Line}, MapState) ->
	#m_fight_attack_tos{
		skillid     = SkillID,
		target_id   = TargetID1, 
		target_type = TargetType1,
		tile		= Tile,
		dir			= Dir
	} = DataIn,
	Caster = get_actor_mapinfo(?TYPE_ROLE, RoleID),
	{ok, SkillBaseInfo} = mod_skill_manager:get_skill_info(SkillID),
	if SkillBaseInfo#p_skill.effect_type == ?SKILL_EFFECT_TYPE_SELF;
	   SkillBaseInfo#p_skill.target_type == ?TARGET_TYPE_SELF ->
			TargetType2 = role,
			TargetID2   = RoleID,
			Target      = Caster;
		true ->
			TargetType2 = TargetType1,
			TargetID2   = TargetID1,
			Target      = get_actor_mapinfo(TargetType1, TargetID1)
	end, 
	{ok, SkillLevel} = mod_skill_manager:get_actor_skill_level(RoleID, role, SkillID), 
	case mod_skill_manager:get_skill_level_info(SkillID, SkillLevel) of
		{ok, SkillLevelInfo} ->
			SkillPos   = mof_common:get_skill_pos(SkillBaseInfo, Caster, Target, Tile, Dir),
			Result     = dispatch(Caster, Target, SkillPos, SkillBaseInfo, SkillLevelInfo, MapState),
			CasterInfo = {?TYPE_ROLE, RoleID, mof_common:get_pos(Caster)},
			TargetInfo = {TargetType2, TargetID2, SkillPos},
			handle_result(CasterInfo, TargetInfo, SkillID, Dir, Result, MapState),
			handle_auto_attack(erase(auto_attack), MapState),
			handle_already_dead(erase(already_dead), MapState);
		_ ->
			?ERROR_LOG("获取不到技能信息:RoleID=~p, SkillID=~p, SkillLevel=~p", [RoleID, SkillID, SkillLevel])
	end;

handle({monster_attack, ?FIGHT, ?FIGHT_ATTACK, DataIn, MonsterID}, MapState) ->
	{TargetID,{SkillID,SkillLevel},TargetType} = DataIn,
	TargetTypeInt = mof_common:actor_type_int(TargetType),
	Caster = get_actor_mapinfo(?TYPE_MONSTER, MonsterID),
	Target = get_actor_mapinfo(TargetTypeInt, TargetID),
	{ok, SkillBaseInfo}  = mod_skill_manager:get_skill_info(SkillID),
	{ok, SkillLevelInfo} = mod_skill_manager:get_skill_level_info(SkillID, SkillLevel),
	CasterPos = mof_common:get_pos(Caster),
	TargetPos = mof_common:get_pos(Target),
	case is_record(CasterPos,p_pos) andalso is_record(TargetPos,p_pos) of
		true ->
			Dir        = common_misc:get_dir(CasterPos, TargetPos),
			Result     = dispatch(Caster, Target, TargetPos#p_pos{dir=Dir}, SkillBaseInfo, SkillLevelInfo, MapState),
			CasterInfo = {?TYPE_MONSTER, MonsterID, CasterPos},
			TargetInfo = {TargetTypeInt, TargetID,  TargetPos},
			handle_result(CasterInfo, TargetInfo, SkillID, Dir, Result, MapState),
			handle_auto_attack(erase(auto_attack), MapState);
		_ when is_record(CasterPos,p_pos) ->
			mod_map_monster:delete_role_from_monster_enemy_list(MonsterID,TargetID,TargetType);
		_ ->
			ingore
	end;

handle({server_npc_attack, ?FIGHT, ?FIGHT_ATTACK, DataIn, ServerNpcID}, MapState) ->
	{TargetID,{SkillID,SkillLevel},TargetType} = DataIn,
	TargetTypeInt = mof_common:actor_type_int(TargetType),
	Caster = get_actor_mapinfo(?TYPE_SERVER_NPC, ServerNpcID),
	Target = get_actor_mapinfo(TargetTypeInt, TargetID),
	{ok, SkillBaseInfo}  = mod_skill_manager:get_skill_info(SkillID),
	{ok, SkillLevelInfo} = mod_skill_manager:get_skill_level_info(SkillID, SkillLevel),
	CasterPos = mof_common:get_pos(Caster),
	TargetPos = mof_common:get_pos(Target),
	case is_record(CasterPos,p_pos) andalso is_record(TargetPos,p_pos) of
		true ->
			Dir        = common_misc:get_dir(CasterPos, TargetPos),
			Result     = dispatch(Caster, Target, TargetPos#p_pos{dir=Dir}, SkillBaseInfo, SkillLevelInfo, MapState),
			CasterInfo = {?TYPE_SERVER_NPC, ServerNpcID, CasterPos},
			TargetInfo = {TargetTypeInt, TargetID, TargetPos},
			handle_result(CasterInfo, TargetInfo, SkillID, Dir, Result, MapState),
			handle_auto_attack(erase(auto_attack), MapState);
		_ ->
			ignore
	end.

handle_result(CasterInfo, TargetInfo, SkillID, Dir, Result, MapState) ->
	{CasterType, CasterID, CasterPos} = CasterInfo,
	{TargetType, TargetID, TargetPos} = TargetInfo,
	case Result of
		{error, Reason} when CasterType == ?TYPE_ROLE ->
			Toc = #m_fight_attack_toc{
				succ        = false,
				reason      = Reason,
				target_type = TargetType,
				target_id   = TargetID
			},
			common_misc:unicast({role, CasterID}, ?_fight_attack, Toc);
		{error, ReasonCode, Reason} when CasterType == ?TYPE_ROLE ->
			Toc = #m_fight_attack_toc{
				succ        = false,
				reason_code = ReasonCode,
				reason      = Reason,
				target_type = TargetType,
				target_id   = TargetID
			},
			common_misc:unicast({role, CasterID}, ?_fight_attack, Toc);
		ResultLst when is_list(ResultLst) ->
			Toc = #m_fight_attack_toc{
				succ        = true,
				src_id		= CasterID,
				skillid 	= SkillID,
				src_pos		= CasterPos,
				src_type	= CasterType,
				result 		= ResultLst,
				dir 		= Dir,
				dest_pos 	= TargetPos,
				target_type = TargetType,
				target_id   = TargetID
			},
			case CasterType of
				?TYPE_ROLE ->
					common_misc:unicast({role, CasterID}, ?_fight_attack, Toc);
				_ ->
					ignore
			end,
			TX      = TargetPos#p_pos.tx,
			TY      = TargetPos#p_pos.ty,
			OffsetX = MapState#map_state.offsetx,
		    OffsetY = MapState#map_state.offsety,
		    case mgeem_map:get_9_slice_by_txty(TX, TY, OffsetX, OffsetY) of
		        undefined -> ignore;
		        Slices ->
		            AllInSenceRole1 = mgeem_map:get_all_in_sence_user_by_slice_list(Slices),
		            AllInSenceRole2 = case CasterType of
						?TYPE_ROLE -> AllInSenceRole1 -- [CasterID];
						_          -> AllInSenceRole1
					end,
					ToOthers = Toc#m_fight_attack_toc{return_self = false},
		            mgeem_map:broadcast(AllInSenceRole2, ?DEFAULT_UNIQUE, ?FIGHT, ?FIGHT_ATTACK, ToOthers)
		    end;
		_ ->
			ignore
	end.

handle_auto_attack({combos, CombosNum, CasterAttr, TargetAttr, Damage}, MapState) ->
	#actor_fight_attr{actor_id=CasterID, actor_type=CasterType} = CasterAttr,
	#actor_fight_attr{actor_id=TargetID, actor_type=TargetType} = TargetAttr,
	CasterPos = mod_map_actor:get_actor_pos(CasterID, mof_common:actor_type_atom(CasterType)),
	TargetPos = mod_map_actor:get_actor_pos(TargetID, mof_common:actor_type_atom(TargetType)),
	case is_record(CasterPos, p_pos) andalso is_record(TargetPos, p_pos) of
		true ->
			CasterInfo = {CasterType, CasterID, CasterPos},
			TargetInfo = {TargetType, TargetID, TargetPos},
			Dir        = common_misc:get_dir(CasterPos, TargetPos),
			Result     = mof_combos_attack:handle(CombosNum, TargetAttr, CasterAttr, Damage, MapState),
			handle_result(CasterInfo, TargetInfo, 9+CombosNum, Dir, Result, MapState),
			handle_auto_attack(erase(auto_attack), MapState);
		_ ->
			ignore
	end;

handle_auto_attack(_, _MapState) ->
	ignore.

handle_already_dead(undefined, _MapState) ->
	ignore;
handle_already_dead(AlreadyDead, MapState) ->
	lists:foreach(fun
		({Tx, TY, Module, Method, DataRecord}) ->
			mgeem_map:do_broadcast_insence_by_txty(Tx, TY, Module, Method, DataRecord, MapState)
	end, AlreadyDead).

%%
%% Local Functions
%%
get_actor_mapinfo(?TYPE_ROLE, ID)       -> mod_map_actor:get_actor_mapinfo(ID, role);
get_actor_mapinfo(?TYPE_PET,  ID)       -> mod_map_actor:get_actor_mapinfo(ID, pet);
get_actor_mapinfo(?TYPE_MONSTER, ID)    -> mod_map_actor:get_actor_mapinfo(ID, monster);
get_actor_mapinfo(?TYPE_SERVER_NPC, ID) -> mod_map_actor:get_actor_mapinfo(ID, server_npc);
get_actor_mapinfo(?TYPE_YBC, ID)        -> mod_map_actor:get_actor_mapinfo(ID, ybc);
get_actor_mapinfo(_Type, _ID)			-> undefined.

dispatch(Caster, Target, SkillPos, SkillBaseInfo, SkillLevelInfo, MapState) ->
	try
		SkillHandler = case cfg_fight:get_skill_handler(SkillBaseInfo#p_skill.id) of
			mof_undefined when SkillBaseInfo#p_skill.contain_common_attack ->
				mof_normal_attack;
			mof_undefined ->
				mof_skill_attack;
			SkillHandler2 ->
				SkillHandler2
		end,
		SkillHandler:handle(Caster, Target, SkillPos, SkillBaseInfo, SkillLevelInfo, MapState)
	catch
		_:{error, Reason} ->
			{error, Reason};
		_:{error, ReasonCode, Reason} ->
			{error, ReasonCode, Reason};
		_:ResultLst when is_list(ResultLst) ->
			ResultLst;
		_:{ignore, _Reason} -> ignore;
		_:Reason ->
			?ERROR_MSG("FIGHT ERROR: ~w ~w", [Reason, erlang:get_stacktrace()]),
			{error, <<"系统错误">>}
	end.
	