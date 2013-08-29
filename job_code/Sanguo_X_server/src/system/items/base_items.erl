%% Author: Administrator
%% Created: 2012-6-20
%% Description: 提供物品其他模块调用的内部接口
-module(base_items).

%%
%% Include files
%%
-include("common.hrl").
%%
%% Exported Functions
%%
-export([fillItems/1, getExpandCost/3,stackItems/1]).

%%
%% API Functions
%%



%%
%% Local Functions
%%
fillItems(ItemList) ->
	?INFO(items, "ItemList=~w", [ItemList]),
	F = fun({ItemID, ItemNum, IsBind}, {B, L}) ->
					  case IsBind =:= B of
						  false ->
							  {B, L};
						  true ->
							  case lists:keyfind(ItemID, 1, L) of
								  false ->
									  {B, [{ItemID, ItemNum, IsBind}|L]};
								  {ItemID, SumNum, IsBind} ->
									  {B, lists:keyreplace(ItemID, 1, L, {ItemID, SumNum+ItemNum, IsBind})}
							  end
					  end
			  end,
	{_, BindList} = lists:foldl(F, {?ITEM_BIND_Y, []}, ItemList),
	?INFO(items, "BindList=~w", [BindList]),
	{_, FreeList} = lists:foldl(F, {?ITEM_BIND_N, []}, ItemList),
	?INFO(items, "BindList=~w, FreeList=~w", [BindList, FreeList]),
	NewBindList = stackItems(BindList),
	NewFreeList = stackItems(FreeList),
	NewBindList ++ NewFreeList.

stackItems([]) ->
	[];
stackItems([{ItemID, ItemNum, IsBind}|ItemList]) ->
	CfgItem = data_items:get(ItemID),
	StackMax = CfgItem#cfg_item.cfg_StackMax,
	case ItemNum - StackMax of
		NewItemNum when NewItemNum =< 0 ->
			RestItemList = stackItems(ItemList),
			[{ItemID, ItemNum, IsBind}|RestItemList];
		NewItemNum ->
			RestItemList = stackItems([{ItemID, NewItemNum, IsBind}|ItemList]),
			[{ItemID, StackMax, IsBind}|RestItemList]
	end.

getExpandCost(_BagType, BeginPos, EndPos) when EndPos < BeginPos ->
	0;
getExpandCost(BagType, BeginPos, EndPos) ->
	{0, InterGold, MaxGold} = data_items:get_extend(BagType),
	MaxPos = 30,
	ExtendGold = min((BeginPos - MaxPos) * InterGold, MaxGold),
	RestExtendGold = getExpandCost(BagType, BeginPos+1, EndPos),
	ExtendGold + RestExtendGold.

%% 装备强化附加价格（不含基础价格）
%% getIntenCost(IntenLevel, EquipAttr, IntensifyInfo)
%% 	IntensifyAttr = get_intensify_attr(IntenLevel-1, IntensifyInfo#intensify_info.add_attr),
%% 	[_, _, _, _, Speed, _, _, _, _, _, _, _, _, PDef, MDef, PAtt, MAtt] = util:list_add(EquipAttr, IntensifyAttr),
%% 	if
%% 		IntensifyInfo#intensify_info.type =:= ?EQUIP_TYPE_WEAPON ->
%% 			if
%% 				(IntensifyInfo#intensify_info.career =:= ?CAREER_MILITANT) orelse (IntensifyInfo#intensify_info.career =:= ?CAREER_FIGHTER) ->
%% 					CurrAttr = PAtt;
%% 				true ->
%% 					CurrAttr = MAtt
%% 			end;
%% 		IntensifyInfo#intensify_info.type =:= ?EQUIP_TYPE_ARMORS ->
%% 			CurrAttr = PDef;
%% 		IntensifyInfo#intensify_info.type =:= ?EQUIP_TYPE_CLOAK ->
%% 			CurrAttr = MDef;
%% 		true ->
%% 			CurrAttr = Speed
%% 	end,
%% 	?INFO(items, "BaseCost=~w, CurrAttr=~w, IntenLevel=~w, Ratio=~w", [IntensifyInfo#intensify_info.base_cost, CurrAttr, IntenLevel, IntensifyInfo#intensify_info.cost_ratio]),
%% 	util:ceil(IntensifyInfo#intensify_info.base_cost + CurrAttr*(IntenLevel+1)*IntenLevel*IntensifyInfo#intensify_info.cost_ratio).
