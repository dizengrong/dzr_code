%% Author: Administrator
%% Created: 2011-9-28
%% Description: TODO: Add description to new_file
-module(pp_holy).

%%
%% Include files
%%
-include("common.hrl").
%%
%% Exported Functions
%%
-export([handle/3]).

%%
%% API Functions
%%
handle(24000, PlayerId, _Flag) ->
	PS = mod_player:get_player_status(PlayerId),

	{ok, BinData} = pt_24:write(24000, []),
	lib_send:send(PS#player_status.send_pid, BinData);

handle(24002, PlayerId, Type) ->
	PS = mod_player:get_player_status(PlayerId),

	{ok, BinData} = pt_24:write(24002, {Type, 30, 0, 0}),
	lib_send:send(PS#player_status.send_pid, BinData);
% handle(24001, PlayerStatus, Type) ->
% 	{RetCode, NewPlayerStatus} = mod_holy:upgrade(PlayerStatus, Type),
% 	mod_player:notify_pet(PlayerStatus#player_status.pid, {Type, RetCode}, ?AUTO_UP_HOLY),
% 	?INFO(holy,"RetCode = ~w", [RetCode]),
% 	?INFO(holy, "oldsilver=[~w]", [PlayerStatus#player_status.silver]),
% 	?INFO(holy, "NEWsilver=[~w]", [NewPlayerStatus#player_status.silver]),
% 	{ok, NewPlayerStatus};

% handle(24002, PlayerStatus, Type) ->
% 	case mod_holy:get_consume_time(PlayerStatus, Type) of
% 		{fail, ErrCode} ->
% 			?INFO(holy,"ErrCode = ~w", [ErrCode]);
% 		{ok, UpgradeTime} ->
% 			?INFO(holy,"UpgradeTime = ~w", [UpgradeTime])
% 	end;

% handle(24003, PlayerStatus, Type) ->
% 	Reply = mod_holy:activate(PlayerStatus, Type),
% 	?INFO(holy,"RetCode = ~w", [Reply]),
% 	{ok, PlayerStatus};

handle(_Cmd, _Status, _Data) ->
	?ERR(holy, "pp_holy", []),
    {error, "pp_holy no match"}.
%%
%% Local Functions
%%

