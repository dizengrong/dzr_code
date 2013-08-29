-module(manager_tcp_sup).

-include("manager.hrl").

-behavior(supervisor).

-define(SERVER, ?MODULE).

-export([start/0, start_link/0, init/1]).

start() ->
    {ok, _} = 
        supervisor:start_child(manager_sup,
                               {?MODULE, 
                                {?MODULE, start_link, []},
                                transient, infinity, supervisor, [?MODULE]}
                              ),
    
    {ok, _} = 
        supervisor:start_child(?SERVER,
                               {manager_tcp_acceptor_sup, 
                                {manager_tcp_acceptor_sup, start_link, []},
                                transient, infinity, supervisor, [manager_tcp_acceptor_sup]}
                              ),
    
    {ok, _} = 
        supervisor:start_child(?SERVER,
                               {manager_tcp_listener, 
                                {manager_tcp_listener, start_link, []},
                                transient, 500, worker, [manager_tcp_listener]}
                              ).
        

start_link() ->
    {ok, _Pid} = 
        supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    {ok, {{one_for_one, 10, 10}, []}}.
