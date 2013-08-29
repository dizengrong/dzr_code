%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @doc 撤机辅助工具
%%%
%%% @end
%%% Created : 10 Jul 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_cheji).

-include("common_server.hrl").

-include("common.hrl").

%% API
-export([
         reset_db_schema/0
        ]).

%%%===================================================================
%%% API
%%%===================================================================

%% 多台机器合并为一台机器时，schema文件必须重新生成
reset_db_schema() ->
    %% 首先需要启动mnesia
    io:format("~s~n", ["prepare to start..."]),
    mnesia:start(),
    common_loglevel:set(3),
    common_config_dyn:reload(common),
    MnesiaDir = mnesia:system_info(directory),
    case file:read_file_info(MnesiaDir++"/schema.dat") of
        {ok, _} ->
            io:format("~s~n", ["wrong mnesia dir " ++ MnesiaDir]),
            init:stop();
        _ ->
            os:cmd(lists:flatten(lists:concat(["rm -rf ", MnesiaDir]))),
            ignore
    end,
    io:format("~s~n", ["prepare to init mnesia table"]),
    mgeed_mnesia:init(),
    mnesia:dump_log(),
    mnesia:stop(),
    TargetMnesiaDIR = common_config:get_mnesia_dir(),
    R = os:cmd(lists:flatten(lists:concat(["mv -f ", MnesiaDir, "/schema.DAT ", TargetMnesiaDIR]))),
    io:format("~p~n", [R]),
    case R of
        [] ->
            os:cmd(lists:flatten(lists:concat(["rm -rf ", MnesiaDir]))),
            io:format("cheji ok ~n");
        _ ->
            io:format("cheji error ~p~n", [R])
    end,
    init:stop().
    

