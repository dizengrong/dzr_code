%% Author: xierongfeng	
%% Created: 2012-11-8
%% Description: 普通技能
-module(mod_normal_skill).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([get_attack_skill_effects/2,
		 get_attack_skill_effect_value/2,
		 get_hook_skill_effect_value/1,
		 get_wealth_skill_effect_value/1,
		 get_mount_skill_effect_value/1]).

%%
%% API Functions
%%
get_attack_skill_effects(RoleID, Category) when Category == ?CATEGORY_WARRIOR;
												Category == ?CATEGORY_HUNTER ->
	get_skill_effect(RoleID, ?SKILL_NORMAL_ATTACK_PHY);
get_attack_skill_effects(RoleID, Category) when Category == ?CATEGORY_RANGER;
												Category == ?CATEGORY_DOCTOR ->
	get_skill_effect(RoleID, ?SKILL_NORMAL_ATTACK_MAGIC);
get_attack_skill_effects(_RoleID, _) ->
	[].

get_attack_skill_effect_value(RoleID, Category) ->
	case get_attack_skill_effects(RoleID, Category) of
	[#p_effect{value=Value}] ->
		Value;
	_ ->
		0
	end.

get_hook_skill_effect_value(RoleID) ->
	case get_skill_effect(RoleID, ?SKILL_NORMAL_HOOK) of
	[#p_effect{value=Value}] ->
		Value;
	_ ->
		1
	end.

get_wealth_skill_effect_value(RoleID) ->
	case get_skill_effect(RoleID, ?SKILL_NORMAL_WEALTH) of
	[#p_effect{value=Value}] ->
		Value;
	_ ->
		1
	end.

get_mount_skill_effect_value(RoleID) ->
	case get_skill_effect(RoleID, ?SKILL_NORMAL_MOUNT) of
		[#p_effect{value=Value}] ->
			Value;
		_ ->
			0
	end.

%%
%% Local Functions
%%
get_skill_level(RoleID, SkillID) ->
	{ok, Level} = mod_skill_manager:get_actor_skill_level(RoleID, role, SkillID),
	Level.

get_skill_effect(RoleID, SkillID) ->
	Level = get_skill_level(RoleID, SkillID),
	if
	Level > 0 ->
		{ok, SkillLevelInfo} = mod_skill_manager:get_skill_level_info(SkillID, Level),
		SkillLevelInfo#p_skill_level.effects;
	true ->
		[]
	end.
