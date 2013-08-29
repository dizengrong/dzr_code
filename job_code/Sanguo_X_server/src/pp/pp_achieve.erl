-module(pp_achieve).

-export([handle/3]).

-include("common.hrl").

handle(29000,AccountID,_Data) ->
	mod_achieve:getTotalPoint(AccountID);

handle(29001,AccountID,Type) ->
	mod_achieve:getAchieveTypeInfo(AccountID,Type);

handle(29003,AccountID,_Data) ->
	mod_achieve:getAwardCanTake(AccountID);

handle(29004,AccountID,{Type,SubType}) ->
	mod_achieve:takeAward(AccountID,Type,SubType);

handle(Cmd, _PlayerId, _) ->
	?ERR(achieve, "achieve protocal ~w not implemented", [Cmd]).