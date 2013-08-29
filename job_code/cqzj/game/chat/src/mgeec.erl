-module(mgeec).

-behaviour(application).
-include("mgeec.hrl").

-export([
	 start/2,
	 stop/1,
	 start/0,
	 stop/0
        ]).

-define(APPS, [mgeec]).

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
    {ok, SupPid} = mgeec_sup:start_link(),
    io:format("~n", []),
    lists:foreach(
      fun ({Msg, Thunk}) ->
              io:format("starting ~p ...", [Msg]),
              Thunk(),
              io:format("done~n");
          ({Msg, M, F, A}) ->
              io:format("starting ~p ...", [Msg]),
              apply(M, F, A),
              io:format("done~n")
      end,
      [       
              {"MGEE Chat - Msg Logger",
               fun() ->
                       mgeec_logger:start()
               end},
              {"Start Config Loader",
               fun() ->
                       mgeec_config:start()
               end},
              {"start client manager", 
               fun() ->
                       mgeec_client_manager:start()
               end},
              {"Start Actor Supverisor",
               fun() ->
                       mgeec_role_sup:start()
               end},
              {"Start Channel Supverisor",
               fun() ->
                       mgeec_channel_sup:start()
               end},
              {"Start Broadcast Supverisor",
               fun() ->
                       mgeec_broadcast_sup:start()
               end},
              {"Start Broadcast Server",
               fun() ->
                       mgeec_broadcast:start()
               end},
              {"Start Server Stop Clear Server",
               fun() ->
                       mgeec_server_stop:start()
               end},
              {"Start Mgeec Goods Cache",
               fun() ->
                       mgeec_goods_cache:start()
               end}
      ]
     ),
    ?SYSTEM_LOG("~ts~n", ["mgeec启动成功"]),
    {ok, SupPid}.

%% --------------------------------------------------------------------
stop(_State) ->
    ok.

