%%% -------------------------------------------------------------------
%%% Author  : xierongfeng
%%% Description : 将宠物属性加到玩家身上
%%%
%%% Created : 2013-5-21
%%% -------------------------------------------------------------------
-module (mod_role_pet).

-include("mgeer.hrl").

-export([update_role_base/5, update_role_base/3, calc/3, calc/2, recalc/2]).
-export([is_pet_equipped/2]).

update_role_base(RoleID, Op1, Pet1, Op2, Pet2) ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	RolePetBag     = mod_map_pet:get_role_pet_bag_info(RoleID),
	RoleBase2      = calc(RoleBase, RolePetBag, [{Op1, Pet1}, {Op2, Pet2}]),
	mod_role_attr:reload_role_base(RoleBase2).

update_role_base(RoleID, Calc, Pet) ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	RolePetBag     = mod_map_pet:get_role_pet_bag_info(RoleID),
	RoleBase2      = calc(RoleBase, RolePetBag, [{Calc, Pet}]),
	mod_role_attr:reload_role_base(RoleBase2).

calc(RoleBase, RolePetBag, OpList) ->
	lists:foldl(fun
		({Calc, Pet}, RoleBaseAcc) ->
			case is_pet_equipped(Pet, RolePetBag) of
				true ->
					mod_role_attr:calc(RoleBaseAcc, Calc, pet_attrs(Pet));
				_ ->
					RoleBaseAcc
			end
	end, RoleBase, OpList).

calc(RoleBase, OpList) ->
	lists:foldl(fun
		({Calc, Pet}, RoleBaseAcc) ->
			mod_role_attr:calc(RoleBaseAcc, Calc, pet_attrs(Pet))
	end, RoleBase, OpList).

is_pet_equipped(#p_pet{pet_id=PetID}, PetBag) ->
	PetID == PetBag#p_role_pet_bag.summoned_pet_id
		orelse lists:member(PetID, PetBag#p_role_pet_bag.hidden_pets).

pet_attrs(Pet) when is_record(Pet, p_pet), Pet#p_pet.attack_type == 1 -> [
	{#p_role_base.min_phy_attack,	Pet#p_pet.phy_attack},
	{#p_role_base.max_phy_attack,	Pet#p_pet.phy_attack},
	{#p_role_base.min_magic_attack,	Pet#p_pet.phy_attack},
	{#p_role_base.max_magic_attack,	Pet#p_pet.phy_attack},
	{#p_role_base.phy_defence,		Pet#p_pet.phy_defence},
	{#p_role_base.magic_defence,	Pet#p_pet.magic_defence},
	{#p_role_base.max_hp,			Pet#p_pet.max_hp}
];
pet_attrs(Pet) when is_record(Pet, p_pet) -> [
	{#p_role_base.min_phy_attack,	Pet#p_pet.magic_attack},
	{#p_role_base.max_phy_attack,	Pet#p_pet.magic_attack},
	{#p_role_base.min_magic_attack,	Pet#p_pet.magic_attack},
	{#p_role_base.max_magic_attack,	Pet#p_pet.magic_attack},
	{#p_role_base.phy_defence,		Pet#p_pet.phy_defence},
	{#p_role_base.magic_defence,	Pet#p_pet.magic_defence},
	{#p_role_base.max_hp,			Pet#p_pet.max_hp}
];
pet_attrs(_) -> [].

recalc(RoleBase, _RoleAttr) ->
	RoleID     = RoleBase#p_role_base.role_id,
	RolePetBag = mod_map_pet:get_role_pet_bag_info(RoleID),
	OperateLst = case is_record(RolePetBag, p_role_pet_bag) of
		true ->
			lists:map(fun
				(#p_pet_id_name{pet_id = PetID}) ->
					{'+', mod_pet_attr:recalc(mod_map_pet:get_pet_info(RoleID, 	PetID))}
			end, RolePetBag#p_role_pet_bag.pets);
		_ ->
			[]
	end,
	calc(RoleBase, RolePetBag, OperateLst).

