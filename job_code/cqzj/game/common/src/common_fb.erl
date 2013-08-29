%%%-------------------------------------------------------------------
%%% @author  bisonwu
%%% @copyright (C) 2010, 
%%% @doc
%%%     副本的常用方法
%%% @end
%%% Created : 23 Nov 2010 by  <>
%%%-------------------------------------------------------------------
-module(common_fb).
-include("common.hrl").

-export([
         get_next_fb_open_time/1,
         get_next_fb_open_time_daily/2
        ]).


%%--------------------------------  定时战场的代码，可复用  [start]--------------------------------


%%@doc 重新设置下一次战场时间
%%@return {ok,NextStartTimeSeconds}
get_next_fb_open_time(ConfigName) when is_atom(ConfigName)->
    [OpenTimes] = common_config_dyn:find(ConfigName,open_times),
    case OpenTimes of
        {daily,DailyOpenTimes}->
            update_next_fb_open_time(daily,ConfigName,DailyOpenTimes);
        {weekly,WeeklyOpenTimes}->
            update_next_fb_open_time(weekly,ConfigName,WeeklyOpenTimes);
        _ ->
            {error,config_err}
    end.

%%@return {ok,Date,StartTimeSeconds,EndTimeSeconds,NextBcStartTime,NextBcEndTime,NextBcProcessTime,
%%                 BeforeInterval,CloseInterval,ProcessInterval}
update_next_fb_open_time(OpenType,ConfigName,OpenTimesList) when is_atom(ConfigName),is_list(OpenTimesList)->
    NowSeconds = common_tool:now(),
    {ok,Date,StartTimeSeconds,EndTimeSeconds} = 
        case OpenType of
            daily->
                get_next_fb_open_time_daily(NowSeconds,OpenTimesList);
            weekly->
                get_next_fb_open_time_weekly(NowSeconds,OpenTimesList)
        end,
    {NextBcStartTime,NextBcEndTime,NextBcProcessTime,
     BeforeInterval,CloseInterval,ProcessInterval} =
        get_next_bc_times(ConfigName,NowSeconds,StartTimeSeconds,EndTimeSeconds),
    {ok,Date,StartTimeSeconds,EndTimeSeconds,NextBcStartTime,NextBcEndTime,NextBcProcessTime,
     BeforeInterval,CloseInterval,ProcessInterval}.

%%@return {ok,Date,StartSeconds,EndSeconds} || {error,not_found)
get_next_fb_open_time_daily(Now,DailyOpenTimes)->
    NowDate = erlang:date(),
    case get_next_fb_open_time_today(NowDate,Now,DailyOpenTimes) of
        {error,not_found}->
            {NextDate,_} = common_tool:seconds_to_datetime(Now+3600*24), %% tomorrow
            get_next_fb_open_time_tomorrow(NextDate,DailyOpenTimes);
        {ok,StartSeconds,EndSeconds}->
            {ok,NowDate,StartSeconds,EndSeconds}
    end.

get_next_fb_open_time_weekly(NowSeconds,OpenTimesList)->
    NowDate = erlang:date(),
    TodayWeek = calendar:day_of_the_week(NowDate),
    case lists:keyfind(TodayWeek,1,OpenTimesList) of
        false ->
            get_next_fb_open_time_otherdate(NowSeconds,TodayWeek,OpenTimesList);
        {TodayWeek,TodayTimeList} ->
            case get_next_fb_open_time_today(NowDate,NowSeconds,TodayTimeList) of
                {error,not_found}->
                    get_next_fb_open_time_otherdate(NowSeconds,TodayWeek,OpenTimesList);
                {ok,StartSeconds,EndSeconds}->
                    {ok,NowDate,StartSeconds,EndSeconds}
            end
    end.

get_next_weekday_2(_,[],SrcWeekDayList)->
    [H|_T] = SrcWeekDayList,
    H;
get_next_weekday_2(TodayWeek,[H|T],SrcWeekDayList)->
    case H>TodayWeek of
        true-> H;
        _ ->
            get_next_weekday_2(TodayWeek,T,SrcWeekDayList)
    end.

get_next_fb_open_time_otherdate(Now,TodayWeek,OpenTimesList)->
    WeekDayList = [ Wk||{Wk,_}<-OpenTimesList ],
    NextWeekDay =
        case WeekDayList of
            [OnlyOneDay]->
                OnlyOneDay;
            _ ->
                get_next_weekday_2(TodayWeek,WeekDayList,WeekDayList)
        end,
    {_,DailyOpenTimes} = lists:keyfind(NextWeekDay,1,OpenTimesList),
    if
        NextWeekDay>TodayWeek->
            {NextDate,_} = common_tool:seconds_to_datetime(Now+3600*24*(NextWeekDay-TodayWeek));
        true->
            {NextDate,_} = common_tool:seconds_to_datetime(Now+3600*24*(7+NextWeekDay-TodayWeek))
    end,
    get_next_fb_open_time_tomorrow(NextDate,DailyOpenTimes).

%%@return {ok,StartSeconds,EndSeconds}
get_next_fb_open_time_today(_NowDate,_NowSeconds,[])->
    {error,not_found};
get_next_fb_open_time_today(NowDate,NowSeconds,[H|T])->
    {StartTimeConf,EndTimeConf} = H,
    StartSeconds = common_tool:datetime_to_seconds({NowDate,StartTimeConf}),
    EndSeconds = common_tool:datetime_to_seconds({NowDate,EndTimeConf}),
    if NowSeconds >= StartSeconds andalso NowSeconds < EndSeconds ->
           {ok,StartSeconds,EndSeconds};
       StartSeconds >=  NowSeconds ->
           {ok,StartSeconds,EndSeconds};
       true ->
           get_next_fb_open_time_today(NowDate,NowSeconds,T)
    end.

%%@return {ok,NextDate,StartSeconds,EndSeconds}
get_next_fb_open_time_tomorrow(NextDate,DailyOpenTimes)->
    [{StartTimeConf,EndTimeConf}|_T] = DailyOpenTimes,
    StartSeconds = common_tool:datetime_to_seconds( {NextDate,StartTimeConf} ),
    EndSeconds = common_tool:datetime_to_seconds( {NextDate,EndTimeConf} ),
    {ok,NextDate,StartSeconds,EndSeconds}.
  
%% 根据副本时间和当前时间计算相应的广播时间
%% 返回 {NextBcStartTime,NextBcEndTime,NextBcProcessTime}
get_next_bc_times(ConfigName,NowSeconds,StartTime,EndTime) when is_atom(ConfigName) ->
    [{BeforeSeconds,BeforeInterval}] =  common_config_dyn:find(ConfigName,fb_open_before_msg_bc),
    [{ProcessInterval}] =  common_config_dyn:find(ConfigName,fb_open_process_msg_bc),
    NextBcStartTime = 
        if NowSeconds >= StartTime ->
                0;
           true ->
                if (StartTime - NowSeconds) >= BeforeSeconds ->
                        StartTime - BeforeSeconds;
                   true ->
                        NowSeconds
                end
        end,
    NextBcEndTime = 
        if NowSeconds >= EndTime ->
               0;
           true ->
               EndTime
        end,
    NextBcProcessTime =
        if NowSeconds > StartTime 
           andalso EndTime > NowSeconds ->
                NowSeconds;
           true ->
                if StartTime =/= 0 ->
                        StartTime;
                   true ->
                        0
                end
        end,
    CloseInterval = 0,
    {NextBcStartTime,NextBcEndTime,NextBcProcessTime,
     BeforeInterval,CloseInterval,ProcessInterval}.

%%--------------------------------  定时战场的代码，可复用  [end]--------------------------------
