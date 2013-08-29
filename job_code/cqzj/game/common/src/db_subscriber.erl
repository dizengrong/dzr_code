%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     DB层的subscriber
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(db_subscriber).

-behaviour(gen_server).
%%-compile(export_all).

-include("common_server.hrl").
-include("mnesia.hrl").
%% -include("common.hrl").
-define(DB_LOCAL_CACHE_SERVER_STATE_KEY, db_local_cache_server_state_key).
-define(DB_LOCAL_CACHE_QUEUE, db_local_cache_queue).


-define(ETS_TABLE_TYPE, ets_table_type).


%%定时发消息进行持久化
-define(DUMP_INTERVAL, 30 * 1000).

%%累积达到多少条就dump一次
-define(DUMP_NUMBER, 3000).
-define(MSG_DUMP_DATA, dump_data).


%% API
-export([start/2, start_link/3]).
-export([call_subscribe/1,call_unsubscribe/1]).
-export([get_subscriber_name/1,triger_mnesia_table_event/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {counter,ram_tab,disk_tab,tab_type,is_using_mysql,backup_to_mysql}).


%%
%% API Functions
%%

call_subscribe(RamTab)->
	case erlang:whereis( get_subscriber_name(RamTab) ) of
		undefined->
			not_found_subscriber;
		Pid->
			gen_server:call( Pid, call_subscribe)
	end.

call_unsubscribe(RamTab)->
	case erlang:whereis( get_subscriber_name(RamTab) ) of
		undefined->
			not_found_subscriber;
		Pid->
			gen_server:call( Pid, call_unsubscribe)
	end.

get_subscriber_name(RamTab)->
	common_tool:to_atom( lists:concat([RamTab,"_subscriber"]) ).


%%--------------------------------------------------------------------

start(RamTab, DiskTab) ->
	SubscriberName = get_subscriber_name(RamTab),
	
    {ok, _} = supervisor:start_child(mgeed_sup, {SubscriberName, 
                                          {?MODULE, start_link, [SubscriberName,RamTab,DiskTab]},
                                          permanent, 300000, worker, [?MODULE]}).

start_link(SubscriberName,RamTab,DiskTab) ->
    gen_server:start_link({local, SubscriberName}, ?MODULE, [RamTab,DiskTab], []).



%%--------------------------------------------------------------------

init([RamTab,DiskTab]) ->
    erlang:process_flag(trap_exit, true),
	%%?ERROR_MSG("tables is init ~p ~p ~n",[RamTab,db:table_info(RamTab,load_node)]),
	%%subscribe_to_tables([RamTab],3),
	erlang:send_after(4000, self(), {subscriber_table,RamTab,3}),
    %%设置不持久化的表
    [NotPersistentTableList] = common_config_dyn:find(etc,not_persistent_table),
    [ put({table_not_persistent, Table}, true) || Table <- NotPersistentTableList],
    %%保存事务和脏读操作的队列
    init_q(),
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_DATA),
    TabType = mnesia:table_info(RamTab, type),
    IsBackupToMysql = db:is_using_mysql_backup() andalso mysql_persistent_config:is_mysql_table(DiskTab),
    State = #state{counter=0,ram_tab=RamTab,disk_tab=DiskTab,tab_type=TabType,backup_to_mysql=IsBackupToMysql},
    init_state(State),
    {ok, State}.

%% ====================================================================
%% Server functions
%% 		gen_server callbacks
%% ====================================================================

handle_call(call_subscribe, _From, #state{ram_tab=RamTab}=State) ->
	mnesia:subscribe({table, RamTab, detailed}),
    {reply, ok, State};
handle_call(call_unsubscribe, _From, #state{ram_tab=RamTab}=State) ->
	mnesia:unsubscribe({table, RamTab, detailed}),
    {reply, ok, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info({'EXIT', _PID, Reason}, State) ->
    ?ERROR_MSG("~ts ~w,State=~w", ["db_local_cache_serve收到EXIT消息", Reason,State]),
	ignore;

handle_info(Info, State) ->
    try
        do_handle_info(Info,State)
    catch
        _:Reason->
            ?ERROR_MSG("~w do_handle_info出错!,Reason=~w,stacktrace=~w,State=~w",[?MODULE,Reason,erlang:get_stacktrace(),State])
    end,
    
    {noreply, State}.

terminate(_Reason, _State) ->
	do_dump_data(terminal),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================


%% ====================================================================
%% Local Functions
%% ====================================================================
do_handle_info({mnesia_table_event,{delete,schema,{schema,DeleteTab},_OldRecord,_EventInfo}} ,#state{ram_tab=RamTab} ) 
  when DeleteTab=:=RamTab ->
    clear_queue();
do_handle_info({mnesia_table_event,{_Type,schema,_Record,_OldRecord,_EventInfo}} ,_State )  ->
    ignore;
do_handle_info({mnesia_table_event,{delete=Type,Tab,Record,_OldRecord,_EventInfo}} ,#state{ram_tab=Tab,disk_tab=DiskTab,tab_type=TabType} )  ->
	?DEBUG("receive Type=~w,Record=~w",[Type,Record]),
	case Record of
		{Tab,Key}->
			update_table_to_queue(Tab, TabType, {delete,DiskTab,Key});
		_ ->
			update_table_to_queue(Tab, TabType, {delete_object,DiskTab,Record})
	end,
	
	check_dump_dirty_data();
do_handle_info( {mnesia_table_event,{write,Tab,Record,_OldRecord,_EventInfo}} ,#state{ram_tab=Tab,disk_tab=DiskTab,tab_type=TabType} )->
	%%统一用批量或单次的replace into
	%%?ERROR_MSG("mnesia_table_event:~p to ~p ~n",[Record,DiskTab]),
    update_table_to_queue(Tab, TabType, {write,DiskTab,Record}),
    check_dump_dirty_data();
do_handle_info( ?MSG_DUMP_DATA ,_State ) ->
	do_dump_data(),
	erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_DATA);
do_handle_info({subscriber_table,Tab,Times} ,_State ) ->
	subscribe_to_tables([Tab],Times);

do_handle_info( Info,State )->
	?WARNING_MSG("receive unknown Info=~w,State=~w",[Info,State]),
	ok.

triger_mnesia_table_event(Tab,Record) ->
	?ERROR_MSG("write table ~p~n",[Tab]),
	SubScriberName = get_subscriber_name(Tab),
	SubScriberName ! {mnesia_table_event,{write,Tab,Record,[],[]}}.

subscribe_to_tables([Tab | T],Times) ->
    case subscribe_to_table(Tab, Times) of
	ok ->
	    subscribe_to_tables(T,Times);
	E ->
	    E
    end;
subscribe_to_tables([],_) ->
    ok.

%% part of subscribe_to_tables/1
subscribe_to_table(Tab, 0) ->
    ?ERROR_MSG("~ts Subscribe Table `~p` At Node: ~p ~n ",["订阅表失败，请重新启动:",Tab,node()]),
    error;
subscribe_to_table(Tab, C) when is_integer(C) ->
    case mnesia:subscribe({table, Tab, detailed}) of
	{error, {not_active_local, Tab}} ->
	    %% ?ERROR_MSG("~ts Subscribe Table `~p` At Node: ~p ~n ",["订阅表失败，请重新启动:",Tab,node()]),
	    %%mnesia:add_table_copy(Tab, node(), ram_copies),
	   %% subscribe_to_table(Tab, C - 1);
		erlang:send_after(4000, self(), {subscriber_table,Tab,C - 1});
	{error, E} ->
	    ?ERROR_MSG("ERR:Subscribe Table `~p` Error: ~p At Node: ~p ~n ",[Tab,E,node()]),
	    error;
	{ok, _Node} ->
	     %%?ERROR_MSG("Subscribe Table `~p` Success At Node: ~p ~n ",[Tab,Node]),
		 ignore
    end.


check_dump_dirty_data() ->
	#state{counter=DC} = OldState = get_state(),
	
	case DC >= ?DUMP_NUMBER of
		true ->
			do_dump_data(),
			NewState = OldState#state{counter=0};
		false ->
			NewState = OldState#state{counter=DC+1}
	end,
	update_state(NewState).

%%@doc 将数据更新写入队列,并对数据读写进行合并
update_table_to_queue(RamTab, TabTypeArg, Info)->
    TabType = case TabTypeArg of
                  undefined->
                      mnesia:table_info(RamTab,type);
                  _-> TabTypeArg
              end,
    case get({table_not_persistent, RamTab}) of
        undefined ->
            case TabType of
                set->
                    do_dirty_for_set(Info);
                ordered_set->
                    do_dirty_for_set(Info);
                bag->
                    do_dirty( Info )
            end;
        _ ->
            ignore
    end.

%%@doc 对insert/update语句进行去重，这样队列会变小
do_dirty_for_set({CrudType,_Tab,Record} = DirtyInfo) 
  when (CrudType=:=update) orelse (CrudType=:=insert)
           orelse (CrudType=:=write)->
    CompareKey = element(2,Record),
    
    Q1 = lists:filter( fun(Info)-> 
                               check_not_duplicate_record(CrudType,CompareKey,Info)
                       end, get_q()),
    Q2 = [ DirtyInfo | Q1 ],
    update_q(Q2);
do_dirty_for_set(Info)->
    do_dirty( Info ).


%% @doc 检查是否是需要删除的重复字典Record
%% 注意，同一个key，不同的CrudType(update/insert)也是不同的
check_not_duplicate_record(CrudType,CompareKey,{CrudType,_Tab,Record})->
    CompareKey /= element(2,Record);
check_not_duplicate_record(_CrudType,_CompareKey,_DirtyInfo)->
    true.

%% @doc 更新数据队列
%% @spec do_dirty( DirtyInfo::tuple() )
do_dirty( {CrudType,_Tab,_Record} =DirtyInfo ) ->
    Q2 = [ DirtyInfo | get_q() ],
    update_q(Q2),
    if
        CrudType =:= delete orelse CrudType =:= delete_object ->
            mark_delete_tag(true);
        true ->
            ignore
    end.

%%@doc 将数据进行持久化
do_dump_data(terminal) ->
    #state{disk_tab=DiskTab} = get_state(),
    ?WARNING_MSG("~ts,DiskTab=~w",["执行数据的最终持久化",DiskTab]),
    do_dump_data().

do_dump_data() ->
    #state{tab_type=TabType,backup_to_mysql=IsBackupToMysql} = get_state(),
    
    case get_q() of
        [] -> ignore;
        Q1 ->
            QueueList = lists:reverse( Q1 ),
            do_dump_data_2(IsBackupToMysql,TabType,QueueList)
    end.

do_dump_data_2(IsBackupToMysql,TabType,QueueList)->    
    try
        IsDeleteTag = get_delete_tag(),
        case IsBackupToMysql of
            true->
                mod_subscriber_dumper:do_mysql_queues( TabType,QueueList,IsDeleteTag );
            false->
                ignore
        end,
        %%dump成功之后，才清空队列中的数据
        clear_queue()
    catch
        _:Reason->
            State = get_state(),
            ?ERROR_MSG("do_dump_data error,State=~w,Reason=~w,stacktrace=~w",[State,Reason,erlang:get_stacktrace()])
    end.

clear_queue()->
    update_q([]),
    mark_delete_tag(false).

init_state(State) ->
    put(?DB_LOCAL_CACHE_SERVER_STATE_KEY, State).

get_state() ->
    get(?DB_LOCAL_CACHE_SERVER_STATE_KEY).

update_state(State) ->
    put(?DB_LOCAL_CACHE_SERVER_STATE_KEY, State).

get_q() ->
    get(?DB_LOCAL_CACHE_QUEUE).

update_q(Q) ->
    put(?DB_LOCAL_CACHE_QUEUE, Q).

init_q() ->
    put(?DB_LOCAL_CACHE_QUEUE, []).

mark_delete_tag(IsDelete) when is_boolean(IsDelete)->
    put(delete_tag, IsDelete).

get_delete_tag()->
    case get(delete_tag) of
        true->
            true;
        _ ->
            false
    end.

