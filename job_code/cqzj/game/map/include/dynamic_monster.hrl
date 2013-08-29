-define(TYPE_BORN_NOTICE, 1).
-define(TYPE_BORN_MONSTER, 2).
-define(ACTIVITY_MONSTER_LIST, activity_monster_list).
-define(ACTIVITY_CONFIG_KEY, dynamic_monster).
-define(BOSS_GROUP_LIST, boss_group_list).
-define(BOSS_GROUP_VIEW_LIST,boss_group_view_list).
-define(BOSS_GROUP_NEXT_REFLASH_TIME,boss_group_next_reflash_time).
-define(DYNAMIC_MONSTER_KEY,100018).
-define(BOSS_GROUP_CONFIG_CREATE_TIME,{5,0,0}).
%%监狱id 都给这个地图执行

%%%%% 动态boss群配置
%% id:唯一id
%% type:类型；daily=每天出生
%% time_params：时间参数；
%%          如果是daily，则为[StartTime,EndTime]
-record(r_boss_group_conf,{id,type,time_params}).
-record(r_boss_group_info, {id,date,start_time,end_time,born_map_list}).

-define(ACTIVITY_TYPE_EVERY_DAY,1).
-define(ACTIIVTY_TYPE_EVERY_WEEK,2).

-define(BOSS_GROUP_GET_LIST,1).
-define(BOSS_GROUP_GET_DETAIL,2).
-define(BOSS_GROUP_TRANSFER,3).
-define(BOSS_GROUP_ATTENTION,4).
-define(BOSS_GROUP_DELETE_ATTENTION,5).
-define(BOSS_GROUP_ATTENTION_NOTICE,6).