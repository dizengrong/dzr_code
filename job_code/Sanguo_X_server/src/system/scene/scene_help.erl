%% Author: dzr
%% Created: 2011-11-29
%% Description: TODO: Add description to scene_help
-module(scene_help).

%%=============================================================================
%% Include files
%%=============================================================================
-include("common.hrl").
%%=============================================================================
%% Exported Functions
%%=============================================================================
-export([
		 get_leave_and_enter_cells/4,
		 broadcast_update/5,
		 broadcast_leave/4,
		 broadcast_enter/4,
		 broadcast_move/4,
		 broadcast_move_check/4,
		 broadcast_monster_state/2,
		 get_move_broadcast_cell/3
		 ]).

%% broadcast player move
%% parameter: SelfId is needed to be filtered
broadcast_move({C, R, CellNum}, MoveMsg, TabName, SelfId) ->
	Fun = fun(Cell, Acc) ->
		case ets:match(TabName, #player_cell{cell = Cell,  move_queue_pid = '$1', player_id = '$2', _ = '_'}) of
			[] -> Acc;
			Matched -> lists:append(Acc, Matched)
		end
	end,
	CellList = get_move_broadcast_cell(CellNum, C, R),
	Acc = lists:foldl(Fun, [], CellList),
	Size = length(Acc),
	case Size > 64 of
		false -> 
			broadcast_move_help(Acc, MoveMsg, SelfId);
		_ ->
			broadcast_move_help2(Acc, MoveMsg, SelfId)
	end.

%% 	case ets:select(TabName, [{#player_cell{cell = '$1', _ = '_'}, [{'==', '$1', Cell}], [] }], 6) of
%% 		'$end_of_table' -> ok;
%% 		{Players, _Continuation} ->
%% 			broadcast_move_help(Players, MoveMsg, SelfId)
%% 	end.

broadcast_move_help([], _, _) -> ok;

broadcast_move_help([[_MoveQueuePid, SelfId | _] | Rest], MoveMsg, SelfId) ->
	broadcast_move_help(Rest, MoveMsg, SelfId);

broadcast_move_help([[MoveQueuePid, _ | _] | Rest], MoveMsg, SelfId) ->	
%% 	lib_send:send(MoveQueuePid, MoveMsg),
	move_queue:send_move_msg(MoveQueuePid, MoveMsg),
	broadcast_move_help(Rest, MoveMsg, SelfId).
%% 	case Player#player_cell.player_id == SelfId of
%% 		true ->
%% 			broadcast_move_help(Rest, MoveMsg, SelfId);
%% 		false ->
%% 			lib_send:send(Player#player_cell.send_pid, MoveMsg),
%% 			?INFO(scene_help, "broadcast_move to ~w : ~w ", [Player#player_cell.player_id, MoveMsg]),
%% 			broadcast_move_help(Rest, MoveMsg, SelfId)
%% 	end.

%% PlayerSenderList的长度大于64，则将PlayerSenderList尽量平均的分成4段，每段16个
%% 然后从每段中取出前面的16个元素，在进行广播
broadcast_move_help2(PlayerSenderList, MoveMsg, _SelfId) ->
	Size = length(PlayerSenderList),
	Len = 4,
	PartitionNum = Size div Len,
	{L11, L12} = lists:split(PartitionNum, PlayerSenderList),
	broadcast_move_help3(L11, MoveMsg, PartitionNum, 0),
	{L21, L22} = lists:split(PartitionNum, L12),
	broadcast_move_help3(L21, MoveMsg, PartitionNum, 0),
	{L31, L32} = lists:split(PartitionNum, L22),
	broadcast_move_help3(L31, MoveMsg, PartitionNum, 0),
	{L41, _L42} = lists:split(PartitionNum, L32),
	broadcast_move_help3(L41, MoveMsg, PartitionNum, 0),
	ok.

broadcast_move_help3(_, _, PartitionNum, Total) when Total >= PartitionNum -> ok;
broadcast_move_help3([[MoveQueuePid | _] | Rest], MoveMsg, PartitionNum, Total) ->
%% 	lib_send:send(MoveQueuePid, MoveMsg),
	move_queue:send_move_msg(MoveQueuePid, MoveMsg),
	broadcast_move_help3(Rest, MoveMsg, PartitionNum, Total + 1).
	
%% 处理哪些其他玩家离开了移动玩家的视野，哪些其他玩家又进入了移动玩家的视野了
broadcast_move_check(NewPlayerLoc, TabName, LeaveCells, EnterCells) ->
	{ok, LeaveMsg} = pt_11:write(11002, [NewPlayerLoc#player_cell.player_id]),
	{ok, EnterMsg} = pt_11:write(11001, [NewPlayerLoc]),
	%% process which cells out of player's view
	[broadcast_leave(Cell1, NewPlayerLoc, LeaveMsg, TabName) || Cell1 <- LeaveCells],
	
	%% process which new cells in player's view
	[broadcast_enter(Cell2, NewPlayerLoc, EnterMsg, TabName) || Cell2 <- EnterCells],
	ok.

broadcast_update([], _Packet, _TabName, _FilterId, _FilterSelf) -> ok;
broadcast_update([Cell | Rest], Packet, TabName, FilterId, FilterSelf) ->
	Players = ets:match(TabName, #player_cell{cell = Cell, player_id = '$1', send_pid = '$2', _ = '_'}),
	broadcast_update_help(Players, Packet, FilterId, FilterSelf),
	broadcast_update(Rest, Packet, TabName, FilterId, FilterSelf).
%% 	case ets:match_object(TabName, #player_cell{cell = Cell, _ = '_'}) of
%% 		[] ->
%% 			none;		
%% 		Players ->
%% 			broadcast_update_help(Players, Packet, FilterId),
%% 			broadcast_update(Rest, Packet, TabName, FilterId)
%% 	end.

broadcast_update_help([], _Packet, _FilterId, _FilterSelf) -> ok;
broadcast_update_help([[PlayerId, Sender | _] | Rest], Packet, FilterId, FilterSelf) ->
	case PlayerId == FilterId andalso FilterSelf == true of
		true -> 
			broadcast_update_help(Rest, Packet, FilterId, FilterSelf);
		_ ->
			lib_send:send(Sender, Packet),
			broadcast_update_help(Rest, Packet, FilterId, FilterSelf)
	end.

broadcast_monster_state([], _Packet) -> ok;
broadcast_monster_state([SendPid | Rest], Packet) ->
	[SendPid1 | _] = SendPid,
	lib_send:send(SendPid1, Packet),
	broadcast_monster_state(Rest, Packet).



%% ================================================================
%% 					LOCAL FUNCTION
%% ================================================================


%% broadcast player enter to the players in cellnum
%% parameter Cell is the cell which other can see player enter
%% 想位于格子Cell中的玩家广播一个玩家PlayerLoc的进入
broadcast_enter(Cell, PlayerLoc, EnterMsg, TabName) ->
	PlayerSelfId = PlayerLoc#player_cell.player_id,
	%% TODO: put the player's id into the match pattern.
	case ets:match_object(TabName, #player_cell{cell = Cell, _ = '_'}) of
		[] -> 
			?INFO(scene, "no one in the cell ~w", [Cell]),
			none;		
		Players ->
			?INFO(scene,"broadcast_enter-Players: ~w", [Players]),
			%% 把其他玩家的进入和路径（如果有的话）发给自己
			Filter = fun(PlayerLocRec) -> PlayerSelfId /= PlayerLocRec#player_cell.player_id end,
			Players1 = lists:filter(Filter, Players),
			case Players1 of
				[] -> ok;
				_ ->
					{ok, OthersPacket} = pt_11:write(11001, Players1),
					lib_send:send(PlayerLoc#player_cell.send_pid, OthersPacket)
			end,
			%% 把自己进入的消息发送给其他玩家
			Fun2 = fun(Sender) -> lib_send:send(Sender, EnterMsg) end,
			[Fun2(SenderPid) || #player_cell{send_pid = SenderPid} <- Players1]
	end.

%% broadcast player leave to the players in cellnum
%% 向位于格子CellNum的玩家广播PlayerLoc的离开
broadcast_leave(CellNum, PlayerLoc, LeaveMsg, TabName) ->
	Result = ets:match(TabName, #player_cell{cell = CellNum, player_id = '$1', send_pid = '$2', _ = '_'}),
	case Result of
		[] ->
			none;
		_ ->
			IdList = [PlayerId || [PlayerId, _SenderPid] <- Result],

			?INFO(scene,"broadcast_leave: ~w leave", [Result]),
			{ok, ViewOutPlayersMsg} = pt_11:write(11002, IdList),
			lib_send:send(PlayerLoc#player_cell.send_pid, ViewOutPlayersMsg),
			[lib_send:send(SenderPid, LeaveMsg) || [_Id, SenderPid] <- Result]
	end.

get_leave_and_enter_cells(OldCell, NewCell, C, R) ->
	%?ERR(scene, "OldCell = ~w, NewCell = ~w", [OldCell, NewCell]),
	if
		OldCell == NewCell ->			%% the same cell
			[];
		OldCell + 1 == NewCell ->		%% move to right cell
			if
				(NewCell rem C) == 0 ->  %% 位于最右边
					if
						NewCell == C -> %% 位于最右边的右上角(NewCell位于最后一列)
							LeaveCells = [OldCell - 1, OldCell - 1 + C],
							EnterCells = [],
							{LeaveCells, EnterCells};
						NewCell == C * R -> %% 位于最右边的右下角
							LeaveCells = [OldCell - 1, OldCell - 1 - C],
							EnterCells = [],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell - 1, OldCell - 1 - C, OldCell - 1 + C],
							EnterCells = [],
							{LeaveCells, EnterCells}
					end;
				(OldCell-1) rem C == 0 -> %% OldCell位于第一列
					if
						OldCell == 1 -> %% 位于第一个格子
							LeaveCells = [],
							EnterCells = [NewCell + 1, NewCell + 1 + C],
							{LeaveCells, EnterCells};
						OldCell == (R- 1) * C + 1 -> %% 位于第一列的最后一个格子
							LeaveCells = [],
							EnterCells = [NewCell + 1, NewCell + 1 - C],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [],
							EnterCells = [NewCell + 1, NewCell + 1 - C, NewCell + 1 + C],
							{LeaveCells, EnterCells}
					end;
				true ->
					if
						NewCell < C ->
							LeaveCells = [OldCell - 1, OldCell - 1 + C],
							EnterCells = [NewCell + 1, NewCell + 1 + C],
							{LeaveCells, EnterCells};
						NewCell > C * (R - 1) ->
							LeaveCells = [OldCell - 1, OldCell - 1 - C],
							EnterCells = [NewCell + 1, NewCell + 1 - C],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell - 1, OldCell - 1 - C, OldCell - 1 + C],
							EnterCells = [NewCell + 1, NewCell + 1 + C, NewCell + 1 -C],
							{LeaveCells, EnterCells}
					end
			end;
		OldCell + 1 - C == NewCell ->	%% move ot right top cell
			if 
				NewCell < C ->
					if
						NewCell == 2 ->
							LeaveCells = [OldCell + C, OldCell + 1 + C],
							EnterCells = [NewCell + 1, NewCell + 1 + C],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell - 1, OldCell - 1 - C, OldCell - 1 + C, OldCell + C, OldCell + 1 + C],
							EnterCells = [NewCell + 1, NewCell + 1 + C],
							{LeaveCells, EnterCells}
					end;
				(NewCell rem C) == 0 ->
					if
						NewCell == C ->
							LeaveCells = [OldCell - 1, OldCell - 1 - C, OldCell - 1 + C, OldCell + C, OldCell + 1 + C],
							EnterCells = [],
							{LeaveCells, EnterCells};
						NewCell == C * (R - 1) ->
							LeaveCells = [OldCell - 1, OldCell - 1 - C],
							EnterCells = [NewCell - C, NewCell - 1 - C],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell - 1, OldCell - 1 - C, OldCell - 1 + C, OldCell + C, OldCell + 1 + C],
							EnterCells = [NewCell - C, NewCell - 1 - C],
							{LeaveCells, EnterCells}
					end;
				true ->
					LeaveCells = [OldCell - 1, OldCell - 1 - C, OldCell - 1 + C, OldCell + C, OldCell + 1 + C],
					EnterCells = [NewCell + 1, NewCell + 1 + C, NewCell + 1 -C, NewCell - C, NewCell - 1 - C],
					{LeaveCells, EnterCells}
			end;
		OldCell + 1 + C == NewCell ->	%% move to right down cell 
			if
				OldCell < C ->
					if
						OldCell == 1 ->
							LeaveCells =  [],
							EnterCells = [NewCell + 1, NewCell + 1 + C, NewCell + 1 -C, NewCell + C, NewCell - 1 + C],
							{LeaveCells, EnterCells};
						OldCell + 1 == C ->
							LeaveCells = [OldCell - 1, OldCell - 1 + C],
							EnterCells = [NewCell + C, NewCell - 1 + C],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell - 1, OldCell - 1 + C],
							EnterCells = [NewCell + 1, NewCell + 1 + C, NewCell + 1 -C, NewCell + C, NewCell - 1 + C],
							{LeaveCells, EnterCells}
					end;
				(OldCell - 1) rem C == 0 ->
					if
						OldCell == (R - 2) * C + 1 ->
							LeaveCells = [OldCell - C, OldCell + 1 - C],
							EnterCells = [NewCell + 1, NewCell + 1 -C],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell - C, OldCell + 1 - C],
							EnterCells = [NewCell + 1, NewCell + 1 + C, NewCell + 1 -C, NewCell +C, NewCell - 1 + C],
							{LeaveCells, EnterCells}
					end;
				NewCell > (R - 1) * C ->
					if
						NewCell == R * C ->
							LeaveCells = [OldCell - 1, OldCell - 1 - C, OldCell - 1 + C, OldCell - C, OldCell + 1 - C],
							EnterCells = [],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell - 1, OldCell - 1 - C, OldCell - 1 + C, OldCell - C, OldCell + 1 - C],
							EnterCells = [NewCell + 1, NewCell + 1 -C],
							{LeaveCells, EnterCells}
					end;
				(NewCell rem C) == 0 ->
					LeaveCells = [OldCell - 1, OldCell - 1 -C, OldCell - 1 + C, OldCell - C, OldCell + 1 - C],
					EnterCells = [NewCell + C, NewCell - 1 + C],
					{LeaveCells, EnterCells};
				true ->
					LeaveCells = [OldCell - 1, OldCell - 1 -C, OldCell - 1 + C, OldCell - C, OldCell + 1 - C],
					EnterCells = [NewCell + 1, NewCell + 1 + C, NewCell + 1 -C, NewCell +C, NewCell - 1 + C],
					{LeaveCells, EnterCells}
			end;
		OldCell == NewCell + 1 ->		%% move to left cell 
			if
				(OldCell rem C) == 0 ->
					if
						OldCell == C ->
							LeaveCells = [],
							EnterCells = [NewCell - 1, NewCell - 1 + C],
							{LeaveCells, EnterCells};
						OldCell == R * C ->
							LeaveCells = [],
							EnterCells = [NewCell - 1, NewCell - 1 - C],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [],
							EnterCells = [NewCell - 1, NewCell - 1 - C, NewCell - 1 + C],
							{LeaveCells, EnterCells}
					end;
				((NewCell - 1) rem C) == 0 ->
					if
						NewCell == 1 ->
							LeaveCells = [OldCell + 1, OldCell + 1 +C],
							EnterCells = [],
							{LeaveCells, EnterCells};
						NewCell == 1 + (R - 1) * C ->
							LeaveCells = [OldCell + 1, OldCell + 1 - C],
							EnterCells = [],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell + 1, OldCell + 1 + C, OldCell + 1 - C],
							EnterCells = [],
							{LeaveCells, EnterCells}
					end;
				true ->
					if
						OldCell < C ->
							LeaveCells = [OldCell + 1, OldCell + 1 + C],
							EnterCells = [NewCell - 1, NewCell - 1 + C],
							{LeaveCells, EnterCells};
						OldCell > (R - 1)*C ->
							LeaveCells = [OldCell + 1, OldCell + 1 - C],
							EnterCells = [NewCell - 1, NewCell - 1 - C],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell + 1, OldCell + 1 + C, OldCell + 1 - C],
							EnterCells = [NewCell - 1, NewCell - 1 - C, NewCell - 1 + C],
							{LeaveCells, EnterCells}
					end
			end;
		OldCell == NewCell + 1 + C ->	%% move to left top cell 
			if
				(OldCell rem C) == 0 ->
					if
						OldCell == R * C ->
							LeaveCells = [],
							EnterCells = [NewCell - 1, NewCell - 1 - C, NewCell - 1 + C, NewCell - C, NewCell - C + 1],
							{LeaveCells, EnterCells};
						OldCell == 2 * C ->
							LeaveCells = [OldCell + C, OldCell - 1 + C],
							EnterCells = [NewCell - 1, NewCell - 1 + C],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell + C, OldCell - 1 + C],
							EnterCells = [NewCell - 1, NewCell - 1 - C, NewCell - 1 + C, NewCell - C, NewCell - C + 1],
							{LeaveCells, EnterCells}
					end;
				OldCell > (R - 1) * C ->
					if
						OldCell == (R - 1) * C + 2 ->
							LeaveCells = [OldCell + 1, OldCell + 1 - C],
							EnterCells = [NewCell - C, NewCell - C + 1],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell + 1, OldCell + 1 - C],
							EnterCells = [NewCell - 1, NewCell - 1 - C, NewCell - 1 + C, NewCell - C, NewCell - C + 1],
							{LeaveCells, EnterCells}
					end;
				NewCell < C ->
					if
						NewCell == 1 ->
							LeaveCells = [OldCell + 1, OldCell + 1 + C, OldCell + 1 - C, OldCell + C, OldCell - 1 + C],
							EnterCells = [],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell + 1, OldCell + 1 + C, OldCell + 1 - C, OldCell + C, OldCell - 1 + C],
							EnterCells = [NewCell - 1, NewCell - 1 + C],
							{LeaveCells, EnterCells}
					end;
				((NewCell - 1) rem C) == 0 ->
					LeaveCells = [OldCell + 1, OldCell + 1 + C, OldCell + 1 - C, OldCell + C, OldCell - 1 + C],
					EnterCells = [NewCell - C, NewCell - C + 1],
					{LeaveCells, EnterCells};
				true ->
					LeaveCells = [OldCell + 1, OldCell + 1 + C, OldCell + 1 - C, OldCell + C, OldCell - 1 + C],
					EnterCells = [NewCell - 1, NewCell - 1 - C, NewCell - 1 + C, NewCell - C, NewCell - C + 1],
					{LeaveCells, EnterCells}
			end;
		OldCell == NewCell + 1 - C ->	%% move to left down cell 
			if
				OldCell < C ->
					if
						OldCell == 2 ->
							LeaveCells = [OldCell + 1, OldCell + 1 +C],
							EnterCells = [NewCell + C, NewCell + C + 1],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell + 1, OldCell + 1 + C],
							EnterCells = [NewCell - 1, NewCell - 1 - C, NewCell - 1 + C, NewCell +C, NewCell + C + 1],
							{LeaveCells, EnterCells}
					end;
				(OldCell rem C) == 0 ->
					if
						OldCell == C ->
							LeaveCells = [],
							EnterCells = [NewCell - 1, NewCell - 1 - C, NewCell - 1 + C, NewCell + C, NewCell + C + 1],
							{LeaveCells, EnterCells};
						OldCell == (R - 1) * C ->
							LeaveCells = [OldCell - C, OldCell - 1 - C],
							EnterCells = [NewCell - 1, NewCell - 1 - C],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell - C, OldCell - 1 - C],
							EnterCells = [NewCell - 1, NewCell - 1 - C, NewCell - 1 + C, NewCell + C, NewCell + C + 1],
							{LeaveCells, EnterCells}
					end;
				((NewCell - 1) rem C == 0) ->
					if
						NewCell == C * (R - 1) + 1 ->
							LeaveCells = [OldCell + 1, OldCell + 1 + C, OldCell + 1 - C, OldCell - C, OldCell - 1 - C],
							EnterCells = [],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell + 1, OldCell + 1 + C, OldCell + 1 - C, OldCell - C, OldCell - 1 - C],
							EnterCells = [NewCell + C, NewCell + C + 1],
							{LeaveCells, EnterCells}
					end;
				NewCell > C * (R - 1) ->
					LeaveCells = [OldCell + 1, OldCell + 1 + C, OldCell + 1 - C, OldCell - C, OldCell - 1 -C],
					EnterCells = [NewCell - 1, NewCell - 1 - C],
					{LeaveCells, EnterCells};
				true ->
					LeaveCells = [OldCell + 1, OldCell + 1 + C, OldCell + 1 - C, OldCell - C, OldCell - 1 -C],
					EnterCells = [NewCell - 1, NewCell - 1 - C, NewCell - 1 + C, NewCell + C, NewCell + C + 1],
					{LeaveCells, EnterCells}
			end;
		OldCell == NewCell + C->	%% move to up cell 
			if
				NewCell =< C ->
					if
						NewCell == 1 ->
							LeaveCells = [OldCell +C, OldCell + 1 + C],
							EnterCells = [],
							{LeaveCells, EnterCells};
						NewCell == C ->
							LeaveCells = [OldCell + C, OldCell - 1 + C],
							EnterCells = [],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell + C, OldCell + 1 + C, OldCell - 1 + C],
							EnterCells = [],
							{LeaveCells, EnterCells}
					end;
				OldCell > (R - 1) * C ->
					if
						OldCell == (R - 1)*C + 1 ->
							LeaveCells = [],
							EnterCells = [NewCell - C, NewCell + 1 - C],
							{LeaveCells, EnterCells};
						OldCell == R*C ->
							LeaveCells = [],
							EnterCells = [NewCell - C, NewCell - 1 - C],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [],
							EnterCells = [NewCell - C, NewCell - 1 - C, NewCell + 1 - C],
							{LeaveCells, EnterCells}
					end;
				(OldCell - 1) rem C == 0 ->
					LeaveCells = [OldCell + C, OldCell + 1 + C],
					EnterCells = [NewCell - C, NewCell + 1 - C],
					{LeaveCells, EnterCells};
				OldCell rem C == 0 ->
					LeaveCells = [OldCell + C, OldCell - 1 + C],
					EnterCells = [NewCell - C, NewCell - 1 - C],
					{LeaveCells, EnterCells};
				true ->
					LeaveCells = [OldCell + C, OldCell + 1 + C, OldCell - 1 + C],
					EnterCells = [NewCell - C, NewCell - 1 - C, NewCell + 1 - C],
					{LeaveCells, EnterCells}
			end;
		OldCell == NewCell - C ->	%% move to bottom cell
			if
				NewCell > (R - 1) * C -> %% 新格子在最后一行
					if
						NewCell == (R - 1) * C + 1 ->
							LeaveCells = [OldCell - C, OldCell + 1 - C],
							EnterCells = [],
							{LeaveCells, EnterCells};
						NewCell == R * C ->
							LeaveCells = [OldCell - C, OldCell - 1 - C],
							EnterCells = [],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell - C, OldCell + 1 - C, OldCell - 1 - C],
							EnterCells = [],
							{LeaveCells, EnterCells}
					end;
				OldCell =< C -> %% 旧格子在第一行
					if
						OldCell == 1 ->
							LeaveCells = [],
							EnterCells = [NewCell + C, NewCell + 1 + C],
							{LeaveCells, EnterCells};
						OldCell == C ->
							LeaveCells = [],
							EnterCells = [NewCell + C, NewCell - 1 + C],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [],
							EnterCells = [NewCell + C, NewCell - 1 + C, NewCell + 1 + C],
							{LeaveCells, EnterCells}
					end;
				true -> %% 在中间
					if
						((NewCell - 1) rem C == 0) -> %% 在第一列
							LeaveCells = [OldCell - C, OldCell + 1 - C],
							EnterCells = [NewCell + C, NewCell + 1 + C],
							{LeaveCells, EnterCells};
						(NewCell rem C == 0) -> %% 在最后列
							LeaveCells = [OldCell - C, OldCell - 1 - C],
							EnterCells = [NewCell + C, NewCell - 1 + C],
							{LeaveCells, EnterCells};
						true ->
							LeaveCells = [OldCell - C, OldCell + 1 - C, OldCell - 1 - C],
							EnterCells = [NewCell + C, NewCell - 1 + C, NewCell + 1 + C],
							{LeaveCells, EnterCells}
					end
			end;
		true -> %% 异常bug！！！
			?ERR(scene, "OldCell = ~w, NewCell = ~w", [OldCell, NewCell]),
			exit("get_leave_and_enter_cells heavey bug!!!")
	end.

get_move_broadcast_cell(CellNum, C, R) ->
	if
		CellNum == 1 ->
			CellList = [CellNum, CellNum + 1, CellNum + C, CellNum + C + 1];
		CellNum == C ->
			CellList = [CellNum, CellNum - 1, CellNum + C, CellNum + C - 1];
		CellNum == (R - 1) * C + 1 ->
			CellList = [CellNum, CellNum - C, CellNum - C + 1, CellNum + 1];
		CellNum == R * C -> 
			CellList = [CellNum, CellNum - C, CellNum - C -  1, CellNum - 1];
		CellNum < C -> %% 在第一行
			CellList = [CellNum, CellNum - 1, CellNum + 1, CellNum + C, CellNum - 1 + C, CellNum + 1 + C];
		CellNum > (R - 1) * C -> %% 最后一行
			CellList = [CellNum, CellNum - 1, CellNum + 1, CellNum - C, CellNum - 1 - C, CellNum + 1 - C];
		(CellNum - 1) rem C == 0 -> %% 在第一类
			CellList = [CellNum, CellNum + 1, CellNum - C, CellNum + C, CellNum + 1 + C, CellNum + 1 - C];
		CellNum rem C == 0 -> %% 在最后一列
			CellList = [CellNum, CellNum - 1, CellNum - C, CellNum + C, CellNum - 1 + C, CellNum - 1 - C];
		true -> 
			CellList = [CellNum, CellNum + 1, CellNum + 1 - C, 
						CellNum + 1 + C, CellNum - 1, CellNum - 1 - C, 
						CellNum - 1 + C, CellNum - C, CellNum + C]
	end,
	CellList.
	
  
%%
%% Tests.
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

get_move_broadcast_cell_test() ->
	Colown = 4, Row = 6,
	Fun = fun(Cell) ->
		CellList = get_move_broadcast_cell(Cell, Colown, Row),
		lists:sort(CellList)
	end,
	
	?assertEqual([1, 2, 5, 6], Fun(1)),
	?assertEqual([3, 4, 7, 8], Fun(4)),
	?assertEqual([17, 18, 21, 22], Fun(21)),
	?assertEqual([19, 20, 23, 24], Fun(24)),
	?assertEqual([5, 6, 9, 10, 13, 14], Fun(9)),
	?assertEqual([15, 16, 19, 20, 23, 24], Fun(20)),
	?assertEqual([1, 2, 3, 5, 6, 7], Fun(2)),
	?assertEqual([18, 19, 20, 22, 23, 24], Fun(23)),
	?assertEqual([5, 6, 7, 9, 10, 11, 13, 14, 15], Fun(10)),
	ok.

get_leave_and_enter_cells_test() ->
	Colown = 4, Row = 6,
	%% 	1	2	3	4
	%% 	5	6	7	8
	%% 	9	10	11	12
	%% 	13	14	15	16
	%% 	17	18	19	20
	%% 	21	22	23	24
	
	Fun = fun(OldCell, NewCell) ->
		{LeaveCells1, EnterCells1} = get_leave_and_enter_cells(OldCell, NewCell, Colown, Row),
		{lists:sort(LeaveCells1), lists:sort(EnterCells1)}
	end,
	
	%% 从当前格子移动到右下角
	?assertEqual({[], [3,7,9,10,11]}, Fun(1, 6)),
	?assertEqual({[1,2], [7,11,13,14,15]}, Fun(5, 10)),
	?assertEqual({[13,14], [19,23]}, Fun(17, 22)),
	?assertEqual({[2,6], [11,12]}, Fun(3, 8)),
	?assertEqual({[2,3,4,6,10], [15,16]}, Fun(7, 12)),
	?assertEqual({[14,15,16,18,22], []}, Fun(19, 24)),
	?assertEqual({[1,5], [4,8,10,11,12]}, Fun(2, 7)),
	?assertEqual({[13,14,15,17,21], [20,24]}, Fun(18, 23)),
	?assertEqual({[5,6,7,9,13], [12,16,18,19,20]}, Fun(10, 15)),
	
	%% 从当前格子移动到左边
	?assertEqual({[3,7], []}, Fun(2, 1)),
	?assertEqual({[3,7,11], []}, Fun(6, 5)),
	?assertEqual({[19,23], []}, Fun(22, 21)),
	?assertEqual({[], [2,6]}, Fun(4, 3)),
	?assertEqual({[], [10,14,18]}, Fun(16, 15)),
	?assertEqual({[], [18,22]}, Fun(24, 23)),
	?assertEqual({[4,8], [1,5]}, Fun(3, 2)),
	?assertEqual({[12,16,20], [9,13,17]}, Fun(15, 14)),
	?assertEqual({[20,24], [17,21]}, Fun(23, 22)),
	
	%% 移动到左上角
	?assertEqual({[3,7,9,10,11], []}, Fun(6, 1)),
	?assertEqual({[4,8,10,11,12], [1,5]}, Fun(7, 2)),
	?assertEqual({[11,12], [2,6]}, Fun(8, 3)),
	?assertEqual({[19,23], [13,14]}, Fun(22, 17)),
	?assertEqual({[20,24], [13,14,15,17,21]}, Fun(23, 18)),
	?assertEqual({[15,19,21,22,23], [9,10]}, Fun(18, 13)),
	?assertEqual({[], [14,15,16,18,22]}, Fun(24, 19)),
	?assertEqual({[19,20], [6,7,8,10,14]}, Fun(16, 11)),
	?assertEqual({[16,20,22,23,24], [9,10,11,13,17]}, Fun(19, 14)),
	
	%% 移动到左下角
	?assertEqual({[3,7], [9,10]}, Fun(2, 5)),
	?assertEqual({[4,8], [1,5,9,10,11]}, Fun(3, 6)),
	?assertEqual({[], [2,6,10,11,12]}, Fun(4, 7)),
	?assertEqual({[13,14,15,19,23], []}, Fun(18, 21)),
	?assertEqual({[14,15,16,20,24], [17,21]}, Fun(19, 22)),
	?assertEqual({[15,16], [18,22]}, Fun(20, 23)),
	?assertEqual({[7,8], [10,14,18,19,20]}, Fun(12, 15)),
	?assertEqual({[5,6,7,11,15], [17,18]}, Fun(10, 13)),
	?assertEqual({[2,3,4,8,12], [5,9,13,14,15]}, Fun(7, 10)),
	
	%% 移动到正上方
	?assertEqual({[9,10], []}, Fun(5, 1)),
	?assertEqual({[9,10,11], []}, Fun(6, 2)),
	?assertEqual({[11,12], []}, Fun(8, 4)),
	?assertEqual({[], [13,14]}, Fun(21, 17)),
	?assertEqual({[], [14,15,16]}, Fun(23, 19)),
	?assertEqual({[], [15,16]}, Fun(24, 20)),
	?assertEqual({[17,18], [5,6]}, Fun(13, 9)),
	?assertEqual({[23,24], [11,12]}, Fun(20, 16)),
	?assertEqual({[17,18,19], [5,6,7]}, Fun(14, 10)),
	
	%% 移动到正下方
	?assertEqual({[], [9,10]}, Fun(1, 5)),
	?assertEqual({[], [9,10,11]}, Fun(2, 6)),
	?assertEqual({[], [11,12]}, Fun(4, 8)),
	?assertEqual({[15,16], []}, Fun(20, 24)),
	?assertEqual({[14,15,16], []}, Fun(19, 23)),
	?assertEqual({[13,14], []}, Fun(17, 21)),
	?assertEqual({[5,6], [17,18]}, Fun(9, 13)),
	?assertEqual({[11,12], [23,24]}, Fun(16, 20)),
	?assertEqual({[5,6,7], [17,18,19]}, Fun(10, 14)),
	ok.
	
	
-endif.
