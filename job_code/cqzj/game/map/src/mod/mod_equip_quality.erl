%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2011, 
%%% @doc
%%% 装备品质改造
%%% @end
%%% Created : 24 Jul 2011 by  <caochuncheng2002@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_equip_quality).

%% INCLUDE
-include("mgeem.hrl").
-include("refining.hrl").

%% API
-export([do_up_equip_quality/1]).

%%%===================================================================
%%% API
%%%===================================================================

do_up_equip_quality({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_up_equip_quality2(RoleId,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
        {ok,EquipGoods,QualityGoods,QualityFee,NewQuality,NewSubQuality} ->
            do_up_equip_quality3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                 EquipGoods,QualityGoods,QualityFee,NewQuality,NewSubQuality)
    end.

do_up_equip_quality2(RoleId,DataRecord) ->
    #m_refining_firing_tos{firing_list = FiringList} = DataRecord,
    %% 材料是否足够合法
    case (erlang:length(FiringList) =:= 2) of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_UPQUALITY_NOT_ENOUGH_GOODS,0})
    end,
    %% 检查是否有要品质改造的装备
    EquipGoods = 
        case lists:foldl(
               fun(EquipPRefiningT,AccEquipPRefiningT) ->
                       case ( AccEquipPRefiningT =:= undefined
                              andalso EquipPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_TARGET
                              andalso EquipPRefiningT#p_refining.goods_type =:= ?TYPE_EQUIP) of
                           true ->
                               EquipPRefiningT;
                           false ->
                               AccEquipPRefiningT
                       end 
               end,undefined,FiringList) of
            undefined ->
                erlang:throw({error,?_LANG_UPQUALITY_NO_EQUIP,0});
            EquipPRefiningTT ->
                case mod_bag:check_inbag(RoleId,EquipPRefiningTT#p_refining.goods_id) of
                    {ok,EquipGoodsT} ->
                        EquipGoodsT;
                    _  ->
                        erlang:throw({error,?_LANG_UPQUALITY_NO_EQUIP,0})
                end
        end,
    [EquipBaseInfo] = common_config_dyn:find_equip(EquipGoods#p_goods.typeid),
    if EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
            erlang:throw({error,?_LANG_UPQUALITY_MOUNT_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
            erlang:throw({error,?_LANG_UPQUALITY_FASHION_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
            erlang:throw({error,?_LANG_UPQUALITY_ADORN_ERROR,0});
       true ->
            next
    end,
    [SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
    case lists:member(EquipGoods#p_goods.typeid,SpecialEquipList) of
        true ->
            erlang:throw({error,?_LANG_UPQUALITY_ADORN_ERROR,0});
        _ ->
            next
    end,
    %% 装备是否还需要改造
    [MaxSubQualityLevel] = common_config_dyn:find(refining,equip_change_quality_sub_max_level),
    case EquipGoods#p_goods.quality =:= ?QUALITY_PERFECT andalso EquipGoods#p_goods.sub_quality =:= MaxSubQualityLevel of
        true ->
            erlang:throw({error,?_LANG_UPQUALITY_FULL,0});
        _ ->
            next
    end,
    %% 检查当前品质等级需要的改造石
    [QualityToColorList] = common_config_dyn:find(refining,quality_to_color),
    TotalQuality = 
        if EquipGoods#p_goods.quality =/= 0 ->
                (EquipGoods#p_goods.quality - 1) * MaxSubQualityLevel + EquipGoods#p_goods.sub_quality;
           true ->
                if EquipGoods#p_goods.sub_quality =/= 0 ->
                        EquipGoods#p_goods.sub_quality;
                   true ->
                        1
                end
        end,
    ParamEquipQuality = 
        lists:foldl(
          fun({MinParamTotalQuality,MaxParamTotalQuality,ParamCurColor},AccParamEquipQuality) ->
                  if AccParamEquipQuality =:= -1 ->
                          ParamCurColor;
                     AccParamEquipQuality =:= 1
                     andalso TotalQuality >= MinParamTotalQuality andalso TotalQuality < MaxParamTotalQuality ->
                          ParamCurColor;
                     AccParamEquipQuality =:= 1 andalso MaxParamTotalQuality =:= TotalQuality ->
                          -1;
                     true ->
                          AccParamEquipQuality
                  end
          end,1,QualityToColorList),
    [QualityMaterialList] = common_config_dyn:find(refining,quality_material),
    {QualityMaterialTypeId,QualityMaterialLevel} = lists:keyfind(ParamEquipQuality,2,QualityMaterialList),
    [QualityMaterialBaseInfo] = common_config_dyn:find_item(QualityMaterialTypeId),
    %% 检查是否有品质改造石
    QualityGoods = 
        case lists:foldl(
               fun(QualityPRefiningT,AccQualityPRefiningT) ->
                       case AccQualityPRefiningT =:= undefined
                           andalso QualityPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_MATERIAL
                           andalso QualityPRefiningT#p_refining.goods_type =:= ?TYPE_ITEM 
                           andalso QualityPRefiningT#p_refining.goods_type_id =:= QualityMaterialTypeId of
                           true ->
                               QualityPRefiningT;
                           false ->
                               AccQualityPRefiningT
                       end
               end,undefined,FiringList) of
            undefined ->
                erlang:throw({error,
                              common_tool:get_format_lang_resources(?_LANG_UPQUALITY_FAIL_GOODS_ERROR,
                                                                    [1,QualityMaterialBaseInfo#p_item_base_info.itemname]),
                              0});
            QualityPRefiningTT ->
                case mod_bag:check_inbag(RoleId,QualityPRefiningTT#p_refining.goods_id) of
                    {ok,QualityGoodsT} ->
                        QualityGoodsT;
                    _  ->
                        erlang:throw({error,
                                      common_tool:get_format_lang_resources(?_LANG_UPQUALITY_FAIL_GOODS_ERROR,
                                                                            [1,QualityMaterialBaseInfo#p_item_base_info.itemname]),
                                      0})
                end
        end,
    %% 当前品质改造需要的最低材料是否合法
    [QualityMaterialProbabilityList] = common_config_dyn:find(refining,quality_material_probability),
    {_,QualityMaterialWeightList} = lists:keyfind(QualityMaterialLevel,1,QualityMaterialProbabilityList),
    {MaxMaterialQuality,_Index} = 
        lists:foldl(
          fun(QualityMaterialWeight,{AccMaxMaterialQuality,AccIndex}) ->
                  if QualityMaterialWeight =/= 0 ->
                          {AccIndex,AccIndex + 1};
                     true ->
                          {AccMaxMaterialQuality,AccIndex + 1}
                  end
          end,{0,1},QualityMaterialWeightList),
    MaterialQuality = common_tool:ceil(MaxMaterialQuality / MaxSubQualityLevel),
    SubMaterialQuality = 
        case MaxMaterialQuality rem MaxSubQualityLevel of
            0 ->
                MaxSubQualityLevel;
            SubMaterialQualityT ->
                SubMaterialQualityT
        end,
    case EquipGoods#p_goods.quality >= MaterialQuality
        andalso EquipGoods#p_goods.sub_quality >= SubMaterialQuality of
        true ->
            erlang:throw({error,?_LANG_UPQUALITY_GOODS_LEVEL_NOT_ENOUGH,0});
        _ ->
            next
    end,
    %% 本次改造新的品质值 和子品质值
    NewSumQuality = mod_refining:get_random_number(QualityMaterialWeightList,0,1),
    NewQuality = common_tool:ceil(NewSumQuality / MaxSubQualityLevel),
    NewSubQuality = 
        case NewSumQuality rem  MaxSubQualityLevel of
            0 ->
                MaxSubQualityLevel;
            NewSubQualityT ->
                NewSubQualityT
        end,
    %% 改造费用
	QualityFee = mod_refining:get_refining_fee(equip_quality_fee, EquipGoods, QualityMaterialLevel, 1),
    {ok,EquipGoods,QualityGoods,QualityFee,NewQuality,NewSubQuality}.

do_up_equip_quality3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                     EquipGoods,QualityGoods,QualityFee,NewQuality,NewSubQuality) ->
    case common_transaction:transaction(
           fun() ->
                   do_t_up_equip_quality(RoleId,EquipGoods,QualityGoods,QualityFee,NewQuality,NewSubQuality)
           end) of
        {atomic,{ok,IsSucc,NewEquipGoods,DelList,UpdateList}} ->
            do_up_equip_quality5({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                 IsSucc,NewEquipGoods,QualityGoods,DelList,UpdateList);
        {aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},?_LANG_REFINING_NOT_BAG_POS_ERROR,0);
                {Reason, ReasonCode} ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
                _ ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},?_LANG_UPQUALITY_ERROR,0)
            end
    end.

do_up_equip_quality5({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                     IsSucc,EquipGoods,QualityGoods,DelList,UpdateList) ->
    case IsSucc =:= true of
        true ->
            Reason = common_tool:get_format_lang_resources(?_LANG_UPQUALITY_SUCC,[EquipGoods#p_goods.quality_rate/100]),
            ReasonCode = 0;
        _ ->
            Reason = ?_LANG_UPQUALITY_FAIL,
            ReasonCode = 1
    end,
    SendSelf = #m_refining_firing_toc{
      succ = true,
      reason = Reason,
      reason_code = ReasonCode,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list,
      update_list = [EquipGoods | UpdateList],
      del_list = DelList,
      new_list = []},
    %% 道具变化通知
    if UpdateList =/= [] ->
            catch common_misc:update_goods_notify({line, Line, RoleId},[EquipGoods | UpdateList]);
       true ->
            catch common_misc:update_goods_notify({line, Line, RoleId},[EquipGoods])
    end,
    if DelList =/= [] ->
            catch common_misc:del_goods_notify({line, Line, RoleId},DelList);
       true ->
            next
    end,
    %% 钱币变化通知
    catch mod_refining:do_refining_deduct_fee_notify(RoleId,{line, Line, RoleId}),
    %% 道具消费日志
    catch common_item_logger:log(RoleId,QualityGoods,1,?LOG_ITEM_TYPE_TI_SHENG_PIN_ZHI_SHI_QU),
    catch common_item_logger:log(RoleId,EquipGoods,?LOG_ITEM_TYPE_TI_SHENG_PIN_ZHI_HUO_DE),
    ?DEBUG("~ts,SendSelf=~w",["天工炉模块返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    ok.

do_t_up_equip_quality(RoleId,EquipGoods,QualityGoods,QualityFee,NewQuality,NewSubQuality) ->
    %% 扣费
    EquipConsume = #r_equip_consume{
      type = quality,
      consume_type = ?CONSUME_TYPE_SILVER_EQUIP_QUALITY,
      consume_desc = ""},
    mod_refining:do_refining_deduct_fee(RoleId,QualityFee,EquipConsume),
    %% 扣除材料
    {DelList,UpdateList} = 
        case catch mod_equip_build:do_transaction_dedcut_goods(RoleId,[QualityGoods],1) of
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
    %% 判断是否品质改造成功
    {NewQuality2,NewSubQuality2} = 
        if NewQuality > EquipGoods#p_goods.quality ->
                IsSucc = true,
                {NewQuality,NewSubQuality};
           NewQuality =:= EquipGoods#p_goods.quality 
           andalso NewSubQuality > EquipGoods#p_goods.sub_quality ->
                IsSucc = true,
                {NewQuality,NewSubQuality};
           true ->
                IsSucc = false,
                {EquipGoods#p_goods.quality,EquipGoods#p_goods.sub_quality}
        end,
    EquipGoods2 = mod_refining:equip_colour_quality_add(mod,EquipGoods,EquipGoods#p_goods.current_colour,NewQuality2,NewSubQuality2),
    %% 判断是否材料是绑定的
    EquipGoods3 = 
        case EquipGoods2#p_goods.bind =:= false andalso QualityGoods#p_goods.bind =:= true of
            true ->
                case mod_refining_bind:do_equip_bind_for_quality(EquipGoods2) of
                    {error,_QualityBindCode} ->
                        EquipGoods2#p_goods{bind=true};
                    {ok,EquipGoods3T} ->
                        EquipGoods3T
                end;
            _ ->
                EquipGoods2
        end,
    %% 重算精练系数
    %% 计算装备精炼系数
    EquipGoods4 = 
        case common_misc:do_calculate_equip_refining_index(EquipGoods3) of
            {error,_ErrorIndexCode} ->
                EquipGoods3;
            {ok, EquipGoods4T} ->
                EquipGoods4T
        end,
    mod_bag:update_goods(RoleId,EquipGoods4),
    {ok,IsSucc,EquipGoods4,DelList,UpdateList}.

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
