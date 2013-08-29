%%%-----------------------------------
%%% @Module  : pt_15
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.04.29
%%% @Description: 15物品信息
%%%-----------------------------------
-module(pt_12).
-include("common.hrl").

-export([read/2, write/2]).

%%
%%客户端 -> 服务端 ----------------------------
%%
%% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 三国项目物品模块 ----------------------------						%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 
%% 查询背包物品列表
read(12000, <<BagType:8, RoleID:32>>) ->
    ?INFO(items, "read: ~w",[[12000, BagType, RoleID]]),
    {ok, {BagType, RoleID}};

%% 移动物品
read(12001, <<WorldID:32, BagType:8, RoleID:32, BagPos:32>>) ->
    ?INFO(items,"read: ~w",[[12001, WorldID, BagType, RoleID, BagPos]]),
    {ok, {WorldID, BagType, RoleID, BagPos}};

%% 包包整理
read(12002, <<BagType:8>>) ->
    ?INFO(items,"read: ~w",[[12002, BagType]]),
    {ok, BagType};
    
%% 背包格子开锁
read(12003, <<BagType:8, BagPos:32>>) ->
    ?INFO(items,"read: ~w",[[12003, BagType, BagPos]]),
    {ok, {BagType, BagPos}};

%% 使用物品
read(12004, <<BagType:8, RoleID:32, WorldID:32, UseNum:32>>) ->
    ?INFO(items,"read: ~w",[[12004, BagType, RoleID, WorldID, UseNum]]),
    {ok, {BagType, RoleID, WorldID, UseNum}};     

%% 丢弃背包一个格子的物品
read(12005, <<BagType:8, WorldID:32>>) ->
    ?INFO(items,"read: ~w",[[12005, BagType, WorldID]]),
    {ok, {BagType, WorldID}};

%% 商店出售物品
read(12006, <<NPCID:32, Size:16, IDList/binary>>) ->
	WorldIDList = readIDList(Size, IDList),
	?INFO(items,"read: ~w",[[12006, NPCID, Size, WorldIDList]]),
	{ok, {NPCID, WorldIDList}};

%% 商店购买物品
read(12007, <<NPCID:32, ItemID:32, ItemNum:32>>) ->
	?INFO(items,"read: ~w",[[12007, NPCID, ItemID, ItemNum]]),
	{ok, {NPCID, ItemID, ItemNum}};

%% 获取物品详细信息
read(12008, <<AccountID:32, WorldID:32, FromMode:8>>) ->
	?INFO(items,"read: ~w",[[12008, AccountID, WorldID, FromMode]]),
	{ok, {AccountID, WorldID, FromMode}};

%% 物品拆分
read(12009, <<WorldID:32, SplitNum:32>>) ->
	?INFO(items,"read: ~w",[[12009, WorldID, SplitNum]]),
	{ok, {WorldID, SplitNum}};

%% 装备强化
read(12010,<<FromType:8, WorldID:32, IsLock:8>>) ->
	?INFO(items,"read: ~w",[[12010,WorldID, IsLock, FromType]]),
	{ok, {WorldID,IsLock,FromType}};

%% 装备启灵
read(12011, <<FromType:8, WorldItemID:32>>) ->
	?INFO(items,"read: ~w",[[12011, WorldItemID,FromType]]),
	{ok, {WorldItemID, FromType}};

%% 装备洗练
read(12012,<<FromMode:8, WorldItemID:32, Size:16, IdList/binary>>) ->
	LockIdList = readIDList(Size, IdList),
	?INFO(items,"read: ~w",[[12012, WorldItemID, LockIdList]]),
	{ok,{WorldItemID, LockIdList, FromMode}};

%% 修改洗练星星值
read(12013,<<WorldItemID:32,Star:32>>) ->
	?INFO(items,"read: ~w",[[12013, WorldItemID, Star]]),
	{ok,{WorldItemID, Star}};

%% 装备升级
read(12014,<<FromType:8,WorldItemID:32,IsPerfect:8>>) ->
	?INFO(items,"read: ~w",[[12014, WorldItemID, IsPerfect,FromType]]),
	{ok,{WorldItemID, IsPerfect, FromType}};

%% 装备品质提升
read(12015,<<FromType:8,WorldItemID:32>>) ->
	?INFO(items,"read: ~w",[[12015,WorldItemID,FromType]]),
	{ok,{WorldItemID,FromType}};

%% 获取洗练星星值/强化概率
read(12016,<<WorldItemID:32,Type:32>>) ->
	?INFO(items,"read: ~w",[[12016, WorldItemID, Type]]),
	{ok,{WorldItemID, Type}};

%% 获取洗练星星值/强化概率
read(12017,<<WorldItemID:32,AddRate:32>>) ->
	?INFO(items,"read: ~w",[[12016, WorldItemID, AddRate]]),
	{ok,{WorldItemID, AddRate}};

%% 宝石镶嵌
read(12018,<<FromType:8,WorldID:32,JewelWorldID:32,Pos:32>>) ->
	?INFO(items,"read: ~w",[[12018, WorldID, JewelWorldID, Pos, FromType]]),
	{ok,{WorldID, JewelWorldID, Pos, FromType}};

%% 宝石拆卸
read(12019,<<FromType:8,WorldID:32,Pos:32>>) ->
	?INFO(items,"read: ~w",[[12019, WorldID, Pos, FromType]]),
	{ok,{WorldID, Pos, FromType}};

%% ************************* 华丽的分隔线 ************************* %%




%% 查询仓库物品列表
read(12020, <<Flag:8>>) ->
    ?INFO(items,"read: ~w",[[12020, Flag]]),
    {ok, Flag};

%% 仓库拖拉物品
read(12021, <<OldBagPos:8, NewBagPos:8>>) ->
    ?INFO(items,"read: ~w",[[12021, OldBagPos, NewBagPos]]),
    {ok, [OldBagPos, NewBagPos]};

%% 仓库整理
read(12022, <<Flag:8>>) ->
    ?INFO(items,"read: ~w",[[12022, Flag]]),
    {ok, Flag};
    
%% 仓库->背包
read(12023, <<BagBagPos:8, BankBagPos:8>>) ->
    ?INFO(items,"read: ~w",[[12023, BagBagPos, BankBagPos]]),
    {ok, [BagBagPos, BankBagPos]};
    
%% 背包->仓库
read(12024, <<BagBagPos:8, BankBagPos:8>>) ->
    ?INFO(items,"read: ~w",[[12024, BagBagPos, BankBagPos]]),
    {ok, [BagBagPos, BankBagPos]};

%% 仓库格子开锁
read(12025, <<NewPosNum:8>>) ->
    ?INFO(items,"read: ~w",[[12026, NewPosNum]]),
    {ok, NewPosNum};

%% 获取物品详细信息
read(12030, <<AccountID:32, WorldItemID:32, Type:8>>) ->
	?INFO(items,"read: ~w",[[12030, AccountID, WorldItemID, Type]]),
    {ok, [AccountID, WorldItemID, Type]};

%%12040协议组，宝石系统
%% 宝石合成模块
%% 宝石合成请求(12040) C->S
%% CMSG_JEWEL _COMBIN			= 12040			//宝石合成请求
%% Int32:	宝石原型id
%% Uint8:	合成类型 0单个合成，1批量合成
%% Unit8:   批量合成数
read(12040, Bin)->
	<<Cfg_item_id:32,Type:8, Num:32>> = Bin,
	?INFO(items,"componse bin:~w",[Bin]),
	{ok,{Cfg_item_id, Type, Num}};

%% 
%% 单个宝石转化(12041) C->S
%% CMSG_JEWEL _CONVERT			= 12041			//宝石转化请求
%% Int32: 被转化的宝石原型ID
%% Int32: 转化为宝石原型ID
%% Uint8:	转化类型 0单个合成，1批量合成
%% Unit8: 批量转化数
read(12041, Bin)->
	<<From_cfg_item_id:32,To_cfg_item_id:32,Type:8, Num:32>> = Bin,
	{ok,{From_cfg_item_id,To_cfg_item_id, Type, Num}};


%% 宝石雕刻(12042) C->S
%% CMSG_JEWEL_CARVE				= 12042		//宝石雕刻
%% Int32:被雕刻宝石的原型ID
%% Uint8:	雕刻类型 0单个雕刻，1批量雕刻
%% Unit8: 批量雕刻数
read(12042, Bin)->
	<<Cfg_item_id:32,Type:8, Num:32>> = Bin,
	{ok,{Cfg_item_id, Type, Num}};



%% 穿装备
read(12050, <<MerID:16, BagPos:8, EquipPos:8>>) ->
	?INFO(items,"read: ~w",[[12050, MerID, BagPos, EquipPos]]),
	{ok, [MerID, BagPos, EquipPos]};

%% 卸装备
read(12051, <<MerID:16, Pos:8, BagPos:8>>) ->
	?INFO(items,"read: ~w",[[12051, MerID, Pos, BagPos]]),
	{ok, [MerID, Pos, BagPos]};

%% 装备强化
read(12052, <<MerID:16, EquipPos:8, Protection:8, OldIntenRate:8>>) ->
	?INFO(items,"read: ~w",[[12052, MerID, EquipPos, Protection, OldIntenRate]]),
	{ok, [MerID, EquipPos, Protection, OldIntenRate]};

%% 装备降级
read(12053, <<MerID:16, EquipPos:8>>) ->
	?INFO(items,"read: ~w",[[12053, MerID, EquipPos]]),
	{ok, [MerID, EquipPos]};

%% 强化成功率
read(12054, <<Flag:8>>) ->
	?INFO(items,"read: ~w",[[12054, Flag]]),
    {ok, Flag};

%% 装备分解
read(12055, <<Size:16, PosList/binary>>) ->
	NewPosList = read_pos_list(Size, PosList, []),
	?INFO(items,"read: ~w",[[12055, Size, NewPosList]]),
    {ok, NewPosList};

%% 戒指升星
read(12056, <<IsUseGold:8, Size:16, RingPosList/binary>>) ->
	NewRingPosList = read_pos_list(Size, RingPosList, []),
	?INFO(items,"read: ~w",[[12056, IsUseGold, Size, NewRingPosList]]),
    {ok, [NewRingPosList, IsUseGold]};

%% 物品拆分
read(12057, <<WorldItemID:32, SplitNum:8>>) ->
	?INFO(items,"read: ~w",[[12057, WorldItemID, SplitNum]]),
    {ok, [WorldItemID, SplitNum]};


%%=============================================================================
%% 寻仙系统
%%=============================================================================
%% 请求当前寻仙信息
read(12100, <<>>) ->
	?INFO(xunxian,"read: ~w",[[12100]]),
	{ok, []};

%% 寻仙一次请求
read(12101, <<>>) ->
	?INFO(xunxian,"read: ~w",[[12101]]),
	{ok, []};

%% 拾起一个物品请求
read(12102, <<ItemPos:32>>) ->
	?INFO(xunxian,"read: ~w",[[12102, ItemPos]]),
	{ok, {ItemPos}};

%%  卖出一个物品
read(12103, <<ItemPos:32>>) ->
	?INFO(xunxian,"read: ~w",[[12103, ItemPos]]),
	{ok, {ItemPos}};

%% 一键寻仙
read(12104, <<Silver:32>>) ->
	?INFO(xunxian,"read: ~w",[[12104,Silver]]),
	{ok, {Silver}};

%% 一键拾起
read(12105, <<>>) ->
	?INFO(xunxian,"read: ~w",[[12105]]),
	{ok, []};

%% 一键卖出
read(12106, <<>>) ->
	?INFO(xunxian,"read: ~w",[[12106]]),
	{ok, []};

%% 锁定最高仙人
read(12107, <<>>) ->
	?INFO(xunxian,"read: ~w",[12107]),
	{ok,[]};


%%=============================================================================
%% 炼金系统 end
%%=============================================================================

%%=============================================================================
%% 交易系统
%%=============================================================================
%% 交易申请
read(12200, <<AccountID:32>>) ->
	?INFO(trade,"read: ~w",[[12200, AccountID]]),
	{ok, AccountID};

%% 接受交易
read(12201, <<AccountID:32>>) ->
	?INFO(trade,"read: ~w",[[12201, AccountID]]),
	{ok, AccountID};

%% 拒绝交易
read(12202, <<AccountID:32>>) ->
	?INFO(trade,"read: ~w",[[12202, AccountID]]),
	{ok, AccountID};

%% 物品从背包拖到交易栏
read(12203, <<BagPos:8>>) ->
	?INFO(trade,"read: ~w",[[12203, BagPos]]),
	{ok, BagPos};

%% 锁定交易栏
read(12204, <<Silver:32, Gold:32>>) ->
	?INFO(trade,"read: ~w",[[12204, Silver, Gold]]),
	{ok, [Silver, Gold]};

%% 物品从交易栏拖到背包
read(12205, <<BagPos:8, PanelPos:8>>) ->
	?INFO(trade,"read: ~w",[[12205, BagPos, PanelPos]]),
	{ok, [BagPos, PanelPos]};

%% 确认交易
read(12206, <<>>) ->
	?INFO(trade,"read: ~w",[12206]),
	{ok, []};

%% 取消交易
read(12207, <<>>) ->
	?INFO(trade,"read: ~w",[12207]),
	{ok, []};

%% 玩家钱币变动(已废除)
%% read(12208, <<Silver:32, Gold:32>>) ->
%% 	?INFO(trade,"read: ~w",[[12208, Silver, Gold]]),
%% 	{ok, [Silver, Gold]};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%									采集功能
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
read(12301,<<NPCID:32>>) ->
	?INFO(caixi,"read:~w",[[12301,NPCID]]),
	{ok, NPCID};


read(_Cmd, BinData) ->
	?ERR(items, "pt_12 read no match:~w", [BinData]),
    {error, no_match}.

readIDList(0, _) ->
	[];
readIDList(Size, <<WorldID:32, IDList/binary>>) ->
	RestIDList = readIDList(Size-1, IDList),
	[WorldID|RestIDList].
	
read_item_list(0, _NewBinData, ItemList) ->
	ItemList;

read_item_list(Size, <<BagPos:8, ItemNum:8, NewBinData/binary>>, ItemList) ->
	%BinData = <<BagPos:8, ItemNum:8, NewBinData/binary>>,
	NewItemList = [{BagPos, ItemNum}|ItemList],
	read_item_list(Size-1, NewBinData, NewItemList).

read_pos_list(0, _NewBinData, PosList) ->
	PosList;

read_pos_list(Size, <<BagPos:8, NewBinData/binary>>, PosList) ->
	NewPosList = [BagPos|PosList],
	read_pos_list(Size-1, NewBinData, NewPosList).
	





%%服务端 -> 客户端 ------------------------------------
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 三国项目物品模块 ----------------------------						%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 返回初始化数据包
write(12000, {BagType, CurrBagNum, ItemList}) ->
	?INFO(items,"SendData = ~w", [[12000, CurrBagNum, ItemList]]),
	case erlang:length(ItemList) of
		ListNum when ListNum =< 0 ->
			ListBin = <<>>;
		ListNum ->
			F = fun(Item) ->
						{_, WorldID} = Item#item.key,
						ItemID = Item#item.cfg_ItemID,
						BagPos = Item#item.gd_BagPos,
						RoleID = Item#item.gd_RoleID,
						StackNum = Item#item.gd_StackNum,
						IntLevel = Item#item.gd_IntensifyLevel,
						IsBind = Item#item.gd_IsBind,
						Quality = Item#item.gd_Quality,
						IsQiling = Item#item.gd_IsQiling,
						<<WorldID:32, ItemID:32, RoleID:32, BagPos:32, StackNum:32, IntLevel:32, IsBind:8,Quality:8,IsQiling:8>>
				end,
			ListBin = list_to_binary(lists:map(F, ItemList))
	end,
	{ok, pt:pack(12000, <<BagType:8, CurrBagNum:32, ListNum:16, ListBin/binary>>)};

%% 返回物品更新信息
write(12001, ItemList) ->
	?INFO(items, "SendData = ~w", [[12001, ItemList]]),
	case erlang:length(ItemList) of
		ListNum when ListNum =< 0 ->
			ListBin = <<>>;
		ListNum ->
			F = fun(Item) ->
						{_, WorldID} = Item#item.key,
						ItemID = Item#item.cfg_ItemID,
						BagType = Item#item.gd_BagType,
						BagPos = Item#item.gd_BagPos,
						RoleID = Item#item.gd_RoleID,
						StackNum = Item#item.gd_StackNum,
						IntLevel = Item#item.gd_IntensifyLevel,
						IsBind = Item#item.gd_IsBind,
						Quality = Item#item.gd_Quality,
						IsQiling = Item#item.gd_IsQiling,
						?INFO(items, "SendData = ~w", [[WorldID, ItemID, BagType, RoleID, BagPos, StackNum, IntLevel, IsBind,Quality,IsQiling]]),
						<<WorldID:32, ItemID:32, BagType:8, RoleID:32, BagPos:32, StackNum:32, IntLevel:32, IsBind:8,Quality:8,IsQiling:8>>
				end,
			ListBin = list_to_binary(lists:map(F, ItemList))
	end,
	{ok, pt:pack(12001, <<ListNum:16, ListBin/binary>>)};


write(12003, {BagType, CurrBagNum}) ->
	?INFO(items, "SendData = ~w", [[12003, BagType, CurrBagNum]]),
    {ok, pt:pack(12003, <<BagType:8, CurrBagNum:32>>)};


write(12008, {Item, FromType}) ->
	{AccountID, WorldID} = Item#item.key,
	BagType = Item#item.gd_BagType,
	ItemID = Item#item.cfg_ItemID,
	BagPos = Item#item.gd_BagPos,
	StackNum = Item#item.gd_StackNum,
	IntLevel = Item#item.gd_IntensifyLevel,
	% RemouldLevel = Item#item.gd_RemouldLevel,
	IsBind = Item#item.gd_IsBind,
	InlayInfo = Item#item.gd_InlayInfo,				
	% IdentifyInfo = Item#item.gd_IdentifyInfo,		
	XilianInfo = Item#item.gd_XilianInfo,			%% 洗练属性
	Quality = Item#item.gd_Quality,					%% 品质
	CfgItem = data_items:get(Item#item.cfg_ItemID),
	UpgrateLevel = CfgItem#cfg_item.cfg_RoleLevel,		%% 装备等级
	RoleID = Item#item.gd_RoleID,

	?INFO(items, "cfg_ItemID = ~w",[Item#item.cfg_ItemID]),
	case CfgItem#cfg_item.cfg_FirstType of
		?ITEM_TYPE_EQUIP ->
			HoleNum = data_items:get_equip_hole_num(IntLevel div 5);
		_ ->
			HoleNum = 0
	end,

	IsQiling = Item#item.gd_IsQiling,



	case erlang:length(InlayInfo) of
		InlayNum when InlayNum =< 0 ->
			InlayBin = <<>>;
		InlayNum ->
			F = fun({A, B}) ->
						<<A:8, B:32>>
				end,
			InlayBin = list_to_binary(lists:map(F, InlayInfo))
	end,
	
	% case erlang:length(IdentifyInfo) of
	% 	IdentifyNum when IdentifyNum =< 0 ->
	% 		IdentifyBin = <<>>;
	% 	IdentifyNum ->
	% 		F1 = fun({A1, B1}) ->
	% 					<<A1:8, B1:32>>
	% 			end,
	% 		IdentifyBin = list_to_binary(lists:map(F1, IdentifyInfo))
	% end,
	?INFO(items, "XilianInfo = ~w",[XilianInfo]),
	?INFO(items, "IntLevel = ~w",[IntLevel]),
	?INFO(items, "Base = ~w",[Item#item.gd_IntenRate]),
	?INFO(items, "Fail = ~w",[Item#item.gd_IntenFailRate]),
	case erlang:length(XilianInfo) of
		XilianNum when XilianNum =< 0 ->
			XilianBin = <<>>;
		XilianNum ->
			F1 = fun({A1, B1, C1}) ->
	 					<<A1:32, B1:8, C1:32>>
				end,
			XilianBin = list_to_binary(lists:map(F1, XilianInfo))
	end,
			
	?INFO(items,"SendData=~w", [[AccountID, BagType, WorldID, ItemID, BagPos, StackNum, HoleNum, IntLevel, IsBind, InlayNum, InlayInfo, XilianNum, XilianInfo]]),
%%     {ok, pt:pack(12008, <<AccountID:32, FromType:8, BagType:8, WorldID:32, ItemID:32, BagPos:32, StackNum:32, HoleNum:8, IntLevel:32, RemouldLevel:32, IsBind:8, InlayNum:16, InlayBin/binary, IdentifyNum:16, IdentifyBin/binary>>)};
	{ok, pt:pack(12008, <<FromType:8, BagType:8, WorldID:32, ItemID:32, UpgrateLevel:32, AccountID:32, IsBind:8, IntLevel:8, HoleNum:8, InlayNum:16, InlayBin/binary, XilianNum:16, XilianBin/binary, Quality:8, IsQiling:32, 0:8, StackNum:32, RoleID:32>>)};

%% ************************* 华丽的分隔线 ************************* %%
write(12006, {}) ->
	?INFO(items, "send_data:[~w]", [12006]),
    {ok, pt:pack(12006, <<>>)};

write(12007, {}) ->
	?INFO(items, "send_data:[~w]", [12007]),
    {ok, pt:pack(12007, <<>>)};

write(12009, {ColumnPos, WorldItemID}) ->
	?INFO(items, "send_data:[~w]", [[ColumnPos, WorldItemID]]),
	{ok, pt:pack(12009, <<ColumnPos:8, WorldItemID:32>>)};

write(12010, {BagPos, ColumnPos}) ->
	?INFO(items, "send_data:[~w]", [[BagPos, ColumnPos]]),
    {ok, pt:pack(12010, <<BagPos:8, ColumnPos:8>>)};

write(12012, {}) ->
	ok;

write(12016,{WordID, Type, Value1, Value2}) ->
	?INFO(items, "send_data:[~w]", [[WordID, Type, Value1, Value2]]),
    {ok, pt:pack(12016, <<WordID:32, Type:32, Value1:32, Value2:32>>)};

%% write(12013, {ItemInfo, ItemFrom}) ->
%% 	WorldItemID = ItemInfo#ets_gd_world_item.gd_world_item_id,
%% 	CfgItemID = ItemInfo#ets_gd_world_item.cfg_item_id,
%% 	?INFO(items, "WorldItemID=~w, CfgItemID=~w, ItemFrom=~w", [WorldItemID, CfgItemID, ItemFrom]),
%% 	{ok, pt:pack(12013, <<WorldItemID:32, CfgItemID:16, ItemFrom:8>>)};
%% 
%% write(12025, EndPosNum) ->
%%     {ok, pt:pack(12025, <<EndPosNum:8>>)};
%% 
%% write(12030, [ItemInfo, HoleNum, Type]) ->
%% 	AccountID = ItemInfo#ets_gd_world_item.gd_account_id,
%% 	BagRank = ItemInfo#ets_gd_world_item.gd_bag_rank,
%% 	ItemID = ItemInfo#ets_gd_world_item.gd_world_item_id,
%% 	CfgItemID = ItemInfo#ets_gd_world_item.cfg_item_id,
%% 	BagPos = ItemInfo#ets_gd_world_item.gd_bag_pos,
%% 	StackNum = ItemInfo#ets_gd_world_item.gd_stack_num,
%% 	IntensifyLevel = ItemInfo#ets_gd_world_item.gd_intensify_level,
%% 	TmpInlayList = ItemInfo#ets_gd_world_item.gd_inlay_info,
%% 	BindInfo = ItemInfo#ets_gd_world_item.gd_bind_info,
%% 	if
%% 		is_list(TmpInlayList) =:= false ->
%% 			InlayList = [];
%% 		true ->
%% 			InlayList = TmpInlayList
%% 	end,
%% 	Size = length(InlayList),
%% 	if
%% 		Size =:= 0 ->
%% 			ListBin = <<>>;
%% 		true ->
%% 			F = fun({A, B}) ->
%% 						<<A:8, B:16>>
%% 				end,
%% 			ListBin = list_to_binary(lists:map(F, InlayList))
%% 	end,
%% 	?INFO(items,"send_data=~w", [[InlayList, BagRank, ItemID, CfgItemID, BagPos, StackNum, HoleNum, IntensifyLevel, Size, ListBin]]),
%%     {ok, pt:pack(12030, <<BagRank:8, ItemID:32, CfgItemID:16, BagPos:8, StackNum:8, HoleNum:8, IntensifyLevel:32, Size:16, ListBin/binary, AccountID:32, Type:8, BindInfo:8>>)};

%%宝石系统 12040协议组
%% 宝石批量合成请求(12040) S->C
%% SMSG_JEWEL _COMBIN			= 12040			//宝石合成结果
%% Int16：宝石合成成功次数
%% Int32: 目标ID
write(12040, {Success_times, Target_id})->
	{ok,pt:pack(12040,<<Success_times:16, Target_id:32>>)};

%% 宝石转化结果(12041) S->C
%% SMSG_JEWEL _CONVERT			= 12041			//宝石转化结果
%% Int16: 宝石成功转化次数
%% Int32: 目标ID
write(12041, {Success_times, Target_id})->
	{ok,pt:pack(12041,<<Success_times:16, Target_id:32>>)};


%% 
%% 宝石雕刻(12042) S->C
%% SMSG_JEWEL_CARVE				= 12042		//宝石雕刻
%% Int16: 宝石成功雕刻次数
%% Int32: 目标ID
write(12042, {Success_times, Target_id})->
	{ok,pt:pack(12042,<<Success_times:16, Target_id:32>>)};


%% %% 装备更新
%% write(12050, EquipInfo) ->
%% 	MerID = EquipInfo#ets_gd_world_item.gd_role_id,
%% 	EquipPos  = EquipInfo#ets_gd_world_item.gd_bag_pos,
%% 	EquipID = EquipInfo#ets_gd_world_item.gd_world_item_id,
%% 	EquipModel = EquipInfo#ets_gd_world_item.cfg_item_id,
%% 	IntensifyLevel = EquipInfo#ets_gd_world_item.gd_intensify_level,
%% 	BindInfo = EquipInfo#ets_gd_world_item.gd_bind_info,
%% 	?INFO(items,"send data:~w", [[12050, MerID, EquipPos, EquipID, EquipModel, IntensifyLevel, BindInfo]]),
%% 	{ok, pt:pack(12050, <<MerID:16, EquipPos:8, EquipID:32, EquipModel:16, IntensifyLevel:8, BindInfo:8>>)};

write(12052, [Result, IsLevelJump]) ->
	?INFO(items, "send_data=~w", [[12052, Result, IsLevelJump]]),
	{ok, pt:pack(12052, <<Result:8, IsLevelJump:8>>)};

write(12053, Result) ->
	?INFO(items,"send_data=~w", [[12053, Result]]),
	{ok, pt:pack(12053, <<Result:8>>)};

write(12054, [IntensifyRate, NextState]) ->
	?INFO(items,"send_data=~w", [[12054, IntensifyRate, NextState]]),
	{ok, pt:pack(12054, <<IntensifyRate:8, NextState:8>>)};

write(12056, NewRingID) ->
	?INFO(items, "send_data=~w", [[12056, NewRingID]]),
	{ok, pt:pack(12056, <<NewRingID:32>>)};

write(12063,{Type, ItemID, MonsterID, Gold, BindGold, Silver}) ->
	{ok, pt:pack(12063,<<Type:8,ItemID:32, MonsterID:32, Gold:32, BindGold:32, Silver:32>>)};

%%=============================================================================
%% 炼金系统
%%=============================================================================
write(12100, {NewXunxianInfo,FromType}) ->
	ImmortalPos = NewXunxianInfo#xunxian.gd_ImmortalPos,
	ItemList = NewXunxianInfo#xunxian.gd_ItemList,
	FreeTimes = NewXunxianInfo#xunxian.gd_FreeTimes,
	?INFO(xunxian, "FreeTimes = ~w, ImmortalPos = ~w, ItemList = ~w.", [FreeTimes, ImmortalPos, ItemList]),
	case length(ItemList) of
		0 ->
			ItemNum = 0,
			ListBin = <<>>;
		ItemNum ->
			F = fun({CfgID, BindInfo}) ->
						<<CfgID:32, BindInfo:8>>
				end,
			ListBin = list_to_binary(lists:map(F, ItemList))
		end,
	?INFO(xunxian,"send_data: ~w",[[12100, FreeTimes, ImmortalPos, ListBin,FromType]]),
	{ok, pt:pack(12100, <<FreeTimes:32, ImmortalPos:32, ItemNum:16, ListBin/binary,FromType:8>>)};

write(12101, {CfgItemID, ItemType, BindInfo}) ->
	?INFO(xunxian,"send_data: ~w",[[12101, CfgItemID, ItemType, BindInfo]]),
	{ok, pt:pack(12101, <<CfgItemID:16, ItemType:8, BindInfo:8>>)};

write(12102, ItemList) ->
	?INFO(xunxian,"send_data: ~w",[[12102, ItemList]]),
	case length(ItemList) of
		0 ->
			ItemNum = 0,
			ListBin = <<>>;
		ItemNum ->
			F = fun({I, T, _N, B}) ->
						<<I:16, T:8, B:8>>
				end,
			ListBin = list_to_binary(lists:map(F, ItemList))
	end,
	?INFO(xunxian,"send_data: ~w",[[12102, ItemNum, ListBin]]),
	{ok, pt:pack(12102, <<ItemNum:16, ListBin/binary>>)};

write(12103, {CfgItemID, BindInfo, Index}) ->
	?INFO(xunxian,"send_data: ~w",[[12103, CfgItemID, BindInfo, Index]]),
	{ok, pt:pack(12103, <<CfgItemID:16, BindInfo:8, Index:8>>)};

write(12104, {PosList, ItemList, LastPos, IsSilverEnough,IsBagEnough}) ->
	?INFO(xunxian,"send_data: ~w",[[12104, PosList, ItemList, LastPos, IsSilverEnough,IsBagEnough]]),
	case length(PosList) of
		0 ->
			PosNum = 0,
			PosListBin = <<>>;
		PosNum ->
			F1 = fun(Pos) ->
						<<Pos:8>>
				end,
			PosListBin = list_to_binary(lists:map(F1, PosList))
		end,
	case length(ItemList) of
		0 ->
			ItemNum = 0,
			ListBin = <<>>;
		ItemNum ->
			F = fun({CfgID, BindInfo}) ->
						<<CfgID:32, BindInfo:8>>
				end,
			ListBin = list_to_binary(lists:map(F, ItemList))
		end,
	{ok, pt:pack(12104, <<PosNum:16, PosListBin/binary, ItemNum:16, ListBin/binary, LastPos:8, IsSilverEnough:8,IsBagEnough:8>>)};

write(12107, {ItemList, FreeTime, CoinType}) ->
	case length(ItemList) of
		0 ->
			ItemNum = 0,
			ListBin = <<>>;
		ItemNum ->
			F = fun({I, T, B, L1, L2, L3, L4, L5}) ->
						<<I:16, T:8, B:8, L1:8, L2:8, L3:8, L4:8, L5:8>>
				end,
			ListBin = list_to_binary(lists:map(F, ItemList))
	end,
	?INFO(xunxian,"send_data: ~w",[[12107, ItemList, FreeTime, CoinType]]),
	{ok, pt:pack(12107, <<ItemNum:16, ListBin/binary, FreeTime:8, CoinType:8>>)};
%%=============================================================================
%% 炼金系统 end
%%=============================================================================

%%=============================================================================
%% 交易系统
%%=============================================================================
%% 交易申请
write(12200, {AccountID, NickName, Level, RoleID}) ->
	?INFO(trade,"send_data: ~w",[[12200, AccountID, NickName, Level, RoleID]]),
	BinName = pt:write_string(NickName),
	{ok, pt:pack(12200, <<AccountID:32, Level:8, BinName/binary, RoleID:8>>)};

%% 接受交易
write(12201, {AccountID, NickName, Level, RoleID}) ->
	?INFO(trade,"send_data: ~w",[[12201, AccountID, NickName, Level, RoleID]]),
	BinName = pt:write_string(NickName),
	{ok, pt:pack(12201, <<AccountID:32, Level:8, BinName/binary, RoleID:8>>)};

%% 拒绝交易
write(12202, {AccountID, NickName, Level, RoleID}) ->
	?INFO(trade,"send_data: ~w",[[12202, AccountID, NickName, Level, RoleID]]),
	BinName = pt:write_string(NickName),
	{ok, pt:pack(12202, <<AccountID:32, Level:8, BinName/binary, RoleID:8>>)};

%% 物品从背包拖到交易栏
write(12203, {Type, PanelPos, WorldItemID, CfgItemID, StackNum, IntensifyLevel, BindInfo}) ->
	?INFO(trade,"send_data: ~w",[[12203, Type, PanelPos, WorldItemID, CfgItemID, StackNum, IntensifyLevel, BindInfo]]),
	{ok, pt:pack(12203, <<Type:8, PanelPos:8, WorldItemID:32, CfgItemID:16, StackNum:8, IntensifyLevel:8, BindInfo:8>>)};

%% 锁定交易栏
write(12204, {Status, OtherStatus}) ->
	?INFO(trade,"send_data: ~w",[[12204, Status, OtherStatus]]),
	{ok, pt:pack(12204, <<Status:8, OtherStatus:8>>)};

%% 物品从交易栏拖到背包
write(12205, {Type, BagPos, PanelPos}) ->
	?INFO(trade,"send_data: ~w",[[12205, Type, BagPos, PanelPos]]),
	{ok, pt:pack(12205, <<Type:8, BagPos:8, PanelPos:8>>)};

%% 确认交易
write(12206, {}) ->
	?INFO(trade,"send_data: ~w",[12206]),
	{ok, pt:pack(12206, <<>>)};

%% 取消交易
write(12207, {}) ->
	?INFO(trade,"send_data: ~w",[12207]),
	{ok, pt:pack(12207, <<>>)};

%% 玩家钱币变动
write(12208, {Status, OtherStatus, Silver, Gold}) ->
	?INFO(trade,"read: ~w",[[12208, Status, OtherStatus, Silver, Gold]]),
	{ok, pt:pack(12208, <<Status:8, OtherStatus:8, Silver:32, Gold:32>>)};

write(99999, RetCode) ->
    {ok, pt:pack(40000, <<RetCode:8>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
