-module(data_scene).

-compile(export_all).

-include("common.hrl").

%% get all scene id list
get_id_list() ->
	[1000, 1100, 1200, 1300, 1400, 1500, 1600, 3000, 3100, 4000].


%%================================================
%% 获取玩家第一次进入游戏可以进入的地图
get_init_access() ->
	[1000, 1100, 1200, 1300, 1400, 1500, 1600, 3000, 3100, 4000].


%%================================================
%% 获取世界boss的地图，地图类型为?SCENE_ARENA2
get_boss_scene() ->
	[3000].


%%================================================
%% 获取所有的副本地图id
get_all_dungeon() ->
	[1200, 1400, 1600].


%%================================================
%% 获取所有的副本地图id
get(1000) ->
	#scene{
		id     = 1000,
		type   = 1,
		row    = 190,
		column = 329
	   };

get(1100) ->
	#scene{
		id     = 1100,
		type   = 2,
		row    = 150,
		column = 184
	   };

get(1200) ->
	#scene{
		id     = 1200,
		type   = 3,
		row    = 111,
		column = 178
	   };

get(1300) ->
	#scene{
		id     = 1300,
		type   = 2,
		row    = 150,
		column = 184
	   };

get(1400) ->
	#scene{
		id     = 1400,
		type   = 3,
		row    = 111,
		column = 178
	   };

get(1500) ->
	#scene{
		id     = 1500,
		type   = 2,
		row    = 150,
		column = 184
	   };

get(1600) ->
	#scene{
		id     = 1600,
		type   = 3,
		row    = 111,
		column = 178
	   };

get(3000) ->
	#scene{
		id     = 3000,
		type   = 6,
		row    = 82,
		column = 94
	   };

get(3100) ->
	#scene{
		id     = 3100,
		type   = 7,
		row    = 98,
		column = 79
	   };

get(4000) ->
	#scene{
		id     = 4000,
		type   = 2,
		row    = 150,
		column = 184
	   }.


%%================================================
%% 获取进入该地图的默认点
get_default_xy(1000) -> {320, 184};

get_default_xy(1100) -> {18, 18};

get_default_xy(1200) -> {8, 79};

get_default_xy(1300) -> {18, 18};

get_default_xy(1400) -> {8, 79};

get_default_xy(1500) -> {18, 18};

get_default_xy(1600) -> {8, 79};

get_default_xy(3000) -> {17, 67};

get_default_xy(3100) -> {20, 62};

get_default_xy(4000) -> {18, 18}.


%%================================================
%% 获取该地图的进入次数限制(0代表无限制)
get_tickets(1200) -> 2;

get_tickets(1400) -> 2;

get_tickets(1600) -> 2.


%%================================================
