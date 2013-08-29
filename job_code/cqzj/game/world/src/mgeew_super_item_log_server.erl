%%% -------------------------------------------------------------------
%%% Author  : markycai
%%% Description :提供高级物品记录
%%% Created : 2011-3-14
%%% -------------------------------------------------------------------
-module(mgeew_super_item_log_server).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").

%% 写到数据库的数据队列
-define(SUPER_ITEM_LOG_QUEUE,super_item_log_queue).
-define(DUMP_MAX_RECORD_COUNT,300).
-define(SUPER_ITEM_LOG_COUNTER_KEY,super_item_log_counter).

%% 定时器尽量使数据和t_log_item写入数据库的进度相仿
-define(DUMP_INTERVAL, 30 * 1000).
-define(MSG_DUMP_SUPER_LOG, dump_super_item_log).
%% --------------------------------------------------------------------
%% External exports
-export([start/0,start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
start()->
    {ok,_} = supervisor:start_child(mgeew_sup,
                                    {?MODULE,
                                     {?MODULE,start_link,[]},
                                     permanent,30000,worker,[?MODULE]}).

start_link()->
    gen_server:start_link({global,?MODULE},?MODULE,[],[]).



%% ====================================================================
%% Server functions
%% ====================================================================

init([]) ->
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_SUPER_LOG),
    erlang:process_flag(trap_exit, true),
    {ok, #state{}}.


handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    do_dump_super_item_logs(),
    %%do_dump_item_logs(),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

do_handle_info({log,Record,Goods})->
    do_log_record(Record,Goods);

do_handle_info(?MSG_DUMP_SUPER_LOG)->
    do_dump_super_item_logs(),
    erlang:send_after(?DUMP_INTERVAL, self(), ?MSG_DUMP_SUPER_LOG);

do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message ,Info = ~w~n",[Info]),
    ignore.

do_log_record(Record,Goods)->
    {Count,SuperItemLogVal} = create_super_item_log_value(Goods),
    Record1 = Record#r_item_log{super_unique_id = Count},
    case get(?SUPER_ITEM_LOG_QUEUE) of
        undefined->
            put( ?SUPER_ITEM_LOG_QUEUE,[SuperItemLogVal]);
        SuperQueues->
            put(?SUPER_ITEM_LOG_QUEUE,[SuperItemLogVal|SuperQueues])
    end,
    common_item_log_server:insert_log(Record1),

    check_do_dump_logs().

%% 检查是否有必要dump log数据
check_do_dump_logs()->
    Queues = get(?SUPER_ITEM_LOG_QUEUE),
    case length(Queues)>?DUMP_MAX_RECORD_COUNT of
        false->
            ignore;
        true->
            %%先写高级道具详细表,再写日志表
            do_dump_super_item_logs()
            %%do_dump_item_logs()
    end.

do_dump_super_item_logs()->
    case get(?SUPER_ITEM_LOG_QUEUE) of
        undefined->ignore;
        []->ignore;
        SuperQueues->
            try
                FieldNames = [super_unique_id,mtime,type_id,level,reinforce_result,punch_num,stone_num,signature,refining_index,stones],
                
                QueuesInsert = lists:reverse(SuperQueues),
                mod_mysql:batch_replace(t_log_super_item,FieldNames,QueuesInsert,3000),
                put(?SUPER_ITEM_LOG_QUEUE,[])
            catch
                _:Reason->
                    ?ERROR_MSG("持久化高级道具日志出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
            end
    end.

%%从mnesia中获取主键
get_super_item_log_counter()->

     Count1 =case db:dirty_read(?DB_WORLD_COUNTER,?SUPER_ITEM_LOG_COUNTER_KEY) of
                 [Count]->
                     #r_world_counter{value=Val}=Count,
                     Val;
                 _-> 1
             end,
    db:dirty_write(?DB_WORLD_COUNTER,#r_world_counter{key = ?SUPER_ITEM_LOG_COUNTER_KEY,value = Count1+1}),
    Count1.

%% 生成高级道具记录
create_super_item_log_value(Goods)->
    Count = get_super_item_log_counter(),
    if is_record(Goods,p_goods) ->
           #p_goods{typeid=TypeID,
                    level=Level,
                    reinforce_result=ReinforceRes,
                    punch_num = PunchNum,
                    stone_num = StoneNum,
                    signature = Signature,
                    refining_index = RefIndex,
                    stones = Stones}=Goods,
           StonesInfo = case Stones of
                            []->undefined;
                            _-> {_StonesNum,StonesList}=
                                    lists:foldr(fun(Stone,{K,JsonList})->
                                                    {K+1,[{K,Stone#p_goods.typeid}|JsonList]}
                                                    end,{0,[]},Stones),
                                common_json2:to_json(StonesList)
                        end,
           {Count,{Count,common_tool:now(),TypeID,Level,ReinforceRes,PunchNum,StoneNum,Signature,RefIndex,StonesInfo}};
       is_record(Goods,r_goods_create_info)->
           #r_goods_create_info{type_id =TypeID}=Goods,
           {Count,{Count,common_tool:now(),TypeID,undefined,undefined,undefined,undefined,undefined,undefined,undefined}};
       true->
           {Count,{Count,common_tool:now(),undefined,undefined,undefined,undefined,undefined,undefined,undefined,undefined}}
    end.








