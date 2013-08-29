%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     记录阅历的消费日志
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mgeew_yueli_log_server).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").

%% API
-export([start/0,
         start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).
-record(state, {}).


%% 默认5分钟将数据转存到MySQL中
-define(DUMP_INTERVAL, 5*1000). %%2分钟记录一次2*60*1000
-define(MSG_DUMP_LOG, dump_yueli_log).

-define(YUELI_LOG_QUEUE,yueli_log_queue).

%%%===================================================================
start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE, {?MODULE, start_link, []},
                                                 permanent, 30000, worker, [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).


%% ====================================================================
%% Server functions
%% 		gen_server callbacks
%% ====================================================================
%%--------------------------------------------------------------------
init([]) ->
    erlang:process_flag(trap_exit, true),
    
	erlang:send_after(?DUMP_INTERVAL,self(),?MSG_DUMP_LOG),
    
    put(?YUELI_LOG_QUEUE,[]),
    
    {ok, #state{}}.

    
    
%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.
%%--------------------------------------------------------------------
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ?ERROR_MSG("等待将阅历日志的临时数据 写入到db中",[]),
    do_dump_yueli_logs(),
    ok.
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================


%% ====================================================================
%% Local Functions
%% ====================================================================

do_handle_info(?MSG_DUMP_LOG)->
    do_dump_yueli_logs(),
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG);

do_handle_info({yueli_logs, RecList}) when is_list(RecList) ->
	case get(?YUELI_LOG_QUEUE) of
        undefined->
            put(?YUELI_LOG_QUEUE,RecList);
        [] ->
            put(?YUELI_LOG_QUEUE,RecList);
        OldList ->
            put(?YUELI_LOG_QUEUE,lists:concat([RecList,OldList]))
    end;

do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.
            

%%@doc 持久化日志
do_dump_yueli_logs()->
    try
        case get(?YUELI_LOG_QUEUE) of
            undefined-> ignore;
            [] -> ignore;
            Queues ->
                save_to_mysql(?YUELI_LOG_QUEUE,Queues)
        end
    catch
        _:Reason->
            ?ERROR_MSG("do_save_consume_log error,Reason=~w,Stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.
 

save_to_mysql(?YUELI_LOG_QUEUE=QueueType,Queues)->
    try
        RecValues = [begin [r_yueli_log|T]=tuple_to_list(Rec),T end||Rec<-Queues],
        %%批量插入
        FieldNames = [ user_id, user_name, use_yueli, rem_yueli, mtime, mtype, mdetail],
        QueuesInsert = lists:reverse(RecValues), %%r_yueli_log
        mod_mysql:batch_insert(t_log_use_yueli,FieldNames,QueuesInsert,3000),
        %%插入成功后update
         put(QueueType,[])
    catch
        _:_Reason->ok
            % ?ERROR_MSG("持久化阅历数据出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.