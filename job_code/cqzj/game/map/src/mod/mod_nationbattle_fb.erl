%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     国家战场（上古战场）
%%% @end
%%% Created : 2011-6-16
%%%-------------------------------------------------------------------
-module(mod_nationbattle_fb).

-include("mgeem.hrl").

-export([
         handle/1,
         handle/2
        ]).

-export([
         init/2,
         loop/2,
         is_fb_map_id/1,
         is_in_fb_map/0,
         check_map_fight/2,
         get_relive_home_pos/2,
         assert_valid_map_id/1,
         get_map_name_to_enter/1,
         clear_map_enter_tag/1,
		 do_fb_open_process_broadcast/2,
		 do_static_broadcast/1
        ]).
-export([
         hook_role_quit/1,hook_role_before_quit/1,
         hook_role_enter/2,
         hook_role_dead/3
        ]).

-export([
         gm_open_battle/1,
         gm_close_battle/0,
         gm_reset_open_times/0
        ]).

%% ====================================================================
%% Macro
%% ====================================================================
-define(NATIONBATTLE_MAP_ID,10501).
-define(BATTLE_RANK_LEN,5).
-define(CALC_UNION_INTERVAL,30*1000).   %%如果系统没有结盟，则每30秒判断是否符合结盟条件
-define(TRANSFER_SCROLL_TYPEID, 10100001).  %%传送卷
-define(NATIONBATTLE_MAP_NAME_TO_ENTER,nationbattle_map_name_to_enter).
-define(DEFAULT_SPLIT_JINGJIE,205). %%默认是五等武林新秀
-define(NATIONBATTLE_ENTRANCE_INFO,nationbattle_entrance_info).
-define(NATIONBATTLE_SUB_ENTRANCE_INFO,nationbattle_sub_entrance_info).

%% 加经验间隔
-define(INTERVAL_EXP_LIST, interval_exp_list).

-define(NATIONBATTLE_MAP_INFO,nationbattle_map_info).
-define(NATIONBATTLE_TIME_DATA,nationbattle_time_data).
-define(NATIONBATTLE_ROLE_INFO,nationbattle_role_info).
-define(ENTER_TYPE_VIP, 2).

%% slave_num: 已经开启的子战场的个数
%% split_jingjie: 按境界分流的境界值
-record(r_nationbattle_entrance_info,{is_opening=false,slave_num=0,split_time_idx=0,split_jingjie=?DEFAULT_SPLIT_JINGJIE}).
-record(r_nationbattle_sub_entrance_info,{all_role_num=0,faction_role_num=[0,0,0]}).

-record(r_nationbattle_map_info,{is_opening=false,slave_num=0,my_slave_map_idx=0,split_time_idx=0,split_jingjie=?DEFAULT_SPLIT_JINGJIE,
                                 faction_role_num=[0,0,0],
                                 role_num=0,max_role_num=0,score_list=[],rank_data=[],
                                 union_nation=[],union_scores=[0,0,0],last_union_time=0}).
            %%union_nation 神农列表
            %%score_list   所有人的积分列表（>0的积分）
            %%rank_data    当前的杀戮榜结果，每次积分列表更新之后，会相应更新这个排序结果
-record(r_nationbattle_time,{date = 0,start_time = 0,end_time = 0,
                                 next_bc_start_time = 0,next_bc_end_time = 0,next_bc_process_time = 0,
                                 before_interval = 0,close_interval = 0,process_interval = 0,
                                 kick_role_time = 0}).
-record(r_nationbattle_role_info,{killer_list=[]}).  %%每个玩家的杀戮信息
            %%killer_list 杀死本玩家的仇人时间/列表

-define(CHANGE_TYPE_MY_SCORE,1).    %%更新类型：1=my_score,2=my_kill_num,3[my_score,my_kill_num],4[三个势力的杀戮值]
-define(CHANGE_TYPE_MY_KILL_NUM,2).
-define(CHANGE_TYPE_MY_SCORE_AND_KILL,3).
-define(CHANGE_TYPE_UNION_NATION,4).
-define(CONFIG_NAME,nationbattle).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

%% 对应的活动ID, 与activity_today.config里的一致
-define(NATIONBATTLE_ACTIVITY_ID,10019).


%% ====================================================================
%% Error Code
%% ====================================================================

-define(ERR_NATIONBATTLE_DISABLE,10999).
-define(ERR_NATIONBATTLE_ENTER_CLOSING,10001).
-define(ERR_NATIONBATTLE_ENTER_LV_LIMIT,10002).
-define(ERR_NATIONBATTLE_ENTER_FB_LIMIT,10003).
-define(ERR_NATIONBATTLE_ENTER_IN_BATTLE,10004).
-define(ERR_NATIONBATTLE_ENTER_MAX_ROLE_NUM,10005).
-define(ERR_NATIONBATTLE_ENTER_TITLE_LIMIT,10006).
-define(ERR_NATIONBATTLE_ENTER_SPLIT_LIMIT,10007).
-define(ERR_NATIONBATTLE_QUIT_NOT_IN_MAP,11001).
-define(ERR_NATIONBATTLE_TRNASFER_YOU_NOT_IN_BATTLE,11002).
-define(ERR_NATIONBATTLE_TRNASFER_HIM_NOT_IN_BATTLE,11003).
-define(ERR_NATIONBATTLE_TRNASFER_NUM_NOT_ENOUGH,11004).
-define(ERR_NATIONBATTLE_REWARD_HAS_FETCHED,11005).
-define(ERR_NATIONBATTLE_REWARD_NO_REWARDS,11006).
-define(ERR_NATIONBATTLE_REWARD_NOT_ENOUGH_POS,11007).
-define(ERR_NATIONBATTLE_ENTER_VIP_LIMIT,11008).


-define(BROADCAST_CENTER_MSG(Message),
		common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_SUB_TYPE,Message)).
-define(BROADCAST_CHAT_MSG(Message),
		common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,Message)).


%% ====================================================================
%% API functions
%% ====================================================================

handle(Info,_State) ->
    handle(Info).
 %% 战场内的传送

handle({_, ?NATIONBATTLE, ?NATIONBATTLE_TRANSFER,_,_,_,_}=Info) ->
    do_nationbattle_transfer(Info);

handle({_, ?NATIONBATTLE, ?NATIONBATTLE_ENTER,_,_,_,_}=Info) ->
    %% 进入国家战场
    do_nationbattle_enter(Info);
handle({_, ?NATIONBATTLE, ?NATIONBATTLE_QUIT,_,_,_,_}=Info) ->
    %% 退出国家战场
    do_nationbattle_quit(Info);

handle({_, ?NATIONBATTLE, ?NATIONBATTLE_REWARD,_,_,_,_}=Info) ->
    %% 查询奖励
    do_nationbattle_reward(Info);
handle({_, ?NATIONBATTLE, ?NATIONBATTLE_FETCH_REWARD,_,_,_,_}=Info) ->
    %% 领取奖励
    do_nationbattle_fetch_reward(Info);
  
handle({open_slave_nationbattle,SlaveMapIdx,SlaveNum,IsOpen}) ->
    do_open_slave_nationbattle(SlaveMapIdx,SlaveNum,IsOpen);  
handle({update_slave_nationbattle_timedata,SlaveMapIdx,TimeData}) ->
    do_update_slave_nationbattle_timedata(SlaveMapIdx,TimeData);  

handle({req_nationbattle_entrance_info}) ->
    do_req_nationbattle_entrance_info();
handle({req_nationbattle_sub_entrance_info}) ->
    do_req_nationbattle_sub_entrance_info();
handle({init_nationbattle_entrance_info,EntranceInfo}) ->
    do_init_nationbattle_entrance_info(EntranceInfo);
handle({update_nationbattle_entrance_info,ValList}) ->
    do_update_nationbattle_entrance_info(ValList);
handle({syn_nationbattle_sub_entrance_info,BattleMapIdx,SubEntranceInfo}) ->
    do_syn_nationbattle_sub_entrance_info(BattleMapIdx,SubEntranceInfo);

handle({calc_battle_union}) ->
    do_calc_battle_union();
handle({split_battle_time_banlance}) ->
    do_split_battle_time_banlance();
handle({gm_reset_open_times}) ->
    reset_battle_open_times();
handle({gm_open_battle, Second}) ->
    case is_opening_battle() of
        true->
            ignore;
        _ ->
            gm_open_nationbattle(Second)
    end;
handle({gm_close_battle}) ->
    case is_opening_battle() of
        true->
            TimeData = get_nationbattle_time_data(),
            TimeData2 = TimeData#r_nationbattle_time{end_time=common_tool:now()},
            put(?NATIONBATTLE_TIME_DATA,TimeData2),
            
            case get_nationbattle_map_info() of
                #r_nationbattle_map_info{slave_num=SlaveNum}->
                        update_slave_nationbattle_timedata(SlaveNum,TimeData2);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end;

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).


init(MapId, MapName) ->
    case is_fb_map_id(MapId) of
        true->
            case MapName =:= common_map:get_common_map_name(MapId) of
                true->
                    MySlaveMapIdx = 0; %%0表示Master进程
                _ ->
                    MySlaveMapIdx = 1
            end,
            BattleMapInfo = #r_nationbattle_map_info{is_opening=false,my_slave_map_idx=MySlaveMapIdx,role_num=0,max_role_num=0,rank_data=[]},
            set_nationbattle_map_info(BattleMapInfo),
			[StartStaticBcTimeList] = common_config_dyn:find(?CONFIG_NAME, nationbattle_start_static_bc_time),
			[StopStaticBcTimeList] = common_config_dyn:find(?CONFIG_NAME, nationbattle_stop_static_bc_time),
			set_nationbattle_start_static_bc_time(StartStaticBcTimeList),
			set_nationbattle_stop_static_bc_time(StopStaticBcTimeList),
            reset_battle_open_times(),
            ok;
        _ ->
            ignore
    end.

loop_static_broadcast(NowSeconds,Record) ->
	#r_nationbattle_time{start_time = StartTime} = Record,
	{StateDate,_} = common_tool:seconds_to_datetime(StartTime),
	{Date, _} = erlang:localtime(),
	if
		StateDate =:= Date ->
			do_static_broadcast(NowSeconds,StartTime);
		true->
			ingore
	end.

do_static_broadcast(NowSeconds,StartTime) ->
	case get_ationbattle_start_static_bc_time() of
		undefined ->
			ingore;
		BcTimeList when is_list(BcTimeList)->
			lists:foreach(fun(StaticBcTime) ->
								  {Day,_} = erlang:localtime(),
								  StaticSecond = common_tool:datetime_to_seconds({Day,StaticBcTime}),
								  do_static_broadcast(NowSeconds,StaticSecond,StartTime,start)
						  end, BcTimeList)
	end.

do_static_broadcast(NowSeconds,StaticBcTime,StartTime,start)->
	if 
		NowSeconds =/= 0 andalso StaticBcTime =/= 0 
			andalso NowSeconds =:= StaticBcTime ->
			MinRoleLevelStr = get_fb_min_role_level_str(),
			BeforeMessage = 
				case StartTime>NowSeconds of 
					true->
						{_Date,Time} = common_tool:seconds_to_datetime(StartTime),
						StartTimeStr = common_time:time_string(Time),
						common_misc:format_lang(?_LANG_NATIONBATTLE_PRESTART,[StartTimeStr,MinRoleLevelStr]);
					_ ->
						common_misc:format_lang(?_LANG_NATIONBATTLE_STARTED,[MinRoleLevelStr])
				end,
			catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,BeforeMessage),
			?BROADCAST_CENTER_MSG(BeforeMessage);
		true ->
			ignore
	end;



do_static_broadcast(_,_,_,_) ->
	ignore.
	
do_static_broadcast({_StaticBcTime,stop})->
	catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,?_LANG_NATIONBATTLE_STATIC_STOP_BROADCAST_MSG),
	?BROADCAST_CENTER_MSG(?_LANG_NATIONBATTLE_STATIC_STOP_BROADCAST_MSG).	
set_nationbattle_start_static_bc_time(BcTimeList)->
	put(nationbattle_start_static_bc_time,BcTimeList).

get_ationbattle_start_static_bc_time() ->
	get(nationbattle_start_static_bc_time).
			
set_nationbattle_stop_static_bc_time(BcTimeList)->
	put(nationbattle_stop_static_bc_time,BcTimeList).

get_nationbattle_stop_static_bc_time() ->
	get(nationbattle_stop_static_bc_time).

	
get_nationbattle_entrance_info()->
    get(?NATIONBATTLE_ENTRANCE_INFO).

get_nationbattle_sub_entrance_info(BattleMapIdx)->
    get({?NATIONBATTLE_SUB_ENTRANCE_INFO,BattleMapIdx}).

set_nationbattle_sub_entrance_info(BattleMapIdx,SubEntranceInfo)->
    put({?NATIONBATTLE_SUB_ENTRANCE_INFO,BattleMapIdx},SubEntranceInfo).

get_nationbattle_time_data()->
    get(?NATIONBATTLE_TIME_DATA).
set_nationbattle_time_data(TimeData2)->
    put(?NATIONBATTLE_TIME_DATA,TimeData2).

get_nationbattle_role_info(RoleID)->
    get({?NATIONBATTLE_ROLE_INFO,RoleID}).
set_nationbattle_role_info(RoleID,BattleRoleInfo)->
    put({?NATIONBATTLE_ROLE_INFO,RoleID},BattleRoleInfo).

get_nationbattle_map_info()->
    get(?NATIONBATTLE_MAP_INFO).
set_nationbattle_map_info(BattleMapInfo)->
    put(?NATIONBATTLE_MAP_INFO,BattleMapInfo).

loop(_MapId,NowSeconds) ->
    case get_nationbattle_time_data() of
        #r_nationbattle_time{date=Date} = NationBattleTimeData ->
            case Date =:= erlang:date() of
                true->
                    loop_2(NowSeconds,NationBattleTimeData);
                _->
                    ignore
            end;
        _ ->
            ignore
    end.
loop_2(NowSeconds,NationBattleTimeData)->
    case ?find_config(enable_nationbattle) of
        [true]->
            case is_opening_battle() of
                true->
                    loop_opening(NowSeconds,NationBattleTimeData);
                _ ->
                    loop_closing(NowSeconds,NationBattleTimeData)
            end;
        _ ->
            ignore
    end.

get_battle_reward_money(Order,RoleLevel)->
	[RewardSilverBase] = ?find_config(reward_silver_base),
	[RewardSilverOrderFactor] = ?find_config(reward_silver_order_factor),
	case get_val_config_by_order(Order,RewardSilverOrderFactor) of
		0->
			RewardSilverBase;
		Val when Val>0->
			RewardSilverBase + RoleLevel*Val div 10
	end.

get_battle_reward_title(Order) ->
    [RewardPropOrderFactor] = ?find_config(reward_title_order_factor),
    case get_val_config_by_order(Order,RewardPropOrderFactor) of
        0->
            0;
        Val when Val>0->
            Val
    end.

get_battle_reward_prop(Order)->
    [RewardPropOrderFactor] = ?find_config(reward_prop_order_factor),
    case get_val_config_by_order(Order,RewardPropOrderFactor) of
        0->
            0;
        Val when Val>0->
            Val
    end.

get_val_config_by_order(_,[])->
    0;
get_val_config_by_order(Order,[H|T])->
    {MinOrder,MaxOrder,Val} = H,
    if
        Order>=MinOrder andalso MaxOrder>=Order ->
            Val;
        true->
            get_val_config_by_order(Order,T)
    end.

loop_opening(NowSeconds,NationBattleTimeData)->
    #r_nationbattle_time{end_time=EndTime} = NationBattleTimeData,
    %% 副本开启过程中广播处理
    do_fb_open_process_broadcast(NowSeconds,NationBattleTimeData),
    loop_static_broadcast(NowSeconds,NationBattleTimeData),
    if
        EndTime>0 andalso NowSeconds>=EndTime->
			?TRY_CATCH( do_battle_fb_log() ),
            {ok,NextStartTimeSeconds} = reset_battle_open_times(),

            %% 关闭副本
            close_nationbattle(NextStartTimeSeconds),
            %% 活动关闭消息的提示
            common_activity:notfiy_activity_end(?NATIONBATTLE_ACTIVITY_ID),
            ok;
        true->
            %% 加经验循环
            case ?find_config(fb_add_exp) of
                [{true,_}]->
                    do_add_exp_interval(NowSeconds);
                _ ->
                    ignore
            end,
            
            %%提前关闭广播
            ignre
    end.


loop_closing(NowSeconds,NationBattleTimeData)->
    #r_nationbattle_time{start_time=StartTime, end_time=EndTime} = NationBattleTimeData,
    if
        StartTime>0 andalso NowSeconds>=StartTime->
            open_nationbattle();
        true->
            %% 活动开始消息通知
            common_activity:notfiy_activity_start({?NATIONBATTLE_ACTIVITY_ID, NowSeconds, StartTime, EndTime}),
            %%提前开始广播
            do_fb_open_before_broadcast(NowSeconds,NationBattleTimeData)
    end.

assert_valid_map_id(DestMapID)->
    case is_fb_map_id(DestMapID) of
        true->
            ok;
        _ ->
            ?ERROR_MSG("严重，试图进入错误的地图,DestMapID=~w",[DestMapID]),
            throw({error,error_map_id,DestMapID})
    end.

is_fb_map_id(DestMapId)->
    ?NATIONBATTLE_MAP_ID =:= DestMapId.

%% @doc 获取复活的回城点
get_relive_home_pos(RoleMapInfo, MapID) when is_record(RoleMapInfo,p_map_role)->
    #p_map_role{faction_id=FactionID} = RoleMapInfo,
    {TX,TY} = get_fb_born_points(FactionID),
    {MapID, TX, TY}.

%%@doc 得到战场的出生点
%%@return   {Tx,Ty}
get_fb_born_points(FactionId) when is_integer(FactionId)->
     [FbBornPoints] = ?find_config(fb_born_points),
     {_,FactionBornList} = lists:keyfind(FactionId, 1, FbBornPoints),
     common_tool:random_element(FactionBornList).

get_fb_map_name() ->
    common_map:get_common_map_name( ?NATIONBATTLE_MAP_ID ).

is_in_fb_map()->
    case get(?NATIONBATTLE_MAP_INFO) of
        #r_nationbattle_map_info{}->
            true;
        _ ->
            false
    end.

check_map_fight(RoleID,TargetRoleID)->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{is_opening=true,union_nation=UnionNation}->
            case mod_map_role:get_role_base(RoleID) of
                {ok,#p_role_base{faction_id=RoleFaction}}->
                    case mod_map_role:get_role_base(TargetRoleID) of
                        {ok,#p_role_base{faction_id=TargetRoleFaction}}->
                            check_map_fight_2(RoleFaction,TargetRoleFaction,UnionNation);
                        _ ->
                            {error, ?_LANG_SYSTEM_ERROR}
                    end;
                _ ->
                    {error, ?_LANG_SYSTEM_ERROR}
            end;
        #r_nationbattle_map_info{is_opening=false}->
            {error, ?_LANG_NATIONBATTLE_FIGHT_FB_CLOSED};
        _ ->
            true
    end.
check_map_fight_2(RoleFaction,TargetRoleFaction,UnionNation)->
    case RoleFaction=:=TargetRoleFaction of
        true->
            {error, ?_LANG_NATIONBATTLE_FIGHT_SAME_FACTION};
        _ ->
            case is_list(UnionNation) andalso length(UnionNation)>0
                     andalso lists:member(RoleFaction, UnionNation)
                     andalso lists:member(TargetRoleFaction, UnionNation) of
                true->
                    {error, ?_LANG_NATIONBATTLE_FIGHT_UNION_NATION};
                _ ->
                    true
            end
    end.

%% 玩家跳转进入战场地图进程
get_map_name_to_enter(RoleId)->
    case get({?NATIONBATTLE_MAP_NAME_TO_ENTER,RoleId}) of
        {_Today,FbMapProcessName,_SlaveMapIdx}->
            FbMapProcessName;
        _ ->
            undefined
    end.

clear_map_enter_tag(_RoleId)->
    ignore.

set_map_enter_tag(RoleID,BattleMapName,SlaveMapIdx)->
    Today = erlang:date(),
    Val = {Today,BattleMapName,SlaveMapIdx},
    put({?NATIONBATTLE_MAP_NAME_TO_ENTER,RoleID},Val).


hook_role_enter(RoleID,_MapID)->
   case get_nationbattle_map_info() of
       #r_nationbattle_map_info{}=BattleMapInfo->
           hook_role_enter_2(RoleID,BattleMapInfo);
       _ ->
           ignore
   end.
hook_role_enter_2(RoleID,BattleMapInfo)->
    case BattleMapInfo of
        #r_nationbattle_map_info{is_opening=true,role_num=CurRoleNum,max_role_num=MaxRoleNum,
                                 split_jingjie=SplitJingjie,
                                 my_slave_map_idx=MySlaveMapIdx,
                                 faction_role_num=FactionRoleNumList,
                                 union_nation=UnionNation,union_scores=UnionScores, score_list=ScoreList,rank_data=RankData}->
            mod_role2:modify_pk_mode_for_role(RoleID,?PK_FACTION),
            NewRoleNum = CurRoleNum+1,
			NewMaxRoleNum = erlang:max(MaxRoleNum,NewRoleNum),
            %%同步入口信息
            
            FactionId = get_role_faction_id(RoleID),
            NewFactionRoleNumList = get_new_faction_role_num_list(enter,FactionRoleNumList,FactionId),
            
            syn_nationbattle_sub_entrance_info(MySlaveMapIdx,NewRoleNum,NewFactionRoleNumList),
            
            set_nationbattle_map_info(BattleMapInfo#r_nationbattle_map_info{role_num=NewRoleNum,max_role_num=NewMaxRoleNum,
                                                                              faction_role_num=NewFactionRoleNumList}),
            
            %%确认境界分流
            case mod_map_role:get_role_attr(RoleID) of
                {ok,#p_role_attr{jingjie=RoleJingjie}}->
                    assert_split_jingjie(MySlaveMapIdx,RoleJingjie,SplitJingjie);
                _ ->
                    next
            end,
            
            %%发送副本的信息
            case get_nationbattle_time_data() of
                #r_nationbattle_time{start_time = StartTime,end_time = EndTime} ->
                    next;
                _ ->
                    StartTime = 0,EndTime = 0
            end,
            case lists:keyfind(RoleID, #p_nationbattle_rank.role_id, ScoreList) of
                #p_nationbattle_rank{score=MyScore,kill_num=MyKillNum} ->
                    ok;
                _ ->
                    MyScore = 0, MyKillNum=0
            end,
            %% 插入加经验列表
            insert_interval_exp_list(RoleID),
            add_rank_battle_buffs(RoleID,RankData),

            %% 完成活动
            hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_NATION_BATTLE),

            R1 = #m_nationbattle_info_toc{change_type=1,
                                          union_nation=UnionNation,union_scores=UnionScores,
                                          fb_start_time=StartTime,fb_end_time=EndTime,
                                          my_score=MyScore,my_kill_num=MyKillNum},
            R2 = #m_nationbattle_rank_toc{ranks=RankData},
            
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?NATIONBATTLE, ?NATIONBATTLE_ENTER, #m_nationbattle_enter_toc{}),
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?NATIONBATTLE, ?NATIONBATTLE_INFO, R1),
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?NATIONBATTLE, ?NATIONBATTLE_RANK, R2),
            ok;
        _ ->
            do_nationbattle_quit_2(RoleID),
            ?ERROR_MSG("副本关闭了，还有人进来！RoleID=~w",[RoleID])
    end.
hook_role_quit(RoleID)->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{is_opening=true,my_slave_map_idx=BattleMapIdx,role_num=CurRoleNum,faction_role_num=FactionRoleNumList}=MapInfo->
            NewRoleNum = CurRoleNum-1,
            FactionId = get_role_faction_id(RoleID),
            NewFactionRoleNumList = get_new_faction_role_num_list(quit,FactionRoleNumList,FactionId),
            
            syn_nationbattle_sub_entrance_info(BattleMapIdx,NewRoleNum,NewFactionRoleNumList),
            
            set_nationbattle_map_info(MapInfo#r_nationbattle_map_info{role_num=NewRoleNum,
                                                                      faction_role_num=NewFactionRoleNumList}),
            delete_battle_buffs(RoleID),
            %% 移出加经验列表
            delete_interval_exp_list(RoleID),
            ok;
        #r_nationbattle_map_info{}->
            delete_battle_buffs(RoleID);
        _ ->
            ignore
    end.

hook_role_before_quit(RoleID)->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{}->
            delete_battle_buffs(RoleID);
        _ ->
            ignore
    end.

%%@doc 增加排行榜上的战场BUFF
add_rank_battle_buffs(_RoleID,[])->
    ignore;
add_rank_battle_buffs(RoleID,RankData)->
    case lists:keyfind(RoleID, #p_nationbattle_rank.role_id, RankData) of
        false->
            ignore;
        _ ->
            [BattleTopBuffId] = ?find_config( battle_top_buff_id),
            mod_role_buff:add_buff(RoleID,BattleTopBuffId)
    end.

%%退出地图的时候，删掉该玩家对应的战场BUFF
delete_battle_buffs(RoleID)->
    [BattleBuffId] = ?find_config(battle_top_buff_id),
    mod_pve_fb:remove_pve_fb_buffs(RoleID, [BattleBuffId]),
    ok.

%%更新各国家人员总数
get_new_faction_role_num_list(enter,FactionRoleNumList,FactionId)->
    [N1,N2,N3] = FactionRoleNumList,
    case FactionId of
        1-> [N1+1,N2,N3];
        2-> [N1,N2+1,N3];
        3-> [N1,N2,N3+1]
    end;
get_new_faction_role_num_list(quit,FactionRoleNumList,FactionId)->
    [N1,N2,N3] = FactionRoleNumList,
    case FactionId of
        1-> [N1-1,N2,N3];
        2-> [N1,N2-1,N3];
        3-> [N1,N2,N3-1]
    end.

get_role_faction_id(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        #p_map_role{faction_id=FactionId}->
            next;
        _ ->
            case mod_map_role:get_role_base(RoleID) of
                {ok,#p_role_base{faction_id=FactionId}}->
                    next;
                _ ->
                    {ok,#p_role_base{faction_id=FactionId}} = common_misc:get_dirty_role_base(RoleID)
            end
    end,
    FactionId.

hook_role_dead(DeadRoleID, SActorID, SActorType)->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{is_opening=true}->
            case SActorType of
                role->
                    Now = common_tool:now(),
                    case get_nationbattle_role_info(DeadRoleID) of
                        undefined->
                            hook_role_dead_2(DeadRoleID, SActorID,Now,false);
                        #r_nationbattle_role_info{killer_list=KillerList}->
                            case lists:keyfind(SActorID, 1, KillerList) of
                                {SActorID,KillTime} when Now<(KillTime+5*60)->
                                    IsKillerLimit=true;
                                _ ->
                                    IsKillerLimit = false
                            end,
                            hook_role_dead_2(DeadRoleID, SActorID,Now,IsKillerLimit)
                    end;    
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.
hook_role_dead_2(DeadRoleID, KillerRoleID,Now,IsKillerLimit)->
    KillInfo = {KillerRoleID,Now},
    case get_nationbattle_role_info(DeadRoleID) of
        undefined->
            BattleRoleInfo2 = #r_nationbattle_role_info{killer_list=[KillInfo]},
            ok;
        #r_nationbattle_role_info{killer_list=KillerList} = BattleRoleInfo->
            KillerList2 = common_tool:add_uniq(KillInfo,KillerList),
            BattleRoleInfo2 = BattleRoleInfo#r_nationbattle_role_info{killer_list=KillerList2},
            ok
    end,
    set_nationbattle_role_info(DeadRoleID,BattleRoleInfo2),
    if
        IsKillerLimit=:=true->
            KillerScore = 0;
        true->
            KillerScore = get_killer_score(DeadRoleID,KillerRoleID),
            update_battle_score(dead_role,DeadRoleID,KillerRoleID)
    end,
    update_battle_score(killer_role,KillerRoleID,KillerScore),
    sort_battle_rank(),
    ok.

sort_battle_rank()->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{score_list=ScoreList,rank_data=OldRankList}=BattleMapInfo->
            {ok,ScoreList2,NewRankList} = get_new_rank_list(ScoreList,false),
            set_nationbattle_map_info(BattleMapInfo#r_nationbattle_map_info{score_list=ScoreList2,rank_data=NewRankList}),
            if
                OldRankList=:=NewRankList->
                    ignore;
                true->
                    %%改变排名玩家的BUFF 
                    change_battle_role_buff(OldRankList,NewRankList),
                    notify_battle_rank(NewRankList)
            end;
        _ ->
            ignore
    end.

%%修改战场的BUFF
change_battle_role_buff([],[])->
    ignore;
change_battle_role_buff(OldRankList,NewRankList)->
    {NewRankRoleIdList,DelRankRoleIdList} = get_change_rank_role_list(OldRankList,NewRankList),
    [BattleTopBuffId] = ?find_config( battle_top_buff_id),
    
    [ mod_role_buff:add_buff(RoleID,BattleTopBuffId)||RoleID<-NewRankRoleIdList] ,
    [ mod_role_buff:del_buff_by_type(RoleID, ?BUFF_TYPE_NATIONBATTLE_TOP)||RoleID<-DelRankRoleIdList] ,
    ok.

%%获得战场的BUFF的变更列表
get_change_rank_role_list([],[])->
    {[],[]};
get_change_rank_role_list(OldRankList,NewRankList)->
    NewRankRoleIdList = 
        lists:foldl(
          fun(E,AccIn)->
                  #p_nationbattle_rank{role_id=RoleID} = E,
                  case lists:keyfind(RoleID, #p_nationbattle_rank.role_id, OldRankList) of
                      false-> [RoleID|AccIn];
                      _ -> AccIn
                  end
          end,[], NewRankList),
    DelRankRoleIdList =
        lists:foldl(
          fun(E,AccIn)->
                  #p_nationbattle_rank{role_id=RoleID} = E,
                  case lists:keyfind(RoleID, #p_nationbattle_rank.role_id, NewRankList) of
                      false-> [RoleID|AccIn];
                      _ -> AccIn
                  end
          end,[], OldRankList),
    {NewRankRoleIdList,DelRankRoleIdList}.

%%获取新的积分排名列表
get_new_rank_list(ScoreList,IsSortAll) when is_list(ScoreList)->
    ScoreList2 =  lists:sort(
                    fun(E1,E2)->
                            #p_nationbattle_rank{score=S1,kill_num=K1} = E1,
                            #p_nationbattle_rank{score=S2,kill_num=K2} = E2,
                            if
                                S1>S2-> true;
                                S1=:=S2-> K1>=K2;
                                true-> false
                            end
                    end, ScoreList),
    if
        IsSortAll =:= true-> PartScoreList = ScoreList2;
        true-> PartScoreList = lists:sublist(ScoreList2, ?BATTLE_RANK_LEN)
    end,
    {_Idx,NewRankList} = 
        lists:foldl(
          fun(E,AccIn)->
                  {Order,RankAcc}= AccIn,
                  #p_nationbattle_rank{role_level=RoleLevel} = E,
                  RewardSilver = get_battle_reward_money(Order,RoleLevel),
                  {Order+1,[E#p_nationbattle_rank{order=Order,reward_silver=RewardSilver}|RankAcc]}
          end, {1,[]}, PartScoreList),
    {ok,ScoreList2,NewRankList}.

notify_battle_rank(NewRankList)->
    RoleIdList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              R2 = #m_nationbattle_rank_toc{ranks=NewRankList},
              common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?NATIONBATTLE, ?NATIONBATTLE_RANK, R2)
      end, RoleIdList). 

get_role_jingjie(RoleID)->
    case mod_map_role:get_role_attr(RoleID) of
        {ok,#p_role_attr{jingjie=Jingjie}}->
            Jingjie;
        _ ->
            0
    end.


%%@doc 获得指定人的战场积分
get_role_battle_score(RoleID)->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{score_list=ScoreList}->
            case lists:keyfind(RoleID,#p_nationbattle_rank.role_id,ScoreList) of
                #p_nationbattle_rank{score=Score} when Score>0 ->
                    Score;
                _ -> 0
            end;
        _ -> 0
    end.

%%输者不会扣除积分
update_battle_score(dead_role,DeadRoleID,KillerRoleID)->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{score_list=ScoreList}->
            case lists:keyfind(DeadRoleID,#p_nationbattle_rank.role_id,ScoreList) of
                #p_nationbattle_rank{score=Score,kill_num=KillNum,role_name=RoleName,faction_id=FactionID} when Score>0 ->
					catch broadcast_dead_msg(common_tool:to_list(common_misc:get_faction_color_name(FactionID)),
											 common_tool:to_list(RoleName),KillNum,KillerRoleID),
                    ok;
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end;
%%赢者根据等级差，增加相应积分
update_battle_score(killer_role,KillerRoleID,KillerScore)->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{score_list=ScoreList}=BattleMapInfo->
            case lists:keyfind(KillerRoleID,#p_nationbattle_rank.role_id,ScoreList) of
                #p_nationbattle_rank{score=Score,role_name=RoleName,faction_id=FactionID,kill_num=KillNum,jingjie=OldJingjie} = RoleRank ->
                    case OldJingjie=:=0 of
                        true->
                            Jingjie = get_role_jingjie(KillerRoleID);
                        _ ->
                            Jingjie = OldJingjie
                    end,
                    NewScore = Score+KillerScore,
                    RoleRank2 = RoleRank#p_nationbattle_rank{score=NewScore,kill_num=KillNum+1,jingjie=Jingjie},
                    ScoreList2 = lists:keystore(KillerRoleID, #p_nationbattle_rank.role_id, ScoreList, RoleRank2),
                    set_nationbattle_map_info( BattleMapInfo#r_nationbattle_map_info{score_list=ScoreList2} ),
                    notify_my_battle_info(KillerRoleID,?CHANGE_TYPE_MY_SCORE_AND_KILL,[NewScore,KillNum+1]),
					catch broadcast_kill_msg(common_tool:to_list(common_misc:get_faction_color_name(FactionID)),
											 common_tool:to_list(RoleName),KillNum+1),
                    ok;
                _ ->
                    case mod_map_actor:get_actor_mapinfo(KillerRoleID,role) of
                        #p_map_role{role_name=RoleName,faction_id=RoleFaction,level=RoleLv} ->
                            Jingjie = get_role_jingjie(KillerRoleID),
                            RoleRank2 = #p_nationbattle_rank{role_id=KillerRoleID,role_name=RoleName,faction_id=RoleFaction,
                                                             role_level=RoleLv,kill_num=1,
                                                             jingjie=Jingjie,
                                                             score=KillerScore},
                            ScoreList2 = lists:keystore(KillerRoleID, #p_nationbattle_rank.role_id, ScoreList, RoleRank2),
                            set_nationbattle_map_info( BattleMapInfo#r_nationbattle_map_info{score_list=ScoreList2} ),
                            notify_my_battle_info(KillerRoleID,?CHANGE_TYPE_MY_SCORE_AND_KILL,[KillerScore,1]),
                            ok;
                        _ ->
                            ignore
                    end,
                    ignore
            end;
        _ ->
            ignore
    end.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% 杀人消息广播
broadcast_kill_msg(FactionName,RoleName,KillNum) when KillNum =:= 5 orelse KillNum =:= 10 orelse
											  KillNum =:= 20 orelse KillNum =:= 35 orelse
											  KillNum =:= 78 orelse KillNum =:= 100 ->
	Message = common_misc:format_lang(?_LANG_NATIONBATTLE_KILLER_MSG(KillNum), [FactionName,RoleName,KillNum]),
	?BROADCAST_CHAT_MSG(Message),
	?BROADCAST_CENTER_MSG(Message); 
broadcast_kill_msg(FactionName,RoleName,KillNum) when KillNum =:= 50 ->
	Message = common_misc:format_lang(?_LANG_NATIONBATTLE_KILLER_MSG_50, [KillNum,FactionName,RoleName]),
	?BROADCAST_CHAT_MSG(Message),
	?BROADCAST_CENTER_MSG(Message);
broadcast_kill_msg(FactionName,RoleName,KillNum) when KillNum > 70 ->
	Message = common_misc:format_lang(?_LANG_NATIONBATTLE_KILLER_MSG_MORE, [FactionName,RoleName,KillNum,RoleName]),
	?BROADCAST_CENTER_MSG(Message);
broadcast_kill_msg(_FactionName,_RoleName,_KillNum) ->
	ignore.

%% 被杀消息广播
broadcast_dead_msg(FactionName,RoleName,KillNum,KillerRoleID) when KillNum >= 50 ->
	{ok,#p_role_base{faction_id=FactionID,role_name=KillerRoleNameTmp}} = mod_map_role:get_role_base(KillerRoleID),
	KillerRoleName = common_tool:to_list(KillerRoleNameTmp),
    KillerFactionName = common_tool:to_list(common_misc:get_faction_color_name(FactionID)),
	Message = common_misc:format_lang(?_LANG_NATIONBATTLE_DEAD_MSG_MORE, [KillerFactionName,KillerRoleName,
																		  FactionName,RoleName,
																		  KillNum,KillerRoleName]),
	?BROADCAST_CHAT_MSG(Message),
	?BROADCAST_CENTER_MSG(Message);
broadcast_dead_msg(_FactionName,_RoleName,_KillNum,_KillerRoleID) ->
	ignore.

do_nationbattle_enter({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_nationbattle_enter_tos{enter_type=EnterType} = DataIn,
    case catch check_nationbattle_enter(RoleID,DataIn) of
        {ok,FactionId,SlaveMapIdx}->
            do_nationbattle_enter_2(RoleID,FactionId,SlaveMapIdx);
        {error,ErrCode,Reason}->
            R2 = #m_nationbattle_enter_toc{error_code=ErrCode,reason=Reason,enter_type=EnterType},
            ?UNICAST_TOC(R2)
    end.

do_nationbattle_enter_2(RoleID,FactionId,SlaveMapIdx)->
    %%地图跳转
    FBMapId = ?NATIONBATTLE_MAP_ID,
    {Tx,Ty} = get_fb_born_points(FactionId),
    
    BattleMapName = get_map_name_by_slave_idx(SlaveMapIdx),
    set_map_enter_tag(RoleID,BattleMapName,SlaveMapIdx),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID, FBMapId, Tx, Ty),
    ok.

%%@interface 查询奖励
do_nationbattle_reward({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    case catch check_nationbattle_reward(RoleID,DataIn) of
        {ok,BattleRank,RewardSilver,RewardPropList}->
            R2 = #m_nationbattle_reward_toc{reward_silver=RewardSilver,reward_prop=RewardPropList,battle_rank=BattleRank};
        {error,ErrCode,Reason}->
            R2 = #m_nationbattle_reward_toc{error_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).


check_nationbattle_reward(RoleID,_DataIn)->
    case db:dirty_read(?DB_ROLE_NATIONBATTLE, RoleID) of
        [#r_role_nationbattle{is_fetched=true}]->
            ?THROW_ERR( ?ERR_NATIONBATTLE_REWARD_HAS_FETCHED );
        [#r_role_nationbattle{is_fetched=false,reward_silver=RewardSilver,reward_prop=RewardPropList,battle_rank=BattleRank}]->
            {ok,BattleRank,RewardSilver,RewardPropList};
        _ ->
            ?THROW_ERR( ?ERR_NATIONBATTLE_REWARD_NO_REWARDS )
    end.

%%@interface 领取奖励
do_nationbattle_fetch_reward({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    case catch check_nationbattle_reward(RoleID,DataIn) of
        {ok,_BattleRank,RewardSilver,RewardPropList}->
            TransFun = fun()-> 
                               t_nationbattle_fetch_reward(RoleID,RewardSilver,RewardPropList) 
                       end,
            case common_transaction:t( TransFun ) of
                {atomic,{ok,RoleAttr2,AddGoodsList}} ->
                    common_misc:send_role_silver_change(RoleID,RoleAttr2),
                    lists:foreach(
                      fun(PropTypeId)-> 
                              common_item_logger:log(RoleID, PropTypeId,1,undefined,?LOG_ITEM_TYPE_NATIONBATTLE_REWARD)
                      end,RewardPropList),
                    
                    case AddGoodsList of
                        []-> ignore;
                        _ ->
                            common_misc:update_goods_notify({role, RoleID}, AddGoodsList)
                    end,
                    
                    R2 = #m_nationbattle_fetch_reward_toc{reward_silver=RewardSilver,reward_prop=RewardPropList};
                {atomic,{error,ErrCode,Reason} } ->
                    R2 = #m_nationbattle_fetch_reward_toc{error_code=ErrCode,reason=Reason};
                {aborted, AbortErr}->
                    {error,ErrCode,Reason} = parse_aborted_err(AbortErr,?ERR_NATIONBATTLE_REWARD_NOT_ENOUGH_POS),
                    R2 = #m_nationbattle_fetch_reward_toc{error_code=ErrCode,reason=Reason}
            end;
        {error,ErrCode,Reason}->
            R2 = #m_nationbattle_fetch_reward_toc{error_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

t_nationbattle_fetch_reward(RoleID,RewardSilver,RewardPropList)->
    MoneyType = silver_bind,
    {ok,RoleAttr2} = common_bag2:t_gain_money(MoneyType, RewardSilver, RoleID, ?GAIN_TYPE_SILVER_NATIONBATTLE_REWARD),
    
    case RewardPropList of
        [PropTypeId] ->
            RewardProp = #p_reward_prop{prop_id=PropTypeId,prop_type=?TYPE_ITEM,prop_num=1,bind=true,color=0},
            {ok,AddGoodsList} = common_bag2:t_reward_prop(RoleID, RewardProp, mission);
        _ ->
            AddGoodsList = []
    end,
    
    %%标记已经领取，脏写必须是最后一个步骤
    case db:dirty_read(?DB_ROLE_NATIONBATTLE,RoleID) of
        [R2Record]->
            db:dirty_write(?DB_ROLE_NATIONBATTLE, R2Record#r_role_nationbattle{is_fetched=true});
        _ ->
            ?THROW_SYS_ERR()
    end,
    
    {ok,RoleAttr2,AddGoodsList}.


%%传送到地图内的指定玩家的位置
do_nationbattle_transfer({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_nationbattle_transfer_tos{role_id=TransRoleID} = DataIn,
    case catch check_nationbattle_transfer(RoleID,DataIn) of
        {ok,#p_pos{tx=TX,ty=TY}}->
            do_nationbattle_transfer_2(RoleID,TX,TY,TransRoleID,{Unique, Module, Method, DataIn, RoleID, PID, _Line});
        {error,ErrCode,Reason}->
            R2 = #m_nationbattle_transfer_toc{role_id=TransRoleID,error_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

do_nationbattle_transfer_2(RoleID,TX,TY,TransRoleID,{Unique, Module, Method, _DataIn, RoleID, PID, _Line})->
    TransFun = fun()-> 
                       case catch mod_bag:decrease_goods_by_typeid(RoleID,?TRANSFER_SCROLL_TYPEID,1) of
                           {bag_error,num_not_enough} ->
                               ?THROW_ERR(?ERR_NATIONBATTLE_TRNASFER_NUM_NOT_ENOUGH);
                           Other ->
                               Other
                       end
               end,
    case common_transaction:t( TransFun ) of
        {atomic, {ok,ChangeList,DeleteList}}->
            case ChangeList of
                []->
                    used_transfer_log(DeleteList),
                    common_misc:del_goods_notify({role, RoleID}, DeleteList);
                _->
                    used_transfer_log(ChangeList),
                    common_misc:update_goods_notify({role, RoleID}, ChangeList)
            end,
            R2 = #m_nationbattle_transfer_toc{role_id=TransRoleID},
			mgeem_map:send({mod, mod_map_transfer, {map_transfer, RoleID, ?NATIONBATTLE_MAP_ID, TX, TY}});
        {aborted, AbortErr} ->
            {error,ErrCode,Reason} = parse_aborted_err(AbortErr,?ERR_NATIONBATTLE_TRNASFER_NUM_NOT_ENOUGH),
            R2 = #m_nationbattle_transfer_toc{role_id=TransRoleID,error_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).


check_nationbattle_transfer(_RoleID,DataIn)->
    #m_nationbattle_transfer_tos{role_id=TransRoleID} = DataIn,
%%     case is_in_fb_map() of
%%         true->
%%             next;
%%         _ ->
%%             ?THROW_ERR(?ERR_NATIONBATTLE_TRNASFER_YOU_NOT_IN_BATTLE)
%%     end,
    case mod_map_role:get_role_pos_detail(TransRoleID) of
         {ok,#p_role_pos{pos=TransPos}}->
            next;
         _ ->
             TransPos = null,
             ?THROW_ERR(?ERR_NATIONBATTLE_TRNASFER_HIM_NOT_IN_BATTLE)
    end,
    {ok,TransPos}.

do_nationbattle_quit({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    case catch check_nationbattle_quit(RoleID,DataIn) of
        ok->
            do_nationbattle_quit_2(RoleID);
        {error,ErrCode,Reason}->
            R2 = #m_nationbattle_quit_toc{error_code=ErrCode,reason=Reason},
			?UNICAST_TOC(R2)
    end.

do_nationbattle_quit_2(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{state=?ROLE_STATE_DEAD}->%%死亡状态
            mod_role2:relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, RoleID, ?RELIVE_TYPE_ORIGINAL_FREE);
        _ ->
            ignore
    end,
	common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?NATIONBATTLE,?NATIONBATTLE_QUIT,#m_nationbattle_quit_toc{}),
    {DestMapId,TX,TY} = get_nationbattle_return_pos(RoleID),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapId, TX, TY),
    ok.

%%获取副本返回的位置
get_nationbattle_return_pos(RoleID)->
    %%好吧，踢回京城
    common_map:get_map_return_pos_of_jingcheng(RoleID).

%%对服务器进行轮番分配时间片段
do_split_battle_time_banlance()->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{is_opening=true}->
            do_split_battle_time_banlance(next_time),
            do_split_battle_time_banlance_2(),
            ok;
        _ ->
            ignore
    end.
do_split_battle_time_banlance(next_time)->
    [SplitTimeInterval] = ?find_config(split_time_interval),
    erlang:send_after(SplitTimeInterval*1000, self(), {mod,?MODULE,{split_battle_time_banlance}}),
    ok.

do_split_battle_time_banlance_2()->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{split_time_idx=SplitTimeIdx}=OldBattleMapInfo ->
            Next = (SplitTimeIdx+1) rem 2,
            BattleMapInfo = OldBattleMapInfo#r_nationbattle_map_info{split_time_idx=Next},
            set_nationbattle_map_info(BattleMapInfo),
            %%将时间分片的信息更新到王城
            do_req_nationbattle_entrance_info(),
            ok;
        _ ->
            ignore
    end.

%%计算神农的积分
do_calc_battle_union()->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{is_opening=true}->
            do_calc_battle_union(next_time),            
            do_calc_battle_union_2(),
            ok;
        _ ->
            ignore
    end.
do_calc_battle_union(next_time)->
    erlang:send_after(?CALC_UNION_INTERVAL, self(), {mod,?MODULE,{calc_battle_union}}),
    ok.
    

do_calc_battle_union_2()->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{score_list=[]} ->
            ignore;
        #r_nationbattle_map_info{is_opening=true,score_list=AllScoreList,
                                 union_scores=OldUnionScores,union_nation=UnionNation,
                                 last_union_time=LastUnionTime}=OldBattleMapInfo ->
            %%保存新的势力杀戮值
            NewUnionScores = get_union_score_list(AllScoreList),
            BattleMapInfo = OldBattleMapInfo#r_nationbattle_map_info{union_scores=NewUnionScores},
            set_nationbattle_map_info(BattleMapInfo),
            
            [{StartUnionInterval,ContinueUnionInterval}] = ?find_config(fb_union_nation),
            Now =common_tool:now(),
            case UnionNation=/=[] of
                true->
                    %%结盟状态
                    case LastUnionTime>0 andalso Now>=(LastUnionTime+ContinueUnionInterval) of
                        true->
                            set_nationbattle_map_info(BattleMapInfo#r_nationbattle_map_info{
                                                                            union_nation=[],
                                                                            last_union_time=0}),
                            notify_union_status([],NewUnionScores);
                        _ ->
                            notify_union_scores(OldUnionScores,NewUnionScores)
                    end;
                _ ->
                    %%非结盟状态
                    case get_nationbattle_time_data() of
                        #r_nationbattle_time{start_time = StartTime} when Now>=(StartTime+StartUnionInterval) ->
                            do_calc_battle_union_2(OldUnionScores,NewUnionScores,BattleMapInfo);
                        _ ->
                            %%结盟时间未到，只更新杀戮值数据
                            notify_union_scores(OldUnionScores,NewUnionScores)
                    end
            end;
        _ ->
            next
    end.

do_calc_battle_union_2(OldUnionScores,NewUnionScores,BattleMapInfo)->
    [Total1,Total2,Total3] = NewUnionScores,
    SortScoreList = lists:sort(
                      fun(E1,E2)-> 
                              {S1,_} = E1,
                              {S2,_} = E2,
                              S1>S2
                      end,[{Total1,1},{Total2,2},{Total3,3}]),
    [{TotalScore1,_Nation1},{TotalScore2,Nation2},{TotalScore3,Nation3}] = SortScoreList,
    if
        TotalScore1>=0 andalso TotalScore1>=(TotalScore2+TotalScore3)->
            Now = common_tool:now(),
            UnionNationList = [Nation2,Nation3],
            set_nationbattle_map_info(BattleMapInfo#r_nationbattle_map_info{union_nation=UnionNationList,
                                                                            union_scores=NewUnionScores,
                                                                            last_union_time=Now}),
            notify_union_status(UnionNationList,NewUnionScores);
        true->
            notify_union_scores(OldUnionScores,NewUnionScores)
    end.


get_union_score_list(AllScoreList)->
    lists:foldl(
      fun(E,AccIn)->
              [Acc1,Acc2,Acc3] = AccIn,
              #p_nationbattle_rank{faction_id=FactionId,score=Score} = E,
              case FactionId of
                  1->
                      [Acc1+Score,Acc2,Acc3];
                  2->
                      [Acc1,Acc2+Score,Acc3];
                  3->
                      [Acc1,Acc2,Acc3+Score]
              end
      end,[0,0,0],AllScoreList).


%%对所有有杀戮值的人进行奖励，并踢出地图
reward_and_kick_all_roles()->
    %%踢人
    RoleIdList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              erase({?NATIONBATTLE_ROLE_INFO,RoleID}),
              do_nationbattle_quit_2(RoleID)
      end, RoleIdList),
    ok.



%% --------------------------------------------------------------------
%%  内部的二级API
%% --------------------------------------------------------------------
assert_role_level(RoleAttr)->
    #p_role_attr{level=RoleLevel} = RoleAttr,
    [MinRoleLevel] = ?find_config(fb_min_role_level),
    if
        MinRoleLevel>RoleLevel->
            ?THROW_ERR( ?ERR_NATIONBATTLE_ENTER_LV_LIMIT );
        true->
            next
    end,
    ok.

get_fb_min_role_level_str()->
    [MinRoleLevel] = ?find_config(fb_min_role_level),
    lists:concat([MinRoleLevel,"级"]).

check_nationbattle_enter(RoleID,DataIn)->
    #m_nationbattle_enter_tos{enter_type=EnterType} = DataIn,
    [EnableNationBattle] = ?find_config(enable_nationbattle),
    if
        EnableNationBattle=:=true->
            next;
        true->
            ?THROW_ERR( ?ERR_NATIONBATTLE_DISABLE )
    end,
    case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
        true ->
            ?THROW_ERR(?ERR_OTHER_ERR, ?_LANG_XIANNVSONGTAO_MSG);
        false -> ignore
    end,
    
    {ok,#p_role_base{faction_id=FactionId}} = mod_map_role:get_role_base(RoleID),
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    
    #p_role_attr{jingjie=RoleJingjie} = RoleAttr,
    assert_role_level(RoleAttr),
    
    case is_in_fb_map() of
        true->
            ?THROW_ERR( ?ERR_NATIONBATTLE_ENTER_IN_BATTLE );
        _ ->
            next
    end,
    #map_state{mapid=MapID,map_type=MapType} = mgeem_map:get_state(),
    IsInWarofkingFb = mod_warofking:is_fb_map_id(MapID),
    
    if
        MapType=:=?MAP_TYPE_COPY->
            ?THROW_ERR( ?ERR_NATIONBATTLE_ENTER_FB_LIMIT );
        IsInWarofkingFb->
            ?THROW_ERR( ?ERR_NATIONBATTLE_ENTER_FB_LIMIT);
        true->
            next
    end,
    %%检查入口信息
    case get_nationbattle_entrance_info() of
        undefined->
            SlaveNum=SplitTimeIdx=SplitJingjie=0,
            req_nationbattle_entrance_info(),
            ?THROW_ERR( ?ERR_NATIONBATTLE_ENTER_CLOSING );
        #r_nationbattle_entrance_info{is_opening=true,slave_num=SlaveNum,split_time_idx=SplitTimeIdx,split_jingjie=SplitJingjie}->
            next;
        _ ->
            SlaveNum=SplitTimeIdx=SplitJingjie=0,
            ?THROW_ERR( ?ERR_NATIONBATTLE_ENTER_CLOSING )
    end,
    
    %%先判断当前玩家是否已登记在某个场地（按照当天的进场历史判断），如果有则只能进这个场。
    FinalSlaveMapIdx = get_final_slave_map_idx(SlaveNum,RoleID,RoleJingjie,SplitTimeIdx,SplitJingjie),
    
    if
        SlaveNum=:=0->
            next;
        true->
            assert_split_jingjie(FinalSlaveMapIdx,RoleJingjie,SplitJingjie)
    end,
    
    %%检查人数
    case get_nationbattle_sub_entrance_info(FinalSlaveMapIdx) of
        undefined->
            req_nationbattle_sub_entrance_info(FinalSlaveMapIdx),
            ?THROW_ERR( ?ERR_NATIONBATTLE_ENTER_CLOSING );
        #r_nationbattle_sub_entrance_info{all_role_num=CurRoleNum}->
            [{NormalMaxRoleNum,AllMaxRoleNum}] = ?find_config(limit_fb_role_num),
            case check_direct_enter_vip(EnterType,RoleID) of
                true->
                    if
                        CurRoleNum>=AllMaxRoleNum->
                            req_nationbattle_sub_entrance_info(FinalSlaveMapIdx),
                            ?THROW_ERR( ?ERR_NATIONBATTLE_ENTER_MAX_ROLE_NUM );
                        true->
                            next
                    end;
                {false,ErrorCode}->
                    ?THROW_ERR( ErrorCode );
                _ ->
                    if
                        CurRoleNum>=NormalMaxRoleNum->
                            req_nationbattle_sub_entrance_info(FinalSlaveMapIdx),
                            ?THROW_ERR( ?ERR_NATIONBATTLE_ENTER_MAX_ROLE_NUM );
                        true->
                            next
                    end
            end;
        _ ->
            ?THROW_ERR( ?ERR_NATIONBATTLE_ENTER_CLOSING )
    end,
    {ok,FactionId,FinalSlaveMapIdx}.

%%判断是否为VIP直接进入
check_direct_enter_vip(?ENTER_TYPE_VIP,RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        #p_map_role{vip_level=VipLevel} ->
            case ?find_config( direct_enter_vip_level) of
                [EnterVip] when VipLevel>= EnterVip->
                    true;
                _ ->
                    {false,?ERR_NATIONBATTLE_ENTER_VIP_LIMIT}
            end;
        _ -> false
    end;
check_direct_enter_vip(_,_)->
    false.


check_nationbattle_quit(_RoleID,_DataIn)->
    case is_in_fb_map() of
        true->
            next;
        _->
            ?THROW_ERR( ?ERR_NATIONBATTLE_QUIT_NOT_IN_MAP )
    end,
    ok.


%%--------------------------------  战场入口消息的代码，可复用  [start]--------------------------------
get_final_slave_map_idx(SlaveNum,RoleID,RoleJingjie,SplitTimeIdx,SplitJingjie)->
    if
        SlaveNum=:=0->
            0;    %%主地图
        true->
            %% 1=根据时间片段进行分流，2=根据境界进行分流
            [{SplitMode,_}] = ?find_config(split_mode),
            case SplitMode of
                ?SPLIT_MODE_TIME->
                    get_final_slave_map_idx_2(split_time_idx,RoleID,SplitTimeIdx);
                ?SPLIT_MODE_JINGJIE->
                    get_final_slave_map_idx_2(split_jingjie,RoleJingjie,SplitJingjie)
            end
    end.

get_final_slave_map_idx_2(split_time_idx,RoleID,SplitTimeIdx)->
    Today = date(),
    case get({?NATIONBATTLE_MAP_NAME_TO_ENTER,RoleID}) of
        {Today,_,SlaveMapIdx}->
            SlaveMapIdx;
        _ ->
            SplitTimeIdx
    end;
get_final_slave_map_idx_2(split_jingjie,RoleJingjie,SplitJingjie)->
    if
        RoleJingjie>=SplitJingjie->
            0;
        true->
            1
    end.

%%@doc 检查玩家分流的战场是否符合条件
assert_split_jingjie(FinalSlaveMapIdx,RoleJingjie,SplitJingjie)->
    [{SplitMode,_}] = ?find_config(split_mode),
    case SplitMode of
        ?SPLIT_MODE_JINGJIE->
            assert_split_jingjie_2(FinalSlaveMapIdx,RoleJingjie,SplitJingjie);
        _ ->
            ok
    end.
assert_split_jingjie_2(FinalSlaveMapIdx,RoleJingjie,SplitJingjie)->
    if
        FinalSlaveMapIdx=:=0 andalso RoleJingjie>=SplitJingjie->
            next;
        FinalSlaveMapIdx=:=1 andalso RoleJingjie<SplitJingjie->
            next;
        true->
            ?THROW_ERR( ?ERR_NATIONBATTLE_ENTER_SPLIT_LIMIT )
    end,
    ok.

%%@doc 根据战场的分场索引得出对应的地图名称
get_map_name_by_slave_idx(FinalMapIdx) when is_integer(FinalMapIdx)->
    case FinalMapIdx of
        0-> %%主战场
            common_map:get_common_map_name(?NATIONBATTLE_MAP_ID);
        _ ->
            common_map:get_common_map_slave_name(?NATIONBATTLE_MAP_ID,FinalMapIdx)
    end.

%%请求更新入口信息
req_nationbattle_entrance_info()->
    send_master_map_msg( {req_nationbattle_entrance_info} ).

req_nationbattle_sub_entrance_info(SlaveMapIdx)->
    send_slave_map_msg(SlaveMapIdx,{req_nationbattle_sub_entrance_info}).

do_req_nationbattle_entrance_info()->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{is_opening=IsOpening,slave_num=SlaveNum,split_time_idx=SplitTimeIdx,split_jingjie=SplitJingjie}->
            EntranceInfo = #r_nationbattle_entrance_info{is_opening=IsOpening,slave_num=SlaveNum,split_time_idx=SplitTimeIdx,split_jingjie=SplitJingjie},
            init_nationbattle_entrance_info(EntranceInfo),
            ok;
        _ ->
            ignore
    end.

do_req_nationbattle_sub_entrance_info()->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{role_num=AllRoleNum,my_slave_map_idx=BattleMapIdx,faction_role_num=FactionRoleNumList}->
            syn_nationbattle_sub_entrance_info(BattleMapIdx,AllRoleNum,FactionRoleNumList),
            ok;
        _ ->
            ignore
    end.

%%同步更新入口信息
%%  包括更新到王城、Slave进程
init_nationbattle_entrance_info(EntranceInfo) when is_record(EntranceInfo,r_nationbattle_entrance_info)->
    [EntranceMapIdList] = ?find_config(entrance_map_id),
    lists:foreach(
      fun(EntranceMapId)->
              SendInfo = {mod,?MODULE,{init_nationbattle_entrance_info,EntranceInfo}},
              case global:whereis_name( common_map:get_common_map_name(EntranceMapId) ) of
                  undefined->
                      ignore;
                  MapPID->
                      MapPID ! SendInfo
              end
      end, EntranceMapIdList).


syn_nationbattle_sub_entrance_info(BattleMapIdx,AllRoleNum,FactionRoleNumList) when is_list(FactionRoleNumList)->
    SubEntranceInfo = #r_nationbattle_sub_entrance_info{all_role_num=AllRoleNum,faction_role_num=FactionRoleNumList},
    syn_nationbattle_sub_entrance_info(BattleMapIdx,SubEntranceInfo).
syn_nationbattle_sub_entrance_info(BattleMapIdx,SubEntranceInfo) when is_record(SubEntranceInfo,r_nationbattle_sub_entrance_info)->
    [EntranceMapIdList] = ?find_config(entrance_map_id),
    lists:foreach(
      fun(EntranceMapId)->
              SendInfo = {mod,?MODULE,{syn_nationbattle_sub_entrance_info,BattleMapIdx,SubEntranceInfo}},
              case global:whereis_name( common_map:get_common_map_name(EntranceMapId) ) of
                  undefined->
                      ignore;
                  MapPID->
                      MapPID ! SendInfo
              end
      end, EntranceMapIdList).

do_syn_nationbattle_sub_entrance_info(BattleMapIdx,SubEntranceInfo)->
    set_nationbattle_sub_entrance_info(BattleMapIdx,SubEntranceInfo),
    ok.

do_init_nationbattle_entrance_info(EntranceInfo) when is_record(EntranceInfo,r_nationbattle_entrance_info)->
    put(?NATIONBATTLE_ENTRANCE_INFO,EntranceInfo),
    ok.

do_update_nationbattle_entrance_info(ValList) when is_list(ValList)->
    case get(?NATIONBATTLE_ENTRANCE_INFO) of
        #r_nationbattle_entrance_info{}= OldInfo->
            EntranceInfo =
                lists:foldl(
                  fun(E,AccIn)-> 
                          {EType,EVal} = E,
                          case EType of
                              is_opening->
                                  AccIn#r_nationbattle_entrance_info{is_opening=EVal}
                          end
                  end, OldInfo, ValList),
            put(?NATIONBATTLE_ENTRANCE_INFO,EntranceInfo),
            ok;
        _ ->
            ignore
    end,
    ok.

%%--------------------------------  战场入口消息的代码，可复用  [end]--------------------------------

%%--------------------------------  定时战场的代码，可复用  [start]--------------------------------

is_opening_battle()->
    case get_nationbattle_map_info() of
        #r_nationbattle_map_info{is_opening=IsOpening}->
            IsOpening;
        _ ->
            false
    end.

%%@doc 重新设置下一次战场时间
%%@return {ok,NextStartTimeSeconds}
reset_battle_open_times()->
    case common_fb:get_next_fb_open_time(?CONFIG_NAME) of
        {ok,Date,StartTimeSeconds,EndTimeSeconds,NextBcStartTime,NextBcEndTime,NextBcProcessTime,
         BeforeInterval,CloseInterval,ProcessInterval}->
            R1 = #r_nationbattle_time{date = Date,
                                      start_time = StartTimeSeconds,end_time = EndTimeSeconds,
                                      next_bc_start_time = NextBcStartTime,
                                      next_bc_end_time = NextBcEndTime,
                                      next_bc_process_time = NextBcProcessTime,
                                      before_interval = BeforeInterval,
                                      close_interval = CloseInterval,
                                      process_interval = ProcessInterval},
            put(?NATIONBATTLE_TIME_DATA,R1),
            {ok,StartTimeSeconds};
        {error,Reason}->
            {error,Reason}
    end.

%%--------------------------------  定时战场的代码，可复用  [end]--------------------------------

%%--------------------------------  战场广播的代码，可复用  [start]--------------------------------
%% 副本开起提前广播开始消息
%% Record 结构为 r_nationbattle_time
%% 返回 new r_nationbattle_time
do_fb_open_before_broadcast(NowSeconds,Record) ->
    #r_nationbattle_time{
                             start_time = StartTime,
                             end_time = EndTime,
                             next_bc_start_time = NextBCStartTime,
                             before_interval = BeforeInterval} = Record,
    if StartTime =/= 0 
       andalso EndTime =/= 0 
       andalso NextBCStartTime =/= 0
       andalso NowSeconds >= NextBCStartTime 
       andalso NowSeconds < StartTime->
            %% 副本开起提前广播开始消息
           MinRoleLevelStr = get_fb_min_role_level_str(),
           BeforeMessage = 
               case StartTime>NowSeconds of 
                   true->
                       {_Date,Time} = common_tool:seconds_to_datetime(StartTime),
                       StartTimeStr = common_time:time_string(Time),
                       common_misc:format_lang(?_LANG_NATIONBATTLE_PRESTART,[StartTimeStr,MinRoleLevelStr]);
                   _ ->
                       common_misc:format_lang(?_LANG_NATIONBATTLE_STARTED,[MinRoleLevelStr])
               end,
           catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,BeforeMessage),
           set_nationbattle_time_data( Record#r_nationbattle_time{
                                                                  next_bc_start_time = NowSeconds + BeforeInterval} );
       true ->
           Record
    end.
%% 副本开启过程中广播处理
%% Record 结构为 r_nationbattle_time
%% 返回
do_fb_open_process_broadcast(NowSeconds,Record) ->
    #r_nationbattle_time{
                              start_time = StartTime,
                              end_time = EndTime,
                              next_bc_process_time = NextBCProcessTime,
                              process_interval = _ProcessInterval} = Record,
    if 
        StartTime =/= 0 andalso EndTime =/= 0 
       andalso NowSeconds >= StartTime andalso EndTime >= NowSeconds 
       andalso NextBCProcessTime =/= 0
       andalso NowSeconds >= NextBCProcessTime ->
            %% 副本开起过程中广播时间到
            MinRoleLevelStr = get_fb_min_role_level_str(),
            ProcessMessage = common_misc:format_lang(?_LANG_NATIONBATTLE_STARTED,[MinRoleLevelStr]),
            catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,ProcessMessage),
            set_nationbattle_time_data( Record#r_nationbattle_time{
                                                 next_bc_process_time = 0} );
       true ->
            ignore
    end.


%%副本关闭的广播
do_fb_close_broadcast(NextStartTime)->
    EndMessageF = 
        if NextStartTime > 0 ->
               NextDateTime = common_tool:seconds_to_datetime(NextStartTime), 
               NextStartTimeStr = common_time:datetime_to_string( NextDateTime ),
               common_misc:format_lang(?_LANG_NATIONBATTLE_CLOSED_TIME,[NextStartTimeStr]);
           true ->
               ?_LANG_NATIONBATTLE_CLOSED_FINAL
        end,
    catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,EndMessageF).

%%--------------------------------  战场广播的代码，可复用  [end]--------------------------------

%%--------------------------------  加经验的代码，可复用  [start]--------------------------------
%% @doc 获取每次间隔加的经验
get_interval_exp_add(_FactionID, Level) ->
    case ?find_config({fb_add_exp, Level}) of
		[] ->
			100;
		[Exp] ->
			Exp
	end.

do_add_exp_interval(Now) ->
    RoleIDList = get_interval_exp_list(Now),
    lists:foreach(
      fun(RoleID) ->
              case mod_map_actor:get_actor_mapinfo(RoleID, role) of
                  undefined ->
                      delete_interval_exp_list(RoleID);
                  #p_map_role{faction_id=FactionID, level=Level} ->
                      ExpAdd = get_interval_exp_add(FactionID, Level),
                      mod_map_role:do_add_exp(RoleID, ExpAdd)
              end
      end, RoleIDList).

%% @doc 插入加经验列表
insert_interval_exp_list(RoleID) ->
    List = get_interval_exp_list(RoleID),
    set_interval_exp_list(RoleID, [RoleID|lists:delete(RoleID, List)]).

delete_interval_exp_list(RoleID) ->
    List = get_interval_exp_list(RoleID),
    set_interval_exp_list(RoleID, lists:delete(RoleID, List)).

get_interval_exp_list(RoleID) ->
    [{_,ExpAddInterval}] = ?find_config(fb_add_exp),
    Key = RoleID rem ExpAddInterval,
    case get({?INTERVAL_EXP_LIST, Key}) of
        undefined ->
            put({?INTERVAL_EXP_LIST, Key}, []),
            [];
        List ->
            List
    end.

set_interval_exp_list(RoleID, List) ->
    [{_,ExpAddInterval}] = ?find_config(fb_add_exp),
    Key = RoleID rem ExpAddInterval,
    put({?INTERVAL_EXP_LIST, Key}, List).

%%--------------------------------  加经验的代码，可复用 [end] --------------------------------

%%--------------------------------  战场开/关的代码，可复用 [start] --------------------------------
%%GM的方便命令
gm_open_battle(SecTime)->
    send_master_map_msg( {gm_open_battle, SecTime} ).
gm_close_battle()->
    send_master_map_msg( {gm_close_battle} ).
gm_reset_open_times()->
    send_master_map_msg( {gm_reset_open_times} ).

%%将消息发送到战场的Master地图进程
send_master_map_msg(Msg)->
    case global:whereis_name( get_fb_map_name() ) of
        undefined->
            ignore;
        MapPID->
            erlang:send(MapPID,{mod,?MODULE,Msg})
    end.

%%将消息发送到战场的Slave地图进程
send_slave_map_msg(SlaveMapIdx,Msg)->
    BattleMapName = get_map_name_by_slave_idx(SlaveMapIdx),
    case global:whereis_name( BattleMapName ) of
        undefined->
            ignore;
        MapPID->
            erlang:send(MapPID,{mod,?MODULE,Msg})
    end.


%%GM开启副本
gm_open_nationbattle(Second)->
	%%GM命令，手动开启
	TimeData = get_nationbattle_time_data(),
	StartTime2 = common_tool:now(),
	[FbGmOpenLastTime] = ?find_config(fb_gm_open_last_time),
	EndTime2 = StartTime2 + FbGmOpenLastTime,
	TimeData2 = TimeData#r_nationbattle_time{date=date(),start_time=StartTime2 + Second,end_time=EndTime2},
	set_nationbattle_time_data(TimeData2).


%%开启副本
open_nationbattle()->   
    [{SplitMode,ForceSplitMode}] = ?find_config(split_mode),
    OnlineNum = common_map:get_online_num(),
    
    if
        ForceSplitMode=:=3->                         %%强制不分流
            SlaveNum = 0;
        ForceSplitMode=:=2 orelse OnlineNum>1000->   %%强制分流或在线超过1000
            if
                SplitMode=:=?SPLIT_MODE_TIME->
                    do_split_battle_time_banlance(next_time);
                true->
                    ok
            end,
            SlaveNum = 1;
        true->
            SlaveNum = 0
    end,
    
    set_nationbattle_map_info(#r_nationbattle_map_info{is_opening=true,slave_num=SlaveNum}),
    
    open_slave_nationbattle(SlaveNum,true),
    
    EntranceInfo = #r_nationbattle_entrance_info{is_opening=true,slave_num=SlaveNum},
    init_nationbattle_entrance_info(EntranceInfo),
    
    lists:foreach(
      fun(BattleMapIdx)->
              syn_nationbattle_sub_entrance_info(BattleMapIdx,#r_nationbattle_sub_entrance_info{})
      end, lists:seq(0, SlaveNum)),
    

    do_calc_battle_union(next_time),
    ok.


%%关闭副本
close_nationbattle(NextStartTime)->
    do_fb_close_broadcast(NextStartTime),
    BattleMapInfo = get_nationbattle_map_info(),
    set_nationbattle_map_info(BattleMapInfo#r_nationbattle_map_info{is_opening=false}),
    
    #r_nationbattle_map_info{slave_num=SlaveNum} = BattleMapInfo,
    open_slave_nationbattle(SlaveNum,false),
    do_nationbattle_stop_after_broadcast(),
    EntranceInfo = #r_nationbattle_entrance_info{is_opening=false},
    init_nationbattle_entrance_info(EntranceInfo),
    reward_and_kick_all_roles(),
    ok.

do_nationbattle_stop_after_broadcast() ->
	case get_nationbattle_stop_static_bc_time() of
		undefined ->
			igonre;
		StopBcTimeList when is_list(StopBcTimeList) ->
			lists:foreach(fun(StopBcTime) ->
								  {Day,_} = erlang:localtime(),
								  RealStopBcTime = common_tool:datetime_to_seconds({Day,StopBcTime}),
								  case RealStopBcTime > common_tool:now() of
									  true ->
										  mgeem_event:set_event(
											{nationbattle_stop_static_bc_time,RealStopBcTime}, 
											RealStopBcTime, 
											mod_nationbattle_fb, 
											do_static_broadcast, 
											{RealStopBcTime,stop});
									  _ ->
										  ingore
								  end
						  end, StopBcTimeList)
	end.
%%开启/关闭 Slave战场
open_slave_nationbattle(SlaveNum,IsOpen) when SlaveNum>0->
    lists:foreach(
      fun(SlaveMapIdx)->
              Msg = {open_slave_nationbattle,SlaveMapIdx,SlaveNum,IsOpen},
              send_slave_map_msg(SlaveMapIdx,Msg)
      end, lists:seq(1, SlaveNum)),
    case IsOpen of
        true->
            update_slave_nationbattle_timedata(SlaveNum,get_nationbattle_time_data());
        _ ->
            ignore
    end,
    ok;
open_slave_nationbattle(_SlaveNum,_)->
    ignore.


do_open_slave_nationbattle(SlaveMapIdx,SlaveNum,IsOpen)->
    set_nationbattle_map_info(#r_nationbattle_map_info{is_opening=IsOpen,slave_num=SlaveNum,my_slave_map_idx=SlaveMapIdx}),
    do_calc_battle_union(next_time),
    ok.


%%修改Slave战场的时间数据
update_slave_nationbattle_timedata(SlaveNum,TimeData) when SlaveNum>0->
    lists:foreach(
      fun(SlaveMapIdx)->
              Msg = {update_slave_nationbattle_timedata,SlaveMapIdx,TimeData},
              send_slave_map_msg(SlaveMapIdx,Msg)
      end, lists:seq(1, SlaveNum)),
    ok;
update_slave_nationbattle_timedata(_SlaveNum,_)->
    ignore.

do_update_slave_nationbattle_timedata(_SlaveMapIdx,TimeData2)->
    put(?NATIONBATTLE_TIME_DATA,TimeData2),
    ok.

%%--------------------------------  战场开/关的代码，可复用 [end] --------------------------------

    

%%解析错误码
parse_aborted_err(AbortErr,BagNotEnoughPosError) when is_integer(BagNotEnoughPosError)->
    case AbortErr of
        {error,ErrCode,_Reason} when is_integer(ErrCode) ->
            AbortErr;
        {bag_error,{not_enough_pos,_BagID}}->
            {error,BagNotEnoughPosError,undefined};
        {bag_error,num_not_enough}->
            {error,?ERR_NATIONBATTLE_TRNASFER_NUM_NOT_ENOUGH,undefined};
        {error,AbortReason} when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        AbortReason when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        _ ->
            ?ERROR_MSG(" aborted,AbortErr=~w,stack=~w",[AbortErr,erlang:get_stacktrace()]),
            {error,?ERR_SYS_ERR,undefined}
    end.

used_transfer_log([Goods|_T])->
    #p_goods{roleid=RoleID}=Goods,
    common_item_logger:log(RoleID,Goods,?LOG_ITEM_TYPE_SHI_YONG_SHI_QU),
    ok.


%%通知更新神农的杀戮值
notify_union_scores(OldUnionScores,NewUnionScores) when OldUnionScores=:=NewUnionScores->
    ignore;
notify_union_scores(_,NewUnionScores)->
    R2 = #m_nationbattle_change_toc{change_type=?CHANGE_TYPE_UNION_NATION,
                                    new_value=NewUnionScores},
    RoleIdList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?NATIONBATTLE, ?NATIONBATTLE_CHANGE, R2)
      end, RoleIdList),
    ok.

%%通知更新神农状态信息
notify_union_status(UnionNationList,NewUnionScores)->
    RoleIdList = mod_map_actor:get_in_map_role(),
    case get_nationbattle_time_data() of
        #r_nationbattle_time{start_time = StartTime,end_time = EndTime}->
            lists:foreach(
              fun(RoleID) ->
                      R1 = #m_nationbattle_info_toc{change_type=2,
                                                    union_nation=UnionNationList,union_scores=NewUnionScores,
                                                    fb_start_time=StartTime,fb_end_time=EndTime,
                                                    my_score=-1,my_kill_num=-1},
                      common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?NATIONBATTLE, ?NATIONBATTLE_INFO, R1)
              end, RoleIdList);
        _ ->
            ignore
    end.


%%@doc 更新战场的个人信息
notify_my_battle_info(RoleID,ChangeType,NewValList) when is_list(NewValList)->
    R2 = #m_nationbattle_change_toc{change_type=ChangeType,new_value=NewValList},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?NATIONBATTLE, ?NATIONBATTLE_CHANGE, R2),
    ok.

%%@doc 根据等级差，获得配置中的相应的积分
get_killer_score(DeadRoleID,KillerRoleID)->
    case mod_map_role:get_role_attr(DeadRoleID) of
        {ok,#p_role_attr{level=DeaderLv}}->
            next;
        _ ->
            DeaderLv = -1
    end,
    case mod_map_role:get_role_attr(KillerRoleID) of
        {ok,#p_role_attr{level=KillerLv}}->
            next;
        _ ->
            KillerLv = -1
    end,
    if
        DeaderLv<0 orelse KillerLv<0 ->
            0;
        true->
            LvDiff = DeaderLv-KillerLv,
            [KillerScoreConfList] = ?find_config(killer_level_score),
            KillerScore1 = get_killer_score_2(LvDiff,KillerScoreConfList),
            ExtraScore1 = get_role_battle_score(DeadRoleID) div 10, %%额外奖励对方现有积分的10%
            (KillerScore1+ExtraScore1)
    end.
get_killer_score_2(_LvDiff,[])->
    0;
get_killer_score_2(LvDiff,[H|T])->
    {MinLvDiff,MaxLvDiff,AddScore} = H,
    case LvDiff>=MinLvDiff andalso MaxLvDiff>=LvDiff of
        true->
            AddScore;
        _ ->
            get_killer_score_2(LvDiff,T)
    end.

%% 发送战场的结果通知
notify_reward_result(NewAllRankList)->
    lists:foreach(
      fun(E)-> 
          #p_nationbattle_rank{order=Order,role_id=RoleID,role_level=RoleLevel} = E,
          %%获取赠送的钱币
          RewardMoney = get_battle_reward_money(Order,RoleLevel),
          TitleId = get_battle_reward_title(Order),
          PropTypeId = get_battle_reward_prop(Order),
          if
              PropTypeId>0 ->
                  RewardPropList = [PropTypeId];
              true->
                  RewardPropList = []
          end,

          if
            TitleId > 0 -> 
                {ok, RoleBase = #p_role_base{faction_id = FactionID, role_name = RoleName}} = mod_map_role:get_role_base(RoleID),
                RoleNameStr = common_misc:get_role_name_color(RoleName,FactionID),
                Text = common_misc:format_lang("【~s】<font color=\"#F24192\">万夫莫敌，获得了上古战场第一名 ！普天同庆！</font>", [RoleNameStr]),
                ?WORLD_CENTER_BROADCAST(Text),
                ?WORLD_CHAT_BROADCAST(Text),
                mod_flowers:free_broadcast_flower(RoleBase),
                common_title_srv:add_title(?TITLE_NATION, RoleID, TitleId);
            true -> ignore
          end,
          
          Now = common_tool:now(),
          R2Battle = #r_role_nationbattle{role_id=RoleID,reward_time=Now,reward_silver=RewardMoney,reward_prop=RewardPropList,
                                          battle_rank=E},
          db:dirty_write(?DB_ROLE_NATIONBATTLE,R2Battle),
          
          R2 = #m_nationbattle_reward_toc{battle_rank=E, reward_silver=RewardMoney,reward_prop=RewardPropList},
          common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?NATIONBATTLE, ?NATIONBATTLE_REWARD, R2),
          ok
      end, NewAllRankList),
    ok.

%%记录战场的日志，并且发送战场的结果通知
do_battle_fb_log()->
    case get_nationbattle_time_data() of
        #r_nationbattle_time{start_time = StartTime,end_time = EndTime} ->
            case get_nationbattle_map_info() of
                #r_nationbattle_map_info{my_slave_map_idx=MySlaveMapIdx,score_list=AllScoreList,max_role_num=MaxRoleNum}->
                    {ok,_,NewAllRankList} = get_new_rank_list(AllScoreList,true),
                    notify_reward_result(NewAllRankList),

                    RewardScoreRoleNum = length(NewAllRankList),
                    NationbattleFBLog = 
                        #r_nationbattle_fb_log{slave_map_idx=MySlaveMapIdx,start_time=StartTime,end_time=EndTime,
                                               max_role_num=MaxRoleNum,reward_score_role_num=RewardScoreRoleNum},
                    common_general_log_server:log_nationbattle_fb(NationbattleFBLog);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.

