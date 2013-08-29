%% Author: Administrator
%% Created: 2012-5-21
%% Description: TODO: Add description to mod_egg_shop_test
-module(mod_rune_altar_test).

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
test_rune_draw() ->
	RoleID = get_one_online_role(),
	DataIn = #m_rune_altar_drawing_tos{draw_type=0},
	mgeer_role:absend(RoleID, {mod,mod_rune_altar,{1,?RUNE_ALTAR,?RUNE_ALTAR_DRAWING,DataIn,RoleID,pid,line}}).


%%
%% Local Functions
%%

get_one_online_role() ->
	[Online|_OnlineList] = mt_mnesia:show_table(db_user_online),
	#r_role_online{role_id=RoleID} = Online,
	RoleID.
   
