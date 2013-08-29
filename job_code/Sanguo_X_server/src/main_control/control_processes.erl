%%%-----------------------------------
%%% @Module  : contorl_processes
%%% @Author  : cjr
%%% @Email   : chenjianrong@4399.com
%%% @Created : 2012-05-02
%%% @Description: launch all control processes which life circle is the same as server
%%%-----------------------------------
-module(control_processes).
-export([start/1]).

-include("common.hrl").

start({Port}) ->
	ok = init_mysql(),

	ok = start_client(),
	ok = start_tcp(Port),
	ok = start_monster(),
	ok.

init_mysql() ->
	{ok, _MysqlPid} = 
		supervisor:start_child
		(
			sg_sup, 
			{
				mysql,
				{mysql, start_link, 
					[?DB, ?DB_HOST, ?DB_PORT, ?DB_USER, ?DB_PASS, ?DB_NAME, fun(_, _, _, _) -> ok end, ?DB_ENCODE]},
				permanent, 10000, worker, [mysql]
			}
		),	
	 mysql:connect(?DB, ?DB_HOST, ?DB_PORT, ?DB_USER, ?DB_PASS, ?DB_NAME, ?DB_ENCODE, true),
	 ok.


start_client() ->
    {ok,_} = supervisor:start_child(
               sg_sup,
               {sg_tcp_client_sup,
                {sg_tcp_client_sup, start_link,[]},
                transient, infinity, supervisor, [sg_tcp_client_sup]}),
    ok.


%%startup tcp listener supervision tree
start_tcp(Port) ->
    {ok,_} = supervisor:start_child(
               sg_sup,
               {sg_tcp_listener_sup,
                {sg_tcp_listener_sup, start_link, [Port]},
                transient, infinity, supervisor, [sg_tcp_listener_sup]}),
    ok.

start_monster() ->
	{ok, _} = sg_sup:start_link(sup_monster),
	{ok, _} = 
		supervisor:start_child(sup_monster,
			{
			 	mod_monster,
		   		{
				 	mod_monster, 
					start_link, 
					[]
				},
				permanent, 10000, worker, [mod_monster]
			}
		).