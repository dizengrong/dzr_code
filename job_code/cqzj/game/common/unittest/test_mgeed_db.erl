%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     对mnesia和mysql进行简单压力测试
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------

-module(test_mgeed_db).

%%
%% Include files
%%
-define(ERLYDB_OPTIONS,[{pool_id, mysql_connect_pool_id},
						{allow_unsafe_statements, true},
						{skip_fk_checks, true}, debug_info,
						{outdir, "../ebin/"}]).
-define(PAGE_SIZE,10000).	%%	默认的分页的大小
-define(MOD_DRIVER,erlydb_mysql).
 
-define( INFO(F,D),io:format(F, D) ).
-compile(export_all).
-include("common.hrl").

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%
t1()->
	io:format("wuzesen",[]),
	ok.
 
%% @doc 对mnesia的r/w测试
t2_w(Count)->
	SourceTab = ?DB_STALL_P,
	{Time, _Value} = timer:tc(testddb, write_mnesia, [Count]),
	TabSize = mnesia:table_info(?DB_STALL_P,size),
	?INFO("Table=~w,Count=~w,TabSize=~p,write_mnesia cost ~w ms",[SourceTab,Count,TabSize,Time/1000]),
	ok.

%% @doc 对mnesia的r/w测试
t2_r()->
	SourceTab = ?DB_STALL_P,
	TabSize = mnesia:table_info(db_stall_p,size),
	{Time, _Value} = timer:tc(testddb, load_mnesia, []),
	?INFO("Table=~w,TabSize=~p,load_mnesia cost ~w ms",[SourceTab,TabSize,Time/1000]),
	ok.

%% @doc 对mysql的r/w测试
%% 这里可能因为没有一次提交多次事务，所以效率较差？
t3_w(Count)->
	SourceTab = r_stall,
	{Time, _Value} = timer:tc(testddb, write_mysql, [Count]),
	TabSize = mod_mysql:select( lists:concat( ["select count(1) from ",SourceTab] ) ),
	?INFO("Table=~w,Count=~w,TabSize=~p,write_mysql cost ~w ms",[SourceTab,Count,TabSize,Time/1000]),
	ok.

%% @doc 对mysql的r/w测试
%% 这里可能因为没有一次提交多次事务，所以效率较差？
t3_r()->
	SourceTab = r_stall,
	TabSize = mod_mysql:select( lists:concat( ["select count(1) from ",SourceTab] ) ),
	{Time, _Value} = timer:tc(testddb, load_mysql, []),
	?INFO("Table=~w,TabSize=~p,load_mysql cost ~w ms",[SourceTab,TabSize,Time/1000]),
	ok.


%%
%% Local Functions
%%

load_mysql()->
	mnesia:clear_table(?DB_STALL),
    %%TODO 改为非事务
	List = mod_mysql:select( "select `role_id`, `start_time`, `mode`, `time_hour`, `remain_time`, `name`, `role_name`, `tx`, `ty`, `mapid` from r_stall" ),
	?INFO("List=~p",[List]),
	ok.
 
   

write_mysql(Count)->
	lists:foreach(fun(E)-> 
						do_t3(E)
					end, lists:seq(1,Count) ),
	ok.

do_t3(Index)->
	MicroSeconds = common_tool:now_microseconds(),
	Name = integer_to_list( common_tool:now() ),
	Record = #r_stall{role_id=MicroSeconds, start_time=MicroSeconds, mode=Index, time_hour=MicroSeconds, 
					  remain_time=MicroSeconds, name=Name, role_name=Name, tx=2, ty=3, mapid=MicroSeconds},
	
	SQL = " insert into r_stall ( `start_time`, `mode`, `time_hour`, `remain_time`, `name`, `role_name`, `tx`, `ty`, `mapid`) values "
			  ++ io_lib:format("( ~w, ~w, ~w, ~w, '~s','~s', ~w, ~w, ~w)",
							   [ 
								 Record#r_stall.start_time,
								 Record#r_stall.mode,
								 Record#r_stall.time_hour,
								 Record#r_stall.remain_time,
								 Record#r_stall.name,
								 Record#r_stall.role_name,
								 Record#r_stall.tx,
								 Record#r_stall.ty,
								 Record#r_stall.mapid
							   ]),
	mod_mysql:insert(SQL),
	ok.


test_binary(insert)->
	DbTable = vartest,
	Id = common_tool:now(),
	Term = {[{name,wuzesen},{age,28}]},
	
	FieldNames = [id,blog1],
	FieldValues = [Id,Term],
	SqlUpdate = mod_mysql:get_esql_insert(DbTable, FieldNames,FieldValues ),
	?MOD_DRIVER:update(SqlUpdate,?ERLYDB_OPTIONS).

test_binary(update,Id)->
	DbTable = vartest,
	Term = {[{name,jiaqi},{age,19},{sex,girl}]},
	
	UpdateTupleList = [{blog1,term_to_binary(Term)}],
	
	WhereExpr = lists:concat([ "`id`=",Id ]), 
	SqlUpdate = mod_mysql:get_esql_update(DbTable,UpdateTupleList,WhereExpr),
	?MOD_DRIVER:update(SqlUpdate,?ERLYDB_OPTIONS);
 

test_binary(select,Id)->
	DbTable = vartest,
	
	FieldNames = [id,blog1],
	WhereExpr = lists:concat([ "id=",Id ]), 
	SqlSelect = mod_mysql:get_esql_select(DbTable,FieldNames,WhereExpr), 
	Result = ?MOD_DRIVER:select(SqlSelect,?ERLYDB_OPTIONS),
	{ok,[{_,BTerm}]} = Result,
	binary_to_term(BTerm).


write_mnesia(Count)->
	lists:foreach(fun(E)-> 
						do_t2(E)
					end, lists:seq(1,Count) ),
	ok.
	
load_mnesia()->
	db:load_whole_table(?DB_STALL_P, ?DB_STALL),
	ok.

do_t2(Index)->
	MicroSeconds = common_tool:now_microseconds(),
	Name = integer_to_list( common_tool:now() ),
	Record = #r_stall{role_id=MicroSeconds, start_time=MicroSeconds, mode=Index, time_hour=MicroSeconds, 
					  remain_time=MicroSeconds, name=Name, role_name=Name, tx=2, ty=3, mapid=MicroSeconds},
	mnesia:dirty_write(?DB_STALL_P, Record),
	ok.
	
	



