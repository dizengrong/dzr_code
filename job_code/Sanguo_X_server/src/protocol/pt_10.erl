%%%-----------------------------------
%%% @Module  : pt_10
%%% @Email   : dizengrong@gmail.com
%%% @Created : 2010.08.7
%%% @Description: 10 帐户信息
%%%-----------------------------------
-module(pt_10).
-export([read/2, write/2]).
-include("common.hrl").
%% -include("economy.hrl").
%% -include("player_record.hrl").
%% -include("scene.hrl").

%%
%%客户端 -> 服务端 ----------------------------
%%

%%登陆
read(10000, BinData) -> 
	{Accname, Rest} = pt:read_string(BinData),
	<<Fcm:8, Timestamp:32, Rest1/binary>> = Rest,
	{Tick, _} = pt:read_string(Rest1),
	?INFO(print,"tick:~w", [Tick]),
    {ok, login, Accname, Fcm, Timestamp, Tick};

%%退出
read(10001, _) ->
    {ok, logout};

%%创建角色
read(10002, <<MerId:16, Bin/binary>>) ->
    {NickName, _} = pt:read_string(Bin),
    {ok, create, [MerId, NickName]};

%% 玩家填写了防沉迷
read(10004, <<_:8>>) ->
    {ok, clear_fcm};

%%进入游戏
read(10003, <<Code:8>>) ->
    {ok, enter, Code};

%% 心跳包
read(10005,<<_Bin/binary>>) ->
	{ok,heartbeat};

%% 新游客登录
read(10010, <<Fcm:8, Timestamp:32, BinData/binary>>) ->
	{Tick, _Rest} = pt:read_string(BinData),
	{ok, new_visitor_enter, Fcm, Timestamp, Tick};

read(10011, Bin) ->
	{Accname, Rest} = pt:read_string(Bin),
	{NickName, _} = pt:read_string(Rest),
	{ok, {Accname, NickName}};


read(10020, _) ->
   {ok, []};

read(10021, _) ->
   {ok, []};

read(10031, _) ->
   {ok, []};

read(10032, _) ->
   {ok, []};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%%登陆返回
write(10000, [Code, Id]) ->
    Data = <<Code:8, Id:32>>,
    {ok, pt:pack(10000, Data)};

%%登陆退出
write(10001, _) ->
    Data = <<>>,
    {ok, pt:pack(10001, Data)};

%%创建角色
write(10002, [Msg, Id]) ->
    Data = <<Msg:8, Id:32>>,
    {ok,  pt:pack(10002, Data)};

%%进入游戏
write(10003, {Account_info,	{Scene, X, Y}, Economy, VipLevel, 
			  AchieveTitle, MainRoleLv, Weiwang,{FCMonlineTime,FCMofflineTime}}) -> 
	
	
    Data = <<(Account_info#account.gd_RoleID):32, 
			 (pt:write_string(Account_info#account.gd_RoleName))/binary, 
			 Scene:16, 
			 X:16, 
			 Y:16,
			 (Economy#economy.gd_gold):32,
			 (Economy#economy.gd_bind_gold):32,
			 (Economy#economy.gd_silver):32,
			 AchieveTitle:8,
			 VipLevel:8,
			 FCMonlineTime:32/unsigned, %% erlang default is unsigned
			 FCMofflineTime:32/unsigned,
			 (Economy#economy.gd_popularity):32,
			 (Economy#economy.gd_totalPopularity):32,
			 (Economy#economy.gd_practice):32,
			 0:32,
			 0:32,
			 0:32,
			 0:32,
			 0:8,
			 Weiwang:8,
			 MainRoleLv:16
			 >>,
    {ok, pt:pack(10003, Data)};


%% 心跳包
write(10005, Now) ->	
   	Data = <<Now:32>>,
   	{ok, pt:pack(10005, Data)};

%% 防沉迷时间已到
write(10006, _) ->	
   	Data = <<0:8>>,
   	{ok, pt:pack(10006, Data)};

%%账号在别处登陆
write(10007, _) ->
    Data = <<>>,
    {ok, pt:pack(10007, Data)};

%% 精力购买服务端返回
write(10020, IsSuccess) ->
    {ok, pt:pack(10020, <<IsSuccess:8>>)};

%% 精力购买服务端返回
write(10021, {Cost, EnergyToBuy}) ->
    {ok, pt:pack(10021, <<Cost:16, EnergyToBuy:8>>)};

write(10031, [RbTimes, TaxTimes, PrayTimes, DTaskTimes, AlchemyTimes]) ->
    {ok, pt:pack(10031, <<RbTimes:8, TaxTimes:8, PrayTimes:8, DTaskTimes:8, AlchemyTimes:8>>)};

write(10999, {Type, ErrCode}) ->
    {ok, pt:pack(10999, <<Type:16, ErrCode:32>>)}.





