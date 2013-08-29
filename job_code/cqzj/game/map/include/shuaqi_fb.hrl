%%刷棋副本

%% 地图副本中的进程字典保存的数据
%% monster_total_num:int()全部怪物
%% monster_pos:list()[{int(),int()}] 剩余怪物的地图出生坐标
%% monster_born_num:int() 已经出生的怪物数量
%% monster_dead_num:int() 怪物死亡数量
%% monster_normal_type:list()=[typelist:list()=[typeid:int()]]  普通怪物出生的类型规则
%% monster_type_conf:record() r_sq_monster_type 
%% born_space_time_conf:record() r_sq_monster_born_space 
%% next_born_time:int() 下次怪物出生时间
%% status:int() 0:创建副本中 1:副本进行中  2:副本关闭中
%% in_role_ids:list() [int()]进入副本角色id
%% out_role_ids:list() [int()]离开副本时的角色id
%% offline_roles_info:list() [{role_id:int(),offline_time:int()}]
%% monster_change_times:int() 怪物改变次数
%% role_dead_times:int() 玩家死亡次数
-record(r_sq_fb_map_info,{fb_type,monster_level = 0,monster_total_num=0,monster_pos=[],monster_born_num = 0,monster_dead_num=0,
                          monster_normal_type,monster_type_conf,born_space_time_conf,start_time,end_time,next_born_time=0,status=0,
                          in_roles_info=[],roles_offline_info=[],monster_change_times=0,roles_dead_info=[]}).
-record(r_role_sq_fb_map_info,{role_id,role_name,faction_id,level,team_id}).

-define(sq_fb_query,1).
-define(sq_fb_enter,2).
-define(sq_fb_quit,3).

-define(sq_fb_status_create,0).
-define(sq_fb_status_running,1).
-define(sq_fb_status_close,2).
-define(sq_fb_status_ignore,3).

%% ==配置文件中的record

%% 副本地图信息
%% max_second:副本最大存在时间
%% min_level:副本要求最小等级
%% max_level:副本要求最大等级
%% team_member:队伍人数
%% fight_times:攻击次数
%% monster_num:怪物数量包括boss
-record(r_sq_fb_mcm,{fb_type,map_id,max_second,min_level,max_level,team_member,fight_times,monster_num}).

%% 副本npc
-record(r_sq_fb_npc,{faction_id,map_id,npc_id}).

%% 权重
-record(r_sq_born_monster_weight,{min_level,max_level,weight}).

%% 怪物配置
-record(r_sq_monster_type,{monster_type_list,boss_type}).

%% 怪物出生间隔
%% start_num 从第几个怪物开始
%% end_num 第几个怪物结束
%% space_second怪物出生间隔时间
%% rest_second 下轮怪物出生休息时间
%% notice_id 广播id
-record(r_sq_monster_born_space,{start_num,end_num,space_seconds,rest_seconds,notice_id}).