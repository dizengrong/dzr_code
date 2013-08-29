%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @doc 数据库操作抽象层
%%% Created : 2010-07-14
%%%-------------------------------------------------------------------
-module(db).

%% API
-export([
         is_using_mysql_persistent/0, 
         is_using_mysql_backup/0
        ]).

-export([
         abort/1, transaction/1, transaction/2, transaction/3,
	 async_dirty/1, async_dirty/2,
	 activity/2, activity/3,
	 is_transaction/0,

	 %% Access within an activity - Lock acquisition
	 lock/2, 
	 read_lock_table/1, 
	 write_lock_table/1,

	 %% Access within an activity - Updates
	 write/1, write/3,
	 delete/1, delete/3,
	 delete_object/1,delete_object/3,
     
     delete_sure/1,delete_object_sure/1,
     delete_sure/3,delete_object_sure/3,

     read/1, read/2, wread/1, read/3,
	 match_object/1, match_object/3, 
	 select/1,select/2,select/3,select/4,
	 all_keys/1,
	 index_match_object/2, index_match_object/4,
	 index_read/3,
	 first/1, next/2, last/1, prev/2,
	 first/3, next/4, last/3, prev/4,

         %% Iterators within an activity 
	 foldl/3, foldr/3,
	 
	 %% Dirty access regardless of activities - Updates
	 dirty_write/1, dirty_write/2,
	 dirty_delete/1, dirty_delete/2,
	 dirty_delete_object/1, dirty_delete_object/2,
	 dirty_update_counter/2, dirty_update_counter/3,

	 %% Dirty access regardless of activities - Read
	 dirty_read/1, dirty_read/2,
	 dirty_select/2,
	 dirty_match_object/1, dirty_match_object/2, dirty_all_keys/1,
	 dirty_index_match_object/2, dirty_index_match_object/3,
	 dirty_index_read/3, dirty_slot/2, 
	 dirty_first/1, dirty_next/2, dirty_last/1, dirty_prev/2, 

	 %% Info
	 table_info/2, schema/0, schema/1,
	 error_description/1, info/0, system_info/1,
	 system_info/0,                      % Not for public use

	 %% Database mgt
	 create_schema/1, delete_schema/1,
	 backup/2,
	 install_fallback/1, install_fallback/2,
	 uninstall_fallback/0, uninstall_fallback/1,
	 activate_checkpoint/1, deactivate_checkpoint/1,
	 backup_checkpoint/2, backup_checkpoint/3, restore/2,

	 %% Table mgt
	 create_table/2, delete_table/1,
	 add_table_copy/3, del_table_copy/2, move_table_copy/3,
	 add_table_index/2, del_table_index/2,
	 transform_table/3, transform_table/4,
	 change_table_copy_type/3,
	 clear_table/1,

	 %% Table load
	 dump_tables/1, wait_for_tables/2, force_load_table/1,
	 set_master_nodes/1, set_master_nodes/2,
	 
	 %% Misc admin
	 dump_log/0, subscribe/1, unsubscribe/1, report_event/1,

	 %% Snmp
	 snmp_open_table/2, snmp_close_table/1,
	 snmp_get_row/2, snmp_get_next_index/2, snmp_get_mnesia_key/2,

	 %% Textfile access
	 load_textfile/1, dump_to_textfile/1,

         s_delete/1,s_delete_object/1, s_write/1, set_debug_level/1, 

         start/0, stop/0,
	 
	 %% QLC functions
	 table/1, table/2
        ]).

-define(DB_PUSH_TRANSACTION_DICT_KEY, db_push_transaction_dict_key).

-define(DB_PUSH_WRITE_DICT_KEY, db_push_write_dict_key).

-define(DB_PUSH_DELETE_DICT_KEY, db_push_delete_dict_key).

-define(DB_PUSH_DELETE_OBJECT_DICT_KEY, db_push_delete_object_dict_key).

-define(db_local_cache_server, db_local_cache_server).

%% DB层的配置开关
-define(IS_USING_MYSQL_PERSISTENT, false).
-define(IS_USING_MYSQL_BACKUP, true).


-include("common_server.hrl").

is_using_mysql_persistent()->
	?IS_USING_MYSQL_PERSISTENT.

is_using_mysql_backup()->
	?IS_USING_MYSQL_BACKUP.
	

abort(Reason) ->
    mnesia:abort(Reason).

activate_checkpoint(Args) -> 
    mnesia:activate_checkpoint(Args).

deactivate_checkpoint(Name) -> 
    mnesia:deactivate_checkpoint(Name).

activity(Kind, Fun) ->
    mnesia:activity(Kind, Fun).
activity(Kind, Fun, Mod) ->
    mnesia:activity(Kind, Fun, Mod).

add_table_copy(Tab, Node, Type) ->
    mnesia:add_table_copy(Tab, Node, Type).

add_table_index(Tab, AttrName) ->
    mnesia:add_table_index(Tab, AttrName).


async_dirty(Fun) ->
    mnesia:async_dirty(Fun).

async_dirty(Fun, Args) ->
    mnesia:async_dirty(Fun, Args).

all_keys(Tab) ->
    mnesia:all_keys(Tab).

backup(Opaque, Mod) ->
    mnesia:backup(Opaque, Mod).

backup_checkpoint(Name, Opaque, Mod) ->
    mnesia:backup_checkpoint(Name, Opaque, Mod).

backup_checkpoint(Name, Opaque) ->
    mnesia:backup_checkpoint(Name, Opaque).

restore(Opaque, Args) ->
    mnesia:restore(Opaque, Args).

change_table_copy_type(Tab, Node, To) ->
    mnesia:change_table_copy_type(Tab, Node, To).


clear_table(Tab) ->
    mnesia:clear_table(Tab).

create_schema(DiscNodes) ->
    mnesia:create_schema(DiscNodes).

create_table(Name, TabDef) ->
    mnesia:create_table(Name, TabDef).

delete_sure({Tab, Key}) ->
    delete_sure(Tab, Key, write).

%%@doc 确认删除成功，否则抛出异常
delete_sure(Tab, Key, LockKind) ->
    case mnesia:read(Tab,Key) of
        []->
            db:abort(key_not_found);
        _ ->
            db:delete(Tab, Key, LockKind)
    end.

delete_object_sure(Record) ->
    Tab = erlang:element(1, Record),
    delete_object_sure(Tab, Record, write).

%%@doc 确认删除成功，否则抛出异常
delete_object_sure(Tab, Record, LockKind) ->
    case db:match_object(Tab, Record, write) of
        []->
            db:abort(object_not_found);
        _->
            db:delete_object(Tab, Record, LockKind)
    end.

delete({Tab, Key}) ->
    mnesia:delete({Tab, Key}).

delete(Tab, Key, LockKind) ->
    mnesia:delete(Tab, Key, LockKind).

delete_object(Record) ->
    mnesia:delete_object(Record).

delete_object(Tab, Record, LockKind) ->
    mnesia:delete_object(Tab, Record, LockKind).

delete_table(Tab) ->
    mnesia:delete_table(Tab).

del_table_copy(Tab, N) ->
    mnesia:del_table_copy(Tab, N).

del_table_index(Tab, Ix) ->
    mnesia:del_table_index(Tab, Ix).

dirty_all_keys(Tab) ->
    mnesia:dirty_all_keys(Tab).

dirty_delete({Tab, Key}) ->
    mnesia:dirty_delete({Tab, Key}).

dirty_delete(Tab, Key) ->
    mnesia:dirty_delete(Tab, Key).

dirty_delete_object(Record) ->
    mnesia:dirty_delete_object(Record).

dirty_delete_object(Tab, Record) ->
    mnesia:dirty_delete_object(Tab, Record).


dirty_first(Tab) ->
    mnesia:dirty_first(Tab).

dirty_index_match_object(Pattern, Pos) ->
    mnesia:dirty_index_match_object(Pattern, Pos).

dirty_index_match_object(Tab, Pattern, Pos) ->
    mnesia:dirty_index_match_object(Tab, Pattern, Pos).

dirty_index_read(Tab, SecondaryKey, Pos) ->
    mnesia:dirty_index_read(Tab, SecondaryKey, Pos).

dirty_last(Tab) ->
    mnesia:dirty_last(Tab).

dirty_match_object(Pattern) ->
    mnesia:dirty_match_object(Pattern).

dirty_match_object(Tab, Pattern) ->
    mnesia:dirty_match_object(Tab, Pattern).

dirty_next(Tab, Key) ->
    mnesia:dirty_next(Tab, Key).

dirty_prev(Tab, Key) ->
    mnesia:dirty_prev(Tab, Key).

dirty_read({Tab, Key}) ->
    db:dirty_read(Tab, Key).

dirty_read(Tab, Key) ->
    mnesia:dirty_read(Tab, Key).

dirty_select(Tab, MatchSpec) ->
    mnesia:dirty_select(Tab, MatchSpec).

dirty_slot(Tab, Slot) ->
    mnesia:dirty_slot(Tab, Slot).

dirty_update_counter({Tab, Key}, Incr) ->
    mnesia:dirty_update_counter({Tab, Key}, Incr).

dirty_update_counter(Tab, Key, Incr) ->
    mnesia:dirty_update_counter(Tab, Key, Incr).

dirty_write(Record) ->
    mnesia:dirty_write(Record).

dirty_write(Tab, Record) ->
    mnesia:dirty_write(Tab, Record).

dump_log() ->
    mnesia:dump_log().

dump_tables(TabList) ->
    mnesia:dump_tables(TabList).

dump_to_textfile(Filename) ->
    mnesia:dump_to_textfile(Filename).

error_description(Error) ->
    mnesia:error_description(Error).

first(Tab) ->
    mnesia:first(Tab).

first(Tid, Ts, Tab) ->
    mnesia:first(Tid, Ts, Tab).

foldl(Function, Acc, Table) ->
    mnesia:foldl(Function, Acc, Table).

foldr(Function, Acc, Table) ->
    mnesia:foldr(Function, Acc, Table).

force_load_table(Tab) ->
    mnesia:force_load_table(Tab).

index_match_object(Pattern, Pos) ->
    mnesia:index_match_object(Pattern, Pos).

index_match_object(Tab, Pattern, Pos, LockKind) ->
    mnesia:index_match_object(Tab, Pattern, Pos, LockKind).

index_read(Tab, SecondaryKey, Pos) ->
    mnesia:index_read(Tab, SecondaryKey, Pos).

info() ->
    mnesia:info().

install_fallback(Opaque) ->
    mnesia:install_fallback(Opaque).

install_fallback(Opaque, BackupMod) ->
    mnesia:install_fallback(Opaque, BackupMod).


is_transaction()  ->
    mnesia:is_transaction().

last(Tab) ->
    mnesia:last(Tab).

last(Tid, Ts, Tab) ->
    mnesia:last(Tid, Ts, Tab).

load_textfile(Filename) ->
    mnesia:load_textfile(Filename).

lock(LockItem, LockKind) ->
    mnesia:lock(LockItem, LockKind).

next(Tab,Key) ->
    mnesia:next(Tab,Key).

next(Tid,Ts,Tab,Key) ->
    mnesia:next(Tid,Ts,Tab,Key).

prev(Tab,Key) ->
    mnesia:prev(Tab,Key).

prev(Tid,Ts,Tab,Key) ->
    mnesia:prev(Tid,Ts,Tab,Key).


match_object(Pattern) ->
    mnesia:match_object(Pattern).

match_object(Tab, Pattern, LockKind) ->
    mnesia:match_object(Tab, Pattern, LockKind).

move_table_copy(Tab, From, To) ->
    mnesia:move_table_copy(Tab, From, To).

read({Tab, Key}) ->
    db:read(Tab, Key).

read(Tab, Key) ->
    mnesia:read(Tab, Key).

read(Tab, Key, LockKind) ->
    mnesia:read(Tab, Key, LockKind).

read_lock_table(Tab) ->
    mnesia:read_lock_table(Tab).

report_event(Event) ->
    mnesia:report_event(Event).

s_delete({Tab, Key}) ->
    mnesia:s_delete({Tab, Key}).

s_delete_object(Record) ->
    mnesia:s_delete_object(Record).

s_write(Record) ->
    mnesia:s_write(Record).

schema() ->
    mnesia:schema().

schema(Tab) ->
    mnesia:schema(Tab).

select(Tab, MatchSpec) ->
    mnesia:select(Tab, MatchSpec).

select(Tab, MatchSpec, Lock) ->
    mnesia:select(Tab, MatchSpec, Lock).

select(Tab, MatchSpec, NObjects, Lock) ->
    mnesia:select(Tab, MatchSpec, NObjects, Lock).

select(Cont) ->
    mnesia:select(Cont).

set_debug_level(Level) ->
    mnesia:set_debug_level(Level).

set_master_nodes(MasterNodes) ->
    mnesia:set_master_nodes(MasterNodes).

set_master_nodes(Tab, MasterNodes) ->
    mnesia:set_master_nodes(Tab, MasterNodes).

snmp_close_table(Tab) ->
    mnesia:snmp_close_table(Tab).

snmp_get_mnesia_key(Tab, RowIndex) ->
    mnesia:snmp_get_mnesia_key(Tab, RowIndex).

snmp_get_next_index(Tab, RowIndex) ->
    mnesia:snmp_get_next_index(Tab, RowIndex).

snmp_get_row(Tab, RowIndex) ->
    mnesia:snmp_get_row(Tab, RowIndex).

snmp_open_table(Tab, SnmpStruct) ->
    mnesia:snmp_open_table(Tab, SnmpStruct).

start() ->
    mnesia:start().

stop() ->
    mnesia:stop().

subscribe(EventCategory) ->
    mnesia:subscribe(EventCategory).

system_info(InfoKey) ->
    mnesia:system_info(InfoKey).

table(Tab) ->
    mnesia:table(Tab).


table(Tab, Option) ->
    mnesia:table(Tab, Option).

table_info(Tab, InfoKey) ->
    mnesia:table_info(Tab, InfoKey).

transaction(Fun) ->
	common_bag2:on_transaction_begin(),
	common_role:on_transaction_begin(),
	common_mission:on_transaction_begin(),
	common_consume_logger:on_transaction_begin(),
	common_prestige_logger:on_transaction_begin(),
	common_pet:on_transaction_begin(),
	case mnesia:transaction(Fun) of
		{atomic, Result} ->
			common_bag2:on_transaction_commit(),
			common_role:on_transaction_commit(),
			common_mission:on_transaction_commit(),
			common_consume_logger:on_transaction_commit(),
			common_prestige_logger:on_transaction_commit(),
			common_pet:on_transaction_commit(),
			{atomic, Result};
		{aborted, Error} ->
			common_bag2:on_transaction_rollback(),
			common_role:on_transaction_rollback(),
			common_mission:on_transaction_rollback(),
			common_consume_logger:on_transaction_rollback(),
			common_prestige_logger:on_transaction_rollback(),
			common_pet:on_transaction_rollback(),
			{aborted, Error}
	end.


transaction(Fun, Retries) ->
    case mnesia:transaction(Fun, Retries) of
        {atomic, Result} ->
            {atomic, Result};
        {aborted, Error} ->
            {aborted, Error}
    end.                          

transaction(Fun, Args, Retries) ->
    case mnesia:transaction(Fun, Args, Retries) of
        {atomic, Result} ->
            {atomic, Result};
        {aborted, Error} ->
            {aborted, Error}
    end.


transform_table(Tab, Fun, NewAttributeList, NewRecordName) ->
    mnesia:transform_table(Tab, Fun, NewAttributeList, NewRecordName).

transform_table(Tab, Fun, NewAttributeList) ->
    mnesia:transform_table(Tab, Fun, NewAttributeList).

uninstall_fallback() ->
    mnesia:uninstall_fallback().

uninstall_fallback(Args) ->
    mnesia:uninstall_fallback(Args).

unsubscribe(EventCategory) ->
    mnesia:unsubscribe(EventCategory).

wait_for_tables(TabList,Timeout) ->
    mnesia:wait_for_tables(TabList,Timeout).

wread({Tab, Key}) ->
    mnesia:wread({Tab, Key}).

write(Record) ->
    mnesia:write(Record).

write(Tab, Record, LockKind) ->
    mnesia:write(Tab, Record, LockKind).

write_lock_table(Tab) ->
    mnesia:write_lock_table(Tab).

system_info() ->
    mnesia:system_info().

delete_schema(DiscNodes) ->
    mnesia:delete_schema(DiscNodes).

%% ---------------------------------------------------------------------------------------- %%

%%local function

