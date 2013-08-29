%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com(C) 2010, 
%%% @doc
%%% 天工炉炼制功能处理模块
%%% @end
%%% Created : 16 Dec 2010 by  <caochuncheng>
%%%-------------------------------------------------------------------
-module(mod_refining_forging).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").
-include("refining.hrl").

-define(ITEM_TYPE_LIST,[?TYPE_ITEM,?TYPE_STONE,?TYPE_EQUIP]).
%% API
-export([
         do_handle_info/1,
         get_refining_forging_by_goods/2,
         do_refining_forging_notify/4
        ]).


%% 天工炉炼制功能
do_handle_info({Unique, ?REFINING, ?REFINING_FORGING, DataRecord, RoleId, PId, Line})
  when erlang:is_record(DataRecord,m_refining_forging_tos)->
    do_refining_forging({Unique, ?REFINING, ?REFINING_FORGING, DataRecord, RoleId, PId, Line});

%% 更新天工炉炼制方案配置
do_handle_info({reload_forging_config}) ->
    do_reload_forging_config();

do_handle_info(Info) ->
    ?ERROR_MSG("~ts,Info=~w",["天工炉炼制模块无法处整此消息",Info]),
    error.

%% 更新天工炉炼制方案配置
%% message format
%% global:send(MapProcessName, {mod_refining_forging,{reload_forging_config}})
do_reload_forging_config() ->
    ?INFO_MSG("~ts",["更新天工炉炼制的炼制方案配置文件"]),
    mod_forging_config:init().


%% 天工炉炼制功能
%% 查询天工炉当前的物品信息
%% 针对物品进行分类
%% 根据物品匹配炼制方案
%% 生成炼制物品
%% 返回结果和消息广播处理
do_refining_forging({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_refining_forging2({Unique, Module, Method, DataRecord, RoleId, PId, Line}) of
        {error,Reason} ->
            do_refining_forging_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason);
        {ok,GoodsList,FFRecord} ->
            do_refining_forging3({Unique, Module, Method, DataRecord, RoleId, PId, Line},GoodsList,FFRecord)
    end.
do_refining_forging2({_Unique, _Module, _Method, DataRecord, RoleId, _PId, _Line}) ->
    %% 检查系统是否开放此功能
    [IsOpenForging] = common_config_dyn:find(etc,open_refining_forging),
    case IsOpenForging of
        true ->
            next;
        false ->
            ?DEBUG("~ts",["系统设计天工炉炼制功能暂不开放"]),
            erlang:throw({error,?_LANG_REINFORCE_FORGING_NOT_OPEN})
    end,
    BagId = DataRecord#m_refining_forging_tos.bag_id,
    if BagId =:= ?REFINING_BAGID ->
            next;
       true ->
            ?DEBUG("~ts,DataRecord=~w",["参数错误，背包id不合法",DataRecord]),
            erlang:throw({error,?_LANG_REINFORCE_FORGING_ERROR})
    end,
    MapRoleInfo = 
        case mod_map_actor:get_actor_mapinfo(RoleId,role) of
            undefined ->
                ?DEBUG("~ts,RoleId=~w",["此炼制请求无法处理，即在当前地图中查找不到玩家的信息",RoleId]),
                erlang:throw({error,?_LANG_REINFORCE_FORGING_ERROR});
            MapRoleInfoT ->
                MapRoleInfoT
        end,
    GoodsList = mod_refining_bag:get_goods_by_bag_id(RoleId,?REFINING_BAGID),
    if GoodsList =:= [] ->
            ?DEBUG("~ts",["天工炉没有物品，无法炼制"]),
            erlang:throw({error,?_LANG_REINFORCE_FORGING_EMPTY});
       true ->
            next
    end,
    %% 返回结果 {ok,r_forging_formula} or {error,Reason}
    FFRecord = 
        case get_refining_forging_by_goods(MapRoleInfo,GoodsList) of
            {ok,FFRecordT} ->
                FFRecordT;
            {error,Reason} ->
                ?DEBUG("~ts,Reason=~w",["此物品无法获取合法的炼制方案",Reason]),
                erlang:throw({error,?_LANG_REINFORCE_FORGING_ERROR})
        end,
    {ok,GoodsList,FFRecord}.

do_refining_forging3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                     GoodsList,FFRecord) ->
     case common_transaction:transaction(fun() -> 
                                 t_create_refining_forging(RoleId,GoodsList,FFRecord)
                         end) of
        {aborted, Reason} ->
             Reason2 = 
                 case Reason of 
                     {throw,{bag_error,BR}} ->
                         ?DEBUG("~ts,bag_error=~w",["炼制操作背包失败，炼制失败",BR]),
                         case BR of
                             {not_enough_pos,_BagID} ->
                                 ?_LANG_REINFORCE_FORGING_BAG;
                             _ ->
                                 ?_LANG_REINFORCE_FORGING_ERROR
                         end;
                     {throw,{error,R}} ->
                         R;
                     _ ->
                         ?DEBUG("~ts,Reason=~w",["炼制失败",Reason]),
                         ?_LANG_REINFORCE_FORGING_ERROR
                 end,
             do_refining_forging_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2);
         {atomic, {ok,[],undefined}} ->
             ?DEBUG("~ts",["物品合法，炼制失败，即概率命中失败"]),
             Reason3 = ?_LANG_REINFORCE_FORGING_FAIL,
             do_refining_forging_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason3);
         {atomic, {ok,NewGoodsList,FFProduct}} ->
             do_refining_forging4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                  GoodsList,FFRecord,NewGoodsList,FFProduct)
    end.
do_refining_forging4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                     GoodsList,_FFRecord,NewGoodsList,FFProduct) ->
    catch do_log_item(RoleId,GoodsList,NewGoodsList),
    case NewGoodsList of 
        [] ->
            Reason = ?_LANG_REINFORCE_FORGING_FAIL,
            do_refining_forging_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason);
        _ ->
            SendSelf = #m_refining_forging_toc{succ = true,
                                               goods_list = NewGoodsList,
                                               depletion_goods = GoodsList},
            ?DEBUG("~ts,Result=~w",["天工炉炼制操作返回结果",SendSelf]),
            common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
            catch do_refining_forging_notify(RoleId,FFProduct,GoodsList,NewGoodsList)
    end.

%% 记录道具奖励的日志信息
do_log_item(RoleId,GoodsList,NewGoodsList) ->
    lists:foreach(
      fun(Goods) ->
              do_log_item2(RoleId,Goods,?LOG_ITEM_TYPE_LIAN_ZHI_SHI_QU)
      end,GoodsList),
    lists:foreach(
      fun(Goods2) ->
              do_log_item2(RoleId,Goods2,?LOG_ITEM_TYPE_LIAN_ZHI_HUO_DE)
      end,NewGoodsList),
    ok.
do_log_item2(RoleId,Goods,LogAction) ->
    common_item_logger:log(RoleId,Goods,LogAction).

do_refining_forging_error({Unique, Module, Method, _DataRecord, RoleId, PId, _Line},Reason) ->
    GoodsList = mod_refining_bag:get_goods_by_bag_id(RoleId,?REFINING_BAGID),
    SendSelf = #m_refining_forging_toc{succ = false,
                                       reason = Reason,
                                       goods_list = GoodsList},
    ?DEBUG("~ts,Result=~w",["天工炉炼制操作返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).
 
%% 通过物品列表获取合法的炼制方案
%% 参数 
%% MapRoleInfo 请炼制的玩家的信息 p_map_role
%% ClassGoodsList 炼制物品信息 [p_goods]
%% 返回结果 {ok,r_forging_formula} or {error,Reason}
get_refining_forging_by_goods(MapRoleInfo,GoodsList) ->
    %% 获取所有的炼制方案 [r_forging_formula]
    ForgingFormulaList = mod_forging_config:get(?REFINING_FORGING_FORMULA),
    CheckFFList = 
        lists:foldl(
          fun(FFRecord,Acc) ->
                  %% FFMaterials 结构为 [r_forging_formula_item]
                  FFMaterials = FFRecord#r_forging_formula.materials,
                  FFProducts = FFRecord#r_forging_formula.products,
                  case check_forging_formula(MapRoleInfo,FFRecord) of
                      true ->
                          case check_forging_formula_products(FFProducts) of
                              false ->
                                  Acc;
                              true ->
                                  case check_refining_forging_material(FFMaterials,GoodsList) of
                                      true ->
                                          [FFRecord | Acc];
                                      false ->
                                          Acc
                                  end
                          end;
                      false ->
                          Acc
                  end
          end,[],ForgingFormulaList),
    ?DEBUG("~ts,AllVaildFFList=~w",["获取材料符合条件的所有炼制方案列表",CheckFFList]),
    Len = erlang:length(CheckFFList),
    if Len =:= 0 ->
            {error,not_found};
       Len =:= 1 ->
            {ok,lists:nth(1,CheckFFList)};
       Len > 1 ->
            SortFFList = 
                lists:sort(
                  fun(FFA,FFB) ->
                          AUpdateTime = FFA#r_forging_formula.update_time,
                          BUpdateTime = FFB#r_forging_formula.update_time,
                          if AUpdateTime >= BUpdateTime ->
                                  true;
                             true ->
                                  false
                          end
                  end,CheckFFList),
            {ok,lists:nth(1,SortFFList)};
       true ->
            {error,other_error}
    end.
%% 检查方案的合法性，即方案的有效时间
%% 参数
%% MapRoleInfo 请炼制的玩家的信息 p_map_role
%% FFRecord 炼制方案记录 r_forging_formula
%% 返回 true or false
check_forging_formula(MapRoleInfo,FFRecord) ->
    case catch check_forging_formula2(MapRoleInfo,FFRecord) of
        {error,Reason} ->
            ?DEBUG("~ts,MapRoleInfo=~w,FFRecord=~w,Reason=~w",["炼制方案不合法",MapRoleInfo,FFRecord,Reason]),
            false;
        {ok} ->
            true
    end.
check_forging_formula2(MapRoleInfo,FFRecord) ->
    FFMaterials = FFRecord#r_forging_formula.materials,
    if erlang:is_list(FFMaterials)
       andalso erlang:length(FFMaterials) > 0 ->
            next;
       true ->
            erlang:throw({error,formula_materials})
    end,  
    FFProducts = FFRecord#r_forging_formula.products,
    if erlang:is_list(FFProducts)
       andalso erlang:length(FFProducts) > 0 ->
            next;
       true ->
            erlang:throw({error,formula_products})
    end,
    MinRoleLevel = FFRecord#r_forging_formula.min_role_level,
    MaxRoleLevel = FFRecord#r_forging_formula.max_role_level,
    Level = MapRoleInfo#p_map_role.level,
    if MinRoleLevel =:= 0 ->
            next;
       MinRoleLevel > 0 
       andalso Level >= MinRoleLevel ->
            next;
       true ->
            erlang:throw({error,formula_min_role_level})
    end,
    if MaxRoleLevel =:= 0 ->
            next;
       MaxRoleLevel > 0
       andalso MaxRoleLevel >= Level ->
            next;
       true ->
             erlang:throw({error,formula_max_role_level})
    end,
    NowDate = common_tool:now(),
    StartDate = FFRecord#r_forging_formula.start_date,
    EndDate =  FFRecord#r_forging_formula.end_date,
    if StartDate =:= 0 ->
            next;
       StartDate > 0 
       andalso NowDate >= StartDate ->
            next;
       true ->
            erlang:throw({error,formula_start_date})
    end,
    if EndDate =:= 0 ->
            next;
       EndDate > 0 
       andalso EndDate >= NowDate ->
            next;
       true ->
            erlang:throw({error,formula_end_date})
    end,
    {ok}.
%% 检查炼制方案中的获取的材料配置是否合理
%% 炼制获得的材料物品，
%% 必须是 type = 1的类型，且材料配置必须是大于或等于 1
%% bind 值必须是  1 洗炼，2 不洗炼，4 根据材料
%% item_num 值必须大于 0
%% 检查 result_weight > 0，succ_probability >= 0 
%% 参数
%% FFProducts 炼制方案中获取材料物品配置列表 [r_forging_formula_item]
%% 返回 true or false
check_forging_formula_products(FFProducts) ->
    if FFProducts =:= [] ->
            false;
       erlang:length(FFProducts) =:= 1 ->
            [Product] = FFProducts,
            Type = Product#r_forging_formula_item.type,
            Bind = Product#r_forging_formula_item.bind,
            ItemNum = Product#r_forging_formula_item.item_num,
            ResultWeight = Product#r_forging_formula_item.result_weight,
            SuccProbability = Product#r_forging_formula_item.succ_probability,
            if Type =:= ?REFINING_FORGING_MATERIAL_TYPE_ITEM
               andalso (Bind =:= 1 orelse Bind =:= 2 orelse Bind =:= 4)
               andalso ItemNum > 0
               andalso ResultWeight > 0
               andalso SuccProbability >= 0 ->
                    true;
               true ->
                    false
            end;
       true ->
            check_forging_formula_products2(FFProducts)
    end.
check_forging_formula_products2(FFProducts) ->
    %% 如果是多个产品配置方案，即一定要是概率的 result_weight > 0,且 SuccProbability >= 0
    %% 且每一个产品 result_weight都一样
    {Flag,_ARW,_Index} = 
        lists:foldl(
          fun(FFProduct,Acc) ->
                  {AccFlag,AccResultWeight,AccIndex} = Acc,
                  Type = FFProduct#r_forging_formula_item.type,
                  Bind = FFProduct#r_forging_formula_item.bind,
                  ItemNum = FFProduct#r_forging_formula_item.item_num,
                  ResultWeight = FFProduct#r_forging_formula_item.result_weight,
                  SuccProbability = FFProduct#r_forging_formula_item.succ_probability,
                  AccResultWeight2 = 
                      if AccIndex =:= 1 ->
                              ResultWeight;
                         true ->
                              AccResultWeight
                      end,
                  AccIndex2 = AccIndex  + 1, 
                  if Type =:= ?REFINING_FORGING_MATERIAL_TYPE_ITEM
                     andalso (Bind =:= 1 orelse Bind =:= 2 orelse Bind =:= 4)
                     andalso ItemNum > 0 andalso ResultWeight > 3 
                     andalso SuccProbability >= 0
                     andalso AccResultWeight2 =:= ResultWeight ->
                          {AccFlag,AccResultWeight2,AccIndex2};
                     true ->
                          {false,AccResultWeight2,AccIndex2}
                     end
          end,{true,0,1},FFProducts),
    Flag.

%% 检查炼制方案与材料是否一致
%% 方案的材料是有可以相关的，需要使用扣除的方式来处理
%% 扣除的方式必须处理材料属性多个条件材料时的处理
%% 传的材料列表必须根据最杂的条件优先判断来处理
%% 参数
%% GoodsList 炼制剩余的物品信息 [p_goods] 
%% SMaterials 方案材料列表 [r_forging_formula_item]
%% 返回 true or false
check_refining_forging_material(SMaterials,GoodsList) ->
    %% 检查材料要求的总数和物品的总数是否一致，
    MSum = lists:foldl(fun(FFItem,AccM) -> AccM + FFItem#r_forging_formula_item.item_num end,0,SMaterials),
    GSum = lists:foldl(fun(Goods,AccG) -> AccG + Goods#p_goods.current_num end, 0, GoodsList),
    if MSum =:= GSum ->
            check_refining_forging_material2(SMaterials,GoodsList);
       true ->
            false
    end.
check_refining_forging_material2(SMaterials,GoodsList) ->
    %% 检查每种材料是否有符合条件的物品
    case get_material_match_goods(SMaterials,GoodsList,true,[]) of
        {true,MatchGoodsList} ->
            check_refining_forging_material3(SMaterials,GoodsList,MatchGoodsList);
        {false,_Result} ->
            false
    end.
check_refining_forging_material3(SMaterials,GoodsList,MatchGoodsList) ->
    %% 检查每一种材料要求的物品的数量是否一致
    Flag = 
        lists:foldl(
          fun({FFItem,MGoodsList},Acc) ->
                  MNumber = FFItem#r_forging_formula_item.item_num,
                  GNumber = lists:foldl(fun(Goods,AccG) -> AccG + Goods#p_goods.current_num end, 0, MGoodsList),
                  if MNumber =:= GNumber ->
                          Acc;
                     true ->
                          false
                  end
          end,true,MatchGoodsList),
    case Flag of
        true ->
            true;
        false ->
            check_refining_forging_material4(SMaterials,GoodsList,MatchGoodsList)
    end.
check_refining_forging_material4(SMaterials,GoodsList,MatchGoodsList) ->
    %% 每种材料要求的物品数与实现的物品数不是一一对等的，必须重新分配此物品列表
    %% 先将一一对等的物品去掉
    {SMaterials2,GoodsList2} = 
        lists:foldl(
          fun({FFItem,MGoodsList},Acc) ->
                  {AccSMaterials,AccGoodsList} = Acc,
                  MNumber = FFItem#r_forging_formula_item.item_num,
                  GNumber = lists:foldl(fun(Goods,AccG) -> AccG + Goods#p_goods.current_num end, 0, MGoodsList),
                  if MNumber =:= GNumber ->
                          AccGoodsList2 = 
                              lists:foldl(
                                fun(IGoods,IAcc) -> 
                                        lists:keydelete(IGoods#p_goods.id,#p_goods.id,IAcc)
                                end,AccGoodsList,MGoodsList),
                          AccSMaterials2 = lists:delete(FFItem,AccSMaterials),
                          {AccSMaterials2,AccGoodsList2};
                     true ->
                          Acc
                  end
          end,{SMaterials,GoodsList},MatchGoodsList),
    %% 重新针对剩下的材料检查材料对应的物品数是否一致
    case get_material_match_goods(SMaterials2,GoodsList2,true,[]) of
        {true,MatchGoodsList2} ->
            check_refining_forging_material5(SMaterials2,GoodsList2,MatchGoodsList2);
        {false,_Result} ->
            false
    end.
check_refining_forging_material5(SMaterials,GoodsList,MatchGoodsList) ->
    %% 先扣除没有符合两种材料要求的物品
    {SMaterials2,GoodsList2,Flag} = 
        lists:foldl(
          fun({AccFFItem,MGoodsList},Acc) ->
                  {AccSMaterials,AccGoodsList,AccFlag} = Acc,
                  case AccFlag of
                      false ->
                          Acc;
                      true ->
                          %% 查找出 MGoodsList 物品中没有被共用的物品
                          MGoodsList2 = get_not_share_use_goods(AccFFItem,MGoodsList,MatchGoodsList),
                          MNumber = AccFFItem#r_forging_formula_item.item_num,
                          GNumber = lists:foldl(fun(Goods,AccG) -> AccG + Goods#p_goods.current_num end, 0, MGoodsList2),
                          if GNumber > MNumber ->
                                  ?DEBUG("~ts",["发现不可以被共用的物品总数超真实材料要求的数量时，即此方案不合法"]),
                                  {AccSMaterials,AccGoodsList,false};
                             GNumber =:= MNumber ->
                                  AccSMaterials2 = lists:delete(AccFFItem,AccSMaterials),
                                  AccGoodsList2 = lists:foldl(
                                                    fun(IGoods,IAcc) -> 
                                                            lists:keydelete(IGoods#p_goods.id,#p_goods.id,IAcc)
                                                    end,AccGoodsList,MGoodsList2),
                                  {AccSMaterials2,AccGoodsList2,AccFlag};
                             true ->
                                  Acc
                          end
                  end
          end,{SMaterials,GoodsList,true},MatchGoodsList),
    case Flag of
        false ->
            false;
        true ->
            if erlang:length(SMaterials2) =:= erlang:length(SMaterials) ->
                    check_refining_forging_material6(SMaterials,GoodsList,MatchGoodsList);
               true ->
                    case get_material_match_goods(SMaterials2,GoodsList2,true,[]) of
                        {true,MatchGoodsList2} ->
                            check_refining_forging_material6(SMaterials2,GoodsList2,MatchGoodsList2);
                        {false,_Result} ->
                            false
                    end
            end
    end.

check_refining_forging_material6(_SMaterials,GoodsList,MatchGoodsList) ->
    %% 现在物品都必须加上共用的物品一部分数量才够用，即接下来的处理即是
    %% 找出有共用物品最少的材料执行扣除，直到可以扣除全部，即此方案符合要求
    %% 查找出每一种材料要求的物品列表中共用的物品数据量，针对从最少到最多的方式扣除物品
    ShareGoodsList = 
        lists:foldl(
          fun({FFItem,MGoodsList},Acc) ->
                  SGoodsList = get_share_use_goods(FFItem,MGoodsList,MatchGoodsList),
                  [{FFItem,SGoodsList}|Acc]
          end,[],MatchGoodsList),
    ShareGoodsList2 = 
        lists:sort(
          fun(SGA,SGB) ->
                  {_SFFA,SGoodsA} = SGA,
                  {_SFFB,SGoodsB} = SGB,
                  if erlang:length(SGoodsA) < erlang:length(SGoodsB) ->
                          true;
                     true ->
                          false
                  end
          end,ShareGoodsList),
    SortSMaterials = [SFFItem || {SFFItem,_SMGoodsList} <- ShareGoodsList2],
    ?DEBUG("~ts,SortSMaterials=~w,GoodsList=~w",["此材料存在共用的物品信息",SortSMaterials,GoodsList]),
    check_refining_forging_material7(SortSMaterials,GoodsList,MatchGoodsList,true).

check_refining_forging_material7([],_GoodsList,_MatchGoodsList,Flag) ->
    Flag;
check_refining_forging_material7(_SMaterials,_GoodsList,_MatchGoodsList,false) ->
    false;
check_refining_forging_material7([H|T],GoodsList,MatchGoodsList,Flag) ->
    ?DEBUG("~ts,FFItem=~w",["当前处理的材料要求",H]),
    case lists:keyfind(H,1,MatchGoodsList) of
        false ->
            check_refining_forging_material7(T,GoodsList,MatchGoodsList,false);
        {H,MGoodsList} ->
            ?DEBUG("~ts,MGoodsList=~w",["当前处理的材料要求",MGoodsList]),
            NotShareGL = get_not_share_use_goods(H,MGoodsList,MatchGoodsList),
            ShareGL = get_share_use_goods(H,MGoodsList,MatchGoodsList),
            NotShareNum = lists:foldl(fun(NSGoods,NSAcc) -> NSAcc + NSGoods#p_goods.current_num end, 0, NotShareGL),
            MNumber = H#r_forging_formula_item.item_num,
            NewNum = NotShareNum - MNumber,
            ?DEBUG("~ts,NotShareGL=~w,ShareGL=~w",["当前处理的材料要求",NotShareGL,ShareGL]),
            if NewNum > 0 ->
                    check_refining_forging_material7(T,GoodsList,MatchGoodsList,false);
               NewNum =:= 0 ->
                    GoodsList2 = 
                        lists:foldl(
                          fun(Goods,AccGoodsList) ->
                                  lists:keydelete(Goods#p_goods.id,#p_goods.id,AccGoodsList)
                          end,GoodsList,NotShareGL),
                    %% 重新针对剩下的材料检查材料对应的物品数是否一致
                    case get_material_match_goods(T,GoodsList2,true,[]) of
                        {true,MatchGoodsList2} ->
                            check_refining_forging_material7(T,GoodsList2,MatchGoodsList2,Flag);
                        {false,_Result} ->
                            check_refining_forging_material7(T,GoodsList,MatchGoodsList,false)
                    end;
               true ->
                    GoodsList3 = 
                        lists:foldl(
                          fun(Goods3,AccGoodsList3) ->
                                  lists:keydelete(Goods3#p_goods.id,#p_goods.id,AccGoodsList3)
                          end,GoodsList,MGoodsList),
                    case deduct_share_goods(MNumber - NotShareNum,ShareGL,T,GoodsList3) of
                        {false,[],[]} ->
                            check_refining_forging_material7(T,GoodsList,MatchGoodsList,false);
                        {true,GoodsList4,MatchGoodsList4} ->
                             check_refining_forging_material7(T,GoodsList4,MatchGoodsList4,Flag)
                    end
            end
    end.
 
%% 扣除共用物品的并返回剩余的物品
%% 目前只实现这一种排除策略，当需要支持每中共用物品扣除一部分，或者扣除某个物品，减其它物品时无法支持
%% 从最多到最少顺序扣除
%% Number 扣除物品数
%% ShareGoodsList 共用物品列表
%% T 材料列表 [r_forging_formula_item]
%% GoodsList 总物品 [p_goods]
%% 返回剩余的物品列表{true,GoodsList,MatchGoodsList} or {false,[],[]}
deduct_share_goods(Number,ShareGoodsList,T,GoodsList) ->
    SortGoodsList = 
        lists:sort(
          fun(GoodsA,GoodsB) ->
                  if GoodsA#p_goods.current_num > GoodsB#p_goods.current_num ->
                          true;                          
                     true ->
                          false
                  end
          end,ShareGoodsList),
    LenList = lists:seq(1,erlang:length(SortGoodsList),1),
    lists:foldl(
      fun(Index,Acc) ->
              {AccFlag,_,_} = Acc,
              case AccFlag of
                  false ->
                      case deduct_share_goods2(Number,SortGoodsList,Index) of
                          {ok,RsGoodsList} ->
                              GoodsList2 = lists:append([GoodsList,RsGoodsList]),
                              case get_material_match_goods(T,GoodsList2,true,[]) of
                                  {true,MatchGoodsList2} ->
                                      {true,GoodsList2,MatchGoodsList2};
                                  {false,_Result} ->
                                      Acc
                              end;
                          {error,Reason} ->
                              ?DEBUG("~ts,Reason=~w",["此扣除物品方式不合理",Reason]),
                              Acc
                      end;
                  true ->
                      Acc
              end
      end,{false,[],[]},LenList).
    
%% 扣除共用物品的并返回剩余的物品
%% 目前只实现这一种排除策略，当需要支持每中共用物品扣除一部分，或者扣除某个物品，减其它物品时无法支持
%% 从最多到最少顺序扣除
%% Number 扣除物品数
%% ShareGoodsList 共用物品列表
%% Index 开始扣除物品的序号 1..erlang:length(ShareGoodsList)
%% 返回剩余的物品列表{ok,[p_goods]} or {error,Reason}
deduct_share_goods2(Number,SortGoodsList,Index) ->
    %% ?DEBUG("Number=~w,SortGoodsList=~w,Index=~w",[Number,SortGoodsList,Index]),
    {Num,Rs,_AccI} = deduct_share_goods3(Number,SortGoodsList,Index),
    if Num =:= 0 ->
            {ok,Rs};
       Num > 0 andalso Index > 1 
       andalso Index =< erlang:length(SortGoodsList) ->
            %% 回扣列表物品
            SubSortGoodsList = lists:sublist(SortGoodsList,Index),
            {Num2,Rs2,_AccI2} =  deduct_share_goods3(Num,SubSortGoodsList,1),
            if Num2 =:= 0 ->
                    {ok,lists:append([Rs,Rs2])};
               true ->
                    {error,not_enough_goods}
            end;
       true ->
            {error,not_enough_goods}
    end.
deduct_share_goods3(Number,ShareGoodsList,Index) ->
    lists:foldl(
      fun(Goods,Acc) ->
              {AccNum,AccRs,I} = Acc,
              if I >= Index andalso AccNum > 0 ->
                      GNumber = Goods#p_goods.current_num,
                      NewNum = GNumber - AccNum,
                      %% ?DEBUG("NewNum=~w",[NewNum]),
                      if NewNum > 0 ->
                              AccRs2 =  [Goods#p_goods{current_num = NewNum}|AccRs],
                              {0,AccRs2,I + 1};
                         NewNum =:= 0 ->
                              {0,AccRs,I + 1};
                         true ->
                              {AccNum - GNumber, AccRs, I + 1}
                      end;
                 true ->
                      {AccNum,[Goods|AccRs],I+1}
              end
      end,{Number,[],Index},ShareGoodsList).
    
%% 查找出物品中没有被共用的物品
%% 从一个符合材料要求的物品列表中，获取没有被共用的物品列表
%% 参数
%% FFItem 材料要求 r_forging_formula_item
%% GoodsList 符合种用材料的物品列表 [p_goods]
%% MatchGoodsList 每种符合材料要求的物品列表 [{r_forging_formula_item,[p_goods]},...]
%% 返回新的符合条件的物品列表 [p_goods] 
get_not_share_use_goods(FFItem,GoodsList,MatchGoodsList) ->
    lists:foldl(
      fun(Goods,Acc) ->
              Flag = 
                  lists:foldl(
                    fun({AccFFItem,MGoodsList},IAcc) ->
                            if FFItem =:= AccFFItem ->
                                    IAcc;
                               true ->
                                    case lists:keyfind(Goods#p_goods.id,#p_goods.id,MGoodsList) of
                                        false ->
                                            IAcc;
                                        _ ->
                                            false
                                    end
                            end
                    end,true,MatchGoodsList),
              case Flag of
                  true ->
                      [Goods|Acc];
                  false ->
                      Acc
              end              
      end,[],GoodsList).
%% 查找出物品中被共用的物品
%% 从一个符合材料要求的物品列表中，获取没有被共用的物品列表
%% 参数
%% FFItem 材料要求 r_forging_formula_item
%% GoodsList 符合种用材料的物品列表 [p_goods]
%% MatchGoodsList 每种符合材料要求的物品列表 [{r_forging_formula_item,[p_goods]},...]
%% 返回新的符合条件的物品列表 [p_goods]
get_share_use_goods(FFItem,GoodsList,MatchGoodsList) ->
    lists:foldl(
      fun(Goods,Acc) ->
              Flag = 
                  lists:foldl(
                    fun({AccFFItem,MGoodsList},IAcc) ->
                            if FFItem =:= AccFFItem ->
                                    IAcc;
                               true ->
                                    case lists:keyfind(Goods#p_goods.id,#p_goods.id,MGoodsList) of
                                        false ->
                                            IAcc;
                                        _ ->
                                            false
                                    end
                            end
                    end,true,MatchGoodsList),
              case Flag of
                  true ->
                      Acc;
                  false ->
                      [Goods|Acc]
              end              
      end,[],GoodsList).
    
%% 检查是不是炼制方案要求的每种材料是不是有对应的物品
%% SMaterials 方案材料列表 [r_forging_formula_item]
%% GoodsList 天工炉总的物品列表 [p_goods]
%% Flag 初始化执行结果 true
%% Result 返回结果 [{r_forging_formula_item,MatchGoodsList},..] MatchGoodsList为符合条件的物品列表
%% 返回 {true,MatchGoodsList} or {false,MatchGoodsList}
get_material_match_goods([],_GoodsList,Flag,Result) ->
    {Flag,Result};
get_material_match_goods(_SMaterials,_GoodsList,false,Result) ->
    {false,Result};
get_material_match_goods([H|T],GoodsList,Flag,Result) ->
    %% 根据每种材料查询符合条件的物品列表
    case get_refining_forging_material_type_ids(H) of
        {error,Reason} ->
            ?DEBUG("~ts,Reason=~w",["根据材料数据查询材料的类型和类型id出错",Reason]),
            get_material_match_goods(T,GoodsList,false,Result);
        {ok,Type,ItemIds} ->
            %% ?DEBUG("~ts,Type=~w,GoodsList=~w,H=~w,ItemIds=~w",["获取符合此材料要求的物品信息",Type,GoodsList,H,ItemIds]),
            MatchGoodsList = get_refining_forging_goods_by_material(Type,GoodsList,H,ItemIds),
            MNumber = H#r_forging_formula_item.item_num,
            GNumber = lists:foldl(fun(Goods,AccG) -> AccG + Goods#p_goods.current_num end, 0, MatchGoodsList),
            if GNumber >= MNumber ->
                    get_material_match_goods(T,GoodsList,Flag,[{H,MatchGoodsList}|Result]);
               true ->
                    ?DEBUG("~ts,FFItem=~w,MNumber=~w,GNumber=~w",["查询到的符合条件的物品列表的总数不合材料要求的数量",H,MNumber,GNumber]),
                    get_material_match_goods(T,GoodsList,false,Result)
            end   
    end.

%% 在物品列表中查询符合条件的物品
%% 参数
%% Type 材料道具类型
%% ItemIds 材料类型id列表，或是那种材料列表
%% FFItem 炼制方案材料 r_forging_formula_item
%% GoodsList 符合条件的物品 [p_goods]
%% 返回符合条件的物品列表  [p_goods] or []
get_refining_forging_goods_by_material(
  ?REFINING_FORGING_MATERIAL_TYPE_ITEM,GoodsList,FFItem,ItemIds)->
    if erlang:length(ItemIds) =:= 1 ->
            [ItemId] = ItemIds,
            lists:foldl(
              fun(Goods,Acc) ->
                      if Goods#p_goods.typeid =:= ItemId ->
                              case check_goods_by_formula_material(Goods,FFItem) of
                                  true ->
                                      [Goods|Acc];
                                  false ->
                                      Acc
                              end;
                         true ->
                              Acc
                      end
              end,[],GoodsList);
       true ->
            []
    end;
get_refining_forging_goods_by_material(
  ?REFINING_FORGING_MATERIAL_TYPE_CLASS,GoodsList,FFItem,ItemIds) ->
    if erlang:length(ItemIds) =:= 1 ->
            [ItemType] = ItemIds,
            lists:foldl(
              fun(Goods,Acc) ->
                      Type = Goods#p_goods.type,
                      if Type =:= ItemType ->
                              case check_goods_by_formula_material(Goods,FFItem) of
                                  true ->
                                      [Goods|Acc];
                                  false ->
                                      Acc
                              end;
                         true ->
                              Acc
                      end
              end,[],GoodsList);
       true ->
            []
    end;
get_refining_forging_goods_by_material(
  ?REFINING_FORGING_MATERIAL_TYPE_CUSTOM,GoodsList,FFItem,ItemIds) ->
    %% ?DEBUG("~ts,GoodsList=~w,FFItem=~w,ItemIds=~w",["自定义分类物品查询",GoodsList,FFItem,ItemIds]),
    lists:foldl(
      fun(Goods,Acc) ->
              TypeId = Goods#p_goods.typeid,
              case lists:member(TypeId,ItemIds) of
                  true ->
                      case check_goods_by_formula_material(Goods,FFItem) of
                          true ->
                              [Goods|Acc];
                          false ->
                              Acc
                      end;
                  false ->
                      Acc
              end
      end,[],GoodsList);
get_refining_forging_goods_by_material(
  ?REFINING_FORGING_MATERIAL_TYPE_NORMAL,GoodsList,FFItem,ItemIds) ->
    if erlang:length(ItemIds) =:= 1 ->
            [TypeValue] = ItemIds,
            lists:foldl(
              fun(Goods,Acc) ->
                      TypeId = Goods#p_goods.typeid,
                      case common_config_dyn:find_item(TypeId) of 
                          [] ->
                              Acc;
                          [BaseItemInfo] ->
                              Kind = BaseItemInfo#p_item_base_info.kind,
                              if TypeValue =:= Kind ->
                                      case check_goods_by_formula_material(Goods,FFItem) of
                                          true ->
                                              [Goods|Acc];
                                          false ->
                                              Acc
                                      end;
                                 true ->
                                      Acc
                              end
                      end
              end,[],GoodsList);
       true ->
            []
    end;
get_refining_forging_goods_by_material(Type,GoodsList,FFItem,ItemIds) ->
    ?DEBUG("~ts,Type=~w,GoodsList=~w,FFItem=~w,ItemIds=~w",
           ["在物品列表中查询符合条件的物品参数出错",Type,GoodsList,FFItem,ItemIds]),
    [].
    
%% 检查某件物品是否符合条件，除了物品个数暂不判断外
%% 检查所有的条件
%% 参数
%% Goods 物品 p_goods
%% FFItem 材料方案 r_forging_formula_item
%% 返回结果 true or false
check_goods_by_formula_material(Goods,FFItem) ->
    case catch check_goods_by_formula_material2(Goods,FFItem) of
        {error,Reason} ->
            ?DEBUG("~ts,Goods=~w,FFItem=~w,Reason=~w",["此物品不符合此材料方案配置要求",Goods,FFItem,Reason]),
            false;
        {ok} ->
            true
    end.
check_goods_by_formula_material2(Goods,FFItem) ->
    Type = Goods#p_goods.type,
    TypeId = Goods#p_goods.typeid,
    case lists:member(Type,?ITEM_TYPE_LIST) of
        true ->
            next;
        false ->
            ?DEBUG("~ts,Type=~w",["物品类型不合法",Type]),
            erlang:throw({error,type})
    end,
    %% 检查洗炼
    MBind = FFItem#r_forging_formula_item.bind,
    GBind = Goods#p_goods.bind,
    %% bind 洗炼类型 1 洗炼，2 不洗炼，3 不要求
    if MBind =:= 1 andalso GBind =:= true ->
            next;
       MBind =:= 2 andalso GBind =:= false ->
            next;
       MBind =:= 3 ->
            next;
       true ->
            ?DEBUG("~ts,MBind=~w,GBind=~w",["洗炼不合法",MBind,GBind]),
            erlang:throw({error,bind})
    end,
    %% 检查级别
    MinLevel = FFItem#r_forging_formula_item.min_level,
    MaxLevel = FFItem#r_forging_formula_item.max_level,
    Level = Goods#p_goods.level,
    if MinLevel =:= 0 
       orelse Level >= MinLevel ->
            next;
       true ->
            ?DEBUG("~ts,MinLevel=~w,Level=~w",["最小级别不合法",MinLevel,Level]),
            erlang:throw({error,min_level})
    end,
    if MaxLevel =:= 0
       orelse MaxLevel >= Level ->
            next;
       true ->
            ?DEBUG("~ts,MaxLevel=~w,Level=~w",["最大级别不合法",MaxLevel,Level]),
            erlang:throw({error,max_level})
    end,
    %% 如果是装备物品的检查
    if Type =:= ?TYPE_EQUIP ->
            MColor = FFItem#r_forging_formula_item.color,
            MQuality = FFItem#r_forging_formula_item.quality,
            MinIndex = FFItem#r_forging_formula_item.min_index,
            MaxIndex = FFItem#r_forging_formula_item.max_index,
            MSlots = FFItem#r_forging_formula_item.slots,
            GColor = Goods#p_goods.current_colour,
            GQuality = Goods#p_goods.quality,
            RefiningIndex =  Goods#p_goods.refining_index,
            GSlot = 
                case common_config_dyn:find_equip(TypeId) of
                    [] ->
                        ?DEBUG("~ts,TypeId=~w",["装备基本信息不合法",TypeId]),
                        erlang:throw({error,type_id});
                    [EquipBaseInfo] ->
                        EquipBaseInfo#p_equip_base_info.slot_num
                end,
            %% 检查颜色
            case lists:member(GColor,MColor) of
                true ->
                    next;
                false ->
                    ?DEBUG("~ts,MColor=~w,GColor=~w",["颜色不合法",MColor,GColor]),
                    erlang:throw({error,color})
            end,
            %% 检查品质
            case lists:member(GQuality,MQuality) of
                true ->
                    next;
                false ->
                    ?DEBUG("~ts,MQuality=~w,GQuality=~w",["品质不合法",MQuality,GQuality]),
                    erlang:throw({error,quality})
            end,
            %% 检查精炼系数
            if MinIndex =:= 0
               orelse RefiningIndex >= MinIndex ->
                    next;
               true ->
                    ?DEBUG("~ts,MinIndex=~w,RefiningIndex=~w",["最小精炼系数不合法",MinIndex,RefiningIndex]),
                    erlang:throw({error,min_index})
            end,
            if MaxIndex =:= 0 
               orelse MaxIndex >= RefiningIndex ->
                    next;
               true ->
                    ?DEBUG("~ts,MaxIndex=~w,RefiningIndex=~w",["最大精炼系数不合法",MaxIndex,RefiningIndex]),
                    erlang:throw({error,max_index})
            end,
            %% 检查部位
            case lists:member(GSlot,MSlots) of
                true ->
                    next;
                false ->
                    ?DEBUG("~ts,MSlots=~w,GSlot=~w",["部位不合法",MSlots,GSlot]),
                    erlang:throw({error,slot})
            end;
       true ->
            next
    end,
    {ok}.

%% 根据材料记录结构获取材料的类型id列表
%% 参数：
%% FFItem 材料记录 r_forging_formula_item
%% 返回结果为{ok,Type,[typeid]} or {ok,Type,[GoodsType]}or {error,Reason}
get_refining_forging_material_type_ids(FFItem) ->
    Type = FFItem#r_forging_formula_item.type,
    TypeValue = FFItem#r_forging_formula_item.type_value,
    case Type of
        ?REFINING_FORGING_MATERIAL_TYPE_ITEM ->
            {ok,Type,[TypeValue]};
        ?REFINING_FORGING_MATERIAL_TYPE_CLASS ->
            case lists:member(TypeValue,?ITEM_TYPE_LIST) of
                true ->
                    {ok,Type,[TypeValue]};
                false ->
                    {error,class_type_not_valid}
            end;
        ?REFINING_FORGING_MATERIAL_TYPE_CUSTOM ->
            get_refining_forging_material_type_ids2(FFItem);
        ?REFINING_FORGING_MATERIAL_TYPE_NORMAL ->
            [NormalClassList] = common_config_dyn:find(refining,normal_class_list),
            case lists:member(TypeValue,NormalClassList) of
                true ->
                    {ok,Type,[TypeValue]};
                false ->
                    {error,normal_value_not_valid}
            end;
        _ ->
            {error,type_not_valid}
    end.
get_refining_forging_material_type_ids2(FFItem) ->
    Type = FFItem#r_forging_formula_item.type,
    TypeValue = FFItem#r_forging_formula_item.type_value,
    case mod_forging_config:find(?REFINING_FORGING_CUSTOM,TypeValue) of
        undefined ->
            {error,custom_not_found};
        ForgingCustom ->
            %% ?DEBUG("~ts,ForgingCustom=~w",["此材料是自定义类型，自定义类型的记录为",ForgingCustom]),
            %% r_forging_custom
            ItemIds = ForgingCustom#r_forging_custom.item_ids,
            if erlang:is_list(ItemIds)
               andalso erlang:length(ItemIds) > 0 ->
                    {ok,Type,ItemIds};
               true ->
                    {error,custom_data_not_valid}
            end
    end.
        
%% 根据炼制的方案生成物品
%% 参数：
%% FFRecord 炼制方案 r_forging_formula
%% RoleId 角色id
%% 返回结果为 {ok,[p_goods]} or {ok,[]} or {error,Reason}
t_create_refining_forging(RoleId,GoodsList,FFRecord) ->
    GoodsIdList = [R#p_goods.id || R <- GoodsList],
    mod_bag:delete_goods(RoleId,GoodsIdList),
    FFProductList = FFRecord#r_forging_formula.products,
    if FFProductList =:= [] ->
            ?DEBUG("~ts,FFProducts=~w",["此炼制方案的永远不会产生物品，蛋疼的配置",FFProductList]),
            {ok,[],undefined};
       erlang:length(FFProductList) =:= 1 ->
            [FFProduct] = FFProductList,
            t_create_refining_forging2(RoleId,GoodsList,FFRecord,FFProduct);
       true ->
            t_create_refining_forging2(RoleId,GoodsList,FFRecord,FFProductList)
    end.

t_create_refining_forging2(RoleId,GoodsList,FFRecord,FFProductList) 
  when erlang:is_list(FFProductList) ->
    %% 炼制方案炼制获得的物品配置有多个处理
    PDataList = [FFR#r_forging_formula_item.succ_probability || FFR <- FFProductList],
    [HFFProduct|_T] = FFProductList,
    ResultWeight = HFFProduct#r_forging_formula_item.result_weight,
    Index = get_forginig_random_result_by_probability(ResultWeight,PDataList),
    if Index > 0 andalso Index =< erlang:length(PDataList) ->
            FFProduct = lists:nth(Index,FFProductList),
            t_create_refining_forging3(RoleId,GoodsList,FFRecord,FFProduct);
       true ->
            ?DEBUG("~ts",["炼制创建物品时，根据多个物品生成配置结果计算不需要创建物品，即炼制失败，扣除物品"]),
            {ok, [], undefined}
    end;
t_create_refining_forging2(RoleId,GoodsList,FFRecord,FFProduct) 
  when erlang:is_record(FFProduct,r_forging_formula_item)->
    Type = FFProduct#r_forging_formula_item.type,
    if Type =:= ?REFINING_FORGING_MATERIAL_TYPE_ITEM ->
            case get_result_type_by_forginig_formula(FFProduct) of
                true ->
                    t_create_refining_forging3(RoleId,GoodsList,FFRecord,FFProduct);
                false ->
                    ?DEBUG("~ts",["炼制创建物品时，根据结果计算不需要创建物品，即炼制失败，扣除物品"]),
                    {ok, [],undefined}
            end;
       true ->
            ?DEBUG("~ts,RoleId=~w,FFProduct=~w",["炼制创建物品失败，物品配置方案中类型出错",RoleId,FFProduct]),
            erlang:throw({error,?_LANG_REINFORCE_FORGING_ERROR})
    end;
t_create_refining_forging2(RoleId,_GoodsList,FFRecord,_FFProducts) ->
    ?DEBUG("~ts,RoleId=~w,FFRecord=~w",["炼制创建物品参数错误，炼制失败",RoleId,FFRecord]),
    erlang:throw({error,?_LANG_REINFORCE_FORGING_ERROR}).

%% 创建物品
t_create_refining_forging3(RoleId,GoodsList,_FFRecord,FFProduct) ->
    ItemType = 
        case get_type_by_forginig_formula(FFProduct) of
            {ok,ItemTypeT} ->
                ItemTypeT;
            {error,Reason} ->
                ?DEBUG("~ts,FFProduct=~w,Reason=~w",["根据炼制方案获取炼制获取的物品的类型不合法",FFProduct,Reason]),
                erlang:throw({error,?_LANG_REINFORCE_FORGING_ERROR})
        end,
    CreateInfo = 
        if ItemType =:= ?TYPE_EQUIP ->
                #r_goods_create_info{
                           type = ItemType,
                           type_id = FFProduct#r_forging_formula_item.type_value,
                           num = FFProduct #r_forging_formula_item.item_num,
                           bind = get_bind_by_forginig_formula(GoodsList,FFProduct),
                           color = get_color_by_forginig_formula(FFProduct),
                           quality = get_quality_by_forginig_formula(FFProduct),         
                           interface_type = refining_forging};
           true ->
                #r_goods_create_info{
             type = ItemType,
             type_id = FFProduct#r_forging_formula_item.type_value,
             num = FFProduct #r_forging_formula_item.item_num,
             bind = get_bind_by_forginig_formula(GoodsList,FFProduct)}
        end,
    {ok, NewGoodsList} = mod_bag:create_goods(RoleId,?REFINING_BAGID,CreateInfo),
    {ok, NewGoodsList, FFProduct}.

%% 根据炼制方案的获取物品配置结果计算是否需要创建物品
%% FFProduct 炼制获得的物品配置 r_forging_formula_item
%% 返回 true or false
get_result_type_by_forginig_formula(FFProduct) ->
    ResultWeight = FFProduct#r_forging_formula_item.result_weight,
    SuccProbability = FFProduct#r_forging_formula_item.succ_probability,
    RandomNumber = random:uniform(ResultWeight),
    if RandomNumber =< SuccProbability ->
            true;
       true ->
            false
    end.

%% 根据炼制获取的物品方案的物品id查询该物品的类型 1,材料，2，宝石，3，装备
%% FFProduct 炼制获得的物品配置 r_forging_formula_item
%% 返回 {ok,ItemType} or {error,Reason}
get_type_by_forginig_formula(FFProduct) ->
    TypeValue = FFProduct#r_forging_formula_item.type_value,
    %% Result 结构为 [{ItemType,FindList},]
    Result =[{?TYPE_ITEM,common_config_dyn:find_item(TypeValue)},
             {?TYPE_STONE,common_config_dyn:find_stone(TypeValue)},
             {?TYPE_EQUIP,common_config_dyn:find_equip(TypeValue)}],
    lists:foldl(
      fun({ItemType,FindList},Acc) ->
              {Flag,_AccType} = Acc,
              case Flag of 
                  ok ->
                      Acc;
                  _ ->
                      if FindList =/= [] ->
                              {ok,ItemType};
                         true ->
                              Acc
                      end
              end
      end,{error,not_found_item_type},Result).

%% 获取炼制时使用的材料洗炼情况
%% 参数
%% GoodsList 炼制的物品列表 [p_goods]
%% FFProduct 炼制获得的物品配置 r_forging_formula_item
%% 返回 true or false
get_bind_by_forginig_formula(GoodsList,FFProduct) ->
    %%bind 洗炼类型 1 洗炼，2 不洗炼，4 根据材料
    FFBind = FFProduct#r_forging_formula_item.bind,
    if FFBind =:= 1 ->
            true;
       FFBind =:= 2 ->
            false;
       true ->
            lists:foldl(
              fun(Goods,AccBind) ->
                      case AccBind of
                          true ->
                              AccBind;
                          false ->
                              Goods#p_goods.bind
                      end
              end,false,GoodsList)
    end.
%% 获取炼制时装备的颜色值
%% 参数
%% DataList 配置各权值列表 [0,1,0,0,0,0] or [10,20,80,0,0,0]
%% 返回 1,2,3,4,5,6其它中的一个
get_color_by_forginig_formula(FFProduct) ->
    ColorList = FFProduct#r_forging_formula_item.color,
    mod_refining:get_random_number(ColorList,0,1).

%% 获取炼制时装备的品质
%% 参数
%% DataList 配置各权值列表 [0,1,0,0,0] or [10,20,80,0,0]
%% 返回 1,2,3,4,5其它中的一个
get_quality_by_forginig_formula(FFProduct) ->
    QualityList = FFProduct#r_forging_formula_item.quality,
    mod_refining:get_random_number(QualityList,0,1).

%% 根据总的概率和概率列表计算命中那一个概率
%% 成功命中那一个概率即返回 DataList 对应原下标
%% 失败即返回-1
get_forginig_random_result_by_probability(SumProbability,DataList) ->
    mod_refining:get_random_number(DataList,SumProbability,-1).

%% 炼制成功通知消息处理
%% 参数
%% GoodsList 消耗的物品 [p_goods]
%% NewGoodsList 获取的物品 [p_goods]
%% FFProduct 炼制方案 r_forging_formula_item
%% 不需要处理返回结果
do_refining_forging_notify(RoleId,FFProduct,GoodsList,NewGoodsList) ->
    %% is_broadcast 是否广播，0 不广播 1 广播
    if FFProduct#r_forging_formula_item.is_broadcast =:= 1 
       andalso NewGoodsList =/= [] ->
            case mod_map_actor:get_actor_mapinfo(RoleId,role) of
                undefined ->
                    ignore;
                MapRoleInfo ->
                    do_refining_forging_notify2(RoleId,GoodsList,NewGoodsList,MapRoleInfo)
            end;
       true ->
            ignore
    end.

do_refining_forging_notify2(_RoleId,_GoodsList,NewGoodsList,MapRoleInfo) ->
    FactionId = MapRoleInfo#p_map_role.faction_id,
    FactionName = 
        if FactionId =:= 1 ->
                lists:append(["<font color=\"#00FF00\">",
                              common_tool:to_list(?_LANG_FACTION_CONST_1),
                              "</font>"]);
           FactionId =:= 2 ->
                lists:append(["<font color=\"#F600FF\">",
                              common_tool:to_list(?_LANG_FACTION_CONST_2),
                              "</font>"]);
           FactionId =:= 3 ->
                lists:append(["<font color=\"#00CCFF\">",
                              common_tool:to_list(?_LANG_FACTION_CONST_3),
                              "</font>"]);
           true ->
                ""
        end,
    RoleName = common_tool:to_list(MapRoleInfo#p_map_role.role_name),
    GoodsName = 
        lists:foldl(
          fun(Goods,Acc) ->
                  lists:concat([Acc," ",common_goods:get_notify_goods_name(Goods)])
          end,"",NewGoodsList),
    LeftMessage = lists:flatten(io_lib:format(?_LANG_REINFORCE_FORGING_SUCC,[FactionName,RoleName,GoodsName])),
    catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,LeftMessage).
