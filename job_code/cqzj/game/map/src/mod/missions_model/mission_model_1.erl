%% Author: chixiaosheng
%% Created: 2011-4-5
%% Description: 对话模型
%%      model_status: 允许多个
%%      listener：纯对话，没有侦听器
-module(mission_model_1, [RoleID, MissionID, MissionBaseInfo]).
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
    TransFun = fun() ->
                       %% 首次陈圆圆任务需要记录流失率
                       [FristMissIdList] = common_config_dyn:find(mission_etc,first_mission_id),
                       case lists:member(MissionID, FristMissIdList) of
                           true->
                               catch common_admin_hook:hook({accept_first_task,RoleID});
                           _ ->
                               ignore
                       end,
                       mission_model_common:common_do(RoleID, MissionID,MissionBaseInfo,RequestRecord, PInfo)
               end,
    ?DO_TRANS_FUN( TransFun ).



%%@doc 取消任务
cancel(PInfo, RequestRecord) ->
    TransFun = fun() ->
                       mission_model_common:common_cancel(RoleID, MissionID, MissionBaseInfo,RequestRecord, PInfo)
               end,
    ?DO_TRANS_FUN( TransFun ).

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