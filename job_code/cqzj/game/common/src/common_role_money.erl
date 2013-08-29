%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 21 Dec 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_role_money).

-include("common.hrl").
-include("common_server.hrl").

%% API
-export([
         reduce/4,
         reduce/5,
         add/4,
         add/5,
         % change/5,
         set/2
        ]).

-export([record_event/4, erase_event/1, update_event_state/2]).

%% 扣钱成功
-define(MONEY_EVENT_STATE_SUCC, 2).
%% 扣钱失败
-define(MONEY_EVENT_STATE_FAIL, 3).

%% @doc 扣除操作
%% ReduceTuple: {SilverReduce, GoldReduce}, SilverReduce和GoldReduce为: {reduce_type, Num, ConsumeType, ConsumeDetail} | undefined
%% reduce_type: glod_any, gold_bind, silver_any, silver_bind. any：先扣绑定再扣不不绑定
%% return: {?REDUCE_ROLE_MONEY_SUCC, RoleID, RoleAttr, SuccReturn} or {?REDUCE_ROLE_MONEY_FAILED, RoleID, Reason, FailedReturn}
reduce(RoleID, ReduceTuple, SuccReturn, FailedReturn)->
    reduce(RoleID, ReduceTuple, SuccReturn, FailedReturn,false).
reduce(RoleID, ReduceTuple, SuccReturn, FailedReturn,ShouldNotify) when is_boolean(ShouldNotify) ->
    mgeer_role:absend(RoleID, {mod_map_role, 
    	{reduce_money, {RoleID, erlang:self(), ReduceTuple, SuccReturn, FailedReturn,ShouldNotify}
	}}).

%% @doc 增加操作
%% addlist: [{add_type, Num, ConsumeType, ConsumeDetail}...]
%% add_type: gold_bind, gold, silver_bind, silver
%% return: {?ADD_ROLE_MONEY_SUCC, RoleID, RoleAttr, SuccReturn} or {?ADD_ROLE_MONEY_FAILED, RoleID, Reason, FailedReturn}
add(RoleID, AddList, SuccReturn, FailedReturn) ->
    add(RoleID, AddList, SuccReturn, FailedReturn,false).
add(RoleID, AddList, SuccReturn, FailedReturn,ShouldNotify) when is_boolean(ShouldNotify) ->
    mgeer_role:absend(RoleID, {mod_map_role, 
   		{add_money, {RoleID, erlang:self(), AddList, SuccReturn, FailedReturn,ShouldNotify}
	}}).

%% @doc 金钱变动，暂时只供钱庄使用，角色在线的话发到地图，不在线则直接修改数据库
%% changelist: [{change_type, Num, ConsumeType, ConsumeDetail}...]
%% change_type: add_gold, add_silver, reduce_gold, reduce_silver，暂时只支持这4种类型
%% return: {?CHANGE_ROLE_MONEY_SUCC, RoleID, RoleAttr, SuccReturn} or {?CHANGE_ROLE_MONEY_FAILED, RoleID, Reason, FailedReturn}
% change(RoleID, EventInfo, ChangeList, SuccReturn, FailedReturn) ->
%     {ok, EventID} = get_event_id(),
%     case common_misc:is_role_online(RoleID) of
%         true ->
%             mgeer_role:absend(RoleID, {mod_map_role, 
% 				{change_money, {RoleID, erlang:self(), EventID, ChangeList, SuccReturn, FailedReturn}}
% 			});
%         false ->
%             change2(RoleID, ChangeList, EventID, SuccReturn, FailedReturn)
%     end,
%     %% 纪录此次操作
%     record_event(EventID, RoleID, EventInfo, ChangeList).

% change2(RoleID, ChangeList, EventID, SuccReturn, FailedReturn) ->
%     case db:transaction(
%            fun() ->
%                    t_do_change(RoleID, ChangeList)
%            end)
%     of
%         {atomic, RoleAttr} ->
%             common_role_money:update_event_state(EventID, ?MONEY_EVENT_STATE_SUCC),
%             erlang:self() ! {?CHANGE_ROLE_MONEY_SUCC, RoleID, EventID, RoleAttr, SuccReturn},
%             ok;
%         {aborted, Error} ->
%             ?ERROR_MSG("change, error: ~w", [Error]),
%             common_role_money:update_event_state(EventID, ?MONEY_EVENT_STATE_FAIL),
%             erlang:self() ! {?CHANGE_ROLE_MONEY_FAILED, RoleID, EventID, ?_LANG_SYSTEM_ERROR, FailedReturn}
%     end.

% t_do_change(RoleID, ChangeList) ->
%     [RoleAttr] = db:read(?DB_ROLE_ATTR, RoleID, read),
%     RoleAttr2 = lists:foldl(
%                   fun(Reduce, Attr) ->
%                           case Reduce of
%                               {reduce_gold, ReduceGold, ConsumeType, ConsumeDetail} ->
%                                   #p_role_attr{gold=Gold} = Attr,
%                                   case Gold >= ReduceGold of
%                                       true ->
%                                           common_consume_logger:use_gold({RoleID, 0, ReduceGold, ConsumeType, ConsumeDetail}),
%                                           Attr#p_role_attr{gold=Gold - ReduceGold};
%                                       false ->
%                                           common_transaction:abort(?_LANG_ROLE_MONEY_NOT_ENOUGH_GOLD)
%                                   end;
%                               {reduce_silver, ReduceSilver, ConsumeType, ConsumeDetail} ->
%                                   #p_role_attr{silver=Silver} = Attr,
%                                   case Silver >= ReduceSilver of
%                                       true ->
%                                           common_consume_logger:use_silver({RoleID, 0, ReduceSilver, ConsumeType, ConsumeDetail}),
%                                           Attr#p_role_attr{silver=Silver - ReduceSilver};
%                                       false ->
%                                           common_transaction:abort(?_LANG_ROLE_MONEY_NOT_ENOUGH_SILVER)
%                                   end;
%                               {add_gold, AddGold, ConsumeType, ConsumeDetail} ->
%                                   common_consume_logger:gain_gold({RoleID, 0, AddGold, ConsumeType, ConsumeDetail}),
%                                   #p_role_attr{gold=Gold} = Attr,
%                                   Attr#p_role_attr{gold=Gold + AddGold};
%                               {add_silver, AddSilver, ConsumeType, ConsumeDetail} ->
%                                   common_consume_logger:gain_silver({RoleID, 0, AddSilver, ConsumeType, ConsumeDetail}),
%                                   #p_role_attr{silver=Silver} = Attr,
%                                   Attr#p_role_attr{silver=Silver + AddSilver}
%                           end
%                   end, RoleAttr, ChangeList),
%     db:write(?DB_ROLE_ATTR, RoleAttr2, write),
%     RoleAttr2.

set(RoleID, AddList) ->
    mgeer_role:absend(RoleID, {mod_map_role, {set_money, {RoleID, AddList}}}).


%%%===================================================================
%%% Internal functions
%%%===================================================================
% get_event_id() ->
%     case db:transaction(
%            fun() ->
%                    [#r_money_event_counter{event_id=EventID}=Counter] = db:dirty_read(?DB_MONEY_EVENT_COUNTER, 1),
%                    db:dirty_write(?DB_MONEY_EVENT_COUNTER, Counter#r_money_event_counter{event_id=EventID+1}),
%                    EventID
%            end)
%     of
%         {atomic, EventID} ->
%             {ok, EventID};
%         {aborted, Error} ->
%             ?ERROR_MSG("get_event_id, error: ~w", [Error]),
%             {error, ?_LANG_SYSTEM_ERROR}
%     end.

record_event(EventID, RoleID, EventInfo, MoneyChange) ->
    global:send(mgeew_money_event_server, {record_event, EventID, RoleID, EventInfo, MoneyChange}),
    ok.

erase_event(EventID) ->
    global:send(mgeew_money_event_server, {erase_event, EventID}),
    ok.

update_event_state(EventID, NewState) ->
    global:send(mgeew_money_event_server, {update_event_state, EventID, NewState}),
    ok.
