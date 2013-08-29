%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%% 
%%% Created : 2012-6-8
%%% -------------------------------------------------------------------
-module(mod_items).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files 12008
%% --------------------------------------------------------------------
-include("common.hrl").
%% -include("player_record.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([start_link/1]).

%% ====================================================================
%% External functions
%% ====================================================================
%% 查询类接口
-export([
		 getItemStatus/1,
		 getAllItems/1,
%% 		 getItemsByType/2,
		 getBagItems/1,
		 getBankItems/1,
		 getAllRoleItems/1,
		 getRoleItems/2,
		 getItem/4,
		 getNumByItemID/2,
		 getBagNullNum/1,
		 getBankNullNum/1,
		 has_items/3,
		 getIntenAllRate/2,  	%% 全套强化比率加成，用来给佣兵加战斗力
		 getAllRoleItemsAttrList/1
		 ]).

%% 背包操作类接口
-export([
		 initItems/1,
		 createItems/3,
		 createItemsOnRole/4,
		 useNumByWorldID/5,
		 useNumByItemID/3,		%% 删除/使用
		 throwByWorldID/3,      %% 删除/丢弃物品
		 throwByWorldIDList/3,  %% 按照世界ID列表来删除某些物品
		 deleteSomeItemsByItemID/2, %% 扣除玩家一定数量的某些物品(如升级材料等)
		 buyItem/4,
		 sellItems/3,
		 cleanItems/2,
		 moveItem/4,
		 expandVolume/3,
		 splitItem/3
		 ]).

%% 装备操作类接口
-export([
		 getRoleAttr/3,
		 equipItem/4,
		 unequipItem/3,
		 intenItem/4,
		 qilingItem/3,
		 xilianItem/4,
		 getXilianStar/2,
		 getIntenRate/2,
		 lockXilianStar/3,
		 addIntenRate/3,
		 upgrateItem/4,
		 upItemQuality/3,
		 inlayJewel/5,
		 backoutJewel/4]).

%% 采集接口
-export([
		 collect/2
		]).

%% 宝石系统
-export([compose_stone/4,
		 convert_stone/5,
		 carve_stone/4
	]).

-export([bag_item_list/1]).

bag_item_list(Id)->
	PS = mod_player:get_player_status(Id),
	{ok, BinData} = pt_12:write_init_pack(12000, 0, []),
	lib_send:send_direct(PS#player_status.send_pid, BinData).

initItems(AccountID) ->
	cache_items:createBag(AccountID, ?BAG_TYPE_BAG),
	cache_items:createBag(AccountID, ?BAG_TYPE_BANK),
	ok.

%% 获取玩家物品进程状态
-spec getItemStatus(integer()) -> list().
getItemStatus(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.items_pid, {getItemStatus, AccountID}).

%% 获取玩家所有物品
-spec getAllItems(integer()) -> list().
getAllItems(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.items_pid, {getAllItems, AccountID}).

%% -spec getItemsByType(integer(), atom()) -> list().
%% getItemsByType(AccountID, BagType) ->
%% 	PS = mod_player:get_player_status(AccountID, BagType),
%% 	gen_server:call(PS#player_status.items_pid, {getItemsByType, BagType}).

%% 获取玩家背包物品
-spec getBagItems(integer()) -> list().
getBagItems(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.items_pid, {getBagItems, AccountID}).

%% 获取玩家仓库物品
-spec getBankItems(integer()) -> list().
getBankItems(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.items_pid, {getBankItems, AccountID}).

%% 获取玩家所有佣兵装备物品
-spec getAllRoleItems(integer()) -> list().
getAllRoleItems(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.items_pid, {getAllRoleItems, AccountID}).

%% 获取玩家指定佣兵的装备物品
-spec getRoleItems(integer(), integer()) -> list().
getRoleItems(AccountID, RoleID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.items_pid, {getRoleItems, AccountID, RoleID}).

%% 获取玩家指定物品的详细信息
-spec getItem(integer(), integer(), integer(), integer()) -> list().
getItem(AccountID, ItemAccountID, WorldID, FromType) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.items_pid, {getItem, AccountID, ItemAccountID, WorldID, FromType}).

%% 获取玩家指定物品的数量
-spec getNumByItemID(integer(), integer()) -> integer().
getNumByItemID(AccountID, ItemID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.items_pid, {getNumByItemID, AccountID, ItemID}).

%% 检测是否有指定数量的物品
%% 有的话返回true，否则返回false
-spec has_items(integer(), integer(), integer()) -> boolean().
has_items(AccountID, ItemID, Num) ->
	(getNumByItemID(AccountID, ItemID) >= Num).

getIntenAllRate(AccountID,RoleID) ->
	lib_items:getIntenAllRate(AccountID,RoleID).

getAllRoleItemsAttrList(AccountID) ->
	lib_items:getItemsAttr(AccountID).

%% 获取玩家背包空格子数量
-spec getBagNullNum(integer()) -> integer().
getBagNullNum(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.items_pid, {getBagNullNum, AccountID}).

%% 获取玩家仓库空格子数量
-spec getBankNullNum(integer()) -> integer().
getBankNullNum(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.items_pid, {getBankNullNum, AccountID}).

%% 根据物品列表生成物品,列表格式[{ItemID1, Num1, BindInfo1}, {ItemID2, Num2, BindInfo2},...]
-spec createItems(integer(), list(), integer()) -> any().
createItems(AccountID, ItemList, FromType) ->
	case length(ItemList) =:= 0 of
		true ->
			void;
		false ->
			PS = mod_player:get_player_status(AccountID),
			gen_server:cast(PS#player_status.items_pid, {createItems, AccountID, ItemList, FromType})
	end.

-spec createItemsOnRole(integer(),integer(),list(),integer()) -> any().
	createItemsOnRole(AccountID,RoleID,ItemList,FromType) ->
		case length(ItemList) =:= 0 of
			true ->
				void;
			false ->
				PS = mod_player:get_player_status(AccountID),
				gen_server:cast(PS#player_status.items_pid, {createItemsOnRole,AccountID,RoleID,ItemList,FromType})
	end.

%% 使用玩家指定物品一定数量
-spec useNumByWorldID(integer(), integer(), integer(), integer(), integer()) -> any().
useNumByWorldID(AccountID, BagType, RoleID, WorldID, ItemNum) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {useNumByWorldID, AccountID, BagType, RoleID, WorldID, ItemNum}).

%% 使用玩家一类物品一定数量 mod_items:useNumByItemID(6000608, 433, 1).
-spec useNumByItemID(integer(), integer(), integer()) -> any().
useNumByItemID(AccountID, ItemID, ItemNum) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {useNumByItemID, AccountID, ItemID, ItemNum}).

%% 丢弃玩家指定物品
-spec throwByWorldID(integer(), integer(), integer()) -> any().
throwByWorldID(AccountID, BagType, WorldID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {throwByWorldID, AccountID, BagType, WorldID}).

%% 丢弃玩家指定物品（多个）
-spec throwByWorldIDList(integer(), integer(), integer()) -> any().
throwByWorldIDList(AccountID, BagType, WorldIDList) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.items_pid, {throwByWorldIDList, AccountID, BagType, WorldIDList}).

%% 扣除某些材料 ItemList = [{CfgItemID,Num},{CfgItemID,Num}]
deleteSomeItemsByItemID(AccountID,ItemList) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.items_pid, {deleteSomeItemsByItemID, AccountID, ItemList}).

%% 玩家购买一个物品
-spec buyItem(integer(), integer(), integer(), integer()) -> any().
buyItem(AccountID, NPCID, ItemID, ItemNum) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {buyItem, AccountID, NPCID, ItemID, ItemNum}).

%% 玩家出售多个物品
-spec sellItems(integer(), integer(), list()) -> any().
sellItems(AccountID, NPCID, ItemList) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {sellItems, AccountID, NPCID, ItemList}).

%% 整理物品
-spec cleanItems(integer(), integer()) -> any().
cleanItems(AccountID, BagType) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {cleanItems, AccountID, BagType}).

%% 物品移动（物品同包裹内移动，物品跨包裹移动）
-spec moveItem(integer(), integer(), integer(), integer()) -> any().
moveItem(AccountID, WorldID, BagType, BagPos) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {moveItem, AccountID, WorldID, BagType, BagPos}).

%% 扩展容量
-spec expandVolume(integer(), integer(), integer()) -> any().
expandVolume(AccountID, BagType, BagPos) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {expandVolume, AccountID, BagType, BagPos}).

%% 拆分物品
-spec splitItem(integer(), integer(), integer()) -> any().
splitItem(AccountID, WorldID, SplitItem) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {splitItem, AccountID, WorldID, SplitItem}).

%%获取佣兵装备加成属性(与玩家是否在线无关)
-spec getRoleAttr(integer(), integer(),integer()) -> #attr_info{}.
getRoleAttr(AccountID, RoleID,RoleLevel) ->
%% 	PS = mod_player:get_player_status(AccountID),
%% 	gen_server:call(PS#player_status.items_pid, {getRoleAttr, PS, RoleID}).
	lib_items:getRoleAttr(AccountID, RoleID,RoleLevel).

%% 装备启灵
-spec qilingItem(integer(),integer(),integer()) -> any().
qilingItem(AccountID,WorldID,FromType) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid,{qilingItem,AccountID,WorldID,FromType}).

%% 装备洗练
-spec xilianItem(integer(),integer(),integer(),integer()) ->any().
xilianItem(AccountID,WorldID,LockIdList,FromMode) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {xilianItem,AccountID,WorldID,LockIdList,FromMode}).

%% 提升装备洗练星星数
-spec lockXilianStar(integer(),integer(),integer()) ->any().
lockXilianStar(AccountID,WorldID,Star) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid,{lockXilianStar,AccountID,WorldID,Star}).

%% 提升装备强化基础概率
-spec addIntenRate(integer(),integer(),integer()) ->any().
addIntenRate(AccountID,WorldID,AddRate) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid,{addIntenRate,AccountID,WorldID,AddRate}).

%%	获取装备星星数
-spec getXilianStar(integer(),integer()) ->any().
getXilianStar(AccountID,WorldID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid,{getXilianStar,AccountID,WorldID}).

%% 获取强化概率
-spec getIntenRate(integer(),integer()) ->any().
getIntenRate(AccountID,WorldID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid,{getIntenRate,AccountID,WorldID}).

%% 装备升级（普通、完美）
-spec upgrateItem(integer(),integer(),integer(),integer()) ->any().
upgrateItem(AccountID,WorldID,IsPerfect,FromType) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid,{upgrateItem,AccountID,WorldID,IsPerfect,FromType}).

%% 装备提升品质
-spec upItemQuality(integer(),integer(),integer()) ->any().
upItemQuality(AccountID,WorldID,FromType) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid,{upItemQuality,AccountID,WorldID,FromType}).

%%宝石镶嵌
-spec inlayJewel(integer(),integer(),integer(),integer(),integer()) ->any().
inlayJewel(AccountID,WorldID,JewelWorldID,Pos,FromType) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid,{inlayJewel,AccountID,WorldID,JewelWorldID,Pos,FromType}).

%%宝石拆卸
-spec backoutJewel(integer(),integer(),integer(),integer()) ->any().
backoutJewel(AccountID,WorldID,Pos,FromType) -> 
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid,{backoutJewel,AccountID,WorldID,Pos,FromType}).

%%采集事件处理
-spec collect(integer(),integer()) ->any().
collect(AccountID,NPCID) -> 
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid,{collect,AccountID,NPCID}).

%%装备物品
-spec equipItem(integer(), integer(), integer(), integer()) -> any().
equipItem(AccountID, WorldID, BagType, RoleID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {equipItem, AccountID, WorldID, BagType, RoleID}).

%%脱下物品
-spec unequipItem(integer(), integer(), integer()) -> any().
unequipItem(AccountID, WorldID, BagType) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {unequipItem, AccountID, WorldID, BagType}).

%%强化装备
-spec intenItem(integer(), integer(), integer(), integer()) -> any().
intenItem(AccountID, WorldID, IsLock, FromType) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {intenItem, AccountID, WorldID, IsLock, FromType}).

%%合成宝石
compose_stone(AccountID,Cfg_item_id, Type, Num)->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {compose_stone, AccountID,Cfg_item_id, Type, Num}).

%%转化宝石
convert_stone(AccountID,From_cfg_item_id,To_cfg_item_id, Type, Num)->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {convert_stone,AccountID,From_cfg_item_id,To_cfg_item_id, Type, Num}).

%% 宝石雕刻
carve_stone(AccountID,Cfg_item_id, Type, Num)->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.items_pid, {carve_stone, AccountID,Cfg_item_id, Type, Num}).



%% ====================================================================
%% Server functions
%% ====================================================================
start_link(AccountID) ->
	gen_server:start_link(?MODULE, [AccountID], []).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([AccountID]) ->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, AccountID),
	mod_player:update_module_pid(AccountID, ?MODULE, self()),
    {ok, null}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({getAllItems, AccountID}, _From, State) ->
	Reply = cache_items:getItemsByType(AccountID, 0),
    {reply, Reply, State};

handle_call({getBagItems, AccountID}, _From, State) ->
	PS = mod_player:get_player_status(AccountID),
	BagType = ?BAG_TYPE_BAG,
	ItemList = cache_items:getItemsByType(AccountID, BagType),
	BagCurrNum = cache_items:getBagNum(AccountID, BagType),
	{ok, Packet} = pt_12:write(12000, {BagType,BagCurrNum, ItemList}),
	lib_send:send_direct(PS#player_status.send_pid, Packet),
	Reply = {BagType, ItemList},
    {reply, Reply, State};

handle_call({getBankItems, AccountID}, _From, State) ->
	PS = mod_player:get_player_status(AccountID),
	BagType = ?BAG_TYPE_BANK,
	ItemList = cache_items:getItemsByType(AccountID, BagType),
	BankCurrNum = cache_items:getBagNum(AccountID, BagType),
	{ok, Packet} = pt_12:write(12000, {BagType,BankCurrNum, ItemList}),
	lib_send:send_direct(PS#player_status.send_pid, Packet),
	Reply = {BagType, ItemList},
    {reply, Reply, State};

handle_call({getAllRoleItems, AccountID}, _From, State) ->
	Reply = cache_items:getItemsByType(AccountID, 3),
    {reply, Reply, State};

handle_call({getRoleItems, AccountID, RoleID}, _From, State) ->
	Reply = cache_items:getItemsByRole(AccountID, RoleID),
    {reply, Reply, State};

handle_call({getBagNullNum, AccountID}, _From, State) ->
	BagNullNum = cache_items:getBagNullNum(AccountID, ?BAG_TYPE_BAG),
	Reply = BagNullNum,
    {reply, Reply, State};

handle_call({getBankNullNum, AccountID}, _From, State) ->
	BagNullNum = cache_items:getBagNullNum(AccountID, ?BAG_TYPE_BANK),
	Reply = BagNullNum,
    {reply, Reply, State};

handle_call({getItem, AccountID, AccountID1, WorldID, FromType}, _From, State) ->
	PS = mod_player:get_player_status(AccountID),
	case cache_items:getItemByWorldID(AccountID1, WorldID) of
		[] ->
			{ok, Packet} = pt_12:write(10999, {0, ?ERR_ITEM_NOT_EXIST}),
			Reply = {[], 0, FromType};
		Item ->
			ItemID = Item#item.cfg_ItemID,
			IntensifyLevel = Item#item.gd_IntensifyLevel,
			CfgItem = data_items:get(ItemID),
			?INFO(items, "Item = ~w, CfgItem=~w, ItemID = ~w, IntLevel=~w", [Item, CfgItem, ItemID, IntensifyLevel]),
			case CfgItem#cfg_item.cfg_FirstType of
				?ITEM_TYPE_EQUIP ->
					HoleNum = data_items:get_equip_hole_num(IntensifyLevel);
				_ ->
					HoleNum = 0
			end,
			{ok, Packet} = pt_12:write(12008, {Item, FromType}),
			Reply = {Item, HoleNum, FromType}
	end,
	lib_send:send_direct(PS#player_status.send_pid, Packet),
    {reply, Reply, State};

handle_call({getNumByItemID, AccountID, ItemID}, _From, State) ->
	case cache_items:getItemsByType(AccountID, 1) of
		[] ->
			Reply = 0;
		ItemList ->
			F = fun(Item, Sum) ->
						case Item#item.cfg_ItemID of
							ItemID ->
								Sum + Item#item.gd_StackNum;
							_ ->
								Sum
						end
				end,
			Reply = lists:foldl(F, 0, ItemList)
	end,

	{reply, Reply, State};

handle_call({getRoleAttr, AccountID, RoleID}, _From, State) ->
	Reply = lib_items:getRoleAttr(AccountID, RoleID),
    {reply, Reply, State};

%% 丢弃多个物品(慎用，无检查)
handle_call({throwByWorldIDList, AccountID, _BagType, WorldIDList}, _From, State) ->
	{ok, NewItemList} = lib_items:throwItems(AccountID,WorldIDList),
	?INFO(items, "NewItemList=~w", [NewItemList]),
	{ok, BinData} = pt_12:write(12001, NewItemList),
	lib_send:send(AccountID, BinData),
	Reply = ok,
   	{reply, Reply, State};

%% 扣除多个物品（慎用，无检查）
handle_call({deleteSomeItemsByItemID, AccountID, ItemList}, _From, State) ->
	NewItemList = lib_items:deleteSomeItems(AccountID,ItemList),
	?INFO(items, "***********NewItemList=~w", [NewItemList]),
	{ok, BinData} = pt_12:write(12001, NewItemList),
	lib_send:send(AccountID, BinData),
	Reply = ok,
   	{reply, Reply, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Descript: 背包操作类方法
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
%% 按物品列表创建多个物品
handle_cast({createItems, AccountID, ItemList, FromType}, State) ->
	case check_items:createItems(AccountID, ItemList) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode});
		{ok, ItemList1} ->
			{ok, NewItemList} = lib_items:createItems(AccountID, ItemList1, FromType),
			?INFO(items, "NewItemList=~w", [NewItemList]),
			{ok, BinData} = pt_12:write(12001, NewItemList)
	end,
	lib_send:send(AccountID, BinData),
    {noreply, State};

handle_cast({createItemsOnRole,AccountID,RoleID,ItemList,FromType}, State) ->
	case check_items:createItemsOnRole(AccountID,RoleID,ItemList) of
		{fail,ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode});
		{ok,ItemList1} ->
			{ok,NewItemList} = lib_items:createItemsOnRole(AccountID, RoleID, ItemList1, FromType),
			?INFO(items, "NewItemList=~w", [NewItemList]),
			{ok, BinData} = pt_15:write(15010, NewItemList),
			mod_role:update_attri_notify(AccountID,RoleID)
	end,
	lib_send:send(AccountID, BinData),
    {noreply, State};

%% 使用一定数量的一类物品
handle_cast({useNumByItemID, AccountID, ItemID, ItemNum}, State) ->
	PS = mod_player:get_player_status(AccountID),
	case check_items:useNumByItemID(AccountID, ItemID, ItemNum) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode});
		{ok, ItemList} ->
			RoleID = 0,
			{ok, NewItemList} = lib_items:useItems(AccountID, RoleID, ItemList, ItemNum),
			?INFO(items, "NewItemList=~w", [NewItemList]),
			{ok, BinData} = pt_12:write(12001, NewItemList)
	end,
	lib_send:send_direct(PS#player_status.send_pid, BinData),
    {noreply, State};

%% 使用一定数量的一个物品
handle_cast({useNumByWorldID, AccountID, _BagType, RoleID, WorldID, ItemNum}, State) ->
	PS = mod_player:get_player_status(AccountID),
	case check_items:useNumByWorldID(AccountID, WorldID, ItemNum) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode});
		{ok, Item} ->
			{ok, NewItemList} = lib_items:useItems(AccountID, RoleID, [Item], ItemNum),
			?INFO(items, "NewItemList=~w", [NewItemList]),
			{ok, BinData} = pt_12:write(12001, NewItemList)
	end,
	lib_send:send_direct(PS#player_status.send_pid, BinData),
    {noreply, State};

%% 丢弃一个物
handle_cast({throwByWorldID, AccountID, _BagType, WorldID}, State) ->
	PS = mod_player:get_player_status(AccountID),
	case check_items:throwByWorldID(AccountID, WorldID) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode});
		{ok, Item} ->
			{ok, NewItemList} = lib_items:throwItem(Item),
			?INFO(items, "NewItemList=~w", [NewItemList]),
			{ok, BinData} = pt_12:write(12001, NewItemList)
	end,
	lib_send:send_direct(PS#player_status.send_pid, BinData),
    {noreply, State};



%% 购买一个物品
handle_cast({buyItem, AccountID, NPCID, ItemID, ItemNum}, State) ->
	PS = mod_player:get_player_status(AccountID),
	case check_items:buyItem(AccountID, NPCID, ItemID, ItemNum) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode});
		{ok, ItemList, SilverCost,GoldCost} ->
			?INFO(items,"cost = ~w",[SilverCost]),
			{ok, NewItemList} = lib_items:buyItems(AccountID, NPCID, ItemList, SilverCost,GoldCost),
			?INFO(items, "NewItemList=~w", [NewItemList]),
			{ok, BinData} = pt_12:write(12001, NewItemList)
	end,
	lib_send:send_direct(PS#player_status.send_pid, BinData),
    {noreply, State};

%% 出售多个物品
handle_cast({sellItems, AccountID, NPCID, ItemIDList}, State) ->
	PS = mod_player:get_player_status(AccountID),
	case check_items:sellItems(AccountID, NPCID, ItemIDList) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode});
		{ok, ItemList, SellSumSilver} ->
			{ok, NewItemList} = lib_items:sellItems(AccountID, ItemList, SellSumSilver),
			?INFO(items, "NewItemList=~w", [NewItemList]),
			{ok,Bin} = pt_12:write(12006,{}),
			lib_send:send_direct(PS#player_status.send_pid, Bin),
			{ok, BinData} = pt_12:write(12001, NewItemList)
	end,
	lib_send:send_direct(PS#player_status.send_pid, BinData),
    {noreply, State};

%% 整理物品
handle_cast({cleanItems, AccountID, BagType}, State) ->
	PS = mod_player:get_player_status(AccountID),
	case check_items:cleanItems(BagType) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode});
		ok ->
			AccountID = PS#player_status.id,
			{ok, NewItemList} = lib_items:cleanItems(AccountID, BagType),
			?INFO(items, "NewItemList=~w", [NewItemList]),
			BagCurrNum = cache_items:getBagNum(AccountID, BagType),
			{ok, BinData} = pt_12:write(12000, {BagType, BagCurrNum, NewItemList})
	end,
	lib_send:send_direct(PS#player_status.send_pid, BinData),
    {noreply, State};

%% 包包内移动物品
handle_cast({moveItem, AccountID, WorldID, BagType, BagPos}, State) ->
	PS = mod_player:get_player_status(AccountID),
	case check_items:moveItem(AccountID, WorldID, BagType, BagPos) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode});
		{ok, Item} ->
			BagType1 = Item#item.gd_BagType,
			case BagType1 of
				BagType ->
					{ok, NewItemList} = lib_items:moveItem(AccountID, Item, BagType, BagPos);
				_ ->
					{ok, NewItemList} = lib_items:moveBag(AccountID, Item, BagType)
			end,
			{ok, BinData} = pt_12:write(12001, NewItemList),
			?INFO(items, "NewItemList=~w", [NewItemList])
	end,
	lib_send:send_direct(PS#player_status.send_pid, BinData),
    {noreply, State};

%% 背包->仓库
handle_cast({moveBag, AccountID, WorldID, BagType, BagPos}, State) ->
	PS = mod_player:get_player_status(AccountID),
	case check_items:moveBag(PS, WorldID, BagPos) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode});
		{ok, Item} ->
			AccountID = PS#player_status.id,
			{ok, NewItemList} = lib_items:moveBag(AccountID, Item, BagType),
			?INFO(items, "NewItemList=~w", [NewItemList]),
			{ok, BinData} = pt_12:write(12001, NewItemList)
	end,
	lib_send:send_direct(PS#player_status.send_pid, BinData),
    {noreply, State};

%% %% 仓库->背包
%% handle_cast({bankToBag, PS, WorldID, BagPos}, State) ->
%% 	case check_items:bankToBag(PS, WorldID, BagPos) of
%% 		{fail, ErrCode} ->
%% 			{ok, BinData} = pt_10:write(10999, {0, ErrCode});
%% 		{ok, Item} ->
%% 			AccountID = PS#player_status.id,
%% 			BagType = ?BAG_TYPE_BAG,
%% 			{ok, NewItemList} = lib_items:moveBag(AccountID, Item, BagType),
%% 			{ok, BinData} = pt_12:write(12001, NewItemList)
%% 	end,
%% 	lib_send:send_direct(PS#player_status.send_pid, BinData),
%%     {noreply, State};

%% 扩展容量
handle_cast({expandVolume, AccountID, BagType, BagPos}, State) ->
	PS = mod_player:get_player_status(AccountID),
	case check_items:expandVolume(AccountID, BagType, BagPos) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode});
		{ok, GoldCost} ->
			ok= lib_items:expandVolume(AccountID, BagType, BagPos, GoldCost),
			{ok, BinData} = pt_12:write(12003, {BagType, BagPos})
	end,
	lib_send:send_direct(PS#player_status.send_pid, BinData),
    {noreply, State};

%% 物品拆分
handle_cast({splitItem, AccountID, WorldID, SplitNum}, State) ->
	PS = mod_player:get_player_status(AccountID),
	case check_items:splitItem(AccountID, WorldID, SplitNum) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode});
		{ok, Item} ->
			{ok, NewItemList} = lib_items:splitItem(Item, SplitNum),
			?INFO(items, "NewItemList=~w", [NewItemList]),
			{ok, BinData} = pt_12:write(12001, NewItemList)
	end,
	lib_send:send_direct(PS#player_status.send_pid, BinData),
    {noreply, State};



%% --------------------------------------------------------------------
%% Descript: 装备操作类方法
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
%% 装备一个物品
handle_cast({equipItem, AccountID, WorldID, BagType, RoleID}, State) ->
	case check_items:equipItem(AccountID, WorldID, BagType, RoleID) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode}),
			lib_send:send(AccountID,BinData);
		{ok, Item, CfgItem} ->
			{ok, NewItem, NewItemList} = lib_items:equipItem(RoleID, Item, CfgItem),
			?INFO(items, "NewItemList=~w", [NewItemList]),
			{ok, BinData1} = pt_12:write(12001, NewItemList),
			{ok, BinData2} = pt_15:write(15010, [NewItem]),
			lib_send:send(AccountID,<<BinData1/binary, BinData2/binary>>)
	end,
    {noreply, State};

%% 卸下一个装备物品
handle_cast({unequipItem, AccountID, WorldID, BagType}, State) ->
	case check_items:unequipItem(AccountID, WorldID, BagType) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData} = pt_10:write(10999, {0, ErrCode}),
			lib_send:send(AccountID,BinData);
		{ok, Item} ->
			{ok, NewItem, NewItemList} = lib_items:unequipItem(Item, BagType),
			?INFO(items, "NewItemList=~w", [NewItemList]),
			?INFO(items, "NewItemList=~w", [NewItemList]),
			{ok, BinData1} = pt_12:write(12001, NewItemList),
			{ok, BinData2} = pt_15:write(15010, [NewItem]),
			lib_send:send(AccountID,<<BinData1/binary, BinData2/binary>>)
	end,
    {noreply, State};

%% 强化物品
handle_cast({intenItem, AccountID, WorldID, IsLock, FromType}, State) ->
	case check_items:intenItem(AccountID, WorldID, IsLock) of
		{fail, ErrCode} ->
			?INFO(items, "ErrCode = [~w]", [ErrCode]),
			{ok, BinData1} = pt_10:write(10999, {0, ErrCode}),
			BinData2 = <<>>;
		{ok, Item, SilverCost, GoldCost, HoldRate} ->
			{ok, NewItem} = lib_items:intenItem(Item, SilverCost, GoldCost, HoldRate),
			BaseRate = NewItem#item.gd_IntenRate,
			FailRate = NewItem#item.gd_IntenFailRate,
			?INFO(items, "HoldRate=~w", [HoldRate]),
			?INFO(items, "NewItem=~w", [NewItem]),
			{ok, BinData1} = pt_12:write(12008, {NewItem, FromType}),
			{ok,BinData2} = pt_12:write(12016,{WorldID, 2, BaseRate, FailRate})
	end,
	lib_send:send(AccountID,<<BinData1/binary, BinData2/binary>>),
    {noreply, State};


%% 物品启灵
handle_cast({qilingItem,AccountID,WorldID,FromType},State) ->
	case check_items:qilingItem(AccountID,WorldID) of
		{fail,ErrCode} ->
			?INFO(items, "ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode}),
			lib_send:send(AccountID,BinData);
		{ok,Item,SilverCost,ItemCostList} ->
			{ok,NewItem,NewItemList} = lib_items:qilingItem(Item,SilverCost,ItemCostList),
			?INFO(items,"NewItem = ~w",[NewItem]),
			{ok,BinData2} = pt_12:write(12008, {NewItem,FromType}),
			{ok,BinData1} = pt_12:write(12001,NewItemList),
			lib_send:send(AccountID,<<BinData1/binary, BinData2/binary>>)
	end,
	{noreply,State};

%% 物品洗练
handle_cast({xilianItem,AccountID,WorldID,LockIdList,FromType},State) ->
	case check_items:xilianItem(AccountID,WorldID,LockIdList) of
		{fail,ErrCode} ->
			?INFO(items,"ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode});
		{ok,Item,SilverCost,GoldCost} ->
			{ok,NewItem} = lib_items:xilianItem(Item,SilverCost,GoldCost,LockIdList),
			?INFO(items,"NewItem = ~w",[NewItem]),
			{ok,BinData} = pt_12:write(12008,{NewItem, FromType})
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 获取装备洗练星星数
handle_cast({getXilianStar,AccountID,WorldID},State) ->
	case check_items:getXilianStar(AccountID,WorldID) of
		{fail,ErrCode} ->
			?INFO(items,"ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode});
		{ok,Item} ->
			Star = Item#item.gd_LuckyStar,
			?INFO(items,"LuckyStar = ~w",[Star]),
			{ok,BinData} = pt_12:write(12016,{WorldID,1,Star,0})
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 获取强化概率
handle_cast({getIntenRate,AccountID,WorldID},State) ->
	case check_items:getIntenRate(AccountID,WorldID) of
		{fail,ErrCode} ->
			?INFO(items,"ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode});
		{ok,Item} ->
			GdBaseRate = Item#item.gd_IntenRate,
			case GdBaseRate =:= 0 andalso Item#item.gd_IntensifyLevel < 74 of
				true ->
					BaseRate = data_items:get_inten_rate(Item#item.gd_IntensifyLevel div 5 +1);
				false ->
					BaseRate = GdBaseRate
			end,
			FailRate = Item#item.gd_IntenFailRate,
			?INFO(items,"IntenRate = ~w and ~w",[BaseRate,FailRate]),
			{ok,BinData} = pt_12:write(12016,{WorldID,2,BaseRate,FailRate})
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 提升装备星星数
handle_cast({lockXilianStar,AccountID,WorldID,Star},State) ->
	case check_items:lockXilianStar(AccountID,WorldID,Star) of
		{fail,ErrCode} ->
			?INFO(items,"ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode});
		{ok,Item,GoldCost} ->
			{ok,LuckyStar} = lib_items:lockXilianStar(Item,GoldCost,Star),
			?INFO(items,"LuckyStar = ~w",[LuckyStar]),
			{ok,BinData} = pt_12:write(12016,{WorldID,1,LuckyStar,0})
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};
 
%% 提升装备强化概率
handle_cast({addIntenRate,AccountID,WorldID,AddRate},State) ->
	case check_items:addIntenRate(AccountID,WorldID,AddRate) of
		{fail,ErrCode} ->
			?INFO(items,"ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode});
		{ok,Item,GoldCost} ->
			{ok,BaseRate,FailRate} = lib_items:addIntenRate(Item,GoldCost,AddRate),
			?INFO(items,"BaseRate = ~w",[BaseRate]),
			{ok,BinData} = pt_12:write(12016,{WorldID,2,BaseRate,FailRate})
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 装备升级
handle_cast({upgrateItem,AccountID,WorldID,IsPerfect,FromType},State) ->
	case check_items:upgrateItem(AccountID,WorldID,IsPerfect) of
		{fail,ErrCode} ->
			?INFO(items,"ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode}),
			lib_send:send(AccountID,BinData);
		{ok,Item,GoldCost,SilverCost,CostItemList} ->
			{ok,NewItem, NewItemList} = lib_items:upgrateItem(Item,SilverCost,GoldCost,CostItemList,IsPerfect), 
			?INFO(items,"NewItem = ~w", [NewItem]),
			{ok,BinData1} = pt_12:write(12001, NewItemList),
			{ok,BinData2} = pt_12:write(12008, {NewItem, FromType}),
			lib_send:send(AccountID,<<BinData1/binary,BinData2/binary>>)
	end,
	{noreply,State};

%% 提升装备品质
handle_cast({upItemQuality,AccountID,WorldID,FromType},State) ->
	case check_items:upItemQuality(AccountID,WorldID) of 
		{fail,ErrCode} ->
			?INFO(items,"ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode}),
			lib_send:send(AccountID,BinData);
		{ok,Item,SilverCost,CostItemList} ->
			{ok,NewItem,NewItemList} = lib_items:upItemQuality(Item,SilverCost,CostItemList), 
			?INFO(items,"NewItem = ~w", [NewItem]),
			?INFO(items,"NewItemList = ~w", [NewItemList]),
			{ok,BinData1} = pt_12:write(12001, NewItemList),
			{ok,BinData2} = pt_12:write(12008, {NewItem, FromType}),
			lib_send:send(AccountID,<<BinData1/binary,BinData2/binary>>)
	end,

	{noreply,State};

%% 宝石镶嵌
handle_cast({inlayJewel,AccountID,WorldID,JewelWorldID,Pos,FromType},State) ->
	case check_items:inlayJewel(AccountID,WorldID,JewelWorldID,Pos) of
		{fail,ErrCode} ->
			?INFO(items,"ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode}),
			lib_send:send(AccountID,BinData);
		{ok,Item,ItemJewel,SilverCost} ->
			{ok,NewItem, NewItemList} = lib_items:inlayJewel(Item,ItemJewel,SilverCost,Pos),
			?INFO(items,"NewItem = ~w", [NewItem]),
			{ok,BinData1} = pt_12:write(12001, NewItemList),
			{ok,BinData2} = pt_12:write(12008, {NewItem, FromType}),
			lib_send:send(AccountID,<<BinData1/binary,BinData2/binary>>)
	end,
	{noreply,State};

%% 宝石拆卸
handle_cast({backoutJewel,AccountID,WorldID,Pos,FromType},State) ->
	case check_items:backoutJewel(AccountID,WorldID,Pos) of
		{fail,ErrCode} ->
			?INFO(items,"ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode}),
			lib_send:send(AccountID,BinData);
		{ok,Item,JewelCfgID,SilverCost} ->
			{ok,NewItem,NewItemList} = lib_items:backoutJewel(Item,JewelCfgID,SilverCost,Pos),
			?INFO(items,"NewItem = ~w", [NewItem]),
			?INFO(items,"NewItemList = ~w",[NewItemList]),
			{ok,BinData1} = pt_12:write(12001, NewItemList),
			{ok,BinData2} = pt_12:write(12008, {NewItem, FromType}),
			lib_send:send(AccountID,<<BinData1/binary,BinData2/binary>>)
	end,
	{noreply,State};

%% 信息反馈(使用藏宝图)
handle_cast({message, AccountID, Message},State) ->
	?INFO(items,"WLSD messages is:~w",[Message]),
	case Message of
	 	{wlsd, Type, ItemID, MonsterID, Gold, BindGold, Silver} ->
	 		{ok, BinData} = pt_12:write(12063, {Type, ItemID, MonsterID, Gold, BindGold, Silver});
	 	{wlsd, ItemList, ItemID} ->
	 		{ok, Packet1} = pt_12:write(12063, {2, ItemID, 0, 0, 0, 0}),
			{ok, Packet2} = pt_12:write(12001, ItemList),
			BinData = <<Packet1/binary, Packet2/binary>>;
	 	_Else ->
		 	?INFO(items,"ErrCode = [~w]",[?ERR_ITEM_MESSAGE_ERR]),
			{ok,BinData} = pt_10:write(10999,{0,?ERR_ITEM_MESSAGE_ERR})
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 采集事件处理
handle_cast({collect,AccountID,NPCID},State) ->
	case check_items:collect(NPCID) of
		{fail,ErrCode} ->
			?INFO(items,"ErrCode = [~W]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode}),
			lib_send:send(AccountID,BinData);
		{ok,Num} ->
			lib_items:collect(NPCID,AccountID,Num)
	end,
	{noreply,State};

%%宝石合成
handle_cast({compose_stone, Id, Cfg_item_id, Type, Num} , State) ->
	?INFO(item, "compose stone, account ~w, item id ~w, type ~w,num:~w",[Id,Cfg_item_id, Type, Num]),
	%%合成宝石,检查背包宝石够不够，钱够不够
	%%生成宝石,删除被合成的宝石
	%%然后返回合成结果，返回物品更新包
			case check_items:compose_stone(Id, Cfg_item_id, Type, Num) of
				{fail, ErrCode}->
					?INFO(items, "Errcode =~w",[ErrCode]),
					{ok,Bin} = pt_12:write(10999,{0,ErrCode}),
					lib_send:send(Id,Bin);
				Compose_times ->
					?INFO(item, "check success, compose ~w times",[Compose_times] ),
%% 					{Create_item_list, Delete_item_list} = lib_items:compose_stone(Id,Cfg_item_id,Compose_times ),
					{Create_item_list, Delete_item_list} = check_items:compose_stone_list(Id,Cfg_item_id,Compose_times),
					case {Create_item_list, Delete_item_list} of
					{fail, ErrCode}->
							?INFO(item,"create item fail errcode:~w",[ErrCode]);
						{_R,_Re} ->
							case length(Create_item_list) of
								0 ->
									?INFO(item, "can not compose"),
									{ok,Bin} = pt_12:write(12040,{0}),
									lib_send:send(Id,Bin);
								_->
									{ok,Bin1} = pt_12:write(12001,Delete_item_list),
									{ok,Bin2} = pt_12:write(12001,Create_item_list),
									lib_send:send(Id,<<Bin1/binary,Bin2/binary>>),
									Target_cfg_item_id = data_items:get_compose_target(Cfg_item_id),
									{ok,Bin3} = pt_12:write(12040,{Compose_times, Target_cfg_item_id}),
									lib_send:send(Id,Bin3),

									?INFO(item, "success compose ~w, delete ~w,create ~w times", 
									[Create_item_list,Delete_item_list,Compose_times])
							end
					end
			end,
{noreply,State};
	
%%宝石转化
handle_cast({convert_stone,Id,From_cfg_item_id,To_cfg_item_id, Type, Num}, State)->
	?INFO(item,"convert stone,accountid:~w,from_cfg_itm_id:~w,to_cfg_item_id:~w,type:~w, num:~w",
			[Id,From_cfg_item_id,To_cfg_item_id, Type,Num]),
	%%check背包宝石，钱够不够
	%%转化宝石,删除被转化的宝石
	%%然后返回转化结果，返回物品更新包
			case check_items:convert_stone(Id, From_cfg_item_id, Type, Num) of
				{fail, ErrCode}->
					?INFO(items, "Errcode =~w",[ErrCode]),
					{ok,Bin} = pt_12:write(10999,{0,ErrCode}),
					lib_send:send(Id,Bin);
				Convert_times ->
					?INFO(item, "check success, convert ~w times",[Convert_times] ),
					{Create_item_list, Delete_item_list} = check_items:convert_stone_list(Id, From_cfg_item_id, To_cfg_item_id, Convert_times),
					case {Create_item_list, Delete_item_list} of
						{fail, ErrCode}->
							?INFO(item,"create item fail errcode:~w",[ErrCode]);
						{_R,_Re} ->
							case length(Create_item_list) of
								0 ->
									?INFO(item, "can not convert"),
									{ok,Bin} = pt_12:write(12041,{0}),
									lib_send:send(Id,Bin);
								_->
									{ok,Bin1} = pt_12:write(12001,Delete_item_list),
									{ok,Bin2} = pt_12:write(12001,Create_item_list),
									lib_send:send(Id,<<Bin1/binary,Bin2/binary>>),

									{ok,Bin3} = pt_12:write(12041,{Convert_times, To_cfg_item_id}),
									lib_send:send(Id,Bin3),

									?INFO(item, "success convert ~w, delete ~w,create ~w times", 
									[Create_item_list,Delete_item_list,Convert_times])
							end
					end
			end,
{noreply,State};		

%%宝石雕刻
handle_cast({carve_stone, Id, Cfg_item_id, Type,Num}, State)->
	?INFO(item,"carve stone,accountid:~w,cfg_itm_id:~w,type:~w",[Id,Cfg_item_id,Type]),
	%%check背包宝石,雕刻材料，钱够不够
	%%雕刻宝石,删除被雕刻的宝石
	%%然后返回雕刻结果，返回物品更新包
			case check_items:carve_stone(Id, Cfg_item_id, Type, Num) of
				{fail, ErrCode}->
					?INFO(items, "Errcode =~w",[ErrCode]),
					{ok,Bin} = pt_12:write(10999,{0,ErrCode}),
					lib_send:send(Id,Bin);
				Carve_times ->
					?INFO(item, "check success, carve ~w times",[Carve_times] ),
					{Create_item_list, Delete_item_list1,Delete_item_list2} = check_items:carve_stone_list(Id, Cfg_item_id,Carve_times),
					case {Create_item_list, Delete_item_list1, Delete_item_list2} of
						{fail, ErrCode, 0}->
							?INFO(item,"create item fail errcode:~w",[ErrCode]);
						{_R,_Re,_Ret} ->
							case length(Create_item_list) of
								0 ->
									?INFO(item, "can not carve"),
									{ok,Bin} = pt_12:write(12042,{0}),
									lib_send:send(Id,Bin);
								_->
									{ok,Bin1} = pt_12:write(12001,Delete_item_list1),
									{ok,Bin2} = pt_12:write(12001,Delete_item_list2),
									{ok,Bin3} = pt_12:write(12001,Create_item_list),
									lib_send:send(Id,<<Bin1/binary,Bin2/binary,Bin3/binary>>),
									Target_id = data_items:get_carve_target(Cfg_item_id),
									{ok,Bin4} = pt_12:write(12042,{Carve_times, Target_id}),
									lib_send:send(Id,Bin4),

									?INFO(item, "success carve ~w, delete ~w,create ~w times", 
									[Create_item_list,Delete_item_list1,Delete_item_list2,Carve_times])
							end
					end
			end,
{noreply,State};		


handle_cast(_Request, State) ->
    {noreply,State}.


%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------



