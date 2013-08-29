%%%----------------------------------------------------------------------
%%% File    : mgeeb.erl
%%% Author  : Liangliang
%%% Created : 2010-06-28
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeeb).

-behaviour(application).

-include("common.hrl").

-export([
	 start/2,
	 stop/1,
	 start/0,
	 stop/0
        ]).

-define(APPS, [mgeeb]).

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
    {ok, SupPid} = mgeeb_sup:start_link(),
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
       {"Behavior Logger",
        fun() ->
                error_logger:add_report_handler(common_logger_h, ""),
                {ok, LogLevel} = application:get_env(log_level),
                common_loglevel:set(LogLevel)
        end},
       {"Behavior Logger Writter",
        fun() ->
                behavior_serverlog:start()
        end},
       {"Cache Server",
        fun() ->
                behavior_cache_server:start(mgeeb_sup)
        end},
       {"Behavior Server",
        fun() ->
                try 
                    behavior_server:start()
                catch
                    _:Reason ->
                        io:format(
                          "~w;~w~n", 
                          ["Behavior Server Start Catch Exception", Reason]
                         )
                end
        end}
      ]
    ),
    ?SYSTEM_LOG("~ts~n", ["mgeeb启动成功"]),
    {ok, SupPid}.

%% --------------------------------------------------------------------
stop(_State) ->
    ok.


