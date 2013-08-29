%%%----------------------------------------------------------------------
%%% File    : mgeer.erl
%%% Author  : xierongfeng
%%% Created : 2013-01-04
%%% Description: 
%%%----------------------------------------------------------------------

-module(mgeer).

-behaviour(application).
-include("mgeer.hrl").
-export([
	 start/2,
	 stop/1,
	 start/0,
	 stop/0
        ]).

-define(APPS, [mgeer]).

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
    {ok, SupPid} = mgeer_sup:start_link(),
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
      [{"QQ CACHE",
      fun() ->
          mod_qq_cache:init()
      end}
      ]),
    ?SYSTEM_LOG("~ts~n", ["mgeer启动成功"]),
    {ok, SupPid}.

%% --------------------------------------------------------------------
stop(_State) ->
    ok.

