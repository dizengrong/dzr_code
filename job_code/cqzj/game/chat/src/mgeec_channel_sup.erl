-module(mgeec_channel_sup).

-behaviour(supervisor).

-include("mgeec.hrl").

-export([start/0, start_link/0]).

-export([
	 init/1
        ]).

-define(SERVER, ?MODULE).

%% --------------------------------------------------------------------
start() ->
    {ok, _Pid} = 
        supervisor:start_child(mgeec_sup,
                               {?MODULE, {?MODULE, start_link, []},
                                transient, infinity, supervisor, [?MODULE]}
                              ).

start_link() ->
	supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    ChildSpec = 
        {mgeec_channel, 
         {mgeec_channel, start_link, []},
         transient, 
         ?CHANNEL_PROCESS_EXIT_WAIT,
         worker,
         [mgeec_channel]},

    ets:new(?ETS_CHANNEL_COUNTER, [bag, public, named_table, {keypos, #channel_counter.channel_sign}]),
    ets:new(?ETS_CHANNEL_ROLE, [bag, public, named_table, {keypos, #channel_role.role_id}]),

    {ok,{{simple_one_for_one,10,10}, [ChildSpec]}}.

%% --------------------------------------------------------------------
