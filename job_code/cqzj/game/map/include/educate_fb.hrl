%% 师门同心副本宏定义文件

%% 师门同心副本配置定义
-define(EDUCATE_FB_CONFIG,educate_fb).

%% 师门同心副本状态
-define(EDUCATE_FB_STATUS_RUNNING,1).
-define(EDUCATE_FB_STATUS_COMPLETE,2).
-define(EDUCATE_FB_STATUS_AWARD,3).

-define(EDUCATE_FB_MAP_STATUS_CREATE,0).
-define(EDUCATE_FB_MAP_STATUS_RUNNING,1).
-define(EDUCATE_FB_MAP_STATUS_CLOSE,2).

-define(EDUCATE_FB_QUERY_TYPE_OPEN_NPC_VIEW,1).
-define(EDUCATE_FB_QUERY_TYPE_USE_LEADER_ITEM_INIT,2).
-define(EDUCATE_FB_QUERY_TYPE_USE_LEADER_ITEM,3).
-define(EDUCATE_FB_QUERY_TYPE_OPEN_AWARD_VIEW,4).
-define(EDUCATE_FB_QUERY_TYPE_NOTICE,5).
-define(EDUCATE_FB_QUERY_TYPE_NOTICE_USE,6).

%% status 副本状态，0未完成 1完成
-record(r_educate_fb_dict,{parent_map_id,parent_map_role = [],
educate_fb_role = [],fb_count = 0,leader_role_id,leader_role_name,goods = [],
item_use_pos = [],start_time = 0,end_time = 0,used_item_role_ids = [],
fb_status = 0,monster_level = 0,fb_map_name,faction_id,fb_close_flag = 0,
fb_offline_roles = [],fb_dead_roles = [],fb_role_dead_times=0,drop_item_role_ids = []}).

-record(r_educate_fb_item_use_pos,{item_id,tx,ty,max_tx,max_ty}).


%% 师门同心副本进程字典信息
%% Record 结构为 r_educate_fb_dict
%% erlang:put({educate_fb_record,MapId},Record)
-define(EDUCATE_FB_RECORD_DICT_PREFIX,educate_fb_record).


-define(EDUCATE_FB_MAP_STATE_DICT_PREFIX,educate_fb_map_state).


-record(r_educate_fb_monster,{monster_level,type,monster_id,weight}).

-record(r_educate_fb_award,{min_count,max_count,award_number = 0}).
-record(r_educate_fb_sub_award,{weight,bc_type = 0,goods_create_special}).

%% 积分处理
-record(r_educate_fb_lucky_count,{min_count,max_count,default_weight,weight,less_weight}).
