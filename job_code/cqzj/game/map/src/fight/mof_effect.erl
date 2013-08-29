%% Author: xierongfeng
%% Created: 2013-2-26
%% Description: 
-module(mof_effect).

%%
%% Include files
%%
-include("mgeem.hrl").
-include("fight.hrl").

%%
%% Exported Functions
%%
-export([handle/5]).

%%
%% API Functions
%%

handle(CasterAttr, TargetAttr, AttResult, Effect, MapState) ->
	handle(Effect#p_effect.calc_type, CasterAttr, TargetAttr, AttResult, Effect, MapState).


%%
%% Local Functions
%%
%%附加物理伤害
handle(?CALC_TYPE_ABSOLUTE_PHY_ATTACK, CasterAttr, TargetAttr, AttResult, Effect, _MapState) ->
	Damage1 = AttResult#p_attack_result.result_value,
	Anti    = TargetAttr#actor_fight_attr.phy_anti,
	Hurt    = CasterAttr#actor_fight_attr.phy_hurt_rate,
	Damage2 = Effect#p_effect.value*(1+Hurt/10000 - Anti/10000),
	AttResult#p_attack_result{result_value = Damage1 + Damage2};
%%附加魔法伤害
handle(?CALC_TYPE_ABSOLUTE_MAGIC_ATTACK, CasterAttr, TargetAttr, AttResult, Effect, _MapState) ->
	Damage1 = AttResult#p_attack_result.result_value,
	Anti    = TargetAttr#actor_fight_attr.magic_anti,
	Hurt    = CasterAttr#actor_fight_attr.magic_hurt_rate,
	Damage2 = Effect#p_effect.value*(1+Hurt/10000 - Anti/10000),
	AttResult#p_attack_result{result_value = Damage1 + Damage2};
%%普通攻击伤害
handle(Calctype, CasterAttr, TargetAttr, AttResult, Effect, _MapState)
	when Calctype == ?CALC_TYPE_BASE_MAIN_ATTACK;
		 Calctype == ?CALC_TYPE_BASE_PHY_ATTACK;
		 Calctype == ?CALC_TYPE_BASE_MAGIC_ATTACK ->
	Damage1  = AttResult#p_attack_result.result_value,
	Category = CasterAttr#actor_fight_attr.category,
	Attack   = mof_normal_attack:calc_damage(Category, CasterAttr, TargetAttr),
	IsCrit   = mof_common:if_crit(CasterAttr, TargetAttr),
	Damage2  = Attack*Effect#p_effect.value/10000*if IsCrit -> 2; true -> 1 end,
	AttResult#p_attack_result{
		result_value = Damage1 + Damage2,
		modifier = case IsCrit of
			true -> ?MODIFIER_CRIT;
			_    -> AttResult#p_attack_result.modifier
		end
	};
%%暴击额外伤害点
handle(?CALC_TYPE_CRIT_EXT_DAMAGE, _CasterAttr, _TargetAttr, AttResult, Effect, _MapState) ->
	Damage1  = AttResult#p_attack_result.result_value,
	case AttResult#p_attack_result.modifier of
		?MODIFIER_CRIT ->
			AttResult#p_attack_result{
				result_value = Damage1 + Effect#p_effect.value,
				modifier = ?MODIFIER_CRIT
			};
		_ ->
			AttResult
	end;
%%溅射伤害
handle(?CALC_TYPE_SPLASH_DAMAGE, _CasterAttr, _TargetAttr, AttResult, Effect, _MapState) ->
	Damage1 = AttResult#p_attack_result.result_value,
	Damage2 = Damage1*Effect#p_effect.value/10000,
	AttResult#p_attack_result{result_value = Damage2};
%%伤害加成
handle(?CALC_TYPE_ADD_DAMAGE, _CasterAttr, _TargetAttr, AttResult, Effect, _MapState) ->
	case Effect#p_effect.probability =< 0 orelse 
		 Effect#p_effect.probability >= 100 orelse 
		 random:uniform(100) =< Effect#p_effect.probability of
		true ->
			Damage1 = AttResult#p_attack_result.result_value,
			Damage2 = case Effect#p_effect.absolute_or_rate of
				?TYPE_ABSOLUTE ->
					Effect#p_effect.value;
				?TYPE_PERCENT ->
					Damage1*Effect#p_effect.value/10000
			end,
			AttResult#p_attack_result{result_value = Damage1 + Damage2};
		false ->
			AttResult
	end;
%%怒气伤害
handle(?CALC_TYPE_NUQI_DAMAGE, _CasterAttr, TargetAttr, AttResult, Effect, _MapState) ->
	case Effect#p_effect.probability =< 0 orelse 
		 Effect#p_effect.probability >= 100 orelse 
		 random:uniform(100) =< Effect#p_effect.probability of
		true ->
			Damage1 = case Effect#p_effect.absolute_or_rate of
				?TYPE_ABSOLUTE ->
					Effect#p_effect.value - TargetAttr#actor_fight_attr.bless;
				?TYPE_PERCENT ->
					Effect#p_effect.value - TargetAttr#actor_fight_attr.bless
			end,
			Damage1 > 0 andalso mof_common:add_attack_result(#p_attack_result{
				dest_id      = TargetAttr#actor_fight_attr.actor_id,
				dest_type    = TargetAttr#actor_fight_attr.actor_type,
				result_type  = ?RESULT_TYPE_REDUCE_HP,
				result_value = common_tool:ceil(Damage1),
				modifier     = ?MODIFIER_NUQI
			});
		false ->
			ignore
	end,
	AttResult;
%%吸血攻击
handle(?CALC_TYPE_ABSORB_HP_ATTACK, CasterAttr, _TargetAttr, AttResult, Effect, _MapState) ->
	AddHP = round(AttResult#p_attack_result.result_value*Effect#p_effect.value/10000),
	#actor_fight_attr{actor_id = CasterID, actor_type = CasterType} = CasterAttr,
	case CasterType of
		?TYPE_ROLE ->
			mod_map_role:do_role_add_hp(CasterID, AddHP, CasterID);
		_ ->
			todo
	end,
	mof_common:add_attack_result(#p_attack_result{
		dest_id      = CasterID,
		dest_type    = CasterType,
		result_type  = ?RESULT_TYPE_ADD_HP,
		result_value = AddHP
	}),
	AttResult;
%%毒性攻击
handle(?CALC_TYPE_POISON_ATTACK, CasterAttr, TargetAttr, AttResult, Effect, _MapState) ->
	Attack = max(CasterAttr#actor_fight_attr.max_phy_attack, 
				 CasterAttr#actor_fight_attr.max_magic_attack),
	Poisoning = #p_buf{
		buff_id          = ?BUFF_POISONING,
		buff_type        = ?BUFF_POISONING,
		absolute_or_rate = ?TYPE_ABSOLUTE,
		last_type        = 4,
		last_interval    = 1,
		last_value       = 8, 
		value            = round(Attack*Effect#p_effect.value/10000)
	},
	mof_buff:add_buff(CasterAttr, TargetAttr, [Poisoning]),
	AttResult;
%%回复生命
handle(?CALC_TYPE_ADD_HP, CasterAttr, TargetAttr, AttResult, Effect, _MapState) ->
	#actor_fight_attr{actor_id = CasterID, max_hp = MaxHP} = CasterAttr,
	AddHP 	   = case Effect#p_effect.absolute_or_rate of
		?TYPE_PERCENT ->
			round(MaxHP*Effect#p_effect.value/10000);
		_ ->
			round(Effect#p_effect.value)
	end,
	TargetID   = TargetAttr#actor_fight_attr.actor_id,
	TargetType = TargetAttr#actor_fight_attr.actor_type,
	case TargetType of
		?TYPE_ROLE ->
			mod_map_role:do_role_add_hp(CasterID, AddHP, TargetID);
		_ ->
			todo
	end,
	mof_common:add_attack_result(#p_attack_result{
		dest_id      = TargetID,
		dest_type    = TargetType,
		result_type  = ?RESULT_TYPE_ADD_HP,
		result_value = AddHP
	}),
	AttResult;
%%连击
handle(?CALC_TYPE_COMBOS_ATTACK, CasterAttr, TargetAttr, AttResult, Effect, _MapState) ->
	Damage1   = AttResult#p_attack_result.result_value,
	CombosNum = case Effect#p_effect.value of 3 -> 2; _ -> 3 end,
	put(auto_attack, {combos, CombosNum, CasterAttr, TargetAttr, Damage1}),
	AttResult;

handle(?CALC_TYPE_ADD_BUFF, CasterAttr, TargetAttr, AttResult, Effect, _MapState) ->
	case random:uniform(100) =< Effect#p_effect.probability of
		true ->
			Target = case Effect#p_effect.effect_type of
				?SKILL_EFFECT_TYPE_SELF ->
					CasterAttr;
				_ ->
					TargetAttr
			end,
			Buffs = common_config_dyn:find(buffs, Effect#p_effect.value),
			mof_buff:add_buff(CasterAttr, Target, Buffs);
		_ ->
			ignore
	end,
	AttResult;
		
%%离魂术
handle(?CALC_TYPE_LI_HUN_SHU, CasterAttr, TargetAttr, AttResult, Effect, _MapState) ->
	case TargetAttr of
		#actor_fight_attr{actor_type = ?TYPE_ROLE, actor_id = TargetID} ->
			{ok, TargetRoleBase} = mod_map_role:get_role_base(TargetID),
			case lists:keymember(?BUFF_ID_GU_YUAN, 
					#p_actor_buf.buff_id, TargetRoleBase#p_role_base.buffs) orelse
				 lists:keymember(?BUFF_ID_LI_HUN, 
					#p_actor_buf.buff_id, TargetRoleBase#p_role_base.buffs) of
				true -> ignore;
				_ ->
					NowTime  = now(),
					CasterID = CasterAttr#actor_fight_attr.actor_id,
					case is_li_hun_shu_trigger(CasterID, Effect, TargetID, NowTime) of
						true ->
							mof_fight_time:set_last_skill_time(role, CasterID, li_hun_shu, NowTime),
							mof_common:add_attack_result(#p_attack_result{
								dest_id      = TargetID,
								dest_type    = ?TYPE_ROLE,
								result_type  = ?RESULT_TYPE_LI_HUN_SHU
							}),
							mod_role_attr:reload_role_base(
								mod_role_buff:add_buff2(TargetRoleBase, [?BUFF_ID_LI_HUN, ?BUFF_ID_GU_YUAN]));
						_ ->
							ignore
					end
			end;
		_ ->
			ignore
	end,
	AttResult;
handle(_CalcType, _CasterAttr, _TargetAttr, AttResult, _Effect, _MapState) ->
	AttResult.

is_li_hun_shu_trigger(CasterID, LiHunShuEffect, TargetID, Now) ->
	#p_effect{probability = LiHunShuProb, value = LiHunShuValue} = LiHunShuEffect,
	case random:uniform(100) =< LiHunShuProb of
		true ->
			LastSkillTime = mof_fight_time:get_last_skill_time(role, CasterID, li_hun_shu),
    		case timer:now_diff(Now, LastSkillTime) / 1000 > cfg_fight:li_hun_shu_cd()*1000 of
    			true ->
					GuyuanShu = mod_skill_ext:fetch(TargetID, gu_yuan_shu),
					GuyuanShuValue = case lists:keyfind({add_effect, mount}, 1, GuyuanShu) of
						{_, [GuyuanShuEffect]} when is_record(GuyuanShuEffect, p_effect) ->
							GuyuanShuEffect#p_effect.value;
						_ ->
							0
					end,
					random:uniform(100) =< (LiHunShuValue - GuyuanShuValue)*3;
				_ ->
					false
			end;
		_ ->
			false
	end.