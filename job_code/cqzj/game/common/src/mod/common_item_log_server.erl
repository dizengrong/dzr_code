%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     记录游戏中的道具日志的缓存服务器
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(common_item_log_server).
-behaviour(gen_server).


-export([start/1,
         start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([insert_log/1,format_log_tab_name/0,check_partition_table/0]).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").
-include("common_server.hrl").

%% 需要合并的道具使用记录类型
-define(COMBINE_ITEM_TYPE_LIST,[?LOG_ITEM_TYPE_SHI_QU_HUO_DE,?LOG_ITEM_TYPE_SHI_YONG_SHI_QU]).

%%定时发消息进行持久化
-define(DUMP_INTERVAL, 30 * 1000).
-define(MINUTE,60*1000). %%一分钟
-define(MAX_DUMP_RECORD_COUNT, 3000).

-define(MSG_DUMP_LOG, dump_item_log).
-define(MSG_DUMP_COMBINE_ITEM_LOG, dump_combine_item_log).
-define(COMBINE_KEY,combine_key).

-define(ITEM_LOG_QUEUE, log_queue).
-define(COMBINE_ITEM_LOG_QUEUE,combine_item_log_queue).




%% ====================================================================
%% API functions
%% ====================================================================

insert_log(Record) when is_record(Record,r_item_log)->
    erlang:send(?MODULE, {item_log,Record}),
    ok.


%% ====================================================================
%% External functions
%% ====================================================================

start(Supervisor) ->
    {ok, _} = supervisor:start_child(Supervisor, {?MODULE, {?MODULE, start_link, []},
                                                 permanent, 30000, worker, [?MODULE]}).
    

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [],[]).

init([]) ->
    %{ok,_} = check_partition_table(),
    
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG),
    
    [CombineItemInterval] = common_config_dyn:find(logs,combine_item_log_interval),
    erlang:send_after(CombineItemInterval*?MINUTE,self(),?MSG_DUMP_COMBINE_ITEM_LOG),
    
    put(?COMBINE_KEY,get_now_combine_key()),
    put(?COMBINE_ITEM_LOG_QUEUE,[]),
    put(?ITEM_LOG_QUEUE,[]),

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
    ?ERROR_MSG("等待将道具日志的临时数据 写入到db中",[]),
    do_dump_item_logs(),
    do_dump_combine_item_logs(),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

get_now_combine_key()->
    %%通过整点的时间点来明显标识是否为合并数据
    {H,_M,_S} = erlang:time(),
    NowDateTime = {erlang:date(),{H,0,0}},
    common_tool:datetime_to_seconds(NowDateTime).



do_handle_info({item_log,#r_item_log{action=Action,color=Color}=Record})->
    case lists:member(Action, ?COMBINE_ITEM_TYPE_LIST) andalso (Color=<?COLOUR_WHITE) of
        true->
            %%只针对道具和白色的装备进行合并
            merge_combine_log_queue(?COMBINE_ITEM_LOG_QUEUE,Record);
        _ ->
            [r_item_log|T] = tuple_to_list(Record),
            
            common_misc:update_dict_queue(?ITEM_LOG_QUEUE,T)
    end;

do_handle_info(?MSG_DUMP_COMBINE_ITEM_LOG)->
    do_dump_combine_item_logs(),
    
    [CombineItemInterval] = common_config_dyn:find(logs,combine_item_log_interval),
    erlang:send_after(CombineItemInterval*?MINUTE,self(),?MSG_DUMP_COMBINE_ITEM_LOG);

do_handle_info(?MSG_DUMP_LOG)->
    do_dump_item_logs(),
    
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_LOG);
    

do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.


%%@doc 将合并记录更新到mysql中
%%      持久化之后便立即清空队列
%% [{{RoleID,Action,ItemID},RoleLevel,Amount,Color,Fineness}] = Queues
save_combine_records_to_mysql(CurrentMTime)->
    case get(?COMBINE_ITEM_LOG_QUEUE) of
        []->ignore;
        undefined->ignore;
        Queues->
            %%?INFO_MSG("save_combine_records_to_mysql,CurrentMTime=~w,Queues=~w",[CurrentMTime,Queues]),
            TabName = get_item_log_tab_name(),
            QueuesInsert = lists:reverse(Queues),
            
            %%批量插入的数据
            FieldNames = [ userid, userlevel, action, itemid, amount, equipid, color, fineness, start_time, end_time,bind_type ,super_unique_id ],
            BatchFieldValues = [ [RoleID,RoleLevel,Action,ItemID,Amount,0,Color,Fineness,CurrentMTime,0,0,SuperUID]
                                 ||{{RoleID,Action,ItemID},RoleLevel,Amount,Color,Fineness,SuperUID}<-QueuesInsert],
            
            %%每次批量插入3000条
            mod_mysql:batch_insert(TabName,FieldNames,BatchFieldValues,?MAX_DUMP_RECORD_COUNT),
            put(?COMBINE_ITEM_LOG_QUEUE,[])
    end.

%%@doc 持久化已合并的道具使用日志
do_dump_combine_item_logs()->
    ?INFO_MSG("do_dump_combine_item_logs",[]),
    try
        CurrentCombineKey = get(?COMBINE_KEY),
        save_combine_records_to_mysql(CurrentCombineKey),
        
        %%生成下一次的合并Key
        NewKey = get_now_combine_key(),
        put(?COMBINE_KEY,NewKey)
    catch
        _:Reason->
            ?ERROR_MSG("持久化合并的道具使用日志出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.

%%@doc 合并道具使用记录
merge_combine_log_queue(QueueKey,CombineItemRecord)->
    ?INFO_MSG("CombineItemRecord=~w",[CombineItemRecord]),
    Val = merge_combine_log_queue2( QueueKey,CombineItemRecord),
    put(QueueKey,Val).

%%@doc 将更新的record合并到Queues中
%% 目前的实现，有可能将今天凌晨1点的记录合并到昨天的数据中
%% [{{RoleID,Action,ItemID},RoleLevel,Amount,Color,Fineness}] = Queues
merge_combine_log_queue2( QueueKey,Rec)->
    #r_item_log{role_id=RoleID,role_level=RoleLevel,action=Action,item_id=ItemID,
                amount=Amount,color=Color,fineness=Fineness,super_unique_id=SuperUID}=Rec,
    Key = {RoleID,Action,ItemID},
    case get(QueueKey) of
        []->
            [{Key,RoleLevel,Amount,Color,Fineness,SuperUID}];
        Queues ->
            case lists:keyfind(Key, 1, Queues) of
                false->
                    [{Key,RoleLevel,Amount,Color,Fineness,SuperUID} |Queues];
                {Key,_OldRoleLevel,OldAmount,_,_,_}->
                    lists:keystore(Key, 1, Queues, {Key,RoleLevel,Amount+OldAmount,Color,Fineness,SuperUID})
            end
    end.

%%@doc 确认日志表是否存在
check_partition_table()->
    case common_config_dyn:find(logs,is_item_log_partition) of
        [true]->
            TabName = format_log_tab_name(),
            SQL = mod_mysql:get_esql_select(TabName,[id],"where 1=2 "), 
            {ok,_} = mod_mysql:select(SQL);
        _ ->
            {ok,ignore}
    end.


do_dump_item_logs()->
    case get(?ITEM_LOG_QUEUE) of
        undefined-> ignore;
        [] -> ignore;
        Queues ->
            try
                TabName = get_item_log_tab_name(),
                %%批量插入的数据，目前最大不能超过3M
                FieldNames = [ userid, userlevel, action, itemid, amount, equipid, color, fineness, start_time, end_time,bind_type,super_unique_id],
                QueuesInsert = lists:reverse(Queues),
                
                mod_mysql:batch_insert(TabName,FieldNames,QueuesInsert,?MAX_DUMP_RECORD_COUNT),
                put(?ITEM_LOG_QUEUE, [])
            catch
                _:_Reason->ok
                    % ?ERROR_MSG("持久化道具日志出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
            end
    end.

%%@doc 获取道具日志表名
get_item_log_tab_name()->
    case common_config_dyn:find(logs,is_item_log_partition) of
        [true]->
            format_log_tab_name();
        _ ->
            t_log_item
    end.

%%@doc 格式化道具日志表名
format_log_tab_name()->
    {Y,_M,_D} = Date = erlang:date(),
    Week = lists:flatten( io_lib:format("_~2..0B", [common_time:week_of_year( Date )]) ) ,
    TabName = lists:concat([t_log_item_,Y,Week]),
    
    [DBName] = common_config_dyn:find_common(db_name_logs),
    {table,DBName,common_tool:to_atom( TabName )}.
 


