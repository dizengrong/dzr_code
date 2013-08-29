%% Author: xirongfeng
%% Created: 2013-2-25
%% Description: 连击 
-module(mof_combos_attack).

%%
%% Include files
%%
-include("mgeem.hrl").

-define(MAX_COMBOS_NUM, 3).

%%
%% Exported Functions
%%
-export([handle/5]).

%%
%% API Functions
%%
handle(CombosNum, TargetAttr, CasterAttr, Damage, MapState) ->
	SkillID = 9 + CombosNum,
	case CasterAttr#actor_fight_attr.actor_type of
		?TYPE_ROLE ->
			AddNuqi = cfg_role_nuqi:add_nuqi(SkillID, 1),
			mod_map_role:add_nuqi(CasterAttr#actor_fight_attr.actor_id, AddNuqi);
		_ -> 
			ignore
	end,
	CombosNum < ?MAX_COMBOS_NUM andalso
		put(auto_attack, {combos, CombosNum + 1, CasterAttr, TargetAttr, Damage}),
	IsRoleFight = CasterAttr#actor_fight_attr.actor_type == ?TYPE_ROLE,
	mof_under_attack:reduce_hp(CasterAttr, TargetAttr, Damage, SkillID, IsRoleFight, MapState),
	[#p_attack_result{
		dest_id      = TargetAttr#actor_fight_attr.actor_id,
		dest_type    = TargetAttr#actor_fight_attr.actor_type,
		result_type  = ?RESULT_TYPE_REDUCE_HP,
		result_value = Damage
	}].

%%
%% Local Functions
%%
