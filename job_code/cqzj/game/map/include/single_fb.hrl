%% 单人副本的头文件

%% ext_datas可以做的事情：
%% 1.比如某个副本类型有很多的关卡，需求需要记录各个关卡的数据
%%   那么里面可以存[{关卡id, data1, data2, data3}]

%% 每个副本类型相关的数据记录
-record (fb_detail, {
	fb_type     = 0,		%% 副本类型
	enter_times = 0,		%% 当天进入次数
	ext_datas   = []		%% 各副本自定义的数据，可以各种格式
}).

%% 玩家的所有副本数据记录
-record(r_single_fb, {
	role_id     = 0,
	fb_datas    = [],	%% 各种副本的数据[#fb_detail{}]
	update_time = 0 	%% 用于重置进入次数的
}).

-record (single_fb_baseinfo, {
	entry_npc       = 0,	%% 入口npc的id
	fb_type         = 0,	%% 副本类型
	fb_id			= 0, 	%% 副本id(可理解为不同等级级别，或是关卡id)
	map_id          = 0,	%% 地图id
	open_level      = 0,	%% 副本开启等级
	max_enter_times = 0 	%% 最大进入次数
}).

-record(battle_open_time, {
	date         = 0, 		%% 下一次开启的date
	start_time   = 0,		%% 开始时间(秒)
	end_time     = 0,		%% 结束时间(秒)
	next_bc_time = 0 		%% 下一次开启的广播时间(秒)
}).
