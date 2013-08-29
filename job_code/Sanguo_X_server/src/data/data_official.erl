-module(data_official).

-compile(export_all).

-include("common.hrl").

%% 根据军功（即声望）获取其官职
get_officail_position(P) when P >= 300000 -> 21;

get_officail_position(P) when P >= 240000 -> 20;

get_officail_position(P) when P >= 180000 -> 19;

get_officail_position(P) when P >= 145000 -> 18;

get_officail_position(P) when P >= 125000 -> 17;

get_officail_position(P) when P >= 105000 -> 16;

get_officail_position(P) when P >= 85000 -> 15;

get_officail_position(P) when P >= 75000 -> 14;

get_officail_position(P) when P >= 65000 -> 13;

get_officail_position(P) when P >= 55000 -> 12;

get_officail_position(P) when P >= 45000 -> 11;

get_officail_position(P) when P >= 40000 -> 10;

get_officail_position(P) when P >= 35000 -> 9;

get_officail_position(P) when P >= 30000 -> 8;

get_officail_position(P) when P >= 25000 -> 7;

get_officail_position(P) when P >= 20000 -> 6;

get_officail_position(P) when P >= 15000 -> 5;

get_officail_position(P) when P >= 8000 -> 4;

get_officail_position(P) when P >= 5000 -> 3;

get_officail_position(P) when P >= 2000 -> 2;

get_officail_position(P) when P >= 0 -> 1.


%%================================================
%% 根据军功（即声望）获取其官职
get_fenglu(1) -> 1000;

get_fenglu(2) -> 4000;

get_fenglu(3) -> 7000;

get_fenglu(4) -> 10000;

get_fenglu(5) -> 13000;

get_fenglu(6) -> 16000;

get_fenglu(7) -> 19000;

get_fenglu(8) -> 22000;

get_fenglu(9) -> 25000;

get_fenglu(10) -> 28000;

get_fenglu(11) -> 31000;

get_fenglu(12) -> 34000;

get_fenglu(13) -> 37000;

get_fenglu(14) -> 40000;

get_fenglu(15) -> 43000;

get_fenglu(16) -> 46000;

get_fenglu(17) -> 49000;

get_fenglu(18) -> 52000;

get_fenglu(19) -> 55000;

get_fenglu(20) -> 58000;

get_fenglu(21) -> 61000.


%%================================================
%% 根据当前器魂等级获取修炼的时间
get_leveling_time(0) -> 120;

get_leveling_time(1) -> 420;

get_leveling_time(2) -> 720;

get_leveling_time(3) -> 1020;

get_leveling_time(4) -> 1320;

get_leveling_time(5) -> 1620;

get_leveling_time(6) -> 2020;

get_leveling_time(7) -> 2420;

get_leveling_time(8) -> 2820;

get_leveling_time(9) -> 3220;

get_leveling_time(10) -> 3820;

get_leveling_time(11) -> 4420;

get_leveling_time(12) -> 5020;

get_leveling_time(13) -> 5920;

get_leveling_time(14) -> 6820;

get_leveling_time(15) -> 8020;

get_leveling_time(16) -> 9220;

get_leveling_time(17) -> 10420;

get_leveling_time(18) -> 11620;

get_leveling_time(19) -> 12820;

get_leveling_time(20) -> 14320;

get_leveling_time(21) -> 15820;

get_leveling_time(22) -> 17320;

get_leveling_time(23) -> 18820;

get_leveling_time(24) -> 20320;

get_leveling_time(25) -> 21920;

get_leveling_time(26) -> 23520;

get_leveling_time(27) -> 25120;

get_leveling_time(28) -> 26720;

get_leveling_time(29) -> 28320;

get_leveling_time(30) -> 30320;

get_leveling_time(31) -> 32320;

get_leveling_time(32) -> 34320;

get_leveling_time(33) -> 36320;

get_leveling_time(34) -> 38320;

get_leveling_time(35) -> 40820;

get_leveling_time(36) -> 43320;

get_leveling_time(37) -> 45820;

get_leveling_time(38) -> 48320;

get_leveling_time(39) -> 50820;

get_leveling_time(40) -> 53820;

get_leveling_time(41) -> 56820;

get_leveling_time(42) -> 59820;

get_leveling_time(43) -> 62820;

get_leveling_time(44) -> 65820;

get_leveling_time(45) -> 69820;

get_leveling_time(46) -> 73820;

get_leveling_time(47) -> 77820;

get_leveling_time(48) -> 81820;

get_leveling_time(49) -> 85820;

get_leveling_time(50) -> 89820.


%%================================================
%% 根据当前器魂等级获取修炼器魂的银币消耗
get_leveling_cost(0) -> 5000;

get_leveling_cost(1) -> 5700;

get_leveling_cost(2) -> 6400;

get_leveling_cost(3) -> 7100;

get_leveling_cost(4) -> 7900;

get_leveling_cost(5) -> 8700;

get_leveling_cost(6) -> 9700;

get_leveling_cost(7) -> 10800;

get_leveling_cost(8) -> 12000;

get_leveling_cost(9) -> 13300;

get_leveling_cost(10) -> 14800;

get_leveling_cost(11) -> 16400;

get_leveling_cost(12) -> 18200;

get_leveling_cost(13) -> 20300;

get_leveling_cost(14) -> 22500;

get_leveling_cost(15) -> 25000;

get_leveling_cost(16) -> 27800;

get_leveling_cost(17) -> 30900;

get_leveling_cost(18) -> 34300;

get_leveling_cost(19) -> 38200;

get_leveling_cost(20) -> 42400;

get_leveling_cost(21) -> 47100;

get_leveling_cost(22) -> 52300;

get_leveling_cost(23) -> 58100;

get_leveling_cost(24) -> 64600;

get_leveling_cost(25) -> 71800;

get_leveling_cost(26) -> 79800;

get_leveling_cost(27) -> 88600;

get_leveling_cost(28) -> 98500;

get_leveling_cost(29) -> 109400;

get_leveling_cost(30) -> 121600;

get_leveling_cost(31) -> 135100;

get_leveling_cost(32) -> 150100;

get_leveling_cost(33) -> 166800;

get_leveling_cost(34) -> 185300;

get_leveling_cost(35) -> 205900;

get_leveling_cost(36) -> 228800;

get_leveling_cost(37) -> 254200;

get_leveling_cost(38) -> 282400;

get_leveling_cost(39) -> 313800;

get_leveling_cost(40) -> 348700;

get_leveling_cost(41) -> 387400;

get_leveling_cost(42) -> 430500;

get_leveling_cost(43) -> 478300;

get_leveling_cost(44) -> 531400;

get_leveling_cost(45) -> 590500;

get_leveling_cost(46) -> 656100;

get_leveling_cost(47) -> 729000;

get_leveling_cost(48) -> 810000;

get_leveling_cost(49) -> 900000;

get_leveling_cost(50) -> 1000000.


%%================================================
%% 根据品阶等级获取提升品阶的军功、元宝消耗
get_pinjie_up_cost(0) -> {6, 8};

get_pinjie_up_cost(1) -> {11, 8};

get_pinjie_up_cost(2) -> {16, 8};

get_pinjie_up_cost(3) -> {20, 8};

get_pinjie_up_cost(4) -> {25, 8};

get_pinjie_up_cost(5) -> {30, 8};

get_pinjie_up_cost(6) -> {35, 8};

get_pinjie_up_cost(7) -> {40, 8};

get_pinjie_up_cost(8) -> {44, 8};

get_pinjie_up_cost(9) -> {49, 8};

get_pinjie_up_cost(10) -> {54, 8};

get_pinjie_up_cost(11) -> {59, 8};

get_pinjie_up_cost(12) -> {64, 8};

get_pinjie_up_cost(13) -> {68, 8};

get_pinjie_up_cost(14) -> {73, 8};

get_pinjie_up_cost(15) -> {78, 8};

get_pinjie_up_cost(16) -> {83, 8};

get_pinjie_up_cost(17) -> {88, 8};

get_pinjie_up_cost(18) -> {92, 8};

get_pinjie_up_cost(19) -> {97, 8};

get_pinjie_up_cost(20) -> {102, 8};

get_pinjie_up_cost(21) -> {108, 8};

get_pinjie_up_cost(22) -> {114, 8};

get_pinjie_up_cost(23) -> {120, 8};

get_pinjie_up_cost(24) -> {126, 8};

get_pinjie_up_cost(25) -> {132, 8};

get_pinjie_up_cost(26) -> {144, 8};

get_pinjie_up_cost(27) -> {152, 8};

get_pinjie_up_cost(28) -> {161, 8};

get_pinjie_up_cost(29) -> {169, 8};

get_pinjie_up_cost(30) -> {178, 8};

get_pinjie_up_cost(31) -> {193, 8};

get_pinjie_up_cost(32) -> {209, 8};

get_pinjie_up_cost(33) -> {224, 8};

get_pinjie_up_cost(34) -> {240, 8};

get_pinjie_up_cost(35) -> {256, 8};

get_pinjie_up_cost(36) -> {271, 8};

get_pinjie_up_cost(37) -> {287, 8};

get_pinjie_up_cost(38) -> {302, 8};

get_pinjie_up_cost(39) -> {318, 8};

get_pinjie_up_cost(40) -> {334, 8};

get_pinjie_up_cost(41) -> {360, 8};

get_pinjie_up_cost(42) -> {386, 8};

get_pinjie_up_cost(43) -> {413, 8};

get_pinjie_up_cost(44) -> {439, 8};

get_pinjie_up_cost(45) -> {466, 8};

get_pinjie_up_cost(46) -> {492, 8};

get_pinjie_up_cost(47) -> {518, 8};

get_pinjie_up_cost(48) -> {545, 8};

get_pinjie_up_cost(49) -> {571, 8};

get_pinjie_up_cost(50) -> {598, 8}.


%%================================================
%% 获取神器阶段
%% 神器
get_shenqi_stage(QinhunLv, PinjieLv) when QinhunLv >= 50 andalso PinjieLv >= 50 -> 6;

%% 仙器
get_shenqi_stage(QinhunLv, PinjieLv) when QinhunLv >= 40 andalso PinjieLv >= 40 -> 5;

%% 魂器
get_shenqi_stage(QinhunLv, PinjieLv) when QinhunLv >= 30 andalso PinjieLv >= 30 -> 4;

%% 灵器
get_shenqi_stage(QinhunLv, PinjieLv) when QinhunLv >= 20 andalso PinjieLv >= 20 -> 3;

%% 宝器
get_shenqi_stage(QinhunLv, PinjieLv) when QinhunLv >= 13 andalso PinjieLv >= 10 -> 2;

%% 法器
get_shenqi_stage(QinhunLv, PinjieLv) when QinhunLv >= 6 andalso PinjieLv >= 4 -> 1;

%% 无
get_shenqi_stage(QinhunLv, PinjieLv) when QinhunLv >= 0 andalso PinjieLv >= 0 -> 0.


%%================================================
%% 根据器魂id和它的等级获取给武将属性的加成
%% 器魂：精0级，气血增加0
get_qihun_added_attri(1, 0) -> 0;

%% 器魂：精1级，气血增加32
get_qihun_added_attri(1, 1) -> 32;

%% 器魂：精2级，气血增加37
get_qihun_added_attri(1, 2) -> 37;

%% 器魂：精3级，气血增加44
get_qihun_added_attri(1, 3) -> 44;

%% 器魂：精4级，气血增加52
get_qihun_added_attri(1, 4) -> 52;

%% 器魂：精5级，气血增加61
get_qihun_added_attri(1, 5) -> 61;

%% 器魂：精6级，气血增加68
get_qihun_added_attri(1, 6) -> 68;

%% 器魂：精7级，气血增加76
get_qihun_added_attri(1, 7) -> 76;

%% 器魂：精8级，气血增加84
get_qihun_added_attri(1, 8) -> 84;

%% 器魂：精9级，气血增加90
get_qihun_added_attri(1, 9) -> 90;

%% 器魂：精10级，气血增加95
get_qihun_added_attri(1, 10) -> 95;

%% 器魂：精11级，气血增加102
get_qihun_added_attri(1, 11) -> 102;

%% 器魂：精12级，气血增加108
get_qihun_added_attri(1, 12) -> 108;

%% 器魂：精13级，气血增加115
get_qihun_added_attri(1, 13) -> 115;

%% 器魂：精14级，气血增加122
get_qihun_added_attri(1, 14) -> 122;

%% 器魂：精15级，气血增加130
get_qihun_added_attri(1, 15) -> 130;

%% 器魂：精16级，气血增加139
get_qihun_added_attri(1, 16) -> 139;

%% 器魂：精17级，气血增加147
get_qihun_added_attri(1, 17) -> 147;

%% 器魂：精18级，气血增加157
get_qihun_added_attri(1, 18) -> 157;

%% 器魂：精19级，气血增加167
get_qihun_added_attri(1, 19) -> 167;

%% 器魂：精20级，气血增加178
get_qihun_added_attri(1, 20) -> 178;

%% 器魂：精21级，气血增加189
get_qihun_added_attri(1, 21) -> 189;

%% 器魂：精22级，气血增加201
get_qihun_added_attri(1, 22) -> 201;

%% 器魂：精23级，气血增加214
get_qihun_added_attri(1, 23) -> 214;

%% 器魂：精24级，气血增加228
get_qihun_added_attri(1, 24) -> 228;

%% 器魂：精25级，气血增加242
get_qihun_added_attri(1, 25) -> 242;

%% 器魂：精26级，气血增加258
get_qihun_added_attri(1, 26) -> 258;

%% 器魂：精27级，气血增加274
get_qihun_added_attri(1, 27) -> 274;

%% 器魂：精28级，气血增加292
get_qihun_added_attri(1, 28) -> 292;

%% 器魂：精29级，气血增加310
get_qihun_added_attri(1, 29) -> 310;

%% 器魂：精30级，气血增加330
get_qihun_added_attri(1, 30) -> 330;

%% 器魂：精31级，气血增加351
get_qihun_added_attri(1, 31) -> 351;

%% 器魂：精32级，气血增加374
get_qihun_added_attri(1, 32) -> 374;

%% 器魂：精33级，气血增加398
get_qihun_added_attri(1, 33) -> 398;

%% 器魂：精34级，气血增加423
get_qihun_added_attri(1, 34) -> 423;

%% 器魂：精35级，气血增加450
get_qihun_added_attri(1, 35) -> 450;

%% 器魂：精36级，气血增加479
get_qihun_added_attri(1, 36) -> 479;

%% 器魂：精37级，气血增加509
get_qihun_added_attri(1, 37) -> 509;

%% 器魂：精38级，气血增加542
get_qihun_added_attri(1, 38) -> 542;

%% 器魂：精39级，气血增加577
get_qihun_added_attri(1, 39) -> 577;

%% 器魂：精40级，气血增加614
get_qihun_added_attri(1, 40) -> 614;

%% 器魂：精41级，气血增加653
get_qihun_added_attri(1, 41) -> 653;

%% 器魂：精42级，气血增加694
get_qihun_added_attri(1, 42) -> 694;

%% 器魂：精43级，气血增加739
get_qihun_added_attri(1, 43) -> 739;

%% 器魂：精44级，气血增加786
get_qihun_added_attri(1, 44) -> 786;

%% 器魂：精45级，气血增加836
get_qihun_added_attri(1, 45) -> 836;

%% 器魂：精46级，气血增加890
get_qihun_added_attri(1, 46) -> 890;

%% 器魂：精47级，气血增加946
get_qihun_added_attri(1, 47) -> 946;

%% 器魂：精48级，气血增加1007
get_qihun_added_attri(1, 48) -> 1007;

%% 器魂：精49级，气血增加1071
get_qihun_added_attri(1, 49) -> 1071;

%% 器魂：精50级，气血增加1140
get_qihun_added_attri(1, 50) -> 1140;

%% 器魂：力0级，物理攻击增加0
get_qihun_added_attri(2, 0) -> 0;

%% 器魂：力1级，物理攻击增加20
get_qihun_added_attri(2, 1) -> 20;

%% 器魂：力2级，物理攻击增加23
get_qihun_added_attri(2, 2) -> 23;

%% 器魂：力3级，物理攻击增加28
get_qihun_added_attri(2, 3) -> 28;

%% 器魂：力4级，物理攻击增加33
get_qihun_added_attri(2, 4) -> 33;

%% 器魂：力5级，物理攻击增加39
get_qihun_added_attri(2, 5) -> 39;

%% 器魂：力6级，物理攻击增加43
get_qihun_added_attri(2, 6) -> 43;

%% 器魂：力7级，物理攻击增加48
get_qihun_added_attri(2, 7) -> 48;

%% 器魂：力8级，物理攻击增加53
get_qihun_added_attri(2, 8) -> 53;

%% 器魂：力9级，物理攻击增加56
get_qihun_added_attri(2, 9) -> 56;

%% 器魂：力10级，物理攻击增加60
get_qihun_added_attri(2, 10) -> 60;

%% 器魂：力11级，物理攻击增加64
get_qihun_added_attri(2, 11) -> 64;

%% 器魂：力12级，物理攻击增加68
get_qihun_added_attri(2, 12) -> 68;

%% 器魂：力13级，物理攻击增加72
get_qihun_added_attri(2, 13) -> 72;

%% 器魂：力14级，物理攻击增加77
get_qihun_added_attri(2, 14) -> 77;

%% 器魂：力15级，物理攻击增加82
get_qihun_added_attri(2, 15) -> 82;

%% 器魂：力16级，物理攻击增加87
get_qihun_added_attri(2, 16) -> 87;

%% 器魂：力17级，物理攻击增加93
get_qihun_added_attri(2, 17) -> 93;

%% 器魂：力18级，物理攻击增加99
get_qihun_added_attri(2, 18) -> 99;

%% 器魂：力19级，物理攻击增加105
get_qihun_added_attri(2, 19) -> 105;

%% 器魂：力20级，物理攻击增加112
get_qihun_added_attri(2, 20) -> 112;

%% 器魂：力21级，物理攻击增加119
get_qihun_added_attri(2, 21) -> 119;

%% 器魂：力22级，物理攻击增加127
get_qihun_added_attri(2, 22) -> 127;

%% 器魂：力23级，物理攻击增加135
get_qihun_added_attri(2, 23) -> 135;

%% 器魂：力24级，物理攻击增加144
get_qihun_added_attri(2, 24) -> 144;

%% 器魂：力25级，物理攻击增加153
get_qihun_added_attri(2, 25) -> 153;

%% 器魂：力26级，物理攻击增加163
get_qihun_added_attri(2, 26) -> 163;

%% 器魂：力27级，物理攻击增加173
get_qihun_added_attri(2, 27) -> 173;

%% 器魂：力28级，物理攻击增加184
get_qihun_added_attri(2, 28) -> 184;

%% 器魂：力29级，物理攻击增加196
get_qihun_added_attri(2, 29) -> 196;

%% 器魂：力30级，物理攻击增加208
get_qihun_added_attri(2, 30) -> 208;

%% 器魂：力31级，物理攻击增加222
get_qihun_added_attri(2, 31) -> 222;

%% 器魂：力32级，物理攻击增加236
get_qihun_added_attri(2, 32) -> 236;

%% 器魂：力33级，物理攻击增加251
get_qihun_added_attri(2, 33) -> 251;

%% 器魂：力34级，物理攻击增加267
get_qihun_added_attri(2, 34) -> 267;

%% 器魂：力35级，物理攻击增加284
get_qihun_added_attri(2, 35) -> 284;

%% 器魂：力36级，物理攻击增加302
get_qihun_added_attri(2, 36) -> 302;

%% 器魂：力37级，物理攻击增加322
get_qihun_added_attri(2, 37) -> 322;

%% 器魂：力38级，物理攻击增加342
get_qihun_added_attri(2, 38) -> 342;

%% 器魂：力39级，物理攻击增加364
get_qihun_added_attri(2, 39) -> 364;

%% 器魂：力40级，物理攻击增加387
get_qihun_added_attri(2, 40) -> 387;

%% 器魂：力41级，物理攻击增加412
get_qihun_added_attri(2, 41) -> 412;

%% 器魂：力42级，物理攻击增加438
get_qihun_added_attri(2, 42) -> 438;

%% 器魂：力43级，物理攻击增加466
get_qihun_added_attri(2, 43) -> 466;

%% 器魂：力44级，物理攻击增加496
get_qihun_added_attri(2, 44) -> 496;

%% 器魂：力45级，物理攻击增加528
get_qihun_added_attri(2, 45) -> 528;

%% 器魂：力46级，物理攻击增加562
get_qihun_added_attri(2, 46) -> 562;

%% 器魂：力47级，物理攻击增加598
get_qihun_added_attri(2, 47) -> 598;

%% 器魂：力48级，物理攻击增加636
get_qihun_added_attri(2, 48) -> 636;

%% 器魂：力49级，物理攻击增加676
get_qihun_added_attri(2, 49) -> 676;

%% 器魂：力50级，物理攻击增加720
get_qihun_added_attri(2, 50) -> 720;

%% 器魂：元0级，法术攻击增加0
get_qihun_added_attri(3, 0) -> 0;

%% 器魂：元1级，法术攻击增加20
get_qihun_added_attri(3, 1) -> 20;

%% 器魂：元2级，法术攻击增加23
get_qihun_added_attri(3, 2) -> 23;

%% 器魂：元3级，法术攻击增加28
get_qihun_added_attri(3, 3) -> 28;

%% 器魂：元4级，法术攻击增加33
get_qihun_added_attri(3, 4) -> 33;

%% 器魂：元5级，法术攻击增加39
get_qihun_added_attri(3, 5) -> 39;

%% 器魂：元6级，法术攻击增加43
get_qihun_added_attri(3, 6) -> 43;

%% 器魂：元7级，法术攻击增加48
get_qihun_added_attri(3, 7) -> 48;

%% 器魂：元8级，法术攻击增加53
get_qihun_added_attri(3, 8) -> 53;

%% 器魂：元9级，法术攻击增加56
get_qihun_added_attri(3, 9) -> 56;

%% 器魂：元10级，法术攻击增加60
get_qihun_added_attri(3, 10) -> 60;

%% 器魂：元11级，法术攻击增加64
get_qihun_added_attri(3, 11) -> 64;

%% 器魂：元12级，法术攻击增加68
get_qihun_added_attri(3, 12) -> 68;

%% 器魂：元13级，法术攻击增加72
get_qihun_added_attri(3, 13) -> 72;

%% 器魂：元14级，法术攻击增加77
get_qihun_added_attri(3, 14) -> 77;

%% 器魂：元15级，法术攻击增加82
get_qihun_added_attri(3, 15) -> 82;

%% 器魂：元16级，法术攻击增加87
get_qihun_added_attri(3, 16) -> 87;

%% 器魂：元17级，法术攻击增加93
get_qihun_added_attri(3, 17) -> 93;

%% 器魂：元18级，法术攻击增加99
get_qihun_added_attri(3, 18) -> 99;

%% 器魂：元19级，法术攻击增加105
get_qihun_added_attri(3, 19) -> 105;

%% 器魂：元20级，法术攻击增加112
get_qihun_added_attri(3, 20) -> 112;

%% 器魂：元21级，法术攻击增加119
get_qihun_added_attri(3, 21) -> 119;

%% 器魂：元22级，法术攻击增加127
get_qihun_added_attri(3, 22) -> 127;

%% 器魂：元23级，法术攻击增加135
get_qihun_added_attri(3, 23) -> 135;

%% 器魂：元24级，法术攻击增加144
get_qihun_added_attri(3, 24) -> 144;

%% 器魂：元25级，法术攻击增加153
get_qihun_added_attri(3, 25) -> 153;

%% 器魂：元26级，法术攻击增加163
get_qihun_added_attri(3, 26) -> 163;

%% 器魂：元27级，法术攻击增加173
get_qihun_added_attri(3, 27) -> 173;

%% 器魂：元28级，法术攻击增加184
get_qihun_added_attri(3, 28) -> 184;

%% 器魂：元29级，法术攻击增加196
get_qihun_added_attri(3, 29) -> 196;

%% 器魂：元30级，法术攻击增加208
get_qihun_added_attri(3, 30) -> 208;

%% 器魂：元31级，法术攻击增加222
get_qihun_added_attri(3, 31) -> 222;

%% 器魂：元32级，法术攻击增加236
get_qihun_added_attri(3, 32) -> 236;

%% 器魂：元33级，法术攻击增加251
get_qihun_added_attri(3, 33) -> 251;

%% 器魂：元34级，法术攻击增加267
get_qihun_added_attri(3, 34) -> 267;

%% 器魂：元35级，法术攻击增加284
get_qihun_added_attri(3, 35) -> 284;

%% 器魂：元36级，法术攻击增加302
get_qihun_added_attri(3, 36) -> 302;

%% 器魂：元37级，法术攻击增加322
get_qihun_added_attri(3, 37) -> 322;

%% 器魂：元38级，法术攻击增加342
get_qihun_added_attri(3, 38) -> 342;

%% 器魂：元39级，法术攻击增加364
get_qihun_added_attri(3, 39) -> 364;

%% 器魂：元40级，法术攻击增加387
get_qihun_added_attri(3, 40) -> 387;

%% 器魂：元41级，法术攻击增加412
get_qihun_added_attri(3, 41) -> 412;

%% 器魂：元42级，法术攻击增加438
get_qihun_added_attri(3, 42) -> 438;

%% 器魂：元43级，法术攻击增加466
get_qihun_added_attri(3, 43) -> 466;

%% 器魂：元44级，法术攻击增加496
get_qihun_added_attri(3, 44) -> 496;

%% 器魂：元45级，法术攻击增加528
get_qihun_added_attri(3, 45) -> 528;

%% 器魂：元46级，法术攻击增加562
get_qihun_added_attri(3, 46) -> 562;

%% 器魂：元47级，法术攻击增加598
get_qihun_added_attri(3, 47) -> 598;

%% 器魂：元48级，法术攻击增加636
get_qihun_added_attri(3, 48) -> 636;

%% 器魂：元49级，法术攻击增加676
get_qihun_added_attri(3, 49) -> 676;

%% 器魂：元50级，法术攻击增加720
get_qihun_added_attri(3, 50) -> 720;

%% 器魂：盾0级，物理防御增加0
get_qihun_added_attri(4, 0) -> 0;

%% 器魂：盾1级，物理防御增加23
get_qihun_added_attri(4, 1) -> 23;

%% 器魂：盾2级，物理防御增加27
get_qihun_added_attri(4, 2) -> 27;

%% 器魂：盾3级，物理防御增加32
get_qihun_added_attri(4, 3) -> 32;

%% 器魂：盾4级，物理防御增加37
get_qihun_added_attri(4, 4) -> 37;

%% 器魂：盾5级，物理防御增加44
get_qihun_added_attri(4, 5) -> 44;

%% 器魂：盾6级，物理防御增加49
get_qihun_added_attri(4, 6) -> 49;

%% 器魂：盾7级，物理防御增加54
get_qihun_added_attri(4, 7) -> 54;

%% 器魂：盾8级，物理防御增加60
get_qihun_added_attri(4, 8) -> 60;

%% 器魂：盾9级，物理防御增加64
get_qihun_added_attri(4, 9) -> 64;

%% 器魂：盾10级，物理防御增加69
get_qihun_added_attri(4, 10) -> 69;

%% 器魂：盾11级，物理防御增加73
get_qihun_added_attri(4, 11) -> 73;

%% 器魂：盾12级，物理防御增加78
get_qihun_added_attri(4, 12) -> 78;

%% 器魂：盾13级，物理防御增加83
get_qihun_added_attri(4, 13) -> 83;

%% 器魂：盾14级，物理防御增加88
get_qihun_added_attri(4, 14) -> 88;

%% 器魂：盾15级，物理防御增加94
get_qihun_added_attri(4, 15) -> 94;

%% 器魂：盾16级，物理防御增加100
get_qihun_added_attri(4, 16) -> 100;

%% 器魂：盾17级，物理防御增加106
get_qihun_added_attri(4, 17) -> 106;

%% 器魂：盾18级，物理防御增加113
get_qihun_added_attri(4, 18) -> 113;

%% 器魂：盾19级，物理防御增加120
get_qihun_added_attri(4, 19) -> 120;

%% 器魂：盾20级，物理防御增加128
get_qihun_added_attri(4, 20) -> 128;

%% 器魂：盾21级，物理防御增加136
get_qihun_added_attri(4, 21) -> 136;

%% 器魂：盾22级，物理防御增加145
get_qihun_added_attri(4, 22) -> 145;

%% 器魂：盾23级，物理防御增加154
get_qihun_added_attri(4, 23) -> 154;

%% 器魂：盾24级，物理防御增加164
get_qihun_added_attri(4, 24) -> 164;

%% 器魂：盾25级，物理防御增加174
get_qihun_added_attri(4, 25) -> 174;

%% 器魂：盾26级，物理防御增加185
get_qihun_added_attri(4, 26) -> 185;

%% 器魂：盾27级，物理防御增加197
get_qihun_added_attri(4, 27) -> 197;

%% 器魂：盾28级，物理防御增加210
get_qihun_added_attri(4, 28) -> 210;

%% 器魂：盾29级，物理防御增加223
get_qihun_added_attri(4, 29) -> 223;

%% 器魂：盾30级，物理防御增加237
get_qihun_added_attri(4, 30) -> 237;

%% 器魂：盾31级，物理防御增加253
get_qihun_added_attri(4, 31) -> 253;

%% 器魂：盾32级，物理防御增加269
get_qihun_added_attri(4, 32) -> 269;

%% 器魂：盾33级，物理防御增加286
get_qihun_added_attri(4, 33) -> 286;

%% 器魂：盾34级，物理防御增加304
get_qihun_added_attri(4, 34) -> 304;

%% 器魂：盾35级，物理防御增加324
get_qihun_added_attri(4, 35) -> 324;

%% 器魂：盾36级，物理防御增加344
get_qihun_added_attri(4, 36) -> 344;

%% 器魂：盾37级，物理防御增加366
get_qihun_added_attri(4, 37) -> 366;

%% 器魂：盾38级，物理防御增加390
get_qihun_added_attri(4, 38) -> 390;

%% 器魂：盾39级，物理防御增加415
get_qihun_added_attri(4, 39) -> 415;

%% 器魂：盾40级，物理防御增加441
get_qihun_added_attri(4, 40) -> 441;

%% 器魂：盾41级，物理防御增加469
get_qihun_added_attri(4, 41) -> 469;

%% 器魂：盾42级，物理防御增加499
get_qihun_added_attri(4, 42) -> 499;

%% 器魂：盾43级，物理防御增加531
get_qihun_added_attri(4, 43) -> 531;

%% 器魂：盾44级，物理防御增加565
get_qihun_added_attri(4, 44) -> 565;

%% 器魂：盾45级，物理防御增加601
get_qihun_added_attri(4, 45) -> 601;

%% 器魂：盾46级，物理防御增加640
get_qihun_added_attri(4, 46) -> 640;

%% 器魂：盾47级，物理防御增加681
get_qihun_added_attri(4, 47) -> 681;

%% 器魂：盾48级，物理防御增加724
get_qihun_added_attri(4, 48) -> 724;

%% 器魂：盾49级，物理防御增加770
get_qihun_added_attri(4, 49) -> 770;

%% 器魂：盾50级，物理防御增加820
get_qihun_added_attri(4, 50) -> 820;

%% 器魂：御0级，法术防御增加0
get_qihun_added_attri(5, 0) -> 0;

%% 器魂：御1级，法术防御增加23
get_qihun_added_attri(5, 1) -> 23;

%% 器魂：御2级，法术防御增加27
get_qihun_added_attri(5, 2) -> 27;

%% 器魂：御3级，法术防御增加32
get_qihun_added_attri(5, 3) -> 32;

%% 器魂：御4级，法术防御增加38
get_qihun_added_attri(5, 4) -> 38;

%% 器魂：御5级，法术防御增加44
get_qihun_added_attri(5, 5) -> 44;

%% 器魂：御6级，法术防御增加49
get_qihun_added_attri(5, 6) -> 49;

%% 器魂：御7级，法术防御增加55
get_qihun_added_attri(5, 7) -> 55;

%% 器魂：御8级，法术防御增加61
get_qihun_added_attri(5, 8) -> 61;

%% 器魂：御9级，法术防御增加65
get_qihun_added_attri(5, 9) -> 65;

%% 器魂：御10级，法术防御增加69
get_qihun_added_attri(5, 10) -> 69;

%% 器魂：御11级，法术防御增加73
get_qihun_added_attri(5, 11) -> 73;

%% 器魂：御12级，法术防御增加78
get_qihun_added_attri(5, 12) -> 78;

%% 器魂：御13级，法术防御增加83
get_qihun_added_attri(5, 13) -> 83;

%% 器魂：御14级，法术防御增加88
get_qihun_added_attri(5, 14) -> 88;

%% 器魂：御15级，法术防御增加94
get_qihun_added_attri(5, 15) -> 94;

%% 器魂：御16级，法术防御增加100
get_qihun_added_attri(5, 16) -> 100;

%% 器魂：御17级，法术防御增加106
get_qihun_added_attri(5, 17) -> 106;

%% 器魂：御18级，法术防御增加113
get_qihun_added_attri(5, 18) -> 113;

%% 器魂：御19级，法术防御增加120
get_qihun_added_attri(5, 19) -> 120;

%% 器魂：御20级，法术防御增加128
get_qihun_added_attri(5, 20) -> 128;

%% 器魂：御21级，法术防御增加136
get_qihun_added_attri(5, 21) -> 136;

%% 器魂：御22级，法术防御增加145
get_qihun_added_attri(5, 22) -> 145;

%% 器魂：御23级，法术防御增加154
get_qihun_added_attri(5, 23) -> 154;

%% 器魂：御24级，法术防御增加164
get_qihun_added_attri(5, 24) -> 164;

%% 器魂：御25级，法术防御增加175
get_qihun_added_attri(5, 25) -> 175;

%% 器魂：御26级，法术防御增加186
get_qihun_added_attri(5, 26) -> 186;

%% 器魂：御27级，法术防御增加198
get_qihun_added_attri(5, 27) -> 198;

%% 器魂：御28级，法术防御增加210
get_qihun_added_attri(5, 28) -> 210;

%% 器魂：御29级，法术防御增加224
get_qihun_added_attri(5, 29) -> 224;

%% 器魂：御30级，法术防御增加238
get_qihun_added_attri(5, 30) -> 238;

%% 器魂：御31级，法术防御增加253
get_qihun_added_attri(5, 31) -> 253;

%% 器魂：御32级，法术防御增加269
get_qihun_added_attri(5, 32) -> 269;

%% 器魂：御33级，法术防御增加286
get_qihun_added_attri(5, 33) -> 286;

%% 器魂：御34级，法术防御增加305
get_qihun_added_attri(5, 34) -> 305;

%% 器魂：御35级，法术防御增加324
get_qihun_added_attri(5, 35) -> 324;

%% 器魂：御36级，法术防御增加345
get_qihun_added_attri(5, 36) -> 345;

%% 器魂：御37级，法术防御增加367
get_qihun_added_attri(5, 37) -> 367;

%% 器魂：御38级，法术防御增加390
get_qihun_added_attri(5, 38) -> 390;

%% 器魂：御39级，法术防御增加415
get_qihun_added_attri(5, 39) -> 415;

%% 器魂：御40级，法术防御增加442
get_qihun_added_attri(5, 40) -> 442;

%% 器魂：御41级，法术防御增加470
get_qihun_added_attri(5, 41) -> 470;

%% 器魂：御42级，法术防御增加500
get_qihun_added_attri(5, 42) -> 500;

%% 器魂：御43级，法术防御增加532
get_qihun_added_attri(5, 43) -> 532;

%% 器魂：御44级，法术防御增加566
get_qihun_added_attri(5, 44) -> 566;

%% 器魂：御45级，法术防御增加602
get_qihun_added_attri(5, 45) -> 602;

%% 器魂：御46级，法术防御增加640
get_qihun_added_attri(5, 46) -> 640;

%% 器魂：御47级，法术防御增加681
get_qihun_added_attri(5, 47) -> 681;

%% 器魂：御48级，法术防御增加725
get_qihun_added_attri(5, 48) -> 725;

%% 器魂：御49级，法术防御增加771
get_qihun_added_attri(5, 49) -> 771;

%% 器魂：御50级，法术防御增加820
get_qihun_added_attri(5, 50) -> 820;

%% 器魂：准0级，命中增加0
get_qihun_added_attri(6, 0) -> 0;

%% 器魂：准1级，命中增加3
get_qihun_added_attri(6, 1) -> 3;

%% 器魂：准2级，命中增加4
get_qihun_added_attri(6, 2) -> 4;

%% 器魂：准3级，命中增加5
get_qihun_added_attri(6, 3) -> 5;

%% 器魂：准4级，命中增加6
get_qihun_added_attri(6, 4) -> 6;

%% 器魂：准5级，命中增加7
get_qihun_added_attri(6, 5) -> 7;

%% 器魂：准6级，命中增加8
get_qihun_added_attri(6, 6) -> 8;

%% 器魂：准7级，命中增加9
get_qihun_added_attri(6, 7) -> 9;

%% 器魂：准8级，命中增加10
get_qihun_added_attri(6, 8) -> 10;

%% 器魂：准9级，命中增加11
get_qihun_added_attri(6, 9) -> 11;

%% 器魂：准10级，命中增加12
get_qihun_added_attri(6, 10) -> 12;

%% 器魂：准11级，命中增加13
get_qihun_added_attri(6, 11) -> 13;

%% 器魂：准12级，命中增加14
get_qihun_added_attri(6, 12) -> 14;

%% 器魂：准13级，命中增加15
get_qihun_added_attri(6, 13) -> 15;

%% 器魂：准14级，命中增加16
get_qihun_added_attri(6, 14) -> 16;

%% 器魂：准15级，命中增加17
get_qihun_added_attri(6, 15) -> 17;

%% 器魂：准16级，命中增加18
get_qihun_added_attri(6, 16) -> 18;

%% 器魂：准17级，命中增加19
get_qihun_added_attri(6, 17) -> 19;

%% 器魂：准18级，命中增加20
get_qihun_added_attri(6, 18) -> 20;

%% 器魂：准19级，命中增加21
get_qihun_added_attri(6, 19) -> 21;

%% 器魂：准20级，命中增加22
get_qihun_added_attri(6, 20) -> 22;

%% 器魂：准21级，命中增加23
get_qihun_added_attri(6, 21) -> 23;

%% 器魂：准22级，命中增加24
get_qihun_added_attri(6, 22) -> 24;

%% 器魂：准23级，命中增加25
get_qihun_added_attri(6, 23) -> 25;

%% 器魂：准24级，命中增加26
get_qihun_added_attri(6, 24) -> 26;

%% 器魂：准25级，命中增加27
get_qihun_added_attri(6, 25) -> 27;

%% 器魂：准26级，命中增加28
get_qihun_added_attri(6, 26) -> 28;

%% 器魂：准27级，命中增加29
get_qihun_added_attri(6, 27) -> 29;

%% 器魂：准28级，命中增加30
get_qihun_added_attri(6, 28) -> 30;

%% 器魂：准29级，命中增加31
get_qihun_added_attri(6, 29) -> 31;

%% 器魂：准30级，命中增加32
get_qihun_added_attri(6, 30) -> 32;

%% 器魂：准31级，命中增加33
get_qihun_added_attri(6, 31) -> 33;

%% 器魂：准32级，命中增加34
get_qihun_added_attri(6, 32) -> 34;

%% 器魂：准33级，命中增加35
get_qihun_added_attri(6, 33) -> 35;

%% 器魂：准34级，命中增加36
get_qihun_added_attri(6, 34) -> 36;

%% 器魂：准35级，命中增加37
get_qihun_added_attri(6, 35) -> 37;

%% 器魂：准36级，命中增加38
get_qihun_added_attri(6, 36) -> 38;

%% 器魂：准37级，命中增加39
get_qihun_added_attri(6, 37) -> 39;

%% 器魂：准38级，命中增加41
get_qihun_added_attri(6, 38) -> 41;

%% 器魂：准39级，命中增加43
get_qihun_added_attri(6, 39) -> 43;

%% 器魂：准40级，命中增加45
get_qihun_added_attri(6, 40) -> 45;

%% 器魂：准41级，命中增加47
get_qihun_added_attri(6, 41) -> 47;

%% 器魂：准42级，命中增加49
get_qihun_added_attri(6, 42) -> 49;

%% 器魂：准43级，命中增加51
get_qihun_added_attri(6, 43) -> 51;

%% 器魂：准44级，命中增加53
get_qihun_added_attri(6, 44) -> 53;

%% 器魂：准45级，命中增加55
get_qihun_added_attri(6, 45) -> 55;

%% 器魂：准46级，命中增加57
get_qihun_added_attri(6, 46) -> 57;

%% 器魂：准47级，命中增加59
get_qihun_added_attri(6, 47) -> 59;

%% 器魂：准48级，命中增加61
get_qihun_added_attri(6, 48) -> 61;

%% 器魂：准49级，命中增加63
get_qihun_added_attri(6, 49) -> 63;

%% 器魂：准50级，命中增加65
get_qihun_added_attri(6, 50) -> 65;

%% 器魂：闪0级，闪避增加0
get_qihun_added_attri(7, 0) -> 0;

%% 器魂：闪1级，闪避增加3
get_qihun_added_attri(7, 1) -> 3;

%% 器魂：闪2级，闪避增加4
get_qihun_added_attri(7, 2) -> 4;

%% 器魂：闪3级，闪避增加5
get_qihun_added_attri(7, 3) -> 5;

%% 器魂：闪4级，闪避增加6
get_qihun_added_attri(7, 4) -> 6;

%% 器魂：闪5级，闪避增加7
get_qihun_added_attri(7, 5) -> 7;

%% 器魂：闪6级，闪避增加8
get_qihun_added_attri(7, 6) -> 8;

%% 器魂：闪7级，闪避增加9
get_qihun_added_attri(7, 7) -> 9;

%% 器魂：闪8级，闪避增加10
get_qihun_added_attri(7, 8) -> 10;

%% 器魂：闪9级，闪避增加11
get_qihun_added_attri(7, 9) -> 11;

%% 器魂：闪10级，闪避增加12
get_qihun_added_attri(7, 10) -> 12;

%% 器魂：闪11级，闪避增加13
get_qihun_added_attri(7, 11) -> 13;

%% 器魂：闪12级，闪避增加14
get_qihun_added_attri(7, 12) -> 14;

%% 器魂：闪13级，闪避增加15
get_qihun_added_attri(7, 13) -> 15;

%% 器魂：闪14级，闪避增加16
get_qihun_added_attri(7, 14) -> 16;

%% 器魂：闪15级，闪避增加17
get_qihun_added_attri(7, 15) -> 17;

%% 器魂：闪16级，闪避增加18
get_qihun_added_attri(7, 16) -> 18;

%% 器魂：闪17级，闪避增加19
get_qihun_added_attri(7, 17) -> 19;

%% 器魂：闪18级，闪避增加20
get_qihun_added_attri(7, 18) -> 20;

%% 器魂：闪19级，闪避增加21
get_qihun_added_attri(7, 19) -> 21;

%% 器魂：闪20级，闪避增加22
get_qihun_added_attri(7, 20) -> 22;

%% 器魂：闪21级，闪避增加23
get_qihun_added_attri(7, 21) -> 23;

%% 器魂：闪22级，闪避增加24
get_qihun_added_attri(7, 22) -> 24;

%% 器魂：闪23级，闪避增加25
get_qihun_added_attri(7, 23) -> 25;

%% 器魂：闪24级，闪避增加26
get_qihun_added_attri(7, 24) -> 26;

%% 器魂：闪25级，闪避增加27
get_qihun_added_attri(7, 25) -> 27;

%% 器魂：闪26级，闪避增加28
get_qihun_added_attri(7, 26) -> 28;

%% 器魂：闪27级，闪避增加29
get_qihun_added_attri(7, 27) -> 29;

%% 器魂：闪28级，闪避增加30
get_qihun_added_attri(7, 28) -> 30;

%% 器魂：闪29级，闪避增加31
get_qihun_added_attri(7, 29) -> 31;

%% 器魂：闪30级，闪避增加32
get_qihun_added_attri(7, 30) -> 32;

%% 器魂：闪31级，闪避增加33
get_qihun_added_attri(7, 31) -> 33;

%% 器魂：闪32级，闪避增加34
get_qihun_added_attri(7, 32) -> 34;

%% 器魂：闪33级，闪避增加35
get_qihun_added_attri(7, 33) -> 35;

%% 器魂：闪34级，闪避增加36
get_qihun_added_attri(7, 34) -> 36;

%% 器魂：闪35级，闪避增加37
get_qihun_added_attri(7, 35) -> 37;

%% 器魂：闪36级，闪避增加38
get_qihun_added_attri(7, 36) -> 38;

%% 器魂：闪37级，闪避增加39
get_qihun_added_attri(7, 37) -> 39;

%% 器魂：闪38级，闪避增加41
get_qihun_added_attri(7, 38) -> 41;

%% 器魂：闪39级，闪避增加43
get_qihun_added_attri(7, 39) -> 43;

%% 器魂：闪40级，闪避增加45
get_qihun_added_attri(7, 40) -> 45;

%% 器魂：闪41级，闪避增加47
get_qihun_added_attri(7, 41) -> 47;

%% 器魂：闪42级，闪避增加49
get_qihun_added_attri(7, 42) -> 49;

%% 器魂：闪43级，闪避增加51
get_qihun_added_attri(7, 43) -> 51;

%% 器魂：闪44级，闪避增加53
get_qihun_added_attri(7, 44) -> 53;

%% 器魂：闪45级，闪避增加55
get_qihun_added_attri(7, 45) -> 55;

%% 器魂：闪46级，闪避增加57
get_qihun_added_attri(7, 46) -> 57;

%% 器魂：闪47级，闪避增加59
get_qihun_added_attri(7, 47) -> 59;

%% 器魂：闪48级，闪避增加61
get_qihun_added_attri(7, 48) -> 61;

%% 器魂：闪49级，闪避增加63
get_qihun_added_attri(7, 49) -> 63;

%% 器魂：闪50级，闪避增加65
get_qihun_added_attri(7, 50) -> 65;

%% 器魂：运0级，躲避暴击增加0
get_qihun_added_attri(8, 0) -> 0;

%% 器魂：运1级，躲避暴击增加3
get_qihun_added_attri(8, 1) -> 3;

%% 器魂：运2级，躲避暴击增加4
get_qihun_added_attri(8, 2) -> 4;

%% 器魂：运3级，躲避暴击增加5
get_qihun_added_attri(8, 3) -> 5;

%% 器魂：运4级，躲避暴击增加6
get_qihun_added_attri(8, 4) -> 6;

%% 器魂：运5级，躲避暴击增加7
get_qihun_added_attri(8, 5) -> 7;

%% 器魂：运6级，躲避暴击增加8
get_qihun_added_attri(8, 6) -> 8;

%% 器魂：运7级，躲避暴击增加9
get_qihun_added_attri(8, 7) -> 9;

%% 器魂：运8级，躲避暴击增加10
get_qihun_added_attri(8, 8) -> 10;

%% 器魂：运9级，躲避暴击增加11
get_qihun_added_attri(8, 9) -> 11;

%% 器魂：运10级，躲避暴击增加12
get_qihun_added_attri(8, 10) -> 12;

%% 器魂：运11级，躲避暴击增加13
get_qihun_added_attri(8, 11) -> 13;

%% 器魂：运12级，躲避暴击增加14
get_qihun_added_attri(8, 12) -> 14;

%% 器魂：运13级，躲避暴击增加15
get_qihun_added_attri(8, 13) -> 15;

%% 器魂：运14级，躲避暴击增加16
get_qihun_added_attri(8, 14) -> 16;

%% 器魂：运15级，躲避暴击增加17
get_qihun_added_attri(8, 15) -> 17;

%% 器魂：运16级，躲避暴击增加18
get_qihun_added_attri(8, 16) -> 18;

%% 器魂：运17级，躲避暴击增加19
get_qihun_added_attri(8, 17) -> 19;

%% 器魂：运18级，躲避暴击增加20
get_qihun_added_attri(8, 18) -> 20;

%% 器魂：运19级，躲避暴击增加21
get_qihun_added_attri(8, 19) -> 21;

%% 器魂：运20级，躲避暴击增加22
get_qihun_added_attri(8, 20) -> 22;

%% 器魂：运21级，躲避暴击增加23
get_qihun_added_attri(8, 21) -> 23;

%% 器魂：运22级，躲避暴击增加24
get_qihun_added_attri(8, 22) -> 24;

%% 器魂：运23级，躲避暴击增加25
get_qihun_added_attri(8, 23) -> 25;

%% 器魂：运24级，躲避暴击增加26
get_qihun_added_attri(8, 24) -> 26;

%% 器魂：运25级，躲避暴击增加27
get_qihun_added_attri(8, 25) -> 27;

%% 器魂：运26级，躲避暴击增加28
get_qihun_added_attri(8, 26) -> 28;

%% 器魂：运27级，躲避暴击增加29
get_qihun_added_attri(8, 27) -> 29;

%% 器魂：运28级，躲避暴击增加30
get_qihun_added_attri(8, 28) -> 30;

%% 器魂：运29级，躲避暴击增加31
get_qihun_added_attri(8, 29) -> 31;

%% 器魂：运30级，躲避暴击增加32
get_qihun_added_attri(8, 30) -> 32;

%% 器魂：运31级，躲避暴击增加33
get_qihun_added_attri(8, 31) -> 33;

%% 器魂：运32级，躲避暴击增加34
get_qihun_added_attri(8, 32) -> 34;

%% 器魂：运33级，躲避暴击增加35
get_qihun_added_attri(8, 33) -> 35;

%% 器魂：运34级，躲避暴击增加36
get_qihun_added_attri(8, 34) -> 36;

%% 器魂：运35级，躲避暴击增加37
get_qihun_added_attri(8, 35) -> 37;

%% 器魂：运36级，躲避暴击增加38
get_qihun_added_attri(8, 36) -> 38;

%% 器魂：运37级，躲避暴击增加39
get_qihun_added_attri(8, 37) -> 39;

%% 器魂：运38级，躲避暴击增加41
get_qihun_added_attri(8, 38) -> 41;

%% 器魂：运39级，躲避暴击增加43
get_qihun_added_attri(8, 39) -> 43;

%% 器魂：运40级，躲避暴击增加45
get_qihun_added_attri(8, 40) -> 45;

%% 器魂：运41级，躲避暴击增加47
get_qihun_added_attri(8, 41) -> 47;

%% 器魂：运42级，躲避暴击增加49
get_qihun_added_attri(8, 42) -> 49;

%% 器魂：运43级，躲避暴击增加51
get_qihun_added_attri(8, 43) -> 51;

%% 器魂：运44级，躲避暴击增加53
get_qihun_added_attri(8, 44) -> 53;

%% 器魂：运45级，躲避暴击增加55
get_qihun_added_attri(8, 45) -> 55;

%% 器魂：运46级，躲避暴击增加57
get_qihun_added_attri(8, 46) -> 57;

%% 器魂：运47级，躲避暴击增加59
get_qihun_added_attri(8, 47) -> 59;

%% 器魂：运48级，躲避暴击增加61
get_qihun_added_attri(8, 48) -> 61;

%% 器魂：运49级，躲避暴击增加63
get_qihun_added_attri(8, 49) -> 63;

%% 器魂：运50级，躲避暴击增加65
get_qihun_added_attri(8, 50) -> 65;

%% 器魂：速0级，速度增加0
get_qihun_added_attri(9, 0) -> 0;

%% 器魂：速1级，速度增加2
get_qihun_added_attri(9, 1) -> 2;

%% 器魂：速2级，速度增加4
get_qihun_added_attri(9, 2) -> 4;

%% 器魂：速3级，速度增加5
get_qihun_added_attri(9, 3) -> 5;

%% 器魂：速4级，速度增加7
get_qihun_added_attri(9, 4) -> 7;

%% 器魂：速5级，速度增加9
get_qihun_added_attri(9, 5) -> 9;

%% 器魂：速6级，速度增加11
get_qihun_added_attri(9, 6) -> 11;

%% 器魂：速7级，速度增加14
get_qihun_added_attri(9, 7) -> 14;

%% 器魂：速8级，速度增加18
get_qihun_added_attri(9, 8) -> 18;

%% 器魂：速9级，速度增加22
get_qihun_added_attri(9, 9) -> 22;

%% 器魂：速10级，速度增加28
get_qihun_added_attri(9, 10) -> 28;

%% 器魂：速11级，速度增加30
get_qihun_added_attri(9, 11) -> 30;

%% 器魂：速12级，速度增加31
get_qihun_added_attri(9, 12) -> 31;

%% 器魂：速13级，速度增加33
get_qihun_added_attri(9, 13) -> 33;

%% 器魂：速14级，速度增加36
get_qihun_added_attri(9, 14) -> 36;

%% 器魂：速15级，速度增加38
get_qihun_added_attri(9, 15) -> 38;

%% 器魂：速16级，速度增加40
get_qihun_added_attri(9, 16) -> 40;

%% 器魂：速17级，速度增加43
get_qihun_added_attri(9, 17) -> 43;

%% 器魂：速18级，速度增加46
get_qihun_added_attri(9, 18) -> 46;

%% 器魂：速19级，速度增加48
get_qihun_added_attri(9, 19) -> 48;

%% 器魂：速20级，速度增加52
get_qihun_added_attri(9, 20) -> 52;

%% 器魂：速21级，速度增加55
get_qihun_added_attri(9, 21) -> 55;

%% 器魂：速22级，速度增加58
get_qihun_added_attri(9, 22) -> 58;

%% 器魂：速23级，速度增加62
get_qihun_added_attri(9, 23) -> 62;

%% 器魂：速24级，速度增加66
get_qihun_added_attri(9, 24) -> 66;

%% 器魂：速25级，速度增加70
get_qihun_added_attri(9, 25) -> 70;

%% 器魂：速26级，速度增加75
get_qihun_added_attri(9, 26) -> 75;

%% 器魂：速27级，速度增加80
get_qihun_added_attri(9, 27) -> 80;

%% 器魂：速28级，速度增加85
get_qihun_added_attri(9, 28) -> 85;

%% 器魂：速29级，速度增加90
get_qihun_added_attri(9, 29) -> 90;

%% 器魂：速30级，速度增加96
get_qihun_added_attri(9, 30) -> 96;

%% 器魂：速31级，速度增加102
get_qihun_added_attri(9, 31) -> 102;

%% 器魂：速32级，速度增加108
get_qihun_added_attri(9, 32) -> 108;

%% 器魂：速33级，速度增加115
get_qihun_added_attri(9, 33) -> 115;

%% 器魂：速34级，速度增加123
get_qihun_added_attri(9, 34) -> 123;

%% 器魂：速35级，速度增加130
get_qihun_added_attri(9, 35) -> 130;

%% 器魂：速36级，速度增加139
get_qihun_added_attri(9, 36) -> 139;

%% 器魂：速37级，速度增加148
get_qihun_added_attri(9, 37) -> 148;

%% 器魂：速38级，速度增加157
get_qihun_added_attri(9, 38) -> 157;

%% 器魂：速39级，速度增加167
get_qihun_added_attri(9, 39) -> 167;

%% 器魂：速40级，速度增加178
get_qihun_added_attri(9, 40) -> 178;

%% 器魂：速41级，速度增加189
get_qihun_added_attri(9, 41) -> 189;

%% 器魂：速42级，速度增加201
get_qihun_added_attri(9, 42) -> 201;

%% 器魂：速43级，速度增加214
get_qihun_added_attri(9, 43) -> 214;

%% 器魂：速44级，速度增加228
get_qihun_added_attri(9, 44) -> 228;

%% 器魂：速45级，速度增加242
get_qihun_added_attri(9, 45) -> 242;

%% 器魂：速46级，速度增加258
get_qihun_added_attri(9, 46) -> 258;

%% 器魂：速47级，速度增加274
get_qihun_added_attri(9, 47) -> 274;

%% 器魂：速48级，速度增加292
get_qihun_added_attri(9, 48) -> 292;

%% 器魂：速49级，速度增加310
get_qihun_added_attri(9, 49) -> 310;

%% 器魂：速50级，速度增加330
get_qihun_added_attri(9, 50) -> 330;

%% 器魂：暴0级，暴击增加0
get_qihun_added_attri(10, 0) -> 0;

%% 器魂：暴1级，暴击增加3
get_qihun_added_attri(10, 1) -> 3;

%% 器魂：暴2级，暴击增加4
get_qihun_added_attri(10, 2) -> 4;

%% 器魂：暴3级，暴击增加5
get_qihun_added_attri(10, 3) -> 5;

%% 器魂：暴4级，暴击增加6
get_qihun_added_attri(10, 4) -> 6;

%% 器魂：暴5级，暴击增加7
get_qihun_added_attri(10, 5) -> 7;

%% 器魂：暴6级，暴击增加8
get_qihun_added_attri(10, 6) -> 8;

%% 器魂：暴7级，暴击增加9
get_qihun_added_attri(10, 7) -> 9;

%% 器魂：暴8级，暴击增加10
get_qihun_added_attri(10, 8) -> 10;

%% 器魂：暴9级，暴击增加11
get_qihun_added_attri(10, 9) -> 11;

%% 器魂：暴10级，暴击增加12
get_qihun_added_attri(10, 10) -> 12;

%% 器魂：暴11级，暴击增加13
get_qihun_added_attri(10, 11) -> 13;

%% 器魂：暴12级，暴击增加14
get_qihun_added_attri(10, 12) -> 14;

%% 器魂：暴13级，暴击增加15
get_qihun_added_attri(10, 13) -> 15;

%% 器魂：暴14级，暴击增加16
get_qihun_added_attri(10, 14) -> 16;

%% 器魂：暴15级，暴击增加17
get_qihun_added_attri(10, 15) -> 17;

%% 器魂：暴16级，暴击增加18
get_qihun_added_attri(10, 16) -> 18;

%% 器魂：暴17级，暴击增加19
get_qihun_added_attri(10, 17) -> 19;

%% 器魂：暴18级，暴击增加20
get_qihun_added_attri(10, 18) -> 20;

%% 器魂：暴19级，暴击增加21
get_qihun_added_attri(10, 19) -> 21;

%% 器魂：暴20级，暴击增加22
get_qihun_added_attri(10, 20) -> 22;

%% 器魂：暴21级，暴击增加23
get_qihun_added_attri(10, 21) -> 23;

%% 器魂：暴22级，暴击增加24
get_qihun_added_attri(10, 22) -> 24;

%% 器魂：暴23级，暴击增加25
get_qihun_added_attri(10, 23) -> 25;

%% 器魂：暴24级，暴击增加26
get_qihun_added_attri(10, 24) -> 26;

%% 器魂：暴25级，暴击增加27
get_qihun_added_attri(10, 25) -> 27;

%% 器魂：暴26级，暴击增加28
get_qihun_added_attri(10, 26) -> 28;

%% 器魂：暴27级，暴击增加29
get_qihun_added_attri(10, 27) -> 29;

%% 器魂：暴28级，暴击增加30
get_qihun_added_attri(10, 28) -> 30;

%% 器魂：暴29级，暴击增加31
get_qihun_added_attri(10, 29) -> 31;

%% 器魂：暴30级，暴击增加32
get_qihun_added_attri(10, 30) -> 32;

%% 器魂：暴31级，暴击增加33
get_qihun_added_attri(10, 31) -> 33;

%% 器魂：暴32级，暴击增加34
get_qihun_added_attri(10, 32) -> 34;

%% 器魂：暴33级，暴击增加35
get_qihun_added_attri(10, 33) -> 35;

%% 器魂：暴34级，暴击增加36
get_qihun_added_attri(10, 34) -> 36;

%% 器魂：暴35级，暴击增加37
get_qihun_added_attri(10, 35) -> 37;

%% 器魂：暴36级，暴击增加38
get_qihun_added_attri(10, 36) -> 38;

%% 器魂：暴37级，暴击增加39
get_qihun_added_attri(10, 37) -> 39;

%% 器魂：暴38级，暴击增加41
get_qihun_added_attri(10, 38) -> 41;

%% 器魂：暴39级，暴击增加43
get_qihun_added_attri(10, 39) -> 43;

%% 器魂：暴40级，暴击增加45
get_qihun_added_attri(10, 40) -> 45;

%% 器魂：暴41级，暴击增加47
get_qihun_added_attri(10, 41) -> 47;

%% 器魂：暴42级，暴击增加49
get_qihun_added_attri(10, 42) -> 49;

%% 器魂：暴43级，暴击增加51
get_qihun_added_attri(10, 43) -> 51;

%% 器魂：暴44级，暴击增加53
get_qihun_added_attri(10, 44) -> 53;

%% 器魂：暴45级，暴击增加55
get_qihun_added_attri(10, 45) -> 55;

%% 器魂：暴46级，暴击增加57
get_qihun_added_attri(10, 46) -> 57;

%% 器魂：暴47级，暴击增加59
get_qihun_added_attri(10, 47) -> 59;

%% 器魂：暴48级，暴击增加61
get_qihun_added_attri(10, 48) -> 61;

%% 器魂：暴49级，暴击增加63
get_qihun_added_attri(10, 49) -> 63;

%% 器魂：暴50级，暴击增加65
get_qihun_added_attri(10, 50) -> 65.


%%================================================
%% 根据品阶所对应的器魂id和品阶等级获取给武将的属性加成
%% 器魂：精品阶0，气血增加0
get_pinjie_added_attri(1, 0) -> 0;

%% 器魂：精品阶1，气血增加48
get_pinjie_added_attri(1, 1) -> 48;

%% 器魂：精品阶2，气血增加56
get_pinjie_added_attri(1, 2) -> 56;

%% 器魂：精品阶3，气血增加66
get_pinjie_added_attri(1, 3) -> 66;

%% 器魂：精品阶4，气血增加78
get_pinjie_added_attri(1, 4) -> 78;

%% 器魂：精品阶5，气血增加92
get_pinjie_added_attri(1, 5) -> 92;

%% 器魂：精品阶6，气血增加103
get_pinjie_added_attri(1, 6) -> 103;

%% 器魂：精品阶7，气血增加114
get_pinjie_added_attri(1, 7) -> 114;

%% 器魂：精品阶8，气血增加127
get_pinjie_added_attri(1, 8) -> 127;

%% 器魂：精品阶9，气血增加135
get_pinjie_added_attri(1, 9) -> 135;

%% 器魂：精品阶10，气血增加143
get_pinjie_added_attri(1, 10) -> 143;

%% 器魂：精品阶11，气血增加153
get_pinjie_added_attri(1, 11) -> 153;

%% 器魂：精品阶12，气血增加162
get_pinjie_added_attri(1, 12) -> 162;

%% 器魂：精品阶13，气血增加173
get_pinjie_added_attri(1, 13) -> 173;

%% 器魂：精品阶14，气血增加184
get_pinjie_added_attri(1, 14) -> 184;

%% 器魂：精品阶15，气血增加196
get_pinjie_added_attri(1, 15) -> 196;

%% 器魂：精品阶16，气血增加208
get_pinjie_added_attri(1, 16) -> 208;

%% 器魂：精品阶17，气血增加221
get_pinjie_added_attri(1, 17) -> 221;

%% 器魂：精品阶18，气血增加236
get_pinjie_added_attri(1, 18) -> 236;

%% 器魂：精品阶19，气血增加251
get_pinjie_added_attri(1, 19) -> 251;

%% 器魂：精品阶20，气血增加267
get_pinjie_added_attri(1, 20) -> 267;

%% 器魂：精品阶21，气血增加284
get_pinjie_added_attri(1, 21) -> 284;

%% 器魂：精品阶22，气血增加302
get_pinjie_added_attri(1, 22) -> 302;

%% 器魂：精品阶23，气血增加321
get_pinjie_added_attri(1, 23) -> 321;

%% 器魂：精品阶24，气血增加342
get_pinjie_added_attri(1, 24) -> 342;

%% 器魂：精品阶25，气血增加364
get_pinjie_added_attri(1, 25) -> 364;

%% 器魂：精品阶26，气血增加387
get_pinjie_added_attri(1, 26) -> 387;

%% 器魂：精品阶27，气血增加412
get_pinjie_added_attri(1, 27) -> 412;

%% 器魂：精品阶28，气血增加438
get_pinjie_added_attri(1, 28) -> 438;

%% 器魂：精品阶29，气血增加466
get_pinjie_added_attri(1, 29) -> 466;

%% 器魂：精品阶30，气血增加496
get_pinjie_added_attri(1, 30) -> 496;

%% 器魂：精品阶31，气血增加527
get_pinjie_added_attri(1, 31) -> 527;

%% 器魂：精品阶32，气血增加561
get_pinjie_added_attri(1, 32) -> 561;

%% 器魂：精品阶33，气血增加597
get_pinjie_added_attri(1, 33) -> 597;

%% 器魂：精品阶34，气血增加635
get_pinjie_added_attri(1, 34) -> 635;

%% 器魂：精品阶35，气血增加675
get_pinjie_added_attri(1, 35) -> 675;

%% 器魂：精品阶36，气血增加719
get_pinjie_added_attri(1, 36) -> 719;

%% 器魂：精品阶37，气血增加764
get_pinjie_added_attri(1, 37) -> 764;

%% 器魂：精品阶38，气血增加813
get_pinjie_added_attri(1, 38) -> 813;

%% 器魂：精品阶39，气血增加865
get_pinjie_added_attri(1, 39) -> 865;

%% 器魂：精品阶40，气血增加921
get_pinjie_added_attri(1, 40) -> 921;

%% 器魂：精品阶41，气血增加979
get_pinjie_added_attri(1, 41) -> 979;

%% 器魂：精品阶42，气血增加1042
get_pinjie_added_attri(1, 42) -> 1042;

%% 器魂：精品阶43，气血增加1108
get_pinjie_added_attri(1, 43) -> 1108;

%% 器魂：精品阶44，气血增加1179
get_pinjie_added_attri(1, 44) -> 1179;

%% 器魂：精品阶45，气血增加1254
get_pinjie_added_attri(1, 45) -> 1254;

%% 器魂：精品阶46，气血增加1335
get_pinjie_added_attri(1, 46) -> 1335;

%% 器魂：精品阶47，气血增加1420
get_pinjie_added_attri(1, 47) -> 1420;

%% 器魂：精品阶48，气血增加1510
get_pinjie_added_attri(1, 48) -> 1510;

%% 器魂：精品阶49，气血增加1607
get_pinjie_added_attri(1, 49) -> 1607;

%% 器魂：精品阶50，气血增加1710
get_pinjie_added_attri(1, 50) -> 1710;

%% 器魂：力品阶0，物理攻击增加0
get_pinjie_added_attri(2, 0) -> 0;

%% 器魂：力品阶1，物理攻击增加30
get_pinjie_added_attri(2, 1) -> 30;

%% 器魂：力品阶2，物理攻击增加35
get_pinjie_added_attri(2, 2) -> 35;

%% 器魂：力品阶3，物理攻击增加42
get_pinjie_added_attri(2, 3) -> 42;

%% 器魂：力品阶4，物理攻击增加49
get_pinjie_added_attri(2, 4) -> 49;

%% 器魂：力品阶5，物理攻击增加58
get_pinjie_added_attri(2, 5) -> 58;

%% 器魂：力品阶6，物理攻击增加65
get_pinjie_added_attri(2, 6) -> 65;

%% 器魂：力品阶7，物理攻击增加72
get_pinjie_added_attri(2, 7) -> 72;

%% 器魂：力品阶8，物理攻击增加80
get_pinjie_added_attri(2, 8) -> 80;

%% 器魂：力品阶9，物理攻击增加85
get_pinjie_added_attri(2, 9) -> 85;

%% 器魂：力品阶10，物理攻击增加90
get_pinjie_added_attri(2, 10) -> 90;

%% 器魂：力品阶11，物理攻击增加96
get_pinjie_added_attri(2, 11) -> 96;

%% 器魂：力品阶12，物理攻击增加102
get_pinjie_added_attri(2, 12) -> 102;

%% 器魂：力品阶13，物理攻击增加109
get_pinjie_added_attri(2, 13) -> 109;

%% 器魂：力品阶14，物理攻击增加116
get_pinjie_added_attri(2, 14) -> 116;

%% 器魂：力品阶15，物理攻击增加123
get_pinjie_added_attri(2, 15) -> 123;

%% 器魂：力品阶16，物理攻击增加131
get_pinjie_added_attri(2, 16) -> 131;

%% 器魂：力品阶17，物理攻击增加140
get_pinjie_added_attri(2, 17) -> 140;

%% 器魂：力品阶18，物理攻击增加149
get_pinjie_added_attri(2, 18) -> 149;

%% 器魂：力品阶19，物理攻击增加158
get_pinjie_added_attri(2, 19) -> 158;

%% 器魂：力品阶20，物理攻击增加168
get_pinjie_added_attri(2, 20) -> 168;

%% 器魂：力品阶21，物理攻击增加179
get_pinjie_added_attri(2, 21) -> 179;

%% 器魂：力品阶22，物理攻击增加190
get_pinjie_added_attri(2, 22) -> 190;

%% 器魂：力品阶23，物理攻击增加203
get_pinjie_added_attri(2, 23) -> 203;

%% 器魂：力品阶24，物理攻击增加216
get_pinjie_added_attri(2, 24) -> 216;

%% 器魂：力品阶25，物理攻击增加229
get_pinjie_added_attri(2, 25) -> 229;

%% 器魂：力品阶26，物理攻击增加244
get_pinjie_added_attri(2, 26) -> 244;

%% 器魂：力品阶27，物理攻击增加260
get_pinjie_added_attri(2, 27) -> 260;

%% 器魂：力品阶28，物理攻击增加276
get_pinjie_added_attri(2, 28) -> 276;

%% 器魂：力品阶29，物理攻击增加294
get_pinjie_added_attri(2, 29) -> 294;

%% 器魂：力品阶30，物理攻击增加313
get_pinjie_added_attri(2, 30) -> 313;

%% 器魂：力品阶31，物理攻击增加333
get_pinjie_added_attri(2, 31) -> 333;

%% 器魂：力品阶32，物理攻击增加354
get_pinjie_added_attri(2, 32) -> 354;

%% 器魂：力品阶33，物理攻击增加377
get_pinjie_added_attri(2, 33) -> 377;

%% 器魂：力品阶34，物理攻击增加401
get_pinjie_added_attri(2, 34) -> 401;

%% 器魂：力品阶35，物理攻击增加426
get_pinjie_added_attri(2, 35) -> 426;

%% 器魂：力品阶36，物理攻击增加454
get_pinjie_added_attri(2, 36) -> 454;

%% 器魂：力品阶37，物理攻击增加483
get_pinjie_added_attri(2, 37) -> 483;

%% 器魂：力品阶38，物理攻击增加513
get_pinjie_added_attri(2, 38) -> 513;

%% 器魂：力品阶39，物理攻击增加546
get_pinjie_added_attri(2, 39) -> 546;

%% 器魂：力品阶40，物理攻击增加581
get_pinjie_added_attri(2, 40) -> 581;

%% 器魂：力品阶41，物理攻击增加618
get_pinjie_added_attri(2, 41) -> 618;

%% 器魂：力品阶42，物理攻击增加658
get_pinjie_added_attri(2, 42) -> 658;

%% 器魂：力品阶43，物理攻击增加700
get_pinjie_added_attri(2, 43) -> 700;

%% 器魂：力品阶44，物理攻击增加745
get_pinjie_added_attri(2, 44) -> 745;

%% 器魂：力品阶45，物理攻击增加792
get_pinjie_added_attri(2, 45) -> 792;

%% 器魂：力品阶46，物理攻击增加843
get_pinjie_added_attri(2, 46) -> 843;

%% 器魂：力品阶47，物理攻击增加897
get_pinjie_added_attri(2, 47) -> 897;

%% 器魂：力品阶48，物理攻击增加954
get_pinjie_added_attri(2, 48) -> 954;

%% 器魂：力品阶49，物理攻击增加1015
get_pinjie_added_attri(2, 49) -> 1015;

%% 器魂：力品阶50，物理攻击增加1080
get_pinjie_added_attri(2, 50) -> 1080;

%% 器魂：元品阶0，法术攻击增加0
get_pinjie_added_attri(3, 0) -> 0;

%% 器魂：元品阶1，法术攻击增加30
get_pinjie_added_attri(3, 1) -> 30;

%% 器魂：元品阶2，法术攻击增加35
get_pinjie_added_attri(3, 2) -> 35;

%% 器魂：元品阶3，法术攻击增加41
get_pinjie_added_attri(3, 3) -> 41;

%% 器魂：元品阶4，法术攻击增加49
get_pinjie_added_attri(3, 4) -> 49;

%% 器魂：元品阶5，法术攻击增加58
get_pinjie_added_attri(3, 5) -> 58;

%% 器魂：元品阶6，法术攻击增加64
get_pinjie_added_attri(3, 6) -> 64;

%% 器魂：元品阶7，法术攻击增加71
get_pinjie_added_attri(3, 7) -> 71;

%% 器魂：元品阶8，法术攻击增加79
get_pinjie_added_attri(3, 8) -> 79;

%% 器魂：元品阶9，法术攻击增加84
get_pinjie_added_attri(3, 9) -> 84;

%% 器魂：元品阶10，法术攻击增加90
get_pinjie_added_attri(3, 10) -> 90;

%% 器魂：元品阶11，法术攻击增加95
get_pinjie_added_attri(3, 11) -> 95;

%% 器魂：元品阶12，法术攻击增加101
get_pinjie_added_attri(3, 12) -> 101;

%% 器魂：元品阶13，法术攻击增加108
get_pinjie_added_attri(3, 13) -> 108;

%% 器魂：元品阶14，法术攻击增加115
get_pinjie_added_attri(3, 14) -> 115;

%% 器魂：元品阶15，法术攻击增加122
get_pinjie_added_attri(3, 15) -> 122;

%% 器魂：元品阶16，法术攻击增加130
get_pinjie_added_attri(3, 16) -> 130;

%% 器魂：元品阶17，法术攻击增加138
get_pinjie_added_attri(3, 17) -> 138;

%% 器魂：元品阶18，法术攻击增加147
get_pinjie_added_attri(3, 18) -> 147;

%% 器魂：元品阶19，法术攻击增加157
get_pinjie_added_attri(3, 19) -> 157;

%% 器魂：元品阶20，法术攻击增加167
get_pinjie_added_attri(3, 20) -> 167;

%% 器魂：元品阶21，法术攻击增加177
get_pinjie_added_attri(3, 21) -> 177;

%% 器魂：元品阶22，法术攻击增加189
get_pinjie_added_attri(3, 22) -> 189;

%% 器魂：元品阶23，法术攻击增加201
get_pinjie_added_attri(3, 23) -> 201;

%% 器魂：元品阶24，法术攻击增加214
get_pinjie_added_attri(3, 24) -> 214;

%% 器魂：元品阶25，法术攻击增加227
get_pinjie_added_attri(3, 25) -> 227;

%% 器魂：元品阶26，法术攻击增加242
get_pinjie_added_attri(3, 26) -> 242;

%% 器魂：元品阶27，法术攻击增加257
get_pinjie_added_attri(3, 27) -> 257;

%% 器魂：元品阶28，法术攻击增加274
get_pinjie_added_attri(3, 28) -> 274;

%% 器魂：元品阶29，法术攻击增加291
get_pinjie_added_attri(3, 29) -> 291;

%% 器魂：元品阶30，法术攻击增加310
get_pinjie_added_attri(3, 30) -> 310;

%% 器魂：元品阶31，法术攻击增加330
get_pinjie_added_attri(3, 31) -> 330;

%% 器魂：元品阶32，法术攻击增加351
get_pinjie_added_attri(3, 32) -> 351;

%% 器魂：元品阶33，法术攻击增加373
get_pinjie_added_attri(3, 33) -> 373;

%% 器魂：元品阶34，法术攻击增加397
get_pinjie_added_attri(3, 34) -> 397;

%% 器魂：元品阶35，法术攻击增加422
get_pinjie_added_attri(3, 35) -> 422;

%% 器魂：元品阶36，法术攻击增加449
get_pinjie_added_attri(3, 36) -> 449;

%% 器魂：元品阶37，法术攻击增加478
get_pinjie_added_attri(3, 37) -> 478;

%% 器魂：元品阶38，法术攻击增加509
get_pinjie_added_attri(3, 38) -> 509;

%% 器魂：元品阶39，法术攻击增加541
get_pinjie_added_attri(3, 39) -> 541;

%% 器魂：元品阶40，法术攻击增加576
get_pinjie_added_attri(3, 40) -> 576;

%% 器魂：元品阶41，法术攻击增加613
get_pinjie_added_attri(3, 41) -> 613;

%% 器魂：元品阶42，法术攻击增加652
get_pinjie_added_attri(3, 42) -> 652;

%% 器魂：元品阶43，法术攻击增加693
get_pinjie_added_attri(3, 43) -> 693;

%% 器魂：元品阶44，法术攻击增加738
get_pinjie_added_attri(3, 44) -> 738;

%% 器魂：元品阶45，法术攻击增加785
get_pinjie_added_attri(3, 45) -> 785;

%% 器魂：元品阶46，法术攻击增加835
get_pinjie_added_attri(3, 46) -> 835;

%% 器魂：元品阶47，法术攻击增加888
get_pinjie_added_attri(3, 47) -> 888;

%% 器魂：元品阶48，法术攻击增加945
get_pinjie_added_attri(3, 48) -> 945;

%% 器魂：元品阶49，法术攻击增加1005
get_pinjie_added_attri(3, 49) -> 1005;

%% 器魂：元品阶50，法术攻击增加1070
get_pinjie_added_attri(3, 50) -> 1070;

%% 器魂：盾品阶0，物理防御增加0
get_pinjie_added_attri(4, 0) -> 0;

%% 器魂：盾品阶1，物理防御增加34
get_pinjie_added_attri(4, 1) -> 34;

%% 器魂：盾品阶2，物理防御增加40
get_pinjie_added_attri(4, 2) -> 40;

%% 器魂：盾品阶3，物理防御增加48
get_pinjie_added_attri(4, 3) -> 48;

%% 器魂：盾品阶4，物理防御增加56
get_pinjie_added_attri(4, 4) -> 56;

%% 器魂：盾品阶5，物理防御增加66
get_pinjie_added_attri(4, 5) -> 66;

%% 器魂：盾品阶6，物理防御增加74
get_pinjie_added_attri(4, 6) -> 74;

%% 器魂：盾品阶7，物理防御增加82
get_pinjie_added_attri(4, 7) -> 82;

%% 器魂：盾品阶8，物理防御增加91
get_pinjie_added_attri(4, 8) -> 91;

%% 器魂：盾品阶9，物理防御增加97
get_pinjie_added_attri(4, 9) -> 97;

%% 器魂：盾品阶10，物理防御增加103
get_pinjie_added_attri(4, 10) -> 103;

%% 器魂：盾品阶11，物理防御增加110
get_pinjie_added_attri(4, 11) -> 110;

%% 器魂：盾品阶12，物理防御增加117
get_pinjie_added_attri(4, 12) -> 117;

%% 器魂：盾品阶13，物理防御增加124
get_pinjie_added_attri(4, 13) -> 124;

%% 器魂：盾品阶14，物理防御增加132
get_pinjie_added_attri(4, 14) -> 132;

%% 器魂：盾品阶15，物理防御增加141
get_pinjie_added_attri(4, 15) -> 141;

%% 器魂：盾品阶16，物理防御增加150
get_pinjie_added_attri(4, 16) -> 150;

%% 器魂：盾品阶17，物理防御增加159
get_pinjie_added_attri(4, 17) -> 159;

%% 器魂：盾品阶18，物理防御增加169
get_pinjie_added_attri(4, 18) -> 169;

%% 器魂：盾品阶19，物理防御增加180
get_pinjie_added_attri(4, 19) -> 180;

%% 器魂：盾品阶20，物理防御增加192
get_pinjie_added_attri(4, 20) -> 192;

%% 器魂：盾品阶21，物理防御增加204
get_pinjie_added_attri(4, 21) -> 204;

%% 器魂：盾品阶22，物理防御增加217
get_pinjie_added_attri(4, 22) -> 217;

%% 器魂：盾品阶23，物理防御增加231
get_pinjie_added_attri(4, 23) -> 231;

%% 器魂：盾品阶24，物理防御增加246
get_pinjie_added_attri(4, 24) -> 246;

%% 器魂：盾品阶25，物理防御增加261
get_pinjie_added_attri(4, 25) -> 261;

%% 器魂：盾品阶26，物理防御增加278
get_pinjie_added_attri(4, 26) -> 278;

%% 器魂：盾品阶27，物理防御增加296
get_pinjie_added_attri(4, 27) -> 296;

%% 器魂：盾品阶28，物理防御增加315
get_pinjie_added_attri(4, 28) -> 315;

%% 器魂：盾品阶29，物理防御增加335
get_pinjie_added_attri(4, 29) -> 335;

%% 器魂：盾品阶30，物理防御增加356
get_pinjie_added_attri(4, 30) -> 356;

%% 器魂：盾品阶31，物理防御增加379
get_pinjie_added_attri(4, 31) -> 379;

%% 器魂：盾品阶32，物理防御增加403
get_pinjie_added_attri(4, 32) -> 403;

%% 器魂：盾品阶33，物理防御增加429
get_pinjie_added_attri(4, 33) -> 429;

%% 器魂：盾品阶34，物理防御增加457
get_pinjie_added_attri(4, 34) -> 457;

%% 器魂：盾品阶35，物理防御增加486
get_pinjie_added_attri(4, 35) -> 486;

%% 器魂：盾品阶36，物理防御增加517
get_pinjie_added_attri(4, 36) -> 517;

%% 器魂：盾品阶37，物理防御增加550
get_pinjie_added_attri(4, 37) -> 550;

%% 器魂：盾品阶38，物理防御增加585
get_pinjie_added_attri(4, 38) -> 585;

%% 器魂：盾品阶39，物理防御增加622
get_pinjie_added_attri(4, 39) -> 622;

%% 器魂：盾品阶40，物理防御增加662
get_pinjie_added_attri(4, 40) -> 662;

%% 器魂：盾品阶41，物理防御增加704
get_pinjie_added_attri(4, 41) -> 704;

%% 器魂：盾品阶42，物理防御增加749
get_pinjie_added_attri(4, 42) -> 749;

%% 器魂：盾品阶43，物理防御增加797
get_pinjie_added_attri(4, 43) -> 797;

%% 器魂：盾品阶44，物理防御增加848
get_pinjie_added_attri(4, 44) -> 848;

%% 器魂：盾品阶45，物理防御增加902
get_pinjie_added_attri(4, 45) -> 902;

%% 器魂：盾品阶46，物理防御增加960
get_pinjie_added_attri(4, 46) -> 960;

%% 器魂：盾品阶47，物理防御增加1021
get_pinjie_added_attri(4, 47) -> 1021;

%% 器魂：盾品阶48，物理防御增加1086
get_pinjie_added_attri(4, 48) -> 1086;

%% 器魂：盾品阶49，物理防御增加1156
get_pinjie_added_attri(4, 49) -> 1156;

%% 器魂：盾品阶50，物理防御增加1230
get_pinjie_added_attri(4, 50) -> 1230;

%% 器魂：御品阶0，法术防御增加0
get_pinjie_added_attri(5, 0) -> 0;

%% 器魂：御品阶1，法术防御增加34
get_pinjie_added_attri(5, 1) -> 34;

%% 器魂：御品阶2，法术防御增加40
get_pinjie_added_attri(5, 2) -> 40;

%% 器魂：御品阶3，法术防御增加48
get_pinjie_added_attri(5, 3) -> 48;

%% 器魂：御品阶4，法术防御增加56
get_pinjie_added_attri(5, 4) -> 56;

%% 器魂：御品阶5，法术防御增加66
get_pinjie_added_attri(5, 5) -> 66;

%% 器魂：御品阶6，法术防御增加74
get_pinjie_added_attri(5, 6) -> 74;

%% 器魂：御品阶7，法术防御增加82
get_pinjie_added_attri(5, 7) -> 82;

%% 器魂：御品阶8，法术防御增加91
get_pinjie_added_attri(5, 8) -> 91;

%% 器魂：御品阶9，法术防御增加97
get_pinjie_added_attri(5, 9) -> 97;

%% 器魂：御品阶10，法术防御增加103
get_pinjie_added_attri(5, 10) -> 103;

%% 器魂：御品阶11，法术防御增加110
get_pinjie_added_attri(5, 11) -> 110;

%% 器魂：御品阶12，法术防御增加117
get_pinjie_added_attri(5, 12) -> 117;

%% 器魂：御品阶13，法术防御增加124
get_pinjie_added_attri(5, 13) -> 124;

%% 器魂：御品阶14，法术防御增加132
get_pinjie_added_attri(5, 14) -> 132;

%% 器魂：御品阶15，法术防御增加141
get_pinjie_added_attri(5, 15) -> 141;

%% 器魂：御品阶16，法术防御增加150
get_pinjie_added_attri(5, 16) -> 150;

%% 器魂：御品阶17，法术防御增加159
get_pinjie_added_attri(5, 17) -> 159;

%% 器魂：御品阶18，法术防御增加169
get_pinjie_added_attri(5, 18) -> 169;

%% 器魂：御品阶19，法术防御增加180
get_pinjie_added_attri(5, 19) -> 180;

%% 器魂：御品阶20，法术防御增加192
get_pinjie_added_attri(5, 20) -> 192;

%% 器魂：御品阶21，法术防御增加204
get_pinjie_added_attri(5, 21) -> 204;

%% 器魂：御品阶22，法术防御增加217
get_pinjie_added_attri(5, 22) -> 217;

%% 器魂：御品阶23，法术防御增加231
get_pinjie_added_attri(5, 23) -> 231;

%% 器魂：御品阶24，法术防御增加246
get_pinjie_added_attri(5, 24) -> 246;

%% 器魂：御品阶25，法术防御增加261
get_pinjie_added_attri(5, 25) -> 261;

%% 器魂：御品阶26，法术防御增加278
get_pinjie_added_attri(5, 26) -> 278;

%% 器魂：御品阶27，法术防御增加296
get_pinjie_added_attri(5, 27) -> 296;

%% 器魂：御品阶28，法术防御增加315
get_pinjie_added_attri(5, 28) -> 315;

%% 器魂：御品阶29，法术防御增加335
get_pinjie_added_attri(5, 29) -> 335;

%% 器魂：御品阶30，法术防御增加356
get_pinjie_added_attri(5, 30) -> 356;

%% 器魂：御品阶31，法术防御增加379
get_pinjie_added_attri(5, 31) -> 379;

%% 器魂：御品阶32，法术防御增加403
get_pinjie_added_attri(5, 32) -> 403;

%% 器魂：御品阶33，法术防御增加429
get_pinjie_added_attri(5, 33) -> 429;

%% 器魂：御品阶34，法术防御增加457
get_pinjie_added_attri(5, 34) -> 457;

%% 器魂：御品阶35，法术防御增加486
get_pinjie_added_attri(5, 35) -> 486;

%% 器魂：御品阶36，法术防御增加517
get_pinjie_added_attri(5, 36) -> 517;

%% 器魂：御品阶37，法术防御增加550
get_pinjie_added_attri(5, 37) -> 550;

%% 器魂：御品阶38，法术防御增加585
get_pinjie_added_attri(5, 38) -> 585;

%% 器魂：御品阶39，法术防御增加622
get_pinjie_added_attri(5, 39) -> 622;

%% 器魂：御品阶40，法术防御增加662
get_pinjie_added_attri(5, 40) -> 662;

%% 器魂：御品阶41，法术防御增加704
get_pinjie_added_attri(5, 41) -> 704;

%% 器魂：御品阶42，法术防御增加749
get_pinjie_added_attri(5, 42) -> 749;

%% 器魂：御品阶43，法术防御增加797
get_pinjie_added_attri(5, 43) -> 797;

%% 器魂：御品阶44，法术防御增加848
get_pinjie_added_attri(5, 44) -> 848;

%% 器魂：御品阶45，法术防御增加902
get_pinjie_added_attri(5, 45) -> 902;

%% 器魂：御品阶46，法术防御增加960
get_pinjie_added_attri(5, 46) -> 960;

%% 器魂：御品阶47，法术防御增加1021
get_pinjie_added_attri(5, 47) -> 1021;

%% 器魂：御品阶48，法术防御增加1086
get_pinjie_added_attri(5, 48) -> 1086;

%% 器魂：御品阶49，法术防御增加1156
get_pinjie_added_attri(5, 49) -> 1156;

%% 器魂：御品阶50，法术防御增加1230
get_pinjie_added_attri(5, 50) -> 1230;

%% 器魂：准品阶0，命中增加0
get_pinjie_added_attri(6, 0) -> 0;

%% 器魂：准品阶1，命中增加2
get_pinjie_added_attri(6, 1) -> 2;

%% 器魂：准品阶2，命中增加3
get_pinjie_added_attri(6, 2) -> 3;

%% 器魂：准品阶3，命中增加4
get_pinjie_added_attri(6, 3) -> 4;

%% 器魂：准品阶4，命中增加5
get_pinjie_added_attri(6, 4) -> 5;

%% 器魂：准品阶5，命中增加6
get_pinjie_added_attri(6, 5) -> 6;

%% 器魂：准品阶6，命中增加7
get_pinjie_added_attri(6, 6) -> 7;

%% 器魂：准品阶7，命中增加8
get_pinjie_added_attri(6, 7) -> 8;

%% 器魂：准品阶8，命中增加9
get_pinjie_added_attri(6, 8) -> 9;

%% 器魂：准品阶9，命中增加10
get_pinjie_added_attri(6, 9) -> 10;

%% 器魂：准品阶10，命中增加11
get_pinjie_added_attri(6, 10) -> 11;

%% 器魂：准品阶11，命中增加12
get_pinjie_added_attri(6, 11) -> 12;

%% 器魂：准品阶12，命中增加13
get_pinjie_added_attri(6, 12) -> 13;

%% 器魂：准品阶13，命中增加14
get_pinjie_added_attri(6, 13) -> 14;

%% 器魂：准品阶14，命中增加15
get_pinjie_added_attri(6, 14) -> 15;

%% 器魂：准品阶15，命中增加16
get_pinjie_added_attri(6, 15) -> 16;

%% 器魂：准品阶16，命中增加17
get_pinjie_added_attri(6, 16) -> 17;

%% 器魂：准品阶17，命中增加18
get_pinjie_added_attri(6, 17) -> 18;

%% 器魂：准品阶18，命中增加19
get_pinjie_added_attri(6, 18) -> 19;

%% 器魂：准品阶19，命中增加20
get_pinjie_added_attri(6, 19) -> 20;

%% 器魂：准品阶20，命中增加21
get_pinjie_added_attri(6, 20) -> 21;

%% 器魂：准品阶21，命中增加23
get_pinjie_added_attri(6, 21) -> 23;

%% 器魂：准品阶22，命中增加25
get_pinjie_added_attri(6, 22) -> 25;

%% 器魂：准品阶23，命中增加27
get_pinjie_added_attri(6, 23) -> 27;

%% 器魂：准品阶24，命中增加29
get_pinjie_added_attri(6, 24) -> 29;

%% 器魂：准品阶25，命中增加31
get_pinjie_added_attri(6, 25) -> 31;

%% 器魂：准品阶26，命中增加33
get_pinjie_added_attri(6, 26) -> 33;

%% 器魂：准品阶27，命中增加35
get_pinjie_added_attri(6, 27) -> 35;

%% 器魂：准品阶28，命中增加37
get_pinjie_added_attri(6, 28) -> 37;

%% 器魂：准品阶29，命中增加39
get_pinjie_added_attri(6, 29) -> 39;

%% 器魂：准品阶30，命中增加41
get_pinjie_added_attri(6, 30) -> 41;

%% 器魂：准品阶31，命中增加43
get_pinjie_added_attri(6, 31) -> 43;

%% 器魂：准品阶32，命中增加45
get_pinjie_added_attri(6, 32) -> 45;

%% 器魂：准品阶33，命中增加47
get_pinjie_added_attri(6, 33) -> 47;

%% 器魂：准品阶34，命中增加49
get_pinjie_added_attri(6, 34) -> 49;

%% 器魂：准品阶35，命中增加51
get_pinjie_added_attri(6, 35) -> 51;

%% 器魂：准品阶36，命中增加53
get_pinjie_added_attri(6, 36) -> 53;

%% 器魂：准品阶37，命中增加56
get_pinjie_added_attri(6, 37) -> 56;

%% 器魂：准品阶38，命中增加59
get_pinjie_added_attri(6, 38) -> 59;

%% 器魂：准品阶39，命中增加62
get_pinjie_added_attri(6, 39) -> 62;

%% 器魂：准品阶40，命中增加65
get_pinjie_added_attri(6, 40) -> 65;

%% 器魂：准品阶41，命中增加68
get_pinjie_added_attri(6, 41) -> 68;

%% 器魂：准品阶42，命中增加71
get_pinjie_added_attri(6, 42) -> 71;

%% 器魂：准品阶43，命中增加74
get_pinjie_added_attri(6, 43) -> 74;

%% 器魂：准品阶44，命中增加77
get_pinjie_added_attri(6, 44) -> 77;

%% 器魂：准品阶45，命中增加80
get_pinjie_added_attri(6, 45) -> 80;

%% 器魂：准品阶46，命中增加83
get_pinjie_added_attri(6, 46) -> 83;

%% 器魂：准品阶47，命中增加86
get_pinjie_added_attri(6, 47) -> 86;

%% 器魂：准品阶48，命中增加89
get_pinjie_added_attri(6, 48) -> 89;

%% 器魂：准品阶49，命中增加92
get_pinjie_added_attri(6, 49) -> 92;

%% 器魂：准品阶50，命中增加95
get_pinjie_added_attri(6, 50) -> 95;

%% 器魂：闪品阶0，闪避增加0
get_pinjie_added_attri(7, 0) -> 0;

%% 器魂：闪品阶1，闪避增加2
get_pinjie_added_attri(7, 1) -> 2;

%% 器魂：闪品阶2，闪避增加3
get_pinjie_added_attri(7, 2) -> 3;

%% 器魂：闪品阶3，闪避增加4
get_pinjie_added_attri(7, 3) -> 4;

%% 器魂：闪品阶4，闪避增加5
get_pinjie_added_attri(7, 4) -> 5;

%% 器魂：闪品阶5，闪避增加6
get_pinjie_added_attri(7, 5) -> 6;

%% 器魂：闪品阶6，闪避增加7
get_pinjie_added_attri(7, 6) -> 7;

%% 器魂：闪品阶7，闪避增加8
get_pinjie_added_attri(7, 7) -> 8;

%% 器魂：闪品阶8，闪避增加9
get_pinjie_added_attri(7, 8) -> 9;

%% 器魂：闪品阶9，闪避增加10
get_pinjie_added_attri(7, 9) -> 10;

%% 器魂：闪品阶10，闪避增加11
get_pinjie_added_attri(7, 10) -> 11;

%% 器魂：闪品阶11，闪避增加12
get_pinjie_added_attri(7, 11) -> 12;

%% 器魂：闪品阶12，闪避增加13
get_pinjie_added_attri(7, 12) -> 13;

%% 器魂：闪品阶13，闪避增加14
get_pinjie_added_attri(7, 13) -> 14;

%% 器魂：闪品阶14，闪避增加15
get_pinjie_added_attri(7, 14) -> 15;

%% 器魂：闪品阶15，闪避增加16
get_pinjie_added_attri(7, 15) -> 16;

%% 器魂：闪品阶16，闪避增加17
get_pinjie_added_attri(7, 16) -> 17;

%% 器魂：闪品阶17，闪避增加18
get_pinjie_added_attri(7, 17) -> 18;

%% 器魂：闪品阶18，闪避增加19
get_pinjie_added_attri(7, 18) -> 19;

%% 器魂：闪品阶19，闪避增加20
get_pinjie_added_attri(7, 19) -> 20;

%% 器魂：闪品阶20，闪避增加21
get_pinjie_added_attri(7, 20) -> 21;

%% 器魂：闪品阶21，闪避增加23
get_pinjie_added_attri(7, 21) -> 23;

%% 器魂：闪品阶22，闪避增加25
get_pinjie_added_attri(7, 22) -> 25;

%% 器魂：闪品阶23，闪避增加27
get_pinjie_added_attri(7, 23) -> 27;

%% 器魂：闪品阶24，闪避增加29
get_pinjie_added_attri(7, 24) -> 29;

%% 器魂：闪品阶25，闪避增加31
get_pinjie_added_attri(7, 25) -> 31;

%% 器魂：闪品阶26，闪避增加33
get_pinjie_added_attri(7, 26) -> 33;

%% 器魂：闪品阶27，闪避增加35
get_pinjie_added_attri(7, 27) -> 35;

%% 器魂：闪品阶28，闪避增加37
get_pinjie_added_attri(7, 28) -> 37;

%% 器魂：闪品阶29，闪避增加39
get_pinjie_added_attri(7, 29) -> 39;

%% 器魂：闪品阶30，闪避增加41
get_pinjie_added_attri(7, 30) -> 41;

%% 器魂：闪品阶31，闪避增加43
get_pinjie_added_attri(7, 31) -> 43;

%% 器魂：闪品阶32，闪避增加45
get_pinjie_added_attri(7, 32) -> 45;

%% 器魂：闪品阶33，闪避增加47
get_pinjie_added_attri(7, 33) -> 47;

%% 器魂：闪品阶34，闪避增加49
get_pinjie_added_attri(7, 34) -> 49;

%% 器魂：闪品阶35，闪避增加51
get_pinjie_added_attri(7, 35) -> 51;

%% 器魂：闪品阶36，闪避增加53
get_pinjie_added_attri(7, 36) -> 53;

%% 器魂：闪品阶37，闪避增加56
get_pinjie_added_attri(7, 37) -> 56;

%% 器魂：闪品阶38，闪避增加59
get_pinjie_added_attri(7, 38) -> 59;

%% 器魂：闪品阶39，闪避增加62
get_pinjie_added_attri(7, 39) -> 62;

%% 器魂：闪品阶40，闪避增加65
get_pinjie_added_attri(7, 40) -> 65;

%% 器魂：闪品阶41，闪避增加68
get_pinjie_added_attri(7, 41) -> 68;

%% 器魂：闪品阶42，闪避增加71
get_pinjie_added_attri(7, 42) -> 71;

%% 器魂：闪品阶43，闪避增加74
get_pinjie_added_attri(7, 43) -> 74;

%% 器魂：闪品阶44，闪避增加77
get_pinjie_added_attri(7, 44) -> 77;

%% 器魂：闪品阶45，闪避增加80
get_pinjie_added_attri(7, 45) -> 80;

%% 器魂：闪品阶46，闪避增加83
get_pinjie_added_attri(7, 46) -> 83;

%% 器魂：闪品阶47，闪避增加86
get_pinjie_added_attri(7, 47) -> 86;

%% 器魂：闪品阶48，闪避增加89
get_pinjie_added_attri(7, 48) -> 89;

%% 器魂：闪品阶49，闪避增加92
get_pinjie_added_attri(7, 49) -> 92;

%% 器魂：闪品阶50，闪避增加95
get_pinjie_added_attri(7, 50) -> 95;

%% 器魂：运品阶0，躲避暴击增加0
get_pinjie_added_attri(8, 0) -> 0;

%% 器魂：运品阶1，躲避暴击增加2
get_pinjie_added_attri(8, 1) -> 2;

%% 器魂：运品阶2，躲避暴击增加3
get_pinjie_added_attri(8, 2) -> 3;

%% 器魂：运品阶3，躲避暴击增加4
get_pinjie_added_attri(8, 3) -> 4;

%% 器魂：运品阶4，躲避暴击增加5
get_pinjie_added_attri(8, 4) -> 5;

%% 器魂：运品阶5，躲避暴击增加6
get_pinjie_added_attri(8, 5) -> 6;

%% 器魂：运品阶6，躲避暴击增加7
get_pinjie_added_attri(8, 6) -> 7;

%% 器魂：运品阶7，躲避暴击增加8
get_pinjie_added_attri(8, 7) -> 8;

%% 器魂：运品阶8，躲避暴击增加9
get_pinjie_added_attri(8, 8) -> 9;

%% 器魂：运品阶9，躲避暴击增加10
get_pinjie_added_attri(8, 9) -> 10;

%% 器魂：运品阶10，躲避暴击增加11
get_pinjie_added_attri(8, 10) -> 11;

%% 器魂：运品阶11，躲避暴击增加12
get_pinjie_added_attri(8, 11) -> 12;

%% 器魂：运品阶12，躲避暴击增加13
get_pinjie_added_attri(8, 12) -> 13;

%% 器魂：运品阶13，躲避暴击增加14
get_pinjie_added_attri(8, 13) -> 14;

%% 器魂：运品阶14，躲避暴击增加15
get_pinjie_added_attri(8, 14) -> 15;

%% 器魂：运品阶15，躲避暴击增加16
get_pinjie_added_attri(8, 15) -> 16;

%% 器魂：运品阶16，躲避暴击增加17
get_pinjie_added_attri(8, 16) -> 17;

%% 器魂：运品阶17，躲避暴击增加18
get_pinjie_added_attri(8, 17) -> 18;

%% 器魂：运品阶18，躲避暴击增加19
get_pinjie_added_attri(8, 18) -> 19;

%% 器魂：运品阶19，躲避暴击增加20
get_pinjie_added_attri(8, 19) -> 20;

%% 器魂：运品阶20，躲避暴击增加21
get_pinjie_added_attri(8, 20) -> 21;

%% 器魂：运品阶21，躲避暴击增加23
get_pinjie_added_attri(8, 21) -> 23;

%% 器魂：运品阶22，躲避暴击增加25
get_pinjie_added_attri(8, 22) -> 25;

%% 器魂：运品阶23，躲避暴击增加27
get_pinjie_added_attri(8, 23) -> 27;

%% 器魂：运品阶24，躲避暴击增加29
get_pinjie_added_attri(8, 24) -> 29;

%% 器魂：运品阶25，躲避暴击增加31
get_pinjie_added_attri(8, 25) -> 31;

%% 器魂：运品阶26，躲避暴击增加33
get_pinjie_added_attri(8, 26) -> 33;

%% 器魂：运品阶27，躲避暴击增加35
get_pinjie_added_attri(8, 27) -> 35;

%% 器魂：运品阶28，躲避暴击增加37
get_pinjie_added_attri(8, 28) -> 37;

%% 器魂：运品阶29，躲避暴击增加39
get_pinjie_added_attri(8, 29) -> 39;

%% 器魂：运品阶30，躲避暴击增加41
get_pinjie_added_attri(8, 30) -> 41;

%% 器魂：运品阶31，躲避暴击增加43
get_pinjie_added_attri(8, 31) -> 43;

%% 器魂：运品阶32，躲避暴击增加45
get_pinjie_added_attri(8, 32) -> 45;

%% 器魂：运品阶33，躲避暴击增加47
get_pinjie_added_attri(8, 33) -> 47;

%% 器魂：运品阶34，躲避暴击增加49
get_pinjie_added_attri(8, 34) -> 49;

%% 器魂：运品阶35，躲避暴击增加51
get_pinjie_added_attri(8, 35) -> 51;

%% 器魂：运品阶36，躲避暴击增加53
get_pinjie_added_attri(8, 36) -> 53;

%% 器魂：运品阶37，躲避暴击增加56
get_pinjie_added_attri(8, 37) -> 56;

%% 器魂：运品阶38，躲避暴击增加59
get_pinjie_added_attri(8, 38) -> 59;

%% 器魂：运品阶39，躲避暴击增加62
get_pinjie_added_attri(8, 39) -> 62;

%% 器魂：运品阶40，躲避暴击增加65
get_pinjie_added_attri(8, 40) -> 65;

%% 器魂：运品阶41，躲避暴击增加68
get_pinjie_added_attri(8, 41) -> 68;

%% 器魂：运品阶42，躲避暴击增加71
get_pinjie_added_attri(8, 42) -> 71;

%% 器魂：运品阶43，躲避暴击增加74
get_pinjie_added_attri(8, 43) -> 74;

%% 器魂：运品阶44，躲避暴击增加77
get_pinjie_added_attri(8, 44) -> 77;

%% 器魂：运品阶45，躲避暴击增加80
get_pinjie_added_attri(8, 45) -> 80;

%% 器魂：运品阶46，躲避暴击增加83
get_pinjie_added_attri(8, 46) -> 83;

%% 器魂：运品阶47，躲避暴击增加86
get_pinjie_added_attri(8, 47) -> 86;

%% 器魂：运品阶48，躲避暴击增加89
get_pinjie_added_attri(8, 48) -> 89;

%% 器魂：运品阶49，躲避暴击增加92
get_pinjie_added_attri(8, 49) -> 92;

%% 器魂：运品阶50，躲避暴击增加95
get_pinjie_added_attri(8, 50) -> 95;

%% 器魂：速品阶0，速度增加0
get_pinjie_added_attri(9, 0) -> 0;

%% 器魂：速品阶1，速度增加7
get_pinjie_added_attri(9, 1) -> 7;

%% 器魂：速品阶2，速度增加10
get_pinjie_added_attri(9, 2) -> 10;

%% 器魂：速品阶3，速度增加13
get_pinjie_added_attri(9, 3) -> 13;

%% 器魂：速品阶4，速度增加18
get_pinjie_added_attri(9, 4) -> 18;

%% 器魂：速品阶5，速度增加22
get_pinjie_added_attri(9, 5) -> 22;

%% 器魂：速品阶6，速度增加26
get_pinjie_added_attri(9, 6) -> 26;

%% 器魂：速品阶7，速度增加29
get_pinjie_added_attri(9, 7) -> 29;

%% 器魂：速品阶8，速度增加33
get_pinjie_added_attri(9, 8) -> 33;

%% 器魂：速品阶9，速度增加35
get_pinjie_added_attri(9, 9) -> 35;

%% 器魂：速品阶10，速度增加38
get_pinjie_added_attri(9, 10) -> 38;

%% 器魂：速品阶11，速度增加40
get_pinjie_added_attri(9, 11) -> 40;

%% 器魂：速品阶12，速度增加43
get_pinjie_added_attri(9, 12) -> 43;

%% 器魂：速品阶13，速度增加46
get_pinjie_added_attri(9, 13) -> 46;

%% 器魂：速品阶14，速度增加49
get_pinjie_added_attri(9, 14) -> 49;

%% 器魂：速品阶15，速度增加53
get_pinjie_added_attri(9, 15) -> 53;

%% 器魂：速品阶16，速度增加57
get_pinjie_added_attri(9, 16) -> 57;

%% 器魂：速品阶17，速度增加61
get_pinjie_added_attri(9, 17) -> 61;

%% 器魂：速品阶18，速度增加65
get_pinjie_added_attri(9, 18) -> 65;

%% 器魂：速品阶19，速度增加69
get_pinjie_added_attri(9, 19) -> 69;

%% 器魂：速品阶20，速度增加74
get_pinjie_added_attri(9, 20) -> 74;

%% 器魂：速品阶21，速度增加81
get_pinjie_added_attri(9, 21) -> 81;

%% 器魂：速品阶22，速度增加86
get_pinjie_added_attri(9, 22) -> 86;

%% 器魂：速品阶23，速度增加92
get_pinjie_added_attri(9, 23) -> 92;

%% 器魂：速品阶24，速度增加98
get_pinjie_added_attri(9, 24) -> 98;

%% 器魂：速品阶25，速度增加104
get_pinjie_added_attri(9, 25) -> 104;

%% 器魂：速品阶26，速度增加110
get_pinjie_added_attri(9, 26) -> 110;

%% 器魂：速品阶27，速度增加118
get_pinjie_added_attri(9, 27) -> 118;

%% 器魂：速品阶28，速度增加125
get_pinjie_added_attri(9, 28) -> 125;

%% 器魂：速品阶29，速度增加133
get_pinjie_added_attri(9, 29) -> 133;

%% 器魂：速品阶30，速度增加142
get_pinjie_added_attri(9, 30) -> 142;

%% 器魂：速品阶31，速度增加151
get_pinjie_added_attri(9, 31) -> 151;

%% 器魂：速品阶32，速度增加160
get_pinjie_added_attri(9, 32) -> 160;

%% 器魂：速品阶33，速度增加171
get_pinjie_added_attri(9, 33) -> 171;

%% 器魂：速品阶34，速度增加182
get_pinjie_added_attri(9, 34) -> 182;

%% 器魂：速品阶35，速度增加193
get_pinjie_added_attri(9, 35) -> 193;

%% 器魂：速品阶36，速度增加206
get_pinjie_added_attri(9, 36) -> 206;

%% 器魂：速品阶37，速度增加219
get_pinjie_added_attri(9, 37) -> 219;

%% 器魂：速品阶38，速度增加233
get_pinjie_added_attri(9, 38) -> 233;

%% 器魂：速品阶39，速度增加248
get_pinjie_added_attri(9, 39) -> 248;

%% 器魂：速品阶40，速度增加263
get_pinjie_added_attri(9, 40) -> 263;

%% 器魂：速品阶41，速度增加280
get_pinjie_added_attri(9, 41) -> 280;

%% 器魂：速品阶42，速度增加298
get_pinjie_added_attri(9, 42) -> 298;

%% 器魂：速品阶43，速度增加317
get_pinjie_added_attri(9, 43) -> 317;

%% 器魂：速品阶44，速度增加338
get_pinjie_added_attri(9, 44) -> 338;

%% 器魂：速品阶45，速度增加359
get_pinjie_added_attri(9, 45) -> 359;

%% 器魂：速品阶46，速度增加382
get_pinjie_added_attri(9, 46) -> 382;

%% 器魂：速品阶47，速度增加406
get_pinjie_added_attri(9, 47) -> 406;

%% 器魂：速品阶48，速度增加432
get_pinjie_added_attri(9, 48) -> 432;

%% 器魂：速品阶49，速度增加460
get_pinjie_added_attri(9, 49) -> 460;

%% 器魂：速品阶50，速度增加490
get_pinjie_added_attri(9, 50) -> 490;

%% 器魂：暴品阶0，暴击增加0
get_pinjie_added_attri(10, 0) -> 0;

%% 器魂：暴品阶1，暴击增加2
get_pinjie_added_attri(10, 1) -> 2;

%% 器魂：暴品阶2，暴击增加3
get_pinjie_added_attri(10, 2) -> 3;

%% 器魂：暴品阶3，暴击增加4
get_pinjie_added_attri(10, 3) -> 4;

%% 器魂：暴品阶4，暴击增加5
get_pinjie_added_attri(10, 4) -> 5;

%% 器魂：暴品阶5，暴击增加6
get_pinjie_added_attri(10, 5) -> 6;

%% 器魂：暴品阶6，暴击增加7
get_pinjie_added_attri(10, 6) -> 7;

%% 器魂：暴品阶7，暴击增加8
get_pinjie_added_attri(10, 7) -> 8;

%% 器魂：暴品阶8，暴击增加9
get_pinjie_added_attri(10, 8) -> 9;

%% 器魂：暴品阶9，暴击增加10
get_pinjie_added_attri(10, 9) -> 10;

%% 器魂：暴品阶10，暴击增加11
get_pinjie_added_attri(10, 10) -> 11;

%% 器魂：暴品阶11，暴击增加12
get_pinjie_added_attri(10, 11) -> 12;

%% 器魂：暴品阶12，暴击增加13
get_pinjie_added_attri(10, 12) -> 13;

%% 器魂：暴品阶13，暴击增加14
get_pinjie_added_attri(10, 13) -> 14;

%% 器魂：暴品阶14，暴击增加15
get_pinjie_added_attri(10, 14) -> 15;

%% 器魂：暴品阶15，暴击增加16
get_pinjie_added_attri(10, 15) -> 16;

%% 器魂：暴品阶16，暴击增加17
get_pinjie_added_attri(10, 16) -> 17;

%% 器魂：暴品阶17，暴击增加18
get_pinjie_added_attri(10, 17) -> 18;

%% 器魂：暴品阶18，暴击增加19
get_pinjie_added_attri(10, 18) -> 19;

%% 器魂：暴品阶19，暴击增加20
get_pinjie_added_attri(10, 19) -> 20;

%% 器魂：暴品阶20，暴击增加21
get_pinjie_added_attri(10, 20) -> 21;

%% 器魂：暴品阶21，暴击增加23
get_pinjie_added_attri(10, 21) -> 23;

%% 器魂：暴品阶22，暴击增加25
get_pinjie_added_attri(10, 22) -> 25;

%% 器魂：暴品阶23，暴击增加27
get_pinjie_added_attri(10, 23) -> 27;

%% 器魂：暴品阶24，暴击增加29
get_pinjie_added_attri(10, 24) -> 29;

%% 器魂：暴品阶25，暴击增加31
get_pinjie_added_attri(10, 25) -> 31;

%% 器魂：暴品阶26，暴击增加33
get_pinjie_added_attri(10, 26) -> 33;

%% 器魂：暴品阶27，暴击增加35
get_pinjie_added_attri(10, 27) -> 35;

%% 器魂：暴品阶28，暴击增加37
get_pinjie_added_attri(10, 28) -> 37;

%% 器魂：暴品阶29，暴击增加39
get_pinjie_added_attri(10, 29) -> 39;

%% 器魂：暴品阶30，暴击增加41
get_pinjie_added_attri(10, 30) -> 41;

%% 器魂：暴品阶31，暴击增加43
get_pinjie_added_attri(10, 31) -> 43;

%% 器魂：暴品阶32，暴击增加45
get_pinjie_added_attri(10, 32) -> 45;

%% 器魂：暴品阶33，暴击增加47
get_pinjie_added_attri(10, 33) -> 47;

%% 器魂：暴品阶34，暴击增加49
get_pinjie_added_attri(10, 34) -> 49;

%% 器魂：暴品阶35，暴击增加51
get_pinjie_added_attri(10, 35) -> 51;

%% 器魂：暴品阶36，暴击增加53
get_pinjie_added_attri(10, 36) -> 53;

%% 器魂：暴品阶37，暴击增加56
get_pinjie_added_attri(10, 37) -> 56;

%% 器魂：暴品阶38，暴击增加59
get_pinjie_added_attri(10, 38) -> 59;

%% 器魂：暴品阶39，暴击增加62
get_pinjie_added_attri(10, 39) -> 62;

%% 器魂：暴品阶40，暴击增加65
get_pinjie_added_attri(10, 40) -> 65;

%% 器魂：暴品阶41，暴击增加68
get_pinjie_added_attri(10, 41) -> 68;

%% 器魂：暴品阶42，暴击增加71
get_pinjie_added_attri(10, 42) -> 71;

%% 器魂：暴品阶43，暴击增加74
get_pinjie_added_attri(10, 43) -> 74;

%% 器魂：暴品阶44，暴击增加77
get_pinjie_added_attri(10, 44) -> 77;

%% 器魂：暴品阶45，暴击增加80
get_pinjie_added_attri(10, 45) -> 80;

%% 器魂：暴品阶46，暴击增加83
get_pinjie_added_attri(10, 46) -> 83;

%% 器魂：暴品阶47，暴击增加86
get_pinjie_added_attri(10, 47) -> 86;

%% 器魂：暴品阶48，暴击增加89
get_pinjie_added_attri(10, 48) -> 89;

%% 器魂：暴品阶49，暴击增加92
get_pinjie_added_attri(10, 49) -> 92;

%% 器魂：暴品阶50，暴击增加95
get_pinjie_added_attri(10, 50) -> 95.


%%================================================
%% 根据神器阶段id值获取给武将属性的加成
get_shenqi_stage_added_attri(0) ->
	#role_update_attri{
		gd_currentHp  = 0,
		gd_maxHp      = 0,
		p_def         = 0,
		m_def         = 0,
		p_att         = 0,
		m_att         = 0,
		gd_mingzhong  = 0,
		gd_shanbi     = 0,
		gd_xingyun    = 0,
		gd_speed      = 0,
		gd_baoji      = 0
	};

get_shenqi_stage_added_attri(1) ->
	#role_update_attri{
		gd_currentHp  = 51,
		gd_maxHp      = 51,
		p_def         = 37,
		m_def         = 37,
		p_att         = 32,
		m_att         = 32,
		gd_mingzhong  = 5,
		gd_shanbi     = 5,
		gd_xingyun    = 5,
		gd_speed      = 11,
		gd_baoji      = 5
	};

get_shenqi_stage_added_attri(2) ->
	#role_update_attri{
		gd_currentHp  = 86,
		gd_maxHp      = 86,
		p_def         = 62,
		m_def         = 62,
		p_att         = 54,
		m_att         = 54,
		gd_mingzhong  = 7,
		gd_shanbi     = 7,
		gd_xingyun    = 7,
		gd_speed      = 24,
		gd_baoji      = 7
	};

get_shenqi_stage_added_attri(3) ->
	#role_update_attri{
		gd_currentHp  = 125,
		gd_maxHp      = 125,
		p_def         = 90,
		m_def         = 90,
		p_att         = 78,
		m_att         = 78,
		gd_mingzhong  = 11,
		gd_shanbi     = 11,
		gd_xingyun    = 11,
		gd_speed      = 35,
		gd_baoji      = 11
	};

get_shenqi_stage_added_attri(4) ->
	#role_update_attri{
		gd_currentHp  = 207,
		gd_maxHp      = 207,
		p_def         = 149,
		m_def         = 149,
		p_att         = 130,
		m_att         = 130,
		gd_mingzhong  = 15,
		gd_shanbi     = 15,
		gd_xingyun    = 15,
		gd_speed      = 60,
		gd_baoji      = 15
	};

get_shenqi_stage_added_attri(5) ->
	#role_update_attri{
		gd_currentHp  = 384,
		gd_maxHp      = 384,
		p_def         = 276,
		m_def         = 276,
		p_att         = 242,
		m_att         = 242,
		gd_mingzhong  = 22,
		gd_shanbi     = 22,
		gd_xingyun    = 22,
		gd_speed      = 110,
		gd_baoji      = 22
	};

get_shenqi_stage_added_attri(6) ->
	#role_update_attri{
		gd_currentHp  = 570,
		gd_maxHp      = 570,
		p_def         = 410,
		m_def         = 410,
		p_att         = 360,
		m_att         = 360,
		gd_mingzhong  = 30,
		gd_shanbi     = 30,
		gd_xingyun    = 30,
		gd_speed      = 164,
		gd_baoji      = 30
	}.


%%================================================
%% 获取最大的器魂等级
get_max_qihun_level() -> 50.


%%================================================
%% get_perfect_rand_val(品阶等级) -> {最小概率值, 最大概率值}
get_perfect_rand_val(0) -> {0.233, 0.35};

get_perfect_rand_val(1) -> {0.225, 0.338};

get_perfect_rand_val(2) -> {0.221, 0.332};

get_perfect_rand_val(3) -> {0.217, 0.326};

get_perfect_rand_val(4) -> {0.213, 0.320};

get_perfect_rand_val(5) -> {0.21, 0.315};

get_perfect_rand_val(6) -> {0.206, 0.309};

get_perfect_rand_val(7) -> {0.202, 0.303};

get_perfect_rand_val(8) -> {0.198, 0.297};

get_perfect_rand_val(9) -> {0.194, 0.291};

get_perfect_rand_val(10) -> {0.190, 0.285};

get_perfect_rand_val(11) -> {0.186, 0.28};

get_perfect_rand_val(12) -> {0.182, 0.274};

get_perfect_rand_val(13) -> {0.178, 0.268};

get_perfect_rand_val(14) -> {0.175, 0.262};

get_perfect_rand_val(15) -> {0.171, 0.256};

get_perfect_rand_val(16) -> {0.167, 0.250};

get_perfect_rand_val(17) -> {0.163, 0.245};

get_perfect_rand_val(18) -> {0.159, 0.239};

get_perfect_rand_val(19) -> {0.155, 0.233};

get_perfect_rand_val(20) -> {0.151, 0.227};

get_perfect_rand_val(21) -> {0.147, 0.221};

get_perfect_rand_val(22) -> {0.143, 0.215};

get_perfect_rand_val(23) -> {0.14, 0.21};

get_perfect_rand_val(24) -> {0.136, 0.204};

get_perfect_rand_val(25) -> {0.132, 0.198};

get_perfect_rand_val(26) -> {0.128, 0.192};

get_perfect_rand_val(27) -> {0.124, 0.186};

get_perfect_rand_val(28) -> {0.120, 0.180};

get_perfect_rand_val(29) -> {0.116, 0.175};

get_perfect_rand_val(30) -> {0.112, 0.169};

get_perfect_rand_val(31) -> {0.108, 0.163};

get_perfect_rand_val(32) -> {0.105, 0.157};

get_perfect_rand_val(33) -> {0.101, 0.151};

get_perfect_rand_val(34) -> {0.097, 0.145};

get_perfect_rand_val(35) -> {0.093, 0.14};

get_perfect_rand_val(36) -> {0.089, 0.134};

get_perfect_rand_val(37) -> {0.085, 0.128};

get_perfect_rand_val(38) -> {0.081, 0.122};

get_perfect_rand_val(39) -> {0.077, 0.116};

get_perfect_rand_val(40) -> {0.073, 0.110};

get_perfect_rand_val(41) -> {0.07, 0.107};

get_perfect_rand_val(42) -> {0.066, 0.104};

get_perfect_rand_val(43) -> {0.062, 0.101};

get_perfect_rand_val(44) -> {0.058, 0.098};

get_perfect_rand_val(45) -> {0.054, 0.095};

get_perfect_rand_val(46) -> {0.050, 0.092};

get_perfect_rand_val(47) -> {0.046, 0.089};

get_perfect_rand_val(48) -> {0.042, 0.086};

get_perfect_rand_val(49) -> {0.038, 0.083};

get_perfect_rand_val(50) -> {0.034, 0.08}.


%%================================================
%% 获取修炼器魂需要的人物等级
get_needlevel_by_qihun(0) -> 30;

get_needlevel_by_qihun(1) -> 30;

get_needlevel_by_qihun(2) -> 30;

get_needlevel_by_qihun(3) -> 30;

get_needlevel_by_qihun(4) -> 31;

get_needlevel_by_qihun(5) -> 32;

get_needlevel_by_qihun(6) -> 34;

get_needlevel_by_qihun(7) -> 36;

get_needlevel_by_qihun(8) -> 38;

get_needlevel_by_qihun(9) -> 40;

get_needlevel_by_qihun(10) -> 42;

get_needlevel_by_qihun(11) -> 44;

get_needlevel_by_qihun(12) -> 46;

get_needlevel_by_qihun(13) -> 48;

get_needlevel_by_qihun(14) -> 50;

get_needlevel_by_qihun(15) -> 52;

get_needlevel_by_qihun(16) -> 54;

get_needlevel_by_qihun(17) -> 55;

get_needlevel_by_qihun(18) -> 56;

get_needlevel_by_qihun(19) -> 58;

get_needlevel_by_qihun(20) -> 60;

get_needlevel_by_qihun(21) -> 62;

get_needlevel_by_qihun(22) -> 64;

get_needlevel_by_qihun(23) -> 66;

get_needlevel_by_qihun(24) -> 68;

get_needlevel_by_qihun(25) -> 70;

get_needlevel_by_qihun(26) -> 72;

get_needlevel_by_qihun(27) -> 74;

get_needlevel_by_qihun(28) -> 76;

get_needlevel_by_qihun(29) -> 78;

get_needlevel_by_qihun(30) -> 80;

get_needlevel_by_qihun(31) -> 81;

get_needlevel_by_qihun(32) -> 82;

get_needlevel_by_qihun(33) -> 83;

get_needlevel_by_qihun(34) -> 84;

get_needlevel_by_qihun(35) -> 85;

get_needlevel_by_qihun(36) -> 86;

get_needlevel_by_qihun(37) -> 87;

get_needlevel_by_qihun(38) -> 88;

get_needlevel_by_qihun(39) -> 89;

get_needlevel_by_qihun(40) -> 90;

get_needlevel_by_qihun(41) -> 91;

get_needlevel_by_qihun(42) -> 92;

get_needlevel_by_qihun(43) -> 93;

get_needlevel_by_qihun(44) -> 94;

get_needlevel_by_qihun(45) -> 95;

get_needlevel_by_qihun(46) -> 96;

get_needlevel_by_qihun(47) -> 97;

get_needlevel_by_qihun(48) -> 98;

get_needlevel_by_qihun(49) -> 99;

get_needlevel_by_qihun(50) -> 100.


%%================================================
