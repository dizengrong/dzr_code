%% Author: dzr
%% Created: 2011-9-28
%% Description: TODO: Add description to mod_gm
-module(mod_gm).

%%=============================================================================
%% Include files
%%=============================================================================
-include("common.hrl").
%%=============================================================================
%% Exported Functions
%%=============================================================================

-compile(export_all).
%%=============================================================================
%% API Functions
%%=============================================================================
replace_role_skill(PlayerId, RoleId, SkillModeIdList) ->
	mod_role:gm_replace_role_skill(PlayerId, RoleId, SkillModeIdList).

delete_role_skill(PlayerId, RoleId, SkillModeId) ->
	case mod_role:delete_role_skill(PlayerId, RoleId, SkillModeId) of
		true ->
			mod_chat:send_to_self(PlayerId, "delete skill successfully!");
		{false, Msg} ->
			mod_chat:send_to_self(PlayerId, io_lib:format("delete skill failed: ~s", [Msg]))
	end.

get_player_roles(PlayerId) ->
	RoleIdList = mod_role:get_employed_id_list(PlayerId),
	Fun = fun(RoleId, Msg) ->
		RoleRec = data_role:get(RoleId),
		string:concat(Msg, io_lib:format("  ~s: ~w", [RoleRec#role.gd_name, RoleId]))
	end,
	Message = lists:foldl(Fun, "", RoleIdList),
	mod_chat:send_to_self(PlayerId, Message).

set_vip(PlayerId, VipLevel) ->
	{ok, EconomyRec} = mod_economy:get(PlayerId),
	Gold = EconomyRec#economy.gd_gold,
	ChargeGold = if
		VipLevel == 1 -> 
			case Gold =< 100 of
				true -> 100 - Gold;
				false -> 0
			end;
		VipLevel == 2 -> 
			case Gold =< 5000 of
				true -> 5000 - Gold;
				false -> 0
			end;
		VipLevel == 3 -> 
			case Gold =< 20000 of
				true -> 20000 - Gold;
				false -> 0
			end;
		VipLevel == 4 -> 
			case Gold =< 50000 of
				true -> 50000 - Gold;
				false -> 0
			end;
		VipLevel == 5 -> 
			case Gold =< 10000 of
				true -> 10000 - Gold;
				false -> 0
			end;
		VipLevel == 6 -> 
			case Gold =< 250000 of
				true -> 250000 - Gold;
				false -> 0
			end;
		VipLevel == 7 -> 
			case Gold =< 250001 of
				true -> 250005;
				false -> 0
			end;
		true ->
			0
	end,
	mod_vip:charge_gold(PlayerId, ChargeGold).



add_bind_silver(PlayerId, Num) ->
	mod_economy:add_silver(PlayerId, Num, 0).

add_silver(PlayerId, Num) ->
	mod_economy:add_silver(PlayerId, Num, 0).

add_gold(PlayerId, Num) ->
	mod_economy:add_gold(PlayerId, Num, 0).

add_bind_gold(PlayerId, Num) ->
	mod_economy:add_bind_gold(PlayerId, Num, 0).

add_popularity(PlayerId, Num) ->
	mod_economy:add_popularity(PlayerId, Num, 0).


%%清除所有任务
clear_mission(_PlayerId, _Type)->
	?ERR(gm, "not implemented").

add_practice(PlayerId, Num) ->
	mod_economy:add_practice(PlayerId, Num, 0).

add_mer_exp(PlayerId, MerId, Exp) ->
	mod_role:add_exp(PlayerId, {MerId, Exp}, 0).

employ(PlayerId, MerId) ->
	mod_role:client_employ(PlayerId, MerId).

open_new_scene(PlayerId, SceneId) ->
	scene:open_new_scene(PlayerId, SceneId).

add_item(PlayerId, CfgItemID, ItemNum) ->
	ItemList = [{CfgItemID, ItemNum, 1}],
	mod_items:createItems(PlayerId, ItemList, ?ITEM_FROM_GM).

change_mer_attri(PlayerId, MerId, Att, Hp) ->
	mod_role:gm_change_attri(PlayerId, MerId, Att, Hp).


complete_story(_PlayerId, _SceneId) ->
	?ERR(gm, "not implemented").

update_holy(_PlayerId, _HolyType, _HolyLevel) ->
	?ERR(gm, "not implemented").

learn_skill(_PlayerId, _MerId, _Num) ->
	?ERR(gm, "not implemented").

go_to(PlayerId, SceneId, X, Y) -> 
	scene:go_to(PlayerId, SceneId, X, Y).

go_to(PlayerId, SceneId) -> 
	{X, Y} = data_scene:get_default_xy(SceneId),
	scene:go_to(PlayerId, SceneId, X, Y).

add_energy(_PlayerId, _Added) ->
	?ERR(gm, "not implemented").

set_all_login_award(_PlayerId, _Days) ->
	?ERR(gm, "not implemented").

switch_guild_comp_state(_Status) ->
	?ERR(gm, "not implemented").

begin_online_arena(_PlayerId, _ApplyTime, _ArenaTime) ->
	?ERR(gm, "not implemented").

rerest_pick_star_data(_PlayerId) ->
	?ERR(gm, "not implemented").

%% 增加Num数量的灵力
add_wakan(_PlayerId, _Num) ->
	?ERR(gm, "not implemented").

tattoo_gamble_always_win(_PlayerId) ->
   ?ERR(gm, "not implemented").

reset_tattoo_gamble_times(_PlayerId) ->
   ?ERR(gm, "not implemented").

gm_battle(_PlayerId, _MonsterGroupId) ->
	?ERR(gm, "not implemented").

refresh_rankings() ->
   ?ERR(gm, "not implemented").

flush_memcache() ->
    cache_util:save_all_right_now().

grap_a_slave(PlayerId, Nickname) -> 
	case mod_fengdi:gm_grap_a_slave(PlayerId, Nickname) of
		true ->
			mod_chat:send_to_self(PlayerId, "add slave successfully");
		{false, Msg} ->
			mod_chat:send_to_self(PlayerId, io_lib:format("add slave failed: ~s", [Msg]))
	end.

set_tower_level(PlayerId,CurrentLevel) ->
	mod_marstower:gm_set_level(PlayerId,CurrentLevel).

add_hp(PlayerId,RoleId,HpAdd) ->
	mod_role:add_hp(PlayerId,RoleId,HpAdd,?HP_ADD_FROM_GM).

%%=============================================================================
%% FOR server
%%=============================================================================
%% delete a account
delete_account(Id) ->
	Sql1 = io_lib:format(<<"delete from gd_account where gd_account.gd_AccountID = ~w">>, [Id]),
	Sql2 = io_lib:format(<<"delete from gd_accountotherinfo where gd_accountotherinfo.gd_AccountID = ~w">>, [Id]),
	Sql3 = io_lib:format(<<"delete from gd_role where gd_role.gd_AccountID = ~w">>, [Id]),
	Sql4 = io_lib:format(<<"delete from gd_worlditem where gd_worlditem.gd_AccountID = ~w">>, [Id]),
	Sql5 = io_lib:format(<<"delete from gd_storyprocess where gd_storyprocess.gd_AccountID = ~w">>, [Id]),
	Sql6 = io_lib:format(<<"delete from gd_accountachievement where gd_accountachievement.gd_AccountID = ~w">>, [Id]),
	Sql7 = io_lib:format(<<"delete from gd_guildmember where gd_guildmember.gd_roleid = ~w">>, [Id]),
	Sql8 = io_lib:format(<<"delete from gd_accounttaskinfo where gd_accounttaskinfo.ID = ~w">>, [Id]),
	Sql9 = io_lib:format(<<"delete from gd_accountcd where gd_accountcd.gd_AccountID = ~w">>, [Id]),
	Sql10 = io_lib:format(<<"delete from gd_accountholy where gd_accountholy.gd_AccountID = ~w">>, [Id]),
	Sql11 = io_lib:format(<<"delete from gd_accountalchemy where gd_accountalchemy.gd_AccountID = ~w">>, [Id]),
	Sql12 = io_lib:format(<<"delete from gd_accountolaward where gd_accountolaward.gd_AccountID = ~w">>, [Id]),
	mod_db_server:execute_batch(Id, [
								   Sql1,
								   Sql2,
								   Sql3,
								   Sql4,
								   Sql5,
								   Sql6,
								   Sql7,
								   Sql8,
								   Sql9,
								   Sql10,
								   Sql11,
								   Sql12]).

delete_all_account() ->
	Sql1 = <<"delete from gd_account ">>,
	Sql2 = <<"delete from gd_accountotherinfo">>,
	Sql3 = <<"delete from gd_role">>,
	Sql4 = <<"delete from gd_worlditem">>,
	Sql5 = <<"delete from gd_storyprocess">>,
	Sql6 = <<"delete from gd_accountachievement">>,
	Sql7 = "delete from gd_guildmember",
	Sql8 = "delete from gd_accounttaskinfo",
	Sql9 = "delete from gd_accountcd",
	Sql10 = "delete from gd_accountholy",
	Sql11 = "delete from gd_accountalchemy",
	Sql12 = "delete from gd_accountolaward",
	db_sql:execute(Sql1),
	db_sql:execute(Sql2),
	db_sql:execute(Sql3),
	db_sql:execute(Sql4),
	db_sql:execute(Sql5),
	db_sql:execute(Sql6),
	db_sql:execute(Sql7),
	db_sql:execute(Sql8),
	db_sql:execute(Sql9),
	db_sql:execute(Sql10),
	db_sql:execute(Sql11),
	db_sql:execute(Sql12).

send_sys_mail(_Status,{_Name,_Title,_Content,_Item_id,_Item_num,_Gold,_Bind_gold,_Silver})->
	?ERR(gm, "not implemented").

clear_single_mission(_PlayerId, _Task_id)->
	?ERR(gm, "not implemented").
	
complete_missions_until(PlayerId, TaskId) ->
    PS = mod_player:get_player_status(PlayerId),
    gen_callback_server:do_async(
        PS#player_status.task_pid,
        {gm_complete_task_until, TaskId}
    ).

reset_missions(PlayerId) ->
    PS = mod_player:get_player_status(PlayerId),
    gen_callback_server:do_async(
        PS#player_status.task_pid,
        gm_reset_tasks
    ).

check_bulletin() ->
	?ERR(gm, "not implemented").

%=======================================================================
% gm command for run business
%=======================================================================

set_grab_max(_PlayerId, _Num) ->
	?ERR(gm, "not implemented").

set_grabbed_max(_PlayerId, _Num) ->
	?ERR(gm, "not implemented").

set_rb_max(_PlayerId, _Num) ->
	?ERR(gm, "not implemented").

set_boss(_Register, _Fight, _Stop) ->
	?ERR(gm, "not implemented").
	
set_arena_rank(_PlayerId,_Rank)->
	?ERR(gm, "not implemented").

open_boss_scene()->
	BossRegister = register,
	case get(BossRegister) of
		undefined -> 
			g_boss:broadcast_battle_register();
		Ref -> 
			timer:cancel(Ref),
			g_boss:broadcast_battle_register()
	end,
	timer:apply_after(300000, g_boss, broadcast_battle_begin, []).

set_boss_alive()->
	BossFight = fight,
	case get(BossFight) of
		undefined -> 
			g_boss:broadcast_battle_begin();
		Ref -> 
			timer:cancel(Ref),
			g_boss:broadcast_battle_begin()
	end.
