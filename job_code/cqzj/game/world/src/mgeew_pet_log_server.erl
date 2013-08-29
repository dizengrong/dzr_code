%%%-------------------------------------------------------------------
%%% @author LinRuirong <linruirong@gmail.com>
%%% @copyright (C) 2011, gmail.com
%%% @doc
%%%     记录异兽相关的日志
%%% @end
%%% Created : 2011-03-04
%%%-------------------------------------------------------------------
-module(mgeew_pet_log_server).
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
-define(LOG_QUEUE_GET_PET, log_queue_get_pet).
-define(LOG_QUEUE_PET_ACTION, log_queue_pet_action).
-define(LOG_QUEUE_PET_TRAINING, log_queue_pet_training).
-define(MSG_DUMP_GET_PET_LOG, dump_get_pet_log).
-define(MSG_DUMP_PET_ACTION_LOG, dump_pet_action_log).
-define(MSG_DUMP_PET_TRAINING_LOG, dump_pet_training_log).



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
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_GET_PET_LOG),
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_PET_ACTION_LOG),
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_PET_TRAINING_LOG),
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

%%获得异兽的日志
do_handle_info({log_get_pet,{PetId, PetName, PetType, PetLevel, GetWay, RoleId, RoleLevel, Faction, PetTypeStr, GetWayStr}})->
    %?ERROR_MSG("~w",[{log_get_pet,{PetId, PetName, PetType, PetLevel, GetWay, RoleId, RoleLevel, Faction, PetTypeStr, GetWayStr}}]),
    MTime = common_tool:now(), 
    do_write_queue_get_pet( [PetId, PetName, PetType, PetLevel, GetWay, RoleId, RoleLevel, Faction, MTime, PetTypeStr, GetWayStr] );
  
%%对异兽的操作日志
do_handle_info({log_pet_action,{PetId, PetName, PetType, RoleId, Action, ActionDetail, PetTypeStr, ActionStr, ActionDetailStr}})->
    %?ERROR_MSG("~w",[{log_pet_action,{PetId, PetName, PetType, RoleId, Action, ActionDetail, PetTypeStr, ActionStr, ActionDetailStr}}]),
    MTime = common_tool:now(),
    do_write_queue_pet_action( [PetId, PetName, PetType, RoleId, Action, ActionDetail, MTime, PetTypeStr, ActionStr, ActionDetailStr] );

%%异兽训练日志
%%OpType 有:
%% 1=>完成训练
%% 2=>立即完成训练
%% 3=>放弃训练
%% 4=>提升星级
%% 5=>立即提升星级
do_handle_info({log_pet_training,{RoleID,RoleName,TrainingHours,PetID,PetLevel,TrainingCost}})->
    %?ERROR_MSG("~w",[{log_pet_training,{PetId, PetName, RoleId, OpType, BindGold, UnBindGold, Star}}]),
    MTime = common_tool:now(),
    do_write_queue_pet_training( [PetID, RoleName, RoleID, PetLevel, TrainingHours,TrainingCost, MTime] );
 
do_handle_info(?MSG_DUMP_GET_PET_LOG)->
    case get(?LOG_QUEUE_GET_PET) of
        undefined-> ignore;
        [] -> ignore;
        Queues ->
            do_dump_get_pet_logs( lists:reverse(Queues) )
    end,
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_GET_PET_LOG);

do_handle_info(?MSG_DUMP_PET_ACTION_LOG)->
    case get(?LOG_QUEUE_PET_ACTION) of
        undefined-> ignore;
        [] -> ignore;
        Queues ->
            do_dump_pet_action_logs( lists:reverse(Queues) )
    end,
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_PET_ACTION_LOG);

do_handle_info(?MSG_DUMP_PET_TRAINING_LOG)->
    case get(?LOG_QUEUE_PET_TRAINING) of
        undefined-> ignore;
        [] -> ignore;
        Queues ->
            do_dump_pet_training_logs( lists:reverse(Queues) )
    end,
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_PET_TRAINING_LOG);


do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.


do_write_queue_get_pet(Q) ->
    case get(?LOG_QUEUE_GET_PET) of
        undefined->
            put( ?LOG_QUEUE_GET_PET,[ Q ] );
        Queues->
            put( ?LOG_QUEUE_GET_PET,[ Q|Queues ] )
    end.

do_write_queue_pet_action(Q) ->
    case get(?LOG_QUEUE_PET_ACTION) of
        undefined->
            put( ?LOG_QUEUE_PET_ACTION,[ Q ] );
        Queues->
            put( ?LOG_QUEUE_PET_ACTION,[ Q|Queues ] )
    end.

do_write_queue_pet_training(Q) ->
    case get(?LOG_QUEUE_PET_TRAINING) of
        undefined->
            put( ?LOG_QUEUE_PET_TRAINING,[ Q ] );
        Queues->
            put( ?LOG_QUEUE_PET_TRAINING,[ Q|Queues ] )
    end.
do_dump_get_pet_logs(Queues)->
    try
        %%批量插入的数据，目前最大不能超过3M
        FieldNames = [pet_id, pet_name, pet_type, pet_level, get_way, role_id, role_level, faction, mtime, pet_type_str, get_way_str],
        
        QueuesInsert = lists:reverse(Queues),
        mod_mysql:batch_insert(t_log_get_pet,FieldNames,QueuesInsert,3000),
        %%插入成功之后，再修改进程字典
        put(?LOG_QUEUE_GET_PET,[])
    catch
        _:Reason->
            ?ERROR_MSG("do_dump_get_pet_logs error,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.

do_dump_pet_action_logs(Queues)->
    try
        %%批量插入的数据，目前最大不能超过3M
        FieldNames = [pet_id, pet_name, pet_type, role_id, action, action_detail, mtime, pet_type_str, action_str, action_detail_str],
        
        QueuesInsert = lists:reverse(Queues),
        mod_mysql:batch_insert(t_log_pet_action,FieldNames,QueuesInsert,3000),
        %%插入成功之后，再修改进程字典
        put(?LOG_QUEUE_PET_ACTION,[])
    catch
        _:Reason->
            ?ERROR_MSG("do_dump_pet_action_logs error,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.

do_dump_pet_training_logs(Queues)->
    try
        %%批量插入的数据，目前最大不能超过3M
        FieldNames = [pet_id, role_name, role_id, pet_level, training_hours, training_cost, mtime],
        
        QueuesInsert = lists:reverse(Queues),
        mod_mysql:batch_insert(t_log_pet_training,FieldNames,QueuesInsert,3000),
        %%插入成功之后，再修改进程字典
        put(?LOG_QUEUE_PET_TRAINING,[])
    catch
        _:Reason->
            ?ERROR_MSG("do_dump_pet_training_logs error,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.
    
 


