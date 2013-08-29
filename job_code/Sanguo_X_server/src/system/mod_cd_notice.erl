%% Author: mankiw
%% Created: 2012-10-16
%% Description: TODO: Add description to mod_cd_notice
-module(mod_cd_notice).

%%
%% Include files
%%
-include("common.hrl").
%%
%% Exported Functions
%%
-export([get_is_have_salary/1, get_soul_weapon_cd/1,get_plant_cd/1, get_is_can_harvest/1,get_arena_cd/1,
		 get_is_can_upgrate_skill/1, get_is_can_feed_horse/1]).

%%
%% API Functions
%%
get_is_have_salary(PlayerId)->
	case mod_official:client_request_fenglu_state(PlayerId) of 
		{false, ErrCode} ->
			{ok, Packet} = pt_23:write(23000, ErrCode),
			lib_send:send_by_id(PlayerId, Packet);
		{true,RCode} ->
			{ok, Packet} = pt_23:write(23000, RCode),
	        lib_send:send_by_id(PlayerId, Packet)
	end.

get_soul_weapon_cd(PlayerId)->
	QihunRec =  mod_official:get_qihun_rec(PlayerId),
	case QihunRec#qi_hun.gd_isInLeveling of
		1 ->
			Now          = util:unixtime(),
			LevelingTime = data_official:get_leveling_time(QihunRec#qi_hun.gd_level),
			LeftTime     = QihunRec#qi_hun.gd_beginTime + LevelingTime - Now;
		0 ->
			LeftTime = 0
	end,
	LevelingId  = QihunRec#qi_hun.gd_levelingId,
	{ok, Packet} = pt_23:write(23001, {LevelingId, LeftTime}),
	lib_send:send_by_id(PlayerId, Packet).
	

get_plant_cd(PlayerId)->
	LandList = fengdi_db:get_lands(PlayerId),
	F = fun(LandListA, LandListB)->
		LandListA#land.cd_time =< LandListB#land.cd_time
	end,
	SortLandList = lists:sort(F, LandList),
	Land = hd(SortLandList),
	CdTime = case Land#land.cd_time-util:unixtime()>0 of
		true -> Land#land.cd_time-util:unixtime();
		false ->0
	end,
	Bin = pt_23:write(23002, CdTime),
	lib_send:send_by_id(PlayerId, Bin).
	
get_is_can_harvest(PlayerId)->
	LandList = fengdi_db:get_lands(PlayerId),
	F = fun(LandListA, LandListB)->
		LandListA#land.state >= LandListB#land.state
	end,
	SortLandList = lists:sort(F, LandList),
	Land = hd(SortLandList),
	IsCanHarvest = case Land#land.state of
		2 -> 1;
		1 -> 0
	end,
	Bin = pt_23:write(23003, IsCanHarvest),
	lib_send:send_by_id(PlayerId, Bin).

get_arena_cd(PlayerId)->
	ArenaRec = g_arena:get_rec(PlayerId),
	CdTime = case ArenaRec#arena_rec.challengetimes>=15 of 
		true -> -1;
		false ->
			mod_cool_down:getCoolDownLeftTimeDayDown(PlayerId, ?ARENA_CD)
	end,
	Bin = pt_23:write(23004, CdTime),
	lib_send:send_by_id(PlayerId, Bin).

get_is_can_upgrate_skill(PlayerId)->
	IsCanUp = case mod_cool_down:getCoolDownLeftTimeDayDown(PlayerId, ?ARENA_CD) of 
		0->1;
		_->0
	end,
		Bin = pt_23:write(23005, IsCanUp),
	lib_send:send_by_id(PlayerId, Bin).

get_is_can_feed_horse(_PlayerId)->
	ok.

clearCd(PlayerId,Type)->
	case Type of
		?ARENA_CD->
			mod_arena:clean_arena_battle_cd(PlayerId,0);%% 0 is to clear,other is to query
		?Qihun_CD->
			mod_official:client_clear_leveling_cd(PlayerId)
	end.
		
	

%%
%% Local Functions
%%

