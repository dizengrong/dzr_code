%% Author: chixiaosheng
%% Created: 2011-4-20
%% Description:  mod_mission_handler
-module(mod_mission_loop).

%%
%% Include files
%%
-include("mission.hrl").

%%
%% Exported Functions
%%
-export([loop/0]).

-define(MISSION_RELOAD_TIME_LIST, [
    {1, {0,0}},
    {1, {1, 0}},  
    {1, {12, 0}}
]).

loop() ->
    LocalTime = calendar:local_time(),
    NowTimestamp = common_tool:now(),
    do_loop(?MISSION_RELOAD_TIME_LIST, LocalTime, NowTimestamp).

do_loop([], _, _) ->
    ignore;
do_loop([Time|List], LocalTime, NowTimestamp) ->
    case Time of
        {1, {H, M}} ->
            {NowDay, {NowH, NowM, _}} = LocalTime,
            if
                NowH =:= H andalso NowM =< M+2 ->
                    do_per_day(NowDay, {H, M});
                true ->
                    do_loop(List, LocalTime, NowTimestamp)
            end;
        _ ->
            do_loop(List, LocalTime, NowTimestamp)
    end.

do_per_day(NowDay, {H, M}) ->
    CurrentVS = mod_mission_data:get_vs(),
    if
        CurrentVS =/= {NowDay, H, M} ->
            mod_mission_data:set_vs({NowDay, H, M}),
            put(?MISSION_MAP_LOOP_ROLE_LIST, mod_map_actor:get_in_map_role());
        true ->
            RoleList = get(?MISSION_MAP_LOOP_ROLE_LIST),
            case RoleList of
                [] ->
                    ignore;
                [R1, R2, R3, R4, R5, R6, R7, R8, R9, R10|RemainList] ->
                    DealList = [R1, R2, R3, R4, R5, R6, R7, R8, R9, R10],
                    reload_role_list(DealList, CurrentVS),
                    put(?MISSION_MAP_LOOP_ROLE_LIST, RemainList);
                _ ->
                    reload_role_list(RoleList, CurrentVS),
                    put(?MISSION_MAP_LOOP_ROLE_LIST, [])
            end
    end.

reload_role_list(RoleList, VS) ->
    lists:foreach(fun(RoleID) ->
        case mod_map_role:get_role_base(RoleID) of
            {ok, _} ->
                MissionData = mod_mission_data:get_mission_data(RoleID),
                NewPInfoList = mod_mission_data:reload_role_pinfo_list(RoleID, MissionData),
                TransFun = fun()->  mod_mission_data:set_pinfo_list(RoleID, NewPInfoList, VS) end,
                case common_transaction:transaction( TransFun ) of
                    {atomic, _} ->
                        DataRecordReturn = #m_mission_list_toc{code=?MISSION_CODE_SUCC,
                                                               code_data=[], 
                                                               list=NewPInfoList},
                        mod_mission_unicast:p_unicast(RoleID, 
                                                      ?DEFAULT_UNIQUE, 
                                                      ?MISSION, 
                                                      ?MISSION_LIST, 
                                                      DataRecordReturn),
                        Line = common_misc:get_role_line_by_id(RoleID),
                        mod_mission_unicast:c_unicast(RoleID, Line);
                    Other ->
                        ?ERROR_MSG("大循环处理玩家列表更新发生系统错误-->~nRoleID:~w~n VS:~w~n Other:~w~n Stacktrace:~w~n<--", 
                                    [RoleID, 
                                     VS,
                                     Other, 
                                     erlang:get_stacktrace()])
                end;
            _ ->
                ignore
        end
    end, RoleList).