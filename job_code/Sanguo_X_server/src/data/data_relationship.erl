-module(data_relationship).

-compile(export_all).

-include("common.hrl").

%% 
reach_pray_max(Count,Level)->
	Count >= 10+(Level div 10).

reach_prayed_max(Count,Level)->
	Count >= 10+(Level div 10).
max_pray_num(Level) ->
		10+(Level div 10).

	-spec max_prayed_num(integer()) -> integer().
	max_prayed_num(Level)->
		10+(Level div 10).

%% GZ0583(彭林) 14:41:37
%% 坚荣兄 好友祝福银币和历练奖励的公式做了相应变化 人数增长的不变
%% 每次祝福和被祝福的银币：
%% 银币=INT(2000+（1-相互之间的友之圣痕等级差/20）*友之圣痕等级*150)
%% 每次祝福和被祝福的历练：
%% 历练= INT(2000+（1-相互之间的友之圣痕等级差/20）*友之圣痕等级*100)


get(_Familiar,Holy1,Holy2,FriendHoly)->
	Money = 2000+(1-abs(Holy1-Holy2)/20) * FriendHoly * 150,
	Exp   = 2000+(1-abs(Holy1-Holy2)/20) * FriendHoly * 100,
	{round(Money),round(Exp)}.
	

%% %%we should use code to generate following info.
%% get_familiar_money_weigth(X)->
%% 	if
%% 		X < 499 -> 0;
%% 		X < 999 -> 0.05;
%% 		X < 1999 -> 0.1;
%% 		X < 2999 -> 0.15;
%% 		X < 3999 -> 0.2;
%% 		true -> 0.25
%% 	end.
%% 		
%% %% 
%% %% money_base(1)-> 100;
%% %% money_base(2)-> 200;
%% %% money_base(_Default) -> 0.
%% 
%% get_familiar_exp_weigth(X)->
%% 	if
%% 		X<499 -> 0;
%% 		X<999 -> 0.05;
%% 		X<1999 -> 0.1;
%% 		X<2999 -> 0.15;
%% 		X<3999 -> 0.2;
%% 		true -> 0.25
%% 	end.
%% %% 
%% %% exp_base(1)-> 100;
%% %% exp_base(2)-> 200;
%% %% exp_base(_Default)-> 0.


-spec get_max_send(Holy_level :: integer())->  integer().
get_max_send(Friend_holy_level) ->
%% 可祝福人数=10+int（友之圣痕/2）
	10+trunc(Friend_holy_level/2). 
	

-spec get_max_recv(Holy_level :: integer())->  integer().
get_max_recv(Friend_holy_level) ->
%% GZ0583(彭林) 16:51:43
%% 注：在30级以前，圣痕功能还没开启的时候， 默认主圣痕及友之圣痕等级为0.
%% GZ0583(彭林) 16:51:55
%% 可祝福数量=10+int（友之圣痕/2）
	10+trunc(Friend_holy_level/2).

-spec get_max_find_friend() -> integer().
get_max_find_friend() ->
	10.


%%GZ0807(方弘瑛) 11:37:23
%%空之圣痕16级开
get_min_level()->
	10.

get_recommend_num()->
	20.

get_item_drop_addition(Familiar) ->
%% 亲密度效果说明
%% 亲密度：1-49     陌路      掉率加成：1% 
%% 亲密度：50-99    相知      掉率加成：2% 
%% 亲密度：100-199  密友      掉率加成：5%
%% 亲密度：200-299  知己      掉率加成：8% 
%% 亲密度：300-399  知音      掉率加成：10% 
%% 亲密度：400-499  莫逆之交  掉率加成：15% 
	if
		Familiar == 0 -> 1;
		Familiar < 50 -> 1.01;
		Familiar < 100 -> 1.02;
		Familiar < 200 -> 1.05;
		Familiar < 300 -> 1.08;
		Familiar < 400 -> 1.1;
		true->1.15
%% 		Familiar < 500 -> 1.15
	end.

get_recommend_extend_factor() -> 1.

get_friend_page_size()->9.

%%================================================
%% 获取同等级银币,get_level_silver(等级) -> 银币
get_level_silver(1) -> 850;

get_level_silver(2) -> 900;

get_level_silver(3) -> 950;

get_level_silver(4) -> 1000;

get_level_silver(5) -> 1050;

get_level_silver(6) -> 1100;

get_level_silver(7) -> 1150;

get_level_silver(8) -> 1200;

get_level_silver(9) -> 1250;

get_level_silver(10) -> 1300;

get_level_silver(11) -> 1350;

get_level_silver(12) -> 1400;

get_level_silver(13) -> 1450;

get_level_silver(14) -> 1500;

get_level_silver(15) -> 1550;

get_level_silver(16) -> 1600;

get_level_silver(17) -> 1650;

get_level_silver(18) -> 1700;

get_level_silver(19) -> 1750;

get_level_silver(20) -> 1800;

get_level_silver(21) -> 1850;

get_level_silver(22) -> 1900;

get_level_silver(23) -> 1950;

get_level_silver(24) -> 2000;

get_level_silver(25) -> 2050;

get_level_silver(26) -> 2100;

get_level_silver(27) -> 2150;

get_level_silver(28) -> 2200;

get_level_silver(29) -> 2250;

get_level_silver(30) -> 2300;

get_level_silver(31) -> 2350;

get_level_silver(32) -> 2400;

get_level_silver(33) -> 2450;

get_level_silver(34) -> 2500;

get_level_silver(35) -> 2550;

get_level_silver(36) -> 2600;

get_level_silver(37) -> 2650;

get_level_silver(38) -> 2700;

get_level_silver(39) -> 2750;

get_level_silver(40) -> 2800;

get_level_silver(41) -> 2850;

get_level_silver(42) -> 2900;

get_level_silver(43) -> 2950;

get_level_silver(44) -> 3000;

get_level_silver(45) -> 3050;

get_level_silver(46) -> 3100;

get_level_silver(47) -> 3150;

get_level_silver(48) -> 3200;

get_level_silver(49) -> 3250;

get_level_silver(50) -> 3300;

get_level_silver(51) -> 3350;

get_level_silver(52) -> 3400;

get_level_silver(53) -> 3450;

get_level_silver(54) -> 3500;

get_level_silver(55) -> 3550;

get_level_silver(56) -> 3600;

get_level_silver(57) -> 3650;

get_level_silver(58) -> 3700;

get_level_silver(59) -> 3750;

get_level_silver(60) -> 3800;

get_level_silver(61) -> 3850;

get_level_silver(62) -> 3900;

get_level_silver(63) -> 3950;

get_level_silver(64) -> 4000;

get_level_silver(65) -> 4050;

get_level_silver(66) -> 4100;

get_level_silver(67) -> 4150;

get_level_silver(68) -> 4200;

get_level_silver(69) -> 4250;

get_level_silver(70) -> 4300;

get_level_silver(71) -> 4350;

get_level_silver(72) -> 4400;

get_level_silver(73) -> 4450;

get_level_silver(74) -> 4500;

get_level_silver(75) -> 4550;

get_level_silver(76) -> 4600;

get_level_silver(77) -> 4650;

get_level_silver(78) -> 4700;

get_level_silver(79) -> 4750;

get_level_silver(80) -> 4800;

get_level_silver(81) -> 4850;

get_level_silver(82) -> 4900;

get_level_silver(83) -> 4950;

get_level_silver(84) -> 5000;

get_level_silver(85) -> 5050;

get_level_silver(86) -> 5100;

get_level_silver(87) -> 5150;

get_level_silver(88) -> 5200;

get_level_silver(89) -> 5250;

get_level_silver(90) -> 5300;

get_level_silver(91) -> 5350;

get_level_silver(92) -> 5400;

get_level_silver(93) -> 5450;

get_level_silver(94) -> 5500;

get_level_silver(95) -> 5550;

get_level_silver(96) -> 5600;

get_level_silver(97) -> 5650;

get_level_silver(98) -> 5700;

get_level_silver(99) -> 5750;

get_level_silver(100) -> 5800.


%%================================================
%% 获取同等级经验,get_level_exp(等级)-> 经验
get_level_exp(1) -> 530;

get_level_exp(2) -> 530;

get_level_exp(3) -> 530;

get_level_exp(4) -> 530;

get_level_exp(5) -> 530;

get_level_exp(6) -> 530;

get_level_exp(7) -> 530;

get_level_exp(8) -> 530;

get_level_exp(9) -> 530;

get_level_exp(10) -> 530;

get_level_exp(11) -> 530;

get_level_exp(12) -> 530;

get_level_exp(13) -> 530;

get_level_exp(14) -> 530;

get_level_exp(15) -> 530;

get_level_exp(16) -> 530;

get_level_exp(17) -> 530;

get_level_exp(18) -> 530;

get_level_exp(19) -> 530;

get_level_exp(20) -> 530;

get_level_exp(21) -> 530;

get_level_exp(22) -> 530;

get_level_exp(23) -> 530;

get_level_exp(24) -> 530;

get_level_exp(25) -> 530;

get_level_exp(26) -> 530;

get_level_exp(27) -> 530;

get_level_exp(28) -> 530;

get_level_exp(29) -> 530;

get_level_exp(30) -> 530;

get_level_exp(31) -> 530;

get_level_exp(32) -> 550;

get_level_exp(33) -> 570;

get_level_exp(34) -> 590;

get_level_exp(35) -> 610;

get_level_exp(36) -> 630;

get_level_exp(37) -> 650;

get_level_exp(38) -> 670;

get_level_exp(39) -> 690;

get_level_exp(40) -> 710;

get_level_exp(41) -> 723;

get_level_exp(42) -> 761;

get_level_exp(43) -> 801;

get_level_exp(44) -> 844;

get_level_exp(45) -> 888;

get_level_exp(46) -> 935;

get_level_exp(47) -> 984;

get_level_exp(48) -> 1036;

get_level_exp(49) -> 1090;

get_level_exp(50) -> 1459;

get_level_exp(51) -> 1599;

get_level_exp(52) -> 1684;

get_level_exp(53) -> 1982;

get_level_exp(54) -> 2406;

get_level_exp(55) -> 2874;

get_level_exp(56) -> 3384;

get_level_exp(57) -> 3937;

get_level_exp(58) -> 4532;

get_level_exp(59) -> 5170;

get_level_exp(60) -> 5226;

get_level_exp(61) -> 5610;

get_level_exp(62) -> 5808;

get_level_exp(63) -> 6019;

get_level_exp(64) -> 6474;

get_level_exp(65) -> 6939;

get_level_exp(66) -> 7679;

get_level_exp(67) -> 8173;

get_level_exp(68) -> 8677;

get_level_exp(69) -> 9497;

get_level_exp(70) -> 9751;

get_level_exp(71) -> 9945;

get_level_exp(72) -> 10789;

get_level_exp(73) -> 11322;

get_level_exp(74) -> 11865;

get_level_exp(75) -> 12073;

get_level_exp(76) -> 12301;

get_level_exp(77) -> 12868;

get_level_exp(78) -> 13447;

get_level_exp(79) -> 14039;

get_level_exp(80) -> 13831;

get_level_exp(81) -> 14088;

get_level_exp(82) -> 14361;

get_level_exp(83) -> 14650;

get_level_exp(84) -> 15260;

get_level_exp(85) -> 16207;

get_level_exp(86) -> 16849;

get_level_exp(87) -> 17855;

get_level_exp(88) -> 18900;

get_level_exp(89) -> 19983;

get_level_exp(90) -> 19994;

get_level_exp(91) -> 21094;

get_level_exp(92) -> 22135;

get_level_exp(93) -> 23210;

get_level_exp(94) -> 24319;

get_level_exp(95) -> 25462;

get_level_exp(96) -> 26638;

get_level_exp(97) -> 27848;

get_level_exp(98) -> 29092;

get_level_exp(99) -> 30208;

get_level_exp(100) -> 32381.


%%================================================
