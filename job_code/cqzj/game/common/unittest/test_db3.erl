%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_db3).

%%
%% Include files
%%
%%
%% Include files
%%
 
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

t1(Code)->
    WhereExpr = io_lib:format("code='~s' ",[Code]),
    ?INFO("WhereExpr=~p",[WhereExpr]),
    Sql = mod_mysql:get_esql_select(t_activate_code,[role_id],WhereExpr) ,
    {ok,_R} = mod_mysql:select(Sql).

t_truncate()->
    Sql = "truncate table t_log_online ",
    {updated,_} = mod_mysql:update(Sql).

t_del()->
    SqlDelete = mod_mysql:get_esql_delete(t_item_list, [] ),
    {ok,_} = mod_mysql:update(SqlDelete).

%% 测试结果
%% test_db3:t_merge(20000).
%% Table=t_log_use_silver,Count=20000,TabSize=20000,test_seq_insert cost 5114.143 msok
t_merge(Count)->
    SourceTab = t_log_use_silver,
    {Time, _Value} = timer:tc(?MODULE, test_seq_merge, [Count]),
    TabSize = get_tab_totalCount(SourceTab),
    ?INFO("Table=~w,Count=~w,TabSize=~p,test_seq_insert cost ~w ms",[SourceTab,Count,TabSize,Time/1000]),
    ok.


%% 测试结果
%% test_db3:t_seq(20000).   
%% Table=t_log_use_silver,Count=20000,TabSize=40000,test_seq_insert cost 4397.437 msok
t_seq(Count)->
    SourceTab = t_log_use_silver,
    {Time, _Value} = timer:tc(?MODULE, test_seq_insert, [Count]),
    TabSize = get_tab_totalCount(SourceTab),
    ?INFO("Table=~w,Count=~w,TabSize=~p,test_seq_insert cost ~w ms",[SourceTab,Count,TabSize,Time/1000]),
    ok.

%% 测试结果
%%  test_db3:t_batch_insert(20000).
%% Table=t_log_use_silver,Count=20000,TabSize=60000,test_batch_insert cost 889.735 msok
t_batch_insert(Count)->
    SourceTab = t_log_use_silver,
    {Time, _Value} = timer:tc(?MODULE, test_batch_insert, [Count]),
    TabSize = get_tab_totalCount(SourceTab),
    ?INFO("Table=~w,Count=~w,TabSize=~p,test_batch_insert cost ~w ms",[SourceTab,Count,TabSize,Time/1000]),
    ok.

%% 测试结果
%%  test_db3:t_batch_replace(20000).
%% Table=t_log_use_silver,Count=20000,TabSize=60000,test_batch_insert cost 889.735 msok
t_batch_replace(Count)->
    SourceTab = t_log_use_silver,
    {Time, _Value} = timer:tc(?MODULE, test_batch_replace, [Count]),
    TabSize = get_tab_totalCount(SourceTab),
    ?INFO("Table=~w,Count=~w,TabSize=~p,t_batch_replace cost ~w ms",[SourceTab,Count,TabSize,Time/1000]),
    ok.



test_seq_merge(Count)->
    LogTime = common_tool:now(),
    MType = 1001,
    lists:foreach(fun(E)->
                          SQL = mod_mysql:get_esql_merge(t_log_use_silver,
                                                         [user_id, silver_bind, silver_unbind, mtime, mtype, mdetail, itemid, amount],
                                                         [E, 100, 200, LogTime, MType, "wuzesen test",0,0 ],
                                                         [{user_id,E},
                                                          {silver_bind,100},
                                                          {silver_unbind,200},
                                                          {mtime,LogTime},
                                                          {mtype,MType},
                                                          {mdetail,"wuzesen test"},
                                                          {itemid,0},
                                                          {amount,0}]) ,
                          {ok,_} = mod_mysql:insert(SQL)
                  end, lists:seq(1, Count)).


test_seq_insert(Count)->
    LogTime = common_tool:now(),
    MType = 1001,
    lists:foreach(fun(E)->
                          SQL = mod_mysql:get_esql_insert(t_log_use_silver,
                                                          [user_id, silver_bind, silver_unbind, mtime, mtype, mdetail, itemid, amount],
                                                          [E, 100, 200, LogTime, MType, "wuzesen test",0,0 ]
                                                         ), 
                          {ok,_} = mod_mysql:insert(SQL)
                  end, lists:seq(1, Count)).

test_batch_insert(Count)->
    LogTime = common_tool:now(),
    MType = 2001,
    
    FieldNames = [user_id, silver_bind, silver_unbind, mtime, mtype, mdetail, itemid, amount],
    BatchFieldValues = [ [E, 100, 200, LogTime, MType, "wuzesen test",0,0 ] || E <- lists:seq(1, Count) ],
    SQL = {esql, {insert,t_log_use_silver2, FieldNames,BatchFieldValues }},
    {ok,_} = mod_mysql:insert(SQL).

test_batch_replace(Count)->
    LogTime = common_tool:now(),
    MType = 2001,
    
    FieldNames = [user_id, silver_bind, silver_unbind, mtime, mtype, mdetail, itemid, amount],
    BatchFieldValues = [ [E, 100, 200, LogTime, MType, "wuzesen test",0,0 ] || E <- lists:seq(1, Count) ],
    SQL = {esql, {replace,t_log_use_silver2, FieldNames,BatchFieldValues }},
    {ok,_} = mod_mysql:insert(SQL).






%% test for db_friend_p
t_bag1(TestType)->
	
	case TestType of
		normal->
			%% select
%% 			db:load_whole_table(db_friend_p,db_friend),
			
			%% insert
			R1 = {r_friend,1676,111,1,17,undefined,{{2010,11,9},17},[]},
			db:dirty_write(db_friend, R1),
			R2 = {r_friend,1676,222,1,17,undefined,{{2010,11,9},17},[]},
			db:dirty_write(db_friend, R2),
			
			%% update
			R3 = {r_friend,1676,222,1,27,undefined,{{2010,22,29},27},[]},
			db:dirty_write(db_friend, R3);
		delete->
			%% delete
			R3 = {r_friend,1676,222,1,27,undefined,{{2010,22,29},27},[]},
			db:dirty_delete_object(db_friend, R3)
	end.

%% test for db_chat_role_channels_p
t_bag2(TestType)->
	case TestType of
		normal->
			%% select
%% 			db:load_whole_table(db_chat_role_channels_p,db_chat_role_channels),
			
			%% insert
			R1 = {r_chat_role_channel_info,111,"channel_level_channel_31_60_1",5},
			db:dirty_write(db_chat_role_channels, R1),
			R2 = {r_chat_role_channel_info,222,"channel_level_channel_31_60_1",5},
			db:dirty_write(db_chat_role_channels, R2),
			
			%% update
			R3 = {r_chat_role_channel_info,111,"channel_level_channel_31_60_1",5},
			db:dirty_write(db_chat_role_channels, R3);
		delete->
			%% delete
			R3 = {r_chat_role_channel_info,111,"channel_level_channel_31_60_1",5},
			db:dirty_delete_object(db_chat_role_channels, R3)
	end.


now2() ->
    {A, B, C} = erlang:now(),
    A * 1000000000 + B*1000 + C div 1000.

t_clean()->
	Tabs = [db_role_attr_p,db_role_base_p,db_role_faction_p],
	[ mnesia:clear_table(E) || E <- Tabs],
	Tabs2 = [db_role_attr,db_role_base,db_role_faction],
	[ mnesia:clear_table(E) || E <- Tabs2],

	ok.

db_size(DbTable)->
	{ok,[[1,TabSize]]} = mod_mysql:select( lists:concat(["select 1,count(1) from ",DbTable]) ),
	?INFO("~nNow=~w,TabSize=~w~n",[now2(),TabSize]),
	ok.
	

t_w()->
	Record = {r_role_faction,1,2},
	db:dirty_write(?DB_ROLE_FACTION, Record ),
	ok.

t_w2(Id)->
	Sql = mod_mysql:get_esql_insert(?DB_ROLE_FACTION_P,[faction_id, number],[Id,2]),
	mod_mysql:insert(Sql).

t_r()->
	DbTable = db_role_faction_p,
	{ok,[[1,TabSize]]} = mod_mysql:select( lists:concat(["select 1,count(1) from ",DbTable]) ),
	?INFO("~nNow=~w,TabSize=~w~n",[now2(),TabSize]),
	ok.

t_r2()->
	Sql = mod_mysql:get_esql_select(?DB_ROLE_FACTION_P,[1,'count(1)'],"1=1"),
	mod_mysql:select(Sql).



get_tab_totalCount(SourceTab)->
    Sql = lists:concat( ["select 1,count(1) from ",SourceTab] ),
    {ok,[[1,TotalCount]]} = mod_mysql:select(Sql),
    TotalCount.


