%%% -------------------------------------------------------------------
%%% Author  : xiaosheng
%%% Description : 任务模块 Behaviour
%%%
%%% Created : 2011-03-22
%%% -------------------------------------------------------------------
-module(b_mission_model).
-include("mission.hrl").  
  
-export([behaviour_info/1]).
-export([do/2,
         cancel/2,
         dispatch_listener/3,
         dispatch_listener/4,
         call_mission_model/4]).

behaviour_info(callbacks) -> 
    [{auth_accept, 1},%%验证是否能够接任务(未接的任务)
     {auth_show, 1},%%验证是否能够显示给玩家(未接的任务)
     {do, 2},%%做任务(已接的任务)
     {cancel, 2},%%取消任务(已接的任务)
     {init_pinfo, 1},%%初始化任务数据
     {listener_trigger, 3}%%侦听器触发
    ];

behaviour_info(_Other) ->
    undefined.


%% --------------------------------------------------------------------
%% 操作任务模型里的方法
%% -------------------------------------------------------------------- 
%%调用模型里的方法
call_mission_model(RoleID, MissionID, Func, Params) ->
    MissionBaseInfo = mod_mission_data:get_base_info(MissionID), 
    ModelID = MissionBaseInfo#mission_base_info.model,
    ModuleName = erlang:list_to_atom(lists:concat(["mission_model_", ModelID])),
    erlang:apply(ModuleName:new(RoleID, MissionID, MissionBaseInfo), Func, Params).

%%@doc 取消任务
cancel(RoleID, RequestRecord)->
    MissionID = RequestRecord#m_mission_cancel_tos.id,
    case mod_mission_data:get_pinfo(RoleID, MissionID) of
        PInfo when is_record(PInfo,p_mission_info)->
            assert_cancel_mission(PInfo,MissionID),
            call_mission_model(RoleID, MissionID, cancel, [PInfo, RequestRecord]);
        Info2 ->
            notify_del_mission(RoleID,MissionID),
            ?ERROR_MSG("错误的PInfo,Info2=~w,RoleID=~w,MissionID=~w,RequestRecord=~w",
                       [Info2,RoleID,MissionID,RequestRecord]),
            throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_PMISSIONINFO_NOT_FOUND, [MissionID]})
    end.

assert_cancel_mission(PInfo,MissionID)->
    #p_mission_info{current_model_status=CurrentModelStatus,type=MissionType} = PInfo,
    case common_config_dyn:find(mission_fb,mission_fb_id_list) of
        [MissionFbIdList]-> next;
        _ ->    MissionFbIdList = []
    end,
    
    if
        CurrentModelStatus =:= ?MISSION_MODEL_STATUS_FIRST ->
            throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_NOT_FOUND, [MissionID]});
        MissionType =:= ?MISSION_TYPE_TITLE->
            throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_TITLE_MISSION_CANNOT_CANCEL, [MissionID]});
        true ->
            case lists:member(MissionID, MissionFbIdList) of
                true->
                    throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_CANNOT_CANCEL, [MissionID]});
                _ ->
                    next
            end
    end,
    ok.
            

%%@doc 通知前端删除该任务
notify_del_mission(RoleID,MissionID) when is_integer(RoleID)->
    mod_mission_unicast:p_update_unicast(del, RoleID, MissionID),
    mod_mission_unicast:c_unicast(RoleID).

%%@doc 执行任务
do(RoleID, RequestRecord) ->
    MissionID = RequestRecord#m_mission_do_tos.id, 
    case mod_mission_data:get_pinfo(RoleID, MissionID) of
        PInfo when is_record(PInfo,p_mission_info)->
            CurrentModelStatus = PInfo#p_mission_info.current_model_status,
            if
                CurrentModelStatus =:= ?MISSION_MODEL_STATUS_FIRST ->
                    Auth = call_mission_model(RoleID, MissionID, auth_accept, [PInfo]);
                true ->
                    Auth = true
            end,
            case Auth of
                true ->
                    call_mission_model(RoleID, MissionID, do, [PInfo, RequestRecord]);
                {false, ReasonCode, ReasonIntData} ->
                    throw({?MISSION_ERROR_MAN, ReasonCode, ReasonIntData})
            end;
		false->
			notify_del_mission(RoleID,MissionID),
            throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_PMISSIONINFO_NOT_FOUND, [MissionID]});
        Info2 ->
            notify_del_mission(RoleID,MissionID),
            ?ERROR_MSG("错误的PInfo,Info2=~w,RoleID=~w,MissionID=~w,RequestRecord=~w",
                       [Info2,RoleID,MissionID,RequestRecord]),
            throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_PMISSIONINFO_NOT_FOUND, [MissionID]})
    end.
            

%%@doc 派发侦听器
dispatch_listener(RoleID, MissionID, ListenerTriggerData) ->
    dispatch_listener(RoleID, MissionID, ListenerTriggerData,0).

dispatch_listener(RoleID, MissionID, ListenerTriggerData,TriggerParam) when is_integer(MissionID) ->
    PInfo = mod_mission_data:get_pinfo(RoleID, MissionID),
    if
        PInfo =:= false ->
            TransFun = 
                fun() ->
                        Type = ListenerTriggerData#mission_listener_trigger_data.type,
                        Value = ListenerTriggerData#mission_listener_trigger_data.value,
                        mod_mission_data:remove_from_listener(RoleID, MissionID, Type, Value),
                        ?ERROR_MSG("~ts:MissionID:~w, ListenerTriggerData:~w", 
                                   ["侦听器触发了，但找不到对应任务，系统强制删除侦听器", MissionID, ListenerTriggerData])
                end,
            common_transaction:transaction( TransFun );
        true ->
            call_mission_model(RoleID, MissionID, listener_trigger, [ListenerTriggerData, PInfo,TriggerParam])
    end;
dispatch_listener(RoleID, MissionIDList, ListenerTriggerData,TriggerParam) when is_list(MissionIDList) ->
    try
        lists:foreach(fun(MissionID) ->
            case dispatch_listener(RoleID, MissionID, ListenerTriggerData,TriggerParam) of
                {atomic, _} ->
                    ignore;
                Error ->
                    throw(Error)
            end
        end, MissionIDList)
    catch
        _:Error ->
            Error
    end.
