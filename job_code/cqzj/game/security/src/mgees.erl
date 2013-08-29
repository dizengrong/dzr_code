%% Author: Administrator
%% Created: 2010-3-18
%% Description: TODO: Add description to security
-module(mgees).

-behaviour(application).

-export([
	 start/0,
	 start/2,
	 stop/1
        ]).


start() ->
    try
        application:start( mgees ),
        ok
    after
        timer:sleep(100)
    end.


start(_Type, _StartArgs) ->
    {ok, AcceptorNum} = application:get_env(acceptor_num),
    {ok, Port} = application:get_env(listen_port),
    case mgees_sup:start_link({Port,AcceptorNum}) of
	{ok, Pid} ->
	    {ok, Pid};
	Error ->
	    Error
    end.

stop(_State) ->
    ok.

