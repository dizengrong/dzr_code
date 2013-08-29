-module (cfg_hero_fb).
-compile(export_all).

%% 零散数据

<?py for data in hero_misc: ?>
%% ${data[2]}
get_misc(${data[0]}) -> ${data[1]};
<?py #endfor ?>
get_misc(_) -> [].


%% 用元宝进行翻牌的价格设定
<?py for data in select_money: ?>

<?py if data[2] == 0: ?>
<?py 	can_sel = 'false' ?>
<?py else: ?>
<?py 	 can_sel = 'true' ?>
<?py #endif ?>
select_money(Barrier) when Barrier >= ${data[0]} andalso Barrier =< ${data[1]} -> {${can_sel}, [${data[3]}, ${data[4]}, ${data[5]}, ${data[6]}, ${data[7]}]};
<?py #endfor ?>
select_money(_) -> {false, []}.


%% 基础奖励配置
<?py for data in basic_reward: ?>
basic_reward(Barrier, ${data[0]}) when Barrier >= ${data[1]} andalso Barrier =< ${data[2]} -> 
	${data[3]};

<?py #endfor ?>
basic_reward(_, _) -> [].

%% 各种模式的第一关
%% 根据r_hero_fb_barrier_info记录中的last_barrier_id=0来判断
<?py for data in barrier_info: ?>
<?py if data[3] == 0: ?>
get_first_barrier_id(${data[0]}) -> ${data[1]};
<?py #endif ?>
<?py #endfor ?>
get_first_barrier_id(ModeType) -> throw({hero_fb_mode_type_not_supported, ModeType}).


%% 各关卡的配置

-record(r_hero_fb_barrier_info, {
	barrier_id, 					%% barrier 关卡序号
	map_id, 						%% 地图ID
	last_barrier_id,				%% 上一关卡ID
	next_barrier_id, 				%% 下一关卡ID
	barrier,						%% 章节
	barrier_name,					%% 关卡名称
	fight_times,					%% 可挑战的次数
	jingjie,						%% 境界
	open_lv,						%% 进入等级要求
	can_gold_fetch     = false,		%% 是否可以元宝翻牌
	expect_time,					%% 期望的时间分参数
	expect_power,					%% 期望的战力分参数
	expect_stone,					%% 期望的宝石分参数
	reward_exp         = 0,			%% 奖励经验
	reward_prestige    = 0, 			%% 奖励的声望
	reward_silver      = 0, 			%% 奖励的银币
	reward_items       = [],			%% 奖励的物品[{物品id, 数量, 物品类型(1,2,3), 是否绑定}...]
	first_battle_items = [],        %% 第一次通关的奖励
	spec_prop_weight,				%% 下面两个目前不需要
	spec_prop_list     = []
}).

<?py for data in barrier_info: ?>

<?py if data[8] == 0: ?>
<?py 	fetch = 'false' ?>
<?py else: ?>
<?py 	 fetch = 'true' ?>
<?py #endif ?>
barrier_info(${data[0]}, ${data[1]}) -> 
	#r_hero_fb_barrier_info{
		barrier_id         = ${data[1]},
		map_id             = ${data[2]},
		last_barrier_id    = ${data[3]},
		next_barrier_id    = ${data[4]},
		barrier            = ${data[5]},
		barrier_name       = "${data[16]}",
		fight_times        = ${data[6]},
		jingjie            = ${data[7]},
		open_lv            = ${data[17]},
		can_gold_fetch     = ${fetch},
		expect_time        = ${data[9]},
		expect_power       = ${data[10]},
		expect_stone       = ${data[11]},
		reward_exp         = ${data[12]},
		reward_prestige    = ${data[13]},
		reward_silver      = ${data[14]},
		reward_items       = ${data[15]},
		first_battle_items = ${data[18]}
};
<?py #endfor ?>
barrier_info(_, _) -> [].


%% 境界副本的辅助怪物列表
<?py for data in assist_monster: ?>
assist_monster(${data[0]}) -> ${data[1]};
<?py #endfor ?>
assist_monster(_) -> [].


%% 对于做任务时进入神兽副本不算次数
<?py for data in do_mission: ?>
do_mission(${data[0]}, ${data[1]}) -> ${data[2]};
<?py #endfor ?>
do_mission(_, _) -> [].


%% 副本地图列表

<?py for data in barrier_info: ?>
is_hero_fb_map_id(${data[2]}) -> true;
<?py #endfor ?>
is_hero_fb_map_id(_) -> false.
