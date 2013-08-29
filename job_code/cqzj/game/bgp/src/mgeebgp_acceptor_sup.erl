%%%----------------------------------------------------------------------
%%% @copyright 2010 mcs (Ming Chao Server)
%%%
%%% @author bisonwu, 2010-7-13
%%% @doc mgeebgp_acceptor_sup
%%%		bgproxy is short for border gateway proxy
%%% @end
%%%----------------------------------------------------------------------
-module(mgeebgp_acceptor_sup).

-behaviour(supervisor).

-include("common.hrl").
-include("mgeebgp_comm.hrl").

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local,?MODULE}, ?MODULE, [] ).

init([]) ->
	?INFO_MSG("~p init",[?MODULE]),
    {ok, {{simple_one_for_one, 10, 10},
          [{mgeebgp_acceptor, 
			{mgeebgp_acceptor, start_link, []},
            transient, brutal_kill, worker, [mgeebgp_acceptor]}]}}.
