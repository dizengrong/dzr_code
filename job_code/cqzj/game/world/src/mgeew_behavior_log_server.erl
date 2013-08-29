%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     记录玩家的流失率行为，目前包括
%%          'ENTER_SPLASH_WINDOW'=>1,
%%          'ACCEPT_FIRST_MISSION'=>2,
%%
%%% @end
%%% Created : 2010-11-18
%%%-------------------------------------------------------------------
-module(mgeew_behavior_log_server).
-behaviour(gen_server).


-export([start/0,
         start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).



%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").

-define(LOG_TYPE_ENTER_SPLASH_WINDOW, 1).
-define(LOG_TYPE_ACCEPT_FIRST_TASK, 2).

%%定时发消息进行持久化
-define(DUMP_INTERVAL, 30 * 1000).
-define(DUMP_MAX_RECORD_COUNT, 500).
-define(LOG_QUEUE, log_queue).
-define(MSG_DUMP_LOG, dump_behavior_log).
-define(ROLE_LIST_ENTER_FLASH_GAME, role_list_enter_flash_game).
-define(ROLE_LIST_ACCEPT_FIRST_TASK,role_list_accept_first_task).


%% ====================================================================
%% External functions
%% ====================================================================

start() ->
    {ok,_} = supervisor:start_child(mgeew_sup, 
                           {?MODULE, 
                            {?MODULE, start_link,[]},
                            permanent, 30000, worker, [?MODULE]}).
    

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [],[]).

init([]) ->
    erlang:process_flag(trap_exit, true),
    do_load_history_data(),
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
    case get(?LOG_QUEUE) of
        undefined -> ignore;
        []-> ignore;
        Queues ->check_do_dump_logs(Queues)
    end,
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

do_handle_info({log,Record})->
    do_log_record(Record);

do_handle_info(?MSG_DUMP_LOG)->
    case get(?LOG_QUEUE) of
        undefined-> ignore;
        [] -> ignore;
        Queues ->
            do_dump_behavior_logs(Queues)
    end,
    
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG);


%%@doc 陈圆圆任务统计
do_handle_info({accept_first_task,RoleID,LoginIP})->
    case get(?ROLE_LIST_ACCEPT_FIRST_TASK) of 
        Lists when is_list(Lists) ->
            case lists:member(RoleID,Lists) of
                true->
                    ignore;
                false->
                    Rec = new_behavior_log_record(RoleID,?LOG_TYPE_ACCEPT_FIRST_TASK,LoginIP),
                    put(?ROLE_LIST_ACCEPT_FIRST_TASK,[RoleID|Lists]),
                    do_log_record(Rec)
            end;
        _->
            ?ERROR_MSG("ROLE_LIST_ACCEPT_FIRST_TASK",[]),
            ignore
    end;

%%@doc 角色进入flash游戏的统计
do_handle_info({enter_flash_game,RoleID,LoginIP})->
    case get(?ROLE_LIST_ENTER_FLASH_GAME) of
        Lists when is_list(Lists) ->
            case lists:member(RoleID,Lists) of
                true->
                    ignore;
                false->
                    Rec = new_behavior_log_record(RoleID,?LOG_TYPE_ENTER_SPLASH_WINDOW,LoginIP),
                    put(?ROLE_LIST_ENTER_FLASH_GAME,[RoleID|Lists]),
                    do_log_record(Rec)
            end;
        _->
            ?ERROR_MSG("ROLE_LIST_ENTER_FLASH_GAME is error",[]),
            ignore
    end;


do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.

do_log_record(Record)->
    [r_fluctuation_behavior_log|RecValues] = tuple_to_list(Record),
    NewQueues =  case get(?LOG_QUEUE) of
        undefined->
            put( ?LOG_QUEUE,[ RecValues ] ),
            [RecValues];         
        Queues->
            put( ?LOG_QUEUE,[ RecValues|Queues ] ),
           [ RecValues|Queues ]
    end,
    check_do_dump_logs(NewQueues).

%%@doc 检查是否有必要dump log数据
check_do_dump_logs(Queues)->
    case length(Queues)> ?DUMP_MAX_RECORD_COUNT of
        false->
            ignore;
        true->
            do_dump_behavior_logs(Queues)
    end.

do_dump_behavior_logs(Queues)->
    try
        Tab = t_log_behavior,
        FieldNames = [ role_id,log_time,behavior_type,login_ip ],

        QueuesInsert = lists:reverse(Queues),
        mod_mysql:batch_insert(Tab,FieldNames,QueuesInsert,3000),
        
        %%插入成功之后，再修改进程字典
        put(?LOG_QUEUE,[])
    catch
        _:Reason->
            ?ERROR_MSG("持久化用户流失率行为日志出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.


new_behavior_log_record(RoleID,Type,ClientIP)->
    StrIP = common_tool:ip_to_str(ClientIP),
    Now = common_tool:now(),
    #r_fluctuation_behavior_log{role_id=RoleID,log_time=Now,behavior_type=Type,login_ip=StrIP}.


do_load_history_data()->
    {ok,List} = mod_mysql:select( mod_mysql:get_esql_select(t_log_behavior,[role_id,behavior_type],[]) ), 
    {AccEnterGame,AccAcceptFirst} = 
      lists:foldl(
        fun(E,{Acc1,Acc2})->
                case E of
                    [RoleID,1]->
                        {[RoleID|Acc1],Acc2};
                    [RoleID,2]->
                        {Acc1,[RoleID|Acc2]}
                end   
        end, {[],[]}, List),
    
    put(?ROLE_LIST_ENTER_FLASH_GAME, AccEnterGame ),
    put(?ROLE_LIST_ACCEPT_FIRST_TASK, AccAcceptFirst).
    

    
    
    
 


