%%%-------------------------------------------------------------------
%%% @author  <ChunchengCao>
%%% @copyright www.gmail.com (C) 2010, 
%%% @doc
%%% 循环消息广播处理
%%% @end
%%% Created : 13 Oct 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_broadcast_cycle).

-behaviour(gen_server).

%% Include files
-include("mgeew.hrl").
-include("broadcast.hrl").

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(CYCLE_MESSAGE_TYPE_LIST,[
                                 ?BC_MSG_TYPE_OPERATE,
                                 ?BC_MSG_TYPE_ALL,
                                 ?BC_MSG_TYPE_SYSTEM,
                                 ?BC_MSG_TYPE_CENTER,
                                 ?BC_MSG_TYPE_POP,
                                 ?BC_MSG_TYPE_CHAT
                                ]).
-define(CHAT_SUB_TYPE_LIST,[
                            ?BC_MSG_TYPE_CHAT_TEAM,
                            ?BC_MSG_TYPE_CHAT_WORLD,
                            ?BC_MSG_TYPE_CHAT_FAMILY,
                            ?BC_MSG_TYPE_CHAT_COUNTRY
                           ]).
-record(state, {message_list}).

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
start_link(ProcessName) ->
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
    {ok, #state{message_list = []}}.

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
    %%?DEBUG("~ts, Info=~w",["接收到的消息为",Info]),
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

%% 循环消息广播处理
do_handle_info({Unique, ?BROADCAST, ?BROADCAST_CYCLE, DataRecord}, State) 
  when erlang:is_record(DataRecord,m_broadcast_cycle_tos)->
    do_cycle_message(Unique, ?BROADCAST, ?BROADCAST_CYCLE, DataRecord, State);
do_handle_info({send_cycle_message,Id}, State) ->
    do_send_cycle_message({send_cycle_message,Id},State);

%% 添加外部操作本进程内部执行接口
do_handle_info({func, Fun, Args}, State) ->
    Ret =(catch apply(Fun,Args)),
    ?ERROR_MSG("~w",[Ret]),
    State;

do_handle_info(Info, State) ->
    ?ERROR_MSG("~ts,Info=~w",["无法处理此消息", Info]),
    State.

do_cycle_message(Unique, Module, Method, DataRecord, State) ->
    case catch do_cycle_message2(Unique, Module, Method, DataRecord, State) of
        {error,Reason} ->
            do_cycle_message_error(Unique, Module, Method, DataRecord, State, Reason);
         {ok} ->
            {MegaSecs, Secs, MicroSecs} = erlang:now(),
            Id = (MegaSecs * 1000000 + Secs) * 1000000 + MicroSecs,
            NowTime = common_tool:now(),
            do_cycle_message3(Unique, Module, Method, DataRecord, State, NowTime, Id)
    end.
do_cycle_message2(_Unique, _Module, _Method, DataRecord, _State) ->
    %% 检查消息参数的合法性
    Type = DataRecord#m_broadcast_cycle_tos.type,
    case lists:member(Type,?CYCLE_MESSAGE_TYPE_LIST) of
        true ->
            next;
       false ->
            erlang:throw({error,<<"消息类型出错">>})
    end,
    SubType = DataRecord#m_broadcast_cycle_tos.sub_type,
    if Type =:= ?BC_MSG_TYPE_CHAT ->
            case lists:member(SubType,?CHAT_SUB_TYPE_LIST) of
                true ->
                    next;
                false ->
                    erlang:throw({error,<<"当是聊天频道时，消息子类型出错">>})
            end;
       true ->
            if SubType =:= ?BC_MSG_SUB_TYPE ->
                    next;
               true ->
                    erlang:throw({error,<<"消息子类型出错">>})
            end
    end,
    Content = DataRecord#m_broadcast_cycle_tos.content,
    if Content =:= "" ->
            erlang:throw({error,<<"消息内容为空">>});
       true ->
            next
    end,
    SendType = DataRecord#m_broadcast_cycle_tos.send_type,
    if SendType =:= 0 orelse SendType =:= 1 ->
            next;
       true ->
            erlang:throw({error,<<"发送类型出错">>})
    end,
    StartTime = DataRecord#m_broadcast_cycle_tos.start_time,
    EndTime = DataRecord#m_broadcast_cycle_tos.end_time,
    NowTime = common_tool:now(),
    if SendType =:= 1 ->
            if EndTime >= StartTime andalso EndTime >= NowTime ->
                    next;
               true ->
                    erlang:throw({error,<<"发送时间出错">>})
            end;
       true ->
            next
    end,
    IntervalTime = DataRecord#m_broadcast_cycle_tos.interval,
    if SendType =:= 1 ->
            if IntervalTime > 0 ->
                    next;
               true ->
                    erlang:throw({error,<<"发送间隔时间出错">>})
            end;
       true ->
            next
    end,
    {ok}.

do_cycle_message3(Unique, Module, Method, DataRecord, State,NowTime,Id) ->
    SendType = DataRecord#m_broadcast_cycle_tos.send_type,
    if SendType =:= 0 ->
            do_send_message(Unique,DataRecord),
            State;
       true ->
            do_cycle_message4(Unique, Module, Method, DataRecord, State,NowTime,Id)
    end.
do_cycle_message4(Unique, Module, Method, DataRecord, State,NowTime,Id) ->
    #state{message_list = MessageList} = State,
    StartTime = DataRecord#m_broadcast_cycle_tos.start_time,
    if StartTime > NowTime ->
            ?DEV("~ts,DataRecord=~w",["当前不到发送消息开始时间，计算消息发送开始时间处理",DataRecord]),
            NewInterval = (StartTime - NowTime) * 1000,
            NewInterval2 = 
                if NewInterval > 4294967295 -> 
                        4294967295; 
                   true -> 
                        NewInterval 
                end,
            TimerRef = erlang:send_after(NewInterval2, self(), {send_cycle_message, Id}),
            MessageRecord = #r_broadcast_cycle_msg{id=Id, msg_record = DataRecord, unique = Unique , 
                                                   module = Module, method = Method, timer_ref = TimerRef},
            NewMessageList = lists:append(MessageList,[MessageRecord]),
            State#state{message_list = NewMessageList};
       true ->
            do_cycle_message5(Unique, Module, Method, DataRecord, State,NowTime,Id)
    end.
do_cycle_message5(Unique, Module, Method, DataRecord, State,NowTime,Id) ->
    #state{message_list = MessageList} = State,
    EndTime = DataRecord#m_broadcast_cycle_tos.end_time,
    if NowTime > EndTime ->
            ?DEV("~ts,DataRecord=~w，NowTime=~w",["当前消息已经过了发送时间，计算消息发送开始时间处理",DataRecord,NowTime]),
            NewMessageList = lists:delete(Id,MessageList),
            State#state{message_list = NewMessageList};
       true ->
            do_cycle_message6(Unique, Module, Method, DataRecord, State,NowTime,Id)
    end.
do_cycle_message6(Unique, Module, Method, DataRecord, State,NowTime,Id) ->
    #state{message_list = MessageList} = State,
    StartTime = DataRecord#m_broadcast_cycle_tos.start_time,
    EndTime = DataRecord#m_broadcast_cycle_tos.end_time,
    IntervalTime = DataRecord#m_broadcast_cycle_tos.interval,
    if NowTime >= StartTime andalso NowTime =< EndTime ->
            do_send_message(Unique,DataRecord),
            MessageList2 = lists:delete(Id,MessageList),
            TimerRef = erlang:send_after(IntervalTime * 1000, self(), {send_cycle_message, Id}),
            MessageRecord = #r_broadcast_cycle_msg{id=Id, msg_record = DataRecord, 
                                                   unique = Unique , module = Module, 
                                                   method = Method, timer_ref = TimerRef},
            MessageList3 = lists:append(MessageList2,[MessageRecord]),
            State#state{message_list = MessageList3};
       true ->
            NewMessageList = lists:delete(Id,MessageList),
            State#state{message_list = NewMessageList}
    end.
do_cycle_message_error(_Unique, _Module, _Method, DataRecord, State, Reason) ->
    ?DEBUG("~ts,Reason=~w,DataRecord=~w",["此后台广播消息不合法",Reason,DataRecord]),
    State.

%%　定时发送循环消息
do_send_cycle_message({send_cycle_message, Id},State) ->
    #state{message_list = MessageList} = State,
    case lists:keyfind(Id,#r_broadcast_cycle_msg.id,MessageList) of
        false ->
            ?DEBUG("~ts",["此循环发送的消息已经被删除，不需要处理"]),
            State;
        Record when erlang:is_record(Record,r_broadcast_cycle_msg) ->
            do_send_cycle_message2({send_cycle_message, Id},State,Record);
        _ ->
            ?DEBUG("~ts",["此循环发送的消息已经为非法消息，不需要处理"]),
            NewMessageList = lists:delete(Id,MessageList),
            State#state{message_list = NewMessageList}
    end.
do_send_cycle_message2({send_cycle_message, Id},State,Record) ->
    #r_broadcast_cycle_msg{msg_record = DataRecord, 
                           unique = Unique , module = Module, 
                           method = Method} = Record,
    NowTime = common_tool:now(),
    do_cycle_message3(Unique, Module, Method, DataRecord, State,NowTime,Id).

%% 发送消息处理
do_send_message(Unique,DataRecord) ->
    Module = ?BROADCAST, 
    Method = ?BROADCAST_GENERAL,
    do_send_message(Unique, Module, Method, DataRecord).

do_send_message(Unique, Module, Method, DataRecord) ->
    RoleIdList = DataRecord#m_broadcast_cycle_tos.role_list,
    if RoleIdList =/= [] andalso erlang:length(RoleIdList) > 0 ->
            do_send_message({role_list, Unique, Module, Method, DataRecord, RoleIdList});
       true ->
            do_send_message2(Unique, Module, Method, DataRecord)
    end.
do_send_message2(Unique, Module, Method, DataRecord) ->
    if DataRecord#m_broadcast_cycle_tos.is_world ->
            do_send_message({world, Unique, Module, Method, DataRecord, 0});
       true ->
            do_send_message3(Unique, Module, Method, DataRecord)
    end.
do_send_message3(Unique, Module, Method, DataRecord) ->
    CountryId = DataRecord#m_broadcast_cycle_tos.country_id,
    if CountryId =/= 0 ->
            do_send_message({country, Unique, Module, Method, DataRecord, CountryId});
       true ->
            do_send_message4(Unique, Module, Method, DataRecord)
    end.
do_send_message4(Unique, Module, Method, DataRecord) ->
     FamliyId = DataRecord#m_broadcast_cycle_tos.famliy_id,
    if FamliyId =/= 0 ->
            do_send_message({famliy, Unique, Module, Method, DataRecord,FamliyId});
       true ->
            do_send_message5(Unique, Module, Method, DataRecord)
    end.
do_send_message5(Unique, Module, Method, DataRecord) ->
    TeamId = DataRecord#m_broadcast_cycle_tos.team_id,
    if TeamId =/= 0 ->
            do_send_message({team,Unique, Module, Method, DataRecord, TeamId});
       true ->
            ?DEBUG("~ts,DataRecord=~w",["无法处理此系统消息",DataRecord])
    end.

%% 根据角色列表发送数据到客户端
do_send_message({role_list, Unique, Module, Method, DataRecord, RoleIdList}) ->
    Type = DataRecord#m_broadcast_cycle_tos.type,
    SubType = DataRecord#m_broadcast_cycle_tos.sub_type,
    Content = DataRecord#m_broadcast_cycle_tos.content,
    Message = #m_broadcast_general_toc{type = [Type],sub_type = SubType,content = Content},
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
    Type = DataRecord#m_broadcast_cycle_tos.type,
    SubType = DataRecord#m_broadcast_cycle_tos.sub_type,
    Content = DataRecord#m_broadcast_cycle_tos.content,
    Message = #m_broadcast_general_toc{type = [Type],sub_type = SubType,content = Content},
    ?DEV("~ts,Message=~w",["接收世界广播消息为：",Message]),
    common_misc:chat_broadcast_to_world(Module, Method, Message);

%% 根据国家频道发送数据到客户端
do_send_message({country, _Unique, Module, Method, DataRecord, CountryId}) ->
    Type = DataRecord#m_broadcast_cycle_tos.type,
    SubType = DataRecord#m_broadcast_cycle_tos.sub_type,
    Content = DataRecord#m_broadcast_cycle_tos.content,
    Message = #m_broadcast_general_toc{type = [Type],sub_type = SubType,content = Content},
    ?DEV("~ts,Message=~w,CountryId=~w",["接收国家广播消息为：",Message,CountryId]),
    common_misc:chat_broadcast_to_faction(CountryId, Module, Method, Message);

%% 根据宗族频道发送数据到客户端
do_send_message({famliy, _Unique, Module, Method, DataRecord,FamliyId}) ->
    Type = DataRecord#m_broadcast_cycle_tos.type,
    SubType = DataRecord#m_broadcast_cycle_tos.sub_type,
    Content = DataRecord#m_broadcast_cycle_tos.content,
    Message = #m_broadcast_general_toc{type = [Type],sub_type = SubType,content = Content},
    ?DEV("~ts,Message=~w,FamliyId=~w",["接收家族广播消息为：",Message,FamliyId]),
    common_misc:chat_broadcast_to_family(FamliyId, Module, Method, Message);
%% 根据队伍发送数据到客户端
do_send_message({team, _Unique, Module, Method, DataRecord, TeamId}) ->
    Type = DataRecord#m_broadcast_cycle_tos.type,
    SubType = DataRecord#m_broadcast_cycle_tos.sub_type,
    Content = DataRecord#m_broadcast_cycle_tos.content,
    Message = #m_broadcast_general_toc{type = [Type],sub_type = SubType,content = Content},
    ?DEV("~ts,Message=~w,TeamId=~w",["接收组队广播消息为：",Message,TeamId]),
    common_misc:chat_broadcast_to_team(TeamId, Module, Method, Message).
