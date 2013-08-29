%% 符文争夺战副本模块宏定义


%% 符文争夺战副本配置文件宏定义
-define(COUNTRY_TREASURE_CONFIG,country_treasure).


%% 玩家进入符文争夺战副本出生点配置
%% map_id 地图id npc_id 入口npc id born_points 出生点列表 [{tx,ty},...]
-record(r_country_treasure_born,{map_id,npc_id,born_points}).

%% 玩家在符文争夺战副本传送的NPC配置
%% faction_id 国家,npc_id NPC id
-record(r_country_treasure_quit_npc,{faction_id,npc_id}).


%% 符文争夺战副本开始时间进程字点
%% Record 结构为 r_country_treasure_dict
%% erlang:put({country_treasure_record,MapId},Record)
-define(COUNTRY_TREASURE_RECORD_DICT_PREFIX,country_treasure_record).

%% start_time 副本开始时间
%% end_time 副本结束时间
%% next_bc_start_time 副本开始前消息广播
%% next_bc_end_time 副本结束前消息广播
%% next_bc_process_time 副本过程中消息广播
-record(r_country_treasure_dict,{week = 0,start_time = 0,end_time = 0,
next_bc_start_time = 0,next_bc_end_time = 0,next_bc_process_time = 0,
before_interval = 0,close_interval = 0,process_interval = 0,min_role_level = 20,
kick_role_time = 0,is_pop = 0}).
