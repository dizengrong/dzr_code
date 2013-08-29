%%% -------------------------------------------------------------------
%%% Author  : xiaosheng
%%% Description : 任务 验证模块
%%%
%%% Created : 2010-9-2
%%% -------------------------------------------------------------------
-module(mod_mission_auth).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mission.hrl"). 

-export([]).
-export([auth_accept/2,auth_show/2,auth_retake/2]).


%% ====================================================================
%% Macro
%% ====================================================================
%% 是否非正数
-define(IS_INVALID_NUM(ID), not ( is_integer(ID) andalso ID>0)).

%%
%% API Functions
%%

%%@doc 验证是否可以重做
%%@return  true | {false, ReasonCode, ReasonIntData}
auth_retake(RoleID, MissionBaseInfo)->
    auth_show(RoleID, MissionBaseInfo).


%%@doc 验证是否可接
%%@return  true | {false, ReasonCode, ReasonIntData}
auth_accept(RoleID, MissionBaseInfo) -> 
    %%验证: 性别、国家、等级、组队、宗族、时间、次数
    
    i_auth_take(RoleID, MissionBaseInfo).


%%@doc 验证是否可以出现在任务列表
%%@return  true | {false, ReasonCode, ReasonIntData}
auth_show(RoleID, MissionBaseInfo) -> 
    %% 验证: 性别、国家、等级、组队、宗族、时间、次数
    i_auth_show(RoleID, MissionBaseInfo).
    
    


%%TODO: auth_distance NPC距离判断
%%TODO: auth_auto_mission_commit 自动任务的提交时间判断

i_auth_show(RoleID, MissionBaseInfo) ->
    #mission_base_info{model=MissionModel} = MissionBaseInfo,
    IsCloseModel9 = common_config_dyn:find(etc,close_mission_shoubian) =:= [true],
    IsCloseModel10 = common_config_dyn:find(etc,close_mission_citan) =:= [true],
    if
        IsCloseModel9 andalso (MissionModel=:=9) ->
            {false, ?MISSION_CODE_FAIL_NOT_FOUND,[]};
        IsCloseModel10 andalso (MissionModel=:=10) ->
            {false, ?MISSION_CODE_FAIL_NOT_FOUND,[]};
        true->
            case i_auth_take_0(RoleID, MissionBaseInfo) of
                {false, ?MISSION_CODE_AUTHFAIL_PROP_NOT_ENOUGH, _} ->
                    true;%%策划要求可以显示
                Other ->
                    Other
            end
    end.


i_auth_take(RoleID, MissionBaseInfo) ->
    #mission_base_info{model=MissionModel} = MissionBaseInfo,
    IsCloseModel9 = common_config_dyn:find(etc,close_mission_shoubian) =:= [true],
    IsCloseModel10 = common_config_dyn:find(etc,close_mission_citan) =:= [true],
    if
        IsCloseModel9 andalso (MissionModel=:=9) ->
            {false, ?MISSION_CODE_FAIL_NOT_FOUND,[]};
        IsCloseModel10 andalso (MissionModel=:=10) ->
            {false, ?MISSION_CODE_FAIL_NOT_FOUND,[]};
        true->
            case i_auth_take_0(RoleID, MissionBaseInfo) of
                {false, ?MISSION_CODE_AUTHFAIL_VIP_LIMIT, _} ->
                    true;%%VIP就算接错了也放过
                Other ->
                    Other
            end
    end.

i_auth_take_0(RoleID, MissionBaseInfo) ->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    %% 验证1）性别、组队、宗族
    #p_role_base{sex=RoleSex,faction_id=RoleFactionID,team_id=RoleTeamID,family_id=RoleFamilyID} = RoleBase,
    #mission_base_info{gender=Gender,faction=Faction,team=HasTeam,family=HasFamily,vip_level=MissVipLevel} = MissionBaseInfo,
    
    VipLevel = mod_vip:get_role_vip_level(RoleID),
    RoleVipLevel = VipLevel+100, %%加上100是为了实现对全体玩家(0)、免费玩家(100)、VIP1(101)、VIP2(102)、VIP3(103)的区别

    if
        Faction>0 andalso (RoleFactionID=/=Faction)->
            {false, ?MISSION_CODE_AUTHFAIL_FACTION_LIMIT,[Faction]};
        Gender>0 andalso (RoleSex=/=Gender)->
            {false, ?MISSION_CODE_AUTHFAIL_SEX_LIMIT,[Gender]};
        HasTeam>0 andalso ?IS_INVALID_NUM(RoleTeamID) ->
            {false, ?MISSION_CODE_AUTHFAIL_TEAM_LIMIT,[]};
        HasFamily>0 andalso ?IS_INVALID_NUM(RoleFamilyID) ->
            {false, ?MISSION_CODE_AUTHFAIL_FAMILY_LIMIT,[]};
        MissVipLevel>0 andalso RoleVipLevel=/=MissVipLevel->
            {false, ?MISSION_CODE_AUTHFAIL_VIP_LIMIT,[MissVipLevel]};
        true->
            i_auth_take_2(MissionBaseInfo, RoleID, RoleBase, RoleAttr)
    end.
    


%%@doc 检查等级
i_auth_take_2(MissionBaseInfo, RoleID, RoleBase, RoleAttr) ->
    
    RoleLevel = RoleAttr#p_role_attr.level,
    MaxLevel = MissionBaseInfo#mission_base_info.max_level,
    MinLevel = MissionBaseInfo#mission_base_info.min_level,
    
    if
        MinLevel>0 andalso (MinLevel>RoleLevel) ->
            {false, ?MISSION_CODE_AUTHFAIL_LEVEL_LIMIT, [MinLevel, MaxLevel]};
        MaxLevel>0 andalso (RoleLevel>MaxLevel) ->
            {false, ?MISSION_CODE_AUTHFAIL_LEVEL_LIMIT, [MinLevel, MaxLevel]};
        true->
            i_auth_take_3(MissionBaseInfo, RoleID, RoleBase, RoleAttr)
    end.

%% --------------------------------------------------------------------
%% 检查前置任务
%% --------------------------------------------------------------------
i_auth_take_3(MissionBaseInfo, RoleID, RoleBase, RoleAttr) ->
    PreMissionID = MissionBaseInfo#mission_base_info.pre_mission_id,

    if
        PreMissionID =:= 0 ->
            i_auth_take_4(MissionBaseInfo, RoleID, RoleBase, RoleAttr);
        true ->
            case is_mission_completed(RoleID,PreMissionID) of
                true->
                    i_auth_take_4(MissionBaseInfo, RoleID, RoleBase, RoleAttr);
                _ ->
                    {false, ?MISSION_CODE_AUTHFAIL_PREMISSION_LIMIT, [PreMissionID]}
            end
    end.


%% --------------------------------------------------------------------
%% 检查时间是否满足
%% --------------------------------------------------------------------
i_auth_take_4(MissionBaseInfo, RoleID, RoleBase, RoleAttr) ->
    CTimeType = MissionBaseInfo#mission_base_info.time_limit_type,
    TimeLimitRec = MissionBaseInfo#mission_base_info.time_limit,
    
    case i_check_datetime(CTimeType, TimeLimitRec) of
        true->
            i_auth_take_5(MissionBaseInfo, RoleID, RoleBase, RoleAttr);
        _ ->
            case TimeLimitRec of
                #mission_time_limit{time_limit_start=CTimeStart,time_limit_end=CTimeEnd} ->
                    {false, ?MISSION_CODE_AUTHFAIL_TIME_LIMIT, [CTimeType, CTimeStart, CTimeEnd]};
                _ ->
                    {false, ?MISSION_CODE_AUTHFAIL_TIME_LIMIT, [CTimeType]}
            end
    end.

%% --------------------------------------------------------------------
%% 检查可接次数
%% --------------------------------------------------------------------
i_auth_take_5(MissionBaseInfo, RoleID, RoleBase, RoleAttr) ->
    #mission_base_info{max_do_times=MaxDoTimes} = MissionBaseInfo,
    CommitTimes = mod_mission_data:get_commit_times(RoleID,MissionBaseInfo),
    case MaxDoTimes>CommitTimes of
        true->
            i_auth_take_6(MissionBaseInfo, RoleID, RoleBase, RoleAttr);
        _ ->
            {false, ?MISSION_CODE_AUTHFAIL_MAX_DO_TIMES_LIMIT, [MaxDoTimes]}
    end.

%% --------------------------------------------------------------------
%% 检查前置道具是否满足
%% --------------------------------------------------------------------
i_auth_take_6(MissionBaseInfo, RoleID, _RoleBase, _RoleAttr) ->
    PrePropList = MissionBaseInfo#mission_base_info.pre_prop_list,
    
    case is_list(PrePropList) of
        true->
            check_prep_prop_list(RoleID, PrePropList);
        _->
            true
    end.

check_prep_prop_list(_RoleID,[])->
    true;
check_prep_prop_list(RoleID,[PreMissionProp|T])->
    #pre_mission_prop{prop_id=PropID,prop_num=PropNum} = PreMissionProp,
    case check_prop(RoleID, PropID, PropNum) of
        true->
            check_prep_prop_list(RoleID,T);
        FalseReturn->
            FalseReturn
    end.


%%@doc 检查单个道具是否满足
check_prop(RoleID, PropID, NeedNum) ->
    case mod_bag:get_goods_num_by_typeid([1, 2, 3], RoleID, PropID) of
        {ok, Num} when (Num >= NeedNum) ->
            true;
        _ ->
            {false, ?MISSION_CODE_AUTHFAIL_PROP_NOT_ENOUGH, [PropID]}
    end.


%% --------------------------------------------------------------------
%% 时间检查
%% --------------------------------------------------------------------
%%TODO: 这里需要修正时间错误
i_check_datetime(?MISSION_TIME_LIMIT_NO, _TimeLimitRec) ->
    true;
i_check_datetime(_, {}) ->
    true;
i_check_datetime(?MISSION_TIME_LIMIT_DAILY, TimeLimitRec) ->
    {_, NowTime} = calendar:local_time(),
    is_nowtime_limit(NowTime,TimeLimitRec);

i_check_datetime(?MISSION_TIME_LIMIT_MONTH, TimeLimitRec) ->
    #mission_time_limit{time_limit_start_day=LimitStartDay,time_limit_end_day=LimitEndDay} = TimeLimitRec,
    {{_Year, _Month, NowDay}, NowTime} = calendar:local_time(),
    is_nowtime_limit(NowTime,TimeLimitRec) andalso (NowDay>=LimitStartDay) andalso (LimitEndDay>=NowDay);

i_check_datetime(?MISSION_TIME_LIMIT_WEEK, TimeLimitRec) ->
    #mission_time_limit{time_limit_start_day=LimitStartDay,time_limit_end_day=LimitEndDay} = TimeLimitRec,
    {{NowYear, NowMonth, NowDay}, NowTime} = calendar:local_time(),
    NowWeekDay = calendar:day_of_the_week(NowYear, NowMonth, NowDay),
    is_nowtime_limit(NowTime,TimeLimitRec) andalso (NowWeekDay>=LimitStartDay) andalso (LimitEndDay>=NowWeekDay);

i_check_datetime(?MISSION_TIME_LIMIT_SOMEDAY, TimeLimitRec) ->
    #mission_time_limit{time_limit_start_timestamp=StartTimeStamp,time_limit_end_timestamp=EndTimeStamp} = TimeLimitRec,
    
    Now = common_tool:datetime_to_seconds( calendar:local_time() ),
    (Now>=StartTimeStamp) andalso (EndTimeStamp>=Now).


    
 
%%%===================================================================
%%% Internal functions
%%%===================================================================

%%@doc 判断任务是否完成
is_mission_completed(RoleID,MissionID)->
    try
        MissionBaseInfo = mod_mission_data:get_base_info(MissionID),
        #mission_base_info{max_do_times=MaxDoTimes} = MissionBaseInfo,
        CommitTimes = mod_mission_data:get_commit_times(RoleID,MissionBaseInfo),
        CommitTimes>=MaxDoTimes
    catch
        _:Reason->
            ?ERROR_MSG("is_mission_completed error,Reason=~w",[Reason]),
            true
    end.

%%@doc 判断是否处于受限时间范围内
is_nowtime_limit({H,M,S}=_NowTime,TimeLimitRec)->
    #mission_time_limit{time_limit_start=LimitStart,time_limit_end=LimitEnd} = TimeLimitRec,
    NowLimit = H*3600 + M*60 + S,
    if
        LimitStart=:=0 andalso LimitEnd =:=0 ->
            true;
        (NowLimit>=LimitStart) andalso (LimitEnd>=NowLimit) ->
            true;
        true->
            false
    end.

    




