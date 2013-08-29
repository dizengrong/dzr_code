-module(data_fengdi).

-compile(export_all).



%% 根据土地id获取其开启的条件：{官职条件, Vip条件}
get_open_land_require(1) -> {1, 0};

get_open_land_require(2) -> {1, 0};

get_open_land_require(3) -> {9, 0};

get_open_land_require(4) -> {12, 0};

get_open_land_require(5) -> {16, 0};

get_open_land_require(6) -> {19, 0}.


%%================================================
%% 根据土地id获取其开启所需的金币
get_open_land_cost(1) -> 0;

get_open_land_cost(2) -> 0;

get_open_land_cost(3) -> 0;

get_open_land_cost(4) -> 0;

get_open_land_cost(5) -> 200;

get_open_land_cost(6) -> 300.


%%================================================
%% get_seed_result(种子类型, 官职id, 种子品质)-> 银币或经验
get_seed_result(1, 1, 1) -> 3900;
get_seed_result(2, 1, 1) -> 8100;

get_seed_result(1, 2, 1) -> 5600;
get_seed_result(2, 2, 1) -> 11000;

get_seed_result(1, 3, 1) -> 7300;
get_seed_result(2, 3, 1) -> 11600;

get_seed_result(1, 4, 1) -> 8000;
get_seed_result(2, 4, 1) -> 12000;

get_seed_result(1, 5, 1) -> 9400;
get_seed_result(2, 5, 1) -> 12500;

get_seed_result(1, 6, 1) -> 11400;
get_seed_result(2, 6, 1) -> 13200;

get_seed_result(1, 7, 1) -> 13700;
get_seed_result(2, 7, 1) -> 13500;

get_seed_result(1, 8, 1) -> 26500;
get_seed_result(2, 8, 1) -> 14000;

get_seed_result(1, 9, 1) -> 30500;
get_seed_result(2, 9, 1) -> 14300;

get_seed_result(1, 10, 1) -> 52600;
get_seed_result(2, 10, 1) -> 15000;

get_seed_result(1, 11, 1) -> 78100;
get_seed_result(2, 11, 1) -> 15500;

get_seed_result(1, 12, 1) -> 90800;
get_seed_result(2, 12, 1) -> 15800;

get_seed_result(1, 13, 1) -> 111000;
get_seed_result(2, 13, 1) -> 16500;

get_seed_result(1, 14, 1) -> 129400;
get_seed_result(2, 14, 1) -> 16800;

get_seed_result(1, 15, 1) -> 152500;
get_seed_result(2, 15, 1) -> 17100;

get_seed_result(1, 16, 1) -> 175800;
get_seed_result(2, 16, 1) -> 17400;

get_seed_result(1, 17, 1) -> 192500;
get_seed_result(2, 17, 1) -> 17600;

get_seed_result(1, 18, 1) -> 201300;
get_seed_result(2, 18, 1) -> 17700;

get_seed_result(1, 19, 1) -> 210300;
get_seed_result(2, 19, 1) -> 17800;

get_seed_result(1, 20, 1) -> 218400;
get_seed_result(2, 20, 1) -> 17900;

get_seed_result(1, 21, 1) -> 234100;
get_seed_result(2, 21, 1) -> 18000;

get_seed_result(1, 1, 2) -> 5800;
get_seed_result(2, 1, 2) -> 20300;

get_seed_result(1, 2, 2) -> 8300;
get_seed_result(2, 2, 2) -> 29000;

get_seed_result(1, 3, 2) -> 11000;
get_seed_result(2, 3, 2) -> 30800;

get_seed_result(1, 4, 2) -> 12000;
get_seed_result(2, 4, 2) -> 32000;

get_seed_result(1, 5, 2) -> 14100;
get_seed_result(2, 5, 2) -> 33500;

get_seed_result(1, 6, 2) -> 17200;
get_seed_result(2, 6, 2) -> 35600;

get_seed_result(1, 7, 2) -> 20500;
get_seed_result(2, 7, 2) -> 36500;

get_seed_result(1, 8, 2) -> 39800;
get_seed_result(2, 8, 2) -> 38000;

get_seed_result(1, 9, 2) -> 45800;
get_seed_result(2, 9, 2) -> 38900;

get_seed_result(1, 10, 2) -> 78800;
get_seed_result(2, 10, 2) -> 41000;

get_seed_result(1, 11, 2) -> 117100;
get_seed_result(2, 11, 2) -> 42500;

get_seed_result(1, 12, 2) -> 136200;
get_seed_result(2, 12, 2) -> 43400;

get_seed_result(1, 13, 2) -> 166500;
get_seed_result(2, 13, 2) -> 45500;

get_seed_result(1, 14, 2) -> 194100;
get_seed_result(2, 14, 2) -> 46400;

get_seed_result(1, 15, 2) -> 228700;
get_seed_result(2, 15, 2) -> 47300;

get_seed_result(1, 16, 2) -> 263700;
get_seed_result(2, 16, 2) -> 48200;

get_seed_result(1, 17, 2) -> 288800;
get_seed_result(2, 17, 2) -> 48800;

get_seed_result(1, 18, 2) -> 302000;
get_seed_result(2, 18, 2) -> 49100;

get_seed_result(1, 19, 2) -> 315400;
get_seed_result(2, 19, 2) -> 49400;

get_seed_result(1, 20, 2) -> 327500;
get_seed_result(2, 20, 2) -> 49700;

get_seed_result(1, 21, 2) -> 351100;
get_seed_result(2, 21, 2) -> 50000;

get_seed_result(1, 1, 3) -> 9700;
get_seed_result(2, 1, 3) -> 50400;

get_seed_result(1, 2, 3) -> 13900;
get_seed_result(2, 2, 3) -> 62000;

get_seed_result(1, 3, 3) -> 18300;
get_seed_result(2, 3, 3) -> 64400;

get_seed_result(1, 4, 3) -> 20000;
get_seed_result(2, 4, 3) -> 66000;

get_seed_result(1, 5, 3) -> 23600;
get_seed_result(2, 5, 3) -> 68000;

get_seed_result(1, 6, 3) -> 28600;
get_seed_result(2, 6, 3) -> 70800;

get_seed_result(1, 7, 3) -> 34200;
get_seed_result(2, 7, 3) -> 72000;

get_seed_result(1, 8, 3) -> 66300;
get_seed_result(2, 8, 3) -> 74000;

get_seed_result(1, 9, 3) -> 76400;
get_seed_result(2, 9, 3) -> 75200;

get_seed_result(1, 10, 3) -> 131400;
get_seed_result(2, 10, 3) -> 78000;

get_seed_result(1, 11, 3) -> 195200;
get_seed_result(2, 11, 3) -> 80000;

get_seed_result(1, 12, 3) -> 227000;
get_seed_result(2, 12, 3) -> 81200;

get_seed_result(1, 13, 3) -> 277500;
get_seed_result(2, 13, 3) -> 84000;

get_seed_result(1, 14, 3) -> 323600;
get_seed_result(2, 14, 3) -> 85200;

get_seed_result(1, 15, 3) -> 381200;
get_seed_result(2, 15, 3) -> 86400;

get_seed_result(1, 16, 3) -> 439500;
get_seed_result(2, 16, 3) -> 87600;

get_seed_result(1, 17, 3) -> 481400;
get_seed_result(2, 17, 3) -> 88400;

get_seed_result(1, 18, 3) -> 503300;
get_seed_result(2, 18, 3) -> 88800;

get_seed_result(1, 19, 3) -> 525700;
get_seed_result(2, 19, 3) -> 89200;

get_seed_result(1, 20, 3) -> 545900;
get_seed_result(2, 20, 3) -> 89600;

get_seed_result(1, 21, 3) -> 585200;
get_seed_result(2, 21, 3) -> 90000;

get_seed_result(1, 1, 4) -> 14600;
get_seed_result(2, 1, 4) -> 100800;

get_seed_result(1, 2, 4) -> 20900;
get_seed_result(2, 2, 4) -> 124000;

get_seed_result(1, 3, 4) -> 27400;
get_seed_result(2, 3, 4) -> 128800;

get_seed_result(1, 4, 4) -> 30000;
get_seed_result(2, 4, 4) -> 132000;

get_seed_result(1, 5, 4) -> 35300;
get_seed_result(2, 5, 4) -> 136000;

get_seed_result(1, 6, 4) -> 42900;
get_seed_result(2, 6, 4) -> 141600;

get_seed_result(1, 7, 4) -> 51200;
get_seed_result(2, 7, 4) -> 144000;

get_seed_result(1, 8, 4) -> 99500;
get_seed_result(2, 8, 4) -> 148000;

get_seed_result(1, 9, 4) -> 114500;
get_seed_result(2, 9, 4) -> 150400;

get_seed_result(1, 10, 4) -> 197100;
get_seed_result(2, 10, 4) -> 156000;

get_seed_result(1, 11, 4) -> 292800;
get_seed_result(2, 11, 4) -> 160000;

get_seed_result(1, 12, 4) -> 340500;
get_seed_result(2, 12, 4) -> 162400;

get_seed_result(1, 13, 4) -> 416200;
get_seed_result(2, 13, 4) -> 168000;

get_seed_result(1, 14, 4) -> 485300;
get_seed_result(2, 14, 4) -> 170400;

get_seed_result(1, 15, 4) -> 571700;
get_seed_result(2, 15, 4) -> 172800;

get_seed_result(1, 16, 4) -> 659200;
get_seed_result(2, 16, 4) -> 175200;

get_seed_result(1, 17, 4) -> 722000;
get_seed_result(2, 17, 4) -> 176800;

get_seed_result(1, 18, 4) -> 754900;
get_seed_result(2, 18, 4) -> 177600;

get_seed_result(1, 19, 4) -> 788600;
get_seed_result(2, 19, 4) -> 178400;

get_seed_result(1, 20, 4) -> 818900;
get_seed_result(2, 20, 4) -> 179200;

get_seed_result(1, 21, 4) -> 877700;
get_seed_result(2, 21, 4) -> 180000;

get_seed_result(1, 1, 5) -> 19400;
get_seed_result(2, 1, 5) -> 151200;

get_seed_result(1, 2, 5) -> 27800;
get_seed_result(2, 2, 5) -> 186000;

get_seed_result(1, 3, 5) -> 36500;
get_seed_result(2, 3, 5) -> 193200;

get_seed_result(1, 4, 5) -> 40000;
get_seed_result(2, 4, 5) -> 198000;

get_seed_result(1, 5, 5) -> 47100;
get_seed_result(2, 5, 5) -> 204000;

get_seed_result(1, 6, 5) -> 57200;
get_seed_result(2, 6, 5) -> 212400;

get_seed_result(1, 7, 5) -> 68300;
get_seed_result(2, 7, 5) -> 216000;

get_seed_result(1, 8, 5) -> 132600;
get_seed_result(2, 8, 5) -> 222000;

get_seed_result(1, 9, 5) -> 152700;
get_seed_result(2, 9, 5) -> 225600;

get_seed_result(1, 10, 5) -> 262800;
get_seed_result(2, 10, 5) -> 234000;

get_seed_result(1, 11, 5) -> 390400;
get_seed_result(2, 11, 5) -> 240000;

get_seed_result(1, 12, 5) -> 454000;
get_seed_result(2, 12, 5) -> 243600;

get_seed_result(1, 13, 5) -> 554900;
get_seed_result(2, 13, 5) -> 252000;

get_seed_result(1, 14, 5) -> 647100;
get_seed_result(2, 14, 5) -> 255600;

get_seed_result(1, 15, 5) -> 762300;
get_seed_result(2, 15, 5) -> 259200;

get_seed_result(1, 16, 5) -> 878900;
get_seed_result(2, 16, 5) -> 262800;

get_seed_result(1, 17, 5) -> 962700;
get_seed_result(2, 17, 5) -> 265200;

get_seed_result(1, 18, 5) -> 1006500;
get_seed_result(2, 18, 5) -> 266400;

get_seed_result(1, 19, 5) -> 1051400;
get_seed_result(2, 19, 5) -> 267600;

get_seed_result(1, 20, 5) -> 1091800;
get_seed_result(2, 20, 5) -> 268800;

get_seed_result(1, 21, 5) -> 1170300;
get_seed_result(2, 21, 5) -> 270000.


%%================================================
%% 获取奴隶笼子开启的条件：get_open_cage_require(Pos) -> {官职, vip}
get_open_cage_require(1) -> {1, 0};

get_open_cage_require(2) -> {1, 0};

get_open_cage_require(3) -> {15, 0};

get_open_cage_require(4) -> {20, 0};

get_open_cage_require(5) -> {1, 2};

get_open_cage_require(6) -> {1, 3}.


%%================================================
%% get_slave_work_profit(劳作类型, 奴隶等级) -> 收益
get_slave_work_profit(1, 1) -> 1920;
get_slave_work_profit(2, 1) -> 10;
get_slave_work_profit(3, 1) -> 2252;

get_slave_work_profit(1, 2) -> 2040;
get_slave_work_profit(2, 2) -> 10;
get_slave_work_profit(3, 2) -> 2284;

get_slave_work_profit(1, 3) -> 2160;
get_slave_work_profit(2, 3) -> 10;
get_slave_work_profit(3, 3) -> 2317;

get_slave_work_profit(1, 4) -> 2280;
get_slave_work_profit(2, 4) -> 10;
get_slave_work_profit(3, 4) -> 2349;

get_slave_work_profit(1, 5) -> 2400;
get_slave_work_profit(2, 5) -> 10;
get_slave_work_profit(3, 5) -> 2382;

get_slave_work_profit(1, 6) -> 2520;
get_slave_work_profit(2, 6) -> 10;
get_slave_work_profit(3, 6) -> 2414;

get_slave_work_profit(1, 7) -> 2640;
get_slave_work_profit(2, 7) -> 10;
get_slave_work_profit(3, 7) -> 2447;

get_slave_work_profit(1, 8) -> 2760;
get_slave_work_profit(2, 8) -> 10;
get_slave_work_profit(3, 8) -> 2479;

get_slave_work_profit(1, 9) -> 2880;
get_slave_work_profit(2, 9) -> 10;
get_slave_work_profit(3, 9) -> 2512;

get_slave_work_profit(1, 10) -> 3000;
get_slave_work_profit(2, 10) -> 10;
get_slave_work_profit(3, 10) -> 2544;

get_slave_work_profit(1, 11) -> 3120;
get_slave_work_profit(2, 11) -> 10;
get_slave_work_profit(3, 11) -> 2577;

get_slave_work_profit(1, 12) -> 3240;
get_slave_work_profit(2, 12) -> 10;
get_slave_work_profit(3, 12) -> 2609;

get_slave_work_profit(1, 13) -> 3360;
get_slave_work_profit(2, 13) -> 10;
get_slave_work_profit(3, 13) -> 2642;

get_slave_work_profit(1, 14) -> 3480;
get_slave_work_profit(2, 14) -> 10;
get_slave_work_profit(3, 14) -> 2674;

get_slave_work_profit(1, 15) -> 3600;
get_slave_work_profit(2, 15) -> 10;
get_slave_work_profit(3, 15) -> 2707;

get_slave_work_profit(1, 16) -> 3720;
get_slave_work_profit(2, 16) -> 10;
get_slave_work_profit(3, 16) -> 2739;

get_slave_work_profit(1, 17) -> 3840;
get_slave_work_profit(2, 17) -> 10;
get_slave_work_profit(3, 17) -> 2772;

get_slave_work_profit(1, 18) -> 3960;
get_slave_work_profit(2, 18) -> 10;
get_slave_work_profit(3, 18) -> 2804;

get_slave_work_profit(1, 19) -> 4080;
get_slave_work_profit(2, 19) -> 10;
get_slave_work_profit(3, 19) -> 2837;

get_slave_work_profit(1, 20) -> 4200;
get_slave_work_profit(2, 20) -> 10;
get_slave_work_profit(3, 20) -> 2869;

get_slave_work_profit(1, 21) -> 4320;
get_slave_work_profit(2, 21) -> 10;
get_slave_work_profit(3, 21) -> 2902;

get_slave_work_profit(1, 22) -> 4440;
get_slave_work_profit(2, 22) -> 10;
get_slave_work_profit(3, 22) -> 2934;

get_slave_work_profit(1, 23) -> 4560;
get_slave_work_profit(2, 23) -> 10;
get_slave_work_profit(3, 23) -> 2967;

get_slave_work_profit(1, 24) -> 4680;
get_slave_work_profit(2, 24) -> 10;
get_slave_work_profit(3, 24) -> 2999;

get_slave_work_profit(1, 25) -> 4800;
get_slave_work_profit(2, 25) -> 10;
get_slave_work_profit(3, 25) -> 3032;

get_slave_work_profit(1, 26) -> 4920;
get_slave_work_profit(2, 26) -> 10;
get_slave_work_profit(3, 26) -> 3064;

get_slave_work_profit(1, 27) -> 5040;
get_slave_work_profit(2, 27) -> 10;
get_slave_work_profit(3, 27) -> 3097;

get_slave_work_profit(1, 28) -> 5160;
get_slave_work_profit(2, 28) -> 10;
get_slave_work_profit(3, 28) -> 3129;

get_slave_work_profit(1, 29) -> 5280;
get_slave_work_profit(2, 29) -> 10;
get_slave_work_profit(3, 29) -> 3162;

get_slave_work_profit(1, 30) -> 5400;
get_slave_work_profit(2, 30) -> 10;
get_slave_work_profit(3, 30) -> 3195;

get_slave_work_profit(1, 31) -> 5580;
get_slave_work_profit(2, 31) -> 10;
get_slave_work_profit(3, 31) -> 3227;

get_slave_work_profit(1, 32) -> 5760;
get_slave_work_profit(2, 32) -> 10;
get_slave_work_profit(3, 32) -> 3260;

get_slave_work_profit(1, 33) -> 5940;
get_slave_work_profit(2, 33) -> 11;
get_slave_work_profit(3, 33) -> 3293;

get_slave_work_profit(1, 34) -> 6120;
get_slave_work_profit(2, 34) -> 11;
get_slave_work_profit(3, 34) -> 3326;

get_slave_work_profit(1, 35) -> 6300;
get_slave_work_profit(2, 35) -> 11;
get_slave_work_profit(3, 35) -> 3359;

get_slave_work_profit(1, 36) -> 6480;
get_slave_work_profit(2, 36) -> 12;
get_slave_work_profit(3, 36) -> 3393;

get_slave_work_profit(1, 37) -> 6660;
get_slave_work_profit(2, 37) -> 12;
get_slave_work_profit(3, 37) -> 3428;

get_slave_work_profit(1, 38) -> 6840;
get_slave_work_profit(2, 38) -> 12;
get_slave_work_profit(3, 38) -> 3462;

get_slave_work_profit(1, 39) -> 7020;
get_slave_work_profit(2, 39) -> 13;
get_slave_work_profit(3, 39) -> 3497;

get_slave_work_profit(1, 40) -> 7200;
get_slave_work_profit(2, 40) -> 13;
get_slave_work_profit(3, 40) -> 3533;

get_slave_work_profit(1, 41) -> 7380;
get_slave_work_profit(2, 41) -> 13;
get_slave_work_profit(3, 41) -> 3618;

get_slave_work_profit(1, 42) -> 7560;
get_slave_work_profit(2, 42) -> 14;
get_slave_work_profit(3, 42) -> 4182;

get_slave_work_profit(1, 43) -> 7740;
get_slave_work_profit(2, 43) -> 14;
get_slave_work_profit(3, 43) -> 4377;

get_slave_work_profit(1, 44) -> 7920;
get_slave_work_profit(2, 44) -> 14;
get_slave_work_profit(3, 44) -> 4573;

get_slave_work_profit(1, 45) -> 8100;
get_slave_work_profit(2, 45) -> 15;
get_slave_work_profit(3, 45) -> 4902;

get_slave_work_profit(1, 46) -> 8280;
get_slave_work_profit(2, 46) -> 15;
get_slave_work_profit(3, 46) -> 5076;

get_slave_work_profit(1, 47) -> 8460;
get_slave_work_profit(2, 47) -> 15;
get_slave_work_profit(3, 47) -> 5294;

get_slave_work_profit(1, 48) -> 8640;
get_slave_work_profit(2, 48) -> 16;
get_slave_work_profit(3, 48) -> 5512;

get_slave_work_profit(1, 49) -> 8820;
get_slave_work_profit(2, 49) -> 16;
get_slave_work_profit(3, 49) -> 7383;

get_slave_work_profit(1, 50) -> 13500;
get_slave_work_profit(2, 50) -> 16;
get_slave_work_profit(3, 50) -> 9229;

get_slave_work_profit(1, 51) -> 13770;
get_slave_work_profit(2, 51) -> 17;
get_slave_work_profit(3, 51) -> 9352;

get_slave_work_profit(1, 52) -> 14040;
get_slave_work_profit(2, 52) -> 17;
get_slave_work_profit(3, 52) -> 10104;

get_slave_work_profit(1, 53) -> 14310;
get_slave_work_profit(2, 53) -> 17;
get_slave_work_profit(3, 53) -> 11893;

get_slave_work_profit(1, 54) -> 14580;
get_slave_work_profit(2, 54) -> 18;
get_slave_work_profit(3, 54) -> 14442;

get_slave_work_profit(1, 55) -> 14850;
get_slave_work_profit(2, 55) -> 18;
get_slave_work_profit(3, 55) -> 17247;

get_slave_work_profit(1, 56) -> 15120;
get_slave_work_profit(2, 56) -> 18;
get_slave_work_profit(3, 56) -> 20308;

get_slave_work_profit(1, 57) -> 15390;
get_slave_work_profit(2, 57) -> 19;
get_slave_work_profit(3, 57) -> 23624;

get_slave_work_profit(1, 58) -> 15660;
get_slave_work_profit(2, 58) -> 19;
get_slave_work_profit(3, 58) -> 27197;

get_slave_work_profit(1, 59) -> 15930;
get_slave_work_profit(2, 59) -> 19;
get_slave_work_profit(3, 59) -> 31025;

get_slave_work_profit(1, 60) -> 16200;
get_slave_work_profit(2, 60) -> 20;
get_slave_work_profit(3, 60) -> 33449;

get_slave_work_profit(1, 61) -> 16470;
get_slave_work_profit(2, 61) -> 20;
get_slave_work_profit(3, 61) -> 35909;

get_slave_work_profit(1, 62) -> 16740;
get_slave_work_profit(2, 62) -> 20;
get_slave_work_profit(3, 62) -> 37176;

get_slave_work_profit(1, 63) -> 17010;
get_slave_work_profit(2, 63) -> 21;
get_slave_work_profit(3, 63) -> 38527;

get_slave_work_profit(1, 64) -> 17280;
get_slave_work_profit(2, 64) -> 21;
get_slave_work_profit(3, 64) -> 41434;

get_slave_work_profit(1, 65) -> 17550;
get_slave_work_profit(2, 65) -> 21;
get_slave_work_profit(3, 65) -> 44413;

get_slave_work_profit(1, 66) -> 17820;
get_slave_work_profit(2, 66) -> 22;
get_slave_work_profit(3, 66) -> 49150;

get_slave_work_profit(1, 67) -> 18090;
get_slave_work_profit(2, 67) -> 22;
get_slave_work_profit(3, 67) -> 52308;

get_slave_work_profit(1, 68) -> 18360;
get_slave_work_profit(2, 68) -> 22;
get_slave_work_profit(3, 68) -> 55535;

get_slave_work_profit(1, 69) -> 18630;
get_slave_work_profit(2, 69) -> 23;
get_slave_work_profit(3, 69) -> 60784;

get_slave_work_profit(1, 70) -> 18900;
get_slave_work_profit(2, 70) -> 23;
get_slave_work_profit(3, 70) -> 61525;

get_slave_work_profit(1, 71) -> 25560;
get_slave_work_profit(2, 71) -> 23;
get_slave_work_profit(3, 71) -> 61833;

get_slave_work_profit(1, 72) -> 25920;
get_slave_work_profit(2, 72) -> 24;
get_slave_work_profit(3, 72) -> 62017;

get_slave_work_profit(1, 73) -> 26280;
get_slave_work_profit(2, 73) -> 24;
get_slave_work_profit(3, 73) -> 62202;

get_slave_work_profit(1, 74) -> 26640;
get_slave_work_profit(2, 74) -> 24;
get_slave_work_profit(3, 74) -> 62386;

get_slave_work_profit(1, 75) -> 27000;
get_slave_work_profit(2, 75) -> 25;
get_slave_work_profit(3, 75) -> 62571;

get_slave_work_profit(1, 76) -> 27360;
get_slave_work_profit(2, 76) -> 25;
get_slave_work_profit(3, 76) -> 62738;

get_slave_work_profit(1, 77) -> 27720;
get_slave_work_profit(2, 77) -> 25;
get_slave_work_profit(3, 77) -> 65628;

get_slave_work_profit(1, 78) -> 28080;
get_slave_work_profit(2, 78) -> 26;
get_slave_work_profit(3, 78) -> 68583;

get_slave_work_profit(1, 79) -> 28440;
get_slave_work_profit(2, 79) -> 26;
get_slave_work_profit(3, 79) -> 71604;

get_slave_work_profit(1, 80) -> 28800;
get_slave_work_profit(2, 80) -> 26;
get_slave_work_profit(3, 80) -> 74689;

get_slave_work_profit(1, 81) -> 29160;
get_slave_work_profit(2, 81) -> 27;
get_slave_work_profit(3, 81) -> 76076;

get_slave_work_profit(1, 82) -> 29520;
get_slave_work_profit(2, 82) -> 27;
get_slave_work_profit(3, 82) -> 77552;

get_slave_work_profit(1, 83) -> 29880;
get_slave_work_profit(2, 83) -> 27;
get_slave_work_profit(3, 83) -> 79114;

get_slave_work_profit(1, 84) -> 30240;
get_slave_work_profit(2, 84) -> 28;
get_slave_work_profit(3, 84) -> 82405;

get_slave_work_profit(1, 85) -> 30600;
get_slave_work_profit(2, 85) -> 28;
get_slave_work_profit(3, 85) -> 87519;

get_slave_work_profit(1, 86) -> 30960;
get_slave_work_profit(2, 86) -> 28;
get_slave_work_profit(3, 86) -> 90990;

get_slave_work_profit(1, 87) -> 31320;
get_slave_work_profit(2, 87) -> 29;
get_slave_work_profit(3, 87) -> 96421;

get_slave_work_profit(1, 88) -> 31680;
get_slave_work_profit(2, 88) -> 29;
get_slave_work_profit(3, 88) -> 102061;

get_slave_work_profit(1, 89) -> 32040;
get_slave_work_profit(2, 89) -> 29;
get_slave_work_profit(3, 89) -> 107910;

get_slave_work_profit(1, 90) -> 32400;
get_slave_work_profit(2, 90) -> 30;
get_slave_work_profit(3, 90) -> 113968;

get_slave_work_profit(1, 91) -> 32760;
get_slave_work_profit(2, 91) -> 30;
get_slave_work_profit(3, 91) -> 120236;

get_slave_work_profit(1, 92) -> 33120;
get_slave_work_profit(2, 92) -> 30;
get_slave_work_profit(3, 92) -> 126173;

get_slave_work_profit(1, 93) -> 33480;
get_slave_work_profit(2, 93) -> 31;
get_slave_work_profit(3, 93) -> 132303;

get_slave_work_profit(1, 94) -> 33840;
get_slave_work_profit(2, 94) -> 31;
get_slave_work_profit(3, 94) -> 138624;

get_slave_work_profit(1, 95) -> 34200;
get_slave_work_profit(2, 95) -> 31;
get_slave_work_profit(3, 95) -> 145137;

get_slave_work_profit(1, 96) -> 34560;
get_slave_work_profit(2, 96) -> 32;
get_slave_work_profit(3, 96) -> 151841;

get_slave_work_profit(1, 97) -> 34920;
get_slave_work_profit(2, 97) -> 32;
get_slave_work_profit(3, 97) -> 158738;

get_slave_work_profit(1, 98) -> 35280;
get_slave_work_profit(2, 98) -> 32;
get_slave_work_profit(3, 98) -> 165827;

get_slave_work_profit(1, 99) -> 35640;
get_slave_work_profit(2, 99) -> 33;
get_slave_work_profit(3, 99) -> 172190;

get_slave_work_profit(1, 100) -> 36000;
get_slave_work_profit(2, 100) -> 33;
get_slave_work_profit(3, 100) -> 184575.


%%================================================
%% get_watering_profit(等级) -> 每次浇水收益
get_watering_profit(1) -> 80;

get_watering_profit(2) -> 160;

get_watering_profit(3) -> 240;

get_watering_profit(4) -> 320;

get_watering_profit(5) -> 400;

get_watering_profit(6) -> 480;

get_watering_profit(7) -> 560;

get_watering_profit(8) -> 640;

get_watering_profit(9) -> 720;

get_watering_profit(10) -> 800;

get_watering_profit(11) -> 880;

get_watering_profit(12) -> 960;

get_watering_profit(13) -> 1040;

get_watering_profit(14) -> 1120;

get_watering_profit(15) -> 1200;

get_watering_profit(16) -> 1280;

get_watering_profit(17) -> 1360;

get_watering_profit(18) -> 1440;

get_watering_profit(19) -> 1520;

get_watering_profit(20) -> 1600;

get_watering_profit(21) -> 1680;

get_watering_profit(22) -> 1760;

get_watering_profit(23) -> 1840;

get_watering_profit(24) -> 1920;

get_watering_profit(25) -> 2000;

get_watering_profit(26) -> 2080;

get_watering_profit(27) -> 2160;

get_watering_profit(28) -> 2240;

get_watering_profit(29) -> 2320;

get_watering_profit(30) -> 2400;

get_watering_profit(31) -> 2480;

get_watering_profit(32) -> 2560;

get_watering_profit(33) -> 2640;

get_watering_profit(34) -> 2720;

get_watering_profit(35) -> 2800;

get_watering_profit(36) -> 2880;

get_watering_profit(37) -> 2960;

get_watering_profit(38) -> 3040;

get_watering_profit(39) -> 3120;

get_watering_profit(40) -> 3200;

get_watering_profit(41) -> 3280;

get_watering_profit(42) -> 3360;

get_watering_profit(43) -> 3440;

get_watering_profit(44) -> 3520;

get_watering_profit(45) -> 3600;

get_watering_profit(46) -> 3680;

get_watering_profit(47) -> 3760;

get_watering_profit(48) -> 3840;

get_watering_profit(49) -> 3920;

get_watering_profit(50) -> 4000;

get_watering_profit(51) -> 4080;

get_watering_profit(52) -> 4160;

get_watering_profit(53) -> 4240;

get_watering_profit(54) -> 4320;

get_watering_profit(55) -> 4400;

get_watering_profit(56) -> 4480;

get_watering_profit(57) -> 4560;

get_watering_profit(58) -> 4640;

get_watering_profit(59) -> 4720;

get_watering_profit(60) -> 4800;

get_watering_profit(61) -> 4880;

get_watering_profit(62) -> 4960;

get_watering_profit(63) -> 5040;

get_watering_profit(64) -> 5120;

get_watering_profit(65) -> 5200;

get_watering_profit(66) -> 5280;

get_watering_profit(67) -> 5360;

get_watering_profit(68) -> 5440;

get_watering_profit(69) -> 5520;

get_watering_profit(70) -> 5600;

get_watering_profit(71) -> 5680;

get_watering_profit(72) -> 5760;

get_watering_profit(73) -> 5840;

get_watering_profit(74) -> 5920;

get_watering_profit(75) -> 6000;

get_watering_profit(76) -> 6080;

get_watering_profit(77) -> 6160;

get_watering_profit(78) -> 6240;

get_watering_profit(79) -> 6320;

get_watering_profit(80) -> 6400;

get_watering_profit(81) -> 6480;

get_watering_profit(82) -> 6560;

get_watering_profit(83) -> 6640;

get_watering_profit(84) -> 6720;

get_watering_profit(85) -> 6800;

get_watering_profit(86) -> 6880;

get_watering_profit(87) -> 6960;

get_watering_profit(88) -> 7040;

get_watering_profit(89) -> 7120;

get_watering_profit(90) -> 7200;

get_watering_profit(91) -> 7280;

get_watering_profit(92) -> 7360;

get_watering_profit(93) -> 7440;

get_watering_profit(94) -> 7520;

get_watering_profit(95) -> 7600;

get_watering_profit(96) -> 7680;

get_watering_profit(97) -> 7760;

get_watering_profit(98) -> 7840;

get_watering_profit(99) -> 7920;

get_watering_profit(100) -> 8000.


%%================================================
