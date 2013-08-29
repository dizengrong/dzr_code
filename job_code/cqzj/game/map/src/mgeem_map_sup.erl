%%% -------------------------------------------------------------------
%%% Author  : Liangliang
%%% Description :
%%%
%%% Created : 2010-3-26
%%% -------------------------------------------------------------------
-module(mgeem_map_sup).

-behaviour(supervisor).
-export([start/0, start_link/0]).

-export([
	 init/1
        ]).

start() ->
    {ok, _} = supervisor:start_child(mgeem_sup, {?MODULE,
                                                 {?MODULE, start_link, []},
                                                 permanent, infinity, supervisor, 
                                                 [?MODULE]}).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    AChild = {mgeem_map,{mgeem_map,start_link,[]},
              temporary, 50000, worker, [mgeem_map]},%% transient
    {ok,{{simple_one_for_one,100,1}, [AChild]}}.

