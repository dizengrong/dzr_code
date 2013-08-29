%%% -------------------------------------------------------------------
%%% Author  : Liangliang
%%% Description : 
%%%
%%% Created : 2010-06-30
%%% -------------------------------------------------------------------
-module(mgeerec_tcp_client).

-behaviour(gen_server).
-include("mgeerec.hrl").
-export([
         start_link/1, 
         notify_auth_passed/3, 
         notify_heartbeat/1,
         process_name/2
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%%游戏服信息： 代理商名称 游戏服ID
-record(state, {socket, agent_name, game_id}).


start_link(ClientSock) ->
    gen_server:start_link(?MODULE, [ClientSock], []).


%%通知说游戏服的认证通过了
notify_auth_passed(Pid, AgentName, GameID) ->
    gen_server:call(Pid, {game_auth_passed, AgentName, GameID}).


%%心跳通知
notify_heartbeat(Parent) ->
    gen_server:cast(Parent, {event, heartbeat}).


init([ClientSock]) ->
    erlang:process_flag(trap_exit, true),
    {ok, #state{socket=ClientSock}}.


%%游戏服认证通过
handle_call({game_auth_passed, AgentName, GameID}, _From, State) ->
    RegName = process_name(AgentName, GameID),
    %%判断是否已经连接过了，防止一个游戏服连接两个socket过来
    case global:whereis_name(RegName) of
        undefined ->
            ok;
        Pid ->
            %%通知上一个连接关闭掉
            gen_server:call(Pid, {event, login_again})
    end,
    global:register_name(RegName, self()),
    NewState = State#state{agent_name=AgentName, game_id=GameID},
    {reply, RegName, NewState};


handle_call({event, login_again}, _From, State) ->
    %%发包通知：有新的连接
    Socket = State#state.socket,
    R = #b_server_msg_toc{msg=?_LANG_SERVER_ANOTHER_LOGIN},
    mgeerec_packet:send(Socket, ?B_SERVER, ?B_SERVER_MSG, R),
    gen_tcp:close(Socket),
    {stop, normal, ok, State};


handle_call(Request, From, State) ->
    ?ERROR_MSG("unexpected call ~p from ~p", [Request, From]),
    Reply = ok,
    {reply, Reply, State}.


handle_cast({'EXIT', _Pid, not_valid_client}, State) ->
    {stop, normal, State};


handle_cast(Msg, State) ->
    ?INFO_MSG("unexpected cast ~p", [Msg]),
    {noreply, State}.


handle_info({'EXIT', _Pid, catch_normal}, State) ->
    {stop, normal, State};


handle_info({'EXIT', _Pid, normal}, State) ->
    {stop, normal, State};


handle_info({'EXIT', _Pid, not_valid_client}, State) ->
    {stop, normal, State};


handle_info({'EXIT', _Pid, unknow_packet}, State) ->
    {stop, normal, State};


handle_info({'EXIT', _Pid, _Reason}, State) ->
    spawn_link(mgeerec_tcp_client_receiver, start, [State#state.socket, self()]),
    {noreply, State};


handle_info({event, run}, State) ->
    spawn_link(mgeerec_tcp_client_receiver, start, [State#state.socket, self()]),
    {noreply, State};


handle_info({info, {Module, Method, DataBin}}, State) ->
    mgeerec_packet:send(State#state.socket, Module, Method, DataBin),
    {noreply, State};


handle_info(Info, State) ->
    ?INFO_MSG("unexpected info ~p", [Info]),
    {noreply, State}.


terminate(Reason, #state{socket=Socket} = State) when is_port(Socket) ->
    ?INFO_MSG("~p terminate : ~p, ~p", [self(), Reason, State]),
    gen_tcp:close(Socket),
    ok;
terminate(Reason, State) ->
    ?INFO_MSG("~p terminate : ~p, ~p ~p", [self(), Reason, State, is_port(State#state.socket)]),
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


process_name(AgentName, GameID) ->
    lists:append(["mgeerec_game_", AgentName, "_", GameID]).


