%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     战神坛副本（定时开启的副本）
%%% @end
%%% Created : 2011-6-16
%%%-------------------------------------------------------------------
-module(mod_arenabattle_fb).

-include("mgeem.hrl").

-export([
         handle/1,
         handle/2
        ]).
 
-export([
         init/2,
         loop/2,
         is_arena_fighter/1,
         is_arena_watcher/1,
         is_fb_map_id/1,
         is_in_fb_map/0,
         check_map_fight/2,
         assert_valid_map_id/1,
         get_map_name_to_enter/1,
         clear_map_enter_tag/1
        ]).
-export([
         hook_role_quit/1,
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
-define(ARENABATTLE_MAP_ID,10502).
-define(ARENABATTLE_MAP_NAME_TO_ENTER,arenabattle_map_name_to_enter).
-define(DEFAULT_SPLIT_JINGJIE,205). %%默认是五等武林新秀
-define(ARENABATTLE_ENTRANCE_INFO,arenabattle_entrance_info).
-define(ARENABATTLE_SUB_ENTRANCE_INFO,arenabattle_sub_entrance_info).

%% 加经验间隔
-define(INTERVAL_EXP_LIST, interval_exp_list).
-define(TRANSFER_FROM_SITE_INTERVAL,5*1000).

-define(ARENABATTLE_MAP_INFO,arenabattle_map_info).
-define(ARENABATTLE_TIME_DATA,arenabattle_time_data).
-define(ARENABATTLE_SCORE_DATA,arenabattle_score_data).
-define(ARENABATTLE_ROLES,arenabattle_roles).
%% slave_num: 已经开启的子战场的个数
%% split_jingjie: 按境界分流的境界值
-record(r_arenabattle_entrance_info,{is_opening=false,slave_num=0,split_time_idx=0,split_jingjie=?DEFAULT_SPLIT_JINGJIE}).
-record(r_arenabattle_sub_entrance_info,{all_role_num=0,faction_role_num=[0,0,0]}).

-record(r_arenabattle_map_info,{is_opening=false,slave_num=0,my_slave_map_idx=0,split_time_idx=0,split_jingjie=?DEFAULT_SPLIT_JINGJIE,
                                faction_role_num=[0,0,0],
                                role_num=0,max_role_num=0,
                                arena_sites=[{1,1}],fight_queue=[],rest_queue=[],line_queue=[],
                                conwin_list=[],reward_list=[]}).
%%      擂台场地——arena_sites:[{SiteID,SiteStatus}]
%%      战斗队列——fight_queue:[{SiteID,FighterIdList,StartTime,EndTime}]
%%      休整队列——rest_queue:[{RoleID,StartTime,EndTime}]
%%      排队队列——line_queue:[RoleID|T]
%%      连胜列表——conwin_list:[{RoleID,ConWinTimes}|T]
%%      奖励列表——reward_list:[{RoleID,ConWinTimes}|T]
-record(r_arenabattle_time,{date = 0,start_time = 0,end_time = 0,
                                 next_bc_start_time = 0,next_bc_end_time = 0,next_bc_process_time = 0,
                                 before_interval = 0,close_interval = 0,process_interval = 0,
                                 kick_role_time = 0}).
-record(r_arenabattle_role_info,{role_id,role_name,head,faction_id,all_score=0,prev_opponent_role_id}).


%% 个人状态
-define(ARENA_ROLE_STATUS_LINE, 1).
-define(ARENA_ROLE_STATUS_FIGHT, 2).
-define(ARENA_ROLE_STATUS_REST, 3).
%% 退出类型
-define(QUIT_TYPE_MAP, 1).
-define(QUIT_TYPE_FIGHT, 2).
%% 擂台状态
-define(ARENA_SITE_STATUS_BLANK, 1).
-define(ARENA_SITE_STATUS_FIGHT, 2).
%% 擂台结果(0=开始战斗，1=本方胜利，2=对方胜利，3=本方退出，4=对方退出，5=战斗超时(平局))
-define(ARENA_RESULT_START, 0).
-define(ARENA_RESULT_SELF_WIN, 1).
-define(ARENA_RESULT_ENEMY_WIN, 2).
-define(ARENA_RESULT_SELF_QUIT, 3).
-define(ARENA_RESULT_ENEMY_QUIT, 4).
-define(ARENA_RESULT_DRAW, 5).
%%每个擂台场地的人数约定
-define(ARENA_ROLE_NUM_PER_SITE, 4).

%% 对应的活动ID, 与activity_today.config里的一致
-define(ARENABATTLE_ACTIVITY_ID,10013).

-define(CAST_LINE_ORDER_INTERVAL,10*1000).   %%每10秒更新最新的排队序号
-define(CONFIG_NAME,arenabattle).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

%% ====================================================================
%% Error Code
%% ====================================================================

-define(ERR_ARENABATTLE_DISABLE,10999).
-define(ERR_ARENABATTLE_ENTER_CLOSING,10001).
-define(ERR_ARENABATTLE_ENTER_LV_LIMIT,10002).
-define(ERR_ARENABATTLE_ENTER_FB_LIMIT,10003).
-define(ERR_ARENABATTLE_ENTER_IN_BATTLE,10004).
-define(ERR_ARENABATTLE_ENTER_MAX_ROLE_NUM,10005).
-define(ERR_ARENABATTLE_ENTER_TITLE_LIMIT,10006).
-define(ERR_ARENABATTLE_ENTER_SPLIT_LIMIT,10007).
-define(ERR_ARENABATTLE_QUIT_NOT_IN_MAP,11001).




%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).

handle({_, ?ARENABATTLE, ?ARENABATTLE_ENTER,_,_,_,_}=Info) ->
    %% 进入战场
    do_arenabattle_enter(Info);
handle({_, ?ARENABATTLE, ?ARENABATTLE_QUIT,_,_,_,_}=Info) ->
    %% 退出战场
    do_arenabattle_quit(Info);

  
handle({open_slave_arenabattle,SlaveMapIdx,SlaveNum,IsOpen}) ->
    do_open_slave_arenabattle(SlaveMapIdx,SlaveNum,IsOpen);  
handle({update_slave_arenabattle_timedata,SlaveMapIdx,TimeData}) ->
    do_update_slave_arenabattle_timedata(SlaveMapIdx,TimeData);  

handle({req_arenabattle_entrance_info}) ->
    do_req_arenabattle_entrance_info();
handle({req_arenabattle_sub_entrance_info}) ->
    do_req_arenabattle_sub_entrance_info();
handle({init_arenabattle_entrance_info,EntranceInfo}) ->
    do_init_arenabattle_entrance_info(EntranceInfo);
handle({update_arenabattle_entrance_info,ValList}) ->
    do_update_arenabattle_entrance_info(ValList);
handle({syn_arenabattle_sub_entrance_info,BattleMapIdx,SubEntranceInfo}) ->
    do_syn_arenabattle_sub_entrance_info(BattleMapIdx,SubEntranceInfo);

handle({transfer_role_from_site,FighterIdList,SiteID}) ->
    do_transfer_role_from_site(FighterIdList,SiteID);
handle({cast_line_order}) ->
    do_cast_line_order();

handle({split_battle_time_banlance}) ->
    do_split_battle_time_banlance();
handle({gm_reset_open_times}) ->
    reset_battle_open_times();
handle({gm_open_battle, Second}) ->
    case is_opening_battle() of
        true->
            ignore;
        _ ->
            gm_open_arenabattle(Second)
    end;
handle({gm_close_battle}) ->
    case is_opening_battle() of
        true->
            TimeData = get_arenabattle_time_data(),
            TimeData2 = TimeData#r_arenabattle_time{end_time=common_tool:now()},
            put(?ARENABATTLE_TIME_DATA,TimeData2),
            
            case get_arenabattle_map_info() of
                #r_arenabattle_map_info{slave_num=SlaveNum}->
                        update_slave_arenabattle_timedata(SlaveNum,TimeData2);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end;

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

init(MapId, _MapName) ->
    case is_fb_map_id(MapId) of
        true->
            case ?find_config(enable_arenabattle) of
                [true]->
                    BattleMapInfo = #r_arenabattle_map_info{is_opening=false,role_num=0,max_role_num=0},
                    set_arenabattle_map_info(BattleMapInfo),
                    reset_battle_open_times();
                _ ->
                    ignore
            end;
        _ ->
            ignore
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
    ?ARENABATTLE_MAP_ID =:= DestMapId.

add_arenabattle_role_info(RoleID,OpponentRoleID) ->
    case mod_map_role:get_role_base(RoleID) of
        {ok,#p_role_base{role_name=RoleName,head=Head,faction_id=FactionId}}->
            Rec = #r_arenabattle_role_info{role_id=RoleID,role_name=RoleName,head=Head,faction_id=FactionId,
										   prev_opponent_role_id=OpponentRoleID},
            add_arenabattle_role_info(Rec);
        _ ->
            ignore
    end.
add_arenabattle_role_info(BattleRoleInfo) ->
    case get(?ARENABATTLE_ROLES) of
        undefined->
            put(?ARENABATTLE_ROLES,[BattleRoleInfo]);
        List ->
            #r_arenabattle_role_info{role_id=RoleID} = BattleRoleInfo,
            List2 = lists:keystore(RoleID, #r_arenabattle_role_info.role_id, List, BattleRoleInfo),
            put(?ARENABATTLE_ROLES,List2)
    end.
get_arenabattle_role_info(RoleID)->
    case get(?ARENABATTLE_ROLES) of
        undefined->
            false;
        List ->
            lists:keyfind(RoleID, #r_arenabattle_role_info.role_id, List)
    end.

get_arenabattle_score_data()->
    get(?ARENABATTLE_SCORE_DATA).
set_arenabattle_score_data(ScoreData2)->
    put(?ARENABATTLE_SCORE_DATA,ScoreData2).

get_arenabattle_time_data()->
    get(?ARENABATTLE_TIME_DATA).
set_arenabattle_time_data(TimeData2)->
    put(?ARENABATTLE_TIME_DATA,TimeData2).

get_arenabattle_entrance_info()->
    get(?ARENABATTLE_ENTRANCE_INFO).

get_arenabattle_sub_entrance_info(BattleMapIdx)->
    get({?ARENABATTLE_SUB_ENTRANCE_INFO,BattleMapIdx}).

set_arenabattle_sub_entrance_info(BattleMapIdx,SubEntranceInfo)->
    put({?ARENABATTLE_SUB_ENTRANCE_INFO,BattleMapIdx},SubEntranceInfo).

get_arenabattle_map_info()->
    get(?ARENABATTLE_MAP_INFO).
set_arenabattle_map_info(BattleMapInfo)->
    put(?ARENABATTLE_MAP_INFO,BattleMapInfo).

loop(_MapId,NowSeconds) ->
    case get_arenabattle_time_data() of
        #r_arenabattle_time{date=Date} = NationBattleTimeData ->
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
    case ?find_config(enable_arenabattle) of
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

loop_opening(NowSeconds,NationBattleTimeData)->
    #r_arenabattle_time{end_time=EndTime} = NationBattleTimeData,
    
    %% 副本开启过程中广播处理
    do_fb_open_process_broadcast(NowSeconds,NationBattleTimeData),
    
    if
        EndTime>0 andalso NowSeconds>=EndTime->
			?TRY_CATCH( do_battle_fb_log() ),
            {ok,NextStartTimeSeconds} = reset_battle_open_times(),

            %% 关闭副本
            close_arenabattle(NextStartTimeSeconds),
            %% 活动关闭消息的提示
            common_activity:notfiy_activity_end(?ARENABATTLE_ACTIVITY_ID),
            ok;
        true->
            %% 加经验循环
            case ?find_config(fb_add_exp) of
                [{true,_}]->
                    do_add_exp_interval(NowSeconds);
                _ ->
                    ignore
            end,
            
            %%判断战斗队列、判断休整队列，判断排队队列
            loop_fight_queue( NowSeconds ),
            loop_rest_queue( NowSeconds ),
            loop_line_queue( NowSeconds )
    end.

loop_fight_queue( NowSeconds )->
    #r_arenabattle_map_info{fight_queue=FightQueue} = get_arenabattle_map_info(),
    lists:foreach(
      fun(E)-> 
              {SiteID,FighterIdList,_StartTime,EndTime} = E,
              if
                  NowSeconds>=EndTime->
                      [RoleIDA,RoleIDB] = FighterIdList,
                      do_battle_finish(SiteID,RoleIDA,RoleIDB,?ARENA_RESULT_DRAW,?ARENA_RESULT_DRAW);
                  true->
                      ignore
              end 
      end, FightQueue),
    ok.

loop_rest_queue( NowSeconds )->
    #r_arenabattle_map_info{rest_queue=RestQueue} = BattleMapInfo = get_arenabattle_map_info(),
    lists:foreach(
      fun(E)-> 
              {RoleID,StartTime,EndTime} = E,
              if
                  NowSeconds>=EndTime->
                      update_role_line_status(RoleID,BattleMapInfo);
                  NowSeconds>=(StartTime+3) ->
                      %%3秒后从擂台移出来，处理复活
                      relive_role_in_rest(RoleID); 
                  true->
                      ignore
              end 
      end, RestQueue),
    ok.

%%将那些不在地图中的用户清除掉
reset_line_queue()->
    BattleMapInfo1 = get_arenabattle_map_info(),
    #r_arenabattle_map_info{line_queue=LineQueue1} = BattleMapInfo1,
    LineQueue2 = lists:foldr(
                   fun(E,AccIn)->
                           case is_role_real_in_map(E) of
                               true->
                                   [E|AccIn];
                               _ ->
                                   AccIn
                           end
                   end, [], LineQueue1),
    BattleMapInfo2 = BattleMapInfo1#r_arenabattle_map_info{line_queue=LineQueue2},
    set_arenabattle_map_info( BattleMapInfo2 ),
    {ok,BattleMapInfo2}.

loop_line_queue( _NowSeconds )->
    {ok,BattleMapInfo} = reset_line_queue(),
    #r_arenabattle_map_info{line_queue=LineQueue,arena_sites=ArenaSites} = BattleMapInfo,
    LineNum = length(LineQueue),
    if
        LineNum>1->
            {RoleIDA,RoleIDB} = select_fighters_from_line_queue(LineQueue),
            case lists:keyfind(?ARENA_SITE_STATUS_BLANK, 2, ArenaSites) of
                false->
                    ignore;
                {SiteID,_}->
                    do_battle_start(RoleIDA,RoleIDB,SiteID)
            end;
        true->
            ignore
    end,
    ok.

%%从排队队列中选取参战者
%%@return {RoleIDA,RoleIDB}
select_fighters_from_line_queue(LineQueue) when is_list(LineQueue)->
	[RoleIDA|T] = LineQueue,
	RoleIDB =
		case get_arenabattle_role_info(RoleIDA) of
			false ->
				SelectedIdList = lists:sublist(T, 5),
				common_tool:random_element(SelectedIdList);
			#r_arenabattle_role_info{prev_opponent_role_id=PrevOpponentRoleID} ->
				T2 = lists:delete(PrevOpponentRoleID, T),
				SelectedIdList = lists:sublist(T2, 5),
				case erlang:length(SelectedIdList) of
					0 ->
						PrevOpponentRoleID;
					_ ->
						common_tool:random_element(SelectedIdList)
				end
		end,
	{RoleIDA,RoleIDB}.
 
loop_closing(NowSeconds,NationBattleTimeData)->
    #r_arenabattle_time{start_time=StartTime, end_time=EndTime} = NationBattleTimeData,
    if
        StartTime>0 andalso NowSeconds>=StartTime->
            open_arenabattle();
        true->
            %% 活动开始消息通知
            common_activity:notfiy_activity_start({?ARENABATTLE_ACTIVITY_ID, NowSeconds, StartTime, EndTime}),
            %%提前开始广播
            do_fb_open_before_broadcast(NowSeconds,NationBattleTimeData)
    end.


get_fb_map_name() ->
    common_map:get_common_map_name( ?ARENABATTLE_MAP_ID ).

is_in_fb_map()->
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{}->
            true;
        _ ->
            false
    end.

%%更新排队序号
do_cast_line_order()->
    erlang:send_after(?CAST_LINE_ORDER_INTERVAL, self(), {mod,?MODULE,{cast_line_order}}),
	#r_arenabattle_map_info{line_queue=LineQueue} = get_arenabattle_map_info(),
    do_cast_line_order_2(LineQueue,erlang:length(LineQueue)).

do_cast_line_order_2([],_QueueLen) ->
	ignore;
do_cast_line_order_2([RoleID|T],QueueLen) ->
	R2 = #m_arenabattle_update_toc{status=?ARENA_ROLE_STATUS_LINE,line_order=QueueLen-erlang:length(T)},
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ARENABATTLE, ?ARENABATTLE_UPDATE, R2),
	do_cast_line_order_2(T,QueueLen).


%% 玩家跳转进入战场地图进程
get_map_name_to_enter(RoleId)->
    case get({?ARENABATTLE_MAP_NAME_TO_ENTER,RoleId}) of
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
    put({?ARENABATTLE_MAP_NAME_TO_ENTER,RoleID},Val).

hook_role_enter(RoleID,_MapID)->
   case get_arenabattle_map_info() of
       #r_arenabattle_map_info{}=BattleMapInfo->
           hook_role_enter_2(RoleID,BattleMapInfo);
       _ ->
           ignore
   end.

%%更新玩家的战斗状态
update_role_fight_status(RoleIDA,RoleIDB,SiteID,BattleMapInfo)->
    %%加入战斗的队列，退出排队队列
    #r_arenabattle_map_info{fight_queue=FightQueue,line_queue=LineQueue,arena_sites=ArenaSites} = BattleMapInfo,
    
    Now = common_tool:now(),
    [{FightTime,_RestTime}] = ?find_config(fb_arena_time),
    NewFighterIdList = [RoleIDA,RoleIDB],
    NewSiteFightInfo = {SiteID,NewFighterIdList,Now,(Now+FightTime)},
    FightQueue2 = lists:keystore(SiteID, 1, FightQueue, NewSiteFightInfo),
    LineQueue2 = lists:delete(RoleIDB, lists:delete(RoleIDA, LineQueue)),
    %%擂台变为战斗状态
    ArenaSites2 = lists:keystore(SiteID, 1, ArenaSites, {SiteID,?ARENA_SITE_STATUS_FIGHT}),
    
    set_arenabattle_map_info(BattleMapInfo#r_arenabattle_map_info{
                                                                  fight_queue=FightQueue2,
                                                                  line_queue=LineQueue2,
                                                                  arena_sites=ArenaSites2}),
    R2 = #m_arenabattle_update_toc{status=?ARENA_ROLE_STATUS_FIGHT,duration=FightTime},
    common_misc:unicast({role, RoleIDA}, ?DEFAULT_UNIQUE, ?ARENABATTLE, ?ARENABATTLE_UPDATE, R2),
    common_misc:unicast({role, RoleIDB}, ?DEFAULT_UNIQUE, ?ARENABATTLE, ?ARENABATTLE_UPDATE, R2),
    %%修改PK模式
    mod_role2:modify_pk_mode_for_role(RoleIDA,?PK_ALL),
    mod_role2:modify_pk_mode_for_role(RoleIDB,?PK_ALL),
    ok.
    
%%更新玩家的休整状态
update_role_rest_status(SiteID,FighterIdList)->
    Now = common_tool:now(),
    BattleMapInfo = get_arenabattle_map_info(),
    #r_arenabattle_map_info{fight_queue=FightQueue,rest_queue=RestQueue} = BattleMapInfo,
    
    [{_FightTime,RestTime}] = ?find_config(fb_arena_time),
    RestQueue2 = lists:foldl(
                   fun(FighterId,AccIn)-> 
                           case is_role_real_in_map(FighterId) of
                               true->
                                   [{FighterId,Now,(Now+RestTime)}|lists:keydelete(FighterId, 1, AccIn)] ;
                               _ ->
                                   lists:keydelete(FighterId, 1, AccIn)
                           end
                   end, RestQueue, FighterIdList),
    
    %%加入休整的队列，退出战斗队列
    if
        SiteID>0->
            FightQueue2 = lists:keydelete(SiteID, 1, FightQueue);
        true->
            FightQueue2 = FightQueue
    end,
    set_arenabattle_map_info(BattleMapInfo#r_arenabattle_map_info{
                                                                  fight_queue=FightQueue2,
                                                                  rest_queue=RestQueue2}),
    R2 = #m_arenabattle_update_toc{status=?ARENA_ROLE_STATUS_REST,duration=RestTime},
    lists:foreach(
      fun(E)->
              catch common_misc:unicast({role, E}, ?DEFAULT_UNIQUE, ?ARENABATTLE, ?ARENABATTLE_UPDATE, R2)
      end, FighterIdList),
    ok.

%%更新玩家的排队状态
update_role_line_status(RoleID,BattleMapInfo)->
    #r_arenabattle_map_info{line_queue=LineQueue,rest_queue=RestQueue} = BattleMapInfo,
    
    %%加入排队的队列，退出休整的队列
    LineQueue2 = lists:append(lists:delete(RoleID, LineQueue), [RoleID]),
    case lists:keyfind(RoleID, 1, RestQueue) of
        false->
            RestQueue2 = RestQueue;
        _ ->
            RestQueue2  = lists:keydelete(RoleID, 1, RestQueue)
    end,
    set_arenabattle_map_info(BattleMapInfo#r_arenabattle_map_info{
                                                                  rest_queue=RestQueue2,
                                                                  line_queue=LineQueue2}),
    LineOrder = length(LineQueue2),
    R2 = #m_arenabattle_update_toc{status=?ARENA_ROLE_STATUS_LINE,line_order=LineOrder},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ARENABATTLE, ?ARENABATTLE_UPDATE, R2),
    ok.

%%@doc 开放更多擂台
open_more_arena_site(NewRoleNum,_) when NewRoleNum<?ARENA_ROLE_NUM_PER_SITE->
    ignore;
open_more_arena_site(NewRoleNum,BattleMapInfo)->
    %%每10个人就多开放一个场地
    SiteNum = (NewRoleNum div ?ARENA_ROLE_NUM_PER_SITE) + 1,
    if
        SiteNum>8-> SiteNum2 = 8;
        true->  SiteNum2 = SiteNum
    end,
    #r_arenabattle_map_info{arena_sites=OldArenaSites} = BattleMapInfo,
    case length(OldArenaSites)>= SiteNum2 of
        true->
            BattleMapInfo2 = BattleMapInfo,
            ignore;
        _ ->
            ArenaSites2 = [{SiteNum2,?ARENA_SITE_STATUS_BLANK}|OldArenaSites],
            BattleMapInfo2 = BattleMapInfo#r_arenabattle_map_info{arena_sites=ArenaSites2},
            set_arenabattle_map_info(BattleMapInfo2)
    end,
    {ok,BattleMapInfo2}.

hook_role_enter_2(RoleID,BattleMapInfo)->
    case BattleMapInfo of
        #r_arenabattle_map_info{is_opening=true,role_num=CurRoleNum,max_role_num=MaxRoleNum,
                                 split_jingjie=SplitJingjie,
                                 my_slave_map_idx=MySlaveMapIdx,
                                 faction_role_num=FactionRoleNumList
                                 }->
            mod_role2:modify_pk_mode_for_role(RoleID,?PK_PEACE),
            NewRoleNum = CurRoleNum+1,
			NewMaxRoleNum = erlang:max(MaxRoleNum,NewRoleNum),
            %%同步入口信息
            
            FactionId = get_role_faction_id(RoleID),
            NewFactionRoleNumList = get_new_faction_role_num_list(enter,FactionRoleNumList,FactionId),
            
            syn_arenabattle_sub_entrance_info(MySlaveMapIdx,NewRoleNum,NewFactionRoleNumList),
            
            BattleMapInfo2 = BattleMapInfo#r_arenabattle_map_info{role_num=NewRoleNum,max_role_num=NewMaxRoleNum,
                                                                              faction_role_num=NewFactionRoleNumList},
            set_arenabattle_map_info(BattleMapInfo2),
            
            %%确认境界分流
            case mod_map_role:get_role_attr(RoleID) of
                {ok,#p_role_attr{jingjie=RoleJingjie}}->
                    catch assert_split_jingjie(MySlaveMapIdx,RoleJingjie,SplitJingjie);
                _ ->
                    next
            end,
            
            %%发送副本的信息
            case get_arenabattle_time_data() of
                #r_arenabattle_time{start_time = StartTime,end_time = EndTime} ->
                    next;
                _ ->
                    StartTime = 0,EndTime = 0
            end,
            
            %% 插入加经验列表
            insert_interval_exp_list(RoleID),

            %% 完成活动
            hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_ARENABATTLE),
            
            
            MyScore = get_my_arena_score(RoleID),
            R1 = #m_arenabattle_info_toc{fb_start_time=StartTime,fb_end_time=EndTime,fb_my_score=MyScore},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ARENABATTLE, ?ARENABATTLE_INFO, R1),
            
            %% 开放更多擂台
            open_more_arena_site(NewRoleNum,BattleMapInfo2),
            
            %%战场的个人状态更新
            update_role_rest_status(0,[RoleID]),
            ok;
        _ ->
            do_arenabattle_quit_map(RoleID),
            ?ERROR_MSG("副本关闭了，还有人进来！RoleID=~w",[RoleID])
    end.

get_my_arena_score(RoleID)->
    mod_arena_misc:get_arena_total_score(RoleID).

hook_role_quit(RoleID)->
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{is_opening=true,my_slave_map_idx=BattleMapIdx,role_num=CurRoleNum,faction_role_num=FactionRoleNumList}=MapInfo->
            %%修改PK模式
            mod_role2:modify_pk_mode_for_role(RoleID,?PK_FACTION),
            
            %% 移出加经验列表
            delete_interval_exp_list(RoleID),
            %% 触发战斗结束，并退出队列
            case is_role_in_fight(RoleID) of
                true->
                    do_arenabattle_quit_fight(RoleID);
                _ ->
                    do_arenabattle_quit_map(RoleID)
            end,
            
            NewRoleNum = CurRoleNum-1,
            FactionId = get_role_faction_id(RoleID),
            NewFactionRoleNumList = get_new_faction_role_num_list(quit,FactionRoleNumList,FactionId),
            
            syn_arenabattle_sub_entrance_info(BattleMapIdx,NewRoleNum,NewFactionRoleNumList),
            
            set_arenabattle_map_info(MapInfo#r_arenabattle_map_info{role_num=NewRoleNum,
                                                                      faction_role_num=NewFactionRoleNumList}),
            ok;
        _ ->
            ignore
    end.

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

is_role_in_current_map(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        #p_map_role{}->
            true;
        _ ->
            false
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

hook_role_dead(DeadRoleID, _SActorID, _SActorType)->
    do_battle_finish(DeadRoleID,?ARENA_RESULT_ENEMY_WIN),
    ok.

check_map_fight(RoleID,TargetRoleID)->
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{is_opening=true}->
            case get_role_fight_info(RoleID) of
                false->
                    {error, ?_LANG_ARENABATTLE_FIGHT_SELF_NOT_IN_FIGHT_QUEUE};
                {_SiteID,FighterIdList,_,_}->
                    case lists:member(TargetRoleID, FighterIdList) of
                        true-> true;
                        _ ->
                            {error, ?_LANG_ARENABATTLE_FIGHT_TARGET_NOT_IN_FIGHT_QUEUE}
                    end
            end;
        #r_arenabattle_map_info{is_opening=false}->
            {error, ?_LANG_ARENABATTLE_FIGHT_FB_CLOSED};
        _ ->
            true
    end.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

is_role_in_fight(RoleID)->
    case get_role_fight_info(RoleID) of
        false-> false;
        _ -> true
    end.
is_arena_fighter(RoleID)->
    is_role_in_fight(RoleID).

%%@doc 是否为竞技场的观众(处于休整队列/排队队列)
is_arena_watcher(RoleID)->
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{line_queue=LineQueue,rest_queue=RestQueue}->
            case lists:member(RoleID, LineQueue) of
                true-> true;
                _ ->
                    case lists:keyfind(RoleID, 1, RestQueue) of
                        false-> false;
                        _ -> true
                    end
            end;
        _ ->
            false
    end.
    
%%获取玩家的战斗信息
get_role_fight_info(RoleID)->    
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{fight_queue=FightQueue}->
            case length(FightQueue)>0 of
                true->
                    get_role_fight_info_2(RoleID,FightQueue);
                _ ->
                    false
            end;
        _ ->
            false
    end.
get_role_fight_info_2(_RoleID,[])->
    false;
get_role_fight_info_2(RoleID,[H|T])->
    {_SiteID,FighterIdList,_,_} = H,
    case lists:member(RoleID, FighterIdList) of
        true->  H;
        _ ->
            get_role_fight_info_2(RoleID,T)
    end.

 
do_arenabattle_enter({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    case catch check_arenabattle_enter(RoleID,DataIn) of
        {ok,FactionId,SlaveMapIdx}->
            do_arenabattle_enter_2(RoleID,FactionId,SlaveMapIdx);
        {error,ErrCode,Reason}->
            R2 = #m_arenabattle_enter_toc{error_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

do_arenabattle_enter_2(RoleID,FactionId,SlaveMapIdx)->
    %%地图跳转
    FBMapId = ?ARENABATTLE_MAP_ID,
    {Tx,Ty} = get_fb_born_points(FactionId),
    
    BattleMapName = get_map_name_by_slave_idx(SlaveMapIdx),
    set_map_enter_tag(RoleID,BattleMapName,SlaveMapIdx),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID, FBMapId, Tx, Ty),
    ok.

do_arenabattle_quit({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_arenabattle_quit_tos{type=QuitType} = DataIn,
    case catch check_arenabattle_quit(RoleID,DataIn) of
        ok->
            case QuitType of
                ?QUIT_TYPE_MAP->
                    do_arenabattle_quit_map(RoleID);
                ?QUIT_TYPE_FIGHT->
                    do_arenabattle_quit_fight(RoleID)
            end,
            R2 = #m_arenabattle_quit_toc{type=QuitType};
        {error,ErrCode,Reason}->
            R2 = #m_arenabattle_quit_toc{type=QuitType,error_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

do_arenabattle_quit_fight(RoleID)->
    do_battle_finish(RoleID,?ARENA_RESULT_SELF_QUIT),
    ok.

do_arenabattle_quit_map(RoleID)->
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{rest_queue=RestQueue,line_queue=LineQueue}=BattleMapInfo->
            %%从队列（排队队列、休整队列）中删除。
            case lists:keyfind(RoleID, 1, RestQueue) of
                false-> RestQueue2 = RestQueue;
                Ele ->  RestQueue2 = lists:delete(Ele, RestQueue)
            end,
            LineQueue2 = lists:delete(RoleID, LineQueue),
            set_arenabattle_map_info(BattleMapInfo#r_arenabattle_map_info{rest_queue=RestQueue2,
                                                                          line_queue=LineQueue2}),
            ok;
        _ ->
            next
    end,
    transfer_from_arena(RoleID,false).


%%战斗开始
do_battle_start(RoleIDA,RoleIDB,SiteID)->
    %% 修改状态（->战斗；传送到擂台上）。
    BattleMapInfo = get_arenabattle_map_info(),
    add_arenabattle_role_info(RoleIDA,RoleIDB),
    add_arenabattle_role_info(RoleIDB,RoleIDA),
    
    update_role_fight_status(RoleIDA,RoleIDB,SiteID,BattleMapInfo),
    notify_arena_fight_info(SiteID,RoleIDA,RoleIDB,?ARENA_RESULT_START,?ARENA_RESULT_START),
    
    {TX,TY} = get_fb_fight_points(SiteID),
    MapState = mgeem_map:get_state(),
    
    relive_role_in_rest(RoleIDA),
    relive_role_in_rest(RoleIDB),
    
    mod_map_actor:same_map_change_pos(RoleIDA, role, TX, TY, ?CHANGE_POS_TYPE_NORMAL, MapState),
    mod_map_actor:same_map_change_pos(RoleIDB, role, TX, TY, ?CHANGE_POS_TYPE_NORMAL, MapState),
    
    ok.

relive_role_in_rest(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{state=?ROLE_STATE_DEAD}->%%死亡状态
            mod_role2:relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, RoleID, ?RELIVE_TYPE_ORIGINAL_GOLD);
        _ ->
            ignore
    end.

%%@doc 判断玩家是否确实在地图中
is_role_real_in_map(RoleID)->
     case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{}-> true;
        _ ->    false
    end.

%%更新玩家的连胜次数
update_role_conwin_status(RoleResultList) when is_list(RoleResultList)->
    BattleMapInfo = get_arenabattle_map_info(),
    BattleMapInfo2 =
        lists:foldl(
          fun(E,AccIn)-> 
                  {RoleID,Result} = E,
                  #r_arenabattle_map_info{conwin_list=ConwinList,reward_list=RewardList} = AccIn,
                  ConWinTimes = get_conwin_times(RoleID,ConwinList),
                  if
                      Result=:=?ARENA_RESULT_SELF_WIN orelse Result=:= ?ARENA_RESULT_ENEMY_QUIT->
                          NewConWinTimes = ConWinTimes+1,
                          case NewConWinTimes>=5 of
                              true->
                                  %%只取最高的连胜次数
                                  case lists:keyfind(RoleID, 1, RewardList) of
                                      {_,RewardWinTimes} when RewardWinTimes>NewConWinTimes->
                                          RewardList2 = RewardList;
                                      _ ->
                                          RewardList2 = lists:keystore(RoleID, 1, RewardList, {RoleID,NewConWinTimes})
                                  end;
                              _ ->
                                  RewardList2 = RewardList
                          end,
                          ConwinList2 = lists:keystore(RoleID, 1, ConwinList, {RoleID,NewConWinTimes}),
                          AccIn#r_arenabattle_map_info{conwin_list=ConwinList2,
                                                       reward_list=RewardList2};
                      true->
                          ConwinList2 = lists:keydelete(RoleID, 1, ConwinList),
                          AccIn#r_arenabattle_map_info{conwin_list=ConwinList2}
                  end
          end, BattleMapInfo, RoleResultList),
    set_arenabattle_map_info(BattleMapInfo2),
    
    %%更新增加积分的数据
    case get_arenabattle_score_data() of
        undefined->
            ScoreDataList = [];
        ScoreDataList ->
            ok
    end,
    ScoreDataList2 = 
    lists:foldl(
      fun(E,AccIn)-> 
              {RoleID,Result} = E,
              AddScore = get_add_score_by_result(RoleID,Result),
              case lists:keyfind(RoleID, 1, ScoreDataList) of
                  {RoleID,AllAddScore}->
                      AllAddScore2 = AllAddScore+AddScore;
                  _ ->
                      AllAddScore2 = AddScore
              end,
              if
                  AddScore>0 ->
                      lists:keystore(RoleID, 1, AccIn, {RoleID,AllAddScore2});
                  true->
                      AccIn
              end
              end, ScoreDataList, RoleResultList),
    set_arenabattle_score_data( ScoreDataList2 ),
    ok.

%%战斗结束
do_battle_finish(SiteID,RoleIDA,RoleIDB,ResultA,ResultB) when is_integer(SiteID)->
    %% 修改状态（->休整；3秒后传送到观众区）。
    FighterIdList = [RoleIDA,RoleIDB],
    update_role_rest_status(SiteID,FighterIdList),
    update_role_conwin_status( [{RoleIDA,ResultA},{RoleIDB,ResultB}] ),
    
    ?TRY_CATCH( notify_arena_fight_info(SiteID,RoleIDA,RoleIDB,ResultA,ResultB),Err1 ),
    ?TRY_CATCH( notify_arena_conwin(FighterIdList), Err2),
    %%3秒后从擂台移出来
    erlang:send_after(?TRANSFER_FROM_SITE_INTERVAL, self(), {mod,?MODULE,{transfer_role_from_site,FighterIdList,SiteID}}),
    ok.

%%战斗结束
do_battle_finish(RoleIDA,ResultA)->
    case get_role_fight_info(RoleIDA) of
        false->
            ignore;
        {SiteID,FighterIdList,_,_}->
            case FighterIdList of
                [RoleIDA,RoleIDB]-> next;
                [RoleIDB,RoleIDA]-> next
            end,
            case ResultA of
                ?ARENA_RESULT_DRAW-> ResultB = ?ARENA_RESULT_DRAW;
                ?ARENA_RESULT_SELF_WIN-> ResultB = ?ARENA_RESULT_ENEMY_WIN;
                ?ARENA_RESULT_SELF_QUIT-> ResultB = ?ARENA_RESULT_ENEMY_QUIT;
                ?ARENA_RESULT_ENEMY_WIN-> ResultB = ?ARENA_RESULT_SELF_WIN;
                ?ARENA_RESULT_ENEMY_QUIT-> ResultB = ?ARENA_RESULT_ENEMY_QUIT
            end,
            do_battle_finish(SiteID,RoleIDA,RoleIDB,ResultA,ResultB)
    end.

do_transfer_role_from_site(FighterIdList,SiteID)->
    lists:foreach(fun(E)->  transfer_from_arena(E,true) end, FighterIdList),
    
    BattleMapInfo = get_arenabattle_map_info(),
    #r_arenabattle_map_info{arena_sites=ArenaSites} = BattleMapInfo,
    
    %%擂台变为空闲状态 
    ArenaSites2 = lists:keystore(SiteID, 1, ArenaSites, {SiteID,?ARENA_SITE_STATUS_BLANK}),
    set_arenabattle_map_info(BattleMapInfo#r_arenabattle_map_info{arena_sites=ArenaSites2}),
    ok.
    
transfer_from_arena(RoleID,TransferToWatchPoint)->    
    case is_role_real_in_map(RoleID) of
        true->  %%如果还留在地图里面，才进行传输
            relive_role_in_rest(RoleID),
            case TransferToWatchPoint of
                true->
                    {TX,TY} = get_fb_watch_point(),
                    mod_map_actor:same_map_change_pos(RoleID, role, TX, TY, ?CHANGE_POS_TYPE_NORMAL, mgeem_map:get_state());
                _ ->
                    mod_role2:modify_pk_mode_for_role(RoleID,?PK_FACTION),
                    {DestMapId,TX,TY} = get_arenabattle_return_pos(RoleID),
                    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapId, TX, TY)
            end;
        _ ->
            ignore
    end.
    


%%获取副本返回的位置
get_arenabattle_return_pos(RoleID)->
    %%好吧，踢回京城
    common_map:get_map_return_pos_of_jingcheng(RoleID).

%%对服务器进行轮番分配时间片段
do_split_battle_time_banlance()->
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{is_opening=true}->
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
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{split_time_idx=SplitTimeIdx}=OldBattleMapInfo ->
            Next = (SplitTimeIdx+1) rem 2,
            BattleMapInfo = OldBattleMapInfo#r_arenabattle_map_info{split_time_idx=Next},
            set_arenabattle_map_info(BattleMapInfo),
            %%将时间分片的信息更新到王城
            do_req_arenabattle_entrance_info(),
            ok;
        _ ->
            ignore
    end.

%%对所有有的人进行奖励，并踢出地图
reward_and_kick_all_roles()->
    %%获取连胜奖励列表
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{reward_list=RewardList} ->
            ok;
        _ ->
			?ERROR_MSG("get_arenabattle_map_info = null!",[]),
            RewardList = []
    end,
	
	%%发送战场的物品奖励信件
	send_battle_reward_letter(RewardList),
	
    %%踢人
    RoleIdList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              ?TRY_CATCH( notify_battle_reward_when_finish(RoleID,RewardList),Err1 ),
              ?TRY_CATCH( transfer_from_arena(RoleID,false),Err2 )
      end, RoleIdList),
    ok.


%%比赛结束，通知奖励
notify_battle_reward_when_finish(RoleID,RewardList)->
    case lists:keyfind(RoleID, 1, RewardList) of
        {RoleID,ConWinTimes}->
            case get_battle_reward_prop(ConWinTimes) of
                {PropTypeId,Num} when Num>0 ->
                    ok;
                _ ->
                    PropTypeId = 0
            end;
        _ ->
            PropTypeId = 0
    end,
    %%提示获得的积分和道具
    ScoreDataList = get_arenabattle_score_data(),
    case lists:keyfind(RoleID, 1, ScoreDataList) of
        {RoleID,AddScore}->
            R2C = #m_arenabattle_reward_toc{reward_score=AddScore,reward_prop=PropTypeId},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ARENABATTLE, ?ARENABATTLE_REWARD, R2C);
        _ ->
            ignore
    end.

get_battle_reward_prop(ConWinTimes)->
    [RewardPropOrderFactor] = ?find_config(reward_prop_conwin_factor),
    case get_val_config_by_order(ConWinTimes,RewardPropOrderFactor) of
        {Val,Num} when Num>0->
            {Val,Num};
        _ ->
            {0,0}
    end.

get_val_config_by_order(_,[])->
    {0,0};
get_val_config_by_order(Order,[H|T])->
    {MinOrder,MaxOrder,Val,Num} = H,
    if
        Order>=MinOrder andalso MaxOrder>=Order ->
            {Val,Num};
        true->
            get_val_config_by_order(Order,T)
    end.

%% --------------------------------------------------------------------
%%  内部的二级API
%% --------------------------------------------------------------------
assert_role_level(RoleAttr)->
    #p_role_attr{level=RoleLevel} = RoleAttr,
    [MinRoleLevel] = ?find_config(fb_min_role_level),
    if
        MinRoleLevel>RoleLevel->
            ?THROW_ERR( ?ERR_ARENABATTLE_ENTER_LV_LIMIT );
        true->
            next
    end,
    ok.

assert_role_jingjie(RoleAttr)->
    #p_role_attr{jingjie=Jingjie} = RoleAttr,
    [MinRoleTitle] = ?find_config(fb_min_role_jingjie),
    if
        MinRoleTitle>Jingjie->
            ?THROW_ERR( ?ERR_ARENABATTLE_ENTER_TITLE_LIMIT );
        true->
            next
    end,
    ok.

get_fb_min_role_jingjie_str()->
    [MinRoleTitle] = ?find_config(fb_min_role_jingjie),
    common_title:get_jingjie_name(MinRoleTitle).

check_arenabattle_enter(RoleID,_DataIn)->
    [EnableNationBattle] = ?find_config(enable_arenabattle),
    if
        EnableNationBattle=:=true->
            next;
        true->
            ?THROW_ERR( ?ERR_ARENABATTLE_DISABLE )
    end,
    
    {ok,#p_role_base{faction_id=FactionId}} = mod_map_role:get_role_base(RoleID),
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    #p_role_attr{jingjie=RoleJingjie} = RoleAttr,
    assert_role_level(RoleAttr),
    assert_role_jingjie(RoleAttr),
    
    case is_in_fb_map() of
        true->
            ?THROW_ERR( ?ERR_ARENABATTLE_ENTER_IN_BATTLE );
        _ ->
            next
    end,
    #map_state{mapid=MapID,map_type=MapType} = mgeem_map:get_state(),
    IsInWarofkingFb = mod_warofking:is_fb_map_id(MapID),
    
    if
        MapType=:=?MAP_TYPE_COPY->
            ?THROW_ERR( ?ERR_ARENABATTLE_ENTER_FB_LIMIT );
        IsInWarofkingFb->
            ?THROW_ERR(?ERR_ARENABATTLE_ENTER_FB_LIMIT);
        true->
            next
    end,
    %%检查入口信息
    case get_arenabattle_entrance_info() of
        undefined->
            SlaveNum=SplitTimeIdx=SplitJingjie=0,
            req_arenabattle_entrance_info(),
            ?THROW_ERR( ?ERR_ARENABATTLE_ENTER_CLOSING );
        #r_arenabattle_entrance_info{is_opening=true,slave_num=SlaveNum,split_time_idx=SplitTimeIdx,split_jingjie=SplitJingjie}->
            next;
        _ ->
            SlaveNum=SplitTimeIdx=SplitJingjie=0,
            ?THROW_ERR( ?ERR_ARENABATTLE_ENTER_CLOSING )
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
    case get_arenabattle_sub_entrance_info(FinalSlaveMapIdx) of
        undefined->
            req_arenabattle_sub_entrance_info(FinalSlaveMapIdx),
            ?THROW_ERR( ?ERR_ARENABATTLE_ENTER_CLOSING );
        #r_arenabattle_sub_entrance_info{all_role_num=CurRoleNum,faction_role_num=FactionRoleNumList}->
            [{LimitRoleMode,AllRoleNum,FactionRoleNum}] = ?find_config(limit_role_mode),
            CurFactionRoleNum = lists:nth(FactionId, FactionRoleNumList),
            case LimitRoleMode of
                ?LIMIT_ROLE_MODE_MAP_NUM->
                    if
                        CurRoleNum>=AllRoleNum->
                            req_arenabattle_sub_entrance_info(FinalSlaveMapIdx),
                            ?THROW_ERR( ?ERR_ARENABATTLE_ENTER_MAX_ROLE_NUM );
                        true->
                            next
                    end;
                ?LIMIT_ROLE_MODE_FACTION_NUM->
                    if
                        CurFactionRoleNum>=FactionRoleNum->
                            req_arenabattle_sub_entrance_info(FinalSlaveMapIdx),
                            ?THROW_ERR( ?ERR_ARENABATTLE_ENTER_MAX_ROLE_NUM );
                        true->
                            next
                    end
            end;
        _ ->
            ?THROW_ERR( ?ERR_ARENABATTLE_ENTER_CLOSING )
    end,
    {ok,FactionId,FinalSlaveMapIdx}.


check_arenabattle_quit(RoleID,DataIn)->
    #m_arenabattle_quit_tos{type=QuitType} = DataIn,
    case is_in_fb_map() of
        true->
            case QuitType=:=?QUIT_TYPE_MAP andalso is_role_in_fight(RoleID)  of
                true->
                    ?THROW_ERR( ?ERR_ARENABATTLE_QUIT_NOT_IN_MAP );
                _ ->
                    next
            end;
        _->
            ?THROW_ERR( ?ERR_ARENABATTLE_QUIT_NOT_IN_MAP )
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
    case get({?ARENABATTLE_MAP_NAME_TO_ENTER,RoleID}) of
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
            ?THROW_ERR( ?ERR_ARENABATTLE_ENTER_SPLIT_LIMIT )
    end,
    ok.


%%@doc 根据战场的分场索引得出对应的地图名称
get_map_name_by_slave_idx(FinalMapIdx) when is_integer(FinalMapIdx)->
    case FinalMapIdx of
        0-> %%主战场
            common_map:get_common_map_name(?ARENABATTLE_MAP_ID);
        _ ->
            common_map:get_common_map_slave_name(?ARENABATTLE_MAP_ID,FinalMapIdx)
    end.

%%请求更新入口信息
req_arenabattle_entrance_info()->
    send_master_map_msg( {req_arenabattle_entrance_info} ).

req_arenabattle_sub_entrance_info(SlaveMapIdx)->
    send_slave_map_msg(SlaveMapIdx,{req_arenabattle_sub_entrance_info}).

do_req_arenabattle_entrance_info()->
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{is_opening=IsOpening,slave_num=SlaveNum,split_time_idx=SplitTimeIdx,split_jingjie=SplitJingjie}->
            EntranceInfo = #r_arenabattle_entrance_info{is_opening=IsOpening,slave_num=SlaveNum,split_time_idx=SplitTimeIdx,split_jingjie=SplitJingjie},
            init_arenabattle_entrance_info(EntranceInfo),
            ok;
        _ ->
            ignore
    end.

do_req_arenabattle_sub_entrance_info()->
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{role_num=AllRoleNum,my_slave_map_idx=BattleMapIdx,faction_role_num=FactionRoleNumList}->
            syn_arenabattle_sub_entrance_info(BattleMapIdx,AllRoleNum,FactionRoleNumList),
            ok;
        _ ->
            ignore
    end.

%%同步更新入口信息
%%  包括更新到王城、Slave进程
init_arenabattle_entrance_info(EntranceInfo) when is_record(EntranceInfo,r_arenabattle_entrance_info)->
    [EntranceMapIdList] = ?find_config(entrance_map_id),
    lists:foreach(
      fun(EntranceMapId)->
              SendInfo = {mod,?MODULE,{init_arenabattle_entrance_info,EntranceInfo}},
              case global:whereis_name( common_map:get_common_map_name(EntranceMapId) ) of
                  undefined->
                      ignore;
                  MapPID->
                      MapPID ! SendInfo
              end
      end, EntranceMapIdList).

syn_arenabattle_sub_entrance_info(BattleMapIdx,AllRoleNum,FactionRoleNumList) when is_list(FactionRoleNumList)->
    SubEntranceInfo = #r_arenabattle_sub_entrance_info{all_role_num=AllRoleNum,faction_role_num=FactionRoleNumList},
    syn_arenabattle_sub_entrance_info(BattleMapIdx,SubEntranceInfo).
syn_arenabattle_sub_entrance_info(BattleMapIdx,SubEntranceInfo) when is_record(SubEntranceInfo,r_arenabattle_sub_entrance_info)->
    [EntranceMapIdList] = ?find_config(entrance_map_id),
    lists:foreach(
      fun(EntranceMapId)->
              SendInfo = {mod,?MODULE,{syn_arenabattle_sub_entrance_info,BattleMapIdx,SubEntranceInfo}},
              case global:whereis_name( common_map:get_common_map_name(EntranceMapId) ) of
                  undefined->
                      ignore;
                  MapPID->
                      MapPID ! SendInfo
              end
      end, EntranceMapIdList).

do_syn_arenabattle_sub_entrance_info(BattleMapIdx,SubEntranceInfo)->
    set_arenabattle_sub_entrance_info(BattleMapIdx,SubEntranceInfo),
    ok.

do_init_arenabattle_entrance_info(EntranceInfo) when is_record(EntranceInfo,r_arenabattle_entrance_info)->
    put(?ARENABATTLE_ENTRANCE_INFO,EntranceInfo),
    ok.

do_update_arenabattle_entrance_info(ValList) when is_list(ValList)->
    case get(?ARENABATTLE_ENTRANCE_INFO) of
        #r_arenabattle_entrance_info{}= OldInfo->
            EntranceInfo =
                lists:foldl(
                  fun(E,AccIn)-> 
                          {EType,EVal} = E,
                          case EType of
                              is_opening->
                                  AccIn#r_arenabattle_entrance_info{is_opening=EVal}
                          end
                  end, OldInfo, ValList),
            put(?ARENABATTLE_ENTRANCE_INFO,EntranceInfo),
            ok;
        _ ->
            ignore
    end,
    ok.

%%--------------------------------  战场入口消息的代码，可复用  [end]--------------------------------

%%--------------------------------  定时战场的代码，可复用  [start]--------------------------------

is_opening_battle()->
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{is_opening=IsOpening}->
            IsOpening;
        _ ->
            false
    end.

%%@doc 重新设置下一次战场时间
%%@return {ok,NextStartTimeSeconds}
reset_battle_open_times()->
    [OpenTimes] = ?find_config(open_times),
    case OpenTimes of
        {daily,DailyOpenTimes}->
            update_next_fb_open_time(daily,DailyOpenTimes);
        _ ->
            {error,config_err}
    end.

update_next_fb_open_time(daily,DailyOpenTimes) when is_list(DailyOpenTimes)->
    NowSeconds = common_tool:now(),
    {ok,Date,StartTimeSeconds,EndTimeSeconds} = get_next_fb_open_time_daily(NowSeconds,DailyOpenTimes),
    {NextBCStartTime,NextBCEndTime,NextBCProcessTime,
     BeforeInterval,CloseInterval,ProcessInterval} =
        get_next_bc_times(NowSeconds,StartTimeSeconds,EndTimeSeconds),
    R1 = #r_arenabattle_time{date = Date,
                              start_time = StartTimeSeconds,end_time = EndTimeSeconds,
                              next_bc_start_time = NextBCStartTime,
                              next_bc_end_time = NextBCEndTime,
                              next_bc_process_time = NextBCProcessTime,
                              before_interval = BeforeInterval,
                              close_interval = CloseInterval,
                              process_interval = ProcessInterval},
    put(?ARENABATTLE_TIME_DATA,R1),
    {ok,StartTimeSeconds}.

%%@return {ok,Date,StartSeconds,EndSeconds} || {error,not_found)
get_next_fb_open_time_daily(Now,DailyOpenTimes)->
    NowDate = erlang:date(),
    case get_next_fb_open_time_today(NowDate,Now,DailyOpenTimes) of
        {error,not_found}->
            {NextDate,_} = common_tool:seconds_to_datetime(Now+3600*24), %% tomorrow
            get_next_fb_open_time_tomorrow(NextDate,DailyOpenTimes);
        {ok,StartSeconds,EndSeconds}->
            {ok,NowDate,StartSeconds,EndSeconds}
    end.

%%@return {ok,StartSeconds,EndSeconds}
get_next_fb_open_time_today(_NowDate,_NowSeconds,[])->
    {error,not_found};
get_next_fb_open_time_today(NowDate,NowSeconds,[H|T])->
    {StartTimeConf,EndTimeConf} = H,
    StartSeconds = common_tool:datetime_to_seconds({NowDate,StartTimeConf}),
    EndSeconds = common_tool:datetime_to_seconds({NowDate,EndTimeConf}),
    if NowSeconds >= StartSeconds andalso NowSeconds < EndSeconds ->
           {ok,StartSeconds,EndSeconds};
       StartSeconds >=  NowSeconds ->
           {ok,StartSeconds,EndSeconds};
       true ->
           get_next_fb_open_time_today(NowDate,NowSeconds,T)
    end.

%%@return {ok,NextDate,StartSeconds,EndSeconds}
%% get_next_fb_open_time_tomorrow(DailyOpenTimes)->
%%     Now = common_tool:now(),
%%     {NextDate,_} = common_tool:seconds_to_datetime(Now+3600*24), %% tomorrow
%%     get_next_fb_open_time_tomorrow(NextDate,DailyOpenTimes).
get_next_fb_open_time_tomorrow(NextDate,DailyOpenTimes)->
    [{StartTimeConf,EndTimeConf}|_T] = DailyOpenTimes,
    StartSeconds = common_tool:datetime_to_seconds( {NextDate,StartTimeConf} ),
    EndSeconds = common_tool:datetime_to_seconds( {NextDate,EndTimeConf} ),
    {ok,NextDate,StartSeconds,EndSeconds}.
  
%% 根据副本时间和当前时间计算相应的广播时间
%% 返回 {NextBCStartTime,NextBCEndTime,NextBCProcessTime}
get_next_bc_times(NowSeconds,StartTime,EndTime) ->
    [{BeforeSeconds,BeforeInterval}] =  ?find_config(fb_open_before_msg_bc),
    [{ProcessInterval}] =  ?find_config(fb_open_process_msg_bc),
    NextBCStartTime = 
        if NowSeconds >= StartTime ->
                0;
           true ->
                if (StartTime - NowSeconds) >= BeforeSeconds ->
                        StartTime - BeforeSeconds;
                   true ->
                        NowSeconds
                end
        end,
    NextBCEndTime = 
        if NowSeconds >= EndTime ->
               0;
           true ->
               EndTime
        end,
    NextBCProcessTime =
        if NowSeconds > StartTime 
           andalso EndTime > NowSeconds ->
                NowSeconds;
           true ->
                if StartTime =/= 0 ->
                        StartTime;
                   true ->
                        0
                end
        end,
    CloseInterval = 0,
    {NextBCStartTime,NextBCEndTime,NextBCProcessTime,
     BeforeInterval,CloseInterval,ProcessInterval}.

%%--------------------------------  定时战场的代码，可复用  [end]--------------------------------

%%--------------------------------  战场广播的代码，可复用  [start]--------------------------------
%% 副本开起提前广播开始消息
%% Record 结构为 r_arenabattle_time
%% 返回 new r_arenabattle_time
do_fb_open_before_broadcast(NowSeconds,Record) ->
    #r_arenabattle_time{
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
           MinJingjieStr = get_fb_min_role_jingjie_str(),
           BeforeMessage = 
               case StartTime>NowSeconds of
                   true->
                       {_Date,Time} = common_tool:seconds_to_datetime(StartTime),
                       StartTimeStr = common_time:time_string(Time),
                       common_misc:format_lang(?_LANG_ARENABATTLE_PRESTART,[StartTimeStr,MinJingjieStr]);
                   _ ->
                       common_misc:format_lang(?_LANG_ARENABATTLE_STARTED,[MinJingjieStr])
               end,
           catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,BeforeMessage),
           set_arenabattle_time_data( Record#r_arenabattle_time{
                                                                  next_bc_start_time = NowSeconds + BeforeInterval} );
       true ->
           Record
    end.
%% 副本开启过程中广播处理
%% Record 结构为 r_arenabattle_time
%% 返回
do_fb_open_process_broadcast(NowSeconds,Record) ->
    #r_arenabattle_time{
                              start_time = StartTime,
                              end_time = EndTime,
                              next_bc_process_time = NextBCProcessTime,
                              process_interval = ProcessInterval} = Record,
    if 
        StartTime =/= 0 andalso EndTime =/= 0 
       andalso NowSeconds >= StartTime andalso EndTime >= NowSeconds 
       andalso NextBCProcessTime =/= 0
       andalso NowSeconds >= NextBCProcessTime ->
            %% 副本开起过程中广播时间到
            MinJingjieStr = get_fb_min_role_jingjie_str(),
            ProcessMessage = common_misc:format_lang(?_LANG_ARENABATTLE_STARTED,[MinJingjieStr]),
            catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,ProcessMessage),
            set_arenabattle_time_data( Record#r_arenabattle_time{
                                                next_bc_process_time = NowSeconds + ProcessInterval} );
       true ->
            ignore
    end.


%%副本关闭的广播
do_fb_close_broadcast(NextStartTime)->
    EndMessageF = 
        if NextStartTime > 0 ->
               NextDateTime = common_tool:seconds_to_datetime(NextStartTime), 
               NextStartTimeStr = common_time:datetime_to_string( NextDateTime ),
               common_misc:format_lang(?_LANG_ARENABATTLE_CLOSED_TIME,[NextStartTimeStr]);
           true ->
               ?_LANG_ARENABATTLE_CLOSED_FINAL
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
gm_open_arenabattle(Second)->
    %%GM命令，手动开启
    TimeData = get_arenabattle_time_data(),
    StartTime2 = common_tool:now(),
    [FbGmOpenLastTime] = ?find_config(fb_gm_open_last_time),
    EndTime2 = StartTime2 + FbGmOpenLastTime,
    TimeData2 = TimeData#r_arenabattle_time{date=date(),start_time=StartTime2 + Second,end_time=EndTime2},
    set_arenabattle_time_data(TimeData2).

%%开启副本
open_arenabattle()->   
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
    
    set_arenabattle_map_info(#r_arenabattle_map_info{is_opening=true,slave_num=SlaveNum}),
    
    open_slave_arenabattle(SlaveNum,true),
    
    EntranceInfo = #r_arenabattle_entrance_info{is_opening=true,slave_num=SlaveNum},
    init_arenabattle_entrance_info(EntranceInfo),
    
    lists:foreach(
      fun(BattleMapIdx)->
              syn_arenabattle_sub_entrance_info(BattleMapIdx,#r_arenabattle_sub_entrance_info{})
      end, lists:seq(0, SlaveNum)),
    
    ok.


%%关闭副本
close_arenabattle(NextStartTime)->
    do_fb_close_broadcast(NextStartTime),
    
    BattleMapInfo = get_arenabattle_map_info(),
    set_arenabattle_map_info(BattleMapInfo#r_arenabattle_map_info{is_opening=false}),
    
    #r_arenabattle_map_info{slave_num=SlaveNum} = BattleMapInfo,
    open_slave_arenabattle(SlaveNum,false),
    
    EntranceInfo = #r_arenabattle_entrance_info{is_opening=false},
    init_arenabattle_entrance_info(EntranceInfo),
    
    reward_and_kick_all_roles(),
    ok.

%%开启/关闭 Slave战场
open_slave_arenabattle(SlaveNum,IsOpen) when SlaveNum>0->
    lists:foreach(
      fun(SlaveMapIdx)->
              Msg = {open_slave_arenabattle,SlaveMapIdx,SlaveNum,IsOpen},
              send_slave_map_msg(SlaveMapIdx,Msg)
      end, lists:seq(1, SlaveNum)),
    case IsOpen of
        true->
            update_slave_arenabattle_timedata(SlaveNum,get_arenabattle_time_data());
        _ ->
            ignore
    end,
    ok;
open_slave_arenabattle(_SlaveNum,_)->
    ignore.


do_open_slave_arenabattle(SlaveMapIdx,SlaveNum,IsOpen)->
    set_arenabattle_map_info(#r_arenabattle_map_info{is_opening=IsOpen,slave_num=SlaveNum,my_slave_map_idx=SlaveMapIdx}),

    ok.


%%修改Slave战场的时间数据
update_slave_arenabattle_timedata(SlaveNum,TimeData) when SlaveNum>0->
    lists:foreach(
      fun(SlaveMapIdx)->
              Msg = {update_slave_arenabattle_timedata,SlaveMapIdx,TimeData},
              send_slave_map_msg(SlaveMapIdx,Msg)
      end, lists:seq(1, SlaveNum)),
    ok;
update_slave_arenabattle_timedata(_SlaveNum,_)->
    ignore.

do_update_slave_arenabattle_timedata(_SlaveMapIdx,TimeData2)->
    put(?ARENABATTLE_TIME_DATA,TimeData2),
    ok.

%%--------------------------------  战场开/关的代码，可复用 [end] --------------------------------

%%发送战场的物品奖励信件
send_battle_reward_letter(RewardList) when is_list(RewardList)->
	lists:foreach(
	  fun( {RoleID,ConWinTimes} )-> 
			  case get_battle_reward_prop(ConWinTimes) of
				  {PropTypeId,Num} when Num>0 ->
					  %%信件方式赠送物品
					  send_battle_reward_letter(RoleID,ConWinTimes,PropTypeId,Num);
				  _ ->
					  ignore
			  end
	  end, RewardList).
send_battle_reward_letter(RoleID,ConWinTimes,PropTypeId,Num) when is_integer(RoleID),is_integer(Num)->
    GoodsCreateInfo = #r_goods_create_info{
                                           bag_id=1, 
                                           position=1,
                                           bind=true,
                                           type= ?TYPE_ITEM, 
                                           type_id= PropTypeId, 
                                           start_time=0, 
                                           end_time=0,
                                           num= Num},
    case mod_bag:create_p_goods(RoleID,GoodsCreateInfo) of
        {ok,GoodsList} ->
            GoodsList2 = [R#p_goods{id = 1} || R <- GoodsList],
            send_battle_reward_letter_2(RoleID,ConWinTimes,GoodsList2);
        {error,Reason}->
            ?ERROR_MSG("send_battle_reward_letter,Reason=~w,RoleID=~w,PropTypeId=~w",[Reason,RoleID,PropTypeId])
    end.
send_battle_reward_letter_2(RoleID,ConWinTimes,[Goods|_T]) ->
    Title = ?_LANG_ARENABATTLE_LETTER_TITLE,
    GoodsNames = [common_goods:get_notify_goods_name(Goods)],
    Text = common_letter:create_temp(?ARENABATTLE_REWARD_LETTER,[ConWinTimes,GoodsNames]),
    common_letter:sys2p(RoleID,Text,Title,[Goods],14),
    ok.


%%获取擂台的传送点
get_fb_fight_points(SiteID)->
    [FbFightPoints] = ?find_config(fb_fight_points),
    {SiteID,{TX,TY}} = lists:keyfind(SiteID, 1, FbFightPoints),
    {TX,TY}.

%%根据结果得出对应的增加积分
get_add_score_by_result(RoleID,Result)->
    case Result of
        ?ARENA_RESULT_SELF_WIN->
            Score=5 + get_conwin_times(RoleID) div 5;
        ?ARENA_RESULT_ENEMY_QUIT->
            Score=5 + get_conwin_times(RoleID) div 5;
        ?ARENA_RESULT_DRAW->
            Score=2;
        _ ->
            Score=0
    end,
    if
        Score>8-> 8;
        true-> Score
    end.

get_conwin_times(RoleID) when is_integer(RoleID)->
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{conwin_list=ConwinList}->
            get_conwin_times(RoleID,ConwinList);
        _ ->
            0
    end.
get_conwin_times(RoleID,ConwinList) when is_integer(RoleID)->
    case lists:keyfind(RoleID, 1, ConwinList) of
        false->
            0;
        {_,ConWin} ->
            ConWin
    end.
    
get_opponent_info(RoleID,Result)->
    #r_arenabattle_role_info{role_name=RoleName,head=Head,
                             faction_id=FactionId} = get_arenabattle_role_info(RoleID),
    Score = get_add_score_by_result(RoleID,Result),
    {RoleName,FactionId,Head,Score}.

get_battle_fight_start_info(RoleID)->
    #r_arenabattle_role_info{role_name=RoleName,head=Head,
                             faction_id=FactionId} = get_arenabattle_role_info(RoleID),
    TotalScore = mod_arena_misc:get_arena_total_score(RoleID),
    {RoleName,FactionId,Head,TotalScore}.

notify_arena_conwin(FighterIdList) when is_list(FighterIdList)->
    lists:foreach(
      fun(E)-> 
              case mod_map_actor:get_actor_mapinfo(E, role) of
                  #p_map_role{role_name=RoleName} ->
                      ConWinTimes = get_conwin_times(E),
                      BcMessage = get_conwin_bc_msg(RoleName,ConWinTimes),
                      notify_arena_conwin_2( BcMessage );
                  _ ->
                      ignore
              end
      end, FighterIdList),
    ok.
notify_arena_conwin_2( undefined )->
    ignore;
notify_arena_conwin_2( BcMessage )->
    common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CENTER],
                                       ?BC_MSG_TYPE_CHAT_WORLD,BcMessage).
    

get_conwin_bc_msg(RoleName,ConWinTimes=3)->
    common_misc:format_lang(?_LANG_ARENABATTLE_CONWIN_3,[RoleName,ConWinTimes] );
get_conwin_bc_msg(RoleName,ConWinTimes=5)->
    common_misc:format_lang(?_LANG_ARENABATTLE_CONWIN_5,[RoleName,ConWinTimes] );
get_conwin_bc_msg(RoleName,ConWinTimes) when ConWinTimes>=10->
    common_misc:format_lang(?_LANG_ARENABATTLE_CONWIN_10,[RoleName,ConWinTimes] );
get_conwin_bc_msg(_,_)->
    undefined.

notify_arena_fight_info(SiteID,RoleIDA,RoleIDB,?ARENA_RESULT_START,?ARENA_RESULT_START)->
    Result = ?ARENA_RESULT_START,
    {NameA,FactionA,HeadA,ScoreTotalA} = get_battle_fight_start_info(RoleIDA),
    {NameB,FactionB,HeadB,ScoreTotalB} = get_battle_fight_start_info(RoleIDB),
    
    R2A = #m_arenabattle_fight_toc{arena_id=SiteID,result=Result,
                                   opponent_id=RoleIDB,
                                   opponent_head=HeadB,
                                   opponent_faction=FactionB,
                                   opponent_name=NameB,
                                   opponent_score=0,
                                   my_score=0,all_score=ScoreTotalA
                                  },
    R2B = #m_arenabattle_fight_toc{arena_id=SiteID,result=Result,
                                   opponent_id=RoleIDA,
                                   opponent_head=HeadA,
                                   opponent_faction=FactionA,
                                   opponent_name=NameA,
                                   opponent_score=0,
                                   my_score=0,all_score=ScoreTotalB
                                  },
    case is_role_in_current_map(RoleIDA) of
        true->
            common_misc:unicast({role, RoleIDA}, ?DEFAULT_UNIQUE, ?ARENABATTLE, ?ARENABATTLE_FIGHT, R2A);
        _ ->
            ignore
    end,
    case is_role_in_current_map(RoleIDB) of
        true->
            common_misc:unicast({role, RoleIDB}, ?DEFAULT_UNIQUE, ?ARENABATTLE, ?ARENABATTLE_FIGHT, R2B);
        _ ->
            ignore
    end,
    ok;
notify_arena_fight_info(SiteID,RoleIDA,RoleIDB,ResultA,ResultB)->
    {NameA,FactionA,HeadA,AddScoreA} = get_opponent_info(RoleIDA,ResultA),
    {NameB,FactionB,HeadB,AddScoreB} = get_opponent_info(RoleIDB,ResultB),
    
    {ok,ScoreTotalA} = mod_arena_misc:add_arena_score(RoleIDA, AddScoreA),
    {ok,ScoreTotalB} = mod_arena_misc:add_arena_score(RoleIDB, AddScoreB),
    
    R2A = #m_arenabattle_fight_toc{
                                   arena_id=SiteID,result=ResultA,
                                   opponent_id=RoleIDB,
                                   opponent_head=HeadB,
                                   opponent_faction=FactionB,
                                   opponent_name=NameB,
                                   opponent_score=AddScoreB,
                                   my_score=AddScoreA,
                                   all_score=ScoreTotalA
                                  },
    R2B = #m_arenabattle_fight_toc{
                                   arena_id=SiteID,result=ResultB,
                                   opponent_id=RoleIDA,
                                   opponent_head=HeadA,
                                   opponent_faction=FactionA,
                                   opponent_name=NameA,
                                   opponent_score=AddScoreA,
                                   my_score=AddScoreB,
                                   all_score=ScoreTotalB
                                  },
    case is_role_in_current_map(RoleIDA) of
        true->
            common_misc:unicast({role, RoleIDA}, ?DEFAULT_UNIQUE, ?ARENABATTLE, ?ARENABATTLE_FIGHT, R2A);
        _ ->
            ignore
    end,
    case is_role_in_current_map(RoleIDB) of
        true->
            common_misc:unicast({role, RoleIDB}, ?DEFAULT_UNIQUE, ?ARENABATTLE, ?ARENABATTLE_FIGHT, R2B);
        _ ->
            ignore
    end,
    ok.

%%@doc 得到战场的出生点
%%@return   {Tx,Ty}
get_fb_born_points(_RoleID) ->
     [FbBornPoints] = ?find_config(fb_born_points),
     common_tool:random_element(FbBornPoints).

%%@doc 得到战场的观看点
%%@return   {Tx,Ty}
get_fb_watch_point() ->
    [FbWatchPoints] = ?find_config(fb_watch_points),
    case get_arenabattle_map_info() of
        #r_arenabattle_map_info{arena_sites=ArenaSites}->
            FightSiteIDs = [ SiteID||{SiteID,Status}<-ArenaSites, Status=:= ?ARENA_SITE_STATUS_FIGHT],
            case length(FightSiteIDs)>0 of
                true->
                    SiteID = common_tool:random_element(FightSiteIDs);
                _ ->
                    {SiteID,_} = common_tool:random_element(ArenaSites)
            end,
            {SiteID,WatchPoints} = lists:keyfind(SiteID, 1, FbWatchPoints),
            common_tool:random_element(WatchPoints);
        _ ->
            {16,33}
    end.

%%记录战场的日志
do_battle_fb_log() ->
	case get_arenabattle_time_data() of
		#r_arenabattle_time{start_time = StartTime,end_time = EndTime} ->
			case get_arenabattle_map_info() of
				#r_arenabattle_map_info{my_slave_map_idx=MySlaveMapIdx,max_role_num=MaxRoleNum,reward_list=RewardList} ->
					ArenabattleFBLog = 
						#r_arenabattle_fb_log{slave_map_idx=MySlaveMapIdx,
                                              start_time=StartTime,
											  end_time=EndTime,
											  max_role_num=MaxRoleNum,
											  reward_mail_role_num=length(RewardList)},
					common_general_log_server:log_arenabattle_fb(ArenabattleFBLog);
				_ ->
					ignore
			end;
		_ ->
			ignore
	end.

