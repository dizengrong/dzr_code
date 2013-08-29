%% Author: mankiw
%% Created: 2012-9-26
%% Description: TODO: Add description to mod_rank
-module(mod_rank).

-behaviour(gen_server).
%% Include files
-include("common.hrl").

%% api export
-export([start_link/1,client_get_person_rankings/3,client_get_tower_rankings/2, client_get_dungeon_rankings/3, getAllRolesCombatPoint/1, 
		 getAllRolesCombatPointFromMemory/1, get_combat_no1/0, client_get_my_rankings/1, updateAllRank/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% api func

start_link(PlayerId) ->
	 gen_server:start_link(?MODULE, PlayerId, []).

%% Range 值 1总战斗力；2主角战斗力；3财富；4军功；5荣誉；6成就；7在线时间；8捕鱼；9竞技场；10装备；11投壶；12寻仙，13坐骑
client_get_person_rankings(PlayerId, Range, Page) ->
	PlayerStatus = mod_player:get_player_status(PlayerId),
	gen_server:cast(PlayerStatus#player_status.rank_pid, {Range, Page}).

client_get_tower_rankings(PlayerId, Page) ->
	PlayerStatus = mod_player:get_player_status(PlayerId),
	gen_server:cast(PlayerStatus#player_status.rank_pid, {tower, Page}).

client_get_dungeon_rankings(PlayerId, Range, Page) ->
	PlayerStatus = mod_player:get_player_status(PlayerId),
	gen_server:cast(PlayerStatus#player_status.rank_pid, {dungeon, Range, Page}).

client_get_my_rankings(PlayerId)->
	PlayerStatus = mod_player:get_player_status(PlayerId),
	gen_server:cast(PlayerStatus#player_status.rank_pid, selfRank).
	
get_combat_no1()->
		case ets:lookup(ets_server_rankings, combat_point) of 
			[]-> 
				?ERR(mod_rank,"global rank process not still start"),
				false;
			[{_, [No1Entry | _]}] -> 
				{PlayerId, _, _, _, _, CombatPoint} = No1Entry,
	 			{PlayerId, CombatPoint};
			_-> 
				?DEBUG(mod_rank,"main role combat rank is null"),
				false
		end.

updateRankDate(PlayerId)->
	PlayerStatus = mod_player:get_player_status(PlayerId),
	gen_server:call(PlayerStatus#player_status.rank_pid,{update, PlayerId}).
	

%% local functions
findPosition(Key, Index, List)->
	mykeyfindTh(Key, Index, List, 1).

mykeyfindTh(_Key, _Index, [], _Th)->-1;
mykeyfindTh(Key, Index, [Head|Rest], Th)->
	case Head of
		{Key, _, _, _, _, _} -> Th;
		_ -> mykeyfindTh(Key, Index, Rest, Th+1)
	end.

init(PlayerId) ->
	erlang:process_flag(trap_exit, true),
	mod_player:update_module_pid(PlayerId,?MODULE,self()),
	initTimer(PlayerId), 
    {ok, PlayerId}.

handle_call({update,PlayerId}, _From, _State) ->
	updateAllRank(PlayerId),
    Reply = ok,
    {reply, Reply, _State};

handle_call(_Request, _From, _State) ->
	?INFO(rankings, "Unknown message: ~w, from: ~w", [_Request, _From]),
    Reply = ok,
    {reply, Reply, _State}.

handle_cast(selfRank, PlayerId) ->
	RankItemList = [combat_point_total,combat_point],
	
	F = fun(RankName)->
		RankingList = 
		case ets:lookup(ets_server_rankings, RankName) of 
			[]->[];
			[{_, Rankings}] -> Rankings
		end,
		findPosition(PlayerId, 1, RankingList)
		end,
	RankThList = lists:map(F, RankItemList),
	Packet = pt_33:write(33000,RankThList),
	lib_send:send_by_id(PlayerId, Packet),
    {noreply, PlayerId};

%%总战斗力
handle_cast({1,Page}, PlayerId) ->
	RankingList = 
		case ets:lookup(ets_server_rankings, combat_point_total) of 
			[]->[];
			[{_, Rankings}] -> Rankings
		end,
	{TotalPages, CurPage, NumEntries, PageList} = 
		util:get_showlist(RankingList, Page, ?RANKINGS_ENTRIES_PER_PAGE),
    Packet = pt_33:write(33001, {2, TotalPages, CurPage, NumEntries, PageList}),
	lib_send:send_by_id(PlayerId, Packet),
    {noreply, PlayerId};

%%主角战斗力
handle_cast({2,Page}, PlayerId) ->
	RankingList = 
		case ets:lookup(ets_server_rankings, combat_point) of 
			[]->[];
			[{_, Rankings}] -> Rankings
		end,
	{TotalPages, CurPage, NumEntries, PageList} = 
		util:get_showlist(RankingList, Page, ?RANKINGS_ENTRIES_PER_PAGE),
    Packet = pt_33:write(33001, {2, TotalPages, CurPage, NumEntries, PageList}),
	lib_send:send_by_id(PlayerId, Packet),
    {noreply, PlayerId};

%%银币
handle_cast({3,Page}, PlayerId) ->
	RankingList = 
		case ets:lookup(ets_server_rankings, silver) of 
			[]->[];
			[{_, Rankings}] -> Rankings
		end,
	{TotalPages, CurPage, NumEntries, PageList} = 
		util:get_showlist(RankingList, Page, ?RANKINGS_ENTRIES_PER_PAGE),
    Packet = pt_33:write(33001, {3, TotalPages, CurPage, NumEntries, PageList}),
	lib_send:send_by_id(PlayerId, Packet),
    {noreply, PlayerId};

%%军功
handle_cast({4,Page}, PlayerId) ->
	RankingList = 
		case ets:lookup(ets_server_rankings, popular) of 
			[]->[];
			[{_, Rankings}] -> Rankings
		end,
	{TotalPages, CurPage, NumEntries, PageList} = 
		util:get_showlist(RankingList, Page, ?RANKINGS_ENTRIES_PER_PAGE),
    Packet = pt_33:write(33001, {4, TotalPages, CurPage, NumEntries, PageList}),
	lib_send:send_by_id(PlayerId, Packet),
    {noreply, PlayerId};

%%成就
handle_cast({6,Page}, PlayerId) ->
	RankingList = 
		case ets:lookup(ets_server_rankings, achievement_point) of 
			[]->[];
			[{_, Rankings}] -> Rankings
		end,
	{TotalPages, CurPage, NumEntries, PageList} = 
		util:get_showlist(RankingList, Page, ?RANKINGS_ENTRIES_PER_PAGE),
    Packet = pt_33:write(33001, {6, TotalPages, CurPage, NumEntries, PageList}),
	lib_send:send_by_id(PlayerId, Packet),
    {noreply, PlayerId};

%%现在时间
handle_cast({7,Page}, PlayerId) ->
	RankingList = 
		case ets:lookup(ets_server_rankings, online_time) of 
			[]->[];
			[{_, Rankings}] -> Rankings
		end,
	{TotalPages, CurPage, NumEntries, PageList} = 
		util:get_showlist(RankingList, Page, ?RANKINGS_ENTRIES_PER_PAGE),
    Packet = pt_33:write(33001, {7, TotalPages, CurPage, NumEntries, PageList}),
	lib_send:send_by_id(PlayerId, Packet),
    {noreply, PlayerId};

%%爬塔
handle_cast({tower,Page}, PlayerId) ->
	RankingList = 
		case ets:lookup(ets_server_rankings, tower_level) of 
			[]->[];
			[{_, Rankings}] -> Rankings
		end,
	{TotalPages, CurPage, NumEntries, PageList} = 
		util:get_showlist(RankingList, Page, ?RANKINGS_ENTRIES_PER_PAGE),
    Packet = pt_33:write(33002, {TotalPages, CurPage, NumEntries, PageList}),
	lib_send:send_by_id(PlayerId, Packet),
    {noreply, PlayerId};

%%副本
handle_cast({dungeon, DungeonId,Page}, PlayerId) ->
	DungeonList = dungeon_rank:get_dungeon_rank(DungeonId),
	{TotalPages, CurPage, NumEntries, PageList} = 
		util:get_showlist(DungeonList, Page, ?RANKINGS_ENTRIES_PER_PAGE),
    Packet = pt_33:write(33003, {DungeonId, TotalPages, CurPage, NumEntries, PageList}),
	lib_send:send_by_id(PlayerId, Packet),
    {noreply, PlayerId};


handle_cast(_Msg, _State) ->
	?INFO(rankings, "Unknown message: ~w", [_Msg]),
    {noreply, _State}.


handle_info({updateAllRank,PlayerId}, _State) ->
	updateAllRank(PlayerId),
	{noreply, _State};
	
handle_info(_Info, _State) ->
    {noreply, _State}.

terminate(_Reason, _PlayerId) ->
	timer:cancel(get(updateTimer)),
	?INFO(rankings, "terminating...."),
    ok.

code_change(_OldVsn, _State, _Extra) ->
    {ok, _State}.


initTimer(PlayerId)->
	RestTime = getTo23_59_xWaitTime(),
	{ok, UpdateTimer}    = timer:send_after(RestTime*1000,  {updateAllRank, PlayerId}),
	put(updateTimer, UpdateTimer).

updateAllRank(PlayerId)->
	MainCombatPoint = getMainRolesCombatPoint(PlayerId),
	AllComBatPoint = getAllRolesCombatPoint(PlayerId),
	AchievePoint = mod_achieve:get_point(PlayerId),
	case gen_cache:lookup(?CACHE_RANK, PlayerId) of
		[]->
			gen_cache:insert(?CACHE_RANK,#rank_status{playerId=PlayerId,mainRoleCombat=MainCombatPoint,
		    	allRolesCombat=AllComBatPoint, achievePoint=AchievePoint});
		_->
			gen_cache:update_element(?CACHE_RANK,PlayerId,[{#rank_status.mainRoleCombat,MainCombatPoint},
			    {#rank_status.allRolesCombat,AllComBatPoint},{#rank_status.achievePoint,AchievePoint}])
	end,
	RestTime = getTo23_59_xWaitTime(),
	{ok, UpdateTimer}    = timer:send_after(RestTime*1000,  {updateAllRank, PlayerId}),
	put(updateTimer, UpdateTimer).

getTo23_59_xWaitTime()->
	RandomSecond = util:rand(0,115),
	?INFO(mod_rank,"get the random update time is ~w",[{23,58,RandomSecond}]),
	{H, M, S} = time(),
	(23-H)*3600+(58-M)*60+RandomSecond-S.

getAllRolesCombatPointFromMemory(PlayerId) ->
	case gen_cache:lookup(?CACHE_RANK, PlayerId) of 
		[]->0;
		[#rank_status{allRolesCombat = AllRolesCombat}] ->
		AllRolesCombat
	end.

getMainRolesCombatPoint(PlayerId)->
	MainRoleRecord = mod_role:get_main_role_rec(PlayerId),
	role_base:calc_combat_point(MainRoleRecord).

getAllRolesCombatPoint(PlayerId)->
	RoleIdList = mod_role:get_employed_id_list(PlayerId),
	F = fun(RoleId,Sum)->
		RoleRecord = mod_role:get_role_rec(PlayerId,RoleId),
		ComBat = role_base:calc_combat_point(RoleRecord),
		(Sum +ComBat)
	end,
	lists:foldl(F, 0, RoleIdList).