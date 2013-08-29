%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     用于更新玩家每天的在线时长
%%% @end
%%% Created : 2010-11-18
%%%-------------------------------------------------------------------
-module(mod_online_update_server).

-behaviour(gen_server).
-include("mgeew.hrl").

-export([start/0, 
         start_link/0
         ]).
-export([]).
-export([split_list/2]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
%% --------------------------------------------------------------------


%%每分钟更新在线时长,单位为分钟
-define(UPDATE_ONLINE_TIME_INTERVAL, 60 * 1000).
-define(DUMP_MAX_RECORD_COUNT, 3000).


-define(MSG_DUMP_ONLINETIME_LIST, dump_online_time_list).
-define(ETS_LOG_USER_ONLINE, ets_log_user_online).
-define(LAST_DUMP_MDATE,last_dump_mdate).
-define(T_LOG_DAILY_ONLINE,t_log_daily_online).



-record(state, {}).



%% ====================================================================
%% API functions
%% ====================================================================


      

%% ====================================================================
%% External functions
%% ====================================================================

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE, {?MODULE, start_link, []},
                                                 permanent, 30000, worker, [?MODULE]}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).



%% --------------------------------------------------------------------
init([]) ->
    erlang:process_flag(trap_exit, true),
    
    ets:new(?ETS_LOG_USER_ONLINE, [named_table, set, protected]),
    do_load_temp_online_data(),
    
    erlang:send_after(?UPDATE_ONLINE_TIME_INTERVAL, self(), ?MSG_DUMP_ONLINETIME_LIST),
    
    {ok, #state{}}.
 
 
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
    ?ERROR_MSG("等待将在线用户时长的临时数据 写入到db中",[]),
    do_dump_online_time(),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_handle_info(?MSG_DUMP_ONLINETIME_LIST)->
    
    do_update_online_time(),
    
    erlang:send_after(?UPDATE_ONLINE_TIME_INTERVAL, self(), ?MSG_DUMP_ONLINETIME_LIST);


%% do_handle_info({ming2_fun,Fun,Args})->
%%     erlang:apply(?MODULE,Fun, Args);
do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.
 


%%@doc 每隔1分钟来检查一下，将当前用户的时长更新到ets表中。
do_update_online_time()->
    Pattern = #r_role_online{ _ = '_'},
    case db:dirty_match_object(?DB_USER_ONLINE,Pattern) of
        [] ->
            ignore;
        Records->
            lists:foreach(fun(Rec)->
                                  #r_role_online{role_id=RoleID} = Rec,   
                                  do_update_online_time_2(RoleID)
                          end,Records)
    end.

do_update_online_time_2(RoleID)->
    case ets:lookup(?ETS_LOG_USER_ONLINE,RoleID) of
        [{RoleID,OnlineTime}]->
            ets:insert(?ETS_LOG_USER_ONLINE, {RoleID,OnlineTime+1});
        []->
            ets:insert(?ETS_LOG_USER_ONLINE, {RoleID,1})
    end,
    check_dump_to_db().

%%@doc 如果>23:56分，并且还没有持久化过的，则将数据持久化到db中
check_dump_to_db()->
    {Hour, Minute, _Second} = erlang:time(),
    case ( Hour>=23 ) andalso( Minute>56 ) of
        false->
            ignore;
        true->
            case get(?LAST_DUMP_MDATE) =:= get_mdate() of
                true->
                    ignore;
                false->
                    do_dump_online_time()
            end
    end.

get_mdate()->
    get_mdate(erlang:date()).
get_mdate({Year,Month,Day})->
    Year*10000 + Month*100 + Day.



%%@doc 将数据持久化到db中，并且清空ets表。
do_dump_online_time()->
    try
        ?ERROR_MSG("do_dump_online_time,Time=~w",[erlang:time()]),
        %%批量插入的数据，目前最大不能超过3M
        FieldNames = [ role_id,mdate,year,month,day,online_time ],
        {Year,Month,Day} = erlang:date(),
        MDate = get_mdate( {Year,Month,Day} ),
        do_delete_temp_online_date(MDate),
        
        UserOnlineList = ets:tab2list(?ETS_LOG_USER_ONLINE),
        case UserOnlineList of
            []->
                ignore;
            _ ->
                SrcBatchFieldValues = [ [RoleID,MDate,Year,Month,Day,OnlineTime]||{RoleID,OnlineTime}<-UserOnlineList ],
                
                mod_mysql:batch_insert(?T_LOG_DAILY_ONLINE,FieldNames,SrcBatchFieldValues,?DUMP_MAX_RECORD_COUNT)
        end,
        
        %%插入成功之后，再清空ETS表
        ets:delete_all_objects(?ETS_LOG_USER_ONLINE),
        put(?LAST_DUMP_MDATE,MDate)
    catch
        _:Reason->
            ?ERROR_MSG("更新玩家在线时长出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.

split_list(SrcList,DestList) when length(SrcList) =< ?DUMP_MAX_RECORD_COUNT ->
    [SrcList|DestList];
split_list(SrcList,DestList)->
    {SubList1,SubList2} = lists:split(?DUMP_MAX_RECORD_COUNT, SrcList),
    split_list(SubList2,[SubList1|DestList]).


do_delete_temp_online_date(MDate)->
    WhereExpr = io_lib:format(" mdate=~w ",[MDate]),
    SQL = mod_mysql:get_esql_delete(?T_LOG_DAILY_ONLINE, WhereExpr ),
    {ok,_} = mod_mysql:delete(SQL).

%%@doc 在启动的时候从数据库中读取当天的临时数据。
do_load_temp_online_data()->
    try
        {Year,Month,Day} = erlang:date(),
        MDate = get_mdate({Year,Month,Day}),
        WhereExpr = io_lib:format(" mdate=~w ",[MDate]),
        Sql = mod_mysql:get_esql_select(?T_LOG_DAILY_ONLINE,[role_id,online_time], WhereExpr),
        {ok,ResultSet} = mod_mysql:select(Sql),
        ?DEBUG("ResultSet=~w",[ResultSet]),
        case ResultSet of
            []->ignore;
            _->
                [ ets:insert(?ETS_LOG_USER_ONLINE, {RoleID,OnlineTime}) ||[RoleID,OnlineTime]<-ResultSet ]
        end
    catch
        _:Reason->
            ?ERROR_MSG("do_load_temp_online_data 出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.

