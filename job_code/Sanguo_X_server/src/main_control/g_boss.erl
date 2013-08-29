-module(g_boss).

-behaviour(gen_server).

-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

-export([start_link/0,
		 init_boss_time/0,
		 calc_stage_time/2,
		 calc_wait_time/2,
		 calc_stage_time/3,
		 get_boss_hp_ets/0,
		 get_boss_damage_ets/1,
		 get_boss_time_remain/1,
    	 boss_battle/3,
		 broadcast_battle_begin/0,
	     get_boss_rec/0,
		 is_boss_alive/1,
		 broadcast_battle_end/1,
		 get_boss_hp/3,
		 broadcast_battle_register/0
    	 ]).

-include("common.hrl").

-define(BOSS_RANK_LENGTH, 10). %%boss 排行榜长度

start_link()->
	gen_server:start_link({local,?MODULE},?MODULE, [], []).

boss_battle(PS, BattleResultRec, [])->
	Id = PS#player_status.id,
	gen_server:cast(?MODULE, {battle_end, Id, BattleResultRec, []}).

%%供战斗模块调用，返回每打一次boss,扣掉boss的血量,返回boss状态:alive(活着) kill(当前玩家击杀) dead(已被杀死)
-spec get_boss_hp(Id :: integer(), BossID :: integer(), Damage :: integer()) -> any().
get_boss_hp(Id, BooId, Damage)->
	gen_server:call(?MODULE, {get_boss_hp, Id, BooId, Damage}).

init([])->
	process_flag(trap_exit, true),
	?INFO(boss,"init boss done"),
	init_ets(), 
	init_boss(),
	init_boss_time(),
	{ok, null}.	

handle_call({request_register_to_battle, _Id}, _From, State)->
	?INFO(boss, "register to boss battle"),
	{H, M, S} = erlang:time(),
	Now = H*?SECONDS_PER_HOUR + M*?SECONDS_PER_MINUTE + S,
	WaitToFight = calc_wait_time(fight, Now),
	?INFO(boss,"the time of waiting to fight,WaitToFight:~w",[WaitToFight]),
	{reply, WaitToFight, State};

handle_call({get_boss_rec, Id}, _From, State)->
	?INFO(boss," get_boss_rec ,Id:~w",[Id]),
	Reply = get_boss_rec(),
	?INFO(boss,"boss rec:~w",[Reply]),
	{reply, Reply, State};

handle_call({get_damage_list, _Id}, _From, State)->
	?INFO(boss, "get_damage_list"),

	%%获取boss伤害列表
	DList = ets:tab2list(?ETS_BOSS_DAMAGE),

	%%排序，取出前10名
	RankList = lists:sort(fun(Rec1,Rec2)->Rec1#boss_damage.damage_value > Rec2#boss_damage.damage_value end, DList),
	case length(RankList) =< ?BOSS_RANK_LENGTH of
		true ->
			Reply = RankList;
		false ->
			Reply = lists:sublist(RankList,  1, ?BOSS_RANK_LENGTH)
	end,
	?INFO(boss,"DamageList reply:~w",[Reply]),
	{reply, Reply, State};

handle_call({get_boss_hp, Id, BossId, Damage}, _From, State)->
	?INFO(boss,"battle call get boss hp,Damage:~w",[Damage]),
	%%处理之前先检查玩家是否已经被boss击杀

	%% get boss hp ets
	BossHpRec = get_boss_hp_ets(),
	
	%%get boss damaged ets
	MyRec = get_boss_damage_ets(Id),
	
	%%get boss record
	[BossRec] = gen_cache:lookup(?BOSS_CACHE_REF, boss),
	?INFO(boss,"BossRec:~w",[BossRec]),
	
	%%get players who in boss battle scene
	SendList = ets:tab2list(?ETS_BOSS_DAMAGE),
	?INFO(boss,"SendList:~w",[SendList]),

	%% 	BossId = data_boss:get_magic_boss_id(),
	case is_boss_alive(BossId) of
		true ->
			BossNewHp0 = BossHpRec#boss_hp.hp_value - Damage,
			?INFO(boss,"boss didn't die, LeftHp:~w",[BossNewHp0]),
		
			case BossNewHp0 > 0 of
				true -> 
					%% boss 剩余的hp 小于等于 此次伤害值
					DamageValue1 = Damage + MyRec#boss_damage.damage_value,
					BossNewHp1 = BossNewHp0,
					Reply0 = {alive, DamageValue1, BossNewHp1};
				false ->
					%% boss 剩余的hp 小于等于 此次伤害值
					DamageValue1 = BossHpRec#boss_hp.hp_value + MyRec#boss_damage.damage_value,
					BossNewHp1 = 0,
					Reply0 = {kill, DamageValue1, BossNewHp1}
			end;
		false ->
			?INFO(boss,"boss have deied"),
			%%boss 已死，玩家伤害加0，boss 血量剩余0
			Reply0 = {dead, 0, 0}
	end,

	{BossState, DamageValue, BossNewHp} = Reply0,
	%%update my damage values which the boss is hurt
	ets:update_element(?ETS_BOSS_DAMAGE, Id, {#boss_damage.damage_value, DamageValue}),

	%% update boss hp ets 
	ets:update_element(?ETS_BOSS_HP, boss_hp, {#boss_hp.hp_value, BossNewHp}),
			
	%%send to client,update my damage ranking level
	{ok, Packet} = pt_62:write(62009, DamageValue),
	lib_send:send_by_id(Id, Packet),
			
    %%update boss damage ranking 可以在这及时更新排行榜
	
	%%update_boss_hp_to_client
	update_boss_hp_to_client(BossNewHp),

	{reply, BossState, State};


handle_call(finish, _From, State)->
	{reply, ok, State}.

handle_cast({enter_boss_scene, Id}, State)->
	?INFO(boss,"requst enter_boss_scene, Id:~w",[Id]),
	case ets:lookup(?ETS_BOSS_DAMAGE, Id) of
		[] ->
			MyRec = #boss_damage{id = Id, damage_value = 0, state = 1},
			ets:insert(?ETS_BOSS_DAMAGE, MyRec);
		[_MyRec] ->
			skip
	end,

	{noreply, State};

handle_cast({player_fight_boss, Id}, State)->
	?INFO(boss, "fight boss"),
	BossId =data_boss:get_magic_boss_id(),
	BossRec = get_boss_rec(),
	BoId = BossRec#boss_rec.boss_id,
	?INFO(boss, "boss id:~w",[BoId]),
	case is_boss_alive(BossId) of
		true ->
			case mod_cool_down:getCoolDownLeftTime(Id, ?BOSS_BATTLE_CD)	> 0 of
				true ->
					?INFO(boss,"player in cd, can not fight the boss"),
					mod_err:send_err_by_id(Id, ?ERR_IN_CD);
				false ->		
%% 					mod_cool_down:addCoolDownLeftTime(Id, ?BOSS_BATTLE_CD, ?BOSS_CD_TIME),%%加cd,cd 时间暂定15 sec
					Factor = (mod_counter:get_counter(Id, ?INSPIRE_SUCCES)+1),%%鼓舞系数
					?INFO(boss,"inspire factor + 1:~w",[Factor]),
					MerList = mod_role:get_on_battle_list(Id),
					?INFO(boss,"MerList:~w",[MerList]),
					F = fun (Role, Acc) ->
							NewRole = Role#role{p_att = Role#role.p_att*Factor, m_att = Role#role.m_att},
							[NewRole|Acc]
						end,
					MonsterRec = data_boss:get_boss_xy(),
					StartupInfo = 
						#battle_start {
							mod = pve,	
							type = ?BATTLE_TYPE_BOSS,
							att_id = Id,
							att_mer = lists:foldl(F, [], MerList),
							monster = MonsterRec#monster.group_id,
							callback = {g_boss, boss_battle, []} 
								},
					battle:start(StartupInfo)
			end;
		false ->
			?INFO(boss,"boss have deied"),
			skip
	end,

	{noreply, State};

handle_cast({battle_end, Id, BattleResultRec, []}, State)->
	?INFO(boss,"player battle end,Id:~w",[Id]),

	[BossRec] = gen_cache:lookup(?BOSS_CACHE_REF, boss),
	?INFO(boss,"BossRec:~w",[BossRec]),


	case BattleResultRec#battle_result.is_win  of
		true ->
			?INFO(boss, "player win the boss"),

			%% update boss state become dead 
			set_boss_state([{is_survival, false}]),

			%% insert next new boss data
			NewBossLevel = BossRec#boss_rec.boss_level+1,
			NewBossHp = data_boss:get_boss_hp_by_level(NewBossLevel),
			NewBossNickName = mod_account:get_player_name(Id),
			NewBossRec = #boss_rec{boss_nickname = NewBossNickName, boss_id = Id, boss_level = NewBossLevel, boss_hp = NewBossHp},
			gen_cache:update_record(?BOSS_CACHE_REF, NewBossRec),
			
			%%broadcast boss is dead
			broadcast_battle_end(Id);
		false ->
			?INFO(boss, "player lose  in the boss battle"),

			SceneId = data_boss:go_back_to_frist_position(),
			scene:go_to(Id, SceneId),
			
			mod_cool_down:addCoolDownLeftTime(Id, ?BOSS_BATTLE_CD, ?BOSS_CD_TIME),%%加cd,cd 时间暂定15 sec
%% 			CdTime = mod_cool_down:getCoolDownLeftTime(Id, ?BOSS_BATTLE_CD),
			%% 战斗结束设置cd 时间15秒
			{ok, Packet1} = pt_62:write(62007, ?BOSS_CD_TIME),
			lib_send:send_by_id(Id, Packet1)
	end,

	{noreply, State};
	

handle_cast(finish, State)->
	{noreply, State}.

handle_info(register, State) ->
%% 	%% refresh ets_boss_room
%% 	?INFO(boss, "kick all player...~n"),
%% 	ets:delete_all_objects(?ETS_BOSS_ROOM),
%% 	
	%% init boss, when finished initializing, boss's state is not alive, so we can not fight it.
	?INFO(boss, "reset boss information...~n"),
	reset_boss(),

	%% let player can register.
	F = fun(_BossID) ->
			set_boss_state([{is_open, true}])
		end,
	lists:foreach(F, data_boss:get_all_boss()),
	
	broadcast_battle_register(),
	{noreply, State};

handle_info(fight, State) ->
	%% set the boss state to alive
	?INFO(boss, "broadcast boss battle begin,make boss alive...~n"),
	get_boss_rec(),
	set_boss_state([{is_survival, true}]),

	broadcast_battle_begin(),
	{noreply, State};

handle_info(die, State) ->
	throw(die),
	{noreply, State};

handle_info(stop, State) ->
   ?INFO(boss, "broadcast boss battle over ,recv msg: stop...~n"),
	%% broadcasting here...
	List = data_boss:get_all_boss(),
	F = fun(_BossID) ->
			set_boss_state([{is_survival, false}, {is_open, false}])
%%             case get_boss_hp(0,BossID, 0) > 0 of
%%                 true -> adjust_boss_hp();
%%                 _    -> void
%%             end
		end,
	lists:foreach(F, List),

	broadcast_battle_end(0),

	{noreply, State};

handle_info({boss_damage, Statistic}, State)->
	?INFO(boss, "update boss hp in time..."),
	?INFO(boss,"Statistic:~w",[Statistic]),
	{CountHurt, _MaxHurt} = Statistic,
	[BossRec] = gen_cache:lookup(?BOSS_CACHE_REF, boss),
	case ets:lookup(?ETS_BOSS_HP, boss_hp) of
		[] ->
			BossHpRec = #boss_hp{hp_value = BossRec#boss_rec.boss_hp},
			ets:insert(?ETS_BOSS_HP, BossHpRec),
			BossHpRec;
		[BossHpRec] ->
			BossHpRec
	end,
	?INFO(boss,"boss_hp_rec:~w",[BossHpRec]),

	BossHp1 = BossHpRec#boss_hp.hp_value - CountHurt,
	?INFO(boss,"BossHp1:~w",[BossHp1]),
	case BossHp1 =< 0 of 
		true ->
			broadcast_battle_end(0),
			BossHp = 0;
		false ->
			BossHp = BossHp1
	end,
	?INFO(boss,"battle over update boss hp :~w",[BossHp]),

	%% uodate ets_boss_hp
	ets:update_element(?ETS_BOSS_HP, boss_hp, {#boss_hp.hp_value, BossHp}),
	
	%%  update boss hp to online players
	SendList = ets:tab2list(?ETS_BOSS_DAMAGE),
	{ok, Bin} = pt_62:write(62004, BossHp),

			F = fun(Info) ->
				%%要不要check 是否在线?
					case mod_player:is_online(Info#boss_damage.id) of
						{true,_PS}->
							?INFO(boss, "player is on line, Id:~w", [Info#boss_damage.id]),
							lib_send:send_by_id(Info#boss_damage.id, Bin);
						false ->
							?INFO(boss, "player is not on  line, Id:~w",[Info#boss_damage.id]),
							skip
					end
				end,
			lists:foreach(F,  SendList),


	{noreply, State};
	

handle_info(_Info, State)->
	{noreply, State}.

terminate(_Reason, _State)->
	ok.

code_change(_OldVsn, State, _Extra)->
	{ok, State}.

init_boss_time()->
	?INFO(boss,"init boss config time"),

	{H, M, S} = erlang:time(),
	Now = H*?SECONDS_PER_HOUR + M*?SECONDS_PER_MINUTE + S,

	WaitToRegister = calc_stage_time(register, Now),
	WaitToFight    = calc_stage_time(fight, Now),
	WaitToStop     = calc_stage_time(stop, Now),
	?INFO(boss, "wait ~w seconds to register.~n", [WaitToRegister]),
	?INFO(boss, "wait ~w seconds to fight. ~n",   [WaitToFight]),
	?INFO(boss, "wait ~w seconds to stop. ~n",    [WaitToStop]),
	
	set_timer(register, WaitToRegister * 1000),
	set_timer(fight,    WaitToFight * 1000),
	set_timer(stop,     WaitToStop * 1000).

%% TimeToWait is millisecond
set_timer(TimerName, TimeToWait) ->
	cancel_timer(TimerName),
	%% use TimerName as a message
	%% we'll receive this message in handle_info/2
	
	Result = timer:send_after(TimeToWait, TimerName),
%% 	Result = timer:apply_after(TimeToWait, gen_server, cast, [self(),begin_to_battle]),
	case Result of
		{ok, TRef} -> put(TimerName, TRef);
		_ -> ok
	end.

cancel_timer(TimerName) ->
	case get(TimerName) of
		undefined -> ok;
		Ref -> timer:cancel(Ref)
	end.

init_ets()->
	ets:new(?ETS_BOSS_HP, [set, named_table, public, {keypos, #boss_hp.fkey}]),
	ets:new(?ETS_BOSS_DAMAGE, [set, named_table, public,{keypos, #boss_damage.id}]).

init_boss()->
%% 	BossRec = get_boss_rec(),
%% 	ets:insert(?ETS_BOSS_HP, #boss_hp{hp_value = BossRec#boss_rec.boss_hp}),
	ok.
 		

calc_stage_time(Stage, Now)->
	Timelist = data_boss:get_boss_time(),
	calc_stage_time(Stage, Now, Timelist).

calc_stage_time(Stage, Now, [])->
	[Time | _] = data_boss:get_boss_time(),
	StageTime = 
	case Stage of 
		register ->
			Time#boss_time.register_time;
		fight ->
			Time#boss_time.begin_time;
		stop ->
			Time#boss_time.end_time
	end,
	?SECONDS_PER_DAY + StageTime - Now;


calc_stage_time(Stage, Now, [Time|Rest])->
	if
		Now > Time#boss_time.register_time ->
			calc_stage_time(Stage, Now, Rest);
		true ->
			StageTime = 
				case Stage of
					register ->
						Time#boss_time.register_time;
					fight ->
						Time#boss_time.begin_time;
					stop ->
						Time#boss_time.end_time
				end,
			StageTime - Now
	end.

calc_wait_time(Stage, Now)->
	TimeList = data_boss:get_boss_time(),
	calc_wait_time(Stage, Now, TimeList).

calc_wait_time(Stage, Now, []) ->
	[Time | _] = data_boss:get_boss_time(),
	StageTime = 
		case Stage of
			register -> Time#boss_time.register_time;
			fight    -> Time#boss_time.begin_time;
			stop     -> Time#boss_time.end_time
		end,
	3600 * 24 - Now + StageTime;

calc_wait_time(Stage, Now, [Time | Rest]) ->	
	StageTime = 
		case Stage of
			register -> Time#boss_time.register_time;
			fight    -> Time#boss_time.begin_time;
			stop     -> Time#boss_time.end_time
		end,
	
	if (StageTime < Now) ->
		calc_wait_time(Stage, Now, Rest);
	true ->
		StageTime - Now
	end.

get_boss_time_remain(_BossID) ->
	{H, M, S} = time(),
	util:unixtime() + calc_wait_time(stop, H * 3600 + M * 60 + S).



%% broadcast to register boss battle
broadcast_battle_register() ->
	Time = get_boss_time_remain([]),
	?INFO(boss, "broadcast_battle_register, Time:~w",[Time]),

	%%打开boss场景
	set_boss_state([{is_open, true}]),

	{ok, Bin} = pt_62:write(62100, Time),
	F = fun(#ets_online{send_pid = SendPid}, _) ->
			lib_send:send(SendPid, Bin)
		end,
	ets:foldl(F, [], ?ETS_ONLINE).

%%broadcast boss dead
broadcast_battle_end(Id) ->

	case Id =:= 0 of
		true ->
			?INFO(boss, "no body kill the boss, just time over"),
			StrName = "",
			Result = {StrName, 0, 0};
		false ->
			?INFO(boss,"boss killed by Id:~w",[Id]),
			StrName = mod_account:get_player_name(Id),
			{Silver, Jungong} = data_boss:get_jisha_award(),
			Result = {StrName, Silver, Jungong}
	end,
	{ok, Bin} = pt_62:write(62005, Result),
	SendList = ets:tab2list(?ETS_BOSS_DAMAGE),
	
	BossId = data_boss:get_magic_boss_id(),
	case is_boss_alive(BossId) of
		true ->
			?INFO(boss, "boss is not dead. ignore...~n"),
			set_boss_state([{is_survival, false},{is_open, false}]),
			ok;
		false  ->
			F = fun(Info) ->
				%%要不要check 是否在线?
					case mod_player:is_online(Info#boss_damage.id) of
						{true,_PS}->
							lib_send:send_by_id(Info#boss_damage.id, Bin);
						false ->
							skip
					end
				end,
			lists:foreach(F,  SendList)
	end,

	%%45秒后强制将玩家赶出世界boss场景
	timer:apply_after(45000, ?MODULE, put_out_player, []).
	%%delete ets_boss_damage, ets_boss_hp
%% 	ets:delete_all_objects(?ETS_BOSS_DAMAGE),
%% 	ets:delete_all_objects(?ETS_BOSS_HP).
			

broadcast_battle_begin() ->
	%% set boss state is alive
	set_boss_state([{is_survival, true}]),
	%%get boss x,y
	MonsterRec = data_boss:get_boss_xy(),
	{X, Y} = {MonsterRec#monster.coord_x, MonsterRec#monster.coord_y},
	%%get boss id
	
	BossRec = get_boss_rec(),
	ets:insert(?ETS_BOSS_HP, #boss_hp{hp_value = BossRec#boss_rec.boss_hp}),
	BossId = data_boss:get_magic_boss_id(),
	%%根据配表获取幻化bossId
	BId = mod_account:get_main_role_id(BossRec#boss_rec.boss_id),
	{ok, Packet} = pt_62:write(62003, {BId, BossId, X, Y}),
	SendList = ets:tab2list(?ETS_BOSS_DAMAGE),
	?INFO(boss,"SendList:~w",[SendList]),
	F = fun(Info) ->
		%%要不要check 是否在线?
			case mod_player:is_online(Info#boss_damage.id) of
				{true,_PS}->
					?INFO(boss, "player is on line, Id:~w,Packet:~w", [Info#boss_damage.id,Packet]),
					lib_send:send_by_id(Info#boss_damage.id, Packet),
					?INFO(boss,"send ok");
				false ->
					?INFO(boss, "player is not on  line, Id:~w",[Info#boss_damage.id]),
					skip
			end
		end,
	lists:foreach(F,  SendList).


reset_boss() ->
	ok.


%% set the new state of the boss
%% using ets:update element to update the boss data
-spec set_boss_state(BossID :: integer(), StateSpec :: [tuple()]) -> ok.
set_boss_state([]) ->
	ok;

set_boss_state(SpecList) ->
	set_boss_state(SpecList, []).

set_boss_state([], UpdateList) ->
	?INFO(boss,"set boss state,UpdateList:~w",[UpdateList]),
	gen_cache:update_element(?BOSS_CACHE_REF, boss, UpdateList);

set_boss_state([{Spec, Value} | Rest], UpDataList) ->
	Elem = 
		case Spec of
			hp          -> {#boss_rec.boss_hp,     Value};
			is_survival -> {#boss_rec.is_survival,    Value};
			is_battle   -> {#boss_rec.is_battle,   Value};
			is_open     -> {#boss_rec.is_open,     Value}
%% 			level       -> {#boss.level,       Value};
%% 			queue       -> {#boss.queue,       Value};
%% 			queue_count -> {#boss.queue_count, Value}
		end,
	set_boss_state(Rest, [Elem | UpDataList]).

adjust_boss_hp() ->
    case ets:lookup(?ETS_BOSS_HP, boss_hp) of
 		[] ->
			0;
		[Rec] ->
			Rec#boss_hp.hp_value
	end.

get_boss_rec()->
	case gen_cache:lookup(?BOSS_CACHE_REF,  boss) of
		[] ->
			%%第一次的boss为战斗力第一的玩家的形象
			%%insert data: id ,nickname, hp 
			?INFO(boss,"no boss rec"),
			case mod_rank:get_combat_no1() of
				{PlayerId, _CombatPoint} ->
					NickName = mod_account:get_player_name(PlayerId),
					BossRecord = #boss_rec{boss_id = PlayerId, boss_nickname = NickName, boss_hp = 2000000};
				false ->
					BossRecord = #boss_rec{boss_id = 7000003, boss_nickname = "BOSS", boss_hp = 2000000}
			end,

			gen_cache:insert(?BOSS_CACHE_REF, BossRecord),
			BossRecord;
		[BossRecord]->
			BossRecord
	end,
	?INFO(boss,"bossrecord:~w",[BossRecord]),
	BossRecord.

is_boss_alive(BossId)->
	?INFO(boss,"bossId:~w",[BossId]),
	case get_boss_state(BossId) of
		false -> 
			false;
		{true, Boss} ->
			?INFO(boss,"boss state:~w",[Boss#boss_rec.is_survival]),
			Boss#boss_rec.is_survival
	end.


%% get boss state returns the state of the boss
-spec get_boss_state(BossID :: integer()) -> true | false.
get_boss_state(_BossID) ->
	case gen_cache:lookup(?BOSS_CACHE_REF, boss) of
%% 	case ets:lookup(?ETS_BOSS, BossID) of
		[] -> 
			?INFO(boss, "no boss"),
			false;
		[Boss] -> 
			{true, Boss}
	end.


get_boss_hp_ets()->
	[BossRec] = gen_cache:lookup(?BOSS_CACHE_REF, boss),
	?INFO(boss,"BossRec:~w",[BossRec]),
	case ets:lookup(?ETS_BOSS_HP, boss_hp) of
		[] ->
			BossHpRec = #boss_hp{hp_value = BossRec#boss_rec.boss_hp},
			ets:insert(?ETS_BOSS_HP, BossHpRec),
			BossHpRec;
		[BossHpRec] ->
			BossHpRec
	end,
	BossHpRec.

get_boss_damage_ets(Id)->
	case ets:lookup(?ETS_BOSS_DAMAGE, Id) of
		[] ->
			?INFO(boss,"my_record is none"),
			MyRec = #boss_damage{id = Id,damage_value = 0},
			ets:insert(?ETS_BOSS_DAMAGE, MyRec),
			MyRec;
		[MyRec] ->
			MyRec
	end,
	?INFO(boss,"MyRec:~w",[MyRec]),
	MyRec.

%%  update boss hp to online players
update_boss_hp_to_client(BossHp)->
	?INFO(boss, "update_boss_hp_to_client"),
	SendList = ets:tab2list(?ETS_BOSS_DAMAGE),
	{ok, Bin} = pt_62:write(62004, BossHp),

		F = fun(Info) ->
				%%要不要check 是否在线?
				case mod_player:is_online(Info#boss_damage.id) of
					{true,_PS}->
						?INFO(boss, "player is on line, Id:~w", [Info#boss_damage.id]),
						lib_send:send_by_id(Info#boss_damage.id, Bin);
					false ->
						?INFO(boss, "player is not on  line, Id:~w",[Info#boss_damage.id]),
						skip
				end
			end,
		lists:foreach(F,  SendList).

put_out_player()->
	%%获取当前boss场景中的玩家
	?INFO(boss,"boss battle is over, please players leave"),
	SendList = ets:tab2list(?ETS_BOSS_DAMAGE),
	
	F = fun(Info) ->
		%%不管在不在线都移出boss场景
		%%获取场景Id, 
		?INFO(boss,"after boss dead,Id:~w stay in boss scene ",[Info#boss_damage.id]),
		[DestSceneId] = data_boss:leave_boss_scene(),
		?INFO(boss,"after leave boss scene ,player's position:~w",[DestSceneId]),
		%%返回场景11004包
		scene:go_back(Info#boss_damage.id, DestSceneId)

	end,

	lists:foreach(F,  SendList),

	ets:delete_all_objects(?ETS_BOSS_DAMAGE),
	ets:delete_all_objects(?ETS_BOSS_HP).
