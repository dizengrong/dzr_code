%% Author: Administrator
%% Created: 2012-5-21
%% Description: TODO: Add description to mod_egg_shop_test
-module(mod_egg_shop_test).

%%
%% Include files
%%
-compile(export_all).
-include("common.hrl").

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%
%%{Unique, Module, Method, _DataIn, RoleID, PID, _Line, _State}
test_egg_use() ->
	RoleID = get_one_online_role(),
	DataIn = #m_egg_use_tos{goods_id=11600021},
	common_misc:send_to_rolemap(RoleID, {mod_egg_shop, {1,?EGG,?EGG_USE,DataIn,RoleID,pid,line,state}}).

test_open_shop() ->
	RoleID = get_one_online_role(),
	DataIn = #m_egg_open_shop_tos{},
	common_misc:send_to_rolemap(RoleID, {mod_egg_shop, {1,?EGG,?EGG_OPEN_SHOP,DataIn,RoleID,pid,line,state}}).

test_refresh_shop() ->
	RoleID = get_one_online_role(),
	DataIn = #m_egg_refresh_shop_tos{},
	common_misc:send_to_rolemap(RoleID, {mod_egg_shop, {1,?EGG,?EGG_REFRESH_SHOP,DataIn,RoleID,pid,line,state}}).

test_buy() ->
	RoleID = get_one_online_role(),
	DataIn = #m_egg_shop_buy_tos{typeid=11600019,num=1,bind=true},
	common_misc:send_to_rolemap(RoleID, {mod_egg_shop, {1,?EGG,?EGG_SHOP_BUY,DataIn,RoleID,pid,line,state}}).

%%
%% Local Functions
%%

get_one_online_role() ->
	[Online|_OnlineList] = mt_mnesia:show_table(db_user_online),
	#r_role_online{role_id=RoleID} = Online,
	RoleID.
   
