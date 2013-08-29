%%%----------------------------------------------------------------------
%%% File    : mgeerec_tcp_acceptor_sup.erl
%%% Author  : Liangliang
%%% Created : 2010-03-10
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeerec_tcp_acceptor_sup).

-behaviour(supervisor).

-include("mgeerec.hrl").

-export([start_link/1]).
-export([init/1]).

start_link(Callback) ->
    supervisor:start_link({local,?MODULE}, ?MODULE, Callback).

init(Callback) ->
    {ok, {{simple_one_for_one, 10, 10},
          [{mgeerec_tcp_acceptor, {mgeerec_tcp_acceptor, start_link, [Callback]},
            transient, brutal_kill, worker, [mgeerec_tcp_acceptor]}]}}.
