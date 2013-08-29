%%%-------------------------------------------------------------------
%%% @author  caochuncheng
%%% @copyright mcsd (C) 2010, 
%%% @doc
%%% 后台广播消息处理
%%% @end
%%% Created : 13 Jul 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_broadcast_admin).

-behaviour(gen_server).

%% Include files
-include("mgeew.hrl").
-include("broadcast.hrl").

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {message_list,games_open_date}).

-define(ADMIN_TYPE_LIST,[
                        {?BC_MSG_TYPE_SYSTEM, true},
                        {?BC_MSG_TYPE_ALL, true},
                        {?BC_MSG_TYPE_CENTER, true},
                        {?BC_MSG_TYPE_CHAT, true},
                        {?BC_MSG_TYPE_POP,true}]).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link({ProcessName}) ->
    gen_server:start_link({local, erlang:list_to_atom(ProcessName)}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    {{Year,Month,Day}, _} = common_config:get_open_day(),
    Month2 = if Month < 10 ->
                     lists:concat(["0",erlang:integer_to_list(Month)]);
                true ->
                     lists:concat(["",erlang:integer_to_list(Month)])
             end,
    Day2 = if Day < 10 ->
                   lists:concat(["0",erlang:integer_to_list(Day)]);
              true ->
                   lists:concat(["",erlang:integer_to_list(Day)])
           end,
    OpenDate = lists:concat(["" , erlang:integer_to_list(Year),"-", Month2, "-",Day2]),
    %% OpenDate = "2010-11-10",
    ?DEBUG("~ts,OpenDate=~w",["获取的开服日期为：",OpenDate]),
    {ok, #state{message_list = [],games_open_date = OpenDate}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(Info, State) ->
    ?DEBUG("~ts,Info=~w", ["接收到消息为",Info]),
    try 
        do_handle_info(Info, State)
    catch
        T:R ->
            ?ERROR_MSG("module: ~w, line: ~w, Info:~w, type: ~w, reason: ~w,stactraceo: ~w",
                       [?MODULE, ?LINE, Info, T, R, erlang:get_stacktrace()])
    end.

    

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================


%% 消息处理
do_handle_info({Unique, Module, Method, Record}, State) ->
    NewState = do_admin_message(Unique, Module, Method, Record, State),
    {noreply, NewState};
%% 定时发送处理
do_handle_info({send_admin_message, Key}, State) ->
    ?DEBUG("~ts,State=~w",["当前后台消息处理状态数据为：",State]),
    NewState = cycle_send_admin_message(Key, State),
    {noreply, NewState};
%% 更新消息处理
do_handle_info({update_admin_message, Record}, State) ->
    NewState = update_send_admin_message(Record,State),
    {noreply, NewState};
%% 删除消息处理
do_handle_info({delete_admin_message, DeleteIdList}, State) ->
    NewState = delete_send_admin_message(DeleteIdList,State),
    {noreply, NewState};
do_handle_info({terminate}, State) ->
    ?INFO_MSG("~ts.",["停止前一次的后台消息广播处理"]),
    {stop, normal, State};

%% 添加外部操作本进程内部执行接口
do_handle_info({func, Fun, Args}, State) ->
    Ret = (catch apply(Fun,Args)),
    ?ERROR_MSG("~w",[Ret]),
    {noreply, State};

do_handle_info(Info, State) ->
    ?ERROR_MSG("~ts,Info=~w",["无法处理此消息",Info]),
    {noreply, State}.

%% 后台广播消息处理
%% Record 结构为 m_broadcast_admin_tos
do_admin_message(Unique, Module, Method, Record, State) ->
    case catch do_admin_message2(Unique, Module, Method, Record, State) of
        {error,Reason} ->
            do_admin_message_error(Unique, Module, Method, Record, Reason, State);
        ok ->
            do_admin_message6(Unique, Module, Method, Record, State)
    end.
do_admin_message2(Unique, Module, Method, Record, State) ->
    case catch do_admin_message3(Unique, Module, Method, Record, State) of
        {error,Reason3} ->
            erlang:throw({error,Reason3});
        ok ->
            ok
    end,
    case catch do_admin_message4(Unique, Module, Method, Record, State) of
        {error,Reason4} ->
            erlang:throw({error,Reason4});
        ok ->
            ok
    end,
    case catch do_admin_message5(Unique, Module, Method, Record, State) of
        {error,Reason5} ->
            erlang:throw({error,Reason5});
        ok ->
            ok
    end.
    
do_admin_message3(_Unique, _Module, _Method, Record, _State) ->
    if erlang:is_record(Record, m_broadcast_admin_tos) ->
            ok;
       true ->
            erlang:throw({error,<<"消息结构不是m_broadcast_admin_tos">>}) 
    end,
    Type = Record#m_broadcast_admin_tos.type,
    case proplists:lookup(Type, ?ADMIN_TYPE_LIST) of
        none ->
            erlang:throw({error,<<"消息子类型不合法">>}) ;
        _ ->
            ok
    end,
    Content =  Record#m_broadcast_admin_tos.content,
    if Content =:= "" ->
            erlang:throw({error,<<"消息内容为空">>});
       true ->
            ok
    end,
    SendStrategy = Record#m_broadcast_admin_tos.send_strategy,
    if SendStrategy =/= 0 
       andalso SendStrategy =/= 1 
       andalso SendStrategy =/= 2 
       andalso SendStrategy =/= 3
       andalso SendStrategy =/= 4 ->
            erlang:throw({error,<<"SendStrategy 参数内容不合法">>});
       true ->
            ok
    end.
do_admin_message4(_Unique, _Module, _Method, Record, _State) ->
    SendStrategy = Record#m_broadcast_admin_tos.send_strategy,
    StartDate = Record#m_broadcast_admin_tos.start_date,
    EndDate = Record#m_broadcast_admin_tos.end_date,
    if SendStrategy =:= 1 orelse SendStrategy =:= 4 ->
            case check_date_string(StartDate) of 
                true ->
                    ok;
                false ->
                    erlang:throw({error,<<"当SendStrategy=1,4时，start_date日期格式出错">>})
            end,
            case check_date_string(EndDate) of
                true ->
                    ok;
                false ->
                     erlang:throw({error,<<"当SendStrategy=1,4时，end_date日期格式出错">>})
            end,
            StartDays = get_date_for_string(StartDate),
            EndDays = get_date_for_string(EndDate),
            if StartDays =< EndDays ->
                    ok;
               true ->
                    erlang:throw({error,<<"当SendStrategy=1,4时，start_date > end_date日期格式出错">>})
            end;
       true ->
            ok
    end,
    if SendStrategy =:= 2 ->
            TStartDate = erlang:list_to_integer(StartDate),
            TEndDate = erlang:list_to_integer(EndDate),
            if TStartDate =< TEndDate andalso TEndDate >= 1 andalso TEndDate =< 7
               andalso TStartDate >= 1 andalso TStartDate =< 7 ->
                    ok;
               true ->
                    erlang:throw({error,<<"当SendStrategy=2时，星期参数出错">>})
            end;
       true ->
            ok
    end,
    if SendStrategy =:= 3 ->
            PStartDate = erlang:list_to_integer(StartDate),
            PEndDate = erlang:list_to_integer(EndDate),
            if PStartDate =< PEndDate ->
                    ok;
               true ->
                    erlang:throw({error,<<"当SendStrategy=3时，开服后天数参数出错">>})
            end;
       true ->
            ok
    end.
do_admin_message5(_Unique, _Module, _Method, Record, State) ->
    #state{games_open_date = GamesOpenDate} = State,
    SendStrategy = Record#m_broadcast_admin_tos.send_strategy,
    StartDate = Record#m_broadcast_admin_tos.start_date,
    EndDate = Record#m_broadcast_admin_tos.end_date,
    StartTime = Record#m_broadcast_admin_tos.start_time,
    EndTime = Record#m_broadcast_admin_tos.end_time,
    if SendStrategy =/= 0 ->
            case check_time_string(StartTime) of
                false ->
                    erlang:throw({error,<<"start_time 数参数出错">>});
                true ->
                    ok
            end,
            case check_time_string(EndTime) of
                false ->
                    erlang:throw({error,<<"end_time 数参数出错">>});
                true ->
                    ok
            end;
       true ->
            ok
    end,
    if SendStrategy =:= 1 orelse SendStrategy =:= 2
       orelse SendStrategy =:= 3 ->
            StartSeconds = get_time_for_string(StartTime),
            EndSeconds = get_time_for_string(EndTime),
            if StartSeconds =< EndSeconds ->
                    ok;
               true ->
                    erlang:throw({error,<<"start_time > end_time 出错">>})
            end;
       SendStrategy =:= 4 ->
            StartDays4 = get_date_for_string(StartDate),
            EndDays4 = get_date_for_string(EndDate),
            StartSeconds4 = get_time_for_string(StartTime),
            EndSeconds4 = get_time_for_string(EndTime),
            Interval4 = calc_diff_seconds(StartDays4,StartSeconds4,EndDays4,EndSeconds4),
            if Interval4 < 0  ->
                    erlang:throw({error,<<"start_day + start_time > end_day + end_time 出错">>});
               true ->
                    ok
            end;
       true ->
            ok
    end,
    NowDays = calendar:date_to_gregorian_days(date()),
    NowSeconds = calendar:time_to_seconds(time()),
    if SendStrategy =:= 1 orelse SendStrategy =:= 4 ->
            EndDays = get_date_for_string(EndDate),
            EndSeconds2 = get_time_for_string(EndTime),
            Interval = calc_diff_seconds(NowDays,NowSeconds,EndDays,EndSeconds2),
            ?DEBUG("~ts,Interval=~w",["结束时间与当前时间比较结果",Interval]),
            if Interval < 0 ->
                    erlang:throw({error,<<"发送的时间段已经过期，不需要处理此消息">>});
               true ->
                    ok
            end;
       SendStrategy =:= 3 ->
            EndDateNumber = erlang:list_to_integer(EndDate,10),
            OpenServiceDays = get_open_service_days(GamesOpenDate),
            EndSeconds3 = get_time_for_string(EndTime),
            CheckInterval = calc_diff_seconds(NowDays,NowSeconds,OpenServiceDays + EndDateNumber,EndSeconds3),
            if CheckInterval < 0 ->
                    ?DEBUG("~ts,CheckInterval=~w,OpenServiceDays=~w",["开服后消息时间检查不合法，不处理此消息",CheckInterval,OpenServiceDays]);
               true ->
                    ok
            end;
       true ->
            ok
    end.
                
                                  
do_admin_message6(Unique, Module, Method, Record, State) ->
    SendStrategy = Record#m_broadcast_admin_tos.send_strategy,
    Key = Record#m_broadcast_admin_tos.id,
    do_admin_message7(SendStrategy, Key, Unique, Module, Method, Record, State).

do_admin_message7(0, Key, Unique, Module, Method, Record, State) ->
    do_admin_message_now(Key, Unique, Module, Method, Record, State);

do_admin_message7(1, Key, Unique, Module, Method, Record, State) ->
    do_admin_message_range(Key, Unique, Module, Method, Record, State);

do_admin_message7(2, Key, Unique, Module, Method, Record, State) ->
    do_admin_message_week(Key, Unique, Module, Method, Record, State);

do_admin_message7(3, Key, Unique, Module, Method, Record, State) ->
    do_admin_message_open_service(Key, Unique, Module, Method, Record, State);

do_admin_message7(4, Key, Unique, Module, Method, Record, State) ->
    do_admin_message_keep(Key, Unique, Module, Method, Record, State).
                                                              
%% 立即发送
do_admin_message_now(_Key, Unique, Module, Method, Record, State) ->
    ?DEBUG("~ts,Record=~w",["立即发送消息处理",Record]),
    do_send_message(Unique, Module, Method, Record),
    State.
%% 指定日期时间范围发送
do_admin_message_range(Key, Unique, Module, Method, Record, State) ->
    StartDays = get_date_for_string(Record#m_broadcast_admin_tos.start_date),
    EndDays = get_date_for_string(Record#m_broadcast_admin_tos.end_date),

    StartSeconds = get_time_for_string(Record#m_broadcast_admin_tos.start_time),
    EndSeconds = get_time_for_string(Record#m_broadcast_admin_tos.end_time),
    Interval = Record#m_broadcast_admin_tos.interval,
    IntervalTime = Interval * 1000,
    
    NowDays = calendar:date_to_gregorian_days(date()),
    NowSeconds = calendar:time_to_seconds(time()),
    AdminRecord = {StartDays,EndDays,StartSeconds,EndSeconds,IntervalTime,NowDays,NowSeconds},
    do_admin_message_range2(Key, Unique, Module, Method, Record, State, AdminRecord).

do_admin_message_range2(Key, Unique, Module, Method, Record, State, AdminRecord) ->
    #state{message_list = MessageList} = State,
    {StartDays,EndDays,StartSeconds,_EndSeconds,IntervalTime,NowDays,NowSeconds}=AdminRecord,
    if NowDays >= StartDays andalso NowSeconds >= StartSeconds ->
            %%当前时间有可能需要发送
            do_admin_message_range3(Key, Unique, Module, Method, Record, State, AdminRecord);
       NowDays >= StartDays 
       andalso EndDays >= NowDays
       andalso StartSeconds > NowSeconds ->
            NewInterval2 = calc_diff_seconds(NowDays,NowSeconds,NowDays,StartSeconds),
            NewInterval3 = 
                if NewInterval2 > 0 ->
                        NewInterval2 * 1000;
                   true ->
                        IntervalTime
                end,
            TimerRef2 = erlang:send_after(NewInterval3 , self(), {send_admin_message, Key}),
            MessageRecord2 = #r_broadcast_admin_msg{msg_record = Record, unique = Unique , module = Module, method = Method, timer_ref = TimerRef2},
            NewMessageList2 = lists:append(MessageList,[{Key, MessageRecord2}]),
            State#state{message_list = NewMessageList2};
       true ->
            %% 计算下一次的发送时间，当前时间不是发送时间
            ?DEBUG("~ts,Record=~w",["当前不到发送消息开始时间，计算消息发送开始时间处理",Record]),
            NewInterval = calc_diff_seconds(NowDays,NowSeconds,StartDays,StartSeconds),
            TimerRef = erlang:send_after(NewInterval * 1000, self(), {send_admin_message, Key}),
            MessageRecord = #r_broadcast_admin_msg{msg_record = Record, unique = Unique , module = Module, method = Method, timer_ref = TimerRef},
            NewMessageList = lists:append(MessageList,[{Key, MessageRecord}]),
            State#state{message_list = NewMessageList}
    end.
do_admin_message_range3(Key, Unique, Module, Method, Record, State, AdminRecord) ->
    #state{message_list = MessageList} = State,
    {_StartDays,EndDays,StartSeconds,EndSeconds,IntervalTime,NowDays,NowSeconds}=AdminRecord,
    if NowDays =< EndDays andalso NowSeconds < EndSeconds ->
            ?DEBUG("~ts,Record=~w",["当日内一段时间内定时发送消息处理",Record]),
            do_send_message(Unique, Module, Method, Record),
            NewInterval = calc_diff_seconds(NowDays,NowSeconds,EndDays,EndSeconds),
            TimerRef = if IntervalTime < (NewInterval * 1000) ->
                               erlang:send_after(IntervalTime, self(), {send_admin_message, Key});
                          true ->
                               erlang:send_after(NewInterval * 1000, self(), {send_admin_message, Key})
                       end,
            MessageRecord = #r_broadcast_admin_msg{msg_record = Record, unique = Unique , module = Module, method = Method, timer_ref = TimerRef},
            NewMessageList = lists:append(MessageList,[{Key, MessageRecord}]),
            State#state{message_list = NewMessageList};
       NowDays =< EndDays ->
            ?DEBUG("~ts,Record=~w",["当日内发送消息已经完成，计算后一天发送时间处理",Record]),
            NextDateInterval = calc_diff_seconds(NowDays,NowSeconds,NowDays + 1, StartSeconds),
            TimerRef = erlang:send_after(NextDateInterval * 1000, self(), {send_admin_message, Key}),
            MsgRecord = #r_broadcast_admin_msg{msg_record = Record, unique = Unique , module = Module, method = Method, timer_ref = TimerRef},
            NewMsgList = lists:append(MessageList,[{Key, MsgRecord}]),
            State#state{message_list = NewMsgList};
       true ->
            ?DEBUG("~ts,Record=~w",["每天一段时间内定时发送消息处理已经结束处理",Record]),
            NewMsgList = proplists:delete(Key, MessageList),
            State#state{message_list = NewMsgList}
    end.
            
%% 按星期发送
do_admin_message_week(Key, Unique, Module, Method, Record, State) ->
    StartDays = erlang:list_to_integer(Record#m_broadcast_admin_tos.start_date,10),
    EndDays = erlang:list_to_integer(Record#m_broadcast_admin_tos.end_date,10),

    StartSeconds = get_time_for_string(Record#m_broadcast_admin_tos.start_time),
    EndSeconds = get_time_for_string(Record#m_broadcast_admin_tos.end_time),
    Interval = Record#m_broadcast_admin_tos.interval,
    IntervalTime = Interval * 1000,
    
    NowDays = calendar:date_to_gregorian_days(date()),
    NowSeconds = calendar:time_to_seconds(time()),
    AdminRecord = {StartDays,EndDays,StartSeconds,EndSeconds,IntervalTime,NowDays,NowSeconds},
    do_admin_message_week2(Key, Unique, Module, Method, Record, State, AdminRecord).

do_admin_message_week2(Key, Unique, Module, Method, Record, State, AdminRecord) ->
    #state{message_list = MessageList} = State,
    {StartDays,EndDays,StartSeconds,_EndSeconds,_IntervalTime,NowDays,NowSeconds}=AdminRecord,
    NowWeek = calendar:day_of_the_week(calendar:gregorian_days_to_date(NowDays)),
    if NowWeek >= StartDays andalso NowWeek =< EndDays ->
            %% 符星期几发送条件
            do_admin_message_week3(Key, Unique, Module, Method, Record, State, AdminRecord);
       true ->
            %% 简单处理每天检查一次
            ?DEBUG("~ts,Record=~w",["星期周期性时间间隔内发送消息当前没有到发送时间，计算后一天检查时间处理",Record]),
            NewInterval = calc_diff_seconds(NowDays, NowSeconds, NowDays + 1, StartSeconds),
            TimerRef = erlang:send_after(NewInterval * 1000, self(), {send_admin_message, Key}),
            MessageRecord = #r_broadcast_admin_msg{msg_record = Record, unique = Unique , module = Module, method = Method, timer_ref = TimerRef},
            NewMessageList = lists:append(MessageList,[{Key, MessageRecord}]),
            State#state{message_list = NewMessageList}
    end.
do_admin_message_week3(Key, Unique, Module, Method, Record, State, AdminRecord) ->
    #state{message_list = MessageList} = State,
    {_StartDays,_EndDays,StartSeconds,EndSeconds,IntervalTime,NowDays,NowSeconds}=AdminRecord,
    if NowSeconds >= StartSeconds andalso NowSeconds < EndSeconds  ->
            ?DEBUG("~ts,Record=~w",["星期周期性时间间隔内发送消息发送处理",Record]),
            do_send_message(Unique, Module, Method, Record),
            NewInterval = calc_diff_seconds(NowDays,NowSeconds,NowDays,EndSeconds),
            TimerRef = if IntervalTime < (NewInterval * 1000) ->
                               erlang:send_after(IntervalTime, self(), {send_admin_message, Key});
                          true ->
                               erlang:send_after(NewInterval * 1000, self(), {send_admin_message, Key})
                       end,
            MessageRecord = #r_broadcast_admin_msg{msg_record = Record, unique = Unique , module = Module, method = Method, timer_ref = TimerRef},
            NewMessageList = lists:append(MessageList,[{Key, MessageRecord}]),
            State#state{message_list = NewMessageList};
       true ->
            ?DEBUG("~ts,Record=~w",["当前不需要处理星期几间隔时间内发送的消息，计算明天检查时间处理",Record]),
            NextInterval = calc_diff_seconds(NowDays, NowSeconds, NowDays + 1, StartSeconds),
            TimerRef = erlang:send_after(NextInterval * 1000, self(), {send_admin_message, Key}),
            MessageRecord = #r_broadcast_admin_msg{msg_record = Record, unique = Unique , module = Module, method = Method, timer_ref = TimerRef},
            NewMessageList = lists:append(MessageList,[{Key, MessageRecord}]),
            State#state{message_list = NewMessageList}
    end.

%% 开服后发送
do_admin_message_open_service(Key, Unique, Module, Method, Record, State) ->
    #state{games_open_date = GamesOpenDate} = State,
    StartDate = erlang:list_to_integer(Record#m_broadcast_admin_tos.start_date,10),
    EndDate = erlang:list_to_integer(Record#m_broadcast_admin_tos.end_date,10),
    OpenServiceDays = get_open_service_days(GamesOpenDate),
    StartSeconds = get_time_for_string(Record#m_broadcast_admin_tos.start_time),
    EndSeconds = get_time_for_string(Record#m_broadcast_admin_tos.end_time),
    Interval = Record#m_broadcast_admin_tos.interval,
    IntervalTime = Interval * 1000,
    
    StartDays = OpenServiceDays + StartDate,
    EndDays = OpenServiceDays + EndDate,

    NowDays = calendar:date_to_gregorian_days(date()),
    NowSeconds = calendar:time_to_seconds(time()),
    AdminRecord = {StartDays,EndDays,StartSeconds,EndSeconds,IntervalTime,NowDays,NowSeconds,OpenServiceDays},
    do_admin_message_open_service2(Key, Unique, Module, Method, Record, State, AdminRecord).

do_admin_message_open_service2(Key, Unique, Module, Method, Record, State, AdminRecord) ->
    #state{message_list = MessageList} = State,
    {StartDays,EndDays,StartSeconds,EndSeconds,IntervalTime,NowDays,NowSeconds,_OpenServiceDays} = AdminRecord,
    if NowDays >= StartDays andalso NowSeconds >= StartSeconds ->
            %%当前时间有可能需要发送
            do_admin_message_open_service3(Key, Unique, Module, Method, Record, State, AdminRecord);
       NowDays >= StartDays 
       andalso EndDays >= NowDays
       andalso StartSeconds > NowSeconds ->
            NewInterval2 = calc_diff_seconds(NowDays,NowSeconds,NowDays,StartSeconds),
            NewInterval3 = 
                if NewInterval2 > 0 ->
                        NewInterval2 * 1000;
                   true ->
                        IntervalTime
                end,
            TimerRef2 = erlang:send_after(NewInterval3, self(), {send_admin_message, Key}),
            MessageRecord2 = #r_broadcast_admin_msg{msg_record = Record, unique = Unique , module = Module, method = Method, timer_ref = TimerRef2},
            NewMessageList2 = lists:append(MessageList,[{Key, MessageRecord2}]),
            State#state{message_list = NewMessageList2};
       true ->
            CheckInterval = calc_diff_seconds(NowDays,NowSeconds,EndDays,EndSeconds),
            if CheckInterval < 0 ->
                    ?DEBUG("~ts,Record=~w",["发送开服后消息任务已经结束，或不合法无法开始发送",Record]),
                    NewMsgList = proplists:delete(Key, MessageList),
                    State#state{message_list = NewMsgList};
               true ->
                    %% 计算下一次的发送时间，当前时间不是发送时间
                    ?DEBUG("~ts,Record=~w",["当前开服后消息发送不需要马上开始发送，计算下一次发送时间处理",Record]),
                    NewInterval = calc_diff_seconds(NowDays,NowSeconds,StartDays,StartSeconds),
                    if NewInterval < 0 ->
                            do_admin_message_open_service3(Key, Unique, Module, Method, Record, State, AdminRecord);
                       true ->
                            TimerRef = erlang:send_after(NewInterval * 1000, self(), {send_admin_message, Key}),
                            MessageRecord = #r_broadcast_admin_msg{msg_record = Record, unique = Unique , 
                                                                   module = Module, method = Method, timer_ref = TimerRef},
                            NewMessageList = lists:append(MessageList,[{Key, MessageRecord}]),
                            State#state{message_list = NewMessageList}
                    end
            end
    end.
do_admin_message_open_service3(Key, Unique, Module, Method, Record, State, AdminRecord) ->
    #state{message_list = MessageList} = State,
    {_StartDays,EndDays,StartSeconds,EndSeconds,IntervalTime,NowDays,NowSeconds,_OpenServiceDays} = AdminRecord,
    if NowDays =< EndDays andalso NowSeconds < EndSeconds ->
            ?DEBUG("~ts,Record=~w",["当前开服后消息发送当天定时发送处理",Record]),
            do_send_message(Unique, Module, Method, Record),
            NewInterval = calc_diff_seconds(NowDays,NowSeconds,EndDays,EndSeconds),
            TimerRef = if IntervalTime < (NewInterval * 1000) ->
                               erlang:send_after(IntervalTime, self(), {send_admin_message, Key});
                          true ->
                               erlang:send_after(NewInterval * 1000, self(), {send_admin_message, Key})
                       end,
            MessageRecord = #r_broadcast_admin_msg{msg_record = Record, unique = Unique , module = Module, method = Method, timer_ref = TimerRef},
            NewMessageList = lists:append(MessageList,[{Key, MessageRecord}]),
            State#state{message_list = NewMessageList};
       NowDays =< EndDays ->
            ?DEBUG("~ts,Record=~w",["当前开服后消息发送当天已经超过发送时间，计算后一天的发送时间处理",Record]),
            NextDateInterval = calc_diff_seconds(NowDays,NowSeconds,NowDays + 1, StartSeconds),
            TimerRef = erlang:send_after(NextDateInterval * 1000, self(), {send_admin_message, Key}),
            MsgRecord = #r_broadcast_admin_msg{msg_record = Record, unique = Unique , module = Module, method = Method, timer_ref = TimerRef},
            NewMsgList = lists:append(MessageList,[{Key, MsgRecord}]),
            State#state{message_list = NewMsgList};
       true ->
            ?DEBUG("~ts,Record=~w",["发送开服后消息任务已经结束，或不合法无法开始发送",Record]),
            NewMsgList = proplists:delete(Key, MessageList),
            State#state{message_list = NewMsgList}
    end.

%% 持续时间段间隔发送
do_admin_message_keep(Key, Unique, Module, Method, Record, State) ->
    StartDays = get_date_for_string(Record#m_broadcast_admin_tos.start_date),
    EndDays = get_date_for_string(Record#m_broadcast_admin_tos.end_date),

    StartSeconds = get_time_for_string(Record#m_broadcast_admin_tos.start_time),
    EndSeconds = get_time_for_string(Record#m_broadcast_admin_tos.end_time),
    Interval = Record#m_broadcast_admin_tos.interval,
    IntervalTime = Interval * 1000,
    
    NowDays = calendar:date_to_gregorian_days(date()),
    NowSeconds = calendar:time_to_seconds(time()),
    AdminRecord = {StartDays,EndDays,StartSeconds,EndSeconds,IntervalTime,NowDays,NowSeconds},
    do_admin_message_keep2(Key, Unique, Module, Method, Record, State, AdminRecord).

do_admin_message_keep2(Key, Unique, Module, Method, Record, State, AdminRecord) ->
    #state{message_list = MessageList} = State,
    {StartDays,_EndDays,StartSeconds,_EndSeconds,IntervalTime,NowDays,NowSeconds}=AdminRecord,
    NowInterval = calc_diff_seconds(StartDays,StartSeconds,NowDays,NowSeconds),
    if NowInterval > 0 ->
            %%当前时间有可能需要发送
            do_admin_message_keep3(Key, Unique, Module, Method, Record, State, AdminRecord);
       true ->
            %% 计算下一次的发送时间，当前时间不是发送时间
            ?DEBUG("~ts,Record=~w",["当前持续间隔时间发送消息还没有开始发送处理",Record]),
            NewInterval = calc_diff_seconds(NowDays,NowSeconds,StartDays,StartSeconds),
            TimerRef = 
                if NewInterval < 0 ->
                        erlang:send_after(IntervalTime, self(), {send_admin_message, Key});
                   true ->
                        erlang:send_after(NewInterval * 1000, self(), {send_admin_message, Key})
                end,
            MessageRecord = #r_broadcast_admin_msg{msg_record = Record, unique = Unique , module = Module, method = Method, timer_ref = TimerRef},
            NewMessageList = lists:append(MessageList,[{Key, MessageRecord}]),
            State#state{message_list = NewMessageList}
    end.
do_admin_message_keep3(Key, Unique, Module, Method, Record, State, AdminRecord) ->
    #state{message_list = MessageList} = State,
    {_StartDays,EndDays,_StartSeconds,EndSeconds,IntervalTime,NowDays,NowSeconds}=AdminRecord,
    NewInterval = calc_diff_seconds(NowDays,NowSeconds,EndDays,EndSeconds),
    if NewInterval > 0 ->
            ?DEBUG("~ts,Record=~w",["持续间隔时间消息定时间隔时间发送处理",Record]),
            do_send_message(Unique, Module, Method, Record),
            TimerRef = if IntervalTime < (NewInterval * 1000) ->
                               erlang:send_after(IntervalTime, self(), {send_admin_message, Key});
                          true ->
                               erlang:send_after(NewInterval * 1000, self(), {send_admin_message, Key})
                       end,
            MessageRecord = #r_broadcast_admin_msg{msg_record = Record, unique = Unique , module = Module, method = Method, timer_ref = TimerRef},
            NewMessageList = lists:append(MessageList,[{Key, MessageRecord}]),
            State#state{message_list = NewMessageList};
       %% NewInterval =:= 0 ->
       %%      do_send_message(Unique, Module, Method, Record),
       %%      ?DEBUG("~ts,Record=~w",["持续间隔时间消息发送最后一次发送消息处理",Record]),
       %%      NewMsgList = proplists:delete(Key, MessageList),
       %%      State#state{message_list = NewMsgList};
       true ->
            ?DEBUG("~ts,Record=~w",["持续间隔时间消息发送，已经不需要发送",Record]),
            NewMsgList1 = proplists:delete(Key, MessageList),
            State#state{message_list = NewMsgList1}
    end.

%% 发送消息处理
do_send_message(_Unique, Module, _Method, Record) ->
    Type = Record#m_broadcast_admin_tos.type,
    SubType = if Type =:= ?BC_MSG_TYPE_CHAT ->
                      ?BC_MSG_TYPE_CHAT_WORLD;
                 true ->
                      ?BC_MSG_SUB_TYPE
              end,
    Content = Record#m_broadcast_admin_tos.content,
    Message = #m_broadcast_general_toc{type = [Type], sub_type = SubType, 
                                          content = Content },
    ?DEBUG("~ts,Message=~w",["发送的消息为：",Message]),
    common_misc:chat_broadcast_to_world(Module, ?BROADCAST_GENERAL, Message).


do_admin_message_error(_Unique, _Module, _Method, Record, Reason, State) ->
    ?DEBUG("~ts,Reason=~w,Record=~w",["此后台广播消息不合法",Reason,Record]),
    State.

%% 循环发送消息时间
cycle_send_admin_message(Key, State) ->
    #state{message_list = MessageList} = State,
    case proplists:lookup(Key, MessageList) of 
        none ->
            %% 消息已经被删除
            ?DEBUG("~ts",["此循环发送的后台消息已经被删除，不需要处理"]),
            State;
        {_, MessageRecord} ->
            #r_broadcast_admin_msg{msg_record = Record, unique = Unique , module = Module, method = Method} = MessageRecord,
            cycle_send_admin_message2(Key,Unique,Module,Method,Record,State)
    end.
cycle_send_admin_message2(Key,Unique,Module,Method,Record,State) ->
    #state{message_list = MessageList} = State,
    SendStrategy = Record#m_broadcast_admin_tos.send_strategy,
    NewMessageList = proplists:delete(Key, MessageList),
    NewState = State#state{message_list = NewMessageList},
    do_admin_message7(SendStrategy, Key, Unique, Module, Method, Record, NewState).

%% 更新消息处理
update_send_admin_message(Record,State) ->
    SendStrategy = Record#m_broadcast_admin_tos.send_strategy,
    if SendStrategy =:= 0 ->
            self() ! {?DEFAULT_UNIQUE, ?BROADCAST, ?BROADCAST_ADMIN, Record},
            State;
       true ->
            update_send_admin_message2(Record,State)
    end.
update_send_admin_message2(Record,State) ->
    #state{message_list = MessageList} = State,
    Key = Record#m_broadcast_admin_tos.id,
    case proplists:lookup(Key, MessageList) of 
        none ->
            %% 消息已经被删除
            ?DEBUG("~ts",["此循环发送的后台消息已经被删除，不需要处理"]),
            %% self() ! {?DEFAULT_UNIQUE, ?BROADCAST, ?BROADCAST_ADMIN, Record},
            State;
        {_, MessageRecord} ->
            update_send_admin_message3(Record,State,MessageRecord)
    end.
update_send_admin_message3(Record,State,MessageRecord) ->
    #state{message_list = MessageList} = State,
    Key = Record#m_broadcast_admin_tos.id,
    #r_broadcast_admin_msg{timer_ref = TimerRef} = MessageRecord,
    case erlang:cancel_timer(TimerRef) of
        false ->
            ?INFO_MSG("~ts,TimerRef=~w,Id=~w,MessageRecord=~w",["更新消息广播时取消不了以前的消息广播定时器",TimerRef,Key,MessageRecord]),
            self() ! {update_admin_message,Record},
            State;
        _Time ->       
            MessageList2 = proplists:delete(Key,MessageList),
            NewState = State#state{message_list = MessageList2},
            self() ! {?DEFAULT_UNIQUE, ?BROADCAST, ?BROADCAST_ADMIN, Record},
            NewState
    end.
%% 删除消息处理
delete_send_admin_message(DeleteIdList,State) ->
    #state{message_list = MessageList} = State,
    ?DEBUG("~ts,MessageList=~w",["此进程的消息广播记录有",MessageList]),
    MessageList2 = 
        lists:foldl(fun(Key,Acc) ->
                            case proplists:lookup(Key, Acc) of 
                                none ->
                                    ?DEBUG("~ts,Id=~w",["此删除的消息广播记录不在此进程处理",Key]),
                                    Acc;
                                {_,MessageRecord} ->
                                    
                                    #r_broadcast_admin_msg{timer_ref = TimerRef} = MessageRecord,
                                    case erlang:cancel_timer(TimerRef) of
                                        false ->
                                            ?DEBUG("~ts,Id=~w",["删除的消息广播失败",Key]),
                                            Acc;
                                        _Time ->
                                            ?DEBUG("~ts,Id=~w",["删除的消息广播成功",Key]),
                                            proplists:delete(Key,Acc)
                                    end
                            end
                    end, MessageList,DeleteIdList),
    ?DEBUG("~ts,NewMessageList=~w",["此进程的消息广播记录有",MessageList2]),
    State#state{message_list = MessageList2}.

%% 获取游戏开服日期
%% TODO 需要确认从那个配置文件中读取
get_open_service_days(GamesOpenDate) ->
    ?DEBUG("~ts,GamesOpenDate=~w",["游戏开服日期是：",GamesOpenDate]),
    case GamesOpenDate of
        error ->
            calendar:date_to_gregorian_days(date());
        _ ->
            case check_date_string(GamesOpenDate) of
                false ->
                    calendar:date_to_gregorian_days(date());
                true ->
                    get_date_for_string(GamesOpenDate)
            end
    end.

%% 计算两个时间相差多少秒
calc_diff_seconds(DateDays1,TimeSeconds1,DateDays2,TimeSeconds2) ->
    Date1 = calendar:gregorian_days_to_date(DateDays1),
    Time1 = calendar:seconds_to_time(TimeSeconds1),
    Date2 = calendar:gregorian_days_to_date(DateDays2),
    Time2 = calendar:seconds_to_time(TimeSeconds2),
    Seconds1 = calendar:datetime_to_gregorian_seconds({Date1, Time1}),
    Seconds2 = calendar:datetime_to_gregorian_seconds({Date2, Time2}),
    Seconds3 = Seconds2 - Seconds1,
    if Seconds3 > 4294966 ->
            4294966;
       true ->
            Seconds3
    end.

%% 将 yyyy-MM-dd的日期格式转换成erlang date days类型
get_date_for_string(DateStr) ->
    DateList = string:tokens(DateStr, "-"),
    ?DEBUG("~ts,DataStr=~w,DateList=~w",["分析日期",DateStr,DateList]),
    NewDateList = [erlang:list_to_integer(Key,10) || Key <- DateList],
    calendar:date_to_gregorian_days(lists:nth(1,NewDateList), 
                                    lists:nth(2,NewDateList), 
                                    lists:nth(3,NewDateList)).
%% 获取时间
get_time_for_string(TimeStr) ->
    TimeList = string:tokens(TimeStr, ":"),
    ?DEBUG("~ts,TimeStr=~w,TimeList=~w",["分析时间",TimeStr,TimeList]),
    NewTimeList = [erlang:list_to_integer(Key,10) || Key <- TimeList],
    H = lists:nth(1,NewTimeList),
    M = lists:nth(2,NewTimeList),
    S = lists:nth(3,NewTimeList),
    calendar:time_to_seconds({H,M,S}).
%% 检查日期是否合法
check_date_string(DateStr) ->
    DateList = string:tokens(DateStr, "-"),
    ?DEBUG("~ts,DataStr=~w,DateList=~w",["检查时，分析日期",DateStr,DateList]),
    NewDateList = [erlang:list_to_integer(Key,10) || Key <- DateList],
    calendar:valid_date(lists:nth(1,NewDateList),
                        lists:nth(2,NewDateList), lists:nth(3,NewDateList)).
%% 检查时间是否合法
check_time_string(TimeStr) ->
    TimeList = string:tokens(TimeStr, ":"),
    ?DEBUG("~ts,TimeStr=~w,TimeList=~w",["检查时，分析时间",TimeStr,TimeList]),
    NewTimeList = [erlang:list_to_integer(Key,10) || Key <- TimeList],
    HH = lists:nth(1,NewTimeList),
    MM = lists:nth(2,NewTimeList),
    SS = lists:nth(3,NewTimeList),
    if HH >= 0 andalso HH < 24 
       andalso MM >= 0 andalso MM < 60
       andalso SS >= 0 andalso SS < 60 ->
            true;
       true ->
            false
    end.
