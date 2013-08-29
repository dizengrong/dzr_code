-module(data_dazuo).

-compile(export_all).



%% 活动时间加成：get_daily_rate(NowTime) when NowTime =< {打坐时间段} -> 加成系数
get_daily_rate(NowTime) when NowTime =< {0,0,0} -> 1;

get_daily_rate(NowTime) when NowTime =< {12,0,0} -> 1;

get_daily_rate(NowTime) when NowTime =< {12,30,0} -> 2;

get_daily_rate(NowTime) when NowTime =< {18,0,0} -> 1;

get_daily_rate(NowTime) when NowTime =< {18,30,0} -> 2;

get_daily_rate(NowTime) when NowTime =< {24,0,0} -> 1.


%%================================================
%% 根据等级获得基础经验：get_experience_by_level(等级) -> 基础经验
get_experience_by_level(1) -> 12;

get_experience_by_level(2) -> 12;

get_experience_by_level(3) -> 12;

get_experience_by_level(4) -> 12;

get_experience_by_level(5) -> 12;

get_experience_by_level(6) -> 12;

get_experience_by_level(7) -> 12;

get_experience_by_level(8) -> 12;

get_experience_by_level(9) -> 12;

get_experience_by_level(10) -> 13;

get_experience_by_level(11) -> 13;

get_experience_by_level(12) -> 13;

get_experience_by_level(13) -> 13;

get_experience_by_level(14) -> 13;

get_experience_by_level(15) -> 13;

get_experience_by_level(16) -> 13;

get_experience_by_level(17) -> 13;

get_experience_by_level(18) -> 13;

get_experience_by_level(19) -> 13;

get_experience_by_level(20) -> 15;

get_experience_by_level(21) -> 15;

get_experience_by_level(22) -> 15;

get_experience_by_level(23) -> 15;

get_experience_by_level(24) -> 15;

get_experience_by_level(25) -> 15;

get_experience_by_level(26) -> 15;

get_experience_by_level(27) -> 15;

get_experience_by_level(28) -> 15;

get_experience_by_level(29) -> 15;

get_experience_by_level(30) -> 19;

get_experience_by_level(31) -> 19;

get_experience_by_level(32) -> 19;

get_experience_by_level(33) -> 19;

get_experience_by_level(34) -> 20;

get_experience_by_level(35) -> 20;

get_experience_by_level(36) -> 20;

get_experience_by_level(37) -> 20;

get_experience_by_level(38) -> 20;

get_experience_by_level(39) -> 21;

get_experience_by_level(40) -> 21;

get_experience_by_level(41) -> 22;

get_experience_by_level(42) -> 25;

get_experience_by_level(43) -> 26;

get_experience_by_level(44) -> 27;

get_experience_by_level(45) -> 29;

get_experience_by_level(46) -> 30;

get_experience_by_level(47) -> 31;

get_experience_by_level(48) -> 33;

get_experience_by_level(49) -> 55;

get_experience_by_level(50) -> 79;

get_experience_by_level(51) -> 83;

get_experience_by_level(52) -> 91;

get_experience_by_level(53) -> 107;

get_experience_by_level(54) -> 130;

get_experience_by_level(55) -> 155;

get_experience_by_level(56) -> 183;

get_experience_by_level(57) -> 213;

get_experience_by_level(58) -> 245;

get_experience_by_level(59) -> 280;

get_experience_by_level(60) -> 301;

get_experience_by_level(61) -> 324;

get_experience_by_level(62) -> 335;

get_experience_by_level(63) -> 347;

get_experience_by_level(64) -> 374;

get_experience_by_level(65) -> 400;

get_experience_by_level(66) -> 443;

get_experience_by_level(67) -> 472;

get_experience_by_level(68) -> 501;

get_experience_by_level(69) -> 548;

get_experience_by_level(70) -> 598;

get_experience_by_level(71) -> 610;

get_experience_by_level(72) -> 662;

get_experience_by_level(73) -> 695;

get_experience_by_level(74) -> 728;

get_experience_by_level(75) -> 741;

get_experience_by_level(76) -> 755;

get_experience_by_level(77) -> 789;

get_experience_by_level(78) -> 825;

get_experience_by_level(79) -> 861;

get_experience_by_level(80) -> 899;

get_experience_by_level(81) -> 915;

get_experience_by_level(82) -> 933;

get_experience_by_level(83) -> 952;

get_experience_by_level(84) -> 991;

get_experience_by_level(85) -> 1053;

get_experience_by_level(86) -> 1095;

get_experience_by_level(87) -> 1160;

get_experience_by_level(88) -> 1228;

get_experience_by_level(89) -> 1298;

get_experience_by_level(90) -> 1371;

get_experience_by_level(91) -> 1447;

get_experience_by_level(92) -> 1518;

get_experience_by_level(93) -> 1592;

get_experience_by_level(94) -> 1668;

get_experience_by_level(95) -> 1747;

get_experience_by_level(96) -> 1827;

get_experience_by_level(97) -> 1910;

get_experience_by_level(98) -> 1996;

get_experience_by_level(99) -> 2072;

get_experience_by_level(100) -> 2221.


%%================================================
%% 活动时间加成：get_vip_rate(VIP类型) -> 加成系数
get_vip_rate(0) -> 1;

get_vip_rate(1) -> 1.2;

get_vip_rate(2) -> 1.3;

get_vip_rate(3) -> 1.5.


%%================================================
