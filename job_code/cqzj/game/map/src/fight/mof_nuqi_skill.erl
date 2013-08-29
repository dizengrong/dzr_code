-module (mof_nuqi_skill).

-include("mgeem.hrl").

-export ([change/3,change_nuqi_huoling/2]).

change(NuqiSkillID, #p_pet_jue_ji{skill_id=SkillID, level=Level, quality=Quality}, Crit) ->
	Effects = cfg_change_skill:change_effects(NuqiSkillID, SkillID, Level, Quality),
	Buffs   = cfg_change_skill:change_buffs(NuqiSkillID, SkillID, Level),
	case lists:keytake(?CALC_TYPE_NUQI_DAMAGE, #p_effect.calc_type, Effects) of
		{value, Effect, AddEffects} ->
			[{add_buff, Buffs}, {add_effect, AddEffects}, 
			 {add_effect_value, [Effect#p_effect{value=Effect#p_effect.value+Crit}]}];
		false ->
			case cfg_fight:get_inner_skill(NuqiSkillID) of
				undefined ->
					[{add_buff, Buffs}, {add_effect, Effects}, 
					 {add_effect_value, [#p_effect{value=Crit}]}];
				_ ->
					[{add_buff, Buffs}, {add_effect, Effects}]
			end
	end.

change_nuqi_huoling(RoleID, SkillID) ->
	#r_nuqi_huoling{skills = HuolingSkills} = mod_nuqi_huoling:fetch(RoleID),

	%%怒气技能有两个技能id, 一个是对自己造成效果, 一个是对周围造成效果
	%%该判断除去对自己造成效果
	case mod_role_skill:is_nuqi_skill(SkillID) of
		false ->
			Buffs = lists:foldl(fun(HuoSkill, Acc) ->
				HuoSkillID = HuoSkill#p_role_skill.skill_id,
				HuoSkillLevel = HuoSkill#p_role_skill.cur_level, 
				case mod_skill_manager:get_skill_level_info(HuoSkillID, HuoSkillLevel) of
					{ok, SkillLevelInfo} -> 
						AccBuffs = SkillLevelInfo#p_skill_level.buffs,
						% mod_role_buff:add_buff(TargetID, Buffs),
						% mof_buff:add_buff(CasterAttr, TargetAttr, Buffs),
						Acc ++ AccBuffs;
					_ -> Acc
				end
			end, [], HuolingSkills);
		true -> Buffs = []
	end,
	[{add_buff, Buffs}].


