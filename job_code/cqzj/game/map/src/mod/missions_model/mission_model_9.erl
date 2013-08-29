%% Author: chixiaosheng
%% Created: 2011-4-12
%% Description: 守边模型
-module(mission_model_9, [RoleID, MissionID, MissionBaseInfo]).
-behaviour(b_mission_model).

%%
%% Include files
%%
-include("mission.hrl").  
%%等待状态
-define(MISSION_MODEL_9_STATUS_WAIT, 1).
%%成功状态-即可以提交
-define(MISSION_MODEL_9_STATUS_SUCC, 2).
%%超时状态-可提交-但提交以后是超时奖励比较少或没有
-define(MISSION_MODEL_9_STATUS_TIMEOUT, 3).

%%
%% Exported Functions
%%
-export([
         auth_accept/1,
         auth_show/1,
         do/2,
         cancel/2,
         listener_trigger/3,
         init_pinfo/1]).

%%
%% API Functions
%%
%%@doc 验证是否可接
auth_accept(_PInfo) -> 
    mod_mission_auth:auth_accept(RoleID, MissionBaseInfo).

%%@doc 验证是否可以出现在任务列表
auth_show(_PInfo) -> 
    mod_mission_auth:auth_show(RoleID, MissionBaseInfo).

%%@doc 执行任务 接-做-交
do(PInfo, RequestRecord) ->
    TransFun = 
        fun() ->
                CurrentModelStatus = PInfo#p_mission_info.current_model_status,
                do_shou_bian(CurrentModelStatus, PInfo, RequestRecord)
        end,
    ?DO_TRANS_FUN( TransFun ).

%%@doc 执行守边任务
do_shou_bian(?MISSION_MODEL_STATUS_FIRST, PInfo, RequestRecord) ->
    set_role_state(RoleID, doing),
    mission_model_common:common_do(RoleID, 
                                   MissionID,
                                   MissionBaseInfo,
                                   RequestRecord, 
                                   PInfo);
do_shou_bian(?MISSION_MODEL_9_STATUS_WAIT, PInfo, RequestRecord) ->
    AcceptTime = PInfo#p_mission_info.accept_time,
    WaitTimeLimit = get_time_limit(?MISSION_MODEL_9_STATUS_WAIT),
    SuccTimeLimit = get_time_limit(?MISSION_MODEL_9_STATUS_SUCC)+WaitTimeLimit,
    
    Now = common_tool:now(),
    
    %%如果大于0 表明已经超过等待时间了
    WaitTimeDiff = Now - (AcceptTime+WaitTimeLimit),
    
    %%如果大于0 表明已经超过成功时间了 即超时
    SuccTimeDiff = Now - (AcceptTime+SuccTimeLimit),
    NpcID = RequestRecord#m_mission_do_tos.npc_id,
    
    if
        WaitTimeDiff < 0 ->
            throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_SB_NOT_MATCH_TIME, [-WaitTimeDiff]});
        WaitTimeDiff >= 0 andalso SuccTimeDiff =< 0 ->
            if
                NpcID =:= 0 ->%%如果NPC为0 则是时间计时器自己提交的 不判断NPC距离 仅切换状态
                    NewPInfo = PInfo#p_mission_info{current_status=?MISSION_STATUS_FINISH},
                    change_status(NewPInfo, +1);%%切换为成功状态
                true ->%%完成任务
                    finish(succ, PInfo, RequestRecord)
            end;
        true ->
            if
                NpcID =:= 0 ->%%如果NPC为0 则是时间计时器自己提交的 不判断NPC距离 仅切换状态
                    NewPInfo = PInfo#p_mission_info{current_status=?MISSION_STATUS_FINISH},
                    change_status(NewPInfo, +2);%%切换为超时
                true ->%%完成任务
                    finish(timeout, PInfo, RequestRecord)
            end
    end;
do_shou_bian(?MISSION_MODEL_9_STATUS_SUCC, PInfo, RequestRecord) ->
    AcceptTime = PInfo#p_mission_info.accept_time,
    WaitTimeLimit = get_time_limit(?MISSION_MODEL_9_STATUS_WAIT),
    SuccTimeLimit = get_time_limit(?MISSION_MODEL_9_STATUS_SUCC)+WaitTimeLimit,
    
    Now = common_tool:now(),
    
    %%如果大于0 表明已经超过成功时间了 即超时
    SuccTimeDiff = Now - (AcceptTime+SuccTimeLimit),
    NpcID = RequestRecord#m_mission_do_tos.npc_id,
    
    if
        SuccTimeDiff =< 0 ->
            if
                NpcID =:= 0 ->
                    throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_SB_DUPLICATE_DO, []});
                true ->%%完成任务
                    finish(succ, PInfo, RequestRecord)
            end;
        true ->
            if
                NpcID =:= 0 ->%%如果NPC为0 则是时间计时器自己提交的 不判断NPC距离 仅切换状态
                    NewPInfo = PInfo#p_mission_info{current_status=?MISSION_STATUS_FINISH},
                    change_status(NewPInfo, +1);%%切换为超时
                true ->%%完成任务
                    finish(timeout, PInfo, RequestRecord)
            end
    end;
do_shou_bian(?MISSION_MODEL_9_STATUS_TIMEOUT, PInfo, RequestRecord) ->
    NpcID = RequestRecord#m_mission_do_tos.npc_id,
    if
        NpcID =:= 0 ->
            throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_SB_DUPLICATE_DO, []});
        true ->
            finish(timeout, PInfo, RequestRecord)
    end.

%% 获取限制时间
get_time_limit(Status) ->
    StatusData = mod_mission_data:get_status_data(Status, MissionBaseInfo),
    StatusData#mission_status_data.time_limit.

%% 改变状态
change_status(NewPInfo, ChangeStep) ->
    CurrentModelStatus = NewPInfo#p_mission_info.current_model_status,
    NewModelStatus = CurrentModelStatus+ChangeStep,
    CurrentStatus = NewPInfo#p_mission_info.current_status,
    NewStatus = CurrentStatus,
    
    if
        CurrentModelStatus =:= ?MISSION_MODEL_STATUS_FIRST ->
            {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
            AcceptLevel = RoleAttr#p_role_attr.level;
        true ->
            AcceptLevel = NewPInfo#p_mission_info.accept_level
    end,
    Now = common_tool:now(),
    NewPinfo2 = NewPInfo#p_mission_info{
        accept_level=AcceptLevel,
        current_status = NewStatus,
        pre_status=CurrentStatus,
        current_model_status = NewModelStatus,
        pre_model_status=CurrentModelStatus,
        accept_time=Now,
        status_change_time=Now
    },
    mod_mission_data:set_pinfo(RoleID, NewPinfo2, notify),
    #m_mission_do_toc{
        id=MissionID,
        current_status=NewStatus,
        pre_status=CurrentStatus,
        current_model_status=NewModelStatus,
        pre_model_status=CurrentModelStatus,
        code=?MISSION_CODE_SUCC,
        code_data=[]}.


get_role_name_str(RoleID)->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    common_tool:to_list(RoleBase#p_role_base.role_name).

%%提交任务
%%成功
finish(succ, PInfo, RequestRecord) ->
    SuccTimes = mod_mission_data:get_succ_times(RoleID, MissionBaseInfo),
    NewSuccTimes = SuccTimes+1,
    MaxDoTimes = MissionBaseInfo#mission_base_info.max_do_times,
	ExpMulti = 1,
    ShouBianRewardList = mod_mission_data:get_setting(shoubian_reward),
    Level = PInfo#p_mission_info.accept_level,
    {Level, SuccExp, _TimeOutExp, SuccPrestige, _TimeOutPrestige, FinalPropList} = lists:keyfind(Level, 1, ShouBianRewardList),
    
    if
        MaxDoTimes =:= NewSuccTimes ->
            BaseRewardData = #mission_reward_data{
                                                  rollback_times=1,
                                                  prop_reward_formula=?MISSION_PROP_REWARD_FORMULA_CHOOSE_ONE,
                                                  attr_reward_formula=?MISSION_ATTR_REWARD_FORMULA_NORMAL,
                                                  exp=common_tool:floor(SuccExp*NewSuccTimes*ExpMulti),
                                                  prestige = SuccPrestige,
                                                  silver=0,
                                                  silver_bind=0,
                                                  prop_reward=FinalPropList                             
                                                 },
            ShouldGiveRewardProp = true;
        true ->
            BaseRewardData = #mission_reward_data{
                                                  rollback_times=1,
                                                  prop_reward_formula=?MISSION_PROP_REWARD_FORMULA_NO,
                                                  attr_reward_formula=?MISSION_ATTR_REWARD_FORMULA_NORMAL,
                                                  exp=common_tool:floor(SuccExp*NewSuccTimes*ExpMulti),
                                                  prestige = SuccPrestige,
                                                  silver=0,
                                                  silver_bind=0,
                                                  prop_reward=[]                              
                                                 },
            ShouldGiveRewardProp = false
    end,
    NewMissionBaseInfo = MissionBaseInfo#mission_base_info{reward_data=BaseRewardData},
    set_role_state(RoleID, return),
    %% 成就 add by caochuncheng 2011-03-17
    Func = {func,fun()->  
                     %% 增加守边的广播
                     case ShouldGiveRewardProp of
                         true->
                             case mod_mission_misc:get_choose_prop_reward(RequestRecord,FinalPropList) of
                                 #p_mission_prop{prop_id=PropID,prop_type=PropType} ->
                                     PropName = mod_mission_misc:get_prop_name(PropID,PropType),
                                     RoleNameStr = get_role_name_str(RoleID),
                                     Notify = common_misc:format_lang(?_LANG_MISSION_SB_GET_GOOD_THING, [RoleNameStr, PropName]),
                                     common_broadcast:bc_send_msg_world(
                                       ?BC_MSG_TYPE_CENTER, ?BC_MSG_SUB_TYPE, Notify);
                                 _ ->
                                     ignore
                             end;
                         _ ->
                             ignore
                     end,
                     catch mod_accumulate_exp:role_do_protect_faction(RoleID),
                     %% 增加守边的日志记录,by wuzesen
                     FailTimes = mod_mission_data:get_fail_times(RoleID, MissionBaseInfo),
                     catch common_loop_mission_logger:log_shoubian( {RoleID,1,NewSuccTimes,FailTimes} )
            end},
    mod_mission_misc:push_trans_func(RoleID,Func),
    
    mission_model_common:common_complete(RoleID, MissionID,  NewMissionBaseInfo, RequestRecord);%%给奖励
%%失败
finish(timeout, PInfo, RequestRecord) ->
    SuccTimes = mod_mission_data:get_succ_times(RoleID, MissionBaseInfo),
    NewSuccTimes = SuccTimes,
    
    ShouBianRewardList = mod_mission_data:get_setting(shoubian_reward),
    Level = PInfo#p_mission_info.accept_level,
    {Level, _SuccExp, TimeOutExp, _SuccPrestige, TimeOutPrestige, _FinalPropList} = lists:keyfind(Level, 1, ShouBianRewardList),
    
    BaseRewardData = #mission_reward_data{rollback_times=1,
                                          prop_reward_formula=?MISSION_PROP_REWARD_FORMULA_NO,
                                          attr_reward_formula=?MISSION_ATTR_REWARD_FORMULA_NORMAL,
                                          exp=TimeOutExp*NewSuccTimes,
                                          prestige=TimeOutPrestige,
                                          silver=0,
                                          silver_bind=0,
                                          prop_reward=[]},
    
    NewMissionBaseInfo = MissionBaseInfo#mission_base_info{reward_data=BaseRewardData},
    set_role_state(RoleID, timeout),
    
    %% 增加守边的日志记录,by wuzesen
    Func = {func,fun()->  
                         FailTimes = mod_mission_data:get_fail_times(RoleID, MissionBaseInfo),
                         catch common_loop_mission_logger:log_shoubian( {RoleID,2,NewSuccTimes,FailTimes} )
            end},
    mod_mission_misc:push_trans_func(RoleID,Func),
    mission_model_common:common_complete(RoleID, MissionID,  NewMissionBaseInfo, RequestRecord, false).

%%@doc 取消任务
cancel(PInfo, RequestRecord) ->
    TransFun = fun() ->
                       mod_mission_data:set_fail_times(RoleID, MissionBaseInfo, 1),
                       mission_model_common:common_cancel(RoleID, MissionID, MissionBaseInfo,RequestRecord, PInfo)
               end,
    TransResult = ?DO_TRANS_FUN( TransFun ),
    case TransResult of
        {atomic, _}->
            set_role_state(RoleID, return),
            SuccTimes = mod_mission_data:get_succ_times(RoleID, MissionBaseInfo),
            FailTimes = mod_mission_data:get_fail_times(RoleID, MissionBaseInfo),
            catch common_loop_mission_logger:log_shoubian( {RoleID,3,SuccTimes,FailTimes} );
        _ ->
            ignore
    end,
    TransResult.
        
        

%%@doc 侦听器触发
listener_trigger(_ListenerData, _PInfo,_TriggerParam) -> ok.

%%@doc 初始化任务pinfo
%%@return #p_mission_info{} | false
init_pinfo(OldPInfo) -> 
    NewPInfo = mission_model_common:init_pinfo(RoleID, OldPInfo, MissionBaseInfo),
    CurrentStatus = NewPInfo#p_mission_info.current_model_status,
    if
        CurrentStatus =/= ?MISSION_MODEL_STATUS_FIRST ->
            NewPInfo;
        true ->
            case auth_show(NewPInfo) of
                true->
                    NewPInfo;
                _ ->
                    false
           end
    end.

%% 设置守边状态
set_role_state(RoleID, doing) ->
    do_set_role_state(RoleID, 1);
set_role_state(RoleID, timeout) ->
    do_set_role_state(RoleID, 2);
set_role_state(RoleID, return) ->
    do_set_role_state(RoleID, 0).

do_set_role_state(RoleID, State) ->
    [RoleState] = db:dirty_read(?DB_ROLE_STATE, RoleID),
    NewRoleState = RoleState#r_role_state{shou_bian=State},
    db:dirty_write(?DB_ROLE_STATE, NewRoleState).