-module(pp_item).

-export([handle/3]).

-include("common.hrl").

handle(12000, AccountID, {BagType, _RoleID}) ->
	case BagType of
		1 ->
			mod_items:getBagItems(AccountID);
		2 ->
			mod_items:getBankItems(AccountID)
	end;

%% 物品移动
handle(12001, AccountID, {WorldID, BagType, RoleID, BagPos}) ->
	case RoleID > 0 of
		false ->
			mod_items:moveItem(AccountID, WorldID, BagType, BagPos);
		true ->
			case BagType =:= 3 of
				true ->
					mod_items:equipItem(AccountID, WorldID, BagType, RoleID);
				false ->
					mod_items:unequipItem(AccountID, WorldID, BagType)
			end
	end;


handle(12002, AccountID, BagType) ->
	mod_items:cleanItems(AccountID, BagType);

handle(12003, AccountID, {BagType, BagPos}) ->
	mod_items:expandVolume(AccountID, BagType, BagPos);

handle(12004, AccountID, {BagType, RoleID, WorldID, UseNum}) ->
	mod_items:useNumByWorldID(AccountID, BagType, RoleID, WorldID, UseNum);

handle(12005, AccountID, {BagType, WorldID}) ->
	mod_items:throwByWorldID(AccountID, BagType, WorldID);

handle(12006, AccountID, {NPCID, WorldIDList}) ->
	mod_items:sellItems(AccountID, NPCID, WorldIDList);

handle(12007, AccountID, {NPCID, ItemID, ItemNum}) ->
	mod_items:buyItem(AccountID, NPCID, ItemID, ItemNum);

handle(12008, AccountID, {ItemAccountID, WorldID, FromMode}) ->
	mod_items:getItem(AccountID, ItemAccountID, WorldID, FromMode);

handle(12009, AccountID, {WorldID, SplitNum}) ->
	mod_items:splitItem(AccountID, WorldID, SplitNum);

handle(12010,AccountID, {WorldID, IsLock,FromType}) ->
	mod_items:intenItem(AccountID,WorldID,IsLock,FromType);

handle(12011, AccountID, {WorldItemID,FromType}) ->
	mod_items:qilingItem(AccountID,WorldItemID,FromType);

handle(12012,AccountID, {WorldID, LockIdList, FromMode}) ->
	mod_items:xilianItem(AccountID, WorldID, LockIdList, FromMode);

handle(12013,AccountID,{WorldItemID,Star}) ->
	mod_items:lockXilianStar(AccountID,WorldItemID,Star);

handle(12014,AccountID,{WorldItemID,IsPerfect,FromType}) ->
	mod_items:upgrateItem(AccountID,WorldItemID,IsPerfect,FromType);

handle(12015,AccountID,{WorldItemID,FromType}) ->
	mod_items:upItemQuality(AccountID,WorldItemID,FromType);

handle(12016,AccountID,{WorldID, Type}) ->
	case Type of
		1 ->
			mod_items:getXilianStar(AccountID, WorldID);
		2 ->
			mod_items:getIntenRate(AccountID, WorldID);
		_Else ->
			ok
	end;

handle(12017,AccountID,{WorldID, AddRate}) ->
	mod_items:addIntenRate(AccountID, WorldID, AddRate);

handle(12018,AccountID,{WorldID, JewelWorldID, Pos, FromType})->
	mod_items:inlayJewel(AccountID,WorldID,JewelWorldID,Pos,FromType);

handle(12019,AccountID,{WorldID, Pos, FromType}) ->
	mod_items:backoutJewel(AccountID, WorldID, Pos, FromType);


%%宝石系统
%%handle 宝石合成
handle(12040,AccountID,{Cfg_item_id, Type, Num}) ->
	?INFO(item,"cfg_id:~w,type:~w,Num:~w",[Cfg_item_id, Type, Num]),
	mod_items:compose_stone(AccountID,Cfg_item_id, Type, Num);

%%handle 宝石转化
handle(12041,AccountID,{From_cfg_item_id,To_cfg_item_id, Type, Num}) ->
	mod_items:convert_stone(AccountID, From_cfg_item_id, To_cfg_item_id, Type, Num);

%%宝石雕刻
handle(12042,AccountID,{Cfg_item_id, Type, Num}) ->
	mod_items:carve_stone(AccountID, Cfg_item_id, Type, Num);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%							寻仙系统											  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 寻仙信息请求
handle(12100, AccountID, _Data) ->
	mod_xunxian:getXunxianInfo(AccountID);

%% 寻仙一次
handle(12101, AccountID, _Data) ->
	mod_xunxian:smelt(AccountID);

%% 拾起一个物品
handle(12102, AccountID, {ItemPos}) ->
	mod_xunxian:pickOne(AccountID, ItemPos);

%% 卖出一个物品
handle(12103,AccountID,{ItemPos}) ->
	mod_xunxian:sellOne(AccountID, ItemPos);

%% 一键寻仙
handle(12104, AccountID, {Silver}) ->
	mod_xunxian:onekeySmelt(AccountID, Silver);

%% 一键拾起
handle(12105, AccountID, _Data) ->
	mod_xunxian:pickAll(AccountID);

%% 一键卖出
handle(12106, AccountID, _Data) ->
	mod_xunxian:sellAll(AccountID);

%% 锁定最高仙人位置
handle(12107, AccountID, _Data) ->
	mod_xunxian:lock(AccountID);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  							采集功能
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
handle(12301,AccountID,NPCID) ->
	mod_items:collect(AccountID,NPCID);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
handle(Cmd, _PlayerId, _) ->
	?ERR(items, "items protocal ~w not implemented", [Cmd]).

