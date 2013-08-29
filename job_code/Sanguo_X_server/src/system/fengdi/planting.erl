-module (planting).

-include ("common.hrl").

-compile(export_all).

is_function_opened(_PlayerId) ->
	%% TO-DO: Add level check to determinate wether plant is opened
	true.

open_land(PlayerId, LandId) ->
	Ret = case fengdi_db:get_land(PlayerId, LandId) of
		[] ->
			{OfficialRequire, VipRequire} = data_fengdi:get_open_land_require(LandId),
			case OfficialRequire =< mod_official:get_official_position(PlayerId) of
				true ->	
					case mod_vip:check_vip(PlayerId, VipRequire) of
						true ->
							Cost = data_fengdi:get_open_land_cost(LandId),
							case mod_economy:check_bind_gold(PlayerId, Cost) of
								true -> 
									true;
								false ->
									{false, ?ERR_NOT_ENOUGH_GOLD}
							end;
						false ->
							{false, ?ERR_NOT_ENOUGH_VIP_LEVEL}
					end;
				false ->
					{false, ?ERR_NOT_ENOUGH_GUAN_ZHI}
			end;
		_ -> 
			{false, ?ERR_UNKNOWN}
	end,
	case Ret of
		true ->
			LandRec = #land{key = {PlayerId, LandId}},
			fengdi_db:insert_land(LandRec),
			CostGold = data_fengdi:get_open_land_cost(LandId),
			mod_economy:use_bind_gold(PlayerId, CostGold, ?GOLD_OPEN_LAND),
			{true, LandRec};
		_ ->
			Ret
	end.

planting_seed(PlayerId, LandId, SeedType, RoleId) ->
	LandRec = fengdi_db:get_land(PlayerId, LandId),
	case LandRec of
		[] ->
			{false, ?ERR_UNKNOWN};
		_ ->
			LeftCd = get_left_cd(LandRec#land.cd_time),
			case (LandRec#land.state == ?PLANTING_NO) andalso 
				 (LeftCd =< 0) of
				true ->
					%% 获取对应类型种子的当前品质，用完后就立刻回原
					SeedQuality = fengdi_db:get_current_seed_quality(PlayerId, SeedType),
					fengdi_db:reset_current_seed_quality(PlayerId, SeedType),
					UpdateFields = [{#land.state, ?PLANTING_MATURE}, 
									{#land.seed_type, SeedType},
									{#land.seed_quality, SeedQuality},
									{#land.seed_data, RoleId}],
					fengdi_db:update_land_elements(LandRec#land.key, UpdateFields),
					NewLandRec = LandRec#land{
										state        = ?PLANTING_MATURE,
										seed_type    = SeedType,
										seed_quality = SeedQuality,
										seed_data    = RoleId},
					{true, NewLandRec};
				false ->
					{false, ?ERR_UNKNOWN}
			end
	end.

refresh_seed_quality(PlayerId, SeedType) ->
	SeedQuality = fengdi_db:get_current_seed_quality(PlayerId, SeedType),
	case SeedQuality of
		?SEED_QUALITY_5 -> 
			{false, ?ERR_UNKNOWN};
		_ ->
			CostGold = data_system:get(6),
			case mod_economy:check_and_use_bind_gold(PlayerId, CostGold, ?GOLD_REFRESH_SEED) of
				false ->
					{false, ?ERR_NOT_ENOUGH_GOLD};
				true ->
					case refresh_seed(SeedQuality) of
						true ->
							SeedQuality1 = SeedQuality + 1,
							fengdi_db:set_current_seed_quality(PlayerId, SeedType, SeedQuality1);
						false ->
							SeedQuality1 = SeedQuality
					end,
					{true, SeedQuality1}
			end
	end.

get_seed_result(PlayerId, LandId) ->
	LandRec = fengdi_db:get_land(PlayerId, LandId),
	case LandRec of
		[] ->
			{false, ?ERR_UNKNOWN};
		_ ->
			case LandRec#land.state of
				?PLANTING_MATURE ->
					send_seed_award(LandRec),
					Cd = get_waiting_cd() + util:unixtime(),
					UpdateFields = [{#land.state, ?PLANTING_NO},
									{#land.cd_time, Cd}],
					fengdi_db:update_land_elements(LandRec#land.key, UpdateFields),
					true;
				?PLANTING_NO ->
					{false, ?ERR_UNKNOWN}
			end
	end.

clean_planting_cd(PlayerId, LandId) ->
	LandRec = fengdi_db:get_land(PlayerId, LandId),
	LeftCd = get_left_cd(LandRec#land.cd_time),
	case LeftCd > 0 of
		true ->
			GoldCost = get_clean_cd_cost(LeftCd),
            ?INFO(land,"get clear cd cost is ~w",[GoldCost]),
			case mod_economy:check_and_use_bind_gold(PlayerId, GoldCost, ?GOLD_CLEAN_PLANTING_CD) of
				false ->
					{false, ?ERR_NOT_ENOUGH_GOLD};
				true ->
					UpdateFields = [{#land.state, ?PLANTING_NO},
									{#land.cd_time, 0}],
					fengdi_db:update_land_elements(LandRec#land.key, UpdateFields),
					true
			end;
		false ->
			true
	end.

ifCanWater(OperatorId,OwnerId) ->
	IfCanWaterBy2 = checkIfCanWater(OperatorId,OwnerId),
    IfCanWaterBy50 = checkWaterTimes(OperatorId),
    case IfCanWaterBy2 of
		true ->
			[#water{count=Count}]=gen_cache:lookup(?GEN_CACHE_ETS_WATER, {OperatorId,OwnerId}),
            gen_cache:update_element(?GEN_CACHE_ETS_WATER, {OperatorId,OwnerId}, [{#water.count, Count-1}]);
		false ->
			false
	end,
	case IfCanWaterBy50 of 
		true ->
			[#waterCounter{waterCount = WaterCount}] = gen_cache:lookup(?WATER_COUNTER_REF, OperatorId),
			gen_cache:update_element(?WATER_COUNTER_REF, OperatorId, [{#waterCounter.waterCount,WaterCount-1}]);
		false->
			false
	end,
	case IfCanWaterBy2 and IfCanWaterBy50 of
		true->1;
		false->0
	end.


watering(OperatorId,OwnerId,LandId) ->
	LandRec = fengdi_db:get_land(OwnerId, LandId),
	case LandRec of
		[] ->
			{false, ?ERR_UNKNOWN};
		_ ->
            case checkIfCanWater(OperatorId,OwnerId) of
                false->
                    ?INFO(land,"error to water Operator is ~w,Owner is ~w, landid is ~w",
                          [OperatorId,OwnerId,LandId]),
                    send_error2_to_client(OperatorId),
                    {false, ?ERR_FENGDI_WATER2};
                true->
                    ?INFO(land,"check water time's per player"),
                    case checkWaterTimes(OperatorId) of
                        true->
                            fengdi_db:increase_watering_times(OwnerId, LandId),
                            true;
                        false->
                            send_error50_to_client(OperatorId),
                            {false, ?ERR_FENGDI_WATER50}
                    end
                            
			end
	end.

%% 校验：玩家一天最多浇水50次
checkWaterTimes(PlayerId)->
    %% 判断上次浇水是否是同一天，不是同一天讲count置为0，更新时间,返回true；
    %% 是同一天则判断则判断，大于等于50返回false，小与50返回true
    case gen_cache:lookup(?WATER_COUNTER_REF, PlayerId) of
        []->
            ?INFO(land,"the player ~w first water .",[PlayerId]),
            gen_cache:insert(?WATER_COUNTER_REF,#waterCounter{waterCount=1,lastWaterTime=util:unixtime(),
                playeId=PlayerId}),
            true;
        [#waterCounter{lastWaterTime=LastWaterTimes,waterCount=WaterCount}]->
            case util:check_other_day(LastWaterTimes) of
                true ->
                    ?INFO(land,"the last water time is yestoday,playeridis ~w",[PlayerId]),
                    gen_cache:update_element(?WATER_COUNTER_REF, PlayerId, [{#waterCounter.waterCount,
                         1},{#waterCounter.lastWaterTime, util:unixtime()}]),
                    true;
                false ->
                    ?INFO(land,"the player ~w water 2th+ times,waterCount is ~w",[PlayerId,WaterCount]),
                    case WaterCount<?MAX_WATER_PERDAY of
                        true->
                            gen_cache:update_element(?WATER_COUNTER_REF, PlayerId, [{#waterCounter.waterCount,
                                WaterCount+1}]),
                            true;
                        false->
                            false
                    end
            end
    end.
            
get_friends_water_info(PlayerId) ->
	FriendRecList = mod_relationship:get_all_friend_list(PlayerId),
	get_friends_water_info_help(PlayerId,FriendRecList, []).

get_friends_water_info_help(_PlayerId, [], Result) -> Result;
get_friends_water_info_help(PlayerId,[FriendRec | Rest], Result) ->
	{_, FriendId} = FriendRec#friend.key,
	case is_function_opened(FriendId) of
		true ->
			HasCanWaterLand =  ifCanWater(PlayerId, FriendId),
			IsCanWater = case HasCanWaterLand of
				0->false;
				1->true
			end,
			Result1 = [{FriendId, FriendRec#friend.role_name, IsCanWater} | Result];
		false ->
			Result1 = Result
	end,
	get_friends_water_info_help(PlayerId, Rest, Result1).

has_can_water_land(PlayerId) ->
	has_can_water_land_help(fengdi_db:get_lands(PlayerId)).

has_can_water_land_help([]) -> false;
has_can_water_land_help([LandRec | Rest]) ->
	case LandRec#land.watering_times < ?FERTILITY_TIMES of
		true ->
			true;
		false ->
			has_can_water_land_help(Rest)
	end.
%% ============================================================================
%% ============================================================================
%% ============================================================================
%% 返回true表示刷新成功，否则失败
refresh_seed(SeedQuality) ->
	Rand = util:rand(1, 100),
	case SeedQuality of
		?SEED_QUALITY_1 -> (Rand >= 70);
		?SEED_QUALITY_2 -> (Rand >= 80);
		?SEED_QUALITY_3 -> (Rand >= 90);
		?SEED_QUALITY_4 -> (Rand >= 95)
	end.

%% 以秒为单位
get_waiting_cd() ->
	8*60*60.

%% 获取清种植等待cd的金币消耗
get_clean_cd_cost(LeftCd) ->
    ?INFO(land,"clear cd leftcd time is ~w",[LeftCd]),
	util:ceil(LeftCd / 120).

checkIfCanWater(OperatorId,OwnerId)->
    ?INFO(land,"player ~w water player ~w 's water",[OperatorId,OwnerId]),
    WaterRecord=gen_cache:lookup(?GEN_CACHE_ETS_WATER, {OperatorId,OwnerId}),
    case WaterRecord of
        []->
            gen_cache:insert(?GEN_CACHE_ETS_WATER,#water{key={OperatorId,OwnerId},data = util:unixtime(),count=1}),
                true;
        [#water{data = Data, count = Count}]-> 
            case util:check_other_day(Data) of
                true->
                    gen_cache:update_element(?GEN_CACHE_ETS_WATER, {OperatorId,OwnerId},[{#water.data, util:unixtime()},
                        {#water.count,1}]),
                        true;
                false->
                    case Count>=2 of
                        true->
                            false;
                        false->
                            ?INFO(land,"player ~w the ~w times water player ~w's land",[OperatorId,Count,OwnerId]),
                            gen_cache:update_element(?GEN_CACHE_ETS_WATER, {OperatorId,OwnerId}, [{#water.count, Count+1}]),
                            true
                    end
            end
    end.

send_error2_to_client(OperatorId)->
    {ok, Packet} = pt_err:write(?ERR_FENGDI_WATER2),
    lib_send:send_by_id(OperatorId, Packet).

send_error50_to_client(OperatorId)->
    {ok, Packet} = pt_err:write(?ERR_FENGDI_WATER50),
    lib_send:send_by_id(OperatorId, Packet).
    
    

get_left_cd(LandCdTime) ->
	LeftCd = LandCdTime - util:unixtime(),
	case LeftCd < 0 of
		true -> 0;
		false -> LeftCd
	end.

send_seed_award(LandRec) ->
	{PlayerId, _LandId} = LandRec#land.key,
	OfficialPos = mod_official:get_official_position(PlayerId),
	SeedType    = LandRec#land.seed_type,
	SeedQuality = LandRec#land.seed_quality,
	Result      = data_fengdi:get_seed_result(SeedType, OfficialPos, SeedQuality),
	case LandRec#land.watering_times >= ?FERTILITY_TIMES of
		true -> Result1 = util:floor(Result * data_system:get(7));
		_ -> 	Result1 = Result
	end,
	case SeedType of
		?SEED_EXP ->
			mod_role:add_exp(PlayerId, {LandRec#land.seed_data, Result1}, ?EXP_FROM_PLANTING);
		?SEED_SILVER ->
			mod_economy:add_silver(PlayerId, Result1, ?SILVER_FROM_PLANTING)
	end.











