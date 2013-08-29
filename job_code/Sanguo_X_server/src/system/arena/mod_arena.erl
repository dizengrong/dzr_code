%%=======mod_arena============
%%=======2012-08-15===========
-module(mod_arena).
-behaviour(gen_server).

-include("common.hrl").
%% -include("player_record.hrl").
%% gen_server callbacks
-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2, code_change/3]).

%%API functions
-export([start_link/1,
		 get_opponent/1,       		%%获取排位信息
%% 		 initArena/1,		   		%%初始化
		 get_recent_record/1,   	%%获取近五场战况
		 challenge/2,				%%发起挑战
		 get_daily_award/2,         %%竞技场每天奖励
		 get_card_award/1 ,      	%%翻牌奖励
		 is_challenge_max/1,
		 get_heroes/2,
		 add_challenge_times/2,
		 clean_arena_battle_cd/2,
		 client_request_win_record/1,
		 send_recent_packet/2,
		 send_win_record_to_client/2,
		 arena_battle/3,
		 get_back_list/2,
		 get_daily_award_list/2
		 ]).

-define(ARENA_YILING_AWARD,0).         %%已经领取奖励
-define(ARENA_MEILING_AWARD,1).        %%没有领取奖励
-define(ARENA_REQUEST_LINGQU, 1).      %%请求领取
-define(QU_ZHENG,5).                   %%向上取整
-define(GAO_JUNGONG,1).                %%翻牌奖励高军功类型
-define(DI_JUNGONG,0).				   %%翻牌奖励低军功类型
-define(GAO_SILVER,3).            %%翻牌奖励高银币类型
-define(DI_SILVER,2).			   %%翻牌奖励低银币类型
-define(NOT_ADD_CHALLENGE_TIMES_FLAG,0). %%不购买挑战次数标志位
-define(ARENA_CD_TIME, 360).%%竞技场cd时间

get_opponent(AccountID)->          	   %%获取5位对手排位信息
	PS = mod_player:get_player_status(AccountID),
	Pid = PS#player_status.arena_pid,
	?INFO(arena,"arena_pid:~w",[Pid]),
	gen_server:cast(PS#player_status.arena_pid, {get_opponent,AccountID}).

get_recent_record(AccountID)->         %%获取近五场战况
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.arena_pid, {get_recent_record, AccountID}).

challenge(AccountID, Rank)->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.arena_pid, {challenge, AccountID, Rank}).

get_daily_award(AccountID, Typestate)->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.arena_pid, {get_daily_award, AccountID, Typestate}).

get_card_award(AccountID)->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.arena_pid, {get_card_award, AccountID}).

get_heroes(AccountID, Page)->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.arena_pid, {get_heroes, AccountID, Page}).

add_challenge_times(AccountID, Falg)->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.arena_pid, {add_challenge_times, AccountID, Falg}).

clean_arena_battle_cd(AccountID, Byte)->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.arena_pid, {clean_arena_battle_cd, AccountID, Byte}).

client_request_win_record(AccountID)->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.arena_pid, {client_request_win_record, AccountID}).

arena_battle(PS, BattleResultRec, [OpponentId]) ->
	gen_server:cast(PS#player_status.arena_pid, {battle_end, PS, BattleResultRec, OpponentId}).

start_link(AccountID)->
	?INFO(arena,"start_link,id:~w",[AccountID]),
	gen_server:start_link(?MODULE, [AccountID], []).

init([AccountID])->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, AccountID),
	mod_player:update_module_pid(AccountID, ?MODULE, self()),
	{ok, null}.

handle_call(_Request,_From, State)->
	{reply, ok, State}.

handle_cast({get_opponent, AccountID}, State)->
	?INFO(arena,"get_rank_info AccountID:~w",[AccountID]),
	%% 取自己的名次信息
	%% 取自己和自己能看到的玩家的信息
	Rank_list = gen_server:call(g_arena, {get_opponents, AccountID}),
	?INFO(arena,"rank info is ~w",[Rank_list]),
	{ok,Bin} = pt_31:write(31000,Rank_list),
	lib_send:send(AccountID, Bin),	
    {noreply, State};

handle_cast({get_recent_record, AccountID}, State)->
	?INFO(arena,"get_recent_record"),
	RecentRec = gen_server:call(g_arena, {get_recent_info, AccountID}), %%最近五场战况
	?INFO(arena,"get_recent_record:~w",[RecentRec]),
	send_recent_packet(AccountID, RecentRec),
%% 	Recent_Rec = gen_server:call(g_arena, {get_recent_info, AccountID}), %%最近五场战况
%% 	?INFO(arena,"recent_rec:~w",[Recent_Rec]),
%% 	Silver = data_arena:get_rank_award_silver(Recent_Rec#arena_rec.rank),
%% 	Jungong = data_arena:get_rank_award_jungong(Recent_Rec#arena_rec.rank),
%% 	ChallengeCount = data_arena:get_daily_challenge_times(),
%% 	EnableChallengetimes = ChallengeCount - Recent_Rec#arena_rec.challengetimes,
%% 	?INFO(arena,"EnableChallengetimes:~w",[EnableChallengetimes]),
%% 	?INFO(arena,"get recent 5 record as Recent_Rec:~w",[Recent_Rec]),
%%  	{ok,Bin} = pt_31:write(31001, {Recent_Rec#arena_rec.sustain_win,Recent_Rec#arena_rec.rank,
%% 									Recent_Rec#arena_rec.win_record,Silver,Jungong,EnableChallengetimes}),
%% 	lib_send:send(AccountID, Bin),	
    {noreply, State};

handle_cast({challenge, AccountID, Rank}, State)->
	?INFO(arena,"challenge"),
	PS = mod_player:get_player_status(AccountID),
	Pid = PS#player_status.player_pid,
	Battle_Pid = PS#player_status.battle_pid ,
	?INFO(arena,"pid:~w,batttle_pid:~w",[Pid,Battle_Pid]),
%% 	check 是否有战斗任务在进行
%% 挑战次数是否达到最大
	case mod_cool_down:getCoolDownLeftTime(AccountID, ?ARENA_CD) > 0  of
		true -> 
			mod_err:send_error(pid, AccountID, 31002, ?ERR_CD_CDING);
				false ->
					case is_challenge_max(AccountID) of
						{fail, _Amount}->
							?INFO(arena,"the max challenge count, can not challenge"),
							?ERR(todo, "the max challenge count, can not challenge");
						true ->
							%%不能挑战比自己排名低的和自己
							Rec = gen_server:call(g_arena, {get_rec, AccountID}),
							?INFO(arena,"challenge rec :~w",[Rec]),
%% 							case Rank < Rec#arena_rec.rank of
%% 								false ->
%% 									?INFO(arena,"can not challenge him or her who behind your rank"),
%% 									mod_err:send_err_by_id(AccountID, ?ERR_RANK_BEHIND);
%% 								true ->
									case Rank =:= Rec#arena_rec.rank of
										true ->
											?INFO(arena,"can not challenge himself or herself"),
											mod_err:send_err_by_id(AccountID, ?ERR_RANK_YOURSELF);
										false ->
											mod_achieve:arenaNotify(AccountID,1),
											StartupInfo = do_challenge(AccountID, Rank),
											battle:start(StartupInfo)
									end
%% 							end	
					end
	end,		

	{noreply, State};


handle_cast({get_daily_award, Id, RequestType}, State)->
	?INFO(arena,"get_daily_award"),
	%%先从data文件取出数据
	{MySilver,MyJunGong, Type,AwardList} = get_award_data(Id),
	Ret = case RequestType =:= ?ARENA_REQUEST_LINGQU of
		true ->
			case mod_counter:get_counter(Id, ?COUNTER_ARENA_WARD,?ARENA_UPDATE_TIME) >= 1 of
				true ->
					?ERR(arena, "~w cannot get more arena ward", [Id]),
					?ARENA_YILING_AWARD;
				false ->
					%%加钱，加声望
					mod_economy:add_silver(Id, MySilver, ?SILVER_FROM_ARENA_DAILY_AWARD),
					mod_economy:add_popularity(Id, MyJunGong, ?POPULARITY_FROM_ARENA_DAILY_AWARD),
					mod_counter:add_counter(Id, ?COUNTER_ARENA_WARD),
					?ARENA_YILING_AWARD
		 	end;
		false ->
			case mod_counter:get_counter(Id, ?COUNTER_ARENA_WARD,?ARENA_UPDATE_TIME) >= 1 of
				true ->
					?ARENA_YILING_AWARD;
				false ->
					?ARENA_MEILING_AWARD
			end
	end,
			
	{ok,Bin} = pt_31:write(31003,{MySilver,MyJunGong, Ret, Type,AwardList}),
	lib_send:send(Id, Bin),
	{noreply, State};

handle_cast({get_card_award, AccountID}, State)->
	?INFO(arena,"get_card_award, Id:~w",[AccountID]),
	{BackType,Sustain_Win} = gen_server:call(g_arena, {get_card_award, AccountID}),
	BackList = get_back_list(BackType, AccountID),
	%% Tyte:		类型 0低军功 1高军功2低银币3高银币
	?INFO(arena,"backlist is ~w, sustain_win is ~w",[BackList,Sustain_Win]),
	{ok,Bin} = pt_31:write(31004, {BackList,Sustain_Win}),
	lib_send:send(AccountID, Bin),		
	{noreply, State};

handle_cast({get_heroes, Id, Page}, State)->
	?INFO(arena,"Id:~w,page:~w",[Id,Page]),
	%%获取英雄榜20位玩家
	%%每页英雄榜显示个数
	Heroes_count = data_arena:get_heroes_count(),
	Heroes_per_page = data_arena:get_heroes_num_per_page(),
	Start_Rank = (Page-1)*Heroes_per_page+1,
	?INFO(arena,"start_rank:~w",[Start_Rank]),
	Heroes_list1 = gen_server:call(g_arena, {get_heroes,Id, Heroes_count}),
%% 	Heroes_list = lists:reverse(Heroes_list1),%%取的时候使用了尾插入组合成列表，所以使用取反
	Heroes_list = lists:sort(fun(Rec1,Rec2)-> Rec1#arena_rec.rank < Rec2#arena_rec.rank end, Heroes_list1),
	?INFO(arena,"Heroes_list length:~w",[length(Heroes_list)]),
	case  (length(Heroes_list)) >= Heroes_count of
		true ->
			Page_count = (Heroes_count + ?QU_ZHENG) div Heroes_per_page;%%总页数
		false ->
			Page_count = (length(Heroes_list) + ?QU_ZHENG) div Heroes_per_page
	end,
	?INFO(arena,"Page_count:~w",[Page_count]),
	%%每页返回裁剪
	Back_list = if 
		length(Heroes_list) =< Heroes_per_page ->
			Heroes_list;
		 true->
			lists:sublist(Heroes_list,  Start_Rank, Heroes_per_page)
	end,
	Length = length(Back_list),
	?INFO(arena,"backlist:~w,Length:~w",[Back_list,Length]),
	{ok,Bin} = pt_31:write(31005,{heroes,{Page_count, Page, Back_list}}),
	?INFO(arena,"bin:~w",[Bin]),
	lib_send:send(Id,Bin),

	{noreply, State};

handle_cast({add_challenge_times, Id, Flag}, State)->  %%Flag 是标志位，0表示只看tip不买,1表示买
	%%根据flag判断玩家是否要购买次数
	?INFO(arena,"add challenge times,Flag:~w",[Flag]),
	T = mod_counter:get_counter(Id, ?COUNTER_ARENA_BUY_CHALLENGE_TIMES),%%原先已购买的次数
	Goldcount = (T+1)*2,      %%购买挑战次数金币消耗
	Ret = case  Flag =:= ?NOT_ADD_CHALLENGE_TIMES_FLAG  of
			true ->
				%%不购买,计算需要的金币=(已买次数+1)*2
%% 				{false, ?ERR_UNKNOWN};	
				{true, ok};
			false ->
				%%购买
				case mod_economy:check_and_use_gold(Id, Goldcount, ?BUY_ARENA_CHALLENGE_TIMES) of
					false ->
						{false, ?ERR_NOT_ENOUGH_GOLD};
					true ->
						Reply = gen_server:call(g_arena, {add_challenge_times, Id}),
						Reply
				end
	 	end,

   case Ret of
   		{false, ErrorCode}->
			?INFO(arena,"add challenge times fail"),
			mod_err:send_err_by_id(Id, ErrorCode);
		{true, _}->
			?INFO(arena,"add challenge times success"),
			NewRec = gen_server:call(g_arena, {get_rec, Id}),
			?INFO(arena,"after add challenge times ,NewRec:~w",[NewRec]),
			skip
	end,
	{ok,Bin} = pt_31:write(31007,{add_challenge_times, Goldcount}),
	?INFO(arena,"bin:~w",[Bin]),
	lib_send:send(Id,Bin),
	{noreply, State};

handle_cast({clean_arena_battle_cd, Id, Byte}, State)->
	?INFO(arena,"client request clean cd"),

	GoldNeed0 = get_clean_battle_cd_cost(Id),
	
	case GoldNeed0 =< 0 of 
		true ->
			?INFO(arena,"no cd to clean"),
			Reply = {0, 0};
		false ->
			case Byte =:= 0 of
				true ->
					?INFO(arena,"client clean cd"),
					case mod_economy:check_and_use_bind_gold(Id, GoldNeed0, ?CLEAN_ARENA_BATTLE_CD) of
						true ->
							mod_cool_down:clearCoolDownLeftTime(Id, ?ARENA_CD),
							Reply = {0, 0};
						false ->
							mod_err:send_err_by_id(Id, ?ERR_NOT_ENOUGH_GOLD),
							LeftCdTime = mod_cool_down:getCoolDownLeftTime(Id, ?ARENA_CD),
							Reply = {LeftCdTime, GoldNeed0}
					end;
				false ->
					?INFO(arena, "client not to clean cd,just look look"),
						LeftCdTime = mod_cool_down:getCoolDownLeftTime(Id, ?ARENA_CD),
						Reply = {LeftCdTime, GoldNeed0}
			end
	end,
	{CdTime, GoldNeed} = Reply,
	{ok, Packet} = pt_31:write(31006, {CdTime, GoldNeed}),
	lib_send:send(Id, Packet),
	{noreply, State};

handle_cast({client_request_win_record, Id}, State)->
	?INFO(arena,"client_request_win_record,Id:~w",[Id]),
	AreRec = gen_server:call(g_arena, {get_rec, Id}),
	?INFO(arena,"client_request_win_record,AreRec:~w",[AreRec]),
	send_win_record_to_client(Id, AreRec),

	{noreply, State};

handle_cast({battle_end, PS, BattleResultRec, OpponentId}, State)->
	?INFO(arena,"accept arena battle result,OpponentId:~w",[OpponentId]),
	Id = PS#player_status.id,
	gen_server:cast(g_arena, {battle_end, Id, BattleResultRec, OpponentId}),
	%%这里要发3个包
	%% 发包给客户端31001
	?INFO(arena,"challenge finish, send packet to client"),
	Rec = gen_server:call(g_arena, {get_rec, Id}),
	?INFO(arena, "Rec:~w",[Rec]),
	Queue0 = Rec#arena_rec.queue,
	?INFO(arena,"Queue0:~w",[Queue0]),
	send_recent_packet(Id, Rec),
	%%发纪录包31008,被挑战者不用发，他下次登录自己会看到
	send_win_record_to_client(Id, Rec),
	Rank_list = gen_server:call(g_arena, {get_opponents, Id}),
	{ok,Bin} = pt_31:write(31000, Rank_list),
	lib_send:send(Id, Bin),

	{noreply, State};

handle_cast(finish, State)->
	{noreply, State}.

handle_info(_Info, State) ->   
    {noreply, State}.   

terminate(_Reason,_State) ->
    ok.

code_change(_OldVsn,State,_Extra) ->
    {ok, State}.


is_challenge_max(Id)->
	Rec = gen_server:call(g_arena, {get_rec, Id}), 
		case (Rec#arena_rec.challengetimes) >= ?MAX_CHALLENGE_TIMES  of
			true ->
				case util:check_other_day(Rec#arena_rec.last_battle_time) of
					false ->
						%%不是第2天，但已达到最大挑战次数
						?INFO(arena,"challengetimes:~w",[Rec#arena_rec.challengetimes]),
						{fail, Rec#arena_rec.challengetimes};
					true ->
						%%next day,reset data
						?INFO(arena,"next day, reset data"),
						NewRec = Rec#arena_rec{challengetimes = 0},
						Updaterec_list =[NewRec],
						g_arena:update_arena_rec(Updaterec_list),
						true
				end;
			false ->
				?INFO(arena,"didn't reach max challenge times"),
				true
		end.



get_award_data(Id)->
	%%获取第一名的等级
	[FirstRec] = gen_cache:lookup(?CACHE_ARENA_REC, 1),
	Level = mod_role:get_main_level(FirstRec#arena_rec.id),
	%%获取自己的等级
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
	{MySilver,MyJunGong, Type,AwardList} = get_daily_award_list(Level, Rank),

	{MySilver,MyJunGong, Type,AwardList}.

get_daily_award_list(Level, Rank) ->
	?INFO(arena,"get daily award list,level:~w",[Level]),

	FirstSilver= data_arena:get_arena_daily_silver(Level),
	FirstJunGong = trunc(1200*Level/50), %%向上取整
	
	FifthSilver  = trunc(FirstSilver*0.6),
	FifthJunGong = trunc(720*Level/50),

	SixSilver = trunc(FirstSilver*0.6*(math:pow(0.98, 6))),
	SixJunGong = trunc(720*Level/50- 1200*Level/50*0.02),
	TwentySilver = trunc(FirstSilver*0.6*(math:pow(0.98, 10))*(math:pow(0.97, 20))),
	TwentyJunGong = trunc(1200*Level/50*0.3),

	TFirstSilver =  trunc(FirstSilver*0.6*(math:pow(0.98, 10))*(math:pow(0.97, 20))*(math:pow(0.99, 21))),
	TFirstJunGong = trunc(1200*Level/50*0.3 - 1200*Level/50*0.003),
	FiftySilver = trunc(FirstSilver*0.6*(math:pow(0.98, 10))*(math:pow(0.97, 20))*(math:pow(0.99, 50))),
	FiftyJunGong = trunc(1200*Level/50*0.21),

	FFirstSilver = trunc(FirstSilver*0.6*(math:pow(0.98, 10))*(math:pow(0.97, 20))*(math:pow(0.99, 50))*(math:pow(0.99, 51))),
	FFirstJunGong = trunc(1200*Level/50*0.21 - 1200*Level/50*0.002),
	HundredSilver =trunc(FirstSilver*0.6*(math:pow(0.98, 10))*(math:pow(0.97, 20))*(math:pow(0.99, 50))*(math:pow(0.995, 100))),
	HundredJunGong = trunc(1200*Level/50*0.11),

    HFistSilver = trunc(FirstSilver*0.6*(math:pow(0.98, 10))*(math:pow(0.97, 20))
						*(math:pow(0.99, 50))*(math:pow(0.995, 100))*(math:pow(0.997, 101))),
	HFirstJunGong = trunc(1200*Level/50*0.11-1200*Level/50*0.001),
	
	FirstType = {FirstSilver, FirstJunGong, FifthSilver, FifthJunGong},
	SecType = {SixSilver, SixJunGong, TwentySilver, TwentyJunGong},
	ThType = {TFirstSilver, TFirstJunGong, FiftySilver, FiftyJunGong},
	FoType = {FFirstSilver, FFirstJunGong, HundredSilver, HundredJunGong},
	FiType = {HFistSilver, HFirstJunGong, 1000, 0},

	if 
		Rank < 1 ->
			?INFO(arena,"player is No.1, get the highest award"),
			MySilver0 = FirstSilver,
			MyJunGong0 = FirstJunGong,
			Type = 1;
		Rank >1 andalso Rank =< 5 ->
			MySilver0 = trunc((1-(Rank-1)/10)*FirstSilver),
			MyJunGong0 = trunc((1 - Rank/10) * FirstJunGong),
			Type = 1;
		Rank > 5 andalso Rank =< 10 ->
			MySilver0 =  trunc(FirstSilver*0.6*(math:pow(0.98, Rank))),
			MyJunGong0 = trunc(720*Level/50- 1200*Level/50*0.02*(Rank-5)),
			Type = 2;
		Rank > 10 andalso Rank =< 20 ->
			MySilver0 =  trunc(FirstSilver*0.6*(math:pow(0.98, 6))),
			MyJunGong0 = trunc(720*Level/50- 1200*Level/50*0.02*5 -1200*Level/50*0.01*(Rank -10)),
			Type = 2;
		Rank > 20 andalso Rank=< 50 ->
			MySilver0 = trunc(FirstSilver*0.6*(math:pow(0.98, 10))*(math:pow(0.97, 20))*(math:pow(0.99, Rank))),
			MyJunGong0 = trunc(1200*Level/50*0.3 - 1200*Level/50*0.003*(Rank-20)),
			Type = 3;
		Rank > 50 andalso Rank =< 100 ->
			MySilver0 = trunc(FirstSilver*0.6*(math:pow(0.98, 10))*(math:pow(0.97, 20))*(math:pow(0.99, 50))*(math:pow(0.99, Rank))),
			MyJunGong0 = trunc(1200*Level/50*0.21 - 1200*Level/50*0.002*(Rank-50)),
			Type = 4;
		true ->
			MySilver0 = trunc(FirstSilver*0.6*(math:pow(0.98, 10))*(math:pow(0.97, 20))
						*(math:pow(0.99, 50))*(math:pow(0.995, 100))*(math:pow(0.997, Rank))),
			MyJunGong0 = trunc(1200*Level/50*0.11-1200*Level/50*0.001),
			Type =5
	end,
	if 
		MySilver0 >1000 ->
			MySilver = MySilver0;
		true ->
			MySilver = 1000
	end,
	if
		 MyJunGong0 > 0 ->
				MyJunGong = MyJunGong0;
		true ->
				MyJunGong = 0
	end,


	{MySilver, MyJunGong, Type, [FirstType, SecType, ThType, FoType, FiType]}.

do_challenge(Id, OpponentRank)->
	?INFO(arena,"begin to challenge"),
%% 	PS = mod_player:get_player_status(AccountID),
	%%根据Rank取出对手信息，开始战斗
%% 	[SelfRec]=  ets:lookup(arena_rank, AccountID), 
%% 	Attr_info	  = gen_cache:lookup(?CACHE_ARENA_REC, SelfRank),	
	%%update challenge time
	Rec = g_arena:get_rec(Id),
	NewRec = Rec#arena_rec{last_battle_time = util:unixtime(),challengetimes = (Rec#arena_rec.challengetimes +1)},
	%%设置cd
	mod_cool_down:addCoolDownLeftTime(Id, ?ARENA_CD, ?ARENA_CD_TIME),%%
	Updaterec_list = [NewRec],
	g_arena:update_arena_rec(Updaterec_list),
	[Opponent_info] = gen_cache:lookup(?CACHE_ARENA_REC, OpponentRank),
	?INFO(arena,"Opponent_info:~w",[Opponent_info]),
	StartupInfo = 
				#battle_start {
					mod = pvp,					  
					att_id = Id,
					%% att_mer = mod_role:get_on_battle_list(Id),
%% 					def_id  = Opponent_info#arena_rec.id,
					def_mer = mod_role:get_on_battle_list(Opponent_info#arena_rec.id),
					callback = {mod_arena, arena_battle, [Opponent_info#arena_rec.id]}
				},
	 StartupInfo.


send_recent_packet(Id, RecentRec)->
	?INFO(arena,"recent_rec:~w",[RecentRec]),
	[FirstRec] = gen_cache:lookup(?CACHE_ARENA_REC, 1),
	Level = mod_role:get_main_level(FirstRec#arena_rec.id),
	Rank = RecentRec#arena_rec.rank,
	{MySilver,MyJunGong, _Type, _AwardList} = get_daily_award_list(Level, Rank),
	ChallengeCount = data_arena:get_daily_challenge_times(),
	case util:check_other_day(RecentRec#arena_rec.last_battle_time) of
		false ->
			%%不是第2天，但已达到最大挑战次数
			?INFO(arena,"already challengetimes:~w",[RecentRec#arena_rec.challengetimes]),
			EnableChallengetimes = ChallengeCount - RecentRec#arena_rec.challengetimes;
		true ->
			%%next day,reset data
			?INFO(arena,"next day, reset data,challenge times is 15"),
			NewRec = RecentRec#arena_rec{challengetimes = 0},
			UpdaterecList =[NewRec],
			g_arena:update_arena_rec(UpdaterecList),
			EnableChallengetimes = ChallengeCount
	end,
	?INFO(arena,"EnableChallengetimes:~w",[EnableChallengetimes]),
	?INFO(arena,"get recent 5 record as Recent_Rec:~w",[RecentRec]),
	CdTime = mod_cool_down:getCoolDownLeftTime(Id, ?ARENA_CD),
 	{ok,Bin} = pt_31:write(31001, {RecentRec#arena_rec.sustain_win,RecentRec#arena_rec.rank,
									RecentRec#arena_rec.win_record,MySilver,MyJunGong,EnableChallengetimes,CdTime}),
	lib_send:send(Id, Bin).



send_win_record_to_client(Id, AreRec)->
	?INFO(arena,"client_request_win_record ,Id:~w",[Id]),
	?INFO(arena,"client_request_recent_win_rec:~w",[AreRec]),
	Queue0 = AreRec#arena_rec.queue,
	?INFO(arena,"client_request_recent_win_rec queue:~w",[Queue0]),
	Queue = case Queue0  of
				{[],[]}->
					Que = queue:new(),
					Recent_rec = #recent_rec{id = Id},
					Que1 = queue:in(Recent_rec, Que),
					Que1;
				Queues ->
					Queues
			end,
	?INFO(arena,"client_request_recent_win_rec queue:~w",[Queue]),
	{ok, Packet} = pt_31:write(31008, Queue),
	lib_send:send_by_id(Id, Packet).

get_back_list(BackType, Id)->
	Role_info = mod_role:get_main_role_rec(Id),
	?INFO(arena,"role_info:~w",[Role_info]),
	Level = Role_info#role.gd_roleLevel,
	{DiJunGong,GaoJunGong,DiSilver,GaoSilver} = data_arena:get_five_battle_award(Level),
	case BackType of
	{gao_jungong,Amount}->
		Type = ?GAO_JUNGONG,   %%翻牌奖励银币类型
		mod_economy:add_popularity(Id, Amount, Type),
		List = [{Type,GaoJunGong},{?DI_SILVER,DiSilver},{?GAO_SILVER,GaoSilver},{?DI_JUNGONG,DiJunGong}],
		List;
	{di_jungong,Amount}->
		Type = ?DI_JUNGONG,	%%翻牌奖励金币类型
		mod_economy:add_popularity(Id, Amount, Type),
		List = [{Type,DiJunGong},{?DI_SILVER,DiSilver},{?GAO_SILVER,GaoSilver},{?GAO_JUNGONG,GaoJunGong}],
		List;
	{gao_silver,Amount}->
		Type = ?GAO_SILVER,	%%翻牌奖励声望类型
		mod_economy:add_silver(Id, Amount, Type),
		List = [{Type,GaoSilver},{?DI_SILVER,DiSilver},{?DI_JUNGONG,DiJunGong},{?GAO_JUNGONG,GaoJunGong}],
		List;
	{di_silver,Amount}->
		Type = ?DI_SILVER,	%%翻牌奖励历练类型
		mod_economy:add_silver(Id, Amount, Type),
		List = [{Type,DiSilver},{?GAO_SILVER,GaoSilver},{?DI_JUNGONG,DiJunGong},{?GAO_JUNGONG,GaoJunGong}],
		List
	end.

get_clean_battle_cd_cost(Id)->
	LeftCd =  mod_cool_down:getCoolDownLeftTime(Id, ?ARENA_CD),
	GoldNeed = trunc(LeftCd/60+1),
	GoldNeed.