%% Author: Administrator
%% Created: 2012-6-12
%% Description: TODO: Add description to cache_items
-module(cache_items).

%%
%% Include files
%%
-include("common.hrl").
-define(CACHE_BAG_REF, cache_util:get_register_name(bag)).
-define(CACHE_ITEM_REF, cache_util:get_register_name(item)).

%%
%% Exported Functions
%%
-export([
		 createBag/2,
		 getBag/2,
		 getBagNum/2,
		 getBagNullCells/2,
		 getBagNullNum/2
		]).

-export([
		 getItemsByType/2,
		 getItemsByRole/2,
		 getItemByPos/4,
		 getItemByWorldID/2,
		 getItemByItemID/3,
		 getItemByItemID/4,
		 getItemNumByItemID/3  %% 包含绑定和非绑定
		]).

-export([
		 updateBagNum/3,
		 updateBagNullCells/3,
		 updateBag/1,
		 updateItem/1,
		 newItem/1,
		 deleteItem/1
		 ]).

%%
%% API Functions
%%
%% 按类型获取包包信息
getBag(AccountID, BagType) ->
	case gen_cache:lookup(?CACHE_BAG_REF, {AccountID, BagType}) of
		[] ->
			#bag{};
		[Bag] ->
			Bag
	end.

%% 根据包包类型获取包包当前的容量
getBagNum(AccountID, BagType) ->
	case gen_cache:lookup(?CACHE_BAG_REF, {AccountID, BagType}) of
		[] ->
			0;
		[Bag] ->
			Bag#bag.gd_CurrNum
	end.

%% 根据包包类型获取包包当前的空余格子列表
getBagNullCells(AccountID, BagType) ->
	case gen_cache:lookup(?CACHE_BAG_REF, {AccountID, BagType}) of
		[] ->
			[];
		[Bag] ->
			Bag#bag.gd_NullNumList
	end.

%% 根据包包类型获取包包当前的空余格子数量
getBagNullNum(AccountID, BagType) ->
	case gen_cache:lookup(?CACHE_BAG_REF, {AccountID, BagType}) of
		[] ->
			0;
		[Bag] ->
			erlang:length(Bag#bag.gd_NullNumList)
	end.

%% 根据背包类型获取该背包所有物品
getItemsByType(AccountID, BagType) ->
	case gen_cache:lookup(?CACHE_ITEM_REF, AccountID) of
		[] ->
			[];
		ItemList ->
			case BagType of
				0 ->
					ItemList;
				_ ->
					F = fun(Item) ->
								(Item#item.gd_BagType =:= BagType)
						end,
					lists:filter(F, ItemList)
			end
	end.

%% 获取玩家指定佣兵的装备列表
getItemsByRole(AccountID, RoleID) ->
	case gen_cache:lookup(?CACHE_ITEM_REF, AccountID) of
		[] ->
			[];
		ItemList ->
			F = fun(Item) ->
						(Item#item.gd_BagType =:= 3) andalso (Item#item.gd_RoleID =:= RoleID)
				end,
			lists:filter(F, ItemList)
	end.

%% 根据世界物品ID获取物品信息
getItemByWorldID(AccountID, WorldID) ->
	case gen_cache:lookup(?CACHE_ITEM_REF, {AccountID, WorldID}) of
		[] ->
			[];
		[Item] ->
			Item
	end.

getItemByItemID(AccountID, BagType, ItemID) ->
	case gen_cache:lookup(?CACHE_ITEM_REF, AccountID) of
		[] ->
			[];
		ItemList ->
			F = fun(Item) ->
						(Item#item.gd_BagType =:= BagType) andalso (Item#item.cfg_ItemID =:= ItemID)
				end,
			lists:filter(F, ItemList)
	end.

getItemByItemID(AccountID, BagType, ItemID, IsBind) ->
	case gen_cache:lookup(?CACHE_ITEM_REF, AccountID) of
		[] ->
			[];
		ItemList ->
			F = fun(Item) ->
						(Item#item.cfg_ItemID =:= ItemID)
							andalso (Item#item.gd_IsBind =:= IsBind)
							andalso (Item#item.gd_BagType =:= BagType)
				end,
			lists:filter(F, ItemList)
	end.

%% 根据包包类型和格子数获取物品信息
getItemByPos(AccountID, BagType, RoleID, BagPos) ->
	case gen_cache:lookup(?CACHE_ITEM_REF, AccountID) of
		[] ->
			[];
		ItemList ->
			F = fun(Item) ->
						(Item#item.gd_BagType =:= BagType)
							andalso (Item#item.gd_RoleID =:= RoleID)
							andalso (Item#item.gd_BagPos =:= BagPos)
				end,
			case lists:filter(F, ItemList) of
				[] ->
					[];
				[NewItem] ->
					NewItem
			end
	end.

updateBagNum(AccountID, BagType, CurrNum) ->
	gen_cache:update_element(?CACHE_BAG_REF, {AccountID, BagType}, [{#bag.gd_CurrNum, CurrNum}]).

updateBagNullCells(AccountID, BagType, NullNumList) ->
	gen_cache:update_element(?CACHE_BAG_REF, {AccountID, BagType}, [{#bag.gd_NullNumList, NullNumList}]).

updateBag(Bag) ->
	gen_cache:update_record(?CACHE_BAG_REF, Bag).

updateItem(Item) ->
	gen_cache:update_record(?CACHE_ITEM_REF, Item).

newItem(Item) ->
	gen_cache:insert(?CACHE_ITEM_REF, Item).

deleteItem(Item) ->
	gen_cache:delete(?CACHE_ITEM_REF, Item).

createBag(AccountID, BagType) ->
	InitBagNum = 30,
	BagNullList = lists:seq(1, InitBagNum),
	BagRecord = #bag{
					 key = {AccountID, BagType},
					 gd_CurrNum = InitBagNum,
					 gd_NullNumList = BagNullList
					 },
	gen_cache:insert(?CACHE_BAG_REF, BagRecord).

getItemNumByItemID(AccountID, Bag_type,CfgItemID) ->
	case gen_cache:lookup(?CACHE_ITEM_REF, AccountID) of
		[] ->
			FilterList = [];
		ItemList ->
			F = fun(Item) ->
					Item#item.cfg_ItemID =:= CfgItemID andalso Bag_type == Item#item.gd_BagType
				end,
			FilterList = lists:filter(F, ItemList)
	end,
	getItemNumFromList(FilterList).


%%
%% Local Functions
%%

%% 统计列表堆叠数量
getItemNumFromList([]) ->
	0;
getItemNumFromList([FirstItem|ResList]) ->
	ThisNum = FirstItem#item.gd_StackNum,
	ThisNum + getItemNumFromList(ResList).

