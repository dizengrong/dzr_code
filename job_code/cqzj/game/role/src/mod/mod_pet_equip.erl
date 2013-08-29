%% Author: XieRongFeng
%% Created: 2012-11-5
%% Description: 宠物装备模块
-module(mod_pet_equip).

%%
%% Include files
%%
-include("mgeer.hrl").

-define(_common_error,	?DEFAULT_UNIQUE,	?COMMON,	?COMMON_ERROR,	#m_common_error_toc).%}
-define(_goods_update,	?DEFAULT_UNIQUE,	?GOODS,		?GOODS_UPDATE,	#m_goods_update_toc).%}

%%
%% Exported Functions
%%
-export([handle/1]).

-export([equip_attrs/2, recalc/1]).

%%
%% API Functions
%%
handle({_Unique, ?PET, ?PET_EQUIP_ON, DataIn, RoleID, PID, _Line}) ->
	#m_pet_equip_on_tos{pet_id = PetID, equip_id = EquipID} = DataIn,
	case check_equip_on(RoleID, PetID, EquipID) of
		{ok, OldPet, PutOnEquip, SlotNum} ->
			SlotIndex    = slot_index(SlotNum),
			PutOnEquip2  = PutOnEquip#p_goods{bind = true, loadposition = SlotNum},
			TakeOffEquip = element(SlotIndex, OldPet#p_pet.equips),
			NewPet       = update_pet(OldPet, SlotIndex, PutOnEquip2, TakeOffEquip),
			case common_transaction:t(fun
					() ->
						update_goods(RoleID, PutOnEquip2, TakeOffEquip, 0, 0)
				 end) of
				{atomic, {ok, UpdateGoods}} ->
					mod_pet_attr:reload_pet_info(NewPet),
					common_misc:unicast2(PID, ?_goods_update{goods = UpdateGoods}),
					mod_role_pet:update_role_base(RoleID, '-', OldPet, '+', NewPet),
					mod_role_event:notify(RoleID, {?ROLE_EVENT_PET_EQUIP, [NewPet, PutOnEquip2]});
				{aborted, {bag_error, {not_enough_pos, _BagID}}} ->
					common_misc:unicast2(PID, ?_common_error{error_str = ?_LANG_EQUIP_BAG_FULL});
            	Error ->
            		?ERROR_LOG("pet put on equip error: ~p", [Error])
            end;
		{error, Msg} ->
			common_misc:unicast2(PID, ?_common_error{error_str = Msg})
	end;

handle({_Unique, ?PET, ?PET_EQUIP_OFF, DataIn, RoleID, PID, _Line}) ->
	#m_pet_equip_off_tos{pet_id=PetID, slot_num=SlotNum, bagid=BagID, position=Pos} = DataIn,
	SlotIndex = slot_index(SlotNum),
	case check_equip_off(RoleID, PetID, SlotIndex) of
		{ok, OldPet, TakeOffEquip} ->
			NewPet = update_pet(OldPet, SlotIndex, undefined, TakeOffEquip),
			case common_transaction:t(fun
					() ->
						update_goods(RoleID, undefined, TakeOffEquip, BagID, Pos)
				 end) of
				{atomic, {ok, UpdateGoods}} ->
					mod_pet_attr:reload_pet_info(NewPet),
					common_misc:unicast2(PID, ?_goods_update{goods = UpdateGoods}),
					mod_role_pet:update_role_base(RoleID, '-', OldPet, '+', NewPet);
				{aborted, {bag_error, {not_enough_pos, _BagID}}} ->
					common_misc:unicast2(PID, ?_common_error{error_str = ?_LANG_EQUIP_BAG_FULL});
            	Error ->
            		?ERROR_LOG("pet take off equip error: ~p", [Error])
            end;
		{error, Msg} ->
			common_misc:unicast2(PID, ?_common_error{error_str = Msg})
	end.

%%
%% Local Functions
%%
check_equip_on(RoleID, PetID, EquipID) ->
	case get_pet_info(RoleID, PetID) of
		Pet when is_record(Pet, p_pet) ->
			case mod_bag:check_inbag(RoleID, EquipID) of
				{ok, Equip = #p_goods{type = ?TYPE_EQUIP}} -> 
					#p_pet{bone = Bone, level = PetLv} = Pet,
					#p_goods{typeid = EquipTypeID, current_colour = EquipColour} = Equip,
					[EquipBase]  = common_config_dyn:find(equip, EquipTypeID),
					SlotNum      = EquipBase#p_equip_base_info.slot_num,
					BonePosLv    = get_pet_bone_pos_lv(Bone, SlotNum),
					MinBonePosLv = cfg_bone:get_put_equip_restrict(EquipColour),
					MinPetLv     = EquipBase#p_equip_base_info.requirement#p_use_requirement.min_level,
					if
						BonePosLv < MinBonePosLv ->
							{error, format_put_error_msg(SlotNum, MinBonePosLv, EquipColour)};
						PetLv < MinPetLv ->
							{error, format_put_error_msg(binary_to_list(EquipBase#p_equip_base_info.equipname), MinPetLv)};
						true ->
							{ok, Pet, Equip, SlotNum}
					end;
				_ -> 
					{error, <<"非法操作">>}
			end;
		_ ->
			{error, <<"非法操作">>}
	end.

check_equip_off(RoleID, PetID, SlotIndex) ->
	case get_pet_info(RoleID, PetID) of
		Pet when is_record(Pet, p_pet) ->
			case element(SlotIndex, Pet#p_pet.equips) of
				Equip when is_record(Equip, p_goods) ->
					{ok, Pet, Equip};
				_ ->
					{error, <<"非法操作">>}
			end;
		_ ->
			{error, <<"非法操作">>}
	end.

update_pet(Pet, SlotIndex, PutOnEquip, TakeOffEquip) ->
	Equips = setelement(SlotIndex, Pet#p_pet.equips, PutOnEquip),
	calc(Pet#p_pet{equips = Equips}, '-', TakeOffEquip, '+', PutOnEquip).

calc(Pet, Op1, Equip1, Op2, Equip2) ->
	Transform = transformer(Pet),
	calc2(calc2(Pet, Transform, Op1, Equip1), Transform, Op2, Equip2).

calc2(Pet, Transform, Op, Equip) ->
	mod_pet_attr:calc(Pet, Op, Transform(Equip)).

transformer(Pet) ->
	fun
		(Equip) when is_record(Equip, p_goods) ->
			SlotNum = case Equip#p_goods.loadposition > 0 of
				true ->
					Equip#p_goods.loadposition;
				false ->
					[EquipBase] = common_config_dyn:find_equip(Equip#p_goods.typeid),
					EquipBase#p_equip_base_info.slot_num
			end, 
			Bonelv = get_pet_bone_pos_lv(Pet#p_pet.bone, SlotNum),
			equip_attrs(Equip, Bonelv);
		(_) -> []
	end.

equip_attrs(#p_goods{add_property = Prop}, BonePosLv) ->
	AddRate = cfg_bone:get_equip_added(BonePosLv),
	lists:map(fun
		({Index, Value}) ->
			{Index, trunc(Value * (1 + AddRate))}
	end, mod_pet_attr:transform(Prop));
equip_attrs(_, _) -> [].

update_goods(RoleID, PutOnEquip, TakeOffEquip, BagID, Pos) ->
	{ok, TakeOffEquips} = case is_record(TakeOffEquip, p_goods) of
		true ->
			TakeOffEquip2 = TakeOffEquip#p_goods{loadposition = 0, state = ?GOODS_STATE_NORMAL},
			if
				BagID > 0, Pos > 0 ->
					mod_bag:create_goods_by_p_goods_and_id(RoleID, BagID, Pos, TakeOffEquip2);
				true ->
					mod_bag:create_goods_by_p_goods_and_id(RoleID, TakeOffEquip2)
			end;
		_ ->
			{ok, []}
	end,
	UpdateGoods = case is_record(PutOnEquip, p_goods) of
		true ->
			mod_bag:delete_goods(RoleID, PutOnEquip#p_goods.id),
			[PutOnEquip#p_goods{current_num = 0}|TakeOffEquips];
		_ ->
			TakeOffEquips
	end,
	{ok,  UpdateGoods}.

slot_index(?PUT_PET_HEAD)	-> #p_pet_equips.head;
slot_index(?PUT_PET_BODY) 	-> #p_pet_equips.body;
slot_index(?PUT_PET_LEG)  	-> #p_pet_equips.leg;
slot_index(?PUT_PET_WAIST)	-> #p_pet_equips.waist;
slot_index(?PUT_PET_NECK) 	-> #p_pet_equips.neck;
slot_index(?PUT_PET_HAND) 	-> #p_pet_equips.hand.

get_pet_bone_pos_lv(PetBone, SlotNum) ->
	case slot_index(SlotNum) of
		#p_pet_equips.head  -> PetBone#p_pet_bone.head_lv;
		#p_pet_equips.body  -> PetBone#p_pet_bone.body_lv;
		#p_pet_equips.leg   -> PetBone#p_pet_bone.leg_lv;
		#p_pet_equips.waist -> PetBone#p_pet_bone.waist_lv;
		#p_pet_equips.neck  -> PetBone#p_pet_bone.neck_lv;
		#p_pet_equips.hand  -> PetBone#p_pet_bone.hand_lv;
		_                   -> 0
	end.

get_pet_info(RoleID, PetID) ->
	case PetID == 0 of
		true ->
			get_summoned_pet_info(RoleID);
		false ->
			mod_role_tab:get(RoleID, {?ROLE_PET_INFO,PetID})
	end.

get_summoned_pet_info(RoleID) ->
	case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
		undefined ->
			undefined;
		PetID ->
			mod_role_tab:get(RoleID, {?ROLE_PET_INFO,PetID})
	end.

format_put_error_msg(Pos, MinBonePosLv, Colour) ->
	case Pos of
		?PUT_PET_HEAD -> Str  = "头骨";
		?PUT_PET_BODY -> Str  = "胸骨";
		?PUT_PET_LEG -> Str   = "腿骨";
		?PUT_PET_WAIST -> Str = "腰骨";
		?PUT_PET_NECK -> Str  = "胫骨";
		?PUT_PET_HAND -> Str  = "趾骨"
	end,
	case Colour of
		?COLOUR_WHITE -> ColourStr  = "白色";
		?COLOUR_GREEN -> ColourStr  = "绿色";
		?COLOUR_BLUE -> ColourStr   = "蓝色";
		?COLOUR_PURPLE -> ColourStr = "紫色";
		?COLOUR_ORANGE -> ColourStr = "橙色";
		?COLOUR_GOLD -> ColourStr   = "金色"
	end,
	Str ++ "等级不够，需要修炼到" ++ 
		integer_to_list(MinBonePosLv) ++ "级，才能穿戴" ++ ColourStr ++ "装备".

format_put_error_msg(Equipname, MinPeriodLv) ->
	"【" ++ Equipname ++ "】是" ++ integer_to_list(MinPeriodLv) ++ 
		"级装备，需要宠物达到" ++ integer_to_list(MinPeriodLv) ++ "级才能穿上".

recalc(PetInfo) ->
	#p_pet{equips = PetEquips} = PetInfo,
	Transform = transformer(PetInfo),
	lists:foldl(fun(SlotIndex, PetAcc) ->
		case element(SlotIndex, PetEquips) of
			Equip when is_record(Equip, p_goods) ->
				calc2(PetAcc, Transform, '+', Equip);
			_ ->
				PetAcc
		end
	end, PetInfo, lists:seq(#p_pet_equips.head, size(PetEquips))).