%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 24 Nov 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_npc).

%% API
-export([
         get_family_ybc_npc_pos/0,
         get_family_publish_npc_pos/0,
         get_family_ybc_publish_pos/1
        ]).


%% 获取宗族拉镖交镖NPC的坐标：边城 蓝玉
get_family_ybc_npc_pos() ->
    [NpcPos] = common_config_dyn:find(server_pos,family_ybc_commiter),
    NpcPos.


%% 获取宗族接镖的NPC的位置
get_family_publish_npc_pos() ->
    [NpcPos] = common_config_dyn:find(server_pos,family_ybc_publisher),
    NpcPos.

%% 获取宗族接镖的NPC的位置与地图
get_family_ybc_publish_pos(_FactionID) ->
    NpcPos = get_family_publish_npc_pos(),
    {10260, NpcPos}.