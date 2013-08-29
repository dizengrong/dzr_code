%%%-------------------------------------------------------------------
%%% @author LinRuirong <linruirong@gmail.com>
%%% @copyright (C) 2011, gmail.com
%%% @doc
%%%     记录玩家参加大明宝藏的日志
%%% @end
%%% Created : 2011-2-12
%%%-------------------------------------------------------------------
-module(mgeew_country_treasure_log_server).
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
-define(DUMP_INTERVAL, 15 * 1000).
-define(LOG_QUEUE, log_queue).
-define(MSG_DUMP_LOG, dump_country_treasure_log).



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

%%新挂单记录
do_handle_info({RoleID,RoleLevel})->
    MTime = common_tool:now(),
    do_write_queue( [MTime,RoleID,RoleLevel] );

do_handle_info(?MSG_DUMP_LOG)->
    case get(?LOG_QUEUE) of
        undefined-> ignore;
        [] -> ignore;
        Queues ->
            do_dump_country_treasure_logs( lists:reverse(Queues) )
    end,
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG);


do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.


do_write_queue(Q) ->
    case get(?LOG_QUEUE) of
        undefined->
            put( ?LOG_QUEUE,[ Q ] );
        Queues->
            put( ?LOG_QUEUE,[ Q|Queues ] )
    end.

do_dump_country_treasure_logs(Queues)->
    try
        %%批量插入的数据，目前最大不能超过3M
        FieldNames = [mtime,role_id,level],
        BatchFieldValues = lists:filter(fun(E)->
                                                case E of
                                                    [A1,A2,A3] when is_integer(A1),is_integer(A2),is_integer(A3)->
                                                        true;
                                                    _ ->
                                                        false
                                                end
                                        end, Queues) ,
        
        QueuesInsert = lists:reverse(BatchFieldValues),
        mod_mysql:batch_insert(t_log_country_treasure,FieldNames,QueuesInsert,3000),
        %%插入成功之后，再修改进程字典
        put(?LOG_QUEUE,[])
    catch
        _:Reason->
            ?ERROR_MSG("do_dump_country_treasure_logs error,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.
    
    

    
 


