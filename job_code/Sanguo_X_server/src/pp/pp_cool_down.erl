%% Author: Administrator
%% Created: 2011-9-28
%% Description: TODO: Add description to new_file
-module(pp_cool_down).

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
handle(23000, PlayerId, _Flag) ->
	PS = mod_player:get_player_status(PlayerId),

	{ok, BinData} = pt_23:write(23000, []),
	lib_send:send_direct(PS#player_status.send_pid, BinData);


% handle(23001, PlayerStatus, Type) ->
% 	?INFO(print,"Type = ~w", [Type]),
% 	{RetCode, NewPlayerStatus} = mod_cool_down:extend(PlayerStatus, Type),
% 	?INFO(cool_down, "RetCode = ~w", [RetCode]),
% 	{ok, NewPlayerStatus};

% handle(23002, PlayerStatus, Num) ->
% 	{RetCode, NewPlayerStatus} = mod_cool_down:clear(PlayerStatus, Num),
% 	?INFO(cool_down, "RetCode = ~w", [RetCode]),
% 	{ok, NewPlayerStatus};

handle(_Cmd, _Status, _Data) ->
	?ERR(cool_down, "pp_cool_down no match", []),
    {error, "pp_cool_down no match"}.
%%
%% Local Functions
%%

