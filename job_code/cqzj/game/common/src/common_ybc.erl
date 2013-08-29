%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 22 Nov 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_ybc).

-include("common.hrl").
%% API
-export([
         update_mapinfo/2,
         get_pos/1,
         get_ybc_commit_mapid/1,
		 get_family_ybc_reward/1
        ]).

get_pos(YbcID) ->
    [#r_ybc{pos=Pos, map_id=MapID}] = db:dirty_read(?DB_YBC, YbcID),
    {MapID, Pos}.

update_mapinfo(YbcID, YbcInfo) ->
    MapID = YbcInfo#r_ybc.map_id,
    common_map:info(common_map:get_common_map_name(MapID), {mod_map_ybc, {update_ybc_map_info, YbcID, YbcInfo}}).

get_ybc_commit_mapid(1) ->
    11105;
get_ybc_commit_mapid(2) ->
    12105;
get_ybc_commit_mapid(3) ->
    13105.

%%家族镖车获得的奖励钱币
get_family_ybc_reward(Level) ->
    case common_config_dyn:find(family_ybc_money, Level) of
        [] ->
            99999999999;
        [#p_family_ybc_money{reward_silver=Silver}] ->
			Silver
    end.
