%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     mysql_persistent的辅助工具模块
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mysql_persistent_util).



%%
%% Include files
%%
-include("common.hrl").
-include("common_server.hrl").

%%
%% Exported Functions
%%
-export([generate_sql_create_table/1]).
-export([generate_sql_create_table/2]).
-export([get_key_tuplelist/1]).
-export([get_keys_index/1]).
-export([get_tab_type/1,get_record_name/1,get_attributes/1,get_key_tuple/1]).
-export([get_fieldtype_list/1,get_fieldname_list/1]).
-export([get_mysql_field_names/1]).

%%
%% API Functions
%%

%% @spec get_keys_index/1 -> list()
get_keys_index(Tab)->
    case do_get_tab_property(Tab,keys_index) of
        undefined-> [];
        Keys -> Keys
    end.

%% @spec get_key_tuple/1 -> Key::{KeyName,KeyType}
get_key_tuple(Tab) when is_atom(Tab)->
    case get_attributes(Tab) of
        undefined-> undefined;
        [ Attr|_OtherFields ]-> 
            { element(1,Attr),element(2,Attr) }
    end.	

%% @spec get_key_tuplelist/1 -> KeyTupleList::[{KeyName,KeyType}]
get_key_tuplelist(Tab) when is_atom(Tab)->
    case do_get_tab_property(Tab,keys) of
        undefined-> [];
        Keys ->
            Attributes = get_attributes(Tab),
            [ do_get_key_tuple_forbag(Attributes,K) ||K<-Keys ]
    end.

do_get_key_tuple_forbag(Attributes,Key)->
    Attr = lists:keyfind(Key, 1, Attributes),
    { element(1,Attr),element(2,Attr) }.



%% @spec get_record_name/1 -> Name::atom()
get_record_name(Tab) when is_atom(Tab)->
    do_get_tab_property(Tab,record_name).

%% @spec get_tab_type/1 -> Type::atom()
get_tab_type(Tab) when is_atom(Tab)->
    do_get_tab_property(Tab,type).

%% @spec get_attributes/1 -> Attributes::list()
get_attributes(Tab) when is_atom(Tab)->
    do_get_tab_property(Tab,attributes).


%% @doc 返回指定表的字段名称列表，例如[id,name,age]
get_fieldname_list(Tab) when is_atom(Tab)->
    case get_attributes(Tab) of
        undefined-> undefined;
        Fields->
            [ element(1,F) || F <- Fields]
    end.


%% @doc 返回指定表的字段类型列表，例如[int,varchar,int,blob]
get_fieldtype_list( Tab ) when is_atom(Tab)->
    case get_attributes(Tab) of
        undefined-> undefined;
        Fields->
            [ element(2,F) || F <- Fields ]
    end.

%%@doc 返回表的所有字段构成的字符串，类似 "`name`,`id`"
get_mysql_field_names(Tab) when is_atom(Tab)->
    FieldNames = get_fieldname_list(Tab),
    do_get_mysql_key_fields( FieldNames ).



%% @doc 产生创建Table的SQL文件
generate_sql_create_table(SqlFilePath)->
    generate_sql_create_table(SqlFilePath, no_drop).

generate_sql_create_table(SqlFilePath, Option)->
    TabNameList = mysql_persistent_config:tables(),
    file:delete( SqlFilePath ),    
    lists:foreach(fun(TabName)-> 
                          TabDef = mysql_persistent_config:table_define(TabName),
                          do_gensql_create_table(SqlFilePath, TabName,TabDef,Option)
                  end, TabNameList),
    io:format("generate_sql_create_table: ~p",[SqlFilePath]),
    ok.

%%
%% Local Functions
%%

do_concat(Things) ->
    lists:concat(Things).

do_gensql_create_table(SqlFilePath, TabName,TabDef,GenOption) when is_atom(TabName),is_list(TabDef)->
    {type,Type} = lists:keyfind(type, 1, TabDef),
    {attributes,Fields} = lists:keyfind(attributes, 1, TabDef),	
    HeadComment = case GenOption of
                      drop->
                          do_concat(["\n-- ----------------------------\n-- Table structure for `",
                                     TabName,
                                     "`\n-- ----------------------------",
                                     "\nDROP TABLE IF EXISTS `",
                                     TabName
                                     ,"`;"]);
                      _ ->
                          do_concat(["\n-- ----------------------------\n-- Table structure for `",
                                     TabName,
                                     "`\n-- ----------------------------",
                                     "\n"])
                  end,

    FirstLine = do_concat([HeadComment,"\nCREATE TABLE IF NOT EXISTS `", TabName ,"` ("]),
    EndLine = "\n) ENGINE=InnoDB DEFAULT CHARSET=utf8;\n",
    Sql4Fields = do_concat( [ do_make_mysql_fields(F) ||F <- Fields] ),
    Sql4PrimaryKey = case Type of
                         set -> 
                             case lists:keyfind(keys, 1, TabDef) of
                                 {keys,[SetKey]}->
                                     ok;
                                 _ ->
                                     SetKey = element(1, hd(Fields))
                             end,
                             do_concat( [Sql4Fields, "\n  PRIMARY KEY  (`", SetKey ,"`)" ] );
                         bag ->
                             {keys,Keys} = lists:keyfind(keys, 1, TabDef),
                             case length(Keys) of
                                 0->
                                     Length = length(Sql4Fields),
                                     string:substr(Sql4Fields, 1,Length-1);
                                 _ ->
                                     KeyFields = do_get_mysql_key_fields(Keys),
                                     do_concat( [Sql4Fields, "\n  PRIMARY KEY  (", KeyFields ,")" ] )
                             end
                     end,
    Sql = do_concat([FirstLine,Sql4PrimaryKey,EndLine]),
    Bytes = Sql,
    file:write_file( SqlFilePath, list_to_binary(Bytes),[append] ).

%%@doc 返回类似 "`name`,`id`"
do_get_mysql_key_fields(Keys)->
    Fromat = lists:concat( lists:duplicate(length(Keys), "`~w`,") ),
    Sql = io_lib:format( Fromat, Keys),
    string:substr(Sql, 1,length(Sql)-1).

do_make_mysql_fields(Field)->
    case Field of
        {FName,FType} ->
            do_concat([ "\n  `", FName ,"` ", FType ," default NULL," ]);
        {FName,FType,FLength} ->
            RealSqlType =  case FType of
                               binchar-> varchar;
                               tuplechar->varchar;
                               _ -> FType
                           end,
            do_concat([ "\n  `", FName ,"` ", RealSqlType ,"(", FLength ,") default NULL," ])
    end.

do_get_tab_property(Tab,Property) when is_atom(Tab)->
    case mysql_persistent_config:table_define(Tab) of
        false->
            undefined;
        TabProps->
            {Property,Val} = lists:keyfind(Property, 1, TabProps),
            Val
    end.

