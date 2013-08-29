%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 12 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_mysql).

%%
%% Include files
%%
-include("common_server.hrl").


%%
%% Exported Functions
%%
-export([
         get_large_pool_size/0,
         get_normal_pool_size/0,
         get_mini_pool_size/0,
         start/0,start/1,start/2,
         select/1,select/2,
         insert/1,insert/2,
         update/1,update/2,
         delete/1,delete/2,
         batch_insert/4,batch_replace/4,
         batch_insert/5,batch_replace/5
        ]).
-export([db_debug_log/4,db_error_log/4]).
-export([get_node_pool_size/0]).

-export([get_esql_select/3,get_esql_insert/3,get_esql_update/3,get_esql_delete/2,get_esql_replace/3]).

-define(MYSQL_CONNECT_POOL_ID, mysql_connect_pool_id).
-define(ERLYDB_OPTIONS,[{pool_id, ?MYSQL_CONNECT_POOL_ID},
						{allow_unsafe_statements, true},
						{skip_fk_checks, true}, debug_info,
						{outdir, "../ebin/"}]).
-define(DEFAULT_TIMEOUT,5000). %%默认超时也是5sec

%% 默认的每个 节点连接池大小
-define(MYSQL_NORMAL_POOL_SIZE, 6).

%% 较小的每个 节点连接池大小
-define(MYSQL_MINI_POOL_SIZE, 3).

%% 设置的较大的节点连接池大小
-define(MYSQL_LARGE_POOL_SIZE, 50).
-define(ENCODING, utf8).
-define(MYSQL_PORT, 3306).



%% ====================================================================
%% API functions
%% ====================================================================

get_normal_pool_size()->
	?MYSQL_NORMAL_POOL_SIZE.

get_large_pool_size()->
	?MYSQL_LARGE_POOL_SIZE.

get_mini_pool_size()->
    ?MYSQL_MINI_POOL_SIZE.

%%@doc 获取本节点的实际连接池大小
get_node_pool_size()->
    mysql:get_pool_size().

start() ->
	start(?MYSQL_NORMAL_POOL_SIZE).

start(PoolSize) ->
    MySqlConfig = common_config:get_mysql_config(),
    start(PoolSize,MySqlConfig).

%%@doc 通过mod_mysql_assist_server来启动mysql连接池
start(PoolSize,MySqlConfig)->
    {ok,_} = common_mysql_sup:start_link(),
    {ok,_} = mod_mysql_assist_server:start(),
    mod_mysql_assist_server:start_mysql_pool(PoolSize,MySqlConfig).


db_debug_log(Module, Line, Level, FormatFun) when (Level=:=error) orelse (Level=:=warn) ->
	db_error_log(Module, Line, Level, FormatFun);
db_debug_log(Module, Line, Level, FormatFun) ->
	mysql:log(Module, Line, Level, FormatFun).

db_error_log(Module, Line, Level, FormatFun) when (Level=:=error) orelse (Level=:=warn)->
	{Format, Arguments} = FormatFun(),
	?WARNING_MSG("~w:~b: "++ Format ++ "~n", [Module, Line] ++ Arguments);
db_error_log(_Module, _Line, _Level, _FormatFun)->
	ignore.



%%
%% CRUD Functions
%%
select(SQL) ->
    do_select(SQL,?DEFAULT_TIMEOUT).
select(SQL,TimeOut) when is_integer(TimeOut) ->
    do_select(SQL,TimeOut).

insert(SQL) ->
    do_sql(SQL,?DEFAULT_TIMEOUT).            
insert(SQL,TimeOut) when is_integer(TimeOut) ->
    do_sql(SQL,TimeOut).

update(SQL) ->
    do_sql(SQL,?DEFAULT_TIMEOUT).
update(SQL,TimeOut) when is_integer(TimeOut) ->
    do_sql(SQL,TimeOut).

delete(SQL) ->
    do_sql(SQL,?DEFAULT_TIMEOUT).
delete(SQL,TimeOut) when is_integer(TimeOut) ->
    do_sql(SQL,TimeOut).


%%@doc 批处理方式的insert into
batch_insert(DbTable,FieldNames,SrcBatchFieldValues,MaxRecordCount) ->
    batch_insert(DbTable,FieldNames,SrcBatchFieldValues,MaxRecordCount,?DEFAULT_TIMEOUT).

batch_insert(_,_,[],_,_)->
	ignore;
batch_insert(DbTable,FieldNames,SrcBatchFieldValues,MaxRecordCount,TimeOut) when TimeOut>0->
    BatchFieldValList = do_split_list(SrcBatchFieldValues,[],MaxRecordCount),
    [ begin 
          SQL = {esql, {insert,DbTable, FieldNames,SubBatchFieldVals }},
          {ok,_} = do_sql(SQL,TimeOut)
      end ||SubBatchFieldVals<-BatchFieldValList].

%%@doc 批处理方式的replace into
batch_replace(DbTable,FieldNames,SrcBatchFieldValues,MaxRecordCount) ->
    batch_replace(DbTable,FieldNames,SrcBatchFieldValues,MaxRecordCount,?DEFAULT_TIMEOUT).

batch_replace(_,_,[],_,_)->
	ignore;
batch_replace(DbTable,FieldNames,SrcBatchFieldValues,MaxRecordCount,TimeOut) when TimeOut>0->
    BatchFieldValList = do_split_list(SrcBatchFieldValues,[],MaxRecordCount),
    [ begin 
          SQL = {esql, {replace,DbTable, FieldNames,SubBatchFieldVals }},
          {ok,_} = do_sql(SQL,TimeOut)
      end ||SubBatchFieldVals<-BatchFieldValList].

do_split_list(SrcList,DestList,MaxRecordCount) when length(SrcList) =< MaxRecordCount ->
    [SrcList|DestList];
do_split_list(SrcList,DestList,MaxRecordCount)->
    {SubList1,SubList2} = lists:split(MaxRecordCount, SrcList),
    do_split_list(SubList2,[SubList1|DestList],MaxRecordCount).

do_sql({esql,_} = ESql,TimeOut) when TimeOut>0 ->
    Options = [{erlydb_timeout,TimeOut}|?ERLYDB_OPTIONS],
    erlydb_mysql:update(ESql,Options);
do_sql(SQL,TimeOut) when TimeOut>0 ->
    mysql:fetch(?MYSQL_CONNECT_POOL_ID, SQL, TimeOut).

%%@doc !!默认erlydb_mysql是返回tupleList的，此处为了统一接口，返回[FiledList],FiledList=[Field1,Field2,Field3,...]
do_select({esql,_} = ESql,TimeOut) when TimeOut>0 ->
    Options = [{erlydb_timeout,TimeOut}|?ERLYDB_OPTIONS],
    case erlydb_mysql:select(ESql,Options) of
        {ok,[]} = R1-> R1;
        {ok,TupleList} when is_list(TupleList)->
            {ok,[ tuple_to_list(T)||T<-TupleList ]};
        Other->
            Other
    end;
do_select(SQL,TimeOut) when TimeOut>0 ->
    case mysql:fetch(?MYSQL_CONNECT_POOL_ID, SQL, TimeOut) of
        {data, MysqlRes} ->
            {ok, mysql:get_result_rows(MysqlRes)};
        {error, Reason} ->
            {error, Reason }
    end.


%%%%%%%%%%%%%%%%%%%%%%%%
%% @doc get_esql for select/insert/update/delete
%% DbTable 类型是atom，或tuple 指定其他数据库的表:{table,DBName,TableName}

get_esql_select(DbTable,FieldNames,WhereExpr) 
  when is_list(FieldNames) ->
    case WhereExpr of
        []->
            {esql, {select, FieldNames, {from, [DbTable]} }};
        _->
            {esql, {select, FieldNames, {from, [DbTable]}, {where, WhereExpr}}}
    end.

%%@doc 只支持单记录的replace into 
get_esql_replace(DbTable,FieldNames,FieldValues) 
  when  is_list(FieldNames) andalso is_list(FieldValues) ->
    {esql, {replace,DbTable, FieldNames,[FieldValues] }}.

%%@doc 只支持单记录的insert into
get_esql_insert(DbTable,FieldNames,FieldValues) 
  when  is_list(FieldNames) andalso is_list(FieldValues) ->
    {esql, {insert,DbTable, FieldNames,[FieldValues] }}.


get_esql_update(DbTable,UpdateTupleList,WhereExpr)
  when  is_list(UpdateTupleList) ->
    case WhereExpr of
        []->
            {esql, {update, DbTable, UpdateTupleList }};
        _->
            {esql, {update, DbTable, UpdateTupleList, {where, WhereExpr} }}
    end.

get_esql_delete(DbTable,WhereExpr) when is_atom(DbTable) orelse is_tuple(DbTable)->
    case WhereExpr of
        []->
            {esql, {delete, DbTable}};
        
        _ ->
            {esql, {delete, DbTable, {where, WhereExpr} }}
    end.




