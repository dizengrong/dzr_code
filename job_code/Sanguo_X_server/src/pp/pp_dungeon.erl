-module (pp_dungeon).

-include ("common.hrl").

-export([handle/3]).


handle(21001, PlayerId, DungeonId) ->
	?INFO(dungeon,"read 21001 DungeonId = ~w",[DungeonId]),
	mod_dungeon:client_get_enter_times(PlayerId, DungeonId);

handle(21002, PlayerId, DungeonId) ->
	mod_dungeon:client_enter(PlayerId, DungeonId);

handle(21003, PlayerId, {DungeonId, TimesToBuy}) ->
	mod_dungeon:client_buy_times(PlayerId, DungeonId, TimesToBuy);

handle(21005, PlayerId, _) ->
	mod_dungeon:client_start_award(PlayerId);

handle(21006, PlayerId, _) ->
	mod_dungeon:client_get_award(PlayerId).	

