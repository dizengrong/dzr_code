-module (mod_slave).

-include ("common.hrl").

-compile(export_all).

get_slave_owner_detail_rec(SlaveId) ->
	SlaveRec = fengdi_db:get_slave_rec(SlaveId),
	case SlaveRec#slave.slave_owner == 0 of
		true ->
			#slave_owner_detail{};
		false ->
			MainRoleRec = role_base:get_main_role_rec(SlaveRec#slave.slave_owner),

			#slave_owner_detail{
				id    = SlaveRec#slave.slave_owner,
				name  = MainRoleRec#role.gd_name,
				level = MainRoleRec#role.gd_roleLevel
			}
	end.

get_slaves(PlayerId) ->
	SlaveOwnerRec = fengdi_db:get_slave_owner_rec(PlayerId),
	get_slaves_detail_info(SlaveOwnerRec).
	

get_slaves_detail_info(SlaveOwnerRec) ->
	SlavesId = [SlaveOwnerRec#slave_owner.slave1,
			    SlaveOwnerRec#slave_owner.slave2,
			    SlaveOwnerRec#slave_owner.slave3,
			    SlaveOwnerRec#slave_owner.slave4,
			    SlaveOwnerRec#slave_owner.slave5,
			    SlaveOwnerRec#slave_owner.slave6],
	get_slaves_detail_info(SlavesId, 1, util:unixtime(), []).

%% 在获取奴隶主的奴隶详细信息时，若对应位置上的奴隶id大于0，
%% 则说明该位置是有奴隶的，如果是过期的奴隶，则重置对应笼子里的id为?CAGE_OPENED
%% 这样在下次来执行这个操作时，不会重复出现过期奴隶的弹出信息了
get_slaves_detail_info([], _Pos, _Now, SlaveDetailList) -> SlaveDetailList;
get_slaves_detail_info([?CAGE_NOT_OPEN | Rest], Pos, Now, SlaveDetailList) -> 
	get_slaves_detail_info(Rest, Pos + 1, Now, SlaveDetailList);
get_slaves_detail_info([?CAGE_OPENED | Rest], Pos, Now, SlaveDetailList) ->
	get_slaves_detail_info(Rest, Pos + 1, Now, SlaveDetailList);
get_slaves_detail_info([SlaveId | Rest], Pos, Now, SlaveDetailList) ->
	SlaveRec = fengdi_db:get_slave_rec(SlaveId),
	case SlaveRec#slave.end_time =< Now of
		true ->
			fengdi_db:reset_cage(SlaveRec#slave.slave_owner, Pos);
		false ->
			ok
	end,
	MainRoleRec = role_base:get_main_role_rec(SlaveId),
	SlaveDetailRec = #slave_detail{
						pos         = Pos,
						slave_id    = SlaveId,
						slave_level = MainRoleRec#role.gd_roleLevel,
						slave_name  = MainRoleRec#role.gd_name,
						end_time    = SlaveRec#slave.end_time,
						taxes       = SlaveRec#slave.taxes
	},
	SlaveDetailList1 = [SlaveDetailRec | SlaveDetailList],
	get_slaves_detail_info(Rest, Pos + 1, Now, SlaveDetailList1).


open_cage(PlayerId, Pos) ->
	{OfficialRequire, VipRequire} = data_fengdi:get_open_land_require(Pos),
	case OfficialRequire =< mod_official:get_official_position(PlayerId) of
		true ->	
			case mod_vip:check_vip(PlayerId, VipRequire) of
				true ->
					fengdi_db:open_cage(PlayerId, Pos);
				false ->
					{false, ?ERR_NOT_ENOUGH_VIP_LEVEL}
			end;
		false ->
			{false, ?ERR_NOT_ENOUGH_GUAN_ZHI}
	end.

battle_for_win_slave(PlayerId, CompanionId) ->
	battle_for_win_slave(PlayerId, CompanionId, 0).
battle_for_win_slave(PlayerId, CompanionId, _FriendId) ->
	case has_free_cage(PlayerId) of
		true ->
			case slave_mirror:lock_player(CompanionId) of
				true ->
					?INFO(slave,"check free cage2"),
					test_pvp(PlayerId, CompanionId),
					%% call_back: mod_fegndi:battle_for_slave_cb(_, _, {CompanionId, FriendId})
					?ERR(slave, "To add battl startup code"),
					{false, ?ERR_UNKNOWN};
				false ->
					{false, ?ERR_LOCK_FAILED}
			end;
		false ->
			{false, ?ERR_NO_FREE_CAGE}
	end.

test_pvp(ID1, ID2) ->
	{NID2, MerList} = 
		case mod_player:is_online(ID2) of
			{true, _} -> {ID2, []};
			_ -> {undefined, mod_role:get_on_battle_list(ID2)} 
		end,
	
	Start = 
		#battle_start {
			mod       = pvp,
		 	type      = 0,     		%% 
			att_id    = ID1,   		%% Attacker's ID
			att_mer   = [],    		%% Attacker's mercenary list
			def_id    = NID2,  		%% Defender's ID
			def_mer   = MerList,    %% Defender's Mercenary list
			maketeam  = false, 		%% true | false
			checklist = [],    		%% [check_specp()]
			caller    = [],    		%% caller module's name or pid
			callback  = {mod_fengdi,battle_for_slave_cb,{ID1,ID2}}
					  },
	battle:start(Start).

%% 为好友而战
%% 1：若好友没有被占领，则是与好友进行战斗并抓好友为奴隶
%% 2：若好友被占领了，则是与占领好友的奴隶主进行战斗兵抓好友为奴隶
battle_for_friend(PlayerId, FriendId) ->
	case mod_relationship:is_friend(PlayerId, FriendId) of
		true ->
			SlaveRec = fengdi_db:get_slave_rec(FriendId),
			case SlaveRec#slave.slave_owner > 0 of
				true ->
					battle_for_win_slave(PlayerId, SlaveRec#slave.slave_owner, FriendId);
				false ->
					battle_for_win_slave(PlayerId, FriendId)
			end;
		false ->
			{false, ?ERR_UNKNOWN}
	end.


has_free_cage(PlayerId) ->
	SlaveOwnerRec = fengdi_db:get_slave_owner_rec(PlayerId),
	(SlaveOwnerRec#slave_owner.slave1 == ?CAGE_OPENED orelse
	 SlaveOwnerRec#slave_owner.slave2 == ?CAGE_OPENED orelse
	 SlaveOwnerRec#slave_owner.slave3 == ?CAGE_OPENED orelse
	 SlaveOwnerRec#slave_owner.slave4 == ?CAGE_OPENED orelse
	 SlaveOwnerRec#slave_owner.slave5 == ?CAGE_OPENED orelse
	 SlaveOwnerRec#slave_owner.slave6 == ?CAGE_OPENED ).

grab_a_slave(SlaveOwnerId, SlaveId) ->
	grab_a_slave(SlaveOwnerId, SlaveId, 0).
%% 如果是从某个奴隶主那抢来的奴隶的话，就设置FromSlaveOwnerId为奴隶主的id
grab_a_slave(SlaveOwnerId, SlaveId, FromSlaveOwnerId) ->
	SlaveOwnerRec = fengdi_db:get_slave_owner_rec(SlaveOwnerId),
	case find_next_free_cage(SlaveOwnerRec) of
		0 ->
			?ERR(slave, "Player has no free cage"),
			{false, ?ERR_NO_FREE_CAGE};
		Pos ->
			fengdi_db:grab_a_slave(SlaveOwnerId, Pos, SlaveId),
			case FromSlaveOwnerId > 0 of
				true ->
					case find_slave_cage(FromSlaveOwnerId, SlaveId) of
						0 -> 
							%% 这种情况是有可能发生的，比如战斗之前是的，
							%% 但战斗过后该奴隶就过期了
							?ERR(slave, "Slave owner ~w has no slave of id: ~w", []);
						SlavePos ->
							%% 奴隶被抢了
							slave_timer:cancle_timer({slave_expire, SlaveId}),
							fengdi_db:reset_cage(FromSlaveOwnerId, SlavePos)
					end;
				false ->
					skip
			end,
			slave_timer:add_timer(?SLAVE_EXPIRE_TIME, 
								  {slave_expire, SlaveId}, 
								  {slave_expire, SlaveOwnerId, Pos, SlaveId}),
			true
	end.

find_next_free_cage(SlaveOwnerRec) ->
	if
		SlaveOwnerRec#slave_owner.slave1 == ?CAGE_OPENED ->
			1;
		SlaveOwnerRec#slave_owner.slave2 == ?CAGE_OPENED ->
			2;
		SlaveOwnerRec#slave_owner.slave3 == ?CAGE_OPENED ->
			3;
		SlaveOwnerRec#slave_owner.slave4 == ?CAGE_OPENED ->
			4;
		SlaveOwnerRec#slave_owner.slave5 == ?CAGE_OPENED ->
			5;
		SlaveOwnerRec#slave_owner.slave6 == ?CAGE_OPENED ->
			6;					
		true -> 
			0
	end.

find_slave_cage(SlaveOwnerId, SlaveId) ->
	SlaveOwnerRec = fengdi_db:get_slave_owner_rec(SlaveOwnerId),
	if
		SlaveOwnerRec#slave_owner.slave1 == SlaveId ->
			1;
		SlaveOwnerRec#slave_owner.slave2 == SlaveId ->
			2;
		SlaveOwnerRec#slave_owner.slave3 == SlaveId ->
			3;
		SlaveOwnerRec#slave_owner.slave4 == SlaveId ->
			4;
		SlaveOwnerRec#slave_owner.slave5 == SlaveId ->
			5;
		SlaveOwnerRec#slave_owner.slave6 == SlaveId ->
			6;					
		true -> 
			0
	end.

battle_for_freedom(SlaveId) ->
	SlaveRec = fengdi_db:get_slave_rec(SlaveId),
	case SlaveRec#slave.slave_owner of
		0 ->
			{false, ?ERR_ALREADY_FREEDOM};
		_SlaveOwnerId ->
			%% TO-DO: 增加战斗启动的代码
			%% call_back: mod_fegndi:battle_for_freedom_cb(_, _, {SlaveOwnerId})
			?ERR(slave, "To add battl startup code"),
			{false, ?ERR_UNKNOWN}
	end.

%% 战斗自由了
battle_win_freedom(SlaveId, SlaveOwnerId) ->
	fengdi_db:free_slave(SlaveId),
	slave_timer:cancle_timer({slave_expire, SlaveId}),
	case find_slave_cage(SlaveOwnerId, SlaveId) of
		0 ->
			?ERR(slave, "Slave ~w already freedom", [SlaveId]);
		SlavePos ->
			fengdi_db:reset_cage(SlaveOwnerId, SlavePos)
	end.

%% 奴隶主主动释放
free_slave(SlaveOwnerId, SlavePos) ->
	fengdi_db:reset_cage(SlaveOwnerId, SlavePos),
	SlaveId = fengdi_db:get_slave_by_cage(SlaveOwnerId, SlavePos),
	case SlaveId > 0 of
		true ->
			fengdi_db:free_slave(SlaveId),
			slave_timer:cancle_timer({slave_expire, SlaveId});
		false ->
			?ERR(slave, "Slave ~w already freedom", [SlaveId])
	end.

slave_work(SlaveOwnerId, WorkType) ->
	SlaveOwnerRec    = fengdi_db:get_slave_owner_rec(SlaveOwnerId),
	HasWorkTimesLeft = (SlaveOwnerRec#slave_owner.work_times < ?MAX_WORK_TIMES),
	IsInCd = (SlaveOwnerRec#slave_owner.next_time =< util:unixtime()),
	Ret = case HasWorkTimesLeft andalso IsInCd of
		true ->
			case get_slave_work_profit(SlaveOwnerRec, WorkType) of
				A when A > 0 ->
					{true, A};
				_ ->
					{false, ?ERR_NO_SLAVES}
			end;
		false ->
			{false, ?ERR_UNKNOWN}
	end,
	case Ret of
		{true, Amount} ->
			case WorkType of
				?WORK_HUNT ->
					mod_economy:add_silver(SlaveOwnerId, Amount, ?SILVER_FROM_SLAVE_WORK);
				?WORK_FARM ->
					mod_economy:add_popularity(SlaveOwnerId, Amount, ?POPULARITY_FROM_SLAVE_WORK);
				?WORK_FEED_HORSE ->
					mod_role:add_exp_to_main_role(SlaveOwnerId, Amount, ?EXP_FROM_SLAVE_WORK)
			end,
			fengdi_db:increase_slave_work_times(SlaveOwnerId, SlaveOwnerRec#slave_owner.work_times);
		_ ->
			skip
	end,
	Ret.


get_slave_work_profit(SlaveOwnerRec, WorkType) ->
	get_slave_work_profit([SlaveOwnerRec#slave_owner.slave1,
						   SlaveOwnerRec#slave_owner.slave2,
						   SlaveOwnerRec#slave_owner.slave3,
						   SlaveOwnerRec#slave_owner.slave4,
						   SlaveOwnerRec#slave_owner.slave5,
						   SlaveOwnerRec#slave_owner.slave6], WorkType, 0).

get_slave_work_profit([], _WorkType, Amount) -> Amount;
get_slave_work_profit([SlaveId | Rest], WorkType, Amount) ->
	case SlaveId > 0 of
		true ->
			SlaveRoleRec = role_base:get_main_role_rec(SlaveId),
			SlaveLv      = SlaveRoleRec#role.gd_roleLevel,
			Amount1      = data_fengdi:get_slave_work_profit(WorkType, SlaveLv) + Amount;
		_ ->
			Amount1 = Amount
	end,
	get_slave_work_profit(Rest, WorkType, Amount1).


get_num_of_slaves(SlaveOwnerRec) ->
	Pos1 = if SlaveOwnerRec#slave_owner.slave1 > 0 -> 1; true -> 0 end,
	Pos2 = if SlaveOwnerRec#slave_owner.slave2 > 0 -> 1; true -> 0 end,
	Pos3 = if SlaveOwnerRec#slave_owner.slave3 > 0 -> 1; true -> 0 end,
	Pos4 = if SlaveOwnerRec#slave_owner.slave4 > 0 -> 1; true -> 0 end,
	Pos5 = if SlaveOwnerRec#slave_owner.slave5 > 0 -> 1; true -> 0 end,
	Pos6 = if SlaveOwnerRec#slave_owner.slave6 > 0 -> 1; true -> 0 end,

	Pos1 + Pos2 + Pos3 + Pos4 + Pos5 + Pos6.

clean_work_cd(SlaveOwnerId) ->
	SlaveOwnerRec = fengdi_db:get_slave_owner_rec(SlaveOwnerId),
	GoldNeed = get_clean_work_cd_cost(SlaveOwnerRec#slave_owner.next_time),
	case mod_economy:check_and_use_bind_gold(SlaveOwnerId, GoldNeed, ?GOLD_CLEAN_WORK_CD) of
		true ->
			fengdi_db:clean_work_cd(SlaveOwnerId),
			true;
		false ->
			{false, ?ERR_NOT_ENOUGH_GOLD}
	end.


get_clean_work_cd_cost(NextCanWorkTime) ->
	LeftCd = NextCanWorkTime - util:unixtime(),
	((15 * LeftCd) div ?WORK_CD).
