%%%----------------------------------------------------------------------
%%% File    : mgeem_sup.erl
%%% Author  : Liangliang
%%% Created : 2010-03-10
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------
-module(mgeem_sup).

-behaviour(supervisor).
-include("mgeem.hrl").
-export([start_link/0]).

-export([
	 init/1
        ]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).


init([]) ->
    {ok,{{one_for_one,10,10}, []}}.
