%% Author: chixiaosheng
%% Created: 2011-4-5
%% Description: 打怪模型
%%      model_status: 必须是3个Status
%%      listener：必须是怪物的侦听器
-module(mission_model_2, [RoleID, MissionID, MissionBaseInfo]).
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

%%打怪模型的第二个状态
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
                
                %%@doc 删除所有侦听器
                i_remove_all_listener(PInfo#p_mission_info.listener_list),
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
                       CurrentModelStatus = PInfo#p_mission_info.current_model_status,
                       MissionMaxModelStatus = MissionBaseInfo#mission_base_info.max_model_status,
                       DeadMonsterType = ListenerData#mission_listener_trigger_data.value,
                       
                       if
                           CurrentModelStatus =:= MissionMaxModelStatus ->
                               ignore;%%任务已经处于已提交状态 直接无视
                           true ->
                               i_trigger(ListenerList, PInfo, DeadMonsterType, 0, 0, [], null)
                       end
               end,
    ?DO_TRANS_FUN( TransFun ).


%%%===================================================================
%%% Internal functions
%%%===================================================================


%%@doc 如果是刚接任务 加侦听器
i_deal_listener(PInfo) ->
    CurrentModelStatus = PInfo#p_mission_info.current_model_status,
    MaxModelStatus = MissionBaseInfo#mission_base_info.max_model_status,
    
    if
        CurrentModelStatus =:= ?MISSION_MODEL_STATUS_FIRST ->
            ListenerListConfig = MissionBaseInfo#mission_base_info.listener_list,
            ListenerList = 
                lists:map(fun(ListenerDataConfig) ->
                                  ListenerType = ListenerDataConfig#mission_listener_data.type,
                                  NeedMonsterType = ListenerDataConfig#mission_listener_data.value,
                                  NeedNum = ListenerDataConfig#mission_listener_data.need_num,
                                  [MapID] = ListenerDataConfig#mission_listener_data.int_list,
                                  
                                  mod_mission_data:join_to_listener(RoleID, MissionID, ListenerType, NeedMonsterType),
                                  #p_mission_listener{type=ListenerType,
                                                      value=NeedMonsterType,
                                                      int_list=[MapID],
                                                      need_num=NeedNum,
                                                      current_num=0}
                          end, ListenerListConfig),
            PInfo#p_mission_info{listener_list=ListenerList};
        CurrentModelStatus =:= MaxModelStatus ->
            %%任务即将提交 删除侦听器
            ListenerList = PInfo#p_mission_info.listener_list,
            i_remove_all_listener(ListenerList),
            PInfo;
        true ->
            PInfo
    end.

%%@doc 计算所有侦听器是否满足要求了
%%@param 待计算的侦听器
%%@param p_mission_info
%%@param TriggerListenerValue 当前触发的怪物ID
%%@param TotalNeed 需要多少
%%@param Complete 已经完成多少
%%@param NewListenerList 重新计算后合并的侦听器列表
%%@param MatchListenerData 此次被触发的侦听器 
i_trigger([], PInfo, _DeadMonsterType, TotalNeed, 
          Complete, NewListenerList, 
          MatchListenerData) ->
    
    NewPInfo = PInfo#p_mission_info{listener_list=NewListenerList},
    if
        MatchListenerData =:= null ->
            %%居然没找到这个侦听器
            ignore;
        TotalNeed =:= Complete ->
            %%切换状态
            
            %%删除所有侦听器
            i_remove_all_listener(PInfo#p_mission_info.listener_list),
            
            mission_model_common:change_model_status(RoleID, MissionID, MissionBaseInfo,NewPInfo, +1),
            
            
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

i_trigger([ListenerData|ListenerList], PInfo, DeadMonsterType, 
          TotalNeed, Complete, NewListenerList, 
          MatchListenerData) ->
    
    NeedMonsterType = ListenerData#p_mission_listener.value,
    CurrentNum = ListenerData#p_mission_listener.current_num,
    NeedNum = ListenerData#p_mission_listener.need_num,
    
    if
        DeadMonsterType =:= NeedMonsterType ->
            NewCurrentNum = CurrentNum+1;
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
        DeadMonsterType =:= NeedMonsterType ->
            NewMatchListenerData = NewListenerData;
        true ->
            NewMatchListenerData = MatchListenerData
    end,
    
    i_trigger(ListenerList, PInfo, DeadMonsterType, 
              TotalNeed+1, NewComplete, 
              [NewListenerData|NewListenerList], 
              NewMatchListenerData).

%%@ 删除所有侦听器 
i_remove_all_listener(ListenerList) ->
    lists:foreach(fun(ListenerData) ->
        ListenerType = ListenerData#p_mission_listener.type,
        ListenerValue = ListenerData#p_mission_listener.value,
        mod_mission_data:remove_from_listener(RoleID, MissionID,  ListenerType, ListenerValue)
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