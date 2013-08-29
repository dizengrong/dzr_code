%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 14 Nov 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_warofking).

-include("common.hrl").

%% API
-export([
         set_begin_war/1,
         set_end_war/1,
         is_begin_war/1
        ]).


%%王座争霸战尚未开始报名
-define(WAROFKING_STATUS_NOT_BEGIN, 0).
%%王座争霸战正在进行中
-define(WAROFKING_STATUS_BEGIN_WAR, 1).



%%判断王座争霸战是否已经开始了
is_begin_war(FactionID) ->
    case db:dirty_read(?DB_WAROFKING, FactionID) of
        [#db_warofking{status=?WAROFKING_STATUS_BEGIN_WAR}] ->
            true;
        _ ->
            false
    end.

set_begin_war(FactionID)->
    R2 = #db_warofking{faction_id=FactionID, status=?WAROFKING_STATUS_BEGIN_WAR},
    db:dirty_write(?DB_WAROFKING,R2).

set_end_war(FactionID)->
    R2 = #db_warofking{faction_id=FactionID, status=?WAROFKING_STATUS_NOT_BEGIN},
    db:dirty_write(?DB_WAROFKING,R2).

