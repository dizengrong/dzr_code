-module(data_task).

-compile(export_all).

-include("common.hrl"). 

%% 获取任务配置
get(1) ->
	#task{
		id         = 1,
		name       = "乱世三国",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=4,value=3},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50042},place_holder],
		npc1       = [1],
		npc2       = [1],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(10) ->
	#task{
		id         = 10,
		name       = "前来相助",
		type       = 1,
		req_type   = 4,
		difficulty = 0,
		tips       = [#task_tip{key={4,[7]},need=1,finish=0}],
		prev_id    = 9,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50051},place_holder],
		npc1       = [7],
		npc2       = [8],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(10001) ->
	#task{
		id         = 10001,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[3]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10002) ->
	#task{
		id         = 10002,
		name       = "师门试炼",
		type       = 11,
		req_type   = 32,
		difficulty = 0,
		tips       = [#task_tip{key={32,[119]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10003) ->
	#task{
		id         = 10003,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[4]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10004) ->
	#task{
		id         = 10004,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[5]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10005) ->
	#task{
		id         = 10005,
		name       = "师门试炼",
		type       = 11,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [15],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10006) ->
	#task{
		id         = 10006,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[6]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10007) ->
	#task{
		id         = 10007,
		name       = "师门试炼",
		type       = 11,
		req_type   = 11,
		difficulty = 0,
		tips       = [#task_tip{key={11,[9]},need=10,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10008) ->
	#task{
		id         = 10008,
		name       = "师门试炼",
		type       = 11,
		req_type   = 32,
		difficulty = 0,
		tips       = [#task_tip{key={32,[120]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10009) ->
	#task{
		id         = 10009,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[4]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(1001) ->
	#task{
		id         = 1001,
		name       = "天牢探视",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [9],
		npc2       = [76],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(10010) ->
	#task{
		id         = 10010,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[7]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10011) ->
	#task{
		id         = 10011,
		name       = "师门试炼",
		type       = 11,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [85],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10012) ->
	#task{
		id         = 10012,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[8]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10013) ->
	#task{
		id         = 10013,
		name       = "师门试炼",
		type       = 11,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [8],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10014) ->
	#task{
		id         = 10014,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[5]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10015) ->
	#task{
		id         = 10015,
		name       = "师门试炼",
		type       = 11,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [22],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10016) ->
	#task{
		id         = 10016,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[7]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10017) ->
	#task{
		id         = 10017,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[1]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10018) ->
	#task{
		id         = 10018,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[3]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10019) ->
	#task{
		id         = 10019,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[7]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(1002) ->
	#task{
		id         = 1002,
		name       = "不准进入",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1001,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [76],
		npc2       = [60],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(10020) ->
	#task{
		id         = 10020,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[1]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10021) ->
	#task{
		id         = 10021,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[3]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10022) ->
	#task{
		id         = 10022,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[5]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10023) ->
	#task{
		id         = 10023,
		name       = "师门试炼",
		type       = 11,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [83],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10024) ->
	#task{
		id         = 10024,
		name       = "师门试炼",
		type       = 11,
		req_type   = 11,
		difficulty = 0,
		tips       = [#task_tip{key={11,[10]},need=10,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10025) ->
	#task{
		id         = 10025,
		name       = "师门试炼",
		type       = 11,
		req_type   = 11,
		difficulty = 0,
		tips       = [#task_tip{key={11,[11]},need=10,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10026) ->
	#task{
		id         = 10026,
		name       = "师门试炼",
		type       = 11,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [59],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10027) ->
	#task{
		id         = 10027,
		name       = "师门试炼",
		type       = 11,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [84],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10028) ->
	#task{
		id         = 10028,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[3]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10029) ->
	#task{
		id         = 10029,
		name       = "师门试炼",
		type       = 11,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[5]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=30},place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(1003) ->
	#task{
		id         = 1003,
		name       = "初识华佗",
		type       = 2,
		req_type   = 32,
		difficulty = 0,
		tips       = [#task_tip{key={32,[120]},need=3,finish=0}],
		prev_id    = 1002,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [60],
		npc2       = [60],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(10030) ->
	#task{
		id         = 10030,
		name       = "师门试炼",
		type       = 11,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [1,2,3],
		npc2       = [4,5,6],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10031) ->
	#task{
		id         = 10031,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[3]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10032) ->
	#task{
		id         = 10032,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 32,
		difficulty = 0,
		tips       = [#task_tip{key={32,[119]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10033) ->
	#task{
		id         = 10033,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[4]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10034) ->
	#task{
		id         = 10034,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[5]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10035) ->
	#task{
		id         = 10035,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [15],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10036) ->
	#task{
		id         = 10036,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[6]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10037) ->
	#task{
		id         = 10037,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 11,
		difficulty = 0,
		tips       = [#task_tip{key={11,[9]},need=10,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10038) ->
	#task{
		id         = 10038,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 32,
		difficulty = 0,
		tips       = [#task_tip{key={32,[120]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10039) ->
	#task{
		id         = 10039,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[4]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(1004) ->
	#task{
		id         = 1004,
		name       = "出谋划策",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1003,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [60],
		npc2       = [76],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(10040) ->
	#task{
		id         = 10040,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[7]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10041) ->
	#task{
		id         = 10041,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [85],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10042) ->
	#task{
		id         = 10042,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[8]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10043) ->
	#task{
		id         = 10043,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [8],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10044) ->
	#task{
		id         = 10044,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[5]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10045) ->
	#task{
		id         = 10045,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [22],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10046) ->
	#task{
		id         = 10046,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[7]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10047) ->
	#task{
		id         = 10047,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[1]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10048) ->
	#task{
		id         = 10048,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[3]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10049) ->
	#task{
		id         = 10049,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[7]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(1005) ->
	#task{
		id         = 1005,
		name       = "投其所好",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1004,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [76],
		npc2       = [19],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(10050) ->
	#task{
		id         = 10050,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[1]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10051) ->
	#task{
		id         = 10051,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[3]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10052) ->
	#task{
		id         = 10052,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[5]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10053) ->
	#task{
		id         = 10053,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [83],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10054) ->
	#task{
		id         = 10054,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 11,
		difficulty = 0,
		tips       = [#task_tip{key={11,[10]},need=10,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10055) ->
	#task{
		id         = 10055,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 11,
		difficulty = 0,
		tips       = [#task_tip{key={11,[11]},need=10,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10056) ->
	#task{
		id         = 10056,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [59],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10057) ->
	#task{
		id         = 10057,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [84],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10058) ->
	#task{
		id         = 10058,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[3]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(10059) ->
	#task{
		id         = 10059,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[5]},need=3,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(1006) ->
	#task{
		id         = 1006,
		name       = "丢失的御猫",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[7]},need=3,finish=0}],
		prev_id    = 1005,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [19],
		npc2       = [19],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(10060) ->
	#task{
		id         = 10060,
		name       = "帮派试炼",
		type       = 12,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [66],
		npc2       = [66],
		rec_reward = [place_holder],
		auto_complete = 1
	};

get(1007) ->
	#task{
		id         = 1007,
		name       = "新的线索",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1006,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [19],
		npc2       = [34],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1008) ->
	#task{
		id         = 1008,
		name       = "得到行踪",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[4]},need=3,finish=0}],
		prev_id    = 1007,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [34],
		npc2       = [76],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1009) ->
	#task{
		id         = 1009,
		name       = "黑风寨",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1008,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [76],
		npc2       = [98],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1010) ->
	#task{
		id         = 1010,
		name       = "清剿山贼",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[3]},need=3,finish=0}],
		prev_id    = 1009,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [98],
		npc2       = [98],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1011) ->
	#task{
		id         = 1011,
		name       = "审问山贼",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1010,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [98],
		npc2       = [11],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1012) ->
	#task{
		id         = 1012,
		name       = "归还御猫",
		type       = 2,
		req_type   = 32,
		difficulty = 0,
		tips       = [#task_tip{key={32,[119]},need=3,finish=0}],
		prev_id    = 1011,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [11],
		npc2       = [60],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1013) ->
	#task{
		id         = 1013,
		name       = "重回平静",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1012,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [60],
		npc2       = [76],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1020) ->
	#task{
		id         = 1020,
		name       = "关关雎鸠",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [66],
		npc2       = [61],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1021) ->
	#task{
		id         = 1021,
		name       = "在河之洲",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1020,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [61],
		npc2       = [59],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1022) ->
	#task{
		id         = 1022,
		name       = "窈窕淑女",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[8]},need=3,finish=0}],
		prev_id    = 1021,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [59],
		npc2       = [59],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1023) ->
	#task{
		id         = 1023,
		name       = "君子好逑",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[5]},need=3,finish=0}],
		prev_id    = 1022,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [59],
		npc2       = [61],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1024) ->
	#task{
		id         = 1024,
		name       = "求之不得",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1023,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [61],
		npc2       = [18],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1025) ->
	#task{
		id         = 1025,
		name       = "优哉游哉",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[2]},need=3,finish=0}],
		prev_id    = 1024,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [18],
		npc2       = [18],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1026) ->
	#task{
		id         = 1026,
		name       = "辗转反侧",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1025,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [18],
		npc2       = [64],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1027) ->
	#task{
		id         = 1027,
		name       = "琴瑟友之",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[4]},need=0,finish=0}],
		prev_id    = 1026,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [64],
		npc2       = [18],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1028) ->
	#task{
		id         = 1028,
		name       = "钟鼓乐之",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[3]},need=0,finish=0}],
		prev_id    = 1027,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [18],
		npc2       = [61],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(11) ->
	#task{
		id         = 11,
		name       = "剿灭山贼",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[3]},need=1,finish=0}],
		prev_id    = 10,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50052},place_holder],
		npc1       = [8],
		npc2       = [9],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1101) ->
	#task{
		id         = 1101,
		name       = "走漏风声",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [36],
		npc2       = [43],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1102) ->
	#task{
		id         = 1102,
		name       = "追捕细作",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[18]},need=3,finish=0}],
		prev_id    = 1101,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [43],
		npc2       = [40],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1103) ->
	#task{
		id         = 1103,
		name       = "突现杀机",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[17]},need=3,finish=0}],
		prev_id    = 1102,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [40],
		npc2       = [43],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1104) ->
	#task{
		id         = 1104,
		name       = "暗中搜查",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1103,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [43],
		npc2       = [61],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1105) ->
	#task{
		id         = 1105,
		name       = "蛛丝马迹",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1104,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [61],
		npc2       = [43],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1106) ->
	#task{
		id         = 1106,
		name       = "作乱之心",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[21]},need=3,finish=0}],
		prev_id    = 1105,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [43],
		npc2       = [41],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1108) ->
	#task{
		id         = 1108,
		name       = "抓捕归营",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[16]},need=3,finish=0}],
		prev_id    = 1107,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [41],
		npc2       = [43],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1120) ->
	#task{
		id         = 1120,
		name       = "军营失窃",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [86],
		npc2       = [86],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1121) ->
	#task{
		id         = 1121,
		name       = "找回信物",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1120,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [86],
		npc2       = [64],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1122) ->
	#task{
		id         = 1122,
		name       = "红玉扳指",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[21]},need=3,finish=0}],
		prev_id    = 1121,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [64],
		npc2       = [64],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1123) ->
	#task{
		id         = 1123,
		name       = "紫玉扳指",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[23]},need=3,finish=0}],
		prev_id    = 1122,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [64],
		npc2       = [60],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1124) ->
	#task{
		id         = 1124,
		name       = "查明情况",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1123,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [60],
		npc2       = [86],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1125) ->
	#task{
		id         = 1125,
		name       = "金色令牌",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[17]},need=3,finish=0}],
		prev_id    = 1124,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [86],
		npc2       = [86],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1126) ->
	#task{
		id         = 1126,
		name       = "捉拿敌将",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1125,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [86],
		npc2       = [33],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1127) ->
	#task{
		id         = 1127,
		name       = "守住机密",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[25]},need=3,finish=0}],
		prev_id    = 1126,
		req_level  = 30,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [33],
		npc2       = [86],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1140) ->
	#task{
		id         = 1140,
		name       = "帮助神医",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 0,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [83],
		npc2       = [75],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1141) ->
	#task{
		id         = 1141,
		name       = "排忧解难",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[35]},need=1,finish=0}],
		prev_id    = 1140,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [75],
		npc2       = [60],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1142) ->
	#task{
		id         = 1142,
		name       = "草乌块根",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[34]},need=1,finish=0}],
		prev_id    = 1140,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [60],
		npc2       = [60],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1143) ->
	#task{
		id         = 1143,
		name       = "人参三七",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[36]},need=1,finish=0}],
		prev_id    = 1140,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [60],
		npc2       = [60],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1144) ->
	#task{
		id         = 1144,
		name       = "神医之托",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1140,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [60],
		npc2       = [68],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1145) ->
	#task{
		id         = 1145,
		name       = "陈年往事",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1140,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [68],
		npc2       = [68],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1146) ->
	#task{
		id         = 1146,
		name       = "恩怨纠葛",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1140,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [68],
		npc2       = [60],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1147) ->
	#task{
		id         = 1147,
		name       = "难以释怀",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1140,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [60],
		npc2       = [60],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1148) ->
	#task{
		id         = 1148,
		name       = "往事难矣",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[37]},need=1,finish=0}],
		prev_id    = 1140,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [60],
		npc2       = [60],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1149) ->
	#task{
		id         = 1149,
		name       = "寻回旧物",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[38]},need=1,finish=0}],
		prev_id    = 1140,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [60],
		npc2       = [68],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1150) ->
	#task{
		id         = 1150,
		name       = "物归原主",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1140,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [68],
		npc2       = [60],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1155) ->
	#task{
		id         = 1155,
		name       = "火冒三丈",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[39]},need=1,finish=0}],
		prev_id    = 0,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [77],
		npc2       = [77],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1156) ->
	#task{
		id         = 1156,
		name       = "雕虫小技",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1155,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [77],
		npc2       = [83],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1157) ->
	#task{
		id         = 1157,
		name       = "神秘药方",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1156,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [83],
		npc2       = [83],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1158) ->
	#task{
		id         = 1158,
		name       = "收集药材",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[40]},need=1,finish=0}],
		prev_id    = 1157,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [83],
		npc2       = [77],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1159) ->
	#task{
		id         = 1159,
		name       = "寻找大黄",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[42]},need=1,finish=0}],
		prev_id    = 1158,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [77],
		npc2       = [118],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1160) ->
	#task{
		id         = 1160,
		name       = "五斗米圣物",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[41]},need=1,finish=0}],
		prev_id    = 1159,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [118],
		npc2       = [118],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1161) ->
	#task{
		id         = 1161,
		name       = "采集硭硝",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[35]},need=1,finish=0}],
		prev_id    = 1160,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [118],
		npc2       = [86],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1162) ->
	#task{
		id         = 1162,
		name       = "求助神医",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1161,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [86],
		npc2       = [60],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1163) ->
	#task{
		id         = 1163,
		name       = "镖局老板",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1162,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [60],
		npc2       = [68],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1164) ->
	#task{
		id         = 1164,
		name       = "得到药材",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[34]},need=1,finish=0}],
		prev_id    = 1163,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [68],
		npc2       = [77],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1165) ->
	#task{
		id         = 1165,
		name       = "投入泻药",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[36]},need=1,finish=0}],
		prev_id    = 1164,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [77],
		npc2       = [77],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1166) ->
	#task{
		id         = 1166,
		name       = "浑水摸鱼",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[37]},need=1,finish=0}],
		prev_id    = 1165,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [77],
		npc2       = [83],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1167) ->
	#task{
		id         = 1167,
		name       = "鱼目混珠",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[38]},need=1,finish=0}],
		prev_id    = 1166,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [83],
		npc2       = [77],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1168) ->
	#task{
		id         = 1168,
		name       = "寻找伪装",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1167,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [77],
		npc2       = [59],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1169) ->
	#task{
		id         = 1169,
		name       = "一无所获",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1168,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [59],
		npc2       = [77],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1170) ->
	#task{
		id         = 1170,
		name       = "锁定目标",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1169,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [77],
		npc2       = [118],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1171) ->
	#task{
		id         = 1171,
		name       = "打劫使者",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[39]},need=1,finish=0}],
		prev_id    = 1170,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [118],
		npc2       = [77],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1172) ->
	#task{
		id         = 1172,
		name       = "伪装成功",
		type       = 2,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[40]},need=1,finish=0}],
		prev_id    = 1171,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [77],
		npc2       = [46],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(1173) ->
	#task{
		id         = 1173,
		name       = "瞒天过海",
		type       = 2,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1172,
		req_level  = 50,
		reward     = [place_holder],
		npc1       = [46],
		npc2       = [83],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(12) ->
	#task{
		id         = 12,
		name       = "反董大军",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 11,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50053},place_holder],
		npc1       = [9],
		npc2       = [10],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(13) ->
	#task{
		id         = 13,
		name       = "押运军粮",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[4]},need=1,finish=0}],
		prev_id    = 12,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50054},place_holder],
		npc1       = [10],
		npc2       = [10],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(14) ->
	#task{
		id         = 14,
		name       = "战场良驹",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 13,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50055},place_holder],
		npc1       = [10],
		npc2       = [11],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(15) ->
	#task{
		id         = 15,
		name       = "调查军营",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 14,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50056},place_holder],
		npc1       = [11],
		npc2       = [12],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(150) ->
	#task{
		id         = 150,
		name       = "兄弟再会",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 94,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [86],
		npc2       = [75],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(151) ->
	#task{
		id         = 151,
		name       = "卧牛山",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 150,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [75],
		npc2       = [99],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(152) ->
	#task{
		id         = 152,
		name       = "赵云加入",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[34]},need=1,finish=0}],
		prev_id    = 151,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [99],
		npc2       = [100],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(153) ->
	#task{
		id         = 153,
		name       = "投靠刘表",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 152,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [100],
		npc2       = [101],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(154) ->
	#task{
		id         = 154,
		name       = "会面百官",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 153,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [101],
		npc2       = [102],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(155) ->
	#task{
		id         = 155,
		name       = "逃离陷阱",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[35]},need=1,finish=0}],
		prev_id    = 154,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [102],
		npc2       = [102],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(156) ->
	#task{
		id         = 156,
		name       = "腹背受敌",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 155,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [102],
		npc2       = [103],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(157) ->
	#task{
		id         = 157,
		name       = "卧龙凤雏",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 156,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [103],
		npc2       = [100],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(158) ->
	#task{
		id         = 158,
		name       = "奇怪阵法",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[36]},need=1,finish=0}],
		prev_id    = 157,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [100],
		npc2       = [104],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(159) ->
	#task{
		id         = 159,
		name       = "八卦锁金阵",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 158,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [104],
		npc2       = [104],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(16) ->
	#task{
		id         = 16,
		name       = "灵药傍身",
		type       = 1,
		req_type   = 32,
		difficulty = 0,
		tips       = [#task_tip{key={32,[13,14,15,16,17]},need=1,finish=0}],
		prev_id    = 15,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50057},place_holder],
		npc1       = [12],
		npc2       = [12],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(160) ->
	#task{
		id         = 160,
		name       = "天青石",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 159,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [104],
		npc2       = [105],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(161) ->
	#task{
		id         = 161,
		name       = "火烧兵寨",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[37]},need=1,finish=0}],
		prev_id    = 160,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [105],
		npc2       = [106],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(162) ->
	#task{
		id         = 162,
		name       = "一顾茅庐",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 161,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [106],
		npc2       = [107],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(163) ->
	#task{
		id         = 163,
		name       = "空手而归",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 162,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [107],
		npc2       = [100],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(164) ->
	#task{
		id         = 164,
		name       = "二顾茅庐",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 163,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [100],
		npc2       = [107],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(165) ->
	#task{
		id         = 165,
		name       = "除掉恶狼",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[38]},need=1,finish=0}],
		prev_id    = 164,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [107],
		npc2       = [100],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(166) ->
	#task{
		id         = 166,
		name       = "再次落空",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 165,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [100],
		npc2       = [102],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(167) ->
	#task{
		id         = 167,
		name       = "三顾茅庐",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 166,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [102],
		npc2       = [108],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(168) ->
	#task{
		id         = 168,
		name       = "十万大军",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 167,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [108],
		npc2       = [109],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(169) ->
	#task{
		id         = 169,
		name       = "清除障碍",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[39]},need=1,finish=0}],
		prev_id    = 168,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [109],
		npc2       = [109],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(17) ->
	#task{
		id         = 17,
		name       = "珍贵赠礼",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 16,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50058},place_holder],
		npc1       = [12],
		npc2       = [12],
		rec_reward = [#task_reward{type=4,value=17},place_holder],
		auto_complete = 0
	};

get(170) ->
	#task{
		id         = 170,
		name       = "引火",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 169,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [109],
		npc2       = [110],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(171) ->
	#task{
		id         = 171,
		name       = "等待时机",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 170,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [110],
		npc2       = [109],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(172) ->
	#task{
		id         = 172,
		name       = "火烧博望坡",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[40]},need=1,finish=0}],
		prev_id    = 171,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [109],
		npc2       = [111],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(173) ->
	#task{
		id         = 173,
		name       = "荆州之主",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 172,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [111],
		npc2       = [108],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(174) ->
	#task{
		id         = 174,
		name       = "樊城避难",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 173,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [108],
		npc2       = [108],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(175) ->
	#task{
		id         = 175,
		name       = "长坂坡",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[41]},need=1,finish=0}],
		prev_id    = 174,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [108],
		npc2       = [112],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(176) ->
	#task{
		id         = 176,
		name       = "一路追寻",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 175,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [112],
		npc2       = [112],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(177) ->
	#task{
		id         = 177,
		name       = "寻找少主",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 176,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [112],
		npc2       = [113],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(178) ->
	#task{
		id         = 178,
		name       = "单骑救主",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 177,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [113],
		npc2       = [114],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(179) ->
	#task{
		id         = 179,
		name       = "突出重围",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[42]},need=1,finish=0}],
		prev_id    = 178,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [114],
		npc2       = [116],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(18) ->
	#task{
		id         = 18,
		name       = "通行手令",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[5]},need=1,finish=0}],
		prev_id    = 17,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50059},place_holder],
		npc1       = [12],
		npc2       = [18],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(180) ->
	#task{
		id         = 180,
		name       = "折断桥梁",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 179,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [116],
		npc2       = [117],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(181) ->
	#task{
		id         = 181,
		name       = "逃离长坂",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 180,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [117],
		npc2       = [117],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(182) ->
	#task{
		id         = 182,
		name       = "拦截追兵",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[43]},need=1,finish=0}],
		prev_id    = 181,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [117],
		npc2       = [86],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(183) ->
	#task{
		id         = 183,
		name       = "挽回颓势",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 182,
		req_level  = 0,
		reward     = [place_holder],
		npc1       = [86],
		npc2       = [83],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(19) ->
	#task{
		id         = 19,
		name       = "牢狱之灾",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 18,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50060},place_holder],
		npc1       = [18],
		npc2       = [19],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(2) ->
	#task{
		id         = 2,
		name       = "拜入师门",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 1,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50043},place_holder],
		npc1       = [1],
		npc2       = [2],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(20) ->
	#task{
		id         = 20,
		name       = "劫狱",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[7]},need=1,finish=0}],
		prev_id    = 19,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50061},place_holder],
		npc1       = [19],
		npc2       = [19],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(21) ->
	#task{
		id         = 21,
		name       = "初识曹操",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 20,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50062},place_holder],
		npc1       = [19],
		npc2       = [20],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(22) ->
	#task{
		id         = 22,
		name       = "得到情报",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 21,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50063},place_holder],
		npc1       = [20],
		npc2       = [21],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(23) ->
	#task{
		id         = 23,
		name       = "人中吕布",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 22,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50064},place_holder],
		npc1       = [21],
		npc2       = [22],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(24) ->
	#task{
		id         = 24,
		name       = "南门守军",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[6]},need=1,finish=0}],
		prev_id    = 23,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50065},place_holder],
		npc1       = [22],
		npc2       = [24],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(25) ->
	#task{
		id         = 25,
		name       = "将军魏延",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 24,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50066},place_holder],
		npc1       = [24],
		npc2       = [23],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(26) ->
	#task{
		id         = 26,
		name       = "赤兔部队",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 25,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50067},place_holder],
		npc1       = [23],
		npc2       = [25],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(27) ->
	#task{
		id         = 27,
		name       = "百毒之王",
		type       = 1,
		req_type   = 32,
		difficulty = 0,
		tips       = [#task_tip{key={32,[121,122,123,124,125,126,127]},need=1,finish=0}],
		prev_id    = 26,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50068},place_holder],
		npc1       = [25],
		npc2       = [26],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(28) ->
	#task{
		id         = 28,
		name       = "龙呤血玉",
		type       = 1,
		req_type   = 37,
		difficulty = 0,
		tips       = [#task_tip{key={37,[427,107001]},need=1,finish=0}],
		prev_id    = 27,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50069},place_holder],
		npc1       = [26],
		npc2       = [26],
		rec_reward = [#task_reward{type=4,value=427},place_holder],
		auto_complete = 0
	};

get(29) ->
	#task{
		id         = 29,
		name       = "支援友军",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 28,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50070},place_holder],
		npc1       = [26],
		npc2       = [28],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(3) ->
	#task{
		id         = 3,
		name       = "神兵利器",
		type       = 1,
		req_type   = 3,
		difficulty = 0,
		tips       = [#task_tip{key={3,[9]},need=1,finish=0}],
		prev_id    = 2,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50044},place_holder],
		npc1       = [2],
		npc2       = [3],
		rec_reward = [#task_reward{type=4,value=9},place_holder],
		auto_complete = 0
	};

get(30) ->
	#task{
		id         = 30,
		name       = "不战而胜",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[8]},need=1,finish=0}],
		prev_id    = 29,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50071},place_holder],
		npc1       = [28],
		npc2       = [27],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(31) ->
	#task{
		id         = 31,
		name       = "传递捷报",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 30,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50072},place_holder],
		npc1       = [27],
		npc2       = [29],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(32) ->
	#task{
		id         = 32,
		name       = "进攻虎牢关",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 31,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50073},place_holder],
		npc1       = [29],
		npc2       = [30],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(33) ->
	#task{
		id         = 33,
		name       = "虎牢之战",
		type       = 1,
		req_type   = 9,
		difficulty = 0,
		tips       = [#task_tip{key={9,[1200]},need=1,finish=0}],
		prev_id    = 32,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50074},place_holder],
		npc1       = [30],
		npc2       = [30],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(34) ->
	#task{
		id         = 34,
		name       = "报告军情",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 33,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50042},place_holder],
		npc1       = [30],
		npc2       = [31],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(35) ->
	#task{
		id         = 35,
		name       = "汉家玉玺",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 34,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50043},place_holder],
		npc1       = [31],
		npc2       = [32],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(36) ->
	#task{
		id         = 36,
		name       = "初入洛阳",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 35,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50044},place_holder],
		npc1       = [32],
		npc2       = [33],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(37) ->
	#task{
		id         = 37,
		name       = "口信",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 36,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [33],
		npc2       = [34],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(38) ->
	#task{
		id         = 38,
		name       = "竹林之约",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 37,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [34],
		npc2       = [35],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(39) ->
	#task{
		id         = 39,
		name       = "心生间隙",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 38,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [35],
		npc2       = [32],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(4) ->
	#task{
		id         = 4,
		name       = "新手试炼",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[1]},need=1,finish=0}],
		prev_id    = 3,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50045},place_holder],
		npc1       = [3],
		npc2       = [4],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(5) ->
	#task{
		id         = 5,
		name       = "无双战袍",
		type       = 1,
		req_type   = 3,
		difficulty = 0,
		tips       = [#task_tip{key={3,[4]},need=1,finish=0}],
		prev_id    = 4,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50046},place_holder],
		npc1       = [4],
		npc2       = [4],
		rec_reward = [#task_reward{type=4,value=4},place_holder],
		auto_complete = 0
	};

get(6) ->
	#task{
		id         = 6,
		name       = "破凰之力",
		type       = 1,
		req_type   = 32,
		difficulty = 0,
		tips       = [#task_tip{key={32,[119]},need=1,finish=0}],
		prev_id    = 5,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50047},place_holder],
		npc1       = [4],
		npc2       = [5],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(60) ->
	#task{
		id         = 60,
		name       = "洛阳之围",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 48,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [32],
		npc2       = [36],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(61) ->
	#task{
		id         = 61,
		name       = "救助袁绍",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 60,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [36],
		npc2       = [37],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(62) ->
	#task{
		id         = 62,
		name       = "利益合作",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 61,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [37],
		npc2       = [38],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(63) ->
	#task{
		id         = 63,
		name       = "刺杀董卓",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[16]},need=1,finish=0}],
		prev_id    = 62,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [38],
		npc2       = [39],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(64) ->
	#task{
		id         = 64,
		name       = "逃离长安",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 63,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [39],
		npc2       = [40],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(65) ->
	#task{
		id         = 65,
		name       = "投奔李傕",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 64,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [40],
		npc2       = [41],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(66) ->
	#task{
		id         = 66,
		name       = "扰敌之法",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[17]},need=1,finish=0}],
		prev_id    = 65,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [41],
		npc2       = [41],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(67) ->
	#task{
		id         = 67,
		name       = "见到贾诩",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 66,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [41],
		npc2       = [42],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(68) ->
	#task{
		id         = 68,
		name       = "诱敌深入",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 67,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [42],
		npc2       = [43],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(69) ->
	#task{
		id         = 69,
		name       = "追击吕布",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[18]},need=1,finish=0}],
		prev_id    = 68,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [43],
		npc2       = [42],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(7) ->
	#task{
		id         = 7,
		name       = "拜见师兄",
		type       = 1,
		req_type   = 37,
		difficulty = 0,
		tips       = [#task_tip{key={37,[426,106001]},need=1,finish=0}],
		prev_id    = 6,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50048},place_holder],
		npc1       = [5],
		npc2       = [5],
		rec_reward = [#task_reward{type=4,value=426},place_holder],
		auto_complete = 0
	};

get(70) ->
	#task{
		id         = 70,
		name       = "继位之人",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 69,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [42],
		npc2       = [44],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(71) ->
	#task{
		id         = 71,
		name       = "西凉来袭",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 70,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [44],
		npc2       = [43],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(72) ->
	#task{
		id         = 72,
		name       = "化解纷争",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[19]},need=1,finish=0}],
		prev_id    = 71,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [43],
		npc2       = [45],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(73) ->
	#task{
		id         = 73,
		name       = "妙计退敌",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 72,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [45],
		npc2       = [43],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(74) ->
	#task{
		id         = 74,
		name       = "同乡之谊",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 73,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [43],
		npc2       = [44],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(75) ->
	#task{
		id         = 75,
		name       = "投奔明主",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 74,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [44],
		npc2       = [46],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(76) ->
	#task{
		id         = 76,
		name       = "入主洛阳",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[20]},need=1,finish=0}],
		prev_id    = 75,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [46],
		npc2       = [47],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(77) ->
	#task{
		id         = 77,
		name       = "洛阳护驾",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 76,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [47],
		npc2       = [46],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(78) ->
	#task{
		id         = 78,
		name       = "击退杨奉",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 77,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [46],
		npc2       = [46],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(79) ->
	#task{
		id         = 79,
		name       = "说服陛下",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 78,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [46],
		npc2       = [48],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(8) ->
	#task{
		id         = 8,
		name       = "庄外村庄",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 7,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50049},place_holder],
		npc1       = [5],
		npc2       = [6],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(80) ->
	#task{
		id         = 80,
		name       = "继续战斗",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[21]},need=1,finish=0}],
		prev_id    = 79,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [48],
		npc2       = [49],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(81) ->
	#task{
		id         = 81,
		name       = "得到徐晃",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[22]},need=1,finish=0}],
		prev_id    = 80,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [49],
		npc2       = [50],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(82) ->
	#task{
		id         = 82,
		name       = "联盟",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 81,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [50],
		npc2       = [51],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(83) ->
	#task{
		id         = 83,
		name       = "抵御吕布",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 82,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [51],
		npc2       = [50],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(84) ->
	#task{
		id         = 84,
		name       = "孤立吕布",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 83,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [50],
		npc2       = [51],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(85) ->
	#task{
		id         = 85,
		name       = "夺取赤兔",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 84,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [51],
		npc2       = [52],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(86) ->
	#task{
		id         = 86,
		name       = "白门楼",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[23]},need=1,finish=0}],
		prev_id    = 85,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [52],
		npc2       = [51],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(87) ->
	#task{
		id         = 87,
		name       = "血诏",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 86,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [51],
		npc2       = [51],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(88) ->
	#task{
		id         = 88,
		name       = "追随刘备",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 87,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [51],
		npc2       = [50],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(89) ->
	#task{
		id         = 89,
		name       = "逃离曹营",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 88,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [50],
		npc2       = [52],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(9) ->
	#task{
		id         = 9,
		name       = "庄外调查",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 8,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},#task_reward{type=11,value=50050},place_holder],
		npc1       = [6],
		npc2       = [7],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(90) ->
	#task{
		id         = 90,
		name       = "剿灭袁术",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[24]},need=1,finish=0}],
		prev_id    = 89,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [52],
		npc2       = [53],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(91) ->
	#task{
		id         = 91,
		name       = "投靠袁绍",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 90,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [53],
		npc2       = [52],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(92) ->
	#task{
		id         = 92,
		name       = "一探究竟",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 91,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [52],
		npc2       = [54],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(93) ->
	#task{
		id         = 93,
		name       = "过五关斩六将",
		type       = 1,
		req_type   = 1,
		difficulty = 0,
		tips       = [#task_tip{key={1,[25]},need=1,finish=0}],
		prev_id    = 92,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [54],
		npc2       = [55],
		rec_reward = [place_holder],
		auto_complete = 0
	};

get(94) ->
	#task{
		id         = 94,
		name       = "就此别过",
		type       = 1,
		req_type   = 2,
		difficulty = 0,
		tips       = [#task_tip{key={2,[0]},need=0,finish=0}],
		prev_id    = 93,
		req_level  = 0,
		reward     = [#task_reward{type=3,value=300},#task_reward{type=7,value=300},#task_reward{type=8,value=300},#task_reward{type=9,value=300},place_holder],
		npc1       = [55],
		npc2       = [57],
		rec_reward = [place_holder],
		auto_complete = 0
	}.


%%================================================
%% 循环任务类型列表
get_cyclic_type_list() -> [11,12].


%%================================================
%% 循环任务随机列表
get_cyclic_task_list(11, 30) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 31) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 32) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 33) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 34) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 35) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 36) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 37) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 38) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 39) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 40) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 41) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 42) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 43) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 44) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 45) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 46) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 47) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 48) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 49) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 50) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 51) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 52) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 53) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 54) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 55) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 56) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 57) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 58) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 59) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 60) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 61) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 62) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 63) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 64) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 65) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 66) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 67) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 68) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 69) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(11, 70) ->
	[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010,10011,10012,10013,10014,10015,10016,10017,10018,10019,10020,10021,10022,10023,10024,10025,10026,10027,10028,10029,10030];

get_cyclic_task_list(12, 30) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 31) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 32) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 33) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 34) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 35) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 36) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 37) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 38) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 39) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 40) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 41) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 42) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 43) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 44) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 45) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 46) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 47) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 48) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 49) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 50) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 51) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 52) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 53) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 54) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 55) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 56) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 57) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 58) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 59) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 60) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 61) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 62) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 63) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 64) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 65) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 66) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 67) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 68) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 69) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060];

get_cyclic_task_list(12, 70) ->
	[10031,10032,10033,10034,10035,10036,10037,10038,10039,10040,10041,10042,10043,10044,10045,10046,10047,10048,10049,10050,10051,10052,10053,10054,10055,10056,10057,1058,10059,10060].


%%================================================
%% 循环任务随机列表
get_cyclic_task_reward(11, 30, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 30, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 30, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 30, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 30, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 30, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 30, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 30, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 30, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 30, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 30, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 31, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 31, 1) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=20},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 31, 2) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=20},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 31, 3) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=20},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 31, 4) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=20},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 31, 5) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=20},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 31, 6) ->
	[#task_reward{type=3,value=1200},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=20},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 31, 7) ->
	[#task_reward{type=3,value=1400},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=20},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 31, 8) ->
	[#task_reward{type=3,value=1600},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=20},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 31, 9) ->
	[#task_reward{type=3,value=1800},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=20},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 31, 10) ->
	[#task_reward{type=3,value=2000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=20},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 32, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 32, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 32, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 32, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 32, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 32, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 32, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 32, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 32, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 32, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 32, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 33, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 33, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 33, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 33, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 33, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 33, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 33, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 33, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 33, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 33, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 33, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 34, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 34, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 34, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 34, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 34, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 34, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 34, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 34, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 34, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 34, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 34, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 35, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 35, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 35, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 35, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 35, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 35, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 35, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 35, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 35, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 35, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 35, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 36, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 36, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 36, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 36, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 36, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 36, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 36, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 36, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 36, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 36, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 36, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 37, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 37, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 37, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 37, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 37, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 37, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 37, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 37, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 37, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 37, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 37, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 38, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 38, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 38, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 38, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 38, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 38, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 38, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 38, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 38, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 38, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 38, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 39, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 39, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 39, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 39, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 39, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 39, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 39, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 39, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 39, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 39, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 39, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 40, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 40, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 40, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 40, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 40, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 40, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 40, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 40, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 40, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 40, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 40, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 41, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 41, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 41, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 41, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 41, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 41, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 41, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 41, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 41, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 41, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 41, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 42, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 42, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 42, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 42, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 42, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 42, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 42, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 42, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 42, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 42, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 42, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 43, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 43, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 43, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 43, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 43, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 43, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 43, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 43, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 43, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 43, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 43, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 44, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 44, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 44, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 44, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 44, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 44, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 44, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 44, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 44, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 44, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 44, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 45, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 45, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 45, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 45, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 45, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 45, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 45, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 45, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 45, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 45, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 45, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 46, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 46, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 46, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 46, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 46, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 46, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 46, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 46, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 46, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 46, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 46, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 47, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 47, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 47, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 47, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 47, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 47, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 47, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 47, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 47, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 47, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 47, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 48, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 48, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 48, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 48, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 48, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 48, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 48, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 48, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 48, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 48, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 48, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 49, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 49, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 49, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 49, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 49, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 49, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 49, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 49, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 49, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 49, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 49, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(11, 50, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 50, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(11, 50, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(11, 50, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(11, 50, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(11, 50, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(11, 50, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(11, 50, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(11, 50, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(11, 50, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(11, 50, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 30, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 30, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 30, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 30, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 30, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 30, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 30, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 30, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 30, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 30, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 30, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 31, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 31, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 31, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 31, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 31, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 31, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 31, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 31, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 31, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 31, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 31, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 32, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 32, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 32, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 32, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 32, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 32, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 32, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 32, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 32, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 32, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 32, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 33, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 33, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 33, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 33, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 33, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 33, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 33, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 33, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 33, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 33, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 33, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 34, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 34, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 34, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 34, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 34, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 34, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 34, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 34, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 34, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 34, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 34, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 35, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 35, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 35, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 35, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 35, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 35, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 35, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 35, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 35, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 35, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 35, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 36, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 36, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 36, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 36, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 36, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 36, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 36, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 36, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 36, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 36, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 36, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 37, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 37, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 37, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 37, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 37, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 37, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 37, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 37, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 37, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 37, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 37, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 38, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 38, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 38, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 38, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 38, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 38, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 38, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 38, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 38, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 38, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 38, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 39, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 39, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 39, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 39, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 39, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 39, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 39, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 39, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 39, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 39, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 39, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 40, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 40, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 40, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 40, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 40, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 40, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 40, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 40, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 40, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 40, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 40, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 41, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 41, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 41, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 41, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 41, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 41, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 41, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 41, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 41, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 41, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 41, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 42, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 42, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 42, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 42, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 42, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 42, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 42, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 42, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 42, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 42, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 42, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 43, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 43, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 43, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 43, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 43, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 43, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 43, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 43, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 43, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 43, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 43, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 44, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 44, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 44, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 44, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 44, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 44, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 44, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 44, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 44, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 44, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 44, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 45, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 45, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 45, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 45, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 45, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 45, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 45, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 45, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 45, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 45, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 45, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 46, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 46, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 46, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 46, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 46, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 46, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 46, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 46, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 46, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 46, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 46, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 47, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 47, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 47, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 47, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 47, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 47, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 47, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 47, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 47, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 47, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 47, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 48, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 48, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 48, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 48, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 48, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 48, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 48, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 48, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 48, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 48, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 48, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 49, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 49, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 49, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 49, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 49, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 49, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 49, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 49, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 49, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 49, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 49, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder];

get_cyclic_task_reward(12, 50, 0) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 50, 1) ->
	[#task_reward{type=3,value=100},#task_reward{type=4,value=1},#task_reward{type=7,value=100},#task_reward{type=8,value=10},#task_reward{type=11,value=100},place_holder];

get_cyclic_task_reward(12, 50, 2) ->
	[#task_reward{type=3,value=200},#task_reward{type=4,value=1},#task_reward{type=7,value=200},#task_reward{type=8,value=10},#task_reward{type=11,value=200},place_holder];

get_cyclic_task_reward(12, 50, 3) ->
	[#task_reward{type=3,value=300},#task_reward{type=4,value=1},#task_reward{type=7,value=300},#task_reward{type=8,value=10},#task_reward{type=11,value=300},place_holder];

get_cyclic_task_reward(12, 50, 4) ->
	[#task_reward{type=3,value=400},#task_reward{type=4,value=1},#task_reward{type=7,value=400},#task_reward{type=8,value=10},#task_reward{type=11,value=400},place_holder];

get_cyclic_task_reward(12, 50, 5) ->
	[#task_reward{type=3,value=500},#task_reward{type=4,value=1},#task_reward{type=7,value=500},#task_reward{type=8,value=10},#task_reward{type=11,value=500},place_holder];

get_cyclic_task_reward(12, 50, 6) ->
	[#task_reward{type=3,value=600},#task_reward{type=4,value=1},#task_reward{type=7,value=600},#task_reward{type=8,value=10},#task_reward{type=11,value=600},place_holder];

get_cyclic_task_reward(12, 50, 7) ->
	[#task_reward{type=3,value=700},#task_reward{type=4,value=1},#task_reward{type=7,value=700},#task_reward{type=8,value=10},#task_reward{type=11,value=700},place_holder];

get_cyclic_task_reward(12, 50, 8) ->
	[#task_reward{type=3,value=800},#task_reward{type=4,value=1},#task_reward{type=7,value=800},#task_reward{type=8,value=10},#task_reward{type=11,value=800},place_holder];

get_cyclic_task_reward(12, 50, 9) ->
	[#task_reward{type=3,value=900},#task_reward{type=4,value=1},#task_reward{type=7,value=900},#task_reward{type=8,value=10},#task_reward{type=11,value=900},place_holder];

get_cyclic_task_reward(12, 50, 10) ->
	[#task_reward{type=3,value=1000},#task_reward{type=4,value=1},#task_reward{type=7,value=1000},#task_reward{type=8,value=10},#task_reward{type=11,value=1000},place_holder].


%%================================================
