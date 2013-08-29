%% Author: XieRongFeng
%% Created: 2012-11-5
%% Description: 宠物基础属性模块
-module(mod_pet_base).

-include("mgeer.hrl").

-export([transform/1, recalc/1, recalc/2]).

transform(Pet = #p_pet{str=Str, int2=Int, con=Con, dex=Dex, men=Men, level=Level}) ->
	[
	    {#p_pet.phy_attack, 	   cfg_pet:attack(Level,  Pet#p_pet.phy_attack_aptitude, 	 Str)},
	    {#p_pet.magic_attack,	   cfg_pet:attack(Level,  Pet#p_pet.magic_attack_aptitude,   Int)},
	    {#p_pet.phy_defence,	   cfg_pet:defence(Level, Pet#p_pet.phy_defence_aptitude,    Dex)},
	    {#p_pet.magic_defence,	   cfg_pet:defence(Level, Pet#p_pet.magic_defence_aptitude,  Men)},
	    {#p_pet.max_hp,			   cfg_pet:max_hp(Level,  Pet#p_pet.max_hp_aptitude,         Con)}
	].

recalc(PetInfo) ->
	recalc(PetInfo, cfg_pet:get_base_info(PetInfo#p_pet.type_id)).

recalc(PetInfo, PetBase) ->
	PetInfo2 = PetInfo#p_pet{
		level                  = 0,
		color                  = 0,
		str                    = 0,
		int2                   = 0,
		con                    = 0,
		dex                    = 0,
		men                    = 0,
		understanding          = 0,
		max_aptitude           = 0,
		max_hp_aptitude        = 0,
		phy_defence_aptitude   = 0,
		magic_defence_aptitude = 0,
		phy_attack_aptitude    = 0,
		magic_attack_aptitude  = 0
	},
	BaseAttrs = [
		{#p_pet.level,					PetInfo#p_pet.level},
		{#p_pet.color,					PetInfo#p_pet.color},
		{#p_pet.str,					PetInfo#p_pet.base_str},
		{#p_pet.int2,					PetInfo#p_pet.base_int2},
		{#p_pet.con,					PetInfo#p_pet.base_con},
		{#p_pet.dex,					PetInfo#p_pet.base_dex},
		{#p_pet.men,					PetInfo#p_pet.base_men},
		{#p_pet.understanding, 			PetInfo#p_pet.understanding},
		{#p_pet.max_hp_aptitude,		PetInfo#p_pet.max_hp_aptitude},
		{#p_pet.phy_defence_aptitude,	PetInfo#p_pet.phy_defence_aptitude},
		{#p_pet.magic_defence_aptitude, PetInfo#p_pet.magic_defence_aptitude},
		{#p_pet.phy_attack_aptitude,	PetInfo#p_pet.phy_attack_aptitude},
		{#p_pet.magic_attack_aptitude,	PetInfo#p_pet.magic_attack_aptitude},
		{#p_pet.max_hp, 				PetBase#p_pet_base_info.add_hp},
		{#p_pet.phy_defence, 			PetBase#p_pet_base_info.add_phy_def},
		{#p_pet.magic_defence, 			PetBase#p_pet_base_info.add_magic_def},
		{#p_pet.phy_attack, 			PetBase#p_pet_base_info.add_attack},
		{#p_pet.magic_attack, 			PetBase#p_pet_base_info.add_attack}
	],
	mod_pet_attr:calc(PetInfo2, '+', BaseAttrs).