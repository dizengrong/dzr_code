%% Author: xierongfeng
%% Created: 2013-2-25
%% Description:
-module(mof_before_attack).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([handle/6, change_skill/4]).

%%
%% API Functions
%%
handle(Caster, Target, Pos, SkillBaseInfo, SkillLevelInfo, MapState) ->
	case is_record(Caster, p_map_role) of
		true ->
			handle2(Caster, Target, Pos, SkillBaseInfo, SkillLevelInfo, MapState);
		_ ->
			CasterAttr = mof_common:get_fight_attr(Caster),
			TargetAttr = case is_equal(Caster, Target) of
				true -> CasterAttr;
				_ 	 -> mof_common:get_fight_attr(Target)
			end,
			{CasterAttr, TargetAttr, SkillBaseInfo, SkillLevelInfo}
	end.

handle2(Caster, Target, Pos, SkillBaseInfo1, SkillLevelInfo1, MapState) ->
	cfg_fight:is_map_can_attack(MapState#map_state.mapid, SkillBaseInfo1#p_skill.id) 
		orelse throw({error, <<"你不能在这里施放该技能">>}),
	CasterID = Caster#p_map_role.role_id,
	mod_role_mount:do_mount_down(CasterID),

	EffectType = SkillBaseInfo1#p_skill.effect_type,
	CasterAttr = mof_common:get_fight_attr(Caster),
	IsHelpSelf = is_equal(Caster, Target),
	TargetAttr = if
		EffectType == ?SKILL_EFFECT_TYPE_SELF -> CasterAttr;
		IsHelpSelf -> CasterAttr;
		true       -> mof_common:get_fight_attr(Target)
	end,

	{SkillBaseInfo2, SkillLevelInfo2} = change_skill(Caster, CasterAttr, SkillBaseInfo1, SkillLevelInfo1),
	if 
		EffectType == ?SKILL_EFFECT_TYPE_ENEMY;
		EffectType == ?SKILL_EFFECT_TYPE_ENEMY_ROLE ->
			mof_common:check_can_attack(Caster, Target, CasterAttr, TargetAttr, Pos, SkillBaseInfo2, MapState);
		EffectType == ?SKILL_EFFECT_TYPE_SELF ->
			mof_common:check_can_help_self(Caster, CasterAttr, SkillBaseInfo2, SkillLevelInfo2);
		true ->
			mof_common:check_can_help(Caster, Target, CasterAttr, TargetAttr, Pos, SkillBaseInfo2)
	end,
	NowTime = now(),
	SkillID = SkillBaseInfo2#p_skill.id,
	{ok, SkillLevel} = mod_skill:get_role_skill_level(CasterID, SkillID),

	AttackSpeed = CasterAttr#actor_fight_attr.attack_speed,
	#p_skill_level{consume_mp=ConsumeMp, cool_time=CoolTime} = SkillLevelInfo2,
	mof_fight_time:check_cd(CasterID, SkillID, CoolTime, AttackSpeed, NowTime),
	CasterMP =  Caster#p_map_role.mp,
	CasterMP >= ConsumeMp orelse throw({error, ?_LANG_SKILL_ROLE_MP_NOT_ENOUGH}),
    mod_map_role:do_role_reduce_mp(CasterID, ConsumeMp, CasterID),
    AddNuqi = cfg_role_nuqi:add_nuqi(SkillID, SkillLevel),
    if 
    	AddNuqi < 0 ->
    		AddNuqi1 = AddNuqi;
    	true ->
    		 AddNuqi1 = trunc(AddNuqi*(1 + CasterAttr#actor_fight_attr.bloodline/100))
    end,
	case mod_map_role:add_nuqi(CasterID, AddNuqi1) of
		{error, nuqi_not_enough} ->
			throw({error, ?_LANG_SKILL_ROLE_NUQI_NOT_ENOUGH});
		_ ->
			ok
	end,
	mof_fight_time:update_cd(CasterID, SkillID, NowTime),
	hook_map_role:attack(CasterID, TargetAttr, SkillBaseInfo1),
	{CasterAttr, TargetAttr, SkillBaseInfo2, SkillLevelInfo2}.

change_skill(Caster, CasterAttr, SkillBaseInfo, SkillLevelInfo) when is_record(Caster, p_map_role) ->
	SkillID = SkillBaseInfo#p_skill.id,
	#p_map_role{role_id=CasterID, summoned_pet_id=PetID} = Caster,
	ChangeTuples = case cfg_fight:is_nuqi_skill(SkillID) of
		true ->
			ChangeList1 = case mod_role_tab:get(CasterID, {?ROLE_PET_INFO, PetID}) of
				#p_pet{hp = HP, jueji = Jueji} when HP > 0 ->
					mof_nuqi_skill:change(SkillID, Jueji, get_crit(CasterAttr));
				_ ->
										[{add_effect_value, [#p_effect{
						calc_type = ?CALC_TYPE_NUQI_DAMAGE,
						value     = get_crit(CasterAttr),
						absolute_or_rate = ?TYPE_ABSOLUTE}]
					 }]
			end,
			ChangeList2 = mof_nuqi_skill:change_nuqi_huoling(CasterID, SkillID),
			% #r_nuqi_huoling{skills = HuolingSkills} = mod_nuqi_huoling:fetch(RoleID),
			ChangeList1 ++ ChangeList2;
		_ ->
			mod_skill_ext:fetch(CasterID, SkillID)
	end,
	mod_skill_ext:change_skill(SkillBaseInfo, SkillLevelInfo, ChangeTuples);
change_skill(_Caster, _CasterAttr, SkillBaseInfo, SkillLevelInfo) ->
	{SkillBaseInfo, SkillLevelInfo}.



%%
%% Local Functions
%%
is_equal(Caster, Target) when Caster == undefined;Target == undefined ->
	Caster == Target;
is_equal(Caster, Target) ->
	is_record(Target, element(1, Caster)) andalso element(2, Caster) == element(2, Target).

get_crit(#actor_fight_attr{crit = Val}) -> Val;
get_crit(_) -> 0.


