%% 爬塔PP

-module(pp_marstower).

-export([handle/3]).

-include("common.hrl").

handle(38000,PlayerID,_Data) ->
	PS = mod_player:get_player_status(PlayerID),
	gen_server:cast(PS#player_status.marstower_pid,{getInfo,PlayerID});

handle(38001,PlayerID,_Data) ->
	PS = mod_player:get_player_status(PlayerID),
	gen_server:cast(PS#player_status.marstower_pid,{enterCircle,PlayerID});

handle(38003,PlayerID,_Data) ->
	PS = mod_player:get_player_status(PlayerID),
	gen_server:cast(PS#player_status.marstower_pid,{getPoint,PlayerID});

handle(38004,PlayerID,ItemIDList) ->
	PS = mod_player:get_player_status(PlayerID),
	gen_server:cast(PS#player_status.marstower_pid,{changePoint,PlayerID,ItemIDList});

handle(38005,PlayerID,{BookID,Num}) ->
	PS = mod_player:get_player_status(PlayerID),
	gen_server:cast(PS#player_status.marstower_pid,{buyBook,PlayerID,BookID,Num});

handle(38006,PlayerID,Floor) ->
	?INFO(marstower,"receive KingInfo request!PlayerID =~w,Floor =~w",[PlayerID,Floor]),
	mod_marstower_king:getKingInfo(PlayerID,Floor);

handle(38007,PlayerID,_Data) ->
	mod_marstower_king:challenge(PlayerID);

handle(38008,PlayerID,_Data) ->
	PS = mod_player:get_player_status(PlayerID),
	gen_server:cast(PS#player_status.marstower_pid,{reset,PlayerID});


handle(Cmd, _Status, Data) ->
    ?DEBUG(account, "handle_account no match: cmd = ~w, data = ~w", [Cmd, Data]),
    {error, "handle_account no match"}.