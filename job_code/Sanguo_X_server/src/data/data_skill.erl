-module(data_skill).

-compile(export_all).

-include("common.hrl").

%% 获取所有同一类技能属性id的普通技能
all_normal_skill(201) ->
	[201001, 201010, 201009, 201008, 201007, 201006, 201005, 201004, 201003, 201002];

all_normal_skill(202) ->
	[202010, 202009, 202008, 202007, 202006, 202005, 202004, 202003, 202002, 202001];

all_normal_skill(203) ->
	[203007, 203008, 203009, 203010, 203006, 203005, 203004, 203003, 203002, 203001];

all_normal_skill(204) ->
	[204007, 204008, 204009, 204010, 204006, 204005, 204004, 204003, 204002, 204001];

all_normal_skill(205) ->
	[205007, 205008, 205009, 205010, 205006, 205005, 205004, 205003, 205002, 205001];

all_normal_skill(206) ->
	[206007, 206008, 206009, 206010, 206006, 206005, 206004, 206003, 206002, 206001];

all_normal_skill(207) ->
	[207007, 207008, 207009, 207010, 207006, 207005, 207004, 207003, 207002, 207001];

all_normal_skill(208) ->
	[208007, 208008, 208009, 208010, 208006, 208005, 208004, 208003, 208002, 208001];

all_normal_skill(209) ->
	[209007, 209008, 209009, 209010, 209006, 209005, 209004, 209003, 209002, 209001];

all_normal_skill(210) ->
	[210007, 210008, 210009, 210010, 210006, 210005, 210004, 210003, 210002, 210001];

all_normal_skill(211) ->
	[211007, 211008, 211009, 211010, 211006, 211005, 211004, 211003, 211002, 211001];

all_normal_skill(212) ->
	[212007, 212008, 212009, 212010, 212006, 212005, 212004, 212003, 212002, 212001];

all_normal_skill(213) ->
	[213007, 213008, 213009, 213010, 213006, 213005, 213004, 213003, 213002, 213001];

all_normal_skill(214) ->
	[214007, 214008, 214009, 214010, 214006, 214005, 214004, 214003, 214002, 214001];

all_normal_skill(215) ->
	[215007, 215008, 215009, 215010, 215006, 215005, 215004, 215003, 215002, 215001];

all_normal_skill(216) ->
	[216007, 216008, 216009, 216010, 216006, 216005, 216004, 216003, 216002, 216001];

all_normal_skill(217) ->
	[217007, 217008, 217009, 217010, 217006, 217005, 217004, 217003, 217002, 217001];

all_normal_skill(218) ->
	[218007, 218008, 218009, 218010, 218006, 218005, 218004, 218003, 218002, 218001];

all_normal_skill(219) ->
	[219007, 219008, 219009, 219010, 219006, 219005, 219004, 219003, 219002, 219001];

all_normal_skill(220) ->
	[220007, 220008, 220009, 220010, 220006, 220005, 220004, 220003, 220002, 220001];

all_normal_skill(221) ->
	[221007, 221008, 221009, 221010, 221006, 221005, 221004, 221003, 221002, 221001];

all_normal_skill(222) ->
	[222009, 222008, 222007, 222006, 222005, 222004, 222003, 222002, 222001, 222010].


%%================================================
%% 获取技能书对应的属性
get_skill_book_exp(262) ->
	10;

get_skill_book_exp(263) ->
	100;

get_skill_book_exp(264) ->
	200;

get_skill_book_exp(265) ->
	300;

get_skill_book_exp(266) ->
	400;

get_skill_book_exp(267) ->
	500;

get_skill_book_exp(268) ->
	600;

get_skill_book_exp(269) ->
	700;

get_skill_book_exp(270) ->
	800;

get_skill_book_exp(271) ->
	900.


%%================================================
%% 获取技能书对应的属性
get_use_skillbook_cost(262) ->
	6000;

get_use_skillbook_cost(263) ->
	10000;

get_use_skillbook_cost(264) ->
	15000;

get_use_skillbook_cost(265) ->
	20000;

get_use_skillbook_cost(266) ->
	30000;

get_use_skillbook_cost(267) ->
	40000;

get_use_skillbook_cost(268) ->
	50000;

get_use_skillbook_cost(269) ->
	70000;

get_use_skillbook_cost(270) ->
	80000;

get_use_skillbook_cost(271) ->
	100000;

get_use_skillbook_cost(413) ->
	50000.


%%================================================
%% 获取所有的技能属性分类id
get_all_skill_class() ->
	[201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222].


%%================================================
%% 根据技能属性id获取其概率
get_skill_class_rate(201) -> 10;

get_skill_class_rate(202) -> 10;

get_skill_class_rate(203) -> 10;

get_skill_class_rate(204) -> 10;

get_skill_class_rate(205) -> 10;

get_skill_class_rate(206) -> 10;

get_skill_class_rate(207) -> 10;

get_skill_class_rate(208) -> 10;

get_skill_class_rate(209) -> 10;

get_skill_class_rate(210) -> 10;

get_skill_class_rate(211) -> 10;

get_skill_class_rate(212) -> 20;

get_skill_class_rate(213) -> 10;

get_skill_class_rate(214) -> 10;

get_skill_class_rate(215) -> 10;

get_skill_class_rate(216) -> 10;

get_skill_class_rate(217) -> 10;

get_skill_class_rate(218) -> 30;

get_skill_class_rate(219) -> 10;

get_skill_class_rate(220) -> 10;

get_skill_class_rate(221) -> 10;

get_skill_class_rate(222) -> 50.


%%================================================
%% 根据技能id获取器刷出的概率
get_skill_rate(100001) -> 0;

get_skill_rate(101001) -> 0;

get_skill_rate(102001) -> 0;

get_skill_rate(103001) -> 0;

get_skill_rate(104001) -> 0;

get_skill_rate(104002) -> 0;

get_skill_rate(104003) -> 0;

get_skill_rate(104004) -> 0;

get_skill_rate(104005) -> 0;

get_skill_rate(104006) -> 0;

get_skill_rate(104007) -> 0;

get_skill_rate(104008) -> 0;

get_skill_rate(104009) -> 0;

get_skill_rate(104010) -> 0;

get_skill_rate(105001) -> 0;

get_skill_rate(105002) -> 0;

get_skill_rate(105003) -> 0;

get_skill_rate(105004) -> 0;

get_skill_rate(105005) -> 0;

get_skill_rate(105006) -> 0;

get_skill_rate(105007) -> 0;

get_skill_rate(105008) -> 0;

get_skill_rate(105009) -> 0;

get_skill_rate(105010) -> 0;

get_skill_rate(106001) -> 0;

get_skill_rate(106002) -> 0;

get_skill_rate(106003) -> 0;

get_skill_rate(106004) -> 0;

get_skill_rate(106005) -> 0;

get_skill_rate(106006) -> 0;

get_skill_rate(106007) -> 0;

get_skill_rate(106008) -> 0;

get_skill_rate(106009) -> 0;

get_skill_rate(106010) -> 0;

get_skill_rate(107001) -> 0;

get_skill_rate(107002) -> 0;

get_skill_rate(107003) -> 0;

get_skill_rate(107004) -> 0;

get_skill_rate(107005) -> 0;

get_skill_rate(107006) -> 0;

get_skill_rate(107007) -> 0;

get_skill_rate(107008) -> 0;

get_skill_rate(107009) -> 0;

get_skill_rate(107010) -> 0;

get_skill_rate(108001) -> 0;

get_skill_rate(108002) -> 0;

get_skill_rate(108003) -> 0;

get_skill_rate(108004) -> 0;

get_skill_rate(108005) -> 0;

get_skill_rate(108006) -> 0;

get_skill_rate(108007) -> 0;

get_skill_rate(108008) -> 0;

get_skill_rate(108009) -> 0;

get_skill_rate(108010) -> 0;

get_skill_rate(109001) -> 0;

get_skill_rate(109002) -> 0;

get_skill_rate(109003) -> 0;

get_skill_rate(109004) -> 0;

get_skill_rate(109005) -> 0;

get_skill_rate(109006) -> 0;

get_skill_rate(109007) -> 0;

get_skill_rate(109008) -> 0;

get_skill_rate(109009) -> 0;

get_skill_rate(109010) -> 0;

get_skill_rate(110001) -> 0;

get_skill_rate(110002) -> 0;

get_skill_rate(110003) -> 0;

get_skill_rate(110004) -> 0;

get_skill_rate(110005) -> 0;

get_skill_rate(110006) -> 0;

get_skill_rate(110007) -> 0;

get_skill_rate(110008) -> 0;

get_skill_rate(110009) -> 0;

get_skill_rate(110010) -> 0;

get_skill_rate(111001) -> 0;

get_skill_rate(111002) -> 0;

get_skill_rate(111003) -> 0;

get_skill_rate(111004) -> 0;

get_skill_rate(111005) -> 0;

get_skill_rate(111006) -> 0;

get_skill_rate(111007) -> 0;

get_skill_rate(111008) -> 0;

get_skill_rate(111009) -> 0;

get_skill_rate(111010) -> 0;

get_skill_rate(112001) -> 0;

get_skill_rate(112002) -> 0;

get_skill_rate(112003) -> 0;

get_skill_rate(112004) -> 0;

get_skill_rate(112005) -> 0;

get_skill_rate(112006) -> 0;

get_skill_rate(112007) -> 0;

get_skill_rate(112008) -> 0;

get_skill_rate(112009) -> 0;

get_skill_rate(112010) -> 0;

get_skill_rate(113001) -> 0;

get_skill_rate(113002) -> 0;

get_skill_rate(113003) -> 0;

get_skill_rate(113004) -> 0;

get_skill_rate(113005) -> 0;

get_skill_rate(113006) -> 0;

get_skill_rate(113007) -> 0;

get_skill_rate(113008) -> 0;

get_skill_rate(113009) -> 0;

get_skill_rate(113010) -> 0;

get_skill_rate(114001) -> 0;

get_skill_rate(114002) -> 0;

get_skill_rate(114003) -> 0;

get_skill_rate(114004) -> 0;

get_skill_rate(114005) -> 0;

get_skill_rate(114006) -> 0;

get_skill_rate(114007) -> 0;

get_skill_rate(114008) -> 0;

get_skill_rate(114009) -> 0;

get_skill_rate(114010) -> 0;

get_skill_rate(115001) -> 0;

get_skill_rate(115002) -> 0;

get_skill_rate(115003) -> 0;

get_skill_rate(115004) -> 0;

get_skill_rate(115005) -> 0;

get_skill_rate(115006) -> 0;

get_skill_rate(115007) -> 0;

get_skill_rate(115008) -> 0;

get_skill_rate(115009) -> 0;

get_skill_rate(115010) -> 0;

get_skill_rate(116001) -> 0;

get_skill_rate(116002) -> 0;

get_skill_rate(116003) -> 0;

get_skill_rate(116004) -> 0;

get_skill_rate(116005) -> 0;

get_skill_rate(116006) -> 0;

get_skill_rate(116007) -> 0;

get_skill_rate(116008) -> 0;

get_skill_rate(116009) -> 0;

get_skill_rate(116010) -> 0;

get_skill_rate(117001) -> 0;

get_skill_rate(117002) -> 0;

get_skill_rate(117003) -> 0;

get_skill_rate(117004) -> 0;

get_skill_rate(117005) -> 0;

get_skill_rate(117006) -> 0;

get_skill_rate(117007) -> 0;

get_skill_rate(117008) -> 0;

get_skill_rate(117009) -> 0;

get_skill_rate(117010) -> 0;

get_skill_rate(118001) -> 0;

get_skill_rate(118002) -> 0;

get_skill_rate(118003) -> 0;

get_skill_rate(118004) -> 0;

get_skill_rate(118005) -> 0;

get_skill_rate(118006) -> 0;

get_skill_rate(118007) -> 0;

get_skill_rate(118008) -> 0;

get_skill_rate(118009) -> 0;

get_skill_rate(118010) -> 0;

get_skill_rate(201001) -> 3;

get_skill_rate(201002) -> 2;

get_skill_rate(201003) -> 1;

get_skill_rate(201004) -> 0;

get_skill_rate(201005) -> 0;

get_skill_rate(201006) -> 0;

get_skill_rate(201007) -> 0;

get_skill_rate(201008) -> 0;

get_skill_rate(201009) -> 0;

get_skill_rate(201010) -> 0;

get_skill_rate(202001) -> 3;

get_skill_rate(202002) -> 2;

get_skill_rate(202003) -> 1;

get_skill_rate(202004) -> 0;

get_skill_rate(202005) -> 0;

get_skill_rate(202006) -> 0;

get_skill_rate(202007) -> 0;

get_skill_rate(202008) -> 0;

get_skill_rate(202009) -> 0;

get_skill_rate(202010) -> 0;

get_skill_rate(203001) -> 3;

get_skill_rate(203002) -> 2;

get_skill_rate(203003) -> 1;

get_skill_rate(203004) -> 0;

get_skill_rate(203005) -> 0;

get_skill_rate(203006) -> 0;

get_skill_rate(203007) -> 0;

get_skill_rate(203008) -> 0;

get_skill_rate(203009) -> 0;

get_skill_rate(203010) -> 0;

get_skill_rate(204001) -> 3;

get_skill_rate(204002) -> 2;

get_skill_rate(204003) -> 1;

get_skill_rate(204004) -> 0;

get_skill_rate(204005) -> 0;

get_skill_rate(204006) -> 0;

get_skill_rate(204007) -> 0;

get_skill_rate(204008) -> 0;

get_skill_rate(204009) -> 0;

get_skill_rate(204010) -> 0;

get_skill_rate(205001) -> 3;

get_skill_rate(205002) -> 2;

get_skill_rate(205003) -> 1;

get_skill_rate(205004) -> 0;

get_skill_rate(205005) -> 0;

get_skill_rate(205006) -> 0;

get_skill_rate(205007) -> 0;

get_skill_rate(205008) -> 0;

get_skill_rate(205009) -> 0;

get_skill_rate(205010) -> 0;

get_skill_rate(206001) -> 3;

get_skill_rate(206002) -> 2;

get_skill_rate(206003) -> 1;

get_skill_rate(206004) -> 0;

get_skill_rate(206005) -> 0;

get_skill_rate(206006) -> 0;

get_skill_rate(206007) -> 0;

get_skill_rate(206008) -> 0;

get_skill_rate(206009) -> 0;

get_skill_rate(206010) -> 0;

get_skill_rate(207001) -> 3;

get_skill_rate(207002) -> 2;

get_skill_rate(207003) -> 1;

get_skill_rate(207004) -> 0;

get_skill_rate(207005) -> 0;

get_skill_rate(207006) -> 0;

get_skill_rate(207007) -> 0;

get_skill_rate(207008) -> 0;

get_skill_rate(207009) -> 0;

get_skill_rate(207010) -> 0;

get_skill_rate(208001) -> 3;

get_skill_rate(208002) -> 2;

get_skill_rate(208003) -> 1;

get_skill_rate(208004) -> 0;

get_skill_rate(208005) -> 0;

get_skill_rate(208006) -> 0;

get_skill_rate(208007) -> 0;

get_skill_rate(208008) -> 0;

get_skill_rate(208009) -> 0;

get_skill_rate(208010) -> 0;

get_skill_rate(209001) -> 3;

get_skill_rate(209002) -> 2;

get_skill_rate(209003) -> 1;

get_skill_rate(209004) -> 0;

get_skill_rate(209005) -> 0;

get_skill_rate(209006) -> 0;

get_skill_rate(209007) -> 0;

get_skill_rate(209008) -> 0;

get_skill_rate(209009) -> 0;

get_skill_rate(209010) -> 0;

get_skill_rate(210001) -> 3;

get_skill_rate(210002) -> 2;

get_skill_rate(210003) -> 1;

get_skill_rate(210004) -> 0;

get_skill_rate(210005) -> 0;

get_skill_rate(210006) -> 0;

get_skill_rate(210007) -> 0;

get_skill_rate(210008) -> 0;

get_skill_rate(210009) -> 0;

get_skill_rate(210010) -> 0;

get_skill_rate(211001) -> 3;

get_skill_rate(211002) -> 2;

get_skill_rate(211003) -> 1;

get_skill_rate(211004) -> 0;

get_skill_rate(211005) -> 0;

get_skill_rate(211006) -> 0;

get_skill_rate(211007) -> 0;

get_skill_rate(211008) -> 0;

get_skill_rate(211009) -> 0;

get_skill_rate(211010) -> 0;

get_skill_rate(212001) -> 3;

get_skill_rate(212002) -> 2;

get_skill_rate(212003) -> 1;

get_skill_rate(212004) -> 0;

get_skill_rate(212005) -> 0;

get_skill_rate(212006) -> 0;

get_skill_rate(212007) -> 0;

get_skill_rate(212008) -> 0;

get_skill_rate(212009) -> 0;

get_skill_rate(212010) -> 0;

get_skill_rate(213001) -> 3;

get_skill_rate(213002) -> 2;

get_skill_rate(213003) -> 1;

get_skill_rate(213004) -> 0;

get_skill_rate(213005) -> 0;

get_skill_rate(213006) -> 0;

get_skill_rate(213007) -> 0;

get_skill_rate(213008) -> 0;

get_skill_rate(213009) -> 0;

get_skill_rate(213010) -> 0;

get_skill_rate(214001) -> 3;

get_skill_rate(214002) -> 2;

get_skill_rate(214003) -> 1;

get_skill_rate(214004) -> 0;

get_skill_rate(214005) -> 0;

get_skill_rate(214006) -> 0;

get_skill_rate(214007) -> 0;

get_skill_rate(214008) -> 0;

get_skill_rate(214009) -> 0;

get_skill_rate(214010) -> 0;

get_skill_rate(215001) -> 3;

get_skill_rate(215002) -> 2;

get_skill_rate(215003) -> 1;

get_skill_rate(215004) -> 0;

get_skill_rate(215005) -> 0;

get_skill_rate(215006) -> 0;

get_skill_rate(215007) -> 0;

get_skill_rate(215008) -> 0;

get_skill_rate(215009) -> 0;

get_skill_rate(215010) -> 0;

get_skill_rate(216001) -> 3;

get_skill_rate(216002) -> 2;

get_skill_rate(216003) -> 1;

get_skill_rate(216004) -> 0;

get_skill_rate(216005) -> 0;

get_skill_rate(216006) -> 0;

get_skill_rate(216007) -> 0;

get_skill_rate(216008) -> 0;

get_skill_rate(216009) -> 0;

get_skill_rate(216010) -> 0;

get_skill_rate(217001) -> 3;

get_skill_rate(217002) -> 2;

get_skill_rate(217003) -> 1;

get_skill_rate(217004) -> 0;

get_skill_rate(217005) -> 0;

get_skill_rate(217006) -> 0;

get_skill_rate(217007) -> 0;

get_skill_rate(217008) -> 0;

get_skill_rate(217009) -> 0;

get_skill_rate(217010) -> 0;

get_skill_rate(218001) -> 3;

get_skill_rate(218002) -> 2;

get_skill_rate(218003) -> 1;

get_skill_rate(218004) -> 0;

get_skill_rate(218005) -> 0;

get_skill_rate(218006) -> 0;

get_skill_rate(218007) -> 0;

get_skill_rate(218008) -> 0;

get_skill_rate(218009) -> 0;

get_skill_rate(218010) -> 0;

get_skill_rate(219001) -> 3;

get_skill_rate(219002) -> 2;

get_skill_rate(219003) -> 1;

get_skill_rate(219004) -> 0;

get_skill_rate(219005) -> 0;

get_skill_rate(219006) -> 0;

get_skill_rate(219007) -> 0;

get_skill_rate(219008) -> 0;

get_skill_rate(219009) -> 0;

get_skill_rate(219010) -> 0;

get_skill_rate(220001) -> 3;

get_skill_rate(220002) -> 2;

get_skill_rate(220003) -> 1;

get_skill_rate(220004) -> 0;

get_skill_rate(220005) -> 0;

get_skill_rate(220006) -> 0;

get_skill_rate(220007) -> 0;

get_skill_rate(220008) -> 0;

get_skill_rate(220009) -> 0;

get_skill_rate(220010) -> 0;

get_skill_rate(221001) -> 3;

get_skill_rate(221002) -> 2;

get_skill_rate(221003) -> 1;

get_skill_rate(221004) -> 0;

get_skill_rate(221005) -> 0;

get_skill_rate(221006) -> 0;

get_skill_rate(221007) -> 0;

get_skill_rate(221008) -> 0;

get_skill_rate(221009) -> 0;

get_skill_rate(221010) -> 0;

get_skill_rate(222001) -> 3;

get_skill_rate(222002) -> 2;

get_skill_rate(222003) -> 1;

get_skill_rate(222004) -> 0;

get_skill_rate(222005) -> 0;

get_skill_rate(222006) -> 0;

get_skill_rate(222007) -> 0;

get_skill_rate(222008) -> 0;

get_skill_rate(222009) -> 0;

get_skill_rate(222010) -> 0;

get_skill_rate(223001) -> 0;

get_skill_rate(224001) -> 0;

get_skill_rate(225001) -> 0;

get_skill_rate(226001) -> 0;

get_skill_rate(227001) -> 0;

get_skill_rate(228001) -> 0;

get_skill_rate(229001) -> 0;

get_skill_rate(230001) -> 0;

get_skill_rate(231001) -> 0;

get_skill_rate(232001) -> 0;

get_skill_rate(233001) -> 0;

get_skill_rate(234001) -> 0;

get_skill_rate(235001) -> 0;

get_skill_rate(236001) -> 0;

get_skill_rate(237001) -> 0;

get_skill_rate(238001) -> 0;

get_skill_rate(239001) -> 0;

get_skill_rate(240001) -> 0;

get_skill_rate(241001) -> 0;

get_skill_rate(242001) -> 0;

get_skill_rate(243001) -> 0;

get_skill_rate(244001) -> 0;

get_skill_rate(245001) -> 0;

get_skill_rate(246001) -> 0;

get_skill_rate(247001) -> 0;

get_skill_rate(248001) -> 0;

get_skill_rate(249001) -> 0;

get_skill_rate(250001) -> 0;

get_skill_rate(251001) -> 0;

get_skill_rate(252001) -> 0;

get_skill_rate(253001) -> 0;

get_skill_rate(254001) -> 0;

get_skill_rate(255001) -> 0;

get_skill_rate(256001) -> 0;

get_skill_rate(257001) -> 0;

get_skill_rate(258001) -> 0;

get_skill_rate(259001) -> 0;

get_skill_rate(260001) -> 0;

get_skill_rate(261001) -> 0;

get_skill_rate(262001) -> 0;

get_skill_rate(263001) -> 0;

get_skill_rate(264001) -> 0;

get_skill_rate(265001) -> 0;

get_skill_rate(266001) -> 0;

get_skill_rate(267001) -> 0;

get_skill_rate(268001) -> 0;

get_skill_rate(269001) -> 0;

get_skill_rate(270001) -> 0;

get_skill_rate(271001) -> 0;

get_skill_rate(272001) -> 0;

get_skill_rate(273001) -> 0;

get_skill_rate(274001) -> 0;

get_skill_rate(275001) -> 0;

get_skill_rate(276001) -> 0;

get_skill_rate(277001) -> 0;

get_skill_rate(278001) -> 0;

get_skill_rate(279001) -> 0;

get_skill_rate(280001) -> 0;

get_skill_rate(281001) -> 0;

get_skill_rate(282001) -> 0;

get_skill_rate(283001) -> 0;

get_skill_rate(284001) -> 0;

get_skill_rate(285001) -> 0;

get_skill_rate(286001) -> 0;

get_skill_rate(287001) -> 0;

get_skill_rate(288001) -> 0;

get_skill_rate(289001) -> 0.


%%================================================
%% 根据技能id获取其详细信息
%% 普通攻击
skill_info(0) ->
	#skill_info{
		mode_id       = 0,
		class_id      = 0,
		type          = 0,
		effect        = 0,
		level_up_exp  = 0,
		next_skill_id = 0
	};

skill_info(100001) ->
	#skill_info{
		mode_id       = 100001,
		class_id      = 100,
		type          = 0,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 正气诀
skill_info(101001) ->
	#skill_info{
		mode_id       = 101001,
		class_id      = 101,
		type          = 2,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 突刺诀
skill_info(102001) ->
	#skill_info{
		mode_id       = 102001,
		class_id      = 102,
		type          = 2,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 凝神决
skill_info(103001) ->
	#skill_info{
		mode_id       = 103001,
		class_id      = 103,
		type          = 2,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 威震四方
skill_info(104001) ->
	#skill_info{
		mode_id       = 104001,
		class_id      = 104,
		type          = 1,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 104002
	};

%% 威震四方
skill_info(104002) ->
	#skill_info{
		mode_id       = 104002,
		class_id      = 104,
		type          = 1,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 104003
	};

%% 威震四方
skill_info(104003) ->
	#skill_info{
		mode_id       = 104003,
		class_id      = 104,
		type          = 1,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 104004
	};

%% 威震四方
skill_info(104004) ->
	#skill_info{
		mode_id       = 104004,
		class_id      = 104,
		type          = 1,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 104005
	};

%% 威震四方
skill_info(104005) ->
	#skill_info{
		mode_id       = 104005,
		class_id      = 104,
		type          = 1,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 104006
	};

%% 威震四方
skill_info(104006) ->
	#skill_info{
		mode_id       = 104006,
		class_id      = 104,
		type          = 1,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 104007
	};

%% 威震四方
skill_info(104007) ->
	#skill_info{
		mode_id       = 104007,
		class_id      = 104,
		type          = 1,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 104008
	};

%% 威震四方
skill_info(104008) ->
	#skill_info{
		mode_id       = 104008,
		class_id      = 104,
		type          = 1,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 104009
	};

%% 威震四方
skill_info(104009) ->
	#skill_info{
		mode_id       = 104009,
		class_id      = 104,
		type          = 1,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 104010
	};

%% 威震四方
skill_info(104010) ->
	#skill_info{
		mode_id       = 104010,
		class_id      = 104,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 坚若磐石
skill_info(105001) ->
	#skill_info{
		mode_id       = 105001,
		class_id      = 105,
		type          = 4,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 105002
	};

%% 坚若磐石
skill_info(105002) ->
	#skill_info{
		mode_id       = 105002,
		class_id      = 105,
		type          = 4,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 105003
	};

%% 坚若磐石
skill_info(105003) ->
	#skill_info{
		mode_id       = 105003,
		class_id      = 105,
		type          = 4,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 105004
	};

%% 坚若磐石
skill_info(105004) ->
	#skill_info{
		mode_id       = 105004,
		class_id      = 105,
		type          = 4,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 105005
	};

%% 坚若磐石
skill_info(105005) ->
	#skill_info{
		mode_id       = 105005,
		class_id      = 105,
		type          = 4,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 105006
	};

%% 坚若磐石
skill_info(105006) ->
	#skill_info{
		mode_id       = 105006,
		class_id      = 105,
		type          = 4,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 105007
	};

%% 坚若磐石
skill_info(105007) ->
	#skill_info{
		mode_id       = 105007,
		class_id      = 105,
		type          = 4,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 105008
	};

%% 坚若磐石
skill_info(105008) ->
	#skill_info{
		mode_id       = 105008,
		class_id      = 105,
		type          = 4,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 105009
	};

%% 坚若磐石
skill_info(105009) ->
	#skill_info{
		mode_id       = 105009,
		class_id      = 105,
		type          = 4,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 105010
	};

%% 坚若磐石
skill_info(105010) ->
	#skill_info{
		mode_id       = 105010,
		class_id      = 105,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 背水一战
skill_info(106001) ->
	#skill_info{
		mode_id       = 106001,
		class_id      = 106,
		type          = 4,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 106002
	};

%% 背水一战
skill_info(106002) ->
	#skill_info{
		mode_id       = 106002,
		class_id      = 106,
		type          = 4,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 106003
	};

%% 背水一战
skill_info(106003) ->
	#skill_info{
		mode_id       = 106003,
		class_id      = 106,
		type          = 4,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 106004
	};

%% 背水一战
skill_info(106004) ->
	#skill_info{
		mode_id       = 106004,
		class_id      = 106,
		type          = 4,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 106005
	};

%% 背水一战
skill_info(106005) ->
	#skill_info{
		mode_id       = 106005,
		class_id      = 106,
		type          = 4,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 106006
	};

%% 背水一战
skill_info(106006) ->
	#skill_info{
		mode_id       = 106006,
		class_id      = 106,
		type          = 4,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 106007
	};

%% 背水一战
skill_info(106007) ->
	#skill_info{
		mode_id       = 106007,
		class_id      = 106,
		type          = 4,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 106008
	};

%% 背水一战
skill_info(106008) ->
	#skill_info{
		mode_id       = 106008,
		class_id      = 106,
		type          = 4,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 106009
	};

%% 背水一战
skill_info(106009) ->
	#skill_info{
		mode_id       = 106009,
		class_id      = 106,
		type          = 4,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 106010
	};

%% 背水一战
skill_info(106010) ->
	#skill_info{
		mode_id       = 106010,
		class_id      = 106,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 浴血狂击
skill_info(107001) ->
	#skill_info{
		mode_id       = 107001,
		class_id      = 107,
		type          = 4,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 107002
	};

%% 浴血狂击
skill_info(107002) ->
	#skill_info{
		mode_id       = 107002,
		class_id      = 107,
		type          = 4,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 107003
	};

%% 浴血狂击
skill_info(107003) ->
	#skill_info{
		mode_id       = 107003,
		class_id      = 107,
		type          = 4,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 107004
	};

%% 浴血狂击
skill_info(107004) ->
	#skill_info{
		mode_id       = 107004,
		class_id      = 107,
		type          = 4,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 107005
	};

%% 浴血狂击
skill_info(107005) ->
	#skill_info{
		mode_id       = 107005,
		class_id      = 107,
		type          = 4,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 107006
	};

%% 浴血狂击
skill_info(107006) ->
	#skill_info{
		mode_id       = 107006,
		class_id      = 107,
		type          = 4,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 107007
	};

%% 浴血狂击
skill_info(107007) ->
	#skill_info{
		mode_id       = 107007,
		class_id      = 107,
		type          = 4,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 107008
	};

%% 浴血狂击
skill_info(107008) ->
	#skill_info{
		mode_id       = 107008,
		class_id      = 107,
		type          = 4,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 107009
	};

%% 浴血狂击
skill_info(107009) ->
	#skill_info{
		mode_id       = 107009,
		class_id      = 107,
		type          = 4,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 107010
	};

%% 浴血狂击
skill_info(107010) ->
	#skill_info{
		mode_id       = 107010,
		class_id      = 107,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 战意激荡
skill_info(108001) ->
	#skill_info{
		mode_id       = 108001,
		class_id      = 108,
		type          = 4,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 108002
	};

%% 战意激荡
skill_info(108002) ->
	#skill_info{
		mode_id       = 108002,
		class_id      = 108,
		type          = 4,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 108003
	};

%% 战意激荡
skill_info(108003) ->
	#skill_info{
		mode_id       = 108003,
		class_id      = 108,
		type          = 4,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 108004
	};

%% 战意激荡
skill_info(108004) ->
	#skill_info{
		mode_id       = 108004,
		class_id      = 108,
		type          = 4,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 108005
	};

%% 战意激荡
skill_info(108005) ->
	#skill_info{
		mode_id       = 108005,
		class_id      = 108,
		type          = 4,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 108006
	};

%% 战意激荡
skill_info(108006) ->
	#skill_info{
		mode_id       = 108006,
		class_id      = 108,
		type          = 4,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 108007
	};

%% 战意激荡
skill_info(108007) ->
	#skill_info{
		mode_id       = 108007,
		class_id      = 108,
		type          = 4,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 108008
	};

%% 战意激荡
skill_info(108008) ->
	#skill_info{
		mode_id       = 108008,
		class_id      = 108,
		type          = 4,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 108009
	};

%% 战意激荡
skill_info(108009) ->
	#skill_info{
		mode_id       = 108009,
		class_id      = 108,
		type          = 4,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 108010
	};

%% 战意激荡
skill_info(108010) ->
	#skill_info{
		mode_id       = 108010,
		class_id      = 108,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 霸刃连斩
skill_info(109001) ->
	#skill_info{
		mode_id       = 109001,
		class_id      = 109,
		type          = 1,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 109002
	};

%% 霸刃连斩
skill_info(109002) ->
	#skill_info{
		mode_id       = 109002,
		class_id      = 109,
		type          = 1,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 109003
	};

%% 霸刃连斩
skill_info(109003) ->
	#skill_info{
		mode_id       = 109003,
		class_id      = 109,
		type          = 1,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 109004
	};

%% 霸刃连斩
skill_info(109004) ->
	#skill_info{
		mode_id       = 109004,
		class_id      = 109,
		type          = 1,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 109005
	};

%% 霸刃连斩
skill_info(109005) ->
	#skill_info{
		mode_id       = 109005,
		class_id      = 109,
		type          = 1,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 109006
	};

%% 霸刃连斩
skill_info(109006) ->
	#skill_info{
		mode_id       = 109006,
		class_id      = 109,
		type          = 1,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 109007
	};

%% 霸刃连斩
skill_info(109007) ->
	#skill_info{
		mode_id       = 109007,
		class_id      = 109,
		type          = 1,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 109008
	};

%% 霸刃连斩
skill_info(109008) ->
	#skill_info{
		mode_id       = 109008,
		class_id      = 109,
		type          = 1,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 109009
	};

%% 霸刃连斩
skill_info(109009) ->
	#skill_info{
		mode_id       = 109009,
		class_id      = 109,
		type          = 1,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 109010
	};

%% 霸刃连斩
skill_info(109010) ->
	#skill_info{
		mode_id       = 109010,
		class_id      = 109,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 横扫千军
skill_info(110001) ->
	#skill_info{
		mode_id       = 110001,
		class_id      = 110,
		type          = 4,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 110002
	};

%% 横扫千军
skill_info(110002) ->
	#skill_info{
		mode_id       = 110002,
		class_id      = 110,
		type          = 4,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 110003
	};

%% 横扫千军
skill_info(110003) ->
	#skill_info{
		mode_id       = 110003,
		class_id      = 110,
		type          = 4,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 110004
	};

%% 横扫千军
skill_info(110004) ->
	#skill_info{
		mode_id       = 110004,
		class_id      = 110,
		type          = 4,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 110005
	};

%% 横扫千军
skill_info(110005) ->
	#skill_info{
		mode_id       = 110005,
		class_id      = 110,
		type          = 4,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 110006
	};

%% 横扫千军
skill_info(110006) ->
	#skill_info{
		mode_id       = 110006,
		class_id      = 110,
		type          = 4,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 110007
	};

%% 横扫千军
skill_info(110007) ->
	#skill_info{
		mode_id       = 110007,
		class_id      = 110,
		type          = 4,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 110008
	};

%% 横扫千军
skill_info(110008) ->
	#skill_info{
		mode_id       = 110008,
		class_id      = 110,
		type          = 4,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 110009
	};

%% 横扫千军
skill_info(110009) ->
	#skill_info{
		mode_id       = 110009,
		class_id      = 110,
		type          = 4,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 110010
	};

%% 横扫千军
skill_info(110010) ->
	#skill_info{
		mode_id       = 110010,
		class_id      = 110,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 暴怒冲锋
skill_info(111001) ->
	#skill_info{
		mode_id       = 111001,
		class_id      = 111,
		type          = 4,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 111002
	};

%% 暴怒冲锋
skill_info(111002) ->
	#skill_info{
		mode_id       = 111002,
		class_id      = 111,
		type          = 4,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 111003
	};

%% 暴怒冲锋
skill_info(111003) ->
	#skill_info{
		mode_id       = 111003,
		class_id      = 111,
		type          = 4,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 111004
	};

%% 暴怒冲锋
skill_info(111004) ->
	#skill_info{
		mode_id       = 111004,
		class_id      = 111,
		type          = 4,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 111005
	};

%% 暴怒冲锋
skill_info(111005) ->
	#skill_info{
		mode_id       = 111005,
		class_id      = 111,
		type          = 4,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 111006
	};

%% 暴怒冲锋
skill_info(111006) ->
	#skill_info{
		mode_id       = 111006,
		class_id      = 111,
		type          = 4,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 111007
	};

%% 暴怒冲锋
skill_info(111007) ->
	#skill_info{
		mode_id       = 111007,
		class_id      = 111,
		type          = 4,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 111008
	};

%% 暴怒冲锋
skill_info(111008) ->
	#skill_info{
		mode_id       = 111008,
		class_id      = 111,
		type          = 4,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 111009
	};

%% 暴怒冲锋
skill_info(111009) ->
	#skill_info{
		mode_id       = 111009,
		class_id      = 111,
		type          = 4,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 111010
	};

%% 暴怒冲锋
skill_info(111010) ->
	#skill_info{
		mode_id       = 111010,
		class_id      = 111,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 乘胜追击
skill_info(112001) ->
	#skill_info{
		mode_id       = 112001,
		class_id      = 112,
		type          = 4,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 112002
	};

%% 乘胜追击
skill_info(112002) ->
	#skill_info{
		mode_id       = 112002,
		class_id      = 112,
		type          = 4,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 112003
	};

%% 乘胜追击
skill_info(112003) ->
	#skill_info{
		mode_id       = 112003,
		class_id      = 112,
		type          = 4,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 112004
	};

%% 乘胜追击
skill_info(112004) ->
	#skill_info{
		mode_id       = 112004,
		class_id      = 112,
		type          = 4,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 112005
	};

%% 乘胜追击
skill_info(112005) ->
	#skill_info{
		mode_id       = 112005,
		class_id      = 112,
		type          = 4,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 112006
	};

%% 乘胜追击
skill_info(112006) ->
	#skill_info{
		mode_id       = 112006,
		class_id      = 112,
		type          = 4,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 112007
	};

%% 乘胜追击
skill_info(112007) ->
	#skill_info{
		mode_id       = 112007,
		class_id      = 112,
		type          = 4,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 112008
	};

%% 乘胜追击
skill_info(112008) ->
	#skill_info{
		mode_id       = 112008,
		class_id      = 112,
		type          = 4,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 112009
	};

%% 乘胜追击
skill_info(112009) ->
	#skill_info{
		mode_id       = 112009,
		class_id      = 112,
		type          = 4,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 112010
	};

%% 乘胜追击
skill_info(112010) ->
	#skill_info{
		mode_id       = 112010,
		class_id      = 112,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 破军之势
skill_info(113001) ->
	#skill_info{
		mode_id       = 113001,
		class_id      = 113,
		type          = 4,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 113002
	};

%% 破军之势
skill_info(113002) ->
	#skill_info{
		mode_id       = 113002,
		class_id      = 113,
		type          = 4,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 113003
	};

%% 破军之势
skill_info(113003) ->
	#skill_info{
		mode_id       = 113003,
		class_id      = 113,
		type          = 4,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 113004
	};

%% 破军之势
skill_info(113004) ->
	#skill_info{
		mode_id       = 113004,
		class_id      = 113,
		type          = 4,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 113005
	};

%% 破军之势
skill_info(113005) ->
	#skill_info{
		mode_id       = 113005,
		class_id      = 113,
		type          = 4,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 113006
	};

%% 破军之势
skill_info(113006) ->
	#skill_info{
		mode_id       = 113006,
		class_id      = 113,
		type          = 4,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 113007
	};

%% 破军之势
skill_info(113007) ->
	#skill_info{
		mode_id       = 113007,
		class_id      = 113,
		type          = 4,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 113008
	};

%% 破军之势
skill_info(113008) ->
	#skill_info{
		mode_id       = 113008,
		class_id      = 113,
		type          = 4,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 113009
	};

%% 破军之势
skill_info(113009) ->
	#skill_info{
		mode_id       = 113009,
		class_id      = 113,
		type          = 4,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 113010
	};

%% 破军之势
skill_info(113010) ->
	#skill_info{
		mode_id       = 113010,
		class_id      = 113,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 龙战八方
skill_info(114001) ->
	#skill_info{
		mode_id       = 114001,
		class_id      = 114,
		type          = 1,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 114002
	};

%% 龙战八方
skill_info(114002) ->
	#skill_info{
		mode_id       = 114002,
		class_id      = 114,
		type          = 1,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 114003
	};

%% 龙战八方
skill_info(114003) ->
	#skill_info{
		mode_id       = 114003,
		class_id      = 114,
		type          = 1,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 114004
	};

%% 龙战八方
skill_info(114004) ->
	#skill_info{
		mode_id       = 114004,
		class_id      = 114,
		type          = 1,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 114005
	};

%% 龙战八方
skill_info(114005) ->
	#skill_info{
		mode_id       = 114005,
		class_id      = 114,
		type          = 1,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 114006
	};

%% 龙战八方
skill_info(114006) ->
	#skill_info{
		mode_id       = 114006,
		class_id      = 114,
		type          = 1,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 114007
	};

%% 龙战八方
skill_info(114007) ->
	#skill_info{
		mode_id       = 114007,
		class_id      = 114,
		type          = 1,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 114008
	};

%% 龙战八方
skill_info(114008) ->
	#skill_info{
		mode_id       = 114008,
		class_id      = 114,
		type          = 1,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 114009
	};

%% 龙战八方
skill_info(114009) ->
	#skill_info{
		mode_id       = 114009,
		class_id      = 114,
		type          = 1,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 114010
	};

%% 龙战八方
skill_info(114010) ->
	#skill_info{
		mode_id       = 114010,
		class_id      = 114,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 奇门遁甲
skill_info(115001) ->
	#skill_info{
		mode_id       = 115001,
		class_id      = 115,
		type          = 4,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 115002
	};

%% 奇门遁甲
skill_info(115002) ->
	#skill_info{
		mode_id       = 115002,
		class_id      = 115,
		type          = 4,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 115003
	};

%% 奇门遁甲
skill_info(115003) ->
	#skill_info{
		mode_id       = 115003,
		class_id      = 115,
		type          = 4,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 115004
	};

%% 奇门遁甲
skill_info(115004) ->
	#skill_info{
		mode_id       = 115004,
		class_id      = 115,
		type          = 4,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 115005
	};

%% 奇门遁甲
skill_info(115005) ->
	#skill_info{
		mode_id       = 115005,
		class_id      = 115,
		type          = 4,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 115006
	};

%% 奇门遁甲
skill_info(115006) ->
	#skill_info{
		mode_id       = 115006,
		class_id      = 115,
		type          = 4,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 115007
	};

%% 奇门遁甲
skill_info(115007) ->
	#skill_info{
		mode_id       = 115007,
		class_id      = 115,
		type          = 4,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 115008
	};

%% 奇门遁甲
skill_info(115008) ->
	#skill_info{
		mode_id       = 115008,
		class_id      = 115,
		type          = 4,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 115009
	};

%% 奇门遁甲
skill_info(115009) ->
	#skill_info{
		mode_id       = 115009,
		class_id      = 115,
		type          = 4,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 115010
	};

%% 奇门遁甲
skill_info(115010) ->
	#skill_info{
		mode_id       = 115010,
		class_id      = 115,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 雷光咒
skill_info(116001) ->
	#skill_info{
		mode_id       = 116001,
		class_id      = 116,
		type          = 4,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 116002
	};

%% 雷光咒
skill_info(116002) ->
	#skill_info{
		mode_id       = 116002,
		class_id      = 116,
		type          = 4,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 116003
	};

%% 雷光咒
skill_info(116003) ->
	#skill_info{
		mode_id       = 116003,
		class_id      = 116,
		type          = 4,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 116004
	};

%% 雷光咒
skill_info(116004) ->
	#skill_info{
		mode_id       = 116004,
		class_id      = 116,
		type          = 4,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 116005
	};

%% 雷光咒
skill_info(116005) ->
	#skill_info{
		mode_id       = 116005,
		class_id      = 116,
		type          = 4,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 116006
	};

%% 雷光咒
skill_info(116006) ->
	#skill_info{
		mode_id       = 116006,
		class_id      = 116,
		type          = 4,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 116007
	};

%% 雷光咒
skill_info(116007) ->
	#skill_info{
		mode_id       = 116007,
		class_id      = 116,
		type          = 4,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 116008
	};

%% 雷光咒
skill_info(116008) ->
	#skill_info{
		mode_id       = 116008,
		class_id      = 116,
		type          = 4,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 116009
	};

%% 雷光咒
skill_info(116009) ->
	#skill_info{
		mode_id       = 116009,
		class_id      = 116,
		type          = 4,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 116010
	};

%% 雷光咒
skill_info(116010) ->
	#skill_info{
		mode_id       = 116010,
		class_id      = 116,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 强兵咒
skill_info(117001) ->
	#skill_info{
		mode_id       = 117001,
		class_id      = 117,
		type          = 4,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 117002
	};

%% 强兵咒
skill_info(117002) ->
	#skill_info{
		mode_id       = 117002,
		class_id      = 117,
		type          = 4,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 117003
	};

%% 强兵咒
skill_info(117003) ->
	#skill_info{
		mode_id       = 117003,
		class_id      = 117,
		type          = 4,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 117004
	};

%% 强兵咒
skill_info(117004) ->
	#skill_info{
		mode_id       = 117004,
		class_id      = 117,
		type          = 4,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 117005
	};

%% 强兵咒
skill_info(117005) ->
	#skill_info{
		mode_id       = 117005,
		class_id      = 117,
		type          = 4,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 117006
	};

%% 强兵咒
skill_info(117006) ->
	#skill_info{
		mode_id       = 117006,
		class_id      = 117,
		type          = 4,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 117007
	};

%% 强兵咒
skill_info(117007) ->
	#skill_info{
		mode_id       = 117007,
		class_id      = 117,
		type          = 4,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 117008
	};

%% 强兵咒
skill_info(117008) ->
	#skill_info{
		mode_id       = 117008,
		class_id      = 117,
		type          = 4,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 117009
	};

%% 强兵咒
skill_info(117009) ->
	#skill_info{
		mode_id       = 117009,
		class_id      = 117,
		type          = 4,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 117010
	};

%% 强兵咒
skill_info(117010) ->
	#skill_info{
		mode_id       = 117010,
		class_id      = 117,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 破军咒
skill_info(118001) ->
	#skill_info{
		mode_id       = 118001,
		class_id      = 118,
		type          = 4,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 118002
	};

%% 破军咒
skill_info(118002) ->
	#skill_info{
		mode_id       = 118002,
		class_id      = 118,
		type          = 4,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 118003
	};

%% 破军咒
skill_info(118003) ->
	#skill_info{
		mode_id       = 118003,
		class_id      = 118,
		type          = 4,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 118004
	};

%% 破军咒
skill_info(118004) ->
	#skill_info{
		mode_id       = 118004,
		class_id      = 118,
		type          = 4,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 118005
	};

%% 破军咒
skill_info(118005) ->
	#skill_info{
		mode_id       = 118005,
		class_id      = 118,
		type          = 4,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 118006
	};

%% 破军咒
skill_info(118006) ->
	#skill_info{
		mode_id       = 118006,
		class_id      = 118,
		type          = 4,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 118007
	};

%% 破军咒
skill_info(118007) ->
	#skill_info{
		mode_id       = 118007,
		class_id      = 118,
		type          = 4,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 118008
	};

%% 破军咒
skill_info(118008) ->
	#skill_info{
		mode_id       = 118008,
		class_id      = 118,
		type          = 4,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 118009
	};

%% 破军咒
skill_info(118009) ->
	#skill_info{
		mode_id       = 118009,
		class_id      = 118,
		type          = 4,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 118010
	};

%% 破军咒
skill_info(118010) ->
	#skill_info{
		mode_id       = 118010,
		class_id      = 118,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 守护
skill_info(201001) ->
	#skill_info{
		mode_id       = 201001,
		class_id      = 201,
		type          = 3,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 201002
	};

%% 守护
skill_info(201002) ->
	#skill_info{
		mode_id       = 201002,
		class_id      = 201,
		type          = 3,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 201003
	};

%% 守护
skill_info(201003) ->
	#skill_info{
		mode_id       = 201003,
		class_id      = 201,
		type          = 3,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 201004
	};

%% 守护
skill_info(201004) ->
	#skill_info{
		mode_id       = 201004,
		class_id      = 201,
		type          = 3,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 201005
	};

%% 守护
skill_info(201005) ->
	#skill_info{
		mode_id       = 201005,
		class_id      = 201,
		type          = 3,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 201006
	};

%% 守护
skill_info(201006) ->
	#skill_info{
		mode_id       = 201006,
		class_id      = 201,
		type          = 3,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 201007
	};

%% 守护
skill_info(201007) ->
	#skill_info{
		mode_id       = 201007,
		class_id      = 201,
		type          = 3,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 201008
	};

%% 守护
skill_info(201008) ->
	#skill_info{
		mode_id       = 201008,
		class_id      = 201,
		type          = 3,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 201009
	};

%% 守护
skill_info(201009) ->
	#skill_info{
		mode_id       = 201009,
		class_id      = 201,
		type          = 3,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 201010
	};

%% 守护
skill_info(201010) ->
	#skill_info{
		mode_id       = 201010,
		class_id      = 201,
		type          = 3,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 毒
skill_info(202001) ->
	#skill_info{
		mode_id       = 202001,
		class_id      = 202,
		type          = 3,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 202002
	};

%% 毒
skill_info(202002) ->
	#skill_info{
		mode_id       = 202002,
		class_id      = 202,
		type          = 3,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 202003
	};

%% 毒
skill_info(202003) ->
	#skill_info{
		mode_id       = 202003,
		class_id      = 202,
		type          = 3,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 202004
	};

%% 毒
skill_info(202004) ->
	#skill_info{
		mode_id       = 202004,
		class_id      = 202,
		type          = 3,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 202005
	};

%% 毒
skill_info(202005) ->
	#skill_info{
		mode_id       = 202005,
		class_id      = 202,
		type          = 3,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 202006
	};

%% 毒
skill_info(202006) ->
	#skill_info{
		mode_id       = 202006,
		class_id      = 202,
		type          = 3,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 202007
	};

%% 毒
skill_info(202007) ->
	#skill_info{
		mode_id       = 202007,
		class_id      = 202,
		type          = 3,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 202008
	};

%% 毒
skill_info(202008) ->
	#skill_info{
		mode_id       = 202008,
		class_id      = 202,
		type          = 3,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 202009
	};

%% 毒
skill_info(202009) ->
	#skill_info{
		mode_id       = 202009,
		class_id      = 202,
		type          = 3,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 202010
	};

%% 毒
skill_info(202010) ->
	#skill_info{
		mode_id       = 202010,
		class_id      = 202,
		type          = 3,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 连击
skill_info(203001) ->
	#skill_info{
		mode_id       = 203001,
		class_id      = 203,
		type          = 3,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 203002
	};

%% 连击
skill_info(203002) ->
	#skill_info{
		mode_id       = 203002,
		class_id      = 203,
		type          = 3,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 203003
	};

%% 连击
skill_info(203003) ->
	#skill_info{
		mode_id       = 203003,
		class_id      = 203,
		type          = 3,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 203004
	};

%% 连击
skill_info(203004) ->
	#skill_info{
		mode_id       = 203004,
		class_id      = 203,
		type          = 3,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 203005
	};

%% 连击
skill_info(203005) ->
	#skill_info{
		mode_id       = 203005,
		class_id      = 203,
		type          = 3,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 203006
	};

%% 连击
skill_info(203006) ->
	#skill_info{
		mode_id       = 203006,
		class_id      = 203,
		type          = 3,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 203007
	};

%% 连击
skill_info(203007) ->
	#skill_info{
		mode_id       = 203007,
		class_id      = 203,
		type          = 3,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 203008
	};

%% 连击
skill_info(203008) ->
	#skill_info{
		mode_id       = 203008,
		class_id      = 203,
		type          = 3,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 203009
	};

%% 连击
skill_info(203009) ->
	#skill_info{
		mode_id       = 203009,
		class_id      = 203,
		type          = 3,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 203010
	};

%% 连击
skill_info(203010) ->
	#skill_info{
		mode_id       = 203010,
		class_id      = 203,
		type          = 3,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 暴击
skill_info(204001) ->
	#skill_info{
		mode_id       = 204001,
		class_id      = 204,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 204002
	};

%% 暴击
skill_info(204002) ->
	#skill_info{
		mode_id       = 204002,
		class_id      = 204,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 204003
	};

%% 暴击
skill_info(204003) ->
	#skill_info{
		mode_id       = 204003,
		class_id      = 204,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 204004
	};

%% 暴击
skill_info(204004) ->
	#skill_info{
		mode_id       = 204004,
		class_id      = 204,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 204005
	};

%% 暴击
skill_info(204005) ->
	#skill_info{
		mode_id       = 204005,
		class_id      = 204,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 204006
	};

%% 暴击
skill_info(204006) ->
	#skill_info{
		mode_id       = 204006,
		class_id      = 204,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 204007
	};

%% 暴击
skill_info(204007) ->
	#skill_info{
		mode_id       = 204007,
		class_id      = 204,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 204008
	};

%% 暴击
skill_info(204008) ->
	#skill_info{
		mode_id       = 204008,
		class_id      = 204,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 204009
	};

%% 暴击
skill_info(204009) ->
	#skill_info{
		mode_id       = 204009,
		class_id      = 204,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 204010
	};

%% 暴击
skill_info(204010) ->
	#skill_info{
		mode_id       = 204010,
		class_id      = 204,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 神佑复生
skill_info(205001) ->
	#skill_info{
		mode_id       = 205001,
		class_id      = 205,
		type          = 3,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 205002
	};

%% 神佑复生
skill_info(205002) ->
	#skill_info{
		mode_id       = 205002,
		class_id      = 205,
		type          = 3,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 205003
	};

%% 神佑复生
skill_info(205003) ->
	#skill_info{
		mode_id       = 205003,
		class_id      = 205,
		type          = 3,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 205004
	};

%% 神佑复生
skill_info(205004) ->
	#skill_info{
		mode_id       = 205004,
		class_id      = 205,
		type          = 3,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 205005
	};

%% 神佑复生
skill_info(205005) ->
	#skill_info{
		mode_id       = 205005,
		class_id      = 205,
		type          = 3,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 205006
	};

%% 神佑复生
skill_info(205006) ->
	#skill_info{
		mode_id       = 205006,
		class_id      = 205,
		type          = 3,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 205007
	};

%% 神佑复生
skill_info(205007) ->
	#skill_info{
		mode_id       = 205007,
		class_id      = 205,
		type          = 3,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 205008
	};

%% 神佑复生
skill_info(205008) ->
	#skill_info{
		mode_id       = 205008,
		class_id      = 205,
		type          = 3,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 205009
	};

%% 神佑复生
skill_info(205009) ->
	#skill_info{
		mode_id       = 205009,
		class_id      = 205,
		type          = 3,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 205010
	};

%% 神佑复生
skill_info(205010) ->
	#skill_info{
		mode_id       = 205010,
		class_id      = 205,
		type          = 3,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 吸血
skill_info(206001) ->
	#skill_info{
		mode_id       = 206001,
		class_id      = 206,
		type          = 3,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 206002
	};

%% 吸血
skill_info(206002) ->
	#skill_info{
		mode_id       = 206002,
		class_id      = 206,
		type          = 3,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 206003
	};

%% 吸血
skill_info(206003) ->
	#skill_info{
		mode_id       = 206003,
		class_id      = 206,
		type          = 3,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 206004
	};

%% 吸血
skill_info(206004) ->
	#skill_info{
		mode_id       = 206004,
		class_id      = 206,
		type          = 3,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 206005
	};

%% 吸血
skill_info(206005) ->
	#skill_info{
		mode_id       = 206005,
		class_id      = 206,
		type          = 3,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 206006
	};

%% 吸血
skill_info(206006) ->
	#skill_info{
		mode_id       = 206006,
		class_id      = 206,
		type          = 3,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 206007
	};

%% 吸血
skill_info(206007) ->
	#skill_info{
		mode_id       = 206007,
		class_id      = 206,
		type          = 3,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 206008
	};

%% 吸血
skill_info(206008) ->
	#skill_info{
		mode_id       = 206008,
		class_id      = 206,
		type          = 3,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 206009
	};

%% 吸血
skill_info(206009) ->
	#skill_info{
		mode_id       = 206009,
		class_id      = 206,
		type          = 3,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 206010
	};

%% 吸血
skill_info(206010) ->
	#skill_info{
		mode_id       = 206010,
		class_id      = 206,
		type          = 3,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 破怒
skill_info(207001) ->
	#skill_info{
		mode_id       = 207001,
		class_id      = 207,
		type          = 3,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 207002
	};

%% 破怒
skill_info(207002) ->
	#skill_info{
		mode_id       = 207002,
		class_id      = 207,
		type          = 3,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 207003
	};

%% 破怒
skill_info(207003) ->
	#skill_info{
		mode_id       = 207003,
		class_id      = 207,
		type          = 3,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 207004
	};

%% 破怒
skill_info(207004) ->
	#skill_info{
		mode_id       = 207004,
		class_id      = 207,
		type          = 3,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 207005
	};

%% 破怒
skill_info(207005) ->
	#skill_info{
		mode_id       = 207005,
		class_id      = 207,
		type          = 3,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 207006
	};

%% 破怒
skill_info(207006) ->
	#skill_info{
		mode_id       = 207006,
		class_id      = 207,
		type          = 3,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 207007
	};

%% 破怒
skill_info(207007) ->
	#skill_info{
		mode_id       = 207007,
		class_id      = 207,
		type          = 3,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 207008
	};

%% 破怒
skill_info(207008) ->
	#skill_info{
		mode_id       = 207008,
		class_id      = 207,
		type          = 3,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 207009
	};

%% 破怒
skill_info(207009) ->
	#skill_info{
		mode_id       = 207009,
		class_id      = 207,
		type          = 3,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 207010
	};

%% 破怒
skill_info(207010) ->
	#skill_info{
		mode_id       = 207010,
		class_id      = 207,
		type          = 3,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 坚盾
skill_info(208001) ->
	#skill_info{
		mode_id       = 208001,
		class_id      = 208,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 208002
	};

%% 坚盾
skill_info(208002) ->
	#skill_info{
		mode_id       = 208002,
		class_id      = 208,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 208003
	};

%% 坚盾
skill_info(208003) ->
	#skill_info{
		mode_id       = 208003,
		class_id      = 208,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 208004
	};

%% 坚盾
skill_info(208004) ->
	#skill_info{
		mode_id       = 208004,
		class_id      = 208,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 208005
	};

%% 坚盾
skill_info(208005) ->
	#skill_info{
		mode_id       = 208005,
		class_id      = 208,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 208006
	};

%% 坚盾
skill_info(208006) ->
	#skill_info{
		mode_id       = 208006,
		class_id      = 208,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 208007
	};

%% 坚盾
skill_info(208007) ->
	#skill_info{
		mode_id       = 208007,
		class_id      = 208,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 208008
	};

%% 坚盾
skill_info(208008) ->
	#skill_info{
		mode_id       = 208008,
		class_id      = 208,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 208009
	};

%% 坚盾
skill_info(208009) ->
	#skill_info{
		mode_id       = 208009,
		class_id      = 208,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 208010
	};

%% 坚盾
skill_info(208010) ->
	#skill_info{
		mode_id       = 208010,
		class_id      = 208,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 法盾
skill_info(209001) ->
	#skill_info{
		mode_id       = 209001,
		class_id      = 209,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 209002
	};

%% 法盾
skill_info(209002) ->
	#skill_info{
		mode_id       = 209002,
		class_id      = 209,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 209003
	};

%% 法盾
skill_info(209003) ->
	#skill_info{
		mode_id       = 209003,
		class_id      = 209,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 209004
	};

%% 法盾
skill_info(209004) ->
	#skill_info{
		mode_id       = 209004,
		class_id      = 209,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 209005
	};

%% 法盾
skill_info(209005) ->
	#skill_info{
		mode_id       = 209005,
		class_id      = 209,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 209006
	};

%% 法盾
skill_info(209006) ->
	#skill_info{
		mode_id       = 209006,
		class_id      = 209,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 209007
	};

%% 法盾
skill_info(209007) ->
	#skill_info{
		mode_id       = 209007,
		class_id      = 209,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 209008
	};

%% 法盾
skill_info(209008) ->
	#skill_info{
		mode_id       = 209008,
		class_id      = 209,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 209009
	};

%% 法盾
skill_info(209009) ->
	#skill_info{
		mode_id       = 209009,
		class_id      = 209,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 209010
	};

%% 法盾
skill_info(209010) ->
	#skill_info{
		mode_id       = 209010,
		class_id      = 209,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 敏捷
skill_info(210001) ->
	#skill_info{
		mode_id       = 210001,
		class_id      = 210,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 210002
	};

%% 敏捷
skill_info(210002) ->
	#skill_info{
		mode_id       = 210002,
		class_id      = 210,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 210003
	};

%% 敏捷
skill_info(210003) ->
	#skill_info{
		mode_id       = 210003,
		class_id      = 210,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 210004
	};

%% 敏捷
skill_info(210004) ->
	#skill_info{
		mode_id       = 210004,
		class_id      = 210,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 210005
	};

%% 敏捷
skill_info(210005) ->
	#skill_info{
		mode_id       = 210005,
		class_id      = 210,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 210006
	};

%% 敏捷
skill_info(210006) ->
	#skill_info{
		mode_id       = 210006,
		class_id      = 210,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 210007
	};

%% 敏捷
skill_info(210007) ->
	#skill_info{
		mode_id       = 210007,
		class_id      = 210,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 210008
	};

%% 敏捷
skill_info(210008) ->
	#skill_info{
		mode_id       = 210008,
		class_id      = 210,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 210009
	};

%% 敏捷
skill_info(210009) ->
	#skill_info{
		mode_id       = 210009,
		class_id      = 210,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 210010
	};

%% 敏捷
skill_info(210010) ->
	#skill_info{
		mode_id       = 210010,
		class_id      = 210,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 强力
skill_info(211001) ->
	#skill_info{
		mode_id       = 211001,
		class_id      = 211,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 211002
	};

%% 强力
skill_info(211002) ->
	#skill_info{
		mode_id       = 211002,
		class_id      = 211,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 211003
	};

%% 强力
skill_info(211003) ->
	#skill_info{
		mode_id       = 211003,
		class_id      = 211,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 211004
	};

%% 强力
skill_info(211004) ->
	#skill_info{
		mode_id       = 211004,
		class_id      = 211,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 211005
	};

%% 强力
skill_info(211005) ->
	#skill_info{
		mode_id       = 211005,
		class_id      = 211,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 211006
	};

%% 强力
skill_info(211006) ->
	#skill_info{
		mode_id       = 211006,
		class_id      = 211,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 211007
	};

%% 强力
skill_info(211007) ->
	#skill_info{
		mode_id       = 211007,
		class_id      = 211,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 211008
	};

%% 强力
skill_info(211008) ->
	#skill_info{
		mode_id       = 211008,
		class_id      = 211,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 211009
	};

%% 强力
skill_info(211009) ->
	#skill_info{
		mode_id       = 211009,
		class_id      = 211,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 211010
	};

%% 强力
skill_info(211010) ->
	#skill_info{
		mode_id       = 211010,
		class_id      = 211,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 强法
skill_info(212001) ->
	#skill_info{
		mode_id       = 212001,
		class_id      = 212,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 212002
	};

%% 强法
skill_info(212002) ->
	#skill_info{
		mode_id       = 212002,
		class_id      = 212,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 212003
	};

%% 强法
skill_info(212003) ->
	#skill_info{
		mode_id       = 212003,
		class_id      = 212,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 212004
	};

%% 强法
skill_info(212004) ->
	#skill_info{
		mode_id       = 212004,
		class_id      = 212,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 212005
	};

%% 强法
skill_info(212005) ->
	#skill_info{
		mode_id       = 212005,
		class_id      = 212,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 212006
	};

%% 强法
skill_info(212006) ->
	#skill_info{
		mode_id       = 212006,
		class_id      = 212,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 212007
	};

%% 强法
skill_info(212007) ->
	#skill_info{
		mode_id       = 212007,
		class_id      = 212,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 212008
	};

%% 强法
skill_info(212008) ->
	#skill_info{
		mode_id       = 212008,
		class_id      = 212,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 212009
	};

%% 强法
skill_info(212009) ->
	#skill_info{
		mode_id       = 212009,
		class_id      = 212,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 212010
	};

%% 强法
skill_info(212010) ->
	#skill_info{
		mode_id       = 212010,
		class_id      = 212,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 强身
skill_info(213001) ->
	#skill_info{
		mode_id       = 213001,
		class_id      = 213,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 213002
	};

%% 强身
skill_info(213002) ->
	#skill_info{
		mode_id       = 213002,
		class_id      = 213,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 213003
	};

%% 强身
skill_info(213003) ->
	#skill_info{
		mode_id       = 213003,
		class_id      = 213,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 213004
	};

%% 强身
skill_info(213004) ->
	#skill_info{
		mode_id       = 213004,
		class_id      = 213,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 213005
	};

%% 强身
skill_info(213005) ->
	#skill_info{
		mode_id       = 213005,
		class_id      = 213,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 213006
	};

%% 强身
skill_info(213006) ->
	#skill_info{
		mode_id       = 213006,
		class_id      = 213,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 213007
	};

%% 强身
skill_info(213007) ->
	#skill_info{
		mode_id       = 213007,
		class_id      = 213,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 213008
	};

%% 强身
skill_info(213008) ->
	#skill_info{
		mode_id       = 213008,
		class_id      = 213,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 213009
	};

%% 强身
skill_info(213009) ->
	#skill_info{
		mode_id       = 213009,
		class_id      = 213,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 213010
	};

%% 强身
skill_info(213010) ->
	#skill_info{
		mode_id       = 213010,
		class_id      = 213,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 愤怒
skill_info(214001) ->
	#skill_info{
		mode_id       = 214001,
		class_id      = 214,
		type          = 3,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 214002
	};

%% 愤怒
skill_info(214002) ->
	#skill_info{
		mode_id       = 214002,
		class_id      = 214,
		type          = 3,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 214003
	};

%% 愤怒
skill_info(214003) ->
	#skill_info{
		mode_id       = 214003,
		class_id      = 214,
		type          = 3,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 214004
	};

%% 愤怒
skill_info(214004) ->
	#skill_info{
		mode_id       = 214004,
		class_id      = 214,
		type          = 3,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 214005
	};

%% 愤怒
skill_info(214005) ->
	#skill_info{
		mode_id       = 214005,
		class_id      = 214,
		type          = 3,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 214006
	};

%% 愤怒
skill_info(214006) ->
	#skill_info{
		mode_id       = 214006,
		class_id      = 214,
		type          = 3,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 214007
	};

%% 愤怒
skill_info(214007) ->
	#skill_info{
		mode_id       = 214007,
		class_id      = 214,
		type          = 3,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 214008
	};

%% 愤怒
skill_info(214008) ->
	#skill_info{
		mode_id       = 214008,
		class_id      = 214,
		type          = 3,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 214009
	};

%% 愤怒
skill_info(214009) ->
	#skill_info{
		mode_id       = 214009,
		class_id      = 214,
		type          = 3,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 214010
	};

%% 愤怒
skill_info(214010) ->
	#skill_info{
		mode_id       = 214010,
		class_id      = 214,
		type          = 3,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 格挡
skill_info(215001) ->
	#skill_info{
		mode_id       = 215001,
		class_id      = 215,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 215002
	};

%% 格挡
skill_info(215002) ->
	#skill_info{
		mode_id       = 215002,
		class_id      = 215,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 215003
	};

%% 格挡
skill_info(215003) ->
	#skill_info{
		mode_id       = 215003,
		class_id      = 215,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 215004
	};

%% 格挡
skill_info(215004) ->
	#skill_info{
		mode_id       = 215004,
		class_id      = 215,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 215005
	};

%% 格挡
skill_info(215005) ->
	#skill_info{
		mode_id       = 215005,
		class_id      = 215,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 215006
	};

%% 格挡
skill_info(215006) ->
	#skill_info{
		mode_id       = 215006,
		class_id      = 215,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 215007
	};

%% 格挡
skill_info(215007) ->
	#skill_info{
		mode_id       = 215007,
		class_id      = 215,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 215008
	};

%% 格挡
skill_info(215008) ->
	#skill_info{
		mode_id       = 215008,
		class_id      = 215,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 215009
	};

%% 格挡
skill_info(215009) ->
	#skill_info{
		mode_id       = 215009,
		class_id      = 215,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 215010
	};

%% 格挡
skill_info(215010) ->
	#skill_info{
		mode_id       = 215010,
		class_id      = 215,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 闪避
skill_info(216001) ->
	#skill_info{
		mode_id       = 216001,
		class_id      = 216,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 216002
	};

%% 闪避
skill_info(216002) ->
	#skill_info{
		mode_id       = 216002,
		class_id      = 216,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 216003
	};

%% 闪避
skill_info(216003) ->
	#skill_info{
		mode_id       = 216003,
		class_id      = 216,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 216004
	};

%% 闪避
skill_info(216004) ->
	#skill_info{
		mode_id       = 216004,
		class_id      = 216,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 216005
	};

%% 闪避
skill_info(216005) ->
	#skill_info{
		mode_id       = 216005,
		class_id      = 216,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 216006
	};

%% 闪避
skill_info(216006) ->
	#skill_info{
		mode_id       = 216006,
		class_id      = 216,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 216007
	};

%% 闪避
skill_info(216007) ->
	#skill_info{
		mode_id       = 216007,
		class_id      = 216,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 216008
	};

%% 闪避
skill_info(216008) ->
	#skill_info{
		mode_id       = 216008,
		class_id      = 216,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 216009
	};

%% 闪避
skill_info(216009) ->
	#skill_info{
		mode_id       = 216009,
		class_id      = 216,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 216010
	};

%% 闪避
skill_info(216010) ->
	#skill_info{
		mode_id       = 216010,
		class_id      = 216,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 命中
skill_info(217001) ->
	#skill_info{
		mode_id       = 217001,
		class_id      = 217,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 217002
	};

%% 命中
skill_info(217002) ->
	#skill_info{
		mode_id       = 217002,
		class_id      = 217,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 217003
	};

%% 命中
skill_info(217003) ->
	#skill_info{
		mode_id       = 217003,
		class_id      = 217,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 217004
	};

%% 命中
skill_info(217004) ->
	#skill_info{
		mode_id       = 217004,
		class_id      = 217,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 217005
	};

%% 命中
skill_info(217005) ->
	#skill_info{
		mode_id       = 217005,
		class_id      = 217,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 217006
	};

%% 命中
skill_info(217006) ->
	#skill_info{
		mode_id       = 217006,
		class_id      = 217,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 217007
	};

%% 命中
skill_info(217007) ->
	#skill_info{
		mode_id       = 217007,
		class_id      = 217,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 217008
	};

%% 命中
skill_info(217008) ->
	#skill_info{
		mode_id       = 217008,
		class_id      = 217,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 217009
	};

%% 命中
skill_info(217009) ->
	#skill_info{
		mode_id       = 217009,
		class_id      = 217,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 217010
	};

%% 命中
skill_info(217010) ->
	#skill_info{
		mode_id       = 217010,
		class_id      = 217,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 幸运
skill_info(218001) ->
	#skill_info{
		mode_id       = 218001,
		class_id      = 218,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 218002
	};

%% 幸运
skill_info(218002) ->
	#skill_info{
		mode_id       = 218002,
		class_id      = 218,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 218003
	};

%% 幸运
skill_info(218003) ->
	#skill_info{
		mode_id       = 218003,
		class_id      = 218,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 218004
	};

%% 幸运
skill_info(218004) ->
	#skill_info{
		mode_id       = 218004,
		class_id      = 218,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 218005
	};

%% 幸运
skill_info(218005) ->
	#skill_info{
		mode_id       = 218005,
		class_id      = 218,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 218006
	};

%% 幸运
skill_info(218006) ->
	#skill_info{
		mode_id       = 218006,
		class_id      = 218,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 218007
	};

%% 幸运
skill_info(218007) ->
	#skill_info{
		mode_id       = 218007,
		class_id      = 218,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 218008
	};

%% 幸运
skill_info(218008) ->
	#skill_info{
		mode_id       = 218008,
		class_id      = 218,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 218009
	};

%% 幸运
skill_info(218009) ->
	#skill_info{
		mode_id       = 218009,
		class_id      = 218,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 218010
	};

%% 幸运
skill_info(218010) ->
	#skill_info{
		mode_id       = 218010,
		class_id      = 218,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 反震
skill_info(219001) ->
	#skill_info{
		mode_id       = 219001,
		class_id      = 219,
		type          = 3,
		effect        = 1,
		level_up_exp  = 600,
		next_skill_id = 219002
	};

%% 反震
skill_info(219002) ->
	#skill_info{
		mode_id       = 219002,
		class_id      = 219,
		type          = 3,
		effect        = 1,
		level_up_exp  = 900,
		next_skill_id = 219003
	};

%% 反震
skill_info(219003) ->
	#skill_info{
		mode_id       = 219003,
		class_id      = 219,
		type          = 3,
		effect        = 1,
		level_up_exp  = 2000,
		next_skill_id = 219004
	};

%% 反震
skill_info(219004) ->
	#skill_info{
		mode_id       = 219004,
		class_id      = 219,
		type          = 3,
		effect        = 1,
		level_up_exp  = 6000,
		next_skill_id = 219005
	};

%% 反震
skill_info(219005) ->
	#skill_info{
		mode_id       = 219005,
		class_id      = 219,
		type          = 3,
		effect        = 1,
		level_up_exp  = 13000,
		next_skill_id = 219006
	};

%% 反震
skill_info(219006) ->
	#skill_info{
		mode_id       = 219006,
		class_id      = 219,
		type          = 3,
		effect        = 1,
		level_up_exp  = 16000,
		next_skill_id = 219007
	};

%% 反震
skill_info(219007) ->
	#skill_info{
		mode_id       = 219007,
		class_id      = 219,
		type          = 3,
		effect        = 1,
		level_up_exp  = 20000,
		next_skill_id = 219008
	};

%% 反震
skill_info(219008) ->
	#skill_info{
		mode_id       = 219008,
		class_id      = 219,
		type          = 3,
		effect        = 1,
		level_up_exp  = 24000,
		next_skill_id = 219009
	};

%% 反震
skill_info(219009) ->
	#skill_info{
		mode_id       = 219009,
		class_id      = 219,
		type          = 3,
		effect        = 1,
		level_up_exp  = 30000,
		next_skill_id = 219010
	};

%% 反震
skill_info(219010) ->
	#skill_info{
		mode_id       = 219010,
		class_id      = 219,
		type          = 3,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 破甲
skill_info(220001) ->
	#skill_info{
		mode_id       = 220001,
		class_id      = 220,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 220002
	};

%% 破甲
skill_info(220002) ->
	#skill_info{
		mode_id       = 220002,
		class_id      = 220,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 220003
	};

%% 破甲
skill_info(220003) ->
	#skill_info{
		mode_id       = 220003,
		class_id      = 220,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 220004
	};

%% 破甲
skill_info(220004) ->
	#skill_info{
		mode_id       = 220004,
		class_id      = 220,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 220005
	};

%% 破甲
skill_info(220005) ->
	#skill_info{
		mode_id       = 220005,
		class_id      = 220,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 220006
	};

%% 破甲
skill_info(220006) ->
	#skill_info{
		mode_id       = 220006,
		class_id      = 220,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 220007
	};

%% 破甲
skill_info(220007) ->
	#skill_info{
		mode_id       = 220007,
		class_id      = 220,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 220008
	};

%% 破甲
skill_info(220008) ->
	#skill_info{
		mode_id       = 220008,
		class_id      = 220,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 220009
	};

%% 破甲
skill_info(220009) ->
	#skill_info{
		mode_id       = 220009,
		class_id      = 220,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 220010
	};

%% 破甲
skill_info(220010) ->
	#skill_info{
		mode_id       = 220010,
		class_id      = 220,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 反击
skill_info(221001) ->
	#skill_info{
		mode_id       = 221001,
		class_id      = 221,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 221002
	};

%% 反击
skill_info(221002) ->
	#skill_info{
		mode_id       = 221002,
		class_id      = 221,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 221003
	};

%% 反击
skill_info(221003) ->
	#skill_info{
		mode_id       = 221003,
		class_id      = 221,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 221004
	};

%% 反击
skill_info(221004) ->
	#skill_info{
		mode_id       = 221004,
		class_id      = 221,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 221005
	};

%% 反击
skill_info(221005) ->
	#skill_info{
		mode_id       = 221005,
		class_id      = 221,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 221006
	};

%% 反击
skill_info(221006) ->
	#skill_info{
		mode_id       = 221006,
		class_id      = 221,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 221007
	};

%% 反击
skill_info(221007) ->
	#skill_info{
		mode_id       = 221007,
		class_id      = 221,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 221008
	};

%% 反击
skill_info(221008) ->
	#skill_info{
		mode_id       = 221008,
		class_id      = 221,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 221009
	};

%% 反击
skill_info(221009) ->
	#skill_info{
		mode_id       = 221009,
		class_id      = 221,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 221010
	};

%% 反击
skill_info(221010) ->
	#skill_info{
		mode_id       = 221010,
		class_id      = 221,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 致命
skill_info(222001) ->
	#skill_info{
		mode_id       = 222001,
		class_id      = 222,
		type          = 3,
		effect        = 2,
		level_up_exp  = 600,
		next_skill_id = 222002
	};

%% 致命
skill_info(222002) ->
	#skill_info{
		mode_id       = 222002,
		class_id      = 222,
		type          = 3,
		effect        = 2,
		level_up_exp  = 900,
		next_skill_id = 222003
	};

%% 致命
skill_info(222003) ->
	#skill_info{
		mode_id       = 222003,
		class_id      = 222,
		type          = 3,
		effect        = 2,
		level_up_exp  = 2000,
		next_skill_id = 222004
	};

%% 致命
skill_info(222004) ->
	#skill_info{
		mode_id       = 222004,
		class_id      = 222,
		type          = 3,
		effect        = 2,
		level_up_exp  = 6000,
		next_skill_id = 222005
	};

%% 致命
skill_info(222005) ->
	#skill_info{
		mode_id       = 222005,
		class_id      = 222,
		type          = 3,
		effect        = 2,
		level_up_exp  = 13000,
		next_skill_id = 222006
	};

%% 致命
skill_info(222006) ->
	#skill_info{
		mode_id       = 222006,
		class_id      = 222,
		type          = 3,
		effect        = 2,
		level_up_exp  = 16000,
		next_skill_id = 222007
	};

%% 致命
skill_info(222007) ->
	#skill_info{
		mode_id       = 222007,
		class_id      = 222,
		type          = 3,
		effect        = 2,
		level_up_exp  = 20000,
		next_skill_id = 222008
	};

%% 致命
skill_info(222008) ->
	#skill_info{
		mode_id       = 222008,
		class_id      = 222,
		type          = 3,
		effect        = 2,
		level_up_exp  = 24000,
		next_skill_id = 222009
	};

%% 致命
skill_info(222009) ->
	#skill_info{
		mode_id       = 222009,
		class_id      = 222,
		type          = 3,
		effect        = 2,
		level_up_exp  = 30000,
		next_skill_id = 222010
	};

%% 致命
skill_info(222010) ->
	#skill_info{
		mode_id       = 222010,
		class_id      = 222,
		type          = 3,
		effect        = 2,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 扰乱军心
skill_info(223001) ->
	#skill_info{
		mode_id       = 223001,
		class_id      = 223,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 破阵攻心
skill_info(224001) ->
	#skill_info{
		mode_id       = 224001,
		class_id      = 224,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 天护之阵
skill_info(225001) ->
	#skill_info{
		mode_id       = 225001,
		class_id      = 225,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 镇守
skill_info(226001) ->
	#skill_info{
		mode_id       = 226001,
		class_id      = 226,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 怒袭
skill_info(227001) ->
	#skill_info{
		mode_id       = 227001,
		class_id      = 227,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 复仇
skill_info(228001) ->
	#skill_info{
		mode_id       = 228001,
		class_id      = 228,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 吸血
skill_info(229001) ->
	#skill_info{
		mode_id       = 229001,
		class_id      = 229,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 绝杀
skill_info(230001) ->
	#skill_info{
		mode_id       = 230001,
		class_id      = 230,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 追魂之刃
skill_info(231001) ->
	#skill_info{
		mode_id       = 231001,
		class_id      = 231,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 虚空一击
skill_info(232001) ->
	#skill_info{
		mode_id       = 232001,
		class_id      = 232,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 流云刺
skill_info(233001) ->
	#skill_info{
		mode_id       = 233001,
		class_id      = 233,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 虎啸破
skill_info(234001) ->
	#skill_info{
		mode_id       = 234001,
		class_id      = 234,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 连环杀阵
skill_info(235001) ->
	#skill_info{
		mode_id       = 235001,
		class_id      = 235,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 冰凌笺
skill_info(236001) ->
	#skill_info{
		mode_id       = 236001,
		class_id      = 236,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 祭风术
skill_info(237001) ->
	#skill_info{
		mode_id       = 237001,
		class_id      = 237,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 分光诀
skill_info(238001) ->
	#skill_info{
		mode_id       = 238001,
		class_id      = 238,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 凝劲术
skill_info(239001) ->
	#skill_info{
		mode_id       = 239001,
		class_id      = 239,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 激狂诀
skill_info(240001) ->
	#skill_info{
		mode_id       = 240001,
		class_id      = 240,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 狂风划影
skill_info(241001) ->
	#skill_info{
		mode_id       = 241001,
		class_id      = 241,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 三魂回春
skill_info(242001) ->
	#skill_info{
		mode_id       = 242001,
		class_id      = 242,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 元灵之光
skill_info(243001) ->
	#skill_info{
		mode_id       = 243001,
		class_id      = 243,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 净衣术
skill_info(244001) ->
	#skill_info{
		mode_id       = 244001,
		class_id      = 244,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 药王经
skill_info(245001) ->
	#skill_info{
		mode_id       = 245001,
		class_id      = 245,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 仙风万里
skill_info(246001) ->
	#skill_info{
		mode_id       = 246001,
		class_id      = 246,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 清心咒
skill_info(247001) ->
	#skill_info{
		mode_id       = 247001,
		class_id      = 247,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 坚若磐石
skill_info(248001) ->
	#skill_info{
		mode_id       = 248001,
		class_id      = 248,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 105006
	};

%% 背水一战
skill_info(249001) ->
	#skill_info{
		mode_id       = 249001,
		class_id      = 249,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 106006
	};

%% 战意激荡
skill_info(250001) ->
	#skill_info{
		mode_id       = 250001,
		class_id      = 250,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 108006
	};

%% 霸刃连斩
skill_info(251001) ->
	#skill_info{
		mode_id       = 251001,
		class_id      = 251,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 109006
	};

%% 横扫千军
skill_info(252001) ->
	#skill_info{
		mode_id       = 252001,
		class_id      = 252,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 110006
	};

%% 暴怒冲锋
skill_info(253001) ->
	#skill_info{
		mode_id       = 253001,
		class_id      = 253,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 乘胜追击
skill_info(254001) ->
	#skill_info{
		mode_id       = 254001,
		class_id      = 254,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 破军之势
skill_info(255001) ->
	#skill_info{
		mode_id       = 255001,
		class_id      = 255,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 113006
	};

%% 龙战八方
skill_info(256001) ->
	#skill_info{
		mode_id       = 256001,
		class_id      = 256,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 雷光咒
skill_info(257001) ->
	#skill_info{
		mode_id       = 257001,
		class_id      = 257,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 116006
	};

%% 强兵咒
skill_info(258001) ->
	#skill_info{
		mode_id       = 258001,
		class_id      = 258,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 117006
	};

%% 破军咒
skill_info(259001) ->
	#skill_info{
		mode_id       = 259001,
		class_id      = 259,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 118006
	};

%% 削弱
skill_info(260001) ->
	#skill_info{
		mode_id       = 260001,
		class_id      = 260,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 睡眠
skill_info(261001) ->
	#skill_info{
		mode_id       = 261001,
		class_id      = 261,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 摧枯拉朽
skill_info(262001) ->
	#skill_info{
		mode_id       = 262001,
		class_id      = 262,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 大地震击
skill_info(263001) ->
	#skill_info{
		mode_id       = 263001,
		class_id      = 263,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 狂风骤雨
skill_info(264001) ->
	#skill_info{
		mode_id       = 264001,
		class_id      = 264,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 撕裂怒吼
skill_info(265001) ->
	#skill_info{
		mode_id       = 265001,
		class_id      = 265,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 剑刃乱舞
skill_info(266001) ->
	#skill_info{
		mode_id       = 266001,
		class_id      = 266,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 破胆怒吼
skill_info(267001) ->
	#skill_info{
		mode_id       = 267001,
		class_id      = 267,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 春日花语
skill_info(268001) ->
	#skill_info{
		mode_id       = 268001,
		class_id      = 268,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 压制打击
skill_info(269001) ->
	#skill_info{
		mode_id       = 269001,
		class_id      = 269,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 血性饥渴
skill_info(270001) ->
	#skill_info{
		mode_id       = 270001,
		class_id      = 270,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 华光普照
skill_info(271001) ->
	#skill_info{
		mode_id       = 271001,
		class_id      = 271,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 疯狂追击
skill_info(272001) ->
	#skill_info{
		mode_id       = 272001,
		class_id      = 272,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 诅咒之印
skill_info(273001) ->
	#skill_info{
		mode_id       = 273001,
		class_id      = 273,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 伤害吸收
skill_info(274001) ->
	#skill_info{
		mode_id       = 274001,
		class_id      = 274,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 钉刺护盾
skill_info(275001) ->
	#skill_info{
		mode_id       = 275001,
		class_id      = 275,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 背水一击
skill_info(276001) ->
	#skill_info{
		mode_id       = 276001,
		class_id      = 276,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 汲取
skill_info(277001) ->
	#skill_info{
		mode_id       = 277001,
		class_id      = 277,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 削弱
skill_info(278001) ->
	#skill_info{
		mode_id       = 278001,
		class_id      = 278,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 睡眠
skill_info(279001) ->
	#skill_info{
		mode_id       = 279001,
		class_id      = 279,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 重击
skill_info(280001) ->
	#skill_info{
		mode_id       = 280001,
		class_id      = 280,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 强攻
skill_info(281001) ->
	#skill_info{
		mode_id       = 281001,
		class_id      = 281,
		type          = 4,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 梦魇阴影
skill_info(282001) ->
	#skill_info{
		mode_id       = 282001,
		class_id      = 282,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 毒雾
skill_info(283001) ->
	#skill_info{
		mode_id       = 283001,
		class_id      = 283,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 幽冥剧毒
skill_info(284001) ->
	#skill_info{
		mode_id       = 284001,
		class_id      = 284,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 伤害反弹
skill_info(285001) ->
	#skill_info{
		mode_id       = 285001,
		class_id      = 285,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 削弱
skill_info(286001) ->
	#skill_info{
		mode_id       = 286001,
		class_id      = 286,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 睡眠
skill_info(287001) ->
	#skill_info{
		mode_id       = 287001,
		class_id      = 287,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 重击
skill_info(288001) ->
	#skill_info{
		mode_id       = 288001,
		class_id      = 288,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	};

%% 强攻
skill_info(289001) ->
	#skill_info{
		mode_id       = 289001,
		class_id      = 289,
		type          = 1,
		effect        = 1,
		level_up_exp  = 0,
		next_skill_id = 0
	}.


%%================================================
%% 根据刷新技能的个数获取对应消耗的银币
get_refresh_cost(1) -> 10000;

get_refresh_cost(2) -> 20000;

get_refresh_cost(3) -> 30000;

get_refresh_cost(4) -> 40000;

get_refresh_cost(5) -> 50000;

get_refresh_cost(6) -> 60000;

get_refresh_cost(7) -> 70000;

get_refresh_cost(8) -> 80000.


%%================================================
%% 根据刷新技能的个数获取对应消耗的银币
get_fixed_cost(1) -> 5;

get_fixed_cost(2) -> 20;

get_fixed_cost(3) -> 30;

get_fixed_cost(4) -> 40;

get_fixed_cost(5) -> 50;

get_fixed_cost(6) -> 60;

get_fixed_cost(7) -> 70;

get_fixed_cost(8) -> 80.


%%================================================
%% 根据平均天赋值获取对应的技能孔数量
get_skill_hole_nums(AverageTalent) when AverageTalent >= 100 -> 6;

get_skill_hole_nums(AverageTalent) when AverageTalent >= 90 -> 5;

get_skill_hole_nums(AverageTalent) when AverageTalent >= 80 -> 4;

get_skill_hole_nums(AverageTalent) when AverageTalent >= 70 -> 3;

get_skill_hole_nums(AverageTalent) when AverageTalent >= 60 -> 2;

get_skill_hole_nums(AverageTalent) when AverageTalent >= 50 -> 1;

get_skill_hole_nums(AverageTalent) when AverageTalent >= 0 -> 0.


%%================================================
%% 根据技能模型id获取其加成
get_role_added_attri(204001) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_baoji      = 6
	};

get_role_added_attri(204002) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_baoji      = 10
	};

get_role_added_attri(204003) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_baoji      = 15
	};

get_role_added_attri(204004) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_baoji      = 23
	};

get_role_added_attri(204005) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_baoji      = 32
	};

get_role_added_attri(204006) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_baoji      = 43
	};

get_role_added_attri(204007) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_baoji      = 55
	};

get_role_added_attri(204008) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_baoji      = 68
	};

get_role_added_attri(204009) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_baoji      = 83
	};

get_role_added_attri(204010) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_baoji      = 100
	};

get_role_added_attri(208001) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_def         = 90
	};

get_role_added_attri(208002) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_def         = 210
	};

get_role_added_attri(208003) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_def         = 360
	};

get_role_added_attri(208004) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_def         = 600
	};

get_role_added_attri(208005) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_def         = 870
	};

get_role_added_attri(208006) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_def         = 1200
	};

get_role_added_attri(208007) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_def         = 1560
	};

get_role_added_attri(208008) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_def         = 1950
	};

get_role_added_attri(208009) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_def         = 2400
	};

get_role_added_attri(208010) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_def         = 3000
	};

get_role_added_attri(209001) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_def         = 90
	};

get_role_added_attri(209002) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_def         = 210
	};

get_role_added_attri(209003) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_def         = 360
	};

get_role_added_attri(209004) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_def         = 600
	};

get_role_added_attri(209005) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_def         = 870
	};

get_role_added_attri(209006) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_def         = 1200
	};

get_role_added_attri(209007) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_def         = 1560
	};

get_role_added_attri(209008) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_def         = 1950
	};

get_role_added_attri(209009) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_def         = 2400
	};

get_role_added_attri(209010) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_def         = 3000
	};

get_role_added_attri(210001) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_speed      = 20
	};

get_role_added_attri(210002) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_speed      = 60
	};

get_role_added_attri(210003) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_speed      = 100
	};

get_role_added_attri(210004) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_speed      = 160
	};

get_role_added_attri(210005) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_speed      = 230
	};

get_role_added_attri(210006) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_speed      = 320
	};

get_role_added_attri(210007) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_speed      = 420
	};

get_role_added_attri(210008) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_speed      = 520
	};

get_role_added_attri(210009) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_speed      = 640
	};

get_role_added_attri(210010) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_speed      = 800
	};

get_role_added_attri(211001) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_att         = 60
	};

get_role_added_attri(211002) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_att         = 140
	};

get_role_added_attri(211003) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_att         = 240
	};

get_role_added_attri(211004) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_att         = 400
	};

get_role_added_attri(211005) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_att         = 580
	};

get_role_added_attri(211006) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_att         = 800
	};

get_role_added_attri(211007) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_att         = 1040
	};

get_role_added_attri(211008) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_att         = 1300
	};

get_role_added_attri(211009) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_att         = 1600
	};

get_role_added_attri(211010) ->
	#role_update_attri{
		gd_liliang    = 0,
		p_att         = 2000
	};

get_role_added_attri(212001) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_att         = 60
	};

get_role_added_attri(212002) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_att         = 140
	};

get_role_added_attri(212003) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_att         = 240
	};

get_role_added_attri(212004) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_att         = 400
	};

get_role_added_attri(212005) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_att         = 580
	};

get_role_added_attri(212006) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_att         = 800
	};

get_role_added_attri(212007) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_att         = 1040
	};

get_role_added_attri(212008) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_att         = 1300
	};

get_role_added_attri(212009) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_att         = 1600
	};

get_role_added_attri(212010) ->
	#role_update_attri{
		gd_liliang    = 0,
		m_att         = 2000
	};

get_role_added_attri(213001) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_maxHp      = 150
	};

get_role_added_attri(213002) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_maxHp      = 350
	};

get_role_added_attri(213003) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_maxHp      = 600
	};

get_role_added_attri(213004) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_maxHp      = 1000
	};

get_role_added_attri(213005) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_maxHp      = 1450
	};

get_role_added_attri(213006) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_maxHp      = 2000
	};

get_role_added_attri(213007) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_maxHp      = 2600
	};

get_role_added_attri(213008) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_maxHp      = 3250
	};

get_role_added_attri(213009) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_maxHp      = 4000
	};

get_role_added_attri(213010) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_maxHp      = 5000
	};

get_role_added_attri(215001) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_gedang     = 5
	};

get_role_added_attri(215002) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_gedang     = 10
	};

get_role_added_attri(215003) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_gedang     = 15
	};

get_role_added_attri(215004) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_gedang     = 20
	};

get_role_added_attri(215005) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_gedang     = 25
	};

get_role_added_attri(215006) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_gedang     = 30
	};

get_role_added_attri(215007) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_gedang     = 35
	};

get_role_added_attri(215008) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_gedang     = 40
	};

get_role_added_attri(215009) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_gedang     = 45
	};

get_role_added_attri(215010) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_gedang     = 50
	};

get_role_added_attri(216001) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_shanbi     = 6
	};

get_role_added_attri(216002) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_shanbi     = 10
	};

get_role_added_attri(216003) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_shanbi     = 15
	};

get_role_added_attri(216004) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_shanbi     = 23
	};

get_role_added_attri(216005) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_shanbi     = 32
	};

get_role_added_attri(216006) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_shanbi     = 43
	};

get_role_added_attri(216007) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_shanbi     = 55
	};

get_role_added_attri(216008) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_shanbi     = 68
	};

get_role_added_attri(216009) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_shanbi     = 83
	};

get_role_added_attri(216010) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_shanbi     = 100
	};

get_role_added_attri(217001) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_mingzhong  = 6
	};

get_role_added_attri(217002) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_mingzhong  = 10
	};

get_role_added_attri(217003) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_mingzhong  = 15
	};

get_role_added_attri(217004) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_mingzhong  = 23
	};

get_role_added_attri(217005) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_mingzhong  = 32
	};

get_role_added_attri(217006) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_mingzhong  = 43
	};

get_role_added_attri(217007) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_mingzhong  = 55
	};

get_role_added_attri(217008) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_mingzhong  = 68
	};

get_role_added_attri(217009) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_mingzhong  = 83
	};

get_role_added_attri(217010) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_mingzhong  = 100
	};

get_role_added_attri(218001) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_xingyun    = 6
	};

get_role_added_attri(218002) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_xingyun    = 10
	};

get_role_added_attri(218003) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_xingyun    = 15
	};

get_role_added_attri(218004) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_xingyun    = 23
	};

get_role_added_attri(218005) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_xingyun    = 32
	};

get_role_added_attri(218006) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_xingyun    = 43
	};

get_role_added_attri(218007) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_xingyun    = 55
	};

get_role_added_attri(218008) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_xingyun    = 68
	};

get_role_added_attri(218009) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_xingyun    = 83
	};

get_role_added_attri(218010) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_xingyun    = 100
	};

get_role_added_attri(220001) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_pojia      = 6
	};

get_role_added_attri(220002) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_pojia      = 10
	};

get_role_added_attri(220003) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_pojia      = 15
	};

get_role_added_attri(220004) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_pojia      = 23
	};

get_role_added_attri(220005) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_pojia      = 32
	};

get_role_added_attri(220006) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_pojia      = 43
	};

get_role_added_attri(220007) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_pojia      = 55
	};

get_role_added_attri(220008) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_pojia      = 68
	};

get_role_added_attri(220009) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_pojia      = 83
	};

get_role_added_attri(220010) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_pojia      = 100
	};

get_role_added_attri(221001) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_fanji      = 6
	};

get_role_added_attri(221002) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_fanji      = 10
	};

get_role_added_attri(221003) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_fanji      = 15
	};

get_role_added_attri(221004) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_fanji      = 23
	};

get_role_added_attri(221005) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_fanji      = 32
	};

get_role_added_attri(221006) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_fanji      = 43
	};

get_role_added_attri(221007) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_fanji      = 55
	};

get_role_added_attri(221008) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_fanji      = 68
	};

get_role_added_attri(221009) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_fanji      = 83
	};

get_role_added_attri(221010) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_fanji      = 100
	};

get_role_added_attri(222001) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_zhiming    = 6
	};

get_role_added_attri(222002) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_zhiming    = 10
	};

get_role_added_attri(222003) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_zhiming    = 15
	};

get_role_added_attri(222004) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_zhiming    = 23
	};

get_role_added_attri(222005) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_zhiming    = 32
	};

get_role_added_attri(222006) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_zhiming    = 43
	};

get_role_added_attri(222007) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_zhiming    = 55
	};

get_role_added_attri(222008) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_zhiming    = 68
	};

get_role_added_attri(222009) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_zhiming    = 83
	};

get_role_added_attri(222010) ->
	#role_update_attri{
		gd_liliang    = 0,
		gd_zhiming    = 100
	}.


%%================================================
