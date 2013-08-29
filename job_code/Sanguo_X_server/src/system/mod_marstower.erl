%% laojiajie@gmail.com
%% 2012-08-27
%% 爬塔模块
-module(mod_marstower).

-behaviour(gen_server).

-include("common.hrl").

-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).
-export([start_link/1]).

-export([initMarsTower/1,check_battle/2,battle_complete/3,sendMonsterList/1,getCurrentFloor/1,
	getCurrentLevel/1,getAchieveFloor/1]).

-export([gm_set_level/2]).

-define(CACHE_MARSTOWER_REF, cache_util:get_register_name(marstower)).

start_link(AccountID) ->
	gen_server:start_link(?MODULE, [AccountID], []).

%% 用户登录初始化数据
init([AccountID]) ->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, AccountID),
	mod_player:update_module_pid(AccountID, ?MODULE, self()),
    {ok, none}.

%% 创建账号时，插入一条数据
initMarsTower(AccountID) ->
	MarsTowerRec = #marstower{
					gd_AccountID     = AccountID,		%% 主键：玩家id
					gd_CurrentFloor  = 1,               %% 当前层数
					gd_CurrentLevel  = 1,				%% 当前关数（1~10）
					gd_LastTime 	 = 0,				%% 上次更新时间
					gd_ResetTimes    = ?MAX_FREE_RESET_TIMES,				%% 重置次数
					gd_Point 		 = 0,				%% 积分
					gd_AchieveLevel  = 1,       		%% 到达关数
					gd_MonsterList   = generateMonsterList(1,1),
					gd_AchieveTime	 = 0 				%% 达到最高关数的时间
					},
	gen_cache:insert(?CACHE_MARSTOWER_REF, MarsTowerRec).

%% 20100 战斗包英雄塔战斗检测
check_battle(AccountID,MonsterId) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.marstower_pid,{check_battle,{AccountID,MonsterId}}).

%% 战斗结束后，mod_player函数调回
battle_complete(PS, BattleResultRec, Callback) ->
	gen_server:cast(PS#player_status.marstower_pid, 
					{battle_complete, {PS#player_status.id, BattleResultRec, Callback}}).


%% 在场景模块玩家进入视野包之后，如果地图是英雄塔，则调用这一函数
sendMonsterList(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.marstower_pid,{sendMonsterList,AccountID}).

%% GM命令，设置当前到第n层
gm_set_level(AccountID,Level) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.marstower_pid,{gm_set_level,AccountID,Level}).

getCurrentFloor(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.marstower_pid,{getCurrentFloor,AccountID}).

getCurrentLevel(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.marstower_pid,{getCurrentLevel,AccountID}).

getAchieveFloor(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.marstower_pid,{getAchieveFloor,AccountID}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%											 	handler 													   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 获取用户当前关数，已到达关数 38000
handle_cast({getInfo,AccountID},State) ->
	[MarsTowerRec] = gen_cache:lookup(?CACHE_MARSTOWER_REF,AccountID),
	?INFO(marstower,"MarsTowerRec = ~w",[MarsTowerRec]),
	Floor = MarsTowerRec#marstower.gd_CurrentFloor,
	Level = MarsTowerRec#marstower.gd_CurrentLevel,
	AchieveLevel = MarsTowerRec#marstower.gd_AchieveLevel,
	AchieveFloor = (AchieveLevel-1) div 10 + 1,
	case util:check_other_day(MarsTowerRec#marstower.gd_LastTime) of 
		false ->
			TranslateLevel = (Floor -1)*10+Level,
			{ok,BinData} = pt_38:write(38000,{TranslateLevel,AchieveLevel}),
			?INFO(marstower,"MarsTower INFO SEND, TranslateLevel:~w, AchieveLevel:~w",
				[TranslateLevel,AchieveLevel]);
		true ->  %% 每天12点自动重置
			case AchieveFloor > 1 of
				true ->
					NewFloor = AchieveFloor -1;
				false ->
					NewFloor = 1
			end,
			NewLevel = 1,
			NewRestTimes = ?MAX_FREE_RESET_TIMES,
			NewMarsTowerRec = MarsTowerRec#marstower{gd_CurrentFloor = NewFloor,
													gd_CurrentLevel = NewLevel,
													gd_ResetTimes=NewRestTimes,
													gd_LastTime = util:unixtime(),
													gd_MonsterList = generateMonsterList(NewFloor,NewLevel)},
			gen_cache:update_record(?CACHE_MARSTOWER_REF, NewMarsTowerRec),
			TranslateLevel = (NewFloor - 1)*10 + NewLevel,
			{ok,BinData} = pt_38:write(38000,{TranslateLevel,AchieveLevel}),
			?INFO(marstower,"MarsTower RESET INFO SEND, TranslateLevel:~w, AchieveLevel:~w",
				[TranslateLevel,AchieveLevel])
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 重置回上一层第一关（每天有一次金币重置机会）38008
handle_cast({reset,AccountID},State) ->
	[MarsTowerRec] = gen_cache:lookup(?CACHE_MARSTOWER_REF,AccountID),
	AchieveLevel = MarsTowerRec#marstower.gd_AchieveLevel,
	AchieveFloor = (AchieveLevel-1) div 10 + 1,
	ResetTimes = MarsTowerRec#marstower.gd_ResetTimes,
	GoldCost = 20,
	case ResetTimes>0 of
		true ->
			case mod_economy:check_and_use_bind_gold(AccountID, GoldCost, ?GOLD_RESET_TOWER) of
				false ->
					?INFO(marstower, "ErrCode = [~w]",[?ERR_NOT_ENOUGH_GOLD]),
					{ok,BinData} = pt_10:write(10999,{0,?ERR_NOT_ENOUGH_GOLD});
				true ->
					case AchieveFloor > 1 of
						true ->
							NewFloor = AchieveFloor -1;
						false ->
							NewFloor = 1
					end,
					NewLevel = 1,
					NewRestTimes = ResetTimes - 1,
					NewMarsTowerRec = MarsTowerRec#marstower{gd_CurrentFloor = NewFloor,
															gd_CurrentLevel = NewLevel,
															gd_ResetTimes=NewRestTimes,
															gd_MonsterList = generateMonsterList(NewFloor,NewLevel)},
					gen_cache:update_record(?CACHE_MARSTOWER_REF, NewMarsTowerRec),
					TranslateLevel = (NewFloor - 1)*10 + NewLevel,
					{ok,BinData} = pt_38:write(38000,{TranslateLevel,AchieveLevel}),
					?INFO(marstower,"MarsTower INFO SEND, TranslateLevel:~w, AchieveLevel:~w",
						[TranslateLevel,AchieveLevel])
			end;
		false ->
			?INFO(marstower, "ErrCode = [~w]",[?ERR_RESET_TIMES_ZERO]),
			{ok,BinData} = pt_10:write(10999,{0,?ERR_RESET_TIMES_ZERO})
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 入塔/进入传送阵（传送至塔内地图）38001
handle_cast({enterCircle,AccountID},State) ->
	[MarsTowerRec] = gen_cache:lookup(?CACHE_MARSTOWER_REF,AccountID),
	TanslateLevel = (MarsTowerRec#marstower.gd_CurrentFloor - 1)*10 +MarsTowerRec#marstower.gd_CurrentLevel,
	{_MonsterId,_Rate,MapID}= data_marstower:get_level_monster(TanslateLevel),
	scene:go_to(AccountID, MapID),
	{noreply,State};

%% 发送怪物
handle_cast({sendMonsterList,AccountID},State)->
	[MarsTowerRec] = gen_cache:lookup(?CACHE_MARSTOWER_REF,AccountID),
	MonsterList = MarsTowerRec#marstower.gd_MonsterList,
	?INFO(marstower,"*********HAVE A LOOK!,MonsterList IS ~w",[MonsterList]),
	{ok,BinData1} = pt_11:write(11405,MonsterList),
	{ok,BinData2} = pt_11:write(11400,MonsterList),
	?INFO(marstower,"11405 send_data:[~w]", [BinData1]),
	lib_send:send(AccountID,<<BinData1/binary,BinData2/binary>>),
	{noreply,State};

%% 战斗处理
handle_cast({battle_complete, {AccountID, BattleResultRec, [MonsterId]}},State) ->
	[MarsTowerRec] = gen_cache:lookup(?CACHE_MARSTOWER_REF,AccountID),
	MonsterList = MarsTowerRec#marstower.gd_MonsterList,
	case BattleResultRec#battle_result.is_win of
		true ->
			NewMonsterList = lists:keydelete(MonsterId,#monster.id,MonsterList),
			?INFO(marstower,"^^^^^^^^^^^^^^^NewMonsterList = ~w,Delete ID = ~w",[NewMonsterList,MonsterId]),
			case NewMonsterList of
				[] ->
					Level = MarsTowerRec#marstower.gd_CurrentLevel,
					Floor = MarsTowerRec#marstower.gd_CurrentFloor,
					case Level >= 10 of
						true ->
							NewLevel = 1,
							case Floor =:= 10 of
								false ->
									NewFloor = Floor+1;
								true ->
									NewFloor = 1
							end,
							mod_achieve:marstowerNotify(AccountID,Floor);
						false ->
							NewLevel = Level+1,
							NewFloor = Floor
					end,
					%% 任务通知
					mod_task:updata_marstower_task(AccountID,Level,1),
					TranslateLevel = (NewFloor -1)*10 +NewLevel,
					NewAchieveLevel = util:max(MarsTowerRec#marstower.gd_AchieveLevel,TranslateLevel),
					NewMarsTowerRec = MarsTowerRec#marstower{gd_CurrentFloor = NewFloor,
															gd_CurrentLevel = NewLevel,
															gd_AchieveLevel = NewAchieveLevel,
															gd_AchieveTime = util:unixtime(),
															gd_MonsterList = generateMonsterList(NewFloor,NewLevel)},
					gen_server:cast(self(),{openCircle,{AccountID,TranslateLevel -1}});
				_NotNull ->
					NewMarsTowerRec = MarsTowerRec#marstower{gd_MonsterList = NewMonsterList}
			end,
			gen_cache:update_record(?CACHE_MARSTOWER_REF, NewMarsTowerRec),
			%% 怪物移除视野包
			{ok,BinData} = pt_11:write(11402, [MonsterId]),
			?INFO(marstower,"*******Mnoster Delete!send_data:[~w]", [BinData]),
			lib_send:send(AccountID,BinData);
		false ->
			void
	end,
	{noreply,State};


%% 开启传送阵 
handle_cast({openCircle,{AccountID,TranslateLevel}},State) ->
	?INFO(marstower,"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^OPRN CIRCLE!"),
	{ok,BinData} = pt_38:write(38002,TranslateLevel),
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 获取积分 38003
handle_cast({getPoint,AccountID},State) ->
	[MarsTowerRec] = gen_cache:lookup(?CACHE_MARSTOWER_REF,AccountID),
	Point = MarsTowerRec#marstower.gd_Point,
	{ok,BinData} = pt_38:write(38003,Point),
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 兑换积分 38004
handle_cast({changePoint,AccountID,ItemIDList},State) ->
	[MarsTowerRec] = gen_cache:lookup(?CACHE_MARSTOWER_REF,AccountID),
	PointAdd = checkItems(AccountID,ItemIDList),
	Point = MarsTowerRec#marstower.gd_Point + PointAdd,
	NewMarsTowerRec = MarsTowerRec#marstower{gd_Point = Point},
	gen_cache:update_record(?CACHE_MARSTOWER_REF, NewMarsTowerRec),
	{ok,BinData} = pt_38:write(38003,Point),
	lib_send:send(AccountID,BinData),
	{noreply,State};


%% 购买技能书 38004
handle_cast({buyBook,AccountID,BookID,Num},State) ->
	[MarsTowerRec] = gen_cache:lookup(?CACHE_MARSTOWER_REF,AccountID),
	Point = MarsTowerRec#marstower.gd_Point,
	AchieveLevel = MarsTowerRec#marstower.gd_AchieveLevel,
	AchieveFloor = (AchieveLevel-1) div 10 + 1,
	{BuyFloor,NeedPoint1} = data_marstower:get_buy_point(BookID),
	NeedPoint = NeedPoint1*Num,
	case AchieveFloor >= BuyFloor of
		true ->
			case Point >= NeedPoint of
				true ->
					case mod_items:getBagNullNum(AccountID) > 0 of
						true ->
							?INFO(marstower,"Buy SkillBook Succesfull!"),
							NewPoint = Point - NeedPoint,
							NewMarsTowerRec = MarsTowerRec#marstower{gd_Point = NewPoint},
							gen_cache:update_record(?CACHE_MARSTOWER_REF, NewMarsTowerRec),
							{ok,BinData} = pt_38:write(38003,NewPoint),
							mod_items:createItems(AccountID, [{BookID,Num,1}], ?ITEM_FROM_MARSTOWER);
						false ->
							?INFO(marstower,"Not Enought BagPos"),
							{ok,BinData} = pt_10:write(10999,{0,?ERR_ITEM_BAG_NOT_ENOUGH})
					end;
				false ->
					?INFO(marstower,"Not Enought Point,Point = ~w,Need Point = ~w",[Point,NeedPoint]),
					{ok,BinData} = pt_10:write(10999,{0,?ERR_NOTENOUGHT_POINT})
			end;
		false ->
			?INFO(marstower,"AchieveFloor Not Enought To Buy! AchieveFloor =~w",[AchieveFloor]),
			{ok,BinData} = pt_10:write(10999,{0,?ERR_ACHIEVE_FLOOR_NOTENOUGHT})
	end,
	lib_send:send(AccountID,BinData),
	{noreply,State};



% % %% 挑战守关将领(要排队，set lock)
% % handle_cast({battleChief,AccountID},State) ->

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                          			GM命令处理														 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
handle_cast({gm_set_level,AccountID,Level},State) ->
	[MarsTowerRec] = gen_cache:lookup(?CACHE_MARSTOWER_REF,AccountID),
	AchieveLevel = MarsTowerRec#marstower.gd_AchieveLevel,
	NewLevel = (Level-1) rem 10 + 1,
	NewFloor = (Level-1) div 10 + 1,
	NewAchieveLevel = util:max(AchieveLevel,Level),
	NewMarsTowerRec = MarsTowerRec#marstower{gd_CurrentFloor = NewFloor,
											gd_CurrentLevel = NewLevel,
											gd_AchieveLevel = NewAchieveLevel,
											gd_AchieveTime = util:unixtime(),
											gd_MonsterList = generateMonsterList(NewFloor,NewLevel)},
	gen_cache:update_record(?CACHE_MARSTOWER_REF, NewMarsTowerRec),
	TranslateLevel = (NewFloor - 1)*10 + NewLevel,
	{ok,BinData} = pt_38:write(38000,{TranslateLevel,NewAchieveLevel}),
	?INFO(marstower,"MarsTower INFO SEND, TranslateLevel:~w, AchieveLevel:~w",
	[TranslateLevel,NewAchieveLevel]),
	lib_send:send(AccountID,BinData),
	{noreply,State};

handle_cast(_Request, State) ->
    {noreply,State}.

%% 战斗检查
handle_call({check_battle,{AccountID,MonsterId}},_From,State) ->
	[MarsTowerRec] = gen_cache:lookup(?CACHE_MARSTOWER_REF,AccountID),
	MonsterList = MarsTowerRec#marstower.gd_MonsterList,
	MonsterIdList = lists:map(fun(MonsterInfo) ->MonsterInfo#monster.id end,MonsterList),
	Reply = lists:member(MonsterId,MonsterIdList),
	{reply,Reply,State};

handle_call({getCurrentFloor,AccountID},_From,State) ->
	[MarsTowerRec] = gen_cache:lookup(?CACHE_MARSTOWER_REF,AccountID),
	Floor = MarsTowerRec#marstower.gd_CurrentFloor,
	Reply = Floor,
	{reply,Reply,State};

handle_call({getCurrentLevel,AccountID},_From,State) ->
	[MarsTowerRec] = gen_cache:lookup(?CACHE_MARSTOWER_REF,AccountID),
	Level = MarsTowerRec#marstower.gd_CurrentLevel,
	Reply = Level,
	{reply,Reply,State};

handle_call({getAchieveFloor,AccountID},_From,State) ->
	[MarsTowerRec] = gen_cache:lookup(?CACHE_MARSTOWER_REF,AccountID),
	AchieveLevel = MarsTowerRec#marstower.gd_AchieveLevel,
	Reply = (AchieveLevel-1) div 10 + 1,
	{reply,Reply,State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%											Local Function													%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 根据当前关数生成怪物列表([{ID,X坐标,Y坐标}])
generateMonsterList(Floor,Level) ->
	TranslateLevel = (Floor -1)*10 +Level,
	{MonsterID1,Rate,MapID1} = data_marstower:get_level_monster(TranslateLevel),
	{MonsterID2,MapID2} = data_marstower:get_random_monster(Floor),
	Monster1 = data_monster:get_monster(MapID1,MonsterID1),
	Monster2 = data_monster:get_monster(MapID2,MonsterID2),
	case util:rand(1,100) < Rate of
		true ->
			[Monster1,Monster2];
		false ->
			[Monster1]
	end.

%% 检查客户端传过来的物品列表是否可兑换积分
checkItems(AccountID,ItemIDList) ->
	Fun = fun(ItemID,Point) ->
		Item = cache_items:getItemByWorldID(AccountID, ItemID),
		CfgItemID = Item#item.cfg_ItemID,
		CfgItem = data_items:get(CfgItemID),
		case CfgItem#cfg_item.cfg_FirstType =:= 3 andalso CfgItem#cfg_item.cfg_SecondType =:= 10 of
			true ->
				AddPoint = data_marstower:get_item_point(CfgItemID),
				Point + AddPoint
		end
	end,
	PointSumAdd = lists:foldl(Fun,0,ItemIDList),
	%% 由于不是3,10的物品上面会直接断掉，所以不用另外判断
	mod_items:throwByWorldIDList(AccountID,1,ItemIDList),
	PointSumAdd.