-module (mod_official).

-include ("common.hrl").

-compile(export_all).

%% for other module
-export ([start_link/1, get_official_position/1, get_added_attri/1, get_qihun_rec/1]).

-export([client_get_fenglu/1, client_get_qihun/1, client_request_leveling/3,
		 client_clear_leveling_cd/1, client_up_pinjie/2, client_get_pinjie/1,
		 client_get_stage/1]).

-export([client_get_fenglu2/2, client_get_qihun2/2, client_request_leveling2/2,
		 client_clear_leveling_cd2/2, client_up_pinjie2/2, client_get_pinjie2/2,
		 client_get_stage2/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
	player_id = 0,
	leveling_timer = none 		%% 修炼器魂的timer，主要是用来通知客户端
	}).

-define(GET_QIHUN_ADDED_ATTRI(Id, QihunRec),
		if
			(Id < QihunRec#qi_hun.gd_levelingId) ->
				data_official:get_qihun_added_attri(Id, QihunRec#qi_hun.gd_level + 1);
			true ->
				data_official:get_qihun_added_attri(Id, QihunRec#qi_hun.gd_level)
		end
).

-define(GET_PINJIE_ADDED_ATTRI(Id, PinjieRec), 
		data_official:get_pinjie_added_attri(Id, erlang:element(1, erlang:element(Id + 2, PinjieRec)))
).

start_link({PlayerId})->
	gen_server:start_link(?MODULE, [PlayerId], []).

%% 获取官职id
get_official_position(PlayerId) ->
	EconomyRec = mod_economy:get(PlayerId),
	data_official:get_officail_position(EconomyRec#economy.gd_totalPopularity).

%% 获取器魂、品阶和神器给武将的加成属性
get_added_attri(PlayerId) ->
	QihunRec = get_qihun_rec(PlayerId),
	PinjieRec = get_pinjie_rec(PlayerId),

	MaxHp1     = ?GET_QIHUN_ADDED_ATTRI(?QIHUN_JING, 	QihunRec),
	PAtt1      = ?GET_QIHUN_ADDED_ATTRI(?QIHUN_LI, 		QihunRec),
	MAtt1      = ?GET_QIHUN_ADDED_ATTRI(?QIHUN_YUAN, 	QihunRec),
	PDef1      = ?GET_QIHUN_ADDED_ATTRI(?QIHUN_DUN, 	QihunRec),
	MDef1      = ?GET_QIHUN_ADDED_ATTRI(?QIHUN_YU, 		QihunRec),
	Mingzhong1 = ?GET_QIHUN_ADDED_ATTRI(?QIHUN_ZHUN, 	QihunRec),
	Shanbi1    = ?GET_QIHUN_ADDED_ATTRI(?QIHUN_SHAN, 	QihunRec),
	Xingyun1   = ?GET_QIHUN_ADDED_ATTRI(?QIHUN_YUN, 	QihunRec),
	Speed1     = ?GET_QIHUN_ADDED_ATTRI(?QIHUN_SU, 		QihunRec),
	Baoji1     = ?GET_QIHUN_ADDED_ATTRI(?QIHUN_BAO, 	QihunRec),

	MaxHp2     = ?GET_PINJIE_ADDED_ATTRI(?QIHUN_JING, 	PinjieRec),
	PAtt2      = ?GET_PINJIE_ADDED_ATTRI(?QIHUN_LI, 	PinjieRec),
	MAtt2      = ?GET_PINJIE_ADDED_ATTRI(?QIHUN_YUAN, 	PinjieRec),
	PDef2      = ?GET_PINJIE_ADDED_ATTRI(?QIHUN_DUN, 	PinjieRec),
	MDef2      = ?GET_PINJIE_ADDED_ATTRI(?QIHUN_YU, 	PinjieRec),
	Mingzhong2 = ?GET_PINJIE_ADDED_ATTRI(?QIHUN_ZHUN, 	PinjieRec),
	Shanbi2    = ?GET_PINJIE_ADDED_ATTRI(?QIHUN_SHAN, 	PinjieRec),
	Xingyun2   = ?GET_PINJIE_ADDED_ATTRI(?QIHUN_YUN, 	PinjieRec),
	Speed2     = ?GET_PINJIE_ADDED_ATTRI(?QIHUN_SU, 	PinjieRec),
	Baoji2     = ?GET_PINJIE_ADDED_ATTRI(?QIHUN_BAO, 	PinjieRec),

	Attri1 = #role_update_attri{
		gd_currentHp  = MaxHp1 + MaxHp2,
		gd_maxHp      = MaxHp1 + MaxHp2,
		p_def         = PDef1 + PDef2,
		m_def         = MDef1 + MDef2,
		p_att         = PAtt1 + PAtt2,
		m_att         = MAtt1 + MAtt2,
		gd_mingzhong  = Mingzhong1 + Mingzhong2,
		gd_shanbi     = Shanbi1 + Shanbi2,
		gd_xingyun    = Xingyun1 + Xingyun2,
		gd_speed      = Speed1 + Speed2,
		gd_baoji      = Baoji1 + Baoji2
	},
	PinjieLv = get_pinjie_lowest_lv(PinjieRec),
	Stage    = data_official:get_shenqi_stage(QihunRec#qi_hun.gd_level, PinjieLv),
	Attri2   = data_official:get_shenqi_stage_added_attri(Stage),
	role_util:role_update_attri_add(Attri1, Attri2).

%% 客户端请求领取俸禄状态
client_request_fenglu_state(PlayerId)->
		gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_request_fenglu_state2, [PlayerId]}).

%% 客户端请求领取俸禄
client_get_fenglu(PlayerId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_get_fenglu2, [PlayerId]}).

%% 客户端请求获取器魂数据
client_get_qihun(PlayerId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_get_qihun2, [PlayerId]}).

%% 客户端请求修炼器魂
client_request_leveling(PlayerId, QihunId, FinishRightNow) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_request_leveling2, [PlayerId, QihunId, FinishRightNow]}).

%% 客户端请求清除正在修炼的器魂cd
client_clear_leveling_cd(PlayerId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_clear_leveling_cd2, [PlayerId]}).

%% 客户端请求器魂品阶数据
client_get_pinjie(PlayerId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_get_pinjie2, [PlayerId]}).

%% 客户端请求提升器魂品阶完美度
client_up_pinjie(PlayerId, QihunId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_up_pinjie2, [PlayerId, QihunId]}).

client_get_stage(PlayerId) ->
	gen_server:cast(mod_player:get_pid(PlayerId, ?MODULE), 
					{request, client_get_stage2, [PlayerId]}).

leveling_timer(ThisPid) ->
	gen_server:cast(ThisPid, 
					{request, leveling_timer2, []}).

%% =====================================================================
%% =====================================================================
init([PlayerId]) ->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, PlayerId),
	mod_player:update_module_pid(PlayerId, ?MODULE, self()),
    {ok, #state{player_id = PlayerId}}.

handle_cast({request, Action, Args}, State) ->
	NewState = ?MODULE:Action(State, Args),
	{noreply, NewState}.

handle_call({request, Action, Args}, _From, State) ->
	{NewState, Reply} = ?MODULE:Action(State, Args),
	{reply, Reply, NewState}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(Reason, State) ->
	case State#state.leveling_timer of
		none -> 
			ok;
		TRef ->
			timer:cancel(TRef)
	end,
	?INFO(dungeon, "~w gen_server terminate, reason: ~w, state: ~w", 
		  [?MODULE, Reason, State]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ==============================================================
%% ====================== 无聊的分割线 ==========================
%% ==============================================================

client_request_fenglu_state2(State, [PlayerId]) ->
	Ret = case mod_counter:get_counter(PlayerId, ?COUNTER_FENGLU) >= 1 of
		true ->
			{false, ?YILING_FENGLU};
		false ->
			{true, ?MEILING_FENGLU}
	end,

	case Ret of
		{false, ErrCode} ->
			{ok, Packet} = pt_13:write(13000, ErrCode),
			lib_send:send_by_id(PlayerId, Packet);
		{true,RCode} ->
			{ok, Packet} = pt_13:write(13000, RCode),
			?INFO(official, "yiling_fenglu:~w",[Packet]),
	        lib_send:send_by_id(PlayerId, Packet)
	end,
	State.

client_get_fenglu2(State, [PlayerId]) ->
	Ret = case mod_counter:get_counter(PlayerId, ?COUNTER_FENGLU) >= 1 of
		true ->
			?ERR(official, "~w cannot get more fenglu", [PlayerId]),
			{false, ?YILING_FENGLU};
		false ->
			mod_counter:add_counter(PlayerId, ?COUNTER_FENGLU),
			OfficialId = get_official_position(PlayerId),
			AddedSliver = data_official:get_fenglu(OfficialId),
			mod_economy:add_silver(PlayerId, AddedSliver, ?SILVER_FROM_FENGLU),
			true
	end,

	case Ret of
		{false, ErrCode} ->
			{ok, Packet} = pt_13:write(13000, ErrCode),
			lib_send:send_by_id(PlayerId, Packet),
			mod_err:send_err_by_id(PlayerId, ErrCode);
		true ->
			{ok, Packet} = pt_13:write(13000, ?YILING_FENGLU),
			?INFO(official, "yiling_fenglu:~w",[Packet]),
	        lib_send:send_by_id(PlayerId, Packet)
	end,
	State.

client_get_qihun2(State, [PlayerId]) ->
	QihunRec = get_qihun_rec(PlayerId),
	?INFO(official_qihun,"Qihunrec:~w",[QihunRec]),
	send_qihun_info_to_client(PlayerId, QihunRec),

	State.

client_get_pinjie2(State, [PlayerId]) ->
	send_pinjie_to_client(PlayerId),

	State.

client_request_leveling2(State, [PlayerId, QihunId, _FinishRightNow]) ->
	?INFO(official,"playerid:~w,qinhunid:~w,finishnow:~w",[PlayerId, QihunId, _FinishRightNow]),
	QihunRec   = get_qihun_rec(PlayerId),
	LevelingId = QihunRec#qi_hun.gd_levelingId,
	% OfficialId = get_official_position(PlayerId),
	CurLevel   = QihunRec#qi_hun.gd_level,
	NeedLevel  = data_official:get_needlevel_by_qihun(CurLevel),
	?INFO(official,"Needlevel:~w",[NeedLevel]),
	Role_Rec   = mod_role:get_main_role_rec(PlayerId),
	Role_level = Role_Rec#role.gd_roleLevel,
	Ret = case CurLevel < data_official:get_max_qihun_level() of
		true ->
			SilverCost = data_official:get_leveling_cost(CurLevel),
			%% 能否修炼器魂的条件：
			%%（程序将控制gd_levelingId为正确的值，如最后一个器魂修炼完了，它的值就为第一个器魂id）
			%% 		1.没有器魂处于修炼状态了，才能请求修炼
			%% 		2.客户端请求的要修炼的器魂id为qi_hun记录中下一个要修炼的器魂id：gd_levelingId
			%% 		3.器魂的能修炼的最大等级不能超过官职所能限定的最大等级
			case Role_level >=  NeedLevel of
				false ->
					{false, ?ERR_NOT_ENOUGH_MER_LEVEL};
				true ->
					case (QihunRec#qi_hun.gd_isInLeveling == 1) orelse 
				 	   		(LevelingId /= QihunId) of
						true -> 
							{false, ?ERR_UNKNOWN};
						false ->
							case mod_economy:check_silver(PlayerId, SilverCost) of
								true ->
									Now = util:unixtime(),
									QihunRec1 = QihunRec#qi_hun{
										gd_isInLeveling = 1, 
										gd_beginTime    = Now
									},
									update_qihun_rec(QihunRec1),
									mod_task:updata_shenqi_task(PlayerId,0,1),
									{true, QihunRec1};
								false ->
									{false, ?ERR_NOT_ENOUGH_SILVER}
							end
					end
			end;
		false ->
			SilverCost = 0,
			{false, ?ERR_OFFICIAL_REACH_MAX}
	end,

	case Ret of
		{false, ErrCode} ->
			State1 = State,
			mod_err:send_err_by_id(PlayerId, ErrCode);
		{true, NewQihunRec} ->
			mod_economy:use_silver(PlayerId, SilverCost, ?SILVER_LEVELING_QIHUN),
			LevelingTime = data_official:get_leveling_time(CurLevel),
			{ok, TRef}   = timer:apply_after((LevelingTime * 1000), ?MODULE, leveling_timer, [self()]),
			State1       = State#state{leveling_timer = TRef},
			send_qihun_info_to_client(PlayerId, NewQihunRec)
	end,
	State1.

%% 修炼器魂的timer，timer到期时要升级器魂
leveling_timer2(State, _) ->
	PlayerId  = State#state.player_id,
	QihunRec1 = get_qihun_rec(PlayerId),
	send_qihun_info_to_client(PlayerId, QihunRec1),
	State#state{leveling_timer = none}.

client_clear_leveling_cd2(State, [PlayerId]) ->
	QihunRec = get_qihun_rec(PlayerId),
	Ret = case QihunRec#qi_hun.gd_isInLeveling of
		0 ->
			{false, ?ERR_UNKNOWN};
		1 ->
			LevelingTime = data_official:get_leveling_time(QihunRec#qi_hun.gd_level),
			LeftTime     = QihunRec#qi_hun.gd_beginTime + LevelingTime - util:unixtime(),
			GoldCost     = get_clear_cd_cost(LeftTime),
			case mod_economy:check_bind_gold(PlayerId, GoldCost) of
				true -> {true, GoldCost};
				false -> {false, ?ERR_NOT_ENOUGH_GOLD}
			end
	end,

	case Ret of
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode);
		{true, GoldCost2} ->
			mod_economy:use_bind_gold(PlayerId, GoldCost2, ?GOLD_FINISH_QIHUN_CD),

			QihunRec1 = level_up_qihun(QihunRec),
			send_qihun_info_to_client(PlayerId, QihunRec1)
	end,
	State.

client_up_pinjie2(State, [PlayerId, QihunId]) ->
	{PinjieLv, PerfectVal} = get_pinjie_info(PlayerId, QihunId),
	QihunRec = get_qihun_rec(PlayerId),
	CurQihunLv = QihunRec#qi_hun.gd_level,
	?INFO(official, "request up qihun ~w pinjie, Id: ~w", [QihunId, QihunRec#qi_hun.gd_levelingId]),
	Ret = case (PinjieLv < CurQihunLv) orelse 
			   ((PinjieLv == CurQihunLv) andalso (QihunId < QihunRec#qi_hun.gd_levelingId)) of
		false ->
			{false, ?ERR_UNKNOWN};
		true ->
			{PopularityNeeded, GoldNeeded} = data_official:get_pinjie_up_cost(PinjieLv),
			case mod_economy:check_bind_gold(PlayerId, GoldNeeded) of
				false -> 
					{false, ?ERR_NOT_ENOUGH_GOLD};
				true ->
					case mod_economy:check_popularity(PlayerId, PopularityNeeded) of
						false ->
							{false, ?ERR_NOT_ENOUGH_POPULARITY};
						true ->	
							{true, PopularityNeeded, GoldNeeded}
					end
			end
	end,

	case Ret of
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode);
		{true, PopularityNeeded2, GoldNeeded2} ->
			add_pinjie_perfect(PlayerId, QihunId, PinjieLv, PerfectVal),
			mod_economy:use_bind_gold(PlayerId, GoldNeeded2, ?GOLD_UP_PINJIE),
			mod_economy:use_popularity(PlayerId, PopularityNeeded2, ?POPULARITY_UP_PINJIE),

			send_pinjie_to_client(PlayerId)
	end,
	State.
			

add_pinjie_perfect(PlayerId, QihunId, PinjieLv, PerfectVal) ->
	Val = rand_a_perfect_value(PinjieLv),
	PerfectVal1 = PerfectVal + Val,
	case PerfectVal1 >= 1000 of
		true ->
			level_up_pinjie(PlayerId, QihunId, PinjieLv);
		false ->
			update_pinjie(PlayerId, QihunId, {PinjieLv, PerfectVal1})
	end.

%% 随机一个完美度
rand_a_perfect_value(PinjieLv) ->
	{Min, Max} = data_official:get_perfect_rand_val(PinjieLv),
	Min1 = erlang:round(Min * 1000),
	Max1 = erlang:round(Max * 1000),
	util:rand(Min1, Max1).

get_clear_cd_cost(LeftTime) ->
	util:ceil(LeftTime / 120).

client_get_stage2(State, [PlayerId]) ->
	Stage = get_shenqi_stage(PlayerId),
	send_stage_to_client(PlayerId, Stage),

	State.

send_qihun_info_to_client(PlayerId, QihunRec) ->
	case QihunRec#qi_hun.gd_isInLeveling of
		1 ->
			Now          = util:unixtime(),
			LevelingTime = data_official:get_leveling_time(QihunRec#qi_hun.gd_level),
			LeftTime     = QihunRec#qi_hun.gd_beginTime + LevelingTime - Now;
		0 ->
			LeftTime = 0
	end,
	LevelingId  = QihunRec#qi_hun.gd_levelingId,
	Level        = QihunRec#qi_hun.gd_level,
	{ok, Packet} = pt_13:write(13010, {LevelingId, Level, LeftTime}),
	lib_send:send_by_id(PlayerId, Packet).

send_pinjie_to_client(PlayerId) ->
	PinjieRec = get_pinjie_rec(PlayerId),
	{ok, Packet} = pt_13:write(13020, PinjieRec),
	lib_send:send_by_id(PlayerId, Packet).

send_stage_to_client(PlayerId, Stage) ->
	{ok, Packet} = pt_13:write(13025, Stage),
	lib_send:send_by_id(PlayerId, Packet).

%% 升级器魂修炼			
level_up_qihun(QihunRec) ->
	NewLevel      = get_next_level(QihunRec#qi_hun.gd_levelingId, QihunRec#qi_hun.gd_level),
	case QihunRec#qi_hun.gd_levelingId =:= ?MAX_QIHUN_ID of
		true ->
			%% 成就通知
			mod_achieve:qihunNotify(QihunRec#qi_hun.gd_accountId,NewLevel);
		false ->
			void
	end,
	NewLevelingId = get_next_leveling(QihunRec#qi_hun.gd_levelingId),
	QihunRec1     = QihunRec#qi_hun{
						gd_levelingId   = NewLevelingId, 
						gd_level        = NewLevel, 
						gd_isInLeveling = 0},
	update_qihun_rec(QihunRec1),
	mod_role:update_attri_all_notify(QihunRec#qi_hun.gd_accountId),

	OldStage = get_shenqi_stage(QihunRec),
	check_shenqi_stage(qihun_level_up, QihunRec#qi_hun.gd_accountId, 
					   OldStage, NewLevel),
	QihunRec1.

%% 升级器魂品阶
level_up_pinjie(PlayerId, QihunId, OldPinjieLv) ->
	NewPinjieLv = OldPinjieLv + 1,
	update_pinjie(PlayerId, QihunId, {NewPinjieLv, 0}),
	mod_achieve:pinjieNotify(PlayerId, QihunId, NewPinjieLv),
	mod_role:update_attri_all_notify(PlayerId),
	OldStage = get_shenqi_stage(PlayerId),
	check_shenqi_stage(pinjie_level_up, PlayerId, OldStage, get_pinjie_lowest_lv(PlayerId)).

%% 检测是否达到了一个新的神器阶段了
check_shenqi_stage(pinjie_level_up, PlayerId, OldStage, NewLevel) ->
	QihunRec = get_qihun_rec(PlayerId),
	NewStage = data_official:get_shenqi_stage(QihunRec#qi_hun.gd_level, NewLevel),
	case NewStage > OldStage of
		true ->	
			%% 通知成就
			mod_achieve:shenqiStageNotify(PlayerId, NewStage),
			shenqi_stage_notify(PlayerId, NewStage);
		false ->
			ok
	end;
check_shenqi_stage(qihun_level_up, PlayerId, OldStage, NewLevel) ->
	PinjieLv = get_pinjie_lowest_lv(PlayerId),
	NewStage = data_official:get_shenqi_stage(NewLevel, PinjieLv),
	case NewStage > OldStage of
		true ->	
			shenqi_stage_notify(PlayerId, NewStage);
		false ->
			ok
	end.

shenqi_stage_notify(PlayerId, NewStage) ->
	set_shenqi_stage(PlayerId, NewStage),
	mod_role:update_attri_all_notify(PlayerId),

	send_stage_to_client(PlayerId, NewStage).

%% 根据规则获取下一个要修炼的器魂id
get_next_leveling(?MAX_QIHUN_ID) -> ?MIN_QIHUN_ID;
get_next_leveling(QihunId) -> QihunId + 1.

%% 根据规则获取下一轮修炼的等级
get_next_level(?MAX_QIHUN_ID, CurLevel) -> CurLevel + 1;
get_next_level(_QihunId, CurLevel) -> CurLevel.

%% 返回对应器魂id的：{品阶等级, 完美度}
get_pinjie_info(PlayerId, QihunId) ->
	PinjieRec = get_pinjie_rec(PlayerId),
	case QihunId of
		?QIHUN_JING ->
			PinjieRec#qihun_pinjie.gd_jing;
		?QIHUN_LI ->
			PinjieRec#qihun_pinjie.gd_li;
		?QIHUN_YUAN ->
			PinjieRec#qihun_pinjie.gd_yuan;
		?QIHUN_DUN ->
			PinjieRec#qihun_pinjie.gd_dun;
		?QIHUN_YU ->
			PinjieRec#qihun_pinjie.gd_yu;
		?QIHUN_ZHUN ->
			PinjieRec#qihun_pinjie.gd_zhun;
		?QIHUN_SHAN ->
			PinjieRec#qihun_pinjie.gd_shan;
		?QIHUN_YUN ->
			PinjieRec#qihun_pinjie.gd_yun;
		?QIHUN_SU ->
			PinjieRec#qihun_pinjie.gd_su;
		?QIHUN_BAO ->
			PinjieRec#qihun_pinjie.gd_bao
	end.

get_pinjie_lowest_lv(PlayerId) when is_integer(PlayerId) ->
	PinjieRec = get_pinjie_rec(PlayerId),
	get_pinjie_lowest_lv(PinjieRec);
get_pinjie_lowest_lv(PinjieRec) ->
	{Level1, _} = PinjieRec#qihun_pinjie.gd_jing,
	{Level2, _} = PinjieRec#qihun_pinjie.gd_li,
	{Level3, _} = PinjieRec#qihun_pinjie.gd_yuan,
	{Level4, _} = PinjieRec#qihun_pinjie.gd_dun,
	{Level5, _} = PinjieRec#qihun_pinjie.gd_yu,
	{Level6, _} = PinjieRec#qihun_pinjie.gd_zhun,
	{Level7, _} = PinjieRec#qihun_pinjie.gd_shan,
	{Level8, _} = PinjieRec#qihun_pinjie.gd_yun,
	{Level9, _} = PinjieRec#qihun_pinjie.gd_su,
	{Level10, _} = PinjieRec#qihun_pinjie.gd_bao,
	lists:min([Level1, Level2, Level3, Level4, Level5, Level6, Level7, Level8, Level9, Level10]).


%% =========================================================================
%% ============================== 数据库操作 ===============================
-define(QIHUN_CACHE_REF, cache_util:get_register_name(qi_hun)).
-define(PINJIE_CACHE_REF, cache_util:get_register_name(qihun_pinjie)).

get_qihun_rec(PlayerId) ->
	case gen_cache:lookup(?QIHUN_CACHE_REF, PlayerId) of
		[] ->
			Rec = #qi_hun{gd_accountId = PlayerId},
			gen_cache:insert(?QIHUN_CACHE_REF, Rec),
			Rec;
		[Rec | _] ->
			reset(Rec)
	end.
 
update_qihun_rec(QihunRec) ->
	gen_cache:update_record(?QIHUN_CACHE_REF, QihunRec).

get_pinjie_rec(PlayerId) ->
	case gen_cache:lookup(?PINJIE_CACHE_REF, PlayerId) of
		[] ->
			Rec = #qihun_pinjie{gd_accountId = PlayerId},
			gen_cache:insert(?PINJIE_CACHE_REF, Rec),
			Rec;
		[Rec | _] ->
			Rec
	end.

update_pinjie(PlayerId, QihunId, PinjieInfo) ->
	%% 器魂宏定义和record：qihun_pinjie中的字段是相关联的
	FieldIndex = QihunId + 2,
	gen_cache:update_element(?PINJIE_CACHE_REF, PlayerId, [{FieldIndex, PinjieInfo}]).

%% 这里的重置是当修炼结束时更新数据并返回新的器魂记录
reset(QihunRec) ->
	case QihunRec#qi_hun.gd_isInLeveling of
		1 ->
			Now = util:unixtime(),
			LevelingTime = data_official:get_leveling_time(QihunRec#qi_hun.gd_level),
			case Now >= (QihunRec#qi_hun.gd_beginTime + LevelingTime) of
				true -> %% 修炼完毕，更新修炼的等级和修炼状态
					level_up_qihun(QihunRec);
				false ->
					QihunRec
			end;
		0 ->
			QihunRec
	end.

set_shenqi_stage(PlayerId, Stage) ->
	gen_cache:update_element(?QIHUN_CACHE_REF, PlayerId, [{#qi_hun.gd_stage, Stage}]).

get_shenqi_stage(QihunRec) when is_record(QihunRec, qi_hun) ->
	QihunRec#qi_hun.gd_stage;
get_shenqi_stage(PlayerId) ->
	QihunRec = get_qihun_rec(PlayerId),
	QihunRec#qi_hun.gd_stage.

