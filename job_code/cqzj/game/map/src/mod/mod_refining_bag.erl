%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2010, 
%%% @doc
%%% 装备精炼系统公用模块
%%% @end
%%% Created :  1 Dec 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_refining_bag).

-include("mgeem.hrl").

%% key 结构为{role_bag,role_id,bag_id}
-define(ROLE_BAG_DICT_PREFIX,role_bag).
%% key 结果为{role_bag_list,role_id}
-define(ROLE_BAG_LIST_DICT_PREFIX,role_bag_list).
%% key 结果为{role_bank_list,role_id}
-define(ROLE_BANK_LIST_DICT_PREFIX,role_bank_list).
%% 人物掉落物品
-define(ROLE_DROP_GOODS_LIST_DICT,role_drop_goods_list).
-define(ROLE_DROP_GOODS_ID_DICT,role_drop_goods_id).

-export([
         %% 根据背包id列表
         %% 返回结果 [p_goods] 或者 []
         get_goods_by_bag_ids/2,
         %% 根据背包id列表,物品类型id物品信息
         %% 返回结果 [p_goods] 或者 []
         get_goods_by_bag_ids_and_type_id/3,
         
         %% 根据背包id列表,物品类型id列表物品信息
         %% 返回结果 [p_goods] 或者 []
         get_goods_by_bag_ids_and_type_ids/3,
         %% 根据背包id获取物品信息
         %% 返回结果[p_goods] 或者 []
         get_goods_by_bag_id/2,
         %% 根据背包id,物品type id获取物品信息
         %% 返回结果[p_goods] 或者 []
         get_goods_by_bag_id_and_item_id/3,
         %% 根据需要获取的背包id，获取当前用户拥有的背包id
         %% 返回结果[bagId] 或者 []
         get_role_exist_bags/2,
         %% 根据背包id列表,物品类型id物品信息
         %% 返回结果为：{error,Reason}或者{ok,p_goods}
         get_goods_by_bag_ids_and_goods_id/3,
         %% 根据背包id,物品id查询某一物品信息
         %% 返回结果为：{error,Reason}或者{ok,p_goods}
         get_goods_by_bag_id_goods_id/3
        ]).

%% 人物掉落物品进程字典处理API
-export([
         %% 将掉落物品放入地图进程字典
         %% 返回{ok,p_goods}或者erlang:throw({error,Reason})
         put_drop_goods/2,
         %% 根据物品id获取物品信息
         %% 返回 {ok,p_goods}或者erlang:throw({error,Reason})
         get_drop_goods/1,
         %% 根据物品id 删除物品信息
         %% 返回 {ok} 或者 erlang:throw({error,Reason})
         delete_drop_goods/1,
         %% 根据物品id，删除物品信息并返回
         %% 返回 {ok,p_goods} 或者 erlang:throw({error,Reason})
         pop_drop_goods/1,
         %% 初始化掉落物品id
         init_drop_goods_id/0,
         %% 获取人物掉落物品最大id
         get_drop_goods_max_id/0
        ]).
%% API

%% 根据背包id列表
%% 参数
%% RoleId 用户id
%% BagIds 背包id列表 [1,2,3,4,5,...]
%% 返回结果 [p_goods] 或者 []
get_goods_by_bag_ids(RoleId,BagIds) ->
    BagIds2 = get_role_exist_bags(RoleId,BagIds),
    lists:foldl(
      fun(BagId,AccList) ->
              lists:append([get_goods_by_bag_id(RoleId,BagId), AccList])
      end,[],BagIds2).

%% 根据背包id列表,物品类型id物品信息
%% 参数
%% RoleId 用户id
%% BagIds 背包id列表 [1,2,3,4,5,...]
%% ItemId 物品类型id
%% 返回结果 [p_goods] 或者 []
get_goods_by_bag_ids_and_type_id(RoleId,BagIds,ItemId) ->
    BagIds2 = get_role_exist_bags(RoleId,BagIds),
    GoodsList = 
        lists:foldl(
          fun(BagId,AccList) ->
                  lists:append([get_goods_by_bag_id(RoleId,BagId), AccList])
          end,[],BagIds2),
    lists:foldl(
      fun(Goods,AccList) ->
              TypeId = Goods#p_goods.typeid,
              if TypeId =:= ItemId ->
                      [Goods|AccList];
                 true ->
                      AccList
              end
      end,[],GoodsList).

%% 根据背包id列表,物品类型id列表物品信息
%% 参数
%% RoleId 用户id
%% BagIds 背包id列表 [1,2,3,4,5,...]
%% ItemIds 物品类型id列表 [ItemId,....]
%% 返回结果 [p_goods] 或者 []
get_goods_by_bag_ids_and_type_ids(RoleId,BagIds,ItemIds) ->
    BagIds2 = get_role_exist_bags(RoleId,BagIds),
    GoodsList = 
        lists:foldl(
          fun(BagId,AccList) ->
                  lists:append([get_goods_by_bag_id(RoleId,BagId), AccList])
          end,[],BagIds2),
    lists:foldl(
      fun(Goods,AccList) ->
              TypeId = Goods#p_goods.typeid,
              case lists:member(TypeId,ItemIds) of
                  true ->
                      [Goods|AccList];
                  false ->
                      AccList
              end
      end,[],GoodsList).

%% 根据背包id获取物品信息
%% 参数
%% RoleId 用户id
%% BagId 背包id
%% 返回结果[p_goods] 或者 []
get_goods_by_bag_id(RoleId,BagId) ->
    case erlang:get({?ROLE_BAG_DICT_PREFIX,RoleId,BagId}) of
        undefined ->
            [];
        {_Content,_OutUseTime,_UsedPosList,GoodsList,_Modified} ->
            GoodsList
    end.
    

%% 根据背包id,物品type id获取物品信息
%% 参数
%% RoleId 用户id
%% BagId 背包id
%% ItemId 物品类型id
%% 返回结果[p_goods] 或者 []
get_goods_by_bag_id_and_item_id(RoleId,BagId,ItemId) ->
    GoodsList = get_goods_by_bag_id(RoleId,BagId),
    lists:foldl(
      fun(Goods,AccList) ->
              TypeId = Goods#p_goods.typeid,
              if TypeId =:= ItemId ->
                      [Goods|AccList];
                 true ->
                      AccList
              end
      end,[],GoodsList).
%% 根据背包id列表,物品id物品信息
%% 参数
%% RoleId 用户id
%% BagIds 背包id列表 [1,2,3,4,5,...]
%% GoodsId #p_good.id 物品id
%% 返回结果为：{error,Reason}或者{ok,p_goods}
get_goods_by_bag_ids_and_goods_id(RoleId,BagIds,GoodsId) ->
    BagIds2 = get_role_exist_bags(RoleId,BagIds),
    GoodsList = 
        lists:foldl(
          fun(BagId,AccList) ->
                  lists:append([get_goods_by_bag_id(RoleId,BagId),AccList])
          end,[],BagIds2),
    RsList = lists:foldl(
               fun(Goods,AccList) ->
                       Id = Goods#p_goods.id,
                       if GoodsId =:= Id ->
                               [Goods|AccList];
                          true ->
                               AccList
                       end
               end,[],GoodsList),
    if erlang:length(RsList) =:= 1 ->
            [H] = RsList,
            {ok,H};
       erlang:length(RsList) =:= 0 ->
            {error,not_found};
       true ->
            {error,duplicate}
    end.

%% 根据背包id,物品id查询某一物品信息
%% 参数
%% RoleId 用户id
%% BagId 背包id
%% GoodsId 物品id
%% 返回结果为：{error,Reason}或者{ok,p_goods}
get_goods_by_bag_id_goods_id(RoleId,BagId,GoodsId) ->
    GoodsList = get_goods_by_bag_id(RoleId,BagId),
    RsList = lists:foldl(
               fun(Goods,AccList) ->
                       Id = Goods#p_goods.id,
                       if GoodsId =:= Id ->
                               [Goods|AccList];
                          true ->
                               AccList
                       end
               end,[],GoodsList),
    if erlang:length(RsList) =:= 1 ->
            [H] = RsList,
            {ok,H};
       erlang:length(RsList) =:= 0 ->
            {error,not_found};
       true ->
            {error,duplicate}
    end.

%% 根据需要获取的背包id，获取当前用户拥有的背包id
%% 参数
%% RoleId 用户id
%% BagIds 背包id列表 [1,2,3,4,5,...]
%% 返回结果[bagId] 或者 []
get_role_exist_bags(RoleId,BagIds) ->
    BagIds2 = 
        case erlang:get({?ROLE_BAG_LIST_DICT_PREFIX,RoleId}) of 
            undefined ->
                [];
            BagIdList ->
                lists:foldl(
                  fun(BagId,AccList) ->
                          case lists:keyfind(BagId,1,BagIdList) of
                              {BagId,_} ->
                                  [BagId|AccList];
                              false ->
                                  AccList
                          end
                  end,[],BagIds)
        end,
    BankId2 = 
        case erlang:get({?ROLE_BANK_LIST_DICT_PREFIX,RoleId}) of 
            undefined ->
                [];
            BankIdList ->
                lists:foldl(
                  fun(BagId,AccList) ->
                          case lists:keyfind(BagId,1,BankIdList) of
                              {BagId,_} ->
                                  [BagId|AccList];
                              false ->
                                  AccList
                          end
                  end,[],BagIds)
        end,
    lists:append([BagIds2,BankId2]).

%% 人物掉落物品  ?ROLE_DROP_GOODS_LIST_DICT
%% 将掉落物品放入地图进程字典
%% 参数
%% GoodsId 物品id
%% Goods 物品信息p_goods
%% 返回{ok,p_goods}或者erlang:throw({error,Reason})
put_drop_goods(GoodsId,Goods) ->
    GoodsList = 
        case erlang:get(?ROLE_DROP_GOODS_LIST_DICT) of
            undefined ->
                [];
            GoodsListT ->
                GoodsListT
        end,
    FilterGoodsList = 
        lists:foldl(
          fun(Goods2,Acc) ->
                  if Goods2#p_goods.id =:= GoodsId ->
                          Acc;
                     true ->
                          [Goods2|Acc]
                  end
          end,[],GoodsList),
    erlang:put(?ROLE_DROP_GOODS_LIST_DICT,[Goods|FilterGoodsList]),
    {ok, Goods}.
%% 根据物品id获取物品信息
%% 参数
%% GoodsId 物品id
%% 返回 {ok,p_goods}或者erlang:throw({error,Reason})
get_drop_goods(GoodsId) ->
    GoodsList = 
        case erlang:get(?ROLE_DROP_GOODS_LIST_DICT) of
            undefined ->
                [];
            GoodsListT ->
                GoodsListT
        end,
    FindGoodsList =
        lists:foldl(
          fun(Goods,Acc) ->
                  if Goods#p_goods.id =:= GoodsId ->
                          [Goods|Acc];
                     true ->
                          Acc
                  end
          end,[],GoodsList),
    if FindGoodsList =:= [] ->
            erlang:throw({error,not_found});
       erlang:length(FindGoodsList) =:= 1 ->
            [FindGoods] = FindGoodsList,
            {ok,FindGoods};
       erlang:length(FindGoodsList) > 1 ->
            erlang:throw({error,duplicate});
       true ->
            erlang:throw({error,other_error})
    end.
%% 根据物品id 删除物品信息
%% 参数
%% GoodsId 物品id
%% 返回 {ok} 或者 erlang:throw({error,Reason})
delete_drop_goods(GoodsId) ->
    GoodsList = 
        case erlang:get(?ROLE_DROP_GOODS_LIST_DICT) of
            undefined ->
                [];
            GoodsListT ->
                GoodsListT
        end,
    RsGoodsList =
        lists:foldl(
          fun(Goods,Acc) ->
                  if Goods#p_goods.id =:= GoodsId ->
                          Acc;
                     true ->
                          [Goods|Acc]
                  end
          end,[],GoodsList),
    erlang:put(?ROLE_DROP_GOODS_LIST_DICT,RsGoodsList),
    {ok}.
%% 根据物品id，删除物品信息并返回
%% 参数
%% GoodsId 物品id
%% 返回 {ok,p_goods} 或者 erlang:throw({error,Reason})
pop_drop_goods(GoodsId) ->
    GoodsList = 
        case erlang:get(?ROLE_DROP_GOODS_LIST_DICT) of
            undefined ->
                [];
            GoodsListT ->
                GoodsListT
        end,
    {RsGoodsList,FindGoodsList} =
        lists:foldl(
          fun(Goods,Acc) ->
                  {RsAcc,FindAcc} = Acc,
                  if Goods#p_goods.id =:= GoodsId ->
                          {RsAcc,[Goods|FindAcc]};
                     true ->
                          {[Goods|RsAcc],FindAcc}
                  end
          end,{[],[]},GoodsList),
    erlang:put(?ROLE_DROP_GOODS_LIST_DICT,RsGoodsList),
    if FindGoodsList =:= [] ->
            erlang:throw({error,not_found});
       erlang:length(FindGoodsList) =:= 1 ->
            [FindGoods] = FindGoodsList,
            {ok,FindGoods};
       erlang:length(FindGoodsList) > 1 ->
            erlang:throw({error,duplicate});
       true ->
            erlang:throw({error,other_error})
    end.

%% 初始化人物掉落物品id
init_drop_goods_id() ->
    erlang:put(?ROLE_DROP_GOODS_ID_DICT,1).
%% 获取人物掉落物品id
get_drop_goods_max_id() ->
    case erlang:get(?ROLE_DROP_GOODS_ID_DICT) of
        undefined ->
            erlang:put(?ROLE_DROP_GOODS_ID_DICT,1),
            1;
        MaxId ->
            erlang:put(?ROLE_DROP_GOODS_ID_DICT,MaxId + 1),
            MaxId
    end.
