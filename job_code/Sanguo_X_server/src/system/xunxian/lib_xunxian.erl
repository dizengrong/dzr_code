-module(lib_xunxian).

-include("common.hrl").

-export([	setXunxianInfo/1,
			getXunxianInfo/1,
			smelt/2,
			pickOne/5,
			sellOne/4,
			pickAll/2,
			sellAll/2,
			onekeySmelt/4,
			lock/3
		]).

setXunxianInfo(AccountID) ->
	XunxianInfo = cache_xunxian:getXunxianInfo(AccountID),
	case util:check_other_day(XunxianInfo#xunxian.gd_LastTime) of
		true ->
			NewXunxianInfo = XunxianInfo#xunxian{gd_FreeTimes = ?MAX_FREE_XUNXIAN_TIMES},
			update(NewXunxianInfo),
			{ok, NewXunxianInfo};
		false ->
			{ok, XunxianInfo}
	end.

getXunxianInfo(AccountID) ->
	XunxianInfo = cache_xunxian:getXunxianInfo(AccountID),
	{ok,XunxianInfo}.


smelt(XunxianInfo, SilverCost) ->
	AccountID = XunxianInfo#xunxian.gd_AccountID,
	ImmortalPos = XunxianInfo#xunxian.gd_ImmortalPos,
	Rate = data_xunxian:getRate(ImmortalPos),
	case util:rand(1, 100) < Rate andalso ImmortalPos /= 5 of
		true ->
			NewImmortalPos = ImmortalPos +1;
		false ->
			NewImmortalPos = 1
	end,
	case XunxianInfo#xunxian.gd_FreeTimes >0 of
		true ->
			NewFreeTimes = XunxianInfo#xunxian.gd_FreeTimes -1;
		false ->
			NewFreeTimes = 0
	end,
	NewItemInfo = generateItem(ImmortalPos),
	NewXunxianInfo = XunxianInfo#xunxian{
					gd_ImmortalPos = NewImmortalPos, 
					gd_ItemList    = XunxianInfo#xunxian.gd_ItemList ++ [NewItemInfo], 
					gd_FreeTimes   = NewFreeTimes,
					gd_LastTime    = util:unixtime()
					},
	mod_economy:use_silver(AccountID,SilverCost,?SILVER_XUNXIAN_COST),
	update(NewXunxianInfo),
	mod_achieve:xunxianNotify(AccountID,1),
	{ok, NewXunxianInfo}.

onekeySmelt(XunxianInfo, PosList, LastPos, SilverCost) ->
	AccountID = XunxianInfo#xunxian.gd_AccountID,
	ItemList = generateItemList(PosList),
	mod_economy:use_silver(AccountID,SilverCost,?SILVER_XUNXIAN_COST),
	case XunxianInfo#xunxian.gd_FreeTimes > length(PosList) of
		true ->
			NewFreeTimes = XunxianInfo#xunxian.gd_FreeTimes - length(PosList);
		false ->
			NewFreeTimes = 0
	end,
	NewXunxianInfo = XunxianInfo#xunxian{
					gd_ImmortalPos = LastPos, 
					gd_ItemList    = XunxianInfo#xunxian.gd_ItemList ++ ItemList,
					gd_FreeTimes   = NewFreeTimes,
					gd_LastTime    = util:unixtime()
					},
	PickNum = check_xunxian:getPickNumStack(NewXunxianInfo#xunxian.gd_ItemList,[]),
	BagNullNum = mod_items:getBagNullNum(AccountID),
	case BagNullNum >= PickNum of
		true -> 
			IsBagEnought = 1;
		false ->
			IsBagEnought = 0
	end,
	update(NewXunxianInfo),
	mod_achieve:xunxianNotify(AccountID,length(PosList)),
	{ok,ItemList,IsBagEnought}.

pickOne(XunxianInfo, AccountID, CfgItemID, BindInfo, ItemPos) ->
	mod_items:createItems(AccountID,[{CfgItemID,1,BindInfo}],?ITEM_FROM_XUNXIAN),
	NewItemList = deleteItemByPos(XunxianInfo#xunxian.gd_ItemList,ItemPos),
	NewXunxianInfo = XunxianInfo#xunxian{gd_ItemList = NewItemList},
	update(NewXunxianInfo),
	{ok,NewXunxianInfo}.

sellOne(XunxianInfo, AccountID, CfgItemID, ItemPos) ->
	CfgItem = data_items:get(CfgItemID),
	SilverGet = CfgItem#cfg_item.cfg_SellSilver,
	mod_economy:add_silver(AccountID, SilverGet, ?SILVER_FROM_XUNXIAN_SELL_ITEM),
	NewItemList = deleteItemByPos(XunxianInfo#xunxian.gd_ItemList,ItemPos),
	NewXunxianInfo = XunxianInfo#xunxian{gd_ItemList = NewItemList},
	update(NewXunxianInfo),
	{ok,NewXunxianInfo}.


pickAll(XunxianInfo, AccountID) ->
	{PickList,UnPickList} = selectPickItem(XunxianInfo#xunxian.gd_ItemList,[],[]),
	F = fun(ItemInfo) -> 
			{CfgItemID, BindInfo} = ItemInfo,
			{CfgItemID, 1, BindInfo}
		end,
	CreateItemList = lists:map(F,PickList),
	mod_items:createItems(AccountID,CreateItemList,?ITEM_FROM_XUNXIAN),
	NewXunxianInfo = XunxianInfo#xunxian{gd_ItemList = UnPickList},
	update(NewXunxianInfo),
	{ok, NewXunxianInfo}.

sellAll(XunxianInfo, AccountID) ->
	{PickList,UnPickList} = selectPickItem(XunxianInfo#xunxian.gd_ItemList,[],[]),
	F = fun(ItemInfo,SumSilver) ->
			{CfgItemID, _BindInfo} = ItemInfo,
			CfgItem = data_items:get(CfgItemID),
			SumSilver + CfgItem#cfg_item.cfg_SellSilver
		end,
	SilverGet = lists:foldl(F,0,UnPickList),
	mod_economy:add_silver(AccountID, SilverGet, ?SILVER_FROM_XUNXIAN_SELL_ITEM),
	NewXunxianInfo = XunxianInfo#xunxian{gd_ItemList = PickList},
	update(NewXunxianInfo),
	{ok, NewXunxianInfo}.

lock(XunxianInfo, AccountID, GoldCost) ->
	mod_economy:use_gold(AccountID, GoldCost, ?GOLD_XUNXIAN_COST),
	NewXunxianInfo = XunxianInfo#xunxian{gd_ImmortalPos = 5},
	update(NewXunxianInfo),
	{ok,NewXunxianInfo}.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%											local function												%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 拾起时删除物品表中的某位置物品
deleteItemByPos(ItemList, ItemPos) ->
	{FrontList, RearList} = lists:split(ItemPos-1, ItemList),
	[_DelItem|NewRearList] = RearList,
	lists:append(FrontList, NewRearList).

%% 根据仙人位置生成一个物品
generateItem(ImmortalPos) ->
	Odds = util:rand(1,1000),
	ItemList = data_xunxian:getItemList(ImmortalPos,Odds),
	ItemOdds = util:rand(1, length(ItemList)),
	lists:nth(ItemOdds, ItemList).

%% 根据仙人位置列表生成物品列表
generateItemList([]) ->
	[];
generateItemList([First|ResPosList]) ->
	Item = generateItem(First),
	[Item]++generateItemList(ResPosList).

%% 更新catch中的寻仙数据
update(XunxianInfo) ->
	cache_xunxian:updateXunxian(XunxianInfo).

%% 筛选出可以拾起的物品
selectPickItem([],PickList,UnPickList) ->
	{PickList,UnPickList};
selectPickItem([FirstItem|RestItemList],PickList,UnPickList) ->
	{CfgItemID,_BindInfo} = FirstItem,
	CfgItem = data_items:get(CfgItemID),
	case CfgItem#cfg_item.cfg_SecondType =:= 9 of
		false ->
			selectPickItem(RestItemList, [FirstItem|PickList], UnPickList);
		true ->
			selectPickItem(RestItemList, PickList, [FirstItem|UnPickList])
	end.
