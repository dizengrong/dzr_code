%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2010, 
%%% @doc
%%% 商贸活动模块处理代码
%%% @end
%%% Created : 25 Dec 2010 by  <caochuncheng>
%%%-------------------------------------------------------------------
-module(mod_trading).


-include("mgeem.hrl").
-include("trading.hrl").

%% API
-export([
         %% 地图初始化时，商贸活动初始化
         init/2,
         %% 地图循环处理函数，即一秒循环
         loop/1
        ]).

-export([
         do_handle_info/1,handle/1,handle/2, send_trading_begin_broadcast/0
        ]).

-export([
         %% 处理玩家销毁道具处理 这方法必须在事务中调用
         hook_t_drop_trading_bill_item/2,
         %% 处理玩家销毁道具处理，是用来记录玩家商贸日志
         hook_drop_trading_bill_item/2,
         %% 玩家进入地图相关商贸信息初始化
         hook_first_enter_map/2,
         %% 当玩家在商贸活动过程中死亡时，删除商票
         hook_role_dead/3,
         %% 手工取消玩家不合法商贸状态
         cancel_role_trading_state/1,
         %% 当地图创建启动完成之后初始化商贸商店信息
         %% hook_start_all_map/0
		 %%获取玩家商贸状态
		 get_role_trading_state/1
        ]).

%%%===================================================================
%%% API
%%%===================================================================
handle(Info,_State)->
  handle(Info).
handle(Info) ->
    do_handle_info(Info).

%% 地图初始化时，商贸活动初始化
%% 参数：
%% MapId 地图id
%% MapName 地图进程名称
init(MapId, MapName) ->
    case get_is_open_trading() of
        true ->
            init2(MapId, MapName);
        false ->
            ignore
    end.

init2(MapId, MapName) ->
    TradingShopList= get_trading_shop_info(),
    TradingShopList2 = 
        lists:foldl(
          fun(TSI,Acc) ->
                  VMapId = TSI#r_trading_shop_info.map_id,
                  if VMapId =:= MapId ->
                          [TSI|Acc];
                     true ->
                          Acc
                  end
          end,[],TradingShopList),
    if TradingShopList2 =:= [] ->
            ignore;
       true ->
            mod_trading_common:put_trading_shop_init_status(MapId,?TRADING_SHOP_INIT_STATUS_FALSE)
    end,
    init3(MapId, MapName).

init3(MapId, _MapName) ->
    CalcMapId = get_trading_shop_godds_price_map_id(),
    Interval = get_goods_price_update_interval(),
    if MapId =:= CalcMapId ->
            erlang:send_after(Interval,self(),{mod_trading,{check_init_trading_shop}});
       true ->
            ignore
    end.

%% 地图循环处理函数，即一秒循环
%% 参数
%% MapId 地图id
loop(MapId) ->
    case get_is_open_trading() of
        true ->
            loop2(MapId);
        false ->
            ignore
    end.
loop2(MapId) ->
    Status = mod_trading_common:get_trading_shop_init_status(MapId),
    if Status =:= ?TRADING_SHOP_INIT_STATUS_TRUE ->
            NowSeconds = common_tool:now(),
            ?DEV("~ts,NowSeconds=~w",["地图一秒循环时，执行到商贸模块时，时间为",NowSeconds]),
            TradingShopList= get_trading_shop_info(),
            TradingShopList2 = 
                lists:foldl(
                  fun(TSI,Acc) ->
                          VMapId = TSI#r_trading_shop_info.map_id,
                          if VMapId =:= MapId ->
                                  [TSI|Acc];
                             true ->
                                  Acc
                          end
                  end,[],TradingShopList),
            if TradingShopList2 =:= [] ->
                    ignore;
               true ->
                    loop3(MapId,NowSeconds,TradingShopList2)
            end;
       true ->
            next
    end.
%% TradingShopList 结构为 [r_trading_shop_info]
loop3(MapId,NowSeconds,TradingShopList) ->
    CalcMapId = get_trading_shop_godds_price_map_id(),
    if MapId =:= CalcMapId ->
            %% 是否需要发送商贸消息广播（宗族商贸日广播）
            case check_trading_broadcast_message(MapId,NowSeconds) of
                true ->
                    send_trading_broadcast_message(MapId,NowSeconds);
                false ->
                    next
            end,
            %% 通知商贸开始的广播
            check_and_do_trading_begin_broadcast(NowSeconds),
            %% 是否需要发送商贸消息广播（商贸结束广播）
            case check_trading_end_broadcast_message(MapId,NowSeconds) of
                true ->
                    send_trading_end_broadcast_message(MapId,NowSeconds);
                false ->
                    next
            end,
            case check_reload_trading_shop_goods_price(MapId,NowSeconds) of
                true ->
                    %% 刷新价格，这时最佳商线会变化，需要控制不要重复刷新
                    [IsOpenChangePrice] = common_config_dyn:find(?TRADING_CONFIG,is_open_change_price),
                    case IsOpenChangePrice of
                        true ->
                            reload_trading_shop_goods_price();
                        _ ->
                            next
                    end;
                false ->
                    next
            end;
       true ->
            next
    end,
    loop4(MapId,NowSeconds,TradingShopList).

loop4(MapId,NowSeconds,TradingShopList) ->
    UpdatePriceTime = mod_trading_common:get_next_goods_price(MapId),
    UpdateNumberTime = mod_trading_common:get_next_goods_number(MapId),
    %% 如果当前时间这变化时间
    if NowSeconds >= UpdatePriceTime ->
            %% 需要更新物品价格
            [IsOpenChangePrice] = common_config_dyn:find(?TRADING_CONFIG,is_open_change_price),
            case IsOpenChangePrice of
                true ->
                    update_trading_shop_goods_price(MapId,NowSeconds,TradingShopList);
                _ ->
                    ignore
            end;
       true ->
            ignore
    end,
    if NowSeconds >= UpdateNumberTime ->
            %% 需要更新物品数量
            update_trading_shop_goods_number(MapId,NowSeconds,TradingShopList);
       true ->
            ignore
    end,
    ok.
 
check_and_do_trading_begin_broadcast(NowSeconds) ->
    {_NowDate, {HH, MM, SS}} = common_tool:seconds_to_datetime(NowSeconds),
    case HH == 13 andalso MM == 0 andalso SS == 0 of
        true ->
            send_trading_begin_broadcast();
            
        false -> ignore
    end,
    ok.

send_trading_begin_broadcast() ->
    ?WORLD_CENTER_BROADCAST(?_LANG_TRADING_START),
    ?WORLD_CHAT_BROADCAST(?_LANG_TRADING_START).

%% 刷新价格，这时最佳商线会变化，需要控制不要重复刷新
reload_trading_shop_goods_price() ->
    TradingShopList= get_trading_shop_info(),
    %% 商店的初始化物品价格记录  [r_trading_shop_price] or []
    ShopPriceList = get_trading_shop_price(),
    lists:foreach(
      fun(TradingShop) ->
              MapId = TradingShop#r_trading_shop_info.map_id,
              MapProcessName = common_map:get_common_map_name(MapId),
              catch global:send(MapProcessName,{mod_trading,{init_trading_shop,ShopPriceList}})
      end,TradingShopList),
    ok.
%% 需要更新物品价格
%% 参数
%% MapId 地图id
%% NowSeconds 当前时间秒数
%% TradingShopList 结构为 [r_trading_shop_info]
update_trading_shop_goods_price(MapId,NowSeconds,TradingShopList) ->
    PriceInterval = get_goods_price_update_interval(),
    UpdatePriceTime = NowSeconds + PriceInterval,
    mod_trading_common:put_next_goods_price(MapId,UpdatePriceTime),
    lists:foreach(
      fun(TradingShopInfo) ->
              NpcId = TradingShopInfo#r_trading_shop_info.npc_id,
              ShopGoodsInfo = mod_trading_common:get_shop_goods(MapId,NpcId),
              GoodsList = ShopGoodsInfo#r_trading_shop_goods.goods,
              CPIndex = ShopGoodsInfo#r_trading_shop_goods.current_price_index,
              {GoodsList2,CPIndex2} = 
                  lists:foldl(
                    fun(Goods,Acc) ->
                            {AccList,_AccIndex} = Acc,
                            %% p_trading_goods
                            TypeId = Goods#p_trading_goods.type_id,
                            %% p_trading_goods_base_info
                            GoodsBaseInfo = mod_trading_config:find(?TRADING_GOODS_CONFIG,TypeId),
                            Prices = GoodsBaseInfo#p_trading_goods_base_info.prices,
                            Index = if CPIndex >= erlang:length(Prices) ->
                                            1;
                                       true ->
                                            CPIndex + 1
                                    end,
                            Price = lists:nth(Index,Prices),
                            {[Goods#p_trading_goods{price = Price}|AccList],Index}
                    end,{[],CPIndex},GoodsList),
              ShopGoodsInfo2 = ShopGoodsInfo#r_trading_shop_goods{
                                 goods = GoodsList2, 
                                 current_price_index = CPIndex2,
                                 current_seconds = NowSeconds},
              mod_trading_common:put_shop_goods(MapId,NpcId,ShopGoodsInfo2)
      end,TradingShopList),
    ok.

%% 需要更新物品数量
%% 参数
%% MapId 地图id
%% NowSeconds 当前时间秒数
%% TradingShopList 结构为 [r_trading_shop_info]
update_trading_shop_goods_number(MapId,NowSeconds,TradingShopList) ->
    NumberInterval = get_goods_number_update_interval(),
    UpdateNumberTime = NowSeconds + NumberInterval,
    mod_trading_common:put_next_goods_number(MapId,UpdateNumberTime),
    lists:foreach(
      fun(TradingShopInfo) ->
              NpcId = TradingShopInfo#r_trading_shop_info.npc_id,
              ShopGoodsInfo = mod_trading_common:get_shop_goods(MapId,NpcId),
              GoodsList = ShopGoodsInfo#r_trading_shop_goods.goods,
              GoodsList2 = 
                  lists:foldl(
                    fun(Goods,Acc) ->
                            %% p_trading_goods
                            TypeId = Goods#p_trading_goods.type_id,
                            %% p_trading_goods_base_info
                            GoodsBaseInfo = mod_trading_config:find(?TRADING_GOODS_CONFIG,TypeId),
                            GoodsNumber = GoodsBaseInfo#p_trading_goods_base_info.number,
                            [Goods#p_trading_goods{number = GoodsNumber}|Acc]
                    end,[],GoodsList),
              ShopGoodsInfo2 = ShopGoodsInfo#r_trading_shop_goods{
                                 goods = GoodsList2,
                                 current_seconds = NowSeconds},
              mod_trading_common:put_shop_goods(MapId,NpcId,ShopGoodsInfo2)
      end,TradingShopList),
    ok.



%% 获取商贸商店信息接口
do_handle_info({Unique, ?TRADING, ?TRADING_SHOP, DataRecord, RoleId, PId, Line})
  when erlang:is_record(DataRecord,m_trading_shop_tos)->
    do_trading_shop({Unique, ?TRADING, ?TRADING_SHOP, DataRecord, RoleId, PId, Line});

%% 商贸商店购买物品接口
do_handle_info({Unique, ?TRADING, ?TRADING_BUY, DataRecord, RoleId, PId, Line})
  when erlang:is_record(DataRecord,m_trading_buy_tos)->
    do_trading_buy({Unique, ?TRADING, ?TRADING_BUY, DataRecord, RoleId, PId, Line});

%% 玩家出售商贸货舱物品接口
do_handle_info({Unique, ?TRADING, ?TRADING_SALE, DataRecord, RoleId, PId, Line})
  when erlang:is_record(DataRecord,m_trading_sale_tos)->
    do_trading_sale({Unique, ?TRADING, ?TRADING_SALE, DataRecord, RoleId, PId, Line});

%% 领取商贸商票接口
do_handle_info({Unique, ?TRADING, ?TRADING_GET, DataRecord, RoleId, PId, Line}) 
  when erlang:is_record(DataRecord,m_trading_get_tos)->
    do_trading_get({Unique, ?TRADING, ?TRADING_GET, DataRecord, RoleId, PId, Line});

%% 交还商贸商票接口
do_handle_info({Unique, ?TRADING, ?TRADING_RETURN, DataRecord, RoleId, PId, Line})
  when erlang:is_record(DataRecord,m_trading_return_tos)->
    do_trading_return({Unique, ?TRADING, ?TRADING_RETURN, DataRecord, RoleId, PId, Line});

%% 兑换商贸宝典物品接口
do_handle_info({Unique, ?TRADING, ?TRADING_EXCHANGE, DataRecord, RoleId, PId, Line})
  when erlang:is_record(DataRecord,m_trading_exchange_tos)->
    do_trading_exchange({Unique, ?TRADING, ?TRADING_EXCHANGE, DataRecord, RoleId, PId, Line});

%% 获取玩家的商贸状态
do_handle_info({Unique, ?TRADING, ?TRADING_STATUS, DataRecord, RoleId, PId, Line}) ->
    do_trading_status({Unique, ?TRADING, ?TRADING_STATUS, DataRecord, RoleId, PId, Line});

%% 商贸活动内部消息处理
%% 更新商贸活动配置文件
%% erlang:send_after(Interval,self(),{mod_trading,{reload_trading_config,Type}})
%% 更新商贸活动配置文件 all,trading trading_goods
do_handle_info({reload_trading_config,Type}) ->
    do_reload_trading_config(Type);
%% 检查是否可以初始化地图商贸商店信息
%% 所有地图进程都启动完成
%% erlang:send_after(Interval,self(),{mod_trading,{check_init_trading_shop}});
do_handle_info({check_init_trading_shop}) ->
    do_check_init_trading_shop();

%% 更新玩家商贸商票信息
%% global:send(MapProcessName,{mod_trading,{update_role_trading,RoleId,RoleTrading}})
do_handle_info({update_role_trading,RoleId,RoleTrading}) ->
    do_update_role_trading(RoleId,RoleTrading);

%% 发送商贸广播消息处理
%% erlang:send_after(Interval,self(),{mod_trading,{send_broadcast_message,StartSeconds,EndSeconds,Interval}})
do_handle_info({send_broadcast_message,StartSeconds,EndSeconds,Interval}) ->
    ?DEV("~ts,StartSeconds=~w,EndSeconds=~w,Interval=~w",["发送商贸消息广播",StartSeconds,EndSeconds,Interval]),
    do_send_broadcast_message(StartSeconds,EndSeconds,Interval);

%% 获取玩家商贸状态信息消息处理
%% global:send(MapProcessName,{mod_trading,{get_role_trading_status,RoleId, PId}})
do_handle_info({get_role_trading_status, RoleId, PId}) ->
    do_get_role_trading_status(RoleId, PId);

%% 删除玩家商贸活动消息处理
%% global:send(MapProcessName,{mod_trading,{delete_role_trading,RoleId,RoleMapInfo,TradingStatus}})
do_handle_info({delete_role_trading, RoleId, RoleMapInfo, TradingStatus}) ->
    do_delete_role_trading(RoleId, RoleMapInfo, TradingStatus);

%% 初始化商贸商店信息消息处理
%% ShopPriceList 结构为 [r_trading_shop_price] or []
do_handle_info({init_trading_shop,ShopPriceList}) ->
    ?DEV("~ts,ShopPriceList=~w",["接收到的初始化商住商店信息",ShopPriceList]),
    do_init_trading_shop(ShopPriceList);
do_handle_info({role_dead,RoleId,RoleMapInfo,SrcActorId,SrcActorType}) ->
	do_role_dead(RoleId,RoleMapInfo,SrcActorId,SrcActorType);
do_handle_info({drop_trading_bill_item,RoleId,TypeId})->
	do_drop_trading_bill_item(RoleId,TypeId);
do_handle_info({t_drop_trading_bill_item,RoleId,TypeId})->
	db:transaction(fun()->do_t_drop_trading_bill_item(RoleId,TypeId) end);
do_handle_info(Info) ->
    ?ERROR_MSG("~ts,Info=~w",["商贸活动模块无法处理此消息",Info]),
    error.
%%玩家死亡处理
do_role_dead(RoleId,RoleMapInfo,SrcActorId,SrcActorType) ->
	case db:transaction(
		   fun() -> 
				   t_hook_role_dead(RoleId)
		   end) of
		{atomic,{ok,UpdateGoodsList,DeleteGoodsList}} ->
			hook_role_dead2(RoleId,RoleMapInfo,UpdateGoodsList,DeleteGoodsList),
			hook_role_dead_letter(RoleId,RoleMapInfo,SrcActorId,SrcActorType);
		{aborted, Reason} ->
			case Reason of 
				not_trading_status ->
					ignore;
				_ ->
					?ERROR_MSG("~ts,Reason=~w",["任务死亡时，处理商贸状态，删除商贸商票时出错",Reason])
			end
	end.
%% 获取商贸商店信息接口
%% DataRecord 结构为 m_trading_shop_tos
do_trading_shop({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_trading_shop2({Unique, Module, Method, DataRecord, RoleId, PId, Line}) of
        {error,Reason} ->
            do_trading_shop_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason);
        {ok,ShopInfo} ->
            do_trading_shop3({Unique, Module, Method, DataRecord, RoleId, PId, Line},ShopInfo)
    end.
do_trading_shop2({_Unique, _Module, _Method, DataRecord, RoleId, _PId, _Line}) ->
    case get_is_open_trading() of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_TRADING_NOT_OPENT})
    end,
    MapId = DataRecord#m_trading_shop_tos.map_id,
    NpcId = DataRecord#m_trading_shop_tos.npc_id,
    CurMapId = mgeem_map:get_mapid(),
    if MapId =:= CurMapId ->
            next;
       true ->
            ?ERROR_MSG("~ts,DataRecord=~w,CurMapId=~w",["参数错误map_id",DataRecord,CurMapId]),
            erlang:throw({error,?_LANG_TRADING_SHOP_PARAM_ERROR})
    end,
    %% 检查玩家是否在NPC附近
    case check_valid_distance(RoleId,NpcId) of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_TRADING_NOT_VALID_DISTANCE})
    end,
%%     RoleMapInfo = 
%%         case mod_map_actor:get_actor_mapinfo(RoleId,role) of
%%             undefined ->
%%                 ?ERROR_MSG("~ts",["在本地图获取不到玩家的地图信息"]),
%%                 erlang:throw({error,?_LANG_TRADING_SHOP_PARAM_ERROR});
%%             RoleMapInfoT ->
%%                 RoleMapInfoT
%%         end,
	{ok,RoleMapInfo} = mod_map_role:get_role_base(RoleId),
    %% 此地图是否是商贸商店存在的地图
    %% 返回[] or [r_trading_shop_info]
    FactionId = RoleMapInfo#p_role_base.faction_id,
    ShopInfoList = get_trading_shop_info_by_faction_id(FactionId),
    if ShopInfoList =:= [] ->
            ?ERROR_MSG("~ts",["玩家不在本国的商贸活动地图上操作"]),
            erlang:throw({error,?_LANG_TRADING_SHOP_NOT_VALID_FACTION});
       true ->
            next
    end,
    case lists:foldl(
           fun(ShopInfo,Acc) ->
                   if ShopInfo#r_trading_shop_info.map_id =:= MapId
                      andalso ShopInfo#r_trading_shop_info.npc_id =:=NpcId ->
                           true;
                      true ->
                           Acc
                   end
           end,false,ShopInfoList) of
        true ->
            next;
        false ->
            ?ERROR_MSG("~ts,DataRecord=~w",["根据map_id,npc_id,type_id相关信息在本地图查找不到相应的商贸商店信息",DataRecord]),
            erlang:throw({error,?_LANG_TRADING_SHOP_PARAM_ERROR})
    end,
    ShopInfo = 
        case mod_trading_common:get_shop_goods(MapId,NpcId) of
            undefined ->
                ?ERROR_MSG("~ts,MapId=~w,NpcId=~w",["此地图此NPC没有相关的商贸商店信息",MapId,NpcId]),
                erlang:throw({error,?_LANG_TRADING_SHOP_PARAM_ERROR});
            ShopInfoT ->
                ShopInfoT
        end,
    {ok,ShopInfo}.
%% ShopInfo 结构为 r_trading_shop_goods
do_trading_shop3({Unique, Module, Method, DataRecord, RoleId, PId, _Line},ShopInfo) ->
    MapId = DataRecord#m_trading_shop_tos.map_id,
    NpcId = DataRecord#m_trading_shop_tos.npc_id,
    %% 获取商店信息，计算最佳商贸时机，计算下次更新时间间隔，获取人物商贸信息
    RoleTradingInfo = 
        case mod_trading_common:get_role_trading(RoleId) of
            undefined ->
                #r_role_trading{role_id = RoleId,map_id = MapId,
                                 npc_id=NpcId,bill = 0,max_bill = 0,
                                 trading_times = 0,status = 0,
                                 start_time = common_tool:now(),
                                 last_bill = 0,
                                 end_time = common_tool:now(),
                                 goods = []};
            RoleTradingInfoT ->
                RoleTradingInfoT
        end,
    #r_trading_shop_goods{goods = ShopGoods,
                          current_price_index = CurPriceIndex,
                          %% 上次价格更新的时间
                          current_seconds = CurSeconds} = ShopInfo,
    NowSeconds = common_tool:now(),
    %% 计算出下次更新时间间隔
    UpdateTime = get_update_time_interval(MapId,NowSeconds),
    %% 根据当前价格索引和当前价格变化时间计算出最佳购买时间间隔和出售时间间隔
    {MaxBuyTime,MaxSaleTime} = get_max_interval_to_buy_or_sale(CurPriceIndex,CurSeconds,NowSeconds),
    SendSelf = #m_trading_shop_toc{
      succ = true,
      shop_goods = ShopGoods,
      max_buy_time = MaxBuyTime,
      max_sale_time = MaxSaleTime,
      role_goods = RoleTradingInfo#r_role_trading.goods,
      bill = RoleTradingInfo#r_role_trading.bill,
      max_bill = RoleTradingInfo#r_role_trading.max_bill,
      update_time = UpdateTime},
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

do_trading_shop_error({Unique, Module, Method, _DataRecord, _RoleId, PId, _Line},Reason) ->
    SendSelf = #m_trading_shop_toc{succ = false,reason = Reason,shop_goods = [],role_goods = []},
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

%% 商贸商店购买物品接口
%% DataRecord 结构为 m_trading_buy_tos
do_trading_buy({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_trading_buy2({Unique, Module, Method, DataRecord, RoleId, PId, Line}) of
        {error,Reason} ->
            do_trading_buy_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason);
        {ok,RoleMapInfo,ShopGoodsInfo,ShopGoods,RoleTrading} ->
            do_trading_buy3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                            RoleMapInfo,ShopGoodsInfo,ShopGoods,RoleTrading)
    end.
do_trading_buy2({_Unique, _Module, _Method, DataRecord, RoleId, _PId, _Line}) ->
    case get_is_open_trading() of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_TRADING_NOT_OPENT})
    end,
    %% 检查当前时间是否有商贸活动时间
    case check_trading_valid_time() of
        true ->
            next;
        false ->
            TodayWeekT = calendar:day_of_the_week(erlang:date()),
            if TodayWeekT =:= 7 ->
                    erlang:throw({error,?_LANG_TRADING_NOT_VALID_TIME_SUNDAY});
               true ->
                    erlang:throw({error,?_LANG_TRADING_NOT_VALID_TIME})
            end
    end,
    MapId = DataRecord#m_trading_buy_tos.map_id,
    NpcId = DataRecord#m_trading_buy_tos.npc_id,
    TypeId = DataRecord#m_trading_buy_tos.type_id,
    Number = DataRecord#m_trading_buy_tos.number,
    CurMapId = mgeem_map:get_mapid(),
    if MapId =:= CurMapId ->
            next;
       true ->
            ?ERROR_MSG("~ts,DataRecord=~w,CurMapId=~w",["参数错误map_id",DataRecord,CurMapId]),
            erlang:throw({error,?_LANG_TRADING_BUY_PARAM_ERROR})
    end,
    ShopMapGroupGoodsNumber = get_shop_max_group_goods_number(),
    if Number > 0 
       andalso Number =< ShopMapGroupGoodsNumber ->
            next;
       true ->
            ?ERROR_MSG("~ts,Number=~w",["物品购买数量不合法",Number]),
            erlang:throw({error,?_LANG_TRADING_BUY_PARAM_ERROR})
    end,      
    %% 检查玩家是否在NPC附近
    case check_valid_distance(RoleId,NpcId) of
        true ->
            next;
        false ->
            ?ERROR_MSG("~ts",["玩家不在NPC附近，无法操作"]),
            erlang:throw({error,?_LANG_TRADING_NOT_VALID_DISTANCE})
    end,
%%     RoleMapInfo = 
%%         case mod_map_actor:get_actor_mapinfo(RoleId,role) of
%%             undefined ->
%%                 ?ERROR_MSG("~ts",["在本地图获取不到玩家的地图信息"]),
%%                 erlang:throw({error,?_LANG_TRADING_BUY_PARAM_ERROR});
%%             RoleMapInfoT ->
%%                 RoleMapInfoT
%%         end,
	{ok,RoleMapInfo} = mod_map_role:get_role_base(RoleId),
    %% 此地图是否是商贸商店存在的地图
    %% 返回[] or [r_trading_shop_info]
    FactionId = RoleMapInfo#p_role_base.faction_id,
    ShopInfoList = get_trading_shop_info_by_faction_id(FactionId),
    if ShopInfoList =:= [] ->
            ?ERROR_MSG("~ts",["玩家不在本国的商贸活动地图上操作"]),
            erlang:throw({error,?_LANG_TRADING_BUY_NOT_VALID_FACTION});
       true ->
            next
    end,
    case lists:foldl(
           fun(ShopInfo,Acc) ->
                   GoodsIds = ShopInfo#r_trading_shop_info.goods_ids,
                   if ShopInfo#r_trading_shop_info.map_id =:= MapId
                      andalso ShopInfo#r_trading_shop_info.npc_id =:=NpcId ->
                           case lists:member(TypeId,GoodsIds) of 
                               true ->
                                   true;
                               false ->
                                   Acc
                           end;
                      true ->
                           Acc
                   end
           end,false,ShopInfoList) of
        true ->
            next;
        false ->
            ?ERROR_MSG("~ts,DataRecord=~w",["根据map_id,npc_id,type_id相关信息在本地图查找不到相应的商贸商店信息",DataRecord]),
            erlang:throw({error,?_LANG_TRADING_BUY_PARAM_ERROR})
    end,
    %% ShopGoodsInfo 结构为 r_trading_shop_goods
    ShopGoodsInfo = mod_trading_common:get_shop_goods(MapId,NpcId),
    %% GoodsList 结构为 [p_trading_goods,...] 
    GoodsList = ShopGoodsInfo#r_trading_shop_goods.goods,
    ShopGoods = 
        case lists:keyfind(TypeId,#p_trading_goods.type_id,GoodsList) of
            false ->
                ?ERROR_MSG("~ts",["此物品不在此商店物品列表中"]),
                erlang:throw({error,?_LANG_TRADING_BUY_PARAM_ERROR});
            ShopGoodsT ->
                ShopGoodsT
        end,
    if ShopGoods#p_trading_goods.number >= Number ->
            next;
       true ->
            erlang:throw({error,?_LANG_TRADING_BUY_PARAM_ERROR})
    end,
    %% 结构为 r_role_trading
    RoleTrading = 
        case mod_trading_common:get_role_trading(RoleId) of
            undefined ->
                erlang:throw({error,?_LANG_TRADING_BUY_NOT_BILL});
            RoleTradingT ->
                RoleTradingT
        end,
    %% 玩家是否有商贸物品没有出售
    RoleGoodsList = RoleTrading#r_role_trading.goods,
    if erlang:length(RoleGoodsList) =:= 0
       andalso MapId =/= RoleTrading#r_role_trading.map_id ->
            next;
       erlang:length(RoleGoodsList) =:= 0
       andalso RoleTrading#r_role_trading.map_id =:= 0 ->
            next;
       erlang:length(RoleGoodsList) > 0
       andalso MapId =:= RoleTrading#r_role_trading.map_id ->
            next;
       true ->
            erlang:throw({error,?_LANG_TRADING_BUY_GOODS_NOT_SALE})
    end,
    RoleBill = RoleTrading#r_role_trading.bill,
    RoleMaxBill = RoleTrading#r_role_trading.max_bill,
    %% 商贸商票价值是否超地商票价值上限
	%% 商贸新需求
    if RoleBill >= RoleMaxBill ->
            erlang:throw({error,?_LANG_TRADING_BUY_LARGE_THAN_MAX_BILL});
       true ->
            next
    end,
    %% 商贸商票价值是否足够
    CurGoodsPrice = ShopGoods#p_trading_goods.price,
    SunGoodsPrice = CurGoodsPrice * Number,
    if RoleBill >= SunGoodsPrice ->
            next;
       true ->
            erlang:throw({error,?_LANG_TRADING_BUY_NOT_ENOUGH})
    end,
    %% 检查商贸货舱位置是否足够
    RoleGoodsMaxNumber = get_role_max_group_goods_number(),
    RoleGoodsMaxPos = get_role_max_goods_pos_number(),
    {SameGoodsList,DiffGoodsList} = 
        lists:foldl(
          fun(RoleGoods,RGAcc) ->
                  {SRGAcc,DRGAcc} = RGAcc,
                  if RoleGoods#p_trading_goods.price =:= ShopGoods#p_trading_goods.price 
                     andalso (RoleGoods#p_trading_goods.number + Number) =< RoleGoodsMaxNumber ->
                          {[RoleGoods|SRGAcc],DRGAcc};
                     true ->
                          {SRGAcc,[RoleGoods|DRGAcc]}
                  end
          end,{[],[]},RoleGoodsList),
    if SameGoodsList =:= []
       andalso erlang:length(DiffGoodsList) >= RoleGoodsMaxPos ->
            erlang:throw({error,?_LANG_TRADING_BUY_POS_FULL});
       SameGoodsList =:= [] 
       andalso Number > RoleGoodsMaxNumber
       andalso erlang:length(DiffGoodsList) >= (RoleGoodsMaxPos - 1) ->
            erlang:throw({error,?_LANG_TRADING_BUY_POS_FULL});
       true ->
            next
    end,
    {ok,RoleMapInfo,ShopGoodsInfo,ShopGoods,RoleTrading}.
%% RoleTrading 结构为 r_role_trading
%% ShopGoodsInfo 结构为 r_trading_shop_goods
%% ShopGoods 结构为 p_trading_goods
do_trading_buy3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                RoleMapInfo,ShopGoodsInfo,ShopGoods,RoleTrading) ->
    MapId = DataRecord#m_trading_buy_tos.map_id,
    NpcId = DataRecord#m_trading_buy_tos.npc_id,
    TypeId = DataRecord#m_trading_buy_tos.type_id,
    Number = DataRecord#m_trading_buy_tos.number,
    %% 执行购买 商店减物品，扣商贸商票价值，获取物品
    ShopGoodsList = ShopGoodsInfo#r_trading_shop_goods.goods,
    RoleGoodsList = RoleTrading#r_role_trading.goods,
    %% 商店减掉对应的物品数量
    NewNumber = ShopGoods#p_trading_goods.number - Number,
    ShopGoods2 = ShopGoods#p_trading_goods{number = NewNumber},
    ShopGoodsList2 = lists:keydelete(TypeId, #p_trading_goods.type_id,ShopGoodsList),
    ShopGoodsList3 = [ShopGoods2|ShopGoodsList2],
    %% 扣除玩家商贸商票价值
    CurGoodsPrice = ShopGoods#p_trading_goods.price,
    RoleBill = RoleTrading#r_role_trading.bill,
    SunGoodsPrice = CurGoodsPrice * Number,
    RoleBill2 = RoleBill - SunGoodsPrice,
    %% 查找出可以叠加的物品
    RoleGoodsMaxNumber = get_role_max_group_goods_number(),
    {SameGoodsList,DiffGoodsList} = 
        lists:foldl(
          fun(RoleGoods,RGAcc) ->
                  {SRGAcc,DRGAcc} = RGAcc,
                  if RoleGoods#p_trading_goods.price =:= ShopGoods#p_trading_goods.price 
                     andalso (RoleGoods#p_trading_goods.number + Number) =< RoleGoodsMaxNumber ->
                          {[RoleGoods|SRGAcc],DRGAcc};
                     true ->
                          {SRGAcc,[RoleGoods|DRGAcc]}
                  end
          end,{[],[]},RoleGoodsList),
    RoleGoodsList2 = 
        if SameGoodsList =:= [] ->
                RoleGoodsMaxNumber = get_role_max_group_goods_number(),
                if Number > RoleGoodsMaxNumber ->
                        lists:append([[ShopGoods#p_trading_goods{number = RoleGoodsMaxNumber}],
                                      [ShopGoods#p_trading_goods{number = Number - RoleGoodsMaxNumber}],
                                      DiffGoodsList]);
                   true ->
                        [ShopGoods#p_trading_goods{number = Number}|DiffGoodsList]
                end;
           true ->
                [HSameGoods|TSameGoods] = SameGoodsList,
                Number2 = HSameGoods#p_trading_goods.number + Number,
                HSameGoods2 = HSameGoods#p_trading_goods{number = Number2},
                lists:append([[HSameGoods2|TSameGoods],DiffGoodsList])
        end,
    ShopGoodsInfo2 = ShopGoodsInfo#r_trading_shop_goods{goods = ShopGoodsList3},
    RoleTrading2 = RoleTrading#r_role_trading{
                     map_id = MapId, 
                     npc_id = NpcId,        
                     bill = RoleBill2,
                     goods = RoleGoodsList2},
    do_trading_buy4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                    RoleMapInfo,ShopGoodsInfo2,RoleTrading2).


do_trading_buy4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                RoleMapInfo,ShopGoodsInfo,RoleTrading) ->
    %% 处理数据持久化操作
    case db:transaction(
           fun() -> 
                   do_t_trading_buy(RoleId,DataRecord,RoleTrading)
           end) of
        {atomic,{ok}} ->
            #m_trading_buy_tos{map_id=MapID} = DataRecord,
            catch hook_trading:hook({trading_buy, RoleId, MapID}),

            do_trading_buy5({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                            RoleMapInfo,ShopGoodsInfo,RoleTrading);
        {aborted, Reason} ->
           if erlang:is_binary(Reason) ->
                   do_trading_buy_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason);
              true ->
                   ?ERROR_MSG("~ts,Reason=~w",["玩家购买商贸商店物品失败",Reason]),
                   Reason2 = ?_LANG_TRADING_BUY_ERROR,
                   do_trading_buy_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2)
           end
    end.
do_trading_buy5({Unique, Module, Method, DataRecord, RoleId, PId, _Line},
                RoleMapInfo,ShopGoodsInfo,RoleTrading) ->
    MapId = DataRecord#m_trading_buy_tos.map_id,
    NpcId = DataRecord#m_trading_buy_tos.npc_id,
    mod_trading_common:put_shop_goods(MapId,NpcId,ShopGoodsInfo),
    mod_trading_common:put_role_trading(RoleId,RoleTrading),
    SendSelf = #m_trading_buy_toc{
      succ = true,
      shop_goods = ShopGoodsInfo#r_trading_shop_goods.goods,
      role_goods = RoleTrading#r_role_trading.goods,
      bill = RoleTrading#r_role_trading.bill
     },
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    FactionId = RoleMapInfo#p_role_base.faction_id,
    %% 将玩家的商贸信息同步到需要此数据的其它商贸的地图进程
    do_sync_role_trading_info(FactionId,MapId,RoleId,RoleTrading).
    
do_trading_buy_error({Unique, Module, Method, DataRecord, _RoleId, PId, _Line},Reason) ->
    SendSelf = #m_trading_buy_toc{succ = false,reason = Reason},
    MapId = DataRecord#m_trading_buy_tos.map_id,
    NpcId = DataRecord#m_trading_buy_tos.npc_id,
    SendSelf2 =
        case  mod_trading_common:get_shop_goods(MapId,NpcId) of
            undefined ->
                SendSelf;
            ShopInfo ->
                %% ShopInfo 结构为 r_trading_shop_goods
                SendSelf#m_trading_buy_toc{
                  shop_goods = ShopInfo#r_trading_shop_goods.goods }
        end,
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf2).

do_t_trading_buy(_RoleId,_DataRecord,RoleTrading) ->
    db:write(?DB_ROLE_TRADING,RoleTrading,write),
    {ok}.
%% 玩家出售商贸货舱物品接口
%% DataRecord 结构为 m_trading_sale_tos
do_trading_sale({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_trading_sale2({Unique, Module, Method, DataRecord, RoleId, PId, Line}) of
        {error,Reason} ->
            do_trading_sale_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason);
        {ok,RoleMapInfo,ShopInfo,RoleTrading} ->
            do_trading_sale3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                             RoleMapInfo,ShopInfo,RoleTrading)
    end.
do_trading_sale2({_Unique, _Module, _Method, DataRecord, RoleId, _PId, _Line}) ->
    case get_is_open_trading() of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_TRADING_NOT_OPENT})
    end,
    %% 检查当前时间是否有商贸活动时间
    case check_trading_valid_time() of
        true ->
            next;
        false ->
            TodayWeekT = calendar:day_of_the_week(erlang:date()),
            if TodayWeekT =:= 7 ->
                    erlang:throw({error,?_LANG_TRADING_NOT_VALID_TIME_SUNDAY});
               true ->
                    erlang:throw({error,?_LANG_TRADING_NOT_VALID_TIME})
            end
    end,
    MapId = DataRecord#m_trading_sale_tos.map_id,
    NpcId = DataRecord#m_trading_sale_tos.npc_id,
    CurMapId = mgeem_map:get_mapid(),
    if MapId =:= CurMapId ->
            next;
       true ->
            ?ERROR_MSG("~ts,DataRecord=~w,CurMapId=~w",["参数错误map_id",DataRecord,CurMapId]),
            erlang:throw({error,?_LANG_TRADING_SALE_PARAM_ERROR})
    end,
    %% 检查玩家是否在NPC附近
    case check_valid_distance(RoleId,NpcId) of
        true ->
            next;
        false ->
            ?ERROR_MSG("~ts",["玩家不在NPC附近，无法操作"]),
            erlang:throw({error,?_LANG_TRADING_NOT_VALID_DISTANCE})
    end,
%%     RoleMapInfo = 
%%         case mod_map_actor:get_actor_mapinfo(RoleId,role) of
%%             undefined ->
%%                 ?ERROR_MSG("~ts",["在本地图获取不到玩家的地图信息"]),
%%                 erlang:throw({error,?_LANG_TRADING_SALE_PARAM_ERROR});
%%             RoleMapInfoT ->
%%                 RoleMapInfoT
%%         end,
	{ok,RoleMapInfo} = mod_map_role:get_role_base(RoleId),
    %% 此地图是否是商贸商店存在的地图
    %% 返回[] or [r_trading_shop_info]
    FactionId = RoleMapInfo#p_role_base.faction_id,
    ShopInfoList = get_trading_shop_info_by_faction_id(FactionId),
    if ShopInfoList =:= [] ->
            ?ERROR_MSG("~ts",["玩家不在本国的商贸活动地图上操作"]),
            erlang:throw({error,?_LANG_TRADING_SALE_NOT_VALID_FACTION});
       true ->
            next
    end,
    case lists:foldl(
           fun(ShopInfo,Acc) ->
                   if ShopInfo#r_trading_shop_info.map_id =:= MapId
                      andalso ShopInfo#r_trading_shop_info.npc_id =:=NpcId ->
                           true;
                      true ->
                           Acc
                   end
           end,false,ShopInfoList) of
        true ->
            next;
        false ->
            ?ERROR_MSG("~ts,DataRecord=~w",["根据map_id,npc_id,type_id相关信息在本地图查找不到相应的商贸商店信息",DataRecord]),
            erlang:throw({error,?_LANG_TRADING_SALE_PARAM_ERROR})
    end,
    %% 结构为 r_trading_shop_goods
    ShopInfo = 
        case mod_trading_common:get_shop_goods(MapId,NpcId) of
            undefined ->
                ?ERROR_MSG("~ts",["获取商贸商店信息出错"]),
                erlang:throw({error,?_LANG_TRADING_SALE_PARAM_ERROR});
            ShopInfoT ->
                ShopInfoT
        end,
    %% 结构为 r_role_trading
    RoleTrading = 
        case mod_trading_common:get_role_trading(RoleId) of
            undefined ->
                ?ERROR_MSG("~ts",["玩家没有商贸商票，无法出售物品"]),
                erlang:throw({error,?_LANG_TRADING_SALE_NOT_BILL});
            RoleTradingT ->
                RoleTradingT
        end,
    %% 玩家是否有商贸物品没有出售
    RoleGoodsList = RoleTrading#r_role_trading.goods,
    if MapId =:= RoleTrading#r_role_trading.map_id ->
            erlang:throw({error,?_LANG_TRADING_SALE_SAME_SHOP});
       true ->
            next
    end,
    if RoleGoodsList =:= [] ->
            erlang:throw({error,?_LANG_TRADING_SALE_GOODS_EMPTY});
       true ->
            next
    end,
    ShopGoodsList = ShopInfo#r_trading_shop_goods.goods,
    RoleGoodsList = RoleTrading#r_role_trading.goods,
    case lists:foldl(
           fun(RoleGoods,AccFlag) ->
                   TypeId = RoleGoods#p_trading_goods.type_id,
                   case lists:keyfind(TypeId,#p_trading_goods.type_id,ShopGoodsList) of
                       false ->
                           false;
                       _VRoleGoods ->
                           AccFlag
                   end
           end,true,RoleGoodsList) of
        true ->
            next;
        false ->
            ?ERROR_MSG("~ts",["玩家商贸货舱出现不是商贸商店中的物品，出错失败"]),
            erlang:throw({error,?_LANG_TRADING_SALE_NOT_VALID_GOODS})
    end,
    {ok,RoleMapInfo,ShopInfo,RoleTrading}.
%% ShopInfo 结构为 r_trading_shop_goods
%% RoleTrading 结构为 r_role_trading
do_trading_sale3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                 RoleMapInfo,ShopInfo,RoleTrading) ->
    %% 计算出此次出售的总价值
    ShopGoodsList = ShopInfo#r_trading_shop_goods.goods,
    RoleGoodsList = RoleTrading#r_role_trading.goods,
	SaleGoodsTypes = DataRecord#m_trading_sale_tos.types,
    [IsOpenChangePrice] = common_config_dyn:find(?TRADING_CONFIG,is_open_change_price),
    {SumBill, NewRoleGoodsList} = 
		lists:foldl(
		  fun(RoleGoods, {BillAcc, RemGoods}) ->
			  Number = RoleGoods#p_trading_goods.number,
			  TypeId = RoleGoods#p_trading_goods.type_id,
			  case lists:member(TypeId, SaleGoodsTypes) of
			  true ->
				  ShopGoods = lists:keyfind(TypeId,#p_trading_goods.type_id,ShopGoodsList),
				  Price =
					  case IsOpenChangePrice of
					  true ->
						  ShopGoods#p_trading_goods.price;
					  _ ->
						  ShopGoods#p_trading_goods.sale_price
					  end,
				  NewBillAcc = BillAcc + (Price * Number),
				  NewRemGoods = lists:keydelete(TypeId, #p_trading_goods.type_id, RemGoods),
				  {NewBillAcc, NewRemGoods};
			  false ->
				  {BillAcc, RemGoods}
			  end
		  end,{0, RoleGoodsList},RoleGoodsList),
    Bill = RoleTrading#r_role_trading.bill,
    RoleTrading2 = case NewRoleGoodsList of
      [] ->
        RoleTrading#r_role_trading{
          map_id = 0,
          npc_id = 0,
          bill   = Bill + SumBill,
          goods  = NewRoleGoodsList
        };
      _ ->
        RoleTrading#r_role_trading{
          bill  = Bill + SumBill,
          goods = NewRoleGoodsList
        }
    end,
    do_trading_sale4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                     RoleMapInfo,ShopInfo,RoleTrading2).

do_trading_sale4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                 RoleMapInfo,ShopInfo,RoleTrading) ->
    %% 处理数据持久化操作
    case db:transaction(
           fun() -> 
                   do_t_trading_sale(RoleId,DataRecord,RoleTrading)
           end) of
        {atomic,{ok}} ->
            catch hook_trading:hook({trading_sale, RoleId}),

            do_trading_sale5({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                             RoleMapInfo,ShopInfo,RoleTrading);
        {aborted, Reason} ->
           if erlang:is_binary(Reason) ->
                   do_trading_sale_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason);
              true ->
                   ?ERROR_MSG("~ts,Reason=~w",["玩家出售商贸商店物品失败",Reason]),
                   Reason2 = ?_LANG_TRADING_SALE_ERROR,
                   do_trading_sale_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2)
           end
    end.

do_trading_sale5({Unique, Module, Method, DataRecord, RoleId, PId, _Line},
                 RoleMapInfo,_ShopInfo,RoleTrading) ->
    MapId = DataRecord#m_trading_sale_tos.map_id,
    mod_trading_common:put_role_trading(RoleId,RoleTrading),
    SendSelf = #m_trading_sale_toc{
      succ = true,
      role_goods = RoleTrading#r_role_trading.goods,
      bill = RoleTrading#r_role_trading.bill
     },
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    FactionId = RoleMapInfo#p_role_base.faction_id,
    %% 将玩家的商贸信息同步到需要此数据的其它商贸的地图进程
    do_sync_role_trading_info(FactionId,MapId,RoleId,RoleTrading).

do_trading_sale_error({Unique, Module, Method, _DataRecord, _RoleId, PId, _Line},Reason) ->
    SendSelf = #m_trading_sale_toc{succ = false, reason = Reason},
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

do_t_trading_sale(_RoleId,_DataRecord,RoleTrading) ->
    db:write(?DB_ROLE_TRADING,RoleTrading,write),
    {ok}.
%% 领取商贸商票接口
%% DataRecord 结构为 m_trading_get_tos
do_trading_get({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_trading_get2({Unique, Module, Method, DataRecord, RoleId, PId, Line}) of
        {error,Reason} ->
            do_trading_get_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason);
        {ok,RoleBase,RoleAttr,RoleBillInfo} ->
            do_trading_get3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                           RoleBase,RoleAttr,RoleBillInfo)
    end.
do_trading_get2({_Unique, _Module, _Method, DataRecord, RoleId, _PId, _Line}) ->
    case get_is_open_trading() of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_TRADING_NOT_OPENT})
    end,
    %% 检查当前时间是否有商贸活动时间
    case check_trading_valid_time() of
        true ->
            next;
        false ->
            TodayWeekT = calendar:day_of_the_week(erlang:date()),
            if TodayWeekT =:= 7 ->
                    erlang:throw({error,?_LANG_TRADING_NOT_VALID_TIME_SUNDAY});
               true ->
                    erlang:throw({error,?_LANG_TRADING_NOT_VALID_TIME})
            end
    end,
    MapId = DataRecord#m_trading_get_tos.map_id,
    NpcId = DataRecord#m_trading_get_tos.npc_id,
	{ok,RoleBase} = mod_map_role:get_role_base(RoleId),
%%     RoleMapInfo = 
%%         case mod_map_actor:get_actor_mapinfo(RoleId,role) of
%%             undefined ->
%%                 ?ERROR_MSG("~ts",["在本地图获取不到玩家的地图信息"]),
%%                 erlang:throw({error,?_LANG_TRADING_GET_PARAM_ERROR});
%%             RoleMapInfoT ->
%%                 RoleMapInfoT
%%         end,
    RoleAttr = 
        case mod_map_role:get_role_attr(RoleId) of
            {ok,RoleAttrT} ->
                RoleAttrT;
            _ ->
                ?ERROR_MSG("~ts",["获取玩家活跃度出错"]),
                erlang:throw({error,?_LANG_TRADING_GET_ACTIVE_POINTS})
        end,
    %% 玩家级别>= 30
    MinRoleLevel = get_role_min_role_level(),
    RoleLevel = RoleAttr#p_role_attr.level,
    if RoleLevel >= MinRoleLevel ->
            next;
       true ->
            erlang:throw({error,?_LANG_TRADING_GET_ROLE_LEVEL})
    end,
    %% 结构为 r_role_trading_bill
    RoleBillInfo = 
        case get_role_trading_bill(RoleLevel) of
            {error,_Reason} ->
                ?ERROR_MSG("~ts,RoleLevel=~w",["玩家级别无法查找到获取的商票配置信息",RoleLevel]),
                erlang:throw({error,?_LANG_TRADING_GET_PARAM_ERROR});
            {ok,RoleBillInfoT} ->
                RoleBillInfoT
        end,
    %% 玩家是否加入宗族
    if RoleBase#p_role_base.family_id =/= 0 ->
            next;
       true ->
            erlang:throw({error,?_LANG_TRADING_GET_NOT_FAMILY})
    end,
    FactionId = RoleBase#p_role_base.faction_id,
    case check_trading_bill_npc(FactionId,MapId,NpcId) of
        false ->
            erlang:throw({error,?_LANG_TRADING_GET_PARAM_ERROR});
        true ->
            next
    end,
    CurMapId = mgeem_map:get_mapid(),
    if MapId =:= CurMapId ->
            next;
       true ->
            ?ERROR_MSG("~ts,DataRecord=~w,CurMapId=~w",["参数错误map_id",DataRecord,CurMapId]),
            erlang:throw({error,?_LANG_TRADING_GET_PARAM_ERROR})
    end,
    %% 检查玩家是否在NPC附近
    case check_valid_distance(RoleId,NpcId) of
        true ->
            next;
        false ->
            ?ERROR_MSG("~ts",["玩家不在NPC附近，无法操作"]),
            erlang:throw({error,?_LANG_TRADING_NOT_VALID_DISTANCE})
    end,
    %% 判断玩家状态是什么状态
    case mod_trading_common:get_role_trading(RoleId) of
        undefined ->
            next;
        _ ->
            erlang:throw({error,?_LANG_TRADING_GET_STATE_TRADING})
    end,
    {ok,RoleBase,RoleAttr,RoleBillInfo}.
%% RoleMapInfo 结构为 p_map_role
%% RoleBillInfo 结构为 r_role_trading_bill
do_trading_get3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                RoleBase,RoleAttr,RoleBillInfo) ->
    case db:transaction(
           fun() -> 
                   do_t_trading_get(RoleId,DataRecord,RoleBase,RoleAttr,RoleBillInfo)
           end) of
        {atomic,{ok,RoleTrading,GoodsList}} ->
            catch hook_trading:hook({trading_get, RoleId}),

            do_trading_get4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                             RoleBase,RoleBillInfo,RoleTrading,GoodsList);
        {aborted, Reason} ->
            Reason2 = 
                case Reason of
                    {throw,{bag_error,BR}} ->
                        ?ERROR_MSG("~ts,bag_error=~w",["领取商贸商票背包操作错误，兑换失败",BR]),
                        case BR of
                            {not_enough_pos,_BagID} ->
                                ?_LANG_TRADING_GET_BAG_ENOUGH;
                            _ ->
                                ?_LANG_TRADING_GET_ERROR
                        end;
                    _ ->
                        if erlang:is_binary(Reason) ->
                                Reason;
                           true ->
                                ?ERROR_MSG("~ts,Reason=~w",["领取商贸商票出错",Reason]),
                                ?_LANG_TRADING_GET_ERROR
                        end
                end,
            do_trading_get_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2)
    end.
%% RoleMapInfo 结构为 p_map_role
%% RoleBillInfo 结构为 r_role_trading_bill
%% RoleTrading 结构为 r_role_trading
%% GoodsList 结构为 [p_goods]
do_trading_get4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                RoleMapInfo,RoleBillInfo,RoleTrading,GoodsList) ->
    SendSelf = #m_trading_get_toc{
      succ = true,
      goods = GoodsList,
      bill = RoleTrading#r_role_trading.bill,
      max_bill = RoleTrading#r_role_trading.max_bill,
      trading_times = RoleTrading#r_role_trading.trading_times},
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    FactionId = RoleMapInfo#p_role_base.faction_id,
    MapId = DataRecord#m_trading_get_tos.map_id,
    do_sync_role_trading_info(FactionId,MapId,RoleId,RoleTrading),
    %% 处理道具更新通知，道具消费日志
    catch do_trading_get5(RoleId,Line,RoleBillInfo,GoodsList).
do_trading_get5(RoleId,Line,RoleBillInfo,GoodsList) ->
    %% 通知背包道具变化
    if erlang:length(GoodsList) > 0 ->
            %%记录道具奖励
            
            LogTypeId = RoleBillInfo#r_role_trading_bill.item_id,
            LogNumber = RoleBillInfo#r_role_trading_bill.item_number,
            common_item_logger:log(RoleId, LogTypeId,LogNumber,undefined,?LOG_ITEM_TYPE_REN_WU_HUO_DE),
            common_misc:update_goods_notify({line, Line, RoleId},GoodsList);
       true ->
            next
    end,
    ok.
do_trading_get_error({Unique, Module, Method, _DataRecord, _RoleId, PId, _Line},Reason) ->
    SendSelf = #m_trading_get_toc{succ = false,reason = Reason},
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).
%% 领取商贸商票事务操作
do_t_trading_get(RoleId,DataRecord,RoleBase,RoleAttr,RoleBillInfo) ->
    %% 判断玩家是否在合法的可商贸状态
    [RoleState] = db:read(?DB_ROLE_STATE,RoleId,write),
    %% stall_auto, stall_self, fight, sitdown, normal, exchange, ybc, trading = 0
    StallSelfState = RoleState#r_role_state.stall_self,
    TradingState = RoleState#r_role_state.trading,
    if StallSelfState =:= true
       orelse TradingState =:= 1 ->
            db:abort(?_LANG_TRADING_GET_STATE_ERROR);
       true ->
            next
    end,
    %% 设置玩家商贸状态
    RoleState2 = RoleState#r_role_state{trading = 1},
    db:write(?DB_ROLE_STATE,RoleState2,write),
    RoleTrading = 
        case db:read(?DB_ROLE_TRADING,RoleId,write) of
            [] ->
                %% 玩家从未玩家商贸活动
                #r_role_trading{role_id = RoleId,map_id = 0,npc_id = 0,
                                start_time = common_tool:now()};
            [RoleTradingT] ->
                RoleTradingT
        end,
    MaxTradingTimes = get_role_max_trading_times(),
    StartTime = RoleTrading#r_role_trading.start_time,
    %% 获取今天0:0:0时的秒数，以判断当前的商贸活动是否需要重新计算
    TodaySeconds = common_tool:datetime_to_seconds({erlang:date(),{0,0,0}}),
    RoleTrading2 = 
        if TodaySeconds > StartTime ->
                %% 今天没有玩家商贸
                #r_role_trading{role_id = RoleId,map_id = 0,npc_id = 0,
                                trading_times = 1, 
                                status = ?TRADING_STATUS_GET,
                                start_time = common_tool:now(),
                                role_trading_bill = RoleBillInfo};
           true ->
                RoleTradingTimes = RoleTrading#r_role_trading.trading_times,
                if RoleTradingTimes >= MaxTradingTimes ->
                        db:abort(?_LANG_TRADING_GET_FULL_TIMES);
                   true ->
                        #r_role_trading{role_id = RoleId,map_id = 0,npc_id = 0,
                                        trading_times = RoleTradingTimes + 1,
                                        status = ?TRADING_STATUS_GET,
                                        start_time = common_tool:now(),
                                        role_trading_bill = RoleBillInfo}
                end
        end,
    do_t_trading_get2(RoleId,DataRecord,RoleBase,RoleAttr,RoleBillInfo,RoleTrading2).
%% RoleMapInfo 结构为 p_map_role
%% RoleBillInfo 结构为 r_role_trading_bill
%% RoleTrading 结构为 r_role_trading
do_t_trading_get2(RoleId,_DataRecord,_RoleMapInfo,_RoleAttr,RoleBillInfo,RoleTrading) ->
    %% 根据配置处理商贸商票信息，创建商票物品
    Bill = RoleBillInfo#r_role_trading_bill.bill,
    MaxBill =  RoleBillInfo#r_role_trading_bill.max_bill,
    RoleTrading2 = RoleTrading#r_role_trading{
                     bill = Bill,
                     max_bill = MaxBill},
    ItemId = RoleBillInfo#r_role_trading_bill.item_id,
    ItemNumber = RoleBillInfo#r_role_trading_bill.item_number,
    Bind = RoleBillInfo#r_role_trading_bill.bind,
    CreateInfo = #r_goods_create_info{
      type=?TYPE_ITEM,
      type_id=ItemId,
      num=ItemNumber,
      bind=Bind},
    {ok,GoodsList} = mod_bag:create_goods(RoleId,CreateInfo),
    db:write(?DB_ROLE_TRADING,RoleTrading2,write),
    {ok,RoleTrading2,GoodsList}.
%% 交还商贸商票接口
%% DataRecord 结构为 m_trading_return_tos
do_trading_return({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_trading_return2({Unique, Module, Method, DataRecord, RoleId, PId, Line}) of
        {error,Reason} ->
            do_trading_return_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason);
        {ok,RoleMapInfo,RoleTrading,IncomeItem} ->
            do_trading_return3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                               RoleMapInfo,RoleTrading,IncomeItem)
    end.
do_trading_return2({_Unique, _Module, _Method, DataRecord, RoleId, _PId, _Line}) ->
    case get_is_open_trading() of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_TRADING_NOT_OPENT})
    end,
%%     RoleMapInfo = 
%%         case mod_map_actor:get_actor_mapinfo(RoleId,role) of
%%             undefined ->
%%                 ?ERROR_MSG("~ts",["在本地图获取不到玩家的地图信息"]),
%%                 erlang:throw({error,?_LANG_TRADING_RETURN_PARAM_ERROR});
%%             RoleMapInfoT ->
%%                 RoleMapInfoT
%%         end,
	{ok,RoleMapInfo} = mod_map_role:get_role_base(RoleId),
    MapId = DataRecord#m_trading_return_tos.map_id,
    NpcId = DataRecord#m_trading_return_tos.npc_id,
    %% 交还商票操作类型，1，一般交还，2，使用商贸宝典
    %%Type = DataRecord#m_trading_return_tos.type,
	%%新需求，屏蔽掉商贸宝典
    %% 商贸宝典物品类型id
    %TypeId = DataRecord#m_trading_return_tos.type_id,
%    if Type =:= 1 ->
%            next;
%       Type =:= 2 
%       andalso TypeId =/= 0 ->
%            case mod_bag:check_inbag_by_typeid(RoleId,TypeId) of
%                false ->
%                    ?ERROR_MSG("~ts,Type=~w,TypeId=~w",["玩家背包没有此物品",Type,TypeId]),
%                    erlang:throw({error,?_LANG_TRADING_RETURN_NOT_GOODS});
%                _ ->
%                    next
%            end;
%       true ->
%            ?ERROR_MSG("~ts,Type=~w,TypeId=~w",["参数出错",Type,TypeId]),
%            erlang:throw({error,?_LANG_TRADING_RETURN_PARAM_ERROR})
%    end,
    FactionId = RoleMapInfo#p_role_base.faction_id,
    case check_trading_bill_npc(FactionId,MapId,NpcId) of
        false ->
            ?ERROR_MSG("~ts,DataRecord=~w",["根据传查找不到相关的领取商贸商票NPC的配置",DataRecord]),
            erlang:throw({error,?_LANG_TRADING_RETURN_PARAM_ERROR});
        true ->
            next
    end,
    CurMapId = mgeem_map:get_mapid(),
    if MapId =:= CurMapId ->
            next;
       true ->
            ?ERROR_MSG("~ts,DataRecord=~w,CurMapId=~w",["参数错误map_id",DataRecord,CurMapId]),
            erlang:throw({error,?_LANG_TRADING_RETURN_PARAM_ERROR})
    end,
    %% 检查玩家是否在NPC附近
    case check_valid_distance(RoleId,NpcId) of
        true ->
            next;
        false ->
            ?ERROR_MSG("~ts",["玩家不在NPC附近，无法操作"]),
            erlang:throw({error,?_LANG_TRADING_NOT_VALID_DISTANCE})
    end,
    %% 检查商贸商票是否合法，是否有相应的物品没有买出
    %% RoleTrading 结构为 r_role_trading
    RoleTrading = 
        case mod_trading_common:get_role_trading(RoleId) of
            undefined ->
                erlang:throw({error,?_LANG_TRADING_RETURN_NOT_BILL});
            RoleTradingT ->
                RoleTradingT
        end,
    if RoleTrading#r_role_trading.goods =/= [] ->
            erlang:throw({error,?_LANG_TRADING_RETURN_HAVE_GOODS});
       true ->
            next
    end,
    %% 判断当前日期是否可以使用增加商贸收益的道具
	%% 新需求，屏蔽掉商贸宝典
    %IncomeItem =
    %    if Type =:= 2 ->
    %            %% IncomeItem 结构为 r_trading_income_item 
    %            IncomeItemT =
    %                case get_trading_income_item(TypeId) of
    %                    {ok,IncomeItemTT} ->
    %                        IncomeItemTT;
    %                    {error,_InError} ->
    %                        ?ERROR_MSG("~ts",["玩家选择的增加商贸收益道具不合法"]),
    %                        erlang:throw({error,?_LANG_TRADING_RETURN_INCOME_GOODS})
    %                end,
    %            TodayWeek = calendar:day_of_the_week(erlang:date()),
    %            if IncomeItemT#r_trading_income_item.week =/= TodayWeek ->
    %                    erlang:throw({error,?_LANG_TRADING_RETURN_INCOME_GOODS_NOT_USE});
    %               true ->
    %                    next
    %            end,
    %            IncomeItemT;
    %       true ->
    %            undefined
    %    end,
	IncomeItem = undefined,
    {ok,RoleMapInfo,RoleTrading,IncomeItem}.
%% RoleMapInfo 结构为 p_map_role
%% RoleTrading 结构为 r_role_trading
%% IncomeItem 结构为 r_trading_income_item 
do_trading_return3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                   RoleMapInfo,RoleTrading,IncomeItem) ->
    %% 计算玩家获得和宗族获得 扣除道具 
    case db:transaction(
           fun() -> 
                   do_t_trading_return(RoleId,DataRecord,RoleMapInfo,RoleTrading,IncomeItem)
           end) of
        {atomic,{ok,RoleTrading2,BillUpdateList,BillDeleteList,InUpdateList,InDeleteList}} ->
            catch hook_trading:hook({trading_return, RoleId}),
			mod_random_mission:handle_event(RoleId, ?RAMDOM_MISSION_EVENT_14),
            do_trading_return4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                               RoleMapInfo,RoleTrading2,IncomeItem,BillUpdateList,
                               BillDeleteList,InUpdateList,InDeleteList);
        {aborted, Reason} ->
            if erlang:is_binary(Reason) ->
                    do_trading_return_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason);
               true ->
                   case Reason of
                       {throw,{bag_error,num_not_enough}}->
                           Reason2 = ?_LANG_TRADING_RETURN_BAG_ERROR;
                       {bag_error,num_not_enough}->
                           Reason2 = ?_LANG_TRADING_RETURN_BAG_ERROR;
                       _ ->
                           Reason2 = ?_LANG_TRADING_RETURN_ERROR
                   end,
                   do_trading_return_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2)
            end
    end.

do_trading_return4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                             RoleMapInfo,RoleTrading,IncomeItem,BillUpdateList,
                               BillDeleteList,InUpdateList,InDeleteList) ->
    MapId = DataRecord#m_trading_return_tos.map_id,
    SendSelf = #m_trading_return_toc{
      succ = true,
      type = DataRecord#m_trading_return_tos.type,
      silver = RoleTrading#r_role_trading.reward_silver,
      silver_bind = RoleTrading#r_role_trading.reward_silver_bind,
      family_money = RoleTrading#r_role_trading.family_money,
      family_contribution = RoleTrading#r_role_trading.family_contribution,
      trading_times = RoleTrading#r_role_trading.trading_times},
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    %% 成就 add by caochuncheng 2011-03-04
    if RoleTrading#r_role_trading.last_bill > 0 ->
            hook_activity_task:done_task(RoleId,?ACTIVITY_TASK_TRADING);
       true ->
            next
    end,
    FactionId = RoleMapInfo#p_role_base.faction_id,
    mod_trading_common:put_role_trading(RoleId,undefined),
    do_sync_role_trading_info(FactionId,MapId,RoleId,undefined),
    catch do_trading_return5({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                             RoleMapInfo,RoleTrading,IncomeItem,BillUpdateList,
                               BillDeleteList,InUpdateList,InDeleteList).

do_trading_return5({_Unique, _Module, _Method, _DataRecord, RoleId, _PId, Line},
                   RoleMapInfo,RoleTrading,IncomeItem,BillUpdateList,
                   BillDeleteList,InUpdateList,InDeleteList) ->
    RoleTradingBill = RoleTrading#r_role_trading.role_trading_bill,
    %% 商贸日志
	{ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleId),
    TradingLog = #r_role_trading_log{
      role_id = RoleId,
      role_name = RoleMapInfo#p_role_base.role_name ,
      role_level = RoleLevel,
      faction_id = RoleMapInfo#p_role_base.faction_id,
      family_id = RoleMapInfo#p_role_base.family_id,
      family_name = RoleMapInfo#p_role_base.family_name,
      bill = RoleTrading#r_role_trading.bill,
      max_bill = RoleTrading#r_role_trading.max_bill,
      trading_times = RoleTrading#r_role_trading.trading_times,
      status = ?TRADING_STATUS_RETURN,
      start_time = RoleTrading#r_role_trading.start_time,
      last_bill = RoleTrading#r_role_trading.last_bill,
      family_money = RoleTrading#r_role_trading.family_money,
      family_contribution = RoleTrading#r_role_trading.family_contribution,
      end_time = RoleTrading#r_role_trading.end_time,
      base_bill = RoleTradingBill#r_role_trading_bill.bill,
      reward_silver = RoleTrading#r_role_trading.reward_silver,
      reward_silver_bind = RoleTrading#r_role_trading.reward_silver_bind
     },
    catch common_general_log_server:log_trading(TradingLog),
    UnicastArg = {line, Line, RoleId},
    IncomeBill = RoleTrading#r_role_trading.last_bill,
	%%新需求，屏蔽掉商贸宗族奖励
    %FamilyBill = RoleTrading#r_role_trading.family_money,
    %FamilyContribution = RoleTrading#r_role_trading.family_contribution,
    #p_role_base{role_name = RoleName,
                family_id = FamilyId} = RoleMapInfo,
    %% 通钱币变化
    if IncomeBill > 0 ->
            {ok,RoleAttr} = mod_map_role:get_role_attr(RoleId),
            UnicastArg = {line, Line, RoleId},
            AttrChangeList = [#p_role_attr_change{
                                 change_type=?ROLE_SILVER_CHANGE, 
                                 new_value = RoleAttr#p_role_attr.silver},
                             #p_role_attr_change{
                                                  change_type=?ROLE_SILVER_BIND_CHANGE, 
                                                  new_value = RoleAttr#p_role_attr.silver_bind}],
            common_misc:role_attr_change_notify(UnicastArg,RoleId,AttrChangeList);
       true ->
            next
    end,
    %% 添加宗族收益和玩家宗族贡献度
    %%新需求，屏蔽掉商贸宗族奖励
	%FamilyProcessName = common_misc:make_family_process_name(FamilyId),
    %if FamilyId =/= 0  ->
    %        if FamilyBill > 0 ->
    %                catch global:send(FamilyProcessName,{add_money, FamilyBill});
    %           true ->
    %                next
    %        end;
    %   true ->
    %        next
    %end,
    %common_family:info(FamilyId, {add_contribution, RoleId, FamilyContribution}),
    
    %% 道具变化 道具消耗日志
    catch do_log_item_for_return(RoleId,
                           RoleTradingBill#r_role_trading_bill.item_id,
                           RoleTradingBill#r_role_trading_bill.item_number),
    catch do_log_item_for_return(RoleId,IncomeItem#r_trading_income_item.item_id,
                           IncomeItem#r_trading_income_item.item_number),
    if BillUpdateList =/= [] ->
            common_misc:update_goods_notify(UnicastArg,BillUpdateList);
       true ->
            next
    end,
    if BillDeleteList =/= [] ->
            common_misc:del_goods_notify(UnicastArg, BillDeleteList);
       true ->
            next
    end,
    if InUpdateList =/= [] ->
            common_misc:update_goods_notify(UnicastArg,InUpdateList);
       true ->
            next
    end,
    if InDeleteList =/= [] ->
            common_misc:del_goods_notify(UnicastArg, InDeleteList);
       true ->
            next
    end,
    %% 通知消息
    %LeftMessage = lists:flatten(io_lib:format(?_LANG_TRADING_RETURN_SUCC,
    %                                          [common_tool:to_list(RoleName),
    %                                           common_tool:to_list(RoleTrading#r_role_trading.reward_silver + RoleTrading#r_role_trading.reward_silver_bind),
    %                                           common_tool:to_list(FamilyBill)])),
	%%新需求，屏蔽掉商贸的宗族奖励
	LeftMessage = lists:flatten(io_lib:format(?_LANG_TRADING_RETURN_SUCC,
                                              [common_tool:to_list(RoleName),
                                               common_tool:to_list(RoleTrading#r_role_trading.reward_silver + RoleTrading#r_role_trading.reward_silver_bind)])),
    catch common_broadcast:bc_send_msg_family(FamilyId,?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_FAMILY,LeftMessage).

%% 记录交还商票使用的道具日志
do_log_item_for_return(RoleId,TypeId,Num) ->
    common_item_logger:log(RoleId, TypeId,Num,undefined,?LOG_ITEM_TYPE_REN_WU_KOU_CHU).
 
do_trading_return_error({Unique, Module, Method, _DataRecord, _RoleId, PId, _Line},Reason) ->
    SendSelf = #m_trading_return_toc{succ = false, reason = Reason},
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

%% RoleMapInfo 结构为 p_map_role
%% RoleTrading 结构为 r_role_trading
%% IncomeItem 结构为 r_trading_income_item 
do_t_trading_return(RoleId,DataRecord,RoleMapInfo,RoleTrading,IncomeItem) ->
    %% 计算此次商贸玩家和宗族获取的收益
    {IncomeBill,FamilyBill} = 
        calc_role_trading_income_bill(DataRecord,RoleTrading,IncomeItem),
    RoleAttr = 
        case mod_map_role:get_role_attr(RoleId) of
            {ok,RoleAttrT} ->
                RoleAttrT;
            {error,_Error} ->
                db:abort(?_LANG_TRADING_RETURN_ERROR)
        end,
    if IncomeBill > 0 ->
           {Silver, SilverBind} = calc_role_trading_award_silver(RoleId, IncomeBill),
           %% 玩家获取钱币，需要记录日志
           %common_consume_logger:gain_silver({RoleId, SilverBind, Silver,?GAIN_TYPE_SILVER_TRADING,""}),
           %NewSilver = RoleAttr#p_role_attr.silver + Silver,
           %NewSilverBind = RoleAttr#p_role_attr.silver_bind + SilverBind,
           %RoleAttr2 = RoleAttr#p_role_attr{silver = NewSilver, silver_bind = NewSilverBind},
		   %新需求，跑商奖励只有铜钱
           NewSilverBind = RoleAttr#p_role_attr.silver_bind + SilverBind + Silver,
           RoleAttr2 = RoleAttr#p_role_attr{silver_bind = NewSilverBind},
           mod_map_role:set_role_attr(RoleId, RoleAttr2);
       true ->
            next
    end,
    %% 修改玩家状态
    [RoleState] = db:read(?DB_ROLE_STATE,RoleId,write),
    %% 设置玩家商贸状态
    RoleState2 = RoleState#r_role_state{trading = 0},
    db:write(?DB_ROLE_STATE,RoleState2,write),
    do_t_trading_return(RoleId,DataRecord,RoleMapInfo,RoleTrading,IncomeItem,IncomeBill,FamilyBill).
do_t_trading_return(RoleId,_DataRecord,_RoleMapInfo,RoleTrading,_IncomeItem,IncomeBill,FamilyBill) ->
    %Type = DataRecord#m_trading_return_tos.type,
    BagIds = get_deduct_trading_income_item_bag_ids(),
    %FamilyContribution = get_trading_role_family_contribution(),
	%%新需求，屏蔽掉宗族的商贸奖励
	FamilyContribution = 0,
	%新需求，屏蔽掉商贸宝典
    %{InUpdateList,InDeleteList} = 
    %if Type =:= 2 ->
    %        %% 扣除增加商贸收益道具 
    %        InNumber = IncomeItem#r_trading_income_item.item_number,
    %        InItemId = IncomeItem#r_trading_income_item.item_id,
    %        {ok,InUpdateListT,InDeleteListT} = 
    %            mod_bag:decrease_goods_by_typeid(RoleId,BagIds,InItemId,InNumber),
    %        ?ERROR_MSG("RoleId=~w,BagIds=~w,InItemId=~w,InNumber=~w,InUpdateListT=~w,InDeleteListT=~w",[RoleId,BagIds,InItemId,InNumber,InUpdateListT,InDeleteListT]),
    %        {InUpdateListT,InDeleteListT};
    %   true ->
    %        {[],[]}
    %end,
	{InUpdateList, InDeleteList} = {[], []},
    %% 删除商贸商票道具
    RoleTradingBill = RoleTrading#r_role_trading.role_trading_bill,
    BillTypeId = RoleTradingBill#r_role_trading_bill.item_id,
    BillNumber = RoleTradingBill#r_role_trading_bill.item_number,
    {ok,BillUpdateList,BillDeleteList} = 
        mod_bag:decrease_goods_by_typeid(RoleId,BagIds,BillTypeId,BillNumber),
    {Silver, SilverBind} = calc_role_trading_award_silver(RoleId, IncomeBill),
    %% 更新玩家商贸记录
    RoleTrading2 = RoleTrading#r_role_trading{
                     last_bill = IncomeBill,
                     end_time = common_tool:now(),
                     family_money = FamilyBill,
                     family_contribution = FamilyContribution,
                     reward_silver = Silver,
                     reward_silver_bind = SilverBind
                    },
    db:write(?DB_ROLE_TRADING,RoleTrading2,write),
    {ok,RoleTrading2,BillUpdateList,BillDeleteList,InUpdateList,InDeleteList}.
%% 计算此次商贸玩家和宗族获取的收益
%% RoleTrading 结构为 r_role_trading
%% IncomeItem 结构为 r_trading_income_item 
%% 返回{IncomeBill,FamilyBill}
calc_role_trading_income_bill(_DataRecord,RoleTrading,_IncomeItem) ->
	%%屏蔽掉商贸宝典
    %%Type = DataRecord#m_trading_return_tos.type,
    Bill = RoleTrading#r_role_trading.bill,
    RoleTradingBill = RoleTrading#r_role_trading.role_trading_bill,
    BaseBill = RoleTradingBill#r_role_trading_bill.bill,
	%新需求，屏蔽掉商贸宗族奖励
    %IncomeScale = get_trading_family_income_scale(),
    if (Bill - BaseBill) =< 0 ->
            {0,0};
       true ->
            IncomeBill = Bill - BaseBill,
			%%屏蔽掉商贸宝典
            %IncomeBill2 = 
            %    if Type =:= 2 ->
            %            AddValue = IncomeItem#r_trading_income_item.add_value,
            %            common_tool:ceil(IncomeBill * (10000 + AddValue) / 10000);
            %       true ->
            %            IncomeBill
            %    end,
			IncomeBill2 = IncomeBill,
            %TempBillT = common_tool:ceil(IncomeBill2 * (IncomeScale / 10000)),
			%%新需求，屏蔽掉宗族奖励
			TempBillT = 0,
            {IncomeBill2,TempBillT}
    end.

%%商贸奖励改为都送绑定跟不绑定的钱币
%%根据IncomeBill值，以及活跃度，确定钱币的多少
%%返回{silver, silver_bind}
%calc_role_trading_award_silver(RoleID, IncomeBill) ->
%    MinActivePoints = get_role_min_active_points(),
%    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
%    if RoleAttr#p_role_attr.active_points >= MinActivePoints ->
%           {IncomeBill, IncomeBill * ?REWARD_SILVER_BIND_MUL};
%       true ->
%           {0, IncomeBill}
%    end.

%%商贸奖励新规则
%%提交时，先判断商票值是否大于商票上限值，
%%商票价值>商票上限值，则跑商成功，继续判断
%%   商票价值>=商票原始价值*2，则提示“完成跑商，获得最高奖励XXX同比”
%%	   商票价值<商票原始价值*2，则提示“完成跑商，获得中等奖励XXX铜币”
%%商票价值<商票上限值，则提示“未完成跑商，只能获得XXX铜币”
calc_role_trading_award_silver(RoleID, IncomeBill) ->
	%%获取玩家等级
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	#p_role_attr{level = RoleLevel} = RoleAttr,
	%%获取对应玩家等级的商票数据
	[BillList] = common_config_dyn:find(?TRADING_CONFIG, role_trading_bill),
	F = fun({r_role_trading_bill, MinLevel, MaxLevel, _Minbill, _Maxbill, _, _, _}) ->
			MinLevel =< RoleLevel andalso RoleLevel =< MaxLevel
		end,
	[{r_role_trading_bill, _MinLevel, _MaxLevel, Minbill, Maxbill, _, _, _}] = lists:filter(F, BillList),
	%%获取对应玩家等级的奖励数据
	[SilverList] = common_config_dyn:find(?TRADING_CONFIG, role_bill_silver),
	G = fun({r_role_bill_silver, MinLevel, MaxLevel, _MaxSilver, _MidSilver, _MinSilver}) ->
			MinLevel =< RoleLevel andalso RoleLevel =< MaxLevel
		end,
	[{r_role_bill_silver, _MinLevel, _MaxLevel, MaxSilver, MidSilver, MinSilver}] = lists:filter(G, SilverList),
	%%根据规则，计算奖励
	case IncomeBill + Minbill < Maxbill of
		true ->
			{0, MinSilver};
		false ->
			case IncomeBill + Minbill >= Minbill * 2 of
				true ->
					{0, MaxSilver};
				false ->
					{0, MidSilver}
			end
	end.

%% 兑换商贸宝典物品接口
%% DataRecord 结构为 m_trading_exchange_tos
do_trading_exchange({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_trading_exchange2({Unique, Module, Method, DataRecord, RoleId, PId, Line}) of 
        {error,Reason} ->
            do_trading_exchange_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason);
        {ok,RoleMapInfo,RoleAttr} ->
            do_trading_exchange3({Unique, Module, Method, DataRecord, RoleId, PId, Line},RoleMapInfo,RoleAttr)
    end.
do_trading_exchange2({_Unique, _Module, _Method, DataRecord, RoleId, _PId, _Line}) ->
    case get_is_open_trading() of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_TRADING_NOT_OPENT})
    end,
%%     RoleMapInfo = 
%%         case mod_map_actor:get_actor_mapinfo(RoleId,role) of
%%             undefined ->
%%                 ?ERROR_MSG("~ts",["在本地图获取不到玩家的地图信息"]),
%%                 erlang:throw({error,?_LANG_TRADING_EXCHANGE_PARAM_ERROR});
%%             RoleMapInfoT ->
%%                 RoleMapInfoT
%%         end,
	{ok,RoleMapInfo} = mod_map_role:get_role_base(RoleId),
    NpcId = DataRecord#m_trading_exchange_tos.npc_id,
    MapId = DataRecord#m_trading_exchange_tos.map_id,
    FamilyContribution = DataRecord#m_trading_exchange_tos.family_contribution,
    FactionId = RoleMapInfo#p_role_base.faction_id,
    case check_trading_book_npc(FactionId,MapId,NpcId) of
        false ->
            ?ERROR_MSG("~ts,DataRecord=~w",["根据传查找不到相关的领取商贸商票NPC的配置",DataRecord]),
            erlang:throw({error,?_LANG_TRADING_EXCHANGE_PARAM_ERROR});
        true ->
            next
    end,
    CurMapId = mgeem_map:get_mapid(),
    if MapId =:= CurMapId ->
            next;
       true ->
            ?ERROR_MSG("~ts,DataRecord=~w,CurMapId=~w",["参数错误map_id",DataRecord,CurMapId]),
            erlang:throw({error,?_LANG_TRADING_EXCHANGE_PARAM_ERROR})
    end,
    %% 返回 {ItemId,ItemNumber}
    {_BookItemId,BookItemNumber,_BookBind} = get_trading_book_item(),
    if FamilyContribution >= BookItemNumber ->
            next;
       true ->
            erlang:throw({error,?_LANG_TRADING_EXCHANGE_FC_ERROR})
    end,
    %% 检查玩家是否在NPC附近
    case check_valid_distance(RoleId,NpcId) of
        true ->
            next;
        false ->
            ?ERROR_MSG("~ts",["玩家不在NPC附近，无法操作"]),
            erlang:throw({error,?_LANG_TRADING_NOT_VALID_DISTANCE})
    end,
    RoleAttr = 
        case mod_map_role:get_role_attr(RoleId) of 
            {ok,RoleAttrT} ->
                RoleAttrT;
            {error,_Reason} ->
                erlang:throw({error,?_LANG_TRADING_EXCHANGE_PARAM_ERROR})
        end,
    RoleFamilyContribution = RoleAttr#p_role_attr.family_contribute,
    if FamilyContribution > RoleFamilyContribution ->
            erlang:throw({error,?_LANG_TRADING_EXCHANGE_FC_NOT_ENOUGH});
       true ->
            next
    end,
    {ok,RoleMapInfo,RoleAttr}.

do_trading_exchange3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                     RoleMapInfo,RoleAttr) ->
    %% 创建道具，记录日志
    case db:transaction(
           fun() -> 
                   do_t_trading_exchange(RoleId,DataRecord,RoleMapInfo,RoleAttr)
           end) of
        {atomic,{ok,GoodsNumber,GoodsList,DeductFC}} ->
            do_trading_exchange4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                RoleMapInfo,RoleAttr,GoodsNumber,GoodsList,DeductFC);
        {aborted, Reason} ->
            Reason2 = 
                case Reason of
                    {throw,{bag_error,BR}} ->
                        ?ERROR_MSG("~ts,bag_error=~w",["商贸商票兑换商贸宝典背包操作错误，兑换失败",BR]),
                        case BR of
                            {not_enough_pos,_BagID} ->
                                ?_LANG_TRADING_EXCHANGE_BAG_ENOUGH;
                            _ ->
                                ?_LANG_TRADING_EXCHANGE_ERROR
                        end;
                    _ ->
                        if erlang:is_binary(Reason) ->
                                Reason;
                           true ->
                                ?ERROR_MSG("~ts,Reason=~w",["兑换商贸宝典出错",Reason]),
                                ?_LANG_TRADING_EXCHANGE_ERROR
                        end
                end,
            do_trading_exchange_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2)
    end.
do_trading_exchange4({Unique, Module, Method, _DataRecord, RoleId, PId, Line},
                                RoleMapInfo,RoleAttr,GoodsNumber,GoodsList,DeductFC) ->
    FamilyContribution = RoleAttr#p_role_attr.family_contribute - DeductFC,
    FamilyContribution2 = if FamilyContribution < 0 -> 0; true -> FamilyContribution end,
    SendSelf = #m_trading_exchange_toc{
      succ = true, 
      goods = GoodsList,
      family_contribution = FamilyContribution2},
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    
    %% 需要通知道具变化，记录获取道具日志
    if erlang:length(GoodsList) > 0 ->
            %%记录道具奖励
            [LogGoods|_T] = GoodsList,
            common_item_logger:log(RoleId,LogGoods,GoodsNumber,?LOG_ITEM_TYPE_REN_WU_HUO_DE),
            catch common_misc:update_goods_notify({line, Line, RoleId},GoodsList);
       true ->
            next
    end,
    %% 更新宗族贡献度
    FamilyId = RoleMapInfo#p_role_base.family_id,
    common_family:info(FamilyId, {add_contribution, RoleId, -DeductFC}),
    ok.
do_trading_exchange_error({Unique, Module, Method, _DataRecord, _RoleId, PId, _Line},Reason) ->
    SendSelf = #m_trading_exchange_toc{succ = false, reason = Reason},
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

do_t_trading_exchange(RoleId,DataRecord,_RoleMapInfo,_RoleAttr) ->
    FamilyContribution = DataRecord#m_trading_exchange_tos.family_contribution,
    %% 返回 {ItemId,ItemNumber}
    {BookItemId,BookItemNumber,Bind} = get_trading_book_item(),
    %% 计算可以兑换的个数
    ItemNumber = FamilyContribution div BookItemNumber,
    CreateInfo = #r_goods_create_info{
      type=?TYPE_ITEM,
      type_id=BookItemId,
      num=ItemNumber,
      bind=Bind},
    {ok,GoodsList} = mod_bag:create_goods(RoleId,CreateInfo),
    {ok,ItemNumber,GoodsList,BookItemNumber * ItemNumber}.
    
%% 获取玩家的商贸状态
do_trading_status({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_trading_status2({Unique, Module, Method, DataRecord, RoleId, PId, Line}) of
        {error,Reason} ->
            do_trading_status_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason);
        {ok,RoleMapInfo,IsTradingMapId,TradingShopList} ->
            do_trading_status3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                               RoleMapInfo,IsTradingMapId,TradingShopList)
    end.
do_trading_status2({_Unique, _Module, _Method, _DataRecord, RoleId, _PId, _Line}) ->
%%     RoleMapInfo = 
%%         case mod_map_actor:get_actor_mapinfo(RoleId,role) of 
%%             undefined ->
%%                 ?ERROR_MSG("~ts",["获取玩家的地图信息出错"]),
%%                 erlang:throw({error,?_LANG_TRADING_STATUS_ERROR});
%%             RoleMapInfoT ->
%%                 RoleMapInfoT
%%         end,
	{ok,RoleMapInfo} = mod_map_role:get_role_base(RoleId),
    FactionId = RoleMapInfo#p_role_base.faction_id,
    MapId = mgeem_map:get_mapid(),
    %% TradingShopList 结构为 r_trading_shop_info
    TradingShopList= get_trading_shop_info(),
    IsTradingMapId = 
        lists:foldl(
          fun(TradingShop,Acc) ->
                  case Acc of
                      false ->
                          VMapId = TradingShop#r_trading_shop_info.map_id,
                          VFactionId = TradingShop#r_trading_shop_info.faction_id,
                          if VMapId =:= MapId
                             andalso VFactionId =:= FactionId->
                                  true;
                             true ->
                                  Acc
                          end;
                      true->
                          Acc
                  end
          end,false,TradingShopList),
    {ok,RoleMapInfo,IsTradingMapId,TradingShopList}.

do_trading_status3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                   RoleMapInfo,IsTradingMapId,TradingShopList) ->
    SendSelf = 
        case IsTradingMapId of
            false ->
                #m_trading_status_toc{succ = true,type =1};
            true ->
                case mod_trading_common:get_role_trading(RoleId) of 
                    undefined ->
                        %% 从数据库查询
                        get_role_trading_status_by_database(RoleId);
                    RoleTrading ->
                        %% 结构为 r_role_trading
                        TradingTimes = RoleTrading#r_role_trading.trading_times,
                        RoleTradingBill = RoleTrading#r_role_trading.role_trading_bill,
                        BaseBill = RoleTradingBill#r_role_trading_bill.bill,
                        Bill = RoleTrading#r_role_trading.bill,
						MaxBill = RoleTradingBill#r_role_trading_bill.max_bill,
                        StartTime = RoleTrading#r_role_trading.start_time,
                        RoleGoods = RoleTrading#r_role_trading.goods,
                        NowSeconds = common_tool:datetime_to_seconds({erlang:date(),{0,0,0}}),
                        NpcId = RoleTrading#r_role_trading.npc_id,
                        TradingTimes2 = 
                            if StartTime >= NowSeconds ->
                                    TradingTimes;
                               true ->
                                    0
                            end,
                        #m_trading_status_toc{succ = true,
                                              type =2,
                                              trading_status = 1,
                                              trading_times = TradingTimes2,
                                              base_bill = BaseBill,
                                              bill = Bill,
											  max_bill = MaxBill,
                                              start_time = StartTime,
                                              role_goods = RoleGoods,
                                              npc_id = NpcId}
                    end
        end,
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    case IsTradingMapId of 
        false ->
            do_trading_status4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                               RoleMapInfo,IsTradingMapId,TradingShopList);
        true ->
            ok
    end.

do_trading_status4({_Unique, _Module, _Method, _DataRecord, RoleId, PId, _Line},
                   RoleMapInfo,_IsTradingMapId,TradingShopList) ->
    %% 将此信息路由到有商贸信息的地图进程
    FactionId = RoleMapInfo#p_role_base.faction_id,
    TradingShopList2 = [R || R <- TradingShopList, 
                             R#r_trading_shop_info.faction_id =:= FactionId],
    [TradingShopInfo | _T] = TradingShopList2,
    MapId = TradingShopInfo#r_trading_shop_info.map_id,
    MapProcessName = common_map:get_common_map_name(MapId),
    catch global:send(MapProcessName,{mod_trading,{get_role_trading_status,RoleId, PId}}).

%% 当玩家不在商贸状态下时，从数据库获取相应的商贸数据返回
%% 返回 m_trading_status_toc
get_role_trading_status_by_database(RoleId) ->
    TradingStatus = #m_trading_status_toc{
      succ = true,
      type =2,
      trading_status = 0,
      trading_times = 0,
      base_bill = 0,
      bill = 0,
	  max_bill = 0,
      start_time = 0,
      role_goods = [],
      npc_id = 0},
    case catch db:dirty_read(?DB_ROLE_TRADING, RoleId) of
        {'EXIT', _Reason} ->
            TradingStatus;
        [] ->
            TradingStatus;
        [RoleTrading] ->
            StartTime = RoleTrading#r_role_trading.start_time,
            NowSeconds = common_tool:datetime_to_seconds({erlang:date(),{0,0,0}}),
            if StartTime >= NowSeconds ->
                    TradingStatus#m_trading_status_toc{
                      trading_times = RoleTrading#r_role_trading.trading_times
                     };
              true ->
                    TradingStatus
            end 
    end.  
do_trading_status_error({Unique, Module, Method, _DataRecord, _RoleId, PId, _Line},Reason) ->
    SendSelf = #m_trading_status_toc{succ = false,type =2,reason = Reason},
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

%% 商贸活动内部消息处理
%% 更新商贸活动配置文件
%% erlang:send_after(Interval,self(),{mod_trading,{reload_trading_config,Type}})
%% 更新商贸活动配置文件 all,trading trading_goods
do_reload_trading_config(Type) ->
    %% 更新初始化商店物品信息
    case Type of 
        all ->
            common_config_dyn:reload(?TRADING_CONFIG),
            mod_trading_config:update(?TRADING_GOODS_CONFIG),
            do_reload_trading_config2();
        ?TRADING_CONFIG ->
            common_config_dyn:reload(?TRADING_CONFIG),
            do_reload_trading_config2();
        ?TRADING_GOODS_CONFIG ->
            mod_trading_config:update(?TRADING_GOODS_CONFIG),
            do_reload_trading_config2();
        _ ->
            ?ERROR_MSG("~ts,Type=~w",["热更新商贸活动配置文件出错",Type])
    end.

do_reload_trading_config2()->
    CalcMapId = get_trading_shop_godds_price_map_id(),
    MapId = mgeem_map:get_mapid(),
    if MapId =:= CalcMapId ->
            TradingShopList= get_trading_shop_info(),
            %% 商店的初始化物品价格记录  [r_trading_shop_price] or []
            ShopPriceList = get_trading_shop_price(),
            lists:foreach(
              fun(TradingShop) ->
                      VMapId = TradingShop#r_trading_shop_info.map_id,
                      VMapProcessName = common_map:get_common_map_name(VMapId),
                      catch global:send(VMapProcessName,{mod_trading,{init_trading_shop,ShopPriceList}})
              end,TradingShopList);
       true ->
            next
    end.
%% 检查是否可以初始化地图商贸商店信息
%% 所有地图进程都启动完成
%% erlang:send_after(Interval,self(),{mod_trading,{check_init_trading_shop}});
do_check_init_trading_shop() ->
    TradingShopList= get_trading_shop_info(),
    Flag = 
        lists:foldl(
          fun(TSI,Acc) ->
                  MapId = TSI#r_trading_shop_info.map_id,
                  MapProcessName = common_map:get_common_map_name(MapId),
                  case global:whereis_name(MapProcessName) of
                      undefined ->
                          false;
                      _ ->
                          Acc
                  end
          end,true,TradingShopList),
    case Flag of
        true ->
            %% 可以初始化
            %% 根据当前时间计算出重置下次商贸商店信息时间
            InitMapId = mgeem_map:get_mapid(),
            NowSeconds = NowSeconds = common_tool:now(),
            UpdateTime = get_reload_trading_shop_seconds(NowSeconds),
            mod_trading_common:put_trading_reload_shop_goods(InitMapId,{UpdateTime,0}),
            %% 商店的初始化物品价格记录  [r_trading_shop_price] or []
            ShopPriceList = get_trading_shop_price(),
            lists:foreach(
              fun(TradingShop) ->
                      MapId = TradingShop#r_trading_shop_info.map_id,
                      MapProcessName = common_map:get_common_map_name(MapId),
                      catch global:send(MapProcessName,{mod_trading,{init_trading_shop,ShopPriceList}})
              end,TradingShopList);
        false ->
            Interval = get_goods_price_update_interval(),
            erlang:send_after(Interval,self(),{mod_trading,{check_init_trading_shop}})
    end.

%% 初始化商贸商店信息消息处理
%% ShopPriceList 结构为 [r_trading_shop_price] or []
do_init_trading_shop(ShopPriceList) ->
    MapId = mgeem_map:get_mapid(),
    TradingShopList= get_trading_shop_info(),
    TradingShopList2 = 
        lists:foldl(
          fun(TSI,Acc) ->
                  VMapId = TSI#r_trading_shop_info.map_id,
                  if VMapId =:= MapId ->
                          [TSI|Acc];
                     true ->
                          Acc
                  end
          end,[],TradingShopList),
    if TradingShopList2 =:= [] ->
            ignore;
       true ->
            do_init_trading_shop2(MapId,ShopPriceList,TradingShopList2)
    end.
do_init_trading_shop2(MapId,ShopPriceList,TradingShopList) ->
    NowSeconds = common_tool:now(),
    PriceInterval = get_goods_price_update_interval(),
    NumberInterval = get_goods_number_update_interval(),
    UpdatePriceTime = NowSeconds + PriceInterval,
    UpdateNumberTime = NowSeconds + NumberInterval,
    mod_trading_common:put_next_goods_price(MapId,UpdatePriceTime),
    mod_trading_common:put_next_goods_number(MapId,UpdateNumberTime),
    lists:foreach(
      fun(TradingShopInfo) ->
              %% GoodsList 结构为 [p_trading_goods,...]
              NpcId = TradingShopInfo#r_trading_shop_info.npc_id,
              SalePriceIndex = 
                  case  TradingShopInfo#r_trading_shop_info.sale_price_index > 0 of
                      true ->
                          TradingShopInfo#r_trading_shop_info.sale_price_index;
                      _ ->
                          1
                  end,
              PriceIndex = get_trading_shop_init_price_by_npc_id(ShopPriceList,NpcId),
              GoodsList = get_trading_shop_goods_by_config(TradingShopInfo,PriceIndex,SalePriceIndex),
              ShopGoods = #r_trading_shop_goods{
                faction_id = common_misc:get_map_faction_id(MapId),
                map_id = MapId,
                npc_id = NpcId,
                goods = GoodsList,
                current_price_index = PriceIndex,
                current_seconds = NowSeconds},
              ?DEV("~ts,MapId=~w,NpcId=~w,ShopGoods=~w",["初始化的商贸信息如下",MapId,NpcId,ShopGoods]),
              mod_trading_common:put_shop_goods(MapId,NpcId,ShopGoods)
      end,TradingShopList),
    mod_trading_common:put_trading_shop_init_status(MapId,?TRADING_SHOP_INIT_STATUS_TRUE),
    ok.
%% 根据NpcId在已经计算好的商贸价格启动索引查询
%% ShopPriceList 结构为 [r_trading_shop_price] or []
get_trading_shop_init_price_by_npc_id(ShopPriceList,NpcId) ->
    case lists:keyfind(NpcId,#r_trading_shop_price.npc_id,ShopPriceList) of
        false ->
            1;
        ShopPrice ->
            ShopPrice#r_trading_shop_price.init_index
    end.
    
%% 玩家操作了商贸商票信息，需要同步到相关的商贸城图去
%% erlang:send(self(),{mod_trading,{sync_role_trading_info,FactionId,MapId,RoleId,RoleTrading}})
do_sync_role_trading_info(FactionId,_MapId,RoleId,RoleTrading) ->
	mgeer_role:absend(RoleId,{mod,mod_trading,{update_role_trading,RoleId,RoleTrading}}),
	ShopInfoList = get_trading_shop_info_by_faction_id(FactionId),
	lists:foreach(
	  fun(ShopInfo) ->
			  ShopMapId = ShopInfo#r_trading_shop_info.map_id,
			  MapProcessName = common_map:get_common_map_name(ShopMapId),
			  catch global:send(MapProcessName,{mod_trading,{update_role_trading,RoleId,RoleTrading}})
	  end,ShopInfoList).
%% 更新玩家商贸商票信息
%% global:send(MapProcessName,{mod_trading,{update_role_trading,RoleId,RoleTrading}})
do_update_role_trading(RoleId,RoleTrading) ->
    mod_trading_common:put_role_trading(RoleId,RoleTrading),
    ok.

%% 发送商贸广播消息处理
%% erlang:send_after(Interval,self(),{mod_trading,{send_broadcast_message,StartSeconds,EndSeconds,Interval}})
do_send_broadcast_message(StartSeconds,EndSeconds,Interval) ->
    case global:whereis_name("mod_broadcast_server") of
        undefined ->
            erlang:send_after(Interval,self(),{mod_trading,{send_broadcast_message,StartSeconds,EndSeconds,Interval}});
        _ ->
            catch common_broadcast:bc_send_cycle_msg_world(
                    ?BC_MSG_TYPE_CENTER,?BC_MSG_SUB_TYPE,
                    ?_LANG_TRADING_SUNDAY_BC_CENTER,StartSeconds,
                    EndSeconds,Interval),
            catch common_broadcast:bc_send_cycle_msg_world(
                    ?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,
                    ?_LANG_TRADING_SUNDAY_BC_CHAT,StartSeconds,
                    EndSeconds,Interval)
    end.

%% 删除玩家商贸活动信息
%% global:send(MapProcessName,{mod_trading,{delete_role_trading,RoleId, RoleMapInfo,TradingStatus}})
do_delete_role_trading(RoleId, RoleMapInfo, TradingStatus) ->
    FactionId = RoleMapInfo#p_role_base.faction_id,
    %% 记录日志
    case mod_trading_common:get_role_trading(RoleId) of
        undefined ->
            ignore;
        RoleTrading ->
            RoleTradingBill = RoleTrading#r_role_trading.role_trading_bill,
            %% 商贸日志
			{ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleId),
            TradingLog = #r_role_trading_log{
              role_id = RoleId,
              role_name = RoleMapInfo#p_role_base.role_name ,
              role_level = RoleLevel,
              faction_id = RoleMapInfo#p_role_base.faction_id,
              family_id = RoleMapInfo#p_role_base.family_id,
              family_name = RoleMapInfo#p_role_base.family_name,
              bill = RoleTrading#r_role_trading.bill,
              max_bill = RoleTrading#r_role_trading.max_bill,
              trading_times = RoleTrading#r_role_trading.trading_times,
              status = TradingStatus,
              start_time = RoleTrading#r_role_trading.start_time,
              last_bill = RoleTrading#r_role_trading.last_bill,
              family_money = RoleTrading#r_role_trading.family_money,
              family_contribution = RoleTrading#r_role_trading.family_contribution,
              end_time = common_tool:now(),
              base_bill = RoleTradingBill#r_role_trading_bill.bill,
              reward_silver = RoleTrading#r_role_trading.reward_silver,
              reward_silver_bind = RoleTrading#r_role_trading.reward_silver_bind
             },
            catch common_general_log_server:log_trading(TradingLog)
    end,
    do_sync_role_trading_info(FactionId,0,RoleId,undefined),
    notify_client_cancel_role_trading_status(RoleId),
    ok.

%% 通知玩家商贸状态取消
notify_client_cancel_role_trading_status(RoleId) ->
    SendSelf = get_role_trading_status_by_database(RoleId),
    Line = common_misc:get_role_line_by_id(RoleId),
    common_misc:unicast(Line, RoleId,?DEFAULT_UNIQUE, ?TRADING, ?TRADING_STATUS, SendSelf).

%% 获取玩家商贸状态信息消息处理
%% global:send(MapProcessName,{mod_trading,{get_role_trading_status,RoleId, PId}})
do_get_role_trading_status(RoleId, PId) ->
    SendSelf = 
        case mod_trading_common:get_role_trading(RoleId) of
            undefined ->
                get_role_trading_status_by_database(RoleId);
            RoleTrading ->
                %% 结构为 r_role_trading
                TradingTimes = RoleTrading#r_role_trading.trading_times,
                RoleTradingBill = RoleTrading#r_role_trading.role_trading_bill,
                BaseBill = RoleTradingBill#r_role_trading_bill.bill,
                Bill = RoleTrading#r_role_trading.bill,
				MaxBill = RoleTrading#r_role_trading.max_bill,
                StartTime = RoleTrading#r_role_trading.start_time,
                RoleGoods = RoleTrading#r_role_trading.goods,
                NowSeconds = common_tool:datetime_to_seconds({erlang:date(),{0,0,0}}),
                NpcId = RoleTrading#r_role_trading.npc_id,
                TradingTimes2 = 
                    if StartTime >= NowSeconds ->
                            TradingTimes;
                       true ->
                            0
                    end,
                #m_trading_status_toc{succ = true,
                                      type =2,
                                      trading_status = 1,
                                      trading_times = TradingTimes2,
                                      base_bill = BaseBill,
                                      bill = Bill,
									  max_bill = MaxBill,
                                      start_time = StartTime,
                                      role_goods = RoleGoods,
                                      npc_id = NpcId}
        end,
    common_misc:unicast2(PId, ?DEFAULT_UNIQUE, ?TRADING, ?TRADING_STATUS, SendSelf).

%% 处理玩家销毁道具处理
%% RoleId 玩家id
%% TypeId 销毁物品类型id
%% 这方法必须在事务中调用
hook_t_drop_trading_bill_item(RoleId,TypeId) ->
	mgeer_role:absend(RoleId,{mod,mod_trading,{t_drop_trading_bill_item,RoleId,TypeId}}).
do_t_drop_trading_bill_item(RoleId,TypeId) ->
    TypeIdList = get_role_trading_bill_type_ids(),
    case lists:member(TypeId,TypeIdList) of 
        true ->
            hook_t_drop_trading_bill_item2(RoleId,TypeId);
        false ->
            ignore
    end.
hook_t_drop_trading_bill_item2(RoleId,_TypeId) ->
    %% 重置玩家状态
    %% 修改玩家状态
    [RoleState] = db:read(?DB_ROLE_STATE,RoleId,write),
    %% 设置玩家商贸状态
    RoleState2 = RoleState#r_role_state{trading = 0},
    db:write(?DB_ROLE_STATE,RoleState2,write),
    ok.
%% 处理玩家销毁道具处理，是用来记录玩家商贸日志
hook_drop_trading_bill_item(RoleId,TypeId) ->
	mgeer_role:absend(RoleId,{mod,mod_trading,{drop_trading_bill_item,RoleId,TypeId}}).
do_drop_trading_bill_item(RoleId,TypeId) ->
    TypeIdList = get_role_trading_bill_type_ids(),
    case lists:member(TypeId,TypeIdList) of 
        true ->
            hook_drop_trading_bill_item2(RoleId,TypeId);
        false ->
            ignore
    end.
hook_drop_trading_bill_item2(RoleId,TypeId) ->
    case mod_map_role:get_role_base(RoleId) of
        undefined ->
            ignore;
       {ok,RoleMapInfo} ->
            hook_drop_trading_bill_item3(RoleId,TypeId,RoleMapInfo)
    end.
hook_drop_trading_bill_item3(RoleId,TypeId,RoleMapInfo) ->
    FactionId = RoleMapInfo#p_role_base.faction_id,
    MapId = mgeem_map:get_mapid(),
    %% TradingShopList 结构为 r_trading_shop_info
    TradingShopList= get_trading_shop_info(),
    IsTradingMapId = 
        lists:foldl(
          fun(TradingShop,Acc) ->
                  case Acc of
                      false ->
                          VMapId = TradingShop#r_trading_shop_info.map_id,
                          VFactionId = TradingShop#r_trading_shop_info.faction_id,
                          if VMapId =:= MapId
                             andalso VFactionId =:= FactionId->
                                  true;
                             true ->
                                  Acc
                          end;
                      true->
                          Acc
                  end
          end,false,TradingShopList),
    case IsTradingMapId of
        true ->
            TradingStatus = ?TRADING_STATUS_PERSON_HANDLE,
            do_delete_role_trading(RoleId,RoleMapInfo,TradingStatus);
        false ->
            hook_drop_trading_bill_item4(RoleId,TypeId,RoleMapInfo,TradingShopList)
    end.

hook_drop_trading_bill_item4(RoleId,_TypeId,RoleMapInfo,TradingShopList) ->
    %% 将此信息路由到有商贸信息的地图进程
    FactionId = RoleMapInfo#p_role_base.faction_id,
    TradingShopList2 = [R || R <- TradingShopList, 
                             R#r_trading_shop_info.faction_id =:= FactionId],
    [TradingShopInfo | _T] = TradingShopList2,
    MapId = TradingShopInfo#r_trading_shop_info.map_id,
    MapProcessName = common_map:get_common_map_name(MapId),
    TradingStatus = ?TRADING_STATUS_PERSON_HANDLE,
    catch global:send(MapProcessName,{mod_trading,{delete_role_trading,RoleId, RoleMapInfo, TradingStatus}}).
    

%% 玩家进入地图相关商贸信息初始化
%% RoleId 玩家id
%% RoleBase 玩家地图信息 结构为 p_role_base
hook_first_enter_map(RoleId,RoleBase) ->
    %% 查询玩家当前是否处理商贸状态
    [RoleState] = db:dirty_read(?DB_ROLE_STATE, RoleId),
    #r_role_state{trading = Trading} = RoleState,
    if Trading =:= 1 ->
            %% 加载商贸相关数据到相应的地图进程中
            hook_first_enter_map2(RoleId,RoleBase);
       true ->
            ignore
    end.
hook_first_enter_map2(RoleId,RoleBase) ->
    [RoleTrading] = db:dirty_read(?DB_ROLE_TRADING, RoleId),
    FactionId = RoleBase#p_role_base.faction_id,
    do_sync_role_trading_info(FactionId,0,RoleId,RoleTrading).


%% 当玩家在商贸活动过程中死亡时，删除商票
%% RoleMapInfo p_map_role
%% SrcActorId 谁导致角色死亡
%% SrcActorType 导致角色死亡的actor的类型: role monster pet

hook_role_dead(RoleId,SrcActorId,SrcActorType) ->
	{ok,RoleMapInfo} = mod_map_role:get_role_base(RoleId),
	mgeer_role:absend(RoleId,{mod,mod_trading,{role_dead,RoleId,RoleMapInfo,SrcActorId,SrcActorType}}).

hook_role_dead2(RoleId,RoleMapInfo,UpdateGoodsList,DeleteGoodsList) ->
    Line = common_misc:get_role_line_by_id(RoleId),
    UnicastArg = {line, Line, RoleId},
    if UpdateGoodsList =/= [] ->
            catch common_misc:update_goods_notify(UnicastArg,UpdateGoodsList);
       true ->
            next
    end,
    if DeleteGoodsList =/= [] ->
            catch common_misc:del_goods_notify(UnicastArg,DeleteGoodsList);
       true ->
            next
    end,
    hook_role_dead3(RoleId,RoleMapInfo).
hook_role_dead3(RoleId,RoleMapInfo) ->
    FactionId = RoleMapInfo#p_role_base.faction_id,
    MapId = mgeem_map:get_mapid(),
    %% TradingShopList 结构为 r_trading_shop_info
    TradingShopList= get_trading_shop_info(),
    IsTradingMapId = 
        lists:foldl(
          fun(TradingShop,Acc) ->
                  case Acc of
                      false ->
                          VMapId = TradingShop#r_trading_shop_info.map_id,
                          VFactionId = TradingShop#r_trading_shop_info.faction_id,
                          if VMapId =:= MapId
                             andalso VFactionId =:= FactionId->
                                  true;
                             true ->
                                  Acc
                          end;
                      true->
                          Acc
                  end
          end,false,TradingShopList),
    case IsTradingMapId of
        true ->
            TradingStatus = ?TRADING_STATUS_PERSON_DEAD,
            do_delete_role_trading(RoleId,RoleMapInfo,TradingStatus);
        false ->
            hook_role_dead4(RoleId,RoleMapInfo,TradingShopList)
    end.
hook_role_dead4(RoleId,RoleMapInfo,TradingShopList) ->
    FactionId = RoleMapInfo#p_role_base.faction_id,
    TradingShopList2 = [R || R <- TradingShopList, 
                             R#r_trading_shop_info.faction_id =:= FactionId],
    [TradingShopInfo | _T] = TradingShopList2,
    MapId = TradingShopInfo#r_trading_shop_info.map_id,
    MapProcessName = common_map:get_common_map_name(MapId),
    TradingStatus = ?TRADING_STATUS_PERSON_DEAD,
    catch global:send(MapProcessName,{mod_trading,{delete_role_trading,RoleId, RoleMapInfo, TradingStatus}}),
    ok.
t_hook_role_dead(RoleId) ->
    [RoleState] = db:read(?DB_ROLE_STATE,RoleId,write),
    %% 是商贸状态，需要处理
    if RoleState#r_role_state.trading =:= 1 ->
            next;
       true ->
            db:abort(not_trading_status)
    end,
    %% 设置玩家商贸状态
    RoleState2 = RoleState#r_role_state{trading = 0},
    db:write(?DB_ROLE_STATE,RoleState2,write),
    [RoleTrading] = db:read(?DB_ROLE_TRADING, RoleId),
    RoleTradingBill = RoleTrading#r_role_trading.role_trading_bill,
    ItemId = RoleTradingBill#r_role_trading_bill.item_id,
    ItemNumber = RoleTradingBill#r_role_trading_bill.item_number,
    %% 玩家死亡时，删除商贸商票的背包配置
    [BagIdList] = common_config_dyn:find(?TRADING_CONFIG,deduct_trading_bill_item_bag_ids),
    %% 删除商贸商票
    {ok,UpdateList,DeleteList}  = 
        mod_bag:decrease_goods_by_typeid(RoleId,BagIdList,ItemId,ItemNumber),
    {ok,UpdateList,DeleteList}.

get_role_trading_state(RoleId) ->
	[RoleState] = db:dirty_read(?DB_ROLE_STATE, RoleId),
	#r_role_state{trading = Trading} = RoleState,
	{ok,Trading}.
	
%% 手工取消玩家商贸状态
cancel_role_trading_state(RoleId) ->
    catch cancel_role_trading_state2(RoleId).
cancel_role_trading_state2(RoleId) ->
    [RoleState] = db:dirty_read(?DB_ROLE_STATE, RoleId),
    #r_role_state{trading = Trading} = RoleState,
    if Trading =:= 1 ->
            cancel_role_trading_state3(RoleId,RoleState);
       true ->
            ignore
    end.
cancel_role_trading_state3(RoleId,RoleState) ->
    [RoleBase] = db:dirty_read(?DB_ROLE_BASE, RoleId),
    [RoleAttr] = db:dirty_read(?DB_ROLE_ATTR, RoleId),
    FactionId = RoleBase#p_role_base.faction_id,
    do_sync_role_trading_info(FactionId,0,RoleId,undefined),
    %% 记录日志
    case catch db:dirty_read(?DB_ROLE_TRADING, RoleId) of
        {'EXIT', Reason} ->
            ?ERROR_MSG("~ts,Reason=~w", ["手工取消商贸商票时，获取玩家商贸信息出错",Reason]),
            ignore;
        [] ->
            ?ERROR_MSG("~ts", ["手工取消商贸商票时，查找不到玩家商贸信息"]),
            ignore;
        [RoleTrading] ->
            RoleTradingBill = RoleTrading#r_role_trading.role_trading_bill,
            %% 商贸日志
            TradingLog = #r_role_trading_log{
              role_id = RoleId,
              role_name = RoleBase#p_role_base.role_name ,
              role_level = RoleAttr#p_role_attr.level,
              faction_id = RoleBase#p_role_base.faction_id,
              family_id = RoleBase#p_role_base.family_id,
              family_name = RoleBase#p_role_base.family_name,
              bill = RoleTrading#r_role_trading.bill,
              max_bill = RoleTrading#r_role_trading.max_bill,
              trading_times = RoleTrading#r_role_trading.trading_times,
              status = ?TRADING_STATUS_DESTROY,
              start_time = RoleTrading#r_role_trading.start_time,
              last_bill = RoleTrading#r_role_trading.last_bill,
              family_money = RoleTrading#r_role_trading.family_money,
              family_contribution = RoleTrading#r_role_trading.family_contribution,
              end_time = common_tool:now(),
              base_bill = RoleTradingBill#r_role_trading_bill.bill,
              reward_silver = RoleTrading#r_role_trading.reward_silver,
              reward_silver_bind = RoleTrading#r_role_trading.reward_silver_bind
             },
            catch common_general_log_server:log_trading(TradingLog)
    end,
    %% 设置玩家商贸状态
    RoleState2 = RoleState#r_role_state{trading = 0},
    db:dirty_write(?DB_ROLE_STATE,RoleState2),
    ok.
%%%===================================================================
%%% Internal functions
%%%===================================================================
%% 获取商贸活动功能是否开放设置
%% 返回 false or true
get_is_open_trading() ->
    case common_config_dyn:find(?TRADING_CONFIG,is_open_trading) of
        [Flag] ->
            Flag;
        _ ->
            false
    end.

%% 商贸活动有效时间
%% 按星期几来配置相关的有效时间
%% 1...7 表示星期一到星期日
get_trading_valid_time() ->
    case common_config_dyn:find(?TRADING_CONFIG,trading_valid_time) of
        [DataList] ->
            DataList;
        _ ->
            []
    end.
%% 使用当前时间判断是否是合法的商贸活动时间
%% 返回 true or false
check_trading_valid_time() ->
    Week =  calendar:day_of_the_week(erlang:date()),
    {H,M,S} = erlang:time(),
    ValidTimeList = get_trading_valid_time(),
    case lists:keyfind(Week,1,ValidTimeList) of
        false ->
            false;
        ValidTime ->
            check_trading_valid_time2(ValidTime,H,M,S)
    end.
check_trading_valid_time2(ValidTime,H,M,S) ->
    {_Week,TimeList} = ValidTime,
    lists:foldl(
      fun({{SH,SM},{EH,EM}},Acc) ->
              NowTimeSeconds = calendar:time_to_seconds({H,M,S}),
              StartTimeSeconds = calendar:time_to_seconds({SH,SM,0}),
              EndTimeSeconds = calendar:time_to_seconds({EH,EM,59}),
              if NowTimeSeconds >= StartTimeSeconds
                 andalso EndTimeSeconds >= NowTimeSeconds->
                      true;
                 true ->
                      Acc
              end
      end,false,TimeList).
%% 计算出下次更新时间间隔，单位为 秒
get_update_time_interval(MapId,NowSeconds) ->
    UpdatePriceTime = mod_trading_common:get_next_goods_price(MapId),
    UpdateNumberTime = mod_trading_common:get_next_goods_number(MapId),
    UpdateInterval1 = UpdatePriceTime - NowSeconds,
    UpdateInterval2 = UpdateNumberTime - NowSeconds,
    if UpdateInterval1 > 0
       andalso UpdateInterval2 > 0
       andalso UpdateInterval1 =< UpdateInterval2 ->
            UpdateInterval1; 
       UpdateInterval1 > 0
       andalso UpdateInterval2 > 0 
       andalso UpdateInterval2 =< UpdateInterval1 ->
            UpdateInterval2;
       true ->
            get_goods_default_update_interval()
    end.
%% 根据当前价格索引和当前价格变化时间计算出最佳购买时间间隔和出售时间间隔
%% 返回 {MaxBuyTime,MaxSaleTime}
get_max_interval_to_buy_or_sale(CurPriceIndex,CurSeconds,NowSeconds) ->
    PriceInterval = get_goods_price_update_interval(),
    MaxIndex = get_shop_max_goods_price_index(),
    MinIndex = get_shop_min_goods_price_index(),
    if MinIndex =:= CurPriceIndex ->
            NextPriceSeconds = (MaxIndex - CurPriceIndex) * PriceInterval + CurSeconds,
            {0,NextPriceSeconds - NowSeconds};
       MaxIndex =:= CurPriceIndex ->
            NextPriceSeconds = PriceInterval + CurSeconds,
            {NextPriceSeconds - NowSeconds,0};
       true ->
            MinSeconds = (MaxIndex + 1 - CurPriceIndex) * PriceInterval + CurSeconds,
            MaxSeconds = (MaxIndex - CurPriceIndex) * PriceInterval + CurSeconds,
            {MinSeconds - NowSeconds, MaxSeconds - NowSeconds}
    end.
%% 商店物品价格最低索引
get_shop_min_goods_price_index() ->
    case common_config_dyn:find(?TRADING_CONFIG,shop_min_goods_price_index) of
        [Value] ->
            Value;
        _ ->
            1
    end.
%% 商店物品价格最高索引
get_shop_max_goods_price_index() ->
    case common_config_dyn:find(?TRADING_CONFIG,shop_max_goods_price_index) of
        [Value] ->
            Value;
        _ ->
            8
    end.
%% 商贸商贸每组物品数量最大值
get_shop_max_group_goods_number() ->
    case common_config_dyn:find(?TRADING_CONFIG,shop_max_group_goods_number) of
        [Value] ->
            Value;
        _ ->
            20
    end.
%% 商贸玩家货舱每组物品数量最大值
get_role_max_group_goods_number() ->
    case common_config_dyn:find(?TRADING_CONFIG,role_max_group_goods_number) of
        [Value] ->
            Value;
        _ ->
            20
    end.
%% 商贸玩家货舱物品位置个数最大值
get_role_max_goods_pos_number() ->
    case common_config_dyn:find(?TRADING_CONFIG,role_max_goods_pos_number) of
        [Value] ->
            Value;
        _ ->
            20
    end.

%% 获取物品价格更新时间间隔，单位：秒
get_goods_price_update_interval() ->
    case common_config_dyn:find(?TRADING_CONFIG,goods_price_update_interval) of
        [Interval] ->
            Interval;
        _ ->
            60
    end.
%% 物品数量更新时间间隔，单位：秒
get_goods_number_update_interval() ->
    case common_config_dyn:find(?TRADING_CONFIG,goods_number_update_interval) of
        [Interval] ->
            Interval;
        _ ->
            600
    end.
%% 默认前端更新时间间隔，单位：秒
get_goods_default_update_interval() ->
    case common_config_dyn:find(?TRADING_CONFIG,goods_default_update_interval) of
        [Interval] ->
            Interval;
        _ ->
            10
    end.
%% 玩家商贸活动最低级别
get_role_min_role_level() ->
    case common_config_dyn:find(?TRADING_CONFIG,role_min_role_level) of
        [Value] ->
            Value;
        _ ->
            25
    end.

%% 玩家可以进行商贸活动的最低活跃值
%% 新需求，奖励算法变更
%get_role_min_active_points() ->
%    case common_config_dyn:find(?TRADING_CONFIG,role_min_active_points) of
%        [Value] ->
%            Value;
%        _ ->
%            1000
%    end.
%% 宗族收益获取比例，单位：万分比
%% 新需求，屏蔽掉商贸宗族奖励
%get_trading_family_income_scale() ->
%    case common_config_dyn:find(?TRADING_CONFIG,trading_family_income_scale) of
%        [Value] ->
%            Value;
%        _ ->
%            100
%    end.

%% 商贸每次完成增加玩家宗族贡献度配置
%% 新需求，屏蔽掉商贸宗族奖励
%get_trading_role_family_contribution() ->
%    case common_config_dyn:find(?TRADING_CONFIG,trading_role_family_contribution) of
%        [Value] ->
%            Value;
%        _ ->
%            3
%    end.
%% 商贸交还商票时扣除背包配置
get_deduct_trading_income_item_bag_ids() ->
    case common_config_dyn:find(?TRADING_CONFIG,deduct_trading_income_item_bag_ids) of
        [Value] ->
            Value;
        _ ->
            [1,2,3,4]
    end.
%% 可以使用增加商贸收益道具配置
%% 返回 {ok,r_trading_income_item} or {error,Reason}
%% 新需求，屏蔽掉商贸宝典
%get_trading_income_item(ItemId) ->
%    case common_config_dyn:find(?TRADING_CONFIG,trading_income_item) of
%        [DataList] ->
%            lists:foldl(
%              fun(R,Acc) ->
%                      {Flag,_Reason} = Acc,
%                      case Flag of
%                          ok ->
%                              Acc;
%                          false ->
%                              if R#r_trading_income_item.item_id =:= ItemId ->
%                                      {ok,R};
%                                 true ->
%                                      Acc
%                              end
%                      end
%              end,{false,not_found},DataList);
%        _ ->
%            {error,not_found}
%    end.
%% 
%% 商贸宝典道具配置
%% 商贸宝典道具id,与宗族贡献度比例 5 
%% 返回 {ItemId,ItemNumber,Bind}
get_trading_book_item() ->
    case common_config_dyn:find(?TRADING_CONFIG,trading_book_item) of
        [List] ->
            List;
        _ ->
            {10100031,5,true}
    end.
%% 可获取商贸宝典物品的NPC配置
%% 返回 [] or [r_trading_bill_npc]
get_trading_book_npc() ->
    case common_config_dyn:find(?TRADING_CONFIG,trading_book_npc) of
        [List] ->
            List;
        _ ->
            []
    end.
%% 返回 true or false
check_trading_book_npc(FactionId,MapId,NpcId) ->
    BookNpcList = get_trading_book_npc(),
    lists:foldl(
      fun(BookNpc,Acc) ->
              if BookNpc#r_trading_bill_npc.faction_id =:= FactionId
                 andalso BookNpc#r_trading_bill_npc.map_id =:= MapId
                 andalso BookNpc#r_trading_bill_npc.npc_id =:= NpcId ->
                      true;
                 true ->
                      Acc
              end
      end,false,BookNpcList).
%% 可获取或交还商贸商票功能的NPC配置
%% 返回 [] or r_trading_bill_npc
get_trading_bill_npc() ->
    case common_config_dyn:find(?TRADING_CONFIG,trading_bill_npc) of
        [List] ->
            List;
        _ ->
            []
    end.
%% 返回 true or false
check_trading_bill_npc(FactionId,MapId,NpcId) ->
    BillNpcList = get_trading_bill_npc(),
    lists:foldl(
      fun(BillNpc,Acc) ->
              if BillNpc#r_trading_bill_npc.faction_id =:= FactionId
                 andalso BillNpc#r_trading_bill_npc.map_id =:= MapId
                 andalso BillNpc#r_trading_bill_npc.npc_id =:= NpcId ->
                      true;
                 true ->
                      Acc
              end
      end,false,BillNpcList).
%% 玩家每天可进行的最多商贸次数
get_role_max_trading_times() ->
    case common_config_dyn:find(?TRADING_CONFIG,role_max_trading_times) of
        [Value] ->
            Value;
        _ ->
            3
    end.
%% 宗族商贸日消息广播配置
get_trading_broadcast_message_config() ->
    case common_config_dyn:find(?TRADING_CONFIG,trading_broadcast_message_config) of
        [Value] ->
            Value;
        _ ->
            {[7],600}
    end.
%% 根据当前时间获取发送商贸消息广播消息的时间段
%% NowDate 结构为 erlang:date()
%% 返回 {ok,TimeRangeList,Interval} or {error,Reason}
get_trading_broadcast_message_time_range(NowDate) ->
    TodayWeek = calendar:day_of_the_week(NowDate),
    {BCWeekList,Interval} = 
        get_trading_broadcast_message_config(),
    case lists:member(TodayWeek,BCWeekList) of
        true ->
            ValidTimeList = get_trading_valid_time(),
            case lists:keyfind(TodayWeek,1,ValidTimeList) of
                false ->
                    {error,not_broadcast_time};
                {TodayWeek,TimeRangeList} ->
                    {ok,TimeRangeList,Interval}
            end;
        false ->
            {error,not_broadcast_day}
    end.

%% 根据玩家的级别获取玩家商票配置信息
%% RoleLevel 玩家级别
%% 返回 {ok,r_role_trading_bill} or {error,Reason}
get_role_trading_bill(RoleLevel) ->
    %% 结构为 r_role_trading_bill
    case common_config_dyn:find(?TRADING_CONFIG,role_trading_bill) of
        [DataList] ->
            lists:foldl(
              fun(R,Acc) ->
                      {Flag,_Reason} = Acc,
                      case Flag of
                          ok ->
                              Acc;
                          error ->
                              MinLevel = R#r_role_trading_bill.min_level,
                              MaxLevel = R#r_role_trading_bill.max_level,
                              if RoleLevel >= MinLevel
                                 andalso MaxLevel >= RoleLevel ->
                                      {ok,R};
                                 true ->
                                      Acc
                              end
                      end
              end,{error,not_found},DataList);
        _ ->
            {error,not_found}
    end.
%% 获取商贸商票物品类型id列表
%% 返回 [] or [TypeId,..]
get_role_trading_bill_type_ids() ->
    case common_config_dyn:find(?TRADING_CONFIG,role_trading_bill) of
        [DataList] ->
            [R#r_role_trading_bill.item_id || R <- DataList];
        _ ->
            []
    end.
%% 获取需要初始化商贸商店信息列表
%% 返回[] or [r_trading_shop_info]
get_trading_shop_info() ->
    case common_config_dyn:find(?TRADING_CONFIG,trading_shop_info) of
        [List] ->
            List;
        _ ->
            []
    end.
%% 根据国家id获取需要初始化商贸商店信息列表
%% 返回[] or [r_trading_shop_info]
get_trading_shop_info_by_faction_id(FactionId) ->
    ShopInfoList = get_trading_shop_info(),
    [R || R <- ShopInfoList,R#r_trading_shop_info.faction_id =:= FactionId].

%% 获取提前计算商贸商店价格变化信息的地图id,
get_trading_shop_godds_price_map_id() ->
    ShopInfoList = get_trading_shop_info(),
    if ShopInfoList =:= [] ->
            10260;
       true ->
            R = lists:nth(1,ShopInfoList),
            R#r_trading_shop_info.map_id
    end.
%% 根据商店配置信息获取物品信息
%% 参数 
% TradingShopInfo 结构为 r_trading_shop_info
%% 返回结果为 {ok,[],Index} or {ok,[p_trading_goods],Index}
get_trading_shop_goods_by_config(TradingShopInfo,PriceIndex,SalePriceIndex) ->
    #r_trading_shop_info{goods_ids = GoodsIds} = TradingShopInfo,
    [IsOpenChangePrice] = common_config_dyn:find(?TRADING_CONFIG,is_open_change_price),
    GoodsBaseInfoList = mod_trading_config:get(?TRADING_GOODS_CONFIG),
    lists:foldl(
      fun(GB,Acc) ->
              TypeId = GB#p_trading_goods_base_info.type_id,
              case lists:member(TypeId,GoodsIds) of
                  true ->
                      Prices = GB#p_trading_goods_base_info.prices,
                      Price = lists:nth(PriceIndex,Prices),
                      SalePrice = 
                          case IsOpenChangePrice of
                              true ->
                                  0;
                              _ ->
                                  lists:nth(SalePriceIndex,Prices)
                          end,
                      Goods = #p_trading_goods{
                        type_id = GB#p_trading_goods_base_info.type_id,
                        order_index = GB#p_trading_goods_base_info.order_index,
                        name = GB#p_trading_goods_base_info.name,
                        price = Price,
                        number = GB#p_trading_goods_base_info.number,
                        sale_price = SalePrice
                       },
                      [Goods|Acc];
                  false ->
                      Acc
              end
      end,[],GoodsBaseInfoList).

%% 商贸活动玩家与NPC的有效距离 {tx,ty}
%% get_trading_role_npc_valid_distance() ->
%%     case common_config_dyn:find(?TRADING_CONFIG,trading_role_npc_valid_distance) of
%%         [Value] ->
%%             Value;
%%         _ ->
%%             {10,10}
%%     end.
%% 检查玩家是否在有效的距离内
%% 参数
%% RoleId 玩家 id
%% NpcId 商贸商店NPC ID
%% 返回 true or false
check_valid_distance(_RoleId,_NpcId) ->
	true.
%%     case mod_map_actor:get_actor_pos(RoleId, role) of
%%         undefined ->
%%             ?ERROR_MSG("~ts", ["获取玩家位置信息出错"]),
%%             false;
%%         _ ->
%%             true
%%     end. 

%% 商贸商店物品价格变动时间配置
get_trading_goods_price_reload_time() ->
    Value = 
        case common_config_dyn:find(?TRADING_CONFIG,trading_goods_price_reload_time) of
            [ValueT] ->
                ValueT;
            _ ->
                [{0,0,0},{12,0,0}]
        end,
    [common_tool:datetime_to_seconds({erlang:date(),{H,M,S}})|| {H,M,S} <- Value].

%% 根据商贸商店的配置信息随机计算出每一个商店的初始化物品价格记录
%% 返回 [r_trading_shop_price] or []
get_trading_shop_price() ->
    ?INFO_MSG("~ts",["不要调用我多次，一次就够了"]),
    [IsOpenChangePrice] = common_config_dyn:find(?TRADING_CONFIG,is_open_change_price),
    [ShopInfoList] =  common_config_dyn:find(?TRADING_CONFIG,trading_shop_info),
    ShopPriceList = 
        lists:foldl(
          fun(ShopInfo,Acc) ->
                  InitPriceIndexs = ShopInfo#r_trading_shop_info.init_price_indexs,
                  InitIndex = 
                      case IsOpenChangePrice =:= false of
                          true ->
                              ShopInfo#r_trading_shop_info.buy_price_index;
                          _ ->
                              if erlang:length(InitPriceIndexs) =:= 1 ->
                                      lists:nth(1,InitPriceIndexs);
                                 true ->
                                      0
                              end
                      end,
                  ShopPrice = #r_trading_shop_price{
                    npc_id = ShopInfo#r_trading_shop_info.npc_id,
                    faction_id = ShopInfo#r_trading_shop_info.faction_id,
                    map_id = ShopInfo#r_trading_shop_info.map_id,
                    price_indexs = InitPriceIndexs,
                    best_index = ShopInfo#r_trading_shop_info.best_price_index,
                    init_index = InitIndex},
                  [ShopPrice | Acc]
          end,[],ShopInfoList),
    case IsOpenChangePrice =:= false of
        true ->
            ShopPriceList;
        _ ->
            get_trading_shop_price2(ShopPriceList)
    end.

get_trading_shop_price2(ShopPriceList) ->
    ClassShopPriceList = 
        lists:foldl(
          fun(ShopPrice,Acc) ->
                  FactionId = ShopPrice#r_trading_shop_price.faction_id,
                  InitIndex = ShopPrice#r_trading_shop_price.init_index,
                  if InitIndex =/= 0 ->
                          Acc;
                     true ->
                          case lists:keyfind(FactionId,1,Acc) of
                              false ->
                                  [{FactionId,[ShopPrice]}|Acc];
                              {FactionId,AccList} ->
                                  Acc2 = lists:keydelete(FactionId,1,Acc),
                                  [{FactionId,[ShopPrice|AccList]}|Acc2]
                          end
                  end
          end,[],ShopPriceList),
    get_trading_shop_price3(ShopPriceList,ClassShopPriceList).
get_trading_shop_price3(ShopPriceList,ClassShopPriceList) ->
    ShopPriceList2 = 
        lists:foldl(
          fun({_FactionId,AccList},Acc) ->
                  AccLen = erlang:length(AccList),
                  RandomNumber = random:uniform(AccLen),
                  BestShopPrice = lists:nth(RandomNumber,AccList),
                  BestShopPrice2 = BestShopPrice#r_trading_shop_price{
                                    init_index = BestShopPrice#r_trading_shop_price.best_index},
                  AccLists2 = lists:keydelete(
                                BestShopPrice#r_trading_shop_price.npc_id,
                                #r_trading_shop_price.npc_id,AccList),
                  AccLists3 = 
                      lists:map(
                        fun(ShopPrice) ->
                                PriceIndexs = ShopPrice#r_trading_shop_price.price_indexs,
                                PriceIndex = random:uniform(erlang:length(PriceIndexs)),
                                InitIndex = lists:nth(PriceIndex,PriceIndexs),
                                ShopPrice#r_trading_shop_price{init_index = InitIndex}
                        end,AccLists2),
                  lists:append([[BestShopPrice2],AccLists3,Acc])
          end,[],ClassShopPriceList),
    get_trading_shop_price4(ShopPriceList,ShopPriceList2).
get_trading_shop_price4(ShopPriceList,ShopPriceList2) ->
    lists:foldl(
      fun(ShopPrice,Acc) ->
              NpcId = ShopPrice#r_trading_shop_price.npc_id,
              case lists:keyfind(NpcId,#r_trading_shop_price.npc_id,ShopPriceList2) of
                  false ->
                      [ShopPrice | Acc];
                  RsShopPrice ->
                      InitIndex = RsShopPrice#r_trading_shop_price.init_index,
                      ShopPrice2 = ShopPrice#r_trading_shop_price{init_index = InitIndex},
                      [ShopPrice2 | Acc]
              end
      end,[],ShopPriceList).

%% 根据当前时间计算出重置下次商贸商店信息时间
get_reload_trading_shop_seconds(NowSeconds) ->
    ReloadTimes = get_trading_goods_price_reload_time(),
    ReloadTimes2 = lists:sort(ReloadTimes),
    Length = erlang:length(ReloadTimes2),
    {true,_AccIndex,RsSeconds} = 
        lists:foldl(
          fun(Seconds,Acc) ->
                  {Flag,Index,RsAcc}=Acc,
                  case Flag of 
                      true ->
                          Acc;
                      false ->
                          if Index < Length ->
                                  Seconds2 = lists:nth(Index + 1,ReloadTimes2),
                                  if NowSeconds > Seconds
                                     andalso NowSeconds < Seconds2 ->
                                          {true,Index + 1,Seconds2};
                                     NowSeconds < Seconds ->
                                          {true,Index + 1,Seconds};
                                     true ->
                                          {Flag,Index + 1,RsAcc}
                                  end;
                             true ->
                                  if Seconds > NowSeconds ->
                                          {true,Index + 1,Seconds};
                                     true ->
                                          Seconds3 = lists:nth(1,ReloadTimes2),
                                          Seconds4 = Seconds3 + 60 * 60 * 24,
                                          {true,Index + 1,Seconds4}
                                  end
                          end
                  end
          end,{false,1,0},ReloadTimes2),
    ?DEV("~ts,NowSeconds=~w,RsSeconds=~w",["当前启动时间计算出下次商贸商店重新初始化时间",NowSeconds,RsSeconds]),
    RsSeconds.

%% 判断是否需要更新随机变化商店的初始价格
%% MapId 地图id
%% NowSeconds 当前时间 common_tool:now()
%% 返回 true or false
check_reload_trading_shop_goods_price(MapId,NowSeconds) ->
    case mod_trading_common:get_trading_reload_shop_goods(MapId) of
        undefined ->
            ?DEV("~ts,MapId=~w",["获取进程字典时的下次初始化时间出错undefined",MapId]),
            UpdateSeconds = get_reload_trading_shop_seconds(NowSeconds),
            mod_trading_common:put_trading_reload_shop_goods(MapId,{UpdateSeconds,0}),
            false;
        {UpdateTime,0} ->
            ?DEV("~ts,UpdateTime=~w,NowSeconds=~w",["获取进程字典时的下次初始化时间",UpdateTime,NowSeconds]),
            if NowSeconds >= UpdateTime ->
                    UpdateSeconds2 = get_reload_trading_shop_seconds(NowSeconds),
                    mod_trading_common:put_trading_reload_shop_goods(MapId,{UpdateSeconds2,0}),
                    true;
               true ->
                    false
            end;
        {_,1} ->
            ?DEV("~ts,MapId=~w",["获取进程字典时的下次初始化时间出错,状态为1",MapId]),
            false
    end.


%% 是否需要发送商贸消息广播
check_trading_broadcast_message(MapId,NowSeconds) ->
    {NowDate,_NowTime} =
        common_tool:seconds_to_datetime(NowSeconds),
    %% Status 状态 1 未处理，2 已处理
    case mod_trading_common:get_trading_broadcast_message(MapId) of
        {NowDate,1} ->
            true;
        {NowDate,2} ->
            false;
        _ ->
            %% 过天处理
            false
    end.
send_trading_broadcast_message(MapId,NowSeconds) ->
    {NowDate,_NowTime} =
        common_tool:seconds_to_datetime(NowSeconds),
    mod_trading_common:put_trading_broadcast_message(MapId,{NowDate,2}),
    %% 返回 {ok,TimeRangeList,Interval} or {error,Reason}
    case get_trading_broadcast_message_time_range(NowDate) of
        {ok,TimeRangeList,Interval} ->
            lists:foreach(
              fun({{SH,SM},{EH,EM}}) ->
                      StartSeconds = common_tool:datetime_to_seconds({NowDate,{SH,SM,0}}),
                      EndSeconds = common_tool:datetime_to_seconds({NowDate,{EH,EM,0}}),
                      erlang:send(self(),{mod_trading,{send_broadcast_message,StartSeconds,EndSeconds,Interval}})
              end,TimeRangeList);
        {error,_Reason} ->
            next
    end.


%% 是否需要发送商贸消息广播（商贸结束广播）
check_trading_end_broadcast_message(MapId,NowSeconds) ->
    BroadcastSeconds =  mod_trading_common:get_trading_end_broadcast_status(MapId),
    if BroadcastSeconds < 0 ->
            true;
       NowSeconds >= BroadcastSeconds ->
            true;
       true ->
            false
    end.

send_trading_end_broadcast_message(MapId,NowSeconds) ->
    {NowDate,_NowTime} =
        common_tool:seconds_to_datetime(NowSeconds),
    TodayWeek = calendar:day_of_the_week(NowDate),
    BroadcastSeconds =  mod_trading_common:get_trading_end_broadcast_status(MapId),
    NextBroadcastSeconds = common_tool:datetime_to_seconds({NowDate,{0,0,0}}) + 24 * 60 * 60,%% 下一天计算发送时间
    case get_trading_end_broadcast_message_config(TodayWeek) of
        {_,[],_} ->
            mod_trading_common:put_trading_end_broadcast_status(MapId,NextBroadcastSeconds);
        {TodayWeek,BcSecondsList,EndSeconds} ->
            MinBcSeconds = lists:nth(1,BcSecondsList),
            MinBcSeconds2 = 
                lists:foldl(
                  fun(BcSeconds,Acc) ->
                          if NowSeconds >= BcSeconds ->
                                  BcSeconds;
                             true ->
                                  Acc
                          end
                  end,MinBcSeconds,BcSecondsList),
            if NowSeconds > EndSeconds ->
                    mod_trading_common:put_trading_end_broadcast_status(MapId,NextBroadcastSeconds);
               MinBcSeconds2 > BroadcastSeconds ->
                    mod_trading_common:put_trading_end_broadcast_status(MapId,MinBcSeconds2);
               true ->
                    send_trading_end_broadcast_message2(MapId,NowSeconds,NowDate,TodayWeek,BcSecondsList,EndSeconds)
            end;
        _ ->
            mod_trading_common:put_trading_end_broadcast_status(MapId,NextBroadcastSeconds)
    end.
send_trading_end_broadcast_message2(MapId,NowSeconds,NowDate,TodayWeek,BcSecondsList,EndSeconds) ->
    BroadcastSeconds =  mod_trading_common:get_trading_end_broadcast_status(MapId),
    BcLen = erlang:length(BcSecondsList),
    {Flag,Index} = 
        lists:foldl(
          fun(BcSeconds,Acc) ->
                  {AccFlag,AccIndex} = Acc,
                  case AccFlag of
                      false ->
                          if BroadcastSeconds =:= BcSeconds ->
                                  {true,AccIndex};
                             true ->
                                  {AccFlag,AccIndex + 1}
                          end;
                      true ->
                          Acc
                  end
          end,{false,1},BcSecondsList),
    case Flag of
        true ->
            %% 需要发送
            Minutes = (EndSeconds - NowSeconds) div 60,
            Minutes2 = if Minutes > 0 -> Minutes; true -> 0 end,
            {CenterMessage,LeftMessage} =
                if Minutes2 =:= 0 ->
                        if TodayWeek =:= 7 ->
                                {?_LANG_TRADING_SUNDAY_BC_END_CENTER_Z,
                                 ?_LANG_TRADING_SUNDAY_BC_END_CHAT_Z};
                           true ->
                                {?_LANG_TRADING_DAY_BC_END_CENTER_Z,
                                 ?_LANG_TRADING_DAY_BC_END_CHAT_Z}
                        end;
                   true ->
                        Minutes3 = common_tool:to_list(Minutes2),
                        if TodayWeek =:= 7 ->
                                {lists:flatten(io_lib:format(?_LANG_TRADING_SUNDAY_BC_END_CENTER,[Minutes3])),
                                 lists:flatten(io_lib:format(?_LANG_TRADING_SUNDAY_BC_END_CHAT,[Minutes3]))};
                           true ->
                                {lists:flatten(io_lib:format(?_LANG_TRADING_DAY_BC_END_CENTER,[Minutes3])),
                                 lists:flatten(io_lib:format(?_LANG_TRADING_DAY_BC_END_CHAT,[Minutes3]))}
                        end
                end,
            catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_SUB_TYPE,CenterMessage),
            catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,LeftMessage);
        false ->
            next
    end,
    if Flag =:= false orelse Index >= BcLen ->
            NextBroadcastSeconds = common_tool:datetime_to_seconds({NowDate,{0,0,0}}) + 24 * 60 * 60,%% 下一天计算发送时间
            mod_trading_common:put_trading_end_broadcast_status(MapId,NextBroadcastSeconds);
       true ->
            NextBroadcastSeconds = lists:nth(Index + 1,BcSecondsList),
            mod_trading_common:put_trading_end_broadcast_status(MapId,NextBroadcastSeconds)
    end.
%% 每天商贸结束时间段提前消息广播
%% 星期几，发送结束消息广播的时间点，结束时间
%% {1,[{18,40,0},{18,45,0},{18:50,0},{18:51,0},{18,53,0},{18,56,0},{18,59,0}],{19,0,0}},
get_trading_end_broadcast_message_config(TodayWeek) ->
    case common_config_dyn:find(?TRADING_CONFIG,trading_end_broadcast_message_config) of
        [ValueList] ->
            case lists:keyfind(TodayWeek,1,ValueList) of
                false ->
                    {0,[],0};
                {Week,TimesList,{EH,EM}} ->
                    TimesList2 = [common_tool:datetime_to_seconds({erlang:date(),{H,M,0}}) || {H,M} <- TimesList],
                    TimesList3= lists:sort(TimesList2),
                    EndTime2 = common_tool:datetime_to_seconds({erlang:date(),{EH,EM,0}}),
                    {Week,TimesList3,EndTime2}
            end;
        _ ->
            {0,[],0}
    end.

%% 玩家商贸状态中死亡书信通知玩家处理
hook_role_dead_letter(RoleId,_RoleMapInfo,SrcActorId,SrcActorType) ->
    LetterText = 
        case SrcActorType of
            role ->
                {FactionId,RoleName} = 
                    case mod_map_actor:get_actor_mapinfo(SrcActorId,role) of
                        undefined ->
                            case common_misc:get_dirty_role_base(SrcActorId) of
                                {ok,#p_role_base{faction_id = FactionIdT,role_name = RoleNameT}}->
                                    {FactionIdT,common_tool:to_list(RoleNameT)};
                                _ ->
                                    {"",""}
                            end;
                        #p_role_base{faction_id = FactionIdT,role_name = RoleNameT} ->
                            {FactionIdT,common_tool:to_list(RoleNameT)}
                    end,
                FactionName = 
                    if FactionId =:= 1 ->
                            lists:append(["<font color=\"#00FF00\">【",
                                          common_tool:to_list(?_LANG_FACTION_CONST_1),
                                          "】</font>"]);
                       FactionId =:= 2 ->
                            lists:append(["<font color=\"#F600FF\">【",
                                          common_tool:to_list(?_LANG_FACTION_CONST_2),
                                          "】</font>"]);
                       FactionId =:= 3 ->
                            lists:append(["<font color=\"#00CCFF\">【",
                                          common_tool:to_list(?_LANG_FACTION_CONST_3),
                                          "】</font>"]);
                       true ->
                            {"",""}
                    end,
                common_letter:create_temp(?TRADING_LOST_ROLE_LETTER,[FactionName, RoleName]);
            _ ->
                common_letter:create_temp(?TRADING_LOST_MONSTER_LETTER,[])
        end,
    common_letter:sys2p(RoleId,LetterText,"商贸遇劫的通知",2).

