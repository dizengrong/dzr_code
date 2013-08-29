-module(pt_60).

-export([read/2,write/2]).

-include("common.hrl").

%%
%%客户端 -> 服务端 ----------------------------
%%
read(60000, BinData) ->
	%%考虑用RSA加个加密key
    case validate(BinData) of
		true->
			{gm_ok,gm_validate_pass};
		false->
			{error,validate_failed}
	end;

%%踢号
%%MANAGEMENT_KICK				=  60001,		//踢玩家
%%String 玩家名字
read(60001, BinData) ->
	<<AccountID:32>> = BinData,
	{gm_ok,AccountID};

%%踢所有人
%%MANAGEMENT_KICK				=  60002,		//踢玩家
%%byte 0
read(60002, _BinData) ->
	{gm_ok, {}};

%% 公告更新
read(60003, _BinData) ->
	{gm_ok, {}};

%% 删除缓存
read(60004, BinData) ->
	<<AccountID:32>> = BinData,
	{gm_ok,AccountID};

%% gm等身份的称号
read(60005, BinData) -> 
	{Name, <<TitleId:16>>} = pt:read_string(BinData),
	{gm_ok, [Name, TitleId]};
	
%% 禁止登陆 
read(60006, BinData) ->
	<<AccountID:32, ForbiddenTime:32>> = BinData,
	{gm_ok, [AccountID, ForbiddenTime]};
	
%% 解禁登陆 
read(60007, BinData) ->
	<<AccountID:32>> = BinData,
	{gm_ok, [AccountID]};
	
%% 禁言 
read(60008, BinData) ->
	<<AccountID:32, ForbiddenTime:32>> = BinData,
	{gm_ok, [AccountID, ForbiddenTime]};

%% 解除禁言 
read(60009, BinData) ->
	<<AccountID:32>> = BinData,
	{gm_ok, [AccountID]};
	
%% 容错匹配
read(Cmd, BinData) ->
	?ERR(pt_60, "read a error Cmd[~w] with param[~w].\n", [Cmd, BinData]).


%%验证回复
%%MANAGEMENT_LOGIN_REPLY				=  60000,		//登录验证结果
%%byte 结果,0成功，1失败
write(60000,Result)->
	{ok, pt:pack(60000, <<Result:8>>)};

%%踢号回复
%%MANAGEMENT_KICK_REPLY				=  60001,		//踢玩家结果
%%byte:		验证结果		0，踢掉。1-踢不掉
write(60001,Result)->
	{ok, pt:pack(60001, <<Result:8>>)};

%%踢全部号回复
%%MANAGEMENT_KICK_REPLY				=  60001,		//踢玩家结果
%%byte:		验证结果		0，踢掉。1-踢不掉
write(60002,Result)->
	{ok, pt:pack(60002, <<Result:8>>)};

%% 公告更新结果
write(60003, Result) ->
	{ok, pt:pack(60003, <<Result:8>>)};

write(60004, Result) ->
	{ok, pt:pack(60004, <<Result:8>>)};

write(60005, Result) ->
	{ok, pt:pack(60005, <<Result:8>>)};

write(60006, Result) ->
	{ok, pt:pack(60006, <<Result:8>>)};

write(60007, Result) ->
	{ok, pt:pack(60007, <<Result:8>>)};

write(60008, Result) ->
	{ok, pt:pack(60008, <<Result:8>>)};

write(60009, Result) ->
	{ok, pt:pack(60009, <<Result:8>>)};
	
write(Cmd, Result) ->
	?ERR(pt_60, "write Cmd[~w] with Result[~w] which not exist.", [Cmd, Result]).

%% GZ0813(周文波) 10:26:50
%% - - 
%% GZ0813(周文波) 10:28:37
%% $GLOBALS['SY_SOCKET_KEY'] = "09EABCD862FAD64830CCCFFF6123987EFBS";

validate(Bin)->
	?INFO(management,"validate bin is ~w",[Bin]),
	{Passport, Rest} = pt:read_string(Bin),
	{Password, _} = pt:read_string(Rest),
	
	io:format("Passport:~w	Password:~w", [Passport, Password]),
	
	true.