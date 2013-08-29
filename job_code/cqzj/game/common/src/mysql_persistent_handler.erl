%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     Mysql持久化的实现模块
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
%%	负责对MySQL DB的持久化处理
 
-module(mysql_persistent_handler).

%%
%% Include files
%%
-include("common.hrl").
-include("common_server.hrl").

%%
%% Exported Functions
%%
-export([dirty_delete/2,dirty_delete_object/3]).
-export([dirty_write/2]).
-export([dirty_write_batch/2,dirty_write_batch/3,dirty_write_batch/4]).
-export([dirty_insert/2,dirty_update/3]).

-define(PAGE_SIZE,10000).	%%	默认的分页的大小

%%
%% API Functions
%%

dirty_insert(DbTable, Record)-> 
	{ok,_R} = do_save_record(insert,DbTable,Record).

dirty_write_batch(DbTable, RecordList)-> 
    dirty_write_batch(DbTable, RecordList,300).

dirty_write_batch(DbTable, RecordList,MaxCountPerTime)-> 
    dirty_write_batch(DbTable, RecordList,MaxCountPerTime,5000).

dirty_write_batch(DbTable, RecordList,MaxCountPerTime,TimeOut)-> 
    FieldNames = mysql_persistent_util:get_fieldname_list(DbTable),
    BatchFieldValuesList = [ get_fields_value_list(DbTable, Rec) || Rec<-RecordList ],
    
    mod_mysql:batch_replace(DbTable,FieldNames,BatchFieldValuesList,MaxCountPerTime,TimeOut).

%% @doc dirty_write/2
%%      replace into 
dirty_write(DbTable, Record)-> 
    {ok,_R} = do_save_record(write,DbTable,Record).


dirty_update(set,DbTable, Record)-> 
	WhereExpr = do_get_whereexpr_for_keyrecord(DbTable,Record),
	{ok,_R} = do_save_record(update,DbTable,Record,WhereExpr);
dirty_update(bag,DbTable, Record)-> 
	WhereExpr = do_concat([ get_whereexpr(DbTable, Record)," limit 1"]),
	{ok,_R} = do_save_record(update,DbTable,Record,WhereExpr).


%% @doc dirty_delete record to mysql
dirty_delete(DbTable, KeyVal)-> 
	?DEBUG("dirty_delete,DbTable=~w,KeyVal=~w",[DbTable,KeyVal]),

	WhereExpr = do_get_whereexpr_for_key(DbTable,KeyVal),
	SqlDelete = mod_mysql:get_esql_delete(DbTable,WhereExpr),
    case mod_mysql:update(SqlDelete) of
        {ok,_R}->
            {ok,_R};
        Error->
            ?ERROR_MSG("Error=~w,Sql=~p",[Error,SqlDelete]),
            Error
    end.


%% @doc dirty_delete_object record to mysql
dirty_delete_object(set,DbTable, Record)->
	?DEBUG("dirty_delete_object,DbTable=~w,Record=~w",[DbTable,Record]),
	KeyVal = element(2,Record),
	dirty_delete(DbTable, KeyVal);
dirty_delete_object(bag,DbTable, Record)->
	?DEBUG("dirty_delete_object,DbTable=~w,Record=~w",[DbTable,Record]),
	WhereExpr = get_whereexpr(DbTable, Record),
	SqlDelete = mod_mysql:get_esql_delete(DbTable,WhereExpr),
    case mod_mysql:update(SqlDelete) of
        {ok,_R}->
            {ok,_R};
        Error->
            ?ERROR_MSG("Error=~w,Sql=~p",[Error,SqlDelete]),
            Error
    end.



%%
%% Local Functions
%%

do_get_whereexpr_for_keyrecord(DbTable,Record)->
	do_get_whereexpr_for_key(DbTable, element(2,Record) ).

do_get_whereexpr_for_key(DbTable,KeyVal)->
	StrKeyVal = common_mysql_misc:field_to_varchar( KeyVal ),
	{KeyName,KeyType} = mysql_persistent_util:get_key_tuple(DbTable),
	WhereExpr = case (KeyType==varchar) 
						 orelse  (KeyType==tuplechar) orelse (KeyType==binchar) of
					true-> do_concat(["`",KeyName,"`=\'",StrKeyVal,"\' limit 1"]);
					_ -> do_concat(["`",KeyName,"`=",StrKeyVal," limit 1"])
				end,
	WhereExpr.

do_concat(Things)->
	lists:concat(Things).

do_save_record(write,DbTable,Record)->
    FieldNames = mysql_persistent_util:get_fieldname_list(DbTable),
    FieldValues = get_fields_value_list(DbTable, Record),
    
    SqlUpdate = mod_mysql:get_esql_replace(DbTable, FieldNames,FieldValues ),
    mod_mysql:update(SqlUpdate);
do_save_record(insert,DbTable,Record)->
	FieldNames = mysql_persistent_util:get_fieldname_list(DbTable),
	FieldValues = get_fields_value_list(DbTable, Record),

    SqlUpdate = mod_mysql:get_esql_insert(DbTable, FieldNames,FieldValues ),
	mod_mysql:insert(SqlUpdate).
do_save_record(update,DbTable,Record,WhereExpr)->
	FieldTupleList = get_fields_tuple_list(DbTable, Record),
	SqlUpdate = mod_mysql:get_esql_update(DbTable, FieldTupleList,WhereExpr),
	
	mod_mysql:update(SqlUpdate).

%% @spec get_whereexpr/2
%% @doc 返回 类似" AKey=AVal and BKey=BVal "的语句
get_whereexpr(DbTable, Record)->
	case mysql_persistent_util:get_key_tuplelist(DbTable) of
		[]->
			AttrList = mysql_persistent_util:get_attributes(DbTable),
			[_H| FieldVals ] = tuple_to_list(Record);
		KeyTupleList ->
			AttrList = KeyTupleList,
			FieldVals = [ element(Idx+1,Record) || Idx <-mysql_persistent_util:get_keys_index(DbTable) ]
	end,
	
	do_get_whereexpr(AttrList,FieldVals,"").

do_get_whereexpr([],[],List)->
	List;
do_get_whereexpr([HAttr|FAttrs],[HVal|FVals],List) when length(List) =:= 0->
	HName = element(1,HAttr),
	L2 = case element(2,HAttr) of
			 varchar ->
				 lists:concat([ HName,"=\'",HVal,"\' "]);
			 tuplechar when is_tuple(HVal) ->
				 lists:concat([ HName,"=\'",common_mysql_misc:field_to_varchar(HVal),"\' "]);
			 binchar ->
				 lists:concat([ HName,"=\'",common_mysql_misc:field_to_varchar(HVal),"\' "]);
			 %%: may not support blob
			 _Other -> 
				 lists:concat([ HName,"=",HVal])
		 end,
	do_get_whereexpr(FAttrs,FVals,L2);
do_get_whereexpr([HAttr|FAttrs],[HVal|FVals],List) when length(List) > 0->
	HName = element(1,HAttr),
	L2 = case element(2,HAttr) of
			 varchar ->
				 lists:concat([List," and ",HName,"=\'",HVal,"\' "]);
			 tuplechar when is_tuple(HVal) ->
				 lists:concat([List," and ",HName,"=\'",common_mysql_misc:field_to_varchar(HVal),"\' "]);
			 binchar ->
				 lists:concat([List," and ",HName,"=\'",common_mysql_misc:field_to_varchar(HVal),"\' "]);
			 %%: may not support blob
			 _Other -> 
				 lists:concat([List," and ",HName,"=",HVal])
			 end,
do_get_whereexpr(FAttrs,FVals,L2).


%% @spec get_fields_value_list/2 -> List
%% @doc 返回 类似 [AVal,BVal]
get_fields_value_list(DbTable, Record)->
	FieldTypeList = mysql_persistent_util:get_fieldtype_list( DbTable ),
	[_H|FieldVals ] = tuple_to_list(Record),
	do_get_fields_value_list(FieldTypeList,FieldVals,[]).

do_get_fields_value_list([],[],List)->
	lists:reverse(List);
do_get_fields_value_list([HType|TTypes],[HVal|TVars],List)->
	%% 对binary,boolean,char,blob进行特殊处理
	L2 = case HType of
			 tinyblob->
				 [ undefined | List];
			 blob->
				 [ undefined | List];
			 tuplechar when is_tuple(HVal)->
				 [ common_mysql_misc:field_to_varchar(HVal)| List];
			 tinyint->
				 [ common_mysql_misc:to_tinyint(HVal) | List];
			 _ ->
				 [HVal | List]
		 end,
	do_get_fields_value_list(TTypes,TVars,L2).


%% @spec get_fields_tuple_list/2 -> TupleList
%% @doc 返回 类似 [{AKey,AVal},{BKey,BVal}]
get_fields_tuple_list(DbTable, Record)->
	Attributes = mysql_persistent_util:get_attributes(DbTable),
	[_H| FieldVals ] = tuple_to_list(Record),
	do_get_fields_tuple_list(Attributes,FieldVals,[]).

do_get_fields_tuple_list([],[],List)->
	lists:reverse(List);
do_get_fields_tuple_list([HAttr|TAttrs],[HVal|TVars],List)->
	HKey = element(1,HAttr),
	HType = element(2,HAttr),
	%% 对binary,boolean,blob进行特殊处理
	L2 = case HType of
			 tinyblob->
				 [{HKey,undefined} | List];
			 blob->
				 [{HKey,undefined} | List];
			 tuplechar->
				 [{HKey,common_mysql_misc:field_to_varchar(HVal)} | List];
			 tinyint->
				  [{HKey,common_mysql_misc:to_tinyint(HVal)} | List];
			 _ -> %% including varchar,binchar
				 [{HKey,HVal} | List]
		 end,
	do_get_fields_tuple_list(TAttrs,TVars,L2).
