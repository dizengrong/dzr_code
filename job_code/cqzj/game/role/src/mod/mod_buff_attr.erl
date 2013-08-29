-module (mod_buff_attr).

-export ([transform/1]).

-include ("mgeer.hrl").

transform(Buff) ->
	case Buff#p_actor_buf.actor_type of
		?TYPE_ROLE ->
			mod_role_attr:transform(buff_prop(Buff));
		?TYPE_PET ->
			mod_pet_attr:transform(buff_prop(Buff));
		?TYPE_MONSTER -> 
			mod_monster_attr:transform(buff_prop(Buff))
	end.

buff_prop(#p_actor_buf{buff_id = BuffID, value = RealValue}) ->
	[Buff] = common_config_dyn:find(buffs, BuffID),
	buff_prop(Buff#p_buf{value = RealValue});
buff_prop(#p_buf{prop_id = PropID, value = Value}) when PropID > 1 ->
	[{PropID, Value}];
buff_prop(#p_buf{prop_id = PropID, value = Value}) when PropID < -1 ->
	[{-PropID, -Value}];
buff_prop(#p_buf{buff_type = BuffType, value = Value}) ->
	case mod_skill_manager:get_buff_func_by_type(BuffType) of
		{ok, add_first_level_attr} -> [
			{#p_property_add.power,    Value},
			{#p_property_add.agile,    Value},
			{#p_property_add.brain,    Value},
			{#p_property_add.vitality, Value},
			{#p_property_add.spirit,   Value}];
		{ok, add_attack} -> [
			{#p_property_add.min_physic_att, Value},
			{#p_property_add.max_physic_att, Value},
			{#p_property_add.min_magic_att,  Value},
			{#p_property_add.max_magic_att,  Value}];
		{ok, reduce_attack} -> [
			{#p_property_add.min_physic_att, -Value},
			{#p_property_add.max_physic_att, -Value},
			{#p_property_add.min_magic_att,  -Value},
			{#p_property_add.max_magic_att,  -Value}];
		{ok, add_phy_attack} -> [
			{#p_property_add.min_physic_att, Value},
			{#p_property_add.max_physic_att, Value}];
		{ok, add_magic_attack} -> [
			{#p_property_add.min_magic_att,  Value},
			{#p_property_add.max_magic_att,  Value}];
		{ok, add_defence} -> [
			{#p_property_add.physic_def,  Value},
			{#p_property_add.magic_def,   Value}];
		{ok, reduce_defence} -> [
			{#p_property_add.physic_def,  -Value},
			{#p_property_add.magic_def,   -Value}];
		{ok, add_anti} -> [
			{#p_property_add.phy_anti,   Value},
			{#p_property_add.magic_anti, Value}];
		{ok, reduce_anti} -> [
			{#p_property_add.phy_anti,   -Value},
			{#p_property_add.magic_anti, -Value}];
		_ ->
			[]
	end.