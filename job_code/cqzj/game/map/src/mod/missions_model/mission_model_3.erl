%% Author: chixiaosheng
%% Created: 2011-4-8
%% Description: 打怪道具掉落模型
%%      model_status: 必须是3个Status
%%      listener：必须是两个Listener，一个怪物/一个道具
-module(mission_model_3, [RoleID, MissionID, MissionBaseInfo]).
-behaviour(b_mission_model).

%%
%% Include files
%%
-include("mission.hrl").  

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

%%打怪模型的第二个状态，该状态表示正在侦听怪物/道具
-define(MISSION_MODEL_2_STATUS_DOING, 1).

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
                if
                    CurrentModelStatus =:= ?MISSION_MODEL_2_STATUS_DOING ->
                        throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_STATUS_ERROR, [CurrentModelStatus]});
                    true ->
                        ignore
                end,
                NewPInfo = i_deal_listener(PInfo),
                mission_model_common:common_do(RoleID, MissionID,MissionBaseInfo,RequestRecord, NewPInfo)
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
listener_trigger(_ListenerData, false,_TriggerParam) ->
    ?ERROR_MSG("侦听器触发了一个不存在的任务，RoleID=~w,MissionID=~w,MissionBaseInfo=~w",[RoleID,MissionID,MissionBaseInfo]),
    ignore;
listener_trigger(ListenerData, PInfo,_TriggerParam) -> 
    TransFun = fun() ->
                       ListenerList = PInfo#p_mission_info.listener_list,
                       ListenerTriggerType = ListenerData#mission_listener_trigger_data.type,
                       ListenerTriggerValue = ListenerData#mission_listener_trigger_data.value,
                       i_trigger(ListenerTriggerType, PInfo, ListenerTriggerValue, ListenerList)
               end,
    ?DO_TRANS_FUN( TransFun ).


%%@doc 如果是刚接任务 加侦听器
i_deal_listener(PInfo) ->
    CurrentModelStatus = PInfo#p_mission_info.current_model_status,
    MaxModelStatus = MissionBaseInfo#mission_base_info.max_model_status,
    
    if
        CurrentModelStatus =:= ?MISSION_MODEL_STATUS_FIRST ->
            %%未接任务 添加侦听器
            ListenerListConfig = MissionBaseInfo#mission_base_info.listener_list,
            {MapID,NeedMonsterType,NeedPropTypeID,NeedPropNum,PropDropRate} = 
                lists:foldl(fun(E,AccIn)-> 
                                    i_deal_listener_2(E,AccIn)
                            end, {0,0,0,0,0}, ListenerListConfig),
            TransIntList = [MapID, NeedMonsterType, PropDropRate],
            ListenerList = [#p_mission_listener{type=?MISSION_LISTENER_TYPE_PROP,
                                                value=NeedPropTypeID,
                                                int_list=TransIntList,
                                                need_num=NeedPropNum,
                                                current_num=0}],
            PInfo#p_mission_info{listener_list=ListenerList};
        CurrentModelStatus =:= MaxModelStatus ->
            %%任务即将提交 删除侦听器
            ListenerList = PInfo#p_mission_info.listener_list,
            i_remove_all_listener(ListenerList),
            PInfo;
        true ->
            PInfo
    end.

i_deal_listener_2(E, {MapID_A,NeedMonsterType_A,NeedPropTypeID_A,NeedPropNum_A,PropDropRate_A}) ->
    #mission_listener_data{type=Type,value=Value,need_num=NeedNum,int_list=IntList} = E,
    case Type of
        ?MISSION_LISTENER_TYPE_MONSTER->
            %%怪物侦听器
            [MapID] = IntList,
            mod_mission_data:join_to_listener(RoleID, MissionID, Type, Value),
            {MapID,Value,NeedPropTypeID_A,NeedPropNum_A,PropDropRate_A};
        ?MISSION_LISTENER_TYPE_PROP->
            %%道具侦听器
            [PropDropRate] = IntList,
            mod_mission_data:join_to_listener(RoleID, MissionID, Type, Value),
            {MapID_A,NeedMonsterType_A,Value,NeedNum,PropDropRate}
    end.


i_trigger(?MISSION_LISTENER_TYPE_MONSTER, PInfo, DeadMonsterType, ListenerList) ->
    i_trigger_monster(ListenerList, PInfo, DeadMonsterType);
i_trigger(?MISSION_LISTENER_TYPE_PROP, PInfo, PropTypeID, ListenerList) ->
    i_trigger_prop(ListenerList, PInfo, PropTypeID, 0, 0, [], null).

%%打一个怪物，掉一个道具
i_trigger_monster([], _PInfo, _DeadMonsterType) ->
    ignore;
i_trigger_monster([Listener|ListenerList], PInfo, DeadMonsterType) ->
    [_MapID,NeedMonsterType, PropDropRate] = Listener#p_mission_listener.int_list,
    NeedPropTypeID = Listener#p_mission_listener.value,
    CurrentModelStatus = PInfo#p_mission_info.current_model_status,
    if
        NeedMonsterType =:= DeadMonsterType
          andalso
        CurrentModelStatus =:= ?MISSION_MODEL_2_STATUS_DOING ->
            Drop = mod_mission_misc:random(PropDropRate),
            if
                Drop =:= true ->
                    %%这个接口内部应该实现背包位置是否足够
                    mod_mission_misc:give_prop(RoleID, NeedPropTypeID, 1);
                true ->
                    ignore
            end;
        true ->
            ignore
    end,
    i_trigger_monster(ListenerList, PInfo, DeadMonsterType).

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
        CurrentModelStatus =:= MaxModelStauts ->
            ignore;
        TotalNeed =:= Complete ->
            %%切换状态                      
            %%删除侦听器
            %%i_remove_all_listener(NewListenerList),
            
            mission_model_common:change_model_status(RoleID, MissionID, MissionBaseInfo,NewPInfo, +1),
           
            
            %%发送最后一次的任务侦听器数据
            DataRecord = #m_mission_listener_toc{mission_id=MissionID, listener=MatchListenerData},
            mod_mission_unicast:p_unicast(RoleID, ?DEFAULT_UNIQUE, 
                                          ?MISSION, ?MISSION_LISTENER, 
                                          DataRecord),
            mod_mission_unicast:c_unicast(RoleID);
        TotalNeed > Complete ->
            if
                CurrentModelStatus =:= MaxModelStauts ->%%玩家可能把道具扔了
                    mission_model_common:change_model_status(RoleID, MissionID, MissionBaseInfo,NewPInfo, -1);
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
        IntList = ListenerData#p_mission_listener.int_list,
        [_MapID, NeedMonsterType, _PropDropRate] = IntList,
        mod_mission_data:remove_from_listener(
          RoleID, MissionID, 
          ListenerType, NeedPropTypeID),
        
        mod_mission_data:remove_from_listener(
          RoleID, MissionID, 
          ?MISSION_LISTENER_TYPE_MONSTER, NeedMonsterType),
        
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