%% Author: xierongfeng
%% Created: 2013-2-24
%% Description:    
-module(mof_common).

%%
%% Include files
%%
-include("mgeem.hrl").
-include("fight.hrl").

%%
%% Exported Functions
%%
-export([
	is_alive/1,
	is_friend/3,
	is_enemy/3,
	in_range/3,
	is_pos_safe/2,
	check_protect_lv/3,
	check_can_help/6,
	check_can_help_self/4,
	check_can_attack/7,
	is_dizzy/1,
	is_slient/1,
	is_disarmed/1,
	get_pos/1,
	get_skill_pos/5, 
	get_all_targets/3,
	get_around_targets/3,
	get_fight_attr/1,
	erase_role_fight_attr/1,
	erase_attack_result/0,
	get_attack_result/0,
	put_attack_result/1,
	add_attack_result/1,
	add_already_dead/1,
	actor_type_atom/1,
	actor_type_int/1,
	is_active/1,
	if_crit/2,
	is_invisible/1,
	is_unbeatable/1,
	is_no_gain_nuqi/1
]).

%%
%% API Functions
%%
is_alive(#p_map_role{state=?ROLE_STATE_DEAD})  -> false;
is_alive(#p_map_monster{state=?DEAD_STATE})    -> false;
is_alive(#p_map_server_npc{state=?DEAD_STATE}) -> false;
is_alive(#p_map_ybc{hp=HP}) when HP =< 0       -> false;
is_alive(#p_map_pet{hp=HP}) when HP =< 0       -> false;
is_alive(Others)                               -> Others =/= undefined.

is_friend(CasterAttr, TargetAttr, TargetMapInfo) ->
	not is_enemy(CasterAttr, TargetAttr, TargetMapInfo) == true.
	
is_enemy(CasterAttr, TargetAttr, TargetMapInfo) ->
	#actor_fight_attr{
		actor_id   = CasterID,
		actor_type = CasterType,
		pk_mode    = CasterPkMode, 
		faction_id = CasterFation,
		family_id  = CasterFamily,
		team_id    = CasterTeamID
	} = CasterAttr,
	#actor_fight_attr{
		actor_id   = TargetID,
		actor_type = TargetType,
		faction_id = TargetFation,
		family_id  = TargetFamily,
		team_id	   = TargetTeamID
	} = TargetAttr,
	if
		CasterType   == TargetType, CasterID == TargetID ->
			{false, <<"不能攻击自己">>};
		TargetType   == ?TYPE_MONSTER ->
			true;
		CasterPkMode == ?PK_PEACE ->
			{false, <<"和平模式下不能发起攻击">>};
		CasterPkMode == ?PK_TEAM,
		CasterTeamID > 0,
		CasterTeamID == TargetTeamID ->
			{false, <<"队伍模式下不能攻击队友">>};
		CasterPkMode == ?PK_FAMILY,
		CasterFamily > 0,
		CasterFamily == TargetFamily ->
			{false, <<"家庭模式下不能攻击同一家族的玩家">>};
		CasterPkMode == ?PK_FACTION,
		CasterFation == TargetFation ->
			{false, <<"势力模式下不能攻击同一势力的玩家">>};
		CasterPkMode == ?PK_MASTER, 
		TargetType   == ?TYPE_SERVER_NPC ->
			{false, <<"无效的目标">>};
		CasterPkMode == ?PK_MASTER, 
		TargetType   == ?TYPE_ROLE orelse TargetType == ?TYPE_PET ->
			RoleMapInfo = case TargetType of
				?TYPE_ROLE ->
					TargetMapInfo;
				?TYPE_PET ->
					PetMapInfo = mod_map_pet:get_map_info(TargetID, pet),
					mod_map_role:get_map_info(PetMapInfo#p_map_pet.role_id, role)
			end,
			TargetPKPoints = RoleMapInfo#p_map_role.pk_point,
			TargetGrayName = RoleMapInfo#p_map_role.gray_name,
			if
				TargetPKPoints > 18; TargetGrayName ->
					true;
				true ->
					{false, <<"无效的目标">>}
			end; 
		TargetType == ?TYPE_YBC ->
			#p_map_ybc{
				creator_id = YbcCreatorID,
				can_attack = YbcCanAttack,
				group_id   = YbcFamily
			} = TargetMapInfo,
			if
				not YbcCanAttack ->
					{false, <<"不能攻击这个镖车">>};
				YbcCreatorID == CasterAttr#actor_fight_attr.actor_id ->
					{false, <<"不能攻击自己的镖车">>};
				YbcFamily == CasterFamily andalso CasterFamily =/= 0 ->
					{false, <<"不能攻击同家一族的镖车">>};
				true ->
					true
			end;
		true ->
			true
	end.

get_pos(#p_map_role{pos=Pos})       -> Pos;
get_pos(#p_map_monster{pos=Pos})    -> Pos;
get_pos(#p_map_server_npc{pos=Pos}) -> Pos;
get_pos(#p_map_ybc{pos=Pos})        -> Pos;
get_pos(#p_map_pet{pos=Pos})        -> Pos;
get_pos(_)							-> undefined.

get_skill_pos(#p_skill{target_type=TargetType}, Caster, Target, Pos, Dir) ->
	SkillPos = if
		TargetType == ?TARGET_TYPE_SELF;
		TargetType == ?TARGET_TYPE_SELF_AROUND;
		TargetType == ?TARGET_TYPE_SELF_FRONT ->
			get_pos(Caster);
		TargetType == ?TARGET_TYPE_OTHER;
		TargetType == ?TARGET_TYPE_OTHER_AROUND;
		TargetType == ?TARGET_TYPE_OTHER_FRONT;
		TargetType == ?TARGET_TYPE_OTHER_LIMIT ->
			get_pos(Target);
		is_record(Pos, p_map_tile) ->
			#p_map_tile{tx=Tx, ty=Ty} = Pos,
			#p_pos{tx=Tx, ty=Ty};
		true ->
			Pos
	end,
	if
		is_record(SkillPos, p_pos), is_integer(Dir) ->
			SkillPos#p_pos{dir=Dir};
		true ->
			SkillPos
	end.

in_range(_Pos1, undefined, _) ->
	throw({error, 222, ?_LANG_FIGHT_ERROR_ACTOR_DEAD});
in_range(Pos1, Pos2, Distance) when Distance > 0 ->
	#p_pos{tx=X1, ty=Y1} = case is_record(Pos1, p_pos) of
		true ->
			Pos1;
		_ ->
			get_pos(Pos1)
	end,
	#p_pos{tx=X2, ty=Y2} = case is_record(Pos2, p_pos) of
		true ->
			Pos2;
		_ ->
			get_pos(Pos2)
	end,
	abs(X1-X2) =< Distance + 1 andalso abs(Y1-Y2) =< Distance + 1;
in_range(_Pos1, _Pos2, _Distance) ->
	true.

is_pos_safe(#map_state{mapid=MapID}, Pos) ->
	is_pos_safe(MapID, Pos);
is_pos_safe(MapID, #p_pos{tx=X, ty=Y}) ->
	SafeType = mcm:safe_type(MapID, {X, Y}),
	SafeType == safe orelse SafeType == absolute_safe;
is_pos_safe(_, _) -> false.

check_protect_lv(CasterAttr, TargetAttr, MapID) ->
	#actor_fight_attr{actor_type=CasterType, actor_level=CasterLv} = CasterAttr,
	#actor_fight_attr{actor_type=TargetType, actor_level=TargetLv} = TargetAttr,
	Protectlv = cfg_fight:protect_lv(),
	IsPVP = CasterType == ?TYPE_ROLE andalso (TargetType == ?TYPE_ROLE orelse TargetType == ?TYPE_PET), 
	case not IsPVP orelse cfg_fight:is_pvp_map(MapID) of
		false when CasterLv < Protectlv ->
			{error, ?_LANG_FIGHT_ATTACK_LESS_THAN_PROTECTED_LEVEL_IN_BORN_MAP};
		false when TargetLv < Protectlv -> 
			{error, ?_LANG_FIGHT_ATTACK_LESS_THAN_PROTECTED_LEVEL_IN_BORN_MAP2};
		_ ->
			ok
	end.

check_can_help(Caster, Target, CasterAttr, TargetAttr, Pos, SkillBaseInfo) ->
	is_alive(Caster) orelse throw({error, ?_LANG_FIGHT_ACTOR_DEAD}),
	Target == undefined orelse is_alive(Target) orelse throw({error, 222, ?_LANG_FIGHT_ERROR_ACTOR_DEAD}),
	Target == undefined orelse is_friend(CasterAttr, TargetAttr, Target) orelse throw({error, <<"无效的目标">>}),
	in_range(Caster, Pos, SkillBaseInfo#p_skill.distance) orelse throw({error, ?_LANG_FIGHT_NOT_IN_ATTACK_RANGE}),		
	check_debuff(CasterAttr, SkillBaseInfo#p_skill.id, []).

check_can_help_self(Caster, CasterAttr, SkillBaseInfo, SkillLevelInfo) ->
	mof_common:is_alive(Caster) orelse throw({error, ?_LANG_FIGHT_ACTOR_DEAD}),
	check_debuff(CasterAttr, SkillBaseInfo#p_skill.id, SkillLevelInfo#p_skill_level.effects).

check_can_attack(Caster, Target, CasterAttr, TargetAttr, Pos, SkillBaseInfo, MapState) ->
	is_alive(Caster) orelse throw({error, ?_LANG_FIGHT_ACTOR_DEAD}),
	Target == undefined orelse is_alive(Target) orelse throw({error, 222, ?_LANG_FIGHT_ERROR_ACTOR_DEAD}),
	Target == undefined orelse case is_enemy(CasterAttr, TargetAttr, Target) of
		{false, CantAttReason} -> throw({error, CantAttReason});
		true -> ok
	end,
	if is_record(Caster, p_map_role), 
	   is_record(Target, p_map_role) orelse is_record(Target, p_map_pet) orelse is_record(Target, p_map_ybc) ->
	    is_pos_safe(MapState, get_pos(Caster)) andalso throw({error, ?_LANG_FIGHT_TARGET_IN_SAFE_AREA}),
		is_pos_safe(MapState, Pos) andalso throw({error, ?_LANG_FIGHT_TARGET_IN_SAFE_AREA}),
		case check_protect_lv(CasterAttr, TargetAttr, MapState#map_state.mapid) of
			{error, Reason} ->
				throw({error,Reason});
			_ ->
				ignore
		end,
		hook_fight:check_fight_pk_mod(Caster, Target, MapState#map_state.mapid),
		hook_fight:check_fight_condition(Caster#p_map_role.role_id, 
			TargetAttr#actor_fight_attr.actor_id, TargetAttr#actor_fight_attr.actor_type);
	true ->
		ignore
	end,
	is_invisible(TargetAttr) andalso throw({ignore, invisible}),
	is_unbeatable(TargetAttr) andalso throw({error, <<"对方处于无敌状态，不受攻击">>}),
	in_range(Caster, Pos, SkillBaseInfo#p_skill.distance) orelse throw({error, ?_LANG_FIGHT_NOT_IN_ATTACK_RANGE}),		
	check_debuff(CasterAttr, SkillBaseInfo#p_skill.id, []).

is_invisible(ActorAttr) when is_record(ActorAttr, actor_fight_attr) ->
	lists:keymember(?BUFF_INVISIBLE, #p_actor_buf.buff_type, ActorAttr#actor_fight_attr.buffs);

is_invisible(_) -> false.

is_unbeatable(ActorAttr) when is_record(ActorAttr, actor_fight_attr) ->
	lists:keymember(?BUFF_UNBEATABLE, #p_actor_buf.buff_type, ActorAttr#actor_fight_attr.buffs);

is_unbeatable(_) -> false.	

is_no_gain_nuqi(ActorAttr) when is_record(ActorAttr, actor_fight_attr) ->
	lists:keymember(?BUFF_NO_NUQI, #p_actor_buf.buff_type, ActorAttr#actor_fight_attr.buffs);

is_no_gain_nuqi(_) -> false.
	
check_debuff(Caster, SkillID, Effects) ->
	#actor_fight_attr{actor_id=CasterID, buffs=Buffs} = Caster,
	CasterType = actor_type_atom(Caster#actor_fight_attr.actor_type),
	mof_skill_cast:is_casting(CasterType, CasterID) andalso throw({error, <<"正在进行另外一个动作">>}),
	cfg_fight:can_cast_when_slient(SkillID) orelse not is_slient(Buffs) orelse throw({error, <<"沉默状态不能使用技能">>}),
	CanClearDizzy = Effects =/= [] andalso lists:any(fun
		(Effect) -> Effect#p_effect.calc_type == ?CALC_TYPE_CLEAR_DIZZY
	end, Effects),
	CanClearDizzy orelse not is_dizzy(Buffs) orelse throw({error, ?_LANG_FIGHT_ACTOR_DIZZY}).

is_dizzy(Buffs) ->
	lists:keymember(?BUFF_DIZZY, #p_actor_buf.buff_type, Buffs).

is_slient(Buffs) ->
	lists:keymember(?BUFF_SLIENT, #p_actor_buf.buff_type, Buffs).

is_disarmed(Buffs) ->
	lists:keymember(?BUFF_DISARM, #p_actor_buf.buff_type, Buffs).

get_all_targets(#p_skill{target_type=?TARGET_TYPE_OTHER_AROUND, target_area=TargetArea}, Pos, CheckFun) ->
	get_around_targets(Pos, TargetArea, CheckFun);
get_all_targets(#p_skill{target_type=?TARGET_TYPE_OTHER_FRONT, target_area=TargetArea}, Pos, CheckFun) ->
	get_front_targets(Pos, TargetArea, CheckFun);
get_all_targets(#p_skill{target_type=?TARGET_TYPE_SELF_AROUND, target_area=TargetArea}, Pos, CheckFun) ->
	get_around_targets(Pos, TargetArea, CheckFun);
get_all_targets(#p_skill{target_type=?TARGET_TYPE_OTHER_LIMIT}, Pos, CheckFun) ->
	get_around_targets(Pos, 3, CheckFun);
get_all_targets(_, _, _) ->
	[].	

get_fight_attr(#p_map_role{role_id=RoleID}) ->
	case get({role_fight_attr, RoleID}) of
		undefined ->
			RoleFightAttr = get_role_fight_attr(RoleID),
			put({role_fight_attr, RoleID}, RoleFightAttr),
			RoleFightAttr;
		RoleFightAttr ->
			RoleFightAttr
	end;
get_fight_attr(#p_map_monster{monsterid=MonsterID}) ->
	#monster_state{monster_info=Monster} = mod_map_monster:get_monster_state(MonsterID),
	[MonsterBaseInfo] = cfg_monster:find(Monster#p_monster.typeid),
	#actor_fight_attr{
		actor_id         = MonsterID,
		actor_type		 = ?TYPE_MONSTER,
		actor_name       = Monster#p_monster.monstername,
		actor_level		 = MonsterBaseInfo#p_monster_base_info.level,
		pk_mode			 = ?PK_ALL,
		max_phy_attack   = Monster#p_monster.max_attack,
		min_phy_attack   = Monster#p_monster.min_attack, 
		max_magic_attack = Monster#p_monster.max_attack, 
		min_magic_attack = Monster#p_monster.min_attack,
		phy_defence      = Monster#p_monster.phy_defence,
		magic_defence    = Monster#p_monster.magic_defence,
		buffs            = Monster#p_monster.buffs,
		luck             = Monster#p_monster.lucky,
		no_defence       = Monster#p_monster.no_defence,
		miss             = Monster#p_monster.miss,
		double_attack    = Monster#p_monster.dead_attack,
		phy_anti         = Monster#p_monster.phy_anti,
		magic_anti       = Monster#p_monster.magic_anti,
		max_hp           = Monster#p_monster.max_hp,
		attack_speed     = Monster#p_monster.attack_speed,
		poisoning_resist = Monster#p_monster.poisoning_resist,
		dizzy_resist     = Monster#p_monster.dizzy_resist,
		freeze_resist    = Monster#p_monster.freeze_resist,
		hit_rate         = Monster#p_monster.hit_rate,
		block            = Monster#p_monster.block,
		wreck            = Monster#p_monster.wreck,
		tough            = Monster#p_monster.tough,
		vigour           = Monster#p_monster.vigour,
		week             = Monster#p_monster.week,
		molder           = Monster#p_monster.molder,
		hunger           = Monster#p_monster.hunger,
		bless            = Monster#p_monster.bless,
		crit             = Monster#p_monster.crit,
		bloodline        = Monster#p_monster.bloodline,
		phy_hurt_rate    = Monster#p_monster.phy_hurt_rate,
		magic_hurt_rate  = Monster#p_monster.magic_hurt_rate
	};
get_fight_attr(#p_map_server_npc{npc_id=NpcID}) ->
	#server_npc_state{server_npc_info=Npc} = mod_server_npc:get_server_npc_state(NpcID),
	[NpcBaseInfo] = common_config_dyn:find(server_npc, Npc#p_server_npc.type_id),
	#actor_fight_attr{
		actor_id         = NpcID,
		actor_type		 = ?TYPE_SERVER_NPC,
		actor_name       = Npc#p_server_npc.npc_name,
		actor_level		 = NpcBaseInfo#p_server_npc_base_info.level,
		faction_id		 = Npc#p_server_npc.npc_country,
		pk_mode			 = ?PK_FACTION,
		max_phy_attack   = Npc#p_server_npc.max_attack,
		min_phy_attack   = Npc#p_server_npc.min_attack,
		max_magic_attack = Npc#p_server_npc.max_attack,
		min_magic_attack = Npc#p_server_npc.min_attack,
		phy_defence      = Npc#p_server_npc.phy_defence,
		magic_defence    = Npc#p_server_npc.magic_defence,
		buffs            = Npc#p_server_npc.buffs,
		luck             = Npc#p_server_npc.lucky,
		no_defence       = Npc#p_server_npc.no_defence,
		miss             = Npc#p_server_npc.miss,
		double_attack    = Npc#p_server_npc.dead_attack,
		phy_anti         = Npc#p_server_npc.phy_anti,
		magic_anti       = Npc#p_server_npc.magic_anti,
		max_hp           = Npc#p_server_npc.max_hp,
		attack_speed     = Npc#p_server_npc.attack_speed,
		poisoning_resist = Npc#p_server_npc.poisoning_resist,
		dizzy_resist     = Npc#p_server_npc.dizzy_resist,
		freeze_resist    = Npc#p_server_npc.freeze_resist,
		hit_rate         = Npc#p_server_npc.hit_rate,
		block            = Npc#p_server_npc.block,
		wreck            = Npc#p_server_npc.wreck,
		tough            = Npc#p_server_npc.tough,
		vigour           = Npc#p_server_npc.vigour,
		week             = Npc#p_server_npc.week,
		molder           = Npc#p_server_npc.molder,
		hunger           = Npc#p_server_npc.hunger,
		bless            = Npc#p_server_npc.bless,
		crit             = Npc#p_server_npc.crit,
		bloodline        = Npc#p_server_npc.bloodline
	};
get_fight_attr(Ybc = #p_map_ybc{}) ->
	#actor_fight_attr{
		actor_id         = Ybc#p_map_ybc.ybc_id,
		actor_type		 = ?TYPE_YBC,
		actor_name       = Ybc#p_map_ybc.name,
		actor_level		 = 100,
		faction_id		 = Ybc#p_map_ybc.faction_id,
		family_id		 = Ybc#p_map_ybc.group_id,
		max_phy_attack   = 0,
		min_phy_attack   = 0,
		max_magic_attack = 0,
		min_magic_attack = 0,
		phy_defence      = Ybc#p_map_ybc.physical_defence,
		magic_defence    = Ybc#p_map_ybc.magic_defence,
		buffs            = [],
		luck             = 0,
		no_defence       = 0,
		miss             = 0,
		double_attack    = 0,
		phy_anti         = 0,
		magic_anti       = 0, 
		max_hp           = Ybc#p_map_ybc.max_hp, 
		attack_speed     = 0,
		poisoning_resist = 0,
		dizzy_resist     = 0,
		freeze_resist    = 0
	};
get_fight_attr(#p_map_pet{role_id=RoleID, pet_id=PetID}) ->
	Pet = mod_role_tab:get(RoleID, {?ROLE_PET_INFO, PetID}),
	#actor_fight_attr{
		actor_id         = PetID,
		actor_type		 = ?TYPE_PET,
		actor_level		 = Pet#p_pet.level,
		actor_name       = Pet#p_pet.pet_name,
		max_phy_attack   = Pet#p_pet.phy_attack,
		min_phy_attack   = Pet#p_pet.phy_attack,
		max_magic_attack = Pet#p_pet.magic_attack,
		min_magic_attack = Pet#p_pet.magic_attack,
		phy_defence      = Pet#p_pet.phy_defence,
		magic_defence    = Pet#p_pet.magic_defence,
		buffs            = Pet#p_pet.buffs,
		pk_mode          = Pet#p_pet.pk_mode,
		luck             = 0,
		no_defence       = 0,
		miss             = 0,
		double_attack    = Pet#p_pet.double_attack,  
		max_hp           = Pet#p_pet.max_hp, 
		attack_speed     = Pet#p_pet.attack_speed,
		poisoning_resist = 0,
		dizzy_resist     = 0,
		freeze_resist    = 0,
		block            = Pet#p_pet.block,
		wreck            = Pet#p_pet.wreck,
		tough            = Pet#p_pet.tough,
		vigour           = Pet#p_pet.vigour,
		week             = Pet#p_pet.week,
		molder           = Pet#p_pet.molder,
		hunger           = Pet#p_pet.hunger,
		bless            = Pet#p_pet.bless,
		crit             = Pet#p_pet.crit,
		bloodline        = Pet#p_pet.bloodline
	};
get_fight_attr(_) ->
	undefined.

get_role_fight_attr(RoleID) ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	RateAttr = case RoleBase#p_role_base.rate_attrs of
        undefined ->
            #p_rate_attrs{};
        Others ->
            Others
    end,
	#actor_fight_attr{
		actor_id		 = RoleID,
		actor_type		 = ?TYPE_ROLE,
		actor_name       = RoleBase#p_role_base.role_name,
		actor_level		 = RoleAttr#p_role_attr.level,
		category		 = case RoleAttr#p_role_attr.category of
			Category when Category == 1; Category == 2 ->
				phy;
			_ ->
				magic
		end,
		jingjie          = RoleAttr#p_role_attr.jingjie,
		juewei           = RoleAttr#p_role_attr.juewei,
		max_phy_attack   = trunc(RoleBase#p_role_base.max_phy_attack*(1+RateAttr#p_rate_attrs.physic_att_rate/10000)),
		min_phy_attack   = trunc(RoleBase#p_role_base.min_phy_attack*(1+RateAttr#p_rate_attrs.physic_att_rate/10000)), 
		max_magic_attack = trunc(RoleBase#p_role_base.max_magic_attack*(1+RateAttr#p_rate_attrs.magic_att_rate/10000)), 
		min_magic_attack = trunc(RoleBase#p_role_base.min_magic_attack*(1+RateAttr#p_rate_attrs.magic_att_rate/10000)),
		phy_defence      = trunc(RoleBase#p_role_base.phy_defence*(1+RateAttr#p_rate_attrs.physic_def_rate/10000)),
		magic_defence    = trunc(RoleBase#p_role_base.magic_defence*(1+RateAttr#p_rate_attrs.magic_def_rate/10000)),
		buffs            = RoleBase#p_role_base.buffs,
		luck             = RoleBase#p_role_base.luck,
		no_defence       = RoleBase#p_role_base.no_defence,
		miss             = RoleBase#p_role_base.miss,
		double_attack    = RoleBase#p_role_base.double_attack,
		phy_anti         = RoleBase#p_role_base.phy_anti,
		magic_anti       = RoleBase#p_role_base.magic_anti,
		pk_mode          = RoleBase#p_role_base.pk_mode,
		pk_points        = RoleBase#p_role_base.pk_points,
		team_id          = RoleBase#p_role_base.team_id,
		family_id        = RoleBase#p_role_base.family_id,
		faction_id       = RoleBase#p_role_base.faction_id,
		gray_name        = RoleBase#p_role_base.if_gray_name,
		max_hp           = trunc(RoleBase#p_role_base.max_hp*(1+RateAttr#p_rate_attrs.blood_rate/10000)),
		phy_hurt_rate    = RoleBase#p_role_base.phy_hurt_rate,
		magic_hurt_rate  = RoleBase#p_role_base.magic_hurt_rate,
		attack_speed     = RoleBase#p_role_base.attack_speed,
		dizzy            = RoleBase#p_role_base.dizzy,
		poisoning        = RoleBase#p_role_base.poisoning,
		freeze           = RoleBase#p_role_base.freeze,
		poisoning_resist = RoleBase#p_role_base.poisoning_resist,
		dizzy_resist     = RoleBase#p_role_base.dizzy_resist,
		freeze_resist    = RoleBase#p_role_base.freeze_resist,
		hurt_rebound     = RoleBase#p_role_base.hurt_rebound,
		hit_rate         = RoleBase#p_role_base.hit_rate,
		block            = RoleBase#p_role_base.block,
		wreck            = RoleBase#p_role_base.wreck,
		tough            = RoleBase#p_role_base.tough,
		vigour           = RoleBase#p_role_base.vigour,
		week             = RoleBase#p_role_base.week,
		molder           = RoleBase#p_role_base.molder,
		hunger           = RoleBase#p_role_base.hunger,
		bless            = RoleBase#p_role_base.bless,
		crit             = RoleBase#p_role_base.crit,
		bloodline        = RoleBase#p_role_base.bloodline
	}.

erase_role_fight_attr(RoleID) ->
	erlang:erase({role_fight_attr, RoleID}).

erase_attack_result() ->
	case erase(attack_result) of
		undefined ->
			[];
		List ->
			List
	end.

get_attack_result() ->
	case get(attack_result) of
		undefined ->
			[];
		List ->
			List
	end.

put_attack_result(Result) when is_list(Result) ->
	put(attack_result, Result).

add_attack_result(Result) when is_record(Result, p_attack_result) ->
	put_attack_result([Result|get_attack_result()]).

add_already_dead(Result) ->
	Key = already_dead,
	put(Key, [Result|case get(Key) of
		undefined ->
			[];
		List ->
			List
	end]).

actor_type_atom(?TYPE_ROLE) -> role;
actor_type_atom(?TYPE_MONSTER) -> monster;
actor_type_atom(?TYPE_SERVER_NPC) -> server_npc;
actor_type_atom(?TYPE_YBC) -> ybc;
actor_type_atom(?TYPE_PET) -> pet;
actor_type_atom(_) -> undefined.

actor_type_int(role) -> ?TYPE_ROLE;
actor_type_int(monster) -> ?TYPE_MONSTER;
actor_type_int(server_npc) -> ?TYPE_SERVER_NPC;
actor_type_int(ybc) -> ?TYPE_YBC;
actor_type_int(pet) -> ?TYPE_PET;
actor_type_int(_) -> 0.

if_crit(#actor_fight_attr{actor_level = CasterLevel, double_attack = CasterCritValue}, 
		#actor_fight_attr{actor_level = TargetLevel, tough         = TargetToughValue}) ->
	CasterCritRate = cfg_fight:crit_rate(CasterLevel, CasterCritValue),
	TargetToughRate = cfg_fight:tough_rate(TargetLevel, TargetToughValue),
	is_active(CasterCritRate - TargetToughRate).

is_active(Rate) when Rate > 0 ->
    common_tool:random(1, 10000) =< Rate;
is_active(_) ->
	false.

%%
%% Local Functions
%%
get_around_targets(#p_pos{tx=X, ty=Y, dir=D}, TargetArea, CheckFun) ->
	N = (TargetArea - 1) div 2,
	Vertex = case TargetArea rem 2 of
		0 ->
			if
				D == 7; D == 0; D == 1 ->
					{X-N-1, Y-N-1, X+N, Y+N};
				D == 3; D == 4; D == 5 ->
					{X-N, Y-N, X+N+1, Y+N+1};
				D == 2 ->
					{X-N, Y-N-1, X+N+1, Y+N};
				D == 6 ->
					{X-N-1, Y-N, X+N, Y+N+1};
				true ->
					{X-N-1, Y-N-1, X+N, Y+N}
			end;
		_ ->
			{X-N, Y-N, X+N, Y+N}
	end,
	get_targets({X-N, Y-N}, Vertex, CheckFun, []).

get_targets(Grid = {X, Y}, Vertex, CheckFun, Acc) ->
    case get({ref, X, Y}) of
     	undefined -> 
	        get_targets(next_grid(Grid, Vertex), Vertex, CheckFun, Acc);
	    List2 ->
			case get_targets2(List2, CheckFun, Acc) of
				{break, Acc2} ->
					Acc2;
				Acc2 ->
					get_targets(next_grid(Grid, Vertex), Vertex, CheckFun, Acc2)
			end
	end;
get_targets(_Grid, _Vertex, _CheckFun, Acc) ->
	Acc.

get_targets2([], _CheckFun, Acc) -> 
	Acc;
get_targets2([{ActorType, ActorID}|T], CheckFun, Acc) ->
	case CheckFun({ActorType, ActorID}) of
		{break, Actor} ->
			{break, [Actor|Acc]};
		{continue, Actor} ->
			get_targets2(T, CheckFun, [Actor|Acc]);
		false ->
			get_targets2(T, CheckFun, Acc)
	end.
	
next_grid({X, Y}, {_MinX, MinY, MaxX, MaxY}) ->
	if
		X >= MaxX, Y >= MaxY ->
			undefined;
		X < MaxX, Y >= MaxY ->
			{X+1, MinY};
		true ->
			{X, Y+1}
	end.


get_front_targets(#p_pos{tx=X, ty=Y, dir=D}, TargetArea, CheckFun) ->
	Vertex = 
		if
			D == 1 ->
				{X,Y,X,Y-TargetArea};
			D == 2 ->
				{X,Y,X+TargetArea,Y-TargetArea};
			D == 3 ->
				{X,Y,X+TargetArea,Y};
			D == 4 ->
				{X,Y, X+TargetArea,Y+TargetArea};
			D == 5 ->
				{X, Y, X,Y+TargetArea};
			D == 6 ->
				{X, Y, X-TargetArea,Y+TargetArea};
			D == 7 ->
				{X, Y, X-TargetArea,Y};
			D == 0 ->
				{X, Y, X-TargetArea,Y-TargetArea};
			true ->
				{X,Y,X,Y-TargetArea}
		end,
	get_front_targets({X, Y}, Vertex, CheckFun, []).

get_front_targets(Grid = {X, Y}, Vertex, CheckFun, Acc) ->
    case get({ref, X, Y}) of
     	undefined -> 
	        get_front_targets(next_front_grid(Grid, Vertex), Vertex, CheckFun, Acc);
	    List2 ->
			case get_front_targets2(List2, CheckFun, Acc) of
				{break, Acc2} ->
					Acc2;
				Acc2 ->
					get_front_targets(next_front_grid(Grid, Vertex), Vertex, CheckFun, Acc2)
			end
	end;
get_front_targets(_Grid, _Vertex, _CheckFun, Acc) ->
	Acc.

get_front_targets2([], _CheckFun, Acc) -> 
	Acc;
get_front_targets2([{ActorType, ActorID}|T], CheckFun, Acc) ->
	case CheckFun({ActorType, ActorID}) of
		{break, Actor} ->
			{break, [Actor|Acc]};
		{continue, Actor} ->
			get_front_targets2(T, CheckFun, [Actor|Acc]);
		false ->
			get_front_targets2(T, CheckFun, Acc)
	end.
	


next_front_grid({X, Y}, {StartX, StartY, EndX, EndY}) ->
	
	if
		StartX =:= EndX andalso  EndY < StartY ->
			if
				Y < EndY andalso X > EndX ->
					undefined;
				X =:= EndX andalso Y =:= EndY ->
					{StartX+1,StartY};
				true ->
					{X, Y-1}
			end;
		
		StartX =:= EndX andalso EndY > StartY ->
			if
				Y > EndY andalso X < EndX ->
					undefined;
				X =:= EndX andalso Y =:= EndY ->
					{StartX-1,StartY};
				true ->
					{X, Y+1}
			end;
		
		StartX > EndX andalso EndY =:= StartY ->
			if
				Y < EndY andalso X < EndX ->
					undefined;
				X =:= EndX andalso Y =:= EndY ->
					{StartX,StartY-1};
				true ->
					{X-1, Y}
			end;
		
		StartX < EndX andalso EndY =:= StartY ->
			if
				Y > EndY andalso X > EndX ->
					undefined;
				X =:= EndX andalso Y =:= EndY ->
					{StartX,StartY+1};
				true ->
					{X+1, Y}
			end;
		
		
		StartX > EndX andalso EndY < StartY ->
			if
				X < (EndX-1) ->
					undefined;
				X =:= EndX andalso Y =:= EndY ->
					{StartX,StartY-1};
				true ->
					{X-1, Y-1}
			end;
		
		
		StartX > EndX andalso EndY > StartY ->
			if
				X < (EndX-1) ->
					undefined;
				X =:= EndX andalso Y =:= EndY ->
					{StartX-1,StartY};
				true ->
					{X-1, Y+1}
			end;
		
		StartX < EndX andalso  EndY > StartY  ->
			if
				X > (EndX+1) ->
					undefined;
				X =:= EndX andalso Y =:= EndY ->
					{StartX+1,StartY};
				true ->
					{X+1, Y+1}
			end;
		
		StartX < EndX andalso  EndY < StartY ->
			if
				X > (EndX+1) ->
					undefined;
				X =:= EndX andalso Y =:= EndY ->
					{StartX+1,StartY};
				true ->
					{X+1, Y-1}
			end
	end.


		
			