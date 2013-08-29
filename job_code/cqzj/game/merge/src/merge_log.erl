%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 17 Jul 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(merge_log).

%% API
-export([
         start_log_server/2
        ]).

-define(LOG_FILE, "/data/logs/cqzj_merge.log").

%%%===================================================================
%%% API
%%%===================================================================

start_log_server(GlobalName, PID) ->
    os:cmd("echo '' > /data/logs/cqzj_merge.log"),
    global:register_name(GlobalName, erlang:self()),
    erlang:send(PID, log_server_started),
    loop_log_server().

loop_log_server() ->
    receive 
        {log, Module, Line, Time, Format, Args} ->
            do_write_log(Module, Line, Time, Format, Args);
        R ->
            M = io_lib:format("~ts:~p", ["收到未知消息", R]),
            file:write_file(?LOG_FILE, M, [append, delayed_write]),
            ok
    end,
    loop_log_server().

do_write_log(Module, Line, Time, Format, Args) ->
    {{Y,Mo,D},{H,Mi,S}} = Time,
    Time2 = io_lib:format("==== ~w-~.2.0w-~.2.0w ~.2.0w:~.2.0w:~.2.0w === ~10s:~.5.0w",
                          [Y, Mo, D, H, Mi, S, Module, Line]),
    L2 = lists:concat(["merge_log ", Time2]),
    B = unicode:characters_to_binary(L2),
    file:write_file(?LOG_FILE, B, [append, delayed_write]),
    try 
        M = io_lib:format(Format, Args),
        file:write_file(?LOG_FILE, M, [append, delayed_write])
    catch _:Error ->
            io:format("log error ~p ~p ~p", [Error, Format, Args])
    end,
    ok.
