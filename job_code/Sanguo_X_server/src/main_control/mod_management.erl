-module(mod_management).

-export([enabled_gm/0,handle/2
			%setUnableChat/2,getisableChat/1,setableChat/1
		]).
-compile(export_all).
-include("common.hrl").
-define(ACCOUNT_CACHE_REF, cache_util:get_register_name(account)).

enabled_gm()->
	%%根据配置文件,判断是否打开管理接口
	case util:get_app_env(management_enable) of
		true-> true;
		_->
			false
	end.

%% 踢人
handle(60001,{AccountID,Socket})->
	Res = 
	case mod_login:logout_sync(AccountID) of
	{logout, success} -> %% 玩家在线，T 之
		1;
	_ -> %% 其它情况(如玩家不在线)
		2
	end,
	{ok, Bin} = pt_60:write(60001, Res),
	gen_tcp:send(Socket, Bin),
	
	ok;
	
%% 踢该服所有玩家
handle(60002,{{},Socket}) ->
	Res = 
	case mod_login:stop_all() of 
	ok -> %% 成功返回
		1;
	_ -> %% 错误返回
		2
	end,
	{ok, Bin} = pt_60:write(60002, Res),
	gen_tcp:send(Socket, Bin),

	ok;
	
%% 重新加载公告
handle(60003,{{},Socket}) ->
	g_bulletin:reload(),
	
	{ok, Bin} = pt_60:write(60003, 1),
	gen_tcp:send(Socket, Bin),

	ok;
	
%% 删除缓存
handle(60004,{AccountID,Socket})->
	cache_util:remove_all_cache_data(AccountID),
	
	%% 返回成功包
	{ok, Bin} = pt_60:write(60004, 1),
	gen_tcp:send(Socket, Bin),
	
	ok;

%% 禁止登陆
handle(60006, {[AccountID, ForbiddenTime], Socket}) ->
	%% 将玩家T掉
	mod_login:logout_sync(AccountID),
	
	%% 禁止登陆结束时间
	ForbiddenReachTime = util:unixtime() + ForbiddenTime,
	player_db:update_account_elements(AccountID, AccountID, 
										[{#account.gd_Lock, 1},
										{#account.gd_LockLimitTime,ForbiddenReachTime}]),
	%% 返回成功包给客户端
	{ok, Bin} = pt_60:write(60006, 1),
	gen_tcp:send(Socket, Bin),
	
	ok;

%% 解除禁止登陆
handle(60007, {[AccountID], Socket}) ->
	%% 将玩家T掉(理论上现在 ets_online 表中应该没有该玩家的数据，以防万一。。清一下)
	mod_login:logout_sync(AccountID),
	
	%% 取消禁止登陆
	player_db:update_account_elements(AccountID, AccountID, 
										[{#account.gd_Lock, 0},
										{#account.gd_LockLimitTime,0}]),
	%% 返回成功包给客户端
	{ok, Bin} = pt_60:write(60007, 1),
	gen_tcp:send(Socket, Bin),
	
	ok;

%% 禁言
handle(60008, {[AccountID, ForbiddenTime], Socket}) ->
	setUnableChat(AccountID, ForbiddenTime),
	
	%% 返回成功包给客户端
	{ok, Bin} = pt_60:write(60008, 1),
	gen_tcp:send(Socket, Bin),
	
	ok;
	
%% 解除禁言
handle(60009, {[AccountID], Socket}) ->
	setableChat(AccountID),
	
	%% 返回成功包给客户端
	{ok, Bin} = pt_60:write(60009, 1),
	gen_tcp:send(Socket, Bin),
	
	ok; 
	
handle(OtherCmd, _CmdParam) ->
	?ERR(manage, "mod_managemnet recieve a error cmd[~w] which has param[~w].\n", [OtherCmd, _CmdParam]),
	err.


setUnableChat(PlayerId,Time)->
	?INFO(management,"set the unable chat,PlayerId is ~w, Time is ~w",[PlayerId, Time]),
	gen_cache:update_element(?ACCOUNT_CACHE_REF, PlayerId, [{#account.gd_ChatLock, 1},{#account.gd_chatLockTime, util:unixtime()+Time}]).

getisableChat(PlayerId)->
	case gen_cache:lookup(?ACCOUNT_CACHE_REF, PlayerId) of
		[]->
			?INFO(management,"can not get the player: ~w's info",[PlayerId]),
			false;
		[AcountRec]->
			%% 锁时间比当前时间早就能聊天
			case is_integer(AcountRec#account.gd_chatLockTime) of
				true->(AcountRec#account.gd_chatLockTime) < util:unixtime();
				false -> true
			end
	end.
setableChat(PlayerId)->
	?INFO(management,"set the able chat,PlayerId is ~w",[PlayerId]),
	gen_cache:update_element(?ACCOUNT_CACHE_REF, PlayerId, [{#account.gd_ChatLock, 0},{#account.gd_chatLockTime, 0}]).