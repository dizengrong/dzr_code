%%%--------------------------------------
%%% @Module  : pp_account
%%% @Email   : dizengrong@gmail.com
%%% @Created : 2012-4-13
%%% @Description:something related to player
%%%--------------------------------------
-module(pp_player_info).

-include ("common.hrl").

-export([handle/3]).



handle(25010, PlayerId, _Data) ->
    PS = mod_player:get_player_status(PlayerId),

    {ok, Packet} = pt_25:write(25010, {0, 0}),
    lib_send:send(PS#player_status.send_pid, Packet);

handle(25100, PlayerId, _Data) ->
	mod_horse:client_get_horse_info(PlayerId);

handle(25101, PlayerId, FeedType) ->
	mod_horse:client_feed_horse(PlayerId, FeedType);

handle(25103, PlayerId, HorseEquipId) ->
	mod_horse:client_buy_horse_equip(PlayerId, HorseEquipId);

handle(25104, PlayerId, IsShow) ->
	mod_horse:client_change_show_state(PlayerId, IsShow).
