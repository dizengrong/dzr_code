%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 29 Jun 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(behavior_server).

-behaviour(gen_server).

-include("mgeeb.hrl").


%% API
-export([
         start/0,
         start_link/0
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-export([connect_to_receiver/0,
         is_connect_to_receiver/0]).

-record(state, {socket}).


-define(ETS_SEND_QUEUE, ets_send_queue).

-define(ETS_UNSEND_QUEUE, ets_unsend_queue).

-define(ETS_UNIQUE, ets_unique).

%%多久检查一次已发送队列
-define(CHECK_SEND_QUEUE_TICKET, 3600 * 1000).

%%多久检查一次未发送队列
-define(CHECK_UNSEND_QUEUE_TICKET, 3600 * 1000).

%%多久重置一次unique
-define(CLEAR_UNIQUE_TICKET, 86400 * 1000).


%%%===================================================================
%%% API
%%%===================================================================

start() ->
    {ok, _} = supervisor:start_child(mgeeb_sup, {?MODULE, 
                                                 {?MODULE, start_link, []},
                                                 transient, brutal_kill, worker, [?MODULE]}).

start_link() ->
    gen_server:start_link(?MODULE, [], []).

%%%===================================================================


%%--------------------------------------------------------------------
init([]) ->
    case common_config_dyn:find_common(conn_receiver) of
        [false] ->
            global:register_name(?MODULE, self()),
            {ok, #state{}};
        _ ->
            init_2()
    end.
    
init_2()->    
    case connect_to_receiver() of
        {ok, Socket} ->
            global:register_name(?MODULE, self()),
            ets:new(?ETS_SEND_QUEUE, [named_table, set, private]),
            ets:new(?ETS_UNSEND_QUEUE, [named_table, set, private]),
            ets:new(?ETS_UNIQUE, [named_table, set, private]),
            ets:insert(?ETS_UNIQUE, {unique, 0}),
            erlang:send_after(?CHECK_SEND_QUEUE_TICKET, self(), check_send_queue),
            erlang:send_after(?CHECK_UNSEND_QUEUE_TICKET, self(), check_unsend_queue),
            erlang:send_after(?CLEAR_UNIQUE_TICKET, self(), clear_unique),
            {ok, #state{socket=Socket}};
        {error, Reason} ->
            case common_config:is_debug() of
                true->
                    ignore;
                _ ->
                    ?ERROR_MSG("~ts:~w", ["连接receiver.server出错", Reason])
            end,
            case common_config_dyn:find_common(conn_receiver) of
                [false] ->
                    ignore;
                _ ->
                    try_start_again()
            end, 
            
            {stop, Reason}
    end.

%%--------------------------------------------------------------------

handle_call({get_socket}, _From, State) ->
    #state{socket=Socket} = State,
    Reply = case Socket of
                undefined->
                    {error,Socket};
                _ ->
                    {ok,Socket}
            end,
    {reply, Reply, State};
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.


%%--------------------------------------------------------------------

%%BehaviorList 类型为list 每个元素为 {Module, Method, Record}
handle_info({behavior_list, BehaviorList}, State) ->
    do_behavior_list(BehaviorList, State#state.socket),
    {noreply, State};
handle_info({s2s_list, BehaviorList}, State) ->
    do_s2s_list(BehaviorList, State#state.socket),
    {noreply, State};
handle_info({tcp, _Socket, Data}, State) ->
    do_handle_data(Data),
    {noreply, State};

handle_info({tcp_closed, _Socket}, State) ->
    ?ERROR_MSG("~ts", ["远程receiver.server的连接关闭"]),
    try_conn_again(State);

handle_info({tcp_error, Socket, Reason}, State) ->
    gen_tcp:close(Socket),
    ?ERROR_MSG("~ts:~w", ["TCP错误", Reason]),
    try_conn_again(State);

handle_info(try_conn_again, State) ->
    try_conn_again(State);

handle_info(check_send_queue, State) ->
    clear_send_queue(),
    {noreply, State};
handle_info(check_unsend_queue, State) ->
    clear_unsend_queue(),
    {noreply, State};
handle_info(clear_unique, State) ->
    ets:insert(?ETS_UNIQUE, {unique, 0}),
    clear_send_queue(),
    clear_unsend_queue(),
    {noreply, State};
handle_info(Info, State) ->
    ?ERROR_MSG("~ts:~w", ["未知消息", Info]),
    {noreply, State}.


%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.


%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
    
do_s2s_list(S2S_List, Socket)->
    do_behavior_list(S2S_List, Socket).

%%处理行为日志列表
do_behavior_list(List, Socket) ->
    Unique = get_new_unique(),
    
    case erlang:is_port(Socket) of
        true ->
            mgeeb_packet:send(Socket, Unique, List),
            push_send_queue(Unique, List);
        false ->
            push_unsend_queue(Unique, List)
    end.

is_connect_to_receiver()->
    gen_server:call({global,?MODULE}, {get_socket}).


%%连接到receiver.server
connect_to_receiver() ->
    Hosts = common_config:get_receiver_host(),
    case erlang:length(Hosts) > 0  of
        true ->
            %%随机选择一个host
            Max = erlang:length(Hosts),
			{_,Host, Port} = lists:nth(common_tool:random(1, Max), Hosts),
			
            Result = gen_tcp:connect(Host, Port, [inet, binary, {packet, 4}, {active, true}]),
            do_auth(Result);
        false ->
            ?ERROR_MSG("~ts", ["配置文件错误，无法读取receiver.server的服务IP端口配置"])
    end.

do_auth({ok, Socket}) ->

    gen_tcp:send(Socket, <<"00000000000000000000000">>),

    AuthData = 
        #b_server_auth_tos{agent_name=common_config:get_agent_name(), 
                           game_id=common_config:get_server_id(), 
                           ticket="123456"},

    gen_tcp:send(Socket, erlang:term_to_binary({?B_SERVER, ?B_SERVER_AUTH, AuthData})),
    {ok, Socket};

do_auth(Other) ->
    Other.

%%处理receiver发送过来的消息
%%确认了一条消息后，从内存中删除
do_handle_data(Data) ->
    {Module, Method, Record} = mgeeb_packet:unpack(Data),
    do_handle_data2(Module, Method, Record).
do_handle_data2(?B_SERVER, ?B_SERVER_AUTH, _Record) ->
    ?INFO_MSG("server auth ok",[]);
do_handle_data2(_Module, ?B_SERVER_UNIQUE, Record) ->
    do_unique(Record);
do_handle_data2(_Module, ?B_SERVER_MSG, Record) ->
    do_msg(Record);
do_handle_data2(Module, Info, Record) ->
    ?ERROR_MSG("~ts:~w ~w ~w", ["未知的消息proto", Module, Info, Record]).

%%删除已经确认的包
do_unique(Record) ->
    remove_from_send_queue(Record#b_server_unique_toc.unique).     
%%处理服务端发来的消息
do_msg(Record) ->       
    ?ERROR_MSG("~ts:~w", ["收到集群发来的消息", Record#b_server_msg_toc.msg]).


%%发送的数据要保存在内存中，等待receiver确认后删除
push_send_queue(Unique, BehaviorList) ->
    ets:insert(?ETS_SEND_QUEUE, {Unique, BehaviorList}).
remove_from_send_queue(Unique) ->
    ets:delete(?ETS_SEND_QUEUE, Unique).
clear_send_queue() ->
    ets:delete_all_objects(?ETS_SEND_QUEUE).
    

%%在网络出错时将日志压入到队列中去
push_unsend_queue(Unique, BehaviorList) ->
    ets:insert(?ETS_UNSEND_QUEUE, {Unique, BehaviorList}).
flush_unsend_queue(Socket) ->
    ets:foldl(
      fun({Unique, BehaviorList}, _) ->
              case erlang:is_port(Socket) of
                  true ->
                      mgeeb_packet:send(Socket, Unique, BehaviorList),
                      remove_from_unsend_queue(Unique);
                  false ->
                      ok
              end
      end, [], ?ETS_UNSEND_QUEUE).
                      
                      
clear_unsend_queue() ->
    ets:delete_all_objects(?ETS_UNSEND_QUEUE).
remove_from_unsend_queue(Unique) ->
    ets:delete(?ETS_UNSEND_QUEUE, Unique).


%%获得一个新的unique
get_new_unique() ->
    ets:update_counter(?ETS_UNIQUE, unique, 1).

try_start_again() ->
    spawn(fun() -> do_try_start_again()  end).

do_try_start_again() ->

    Pid = self(),
    erlang:send_after(1000, Pid, {Pid, start}),
    receive
        {Pid, start} ->
            try 
                {ok, _} = start(),
                ?DEBUG("~ts", ["哟!RP大爆发，重新连接receiver.server成功"])
            catch 
                _:_ -> 
                    %%?ERROR_MSG("~ts", ["重新连接receiver.server失败，将再次尝试"]),
                    ok
            end;
        Other ->
            ?DEBUG("~ts:~w", ["重新连接receiver.server时，重连进程遇到未知的消息", Other]),
            ok
    after 5000 ->
            exit(normal)
    end.

try_conn_again(State) ->
    case connect_to_receiver() of
        {ok, NewSocket} ->
            flush_unsend_queue(NewSocket),
            ?DEBUG("~ts", ["哟!RP大爆发，重新连接receiver.server成功"]),
            {noreply, State#state{socket=NewSocket}};
        {error, _Reason} ->
            ?ERROR_MSG("~ts", ["重新连接receiver.server失败，将再次尝试"]),
            erlang:send_after(1000, self(), try_conn_again),
            {noreply, State}
    end.
