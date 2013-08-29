-module (mod_role_attr).

-export ([transform/1, calc/5, calc/3, reload_role_base/1, reload_role_base/2, recalc/1, recalc/2]).

-import (common_tool, [ceil/1]).

-include("common.hrl").

-define(_base_reload, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_BASE_RELOAD, #m_role2_base_reload_toc).%}

transform(PropRec) when is_record(PropRec, p_property_add) ->
	lists:foldl(fun
		(N1, Acc) ->
			Value = element(N1, PropRec),
			N2    = prop_map(N1),
			case N2 =/= undefined andalso Value =/= 0 of
				true ->
					[{N2, Value}|Acc];
				_ ->
					Acc
			end
	end,[],lists:seq(2, size(PropRec)));
transform(PropLst) when is_list(PropLst) ->
	lists:foldl(fun
		({N1, Value}, Acc) ->
			N2 = prop_map(N1),
			case N2 =/= undefined andalso Value =/= 0 of
				true ->
					[{N2, Value}|Acc];
				_ ->
					Acc
			end
	end,[],PropLst);
transform(_) -> [].

prop_map(#p_property_add.hurt_shift)		 -> undefined;
prop_map(#p_property_add.main_property)		 -> undefined;
prop_map(#p_property_add.blood_rate)		 -> blood_rate;
prop_map(#p_property_add.physic_att_rate)	 -> physic_att_rate;
prop_map(#p_property_add.magic_att_rate)	 -> magic_att_rate;
prop_map(#p_property_add.physic_def_rate)	 -> physic_def_rate;
prop_map(#p_property_add.magic_def_rate)	 -> magic_def_rate;
prop_map(#p_property_add.magic_rate) 		 -> magic_rate;
prop_map(#p_property_add.power)              -> #p_role_base.str;
prop_map(#p_property_add.agile)              -> #p_role_base.dex;
prop_map(#p_property_add.brain)              -> #p_role_base.int2;
prop_map(#p_property_add.vitality)           -> #p_role_base.con;
prop_map(#p_property_add.spirit)             -> #p_role_base.men;
prop_map(#p_property_add.min_physic_att)     -> #p_role_base.min_phy_attack;
prop_map(#p_property_add.max_physic_att)     -> #p_role_base.max_phy_attack;
prop_map(#p_property_add.min_magic_att)      -> #p_role_base.min_magic_attack;
prop_map(#p_property_add.max_magic_att)      -> #p_role_base.max_magic_attack;
prop_map(#p_property_add.physic_def)         -> #p_role_base.phy_defence;
prop_map(#p_property_add.magic_def)          -> #p_role_base.magic_defence;
prop_map(#p_property_add.blood)              -> #p_role_base.max_hp;
prop_map(#p_property_add.magic)              -> #p_role_base.max_mp;
prop_map(#p_property_add.blood_resume_speed) -> #p_role_base.hp_recover_speed;
prop_map(#p_property_add.magic_resume_speed) -> #p_role_base.mp_recover_speed;
prop_map(#p_property_add.dead_attack)        -> #p_role_base.double_attack;
prop_map(#p_property_add.lucky)              -> #p_role_base.luck;
prop_map(#p_property_add.move_speed)         -> #p_role_base.move_speed;
prop_map(#p_property_add.attack_speed)       -> #p_role_base.attack_speed;
prop_map(#p_property_add.dodge)              -> #p_role_base.miss;
prop_map(#p_property_add.no_defence)         -> #p_role_base.no_defence;
prop_map(#p_property_add.dizzy)              -> #p_role_base.dizzy;
prop_map(#p_property_add.poisoning)          -> #p_role_base.poisoning;
prop_map(#p_property_add.freeze)             -> #p_role_base.freeze;
prop_map(#p_property_add.hurt)               -> #p_role_base.hurt;
prop_map(#p_property_add.poisoning_resist)   -> #p_role_base.poisoning_resist;
prop_map(#p_property_add.dizzy_resist)       -> #p_role_base.dizzy_resist;
prop_map(#p_property_add.freeze_resist)      -> #p_role_base.freeze_resist;
prop_map(#p_property_add.phy_anti)           -> #p_role_base.phy_anti;
prop_map(#p_property_add.magic_anti)         -> #p_role_base.magic_anti;
prop_map(#p_property_add.hurt_rebound)       -> #p_role_base.hurt_rebound;
prop_map(#p_property_add.hit_rate)           -> #p_role_base.hit_rate;
prop_map(#p_property_add.block)              -> #p_role_base.block;
prop_map(#p_property_add.wreck)              -> #p_role_base.wreck;
prop_map(#p_property_add.tough)              -> #p_role_base.tough;
prop_map(#p_property_add.vigour)             -> #p_role_base.vigour;
prop_map(#p_property_add.week)               -> #p_role_base.week;
prop_map(#p_property_add.molder)             -> #p_role_base.molder;
prop_map(#p_property_add.hunger)             -> #p_role_base.hunger;
prop_map(#p_property_add.bless)              -> #p_role_base.bless;
prop_map(#p_property_add.crit)               -> #p_role_base.crit;
prop_map(#p_property_add.bloodline)          -> #p_role_base.bloodline.

calc(RoleBase, Calc1, Attrs1, Calc2, Attrs2) ->
	calc(calc(RoleBase, Calc1, Attrs1), Calc2, Attrs2).

calc(RoleBase1, Calc, Attrs) ->
	RoleBase2 = calc2(RoleBase1, Calc, Attrs),
	case contain_base_attr(Attrs) of
		true ->
			calc2(calc2(RoleBase2, 
				'-', mod_role_base:transform(RoleBase1)),
				'+', mod_role_base:transform(RoleBase2));
		_ ->
			RoleBase2
	end.

calc2(RoleBase, _Calc, []) -> RoleBase;
calc2(RoleBase1, Calc, [{Index, Value}|Attrs1]) when is_integer(Index) ->
	NewValue = case Calc of
		'+' -> element(Index, RoleBase1) + Value;
		'-' -> element(Index, RoleBase1) - Value
	end,
	RoleBase2 = setelement(Index, RoleBase1, NewValue),
	Attrs2    = case Index of
		#p_role_base.hurt -> [
			{#p_role_base.phy_hurt_rate,   Value},
			{#p_role_base.magic_hurt_rate, Value}|Attrs1];
		_ ->
			Attrs1
	end,
	calc2(RoleBase2, Calc, Attrs2);
calc2(RoleBase, Calc, [{Index, Value}|Attrs]) when is_atom(Index) ->
	Index2 = case Index of
		blood_rate      -> #p_rate_attrs.blood_rate;
		physic_att_rate -> #p_rate_attrs.physic_att_rate;
		magic_att_rate  -> #p_rate_attrs.magic_att_rate;
		physic_def_rate -> #p_rate_attrs.physic_def_rate;
		magic_def_rate  -> #p_rate_attrs.magic_def_rate;
		magic_rate      -> #p_rate_attrs.magic_rate
	end,
	RateAttrs1 = case RoleBase#p_role_base.rate_attrs of
		undefined -> #p_rate_attrs{};
		Others    -> Others
	end,
	RateAttrs2 = setelement(Index2, RateAttrs1, element(Index2, RateAttrs1) + Value),
	calc2(RoleBase#p_role_base{rate_attrs = RateAttrs2}, Calc, Attrs).

contain_base_attr(Attrs) ->
	lists:any(fun
		({Index, _Value}) ->
			Index == #p_role_base.str  orelse
			Index == #p_role_base.int2 orelse
			Index == #p_role_base.dex  orelse
			Index == #p_role_base.men  orelse
			Index == #p_role_base.con
	end, Attrs).

reload_role_base(RoleBase) ->
	reload_role_base(RoleBase, true).
reload_role_base(RoleBase = #p_role_base{role_id = RoleID}, UpdateMapRole) ->
	mod_role_tab:put({?role_base, RoleID}, RoleBase),
	RoleBase2 = case RoleBase#p_role_base.rate_attrs of
		undefined -> RoleBase;
		RateAttrs ->
			RoleBase#p_role_base{
				max_hp           = trunc(RoleBase#p_role_base.max_hp*(1+RateAttrs#p_rate_attrs.blood_rate/10000)),
				max_mp           = trunc(RoleBase#p_role_base.max_mp*(1+RateAttrs#p_rate_attrs.magic_rate/10000)),
				max_phy_attack   = trunc(RoleBase#p_role_base.max_phy_attack*(1+RateAttrs#p_rate_attrs.physic_att_rate/10000)),
				min_phy_attack   = trunc(RoleBase#p_role_base.min_phy_attack*(1+RateAttrs#p_rate_attrs.physic_att_rate/10000)),
				max_magic_attack = trunc(RoleBase#p_role_base.max_magic_attack*(1+RateAttrs#p_rate_attrs.magic_att_rate/10000)),
				min_magic_attack = trunc(RoleBase#p_role_base.min_magic_attack*(1+RateAttrs#p_rate_attrs.magic_att_rate/10000)),
				phy_defence      = trunc(RoleBase#p_role_base.phy_defence*(1+RateAttrs#p_rate_attrs.physic_def_rate/10000)),
				magic_defence    = trunc(RoleBase#p_role_base.magic_defence*(1+RateAttrs#p_rate_attrs.magic_def_rate/10000))
			}
	end,
	common_misc:unicast({role, RoleID}, ?_base_reload{role_base = RoleBase2}),
	UpdateMapRole andalso mod_map_role:update_map_role_info(RoleID).

recalc(RoleID) ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	recalc(RoleBase, RoleAttr).

recalc(RoleBase, RoleAttr) ->
	RoleBase2 = RoleBase#p_role_base{
		move_speed       = ?DEFAULT_MOVE_SPEED,
		attack_speed     = ?DEFAULT_ATTACK_SPEED,
		max_hp           = common_misc:get_level_base_hp(RoleAttr#p_role_attr.level),
        max_mp           = common_misc:get_level_base_mp(RoleAttr#p_role_attr.level),
		luck             = ?DEFAULT_LUCK,
		phy_defence      = ?DEFAULT_PHY_DEFENCE,
		magic_defence    = ?DEFAULT_MAGIC_DEFENCE,
		max_phy_attack   = ?DEFAULT_MAX_PHY_ATTACK,
		min_phy_attack   = ?DEFAULT_MIN_PHY_ATTACK,
		max_magic_attack = ?DEFAULT_MAX_MAGIC_ATTACK,
		min_magic_attack = ?DEFAULT_MIN_MAGIC_ATTACK,
		double_attack    = ?DEFAULT_DOUBLE_ATTACK,
		phy_anti         = 0,
		magic_anti       = 0,
		phy_hurt_rate    = 0,
		magic_hurt_rate  = 0,
		hit_rate         = 10000,
		miss             = ?DEFAULT_MISS,
		no_defence       = ?DEFAULT_NO_DEFENCE,
		block            = 0,
		wreck            = 0,
		tough            = 0,
		vigour           = 0,
		week             = 0,
		molder           = 0,
		hunger           = 0,
		bless            = 0,
		crit             = 0,
		bloodline        = 0,
		rate_attrs       = undefined
	},
	CalcModules = [
		mod_role_base, 
		mod_role_buff, 
		mod_role_equip,
		mod_equip_gems, 
		mod_hidden_examine_fb, 
		mod_pet_grow, 
		mod_role_grow, 
		mod_role_jingjie, 
		mod_role_juewei, 
		mod_role_pet,
		mod_role_fashion,
		mod_role_mount,
		common_title,
		mod_nuqi_huoling,
		mod_fulu,
		mod_rage_practice,
		mod_rune_altar

	],
	lists:foldl(fun
		(Module, RoleBaseAcc) ->
			Module:recalc(RoleBaseAcc, RoleAttr)
	end, RoleBase2, CalcModules).
