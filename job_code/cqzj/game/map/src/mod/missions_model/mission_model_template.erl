%% Author: chixiaosheng
%% Created: 2011-4-5
%% Description: 模型模版
-module(mission_model_template, [RoleID, MissionID, MissionBaseInfo]).
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
auth_accept(_PInfo) -> ignore.

%%@doc 验证是否可以出现在任务列表
auth_show(_PInfo) -> ignore.

%%@doc 执行任务 接-做-交
do(_PInfo, _RequestRecord) -> ignore.

%%@doc 取消任务
cancel(_PInfo, _RequestRecord) -> ignore.

%%@doc 侦听器触发
listener_trigger(_ListenerData, _PInfo,_TriggerParam) -> ignore.

%%@doc 初始化任务pinfo
init_pinfo(_OldPinfo) -> ignore.