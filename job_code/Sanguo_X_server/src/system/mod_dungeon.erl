-module (mod_dungeon).

-include ("common.hrl").

-export ([start_link/1, leave/2, battle_complete/3, 
		  check_process/2, calculate_score/5]).

-export([client_enter/2, client_get_enter_times/2, client_buy_times/3,
		 client_start_award/1, client_get_award/1,sendProgress/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([client_enter2/2, leave2/2, battle_complete2/2, check_process2/2,
		 format_state/1, format_state2/2, client_get_enter_times2/2,
		 client_buy_times2/2, client_start_award2/2, client_get_award2/2]).

-record (dungeon_state, {
	player_id         = 0,
	scene_id		  = 0,		%% 当前副本的地图id
	left_process  	  = [],		%% 当前副本的剩余进度
	max_att_damage    = 0,		%% 攻击最高伤害
	total_round       = 0,		%% 副本打完时的战斗回合数（每次累积）
	total_damage_recv = 0,		%% 副本打完时的个人承受的总伤害(每次累积)
	award_id          = -1 		
	%% 转盘奖励id，-1：副本没完成，0：副本完成但没产生奖励，> 0：奖励产生了
	}).	

start_link({PlayerId})->
	gen_server:start_link(?MODULE, [PlayerId], []).

%% 客户端请求进入副本的次数
client_get_enter_times(PlayerId, DungeonId) ->
	PS = mod_player:get_player_status(PlayerId),
	gen_server:cast(PS#player_status.story_pid, 
					{request, client_get_enter_times2, [PlayerId, DungeonId]}).

%% 客户端请求进入副本
client_enter(PlayerId, SceneId) -> 
	?INFO(dungeon,"Have A Look! client_enter,SceneId = ~w",[SceneId]),
	PS = mod_player:get_player_status(PlayerId),
	gen_server:cast(PS#player_status.story_pid, 
					{request, client_enter2, [PlayerId, SceneId]}).

%% 进入场景时，更新副本进度
sendProgress(PlayerId) ->
	PS = mod_player:get_player_status(PlayerId),
	gen_server:cast(PS#player_status.story_pid, 
					{sendProgress, PlayerId}).

%% 客户端请求购买进入副本的次数
client_buy_times(PlayerId, DungeonId, TimesToBuy) ->
	PS = mod_player:get_player_status(PlayerId),
	gen_server:cast(PS#player_status.story_pid, 
					{request, client_buy_times2, [PlayerId, DungeonId, TimesToBuy]}).

%% 客户端请求启动奖励转盘
client_start_award(PlayerId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_start_award2, [PlayerId]}).

%% 客户端请求获取转盘奖励
client_get_award(PlayerId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_get_award2, [PlayerId]}).

leave(PlayerId, SceneId) ->
	case mod_player:get_player_status(PlayerId) of
		undefined -> %% 玩家不在线了
			ok;
		PS ->
			gen_server:cast(PS#player_status.story_pid, 
							{request, leave2, [PlayerId, SceneId]})
	end.

check_process(PlayerId, MonsterUniqueId) ->
	gen_server:call(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, check_process2, [PlayerId, MonsterUniqueId]}).

%% 战斗结果处理
battle_complete(PS, BattleResultRec, Callback) ->
	gen_server:cast(PS#player_status.story_pid, 
					{request, battle_complete2, [PS#player_status.id, BattleResultRec, Callback]}). 


%% ===================================================
%% ================ for debug ========================
format_state(PlayerId) ->
	PS = mod_player:get_player_status(PlayerId),
	gen_server:cast(PS#player_status.story_pid, 
					{request, format_state2, []}).

init([PlayerId]) ->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, PlayerId),
	mod_player:update_module_pid(PlayerId, ?MODULE, self()),
	State = take_state(PlayerId),
    {ok, State}.

%% 每次进入副本场景都会向客户端发送进度
handle_cast({sendProgress,PlayerId}, State) ->
	?INFO(dungeon,"SendProgress! State = ~w",[State]),
	AllProcess = data_dungeon:get_all_process1(State#dungeon_state.scene_id),
	DeleteProcess1 = AllProcess -- State#dungeon_state.left_process,
	DeleteProcess = takeID(DeleteProcess1),
	?INFO(dungeon,"^^^^^^^Start SendProgress,DeleteProcess = ~w",[DeleteProcess]),
	{ok,BinData} = pt_21:write(21000,DeleteProcess),
	lib_send:send(PlayerId,BinData),
	{noreply,State};


handle_cast({request, Action, Args}, State) ->
	NewState = ?MODULE:Action(State, Args),
	{noreply, NewState}.

handle_call({request, Action, Args}, _From, State) ->
	{NewState, Reply} = ?MODULE:Action(State, Args),
	{reply, Reply, NewState}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(Reason, State) ->
	?INFO(dungeon, "~w gen_server terminate, reason: ~w, state: ~w", 
		  [?MODULE, Reason, State]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.		


%% =================================================================
%% =================================================================
%% =================================================================
client_get_enter_times2(State, [PlayerId, DungeonId]) ->
	send_enter_times_to_client(PlayerId, DungeonId),

	State.

client_enter2(State, [PlayerId, SceneId]) ->
	?INFO(dungeon,"enter dungeon State = ~w",[State]),
	DungeonRec    = get_dungeon_rec(PlayerId, SceneId),
	EnterTimes    = DungeonRec#dungeon.enterTimes,
	Buytimes      = DungeonRec#dungeon.buyTimes,
	TimesRestrict = data_scene:get_tickets(SceneId) + Buytimes,
	%% TO-DO: 添加进入副本的等级限制
	Ret = case (TimesRestrict == 0) orelse (EnterTimes < TimesRestrict) of
		false -> 
			{false, ?ERR_UNKNOWN};
		true ->
			add_enter_times(PlayerId, SceneId),
			true
	end,

	case Ret of
		true ->
			scene:go_to(PlayerId, SceneId),
			%% setup 此时的副本进度
			% Oldstate = take_state(PlayerId),
			% case length(Oldstate#dungeon_state.left_process) =:= 0 andalso Oldstate#dungeon_state.total_round =:= 0 of
			% 	true ->
			IsInTeam = (mod_team:get_team_state(PlayerId) /= false),
			State1   = init_dungeon_state(State, SceneId, IsInTeam);
			% 	false ->
			% 		State1 = Oldstate
			% end;
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode),
			State1 = State
	end,
	
	State1.

init_dungeon_state(State, SceneId, IsInTeam) ->
	State1 = reset_dungeon_state(State),
	case IsInTeam of
		true -> 
			AllProcess = data_dungeon:get_all_process2(SceneId);
		false -> 
			AllProcess = data_dungeon:get_all_process1(SceneId)
	end, 
	State2 = State1#dungeon_state{
			left_process      = AllProcess,
			scene_id          = SceneId
	},
	save_state(State2#dungeon_state.player_id,State2),
	?INFO(dungeon,"State2 = ~w",[State2]),
	State2.

reset_dungeon_state(State) ->
	?INFO(dungeon,"dungeon State = ~w",[State]),
	State#dungeon_state{
			left_process      = [],
			scene_id          = 0,
			max_att_damage    = 0,
			total_round       = 0,
			total_damage_recv = 0,
			award_id          = -1
	}.			

client_buy_times2(State, [PlayerId, DungeonId, TimesToBuy]) ->
	TimesBuyed = get_buy_times(PlayerId, DungeonId),
	Ret = case TimesBuyed + TimesToBuy =< data_dungeon:get_max_buy_times(DungeonId) of
		true ->
			GoldCost = get_buy_cost(DungeonId, TimesBuyed, TimesToBuy),
			case mod_economy:check_and_use_bind_gold(PlayerId, GoldCost, ?GOLD_BUG_DUNGEON_TIMES) of
				false ->
					{false, ?ERR_NOT_ENOUGH_GOLD};
				true ->
					add_buy_times(PlayerId, DungeonId, TimesToBuy),
					true
			end;
		false ->
			{false, ?ERR_DUNGEON_NO_BUY_TIMES}
	end,

	case Ret of
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode);
		true ->
			send_enter_times_to_client(PlayerId, DungeonId)
	end,

	State.

client_start_award2(State, [PlayerId]) ->
	%% 只有副本打完了才能启动转盘
	case State#dungeon_state.award_id == 0 of
		true ->
			DungeonId = State#dungeon_state.scene_id,
			Base = get_round_base(DungeonId),
			N = util:rand(1, Base),
			AwardId = get_rand_award_id(N, DungeonId),

			{ok, Packet} = pt_21:write(21005, AwardId),
			lib_send:send_by_id(PlayerId, Packet),

			State#dungeon_state{award_id = AwardId};
		false ->
			mod_err:send_err_by_id(PlayerId, ?ERR_UNKNOWN),
			State
	end.

get_round_base(DungeonId) ->
	get_round_base(DungeonId, ?MAX_AWARD_ID, 0).

get_round_base(_DungeonId, 0, Base) -> Base;
get_round_base(DungeonId, AwardId, Base) ->
	{_Item, Rate} = data_dungeon:get_award(DungeonId, AwardId),
	get_round_base(DungeonId, AwardId - 1, Base + Rate).

get_rand_award_id(N, DungeonId) ->
	get_rand_award_id(1, N, DungeonId, 0).

get_rand_award_id(?MAX_AWARD_ID, _N, _DungeonId, _Acc) ->
	?MAX_AWARD_ID;
get_rand_award_id(AwardId, N, DungeonId, Acc) ->
	{_Item, Rate} = data_dungeon:get_award(DungeonId, AwardId),
	case Acc + Rate >= N andalso Acc =< N of
		true ->
			AwardId;
		false ->
			get_rand_award_id(AwardId + 1, N, DungeonId, Acc + Rate)
	end.

client_get_award2(State, [PlayerId]) ->
	AwardId = State#dungeon_state.award_id,
	case AwardId == 0 of
		true ->
			mod_err:send_err_by_id(PlayerId, ?ERR_UNKNOWN);
		false ->
			DungeonId = State#dungeon_state.scene_id,
			{Item, _Rate} = data_dungeon:get_award(DungeonId, AwardId),
			?INFO(dungeon,"createItems,PlayerID = ~w,Itemlist = ~w",[PlayerId,[{Item, 1, 0}]]),
			mod_items:createItems(PlayerId, [{Item, 1, 0}], ?ITEM_FROM_DUNGEON_AWARD)
	end,

	State#dungeon_state{award_id = 0}.

send_enter_times_to_client(PlayerId, DungeonId) ->
	DungeonRec = get_dungeon_rec(PlayerId, DungeonId),
	TimesBuyed = DungeonRec#dungeon.buyTimes,
	EnterTimes = DungeonRec#dungeon.enterTimes,
	LeftTimes = get_max_enter_times(PlayerId, DungeonId) - EnterTimes,


	{ok, Packet} = pt_21:write(21001, {DungeonId, EnterTimes, LeftTimes, TimesBuyed}),
	lib_send:send_by_id(PlayerId, Packet).

%% 进入副本的最大次数为副本本身的次数限制加上购买的次数
get_max_enter_times(PlayerId, DungeonId) ->
	data_scene:get_tickets(DungeonId) + get_buy_times(PlayerId, DungeonId).

get_buy_cost(_DungeonId, _TimesUsed, 0) -> 0;
get_buy_cost(DungeonId, TimesUsed, TimesToBuy) ->
	Cost = data_dungeon:get_buy_cost(DungeonId, TimesUsed + 1),
	Cost + get_buy_cost(DungeonId, TimesUsed + 1, TimesToBuy - 1).


check_process2(State, [PlayerId, MonsterUniqueId]) ->
	LeftProcess = State#dungeon_state.left_process,
	Reply =
	case lists:keyfind(MonsterUniqueId, 1, LeftProcess) of
		false ->
			false;
		{_ID,Area} ->
			[{_FirstID,FirstArea}|_Res] = LeftProcess,
			case Area =:= FirstArea of
				true ->
					true;
				false ->
					mod_err:send_err_by_id(PlayerId, ?ERR_PROCESS_NO_FINISH),
					false
			end
	end,
	?INFO(dungeon,"LeftProcess = ~w",[State#dungeon_state.left_process]),
	{State, Reply}.


leave2(State, [PlayerId, _SceneId]) ->
	%% TO-DO: do something
	mod_team:leave_scene(PlayerId),
	% State1 = reset_dungeon_state(State),
	% save_state(PlayerId,State1),
	State.


battle_complete2(State, [PlayerId, BattleResultRec, [ProcessId]]) ->
	
	case BattleResultRec#battle_result.is_win of
		false -> 
			IsLast = false,
			State2 = State;
		true ->
			%% TO-DO: 更新副本的评价条目
			Round           = BattleResultRec#battle_result.statistic#battle_statistic.round,
			DamageRecv      = BattleResultRec#battle_result.statistic#battle_statistic.max_damage_suffer,
			MaxAttDamage    = BattleResultRec#battle_result.statistic#battle_statistic.max_damage_deal,
			TotalRound      = State#dungeon_state.total_round + Round, 
			TotalDamageRecv = State#dungeon_state.total_damage_recv + DamageRecv,
			case State#dungeon_state.max_att_damage < MaxAttDamage of
				true -> 
					MaxAttDamage1 = MaxAttDamage;
				false ->
					MaxAttDamage1 = State#dungeon_state.max_att_damage
			end,
			LeftProcess = lists:keydelete(ProcessId, 1, State#dungeon_state.left_process),
			State1 = State#dungeon_state{
							total_round       = TotalRound,
							max_att_damage    = MaxAttDamage1,
							total_damage_recv = TotalDamageRecv,
							left_process      = LeftProcess
			},
			save_state(PlayerId,State1),
			case LeftProcess of
				[] ->
					IsLast = true;
				_NotNull ->
					IsLast = false
			end,
			State2 = State1
	end,
	case BattleResultRec#battle_result.is_win of
		true ->
			{ok, Packet} = pt_21:write(21000, [ProcessId]),
			lib_send:send_by_id(PlayerId, Packet);
		false ->
			ok
	end,
	case IsLast of
		true ->  
			complete_dungeon(State2,BattleResultRec),
			mod_task:update_dungeon_task(PlayerId,State#dungeon_state.scene_id,1),
			State3 = State2#dungeon_state{award_id = 0};
		false -> 
			State3 = State2
	end,

	State3.

complete_dungeon(State,BattleResultRec) ->
	%% 做结算
	?INFO(dungeon,"Start dungeon JieShuan!"),
	DungeonId    = State#dungeon_state.scene_id,
	PlayerId     = State#dungeon_state.player_id,
	DungeonRec   = get_dungeon_rec(PlayerId, DungeonId),
	MaxAttDamage = State#dungeon_state.max_att_damage,
	BattleRound  = State#dungeon_state.total_round, 
	DamageRecv   = State#dungeon_state.total_damage_recv,
	RoleRecList = mod_role:get_on_battle_list(PlayerId),
	Blood = lists:foldl(fun(Rec,Sum) ->Sum+Rec#role.gd_maxHp end,0,RoleRecList),
	%% 挂机状态的要停止挂机
	mod_guaji:stopGuaji(PlayerId,7),
	NewScore = calculate_score(DungeonId,Blood,MaxAttDamage, BattleRound, DamageRecv),
	OldScore = DungeonRec#dungeon.score,
	OldRank = dungeon_rank:get_rank(PlayerId, DungeonId),
	OldBestRank = DungeonRec#dungeon.bestRank,
	case NewScore > OldScore of
		true -> 
			%% 去排行榜更新自己的成绩，如果上榜了的话
			NewRank = dungeon_rank:update_best_score(PlayerId, DungeonId, NewScore);
		false ->
			NewRank = OldRank
	end,
	%% 把一个好的名次保存下来
	case OldBestRank =:= 0 of
		true ->
			BestRank = NewRank;
		false ->
			case NewRank =:= 0 of
				true ->
					BestRank = OldBestRank;
				false ->
					BestRank = util:min(OldBestRank,NewRank)
			end
	end,
	Battle_rank = get_battle_rank(BattleResultRec,Blood),
	save_best(PlayerId, DungeonRec, MaxAttDamage, BattleRound, DamageRecv,BestRank,NewScore),
	{ok, Packet} = pt_21:write(21004, {DungeonId, 
									   MaxAttDamage, 
									   BattleRound, 
									   DamageRecv, 
									   NewScore,
									   NewRank, 
									   Battle_rank,
									   DungeonRec#dungeon.maxAttDamage,
									   DungeonRec#dungeon.totalRound,
									   DungeonRec#dungeon.totalDamageRecv,
									   OldBestRank,
									   OldScore}),
	?INFO(dungeon,"JieShuan INFO:~w,~w,~w,~w,~w,~w,~w,~w,~w,~w,~w,~w",
						[
						   DungeonId, 
						   MaxAttDamage, 
						   BattleRound, 
						   DamageRecv, 
						   NewScore,
						   NewRank, 
						   Battle_rank,
						   DungeonRec#dungeon.maxAttDamage,
						   DungeonRec#dungeon.totalRound,
						   DungeonRec#dungeon.totalDamageRecv,
						   OldBestRank,
						   OldScore]),
	lib_send:send_by_id(PlayerId, Packet).
	
get_battle_rank(BattleResultRec,Blood) ->
	Round = BattleResultRec#battle_result.statistic#battle_statistic.round,
	DamageRecv = BattleResultRec#battle_result.statistic#battle_statistic.max_damage_suffer,
	Rate = DamageRecv/Blood,
	data_dungeon:get_battle_rank(Round,Rate).


save_best(PlayerId, DungeonRec, NewMaxAttDamage, NewBattleRound, NewDamageRecv,BestRank,NewScore) ->
	case NewMaxAttDamage > DungeonRec#dungeon.maxAttDamage of
		true -> Updates = [{#dungeon.maxAttDamage, NewMaxAttDamage}];
		false -> Updates = []
	end,
	case DungeonRec#dungeon.totalRound =:= 0 orelse NewBattleRound < DungeonRec#dungeon.totalRound of
		true -> Updates1 = [{#dungeon.totalRound, NewBattleRound} | Updates];
		false -> Updates1 = Updates
	end,
	case DungeonRec#dungeon.totalDamageRecv =:= 0 orelse NewDamageRecv < DungeonRec#dungeon.totalDamageRecv of
		true -> Updates2 = [{#dungeon.totalDamageRecv, NewDamageRecv} | Updates1];
		false -> Updates2 = Updates1
	end,
	case DungeonRec#dungeon.bestRank =:= BestRank of
		true -> Updates3 = Updates2;
		false -> Updates3 = [{#dungeon.bestRank, BestRank} | Updates2]
	end,
	case DungeonRec#dungeon.score < NewScore of
		true -> Updates4 = [{#dungeon.score, NewScore} | Updates3];
		false -> Updates4 = Updates3
	end,
	case Updates4 of
		[] -> ok;
		_ ->
			update_dungeon_elements(PlayerId, DungeonRec#dungeon.key, Updates4)
	end.

format_state2(State, []) ->
	?INFO(dungeon, "mod_dungeon state is ~w", [State]),
	State.

calculate_score(DungeonId, Blood, MaxAttDamage, BattleRound, DamageRecv) ->
	case BattleRound =:= 0 of
		true ->
			0;
		false ->
		MonsterNum = length(data_dungeon:get_all_process1(DungeonId)),
		case MonsterNum =:= 1 of
			false ->
				Para = 10;
			true ->
				Para = 40
		end,
		Point = MaxAttDamage*0.5 + 2000*(1 - DamageRecv/MonsterNum/Blood) + 3000*(1 - BattleRound/MonsterNum/Para),
		round(Point)
	end.

%%--------------------------------------------------------------------------
%%-------------------------- 保存副本进度的操作 ----------------------------
-define(DUNGEON_STATE_CACHE_REF, cache_util:get_register_name(dungeon_status)).

save_state(PlayerId,State) ->
	Rec = #dungeon_status{gd_accountId = PlayerId, gd_state = State},
	case gen_cache:lookup(?DUNGEON_STATE_CACHE_REF, PlayerId) of
		[] ->
			gen_cache:insert(?DUNGEON_STATE_CACHE_REF,Rec);
		[_Rec] ->
			gen_cache:update_record(?DUNGEON_STATE_CACHE_REF,Rec)
	end.

take_state(PlayerId) ->
	case gen_cache:lookup(?DUNGEON_STATE_CACHE_REF, PlayerId) of
		[] ->
			#dungeon_state{player_id = PlayerId};
		[Rec] ->
			Rec#dungeon_status.gd_state
	end.

%% =========================================================================
%% ========================= 有关副本的数据库操作 ==========================
-define(DUNGEON_CACHE_REF, cache_util:get_register_name(dungeon)).

get_dungeon_rec(PlayerId, DungeonId) ->
	case gen_cache:lookup(?DUNGEON_CACHE_REF, {PlayerId, DungeonId}) of
		[] ->
			Rec = #dungeon{key = {PlayerId, DungeonId}, updateTime = util:unixtime()},
			insert_dungeon_score(Rec),
			Rec;
		[Rec | _] ->
			reset_if_tomorrow(Rec)
					
	end.

reset_if_tomorrow(Rec) ->
	{PlayerId, DungeonId} = Rec#dungeon.key,
	Now = util:unixtime(),
	case util:get_diff_day(Rec#dungeon.updateTime, Now) of
		the_same_day -> Rec;
		_ -> 
			UpdateFields = [{#dungeon.updateTime, Now}, 
							{#dungeon.enterTimes, 0},
							{#dungeon.buyTimes, 0}],
			update_dungeon_elements(PlayerId, {PlayerId, DungeonId}, UpdateFields),
			Rec#dungeon{updateTime = Now, enterTimes = 0}
	end.

insert_dungeon_score(Rec) ->
	gen_cache:insert(?DUNGEON_CACHE_REF, Rec).

update_dungeon_elements(_PlayerId, Key, UpdateFields) ->
	gen_cache:update_element(?DUNGEON_CACHE_REF, Key, UpdateFields).

add_enter_times(PlayerId, SceneId) ->
	gen_cache:update_counter(?DUNGEON_CACHE_REF, {PlayerId, SceneId}, {#dungeon.enterTimes, 1}).

get_buy_times(PlayerId, SceneId) ->
	Rec = get_dungeon_rec(PlayerId, SceneId),
	Rec#dungeon.buyTimes.

add_buy_times(PlayerId, SceneId, AddTimes) ->
	gen_cache:update_counter(?DUNGEON_CACHE_REF, {PlayerId, SceneId}, {#dungeon.buyTimes, AddTimes}).
%% =========================================================================
%% =========================================================================

takeID(ProcessTuple)->
	Fun = fun({ID,_Area}) ->
		ID
	end,
	lists:map(Fun,ProcessTuple).