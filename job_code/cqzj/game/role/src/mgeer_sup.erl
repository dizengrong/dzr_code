%%%----------------------------------------------------------------------
%%% File    : mgeer_sup.erl
%%% Author  : xierongfeng
%%% Created : 2013-01-04
%%% Description: 
%%%----------------------------------------------------------------------
-module(mgeer_sup).

-behaviour(supervisor).
-include("mgeer.hrl").
-export([start_link/0]).

-export([
	 init/1
        ]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).


init([]) ->
    Child ={mgeer_role, 
            {mgeer_role, start_link, []},
            temporary, 30000, worker,
            [mgeer_role]},
    {ok,{{simple_one_for_one,10,10}, [Child]}}.
