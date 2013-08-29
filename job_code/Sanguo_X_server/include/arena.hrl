%%============================================================================================
%% 竞技排行榜 begin
%%============================================================================================					 
-record(arena_rec, {
					rank    = 0,
					id      = 0,    
					sustain_win = 0,
					win_record={0,0,0,0,0},
					challengetimes=0,
					last_battle_time = 0,
					queue      = queue:new()     %%记录最近五场报告
					}). 


-record(arena_rec_types, {
					rank             = {integer},
					id               = {integer},
					sustain_win      = {integer},
					win_record       = {term},
					challengetimes   = {integer}, 
					last_battle_time = {integer},
					queue            = {term}
					}). 

-record(rank_index, {
					id      = 0 ,
					rank    = 0  
					}). 

-record(recent_rec, {
					 id                 = 0,
                     challenger_name    = "",
					 challenged_name     = "",
                     win_rec            = 0,  %%2 lose,1  win
					 challenge_time      = 0,
					 ranking             = 0    %%0 排名不变， n排名变成第n名
                    }).

-define(MAX_CHALLENGE_TIMES, 15). 	%%每天最大挑战次数
-define(CACHE_ARENA_REC, cache_util:get_register_name(arena_rec)).
-define(ARENA_UPDATE_TIME,22).
-define(BUY_ARENA_CHALLENGE_TIMES, 31007).
-define(BATTLE_CD, 10*60).				
-define(CLEAN_ARENA_BATTLE_CD, 31006).
-define(CHALLENGE_FIVE_TIMES, 5).  %%挑战5次翻牌
%%============================================================================================
%% 竞技排行榜 end
%%============================================================================================	
