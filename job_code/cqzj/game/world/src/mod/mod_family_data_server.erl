%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     宗族的数据处理Server
%%% @end
%%% Created : 2010-11-18
%%%-------------------------------------------------------------------
-module(mod_family_data_server).

-behaviour(gen_server).
-include("mgeew.hrl").

-export([start/0, 
         start_link/0
         ]).
-export([update/1,delete/1,create/1,combine/2]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
%% --------------------------------------------------------------------


%%每分钟更新在线时长,单位为分钟
-define(UPDATE_FAMILY_DATA_INTERVAL, 60 * 1000).


-define(MSG_DUMP_DATA, dump_family_data_list).
-define(LOG_QUEUE, log_queue).
-define(FAMILY_CREATE_TIME_LIST,family_create_time_list).


-record(state, {}).



%% ====================================================================
%% API functions
%% ====================================================================
delete(FamilyID)->
    erlang:send(?MODULE, {delete,FamilyID}),
    ok.

create(FamilyInfo)->
    erlang:send(?MODULE, {create,FamilyInfo}),
    ok.

update(FamilyInfo)->
    erlang:send(?MODULE, {update,FamilyInfo}),
    ok.
      
combine(CombineFamily,TargetFamily)->
    erlang:send(?MODULE, {combine,CombineFamily,TargetFamily}),
    ok.

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
    load_family_time_list(),
    
    erlang:send_after(?UPDATE_FAMILY_DATA_INTERVAL, self(), ?MSG_DUMP_DATA),
    
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
    ?ERROR_MSG("等待将在宗族的临时数据 写入到db中",[]),
    do_dump_family_data(),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_handle_info(?MSG_DUMP_DATA)->
    erlang:send_after(?UPDATE_FAMILY_DATA_INTERVAL, self(), ?MSG_DUMP_DATA),
    do_dump_family_data(),
    ok;

do_handle_info({delete,FamilyID})->
    case get(?LOG_QUEUE) of
        undefined ->
            ignore;
        []->
            ignore;
        Queues ->
            Queues2 = lists:filter(fun([H|_T2])->H=/=FamilyID end, Queues),
            put( ?LOG_QUEUE,Queues2 )
    end,
    try
        SQL = io_lib:format("delete from t_family_summary where `family_id`= ~w;", [FamilyID]),
        mod_mysql:delete(SQL),
        
        %%删除宗族仓库日志
        SQL2 = io_lib:format("delete from t_family_depot_put_logs where `family_id`= ~w;", [FamilyID]),
        mod_mysql:delete(SQL2),
        
        SQL3 = io_lib:format("delete from t_family_depot_get_logs where `family_id`= ~w;", [FamilyID]),
        mod_mysql:delete(SQL3)
    catch
        _:Reason->
            ?ERROR_MSG("删除宗族出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end;
do_handle_info({create,FamilyInfo})->
    #p_family_info{family_id=FamilyID} = FamilyInfo,
    CreateTime = common_tool:now(),
    update_family_create_time({FamilyID,CreateTime}),
    do_create_family_info(FamilyInfo,CreateTime);
do_handle_info({update,FamilyInfo})->
    #p_family_info{family_id=FamilyID} = FamilyInfo,
    CreateTime = get_family_create_time(FamilyID), 
    do_update_family_info(FamilyInfo,CreateTime);

do_handle_info({combine,CombineFamily,TargetFamily})->
	#p_family_info{family_id=FamilyID,family_name=FamilyName,owner_role_id=OwnerRoleID,
				   active_points=ActivePoints,cur_members=CurMembers,money=Money,
				   level=Level,gongxun=Gongxun,owner_role_name=OwnerRoleName,faction_id=FactionID} = CombineFamily,
	#p_family_info{family_id=TargetFamilyID,family_name=TargetFamilyName} = TargetFamily,
	FieldNames = [combine_family_id, combine_family_name, target_family_id, target_family_name, owner_role_id, 
				  owner_role_name, faction_id, active_points, money, cur_members, level, gongxun, create_time],
	FieldValues = [FamilyID,FamilyName,TargetFamilyID,TargetFamilyName,OwnerRoleID,OwnerRoleName,FactionID,ActivePoints,Money,CurMembers,Level,Gongxun,common_tool:now()],
	SQL = mod_mysql:get_esql_insert(t_family_combine,FieldNames,FieldValues),
	{ok,_} = mod_mysql:insert(SQL);

do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.

%%@doc 创建宗族信息
do_create_family_info(FamilyInfo,CreateTime) when is_record(FamilyInfo,p_family_info)->
    FieldValues = get_FieldValues(FamilyInfo,CreateTime),
    try 
        FieldNames = [family_id, family_name, create_role_id, create_role_name, owner_role_id, 
                              owner_role_name, faction_id, active_points, money, cur_members, level, gongxun, create_time],
        SQL = mod_mysql:get_esql_insert(t_family_summary,FieldNames,FieldValues),
        {ok,_} = mod_mysql:insert(SQL)
    catch
        _:Reason->
            ?ERROR_MSG("创建宗族数据出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.

%%@doc 更新宗族信息
do_update_family_info(FamilyInfo,CreateTime) when is_record(FamilyInfo,p_family_info)->
    FieldValues = get_FieldValues(FamilyInfo,CreateTime),
    update_queue(?LOG_QUEUE,FieldValues).

get_FieldValues(FamilyInfo,CreateTime)when is_record(FamilyInfo,p_family_info)->
    #p_family_info{family_id=FamilyID, family_name=FamilyName, 
                   faction_id=FactionID, active_points=ActivePoints,
                   money=Money, cur_members=CurMembers,
                   level=Level, gongxun=Gongxun,
                   create_role_id=CreateRoleID, create_role_name=CreateRoleName,
                   owner_role_id=OwnerRoleID, owner_role_name=OwnerRoleName
                  } = FamilyInfo,
    %%这里的顺序必须跟字段对应
    FieldValues = [FamilyID, FamilyName, CreateRoleID, CreateRoleName, 
                   OwnerRoleID,OwnerRoleName, FactionID, ActivePoints, 
                   Money, CurMembers, Level, Gongxun, CreateTime],
    FieldValues.

update_family_create_time({FamilyID,_CreateTime}=UpdateInfo) when is_integer(FamilyID)->
    case get(?FAMILY_CREATE_TIME_LIST) of
        TimeList when is_list(TimeList)->
            List2 = lists:keydelete(FamilyID, 1, TimeList),
            put(?FAMILY_CREATE_TIME_LIST,[UpdateInfo|List2]);
        _ ->
            put(?FAMILY_CREATE_TIME_LIST,[UpdateInfo])
    end.
get_family_create_time(FamilyID) when is_integer(FamilyID)->
    Time = case get(?FAMILY_CREATE_TIME_LIST) of
               TimeList when is_list(TimeList)->
                   case lists:keyfind(FamilyID, 1, TimeList) of
                       {_,Time1}->
                           Time1;
                       _ ->
                           now
                   end;
               _ ->
                   now
           end,
    case Time of
        now->
            CreateTime = common_tool:now(),
            update_family_create_time({FamilyID,CreateTime}),
            CreateTime;
        _ ->
            Time
    end.


%%@doc 从mysql加载宗族的创建时间
load_family_time_list()->
    try
        SQL = mod_mysql:get_esql_select(t_family_summary,[family_id,create_time], []),
        {ok,ResultSet} = mod_mysql:select(SQL),
        case ResultSet of
            []->ignore;
            _->
                put(?FAMILY_CREATE_TIME_LIST,[ {FamilyID,CreateTime} ||[FamilyID,CreateTime]<-ResultSet ] )
        end
    catch
        _:Reason->
            ?ERROR_MSG("从mysql加载宗族的创建时间出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()]),
            throw({error,Reason})
    end.
 

%%@doc 将数据更新到log的队列
update_queue(TheKey,FieldValues) when is_list(FieldValues)->
    case get(TheKey) of
        undefined ->
            put(TheKey, [FieldValues]);
        Queues ->
            [FamilyID|_T] = FieldValues,
            Queues2 = lists:filter(fun([H|_T2])->H=/=FamilyID end, Queues),
            put( TheKey,[FieldValues|Queues2] )
    end.
 


%%@doc 将数据持久化到db中，批量更新
do_dump_family_data()->
    try 
        case get(?LOG_QUEUE) of
            undefined->
                ignore;
            []->
                ignore;
            Queues->
                FieldNames = [family_id, family_name, create_role_id, create_role_name, owner_role_id, 
                              owner_role_name, faction_id, active_points, money, cur_members, level, gongxun, create_time],
                QueuesInsert = lists:reverse(Queues),
                mod_mysql:batch_replace(t_family_summary,FieldNames,QueuesInsert,3000),
                
                %%持久化之后清空缓存
                put(?LOG_QUEUE,[])
        end
    catch
        _:Reason->
            ?ERROR_MSG("更新宗族数据出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.
 
  
