%%% -------------------------------------------------------------------
%%% Author  : fangshaokong
%%% Description : 官职装备
%%%
%%% Created : 2011-3-9
%%% -------------------------------------------------------------------
-module(mod_map_office).

-include("mgeem.hrl").
-include("office.hrl").

-export([handle/2]).

handle(Info, State) ->
    do_handle(Info, State).

do_handle({take_equip, RoleID, TakeOfficeID, TakeNum, Unique, Module, Method, PID}, _State) ->
    ItemTypeID = ?OFFICE_EQUIP(TakeOfficeID),
    Result = case check_has_good_by_typeid(RoleID,ItemTypeID) of
                 false ->
                     case mod_equip:get_equip_baseinfo(ItemTypeID) of
                         error ->
                             ?_LANG_STALL_GOODS_NOT_EXIST;
                         {ok,_BaseInfo} ->
                             IsBind = true,
                             case db:transaction(
                                    fun() ->
                                            CreateInfo = #r_goods_create_info{bind=IsBind, type=?TYPE_EQUIP, type_id=ItemTypeID, num=TakeNum},
                                            mod_bag:create_goods(RoleID,CreateInfo)
                                    end)
                             of 
                                 {aborted, Reason} when is_binary(Reason) ->
                                     Reason;
                                 {aborted,{bag_error,{not_enough_pos,_BagID}}} ->
                                     ?_LANG_GOODS_BAG_NOT_ENOUGH;
                                 {aborted, Reason} ->
                                     Reason;
                                 {atomic, {ok,GoodsInfoList}} ->
                                     common_item_logger:log(RoleID,ItemTypeID,TakeNum,IsBind,?LOG_ITEM_TYPE_TAKE_OFFICE_EQUIP),
                                     common_misc:update_goods_notify({role, RoleID}, GoodsInfoList),
                                     ok
                             end
                     end;
                 true ->
                     ?_LANG_OFFICE_ALREADY_TAKE_OFFICE_EQUIP
             end,
    DataRecord = case Result of
                     ok ->
                         #m_office_take_equip_toc{};
                     Error ->
                         #m_office_take_equip_toc{succ=false,reason=Error}
                 end,
    common_misc:unicast2(PID,Unique,Module,Method,DataRecord);

do_handle({retrieve_office_equip, RoleID, OfficeID}, _State) ->
    ItemTypeID = ?OFFICE_EQUIP(OfficeID),
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    case common_transaction:transaction(fun() ->
                                                t_retrieve_office_equipp(ItemTypeID, RoleID, RoleAttr)
                                        end) of
        {atomic, {ok,_UpdateGoodsList,DeleteGoodsList}} ->
            common_item_logger:log(RoleID, ItemTypeID, 1, undefined,?LOG_ITEM_TYPE_RETRIEVE_OFFICE_EQUIP),
            %%TODO 仓库无法实时清除
            %% 			lists:foreach(fun(Goods) ->
            %% 								  del_depot_goods_notify(RoleID, Goods#p_goods.id)
            %% 						  end,DeleteGoodsList),
            common_misc:del_goods_notify({role, RoleID}, DeleteGoodsList);
        {atomic, {ok, UnloadEquip}} ->
            common_misc:notify_del_equip(RoleID, UnloadEquip#p_goods.loadposition),
            {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
            NewRoleBase    = mod_role_equip:calc(RoleBase, '-', UnloadEquip),
            mod_role_attr:reload_role_base(NewRoleBase),
            common_item_logger:log(RoleID, ItemTypeID, 1, undefined,?LOG_ITEM_TYPE_RETRIEVE_OFFICE_EQUIP);
        {aborted, {bag_error, num_not_enough}} ->
            %%玩家身上没有这个官印
            ignore;
        {aborted, {bag_error, Reason}} ->
            ?ERROR_MSG("收回官印错误，{bag_error,RoleID=~w,OfficeID=~w,Reason=~w}",[RoleID, OfficeID, Reason]);
        {aborted, Error} ->
            ?ERROR_MSG("收回官印错误，{aborted,RoleID=~w,OfficeID=~w,Reason=~w}",[RoleID, OfficeID, Error])
    end.

t_retrieve_office_equipp(ItemTypeID, RoleID, RoleAttr) ->
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

%% del_depot_goods_notify(RoleID, GoodID) ->
%% 	?ERROR_MSG("GoodID:~p",[GoodID]),
%% 	DataRecord = #m_depot_destroy_toc{succ = true,id = GoodID},
%% 	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?DEPOT, ?DEPOT_DESTROY, DataRecord).

%% @doc 检查玩家是否拥有某一类型物品，包括所有位置：背包、仓库、身上 
check_has_good_by_typeid(RoleID,TypeID) ->
    case mod_bag:get_goods_by_typeid(RoleID,TypeID,[1,2,3,5,6,7,8,9]) of
        {ok, []} ->
            case mod_goods:get_equip_by_typeid(RoleID, TypeID) of
                {error, equip_not_found} ->
                    false;
                {ok, _UnloadInfo} ->
                    true
            end;
        {ok, _Find} ->
            true
    end.
