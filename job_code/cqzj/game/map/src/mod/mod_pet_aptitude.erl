%% Author: dizengrong
%% Created: 2013-4-22
%% @doc: 这里实现的是t6项目中的宠物洗灵功能
-module (mod_pet_aptitude).
-include("mgeem.hrl").
-export([handle/3, get_pet_total_aptitude/1]).

%% 异兽洗灵手续费50两
-define(REFRESH_APTITUDE_SILVER_COST, 50).


get_pet_total_aptitude(PetInfoRec) ->
	case PetInfoRec#p_pet.attack_type of
        ?PET_ATTACK_TYPE_PHY ->
        	PetInfoRec#p_pet.phy_attack_aptitude +
			PetInfoRec#p_pet.phy_defence_aptitude +
			PetInfoRec#p_pet.magic_defence_aptitude +
			PetInfoRec#p_pet.max_hp_aptitude;
		_ ->
			PetInfoRec#p_pet.magic_attack_aptitude +
			PetInfoRec#p_pet.phy_defence_aptitude +
			PetInfoRec#p_pet.magic_defence_aptitude +
			PetInfoRec#p_pet.max_hp_aptitude
	end.

handle(Method, RoleID, DataIn) ->
	case Method of
		?PET_REFRESH_APTITUDE ->
			do_refresh(RoleID, DataIn);
		?PET_REFRESH_APTITUDE_REPLACE ->
			do_replace(RoleID, DataIn);
		?PET_REFRESH_APTITUDE_KEEP ->
			do_keep(RoleID, DataIn)
	end.

do_refresh(RoleID, DataIn) ->
	PetId       = DataIn#m_pet_refresh_aptitude_tos.pet_id,
	AutoBuyItem = DataIn#m_pet_refresh_aptitude_tos.auto_buy_item,
	Bind        = DataIn#m_pet_refresh_aptitude_tos.bind,
	ItemType    = case DataIn#m_pet_refresh_aptitude_tos.item_type of
		0 -> 12300118; %% 没选中洗灵丹时，默认给初级洗灵丹
		T -> T
	end,
	case refresh_check(RoleID, PetId, ItemType, AutoBuyItem, Bind) of
		{error, Reason} -> common_misc:send_common_error(RoleID, 0, Reason);
		{true, PetInfoRec, CostGold} -> 
			%% 扣除money或物品
			common_bag2:use_money(RoleID, silver_any, ?REFRESH_APTITUDE_SILVER_COST, ?CONSUME_TYPE_SILVER_PET_REFRESH_APTITUDE),
			case AutoBuyItem of
				true  -> common_bag2:use_money(RoleID, gold_unbind, CostGold, ?CONSUME_TYPE_GOLD_PET_APTITUDE_AUTO_BUY_ITEM);
				false -> mod_bag:use_item(RoleID, ItemType, 1, ?LOG_ITEM_TYPE_SHI_YONG_SHI_QU)
			end,

			PetInfoRec1 = random_refresh(PetInfoRec, ItemType),
			mod_map_pet:set_pet_info(PetId, PetInfoRec1),
			mod_map_pet:write_pet_action_log(PetInfoRec1,RoleID,?PET_ACTION_TYPE_REFRESH_APTITUDE,"异兽洗灵",0,""),

			mod_random_mission:handle_event(RoleID,?RAMDOM_MISSION_EVENT_5),
			% hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_REFRESH_APTITUDE),
			mgeer_role:send(RoleID, {apply, hook_mission_event, hook_special_event, [RoleID, ?MISSON_EVENT_REFRESH_APTITUDE]}),
			%% 完成成就
            case ItemType of
                12300120 -> %% 使用高级洗灵方式
                    mod_achievement2:achievement_update_event(RoleID, 21003, 1),
                    mod_achievement2:achievement_update_event(RoleID, 22004, 1),
                    mod_achievement2:achievement_update_event(RoleID, 23001, 1),
                    mod_achievement2:achievement_update_event(RoleID, 24002, 1);
                _ -> ignore
            end,
            Msg1 = lists:concat(["洗灵成功，消耗钱币：", ?REFRESH_APTITUDE_SILVER_COST]),
			Msg2 = case CostGold > 0 of
				true -> lists:concat(["，消耗元宝：", CostGold]);
				false -> ""
			end,
			?ROLE_SYSTEM_BROADCAST(RoleID, lists:concat([Msg1, Msg2])),
			Msg = #m_pet_refresh_aptitude_toc{succ=true, pet_info=PetInfoRec1},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_REFRESH_APTITUDE, Msg)
	end.

refresh_check(RoleID, PetId, ItemType, AutoBuyItem, _Bind) ->
	Cost = ?REFRESH_APTITUDE_SILVER_COST,
	case common_bag2:check_money_enough(silver_any, Cost, RoleID) of
		false -> {error, ?_LANG_NOT_ENOUGH_SILVER};
		true ->
			PetInfoRec = mod_map_pet:get_pet_info(RoleID, PetId),
			case AutoBuyItem of
				false ->
					case mod_bag:get_goods_num_by_typeid([1,2,3], RoleID, ItemType) of
						{ok, Num} when Num > 0 -> {true, PetInfoRec, 0};
						_ -> {error, <<"您背包中没有可用的洗灵丹">>}
					end;
				true ->
					{GoodsMoneyType, ItemPrice} = mod_shop:get_goods_price(ItemType),
					case common_bag2:check_money_enough(GoodsMoneyType, ItemPrice, RoleID) of
						false -> {error, ?_LANG_NOT_ENOUGH_GOLD};
						true  -> {true, PetInfoRec, ItemPrice}
					end
			end
	end.

random_refresh(PetInfoRec, ItemType) ->
	{FloatMin, FloatMax} = cfg_pet_aptitude:refresh_rule(ItemType),
	CurMaxAptitude = PetInfoRec#p_pet.max_aptitude,
	case PetInfoRec#p_pet.attack_type of
        ?PET_ATTACK_TYPE_PHY ->
            PAAptitude = random_single_aptitude(PetInfoRec#p_pet.phy_attack_aptitude, CurMaxAptitude, FloatMin, FloatMax),
            MAAptitude = trunc(PAAptitude/5) + 100 + random:uniform(200);
        ?PET_ATTACK_TYPE_MAGIC ->
            MAAptitude = random_single_aptitude(PetInfoRec#p_pet.magic_attack_aptitude, CurMaxAptitude, FloatMin, FloatMax),
            PAAptitude = trunc(MAAptitude/5) + 100 + random:uniform(200)
    end,
	HPAptitude = random_single_aptitude(PetInfoRec#p_pet.max_hp_aptitude, CurMaxAptitude, FloatMin, FloatMax),
	PDAptitude = random_single_aptitude(PetInfoRec#p_pet.phy_defence_aptitude, CurMaxAptitude, FloatMin, FloatMax),
	MDAptitude = random_single_aptitude(PetInfoRec#p_pet.magic_defence_aptitude, CurMaxAptitude, FloatMin, FloatMax),
	PetInfoRec#p_pet{
		phy_attack_aptitude_tmp    = PAAptitude,
		magic_attack_aptitude_tmp  = MAAptitude,
		max_hp_aptitude_tmp        = HPAptitude,
		phy_defence_aptitude_tmp   = PDAptitude,
		magic_defence_aptitude_tmp = MDAptitude
	}.


random_single_aptitude(Aptitude, CurMaxAptitude, FloatMin, FloatMax) ->
	NewAptitude = Aptitude + common_tool:random(FloatMin, FloatMax),
	if
		NewAptitude < 0 -> NewAptitude1 = 0;
		NewAptitude > CurMaxAptitude -> NewAptitude1 = CurMaxAptitude;
		true -> NewAptitude1 = NewAptitude
	end,
	NewAptitude1.


do_replace(RoleID, DataIn) ->
	PetId = DataIn#m_pet_refresh_aptitude_replace_tos.pet_id,
	PetInfo = mod_map_pet:get_pet_info(RoleID, PetId),
	#p_pet{
		max_hp_aptitude_tmp        = HPAptitudeTmp,
		phy_defence_aptitude_tmp   = PDAptitudeTmp,
		magic_defence_aptitude_tmp = MDAptitudeTmp,
		phy_attack_aptitude_tmp    = PAAptitudeTmp,
		magic_attack_aptitude_tmp  = MAAptitudeTmpD
	} = PetInfo,
	case HPAptitudeTmp == 0 andalso PDAptitudeTmp == 0 andalso
		 MDAptitudeTmp == 0 andalso PAAptitudeTmp == 0 andalso MAAptitudeTmpD == 0 of
		true -> %% something is wrong
			ignore;
		false ->
			NewPetInfo = update_pet_info(PetInfo),
			mod_role_event:notify(RoleID, {?ROLE_EVENT_PET_ZZ, NewPetInfo}),
			mod_role_pet:update_role_base(RoleID, '-', PetInfo, '+', NewPetInfo),
			mod_map_pet:write_pet_action_log(NewPetInfo,RoleID,?PET_ACTION_TYPE_REFRESH_APTITUDE,"异兽洗灵",0,""),
			Msg = #m_pet_refresh_aptitude_replace_toc{succ=true,pet_info=NewPetInfo},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_REFRESH_APTITUDE_REPLACE, Msg),
			mod_map_pet:refresh_qrhl_data(RoleID)
	end.

do_keep(RoleID, DataIn) ->
	PetId   = DataIn#m_pet_refresh_aptitude_keep_tos.pet_id,
	PetInfo = mod_map_pet:get_pet_info(RoleID, PetId),
	NewPetInfo = PetInfo#p_pet{
		max_hp_aptitude_tmp        = 0,
		phy_defence_aptitude_tmp   = 0,
		magic_defence_aptitude_tmp = 0,
		phy_attack_aptitude_tmp    = 0,
		magic_attack_aptitude_tmp  = 0
	},
	mod_map_pet:set_pet_info(PetId, NewPetInfo),
	mod_map_pet:write_pet_action_log(NewPetInfo,RoleID,?PET_ACTION_TYPE_REFRESH_APTITUDE,"异兽洗灵",0,""),
	Msg = #m_pet_refresh_aptitude_keep_toc{succ=true,pet_info=NewPetInfo},
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_REFRESH_APTITUDE_KEEP, Msg).

update_pet_info(OldPetInfo) ->
	OldAptitudeAttrs = [
		{#p_pet.max_hp_aptitude,        OldPetInfo#p_pet.max_hp_aptitude}, 
		{#p_pet.phy_defence_aptitude,   OldPetInfo#p_pet.phy_defence_aptitude}, 
		{#p_pet.magic_defence_aptitude, OldPetInfo#p_pet.magic_defence_aptitude}, 
		{#p_pet.phy_attack_aptitude,    OldPetInfo#p_pet.phy_attack_aptitude}, 
		{#p_pet.magic_attack_aptitude,  OldPetInfo#p_pet.magic_attack_aptitude}
	],
	NewAptitudeAttrs = [
		{#p_pet.max_hp_aptitude,        OldPetInfo#p_pet.max_hp_aptitude_tmp}, 
		{#p_pet.phy_defence_aptitude,   OldPetInfo#p_pet.phy_defence_aptitude_tmp}, 
		{#p_pet.magic_defence_aptitude, OldPetInfo#p_pet.magic_defence_aptitude_tmp}, 
		{#p_pet.phy_attack_aptitude,    OldPetInfo#p_pet.phy_attack_aptitude_tmp}, 
		{#p_pet.magic_attack_aptitude,  OldPetInfo#p_pet.magic_attack_aptitude_tmp}
	],
	NewPetInfo1 = mod_pet_attr:calc(OldPetInfo, '-', OldAptitudeAttrs, '+', NewAptitudeAttrs), 
	NewPetInfo2 = NewPetInfo1#p_pet{
		hp                         = NewPetInfo1#p_pet.max_hp,
		max_hp_aptitude_tmp        = 0,
		phy_defence_aptitude_tmp   = 0,
		magic_defence_aptitude_tmp = 0,
		phy_attack_aptitude_tmp    = 0,
		magic_attack_aptitude_tmp  = 0
	},
	mod_pet_attr:reload_pet_info(NewPetInfo2),
	NewPetInfo2.