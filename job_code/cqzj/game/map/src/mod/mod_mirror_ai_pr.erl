%% Author: xierf
%% Created: 2012-5-22
%% Description: 镜像AI优先级：根据角色或异兽当前状态对可选动作设置优先级，最高为1级，ignore表示不执行些动作
-module(mod_mirror_ai_pr).

%%
%% Include files
%%
-include("mgeem.hrl"). 
-include("mirror.hrl").

%%
%% Exported Functions
%%
-export([priority/2, priority/4]).

%%
%% API Functions
%%

%%跟踪
priority(follow, #p_map_role{state_buffs=StateBuffs}) ->
	case lists:any(fun
		(#p_actor_buf{buff_id=BuffID}) ->
			BuffID == ?BUFF_TYPE_QING_LONG orelse 
			BuffID == ?BUFF_TYPE_XUAN_FENG orelse 
			BuffID == ?BUFF_TYPE_LUN_HUI
	end, StateBuffs) of
		true ->
			0;
		false ->
			5
	end;

%%攻击
priority(attack, _ActorMapInfo) ->
	4;

%%停止
priority(stop, #p_map_role{state_buffs=StateBuffs}) ->
	case lists:any(fun(#p_actor_buf{buff_type=Type}) ->
			case common_config_dyn:find(buff_type, Type) of
				[Atom] when Atom == dizzy;
						    Atom == hidden_to_other;
						    Atom == hidden_not_move ->
				   true;
				_ ->
				   false
			end
		 end, StateBuffs) of
		true ->
			1;
		false ->
			ignore
	end;

%%异兽不会被控制
priority(stop, _PetMapInfo) ->
	ignore;

%%角色技能优先级
priority({SkillID, SkillLevel}, ActorMapInfo) when is_record(ActorMapInfo, p_map_role) ->
	case cfg_mirror:skill_type(SkillID) of
		ignore ->
			ignore;
		attack ->
			3;
		Atom ->
			priority(Atom, SkillID, SkillLevel, ActorMapInfo)
	end;

%%异兽技能优先级
priority(_Skill, _PetMapInfo) ->
	3.

%%大招(不包括医疗、无敌技能)
priority(ult, _SkillID, _SkillLevel, _ActorMapInfo) ->
	2;

priority(nuqi, SkillID, SkillLevel, ActorMapInfo) ->
	case cfg_role_nuqi:add_nuqi(SkillID, SkillLevel) >= ActorMapInfo#p_map_role.nuqi of
		true -> 2;
		_    -> ignore
	end;

%%驱散负面状态的技能
priority(dispel_debuff, _SkillID, _SkillLevel, #p_map_role{state_buffs=StateBuffs}) ->
	case lists:any(fun(#p_actor_buf{buff_id=BuffID}) ->
		case common_config_dyn:find(buffs, BuffID) of
			[#p_buf{can_remove=true, is_debuff=true}] ->
			   true;
			_ ->
			   false
		end
	end, StateBuffs) of
		true ->
			2;
		false ->
			ignore
	end;

%%医疗技能
priority(heal, _SkillID, _SkillLevel, #p_map_role{hp=HP, max_hp=MaxHP}) when HP*2 =< MaxHP ->
	3;

priority(heal, SkillID, SkillLevel, #p_map_role{hp=HP, max_hp=MaxHP}) ->
	{ok, #p_skill_level{buffs=Buffs}} = mod_skill_manager:get_skill_level_info(SkillID, SkillLevel),
	AddHP = lists:sum([Val*erlang:max(1, LastSecs - 1)||
		#p_buf{value=Val, buff_type=Type, last_value=LastSecs}<-Buffs,
		case common_config_dyn:find(buff_type, Type) of
			[Atom] when Atom == add_hp;
					    Atom == add_hp_not_move ->
			   true;
			_ ->
			   false
		end]),
	case MaxHP - HP >= AddHP of
		true ->
			3;
		false ->
			ignore
	end;


%%状态技能：对于状态持续时间比冷却时间长的技能，当镜像身上已有该技能对应效果时，不再重复施法
priority(add_buff, SkillID, SkillLevel, #p_map_role{state_buffs=StateBuffs}) ->
	case mod_skill_manager:get_skill_level_info(SkillID, SkillLevel) of
		{ok, #p_skill_level{buffs=[Buff|_]}} ->
			case lists:keymember(Buff#p_buf.buff_id, #p_actor_buf.buff_id, StateBuffs) of
				true ->
					ignore;
				false ->
					1
			end;
		_ ->
			1
	end.

%%
%% Local Functions
%%
