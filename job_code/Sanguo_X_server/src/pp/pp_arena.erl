%%=============pp_arena.erl=====
%%%=======p_31==================

-module(pp_arena).
-export([handle/3]).

-include("common.hrl").

handle(31000, AccountID, [])->
	mod_arena:get_opponent(AccountID);  %%获取排位信息

handle(31001, AccountID, [])->
	mod_arena:get_recent_record(AccountID);

handle(31002, AccountID, [Rank])->
	mod_arena:challenge(AccountID, Rank);

handle(31003, AccountID, [Typestate])->
	mod_arena:get_daily_award(AccountID, Typestate);

handle(31004, AccountID, [])->
	mod_arena:get_card_award(AccountID);

handle(31005, AccountID, [Page])->
	mod_arena:get_heroes(AccountID, Page);

handle(31006, AccountID, [Byte])->
	mod_arena:clean_arena_battle_cd(AccountID, Byte);

handle(31007, AccountID, [Flag])->
	mod_arena:add_challenge_times(AccountID,  Flag);

handle(31008, AccountID, [])->
	mod_arena:client_request_win_record(AccountID);

handle(Cmd, _PlayerId, _) ->
	?ERR(arena, "arena protocal ~w not implemented", [Cmd]).