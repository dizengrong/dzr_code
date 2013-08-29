-module(mgees_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------

-export([start_link/1]).

-export([
	 init/1
        ]).

%% --------------------------------------------------------------------
-define(SERVER, ?MODULE).


start_link({Port,AccNum}) -> 
	supervisor:start_link({local,?SERVER},?MODULE, [Port,AccNum]).

	
%% --------------------------------------------------------------------
init([Port,AccNum]) ->
    error_logger:error_msg("~p ~p", [Port,AccNum]),
   {ok, {{one_for_one, 10, 10},
          [{mgees_acceptor_sup, {mgees_acceptor_sup, start_link,[]},
            transient, infinity, supervisor, [mgees_acceptor_sup]},
		   
           {mgees_listener, {mgees_listener, start_link,[Port,AccNum]},        
            transient, 100, worker, [mgees_listener]}
		   
		  ]}}.


