-module(sg_networking).
-export([start/1]).

-include("common.hrl").
%% -include("ets_sql_map.hrl").

start({Port}) ->
	ok = start_rand(),
	
	ok = init_mysql(),
	ok = init_user_log_mysql(),

	ok = start_user_log(),
	ok = start_uid_server(),

	
	init_gen_cache(),
	
	%%init data
	mod_account:init_global_name_table(),
	mod_player:init_ets(),
	scene_man:init_scene(),
	mod_team:init_team_ets(),
	g_arena:init_ets(),
    g_rank:init_ets(),
	
	start_dungeon_rank(),
	start_slave_timer(),
	start_slave_mirror(),
	
	?INFO(monster,"start moster manage process"),
 	ok = start_monster(),
		
	?INFO(guild, "starting guild manager"),
	start_guild(),
	
	?INFO(mail,"start mail manage process"),
	ok = start_mail(),

	ok = start_client(),
	ok = start_tcp(Port),
	
	ok = start_g_arena(),

	ok = start_marstower_king(),
	
	ok = start_g_yunbiao(),

	ok = start_g_boss(),

	%% 排行榜
	ok = start_rank_mod(),

	ok = start_statistics(),
	
	ok = start_g_bulletin(),
	
	ok = g_bulletin_queue(),

	ok.

%% start g_bulletin_queue
g_bulletin_queue()->
	{ok, _} = sg_sup:start_link(sup_bulletin_queue),
    {ok,_} = supervisor:start_child(
               sup_bulletin_queue,
               {g_bulletin_queue,
                {g_bulletin_queue, start_link,[]},
                permanent, 10000, worker, [g_bulletin_queue]}),
	ok.

%% start bulletin
start_g_bulletin()->
	{ok, _} = sg_sup:start_link(sup_bulletin),
    {ok,_} = supervisor:start_child(
               sup_bulletin,
               {g_bulletin,
                {g_bulletin, start_link,[]},
                permanent, 10000, worker, [g_bulletin]}),
	ok.

%% start rank
start_rank_mod()->
	{ok, _} = sg_sup:start_link(sup_rank),
    {ok,_} = supervisor:start_child(
               sup_rank,
               {g_rank,
                {g_rank, start_link,[]},
                permanent, 10000, worker, [g_rank]}),
	ok.

%%random seed
start_rand() ->
	{ok, _} = sg_sup:start_link(sup_rand),
    {ok,_} = supervisor:start_child(
               sup_rand,
               {mod_rand,
                {mod_rand, start_link,[]},
                permanent, 10000, worker, [mod_rand]}),
    ok.

start_guild() ->
	{ok, _} = sg_sup:start_link(sup_guild),
	{ok, _} = supervisor:start_child(
				sup_guild, 
				{guild_man, {guild_man, start_link, []},
				 permanent, 10000, worker, [guild_man]}).

%%startup client supervision tree
start_client() ->
    {ok,_} = supervisor:start_child(
               sg_sup,
               {sg_tcp_client_sup,
                {sg_tcp_client_sup, start_link,[]},
                transient, infinity, supervisor, [sg_tcp_client_sup]}),
    ok.

%%startup tcp listener supervision tree
start_tcp(Port) ->
    {ok,_} = supervisor:start_child(
               sg_sup,
               {sg_tcp_listener_sup,
                {sg_tcp_listener_sup, start_link, [Port]},
                transient, infinity, supervisor, [sg_tcp_listener_sup]}),
    ok.


%%startup logging supervision tree
start_user_log() ->
	{ok, _} = sg_sup:start_link(sup_user_log),
    {ok,_} = supervisor:start_child(
               sup_user_log,
               {mod_user_log,
                {mod_user_log, start_link,[]},
                permanent, 10000, worker, [mod_user_log]}),
    ok.


init_mysql() ->
	{ok, _MysqlPid} = 
		supervisor:start_child
		(
			sg_sup, 
			{
				mysql,
				{mysql, start_link, 
					[?DB, ?DB_HOST, ?DB_PORT, ?DB_USER, ?DB_PASS, ?DB_NAME, fun(_, _, _, _) -> ok end, ?DB_ENCODE]},
				permanent, 10000, worker, [mysql]
			}
		),	
	 mysql:connect(?DB, ?DB_HOST, ?DB_PORT, ?DB_USER, ?DB_PASS, ?DB_NAME, ?DB_ENCODE, true),
	 ok.

init_user_log_mysql() ->
	 mysql:connect(?USER_LOG_DB, ?DB_HOST, ?DB_PORT, ?DB_USER, ?DB_PASS, ?USER_LOG_DB_NAME, ?DB_ENCODE, true),
	 ok.

init_gen_cache() ->
	RecordList = map_data:tables(),
	{ok, _} = sg_sup:start_link(cache_sup),
	Fun = fun(Record) ->   
		Mapper = map_data:map(Record), 
		GenCacheCb = map_data:gen_cache_call_back(Record),
		GenCacheState = #gen_cache_state{record = Record, mapper = Mapper, 
										 call_back = GenCacheCb},
		gen_cache:init_ets(GenCacheState), 
		{ok, _PID} = supervisor:start_child(cache_sup, 
										{cache_util:get_register_name(Record),
										 {gen_cache, start_link, [GenCacheState]},
										 permanent, 10000, worker, [gen_cache]})
	end,
	[Fun(Record) || Record <- RecordList].

start_uid_server() ->
	{ok, _} = sg_sup:start_link(sup_uid),
	{ok,_} = supervisor:start_child(
               sup_uid,
               {uid_server,
                {uid_server, start_link, []},
                permanent, 10000, worker, [uid_server]}),
    ok.

start_monster() ->
	{ok, _} = sg_sup:start_link(sup_monster),
	{ok, _} = 
		supervisor:start_child(sup_monster,
			{
			 	mod_monster,
		   		{
				 	mod_monster, 
					start_link, 
					[]
				},
				permanent, 10000, worker, [mod_monster]
			}
		),
	ok.

start_dungeon_rank() ->
	{ok, _} = sg_sup:start_link(sup_dungeon_rank),
	{ok,_} = supervisor:start_child(
               sup_dungeon_rank,
               {dungeon_rank,
                {dungeon_rank, start_link, []},
                permanent, 10000, worker, [dungeon_rank]}
		).

start_slave_timer() ->
	{ok, _} = sg_sup:start_link(sup_slave_timer),
	{ok,_} = supervisor:start_child(
               sup_slave_timer,
               {slave_timer,
                {slave_timer, start_link, []},
                permanent, 10000, worker, [slave_timer]}
		).

start_slave_mirror() ->
	{ok, _} = sg_sup:start_link(sup_slave_mirror),
	{ok,_} = supervisor:start_child(
               sup_slave_mirror,
               {slave_mirror,
                {slave_mirror, start_link, []},
                permanent, 10000, worker, [slave_mirror]}
		).	
start_mail()->
	{ok, _} = sg_sup:start_link(sup_mail),
	{ok, _} = 
		supervisor:start_child(sup_mail,
			{
			 	mod_mail,
		   		{
				 	mod_mail, 
					start_link, 
					[]
				},
				permanent, 10000, worker, [mod_mail]
			}
		),
	ok.

start_g_arena()->
	{ok, _} = sg_sup:start_link(sup_g_arena),
	{ok, _} = 
		supervisor:start_child(sup_g_arena,
			{
			 	g_arena,
		   		{
				 	g_arena, 
					start_link, 
					[]
				},
				permanent, 10000, worker, [g_arena]
			}
		),
	ok.

start_g_yunbiao()->
	{ok, _} = sg_sup:start_link(sup_g_yunbiao),
	{ok, _} = 
		supervisor:start_child(sup_g_yunbiao,
			{
			 	g_yunbiao,
		   		{
				 	g_yunbiao, 
					start_link, 
					[]
				},
				permanent, 10000, worker, [g_yunbiao]
			}
		),
	ok.

start_marstower_king()->
	{ok, _} = sg_sup:start_link(sup_marstower_king),
	{ok, _} = supervisor:start_child(sup_marstower_king,
			{
				mod_marstower_king,
				{
					mod_marstower_king,
					start_link,
					[]
				},
				permanent,10000,worker,[mod_marstower_king]
			}
		),
	ok.

start_g_boss()->
	{ok, _} = sg_sup:start_link(sup_g_boss),
	{ok, _} = supervisor:start_child(sup_g_boss,
			{
				g_boss,
				{
					g_boss,
					start_link,
					[]
				},
				permanent,10000,worker,[g_boss]
			}
		),
	ok.
	
start_statistics() ->
	{ok, _} = sg_sup:start_link(sup_statistics),
	{ok, _} = supervisor:start_child(
				sup_statistics,
				{mod_statistics, 
				{mod_statistics, start_link, []}, permanent, 10000, worker, [mod_statistics]}),
	ok.