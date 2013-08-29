%%%----------------------------------------------------------------------
%%% File    : mgeed.erl
%%% Author  : Liangliang
%%% Purpose : MGEE application
%%% Created : 2010-01-01
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeed).

-behaviour(application).

-include("common.hrl").

-export([
	 start/2,
	 stop/1,
	 start/0,
	 stop/0
        ]).


-export([]).


-define(APPS, [mgeed]).

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
start(_Name, []) ->
    {ok, SupPid} = mgeed_sup:start_link(),
    lists:foreach(
      fun ({Msg, Thunk}) ->
              io:format("starting ~-40s ...", [Msg]),
              Thunk(),
              io:format("done~n");
          ({Msg, M, F, A}) ->
              io:format("starting ~-40s ...", [Msg]),
              apply(M, F, A),
              io:format("done~n")
      end,
      [
       {"Mysql Server",
        fun() ->
                MiniPoolSize = mod_mysql:get_mini_pool_size(),
                mod_mysql:start(MiniPoolSize)
        end},
       {"DB Cache Server",
        fun() ->
                mgeed_dict_persistent:start()
        end},
       {"Mnesia table Init",
        fun () ->
                mgeed_mnesia:init()
        end}
      ]),
    ?SYSTEM_LOG("~ts~n", ["mgeed启动成功"]),
    {ok, SupPid}.


stop(_State) ->
    ok.


