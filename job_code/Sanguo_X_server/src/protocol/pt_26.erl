
%% pt_26 is for yunbiao
-module(pt_26).

%%
%% Include files
%%

-include("common.hrl").

-export([read/2, write/2,write/4]).

%%request yunbiao message (26000)   C->S
read(26000, _Bin)->
	{ok, []};

%%请求吉星信息
read(26001, _Bin)->
	{ok, []};

%%26003 刷新镖车品质
read(26003, _Bin)->
	{ok, []};

%%26004 一键刷新镖车到最高品质
read(26004, _Bin)->
	{ok, []};

%%转运(26005)
read(26005, _Bin)->
	?INFO(yunbiao,"read 26005"),
	{ok, []};

%%开始运镖（26006）
read(26006, Bin)->
	<<NpcId:16>> = Bin,
	{ok, [NpcId]};

read(26007, Bin)->
	<<NpcId:16>> = Bin,
	{ok, [NpcId]};

%% 26008 打劫运镖中的玩家：¶
%% 运镖完成（26008）C->S
%% int32:        正在运镖的玩家的账号ID
read(26008, Bin)->
	<<RobId:32>> = Bin,
	{ok, [RobId]};

%% 26010登陆时请求玩家的运镖状态
%% 玩家登陆时获取跑商状态(26010)C->S
read(26010, _Bin)->
	{ok, []};

%%玩家继续运镖
read(26011, Bin)->
	?INFO(yunbiao,"read 26011, Bin"),
	<<NpcId:16>> = Bin,
	{ok, [NpcId]}.

%%%==================================write==========================
%%%=================================================================


%% 返回运镖基础信息（26000）S->C
%% int8:          当前镖车品质
%% int8:           剩余运镖次数
%% int16:         镖车数
%%     int8:      镖车品质(1-5)
%%     uint32:    价格
%%     int16:     军功
write(26000, Type, Times, BiaocheData)->
	Length = length(BiaocheData),
	?INFO(26000, "Type:~w,Length:~w,Times:~w",[Type,Length,Times]),
	F = fun(Info)->
			[NType, {Price, Jungong}] = Info,
			[<<NType:8, Price:32,Jungong:16>>]
		end,
	Bin = list_to_binary([F(Info) || Info<-BiaocheData]),
	?INFO(yunbiao,"26000,Bin:~w",[Bin]),
	{ok, pt:pack(26000, <<Type:8,Times:8,Length:16,Bin/binary>>)}.
	
%% 返回吉星基础信息（26001）S->C
%% int8:       当前吉星等级
%% int16:      当前吉星加成%
%% int16:      当前运势点
%% int16:      升级到下一级吉星需要的运势点
%% int16:      当前转运需要的元宝

write(26001, {JixingRec, Goldcount}) ->
	?INFO(yunbiao,"jixing_rec:~w",[JixingRec]),
	JixingLevel  = JixingRec#jixing.starLevel,
	Yunshi_point = JixingRec#jixing.yunshi_Point,
	Up_yunshi_point = JixingRec#jixing.up_yunshi_point,
	Need_golds   = Goldcount,
	Add_factor =  JixingRec#jixing.addfactor,
	?INFO(yunbiao,"JixingLevel:~w, Add_factor:~w,Yunshi_point:~w, Up_yunshi_point:~w,Need_golds:~w",
						[JixingLevel, Add_factor,Yunshi_point, Up_yunshi_point,Need_golds]),
	{ok, pt:pack(26001, <<JixingLevel:8, Add_factor:16,Yunshi_point:16, Up_yunshi_point:16,Need_golds:16>>)};

%% 返回镖车品质（26003）S->C
%% int8:       当前镖车品质
write(26003, NewType)->
	{ok, pt:pack(26003, <<NewType:8>>)};
%%开始运镖
write(26006, Type)->
	{ok, pt:pack(26006, <<Type:8>>)};
%% 
%% 运镖完成返回（26007）S->C
%% int8:        1普通   2大卖  3一抢而空...
%% uint32:      获得的银币
%% int16:       获得军功
write(26007, {Type, SilverAmount, JungongAmount})->
	{ok, pt:pack(26007, <<Type:8,SilverAmount:32,JungongAmount:16>>)};

%% 劫镖战斗结束后返回（26008）S->C
%% uint32:      获得的银币
%% int16:       获得的军功
write(26008, {SilverAmount, JungongAmount})->
	?INFO(yunbiao,"rob biao award,silver:~w,jungong:~w",[SilverAmount, JungongAmount]),
	{ok, pt:pack(26008, <<SilverAmount:32,JungongAmount:16>>)};
%% 26009通知玩家被劫¶
%% 通知玩家被劫(26009)S->C
%% int32:      劫镖者的账号ID
%% string:     劫镖者的名字
%% int8:       战斗结果(0劫镖失败，1劫镖胜利)
write(26009, {RobId, Name, Res})->
	BinName = pt:write_string(Name),
	{ok, pt:pack(26009, <<RobId:32,BinName/binary,Res:8>>)};

%% 玩家登陆时获取跑商状态(26010)S->C
%% int8:       是否在运镖  0不是  1是
%% int8:       镖车的品质
%% int8:      剩余运镖次数
write(26010, {State, GemType,YbTimes})->
	{ok, pt:pack(26010, <<State:8,GemType:8,YbTimes:8>>)}.
	