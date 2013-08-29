-module(manager_tcp_acceptor).

-behavior(gen_server).

-include("manager.hrl").

-record(state, {}).

-export([start_link/1, init/1]).

-export([handle_info/2, handle_cast/2, handle_call/3, terminate/2, code_change/3]).

start_link(Socket) ->
    {ok, Pid} = gen_server:start_link(?MODULE, [], []),
	Pid ! {loop_accept, Socket}.

init([]) ->
    erlang:process_flag(trap_exit, true),
    {ok, #state{}}.

handle_info({loop_accept, Socket}, State) ->
    ?DEV("~ts (:", ["开始接受连接"]),
    case gen_tcp:accept(Socket) of
        {ok, AcceptorSocket} ->
            manager_auth:cast_auth(AcceptorSocket),
            self() ! {loop_accept, Socket},
    		{noreply, State};
        {error, closed} ->
            {stop, normal, State};
        {error, Reason} ->
            ?ERROR_MSG("~ts:~w", ["gen_tcp:accept失败了,原因是", Reason]),
            {stop, normal, State}
    end;

handle_info(Info, State) ->
    ?DEV("~ts:~w", ["收到未知的消息(handle_info)", Info]),
    {noreply, State}.

handle_cast(Info, State) ->
    ?DEV("~ts:~w", ["收到未知的消息(handle_cast)", Info]),
    {noreply, State}.
   
handle_call(Info, _From, State) ->
    ?DEV("~ts:~w", ["收到未知的消息(handle_call)", Info]),
    {reply, ok, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
