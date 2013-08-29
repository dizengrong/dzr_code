%%% -------------------------------------------------------------------
%%% Author  : liuzhe
%%% Description : 
%%%        computer and update rank
%%%
%%% Created : 2012-9-24
%%% -------------------------------------------------------------------
-module(g_rank).

-behaviour(gen_fsm).

%% Include files
-include("common.hrl").

%% api exports
-export([start_link/0, updateDb/0, init_ets/0]).

%% gen_server callbacks
-export([init/1, handle_event/3, terminate/3, code_change/4, handle_info/3, handle_sync_event/4]).

-define(TAB_GAME_PROCESS, "AT_TopGameProcess").				%% 游戏进度
-define(TAB_KILLMONSTER, "AT_TopKillMonster").				%% 打怪排行
-define(TAB_COMBAT_POINT_TOTAL, "at_topcombatpointTotal").	%% 总战斗力排行
-define(TAB_COMBAT_POINT, "at_topcombatpoint").				%% 战斗力排行
-define(TAB_SILVER, "at_topSilver").						%% 银币排行
-define(TAB_ONLINE_TIME, "AT_TopOnlineTime").				%% 在线时长
-define(TAB_ACHIEVEMENT_POINT, "AT_TopAchievementPoint").	%% 成就排行
-define(TAB_REPUTATION, "AT_TopReputation").				%% 声望排行
-define(TAB_POPULAR_POINT, "at_toppopularity").				%% 军功排行
-define(TAB_GUILD, "AT_TopGuild").							%% 公会排行
-define(TAB_TOWER_LEVEL, "at_toptower").				%% 下水道层数排行
-define(TAB_EQUIPMENT, "AT_TopEquipment").					%% 装备排行
-define(TAB_STONE, "AT_TopStone").							%% 魂石排行
-define(TAB_RIDE_LEVEL, "AT_TopHorseLevel").				%% 坐骑排行


%% External functions
start_link() ->
	gen_fsm:start_link({local, ?MODULE}, ?MODULE, [], []).

updateDb()->
	?INFO(g_rank,"send computer and update event ,time: ~w",[{date(),time()}]),
	gen_fsm:send_event(?MODULE, update).

%% fsm action functions
waiting(timeout, _State) ->
	db_sql:execute("CALL at_Top(0);"),
	put(lastupdateTime,{date(),time()}),
	read_db(),
	WaittingTime = getNextUpdateTime(),
	?INFO(g_rank,"time to 24 have to waitting ~w s", [WaittingTime]),
	put(lastWaitTime,WaittingTime),
	{next_state, waiting, WaittingTime, WaittingTime*1000};

waiting(update, _status)->
	db_sql:execute("CALL at_Top(0);"),
	put(lastupdateTime,{date(),time()}),
	read_db(),
	WaittingTime = getNextUpdateTime(),
	?INFO(g_rank,"force update ,time to 24 have to waitting ~w s", [WaittingTime]),
	put(lastWaitTime,WaittingTime),
	{next_state, waiting, WaittingTime, WaittingTime*1000}.
	

%% Server functions

init_ets()->
	ets:new(ets_server_rankings, [named_table, set, public, {keypos, 1}, {read_concurrency, true}]).

init([]) ->
	erlang:process_flag(trap_exit, true),
	read_db(),
	WaittingTime = getNextUpdateTime(),
	?INFO(g_rank,"time to 24 have to waitting ~w s", [WaittingTime]),
	put(lastWaitTime,WaittingTime),
    {ok, waiting, WaittingTime, WaittingTime*1000}.

handle_call(_Request, _From, _State) ->
	?INFO(rankings, "Unknown message: ~w, from: ~w", [_Request, _From]),
    Reply = ok,
    {reply, Reply, _State}.

handle_cast(read_db, State) ->
	cache_util:start_update_to_db(?CACHE_RANK),
	timer:sleep(4*1000),
	db_sql:execute("CALL at_Top(0);"),
	read_db(),
	{noreply, State}.

handle_event(stop, _StateName, State) ->
	{stop, normal, State}.

handle_sync_event(_Any, _From, StateName, State) ->
	{reply, {error, unhandled}, StateName, State}.

code_change(_OldVsn, StateName, State, _Extra) ->
	{ok, StateName, State}.

handle_info(_Any, StateName, State) ->
	{next_state, StateName, State}.

terminate(_Any, _StateName, _Opts) ->
	?INFO(bulletin, "Terminating...", []),
    ok.

%%% local functions
read_db() ->
	read_db_combat_point_total(),
 	read_db_combat_point(),
	read_db_silver(),
 	read_db_online_time(),
 	read_db_achievement_point(),
	read_db_popular_point(),
	read_db_guild(),
 	read_db_tower_level(),
	ets:insert(ets_server_rankings, {last_read_db, util:unixtime()}),
	ok.

	

read_db_helper(TabName, Fields, Cond, Order, Normalizer) ->
	DBRowNormalizer = 
		case Normalizer of
			default -> 
				fun(Row) -> 
						[AccID, Name, Level, RoleID, GuildName, Val] = Row, 
						case GuildName of 
						    undefined->
								 GuildNameReal = " ";
							
							_ -> 
								 GuildNameReal = binary_to_list(GuildName)
						end,
						{AccID, binary_to_list(Name), Level, 
						 RoleID, GuildNameReal, Val} 
				end;
			_ ->
				Normalizer
		end,
	Concater = fun(Field, AccStr) ->
					   case length(AccStr) of
						   0 ->
							   Field ++ " ";
						   _ ->
							   Field ++ "," ++ AccStr
					   end
			   end,
	FieldStr = lists:foldr(Concater, "", Fields),
    SQL = 
	case Cond of
		none ->
			io_lib:format("SELECT ~s FROM ~s ORDER BY ~s ;", [FieldStr, TabName, Order]);
		_ ->
			io_lib:format("SELECT ~s FROM ~s WHERE ~s ORDER BY ~s ;", [FieldStr, TabName, Cond, Order])
	end,
	
	?INFO(rankings, "Reading DB for ~s, SQL = ~s", [TabName, SQL]),
	
	Rows = db_sql:get_all(SQL),
	lists:map(DBRowNormalizer, Rows).



read_db_combat_point_total() ->
	RankingList = read_db_helper(?TAB_COMBAT_POINT_TOTAL,
								 ["playerId", "playerName", "Level", "roleId", 
								  "guildName", "combatTotal"],
								 none, %%"gd_CareerID = " ++ integer_to_list(Career),
								 "combatTotal DESC, Level DESC, playerId LIMIT 100",
								 default),
	ets:insert(ets_server_rankings, {combat_point_total, RankingList}).

read_db_silver() ->
	RankingList = read_db_helper(?TAB_SILVER,
								 ["playerId", "playerName", "Level", "roleId", 
								  "guildName", "silver"],
								 none, %%"gd_CareerID = " ++ integer_to_list(Career),
								 "silver DESC, Level DESC, playerId LIMIT 100",
								 default),
	ets:insert(ets_server_rankings, {silver, RankingList}).

read_db_combat_point() ->
	RankingList = read_db_helper(?TAB_COMBAT_POINT,
								 ["playerId", "playerName", "Level", "roleId", 
								  "gd_GuildName", "gd_CombatPoint"],
								 none, %%"gd_CareerID = " ++ integer_to_list(Career),
								 "gd_CombatPoint DESC, Level DESC, playerId LIMIT 100",
								 default),
	ets:insert(ets_server_rankings, {combat_point, RankingList}).


read_db_online_time() ->
	RankingList = read_db_helper(?TAB_ONLINE_TIME, 
								 ["playerId", "playerName", "level", 
								  "roleId", "guildName", "onlineTime"], 
								 none,
								 "onlineTime DESC, level DESC, playerId",
								 default),
	ets:insert(ets_server_rankings, {online_time, RankingList}).

read_db_achievement_point() ->
	RankingList = read_db_helper(?TAB_ACHIEVEMENT_POINT, 
								 ["playerId", "playerName", "level", 
								  "roleId", "guildName", "achieve"], 
								 none,
								 "achieve DESC, level DESC, playerId",
								 default),
	ets:insert(ets_server_rankings, {achievement_point, RankingList}).


read_db_popular_point() ->
	RankingList = read_db_helper(?TAB_POPULAR_POINT,
								 ["playerId", "playerName", "playerLevel", 
								  "roleId", "guildName", "popularity"],
								 none,
								 "popularity DESC, playerLevel DESC, playerId",
								 default),
	ets:insert(ets_server_rankings, {popular, RankingList}).

read_db_tower_level() ->
	TowerNormalizer = fun(Row) ->
							  [PlayerId, PlayerName, Level, Combat, 
							   Tower, UpdateTime] = Row,
							  {PlayerId, binary_to_list(PlayerName), Level, Combat, Tower, UpdateTime}
					  end,
	RankingList = read_db_helper(?TAB_TOWER_LEVEL,
								 ["playerId", "playerName", "level",
								  "combat", "tower", "updateTime"],
								 none,
								 "tower DESC, updateTime",
								 TowerNormalizer),
	ets:insert(ets_server_rankings, {tower_level, RankingList}).

read_db_guild() ->
	GuildNormalizer = fun(Row) ->
							  [GuildID, GuildName, GuildLevel, HisMerit, 
							   MemberNum, MaxMemberNum] = Row,
							  {GuildID, binary_to_list(GuildName), GuildLevel, HisMerit, MemberNum, MaxMemberNum}
					  end,
	RankingList = read_db_helper(?TAB_GUILD,
								 ["gd_GuildID", "gd_GuildName", "gd_GuildLevel", "gd_HisMirit", 
								  "gd_MemberNum", "gd_MaxMemberNum"],
								 none,
								 "gd_HisMirit DESC, gd_GuildLevel DESC, gd_MemberNum DESC",
								 GuildNormalizer),
	ets:insert(ets_server_rankings, {guild, RankingList}).

getNextUpdateTime()->
	{H, M, S} = time(),
	(23-H)*3600+(59-M)*60+(56-S).

