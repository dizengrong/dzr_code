%%% -------------------------------------------------------------------
%%% Author  : xierongfeng
%%% Description : 特殊BUFF模块
%%%
%%% Created : 2013-5-21
%%% -------------------------------------------------------------------

-module(mod_special_buff).

-export([calc/3]).

-include("mgeer.hrl").

%%离魂术BUFF效果：解散所有宠物 
calc(RoleBase, '+', #p_actor_buf{buff_id = ?BUFF_ID_LI_HUN}) ->
	RoleID     = RoleBase#p_role_base.role_id,
	RolePetBag = #p_role_pet_bag{
		summoned_pet_id = SummonedPetID,
		hidden_pets     = HiddenPets
	} = mod_map_pet:get_role_pet_bag_info(RoleID),
	Callback = #m_pet_call_back_tos{pet_id = SummonedPetID, is_hidden = false},
	self() ! {?DEFAULT_UNIQUE, ?PET, ?PET_CALL_BACK, Callback, RoleID, undefined, 0},
	mod_map_pet:set_role_pet_bag_info(RoleID, RolePetBag#p_role_pet_bag{hidden_pets = []}),
	mod_role_pet:calc(RoleBase, 
		[{'-', mod_map_pet:get_pet_info(RoleID, HiddenPetID)}||HiddenPetID <- HiddenPets]);
calc(RoleBase, _, _) -> RoleBase.