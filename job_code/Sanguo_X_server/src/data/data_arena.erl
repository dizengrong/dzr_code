-module(data_arena).

-compile(export_all).



%% 根据玩家等级获取其翻牌的奖励：{军功低, 军功高, 银币低, 银币高}
get_five_battle_award(1) -> {8, 10,1000, 1300};

get_five_battle_award(2) -> {8, 10,1000, 1300};

get_five_battle_award(3) -> {8, 10,1000, 1300};

get_five_battle_award(4) -> {8, 10,1000, 1300};

get_five_battle_award(5) -> {8, 10,1000, 1300};

get_five_battle_award(6) -> {8, 10,1000, 1300};

get_five_battle_award(7) -> {8, 10,1000, 1300};

get_five_battle_award(8) -> {8, 10,1000, 1300};

get_five_battle_award(9) -> {8, 10,1000, 1300};

get_five_battle_award(10) -> {8, 10,1000, 1300};

get_five_battle_award(11) -> {8, 10,1000, 1300};

get_five_battle_award(12) -> {8, 10,1000, 1300};

get_five_battle_award(13) -> {8, 10,1000, 1300};

get_five_battle_award(14) -> {8, 10,1000, 1300};

get_five_battle_award(15) -> {8, 10,1000, 1300};

get_five_battle_award(16) -> {8, 10,1000, 1300};

get_five_battle_award(17) -> {8, 10,1000, 1300};

get_five_battle_award(18) -> {8, 10,1000, 1300};

get_five_battle_award(19) -> {8, 10,1000, 1300};

get_five_battle_award(20) -> {8, 10,1000, 1300};

get_five_battle_award(21) -> {8, 10,1000, 1300};

get_five_battle_award(22) -> {8, 10,1000, 1300};

get_five_battle_award(23) -> {8, 10,1000, 1300};

get_five_battle_award(24) -> {8, 10,1000, 1300};

get_five_battle_award(25) -> {8, 10,1000, 1300};

get_five_battle_award(26) -> {10, 13,1000, 1300};

get_five_battle_award(27) -> {10, 13,1000, 1300};

get_five_battle_award(28) -> {10, 13,1000, 1300};

get_five_battle_award(29) -> {10, 13,1000, 1300};

get_five_battle_award(30) -> {10, 13,1500, 1950};

get_five_battle_award(31) -> {12, 15,1500, 1950};

get_five_battle_award(32) -> {12, 15,1500, 1950};

get_five_battle_award(33) -> {12, 15,1500, 1950};

get_five_battle_award(34) -> {12, 15,1500, 1950};

get_five_battle_award(35) -> {12, 15,1500, 1950};

get_five_battle_award(36) -> {14, 18,2000, 2600};

get_five_battle_award(37) -> {14, 18,2000, 2600};

get_five_battle_award(38) -> {14, 18,2000, 2600};

get_five_battle_award(39) -> {14, 18,2000, 2600};

get_five_battle_award(40) -> {14, 18,2000, 2600};

get_five_battle_award(41) -> {16, 20,2500, 3250};

get_five_battle_award(42) -> {16, 20,2500, 3250};

get_five_battle_award(43) -> {16, 20,2500, 3250};

get_five_battle_award(44) -> {16, 20,2500, 3250};

get_five_battle_award(45) -> {16, 20,2500, 3250};

get_five_battle_award(46) -> {18, 23,3000, 3900};

get_five_battle_award(47) -> {18, 23,3000, 3900};

get_five_battle_award(48) -> {18, 23,3000, 3900};

get_five_battle_award(49) -> {18, 23,3000, 3900};

get_five_battle_award(50) -> {18, 23,3000, 3900};

get_five_battle_award(51) -> {20, 25,3500, 4550};

get_five_battle_award(52) -> {20, 25,3500, 4550};

get_five_battle_award(53) -> {20, 25,3500, 4550};

get_five_battle_award(54) -> {20, 25,3500, 4550};

get_five_battle_award(55) -> {20, 25,3500, 4550};

get_five_battle_award(56) -> {22, 28,4000, 5200};

get_five_battle_award(57) -> {22, 28,4000, 5200};

get_five_battle_award(58) -> {22, 28,4000, 5200};

get_five_battle_award(59) -> {22, 28,4000, 5200};

get_five_battle_award(60) -> {22, 28,4000, 5200};

get_five_battle_award(61) -> {24, 30,4500, 5850};

get_five_battle_award(62) -> {24, 30,4500, 5850};

get_five_battle_award(63) -> {24, 30,4500, 5850};

get_five_battle_award(64) -> {24, 30,4500, 5850};

get_five_battle_award(65) -> {24, 30,4500, 5850};

get_five_battle_award(66) -> {26, 33,5000, 6500};

get_five_battle_award(67) -> {26, 33,5000, 6500};

get_five_battle_award(68) -> {26, 33,5000, 6500};

get_five_battle_award(69) -> {26, 33,5000, 6500};

get_five_battle_award(70) -> {26, 33,5000, 6500};

get_five_battle_award(71) -> {28, 35,5500, 7150};

get_five_battle_award(72) -> {28, 35,5500, 7150};

get_five_battle_award(73) -> {28, 35,5500, 7150};

get_five_battle_award(74) -> {28, 35,5500, 7150};

get_five_battle_award(75) -> {28, 35,5500, 7150};

get_five_battle_award(76) -> {30, 38,6000, 7800};

get_five_battle_award(77) -> {30, 38,6000, 7800};

get_five_battle_award(78) -> {30, 38,6000, 7800};

get_five_battle_award(79) -> {30, 38,6000, 7800};

get_five_battle_award(80) -> {30, 38,6000, 7800};

get_five_battle_award(81) -> {32, 40,6500, 8450};

get_five_battle_award(82) -> {32, 40,6500, 8450};

get_five_battle_award(83) -> {32, 40,6500, 8450};

get_five_battle_award(84) -> {32, 40,6500, 8450};

get_five_battle_award(85) -> {32, 40,6500, 8450};

get_five_battle_award(86) -> {34, 43,7000, 9100};

get_five_battle_award(87) -> {34, 43,7000, 9100};

get_five_battle_award(88) -> {34, 43,7000, 9100};

get_five_battle_award(89) -> {34, 43,7000, 9100};

get_five_battle_award(90) -> {34, 43,7000, 9100};

get_five_battle_award(91) -> {36, 45,7500, 9750};

get_five_battle_award(92) -> {36, 45,7500, 9750};

get_five_battle_award(93) -> {36, 45,7500, 9750};

get_five_battle_award(94) -> {36, 45,7500, 9750};

get_five_battle_award(95) -> {36, 45,7500, 9750};

get_five_battle_award(96) -> {38, 48,8000, 10400};

get_five_battle_award(97) -> {38, 48,8000, 10400};

get_five_battle_award(98) -> {38, 48,8000, 10400};

get_five_battle_award(99) -> {38, 48,8000, 10400};

get_five_battle_award(100) -> {38, 48,8000, 10400}.


%%================================================
%% 获取英雄榜总数
get_heroes_count()-> 20.

%%================================================
%% 获取英雄榜每页数
get_heroes_num_per_page()-> 6.

%%================================================
%% 获取每天挑战次数
get_daily_challenge_times()-> 15.

%%================================================
%% 根据第一名玩家等级获取每天宝箱奖励:{银币，军功}
get_arena_daily_silver(1) -> 100000;

get_arena_daily_silver(2) -> 100000;

get_arena_daily_silver(3) -> 100000;

get_arena_daily_silver(4) -> 100000;

get_arena_daily_silver(5) -> 100000;

get_arena_daily_silver(6) -> 100000;

get_arena_daily_silver(7) -> 100000;

get_arena_daily_silver(8) -> 100000;

get_arena_daily_silver(9) -> 100000;

get_arena_daily_silver(10) -> 100000;

get_arena_daily_silver(11) -> 100000;

get_arena_daily_silver(12) -> 100000;

get_arena_daily_silver(13) -> 100000;

get_arena_daily_silver(14) -> 100000;

get_arena_daily_silver(15) -> 100000;

get_arena_daily_silver(16) -> 100000;

get_arena_daily_silver(17) -> 100000;

get_arena_daily_silver(18) -> 100000;

get_arena_daily_silver(19) -> 100000;

get_arena_daily_silver(20) -> 100000;

get_arena_daily_silver(21) -> 100000;

get_arena_daily_silver(22) -> 100000;

get_arena_daily_silver(23) -> 100000;

get_arena_daily_silver(24) -> 100000;

get_arena_daily_silver(25) -> 100000;

get_arena_daily_silver(26) -> 120000;

get_arena_daily_silver(27) -> 120000;

get_arena_daily_silver(28) -> 120000;

get_arena_daily_silver(29) -> 120000;

get_arena_daily_silver(30) -> 150000;

get_arena_daily_silver(31) -> 150000;

get_arena_daily_silver(32) -> 150000;

get_arena_daily_silver(33) -> 150000;

get_arena_daily_silver(34) -> 150000;

get_arena_daily_silver(35) -> 150000;

get_arena_daily_silver(36) -> 180000;

get_arena_daily_silver(37) -> 180000;

get_arena_daily_silver(38) -> 180000;

get_arena_daily_silver(39) -> 180000;

get_arena_daily_silver(40) -> 180000;

get_arena_daily_silver(41) -> 200000;

get_arena_daily_silver(42) -> 200000;

get_arena_daily_silver(43) -> 200000;

get_arena_daily_silver(44) -> 200000;

get_arena_daily_silver(45) -> 200000;

get_arena_daily_silver(46) -> 230000;

get_arena_daily_silver(47) -> 230000;

get_arena_daily_silver(48) -> 230000;

get_arena_daily_silver(49) -> 230000;

get_arena_daily_silver(50) -> 230000;

get_arena_daily_silver(51) -> 260000;

get_arena_daily_silver(52) -> 260000;

get_arena_daily_silver(53) -> 260000;

get_arena_daily_silver(54) -> 260000;

get_arena_daily_silver(55) -> 260000;

get_arena_daily_silver(56) -> 300000;

get_arena_daily_silver(57) -> 300000;

get_arena_daily_silver(58) -> 300000;

get_arena_daily_silver(59) -> 300000;

get_arena_daily_silver(60) -> 300000;

get_arena_daily_silver(61) -> 350000;

get_arena_daily_silver(62) -> 350000;

get_arena_daily_silver(63) -> 350000;

get_arena_daily_silver(64) -> 350000;

get_arena_daily_silver(65) -> 350000;

get_arena_daily_silver(66) -> 400000;

get_arena_daily_silver(67) -> 400000;

get_arena_daily_silver(68) -> 400000;

get_arena_daily_silver(69) -> 400000;

get_arena_daily_silver(70) -> 400000;

get_arena_daily_silver(71) -> 450000;

get_arena_daily_silver(72) -> 450000;

get_arena_daily_silver(73) -> 450000;

get_arena_daily_silver(74) -> 450000;

get_arena_daily_silver(75) -> 450000;

get_arena_daily_silver(76) -> 500000;

get_arena_daily_silver(77) -> 500000;

get_arena_daily_silver(78) -> 500000;

get_arena_daily_silver(79) -> 500000;

get_arena_daily_silver(80) -> 500000;

get_arena_daily_silver(81) -> 550000;

get_arena_daily_silver(82) -> 550000;

get_arena_daily_silver(83) -> 550000;

get_arena_daily_silver(84) -> 550000;

get_arena_daily_silver(85) -> 600000;

get_arena_daily_silver(86) -> 600000;

get_arena_daily_silver(87) -> 600000;

get_arena_daily_silver(88) -> 650000;

get_arena_daily_silver(89) -> 650000;

get_arena_daily_silver(90) -> 650000;

get_arena_daily_silver(91) -> 700000;

get_arena_daily_silver(92) -> 700000;

get_arena_daily_silver(93) -> 700000;

get_arena_daily_silver(94) -> 700000;

get_arena_daily_silver(95) -> 750000;

get_arena_daily_silver(96) -> 750000;

get_arena_daily_silver(97) -> 750000;

get_arena_daily_silver(98) -> 800000;

get_arena_daily_silver(99) -> 800000;

get_arena_daily_silver(100) -> 800000.


%%================================================
%% 系统发奖时间
get_system(22) -> {22, 0, 0}.

%%================================================
