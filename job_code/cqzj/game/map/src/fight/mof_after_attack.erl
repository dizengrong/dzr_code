%% Author: xierongfeng
%% Created: 2013-2-25
%% Description:单体攻击触发后处理
-module(mof_after_attack).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([handle/7]).

%%
%% API Functions
%%
handle(CasterAttr, TargetAttr, AttResult1, Pos, SkillBaseInfo, SkillLevelInfo, MapState) ->
	#p_skill_level{skill_id=SkillID, effects=Effects, buffs=Buffs} = SkillLevelInfo,
	AttResult2 = lists:foldl(fun(Effect, AttResultAcc) ->
		case not is_splash_effect(Effect) of
			true ->
				mof_effect:handle(CasterAttr, TargetAttr, AttResultAcc, Effect, MapState);
			false ->
				AttResultAcc
		end
	end, AttResult1, Effects),
	mof_buff:add_buff(CasterAttr, TargetAttr, Buffs),
	SkillTargetType = SkillBaseInfo#p_skill.target_type,
	if 
		SkillTargetType == ?TARGET_TYPE_SELF_AROUND;
		SkillTargetType == ?TARGET_TYPE_SELF_FRONT;
		SkillTargetType == ?TARGET_TYPE_OTHER_AROUND;
		SkillTargetType == ?TARGET_TYPE_OTHER_FRONT;
		SkillTargetType == ?TARGET_TYPE_OTHER_LIMIT ->
			CheckFun = check_taget_fun(SkillBaseInfo, CasterAttr, TargetAttr, MapState#map_state.mapid),
			lists:foreach(fun(TargetAttr2) -> 
				splash_damage(CasterAttr, TargetAttr2, AttResult2, SkillLevelInfo, MapState)
			end, mof_common:get_all_targets(SkillBaseInfo, Pos, CheckFun));
		true ->
			ignore
	end,
	case CasterAttr#actor_fight_attr.actor_type == ?TYPE_ROLE andalso 
		 TargetAttr#actor_fight_attr.actor_type == ?TYPE_ROLE of
		true -> 
			case mod_role_juewei:is_suppressed(CasterAttr#actor_fight_attr.juewei, 
											   TargetAttr#actor_fight_attr.juewei) of
				true ->
					mod_map_role:clean_role_nuqi(TargetAttr#actor_fight_attr.actor_id, 1);
				false -> ignore
			end;
		false -> ignore
	end,
	case CasterAttr#actor_fight_attr.actor_type == ?TYPE_ROLE of
		true  -> mod_fulu:hook_fight(CasterAttr, TargetAttr, SkillID);
		false -> ignore
	end,
	mof_buff:under_attack(TargetAttr, AttResult2#p_attack_result.result_value),
	mof_under_attack:handle(CasterAttr, TargetAttr, AttResult2, SkillID, MapState).


%%
%% Local Functions
%%
check_taget_fun(SkillBaseInfo, CasterAttr, TargetAttr0, MapID) ->
	#actor_fight_attr{actor_type=CasterTypeInt, actor_id=CasterID} = CasterAttr,
	#actor_fight_attr{actor_type=TargetTypeInt0, actor_id=TargetID0} = TargetAttr0,
	CasterType = mof_common:actor_type_atom(CasterTypeInt),
	TargetType0 = mof_common:actor_type_atom(TargetTypeInt0),
	fun
		({?TYPE_PET, _}) ->
			false;
	   ({TargetType, TargetID}) when {TargetType, TargetID} == {CasterType, CasterID} ->
			false;
	   ({TargetType, TargetID}) when {TargetType, TargetID} == {TargetType0, TargetID0} ->
			false;
	   ({TargetType, TargetID}) ->
			TargetMapInfo = mod_map_actor:get_actor_mapinfo(TargetID, TargetType),
			case mof_common:is_alive(TargetMapInfo) of
				true ->
					TargetAttr = mof_common:get_fight_attr(TargetMapInfo),
					mof_common:check_protect_lv(CasterAttr, TargetAttr, MapID) == ok
					andalso (mof_common:is_enemy(CasterAttr, TargetAttr, TargetMapInfo) == true)
					andalso mof_common:is_invisible(TargetAttr) /= true
					andalso mof_common:is_unbeatable(TargetAttr) /= true
					andalso if
						SkillBaseInfo#p_skill.target_type == ?TARGET_TYPE_OTHER_LIMIT ->
							LimitNum = SkillBaseInfo#p_skill.target_area,
							FoundNum = case erase(found_targets) of
								undefined -> 0;
								FoundNum2 -> FoundNum2
							end,
							if
								LimitNum == 1->
									{break, TargetAttr};
								FoundNum + 1 >= LimitNum ->
									{break, TargetAttr};
								true ->
									put(found_targets, FoundNum + 1),
									{continue, TargetAttr}
							end;
						true ->
							{continue, TargetAttr}
					end;
				_ ->
					false
			end
	end.

%%是否溅射效果
is_splash_effect(#p_effect{calc_type=Calctype}) ->
	Calctype == ?CALC_TYPE_SPLASH_DAMAGE.

%%是否伤害效果
is_damage_effect(#p_effect{calc_type=Calctype}) ->
	Calctype == ?CALC_TYPE_BASE_MAIN_ATTACK orelse
	Calctype == ?CALC_TYPE_BASE_PHY_ATTACK orelse
	Calctype == ?CALC_TYPE_BASE_MAGIC_ATTACK orelse
	Calctype == ?CALC_TYPE_ABSOLUTE_PHY_ATTACK orelse 
	Calctype == ?CALC_TYPE_ABSOLUTE_MAGIC_ATTACK orelse
	Calctype == ?CALC_TYPE_ADD_DAMAGE.

%%溅射伤害
splash_damage(CasterAttr, TargetAttr, AttResult1, SkillLevelInfo, MapState) ->
	#p_skill_level{skill_id=SkillID, effects=Effects, buffs=Buffs} = SkillLevelInfo,
	AttResult2 = lists:foldl(fun(Effect, AttResultAcc) ->
		case not is_damage_effect(Effect) of
			true ->
				mof_effect:handle(CasterAttr, TargetAttr, AttResultAcc, Effect, MapState);
			_ ->
				AttResultAcc
		end
	end, AttResult1, Effects),
	mof_buff:add_buff(CasterAttr, TargetAttr, Buffs),
	mof_under_attack:handle(CasterAttr, TargetAttr, AttResult2, SkillID, MapState).