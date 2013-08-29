%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 25 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_lists).

%% API
-export([
         implode/2
        ]).

implode(List, Glue) ->
    L2 = lists:foldl(
           fun(Ele, Acc) ->
                   case Acc of
                       [] ->
                           [Ele];
                       _ ->
                           lists:concat([Acc, Glue, common_tool:to_list(Ele)])
                   end
           end, [], List),
    lists:flatten(L2).


