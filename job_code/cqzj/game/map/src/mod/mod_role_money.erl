%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 30 Dec 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_role_money).

%% API
-export([
         do_reduce_money/1,
         do_add_money/1,
         do_set_money/1,
         % do_change_money/1,
         t_reduce_silver_any/3
        ]).

-include("mgeem.hrl").

%% 扣钱成功
-define(MONEY_EVENT_STATE_SUCC, 2).
%% 扣钱失败
-define(MONEY_EVENT_STATE_FAIL, 3).

%%@doc 根据请求参数，发送钱币/元宝更新的通知
%%注意，目前不支持gold_any 和silver_any两种tag类型
do_send_money_change(RoleID,MoneyList,RoleAttr)->
    #p_role_attr{silver=Silver,silver_bind=SilverBind,gold=Gold,gold_bind=GoldBind} = RoleAttr,
    ChangeAttList = lists:foldl(fun(MoneyUpdate,AccIn)->
                                        %% gold_any 和silver_any 暂时不支持
                                        case erlang:element(1, MoneyUpdate) of
                                            silver_bind->
                                                [#p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE,new_value=SilverBind}|AccIn ];
                                            silver->
                                                [#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE,new_value=Silver}|AccIn ];
                                            silver_any->
                                                [#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE,new_value=Silver},
                                                 #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE,new_value=SilverBind}|AccIn];
                                            gold_bind->
                                                [#p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE,new_value=GoldBind}|AccIn ];
                                            gold->
                                                [#p_role_attr_change{change_type=?ROLE_GOLD_CHANGE,new_value=Gold}|AccIn ];
                                            gold_any->
                                                [#p_role_attr_change{change_type=?ROLE_GOLD_CHANGE,new_value=Gold},
                                                 #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE,new_value=GoldBind}|AccIn]
                                        end
                                end,[],MoneyList),
    %%?INFO_MSG("ChangeList=~w",[ChangeAttList]),
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList).

%% 扣钱
%% 成功时返回消息: {?REDUCE_ROLE_MONEY_SUCC, RoleID, RoleAttr, SuccReturn}
%% 失败时返回消息: {?REDUCE_ROLE_MONEY_FAILED, RoleID, Reason, FailedReturn}
do_reduce_money({RoleID, From, {SilverReduce, GoldReduce}, SuccReturn, FailedReturn,ShouldNotify}) ->

    case common_transaction:transaction(fun() -> t_do_reduce_money(RoleID, SilverReduce, GoldReduce) end) of
        {atomic, RoleAttr} ->
            case ShouldNotify of
                true->
                    if
                        SilverReduce == undefined andalso GoldReduce == undefined ->
                            ReduceList = [];
                        SilverReduce == undefined andalso GoldReduce =/= undefined ->
                            ReduceList = [GoldReduce];
                        SilverReduce =/= undefined andalso GoldReduce == undefined ->
                            ReduceList = [SilverReduce];
                        true -> 
                            ReduceList = [SilverReduce, GoldReduce]
                    end,
                    do_send_money_change(RoleID,ReduceList,RoleAttr);
                _->
                    ignore
            end,
            From ! {?REDUCE_ROLE_MONEY_SUCC, RoleID, RoleAttr, SuccReturn};
        {aborted, Error} ->
            case Error of
                {'EXIT', ErrorInfo} ->
                    ?ERROR_MSG("~ts:~w", ["扣除玩家财富时发生系统错误", ErrorInfo]),
                    Reason = ?_LANG_ROLE_MONEY_SYSTEM_ERROR_WHEN_REDUCE;
                {error, ErrorInfo} ->
                    ?ERROR_MSG("~ts:~w", ["扣除玩家财富时发生系统错误", ErrorInfo]),
                    Reason = ?_LANG_ROLE_MONEY_SYSTEM_ERROR_WHEN_REDUCE;
                _ ->
                    Reason = Error
            end,
            From ! {?REDUCE_ROLE_MONEY_FAILED, RoleID, Reason, FailedReturn}
    end,
    ok.

%%@doc  扣除钱币（先扣除绑定、再扣除不绑定）
%%      事务内方法
t_reduce_silver_any(RoleAttr,ReduceSilver,ConsumeType)->
    #p_role_attr{role_id=RoleID,silver=Silver, silver_bind=SilverBind} = RoleAttr,
    case SilverBind >= ReduceSilver of
        true ->
            common_consume_logger:use_silver({RoleID, ReduceSilver, 0, ConsumeType, ""}),
            RoleAttr#p_role_attr{silver_bind=SilverBind - ReduceSilver};
        false ->
            case (Silver+SilverBind)-ReduceSilver >= 0 of
                true ->
                    common_consume_logger:use_silver({RoleID, SilverBind,(ReduceSilver-SilverBind), ConsumeType, ""}),
                    RoleAttr#p_role_attr{silver=(Silver+SilverBind)-ReduceSilver, silver_bind=0};
                false ->
                    common_transaction:abort(?_LANG_ROLE_MONEY_NOT_ENOUGH_SILVER_ANY)
            end
    end.

t_do_reduce_money(RoleID, SilverReduce, GoldReduce) ->
    case mod_map_role:get_role_attr(RoleID) of 
        {ok, RoleAttr} ->
            NewRoleAttr1 = case SilverReduce of
                undefined -> RoleAttr;
                {MoneyType, Reduce, ConsumeType, ConsumeDetail} ->
                    case common_bag2:t_deduct_money(MoneyType, Reduce, RoleID, {ConsumeType, ConsumeDetail}) of
                        {ok, RoleAttr2} ->
                            RoleAttr2;
                        {error, Reason2} ->
                            common_transaction:abort(Reason2)
                    end
            end,
            NewRoleAttr2 = case GoldReduce of
                undefined ->
                    NewRoleAttr1;
                {MoneyType2, Reduce2, ConsumeType2, ConsumeDetail2} ->
                    case common_bag2:t_deduct_money(MoneyType2, Reduce2, NewRoleAttr1, {ConsumeType2, ConsumeDetail2},0,0) of
                        {ok, RoleAttr3} -> RoleAttr3;
                        {error, Reason} -> 
                            common_transaction:abort(Reason)
                    end
            end,
            NewRoleAttr2;
        _ ->
            common_transaction:abort(?_LANG_ROLE_MONEY_NOT_ONLINE)
    end.

                                         


%% 加钱 
%% 成功时返回消息: {?ADD_ROLE_MONEY_SUCC, RoleID, RoleAttr, SuccReturn}
%% 失败时返回消息: {?ADD_ROLE_MONEY_FAILED, RoleID, Reason, FailedReturn}
do_add_money({RoleID, From, AddMoneyList, SuccReturn, FailedReturn,ShouldNotify}) ->
    case common_transaction:transaction(fun() -> t_do_add_money(RoleID, AddMoneyList) end) of
        {atomic, RoleAttr} ->
            case ShouldNotify of
                true->
                    do_send_money_change(RoleID,AddMoneyList,RoleAttr);
                _->
                    ignore
            end,
            
            From ! {?ADD_ROLE_MONEY_SUCC, RoleID, RoleAttr, SuccReturn};
        {aborted, Error} ->
            case Error of
                {'EXIT', ErrorInfo} ->
                    ?ERROR_MSG("~ts:~w", ["增加玩家财富时发生系统错误", ErrorInfo]),
                    Reason = ?_LANG_ROLE_MONEY_SYSTEM_ERROR_WHEN_ADD;
                {error, ErrorInfo} ->
                    ?ERROR_MSG("~ts:~w", ["增加玩家财富时发生系统错误", ErrorInfo]),
                    Reason = ?_LANG_ROLE_MONEY_SYSTEM_ERROR_WHEN_ADD;
                _ ->
                    Reason = Error
            end,
            From ! {?ADD_ROLE_MONEY_FAILED, RoleID, Reason, FailedReturn}
    end,
    ok.

t_do_add_money(RoleID, AddList) ->
    case mod_map_role:get_role_attr(RoleID) of        
        {ok, RoleAttr} ->
            RoleAttr2 = lists:foldl(
                          fun(Add, Attr) ->
                                  case Add of
                                      {gold_bind, AddGold, ConsumeType, ConsumeDetail} ->
                                          common_consume_logger:gain_gold({RoleID, AddGold, 0, ConsumeType, ConsumeDetail}),
                                          #p_role_attr{gold_bind=GoldBind} = Attr,
                                          Attr#p_role_attr{gold_bind=GoldBind + AddGold};
                                      {gold, AddGold, ConsumeType, ConsumeDetail} ->
                                          common_consume_logger:gain_gold({RoleID, 0, AddGold, ConsumeType, ConsumeDetail}),
                                          #p_role_attr{gold=Gold} = Attr,
                                          Attr#p_role_attr{gold=Gold + AddGold};
                                      {silver_bind, AddSilver, ConsumeType, ConsumeDetail} ->
                                          common_consume_logger:gain_silver({RoleID, AddSilver, 0, ConsumeType, ConsumeDetail}),
                                          #p_role_attr{silver_bind=SilverBind} = Attr,
                                          Attr#p_role_attr{silver_bind=SilverBind + AddSilver};
                                      {silver, AddSilver, ConsumeType, ConsumeDetail} ->
                                          common_consume_logger:gain_silver({RoleID, 0, AddSilver, ConsumeType, ConsumeDetail}),
                                          #p_role_attr{silver=Silver} = Attr,
                                          Attr#p_role_attr{silver=Silver + AddSilver}
                                  end
                          end, RoleAttr, AddList),
            mod_map_role:set_role_attr(RoleID, RoleAttr2),            
            RoleAttr2;
        {error, _} ->
            common_transaction:abort(?_LANG_ROLE_MONEY_NOT_ONLINE)
    end.

%%@doc GM指令专用
do_set_money({RoleID, SetList}) ->
    case common_transaction:transaction(fun() -> t_do_set_money(RoleID, SetList) end) of
        {atomic, RoleAttr} ->
            #p_role_attr{gold=NewGold, gold_bind=NewGoldBind, silver=S, silver_bind=SB} = RoleAttr,
            Record = #m_role2_attr_change_toc{
              roleid  = RoleID,
              changes = [
                         #p_role_attr_change{change_type=?ROLE_GOLD_CHANGE,new_value=NewGold},
                         #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE,new_value=S},
                         #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE,new_value=SB},
                         #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE,new_value=NewGoldBind}
                        ]
             },
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, Record),
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("~ts:~p", ["设置玩家财富出错", Error])
    end.

%% GM指令专用
t_do_set_money(RoleID, AddList) ->
    case mod_map_role:get_role_attr(RoleID) of        
        {ok, RoleAttr} ->
            RoleAttr2 = lists:foldl(
                          fun(Add, Attr) ->
                                  case Add of
                                      {gold_bind, AddGold} ->
                                          Attr#p_role_attr{gold_bind=AddGold};
                                      {gold, AddGold} ->
                                          Attr#p_role_attr{gold=AddGold};
                                      {silver_bind, AddSilver} ->
                                          Attr#p_role_attr{silver_bind=AddSilver};
                                      {silver, AddSilver} ->
                                          Attr#p_role_attr{silver=AddSilver}
                                  end
                          end, RoleAttr, AddList),
            
            lists:foreach(fun(Add)->
                                  case Add of
                                      {gold_bind, AddGold} ->
                                          common_consume_logger:gain_gold({RoleID, AddGold, 0, ?GAIN_TYPE_GOLD_GIVE_FROM_GM_CODE, ""});
                                      {gold, AddGold} ->
                                          common_consume_logger:gain_gold({RoleID, 0, AddGold, ?GAIN_TYPE_GOLD_GIVE_FROM_GM_CODE, ""});
                                      {silver_bind, AddSilver} ->
                                          common_consume_logger:gain_silver({RoleID, AddSilver, 0, ?GAIN_TYPE_SILVER_GIVE_FROM_GM_CODE, ""});
                                      {silver, AddSilver} ->
                                          common_consume_logger:gain_silver({RoleID, 0, AddSilver, ?GAIN_TYPE_SILVER_GIVE_FROM_GM_CODE, ""})
                                  end
                          end, AddList),
            mod_map_role:set_role_attr(RoleID, RoleAttr2),            
            RoleAttr2;
        {error, _} ->
            common_transaction:abort(?_LANG_ROLE_MONEY_NOT_ONLINE)
    end.

% do_change_money({RoleID, From, EventID, ChangeList, SuccReturn, FailedReturn}) ->
%     case common_transaction:transaction(fun() -> t_do_change_money(RoleID, ChangeList) end) of
%         {atomic, RoleAttr} ->
%             common_role_money:update_event_state(EventID, ?MONEY_EVENT_STATE_SUCC),
%             From ! {?CHANGE_ROLE_MONEY_SUCC, RoleID, EventID, RoleAttr, SuccReturn};
%         {aborted, Error} ->
%             case Error of
%                 {'EXIT', ErrorInfo} ->
%                     ?ERROR_MSG("~ts:~w", ["扣除玩家财富时发生系统错误", ErrorInfo]),
%                     Reason = ?_LANG_ROLE_MONEY_SYSTEM_ERROR_WHEN_REDUCE;
%                 {error, ErrorInfo} ->
%                     ?ERROR_MSG("~ts:~w", ["扣除玩家财富时发生系统错误", ErrorInfo]),
%                     Reason = ?_LANG_ROLE_MONEY_SYSTEM_ERROR_WHEN_REDUCE;
%                 _ ->
%                     Reason = Error
%             end,
%             common_role_money:update_event_state(EventID, ?MONEY_EVENT_STATE_FAIL),
%             From ! {?CHANGE_ROLE_MONEY_FAILED, RoleID, EventID, Reason, FailedReturn}
%     end,
%     ok.

% t_do_change_money(RoleID, ChangeList) ->
%     case mod_map_role:get_role_attr(RoleID) of        
%         {ok, RoleAttr} ->
%             RoleAttr2 = lists:foldl(
%                           fun(Reduce, Attr) ->
%                                   case Reduce of
%                                       {reduce_gold, ReduceGold, ConsumeType, ConsumeDetail} ->
%                                           #p_role_attr{gold=Gold} = Attr,
%                                           case Gold >= ReduceGold of
%                                               true ->
%                                                   common_consume_logger:use_gold({RoleID, 0, ReduceGold, ConsumeType, ConsumeDetail}),
%                                                   Attr#p_role_attr{gold=Gold - ReduceGold};
%                                               false ->
%                                                   common_transaction:abort(?_LANG_ROLE_MONEY_NOT_ENOUGH_GOLD)
%                                           end;
%                                       {reduce_silver, ReduceSilver, ConsumeType, ConsumeDetail} ->
%                                           #p_role_attr{silver=Silver} = Attr,
%                                           case Silver >= ReduceSilver of
%                                               true ->
%                                                   common_consume_logger:use_silver({RoleID, 0, ReduceSilver, ConsumeType, ConsumeDetail}),
%                                                   Attr#p_role_attr{silver=Silver - ReduceSilver};
%                                               false ->
%                                                   common_transaction:abort(?_LANG_ROLE_MONEY_NOT_ENOUGH_SILVER)
%                                           end;
%                                       {add_gold, AddGold, ConsumeType, ConsumeDetail} ->
%                                           common_consume_logger:gain_gold({RoleID, 0, AddGold, ConsumeType, ConsumeDetail}),
%                                           #p_role_attr{gold=Gold} = Attr,
%                                           Attr#p_role_attr{gold=Gold + AddGold};
%                                       {add_silver, AddSilver, ConsumeType, ConsumeDetail} ->
%                                           common_consume_logger:gain_silver({RoleID, 0, AddSilver, ConsumeType, ConsumeDetail}),
%                                           #p_role_attr{silver=Silver} = Attr,
%                                           Attr#p_role_attr{silver=Silver + AddSilver}
%                                   end
%                           end, RoleAttr, ChangeList),
%             mod_map_role:set_role_attr(RoleID, RoleAttr2),
%             RoleAttr2;
%         {error, _} ->
%             common_transaction:abort(?_LANG_ROLE_MONEY_NOT_ONLINE)
%     end.

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-compile(export_all).

basic_test_() ->
     {setup, 
      fun basic_test_setup/0,
      fun basic_test_stop/1,
      {with, [
              fun reduce_gold_any_not_enough/1,
              fun reduce_silver_any_not_enough/1,
              fun reduce_gold_enough/1,
              fun reduce_sivler_enough/1,
              fun reduce_gold_bind_enough/1,
              fun reduce_sivler_bind_enough/1,
              fun reduce_gold_any_enough/1,
              fun reduce_silver_any_enough/1,

              fun add_gold_enough/1,
              fun add_sivler_enough/1,
              fun add_gold_bind_enough/1,
              fun add_sivler_bind_enough/1,

              fun reduce_silver_both/1
             ]}}.

basic_test_setup() ->
    %% 初始化角色信息
    RoleID = 1001, 
    RoleAttr = #p_role_attr{role_id=RoleID, gold=1000, gold_bind=1000, silver=1000, silver_bind=1000},
    {RoleID, RoleAttr}.

basic_test_stop({_RoleID, _RoleAttr}) ->
    ok.

%% 任意元宝足够消耗测试
reduce_gold_any_enough({RoleID, RoleAttr}) ->
    erlang:put({role_attr, RoleID}, RoleAttr),
    do_reduce_money({RoleID, erlang:self(), [{gold_any, 500}], succ, failed, ignore, ignore}),
    receive
        {?REDUCE_ROLE_MONEY_SUCC, RoleID, RoleAttr2, succ} ->
            ?assertEqual(RoleAttr2, erlang:get({role_attr, RoleID})),
            ?assertEqual(RoleAttr2#p_role_attr.gold_bind, 500)
    after 1000 ->
            erlang:throw({error, reduce_role_money_failed, no_return_msg})
    end. 

reduce_silver_both({RoleID, RoleAttr}) ->
    erlang:put({role_attr, RoleID}, RoleAttr),
    do_reduce_money({RoleID, erlang:self(), [{silver, 500}, {silver_bind, 400}], succ, failed, ignore, ignore}),
    receive
        {?REDUCE_ROLE_MONEY_SUCC, RoleID, RoleAttr2, succ} ->
            ?assertEqual(RoleAttr2#p_role_attr.silver_bind, 600),
            ?assertEqual(RoleAttr2#p_role_attr.silver, 500),
            ?assertEqual(RoleAttr2, erlang:get({role_attr, RoleID}))
    after 1000 ->
            erlang:throw({error, reduce_role_money_failed, no_return_msg})
    end.

%% 任何元宝消耗测试
reduce_gold_enough({RoleID, RoleAttr}) ->
    erlang:put({role_attr, RoleID}, RoleAttr),
    do_reduce_money({RoleID, erlang:self(), [{gold, 500}], succ, failed, ignore, ignore}),
    receive
        {?REDUCE_ROLE_MONEY_SUCC, RoleID, RoleAttr2, succ} ->
            ?assertEqual(RoleAttr2, erlang:get({role_attr, RoleID})),
            ?assertEqual(RoleAttr2#p_role_attr.gold, 500)
    after 1000 ->
            erlang:throw({error, reduce_role_money_failed, no_return_msg})
    end. 

reduce_gold_bind_enough({RoleID, RoleAttr}) ->
    erlang:put({role_attr, RoleID}, RoleAttr),
    do_reduce_money({RoleID, erlang:self(), [{gold_bind, 500}], succ, failed, ignore, ignore}),
    receive
        {?REDUCE_ROLE_MONEY_SUCC, RoleID, RoleAttr2, succ} ->
            ?assertEqual(RoleAttr2, erlang:get({role_attr, RoleID})),
            ?assertEqual(RoleAttr2#p_role_attr.gold_bind, 500)
    after 1000 ->
            erlang:throw({error, reduce_role_money_failed, no_return_msg})
    end. 

reduce_sivler_enough({RoleID, RoleAttr}) ->
    erlang:put({role_attr, RoleID}, RoleAttr),
    do_reduce_money({RoleID, erlang:self(), [{silver, 500}], succ, failed, ignore, ignore}),
    receive
        {?REDUCE_ROLE_MONEY_SUCC, RoleID, RoleAttr2, succ} ->
            ?assertEqual(RoleAttr2, erlang:get({role_attr, RoleID})),
            ?assertEqual(RoleAttr2#p_role_attr.silver, 500)
    after 1000 ->
            erlang:throw({error, reduce_role_money_failed, no_return_msg})
    end. 

reduce_silver_any_enough({RoleID, RoleAttr}) ->
    erlang:put({role_attr, RoleID}, RoleAttr),
    do_reduce_money({RoleID, erlang:self(), [{silver_any, 500}], succ, failed, ignore, ignore}),
    receive
        {?REDUCE_ROLE_MONEY_SUCC, RoleID, RoleAttr2, succ} ->
            ?assertEqual(RoleAttr2, erlang:get({role_attr, RoleID})),
            ?assertEqual(RoleAttr2#p_role_attr.silver_bind, 500)
    after 1000 ->
            erlang:throw({error, reduce_role_money_failed, no_return_msg})
    end. 

reduce_sivler_bind_enough({RoleID, RoleAttr}) ->
    erlang:put({role_attr, RoleID}, RoleAttr),
    do_reduce_money({RoleID, erlang:self(), [{silver_bind, 500}], succ, failed, ignore, ignore}),
    receive
        {?REDUCE_ROLE_MONEY_SUCC, RoleID, RoleAttr2, succ} ->
            ?assertEqual(RoleAttr2, erlang:get({role_attr, RoleID})),
            ?assertEqual(RoleAttr2#p_role_attr.silver_bind, 500)
    after 1000 ->
            erlang:throw({error, reduce_role_money_failed, no_return_msg})
    end.
            

reduce_gold_any_not_enough({RoleID, RoleAttr}) ->
    %% 测试扣任意元宝不够的情况
    erlang:put({role_attr, RoleID}, RoleAttr),
    do_reduce_money({RoleID, erlang:self(), [{gold_any, 1200}], succ, failed, ignore, ignore}),
    receive 
        {?REDUCE_ROLE_MONEY_FAILED, RoleID, Reason, failed} ->            
            ?assertEqual(RoleAttr, erlang:get({role_attr, RoleID})),
            ?assertEqual(Reason, ?_LANG_ROLE_MONEY_NOT_ENOUGH_GOLD_ANY)
    after 1000 ->
            erlang:throw({error, reduce_role_money_failed, no_return_msg})
    end.


reduce_silver_any_not_enough({RoleID, RoleAttr}) ->
    erlang:put({role_attr, RoleID}, RoleAttr),
    %% 测试扣任何钱币不足的情况
    do_reduce_money({RoleID, erlang:self(), [{silver_any, 1200}], succ, failed, ignore, ignore}),
    receive 
        {?REDUCE_ROLE_MONEY_FAILED, RoleID, Reason2, failed} ->
            ?assertEqual(RoleAttr, erlang:get({role_attr, RoleID})),
            ?assertEqual(Reason2, ?_LANG_ROLE_MONEY_NOT_ENOUGH_SILVER_ANY)
    after 1000 ->
            erlang:throw({error, reduce_role_money_failed, no_return_msg})
    end.

%%---------------------------------------------------------------------------------------

%% 元宝增加测试
add_gold_enough({RoleID, RoleAttr}) ->
    erlang:put({role_attr, RoleID}, RoleAttr),
    do_add_money({RoleID, erlang:self(), [{gold, 500}], succ, failed, ignore, ignore}),
    receive
        {?ADD_ROLE_MONEY_SUCC, RoleID, RoleAttr2, succ} ->
            ?assertEqual(RoleAttr2, erlang:get({role_attr, RoleID})),
            ?assertEqual(RoleAttr2#p_role_attr.gold, 1500)
    after 1000 ->
            erlang:throw({error, add_role_money_failed, no_return_msg})
    end. 

add_gold_bind_enough({RoleID, RoleAttr}) ->
    erlang:put({role_attr, RoleID}, RoleAttr),
    do_add_money({RoleID, erlang:self(), [{gold_bind, 500}], succ, failed, ignore, ignore}),
    receive
        {?ADD_ROLE_MONEY_SUCC, RoleID, RoleAttr2, succ} ->
            ?assertEqual(RoleAttr2, erlang:get({role_attr, RoleID})),
            ?assertEqual(RoleAttr2#p_role_attr.gold_bind, 1500)
    after 1000 ->
            erlang:throw({error, add_role_money_failed, no_return_msg})
    end. 

add_sivler_enough({RoleID, RoleAttr}) ->
    erlang:put({role_attr, RoleID}, RoleAttr),
    do_add_money({RoleID, erlang:self(), [{silver, 500}], succ, failed, ignore, ignore}),
    receive
        {?ADD_ROLE_MONEY_SUCC, RoleID, RoleAttr2, succ} ->
            ?assertEqual(RoleAttr2, erlang:get({role_attr, RoleID})),
            ?assertEqual(RoleAttr2#p_role_attr.silver, 1500)
    after 1000 ->
            erlang:throw({error, add_role_money_failed, no_return_msg})
    end. 

add_sivler_bind_enough({RoleID, RoleAttr}) ->
    erlang:put({role_attr, RoleID}, RoleAttr),
    do_add_money({RoleID, erlang:self(), [{silver_bind, 500}], succ, failed, ignore, ignore}),
    receive
        {?ADD_ROLE_MONEY_SUCC, RoleID, RoleAttr2, succ} ->
            ?assertEqual(RoleAttr2, erlang:get({role_attr, RoleID})),
            ?assertEqual(RoleAttr2#p_role_attr.silver_bind, 1500)
    after 1000 ->
            erlang:throw({error, add_role_money_failed, no_return_msg})
    end.
            
-endif.

