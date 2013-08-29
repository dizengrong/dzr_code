%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     数据库的简单压力测试
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_db).

%%
%% Include files
%%
%%
%% Include files
%%
 
-define( INFO(F,D),io:format(F, D) ).
-compile(export_all).
-include("common.hrl").
-include("common_server.hrl").
-define(MYSQL_CONNECT_POOL_ID, mysql_connect_pool_id).

%%
%% Exported Functions
%%
-export([]).

t()->
    ?ERROR_MSG("吴泽森,~w",[abc]),
    ?ERROR_MSG("~ts,~w",["吴泽森",abc]),
    ok.

%%
%% API Functions
%%
t_select_20()->
    SQL = "select id,username from ming2_cent.t_User",
    mod_mysql:select(SQL).

t_select_21()->
    SQL = {esql, {select, [id,username], {from, [{table,ming2_cent,t_User}]} }},
    mod_mysql:select(SQL).

t_insert_2()->
    SQL = {esql, {insert,{table,ming2_cent,t_wuzs}, [id,username],[[10,"zesen10"]] }},
    mod_mysql:update(SQL).

t_update_2()->
    SQL = {esql, {update, {table,ming2_cent,t_wuzs}, [{username,"zesen20"}],{where, "id=10"} }},
    mod_mysql:update(SQL).
     

t_delete_2()->
    SQL = {esql, {delete, {table,ming2_cent,t_wuzs}}},
    mod_mysql:update(SQL).


t_create()->
    SQL = "create table IF NOT EXISTS `t_log_login5` as select * from t_log_login2 where 1=2 limit 1",
    mod_mysql:update(SQL).
 

t2_w(Count)->
	SourceTab = ?DB_STALL_P,
	{Time, _Value} = timer:tc(testwdb, write_mnesia, [Count]),
	TabSize = mnesia:table_info(?DB_STALL_P,size),
	?INFO("Table=~w,Count=~w,TabSize=~p,write_mnesia cost ~w ms",[SourceTab,Count,TabSize,Time/1000]),
	ok.

t2_r()->
	SourceTab = ?DB_STALL_P,
	TabSize = mnesia:table_info(db_stall_p,size),
	{Time, _Value} = timer:tc(testwdb, load_mnesia, []),
	?INFO("Table=~w,TabSize=~p,load_mnesia cost ~w ms",[SourceTab,TabSize,Time/1000]),
	ok.


t3_w(Count)->
	SourceTab = r_stall,
	{Time, _Value} = timer:tc(testwdb, write_mysql, [Count]),
	TabSize = get_tab_totalCount(SourceTab),
	?INFO("Table=~w,Count=~w,TabSize=~p,write_mysql cost ~w ms",[SourceTab,Count,TabSize,Time/1000]),
	ok.

t3_r()->
	SourceTab = r_stall,
	TabSize = get_tab_totalCount(SourceTab),
%% 	{Time, _Value} = timer:tc(testwdb, load_mysql, []),
	{Time, _Value} = timer:tc(testwdb, load_mysql_2, []),
	?INFO("~nTable=~w,TabSize=~p,load_mysql cost ~w ms",[SourceTab,TabSize,Time/1000]),
	ok.

t3_index()->
	SourceTab = r_stall,
	TabSize = get_tab_totalCount(SourceTab),
	{Time, _} = timer:tc(mnesia, add_table_index, [db_stall, mapid]),
	?INFO("~nTable=~w,TabSize=~p,add_table_index mapid,scost ~w ms",[SourceTab,TabSize,Time/1000]),
	{Time2, _} = timer:tc(mnesia, add_table_index, [db_stall, mode]),
	?INFO("~nTable=~w,TabSize=~p,add_table_index mapid,scost ~w ms",[SourceTab,TabSize,Time2/1000]),
	ok.

get_tab_totalCount(SourceTab)->
	Sql = lists:concat( ["select 1,count(1) from ",SourceTab] ),
	{ok,[[1,TotalCount]]} = mod_mysql:select(Sql),
	TotalCount.

%% 一次性将全部数据加载到内存中，实际上不现实
load_mysql()->
	mnesia:clear_table(?DB_STALL),
    %%TODO 改为非事务
	ResultSet = mod_mysql:select( "select `role_id`, `start_time`, `mode`, `time_hour`, `remain_time`, `name`, `role_name`, `tx`, `ty`, `mapid` from r_stall" ),
	%%?INFO("~nResultSet=~p",[ResultSet]),
	{ok,DataList} = ResultSet,
	Records = [ map_record(r_stall,X) || X <- DataList],
	%%?INFO("~nRecords=~p",[Records]),
	%%[ ?INFO("~nis_record=~p",[is_record(R,r_stall)]) || R <- Records],
	
	[mnesia:dirty_write(?DB_STALL, R) || R <- Records],
	ok.

%% 一次性将全部数据加载到内存中，实际上不现实
load_mysql_2()->
	mnesia:clear_table(?DB_STALL),
    %%TODO 改为非事务
	PageSize =5000,
	{ok,[[1,TotalCount]]} = mod_mysql:select("select 1,count(1) from r_stall"),
	?INFO("~nTotalCount=~p",[TotalCount]),
	
	case is_integer(TotalCount) of
		true->
			do_load_mysql_paginated(0,PageSize,TotalCount);
		false->
			?INFO("~nError occur,TotalCount=~p",[TotalCount])
	end.

do_load_mysql_paginated(Start,PageSize,TotalCount) when ( TotalCount > Start)->
	
	Sql = lists:concat(["select `role_id`, `start_time`, `mode`, `time_hour`, `remain_time`, `name`, `role_name`, `tx`, `ty`, `mapid` from r_stall limit ", Start,",",PageSize ]),
	ResultSet = mod_mysql:select( Sql ),
	{ok,DataList} = ResultSet,
	Records = [ map_record(r_stall,X) || X <- DataList],
	[mnesia:dirty_write(?DB_STALL, R) || R <- Records],
	
	do_load_mysql_paginated(Start+PageSize,PageSize,TotalCount);
do_load_mysql_paginated(_Start,_PageSize,_TotalCount)->
	done.

map_record(r_stall,X)->
	Y = [r_stall|X],
	list_to_tuple(Y).
 
   

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
	
	