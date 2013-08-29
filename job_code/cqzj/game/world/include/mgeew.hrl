%%%----------------------------------------------------------------------
%%% @copyright 2010 mgeew (Ming Game Engine Erlang - World Server)
%%%
%%% @author odinxu, 2010-03-24
%%% @doc 
%%% @end
%%%----------------------------------------------------------------------

-define(APP_NAME, 'world.server').

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

%%带STACK的ERROR_MSG
-define(ERROR_MSG_STACK(Arg1,Arg2),  %% Args为两个参数
    common_logger:error_msg( node(), ?MODULE,?LINE,"Info:~s, Error: ~w, Stack:~w", [Arg1,Arg2,erlang:get_stacktrace()])).


-define(CRITICAL_MSG(Format, Args),
        common_logger:critical_msg( node(), ?MODULE,?LINE,Format, Args)).
    
-define(UNICAST_TOC(R2),common_misc:unicast2(PID, Unique, Module, Method, R2)).


-define(THROW_ERR(ErrCode),throw({error,ErrCode,undefined})).
-define(THROW_ERR_REASON(ErrReason),throw({error,2,ErrReason})).
-define(THROW_SYS_ERR(),?ERROR_MSG_STACK(system_err,[]), throw({error,?ERR_SYS_ERR,undefined})).

%%常见错误类型
-define(ERR_OK, 0). %%OK
-define(ERR_SYS_ERR, 1).    %%系统错误
-define(ERR_OTHER_ERR, 2).  %%其他错误，具体原因见Reason
-define(ERR_INTERFACE_ERR, 3).  %%接口错误
    
-record(role_state, {roleid, friendlist, line, buf_timer_ref, doing_mission_random=false, relive_timer_ref=false,cur_login_ip=[]}).

-record(relive_money, {gold, silver, copper}).


-define(TEAM_MAX_ROLE_COUNT, 5).

-define(HEARTBEAT_TICKET_TIME, 3000).

-define(HEARTBEAT_MAX_FAIL_TIME, 1).

-define(ACCOUNT_ROLE_COUNT_MAX, 3).

-define(RECV_TIMEOUT, 5000).

-define(LOGIN_MODULE, <<"login">>).

-define(HEART_BEAT, <<"00">>).

-define(ETS_MM_MAP, ets_mm_map).


%% 组队模块配置数据文件和ETS表名定义
-define(ETS_TEAM_CONFIG,ets_team_config).
%% 组队同意邀请消息处理记录，主要是用来处理当A邀请B，C之后，D邀请A，
%% 此时A同意D的邀请，并发的处理B，C在没有创建队伍时同意A的邀请的操作
-define(TEAM_ACCEPT_REQ_DELAY,1000).
-define(ETS_TEAM_ACCEPT_REQ,ets_team_accept_req).
%% 队伍信息定义
%% 队伍id
%% 物品拾取模式，1：自由拾取，2：独自拾取
%% 经验分配， 1：普通模式，2：经验传授
%% 队长角色id
%% 队伍成员列表
%% 队伍创建时间 
-record(r_team_state,{team_id,proccess_name, pick_type, exp_type, leader_role_id, team_role_list, create_time}).
%% 默认队伍最大人数值
-define(DEFAULT_MAX_MEMBER_COUNT,6).
%% 默认角色断线缓存时间，单位：分钟 
-define(DEFAULT_OFFLINE_CACHE_TIME,2).

-define(ETS_TEAM_EXP,ets_team_exp).
%% 处理角色打怪经验时间间隔,单位为：milliseconds 毫秒
-define(DEFAULT_TEAM_EXP_INTERVAL, 100).
%% 默认组队经验处理进程数
-define(DEFAULT_TEAM_MAX_EXP_PROCESS_COUNT, 10).
%% 默认一次处理最多的经验记录数
-define(DEFAULT_TEAM_MAX_EXP_RECORD_COUNT,10).
-define(DEFAULT_TEAM_MAX_PIXELS_X,1002).
-define(DEFAULT_TEAM_MAX_PIXELS_Y,580).
%% 默认 组队队员属性消息自动通知时间间隔，单位：毫秒
-define(DEFAULT_TEAM_ATTR_NOTIFY_INTERVAL, 200).
%% 默认 组队队员间是否可见消息通知间隔，单位：毫秒
-define(DEFAULT_TEAM_VISIBLE_MESSAGE_INTERVAL, 1000).
%% 默认 角色获取五行属性的最低级别,
%% TODO 暂时没有配置文件可以配置此数据
-define(DEFAULT_ROLE2_FIVE_ELE_ATTR_MIN_LEVEL, 16).

%% 物品临时背包Id
-define(SYSTEM_TEMP_BAG_ID,99).


-include("common.hrl").
-include("letter.hrl").
-include("mission_event.hrl").


%% 宏定义要求同样的命名规约，用于发送succ=false的toc数据结构
-define(SEND_ERR_TOC(RecName,Reason),        
        R2 = #RecName{succ=false,reason=Reason},common_misc:unicast(Line, RoleID, Unique, Module, Method, R2)
).
-define(SEND_ERR_TOC2(RecName,Reason),        
        case is_binary(Reason) of
            true ->
                R3 = #RecName{succ=false,reason=Reason},common_misc:unicast(Line, RoleID, Unique, Module, Method, R3);
            false ->
                ?ERROR_MSG_STACK("SystemError",Reason),
                R3 = #RecName{succ=false,reason=?_LANG_SYSTEM_ERROR},common_misc:unicast(Line, RoleID, Unique, Module, Method, R3)
            end
).

%%排行榜活动
-record(r_rank_activity,{rank_id,end_time,letter_title,letter_text,prizes_info}).
-record(r_rank_prize_info,{start_ranking,end_ranking,prize_goods}).
-record(r_rank_prize_goods,{type_id,num,bind,last_time}).

-include("activity.hrl").

-record(r_activity_schedule, {activity_id, start_time, end_time}).
-record(r_activity_setting, {activity_id, rank_size, qualified_value, view_rank_size, module}).