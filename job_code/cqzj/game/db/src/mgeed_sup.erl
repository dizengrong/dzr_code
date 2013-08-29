%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2010-1-1
%%% -------------------------------------------------------------------
-module(mgeed_sup).

-behaviour(supervisor).
-include("mgeed.hrl").
-export([start_link/0]).


-export([
	 init/1
        ]).


start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).


init([]) ->
    {ok,{{one_for_one,10,10}, []}}.



