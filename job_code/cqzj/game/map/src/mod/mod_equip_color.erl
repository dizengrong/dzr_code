%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2011, 
%%% @doc
%%% 提升装备颜色模块
%%% @end
%%% Created : 11 May 2011 by  <caochuncheng2002@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_equip_color).

%% INCLUDE
-include("mgeem.hrl").
-include("refining.hrl").

%% API
-export([
         do_up_equip_color/1
        ]).


%%%===================================================================
%%% API
%%%===================================================================
%% 提升装备颜色 
%% DataRecord 结构为 m_refining_firing_tos
do_up_equip_color({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_up_equip_color2(RoleId,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
        {ok,EquipGoods} ->
            do_up_equip_color3({Unique, Module, Method, DataRecord, RoleId, PId, Line},EquipGoods);
        {ok,EquipGoods,ColorGoodsList,GolorPRefiningList,CurProbability,ColorFee} ->
            do_up_equip_color4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                               EquipGoods,ColorGoodsList,GolorPRefiningList,CurProbability,ColorFee)
    end.
do_up_equip_color2(RoleId,DataRecord) ->
    #m_refining_firing_tos{firing_list = FiringList,sub_op_type = SubOpType} = DataRecord,
    case SubOpType =:= ?FIRING_OP_TYPE_UPCOLOR_1 orelse SubOpType =:= ?FIRING_OP_TYPE_UPCOLOR_2 of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_UPCOLOR_TYPE_ERROR,0})
    end,
    case erlang:length(FiringList) > 0 of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_UPCOLOR_NO_EQUIP_ERROR,0})
    end,
    %% 检查是否有要提升颜色的装备
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
                erlang:throw({error,?_LANG_UPCOLOR_NO_EQUIP_ERROR,0});
            EquipPRefiningTTList when erlang:length(EquipPRefiningTTList) =:= 1 ->
                [EquipPRefiningTT] = EquipPRefiningTTList,
                case mod_bag:check_inbag(RoleId,EquipPRefiningTT#p_refining.goods_id) of
                    {ok,EquipGoodsT} ->
                        EquipGoodsT;
                    _  ->
                        erlang:throw({error,?_LANG_UPCOLOR_NO_EQUIP_ERROR,0})
                end;
            _ ->
                erlang:throw({error,?_LANG_UPCOLOR_TOO_MUCH_EQUIP_ERROR,0})
        end,
    %% 检查是否存在一个装备被使用成提升装备和材料
    case lists:foldl(
           fun(DiffEquipPRefiningT,AccDiffEquipPRefiningTFlag) ->
                   case DiffEquipPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_MATERIAL
                       andalso DiffEquipPRefiningT#p_refining.goods_id =:= EquipGoods#p_goods.id of
                       true ->
                           false;
                       _ ->
                           AccDiffEquipPRefiningTFlag
                   end
           end,true,FiringList) of
        false ->
            erlang:throw({error,?_LANG_UPCOLOR_USE_TWO_ERROR,0});
        _ ->
            next
    end,
    [EquipBaseInfo] = common_config_dyn:find_equip(EquipGoods#p_goods.typeid),
    if EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
            erlang:throw({error,?_LANG_UPCOLOR_MOUNT_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
            erlang:throw({error,?_LANG_UPCOLOR_FASHION_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
            erlang:throw({error,?_LANG_UPCOLOR_ADORN_ERROR,0});
       true ->
            next
    end,
    [SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
    case lists:member(EquipGoods#p_goods.typeid,SpecialEquipList) of
        true ->
            erlang:throw({error,?_LANG_UPCOLOR_ADORN_ERROR,0});
        _ ->
            next
    end,
    if EquipGoods#p_goods.current_colour =:= ?COLOUR_GOLD ->
            erlang:throw({error,?_LANG_UPCOLOR_MAX_COLOR,0});
       true ->
            next
    end,
   GolorPRefiningList = 
        lists:foldl(
          fun(GolorPRefiningT,AccGolorPRefiningList) ->
                  case GolorPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_MATERIAL of
                      true ->
                          [GolorPRefiningT|AccGolorPRefiningList];
                      false ->
                          AccGolorPRefiningList
                  end
          end,[],FiringList),
    if SubOpType =:= ?FIRING_OP_TYPE_UPCOLOR_1 andalso GolorPRefiningList =:= []  ->
            %% 如果是查询操作，即检查到这里即可以
            erlang:throw({ok,EquipGoods});
       SubOpType =:= ?FIRING_OP_TYPE_UPCOLOR_2 andalso GolorPRefiningList =:= [] ->
            erlang:throw({error,?_LANG_UPCOLOR_NO_GOODS_ERROR,0});
       true ->
            next
    end,
    case SubOpType =:= ?FIRING_OP_TYPE_UPCOLOR_2 
        andalso erlang:length(GolorPRefiningList) > 0
        andalso erlang:length(GolorPRefiningList) =< 5 of
        true ->
            next;
        _ ->
            case erlang:length(GolorPRefiningList) > 5 of
                true ->
                    erlang:throw({error,?_LANG_UPCOLOR_NO_GOODS_ERROR,0});
                _ ->
                    erlang:throw({error,?_LANG_UPCOLOR_TOO_MUCH_GOODS_ERROR,0})
            end
    end,
    ColorGoodsList = 
        lists:foldl(
          fun(GolorPRefiningTT,AccColorGoodsList) ->
                  case mod_bag:check_inbag(RoleId,GolorPRefiningTT#p_refining.goods_id) of
                      {ok,ColorGoodsT} ->
                          [ColorGoodsT|AccColorGoodsList];
                      _  ->
                          AccColorGoodsList
                  end
          end,[],GolorPRefiningList),
    case erlang:length(ColorGoodsList) =:= erlang:length(GolorPRefiningList) of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_UPCOLOR_GOODS_NO_IN_BAG,0})
    end,
    %% 特殊装备不可以当材料提升装备颜色
    lists:foreach(
      fun(SpecialColorGoods) ->
              if SpecialColorGoods#p_goods.type =:= ?TYPE_EQUIP ->
                      [SpecialEquipBaseInfo] = common_config_dyn:find_equip(SpecialColorGoods#p_goods.typeid),
                      if SpecialEquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
                              erlang:throw({error,?_LANG_UPCOLOR_MOUNT_M_ERROR,0});
                         SpecialEquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
                              erlang:throw({error,?_LANG_UPCOLOR_FASHION_M_ERROR,0});
                         SpecialEquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
                              erlang:throw({error,common_tool:get_format_lang_resources(?_LANG_UPCOLOR_ADORN_M_ERROR,[SpecialColorGoods#p_goods.name]),0});
                         true ->
                              next
                      end,
                      case lists:member(SpecialColorGoods#p_goods.typeid,SpecialEquipList) of
                          true ->
                              erlang:throw({error,common_tool:get_format_lang_resources(?_LANG_UPCOLOR_ADORN_M_ERROR,[SpecialColorGoods#p_goods.name]),0});
                          _ ->
                              next
                      end;
                 true ->
                      next
              end
      end,ColorGoodsList),
    %% 检查是否是提升装备颜色的材料
    [ColorMaterialList] = common_config_dyn:find(refining,equip_color_material),
    case lists:foldl(
           fun(ColorGoods,AccColorGoodsFlag) ->
                   case ColorGoods#p_goods.type =:= ?TYPE_EQUIP
                       orelse lists:member(ColorGoods#p_goods.typeid,ColorMaterialList) of
                       true ->
                           AccColorGoodsFlag;
                       _ ->
                           false
                   end
           end,true,ColorGoodsList) of
        false ->
            erlang:throw({error,?_LANG_UPCOLOR_INVALID_GOODS_ERROR,0});
        _ ->
            next
    end,
    %% 装备材料颜色限制
    [MinMaterialColor] = common_config_dyn:find(refining,equip_color_min_material_color),
    case lists:foldl(
           fun(MinColorGoods,AccMinColorGoodsFlag) ->
                   if MinColorGoods#p_goods.type =:= ?TYPE_EQUIP ->
                           if MinColorGoods#p_goods.current_colour >= MinMaterialColor ->
                                   AccMinColorGoodsFlag;
                              true ->
                                   false
                           end;
                      true ->
                           AccMinColorGoodsFlag
                   end
           end,true,ColorGoodsList) of
        false ->
            erlang:throw({error,?_LANG_UPCOLOR_INVALID_COLOR_GOODS,0});
        _ ->
            next
    end,
    %% 计算当前材料的概率，是否放多了材料
    [ColorProbabilityList] = common_config_dyn:find(refining,equip_color_probability),
    ColorGoodsProbabilityList = 
        lists:foldl(
          fun(ColorGoodsProbabilityT,AccColorGoodsProbabilityList) ->
                  #p_refining{goods_number = ColorGoodsProbabilityNumber} = 
                      lists:keyfind(ColorGoodsProbabilityT#p_goods.id,#p_refining.goods_id,GolorPRefiningList),
                  lists:append([lists:foldl(
                                  fun(_,AccSubColorGoodsProbabilityList) ->
                                          [ColorGoodsProbabilityT|AccSubColorGoodsProbabilityList]
                                  end,[],lists:seq(1,ColorGoodsProbabilityNumber,1))
                                ,AccColorGoodsProbabilityList])
          end,[],ColorGoodsList),
    {CurProbability,MaxProbabilityIndex} = 
        lists:foldl(
          fun(ColorGoodsT,{AccCurProbability,AccMaxProbabilityIndex}) ->
                  DiffColor = EquipGoods#p_goods.current_colour - ColorGoodsT#p_goods.current_colour,
                  case lists:member(ColorGoodsT#p_goods.typeid,ColorMaterialList) of
                      true -> %% 材料
                          ColorMaterialType = 1,
                          DiffIndex = 0;
                      false ->
                          ColorMaterialType = 2,
                          DiffIndex = ColorGoodsT#p_goods.level div 10 - EquipGoods#p_goods.level div 10
                  end,
                  case [PR || PR <- ColorProbabilityList,
                              PR#r_equip_color_probability.material_type =:=  ColorMaterialType,
                              PR#r_equip_color_probability.min_color =< DiffColor,
                              PR#r_equip_color_probability.max_color >= DiffColor,
                              PR#r_equip_color_probability.min_index =< DiffIndex,
                              PR#r_equip_color_probability.max_index >= DiffIndex] of
                      [] ->
                          erlang:throw({error,common_tool:get_format_lang_resources(?_LANG_UPCOLOR_INVALID_COLOR_EQUIP,[ColorGoodsT#p_goods.name]),0});
                      [PRT] ->
                          AccCurProbability2 = AccCurProbability + PRT#r_equip_color_probability.probability,
                          case AccCurProbability >= 10000 of
                              true ->
                                  {AccCurProbability2,AccMaxProbabilityIndex};
                              _ ->
                                  {AccCurProbability2,AccMaxProbabilityIndex + 1}
                          end
                  end
          end,{0,0},ColorGoodsProbabilityList),
    ?DEBUG("~ts,CurProbability=~w",["本次装备提升概率",CurProbability]),
    case CurProbability >= 10000 andalso erlang:length(ColorGoodsProbabilityList) > MaxProbabilityIndex of
        true ->
            erlang:throw({error,?_LANG_UPCOLOR_MAX_PROBABILITY,0});
        _ ->
            next
    end,
    %% 计算费用
    NextEquipColor = EquipGoods#p_goods.current_colour + 1,
    ColorFee = 
        case common_config_dyn:find(refining,equip_color_fee) of
            [ColorFeeList] ->
                case lists:keyfind(NextEquipColor,1,ColorFeeList) of
                    false ->
                        erlang:throw({error,?_LANG_UPCOLOR_ERROR,0});
                    {_,ColorFeeT} ->
                        ColorFeeT
                end;
            _ ->
                erlang:throw({error,?_LANG_UPCOLOR_ERROR,0})
        end,
    
    {ok,EquipGoods,ColorGoodsList,GolorPRefiningList,CurProbability,ColorFee}.
%% 查询操作处理
do_up_equip_color3({Unique, Module, Method, DataRecord, _RoleId, PId, _Line},EquipGoods) ->
    NextColor = EquipGoods#p_goods.current_colour + 1,
    EquipGoods2 = mod_refining:equip_colour_quality_add(
                        mod,EquipGoods,NextColor,EquipGoods#p_goods.quality, EquipGoods#p_goods.sub_quality),
    SendSelf = #m_refining_firing_toc{
      succ = true,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list,
      update_list = [],
      del_list = [],
      new_list = [EquipGoods2]},
    ?DEBUG("~ts,SendSelf=~w",["天工炉模块返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

do_up_equip_color4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                   EquipGoods,ColorGoodsList,GolorPRefiningList,CurProbability,ColorFee) ->
    case common_transaction:transaction(
           fun() ->
                   do_t_up_equip_color(RoleId,EquipGoods,ColorGoodsList,GolorPRefiningList,CurProbability,ColorFee)
           end) of
        {atomic,{ok,NewEquipGoods,IsSucc,DelList,UpdateList}} ->
            do_up_equip_color5({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                               NewEquipGoods,ColorGoodsList,GolorPRefiningList,IsSucc,DelList,UpdateList);
        {aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},?_LANG_REFINING_NOT_BAG_POS_ERROR,0);
                {Reason, ReasonCode} ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
                _ ->
                    Reason2 = ?_LANG_UPCOLOR_ERROR,
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2,0)
            end
    end.

do_up_equip_color5({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                   EquipGoods,ColorGoodsList,GolorPRefiningList,IsSucc,DelList,UpdateList) ->
    NextList = 
        if EquipGoods#p_goods.current_colour >= ?COLOUR_GOLD ->
                [];
           true ->
                [mod_refining:equip_colour_quality_add(
                       mod,EquipGoods,EquipGoods#p_goods.current_colour + 1,EquipGoods#p_goods.quality, EquipGoods#p_goods.sub_quality)]
        end,
    SendUpdateList = 
        case IsSucc of
            true ->
                ColorName = lists:nth(EquipGoods#p_goods.current_colour,[?_LANG_COLOR_WHITE,
                                                                         ?_LANG_COLOR_GREEN,
                                                                         ?_LANG_COLOR_BLUE,
                                                                         ?_LANG_COLOR_PURPLE,
                                                                         ?_LANG_COLOR_ORANGE,
                                                                         ?_LANG_COLOR_GOLD]),
                Reason = common_tool:get_format_lang_resources(?_LANG_UPCOLOR_SUCC_BC,[EquipGoods#p_goods.name,ColorName]),
                ReasonCode = 0,
                [EquipGoods|UpdateList];
            false ->
                Reason = ?_LANG_UPCOLOR_FAIL_BC,
                ReasonCode = 1,
                UpdateList
        end,
    SendSelf = #m_refining_firing_toc{
      succ = true,
      reason = Reason,reason_code = ReasonCode,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list,
      update_list = SendUpdateList,
      del_list = DelList,
      new_list = NextList},
    %% 道具变化通知
    if DelList =/= [] ->
            catch common_misc:del_goods_notify({line, Line, RoleId},DelList);
       true ->
            next
    end,
    if SendUpdateList =/= [] ->
            catch common_misc:update_goods_notify({line, Line, RoleId},SendUpdateList);
       true ->
            next
    end,
    %% 钱币变化通知
    catch mod_refining:do_refining_deduct_fee_notify(RoleId,{line, Line, RoleId}),
    %% 道具消费日志
    catch common_item_logger:log(RoleId,EquipGoods,?LOG_ITEM_TYPE_UPCOLOR_HUO_DE),
    lists:foreach(
      fun(DelGoods) ->
              #p_refining{goods_number = DelGoodsNumber} = 
                  lists:keyfind(DelGoods#p_goods.id,#p_refining.goods_id,GolorPRefiningList),
              catch common_item_logger:log(RoleId,DelGoods,DelGoodsNumber,?LOG_ITEM_TYPE_UPCOLOR_SHI_QU)
      end,ColorGoodsList),
    ?DEBUG("~ts,SendSelf=~w",["天工炉模块返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    %% 提升装备颜色消息广播通知
    case EquipGoods#p_goods.current_colour >= ?COLOUR_ORANGE andalso ReasonCode =:= 0 of
        true ->
            LangColorName = 
                if EquipGoods#p_goods.current_colour =:= ?COLOUR_ORANGE ->
                        ?_LANG_COLOR_ORANGE;
                   true ->
                        ?_LANG_COLOR_GOLD
                end,
            #p_map_role{role_name = RoleName,faction_id = FactionId} = mod_map_actor:get_actor_mapinfo(RoleId,role),
            FactionName = 
                if FactionId =:= 1 ->
                        ?_LANG_COLOR_FACTION_1;
                   FactionId =:= 2 ->
                        ?_LANG_COLOR_FACTION_2;
                   true ->
                        ?_LANG_COLOR_FACTION_3
                end,
            LangGoodsName = common_goods:get_notify_goods_name(EquipGoods#p_goods{current_colour = EquipGoods#p_goods.current_colour - 1}),
            LeftMessage = lists:flatten(io_lib:format(?_LANG_UPCOLOR_SUCC_FACTION_BC,
                                                      [FactionName,RoleName,LangGoodsName,LangColorName])),
            common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,LeftMessage),
            ok;
        _ ->
            ignore
    end,
    ok.
do_t_up_equip_color(RoleId,EquipGoods,ColorGoodsList,GolorPRefiningList,CurProbability,ColorFee) ->
    %% 扣费
    NextColor = EquipGoods#p_goods.current_colour + 1,
    ConsumeType = 
        if NextColor =:= ?COLOUR_GREEN ->
                ?CONSUME_TYPE_SILVER_EQUIP_UPCOLOR_GREEN;
           NextColor =:= ?COLOUR_BLUE ->
                ?CONSUME_TYPE_SILVER_EQUIP_UPCOLOR_BLUE;
           NextColor =:= ?COLOUR_PURPLE ->
                ?CONSUME_TYPE_SILVER_EQUIP_UPCOLOR_PURPLE;
           NextColor =:= ?COLOUR_ORANGE ->
                ?CONSUME_TYPE_SILVER_EQUIP_UPCOLOR_ORANGE;
           NextColor =:= ?COLOUR_GOLD ->
                ?CONSUME_TYPE_SILVER_EQUIP_UPCOLOR_GOLD;
           true ->
                ?CONSUME_TYPE_SILVER_EQUIP_UPCOLOR_GREEN
        end,
    EquipConsume = #r_equip_consume{
      type = upcolor,consume_type = ConsumeType,consume_desc = ""},
    case catch mod_refining:do_refining_deduct_fee(RoleId,ColorFee,EquipConsume) of
        {error,ColorFeeError} ->
            common_transaction:abort({ColorFeeError,0});
        _ ->
            next
    end,
    {DelList,UpdateList} = 
        lists:foldl(
          fun(DelColorGoods,{AccDelList,AccUpdateList}) ->
                  #p_refining{goods_number = DelGoodsNumber} = 
                      lists:keyfind(DelColorGoods#p_goods.id,#p_refining.goods_id,GolorPRefiningList),
                  {AccDelListT,AccUpdateListT} = 
                      case catch mod_equip_build:do_transaction_dedcut_goods(RoleId,[DelColorGoods],DelGoodsNumber) of
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
                  {lists:append([AccDelListT,AccDelList]),lists:append([AccUpdateListT,AccUpdateList])}
          end,{[],[]},ColorGoodsList),
    IsSucc = random:uniform(10000) =< CurProbability,
    %% 材料是否绑定
    IsColorGoodsBind = 
        lists:foldl(
          fun(ColorGoodsBindT,AccIsColorGoodsBind) ->
                  case ColorGoodsBindT#p_goods.bind =:= true of
                      true ->
                          true;
                      _ ->
                          AccIsColorGoodsBind
                  end
          end,false,ColorGoodsList),
    EquipGoods7 = 
        case IsSucc of
            true ->
                EquipGoods2 = mod_refining:equip_colour_quality_add(
                                    mod,EquipGoods,NextColor,EquipGoods#p_goods.quality, EquipGoods#p_goods.sub_quality),
                %% 装备绑定
                EquipGoods3 = 
                    case EquipGoods2#p_goods.bind =:= false
                        andalso IsColorGoodsBind =:= true of
                        true ->
                            %% 需要处理绑定属性
                            case EquipGoods2#p_goods.use_bind =/= 0 andalso erlang:is_list(EquipGoods2#p_goods.equip_bind_attr)
                                 andalso erlang:length(EquipGoods2#p_goods.equip_bind_attr) > 0 of
                                true ->
                                    EquipGoods2#p_goods{bind=true};
                                _ ->
                                    case mod_refining_bind:do_equip_bind_by_config_atom(
                                           EquipGoods2,equip_bind_attr_number_upcolor,equip_bind_attr_level_upcolor) of
                                        {ok,EquipGoods3T} ->
                                            EquipGoods3T;
                                        _ ->
                                            EquipGoods2#p_goods{bind = true}
                                    end
                            end;
                        _ ->
                            EquipGoods2
                    end,
                %% 计算装备精炼系数
                EquipGoods4 = 
                    case common_misc:do_calculate_equip_refining_index(EquipGoods3) of
                        {error,_ErrorIndexCode} ->
                            EquipGoods3;
                        {ok, EquipGoods4T} ->
                            EquipGoods4T
                    end,
                mod_bag:update_goods(RoleId,EquipGoods4),
                EquipGoods4;
            _ ->
                %% 装备绑定
                case EquipGoods#p_goods.bind =:= false 
                    andalso IsColorGoodsBind =:= true of
                    true ->
                        %% 需要处理绑定属性
                        EquipGoods5 = 
                            case EquipGoods#p_goods.use_bind =/= 0 andalso erlang:is_list(EquipGoods#p_goods.equip_bind_attr)
                                                        andalso erlang:length(EquipGoods#p_goods.equip_bind_attr) > 0 of
                                true ->
                                    EquipGoods#p_goods{bind=true};
                                _ ->
                                    case mod_refining_bind:do_equip_bind_by_config_atom(
                                           EquipGoods,equip_bind_attr_number_upcolor,equip_bind_attr_level_upcolor) of
                                        {ok,EquipGoods5T} ->
                                            EquipGoods5T;
                                        _ ->
                                            EquipGoods#p_goods{bind = true}
                                    end
                            end,
                        EquipGoods6 = 
                            case common_misc:do_calculate_equip_refining_index(EquipGoods5) of
                                {error,_ErrorIndexCode} ->
                                    EquipGoods5;
                                {ok, EquipGoods6T} ->
                                    EquipGoods6T
                            end,
                        mod_bag:update_goods(RoleId,EquipGoods6),
                        EquipGoods6;
                    _ ->
                        EquipGoods
                end
        end,
    {ok,EquipGoods7,IsSucc,DelList,UpdateList}.

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
