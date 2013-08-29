
%% 玩家在线挂机模块

%% 玩家级别与每次获取的经验配置
%% role_level 玩家级别 exp 最少时间获取的经验值
-record(r_on_hook_role_exp,{role_level,exp}).

%% 玩家在线挂机记录结构
%% role_id 玩家id, start_time 在线挂机开始时间 sum_exp 获得的总经验 next_time下次获得时间，
%% role_exp_record 玩家在线挂机经验配置 结构为 r_on_hook_role_exp
%% end_time 在线挂机结束时间
-record(r_role_on_hook,{role_id,start_time = 0,times = 0,sum_exp = 0,next_time = 0,role_exp_record,end_time = 0}).

%% 玩家在线挂机进程字典前缀定义
%% Record 结构为 r_role_on_hook
%% erlang:put({on_hook_role,RoleId},Record)
-define(MAP_ON_HOOK_ROLE_DICT_PREFIX,map_on_hook_role).

-define(ON_HOOK_CONFIG,role_on_hook).

