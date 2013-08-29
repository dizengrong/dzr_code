-module (mod_server_npc_attr).

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

prop_map(#p_property_add.min_physic_att)     -> #p_server_npc.min_attack;
prop_map(#p_property_add.max_physic_att)     -> #p_server_npc.max_attack;
prop_map(#p_property_add.min_magic_att)      -> #p_server_npc.min_attack;
prop_map(#p_property_add.max_magic_att)      -> #p_server_npc.max_attack;
prop_map(#p_property_add.physic_def)         -> #p_server_npc.phy_defence;
prop_map(#p_property_add.magic_def)          -> #p_server_npc.magic_defence;
prop_map(#p_property_add.blood)              -> #p_server_npc.max_hp;
prop_map(#p_property_add.dead_attack)        -> #p_server_npc.dead_attack;
prop_map(#p_property_add.attack_speed)       -> #p_server_npc.attack_speed;
prop_map(#p_property_add.dodge)              -> #p_server_npc.miss;
prop_map(#p_property_add.no_defence)         -> #p_server_npc.no_defence;
prop_map(#p_property_add.poisoning_resist)   -> #p_server_npc.poisoning_resist;
prop_map(#p_property_add.dizzy_resist)       -> #p_server_npc.dizzy_resist;
prop_map(#p_property_add.freeze_resist)      -> #p_server_npc.freeze_resist;
prop_map(#p_property_add.phy_anti)           -> #p_server_npc.phy_anti;
prop_map(#p_property_add.magic_anti)         -> #p_server_npc.magic_anti;
prop_map(#p_property_add.hit_rate)           -> #p_server_npc.hit_rate;
prop_map(#p_property_add.block)              -> #p_server_npc.block;
prop_map(#p_property_add.wreck)              -> #p_server_npc.wreck;
prop_map(#p_property_add.tough)              -> #p_server_npc.tough;
prop_map(#p_property_add.vigour)             -> #p_server_npc.vigour;
prop_map(#p_property_add.week)               -> #p_server_npc.week;
prop_map(#p_property_add.molder)             -> #p_server_npc.molder;
prop_map(#p_property_add.hunger)             -> #p_server_npc.hunger;
prop_map(#p_property_add.bless)              -> #p_server_npc.bless;
prop_map(#p_property_add.crit)               -> #p_server_npc.crit;
prop_map(#p_property_add.bloodline)          -> #p_server_npc.bloodline;
prop_map(_)									 -> undefined.

calc(ServerNpc, Op1, Attrs1, Op2, Attrs2) ->
	calc(calc(ServerNpc, Op1, Attrs1), Op2, Attrs2).

calc(ServerNpc, _Calc, []) -> ServerNpc;
calc(ServerNpc,  Calc, [{Index, Value}|Attrs]) ->
	NewValue = case Calc of
		'+' -> element(Index, ServerNpc) + Value;
		'-' -> element(Index, ServerNpc) - Value
	end,
	ServerNpc1 = setelement(Index, ServerNpc, NewValue),
	calc(ServerNpc1, Calc, Attrs).
