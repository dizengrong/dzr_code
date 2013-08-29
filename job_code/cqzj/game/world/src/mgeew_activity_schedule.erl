%%%-------------------------------------------------------------------
%%% @author chenrong
%%% @doc
%%%     定时活动
%%% @end
%%% Created : 2012-04-17
%%%-------------------------------------------------------------------
-module(mgeew_activity_schedule).

-behaviour(gen_server).
-include("mgeew.hrl").

-export([start/0,
         start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([admin_get_top_rank_list/1,
         admin_get_all_rank_list/1,
         admin_get_rank_info/2,
         check_can_fetch_reward/2,
         admin_open_activity/1,
         hot_update_config/0]).

-record(state, {}).

-define(PERSISTEN_TIME, 60000). 

-define(CAN_FETCH, 0).
-define(ALREADY_FETCH, 1).
-define(CAN_NOT_FETCH, 2).

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE,
                                                 {?MODULE, start_link, []},
                                                 permanent,10000, worker,
                                                 [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    %% 当游戏启动完毕后，再开始真正的初始化
    erlang:process_flag(trap_exit, true),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    %% 清空当前所有开启的活动图标通知标记
    clear_activity_event_state(),
    case get_current_open_activity_info() of
        undefined ->
            ignore;
        {ActivityID, _, _} ->
            persist_rank_data(ActivityID)
    end,
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% 因为在启动时需要写db_event_state表，标记活动开始，引起even_state表在随后map启动加载时被重置了
%% 因此暂时采取在manager_node中当所有进程启动完毕时发送消息，此时再开始初始化该进程的数据，保持表的数据一致。
do_handle_info(application_start_complete) ->
    %% 清除所有活动的图标通知标记
    clear_activity_event_state(),
    init_schedule_data(),
    erlang:send_after( 1000, self(), loop),
    erlang:send_after( ?PERSISTEN_TIME, self(), persist_rank_data),
    ok;

do_handle_info(loop) ->
    loop();
do_handle_info({update_rank_element, {ActivityID, RoleID, Info}}) ->
    case get_current_open_activity_info() of
        {OpenActivityID, _, _} when ActivityID =:= OpenActivityID ->
			[#r_activity_setting{module=ModuleName}] = common_config_dyn:find(activity_schedule, ActivityID),
			case ModuleName of
				undefined ->
					ignore;
				_ ->
					ModuleName:update(RoleID, Info)
			end;
        _ ->
            ignore
    end;

do_handle_info({info, {ActivityID, RoleID}}) ->
	case get_current_open_activity_info() of
		{OpenActivityID, StartTime, EndTime} when ActivityID =:= OpenActivityID ->
			[#r_activity_setting{module=ModuleName}] = common_config_dyn:find(activity_schedule, ActivityID),
			case ModuleName of
				undefined ->
					ignore;
				_ ->
					MyRankInfo = common_activity_rank:get_my_rank_info(ModuleName, RoleID),
					NearRankInfoList = common_activity_rank:get_near_rank_info(ModuleName, RoleID),
					Status = 
						case {db:dirty_read(?DB_ACTIVITY_RANK_REWARD_P, {ActivityID, RoleID}), MyRankInfo#r_activity_rank.is_qualified} of
							{[], true} ->
								?CAN_FETCH;
							{[#r_activity_rank_reward{last_fetch_time=LastFetchTime}], true} ->
								case check_can_fetch_reward(LastFetchTime, {StartTime, EndTime}) of
									ok ->
										?CAN_FETCH;
									already_fetch ->
										?ALREADY_FETCH;
									over_time ->
										?CAN_NOT_FETCH
								end;
							_ ->
								?CAN_NOT_FETCH
						end,
					[#r_activity_setting{qualified_value=QualifiedValue}] = common_config_dyn:find(activity_schedule, ActivityID),
					DataRecord = #m_activity_schedule_info_toc{id=ActivityID, my_rank=transformRankInfo(MyRankInfo), 
															   near_ranks=transformRankInfoList(NearRankInfoList),
															   start_time=StartTime, end_time=EndTime,
															   status=Status, qualified_score=QualifiedValue},
					common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_SCHEDULE_INFO, DataRecord)
			end;
		_ ->
			ErrorRecord = #m_activity_schedule_info_toc{error_code=?ERR_ACTIVITY_SCHEDULE_NOT_START},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_SCHEDULE_INFO, ErrorRecord)
	end,
	ok;

do_handle_info({fetch_reward, {ActivityID, RoleID}}) ->
    case get_current_open_activity_info() of
        {OpenActivityID, StartTime, EndTime} when ActivityID =:= OpenActivityID ->
            send_role_activity_rank_info(ActivityID, RoleID, StartTime, EndTime);
        _ ->
            ErrorRecord = #m_activity_schedule_fetch_toc{error_code=?ERR_ACTIVITY_SCHEDULE_FETCH_OVER_TIME},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_SCHEDULE_FETCH, ErrorRecord)
    end,
    ok;

do_handle_info(persist_rank_data) ->
    case get_current_open_activity_info() of
        undefined ->
            ignore;
        {ActivityID, _, _} ->
            persist_rank_data(ActivityID)
    end,
    erlang:send_after( ?PERSISTEN_TIME, self(), persist_rank_data),
    ok;

do_handle_info({admin_query, Msg}) ->
    do_admin_query(Msg);

do_handle_info(Info) ->
    ?ERROR_MSG("定时活动进程无法处理此消息 Info=~w",[Info]),
    ok.

%% 存储当前开启活动的信息
set_current_open_activity_info(ActivityID, StartTime, EndTime) ->
    erlang:put(active_schedule_activity, {ActivityID, StartTime, EndTime}).

get_current_open_activity_info() ->
    erlang:get(active_schedule_activity).

clear_current_open_activity_info() ->
    erlang:erase(active_schedule_activity).

%% 存储event_state
%% 服务器重启时，该值可能是过期，或是当前需开启的
%% 启动后，该值可能表示当前或是下一个开启活动的时间
set_schedule_activity_data(EventState) ->
    erlang:put(schedule_activity_data, EventState).

get_schedule_activity_data() ->
    erlang:get(schedule_activity_data).

%% 初始化活动配置数据
init_schedule_data() ->
    case common_misc:get_event_state(schedule_activity) of
        {ok, #r_event_state{data=Data}} ->
            %%需检查配置，检查记录中的seqId, ActivityID跟配置是否一致
            check_and_validate_event_state(Data);
        _ ->
            ignore
    end,
    ok.

check_and_validate_event_state(Data) ->
    [SeqList] = common_config_dyn:find(activity_schedule, seq_list),
	case SeqList of
        [] ->
            ignore;
        _ ->
            case lists:keyfind(Data#r_schedule_data.seq_id, 1, SeqList) of
                false ->
                    set_up_next_schedule_activity(Data);
                {_SeqID, ActivityID} ->
                    set_schedule_activity_data(Data#r_schedule_data{activity_id=ActivityID})
            end
    end.

loop() ->
    erlang:send_after( 1000, self(), loop),
    [SeqList] = common_config_dyn:find(activity_schedule, seq_list),
    case SeqList of
        [] -> 
            ignore;
        _ -> 
             OpenDays = common_config:get_opened_days(),
            [ActivityOpenDay] = common_config_dyn:find(activity_schedule, open_day),
            case OpenDays > ActivityOpenDay andalso erlang:length(SeqList) > 0 of
                true ->
                    case get_schedule_activity_data() of
                        undefined ->
                            [{SeqID, ActivityID} | _T] = SeqList,
                            {StartTime, EndTime} = calc_activity_time(ActivityID),
                            ScheduleData = #r_schedule_data{seq_id=SeqID, activity_id=ActivityID, start_time=StartTime, end_time=EndTime},
                            init_activity_data(ScheduleData);
                        ScheduleData ->
                            init_activity_data(ScheduleData)
                    end;
                false ->
                    ignore
            end
    end.

%% 以当天的10：00 至 3天后的9：59：50
calc_activity_time(ActivityID) ->
	[OpenTimeSectionList] = common_config_dyn:find(activity_schedule, open_time_section),
	case lists:keyfind(ActivityID,1, OpenTimeSectionList) of
		{_,OpenTimeList} ->
			{StartDate,EndDate} = get_activity_time(time(),OpenTimeList),
			StartTime = common_tool:datetime_to_seconds({date(),StartDate}),
			EndTime = common_tool:datetime_to_seconds({date(),EndDate});
		_ ->
			[OpenTime] = common_config_dyn:find(activity_schedule, open_time),
			StartTime = common_tool:datetime_to_seconds({date(), OpenTime}),
			[ContinueDays] = common_config_dyn:find(activity_schedule, continuous_days),
			EndTime = common_tool:datetime_to_seconds({common_time:add_days(date(), ContinueDays), OpenTime}) - 10
	end,
	{StartTime, EndTime}.

get_activity_time(CurrentTime,[H|T]) ->
	{_,EndDate} = H,	
	if
		CurrentTime =< EndDate ->
			H;
		true ->
			if
				T =:= [] ->
					H;
				true ->
					get_activity_time(CurrentTime,T)
			end
	end.
	
	
	
init_activity_data(ScheduleData) ->
    Now = common_tool:now(),
    #r_schedule_data{activity_id=ActivityID, start_time=StartTime, end_time=EndTime} = ScheduleData,
    CurrentOpenActivityInfo = get_current_open_activity_info(),
    if CurrentOpenActivityInfo =:= {ActivityID, StartTime, EndTime} andalso
           Now >= StartTime andalso EndTime >= Now ->
           %% 已经开始
           ignore;
       Now >= StartTime andalso EndTime >= Now ->
           %% 开始
           ?ERROR_MSG("activity_schedule start ~w", [{ActivityID, StartTime, EndTime}]),
           init_module_data(ScheduleData);
       Now > EndTime andalso 
           CurrentOpenActivityInfo =:= {ActivityID, StartTime, EndTime} ->
           %% 结束
           ?ERROR_MSG("activity_schedule end activity_id: ~w, time : ~w", [ActivityID, EndTime]),
           close_schedule_activity(ActivityID);
       Now > EndTime ->
           set_up_next_schedule_activity(ScheduleData);
       StartTime > Now ->
           ignore;
       true ->
           ignore
    end,
    ok.
-define(ACTIVITY_MODULE_INT(Module,Act,ScheduleSetting),case Module of  undefined -> ignore;_ -> Module:init(Act, ScheduleSetting) end).
init_module_data(ScheduleData) ->
    #r_schedule_data{activity_id=ActivityID, start_time=StartTime, end_time=EndTime} = ScheduleData,
    [ScheduleSetting] = common_config_dyn:find(activity_schedule, ActivityID),
    #r_activity_setting{module=Module} = ScheduleSetting,
    %% 比较服务器存取的event_state时间是否与当前即将开启的时间是一致的
    case common_misc:get_event_state(schedule_activity) of
        {ok, #r_event_state{data=EventData}} ->
            case compare_schedule_data(EventData, ScheduleData) of
                the_same ->
                    ?ERROR_MSG("activity_schedule init load", []),
                   %% Module:init(load, ScheduleSetting);
					?ACTIVITY_MODULE_INT(Module,load,ScheduleSetting);
                not_the_same ->
                    ?ERROR_MSG("activity_schedule init clear 1", []),
                   %% Module:init(clear, ScheduleSetting)
					?ACTIVITY_MODULE_INT(Module,clear,ScheduleSetting)
            end;
        _ ->
            ?ERROR_MSG("activity_schedule init clear 2", []),
            %%Module:init(clear, ScheduleSetting)
			?ACTIVITY_MODULE_INT(Module,clear,ScheduleSetting)
    end,
    set_current_open_activity_info(ActivityID, StartTime, EndTime),
    set_schedule_activity_data(ScheduleData),
    common_misc:set_event_state(schedule_activity, ScheduleData),
    notify_activity_start(ActivityID, StartTime, EndTime).

compare_schedule_data(ScheduleData1, ScheduleData2) ->
    if ScheduleData1 =:= undefined orelse ScheduleData2 =:= undefined ->
           not_the_same;
       true ->
           #r_schedule_data{activity_id=ActivityID1, start_time=StartTime1, end_time=EndTime1} = ScheduleData1,
           #r_schedule_data{activity_id=ActivityID2, start_time=StartTime2, end_time=EndTime2} = ScheduleData2,
           if StartTime1 =:= StartTime2 andalso EndTime1 =:= EndTime2 andalso ActivityID1 =:= ActivityID2 ->
                  the_same;
              true ->
                  not_the_same
           end
    end.

close_schedule_activity(ActivityID) ->
    clear_current_open_activity_info(),
    notify_activity_end(ActivityID),
    %% 活动结束，需最后持久化最终的数据
    persist_rank_data(ActivityID),
    ok.

set_up_next_schedule_activity(ScheduleData) ->
	%%算出下一个活动开始的时间 
	case get_next_seq_data(ScheduleData) of
		undefined ->
			?ERROR_MSG("没找到内嵌活动",[]);
		{NextSeqID, NextActivityID} ->
			{NextStartTime, NextEndTime} = calc_activity_time(NextActivityID),
			NextScheduleData = #r_schedule_data{seq_id=NextSeqID, activity_id=NextActivityID, start_time=NextStartTime, end_time=NextEndTime},
			set_schedule_activity_data(NextScheduleData),
			ok
	end.

get_next_seq_data(CurrentScheduleData) ->
	[SeqList] = common_config_dyn:find(activity_schedule, seq_list),
	case SeqList of
		[] -> undefined;
		_ ->
			{LastSeqID, _} = lists:last(SeqList),
			case CurrentScheduleData#r_schedule_data.seq_id >= LastSeqID of
				true ->
					[FirstSeqData | _T] = SeqList,
					FirstSeqData;
				false ->
					[FirstSeqData | _T] = lists:filter(fun({SeqID, _}) -> SeqID > CurrentScheduleData#r_schedule_data.seq_id end, SeqList),
					FirstSeqData
			end
	end.

transformRankInfo(RankInfo) ->
    #r_activity_rank{role_id=RoleID, faction_id=FactionID, role_name=RoleName, 
                     ranking=Ranking,is_qualified=IsQualified, score=Score, value=_Value} = RankInfo,
    case FactionID =:= undefined orelse RoleName =:= undefined of
        true ->
            case db:dirty_read(?DB_ROLE_BASE, RoleID) of
                [#p_role_base{faction_id=FactionIDT, role_name=RoleNameT}] ->
                    #p_activity_rank{role_id=RoleID, faction_id=FactionIDT, role_name=RoleNameT, 
                                     is_qualified=IsQualified, ranking=Ranking, score=Score};
                _ ->
                    #p_activity_rank{role_id=RoleID, faction_id=FactionID, role_name=RoleName, 
                                     is_qualified=IsQualified, ranking=Ranking, score=Score}
            end;
        _ ->
            #p_activity_rank{role_id=RoleID, faction_id=FactionID, role_name=RoleName, 
                                     is_qualified=IsQualified, ranking=Ranking, score=Score}
    end.

transformRankInfoList(RankInfoList) ->
    lists:map(fun(RankInfo) -> transformRankInfo(RankInfo) end, RankInfoList).

notify_activity_start(ActivityID, StartTime, EndTime) ->
    common_activity:notfiy_activity_start({ActivityID, common_tool:now(), StartTime, EndTime}),
    ok.

notify_activity_end(ActivityID) ->
    common_activity:notfiy_activity_end(ActivityID),
    ok.

send_role_activity_rank_info(ActivityID, RoleID, StartTime, EndTime) ->
	[#r_activity_setting{module=ModuleName}] = common_config_dyn:find(activity_schedule, ActivityID),
	case ModuleName of
		undefined ->
			ingore;
		_ ->
			common_misc:send_to_rolemap(RoleID, {mod_activity, {activity_schedule_reward_fetch, 
																{RoleID, ActivityID, common_activity_rank:get_my_rank_info(ModuleName,RoleID),
																 StartTime, EndTime}}})
	end.

check_can_fetch_reward(LastFetchTime, {StartTime, EndTime}) ->
    EndTimeTmp = erlang:min(StartTime + 86400, EndTime),
    Now = common_tool:now(),
    if LastFetchTime > Now ->
           over_time;
       LastFetchTime >= StartTime andalso EndTimeTmp >= LastFetchTime andalso EndTimeTmp =< EndTime
           andalso Now >= StartTime andalso EndTimeTmp >= Now ->
           already_fetch;
       LastFetchTime >= EndTimeTmp andalso LastFetchTime =< EndTime ->
           check_can_fetch_reward(LastFetchTime, {EndTimeTmp, EndTime});
       LastFetchTime > EndTime ->
           over_time;
       true ->
           ok
    end.

clear_activity_event_state() ->
    [ActivityList] = common_config_dyn:find(activity_notice, open_activity),
    lists:foreach(
      fun(ActivityID) ->
              lists:foreach(fun(FactionID) -> common_misc:del_event_state({ActivityID, FactionID}) end, lists:seq(1, 3))
      end, ActivityList),
    ok.

persist_rank_data(ActivityID) ->
	case common_config_dyn:find(activity_schedule, ActivityID) of
		[#r_activity_setting{module=ModuleName}] ->
			case ModuleName of
				undefined ->
					ignore;
				_ ->
					ModuleName:persist_data()
			end;
		_ ->
			ignore
	end,
	ok.

%% ================
%% admin helper function
%% ================
do_admin_query(Msg) ->
    case Msg of
        {get_top_rank_list, ActivityID} ->
            [#r_activity_setting{module=ModuleName}] = common_config_dyn:find(activity_schedule, ActivityID),
			case ModuleName of
				undefined ->
					ignore;
				_ ->
					TopRankList = common_activity_rank:get_top_rank_list(ModuleName),
					?DBG("get_top_rank_list ~w",[TopRankList])
			end;
        {get_all_rank_list, ActivityID} ->
			[#r_activity_setting{module=ModuleName}] = common_config_dyn:find(activity_schedule, ActivityID),
			case ModuleName of
				undefiend ->
					ingore;
				_ ->
					RankList = common_activity_rank:get_rank_list(ModuleName),
					?DBG("get_all_rank_list ~w",[RankList])
			end;
        {get_rank_info, {ActivityID, RoleID}} ->
			[#r_activity_setting{module=ModuleName}] = common_config_dyn:find(activity_schedule, ActivityID),
			case ModuleName of
				undefined ->
					ignore;
				_ ->
					RankInfo = common_activity_rank:get_rank_info(ModuleName, RoleID),
					?DBG("get_rank_info ~w",[RankInfo])
			end;
        {open_activity, ActivityID} ->
            %% GM命令,只用于测试, 不能用于外服
            StartTime = common_tool:now(),
            EndTime = StartTime + 1800,
            clear_all_activity_event(),
            db:clear_table(?DB_ACTIVITY_RANK_REWARD_P),
            NextScheduleData = #r_schedule_data{seq_id=1, activity_id=ActivityID, start_time=StartTime, end_time=EndTime},
            set_schedule_activity_data(NextScheduleData),
            ?DBG("admin open activity ~w, time range : ~w", [ActivityID, {StartTime, EndTime}]);
        reload_config -> %%  更新配置
            reload_config(),
            ok;
        _ ->
            ignore
    end.

admin_get_top_rank_list(ActivityID) ->
    global:send(mgeew_activity_schedule, {admin_query,{get_top_rank_list, ActivityID}}).

admin_get_all_rank_list(ActivityID) ->
    global:send(mgeew_activity_schedule, {admin_query,{get_all_rank_list, ActivityID}}).

admin_get_rank_info(ActivityID, RoleID) ->
    global:send(mgeew_activity_schedule, {admin_query,{get_rank_info, {ActivityID, RoleID}}}).

%% 该方法只能用于测试，不能用于外服，会清空定时活动的奖励领取记录
admin_open_activity(ActivityID) ->
    global:send(mgeew_activity_schedule, {admin_query,{open_activity, ActivityID}}).

clear_all_activity_event() ->
    lists:foreach(
      fun(ActivityID) -> close_schedule_activity(ActivityID) end, 
      [?ACTIVITY_SCHEDULE_SILVER,?ACTIVITY_SCHEDULE_EXP,?ACTIVITY_SCHEDULE_EQUIP]).

hot_update_config() ->
    global:send(mgeew_activity_schedule, {admin_query,reload_config}),
    ok.

reload_config() ->
    case get_schedule_activity_data() of
        undefined ->
            ignore;
        ScheduleData ->
            reload_config_2(ScheduleData)
    end,
    ?DBG("admin reload activity schedule config succ", []).

reload_config_2(ScheduleData) ->
    #r_schedule_data{seq_id=SeqID, activity_id=ActivityID, start_time=StartTime, end_time=EndTime} = ScheduleData,
	[SeqList] = common_config_dyn:find(activity_schedule, seq_list),
    case SeqList of
        [] ->
            ?DBG("reload config, seq_list is empty, clear all schedule activity"),
            close_schedule_activity(ActivityID);
        _ ->
            case {erlang:length(SeqList) > 0, find_seq_data_by_seq_id(SeqID)} of
                {true, {SeqID, ConfigActivityID}} ->
                    if ActivityID =:= ConfigActivityID ->
                           ?DBG("reload config, no need to change activity", []),
                           ignore;
                       true ->
                           %% 修改当前开启活动的配置，关闭活动，开启新的活动，时间仍是被关闭活动的时间范围
                           close_schedule_activity(ActivityID),
                           NewScheduleData = #r_schedule_data{seq_id=SeqID, activity_id=ConfigActivityID, start_time=StartTime, end_time=EndTime},
                           set_schedule_activity_data(NewScheduleData),
                           ?DBG("reload config, Seq is the same , but different activityID ~w", [{ActivityID, ConfigActivityID}]),
                           ok
                    end;
                {true , undefined} ->
                    ?DBG("reload config, Seq ~w not exist, set up next activity", [SeqID]),
                    close_schedule_activity(ActivityID),
                    set_up_next_schedule_activity(ScheduleData);    
                {false, _} ->
                    ?DBG("error no seq id 2 ~w", [SeqID]),
                    close_schedule_activity(ActivityID)
            end
    end,
    ok.

find_seq_data_by_seq_id(SeqID) ->
    [SeqList] = common_config_dyn:find(activity_schedule, seq_list),
    lists:foldl(
      fun({SeqIDT, ActivityID}, Acc) ->
              if SeqIDT =:= SeqID ->
                     {SeqIDT, ActivityID};
                 true ->
                     Acc
              end
      end, undefined, SeqList).