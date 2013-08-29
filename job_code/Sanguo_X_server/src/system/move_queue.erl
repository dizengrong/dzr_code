%% Author: dzr
%% Created: 2011-12-27
%% Description: TODO: Add description to move_queue
-module(move_queue).

%%=============================================================================
%% Include files
%%=============================================================================
-include("common.hrl").

-define(MAX_QUEUE_SIZE, 10).
-define(PROCESS_NUM, 3).
%%=============================================================================
%% Exported Functions
%%=============================================================================
-export([start/2,
		 stop/1,
		 send_move_msg/2]).
 
%% -export([sender/2]).
 
%%=============================================================================
%% API Functions
%%=============================================================================
start(Socket, SendPid) ->
	process_flag(trap_exit, true),
	Q = queue:new(),
	Now = util:longunixtime(),
	loop(Socket, Q, 0, SendPid, Now).

stop(Mqpid) ->
	Mqpid ! stop.

send_move_msg(Mqpid, Packet) ->
	Mqpid ! Packet.
	
loop(Sock, Q, QSize, SendPid, Timer) ->
	receive
		stop -> ok;
		
		{'EXIT', _From, _Reason} -> ok;
		
		Packet ->
			case QSize < ?MAX_QUEUE_SIZE of
				true -> 
					Q1 = queue:in(Packet, Q),
					NewQ = Q1,
					NewQSize = QSize + 1;
				false ->
					Q1 = queue:drop(Q),
					NewQ = queue:in(Packet, Q1),
					NewQSize = QSize
			end,
			Now = util:longunixtime(),
			if
				Now - Timer > 50 -> %% 大于100毫秒就发送		
					{NewQ1, Msg, Len} = build_msg(NewQ, <<>>, 5, 0),
					lib_send:send(SendPid, Msg),
					NewQSize1 = NewQSize - Len,
					loop(Sock, NewQ1, NewQSize1, SendPid, Now);					
				true ->
					loop(Sock, NewQ, NewQSize, SendPid, Timer)
			end					
	end.

%%=============================================================================
%% Local Functions
%%=============================================================================
build_msg(Q, Msg, 0, OutLen) ->
	{Q, Msg, OutLen};

build_msg(Q, Msg, Len, OutLen) ->
	case queue:out(Q) of
		{{value, MoveMsg}, NQ} ->
			Len1 = Len - 1,
			OutLen1 = OutLen + 1,
			build_msg(NQ, <<Msg/binary, MoveMsg/binary>>, Len1, OutLen1);
		
		{empty, NQ} ->
			{NQ, Msg, OutLen}
	end.
	
