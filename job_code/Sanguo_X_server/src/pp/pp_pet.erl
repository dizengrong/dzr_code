%% Author: dzr
%% Created: 2011-12-9
%% Description: TODO: Add description to pp_pet
-module(pp_pet).

%%=============================================================================
%% Include files
%%=============================================================================
-include("common.hrl").
%%=============================================================================
%% Exported Functions
%%=============================================================================
-export([handle/3]).



%% 请求任务总览
handle(28010, PlayerId, _) ->
	PS = mod_player:get_player_status(PlayerId),

	{_, Packet} = pt_28:write(28009, 0),
	lib_send:send(PS#player_status.send_pid, Packet);

handle(Cmd, _Status, Data) ->
    ?DEBUG(account, "pp_pet no match: cmd = ~w, data = ~w", [Cmd, Data]),
    {error, "pp_pet no match"}.

