-module(data_xunxian).

-compile(export_all).

-include("common.hrl").

%% 寻仙物品：getItemList({仙人位置}, Odds) when Odds =< {几率} -> 物品
getItemList(1, Odds) when Odds =< 360 -> [{297,1}];

getItemList(1, Odds) when Odds =< 420 -> [{92,1}];

getItemList(1, Odds) when Odds =< 480 -> [{102,1}];

getItemList(1, Odds) when Odds =< 540 -> [{112,1}];

getItemList(1, Odds) when Odds =< 600 -> [{122,1}];

getItemList(1, Odds) when Odds =< 660 -> [{132,1}];

getItemList(1, Odds) when Odds =< 720 -> [{142,1}];

getItemList(1, Odds) when Odds =< 780 -> [{152,1}];

getItemList(1, Odds) when Odds =< 840 -> [{162,1}];

getItemList(1, Odds) when Odds =< 900 -> [{172,1}];

getItemList(1, Odds) when Odds =< 1000 -> [{306,1}];

getItemList(2, Odds) when Odds =< 270 -> [{297,1}];

getItemList(2, Odds) when Odds =< 300 -> [{92,1}];

getItemList(2, Odds) when Odds =< 330 -> [{102,1}];

getItemList(2, Odds) when Odds =< 360 -> [{112,1}];

getItemList(2, Odds) when Odds =< 390 -> [{122,1}];

getItemList(2, Odds) when Odds =< 420 -> [{132,1}];

getItemList(2, Odds) when Odds =< 450 -> [{142,1}];

getItemList(2, Odds) when Odds =< 480 -> [{152,1}];

getItemList(2, Odds) when Odds =< 510 -> [{162,1}];

getItemList(2, Odds) when Odds =< 540 -> [{172,1}];

getItemList(2, Odds) when Odds =< 580 -> [{93,1}];

getItemList(2, Odds) when Odds =< 620 -> [{103,1}];

getItemList(2, Odds) when Odds =< 660 -> [{113,1}];

getItemList(2, Odds) when Odds =< 700 -> [{123,1}];

getItemList(2, Odds) when Odds =< 740 -> [{133,1}];

getItemList(2, Odds) when Odds =< 780 -> [{143,1}];

getItemList(2, Odds) when Odds =< 820 -> [{153,1}];

getItemList(2, Odds) when Odds =< 860 -> [{163,1}];

getItemList(2, Odds) when Odds =< 900 -> [{173,1}];

getItemList(2, Odds) when Odds =< 950 -> [{306,1}];

getItemList(2, Odds) when Odds =< 1000 -> [{307,1}];

getItemList(3, Odds) when Odds =< 220 -> [{297,1}];

getItemList(3, Odds) when Odds =< 240 -> [{92,1}];

getItemList(3, Odds) when Odds =< 260 -> [{102,1}];

getItemList(3, Odds) when Odds =< 280 -> [{112,1}];

getItemList(3, Odds) when Odds =< 300 -> [{122,1}];

getItemList(3, Odds) when Odds =< 320 -> [{132,1}];

getItemList(3, Odds) when Odds =< 340 -> [{142,1}];

getItemList(3, Odds) when Odds =< 360 -> [{152,1}];

getItemList(3, Odds) when Odds =< 380 -> [{162,1}];

getItemList(3, Odds) when Odds =< 400 -> [{172,1}];

getItemList(3, Odds) when Odds =< 430 -> [{93,1}];

getItemList(3, Odds) when Odds =< 460 -> [{103,1}];

getItemList(3, Odds) when Odds =< 490 -> [{113,1}];

getItemList(3, Odds) when Odds =< 520 -> [{123,1}];

getItemList(3, Odds) when Odds =< 550 -> [{133,1}];

getItemList(3, Odds) when Odds =< 580 -> [{143,1}];

getItemList(3, Odds) when Odds =< 610 -> [{153,1}];

getItemList(3, Odds) when Odds =< 640 -> [{163,1}];

getItemList(3, Odds) when Odds =< 670 -> [{173,1}];

getItemList(3, Odds) when Odds =< 690 -> [{94,1}];

getItemList(3, Odds) when Odds =< 710 -> [{104,1}];

getItemList(3, Odds) when Odds =< 730 -> [{114,1}];

getItemList(3, Odds) when Odds =< 750 -> [{124,1}];

getItemList(3, Odds) when Odds =< 770 -> [{134,1}];

getItemList(3, Odds) when Odds =< 790 -> [{144,1}];

getItemList(3, Odds) when Odds =< 810 -> [{154,1}];

getItemList(3, Odds) when Odds =< 830 -> [{164,1}];

getItemList(3, Odds) when Odds =< 850 -> [{174,1}];

getItemList(3, Odds) when Odds =< 950 -> [{307,1}];

getItemList(3, Odds) when Odds =< 1000 -> [{308,1}];

getItemList(4, Odds) when Odds =< 40 -> [{93,1}];

getItemList(4, Odds) when Odds =< 80 -> [{103,1}];

getItemList(4, Odds) when Odds =< 120 -> [{113,1}];

getItemList(4, Odds) when Odds =< 160 -> [{123,1}];

getItemList(4, Odds) when Odds =< 200 -> [{133,1}];

getItemList(4, Odds) when Odds =< 240 -> [{143,1}];

getItemList(4, Odds) when Odds =< 280 -> [{153,1}];

getItemList(4, Odds) when Odds =< 320 -> [{163,1}];

getItemList(4, Odds) when Odds =< 360 -> [{173,1}];

getItemList(4, Odds) when Odds =< 400 -> [{94,1}];

getItemList(4, Odds) when Odds =< 440 -> [{104,1}];

getItemList(4, Odds) when Odds =< 480 -> [{114,1}];

getItemList(4, Odds) when Odds =< 520 -> [{124,1}];

getItemList(4, Odds) when Odds =< 560 -> [{134,1}];

getItemList(4, Odds) when Odds =< 600 -> [{144,1}];

getItemList(4, Odds) when Odds =< 640 -> [{154,1}];

getItemList(4, Odds) when Odds =< 680 -> [{164,1}];

getItemList(4, Odds) when Odds =< 720 -> [{174,1}];

getItemList(4, Odds) when Odds =< 740 -> [{95,1}];

getItemList(4, Odds) when Odds =< 760 -> [{105,1}];

getItemList(4, Odds) when Odds =< 780 -> [{115,1}];

getItemList(4, Odds) when Odds =< 800 -> [{125,1}];

getItemList(4, Odds) when Odds =< 820 -> [{135,1}];

getItemList(4, Odds) when Odds =< 840 -> [{145,1}];

getItemList(4, Odds) when Odds =< 860 -> [{155,1}];

getItemList(4, Odds) when Odds =< 880 -> [{165,1}];

getItemList(4, Odds) when Odds =< 900 -> [{175,1}];

getItemList(4, Odds) when Odds =< 950 -> [{308,1}];

getItemList(4, Odds) when Odds =< 1000 -> [{309,1}];

getItemList(5, Odds) when Odds =< 60 -> [{94,1}];

getItemList(5, Odds) when Odds =< 120 -> [{104,1}];

getItemList(5, Odds) when Odds =< 180 -> [{114,1}];

getItemList(5, Odds) when Odds =< 240 -> [{124,1}];

getItemList(5, Odds) when Odds =< 300 -> [{134,1}];

getItemList(5, Odds) when Odds =< 360 -> [{144,1}];

getItemList(5, Odds) when Odds =< 420 -> [{154,1}];

getItemList(5, Odds) when Odds =< 480 -> [{164,1}];

getItemList(5, Odds) when Odds =< 540 -> [{174,1}];

getItemList(5, Odds) when Odds =< 560 -> [{95,1}];

getItemList(5, Odds) when Odds =< 580 -> [{105,1}];

getItemList(5, Odds) when Odds =< 600 -> [{115,1}];

getItemList(5, Odds) when Odds =< 620 -> [{125,1}];

getItemList(5, Odds) when Odds =< 640 -> [{135,1}];

getItemList(5, Odds) when Odds =< 660 -> [{145,1}];

getItemList(5, Odds) when Odds =< 680 -> [{155,1}];

getItemList(5, Odds) when Odds =< 700 -> [{165,1}];

getItemList(5, Odds) when Odds =< 720 -> [{175,1}];

getItemList(5, Odds) when Odds =< 730 -> [{96,1}];

getItemList(5, Odds) when Odds =< 740 -> [{106,1}];

getItemList(5, Odds) when Odds =< 750 -> [{116,1}];

getItemList(5, Odds) when Odds =< 760 -> [{126,1}];

getItemList(5, Odds) when Odds =< 770 -> [{136,1}];

getItemList(5, Odds) when Odds =< 780 -> [{146,1}];

getItemList(5, Odds) when Odds =< 790 -> [{156,1}];

getItemList(5, Odds) when Odds =< 800 -> [{166,1}];

getItemList(5, Odds) when Odds =< 810 -> [{176,1}];

getItemList(5, Odds) when Odds =< 900 -> [{308,1}];

getItemList(5, Odds) when Odds =< 950 -> [{309,1}];

getItemList(5, Odds) when Odds =< 1000 -> [{310,1}].


%%================================================
%% 寻仙银币消耗：getSilverCost({仙人位置}) -> 消耗银币
getSilverCost(1) -> 6000;

getSilverCost(2) -> 10000;

getSilverCost(3) -> 20000;

getSilverCost(4) -> 40000;

getSilverCost(5) -> 80000.


%%================================================
%% 寻仙银币消耗：getRate({仙人位置}) -> 前进概率
getRate(1) -> 60;

getRate(2) -> 50;

getRate(3) -> 30;

getRate(4) -> 20;

getRate(5) -> 0.


%%================================================
