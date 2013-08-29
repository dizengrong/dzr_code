%% @author author <author@example.com>
%% @copyright YYYY author.

%% @doc TEMPLATE.

-module(mgeeweb).
-author('author <author@example.com>').

-include("common.hrl").

-export([start/0, stop/0]).

ensure_started(App) ->
    case application:start(App) of
        ok ->
            ok;
        {error, {already_started, App}} ->
            ok
    end.

%% @spec start() -> ok
%% @doc Start the mgeeweb server.
start() ->
    mgeeweb_deps:ensure(),
    ensure_started(crypto),
    application:start(mgeeweb),
    ?SYSTEM_LOG("~ts~n", ["mgeeweb启动成功"]),
    ok.

%% @spec stop() -> ok
%% @doc Stop the mgeeweb server.
stop() ->
    Res = application:stop(mgeeweb),
    application:stop(crypto),
    Res.
