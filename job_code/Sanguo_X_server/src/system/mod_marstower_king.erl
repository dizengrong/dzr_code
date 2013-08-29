%%mail:laojiajie@4399.net
%% 爬塔霸主模块
-module(mod_marstower_king).

-behaviour(gen_server).

-export([init/1,handle_info/2,handle_cast/2, handle_call/3,terminate/2, code_change/3]).
-export([start_link/0,getKingInfo/2,challenge/1,battle_complete/3,unlock/1]).

-include("common.hrl").

-define(CACHE_MARSTOWER_KING_REF, cache_util:get_register_name(marstower_king)).

-define(TIME_UNLOCK_SET,(300 * 1000)). %% 300秒

-record(state,
		{
		timer_ref1 ,
		timer_ref2 ,
		timer_ref3 ,
		timer_ref4 ,
		timer_ref5 ,
		timer_ref6 ,
		timer_ref7 ,
		timer_ref8 ,
		timer_ref9 ,
		timer_ref10 
		}).

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
	process_flag(trap_exit, true),
	initEachFloor(),
	NewState = #state{
					timer_ref1 = none, %% 计时器
					timer_ref2 = none,
					timer_ref3 = none,
					timer_ref4 = none,
					timer_ref5 = none,
					timer_ref6 = none,
					timer_ref7 = none,
					timer_ref8 = none,
					timer_ref9 = none,
					timer_ref10 = none
	},
    {ok, NewState}.

getKingInfo(AccountID,Floor) ->
	gen_server:cast(mod_marstower_king, {getKingInfo,AccountID,Floor}).

challenge(AccountID) ->
	?INFO(marstower,"Have A look"),
	gen_server:cast(mod_marstower_king,{challenge,AccountID}).

battle_complete(PS, BattleResultRec, Callback) ->
	gen_server:cast(mod_marstower_king, 
					{battle_complete, {PS#player_status.id, BattleResultRec, Callback}}).

unlock(Floor) ->
	gen_server:cast(mod_marstower_king, {unlock,Floor}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%											handler															%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 获取某一层的霸主信息，0为当前层 38006
handle_cast({getKingInfo,AccountID,Floor},State) ->
	?INFO(marstower,"Start to handle KingInfo Request"),
	case Floor =:= 0 of
		true ->
			Floor1 = mod_marstower:getCurrentFloor(AccountID),
			?INFO(marstower,"KINFINFO,***********Floor1 = ~w",[Floor1]),
			[KingRec] = gen_cache:lookup(?CACHE_MARSTOWER_KING_REF,Floor1);
		false ->
			Floor1 = Floor,
			[KingRec] = gen_cache:lookup(?CACHE_MARSTOWER_KING_REF,Floor)
	end,
	case KingRec#marstower_king.gd_IsAccount =:= 0 of
		true ->
			ID = 0,
			{MonsterID,SceneID} = data_marstower:get_leader_monster(Floor1),
			MonsterRec = data_monster:get_monster(SceneID,MonsterID),
			RoleID = MonsterRec#monster.group_id,
			Name = "aa";
		false ->
			ID = KingRec#marstower_king.gd_ID,
			AccoutRec = mod_account:get_account_info_rec(ID),
			RoleID = AccoutRec#account.gd_RoleID,
			Name = AccoutRec#account.gd_RoleName
	end,
	?INFO(marstower,"Send King INFO:Floor = ~w, ID = ~w, RoleID = ~w,Name =~w",[Floor1,ID,RoleID,Name]),
	{ok, BinData} = pt_38:write(38006,{Floor1,ID,RoleID,Name}),
	lib_send:send(AccountID,BinData),
	{noreply,State};

%% 挑战自己所在层霸主 38007
handle_cast({challenge,AccountID},State) ->
	Floor1 = mod_marstower:getCurrentFloor(AccountID),
	Level1 = mod_marstower:getCurrentLevel(AccountID),
	?INFO(marstower,"Floor1 ****************************= ~w,Level1= ~w",[Floor1,Level1]),
	case Level1 =:= 1 of
		true ->
			Floor = Floor1 -1;
		false ->
			Floor = Floor1
	end,
	?INFO(marstower,"Floor = ~w",[Floor]),
	[KingRec] = gen_cache:lookup(?CACHE_MARSTOWER_KING_REF,Floor),
	case KingRec#marstower_king.gd_Lock =:= 0 andalso getsetFloor(State,Floor) =:= none of
		false ->
			?INFO(marstower, "ErrCode = [~w]",[?ERR_KING_BUSY]),
			{ok,BinData} = pt_10:write(10999,{0,?ERR_KING_BUSY}),
			lib_send:send(AccountID,BinData);
		true ->
			case check_identity(AccountID,Floor) of
				false ->
					?INFO(marstower, "ErrCode = [~w]",[?ERR_HAVE_BEEN_KING]),
					{ok,BinData} = pt_10:write(10999,{0,?ERR_HAVE_BEEN_KING}),
					lib_send:send(AccountID,BinData);
				true ->
					?INFO(marstower, "Start challenge,Floor = ~w",[Floor]),	
					%% 上锁
					NewKingRec = KingRec#marstower_king { gd_Lock = AccountID},
					gen_cache:update_record(?CACHE_MARSTOWER_KING_REF, NewKingRec),
					case KingRec#marstower_king.gd_IsAccount =:= 0 of
						false ->
							BattleStartRec = #battle_start {
						        mod      = pvp,
						        att_id   = AccountID,
						        def_mer  = mod_role:get_on_battle_list(KingRec#marstower_king.gd_ID),
						        callback = {mod_marstower_king, battle_complete, [Floor]}
							};
						true ->
							{MonsterID,SceneID} = data_marstower:get_leader_monster(Floor),
							MonsterRec = data_monster:get_monster(SceneID,MonsterID),
							BattleStartRec = #battle_start {
						        mod      = pve,
						        att_id   = AccountID,
						        monster  = MonsterRec#monster.group_id,
						        callback = {mod_marstower_king, battle_complete, [Floor]}
							}
					end,
					%% 开启这一层的计时器
					gen_server:cast(mod_marstower_king, {unlock_after_time, Floor}),
					%% 战斗开始
					battle:start(BattleStartRec)
			end
	end,
	{noreply,State};


%% 挑战事件callback处理
handle_cast({battle_complete, {AccountID, BattleResultRec, [Floor]}},State) ->
	[KingRec] = gen_cache:lookup(?CACHE_MARSTOWER_KING_REF,Floor),
    %% 战斗校验
    case KingRec#marstower_king.gd_Lock =:= AccountID of
    	true ->
    		%% 战斗结果处理(开锁，清计时器)
    		case BattleResultRec#battle_result.is_win of
				true ->
					%% 清除旧层霸主身份
					clear(AccountID),
					%% 
					NewKingRec = KingRec#marstower_king{
											gd_IsAccount = 1,
											gd_ID = AccountID,
											gd_Lock = 0
					},
					?INFO(marstower,"Congratulation! You Win! Floor =~w",[Floor]),
					gen_cache:update_record(?CACHE_MARSTOWER_KING_REF,NewKingRec),
					{ok,BinData} = pt_38:write(38007,{1,Floor});
				false ->
					?INFO(marstower,"You Lose,Try Again!"),
					unlock(Floor),
					{ok,BinData} = pt_38:write(38007,{0,Floor})
			end,
			%% 清除计时器
			case getsetFloor(State,Floor) of
		        none -> 
		        	void;
		        TimerRef ->
		            timer:cancel(TimerRef)
		    end,
		    NewState = unsetFloor(State,Floor);
    	false ->
    		%% 这里不用unlock,因为上锁的并不是玩家，玩家的锁已经超时被计时器清理，解锁只能是上锁人和计时器
    		?INFO(marstower,"LockID is not equal to AccountID,LockID = ~w,AccountID = ~w",
    					[KingRec#marstower_king.gd_Lock, AccountID]),
    		{ok,BinData} = pt_10:write(10999,{0,?ERR_CHALLENGE_TIMEOUT}),
    		NewState = State
    end,
    lib_send:send(AccountID,BinData),
    gen_server:cast(mod_marstower_king, {getKingInfo,AccountID,Floor}),
    {noreply,NewState};


%%///////////////////////////////////////////////定时器///////////////////////////////////////////////////////

%% 定时器，战斗开始后，一段时间清除霸主上锁状态，防止一些掉线等原因导致后面的人不能挑战
handle_cast({unlock_after_time,Floor},State) ->
	case getsetFloor(State,Floor) of
        none -> 
        	void;
        TimerRef ->
            timer:cancel(TimerRef)
    end,
    NewState = setFloor(State,Floor),
    {noreply, NewState};

%% 清除某层的霸主上锁状态
handle_cast({unlock,Floor},State) ->
	[KingRec] = gen_cache:lookup(?CACHE_MARSTOWER_KING_REF,Floor),
	NewKingRec = KingRec#marstower_king { gd_Lock = 0},
	gen_cache:update_record(?CACHE_MARSTOWER_KING_REF,NewKingRec),
	case getsetFloor(State,Floor) of
        none -> 
        	void;
        TimerRef ->
            timer:cancel(TimerRef)
    end,
    NewState = unsetFloor(State,Floor),
	{noreply,NewState};

%%////////////////////////////////////////////////////////////////////////////////////////////////////////////

handle_cast(_Request, State) ->
    {noreply,State}.

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
%%										local function														%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 初始化每一层的霸主
initEachFloor() ->
	Fun = fun(A) -> 
		case gen_cache:lookup(?CACHE_MARSTOWER_KING_REF,A) of
			[KingRec] ->
				NewKingRec = KingRec#marstower_king{gd_Lock = 0},
				gen_cache:update_record(?CACHE_MARSTOWER_KING_REF,NewKingRec);
			[] ->
				{MonsterID, _SceneID} = data_marstower:get_leader_monster(A),
				NewKingRec = #marstower_king{
											gd_Floor = A,
											gd_IsAccount = 0,
											gd_ID = MonsterID,
											gd_Lock = 0
											},
				gen_cache:insert(?CACHE_MARSTOWER_KING_REF,NewKingRec)
		end
	end,
	lists:foreach(Fun,lists:seq(1,10)).

%% 设置锁上某一层的定时器
setFloor(State, Floor) ->
	case Floor of
		1 ->
			{ok, TRef} = timer:apply_after(?TIME_UNLOCK_SET, ?MODULE, unlock, [Floor]),
			NewState = State#state{timer_ref1 = TRef};
		2 ->
			{ok, TRef} = timer:apply_after(?TIME_UNLOCK_SET, ?MODULE, unlock, [Floor]),
			NewState = State#state{timer_ref2 = TRef};
		3 ->
			{ok, TRef} = timer:apply_after(?TIME_UNLOCK_SET, ?MODULE, unlock, [Floor]),
			NewState = State#state{timer_ref3 = TRef};
		4 ->
			{ok, TRef} = timer:apply_after(?TIME_UNLOCK_SET, ?MODULE, unlock, [Floor]),
			NewState = State#state{timer_ref4 = TRef};
		5 ->
			{ok, TRef} = timer:apply_after(?TIME_UNLOCK_SET, ?MODULE, unlock, [Floor]),
			NewState = State#state{timer_ref5 = TRef};
		6 ->
			{ok, TRef} = timer:apply_after(?TIME_UNLOCK_SET, ?MODULE, unlock, [Floor]),
			NewState = State#state{timer_ref6 = TRef};
		7 ->
			{ok, TRef} = timer:apply_after(?TIME_UNLOCK_SET, ?MODULE, unlock, [Floor]),
			NewState = State#state{timer_ref7 = TRef};
		8 ->
			{ok, TRef} = timer:apply_after(?TIME_UNLOCK_SET, ?MODULE, unlock, [Floor]),
			NewState = State#state{timer_ref8 = TRef};
		9 ->
			{ok, TRef} = timer:apply_after(?TIME_UNLOCK_SET, ?MODULE, unlock, [Floor]),
			NewState = State#state{timer_ref9 = TRef};
		10 ->
			{ok, TRef} = timer:apply_after(?TIME_UNLOCK_SET, ?MODULE, unlock, [Floor]),
			NewState = State#state{timer_ref10 = TRef};
		_Else ->
			NewState = State
	end,
	NewState.

%% 解除某一层的解锁定时器
unsetFloor(State, Floor) ->
	case Floor of
		1 ->
			NewState = State#state{timer_ref1 = none};
		2 ->
			NewState = State#state{timer_ref2 = none};
		3 ->
			NewState = State#state{timer_ref3 = none};
		4 ->
			NewState = State#state{timer_ref4 = none};
		5 ->
			NewState = State#state{timer_ref5 = none};
		6 ->
			NewState = State#state{timer_ref6 = none};
		7 ->
			NewState = State#state{timer_ref7 = none};
		8 ->
			NewState = State#state{timer_ref8 = none};
		9 ->
			NewState = State#state{timer_ref9 = none};
		10 ->
			NewState = State#state{timer_ref10 = none};
		_Else ->
			NewState = State
	end,
	NewState.

%% 获取某一层定时器状态
getsetFloor(State, Floor) ->
	case Floor of
		1 ->
			State#state.timer_ref1;
		2 ->
			State#state.timer_ref2;
		3 ->
			State#state.timer_ref3;
		4 ->
			State#state.timer_ref4;
		5 ->
			State#state.timer_ref5;
		6 ->
			State#state.timer_ref6;
		7 ->
			State#state.timer_ref7;
		8 ->
			State#state.timer_ref8;
		9 ->
			State#state.timer_ref9;
		10 ->
			State#state.timer_ref10;
		_Else ->
			0
	end.

check_identity(AccountID,Floor) ->
	Fun = fun(A) -> 
		case gen_cache:lookup(?CACHE_MARSTOWER_KING_REF,A) of
			[] ->
				{A,0};
			[KingRec] ->
				case KingRec#marstower_king.gd_IsAccount =:= 1 of
					true ->
						{A,KingRec#marstower_king.gd_ID};
					false ->
						{A,0}
				end
		end
	end,
	IDList = lists:map(Fun,lists:seq(1,10)),
	case lists:keytake(AccountID,2,IDList) of
		{value,{Floor1,_Value},_RestList} ->
			Floor1 < Floor;
		false ->
			true
	end.

clear(AccountID) ->
	Fun = fun(A) -> 
		case gen_cache:lookup(?CACHE_MARSTOWER_KING_REF,A) of
			[] ->
				{A,0};
			[KingRec] ->
				case KingRec#marstower_king.gd_IsAccount =:= 1 of
					true ->
						{A,KingRec#marstower_king.gd_ID};
					false ->
						{A,0}
				end
		end
	end,
	IDList = lists:map(Fun,lists:seq(1,10)),
	case lists:keytake(AccountID,2,IDList) of
		{value,{Floor,_Value},_RestList} ->
			{MonsterID, _SceneID} = data_marstower:get_leader_monster(Floor),
			NewKingRec = #marstower_king{
											gd_Floor = Floor,
											gd_IsAccount = 0,
											gd_ID = MonsterID,
											gd_Lock = 0
											},
			gen_cache:update_record(?CACHE_MARSTOWER_KING_REF,NewKingRec);
		false ->
			void
	end.