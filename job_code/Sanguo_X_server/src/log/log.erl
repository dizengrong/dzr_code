%% Author: Administrator
%% Created: 2012-1-31
%% Description: TODO: Add description to log
-module(log).


-export([start/0, 
		 stop/0]).

start() ->
    application:start(log).

stop() ->
    application:stop(log),
	init:stop().


