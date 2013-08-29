%%mail:laojiajie@4399.net
-module (dungeon_rank).

-include("common.hrl").

-export([start_link/0, stop/0, init/1, handle_call/3, 
	     handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([get_rank/2,update_best_score/3,get_dungeon_rank/1]).

-define(TOP_NUM, 100).				%% 记录前多少名

-record(rank_state, {
	rank_info_list	  = []		%% 所有副本对应的排名数据: [#rank_info{}]
	}).

-record(rank_info, {
	dungeonId         = 0,
	sortList		  = []		%% 排好序的用户信息列表：[#player_rank_info{}]
	}).

-record(player_rank_info,{
	playerId 		  = 0,		
	score			  = 0,
	time			  = 0
	}).

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, data_scene:get_all_dungeon(), []).

stop() ->
	gen_server:cast(?MODULE, stop).

init(AllDungeon) ->
	RankInfoList  = init_dungeon_rank(AllDungeon, []),
	{ok, #rank_state{rank_info_list = RankInfoList}}.

init_dungeon_rank([], RankInfoList) -> RankInfoList;
init_dungeon_rank([DungeonId | Rest], RankInfoList) ->
	Sql = io_lib:format("SELECT gd_accountId, dungeonId, updateTime, score "
					  " FROM gd_dungeon WHERE dungeonId = ~w ORDER BY score DESC,updateTime LIMIT ~w ", [DungeonId, ?TOP_NUM]),
	DataList = db_sql:get_all(Sql),
	PlayerInfoList = buildPlayerInfo(DataList,[]),
	SortList = sortPlayerInfo(PlayerInfoList),
	RankInfo = #rank_info{
			dungeonId = DungeonId,
			sortList  = SortList
		},
	init_dungeon_rank(Rest, [RankInfo | RankInfoList]).

%% 把sql数据转化成用户信息record列表
buildPlayerInfo([],PlayerInfoList) -> 
	PlayerInfoList;
buildPlayerInfo([Head|Rest],PlayerInfoList) ->
	[PlayerId, _DungeonId, UpdateTime, Score] = Head,
	PlayerInfo = #player_rank_info{
			playerId = PlayerId,
			score = Score,
			time = UpdateTime
		},
	buildPlayerInfo(Rest,PlayerInfoList++[PlayerInfo]).

%% 对用户信息进行排序
sortPlayerInfo(PlayerInfoList) ->
	Fun = fun (PlayerInfo1,PlayerInfo2)->
		if  PlayerInfo1#player_rank_info.score > PlayerInfo2#player_rank_info.score ->
				true;
			PlayerInfo1#player_rank_info.score < PlayerInfo2#player_rank_info.score ->
				false;
			true ->
				PlayerInfo1#player_rank_info.time =< PlayerInfo2#player_rank_info.time
		end
	end,
	lists:sort(Fun,PlayerInfoList).

%%------------------------------------------- 获取榜上排名 -------------------------------------------------
get_rank(PlayerId,DungeonId) ->
	gen_server:call(?MODULE, {get_rank, {PlayerId,DungeonId}}).

%%--------------------------------------------  重新排名并获取新排名 ---------------------------------------------------
update_best_score(PlayerId, DungeonId, NewScore) ->
	gen_server:call(?MODULE, {update_best_score, {PlayerId,DungeonId,NewScore}}).

%%--------------------------------------------  获取某一副本的所有排名	--------------------------------------------------
get_dungeon_rank(DungeonId) ->
	gen_server:call(?MODULE, {get_dungeon_rank, {DungeonId}}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  handler  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

handle_cast(stop, State) ->
    {stop, normal, State};

handle_cast(_Request, State) ->
    {noreply,State}.

%% dungeon_rank:get_dungeon_rank(213,1400).
handle_call({get_dungeon_rank, {DungeonId}}, _From, State) ->
	RankInfoList = State#rank_state.rank_info_list,
	case lists:keyfind(DungeonId,#rank_info.dungeonId,RankInfoList) of
		false ->
			PlayerInfoList = [];
		RankInfo ->
			PlayerInfoList = RankInfo#rank_info.sortList,
			?INFO(dungeon,"PlayerInfoList = ~p",[PlayerInfoList])
	end,
	{reply,PlayerInfoList,State};

handle_call({get_rank, {PlayerId,DungeonId}},_From,State) ->
	RankInfoList = State#rank_state.rank_info_list,
	RankInfo = lists:keyfind(DungeonId,#rank_info.dungeonId,RankInfoList),
	SortList = RankInfo#rank_info.sortList,
	{List1,_List2} = lists:splitwith(fun(A)->A#player_rank_info.playerId /= PlayerId end,SortList),
	Rank1 = length(List1)+1,
	case Rank1 > ?TOP_NUM of
		true ->
			Reply = 0;
		false ->
			Reply = Rank1
	end,
	{reply,Reply,State};

handle_call({update_best_score, {PlayerId,DungeonId,NewScore}},_From,State) ->
	RankInfoList = State#rank_state.rank_info_list,
	RankInfo = lists:keyfind(DungeonId,#rank_info.dungeonId,RankInfoList),
	SortList = RankInfo#rank_info.sortList,
	case length(SortList) >= ?TOP_NUM of
		true ->
			Last = lists:last(SortList),
			case NewScore =< Last#player_rank_info.score of
				true ->
					NewState = State,
					Reply = 0;
				false ->
					SortList1 = lists:keydelete(PlayerId,#player_rank_info.playerId,SortList),
					{List1,List2} = lists:splitwith(fun(A)->A#player_rank_info.score >= NewScore end,SortList1),
					Reply= length(List1)+1,
					SortList2 = List1++[#player_rank_info{playerId = PlayerId,score = NewScore,time = util:unixtime()}]++List2,
					case length(SortList2) > ?TOP_NUM of
						true ->
							NewSortList = lists:delete(lists:last(SortList2),SortList2);
						false ->
							NewSortList = SortList2
					end,
					NewRankInfoList = lists:keyreplace(DungeonId,#rank_info.dungeonId,RankInfoList,
						#rank_info{dungeonId = DungeonId,sortList = NewSortList}),
					NewState = State#rank_state{rank_info_list = NewRankInfoList}
			end;
		false ->
			SortList1 = lists:keydelete(PlayerId,#player_rank_info.playerId,SortList),
			{List1,List2} = lists:splitwith(fun(A)->A#player_rank_info.score >= NewScore end,SortList1),
			Reply= length(List1)+1,
			SortList2 = List1++[#player_rank_info{playerId = PlayerId,score = NewScore,time = util:unixtime()}]++List2,
			NewRankInfoList = lists:keyreplace(DungeonId,#rank_info.dungeonId,RankInfoList,
						#rank_info{dungeonId = DungeonId,sortList = SortList2}),
			NewState = State#rank_state{rank_info_list = NewRankInfoList}
	end,
	{reply,Reply,NewState};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_info(stop, State) ->
    {stop, State}.

terminate(Reason, State) ->
	?INFO(player, "~w gen_server terminate, reason: ~w, state: ~w", 
		  [?MODULE, Reason, State]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.