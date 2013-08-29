-module(sg_sup).
-behaviour(supervisor).

-include("common.hrl").


-export([start_link/1, start_child/1, start_child/2, init/1]).

start_link(Sup_tree_name) ->
	{ok,Pid} =  supervisor:start_link({local,Sup_tree_name}, ?MODULE, []),
	
	unlink(Pid),
	{ok,Pid}.
	

start_child(Mod) ->
    start_child(Mod, []).

%Call this method can dynamically generate a child process which act as worker. 
%And will call start_link method which was defined in the module Mod. 
start_child(Mod, Args) ->
    {ok, _} = supervisor:start_child(?MODULE,
                                     {Mod, {Mod, start_link, Args},
                                      transient, 100, worker, [Mod]}),
    ok.

init([]) -> 
	%gen_event:swap_handler(alarm_handler, {alarm_handler, swap}, {sd_alarm_handler, sd_server}),
	{
	 ok, 
	 {{one_for_one, 20, 10}, []}
	}. 


%% 
%% init_mysql() ->
%% 	mysql:start_link(?DB, ?DB_HOST, ?DB_PORT, ?DB_USER, ?DB_PASS, ?DB_NAME, fun(_, _, _, _) -> ok end, ?DB_ENCODE),
%%     mysql:connect(?DB, ?DB_HOST, ?DB_PORT, ?DB_USER, ?DB_PASS, ?DB_NAME, ?DB_ENCODE, true).

