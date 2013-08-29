%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com(C) 2011, 
%%% @doc
%%% 声望模块
%%% @end
%%% Created : 19 Jul 2011 by  <caochuncheng2002@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_prestige).

-include("mgeem.hrl").
-include("prestige.hrl").

%% API
-export([
		 do_handle_info/1,
		 do_add_prestige/3
		]).

%%%===================================================================
%%% API
%%%===================================================================
%% 声望查询
do_handle_info({Unique, ?PRESTIGE, ?PRESTIGE_QUERY, DataRecord, RoleID, PId}) ->
    do_prestige_query({Unique, ?PRESTIGE, ?PRESTIGE_QUERY, DataRecord, RoleID, PId});
%% 声望兑换
do_handle_info({Unique, ?PRESTIGE, ?PRESTIGE_DEAL, DataRecord, RoleID, PId}) ->
    do_prestige_deal({Unique, ?PRESTIGE, ?PRESTIGE_DEAL, DataRecord, RoleID, PId});

do_handle_info({admin_set_role_prestige, RoleID, NewPrestige}) ->
    do_admin_set_role_prestige(RoleID,NewPrestige);

do_handle_info(Info) ->
    ?ERROR_MSG("~ts,Info=~w",["声望模块无法处理此消息",Info]),
    error.

do_add_prestige(RoleID, AddPrestige,ConsumeLogType) ->
	case common_transaction:transaction(
		   fun() ->
				   common_bag2:t_gain_prestige(AddPrestige,RoleID,ConsumeLogType)
		   end)
		of
		{atomic, {ok, NewRoleAttr}} ->
			common_misc:send_role_prestige_change(RoleID,NewRoleAttr);
		{aborted, Reason} when is_binary(Reason) ->
			{fail,Reason};
		{aborted, Reason} ->
			?ERROR_MSG("do_add_prestige, reason: ~w", [Reason]),
			{fail,Reason}                                      
	end.

%% 游戏管理设置玩家声望值
do_admin_set_role_prestige(RoleID,NewPrestige) ->
    case common_transaction:transaction(
           fun() ->
                   {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
                   RoleAttr2 = RoleAttr#p_role_attr{cur_prestige = NewPrestige},
                   mod_map_role:set_role_attr(RoleID,RoleAttr2),
                   {ok,RoleAttr2}
           end) of
        {atomic,{ok,NewRoleAttr}} ->
            catch common_misc:send_role_prestige_change(RoleID,NewRoleAttr);
        {aborted, Error} ->
            ?ERROR_MSG("do_admin_set_role_prestige error:~w",[Error])
    end.

%% 声望查询
do_prestige_query({Unique, Module, Method, DataRecord, RoleID, PId}) ->
    case catch do_prestige_query2(RoleID,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_prestige_query_error({Unique, Module, Method, DataRecord, RoleID, PId},Reason,ReasonCode);
        {ok,PPrestigeItemList} ->
            do_prestige_query3({Unique, Module, Method, DataRecord, RoleID, PId},PPrestigeItemList)
    end.
do_prestige_query2(RoleID,DataRecord) ->
    case DataRecord#m_prestige_query_tos.op_type =:= 1 of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_PRESTIGE_QUERY_PARAM_ERROR,0})
    end,
    case DataRecord#m_prestige_query_tos.group_id =/= 0 of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_PRESTIGE_QUERY_PARAM_ERROR,0})
    end,
    PrestigeExchangeConfigList = 
        case DataRecord#m_prestige_query_tos.class_id =/= 0 of
            true ->
                [PrestigeExchangeConfigA 
                 || PrestigeExchangeConfigA <- common_config_dyn:list(prestige_exchange),
                    PrestigeExchangeConfigA#r_prestige_exchange_base.group_id =:= DataRecord#m_prestige_query_tos.group_id,
                    PrestigeExchangeConfigA#r_prestige_exchange_base.class_id =:= DataRecord#m_prestige_query_tos.class_id];
            _ ->
                [PrestigeExchangeConfigB 
                 || PrestigeExchangeConfigB <- common_config_dyn:list(prestige_exchange),
                    PrestigeExchangeConfigB#r_prestige_exchange_base.group_id =:= DataRecord#m_prestige_query_tos.group_id]
        end,
    PPrestigeItemList = 
        lists:foldl(
          fun(PrestigeExchangeConfigC,AccPPrestigeItemList) ->
                  lists:append([AccPPrestigeItemList,get_p_prestige_item(RoleID,PrestigeExchangeConfigC)])
          end,[],PrestigeExchangeConfigList),
    {ok,PPrestigeItemList}.
get_p_prestige_item(RoleID,PrestigeExchangeConfig) ->
    lists:foldl(
      fun(ItemConfig,AccItemGoodsList) ->
              case get_p_prestige_item_goods(RoleID,ItemConfig) of
                  {ok,ItemGoodsList} ->
                      case erlang:length(ItemGoodsList) =:= 1 of
                          true ->
                              [#p_prestige_item{
                                  group_id = PrestigeExchangeConfig#r_prestige_exchange_base.group_id,
                                  class_id = PrestigeExchangeConfig#r_prestige_exchange_base.class_id,
                                  key = ItemConfig#r_prestige_exchange_base_item.key,
                                  min_level = ItemConfig#r_prestige_exchange_base_item.min_level,
                                  max_level = ItemConfig#r_prestige_exchange_base_item.max_level,
                                  need_prestige = ItemConfig#r_prestige_exchange_base_item.need_prestige,
                                  item = lists:nth(1,ItemGoodsList)} | AccItemGoodsList];
                          _ ->
                              AccItemGoodsList
                      end;
                  _ ->
                      AccItemGoodsList
              end
      end,[],PrestigeExchangeConfig#r_prestige_exchange_base.item_list).
get_p_prestige_item_goods(RoleID,ItemConfig) ->
    #r_prestige_exchange_base_item{item_type = ItemType,
                                   item_id = ItemId,
                                   item_number = ItemNumber,
                                   bind = ItemBind,
                                   color = ItemColor,
                                   quality = ItemQuality,
                                   sub_quality = ItemSubQuality,
                                   reinforce = ReinforceList,
                                   punch_num = PunchNum,
                                   add_attr = AddAttr} = ItemConfig,
    case mod_refining_tool:get_p_goods_by_param({ItemType,ItemId,ItemNumber,ItemBind,ItemColor,ItemQuality,ItemSubQuality,ReinforceList,PunchNum,AddAttr}) of
        {ok,GoodsList} ->
            {ok,[Goods#p_goods{roleid = RoleID,id = 99999999,bagid = 0,bagposition = 0}||Goods <-  GoodsList]};
        Error ->
            Error
    end.
do_prestige_query3({Unique, Module, Method, DataRecord, _RoleId, PId},PPrestigeItemList) ->
    SendSelf=#m_prestige_query_toc{
      op_type = DataRecord#m_prestige_query_tos.op_type,
      group_id = DataRecord#m_prestige_query_tos.group_id,
      class_id = DataRecord#m_prestige_query_tos.class_id,
      succ = true,
      item_list = PPrestigeItemList},
    ?DEBUG("~ts,SendSelf=~w",["声望模块Query",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).

do_prestige_query_error({Unique, Module, Method, DataRecord, _RoleId, PId},Reason,ReasonCode) ->
    SendSelf=#m_prestige_query_toc{
      op_type = DataRecord#m_prestige_query_tos.op_type,
      group_id = DataRecord#m_prestige_query_tos.group_id,
      class_id = DataRecord#m_prestige_query_tos.class_id,
      succ = false,
      reason = Reason,
      reason_code = ReasonCode,
      item_list = []},
    ?DEBUG("~ts,SendSelf=~w",["声望模块Query",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).
%% 声望兑换
do_prestige_deal({Unique, Module, Method, DataRecord, RoleID, PId}) ->
    case catch do_prestige_deal2(RoleID,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_prestige_deal_error({Unique, Module, Method, DataRecord, RoleID, PId},Reason,ReasonCode);
        {ok,RoleAttr,PrestigeItemConfig,GoodsList} ->
            do_prestige_deal3({Unique, Module, Method, DataRecord, RoleID, PId},RoleAttr,PrestigeItemConfig,GoodsList)
    end.
do_prestige_deal2(RoleID,DataRecord) ->
    case DataRecord#m_prestige_deal_tos.group_id =/= 0 
        andalso DataRecord#m_prestige_deal_tos.class_id =/= 0 
        andalso DataRecord#m_prestige_deal_tos.key =/= 0
        andalso DataRecord#m_prestige_deal_tos.number =/= 0 of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_PRESTIGE_DEAL_PARAM_ERROR,0})
    end,
    PrestigeExchangeConfig = 
        case common_config_dyn:find(prestige_exchange,{DataRecord#m_prestige_deal_tos.group_id,DataRecord#m_prestige_deal_tos.class_id}) of
            [PrestigeExchangeConfigT] ->
                PrestigeExchangeConfigT;
            _ ->
                erlang:throw({error,?_LANG_PRESTIGE_DEAL_PARAM_ERROR,0})
        end,
    PrestigeItemConfig = 
        case lists:keyfind(DataRecord#m_prestige_deal_tos.key,#r_prestige_exchange_base_item.key,
                           PrestigeExchangeConfig#r_prestige_exchange_base.item_list) of
            false ->
                erlang:throw({error,?_LANG_PRESTIGE_DEAL_PARAM_ERROR,0});
            PrestigeItemConfigT ->
                PrestigeItemConfigT
        end,
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    case RoleAttr#p_role_attr.cur_prestige >= (PrestigeItemConfig#r_prestige_exchange_base_item.need_prestige * DataRecord#m_prestige_deal_tos.number) of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_PRESTIGE_DEAL_NOT_ENOUGH_ERROR,0})
    end,
    GoodsList = 
        lists:foldl(
          fun(_I,AccGoodsList) ->
                  case get_p_prestige_item_goods(RoleID,PrestigeItemConfig) of
                      {ok,GoodsListT} ->
                          lists:append([AccGoodsList,[Goods#p_goods{roleid = RoleID,id = 0}|| Goods <- GoodsListT]]);
                      _ ->
                          ?ERROR_MSG("~ts,PrestigeExchangeConfig=~w",["声望兑换的配置出错，无法创建物品道具",PrestigeExchangeConfig]),
                          erlang:throw({error,?_LANG_PRESTIGE_DEAL_NOT_ENOUGH_ERROR,0})
                  end
          end,[],lists:seq(1,DataRecord#m_prestige_deal_tos.number,1)),
    {ok,RoleAttr,PrestigeItemConfig,GoodsList}.
do_prestige_deal3({Unique, Module, Method, DataRecord, RoleID, PId},RoleAttr,PrestigeItemConfig,GoodsList) ->
     case common_transaction:transaction(
           fun() ->
                   do_t_prestige_deal(RoleID,DataRecord,RoleAttr,PrestigeItemConfig,GoodsList)
           end) of
        {atomic,{ok,RoleAttr2,CreateGoodsList}} ->
            do_prestige_deal4({Unique, Module, Method, DataRecord, RoleID, PId},RoleAttr2,PrestigeItemConfig,CreateGoodsList);
        {aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                    do_prestige_deal_error({Unique, Module, Method, DataRecord, RoleID, PId},?_LANG_PRESTIGE_NOT_BAG_POS_ERROR,0);
                {Reason, ReasonCode} ->
                    do_prestige_deal_error({Unique, Module, Method, DataRecord, RoleID, PId},Reason,ReasonCode);
                _ ->
                    do_prestige_deal_error({Unique, Module, Method, DataRecord, RoleID, PId},?_LANG_PRESTIGE_DEAL_ERROR,0)
            end
    end.
do_t_prestige_deal(RoleID,DataRecord,RoleAttr,PrestigeItemConfig,GoodsList) ->
    {ok,CreateGoodsList} = mod_bag:create_goods_by_p_goods(RoleID,GoodsList),
    NeedPrestige = PrestigeItemConfig#r_prestige_exchange_base_item.need_prestige * DataRecord#m_prestige_deal_tos.number,
    RoleAttr2 = RoleAttr#p_role_attr{cur_prestige = RoleAttr#p_role_attr.cur_prestige - NeedPrestige},
    mod_map_role:set_role_attr(RoleID,RoleAttr2),
    {ok,RoleAttr2,CreateGoodsList}.
do_prestige_deal4({Unique, Module, Method, DataRecord, RoleID, PId},RoleAttr,PrestigeItemConfig,CreateGoodsList) ->
    %% 通知物品
    catch common_misc:update_goods_notify({role,RoleID},CreateGoodsList),
    %% 记录日志，返回消息
    SendSelf=#m_prestige_deal_toc{
      group_id = DataRecord#m_prestige_deal_tos.group_id,
      class_id = DataRecord#m_prestige_deal_tos.class_id,
      key = DataRecord#m_prestige_deal_tos.key,
      number = DataRecord#m_prestige_deal_tos.number,
      succ = true,
      consume_prestige = PrestigeItemConfig#r_prestige_exchange_base_item.need_prestige * DataRecord#m_prestige_deal_tos.number,
      award_list = CreateGoodsList,
      sum_prestige = RoleAttr#p_role_attr.sum_prestige,
      cur_prestige =  RoleAttr#p_role_attr.cur_prestige},
    ?DEBUG("~ts,SendSelf=~w",["声望模块Deal",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    %% 记录日志
    GoodsLogNumber = PrestigeItemConfig#r_prestige_exchange_base_item.item_number * DataRecord#m_prestige_deal_tos.number,
    [HLogGoods|_TLogGoodsList] = CreateGoodsList,
    catch common_item_logger:log(RoleID,HLogGoods,GoodsLogNumber,?LOG_ITEM_TYPE_GAIN_PRESTIGE),
    ok.
do_prestige_deal_error({Unique, Module, Method, DataRecord, _RoleId, PId},Reason,ReasonCode) ->
    SendSelf=#m_prestige_deal_toc{
      group_id = DataRecord#m_prestige_deal_tos.group_id,
      class_id = DataRecord#m_prestige_deal_tos.class_id,
      key = DataRecord#m_prestige_deal_tos.key,
      number = DataRecord#m_prestige_deal_tos.number,
      succ = false,
      reason = Reason,
      reason_code = ReasonCode},
    ?DEBUG("~ts,SendSelf=~w",["声望模块Deal",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).
