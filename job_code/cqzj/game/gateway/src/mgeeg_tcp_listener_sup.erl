%%%----------------------------------------------------------------------
%%% File    : mgeeg_tcp_listener_sup.erl
%%% Author  : Liangliang
%%% Created : 2010-01-02
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeeg_tcp_listener_sup).

-behaviour(supervisor).

-export([start_link/5, start_link/6]).

-export([init/1]).

-include("mgeeg.hrl").

start_link(Port, Line, SocketOpts, OnStartup, OnShutdown) ->
    start_link(Port, Line, SocketOpts, OnStartup, OnShutdown, 1).

start_link(Port, Line, SocketOpts, OnStartup, OnShutdown, ConcurrentAcceptorCount) ->
    supervisor:start_link(
      ?MODULE, {Port, Line, SocketOpts, OnStartup, OnShutdown, ConcurrentAcceptorCount}).

init({Port, Line, SocketOpts, OnStartup, OnShutdown, ConcurrentAcceptorCount}) ->
    %% This is gross. The tcp_listener needs to know about the
    %% mgee_tcp_acceptor_sup, and the only way I can think of accomplishing
    %% that without jumping through hoops is to register the
    %% mgee_tcp_acceptor_sup.
	AcceptorSup = common_tool:to_atom(lists:concat(["mgeeg_tcp_acceptor_sup_",Line])),
    {ok, {{one_for_all, 10, 10},
          [{AcceptorSup, {mgeeg_tcp_acceptor_sup, start_link, [AcceptorSup]},
            transient, infinity, supervisor, [mgeeg_tcp_acceptor_sup]},
           {mgeeg_tcp_listener, {mgeeg_tcp_listener, start_link,
                           [Port, Line, SocketOpts,
                            ConcurrentAcceptorCount, AcceptorSup,
                            OnStartup, OnShutdown]},
            transient, 100, worker, [mgeeg_tcp_listener]}]}}.
