-module(pp_dazuo).

-export([handle/3]).

-include("common.hrl").

handle(49000,AccountID,_Data) ->
	mod_dazuo:getTotalPoint(AccountID);

handle(49001,AccountID,ID) ->
	mod_dazuo:beginDazuo(AccountID,ID);

handle(49002,AccountID,_Data) ->
	mod_dazuo:endDazuo(AccountID);


handle(Cmd, _PlayerId, _) ->
	?ERR(dazuo, "dazuo protocal ~w not implemented", [Cmd]).