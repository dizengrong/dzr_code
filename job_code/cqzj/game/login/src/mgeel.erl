%%%----------------------------------------------------------------------
%%% File    : mgeel.erl
%%% Author  : Liangliang
%%% Purpose : MGEE application
%%% Created : 2010-03-10
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeel).

-behaviour(application).

-include("mgeel.hrl").

-export([
	 start/2,
	 stop/1,
	 start/0,
	 stop/0
        ]).

-define(APPS, [mgeel]).

%% --------------------------------------------------------------------

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
    {ok, SupPid} = mgeel_sup:start_link(),
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
       {"MGEEL Account Server",
        fun() ->
                mgeel_account_server:start()
        end},
       {"MGEEL Key Server",
        fun () ->
                mgeel_key_server:start()
        end},
       {"MGEEL Stat Server",
        fun () ->
                mgeel_stat_server:start()
        end},
       {"MGEEL Line Server",
        fun() ->
                mgeel_line:start()
        end},
       {"S2S server", 
        fun() ->
                [S2SPort] = common_config_dyn:find(common, s2s_port),
                io:format("start, s2s_port: ~w", [S2SPort]),
                mgeel_s2s:start(S2SPort)
        end},
       {"MGEEL GM Server",
        fun() ->
                mgeel_gm_server:start()
        end}
	  ]
	  ),
    ?SYSTEM_LOG("~ts~n", ["mgeel启动成功"]),
    {ok, SupPid}.

%% --------------------------------------------------------------------
stop(_State) ->
    ok.

