-module (data_horse).

-compile(export_all).

-include ("common.hrl").


%% 获取喂养的消耗：
%% get_feed_cost(喂养类型) -> {银币，绑定金币}
get_feed_cost(1) -> {5000, 0};
get_feed_cost(2) -> {0, 5};
get_feed_cost(3) -> {0, 50}.

%% 获取喂养所得的经验
%% get_feed_exp(喂养类型) -> 经验.
get_feed_exp(1) -> 5000;
get_feed_exp(2) -> 10000;
get_feed_exp(3) -> 100000.

%% 获取对应坐骑时装的金币
%% get_equip_cost(坐骑时装id) -> 金币.
get_equip_cost(1) -> 10;
get_equip_cost(2) -> 20;
get_equip_cost(_) -> 30.

%% 获取坐骑的最高等级
get_max_level() -> 3.

%% 根据总经验确定坐骑的等级
get_level(Exp) when Exp >= 1500 -> 3;
get_level(Exp) when Exp >= 1000 -> 2;
get_level(Exp) when Exp >= 500 -> 1;
get_level(_Exp) -> 0.

%% 根据坐骑的等级获取给主将的加成
%% get_added_attri(坐骑等级) -> {力量, 元神, 体格, 敏捷}.
get_added_attri(0) -> 
	#role_update_attri{
		gd_liliang    = 0,
		gd_yuansheng  = 0,
		gd_tipo       = 0,
		gd_minjie     = 0
	};
get_added_attri(1) ->
	#role_update_attri{
		gd_liliang    = 100,
		gd_yuansheng  = 100,
		gd_tipo       = 100,
		gd_minjie     = 100
	};
get_added_attri(2) -> 
	#role_update_attri{
		gd_liliang    = 200,
		gd_yuansheng  = 200,
		gd_tipo       = 200,
		gd_minjie     = 200
	};
get_added_attri(3) -> 
	#role_update_attri{
		gd_liliang    = 300,
		gd_yuansheng  = 300,
		gd_tipo       = 300,
		gd_minjie     = 300
	}.

