%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     记录游戏的普通任务日志(主线、支线)
%%% @end
%%% Created : 2011-4-22
%%%-------------------------------------------------------------------
-module(mgeew_mission_log_server).
-behaviour(gen_server).


-export([start/0,
         start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").


%%定时发消息进行持久化
-define(DUMP_INTERVAL, 30 * 1000).
-define(MAX_DUMP_RECORD_COUNT, 3000).
-define(LOG_QUEUE_SINGLE, log_queue_single).
-define(LOG_QUEUE_BATCH, log_queue_batch).

-define(MSG_DUMP_LOG, dump_mission_log).

%%任务状态:
-define(LOG_TYPE_MISSION_ACCEPT, 1). %%已接受



%% ====================================================================
%% API functions
%% ====================================================================



%% ====================================================================
%% External functions
%% ====================================================================

start() ->
    {ok,_} = supervisor:start_child(mgeew_sup, 
                           {?MODULE, 
                            {?MODULE, start_link,[]},
                            permanent, brutal_kill, worker, [?MODULE]}).
    

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [],[]).

init([]) ->
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG),
    {ok, []}.
 
 
%% ====================================================================
%% Server functions
%%      gen_server callbacks
%% ====================================================================
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------


do_handle_info({Status,MissionLogData})->
	do_write_queue(Status,MissionLogData),
	ok;

do_handle_info(?MSG_DUMP_LOG)->
    
    do_dump_batch_log(),
    do_dump_single_log(),
    
    
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG);


do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.


do_write_queue(Status,{RoleID,RoleLevel,MissionID,MissionType,MaxDoTimes}) ->
    case MaxDoTimes>1 of
        true->
            %%很少有单条插入的任务
            Sql = do_format_sql(RoleID,RoleLevel,MissionID,Status,MissionType),
            common_misc:update_dict_queue(?LOG_QUEUE_SINGLE, Sql);
        _ ->
            Now = common_tool:now(),
            FieldsValue = [RoleID,RoleLevel,MissionID,MissionType,Status,1,Now ],
            common_misc:update_dict_queue(?LOG_QUEUE_BATCH, FieldsValue)
    end. 

%%单条插入任务日志
do_dump_single_log()->
    case get(?LOG_QUEUE_SINGLE) of
        undefined-> ignore;
        []-> ignore;
        Queues->
            try
              QueuesInsert = lists:reverse(Queues),
              [ do_single_insert(SQL) || SQL <- QueuesInsert ],
              put(?LOG_QUEUE_SINGLE,[])
            catch
                _:_Reason->
                  ignore
            end
    end.

do_single_insert(SQL)->
    case mod_mysql:insert(SQL) of
        {error,Error}->
            ?ERROR_MSG("持久化任务日志出错,Reason=~w,SQL=~s    stacktrace=~w",[Error,SQL,erlang:get_stacktrace()]),
            erlang:throw({error,Error});
        _ -> ok
    end.
    
%%批量插入任务日志
do_dump_batch_log()->
    case get(?LOG_QUEUE_BATCH) of
        undefined-> ignore;
        []-> ignore;
        Queues->
            QueuesInsert = lists:reverse(Queues),
            do_batch_insert(QueuesInsert)
    end.
do_batch_insert(QueuesInsert)->
    Tab = t_log_mission,
    try
        FieldNames = [role_id,level,mission_id,mission_type,status,total,mtime],
        mod_mysql:batch_replace(Tab, FieldNames, QueuesInsert, ?MAX_DUMP_RECORD_COUNT),
        put(?LOG_QUEUE_BATCH,[])
    catch
        _:Reason->
            ?ERROR_MSG("insert to table:~w error,reason:~w  stack:~w",[Tab,Reason,erlang:get_stacktrace()])
    end.

%%格式化sql
do_format_sql(RoleID,RoleLevel,MissionID,Status,MissionType)->
    Now = common_tool:now(),
    if
        Status =:= ?LOG_TYPE_MISSION_ACCEPT ->
            io_lib:format(" INSERT INTO t_log_mission(`role_id`,`level`,`mission_id`,`mission_type`,`status`,`total`,`mtime`)VALUES(~w,~w,~w,~w,~w,1,~w) ON DUPLICATE KEY UPDATE `status`=~w,`total`=`total`+1,`mtime`=~w ;",[RoleID,RoleLevel,MissionID,MissionType,Status,Now,Status,Now]);
        true ->
            io_lib:format(" UPDATE t_log_mission SET `status`=~w, `mtime`=~w, `level`=~w WHERE `role_id`=~w AND `mission_id`=~w; ",[Status,Now,RoleLevel,RoleID,MissionID])
    end.
	
    
    
    
 


