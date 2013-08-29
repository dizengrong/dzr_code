%% Author: dzr
%% Created: 2011-10-12
%% Description: TODO: Add description to pt_25
-module(pt_25).

%%=============================================================================
%% Include files
%%=============================================================================
-include("common.hrl").

%%=============================================================================
%% Exported Functions
%%=============================================================================
-export([read/2, write/2]).

%%=============================================================================
%% API Functions
%%=============================================================================

read(25010, _R) ->
	{ok, []};

read(25100, _R) ->
	{ok, []};

read(25101, <<FeedType:8>>) ->
	{ok, FeedType};

read(25103, <<HorseEquipId:32>>) ->
	{ok, HorseEquipId};

read(25104, <<IsShow:32>>) ->
	{ok, IsShow};

read(Cmd, _R) ->
	?ERR(print, "protocal not matched: ~w", [Cmd]),
    {error, protocal_no_match}.


write(25000, EconomyRec) ->
    {ok, pt:pack(25000, <<(EconomyRec#economy.gd_silver):32,
                          (EconomyRec#economy.gd_gold):32,
                          (EconomyRec#economy.gd_bind_gold):32,
                          (EconomyRec#economy.gd_popularity):32,
                          (EconomyRec#economy.gd_totalPopularity):32,
                          (EconomyRec#economy.gd_practice):32>>)};

write(25003,Weiwang) ->
	{ok,pt:pack(25003,<<Weiwang:8>>)};

write(25010, {HorseId, WingId}) -> 
	{ok, pt:pack(25010, <<HorseId:32, WingId:32>>)};

write(25100, HorseRec) ->
	Size = length(HorseRec#horse.gd_equipList),
	Bin0 = pt:write_id_list(Size, HorseRec#horse.gd_equipList, 32),
	Bin = <<(HorseRec#horse.gd_horse):32,
			(HorseRec#horse.gd_isShow):8,
			(HorseRec#horse.gd_exp):32,
			(HorseRec#horse.gd_curHorseEquip):32,
			Size:16, Bin0/binary>>,
	{ok, pt:pack(25100, Bin)};

write(25102, LeftFeedTimes) -> 
	{ok, pt:pack(25102, <<LeftFeedTimes:8>>)}.