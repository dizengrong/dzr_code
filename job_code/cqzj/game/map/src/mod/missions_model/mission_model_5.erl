%% Author: chixiaosheng
%% Created: 2011-4-9
%% Description: 道具搜集模型 - 3次对话 - 中间那只NPC给道具
%%      model_status: 必须是3个Status
%%      listener：必须是道具的侦听器
-module(mission_model_5, [RoleID, MissionID, MissionBaseInfo]).
-behaviour(b_mission_model).

%%
%% Include files
%%
-include("mission.hrl").  
-define(MISSION_MODEL_5_GIVE_PROP_STATUS, 1).

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
                case i_deal_listener(PInfo, RequestRecord) of
                    ignore ->
                        #m_mission_do_toc{
                            id=MissionID,
                            current_status=PInfo#p_mission_info.current_status,
                            pre_status=PInfo#p_mission_info.pre_status,
                            current_model_status=PInfo#p_mission_info.current_model_status,
                            pre_model_status=PInfo#p_mission_info.pre_model_status,
                            code=?MISSION_CODE_SUCC,
                            code_data=[]};
                    NewPInfo ->
                        mission_model_common:common_do(RoleID, MissionID,MissionBaseInfo,RequestRecord, NewPInfo)
                end
        end,
    ?DO_TRANS_FUN( TransFun ).


%%@doc 取消任务
cancel(PInfo, RequestRecord) ->
    TransFun = 
        fun() ->
                Result = mission_model_common:common_cancel(RoleID, MissionID, MissionBaseInfo, RequestRecord, PInfo),
                
                %%@doc 删除侦听器
                ListenerList = PInfo#p_mission_info.listener_list,
                i_remove_all_listener(ListenerList),
                
                Result
        end,
    ?DO_TRANS_FUN( TransFun ).

%%@doc 侦听器触发
listener_trigger(ListenerData, PInfo,_TriggerParam) -> 
    TransFun = fun() ->
                       ListenerList = PInfo#p_mission_info.listener_list,
                       PropTypeID = ListenerData#mission_listener_trigger_data.value,
                       i_trigger_prop(ListenerList, PInfo, PropTypeID, 0, 0, [], null)
               end,
    ?DO_TRANS_FUN( TransFun ).


%%@doc 如果是刚接任务 加侦听器
i_deal_listener(PInfo, RequestRecord) ->
    CurrentModelStatus = PInfo#p_mission_info.current_model_status,
    MaxModelStatus = MissionBaseInfo#mission_base_info.max_model_status,
    
    if
        CurrentModelStatus =:= ?MISSION_MODEL_STATUS_FIRST ->
            ListenerListConfig = MissionBaseInfo#mission_base_info.listener_list,
            ListenerList = 
                lists:map(fun(ListenerDataConfig) ->
                    ListenerType = ListenerDataConfig#mission_listener_data.type,
                    NeedPropTypeID = ListenerDataConfig#mission_listener_data.value,
                    NeedNum = ListenerDataConfig#mission_listener_data.need_num,
                    [GivePropNpcID] = ListenerDataConfig#mission_listener_data.int_list,
                    %%道具侦听器
                    mod_mission_data:join_to_listener(RoleID, MissionID, ListenerType, NeedPropTypeID),
                    %%直接将玩家侦听器数据设置为已经满足要求
                    #p_mission_listener{type=ListenerType,
                                        value=NeedPropTypeID,
                                        int_list=[GivePropNpcID],
                                        need_num=NeedNum,
                                        current_num=0}
                end, ListenerListConfig),
                %%怪物ID/怪物当前数量/所需数量
            PInfo#p_mission_info{listener_list=ListenerList};
        CurrentModelStatus =:= ?MISSION_MODEL_5_GIVE_PROP_STATUS ->
            ListenerListConfig = PInfo#p_mission_info.listener_list,
            lists:foreach(fun(ListenerData) ->
                NeedPropTypeID = ListenerData#p_mission_listener.value,
                NeedNum = ListenerData#p_mission_listener.need_num,
                [GivePropNpcID] = ListenerData#p_mission_listener.int_list,
                if
                    GivePropNpcID =:= RequestRecord#m_mission_do_tos.npc_id ->
                        mod_mission_misc:give_prop(RoleID, NeedPropTypeID, NeedNum),
                        ListenerData#p_mission_listener{current_num=NeedNum};
                    true ->
                        ListenerData
                end
                end, ListenerListConfig),
             ignore;
        CurrentModelStatus =:= MaxModelStatus ->
            %%任务即将提交 删除侦听器
            ListenerList = PInfo#p_mission_info.listener_list,
            i_remove_all_listener(ListenerList),
            PInfo;
        true ->
            PInfo
    end.

i_trigger_prop([], PInfo, _GetPropTypeID, TotalNeed, 
               Complete, NewListenerList, MatchListenerData) ->
    NewPInfo = PInfo#p_mission_info{listener_list=NewListenerList},
    MaxModelStauts = MissionBaseInfo#mission_base_info.max_model_status,
    CurrentModelStatus = PInfo#p_mission_info.current_model_status,
    
    if
        MatchListenerData =:= null ->
            %%居然没找到这个侦听器
            ignore;
        TotalNeed =:= Complete 
          andalso
        MaxModelStauts =:= CurrentModelStatus->
            ignore;
        TotalNeed =:= Complete ->
            %%切换状态                      
            %%删除侦听器
            mission_model_common:change_model_status(RoleID, MissionID, MissionBaseInfo, NewPInfo, +1),
            
            %%发送最后一次的任务侦听器数据
            DataRecord = #m_mission_listener_toc{mission_id=MissionID, listener=MatchListenerData},
            mod_mission_unicast:p_unicast(RoleID, ?DEFAULT_UNIQUE, 
                                          ?MISSION, ?MISSION_LISTENER, 
                                          DataRecord),
            mod_mission_unicast:c_unicast(RoleID);
        TotalNeed > Complete ->
            if
                CurrentModelStatus =:= MaxModelStauts ->%%玩家可能把道具扔了
                    mission_model_common:change_model_status(RoleID, MissionID, MissionBaseInfo, NewPInfo, -1);
                true ->
                    %%单独更新侦听器数据
                    mod_mission_data:set_pinfo(RoleID, NewPInfo),
                    DataRecord = #m_mission_listener_toc{mission_id=MissionID, listener=MatchListenerData},
                    mod_mission_unicast:p_unicast(RoleID, ?DEFAULT_UNIQUE, ?MISSION, ?MISSION_LISTENER, DataRecord)
            end,
            mod_mission_unicast:c_unicast(RoleID)
    end;

 i_trigger_prop([ListenerData|ListenerList], PInfo, GetPropTypeID, TotalNeed, 
               Complete, NewListenerList, MatchListenerData) ->
    
    
    NeedPropTypeID = ListenerData#p_mission_listener.value,
    CurrentNum = ListenerData#p_mission_listener.current_num,
    NeedNum = ListenerData#p_mission_listener.need_num,
    
    if
        GetPropTypeID =:= NeedPropTypeID ->
            NewCurrentNum = mod_mission_misc:get_prop_num_in_bag(RoleID,GetPropTypeID);
        true ->
            NewCurrentNum = CurrentNum
    end,

    if
        NewCurrentNum >= NeedNum ->
            NewComplete = Complete+1;
        NewCurrentNum < NeedNum ->
            NewComplete = Complete
    end,
    NewListenerData = ListenerData#p_mission_listener{current_num=NewCurrentNum},
    
    if
        GetPropTypeID =:= NeedPropTypeID ->
            MatchListenerData2 = NewListenerData;
        true ->
            MatchListenerData2 = MatchListenerData
    end,
    
    i_trigger_prop(ListenerList, PInfo, 
                   GetPropTypeID, TotalNeed+1, 
                   NewComplete, [NewListenerData|NewListenerList], 
                   MatchListenerData2).

%%@doc 删除所有侦听器
i_remove_all_listener(ListenerList) ->
    lists:foreach(fun(ListenerData) ->
        ListenerType = ListenerData#p_mission_listener.type,
        NeedPropTypeID = ListenerData#p_mission_listener.value,
        NeedNum = ListenerData#p_mission_listener.need_num,
        
        mod_mission_data:remove_from_listener(
          RoleID, MissionID, 
          ListenerType, NeedPropTypeID),
        
        mod_mission_misc:del_prop(RoleID, NeedPropTypeID, NeedNum)
    end, ListenerList).
    
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