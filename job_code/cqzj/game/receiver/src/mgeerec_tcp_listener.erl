%%%----------------------------------------------------------------------
%%% File    : mgee_tcp_listener.erl
%%% Author  : Liangliang
%%% Created : 2010-01-02
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeerec_tcp_listener).

-behaviour(gen_server).

-include("mgeerec.hrl").

-export([start_link/6]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {sock, on_startup, on_shutdown}).

%%--------------------------------------------------------------------

start_link(Port, SocketOpts,
           ConcurrentAcceptorCount, AcceptorSup,
           OnStartup, OnShutdown) ->
    gen_server:start_link(
      ?MODULE, {Port, SocketOpts,
                ConcurrentAcceptorCount, AcceptorSup,
                OnStartup, OnShutdown}, []).

%%--------------------------------------------------------------------

init({Port, SocketOpts,ConcurrentAcceptorCount, AcceptorSup,
      {M,F,A} = OnStartup, OnShutdown}) ->
    process_flag(trap_exit, true),
    case gen_tcp:listen(Port, SocketOpts ++ [{active, false}]) of
    {ok, LSock} ->
		%% if listen successful ,we start several acceptor to accept it
        lists:foreach(
			fun (_) ->
            	{ok, APid} = supervisor:start_child(AcceptorSup, [LSock]),
				APid ! {event, start}
            end,
            lists:duplicate(ConcurrentAcceptorCount, dummy)),
        apply(M, F, A ++ [Port]),
        {ok, #state{sock = LSock, on_startup = OnStartup, on_shutdown = OnShutdown}};
    {error, Reason} ->
        ?ERROR_MSG(
        	"failed to start ~s on port:~p - ~p~n",
            [?MODULE, Port, Reason]),
        {stop, {cannot_listen, Port, Reason}}
    end.

handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({'EXIT', _, Reason}, State) ->
    ?ERROR_MSG("listener stop ~p ", [Reason]),
    {stop, normal, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(Reason, #state{sock=LSock, on_shutdown = {M,F,_A}}) ->
    {ok, {IPAddress, Port}} = inet:sockname(LSock),
    gen_tcp:close(LSock),
    ?INFO_MSG("stopped ~s on ~s:~p, reason:~p", [?MODULE, inet_parse:ntoa(IPAddress), Port, Reason]),
    apply(M, F, [IPAddress, Port]).

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
