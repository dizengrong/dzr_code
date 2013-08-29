%%%-----------------------------------
%%% @Module  : mod_login
%%% @Email   : dizengrong@gmail.com
%%% @Created : 2011.08.7
%%% @Description: 用户登陆
%%%-----------------------------------
-module(mod_login).

-include("common.hrl").
%% -include("player_record.hrl").

-define (PROCESS_SPEC(Module, Args), 
	{Module, {Module, start_link, Args}, transient, 100, worker, [Module]}).

-export([login/3, 
		 logout_sync/1,
		 logout_async/1,
		 stop_all/0,
		 do_after_login_init/3]).



%% 用户登陆， 登录成功返回{ok, Pid}|{error, fail}
login(start, [Id, _Accname, Fcm, ReaderPid], Socket)  ->
	%% 检查死进程
	%%todo, 检查顶号,考虑看能否把进程接回来
	login(Id,Socket,Fcm, ReaderPid).

%% 开始一个游戏进程
login(PlayerId, Socket, Fcm, ReaderPid) ->
	case mod_player:is_online(PlayerId) of
		false -> 
			{Account_info, Economy_info} = mod_account:get_info_by_id(PlayerId),
			?INFO(login,"account info is ~w, economy info is ~w",[Account_info, Economy_info]),
			case is_locked(Account_info) of
				true -> 
					{error, fail};
				_ ->
					{ok,Sup_pid} = login_success(Account_info, Economy_info, Socket, Fcm, ReaderPid),
					{ok, Sup_pid}
			end;
		{true, _PS} ->
			logout_sync(PlayerId),
			%%cjr, 注意，这个地方潜在地会产生死递归
			%%更安全的做法应该是加上个retry flag，如果retry次数太离谱了就中断递归
			login(PlayerId, Socket, Fcm, ReaderPid)
	end.
	

is_locked(Account_info) ->
	case Account_info#account.gd_Lock of
		1 -> %% 封号了
			Now = util:unixtime(),
			(Now < Account_info#account.gd_LockLimitTime);
		_ -> false
	end.

    
%%=========================================================
%% 把所有在线玩家踢出去
%%=========================================================
stop_all() ->
    L = ets:tab2list(?ETS_ONLINE),
    do_stop_all(L).

logout_sync(PlayerId)->
	case mod_player:is_online(PlayerId) of
		false ->
			?ERR(logout, "player ~w already logout", [PlayerId]),
			{logout, player_not_online};
		{true, PS} ->
			process_flag(trap_exit, true),
			Reader_pid = PS#player_status.reader_pid,
			link(PS#player_status.player_sup_pid),
			mod_player_sup:stop(Reader_pid),
			receive
				{'EXIT',Pid,Reason}->
					?INFO(login, "got exit signal, Reason ~w from pid ~w",[Reason,Pid]),
					{logout, success};
				Other->
					?ERR(login,"unknown signal got, check what's that ~w",[Other]),
					{logout, fail}
			after 5000->
				?ERR(login,"timeout, should not happen"),
				{logout, timeout}
		end
	end.

logout_async(PlayerId)->
	case mod_player:is_online(PlayerId) of
		false ->
			?ERR(logout, "player ~w already logout", [PlayerId]),
			{logout, fail};
		{true, PS} ->
			Reader_pid = PS#player_status.reader_pid,
			mod_player_sup:stop(Reader_pid),
			{logout, success}
	end.

    

%%=========================================================
%% 退出登陆， 所有的其他logout函数必须最终调用这个 
%% Status:玩家状态记录，
%%=========================================================


%% 让所有玩家自动退出
do_stop_all([]) ->
    ok;
do_stop_all([H | T]) ->
	mod_player:logout_event(H#ets_online.id),
    logout_async(H#ets_online.id),
    do_stop_all(T).

%% 登陆成功，加载或更新数据
login_success(Account_info, Economy_info, Socket, Fcm, ReaderPid) ->	
	?INFO(mod_login, "PlayerAndOtherInfo = ~w, ~w", [Account_info, Economy_info]),
	%% 打开?SEND_MSG个广播信息进程，之前是开3个广播进程的，不过这样可能满足不了有发包先后顺序的情况，因此宏定义SEND_MSG改为了1个，不过接口保留
	%% TODO：LATE TO CHANGE THIS
	
	Self_pid = self(),
	Fun = fun(_)-> 
		spawn_link(fun()->
			  socket_queue:send_msg(Socket, Account_info#account.gd_accountID,Self_pid)
		end)
	end,
    SendPid = lists:map(Fun,lists:duplicate(1, 1)),

	%% 建立移动消息发送进程
	MoveQueuePid = erlang:spawn_link(move_queue, start, [Socket,SendPid]),
	
	{ok, Sup_id} = mod_player_sup:start_link(),
	
	%%在各模块init的时候再设置，这样监控树重启后才能挂回player进程
	Team_spec = ?PROCESS_SPEC(mod_team, [{Account_info#account.gd_accountID}]),
    {ok, Team_pid} = supervisor:start_child(Sup_id, Team_spec),

    OfficialSpec = ?PROCESS_SPEC(mod_official, [{Account_info#account.gd_accountID}]),
	{ok, OfficialPid} = supervisor:start_child(Sup_id, OfficialSpec),
    
	?INFO(login, "Starting Scene Process"),
   	SceneSpec = ?PROCESS_SPEC(scene, [Account_info#account.gd_accountID]),
	{ok, Scene_pid} = supervisor:start_child(Sup_id, SceneSpec),
	?INFO(login, "Finish Starting Scene"),
	
	RoleSpec = ?PROCESS_SPEC(mod_role, [{Account_info#account.gd_accountID}]),
	{ok, RolePid} = supervisor:start_child(Sup_id, RoleSpec),

	ChatSpec = ?PROCESS_SPEC(mod_chat, [{Account_info#account.gd_accountID}]),
	{ok, ChatPid} = supervisor:start_child(Sup_id, ChatSpec),

    TaskSpec = ?PROCESS_SPEC(mod_task, [Account_info#account.gd_accountID]),
    {ok, TaskPid} = supervisor:start_child(Sup_id, TaskSpec),

	ItemsSpec = ?PROCESS_SPEC(mod_items, [Account_info#account.gd_accountID]),
    {ok, ItemsPid} = supervisor:start_child(Sup_id, ItemsSpec),

	Relation_spec = ?PROCESS_SPEC(mod_relationship, [Account_info#account.gd_accountID]),
    {ok, Relation_pid} = supervisor:start_child(Sup_id, Relation_spec),

    DungeonSpec = ?PROCESS_SPEC(mod_dungeon, [{Account_info#account.gd_accountID}]),
    {ok, DungeonPid} = supervisor:start_child(Sup_id, DungeonSpec),

    FengdiSpec = ?PROCESS_SPEC(mod_fengdi, [{Account_info#account.gd_accountID}]),
    {ok, FengdiPid} = supervisor:start_child(Sup_id, FengdiSpec),

    XunxianSpec = ?PROCESS_SPEC(mod_xunxian,[Account_info#account.gd_accountID]),
    {ok, XunxianPid} = supervisor:start_child(Sup_id, XunxianSpec),

    DazuoSpec = ?PROCESS_SPEC(mod_dazuo,[Account_info#account.gd_accountID]),
    {ok, DazuoPid} = supervisor:start_child(Sup_id, DazuoSpec),
	
	GuajiSpec = ?PROCESS_SPEC(mod_guaji,[Account_info#account.gd_accountID]),
	{ok, GuajiPid} = supervisor:start_child(Sup_id, GuajiSpec),

	ArenaSpec = ?PROCESS_SPEC(mod_arena,[Account_info#account.gd_accountID]),	
	{ok, ArenaPid} = supervisor:start_child(Sup_id, ArenaSpec),	
	
	GuildSpec = ?PROCESS_SPEC(guild, [Account_info#account.gd_accountID]),
	{ok, GuildPid} = supervisor:start_child(Sup_id, GuildSpec),
	
	AnnouncementSpec = ?PROCESS_SPEC(mod_announcement,[Account_info#account.gd_accountID]),  
	{ok, AnnouncementPid} = supervisor:start_child(Sup_id, AnnouncementSpec),	

	YunBiaoSpec = ?PROCESS_SPEC(mod_yunbiao,[Account_info#account.gd_accountID]),	
	{ok, YunBiaoPid} = supervisor:start_child(Sup_id, YunBiaoSpec),

	MarstowerSpec = ?PROCESS_SPEC(mod_marstower,[Account_info#account.gd_accountID]),	
	{ok, MarstowerPid} = supervisor:start_child(Sup_id,MarstowerSpec),

	AchieveSpec = ?PROCESS_SPEC(mod_achieve,[Account_info#account.gd_accountID]),
	{ok, AchievePid} = supervisor:start_child(Sup_id,AchieveSpec),

	BossSpec = ?PROCESS_SPEC(mod_boss,[Account_info#account.gd_accountID]),
	{ok, BossPid} = supervisor:start_child(Sup_id,BossSpec),

    TempBagSpec = ?PROCESS_SPEC(mod_temp_bag,[Account_info#account.gd_accountID]),
    {ok, TempBagPid} = supervisor:start_child(Sup_id,TempBagSpec),
    
    CoolDownSpec = ?PROCESS_SPEC(mod_cool_down,[Account_info#account.gd_accountID]),
    {ok, CoolDownPid} = supervisor:start_child(Sup_id,CoolDownSpec),

    RankSpec = ?PROCESS_SPEC(mod_rank,[Account_info#account.gd_accountID]),
    {ok, RankPid} = supervisor:start_child(Sup_id,RankSpec),

	
	Player_status = #player_status{
					id             = Account_info#account.gd_accountID,
					scene_pid      = Scene_pid, 
					mer_pid        = RolePid, 
					send_pid       = SendPid,
					guild_pid      = GuildPid,
					move_queue_pid = MoveQueuePid,
					player_sup_pid = Sup_id,
					reader_pid     = ReaderPid,
					chat_pid       = ChatPid,
					task_pid       = TaskPid,
					items_pid      = ItemsPid,
					relation_pid   = Relation_pid,
					story_pid      = DungeonPid,
					team_pid       = Team_pid,
					official_pid   = OfficialPid,
					fengdi_pid     = FengdiPid,
					xunxian_pid    = XunxianPid,
					dazuo_pid      = DazuoPid,
					arena_pid      = ArenaPid,					
					guaji_pid	   = GuajiPid,					
					yunbiao_pid    = YunBiaoPid,
					marstower_pid  = MarstowerPid,
					achieve_pid    = AchievePid,
					announcement_pid = AnnouncementPid,
                    temp_bag_pid   = TempBagPid,
                    cool_down_pid  = CoolDownPid,
					boss_pid       = BossPid,
				    rank_pid       = RankPid

				},

	?INFO(mod_login,"After login, PlayerStatus:~w", [Player_status]),
    %% 通知mod_player让它记录该玩家状态
    PlayerSpec = ?PROCESS_SPEC(mod_player, [{Account_info,Player_status,self()}]),
	{ok, _PlayerPid} = supervisor:start_child(Sup_id, PlayerSpec),
	?INFO(login, "start child done."),	

	do_after_login_init(Account_info#account.gd_accountID, SendPid,Fcm),
	?INFO(login, "do after login done."),	
	mod_player:login_event(Account_info#account.gd_accountID),
	?INFO(login, "login event done."),	
    {ok,Sup_id}.

do_after_login_init(PlayerId, SendPid,Fcm) ->
	{Account_info, _Economy_info} = mod_account:get_info_by_id(PlayerId),
	Economy      = mod_economy:get(PlayerId),
	Position     = scene:get_position(PlayerId),
	VipLevel     = mod_vip:get_vip_level(PlayerId),
	AchieveTitle = mod_achieve:get_title(PlayerId),
	MainRoleLv = mod_role:get_main_level(PlayerId),
	Weiwang = mod_role:get_weiwang(PlayerId),
	%%获取防沉迷信息
	{FCMofflineTime,FCMonlineTime} = if
		Fcm == ?NOT_FCM -> {0,0}; 
		true ->	calc_fcm(Account_info#account.gd_accountID)
	end,
	{ok, BinData1} = pt_10:write(10003, {Account_info,
						Position,
						Economy,
						VipLevel,
						AchieveTitle,
						MainRoleLv,
						Weiwang,
						{FCMonlineTime,FCMofflineTime}
						}),

    lib_send:send_direct(SendPid, BinData1).
	
calc_fcm(Id)->
	Player_data = player_db:get_player_data(Id),
	Account_info = mod_account:get_account_info_rec(Id),

	Login_time = util:unixtime(),

	OfflineTime = Login_time - Account_info#account.gd_LastLoginoutTime,
	?INFO(fcm, "offline time is ~w", [OfflineTime]),
	
	Total = OfflineTime + Player_data#player_data.gd_fcmOfflineTime,
	?INFO(fcm, "Total offline time is ~w", [Total]),

	case Total >= ?FCM_OFFLIEN_RESET_TIME of
		true ->
			player_db:update_player_data_elements(Id, Id, [{#player_data.gd_fcmOfflineTime,0},
								{#player_data.gd_fcmOnlineTime,0}]), 
			{0, 0}; %% 重置防沉迷时间
		
		false ->
			%%更新防沉迷离线时间为total
			player_db:update_player_data_elements(Id, Id, [{#player_data.gd_fcmOfflineTime,Total}]),
			
			{Total, Player_data#player_data.gd_fcmOnlineTime}
	end.

	