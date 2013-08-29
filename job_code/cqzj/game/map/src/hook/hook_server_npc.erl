%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 15 Aug 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(hook_server_npc).

-include("mgeem.hrl").

%% API
-export([
         dead/4
        ]).

%%%===================================================================
%%% API
%%%===================================================================
dead(_ActorType,ServerNpcID, ServerNpcTypeID, _ActorID) ->
    mod_warofmonster:hook_server_npc_dead(ServerNpcID, ServerNpcTypeID),
    mod_guard_fb:hook_server_npc_dead(ServerNpcID, ServerNpcTypeID),
%%     case mod_waroffaction:check_in_waroffaction_time() of
%%         true ->
%%             catch mod_waroffaction:waroffaction_npc_dead(ServerNpcTypeID,ServerNpcID,RoleID),
%%             catch mod_waroffaction:add_waroffaction_npc_gongxun(RoleID, ServerNpcTypeID);
%%         false ->
%%             ignore
%%     end,
    ok.
