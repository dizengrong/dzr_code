%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 16 Dec 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeem_slave).

%% API
-export([start/0]).

start() ->
    {ok, [[MasterNodeTmp]]} = init:get_argument(master_node),
    MasterNode = erlang:list_to_atom(MasterNodeTmp),
    net_kernel:connect_node(MasterNode),
    erlang:process_flag(trap_exit, true),
    erlang:monitor_node(MasterNode, true),
    timer:sleep(2000),
    global:send(lists:concat(["master_", MasterNode]), {slave_started, erlang:node()}),
    loop(MasterNode).

loop(MasterNode) ->
    receive 
        {nodedown, MasterNode} ->
            do_reconnect(MasterNode);
        _ ->
            loop(MasterNode)
    end.

do_reconnect(MasterNode) ->
    timer:sleep(1000),
    case net_kernel:connect_node(MasterNode) of
        false ->
            do_reconnect(MasterNode);
        _ ->
            loop(MasterNode)
    end.
