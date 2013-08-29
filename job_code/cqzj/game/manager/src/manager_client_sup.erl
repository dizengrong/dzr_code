-module(manager_client_sup).

-include("manager.hrl").

-behavior(supervisor).

-define(SERVER, ?MODULE).

-export([start/0, start_link/0, init/1]).
 
start() ->
    {ok, _Pid} = 
        supervisor:start_child(manager_sup,
                               {?MODULE, {?MODULE, start_link, []},
                                transient, infinity, supervisor, [?MODULE]}
                              ).

start_link() ->
    {ok, _Pid} = 
        supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    ChildSpec = 
        {manager_client,
         {manager_client,
          start_link,
          []
         },
         temporary, ?CLIENT_PROCESS_EXIT_WAIT, worker, [manager_client]},

    {ok, {{simple_one_for_one, 1, 1}, [ChildSpec]}}.
