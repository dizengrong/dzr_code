%% 检验副本（t6中叫战纪副本）的等级打卡关卡的配置数据

-module (cfg_examine_fb).
-compile(export_all).

%% 玩家等级开启的关卡id的列表
<?py examine_fb_open_barriers[0][1] = eval(examine_fb_open_barriers[0][1]) ?>
get_open_barriers(${examine_fb_open_barriers[0][0]}) -> ${examine_fb_open_barriers[0][1]};
<?py for i in range(1, len(examine_fb_open_barriers)): ?>
<?py examine_fb_open_barriers[i][1] = examine_fb_open_barriers[i - 1][1] + eval(examine_fb_open_barriers[i][1]) ?>
get_open_barriers(${examine_fb_open_barriers[i][0]}) -> ${examine_fb_open_barriers[i][1]};
<?py #endfor ?>
get_open_barriers(_) -> [].


%% 检验副本翻牌的元宝: get_selected_gold(次数) -> 需要的元宝
<?py for data in examine_fb_selected_gold: ?>
get_selected_gold(${data[0]}) -> ${data[1]};
<?py #endfor ?>
get_selected_gold(_) -> 100.


<?py def get_rule_id_quality(rule_id, _values):?>
<?py	for data in _values: ?>
<?py		if data[0] == rule_id: ?>
<?py			return data[4] ?>
<?py #endif ?>
<?py #endfor ?>
<?py #enddef ?>

%% 各关卡牌的权重: get_weights(关卡id) -> [{奖励索引id, 权重值}]
<?py for data in examine_fb_selected_rule: ?>
<?py ruleIdList = eval(data[2]) ?>
<?py s = "[" ?>
<?py for id in ruleIdList: ?>
<?py s = s + "{" + str(id) + ", " + str(get_rule_id_quality(id, examine_fb_selected_item)) + "}," ?>
<?py #endfor ?>
<?py s = s[:-1] ?>
<?py s = s + "]" ?>
get_weights(Id) when Id >= ${data[0]} andalso Id =< ${data[1]} -> ${s};
<?py #endfor ?>
get_weights(_Id) -> [{1,1}].


%% 各关卡的奖励
%% get_reward(Id, 奖励索引id) when Id == 关卡id -> {物品id, 数量, 物品类型, 是否绑定}
<?py for data in examine_fb_selected_item: ?>
<?py item_type = int(data[1]) // 10000000 ?>
<?py if data[3] == 0: ?>
<?py 	is_bind = 'false' ?>
<?py else: ?>
<?py 	 is_bind = 'true' ?>
<?py #endif ?>
get_reward(${data[0]}) -> {${data[1]}, ${data[2]}, ${item_type}, ${is_bind}};
<?py #endfor ?>
get_reward(_) -> {13000005, 1, 1, true}.


%% 所有的章节
<?py all_ids = [d[0] for d in all_barrier_ids] ?>
all_big_barriers() -> ${all_ids}.

%% 章节id的列表
<?py for data in all_barrier_ids: ?>
all_barriers(${data[0]}) -> ${data[1]};
<?py #endfor ?>
all_barriers(_) -> [].

%% 章节满星奖励
<?py for data in full_star_awards: ?>
<?py item_type = int(data[1]) // 10000000 ?>
full_star_award(${data[0]}) -> [{${data[1]}, ${data[2]}, ${item_type}, ${is_bind}}];
<?py #endfor ?>
full_star_award(_) -> [].


%% 关卡配置
%%  关卡的配置数据（检验副本的）
-record(r_barrier_conf, {
        id                = 0,      %% 关卡id
        can_fetch         = true,   %% 是否可以翻牌
        can_gold_fetch    = true,   %% 是否可以使用金币翻牌
        %% 有关关卡评分的
        score_time_param  = 0,      %% 期望的时间分参数
        score_power_param = 0,      %% 期望的战力分参数 
        score_stone_param = 0,      %% 期望的宝石分参数
        %% 有关过关奖励的
        reward_exp        = 0,      %% 奖励的经验 
        reward_prestige   = 0,      %% 奖励的声望
        reward_silver     = 0,      %% 奖励的银币
        reward_yueli      = 0,      %% 奖励的阅历
        reward_items      = []      %% 奖励的物品[{物品id, 数量, 物品类型(1,2,3), 是否绑定}]
    }).
<?py for data in examine_fb_barrier_conf: ?>
get_barrier_conf(${data[0]}) -> #r_barrier_conf{id = ${data[0]}, score_time_param = ${data[5]}, score_power_param =${data[6]}, reward_yueli = ${data[10]}  , reward_exp =${data[7]}, reward_prestige = ${data[8]}, reward_silver = ${data[9]}, reward_items = ${data[11]}};
<?py #endfor ?>
get_barrier_conf(_) -> undefined.


<?py for data in examine_fb_misc: ?>
%% ${data[2]}
get_misc(${data[0]}) -> ${data[1]};
<?py #endfor ?>
get_misc(_) -> undefined.

<?py all_maps = [] ?>
<?py for data in examine_fb_barrier_conf: ?>
<?py all_maps.append(data[3]) ?>
<?py #endfor ?>

<?py for data in {}.fromkeys(all_maps).keys(): ?>
is_examine_fb_map_id(${data}) -> true;
<?py #endfor ?>
is_examine_fb_map_id(_) -> false.


%%根据VIP等级限制每天每大关最大重置次数,元宝
%%关卡ID是101时：大关关卡ID为1，关卡ID是201时：大关关卡ID为2，以此类推
%%get_reset_max_times(VIP等级) -> [{大关关卡, 小关卡最大重置次数, 每重置的元宝, 免费重置次数}]}
<?py for data in examine_fb_reset: ?>
get_reset_max_times(${data[0]}) -> ${data[1]};
<?py #endfor ?>
get_reset_max_times(_) -> undefined.


%% 副本的关卡配置
%% barrier_id 关卡ID
%% next_barrierid 下一关关卡ID
%% min_enter_level  每关关卡最低进入等级
%% enter_max_time 进入当前关的免费次数
%% map_id 地图ID
%%monster_list 怪物列表
%%reward_exp 奖励经验
%% need_equip_level : {slot_num, min_level }需要的时装,座骑的强化等级
%% need_xfire : 指定拥有某个法宝
%% xiangqian_num :总共需要吞丹药N颗才可进入关卡（丹药系统）；
%% xiangqian_by_type :根据物品类型ID共有丹药N颗才可进入关卡
%%pet_aptitude_upgrade:异兽的资质 达到某个值（ 例如50）即可进入某个副本
%%pet_period_upgrade:异兽的阶位 达到XX阶（例如2阶）即可进入某个副本
%%skill_upgrade:7个小星宿，任何一个星宿强化到XX级（例如3级 ）即可进入副本
%%life_star_upgrade:	星宿系统达到本命星XX级（例如2级）即可进入副本
%%equip_typeids:%%拥有某个装备
-record(r_examine_fb_barrier_conf, {
		barrier_id,						%% 关卡ID
		next_barrierid, 				%% 下一关关卡ID
		min_enter_level      =0,		%% 每关关卡最低进入等级(这个也不用配置了)
		enter_max_time		 =5,		%% 进入当前关的免费次数
		map_id, 						%% 地图ID
		monster_list         =[],		%% 怪物列表
		reward_exp           =0,		%% 奖励经验(这个经验不用配)
		need_equip_level     =0, 		%% 下面的不用配置，保留默认值
		pet_aptitude_upgrade =0,
		pet_period_upgrade   =0,
		skill_upgrade        =0,
		life_star_upgrade    =0,
		equip_typeids        =0
}).
<?py for data in examine_fb_barrier_conf: ?>
get_examine_conf(${data[0]}) -> #r_examine_fb_barrier_conf{barrier_id = ${data[0]}, next_barrierid = ${data[1]}, enter_max_time = ${data[2]}, map_id = ${data[3]}, monster_list = ${data[4]}};
<?py #endfor ?>
get_examine_conf(Id) -> throw({error, 4, {Id}}).


%% 普通关卡对应要开启的隐藏副本id
%%（对应普通副本有隐藏副本的就在下面加, 隐藏副本开启隐藏副本也可以在下面加）
%% get_open_hidden_barriers(普通关卡id) -> [隐藏关卡id]
<?py for data in examine_fb_hidden_open: ?>
get_open_hidden_barriers(${data[0]}) -> ${data[1]};
<?py #endfor ?>
get_open_hidden_barriers(_) -> [].
 

%% 隐藏关卡配置
%% -define(HIDDEN_FB_TYPE_1, 	1). %% 1、宝箱：打开宝箱可以获得道具（宝箱id）
%% -define(HIDDEN_FB_TYPE_2, 	2). %% 2、巢穴：清剿所有小怪获得大量经验（r_examine_fb_barrier_conf）
%% -define(HIDDEN_FB_TYPE_3, 	3). %% 3、挑战：杀死指定boss获得稀有道具（r_examine_fb_barrier_conf）
%% -define(HIDDEN_FB_TYPE_4, 	4). %% 4、增加角色属性
%% -define(HIDDEN_FB_TYPE_5, 	5). %% 5、增加金钱：获得大量金砖（银币数）
%% -define(HIDDEN_FB_TYPE_6, 	6). %% 6、免费增加一次大富翁
%% -define(HIDDEN_FB_TYPE_7, 	7). %% 7、免费增加一次神游三界/月光宝盒（次数）
%% -define(HIDDEN_FB_TYPE_8, 	8). %% 8、免费增加一次封神榜（次数）
%% -define(HIDDEN_FB_TYPE_9,    9). %% 9、消耗道具({物品id, 数量})
%% -define(HIDDEN_FB_TYPE_10,   10). %% 10、满星通关的宝箱奖励({物品id, 章节id})
-record(hidden_fb_conf, {
		id, 		%% 隐藏关卡id
		type, 		%% 隐藏关卡类型
		award_data  %% 奖励数据
	}).
%% get_hidden_fb(隐藏关卡id) -> #hidden_fb_conf{}
%% get_hidden_fb(1010) -> #hidden_fb_conf{id = 1010, type = 5, award_data = 1000};
%% get_hidden_fb(2005) -> #hidden_fb_conf{id = 2005, type = 2, award_data = get_examine_conf(205)};
%% get_hidden_fb(2010) -> #hidden_fb_conf{id = 2010, type = 4, award_data = 1000}.

<?py for data in examine_fb_hidden_barries: ?>
<?py award = data[2] ?>
<?py if data[1] == 2 or data[1] == 3:?>
<?py award = "get_examine_conf(" + str(data[2]) +")" ?>
<?py #endif ?>
get_hidden_fb(${data[0]}) -> #hidden_fb_conf{id = ${data[0]}, type = ${data[1]}, award_data = ${award}};
<?py #endfor ?>
get_hidden_fb(_) -> undefined.


%% 如果隐藏关卡类型是HIDDEN_FB_TYPE_2的话，需要在这里加上对应的配置
%% examine_to_hidden_barriers(普通关卡id) -> 隐藏关卡id
<?py for data in examine_fb_hidden_barries: ?>
<?py if data[1] == 2 or data[1] == 3:?>
examine_to_hidden_barriers(${data[2]}) -> ${data[0]};
<?py #endif ?>
<?py #endfor ?>
examine_to_hidden_barriers(_) -> [].


%% 隐藏关卡的进入额外条件(目前只支持消耗某物品)
get_hidden_fb_enter_condition(_) -> [].


-record(p_role_base, {
		role_id,
		role_name,
		account_name,
		sex,
		create_time,
		status           = 0,
		head,
		faction_id,
		team_id          = 0,
		family_id        = 0,
		family_name      = "",
		max_hp,
		max_mp,
		str              = 1,
		int2             = 1,
		con              = 2,
		dex              = 1,
		men              = 1,
		base_str         = 0,
		base_int         = 0,
		base_con         = 0,
		base_dex         = 0,
		base_men         = 0,
		pk_title,
		max_phy_attack,
		min_phy_attack,
		max_magic_attack,
		min_magic_attack,
		phy_defence,
		magic_defence,
		hp_recover_speed,
		mp_recover_speed,
		luck,
		move_speed,
		attack_speed,
		no_defence       = 0,
		miss             = 0,
		double_attack    = 0,
		phy_anti         = 0,
		magic_anti       = 0,
		cur_title,
		cur_title_color,
		pk_mode          = 0,
		pk_points        = 0,
		last_gray_name   = 0,
		if_gray_name     = false,
		weapon_type      = 0,
		buffs,
		phy_hurt_rate    = 0,
		magic_hurt_rate  = 0,
		dizzy            = 0,
		poisoning        = 0,
		freeze           = 0,
		hurt             = 0,
		poisoning_resist = 0,
		dizzy_resist     = 0,
		freeze_resist    = 0,
		hurt_rebound     = 0,
		equip_score      = 0,
		hit_rate         = 10000,
		account_type     = 0,
		server_id        = 0,
		is_disabled      = false,
		block            = 0,
		wreck            = 0,
		tough            = 0,
		vigour           = 0,
		week             = 0,
		molder           = 0,
		hunger           = 0,
		bless            = 0,
		crit             = 0,
		bloodline        = 0
}).
%% 增加人物属性类奖励配置(切记:加成id不能修改或删除)
% get_attr_award(加成id) -> {1或2代表是一级还是二级属性, 字段, 值};
<?py for data in examine_fb_add_attr: ?>
get_attr_award(${data[0]}) -> [{${data[1]}, ${data[2]}}];
<?py #endfor ?>
get_attr_award(_) -> [].


%% 打死一个怪物会召唤新的怪物的配置
% called_monster(关卡id, 死亡的怪物id) -> [召唤的怪物id].
<?py for data in examine_fb_call_monster1: ?>
called_monster(${data[0]}, ${data[1]}) -> ${data[2]};
<?py #endfor ?>
%% 下面这个表示没有召唤的怪物
called_monster(_, _) -> [].


%% 奖励关卡（隐藏关起开启的一个打怪关卡）召唤的新一波的怪物
% call_bonus_monster(对应的普通关卡id) -> [{怪物id, X坐标, Y坐标}].
<?py for data in examine_fb_call_monster2: ?>
call_bonus_monster(${data[0]}) -> ${data[1]};
<?py #endfor ?>
%% 下面的这个表示没有新的一波怪物
call_bonus_monster(_) -> [].
