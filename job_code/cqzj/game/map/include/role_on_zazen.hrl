
%% 玩家在线挂机模块

%% 玩家级别与每次获取的经验配置
%% role_level 玩家级别 exp 最少时间获取的经验值
-record(r_on_zazen_role_exp,{role_level,exp}).

%% 玩家在线挂机记录结构
%% role_id 玩家id, start_time 在线挂机开始时间 sum_exp 获得的总经验 next_time下次获得时间，
%% role_exp_record 玩家在线挂机经验配置 结构为 r_on_hook_role_exp
%% end_time 在线挂机结束时间
-record(r_role_on_zazen,{role_id,role_exp_record,next_time = 0,sum_exp = 0}).

%% 玩家在线挂机进程字典前缀定义
%% Record 结构为 r_role_on_hook
%% erlang:put({on_hook_role,RoleId},Record)
-define(MAP_ON_ZAZEN_ROLE_DICT_PREFIX,map_on_zazen_role).

-define(on_zazen_config,role_on_zazen).

