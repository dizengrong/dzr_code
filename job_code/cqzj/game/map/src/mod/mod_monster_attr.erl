-module (mod_monster_attr).

-export ([transform/1, calc/5, calc/3]).

-include("common.hrl").

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

prop_map(#p_property_add.min_physic_att)     -> #p_monster.min_attack;
prop_map(#p_property_add.max_physic_att)     -> #p_monster.max_attack;
prop_map(#p_property_add.min_magic_att)      -> #p_monster.min_attack;
prop_map(#p_property_add.max_magic_att)      -> #p_monster.max_attack;
prop_map(#p_property_add.physic_def)         -> #p_monster.phy_defence;
prop_map(#p_property_add.magic_def)          -> #p_monster.magic_defence;
prop_map(#p_property_add.blood)              -> #p_monster.max_hp;
prop_map(#p_property_add.dead_attack)        -> #p_monster.dead_attack;
prop_map(#p_property_add.attack_speed)       -> #p_monster.attack_speed;
prop_map(#p_property_add.dodge)              -> #p_monster.miss;
prop_map(#p_property_add.no_defence)         -> #p_monster.no_defence;
prop_map(#p_property_add.poisoning_resist)   -> #p_monster.poisoning_resist;
prop_map(#p_property_add.dizzy_resist)       -> #p_monster.dizzy_resist;
prop_map(#p_property_add.freeze_resist)      -> #p_monster.freeze_resist;
prop_map(#p_property_add.phy_anti)           -> #p_monster.phy_anti;
prop_map(#p_property_add.magic_anti)         -> #p_monster.magic_anti;
prop_map(#p_property_add.hit_rate)           -> #p_monster.hit_rate;
prop_map(#p_property_add.block)              -> #p_monster.block;
prop_map(#p_property_add.wreck)              -> #p_monster.wreck;
prop_map(#p_property_add.tough)              -> #p_monster.tough;
prop_map(#p_property_add.vigour)             -> #p_monster.vigour;
prop_map(#p_property_add.week)               -> #p_monster.week;
prop_map(#p_property_add.molder)             -> #p_monster.molder;
prop_map(#p_property_add.hunger)             -> #p_monster.hunger;
prop_map(#p_property_add.bless)              -> #p_monster.bless;
prop_map(#p_property_add.crit)               -> #p_monster.crit;
prop_map(#p_property_add.bloodline)          -> #p_monster.bloodline;
prop_map(#p_property_add.hurt)          	 -> hurt;
prop_map(_)									 -> undefined.

calc(Monster, Op1, Attrs1, Op2, Attrs2) ->
	calc(calc(Monster, Op1, Attrs1), Op2, Attrs2).

calc(Monster, _Calc, []) -> Monster;
calc(Monster, Calc, [{Index, Value}|Attrs]) ->
	case Index of
		hurt -> 
			Attrs1 = [
				{#p_monster.phy_hurt_rate,   Value},
				{#p_monster.magic_hurt_rate, Value}|Attrs],
			calc(Monster, Calc, Attrs1);
		_ ->
			NewValue = case Calc of
				'+' -> element(Index, Monster) + Value;
				'-' -> element(Index, Monster) - Value
			end,
			Monster1 = setelement(Index, Monster, NewValue),
			calc(Monster1, Calc, Attrs)
	end.
