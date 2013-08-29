%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com(C) 2011, 
%%% @doc
%%% 装备升级接口
%%% @end
%%% Created : 20 Jun 2011 by  <caochuncheng2002@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_equip_upgrade).

%% INCLUDE
-include("mgeem.hrl").
-include("refining.hrl").

%% API
-export([
         do_equip_upgrade/1
        ]).

%%%===================================================================
%%% API
%%%===================================================================

do_equip_upgrade({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_equip_upgrade2(RoleId,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
        {ok,NextEquipGoods} ->
            do_equip_upgrade3({Unique, Module, Method, DataRecord, RoleId, PId, Line},NextEquipGoods);
        {ok,EquipGoods,UpgradeGoods,NextEquipGoods,UpgradeFee} ->
            do_equip_upgrade4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                              EquipGoods,UpgradeGoods,NextEquipGoods,UpgradeFee)
    end.
do_equip_upgrade2(RoleId,DataRecord) ->
    #m_refining_firing_tos{firing_list = FiringList,sub_op_type = SubOpType} = DataRecord,
    case SubOpType =:= ?FIRING_OP_TYPE_UPEQUIP_1 orelse SubOpType =:= ?FIRING_OP_TYPE_UPEQUIP_2 of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_UPEQUIP_TYPE_ERROR,0})
    end,
    case erlang:length(FiringList) =:= 2 of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_UPEQUIP_PARAM_ERROR,0})
    end,
    %% 检查是否有要升级的装备
    EquipGoods = 
        case lists:foldl(
               fun(EquipPRefiningT,AccEquipPRefiningT) ->
                       case EquipPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_TARGET
                           andalso EquipPRefiningT#p_refining.goods_type =:= ?TYPE_EQUIP of
                           true ->
                               [EquipPRefiningT|AccEquipPRefiningT];
                           false ->
                               AccEquipPRefiningT
                       end 
               end,[],FiringList) of
            [] ->
                erlang:throw({error,?_LANG_UPEQUIP_NO_EQUIP_ERROR,0});
            EquipPRefiningTTList when erlang:length(EquipPRefiningTTList) =:= 1 ->
                [EquipPRefiningTT] = EquipPRefiningTTList,
                case mod_bag:check_inbag(RoleId,EquipPRefiningTT#p_refining.goods_id) of
                    {ok,EquipGoodsT} ->
                        EquipGoodsT;
                    _  ->
                        erlang:throw({error,?_LANG_UPEQUIP_NO_EQUIP_ERROR,0})
                end;
            _ ->
                erlang:throw({error,?_LANG_UPEQUIP_NO_EQUIP_ERROR,0})
        end,
    [EquipBaseInfo] = common_config_dyn:find_equip(EquipGoods#p_goods.typeid),
    if EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
            erlang:throw({error,?_LANG_UPEQUIP_MOUNT_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
            erlang:throw({error,?_LANG_UPEQUIP_FASHION_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
            erlang:throw({error,?_LANG_UPEQUIP_ADORN_ERROR,0});
       true ->
            next
    end,
    [SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
    case lists:member(EquipGoods#p_goods.typeid,SpecialEquipList) of
        true ->
            erlang:throw({error,?_LANG_UPEQUIP_ADORN_ERROR,0});
        _ ->
            next
    end,
    %% 检查是否有装备升级符
    UpgradeGoods = 
        case lists:foldl(
               fun(UpgradePRefiningT,AccUpgradePRefiningT) ->
                       case ( AccUpgradePRefiningT =:= undefined
                              andalso UpgradePRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_MATERIAL
                              andalso UpgradePRefiningT#p_refining.goods_type =:= ?TYPE_ITEM) of
                           true ->
                               UpgradePRefiningT;
                           false ->
                               AccUpgradePRefiningT
                       end
               end,undefined,FiringList) of
            undefined ->
                erlang:throw({error,?_LANG_UPEQUIP_NOT_ENOUGH_GOODS,0});
            UpgradePRefiningTT ->
                case mod_bag:check_inbag(RoleId,UpgradePRefiningTT#p_refining.goods_id) of
                    {ok,UpgradeGoodsT} ->
                        UpgradeGoodsT;
                    _  ->
                        case SubOpType =:= ?FIRING_OP_TYPE_UPEQUIP_1 of
                            true ->
                                #p_goods{id = 0,type = ?TYPE_ITEM,typeid = UpgradePRefiningTT#p_refining.goods_type_id,
                                         bind = EquipGoods#p_goods.bind};
                            _ ->
                                erlang:throw({error,?_LANG_UPEQUIP_NOT_ENOUGH_GOODS,0})
                        end
                end
        end,
    [EquipUpgradeMaterialList] = common_config_dyn:find(refining,equip_upgrade_material),
    UpgradeGoodsLevel = 
        case lists:keyfind(UpgradeGoods#p_goods.typeid,1,EquipUpgradeMaterialList) of
            false ->
                erlang:throw({error,?_LANG_UPEQUIP_INVALID_GOODS,0});
            {_,UpgradeGoodsLevelT} ->
                UpgradeGoodsLevelT
        end,
    [EquipUpgradeLinkList] = common_config_dyn:find(refining,equip_upgrade_link_list),
    NextTypeId = 
        case lists:foldl(
               fun(EquipUpgradeLinkSubList,AccNextTypeId) ->
                       if AccNextTypeId =:= 0 ->
                               case lists:keyfind(EquipGoods#p_goods.typeid,#r_equip_upgrade_link.type_id,EquipUpgradeLinkSubList) of
                                   false ->
                                       AccNextTypeId;
                                   _ ->
                                       case lists:keyfind(UpgradeGoodsLevel,#r_equip_upgrade_link.link_code,
                                                          [EquipUpgradeLink || EquipUpgradeLink <- EquipUpgradeLinkSubList,
                                                                               EquipUpgradeLink#r_equip_upgrade_link.link_type =:= 1]) of
                                           false ->
                                               AccNextTypeId;
                                           #r_equip_upgrade_link{type_id =AccNextTypeIdT} ->
                                               AccNextTypeIdT
                                       end
                               end;
                          true ->
                               AccNextTypeId
                       end
               end,0,EquipUpgradeLinkList) of
            0 ->
                erlang:throw({error,?_LANG_UPEQUIP_EQUIP_LINK_ERROR,1});
            NextTypeIdT ->
                NextTypeIdT
        end,
    case NextTypeId =:= EquipGoods#p_goods.typeid of
        true ->
            erlang:throw({error,?_LANG_UPEQUIP_SAME_EQUIP_ERROR,0});
        _ ->
            next
    end,
    NextEquipGoods = 
        case get_next_equip_goods(EquipGoods,NextTypeId,UpgradeGoods#p_goods.bind) of
            {error,_GNextEquipGoodsError} ->
                erlang:throw({error,?_LANG_UPEQUIP_NEXT_EQUIP_ERROR,0});
            {ok,NextEquipGoodsT} ->
                NextEquipGoodsT
        end, 
    case SubOpType =:= ?FIRING_OP_TYPE_UPEQUIP_1 of
        true ->
            erlang:throw({ok,NextEquipGoods});
        _ ->
            next
    end,
	UpgradeFee = mod_refining:get_refining_fee(equip_upgrade_fee, EquipGoods),
    {ok,EquipGoods,UpgradeGoods,NextEquipGoods,UpgradeFee}.

do_equip_upgrade3({Unique, Module, Method, DataRecord, _RoleId, PId, _Line},NextEquipGoods) ->
    SendSelf = #m_refining_firing_toc{
      succ = true,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list,
      update_list = [],
      del_list = [],
      new_list = [NextEquipGoods]},
    ?DEBUG("~ts,SendSelf=~w",["天工炉模块返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

do_equip_upgrade4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                  EquipGoods,UpgradeGoods,NextEquipGoods,UpgradeFee) ->
    DelUpgradeNumber = 1,
     case common_transaction:transaction(
           fun() ->
                   do_t_equip_upgrade(RoleId,UpgradeGoods,NextEquipGoods,UpgradeFee,DelUpgradeNumber)
           end) of
        {atomic,{ok,DelList,UpdateList}} ->
            do_equip_upgrade5({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                              EquipGoods,UpgradeGoods,NextEquipGoods,DelList,UpdateList,DelUpgradeNumber);
        {aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},?_LANG_REFINING_NOT_BAG_POS_ERROR,0);
                {Reason, ReasonCode} ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
                _ ->
                    Reason2 = ?_LANG_UPEQUIP_ERROR,
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2,0)
            end
    end.

do_equip_upgrade5({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                  EquipGoods,UpgradeGoods,NextEquipGoods,DelList,UpdateList,DelUpgradeNumber) ->
    %% 道具变化通知
    if DelList =/= [] ->
            catch common_misc:del_goods_notify({line, Line, RoleId},DelList);
       true ->
            next
    end,
    case [NextEquipGoods|UpdateList] =/= [] of
        true ->
            catch common_misc:update_goods_notify({line, Line, RoleId},[NextEquipGoods|UpdateList]);
        _ ->
            next
    end,
    %% 钱币变化通知
    catch mod_refining:do_refining_deduct_fee_notify(RoleId,{line, Line, RoleId}),
    SendSelf = #m_refining_firing_toc{
      succ = true,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list,
      update_list = [NextEquipGoods|UpdateList],
      del_list = DelList,
      new_list = []},
    ?DEBUG("~ts,SendSelf=~w",["天工炉模块返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    %% 道具消费日志
    catch common_item_logger:log(RoleId,NextEquipGoods,?LOG_ITEM_TYPE_ZHUANG_BEI_SHENG_JI_HUO_DE),
    catch common_item_logger:log(RoleId,EquipGoods,?LOG_ITEM_TYPE_ZHUANG_BEI_SHENG_JI_SHI_QU),
    catch common_item_logger:log(RoleId,UpgradeGoods,DelUpgradeNumber,?LOG_ITEM_TYPE_ZHUANG_BEI_SHENG_JI_SHI_QU),
    ok.

do_t_equip_upgrade(RoleId,UpgradeGoods,NextEquipGoods,UpgradeFee,DelUpgradeNumber) ->
    EquipConsume = #r_equip_consume{
      type = upgrade,consume_type = ?CONSUME_TYPE_SILVER_EQUIP_UPGRADE,consume_desc = ""},
    case catch mod_refining:do_refining_deduct_fee(RoleId,UpgradeFee,EquipConsume) of
        {error,UpgradeFeeError} ->
            common_transaction:abort({UpgradeFeeError,0});
        _ ->
            next
    end,
    {DelList,UpdateList} = 
        case catch mod_equip_build:do_transaction_dedcut_goods(RoleId,[UpgradeGoods],DelUpgradeNumber) of
            {error,GoodsError} ->
                common_transaction:abort({GoodsError,0});
            {ok,DelListT,UpdateListT} ->
                DelListT2  = 
                    lists:foldl(
                      fun(DelGoods,AccDelListT2) -> 
                              case lists:keyfind(DelGoods#p_goods.id,#p_goods.id,UpdateListT) of
                                  false ->
                                      [DelGoods | AccDelListT2];
                                  _ ->
                                      AccDelListT2
                              end
                      end,[],DelListT),
                {DelListT2,UpdateListT}
        end,
    mod_bag:update_goods(RoleId,NextEquipGoods),
    {ok,DelList,UpdateList}.

do_refining_firing_error({Unique, Module, Method, DataRecord, _RoleId, PId, _Line},Reason,ReasonCode) ->
    SendSelf = #m_refining_firing_toc{
      succ = false,
      reason = Reason,
      reason_code = ReasonCode,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list},
    ?DEBUG("~ts,SendSelf=~w",["天工炉模块返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

%% 根据当前的装备获得目标装备p_goods
%% EquipGoods 要升级的装备 p_goods
%% NextTypeId 升级的目标装备类型id
%% MatrailBind 升级材料是否绑定 true or false
%% 返回 {ok,NextGoods} or {error,Reason}
get_next_equip_goods(EquipGoods,NextTypeId,MatrailBind) ->
    catch get_next_equip_goods2(EquipGoods,NextTypeId,MatrailBind).
get_next_equip_goods2(EquipGoods,NextTypeId,MatrailBind) ->
    NextEquipBaseInfo = 
        case common_config_dyn:find_equip(NextTypeId) of
            [NextEquipBaseInfoT] ->
                NextEquipBaseInfoT;
            _ ->
                erlang:throw({error,next_type_id_error})
        end,
    %% 验证通过，根据条件生成新的装备
    NewGoods = #p_goods{
      id =EquipGoods#p_goods.id,
      type = ?TYPE_EQUIP,
      roleid=EquipGoods#p_goods.roleid,
      current_num = EquipGoods#p_goods.current_num,
      state = 0,
      bagposition = EquipGoods#p_goods.bagposition,
      bagid = EquipGoods#p_goods.bagid,
      sell_type = NextEquipBaseInfo#p_equip_base_info.sell_type,
      sell_price = NextEquipBaseInfo#p_equip_base_info.sell_price,
      typeid = NextTypeId,
      name = NextEquipBaseInfo#p_equip_base_info.equipname,
      level =(NextEquipBaseInfo#p_equip_base_info.requirement)#p_use_requirement.min_level, 
      endurance = NextEquipBaseInfo#p_equip_base_info.endurance,
      loadposition = 0,
      current_endurance = NextEquipBaseInfo#p_equip_base_info.endurance,
      bind = EquipGoods#p_goods.bind,
      embe_pos = EquipGoods#p_goods.embe_pos,
      embe_equipid = EquipGoods#p_goods.embe_equipid,
      current_colour = EquipGoods#p_goods.current_colour,
      reinforce_result = EquipGoods#p_goods.reinforce_result,
      reinforce_rate = EquipGoods#p_goods.reinforce_rate,
      reinforce_result_list = EquipGoods#p_goods.reinforce_result_list,
      quality = EquipGoods#p_goods.quality,
      sub_quality = EquipGoods#p_goods.sub_quality,
      quality_rate = EquipGoods#p_goods.quality_rate,
      forge_num = EquipGoods#p_goods.forge_num,
      stone_num = EquipGoods#p_goods.stone_num,
      punch_num = EquipGoods#p_goods.punch_num,
      add_property=NextEquipBaseInfo#p_equip_base_info.property,
      stones = EquipGoods#p_goods.stones,
      signature = EquipGoods#p_goods.signature,
      sign_role_id = EquipGoods#p_goods.sign_role_id,
      equip_bind_attr = EquipGoods#p_goods.equip_bind_attr,
      use_bind = EquipGoods#p_goods.use_bind},
    %% 装备颜色
    NewGoods2 = mod_refining:equip_colour_quality_add(new,NewGoods,1,1,1),
    %% 强化处理
    NewGoods3 = mod_equip_change:equip_reinforce_property_add(NewGoods2,NextEquipBaseInfo),
    %% 宝石处理
    NewGoods4 = 
        case  NewGoods2#p_goods.stones =/= undefined 
            andalso erlang:is_list(NewGoods2#p_goods.stones)
            andalso NewGoods2#p_goods.stones =/= [] of
            true ->
                mod_equip_change:equip_stone_property_add(NewGoods3);
            _ ->
                NewGoods3
        end,
    %% 绑定处理
    NewGoods5 = mod_refining_bind:do_equip_bind_for_equip_upgrade(NewGoods4,NextEquipBaseInfo),
    %% 材料绑定处理
    NewGoods6 =
        case MatrailBind =:= true andalso NewGoods5#p_goods.bind =:= false of
            true ->
                case mod_refining_bind:do_equip_bind_for_upgrade(NewGoods5) of 
                    {error,_BindErrorCode} ->
                        NewGoods5#p_goods{bind=true};
                    {ok,NewGoods6T} ->
                        NewGoods6T
                end;
            _ ->
                NewGoods5
        end,
    %% 精炼系数处理
    NewGoods7 = 
        case common_misc:do_calculate_equip_refining_index(NewGoods6) of
            {error,_IndexErrorCode} ->
                NewGoods6;
            {ok,NewGoods7T} ->
                NewGoods7T
        end,
    {ok,NewGoods7}.
