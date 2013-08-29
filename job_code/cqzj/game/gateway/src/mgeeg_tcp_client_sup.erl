%%% -------------------------------------------------------------------
%%% Author  : Liangliang
%%% Description :
%%%
%%% Created : 2010-3-12
%%% -------------------------------------------------------------------
-module(mgeeg_tcp_client_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([
	 init/1
        ]).


start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).


init([]) ->
    Child ={mgeeg_tcp_client, 
            {mgeeg_tcp_client, start_link, []},
            temporary, 30000, worker,
            [mgeeg_tcp_client]},
    {ok,{{simple_one_for_one,10,10}, [Child]}}.
