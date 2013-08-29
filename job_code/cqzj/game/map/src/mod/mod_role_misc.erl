%% Author: xierongfeng
%% Created: 2012-11-16
%% Description: 玩家杂项数据
-module(mod_role_misc).

%%
%% Include files
%%
-include("mgeem.hrl").
-include("single_fb.hrl").

-define(_try_init(Init), 
		try 
			Module:Init(RoleID, lists:keyfind(RecTag, 1, Tuples)) 
		catch 
			T:E -> 
				?ERROR_MSG("严重问题:~p ~p ~p", [T, E, erlang:get_stacktrace()])
		end).

-define(_try_delete(Delete), 
		try 
			Rec = Module:Delete(RoleID),
			case is_record(Rec, RecTag) of
			true ->
				[Rec|Acc];
			false ->
				Acc
			end 
		catch 
			T:E -> 
				?ERROR_MSG("严重问题:~p ~p ~p", [T, E, erlang:get_stacktrace()]),
				Acc
		end).

%% CALLBACKS定义中的格式为{rec_tag, module}
%% module模块必须提供init/2和delete/1回调方法
%% init/2会在玩家进入地图时进行初始化的
%% delete/1要返回数据，并会在玩家离开地图或是某个时间调用来保存数据的
%% rec_tag为该模块对应的数据的record名称
-define(CALLBACKS, [
	{r_consume_task, mod_consume_task},
	{p_role_gems, mod_equip_gems},
	{r_role_hidden_examine_fb, mod_examine_fb},
	{r_role_worship, mod_role_worship},
	{r_role_jingjie, mod_role_jingjie},
	{r_role_juewei, mod_role_juewei},
	{r_role_family_misc, mod_map_family, init_role_family_misc, delete_role_family_misc},  
	{r_pet_da_dan, mod_pet_da_dan},
	{r_role_signin, mod_role_signin},
	{r_role_fashion, mod_role_fashion},
	{r_role_pet_hun, mod_pet_hun},
	{r_friend_visit, mod_friend, init_friend_visit, delete_friend_visit},
	{r_solo_fb, mod_solo_fb, put_fb_rec, del_fb_rec},
	{r_role_time_gift, mod_time_gift},
	{r_role_level_gift, mod_level_gift},
	{p_score, mod_score},
	{r_random_mission, mod_random_mission},
	{r_achievements, mod_achievement2}, 
	{r_role_mount, mod_role_mount},
	{r_qq_yvip, mod_yvip_activity},
	{r_daily_counter, mod_daily_counter},
	{r_pay_data, mod_activity},
	{r_activity_task, mod_daily_activity},
	{r_dingzi, mod_activity, init_dingzi, delete_dingzi},
	{r_money_fb, mod_money_fb, init_money_data, delete_money_data},
	{r_level_sale, mod_level_sale, init_sale, delete_sale},
    {r_qrhl, mod_qrhl},
    {r_open_server_activity,mod_open_activity},
    {r_role_share_invite, mod_share_invite},
	{r_role_killed_ybc, mod_ybc_person},
	{r_role_skill_time_tiyan, mod_skill_shape_tiyan},
	{r_guide_buy_mission, hook_guide_tip},
	{r_single_fb, mod_single_fb, role_misc_init, role_misc_delete},
	{r_times_counter, mod_counter, counter_init, counter_delete},
	{r_skill_ext, mod_skill_ext},
	{r_nuqi_huoling, mod_nuqi_huoling},
	{r_role_rune_altar, mod_rune_altar},
	{r_fulu, mod_fulu, init_fulu, delete_fulu},
	{r_rage_practice, mod_rage_practice, init_rage_practice, delete_rage_practice},
	{r_role_cd, mod_role_cd, init_role_cd, delete_role_cd}
]).

%%
%% Exported Functions
%%
-export([init/1, delete/1]).

%%
%% API Functions
%%
init(#r_role_misc{role_id=RoleID, tuples=Tuples}) ->
	lists:foreach(fun
		({RecTag, Module}) ->
			?_try_init(init);
		({RecTag, Module, Init, _Delete}) ->
			?_try_init(Init)
	end, ?CALLBACKS).

delete(RoleID) ->
	Tuples = lists:foldl(fun
		({RecTag, Module}, Acc) ->
		 	?_try_delete(delete);
		({RecTag, Module, _Init, Delete}, Acc) ->
		 	?_try_delete(Delete)
	end, [], ?CALLBACKS),
	#r_role_misc{role_id=RoleID, tuples=Tuples}.

%%
%% Local Functions
%%
