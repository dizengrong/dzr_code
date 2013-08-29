%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com(C) 2011, 
%%% @doc
%%% 活动模块公共处理模块
%%% 主要是用来操作
%%% 玩家活动状态表
%%% -define(DB_ROLE_ACTIVITY, db_role_activity).
%%% -define(DB_ROLE_ACTIVITY_P, db_role_activity_p).
%%% @end
%%% Created : 22 Jan 2011 by  <caochuncheng>
%%%-------------------------------------------------------------------
-module(common_activity).

-include("common.hrl").
-include("common_server.hrl").
-include("activity.hrl").

%% API
-export([get_activity_config/1,get_activity_config_list/1]).
-export([get_activity_config_by_name/1]).
-export([
         %% 根据玩家id 查询玩家活动信息
         %% 返回 {ok,Activity} or {error,Reason}
         %% Activity 结构为 r_role_activity
         get_dirty_role_activity/1,
         
         %% 根据某一个活动的事件id查询玩家的此活动信息
         %% 返回 {ok,ActivityInfo} or {error,Reason}
         %% ActivityInfo 结构为 r_role_activity_info
         get_dirty_role_activity_info_by_key/2,
         
         %% 玩家某一活动信息记录
         %% 返回结果 {ok,Activity} or db:abort(Reason)
         %% Activity 结构为 r_role_activity
         insert_t_role_activity_info/2,
         
         %% 更新玩家某一活动信息记录
         %% 返回结果 {ok,Activity} or db:abort(Reason)
         %% Activity 结构为 r_role_activity
         update_t_role_activity_info/2,
         
         %% 插入或更玩家某一活动信息
         %% 返回结果 {ok,Activity} or db:abort()
         insert_and_update_t_role_activity_info/2,
         
         %% 活动时间判断
         %% 返回结果 {true, RemainTime} or {false, RemainTime} or {false, no_activity}
         check_activity_time/3,
         
         %% 特殊活动 发送信息
         send_special_activity/1,
         %% 获取某特殊活动的配置文件名
         get_config_filename/1,
         %% 根据特殊活动id和文件名获取配置
         get_config/2,
         %% 检查 某 配置文件 的可见/活动/领奖 时间
         check_config_time/3,
         %% 获取能获取的最高条件
         get_highest_condition/3,
         %% 检查是否符合某个条件
         check_config_condition/3,
         %% 将配置文件中的时间转换成时间戳
         convert_time/1,
         stat_special_activity/2
        ]).

-export([notfiy_activity_start/1,
         notfiy_activity_end/1,
         check_activity_accgold_time/0,
         check_activity_notice_config/1]).

%%%===================================================================
%%% API
%%%===================================================================

%%@doc 获取匹配的活动配置的Record，只返回第一条匹配的Record
%%@result [] | [Record]
get_activity_config_by_name(KeyName) when is_atom(KeyName)->
    case common_config_dyn:find(activity_define,KeyName) of 
        [[ActKey|_T]]when is_integer(ActKey)-> 
            common_activity:get_activity_config(ActKey);
        _ ->
            []
    end.

%%@doc 获取匹配的活动配置的Record的列表
%%@result [] | [Record]
get_activity_config_list(Key) when is_integer(Key)->
    case common_config_dyn:find(activity_define,Key) of
        []->
            [];
        [ConfigList] when is_list(ConfigList)->
            get_match_config_records(ConfigList,false);
        _ ->
            []
    end.

%%@doc 获取匹配的活动配置的Record，只返回第一条匹配的Record
%%@result [] | [Record]
get_activity_config(Key) when is_integer(Key)->
    case common_config_dyn:find(activity_define,Key) of
        []->
            [];
        [ConfigList] when is_list(ConfigList)->
            get_match_config_records(ConfigList,true);
        _ ->
            []
    end.
get_match_config_records([],_IsSingle)->
    [];
get_match_config_records([H|T],IsSingle)->
    {IsOpen,StartTime,EndTime,Recs} = H,
    case check_activity_time(IsOpen,StartTime,EndTime) of
        {true, _} ->
            %%?INFO_MSG("get_match_config_records,Recs=~w",[Recs]),
            case is_list(Recs) of
                true->
                    case IsSingle of
                        true->
                            [HRec|_TRec] = Recs,
                            [HRec];
                        _ ->
                            Recs
                    end;
                _ ->
                    [Recs]
            end;
        _ ->
            get_match_config_records(T,IsSingle)
    end.

%%@doc 判断是否在累计元宝消费的活动时间内
%%@return true | false
check_activity_accgold_time()->
    ActList = common_config_dyn:list(activity_accgold),
    check_activity_accgold_time(ActList).

check_activity_accgold_time([])->
    false;
check_activity_accgold_time([H|T])->
    #r_activity_accgold{start_time=StartTime,end_time=EndTime} = H,
    case check_activity_time(true,StartTime,EndTime) of
        {true,_}->
            true;
        {false,_}->
            check_activity_accgold_time(T)
    end.

-define(OPENDAYS(D),{open_days,D}).

%%@doc 检查活动时间
check_activity_time(true,{?OPENDAYS(StartDiff),StartTime},{?OPENDAYS(EndDiff),EndTime})->
    {OpenDate, _} = common_config:get_open_day(),
    StartDate = common_time:add_days(OpenDate,StartDiff),
    EndDate = common_time:add_days(OpenDate,EndDiff),
        
    StartTimeStamp = common_tool:datetime_to_seconds({StartDate,StartTime}),
    EndTimeStamp = common_tool:datetime_to_seconds({EndDate,EndTime}),

    Now = common_tool:datetime_to_seconds( calendar:local_time() ),
    %%?INFO_MSG("check_activity_time,{StartTimeStamp,EndTimeStamp,Now}=~w",[{StartTimeStamp,EndTimeStamp,Now}]),
    Result = (Now>=StartTimeStamp) andalso (EndTimeStamp>=Now),
    case Result of
        true ->
            {true, EndTimeStamp-Now};
        _ ->
            {false, StartTimeStamp-Now}
    end;
check_activity_time(true,StartTime,EndTime)->
    StartTimeStamp = common_tool:datetime_to_seconds(StartTime),
    EndTimeStamp = common_tool:datetime_to_seconds(EndTime),

    Now = common_tool:datetime_to_seconds( calendar:local_time() ),
    %%?INFO_MSG("check_activity_time,{StartTimeStamp,EndTimeStamp,Now}=~w",[{StartTimeStamp,EndTimeStamp,Now}]),
    Result = (Now>=StartTimeStamp) andalso (EndTimeStamp>=Now),
    case Result of
        true ->
            {true, EndTimeStamp-Now};
        _ ->
            {false, StartTimeStamp-Now}
    end;
check_activity_time(_IsOpen,_StartTime,_EndTime)->
    {false, no_activity}.



%% 根据玩家id 查询玩家活动信息
%% 参数
%% RoleID 玩家id
%% 返回 {ok,Activity} or {error,Reason}
%% ActivityInfo 结构为 r_role_activity
get_dirty_role_activity(RoleID) ->
    case catch db:dirty_read(?DB_ROLE_ACTIVITY, RoleID) of
        {'EXIT', R} ->
            {error,R};
        [] ->
            {error, not_found};
        [Activity] ->
            {ok, Activity}
    end.

%% 根据某一个活动的事件id查询玩家的此活动信息
%% 参数
%% RoleID 玩家id
%% Key 事件id
%% 返回 {ok,ActivityInfo} or {error,Reason}
%% ActivityInfo 结构为 r_role_activity_info
get_dirty_role_activity_info_by_key(RoleID,Key) ->
    %% 检查此活动事件是否合法
    case get_dirty_role_activity(RoleID) of
        {error,R} ->
            {error,R};
        {ok,Activity} ->
            case lists:keyfind(Key,#r_role_activity_info.key,Activity#r_role_activity.activitys) of
                false ->
                    {error,not_found};
                ActivityInfo ->
                    {ok,ActivityInfo}
            end
    end.
%% 玩家某一活动信息记录
%% 参数
%% RoleID 玩家Id
%% ActivityInfo 某一活动信息 结构为 r_role_activity_info
%% 返回结果 {ok,Activity} or db:abort(Reason)
insert_t_role_activity_info(RoleID,ActivityInfo) ->
    RoleActivity =
        case db:read(?DB_ROLE_ACTIVITY,RoleID) of
            [] ->
                #r_role_activity{role_id = RoleID,activitys = []};
            RoleActivityT ->
                RoleActivityT
        end,
    ActivitysList = RoleActivity#r_role_activity.activitys,
    case lists:keyfind(ActivityInfo#r_role_activity_info.key,#r_role_activity_info.key,ActivitysList) of
        false ->
            RoleActivity2 = RoleActivity#r_role_activity{activitys = [ActivityInfo|ActivitysList]},
            db:write(?DB_ROLE_ACTIVITY,RoleActivity2,write),
            {ok,RoleActivity2};
        _ ->
            db:abort(activity_info_not_exist)
    end.

%% 更新玩家某一活动信息记录
%% 参数
%% RoleID 玩家Id
%% ActivityInfo 某一活动信息 结构为 r_role_activity_info
%% 返回结果 {ok,Activity} or db:abort(Reason)
update_t_role_activity_info(RoleID,ActivityInfo) ->
    RoleActivity =
        case db:read(?DB_ROLE_ACTIVITY,RoleID) of
            [] ->
                db:abort(role_not_activity_info);
            RoleActivityT ->
                RoleActivityT
        end,
    ActivitysList = RoleActivity#r_role_activity.activitys,
    case lists:keyfind(ActivityInfo#r_role_activity_info.key,#r_role_activity_info.key,ActivitysList) of
        false ->
            db:abort(activity_info_not_exist);
        _ ->
            ActivitysList2 = lists:keydelete(ActivityInfo#r_role_activity_info.key,
                                             #r_role_activity_info.key,
                                             ActivitysList),
            RoleActivity2 = RoleActivity#r_role_activity{activitys = [ActivityInfo|ActivitysList2]},
            db:write(?DB_ROLE_ACTIVITY,RoleActivity2,write),
            {ok,RoleActivity2}
    end.


%% 插入或更玩家某一活动信息
%%% 参数
%% RoleID 玩家Id
%% ActivityInfo 某一活动信息 结构为 r_role_activity_info
%% 返回结果 {ok,Activity} or db:abort()
insert_and_update_t_role_activity_info(RoleID,ActivityInfo) ->
    RoleActivity =
        case db:read(?DB_ROLE_ACTIVITY,RoleID) of
            [] ->
                #r_role_activity{role_id = RoleID,activitys = []};
            RoleActivityT ->
                RoleActivityT
        end,
    ActivitysList = RoleActivity#r_role_activity.activitys,
    RoleActivity2 = 
        case lists:keyfind(ActivityInfo#r_role_activity_info.key,#r_role_activity_info.key,ActivitysList) of
            false ->
                RoleActivity#r_role_activity{activitys = [ActivityInfo|ActivitysList]};
            _ ->
                ActivitysList2 = lists:keydelete(ActivityInfo#r_role_activity_info.key,
                                                 #r_role_activity_info.key,
                                                 ActivitysList),
                RoleActivity#r_role_activity{activitys = [ActivityInfo|ActivitysList2]}
        end,
    db:write(?DB_ROLE_ACTIVITY,RoleActivity2,write),
    {ok,RoleActivity2}.

%%======================= start special activity==========================================
%% 特殊活动
send_special_activity(Msg)->
    case global:whereis_name(mgeew_activity_server) of
        undefined->
            ?ERROR_MSG("活动进程挂了！~n",[]);
        _->
            global:send(mgeew_activity_server,Msg)
    end.


%% 检查配置文件

get_config_filename(ActivityKey)->
    case lists:keyfind(ActivityKey, 1, ?ACTIVITY_CONFIG_LIST) of
        {ActivityKey,ConfigName}->
            {ok,ConfigName};
        false->
            throw({error,"活动没有开启，敬请期待"})
    end.

%% get_config(ActivityKey)->
%%     case lists:keyfind(ActivityKey, 1, ?ACTIVITY_CONFIG_LIST) of
%%         {ActivityKey,ConfigName}->
%%             get_config(ActivityKey,ConfigName);
%%         false->
%%             throw({error,"找不到配置文件"})
%%     end.
get_config(ActivityKey,ConfigName)->
    case common_config_dyn:find(ConfigName,ActivityKey) of
        []->throw({error,"活动没有开启，敬请期待"});
        [Config]->{ok,Config}
    end.

convert_time(ErlangTime)->
    case ErlangTime of
        {{open_day,Day},{Hour,Min,Sec}}->
            {{OpenYear,OpenMonth,OpenDay},{_,_,_}}=common_config:get_open_day(),
            common_tool:datetime_to_seconds({{OpenYear,OpenMonth,OpenDay},{Hour,Min,Sec}})+Day*86400;
        {{Year,Month,Day},{Hour,Min,Sec}}->
            common_tool:datetime_to_seconds({{Year,Month,Day},{Hour,Min,Sec}});
        _-> 0
    end.

         


%% 检查可见时间
-define(CHECK_CONFIG_VISIBLE_TIME(Config,ActivityRecord),
    Now = common_tool:now(),
    StartTime = convert_time(Config#ActivityRecord.visible_start_time),
    EndTime = convert_time(Config#ActivityRecord.visible_end_time),
    case StartTime<Now andalso EndTime>Now of
        true->{ok,StartTime,EndTime};
        false->throw({error,"当前活动不可见"})
    end).

%% 检查活动时间
-define(CHECK_CONFIG_ACTIVITY_TIME(Config,ActivityRecord),
    Now = common_tool:now(),
    StartTime = convert_time(Config#ActivityRecord.activity_start_time),
    EndTime = convert_time(Config#ActivityRecord.activity_end_time),  
    case StartTime<Now andalso EndTime>Now of
        true->{ok,StartTime,EndTime};
        false->throw({error,"现在不是此次活动的活动时间"})
    end).

%% 检查奖励时间
-define(CHECK_CONFIG_REWARD_TIME(Config,ActivityRecord),
    Now = common_tool:now(),
    StartTime = convert_time(Config#ActivityRecord.reward_start_time),
    EndTime = convert_time(Config#ActivityRecord.reward_end_time),
    case StartTime<Now andalso EndTime>Now of
        true->{ok,StartTime,EndTime};
        false->throw({error,"现在不是此次活动的领奖时间"})
    end).


check_config_time(spend_activity,visible,Config)->
    ?CHECK_CONFIG_VISIBLE_TIME(Config,r_spend_activity);
check_config_time(spend_activity,activity,Config)->
    ?CHECK_CONFIG_ACTIVITY_TIME(Config,r_spend_activity);
check_config_time(spend_activity,reward,Config)->
    ?CHECK_CONFIG_REWARD_TIME(Config,r_spend_activity);

check_config_time(ranking_activity,visible,Config)->
    ?CHECK_CONFIG_VISIBLE_TIME(Config,r_ranking_activity);
check_config_time(ranking_activity,activity,Config)->
    ?CHECK_CONFIG_ACTIVITY_TIME(Config,r_ranking_activity);
check_config_time(ranking_activity,reward,Config)->
    ?CHECK_CONFIG_REWARD_TIME(Config,r_ranking_activity);

check_config_time(other_activity,visible,Config)->
    ?CHECK_CONFIG_VISIBLE_TIME(Config,r_other_activity);
check_config_time(other_activity,activity,Config)->
    ?CHECK_CONFIG_ACTIVITY_TIME(Config,r_other_activity);
check_config_time(other_activity,reward,Config)->
    ?CHECK_CONFIG_REWARD_TIME(Config,r_other_activity).




%% start 不同活动检查的条件方式不同------------------------------------

%% 获取能达到的最高的条件id
get_highest_condition(_ActivityKey,[],_Arg)->
    {ok,0};
get_highest_condition(ActivityKey,[H|T],Arg)->
    case check_config_condition(ActivityKey,H,Arg) of
        true->{ok,H#r_condition_prize.condition_id};
        false->get_highest_condition(ActivityKey,T,Arg)
    end.


check_config_condition(?SPEND_SUM_PAY_KEY,Condition,SumGolds)->
    SumGolds>=Condition#r_condition_prize.condition;
check_config_condition(?SPEND_ONCE_PAY_KEY,Condition,SumGolds)->
    SumGolds>=Condition#r_condition_prize.condition;
check_config_condition(?SPEND_USE_GOLD_KEY,Condition,SumGolds)->
    SumGolds>=Condition#r_condition_prize.condition;

check_config_condition(?RANK_ROLE_LEVEL_KEY,Condition,Rank)->
    {StartLevel,EndLevel} = Condition#r_condition_prize.condition,
    StartLevel=<Rank andalso Rank=<EndLevel;
check_config_condition(?RANK_EQUIP_REFINING_KEY,Condition,Rank)->
    {StartLevel,EndLevel} = Condition#r_condition_prize.condition,
    StartLevel=<Rank andalso Rank=<EndLevel;
check_config_condition(?RANK_EQUIP_REINFORCE_KEY,Condition,Rank)->
    {StartLevel,EndLevel} = Condition#r_condition_prize.condition,
    StartLevel=<Rank andalso Rank=<EndLevel;
check_config_condition(?RANK_EQUIP_STONE_KEY,Condition,Rank)->
    {StartLevel,EndLevel} = Condition#r_condition_prize.condition,
    StartLevel=<Rank andalso Rank=<EndLevel;
check_config_condition(?RANK_PET_KEY,Condition,Rank)->
    {StartLevel,EndLevel} = Condition#r_condition_prize.condition,
    StartLevel=<Rank andalso Rank=<EndLevel;
check_config_condition(?RANK_YDAY_GIVE_FLOWER_KEY,Condition,Rank)->
    {StartLevel,EndLevel} = Condition#r_condition_prize.condition,
    StartLevel=<Rank andalso Rank=<EndLevel;
check_config_condition(?RANK_YDAY_RECV_FLOWER_KEY,Condition,Rank)->
    {StartLevel,EndLevel} = Condition#r_condition_prize.condition,
    StartLevel=<Rank andalso Rank=<EndLevel;
check_config_condition(?OTHER_EQUIP_REINFORCE_KEY,Condition,{TypeID,ReinForceResult})->
    {AimTypeID,AimReinForceResult} = Condition#r_condition_prize.condition,
    AimTypeID=:=TypeID andalso AimReinForceResult=<ReinForceResult;
check_config_condition(?OTHER_EQUIP_STONE_KEY,Condition,{TypeID,StonesNum})->
    {AimTypeID,AimStonesNum} = Condition#r_condition_prize.condition,
    AimTypeID=:=TypeID andalso AimStonesNum=<StonesNum.

stat_special_activity(ActivityKey,Info)->
    {ok,ConfigName} = get_config_filename(ActivityKey),
    {ok,Config}=get_config(ActivityKey,ConfigName),
    {ok,_,_} = check_config_time(ConfigName,activity,Config),
    send_stat_info_by_filename(ConfigName,{ActivityKey,Info}).
%%不同配置文件的活动接口不同..
send_stat_info_by_filename(spend_activity,Info)->
    send_special_activity({stat_pay,Info});
%% send_stat_info_by_filename(ranking_activity,ActivityKey,Info)->
%%     send_special_activity({stat_ranking,{ActivityKey,Info}});
send_stat_info_by_filename(other_activity,Info)->
    send_special_activity({stat_other,Info}).

        


%%======================= end special activity ==========================================


%% 通知活动开始
%% 活动开始前的消息提示
notfiy_activity_start({ActivityId, NowSeconds, StartTime, EndTime}) ->
    [ notfiy_activity_start({ActivityId, NowSeconds, StartTime, EndTime, FactionId})||FactionId<-[1,2,3] ];
notfiy_activity_start({ActivityId, NowSeconds, StartTime, EndTime, FactionId}) ->
    case check_activity_notice_config(ActivityId) of
        {error, not_found_config} ->
            ignore;
        #r_activity_notice_config{ahead_time=AheadTime} ->
            broadcast_activity_start_notice(ActivityId, AheadTime, NowSeconds, StartTime, EndTime, FactionId);
        _->
            ignore
    end.


%% 活动关闭的消息提示
notfiy_activity_end(ActivityId) when is_integer(ActivityId) ->
    [ notfiy_activity_end({ActivityId, FactionId})||FactionId<-[1,2,3] ];
notfiy_activity_end({ActivityId, FactionId}) ->
    case check_activity_notice_config(ActivityId) of
        {error, not_found_config} ->
            ignore;
        _ ->
            broadcast_activity_end_notice(ActivityId, FactionId)
    end.
        
broadcast_activity_start_notice(ActivityId, AheadTime, NowSeconds, StartTime, EndTime, FactionId) ->  
    IsTimeToNotice = is_time_to_notice(AheadTime, NowSeconds, StartTime),
    case IsTimeToNotice of
        true ->
            Flag = common_misc:get_event_state({ActivityId, FactionId}),
            case Flag of
                {false, []} ->
                    common_misc:set_event_state({ActivityId, FactionId}, {StartTime, EndTime}),
                    DataRecord = #m_activity_notice_start_toc{activity_id=ActivityId,
                                                              start_time=StartTime,
                                                              end_time=EndTime},
                    common_misc:chat_broadcast_to_faction(FactionId, ?ACTIVITY,?ACTIVITY_NOTICE_START,DataRecord);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.


%% 特殊处理全民拉镖的时间触发器不是在地图里触发的，因此无法获取flag
broadcast_activity_end_notice(ActivityId, FactionId) ->
    common_misc:del_event_state({ActivityId, FactionId}),
    DataRecord = #m_activity_notice_end_toc{activity_id=ActivityId},
    common_misc:chat_broadcast_to_faction(FactionId, ?ACTIVITY,?ACTIVITY_NOTICE_END,DataRecord).

check_activity_notice_config(ActivityId) ->
    case common_config_dyn:find(activity_notice, {activity, ActivityId}) of
        [Config] ->
            Config;
        [] ->
            {error, not_found_config}
    end.
            
is_time_to_notice(AheadTime, NowSeconds, StartTime) ->
    if AheadTime + NowSeconds >= StartTime ->
           true;
       true ->
           false
    end.
