%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 28 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeew_pay_server).

-behaviour(gen_server).

-include("mgeew.hrl").

%% API
-export([start/0, start_link/0]).
-export([check_is_first_pay/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-define(ADD_GOLD_BY_PAY,pay_add_gold).
-define(ADD_GOLD_BY_PLATFORM_POINT,add_gold_by_platform_point).

-define(PROCESS_FAILED_QUEUE_INTERVAL, 30000).

%% n秒没到账自动补发
-define(PAY_FAILED_RETURN_SECONDS, 10).
%% n秒循环检查一次
-define(LOOP_PAY_FAILED_INTERVAL, 2000).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE, {?MODULE, start_link, []},
                                                 permanent, 30000, worker, [?MODULE]}).

%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({global, ?SERVER}, ?MODULE, [], []).

%%%===================================================================

%%--------------------------------------------------------------------
init([]) ->
    erlang:process_flag(trap_exit, true),
    init_pay_index_table(),
    ok = common_config_dyn:init(activity_pay_first),
    erlang:send_after(?PROCESS_FAILED_QUEUE_INTERVAL, erlang:self(), process_failed_queue),
    erlang:send_after(?LOOP_PAY_FAILED_INTERVAL, erlang:self(), loop),
    {ok, #state{}}.

%%--------------------------------------------------------------------
handle_call(Request, _From, State) ->
    Reply = do_handle_call(Request),
    {reply, Reply, State}.

%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

%%--------------------------------------------------------------------
terminate(Reason, _State) ->
    ?ERROR_MSG("~ts:~w", ["充值服务down掉", Reason]),
    ok.

%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================

do_handle_info({?ADD_ROLE_MONEY_SUCC, RoleID, RoleAttr, {?ADD_GOLD_BY_PAY,OrderID,PayGold,PayReturnGold,{Year, Month, Day, Hour},IsFirst}})->
    #p_role_attr{gold=CurrentGold,role_name=RoleName}=RoleAttr,
    ?ERROR_MSG("充值的元宝成功增加到玩家背包中,RoleID=~w,CurrentGold=~w",[RoleID,CurrentGold]),
    do_insert_pay_gold_log(true,OrderID,RoleID,PayGold,""),
    do_remove_failed_queue(OrderID),
	%% 充值成功才发送信件
	send_succ_letter(RoleID,RoleName,PayGold,PayReturnGold,{Year, Month, Day, Hour},IsFirst),
	delete_pay_order_dict(RoleID, OrderID),
    ok;
do_handle_info({?ADD_ROLE_MONEY_FAILED, RoleID, Reason, {?ADD_GOLD_BY_PAY,OrderID,PayGold}})->
    ?ERROR_MSG("充值的元宝增加失败！,RoleID=~w,Reason=~w",[RoleID,Reason]),
    do_insert_into_failed_queue(RoleID, OrderID, PayGold),
    do_insert_pay_gold_log(false,OrderID,RoleID,PayGold,Reason),
	delete_pay_order_dict(RoleID, OrderID),
    ok;

do_handle_info({?ADD_ROLE_MONEY_SUCC, RoleID, RoleAttr, {?ADD_GOLD_BY_PLATFORM_POINT,OrderID,BindGold}})->
    #p_role_attr{gold=CurrentGold,role_name=RoleName}=RoleAttr,
    ?ERROR_MSG("赠送的礼券成功增加到玩家背包中,RoleID=~w,CurrentGold=~w",[RoleID,CurrentGold]),
    %% 充值成功才发送信件
    mod_platform_point:send_succ_letter(RoleID, RoleName, BindGold),
    delete_pay_order_dict(RoleID, OrderID),
    ok;
do_handle_info({?ADD_ROLE_MONEY_FAILED, RoleID, Reason, {?ADD_GOLD_BY_PLATFORM_POINT,OrderID,BindGold}})->
    ?ERROR_MSG("赠送的礼券增加失败！,RoleID=~w,BindGold=~w,Reason=~w",[RoleID,BindGold,Reason]),
    delete_pay_order_dict(RoleID, OrderID),
    ok;

do_handle_info(process_failed_queue) ->
    erlang:send_after(?PROCESS_FAILED_QUEUE_INTERVAL, erlang:self(), process_failed_queue),
    do_process_failed_queue();

do_handle_info(loop) ->
    erlang:send_after(?LOOP_PAY_FAILED_INTERVAL, erlang:self(), loop),
    loop();

do_handle_info(pay_order_list) ->
    ?ERROR_MSG("pay_order_list:~p",[erlang:get(pay_order_list)]);

do_handle_info(clear_pay_order_list) ->
    ?ERROR_MSG("pay_order_list:~p",[erlang:get(pay_order_list)]),
	erlang:erase(pay_order_list),
	?ERROR_MSG("clear_pay_order_list success",[]);

do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.

-define(IS_MONEY(M),(erlang:is_integer(M) orelse erlang:is_float(M))).

%%普通充值接口
do_handle_call({pay,OrderID , AcName, PayTime, PayGold, PayMoney, {Year, Month, Day, Hour}})
  when OrderID =/= undefined andalso AcName =/= undefined  andalso erlang:is_integer(PayTime) andalso erlang:is_integer(PayGold)
        andalso ?IS_MONEY(PayMoney) andalso erlang:is_integer(Year) andalso erlang:is_integer(Month)
       andalso erlang:is_integer(Month) andalso erlang:is_integer(Day) andalso erlang:is_integer(Hour) ->    
    do_pay(OrderID, AcName, PayTime, PayGold, PayMoney, {Year, Month, Day, Hour});

%%平台点数赠送礼券，主要是台湾运营商的需求
do_handle_call({give_bind_gold, GiveID, AcName, GiveTime, BindGold, ActivePoint, {Year, Month, Day, Hour}})
  when GiveID =/= undefined andalso AcName =/= undefined  andalso erlang:is_integer(GiveTime) andalso erlang:is_integer(BindGold)
        andalso ?IS_MONEY(ActivePoint) andalso erlang:is_integer(Year) andalso erlang:is_integer(Month)
       andalso erlang:is_integer(Month) andalso erlang:is_integer(Day) andalso erlang:is_integer(Hour) ->    
    mod_platform_point:give_bind_gold(GiveID, AcName, GiveTime, BindGold, ActivePoint, {Year, Month, Day, Hour});
do_handle_call(Request) -> 
    ?ERROR_MSG("~ts:~w", ["未知的CALL", Request]).


do_pay(OrderID, AccountName, PayTime, PayGold, PayMoney, {Year, Month, Day, Hour}) ->
    ?ERROR_MSG("收到充值请求,OrderID=~p,AccountName=~ts,Params=~w", [OrderID, AccountName, {PayTime, PayGold, PayMoney, {Year, Month, Day, Hour}}]),
    
    BinAccountName = common_tool:to_binary(AccountName),
    IsFirst = check_is_first_pay(BinAccountName),
    case db:transaction(fun() -> 
                                t_do_pay(OrderID, BinAccountName, PayTime, PayGold, PayMoney, 
                                         {Year, Month, Day, Hour},IsFirst) end) of
        {atomic, {RoleID, _NewGold, _PayReturnGold, RoleName}} ->
            %% 发送到behavior
            {ok, #p_role_attr{level=Level} } = common_misc:get_dirty_role_attr(RoleID),
            PayDateTime = calendar:datetime_to_gregorian_seconds({{Year, Month, Day},{0,0,0}})-calendar:datetime_to_gregorian_seconds({{1970,1,1}, {8,0,0}}),
            {{OpenY,OpenM,OpenD}, _} = common_config:get_open_day(),
            OnlineDay = calendar:date_to_gregorian_days(erlang:date())-calendar:date_to_gregorian_days(OpenY,OpenM,OpenD),
            ?TRY_CATCH( common_behavior:send({pay_log,{AccountName,RoleID,RoleName,OrderID,PayMoney,PayGold,PayTime,Year, 
														Month, Day, Hour,Level,PayDateTime,OnlineDay}}), Err1 ),
            %%充值活动 
            catch global:send(mgeew_special_activity, {2,RoleID, PayGold}),
            catch common_activity:stat_special_activity(?SPEND_SUM_PAY_KEY,{RoleID,PayGold}),
            catch common_activity:stat_special_activity(?SPEND_ONCE_PAY_KEY,{RoleID,PayGold}),
			?DBG(PayGold),
			catch mod_open_activity:hook_pay_event(RoleID, PayGold),
			catch mod_role_tab:update_element(RoleID, p_role_attr, [{#p_role_attr.is_payed, true}]),
            ok;
        {aborted, Reason} ->
            case erlang:is_binary(Reason) of
                true ->
                    ?ERROR_MSG("~ts:~w", ["充值出错", common_tool:to_list(Reason)]);
                false ->
                    ?ERROR_MSG("~ts:~w", ["充值出错", Reason])
            end,
            case Reason of
                ?_LANG_PAY_DUPLICATED ->
                    used;
                ?_LANG_PAY_ACCOUNT_NOT_FOUND->
                    not_found;
                _ ->
                    error
            end
    end.

%% @doc 检查是否首次充值
check_is_first_pay(AccountName)->
    Limit = 1,
    MatchHead = #r_pay_log{_='_', account_name=AccountName},
    Guard = [],
    Result = ['$_'],
    case ets:select(?DB_PAY_LOG,[{MatchHead, Guard, Result}],Limit) of
        {ExpRecordList,_Continuation} when length(ExpRecordList)>0->
            false;
        _ ->    %% '$end_of_table'
            true
    end.

t_do_pay(OrderID, AccountName, PayTime, PayGold, PayMoney, {Year, Month, Day, Hour},IsFirst) ->
    %%判断是否该订单已经处理过
    case db:match_object(?DB_PAY_LOG, #r_pay_log{order_id=OrderID, _='_'}, write) of
        [] ->
            case get_role_base_by_name(AccountName) of
                []->
                    
                    LowerAccountName = get_lower_account_name(AccountName),
                    case get_role_base_by_name(LowerAccountName) of
                        []->
                            db:abort(?_LANG_PAY_ACCOUNT_NOT_FOUND);
                        RoleBase->
                            t_do_pay2(OrderID, AccountName, RoleBase, PayTime, PayGold, PayMoney, {Year, Month, Day, Hour},IsFirst)
                    end;
                RoleBase->
                    t_do_pay2(OrderID, AccountName, RoleBase, PayTime, PayGold, PayMoney, {Year, Month, Day, Hour},IsFirst)
            end;
        _ ->
            db:abort(?_LANG_PAY_DUPLICATED)
    end.

get_lower_account_name(AccountName)->
    case common_config:is_account_case_sensitive() of
        true->
            AccountName;
        _ ->
            list_to_binary( string:to_lower( binary_to_list(AccountName) ) )
    end.

%%@doc 根据账户名获取RoleBase
%%@return RoleBase | []
get_role_base_by_name(AccountName)->
    case db:match_object(?DB_ROLE_BASE_P, #p_role_base{account_name=AccountName, _='_'}, write) of
        [] ->
            [];
        RoleBaseList ->
            case RoleBaseList of
                [RoleBase] ->  RoleBase;
                _ -> {ok,RoleBase} = get_main_role_base(RoleBaseList)
            end,
            RoleBase
    end.

%%@doc 获取多个角色中的主角色
get_main_role_base(RoleBaseList) when is_list(RoleBaseList)->
    NewRoleBaseList = [ {RoleID,CreateTime,RoleBase}||#p_role_base{role_id=RoleID,create_time=CreateTime}=RoleBase<-RoleBaseList ],
    RoleLvList = lists:foldl(
                   fun(E,AccIn)->
                           {RoleID,CreateTime,RoleBase} = E,
                           case db:dirty_read(?DB_ROLE_ATTR,RoleID) of
                               [#p_role_attr{level=Level}] ->
                                   [{RoleID,Level,CreateTime,RoleBase}|AccIn];
                               _ ->
                                   AccIn
                           end
                   end, [], NewRoleBaseList),
    [H|T] = RoleLvList,
    get_main_role_base_2(H,T).

get_main_role_base_2(E,[])->
    {_RoleID,_v,_CreateTime,RoleBase} = E,
    {ok,RoleBase};
get_main_role_base_2(E,[H|T])->
    {_,LvE,CreateTimeE,_} = E,
    {_,LvH,CreateTimeH,_} = H,
    if
        LvE>LvH->
            get_main_role_base_2(E,T);
        LvH>LvE->
            get_main_role_base_2(H,T);
        true->
            if
                CreateTimeE>CreateTimeH->
                    get_main_role_base_2(E,T);
                true->
                    get_main_role_base_2(H,T)
            end
    end.            


%% 在线更新元宝
t_do_add_gold_online(OrderID, RoleID, PayGold, 0, {Year, Month, Day, Hour},IsFirst)->
    t_do_add_gold_online(OrderID, RoleID, PayGold,{Year, Month, Day, Hour},IsFirst);
t_do_add_gold_online(OrderID, RoleID, PayGold, PayReturnGold,{Year, Month, Day, Hour},IsFirst)->
    AddMoneyList = [{gold, PayGold,?GAIN_TYPE_GOLD_FROM_PAY,""},
                    {gold, PayReturnGold,?GAIN_TYPE_GOLD_PAY_RETURN_MONEY,""}],
    %%同时发送钱币/元宝更新的通知
    common_role_money:add(RoleID, AddMoneyList,{?ADD_GOLD_BY_PAY,OrderID,PayGold,PayReturnGold,{Year, Month, Day, Hour},IsFirst},{?ADD_GOLD_BY_PAY,OrderID,PayGold}, true).

t_do_add_gold_online(OrderID, RoleID, PayGold, {Year, Month, Day, Hour},IsFirst)->
    AddMoneyList = [{gold, PayGold,?GAIN_TYPE_GOLD_FROM_PAY,""}],
    %%同时发送钱币/元宝更新的通知
    common_role_money:add(RoleID, AddMoneyList,{?ADD_GOLD_BY_PAY,OrderID,PayGold,0,{Year, Month, Day, Hour},IsFirst},{?ADD_GOLD_BY_PAY,OrderID,PayGold}, true).

%% 离线更新元宝
t_do_add_gold_offline(RoleAttr,OldGold,PayGold)->
    NewRoleAttr = RoleAttr#p_role_attr{gold=OldGold + PayGold},
    db:write(?DB_ROLE_ATTR, NewRoleAttr, write).

t_do_pay2(OrderID, AccountName, RoleBase, PayTime, PayGold, PayMoney, {Year, Month, Day, Hour},IsFirst) ->
    #p_role_base{role_id=RoleID, role_name=RoleName} = RoleBase,
    [#p_role_attr{gold=OldGold,level=RoleLevel,is_payed=IsPayed}=RoleAttr] = db:read(?DB_ROLE_ATTR, RoleID),
    [#r_pay_log_index{value=ID}] = db:read(?DB_PAY_LOG_INDEX, 1),
    case IsPayed of
        true->  RoleAttr2=RoleAttr;
        _ ->    RoleAttr2=RoleAttr#p_role_attr{is_payed=true}
    end,
    
    NewID = 1 + ID, %%新的日志ID
    %%记录日志
    %%给对应的玩家添加元宝，发信件通知玩家
    RLog = #r_pay_log{id=ID+1,order_id=OrderID, role_id=RoleID, role_name=RoleName,
                      account_name=AccountName, pay_time=PayTime, pay_gold=PayGold,
                      pay_money=PayMoney, year=Year, month=Month, day=Day, hour=Hour, is_first=IsFirst,role_level=RoleLevel},
    t_do_pay3(OrderID, PayGold, OldGold, RoleAttr2, RLog, NewID,{Year, Month, Day, Hour},IsFirst,IsPayed).
        
    
%% 不满足首充
t_do_pay3(OrderID, PayGold, OldGold, RoleAttr, RLog, NewID,{Year, Month, Day, Hour},IsFirst,IsPayed) ->
    db:write(?DB_PAY_LOG, RLog, write),
    db:write(?DB_PAY_LOG_INDEX, #r_pay_log_index{id=1, value=NewID}, write),
    #p_role_attr{role_id=RoleID,role_name=RoleName} = RoleAttr,
    case db:read(?DB_PAY_ACTIVITY_P, RoleID, write) of
        [] ->
            db:write(?DB_PAY_ACTIVITY_P, #r_pay_activity{role_id=RoleID, all_pay_gold=PayGold, get_first=false, 
                                                         accumulate_history=[]}, write);
        [#r_pay_activity{all_pay_gold=AllPayGold} = PayActivity] ->
            db:write(?DB_PAY_ACTIVITY_P, PayActivity#r_pay_activity{role_id=RoleID, all_pay_gold=AllPayGold+PayGold}, write)
    end,
    %% mod by caochuncheng 2011-12-27 充值返还
    case get_pay_return_gold({Year,Month,Day,Hour},PayGold) of
        {ok,PayReturnGold} ->
            ignore;
        _ ->
            PayReturnGold = 0
    end,
    
    case db:read(?DB_USER_ONLINE, RoleID, read) =:= [] orelse common_misc:is_role_online2(RoleID) =:= false of
        true ->
			?ERROR_MSG("玩家离线充值：~w",[{OrderID, RoleID, PayGold, OldGold, {Year, Month, Day, Hour}}]),
            t_do_add_gold_offline(RoleAttr, OldGold,PayGold + PayReturnGold),
            common_consume_logger:gain_gold({RoleID, 0, PayReturnGold, ?GAIN_TYPE_GOLD_PAY_RETURN_MONEY, ""}),
            common_consume_logger:gain_gold({RoleID, 0, PayGold, ?GAIN_TYPE_GOLD_FROM_PAY, ""}),
			send_succ_letter(RoleID,RoleName,PayGold,PayReturnGold,{Year, Month, Day, Hour},IsFirst);
        false ->
			?ERROR_MSG("玩家在线充值：~w",[{OrderID, RoleID, PayGold, OldGold, {Year, Month, Day, Hour}}]),
            case IsPayed of
                true-> ignore;  %%之前已充值的玩家不需要修改标志
                _ -> 
                    db:write(?DB_ROLE_ATTR, RoleAttr, write)
            end,
			OtherArgs = {RoleName,PayGold,PayReturnGold,{Year, Month, Day, Hour},IsFirst},
			put_pay_order_dict(RoleID,OrderID,common_tool:now(),OtherArgs),
            t_do_add_gold_online(OrderID, RoleID, PayGold, PayReturnGold,{Year, Month, Day, Hour},IsFirst)
    end,    
    {RoleID, OldGold+PayGold+PayReturnGold, PayReturnGold, RoleAttr#p_role_attr.role_name}.

%% 获取充值返还元宝
get_pay_return_gold({_Year,_Month,_Day,_Hour},_PayGold) -> {error,no_pay_return_gold}.
    % {{OpenYear,OpenMonth,OpenDay},_OpenTime} = common_config:get_open_day(),
    % OpenSeconds = common_tool:datetime_to_seconds({{OpenYear,OpenMonth,OpenDay},{0,0,0}}),
    % PaySeconds = common_tool:datetime_to_seconds({{Year,Month,Day},{Hour,0,0}}),
    % [{{StartDay,EndDay},MinPayGold,ReturnPer}] = common_config_dyn:find(pay_gift, pay_return),
    % StartSeconds = OpenSeconds + StartDay * 24 * 60 * 60,
    % EndSeconds = OpenSeconds + EndDay * 24 * 60 * 60,
    % case PaySeconds >= StartSeconds andalso EndSeconds >= PaySeconds andalso PayGold >= MinPayGold of
    %     true -> %% 需要处理充值返还
    %         {ok,PayGold div ReturnPer};
    %     _ ->
    %         {error,no_pay_return_gold}
    % end.
            

%% 初始化充值记录表的数据
init_pay_index_table() ->
    case db:dirty_read(?DB_PAY_LOG_INDEX, 1) of
        [] ->
            db:dirty_write(?DB_PAY_LOG_INDEX, #r_pay_log_index{id=1, value=1});
        _ ->
            ignore
    end.
            
    
%%记录在线充值送元宝的日志表（不包括离线充值）
do_insert_pay_gold_log(IsSuccess,OrderID,RoleID,PayGold,_Reason)->
    try
        Now = common_tool:now(),
        StrReason = "",
        NSuccess = case IsSuccess of
                       true-> 1;
                       _-> 0
                   end,
        PayType = 1, %%'充值方式：1表示在线充值，2表示离线充值'
        FieldNames = [ order_id,role_id,is_succ,pay_type,pay_gold,mtime,reason ],
        FieldValues = [OrderID,RoleID,NSuccess,PayType,PayGold,Now,StrReason],
        
        SQL = mod_mysql:get_esql_insert(t_log_pay_gold,FieldNames,FieldValues),
        {ok,_} = mod_mysql:insert(SQL)
    catch
        _:Reason->
            ?ERROR_MSG("do_insert_pay_gold_log failed! reason: ~w, stack: ~w", [Reason, erlang:get_stacktrace()])
    end.    

    
%% 充值失败的记录插入到某个单独数据表中
do_insert_into_failed_queue(RoleID, OrderID, PayGold) ->
    case db:dirty_read(?DB_PAY_FAILED_P, OrderID) of
        [] ->
            db:dirty_write(?DB_PAY_FAILED_P, #r_pay_failed{order_id=OrderID, role_id=RoleID, pay_gold=PayGold});
        _ ->
            %% 已经记录了就不用处理了
            ignore
    end.

do_remove_failed_queue(OrderID) ->
    db:dirty_delete(?DB_PAY_FAILED_P, OrderID).

loop() ->
	case erlang:get(pay_order_list) of
		undefined ->
			nil;
		[] ->
			nil;
		PayOrderList ->
			Now = common_tool:now(),
			lists:foreach(fun({{RoleID,OrderID},PayTime,OtherArgs}) ->
								  case Now - PayTime >= ?PAY_FAILED_RETURN_SECONDS of
									  true ->
										  delete_pay_order_dict(RoleID,OrderID),
										  return_money(RoleID,OrderID,PayTime,OtherArgs);
									  false ->
										  nil
								  end
						  end, PayOrderList)
	end.

delete_pay_order_dict(RoleID,OrderID) ->
	case erlang:get(pay_order_list) of
		undefined ->
			nil;
		PayOrderList ->
			erlang:put(pay_order_list,lists:keydelete({RoleID,OrderID},1,PayOrderList))
	end.
put_pay_order_dict(RoleID,OrderID,PayTime,OtherArgs) ->
	common_misc:update_dict_queue(pay_order_list, {{RoleID,OrderID},PayTime,OtherArgs}).

return_money(RoleID,OrderID,PayTime,OtherArgs) ->
	Func = fun() ->
				   ?ERROR_MSG("杯具事情发生了,充值成功但玩家元宝没到账,Args:~w",[{RoleID,OrderID,PayTime,OtherArgs}]),
				   {RoleName,PayGold,PayReturnGold,{Year, Month, Day, Hour},IsFirst} = OtherArgs,
				   [#p_role_attr{gold=OldGold}=RoleAttr] = db:read(?DB_ROLE_ATTR, RoleID),
				   case db:read(?DB_USER_ONLINE, RoleID, read) =:= [] orelse common_misc:is_role_online2(RoleID) =:= false of
					   true ->
						   ?ERROR_MSG("玩家离线充值(补充)：~w",[{OrderID, RoleID, PayGold, OldGold, {Year, Month, Day, Hour}}]),
						   t_do_add_gold_offline(RoleAttr, OldGold,PayGold + PayReturnGold),
						   common_consume_logger:gain_gold({RoleID, 0, PayReturnGold, ?GAIN_TYPE_GOLD_PAY_RETURN_MONEY, ""}),
						   common_consume_logger:gain_gold({RoleID, 0, PayGold, ?GAIN_TYPE_GOLD_FROM_PAY, ""}),
						   send_succ_letter(RoleID,RoleName,PayGold,PayReturnGold,{Year, Month, Day, Hour},IsFirst);
					   false ->
						   ?ERROR_MSG("玩家在线充值(补充)：~w",[{OrderID, RoleID, PayGold, OldGold, {Year, Month, Day, Hour}}]),
						   db:write(?DB_ROLE_ATTR, RoleAttr, write),
						   %%开放以下两行代码将一直补充值到成功，但比较危险，暂时只给一次补充值机会
						   %%OtherArgs = {RoleName,PayGold,PayReturnGold,{Year, Month, Day, Hour},IsFirst},
						   %%put_pay_order_dict(RoleID,OrderID,common_tool:now(),OtherArgs),
						   t_do_add_gold_online(OrderID, RoleID, PayGold, PayReturnGold,{Year, Month, Day, Hour},IsFirst)
				   end
		   end,
	case db:transaction(Func) of
		{atomic, _} ->
			ok;
		{aborted, Error} ->
			?ERROR_MSG("补发玩家失败充值记录失败:~w", [{RoleID,OrderID,PayTime,OtherArgs,Error}])
	end.	
			                                  
do_process_failed_queue() ->
    lists:foreach(
      fun(#r_pay_failed{order_id=OrderID, role_id=RoleID, pay_gold=PayGold}) ->
              do_process_failed(OrderID, RoleID, PayGold)
      end, db:dirty_match_object(?DB_PAY_FAILED_P, #r_pay_failed{_='_'})).

do_process_failed(OrderID, RoleID, PayGold) ->
    Func = fun() ->
                   [RoleAttr] = db:read(?DB_ROLE_ATTR, RoleID, write),
                   [#r_pay_log{year=Year, month=Month, day=Day, hour=Hour, is_first=IsFirst}] = db:match_object(?DB_PAY_LOG, #r_pay_log{order_id=OrderID, _='_'}, write),
                   %% mod by caochuncheng 2011-12-27 充值返还
                   case get_pay_return_gold({Year,Month,Day,Hour},PayGold) of
                       {ok,PayReturnGold} ->
                           ignore;
                       _ ->
                           PayReturnGold = 0
                   end,
                   case db:read(?DB_USER_ONLINE, RoleID, read) of
                       [] ->
                           t_do_add_gold_offline(RoleAttr#p_role_attr{is_payed=true}, RoleAttr#p_role_attr.gold, PayGold + PayReturnGold),
                           common_consume_logger:gain_gold({RoleAttr#p_role_attr.role_id, 0, PayReturnGold, ?GAIN_TYPE_GOLD_PAY_RETURN_MONEY, ""}),
                           common_consume_logger:gain_gold({RoleID, 0, PayGold, ?GAIN_TYPE_GOLD_FROM_PAY, ""});
                       _ ->
                           db:write(?DB_ROLE_ATTR, RoleAttr#p_role_attr{is_payed=true}, write),
                           t_do_add_gold_online(OrderID, RoleID, PayGold, PayReturnGold, {Year,Month,Day,Hour}, IsFirst)
                   end
           end,
    case db:transaction(Func) of
        {atomic, _} ->
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("{OrderID, RoleID, PayGold}=~w",[{OrderID, RoleID, PayGold}]),
            ?ERROR_MSG("~ts:~p", ["补发玩家失败充值记录失败", Error])
    end.

send_succ_letter(RoleID,RoleName,PayGold,PayReturnGold,{_Year, _Month, _Day, _Hour},_IsFirst) ->
	Content = common_letter:create_temp(?RECHARGE_SUCCESS_LETTER, [RoleName, PayGold]),
	common_letter:sys2p(RoleID,Content,?_LANG_LEETER_PAY_SUCCESS,14),
	case PayReturnGold > 0 of
		true ->
			PayReturnLetterContent = common_letter:create_temp(?PAY_RETURN_GOLD_LETTER, [common_tool:to_list(PayReturnGold)]),
			common_letter:sys2p(RoleID,PayReturnLetterContent,common_tool:to_list(?_LANG_LEETER_PAY_RETURN_GOLD_LETTER_TITLE),14);
		_ ->
			ignore
	end.
	% case IsFirst of
	% 	true ->
	% 		Text = common_letter:create_temp(?PAY_FIRST_LETTER, [RoleName, Year, Month, Day]),
	% 		common_letter:sys2p(RoleID, Text, ?_LANG_PAY_FIRST_TITLE, 14);
	% 	false ->
	% 		ignore
	% end.
