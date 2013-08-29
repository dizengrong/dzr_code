-module(data_boss).

-compile(export_all).

-include("common.hrl").

leave_boss_scene()->
	[1000].

get_boss_hp_by_level(_)->
	999999.

get_jisha_award()->
	{100000, 100000}.

get_magic_boss_id()->
	5000.

get_boss_xy()->
	Rec = data_monster:get_monster(3000, 653),
	Rec.

go_back_to_frist_position()->
	3000.

get_bossscene_id()->
	1500.

get_probability()->
	[50,50].

get_silver_inspire()->
	1000.

get_gold_inspire()->
	2.

get_gold_to_clean_cd()->
	3.

get_boss_time()->
	[#boss_time{
		register_time=57300,
		begin_time=57600,
		end_time=58800}
%% 	#boss_time{
%% 		register_time=68400,
%% 		begin_time=68700,
%% 		end_time=69300}
		].

%% return all boss id
get_all_boss() ->
	[5000].

%% get_boss(5000) ->
%% 	#boss {
%% 		boss_id  = 5000,
%% 		boss_hp  = 20000000,
%% 		scene_id = 2901,
%% 		level    = {30,150}
%% 	};
	
get_boss(_) -> undefined.