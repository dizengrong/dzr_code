-module(g_arena).
-behavior(gen_server).

-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

-export([start_link/0,
		init_ets/0,
	 	get_wintimes/1,
		get_award/2,
		get_rec/1,
		update_ets/1,
		update_arena_rec/1,
		get_opponents/1,
		get_challenge_queue/2,
		update_arena_rec_element/1
		]).

-define(MAX_WIN_RECORD, 5).
-define(INIT_WIN_RECORD, {0,0,0,0,0}).
-define(WIN, 1).
-define(LOSE,2).
-define(Porobality,100).               %%翻牌概率和


-include("common.hrl").
start_link() ->
	gen_server:start_link({local,?MODULE},?MODULE, [], []).

%% get_award_data(Id)->
%% 	case ets:lookup(arena_rank, Id) of
%% 		{} ->
%% 			TotNum = ets:info(arena_rank, size),
%% 			Rank = TotNum + 1,
%% 			Rank;
%% 		{_Id, Rank}->
%% 			Rank
%% 	end.

%% get_rec(Id)->
%% 	ets:lookup(arena_rank, Id),
%% 	Rec = gen_cache:lookup(?CACHE_ARENA_REC, Rank),
%% 	Rec.




%% update_ets(UserId, UserRank)->
%% 	ets:update_element(arena_rank, UserId, {#rank_index.rank, UserRank}),
%% 	ok.

%% update_arena_rec(Updaterec)->
%% 	gen_cache:update_record(?CACHE_ARENA_REC, Updaterec).

%% update_arena_rec_element(Key, UpdateFields)->
%% 	gen_cache:update_element(?CACHE_ARENA_REC, Key, UpdateFields).

init_ets()->
	ets:new(arena_rank, [named_table,{keypos, #rank_index.id},public]).

init([])->
	process_flag(trap_exit, true),
	?INFO(arena,"init g_arena"),
	
	Ranklist = gen_cache:tab2list(?CACHE_ARENA_REC),
%% 	?INFO(arena,"Ranklist:~w",[Ranklist]),
	F = fun(Rec)->
			ets:insert(arena_rank, #rank_index{id = Rec#arena_rec.id, rank = Rec#arena_rec.rank})
		end,
	[F(Rec) || Rec <- Ranklist],
	{ok, null}.


handle_call({get_opponents, Id}, _From, State)->
	Reply = get_opponents(Id),
	?INFO(arena,"get opponents reply:~w",[Reply]), 
	{reply, Reply, State};

handle_call({get_recent_info, Id}, _From, State)->
	case ets:lookup(arena_rank, Id) of 
		[] -> 
		    TotNum = ets:info(arena_rank, size),
			Rank = TotNum+1,
			ets:insert(arena_rank, #rank_index{id = Id, rank = Rank}),      %%将玩家数据插入ets
			 
			NewRec = #arena_rec{id = Id,rank = Rank},
			gen_cache:insert(?CACHE_ARENA_REC, NewRec), %%将玩家数据插入数据库
			?INFO(arena,"self rank:~w",[Rank]),
			Reply = NewRec;
		[Rec]->
			[Reply] = gen_cache:lookup(?CACHE_ARENA_REC, Rec#rank_index.rank)
	end,
	?INFO(arena,"get_recent_info,Reply:~w",[Reply]),
	{reply, Reply, State};


handle_call({get_rec, Id}, _From, State)->
	Reply = get_rec(Id),
	?INFO(arena,"Reply:~w",[Reply]),
	{reply, Reply, State};

handle_call({get_award_data, Id}, _From, State)->
	case ets:lookup(arena_rank, Id) of
		[] ->
			TotNum = ets:info(arena_rank, size),
			Rank = TotNum + 1,
			Reply = Rank;
		[Rec]->
			Reply = Rec#rank_index.rank
	end,
	{reply, Reply, State};

handle_call({get_heroes, Id, Num},	_From, State)->
	?INFO(arena,"Start_Rank:~w,heroes num:~w",[Num]),
	Seq_list = lists:seq(1, Num),
	?INFO(arena,"Seqlist:~w",[Seq_list]),
	F = fun(Seq, Acc)->
		case gen_cache:lookup(?CACHE_ARENA_REC, Seq) of
				[] ->
					%%检查前20名有木有当前玩家，没有插入
					case ets:lookup(arena_rank, Id) of
						[] ->
							Rank = Seq,
							ets:insert(arena_rank, #rank_index{id = Id, rank = Rank}),     %%将玩家数据插入ets
							NewRec = #arena_rec{id = Id,rank = Rank},
							gen_cache:insert(?CACHE_ARENA_REC, NewRec), %%将玩家数据插入数据库
							[NewRec|Acc];
						[_Ret] ->
							Acc
					end;
				[Ret]->
					[Ret|Acc] 
		end
		end,
	Reply = lists:foldl(F, [], Seq_list),
	?INFO(arena,"reply:~w",[Reply]),
	{reply, Reply, State};

handle_call({get_card_award, AccountID}, _From, State)->
	Rec = get_rec(AccountID),
	?INFO(arena,"get_card_award, record:~w",[Rec]),
	if		
		length(Rec#arena_rec.win_record) < ?CHALLENGE_FIVE_TIMES ->  
%% 		length(Rec#arena_rec.win_record) < 0 -> %%%先改成0调试
			mod_err:send_err_by_id(AccountID, ?ERR_NO_FIVE_CHALLENGE_TIMES),
			Result = null;	
		true->
			Role_info = mod_role:get_main_role_rec(AccountID),
			?INFO(arena,"role_info:~w",[Role_info]),
			Level = Role_info#role.gd_roleLevel,
			BackType = get_award(Rec#arena_rec.win_record, Level),
			Result =BackType
	end,
	?INFO(arena,"get_card_award backlist:~w",[Result]),
	%%清掉之前的战斗记录
	NewRec = Rec#arena_rec{win_record={0,0,0,0,0}},
	NewRecList = [NewRec],
	update_arena_rec(NewRecList),

	Reply = {Result, NewRec#arena_rec.sustain_win},

	{reply, Reply, State};
		
handle_call({add_challenge_times, Id}, _From, State)->
	Rec = get_rec(Id),
	Max_challenge_times = data_arena:get_daily_challenge_times(),
	Reply = 
	case Rec#arena_rec.challengetimes =:= Max_challenge_times of
		true ->
			NewRec = Rec#arena_rec{challengetimes = Rec#arena_rec.challengetimes -1 },
			gen_cache:update_record(?CACHE_ARENA_REC, NewRec),
			?INFO(arena,"add challenge times,NewRec:~w",[NewRec]),
			mod_counter:add_counter(Id, ?COUNTER_ARENA_BUY_CHALLENGE_TIMES),
			{true, ok};
		false ->
			{false, ?ERR_REACH_THE_MAX_CHALLENGE_TIME}
	end,
	{reply, Reply, State};


handle_call({finish, _AccountID}, _From, State)->
	{reply, ok, State}.



handle_cast({update_ets, Updatelist}, State)->
	update_ets(Updatelist),
	{noreply, State};

handle_cast({update_arena_rec, Updaterec_list}, State)->
	update_arena_rec(Updaterec_list),
	{noreply, State};

handle_cast({battle_end, Id, BattleResultRec, OpponentId}, State) ->
	?INFO(arena,"arena challenge finish ,result Id:~w is BattleResultRec:~w",[Id, BattleResultRec]),
	?INFO(arena,"opponent_info:~w",[OpponentId]),
%% 	Id = PS#player_status.id,
	?INFO(arena, "self Id:~w",[Id]),
	SelfRec = get_rec(Id),
	OpponentInfo = get_rec(OpponentId),
	?INFO(arena,"self_rec:~w, OpponentInfo:~w",[SelfRec,OpponentInfo]),
	%%获取挑战者被挑战者姓名
	ChallengerName = mod_account:get_player_name(Id),
	ChallengedName = mod_account:get_player_name(OpponentId),
	case BattleResultRec#battle_result.is_win of
		true ->
			%% 赢的处理
			%%更新ets,DB中的排名，
			?INFO(arena, "challenge win"),
			%%如果挑战者名次已经在被挑战者前时不改变彼此名次
			case SelfRec#arena_rec.rank > OpponentInfo#arena_rec.rank of
				true ->
					?INFO(arena, "win, my rank behind opponent rank ,switch our ranks "),
					UpdateList = [{Id, OpponentInfo#arena_rec.rank},{OpponentId, SelfRec#arena_rec.rank}],
					update_ets(UpdateList),
					%%因为队列中要用所以这里先更新名次
					NewSelfRec0 = SelfRec#arena_rec{rank = OpponentInfo#arena_rec.rank,
										sustain_win = SelfRec#arena_rec.sustain_win+1
%% 										challengetimes =SelfRec#arena_rec.challengetimes+1
													},
					NewOpponentRec0 = OpponentInfo#arena_rec{rank = SelfRec#arena_rec.rank},	

					Update_rec_list0 = [NewSelfRec0, NewOpponentRec0],
					update_arena_rec(Update_rec_list0);
				false ->
					?INFO(arena, "win ,but my rank front the opponent rank ,not change our rank"),
					NewSelfRec0 = SelfRec,
					NewOpponentRec0 = OpponentInfo
			end,
			?INFO(arena,"win_record:~w",[SelfRec#arena_rec.win_record]),
			case  erlang:element(?MAX_WIN_RECORD,  SelfRec#arena_rec.win_record) =:= 0 of %%判断第5颗星是否已使用
				false ->	
					NewRecord = ?INIT_WIN_RECORD,
					WinRecord = erlang:setelement(1, NewRecord, ?WIN),
					?INFO(arena,"WinRecord:~w",[WinRecord]);
				true ->
					case mod_counter:get_counter(Id, ?COUNTER_ARENA_BUY_CHALLENGE_TIMES)=:= 0 of
						false  ->
							case (mod_counter:get_counter(Id, ?COUNTER_ARENA_BUY_CHALLENGE_TIMES)+1) rem ?MAX_WIN_RECORD =:= 0 of
								true ->
									?INFO(arena,"the five position"),
									Nth = ?MAX_WIN_RECORD;
								false ->
									Nth = (mod_counter:get_counter(Id, ?COUNTER_ARENA_BUY_CHALLENGE_TIMES)+1) rem ?MAX_WIN_RECORD
							end;
						true ->
							?INFO(arena,"win_record:~w",[SelfRec#arena_rec.win_record]),
							case (SelfRec#arena_rec.challengetimes) rem ?MAX_WIN_RECORD =:= 0 of
								true ->
									?INFO(arena,"the five position"),
									Nth = ?MAX_WIN_RECORD;
								false ->
									Nth = (SelfRec#arena_rec.challengetimes) rem ?MAX_WIN_RECORD
							end
					end,
					WinRecord = setelement(Nth,SelfRec#arena_rec.win_record, ?WIN)
			end,
			%%挑战纪录
			case SelfRec#arena_rec.rank > OpponentInfo#arena_rec.rank of
				true ->
					ChallengerRecord = #recent_rec{id = Id, challenger_name = ChallengerName, 
						challenged_name = ChallengedName,challenge_time = SelfRec#arena_rec.last_battle_time,win_rec = ?WIN,ranking=OpponentInfo#arena_rec.rank},
					ChallengedRecord = #recent_rec{id = OpponentId, challenger_name = ChallengerName, 
						challenged_name = ChallengedName,challenge_time = SelfRec#arena_rec.last_battle_time,win_rec = ?LOSE,ranking=SelfRec#arena_rec.rank},
					?INFO(arena,"ChallengerRecord:~w,ChallengedRecord:~w",[ChallengerRecord,ChallengedRecord]);
				false ->
					ChallengerRecord = #recent_rec{id = Id, challenger_name = ChallengerName, 
						challenged_name = ChallengedName,challenge_time = SelfRec#arena_rec.last_battle_time, win_rec = ?WIN},
					ChallengedRecord = #recent_rec{id = OpponentId, challenger_name = ChallengerName, 
						challenged_name = ChallengedName,challenge_time = SelfRec#arena_rec.last_battle_time, win_rec = ?LOSE},
					?INFO(arena,"ChallengerRecord:~w,ChallengedRecord:~w",[ChallengerRecord,ChallengedRecord])
			end,
			%%插入纪录队列
			SelfQueue = get_challenge_queue(NewSelfRec0, ChallengerRecord),
			OpponentQueue = get_challenge_queue(NewOpponentRec0, ChallengedRecord),
		
			NewSelfRec = NewSelfRec0#arena_rec{
										win_record = WinRecord,
										queue = SelfQueue},
			
			NewOpponentRec = NewOpponentRec0#arena_rec{queue = OpponentQueue},	
			UpdateRecList = [NewSelfRec, NewOpponentRec],
			update_arena_rec(UpdateRecList);
					
		false ->
			?INFO(arena,"challenge lose"),
			%% 输的处理
			%%更新challenge_times+1,win_record=[0,1,1,1,1]
			%%挑战纪录
			ChallengerRecord = #recent_rec{id = Id, challenger_name = ChallengerName, 
						challenged_name = ChallengedName,challenge_time = SelfRec#arena_rec.last_battle_time,win_rec = ?LOSE},
			ChallengedRecord = #recent_rec{id = OpponentId, challenger_name = ChallengerName, 
						challenged_name = ChallengedName,challenge_time = SelfRec#arena_rec.last_battle_time,win_rec = ?WIN},
			?INFO(arena,"ChallengerRecord:~w,ChallengedRecord:~w",[ChallengerRecord,ChallengedRecord]),
			%%插入纪录队列
			SelfQueue = get_challenge_queue(SelfRec, ChallengerRecord),
			OpponentQueue = get_challenge_queue(OpponentInfo, ChallengedRecord),
			?INFO(arena,"Queue:~w,Queue1:~w",[SelfQueue,OpponentQueue]),
			?INFO(arena,"win_record:~w",[SelfRec#arena_rec.win_record]),
			case  erlang:element(?MAX_WIN_RECORD,  SelfRec#arena_rec.win_record) =:= 0 of
				false ->	
					?INFO(arena,"reach the five position"),
					NewRecord = ?INIT_WIN_RECORD,
					WinRecord = erlang:setelement(1, NewRecord, ?LOSE);
				true ->
					?INFO(arena,"not reach the five position"),
					case mod_counter:get_counter(Id, ?COUNTER_ARENA_BUY_CHALLENGE_TIMES)=:= 0 of
						false  ->
							?INFO(arena,"not buy any challenge time"),
							case (mod_counter:get_counter(Id, ?COUNTER_ARENA_BUY_CHALLENGE_TIMES)+1) rem ?MAX_WIN_RECORD =:= 0 of
								true ->
									?INFO(arena,"the five position"),
									Nth = ?MAX_WIN_RECORD;
								false ->
									Nth = (mod_counter:get_counter(Id, ?COUNTER_ARENA_BUY_CHALLENGE_TIMES)+1) rem ?MAX_WIN_RECORD
							end;
							
						true ->
							?INFO(arena,"buy challenge time"),
							case (SelfRec#arena_rec.challengetimes) rem ?MAX_WIN_RECORD =:= 0 of
								true ->
									?INFO(arena,"the five position"),
									Nth = ?MAX_WIN_RECORD;
								false ->
									Nth = (SelfRec#arena_rec.challengetimes) rem ?MAX_WIN_RECORD
							end
					end,
					WinRecord = setelement(Nth,SelfRec#arena_rec.win_record, ?LOSE)
			end,
			UpdateFields = [
%% 							{#arena_rec.challengetimes, SelfRec#arena_rec.challengetimes+1},
							{#arena_rec.win_record, WinRecord},{#arena_rec.queue, SelfQueue},{#arena_rec.sustain_win,0}],
			OpponentUpdateFields = [{#arena_rec.queue,OpponentQueue}],
			UpdateFieldlist = [{SelfRec#arena_rec.rank, UpdateFields},{OpponentInfo#arena_rec.rank,OpponentUpdateFields}],
			update_arena_rec_element(UpdateFieldlist)
	end,

	{noreply, State};

handle_cast({update_arena_rec_element, UpdateFieldlist}, State)->
	update_arena_rec_element(UpdateFieldlist),
%% 	F = fun(Info)->
%% 		{Key, UpdateFields} = Info,
%% 		update_arena_rec_element(Key, UpdateFields)
%% 		end,
%% 	[F(Info) || Info <- UpdateFieldlist],
%% %% 	gen_cache:update_element(?CACHE_ARENA_REC, Key, UpdateFields),
	{noreply, State};


handle_cast(_Request, State)->
	{noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason,_State) ->
    ok.

code_change(_OldVsn,State,_Extra) ->
    {ok, State}.

get_opponent_from_record(Min, Max, Tidu)->	
	Seq_list = lists:seq(Min, Max, Tidu),   
	?INFO(arena,"seq_list:~w",[Seq_list]),                 %%排名列表
	F = fun(Seq, Acc)->
		case gen_cache:lookup(?CACHE_ARENA_REC, Seq) of
				[] ->
					Acc;
				[Ret]->
					[Ret|Acc] 
				end
		end,
	lists:foldl(F, [], Seq_list).
	%[F(Seq) || Seq<-Seq_list].

%% arena_battle(PS, BattleResultRec, [Opponent_info]) ->
%% 	gen_server:cast(g_arena, {battle_end, PS, BattleResultRec, Opponent_info}).


get_rec(Id)->
	case  ets:lookup(arena_rank, Id) of
		[]->
			?INFO(arena,"is not record"),
			TotNum = ets:info(arena_rank, size),
			Rank = TotNum+1,
			ets:insert(arena_rank, #rank_index{id = Id, rank = Rank}),      %%将玩家数据插入ets
			NewRec = #arena_rec{id = Id,rank = Rank},
			gen_cache:insert(?CACHE_ARENA_REC, NewRec), %%将玩家数据插入数据库
			Rank;
		[Rec] ->
			?INFO(arena,"have record,Rec:~w",[Rec]),
			Rank = Rec#rank_index.rank,
			Rank
	end,
	?INFO(arena,"get_rec record,rank:~w",[Rank]),
	[Reply] = gen_cache:lookup(?CACHE_ARENA_REC, Rank),
	?INFO(arena,"get_rec  gen_cache:lookup reply:~w",[Reply]),
	Reply.

update_ets(Updatelist)->
?INFO(arena,"update ets:~w",[Updatelist]),
	F = fun(Info)->
		{UserId, UserRank} = Info,
		?INFO(arena,"update ets,Info:~w",[Info]),
		ets:update_element(arena_rank, UserId, {#rank_index.rank, UserRank})
		end,
	[F(Info) || Info <- Updatelist ].
	
update_arena_rec(Updaterec_list)->
	?INFO(arena,"update arena_rec:~w",[Updaterec_list]),
	F = fun(Updaterec)->	
		gen_cache:update_record(?CACHE_ARENA_REC, Updaterec)
		end,
	[F(Updaterec) || Updaterec <- Updaterec_list].

update_arena_rec_element(Key, UpdateFields)->
	gen_cache:update_element(?CACHE_ARENA_REC, Key, UpdateFields).

get_opponents(Id)->
	?INFO(arena,"Id:~w",[Id]),
	case ets:lookup(arena_rank, Id) of
		[]->
			TotNum = ets:info(arena_rank, size),
			%% 自己是最后的名次 = 已有的人数+1 
			?INFO(arena,"Not in area yet, Totnum:~w",[TotNum]),
			Rank = TotNum+1,
			?INFO(arena,"Rank:~w",[Rank]),
			ets:insert(arena_rank, #rank_index{id = Id, rank = Rank}),      %%将玩家数据插入ets
			NewRec = #arena_rec{id = Id,rank = Rank},
			?INFO(arena, "new person enter,NewRec:~w",[NewRec]),
			gen_cache:insert(?CACHE_ARENA_REC, NewRec), %%将玩家数据插入数据库
			Rank;
		[Rec] ->
			Rank = Rec#rank_index.rank,
			?INFO(arena,"Rank:~w",[Rank]),
			Rank	
	end,
	
	if
		Rank =< 6 ->
			Tidu = 1,
			Reply = get_opponent_from_record(1, 5, Tidu);%%固定显示前5名
		Rank >6 andalso Rank =< 100 ->
			Tidu = 1,
			Reply = get_opponent_from_record(Rank-5, Rank, Tidu);
		Rank >100 andalso Rank =< 400 ->
			Tidu = 5,
			Reply = get_opponent_from_record(Rank-5*5, Rank, Tidu);
		Rank >400 andalso Rank =< 1000 ->
			Tidu = 10,
			Reply = get_opponent_from_record(Rank-5*10, Rank, Tidu);
		Rank >1000 andalso Rank =< 2000 ->
			Tidu = 25,
			Reply = get_opponent_from_record(Rank-5*25, Rank, Tidu);
		true ->
			Tidu = 100,
			Reply = get_opponent_from_record(Rank - 5*100, Rank, Tidu)
	end,
	Reply.

get_challenge_queue(Player_rec, Record)->
	?INFO(arena,"get challenge queue,player rec:~w,Record:~w",[Player_rec, Record]),
	Queue = Player_rec#arena_rec.queue,
	?INFO(arena,"get_challenge_queue:~w",[Queue]),
	Size = queue:len(Queue),
	?INFO(arena,"Queue:~w,size:~w",[Queue,Size]),
		case Size >=  ?MAX_WIN_RECORD of
			%%max size reached
			true ->
				Q1 = queue:drop(Queue),
				Q2 = queue:in(Record,Q1);
			false->
				Q2 = queue:in(Record,Queue)
		end,
	Q2.

update_arena_rec_element(UpdateFieldlist)->
	F = fun(Info)->
		{Key, UpdateFields} = Info,
		update_arena_rec_element(Key, UpdateFields)
		end,
	[F(Info) || Info <- UpdateFieldlist].
%% 	gen_cache:update_element(?CACHE_ARENA_REC, Key, UpdateFields),


get_award(_WinRecord, Level)->
	%%计算胜利次数,{1,2,1,1,2}
%% 	Acc = get_wintimes(WinRecord),
%% 	
%% 	%%just for debug
%% 	if 
%% 		Acc > 5 ->
%% 			?ERR(arena,"win record exceed 5, it's ~w",[WinRecord]),
%% 			Win_times = 5;	
%% 		true->
%% 			Win_times = Acc
%% 	end,

	random:seed(now()),
	Chance = util:rand(1, ?Porobality),
%% 	Chance = random:uniform(100),
	{DiJunGong,GaoJunGong,DiSilver,GaoSilver} = data_arena:get_five_battle_award(Level),
	?INFO(arena,"card award :levle:~w,DiJunGong,GaoJunGong,DiSilver,GaoSilver:~w",
					[Level,[DiJunGong,GaoJunGong,DiSilver,GaoSilver]]),
	if 
		Chance =< 35 ->
			Award_type = di_jungong,
			Award_amount = DiJunGong;
		Chance  >= 36 andalso Chance =< 50 ->			
			Award_type = gao_jungong,
			Award_amount = GaoJunGong;
		Chance  >= 51 andalso Chance =< 85 ->		
			Award_type = di_silver,
			Award_amount = DiSilver;
		true->
			Award_type = gao_silver,
			Award_amount = GaoSilver
	end,

	{Award_type,Award_amount}.

get_wintimes(WinRecord)->
	List = [1,2,3,4,5],
	F = fun(X, Acc)->
		case element(X,WinRecord) =:=1 of
			true ->
				Acc + 1;
			false ->
				Acc
		end
	end,
	lists:foldl(F, 0, List).
