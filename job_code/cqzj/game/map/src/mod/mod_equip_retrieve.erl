%% Author: xierf
%% Created: 2012-6-21
%% Description: 装备回收
-module(mod_equip_retrieve).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([start/4, handle/2]).

%%
%% API Functions
%%
start(RoleID, ItemTypeID, Msg, LogType) when RoleID > 0, ItemTypeID > 0 ->
	case common_misc:is_role_online(RoleID) of
	true ->
		common_misc:send_to_rolemap(RoleID, {mod, ?MODULE,{retrieve_equip_online, RoleID, ItemTypeID, LogType}}),
		common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_CENTER, Msg);
	false ->
		retrieve_equip_offline(RoleID, ItemTypeID, LogType)
	end;

start(_RoleID, _ItemTypeID, _Msg, _LogType) ->
	ignore.

handle({retrieve_equip_online, RoleID, ItemTypeID, LogType}, _State) ->
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	case common_transaction:t(
		   fun() ->
				   t_retrieve_equip(ItemTypeID, RoleID, RoleAttr)
		   end) of
	{atomic, {ok,_UpdateGoodsList,DeleteGoodsList}} ->
		common_item_logger:log(RoleID, ItemTypeID, 1, undefined, LogType),
		common_misc:del_goods_notify({role, RoleID}, DeleteGoodsList);
	{atomic, {ok, Equip}} ->
		common_misc:notify_del_equip(RoleID, Equip#p_goods.loadposition),
		mod_role_equip:update_role_base(RoleID, '-', Equip),
		common_item_logger:log(RoleID, ItemTypeID, 1, undefined, LogType);
	{aborted, {bag_error, num_not_enough}} ->
		ignore;
	{aborted, {bag_error, Reason}} ->
		?ERROR_MSG("收回装备错误，{bag_error,RoleID=~w,ItemTypeID=~w,Reason=~w}",[RoleID, ItemTypeID, Reason]);
	{aborted, Error} ->
		?ERROR_MSG("收回装备错误，{aborted,RoleID=~w,ItemTypeID=~w,Reason=~w}",[RoleID, ItemTypeID, Error])
	end.


%%
%% Local Functions
%%
retrieve_equip_offline(RoleID, ItemTypeID, LogType) ->
	%%得到玩家拥有的背包ID
	BagList = case db:dirty_read(?DB_ROLE_BAG_BASIC_P, RoleID) of
			  {'EXIT', Reason} ->
				  ?ERROR_MSG("~ts,Reason=~w", ["收回装备时脏读玩家背包信息出错",Reason]),
				  [];
			  [] ->
				  ?ERROR_MSG("~ts,RoleId=~w", ["收回装备时脏读玩家背包信息为空",RoleID]),
				  [];
			  [BagInfoRecord] ->
				  #r_role_bag_basic{bag_basic_list = BagInfoListT} = BagInfoRecord,
				  [element(1,BagInfo)||BagInfo<-BagInfoListT]
			  end,
	lists:foreach(fun(BagId) ->
						  RoleBagKey = {RoleID, BagId},
						  case db:dirty_read(?DB_ROLE_BAG_P, RoleBagKey) of
						  {'EXIT', Reason2} ->
							  ?ERROR_MSG("~ts,RoleId=~w,BagId=~w,Reason=~w", 
										 ["收回装备时脏读玩家背包物品信息出错",RoleID,BagId,Reason2]),
							  ignore;
						  [] ->
							  ignore;
						  [RoleBagRecord] ->
							  #r_role_bag{bag_goods = GoodsList} = RoleBagRecord,
							  NewGoodsList = lists:keydelete(ItemTypeID,#p_goods.typeid,GoodsList),
							  case GoodsList =/= NewGoodsList of
							  true ->
								  NewRoleBagRecord = RoleBagRecord#r_role_bag{bag_goods = NewGoodsList},
								  db:dirty_write(?DB_ROLE_BAG_P, NewRoleBagRecord);
							  false ->
								  ignore
							  end
						  end
				  end,BagList),
	[RoleAttr] = db:dirty_read(?DB_ROLE_ATTR, RoleID),
	#p_role_attr{equips=Equips} = RoleAttr,
	case lists:keytake(ItemTypeID, #p_goods.typeid, Equips) of
		{value, RetrieveEquip, Equips2} ->
			[RoleBase] = db:diryt_read(?DB_ROLE_BASE, RoleID),
			RoleBase2  = mod_role_equip:calc(RoleBase, '-', RetrieveEquip),
			RoleAttr2  = RoleAttr#p_role_attr{equips=Equips2},
			db:dirty_write(?DB_ROLE_BASE, RoleBase2),
			db:dirty_write(?DB_ROLE_ATTR, RoleAttr2);
		false ->
			ignore
	end,
	common_item_logger:log(RoleID, ItemTypeID, 1, undefined, LogType).

t_retrieve_equip(ItemTypeID, RoleID, RoleAttr) ->
	case mod_goods:get_equip_by_typeid(RoleID, ItemTypeID) of
	{error, equip_not_found} ->
		mod_bag:decrease_goods_by_typeid(RoleID,[1,2,3,5,6,7,8,9],ItemTypeID,1);
	{ok, UnloadInfo} ->
		{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
		Equips = RoleAttr#p_role_attr.equips,
		Equips2 = lists:keydelete(ItemTypeID, #p_goods.typeid, Equips),
		case Equips2 =/= Equips of
		true ->
			RoleAttr2 = RoleAttr#p_role_attr{equips=Equips2},
			mod_map_role:set_role_attr(RoleID, RoleAttr2),
			{ok, UnloadInfo};
		false ->
			ignore
		end
	end.

