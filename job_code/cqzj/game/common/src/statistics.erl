%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 15 Sep 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(statistics).

-include("mnesia.hrl").

%% API
-export([
         loop/0,
         register_as_key_process/1,
         get/1,
         help/0
        ]).


loop() ->
    print_runqueue(),
    print_messages(),
    timer:sleep(2000),
    loop().

help() ->
    ok.

%%获取当前在线的玩家数量
get(online) ->
    ok;
%%获取各个地图的玩家数量
get(map_online) ->
    ok;
%%获取某个地图的玩家数量
get({map_online, _MapID}) ->
    ok;
%%获取每个节点的runqueue信息
get(runqueue) ->
    ok;
%%获取关键进程的消息队列长度
get(messages) ->
    ok;
%%获取关键进程的内存占用
get(memory) ->
    ok.


print_runqueue() ->
    Result = get_runqueue(),
    io:format("~-30s | ~20s ~n", ["---node---", "---run_queue---"]),
    lists:foreach(
      fun({Node, RunQueue}) ->
              io:format("~-30w | ~20s ~n", [Node, erlang:integer_to_list(RunQueue)])
      end, Result).

get_messages() ->
    List = get_key_process_list(),
    lists:foldl(
      fun(#r_key_process{name=GlobalName, node=Node}, Acc) ->
              case global:whereis_name(GlobalName) of
                  undefined ->
                      io:format("~n key process : ~p [~p] down ~n", [GlobalName, Node]),
                      mnesia:dirty_delete(?DB_KEY_PROCESS, GlobalName);
                  PID ->
                      {_, ML} = rpc:call(Node, erlang, process_info, [PID, message_queue_len]),
                      [{Node, GlobalName, ML} | Acc]
              end
      end, [], List).

print_messages() ->
    io:format("~-30s | ~20s | ~30s ~n", ["--- node ---", "--- global name ---", "--- message queue len ---"]),
    List = get_messages(),
    lists:foreach(
      fun({Node, GlobalName, ML}) ->
              io:format("~-30w | ~20s | ~30s ~n", [Node, GlobalName, erlang:integer_to_list(ML)])
      end, List).
    


%%获取系统中各个节点的队列信息
get_runqueue() ->
    lists:foldl(
      fun(Node, Acc) ->
              Run = rpc:call(Node, erlang, statistics, [run_queue]),
              [{Node, Run} | Acc]
      end, [], nodes()).


get_key_process_list() ->
    mnesia:dirty_match_object(?DB_KEY_PROCESS, #r_key_process{_='_'}).


%%将某个进程注册到系统关键进程列表中去
register_as_key_process(GlobalName) ->
    mnesia:dirty_write(?DB_KEY_PROCESS, #r_key_process{name=GlobalName, node=erlang:node()}),
    ok.

