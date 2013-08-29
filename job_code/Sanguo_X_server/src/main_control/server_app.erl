%%%-----------------------------------
%%% @Module  : server_app
%%% @Author  : cjr
%%% @Email   : chenjianrong@4399.com
%%% @Created : 2012.05.02
%%% @Description: 
%%%-----------------------------------
-module(server_app).
-behaviour(application).
-export([start/2, stop/1]).
-include("common.hrl").


start(normal, []) ->
	Ret = case init_node() of
		true ->
		    {ok, SupPid} = sg_sup:start_link(sg_sup),
			
			dragon_loglevel:set_default_debug_info(),
			%%error_logger:add_report_handler(gen_handler),
			error_logger:add_report_handler(gen_handler, util:get_app_env(log_node)),
			receive 
				Msg -> 
					?INFO(init,"sd_server_app get message: ~w",[Msg])
				after 0 -> ok
			end,
	    	sg_networking:start({util:get_app_env(port)}),
	    	?INFO(init,"self pid is ~w",[self()]),
	    	{ok, SupPid};
		false ->
			false
	end,
	case Ret of
		false -> 
			LogNode = util:get_app_env(log_node),
			rpc:call(LogNode, log, stop, []),
			init:stop();
		_ -> Ret
	end.
    
  
stop(_State) ->   
    void. 

init_node() ->
	NodeName = util:get_app_env(node_name),
	case net_kernel:start([NodeName]) of
		{error, Reason} ->
			io:format("Init server node failed, reason: ~w", [Reason]),
			false;
		{ok, _Pid} ->
			Cookie = util:get_app_env(node_cookie),
			erlang:set_cookie(NodeName, Cookie),
			true
	end.

