%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 18 Nov 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_event).

-include("common_server.hrl").
-include("common.hrl").

%% API
-export([
         get_country_treasure_config/3,
         in_warofcity/0,
         check_is_waroffaction_time/0,
         check_is_warofking_time/0
        ]).

%% 当前是否处于地图争夺战期间
in_warofcity() ->
    true.

%% 检查是否国战时间  
check_is_waroffaction_time()->
    case db:dirty_read(?DB_WAROFFACTION, 1) of
        []->
            false;
        _->
            true
    end.

%% 检查是否国王争夺战时间
check_is_warofking_time()->
    case common_time:weekday() of
        6->
            WOKConfig = common_config:get_warofking_config(),
            {
             {apply_begin_time, {ApplyBeginTimeHour, ApplyBeginTimeMin}},
             {apply_time, ApplyTime},
             {safe_time, SafeTime},
             {war_time, WarTime}
            } = WOKConfig,
            {H,M,S} = erlang:time(),
            TodaySecond = H*60*60 + M*60 + S,
            WOKStartTime = ApplyBeginTimeHour*60*60 + ApplyBeginTimeMin*60 + ApplyTime,
            WOKEndTime = WOKStartTime + SafeTime + WarTime,
            TodaySecond>WOKStartTime andalso TodaySecond<WOKEndTime;
        _->
            false
    end.


get_country_treasure_config(OpType,StartSeconds,NKeepInterval) ->
    NowSeconds = common_tool:now(),
    {NowDate,_NowTime} = common_tool:seconds_to_datetime(NowSeconds),
    TodayWeek = calendar:day_of_the_week(NowDate),
    EndSeconds = StartSeconds + NKeepInterval * 60,
    Name = country_treasure,
    NameFilePath = common_config:get_map_config_file_path(Name),
    {ok,NameDataList} = file:consult(NameFilePath),
    NameDataList2 = 
        case OpType of
            start ->
                lists:foldl(
                  fun({Key,Value},Acc) ->
                          case Key of
                              open_times ->
                                  Value2 = 
                                      lists:foldl(
                                        fun({Week,TimeList},AccValue) ->
                                                if Week =:= TodayWeek ->
                                                        {_NowDate,StartTime} = common_tool:seconds_to_datetime(StartSeconds),
                                                        {_NowDate,EndTime} = common_tool:seconds_to_datetime(EndSeconds),
                                                        TimeList2 =[{StartTime,EndTime}],
                                                        [{Week,TimeList2}|AccValue];
                                                   true ->
                                                        [{Week,TimeList}|AccValue]
                                                end
                                        end,[],Value),
                                  io:format("open_times=~p~n",[Value2]),
                                  [{Key,Value2}|Acc];
                              open_day_flag ->
                                  Value2 = false,
                                  [{Key,Value2}|Acc];
                              _ ->
                                  [{Key,Value}|Acc]
                          end
                  end,[],NameDataList);
            reset ->
                NameDataList
        end,
    {ok,Name,NameDataList2}.

