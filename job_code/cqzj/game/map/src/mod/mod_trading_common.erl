%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2010, 
%%% @doc
%%% 商贸活动公共模块
%%% 提供商贸活动相关的玩家商贸货舱的操作接口
%%% @end
%%% Created : 25 Dec 2010 by  <caochuncheng>
%%%-------------------------------------------------------------------
-module(mod_trading_common).

-include("mgeem.hrl").
-include("trading.hrl").

%% API
-export([
         %% 保存商贸商店物品信息
         put_shop_goods/3,
         %% 获取商贸商店物品信息
         get_shop_goods/2,
         %% 保存下次物品价格更新时间
         put_next_goods_price/2,
         %% 获取下次物品价格更新时间
         get_next_goods_price/1,
         %% 保存下次物品数量更新时间
         put_next_goods_number/2,
         %% 获取下次物品数量更新时间
         get_next_goods_number/1,

         %% 玩家商贸信息
         %% 保存商贸玩家信息
         put_role_trading/2,
         %% 获取商贸玩家信息
         get_role_trading/1,
         

         %% 地图商贸商店初始化数据标志
         put_trading_shop_init_status/2,
         get_trading_shop_init_status/1,

         %% 重新初始化商贸商店物品信息
         put_trading_reload_shop_goods/2,
         get_trading_reload_shop_goods/1,

         %% 商贸消息广播处理状态保存
         put_trading_broadcast_message/2,
         get_trading_broadcast_message/1,

         %% 商贸结束消息广播状态
         put_trading_end_broadcast_status/2,
         get_trading_end_broadcast_status/1
         
        ]).

%%%===================================================================
%%% API
%%%===================================================================

%% 保存商贸商店物品信息
%% 参数
%% MapId 地图id
%% NpcId 商贸商店NPC id
%% GoodsRecord 商贸商店信息 r_trading_shop_goods
%% 返回 ok or erlang:throw({error,Reason})
put_shop_goods(MapId,NpcId,GoodsRecord) ->
    erlang:put({?TRADING_SHOP_DICT_PREFIX,MapId,NpcId},GoodsRecord).
%% 获取商贸商店物品信息
get_shop_goods(MapId,NpcId) ->
    erlang:get({?TRADING_SHOP_DICT_PREFIX,MapId,NpcId}).

%% 保存下次物品价格更新时间
put_next_goods_price(MapId,NextSeconds) ->
    erlang:put({?TRADING_PRICE_SECONDS_DICT_PREFIX,MapId},NextSeconds).
%% 获取下次物品价格更新时间
get_next_goods_price(MapId) ->
    erlang:get({?TRADING_PRICE_SECONDS_DICT_PREFIX,MapId}).

%% 保存下次物品数量更新时间
put_next_goods_number(MapId,NextSeconds) ->
    erlang:put({?TRADING_NUMBER_SECONDS_DICT_PREFIX,MapId},NextSeconds).
%% 获取下次物品数量更新时间
get_next_goods_number(MapId) ->
    erlang:get({?TRADING_NUMBER_SECONDS_DICT_PREFIX,MapId}).
    
%% 保存商贸玩家信息
%% RoleId 玩家id RoleTrading 玩家商贸记录信息 r_role_trading
put_role_trading(RoleId,RoleTrading) ->
    erlang:put({?ROLE_TRADING_DICT_PREFIX,RoleId},RoleTrading). 
%% 获取商贸玩家信息
%% RoleId 玩家id
get_role_trading(RoleId) ->
    erlang:get({?ROLE_TRADING_DICT_PREFIX,RoleId}).

%% 地图商贸商店初始化数据标志
%% Status 状态 1 未初始化，2 已初始化
put_trading_shop_init_status(MapId,Status) ->
    erlang:put({?TRADING_SHOP_INIT_STATUS_DICT_PREFIX,MapId},Status).
get_trading_shop_init_status(MapId) ->
    case erlang:get({?TRADING_SHOP_INIT_STATUS_DICT_PREFIX,MapId}) of
        undefined ->
            1;
        Value ->
            Value
    end.

put_trading_reload_shop_goods(MapId,State) ->
    erlang:put({?TRADING_RELOAD_SHOP_GOODS_DICT_PREFIX,MapId},State).
get_trading_reload_shop_goods(MapId) ->
    erlang:get({?TRADING_RELOAD_SHOP_GOODS_DICT_PREFIX,MapId}).


%% 商贸广播消息处理
%% Date erlang:date()
%% Status 状态 1 未处理，2 已处理
%% erlang:put({trading_broadcast_status,MapId},{Date,Status})
put_trading_broadcast_message(MapId,BCData) ->
    erlang:put({?TRADING_BROADCAST_STATUS_DICT_PREFIX,MapId},BCData).
get_trading_broadcast_message(MapId) ->
    case erlang:get({?TRADING_BROADCAST_STATUS_DICT_PREFIX,MapId}) of
        undefined ->
            {erlang:date(),1};
        Value ->
            Value
    end.
    
%% 商贸广播消息处理（商贸结束广播）
%% NextBroadcastSeconds 下次广播时间 common_tool:now()
%% erlang:put({trading_end_broadcast_status,MapId},NextBroadcastSeconds)
put_trading_end_broadcast_status(MapId,NextBroadcastSeconds) ->
    erlang:put({?TRADING_END_BROADCAST_STATUS_DICT_PREFIX,MapId},NextBroadcastSeconds).
get_trading_end_broadcast_status(MapId) ->
    case erlang:get({?TRADING_END_BROADCAST_STATUS_DICT_PREFIX,MapId}) of
        undefined ->
            -1;
        Value->
            Value
    end.


    
