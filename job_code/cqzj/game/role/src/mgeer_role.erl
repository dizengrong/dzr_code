%%% -------------------------------------------------------------------
%%% Author  : xierongfeng
%%% Description : 玩家进程
%%%
%%% Created : 2012-11-2
%%% -------------------------------------------------------------------
-module(mgeer_role).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeer.hrl").

-record(state, {}).

%% 调用handle/2 的缩写
-define(MODULE_HANDLE_TWO(Module,HandleModule),
    do_handle_info({Unique, Module, Method, DataIn, RoleID, PID, Line}, _State) ->
    HandleModule:handle({Unique, Module, Method, DataIn, RoleID, PID, Line}, mgeem_map:get_state())).
%% 调用handle/1 的缩写
-define(MODULE_HANDLE_ONE(Module,HandleModule),
    do_handle_info({Unique, Module, Method, DataIn, RoleID, PID, Line}, _State) ->
    HandleModule:handle({Unique, Module, Method, DataIn, RoleID, PID, Line})).
%% 调用handle/1 同时带上State参数的缩写
-define(MODULE_HANDLE_ONE_STATE(Module,HandleModule),
		do_handle_info({Unique, Module, Method, DataIn, RoleID, PID, Line}, _State) ->
		HandleModule:handle({Unique, Module, Method, DataIn, RoleID, PID, Line, mgeem_map:get_state()})).

-define(ROLE_BASE_ATTR_PERSISTENT_INTERVAL, 1800).
-define(ROLE_IS_LOGIN_STATUS_INTERVAL, 3600*1000).
%% --------------------------------------------------------------------
%% External exports
-export([
	start/5, 
	start_link/5, 
	absend/2, 
	send/2, 
	run/2, 
	proc_name/1, 
	call/2, 
	call/4, 
	send_reload_base/3, 
	send_reload_base/5, 
	reload_role_base/3, 
	reload_role_base/5
]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% External functions
%% ====================================================================
start(RoleID, AccountFullInfo, PID, Line, ClientIP) ->
	ProcName = proc_name(RoleID),
	case global:whereis_name(ProcName) of
		undefined ->
			supervisor:start_child(mgeer_sup, [ProcName, AccountFullInfo, PID, Line, ClientIP]);
		Pid ->
			{ok, Pid}
	end.

start_link(ProcName, AccountFullInfo, PID, Line, ClientIP) ->
	gen_server:start_link(?MODULE, [ProcName, AccountFullInfo, PID, Line, ClientIP], []).

absend(RoleID, Msg) when RoleID < 0 ->
	self() ! Msg;
absend(RoleID, Msg) ->
	case global:whereis_name(proc_name(RoleID)) of
		undefined ->
			?ERROR_MSG("Process:mgeer_role_~p is down",[RoleID]);
		Pid ->
			Pid ! Msg
	end.

send(RoleID, Msg) when RoleID < 0 ->
	self() ! Msg;
send(RoleID, Msg) ->
	Pid = global:whereis_name(proc_name(RoleID)),
	case Pid == self() of
		true ->
			handle_info(Msg, undefined);
		false ->
			Pid ! Msg
	end.

run(RoleID, Fun) ->
	Pid = global:whereis_name(proc_name(RoleID)),
	case Pid == self() of
		true ->
			Fun();
		false ->
			Pid ! {apply, Fun}
	end.

%% for debug
call(RoleID, Fun) ->
	Pid = global:whereis_name(proc_name(RoleID)),
	case Pid == self() of
		true ->
			Fun();
		false ->
			gen_server:call(Pid, {apply, Fun})
	end.

call(RoleID, M, F, A) ->
	Pid = global:whereis_name(proc_name(RoleID)),
	case Pid == self() of
		true ->
			apply(M, F, A);
		false ->
			gen_server:call(Pid, {apply, M, F, A})
	end.

proc_name(RoleID) ->
	common_tool:int_to_atom(RoleID).

send_reload_base(RoleID, Calc1, Attrs1) ->
	mgeer_role:send(
		RoleID, 
		{apply, ?MODULE, reload_role_base, [RoleID, Calc1, Attrs1]}
	).
send_reload_base(RoleID, Calc1, Attrs1, Calc2, Attrs2) ->
	mgeer_role:send(
		RoleID, 
		{apply, ?MODULE, reload_role_base, [RoleID, Calc1, Attrs1, Calc2, Attrs2]}
	).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% --------------------------------------------------------------------
init([ProcName, AccountFullInfo, PID, Line, ClientIP]) ->
	group_leader(self(), self()),
	erlang:monitor(process, PID),
	random:seed(now()),	
	global:register_name(ProcName, self()),

	#r_account_full_info{
		role_id			  = RoleID,
		role_detail       = #p_role{
			base  = RoleBase,
			attr  = RoleAttr,
			pos   = RolePos,
			fight = RoleFight,
			ext   = RoleExt
		},
		accumulate_info   = AccumulateInfo,
		goal_info         = RoleGoalInfo, 
		hero_fb_info      = HeroFBInfo, 
		role_monster_drop = DropInfo,
		refining_box_info = RefiningBoxInfo, 
		achievement_info  = AchievementInfo,
		team_info         = TeamInfo,
		map_ext_info      = MapExtInfo,
		skill_list        = SkillList,
		jingjie_info      = JingjieInfo, 
		role_misc         = RoleMisc
	} = AccountFullInfo,
	
	NewMapExtInfo = MapExtInfo#r_role_map_ext{
		horse_racing=#r_horse_racing_ext{}
	},
    RoleDetail = #r_role_map_detail{
		base              = RoleBase,
		attr              = RoleAttr,
		accumulate_info   = AccumulateInfo,
		hero_fb_info      = HeroFBInfo,
		role_monster_drop = DropInfo,
		refining_box_info = RefiningBoxInfo, 
		goal_info         = RoleGoalInfo, 
		achievement_info  = AchievementInfo,
		team_info         = TeamInfo,
		map_ext_info      = NewMapExtInfo,
		skill_list        = SkillList,
		pos               = RolePos,
		role_fight        = RoleFight,
		jingjie_info      = JingjieInfo
    },
	MapID = RolePos#p_role_pos.map_id,
	RolePos2 = case ?IS_SOLO_FB(MapID) of
		true ->
			SoloFb = lists:keyfind(r_solo_fb, 1, RoleMisc#r_role_misc.tuples),
			mod_solo_fb:init(MapID, ProcName, SoloFb),
			RolePos#p_role_pos{map_process_name=ProcName};
		_ ->
			RolePos
	end,
	mod_role_tab:init(RoleID),
	mod_role_tab:put({role_ext, RoleID}, RoleExt),
	mod_map_role:set_role_detail(RoleID, RoleDetail#r_role_map_detail{pos=RolePos2}),
	handle_info({init, AccountFullInfo, PID, Line, ClientIP}, #state{}),
    {ok, #state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% --------------------------------------------------------------------
handle_call(get, _From, State) ->
	{reply, get(), State};
handle_call({get, Key}, _From, State) ->
	Reply = case is_list(Key) of
		true ->
			[get(K)||K<-Key];
		false ->
			get(Key)
	end,
	{reply, Reply, State};
handle_call({login_again, RoleID, PID, Line, ClientIP}, _From, State) ->
	erlang:monitor(process, PID),
	put('PID', PID),
	put(online, true),
	case get(is_map_process) of
		true ->
			put({role_msg_queue, PID}, []),
			put({roleid_to_pid, RoleID}, PID);
		_ ->
			put({roleid_to_pid, RoleID}, {PID, in_role_process})
	end,
	{ok, RoleState} = mod_map_role:get_role_state(RoleID),
	mod_map_role:set_role_state(RoleID, RoleState#r_role_state2{
		pid       = PID, 
		line      = Line,
		client_ip = ClientIP
    }),
	{ok, RoleBase}  = mod_map_role:get_role_base(RoleID),
	{ok, RoleAttr}  = mod_map_role:get_role_attr(RoleID),
	RoleAttr2  = case common_config:get_agent_name() of
		Agent when Agent == "pengyou";
				   Agent == "qq" ->
			case cfg_cheat:is_cheater(RoleBase#p_role_base.account_name) of
                true ->
                    RoleAttr;
                false ->
			         RoleAttr#p_role_attr{gold = mod_qq_api:get_balance(RoleID)}
            end;
		_ ->
			RoleAttr
	end,
	mod_role_tab:put({?role_attr, RoleID}, RoleAttr2),
	{ok, RolePos}   = mod_map_role:get_role_pos_detail(RoleID),
	{ok, RoleFight} = mod_map_role:get_role_fight(RoleID),
	RoleDetail = #p_role{
		base  = RoleBase,
		attr  = RoleAttr2,
		pos   = RolePos,
		fight = RoleFight,
		ext   = mod_role_tab:get({role_ext, RoleID})
	},
	{reply, {mod_bag:get_role_bag_dicts(RoleID), RoleDetail}, State};
handle_call({apply, Fun}, _From, State) ->
    {reply, catch Fun(), State};
handle_call({apply, M, F, A}, _From, State) ->
	{reply, catch apply(M, F, A), State};
handle_call(Req, _From, State) ->
	?ERROR_MSG("unexpected request: ~p", [Req]),
	{reply, unexpected, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% --------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% --------------------------------------------------------------------
handle_info({init, AccountFullInfo, PID, Line, ClientIP}, State) ->
	#r_account_full_info{
		role_id			 = RoleID,
		role_detail      = #p_role{base = RoleBase},
		pet_process_info = PetProcessInfo,
		bag              = RoleBagInfoList, 
		mission_data     = MissionData,
		shortcut_bar     = Shortcut,
		role_misc        = RoleMisc,
		family_info 	 = FamilyInfo
	} = AccountFullInfo,
	
    RoleState = #r_role_state2{
		role_id        = RoleID, 
		role_name      = RoleBase#p_role_base.role_name, 
		gray_name_time = RoleBase#p_role_base.last_gray_name, 
		auto_ybc       = false, 
		pid            = PID, 
		client_ip      = ClientIP, 
		line           = Line
    },
	
	put('PID', PID),
	put(online, true),
	put(role_id, RoleID),
	put(in_map_role,[RoleID]),
	put(now, common_tool:now()),
	put({roleid_to_pid, RoleID}, {PID, in_role_process}),
	
	mod_map_role:set_role_state(RoleID, RoleState),
	mod_bag:init_role_bag_info(RoleBagInfoList),
	mod_mission_data:init_role_data(RoleID, MissionData),

	mod_letter:set_send_count_data(RoleID, undefined),
	mod_flowers:init_role_data(RoleID), 
	
	mod_map_pet:set_pet_process_info(RoleID, PetProcessInfo),
	mod_shortcut:set_role_shortcut_bar(RoleID, Shortcut),
	mod_role_misc:init(RoleMisc),
	mod_map_actor:init_in_map_role(),
	hook_role:init(),

	Self = self(),
	erlang:send_after(3000, Self, {mod_offline_event, {dispatch_offline_event, RoleID}}),
	case is_record(FamilyInfo, p_family_info) of
		true ->
			erlang:send_after(3000, Self, {mod_achievement2, {check_family_achievement, RoleID, FamilyInfo}});
		false -> ignore
	end,
	erlang:send_after(?ROLE_BASE_ATTR_PERSISTENT_INTERVAL*1000, Self, role_base_attr_persistent),
	erlang:send_after(common_time:diff_next_daytime(0, 0)*1000, Self, do_at_oclock),
	erlang:send_after(?ROLE_IS_LOGIN_STATUS_INTERVAL, self(), is_login),

	{noreply, State};

handle_info({'DOWN', _, _, _PID, _}, State) ->
	put(online, false) =/= false andalso
	case common_global:get(mgeeg_stop, false) of
		true ->
			handle_info(offline, State);
		_ ->
			erlang:send_after(10*1000, self(), offline),
			{noreply, State}
	end;

handle_info(offline, State) ->
	case get(online) of
		true ->
			{noreply, State};
		_ ->
			RoleID = get(role_id),
			case mgeem_map:get_state() of
				MapState = #map_state{mapid = MapID} when ?IS_SOLO_FB(MapID) ->
					catch mod_map_role:handle({role_exit, RoleID}, MapState);
				#map_state{} ->
					catch mgeem_map:call({mod_map_role, {role_exit, RoleID}});
				_ ->
					ignore
			end,
			hook_role:offline(RoleID),
			{stop, normal, State}
	end;

handle_info({'EXIT', _, _Reason}, State) ->
    {stop, normal, State};

handle_info(Info, State) ->
	try  
		do_handle_info(Info, mgeem_map:get_state())
	catch
		T:R ->
			?ERROR_MSG("Info:~w, type:~w, reason:~w, stactraceo:~w", [Info, T, R, erlang:get_stacktrace()])
	end,
	{noreply, State}.

?MODULE_HANDLE_ONE(?GOAL2,				mod_goal2);
?MODULE_HANDLE_ONE(?SCORE,				mod_score);
?MODULE_HANDLE_ONE(?GOODS, 				mod_goods);
?MODULE_HANDLE_ONE(?SKILL, 				mod_role_skill);
?MODULE_HANDLE_ONE(?MISSION, 			mod_mission_handler);
?MODULE_HANDLE_ONE(?RANDOM_MISSION, 	mod_random_mission);
?MODULE_HANDLE_ONE(?JINGJIE, 			mod_role_jingjie);
?MODULE_HANDLE_ONE(?JUEWEI, 			mod_role_juewei);
?MODULE_HANDLE_ONE(?WORSHIP, 			mod_role_worship);
?MODULE_HANDLE_ONE(?FASHION, 			mod_role_fashion);
?MODULE_HANDLE_ONE(?SHORTCUT, 			mod_shortcut);
?MODULE_HANDLE_ONE(?TREASBOX, 			mod_treasbox);
?MODULE_HANDLE_ONE(?TITLE, 				mod_title);
?MODULE_HANDLE_ONE(?SYSTEM, 			mod_system);
?MODULE_HANDLE_ONE(?CAISHEN,			mod_caishen);
?MODULE_HANDLE_ONE(?LIANQI,				mod_lianqi);
?MODULE_HANDLE_ONE(?HORSE_RACING,		mod_horse_racing);
?MODULE_HANDLE_ONE(?ACCUMULATE_EXP,		mod_accumulate_exp);
?MODULE_HANDLE_TWO(?FAMILY,				mod_map_family);
?MODULE_HANDLE_ONE(?FAMILY_IDOL,		mod_map_fml_idol);
?MODULE_HANDLE_ONE(?FMLSHOP,			mod_map_fmlshop);
?MODULE_HANDLE_ONE(?FMLDEPOT,			mod_map_fmldepot);
?MODULE_HANDLE_ONE(?SIGNIN,				mod_role_signin);
?MODULE_HANDLE_ONE(?GEMS,				mod_equip_gems);
?MODULE_HANDLE_ONE(?GIFT,				mod_gift);
?MODULE_HANDLE_ONE(?NEWCOMER,			mod_newcomer);
?MODULE_HANDLE_ONE(?PRESENT,			mod_present);
?MODULE_HANDLE_ONE(?ACCESS_GUIDE,		mod_access_guide);
?MODULE_HANDLE_ONE(?STALL,				mod_stall);
?MODULE_HANDLE_ONE(?ACTIVITY,			mod_activity);
?MODULE_HANDLE_ONE(?TRADING,			mod_trading);
?MODULE_HANDLE_ONE(?GUARD_FB,			mod_guard_fb);
?MODULE_HANDLE_ONE(?EXCHANGE,			mod_exchange);
?MODULE_HANDLE_ONE(?ACHIEVEMENT,		mod_achievement2);
?MODULE_HANDLE_ONE(?QRHL,               mod_qrhl);
?MODULE_HANDLE_ONE(?PVE_FB,				mod_pve_fb);
?MODULE_HANDLE_ONE(?MISSION_FB,			mod_mission_fb);
?MODULE_HANDLE_ONE(?SWL_MISSION, 		mod_swl_mission);
?MODULE_HANDLE_ONE(?QQ, 				mod_qq);
?MODULE_HANDLE_ONE(?DAILY_COUNTER, 		mod_daily_counter);
?MODULE_HANDLE_ONE(?FRIEND, 			mod_friend);
?MODULE_HANDLE_ONE(?BOMB_FB, 			mod_bomb_fb);
?MODULE_HANDLE_ONE(?OPEN_ACTIVITY, 		mod_open_activity);
?MODULE_HANDLE_ONE(?NATIONBATTLE,		mod_nationbattle_fb);
?MODULE_HANDLE_ONE(?MOUNT, 				mod_role_mount);
?MODULE_HANDLE_ONE(?BIGPVE,             mod_bigpve_fb);
?MODULE_HANDLE_ONE(?TOWER_FB,           mod_tower_fb);
?MODULE_HANDLE_ONE(?CONSUME_TASK,       mod_consume_task);
?MODULE_HANDLE_ONE(?HUOLING,       		mod_nuqi_huoling);
?MODULE_HANDLE_ONE(?RUNE_ALTAR, 		mod_rune_altar);
?MODULE_HANDLE_ONE(?RAGE_PRACTICE, 		mod_rage_practice);
?MODULE_HANDLE_ONE(?CD, 				mod_role_cd);

?MODULE_HANDLE_ONE_STATE(?ROLE2, 		mod_role2);
?MODULE_HANDLE_ONE_STATE(?VIP, 			mod_vip);
?MODULE_HANDLE_ONE_STATE(?DEPOT, 		mod_depot);
?MODULE_HANDLE_ONE_STATE(?ITEM, 		mod_item);
?MODULE_HANDLE_ONE_STATE(?EQUIP, 		mod_equip);
?MODULE_HANDLE_ONE_STATE(?REFINING, 	mod_refining);
?MODULE_HANDLE_ONE_STATE(?SHOP, 		mod_shop);
?MODULE_HANDLE_ONE_STATE(?LEVEL_GIFT, 	mod_level_gift);
?MODULE_HANDLE_ONE_STATE(?FLOWERS,		mod_flowers);
?MODULE_HANDLE_ONE_STATE(?BROADCAST,	mod_broadcast);
?MODULE_HANDLE_ONE_STATE(?LETTER,		mod_letter);
?MODULE_HANDLE_ONE_STATE(?COLLECT,		mod_map_collect);
?MODULE_HANDLE_ONE_STATE(?HERO_FB, 		mod_hero_fb);
?MODULE_HANDLE_ONE_STATE(?EGG,			mod_egg_shop);
?MODULE_HANDLE_ONE_STATE(?SPRING,       mod_spring);

?MODULE_HANDLE_TWO(?PET,				mod_map_pet);
?MODULE_HANDLE_TWO(?EQUIP_BUILD,		mod_equip_build);
?MODULE_HANDLE_TWO(?FIGHT,				mof_fight_handler);
?MODULE_HANDLE_TWO(?MOVE,				mod_move);
?MODULE_HANDLE_TWO(?RNKM, 				mod_mirror_rnkm);
?MODULE_HANDLE_TWO(?CLGM, 				mod_mirror_clgm);
?MODULE_HANDLE_TWO(?EXAMINE_FB, 		mod_examine_fb);
?MODULE_HANDLE_TWO(?MIRROR_FIGHT, 		mod_mirror_fb);


do_handle_info({role_online, RoleID, IsFirstEnter}, _State) ->
	check_auto_relive(RoleID),
	hook_role:online(RoleID, IsFirstEnter);

%% 第一次进入地图
do_handle_info({first_enter, Info}, State) ->
    mod_map_actor:handle({first_enter, Info}, State);

%%传送卷
do_handle_info({Unique, ?MAP, ?MAP_TRANSFER, DataIn, RoleID, _PID, Line}, State) ->
    mod_map_transfer:handle({Unique, ?MAP, ?MAP_TRANSFER, DataIn, RoleID, _PID, Line}, State);

do_handle_info({Unique, ?MAP, Method, DataIn, RoleID, PID, Line}, State) ->
    mgeem_map:handle_info({Unique, ?MAP, Method, DataIn, RoleID, PID, Line}, State);

do_handle_info({Unique, ?DRIVER, Method, DataIn, RoleID, PID, _Line}, _State) ->
    mod_driver:handle({Unique, ?DRIVER, Method, DataIn, RoleID, PID});

do_handle_info({Unique, ?TEAM, Method, DataIn, RoleID, Pid, _Line}, _State) ->
    mod_map_team:do_handle_info({Unique, ?TEAM, Method, DataIn, RoleID, Pid});

%% 成就系统处理模块
do_handle_info({mod_achievement2, Msg}, _State) ->
    mod_achievement2:handle(Msg);

do_handle_info({mod_offline_event, Msg}, _State) ->
    mod_offline_event:handle(Msg);

do_handle_info({mod_yvip_activity, Msg}, _State) ->
    mod_yvip_activity:handle(Msg);

%% 声望兑换功能
do_handle_info({Unique, ?PRESTIGE, Method, DataIn, RoleID, Pid, _Line}, _State) ->
    mod_prestige:do_handle_info({Unique, ?PRESTIGE, Method, DataIn, RoleID, Pid});
do_handle_info({mod_prestige, Msg}, _State) ->
    mod_prestige:do_handle_info(Msg);

%% 排行榜
do_handle_info({Unique, ?RANKING, ?RANKING_EQUIP_JOIN_RANK, DataIn, RoleID, Pid, Line}, _State) ->
    do_ranking_equip_join_rank(Unique, ?RANKING, ?RANKING_EQUIP_JOIN_RANK, DataIn, RoleID, Pid, Line);

do_handle_info({Unique, ?PERSONYBC, Method, DataIn, RoleID, _PID, Line}, State) ->
    mod_ybc_person:handle({Unique, ?PERSONYBC, Method, DataIn, RoleID, _PID,Line, State});

do_handle_info({apply, Fun}, _State) ->
	Fun();
do_handle_info({apply, Mod, Fun, Args}, _State) ->
	apply(Mod, Fun, Args);
%%对指定的模块发送消息，通用，建议使用
do_handle_info({mod,Module,Msg}, State) ->
    Module:handle(Msg, State);
do_handle_info({mod_fight,Msg}, State) ->
    mof_fight_handler:handle(Msg, State);
do_handle_info({mod_map_actor,Msg}, State) ->
    mod_map_actor:handle(Msg, State);
%% 日常循环任务模块 
do_handle_info({mod_daily_mission,Msg}, State) ->
    mod_daily_mission:handle(Msg, State);
%% 新手模块
do_handle_info({mod_newcomer,Msg},_State) ->
    mod_newcomer:handle(Msg);
%% 境界模块自动升级
do_handle_info({mod_role_jingjie,Msg},_State) ->
    mod_role_jingjie:handle(Msg);
do_handle_info({mod_role_juewei,Msg},_State) ->
    mod_role_juewei:handle(Msg);
%% 战神坛积分赛
do_handle_info({mod_crown_arena_fb,Msg},_State) ->
    mod_crown_arena_fb:handle(Msg);
%% 战神坛排名赛
do_handle_info({mod_crown_arena_cull_fb,Msg},_State) ->
    mod_crown_arena_cull_fb:handle(Msg);
%% 体力模块 
do_handle_info({mod_tili,Msg}, State) ->
    mod_tili:handle(Msg, State);
do_handle_info({mod_pk, Msg}, State) ->
    mod_pk:handle(Msg, State);
do_handle_info({mod_map_office,Msg}, State) ->
    mod_map_office:handle(Msg, State);
do_handle_info({mod_flowers,Msg}, State) ->
    mod_flowers:handle({Msg, State});

%% VIP
do_handle_info({mod_vip, Msg}, _State) ->
    mod_vip:handle(Msg);
do_handle_info({mod_skill, Msg}, _State) ->
    mod_skill:handle(Msg);
%% 信件处理
do_handle_info({mod_letter,Msg},_State)->
    mod_letter:handle(Msg);
do_handle_info({mod_daily_pay, Msg}, _State) ->
    mod_daily_pay:handle(Msg);
do_handle_info({mod_treasbox, Msg}, _MapState) ->
    mod_treasbox:handle(Msg);
%% 系统产出告知模块
do_handle_info({mod_access_guide,Msg}, _State) ->
    mod_access_guide:handle(Msg);
%% 魔尊洞窟
do_handle_info({mod_guard_fb, Msg}, _State) ->
    mod_guard_fb:handle(Msg);

do_handle_info({mod_mission_change_skin, Msg}, State) ->
    mod_mission_change_skin:handle(Msg,State);

do_handle_info({mod_stall, Msg}, _State) ->
    mod_stall:handle(Msg);

do_handle_info({mod_map_collect,Msg},State) ->
    mod_map_collect:handle({Msg,State});
do_handle_info({mod_map_monster,Msg}, State) ->
    mod_map_monster:handle(Msg,State);

%% 神王令任务模块 
do_handle_info({mod_swl_mission,Msg},State) ->
    mod_swl_mission:handle(Msg,State);

do_handle_info({mod_map_team, Msg}, _State) ->
    mod_map_team:do_handle_info(Msg);

do_handle_info({mod_pet_training, Msg}, _State) ->
    mod_pet_training:handle(Msg);

% do_handle_info({mod_nuqi_huoling, Msg}, _State) ->
% 	mod_nuqi_huoling:handle(Msg);

%%@doc 每天零点处理的事情
do_handle_info(do_at_oclock, _State) ->
    erlang:send_after(common_time:diff_next_daytime(0, 0)*1000, self(), do_at_oclock),    
    hook_at_oclock:hook([get(role_id)]); 

%%@doc 验证qq用户的登录态，对有效期进行续期
do_handle_info(is_login, _State) ->
    erlang:send_after(?ROLE_IS_LOGIN_STATUS_INTERVAL, self(), is_login),
	mod_qq_api:is_login(get(role_id));

do_handle_info({enter_map, MapPID, MapState, ApplyAfterEnterMap}, _State) ->
	MapID = MapState#map_state.mapid,
	case ?IS_SOLO_FB(MapID) of
		true ->
			erlang:send(self(), loop),
			erlang:send(self(), loop_ms);
		_ ->
			ignore
	end,
	put(map_id, MapID),
	put(map_pid, MapPID),
	put(map_state_key, MapState),
	RoleID = get(role_id),
	mod_role_tab:update_element(RoleID, p_role_pos, [
		{#p_role_pos.map_id, MapID}, 
		{#p_role_pos.map_process_name, MapState#map_state.map_name}
	]),
	case ApplyAfterEnterMap of
		{_, {M, F, A}} ->
			apply(M, F, A);
		_ ->
			ignore
	end,
	check_auto_relive(RoleID);

do_handle_info(loop, MapState) ->
	case is_record(MapState, map_state) andalso ?IS_SOLO_FB(MapState#map_state.mapid) of
		true ->
			erlang:send_after(1000, self(), loop),
			hook_map:loop(MapState#map_state.mapid);
		_ ->
			ignore
	end;

do_handle_info(loop_ms, MapState) ->
	case is_record(MapState, map_state) andalso ?IS_SOLO_FB(MapState#map_state.mapid) of
		true ->
			erlang:send_after(200, self(), loop_ms),
		    NowMsec = common_tool:now2(),
		    erlang:put(now2, NowMsec),    
		    hook_map:loop_ms(MapState#map_state.mapid, NowMsec);
		_ ->
			case erase(is_map_process) of
				true ->
					PID = get('PID'),
					erase({pid_to_roleid, PID}),
					mgeem_map:flush_all_role_msg_queue(),
					put({roleid_to_pid, get(role_id)}, {PID, in_role_process}),
					mod_solo_fb:clear();
				_ ->
					ignore
			end
	end;

do_handle_info({mod_qrhl, Msg}, _State) ->
    RoleID = get(role_id),
    mod_qrhl:handle(RoleID, Msg);
do_handle_info({mod_gm,Msg}, State) ->
    mod_gm:handle(Msg, State);
do_handle_info({mod_map_role,Msg}, State) ->
    mod_map_role:handle(Msg, State);
do_handle_info({mod_map_pet, Msg}, State) ->
    mod_map_pet:handle(Msg, State);
do_handle_info({mod_map_family,Msg}, State) ->
    mod_map_family:handle(Msg, State);

do_handle_info({mod_role2,Msg}, _State)->
	mod_role2:handle(Msg);
do_handle_info({mod_mission_handler, Msg}, _State) ->
    mod_mission_handler:handle(Msg);
do_handle_info({mod_bag_handler,Msg}, State) ->
    mod_bag_handler:handle(Msg,State);
do_handle_info({mod_nimbus, Msg}, _State) ->
    mod_nimbus:handle(Msg);
do_handle_info({mod_horse_racing, Msg}, _State)->
    mod_horse_racing:handle(Msg);

do_handle_info({change_attr,family_contribute,RoleID,Value},_State) ->
    mod_map_role:update_role_attr({family_contribute,Value},RoleID);

do_handle_info({mod_mission_fb, Msg}, _State) ->
    mod_mission_fb:handle(Msg);

do_handle_info({mod_bigpve_fb,Msg},_State) ->
    mod_bigpve_fb:handle(Msg);

do_handle_info({mod_role_signin, signin, RoleID, Day}, _State) ->
	PID = get('PID'),
	mod_role_signin:handle({signin, PID, RoleID, Day});	

do_handle_info({mod_role_signin, clear_signin, RoleID}, _State) ->
	PID = get('PID'),
	mod_role_signin:handle({clear_signin, PID, RoleID});	

do_handle_info({mod_time_gift, clear_timegift, RoleID}, _State) ->
	PID = get('PID'),
	mod_time_gift:handle({clear_timegift, PID, RoleID});	
	
do_handle_info({mod_time_gift, time_gift, RoleID}, _State) ->
	PID = get('PID'),
	mod_time_gift:handle({time_gift, PID, RoleID});	

%% 初始化离线事件	
do_handle_info({dispatch_offline_event, RoleID}, State) ->
	Rec = mod_offline_event:get_db_data(RoleID),
	mod_offline_event:dispatch_event(Rec),
	{noreply, State};

%% 检测成就中的家族成就
do_handle_info({check_family_achievement, RoleID, FamilyInfo}, _State) ->
	mod_achievement2:achievement_update_event(RoleID, 33005, FamilyInfo#p_family_info.level),
	mod_achievement2:achievement_update_event(RoleID, 44001, FamilyInfo#p_family_info.level);

do_handle_info({qq_buy_goods_callback, From, Token, ItemNum, Amt}, _State) ->
	mod_shop_qq_callback:handle({qq_buy_goods_callback, From, Token, ItemNum, Amt});
do_handle_info({qq_exchange_goods_callback, From, Token, ItemNum, Amt}, _State) ->
	mod_shop_qq_callback:handle({qq_exchange_goods_callback, From, Token,ItemNum, Amt});
do_handle_info({qq_activity_callback, From, _Discountid, Token, ItemType, ItemNum}, _State) ->
	Ret = mod_yvip_activity:open_yvip_callback(get(role_id), Token, ItemType, ItemNum),
	From ! Ret;	

do_handle_info(role_base_attr_persistent, _State) ->
	erlang:send_after(?ROLE_BASE_ATTR_PERSISTENT_INTERVAL*1000, self(), role_base_attr_persistent),
	mod_map_role:role_base_attr_persistent();

do_handle_info({timeout, TimerRef, {buff_timeout, ActorType, ActorID, BuffID}}, State) ->
	case ActorType of
		role ->
			mod_role_buff:handle({buff_timeout, TimerRef, ActorID, BuffID}, State);
		pet ->
			mod_pet_buff:handle({buff_timeout, TimerRef, ActorID, BuffID}, State);
		_ ->
			ignore
	end;

do_handle_info({timeout, TimerRef, {pet_grow_timeout, GrowInfo}}, _State) ->
	mod_pet_grow:change_grow_level(GrowInfo, TimerRef);

do_handle_info(Info, State) ->
    ?ERROR_MSG("receive unknow msg: ~w, State: ~w", [Info, State]).

%% --------------------------------------------------------------------
%% Function: terminate/2
%% --------------------------------------------------------------------
terminate(Reason, _State) ->
	?DBG("offline,RoleID=~w,Reason=~w",[get(role_id),Reason]),
	hook_role:terminate(),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% @doc 神兵排行榜在地图这边的处理，先获取到装备的信息再发到排行榜进程
do_ranking_equip_join_rank(Unique, Module, Method, DataIn, RoleID, Pid, Line) ->
    #m_ranking_equip_join_rank_tos{goods_id=GoodsID} = DataIn,

    case mod_bag:get_goods_by_id(RoleID, GoodsID) of
        {ok, GoodsInfo} ->
            do_ranking_equip_join_rank2(Unique, Module, Method, DataIn, GoodsInfo, RoleID, Pid, Line),
            ok;
        {error, _} ->
            case mod_goods:get_equip_by_id(RoleID, GoodsID) of
                {ok, GoodsInfo} ->
                    do_ranking_equip_join_rank2(Unique, Module, Method, DataIn, GoodsInfo, RoleID, Pid, Line),
                    ok;
                _ ->
                    DataRecord = #m_ranking_equip_join_rank_toc{succ=false, reason=?_LANG_RANKING_EQUIP_NOT_EXIST},
                    common_misc:unicast2(Pid, Unique, Module, Method, DataRecord)
            end
    end.

do_ranking_equip_join_rank2(Unique, Module, Method, DataIn, GoodsInfo, RoleID, Pid, Line) ->
    case global:whereis_name(mgeew_ranking) of
        undefined ->
            DataRecord = #m_ranking_equip_join_rank_toc{succ=false, reason=?_LANG_SYSTEM_ERROR},
            common_misc:unicast2(Pid, Unique, Module, Method, DataRecord);
        RPID ->
            %% 将goods_id替换成goods_info，不大好的处理，暂时这样
            DataIn2 = DataIn#m_ranking_equip_join_rank_tos{goods_id=GoodsInfo},

            Info = {Unique, Module, Method, DataIn2, RoleID, Pid, Line},
            RPID ! Info
    end.

check_auto_relive(RoleID) ->
    case mod_map_role:get_role_base(RoleID) of
        {ok, #p_role_base{status=?ROLE_STATE_DEAD}} ->
			mod_map_role:role_dead_normal(RoleID, "", false);
		_ ->
			ignore
	end.

reload_role_base(RoleID, Calc1, Attrs1) ->
	{ok, #p_role_base{} = RoleBase} = mod_map_role:get_role_base(RoleID),
	NewRoleBase = mod_role_attr:calc(RoleBase, Calc1, Attrs1),
	mod_role_attr:reload_role_base(NewRoleBase).
reload_role_base(RoleID, Calc1, Attrs1, Calc2, Attrs2) ->
	{ok, #p_role_base{} = RoleBase} = mod_map_role:get_role_base(RoleID),
	NewRoleBase = mod_role_attr:calc(RoleBase, Calc1, Attrs1, Calc2, Attrs2),
	mod_role_attr:reload_role_base(NewRoleBase).

