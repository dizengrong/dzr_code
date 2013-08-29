%%%----------------------------------------------------------------------
%%% File    : mgeerec.erl
%%% Author  : Liangliang
%%% Created : 2010-06-30
%%% Description: 游戏服务行为日志接收端
%%%----------------------------------------------------------------------

-module(mgeerec).

-behaviour(application).
-include("mgeerec.hrl").
-export([
	 start/2,
	 stop/1,
	 start/0,
	 stop/0
        ]).

-define(APPS, [sasl, mgeerec]).

%% --------------------------------------------------------------------

start() ->
    try
        ok = common_misc:start_applications(?APPS) 
    after
        timer:sleep(100)
    end.

stop() ->
    ok = common_misc:stop_applications(?APPS).


%% --------------------------------------------------------------------
start(normal, []) ->
    {ok, SupPid} = mgeerec_sup:start_link(),
    lists:foreach(
      fun ({Msg, Thunk}) ->
              io:format("starting ~-24s ...", [Msg]),
              Thunk(),
              io:format("done~n");
          ({Msg, M, F, A}) ->
              io:format("starting ~-20s ...", [Msg]),
              apply(M, F, A),
              io:format("done~n")
      end, 
      [
	   {"MGEE Receiver Logger",
        fun () ->
                {ok, LogPath} = application:get_env(log_path),
                error_logger:add_report_handler(mgeerec_logger_h, LogPath),
                {ok, LogLevel} = application:get_env(log_level),
                mgeerec_loglevel:set(LogLevel)
        end},
	   {"MGEE common Logger",
        fun() ->
                error_logger:add_report_handler(common_logger_h, ""),
                {ok, LogLevel} = application:get_env(log_level),
                common_loglevel:set(LogLevel)
        end},
       {"Common Config init",
        fun() ->
                common_config_dyn:init_basic(),
                common_config_dyn:init(item),
                common_config_dyn:init(stone),
                common_config_dyn:init(equip),
                common_config_dyn:init(receiver_server)
        end},
       {"Start inets Server",
        fun() ->
                inets:start()
        end},
	   {"Mysql Server",
			   fun() ->
					   NormalPoolSize = mod_mysql:get_normal_pool_size(),
					   MySqlConfig = mgeerec_config:get_mysql_config(),
					   mod_mysql:start(NormalPoolSize,MySqlConfig)
			   end},
       {"TCP listeners",
        fun () ->
                mgeerec_networking:start(),
                AcceptorNum = common_config:get_receiver_host_acceptor_num(),
                {ok, [[PortStr]]} = init:get_argument(port),
                Port = common_tool:to_integer(PortStr),
                ok = mgeerec_networking:start_tcp_listener(Port, AcceptorNum)
        end}
      ]),
    io:format("~nbroker running~n"),
    {ok, SupPid}.

%% --------------------------------------------------------------------
stop(_State) ->
    ok.

