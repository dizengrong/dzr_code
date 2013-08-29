%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc 自动加载和卸载帐号/角色数据接口
%%%
%%% @end
%%% Created :  1 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(db_loader).

-include("common.hrl").
-include("common_server.hrl").

-define(DEF_RAM_TABLE(Type,Rec),
		[ {ram_copies, [node()]},
		  {type, Type},
		  {record_name, Rec},
		  {attributes, record_info(fields, Rec)}
		]).

-export([
		 load_role_table/1,
		 load_account_table/1,
		 load_login_whole_tables/0,
		 load_map_whole_tables/0,
		 load_world_whole_tables/0,
		 load_line_whole_tables/0,
		 load_chat_whole_tables/0,
		 init_line_tables/0,
		 init_map_tables/0,
		 init_login_tables/0,
		 init_world_tables/0,
		 init_chat_tables/0,
		 map_table_defines/0,
		 world_table_defines/0,
		 chat_table_defines/0,
		 login_table_defines/0
		]).

-define(TABLE_MAPPING(TabList),[ {get_ptab_name(Tab),Tab}|| Tab<- TabList ]).

load_login_whole_tables() ->
	[ do_add_tab_index(TabIndex)|| TabIndex <- login_table_indexs() ].

load_map_whole_tables() ->
	[ do_add_tab_index(TabIndex)|| TabIndex <- map_table_indexs() ].


load_world_whole_tables() ->
	[ do_add_tab_index(TabIndex)|| TabIndex <- world_table_indexs() ].

load_line_whole_tables() ->
	ok.

load_chat_whole_tables() ->
	[ do_add_tab_index(TabIndex)|| TabIndex <- chat_table_indexs() ].


%%帐号登录后初始化帐号相关表，例如fcm等等
load_account_table(_AccountName) -> 
	ok.

%%帐号登录后需要提前载入帐号下角色的所有相关数据，有些表是在init_whole_table中载入的
load_role_table(_AccountName) -> 
	ok.

init_chat_tables() ->
	lists:foreach(
	  fun({Tab, Definition}) ->
			  mnesia:create_table(Tab, Definition)
	  end,
	  chat_table_defines()
	),
	ok.


init_line_tables() ->
	lists:foreach(
	  fun({Tab, Definition}) ->
			  mnesia:create_table(Tab, Definition)
	  end,
	  line_table_defines()
	),
	ok.


init_map_tables() ->
	lists:foreach(
	  fun({Tab, Definition}) ->
			  mnesia:create_table(Tab, Definition)
	  end,
	  map_table_defines()
	),
	ok.


init_login_tables() ->
	lists:foreach(
	  fun({Tab, Definition}) ->
			  mnesia:create_table(Tab, Definition)
	  end,
	  login_table_defines()
	),
	ok.


init_world_tables() ->
	lists:foreach(
	  fun({Tab, Definition}) ->
			  mnesia:create_table(Tab, Definition)
	  end,
	  world_table_defines()
	),
	ok.


login_table_defines() ->
	[].

map_table_defines() -> 
	[
	 {?DB_MAP_ONLINE, ?DEF_RAM_TABLE(set,r_map_online)},
	 {?DB_BAG_SHOP,  ?DEF_RAM_TABLE(set, r_bag_shop)}
	].


world_table_defines() ->
	[
	 {?DB_FRIEND_REQUEST, 
	  [ {ram_copies, [node()]},
		{type, bag }, 
		{record_name, r_friend_request}, 
		{attributes, record_info(fields, r_friend_request)} ]},
	 {?DB_USER_ONLINE,
	  [ {ram_copies, [node()]}, 
		{type, set},
		{record_name, r_role_online}, 
		{attributes, record_info(fields, r_role_online)} ]}
	].

line_table_defines() ->
	[].

chat_table_defines() ->
	[
	].


%% @spec do_add_tab_index/1
%% @doc 对mnesia的内存表增加索引
do_add_tab_index(TabIndexDefine)->
	{Tab, [{index, IndexList} ]} = TabIndexDefine,
	[ db:add_table_index(Tab, AttrName) ||AttrName <- IndexList  ].

login_table_indexs() ->
	[].

map_table_indexs() ->
	[
	 {?DB_STALL_GOODS,
	  [{index, [role_id]} ]},
	 {?DB_STALL_GOODS_TMP,
	  [{index, [role_id]} ]},
	 {?DB_YBC_PERSON,
	  [ {index, [role_id]} ]}
	].


world_table_indexs() ->
	[
	 {?DB_STALL,
	  [ {index, [mapid, mode]} ]},
	 
	 {?DB_ROLE_BASE,
	  [ {index, [role_name, account_name, family_id]} ]},
	 
	 {?DB_BROADCAST_MESSAGE,
	  [ {index, [msg_type,expected_time,send_flag]}
	  ]},
	 %%私人信件表
	 {?DB_PERSONAL_LETTER_P,
	  [ {index, [sender_id,receiver_id]}]}
	].

chat_table_indexs() ->
	[].


