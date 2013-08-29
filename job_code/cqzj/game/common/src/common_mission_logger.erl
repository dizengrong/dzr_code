%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     记录游戏中的任务日志
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(common_mission_logger).


%% API
-export([log_accept/1,log_finish/1,log_commit/1,log_cancel/1]).


%%任务类型：
-define(MISSION_TYPE_MAIN, 1).
-define(MISSION_TYPE_BRANCH, 2).
-define(MISSION_TYPE_LOOP, 3).

%%任务状态:
-define(LOG_TYPE_MISSION_ACCEPT, 1). %%已接受
-define(LOG_TYPE_MISSION_FINISH, 2). %%已完成
-define(LOG_TYPE_MISSION_COMMIT, 3). %%已提交，即领奖
-define(LOG_TYPE_MISSION_CANCEL, 4). %%已取消


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").
-include("common_server.hrl").

%% ====================================================================
%% API Functions
%% ====================================================================
log_accept({_RoleID,_RoleLevel,_MissionID,?MISSION_TYPE_LOOP,_MaxDoTimes})->
    ignore;
log_accept(MissionLogData)->
    log(?LOG_TYPE_MISSION_ACCEPT,MissionLogData).

log_finish({_RoleID,_RoleLevel,_MissionID,?MISSION_TYPE_LOOP,_MaxDoTimes})->
    ignore;
log_finish(MissionLogData)->
    log(?LOG_TYPE_MISSION_FINISH,MissionLogData).

log_commit({_RoleID,_RoleLevel,_MissionID,?MISSION_TYPE_LOOP,_MaxDoTimes})->
    ignore;
log_commit(MissionLogData)->
    log(?LOG_TYPE_MISSION_COMMIT,MissionLogData).

log_cancel({_RoleID,_RoleLevel,_MissionID,?MISSION_TYPE_LOOP,_MaxDoTimes})->
    ignore;
log_cancel(MissionLogData)->
    log(?LOG_TYPE_MISSION_CANCEL,MissionLogData).


%% ====================================================================
%% Internal Functions
%% ====================================================================
log(Status,MissionLogData)->
    global:send(mgeew_mission_log_server,{Status,MissionLogData}).




