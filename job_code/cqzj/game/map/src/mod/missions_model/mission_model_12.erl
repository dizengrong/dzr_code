%%% @author bisonwu <wuzesen@gmail.com>
%% Created: 2011-6-22
%% Description: 玩家升级任务模型 - 3次对话 - 中间状态去升级
%%      model_status: 必须是3个Status
%%      listener：必须是升级的侦听器
-module(mission_model_12, [RoleID, MissionID, MissionBaseInfo]).
-behaviour(b_mission_model).

%%
%% Include files
%%
-include("mission.hrl").  
-define(MISSION_MODEL_12_LEVEL_STATUS, 1).

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
                  DoResult = mission_model_common:common_do(RoleID, MissionID,MissionBaseInfo,RequestRecord, NewPInfo),
                  case PInfo#p_mission_info.current_model_status of
                      ?MISSION_MODEL_STATUS_FIRST->
                          %%如果第一次接任务的时候就已经达到等级条件，就算完成任务了
                          {ok,#p_role_attr{level=CurrLevel}} = mod_map_role:get_role_attr(RoleID),
                          ListenerList = NewPInfo#p_mission_info.listener_list,
                          case ListenerList of
                              [#p_mission_listener{value=NeedLevel}] when (CurrLevel>=NeedLevel)->
                                  Func1 = {func,fun()->  
                                                    hook_level_change:hook_mission(RoleID,CurrLevel)
                                           end},
                                  mod_mission_misc:push_trans_func(RoleID,Func1);
                              _ ->
                                  DoResult
                          end;
                      _ ->
                          DoResult
                  end
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
                       NeedLevel = ListenerData#mission_listener_trigger_data.value,
                       i_trigger_prop(ListenerList, PInfo, NeedLevel)
               end,
    ?DO_TRANS_FUN( TransFun ).


%%@doc 如果是刚接任务 加侦听器
i_deal_listener(PInfo, _RequestRecord) ->
    CurrentModelStatus = PInfo#p_mission_info.current_model_status,
    MaxModelStatus = MissionBaseInfo#mission_base_info.max_model_status,
    
    if
        CurrentModelStatus =:= ?MISSION_MODEL_STATUS_FIRST ->
            ListenerListConfig = MissionBaseInfo#mission_base_info.listener_list,
            ListenerList = 
                lists:map(fun(ListenerDataConfig) ->
                    ListenerType = ListenerDataConfig#mission_listener_data.type,
                    NeedLevel = ListenerDataConfig#mission_listener_data.value,
                    NeedNum = ListenerDataConfig#mission_listener_data.need_num,
                    %%增加侦听器
                    mod_mission_data:join_to_listener(RoleID, MissionID, ListenerType, NeedLevel),
                    %%直接将玩家侦听器数据设置为已经满足要求
                    #p_mission_listener{type=ListenerType,
                                        value=NeedLevel,
                                        int_list=[],
                                        need_num=NeedNum,
                                        current_num=0}
                end, ListenerListConfig),
                %%怪物ID/怪物当前数量/所需数量
            PInfo#p_mission_info{listener_list=ListenerList};
        CurrentModelStatus =:= ?MISSION_MODEL_12_LEVEL_STATUS ->
            ListenerListConfig = MissionBaseInfo#mission_base_info.listener_list,
            PropTypeIDList = 
                lists:map(fun(ListenerDataConfig) ->
                    ListenerDataConfig#mission_listener_data.value
                end, ListenerListConfig),
            throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_NOT_LEVEL_UP, PropTypeIDList});
        CurrentModelStatus =:= MaxModelStatus ->
            %%任务即将提交 删除侦听器
            ListenerList = PInfo#p_mission_info.listener_list,
            i_remove_all_listener(ListenerList),
            PInfo;
        true ->
            PInfo
    end.

change_status_for_trigger(Listener,PInfo,AddStep) when is_integer(AddStep)->
    ListenerList2=[Listener#p_mission_listener{current_num=1}],
    NewPInfo = PInfo#p_mission_info{listener_list=ListenerList2},
    mission_model_common:change_model_status(RoleID, MissionID, MissionBaseInfo, NewPInfo, AddStep).

i_trigger_prop([], _PInfo, _NeedLevel) ->
    ignore;
i_trigger_prop([Listener], PInfo, NeedLevel) ->
    MaxModelStauts = MissionBaseInfo#mission_base_info.max_model_status,
    CurrentModelStatus = PInfo#p_mission_info.current_model_status,
    case mod_map_role:get_role_attr(RoleID) of
        {ok,#p_role_attr{level=CurrLevel}}->
            if
                MaxModelStauts =:= CurrentModelStatus->
                    ignore;
                CurrLevel >= NeedLevel->
                    %%切换状态                      
                    %%删除侦听器
                    change_status_for_trigger(Listener,PInfo,+1);
                true->
                    ignore
            end;
        _ ->
            ignore
    end.

%%@doc 删除所有侦听器
i_remove_all_listener(ListenerList) ->
    lists:foreach(fun(ListenerData) ->
        ListenerType = ListenerData#p_mission_listener.type,
        NeedLevel = ListenerData#p_mission_listener.value,
        
        mod_mission_data:remove_from_listener(
          RoleID, MissionID, 
          ListenerType, NeedLevel)
        
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