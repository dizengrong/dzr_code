-module(check_xunxian).

-include("common.hrl").

-export([smelt/1,onekeySmelt/2, pickOne/2,sellOne/2,pickAll/1,sellAll/1,lock/1,getPickNum/2,getPickNumStack/2]).


smelt(AccountID) ->
	case cache_xunxian:getXunxianInfo(AccountID) of
		[] ->
			{fail, ?ERR_XUNXIAN_NOT_EXIST};
		XunxianInfo ->
			ImmortalPos = XunxianInfo#xunxian.gd_ImmortalPos,
			case XunxianInfo#xunxian.gd_FreeTimes > 0 of
				true ->
					SilverCost = 0;
				false ->
					SilverCost = data_xunxian:getSilverCost(ImmortalPos)
			end,
			case check_NullPos(XunxianInfo)>0 of
				false->
					{fail, ?ERR_XUNXIAN_ITEMS_FULL};
				true ->
					case mod_economy:check_silver(AccountID, SilverCost) of
						false ->
							{fail, ?ERR_NOT_ENOUGH_SILVER};
						true ->	
							{ok,XunxianInfo,SilverCost}
					end
			end
	end.

onekeySmelt(AccountID,Silver) ->
	case cache_xunxian:getXunxianInfo(AccountID) of
		[] ->
			{fail, ?ERR_XUNXIAN_NOT_EXIST};
		XunxianInfo ->
			StartPos = XunxianInfo#xunxian.gd_ImmortalPos,
			NullPosNum = check_NullPos(XunxianInfo),
			[EconomyInfo] = mod_economy:get_economy_status(AccountID),
			SystemSilver = EconomyInfo#economy.gd_silver,
			case Silver =:= 0 of
				true -> 
					SumSilver = SystemSilver;
				false ->
					SumSilver = Silver
			end,
			?INFO(xunxian,"SumSilver = ~w",[SumSilver]),
			case XunxianInfo#xunxian.gd_FreeTimes > 0 of
				true ->
					SilverCostFirst = 0;
				false ->
					SilverCostFirst = data_xunxian:getSilverCost(StartPos)
			end,
			case NullPosNum > 0 of
				false->
					{fail, ?ERR_XUNXIAN_ITEMS_FULL};
				true ->
					case mod_economy:check_silver(AccountID, SilverCostFirst) of
						false ->
							{fail, ?ERR_NOT_ENOUGH_SILVER};
						true ->	
							case XunxianInfo#xunxian.gd_FreeTimes > 0 of
								true ->
									UseFreeTimes = min(XunxianInfo#xunxian.gd_FreeTimes,NullPosNum),
									{PosList1, LastPos1, _SilverCost, _IsSilverEnough} = generatePosList([], StartPos, UseFreeTimes, 0, 9999999);
								false ->
									LastPos1 = StartPos,
									PosList1 = []
							end,
							{PosList2, LastPos2, SilverCost, IsSilverEnough} = generatePosList([], LastPos1, NullPosNum - length(PosList1), 0, SumSilver),
							PosList = PosList1 ++ PosList2,
							?INFO(xunxian, "PosList, LastPos, SilverCost, IsSilverEnough:[~w]",[[PosList, LastPos2, SilverCost, IsSilverEnough]]),
							{ok, XunxianInfo, PosList, LastPos2, SilverCost, IsSilverEnough}
					end
			end
	end.


pickOne(AccountID, ItemPos) ->
	case cache_xunxian:getXunxianInfo(AccountID) of
		[] ->
			{fail, ?ERR_XUNXIAN_NOT_EXIST};
		XunxianInfo ->
			case mod_items:getBagNullNum(AccountID) > 0 of
				false ->
					{fail, ?ERR_ITEM_BAG_NOT_ENOUGH};
				true ->
					ItemList = XunxianInfo#xunxian.gd_ItemList,
					case 0 < ItemPos andalso ItemPos =< length(ItemList) of
						false ->
							{fail, ?ERR_XUNXIAN_ILLEGAL_ITEM_INDEX};
						true ->
							{CfgItemID,BindInfo} = selectItemByPos(ItemList,ItemPos),
							CfgItem = data_items:get(CfgItemID),
							case CfgItem#cfg_item.cfg_SecondType =:= 9 of
								true ->
									{fail, ?ERR_XUNXIAN_ITEM_UNPICK};
								false ->
									{ok,XunxianInfo, CfgItemID, BindInfo}
							end
					end
			end
	end.


sellOne(AccountID, ItemPos) ->
	case cache_xunxian:getXunxianInfo(AccountID) of
		[] ->
			{fail, ?ERR_XUNXIAN_NOT_EXIST};
		XunxianInfo ->
			ItemList = XunxianInfo#xunxian.gd_ItemList,
			case 0 < ItemPos andalso ItemPos =< length(ItemList) of
				false ->
					{fail, ?ERR_XUNXIAN_ILLEGAL_ITEM_INDEX};
				true ->
					{CfgItemID,_BindInfo} = selectItemByPos(ItemList,ItemPos),
					CfgItem = data_items:get(CfgItemID),
					case CfgItem#cfg_item.cfg_SellSilver /= 0 of
						false ->
							{fail, ?ERR_ITEM_NOT_SELL};
						true ->
							{ok,XunxianInfo, CfgItemID}
					end
			end
	end.

pickAll(AccountID) ->
	case cache_xunxian:getXunxianInfo(AccountID) of
		[] ->
			{fail, ?ERR_XUNXIAN_NOT_EXIST};
		XunxianInfo -> 
			PickNum = getPickNumStack(XunxianInfo#xunxian.gd_ItemList,[]),
			case PickNum > 0 of
				false ->
					{fail, ?ERR_XUNXIAN_NO_ITEMS_PICK};
				true ->
					case mod_items:getBagNullNum(AccountID) >= PickNum of
						false ->
							{fail, ?ERR_ITEM_BAG_NOT_ENOUGH};
						true ->
							{ok, XunxianInfo}
					end
			end
	end.

sellAll(AccountID) ->
	case cache_xunxian:getXunxianInfo(AccountID) of
		[] ->
			{fail, ?ERR_XUNXIAN_NOT_EXIST};
		XunxianInfo -> 
			PickNum = getPickNum(XunxianInfo#xunxian.gd_ItemList,0),
			UnPickNum = length(XunxianInfo#xunxian.gd_ItemList) - PickNum,
			case UnPickNum > 0 of
				false ->
					{fail, ?ERR_XUNXIAN_NO_ITEMS_SELL};
				true ->
					{ok, XunxianInfo}
			end
	end.

lock(AccountID) ->
	case cache_xunxian:getXunxianInfo(AccountID) of
		[] ->
			{fail, ?ERR_XUNXIAN_NOT_EXIST};
		XunxianInfo -> 
			Pos = XunxianInfo#xunxian.gd_ImmortalPos,
			case Pos =:= 5 of
				true ->
					{fail,?ERR_XUNXIAN_POS_MAX};
				false ->
				GoldCost = 300,
				case mod_economy:check_gold(AccountID,GoldCost) of
					false ->
						{fail,?ERR_NOT_ENOUGH_GOLD};
					true ->
						{ok,XunxianInfo,GoldCost}
				end
			end
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%											local function												%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 从Item列表中选出某位置的Item
selectItemByPos(ItemList,Pos) ->
	{_FrontList, RearList} = lists:split(Pos-1, ItemList),
	[Item|_NewRearList] = RearList,
	Item.

%% 筛选能捡起的物品的数量
getPickNum([], Sum) ->
	Sum;
getPickNum([FirstItem|RestItemList], Sum) ->
	{CfgItemID,_BindInfo} = FirstItem,
	CfgItem = data_items:get(CfgItemID),
	case CfgItem#cfg_item.cfg_SecondType =:= 9 of
		true ->
			getPickNum(RestItemList, Sum);
		false ->
			getPickNum(RestItemList, Sum+1)
	end.

%% 筛选能使其的物品的种类（用于生成物品时背包是否足够的判断）
getPickNumStack([], SumList) ->
	length(SumList);
getPickNumStack([FirstItem|RestItemList], SumList) ->
	{CfgItemID,_BindInfo} = FirstItem,
	CfgItem = data_items:get(CfgItemID),
	case CfgItem#cfg_item.cfg_SecondType =:= 9 of
		true ->
			getPickNumStack(RestItemList, SumList);
		false ->
			case lists:keyfind(CfgItemID,1,SumList) of
				false ->
					getPickNumStack(RestItemList, [FirstItem|SumList]);
				_NotNull ->
					getPickNumStack(RestItemList, SumList)
			end
	end.

%% 检查物品列表空格的数量
check_NullPos(XunxianInfo) ->
	NullPosNum = ?MAX_ITEM_POS - length(XunxianInfo#xunxian.gd_ItemList),
	NullPosNum.

%% 生成仙人位置列表
generatePosList(PosList, LastPos, _NullPosNum, SumSilverCost , 0) ->
	{PosList, LastPos, SumSilverCost, 0};
generatePosList(PosList, LastPos, 0 ,SumSilverCost, _SumSilverOwn) ->
	{PosList, LastPos, SumSilverCost, 1};
generatePosList(PosList, LastPos, NullPosNum, SumSilverCost, SumSilverOwn) ->
	Rate = data_xunxian:getRate(LastPos),
	case util:rand(1, 100) < Rate andalso LastPos /= 5 of
		true ->
			NewImmortalPos = LastPos +1;
		false ->
			NewImmortalPos = 1
	end,
	SilverCost = data_xunxian:getSilverCost(LastPos),
	?INFO(xunxian,"Pos = ~w,SilverCost= ~w",[LastPos,SilverCost]),
	case SumSilverCost + SilverCost < SumSilverOwn of
		false ->
			generatePosList(PosList, LastPos, NullPosNum, SumSilverCost , 0);
		true ->
			generatePosList(PosList ++ [LastPos], NewImmortalPos ,NullPosNum - 1, SumSilverCost + SilverCost, SumSilverOwn)
	end.
