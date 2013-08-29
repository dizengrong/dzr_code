-ifndef(__ANNOUNCEMENT_HRL__).
-define(__ANNOUNCEMENT_HRL__, 1).

-include("types.hrl").

-define(ANNOUNCE_ACHIEVEMENT, 	1).
-define(ANNOUNCE_RUN_BUSINESS,	2).
-define(ANNOUNCE_ROB_SUCCESS,	3).
-define(ANNOUNCE_ROB_FAIL,		4).
-define(ANNOUNCE_PURPLE_ITEM,	5).
-define(ANNOUNCE_ONLINE_ARENA,	6).
-define(ANNOUNCE_ONLINE_AWARD,	7).
-define(ANNOUNCE_GUILD,			8).
-define(ANNOUNCE_PET,			9).
-define(ANNOUNCE_OFFLINE_ARENA,	10).
-define(ANNOUNCE_HORN,			11).
-define(ANNOUNCE_OFFLINE_ARENA_FIRST_RANKS,12).
-define(ANNOUNCE_BOXING_HOST_CHANGES,	13).
-define(ANNOUNCE_FLOWER,		14).
-define(ANNOUNCE_GUILD_DONATE,	15).
-define(ANNOUNCE_FIRST_CHARGE_REWARD,	16).
-define(ANNOUNCE_WORLD_BOSS_RANK,		17).
-define(ANNOUNCE_NEW_CARD,		18).
-define(ANNOUNCE_EXCHANGE_CARD,		    19).
-define(ANNOUNCE_WORLD_BOSS_KILLER,		20).
-define(SEND_ARENA_NO1_CHANGE,23).
-define(ADD_DELETE_FRIEND,21).
-define(SEND_ITEM_QUALIY,22).

-define(CARD_FROM_RESURRECTION, 1).
-define(CARD_FROM_HUNTING,      2).

-record(player_event, 
    {
        type       = none :: none | arena | garden | boxing,
        content    = {}   :: any()
    }).

-endif.

