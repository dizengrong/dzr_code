%%%-------------------------------------------------------------------
%%% @author chenrong
%%% @doc
%%%     钦点美人
%%% @end
%%% Created : 2012-06-09
%%%-------------------------------------------------------------------
-module(mgeew_horse_racing).

-behaviour(gen_server).
-include("mgeew.hrl").
-include("horse_racing.hrl").

-export([start/0,
         start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

-define(PERSISTEN_TIME, 60000). 

-define(DEFAULT_HORSE_TYPE, 1). %% 默认小白马

-define(STATUS_NOT_RACING, 1). %% 还没开始跑马 
-define(STATUS_RACING, 2). %% 跑马中 

-define(GAME_SCORE_QUERY, 1).
-define(GAME_SCORE_UPDATE, 2).

-define(BUY_HORSE, 1).
-define(PLAY_GAME_GET_HORSE, 2).

-define(WARNING_LETTER_TIME, 290). %% 最后5分钟的警告信

-define(HP_ADDED_BY_BUY, 50000). %% 元宝召唤增加的血量

-define(RAMDOM_MISSION_EVENT_13,			13). %% 13.	钦点美人

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, {?MODULE,
                                                 {?MODULE, start_link, []},
                                                 permanent,10000, worker,
                                                 [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    erlang:process_flag(trap_exit, true),
    init_horse_racing_data(),
    erlang:send_after( 1000, self(), loop),
    erlang:send_after( ?PERSISTEN_TIME, self(), persist_data),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    persist_data(),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% dict manager functions
%% --------------------------------------------------------------------

%%记录进入钦点美人界面的玩家列表 (用于广播信息)
get_enter_role_list() ->
    get_list_from_dict(enter_role_list).

get_enter_role_id_list() ->
    lists:map(fun({RoleID, _})->RoleID end, get_enter_role_list()).

is_in_enter_role_list(RoleID) ->
    case lists:keyfind(RoleID, 1, get_enter_role_list()) of
        false ->
            false;
        _ ->
            true
    end.

join_enter_role_list(RoleID, VipLevel) ->
    EnterRoleList = get_enter_role_list(),
    erlang:put(enter_role_list, lists:keystore(RoleID, 1, EnterRoleList, {RoleID, VipLevel})).

del_enter_role(RoleID) ->
    erlang:put(enter_role_list, lists:keydelete(RoleID, 1, get_enter_role_list())).

%%所有玩家的钦点美人数据列表
get_horse_racing_info_list() ->
    get_list_from_dict(all_horse_racing_info).

set_horse_racing_info_list(AllList) ->
    erlang:put(all_horse_racing_info, AllList).

%% 获取所有正在跑马的列表
get_in_racing_info_list() ->
    lists:filter(fun(Info) -> Info#r_horse_racing.status =:= ?STATUS_RACING end, get_horse_racing_info_list()).

get_in_racing_info_list_exclude(RoleID) ->
    lists:filter(
      fun(Info) -> 
              Info#r_horse_racing.status =:= ?STATUS_RACING andalso Info#r_horse_racing.role_id =/= RoleID 
      end, get_horse_racing_info_list()).

%% 分页获取正在跑马的玩家列表
get_in_racing_info_list_by_page(Page, AllList) ->
    [PageSize] = common_config_dyn:find(horse_racing, page_size),
    if (Page-1)*PageSize > erlang:length(AllList) ->
           [];
       true ->
           lists:sublist(AllList, (Page-1)*PageSize + 1, PageSize)
    end.

%% 获取玩家跑马信息
get_horse_racing_info(RoleID) ->
    case lists:keyfind(RoleID, #r_horse_racing.role_id, get_horse_racing_info_list()) of
        false ->
            undefined;
        Info->
            Info
    end.

%% 更新玩家数据，并加入到更新列表中，定时存储
update_horse_racing_info(Info) ->
    AllList = get_horse_racing_info_list(),
    NewAllList = lists:keystore(Info#r_horse_racing.role_id, #r_horse_racing.role_id, AllList, Info),
    set_horse_racing_info_list(NewAllList),
    join_update_info_list(Info),
    ok.

%% 记录钦点美人数据修改的列表
get_update_info_list() ->
    get_list_from_dict(update_list).

join_update_info_list(Info) ->
    AllList = get_update_info_list(),
    NewAllList = lists:keystore(Info#r_horse_racing.role_id, #r_horse_racing.role_id, AllList, Info),
    erlang:put(update_list, NewAllList),
    ok.

clear_update_info_list() ->
    erlang:erase(update_list).

%% 玩家的奖励数据
get_role_reward_list() ->
    get_list_from_dict(reward_list).

set_role_reward_list(RewardList) ->
    erlang:put(reward_list, RewardList).

get_role_reward(RoleID) ->
    case lists:keyfind(RoleID, #r_horse_racing_reward.role_id, get_role_reward_list()) of
        false ->
            #r_horse_racing_reward{role_id=RoleID}; %% 默认为空奖励
        Reward->
            Reward
    end.

update_role_reward(Reward) ->
    AllList = get_role_reward_list(),
    NewAllList = lists:keystore(Reward#r_horse_racing_reward.role_id, #r_horse_racing_reward.role_id, AllList, Reward),
    set_role_reward_list(NewAllList),
    join_update_reward_list(Reward),
    ok.

%% 记录钦点美人数据修改的列表
get_update_reward_list() ->
    get_list_from_dict(update_reward_list).

join_update_reward_list(Reward) ->
    AllList = get_update_reward_list(),
    NewAllList = lists:keystore(Reward#r_horse_racing_reward.role_id, #r_horse_racing_reward.role_id, AllList, Reward),
    erlang:put(update_reward_list, NewAllList),
    ok.

clear_update_reward_list() ->
    erlang:erase(update_reward_list).

%% 获得所有的玩家日志记录
get_all_operate_log() ->
    get_list_from_dict(all_log).

set_all_operate_log(AllLogs) ->
    erlang:put(all_log, AllLogs).

update_all_operate_log(Log) when Log#r_horse_racing_log.source_role_id =/= 0 -> %% 只保存非系统奇遇信息
    [{_,AllLogNum}] = common_config_dyn:find(horse_racing, log_num),
    AllLogs = get_all_operate_log(),
    NewAllLogs = lists:sublist([Log|AllLogs], AllLogNum),
    set_all_operate_log(NewAllLogs);
update_all_operate_log(_) ->
    ignore.

get_list_from_dict(Key) ->
    case erlang:get(Key) of
        undefined ->
            [];
        List ->
            List
    end.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%% 初始化数据
init_horse_racing_data() ->
    case db:dirty_match_object(?DB_HORSE_RACING_P, #r_horse_racing{_ = '_'}) of
        [] ->
            set_horse_racing_info_list([]);
        AllInfo ->
            set_horse_racing_info_list(AllInfo)
    end,
    case db:dirty_match_object(?DB_HORSE_RACING_REWARD_P, #r_horse_racing_reward{_ = '_'}) of
        [] ->
            set_role_reward_list([]);
        RewardList ->
            set_role_reward_list(RewardList)
    end,
    case db:dirty_read(?DB_HORSE_RACING_ALL_LOG_P, 1) of
        [] ->
            set_all_operate_log([]);
        [#r_horse_racing_all_log{log_list=AllLogs}] ->
            set_all_operate_log(AllLogs)
    end.

do_handle_info(loop) ->
    erlang:send_after( 1000, self(), loop),
    loop_check_over_time(),
    loop_system_operate(), %% 系统奇遇
    ok;

do_handle_info(persist_data) ->
    persist_data(),
    erlang:send_after( ?PERSISTEN_TIME, self(), persist_data);

do_handle_info({role_enter, RoleID, Params}) ->
    do_role_enter(RoleID, Params);

do_handle_info({role_exit, RoleID}) ->
    do_role_exit(RoleID);

do_handle_info({refresh_daily_counter_times,RoleID,RemainTimes}) ->
    refresh_daily_counter_times(RoleID,RemainTimes);

do_handle_info({_,?HORSE_RACING, ?HORSE_RACING_INFO_LIST, _, _, _ ,_}=Info) ->
    do_get_horse_racing_info_list(Info);

do_handle_info({_,?HORSE_RACING, ?HORSE_RACING_INFO, _, _, _ ,_}=Info) ->
    do_get_horse_racing_info(Info);

do_handle_info({get_horse, RoleID, HorseType, OpType}) ->
    do_role_get_horse(RoleID, HorseType, OpType);

do_handle_info({_,?HORSE_RACING, ?HORSE_RACING_START, _, _, _ ,_}=Info) ->
    do_start_horse_racing(Info);

do_handle_info({_,?HORSE_RACING, ?HORSE_RACING_OPERATE, _, _, _ ,_}=Info) ->
    do_horse_racing_operate(Info);

do_handle_info({operate_succ, RoleID, OpType, TargetRoleID}) ->
    do_operate_succ(RoleID, OpType, TargetRoleID);

do_handle_info({operate_failed, RoleID, OpType, TargetRoleID}) ->
    do_operate_failed(RoleID, OpType, TargetRoleID);

do_handle_info({_,?HORSE_RACING, ?HORSE_RACING_REWARD_FETCH, _, _, _ ,_}=Info) ->
    do_horse_racing_reward_fetch(Info);

do_handle_info({_,?HORSE_RACING, ?HORSE_RACING_LOG, _, _, _ ,_}=Info) ->
    do_horse_racing_log(Info);

do_handle_info({_,?HORSE_RACING, ?HORSE_RACING_GAME_SCORE, _, _, _ ,_}=Info) ->
    do_horse_racing_game_score(Info);

do_handle_info({vip_up, RoleID, VipLevel}) ->
    do_role_vip_up(RoleID, VipLevel);

do_handle_info({_,?HORSE_RACING, ?HORSE_RACING_REWARD_NOTICE, _, _, _ ,_}=Info) ->
    do_horse_racing_reward_query(Info);

do_handle_info({_, ?HORSE_RACING, ?HORSE_RACING_GET, _, _, _, _} = Info) ->
    do_horse_racing_get(Info);

do_handle_info({_, ?HORSE_RACING, ?HORSE_RACING_OPERATE_LIST, _, _, _, _} = Info) ->
    do_horse_racing_operate_list(Info);

%% 慎重， 此接口只为了调试方便清空数据的
do_handle_info({clear_all}) ->
    set_all_operate_log([]),
    set_horse_racing_info_list([]),
    set_role_reward_list([]),
    clear_update_info_list(),
    clear_update_reward_list(),
    db:clear_table(?DB_HORSE_RACING_P),
    db:clear_table(?DB_HORSE_RACING_REWARD_P),
    db:clear_table(?DB_HORSE_RACING_ALL_LOG_P),
    ok;

%% 用于重启时修改数据
do_handle_info(reload) ->
    init_horse_racing_data();

do_handle_info(Info) ->
    ?ERROR_MSG("钦点美人进程无法处理此消息 Info=~w",[Info]),
    ok.


 refresh_daily_counter_times(_RoleID,_RemainTimes) -> ok.
%% 	 [RaceTimes] = common_config_dyn:find(horse_racing, race_times),
%% 	 case get_horse_racing_info(RoleID) of
%% 		 undefined ->
%% 			 RealRemainTimes = RaceTimes;
%% 		 Info ->
%% 			 #r_horse_racing{last_reset_date=LastResetDate,today_racing_times=TodayRacingTimes} = Info, 
%% 			 case LastResetDate =:= erlang:date() of
%% 				 true ->
%% 					 RealRemainTimes = 
%% 						 case  RemainTimes > 0 of
%% 							 true ->
%% 								 update_horse_racing_info(Info#r_horse_racing{today_racing_times=RaceTimes-RemainTimes}),
%% 								 RemainTimes;
%% 							 _ ->
%% 								 RaceTimes-TodayRacingTimes
%% 						 end; 
%% 				 _ ->
%% 					 RealRemainTimes = 
%% 						 case  RemainTimes > 0 of
%% 							 true ->
%% 								 TodayRacingTimes = RaceTimes-RemainTimes,
%% 								 RemainTimes;
%% 							 _ ->
%% 								 TodayRacingTimes = 0,
%% 								 RaceTimes-TodayRacingTimes
%% 						 end,
%% 					 NewInfo = Info#r_horse_racing{last_reset_date = erlang:date(), today_racing_times=TodayRacingTimes, 
%% 												   bless_horse_list=[], punish_horse_list=[]},
%% 					 update_horse_racing_info(NewInfo)
%% 			 end			 
%% 	 end,
%% 	 mod_daily_counter:set_mission_remain_times(RoleID, ?HORSE_RACING_START, RealRemainTimes, true).

loop_check_over_time() ->
    [#r_horse_config{hp=HP}] = common_config_dyn:find(horse_racing, {horse, ?DEFAULT_HORSE_TYPE}),
    Now = common_tool:now(),
    lists:foreach(
      fun(Info) ->
              #r_horse_racing{role_id=RoleID, end_time=EndTime, is_send_warning=IsSendWarning} = Info,
              if Now >= EndTime ->
                     NewInfo = Info#r_horse_racing{horse_id=0,horse_type=?DEFAULT_HORSE_TYPE, cur_hp=HP, status=?STATUS_NOT_RACING,  
                                                   end_time=Now, blessed_times=0, punished_times=0, system_operate_times=0,
                                                   blessed_list=[], punished_list=[], game_info=[],is_send_warning=false, multiple=1},
                     log_my_operation(NewInfo, ?OP_TYPE_END),
                     R2C = #m_horse_racing_end_toc{info=transformMyInfo(NewInfo)},
                     common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_END, R2C),
                     calc_and_notify_reward(Info);
                 not IsSendWarning andalso (Now + ?WARNING_LETTER_TIME >= EndTime) ->
                     send_warning_letter(Info),
                     update_horse_racing_info(Info#r_horse_racing{is_send_warning=true});
                 true ->
                     ignore
              end
      end, get_in_racing_info_list()).

calc_and_notify_reward(Info) ->
	#r_horse_racing{role_id=RoleID, cur_hp=CurHP, horse_type=HorseType, multiple=Multiple} = Info,
	
	[QualifiedHP] = common_config_dyn:find(horse_racing, qualified_hp),
	[#r_horse_config{base_exp_times=BaseExpTimes,reward_exp_multi=ExpMulti,reward_yueli=Yueli}] = common_config_dyn:find(horse_racing, {horse, HorseType}),
	case db:dirty_read(?DB_ROLE_ATTR, RoleID) of
		[#p_role_attr{level=Level}] ->
			[LianqiExp] = common_config_dyn:find(lianqi, {exp, Level}),
			BaseRewardExp = common_tool:ceil(BaseExpTimes * LianqiExp + Level * ExpMulti),
			?DBG(HorseType),
			?DBG(Multiple),
			?DBG(Level),
			if CurHP >= QualifiedHP ->
				   notify_role_succ_reward({BaseRewardExp, Yueli}, Info);
			   true ->
				   notify_role_failed_reward({BaseRewardExp}, Info)
			end;
		_ ->
			ignore
	end.

notify_role_succ_reward({BaseRewardExp, Yueli}, Info) ->
    #r_horse_racing{role_id=RoleID, role_name=RoleName, blessed_list=BlessedListT, punished_list=PunishedListT} = Info,
    TotalBlessHP = calc_total_operate_hp(BlessedListT),
    MyReward = get_role_reward(RoleID),
    update_role_reward(MyReward#r_horse_racing_reward{
          acc_reward_exp=MyReward#r_horse_racing_reward.acc_reward_exp + BaseRewardExp,
          reward_yueli = Yueli
    }),
    BlessedList = merge_log(BlessedListT),
    PunishedList = merge_log(PunishedListT),
    send_succ_letter(RoleID, BaseRewardExp, Yueli, BlessedList, PunishedList),
    notify_role_to_fetch_reward(RoleID, BaseRewardExp),
    lists:foreach(
      fun(#r_horse_racing_log{source_role_id=SRoleID, value=Value}) ->
              if SRoleID =/= RoleID andalso SRoleID =/= 0 ->
                     SReward = get_role_reward(SRoleID),
                     BlessPercentage = Value / TotalBlessHP,
                     SRewardExp = common_tool:floor(BaseRewardExp * 0.5 * BlessPercentage),
                     update_role_reward(SReward#r_horse_racing_reward{acc_reward_exp=SReward#r_horse_racing_reward.acc_reward_exp + SRewardExp}),
                     send_other_succ_letter(RoleName, SRoleID, BlessPercentage, SRewardExp),
                     notify_role_to_fetch_reward(SRoleID, SRewardExp),
                     ok;
                 true ->
                     ignore
              end
      end, BlessedList).

notify_role_failed_reward({BaseRewardExp}, Info) ->
    #r_horse_racing{role_id=RoleID, role_name=RoleName, blessed_list=BlessedListT, punished_list=PunishedListT} = Info,
	?DBG(BlessedListT),
	?DBG(PunishedListT),
    TotalPunishHP = calc_total_operate_hp(PunishedListT),
    MyReward = get_role_reward(RoleID),
    [{_, _, Percentage}] = common_config_dyn:find(horse_racing, {vip, get_vip_level_ex(RoleID)}),
    MyRewardExp = common_tool:floor(BaseRewardExp*Percentage),
    update_role_reward(MyReward#r_horse_racing_reward{acc_reward_exp=MyReward#r_horse_racing_reward.acc_reward_exp + MyRewardExp}),
    BlessedList = merge_log(BlessedListT),
    PunishedList = merge_log(PunishedListT),
    send_failed_letter(RoleID, MyRewardExp, BlessedList, PunishedList),
    notify_role_to_fetch_reward(RoleID, MyRewardExp),
    lists:foreach(
      fun(#r_horse_racing_log{source_role_id=SRoleID, value=Value}) ->
              if SRoleID =/= RoleID andalso SRoleID =/= 0 ->
                     SReward = get_role_reward(SRoleID),
                     PunishPercentage = Value / TotalPunishHP,
                     SRewardExp = common_tool:floor(erlang:abs(BaseRewardExp * 1 * PunishPercentage)),
                     update_role_reward(SReward#r_horse_racing_reward{acc_reward_exp=SReward#r_horse_racing_reward.acc_reward_exp + SRewardExp}),
                     send_other_failed_letter(RoleName, SRoleID, PunishPercentage, SRewardExp),
                     notify_role_to_fetch_reward(SRoleID, SRewardExp),
                     ok;
                 true ->
                     ignore
              end
      end, PunishedList).

calc_total_operate_hp(OperateList) ->
    lists:foldl(fun(#r_horse_racing_log{value=Value}, Acc) -> Value + Acc end, 0, OperateList).

%% 系统奇遇
loop_system_operate() ->
    [GapTime] = common_config_dyn:find(horse_racing, system_operate_gap_time),
    Now = common_tool:now(),
    lists:foreach(
      fun(Info) ->
              #r_horse_racing{role_id=RoleID, last_system_operate_time=LastOperateTime, cur_hp=CurHP} = Info,
              if LastOperateTime + GapTime =< Now ->
                     [OperateRandomList] = common_config_dyn:find(horse_racing, system_operate_weight),  
                     {OpType,_} = common_tool:random_from_tuple_weights(OperateRandomList, 2),
                     [{_, _, Value}] = common_config_dyn:find(horse_racing, {operate, OpType}),
                     NewTargetInfo = Info#r_horse_racing{cur_hp=erlang:max(CurHP + Value, 0), last_system_operate_time=LastOperateTime + GapTime},
                     {ok, _, NewTargetInfo2} = log_operation(system, NewTargetInfo, OpType, Value),
                     case is_in_enter_role_list(RoleID) of
                         true ->
                             R2C = #m_horse_racing_operate_toc{op_type=OpType, my_info=transformMyInfo(NewTargetInfo2), target_info=transformInfo(NewTargetInfo2)},
                             common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_OPERATE, R2C);
                         _ ->
                             ignore
                     end;
                 true ->
                     ignore
              end
      end, get_in_racing_info_list()).

%% 玩家打开钦点美人页面
%% 玩家没参与过，则默认帮他插入一条初始数据
%% 参加过的，则判断是否需要帮玩家更新数据（护体惩罚次数，每天参加的次数等等）
do_role_enter(RoleID, {RoleName, FactionID, VipLevel}) ->
    join_enter_role_list(RoleID, VipLevel),
    RacingInfo = 
        case get_horse_racing_info(RoleID) of
            undefined ->
                %% 默认初始值
                [#r_horse_config{hp=HP}] = common_config_dyn:find(horse_racing, {horse, ?DEFAULT_HORSE_TYPE}),
                DefaultInfo =#r_horse_racing{role_id=RoleID, role_name=RoleName, faction_id=FactionID, 
                                             horse_type=?DEFAULT_HORSE_TYPE, cur_hp=HP, status=?STATUS_NOT_RACING,
                                             bless_horse_list=[], punish_horse_list=[]},
                %% 插入默认值，简化后面其他功能操作处理
                update_horse_racing_info(DefaultInfo),
                DefaultInfo;
            Info ->
                #r_horse_racing{last_reset_date=LastResetDate} = Info,
                case LastResetDate =:= erlang:date() of
                    true ->
                        Info;
                    _ ->
                        NewInfo = Info#r_horse_racing{last_reset_date = erlang:date(), today_racing_times=0, 
                                                      bless_horse_list=[], punish_horse_list=[]},
                        update_horse_racing_info(NewInfo),
                        NewInfo
                end
        end,
    AllRacingList = get_in_racing_info_list_exclude(RoleID),
    OtherInfoList = get_in_racing_info_list_by_page(1, AllRacingList),
    R2C = #m_horse_racing_enter_toc{cur_page=1, max_page=calc_max_page(AllRacingList), 
                                    my_info=transformMyInfo(RacingInfo), info_list=transformInfo(OtherInfoList)},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_ENTER, R2C),
    mgeer_role:absend(RoleID, {mod_horse_racing, {role_enter, RoleID}}),
    ok.

%% 退出钦点美人
do_role_exit(RoleID) ->
    del_enter_role(RoleID).

%% 分页查询正在跑马的玩家信息
do_get_horse_racing_info_list({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
    #m_horse_racing_info_list_tos{page=Page} = DataIn,
    RacingInfo = get_horse_racing_info(RoleID),
    AllRacingList = get_in_racing_info_list_exclude(RoleID),
    OtherInfoList = get_in_racing_info_list_by_page(Page, AllRacingList),
    R2C = #m_horse_racing_info_list_toc{cur_page=Page, max_page=calc_max_page(AllRacingList),
                                        my_info=transformMyInfo(RacingInfo), info_list=transformInfo(OtherInfoList)},
    ?UNICAST_TOC(R2C).

do_get_horse_racing_info({Unique, Module, Method, DataIn, _RoleID, PID, _Line}) ->
    #m_horse_racing_info_tos{role_id=QueryRoleID} = DataIn,
    case get_horse_racing_info(QueryRoleID) of
        undefined ->
            R2C = #m_horse_racing_info_toc{err_code=?ERR_SYS_ERR};
        RacingInfo ->
            R2C = #m_horse_racing_info_toc{info=transformMyInfo(RacingInfo)}
    end,
    ?UNICAST_TOC(R2C).

%% 开始跑马
do_start_horse_racing({Unique, Module, Method, _DataIn, RoleID, PID, _Line}) ->
    RacingInfo = get_horse_racing_info(RoleID),
    #r_horse_racing{status=Status, last_reset_date=LastResetDate, today_racing_times=TodayRaceTimes} = RacingInfo,
    [RaceTimes] = common_config_dyn:find(horse_racing, race_times),
    NewTodayRaceTimes = get_today_race_times(LastResetDate, TodayRaceTimes),
    if Status =:= ?STATUS_RACING ->
            mgeer_role:send(RoleID, {apply, hook_mission_event, hook_special_event, [RoleID, ?MISSION_EVENT_START_HORSE]}),
           ?UNICAST_TOC(#m_horse_racing_start_toc{err_code=?ERR_HORSE_RACING_START_IN_RACING_STATUS});
       NewTodayRaceTimes >= RaceTimes ->
       mgeer_role:send(RoleID, {apply, hook_mission_event, hook_special_event, [RoleID, ?MISSION_EVENT_START_HORSE]}),
           ?UNICAST_TOC(#m_horse_racing_start_toc{err_code=?ERR_HORSE_RACING_NO_RACE_TIMES});
       true ->
           Now = common_tool:now(),
           [TotalTime] = common_config_dyn:find(horse_racing, total_time),
           HorseID = generate_horse_id(RoleID, NewTodayRaceTimes + 1),
           case LastResetDate =:= erlang:date() of
               true ->
                   NewRacingInfo = RacingInfo#r_horse_racing{horse_id=HorseID,status=?STATUS_RACING, today_racing_times=NewTodayRaceTimes + 1,
                                                             last_system_operate_time=Now, start_time=Now, end_time=Now + TotalTime};
               false ->
                   NewRacingInfo = RacingInfo#r_horse_racing{horse_id=HorseID,status=?STATUS_RACING, today_racing_times=NewTodayRaceTimes + 1,
                                                             last_system_operate_time=Now, start_time=Now, end_time=Now + TotalTime,
                                                             bless_horse_list=[], punish_horse_list=[],
                                                             last_reset_date = erlang:date()}
           end,
		   mod_daily_counter:set_mission_remain_times(RoleID, ?HORSE_RACING_START, RaceTimes-NewTodayRaceTimes - 1, true),
           log_my_operation(NewRacingInfo, ?OP_TYPE_START),
           AllRacingList = get_in_racing_info_list_exclude(RoleID),
           OtherInfoList = get_in_racing_info_list_by_page(1, AllRacingList),
           ?UNICAST_TOC(#m_horse_racing_start_toc{cur_page=1, max_page=calc_max_page(AllRacingList), 
                                                  my_info=transformMyInfo(NewRacingInfo), info_list=transformInfo(OtherInfoList)}),
           % hook_mission_event:hook_special_event(RoleID,?MISSION_EVENT_START_HORSE),
           mgeer_role:send(RoleID, {apply, hook_mission_event, hook_special_event, [RoleID, ?MISSION_EVENT_START_HORSE]}),
           hook_start_horse_racing(RoleID, NewTodayRaceTimes + 1 =:= RaceTimes),
		   mod_random_mission:handle_event(RoleID, ?RAMDOM_MISSION_EVENT_13),
           hook_activity_task:done_task(RoleID, ?ACTIVITY_TASK_HORSE_RACE)
    end.

hook_start_horse_racing(RoleID, IsMaxTime) ->
	if IsMaxTime =:= true ->
		   mod_access_guide:send_hook_info(RoleID, {finish_horse_racing, RoleID});
	   true ->
		   ignore
	end.

generate_horse_id(RoleID, TodayRacingTimes) ->
    {_,_,Day} = erlang:date(),
    RoleID * 10000 + Day*100 + TodayRacingTimes.

%% 玩家作祝福，惩罚操作
do_horse_racing_operate({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
    #m_horse_racing_operate_tos{role_id=TargetRoleID, op_type=OpType} = DataIn,
    case catch check_horse_racing_operate(RoleID, DataIn) of
        {error, ErrCode, Reason} ->
            ?UNICAST_TOC(#m_horse_racing_operate_toc{err_code=ErrCode, reason=Reason, op_type=OpType});
        {ok, NewRacingInfo} ->
            %% 先扣除次数，然后在map中扣除金钱，map通知world扣除结果，再进行相应的处理（扣除失败则恢复次数）
            update_horse_racing_info(NewRacingInfo),
            mgeer_role:absend(RoleID, {mod_horse_racing, {operate, RoleID, OpType, TargetRoleID}})
    end.

check_horse_racing_operate(RoleID, DataIn) ->
    #m_horse_racing_operate_tos{role_id=TargetRoleID, op_type=OpType} = DataIn,
    case not lists:member(OpType, [?OP_TYPE_SILVER_BLESS, ?OP_TYPE_GOLD_BLESS, ?OP_TYPE_SILVER_PUNISH, ?OP_TYPE_GOLD_PUNISH]) of
        true ->
            ?THROW_ERR(?ERR_HORSE_RACING_OPERATE_CODE_ERROR);
        false ->
            ignore
    end,
    IsPunishOpType = lists:member(OpType, [?OP_TYPE_SILVER_PUNISH, ?OP_TYPE_GOLD_PUNISH]),
    IsBlessOpType = lists:member(OpType, [?OP_TYPE_SILVER_BLESS, ?OP_TYPE_GOLD_BLESS]),
    case RoleID =:= TargetRoleID andalso IsPunishOpType of
        true ->
            ?THROW_ERR(?ERR_HORSE_RACING_CAN_NOT_PUNISH_MYSELF);
        false ->
            ignore
    end,
    
    RacingInfo = get_horse_racing_info(RoleID),
    case RoleID =:= TargetRoleID andalso RacingInfo#r_horse_racing.status =:= ?STATUS_NOT_RACING of
        true ->
            ?THROW_ERR(?ERR_HORSE_RACING_CANT_BLESS_MYSELF_NOT_RACING);
        _ ->
            ignore
    end,
  
    #r_horse_racing{horse_id=TargetHorseID, status=TargetStatus} = get_horse_racing_info(TargetRoleID),
    if TargetStatus =:= ?STATUS_NOT_RACING ->
           ?THROW_ERR(?ERR_HORSE_RACING_CANT_OPERATE_TARGET_NOT_RACING);
       true ->
           ignore
    end,
    
    case RacingInfo#r_horse_racing.last_reset_date =:= erlang:date() of
        true ->
            NewRacingInfo = RacingInfo;
        false ->
            %% 打开钦点美人界面，跨天操作时，顺便重置玩家的次数
            NewRacingInfo = RacingInfo#r_horse_racing{bless_horse_list=[], punish_horse_list=[],
                                                      last_reset_date=erlang:date(), today_racing_times=0}
    end,
    #r_horse_racing{bless_horse_list=BlessHorseList, punish_horse_list=PunishHorseList} = NewRacingInfo,
    case (IsPunishOpType andalso lists:member(TargetHorseID, PunishHorseList)) orelse 
             (IsBlessOpType andalso lists:member(TargetHorseID, BlessHorseList)) of
        true ->
            {ok, NewRacingInfo};
        _ ->
            [{BlessTimes, PunishTimes, _}] = common_config_dyn:find(horse_racing, {vip, get_vip_level(RoleID)}),
            RemainBlessTimes = erlang:max(BlessTimes - erlang:length(BlessHorseList), 0),
            RemainPunishTimes = erlang:max(PunishTimes - erlang:length(PunishHorseList), 0),
            NewRacingInfo2 = 
                case {IsPunishOpType, IsBlessOpType, RoleID =:= TargetRoleID, RemainPunishTimes =< 0, RemainBlessTimes =< 0} of
                    {_, _, true, _, _} -> %% 针对自己的不算次数 
                        NewRacingInfo;
                    {true, _, _, true, _} ->
						if
							PunishTimes =< 0 ->
								?THROW_ERR(?ERR_HORSE_RACING_VIPLEVEL_NOT_ENOUGH);
							true ->
								?THROW_ERR(?ERR_HORSE_RACING_NOT_ENOUGH_PUNISH_TIMES)
						end;
                    {true, _, _, false, _} ->
                        NewRacingInfo#r_horse_racing{punish_horse_list=[TargetHorseID|PunishHorseList]};
                    {_, true,  _, _, true} ->
						if
							PunishTimes =< 0 ->
								?THROW_ERR(?ERR_HORSE_RACING_VIPLEVEL_NOT_ENOUGH);
							true ->
								?THROW_ERR(?ERR_HORSE_RACING_NOT_ENOUGH_BLESS_TIMES)
						end;
                    {_, true, _, _, false} ->
                        NewRacingInfo#r_horse_racing{bless_horse_list=[TargetHorseID|BlessHorseList]}
                end,
            {ok, NewRacingInfo2}
    end.

do_operate_succ(RoleID, OpType, TargetRoleID) ->
    MyInfo = get_horse_racing_info(RoleID),
    TargetInfo = get_horse_racing_info(TargetRoleID),
    [{_, _, Value}] = common_config_dyn:find(horse_racing, {operate, OpType}),
    NewTargetInfo = TargetInfo#r_horse_racing{cur_hp=erlang:max(TargetInfo#r_horse_racing.cur_hp + Value, 0)},
    {ok, NewMyInfo, NewTargetInfo2} = log_operation(MyInfo, NewTargetInfo, OpType, Value),
    R2C = #m_horse_racing_operate_toc{op_type=OpType, my_info=transformMyInfo(NewMyInfo), target_info=transformMyInfo(NewTargetInfo2)},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_OPERATE, R2C),
    case is_in_enter_role_list(TargetRoleID) of
        true ->
            R2Target = #m_horse_racing_operate_toc{op_type=OpType, my_info=transformMyInfo(NewTargetInfo2), target_info=transformMyInfo(NewMyInfo)},
            common_misc:unicast({role, TargetRoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_OPERATE, R2Target);
        _ ->
            ignore
    end.

do_operate_failed(RoleID, OpType, _TargetRoleID) ->
    MyInfo = get_horse_racing_info(RoleID),
    #r_horse_racing{bless_horse_list=BlessHorseList, punish_horse_list=PunishHorseList} = MyInfo,
    IsBlessOpType = lists:member(OpType, [?OP_TYPE_SILVER_BLESS, ?OP_TYPE_GOLD_BLESS]),
    if IsBlessOpType ->
           NewMyInfo = MyInfo#r_horse_racing{bless_horse_list=shift_list(BlessHorseList)};
       true ->
           NewMyInfo = MyInfo#r_horse_racing{punish_horse_list=shift_list(PunishHorseList)}
    end,
    update_horse_racing_info(NewMyInfo).

shift_list([]) ->
    [];
shift_list([_H|T]) ->
    T.

do_horse_racing_reward_fetch({Unique, Module, Method, _DataIn, RoleID, PID, _Line}) ->
    #r_horse_racing_reward{acc_reward_exp=RewardExp, reward_yueli=Yueli} = get_role_reward(RoleID),
    if RewardExp > 0 ->
           update_role_reward(#r_horse_racing_reward{role_id=RoleID}),
           mgeer_role:absend(RoleID, {mod_horse_racing, {fetch_reward, RoleID, RewardExp, 0, Yueli}});
       true ->
           ?UNICAST_TOC(#m_horse_racing_reward_fetch_toc{err_code=?ERR_HORSE_RACING_ALREADY_FETCHED})
    end.

do_horse_racing_log({Unique, Module, Method, _DataIn, RoleID, PID, _Line}) ->
    AllLogs = get_all_operate_log(),
    #r_horse_racing{log_list=MyLogList} = get_horse_racing_info(RoleID),
    R2C = #m_horse_racing_log_toc{all_logs=transformLog(lists:reverse(AllLogs)), my_logs=transformLog(lists:reverse(MyLogList))},
    ?UNICAST_TOC(R2C).

do_horse_racing_game_score({Unique, Module, Method, DataIn, _RoleID, PID, _Line}=Info) ->
    #m_horse_racing_game_score_tos{op_type=OpType} = DataIn,
    case OpType of
        ?GAME_SCORE_QUERY ->
            do_query_game_score(Info);
        ?GAME_SCORE_UPDATE ->
            do_update_game_score(Info);
        _ ->
            ?UNICAST_TOC(#m_horse_racing_game_score_toc{err_code=?ERR_SYS_ERR})
    end.

do_query_game_score({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
    #m_horse_racing_game_score_tos{game_id=GameID} = DataIn,
    case get_horse_racing_info(RoleID) of
        undefined ->
            ?UNICAST_TOC(#m_horse_racing_game_score_toc{err_code=?ERR_SYS_ERR});
        RacingInfo ->
            #r_horse_racing{game_info=GameInfoList} = RacingInfo,
            case lists:keyfind(GameID, 1, GameInfoList) of
                false ->
                    Score = 0;
                {GameID, Score} ->
                    Score
            end,
            ?UNICAST_TOC(#m_horse_racing_game_score_toc{game_id=GameID, score=Score})
    end.
    
do_update_game_score({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
    #m_horse_racing_game_score_tos{game_id=GameID, score=Score} = DataIn,
    case get_horse_racing_info(RoleID) of
        undefined ->
            ?UNICAST_TOC(#m_horse_racing_game_score_toc{err_code=?ERR_SYS_ERR});
        RacingInfo ->
            #r_horse_racing{game_info=GameInfoList} = RacingInfo,
            NewGameInfoList = lists:keystore(GameID, 1, GameInfoList, {GameID, Score}),
            update_horse_racing_info(RacingInfo#r_horse_racing{game_info=NewGameInfoList}),
            ?UNICAST_TOC(#m_horse_racing_game_score_toc{game_id=GameID, score=Score})
    end.

do_role_vip_up(RoleID, _VipLevel) ->
    case get_horse_racing_info(RoleID) of
        undefined ->
            ignore;
        RacingInfo ->
            case is_in_enter_role_list(RoleID) of
                true ->
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_INFO, 
                                        #m_horse_racing_info_toc{info=transformMyInfo(RacingInfo)});
                _ ->
                    ignore
            end
    end.

do_horse_racing_reward_query({_Unique, _Module, _Method, _DataIn, RoleID, _PID, _Line}) ->
    Reward = get_role_reward(RoleID),
    notify_role_to_fetch_reward(RoleID, Reward).

do_horse_racing_get({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
    #m_horse_racing_get_tos{op_typ=OpType, horse_type=HorseType} = DataIn,
    case catch check_horse_racing_get(RoleID, OpType, HorseType) of
        {error, ErrCode, Reason} ->
            ?UNICAST_TOC(#m_horse_racing_get_toc{err_code=ErrCode, reason=Reason, op_type=OpType});
        {ok, ?BUY_HORSE} ->
            mgeer_role:absend(RoleID, {mod_horse_racing, {buy_horse, RoleID, HorseType, OpType}});
        {ok, ?PLAY_GAME_GET_HORSE} ->
            do_role_get_horse(RoleID, HorseType, OpType)
    end.

check_horse_racing_get(RoleID, OpType, HorseType) ->
    case OpType of
        ?BUY_HORSE ->
            ok;
        ?PLAY_GAME_GET_HORSE ->
            ok;
        _ ->
            ?ERROR_MSG("Wrong optype: ~w, RoleID: ~w", [OpType, RoleID]),
            ?THROW_ERR(?ERR_SYS_ERR)
    end,
    #r_horse_config{consume_gold=Gold} =
                       case common_config_dyn:find(horse_racing, {horse, HorseType}) of
                           [] ->
                               ?ERROR_MSG("config error, HorseType: ~w, RoleID: ~w", [HorseType, RoleID]),
                               ?THROW_ERR(?ERR_SYS_ERR);
                           [HorseConfigT] ->
                               HorseConfigT
                       end,
    if OpType =:= ?BUY_HORSE andalso Gold =:= 0 ->
            ?THROW_ERR(?ERR_HORSE_RACING_CAN_NOT_BUY);
       true ->
           ok
    end,
    case get_horse_racing_info(RoleID) of
        undefined ->
            ?THROW_SYS_ERR();
        RacingInfo when RacingInfo#r_horse_racing.status =:= ?STATUS_RACING ->
            ?THROW_ERR(?ERR_HORSE_RACING_CANT_GET_HORSE_IN_RACING_STATUS);
        RacingInfo when RacingInfo#r_horse_racing.horse_type >= HorseType ->
            ?THROW_ERR(?ERR_HORSE_RACING_CANT_GET_LOW_LEVEL_HORSE);
        _ ->
            ignore
    end,
    {ok, OpType}.

%% 获得纸船（购买或小游戏获得）
do_role_get_horse(RoleID, HorseType, OpType) ->
    RacingInfo = get_horse_racing_info(RoleID),
    [#r_horse_config{hp=HP}] = common_config_dyn:find(horse_racing, {horse, HorseType}),
    case OpType of
        ?BUY_HORSE ->
            [MultipleList] = common_config_dyn:find(horse_racing, prestige_multiple_weights),
            {Multiple,_} = common_tool:random_from_tuple_weights(MultipleList, 2),
            NewRacingInfo = RacingInfo#r_horse_racing{horse_type=HorseType, cur_hp=HP+?HP_ADDED_BY_BUY, multiple=Multiple};
        _ ->
            NewRacingInfo = RacingInfo#r_horse_racing{horse_type=HorseType, cur_hp=HP, multiple=1}
    end,
    update_horse_racing_info(NewRacingInfo),
    R2C = #m_horse_racing_get_toc{info=transformMyInfo(NewRacingInfo),op_type=OpType},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_GET, R2C).

do_horse_racing_operate_list({Unique, Module, Method, _DataIn, RoleID, PID, _Line}) ->
    RacingInfo = get_horse_racing_info(RoleID),
    #r_horse_racing{bless_horse_list=TBlessList, punish_horse_list=TPunishList} = RacingInfo,
    BlessHorseList = transformHorseList(TBlessList, asc),
    PunishHorseList = transformHorseList(TPunishList, desc),
    R2C = #m_horse_racing_operate_list_toc{bless_list=transformInfo(BlessHorseList), puninsh_list=transformInfo(PunishHorseList)},
    ?UNICAST_TOC(R2C).

%%==================
%% common functions
%%====================

persist_data() ->
    lists:foreach(
      fun(RacingInfo) ->
              db:dirty_write(?DB_HORSE_RACING_P, RacingInfo)
      end, get_update_info_list()),
    clear_update_info_list(),
    
    lists:foreach(
      fun(Reward) ->
              db:dirty_write(?DB_HORSE_RACING_REWARD_P, Reward)
      end, get_update_reward_list()),
    clear_update_reward_list(),
    
    db:dirty_write(?DB_HORSE_RACING_ALL_LOG_P, #r_horse_racing_all_log{log_list=get_all_operate_log()}),
    ok.

transformMyInfo(RacingInfo) ->
    #r_horse_racing{role_id=RoleID, horse_type=HorseType, bless_horse_list=BlessHorseList, punish_horse_list=PunishHorseList} = RacingInfo,
    PRacingInfo = transformInfo(RacingInfo),
    case db:dirty_read(?DB_ROLE_ATTR, RoleID) of
        [#p_role_attr{level=Level}] ->
            [#r_horse_config{base_exp_times=BaseExpTimes,reward_exp_multi=ExpMulti}] = 
                common_config_dyn:find(horse_racing, {horse, HorseType}),
            [{BlessTimes, PunishTimes, _}] = common_config_dyn:find(horse_racing, {vip, get_vip_level(RoleID)}),
            RemainBlessTimes = erlang:max(BlessTimes - erlang:length(BlessHorseList), 0),
            RemainPunishTimes = erlang:max(PunishTimes - erlang:length(PunishHorseList), 0),
            [LianqiExp] = common_config_dyn:find(lianqi, {exp, Level}),
            BaseRewardExp = common_tool:ceil(BaseExpTimes * LianqiExp + Level * ExpMulti),
            RewardPrestige = get_reward_prestige(Level, HorseType),
            PRacingInfo#p_horse_racing_info{reward_exp=BaseRewardExp, reward_prestige=RewardPrestige, reward_silver=0,
                                            remain_bless_times=RemainBlessTimes, remain_punish_times=RemainPunishTimes};
        _ ->
            PRacingInfo
    end.
transformInfo(RacingInfo) when erlang:is_record(RacingInfo, r_horse_racing) ->
    #r_horse_racing{role_id=RoleID, role_name=RoleName, faction_id=FactionID,
                    horse_type=Type, cur_hp=CurHP, status=Status, multiple=Multiple,
                    start_time=StartTime, end_time=EndTime, today_racing_times=TodayRacingTimes,
                    blessed_times=BlessedTimes, punished_times=PunishedTimes, system_operate_times=SystemOpTimes} = RacingInfo,
    [TotalRacingTimes] = common_config_dyn:find(horse_racing, race_times),
    #p_horse_racing_info{role_id=RoleID, role_name=RoleName, faction_id=FactionID, horse_type=Type, cur_hp=CurHP, status=Status,
                         start_time=StartTime, end_time=EndTime, blessed_times=BlessedTimes, punished_times=PunishedTimes,
                         system_operate_times=SystemOpTimes, remain_bless_times=0, remain_punish_times=0,
                         cur_racing_times=TodayRacingTimes, total_racing_times=TotalRacingTimes,multiple=Multiple};
transformInfo(InfoList) when erlang:is_list(InfoList) ->
    lists:map(fun(RacingInfo) -> transformInfo(RacingInfo) end, InfoList).

transformLog(LogInfo) when erlang:is_record(LogInfo, r_horse_racing_log) ->
    #r_horse_racing_log{op_type=OpType, source_role_id=SRoleID, source_faction_id=SFactionID, source_role_name=SRoleName,
                        target_role_id=TRoleID, target_faction_id=TFactionID, target_role_name=TRoleName, value=Value, timestamp=Timestamp} = LogInfo,
    #p_horse_racing_log{op_type=OpType, source_role_id=SRoleID, source_faction_id=SFactionID, source_role_name=SRoleName,
                        target_role_id=TRoleID, target_faction_id=TFactionID, target_role_name=TRoleName, value=Value, timestamp=Timestamp};
transformLog(LogInfoList) when erlang:is_list(LogInfoList) ->
    lists:map(fun(LogInfo) -> transformLog(LogInfo) end, LogInfoList).

transformHorseList(HorseList, SortType) ->
    transforHorseList_2(
      lists:foldl(
        fun(HorseID, Acc) ->
                RoleID = HorseID div 10000,
                Info = get_horse_racing_info(RoleID),
                if Info#r_horse_racing.status =:= ?STATUS_RACING andalso HorseID =:= Info#r_horse_racing.horse_id ->
                       [Info | Acc];
                   true ->
                       Acc
                end
        end, [], HorseList), SortType).

transforHorseList_2(HorseList, SortType) ->
    SortFun = 
        fun(#r_horse_racing{cur_hp=Hp1, horse_type=HorseType1}, #r_horse_racing{cur_hp=Hp2, horse_type=HorseType2}) -> 
                if HorseType1 > HorseType2 ->
                       true;
                   HorseType1 =:= HorseType2 andalso SortType =:= asc andalso Hp1 < Hp2 ->
                       true;
                   HorseType1 =:= HorseType2 andalso SortType =:= desc andalso Hp1 >= Hp2 ->
                       true;
                   true ->
                       false
                end
        end,
    lists:sort(SortFun, HorseList).

get_today_race_times(LastRaceDate, RaceTimes) ->
    case LastRaceDate =:= erlang:date() of
        true ->
            RaceTimes;
        _ ->
            0
    end.

get_reward_prestige(RoleLevel, HorseType) ->
    [RewardList] = common_config_dyn:find(horse_racing, presitge_reward),
    case lists:keyfind(HorseType, 1, RewardList) of
        false ->
            0;
        {HorseType, PrestigeList} ->
            lists:foldl(
              fun({MinRoleLevel, MaxRoleLevel, Prestige}, Acc) ->
                      if RoleLevel >= MinRoleLevel andalso MaxRoleLevel >= RoleLevel ->
                             Prestige;
                         true ->
                             Acc
                      end
              end, 0, PrestigeList)
    end.

log_operation(system, TargetInfo, OpType, Value) ->
    SourceInfo = #r_horse_racing{role_id=0, faction_id=0, role_name=undefined},
    log_operation(SourceInfo, TargetInfo, OpType, Value);
log_operation(SourceInfo, TargetInfo, OpType, Value) when OpType =:= ?OP_TYPE_SILVER_PUNISH 
                                                          orelse OpType =:= ?OP_TYPE_GOLD_PUNISH
                                                          orelse OpType =:= ?OP_TYPE_SYSTEM_PUNISH ->
    #r_horse_racing{role_id=SRoleID, faction_id=SFactionID, role_name=SRoleName, log_list=SLogList} = SourceInfo,
    #r_horse_racing{role_id=TRoleID, faction_id=TFactionID, role_name=TRoleName, log_list=TLogList, 
                    system_operate_times=SystemTimes, punished_list=TPunishedList, punished_times=PunishedTimes} = TargetInfo,
    Log = #r_horse_racing_log{key={TRoleID, common_tool:now_nanosecond()},
                              op_type=OpType,
                              source_role_id=SRoleID,
                              source_faction_id=SFactionID,
                              source_role_name=SRoleName,
                              target_role_id=TRoleID,
                              target_faction_id=TFactionID,
                              target_role_name=TRoleName,
                              value=Value,
                              timestamp=common_tool:now()},
    if SRoleID =:= 0 -> %% 奇遇
           NewTargetInfo = TargetInfo#r_horse_racing{system_operate_times=SystemTimes+1, log_list=append_role_log(Log,TLogList),
                                                     punished_list=[Log|TPunishedList]},
           NewSourceInfo = SourceInfo,
           update_horse_racing_info(NewTargetInfo);
       SRoleID =:= TRoleID ->
           NewSourceInfo = SourceInfo,
           NewTargetInfo = SourceInfo; %% 忽略对自己惩罚
       true ->
           NewTargetInfo = TargetInfo#r_horse_racing{punished_times=PunishedTimes+1, punished_list=[Log|TPunishedList],
                                                     log_list=append_role_log(Log,TLogList)},
           NewSourceInfo = SourceInfo#r_horse_racing{log_list=append_role_log(Log,SLogList)},
           update_horse_racing_info(NewTargetInfo),
           update_horse_racing_info(NewSourceInfo)
    end,
    update_all_operate_log(Log),
    broadcast_log_info(Log),
    {ok, NewSourceInfo, NewTargetInfo};
log_operation(SourceInfo, TargetInfo, OpType, Value) when OpType =:= ?OP_TYPE_SILVER_BLESS 
                                                          orelse OpType =:= ?OP_TYPE_GOLD_BLESS
                                                          orelse OpType =:= ?OP_TYPE_SYSTEM_BLESS ->
    #r_horse_racing{role_id=SRoleID, faction_id=SFactionID, role_name=SRoleName, log_list=SLogList} = SourceInfo,
    #r_horse_racing{role_id=TRoleID, faction_id=TFactionID, role_name=TRoleName, log_list=TLogList, 
                    system_operate_times=SystemTimes, blessed_list=TBlessedList, blessed_times=BlessedTimes} = TargetInfo,
    Log = #r_horse_racing_log{key={TRoleID, common_tool:now_nanosecond()},
                              op_type=OpType,
                              source_role_id=SRoleID,
                              source_faction_id=SFactionID,
                              source_role_name=SRoleName,
                              target_role_id=TRoleID,
                              target_faction_id=TFactionID,
                              target_role_name=TRoleName,
                              value=Value,
                              timestamp=common_tool:now()},
    if SRoleID =:= 0 -> %% 奇遇
           NewTargetInfo = TargetInfo#r_horse_racing{system_operate_times=SystemTimes+1, log_list=append_role_log(Log, TLogList),
                                                     blessed_list=[Log|TBlessedList]},
           NewSourceInfo = SourceInfo,
           update_horse_racing_info(NewTargetInfo);
       SRoleID =:= TRoleID ->
           NewTargetInfo = TargetInfo#r_horse_racing{blessed_times=BlessedTimes+1, blessed_list=[Log|TBlessedList],
                                                     log_list=append_role_log(Log,TLogList)},
           NewSourceInfo = NewTargetInfo,
           update_horse_racing_info(NewTargetInfo);
       true ->
           NewTargetInfo = TargetInfo#r_horse_racing{blessed_times=BlessedTimes+1, blessed_list=[Log|TBlessedList],
                                                     log_list=append_role_log(Log,TLogList)},
           NewSourceInfo = SourceInfo#r_horse_racing{log_list=append_role_log(Log,SLogList)},
           update_horse_racing_info(NewTargetInfo),
           update_horse_racing_info(NewSourceInfo)
    end,
    update_all_operate_log(Log),
    broadcast_log_info(Log),
    {ok, NewSourceInfo, NewTargetInfo}.

log_my_operation(SourceInfo, OpType) ->
    #r_horse_racing{role_id=SRoleID, faction_id=SFactionID, role_name=SRoleName, log_list=SLogList} = SourceInfo,
    Log = #r_horse_racing_log{key={SRoleID, common_tool:now_nanosecond()},
                              op_type=OpType,
                              source_role_id=SRoleID,
                              source_faction_id=SFactionID,
                              source_role_name=SRoleName,
                              target_role_id=SRoleID,
                              target_faction_id=SFactionID,
                              target_role_name=SRoleName,
                              timestamp=common_tool:now()},
    NewSourceInfo = SourceInfo#r_horse_racing{log_list=append_role_log(Log,SLogList)},
    update_horse_racing_info(NewSourceInfo),
    update_all_operate_log(Log),
    broadcast_log_info(Log),
    {ok, NewSourceInfo}.

notify_role_to_fetch_reward(RoleID, Reward) when erlang:is_record(Reward, r_horse_racing_reward)->
    #r_horse_racing_reward{acc_reward_exp=RewardExp} = Reward,
    notify_role_to_fetch_reward(RoleID, RewardExp);
notify_role_to_fetch_reward(RoleID, RewardExp) when RewardExp > 0 ->
    case is_in_enter_role_list(RoleID) of
        true ->
            R2C = #m_horse_racing_reward_notice_toc{exp=RewardExp, presitge=0, silver=0},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_REWARD_NOTICE, R2C);
        _ ->
            ignore
    end;
notify_role_to_fetch_reward(_, _) ->
    ignore.

broadcast_log_info(Log) ->
    #r_horse_racing_log{source_role_id=SRoleID, target_role_id=TRoleID} = Log,
    if SRoleID =:= 0 -> %% 奇遇
           R2C = #m_horse_racing_log_toc{my_logs=transformLog([Log]), all_logs=[]},
           broadcast_log_info(R2C, [TRoleID]);
       SRoleID =:= TRoleID ->
           R2C = #m_horse_racing_log_toc{my_logs=transformLog([Log]), all_logs=transformLog([Log])},
           broadcast_log_info(R2C, [TRoleID]),
           R2AllC = #m_horse_racing_log_toc{my_logs=[], all_logs=transformLog([Log])},
           broadcast_log_info(R2AllC, lists:delete(TRoleID, get_enter_role_id_list()));
       true ->
           R2C = #m_horse_racing_log_toc{my_logs=transformLog([Log]), all_logs=transformLog([Log])},
           broadcast_log_info(R2C, [TRoleID, SRoleID]),
           R2AllC = #m_horse_racing_log_toc{my_logs=[], all_logs=transformLog([Log])},
           broadcast_log_info(R2AllC, get_enter_role_id_list(), [TRoleID, SRoleID])
    end.

broadcast_log_info(R2C, RoleIDList) ->
    broadcast_log_info(R2C, RoleIDList, []).

broadcast_log_info(R2C, RoleIDList, ExCludeList) ->
    lists:foreach(
      fun(RoleID) -> 
              case (not lists:member(RoleID, ExCludeList) andalso is_in_enter_role_list(RoleID)) of
                  true ->
                      common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HORSE_RACING, ?HORSE_RACING_LOG, R2C);
                  false ->
                      ignore
              end
      end, RoleIDList).                            

calc_max_page([]) ->
    1;
calc_max_page(AllRacingList) ->
    [PageSize] = common_config_dyn:find(horse_racing, page_size),
    common_tool:ceil(erlang:length(AllRacingList) / PageSize).

%% 当玩家在钦点美人界面时，vip等级是最新的
get_vip_level(RoleID) ->
    case lists:keyfind(RoleID, 1, get_enter_role_list()) of
        false ->
            0;
        {RoleID, VipLevel} ->
            VipLevel
    end.

%% 不在界面时，考虑到vip不是经常变化，简单处理，直接读取P表
get_vip_level_ex(RoleID) ->
    case is_in_enter_role_list(RoleID) of
        true ->
            get_vip_level(RoleID);
        _ ->
            mod_vip:get_dirty_role_vip_level(RoleID)
    end.

append_role_log(Log, LogList) ->
    [{PersonalLogNum,_}] = common_config_dyn:find(horse_racing, log_num),
    lists:sublist([Log|LogList], PersonalLogNum).

%% 将同一玩家的护体或惩罚数值累加为一条
merge_log(LogList) ->
    lists:foldl(
      fun(#r_horse_racing_log{source_role_id=RoleID, value=Value}=Log, MergeList) ->
              if RoleID =:= 0 ->
                     MergeList;
                 true ->
                     case lists:keyfind(RoleID, #r_horse_racing_log.source_role_id, MergeList) of
                         false ->
                             [Log | MergeList];
                         #r_horse_racing_log{value=MValue}=MLog ->
                             lists:keystore(RoleID, #r_horse_racing_log.source_role_id, MergeList, MLog#r_horse_racing_log{value=MValue+Value})
                     end
              end
      end, [], LogList).

send_succ_letter(RoleID, RewardExp, _Yueli, BlessList, PunishList) ->
    Title = "钦点美人领奖通知",
    Text1 = "尊敬的玩家：\n      恭喜您在本次钦点美人中经历重重困难，钦点美人成功！\n",
    case BlessList =:= [] of
        true ->
            Text2 = "";
        _ ->
            Text2 = "      对您祝福的玩家：" ++ lists:map(fun(#r_horse_racing_log{source_role_name=RoleName}) -> "<font color=\"#07ff00\">" ++ erlang:binary_to_list(RoleName) ++ "</font>，" end, BlessList) ++ "\n"
    end,
    case PunishList =:= [] of
        true ->
            Text3 = "";
        _ ->
            Text3 = "      对你拦截的玩家：" ++ lists:map(fun(#r_horse_racing_log{source_role_name=RoleName}) -> "<font color=\"#ff0000\">" ++ erlang:binary_to_list(RoleName) ++ "</font>，" end, PunishList) ++ "\n"
    end,
    Text4 = "      获得奖励：~w经验\n      请到钦点美人界面，点击<font color=\"#fbfe00\">【领取奖励】</font>获取您的奖励。",
    Text = common_misc:format_lang(lists:concat([Text1, Text2, Text3, Text4]), [RewardExp]),
    common_letter:sys2p(RoleID,common_tool:to_binary(Text),Title).

send_other_succ_letter(RoleName, OtherRoleID, BlessPercentage, RewardExp) ->
    Title = "钦点美人领奖通知",
    Text1 = "尊敬的玩家：\n      感谢您对<font color=\"#07ff00\">~s</font>的美人进行祝福，为其保驾护航，<font color=\"#07ff00\">~s</font>钦点美人成功！\n",
    Text2 = "      祝福加血比例：~.2f%，\n      获得奖励：~w经验，\n      请到钦点美人界面，点击<font color=\"#fbfe00\">【领取奖励】</font>获取您的奖励。",
    Text = common_misc:format_lang(lists:concat([Text1, Text2]), [RoleName, RoleName, BlessPercentage*100, RewardExp]),
    common_letter:sys2p(OtherRoleID,common_tool:to_binary(Text),Title).

send_failed_letter(RoleID, RewardExp, BlessList, PunishList) ->
    Title = "钦点美人领奖通知",
    Text1 = "尊敬的玩家：\n      您在本次钦点美人中受到敌人的袭击，很遗憾钦点美人失败！\n",
    case PunishList =:= [] of
        true ->
            Text2 = "";
        _ ->
            Text2 = "      对你拦截的玩家：" ++ lists:map(fun(#r_horse_racing_log{source_role_name=RoleName}) -> "<font color=\"#ff0000\">" ++ erlang:binary_to_list(RoleName) ++ "</font>，" end, PunishList) ++ "\n"
    end,
    case BlessList =:= [] of
        true ->
            Text3 = "";
        _ ->
            Text3 = "      对您祝福的玩家：" ++ lists:map(fun(#r_horse_racing_log{source_role_name=RoleName}) -> "<font color=\"#07ff00\">" ++ erlang:binary_to_list(RoleName) ++ "</font>，" end, BlessList) ++ "\n"
    end,
    Text4 = "      获得奖励：~w经验，\n      请到钦点美人界面，点击<font color=\"#fbfe00\">【领取奖励】</font>获取您的奖励。",
    Text = common_misc:format_lang(lists:concat([Text1, Text2, Text3, Text4]), [RewardExp]),
    common_letter:sys2p(RoleID,common_tool:to_binary(Text),Title).

send_other_failed_letter(RoleName, OtherRoleID, PunishPercentage, RewardExp) ->
    Title = "钦点美人领奖通知",
    Text1 = "尊敬的玩家：\n      您对<font color=\"#ff0000\">~s</font>的美人进行拦截，狙击成功，<font color=\"#ff0000\">~s</font>的钦点美人失败！\n",
    Text2 = "      拦截减血比例：~.2f%，\n      获得奖励：~w经验，\n      请到钦点美人界面，点击<font color=\"#fbfe00\">【领取奖励】</font>获取您的奖励。",
    Text = common_misc:format_lang(lists:concat([Text1, Text2]), [RoleName, RoleName, PunishPercentage*100, RewardExp]),
    common_letter:sys2p(OtherRoleID,common_tool:to_binary(Text),Title).

%% fix_prestige(Num) ->
%%     erlang:max(Num, 10).

send_warning_letter(Info) ->
    #r_horse_racing{role_id=RoleID, cur_hp=HP} = Info,
    Title = "钦点美人提醒",
    Text1 = "      您还有<font color=\"#ff0000\">5分钟</font>结束钦点美人，现在美人魅力值为<font color=\"#ff0000\">~w</font>，请慎防受到敌人的拦截而<font color=\"#ff0000\">失败</font>哦！",
    Text = common_misc:format_lang(Text1, [HP]),
    common_letter:sys2p(RoleID,common_tool:to_binary(Text),Title).
