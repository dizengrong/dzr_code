%% Author:xierongfeng
%% Created: 2013-2-24
%% Description:技能攻击模块（不能闪避）
-module(mof_skill_attack).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([handle/6, handle2/6]).

%%
%% API Functions
%%
handle(Caster, Target, Pos, SkillBaseInfo1, SkillLevelInfo1, MapState) ->
	{CasterAttr, TargetAttr, SkillBaseInfo2, SkillLevelInfo2} = 
		mof_before_attack:handle(Caster, Target, Pos, SkillBaseInfo1, SkillLevelInfo1, MapState),
	handle2(CasterAttr, TargetAttr, Pos, SkillBaseInfo2, SkillLevelInfo2, MapState).

handle2(CasterAttr, TargetAttr, Pos, SkillBaseInfo, SkillLevelInfo, MapState) ->
	#p_skill{target_type=SkillTargetType, effect_type=SkillEffectType} = SkillBaseInfo,
	if 
		SkillTargetType == ?TARGET_TYPE_SELF_AROUND;
		SkillTargetType == ?TARGET_TYPE_SELF_FRONT;
		SkillTargetType == ?TARGET_TYPE_OTHER_AROUND;
		SkillTargetType == ?TARGET_TYPE_OTHER_FRONT ->
			CheckFun = check_taget_fun(SkillBaseInfo, CasterAttr, MapState#map_state.mapid),
			lists:foreach(fun(TargetFightAttr) ->
				do_attack(CasterAttr, TargetFightAttr, SkillEffectType, SkillLevelInfo, MapState)
			end, mof_common:get_all_targets(SkillBaseInfo, Pos, CheckFun));
		true ->
			do_attack(CasterAttr, TargetAttr, SkillEffectType, SkillLevelInfo, MapState)
	end,
	%%返回战斗结果
	mof_common:erase_attack_result().

%%
%% Local Functions
%%
check_taget_fun(SkillBaseInfo, CasterAttr, MapID) ->
	CasterID   = CasterAttr#actor_fight_attr.actor_id,
	CasterType = mof_common:actor_type_atom(CasterAttr#actor_fight_attr.actor_type),
	IsAttack   = SkillBaseInfo#p_skill.effect_type == ?SKILL_EFFECT_TYPE_ENEMY orelse 
				 SkillBaseInfo#p_skill.effect_type == ?SKILL_EFFECT_TYPE_ENEMY_ROLE,
	fun
		({?TYPE_PET, _}) -> 
			false;
	   ({TargetType, TargetID}) when IsAttack, {TargetType, TargetID} == {CasterType, CasterID} ->
			false;
	   ({TargetType, TargetID}) ->
			TargetMapInfo = mod_map_actor:get_actor_mapinfo(TargetID, TargetType),
			mof_common:is_alive(TargetMapInfo) andalso begin
				TargetAttr = mof_common:get_fight_attr(TargetMapInfo),
				not (IsAttack xor (mof_common:is_enemy(CasterAttr, TargetAttr, TargetMapInfo) == true))
				andalso mof_common:check_protect_lv(CasterAttr, TargetAttr, MapID) == ok
				andalso mof_common:is_invisible(TargetAttr) /= true
				andalso mof_common:is_unbeatable(TargetAttr) /= true
				andalso (
					TargetType == monster orelse not 
					mof_common:is_pos_safe(MapID, mof_common:get_pos(TargetMapInfo))
				) andalso {continue, TargetAttr}
			end
	end.

do_attack(CasterAttr, TargetAttr, SkillEffectType, SkillLevelInfo, MapState) ->
	#p_skill_level{skill_id=SkillID, effects=Effects, buffs=Buffs} = SkillLevelInfo,
	AttResult0 = #p_attack_result{
		dest_id      = TargetAttr#actor_fight_attr.actor_id,
		dest_type    = TargetAttr#actor_fight_attr.actor_type,
		result_type  = ?RESULT_TYPE_REDUCE_HP
	},
	AttResult1 = lists:foldl(fun(Effect, AttResultAcc) ->
		mof_effect:handle(CasterAttr, TargetAttr, AttResultAcc, Effect, MapState)
	end, AttResult0, Effects),
	mof_buff:add_buff(CasterAttr, TargetAttr, Buffs),
	if 
		AttResult1#p_attack_result.result_value > 0; 
		SkillEffectType == ?SKILL_EFFECT_TYPE_ENEMY;
		SkillEffectType == ?SKILL_EFFECT_TYPE_ENEMY_ROLE ->
			mof_under_attack:handle(CasterAttr, TargetAttr, AttResult1, SkillID, MapState);
		true ->
			ignore
	end.
	
