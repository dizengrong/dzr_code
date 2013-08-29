-module(mod_boss).

-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

-include("common.hrl").

-export([start_link/1,
		 request_to_enter_boss_battle/1, %%报名参战
		 request_boss_basic_info/1,
		 boss_damage_ranking/1,
%% 		 get_boss_rec/0,
		 update_boss_hp/1,
		 player_fight_boss/1,	               	 %%打boss	
%% 		 get_boss_state/1,
%% 		 is_boss_alive/1,
		 silver_inspire/1,             %%银币鼓舞
		 gold_inspire/1,			   %%金币鼓舞
		 client_request_clean_cd/1,    %%清cd
		 boss_appear/1,
		 client_request_to_leave/1,
		 leave_boss_scene/1
		]).


start_link(AccountID)->
	gen_server:start_link(?MODULE, [AccountID], []).

request_to_enter_boss_battle(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.boss_pid, {request_to_enter_boss_battle, Id}).

request_boss_basic_info(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.boss_pid, {request_boss_basic_info, Id}).

boss_damage_ranking(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.boss_pid, {boss_damage_ranking, Id}).

boss_appear(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.boss_pid, {boss_appear, Id}).

update_boss_hp(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.boss_pid, {update_boss_hp, Id}).

player_fight_boss(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.boss_pid, {player_fight_boss, Id}).

silver_inspire(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.boss_pid, {silver_inspire, Id}).

gold_inspire(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.boss_pid, {gold_inspire, Id}).

client_request_clean_cd(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.boss_pid, {client_request_clean_cd, Id}).

client_request_to_leave(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.boss_pid, {client_request_to_leave, Id}).

leave_boss_scene(Id)->
	gen_server:cast(?MODULE, {leave_boss_scene, Id}).

init([AccountID])->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, AccountID),
	mod_player:update_module_pid(AccountID, ?MODULE, self()),
	{ok, null}.

handle_call(request, _From, State)->
	Reply = ok,
	{reply, Reply, State}.

handle_cast({request_to_enter_boss_battle, Id}, State)->
	?INFO(boss,"register_to_battle, Id:~w",[Id]),
	%%获取距离开战的时间
	%% 	Left_Time = gen_server:call(g_boss, {request_register_to_battle, Id}),
	%% 	?INFO(boss, "Left_Time:~w",[Left_Time]),
	
	%%先看看世界boss是否开放
	BossRec = gen_server:call(g_boss, {get_boss_rec, Id}),
	case BossRec#boss_rec.is_open  of
		false ->
			?INFO(boss,"boss battle is not open, please wait...."),
			mod_err:send_err_by_id(Id, ?ERR_BOSS_BATTLE_IS_NOT_OPEN);
		true ->
			?INFO(boss,"boss battle is open, please come in...."),
			%%获取boss场景Id, 
			[DestSceneId] = data_scene:get_boss_scene(),

			%%返回场景11004包
			scene:go_to(Id, DestSceneId),

			%%insert ets_boss_damage
			gen_server:cast(g_boss, {enter_boss_scene, Id})
	end,

	{noreply, State};

handle_cast({request_boss_basic_info, Id}, State)->
	?INFO(boss,"request_boss_basic_info"),
	BossRec = gen_server:call(g_boss, {get_boss_rec, Id}),
	?INFO(boss,"boss record:~w",[BossRec]),
	{ok, Packet} = pt_62:write(62001, {Id, BossRec}),
	lib_send:send_by_id(Id, Packet),

	DamageList = gen_server:call(g_boss, {get_damage_list, Id}),
	{ok, Packet0} = pt_62:write(62002, DamageList),
	lib_send:send_by_id(Id, Packet0),

 	timer:apply_after(?UPDAT_BOSS_RABKING_TIME, gen_server, cast, [self(),{boss_damage_ranking, Id}]),

	%%check is or not show boss to player
	BossId = data_boss:get_magic_boss_id(),
	case g_boss:is_boss_alive(BossId) of
		true ->
			?INFO(boss,"boss alive, show boss"),
			MonsterRec = data_boss:get_boss_xy(),
			{X, Y} = {MonsterRec#monster.coord_x, MonsterRec#monster.coord_y},
			%%get boss id
			%%根据配表获取幻化bossId
			BId = mod_account:get_main_role_id(BossRec#boss_rec.boss_id),
			{ok, Bin} = pt_62:write(62003, {BId, BossId, X, Y}),
			lib_send:send_by_id(Id, Bin);
		false ->
			?INFO(boss,"boss is not alive, please wait.."),
			skip
	end,

	case ets:lookup(?ETS_BOSS_DAMAGE, Id) of
		[] ->
			MyRec = #boss_damage{id = Id, damage_value = 0},
			ets:insert(?ETS_BOSS_DAMAGE, MyRec);
		[MyRec] ->
			MyRec
	end,
	{ok, Packet1} = pt_62:write(62009, MyRec#boss_damage.damage_value),
	lib_send:send_by_id(Id, Packet1),

	{noreply, State};

handle_cast({boss_damage_ranking, Id}, State)->
	?INFO(boss,"boss damage ranking"),
	
	DamageList = gen_server:call(g_boss, {get_damage_list, Id}),
	?INFO(boss,"DamageList:~w",[DamageList]),
	case ets:lookup(?ETS_BOSS_DAMAGE, Id) of
		[]->
			skip;
		[MyRec] ->
			case MyRec#boss_damage.state =:= 0 of
				true ->
					skip;
				false ->
					{ok, Packet} = pt_62:write(62002, DamageList),
					lib_send:send_by_id(Id, Packet)
			end
	end,

	%%定时发包
	?INFO(boss,"update boss damage ranking"),
	timer:apply_after(?UPDAT_BOSS_RABKING_TIME, gen_server, cast, [self(),{boss_damage_ranking, Id}]),

	{noreply, State};

handle_cast({boss_appear, _Id}, State)->
	?INFO(boss, "boss appear"),

	{noreply, State};

handle_cast({update_boss_hp, Id}, State)->
	?INFO(boss,"update boss hp"),

	BossHP = gen_server:call(g_boss, {get_boss_hp, Id}),
	case BossHP =:= 0 of 
		true ->
			?INFO(boss,"boss have died"),
			?ERR(todo,"tell the client");
		false ->
			{ok, Packet} = pt_62:write(62004, BossHP),
			lib_send:send_by_id(Id, Packet)
	end,
	{noreply, State};

handle_cast({player_fight_boss, Id}, State)->
	?INFO(boss, "fight_boss"),
	gen_server:cast(g_boss, {player_fight_boss, Id}),
	
	{noreply, State};

handle_cast({silver_inspire, Id}, State)->
	?INFO(boss,"silver inspire,Id:~w",[Id]),
	case mod_counter:get_counter(Id, ?INSPIRE_SUCCES) =:= 5 of
		true ->
			?INFO(boss, "can not inspire any more"),
			mod_err:send_err_by_id(Id, ?ERR_SILVER_INSPIRE_OVER);
		false ->
			Amount = data_boss:get_silver_inspire(),
			case mod_economy:check_and_use_silver(Id, Amount, ?SILVER_USE_TO_INSPIRE) of
				false ->
					?INFO(boss,"silver not enough to inspire"),
					mod_err:send_err_by_id(Id, ?ERR_NOT_ENOUGH_SILVER);
				true ->
					case is_succes_inspire() of
						nosucces ->
							?INFO(boss, "silver inspire not succes"),
							%% 返回原来的鼓舞系数
							CountInspire = mod_counter:get_counter(Id, ?INSPIRE_SUCCES);
						succes ->
							?INFO(boss,"silver inspire succes"),
							mod_counter:add_counter(Id, ?INSPIRE_SUCCES),
							%% 返回新的鼓舞系数
							CountInspire = mod_counter:get_counter(Id, ?INSPIRE_SUCCES)
					end,
					{ok, Packet} = pt_62:write(62008, CountInspire),
					lib_send:send_by_id(Id, Packet)
			end
	end,
	{noreply, State};

handle_cast({gold_inspire, Id}, State)->
	?INFO(boss,"gold inspire,Id:~w",[Id]),
	case mod_counter:get_counter(Id, ?INSPIRE_SUCCES) =:= 5 of
		true ->
			?INFO(boss, "can not inspire any more"),
			mod_err:send_err_by_id(Id, ?ERR_GOLD_INSPIRE_OVER);
		false ->
			Amount = data_boss:get_gold_inspire(),
			case mod_economy:check_and_use_gold(Id, Amount, ?GOLD_USE_TO_INSPIRE) of
				false ->
					?INFO(boss,"gold not enough to inspire"),
					mod_err:send_err_by_id(Id, ?ERR_NOT_ENOUGH_GOLD);
				true ->
					?INFO(boss,"gold inspire succes"),
					mod_counter:add_counter(Id, ?INSPIRE_SUCCES),
					%% 返回新的鼓舞系数
					CountInspire = mod_counter:get_counter(Id, ?INSPIRE_SUCCES),

					{ok, Packet} = pt_62:write(62008, CountInspire),
					lib_send:send_by_id(Id, Packet)
			end
	end,
	{noreply, State};

handle_cast({client_request_clean_cd, Id}, State)->
	?INFO(boss,"client request clean cd time"),
	Amount = data_boss:get_gold_to_clean_cd(),
	case mod_economy:check_and_use_bind_gold(Id, Amount, ?GOLD_USE_TO_CLEAN_CD) of
		false ->
			?INFO(boss,"gold not enough to clean cd"),
			mod_err:send_err_by_id(Id, ?ERR_NOT_ENOUGH_GOLD);
		true ->
			?INFO(boss, "clean cd success"),
			%% clean cd 
			mod_cool_down:clearCoolDownLeftTime(Id, ?BOSS_BATTLE_CD),
			
			%%send 0 cd to client
			{ok, Packet} = pt_62:write(62007, 0),
			lib_send:send_by_id(Id, Packet)
		
	end,
	{noreply, State};

handle_cast({client_request_to_leave, Id}, State)->
	?INFO(boss,"client requst to leave"),
	case ets:lookup(?ETS_BOSS_DAMAGE, Id) of
		[] ->
			MyRec = #boss_damage{id = Id, damage_value = 0},
			ets:insert(?ETS_BOSS_DAMAGE, MyRec);
		[MyRec] ->
			MyRec
	end,
	%% update player state
	ets:update_element(?ETS_BOSS_DAMAGE, Id, {#boss_damage.state, 0}),

	[DestSceneId] = data_scene:get_boss_scene(),
	scene:go_back(Id, DestSceneId),

	{noreply, State};

handle_cast({leave_boss_scene, Id}, State)->
	?INFO(boss, "scene module call ,player leave boss scene"),
	case ets:lookup(?ETS_BOSS_DAMAGE, Id) of
		[] ->
			MyRec = #boss_damage{id = Id, damage_value = 0},
			ets:insert(?ETS_BOSS_DAMAGE, MyRec);
		[MyRec] ->
			MyRec
	end,
	%% update player state
	ets:update_element(?ETS_BOSS_DAMAGE, Id, {#boss_damage.state, 0}),

	{noreply, State};

handle_cast(request, State)->
	{noreply, State}.

handle_info(_Info, State)->
	{noreply, State}.

terminate(_Reason, _State)->
	%%玩家断线提出boss场景
%% 	?INFO(boss,"state is player Id:~w",[State]),
%% 	[DestSceneId] = data_boss:leave_boss_scene(),
%% 
%% 	%%返回场景11004包
%% 	scene:go_back(State, DestSceneId),
	ok.

code_change(_OldVsn, State, _Extra)->
	{ok, State}.

is_succes_inspire()->
	Rand = random:uniform(100),
	[H|_] = data_boss:get_probability(),
	Result = 
	case Rand =< H of
		true ->
			nosucces;
		false ->
			succes
	end,
	Result.

