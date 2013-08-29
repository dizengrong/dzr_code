%% Author: Administrator
%% Created: 2012-6-12
%% Description: TODO: Add description to check_items
-module(check_items).

%%
%% Include files economy
%%
-include("common.hrl").

%%
%% Exported Functions
%%
-export([
		 createItems/2,
		 createItemsOnRole/3,
		 useNumByItemID/3,
		 useNumByWorldID/3,
		 throwByWorldID/2,
		 buyItem/4,
		 sellItems/3,
		 moveItem/4,
		 expandVolume/3,
		 splitItem/3,
		 cleanItems/1,
		 unequipItem/3,
		 equipItem/4,
		 intenItem/3,
		 qilingItem/2,
		 xilianItem/3,
		 getXilianStar/2,
		 getIntenRate/2,
		 lockXilianStar/3,
		 upgrateItem/3,
		 upItemQuality/2,
		 inlayJewel/4,
		 backoutJewel/3,
		 addIntenRate/3,
		 collect/1 
		]).

-export([get_convert_times/4,
		is_enough_sliver/3,
		is_possible/2,
		is_enough_stone_num/2,
		compose_stone/4,
		compose_stone_list/3,
		convert_stone/4,
		convert_stone_list/4,
		carve_stone/4,
		carve_stone_list/3
		]).
%%
%% API Functions
%%
createItems(AccountID, ItemList) ->
	?INFO(items, "ItemList=~w", [ItemList]),
	NewItemList = base_items:fillItems(ItemList),
	ItemNum = erlang:length(NewItemList),
	case cache_items:getBagNullNum(AccountID, 1) of
		NullNum when ItemNum > NullNum ->
			{fail, ?ERR_ITEM_BAG_NOT_ENOUGH};
		_ ->
			{ok, NewItemList}
	end.

createItemsOnRole(AccountID,RoleID,ItemList) ->
	F1 = fun({ItemID,_IsBind}) ->
		CfgItem = data_items:get(ItemID),
		CfgItem#cfg_item.cfg_SecondType
		end,
	PosList1 = lists:map(F1,ItemList),
	ItemsOnRole = cache_items:getItemsByRole(AccountID, RoleID),
	F2 = fun(Item) ->
		CfgItem = data_items:get(Item#item.cfg_ItemID),
		CfgItem#cfg_item.cfg_SecondType
		end,
	PosListOnRole = lists:map(F2,ItemsOnRole),
	case length(PosList1 -- [1,2,3,4,5,6,7,8]) =:= 0 of
		true ->	
			case length(PosListOnRole -- PosList1) =:= length(PosListOnRole) of
				true ->
					{ok,ItemList};
				false ->
					{fail,?ITEM_CREATE_POS_NOTNULL}
			end;
		false ->
			{fail,?ITEM_CREATE_POS_ERR}
	end.


useNumByItemID(AccountID, ItemID, ItemNum) ->
	ItemList = cache_items:getItemByItemID(AccountID, ?BAG_TYPE_BAG, ItemID),
	F = fun(Item, Sum) ->
				Sum + Item#item.gd_StackNum
		end,
	SumNum = lists:foldl(F, 0, ItemList),
	case SumNum < ItemNum of
		true ->
			{fail, ?ERR_ITEM_NOT_ENOUGH};
		false ->
			{ok, ItemList}
	end.

useNumByWorldID(AccountID, WorldID, ItemNum) ->
	case cache_items:getItemByWorldID(AccountID, WorldID) of
		[] ->
			{fail, ?ERR_ITEM_NOT_EXIST};
		Item ->
			ItemID = Item#item.cfg_ItemID,
			CfgItem = data_items:get(ItemID),
			IsUse = CfgItem#cfg_item.cfg_IsUse,
			case IsUse =:= ?ITEM_USE_Y of
				false ->
					{fail, ?ERR_ITEM_NOT_USE};
				true ->
					case Item#item.gd_StackNum < ItemNum of
						true ->
							{fail, ?ERR_ITEM_NOT_ENOUGH};
						false ->
							case checkSkillBook(AccountID,CfgItem) of
								true ->
									{ok, Item};
								false ->
									{fail,?ERR_SKILL_NOT_EXIST}
							end
					end
			end
	end.

throwByWorldID(AccountID, WorldID) ->
	case cache_items:getItemByWorldID(AccountID, WorldID) of
		[] ->
			{fail, ?ERR_ITEM_NOT_EXIST};
		Item ->
			CfgItem = data_items:get(Item#item.cfg_ItemID),
			case CfgItem#cfg_item.cfg_IsThrow =:= 0 of
				true ->
					{fail, ?ERR_ITEM_NOT_THROW};
				false ->
					case erlang:length(Item#item.gd_InlayInfo) > 0 of
						true ->
							{fail, ?ERR_ITEM_EQUIP_INLAY_STONE};
						false ->
							{ok, Item}
					end
			end
	end.

buyItem(AccountID, 0, ItemID, ItemNum) ->
	%% TODO 检查NPC
	case cache_items:getBagNullNum(AccountID, ?BAG_TYPE_BAG) of
		NullNum when NullNum =< 0 ->
			{fail, ?ERR_ITEM_BAG_NOT_ENOUGH};
		NullNum ->
			ItemList = [{ItemID, ItemNum, 1}],
			NewItemList = base_items:stackItems(ItemList),
			CellNum = erlang:length(NewItemList),
			case NullNum < CellNum of
				true ->
					{fail, ?ERR_ITEM_BAG_NOT_ENOUGH};
				false ->
					CfgItem = data_items:get(ItemID),
					BuySilver = CfgItem#cfg_item.cfg_BuySilver,
					SumSilver = BuySilver * ItemNum,
					case mod_economy:check_silver(AccountID, SumSilver) of
						false ->
							{fail, ?ERR_NOT_ENOUGH_SILVER};
						true ->
							{ok, NewItemList, SumSilver}
					end
			end
	end;

buyItem(AccountID, NPCID, ItemID, ItemNum) when NPCID =/= 0 ->
	%% TODO 检查NPC
	NPCCheck = 
	case NPCID of
		9999 -> %% 爬塔购买面板
			Floor = mod_marstower:getAchieveFloor(AccountID),
			check_marstower_buy(Floor,ItemID);
		_Else ->
			true
	end,
	case NPCCheck of
		true ->
			case cache_items:getBagNullNum(AccountID, ?BAG_TYPE_BAG) of
				NullNum when NullNum =< 0 ->
					{fail, ?ERR_ITEM_BAG_NOT_ENOUGH};
				NullNum ->
					ItemList = [{ItemID, ItemNum, 1}],
					NewItemList = base_items:stackItems(ItemList),
					CellNum = erlang:length(NewItemList),
					case NullNum < CellNum of
						true ->
							{fail, ?ERR_ITEM_BAG_NOT_ENOUGH};
						false ->
							CfgItem = data_items:get(ItemID),
							BuyGold = CfgItem#cfg_item.cfg_BuyGold,
							SumGold = BuyGold * ItemNum,
							BuySilver = CfgItem#cfg_item.cfg_BuySilver,
							SumSilver = BuySilver * ItemNum,
							case mod_economy:check_gold(AccountID, SumGold) of
								false ->
									{fail, ?ERR_NOT_ENOUGH_GOLD};
								true ->
									case mod_economy:check_silver(AccountID, SumSilver) of
										false ->
											{fail, ?ERR_NOT_ENOUGH_SILVER};
										true ->
											{ok, NewItemList, SumSilver,SumGold}
									end
							end
					end
			end;
		{fail,ErrCode} ->
			{fail, ErrCode}
	end.


sellItems(AccountID, _NPCID, ItemList) ->
	%% TODO 检查NPC
	case sellItems1(AccountID, ItemList) of
		{fail, ErrCode} ->
			{fail, ErrCode};
		{ok, NewItemList, SellSumSilver} ->
			{ok, NewItemList, SellSumSilver}
	end.

sellItems1(_AccountID, []) ->
	{ok, [], 0};
sellItems1(AccountID, [WorldID|RestItemList]) ->
	case cache_items:getItemByWorldID(AccountID, WorldID) of
		[] ->
			{fail, ?ERR_ITEM_NOT_EXIST};
		Item ->
			CfgItem = data_items:get(Item#item.cfg_ItemID),
			case CfgItem#cfg_item.cfg_SellSilver =< 0 of
				true ->
					{fail, ?ERR_ITEM_NOT_SELL};
				false ->
					SellSilver = CfgItem#cfg_item.cfg_SellSilver,
					case sellItems1(AccountID, RestItemList) of
						{fail, ErrCode} ->
							?ERR(items, "ErrCode=~w", [ErrCode]),
							{fail, ErrCode};
						{ok, RestItemList1, RestSellSilver} ->
							?ERR(items, "RestItemList1=~w, RestSellSilver=~w", [RestItemList1, RestSellSilver]),
							{ok, [Item|RestItemList1], RestSellSilver + SellSilver}
					end
			end
	end.

cleanItems(BagType) ->
	case BagType > 2 of
		true ->
			{fail, ?ERR_ITEM_ILLEGAL_BAG_POS};
		false ->
			ok
	end.

moveItem(AccountID, WorldID, BagType, BagPos) ->
	case cache_items:getItemByWorldID(AccountID, WorldID) of
		[] ->
			{fail, ?ERR_ITEM_NOT_EXIST};
		Item ->
			BagType1 = Item#item.gd_BagType,
			BagPos1 = Item#item.gd_BagPos,
			case (BagType =:= BagType1) andalso (BagPos =:= BagPos1) of
				true ->
					{fail, ?ERR_UNKNOWN};
				false ->
					case cache_items:getBagNum(AccountID, BagType) of
						CurrNum when CurrNum < BagPos ->
							{fail, ?ERR_ITEM_ILLEGAL_BAG_POS};
						_ ->
							{ok, Item}
					end
			end
	end.

expandVolume(AccountID, BagType, BagPos) ->
	case BagPos =< 0 of
		true ->
			{fail, ?ERR_ITEM_ILLEGAL_BAG_POS};
		false ->
			SysMaxNum = 200, %data_system:get(1),
			EndPos = min(SysMaxNum, BagPos),
			case cache_items:getBagNum(AccountID, BagType) of
				CurrNum when CurrNum >= SysMaxNum ->
					{fail, ?ERR_ITEM_BAG_OVER_MAX};
				CurrNum when CurrNum >= EndPos ->
					{fail, ?ERR_ITEM_BAG_EXTEND};
				CurrNum ->
					ExtendGold = base_items:getExpandCost(BagType, CurrNum+1, EndPos),
					case mod_economy:check_bind_gold(AccountID, ExtendGold) of
						false ->
							{fail, ?ERR_NOT_ENOUGH_GOLD};
						true ->
							{ok, ExtendGold}
					end
			end
	end.

splitItem(AccountID, WorldID, SplitNum) ->
	case cache_items:getItemByWorldID(AccountID, WorldID) of
		[] ->
			{fail, ?ERR_ITEM_NOT_EXIST};
		Item ->
			BagType = Item#item.gd_BagType,
			StackNum = Item#item.gd_StackNum,
			case BagType =:= ?BAG_TYPE_BAG of
				false ->
					{fail, ?ERR_ITEM_NOT_IN_BAG};
				true ->
					case StackNum > SplitNum of
						false ->
							{fail, ?ERR_ITEM_SPLIT_NUM};
						true ->
							{ok, Item}
					end
			end
	end.

%% ************************** 华丽的分隔线 ************************** %%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 装备处理方法														 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
qilingItem(AccountID,WorldID)->
	case cache_items:getItemByWorldID(AccountID,WorldID) of
		[] ->
			{fail,?ERR_ITEM_NOT_EXIST};
		Item ->
			CfgItem = data_items:get(Item#item.cfg_ItemID),
			case CfgItem#cfg_item.cfg_RoleLevel >= 40 andalso Item#item.gd_Quality =:=5 of
				false ->
					{fail,?ERR_ITEM_NOT_QILING};
				true ->
						case Item#item.gd_IsQiling =:= 1 of
							true ->
								{fail, ?ERR_ITEM_HAVE_QILING};
							false ->
								{SilverCost,CostItemList} = data_items:get_qiling_cost(CfgItem#cfg_item.cfg_SecondType,CfgItem#cfg_item.cfg_RoleLevel),
								case costItemsIsEnough(AccountID,CostItemList) of
									false ->
										{fail,?ERR_ITEM_NOT_ENOUGH};
									true ->
										case mod_economy:check_silver(AccountID, SilverCost) of
											false ->
												{fail, ?ERR_NOT_ENOUGH_SILVER};
											true ->	
												{ok, Item, SilverCost, CostItemList}
										end
								end
						end
			end
	end.

xilianItem(AccountID,WorldID,LockIdList) ->
	case cache_items:getItemByWorldID(AccountID,WorldID) of
		[] ->
			{fail,?ERR_ITEM_NOT_EXIST};
		Item ->
		CfgItem = data_items:get(Item#item.cfg_ItemID),
			case CfgItem#cfg_item.cfg_IsXilian =:= 1 of
				false ->
					{fail,?ERR_ITEM_NOT_XILIAN};
				true ->
					{SilverCost,GoldCostEach} = data_items:get_xilian_cost(CfgItem#cfg_item.cfg_RoleLevel),
					GoldCost = GoldCostEach*length(LockIdList),
					case mod_economy:check_silver(AccountID, SilverCost) of
						false ->
							{fail, ?ERR_NOT_ENOUGH_SILVER};
						true ->
							case mod_economy:check_bind_gold(AccountID, GoldCost) of
								false ->
									{fail, ?ERR_NOT_ENOUGH_GOLD};
								true ->	
									{ok, Item, SilverCost,GoldCost}
							end
					end
			end
	end.

lockXilianStar(AccountID, WorldID, Star) ->
	case cache_items:getItemByWorldID(AccountID,WorldID) of
		[] ->
			{fail,?ERR_ITEM_NOT_EXIST};
		Item ->
			case Star*100 =< Item#item.gd_LuckyStar of
			 	true ->
			 		{fail, ?ERR_XILIAN_LOCKSTAR_ERR};
			 	false->
			 		CfgItem = data_items:get(Item#item.cfg_ItemID),
			 		[_First|NumList] = lists:seq(Item#item.gd_LuckyStar div 100 , Star),
					GoldCost = lockXilianStarCost(CfgItem#cfg_item.cfg_RoleLevel,NumList,0),
					case mod_economy:check_bind_gold(AccountID, GoldCost) of
						false ->
							{fail, ?ERR_NOT_ENOUGH_GOLD};
						true ->	
							{ok, Item, GoldCost}
					end
			end
	end.


addIntenRate(AccountID,WorldID,AddRate)->
	case cache_items:getItemByWorldID(AccountID,WorldID) of
		[] ->
			{fail,?ERR_ITEM_NOT_EXIST};
		Item ->
			BaseRate = Item#item.gd_IntenRate,
			FailRate = Item#item.gd_IntenFailRate,
			case AddRate >= BaseRate of
				false ->
					{fail, ?ERR_ITEM_INTENSIFY_HOLERATE_MAX};
				true ->
					case FailRate+AddRate > 100 of
						true ->
							{fail, ?ERR_ITEM_INTENSIFY_HOLERATE_MAX};
						false ->
		%%					BaseRateMax = getIntenBaseRateMax(),
							BaseRateMax = data_items:get_inten_max_rate(Item#item.gd_IntensifyLevel div 5),
							case AddRate > BaseRateMax of
								true ->
									{fail,?ERR_ITEM_INTENSIFY_BASERATE_MAX};
								false ->
									GoldCostEach = data_items:get_inten_uprate_cost(Item#item.gd_IntensifyLevel div 5),
									GoldCost = GoldCostEach*(AddRate - BaseRate),
									case mod_economy:check_bind_gold(AccountID, GoldCost) of
										false ->
											{fail, ?ERR_NOT_ENOUGH_GOLD};
										true ->	
											{ok, Item, GoldCost}
									end
							end
					end
			end
	end.


getXilianStar(AccountID, WorldID) ->
	case cache_items:getItemByWorldID(AccountID,WorldID) of
		[] ->
			{fail,?ERR_ITEM_NOT_EXIST};
		Item ->
			{ok, Item}
	end.

getIntenRate(AccountID, WorldID) ->
	case cache_items:getItemByWorldID(AccountID,WorldID) of
		[] ->
			{fail,?ERR_ITEM_NOT_EXIST};
		Item ->
			{ok, Item}
	end.
 
upgrateItem(AccountID,WorldID,IsPerfect) ->
	case cache_items:getItemByWorldID(AccountID, WorldID) of
		[] ->
			{fail, ?ERR_ITEM_NOT_EXIST};
		Item ->
			ItemID = Item#item.cfg_ItemID,
			CfgItem = data_items:get(ItemID),
			case CfgItem#cfg_item.cfg_IsUpgrate =:= 1 of
				false ->
					{fail, ?ERR_ITEM_NOT_UPGRATE};
				true ->
					case Item#item.gd_BagType =/= 3 of
						true ->
							RoleLevel = 999; %% 不在人物身上，没有限制
						false ->
							RoleRec = mod_role:get_role_rec(AccountID,Item#item.gd_RoleID),
							RoleLevel = RoleRec#role.gd_roleLevel
					end,
					NextCfgItemID = data_items:get_upgrate_cfgid(ItemID),
					NextCfgItem = data_items:get(NextCfgItemID),
					case NextCfgItem#cfg_item.cfg_RoleLevel > RoleLevel of
						true ->
							{fail, ?ERR_ITEM_LEVEL_BIGGER}; %% 装备不能超过佣兵等级，如果在身上
						false ->
		%%					MaxLevel = data_items:getMaxUpgrateLevel(),
							MaxLevel = 100,
							case CfgItem#cfg_item.cfg_RoleLevel >= MaxLevel of
								true ->
									{fail, ?ERR_ITEM_UPGRATE_LEVEL_MAX};
								false ->
		 							{SilverCost,CostItemList1} = data_items:get_upgrate_cost(CfgItem#cfg_item.cfg_ItemID),
		 							case Item#item.gd_Quality =:= 1 of
		 								true ->
		 									CostItemList = CostItemList1;
		 								false ->
		 									{_SilverCost,CostItemList2} = data_items:get_upquality_cost(CfgItem#cfg_item.cfg_RoleLevel, Item#item.gd_Quality-1),
		 									CostItemList = CostItemList1++CostItemList2,
		 									?INFO(items,"CostItemList2 = ~w",[CostItemList2])
		 							end,
		 							?INFO(items,"CostItemList = ~w",[CostItemList]),
		 							GoldCost = data_items:get_perfect_upgrate_cost(Item#item.gd_IntensifyLevel div 5),
									case mod_economy:check_silver(AccountID, SilverCost) of
										false ->
											{fail, ?ERR_NOT_ENOUGH_SILVER};
										true ->
											case costItemsIsEnough(AccountID,CostItemList) of
												false ->
													{fail,?ERR_ITEM_NOT_ENOUGH};
												true -> 
													case IsPerfect =:= 1 of
														false ->
															{ok, Item, SilverCost, GoldCost, CostItemList};
														true ->
															case mod_economy:check_bind_gold(AccountID,GoldCost)  of
																false ->
																	{fail, ?ERR_NOT_ENOUGH_GOLD};
																true ->
																	{ok, Item, SilverCost, GoldCost, CostItemList}
															end
													end
											end
											
									end
							end
					end
			end
	end.

upItemQuality(AccountID,WorldID) ->
	case cache_items:getItemByWorldID(AccountID,WorldID) of
		[] ->
			{fail,?ERR_ITEM_NOT_EXIST};
		Item ->
			ItemID = Item#item.cfg_ItemID,
			CfgItem = data_items:get(ItemID),
			case CfgItem#cfg_item.cfg_IsUpquality =:= 1 of
				false ->
					{fail, ?ERR_ITEM_NOT_UPQUALITY};
				true ->
%%					MaxLevel = data_items:getMaxUpquailtyLevel(),
					MaxLevel = 5,
					case Item#item.gd_Quality >= MaxLevel of
						true ->
							{fail, ?ERR_ITEM_UPQUALITY_LEVEL_MAX};
						false ->
							{SilverCost,CostItemList} = data_items:get_upquality_cost(CfgItem#cfg_item.cfg_RoleLevel, Item#item.gd_Quality),
							case mod_economy:check_silver(AccountID, SilverCost) of
								false ->
									{fail, ?ERR_NOT_ENOUGH_SILVER};
								true ->
									case costItemsIsEnough(AccountID,CostItemList) of
										false ->
											{fail,?ERR_ITEM_NOT_ENOUGH};
										true -> 
											{ok, Item, SilverCost,CostItemList}
									end
							end
					end
			end
	end.

inlayJewel(AccountID,WorldID,JewelWorldID,Pos) ->
	case cache_items:getItemByWorldID(AccountID,WorldID) of
		[] ->
			{fail,?ERR_ITEM_NOT_EXIST};
		Item ->
			case cache_items:getItemByWorldID(AccountID,JewelWorldID) of
				[] ->
					{fail,?ERR_ITEM_STONE_NOT_EXIST};
				ItemJewel ->
					ItemID = Item#item.cfg_ItemID,
					CfgItem = data_items:get(ItemID),
					ItemJewelID = ItemJewel#item.cfg_ItemID,
					CfgItemJewel = data_items:get(ItemJewelID),
					case CfgItem#cfg_item.cfg_IsUpquality =:= 1 of
						false ->
							{fail, ?ERR_ITEM_NOT_UPQUALITY};
						true ->
							PosNum = data_items:get_equip_hole_num(Item#item.gd_IntensifyLevel div 5),       %%根据强化等级取得孔数
							case PosNum - length(Item#item.gd_InlayInfo) > 0 of		%%孔数是否足够
								false ->
									{fail,?ERR_ITEM_HOLE_NOT_EXIST};
								true ->
									case lists:keymember(Pos ,1, Item#item.gd_InlayInfo) of       %%位置是否被占用
										true ->
											{fail,?ERR_ITEM_HOLE_NOT_NULL};
										false ->
											case checkItemJewelType(CfgItem#cfg_item.cfg_SecondType,CfgItemJewel#cfg_item.cfg_SecondType) of  %%类型是否匹配
												false ->
													{fail,?ERR_ITEM_INLAY_TYPE_ERROR};
												true ->
													case checkJewelType(Item#item.gd_InlayInfo,CfgItemJewel#cfg_item.cfg_SecondType) of		%%类型是否已存在两个
														true ->
															{fail,?ERR_ITEM_INLAY_SAME_TYPE};
														false ->
															%%data_items:get_inlay_cost(宝石等级) -> {镶嵌银币费用, 拆卸银币消耗}
															{SilverCost,_SilverCost}=data_items:get_inlay_cost(CfgItemJewel#cfg_item.cfg_GradeLevel),
															case mod_economy:check_silver(AccountID, SilverCost) of
																false ->
																	{fail, ?ERR_NOT_ENOUGH_SILVER};
																true ->
																	{ok,Item,ItemJewel,SilverCost}
															end
													end
											end
									end
							end
					end
			end
	end.

checkItemJewelType(ItemType,JewelType) ->
	List = data_items:get_item_jewel_list(),
	lists:member({ItemType,JewelType},List).

checkJewelType(InlayInfoList,SecondType) ->
	F2 = fun(InlayInfo) ->
				 {_Pos,CfgItemID} = InlayInfo,
				 CfgItem = data_items:get(CfgItemID),
				 CfgItem#cfg_item.cfg_SecondType
		 end,
	TypeList = lists:map(F2, InlayInfoList),
	lists:member(SecondType, TypeList -- [SecondType]).


backoutJewel(AccountID,WorldID,Pos) ->
	case cache_items:getItemByWorldID(AccountID, WorldID) of
		[] ->
			{fail, ?ERR_ITEM_NOT_EXIST};
		Item -> 
			InlayInfo = Item#item.gd_InlayInfo,
			case lists:keyfind(Pos, 1 ,InlayInfo) of
				false ->
					{fail,?ERR_ITEM_HOLE_NOT_INLAY};
				{Pos, JewelCfgID} ->
					JewelCfgInfo = data_items:get(JewelCfgID),
					{_SilverCost,SilverCost} = data_items:get_inlay_cost(JewelCfgInfo#cfg_item.cfg_GradeLevel),
					case mod_economy:check_silver(AccountID, SilverCost) of
						false ->
							{fail, ?ERR_NOT_ENOUGH_SILVER};
						true ->
							case cache_items:getBagNum(AccountID, 1) > 0 of
								false ->
									{fail, ?ERR_ITEM_ILLEGAL_BAG_POS};
								true ->
									{ok,Item,JewelCfgID,SilverCost}
							end
					end
			end
	end.
		


equipItem(AccountID, WorldID, BagType, RoleID) ->
	case cache_items:getItemByWorldID(AccountID, WorldID) of
		[] ->
			{fail, ?ERR_ITEM_NOT_EXIST};
		Item ->
			case mod_role:get_role_rec(AccountID, RoleID) of
				none ->
					{fail, ?ERR_MER_NOT_EXIST};
				RoleRec ->
					RoleLevel = RoleRec#role.gd_roleLevel,
					ItemID = Item#item.cfg_ItemID,
					CfgItem = data_items:get(ItemID),
					FirstType = CfgItem#cfg_item.cfg_FirstType,
					Career = RoleRec#role.gd_careerID,
					CfgCareer = CfgItem#cfg_item.cfg_Career,
					EquipPos = CfgItem#cfg_item.cfg_SecondType,
					EquipLevel = CfgItem#cfg_item.cfg_RoleLevel,
					case FirstType =:= ?ITEM_TYPE_EQUIP of
						false ->
							{fail, ?ERR_ITEM_NOT_EQUIPMENT};
						true ->
							case (CfgCareer =:= 0) orelse (CfgCareer =:= Career) orelse (CfgCareer =:= 3 andalso Career =:= 4) of
								false ->
									{fail, ?ERR_CARRER_NOT_ALLOWED};
								true ->
									?INFO(items,"BagType = ~w,EquipPos = ~w",[BagType,EquipPos]),
									case (BagType =:= ?BAG_TYPE_ROLE) of
										false ->
											{fail, ?ERR_ITEM_ERR_EQUIP_POS};
										true ->
											case RoleLevel < EquipLevel of
												true ->
													{fail, ?ERR_NOT_ENOUGH_MER_LEVEL};
												false ->
													{ok, Item, CfgItem}
											end
									end
							end
					end
			end
	end.

unequipItem(AccountID, WorldID, BagType) ->
	case cache_items:getItemByWorldID(AccountID, WorldID) of
		[] ->
			{fail, ?ERR_ITEM_NOT_EXIST};
		Item ->
			case cache_items:getBagNullNum(AccountID, BagType) of
				NullNum when NullNum =< 0 ->
					{fail, ?ERR_ITEM_BAG_NOT_ENOUGH};
				_ ->
					case Item#item.gd_BagType =:= ?BAG_TYPE_ROLE of
						false ->
							{fail, ?ERR_ITEM_NOT_EQUIP};
						true ->
							{ok, Item}
					end
			end
	end.

intenItem(AccountID, WorldID, IsLock) ->
	case cache_items:getItemByWorldID(AccountID, WorldID) of
		[] ->
			{fail, ?ERR_ITEM_NOT_EXIST};
		Item ->
			ItemID = Item#item.cfg_ItemID,
			CfgItem = data_items:get(ItemID),
			case CfgItem#cfg_item.cfg_IsInten =:= 1 of
				false ->
					{fail, ?ERR_ITEM_NOT_EQUIP};
				true ->
%%					MaxLevel = data_items:getMaxLevel(),
					MaxLevel = 75,
					case Item#item.gd_IntensifyLevel >= MaxLevel of
						true ->
							{fail, ?ERR_ITEM_INTENSIFY_LEVEL_MAX};
						false ->
%% 							GoldCost = data_items:getUpRateCost(AddRate),
							?INFO(items,"level:~w,IntenLevel:~w",[CfgItem#cfg_item.cfg_RoleLevel, Item#item.gd_IntensifyLevel div 5]),
							{SilverCost,GoldCost1} = data_items:get_inten_cost(CfgItem#cfg_item.cfg_RoleLevel, Item#item.gd_IntensifyLevel div 5),
							case mod_economy:check_silver(AccountID, SilverCost) of
								false ->
									{fail, ?ERR_NOT_ENOUGH_SILVER};
								true ->	
									GdBaseRate = Item#item.gd_IntenRate,
									case GdBaseRate =:= 0 of
										true ->
											BaseRate = data_items:get_inten_rate(Item#item.gd_IntensifyLevel div 5);
										false ->
											BaseRate = GdBaseRate
									end,
									FailRate = Item#item.gd_IntenFailRate,
%% 									GradeLevel = CfgItem#cfg_item.cfg_GradeLevel,
%% 									EquipType = CfgItem#cfg_item.cfg_SecondType,
%% 									Career = CfgItem#cfg_item.cfg_Career,
%% 									SilverCost = base_items:getIntCost(EquipType, GradeLevel, Career),
									case IsLock =:= 1 of
										true ->
%%											MaxBaseRate = data_items:getMaxBaseIntenRate(),
											MaxBaseRate = data_items:get_inten_max_rate(Item#item.gd_IntensifyLevel div 5),
											AddRate1 = 100 - FailRate - BaseRate,
											AddRate2 = MaxBaseRate - BaseRate,
											case AddRate1 > AddRate2 of
												true ->
													AddRate = AddRate2;
												false ->
													AddRate = AddRate1
											end,
											HoldRate = BaseRate+FailRate+AddRate,
											GoldCost2 = data_items:get_inten_uprate_cost(Item#item.gd_IntensifyLevel div 5)*AddRate;
										false ->
											HoldRate = BaseRate+FailRate,
											GoldCost2 = 0
									end,
									case Item#item.gd_IntensifyLevel rem 5 =:=4 of
										true ->
											GoldCost = GoldCost1+GoldCost2;
										false ->
											GoldCost = GoldCost2
									end,
									case mod_economy:check_bind_gold(AccountID,GoldCost)  of
										false ->
											{fail, ?ERR_NOT_ENOUGH_GOLD};
										true ->
											{ok, Item, SilverCost, GoldCost, HoldRate}
									end
							end
					end
			end
	end.
%%
%% Local Functions
%%
%%

%% 采集判断
collect(NPCID) ->
	case data_items:get_collect_task(NPCID) of
		false ->
			{fail,?COLLECT_NOT_EXIT};
		[Num] ->
			{ok,Num}
	end.


costItemsIsEnough(_AccountID,[]) ->
	true;
costItemsIsEnough(AccountID,[{CfgItemID,Num}|RestCostItemList]) ->
	ItemList = cache_items:getItemByItemID(AccountID,1,CfgItemID),
	F = fun(Item, Sum) ->
			Sum + Item#item.gd_StackNum
	end,
	SumNum = lists:foldl(F, 0, ItemList),
	case Num =< SumNum of
		false -> false;
		true -> costItemsIsEnough(AccountID, RestCostItemList)
	end.

lockXilianStarCost(_ItemLevel,[],GoldCost) ->
	GoldCost;
lockXilianStarCost(ItemLevel,[FirstNum|ResNumList],GoldCost) ->
	AddCost = data_items:get_xilian_star_cost(ItemLevel,FirstNum),
	lockXilianStarCost(ItemLevel,ResNumList,GoldCost+AddCost).

%%%宝石合成===============================================================
compose_stone(Id, Cfg_item_id, Type, Num)->
	%%判断宝石数目
	case is_enough_stone_num(Id, Cfg_item_id) of 
		0 ->
			{fail,?ERR_ITEM_NOT_ENOUGH};
		_Ret ->
			%%判断钱够不够 并且与宝石数目比较，求可能合成次数
			case is_enough_sliver(Id, Cfg_item_id, Num) of
				0 ->
					{fail, ?ERR_NOT_ENOUGH_SILVER};
				Ret ->
					if 
						Type == ?ONE_STONE_ONCE ->
							 1;
						true->
							Ret
					end
			end
	end.
compose_stone_list(Id, Cfg_item_id, Num)->
	Target_cfg_item_id = data_items:get_compose_target(Cfg_item_id),
	case createItems(Id, [{Target_cfg_item_id,Num,1}]) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			Ret = {fail,ErrCode},
			Ret;	
		{ok, NewItemList1} ->
			Ret = lib_items:update_compose_stone_list(Id, Cfg_item_id, Num,NewItemList1),
			Ret
	end.

%%%宝石转化===============================================================
convert_stone(Id, From_cfg_item_id, Type, Num)-> 
	%% 检查宝石数量
	case cache_items:getItemNumByItemID(Id, ?BAG_TYPE_BAG, From_cfg_item_id) of
		0 ->
			{fail,?ERR_ITEM_STONE_NOT_EXIST};
		_ ->
			%%判断钱够不够 并且与宝石数目比较，求可能合成次数
			case get_convert_times(Id, From_cfg_item_id, Type, Num) of
				0 ->
					{fail, ?ERR_NOT_ENOUGH_SILVER};
				Ret ->
					Ret
			end
	end.
convert_stone_list(Id, From_cfg_item_id,Target_cfg_item_id,Num)->
	?INFO(item,"convert stone for ~w, From_cfg_item_id ~w to ~w, num ~w",[Id, From_cfg_item_id,Target_cfg_item_id, Num]),
	case createItems(Id, [{Target_cfg_item_id,Num,1}]) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			Ret = {fail, ErrCode},
			Ret;	
		{ok, NewItemList1} ->
			Ret = lib_items:update_convert_stone_list(Id, From_cfg_item_id,Target_cfg_item_id, Num,NewItemList1),
			Ret
	end.

%%宝石雕刻
carve_stone(Id, Cfg_item_id, Type, Num)->
	%% 检查宝石与雕刻材料数量
		Stone_num = cache_items:getItemNumByItemID(Id, ?BAG_TYPE_BAG, Cfg_item_id),
		Economy = mod_economy:get(Id),
		Cfg_item = data_items:get(Cfg_item_id),
		Stone_level = Cfg_item#cfg_item.cfg_RoleLevel,
		if 
			Stone_num == 0 ->
				{fail, ?ERR_ITEM_STONE_NOT_EXIST};
			true ->
				Material_id  = data_items:get_carve_material(Cfg_item_id),
				Material_num = cache_items:getItemNumByItemID(Id, ?BAG_TYPE_BAG, Material_id),
				if 
					Material_num == 0 ->
						{fail, ?ERR_ITEM_STONE_NOT_EXIST};
					true ->
						Silver_carve_by_level = data_items:get_carve_silver_by_level(Cfg_item_id, Stone_level),
						case Stone_num >= Material_num of
							true ->
								Possible_times1 = util:min(Material_num,
									Economy#economy.gd_silver div Silver_carve_by_level),
								Possible_times = util:min(Num, Possible_times1),
								Ret = is_possible(Possible_times, Type),
								Ret;
							false ->
								Possible_times1 = util:min(Stone_num,
									Economy#economy.gd_silver div Silver_carve_by_level),
								Possible_times = util:min(Num, Possible_times1),
								Ret = is_possible(Possible_times, Type),
								Ret
						end
				end
		end.

carve_stone_list(Id, Cfg_item_id, Num)->
	?INFO(item,"carve stone for Id:~w, Cfg_item_id ~w, num ~w",[Id, Cfg_item_id, Num]),
	Target_cfg_item_id = data_items:get_carve_target(Cfg_item_id),
	case createItems(Id, [{Target_cfg_item_id,Num,1}]) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			Ret = {fail, ErrCode, 0},
			Ret;	
		{ok, NewItemList1} ->
			Ret = lib_items:update_carve_stone_list(Id, Cfg_item_id, Num,NewItemList1),
			Ret
	end.

is_possible(Possible_times, Type)->
	Ret = if 
			Possible_times == 0 ->
				{fail, ?ERR_NOT_ENOUGH_SILVER};
			Type == ?ONE_STONE_ONCE ->
				1;
			true->
				Possible_times
		end,
	Ret.

is_enough_stone_num(Id, Cfg_item_id)->
	Stone_num = cache_items:getItemNumByItemID(Id,?BAG_TYPE_BAG, Cfg_item_id),
	Cfg_item = data_items:get(Cfg_item_id),
	Stone_level = Cfg_item#cfg_item.cfg_RoleLevel,	
	Stone_compose_num = data_items:get_compose_num_by_level(Stone_level), 
	Ret = Stone_num div Stone_compose_num,
	Ret.
is_enough_sliver(Id, Cfg_item_id, Num)->
	Stone_num = cache_items:getItemNumByItemID(Id,?BAG_TYPE_BAG, Cfg_item_id),
	Cfg_item = data_items:get(Cfg_item_id),
	Stone_level = Cfg_item#cfg_item.cfg_RoleLevel,	
	Economy = mod_economy:get(Id),
	Stone_compose_num = data_items:get_compose_num_by_level(Stone_level), 
	?INFO(item,"Stone_num:~w,Stone_level:~w,Stone_compose_num:~w",[Stone_num,Stone_level,Stone_compose_num]),
	Silver_compose = data_items:get_compose_silver_by_level(Cfg_item_id,Stone_level),
	?INFO(item,"Sliver_compose:~w",[Silver_compose]),
	Possible_times1 = util:min(Stone_num div Stone_compose_num,
			Economy#economy.gd_silver div Silver_compose), 
	Possible_times = util:min(Possible_times1,Num), 
	Possible_times.

get_convert_times(Id, From_cfg_item_id, Type, Num)->
	Stone_num = cache_items:getItemNumByItemID(Id, ?BAG_TYPE_BAG, From_cfg_item_id),
	Cfg_item = data_items:get(From_cfg_item_id),
	Stone_level = Cfg_item#cfg_item.cfg_RoleLevel,	
	Economy = mod_economy:get(Id),
	Silver_convert_by_level = data_items:get_convert_silver_by_level(From_cfg_item_id, Stone_level),
	Possible_times1 = util:min(Stone_num,
			Economy#economy.gd_silver div Silver_convert_by_level), 
	Possible_times = util:min(Num,Possible_times1),
	Ret = if 
			Possible_times == 0 ->
				0;
			Type == ?ONE_STONE_ONCE ->
				1;
			true->
				Possible_times
	end,
	?INFO(item, "convert times ~w, item id ~w, type is ~w ", [Ret,From_cfg_item_id,Type] ),
	Ret.

check_marstower_buy(Floor,ItemID) ->
	case Floor > 2 of
		true ->
			BuyFloor = Floor -2,
			Fun = fun(F,SumList) ->
				ItemList = data_marstower:get_buy_item(F),
				SumList++ItemList
			end,
			BuyList = lists:foldl(Fun,[],lists:seq(1,BuyFloor)),
			?INFO(item,"Buy list is:~w",[BuyList]),
			case lists:member(ItemID,BuyList) of
				true ->
					true;
				false ->
					{fail,?ERR_MARSTOWER_BUY_CLOSE}
			end;
		false ->
			{fail,?ERR_MARSTOWER_BUY_CLOSE}
	end.

checkSkillBook(AccountID,CfgItem) ->
	case CfgItem#cfg_item.cfg_UseEffect of
		[] ->
			true;
		Effect ->
			case lists:keyfind(skill,1,Effect) of
				false ->
					true;
				{skill,SkillID,_Level} ->
					RoleRec = mod_role:get_main_role_rec(AccountID),
					lists:keymember(SkillID,2,RoleRec#role.gd_skill)
			end
	end.