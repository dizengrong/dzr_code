-module(mod_depot).

-include("mgeem.hrl").

-define(DICT_DEPOT_LIST, dict_key_depot_list).

-export([handle/1]).

handle({_, ?DEPOT, ?DEPOT_GET_GOODS, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_depot_get_goods_tos)->
    do_get_goods(Msg);
handle({_, ?DEPOT, ?DEPOT_DREDGE, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_depot_dredge_tos)->
    do_dredge_depot(Msg);
handle({_, ?DEPOT, ?DEPOT_DESTROY, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_depot_destroy_tos)->
    do_destroy(Msg);
handle({_, ?DEPOT, ?DEPOT_SWAP, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_depot_swap_tos)->
    do_swap(Msg);
handle({_, ?DEPOT, ?DEPOT_DIVIDE, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_depot_divide_tos)->
    do_divide(Msg);
handle({_, ?DEPOT, ?DEPOT_TIDY, DataIn, _, _, _, _}=Msg)
  when is_record(DataIn, m_depot_tidy_tos) ->
    do_tidy(Msg).

%%获取仓库信息---------------------------------------------------------------------------------
do_get_goods({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_depot_get_goods_tos{depot_id=DepotID} = DataIn,
    %%npc判断
    {ok,{role_depository_list,_IDList},GoodsList} = mod_bag:get_role_depot_info(RoleID),
    ?INFO_MSG("IDList:~w GoodsList: ~w~n",[_IDList,GoodsList]),
    Depots = 
        lists:foldl(
          fun(BagID,AccDepots) ->
                  case lists:keyfind(BagID,2,GoodsList) of
                      false ->
                          AccDepots;
                      {role_bag,BagID,List} ->
                          [#p_depot_bag{bagid=BagID,goods_list=List}|AccDepots]
                  end
          end,[],[DepotID]),
    common_misc:unicast(Line, RoleID, Unique, Module, Method, #m_depot_get_goods_toc{depots=Depots, depot_num=erlang:length(GoodsList)}).

%%开通仓库-------------------------------------------------------------------------------------
do_dredge_depot({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State})->
    #m_depot_dredge_tos{bagid=BagID}=DataIn,
    {ok,{role_depository_list,_IDList},GoodsList} = mod_bag:get_role_depot_info(RoleID),
    Data = 
        try
            case BagID > 6 andalso BagID < 10 of
                true ->
                    next;
                false ->
                    erlang:throw(?_LANG_DEPOT_NOT_CAN_OPENED)
            end,
            case lists:keymember(BagID-1,2,GoodsList) of
                true ->
                    next;
                false ->
                    erlang:throw(?_LANG_DEPOT_NOT_CAN_LEAPFROG_DREDGE)
            end,
            case lists:keymember(BagID,2,GoodsList) of
                false ->
                    next;
                true ->
                    erlang:throw(?_LANG_DEPOT_HAS_BEEN_OPENED)
            end,
            RoleAttr = do_dredge_depot2(BagID, RoleID),
            ?DEBUG("NewRoleInfo:~w~n",[RoleAttr]),
            P1 = #p_role_attr_change{change_type=6,new_value=RoleAttr#p_role_attr.silver},
            P2 = #p_role_attr_change{change_type=7,new_value=RoleAttr#p_role_attr.silver_bind},
            RC = #m_role2_attr_change_toc{roleid=RoleID,changes=[P1,P2]},
            common_misc:unicast(Line, RoleID, ?DEFAULT_UNIQUE,?ROLE2,?ROLE2_ATTR_CHANGE,RC),
            #m_depot_dredge_toc{succ=true,bagid=BagID}
        catch
            _:R when is_binary(R) ->
                #m_depot_dredge_toc{succ = false,reason = R};
            _:R ->
                ?ERROR_MSG("~ts:~w~n",["开通仓库失败",R]),
                #m_depot_dredge_toc{succ = false,reason = ?_LANG_SYSTEM_ERROR}
        end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, Data).


do_dredge_depot2(BagID, RoleID) ->
    case db:transaction(
           fun()->
                   {ok, RoleInfo} = mod_map_role:get_role_attr(RoleID),
                   %% VIP3以上就免费开通
                   VipLevel = mod_vip:get_role_vip_level(RoleID),
                   [RemoteDepotMinLevel] = common_config_dyn:find(vip, remote_depot_min_level),
                   case VipLevel >= RemoteDepotMinLevel of
                       true ->
                           NewRoleInfo = RoleInfo;
                       _ ->
                           NewRoleInfo = t_cut_dredge_moeny(BagID,RoleInfo)
                   end,
                   mod_map_role:set_role_attr(RoleID, NewRoleInfo),
                   mod_bag:create_bag(RoleID,{BagID,0,0,?PER_DEPOT_GRID_ROWS,?PER_DEPOT_GRIE_CLOWNS,?PER_DEPOT_GRID_NUMBER}),
                   [BagBasicInfo]= db:read(?DB_ROLE_BAG_BASIC_P,RoleID),
                   #r_role_bag_basic{bag_basic_list=BagBasicList} = BagBasicInfo,
                   NewBagBasicInfo = BagBasicInfo#r_role_bag_basic{bag_basic_list=[{BagID,0,0,?PER_DEPOT_GRID_ROWS,?PER_DEPOT_GRIE_CLOWNS,?PER_DEPOT_GRID_NUMBER}|BagBasicList]},
                   db:write(?DB_ROLE_BAG_BASIC_P,NewBagBasicInfo,write),
                   common_consume_logger:use_silver({RoleID, 
                                                     RoleInfo#p_role_attr.silver_bind-
                                                         NewRoleInfo#p_role_attr.silver_bind,
                                                     RoleInfo#p_role_attr.silver-
                                                         NewRoleInfo#p_role_attr.silver,
                                                     ?CONSUME_TYPE_SILVER_DEPOT,
                                                     ""}),
                   NewRoleInfo
           end)
    of
        {aborted, Reason} ->
            erlang:throw(Reason);
        {atomic, NewRoleInfo} ->
            %% 完成成就
            mod_achievement2:achievement_update_event(RoleID, 41002, 1),
            NewRoleInfo
    end.

t_cut_dredge_moeny(7,RoleInfo) ->
    t_cut_dredge_moeny2(1000,RoleInfo);
t_cut_dredge_moeny(8,RoleInfo) ->
    t_cut_dredge_moeny2(10000,RoleInfo);
t_cut_dredge_moeny(9,RoleInfo) ->
    t_cut_dredge_moeny2(100000,RoleInfo).

t_cut_dredge_moeny2(Price,RoleInfo) ->
    #p_role_attr{silver=Silver,silver_bind=SilverBind}=RoleInfo,
    case SilverBind - Price  of
        R1 when R1 < 0  -> 
            case Silver - abs(R1) of
                R2 when R2 < 0 ->
                    db:abort(?_LANG_DEPOT_NOT_MOENY);
                R2 ->
                    RoleInfo#p_role_attr{silver=R2,silver_bind=0}
            end;
        R1 ->
            RoleInfo#p_role_attr{silver_bind= R1}
    end.

%%摧毁物品-------------------------------------------------------------------------------------
do_destroy({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_depot_destroy_tos{id = GoodsID} = DataIn,
    ?INFO_MSG("GoodsID:~w~n",[GoodsID]),
    case db:transaction(fun() -> delete_goods(RoleID, GoodsID) end) of
        {aborted, Reason} when is_binary(Reason)->
            R = #m_depot_destroy_toc{succ = false,reason = Reason};
        {aborted, Error} ->
            ?DEBUG("destroy_goods transaction fail, reason = ~w~n", [Error]),
            Reason = 
                case Error of
                    {throw,goods_can_not_drop} ->
                        ?_LANG_ITEM_CAN_NOT_DROP;
                    _ ->
                        ?_LANG_SYSTEM_ERROR
                end,
            R = #m_depot_destroy_toc{succ = false,reason = Reason};
        {atomic, {ok,Goods}} ->
            %% add by caochuncheng 玩家商贸商票销毁处理
            catch mod_trading:hook_drop_trading_bill_item(RoleID,Goods#p_goods.typeid),
            destroy_goods_log([Goods]),
            R = #m_depot_destroy_toc{succ = true,id = Goods#p_goods.id}

    end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

delete_goods(RoleID,GoodsID) ->
    case mod_bag:check_indepot_by_id(RoleID, GoodsID) of
        {error,goods_not_found} ->
            throw(goods_not_found);
        {ok,GoodsInfoT} ->
            [CanNotDropList] = common_config_dyn:find(item_special, can_not_drop_list),
            case lists:member(GoodsInfoT#p_goods.typeid, CanNotDropList) of
                true ->
                    throw(goods_can_not_drop);
                false ->
                    ok
            end
    end,
   case catch lists:foldl(
                 fun(BagID,_Acc) ->
                         case catch mod_bag:delete_depositroy_goods(RoleID,BagID,GoodsID) of
                             {ok, [Goods]} ->
                                 erlang:throw({ok,Goods});
                             _Other ->
                                 _Other
                         end
                 end,{error,goods_not_found},[6,7,8,9])
   of
       {bag_error,goods_not_found} ->
           throw(goods_not_found);
       {ok,GoodsInfo} ->
           %% add by caochuncheng 添加商贸hook
           mod_trading:hook_t_drop_trading_bill_item(RoleID,GoodsInfo#p_goods.typeid),
           {ok,GoodsInfo}
   end.

destroy_goods_log(GoodsList) ->
    lists:foreach(
      fun(Goods) ->
              #p_goods{roleid=RoleID}=Goods,
              common_item_logger:log(RoleID,Goods,?LOG_ITEM_TYPE_SHOU_DONG_DIU_QI)
      end,GoodsList).

%%同仓库中的物品交换位置或者合并  ---------------------------------------------------------------  
do_swap({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_depot_swap_tos{goodsid = GoodID, position = Position, bagid=BagID} = DataIn,
    ?DEBUG("BagID:~w Position:~w~n",[BagID,Position]),
    case get_bag_and_pos(RoleID,BagID,Position) of
        {ok,Bag,Pos} ->
            case check_inbag(RoleID, GoodID) of
                {ok, GoodsInfo} ->
                    [CanNotInDepotList] = common_config_dyn:find(item_special, can_not_swap_in_depot_list),
                    case {lists:member(BagID, ?DEPOT_BAG_ID_LIST), lists:member(GoodsInfo#p_goods.typeid, CanNotInDepotList)} of
                        {true, true} ->
                            R = #m_depot_swap_toc{succ = false, reason = ?_LANG_ITEM_CAN_SWAP_IN_DEPOT};
                        _ ->
                            case mod_bag:check_bags_times_up(GoodsInfo#p_goods.bagid,Bag,RoleID,Pos) of
                                true->
                                    case db:transaction(fun() -> mod_bag:swap_goods(GoodID, Pos, Bag, RoleID) end) of
                                        {aborted, Reason}when is_binary(Reason) ->
                                            R = #m_depot_swap_toc{succ = false, reason = Reason};
                                        {aborted, Reason} ->
                                            ?INFO_MSG("swap_goods transaction fail, reason = ~w~n", [Reason]),
                                            R = #m_depot_swap_toc{succ = false, reason = ?_LANG_SYSTEM_ERROR};
                                        {atomic, {ok,none,Goods2}} ->
                                            hook_prop:hook(create, [Goods2]),
                                            R = #m_depot_swap_toc{succ = true, goods1 = GoodsInfo#p_goods{id=0}, goods2 = Goods2};
                                        {atomic, {ok,Goods1,Goods2}} ->
                                            hook_prop:hook(create, [Goods1]),
                                            hook_prop:hook(create, [Goods2]),
                                            R = #m_depot_swap_toc{succ = true, goods1 = Goods1, goods2 = Goods2}
                                    end;
                                false->
                                    R = #m_depot_swap_toc{succ=false,reason=?_LANG_ITEM_MOVE_EXTAND_BAG_TIMES_UP}
                            end
                    end;
                Other ->
                    ?INFO_MSG("swap_goods transaction fail, other = ~w~n", [Other]),
                    R = #m_depot_swap_toc{succ = false, reason = ?_LANG_SYSTEM_ERROR}
            end;
        {error,{not_enough_pos,_BagID}} ->
            R = #m_depot_swap_toc{succ = false, reason = ?_LANG_DEPOT_BAG_NOT_POS};
        {error, _} ->
            R = #m_depot_swap_toc{succ = false, reason = ?_LANG_SYSTEM_ERROR}
    end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

check_inbag(RoleID,GoodsID) ->
    catch lists:foldl(
            fun(BagID,_Acc) ->
                    case mod_bag:check_inbag(RoleID,GoodsID,BagID) of
                        {ok, Goods} ->
                            erlang:throw({ok,Goods});
                        _Other ->
                            _Other
                    end
            end,{error,not_found},[1,2,3,6,7,8,9]).

get_bag_and_pos(RoleID,BagID,Position) ->
  if
      is_integer(BagID) andalso BagID >0 andalso is_integer(Position) andalso Position > 0 ->
            {ok,BagID,Position};
      is_integer(BagID) andalso BagID > 0 andalso is_integer(Position) andalso Position == 0 ->
            case mod_bag:get_empty_bag_pos(RoleID,BagID,1) of
                {ok,_,[{Bag,Pos}]} ->
                    {ok,Bag,Pos};
                {error, Reason} ->
                    {error, Reason}
            end;
      true ->
            case mod_bag:get_empty_bag_pos(RoleID,1) of
                {ok,_,[{Bag,Pos}]} ->
                    {ok,Bag,Pos};
                {error, Reason} ->
                    {error, Reason}
            end
  end.
        
%%拆分仓库中的物品-----------------------------------------------------------------------------  
do_divide({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_depot_divide_tos{id = GoodID, num = DivideNum,bagid=BagID, position = NewPosition} = DataIn,
    case db:transaction(fun() -> mod_bag:divide_goods(GoodID, DivideNum, NewPosition, BagID, RoleID) end) of
        {aborted, Reason} when is_binary(Reason)->
            R = #m_refining_divide_toc{succ = false, reason = Reason};
        {aborted, Reason} ->
            ?DEBUG("divide_goods transaction fail, reason = ~w~n", [Reason]),
            R = #m_depot_divide_toc{succ = false, reason = ?_LANG_SYSTEM_ERROR};
        {atomic, {ok, Goods1,Goods2}} -> 
            R = #m_depot_divide_toc{succ = true,  goods1 = Goods1, goods2 = Goods2}
    end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%%整理仓库中的物品-----------------------------------------------------------------------------
do_tidy({Unique, Module, Method, DataIn, RoleID, _Pid, Line,_State}) ->
    #m_depot_tidy_tos{bagid=BagID}=DataIn,
    case db:transaction(fun() -> mod_bag:tidy_bag(RoleID,BagID) end) of
        {aborted, Reason} ->
            ?DEBUG("dity depot ~w error reason = ~w~n", [BagID,Reason]),
            Data = #m_depot_tidy_toc{succ=false,bagid = BagID, goods_list=[]};
        {atomic, {_,GoodsList}} ->
            ?DEBUG("~w~n",[GoodsList]),
            Data = #m_depot_tidy_toc{succ=true,bagid = BagID, goods_list = GoodsList}
    end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, Data).
    
 









        
            
