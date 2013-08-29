%% Author: xierongfeng
%% Created: 2013-2-25
%% Description:受到伤害后处理
-module(mof_under_attack).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([handle/5, reduce_hp/6]).

%%
%% API Functions
%%
handle(CasterAttr, TargetAttr, AttResult, SkillID, MapState) ->
	#actor_fight_attr{actor_type = TargetType1, actor_id = TargetID1} = TargetAttr,
	AttResults = [AttResult|mof_common:get_attack_result()],
	mof_common:put_attack_result(AttResults),
	Damage = common_tool:ceil(lists:sum([Val||#p_attack_result{
		result_type  = ?RESULT_TYPE_REDUCE_HP, 
		result_value = Val,
		dest_type    = TargetType2,
		dest_id      = TargetID2
	} <- AttResults, TargetType1 == TargetType2, TargetID1 == TargetID2])),
	IsRoleFight = CasterAttr#actor_fight_attr.actor_type == ?TYPE_ROLE,
	reduce_hp(CasterAttr, TargetAttr, Damage, SkillID, IsRoleFight, MapState).

reduce_hp(CasterAttr, TargetAttr, Damage, SkillID, IsRoleFight, MapState) ->
	#actor_fight_attr{
		actor_id   = CasterID,
		actor_type = CasterType,
		actor_name = CasterName
	} = CasterAttr,
	#actor_fight_attr{
		actor_id   = TargetID,
		actor_type = TargetType
	} = TargetAttr,
	CasterType2 = mof_common:actor_type_atom(CasterType),
	case TargetType of
		?TYPE_ROLE ->
			hook_map_role:be_attacked(TargetID, CasterID, CasterType, ?SKILL_EFFECT_TYPE_ENEMY),
			mod_map_role:do_role_reduce_hp(TargetID, Damage, CasterName, CasterID, CasterType2, MapState);
		?TYPE_MONSTER ->
			mod_map_monster:reduce_hp(TargetID, Damage, CasterID, CasterType2, IsRoleFight, SkillID);
		?TYPE_SERVER_NPC ->
			mod_server_npc:reduce_hp(TargetID, Damage, CasterID, CasterType2);
		?TYPE_YBC ->
			mod_map_ybc:reduce_hp(TargetID, Damage, CasterID, CasterType2);
		?TYPE_PET ->
			mod_map_pet:pet_reduce_hp(TargetID, Damage, CasterID, CasterType2)
	end.

%%
%% Local Functions
%%

