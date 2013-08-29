%% Author: xierongfeng
%% Created: 2013-2-25
%% Description: 伤害反射
-module(mof_hurt_rebound).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([handle/3]).

%%
%% API Functions
%%
handle(CasterAttr, TargetAttr, MapState) ->
	#actor_fight_attr{hurt_rebound  = Damage} = TargetAttr,
	if
		is_integer(Damage), Damage > 0 -> 
			IsRoleFight = CasterAttr#actor_fight_attr.actor_type == ?TYPE_ROLE,
			mof_under_attack:reduce_hp(TargetAttr, CasterAttr, Damage, 8, IsRoleFight, MapState),
			mof_common:add_attack_result(#p_attack_result{
				dest_id      = CasterAttr#actor_fight_attr.actor_id,
				dest_type    = CasterAttr#actor_fight_attr.actor_type,
				result_type  = ?RESULT_TYPE_REDUCE_HP,
				result_value = Damage
			});
		true ->
			ignore
	end.

%%
%% Local Functions
%%

