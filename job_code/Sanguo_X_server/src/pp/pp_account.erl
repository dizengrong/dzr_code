%%%--------------------------------------
%%% @Module  : pp_account
%%% @Email   : dizengrong@gmail.com
%%% @Created : 2011.08.7
%%% @Description:用户账户管理
%%%--------------------------------------
-module(pp_account).

-export([handle/3]).

-include("common.hrl").




%%登陆验证
%% return: 验证成功则为玩家Id， 否则为0
handle(10000, Socket, [Accname, Timestamp, Tick]) ->
	case tick_check(Timestamp, Accname, Tick) of
		ok ->
		    Res = case mod_account:get_account_id_by_name(Accname) of
				{true, Id} 	-> Id;
				false		-> 0
			end,
			if
				Res > 0 -> 
					{ok, BinData} = pt_10:write(10000, [2, Res]);
				Res == 0 ->
					{ok, BinData} = pt_10:write(10000, [1, 0])
			end,
			Res;
		failed -> 
			{ok, BinData} = pt_10:write(10000, [0, 0]),
			Res = 0
	end,
	gen_tcp:send(Socket, BinData),
	Res;

%% 创建角色
%% return： 创建成功则为玩家ID，否则为0
handle(10002, Socket, [AccName, MerId, RoleName])
when is_list(AccName), is_list(RoleName)->
	case mod_account:create_role(AccName, RoleName, MerId) of
		{false, Msg} ->
			{ok, BinData} = pt_10:write(10002, [Msg, 0] ),
			gen_tcp:send(Socket, BinData),
			0;
		{true, Id} 	-> 
			{ok, BinData} = pt_10:write(10002, [0, Id]),
			gen_tcp:send(Socket, BinData),
			%% 记录日志
			Address = util:get_format_ip(Socket),
			mod_user_log:log_user(log_create_role, Id, [AccName, RoleName, MerId, Address]),
			mod_user_log:log_user(log_account_access, Id, [3, AccName, Address, 2]),
			Id
	end;

handle(10004, Id, clear_fcm) ->
	?INFO(login, "player ~w cleared fcm",[Id]),
	mod_account:clear_fcm(Id);

%% TO-DO: 处理心跳包
handle(10005,Id, _Data) ->
	Now = util:unixtime(),
    case get(fcm) of
		0 ->
			%% 发送服务端时间
			send_sever_time(Id, Now);
		1 -> %% 需要防沉迷
			Account = mod_account:get_account_info_rec(Id),
			Player_data = player_db:get_player_data(Id),
			FcmOnlineTime = Now - Account#account.gd_LastLoginTime,
			TotalFcmOnlineTime = Player_data#player_data.gd_fcmOnlineTime + FcmOnlineTime,

			case TotalFcmOnlineTime >= ?MAX_FCM_ONLINE_TIME of
				true -> %% 超过在线时间了
					{ok, Packet1} = pt_10:write(10006, 0),
					lib_send:send(Id, Packet1),
					mod_player:logout_event(Id),
					mod_login:logout_async(Id),
					player_db:update_player_data_elements(Id, Id, [{#player_data.gd_fcmOfflineTime,0}]);
				false ->
					%% 发送服务端时间
					send_sever_time(Id, Now)
			end
	end;

%% 通知客户端账户在别处登陆	
handle(10007, Socket, _R) ->
	{ok, BinData} = pt_10:write(10007, []),
	gen_tcp:send(Socket, BinData);

%% 处理游客登录
handle(10010, Socket, [Timestamp, Tick]) ->
	case tick_check(Timestamp, "", Tick) of 
		ok ->
			case mod_account:create_visitor() of
				{{true, Id, AccName, RoleName}, MerId} ->
					Result = {true, Id, AccName, RoleName},
					%% 记录日志
					Address = util:get_format_ip(Socket),
					mod_user_log:log_user(log_create_role, Id, [AccName, RoleName, MerId, Address]),
					mod_user_log:log_user(log_account_access, Id, [3, AccName, Address, 1]),
					{ok, BinData} = pt_10:write(10000, [2, Id]);
				Other -> 
					Result = Other,
					{ok, BinData} = pt_10:write(10000, [0, 0])
			end;
		failed -> 
			{ok, BinData} = pt_10:write(10000, [0, 0]),
			Result = {false, 0}
	end,
	gen_tcp:send(Socket, BinData),
	Result;


handle(10011, Id, {Accname, RoleName})->
	%%对account模块，更新ets信息
	%%更新数据库信息
	%%对role模块，更新名字信息
	%%其他模块的改名，暂时不做考虑
	%%写log
	case mod_account:visitor_to_player(Id, Accname, RoleName) of
		ok -> %% 更新在ets中的数据成功了
			%% 更新在cache中的数据
			%% 记录日志
			mod_mercenary:change_role_name(Id, RoleName),

			Ip = util:get_format_ip(Id),
			mod_user_log:log_user(log_visitor2player, 
								  Id, 
								  [Accname, RoleName, Ip]),
		
			{ok, Packet} = pt_10:write(10002, [?VISITOR_SUCCESS, Id]),
			lib_send:send(Id, Packet);
		{false, Reason} ->
			User_id = 0, %%协议10002错误时传入  
			{ok, Packet} = pt_10:write(10002, [Reason, User_id] ),
			lib_send:send(Id, Packet)
	end;

handle(10031, PlayerId, _) ->
	PS = mod_player:get_player_status(PlayerId),

	{ok, Packet} = pt_10:write(10031, [0, 0, 0, 0, 0]),
	lib_send:send(PS#player_status.send_pid, Packet).

%% tick 检测
tick_check(Timestamp, Accname, Tick) ->
	ServerKey = util:get_app_env(server_key),
	ServerTick = util:md5(integer_to_list(Timestamp) ++ Accname ++ ServerKey),
	?INFO(?MODULE, "Timestamp: ~w, Accname: ~w, ClientTick: ~s, ServerTick: ~s", 
		  [Timestamp, Accname, Tick, ServerTick]),
	case ServerTick == Tick of
		true -> ok;
		_ ->
			?INFO(account, "tick check failed"), 
			failed
	end.

send_sever_time(Id, Now) ->
	{ok, Packet} = pt_10:write(10005, Now),
	lib_send:send(Id, Packet).
