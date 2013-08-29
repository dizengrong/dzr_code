%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     运维瑞士军刀，for map
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mt_map).

%%
%% Include files
%%
-include("common.hrl").

-compile(export_all).
-define( DEBUG(F,D),io:format(F, D) ).

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%
get_db_map_list()->
    Pattern = #r_map_online{_='_'},
    db:dirty_match_object(db_map_online,Pattern).

stat_map_by_id(SpecMapId) when is_integer(SpecMapId)->
    lists:foldl(fun(E,Acc)->
                     #r_map_online{map_id=MapId}=E,
                     case MapId of
                         SpecMapId->
                             acc_by_key(MapId,Acc);
                         _ ->
                             Acc
                     end
                 end , [], get_db_map_list()).
stat_map_by_id()->
    lists:foldl(fun(E,Acc)->
                     #r_map_online{map_id=MapId}=E,
                     acc_by_key(MapId,Acc)
                 end , [], get_db_map_list()).

stat_map_by_node()->
    lists:foldl(fun(E,Acc)->
                     #r_map_online{node=Node}=E,
                     acc_by_key(Node,Acc)
                 end , [], get_db_map_list()).
stat_map_by_node2()->
    lists:foldl(fun(E,Acc)->
                     #r_map_online{map_id=MapId,node=Node}=E,
                     Key = {Node,MapId},
                     acc_by_key(Key,Acc)
                 end , [], get_db_map_list()).

%%根据key进行统计
acc_by_key(Key,Acc)->
    case lists:keyfind(Key, 1, Acc) of
        false->
            [{Key,1}|Acc];
        {_,N} ->
            lists:keystore(Key, 1, Acc, {Key,N+1})
    end.


