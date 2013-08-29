-module(pp_boss).

-export([handle/3]).

-include("common.hrl").

%%request enter the boss scene
handle(62000, AccountID, {})->
	mod_boss:request_to_enter_boss_battle(AccountID);

%%request boss basic information
handle(62001, AccountID, {})->
	mod_boss:request_boss_basic_info(AccountID);

handle(62002, AccountID, {})->
	mod_boss:boss_damage_ranking(AccountID);

handle(62003, AccountID, {})->
	mod_boss:boss_appear(AccountID);

handle(62004, AccountID, {})->
	mod_boss:update_boss_hp(AccountID);



handle(62006, AccountID, {})->
	mod_boss:player_fight_boss(AccountID);


%%鼓舞
handle(62008, AccountID, [Type])->
	case Type of
		?SILVER_INSPIRE ->	
			mod_boss:silver_inspire(AccountID);
		?GOLD_INSPIRE ->
			mod_boss:gold_inspire(AccountID)
	end;

handle(62007, AccountID, {})->
	?INFO(boss,"handle 62007 clean cd "),
	mod_boss:client_request_clean_cd(AccountID);

handle(62010, AccountID, {})->
	?INFO(boss," client request to leave boss scene"),
	mod_boss:client_request_to_leave(AccountID);

handle(Cmd, _PlayerId, _) ->
	?ERR(boss, "boss protocal ~w not implemented", [Cmd]).