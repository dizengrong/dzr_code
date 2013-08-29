%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 27 Aug 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_goal_service).

%% API
-export([
         get/3
        ]).

-include("mgeeweb.hrl").

-define(ENABLE_GOAL_LIST, [10001, 10002, 10003, 10004, 10005, 10006, 10011, 10012, 10013, 10014,10015, 10021, 10022, 10023, 10024, 10025, 
                          10031, 10032, 10033, 10034, 10035, 10041, 10042, 10043, 10044, 10051, 10052, 10053, 10054,
                          10061, 10062, 10063, 10071, 10072, 10073, 10081, 10082, 10083, 10091, 10092, 10093]).

get("/import" ++ _, Req, _) ->
    do_import(Req);

get(_, Req, _) ->
    Req:not_found().

%% 导出传奇目标信息到mysql，先清空表， Todo 优化成批量插入
do_import(Req) ->
    common_config_dyn:init(goal),
    mod_mysql:update("truncate table t_role_goal_info"),
    lists:foreach(
      fun(#p_role_goal{role_id=RoleID, goals=Goals, days=Days}) ->
              RemainGoals = 
                  lists:foldl(
                    fun(#p_role_goal_item{goal_id=GoalID, finished=Finished, fetched=Fetched}, Acc) ->
                            case common_config_dyn:find(goal, GoalID) of
                                [#p_goal_config{day=NeedDay}] ->
                                    DbTable = t_role_goal_info, 
                                    FieldNames = [role_id, goal_id, finished, fetched, need_days, current_days],
                                    case Finished of
                                        true ->
                                            Finish = 1;
                                        false ->
                                            Finish = 0
                                    end, 
                                    case Fetched of
                                        true ->
                                            Fetch = 1;
                                        false ->
                                            Fetch = 0
                                    end, 
                                    SubBatchFieldVals = [[RoleID, GoalID, Finish, Fetch, NeedDay, Days]],
                                    mod_mysql:update({esql, {insert,DbTable, FieldNames,SubBatchFieldVals }});
                                [] ->
                                    ignore
                            end,
                            lists:delete(GoalID, Acc)
                    end, ?ENABLE_GOAL_LIST, Goals),
              RemainGoals2 = lists:foldl(
                              fun(GoalID, Acc) ->
                                      case common_config_dyn:find(goal, GoalID) of 
                                          [] ->
                                              lists:delete(GoalID, Acc);
                                          _ ->
                                              Acc
                                      end
                              end, RemainGoals, RemainGoals),
              lists:foreach(
                fun(GoalID) ->
                        DbTable = t_role_goal_info, 
                        FieldNames = [role_id, goal_id, finished, fetched, need_days, current_days],
                        [#p_goal_config{day=NeedDay}] = common_config_dyn:find(goal, GoalID),
                        SubBatchFieldVals = [[RoleID, GoalID, 0, 0, NeedDay, Days]],
                        mod_mysql:update({esql, {insert,DbTable, FieldNames,SubBatchFieldVals }})
                end, RemainGoals2),
              ok
      end, db:dirty_match_object(db_role_goal_p, #p_role_goal{_='_'})),
    mgeeweb_tool:return_json_ok(Req).

