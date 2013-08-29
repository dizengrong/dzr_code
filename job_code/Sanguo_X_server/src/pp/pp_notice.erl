-module (pp_notice).

-export([handle/3]).

handle(23000, PlayerId, _)->
	mod_official:get_is_have_salary(PlayerId);

handle(23001, PlayerId, _)->
	mod_official:get_is_have_salary(PlayerId);

handle(23002, PlayerId, _)->
	mod_official:get_is_have_salary(PlayerId);

handle(23003, PlayerId, _)->
	mod_official:get_is_have_salary(PlayerId);

handle(23004, PlayerId, _)->
	mod_official:get_is_have_salary(PlayerId);

handle(23005, PlayerId, _)->
	mod_official:get_is_have_salary(PlayerId);

handle(23010, PlayerId, _)->
	mod_official:get_is_have_salary(PlayerId).


