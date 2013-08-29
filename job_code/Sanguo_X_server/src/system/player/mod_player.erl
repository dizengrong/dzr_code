-module(mod_player).

-include("common.hrl").

-export([start_link/1, update_module_pid/3, init_ets/0, get_player_status/1,
		 is_online/1, logout_event/1, login_event/1, get_pid/2,
		 battle_complete/2, get_main_role_id/1]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% internal export
-export([update_module_pid2/2, get_player_status2/2, check_battle/3, check_pvp_battle/5, set_battle/2, clear_battle/2,
	get_pid2/2]).

-record(state, {
	account_info,
	ps
	}).

init_ets()->
	ets:new(?ETS_ONLINE, [public,named_table,{keypos,#ets_online.id}]).

start_link({Account_info,Player_status,Reader_pid})->
	gen_server:start_link(?MODULE, {Account_info,Player_status,Reader_pid}, []).

-spec get_player_status(player_id()) -> undefined | ps().
get_player_status(PlayerId)->
	case is_online(PlayerId) of
		false ->
			?ERR(player,"player ~w is not online", [PlayerId]),
			undefined;
		{true, PS} ->
			PS
	end. 

%% 获取对应模块的pid
-spec get_pid(player_id(), Module::atom()) -> none | pid().
get_pid(PlayerId, ModuleName) ->
	case ets:lookup(?ETS_ONLINE, PlayerId) of
		[Rec]->
			gen_server:call(Rec#ets_online.pid, {message, get_pid2, [ModuleName]});
		[]->
			none
	end.

-spec is_online(player_id()) -> false | {true, ps()}.
is_online(PlayerId)->
	case ets:lookup(?ETS_ONLINE, PlayerId) of
		[Rec]->
			PS = gen_server:call(Rec#ets_online.pid, 
							{message, get_player_status2, []}),
			{true, PS};
		[]->
			false
	end.

update_module_pid(Id,Module_reference,Update_pid)->
	case ets:lookup(?ETS_ONLINE, Id) of
		[Rec]->
			gen_server:cast(Rec#ets_online.pid, 
				{message, update_module_pid2, [Module_reference,Update_pid]});
		[]->
			?INFO(player,"player ~w is not online",[Id])
	end.

%% 玩家下线事件，在这里保存不能在进程terminate时保存的数据
logout_event(PlayerId) ->
	?INFO(rankings,"computer ~w's rankstatus for offline",[PlayerId]),
	mod_rank:updateAllRank(PlayerId),
	Player_data = player_db:get_player_data(PlayerId),
	Account_info = mod_account:get_account_info_rec(PlayerId),
	Now = util:unixtime(),
%%	player_db:save_logout_time(PlayerId, Now),
%%	LastLoginTime = player_db:get_last_login_time(PlayerId),
	LastLoginTime = Account_info#account.gd_LastLoginTime,

	DayOnlineTime = Player_data#player_data.gd_dayOnlineTime, 
	OnlineTime = Player_data#player_data.gd_totalOnlineTime,
	
	TotalOnlineTime = (Now - LastLoginTime) + OnlineTime,

	case util:get_diff_day(LastLoginTime, Now) of
		the_same_day ->
			DayOnlineTime1 = (Now - LastLoginTime) + DayOnlineTime;
		_ -> 
			{_, {H, M, S}} = calendar:seconds_to_daystime(Now),
			DayOnlineTime1 = H*3600 + M*60 + S
	end,
	
	%%更新防沉迷时间
	FCM_online_time = (Now - LastLoginTime) + Player_data#player_data.gd_fcmOnlineTime,
	?INFO(fcm,"fcm online time is ~w",[FCM_online_time]),
	player_db:update_account_elements(PlayerId, PlayerId, [{#account.gd_LastLoginoutTime,Now}]),
	player_db:update_player_data_elements(PlayerId, PlayerId, [{#player_data.gd_dayOnlineTime,DayOnlineTime1},
									{#player_data.gd_totalOnlineTime,TotalOnlineTime},
									{#player_data.gd_fcmOnlineTime, FCM_online_time}]).



login_event(PlayerId) ->
	Now = util:unixtime(),
	player_db:save_login_time(PlayerId, Now),
	ok.

%% 战斗结果处理
battle_complete(PlayerId, BattleResult) ->
	?INFO(mod_player, "calling battle_complete"),

	case get_player_status(PlayerId) of
		false -> 
			?ERR(player, "battle result ~w not handled", [BattleResult]);
		PS ->
			gen_server:cast(PS#player_status.player_pid, {battle_complete, BattleResult})
	end.

%% 获取主将的角色id
get_main_role_id(PlayerId) ->
	AccoutRec = mod_account:get_account_info_rec(PlayerId),
	AccoutRec#account.gd_RoleID.

init({Account_info,PS, _Reader_pid})->
    %% 更新ETS_ONLINE在线表
	Online_info = #ets_online{
			id       = Account_info#account.gd_accountID,
			accname  = Account_info#account.gd_Account,
			nickname = Account_info#account.gd_RoleName,
			pid      = self(),
			send_pid = PS#player_status.send_pid
	},
	?INFO(login,"update ets online ~w",[Online_info]),

    true = ets:insert(?ETS_ONLINE, Online_info),

	erlang:process_flag(trap_exit, true),
	erlang:put(id, PS#player_status.id),
	PS1 = PS#player_status{player_pid = self()},
    {ok, #state{account_info = Account_info, ps = PS1}}.


handle_cast({clear_battle, BattlePid}, State) ->
	Ps = State#state.ps,
	if (Ps#player_status.battle_pid =/= BattlePid) ->
		{noreply, State};
	true ->
		Nps = Ps#player_status {battle_pid = ?UNDEFINED},
		{noreply, State#state{ps = Nps}}
	end;

handle_cast({battle_complete, BattleResult}, State) ->
	Ps = State#state.ps,
	?INFO(player, "reset battle pid"),
	Nps = Ps#player_status{battle_pid = ?UNDEFINED},
	
	hanleBattleEvent(State#state.ps, BattleResult),  %% 处理玩家战斗事件
	case BattleResult#battle_result.callback of
        {Mod, Fun, Args} ->
        	?INFO(battle,"battle callback succesful!"),
            Mod:Fun(State#state.ps, BattleResult, Args);
        CallbackList ->
        	handleCallbackList(CallbackList, BattleResult, State)
    end,
	{noreply, State#state{ps = Nps}};

handle_cast({message, Action, Args}, State) ->
	?INFO(player,"action is ~w, args is ~w",[Action,Args]),
	?MODULE:Action(State, Args).



handle_call({set_battle, BattlePid}, _From, State) ->
	Ps = State#state.ps,
	if (Ps#player_status.battle_pid =/= ?UNDEFINED) ->
		{reply, {false, in_battle}, State};
	true ->
		Nps = Ps#player_status {battle_pid = BattlePid},
		{reply, true, State#state{ps = Nps}}
	end;

handle_call({check_battle, BattlePid, TeamMateID}, _From, State) ->
	Ps = State#state.ps,
	ID = Ps#player_status.id,
	
	?INFO(player, "check battle: BattlePid = ~w, ID = ~w, TeamMateID = ~w",
		[BattlePid, ID, TeamMateID]),
	
	if (Ps#player_status.battle_pid =/= ?UNDEFINED) ->
		?ERR(battle, "player is in battle ID = ~w", [ID]),
		{reply, {false, in_battle}, State};
	true ->
		case TeamMateID of
			0 ->
				Nps = Ps#player_status {battle_pid = BattlePid},
				{reply, true, State#state {ps = Nps}};
			_ ->
				case mod_player:set_battle(TeamMateID, BattlePid) of
				true -> 
					Nps = Ps#player_status {battle_pid = BattlePid},
					{reply, true, State#state {ps = Nps}};
				false ->
					?ERR(player, "make team fail ID = ~w, MemID = ~w", [ID, TeamMateID]),
					{reply, {false, make_team_fail}, State}
				end
		end
	end; 

handle_call({check_pvp_battle, Pid, BattlePid, TeamMateID, RivalTeamMateID}, _From, State) ->
	Ps = State#state.ps,
	ID = Ps#player_status.id,
	?INFO(player, "check pvp battle, ID = ~w, TeamMateID = ~w", [ID, TeamMateID]),
	
	if (Ps#player_status.battle_pid =/= ?UNDEFINED) ->
		?ERR(player, "player is in battle ID = ~w", [ID]),
		{reply, {false, in_battle}, State};
	true ->
		case catch mod_player:check_battle(Pid, BattlePid, RivalTeamMateID) of
			true -> 
				case TeamMateID of
					0 ->
						Ps = State#state.ps,
						Nps = Ps#player_status {battle_pid = BattlePid},
						{reply, true, State#state {ps = Nps}};
					_ ->
						case mod_player:set_battle(TeamMateID, BattlePid) of
						true ->
							Nps = Ps#player_status {battle_pid = BattlePid},
							{reply, true, State#state {ps = Nps}};
						false ->
							{reply, {false, make_team_fail}, State}
						end
				end;
			{false, in_battle} ->
				{reply, {false, rival_in_battle}, State};
			{'EXIT', Reason} ->
				?ERR(player, "check battle fail Reason: ~w", [Reason]),
				{reply, {false, Reason}, State}
		end
	end;

handle_call({message, Action, Args}, _From,State) ->
	?INFO(player,"action is ~w, args is ~w",[Action,Args]),
	?MODULE:Action(State, Args).


handle_info(_Info, State) ->
    {noreply, State}.

terminate(Reason, State) ->
	%% 更新ETS_ONLINE在线表
	Account_info = State#state.account_info,
	ets:delete(?ETS_ONLINE, Account_info#account.gd_accountID),

	?INFO(player, "~w gen_server terminate, reason: ~w, state: ~w", 
		  [?MODULE, Reason, State]),
	
	Ps = State#state.ps,
	BattlePid = Ps#player_status.battle_pid,
	
	if (is_pid(BattlePid)) ->
		exit(BattlePid, kill);
	true ->
		ok
	end.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.	


%% ====================== handle cast message =========================
%% 如果你这个方法里面加了个pid，你也许也想在get_pid/2方法中也加一个对应的东东
update_module_pid2(State, [Module_reference, Update_pid]) ->
	?INFO(player,"update module pid for module ~w",[Module_reference]),
	PS = State#state.ps,
	case Module_reference of 
		battle ->
			New_state = PS#player_status{battle_pid = Update_pid};
		guild ->
			New_state = PS#player_status{guild_pid = Update_pid};
		mod_role->
			New_state = PS#player_status{mer_pid = Update_pid};
		mod_items->
			New_state = PS#player_status{items_pid = Update_pid};
		mod_dungeon->
			New_state = PS#player_status{story_pid = Update_pid};
		mod_relationship->
			New_state = PS#player_status{relation_pid = Update_pid};
		mod_team->
			New_state = PS#player_status{team_pid = Update_pid};
		mod_task ->
			New_state = PS#player_status{task_pid = Update_pid};
		scene ->
			New_state = PS#player_status{scene_pid = Update_pid};
		mod_official ->
			New_state = PS#player_status{official_pid = Update_pid};
		mod_chat ->
			New_state = PS#player_status{chat_pid = Update_pid};
		mod_horse ->
			New_state = PS#player_status{horse_pid = Update_pid};
		mod_fengdi ->
			New_state = PS#player_status{fengdi_pid = Update_pid};
		mod_xunxian ->
			New_state = PS#player_status{xunxian_pid = Update_pid};
		mod_dazuo ->
			New_state = PS#player_status{dazuo_pid = Update_pid};
		mod_guaji ->
			New_state = PS#player_status{guaji_pid = Update_pid};
		mod_marstower ->
			New_state = PS#player_status{marstower_pid = Update_pid};
		mod_achieve ->
			New_state = PS#player_status{achieve_pid = Update_pid};
        mod_temp_bag ->
            New_state = PS#player_status{temp_bag_pid = Update_pid};
        mod_cool_down ->
            New_state = PS#player_status{cool_down_pid = Update_pid};
		Other->
			?INFO(init,"unknown pid reference as ~w",[Other]),
			New_state = PS	
	end,
	{noreply, State#state{ps = New_state}}.

handleCallbackList([],_BattleResultRec,_State) ->
	void;
handleCallbackList([{Mod, Fun, Args}|Res],BattleResultRec,State) ->
	?INFO(battle,"battle callback succesful!"),
    Mod:Fun(State#state.ps, BattleResultRec, Args),
    handleCallbackList(Res,BattleResultRec,State);
handleCallbackList(_Else,_BattleResultRec,_State) ->
	?INFO(battle,"battle callback void!"),
    void.

%% ====================== end hanle cast message ======================

%% ====================== handle call message =========================
get_player_status2(State, []) ->
	{reply, State#state.ps, State}.

get_pid2(State, [ModuleName]) ->
	PS  = State#state.ps,
	Pid = case ModuleName of
		battle       	 -> PS#player_status.battle_pid;
		mod_role         -> PS#player_status.mer_pid;
		mod_items        -> PS#player_status.items_pid;
		mod_dungeon      -> PS#player_status.story_pid;
		mod_relationship -> PS#player_status.relation_pid;
		mod_team         -> PS#player_status.team_pid;
		mod_task         -> PS#player_status.task_pid;
		scene            -> PS#player_status.scene_pid;
		mod_official     -> PS#player_status.official_pid;
		mod_chat         -> PS#player_status.chat_pid;
		mod_horse        -> PS#player_status.horse_pid;
		mod_fengdi       -> PS#player_status.fengdi_pid;
		mod_xunxian      -> PS#player_status.xunxian_pid;
		mod_dazuo		 -> PS#player_status.dazuo_pid;
		mod_guaji		 -> PS#player_status.guaji_pid;
		mod_marstower    -> PS#player_status.marstower_pid;
		mod_achieve		 -> PS#player_status.achieve_pid
	end,
	{reply, Pid, State}.
%% ====================== end hanle call message ======================


clear_battle(ID, BattlePid) ->
	case ets:lookup(?ETS_ONLINE, ID) of
		[] -> ok;
		[#ets_online {pid = Pid}] ->
			gen_server:cast(Pid, {clear_battle, BattlePid})
	end.

set_battle(ID, BattlePid) ->
	case ets:lookup(?ETS_ONLINE, ID) of
		[] -> false;
		[#ets_online {pid = Pid}] ->
			gen_server:call(Pid, {set_battle, BattlePid})
	end.

check_battle(Pid, BattlePid, MakeTeam) ->
	gen_server:call(Pid, {check_battle, BattlePid, MakeTeam}).

check_pvp_battle(Pid1, Pid2, BattlePid, TeamMateID, RivalTeamMateID) ->
	gen_server:call(Pid1, {check_pvp_battle, Pid2, BattlePid, TeamMateID, RivalTeamMateID}).

hanleBattleEvent(PS,BattleResultRec) ->
	case BattleResultRec#battle_result.mon_id =/= undefined of
		true ->
			?INFO(task,"hit the monster one times!"),
			player_events:post_event(PS,'monster.fight_monster',{BattleResultRec#battle_result.mon_id}),
			case BattleResultRec#battle_result.is_win of
				true ->
					%% 玩家事件钩子：杀死怪物组合
					?INFO(task,"Finsh monster kill, group_id =~w",[BattleResultRec#battle_result.mon_id]),
		            player_events:post_event(PS, 'monster.kill_group', {BattleResultRec#battle_result.mon_id});
				false ->
					?INFO(task,"Cant defeat the monster,try again!"),
    				%% 玩家事件钩子：被怪物打死了
    				player_events:post_event(PS,'monster.monster_win',{BattleResultRec#battle_result.mon_id})
    		end;
    	false ->
    		void
    end.
	
