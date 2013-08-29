%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_mysql_persistent_handler).

%%
%% Include files
%%
-include("common.hrl").

%%
%% Exported Functions
%%
-export([]).
-compile(export_all).


%%
%% Macros
%%
-define( TESTMOD,mysql_persistent_handler ).
-define( DEBUG(F,D),io:format(F, D) ).
-define(ERLYDB_OPTIONS,[{pool_id, mysql_connect_pool_id},
						{allow_unsafe_statements, true},
						{skip_fk_checks, true}, debug_info,
						{outdir, "../ebin/"}]).


%% test for db_friend_p
t_bag1(TestType)->
	
	case TestType of
		normal->
			%% insert
			R1 = {r_friend,1676,111,1,17,undefined,{{2010,11,9},17},[]},
			mysql_persistent_handler:dirty_insert(db_friend_p, R1),
			R2 = {r_friend,1676,222,1,17,undefined,{{2010,11,9},17},[]},
			mysql_persistent_handler:dirty_insert(db_friend_p, R2),
			
			%% update
			R3 = {r_friend,1676,222,1,27,undefined,{{2010,22,29},27},[]},
			mysql_persistent_handler:dirty_update(bag,db_friend_p, R3),
			
			%% select
			mysql_persistent_handler:load_whole_table(db_friend_p,db_friend);
		delete->
			%% delete
			R3 = {r_friend,1676,222,1,27,undefined,{{2010,22,29},27},[]},
			mysql_persistent_handler:dirty_delete_object(bag,db_friend_p, R3),
			
			mysql_persistent_handler:load_whole_table(db_friend_p,db_friend)
	end.

%% test for db_chat_role_channels_p
t_bag2(TestType)->
	case TestType of
		normal->
			%% insert
			R1 = {r_chat_role_channel_info,111,"channel_level_channel_31_60_1",5},
			mysql_persistent_handler:dirty_insert(db_chat_role_channels_p, R1),
			R2 = {r_chat_role_channel_info,222,"channel_level_channel_31_60_1",5},
			mysql_persistent_handler:dirty_insert(db_chat_role_channels_p, R2),
			
			%% update
			R3 = {r_chat_role_channel_info,111,"channel_level_channel_31_60_1",5},
			mysql_persistent_handler:dirty_update(bag,db_chat_role_channels_p, R3);
		delete->
			%% delete
			R3 = {r_chat_role_channel_info,111,"channel_level_channel_31_60_1",5},
			mysql_persistent_handler:dirty_delete_object(bag,db_chat_role_channels_p, R3),
			
			%% select
			mysql_persistent_handler:load_whole_table(db_chat_role_channels_p,db_chat_role_channels)
	end.

t_tuplechar(T)->
	case (T==i) orelse (T==a) of
		true->
			Record = {r_role_bag,{4,6},[],undefined,undefined,6,7},
			A = mysql_persistent_handler:dirty_insert(db_role_bag_p,Record);
		_ -> A = 0
	end,
	case (T==u) orelse (T==a) of
		true->
			Record2 = {r_role_bag,{4,6},[],undefined,undefined,8,9},
			B = mysql_persistent_handler:dirty_update(db_role_bag_p,Record2);
		_ -> B = 0
	end,
	
	{A,B}.


t_varchar(T)->
	case (T==i) orelse (T==a) of
		true->
			Record = {r_key_process,"broadcast_server_6001",
					  'mgeeg_6001@www.ming2game-debug.com'},
			A = mysql_persistent_handler:dirty_insert(db_key_process,Record);
		_ -> A = 0
	end,
	case (T==u) orelse (T==a) of
		true->
			Record2 = {r_key_process,"broadcast_server_6001",
					   'abc'},
			B = mysql_persistent_handler:dirty_update(db_key_process,Record2);
		_ -> B = 0
	end,
	
	{A,B}.

t_binchar(T)->
	case (T==i) orelse (T==a) of
		true->
			Record = {r_account,<<"wuzesen">>,1,2,3},
			A = mysql_persistent_handler:dirty_insert(db_account_p,Record);
		_ -> A = 0
	end,
	case (T==u) orelse (T==a) of
		true->
			Record2 = {r_account,<<"wuzesen">>,4,5,6},
			B = mysql_persistent_handler:dirty_update(db_account_p,Record2);
		_ -> B = 0
	end,
	
	{A,B}.


test_init_data()->
	Seconds = common_tool:now(),
	
	SQL = " insert into `t_log_use_gold` ( `user_id`, `user_name`, `account_name`, `gold_bind`, `gold_unbind`, `mtime`, `mtype`, `mdetail`, `item_id`, `item_amount`) values "
			  ++ io_lib:format("(  ~w, '~s', '~s', ~w, ~w, ~w, ~w, '~s', ~w, ~w)",
							   [ 1,
								 "wuzesen",
								 "acct_wuzesen",
								 10,
								 20,
								 Seconds,
								 4001,
								 "test gold",
								 0,
								 0
							   ]),
	mod_mysql:insert(SQL).

test_api()->
	
	test_dirty_write(),
	test_load_whole_table(),
	test_dirty_delete(),
	test_dirty_delete_object(),
	
	ok.

test_load_whole_table()->
	
	DbTable =  db_role_attr_p,
	TargetTable =  db_role_attr,
	?TESTMOD:load_whole_table(DbTable, TargetTable).

test_dw_bin()->
	Record={r_account,<<97,105,115,111,110,48,49>>,1288920477,undefined,undefined},
	DbTable = db_account_p,
	?TESTMOD:dirty_write(DbTable, Record).

test_dirty_write()->
	DbTable = db_account_p,
	Record = {r_account,"wuzesen1",1298472222,1},
	?TESTMOD:dirty_write(DbTable, Record),
	Record2 = {r_account,"wuzesen2",1298473333,1},
	?TESTMOD:dirty_write(DbTable, Record2).

test_dirty_write2()->
    DbTable = db_account_p,
    ?TESTMOD:dirty_delete(DbTable, "wuzesen1"),
    ?TESTMOD:dirty_delete(DbTable, "wuzesen2"),
    Record1 = {r_account,"wuzesen1",1298472222,1},
    ?TESTMOD:dirty_write(DbTable, Record1),
    Record2 = {r_account,"wuzesen1",1298473333,1},
    ?TESTMOD:dirty_write(DbTable, Record2),
    Record3 = {r_account,"wuzesen1",1298474444,1},
    ?TESTMOD:dirty_write(DbTable, Record3),
    Record4 = {r_account,"wuzesen2",1298475555,1},
    ?TESTMOD:dirty_write(DbTable, Record4).

test_dirty_delete()->
	DbTable = db_account_p,
	KeyVal = "wuzesen1",
	?TESTMOD:dirty_delete(DbTable, KeyVal).

test_dirty_delete_object()->
	DbTable = db_ban_user_p,
	Record2 = {r_ban_user,"wuzesen2",2,3},
	?TESTMOD:dirty_delete_object(DbTable, Record2).
 


%% insert statement sample
t_i()->
	Statement={esql,{insert,tvoyage_sailor,
                               [total_tasks,week_tasks,pirate_score,level,
                                family_id,nickname,user_id],
                               [[1,1,4,3,2,"aa",1]]}},
	erlydb_mysql:update(Statement,?ERLYDB_OPTIONS).


%% update statement sample
t_u()->
	Statement = {esql,
				 {update, tvoyage_sailor, 
				  [{total_tasks,20},
				   {week_tasks,19},
				   {pirate_score,18},
				   {level,17},
				   {family_id,16}], {user_id,'=',1}
				 }},
	erlydb_mysql:update(Statement,?ERLYDB_OPTIONS).


t_s()->
	Q = {select, [id,user_id], {from, [t_log_use_gold]},
		 {where, " `id`=1 limit 1"}},
	Statement={esql,Q},
%% 	erlydb_mysql:select(Statement,?ERLYDB_OPTIONS).
	mod_mysql:select(Statement).

t_sql()->
	mysql_persistent_util:generate_sql_create_table(),
	ok.

