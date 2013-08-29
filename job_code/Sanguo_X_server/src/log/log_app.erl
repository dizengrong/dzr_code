%% Author: Administrator
%% Created: 2011-9-21
%% Description: TODO: Add description to client_app
-module(log_app).

-behaviour(application).

-include("common.hrl").

-export([start/2, stop/1]). 

start(_Type, _Args) ->
	case init_node() of
		true ->
			dragon_loglevel:set(5),
			application:start(sasl),
			
			LogPath = get_log_path(),
			io:format("log_path = ~s", [LogPath]),
		    error_logger:add_report_handler(dragon_logger_h, LogPath),
			%% must delete this handler!!!
			error_logger:delete_report_handler(error_logger),
		    {ok, SupPid} = log_sup:start_link(),
		    {ok, SupPid};
		false -> 
			init:stop(),
			false
	end.
  
stop(_State) -> 
	ok.

get_log_path() ->
    case application:get_env(log_path) of
	{ok, Path} ->
	    Path;
	undefined ->
	    ?LOG_PATH		
    end.

init_node() ->
	NodeName = util:get_log_app_env(node_name),
	io:format("NodeName = ~w", [NodeName]),
	case net_kernel:start([NodeName]) of
		{error, Reason} ->
			io:format("Init log node failed, reason: ~w", [Reason]),
			false;
		{ok, _Pid} ->
			Cookie = util:get_log_app_env(node_cookie),
			erlang:set_cookie(node(), Cookie),
			true
	end.    