%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     Mysql持久化表的配置
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------

-module(mysql_persistent_config).


%%
%% Include files
%%
-include("common.hrl").
-include("common_server.hrl").

%%
%% Exported Functions
%%
-export([table_define/1,tables/0]).
-export([is_mysql_table/1]).
-export([subscribe_table_p/0]).

%%
%% API Functions
%%

%% @spec is_mysql_table(DbTable::atom())-> boolean()
%% @doc 判断该表是否作为Mysql的持久化
is_mysql_table(DbTab) when is_atom(DbTab)->
    table_define(DbTab) =/= false.

subscribe_table_p() ->
    [db_role_vip_p, db_role_couple_sole_p, db_role_couple_pair_p].

%%@doc 所有的mysql持久化表列表
tables()->
    [
		db_role_faction_p,
		db_account_p,
		db_role_base_p,
		db_role_attr_p,
		db_role_ext_p,
		db_role_level_rank_p,
		db_role_pkpoint_rank_p,
		db_role_world_pkpoint_rank_p,
		db_family_active_rank_p,
		db_role_gongxun_rank_p,
		db_family_gongxun_persistent_rank_p,
		db_normal_title_p,
		db_role_give_flowers_yesterday_rank_p,
		db_role_rece_flowers_yesterday_rank_p,
		db_role_pet_rank_p,
		db_pet_p,
		db_role_vip_p,
		db_fcm_data_p,
		db_pay_log_p,
		db_pay_log_index_p,
		db_role_fighting_power_rank_p,
		db_role_rece_flowers_rank_p,
		db_role_give_flowers_rank_p
	].


%% mnesia和mysql数据库表的映射定义
    %% 注意——
    %% 1)对字段的顺序不能随便调整，因为erlang中，record只是一个带tag的tuple
    %% 2)支持的字段类型如下：
    %%      int :: integer()
    %%      bigint :: integer()
    %%      tinyint :: boolean()
    %%      varchar :: string()
    %%      binchar :: binary字段作为varchar类型来存储，例如role_name
    %%      tuplechar :: tuple字段作为varchar类型来存储，例如role_bag_key
    %%              tuple的每个元素必须是integer()或atom()
    %%      blob :: 该字段不写入mysql
    %%      tinyblob :: 该字段不写入mysql
    %%  目前一共65个表
    %%  [ ].

%% 定义表结构
table_define(db_role_faction_p)->
    [{type,set},
     {record_name,r_role_faction},
     {attributes,[{faction_id,int},{number,int}]}];
table_define(db_account_p)->
    [{type,set},
     {record_name,r_account},
     {attributes,
      [{account_name,binchar,50}, %% required string
       {create_time,int},{role_num,int}]}];

table_define(db_role_base_p)->
	[{type,set},
	 {record_name,p_role_base},
	 {attributes,
	  [
	   {role_id, int},
	   {role_name, binchar, 50},	%% required string
	   {account_name, binchar, 50},	%% required string
	   {sex,int},
	   {create_time,int},
	   {status,int},
	   {head,int},
	   {faction_id,int},
	   {team_id,int},
	   {family_id,int},
	   {family_name, varchar, 50},	%% optional string
	   {max_hp,int},
	   {max_mp,int},
	   {str,int},
	   {int2,int},
	   {con,int},
	   {dex,int},
	   {men,int},
	   {base_str,int},
	   {base_int,int},
	   {base_con,int},
	   {base_dex,int},
	   {base_men,int},
	   {pk_title,int},
	   {max_phy_attack,int},
	   {min_phy_attack,int},
	   {max_magic_attack,int},
	   {min_magic_attack,int},
	   {phy_defence,int},
	   {magic_defence,int},
	   {hp_recover_speed,int},
	   {mp_recover_speed,int},
	   {luck,int},
	   {move_speed,int},
	   {attack_speed,int},
	   {no_defence,int},
	   {miss,int},
	   {double_attack,int},
	   {phy_anti,int},
	   {magic_anti,int},
	   {cur_title, varchar, 100},	%% optional string
	   {cur_title_color, varchar, 50}, %% optional string
	   {pk_mode,int},
	   {pk_points,int},
	   {last_gray_name,int},
	   {if_gray_name, tinyint},
	   {weapon_type,int},
	   {buffs, blob},
	   {phy_hurt_rate,int},
	   {magic_hurt_rate,int},
	   {disable_menu, blob},	%%貌似修改了定义？？
	   {dizzy,int},
	   {poisoning,int},
	   {freeze,int},
	   {hurt,int},
	   {poisoning_resist,int},
	   {dizzy_resist,int},
	   {freeze_resist,int},
	   {hurt_rebound, int},
	   {hit_rate, int},
	   {account_type, int},
	   {server_id, int},
	   {is_disabled, tinyint},
	   {block, int},
	   {wreck, int},
	   {tough, int},
	   {vigour, int},
	   {week, int},
	   {molder, int},
	   {hunger, int},
	   {bless, int},
	   {crit, int},
	   {bloodline, int},
     {rate_attrs, blob}
	  ]}];
table_define(db_role_attr_p)->
    [{type,set},
     {record_name,p_role_attr},
     {attributes,
      [{role_id,int},
       {role_name,binchar,50},	%% optional string
       {next_level_exp,bigint},
       {exp,bigint},
       {level,int},
       {five_ele_attr,int},
       {last_login_location,binchar,50},	%% optional string
       {equips,blob},	%%repeated p_goods 
       {jungong,int},
       {charm,int},
       {couple_id,int},
       {couple_name,int},
       {skin,blob},	%% required p_skin
       {cur_energy,int},
       {max_energy,int},
       {remain_skill_points,int},
       {gold,int},
       {gold_bind,int},
       {silver,int},
       {silver_bind,int},
       {show_cloth,tinyint},	%% required bool show_cloth
       {moral_values,int},
       {gongxun,int},
       {last_login_ip,varchar,30},	%% optional string
       {office_id,int},
       {office_name,varchar,50},	%% required string office_name
       {unbund,tinyint},	%% bool unbund
       {family_contribute,int},
       {active_points,int},
       {category,int},
       {show_equip_ring, tinyint},
       {is_payed, tinyint},
       {sum_prestige,bigint},
       {cur_prestige,bigint},
       {jingjie,int},
       {medals,blob},
       {recruitment_type_id, int},
       {juewei, int},
       {yueli, int}
      ]}];
table_define(db_role_ext_p)->
    [{type,set},
     {record_name,p_role_ext},
     {attributes,
      [{role_id,int},
       {signature,varchar,255},   %% optional string
       {birthday,int},
       {constellation,int},
       {country,int},
       {province,int},
       {city,int},
       {blog,varchar,255},    %% optional string
       {family_last_op_time,int},
       {last_login_time,int},
       {last_offline_time,int},
       {role_name,binchar,50},        %% required string
       {sex,int},
       {ever_leave_xsc,tinyint,1}]}];   %% required p_skin
table_define(db_role_level_rank_p)->
    [{type,set},
     {record_name,p_role_level_rank},
     {attributes,
      [{role_id,int},
       {role_name,binchar,50},	%% optional string
       {faction_id,int},
       {family_name,varchar,50},	%% optional string
       {level,int},
       {ranking,int},
       {title,varchar,255},	%% optional string
       {exp,bigint},
       {category,int}]}];
table_define(db_role_pkpoint_rank_p)->
    [{type,set},
     {record_name,p_role_pkpoint_rank},
     {attributes,
      [{role_id,int},
       {role_name,binchar,50},	%% required string	role_name
       {faction_id,int},
       {family_name,varchar,50},	%% optional string	family_name
       {ranking,int},
       {title,varchar,255},	%% optional string	title
       {pk_points,int}]}];
table_define(db_role_world_pkpoint_rank_p)->
    [{type,set},
     {record_name,p_role_pkpoint_rank},
     {attributes,
      [{role_id,int},
       {role_name,binchar,50},	%% required string	role_name
       {faction_id,int},
       {family_name,varchar,50},	%% optional string	family_name
       {ranking,int},
       {title,varchar,255},	%% optional string	title
       {pk_points,int}]}];
table_define(db_family_active_rank_p)->
    [{type,set},
     {record_name,p_family_active_rank},
     {attributes,
      [{family_id,int},
       {family_name,varchar,50},	%% required string	family_name	
       {owner_role_name,binchar,50}, %% required string	owner_role_name
       {level,int},
       {ranking,int},
       {member_count,int},
       {active,int},
       {faction_id,int}]}];
table_define(db_role_gongxun_rank_p)->
    [{type,set},
     {record_name,p_role_gongxun_rank},
     {attributes,
      [{role_id,int},
       {role_name,binchar,50},	%% required string	role_name
       {faction_id,int},
       {family_name,varchar,50},	%% required string	family_name
       {level,int},
       {ranking,int},
       {title,varchar,255},	%% required string	title
       {exp,bigint},
       {gongxun,int}]}];
table_define(db_family_gongxun_persistent_rank_p)->
    [{type,set},
     {record_name,p_family_gongxun_persistent_rank},
     {attributes,
      [{key,int},
       {family_id,int},
       {total_gongxun,int},
       {ranking,int},
       {date,int}]}];
table_define(db_normal_title_p)->
    [{type,set},
     {record_name,p_title},
     {attributes,
      [{id,int},
       {name,varchar,50},
       {type,int},
       {auto_timeout,tinyint,1},
       {timeout_time,int},
       {role_id,int},
       {show_in_chat,tinyint,1},
       {show_in_sence,tinyint,1},
       {color,varchar,50},
       {type_id, int}]}];
table_define(db_role_give_flowers_yesterday_rank_p)->  
    [{type,set},
     {record_name,p_role_give_flowers_yesterday_rank},
     {attributes,
      [{role_id,int},
       {ranking,int},
       {role_name,binchar,50},
       {level,int},
       {score,int},
       {family_id,int},
       {family_name,varchar,50},   
       {faction_id,int},
       {title,varchar,255}]}];
table_define(db_role_rece_flowers_yesterday_rank_p)->  
    [{type,set},
     {record_name,p_role_rece_flowers_yesterday_rank},
     {attributes,
      [{role_id,int},
       {ranking,int},
       {role_name,binchar,50},
       {level,int},
       {charm,int},
       {family_id,int},
       {family_name,varchar,50},   
       {faction_id,int},
       {title,varchar,255}]}];
table_define(db_role_pet_rank_p)-> 
    [{type,set},
     {record_name,p_role_pet_rank},
     {attributes,
      [{pet_id,int},
       {pet_type_name,varchar,50},   %%optional  string  
       {role_id,int},
       {ranking,int},
       {role_name,varchar,50},   %%optional  string  
       {level,int},
       {color,int},
       {understanding,int},
       {score,int},
       {faction_id,int},
       {title,varchar,50},
       {pet_name,varchar,50}]}];
table_define(db_pet_p)-> 
    [{type,set},
     {record_name,p_pet},
     {attributes,
      [{pet_id,int},
       {type_id,int},
       {role_id,int},
       {role_name,varchar,50},   %%optional  string  
       {hp,int},
       {max_hp,int},
       {pet_name,varchar,50},    %%optional string  
       {color,int},
       {understanding,int},
       {sex,int},
       {pk_mode,int},
       {bind,tinyint},           %%optional    bool 
       {mate_id,int},
       {mate_name,varchar,50},   %%optional string
       {level,int},
       {exp,bigint},             %%required    double
       {life,int},
       {generated,int},
       {buffs,blob},             %%repeated    p_actor_buf
       {str,int},
       {int2,int},
       {con,int},
       {dex,int},
       {men,int},
       {base_str,int},
       {base_int2,int},
       {base_con,int},
       {base_dex,int},
       {base_men,int},
       {phy_defence,int},
       {magic_defence,int},
       {phy_attack,int},
       {magic_attack,int},
       {double_attack,int},
       {hit_rate,int},
       {miss,int},
       {attack_speed,int},
       {attack_type,int},
       {category_type,int},
       {period,int},
       {skills,tinyblob},           %%repeated  p_pet_skill
       {title,varchar,50},          %%optional    string
       {max_hp_aptitude,int},
       {phy_defence_aptitude,int},
       {magic_defence_aptitude,int},
       {phy_attack_aptitude,int},
       {magic_attack_aptitude,int},
       {double_attack_aptitude,int},
       {get_tick,int},
       {next_level_exp,bigint},
       {state,int},
       {max_hp_grow_add,int},
       {phy_defence_grow_add,int},
       {magic_defence_grow_add,int},
       {phy_attack_grow_add,int},
       {magic_attack_grow_add,int},
       {max_skill_grid,int},
       {tricks,tinyblob},
       {max_aptitude,int},
       {max_understanding,int},
       {can_periodup,int},
       {max_hp_aptitude_tmp,int},
       {phy_defence_aptitude_tmp,int},
       {magic_defence_aptitude_tmp,int},
       {phy_attack_aptitude_tmp,int},
       {magic_attack_aptitude_tmp,int},
       {double_attack_aptitude_tmp,int},
       {surmount_aptitude,int},
	   {no_defence, int},
	   {block, int},
	   {wreck, int},
	   {tough, int},
	   {vigour, int},
	   {week, int},
	   {molder, int},
	   {hunger, int},
	   {bless, int},
	   {crit, int},
	   {bloodline, int},
     {equips, tinyblob},
     {bone, tinyblob},
     {qinmidu, int},
     {max_qinmidu, int},
     {mood, int},
     {foster, tinyblob},
     {jueji, tinyblob}
	   ]}];    %%repeated  p_pet_trick
table_define(db_role_vip_p)-> 
    [{type,set},
     {record_name,r_role_vip},
     {attributes,
      [{role_id,int},
       {vip_level,int},
       {jifen,int},
       {is_transfer_notice_free,tinyint},
       {is_transfer_notice,tinyint},
       {remote_depot_num,int},
	   {event_log,blob}]}];
table_define(db_fcm_data_p)-> 
    [{type,set},
     {record_name,r_fcm_data},
     {attributes,
      [{account,varchar,50},  
       {card,varchar,50},  
       {truename,varchar,50},  
       {offline_time,int},
       {total_online_time,int},
       {passed,tinyint}]}];
table_define(db_pay_log_p)-> 
    [{type,set},
     {record_name,r_pay_log},
     {attributes,
      [{id,int},
       {order_id,binchar, 20000},	%% optional string
       {role_id,int},
       {role_name,binchar,50},	%% required string	role_name
       {account_name,binchar,50},	%% required string	account_name
       {pay_time,int},
       {pay_gold,int},
       {pay_money,int},
       {year,int},
       {month,int},
       {day,int},
       {hour,int},
       {role_level,int},
       {is_first,tinyint}
      ]}];
table_define(db_pay_log_index_p)-> 
    [{type,set},
     {record_name,r_pay_log_index},
     {attributes,[{id,int},{value,int}]}];
table_define(db_role_rece_flowers_rank_p)-> 
    [{type, set},
     {record_name, p_role_rece_flowers_rank},
     {attributes,
      [{role_id, int},
       {ranking, int},
       {role_name, binchar, 50},
       {level, int},
       {charm, int},
       {family_id, int},
       {family_name, varchar, 50},
       {faction_id, int},
       {title,varchar,255}]}];
table_define(db_role_give_flowers_rank_p)->
    [{type, set},
     {record_name, p_role_give_flowers_rank},
     {attributes,
      [{role_id, int},
       {ranking, int},
       {role_name, binchar, 50},
       {level, int},
       {score, int},
       {family_id, int},
       {family_name, varchar, 50},
       {faction_id, int},
       {title, varchar, 255}]}];
table_define(db_role_fighting_power_rank_p)-> 
    [{type, set},
     {record_name, p_role_fighting_power_rank},
     {attributes,
      [{role_id, int},
       {ranking, int},
       {role_name, binchar, 50},
       {level, int},
       {fighting_power, int},
       {family_id, int},
       {family_name, varchar, 50},
       {faction_id, int},
       {title,varchar,255},
       {category, int},
       {sex, int}
       ]}];
table_define(_)->
    false.


