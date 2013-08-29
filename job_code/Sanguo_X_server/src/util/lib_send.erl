%%%-----------------------------------
%%% @Module  : lib_send
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.05.05
%%% @Description: 发送消息
%%%-----------------------------------

%%=============================================================================
%% IMPORTANT:
%%		这里封装了发送数据包的函数，所有要通过tcp socket发送的数据包都应该调用这里的函数来发送。
%%		目前数据包的发送没有实现队列发送模式，不过在将来可能会要分离计算和通信IO，因此会对发送数据包做一些处理，
%%		比如合并数据包一起发送，并设置一起发送数据包的最大长度和发送的最大等待时间等。
%%		注意：包的合并只能是针对同一个玩家的包!
%%=============================================================================
-module(lib_send).

-include("common.hrl").
%% -include("player_record.hrl").

-export([send_by_id/2]).

-export([
         send_direct/2,
         send/2,
         send_after/3,
         send_to_all/1,
		 rpc_send/2,
		 send_to_local_all/1,
%% 		 send_to_local_guild/2,
		 ack_send/2,
		 send_to_uid/2,
		 send_to_nick/2,
%%         send_to_local_all/1,
        send_to_scene/2,
%%         send_to_area_scene/4,
        send_to_guild/2
%%         send_to_team/3,
%%         rand_to_process/1
       ]).

send_by_id(Id,Packet)->
	PS = mod_player:get_player_status(Id),
	?INFO(send,"send to id ~w, pack ~w",[Id,Packet]),
	send(PS#player_status.send_pid,Packet).

%%============================================================
%% 下面的三个发送函数是发送socket包的主要接口，其中参数PlayerSenders是玩家的消息发送进程，
%% 这个是记录在玩家记录的send_pid字段，其函数定义为mod_login:send_msg/2.
%%============================================================

%% 玩家的数据包将进入队列等待发送
send(PlayerSenders, Packet) when is_integer(PlayerSenders)->
	send_by_id(PlayerSenders, Packet);

send(PlayerSenders, Packet) ->
	rand_to_process(PlayerSenders) ! {send, Packet}.
%% 	mod_logger:log_packet(Packet),
%% 	gen_tcp:send(Socket, Packet).

send_direct(PlayerSenders, Packet) when is_integer(PlayerSenders)->
	send_by_id(PlayerSenders, Packet);
%% 直接发送数据包，不进入队列等待发送    
send_direct(PlayerSenders, Packet) ->
	rand_to_process(PlayerSenders) ! {send_direct, Packet}.

%% 玩家的数据包将进入队列等待，并在超时TimeOut到达时发送
send_after(PlayerSenders, Packet, TimeOut) ->
	rand_to_process(PlayerSenders) ! {send_after, Packet, TimeOut}.

%% 应答发送，若发送成功，则返回true， 否则返回false
-spec ack_send(inet:socket(), binary()) -> true | false.
ack_send(Socket, Packet) ->
	case gen_tcp:send(Socket, Packet) of
		ok ->
			true;
		_Other ->
			false
	end.

	
%% 远程的节点调用这个方法来向ID为PlayerId的玩家发送包Packet
%% 由调用者确定玩家PlayerId在该server上，若不在，则忽略
rpc_send(PlayerId, Packet) ->
	case ets:lookup(?ETS_ONLINE, PlayerId) of
		[] ->
			ignore;
		[Player] ->
			lib_send:send(Player#ets_online.send_pid, Packet)
	end.


%% 发送信息给指定玩家名.
%% Nick:名称
%% Bin:二进制数据.
send_to_nick(Nick, Bin) ->
	case mod_account:get_account_id_by_rolename(Nick) of
		false ->
			?DEBUG(send, "Player ~w not online", [Nick]);
		{true, PlayerId} ->
			case ets:lookup(?ETS_ONLINE, PlayerId) of
			[] ->
				?DEBUG(send, "Player ~w not online", [Nick]);
			[Player] ->
				send(Player#ets_online.send_pid, Bin)
			end
	end.

%% 
%% %%发送信息给同线指定玩家ID.
%% %%Uid:玩家ID
%% %%Bin:二进制数据.
%% 返回值说明：
%%           false:对方不在线
%%           true :信息已发送
send_to_uid(PlayerId, Bin) ->
    case ets:lookup(?ETS_ONLINE, PlayerId) of
        [] -> false;
        [Player] -> send(Player#ets_online.send_pid, Bin), true
    end.
%% 
%% %%发送信息到情景
%% %%Q:场景ID
%% %%Bin:数据
 send_to_scene(L, Bin) ->
     do_broadcast(L, Bin).

%%发送信息到帮派
%%Q:帮派ID
%%Bin:数据
send_to_guild(L, Bin) ->
    do_broadcast(L, Bin).

%% %%发送信息到组队
%% %%Sid:游戏逻辑ID
%% %%TeamId:组队ID
%% %%Bin:数据
%% send_to_team(Sid, TeamId, Bin) ->
%%     if (TeamId > 0) ->
%%             L = ets:match(?ETS_ONLINE, #ets_online{sid='$1',  pid_team=TeamId, _='_'}),
%%             do_broadcast(L, Bin);
%%         true ->
%%             send_to_sid(Sid, Bin)
%%     end.
%% 
%% %%发送信息到情景(9宫格区域，不是整个场景)
%% %%Q:场景ID
%% %%X,Y坐标
%% %%Bin:数据
%% send_to_area_scene(Q, X2, Y2, Bin) ->
%%     AllUser = ets:match(?ETS_ONLINE, #ets_online{sid = '$1',x = '$2', y='$3', scene = Q, _='_'}),
%%     XY2 = lib_scene:get_xy(X2, Y2),
%%     F = fun([Sid, X, Y]) ->
%%         XY = lib_scene:get_xy(X, Y),
%%         if
%%             XY == XY2 orelse XY == XY2 + 1 orelse XY == XY2 -1 orelse XY == XY2 -8 orelse XY == XY2 +8 orelse XY == XY2 -9 orelse XY == XY2 +9 orelse XY == XY2 -7  orelse XY == XY2+7 ->
%%                 send_to_sid(Sid, Bin);
%%             true->
%%                 ok
%%         end
%%     end,
%%     [F([Sid, X, Y]) || [Sid, X, Y] <- AllUser].
%% 

%% 发送信息到世界
send_to_all(Bin) ->
    send_to_local_all(Bin).
    % mod_disperse:broadcast_to_world(Bin).

%% 发送给本节点上的所有玩家
send_to_local_all(Bin) ->
	?INFO(send, "lib_send:send_to_local_all called, bin = ~w", [Bin]),
    L = ets:match(?ETS_ONLINE, #ets_online{send_pid='$1', _='_'}),
    do_broadcast(L, Bin).

%% 发送到本节点的公会成员
%% send_to_local_guild(Bin, GuildID) ->
%% 	?INFO(send, "lib_send:send_to_local_guild called, bin = ~w, guild_id = ~w", [Bin, GuildID]),
%% 	MList = lib_guild:get_node_guild_member_list(GuildID, node()),
%% 	GetSendPids = fun(#guild_member{role_id=AccID}, AccList) ->
%% 						  case ets:lookup(?ETS_ONLINE, AccID) of
%% 							  [OnlineEntry] ->
%% 								  #ets_online{send_pid=SendPIDs} = OnlineEntry,
%% 								  [[SendPIDs] | AccList];
%% 							  [] ->
%% 								  AccList
%% 						  end
%% 				  end,
%% 	SenderList = lists:foldl(GetSendPids, [], MList),
%% 	?DEBUG(send, "SenderList = ~w", [SenderList]),
%% 	do_broadcast(SenderList, Bin).

%% 对列表中的所有socket进行广播
do_broadcast(L, Bin) ->
    F = fun([S]) ->
        send(S, Bin),
		?INFO(do_broadcast, "send called in do_broadcast to Player ~w",[S])
    end,
    [F(D) || D <- L].

rand_to_process(S) ->
 	[Sender | _] = S,
 	Sender.
%%     case get(send_num) of
%%     	undefined ->
%%     		put(send_num, 2),
%%     		[S1 | _] = S,
%%     		S1;
%%     	1 ->
%%     		[S1 | _] = S,
%%     		put(send_num, 2),
%%     		S1;
%%     	2 ->
%%     		[_, S2 | _] = S,
%%     		put(send_num, 3),
%%     		S2;
%%     	3 ->
%%     		[_, _, S3] = S,
%%     		put(send_num, 1),
%%     		S3
%%     end.

