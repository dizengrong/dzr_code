%% 场景大战副本类型 定义

-define(SCENE_WAR_FB_TYPE_PYH, 1). %% 鄱阳湖副本
-define(SCENE_WAR_FB_TYPE_DTFD, 2). %% 洞天福地副本
-define(SCENE_WAR_FB_TYPE_PYEH, 4). %% 捕鱼儿海副本
-define(SCENE_WAR_FB_TYPE_DXWL, 5). %% 地下王陵副本

%% 场景大战副本配置定义
-define(SCENE_WAR_FB_CONFIG,scene_war_fb).

-define(SCENE_WAR_FB_FB_STATUS_CREATE,0).
-define(SCENE_WAR_FB_FB_STATUS_RUNNING,1).
-define(SCENE_WAR_FB_FB_STATUS_COMPLETE,2).
-define(SCENE_WAR_FB_FB_STATUS_NOT_ENTER,3).
-define(SCENE_WAR_FB_FB_STATUS_CLOSE,4).
%% 场景大战副本组队要求
-define(SCENE_WAR_FB_TEAM_LEVEL_ONE,1).
-define(SCENE_WAR_FB_TEAM_LEVEL_TWO,2).
-define(SCENE_WAR_FB_TEAM_LEVEL_THREE,3).

%% 场景大战副本怪物
-define(SCENE_WAR_FB_BORN_MONSTER_AUTO,1).
-define(SCENE_WAR_FB_BORN_MONSTER_DYNAMIC,2).
-define(SCENE_WAR_FB_BORN_MONSTER_CALL,3).

%% 场景副本精英
-define(SW_FB_BORN_ELITE_NEVER,1).
-define(SW_FB_BORN_ELITE_NORMAL_DEAD,2).
-define(SW_FB_BORN_ELITE_TOGETHER,3).

%% 进入场景类型
-define(SCENE_WAR_FB_ENTER_FB_TYPE_CREATE,1).
-define(SCENE_WAR_FB_ENTER_FB_TYPE_JOIN,2).

-define(SCENE_WAR_FB_CALL_MONSTER_TYPE,2).

-define(SCENE_WAR_FB_RETURN_CODE_NOT_GOLD,2).%% 元宝不足

-define(TEAM_MEMBER_MAX_DIS, 7). %% 队员最大距离

%% 场景大战进程字典记录定义
-record(r_sw_fb_enter_dict,{fb_id,fb_seconds,fb_status = 0,fb_type,fb_level,team_id = 0,team_role_ids = [],in_role_ids = []}).
%% scene_war_fb 进入场景大战副本玩家记录列表 [r_scene_war_fb,...] 
%% collect_info 副本采集物列表 [] or [p_map_collect,..]
%% role_dead_times 玩家在副本中死亡次数记录 [{roleid,times}]
%% cur_monster_key 副本中怪物出生的相关数值  可以是怪物等级或者当前关卡数
%% monster_type 记录当前怪物类型 理论上是normal elite两种类型  ..
-record(r_sw_fb_dict,{fb_id,fb_seconds,fb_status = 0,fb_type,fb_level,team_id = 0,team_role_ids = [],in_role_ids = [],
start_time = 0,end_time = 0,scene_war_fb = [],monster_number = 0,cur_monster_number = 0,collect_info = [],collect_log_flag = 0,
fb_close_flag = 0,enter_fb_map_id,log_role_ids = [],role_dead_times = [],fb_offline_role_ids = [],cur_monster_key=0,close_seconds=30,
                      born_monster,born_elite,monster_type=1}).


%% 场景大战副本入口地图进程字典信息
%% DataRecordList 结构为 [r_sw_fb_enter_dict,...]
%% erlang:put({sw_fb_enter_dict,MapId},DataRecordList)
-define(SW_FB_ENTER_DICT_PREFIX,sw_fb_enter_dict).
%% 场景大战副本入口地图进程字典信息
%% DataRecord 结构为 r_sw_fb_dict
%% erlang:put({sw_fb_dict,MapId},DataRecord)
-define(SW_FB_DICT_PREFIX,sw_fb_dict).

%% 场景大战副本
%% erlang:put({sw_fb_map_dict,MapId},{FbMapId,FbMapProcessName})
-define(SW_FB_MAP_DICT_PREFIX,sw_fb_map_dict).

%% 副本组队
-define(SW_FB_TEAM, sw_fb_team).
-define(SW_FB_TEAM_LIST, sw_fb_team_list).
-define(SW_FB_NO_TEAM_ROLE_LIST, sw_fb_no_team_role_list).

%% 场景大战召唤怪物
%% pass_id:关卡id
%% call_monster_key:召唤怪物条件
%% item_use_pos:召唤怪物的位置{tx,ty}
%% next_pass_id:下一个关卡  0:表示结束  发奖励喽
-record(r_sw_fb_call_monster,{pass_id,next_pass_id}). 

-define(START_PASS,1).
-define(FINISH_PASS,-1).

%% 场景大战副本NPC配置
%% map_id 地图id
%% npc_id 场景大战NPC
%% fb_type 副本类型
%% fb_level 副本级别
-record(r_sw_fb_npc,{map_id,npc_id,fb_type,fb_level}).

%% 进入场景大战副费用和次数
%% min_times 最少副本次数
%% max_times 最多副本次数
%% fb_type 副本类型
%% fb_fee 进入费用
-record(r_sw_fb_fee,{min_times,max_times,fb_type,fb_fee = 0}).


%% 副本采集物品配置
%% 当副本级别为0时，表示适合所有此副本类型的配置，即当具体的副本级别没有配置时使用0的配置
%% fb_type 副本类型
%% fb_level 副本级别
%% weight 副本权重
%% collects 采集物 [p_collect_point_base_info,..]
-record(r_sw_fb_collect,{fb_type,fb_level,weight,collects = []}).

%% 副本内掉落物特殊处理配置
%% fb_type 副本类型
%% fb_level 副本级别
%% monster_type_id 怪物id
%% award_items 奖励道具
-record(r_sw_fb_monster,{fb_type,fb_level,monster_type_id,award_items = []}).
%% color 装备颜色[0,0,0,0,0,0] quality 装备品质 [0,0,0,0,0]
%% %% item_bind 绑定概率 默认权值 100,但是0 不绑定 100绑定
-record(r_sw_fb_monster_item,{item_id,item_type,item_number,item_bind = 0,weight,color = [],quality = []}).

%% fb_type 副本类型
%% min_num - max_num 人数多少到多少
%% exp_rate 经验比例
-record(r_sw_fb_exp, {fb_type, min_num, max_num, exp_rate}).


%% 最小级别，最大级别，权重值
-record(r_sw_role_level_weight,{min_level,max_level,weight}).


