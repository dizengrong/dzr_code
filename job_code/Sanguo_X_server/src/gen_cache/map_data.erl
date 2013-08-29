%% Author: dzr
%% Created: 2012-2-7
%% Description: TODO: Add description to map_data
-module(map_data).

%%
%% Include files
%%
-include("common.hrl").

%%-include("task.hrl").
%% -include("ets_sql_map.hrl"). 
%% -include("role.hrl").
%% -include("player_record.hrl").
%% -include("economy.hrl").
%% -include("scene.hrl").
%%
%% Exported Functions
%%
-export([tables/0, map/1, gen_cache_call_back/1, gen_cache_opt/1]). 

%% 将下面的所有的map的第一个参数放到下面的列表中,如果需要使用gen_cache的话
tables() -> 
	[
    rank_status,
    waterCounter,
	temp_bag,
	account, 
	economy, 
	position, 
	role,
	 role_data, 
	player_data, 
	player_task,
	 counter,
	bag, 
	item, 
	friend,
	 black_list,
	 dungeon,
	 dungeon_status,
	horse, 
	land,
	 fengdi_data,
	 qi_hun, 
	qihun_pinjie,
	 xunxian,
	 slave, 
	slave_owner,
	 guaji,
	arena_rec,
	 guild_info,
	 guild_member,
	 marstower,
	 marstower_king,
	yun_biao,
	jixing,
    water,
    zhuanyun,
    achieve,
    ets_cool_down,
	boss_rec].

%% 排行榜
map(rank_status)->#map{
					   ets_tab = rank_status,
					   sql_tab = gd_rankstatus,
					   key_classic = 1,
					   key_fields = [playerId],
					   fields = record_info(fields,rank_status),
					   fields_spec = #rank_status_types{},
					   ignored_fields = []
					   };

%% cd模块
map(ets_cool_down)->#map{
                    ets_tab = ets_cool_down,
                    sql_tab = gd_cool_down,
                    key_classic = 2,
                    key_fields = [playerId,cdType],
                    fields = record_info(fields,ets_cool_down),
                    fields_spec = #ets_cool_down_types{},
                    ignored_fields = []
                    };

%% 玩家浇水次数计算器
map(waterCounter)->#map{
                    ets_tab = waterCounter,
                    sql_tab = gd_water_counter,
                    key_classic = 1,
                    key_fields = [playerId],
                    fields = record_info(fields,waterCounter),
                    fields_spec = #waterCounterTypes{},
                    ignored_fields = []
                    };

%% 临时背包表
map(temp_bag)->#map{
					ets_tab = temp_bag,
					sql_tab = gd_temp_bag,
                    key_classic = 2,
                    key_fields = [playerId,bagType],
                    fields = record_info(fields,temp_bag),
                    fields_spec = #temp_bag_types{},
                    ignored_fields = []
					};

%% 每天给一个玩家最多浇水两次，为了实现这个算法，开了一张gen_cache表
map(water)->#map{
                ets_tab        = water,
                sql_tab        = gd_water,
                key_classic    = 2,
                key_fields     = [playerId,ownerId],
                fields         = record_info(fields, water),
                fields_spec    = #water_types{},
                ignored_fields = []
    };

%% map的参数为对应的record
map(account) -> #map{
				ets_tab        = ets_account,
				sql_tab        = gd_account,
				key_classic    = 1,
				key_fields     = [gd_accountID],
				fields         = record_info(fields, account),
				fields_spec    = #account_types{},
				ignored_fields = [
					gd_Password, 
					gd_PartnerSource]
	};
%% map(cd_status) ->   #map{
%%                 ets_tab        = cd_status,
%%                 sql_tab        = gd_status_cd,
%%                 key_classic    = 2,
%%                 key_fields     = [account_id,cd_num],
%%                 fields         = record_info(fields,cd_status),
%%                 fields_spec    = #cd_status_types{},
%%                 ignored_fields = []
%%     };

map(economy) -> #map{
				ets_tab        = ets_economy,
				sql_tab        = gd_economy,
				key_classic    = 1,
				key_fields     = [gd_accountId],
				fields         = record_info(fields, economy),
				fields_spec    = #economy_types{},
				ignored_fields = []
	};
map(position) -> #map{
				ets_tab        = ets_position,
				sql_tab        = gd_position,
				key_classic    = 1,
				key_fields     = [gd_accountId],
				fields         = record_info(fields, position),
				fields_spec    = #position_types{},
				ignored_fields = []
	};
map(role) -> #map{
				ets_tab        = ets_role,
				sql_tab        = gd_role,
				key_classic    = 2,
				key_fields     = [gd_accountId, gd_roleId],
				fields         = record_info(fields, role),
				fields_spec    = #role_types{},
				ignored_fields = [gd_liliang, gd_yuansheng, gd_tipo, gd_minjie,  
								  gd_liliangTalent, gd_yuanshengTalent,
								  gd_tipoTalent, gd_minjieTalent,   
								  gd_speed, gd_baoji, gd_shanbi, gd_gedang,
								  gd_mingzhong, gd_zhiming, gd_xingyun,  
								  gd_fanji, gd_pojia, gd_currentHp, gd_maxHp,    
								  p_def, m_def, p_att, m_att, star_lv]
	};
map(role_data) -> #map{
				ets_tab        = ets_role_data,
				sql_tab        = gd_roleData,
				key_classic    = 1,
				key_fields     = [gd_accountId],
				fields         = record_info(fields, role_data),
				fields_spec    = #role_data_types{},
				ignored_fields = []
	};
map(player_data) -> #map{
				ets_tab        = ets_player_data,
				sql_tab        = gd_playerData,
				key_classic    = 1,
				key_fields     = [gd_accountId],
				fields         = record_info(fields, player_data),
				fields_spec    = #player_data_types{},
				ignored_fields = []
	};
map(uid) -> #map{
				ets_tab        = ets_uid,
				sql_tab        = g_uid,
				key_classic    = 2,
				key_fields     = [server_index, type],
				fields         = record_info(fields, uid),
				fields_spec    = #uid_types{},
				ignored_fields = []
	};		
map(player_task) -> #map{
				ets_tab        = ets_player_task,
				sql_tab        = gd_task,
				key_classic    = 1,
				key_fields     = [gd_accountID],
				fields         = record_info(fields, player_task),
				fields_spec    = #player_task_types{},
				ignored_fields = []
	};
map(counter) -> #map{
				ets_tab        = ets_counter,
				sql_tab        = gd_counter,
				key_classic    = 2,
				key_fields     = [gd_accountId, gd_type],
				fields         = record_info(fields, counter),
				fields_spec    = #counter_types{},
				ignored_fields = []
	};	
map(bag) -> #map{
				ets_tab        = ets_bag,
				sql_tab        = gd_AccountBag,
				key_classic    = 2,
				key_fields     = [gd_AccountID, gd_BagType],
				fields         = record_info(fields, bag),
				fields_spec    = #bag_types{},
				ignored_fields = []
	};
map(item) -> #map{
				ets_tab        = ets_items,
				sql_tab        = gd_AccountItem,
				key_classic    = 2,
				key_fields     = [gd_AccountID, gd_WorldID],
				fields         = record_info(fields, item),
				fields_spec    = #item_types{},
				ignored_fields = []
	};

map(friend)-> #map{
				ets_tab        = ets_friend,
				sql_tab        = gd_friend,
				key_classic    = 2,
				key_fields     = [gd_AccountID,gd_friend_id],
				fields         = record_info(fields, friend),
				fields_spec    = #friend_types{},
				ignored_fields = []
	};
	 
map(black_list)-> #map{
				ets_tab        = ets_black_list,
				sql_tab        = gd_black_list,
				key_classic    = 2,
				key_fields     = [gd_AccountID,gd_friend_id],
				fields         = record_info(fields, black_list),
				fields_spec    = #black_list_types{},
				ignored_fields = []
	};
map(dungeon)-> #map{
				ets_tab        = ets_dungeon,
				sql_tab        = gd_dungeon,
				key_classic    = 2,
				key_fields     = [gd_accountId, dungeonId],
				fields         = record_info(fields, dungeon),
				fields_spec    = #dungeon_types{},
				ignored_fields = []
	};
map(dungeon_status)-> #map{
				ets_tab        = ets_dungeon_status,
				sql_tab        = gd_dungeon_status,
				key_classic    = 1,
				key_fields     = [gd_accountId],
				fields         = record_info(fields, dungeon_status),
				fields_spec    = #dungeon_status_types{},
				ignored_fields = []
	
	};
map(horse)-> #map{
				ets_tab        = ets_horse,
				sql_tab        = gd_horse,
				key_classic    = 1,
				key_fields     = [gd_accountId],
				fields         = record_info(fields, horse),
				fields_spec    = #horse_types{},
				ignored_fields = []
	};	
map(qi_hun)-> #map{
				ets_tab        = ets_qi_hun,
				sql_tab        = gd_qiHun,
				key_classic    = 1,
				key_fields     = [gd_accountId],
				fields         = record_info(fields, qi_hun),
				fields_spec    = #qi_hun_types{},
				ignored_fields = []
	};
map(qihun_pinjie)-> #map{
				ets_tab        = ets_qihun_pinjie,
				sql_tab        = gd_qihunPinjie,
				key_classic    = 1,
				key_fields     = [gd_accountId],
				fields         = record_info(fields, qihun_pinjie),
				fields_spec    = #qihun_pinjie_types{},
				ignored_fields = []
	};
map(land)-> #map{
				ets_tab        = ets_land,
				sql_tab        = gd_land,
				key_classic    = 2,
				key_fields     = [gd_accountId, gd_landId],
				fields         = record_info(fields, land),
				fields_spec    = #land_types{},
				ignored_fields = []
	};
map(fengdi_data)-> #map{
				ets_tab        = ets_fengdi_data,
				sql_tab        = gd_fengdiData,
				key_classic    = 1,
				key_fields     = [gd_accountId],
				fields         = record_info(fields, fengdi_data),
				fields_spec    = #fengdi_data_types{},
				ignored_fields = []
	};				
map(xunxian)-> #map{
				ets_tab		   = ets_xunxian,
				sql_tab		   = gd_xunxian,
				key_classic    = 1,
				key_fields     = [gd_AccountID],
				fields         = record_info(fields, xunxian),
				fields_spec	   = #xunxian_types{},
				ignored_fields = []
	};
map(slave)-> #map{
				ets_tab        = ets_slave,
				sql_tab        = gd_slave,
				key_classic    = 1,
				key_fields     = [gd_accountId],
				fields         = record_info(fields, slave),
				fields_spec    = #slave_types{},
				ignored_fields = []
	};	
map(slave_owner)-> #map{
				ets_tab        = ets_slave_owner,
				sql_tab        = gd_slaveOwner,
				key_classic    = 1,
				key_fields     = [gd_accountId],
				fields         = record_info(fields, slave_owner),
				fields_spec    = #slave_owner_types{},
				ignored_fields = []
	};
map(guild_info) -> 
	#map {
		ets_tab        = ?ETS_GUILD_INFO,
		sql_tab        = gd_guild,
		key_classic    = 1,
		key_fields     = [guild_id],
		fields         = record_info(fields, guild_info),
		fields_spec    = #guild_info_types{},
		ignored_fields = [apply_list]
	};
map(guild_member) ->
	#map {
		ets_tab        = ?ETS_GUILD_MEM,
		sql_tab        = gd_guildmember,
		key_classic    = 1,
		key_fields     = [id],
		fields         = record_info(fields, guild_member),
		fields_spec    = #guild_member_types{},
		ignored_fields = [] 
	};
map(guaji) ->
	#map{
		ets_tab        = ets_guaji,
		sql_tab        = gd_guaji,
		key_classic    = 1,
		key_fields     = [gd_AccountID],
		fields         = record_info(fields, guaji),
		fields_spec    = #guaji_types{},
		ignored_fields = [event]
	};
map(marstower) ->
	#map{
		ets_tab        = ets_marstower,
		sql_tab        = gd_marstower,
		key_classic    = 1,
		key_fields     = [gd_AccountID],
		fields         = record_info(fields, marstower),
		fields_spec    = #marstower_types{},
		ignored_fields = []
	};

map(arena_rec)->
	 #map{
			ets_tab		   = ets_arena_rec,
			sql_tab		   = gd_arena_rec,
			key_classic    = 1,
			key_fields     = [rank],
			fields         = record_info(fields, arena_rec),
			fields_spec	   = #arena_rec_types{},
			ignored_fields = []
	};

map(marstower_king)->
	#map{
			ets_tab		   = ets_marstower_king,
			sql_tab		   = gd_marstower_king,
			key_classic    = 1,
			key_fields     = [gd_Floor],
			fields         = record_info(fields, marstower_king),
			fields_spec	   = #marstower_king_types{},
			ignored_fields = []
	};

map(yun_biao)->
	#map{
			ets_tab		   = ets_yunbiao,
			sql_tab		   = gd_yun_biao,
			key_classic    = 1,
			key_fields     = [id],
			fields         = record_info(fields, yun_biao),
			fields_spec	   = #yun_biao_types{},
			ignored_fields = []
	};

map(jixing)->
	#map{
			ets_tab		   = ets_jixing,
			sql_tab		   = gd_jixing,
			key_classic    = 1,
			key_fields     = [fkey],
			fields         = record_info(fields, jixing),
			fields_spec	   = #jixing_types{},
			ignored_fields = []
	};

map(zhuanyun)->
	#map{
			ets_tab		   = ets_zhuanyun,
			sql_tab		   = gd_zhuanyun,
			key_classic    = 1,
			key_fields     = [id],
			fields         = record_info(fields, zhuanyun),
			fields_spec	   = #zhuanyun_types{},
			ignored_fields = []
	};

map(achieve)-> #map{
				ets_tab		   = ets_achieve,
				sql_tab		   = gd_achievement,
				key_classic    = 3,
				key_fields     = [gd_AccountID,gd_Type,gd_SubType],
				fields         = record_info(fields, achieve),
				fields_spec	   = #achieve_types{},
				ignored_fields = []
	};

map(boss_rec)-> #map{
				ets_tab		   = ets_boss_rec,
				sql_tab		   = gd_boss,
				key_classic    = 1,
				key_fields     = [fkey],
				fields         = record_info(fields, boss_rec),
				fields_spec	   = #boss_types{},
				ignored_fields = []
	};

map(_) -> none.
	
%% gen_cache_call_back 数据
gen_cache_call_back(_) ->
	#gen_cache_call_back{
	}.

gen_cache_opt(slave) -> #gen_cache_opt{
	pre_load = true
};

gen_cache_opt(guild_info)   -> #gen_cache_opt {pre_load = true};
gen_cache_opt(guild_member) -> #gen_cache_opt {pre_load = true};
gen_cache_opt(arena_rec) -> #gen_cache_opt {pre_load = true};

gen_cache_opt(_) -> undefined.












