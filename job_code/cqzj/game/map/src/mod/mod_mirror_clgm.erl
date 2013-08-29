%%% -------------------------------------------------------------------
%%% Author  : xierf
%%% Description :血战到底 Challenage Match
%%%
%%% Created : 2012-6-7
%%% -------------------------------------------------------------------
-module(mod_mirror_clgm).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").

-define(CHLG_MATCH_MAP_ID, 10324).

-define(MAX_ARENA_NUM, 24).
-define(RANK_PER_ARENA, 3).
-define(MAX_HISTORY_COUNT, 20).
-define(MAX_FIGHT_TIME, 40).

-define(FIGHT_RESULT(IsRoleWin), case IsRoleWin of true -> 1; false -> 2 end).

-define(MIRROR_INIT, 0).
-define(MIRROR_IDLE, 1).
-define(MIRROR_BUSY, 2).

-define(GIVE_BONUS_TIME, {10, 0, 0}).
-define(PERSIST_MIRRORS_INTERVAL, 900).

-define(_clgm_error, ?DEFAULT_UNIQUE, ?CLGM, ?CLGM_ERROR, #m_clgm_error_toc).
-define(_clgm_open, Unique, ?CLGM, ?CLGM_OPEN, #m_clgm_open_toc).
-define(_clgm_rotate, Unique, ?CLGM, ?CLGM_ROTATE, #m_clgm_rotate_toc).
-define(_clgm_lookup_arena, Unique, ?CLGM, ?CLGM_LOOKUP_ARENA, #m_clgm_lookup_arena_toc).
-define(_clgm_update_role, ?DEFAULT_UNIQUE, ?CLGM, ?CLGM_UPDATE_ROLE, #m_clgm_update_role_toc).
-define(_clgm_update_mirror, ?DEFAULT_UNIQUE, ?CLGM, ?CLGM_UPDATE_MIRROR, #m_clgm_update_mirror_toc).
-define(_clgm_update_history, ?DEFAULT_UNIQUE, ?CLGM, ?CLGM_UPDATE_HISTORY, #m_clgm_update_history_toc).
-define(_role2_getroleattr, Unique, ?ROLE2, ?ROLE2_GETROLEATTR, #m_role2_getroleattr_toc).

%% --------------------------------------------------------------------
%% External exports
-export([start/0, start_link/0, after_fight/4, mirror_fb_stop/1, handle/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([weight_random/1]).

-import(common_tool, [to_list/1]).

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
start() ->
	supervisor:start_child(mgeem_sup, {?MODULE, {?MODULE, start_link, []}, transient, 30000, worker, [?MODULE]}).

start_link() ->
	gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%%玩家退出副本
mirror_fb_stop(RoleID) ->
	global:send(?MODULE, {mirror_fb_stop, RoleID}).
	

%%玩家挑战镜像战斗结束
after_fight(RoleID, MirrorID, MirrorTab, IsRoleWin) ->
	{ok, #p_role_attr{level = Level}} = mod_map_role:get_role_attr(RoleID),
	{ok, #p_role_base{role_name = RoleName}} = mod_map_role:get_role_base(RoleID),
	MirrorRank = ets:lookup_elment(MirrorTab, rank, 2),
	[#p_role_attr{
		role_id   = MirrorID,
		role_name = MirrorName,
		level     = MirrorLevel
 	}] = ets:lookup(MirrorTab, p_role_attr),
	FightBonus = get_fight_bonus(Level, MirrorRank, IsRoleWin),
	case IsRoleWin of
	true ->
		add_bonus(RoleID, FightBonus, "你在血战到底中挑战"++to_list(MirrorName)++"胜利，获得"),
		ArenaName = get_arena_name(MirrorRank),
		common_letter:sys2p(MirrorID, lists:concat([
			"你被", to_list(RoleName), "击败了，失去了", ArenaName,
			"擂台的擂主之位【第", get_real_rank(MirrorRank), "名】，赶快去挑战夺回吧！"
		]), "血战到底通知"),
		common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT_WORLD, 
			lists:concat([
				to_list(RoleName), "击败了", to_list(MirrorName), "获得了",
				ArenaName, "擂台的擂主之位【第", get_real_rank(MirrorRank), "名】!"
			]));
	false ->
		add_bonus(RoleID, FightBonus, "你在血战到底中挑战"++to_list(MirrorName)++"失败，获得")
	end,
	update_role_after_under_chlg(MirrorID, get_fight_bonus(MirrorLevel, MirrorRank, not IsRoleWin)),
	global:send(?MODULE, {after_fight, RoleID, RoleName, MirrorID, MirrorName, MirrorRank, IsRoleWin}).

update_role_after_under_chlg(RoleID, UnderChlgBonus) ->
	RoleInfo  =  dirty_read(?DB_CLGM_ROLE, RoleID),
	OldBonus  =  RoleInfo#r_clgm_role.bonus,
	db:dirty_write(?DB_CLGM_ROLE, RoleInfo#r_clgm_role{bonus = OldBonus+UnderChlgBonus}).

%%开始转盘
handle({Unique, ?CLGM, ?CLGM_ROTATE, _DataIn, RoleID, PID, Line}, _MapState) ->
	RoleInfo = dirty_read(?DB_CLGM_ROLE, RoleID),
	#p_clgm_role{rotated_count=RotatedCount} = p_clgm_role(RoleInfo),
	VipLevel=mod_vip:get_role_vip_level(RoleID),
	[CostTuple] = common_config_dyn:find(chlg_match, rotate_cost),
	CostIndex = erlang:min(tuple_size(CostTuple), RotatedCount+1),
	case element(CostIndex, CostTuple) of
	{s, Cost} ->
		PayType = silver_any,
		LogType = ?CONSUME_TYPE_SILVER_CLGM_CHLG;
	{g, Cost} ->
		PayType = gold_any,
		LogType = ?CONSUME_TYPE_GOLD_CLGM_CHLG
	end,
	Discount = case VipLevel of
			   0 -> 1;
			   _ -> element(VipLevel, hd(common_config_dyn:find(chlg_match, rotate_cost_discount)))
			   end,
	PayMoney = round(Cost*Discount),
	case common_transaction:t(
		   fun() ->
				   common_bag2:t_deduct_money(PayType, PayMoney, RoleID, LogType)
		   end) of
	{_,{ok,NewRoleAttr}}->
		ChangeList = [#p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value=NewRoleAttr#p_role_attr.gold},
					  #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.gold_bind},
					  #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value=NewRoleAttr#p_role_attr.silver},
					  #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.silver_bind}],
		common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
		NewRoleInfo=RoleInfo#r_clgm_role{rotated_count=RotatedCount+1, last_rotate_time=common_tool:now()},
		db:dirty_write(?DB_CLGM_ROLE, NewRoleInfo),
		case PayType of
		silver_any ->
			Msg = "你消耗了"++common_misc:format_silver(PayMoney)++"选擂",
			common_broadcast:bc_send_msg_role(RoleID, [?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_SYSTEM], Msg);
		gold_any ->
			Msg = "你消耗了"++to_list(PayMoney)++"元宝选擂",
			common_broadcast:bc_send_msg_role(RoleID, [?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_SYSTEM], Msg)
		end,
		global:send(?MODULE, {Unique, ?CLGM, ?CLGM_ROTATE, NewRoleAttr#p_role_attr.category, RoleID, PID, Line});
	{_,{error,gold_any}} ->
		common_misc:unicast2(PID, ?_clgm_error{mesg = <<"元宝不足">>});
	{_,{error,silver_any}} -> 
		common_misc:unicast2(PID, ?_clgm_error{mesg = <<"金钱不足">>});
	{_,{error, Reason}} ->
		common_misc:unicast2(PID, ?_clgm_error{mesg = Reason})
	end;

%%强攻
handle(Info = {_Unique, ?CLGM, ?CLGM_STORM, DataIn, RoleID, PID, _Line}, _MapState) ->
	#m_clgm_storm_tos{role_id=ChlgRoleID}=DataIn,
	TimeDiff=calendar:time_to_seconds(?GIVE_BONUS_TIME) - calendar:time_to_seconds(time()),
	if
	RoleID == ChlgRoleID ->
		common_misc:unicast2(PID, ?_clgm_error{mesg = <<"不能挑战自己">>});
	TimeDiff >= 0, TimeDiff =< 60 ->
		common_misc:unicast2(PID, ?_clgm_error{mesg = <<"发放奖励前1分钟，不能挑战">>});
	true ->
		VipLevel=mod_vip:get_role_vip_level(RoleID),
		[Cost] = common_config_dyn:find(chlg_match, storm_cost),
		Discount = case VipLevel of
				   0 -> 1;
				   _ -> element(VipLevel, hd(common_config_dyn:find(chlg_match, storm_cost_discount)))
				   end,
		PayMoney = round(Cost*Discount),
		case common_transaction:t(
			   fun() ->
					   common_bag2:t_deduct_money(gold_any, PayMoney, RoleID, ?CONSUME_TYPE_GOLD_CLGM_STORM)
			   end) of
		{_,{ok,NewRoleAttr}}->
			ChangeList = [#p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, 
											  new_value=NewRoleAttr#p_role_attr.gold},
						  #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, 
											  new_value=NewRoleAttr#p_role_attr.gold_bind}],
			common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
			Msg = "你消耗了"++to_list(PayMoney)++"元宝强攻",
			common_broadcast:bc_send_msg_role(RoleID, [?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_SYSTEM], Msg),
			global:send(?MODULE, Info);
		{_,{error,gold_any}} -> 
			common_misc:unicast2(PID, ?_clgm_error{mesg = <<"元宝不足">>});
		{_,{error,Reason}} ->
			common_misc:unicast2(PID, ?_clgm_error{mesg = Reason})
		end
	end;

%%领取奖励
handle({_Unique, ?CLGM, ?CLGM_GET_BONUS, _DataIn, RoleID, PID, _Line}, _MapState) ->
	RoleInfo = dirty_read(?DB_CLGM_ROLE, RoleID),
	#r_clgm_role{equip=Equip, bonus=Bonus} = RoleInfo,
	NewBonus=case add_bonus(RoleID, Bonus, "你领取了血战到底奖励") of
			 ok -> 0;
			 _  -> Bonus
			 end,
	NowTime=time(),
	TimeDiff=case ?GIVE_BONUS_TIME >= NowTime of
			 true ->
				 calendar:time_to_seconds(?GIVE_BONUS_TIME)-calendar:time_to_seconds(NowTime);
			 false ->
				 86400+calendar:time_to_seconds(?GIVE_BONUS_TIME)-calendar:time_to_seconds(NowTime)
			 end,
	NewEquip=case TimeDiff > 60 of
			 true ->
				 StartTime=common_tool:now(),
				 EndTime=StartTime+TimeDiff,
				 case add_equip(RoleID, Equip, StartTime, EndTime, "你领取了血战到底奖励") of
				 ok -> 0;
				 _  -> Equip
				 end;
			 false ->
				 common_misc:unicast2(PID, ?_clgm_error{mesg = <<"发放奖励前1分钟，不能领取装备">>}),
				 Equip
			 end,
	NewRoleInfo=RoleInfo#r_clgm_role{bonus=NewBonus,equip=NewEquip},
	db:dirty_write(?DB_CLGM_ROLE, NewRoleInfo),
	common_misc:unicast2(PID, ?_clgm_update_role{
		type = 2, 
		role = p_clgm_role(NewRoleInfo)
	});

%%查询镜像属性
handle({Unique, ?CLGM, ?CLGM_MIRROR_ATTR, DataIn, _RoleID, PID, _Line}, _MapState) ->
	#m_clgm_mirror_attr_tos{mirror_id = MirrorID} = DataIn,
	MirrorTab  = ets:lookup_element(t_clgm, MirrorID, 2),
	[RoleBase] = ets:lookup(MirrorTab, p_role_base),
	[RoleAttr] = ets:lookup(MirrorTab, p_role_attr),
	RoleInfo = mod_role2:p_other_role_info(RoleBase, RoleAttr),
	common_misc:unicast2(PID, ?_role2_getroleattr{role_info=RoleInfo}).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% --------------------------------------------------------------------
init([]) ->
	ets:new(t_clgm, [named_table]),
	erlang:send(self(), init),
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
		({Key, _}) ->
			erase(Key)
	end, get()),
	{reply, ok, State};

handle_call({set_status, Rank, Status}, _From, State) ->
	Mirror = get_mirror(Rank),
	catch put({mirror, Rank}, Mirror#p_clgm_mirror{status=Status}),
	{reply, ok, State}.

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
	countdown(give_bonus, ?GIVE_BONUS_TIME),
	lists:foreach(fun(#r_clgm_mirror{rank=Rank, detail=Detail}) ->
		MirrorTab = ets:new(t_mirror, []),
		ets:insert(MirrorTab, Detail),
		ets:insert(t_clgm, {Rank, MirrorTab}),
		RoleBase = lists:keyfind(p_role_base, 1, Detail),
		set_rank(RoleBase#p_role_base.role_id, Rank)
	 end, mt_mnesia:show_table(?DB_CLGM_MIRROR));

%%打开血战到底界面
do_handle_info({Unique, ?CLGM, ?CLGM_OPEN, _DataIn, RoleID, PID, _Line}) ->
	RoleInfo=p_clgm_role(dirty_read(?DB_CLGM_ROLE, RoleID)),
	ListenArena=if
		RoleInfo#p_clgm_role.chlg_arena /= undefined ->
			RoleInfo#p_clgm_role.chlg_arena;
		RoleInfo#p_clgm_role.rank /= undefined ->
			(RoleInfo#p_clgm_role.rank + 2) div ?RANK_PER_ARENA;
		true ->
			random:seed(now()),
			random:uniform(?MAX_ARENA_NUM)
	end,
	add_listener(ListenArena, RoleID),
	common_misc:unicast2(PID, ?_clgm_open{
		arena_id  = ListenArena, 
		role      = RoleInfo, 
		mirrors   = get_mirrors(ListenArena), 
		histories = get_histories()
	});

%%开始选择擂台
do_handle_info({Unique, ?CLGM, ?CLGM_ROTATE, Category, RoleID, PID, _Line}) ->
	[WeightLst]=case Category of
				1 ->
					common_config_dyn:find(chlg_match, rotate_weight_1);
				2 ->
					common_config_dyn:find(chlg_match, rotate_weight_2);
				3 ->
					common_config_dyn:find(chlg_match, rotate_weight_3);
				4 ->
					common_config_dyn:find(chlg_match, rotate_weight_4)
				end,
	ChlgArena=weight_random(WeightLst),
	set_chlg_arena(RoleID, ChlgArena),
	del_listener(all_arenas, RoleID),
	add_listener(ChlgArena, RoleID),
	common_misc:unicast2(PID, ?_clgm_rotate{
		arena_id = ChlgArena,
		mirrors  = get_mirrors(ChlgArena)
	});

%%关闭血战到底界面
do_handle_info({_Unique, ?CLGM, ?CLGM_CLOSE, _DataIn, RoleID, _PID, _Line}) ->
	del_listener(history, RoleID),
	del_listener(all_arenas, RoleID);

%%查看擂台信息
do_handle_info({Unique, ?CLGM, ?CLGM_LOOKUP_ARENA, DataIn, RoleID, PID, _Line}) ->
	#m_clgm_lookup_arena_tos{arena_id=ArenaID} = DataIn,
	del_listener(all_arenas, RoleID),
	add_listener(ArenaID, RoleID),
	common_misc:unicast2(PID, ?_clgm_lookup_arena{
		arena_id = ArenaID, 
		mirrors  = get_mirrors(ArenaID), 
		can_chlg = get_chlg_arena(RoleID) == ArenaID
	});

%%挑战镜像
do_handle_info({Unique, ?CLGM, ?CLGM_CHALLENGE, DataIn, RoleID, PID, Line}) ->
	#m_clgm_challenge_tos{rank=ChlgRank, role_id=ChlgRoleID}=DataIn,
	NowTime=common_tool:now(),
	ChlgMirror=get_mirror(ChlgRank),
	ChlgArena=get_chlg_arena(RoleID),
	TimeDiff=calendar:time_to_seconds(?GIVE_BONUS_TIME) - calendar:time_to_seconds(time()),
	IsMirrorFighting=is_fighting(ChlgMirror, NowTime),
	if
	RoleID == ChlgRoleID ->
		common_misc:unicast2(PID, ?_clgm_error{mesg = <<"不能挑战自己">>});
	ChlgArena == undefined ->
		common_misc:unicast2(PID, ?_clgm_error{mesg = <<"你没有这个擂台的挑战权">>});
	TimeDiff >= 0, TimeDiff =< 60 ->
		common_misc:unicast2(PID, ?_clgm_error{mesg = <<"发放奖励前1分钟，不能挑战">>});
	ChlgMirror == undefined ->
		del_chlg_arena(RoleID),
		del_mirror(get_rank(RoleID)),
		set_rank(RoleID, ChlgRank),
		MirrorTab = ets:new(t_mirror, [public]),		
		Mirror = [
			{modified, true},
			{fight_time, 0},
			{status, ?MIRROR_IDLE}
			|mod_mirror:copy(RoleID)
		],
		ets:insert(MirrorTab, Mirror),
		ets:insert(t_clgm, {ChlgRank, MirrorTab}),
		db:dirty_write(?DB_RNKM_MIRROR, #r_clgm_mirror{rank=ChlgRank, detail=Mirror}),
		common_misc:unicast2(PID, ?_clgm_update_role{
			role = p_clgm_role(RoleID)
		}),
		Pmirror = get_mirror(ChlgRank, MirrorTab),
		lists:foreach(fun(ListenerID) ->
			common_misc:unicast({role, ListenerID}, ?_clgm_update_mirror{
				mirror = Pmirror
			})
		end, get_listeners({rank, ChlgRank}));
	ChlgMirror#p_clgm_mirror.status == ?MIRROR_INIT ->
		common_misc:unicast2(PID, ?_clgm_error{mesg = <<"正在生成玩家镜像，请稍等">>});
	IsMirrorFighting ->
		common_misc:unicast2(PID, ?_clgm_error{mesg = <<"这个擂台正在发生另外一场战斗，请稍等一会，再次攻擂">>});
	RoleID == ChlgMirror#p_clgm_mirror.role_id ->
		common_misc:unicast2(PID, ?_clgm_error{mesg = <<"不能挑战自己">>});
	ChlgRoleID /=0, ChlgRoleID /= ChlgMirror#p_clgm_mirror.role_id ->
		do_handle_info({Unique, ?CLGM, ?CLGM_OPEN, #m_clgm_open_tos{}, RoleID, PID, Line});
	true ->
		put({fight_rank, RoleID}, ChlgRank),
		del_chlg_arena(RoleID),
		del_mirror(get_rank(RoleID)),
		MirrorTab = ets:lookup_element(t_clgm, ChlgRank, 2),
		ets:insert(MirrorTab, [{status, ?MIRROR_BUSY}, {fight_time, NowTime}]),
		RoleProcName = mgeer_role:proc_name(RoleID),
		RolePID = global:whereis_name(RoleProcName),
		common_misc:send_to_rolemap(RoleID, {mod, mod_mirror_fb, 
			{change_map, RoleID, 10324, RolePID, RoleProcName, MirrorTab, []}
		})
	end;

%%挑战镜像
do_handle_info({Unique, ?CLGM, ?CLGM_STORM, DataIn, RoleID, PID, Line}) ->
	#m_clgm_storm_tos{rank=ChlgRank, role_id=ChlgRoleID}=DataIn,
	set_chlg_arena(RoleID, ChlgRank div ?RANK_PER_ARENA),
	common_misc:unicast2(PID, ?_clgm_update_role{role=p_clgm_role(RoleID)}),
	DataIn2=#m_clgm_challenge_tos{rank=ChlgRank, role_id=ChlgRoleID},
	do_handle_info({Unique, ?CLGM, ?CLGM_CHALLENGE, DataIn2, RoleID, PID, Line});

%%玩家挑战镜像战斗结束
do_handle_info({after_fight, AttackerID, AttackerName, 
				DefencerID, DefencerName, DefencerRank, IsAttackerWin}) ->
	AttackerRank = get_rank(AttackerID),
	NewAttackerRank = case IsAttackerWin of
		true ->
			DefencerRank;
		false ->
			undefined
	end,
	NewDefencerRank = case IsAttackerWin of
		true ->
			undefined;
		false ->
			DefencerRank
	end,
	AttackerMirror = case get_mirror(AttackerRank) of
		undefined ->
		   {ok, RoleBase} = mod_map_role:get_role_base(AttackerID),
		   {ok, RoleAttr} = mod_map_role:get_role_attr(AttackerID),
		   #p_clgm_mirror{
				role_id   = AttackerID, 
				role_name = RoleBase#p_role_base.role_name, 
				sex       = RoleBase#p_role_base.sex, 
				level     = RoleAttr#p_role_attr.level, 
				category  = RoleAttr#p_role_attr.category
			};
		AttackerMirror0 ->
		   AttackerMirror0
	end,
	DefencerMirror = get_mirror(DefencerRank),
	MirrorTab = ets:lookup_element(t_clgm, DefencerRank, 2),
	case NewAttackerRank =< ?MAX_ARENA_NUM * ?RANK_PER_ARENA of
		true ->
			set_rank(AttackerID, NewAttackerRank),
			ets:insert(MirrorTab, [
				{modified, true},
				{fight_time, 0},
				{status, ?MIRROR_IDLE}
				|mod_mirror:copy(AttackerID)
			]),
			NewAttackerMirror = AttackerMirror#p_clgm_mirror{
				rank   = NewAttackerRank, 
				status = ?MIRROR_IDLE
			},
			lists:foreach(fun(ListenerID) ->
				common_misc:unicast({role, ListenerID}, ?_clgm_update_mirror{
					mirror = NewAttackerMirror
				})
			end, get_listeners({rank, NewAttackerRank}));
		false ->
			del_rank(AttackerID)
	end,
	case NewDefencerRank =< ?MAX_ARENA_NUM * ?RANK_PER_ARENA of
		true ->
			set_rank(DefencerID, NewDefencerRank),
			NewDefencerMirror=DefencerMirror#p_clgm_mirror{
				rank   = NewDefencerRank, 
				status = ?MIRROR_IDLE
			},
			ets:insert(MirrorTab, [
				{modified, true},
				{fight_time, 0},
				{status, ?MIRROR_IDLE}
				|mod_mirror:copy(DefencerID)
			]),
			lists:foreach(fun(ListenerID) ->
				common_misc:unicast({role, ListenerID}, ?_clgm_update_mirror{
					mirror = NewDefencerMirror
				})
			end, get_listeners({rank, NewDefencerRank})); 
		false ->
			del_rank(DefencerID)
	end,
	#p_clgm_mirror{role_name=DefencerName, rank=ChlgRank} = DefencerMirror,
	common_misc:unicast({role, AttackerID}, 
		?_clgm_update_role{role=p_clgm_role(AttackerID)}),
	common_misc:unicast({role, DefencerID}, 
		?_clgm_update_role{role=p_clgm_role(DefencerID)}),
	case IsAttackerWin of
	true ->
		History = #p_clgm_history{
			att_id   = AttackerID,
			att_name = AttackerName,
			def_id   = DefencerID,
			def_name = DefencerName,
			rank     = ChlgRank,
			result   = ?FIGHT_RESULT(IsAttackerWin),
			time     = common_tool:now()
		},
		add_history(History),
		lists:foreach(fun(ListenerID) ->
			common_misc:unicast({role, ListenerID}, ?_clgm_update_history{
				history = History
			})
		end, get_listeners(history));
	false ->
		ignore
	end;

do_handle_info(give_bonus) ->
	countdown(give_bonus, ?GIVE_BONUS_TIME),
	lists:foreach(fun(#r_clgm_given_equip{role_id=RoleID, equip_id=EquipID}) ->
		RoleInfo = dirty_read(?DB_CLGM_ROLE, RoleID),
		db:dirty_write(?DB_CLGM_ROLE, RoleInfo#r_clgm_role{equip=0}),
		mod_equip_retrieve:start(RoleID, EquipID, 
			<<"血战到底装备回收,请重新挑战获取">>, ?LOG_ITEM_TYPE_RETRIEVE_CLGM_EQUIP)
	end, db:dirty_match_object(?DB_CLGM_GIVEN_EQUIP, #r_clgm_given_equip{_='_'})),
	db:clear_table(?DB_CLGM_GIVEN_EQUIP),
	lists:foreach(fun({MirrorRank, MirrorTab}) ->
		case ets:info(MirrorTab) of
			undefined ->
				[RoleAttr] = ets:lookup(MirrorTab, p_role_attr),
				#p_role_attr{role_id = RoleID, level = Level} = RoleAttr,
				del_rank(RoleID),
			 	del_mirror(MirrorRank),
			 	EquipID = get_rank_equip(Level, MirrorRank),
			 	RoleInfo = #r_clgm_role{
			 		bonus = OldBonus
			 	} = dirty_read(?DB_CLGM_ROLE, RoleID),
			 	NewRoleInfo = RoleInfo#r_clgm_role{
					equip = EquipID, 
					bonus = OldBonus
			 	},
			 	db:dirty_write(?DB_CLGM_ROLE, NewRoleInfo),
			 	db:dirty_write(?DB_CLGM_GIVEN_EQUIP, 
			 		#r_clgm_given_equip{
						rank     = MirrorRank, 
						role_id  = RoleID, 
						equip_id = EquipID
			 	}),
			 	common_misc:unicast({role, RoleID}, ?_clgm_update_role{
					type = 2, 
					role = p_clgm_role(NewRoleInfo)
			 	}),
				common_letter:sys2p(RoleID, 
					"恭喜您获得了擂台装备及金钱奖励，请您记得点击领取奖励，期待您的再次挑战并祝您游戏愉快!", 
					"血战到底通知");
			_ ->
				ignore
		end
	end, ets:tab2list(t_clgm));

do_handle_info(persist_mirrors) ->
	countdown(persist_mirrors, ?PERSIST_MIRRORS_INTERVAL),
	lists:foreach(fun({MirrorRank, MirrorTab})->
		case ets:info(MirrorTab) of
			undefined ->
				db:dirty_delete(?DB_CLGM_MIRROR, MirrorRank);
			_ ->
				case ets:lookup(MirrorTab, modified) of
					[{_, true}] ->
						db:dirty_write(?DB_CLGM_MIRROR, #r_clgm_mirror{
							rank   = MirrorRank,
							detail = ets:tab2list(MirrorTab)
						});
					_ ->
						ignore
				end
		end
	end, 
	ets:tab2list(t_clgm));

do_handle_info({mirror_fb_stop, RoleID}) ->
	case erase({fight_rank, RoleID}) of
	undefined ->
		ignore;
	Rank ->
		case ets:lookup(t_clgm, Rank) of
		[{_, MirrorTab}] ->
			ets:update_element(MirrorTab, status, {2, ?MIRROR_IDLE});
		_ ->
			ignore
		end
	end;

do_handle_info(_Info) ->
	ignore.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
	ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
get_rank(RoleID) ->
	get({rank, RoleID}).

set_rank(RoleID, Rank) ->
	put({rank, RoleID}, Rank).

del_rank(RoleID) ->
	erase({rank, RoleID}).

get_chlg_arena(RoleID) ->
	get({chlg_arena, RoleID}).

set_chlg_arena(RoleID, Arena) ->
	put({chlg_arena, RoleID}, Arena).

del_chlg_arena(RoleID) ->
	erase({chlg_arena, RoleID}).

get_mirror(Rank) ->
	MirrorTab = ets:lookup_element(t_clgm, Rank, 2),
	get_mirror(Rank, MirrorTab).

get_mirror(Rank, MirrorTab) ->
	[RoleAttr] = ets:lookup(MirrorTab, p_role_attr),
	[RoleBase] = ets:lookup(MirrorTab, p_role_base),
	#p_clgm_mirror{
		rank       = Rank,
		role_id    = RoleBase#p_role_base.role_id,
		role_name  = RoleBase#p_role_base.role_name,
		sex        = RoleBase#p_role_base.sex,
		level      = RoleAttr#p_role_attr.level,
		jingjie    = RoleAttr#p_role_attr.jingjie,
		category   = RoleAttr#p_role_attr.category,
		status     = ets:lookup_element(MirrorTab, status, 2),
		fight_time = ets:lookup_element(MirrorTab, fight_time, 2)
	}.

del_mirror(undefined) ->
	ignore;
del_mirror(Rank) ->
	case ets:lookup(t_clgm, Rank) of
		[{_, MirrorTab}] ->
			ets:delete(MirrorTab),
			lists:foreach(fun(RoleID) ->
				common_misc:unicast({role, RoleID}, 
					?_clgm_update_mirror{mirror=#p_clgm_mirror{rank=Rank}})
			end, get_listeners({rank, Rank}));
		_ ->
			ignore
	end.

get_mirrors(Arena) ->
	[Mirror||Mirror<-[get_mirror((Arena-1)*?RANK_PER_ARENA+R)
						||R<-lists:seq(1, ?RANK_PER_ARENA)],
			 Mirror/=undefined].

get_listeners({rank, Rank}) ->
	get_listeners((Rank+2) div ?RANK_PER_ARENA);

get_listeners(Arena) ->
	case get({listeners, Arena}) of
	undefined ->
		[];
	List ->
		List
	end.

add_listener(Arena, RoleID) when Arena >= 1 andalso Arena =< ?MAX_ARENA_NUM ->
	put({listeners, history}, [RoleID|lists:delete(RoleID, get_listeners(history))]),
	put({listeners, Arena}, [RoleID|lists:delete(RoleID, get_listeners(Arena))]);

add_listener(_Arena, _RoleID) ->
	ignore.

del_listener(all_arenas, RoleID) ->
	lists:foreach(fun(N) -> 
		del_listener(N, RoleID) 
	end, lists:seq(1, ?MAX_ARENA_NUM));

del_listener({rank, Rank}, RoleID) ->
	del_listener((Rank+2) div ?RANK_PER_ARENA, RoleID);

del_listener(Arena, RoleID) when Arena == history 
	orelse (Arena >= 1 andalso Arena =< ?MAX_ARENA_NUM) ->
	put({listeners, Arena}, lists:delete(RoleID, get_listeners(Arena)));

del_listener(_Arena, _RoleID) ->
	ignore.

add_history(History) ->
	put(histories, [History|lists:sublist(get_histories(), ?MAX_HISTORY_COUNT-1)]).

get_histories() ->
	case get(histories) of
	undefined ->
		[];
	Histories ->
		Histories
	end.

is_fighting(#p_clgm_mirror{
		status     = ?MIRROR_BUSY, 
		fight_time = FightTime
	}, Time) when Time < FightTime + ?MAX_FIGHT_TIME ->
	true;
is_fighting(_Mirror, _Time) ->
	false.

dirty_read(?DB_CLGM_ROLE, RoleID) ->
	case db:dirty_read(?DB_CLGM_ROLE, RoleID) of
		[] ->
			#r_clgm_role{role_id=RoleID};
		[Rec] ->
			Rec
	end.

p_clgm_role(#r_clgm_role{
		role_id          = RoleID,
		bonus            = Bonus,
		equip            = Equip,
		rotated_count    = RotatedCount,
		last_rotate_time = LastRotateTiime
	}) ->
	Date = date(),
	RotatedCount2 = case common_tool:seconds_to_datetime(LastRotateTiime) of
		{Date, _} ->
			RotatedCount;
		_ ->
			0
	end,
	#p_clgm_role{
		role_id       = RoleID,
		rank          = get_rank(RoleID),
		bonus         = Bonus,
		equip         = Equip,
		chlg_arena    = get_chlg_arena(RoleID),
		rotated_count = RotatedCount2
	};

p_clgm_role(RoleID) ->
	#p_clgm_role{role_id=RoleID,rank=get_rank(RoleID),chlg_arena=get_chlg_arena(RoleID)}.

add_bonus(RoleID, Bonus, Msg) when Bonus > 0 ->
	case common_transaction:t(
		   fun() ->
				   common_bag2:t_gain_money(silver_bind, Bonus, RoleID, ?GAIN_TYPE_SILVER_FROM_CLGM)
		   end) of
	{atomic,{ok, RoleAttr}} ->
		ChangeList = [#p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value=RoleAttr#p_role_attr.silver_bind}],
		common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
		common_broadcast:bc_send_msg_role(RoleID, [?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_SYSTEM], Msg++common_misc:format_silver(Bonus)),
		ok;
	Error ->
		?ERROR_LOG("add bonus error, ~p", [Error]),
		error
	end;

add_bonus(_RoleID, _Bonus, _Msg) ->
	ignore.

add_equip(RoleID, EquipType, StartTime, EndTime, Msg) when EquipType > 0 ->
	Goods = #r_goods_create_info{
		bind           = true, 
		type           = ?TYPE_EQUIP, 
		type_id        = EquipType, 
		num            = 1, 
		start_time     = StartTime, 
		end_time       = EndTime, 
		interface_type = monster_flop
	},
	case common_transaction:t(fun() ->
			mod_bag:create_goods(RoleID, Goods)
		 end) of
		{atomic,{ok, EquipList}} ->
			common_item_logger:log(RoleID, Goods, ?LOG_ITEM_TYPE_CLGM_REWARD),
			common_misc:update_goods_notify({role, RoleID}, EquipList),
			[#p_equip_base_info{equipname=EquipName}]=common_config_dyn:find(equip, EquipType),
			common_broadcast:bc_send_msg_role(RoleID, 
				[?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_SYSTEM], Msg++to_list(EquipName)),
			ok;
		{aborted, {bag_error, {not_enough_pos, _}}} ->
			common_misc:unicast({role, RoleID}, ?_clgm_error{mesg = <<"背包空间已满，请整理背包！">>});
		Error ->
			?ERROR_LOG("add equip error, ~p", [Error]),
			error
	end;

add_equip(_RoleID, _Equip, _StartTime, _EndTime, _Msg) ->
	ignore.

get_fight_bonus(Level, Rank, IsWin) ->
	BonusKey = if
				   Level >= 90 -> fight_bonus_90;
				   Level >= 80 -> fight_bonus_80;
				   Level >= 70 -> fight_bonus_70;
				   Level >= 60 -> fight_bonus_60;
				   Level >= 50 -> fight_bonus_50;
				   Level >= 40 -> fight_bonus_40;
				   Level >= 30 -> fight_bonus_30;
				   Level >= 20 -> fight_bonus_20
			   end,
	[BonusTuple1] = common_config_dyn:find(chlg_match, BonusKey),
	BonusTuple2 = element(?FIGHT_RESULT(IsWin), BonusTuple1),
	element(get_real_rank(Rank), BonusTuple2).

get_rank_equip(Level, Rank) ->
	EquipKey = if
				   Level >= 90 -> equip_90;
				   Level >= 80 -> equip_80;
				   Level >= 70 -> equip_70;
				   Level >= 60 -> equip_60;
				   Level >= 50 -> equip_50;
				   Level >= 40 -> equip_40;
				   Level >= 30 -> equip_30;
				   Level >= 20 -> equip_20
			   end,
	[EquipTuple] = common_config_dyn:find(chlg_match, EquipKey),
	element(Rank, EquipTuple).

weight_random(WeightList) ->
	random:seed(now()),
	weight_random(0, random:uniform(lists:sum(WeightList)), 0, WeightList).

weight_random(Index, Random, Weight, WeightList) ->
	if
		Random =< Weight ->
			Index;
		WeightList == [] ->
			Index;
		true ->
			[H|T] = WeightList,
			weight_random(Index+1, Random, Weight+H, T)
	end.

countdown(Type, Time) ->
	case get({timer, Type}) of
		Timer when is_reference(Timer) ->
			erlang:cancel_timer(Timer);
		_ ->
			ignore
	end,
	Secs = calendar:time_to_seconds(Time) - calendar:time_to_seconds(time()),
	Secs2 = if Secs =< 0 -> 86400 + Secs; true -> Secs end, 
	put({timer, Type}, erlang:send_after(Secs2*1000, self(), Type)).

get_arena_name(Rank) ->
	[Tuple] = common_config_dyn:find(chlg_match, arena_name),
	element((Rank+2) div 3, Tuple).

get_real_rank(Rank) ->
	case Rank rem ?RANK_PER_ARENA of
		0 -> 3;
		R -> R
	end.