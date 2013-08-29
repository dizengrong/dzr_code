%% Author: chixiaosheng
%% Created: 2011-4-5
%% Description: 任务通用模型
-module(mission_model_common).

%%
%% Include files
%%
-include("mission.hrl").  

%%
%% Exported Functions
%%
-export([
			common_do/5,
			common_complete/4,
			common_complete/5,
			common_cancel/5,
			init_pinfo/3,
			change_model_status/5,
			reload_at_oclock/2
		]).

%%-----------------------------任务执行逻辑处理区-Start-----------------------------
%%@doc PInfo由模型传入 是因为有些玩法需要对PInfo里的int_data_x(1,2,3,4)做特殊处理
common_do(RoleID, MissionID,MissionBaseInfo,RequestRecord, PInfo) ->
    MaxModelStatus = MissionBaseInfo#mission_base_info.max_model_status,
    CurrentModelStatus = PInfo#p_mission_info.current_model_status,
    if
        CurrentModelStatus =:= MaxModelStatus ->%%提交任务
            common_complete(RoleID, MissionID,MissionBaseInfo,RequestRecord);
        true ->%%切换状态
            change_model_status(RoleID, MissionID,MissionBaseInfo,PInfo, +1)
    end.


%% --------------------------------------------------------------------
%% 完成任务，最后的提交任务
%% -------------------------------------------------------------------- 
common_complete(RoleID, MissionID,MissionBaseInfo,RequestRecord) ->
    common_complete(RoleID, MissionID,MissionBaseInfo,RequestRecord, true).
common_complete(RoleID, MissionID,MissionBaseInfo,RequestRecord, IsSuccess) ->
    %% 一定要先把次数写入
    if
        IsSuccess =:= true ->
            mod_mission_data:set_succ_times(RoleID, MissionBaseInfo, 1);
        true ->
            mod_mission_data:set_fail_times(RoleID, MissionBaseInfo, 1)
    end,
            
    RewardData = mod_mission_misc:call_mission_reward(RoleID, MissionID, MissionBaseInfo, RequestRecord),
    MaxModelStatus = MissionBaseInfo#mission_base_info.max_model_status,
    Result =  #m_mission_do_toc{
                                id=MissionID,
                                current_status=?MISSION_STATUS_FINISH,
                                pre_status=?MISSION_STATUS_FINISH,
                                current_model_status=MaxModelStatus,
                                pre_model_status=MaxModelStatus,
                                reward_data=RewardData,
                                code=?MISSION_CODE_SUCC,
                                code_data=[]},
    %%从任务列表里删除

    %%触发后置任务的列表
    update_next_mission(RoleID,MissionBaseInfo),
    
    mod_mission_data:del_pinfo(RoleID, MissionID, notify),
    do_retake_check(RoleID,MissionBaseInfo),
    %%调用hook
    #mission_base_info{id=MissionID,type=MissionType,big_group=BigGroup,small_group=SmallGroup} = MissionBaseInfo,
    
    _MissionHookRecord =  
        #r_mission_hook{role_id = RoleID,
                        mission_id = MissionID,
                        mission_type = MissionType,
                        big_group = BigGroup,
                        small_group = SmallGroup,
                        do_type = 0, %%执行类型: 0正常 1委托(自动任务)
                        do_times = 1},
    Func = {func,
            fun()->  
                    hook_mission_update:hook(mission_commit,RoleID,MissionBaseInfo) 
            end},
    mod_mission_misc:push_trans_func(RoleID,Func),   
    Result.

%% --------------------------------------------------------------------
%% 切换状态
%% -------------------------------------------------------------------- 
change_model_status(RoleID, MissionID,MissionBaseInfo,PInfo, ChangeStep) ->
    MaxModelStatus = MissionBaseInfo#mission_base_info.max_model_status,
    CurrentModelStatus = PInfo#p_mission_info.current_model_status,
    NewModelStatus = CurrentModelStatus+ChangeStep,
    CurrentStatus = PInfo#p_mission_info.current_status,
    if
        NewModelStatus =:= MaxModelStatus ->
            %%触发后置任务的列表
            update_next_mission(RoleID,MissionBaseInfo),
            %%调用hook
            Func1 = {func,fun()->  hook_mission_update:hook(mission_finish,RoleID,MissionBaseInfo) end},
            mod_mission_misc:push_trans_func(RoleID,Func1),
            NewStatus = ?MISSION_STATUS_FINISH;
        true ->
            NewStatus = ?MISSION_STATUS_DOING
    end,
    if
        CurrentModelStatus =:= ?MISSION_MODEL_STATUS_FIRST ->
            %%调用hook
            Func2 = {func,fun()->  hook_mission_update:hook(mission_accept,RoleID,MissionBaseInfo) end},
            mod_mission_misc:push_trans_func(RoleID,Func2),
            {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
            AcceptLevel = RoleAttr#p_role_attr.level;
        true ->
            AcceptLevel = PInfo#p_mission_info.accept_level
    end,
    Now = common_tool:now(),
    NewPinfo = PInfo#p_mission_info{
        accept_level=AcceptLevel,
        current_status = NewStatus,
        pre_status=CurrentStatus,
        current_model_status = NewModelStatus,
        pre_model_status=CurrentModelStatus,
        accept_time=Now,
        status_change_time=Now
    },
    mod_mission_data:set_pinfo(RoleID, NewPinfo, notify),
    #m_mission_do_toc{
        id=MissionID,
        current_status=NewStatus,
        pre_status=CurrentStatus,
        current_model_status=NewModelStatus,
        pre_model_status=CurrentModelStatus,
        code=?MISSION_CODE_SUCC,
        code_data=[]}.

%% --------------------------------------------------------------------
%% 检查是否能够重接任务
%% -------------------------------------------------------------------- 
do_retake_check(RoleID, MissionBaseInfo) ->
    do_retake_check(RoleID, MissionBaseInfo, false).
do_retake_check(RoleID, MissionBaseInfo, GroupNoRandom) ->
    SmallGroup = MissionBaseInfo#mission_base_info.small_group,
    
    if
        SmallGroup =/= 0 andalso GroupNoRandom =:= false ->
            %%下面是测试时使用的快捷方法 你Y的老是随机的有木有
            %%MissionID = MissionBaseInfo#mission_base_info.id,
            %%b_mission_model:call_mission_model(RoleID, MissionID, init_pinfo, [false]);
            %%下面的是真实代码
            RandomMissionID = mod_mission_data:get_group_random_one(SmallGroup),
            PInfo = b_mission_model:call_mission_model(RoleID, RandomMissionID, init_pinfo, [false]);
        SmallGroup =/= 0 ->
            MissionID = MissionBaseInfo#mission_base_info.id,
            PInfo = b_mission_model:call_mission_model(RoleID, MissionID, init_pinfo, [false]);
        true ->
            MissionID = MissionBaseInfo#mission_base_info.id,
            PInfo = b_mission_model:call_mission_model(RoleID, MissionID, init_pinfo, [false])
    end,
    case PInfo of
        false->
            ignore;
        _ ->
            mod_mission_data:set_pinfo(RoleID, PInfo, notify)
    end.
    
%%-----------------------------任务执行逻辑处理区-END-----------------------------


%%@doc PInfo由模型传入 是因为有些玩法需要对PInfo里的int_data_x(1,2,3,4)做特殊处理
common_cancel(RoleID, MissionID,MissionBaseInfo,_RequestRecord, _PInfo) ->
    mod_mission_data:del_pinfo(RoleID, MissionID, notify),
    do_retake_check(RoleID, MissionBaseInfo, true),
    %%调用hook
    Func = {func,fun()->  hook_mission_update:hook(mission_cancel,RoleID,MissionBaseInfo) end},
    mod_mission_misc:push_trans_func(RoleID,Func),
    
    #m_mission_cancel_toc{id=MissionID, code=?MISSION_CODE_SUCC}.

init_pinfo(RoleID, false, MissionBaseInfo) ->
    new_pinfo(RoleID, MissionBaseInfo);
init_pinfo(RoleID, OldPInfo, MissionBaseInfo) ->
    %%循环任务，在每天重新加载任务列表时，需要将完成当前完成次数置零
    case MissionBaseInfo of
        #mission_base_info{type=?MISSION_TYPE_LOOP}->
            CounterData = mod_mission_data:get_counter(RoleID, MissionBaseInfo),
            Today = date(),
            case CounterData#mission_counter.last_clear_counter_time of
                undefined->
                    OldPInfo;
                {Today,_}->
                    OldPInfo;
                _ ->
                    OldPInfo#p_mission_info{commit_times=0,succ_times=0}
            end;
        _ ->
            OldPInfo
    end.

new_pinfo(RoleID, MissionBaseInfo) ->
    %%?ERROR_MSG("MissionBaseInfo:~w", [MissionBaseInfo]),
    MaxModelStatus = MissionBaseInfo#mission_base_info.max_model_status,
    if
        MaxModelStatus =:= ?MISSION_MODEL_STATUS_FIRST ->
            CurrentStatus = ?MISSION_STATUS_FINISH;
        true ->
            CurrentStatus = ?MISSION_STATUS_NOT_ACCEPT
    end,
    CounterData = mod_mission_data:get_counter(RoleID, MissionBaseInfo),
    CurrentCommitTimes = CounterData#mission_counter.commit_times,
    CurrentSuccTimes = CounterData#mission_counter.succ_times,
    #p_mission_info{id=MissionBaseInfo#mission_base_info.id,
                    model=MissionBaseInfo#mission_base_info.model,
                    type=MissionBaseInfo#mission_base_info.type,
                    current_status=CurrentStatus,
                    pre_status=CurrentStatus,
                    current_model_status=?MISSION_MODEL_STATUS_FIRST,
                    pre_model_status=?MISSION_MODEL_STATUS_FIRST,
                    commit_times=CurrentCommitTimes,
                    succ_times=CurrentSuccTimes,
                    accept_time=0,
                    status_change_time=0,
                    listener_list=[],
                    int_list_1=[],
                    int_list_2=[],
                    int_list_3=[],
                    int_list_4=[]}.

%%@doc 处理后置任务
update_next_mission(RoleID,MissionBaseInfo)->
    NextMissionList = MissionBaseInfo#mission_base_info.next_mission_list,
    update_next_mission_2(RoleID, NextMissionList) .
update_next_mission_2(_RoleID,0)->
    ignore;
update_next_mission_2(_RoleID,[])->
    ignore;
update_next_mission_2(RoleID,[MissionID|T])->
    update_next_mission_3(RoleID,MissionID),
    update_next_mission_2(RoleID,T).

update_next_mission_3(RoleID,NextMissionID)->
    case b_mission_model:call_mission_model(RoleID, NextMissionID, init_pinfo, [false]) of
        false->
            ignore;
        NextPInfo->
            mod_mission_data:set_pinfo(RoleID, NextPInfo,notify)
    end.

%% 凌晨执行一次
reload_at_oclock(RoleID, VS) ->
	case mod_map_role:get_role_base(RoleID) of
		{ok, RoleBase} ->
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
					mod_mission_unicast:c_unicast(RoleID, Line),
					?TRY_CATCH(mod_mission_change_skin:hook_reload_mission(RoleBase));
				Other ->
					?ERROR_MSG("大循环处理玩家列表更新发生系统错误-->~nRoleID:~w~n VS:~w~n Other:~w~n Stacktrace:~w~n<--", 
							   [RoleID, 
								VS,
								Other, 
								erlang:get_stacktrace()])
					
			end;
		_ ->
			ignore
	end.
