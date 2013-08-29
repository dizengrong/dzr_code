%%%-------------------------------------------------------------------
%%% @author  caochuncheng
%%% @copyright mcsd (C) 2010, 
%%% @doc
%%% 消息广播接口服务
%%% @end
%%% Created : 12 Jul 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_broadcast_server).

-behaviour(gen_server).

%% Include files
-include("mgeew.hrl").
-include("broadcast.hrl").

%% API
-export([start_link/0,
         start/0]).


%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {g_process_list,g_count,
                c_process_list,c_count,
                a_process_list,a_count,
                d_process_list,d_count}).

%%%===================================================================
%%% API
%%%===================================================================
start() ->
    try 
        supervisor:start_child(
          mgeew_sup, 
          {mod_broadcast_sup,
           {mod_broadcast_sup, start_link, []},
           transient, infinity, supervisor, [mod_broadcast_sup]}),
        supervisor:start_child(
          mgeew_sup, 
          {mod_broadcast_server,
           {mod_broadcast_server, start_link, []},
           transient, brutal_kill, worker, [mod_broadcast_server]}),
        ChildSpec = {?MOD_BROADCAST_CYCLE, 
                     {mod_broadcast_cycle,start_link,[?MOD_BROADCAST_CYCLE]},
                     permanent, 2000,worker,?BROADCAST_MODULES},
        supervisor:start_child({mod_broadcast_sup,node()}, ChildSpec)
    catch
        _:Error ->
            ?ERROR_MSG("~ts Error=~p",["初始化消息广播服务出错",Error])
    end,
    ok.
%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({global, ?MOD_BROADCAST_SERVER}, ?MODULE, [], []).

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
    State = init_process(),
    %% 初始化后台消息广播数据
    init_broadcast_admin_data(),
    ?DEBUG("~ts,State=~w",["启动消息广播服务成功",State]),
    %% 启动之后2分钟执行后台消息广播处理
    erlang:send_after(20000, self(), {init_broadcast_admin_message}),
    {ok, State}.

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
handle_call(Request, From, State) ->
    ?DEBUG("~ts,Request=~w,From=~w,State=~w",["接收到的Call数据为", Request, From, State]),
    do_handle_call(Request, From, State).

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
    NewState = 
        try
            do_handle_info(Info, State)
        catch
            T:R ->
                ?ERROR_MSG("module: ~w, line: ~w, Info:~w, type: ~w, reason: ~w,stactraceo: ~w",
                           [?MODULE, ?LINE, Info, T, R, erlang:get_stacktrace()]),
                State
        end,
    {noreply, NewState}.

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
%% 初始化消息广播服务
init_process() ->
    init_process2().
init_process2() ->
    State = #state{g_process_list = [], g_count = 0, 
                   c_process_list = [], c_count = 0, 
                   a_process_list = [],a_count = 0,
                   d_process_list = [],d_count = 0},
    init_process3(State).
init_process3(State) ->    
    GeneralProcessCount = get_msg_general_process_count(),
    SeqList = lists:seq(1, GeneralProcessCount, 1),
    PidList = 
        lists:map(fun(Index) -> 
                          ProcessName = get_broadcast_process_name({general, Index}),
                          ProcessState = {ProcessName},
                          ChildSpec = {ProcessName, {mod_broadcast_general,start_link,[ProcessState]},
                                       permanent, 2000,worker,?BROADCAST_MODULES},
                          case supervisor:start_child({mod_broadcast_sup,node()}, ChildSpec) of
                              {ok, Pid} ->
                                  ?DEBUG("~ts,Index=~w",["初始化进程创建一般消息广播处理进程成功",Index]),
                                  Pid;
                              R ->
                                  ?ERROR_MSG("~ts,Index=~w,Reason=~w",["初始化进程创建一般消息广播处理进程失败",Index,R]),
                                  R
                          end
                  end,SeqList),
    PidList2 = [P || P <- PidList, erlang:is_pid(P)],
    NewState = State#state{g_process_list = PidList2, g_count = GeneralProcessCount},
    init_process4(NewState).
init_process4(State) ->
    CountdownProcessCount = get_msg_countdown_process_count(),
    SeqList = lists:seq(1, CountdownProcessCount, 1),
    PidList = 
        lists:map(fun(Index) -> 
                          ProcessName = get_broadcast_process_name({countdown, Index}),
                          ProcessState = {ProcessName},
                          ChildSpec = {ProcessName, {mod_broadcast_countdown,start_link,[ProcessState]},
                                       permanent, 2000,worker,?BROADCAST_MODULES},
                          case supervisor:start_child({mod_broadcast_sup,node()}, ChildSpec) of
                              {ok, Pid} ->
                                  ?DEBUG("~ts,Index=~w",["初始化进程创建倒计时消息广播处理进程成功",Index]),
                                  Pid;
                              R ->
                                  ?ERROR_MSG("~ts,Index=~w,Reason=~w",["初始化进程创建倒计时消息广播处理进程失败",Index,R]),
                                  R
                          end
                  end,SeqList),
    PidList2 = [P || P <- PidList, erlang:is_pid(P)],
    NewState = State#state{c_process_list = PidList2, c_count = CountdownProcessCount},
    init_process5(NewState).
init_process5(State) ->
    DeleteProcessCount = get_msg_delete_process_count(),
    SeqList = lists:seq(1, DeleteProcessCount, 1),
    PidList = 
        lists:map(fun(Index) -> 
                          ProcessName = get_broadcast_process_name({delete, Index}),
                          ProcessState = {ProcessName},
                          ChildSpec = {ProcessName,{mod_broadcast_delete,start_link,[ProcessState]},
                                       permanent, 2000,worker,?BROADCAST_MODULES},
                          case supervisor:start_child({mod_broadcast_sup,node()}, ChildSpec) of
                              {ok, Pid} ->
                                  ?DEBUG("~ts,Index=~w",["初始化进程创建删除已经发送消息广播处理进程成功",Index]),
                                  Pid;
                              R ->
                                  ?ERROR_MSG("~ts,Index=~w,Reason=~w",["初始化进程创建删除已经发关送消息广播处理进程失败",Index,R]),
                                  R
                          end
                  end,SeqList),
    PidList2 = [P || P <- PidList, erlang:is_pid(P)],
    NewState = State#state{d_process_list = PidList2, d_count = DeleteProcessCount},
    init_process6(NewState).
init_process6(State) ->
    AdminProcessCount = get_msg_admin_process_count(),
    SeqList = lists:seq(1, AdminProcessCount, 1),
    PidList = 
        lists:map(fun(Index) -> 
                          ProcessName = get_broadcast_process_name({admin, Index}),
                          ProcessState = {ProcessName},
                          ChildSpec = {ProcessName, {mod_broadcast_admin,start_link,[ProcessState]},
                                       permanent, 2000,worker,?BROADCAST_MODULES},
                          case supervisor:start_child({mod_broadcast_sup,node()}, ChildSpec) of
                              {ok, Pid} ->
                                  ?DEBUG("~ts,Index=~w",["初始化进程创建后台消息广播处理进程成功",Index]),
                                  Pid;
                              R ->
                                  ?ERROR_MSG("~ts,Index=~w,Reason=~w",["初始化进程创建后台消息广播处理进程失败",Index,R]),
                                  R
                          end
                  end,SeqList),
    PidList2 = [P || P <- PidList, erlang:is_pid(P)],
    State#state{a_process_list = PidList2, a_count = AdminProcessCount}.

%% 初始化后台消息广播数据
init_broadcast_admin_data() ->
    BroadcastAdminFile = common_config:get_world_config_file_path(broadcast_admin),
    case file:consult(BroadcastAdminFile) of
        {ok,AdminMessageList} ->
            init_broadcast_admin_data2(AdminMessageList);
        Error ->
            ?INFO_MSG("~ts,BroadcastAdminFile=~w,Error=~w",["读取后台消息广播初始化消息数据出错",BroadcastAdminFile,Error]),
            ignore
    end.
init_broadcast_admin_data2(AdminMessageList) ->
    case catch db:transaction(
                 fun() ->
                         lists:foreach(
                           fun(AdminRecord) ->
                                   MessageRecord = #r_broadcast_message{
                                     id =AdminRecord#m_broadcast_admin_tos.id,
                                     foreign_id = AdminRecord#m_broadcast_admin_tos.foreign_id,
                                     unique = ?DEFAULT_UNIQUE,
                                     msg_type = ?BROADCAST_ADMIN,
                                     msg_record = AdminRecord,
                                     create_time = common_tool:now(),
                                     expected_time = common_tool:now(),
                                     send_time = 0, %% 最后发送时间
                                     send_times = 0, %% 发送次数
                                     send_flag = 0, %% 消息发送状态 0：新增，1：发送成功，2：发送失败，3：发送中，9：其它错误
                                     send_desc = ""},
                                   db:write(?DB_BROADCAST_MESSAGE, MessageRecord, write)
                           end,AdminMessageList)
                 end ) of
        {atomic, ok} ->
            ok;
        {aborted,Error} ->
            ?ERROR_MSG("~ts Error =~w",["初始化后台消息广播消息数据进出错",Error]),
            error
    end.
    

%% 处理CALL请求
do_handle_call({?BROADCAST_ADMIN,DataRecord}, _From, State) ->
    Reply = mod_broadcast_admin_db:do_handle_call(DataRecord),
    {reply, Reply, State};
do_handle_call(Request, _From, State) ->
    ?ERROR_MSG("~ts,Request=~w",["无法处理CALL此消息",Request]),
    Reply = error,
    {reply, Reply, State}.

%% 处理广播消息
%%一般的消息广播
%% 后台消息广播 重新重新注册消息广播处理进程
do_handle_info({update_send_message_pid},State)->
    do_update_send_message_pid(State);

do_handle_info({Unique, ?BROADCAST, ?BROADCAST_GENERAL, DataRecord}, State) ->
    do_broadcast_general(Unique, ?BROADCAST, ?BROADCAST_GENERAL, DataRecord, State),
    State;

%% 倒计时消息广播
do_handle_info({Unique, ?BROADCAST, ?BROADCAST_COUNTDOWN, DataRecord}, State) ->
    do_broadcast_countdown(Unique, ?BROADCAST, ?BROADCAST_COUNTDOWN, DataRecord, State),
    State;

%% 后台消息广播
do_handle_info({Unique, ?BROADCAST, ?BROADCAST_ADMIN, DataRecord}, State) ->
    do_broadcast_admin(Unique, ?BROADCAST, ?BROADCAST_ADMIN, DataRecord, State),
    State;
%% 更新后台消息广播
do_handle_info({update_broadcast_admin_message, DataRecord}, State)
  when erlang:is_record(DataRecord,m_broadcast_admin_tos)->
    do_update_broadcast_admin_message(DataRecord,State),
    State;
%% 删除后台消息广播
do_handle_info({delete_broadcast_admin_message, DeleteIdList}, State)
  when erlang:is_list(DeleteIdList) ->
    do_delete_broadcast_admin_message(DeleteIdList,State),
    State;
%% 初始化后台消息广播处理
do_handle_info({init_broadcast_admin_message}, State) ->
    do_init_broadcast_admin_message(State),
    State;
do_handle_info({init_broadcast_admin_message_one,DataRecord}, State)
  when erlang:is_record(DataRecord,m_broadcast_admin_tos) ->
    do_init_broadcast_admin_message_one(DataRecord,State),
    State;

%% 循环消息广播处理
do_handle_info({Unique, ?BROADCAST, ?BROADCAST_CYCLE, DataRecord}, State)
  when erlang:is_record(DataRecord,m_broadcast_cycle_tos)->
    do_broadcast_cycle({Unique, ?BROADCAST, ?BROADCAST_CYCLE, DataRecord},State),
    State;

%% 添加外部操作本进程内部执行接口
do_handle_info({func, Fun, Args}, State) ->
    Ret = (catch apply(Fun,Args)),
    ?ERROR_MSG("~w",[Ret]),
    State;

do_handle_info(Info, State) ->
    ?ERROR_MSG("~ts, Info=~w",["无法处理此消息",Info]),
    State.
%% 消息处理进程重起，重新注册pid
do_update_send_message_pid(State) ->
    ?ERROR_MSG("~ts,State=~w",["人工更新操作之前消息广播模块进程State情况为：",State]),
    DeleteProcessCount = get_msg_delete_process_count(),
    GeneralProcessCount = get_msg_general_process_count(),
    AdminProcessCount = get_msg_admin_process_count(),
    CountdownProcessCount = get_msg_countdown_process_count(),
    DSeqList = lists:seq(1, DeleteProcessCount, 1),
    GSeqList = lists:seq(1, GeneralProcessCount, 1),
    CSeqList = lists:seq(1, CountdownProcessCount, 1),
    ASeqList = lists:seq(1, AdminProcessCount, 1),
    DPidList = 
        lists:foldl(
          fun(DIndex,DPList) ->
                  DProcessName = get_broadcast_process_name({delete,DIndex}),
                  DAProcessName = common_tool:list_to_atom(DProcessName),
                  case erlang:whereis(DAProcessName) of
                      undefined ->
                          DPList;
                      DPid when erlang:is_pid(DPid) ->
                          [DPid|DPList];
                      _ ->
                          DPList
                  end
          end,[],DSeqList),
    GPidList = 
        lists:foldl(
          fun(GIndex,GPList) ->
                  GProcessName = get_broadcast_process_name({general,GIndex}),
                  GAProcessName = common_tool:list_to_atom(GProcessName),
                  case erlang:whereis(GAProcessName) of
                      undefined ->
                          GPList;
                      GPid when erlang:is_pid(GPid) ->
                          [GPid|GPList];
                      _ ->
                          GPList
                  end
          end,[],GSeqList),
    CPidList = 
        lists:foldl(
          fun(CIndex,CPList) ->
                  CProcessName = get_broadcast_process_name({countdown,CIndex}),
                  CAProcessName = common_tool:list_to_atom(CProcessName),
                  case erlang:whereis(CAProcessName) of
                      undefined ->
                          CPList;
                      CPid when erlang:is_pid(CPid) ->
                          [CPid|CPList];
                      _ ->
                          CPList
                  end
          end,[],CSeqList),
    APidList = 
        lists:foldl(
          fun(AIndex,APList) -> 
                  AProcessName = get_broadcast_process_name({admin, AIndex}),
                  AAProcessName = common_tool:list_to_atom(AProcessName),
                  case erlang:whereis(AAProcessName) of
                      undefined ->
                          APList;
                      APid when erlang:is_pid(APid) ->
                          [APid|APList];
                      _ ->
                          APList
                  end
          end,[],ASeqList),
    NewState =  State#state{
                  g_process_list = GPidList, g_count = erlang:length(GPidList), 
                  c_process_list = CPidList, c_count = erlang:length(CPidList), 
                  a_process_list = APidList,a_count = erlang:length(APidList),
                  d_process_list = DPidList,d_count = erlang:length(DPidList)
                 },
    ?ERROR_MSG("~ts,NewState=~w",["人工更新操作之后消息广播模块进程State情况为：",NewState]),
    NewState.
    

%%一般的消息广播
do_broadcast_general(Unique, Module, Method, DataRecord, State) ->
    case erlang:is_record(DataRecord, m_broadcast_general_tos) of
        true ->
            do_broadcast_general2(Unique, Module, Method, DataRecord, State);
        false ->
            Reason = ?_LANG_BROADCAST_MESSAGE_RECORD_ERROR,
            do_broadcast_general_error(Unique, Module, Method, Reason, DataRecord, State)
    end.
do_broadcast_general2(Unique, Module, Method, DataRecord, State) ->
    #state{g_process_list = GProcessList,g_count = GProcessCount} = State,
    RandomNumber = random:uniform(GProcessCount),
    RandomPid = lists:nth(RandomNumber, GProcessList),
    erlang:send(RandomPid,{Unique, Module, Method, DataRecord}).

do_broadcast_general_error(Unique, Module, Method, Reason, DataRecord, _State) ->
    %% 不合法的消息结构，只记录错误的日志信息，不需要其它处理
    ?DEBUG("~ts,Reason=~w,Unique=~w,Module=~w,Method=~w,DataRecord=~w",["一般消息广播出错",Unique, Module, Method, Reason, DataRecord]),
    ok.

%% 倒计时消息广播
do_broadcast_countdown(Unique, Module, Method, DataRecord, State) ->
    case erlang:is_record(DataRecord, m_broadcast_countdown_tos) of
        true ->
            do_broadcast_countdown2(Unique, Module, Method, DataRecord, State);
        false ->
            Reason = ?_LANG_BROADCAST_MESSAGE_RECORD_ERROR,
           do_broadcast_countdown_error(Unique, Module, Method, Reason, DataRecord, State)
    end.
do_broadcast_countdown2(Unique, Module, Method, DataRecord, State) ->
    {MegaSecs, Secs, MicroSecs} = erlang:now(),
    Id = (MegaSecs * 1000000 + Secs) * 1000000 + MicroSecs,
    RecordId = DataRecord#m_broadcast_countdown_tos.id,
    NewDataRecord = if RecordId =:= 0 ->
                            DataRecord#m_broadcast_countdown_tos{id = Id};
                       true ->
                            DataRecord
                    end,
    Record = #r_broadcast_message{id = Id,unique = Unique,msg_type = Method,
                                  msg_record = NewDataRecord,
                                  create_time = common_tool:now(),
                                  expected_time = common_tool:now(),
                                  send_time = 0, %% 最后发送时间
                                  send_times = 0, %% 发送次数
                                  send_flag = 0, %% 消息发送状态 0：新增，1：发送成功，2：发送失败，3：发送中，9：其它错误
                                  send_desc = ""},
    t_insert_broadcast_message_record(Record),
    do_broadcast_countdown3(Unique, Module, Method, NewDataRecord, Id, State).

do_broadcast_countdown3(Unique, Module, Method, DataRecord,Key, State) ->
    #state{c_process_list = CProcessList,c_count = CProcessCount} = State,
    RandomNumber = random:uniform(CProcessCount),
    RandomPid = lists:nth(RandomNumber, CProcessList),
    erlang:send(RandomPid,{Key, Unique, Module, Method, DataRecord}).

do_broadcast_countdown_error(Unique, Module, Method, Reason, DataRecord, _State) ->
    %% 不合法的消息结构，只记录错误的日志信息，不需要其它处理
    ?DEBUG("~ts,Reason=~w,Unique=~w,Module=~w,Method=~w,DataRecord=~w",["倒计时消息广播出错",Unique, Module, Method, Reason, DataRecord]),
    ok.

%% 后台消息广播
do_broadcast_admin(Unique, Module, Method, DataRecord, State) ->
    if erlang:is_list(DataRecord) ->
            do_broadcast_admin2(Unique, Module, Method, DataRecord, State);
       erlang:is_record(DataRecord, m_broadcast_admin_tos) ->
            do_broadcast_admin2(Unique, Module, Method, [DataRecord], State);
       true ->
            Reason = ?_LANG_BROADCAST_MESSAGE_RECORD_ERROR,
            do_broadcast_admin_error(Unique, Module, Method, Reason, DataRecord, State)
    end.

do_broadcast_admin2(Unique, Module, Method, DataRecord, State) 
  when erlang:is_list(DataRecord)->
    RecordList = [R || R <- DataRecord,
                       erlang:is_record(R,m_broadcast_admin_tos)],
    if erlang:length(RecordList) =:= erlang:length(DataRecord)  ->
            do_broadcast_admin3(Unique, Module, Method, DataRecord, State);
       true ->
            Reason = ?_LANG_BROADCAST_MESSAGE_RECORD_ERROR,
            do_broadcast_admin_error(Unique, Module, Method, Reason, DataRecord, State)
    end;
do_broadcast_admin2(Unique, Module, Method, DataRecord, State) ->
    Reason = ?_LANG_BROADCAST_MESSAGE_RECORD_ERROR,
    do_broadcast_admin_error(Unique, Module, Method, Reason, DataRecord, State).

do_broadcast_admin3(Unique, Module, Method, DataRecord, State) ->
    #state{a_process_list = AProcessList,a_count = AProcessCount} = State,
    lists:foreach(fun(Record) ->
                          RandomNumber = random:uniform(AProcessCount),
                          RandomPid = lists:nth(RandomNumber, AProcessList),
                          erlang:send(RandomPid,{Unique, Module, Method, Record})
                  end,DataRecord).

do_broadcast_admin_error(Unique, Module, Method, Reason, DataRecord, _State) ->
    %% 不合法的消息结构，只记录错误的日志信息，不需要其它处理
    ?DEBUG("~ts,Reason=~w,Unique=~w,Module=~w,Method=~w,DataRecord=~w",["后台消息广播出错",Reason, Unique, Module, Method, DataRecord]),
    ok.
%% 更新后台消息广播消息处理
do_update_broadcast_admin_message(DataRecord,State) ->
    #state{a_process_list = AProcessList,a_count = AProcessCount} = State,
    SendStrategy = DataRecord#m_broadcast_admin_tos.send_strategy,
    if SendStrategy =:= 0 ->
            RandomNumber = random:uniform(AProcessCount),
            RandomPid = lists:nth(RandomNumber, AProcessList),
            erlang:send(RandomPid,{update_admin_message, DataRecord});
       true ->
            lists:foreach(fun(Pid) ->
                                  erlang:send(Pid,{update_admin_message, DataRecord})
                          end,AProcessList)
    end.
%% 删除后台消息广播消息处理
do_delete_broadcast_admin_message(DeleteIdList,State) ->
    #state{a_process_list = AProcessList} = State,
    lists:foreach(fun(Pid) ->
                          erlang:send(Pid,{delete_admin_message, DeleteIdList})
                  end,AProcessList).
%% 初始化后台消息广播
do_init_broadcast_admin_message(_State) ->
    AdminMessageList = mod_broadcast_admin_db:get_broadcast_admin_message_list(),
    lists:foreach(
      fun(DataRecord) ->
              Interval = DataRecord#m_broadcast_admin_tos.interval,
              erlang:send_after(Interval * 1000, self(), {init_broadcast_admin_message_one,DataRecord})
      end,AdminMessageList).
do_init_broadcast_admin_message_one(DataRecord,State) ->
    do_broadcast_admin2(?DEFAULT_UNIQUE, ?BROADCAST, ?BROADCAST_ADMIN, [DataRecord], State).

%% 循环消息广播
do_broadcast_cycle({Unique, Module, Method, DataRecord},_State) ->
    RegName = common_tool:list_to_atom(?MOD_BROADCAST_CYCLE),
    erlang:send(RegName,{Unique, Module, Method, DataRecord}).

%% 获取消息广播进程名称
get_broadcast_process_name({general, Index}) ->
    lists:concat([broadcast_general_, Index]);

get_broadcast_process_name({countdown, Index}) ->
    lists:concat([broadcast_countdown_, Index]);

get_broadcast_process_name({admin, Index}) ->
    lists:concat([broadcast_admin_, Index]);

get_broadcast_process_name({delete, Index}) ->
    lists:concat([broadcast_delete_, Index]).
%% 获取进行一般消息广播进程数
get_msg_general_process_count() ->
    case common_config_dyn:find(broadcast,msg_general_process_count) of
        [GeneralProcessCount] -> GeneralProcessCount;
        _ -> ?DEFAULT_MSG_GENERAL_PROCESS_COUNT
    end.
%% 获取进行倒计时消息广播进程数
get_msg_countdown_process_count() ->
    case common_config_dyn:find(broadcast,msg_countdown_process_count) of
        [CountdownProcessCount] -> CountdownProcessCount;
        _ -> ?DEFAULT_MSG_COUNTDOWN_PROCESS_COUNT
    end.

%% 获取进行后台管理消息广播进程数
get_msg_admin_process_count() ->
    case common_config_dyn:find(broadcast,msg_admin_process_count) of
        [AdminProcessCount] -> AdminProcessCount;
        _ -> ?DEFAULT_MSG_ADMIN_PROCESS_COUNT
    end.
get_msg_delete_process_count() ->
    case common_config_dyn:find(broadcast,msg_delete_process_count)  of
        [DeleteProcessCount] -> DeleteProcessCount;
        _ -> ?DEFAULT_MSG_DELETE_PROCESS_COUNT
    end.

%% 将需要持久化的消息插入数据库
t_insert_broadcast_message_record(Record) ->
    case catch db:transaction(fun() ->  insert_broadcast_message_record(Record)  end) of
        {atomic, ok} ->
            ok;
        R ->
            ?ERROR_MSG("~ts ~w",["新增广播消息出错",R]),
            error
    end.
insert_broadcast_message_record(Record) ->
     db:write(?DB_BROADCAST_MESSAGE, Record, write).

