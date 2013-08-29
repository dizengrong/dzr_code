%% Author: caochuncheng
%% Created: 2011-10-13
%% Description: 使用道具完成任务类型
%%      model_status: 3个status
%%      listener：必须是道具的侦听器
-module(mission_model_17, [RoleID, MissionID, MissionBaseInfo]).
-behaviour(b_mission_model).

%%
%% Include files
%%
-include("mission.hrl").  
-define(MISSION_MODEL_17_STATUS_DOING, 1). %% 此状态下需要玩家使用道具

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
                i_remove_all_listener(ListenerList,true),
                
                Result
        end,
    ?DO_TRANS_FUN( TransFun ).

%%@doc 侦听器触发
listener_trigger(ListenerData, PInfo,_TriggerParam) -> 
    TransFun = fun() ->
                       ListenerList = PInfo#p_mission_info.listener_list,
                       ListenerTriggerType = ListenerData#mission_listener_trigger_data.type,
                       ListenerTriggerValue = ListenerData#mission_listener_trigger_data.value,
                       i_trigger(ListenerTriggerType, PInfo, ListenerTriggerValue, ListenerList)
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
                    IntList =  ListenerDataConfig#mission_listener_data.int_list,
                    case ListenerType of
                        ?MISSION_LISTENER_TYPE_GIVE_USE_PROP ->
                            [GivePropNpcID] = ListenerDataConfig#mission_listener_data.int_list,
                            if  GivePropNpcID =:= RequestRecord#m_mission_do_tos.npc_id ->
                                    mod_mission_misc:give_prop(RoleID, NeedPropTypeID, NeedNum),
                                    CurrentNum = 0;
                                true ->
                                    CurrentNum = 0
                            end;
                        _ ->
                            CurrentNum = 0
                    end,
                    %%道具侦听器
                    mod_mission_data:join_to_listener(RoleID, MissionID, ListenerType, NeedPropTypeID),
                    %%直接将玩家侦听器数据设置为已经满足要求
                    #p_mission_listener{type=ListenerType,
                                        value=NeedPropTypeID,
                                        int_list=IntList,
                                        need_num=NeedNum,
                                        current_num=CurrentNum}
                end, ListenerListConfig),
                %%怪物ID/怪物当前数量/所需数量
            PInfo#p_mission_info{listener_list=ListenerList};
        CurrentModelStatus =:= MaxModelStatus ->
            %%任务即将提交 删除侦听器
            ListenerList = PInfo#p_mission_info.listener_list,
            i_remove_all_listener(ListenerList,false),
            PInfo;
        true ->
            PInfo
    end.


i_trigger(?MISSION_LISTENER_TYPE_GIVE_USE_PROP, PInfo, GiveUseTypeID, ListenerList) ->
    i_trigger_give_use_prop(ListenerList, PInfo, GiveUseTypeID, 0, 0, [], null);
i_trigger(?MISSION_LISTENER_TYPE_PROP, PInfo, PropTypeID, ListenerList) ->
    i_trigger_prop(ListenerList, PInfo, PropTypeID, 0, 0, [], null).

%% 使用一个赠送的任务道具
i_trigger_give_use_prop([], PInfo, _GiveUseTypeID, TotalNeed, Complete, NewListenerList, MatchListenerData) ->
    NewPInfo = PInfo#p_mission_info{listener_list=NewListenerList},
    MaxModelStauts = MissionBaseInfo#mission_base_info.max_model_status,
    CurrentModelStatus = PInfo#p_mission_info.current_model_status,
    if MatchListenerData =:= null ->%%居然没找到这个侦听器
           ignore;
       TotalNeed =:= Complete andalso  MaxModelStauts =:= CurrentModelStatus->
           ignore;
       TotalNeed =:= Complete ->
           %%切换状态    删除侦听器
           mission_model_common:change_model_status(RoleID, MissionID, MissionBaseInfo, NewPInfo, +1),
           %%发送最后一次的任务侦听器数据
           DataRecord = #m_mission_listener_toc{mission_id=MissionID, listener=MatchListenerData},
           mod_mission_unicast:p_unicast(RoleID, ?DEFAULT_UNIQUE, ?MISSION, ?MISSION_LISTENER, DataRecord),
           mod_mission_unicast:c_unicast(RoleID);
       TotalNeed > Complete ->
            %%单独更新侦听器数据
            mod_mission_data:set_pinfo(RoleID, NewPInfo),
            DataRecord = #m_mission_listener_toc{mission_id=MissionID, listener=MatchListenerData},
            mod_mission_unicast:p_unicast(RoleID, ?DEFAULT_UNIQUE, ?MISSION, ?MISSION_LISTENER, DataRecord),
            mod_mission_unicast:c_unicast(RoleID)
    end;
i_trigger_give_use_prop([ListenerData|ListenerList], PInfo, GiveUseTypeID, TotalNeed,Complete, NewListenerList, MatchListenerData) ->
    NeedGiveUseTypeID = ListenerData#p_mission_listener.value,
    CurrentNum = ListenerData#p_mission_listener.current_num,
    NeedNum = ListenerData#p_mission_listener.need_num,
    if GiveUseTypeID =:= NeedGiveUseTypeID ->
            NewCurrentNum = CurrentNum+1;
        true ->
            NewCurrentNum = CurrentNum
    end,
    if NewCurrentNum >= NeedNum ->
            NewComplete = Complete+1;
       true ->
            NewComplete = Complete
    end,
    NewListenerData = ListenerData#p_mission_listener{current_num=NewCurrentNum},
    if GiveUseTypeID =:= NeedGiveUseTypeID ->
            NewMatchListenerData = NewListenerData;
        true ->
            NewMatchListenerData = MatchListenerData
    end,
    i_trigger_give_use_prop(ListenerList, PInfo, GiveUseTypeID, TotalNeed+1, NewComplete, [NewListenerData|NewListenerList], NewMatchListenerData).


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
i_remove_all_listener(ListenerList,ShouldDelProp) ->
    lists:foreach(fun(ListenerData) ->
        ListenerType = ListenerData#p_mission_listener.type,
        NeedPropTypeID = ListenerData#p_mission_listener.value,
        NeedNum = ListenerData#p_mission_listener.need_num,
        
        mod_mission_data:remove_from_listener(
          RoleID, MissionID, 
          ListenerType, NeedPropTypeID),
        
        case ShouldDelProp of
            true->
                mod_mission_misc:del_prop(RoleID, NeedPropTypeID, NeedNum);
            _ ->
                ok
        end
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