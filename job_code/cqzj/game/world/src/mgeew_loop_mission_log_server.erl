%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     记录循环任务日志
%%% @end
%%% Created : 2011-4-22
%%%-------------------------------------------------------------------
-module(mgeew_loop_mission_log_server).
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
-define(MAX_DUMP_RECORD_COUNT, 1000).
-define(LOG_QUEUE, log_queue).
-define(MSG_DUMP_LOG, dump_mission_log).

-define(LOG_QUEUE_SHOUBIAN,log_queue_shoubian).
-define(LOG_QUEUE_CITAN,log_queue_citan).



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

-define(DO_DUMP_LOG(Key,Fun),
        case get(Key) of
            undefined -> ignore;
            [] -> ignore;
            _ -> Fun( Key,get(Key) )
        end).

-define(TRANSFROM_DATE_ID(RoleID),
        Date = common_misc:format_lang("~w-~w-~w",[Y,M,D]),
        ID = common_misc:format_lang("~w_~w~w~w",[RoleID,Y,M,D])
        ).

do_handle_info({log_shoubian,RecLog})->
    #r_shoubian_log{role_id=RoleID, mdate={Y,M,D} } = RecLog,
    ?TRANSFROM_DATE_ID(RoleID),
    
    R2 = RecLog#r_shoubian_log{id=ID,mdate=Date},
    [_ | T] = erlang:tuple_to_list(R2),
    common_misc:update_dict_queue(?LOG_QUEUE_SHOUBIAN, T),
    ok;

do_handle_info({log_citan,RecLog})->
    #r_citan_log{role_id=RoleID, mdate={Y,M,D} } = RecLog,
    ?TRANSFROM_DATE_ID(RoleID),
    
    R2 = RecLog#r_citan_log{id=ID,mdate=Date},
    [_ | T] = erlang:tuple_to_list(R2),
    common_misc:update_dict_queue(?LOG_QUEUE_CITAN, T),
    ok;

do_handle_info(?MSG_DUMP_LOG)->
    ?DO_DUMP_LOG( ?LOG_QUEUE_SHOUBIAN,do_dump_shoubian ),
    ?DO_DUMP_LOG( ?LOG_QUEUE_CITAN,do_dump_citan ),
    
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG);


do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.



-define(DO_DUMP_FIELDS_LOG(FieldNames,Tab),
        try
            QueuesInsert = lists:reverse(Queues),
            mod_mysql:batch_replace(Tab, FieldNames, QueuesInsert, ?MAX_DUMP_RECORD_COUNT),
            put(Key, [])
        catch
            _:Reason->
                ?ERROR_MSG("insert to table:~w error,Key=~w,reason:~w  stack:~w",[Tab,Key,Reason,erlang:get_stacktrace()])
        end).

do_dump_shoubian(Key,Queues) ->
    FieldNames = record_info(fields, r_shoubian_log),
    ?DO_DUMP_FIELDS_LOG(FieldNames,t_log_shoubian).

do_dump_citan(Key,Queues) ->
    FieldNames = record_info(fields, r_citan_log),
    ?DO_DUMP_FIELDS_LOG(FieldNames,t_log_citan).


