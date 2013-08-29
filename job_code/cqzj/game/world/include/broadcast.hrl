
%% 消息广播

-define(MOD_BROADCAST_SERVER,"mod_broadcast_server").

-define(MOD_BROADCAST_CYCLE,"mod_broadcast_cycle").

-define(ETS_BROADCAST_CONFIG,ets_broadcast_config).

-define(DEFAULT_MSG_GENERAL_PROCESS_COUNT,1).
-define(DEFAULT_MSG_COUNTDOWN_PROCESS_COUNT,1).
-define(DEFAULT_MSG_ADMIN_PROCESS_COUNT,1).
-define(DEFAULT_MSG_DELETE_PROCESS_COUNT,1).

-define(BROADCAST_MODULES,[mod_broadcast_general,
                           mod_broadcast_countdown,
                           mod_broadcast_admin,
                           mod_broadcast_delete,
                           mod_broadcast_cycle]).

%% 单位：毫秒
-define(DEFAULT_MSG_DELETE_INTERVAL_TIME,60000).
%% 单位：次数
-define(DEFAULT_MSG_COUNTDOWN_SYNC_TIMES,10).

-record(r_broadcast_countdown_msg,{msg_record,interval_time,unique, module, method, start_time, end_time, send_times, timer_ref}).


-record(r_broadcast_admin_msg,{msg_record, unique, module, method, timer_ref}).

-record(r_broadcast_cycle_msg,{id,msg_record, unique, module, method, timer_ref}).

-define(BROADCAST_DEV_FLAG,true).
