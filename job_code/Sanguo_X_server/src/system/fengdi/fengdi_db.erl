-module (fengdi_db).

-include("common.hrl").

-compile(export_all).


-define(FENGDI_CACHE_REF, 		cache_util:get_register_name(fengdi_data)).
-define(SLAVE_CACHE_REF, 		cache_util:get_register_name(slave)).
-define(SLAVE_OWNER_CACHE_REF, 	cache_util:get_register_name(slave_owner)).

%% =========================================================================
%% ======================== 有关封地的细碎数据库操作 =======================
get_current_seed_quality(PlayerId, SeedType) ->
	Rec = get_fengdi_data(PlayerId),
	case SeedType of
		?SEED_EXP ->
			Rec#fengdi_data.exp_seed_quality;
		?SEED_SILVER ->
			Rec#fengdi_data.sil_seed_quality
	end.

%% 返回: {经验种子品质， 银币种子品质}
get_current_seed_quality(PlayerId) ->
	Rec = get_fengdi_data(PlayerId),
    ?INFO(land,"client get seed info result is ~w",[Rec]),
	{Rec#fengdi_data.exp_seed_quality, Rec#fengdi_data.sil_seed_quality}.

%% 重置当前的种子品质为最低等的
reset_current_seed_quality(PlayerId, SeedType) ->
	case SeedType of
		?SEED_EXP ->
			FieldIndex = #fengdi_data.exp_seed_quality;
		?SEED_SILVER ->
			FieldIndex = #fengdi_data.sil_seed_quality
	end,
	gen_cache:update_element(?FENGDI_CACHE_REF, PlayerId, [{FieldIndex, ?SEED_QUALITY_1}]).

set_current_seed_quality(PlayerId, SeedType, SeedQuality) ->
	case SeedType of
		?SEED_EXP ->
			FieldIndex = #fengdi_data.exp_seed_quality;
		?SEED_SILVER ->
			FieldIndex = #fengdi_data.sil_seed_quality
	end,
	gen_cache:update_element(?FENGDI_CACHE_REF, PlayerId, [{FieldIndex, SeedQuality}]).

get_fengdi_data(PlayerId) ->
	case gen_cache:lookup(?FENGDI_CACHE_REF, PlayerId) of
		[] ->
			Rec = #fengdi_data{gd_accountId = PlayerId},
			gen_cache:insert(?FENGDI_CACHE_REF, Rec);
		[Rec | _] ->
			ok
	end,
	Rec.
%% =========================================================================
%% ====================== end ==============================================



%% =========================================================================
%% ========================= 有关种植的数据库操作 ==========================
get_lands(PlayerId) ->
	case gen_cache:lookup(?LAND_CACHE_REF, PlayerId) of
		[] ->
			Rec1 = #land{key = {PlayerId, 1}},
			Rec2 = #land{key = {PlayerId, 2}},
			insert_land(Rec1),
			insert_land(Rec2),
			[Rec1, Rec2];
		LandRecList ->
			check_and_reset(util:unixtime(), LandRecList, [])
	end.

get_land(PlayerId, LandId) ->
	Recs = gen_cache:lookup(?LAND_CACHE_REF, {PlayerId, LandId}),
	case Recs of
		[] ->
			[];
		_ ->
			[Rec | _] = check_and_reset(util:unixtime(), Recs, []),	
			Rec
	end.

check_and_reset(_Now, [], LandRecList) -> LandRecList;
check_and_reset(Now, [LandRec | Rest], LandRecList) ->
	LandRec1 = check_and_reset_watering_times(Now, LandRec),
	LandRec2 = check_and_reset_cd_time(Now, LandRec1),
	case LandRec2 /= LandRec of
		true ->
			gen_cache:update_record(?LAND_CACHE_REF, LandRec2);
		_ ->
			ok
	end,	
	check_and_reset(Now, Rest, [LandRec2 | LandRecList]).

check_and_reset_watering_times(Now, LandRec) ->
	case util:get_diff_day(LandRec#land.update_time, Now) of
		the_same_day -> 
			LandRec1 = LandRec;
		_ ->
			LandRec1 = LandRec#land{update_time = Now, watering_times = 0}
	end,
	LandRec1.
check_and_reset_cd_time(Now, Rec) ->
	case (Rec#land.state == ?PLANTING_NO) andalso 
		 (Rec#land.cd_time > 0) andalso
		 (Now >= Rec#land.cd_time) of
		true ->
			Rec1 = Rec#land{state = ?PLANTING_NO, cd_time = 0};
		false ->
			Rec1 = Rec
	end,
	Rec1.

increase_watering_times(PlayerId, LandId) ->
	gen_cache:update_counter(?LAND_CACHE_REF, {PlayerId, LandId}, {#land.watering_times, 1}).

insert_land(Rec) ->
	gen_cache:insert(?LAND_CACHE_REF, Rec).

update_land_elements(Key, UpdateFields) ->
	gen_cache:update_element(?LAND_CACHE_REF, Key, UpdateFields).	

%% =========================================================================
%% ====================== end ==============================================

%% =========================================================================
%% ========================= 有关奴隶的数据库操作 ==========================
get_all_slave_recs() ->
	gen_cache:tab2list(?SLAVE_CACHE_REF).
	
get_slave_owner_rec(PlayerId) ->
	case gen_cache:lookup(?SLAVE_OWNER_CACHE_REF, PlayerId) of
		[] ->
			Rec = #slave_owner{gd_accountId = PlayerId},
			gen_cache:insert(?SLAVE_OWNER_CACHE_REF, Rec),
			Rec;
		[Rec | _] ->
			check_and_reset_slave_owner_rec(Rec)
	end.

get_slave_by_cage(SlaveOwnerId, Pos) ->
	Rec = get_slave_owner_rec(SlaveOwnerId),
	erlang:element(get_cage_field_index_by_pos(Pos), Rec).

check_and_reset_slave_owner_rec(Rec) ->
	Now = util:unixtime(),
	case util:get_diff_day(Rec#slave_owner.update_time, Now) of
		the_same_day -> 
			Rec;
		_ ->
			UpdateFields = [{#slave_owner.work_times, 0}, {#slave_owner.update_time, Now}],
			update_slave_owner_elements(Rec#slave_owner.gd_accountId, UpdateFields),
			Rec#slave_owner{work_times = 0, update_time = Now}
	end.

update_slave_owner_elements(Key, UpdateFields) ->
	gen_cache:update_element(?SLAVE_OWNER_CACHE_REF, Key, UpdateFields).

get_slave_rec(SlaveId) ->
	case gen_cache:lookup(?SLAVE_CACHE_REF, SlaveId) of
		[] ->
			Rec = #slave{gd_accountId = SlaveId},
			gen_cache:insert(?SLAVE_CACHE_REF, Rec);
		[Rec | _] ->
			ok
	end,
	Rec.

%% 重置位于第Pos个笼子中的奴隶id为?CAGE_OPENED
reset_cage(SlaveOwnerId, Pos) ->
	FieldIndex = get_cage_field_index_by_pos(Pos),
	update_slave_owner_elements(SlaveOwnerId, [{FieldIndex, ?CAGE_OPENED}]).

%% 奴隶释放了
free_slave(SlaveId) ->
	UpdateFields = [{#slave.slave_owner, 0}, {#slave.end_time, 0}, {#slave.taxes, 0}],
	gen_cache:update_element(?SLAVE_CACHE_REF, SlaveId, UpdateFields).

%% 需要修改奴隶主的记录和奴隶记录
grab_a_slave(SlaveOwnerId, Pos, SlaveId) ->
	FieldIndex = get_cage_field_index_by_pos(Pos),
	update_slave_owner_elements(SlaveOwnerId, [{FieldIndex, SlaveId}]),

	UpdateFields = [{#slave.slave_owner, SlaveId},
					{#slave.taxes, 0},
					{#slave.end_time, util:unixtime() + ?SLAVE_EXPIRE_TIME}],
	gen_cache:update_element(?SLAVE_CACHE_REF, SlaveId, UpdateFields).

open_cage(SlaveOwnerId, Pos) ->
	FieldIndex = get_cage_field_index_by_pos(Pos),
	update_slave_owner_elements(SlaveOwnerId, [{FieldIndex, ?CAGE_OPENED}]).
	
get_cage_field_index_by_pos(Pos) ->
	case Pos of
		1 -> #slave_owner.slave1;
		2 -> #slave_owner.slave2;
		3 -> #slave_owner.slave3;
		4 -> #slave_owner.slave4;
		5 -> #slave_owner.slave5;
		6 -> #slave_owner.slave6
	end.

increase_slave_work_times(SlaveOwnerId, OldWorkTimes) ->
	UpdateFields = [{#slave_owner.work_times, OldWorkTimes + 1},
					{#slave_owner.next_time, util:unixtime() + ?WORK_CD}],
	update_slave_owner_elements(SlaveOwnerId, UpdateFields).
%% =========================================================================
%% ====================== end ==============================================

clean_work_cd(SlaveownerId)->
	SlaveOwnerRec = get_slave_owner_rec(SlaveownerId),
	Now = util:unixtime(),
	UpdateFields = [{#slave_owner.next_time, 0}, {#slave_owner.update_time, Now}],
	update_slave_owner_elements(SlaveOwnerRec#slave_owner.gd_accountId, UpdateFields).
	

