%%%-------------------------------------------------------------------
%%% @author  caochuncheng
%%% @copyright mcsd (C) 2010, 
%%% @doc
%%% 消息广播处理：倒计时消息处理
%%% @end
%%% Created : 12 Jul 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_broadcast_countdown).

-behaviour(gen_server).

%% Include files
-include("mgeew.hrl").
-include("broadcast.hrl").

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {sync_times, message_list}).

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
    SyncTimes = get_msg_countdown_sync_times(),
    {ok, #state{sync_times = SyncTimes, message_list = []}}.

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
    ?DEBUG("~ts,Info=~w",["接收到的消息为",Info]),
    NewState = do_handle_info(Info, State),
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
terminate(Reason, State) ->
    do_terminate(Reason,State),
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


do_handle_info({Key, Unique, Module, Method, DataRecord}, State) ->
    do_countdown_message({Key, Unique, Module, Method, DataRecord, State});
do_handle_info({sync_countdown_message,Key},State) ->
    do_countdown_sync_message(Key, State);

%% 添加外部操作本进程内部执行接口
do_handle_info({func, Fun, Args}, State) ->
    Ret =(catch  apply(Fun,Args)),
    ?ERROR_MSG("~w",[Ret]),
    State;

do_handle_info(Info, State) ->
    ?ERROR_MSG("~ts,Info=~w",["无法处理此消息",Info]),
    State.


do_countdown_message({Key, Unique, Module, Method, DataRecord, State}) ->
    Type = DataRecord#m_broadcast_countdown_tos.type,
    if Type =:= ?BC_MSG_TYPE_COUNTDOWN ->
            SubType = DataRecord#m_broadcast_countdown_tos.sub_type,
            do_countdown_message2({SubType, Key, Unique, Module, Method, DataRecord, State});
       true ->
            ?DEBUG("~ts,DataRecord=~w",["倒计时消息类型出错",DataRecord]),
            Reason = <<"倒计时消息类型出错">>,
            do_countdown_message_error(Key, Reason, State)
    end.

do_countdown_message2({?BC_MSG_TYPE_COUNTDOWN_DUNGEON, Key, Unique, Module, Method, DataRecord, State}) ->
    StartTime = common_tool:now(),
    do_countdown_message3({Key, Unique, Module, Method, DataRecord, StartTime, State});
do_countdown_message2({?BC_MSG_TYPE_COUNTDOWN_TASK, Key, Unique, Module, Method, DataRecord, State}) ->
    StartTime = common_tool:now(),
    do_countdown_message3({Key, Unique, Module, Method, DataRecord, StartTime, State});
do_countdown_message2(Info) ->
    {_SubType, Key, _Unique, _Module, _Method, _DataRecord, State} = Info,
    ?DEBUG("~ts,Info=~w",["倒计时消息子类型出错", Info]),
    Reason = <<"倒计时消息子类型出错">>,
    do_countdown_message_error(Key, Reason, State).
    

%% 倒计时消息广播
do_countdown_message3({Key, Unique, Module, Method, DataRecord, StartTime, State}) ->
    RoleIdList = DataRecord#m_broadcast_countdown_tos.role_list,
    if RoleIdList =/= [] andalso erlang:length(RoleIdList) > 0 ->
            do_send_message({role_list, Unique, Module, Method, DataRecord, RoleIdList}),
            do_countdown_message_succ({Key, Unique, Module, Method, DataRecord, StartTime, State});
       true ->
            do_countdown_message4({Key, Unique, Module, Method, DataRecord, StartTime, State})
    end.
do_countdown_message4({Key, Unique, Module, Method, DataRecord, StartTime, State}) ->
    if DataRecord#m_broadcast_countdown_tos.is_world ->
            do_send_message({world, Unique, Module, Method, DataRecord, 0}),
            do_countdown_message_succ({Key, Unique, Module, Method, DataRecord, StartTime, State});
       true ->
            do_countdown_message5({Key, Unique, Module, Method, DataRecord, StartTime, State})
    end.
do_countdown_message5({Key, Unique, Module, Method, DataRecord, StartTime, State}) ->
    CountryId = DataRecord#m_broadcast_countdown_tos.country_id,
    if CountryId =/= 0 ->
            do_send_message({country, Unique, Module, Method, DataRecord, CountryId}),
            do_countdown_message_succ({Key, Unique, Module, Method, DataRecord, StartTime, State});
       true ->
            do_countdown_message6({Key, Unique, Module, Method, DataRecord,StartTime, State})
    end.
do_countdown_message6({Key, Unique, Module, Method, DataRecord, StartTime, State}) ->
    FamliyId = DataRecord#m_broadcast_countdown_tos.famliy_id,
    if FamliyId =/= 0 ->
            do_send_message({famliy, Unique, Module, Method, DataRecord,FamliyId}),
            do_countdown_message_succ({Key, Unique, Module, Method, DataRecord, StartTime, State});
       true ->
            do_countdown_message7({Key, Unique, Module, Method, DataRecord,StartTime, State})
    end.

do_countdown_message7({Key, Unique, Module, Method, DataRecord, StartTime, State}) ->
    TeamId = DataRecord#m_broadcast_countdown_tos.team_id,
    if TeamId =/= 0 ->
            do_send_message({team,Unique, Module, Method, DataRecord, TeamId}),
            do_countdown_message_succ({Key, Unique, Module, Method, DataRecord, StartTime, State});
       true ->
            ?DEBUG("~ts,DataRecord=~w",["无法处理此倒计时消息",DataRecord]),
            State
    end.


do_countdown_message_error(Key, Reason, State) ->
    SendTime = common_tool:now(),
    SendTimes = 0,
    SendFlag = 2,
    SendDesc = Reason,
    dirty_update_broadcast_message(Key, SendTime, SendTimes, SendFlag, SendDesc),
    State.
    
do_countdown_message_succ({Key, Unique, Module, Method, DataRecord, StartTime, State}) ->
    #state{sync_times = SyncTimes, message_list = MessageList} = State,
    case proplists:lookup(Key,MessageList) of
        none ->
            %% 第一次消息发送处理
            CountDownTime = DataRecord#m_broadcast_countdown_tos.countdown_time,
            EndTime = get_msg_countdown_end_time(StartTime, CountDownTime),
            IntervalTime = get_msg_countdown_interval_time(CountDownTime, SyncTimes),
            ?DEBUG("~ts,CountDownTime=~w,IntervalTime=~w,SyncTimes=~w,StartTime=~w,EndTime=~w",
                   ["根据倒计时时间长度和设置的同步次数，算出同步时间间隔为单位秒：",
                    CountDownTime,IntervalTime,SyncTimes,StartTime,EndTime]),
            TimeRef = erlang:send_after(IntervalTime, self(), {sync_countdown_message,Key}),
            R = #r_broadcast_countdown_msg{msg_record = DataRecord, interval_time = IntervalTime,
                                           unique = Unique, module = Module, method = Method,
                                           start_time = StartTime, end_time = EndTime, send_times = 1, 
                                           timer_ref = TimeRef},
            NewMessageList = lists:append(MessageList, [{Key,R}]),
            #state{sync_times = SyncTimes, message_list = NewMessageList};
        {_,Record} ->
            %% 同步倒计时时间过程消息，包括处理最后一次消息通知
            do_countdown_message_succ2({Key, Unique, Module, Method, DataRecord, Record,  State})
    end.

do_countdown_message_succ2({Key, Unique, Module, Method, DataRecord, Record,  State}) ->
    #state{sync_times = SyncTimes, message_list = MessageList} = State,
    #r_broadcast_countdown_msg{interval_time = IntervalTime, send_times = SendTimes} = Record,
    if (SyncTimes - SendTimes) > 1 andalso SendTimes < SyncTimes ->
            TimeRef = erlang:send_after(IntervalTime, self(), {sync_countdown_message,Key}),
            NewRecord = Record#r_broadcast_countdown_msg{send_times = SendTimes + 1,timer_ref = TimeRef},
            NewMessageList = lists:map(fun({K,R}) ->
                                               if K =:= Key ->
                                                       {K, NewRecord};
                                                  true ->
                                                       {K, R}
                                               end
                                       end,MessageList),
            #state{sync_times = SyncTimes, message_list = NewMessageList};
       true ->
            do_countdown_message_succ3({Key, Unique, Module, Method, DataRecord, Record,  State})
    end.
do_countdown_message_succ3({Key, Unique, Module, Method, DataRecord, Record,  State}) ->
    #m_broadcast_countdown_tos{current_countdown_time = CurCountdownTime} = DataRecord,
    if CurCountdownTime =< 0 ->
            #r_broadcast_countdown_msg{timer_ref = TimeRef} = Record,
            case erlang:cancel_timer(TimeRef) of
                false ->
                    ?INFO_MSG("~ts,TimeRef=~w",["倒计时消息被提前取消息时，取消定时器下次任务时出错",TimeRef]);
                Time ->
                    ?INFO_MSG("~ts,Time=~w",["倒计时消息被提前取消息时，取消定时器下次任务时成功",Time])
            end,
            do_countdown_message_succ5({Key, Unique, Module, Method, DataRecord, Record,  State});
       true ->
            do_countdown_message_succ4({Key, Unique, Module, Method, DataRecord, Record,  State})
    end.
do_countdown_message_succ4({Key, Unique, Module, Method, DataRecord, Record,  State}) ->
    #state{ message_list = MessageList} = State,
    #r_broadcast_countdown_msg{end_time = EndTime, send_times = SendTimes} = Record,
    NowTime = common_tool:now(),
    if NowTime < EndTime ->
            %% 最后一次通知即发送的时间间隔
            IntervalTime = (EndTime - NowTime) * 1000,
            TimeRef = erlang:send_after(IntervalTime, self(), {sync_countdown_message,Key}),
            NewRecord = Record#r_broadcast_countdown_msg{send_times = SendTimes + 1,timer_ref = TimeRef},
            NewMessageList = lists:map(fun({K,R}) ->
                                               if K =:= Key ->
                                                       {K, NewRecord};
                                                  true ->
                                                       {K, R}
                                               end
                                       end,MessageList),
            State#state{message_list = NewMessageList};
       true ->
            do_countdown_message_succ5({Key, Unique, Module, Method, DataRecord, Record,  State})
    end.
do_countdown_message_succ5({Key, _Unique, _Module, _Method, _DataRecord, Record,  State}) ->
    #state{message_list = MessageList} = State,
    #r_broadcast_countdown_msg{send_times = SendTimes} = Record,
    SendTime = common_tool:now(),
    SendFlag = 1,
    SendDesc = "",
    dirty_update_broadcast_message(Key, SendTime, SendTimes, SendFlag, SendDesc),
    NewMessageList = lists:delete(Key,MessageList),
    ?DEBUG("~ts,Key=~w,SendTimes=~w",["此倒计时广播消息发送的次数为：",Key,SendTimes]),
    State#state{message_list = NewMessageList}.

%% 更新广播消息状态
dirty_update_broadcast_message(Key, SendTime, SendTimes, SendFlag, SendDesc) ->
    Parrten = #r_broadcast_message{id = Key, _ = '_'},
    try
        case db:dirty_match_object(?DB_BROADCAST_MESSAGE,Parrten) of
            [] ->
                ok;
            [Record] when is_record(Record,r_broadcast_message) ->
                R = Record#r_broadcast_message{send_time = SendTime,send_times = SendTimes,send_flag = SendFlag,send_desc = SendDesc},
                db:dirty_write(?DB_BROADCAST_MESSAGE, R)
        end
    catch 
        _:Reason ->
            ?DEBUG("~ts,Reason=~w",["更新广播消息状态出错",Reason])
    end.
        
%% 同步倒计时消息时间
do_countdown_sync_message(Key, State) ->
    #state{message_list = MessageList} = State,
    case proplists:lookup(Key, MessageList) of
        none ->
            %% 此消息已经从发送列表删除，即不需要再次处理
            ignore;
         {Key,Record}->
            #r_broadcast_countdown_msg{msg_record = DataRecord,
                                       unique = Unique, module = Module, method = Method} = Record,
            do_countdown_sync_message2({Key, Unique, Module, Method, DataRecord, Record, State})
    end.

do_countdown_sync_message2({Key, Unique, Module, Method, DataRecord, Record, State}) ->
    #m_broadcast_countdown_tos{countdown_time = CountdownTime} = DataRecord,
    #r_broadcast_countdown_msg{start_time = StartTime} = Record,
    IntervalTime = CountdownTime - (common_tool:now() - StartTime),
    NewDataRecord =  if IntervalTime < 0 ->
                             DataRecord#m_broadcast_countdown_tos{current_countdown_time = 0};
                        true ->
                             DataRecord#m_broadcast_countdown_tos{current_countdown_time = IntervalTime}
                     end,
    do_countdown_sync_message3({Key, Unique, Module, Method, NewDataRecord,StartTime, State}).

do_countdown_sync_message3({Key, Unique, Module, Method, DataRecord, StartTime, State}) ->
    ?DEBUG("~ts,DataRecord=~w",["同步倒计时时间消息",DataRecord]),
    do_countdown_message3({Key, Unique, Module, Method, DataRecord, StartTime, State}).


%% 倒计时消息退出处理处理
do_terminate(Reason, State) ->
    case Reason of
        normal ->
            ?INFO_MSG("[Mod Team] ~ts Reason=~w",["正常的退出不需要处理",Reason]);
        _ ->
            do_terminate2(Reason, State)
    end.
do_terminate2(Reason, State) ->
    #state{message_list = MessageList} = State,
    lists:foreach(fun({K,R}) ->
                          #r_broadcast_countdown_msg{send_times = SendTimes} = R,
                          SendTime = common_tool:now(),
                          SendFlag = 9,
                          SendDesc = ["broadcast countdown process terminate Reason ",Reason] ,
                          dirty_update_broadcast_message(K, SendTime, SendTimes, SendFlag, SendDesc)
                  end,MessageList).

%% 获取倒计时消息同步的次数
get_msg_countdown_sync_times() ->
    case common_config_dyn:find(broadcast, msg_countdown_sync_times) of
        [SyncTimes] -> SyncTimes;
        _ -> ?DEFAULT_MSG_COUNTDOWN_SYNC_TIMES
    end.

%% 计算时间间隔
%% CountDownTime 单位为：秒
get_msg_countdown_interval_time(CountDownTime, SyncTimes) ->
    erlang:trunc((CountDownTime * 1000) / SyncTimes).

%% 计算倒计时结束时间
get_msg_countdown_end_time(StartTime, CountDownTime) ->
    StartTime + CountDownTime.

%% 根据角色列表发送数据到客户端
do_send_message({role_list, Unique, Module, Method, DataRecord, RoleIdList}) ->
    Type = DataRecord#m_broadcast_countdown_tos.type,
    SubType = DataRecord#m_broadcast_countdown_tos.sub_type,
    Content = DataRecord#m_broadcast_countdown_tos.content,
    Id = DataRecord#m_broadcast_countdown_tos.id,
    CountDownTime = DataRecord#m_broadcast_countdown_tos.countdown_time,
    CurrentCountDownTime = DataRecord#m_broadcast_countdown_tos.current_countdown_time,
    Message = #m_broadcast_countdown_toc{type = Type,sub_type = SubType,content = Content,id = Id,
                                         countdown_time = CountDownTime, current_countdown_time = CurrentCountDownTime},
    lists:foreach(fun(RoleId) ->
                          case common_misc:is_role_online(RoleId) of
                              false -> ignore;
                              true ->
                                  Line = common_misc:get_role_line_by_id(RoleId),
                                  common_misc:unicast(Line, RoleId, Unique, Module, Method, Message)
                          end
                  end,RoleIdList);
%% 根据世界频道发送数据到客户端
do_send_message({world, _Unique, Module, Method, DataRecord, _World}) ->
    Type = DataRecord#m_broadcast_countdown_tos.type,
    SubType = DataRecord#m_broadcast_countdown_tos.sub_type,
    Content = DataRecord#m_broadcast_countdown_tos.content,
    Id = DataRecord#m_broadcast_countdown_tos.id,
    CountDownTime = DataRecord#m_broadcast_countdown_tos.countdown_time,
    CurrentCountDownTime = DataRecord#m_broadcast_countdown_tos.current_countdown_time,
    Message = #m_broadcast_countdown_toc{type = Type,sub_type = SubType,content = Content,id = Id,
                                         countdown_time = CountDownTime, current_countdown_time = CurrentCountDownTime},
    ?DEBUG("~ts,Message=~w",["接收世界广播消息为：",Message]),
    common_misc:chat_broadcast_to_world(Module, Method, Message);
%% 根据国家频道发送数据到客户端
do_send_message({country, _Unique, Module, Method, DataRecord, CountryId}) ->
    Type = DataRecord#m_broadcast_countdown_tos.type,
    SubType = DataRecord#m_broadcast_countdown_tos.sub_type,
    Content = DataRecord#m_broadcast_countdown_tos.content,
    Id = DataRecord#m_broadcast_countdown_tos.id,
    CountDownTime = DataRecord#m_broadcast_countdown_tos.countdown_time,
    CurrentCountDownTime = DataRecord#m_broadcast_countdown_tos.current_countdown_time,
    Message = #m_broadcast_countdown_toc{type = Type,sub_type = SubType,content = Content,id = Id,
                                         countdown_time = CountDownTime, current_countdown_time = CurrentCountDownTime},
    ?DEBUG("~ts,Message=~w,CountryId=~w",["接收国家广播消息为：",Message,CountryId]),
    common_misc:chat_broadcast_to_faction(CountryId, Module, Method, Message);

%% 根据家族频道发送数据到客户端
do_send_message({famliy, _Unique, Module, Method, DataRecord,FamliyId}) ->
    Type = DataRecord#m_broadcast_countdown_tos.type,
    SubType = DataRecord#m_broadcast_countdown_tos.sub_type,
    Content = DataRecord#m_broadcast_countdown_tos.content,
    Id = DataRecord#m_broadcast_countdown_tos.id,
    CountDownTime = DataRecord#m_broadcast_countdown_tos.countdown_time,
    CurrentCountDownTime = DataRecord#m_broadcast_countdown_tos.current_countdown_time,
    Message = #m_broadcast_countdown_toc{type = Type,sub_type = SubType,content = Content,id = Id,
                                         countdown_time = CountDownTime, current_countdown_time = CurrentCountDownTime},
    ?DEBUG("~ts,Message=~w,FamliyId=~w",["接收家族广播消息为：",Message,FamliyId]),
    common_misc:chat_broadcast_to_family(FamliyId, Module, Method, Message);
%% 根据队伍发送数据到客户端
do_send_message({team, _Unique, Module, Method, DataRecord, TeamId}) ->
    Type = DataRecord#m_broadcast_countdown_tos.type,
    SubType = DataRecord#m_broadcast_countdown_tos.sub_type,
    Content = DataRecord#m_broadcast_countdown_tos.content,
    Id = DataRecord#m_broadcast_countdown_tos.id,
    CountDownTime = DataRecord#m_broadcast_countdown_tos.countdown_time,
    CurrentCountDownTime = DataRecord#m_broadcast_countdown_tos.current_countdown_time,
    Message = #m_broadcast_countdown_toc{type = Type,sub_type = SubType,content = Content,id = Id,
                                         countdown_time = CountDownTime, current_countdown_time = CurrentCountDownTime},
    ?DEBUG("~ts,Message=~w,TeamId=~w",["接收组队广播消息为：",Message,TeamId]),
    common_misc:chat_broadcast_to_team(TeamId, Module, Method, Message).
