%%%-------------------------------------------------------------------
%%% @author  bisonwu
%%% @copyright (C) 2010, 
%%% @doc
%%%     循环任务的日志记录
%%% @end
%%% Created : 23 Nov 2010 by  <>
%%%-------------------------------------------------------------------
-module(common_loop_mission_logger).

-export([
         log_shoubian/1,
         log_citan/1,
         log_guotan/1
        ]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").
-include("common_server.hrl").
 
%%刺探类型：
-define(LOG_TYPE_CITAN, 1).
-define(LOG_TYPE_GUOTAN, 2).

%%任务的结束状态
-define(STATUS_FINISH, 1). %%完成
-define(STATUS_TIMEOUT, 2). %%超时
-define(STATUS_CANCEL, 3). %%取消




%% ====================================================================
%% API functions
%% ====================================================================
log_shoubian(Log) when is_tuple(Log)->
    R2 = get_shoubian_record(Log),
    global:send(mgeew_loop_mission_log_server,{log_shoubian,R2}).

%%注，刺探是没有超时状态的 
log_citan(Log) when is_tuple(Log)->
    R2 = get_citan_record(Log,?LOG_TYPE_CITAN),
    global:send(mgeew_loop_mission_log_server,{log_citan,R2}).

log_guotan(Log) when is_tuple(Log)->
    R2 = get_citan_record(Log,?LOG_TYPE_GUOTAN),
    global:send(mgeew_loop_mission_log_server,{log_citan,R2}).


%%%===================================================================
%%% Internal functions
%%%===================================================================

get_shoubian_record(Log)->
    {RoleID,Status,Succ,Fail} = Log,
    {ok,#p_role_base{faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
    Date = erlang:date(),
    #r_shoubian_log{role_id=RoleID, faction_id=FactionID, mdate=Date, status=Status, 
                    success=Succ, fail=Fail, total=(Succ+Fail)}.

get_citan_record({RoleID,Status,Succ,Fail},Type)->
    {ok,#p_role_base{faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
    Date = erlang:date(),
    #r_citan_log{type=Type, role_id=RoleID, faction_id=FactionID, mdate=Date, status=Status, 
                 success=Succ, fail=Fail, total=(Succ+Fail)}.




 
