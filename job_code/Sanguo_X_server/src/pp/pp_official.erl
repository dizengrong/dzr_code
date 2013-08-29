-module (pp_official).

-export([handle/3]).

handle(13000, PlayerId, _)->
	mod_official:client_request_fenglu_state(PlayerId);

handle(13001, PlayerId, _) ->
	mod_official:client_get_fenglu(PlayerId);

handle(13010, PlayerId, _) ->
	mod_official:client_get_qihun(PlayerId);


handle(13011, PlayerId, {QihunId, FinishRightNow}) ->
	mod_official:client_request_leveling(PlayerId, QihunId, FinishRightNow);	

handle(13012, PlayerId, _) ->
	mod_official:client_clear_leveling_cd(PlayerId);

handle(13020, PlayerId, _) ->
	mod_official:client_get_pinjie(PlayerId);

handle(13021, PlayerId, QihunId) ->
	mod_official:client_up_pinjie(PlayerId, QihunId);

handle(13025, PlayerId, _) ->
	mod_official:client_get_stage(PlayerId).	
