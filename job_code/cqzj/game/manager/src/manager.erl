-module(manager).

-behaviour(application).

-include("manager.hrl").

-export([
	 start/2,
	 stop/1,
	 start/0,
	 stop/0
        ]).

-define(APPS, [manager]).

start() ->
    try
        ok = common_misc:start_applications(?APPS) 
    after
        %%give the error loggers some time to catch up
        timer:sleep(100)
    end.

stop() ->
    ok = common_misc:stop_applications(?APPS).

%% --------------------------------------------------------------------
start(normal, []) ->
    code:ensure_loaded(all_pb),
    {ok, SupPid} = manager_sup:start_link(),
     lists:foreach(
      fun ({Msg, Thunk}) ->
              io:format("starting ~-32s ...", [Msg]),
              Thunk(),
              io:format("done~n");
          ({Msg, M, F, A}) ->
              io:format("starting ~-20s ...", [Msg]),
              apply(M, F, A),
              io:format("done~n")
      end,
      [
       {"Common Config init",
        fun() ->
            common_config_dyn:init(common)
        end},
       {"Manager Tcp Sup",
        fun() ->
            manager_tcp_sup:start()
        end},
       {"Manager Client Sup",
        fun() ->
            manager_client_sup:start()
        end},
       {"Manager Auth",
        fun() ->
            manager_auth:start()
        end},
       {"manager log",
        fun() ->
                manager_log:start()
        end},
       {"Node Manager",
        fun() ->
                ok = manager_node:start_all()
        end}
      ]),
    io:format("~nbroker running~n"),
    {ok, SupPid}.

stop(_State) ->
    ok.


