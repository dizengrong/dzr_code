%%%----------------------------------------------------------------------
%%% File    : mgeeg_tcp_acceptor_sup.erl
%%% Author  : Liangliang
%%% Created : 2010-03-10
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeeg_tcp_acceptor_sup).

-behaviour(supervisor).

-include("mgeeg.hrl").

-export([start_link/1]).
-export([init/1]).

start_link(Name) ->
	case erlang:whereis(?MODULE) of
		undefined ->
    		supervisor:start_link({local, Name}, ?MODULE, []);
		_ ->
			ignore
	end.

init([]) ->
    {ok, {{simple_one_for_one, 10, 10},
          [{mgeeg_tcp_acceptor, {mgeeg_tcp_acceptor, start_link, []},
            transient, brutal_kill, worker, [mgeeg_tcp_acceptor]}]}}.
