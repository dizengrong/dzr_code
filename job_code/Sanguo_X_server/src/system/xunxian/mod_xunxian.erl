%%寻仙系统
%%e-mail:laojiajie@4399.net
-module(mod_xunxian).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
% %% --------------------------------------------------------------------
-include("common.hrl").

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/1]).

-export(
   [
   	initXunxian/1,
	getXunxianInfo/1,
	getItemList/1,
	smelt/1,
	onekeySmelt/2,
	pickOne/2,
	pickAll/1,
	sellOne/2,
	sellAll/1,
	getFreeTimes/1,
	lock/1
	% smelt_for_pet/3
   ]
).


start_link(AccountID) ->
	gen_server:start_link(?MODULE, [AccountID], []).

init([AccountID]) ->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, AccountID),
	mod_player:update_module_pid(AccountID, ?MODULE, self()),
    {ok, null}.

initXunxian(AccountID) ->
	cache_xunxian:init(AccountID),
	ok.
%% ====================================================================
%% External functions
%% ====================================================================

%% 获取玩家寻仙初始化信息(pt:12100)
-spec getXunxianInfo(integer()) -> ok.
getXunxianInfo(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.xunxian_pid, {getXunxianInfo, AccountID}).

%% 获取玩家寻仙物品信息
-spec getItemList(integer()) -> ok.
getItemList(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.xunxian_pid, {getItemList, AccountID}). 

%% 获取当天的剩余炼金次数
getFreeTimes(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.xunxian_pid, {getFreeTimes, AccountID}).

%% 按照级别进行寻仙操作(pt:12101)
-spec smelt(integer()) -> {fail, integer()} | {ok, #player_status{}}.
smelt(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.xunxian_pid, {smelt, AccountID}). 

%% 一键寻仙
-spec onekeySmelt(integer(),integer()) -> {ok, #player_status{}}.
onekeySmelt(AccountID,Silver) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.xunxian_pid, {onekeySmelt,AccountID,Silver}).

%% 拾起一个炼金物品
-spec pickOne(integer(), integer()) -> {fail, integer()} | ok.
pickOne(AccountID, ItemPos) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.xunxian_pid, {pickOne, AccountID, ItemPos}).

%% 出售一个炼金物品
-spec sellOne(integer(), integer()) -> {fail, integer()} | {ok, #player_status{}}.
sellOne(AccountID, ItemPos) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.xunxian_pid, 
					{sellOne, AccountID, ItemPos}).

%% 拾起所有炼金物品
-spec pickAll(integer()) -> {fail, integer()} | ok.
pickAll(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.xunxian_pid, {pickAll, AccountID}).

%% 
-spec lock(integer()) -> {fail, integer()} | ok.
lock(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.xunxian_pid, {lock, AccountID}).

%% 卖掉所有炼金物品
-spec sellAll(integer()) -> {fail, integer()} | {ok, #player_status{}}.
sellAll(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.xunxian_pid, {sellAll, AccountID}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 获取玩家寻仙初始化信息(pt:12100)
handle_cast({getXunxianInfo, AccountID}, State) ->
	{ok, NewXunxianInfo} = lib_xunxian:setXunxianInfo(AccountID),
	{ok, BinData} = pt_12:write(12100, {NewXunxianInfo, 0}),
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 获取玩家寻仙物品列表
handle_cast({getItemList, AccountID}, State) ->
	{ok, XunxianInfo} = lib_xunxian:getXunxianInfo(AccountID),
	?INFO(xunxian, "XunxianInfo:[~w]", [XunxianInfo]),
	ItemList = XunxianInfo#xunxian.gd_ItemList,
	{ok, BinData} = pt_12:write(12102, ItemList),
	?INFO(xunxian, "send_data:[~w]", [BinData]),
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 获取当天的剩余免费次数
handle_cast({getFreeTimes, AccountID}, State) ->
	{ok, XunxianInfo} = lib_xunxian:getXunxianInfo(AccountID),
	?INFO(xunxian, "XunxianInfo:[~w]", [XunxianInfo]),
	FreeTimes = XunxianInfo#xunxian.gd_FreeTimes,
	{ok,BinData} = pt_12:write(12102,FreeTimes),
	?INFO(xunxian, "send_data:[~w]", [BinData]),
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 寻仙一次
handle_cast({smelt, AccountID}, State) ->
	case check_xunxian:smelt(AccountID) of
		{fail,ErrCode} ->
			?INFO(xunxian, "ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode});
		{ok,XunxianInfo,SilverCost} ->
			{ok,NewXunxianInfo} = lib_xunxian:smelt(XunxianInfo,SilverCost),
			{ok,BinData} = pt_12:write(12100, {NewXunxianInfo, 1}),
			?INFO(xunxian, "send_data:[~w]", [BinData])
	end,
	lib_send:send(AccountID,BinData),
	{noreply, State};


%% 一键寻仙
%%	Silver =:=0 时，是一键炼金，根据玩家总银币作是否足够的判断；
%%	Silver不为0时，为前端的自动寻仙逻辑，根据传递过来的用户设置的剩余银币来作判断。
handle_cast({onekeySmelt,AccountID,Silver}, State) ->
	case check_xunxian:onekeySmelt(AccountID,Silver) of
		{fail, ErrCode} ->
			?INFO(xunxian, "ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode});
		{ok, XunxianInfo, PosList, LastPos, SilverCost, IsSilverEnough} ->
			{ok, NewItemList,IsBagEnough} = lib_xunxian:onekeySmelt(XunxianInfo,PosList, LastPos, SilverCost),
			{ok, BinData} = pt_12:write(12104,{PosList, NewItemList, LastPos, IsSilverEnough,IsBagEnough}),
			?INFO(xunxian, "send_data:[~w]",[BinData])
	end,
	lib_send:send(AccountID, BinData),
	{noreply, State};


%% 捡起一个物品
handle_cast({pickOne, AccountID, ItemPos}, State) ->
	case check_xunxian:pickOne(AccountID, ItemPos) of
		{fail,ErrCode} ->
			?INFO(xunxian, "ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode});
		{ok,XunxianInfo, CfgItemID, BindInfo} ->
			{ok,NewXunxianInfo} = lib_xunxian:pickOne(XunxianInfo, AccountID, CfgItemID, BindInfo, ItemPos),
			{ok,BinData} = pt_12:write(12100,{NewXunxianInfo, 2}),
			?INFO(xunxian, "send_data:[~w]", [BinData])
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};


%% 出售一个物品
handle_cast({sellOne, AccountID, ItemPos}, State) ->
	case check_xunxian:sellOne(AccountID, ItemPos) of
		{fail,ErrCode} ->
			?INFO(xunxian, "ErrCode = [~w]",[ErrCode]),
			{ok,BinData} = pt_10:write(10999,{0,ErrCode});
		{ok,XunxianInfo, CfgItemID} ->
			{ok, NewXunxianInfo}=lib_xunxian:sellOne(XunxianInfo, AccountID, CfgItemID, ItemPos),
			{ok,BinData} = pt_12:write(12100,{NewXunxianInfo, 3}),
			?INFO(xunxian, "send_data:[~w]", [BinData])
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 拾起所有物品
handle_cast({pickAll, AccountID},State) ->
	case check_xunxian:pickAll(AccountID) of
		{fail,ErrCode} ->
			?INFO(xunxian, "ErrCode = [~w]",[ErrCode]),
			{ok, BinData} = pt_10:write(10999,{0,ErrCode});
		{ok,XunxianInfo} ->
			{ok, NewXunxianInfo} = lib_xunxian:pickAll(XunxianInfo, AccountID),
			{ok,BinData} = pt_12:write(12100,{NewXunxianInfo, 5}),
			?INFO(xunxian, "send_data:[~w]", [BinData])
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 卖掉所有物品
handle_cast({sellAll, AccountID},State) ->
	case check_xunxian:sellAll(AccountID) of
		{fail,ErrCode} ->
			?INFO(xunxian, "ErrCode = [~w]",[ErrCode]),
			{ok, BinData} = pt_10:write(10999,{0,ErrCode});
		{ok,XunxianInfo} ->
			{ok, NewXunxianInfo} = lib_xunxian:sellAll(XunxianInfo, AccountID),
			{ok, BinData} = pt_12:write(12100,{NewXunxianInfo, 6}),
			?INFO(xunxian, "send_data:[~w]", [BinData])
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 锁定最高仙人
handle_cast({lock,AccountID},State) ->
	case check_xunxian:lock(AccountID) of
		{fail,ErrCode} ->
			?INFO(xunxian, "ErrCode = [~w]",[ErrCode]),
			{ok, BinData} = pt_10:write(10999,{0,ErrCode});
		{ok,XunxianInfo,GoldCost} ->
			{ok, NewXunxianInfo} = lib_xunxian:lock(XunxianInfo, AccountID, GoldCost),
			{ok, BinData} = pt_12:write(12100,{NewXunxianInfo, 7}),
			?INFO(xunxian, "send_data:[~w]", [BinData])
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};

handle_cast(_Request, State) ->
    {noreply,State}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.





