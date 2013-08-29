%%%---------------------------------------
%%% @Module  : data_vip
%%% @Author  : cjr
%%% @Email   : chenjianrong@4399.com
%%% @Created : 2011-10-31
%%% @Description:  
%%%---------------------------------------


-module(data_vip).

-export([get_vip_level_by_gold/1,
		 get_day_card_price/1,
		get_week_card_price/1,
		get_extra_employable/1]).

%% vip等级	日卡价格	周卡价格	上限	下限	作用1	作用2	作用3	作用4	作用5
%% 1	9	59	99	1	1.24小时的训练模式	2.跑商刷新矿石	0	0	0
%% 2	19	119	1999	100	1.每日任务可用金券或金币刷新	2.高级训练模式,训练获得的经验为普通的150%	VIP1的功能	0	0
%% 3	39	239	4999	2000	1.可固定强化成功率为100%	2.白金培养属性,更容易培养高属性	3.72小时的训练模式	4.白金训练模式,训练获得经验为普通的180%	VIP1~2的所有功能
%% 4	0	0	19999	5000	1.强化装备会产生越级	2.可购买精力	3.开通第4个训练位置	4.可购买1条圣痕队列	VIP1~3的所有功能
%% 5	0	0	49999	20000	1.至尊培养功能,成功率更高	2.可快速完成每日任务	3.可招募佣兵位置增加1	4.黄金训练模式,训练获得经验为210%	VIP1~4的所有功能
%% 6	0	0	99999	50000	1.可招募佣兵增加2	2.可购买2条圣痕队列	3.开通第5个训练位置	VIP1~5的所有功能	0
%% 7	0	0	0	100000	1.可使用金币突飞	2.开通第6个训练位置	3.至尊训练模式,训练获得经验为240%	VIP1~6的所有功能	0

get_vip_level_by_gold(Gold) when Gold == 0->
	0;


get_vip_level_by_gold(Gold) when Gold =< 100->
	1;

get_vip_level_by_gold(Gold) when Gold =< 500->
	2;

get_vip_level_by_gold(Gold) when Gold =< 2000->
	3;

get_vip_level_by_gold(Gold) when Gold =< 5000->
	4;

get_vip_level_by_gold(Gold) when Gold =< 10000->
	5;

get_vip_level_by_gold(Gold) when Gold =< 20000->
	6;

get_vip_level_by_gold(_Gold) ->
	7.

%% VIP卡等级	日卡	周卡
%% 1	9金币	59金币
%% 2	19金币	119金币
%% 3	39金币	239金币

get_day_card_price(0)->
	0;

get_day_card_price(1)->
	9;

get_day_card_price(2)->
	19;

get_day_card_price(3)->
	39;

get_day_card_price(_Other)->
	0.

get_week_card_price(0)->
	0;

get_week_card_price(1)->
	59;

get_week_card_price(2)->
	119;

get_week_card_price(3)->
	239;

get_week_card_price(_Other)->
	0.

%% 根据vip等级获取额外可以多招募的佣兵数	
get_extra_employable(VipLevel) when VipLevel >= 6 -> 2 + 5;
get_extra_employable(VipLevel) when VipLevel >= 5 -> 1 + 5;
get_extra_employable(_VipLevel) -> 0 + 5.