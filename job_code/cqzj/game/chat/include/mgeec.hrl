-include("common.hrl").

-define(APP_NAME, 'chat.server').

-define(DEV(Format, Args),
        common_logger:dev(?APP_NAME, ?MODULE, ?LINE, Format, Args)).

-define(DEBUG(Format, Args),
        common_logger:debug_msg(?APP_NAME, ?MODULE,?LINE,Format, Args)).

-define(INFO_MSG(Format, Args),
        common_logger:info_msg( node(), ?MODULE,?LINE,Format, Args)).
			      
-define(WARNING_MSG(Format, Args),
        common_logger:warning_msg( node(), ?MODULE,?LINE,Format, Args)).
			      
-define(ERROR_MSG(Format, Args),
        common_logger:error_msg( node(), ?MODULE,?LINE,Format, Args)).

-define(CRITICAL_MSG(Format, Args),
        common_logger:critical_msg( node(), ?MODULE,?LINE,Format, Args)).
    
-define(HEART_BEAT, <<"00">>).


%% equal to <<"<policy-file-request/>\0">>
-define(CROSS_DOMAIN_FLAG, <<60,112,111,108,105,99,121,45,102,105,108,101,45,114,101,113,117,101,115,116,47,62,0>>).


-define(ETS_MM_MAP, ets_mm_map).

-define(TCP_OPTS, [
                   binary, 
                   {packet, 0},
                   {reuseaddr, true}, 
                   {nodelay, false},   
                   {delay_send, true}, 
                   {active, false},
                   {exit_on_close, false},
                   {send_timeout, 3000}
                  ]).

-define(UNKNOW_PACKET_MAX, 100).

-define(CHANNEL_PROCESS_EXIT_WAIT, 500).%%频道进程退出时等待多少秒
-define(ROLE_PROCESS_EXIT_WAIT, 500).%%角色进程退出时等待多少秒

-record(channel_role, {channel_sign, role_id, role_info, pid, channel_extend_process}).
-define(ETS_CHANNEL_ROLE, chat_channel_role).%%频道成员列表

%%类型 1世界/2国家/3家族/4组队/5好友群
%%扩展进程数量
-define(CHANNEL_TYPE_CONFIG, [{1, 10}, {2, 1}, {3, 1}, {4, 1}, {5, 10}]).
-record(chat_server, {ip, port, acceptor_num}).

-record(channel_counter, {channel_sign, extend_id, num}).
-define(ETS_CHANNEL_COUNTER, chat_channel_counter).%%频道子进程成员数统计表

-record(chat_role_state, {gateway_pid, channel_list, role_id, role_name, process_name, role_chat_data, chat_role_info, client_ip, last_chat_time={0, 0, 0}}).

-define(CHAT_TIME_LIMIE, 3).%%前后发言时间限制

-record(chat_log_data, {to_type, to_sign, role_id, rolename,  msg, time}).

-define(LOG_ROLE_PER_DIR, 1000).
-define(ETS_LOG, ets_log).
-define(LOG_NUM_TO_WRITE, 2).

-define(ETS_CONFIG, mgeec_ets_config).

-define(CHAT_STATUS_OFFLINE, 1).
-define(CHAT_STATUS_ONLINE, 2).

-define(CHAT_FRIENDLY_ADD_PER_TIME, 1).%%每次计算加多少点亲密度
-define(CHAT_FRIENDLY_TIME, 600000).%%好友亲密度计算，两次对话的有效单位时间 10分钟
-define(CHAT_FRIENDLY_NUM_PER_TIME, 10).%%每个单位时间内有效聊天到达多少次后
-define(CHAT_FRIENDLY_NUM_MAX, 100).%%每天累计最大值

%% 记录聊天日志相关的ETS表
-define(ETS_CHAT_LOG_WORLD, ets_chat_log_world).
-define(ETS_CHAT_LOG_COUNTRY, ets_chat_log_country).
-define(ETS_CHAT_LOG_LEVEL_CHANNEL,ets_chat_log_level_channel).

-define(CHAT_ERROR_CODE_ROLE_NOT_ONLINE, 1).%%不在线
-define(CHAT_ERROR_CODE_IN_ROLE_BLACKLIST, 2).%%在对方黑名单
-define(CHAT_ERROR_CODE_CHAT_TOO_FAST, 3).%%发言太快
-define(CHAT_ERROR_CODE_TALK_TO_SELF, 4).%%不能跟自己说话
