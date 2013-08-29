-module(manager_tcp_acceptor_sup).

-include("manager.hrl").

-behavior(supervisor).

-define(SERVER, ?MODULE).

-export([start_link/0, init/1]).
 
start_link() ->
    {ok, _Pid} = 
        supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->

    ChildSpec = 
        {manager_tcp_acceptor,
         {manager_tcp_acceptor,
          start_link,
          []
         },
         transient, brutal_kill, worker, [manager_tcp_acceptor]},

    {ok, {{simple_one_for_one, 10, 10}, [ChildSpec]}}.
