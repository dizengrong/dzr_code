%% ====================================================================
%% Author: Administrator
%% Created: 2012-6-12
%% Description: TODO: Add description to lib_items
%% ====================================================================
-module(lib_items).

%% ====================================================================
%% Include files ITEM_FROM_STONE_BACKOUT 
%% ====================================================================
-include("common.hrl").

%% ====================================================================
%% Exported Functions 
%% ====================================================================
-export([
		 createItems/3,
		 createItemsOnRole/4,
		 useItems/4,
		 throwItem/1,
		 throwItems/2,
		 buyItems/5,
		 sellItems/3,
		 cleanItems/2,
		 moveItem/4,
		 moveBag/3,
		 expandVolume/4,
		 splitItem/2
		]).

-export([
		 getRoleAttr/3,
		 getItemsAttr/1,
		 equipItem/3,
		 unequipItem/2,
		 intenItem/4,
		 qilingItem/3,
		 xilianItem/4,
		 lockXilianStar/3,
		 addIntenRate/3,
		 upgrateItem/5,
		 upItemQuality/3,
		 inlayJewel/4,
		 backoutJewel/4,
		 getIntenAllRate/2,
		deleteSomeItems/2,
		deleteSomeItems/3
		]).

-export([collect/3]).

-export([update_compose_stone_list/4,
		 update_convert_stone_list/5,
		 update_carve_stone_list/4
		 
	]).

%% ====================================================================
%% API Functions
%% ====================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 物品基本操作方法													 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 按创建列表创建多个物品
createItems(_AccountID, [], _FromType) ->
	{ok, []};
createItems(AccountID, [{ItemID, ItemNum, IsBind}|ItemList], FromType) ->
	BagItemList = cache_items:getItemByItemID(AccountID, ?BAG_TYPE_BAG, ItemID, IsBind),
	BagType = 1,
	Desc = "",
	CfgItem = data_items:get(ItemID),
	?INFO(items,"AccountID:~w, BagType:~w, ItemNum:~w, CfgItem:~w, BagItemList:~w, Desc:~w",
			[AccountID, BagType, ItemNum, CfgItem, BagItemList, Desc]),
	case stackItems(AccountID, BagType, ItemNum, CfgItem, BagItemList, Desc) of
		{0, StackItemList} ->
			case FromType of
				?ITEM_FROM_STONE_BACKOUT ->
					skip;
				?ITEM_FROM_SPLIT ->
					skip;
				_ ->
					%% 4 紫色   5-橙色   6-红色   7金色
					case CfgItem#cfg_item.cfg_SecondType of
						?EQUIP_TYPE_FRAGMENT ->
							skip;
%% 						?MATERIAL_TYPE_FRAGMENT ->
%% 							skip;
						_ ->
							case CfgItem#cfg_item.cfg_GradeLevel >= 4 of
								true ->
									%% TODO 通知公告模块处理
									skip;
								false ->
									skip
							end
					end
			end;
		{StackItemNum, StackItemList1} ->
			?INFO(items,"StackItemNum:~w,StackItemList1:~w",[StackItemNum,StackItemList1]),
			NewItem = createItem(AccountID, ItemID, StackItemNum, IsBind, FromType, Desc),
			StackItemList = [NewItem|StackItemList1]
	end,

    %% 玩家事件钩子：背包物品数量改变
    player_events:post_event(AccountID, 'items.bag_count_alter', {ItemID, ItemNum}),

	{ok, RestItemList} = createItems(AccountID, ItemList, FromType),
	{ok, lists:append(StackItemList, RestItemList)}.

createItemsOnRole(_AccountID,_RoleID,[],_FromType) ->
	{ok,[]};
createItemsOnRole(AccountID, RoleID, [{ItemID,IsBind}|ItemList], FromType) ->
	Desc = "",
	NewItem = createItem(AccountID, 3, RoleID, ItemID, 1, IsBind, FromType, Desc),
	{ok,RestList} = createItemsOnRole(AccountID, RoleID, ItemList, FromType),
	{ok, lists:append([NewItem], RestList)}.


%% 按物品列表使用一定数量的物品
useItems(_AccountID, _RoleID, _ItemList, ItemNum) when ItemNum =< 0 ->
	{ok, []};
useItems(_AccountID, _RoleID, [], _ItemNum) ->
	{ok, []};
useItems(AccountID, RoleID, [Item|ItemList], ItemNum) ->
	ItemID = Item#item.cfg_ItemID,
	CfgItem = data_items:get(ItemID),
	UseEffect = CfgItem#cfg_item.cfg_UseEffect,
	StackNum = Item#item.gd_StackNum,
	case StackNum =< ItemNum of
		true ->
			Desc = "",
			deleteItem(Item, ?ITEM_DEL_USE, Desc),
			NewItemNum = ItemNum - StackNum,
			NewItem = getNullItem(Item),
			%% 需要在对物品列表做一下过滤，如果删除和新增的物品在同一个格子的话
			{ok, NewItemList1} = getUseEffect(AccountID, RoleID, UseEffect, ItemNum),
			{ok, RestItemList1} = useItems(AccountID, RoleID, ItemList, NewItemNum),
			NewItemList = makeReturnList(NewItem, NewItemList1),
			RestItemList = lists:foldl(fun makeReturnList/2, RestItemList1, NewItemList);
		false ->
			Desc = "",
			NewItemNum = StackNum - ItemNum,
			NewItem = Item#item{ gd_StackNum=NewItemNum },
			updateItem(NewItem, ?ITEM_DEC_USE, Desc),
			{ok, NewItemList} = getUseEffect(AccountID, RoleID, UseEffect, ItemNum),
			RestItemList = makeReturnList(NewItem, NewItemList)
	end,

    case Item#item.gd_BagType of
        ?BAG_TYPE_BAG ->
            %% 玩家事件钩子：背包物品数量改变
            player_events:post_event(AccountID, 'items.bag_count_alter', {ItemID, -ItemNum});
        _ ->
            void
    end,
	
	{ok, RestItemList}.

%% 丢弃一个物品
throwItem(Item) ->
	DelType = ?ITEM_DEL_THROW,
	Desc = "",
	deleteItem(Item, DelType, Desc),
	NewItem = getNullItem(Item),
	{ok, [NewItem]}.

%% 丢弃多个物品
throwItems(AccountID,ItemWorldIDList) ->
	DelType = ?ITEM_DEL_THROW,
	Desc = "",
	Fun = fun(ItemID) ->
		Item = cache_items:getItemByWorldID(AccountID, ItemID),
		deleteItem(Item, DelType, Desc),
		getNullItem(Item)
	end,
	NewItemList = [Fun(ItemID)||ItemID <- ItemWorldIDList],
	{ok,NewItemList}.


%% 按物品列表购买多个物品
buyItems(AccountID, _NPCID, ItemList, SilverCost, GoldCost) ->
	mod_economy:use_bind_gold(AccountID, GoldCost, ?GOLD_BUY_ITEM_COST),
	mod_economy:use_silver(AccountID, SilverCost, ?SILVER_BUY_ITEM_COST),
	%% 生成购买的物品
	ItemList1 = base_items:fillItems(ItemList),
	{ok, NewItemList} = createItems(AccountID, ItemList1, ?ITEM_FROM_SHOP),
	{ok, NewItemList}.

%% 按物品列表出售多个物品
sellItems(AccountID, ItemList, SellSumSilver) ->
	mod_economy:add_silver(AccountID, SellSumSilver, ?SILVER_FROM_ITEM_SELL),
	Desc = "",
	DelFun = fun(Item) ->
					 deleteItem(Item, ?ITEM_DEL_SHOP, Desc)
			 end,
	lists:foreach(DelFun, ItemList),
	NewItemList = lists:map(fun getNullItem/1, ItemList),
	{ok, NewItemList}.


splitItem(Item, SplitNum) ->
	{AccountID, _} = Item#item.key,
	NewStackNum = Item#item.gd_StackNum - SplitNum,
	OldItem = Item#item{ gd_StackNum=NewStackNum },
	Desc = "",
	DecType = ?ITEM_DEC_SPLIT,
	updateItem(OldItem, DecType, Desc),
	
	ItemID = Item#item.cfg_ItemID,
	BagType = Item#item.gd_BagType,
	RoleID = 0,
	IsBind = Item#item.gd_IsBind,
	FromType = ?ITEM_FROM_SPLIT,
	NewItem = createItem(AccountID, BagType, RoleID, ItemID, SplitNum, IsBind, FromType, Desc),
	{ok, [OldItem, NewItem]}.

%%武器启灵
qilingItem(Item,SilverCost,CostItemList) ->
	NewItem = Item#item{gd_IsQiling = 1},
	{AccountID, _} = Item#item.key,
	Desc = "",
	DecType = ?ITEM_FROM_QILING,
	mod_economy:use_silver(AccountID, SilverCost, ?GOLD_QILING_COST),
	NotiItemList = deleteSomeItems(AccountID,CostItemList,[]),
	updateItem(NewItem,DecType,Desc),
	if
	 	Item#item.gd_BagType == 3 ->
	 		RoleID = Item#item.gd_RoleID,
	 		mod_role:update_attri_notify(AccountID, RoleID);
	 	true ->
	 	ok
	end,
	{ok, NewItem,[NewItem|NotiItemList]}.


%%武器洗练
% #define PI 3.1415926
% int rand_by_yx()
% {
%     int rand1, rand2;
%     rand1 = rand() * PI;
%     rand2 = rand() * PI;

%     return 0.5 * (cos(min(rand1, rand2)) - cos(max(rand1, rand2)));

xilianItem(Item,SilverCost,GoldCost, LockIdList) ->
    {AccountID, _} = Item#item.key,
    Desc = "",
	DecType = ?ITEM_FROM_XILIAN,
	CfgItemID = Item#item.cfg_ItemID,
	CfgItem = data_items:get(CfgItemID),
	Star = Item#item.gd_LuckyStar div 100,
	Level = CfgItem#cfg_item.cfg_RoleLevel,
	OldXilianInfo = Item#item.gd_XilianInfo,
	?INFO(items,"OldXilianInfo = ~w",[OldXilianInfo]),
	LockedXilianInfo = takeTheLockedXilianInfo(LockIdList,OldXilianInfo,[]),
	?INFO(items,"LockedXilianInfo = ~w",[LockedXilianInfo]),
	Times1 = util:rand(3,6),
	Times2 = 6-length(LockIdList),
	if
		Times1<Times2 -> Times = Times1;
		true -> Times = Times2
	end,
	NewXilianInfo = generateNewAttrList(Star,Level, CfgItem#cfg_item.cfg_Career, CfgItem#cfg_item.cfg_SecondType,LockIdList,Times,LockedXilianInfo),
	?INFO(items,"NewXilianInfo = ~w",[NewXilianInfo]),
	%%扣除金币银币
	mod_economy:use_silver(AccountID, SilverCost, ?SILVER_XILIAN_ITEM_COST),
	mod_economy:use_bind_gold(AccountID, GoldCost, ?GOLD_XILIAN_ITEM_COST),
	%%构造新物品
	case Star<6 of
		false ->
			NewItem = Item#item{ gd_XilianInfo = NewXilianInfo};
		true ->
			NewItem = Item#item{ gd_LuckyStar = Item#item.gd_LuckyStar + 1, gd_XilianInfo = NewXilianInfo }
		end,
	%%更新物品
	updateItem(NewItem,DecType,Desc),
	if
	 	Item#item.gd_BagType == 3 ->
	 		RoleID = Item#item.gd_RoleID,
	 		mod_role:update_attri_notify(AccountID, RoleID);
	 	true ->
	 	ok
	end,
	{ok,NewItem}.

%%根据id提取已锁定的洗练属性
takeTheLockedXilianInfo([],_OldXilianInfo,LockedList) ->
	LockedList;
takeTheLockedXilianInfo([FirstId|LockIdList],OldXilianInfo,LockedList) ->
	case lists:keyfind(FirstId,1,OldXilianInfo) of
		false ->
			takeTheLockedXilianInfo(LockIdList,OldXilianInfo,LockedList);
		XilianInfo ->
			case XilianInfo of
				[] ->
					takeTheLockedXilianInfo(LockIdList,OldXilianInfo,LockedList);
				_Else ->
					takeTheLockedXilianInfo(LockIdList,OldXilianInfo,[XilianInfo|LockedList])
			end
	end.

%%根据星级和物品类型洗练出随机属性 
generateNewAttrList(_Star,_Level,_Career,_SecondType,_LockIdList,0,NewAttrList) ->
	NewAttrList;
generateNewAttrList(Star,Level,Career,SecondType,LockIdList,Times,NewAttrList) ->
	Id = generateNewId(LockIdList),
	AttrType = generateNewAttrType(Career,SecondType,NewAttrList),
	{Low,_Max} = data_items:get_xilian_attr_range(Star+1,Level,AttrType),
	{_Low,Max} = data_items:get_xilian_attr_range(10,Level,AttrType),
	Value1 = util:rand(Low,Max),
	Value = Value1 -Low,
	Attribute = Low + Value*Value div (Max-Low),
	generateNewAttrList(Star,Level,Career,SecondType,[Id|LockIdList],Times - 1,[{Id,AttrType,Attribute}|NewAttrList]).

%%为洗练属性设定一个新ID
generateNewId(LockIdList) ->
	RandomNum = util:rand(1,100),
	case lists:member(RandomNum,LockIdList) of
		false ->
			RandomNum;
		true ->
			generateNewId(LockIdList)
	end.

%%产生一个属性类型（过滤出现三个相同的情况）
generateNewAttrType(Career,SecondType,NewAttrList)->
	if 
		Career =:= 1 orelse Career =:=2 ->
			Attrlist = data_items:get_attr_type_list(SecondType) -- [2];
		Career =:=3 ->
			Attrlist = data_items:get_attr_type_list(SecondType) -- [1];
		true ->
		Attrlist = data_items:get_attr_type_list(SecondType)
	end,
	Length = length(Attrlist),
	Pos = util:rand(1,Length),
	{_FrontList, RearList} = lists:split(Pos-1, Attrlist),
	[Attr|_RearList] = RearList,
	FiltedList = lists:filter(fun({_A, B ,_C}) -> B /= Attr end,NewAttrList),
	TypeNum = length(NewAttrList) - length(FiltedList),
	case TypeNum =< 1 of
		false ->
			generateNewAttrType(Career,SecondType,NewAttrList);
		true ->
			Attr
	end.



%%锁定洗练星星等级
lockXilianStar(Item,GoldCost,Star) ->
	{AccountID, _} = Item#item.key,
	Desc = "",
	DecType = ?ITEM_FROM_XILIAN,
	mod_economy:use_bind_gold(AccountID, GoldCost, ?GOLD_XILIAN_ITEM_COST),
	NewItem = Item#item{gd_LuckyStar = Star*100},
	updateItem(NewItem,DecType,Desc),
	if
	 	Item#item.gd_BagType == 3 ->
	 		RoleID = Item#item.gd_RoleID,
	 		mod_role:update_attri_notify(AccountID, RoleID);
	 	true ->
	 	ok
	end,
	{ok, Star*100}.

%% 提高强化基础概率
addIntenRate(Item,GoldCost,AddRate) ->
	?INFO(item,"GoldCost = ~w,AddRate =~w",[GoldCost,AddRate]),
	{AccountID, _} = Item#item.key,
	Desc = "",
	DecType = ?ITEM_FROM_XILIAN,
	mod_economy:use_bind_gold(AccountID, GoldCost, ?GOLD_XILIAN_ITEM_COST),
	FailRate = Item#item.gd_IntenFailRate,
	NewBaseRate = AddRate,
	NewItem = Item#item{ gd_IntenRate = NewBaseRate },
	updateItem(NewItem,DecType,Desc),
	if
	 	Item#item.gd_BagType == 3 ->
	 		RoleID = Item#item.gd_RoleID,
	 		mod_role:update_attri_notify(AccountID, RoleID);
	 	true ->
	 	ok
	end,
	{ok, NewBaseRate, FailRate}.

%% 装备升级
upgrateItem(Item,SilverCost,GoldCost,CostItemList,IsPerfect) ->
	{AccountID, _} = Item#item.key,
	Desc = "",
	DecType = ?ITEM_FROM_UPGRATE,
	CfgItemID = Item#item.cfg_ItemID,
	NewCfgItemID = data_items:get_upgrate_cfgid(CfgItemID),
	case IsPerfect =:= 1 of
		true ->
			mod_economy:use_bind_gold(AccountID, GoldCost, ?GOLD_UPGRATE_ITEM_COST),
			mod_economy:use_silver(AccountID, SilverCost, ?SILVER_UPGRATE_ITEM_COST),
			NotiItemList = deleteSomeItems(AccountID,CostItemList,[]),
			NewItem = Item#item{cfg_ItemID = NewCfgItemID, gd_IsQiling =0, gd_LuckyStar = 0,gd_IntenRate=0,gd_IntenFailRate=0};
		false ->
			mod_economy:use_silver(AccountID, SilverCost, ?SILVER_UPGRATE_ITEM_COST),
			NotiItemList = deleteSomeItems(AccountID,CostItemList,[]),
			case Item#item.gd_IntensifyLevel > 5 of
				true ->
					NewIntenLevel = Item#item.gd_IntensifyLevel - 5;
				false ->
					NewIntenLevel = 0
			end,
			NewItem = Item#item{cfg_ItemID = NewCfgItemID, gd_IntensifyLevel = NewIntenLevel,gd_IsQiling =0,gd_LuckyStar = 0,gd_IntenRate=0,gd_IntenFailRate=0}
	end,
	updateItem(NewItem,DecType,Desc),
	if
	 	Item#item.gd_BagType == 3 ->
	 		RoleID = Item#item.gd_RoleID,
	 		mod_role:update_attri_notify(AccountID, RoleID);
	 	true ->
	 	ok
	end,
	{ok, NewItem, [NewItem|NotiItemList]}.

%% 提升装备品质
upItemQuality(Item, SilverCost, CostItemList) ->
	{AccountID, _} = Item#item.key,
	Desc = "",
	DecType = ?ITEM_FROM_UPQUALITY,
	NewItem = Item#item{gd_Quality = Item#item.gd_Quality+1},
	%% 成就通知
	mod_achieve:roleItemNotify(AccountID),
	_Info = mod_account:get_account_info_rec(AccountID),
	% mod_announcement:send_item_qualiy(AccountID, Info, NewItem),%%物品品质提升，公告发布
	mod_economy:use_silver(AccountID, SilverCost, ?SILVER_UPQUALITY_ITEM_COST),
	NotiItemList = deleteSomeItems(AccountID,CostItemList,[]),
	updateItem(NewItem,DecType,Desc),
	if
	 	Item#item.gd_BagType == 3 ->
	 		RoleID = Item#item.gd_RoleID,
	 		mod_role:update_attri_notify(AccountID, RoleID);
	 	true ->
	 	ok
	end,
	{ok, NewItem,[NewItem] ++ NotiItemList}.

%% 宝石镶嵌
inlayJewel(Item,ItemJewel,SilverCost,Pos) ->
	{AccountID, _} = Item#item.key,
	Desc = "",
	DecType = ?ITEM_FROM_INLAY,
	NewItem = Item#item{gd_InlayInfo = [{Pos,ItemJewel#item.cfg_ItemID}]++Item#item.gd_InlayInfo},
	mod_economy:use_silver(AccountID, SilverCost, ?SILVER_INLAY_ITEM_COST),
	NotiItemList = deleteSomeItems(AccountID,[{ItemJewel#item.cfg_ItemID,1}],[]),
	updateItem(NewItem,DecType,Desc),
	%% 宝石成就通知
	mod_achieve:jewelNotify(AccountID),
	%% 宝石任务通知
	mod_task:updata_inlay_task(AccountID,ItemJewel#item.cfg_ItemID,1),
	if
	 	Item#item.gd_BagType == 3 ->
	 		RoleID = Item#item.gd_RoleID,
	 		mod_role:update_attri_notify(AccountID, RoleID);
	 	true ->
	 	ok
	end,
	{ok, NewItem, [NewItem|NotiItemList]}.


%%宝石拆卸
backoutJewel(Item,JewelCfgID,SilverCost,Pos) ->
	{AccountID, _} = Item#item.key,
	Desc = "",
	FromType = ?ITEM_FROM_STONE_BACKOUT,
	mod_economy:use_silver(AccountID,SilverCost,?SILVER_BACKOUT_ITEM_COST),
	NewInlayInfo = lists:keydelete(Pos, 1, Item#item.gd_InlayInfo),
	NewItem = Item#item{gd_InlayInfo = NewInlayInfo},
	updateItem(NewItem,FromType,Desc),
	NewItem1 = createItem(AccountID, JewelCfgID, 1, 1, FromType, Desc),
	if
	 	Item#item.gd_BagType == 3 ->
	 		RoleID = Item#item.gd_RoleID,
	 		mod_role:update_attri_notify(AccountID, RoleID);
	 	true ->
	 	ok
	end,
	{ok, NewItem, [NewItem]++[NewItem1]}.
	
%% 采集
collect(NPCID,AccountID,MonsterID) ->
	case MonsterID of
		0 ->
			%% 更新采集任务
			mod_task:update_harvesting_task(AccountID,NPCID,1),
			?INFO(task,"Updata_harvesting_task,AccountID:~w,NPCID:~w,Num:1",[AccountID,NPCID]),
			ok;
		_NotNull ->
			Start = #battle_start {
                                mod      = pve,
                                type     = 0,       %% TODO: 写个真的值上去
                                att_id   = AccountID,
                                att_mer  = [],
                                monster  = MonsterID,
                                maketeam = false,
                                caller   = self(),
                                callback = {}
                            },
			?INFO(battle, "battle starting... Start = ~w", [Start]),
			battle:start(Start)
	end.

%% ************************** 华丽的分隔线 ************************** %%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 背包处理方法														 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 按包包类型整理包包的物品
cleanItems(AccountID, BagType) ->
	case cache_items:getItemsByType(AccountID, BagType) of
		[] ->
			NewItemList = [];
		ItemList1 ->
			ItemList = sortCleanItems(ItemList1),
			{Num, _} = lists:foldl(fun cleanItem/2, {1, []}, ItemList),
			BagMaxNum = cache_items:getBagNum(AccountID, BagType),
			NullNumList = lists:seq(Num, BagMaxNum),
			cache_items:updateBagNullCells(AccountID, BagType, NullNumList),
			NewItemList = cache_items:getItemsByType(AccountID, BagType)
	end,
	{ok, NewItemList}.

%% 包包内移动物品
moveItem(AccountID, Item, BagType, BagPos) ->
	RoleID = 0,
	Desc = "",
	case cache_items:getItemByPos(AccountID, BagType, RoleID, BagPos) of
		[] ->
			NullCell = Item#item.gd_BagPos,
			DestItem = Item#item{ gd_BagType=BagType,gd_BagPos=BagPos },
			updateItem(DestItem, 0, Desc),
			NullCellList = cache_items:getBagNullCells(AccountID, BagType),
			NewNullCellList = lists:delete(BagPos, [NullCell|NullCellList]),
			cache_items:updateBagNullCells(AccountID, BagType, lists:sort(NewNullCellList)),
			SrcItem = getNullItem(Item);
		Item1 ->
			ItemID = Item#item.cfg_ItemID,
			ItemNum = Item#item.gd_StackNum,
			IsBind = Item#item.gd_IsBind,
			ItemID1 = Item1#item.cfg_ItemID,
			ItemNum1 = Item1#item.gd_StackNum,
			IsBind1 = Item1#item.gd_IsBind,
			case (ItemID =:= ItemID1) andalso (IsBind =:= IsBind1) of
				false ->
					BagType1 = Item#item.gd_BagType,
					BagPos1 = Item#item.gd_BagPos,
					SrcItem = Item#item{ gd_BagType=BagType,gd_BagPos=BagPos },
					DestItem = Item1#item{ gd_BagType=BagType1,gd_BagPos=BagPos1 },
					updateItem(SrcItem, 0, Desc),
					updateItem(DestItem, 0, Desc);
				true ->
					CfgItem = data_items:get(ItemID),
					StackMax = CfgItem#cfg_item.cfg_StackMax,
					FullID = CfgItem#cfg_item.cfg_FullID,
					case (ItemNum =:= StackMax) orelse (ItemNum1 =:= StackMax) of
						true ->
							BagType1 = Item#item.gd_BagType,
							BagPos1 = Item#item.gd_BagPos,
							SrcItem = Item#item{ gd_BagType=BagType,gd_BagPos=BagPos },
							DestItem = Item1#item{ gd_BagType=BagType1,gd_BagPos=BagPos1 },
							updateItem(SrcItem, 0, Desc),
							updateItem(DestItem, 0, Desc);
						false ->
							case ItemNum + ItemNum1 - StackMax of
								NewItemNum when NewItemNum > 0 ->
									SrcItem = Item#item{ gd_StackNum=ItemNum+ItemNum1-StackMax },
									cache_items:updateItem(SrcItem),
									case FullID > 0 of
										false -> %% 非碎片
											DestItem = Item1#item{ gd_StackNum = StackMax },
											cache_items:updateItem(DestItem);
										true ->
											deleteItem(Item1, ?ITEM_DEL_FRAGMANT_COMPOS, Desc),
											RoleID = 0,
											ItemNum = 1,
											DestItem1 = createItem(AccountID, BagType, RoleID, FullID, ItemNum, IsBind, ?ITEM_FROM_FRAGMANT_COMPOS, Desc),
											case DestItem1#item.gd_BagPos =:= Item1#item.gd_BagPos of
												true ->
													DestItem = DestItem1;
												false ->
													DestItem = DestItem1#item{ gd_BagPos=Item1#item.gd_BagPos }
											end
									end;
								NewItemNum ->
									SrcItem = getNullItem(Item),
									deleteItem(Item, ?ITEM_DEL_STACK, Desc),
									case (NewItemNum =:= 0) andalso (FullID > 0) of
										false -> %% 非碎片
											DestItem = Item1#item{ gd_StackNum = ItemNum + ItemNum1 },
											cache_items:updateItem(DestItem);
										true ->
											deleteItem(Item1, ?ITEM_DEL_FRAGMANT_COMPOS, Desc),
											RoleID = 0,
											ItemNum = 1,
											DestItem1 = createItem(AccountID, BagType, RoleID, FullID, ItemNum, IsBind, ?ITEM_FROM_FRAGMANT_COMPOS, Desc),
											case DestItem1#item.gd_BagPos =:= Item1#item.gd_BagPos of
												true ->
													DestItem = DestItem1;
												false ->
													DestItem = DestItem1#item{ gd_BagPos=Item1#item.gd_BagPos }
											end
									end
							end
					end
			end
	end,										
	{ok, [SrcItem, DestItem]}.

moveBag(AccountID, Item, BagType) ->
	Desc = "",
	ItemID = Item#item.cfg_ItemID,
	IsBind = Item#item.gd_IsBind,
	
	%% 处理原物品信息
	BagType1 = Item#item.gd_BagType,
	BagPos1 = Item#item.gd_BagPos,
	NullCellList1 = cache_items:getBagNullCells(AccountID, BagType1),
	NewNullCellList1 = lists:sort([BagPos1|NullCellList1]),
	cache_items:updateBagNullCells(AccountID, BagType1, NewNullCellList1),
	
	SrcItem = getNullItem(Item),
	updateItem(SrcItem, 0, Desc),
	
	case cache_items:getItemByItemID(AccountID, BagType, ItemID, IsBind) of
		[] ->
			[BagPos|NullCellList] = cache_items:getBagNullCells(AccountID, BagType),
			cache_items:updateBagNullCells(AccountID, BagType, NullCellList),
			DestItem = Item#item{ gd_BagType=BagType,gd_BagPos=BagPos },
			updateItem(DestItem, 0, Desc),
			NewItemList = [SrcItem, DestItem];
		ItemList ->
			CfgItem = data_items:get(ItemID),
			ItemNum = Item#item.gd_StackNum,
			case stackItems(AccountID, BagType, ItemNum, CfgItem, ItemList, Desc) of
				{0, StackItemList} ->
					deleteItem(Item,?ITEM_DEL_FROM_MOVE,""),
					NewItemList = [SrcItem|StackItemList];
				{NewItemNum, StackItemList} ->
					[BagPos|NullCellList] = cache_items:getBagNullCells(AccountID, BagType),
					cache_items:updateBagNullCells(AccountID, BagType, NullCellList),
					DestItem = Item#item{ gd_BagType=BagType,gd_BagPos=BagPos,gd_StackNum=NewItemNum },
					updateItem(DestItem, 0, Desc),
					NewItemList = [SrcItem, DestItem] ++ StackItemList
			end
	end,

    %% 玩家事件钩子：背包物品数量改变
    case {Item#item.gd_BagType, BagType} of
        {?BAG_TYPE_BAG, Dest} when Dest =/= ?BAG_TYPE_BAG ->
            player_events:post_event(AccountID, 'items.bag_count_alter', {Item#item.cfg_ItemID, -(Item#item.gd_StackNum)});
        {Src, ?BAG_TYPE_BAG} when Src =/= ?BAG_TYPE_BAG ->
            player_events:post_event(AccountID, 'items.bag_count_alter', {Item#item.cfg_ItemID, Item#item.gd_StackNum});
        _ ->
            void
    end,
	
	{ok, NewItemList}.

expandVolume(AccountID, BagType, BagPos, GoldCost) ->
	case BagType of
		1 ->
			UseType = ?GOLD_EXTEND_BAG_COST;
		2 ->
			UseType = ?GOLD_EXTEND_BANK_COST
	end,
	mod_economy:use_bind_gold(AccountID, GoldCost, UseType),
	Bag = cache_items:getBag(AccountID, BagType),
	CurrBagNum = Bag#bag.gd_CurrNum,
	ExpandCellList = lists:seq(CurrBagNum+1, BagPos),
	NullCellList = Bag#bag.gd_NullNumList,
	NewNullCellList = NullCellList ++ ExpandCellList,
	NewBag = Bag#bag{ gd_CurrNum=BagPos, gd_NullNumList=NewNullCellList },
	cache_items:updateBag(NewBag),
	ok.

%% ************************** 华丽的分隔线 ************************** %%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 装备处理方法														 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 获取某玩家的所有装备属性
%% return：{原型ID,等级,属性#role_update_attri{}}
getItemsAttr(AccountID) ->
	ItemList = cache_items:getItemsByType(AccountID, 3),
	F1 = fun(Item) ->
		ItemID = Item#item.cfg_ItemID,
				 {_AccountID,_ItemWorldID} = Item#item.key,
				 IntenLevel = Item#item.gd_IntensifyLevel, %%强化等级
				 CfgItem = data_items:get(ItemID),
				 LegendAttr = data_items:get_legend_attr(CfgItem#cfg_item.cfg_SecondType,CfgItem#cfg_item.cfg_RoleLevel), %%传奇属性
				 IntenInitAttr = data_items:get_inten_attr(CfgItem#cfg_item.cfg_SecondType,CfgItem#cfg_item.cfg_RoleLevel),  %%强化属性初始成长值
				 IntenAttr = attr_multiply_quality(IntenInitAttr,IntenLevel), %%强化属性
				 QualityRate = data_items:get_quality_rate(Item#item.gd_Quality), %%品质系数
				 ?INFO(items,"LegendAttr = ~w,IntenAttr =~w,QualityRate =~w",[LegendAttr,IntenAttr,QualityRate]),
				 case Item#item.gd_IsQiling =:=1 of
				 	true ->
				 		QinglingAttr = data_items:get_qiling_attr(CfgItem#cfg_item.cfg_SecondType,CfgItem#cfg_item.cfg_RoleLevel); %%启灵属性
				 	false ->
				 		QinglingAttr = #role_update_attri{}
				 end,
				 XilianAttr = getWashAttr(Item#item.gd_XilianInfo), %%洗练属性
				 InlayAttr = getInlayAttr(Item#item.gd_InlayInfo), %%镶嵌属性
				 ItemAttr = lists:foldl(fun attr_add/2, #role_update_attri{}, [attr_multiply_quality(LegendAttr,QualityRate), attr_multiply_quality(IntenAttr,QualityRate),XilianAttr,InlayAttr,QinglingAttr]),
				 {Item#item.cfg_ItemID,CfgItem#cfg_item.cfg_RoleLevel,ItemAttr}
		end,
	lists:map(F1,ItemList).


%% 获取指定佣兵身上装备的属性和
getRoleAttr(AccountID, RoleID,RoleLevel) ->
	ItemList = cache_items:getItemsByRole(AccountID, RoleID),
	F1 = fun(Item, SumRec) ->
				 ItemID = Item#item.cfg_ItemID,
				 {_AccountID,ItemWorldID} = Item#item.key,
				 IntenLevel = Item#item.gd_IntensifyLevel, %%强化等级
				 CfgItem = data_items:get(ItemID),
				 LegendAttr = data_items:get_legend_attr(CfgItem#cfg_item.cfg_SecondType,CfgItem#cfg_item.cfg_RoleLevel), %%传奇属性
				 IntenInitAttr = data_items:get_inten_attr(CfgItem#cfg_item.cfg_SecondType,CfgItem#cfg_item.cfg_RoleLevel),  %%强化属性初始成长值
				 IntenAttr = attr_multiply_quality(IntenInitAttr,IntenLevel), %%强化属性
				 QualityRate = data_items:get_quality_rate(Item#item.gd_Quality), %%品质系数
				 ?INFO(items,"LegendAttr = ~w,IntenAttr =~w,QualityRate =~w",[LegendAttr,IntenAttr,QualityRate]),
				 case Item#item.gd_IsQiling =:=1 of
				 	true ->
				 		QinglingAttr = data_items:get_qiling_attr(CfgItem#cfg_item.cfg_SecondType,CfgItem#cfg_item.cfg_RoleLevel); %%启灵属性
				 	false ->
				 		QinglingAttr = #role_update_attri{}
				 end,
				 XilianAttr = getWashAttr(Item#item.gd_XilianInfo), %%洗练属性
				 InlayAttr = getInlayAttr(Item#item.gd_InlayInfo), %%镶嵌属性
				 ItemAttr = lists:foldl(fun attr_add/2, SumRec, [attr_multiply_quality(LegendAttr,QualityRate), attr_multiply_quality(IntenAttr,QualityRate),XilianAttr,InlayAttr,QinglingAttr]),
				 ?INFO(items,"ItemCfgID= ~w,ItemWorldID = ~w ,Item Attribute is: ~w",[ItemID,ItemWorldID, ItemAttr]),
				 ItemAttr
		end,

	SuitList = getSuitList(ItemList),
	%% 获取套装属性
	SuiltAttrRec = getSuiltAttr(SuitList),				 %% 套装属性
	?INFO(items,"SuitAttr = ~w",[SuiltAttrRec]),
	IntenAllAttr = getIntenAllAttr(RoleLevel, ItemList), %% 全套强化属性
	?INFO(items,"IntenAllAttr = ~w",[IntenAllAttr]),
	AppendAttr = attr_add(SuiltAttrRec,IntenAllAttr),
	HoldAttr = lists:foldl(F1, AppendAttr, ItemList),
	?INFO(items,"HoldAttr = ~w",[HoldAttr]),
	HoldAttr.
	%%TODO 获取装备洗练属性
	

equipItem(RoleID, Item, CfgItem) ->
	{AccountID, _} = Item#item.key,
	BagPos = CfgItem#cfg_item.cfg_SecondType,
	BagType1 = Item#item.gd_BagType,
	BagPos1 = Item#item.gd_BagPos,
	Desc = "",
	DestItem = Item#item{ gd_BagType=?BAG_TYPE_ROLE,gd_RoleID=RoleID,gd_BagPos=BagPos },
	case cache_items:getItemByPos(AccountID, ?BAG_TYPE_ROLE, RoleID, BagPos) of
		[] ->
			?INFO(items,"SrcItem = Null"),
			SrcItem = getNullItem(Item),
			BagNullList = cache_items:getBagNullCells(AccountID, BagType1),
			cache_items:updateBagNullCells(AccountID, BagType1, [BagPos1|BagNullList]);
		Item1 ->
			?INFO(items,"SrcItem = Item1:~w",[[Item1]]),
			SrcItem = Item1#item{ gd_BagType=BagType1, gd_RoleID=0, gd_BagPos=BagPos1 },
			updateItem(SrcItem, 0, Desc)
	end,
	updateItem(DestItem, 0, Desc),
	mod_role:update_attri_notify(AccountID, RoleID),
	%% 成就和任务通知
	mod_achieve:roleItemNotify(AccountID),
	mod_task:update_clothing_task(AccountID, Item#item.cfg_ItemID, 1),
	?INFO(items,"EQUIP ITEM-------BagPos = ~w ,SEND12001:SrcItem = ~w, SEND15010:DestItem = ~w",[BagPos, SrcItem,DestItem]),
	{ok,DestItem,[SrcItem]}.

unequipItem(Item, BagType) ->
	Desc = "",
	SrcItem = getNullItem(Item),
	{AccountID, _WorldID} = Item#item.key,
	RoleID = Item#item.gd_RoleID,
	[BagPos|BagNullList] = cache_items:getBagNullCells(AccountID, BagType),
	DestItem = Item#item{ gd_BagType=BagType,gd_BagPos = BagPos ,gd_RoleID = 0},
	updateItem(DestItem, 0, Desc),
	cache_items:updateBagNullCells(AccountID, BagType, BagNullList),
	mod_role:update_attri_notify(AccountID, RoleID),
	?INFO(items,"UNEQUIP ITEM-------BagPos = ~w ,SEND15010:SrcItem = ~w, SEND12001:DestItem = ~w",[BagPos, SrcItem,DestItem]),
	{ok, SrcItem, [DestItem]}.

intenItem(Item, SilverCost, GoldCost, HoldRate) ->
	GoldUseType = ?GOLD_INTENSIFY_EQUIP_COST,
	SilverUseType = ?SILVER_INTENSIFY_EQUIP_COST,
	{AccountID, WorldID} = Item#item.key,
	case util:rand(1, 100) of
		RandNum when RandNum > HoldRate ->
			SilverCost1 = util:ceil(SilverCost),
			BaseIntenRate = data_items:get_inten_rate(Item#item.gd_IntensifyLevel div 5),
			NewItem = Item#item{ gd_IntenRate = BaseIntenRate, gd_IntenFailRate=Item#item.gd_IntenFailRate+1 },
			UpdateType = 0,
			Desc = "",
			updateItem(NewItem, UpdateType, Desc);
		_ ->
			SilverCost1 = SilverCost,
			NewLevel = Item#item.gd_IntensifyLevel+1,
			BaseIntenRate = data_items:get_inten_rate(NewLevel div 5),
			NewItem = Item#item{ gd_IntenRate = BaseIntenRate,gd_IntensifyLevel=NewLevel, gd_IsBind=?ITEM_BIND_Y, gd_IntenFailRate = 0},
			RoleID = Item#item.gd_RoleID,
			UpdateType = 0,
			Desc = "",
			updateItem(NewItem, UpdateType, Desc),
			mod_achieve:intenNotify(AccountID,WorldID,NewLevel div 5),
			case RoleID > 0 of
				true ->
					mod_role:update_attri_notify(AccountID, RoleID);
				false ->
					skip
			end
	end,
	mod_economy:use_silver(AccountID, SilverCost1, SilverUseType),
	mod_economy:use_bind_gold(AccountID,GoldCost,GoldUseType),
	%% 成就通知
	mod_achieve:roleItemNotify(AccountID),
	%% 任务更新通知
	mod_task:update_inten_equipment_task(AccountID,NewItem#item.cfg_ItemID,1),
	?INFO(task,"updata inten task,AccountID =~w,ItemID =~w,Times =~w",[AccountID,NewItem#item.cfg_ItemID,1]),
	{ok, NewItem}.
	



%% ************************** 华丽的分隔线 ************************** %%

%% ====================================================================
%% Local Functions
%% ====================================================================
%% 删除一个物品
deleteItem(Item, DelType, _Desc) ->
	{AccountID, _} = Item#item.key,
	BagType = Item#item.gd_BagType,
	BagPos = Item#item.gd_BagPos,
	NullCellList = cache_items:getBagNullCells(AccountID, BagType),
	NewNullCellList = lists:sort([BagPos|NullCellList]),
	cache_items:updateBagNullCells(AccountID, BagType, NewNullCellList),
	cache_items:deleteItem(Item),

    %% 玩家事件钩子：背包物品数量改变
    case {Item#item.gd_BagType, DelType} of
        %% 要忽略掉堆叠事件，因为物品实际上没有减少
        %% 要忽略掉使用事件，因为在useItems(...)里已经发过了
        {?BAG_TYPE_BAG, DT} when DT =/= ?ITEM_DEL_STACK, DT =/= ?ITEM_DEL_USE ->
            player_events:post_event(AccountID, 'items.bag_count_alter', 
                {Item#item.cfg_ItemID, -(Item#item.gd_StackNum)});
        _ ->
            void
    end.

deleteSomeItems(AccountID,ItemList)->
	deleteSomeItems(AccountID,ItemList,[]).

%%扣除玩家一定数量的某些物品 
deleteSomeItems(_AccountID,[],NotiItemsList) ->
	NotiItemsList;
deleteSomeItems(AccountID,[{CfgItemID,Num}|RestItemsList],NotiItemsList) ->
	ItemList = cache_items:getItemByItemID(AccountID,1,CfgItemID),
	NotiItemList = deleteOneItemByNum(ItemList,Num,[]),
	deleteSomeItems(AccountID,RestItemsList,NotiItemList ++ NotiItemsList).


deleteOneItemByNum([FirstItem|RestItemList],Num,NotiItemList) ->
	NewNum = FirstItem#item.gd_StackNum - Num,
	case NewNum > 0 of
		true ->
			NewItem = FirstItem#item{gd_StackNum = NewNum},
			updateItem(NewItem,?ITEM_DEL_USE,""),
			[NewItem] ++ NotiItemList;
		false ->
			case NewNum =:= 0 of
				true ->
					deleteItem(FirstItem,?ITEM_DEL_USE,""),
					NewItem = getNullItem(FirstItem),
					[NewItem] ++ NotiItemList;
				false ->
					deleteItem(FirstItem,?ITEM_DEL_USE,""),
					NewItem = getNullItem(FirstItem),
					deleteOneItemByNum(RestItemList,Num - FirstItem#item.gd_StackNum,[NewItem] ++ NotiItemList)
			end
	end.
	

% %% 扣除玩家一类物品中的一定数量
% delete_more_items_by_num(ItemStatus, [], _ItemNum, _DelType, _UpdType) ->
% 	{ok, ItemStatus, []};

% delete_more_items_by_num(ItemStatus, _ItemList, ItemNum, _DelType, _UpdType) when ItemNum =< 0->
% 	{ok, ItemStatus, []};

% delete_more_items_by_num(ItemStatus, [ItemInfo|ItemList], ItemNum, DelType, UpdType) ->
% 	NewItemNum = ItemInfo#ets_gd_world_item.gd_stack_num - ItemNum,
% 	if
% 		NewItemNum > 0 ->
% %% 			NewItemInfo = change_item_info(ItemStatus, ItemInfo, ItemInfo#ets_gd_world_item.gd_bag_rank, ItemInfo#ets_gd_world_item.gd_bag_pos, NewItemNum),
% 			NewItemInfo = update_item_num(ItemStatus, ItemInfo, NewItemNum, UpdType),
% 			{ok, ItemStatus, [NewItemInfo]};
% 		true->
% 			NewItemStatus = delete_item(ItemStatus, ItemInfo, DelType),
% 			NewItemInfo = #ets_gd_world_item{ gd_bag_pos=ItemInfo#ets_gd_world_item.gd_bag_pos },
% 			{ok, RestItemStatus, RestItemList} = delete_more_items_by_num(NewItemStatus, ItemList, ItemNum - ItemInfo#ets_gd_world_item.gd_stack_num, DelType, UpdType),
% 			{ok, RestItemStatus, [NewItemInfo|RestItemList]}
% 	end.

%% 更新一个物品
updateItem(Item, _UpdType, _Desc) ->
	cache_items:updateItem(Item).

%% 生成一个格子的空物品
getNullItem(Item) ->
	BagType = Item#item.gd_BagType,
	BagPos = Item#item.gd_BagPos,
	RoleID = Item#item.gd_RoleID,
	#item{ gd_BagType=BagType, gd_BagPos=BagPos ,gd_RoleID = RoleID}.

%% 创建一个背包物品
createItem(AccountID, ItemID, ItemNum, IsBind, FromType, Desc) ->
	BagType = 1,
	RoleID = 0,
	createItem(AccountID, BagType, RoleID, ItemID, ItemNum, IsBind, FromType, Desc).

%% 创建一个指定位置的物品
createItem(AccountID, BagType, RoleID, ItemID, ItemNum, IsBind, _FromType, _Desc) ->
	?INFO(items, "ItemID=~w, ItemNum=~w, BindInfo=~w", [ItemID, ItemNum, IsBind]),

	%% 取物品基本信息
    CfgItem = data_items:get(ItemID),
	
	%% 生成新物品状态
	case BagType of
		1 ->
			%% 取背包存放格子，第一个非空格子
			[BagPos|NullNumList] = cache_items:getBagNullCells(AccountID, 1),
			%% 生成新物品状态
			cache_items:updateBagNullCells(AccountID, 1, NullNumList);
		2 ->
			%% 取仓库存放格子，第一个非空格子
			[BagPos|NullNumList] = cache_items:getBagNullCells(AccountID, 2),
			%% 生成新物品状态
			cache_items:updateBagNullCells(AccountID, 2, NullNumList);
		3 ->
			BagPos = CfgItem#cfg_item.cfg_SecondType
	end,
	
	WorldID = uid_server:get_seq_num(?UID_ITEMS), 
	
	%% 生成世界物品信息,
	Item = #item{
				 key = {AccountID, WorldID},
				 cfg_ItemID = CfgItem#cfg_item.cfg_ItemID,
				 gd_IsBind = IsBind,
				 gd_StackNum = ItemNum,
				 gd_BagType = BagType,
				 gd_RoleID = RoleID,
				 gd_BagPos = BagPos,
				 gd_CreateTime = util:unixtime(),
				 gd_EndTime = 0
				},
	cache_items:newItem(Item),
	Item.

%% 将一定数量的物品堆叠到已有的该类型物品的列表中
stackItems(_AccountID, _BagType, ItemNum, _CfgItem, _ItemList, _Desc) when ItemNum =< 0 ->
	{0, []};
stackItems(_AccountID, _BagType, ItemNum, _CfgItem, [], _Desc) ->
	{ItemNum, []};
stackItems(AccountID, BagType, ItemNum, CfgItem, [Item|ItemList], Desc) ->
	StackMax = CfgItem#cfg_item.cfg_StackMax,
	case Item#item.gd_StackNum + ItemNum - StackMax of
		%% 当前堆叠数量加总数量大于等于最大堆叠数
		NewItemNum when NewItemNum >= 0 ->
			%% 当前物品叠堆数等于最大叠堆数
			case Item#item.gd_StackNum =:= CfgItem#cfg_item.cfg_StackMax of
				true ->
					NewItemList = [];
				false ->
					case CfgItem#cfg_item.cfg_FullID =:= 0 of
						true -> %% 非碎片
							NewItem = Item#item{ gd_StackNum = StackMax },
							cache_items:updateItem(NewItem),
							NewItemList = [NewItem];
						false -> %% 碎片
							deleteItem(Item, ?ITEM_DEL_FRAGMANT_COMPOS, Desc),
							RoleID = 0,
							FullItemID = CfgItem#cfg_item.cfg_FullID,
							ItemNum = 1,
							IsBind = Item#item.gd_IsBind,
							NewItem = createItem(AccountID, BagType, RoleID, FullItemID, ItemNum, IsBind, ?ITEM_FROM_FRAGMANT_COMPOS, Desc),
							if
								NewItem#item.gd_BagPos =:= Item#item.gd_BagPos ->
									NewItemList = [NewItem];
								true ->
									NewItemList = [NewItem, #item{ gd_BagType=BagType, gd_BagPos=Item#item.gd_BagPos }]
							end
					end
			end;
			%% 当前堆叠数量加总数量小于最大堆叠数
		NewItemNum ->
			NewItem = Item#item{ gd_StackNum=StackMax + NewItemNum },
			cache_items:updateItem(NewItem),
			NewItemList = [NewItem]
	end,
	{RestItemNum, RestItemList} = stackItems(AccountID, BagType, NewItemNum, CfgItem, ItemList, Desc),
	{RestItemNum, lists:append(NewItemList, RestItemList)}.

%% 对包包的物品进行整理前排序
sortCleanItems(ItemList) ->
	F = fun(Item1, Item2) ->
				CfgItem1 = data_items:get(Item1#item.cfg_ItemID),
				CfgItem2 = data_items:get(Item2#item.cfg_ItemID),
				%% 按第一类型排序(装备>宝石>道具)
				case CfgItem1#cfg_item.cfg_FirstType =:= CfgItem2#cfg_item.cfg_FirstType of
					false ->
						(CfgItem1#cfg_item.cfg_FirstType =< CfgItem2#cfg_item.cfg_FirstType);
					true ->
						%% 按品质排序(从高到低)
						case CfgItem1#cfg_item.cfg_GradeLevel =:= CfgItem2#cfg_item.cfg_GradeLevel of
							false ->
								(CfgItem1#cfg_item.cfg_GradeLevel >= CfgItem2#cfg_item.cfg_GradeLevel);
							true ->
								%% 按物品等级排序(从高到低)
								case CfgItem1#cfg_item.cfg_RoleLevel =:= CfgItem2#cfg_item.cfg_RoleLevel of
									false ->
										(CfgItem1#cfg_item.cfg_RoleLevel >= CfgItem2#cfg_item.cfg_RoleLevel);
									true ->
										%% 按第二类型排序(从小到大)
										case CfgItem1#cfg_item.cfg_SecondType =:= CfgItem2#cfg_item.cfg_SecondType of
											false ->
												(CfgItem1#cfg_item.cfg_SecondType =< CfgItem2#cfg_item.cfg_SecondType);
											true ->
												%% 按物品原型ID排序(从小到大)
												case CfgItem1#cfg_item.cfg_ItemID =:= CfgItem2#cfg_item.cfg_ItemID of
													false ->
														(CfgItem1#cfg_item.cfg_ItemID =< CfgItem2#cfg_item.cfg_ItemID);
													true ->
														%% 按绑定信息排序(从绑定到非绑定)
														case Item1#item.gd_IsBind =:= Item2#item.gd_IsBind of
															false ->
																(Item1#item.gd_IsBind >= Item2#item.gd_IsBind);
															true ->
																%% 按强化等级排序(从高到低)
																case Item1#item.gd_IntensifyLevel =:= Item2#item.gd_IntensifyLevel of
																	false ->
																		(Item1#item.gd_IntensifyLevel >= Item2#item.gd_IntensifyLevel);
																	true ->
																		%% 按堆叠数量排序(从多到少)
																		(Item1#item.gd_StackNum >= Item2#item.gd_StackNum)
																end
														end
												end
										end
								end
						end
				end
		end,
	lists:sort(F, ItemList).

%% 对一个格子的物品进行整理处理
cleanItem(Item, {Num, OldItem}) ->
	Desc = "",
	case OldItem of
		[] ->
			NewItem = Item#item{ gd_BagPos=Num },
			updateItem(NewItem, 0, Desc),
			{Num+1, Item};
		_ ->
			case (OldItem#item.cfg_ItemID =:= Item#item.cfg_ItemID)
				andalso (OldItem#item.gd_IsBind=:= Item#item.gd_IsBind) of
				false ->
					NewItem = Item#item{ gd_BagPos=Num },
					updateItem(NewItem, 0, Desc),
					{Num+1, NewItem};
				true ->
					CfgItem = data_items:get(Item#item.cfg_ItemID),
					StackMax = CfgItem#cfg_item.cfg_StackMax,
					case OldItem#item.gd_StackNum =:= StackMax of
						true ->
							NewItem = Item#item{ gd_BagPos=Num },
							updateItem(NewItem, 0, Desc),
							{Num+1, NewItem};
						false ->
							ItemNum = Item#item.gd_StackNum,
							OldItemNum = OldItem#item.gd_StackNum,
							case OldItemNum + ItemNum - StackMax of
								RestNum when RestNum >= 0 ->
									case CfgItem#cfg_item.cfg_FullID > 0 of
										true ->
											deleteItem(OldItem, ?ITEM_DEL_FRAGMANT_COMPOS, Desc),
											{AccountID, _} = OldItem#item.key,
											ItemID = CfgItem#cfg_item.cfg_FullID,
											IsBind = OldItem#item.gd_IsBind,
											FromType = ?ITEM_FROM_FRAGMANT_COMPOS,
											ItemNum1 = 1,
											BagPos = OldItem#item.gd_BagPos,
											TmpItem = createItem(AccountID, ItemID, ItemNum1, IsBind, FromType, Desc),
											OldItem1 = TmpItem#item{ gd_BagPos=BagPos },
											updateItem(OldItem1, 0, Desc),
											DelType = ?ITEM_DEL_FRAGMANT_COMPOS,
											DecType = ?ITEM_DEC_FRAGMANT_COMPOS;
										false ->
											OldItem1 = OldItem#item{ gd_StackNum=StackMax },
											updateItem(OldItem1, ?ITEM_ADD_STACK, Desc),
											DelType = ?ITEM_DEL_STACK,
											DecType = ?ITEM_DEC_STACK
									end,
									case RestNum =:= 0 of
										true ->
											deleteItem(Item, DelType, Desc),
											{Num, OldItem1};
										false ->
											NewItem = Item#item{ gd_StackNum=RestNum,gd_BagPos=Num },
											updateItem(NewItem, DecType, Desc),
											{Num+1, NewItem}
									end;
								_ ->
									NewItem = OldItem#item{ gd_StackNum=OldItemNum+ItemNum },
									updateItem(NewItem, ?ITEM_ADD_STACK, Desc),
									deleteItem(Item, ?ITEM_DEL_STACK, Desc),
									{Num, NewItem}
							end
									
					end
			end
	end.

getUseEffect(_AccountID, _RoleID, _ItemList, ItemNum) when ItemNum =< 0 ->
	{ok, []};
getUseEffect(_AccountID, _RoleID, [], _ItemNum) ->
	{ok, []};
getUseEffect(AccountID, RoleID, [{Type, Num, IsBind}|UseEffect], ItemNum) ->
	case Type of
		gold ->
			LogType = ?GOLD_FROM_USE_ITEM,
			case IsBind of
				?ITEM_BIND_N ->
					mod_economy:add_gold(AccountID, Num * ItemNum, LogType);
				?ITEM_BIND_Y ->
					mod_economy:add_bind_gold(AccountID, Num * ItemNum, LogType)
			end,
			NewItemList = [];
		silver ->
			mod_economy:add_silver(AccountID, Num * ItemNum, ?SILVER_FROM_USE_ITEM),
			NewItemList = [];
		practice ->
			mod_economy:add_practice(AccountID, Num * ItemNum, ?PRACTICE_FROM_USE_ITEM),
			NewItemList = [];
		popularity ->
			mod_economy:add_popularity(AccountID, Num * ItemNum, ?POPULARITY_FROM_USE_ITEM),
			NewItemList = [];
		wakan ->
			mod_economy:add_wakan(AccountID, Num * ItemNum, ?WAKAN_FORM_USE_ITEM),
			NewItemList = [];
		exp ->
			mod_role:add_exp(AccountID, {RoleID, Num * ItemNum}, ?EXP_FROM_USE_ITEM),
			NewItemList = [];
		wlsd ->
			NewItemList = [],
			useWlsd(AccountID,Num);
		skill ->
			NewItemList = [],
			?INFO(item,"use skill book"),
			role_skill:add_skill_exp_to_n(AccountID, RoleID, Num, IsBind);
		_ ->
			ItemList = [{Type, Num * ItemNum, IsBind}],
			ItemList1 = base_items:fillItems(ItemList),
			{ok, NewItemList} = createItems(AccountID, ItemList1, ?ITEM_FROM_USE_ITEM)
	end,
	{ok, RestItemList} = getUseEffect(AccountID, RoleID, UseEffect, ItemNum),
	{ok, NewItemList ++ RestItemList}.

makeReturnList(Item, ItemList) ->
	BagType = Item#item.gd_BagType,
	BagPos = Item#item.gd_BagPos,
	F = fun(I) ->
				I#item.gd_BagType =:= BagType
		end,
	ItemList1 = lists:filter(F, ItemList),
	case lists:keyfind(BagPos, #item.gd_BagPos, ItemList1) of
		false ->
			[Item|ItemList];
		_ ->
			ItemList
	end.


%%传入[{1,20},{1,20},{4,30},{1,20},{2,20},{2,20}]的人物套装信息，生成[{{1,20},3}。。。]这样一个可处理的元组列表
getSuiltAttr(FullIDList) ->
	Empty_suilt_list = [],
	SuiltInfoArry = getSuiltInfo(FullIDList,Empty_suilt_list),
	case SuiltInfoArry of
		[] ->
			#role_update_attri{};
		[SuiltInfo1|SuiltInfo2] ->
			case SuiltInfo2 of
				[] ->
					{Level1,Num1} = SuiltInfo1,
					data_items:get_suit_attr(Level1,Num1);
				{Level2,Num2} ->
					{Level1,Num1} = SuiltInfo1,
					Attr1 = data_items:get_suit_attr(Level1,Num1),
					Attr2 = data_items:get_suit_attr(Level2,Num2),
					attr_add(Attr1,Attr2)
			end
	end.
 
%%从装备列表中统计出套装信息[{{Type，Level},Num},{{Type，Level},Num}...]
getSuiltInfo([],SumList) ->
	SumList;
getSuiltInfo(ItemLevelList,SumList) ->
	[FirstItem| _] = ItemLevelList,
	FiltedList = lists:filter(fun(A) -> A /= FirstItem end,ItemLevelList),
	TypeNum = length(ItemLevelList) - length(FiltedList),
	case TypeNum >=3 of
		true ->
			getSuiltInfo(FiltedList,[{FirstItem,TypeNum}|SumList]);
		false ->
			getSuiltInfo(FiltedList,SumList)
	end.

%%获取全套强化属性：data_items:get_inten_all_attr(人物等级,全套强化等级) -> #role_update_attri
getIntenAllAttr(RoleLevel,ItemList) -> 
	F2 = fun(Item,IntenLevelList) ->
		CfgItem = data_items:get(Item#item.cfg_ItemID),
		?INFO(lib_items,"getIntenAllAttr cfgItem is ~w",[CfgItem]),
		case CfgItem#cfg_item.cfg_SecondType =< 6 of
			true ->
				Level = Item#item.gd_IntensifyLevel div 5,
				IntenLevelList++[Level];
			false ->
				IntenLevelList
		end
		end,
	IntenLevelList = lists:foldl(F2,[],ItemList),
	?INFO(items,"IntenLevelList = ~w",[IntenLevelList]),
	case IntenLevelList of
		[] ->
			MinLevel = 0;
		_Else ->
			MinLevel = lists:min(IntenLevelList)
	end,
	RoleLevel1 = RoleLevel div 10 * 10,
	case MinLevel >= 8 andalso length(IntenLevelList) =:= 6 of
		true ->
			case MinLevel of
				9 ->
					MinLevel1 =8;
				11 ->
					MinLevel1 =10;
				_Else1 ->
					MinLevel1 = MinLevel
			end,
			data_items:get_inten_all_attr(RoleLevel1,MinLevel1);
		false ->
			#role_update_attri{}
	end.

getIntenAllRate(AccountID,RoleID) ->
	ItemList = cache_items:getItemsByRole(AccountID, RoleID),
	F2 = fun(Item,IntenLevelList) ->
		CfgItem = data_items:get(Item#item.cfg_ItemID),
		case CfgItem#cfg_item.cfg_SecondType =< 6 of
			true ->
				Level = Item#item.gd_IntensifyLevel div 5,
				IntenLevelList++[Level];
			false ->
				IntenLevelList
		end
		end,
	IntenLevelList = lists:foldl(F2,[],ItemList),
	?INFO(items,"IntenLevelList = ~w",[IntenLevelList]),
	case IntenLevelList of
		[] ->
			MinLevel = 0;
		_Else ->
			MinLevel = lists:min(IntenLevelList)
	end,
	case MinLevel >= 8 andalso length(IntenLevelList) =:= 6 of
		true ->
			case MinLevel of
				9 ->
					MinLevel1 =8;
				11 ->
					MinLevel1 =10;
				_Else1 ->
					MinLevel1 = MinLevel
			end,
			data_items:get_inten_all_rate(MinLevel1);
		false ->
			{0,0,0,0}
	end.

	% [T1,T2,T3,T4,T5,T6,T7,T8,T9,T10] = SumList,
	% case SuiltType of
	% 	1 ->
	% 		getSuiltInfo(RestList,[T1+1,T2,T3,T4,T5,T6,T7,T8,T9,T10]);
	% 	2 ->
	% 		getSuiltInfo(RestList,[T1,T2+1,T3,T4,T5,T6,T7,T8,T9,T10]);
	% 	3 ->
	% 		getSuiltInfo(RestList,[T1,T2,T3+1,T4,T5,T6,T7,T8,T9,T10]);
	% 	4 ->
	% 		getSuiltInfo(RestList,[T1,T2,T3,T4+1,T5,T6,T7,T8,T9,T10]);
	% 	5 ->
	% 		getSuiltInfo(RestList,[T1,T2,T3,T4,T5+1,T6,T7,T8,T9,T10]);
	% 	6 ->
	% 		getSuiltInfo(RestList,[T1,T2,T3,T4,T5,T6+1,T7,T8,T9,T10]);
	% 	7 ->
	% 		getSuiltInfo(RestList,[T1,T2,T3,T4,T5,T6,T7+1,T8,T9,T10]);
	% 	8 ->
	% 		getSuiltInfo(RestList,[T1,T2,T3,T4,T5,T6,T7,T8+1,T9,T10]);
	% 	9 ->
	% 		getSuiltInfo(RestList,[T1,T2,T3,T4,T5,T6,T7,T8,T9+1,T10]);
	% 	10 ->
	% 		getSuiltInfo(RestList,[T1,T2,T3,T4,T5,T6,T7,T8,T9,T10+1])
	% end.


%%从装备套装Info统计信息中生成最终有用的元组列表[{Type,Num}.....]
% getSuiltInfoArry([],B,SumList) ->
% 	SumList;
% getSuiltInfoArry(SuiltTypeNum|RestList,B,SumList) ->
% 	B1 = B+1,
% 	case SuiltTypeNum >= 3 of
% 		true -> getSuiltInfoArry(RestList,B1,[{B1,SuiltTypeNum}|SumList]);
% 		false -> getSuiltInfoArry(RestList,B1,SumList)
% 	end.

getWashAttr([]) ->
	#role_update_attri{};
getWashAttr([{_ID,I, N}|RestList]) ->
	case I of
		1 ->
			NewAttr = #role_update_attri{ p_att = N };
		2 ->
			NewAttr = #role_update_attri{ m_att = N };
		3 ->
			NewAttr = #role_update_attri{ p_def = N };
		4 ->
			NewAttr = #role_update_attri{ m_def = N };
		5 ->
			NewAttr = #role_update_attri{ gd_maxHp = N };
		6 ->
			NewAttr = #role_update_attri{ gd_speed = N };
		7 ->
			NewAttr = #role_update_attri{ gd_baoji = N };
		8 ->
			NewAttr = #role_update_attri{ gd_mingzhong = N };
		9 ->
			NewAttr = #role_update_attri{ gd_xingyun = N };
		10 ->
			NewAttr = #role_update_attri{ gd_shanbi = N };
		11 ->
			NewAttr = #role_update_attri{ gd_gedang = N };
		12 ->
			NewAttr = #role_update_attri{ gd_fanji = N };
		13 ->
			NewAttr = #role_update_attri{ gd_pojia = N };
		14 ->
			NewAttr = #role_update_attri{ gd_zhiming = N };
		_I ->
			NewAttr = #role_update_attri{}
	end,
	RestAttr = getWashAttr(RestList),
	attr_add(RestAttr, NewAttr).

getInlayAttr([]) ->
	#role_update_attri{};
getInlayAttr([{_I, CfgItemID}|RestList]) ->
	CfgItem = data_items:get(CfgItemID),
	NewAttr = CfgItem#cfg_item.cfg_AttrInfo,
	RestAttr = getInlayAttr(RestList),
	attr_add(RestAttr, NewAttr).

attr_add(AttrRec1, AttrRec2) when erlang:is_record(AttrRec1, role_update_attri) andalso erlang:is_record(AttrRec2, role_update_attri) ->
	LiLiang   = AttrRec1#role_update_attri.gd_liliang + AttrRec2#role_update_attri.gd_liliang,
	YuanSheng = AttrRec1#role_update_attri.gd_yuansheng + AttrRec2#role_update_attri.gd_yuansheng,
	TiPo      = AttrRec1#role_update_attri.gd_tipo + AttrRec2#role_update_attri.gd_tipo,
	MinJie    = AttrRec1#role_update_attri.gd_minjie + AttrRec2#role_update_attri.gd_minjie,
	Speed     = AttrRec1#role_update_attri.gd_speed + AttrRec2#role_update_attri.gd_speed,
	BaoJi     = AttrRec1#role_update_attri.gd_baoji + AttrRec2#role_update_attri.gd_baoji,
	ShanBi    = AttrRec1#role_update_attri.gd_shanbi + AttrRec2#role_update_attri.gd_shanbi,
	GeDang    = AttrRec1#role_update_attri.gd_gedang + AttrRec2#role_update_attri.gd_gedang,
	MingZhong = AttrRec1#role_update_attri.gd_mingzhong + AttrRec2#role_update_attri.gd_mingzhong,
	ZhiMing   = AttrRec1#role_update_attri.gd_zhiming + AttrRec2#role_update_attri.gd_zhiming,
	XingYun   = AttrRec1#role_update_attri.gd_xingyun + AttrRec2#role_update_attri.gd_xingyun,
	FanJi     = AttrRec1#role_update_attri.gd_fanji + AttrRec2#role_update_attri.gd_fanji,
	PoJia     = AttrRec1#role_update_attri.gd_pojia + AttrRec2#role_update_attri.gd_pojia,
	CurrentHp = AttrRec1#role_update_attri.gd_currentHp + AttrRec2#role_update_attri.gd_currentHp,
	MaxHp     = AttrRec1#role_update_attri.gd_maxHp + AttrRec2#role_update_attri.gd_maxHp,
	PDef      = AttrRec1#role_update_attri.p_def + AttrRec2#role_update_attri.p_def,
	MDef      = AttrRec1#role_update_attri.m_def + AttrRec2#role_update_attri.m_def,
	PAtt      = AttrRec1#role_update_attri.p_att + AttrRec2#role_update_attri.p_att,
	MAtt      = AttrRec1#role_update_attri.m_att + AttrRec2#role_update_attri.m_att,
	#role_update_attri{
			gd_liliang    = LiLiang,			%% 腕力
			gd_yuansheng  = YuanSheng,			%% 元神
			gd_tipo       = TiPo,			%% 体魄
			gd_minjie     = MinJie,			%% 敏捷	
			
			gd_speed      = Speed,			%% 攻击速度
			gd_baoji      = BaoJi,			%% 暴击
			gd_shanbi     = ShanBi,			%% 闪避
			gd_gedang     = GeDang,			%% 格挡
			gd_mingzhong  = MingZhong,			%% 命中率
			gd_zhiming    = ZhiMing,			%% 致命
			gd_xingyun    = XingYun,			%% 幸运
			gd_fanji      = FanJi,			%% 反击
			gd_pojia      = PoJia,			%% 破甲
			
			gd_currentHp  = CurrentHp,			%% 当前血量
			gd_maxHp      = MaxHp,			%% 最大血量
			p_def         = PDef,			%% 物理防御
			m_def         = MDef,			%% 魔法防御
			p_att         = PAtt,			%% 攻击力
			m_att         = MAtt			%% 魔攻
	}.

%% 使用藏宝图
useWlsd(AccountID, ItemID) ->
	RandNum = util:rand(1,100),
	EventInfo = data_items:get_wlsd_event(ItemID, RandNum),
	?INFO(items, "ItemID=~w, RandNum=~w, EventInfo=~w", [ItemID, RandNum, EventInfo]),
	case EventInfo of
		{0, _, _} ->
			Message = {wlsd,0,0,0,0,0,0};
		{1, MonsterID, _} ->
			%% TODO 打怪物
			Start = #battle_start {
                                mod      = pve,
                                type     = 0,       %% TODO: 写个真的值上去
                                att_id   = AccountID,
                                att_mer  = [],
                                monster  = MonsterID,
                                maketeam = false,
                                caller   = self(),
                                callback = {}
                            },
			?INFO(battle, "battle starting... Start = ~w", [Start]),
			battle:start(Start),
			Message = {wlsd,1,0,MonsterID,0,0,0};
		{2, ItemID1, IsBind} ->
			{ok,NotifyItemList} = createItems(AccountID, [{ItemID1, 1, IsBind}], ?ITEM_FROM_WLSD),
			Message = {wlsd, NotifyItemList, ItemID1};
		{3, Num, 1} ->
			mod_economy:add_bind_gold(AccountID, Num, ?GOLD_FROM_WLSD),
			Message = {wlsd,3, 0, 0, 0, Num, 0};
		{3, Num, 0} ->
			mod_economy:add_gold(AccountID, Num, ?GOLD_FROM_WLSD),
			Message = {wlsd, 3, 0, Num, 0, 0, 0};
		{4, Num, _Bind} ->
			mod_economy:add_silver(AccountID, Num, ?SILVER_FROM_WLSD),
			Message = {wlsd, 4, 0, Num, 0, 0, 0};
		_ ->
			Message = {wlsd,0,0,0,0,0,0}
	end,
	gen_server:cast(self(), {message, AccountID, Message}).


attr_multiply_quality(AttrRec1,Rate) ->
	LiLiang   = trunc(AttrRec1#role_update_attri.gd_liliang * Rate),
	YuanSheng = trunc(AttrRec1#role_update_attri.gd_yuansheng * Rate),
	TiPo      = trunc(AttrRec1#role_update_attri.gd_tipo * Rate),
	MinJie    = trunc(AttrRec1#role_update_attri.gd_minjie * Rate),
	Speed     = trunc(AttrRec1#role_update_attri.gd_speed * Rate),
	BaoJi     = trunc(AttrRec1#role_update_attri.gd_baoji * Rate),
	ShanBi    = trunc(AttrRec1#role_update_attri.gd_shanbi * Rate),
	GeDang    = trunc(AttrRec1#role_update_attri.gd_gedang * Rate),
	MingZhong = trunc(AttrRec1#role_update_attri.gd_mingzhong * Rate),
	ZhiMing   = trunc(AttrRec1#role_update_attri.gd_zhiming * Rate),
	XingYun   = trunc(AttrRec1#role_update_attri.gd_xingyun * Rate),
	FanJi     = trunc(AttrRec1#role_update_attri.gd_fanji * Rate),
	PoJia     = trunc(AttrRec1#role_update_attri.gd_pojia * Rate),
	CurrentHp = trunc(AttrRec1#role_update_attri.gd_currentHp * Rate),
	MaxHp     = trunc(AttrRec1#role_update_attri.gd_maxHp * Rate),
	PDef      = trunc(AttrRec1#role_update_attri.p_def * Rate),
	MDef      = trunc(AttrRec1#role_update_attri.m_def * Rate),
	PAtt      = trunc(AttrRec1#role_update_attri.p_att * Rate),
	MAtt      = trunc(AttrRec1#role_update_attri.m_att * Rate),
	#role_update_attri{
			gd_liliang    = LiLiang,			%% 腕力
			gd_yuansheng  = YuanSheng,			%% 元神
			gd_tipo       = TiPo,			%% 体魄
			gd_minjie     = MinJie,			%% 敏捷	
			
			gd_speed      = Speed,			%% 攻击速度
			gd_baoji      = BaoJi,			%% 暴击
			gd_shanbi     = ShanBi,			%% 闪避
			gd_gedang     = GeDang,			%% 格挡
			gd_mingzhong  = MingZhong,			%% 命中率
			gd_zhiming    = ZhiMing,			%% 致命
			gd_xingyun    = XingYun,			%% 幸运
			gd_fanji      = FanJi,			%% 反击
			gd_pojia      = PoJia,			%% 破甲
			
			gd_currentHp  = CurrentHp,			%% 当前血量
			gd_maxHp      = MaxHp,			%% 最大血量
			p_def         = PDef,			%% 物理防御
			m_def         = MDef,			%% 魔法防御
			p_att         = PAtt,			%% 攻击力
			m_att         = MAtt			%% 魔攻
			}.

getSuitList([])->
	[]; 
getSuitList([FirstItem|ResItemList])->
	CfgItemID = FirstItem#item.cfg_ItemID,
	CfgItem = data_items:get(CfgItemID),
	RestList = getSuitList(ResItemList),
	case FirstItem#item.gd_IsQiling =:= 1 of
		true ->
			RestList ++ [CfgItem#cfg_item.cfg_RoleLevel];
		false ->
			RestList
	end.

update_compose_stone_list(Id, Cfg_item_id, Num,NewItemList1)->
	Cfg_item = data_items:get(Cfg_item_id),
	Stone_level = Cfg_item#cfg_item.cfg_RoleLevel,
	Stone_compose_num = data_items:get_compose_num_by_level(Stone_level), 
	Silver_compose = data_items:get_compose_silver_by_level(Cfg_item_id,Stone_level),

	mod_economy:use_silver(Id, Silver_compose * Num, ?SILVER_COMPOSE_ITEM_COST),
	NotiItemList = deleteSomeItems(Id,[{Cfg_item_id,Stone_compose_num * Num}],[]),
			
	{ok, NewItemList} = createItems(Id, NewItemList1, ?ITEM_FROM_COMPOSE),
	?INFO(items, "NewItemList=~w", [NewItemList]),
	Ret = {NewItemList,NotiItemList},
	Ret.

update_convert_stone_list(Id, From_cfg_item_id, Target_cfg_item_id, Num,NewItemList1)->
	Cfg_item = data_items:get(From_cfg_item_id),
	Stone_level = Cfg_item#cfg_item.cfg_RoleLevel,
 			
	%%check whether the from and target are the same stone 
	To_cfg_item = data_items:get(Target_cfg_item_id),
	Stone_level = To_cfg_item#cfg_item.cfg_RoleLevel,

	Silver_convert = data_items:get_convert_silver_by_level(From_cfg_item_id,Stone_level),

	mod_economy:use_silver(Id, Silver_convert * Num, ?SILVER_CONVERT_ITEM_COST),
	NotiItemList = deleteSomeItems(Id,[{From_cfg_item_id, Num}],[]),
			
	{ok, NewItemList} = createItems(Id, NewItemList1, ?ITEM_FROM_CONVERT),
	?INFO(items, "NewItemList=~w", [NewItemList]),
	Ret = {NewItemList,NotiItemList},
	Ret.

update_carve_stone_list(Id, Cfg_item_id, Num,NewItemList1)->
	Cfg_item = data_items:get(Cfg_item_id),
	Stone_level = Cfg_item#cfg_item.cfg_RoleLevel,
 	Material_id  = data_items:get_carve_material(Cfg_item_id),

	Silver_carve = data_items:get_carve_silver_by_level(Cfg_item_id, Stone_level),
	mod_economy:use_silver(Id, Silver_carve * Num, ?SILVER_CARVE_ITEM_COST),
	NotiItemList1 = deleteSomeItems(Id,[{Cfg_item_id, Num}],[]),
	NotiItemList2 = deleteSomeItems(Id,[{Material_id, Num}],[]),
			
	{ok, NewItemList} = createItems(Id, NewItemList1, ?ITEM_FROM_CARVE),
	?INFO(items, "NewItemList=~w", [NewItemList]),
	Ret = {NewItemList,NotiItemList1,NotiItemList2},
	Ret.


