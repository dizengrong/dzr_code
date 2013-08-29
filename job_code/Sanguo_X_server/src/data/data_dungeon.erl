-module(data_dungeon).

-compile(export_all).

-include("common.hrl").

%% 获取副本地图（普通）中的所有进度
get_all_process1(1200) ->
	[{34,1},{35,1},{36,1},{37,2},{38,3},{39,3},{40,3},{41,4},{42,5},{43,5},{44,5},{45,6}];

get_all_process1(1400) ->
	[{91,1},{92,1},{93,1},{94,2},{95,3},{96,3},{97,3},{98,4},{99,5},{100,6},{101,7},{102,8}];

get_all_process1(1600) ->
	[{148,1},{149,1},{150,1},{151,2},{152,3},{153,3},{154,3},{155,4},{156,5},{157,5},{158,5},{159,6}].


%%================================================
%% 获取副本地图（精英）中的所有进度
get_all_process2(1200) ->
	[{46,1},{47,1},{48,1},{49,2},{50,3},{51,3},{52,3},{53,4},{54,5},{55,5},{56,5},{57,6}];

get_all_process2(1400) ->
	[{103,1},{104,1},{105,1},{106,2},{107,3},{108,3},{109,3},{110,4},{111,5},{112,6},{113,7},{114,8}];

get_all_process2(1600) ->
	[{160,1},{161,1},{162,1},{163,2},{164,3},{165,3},{166,3},{167,4},{168,5},{169,5},{170,5},{171,6}].


%%================================================
%%   获取副本中进度的信息  
process(34) -> 
	#dungeon_process{
		id               = 34,
		x                = 39,
		y                = 86,
		scope            = 0,
		monster_group_id = 9
	};

process(35) -> 
	#dungeon_process{
		id               = 35,
		x                = 39,
		y                = 91,
		scope            = 0,
		monster_group_id = 9
	};

process(36) -> 
	#dungeon_process{
		id               = 36,
		x                = 45,
		y                = 91,
		scope            = 0,
		monster_group_id = 9
	};

process(37) -> 
	#dungeon_process{
		id               = 37,
		x                = 53,
		y                = 84,
		scope            = 0,
		monster_group_id = 12
	};

process(38) -> 
	#dungeon_process{
		id               = 38,
		x                = 88,
		y                = 53,
		scope            = 0,
		monster_group_id = 10
	};

process(39) -> 
	#dungeon_process{
		id               = 39,
		x                = 87,
		y                = 58,
		scope            = 0,
		monster_group_id = 10
	};

process(40) -> 
	#dungeon_process{
		id               = 40,
		x                = 93,
		y                = 58,
		scope            = 0,
		monster_group_id = 10
	};

process(41) -> 
	#dungeon_process{
		id               = 41,
		x                = 103,
		y                = 53,
		scope            = 0,
		monster_group_id = 13
	};

process(42) -> 
	#dungeon_process{
		id               = 42,
		x                = 128,
		y                = 26,
		scope            = 0,
		monster_group_id = 11
	};

process(43) -> 
	#dungeon_process{
		id               = 43,
		x                = 127,
		y                = 29,
		scope            = 0,
		monster_group_id = 11
	};

process(44) -> 
	#dungeon_process{
		id               = 44,
		x                = 131,
		y                = 27,
		scope            = 0,
		monster_group_id = 11
	};

process(45) -> 
	#dungeon_process{
		id               = 45,
		x                = 145,
		y                = 20,
		scope            = 0,
		monster_group_id = 14
	};

process(46) -> 
	#dungeon_process{
		id               = 46,
		x                = 39,
		y                = 86,
		scope            = 0,
		monster_group_id = 9
	};

process(47) -> 
	#dungeon_process{
		id               = 47,
		x                = 39,
		y                = 91,
		scope            = 0,
		monster_group_id = 9
	};

process(48) -> 
	#dungeon_process{
		id               = 48,
		x                = 45,
		y                = 91,
		scope            = 0,
		monster_group_id = 9
	};

process(49) -> 
	#dungeon_process{
		id               = 49,
		x                = 53,
		y                = 84,
		scope            = 0,
		monster_group_id = 12
	};

process(50) -> 
	#dungeon_process{
		id               = 50,
		x                = 88,
		y                = 53,
		scope            = 0,
		monster_group_id = 10
	};

process(51) -> 
	#dungeon_process{
		id               = 51,
		x                = 87,
		y                = 58,
		scope            = 0,
		monster_group_id = 10
	};

process(52) -> 
	#dungeon_process{
		id               = 52,
		x                = 93,
		y                = 58,
		scope            = 0,
		monster_group_id = 10
	};

process(53) -> 
	#dungeon_process{
		id               = 53,
		x                = 103,
		y                = 53,
		scope            = 0,
		monster_group_id = 13
	};

process(54) -> 
	#dungeon_process{
		id               = 54,
		x                = 128,
		y                = 26,
		scope            = 0,
		monster_group_id = 11
	};

process(55) -> 
	#dungeon_process{
		id               = 55,
		x                = 127,
		y                = 29,
		scope            = 0,
		monster_group_id = 11
	};

process(56) -> 
	#dungeon_process{
		id               = 56,
		x                = 131,
		y                = 27,
		scope            = 0,
		monster_group_id = 11
	};

process(57) -> 
	#dungeon_process{
		id               = 57,
		x                = 145,
		y                = 20,
		scope            = 0,
		monster_group_id = 14
	};

process(91) -> 
	#dungeon_process{
		id               = 91,
		x                = 39,
		y                = 86,
		scope            = 0,
		monster_group_id = 26
	};

process(92) -> 
	#dungeon_process{
		id               = 92,
		x                = 39,
		y                = 91,
		scope            = 0,
		monster_group_id = 26
	};

process(93) -> 
	#dungeon_process{
		id               = 93,
		x                = 45,
		y                = 91,
		scope            = 0,
		monster_group_id = 26
	};

process(94) -> 
	#dungeon_process{
		id               = 94,
		x                = 53,
		y                = 84,
		scope            = 0,
		monster_group_id = 30
	};

process(95) -> 
	#dungeon_process{
		id               = 95,
		x                = 88,
		y                = 53,
		scope            = 0,
		monster_group_id = 27
	};

process(96) -> 
	#dungeon_process{
		id               = 96,
		x                = 87,
		y                = 58,
		scope            = 0,
		monster_group_id = 27
	};

process(97) -> 
	#dungeon_process{
		id               = 97,
		x                = 93,
		y                = 58,
		scope            = 0,
		monster_group_id = 27
	};

process(98) -> 
	#dungeon_process{
		id               = 98,
		x                = 103,
		y                = 53,
		scope            = 0,
		monster_group_id = 31
	};

process(99) -> 
	#dungeon_process{
		id               = 99,
		x                = 128,
		y                = 26,
		scope            = 0,
		monster_group_id = 28
	};

process(100) -> 
	#dungeon_process{
		id               = 100,
		x                = 127,
		y                = 29,
		scope            = 0,
		monster_group_id = 32
	};

process(101) -> 
	#dungeon_process{
		id               = 101,
		x                = 131,
		y                = 27,
		scope            = 0,
		monster_group_id = 29
	};

process(102) -> 
	#dungeon_process{
		id               = 102,
		x                = 145,
		y                = 20,
		scope            = 0,
		monster_group_id = 33
	};

process(103) -> 
	#dungeon_process{
		id               = 103,
		x                = 39,
		y                = 86,
		scope            = 0,
		monster_group_id = 26
	};

process(104) -> 
	#dungeon_process{
		id               = 104,
		x                = 39,
		y                = 91,
		scope            = 0,
		monster_group_id = 26
	};

process(105) -> 
	#dungeon_process{
		id               = 105,
		x                = 45,
		y                = 91,
		scope            = 0,
		monster_group_id = 26
	};

process(106) -> 
	#dungeon_process{
		id               = 106,
		x                = 53,
		y                = 84,
		scope            = 0,
		monster_group_id = 30
	};

process(107) -> 
	#dungeon_process{
		id               = 107,
		x                = 88,
		y                = 53,
		scope            = 0,
		monster_group_id = 27
	};

process(108) -> 
	#dungeon_process{
		id               = 108,
		x                = 87,
		y                = 58,
		scope            = 0,
		monster_group_id = 27
	};

process(109) -> 
	#dungeon_process{
		id               = 109,
		x                = 93,
		y                = 58,
		scope            = 0,
		monster_group_id = 27
	};

process(110) -> 
	#dungeon_process{
		id               = 110,
		x                = 103,
		y                = 53,
		scope            = 0,
		monster_group_id = 31
	};

process(111) -> 
	#dungeon_process{
		id               = 111,
		x                = 128,
		y                = 26,
		scope            = 0,
		monster_group_id = 28
	};

process(112) -> 
	#dungeon_process{
		id               = 112,
		x                = 127,
		y                = 29,
		scope            = 0,
		monster_group_id = 32
	};

process(113) -> 
	#dungeon_process{
		id               = 113,
		x                = 131,
		y                = 27,
		scope            = 0,
		monster_group_id = 29
	};

process(114) -> 
	#dungeon_process{
		id               = 114,
		x                = 145,
		y                = 20,
		scope            = 0,
		monster_group_id = 33
	};

process(148) -> 
	#dungeon_process{
		id               = 148,
		x                = 39,
		y                = 86,
		scope            = 0,
		monster_group_id = 44
	};

process(149) -> 
	#dungeon_process{
		id               = 149,
		x                = 39,
		y                = 91,
		scope            = 0,
		monster_group_id = 44
	};

process(150) -> 
	#dungeon_process{
		id               = 150,
		x                = 45,
		y                = 91,
		scope            = 0,
		monster_group_id = 44
	};

process(151) -> 
	#dungeon_process{
		id               = 151,
		x                = 53,
		y                = 84,
		scope            = 0,
		monster_group_id = 48
	};

process(152) -> 
	#dungeon_process{
		id               = 152,
		x                = 88,
		y                = 53,
		scope            = 0,
		monster_group_id = 45
	};

process(153) -> 
	#dungeon_process{
		id               = 153,
		x                = 87,
		y                = 58,
		scope            = 0,
		monster_group_id = 45
	};

process(154) -> 
	#dungeon_process{
		id               = 154,
		x                = 93,
		y                = 58,
		scope            = 0,
		monster_group_id = 45
	};

process(155) -> 
	#dungeon_process{
		id               = 155,
		x                = 103,
		y                = 53,
		scope            = 0,
		monster_group_id = 49
	};

process(156) -> 
	#dungeon_process{
		id               = 156,
		x                = 128,
		y                = 26,
		scope            = 0,
		monster_group_id = 46
	};

process(157) -> 
	#dungeon_process{
		id               = 157,
		x                = 127,
		y                = 29,
		scope            = 0,
		monster_group_id = 46
	};

process(158) -> 
	#dungeon_process{
		id               = 158,
		x                = 131,
		y                = 27,
		scope            = 0,
		monster_group_id = 46
	};

process(159) -> 
	#dungeon_process{
		id               = 159,
		x                = 145,
		y                = 20,
		scope            = 0,
		monster_group_id = 50
	};

process(160) -> 
	#dungeon_process{
		id               = 160,
		x                = 39,
		y                = 86,
		scope            = 0,
		monster_group_id = 44
	};

process(161) -> 
	#dungeon_process{
		id               = 161,
		x                = 39,
		y                = 91,
		scope            = 0,
		monster_group_id = 44
	};

process(162) -> 
	#dungeon_process{
		id               = 162,
		x                = 45,
		y                = 91,
		scope            = 0,
		monster_group_id = 44
	};

process(163) -> 
	#dungeon_process{
		id               = 163,
		x                = 53,
		y                = 84,
		scope            = 0,
		monster_group_id = 48
	};

process(164) -> 
	#dungeon_process{
		id               = 164,
		x                = 88,
		y                = 53,
		scope            = 0,
		monster_group_id = 45
	};

process(165) -> 
	#dungeon_process{
		id               = 165,
		x                = 87,
		y                = 58,
		scope            = 0,
		monster_group_id = 45
	};

process(166) -> 
	#dungeon_process{
		id               = 166,
		x                = 93,
		y                = 58,
		scope            = 0,
		monster_group_id = 45
	};

process(167) -> 
	#dungeon_process{
		id               = 167,
		x                = 103,
		y                = 53,
		scope            = 0,
		monster_group_id = 49
	};

process(168) -> 
	#dungeon_process{
		id               = 168,
		x                = 128,
		y                = 26,
		scope            = 0,
		monster_group_id = 46
	};

process(169) -> 
	#dungeon_process{
		id               = 169,
		x                = 127,
		y                = 29,
		scope            = 0,
		monster_group_id = 46
	};

process(170) -> 
	#dungeon_process{
		id               = 170,
		x                = 131,
		y                = 27,
		scope            = 0,
		monster_group_id = 46
	};

process(171) -> 
	#dungeon_process{
		id               = 171,
		x                = 145,
		y                = 20,
		scope            = 0,
		monster_group_id = 50
	}.


%%================================================
%% 根据副本id和购买次数获取购买需要的金币
get_buy_cost(1200, 1) -> 10;

get_buy_cost(1200, 2) -> 20;

get_buy_cost(1200, 3) -> 30;

get_buy_cost(1200, 4) -> 40;

get_buy_cost(1200, 5) -> 50;

get_buy_cost(1400, 1) -> 10;

get_buy_cost(1400, 2) -> 20;

get_buy_cost(1400, 3) -> 30;

get_buy_cost(1400, 4) -> 40;

get_buy_cost(1400, 5) -> 50;

get_buy_cost(1600, 1) -> 10;

get_buy_cost(1600, 2) -> 20;

get_buy_cost(1600, 3) -> 30;

get_buy_cost(1600, 4) -> 40;

get_buy_cost(1600, 5) -> 50.


%%================================================
%% 根据副本id获取能购买的最大次数
get_max_buy_times(1200) -> 5;

get_max_buy_times(1400) -> 5;

get_max_buy_times(1600) -> 5.


%%================================================
%% 获取副本的奖励:get_award(DungeonId, AwardId) -> {Item, Rate}
get_award(1200, 1) -> {280,10};
get_award(1200, 2) -> {283,5};
get_award(1200, 3) -> {286,1};
get_award(1200, 4) -> {293,1};
get_award(1200, 5) -> {296,1};
get_award(1200, 6) -> {283,1};
get_award(1200, 7) -> {294,1};
get_award(1200, 8) -> {295,1};

get_award(1400, 1) -> {280,1};
get_award(1400, 2) -> {285,1};
get_award(1400, 3) -> {288,1};
get_award(1400, 4) -> {293,1};
get_award(1400, 5) -> {296,1};
get_award(1400, 6) -> {283,1};
get_award(1400, 7) -> {294,1};
get_award(1400, 8) -> {295,1};

get_award(1600, 1) -> {280,1};
get_award(1600, 2) -> {285,1};
get_award(1600, 3) -> {288,1};
get_award(1600, 4) -> {293,1};
get_award(1600, 5) -> {296,1};
get_award(1600, 6) -> {283,1};
get_award(1600, 7) -> {294,1};
get_award(1600, 8) -> {295,1}.


%%================================================
%% 副本评分
get_battle_rank(A,B) when A =<3 andalso B =<0.1-> 1;

get_battle_rank(A,B) when A =<6 andalso B =<0.2-> 2;

get_battle_rank(A,B) when A =<8 andalso B =<0.3-> 3;

get_battle_rank(A,B) when A =<12 andalso B =<0.5-> 4;

get_battle_rank(A,B) when A =<16 andalso B =<0.7-> 5;

get_battle_rank(A,B) when A =<20 andalso B =<0.9-> 6;

get_battle_rank(A,B) when A =<1000 andalso B =<1-> 7.


%%================================================
