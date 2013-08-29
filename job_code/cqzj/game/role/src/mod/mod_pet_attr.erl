-module (mod_pet_attr).

-export ([transform/1, calc/5, calc/3, reload_pet_info/1, recalc/1]).

-include("common.hrl").

-define (_pet_info, ?DEFAULT_UNIQUE, ?PET, ?PET_INFO, #m_pet_info_toc).%}

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

prop_map(#p_property_add.power)              -> #p_pet.str;
prop_map(#p_property_add.agile)              -> #p_pet.dex;
prop_map(#p_property_add.brain)              -> #p_pet.int2;
prop_map(#p_property_add.vitality)           -> #p_pet.con;
prop_map(#p_property_add.spirit)             -> #p_pet.men;
prop_map(#p_property_add.min_physic_att)     -> #p_pet.phy_attack;
prop_map(#p_property_add.max_physic_att)     -> #p_pet.phy_attack;
prop_map(#p_property_add.min_magic_att)      -> #p_pet.magic_attack;
prop_map(#p_property_add.max_magic_att)      -> #p_pet.magic_attack;
prop_map(#p_property_add.physic_def)         -> #p_pet.phy_defence;
prop_map(#p_property_add.magic_def)          -> #p_pet.magic_defence;
prop_map(#p_property_add.blood)              -> #p_pet.max_hp;
prop_map(#p_property_add.dead_attack)        -> #p_pet.double_attack;
prop_map(#p_property_add.attack_speed)       -> #p_pet.attack_speed;
prop_map(#p_property_add.dodge)              -> #p_pet.miss;
prop_map(#p_property_add.no_defence)         -> #p_pet.no_defence;
prop_map(#p_property_add.hit_rate)           -> #p_pet.hit_rate;
prop_map(#p_property_add.block)              -> #p_pet.block;
prop_map(#p_property_add.wreck)              -> #p_pet.wreck;
prop_map(#p_property_add.tough)              -> #p_pet.tough;
prop_map(#p_property_add.vigour)             -> #p_pet.vigour;
prop_map(#p_property_add.week)               -> #p_pet.week;
prop_map(#p_property_add.molder)             -> #p_pet.molder;
prop_map(#p_property_add.hunger)             -> #p_pet.hunger;
prop_map(#p_property_add.bless)              -> #p_pet.bless;
prop_map(#p_property_add.crit)               -> #p_pet.crit;
prop_map(#p_property_add.bloodline)          -> #p_pet.bloodline;
prop_map(_)									 -> undefined.

calc(Pet, Op1, Attrs1, Op2, Attrs2) ->
	calc(calc(Pet, Op1, Attrs1), Op2, Attrs2).

calc(Pet1, Calc, Attrs) -> 
	Pet2 = calc2(Pet1, Calc, Attrs),
	ContainBaseAttr = lists:any(fun
		({Index, _Value}) ->
			Index == #p_pet.str  				   orelse
			Index == #p_pet.int2 				   orelse
			Index == #p_pet.dex  				   orelse
			Index == #p_pet.men  				   orelse
			Index == #p_pet.con  				   orelse
			Index == #p_pet.phy_attack_aptitude    orelse
			Index == #p_pet.magic_attack_aptitude  orelse
			Index == #p_pet.phy_defence_aptitude   orelse
			Index == #p_pet.magic_defence_aptitude orelse
			Index == #p_pet.max_hp_aptitude        orelse
			Index == #p_pet.level                  orelse
			Index == #p_pet.color                  orelse
			Index == #p_pet.understanding
	end, Attrs),
	if
		ContainBaseAttr ->
			Pet3 = calc2(calc2(Pet2, 
				'-', mod_pet_base:transform(Pet1)), '+', mod_pet_base:transform(Pet2)),
			Pet3#p_pet{
				max_aptitude = common_pet:get_pet_max_aptitude(
					Pet3#p_pet.level, Pet3#p_pet.color, Pet3#p_pet.understanding),
				max_understanding = common_pet:get_pet_max_understanding(Pet3#p_pet.level)
			};
		true ->
			Pet2
	end.

calc2(Pet, _Calc, []) -> Pet;
calc2(Pet1, Calc, [{Index, Value}|Attrs]) ->
	NewValue = case Calc of
		'+' -> element(Index, Pet1) + Value;
		'-' -> element(Index, Pet1) - Value
	end,
	Pet2 = setelement(Index, Pet1, NewValue),
	calc2(Pet2, Calc, Attrs).

reload_pet_info(Pet = #p_pet{role_id = RoleID, pet_id = PetID}) ->
	NewPet = Pet#p_pet{hp = Pet#p_pet.max_hp},
	mod_role_tab:put(RoleID, {?ROLE_PET_INFO, PetID}, NewPet),
	common_misc:unicast({role, RoleID}, ?_pet_info{pet_info = NewPet}).

recalc(PetInfo) ->
	ResetPet = PetInfo#p_pet{
		attack_speed           = ?DEFAULT_ATTACK_SPEED,
		max_hp                 = 0,
		phy_defence            = 0,
		magic_defence          = 0,
		phy_attack             = 0,
		magic_attack           = 0,
		double_attack          = 0,
		hit_rate               = 0,
		miss                   = 0,
		no_defence             = 0,
		block                  = 0,
		wreck                  = 0,
		tough                  = 0,
		vigour                 = 0,
		week                   = 0,
		molder                 = 0,
		hunger                 = 0,
		bless                  = 0,
		crit                   = 0,
		bloodline              = 0
	},
	NewPetInfo = lists:foldl(fun
		(Module, PetAcc) ->
			Module:recalc(PetAcc)
	end, ResetPet, 
	[mod_pet_base, mod_pet_buff, mod_pet_equip]),
	reload_pet_info(NewPetInfo),
	NewPetInfo.