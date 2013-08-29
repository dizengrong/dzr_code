-module (mod_fengdi).

-include("common.hrl").


-export([start_link/1, watering/3]).

-export([client_get_lands/1, client_get_lands/2, client_open_land/2, client_planting/4,
		 client_refresh_seed_quality/2, client_get_seed_result/2,
		 client_clean_planting_cd/2, client_get_slaves/1, client_open_cage/2,
		 client_refresh_non_slaves/1, client_battle_non_slave/2,
		 client_battle_for_friend/2, client_battle_for_freedom/1,
		 client_free_slave/2, client_slave_work/2, client_clean_work_cd/1,
		 gain_taxes/2, client_get_friends_water_info/1,client_get_seed_info/1]).


%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% internal export
-export([client_get_lands2/2, client_open_land2/2, client_planting2/2, 
		 client_refresh_seed_quality2/2, client_get_seed_result2/2, 
		 client_clean_planting_cd2/2, client_get_slaves2/2,
		 client_open_cage2/2, client_refresh_non_slaves2/2,
		 client_battle_non_slave2/2, battle_for_slave_cb/3, battle_for_slave_cb2/2,
		 client_battle_for_friend2/2, battle_for_freedom_cb/3,
		 client_battle_for_freedom2/2, battle_for_freedom_cb2/2,
		 client_free_slave2/2, client_slave_work2/2,
		 client_clean_work_cd2/2, client_get_friends_water_info2/2,
		 gm_grap_a_slave/2]).

-record(fengdi_state, {
		player_id = 0,
		non_slaves = []		%% 当前记录的可以挑战的非奴隶玩家id的list
	}).

start_link({PlayerId})->
	gen_server:start_link(?MODULE, [PlayerId], []).

%% ===========================================================
%% ====================== 种植 ===============================
%% 客户端获取自己的土地数据
client_get_lands(PlayerId) ->
    ?INFO(land,"call get self fengdi,PlayerId :~w",[PlayerId]),
	PS = mod_player:get_player_status(PlayerId),
	gen_server:cast(PS#player_status.fengdi_pid, 
					{request, client_get_lands2, [PlayerId]}).

%% 客户端获取别人的土地数据
client_get_lands(PlayerId, OtherPlayerId) ->
	LandRecList = fengdi_db:get_lands(OtherPlayerId),
    PlayerName = mod_account:get_player_name(OtherPlayerId),
    EmployID = mod_role:get_main_role_employed_id(OtherPlayerId),
    ?INFO(land,"client get land by EmployId ~w,PlayerName ~w",[EmployID,PlayerName]),
	{ok, Packet} = pt_22:write(22000, {OtherPlayerId, LandRecList,PlayerName,EmployID}),
	lib_send:send_by_id(PlayerId, Packet).

%% 客户端请求打开一块土地
client_open_land(PlayerId, LandId) ->
	PS = mod_player:get_player_status(PlayerId),
	gen_server:cast(PS#player_status.fengdi_pid, 
					{request, client_open_land2, [PlayerId, LandId]}).

%% 客户端请求种植种子
client_planting(PlayerId, LandId, SeedType, RoleId) ->
	PS = mod_player:get_player_status(PlayerId),
	gen_server:cast(PS#player_status.fengdi_pid, 
					{request, client_planting2, [PlayerId, LandId, SeedType, RoleId]}).

%% 客户端请求刷新种子的品质
client_refresh_seed_quality(PlayerId, SeedType) ->
	PS = mod_player:get_player_status(PlayerId),
	gen_server:cast(PS#player_status.fengdi_pid, 
					{request, client_refresh_seed_quality2, [PlayerId, SeedType]}).

%% 客户端请求获取种子成熟的果实
client_get_seed_result(PlayerId, LandId) ->
	PS = mod_player:get_player_status(PlayerId),
	gen_server:cast(PS#player_status.fengdi_pid, 
					{request, client_get_seed_result2, [PlayerId, LandId]}).

%% 客户端请求清除种植等待cd
client_clean_planting_cd(PlayerId, LandId) ->
	PS = mod_player:get_player_status(PlayerId),
	gen_server:cast(PS#player_status.fengdi_pid, 
					{request, client_clean_planting_cd2, [PlayerId, LandId]}).

%% %% 客户端请求清除种植等待cd
client_get_friends_water_info(PlayerId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_get_friends_water_info2, [PlayerId]}).

%% 给土地浇水，浇水成功返回true，否则返回false
%% 只能好友模块调用这个方法来给玩家的好友PlayerId的土地LandId浇水
watering(PlayerId, FriendId, LandId) ->
	%% TO-DO: 好友模块要添加处理，在这里或是其他地方
		
	case planting:watering(PlayerId,FriendId, LandId) of
        true ->
			?INFO(land, "add watering times of friend ~w land ~w successfully", 
				  [FriendId, LandId]),
            PlayerLevel = mod_role:get_main_level(PlayerId),
            Amount=data_fengdi:get_watering_profit(PlayerLevel),
            mod_economy:add_silver(PlayerId, Amount, ?SILVER_FROM_WATERING),
            ?INFO(land, "add silver ~w to player ~w(level is ~w) for water",[Amount,PlayerId,PlayerLevel]),
			send_silverInfo_to_client(PlayerId,FriendId,Amount),
            send_lands_to_client(PlayerId, FriendId),
			true;
		{false, ErrCode} ->
			?ERR(land, "player watering for friend ~w of land ~w failed, error code: ~w",
				 [FriendId, LandId, ErrCode]),
			false
	end.
%% 客户端请求种子信息
client_get_seed_info(PlayerId)->
    ?INFO(land,"client ~w get seed info",[PlayerId]),
    send_seed_quality_to_client(PlayerId).
%% ===========================================================
%% ====================== end ================================

%% ===========================================================
%% ====================== 奴隶 ===============================
client_get_slaves(PlayerId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_get_slaves2, [PlayerId]}).

client_open_cage(PlayerId, Pos) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_open_cage2, [PlayerId, Pos]}).

%% 请求刷新系统筛选的非奴隶
client_refresh_non_slaves(PlayerId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_refresh_non_slaves2, [PlayerId]}).

%% 打系统筛选的非奴隶玩家
client_battle_non_slave(PlayerId, NonSlaveId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_battle_non_slave2, [PlayerId, NonSlaveId]}).

%% 抓好友为奴隶或是为好友而战
client_battle_for_friend(PlayerId, FriendId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_battle_for_friend2, [PlayerId, FriendId]}).

battle_for_slave_cb(PlayerStatus, BattleResult, Args) ->
	gen_server:cast(PlayerStatus#player_status.fengdi_pid, 
					{request, battle_for_slave_cb2, [PlayerStatus#player_status.id, BattleResult, Args]}).

client_battle_for_freedom(PlayerId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_battle_for_freedom2, [PlayerId]}).

battle_for_freedom_cb(PlayerId, BattleResult, Args) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, battle_for_freedom_cb2, [PlayerId, BattleResult, Args]}).

client_free_slave(PlayerId, Pos) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_free_slave2, [PlayerId, Pos]}).

client_slave_work(PlayerId, WorkType) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_slave_work2, [PlayerId, WorkType]}).

client_clean_work_cd(PlayerId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_clean_work_cd2, [PlayerId]}).

%% 当玩家得到押镖银币收益时，判断他是否有奴隶主，然后确定是否要交税金
%% 返回奴隶所得的银币
gain_taxes(PlayerId, Silver) ->
	SlaveRec = fengdi_db:get_slave_rec(PlayerId),
	case SlaveRec#slave.slave_owner of
		SlaveOwnerId when SlaveOwnerId > 0 ->
			OwnerGot = util:floor(Silver*0.05),
			mod_economy:add_silver(SlaveOwnerId, OwnerGot, ?SILVER_FROM_SLAVE_TAX),
			?INFO(slave, "Slave ~w pay taxes silver ~w to his owner ~w", 
				  [PlayerId, OwnerGot, SlaveOwnerId]),
			Silver - OwnerGot;
		_ ->
			Silver
	end.

gm_grap_a_slave(PlayerId, Nickname) ->
	case mod_account:get_account_id_by_name(Nickname) of
		false ->
			{false, "No this player"};
		{true, OtherPlayerId} ->
			SlaveRec = fengdi_db:get_slave_rec(OtherPlayerId),
			case SlaveRec#slave.slave_owner == 0 of
				true ->
					case mod_slave:grab_a_slave(PlayerId, OtherPlayerId) of
						true ->
							send_slaves_to_client(PlayerId),
							true;
						{false, ErrCode} ->
							mod_err:send_err_by_id(PlayerId, ErrCode),
							{false, "failed"}
					end;
				false ->
					{false, "Player is already a slave"}
			end
	end.
%% ===========================================================
%% ====================== end ================================


%% =================================================================
%% =================================================================
init([PlayerId]) ->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, PlayerId),
	mod_player:update_module_pid(PlayerId, ?MODULE, self()),
    {ok, #fengdi_state{player_id = PlayerId}}.

handle_cast({request, Action, Args}, State) ->
	NewState = ?MODULE:Action(State, Args),
	{noreply, NewState}.

handle_call({request, Action, Args}, _From, State) ->
	{NewState, Reply} = ?MODULE:Action(State, Args),
	{reply, Reply, NewState}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(Reason, State) ->
	?INFO(fengdi, "~w gen_server terminate, reason: ~w, state: ~w", 
		  [?MODULE, Reason, State]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.		

%% =================================================================
%% =================================================================
send_lands_to_client(PlayerId) ->
	send_lands_to_client(PlayerId, PlayerId).
send_lands_to_client(SendToWho, WhosLands) ->
	LandRecList = fengdi_db:get_lands(WhosLands),
    PlayerName = mod_account:get_player_name(WhosLands),
    EmployID = mod_role:get_main_role_employed_id(WhosLands),
    ?INFO(land,"client get land by EmployId ~w,PlayerName ~w",[EmployID,PlayerName]),
    {ok, Packet} = pt_22:write(22000, {WhosLands, LandRecList,PlayerName,EmployID}),
	lib_send:send_by_id(SendToWho, Packet).

send_silverInfo_to_client(PlayerId,OwnerId,Amount)->
	IsCanWater = planting:ifCanWater(PlayerId,OwnerId),
    {ok,Packet} = pt_22:write(22007, {Amount,OwnerId,IsCanWater}),
        lib_send:send_by_id(PlayerId, Packet).


send_seed_quality_to_client(PlayerId) ->
	SeedsQuality = fengdi_db:get_current_seed_quality(PlayerId),

	{ok, Packet} = pt_22:write(22003, SeedsQuality),
	lib_send:send_by_id(PlayerId, Packet).

client_get_lands2(State, [PlayerId]) ->
    ?INFO(dealfengdi,"PlayerId :~w get self fengdi,Pid is ~w",[PlayerId,self()]),
	send_lands_to_client(PlayerId),
	State.

client_open_land2(State, [PlayerId, LandId]) ->
    
	case planting:open_land(PlayerId, LandId) of
		{true, _LandRec} ->
			?INFO(land, "open land ~w successfully", [LandId]),
			send_lands_to_client(PlayerId);
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode)
	end,
	
	State.

client_planting2(State, [PlayerId, LandId, SeedType, RoleId]) ->
	case planting:planting_seed(PlayerId, LandId, SeedType, RoleId) of
		{true, _LandRec} ->
			?INFO(land, "planting seed on land ~w successfully, SeedType: ~w, RoleId: ~w", 
				  [LandId, SeedType, RoleId]),
			send_lands_to_client(PlayerId),
			send_seed_quality_to_client(PlayerId);
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode)
	end,
	
	State.	


client_refresh_seed_quality2(State, [PlayerId, SeedType]) ->
	case planting:refresh_seed_quality(PlayerId, SeedType) of
		{true, SeedQuality} ->
			?INFO(land, "refresh seed of type ~w successfully, SeedQuality: ~w", 
				  [SeedType, SeedQuality]),
			send_seed_quality_to_client(PlayerId);
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode)
	end,
	
	State.


client_get_seed_result2(State, [PlayerId, LandId]) ->
	case planting:get_seed_result(PlayerId, LandId) of
		true ->
			?INFO(land, "get seed result of land ~w successfully", [LandId]),
			send_lands_to_client(PlayerId);
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode)
	end,
	
	State.

client_get_friends_water_info2(State, [PlayerId]) ->
	FriendWaterInfoList = planting:get_friends_water_info(PlayerId),

	{ok, Packet} = pt_22:write(22006, FriendWaterInfoList),
	lib_send:send_by_id(PlayerId, Packet),

	State.

client_clean_planting_cd2(State, [PlayerId, LandId]) ->
	case planting:clean_planting_cd(PlayerId, LandId) of
		true ->
			?INFO(land, "clean cd of land ~w successfully", [LandId]),
			send_lands_to_client(PlayerId);
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode)
	end,
	
	State.


send_slaves_to_client(PlayerId) ->
	SlaveDetailList = mod_slave:get_slaves(PlayerId),
	SlaveOwnerDetailRec = mod_slave:get_slave_owner_detail_rec(PlayerId),
	
	{ok, Packet} = pt_22:write(22100, {PlayerId, SlaveOwnerDetailRec, SlaveDetailList}),
	lib_send:send_by_id(PlayerId, Packet).

client_get_slaves2(State, [PlayerId]) ->
	send_slaves_to_client(PlayerId),
	send_slave_work_info_to_client(PlayerId),
	
	State.

client_open_cage2(State, [PlayerId, Pos]) ->
	case mod_slave:open_cage(PlayerId, Pos) of
		true ->
			?INFO(slave, "open slave cage ~w successfully", [Pos]),
			send_slaves_to_client(PlayerId);
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode)
	end,
	State.

client_refresh_non_slaves2(State, [PlayerId]) ->
	NonSlaves = slave_mirror:get_non_slaves(),
	NonSlaveRecs = get_non_slaves_detail_list(NonSlaves),
	{ok, Packet} = pt_22:write(22102, NonSlaveRecs),
	lib_send:send_by_id(PlayerId, Packet),

	State#fengdi_state{non_slaves = NonSlaves}.

get_non_slaves_detail_list(NonSlaves) ->
	get_non_slaves_detail_list2(NonSlaves, []).


get_non_slaves_detail_list2([], NonSlaveRecs) -> NonSlaveRecs;
get_non_slaves_detail_list2([PlayerId | Rest], NonSlaveRecs) ->
	MainRoleRec = role_base:get_main_role_rec(PlayerId),
	NonSlaveRec = #non_slave_detail{
		id     = PlayerId,
		name   = MainRoleRec#role.gd_name,
		level  = MainRoleRec#role.gd_roleLevel,
		career = MainRoleRec#role.gd_careerID
	},
	get_non_slaves_detail_list2(Rest, [NonSlaveRec | NonSlaveRecs]).


client_battle_non_slave2(State, [PlayerId, NonSlaveId]) ->
	?INFO(slave,"battle begin"),
	Ret = case lists:member(NonSlaveId, State#fengdi_state.non_slaves) of
		true ->
			case mod_slave:battle_for_win_slave(PlayerId, NonSlaveId) of
				true ->
					?INFO(slave, "player will battle with non slave: ~w", [NonSlaveId]),
					true;
				_ ->
					skip
			end;
		false ->
			?ERR(slave, "Current can battle slaves are: ~w, but client select ~w",
				 [State#fengdi_state.non_slaves, NonSlaveId]),
			{false, ?ERR_UNKNOWN}
	end,
    ?INFO(slave,"battle begin ~w",[Ret]),
	case Ret of
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode);
		_ -> 
			skip
	end,
	State.

battle_for_slave_cb2(State, [PlayerId, BattleResultRec, {CompanionId, FriendId}]) ->
	case BattleResultRec#battle_result.is_win of
		false ->
			?INFO(slave, "Battle for slave lose, CompanionId: ~w, FriendId: ~w",
				  [CompanionId, FriendId]);
		true ->
			case FriendId > 0 of
				true ->
					SlaveId = FriendId,
					mod_slave:grab_a_slave(PlayerId, SlaveId, CompanionId);
				false ->
					SlaveId = CompanionId,
					mod_slave:grab_a_slave(PlayerId, SlaveId)
			end,
			?INFO(slave, "player grab slave ~w successfully", [SlaveId]),
			case mod_slave:grab_a_slave(PlayerId, SlaveId) of
				true ->
					send_slaves_to_client(PlayerId);
				{false, ErrCode} ->
					mod_err:send_err_by_id(PlayerId, ErrCode)
			end
	end,
	State.


client_battle_for_friend2(State, [PlayerId, FriendId]) ->		
	Ret = case mod_slave:battle_for_friend(PlayerId, FriendId) of
		true ->
			?INFO(slave, "player will battle with for friend: ~w", [FriendId]),
			true;
		_ ->
			skip
	end, 

	case Ret of
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode);
		_ -> 
			skip
	end,
	State.


client_battle_for_freedom2(State, [PlayerId]) ->
	Ret = mod_slave:battle_for_freedom(PlayerId),
	case Ret of
		true ->
			?INFO(slave, "player will battle with his slaveowner", []);
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode)
	end,
	State.

battle_for_freedom_cb2(State, [PlayerId, BattleResultRec, {SlaveOwnerId}]) ->
	case BattleResultRec#battle_result.is_win of
		false ->
			?INFO(slave, "Battle for freedom failed");
		true ->
			?INFO(slave, "Player ~w is free", [PlayerId]),
			mod_slave:battle_win_freedom(PlayerId, SlaveOwnerId)
	end,
	State. 

client_free_slave2(State, [PlayerId, Pos]) ->
	mod_slave:free_slave(PlayerId, Pos),
	send_slaves_to_client(PlayerId),
	?INFO(slave, "Player ~w free the slave in cage: ~w", [PlayerId, Pos]),
	State.

client_slave_work2(State, [PlayerId, WorkType]) ->
	case mod_slave:slave_work(PlayerId, WorkType) of
		{true, Amount} -> 
			?INFO(slave, "Let slave work with type: ~w, and gain amount: ~w", 
				  [WorkType, Amount]),
			send_slave_work_info_to_client(PlayerId);
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode)
	end,

	State.

send_slave_work_info_to_client(PlayerId) ->
	SlaveOwnerRec = fengdi_db:get_slave_owner_rec(PlayerId),
	case SlaveOwnerRec#slave_owner.next_time - util:unixtime() of
		LeftCd when LeftCd > 0 ->
			LeftCd1 = LeftCd;
		_ ->
			LeftCd1 = 0
	end,
	Data = {?MAX_WORK_TIMES - SlaveOwnerRec#slave_owner.work_times, LeftCd1},
	{ok, Packet} = pt_22:write(22107, Data),
	lib_send:send_by_id(PlayerId, Packet).

client_clean_work_cd2(State, [PlayerId]) ->
	case mod_slave:clean_work_cd(PlayerId) of
		true ->
			?INFO(slave, "Player clean salve work cd successfully"),
			send_slave_work_info_to_client(PlayerId);
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode)
	end,

	State.

