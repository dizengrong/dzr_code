%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2011, 
%%% @doc
%%%
%%% @end
%%% Created : 10 Jan 2011 by  <>
%%%-------------------------------------------------------------------
-module(hook_map_server_npc).

%% API
-export([be_attacked/3]).

-include("mgeem.hrl").

%%%===================================================================
%%% API
%%%===================================================================

%% @doc Npc被攻击，被本国玩家攻击会灰名
be_attacked(NpcID, SActorID, SActorType) ->
    case mod_map_actor:get_actor_mapinfo(NpcID, server_npc) of
        undefined ->
            ignore;
        NpcMapInfo ->
            mod_gray_name:change(NpcMapInfo, SActorID, SActorType)
    end.

%%%===================================================================
%%% Internal functions
%%%===================================================================
