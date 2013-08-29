-module(mgeec_role_sup).

-include("mgeec.hrl").

-behavior(supervisor).

-define(SERVER, ?MODULE).

-export([start/0, start_link/0, init/1]).
 
start() ->
    {ok, _Pid} = 
        supervisor:start_child(mgeec_sup,
                               {?MODULE, {?MODULE, start_link, []},
                                transient, infinity, supervisor, [?MODULE]}
                              ).

start_link() ->
    {ok, _Pid} = 
        supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    ChildSpec = 
        {mgeec_role,
         {mgeec_role,
          start_link,
          []
         },
         temporary, ?ROLE_PROCESS_EXIT_WAIT, worker, [mgeec_role]},

    {ok, {{simple_one_for_one, 1, 1}, [ChildSpec]}}.
