
-module(pp_guaji).
%% mail:laojiajie@4299.net

-include("common.hrl").

-export([handle/3]).


handle(61000, AccountID, _Data) ->
    mod_guaji:getInfo(AccountID);

handle(61001,AccountID,{Precent, IsUseDrug, IsUseBlood, IsAutoStop, IsAutoBuy}) ->
	mod_guaji:setInfo(AccountID, Precent, IsUseDrug, IsUseBlood, IsAutoStop, IsAutoBuy);

handle(61002,AccountID,_Data) ->
	mod_guaji:startGuaji(AccountID);

handle(61003,AccountID,_Data) ->
	mod_guaji:stopGuaji(AccountID,1);

handle(61004,AccountID,AddTimes) ->
	mod_guaji:buyGuaji(AccountID,AddTimes);

handle(_, _, _) ->
	ok.