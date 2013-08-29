%% Author: dzr
%% Created: 2011-9-28
%% Description: TODO: Add description to pp_gm
-module(pp_gm).

%%=============================================================================
%% Include files
%%=============================================================================
-include("common.hrl").
%%=============================================================================
%% Exported Functions
%%=============================================================================
-export([handle/3]).

%% ============== GM command code ===============
%% 1:clear map process
%% 2:restore achieve award
%% 3:set player's vip level
%% 4:add bind silver
%% 5:add gold
%% 6:add bind gold
%% 7:add popularity
%% 8:add practice
%% 9:add silver
%% 10:add mercenary experience
%% 11:清除所有任务
%% 12:增加一个可雇佣的佣兵
%% 13：添加一个玩家可以进入的地图
%% 14：添加一个物品
%% 16：更改佣兵的属性
%% 17：即可完成该剧情地图的所有进度
%% 18：查看自己的所有佣兵id
%% 19:武器直接强化到指定级别
%% 20: 学习一个技能 
%% 21:清除1个任务
%% 22:从一个城镇地图移动到另一个城镇地图的某个位置
%% 23:增加精力
%% 24:完成任务，到指定ID为止
%% 25:重置所有任务
%% 26:设置所有登陆奖励
%% 27:设置
%% 29:设置跑商次数，掠夺次数，被掠夺次数
%% 30:设置竞技场名次
%% 42:设置爬塔当前层数
%% 43:增加血量

%% parameter:
%%		PlayerId: player_status record
%%		1:		gm command code
%%		the last is the gm command parameter list
%% return:
%%		{ok, NewStatus} if you updated data in Status

handle(PlayerId, 1, [RoleId, SkillModeIdList]) ->
	mod_gm:replace_role_skill(PlayerId, list_to_integer(RoleId), 
									util:string_to_term(SkillModeIdList));

handle(PlayerId, 2, [RoleId, SkillModeId]) ->
	mod_gm:delete_role_skill(PlayerId, 
						   list_to_integer(RoleId), 
						   list_to_integer(SkillModeId));

handle(PlayerId, 3, [VipLevel]) ->
	mod_gm:set_vip(PlayerId, list_to_integer(VipLevel));

handle(PlayerId, 4, [Num]) ->
	mod_gm:add_bind_silver(PlayerId, list_to_integer(Num));

handle(PlayerId, 5, [Num]) ->
	mod_gm:add_gold(PlayerId, list_to_integer(Num));

handle(PlayerId, 6, [Num]) ->
	mod_gm:add_bind_gold(PlayerId, list_to_integer(Num));

handle(PlayerId, 7, [Num]) ->
	mod_gm:add_popularity(PlayerId, list_to_integer(Num));

handle(PlayerId, 8, [Num]) ->
	mod_gm:add_practice(PlayerId, list_to_integer(Num));

handle(PlayerId, 9, [Num]) ->
	mod_gm:add_silver(PlayerId, list_to_integer(Num));

handle(PlayerId, 10, [MerId, Exp]) ->
	mod_gm:add_mer_exp(PlayerId, list_to_integer(MerId), list_to_integer(Exp));

handle(PlayerId, 11, [Num]) ->
 	mod_gm:clear_mission(PlayerId, list_to_integer(Num));

handle(PlayerId, 12, [MerId]) ->
	mod_gm:employ(PlayerId, list_to_integer(MerId));

handle(PlayerId, 13, [SceneId]) ->
	mod_gm:open_new_scene(PlayerId, list_to_integer(SceneId));

handle(PlayerId, 14, [CfgItemID, ItemNum]) ->
	mod_gm:add_item(PlayerId, list_to_integer(CfgItemID), list_to_integer(ItemNum));

handle(PlayerId, 15, [Name,Title,Content,Item_id,Item_num,Gold,Bind_gold,Silver]) ->
	?INFO(gm,"~w",[[Name,Title,Content,Item_id,Item_num]]),
	mod_gm:send_sys_mail(PlayerId,{Name,Title,Content,list_to_integer(Item_id),list_to_integer(Item_num),
		list_to_integer(Gold),list_to_integer(Bind_gold),list_to_integer(Silver)});

handle(PlayerId, 16, [MerId, Att, Hp]) ->
	mod_gm:change_mer_attri(PlayerId, list_to_integer(MerId), 
							list_to_integer(Att), list_to_integer(Hp));

handle(PlayerId, 17, [SceneId]) ->
	mod_gm:complete_story(PlayerId, list_to_integer(SceneId));

handle(PlayerId, 18, _) ->
	mod_gm:get_player_roles(PlayerId);


handle(PlayerId, 19, [HolyType, HolyLevel]) ->
	mod_gm:update_holy(PlayerId, list_to_integer(HolyType), list_to_integer(HolyLevel));

handle(PlayerId, 20, [MerId, Num]) ->
	mod_gm:learn_skill(PlayerId, list_to_integer(MerId), list_to_integer(Num));

handle(PlayerId, 21, [Task_id]) ->
	mod_gm:clear_single_mission(PlayerId, list_to_integer(Task_id));

handle(PlayerId, 22, [DestScene, X, Y]) ->
	mod_gm:go_to(PlayerId, list_to_integer(DestScene), list_to_integer(X), list_to_integer(Y));

handle(PlayerId, 22, [DestScene]) ->
	mod_gm:go_to(PlayerId, list_to_integer(DestScene));
	
handle(PlayerId, 23, [Added]) ->
	mod_gm:add_energy(PlayerId, list_to_integer(Added));

handle(PlayerId, 24, [TaskId]) ->
	mod_gm:complete_missions_until(PlayerId, list_to_integer(TaskId));

handle(PlayerId, 25, _) ->
	mod_gm:reset_missions(PlayerId);

handle(PlayerId, 26, [Days]) ->
	mod_gm:set_all_login_award(PlayerId, list_to_integer(Days));

handle(_PlayerId, 27, []) ->
	mod_gm:check_bulletin();

handle(PlayerId, 29, [Tag, SNum]) ->
	Num = list_to_integer(SNum),
	if (Num =< 1) -> ok;
		true ->
			case Tag of
				"grab"    -> mod_gm:set_grab_max(PlayerId, Num);
				"grabbed" -> mod_gm:set_grabbed_max(PlayerId, Num);
				"rb"      -> mod_gm:set_rb_max(PlayerId, Num)
			end
	end;

handle(PlayerId, 30, [Rank]) ->
	mod_gm:set_arena_rank(PlayerId,list_to_integer(Rank));

handle(_PlayerId, 31, [Register, Fight, Stop]) ->
	try
		R = list_to_integer(Register),
		F = list_to_integer(Fight),
		S = list_to_integer(Stop),
	
		if (F =< R orelse S =< F) ->
			ok;
		true ->
			mod_gm:set_boss(R, F, S)
		end
	catch _:_ ->
		ok
	end;

handle(PlayerId, 32, _NoUse) ->
	mod_gm:switch_guild_comp_state(PlayerId);

handle(PlayerId, 33, [ApplyTime, ArenaTime]) ->
	mod_gm:begin_online_arena(PlayerId, list_to_integer(ApplyTime), list_to_integer(ArenaTime));

handle(PlayerId, 34, []) ->
	mod_gm:rerest_pick_star_data(PlayerId);

handle(PlayerId, 35, [Num]) ->
	mod_gm:add_wakan(PlayerId, list_to_integer(Num));

handle(PlayerId, 36, _NoUse) ->
    mod_gm:tattoo_gamble_always_win(PlayerId);

handle(PlayerId, 37, _NoUse) ->
    mod_gm:reset_tattoo_gamble_times(PlayerId);

handle(PlayerId, 38, [MonsterGroupId]) ->
    mod_gm:gm_battle(PlayerId, list_to_integer(MonsterGroupId));    

handle(_PlayerId, 39, _NoUse) ->
    mod_gm:refresh_rankings();

handle(_PlayerId, 40, _NoUse) ->
    mod_gm:flush_memcache();

handle(PlayerId, 41, [Nickname]) ->
    mod_gm:grap_a_slave(PlayerId, Nickname);

handle(PlayerId,42,[CurrentLevel]) ->
	Level = list_to_integer(CurrentLevel),
	mod_gm:set_tower_level(PlayerId,Level);

handle(PlayerId,43,[RoleId,HpAdd]) ->
	mod_gm:add_hp(PlayerId,list_to_integer(RoleId),list_to_integer(HpAdd));

handle(PlayerId, 44, [])->
	mod_gm:open_boss_scene();

handle(PlayerId, 45, [])->
	mod_gm:set_boss_alive();

handle(_PlayerId,Code, Para) ->
	?INFO(gm,"gm handle faile for wrong command: code = ~w, parameter = ~w", [Code, Para]).











