%%% -------------------------------------------------------------------
%%% Author  : xierf
%%% Description :竞技场
%%%
%%% Created : 2012-6-7
%%% -------------------------------------------------------------------
-module(mod_mirror_rnkm).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").

-define(RANK_MATCH_MAP_ID, 10323).

-define(MAX_HISTORY_COUNT, 5).
-define(MAX_FIGHT_TIME, 40).

-define(MIRROR_INIT, 0).
-define(MIRROR_IDLE, 1).
-define(MIRROR_BUSY, 2).

-define(UPDATE_HEROS_INTERVAL, 120).
-define(PERSIST_MIRRORS_INTERVAL, 900).

-define(TREND_KEEP, 0).
-define(TREND_UP, 1).
-define(TREND_DOWN, 2).

-define(ADD_CHANCE_GOLD(AddedChances), if AddedChances >= 10 -> 100; true -> (AddedChances + 1)* 10 end).

-define(ADD_BONUS_INTERVAL, 600).
-define(GIVE_BONUS_TIME, {22, 0, 0}).

-define(FIGHT_RESULT(IsRoleWin), case IsRoleWin of true -> 1; _ -> 2 end).

-define(_rnkm_error, ?DEFAULT_UNIQUE, ?RNKM, ?RNKM_ERROR, #m_rnkm_error_toc).
-define(_rnkm_open, ?DEFAULT_UNIQUE, ?RNKM, ?RNKM_OPEN, #m_rnkm_open_toc).
-define(_rnkm_update_role, ?DEFAULT_UNIQUE, ?RNKM, ?RNKM_UPDATE_ROLE, #m_rnkm_update_role_toc).
-define(_rnkm_update_mirror, ?DEFAULT_UNIQUE, ?RNKM, ?RNKM_UPDATE_MIRROR, #m_rnkm_update_mirror_toc).
-define(_rnkm_update_history, ?DEFAULT_UNIQUE, ?RNKM, ?RNKM_UPDATE_HISTORY, #m_rnkm_update_history_toc).
-define(_rnkm_heros, ?DEFAULT_UNIQUE, ?RNKM, ?RNKM_HEROS, #m_rnkm_heros_toc).
-define(_rnkm_add_chance, Unique, ?RNKM, ?RNKM_ADD_CHANCE, #m_rnkm_adsd_chance_toc).
-define(_rnkm_get_bonus, ?DEFAULT_UNIQUE, ?RNKM, ?RNKM_GET_BONUS, #m_rnkm_get_bonus_toc).
-define(_rnkm_refresh_cd, ?DEFAULT_UNIQUE, ?RNKM, ?RNKM_REFRESH_CD, #m_rnkm_refresh_cd_toc).
-define(_rnkm_match_end, ?DEFAULT_UNIQUE, ?RNKM, ?RNKM_MATCH_END, #m_rnkm_match_end_toc).
-define(_rnkm_bonus_notice, ?DEFAULT_UNIQUE, ?RNKM, ?RNKM_BONUS_NOTICE, #m_rnkm_bonus_notice_toc).
-define(_rnkm_update_notice, ?DEFAULT_UNIQUE, ?RNKM, ?RNKM_UPDATE_NOTICE, #m_rnkm_update_notice_toc).
-define(_role2_getroleattr, Unique, ?ROLE2, ?ROLE2_GETROLEATTR, #m_role2_getroleattr_toc).

%% --------------------------------------------------------------------
%% External exports
-export([start/0, start_link/0, after_fight/4, mirror_fb_stop/1, handle/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([add_remain_changce/2]).

-export([get_random_listen_ranks/1,refresh_daily_counter_times/2]).

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
start() ->
	supervisor:start_child(mgeem_sup, {?MODULE, {?MODULE, start_link, []}, transient, 30000, worker, [?MODULE]}).

start_link() ->
	gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

refresh_daily_counter_times(RoleID,RemainTimes) ->
	#r_rnkm_role{last_chlg_time=ChlgTime, 
				 remain_chances=ReaminChances, last_add_time=LastAddTime} = RoleInfo = dirty_read(?DB_RNKM_ROLE, RoleID),
	Date = date(),
	if
		RemainTimes > 0 ->
			db:dirty_write(?DB_RNKM_ROLE, RoleInfo#r_rnkm_role{remain_chances=RemainTimes}),
			IsNotity = true,
			ReaminChances2 = RemainTimes;
		true ->
			ReaminChances2 = 
				case common_tool:seconds_to_datetime(erlang:max(LastAddTime, ChlgTime)) of
					{Date, _} ->
						ReaminChances;
					_ ->
						cfg_rank_match:max_chances()
				end,
			IsNotity = false
	end,
	mod_daily_counter:set_mission_remain_times(RoleID, 1018, ReaminChances2,IsNotity).


	
%% 增加竞技场挑战次数
add_remain_changce(RoleID, Times) ->
	RoleInfo = dirty_read(?DB_RNKM_ROLE, RoleID),
	#p_rnkm_role{remain_chances=RemainChances} = p_rnkm_role(RoleInfo),
	NewRoleInfo=RoleInfo#r_rnkm_role{
		remain_chances = RemainChances + Times, 
		last_add_time  = common_tool:now()
	},
	db:dirty_write(?DB_RNKM_ROLE, NewRoleInfo),
	Msg = #m_rnkm_update_role_toc{role=p_rnkm_role(NewRoleInfo)},
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?RNKM, ?RNKM_UPDATE_ROLE, Msg).

%%玩家退出副本
mirror_fb_stop(RoleID) ->
	global:send(?MODULE, {mirror_fb_stop, RoleID}).

%%战斗结束，玩家挑战自己的镜像
after_fight(ChallengerID, MirrorID, _MirrorTab, _IsChallengerWin) when ChallengerID == MirrorID ->
	ignore;

%%战斗结束，玩家挑战他人的镜像
after_fight(ChallengerID, MirrorID, MirrorTab, IsChallengerWin) ->
	Now            = common_tool:now(),
	ChallengerRank = erase(role_rank),
	ChallengerTab  = erase(role_table),
	{ok, #p_role_base{role_name = ChallengerName}} = mod_map_role:get_role_base(ChallengerID),
	[#p_role_base{role_name = MirrorName}] = ets:lookup(MirrorTab, p_role_base),
	FightResult      = ?FIGHT_RESULT(IsChallengerWin),
	MirrorRank       = erase(mirror_rank),
	FightBonus       = get_fight_bonus(MirrorRank),
	MirrorFightBonus = case ets:lookup(MirrorTab, fight_bonus) of
		[{_, MirrorFightBonus2}] -> MirrorFightBonus2;
		_ -> 0
	end,
	MirrorWinCount   = case ets:lookup(MirrorTab, win_count) of
		[{_, MirrorWinCount2}] -> MirrorWinCount2;
		_ -> 0
	end,
	ChallengerFightBonus = case ChallengerTab of
		undefined -> 0;
		_ 		  -> case ets:lookup(ChallengerTab, fight_bonus) of
			[{_, ChallengerFightBonus2}] -> ChallengerFightBonus2;
			_ -> 0
		end
	end,
	ChallengerWinCount = case ChallengerTab of
	    undefined -> 0;
	    _         -> case ets:lookup(ChallengerTab, win_count) of
			[{_, ChallengerWinCount2}] -> ChallengerWinCount2;
			_ -> 0
		end
	end,
	VipLevel = mod_vip:get_role_vip_level(ChallengerID),
	VipLevel < 5 andalso mod_role_cd:add_cd_time(ChallengerID, 12, cfg_rank_match:challenge_cd()),
	case IsChallengerWin of
		true -> %% 如果玩家胜利
			ChallengerAddBonus      = round(FightBonus*0.4),
			ChallengerAddFightBonus = MirrorFightBonus+round(FightBonus*0.5),
			ChallengerResultRank    = min(MirrorRank, ChallengerRank),
			ChallengerHistory = #p_rnkm_history{
				chlg_id     = ChallengerID, 
				time        = Now, 
				enemy_id    = MirrorID, 
				enemy_name  = MirrorName, 
				is_winner   = true, 
				result_rank = ChallengerResultRank,
				add_bonus   = ChallengerAddFightBonus
			},
			MirrorAddBonus      = round(FightBonus*0.1),
			MirrorAddFightBonus = 0 - MirrorFightBonus,
			MirrorResultRank    = max(MirrorRank, ChallengerRank),
			MirrorHistory = #p_rnkm_history{
				chlg_id     = ChallengerID, 
				time        = Now, 
				enemy_id    = ChallengerID, 
				enemy_name  = ChallengerName, 
				is_winner   = false, 
				result_rank = MirrorResultRank,
				add_bonus   = MirrorAddFightBonus+MirrorAddBonus
			},
			ChallengerRank >= MirrorRank andalso case ChallengerTab of
				undefined ->
					ChallengerRank > cfg_rank_match:max_rank() andalso begin
						NewMirror = [
							{modified, true},
							{status, ?MIRROR_BUSY},
							{fight_time, common_tool:now()},
							{win_count, ChallengerWinCount+1},
							{fight_bonus, ChallengerFightBonus+ChallengerAddFightBonus}
							|mod_mirror:copy(ChallengerID)
						],
						ets:delete_all_objects(MirrorTab),
						ets:insert(MirrorTab, NewMirror)
					end;
				_ ->
					ets:insert(ChallengerTab, [
						{modified, true},
						{win_count, ChallengerWinCount+1},
						{fight_bonus, ChallengerFightBonus+ChallengerAddFightBonus}
						|mod_mirror:copy(ChallengerID)
					]),
					ets:insert(MirrorTab, [
						{modified, true},
						{win_count, 0},
						{fight_bonus, 0}
					]),
					ets:insert(t_rnkm, {MirrorRank, ChallengerTab}),
					ets:insert(t_rnkm, {ChallengerRank, MirrorTab})
			end,
			ChallengerRank < MirrorRank andalso  ets:insert(ChallengerTab, [
				{modified, true},
				{win_count, ChallengerWinCount+1},
				{fight_bonus, ChallengerFightBonus+ChallengerAddFightBonus}
			]),
			add_winning_notice(ChallengerID, ChallengerName, ChallengerWinCount+1);
		false -> %% 如果镜像胜利
			ChallengerAddBonus      = round(FightBonus*0.1),
			ChallengerAddFightBonus = 0,
			ChallengerHistory       = #p_rnkm_history{
				chlg_id     = ChallengerID, 
				time        = Now, 
				enemy_id    = MirrorID, 
				enemy_name  = MirrorName, 
				is_winner   = false, 
				change_rank = false, 
				add_bonus   = ChallengerAddFightBonus
			},
			MirrorAddBonus      = round(FightBonus*0.4),
			MirrorAddFightBonus = round(FightBonus*0.5),
			MirrorHistory       = #p_rnkm_history{
				chlg_id     = ChallengerID, 
				time        = Now, 
				enemy_id    = ChallengerID, 
				enemy_name  = ChallengerName, 
				is_winner   = true, 
				change_rank = false, 
				add_bonus   = MirrorAddFightBonus+MirrorAddBonus
			},
			ChallengerTab =/= undefined 
			andalso ets:insert(ChallengerTab, [
				{modified, true},
				{win_count, 0}
			]),
			ets:insert(MirrorTab, [
				{modified, true},
				{win_count, MirrorWinCount+1},
				{fight_bonus, MirrorFightBonus+MirrorAddFightBonus}
			]),
			add_winning_notice(MirrorID, MirrorName, MirrorWinCount+1)
	end,
	add_bonus(ChallengerID, ChallengerAddBonus, ""),
	common_misc:unicast({role, ChallengerID}, ?_rnkm_match_end{
		result = FightResult, 
		bonus  = ChallengerAddBonus
	}),
	update_role_after_chlg(ChallengerID, ChallengerHistory),
	update_role_after_under_chlg(MirrorID, MirrorAddBonus, MirrorHistory),
	common_misc:unicast({role, MirrorID}, ?_rnkm_update_history{history=MirrorHistory}),
	global:send(?MODULE,  {fight_other, IsChallengerWin,
		ChallengerID, ChallengerAddFightBonus, abs(MirrorID), MirrorAddFightBonus}),
	common_general_log_server:log_rnkm(#r_rnkm_log{
		time           = Now,
		rank           = MirrorRank,
		result         = FightResult,
		attacker_id    = ChallengerID,
		attacker_name  = ChallengerName,
		attacker_bonus = ChallengerAddFightBonus+ChallengerAddBonus,
		defencer_id    = MirrorID,
		defencer_name  = MirrorName,
		defencer_bonus = MirrorAddFightBonus+MirrorAddBonus
	}).

update_role_after_chlg(RoleID, History) ->
	RoleInfo = dirty_read(?DB_RNKM_ROLE, RoleID),
	#p_rnkm_role{remain_chances=RemainChances} = p_rnkm_role(RoleInfo),
	mod_daily_counter:set_mission_remain_times(RoleID, 1018, RemainChances-1,true),
	db:dirty_write(?DB_RNKM_ROLE, RoleInfo#r_rnkm_role{
		last_chlg_time = History#p_rnkm_history.time, 
		remain_chances = RemainChances-1,
		histories      = add_history(History, RoleInfo#r_rnkm_role.histories)
	}).

update_role_after_under_chlg(RoleID, UnderChlgBonus, History) ->
	RoleInfo = dirty_read(?DB_RNKM_ROLE, RoleID),
	NewRoleInfo = RoleInfo#r_rnkm_role{
		new_bonus = RoleInfo#r_rnkm_role.new_bonus+UnderChlgBonus,
		histories = add_history(History, RoleInfo#r_rnkm_role.histories)
	},
	db:dirty_write(?DB_RNKM_ROLE, NewRoleInfo),
	common_misc:unicast({role, RoleID}, ?_rnkm_update_role{role=p_rnkm_role(NewRoleInfo)}).

add_chance_gold(1) -> 5;
add_chance_gold(AddedChances) when AddedChances =< 5 -> 10;
add_chance_gold(_) -> 20.

%%增加挑战次数
handle({_Unique, ?RNKM, ?RNKM_ADD_CHANCE, _DataIn, RoleID, PID, _Line}, _MapState) ->
	RoleInfo = dirty_read(?DB_RNKM_ROLE, RoleID),
	#p_rnkm_role{
		added_chances  = AddedChances, 
		remain_chances = RemainChances
	} = p_rnkm_role(RoleInfo),
	case common_transaction:t(fun
		() ->
			common_bag2:t_deduct_money(gold_unbind, 
				round(add_chance_gold(AddedChances + 1)), 
				RoleID, ?CONSUME_TYPE_GOLD_RNKM_ADD_CHANCE)
		end) of
		{_, {ok,NewRoleAttr}}->
			ChangeList = [
				#p_role_attr_change{
					change_type = ?ROLE_GOLD_BIND_CHANGE, 
					new_value   = NewRoleAttr#p_role_attr.gold_bind
				},
				#p_role_attr_change{
					change_type = ?ROLE_GOLD_CHANGE, 
					new_value   = NewRoleAttr#p_role_attr.gold
				}
			],
			common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
			NewRoleInfo = RoleInfo#r_rnkm_role{
				added_chances  = AddedChances+1,
				remain_chances = RemainChances+1, 
				last_add_time  = common_tool:now()
			},
			mod_daily_counter:set_mission_remain_times(RoleID, 1018, RemainChances+1, true),
			db:dirty_write(?DB_RNKM_ROLE, NewRoleInfo),
			common_misc:unicast2(PID, ?_rnkm_update_role{role=p_rnkm_role(NewRoleInfo)});
		{_, {error,gold_any}}->
			common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"礼券不足">>});
		{_, {error,gold_unbind}}->
			common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"元宝不足">>});
		{_, {error,Reason}} ->
			common_misc:unicast2(PID, ?_rnkm_error{mesg = Reason})
	end;

%%领取奖励
handle({_Unique, ?RNKM, ?RNKM_GET_BONUS, _DataIn, RoleID, PID, _Line}, _MapState) ->
	RoleInfo = dirty_read(?DB_RNKM_ROLE, RoleID),
	#r_rnkm_role{old_bonus=OldBonus} = RoleInfo,
	case OldBonus =< 0 of
	true ->
		common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"没有奖励钱币">>});
	false ->
		case add_bonus(RoleID, round(OldBonus), "你领取了个人竞技奖励：") of
		ok ->
			NewRoleInfo=RoleInfo#r_rnkm_role{old_bonus=0},
			db:dirty_write(?DB_RNKM_ROLE, NewRoleInfo),
			common_misc:unicast2(PID, ?_rnkm_update_role{role=p_rnkm_role(NewRoleInfo)});
		_ ->
			ignore
		end
	end;

%%查询镜像属性
handle({Unique, ?RNKM, ?RNKM_MIRROR_ATTR, DataIn, RoleID, PID, _Line}, _MapState) ->
	#m_rnkm_mirror_attr_tos{mirror_id=MirrorID} = DataIn,
	MirrorTab  = ets:lookup_element(t_rnkm, MirrorID, 2),
	[RoleBase] = ets:lookup(MirrorTab, p_role_base),
	[RoleAttr] = ets:lookup(MirrorTab, p_role_attr),
	RoleInfo = mod_role2:p_other_role_info(RoleBase, RoleAttr),
	MirrorRoleID = abs(RoleBase#p_role_base.role_id),
	{ok, _, CanWorship, RemTimes} = mod_role_worship:get_worship_info(RoleID, MirrorRoleID),
	{ok, WorshipCount, DisdainCount} = mod_role_worship:count(MirrorRoleID),
	common_misc:unicast2(PID, ?_role2_getroleattr{
		role_info = RoleInfo,
		worship_info = #p_worship_info{
			can_worship   = CanWorship,
			rem_times     = RemTimes,
            worship_count = WorshipCount, 
            disdain_count = DisdainCount
    	}
	});

%%快速冷却
handle({_Unique, ?RNKM, ?RNKM_REFRESH_CD, _DataIn, RoleID, PID, _Line}, _MapState) ->
	case mod_role_cd:clear_cd(RoleID, 12) of
		{error, Reason} -> common_misc:unicast2(PID, ?_rnkm_error{mesg = Reason});
		true ->
			RoleInfo     = dirty_read(?DB_RNKM_ROLE, RoleID),
			LastChlgTime = erlang:min(RoleInfo#r_rnkm_role.last_chlg_time, common_tool:now()),
			db:dirty_write(?DB_RNKM_ROLE, RoleInfo#r_rnkm_role{
				last_chlg_time = erlang:max(0, LastChlgTime-cfg_rank_match:challenge_cd())
			}),
			mod_role_cd:send_cd_info_to_client(RoleID, 12)
	end.

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% --------------------------------------------------------------------
init([]) ->
	random:seed(now()),
	erlang:send(self(), init),
	ets:new(t_rnkm, [named_table, public]),
	ets:new(t_rnkm_watcher, [named_table, public]),
	ets:new(t_rnkm_notice, [named_table, public]),
	ets:insert(t_rnkm_notice, {notices, []}),
	{ok, #state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% --------------------------------------------------------------------
handle_call(get, _From, State) ->
	{reply, get(), State};

handle_call({get, Key}, _From, State) ->
	{reply, get(Key), State};

handle_call({put, Key, Val}, _From, State) ->
	{reply, put(Key, Val), State};

handle_call(clear, _From, State) ->
	lists:foreach(fun
		({'$ancestors', _}) ->
			  ignore;
		 ({'$initial_call', _}) ->
			  ignore;
		 ({last_rank, _}) ->
			  put(last_rank, 0);
		 ({Key, _}) ->
			  erase(Key)
	  end,  get()),
	{reply, ok, State};

handle_call(_Request, _From, State) ->
	{reply, ignore, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% --------------------------------------------------------------------
handle_cast(_Msg, State) ->
	{noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% --------------------------------------------------------------------
handle_info(Info, State) ->
	?DO_HANDLE_INFO(Info, State),
	{noreply, State}.

do_handle_info(init) ->
	case common_global:get(max_role_level_yesterday) of
		undefined ->
			erlang:spawn(fun() ->
				RankList=db:dirty_match_object(?DB_ROLE_LEVEL_RANK_P, #p_role_level_rank{_='_'}),
				MaxRoleLevel = case lists:keyfind(1, #p_role_level_rank.ranking, RankList) of
					 #p_role_level_rank{level=MaxRoleLevel2} ->
						 MaxRoleLevel2;
					 _ ->
						 1
				end,
				common_global:put(max_role_level_yesterday, MaxRoleLevel)
			end);
		_ ->
			ignore
	end,
	countdown(give_bonus, ?GIVE_BONUS_TIME),
	countdown(add_bonus, ?ADD_BONUS_INTERVAL),
	countdown(update_heros, ?UPDATE_HEROS_INTERVAL),
	countdown(persist_mirrors, ?PERSIST_MIRRORS_INTERVAL),
	init(mt_mnesia:show_table(?DB_RNKM_MIRROR), _Len=0);

%%打开竞技场界面
do_handle_info({_Unique, ?RNKM, ?RNKM_OPEN, _DataIn, RoleID, PID, _Line}) ->
	RoleRank = get_rank(RoleID),
	case RoleRank =< cfg_rank_match:max_rank() andalso not is_ranked(RoleID) of
	true ->
		set_last_rank(RoleRank),
		set_rank(RoleID, RoleRank),
		Mirror = [
			{modified, true},
			{win_count, 0},
			{fight_time, 0},
			{fight_bonus, 0},
			{status, ?MIRROR_IDLE}
			|mod_mirror:copy(RoleID)
		],
		MirrorTab = ets:new(t_mirror, [public]),		
		ets:insert(MirrorTab, Mirror),
		ets:insert(t_rnkm, {RoleRank, MirrorTab});
	false ->
		ignore
	end,
	ListenRanks = get_random_listen_ranks(RoleRank),
	set_listen_ranks(RoleID, ListenRanks),
	lists:foreach(fun
		(ListenRank) -> 
			add_listener(ListenRank, RoleID) 
	end, ListenRanks),
	RoleInfo = dirty_read(?DB_RNKM_ROLE, RoleID),
	common_misc:unicast2(PID, ?_rnkm_open{
		role      = p_rnkm_role(RoleInfo), 
		mirrors   = [M||ListenRank<-ListenRanks,
			is_record(M = get_mirror(ListenRank), p_rnkm_mirror)],
		histories = RoleInfo#r_rnkm_role.histories,
		notices   = ets:lookup_element(t_rnkm_notice, notices, 2)
	}),
	mod_role_cd:send_cd_info_to_client(RoleID, 12),
	ets:insert(t_rnkm_watcher, {RoleID});

%%关闭竞技场界面
do_handle_info({_Unique, ?RNKM, ?RNKM_CLOSE, _DataIn, RoleID, _PID, _Line}) ->
	lists:foreach(fun
		(Rank) -> del_listener(Rank, RoleID) 
	end, del_listen_ranks(RoleID)),
	ets:delete(t_rnkm_watcher, RoleID);

%%查看英雄榜
do_handle_info({_Unique, ?RNKM, ?RNKM_HEROS, _DataIn, _RoleID, PID, _Line}) ->
	common_misc:unicast2(PID, ?_rnkm_heros{heros=get_heros()});

%%挑战镜像
do_handle_info({Unique, ?RNKM, ?RNKM_CHALLENGE, DataIn, RoleID, PID, Line}) ->
	#m_rnkm_challenge_tos{
		rank      = ChlgRank, 
		role_id   = ChlgRoleID, 
		vip_level = VipLevel
	} = DataIn,
	RoleInfo = dirty_read(?DB_RNKM_ROLE, RoleID),
	#p_rnkm_role{
		% chlg_time      = ChlgTime, 
		remain_chances = RemainChances
	} = p_rnkm_role(RoleInfo),
	Now        = common_tool:now(),
	RoleRank   = get_rank(RoleID),
	RoleMirror = get_mirror(RoleRank),
	ChlgMirror = get_mirror(ChlgRank),
	% ChlgCD     = cfg_rank_match:challenge_cd(),
	TimeDiff   = calendar:time_to_seconds(?GIVE_BONUS_TIME) - calendar:time_to_seconds(time()),
	IsRoleFighting   = is_fighting(RoleMirror, Now),
	IsMirrorFighting = is_fighting(ChlgMirror, Now),
	IsListenRank     = lists:member(ChlgRank, get_listen_ranks(RoleID)),
	#p_role_pos{map_id=MapID} = mod_role_tab:get({?role_pos, RoleID}),
	IsCopyMap = mcm:is_copy(MapID),

	% #p_map_role{state=RoleState} = mod_map_actor:get_actor_mapinfo(RoleID, role),
    
    %% 是否达到最小进入等级
    % [MinLevel] = ?find_config( {min_enter_level,BarrierID}),

    SkinMissionFlag = mod_mission_change_skin:is_doing_change_skin_mission(RoleID),

    IsInCd = mod_role_cd:is_in_cd(RoleID, 12),

	if
	% RoleState == ?ROLE_STATE_EAT -> 
	% 	common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"点餐状态不能进行挑战">>});
	SkinMissionFlag ->
		common_misc:unicast2(PID, ?_rnkm_error{mesg = ?_LANG_XIANNVSONGTAO_MSG});
	RoleID == abs(ChlgRoleID) ->
		common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"不能挑战自己">>});
	RemainChances =< 0 ->
		common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"已经超过当天最大挑战次数">>});
	VipLevel < 5 andalso IsInCd ->
		common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"挑战冷却时间未到">>});
	TimeDiff >= 0, TimeDiff =< 60 ->
		common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"发放奖励前1分钟，不能挑战">>});
	is_record(RoleMirror, p_rnkm_mirror), 
	RoleMirror#p_rnkm_mirror.status == ?MIRROR_INIT ->
		common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"玩家正在进入竞技场，请稍候">>});
	IsRoleFighting ->
		common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"你正在战斗中">>});
	ChlgMirror#p_rnkm_mirror.status == ?MIRROR_INIT ->
		common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"玩家正在进入竞技场，请稍候">>});
	IsMirrorFighting ->
		common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"该玩家正在战斗中">>});
	ChlgRoleID /= ChlgMirror#p_rnkm_mirror.role_id ->
		do_handle_info({Unique, ?RNKM, ?RNKM_OPEN, #m_rnkm_open_tos{}, RoleID, PID, Line});
	not IsListenRank ->
		common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"不能挑战该玩家">>});
	?IS_MIRROR_FB(MapID) ->
		mgeer_role:absend(RoleID, {mod, mod_mirror_fb, {terminate, RoleID}}),
		common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"系统繁忙，请稍后再试">>});
	IsCopyMap ->
		common_misc:unicast2(PID, ?_rnkm_error{mesg = <<"副本地图中不能发起挑战">>});
	true ->
		put({fight_ranks, RoleID}, [RoleRank, ChlgRank]),
		case RoleID /= ChlgRoleID andalso is_record(RoleMirror, p_rnkm_mirror) of
			true ->
				RoleTab = ets:lookup_element(t_rnkm, RoleRank, 2),
				ets:insert(RoleTab, [{status, ?MIRROR_BUSY}, {fight_time, Now}]),
				ExtInfo = [{role_table, RoleTab}, {role_rank, RoleRank}, {mirror_rank, ChlgRank}];
			false ->
				ExtInfo = [{role_table, undefined}, {role_rank, undefined}, {mirror_rank, ChlgRank}]
		end,
		MirrorTab = ets:lookup_element(t_rnkm, ChlgRank, 2),
		ets:insert(MirrorTab, [{status, ?MIRROR_BUSY}, {fight_time, Now}]),
		%% 获得积分
		mod_score:gain_score_notify(RoleID, ?SCORE_TYPE_JINGJI,{?SCORE_TYPE_JINGJI,"竞技获得积分"}),
		RoleProcName = mgeer_role:proc_name(RoleID),
		RolePID = global:whereis_name(RoleProcName),
		
		common_misc:send_to_rolemap(RoleID, {mod, mod_mirror_fb, 
			{change_map, RoleID, 10323, RolePID, RoleProcName, MirrorTab, ExtInfo}
		}),
		if (RemainChances - 1) =< 0 ->
			mod_access_guide:send_hook_info(RoleID, {rnkm, RoleID});
		true ->
			ignore
		end,
		%% 完成活动
		hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_MIRROR),
		mgeer_role:send(RoleID, {apply, hook_mission_event, hook_special_event, [RoleID, ?MISSION_EVENT_RNKM_CHALLENGE]}),
		% hook_mission_event:hook_special_event(RoleID,?MISSION_EVENT_RNKM_CHALLENGE),
		mod_random_mission:handle_event(RoleID, ?RAMDOM_MISSION_EVENT_15)
	end;

%%战斗结束，玩家挑战自己的镜像
do_handle_info({fight_self, RoleID}) ->
	RoleRank = get_rank(RoleID),
	Pmirror  = get_mirror(RoleRank),
	lists:foreach(fun(ListenerID) ->
		common_misc:unicast({role, ListenerID}, 
			?_rnkm_update_mirror{ mirror = Pmirror })
	end, get_listeners(RoleRank));

%%战斗结束，玩家挑战他人的镜像
do_handle_info({fight_other, IsAttackerWin,
				AttackerID, AttackerAddFightBonus, 
				DefencerID, DefencerAddFightBonus}) ->
	AttackerRank = get_rank(AttackerID),
	DefencerRank = get_rank(DefencerID),
	NewAttackerRank = case AttackerRank < DefencerRank orelse IsAttackerWin of
		true ->
			min(AttackerRank, DefencerRank);
		false ->
			max(AttackerRank, DefencerRank)
	end,
	NewDefencerRank = case AttackerRank < DefencerRank orelse IsAttackerWin of
		true ->
			max(AttackerRank, DefencerRank);
		false ->
			min(AttackerRank, DefencerRank)
	end,
	AttackerMirror = case get_mirror(AttackerRank) of
		undefined ->
			{ok, RoleBase} = mod_map_role:get_role_base(AttackerID),
			{ok, RoleAttr} = mod_map_role:get_role_attr(AttackerID),
			#p_rnkm_mirror{
				role_id    = AttackerID, 
				role_name  = RoleBase#p_role_base.role_name, 
				role_level = RoleAttr#p_role_attr.level, 
				sex        = RoleBase#p_role_base.sex, 
				category   = RoleAttr#p_role_attr.category
			};
		AttackerMirror0 ->
			AttackerMirror0
   end,
	DefencerMirror = get_mirror(DefencerRank),
	case NewAttackerRank =< cfg_rank_match:max_rank() of
		true ->
			set_rank(AttackerID, NewAttackerRank),
			NewAttackerBonus  = AttackerMirror#p_rnkm_mirror.fight_bonus+AttackerAddFightBonus,
			NewAttackerMirror = AttackerMirror#p_rnkm_mirror{
				rank        = NewAttackerRank,
				status      = ?MIRROR_IDLE, 
				fight_bonus = erlang:max(0, NewAttackerBonus)
			},
			Pmirror1 = get_mirror(NewAttackerMirror),
			lists:foreach(fun(ListenerID) ->
				common_misc:unicast({role, ListenerID}, ?_rnkm_update_mirror{
					mirror = Pmirror1
				})
			end, get_listeners(NewAttackerRank));
		false ->
			del_rank(AttackerID)
	end,
	case NewDefencerRank =< cfg_rank_match:max_rank() of
		true ->
			set_rank(DefencerID, NewDefencerRank),
			NewDefencerBonus=DefencerMirror#p_rnkm_mirror.fight_bonus+DefencerAddFightBonus,
			NewDefencerMirror=DefencerMirror#p_rnkm_mirror{
				rank        = NewDefencerRank, 
				status      = ?MIRROR_IDLE, 
				fight_bonus = erlang:max(0, NewDefencerBonus)
			},
			Pmirror2 = get_mirror(NewDefencerMirror),
			lists:foreach(fun(ListenerID) ->
				common_misc:unicast({role, ListenerID}, ?_rnkm_update_mirror{
					mirror = Pmirror2
				})
			end, get_listeners(NewDefencerRank));
		false ->
			common_misc:unicast({role, DefencerID}, ?_rnkm_update_mirror{}),
			del_rank(DefencerID)
	end,
	case AttackerRank > DefencerRank andalso IsAttackerWin of
		true ->
			lists:foreach(fun(Rank) -> 
				del_listener(Rank, AttackerID) 
			end, del_listen_ranks(AttackerID)),
			lists:foreach(fun(Rank) -> 
				del_listener(Rank, DefencerID) 
			end, del_listen_ranks(DefencerID));
		false ->
			ignore
	end;

%%更新英雄榜
do_handle_info(update_heros) ->
	countdown(update_heros, ?UPDATE_HEROS_INTERVAL),
	Heros = get_heros(),
	NewHeros = [begin
		#p_rnkm_mirror{
			role_id    = RoleID,
			role_name  = RoleName,
			role_level = RoleLevel
		} = Mirror,
		Trend = case lists:keyfind(RoleID, #p_rnkm_hero.role_id, Heros) of
			false ->
				?TREND_UP;
			#p_rnkm_hero{rank=OldRank} ->
				if Rank  > OldRank -> ?TREND_UP;
				   Rank == OldRank -> ?TREND_KEEP;
				   Rank  < OldRank -> ?TREND_DOWN
				end
		end,
		#p_rnkm_hero{
			rank       = Rank,
			role_id    = RoleID,
			role_name  = RoleName,
			role_level = RoleLevel,
			trend      = Trend
		}
	end||Rank<-lists:seq(1, 10), is_record(Mirror = get_mirror(Rank), p_rnkm_mirror)],
	set_heros(NewHeros);

do_handle_info(add_bonus) ->
	countdown(add_bonus, ?ADD_BONUS_INTERVAL),
	foreach_mirror(fun({MirrorRank, MirrorTab})->
		#p_rnkm_mirror{
			role_id    = RoleID, 
			rank_bonus = RankBonus
		} = get_mirror(MirrorRank, MirrorTab),
		RoleInfo = dirty_read(?DB_RNKM_ROLE, RoleID),
		#r_rnkm_role{new_bonus = NewBonus} = RoleInfo,
		NewRoleInfo = RoleInfo#r_rnkm_role{
			new_bonus = NewBonus + RankBonus
		},
		db:dirty_write(?DB_RNKM_ROLE, NewRoleInfo),
		common_misc:unicast({role, RoleID}, ?_rnkm_update_role{
			role = p_rnkm_role(NewRoleInfo)
		})
	end);

do_handle_info(give_bonus) ->
	countdown(give_bonus, ?GIVE_BONUS_TIME),
	foreach_mirror(fun({MirrorRank, MirrorTab}) ->
		Mirror = #p_rnkm_mirror{
			role_id     = RoleID,
			fight_bonus = FightBonus, 
			rank_bonus  = RankBonus
		} = get_mirror(MirrorRank, MirrorTab),
		RoleInfo = #r_rnkm_role{
			old_bonus = OldBonus, 
			new_bonus = NewBonus
		} = dirty_read(?DB_RNKM_ROLE, RoleID),
		NewRoleInfo = RoleInfo#r_rnkm_role{
			old_bonus = OldBonus+NewBonus+FightBonus+RankBonus,
			new_bonus = 0
		},
		db:dirty_write(?DB_RNKM_ROLE, NewRoleInfo),
		ets:insert(MirrorTab, [{modified, true}, {fight_bonus, 0}]),
		lists:foreach(fun(ListenerID) ->
			common_misc:unicast({role, ListenerID}, ?_rnkm_update_mirror{
				mirror = Mirror#p_rnkm_mirror{fight_bonus=0}
			})
		end, get_listeners(MirrorRank)),
		common_misc:unicast({role, RoleID}, ?_rnkm_update_role{
			role = p_rnkm_role(NewRoleInfo)
		})
	end);

do_handle_info(persist_mirrors) ->
	countdown(persist_mirrors, ?PERSIST_MIRRORS_INTERVAL),
	foreach_mirror(fun({MirrorRank, MirrorTab})->
		case ets:lookup(MirrorTab, modified) of
			[{_, true}] ->
				ets:delete(MirrorTab, modified),
				db:dirty_write(?DB_RNKM_MIRROR, #r_rnkm_mirror{
					rank   = MirrorRank,
					detail = ets:tab2list(MirrorTab)
				});
			_ ->
				ignore
		end
	end);
	
do_handle_info({mirror_fb_stop, RoleID}) ->
	case erase({fight_ranks, RoleID}) of
		undefined ->
			ignore;
		Ranks ->
			[case ets:lookup(t_rnkm, Rank) of
				[{_, MirrorTab}] ->
					ets:update_element(MirrorTab, status, {2, ?MIRROR_IDLE});
				_ ->
					ignore
			end||Rank<-Ranks]
	end;

do_handle_info(_Info) ->
	ignore.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
	do_handle_info(persist_mirrors),
	ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
init([Mirror|T], Len) ->

	#r_rnkm_mirror{
		rank   = Rank,
		detail = Detail
	} = Mirror,
	MirrorTab = ets:new(t_mirror, [public]),
	ets:insert(MirrorTab, Detail),
	ets:insert(t_rnkm, {Rank, MirrorTab}),
	RoleBase = lists:keyfind(p_role_base, 1, Detail),
	set_rank(abs(RoleBase#p_role_base.role_id), Rank),
	init(T, Len+1);

init([], Len) ->
	set_last_rank(Len).

get_last_rank() ->
	ets:info(t_rnkm,size).

set_last_rank(Rank) ->
	put(last_rank, Rank).

is_ranked(RoleID) ->
	get({rank, RoleID}) /= undefined.

get_rank(RoleID) ->
	case get({rank, RoleID}) of
	undefined ->
		get_last_rank()+1;
	Rank ->
		Rank
	end.

set_rank(RoleID, Rank) ->
	put({rank, RoleID}, Rank).

del_rank(RoleID) ->
	erase({rank, RoleID}).

get_mirror(Mirror = #p_rnkm_mirror{rank=Rank}) ->
	Mirror#p_rnkm_mirror{rank_bonus=get_rank_bonus(Rank)};

get_mirror(Rank) ->
	case ets:lookup(t_rnkm, Rank) of
	[{_, MirrorTab}] ->
		case ets:info(MirrorTab) of
			undefined ->
				undefined;
			_ ->
				get_mirror(Rank, MirrorTab)
		end;
	_ ->
		undefined
	end.
 
get_mirror(Rank, MirrorTab) ->
	[RoleBase] = ets:lookup(MirrorTab, p_role_base),
	[RoleAttr] = ets:lookup(MirrorTab, p_role_attr),
	#p_rnkm_mirror{
		rank        = Rank,
		role_id     = abs(RoleBase#p_role_base.role_id),
		role_name   = RoleBase#p_role_base.role_name,
		sex         = RoleBase#p_role_base.sex,
		role_level  = RoleAttr#p_role_attr.level,
		category    = RoleAttr#p_role_attr.category,
		status      = case ets:lookup(MirrorTab, status) of
			[{_, Status}] -> Status;
			_ -> ?MIRROR_IDLE
		end,
		fight_bonus = case ets:lookup(MirrorTab, fight_bonus) of
			[{_, FightBonus}] -> FightBonus;
			_ -> 0
		end,
		fight_time  = case ets:lookup(MirrorTab, fight_time) of
			[{_, FightTime}] -> FightTime;
			_ -> 0
		end,
		rank_bonus  = get_rank_bonus(Rank)
	}.

get_listeners(Rank) ->
	case get({listeners, Rank}) of
	undefined ->
		[];
	List ->
		List
	end.

get_listen_ranks(RoleID) ->
	case get({listen_ranks, RoleID}) of
	undefined ->
		[];
	Ranks ->
		Ranks
	end.

set_listen_ranks(RoleID, Ranks) ->
	put({listen_ranks, RoleID}, Ranks).

del_listen_ranks(RoleID) ->
	case erase({listen_ranks, RoleID}) of
	undefined ->
		[];
	Ranks ->
		Ranks
	end.

add_listener(Rank, RoleID) ->
	Rank >= 1 andalso Rank =< cfg_rank_match:max_rank()
		andalso put({listeners, Rank}, [RoleID|lists:delete(RoleID, get_listeners(Rank))]).

del_listener(Rank, RoleID) ->
	Rank >= 1 andalso Rank =< cfg_rank_match:max_rank()
		andalso put({listeners, Rank}, lists:delete(RoleID, get_listeners(Rank))).

add_history(History, Histories) ->
	[History|lists:sublist(Histories, ?MAX_HISTORY_COUNT-1)].

get_heros() ->
	case get(heros) of
	undefined ->
		[];
	Heros ->
		Heros
	end.

is_fighting(#p_rnkm_mirror{status=?MIRROR_BUSY, fight_time=FightTime}, Time) when Time < FightTime + ?MAX_FIGHT_TIME ->
	true;

is_fighting(_Mirror, _Time) ->
	false.

dirty_read(?DB_RNKM_ROLE, RoleID) ->
	case db:dirty_read(?DB_RNKM_ROLE, RoleID) of
		[] ->
			#r_rnkm_role{role_id=RoleID, remain_chances=cfg_rank_match:max_chances()};
		[Rec] ->
			Rec
	end.

p_rnkm_role(#r_rnkm_role{
	role_id        = RoleID, 
	old_bonus      = OldBonus, 
	new_bonus      = NewBonus, 
	last_chlg_time = ChlgTime, 
	remain_chances = ReaminChances, 
	added_chances  = AddedChances, 
	last_add_time  = LastAddTime}) ->
	
	Date = date(),
	AddedChances2 = case common_tool:seconds_to_datetime(LastAddTime) of
		{Date, _} ->
			AddedChances;
		_ ->
			0
	end,
	ReaminChances2 = case common_tool:seconds_to_datetime(erlang:max(LastAddTime, ChlgTime)) of
		{Date, _} ->
			ReaminChances;
		_ ->
			cfg_rank_match:max_chances()
	end,
	#p_rnkm_role{
		role_id        = RoleID, 
		old_bonus      = OldBonus, 
		new_bonus      = NewBonus, 
		chlg_time      = ChlgTime, 
		remain_chances = ReaminChances2, 
		added_chances  = AddedChances2
	}.

set_heros(Heros) ->
	put(heros, Heros).

add_bonus(RoleID, Bonus, Msg) ->
	case common_transaction:t(fun() ->
			%%  奖励的金钱改成经验
			{ok,RoleAttr}     = mod_map_role:get_role_attr(RoleID),
			{ok,NewRoleAttr}  = common_bag2:t_gain_money(
				silver_bind, Bonus, RoleAttr, ?GAIN_TYPE_SILVER_FROM_RNKM),
			% ok = common_bag2:t_add_exp(RoleID, Bonus),
			% {ok,NewRoleAttr}     = mod_map_role:get_role_attr(RoleID),
			{ok,NewRoleAttr2} = common_bag2:t_gain_prestige(
				Bonus, NewRoleAttr, ?GAIN_TYPE_PRESTIGE_FROM_RNKM),
			mod_map_role:set_role_attr(RoleID,NewRoleAttr2),
			{ok,NewRoleAttr2}
		 end) of
		{atomic,{ok, NewRoleAttr2}} ->
			ChangeList = [
				#p_role_attr_change{
					change_type = ?ROLE_SILVER_BIND_CHANGE, 
					new_value   = NewRoleAttr2#p_role_attr.silver_bind
				},
				#p_role_attr_change{
					change_type = ?ROLE_SUM_PRESTIGE_CHANGE, 
					new_value   = NewRoleAttr2#p_role_attr.sum_prestige
				},
				#p_role_attr_change{
					change_type = ?ROLE_CUR_PRESTIGE_CHANGE, 
					new_value   = NewRoleAttr2#p_role_attr.cur_prestige
				}],
			common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
			case Msg of
				"" ->
					ignore;
				_ ->
					common_broadcast:bc_send_msg_role(RoleID, 
						[?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_SYSTEM], 
						lists:concat([
							Msg,common_misc:format_silver(Bonus),",",Bonus,"声望"
						]))
			end,
			ok;
		_ ->
			error
	end.

get_fight_bonus(Rank) ->
	MaxRoleLevel = common_global:get(max_role_level_yesterday, 1),
	cfg_rank_match:fight_bonus(MaxRoleLevel, Rank).

get_rank_bonus(Rank) ->
	MaxRoleLevel = common_global:get(max_role_level_yesterday, 1),
	cfg_rank_match:rank_bonus(MaxRoleLevel, Rank).

countdown(Type, Time) ->
	case get({timer, Type}) of
		Timer when is_reference(Timer) ->
			erlang:cancel_timer(Timer);
		_ ->
			ignore
	end,
	After = case is_integer(Time) of
		true ->
			Time;
		_ ->
			Secs = calendar:time_to_seconds(Time) - calendar:time_to_seconds(time()),
			if Secs =< 0 -> 86400 + Secs; true -> Secs end
	end,
	put({timer, Type}, erlang:send_after(After*1000, self(), Type)).


get_random_listen_ranks(Rank) when Rank =< 10 ->
	[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

get_random_listen_ranks(Rank) ->
	Rank2 = erlang:min(cfg_rank_match:max_rank(), Rank),
	get_random_listen_ranks(max(1, Rank2 div 10 - 1), [Rank2]).

get_random_listen_ranks(_Step, Result) when length(Result) >= 10 ->
	Result;

get_random_listen_ranks(Step, [H|T]) ->
	get_random_listen_ranks(Step, [H-random:uniform(Step), H|T]).
	
send_wining_event(WinnerID, WinCount) ->
	case common_misc:is_role_online(WinnerID) of
		true ->
			mod_achievement2:achievement_update_event(WinnerID, 42006, WinCount),
			mod_achievement2:achievement_update_event(WinnerID, 43001, WinCount),
			mod_achievement2:achievement_update_event(WinnerID, 44003, WinCount);
		false ->
			mod_offline_event:add_event(WinnerID, ?OFFLINE_EVENT_TYPE_WIN_COUNT, WinCount)
	end.

add_winning_notice(WinnerID, WinnerName, WinCount) when WinCount == 10;
														WinCount == 20;
														WinCount == 30;
														WinCount == 50;
														WinCount == 80;
														WinCount == 100 ->
	send_wining_event(WinnerID, WinCount),
	NewNotice = #p_rnkm_notice{
		winner_id   = WinnerID,
		winner_name = WinnerName,
		win_count   = WinCount	   
	},
	NewNotices = case ets:lookup_element(t_rnkm_notice, notices, 2) of
		[N1, N2, _N3|_] ->
			[NewNotice, N1, N2];
		OldNotices ->
			[NewNotice|OldNotices]
	end,
	ets:insert(t_rnkm_notice, {notices, NewNotices}),
	lists:foreach(fun({RoleID}) ->
		common_misc:unicast({role, RoleID}, ?_rnkm_update_notice{ notice = NewNotice })
	end, ets:tab2list(t_rnkm_watcher)),
	Boradcast = fun(JingjieChang) -> 
		case WinCount of
			10 ->
				common_misc:format_lang(<<"【~s】在~s连胜了10场，试图引起大家注意！">>, [WinnerName, JingjieChang]);
			20 ->
				common_misc:format_lang(<<"【~s】在~s连胜了20场，正在一旁偷着笑！">>, [WinnerName, JingjieChang]);
			30 ->
				common_misc:format_lang(<<"【~s】在~s连胜了30场，正在得瑟地昂着头！">>, [WinnerName, JingjieChang]);
			50 ->
				common_misc:format_lang(<<"【~s】在~s连胜了50场，已经无法阻止他了！">>, [WinnerName, JingjieChang]);
			80 ->
				common_misc:format_lang(<<"【~s】在~s连胜了80场，这是要逆天吗？">>, [WinnerName, JingjieChang]);
			100 ->
				common_misc:format_lang(<<"【~s】在~s连胜了100场，算了随他去吧……">>, [WinnerName, JingjieChang])
		end
	end,
	JingjieChang1 = "<a href=\"event:open|OPEN_RANKMATCH_PANEL\"><font color=\"#00FF00\"><u>竞技场</u></font></a>",
	common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,Boradcast(JingjieChang1)),
	common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT_WORLD,Boradcast("竞技场"));
add_winning_notice(WinnerID, _WinnerName, WinCount) ->
	send_wining_event(WinnerID, WinCount).

foreach_mirror(Fun) ->
	lists:foreach(fun({MirrorRank, MirrorTab}) ->
		case ets:info(MirrorTab) of
			undefined ->
				ignore;
			_ ->
	  			Fun({MirrorRank, MirrorTab})
		end
	end, ets:tab2list(t_rnkm)).
