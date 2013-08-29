-module (pt_21).

-export([read/2, write/2]).

read(21001, <<DungeonId:16>>) -> 
	{ok, DungeonId};

read(21002, <<DungeonId:16>>) -> 
	{ok, DungeonId};

read(21003, <<DungeonId:16, TimesToBuy>>) -> 
	{ok, {DungeonId, TimesToBuy}};

read(21005, _) -> 
	{ok, []};

read(21006, _) -> 
	{ok, []}.

write(21000, ProcessIdList) ->
	case erlang:length(ProcessIdList) of
		ListNum when ListNum =< 0 ->
			ListBin = <<>>;
		ListNum ->
			F = fun(ProcessId) ->
				<<ProcessId:32>>
			end,
			ListBin = list_to_binary(lists:map(F, ProcessIdList))
	end,
	{ok, pt:pack(21000, <<ListNum:16, ListBin/binary>>)};

write(21001, {DungeonId, EnterTimes, LeftTimes, BuyTimes}) ->
	{ok, pt:pack(21001, <<DungeonId:16, EnterTimes:8, LeftTimes:8, BuyTimes:8>>)};

write(21004, {DungeonId, MaxAttDamage, BattleRound, DamageRecv, Score, Rank, BattleRank,
			  HistoryMaxAttDamage, HistoryBattleRound, HistoryDamageRecv, HistoryRank, HistoryScore}) ->
	{ok, pt:pack(21004, <<DungeonId:16,
						  MaxAttDamage:32,
						  BattleRound:16, 
						  DamageRecv:32,
						  Score:32,
						  Rank:16,
						  BattleRank:8,
						  HistoryMaxAttDamage:32,
						  HistoryBattleRound:16,
						  HistoryDamageRecv:32,
						  HistoryRank:16,
						  HistoryScore:32>>)};

write(21005, Result) ->
	{ok, pt:pack(21005, <<Result:8>>)}.	