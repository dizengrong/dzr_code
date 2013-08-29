%% Author: dzr
%% Created: 2011-12-9
%% Description: TODO: Add description to pt_28
-module(pt_28).

%%=============================================================================
%% Include files
%%=============================================================================

-include("common.hrl").


-export([read/2, write/2]).

%%=============================================================================
%% API Functions
%%=============================================================================

read(28009, _Bin) ->
	{ok, []};

read(28008, _Bin) ->
	{ok, []};

read(28001, <<EquipId:32, Times:16, BeginRate:8, RateLock:8>>) ->
	{ok, {EquipId, Times, BeginRate, RateLock}};

read(28002, <<MerId:32, FosterType:8, HowManyToCost:32, StrongWish:16, 
			  Intelligencev:16, ConstitutionWish:16, AccurateWish:16>>) ->
	{ok, {MerId, FosterType, HowManyToCost, 
		  [StrongWish, Intelligencev, ConstitutionWish, AccurateWish]}};

read(28003, <<MerId:32, Type:8, SpeedUpTimes:16>>) ->
	{ok, {MerId, Type, SpeedUpTimes}};

read(28004, <<HolyType:8, UpToLevel:8>>) ->
	{ok, {HolyType, UpToLevel}};

read(28005, _) ->
	{ok, []};

read(28006, <<Type:8, Times:8, PrePay:32>>) ->
	{ok, {Type, Times, PrePay}};

read(28007, <<FunctionId:8>>) ->
	{ok, FunctionId};

read(28010, _) ->
	{ok, []};

read(28012, _) ->
	{ok, []};

read(28013, <<ShowState:8>>) ->
	{ok, ShowState};

read(28014, BinData) ->
	{NewPetName, _} = pt:read_string(BinData),
	{ok, NewPetName};

read(Cmd, _R) ->
	?ERR(scene, "client protocal not matched:~w", [Cmd]),
    {error, protocal_no_match}.

%% write(28001, {ItemInfo, PetIntensify}) ->
%%     {ok, pt:pack(28001, <<(ItemInfo#ets_gd_world_item.gd_world_item_id):32, 
%% 						  (ItemInfo#ets_gd_world_item.cfg_item_id):32, 
%% 						  (ItemInfo#ets_gd_world_item.gd_role_id):32,
%% 						  (ItemInfo#ets_gd_world_item.gd_bag_pos):8,
%% 						  (PetIntensify#pet_intensify.left_times):16, 
%% 						  (PetIntensify#pet_intensify.begin_rate):8, 
%% 						  (PetIntensify#pet_intensify.lock_rate):8, 
%% 						  (PetIntensify#pet_intensify.init_lv):8, 
%% 						  (PetIntensify#pet_intensify.after_lv):8, 
%% 						  (PetIntensify#pet_intensify.state):8>>)};
%% 
%% write(28002, PetFosterRec) ->
%% 	[Old1, Old2, Old3, Old4 | _] = PetFosterRec#pet_foster.init_attri,
%% 	[New1, New2, New3, New4] = PetFosterRec#pet_foster.after_attri,
%%     {ok, pt:pack(28002, <<(PetFosterRec#pet_foster.mer_id):32, 
%% 						  (PetFosterRec#pet_foster.foster_type):8, 
%% 						  (PetFosterRec#pet_foster.cost):32,
%% 						  Old1:16, Old2:16, Old3:16, Old4:16, 
%% 						  New1:16, New2:16, New3:16, New4:16,
%% 						  (PetFosterRec#pet_foster.state):8>>)};
%% 
%% write(28003, PetSpeedUp) ->
%%     {ok, pt:pack(28003, <<(PetSpeedUp#pet_speed_up.mer_id):32,
%% 						  (PetSpeedUp#pet_speed_up.left_times):16,
%% 						  (PetSpeedUp#pet_speed_up.init_mer_lv):8,
%% 						  (PetSpeedUp#pet_speed_up.after_lv):8,
%% 						  (PetSpeedUp#pet_speed_up.state):8>>)};
%% 
%% write(28004, PetUpHoly) ->
%%     {ok, pt:pack(28004, <<(PetUpHoly#pet_up_holy.type):8,
%% 						  (PetUpHoly#pet_up_holy.wanted_lv):8,
%% 						  (PetUpHoly#pet_up_holy.init_lv):8,
%% 						  (PetUpHoly#pet_up_holy.after_lv):8,
%% 						  (PetUpHoly#pet_up_holy.state):8>>)};
%% 
%% write(28005, PetTax) ->
%%     {ok, pt:pack(28005, <<(PetTax#pet_tax.left_times):8,
%% 						  (PetTax#pet_tax.gain):32,
%% 						  (PetTax#pet_tax.state):8>>)};
%% 
%% write(28006, PetAlchemy1) ->
%% 	Size = length(PetAlchemy1#pet_alchemy.stones),
%% 	Bin = write_stone(PetAlchemy1#pet_alchemy.stones, <<>>),
%%     {ok, pt:pack(28006, <<(PetAlchemy1#pet_alchemy.type):8,
%% 						  (PetAlchemy1#pet_alchemy.left_times):8,
%% 						  (PetAlchemy1#pet_alchemy.cost):32,
%% 						  (PetAlchemy1#pet_alchemy.gain):32,
%% 						  Size:16, Bin/binary>>)};
%% 
%% write(28007, FunctionId) ->
%%     {ok, pt:pack(28007, <<FunctionId:8>>)};
%% 
%% write(28008, PetLevel) ->
%%     {ok, pt:pack(28008, <<PetLevel:8>>)};
%% 
write(28009, _Pet) ->
	PetName = pt:write_string("fuck"),
    {ok, pt:pack(28009, <<0:8, PetName/binary>>)};
%% 
%% write(28011, {FunctionId, ErrCode}) ->
%%     {ok, pt:pack(28011, <<FunctionId:8, ErrCode:16>>)};
%% 
%% write(28012, PetRemaider) ->
%% 	{ok, pt:pack(28012, <<(PetRemaider#pet_remaider.achieve_award):8,
%% 						  (PetRemaider#pet_remaider.daily_task_times):8,
%% 						  (PetRemaider#pet_remaider.alchemy_times):8,
%% 						  (PetRemaider#pet_remaider.runb_times):8,
%% 						  (PetRemaider#pet_remaider.runb_stone_price):32,
%% 						  (PetRemaider#pet_remaider.arean_rank):32,
%% 						  (PetRemaider#pet_remaider.arean_award):8,
%% 						  (PetRemaider#pet_remaider.left_tax_times):8>>)};
%% 
%% write(28014, {MsgCode, NewPetName}) ->
%% 	Bin = pt:write_string(NewPetName),
%%     {ok, pt:pack(28014, <<MsgCode:8, Bin/binary>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

write_stone([], BinAcc) -> BinAcc;
write_stone([{CfgItemID, 1, _, BindInfo} | Rest], BinAcc) ->
	BinAcc1 = <<CfgItemID:16, BindInfo:8, BinAcc/binary>>,
	write_stone(Rest, BinAcc1);
write_stone([{_CfgItemID, _, _, _BindInfo} | Rest], BinAcc) ->
	write_stone(Rest, BinAcc).
