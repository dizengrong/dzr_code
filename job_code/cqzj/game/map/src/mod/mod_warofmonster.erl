%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     怪物攻城战
%%% @end
%%% Created : 2011-6-16
%%%-------------------------------------------------------------------
-module(mod_warofmonster).
 
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
         get_relive_home_pos/2,
         check_map_fight/2,
         assert_valid_map_id/1,
         get_map_name_to_enter/1,set_map_enter_tag/2,
         clear_map_enter_tag/1
        ]).
-export([
         hook_monster_dead/3,
         hook_server_npc_dead/2,
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
-define(BUY_BUFF_TYPE_SILVER,1).
-define(BUY_BUFF_TYPE_GOLD,2).
-define(WAROFMONSTER_MAP_ID_LIST,[11112,12112,13112]).
-define(WAROFMONSTER_MAP_ID_LIST_2,[{11112,1},{12112,2},{13112,3}]).
-define(BATTLE_RANK_LEN,5).
-define(WAROFMONSTER_MAP_NAME_TO_ENTER,warofmonster_map_name_to_enter).
-define(WAROFMONSTER_ENTRANCE_INFO,warofmonster_entrance_info).
-define(WAROFMONSTER_SUB_ENTRANCE_INFO,warofmonster_sub_entrance_info).


-define(WAROFMONSTER_MAP_INFO,warofmonster_map_info).
-define(WAROFMONSTER_TIME_DATA,warofmonster_time_data).
-define(WAROFMONSTER_ROLE_INFO,warofmonster_role_info).
-define(WAROFMONSTER_FB_GUARD_INFO,warofmonster_fb_guard_info).
-define(WAROFMONSTER_LIVE_GUARD_LIST,warofmonster_live_guard_list). %%活着的超级守卫的列表，不能重复
%% slave_num: 已经开启的子战场的个数
%% split_jingjie: 按境界分流的境界值
-record(r_warofmonster_entrance_info,{is_opening=false}).
-record(r_warofmonster_sub_entrance_info,{map_role_num=0}).

-record(r_warofmonster_map_info,{is_opening=false,max_role_num=0,cur_role_list=[],enter_role_list=[],timer_ref_list=[],
                                 notify_result_times=0,next_refresh_time=0,
                                 fb_faction_id=0,faction_score=0,faction_level=0,fb_result=0,
                                 score_list=[], rank_data=[]}).
            %%cur_role_list     记录当前地图的玩家列表 [{RoleID,FamilyID}]
            %%enter_role_list   进入地图的玩家列表[RoleID]
            %%next_refresh_time     下一次怪物的刷新时间
            %%remain_refresh_times  剩余刷新次数
            %%score_list   所有家族的积分列表（>0的积分）
            %%rank_data    当前的杀戮榜结果，每次积分列表更新之后，会相应更新这个排序结果
            %%notify_result_times   发送更新结果的通告
-record(r_warofmonster_time,{date = 0,start_time = 0,end_time = 0,
                             next_bc_start_time = 0,next_bc_end_time = 0,next_bc_process_time = 0,
                             before_interval = 0,close_interval = 0,process_interval = 0,
                             kick_role_time = 0}).
-record(r_warofmonster_role_info,{my_score=0,my_exp=0,my_prestige=0,my_silver=0}).  %%每个玩家的数据存储
-record(r_warofmonster_guard_info,{id,type_id,cur_energy,max_energy,invest_list=[]}).

-define(CHANGE_TYPE_FACTION_SCORE,1).    %%更新类型：1=势力积分；2=本人积分；3=本人排行
-define(CHANGE_TYPE_MY_SCORE,2).
-define(CHANGE_TYPE_MY_RANK,3).
-define(CHANGE_TYPE_REFRESH_TIME,4).
-define(RESULT_TYPE_WIN,1).
-define(RESULT_TYPE_FAIL,2).

-define(MAX_MONSTER_NUM,200). %%200

-define(GAIN_TYPE_ROLE,1).    %%获得的方式(1=本人击杀2=箭塔击杀3=陷阱击杀)
-define(GAIN_TYPE_TOWER,2).
-define(GAIN_TYPE_TRAP,3).
-define(CONFIG_NAME,warofmonster).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).


%% 对应的活动ID, 与activity_today.config里的一致
-define(WAROFMONSTER_ACTIVITY_ID,10027).

%% 加经验间隔
-define(INTERVAL_EXP_LIST, interval_exp_list).


%% ====================================================================
%% Error Code
%% ====================================================================

-define(ERR_WAROFMONSTER_DISABLE,109999).
-define(ERR_WAROFMONSTER_ENTER_CLOSING,109001).
-define(ERR_WAROFMONSTER_ENTER_LV_LIMIT,109002).
-define(ERR_WAROFMONSTER_ENTER_FB_LIMIT,109003).
-define(ERR_WAROFMONSTER_ENTER_FAMILY_LIMIT,109004).
-define(ERR_WAROFMONSTER_ENTER_FACTION_LIMIT,109005).
-define(ERR_WAROFMONSTER_ENTER_IN_BATTLE,109006).
-define(ERR_WAROFMONSTER_ENTER_MAX_ROLE_NUM,109007).
-define(ERR_WAROFMONSTER_ENTER_JINGJIE_LIMIT,109008).
-define(ERR_WAROFMONSTER_QUIT_NOT_IN_MAP,109010).
-define(ERR_WAROFMONSTER_BUY_BUFF_CD_TIME,109011).
-define(ERR_WAROFMONSTER_BUY_BUFF_EXISTS,109012).
-define(ERR_WAROFMONSTER_BUY_BUFF_NOT_IN_MAP,109013).
-define(ERR_WAROFMONSTER_BUY_BUFF_INVALID_BUFF,109014).
-define(ERR_WAROFMONSTER_BUY_BUFF_SILVER_NOT_ENOUGH,109015).
-define(ERR_WAROFMONSTER_BUY_BUFF_GOLD_NOT_ENOUGH,109016).
-define(ERR_WAROFMONSTER_NOT_IN_MAP,109017).

-define(ERR_WAROFMONSTER_GROW_GUARD_NOT_EXISTS,109018).
-define(ERR_WAROFMONSTER_GROW_GUARD_SILVER_NOT_ENOUGH,109019).
-define(ERR_WAROFMONSTER_GROW_GUARD_GOLD_NOT_ENOUGH,109020).
-define(ERR_WAROFMONSTER_GROW_GUARD_LEVEL_FULL,109021).
-define(ERR_WAROFMONSTER_SUMMON_GUARD_GOLD_NOT_ENOUGH,109022).
-define(ERR_WAROFMONSTER_SUMMON_GUARD_NOT_EXISTS,109023).
-define(ERR_WAROFMONSTER_SUMMON_GUARD_DUPLICATED,109024).
-define(ERR_WAROFMONSTER_SUMMON_GUARD_INVALID_ID,109025).

-define(ERR_WAROFMONSTER_METHOD_NOT_SUPPORT,109099).



%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).

%%C/S接口
handle({_, ?WAROFMONSTER, ?WAROFMONSTER_ENTER,_,_,_,_}=Info) ->
    do_warofmonster_enter(Info);
handle({_, ?WAROFMONSTER, ?WAROFMONSTER_QUIT,_,_,_,_}=Info) ->
    do_warofmonster_quit(Info);
handle({_, ?WAROFMONSTER, ?WAROFMONSTER_BUY_BUFF,_,_,_,_}=Info) ->
    do_warofmonster_buy_buff(Info);
handle({_, ?WAROFMONSTER, ?WAROFMONSTER_GUARD_INFO,_,_,_,_}=Info) ->
    do_warofmonster_guard_info(Info);
handle({_, ?WAROFMONSTER, ?WAROFMONSTER_GROW_GUARD,_,_,_,_}=Info) ->
    do_warofmonster_grow_guard(Info);
handle({_, ?WAROFMONSTER, ?WAROFMONSTER_SUMMON_GUARD,_,_,_,_}=Info) ->
    do_warofmonster_summon_guard(Info);


handle({req_warofmonster_entrance_info}) ->
    do_req_warofmonster_entrance_info();
handle({req_warofmonster_sub_entrance_info}) ->
    do_req_warofmonster_sub_entrance_info();
handle({init_warofmonster_entrance_info,EntranceInfo}) ->
    do_init_warofmonster_entrance_info(EntranceInfo);
handle({update_warofmonster_entrance_info,ValList}) ->
    do_update_warofmonster_entrance_info(ValList);
handle({syn_warofmonster_sub_entrance_info,FactionId,SubEntranceInfo}) ->
    do_syn_warofmonster_sub_entrance_info(FactionId,SubEntranceInfo);
handle({refresh_warofmonster_monster}) ->
    do_refresh_warofmonster_monster();
handle({born_warofmonster_monster,MonsterList,NextIntervalTime}) ->
    do_born_warofmonster_monster(MonsterList,NextIntervalTime);
handle({del_live_guard,GuardId,GuardTypeID}) ->
    do_del_live_guard(GuardId,GuardTypeID);

handle({kick_all_roles}) ->
    do_kick_all_roles();

handle({gm_reset_open_times}) ->
    reset_battle_open_times();
handle({gm_open_battle, Second}) ->
    case is_opening_battle() of
        true->
            ignore;
        _ ->
            gm_open_warofmonster(Second)
    end;
handle({gm_close_battle}) ->
    case is_opening_battle() of
        true->
            TimeData = get_warofmonster_time_data(),
            TimeData2 = TimeData#r_warofmonster_time{end_time=common_tool:now()},
            put(?WAROFMONSTER_TIME_DATA,TimeData2),
            #r_warofmonster_map_info{timer_ref_list=TimerRefList} = get_warofmonster_map_info(),
            catch [ timer:cancel(TRef)||TRef<-TimerRefList ],
            ok;
        _ ->
            ignore
    end;

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

%%刷新怪物
do_refresh_warofmonster_monster()->
    mod_map_monster:delete_all_monster(),
    ServerNpcIdList = mod_server_npc:get_server_npc_id_list(),
    mod_server_npc:delete_server_npc(ServerNpcIdList),
    [ del_warofmonster_fb_guard_info(GuardID)||GuardID<-ServerNpcIdList ],
    
    case get_warofmonster_map_info() of
        #r_warofmonster_map_info{}=OldMapInfo->
            Now = common_tool:now(),
            [FbBornMonsterList] = ?find_config(fb_born_monster),
            [{FirstBornTime,_,_}|_T] =FbBornMonsterList, 
            set_warofmonster_map_info( OldMapInfo#r_warofmonster_map_info{next_refresh_time=Now+FirstBornTime} ),
            [ do_refresh_warofmonster_monster_2(BornTime,NextIntervalTime,MonsterList) ||{BornTime,NextIntervalTime,MonsterList}<-FbBornMonsterList ],
            
            [FbBornServerNpcList] = ?find_config(fb_born_server_npc),
            [ do_refresh_fb_server_npc_2(BornServerNpc) ||BornServerNpc<-FbBornServerNpcList ],
    
            ok;
        _ ->
            ignore
    end.

do_refresh_warofmonster_monster_2(BornTime,NextIntervalTime,MonsterList) when BornTime>0->
    TimerRef = erlang:send_after(BornTime*1000, self(), {mod,?MODULE,{born_warofmonster_monster,MonsterList,NextIntervalTime}}),
    #r_warofmonster_map_info{timer_ref_list=OldList} = OldMapInfo = get_warofmonster_map_info(),
    NewMapInfo = OldMapInfo#r_warofmonster_map_info{timer_ref_list=[TimerRef|OldList]},
    set_warofmonster_map_info(NewMapInfo),
    ok.

do_refresh_fb_server_npc_2(BornServerNpc)->
    #r_born_server_npc{npc_type_Id=NpcTypeID,pos_list=PosList,dir=Dir} = BornServerNpc,
    [ do_refresh_fb_server_npc_3(NpcTypeID,Tx,Ty,Dir) ||{Tx,Ty}<-PosList ].
    
    
do_refresh_fb_server_npc_3(NpcTypeID,Tx,Ty,Dir)->    
    Pos = #p_pos{tx = Tx,ty = Ty,dir = Dir},
    #map_state{mapid=MapID,map_name=MapName} = mgeem_map:get_state(),
    {ok,ServerNpcInfo} = get_server_npc_info(NpcTypeID,MapID,Pos),
    mod_server_npc:init_map_server_npc(MapName, MapID, [ServerNpcInfo]),
    ok.

%%达到时间条件，出生怪物
do_born_warofmonster_monster(MonsterList,NextIntervalTime)->
    case get_warofmonster_map_info() of
        #r_warofmonster_map_info{is_opening=true}=OldMapInfo->
            Now = common_tool:now(),
            [ do_born_warofmonster_monster_2(MonsterParam) ||MonsterParam<-MonsterList ],
            
            %%更新下次的刷新时间
            if
                NextIntervalTime>0 ->
                    set_warofmonster_map_info( OldMapInfo#r_warofmonster_map_info{next_refresh_time=Now+NextIntervalTime} ),
                    notify_battle_refresh_time( Now+NextIntervalTime );
                true->
                    ignore
            end;
        _ ->
            ignore
    end.


do_born_warofmonster_monster_2( {MonsterTypeId,role,PosIndex,PosList} )->
    RoleIDList = mod_map_actor:get_in_map_role(),
    
    %%判断当前的怪物总数
    MonsterIdList = mod_map_monster:get_monster_id_list(),
    AllMonsterNum = length(MonsterIdList),
    case AllMonsterNum > ?MAX_MONSTER_NUM of
        true->
            [ broadcast_arise_monster(RoleID,AllMonsterNum)||RoleID<-RoleIDList ];
        _ ->
            %%根据在线人数判断
            BornNum = get_monster_born_num_by_role( length(RoleIDList) ),
            do_born_warofmonster_monster_2( {MonsterTypeId,BornNum,PosIndex,PosList} )
    end;
do_born_warofmonster_monster_2( {MonsterTypeId,BornNum,PosIndex,PosList} ) when is_integer(BornNum)->
    #map_state{mapid=MapID, map_name=MapProcessName} = mgeem_map:get_state(),
    {ok,MonsterList} = get_born_monster_list(MapID,MonsterTypeId,BornNum,PosList),
    mod_map_monster:init_call_fb_monster(MapProcessName,MapID,MonsterList),
    
    %%广播
    case is_integer(PosIndex) andalso PosIndex>0 of
        true->
            [MonsterBcPosList] = ?find_config(fb_monster_broadcast_pos),
            {_,NpcIdPostFix} = lists:keyfind(PosIndex, 1, MonsterBcPosList),
            
            RoleIDList = mod_map_actor:get_in_map_role(),
            case get_warofmonster_map_info() of
                #r_warofmonster_map_info{fb_faction_id=FactionId}->
                    [ broadcast_arise_monster(RoleID,FactionId,NpcIdPostFix,BornNum)||RoleID<-RoleIDList ];
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.
     
%%广播怪物的出生点
broadcast_arise_monster(RoleID,AllNum)->
    R2 = #m_warofmonster_arise_monster_toc{monster_num=AllNum,monster_type=1},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFMONSTER, ?WAROFMONSTER_ARISE_MONSTER, R2),
    ok.

broadcast_arise_monster(RoleID,FactionId,NpcIdPostFix,BornNum)->
    NpcId = NpcIdPostFix + FactionId*1000000,
    R2 = #m_warofmonster_arise_monster_toc{arise_pos_id=NpcId,monster_num=BornNum,monster_type=2},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFMONSTER, ?WAROFMONSTER_ARISE_MONSTER, R2),
    ok.

%%@return {ok,MonsterList}
get_born_monster_list(MapID,MonsterTypeId,BornNum,PosList)->
    BornNumList = lists:seq(1, BornNum),
    MonsterList = 
        lists:foldl(
          fun({Tx,Ty},AccIn)->
                  Pos = #p_pos{tx=Tx, ty=Ty, dir=1},
                  lists:foldl(
                    fun(_Seq,AccInMonster)->
                            Monster = #p_monster{reborn_pos=Pos,
                                                 monsterid=mod_map_monster:get_max_monster_id_form_process_dict(),
                                                 typeid=MonsterTypeId,
                                                 mapid=MapID},
                            [Monster|AccInMonster]
                    end, AccIn, BornNumList)
          end, [], PosList),
    {ok,MonsterList}.

init(MapId, _MapName) ->
    case is_fb_map_id(MapId) of
        true->
            FbFactionId = get_fb_faction_id(MapId),
            BattleMapInfo = #r_warofmonster_map_info{is_opening=false,fb_faction_id=FbFactionId,cur_role_list=[],max_role_num=0,rank_data=[]},
            set_warofmonster_map_info(BattleMapInfo),
            reset_battle_open_times(),
            ok;
        _ ->
            ignore
    end.


get_warofmonster_entrance_info()->
    get(?WAROFMONSTER_ENTRANCE_INFO).

get_warofmonster_sub_entrance_info(FactionId)->
    get({?WAROFMONSTER_SUB_ENTRANCE_INFO,FactionId}).

set_warofmonster_sub_entrance_info(FactionId,SubEntranceInfo)->
    put({?WAROFMONSTER_SUB_ENTRANCE_INFO,FactionId},SubEntranceInfo).

get_warofmonster_time_data()->
    get(?WAROFMONSTER_TIME_DATA).
set_warofmonster_time_data(TimeData2)->
    put(?WAROFMONSTER_TIME_DATA,TimeData2).

del_warofmonster_fb_guard_info(GuardID)->
    erase({?WAROFMONSTER_FB_GUARD_INFO,GuardID}).
get_warofmonster_fb_guard_info(GuardID)->
    get({?WAROFMONSTER_FB_GUARD_INFO,GuardID}).
set_warofmonster_fb_guard_info(GuardID,NewGuardInfo)->
    put({?WAROFMONSTER_FB_GUARD_INFO,GuardID},NewGuardInfo).

get_warofmonster_role_info(RoleID)->
    get({?WAROFMONSTER_ROLE_INFO,RoleID}).
set_warofmonster_role_info(RoleID,BattleRoleInfo)->
    put({?WAROFMONSTER_ROLE_INFO,RoleID},BattleRoleInfo).

get_warofmonster_map_info()->
    get(?WAROFMONSTER_MAP_INFO).
set_warofmonster_map_info(BattleMapInfo)->
    put(?WAROFMONSTER_MAP_INFO,BattleMapInfo).

add_warofmonster_live_guard(MapName,MapID,LiveTime,ServerNpcInfo) when LiveTime>0->
    #p_server_npc{npc_id=GuardId,type_id=GuardTypeID} = ServerNpcInfo,
    mod_server_npc:init_map_server_npc(MapName, MapID, [ServerNpcInfo]),
    erlang:send_after( LiveTime*1000 , self(), {mod,?MODULE,{del_live_guard,GuardId,GuardTypeID}}),
    
    case get(?WAROFMONSTER_LIVE_GUARD_LIST) of
        undefined->
            put(?WAROFMONSTER_LIVE_GUARD_LIST,[GuardTypeID]);
        List->
            List2 = [GuardTypeID|lists:delete(GuardTypeID, List)],
            put(?WAROFMONSTER_LIVE_GUARD_LIST,List2)
    end.
do_del_live_guard(GuardId,GuardTypeID)->
    mod_server_npc:delete_server_npc(GuardId),
    case get(?WAROFMONSTER_LIVE_GUARD_LIST) of
        undefined->
            ignore;
        List->
            List2 = [lists:delete(GuardTypeID, List)],
            put(?WAROFMONSTER_LIVE_GUARD_LIST,List2)
    end.

loop(_MapId,NowSeconds) ->
    case get_warofmonster_time_data() of
        #r_warofmonster_time{date=Date} = NationBattleTimeData ->
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
    case ?find_config(enable_warofmonster) of
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
    #r_warofmonster_time{end_time=EndTime} = NationBattleTimeData,
    
    %% 副本开启过程中广播处理
    do_fb_open_process_broadcast(NowSeconds,NationBattleTimeData),
    
    if
        EndTime>0 andalso NowSeconds>=EndTime->
            %% 关闭副本
            close_warofmonster(),
            
            %% 活动关闭消息的提示
            common_activity:notfiy_activity_end(?WAROFMONSTER_ACTIVITY_ID),
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
    #r_warofmonster_time{start_time=StartTime, end_time=EndTime} = NationBattleTimeData,
    if
        StartTime>0 andalso NowSeconds>=StartTime->
            open_warofmonster();
        true->
            %% 活动开始消息通知
            common_activity:notfiy_activity_start({?WAROFMONSTER_ACTIVITY_ID, NowSeconds, StartTime, EndTime}),
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
    lists:member(DestMapId, ?WAROFMONSTER_MAP_ID_LIST).

%% @doc 获取复活的回城点
get_relive_home_pos(_, MapID) ->
    {TX,TY} = get_fb_born_points(), 
    {MapID, TX, TY}.

%%@doc 得到战场的出生点
%%@return   {MapID,Tx,Ty}
get_fb_born_points()->
     [FbBornPoints] = ?find_config(fb_born_points),
     common_tool:random_element(FbBornPoints).


%%@doc 根据国家ID获取对应的地图名称
get_fb_map_name_by_faction(FactionId) when is_integer(FactionId) ->
    FBMapId = lists:nth(FactionId, ?WAROFMONSTER_MAP_ID_LIST),
    common_map:get_common_map_name( FBMapId ).

is_in_fb_map()->
    case get(?WAROFMONSTER_MAP_INFO) of
        #r_warofmonster_map_info{}->
            true;
        _ ->
            false
    end.


check_map_fight(RoleID,TargetRoleID)->
    case get_warofmonster_map_info() of
        #r_warofmonster_map_info{is_opening=true}->
            case mod_map_role:get_role_base(RoleID) of
                {ok,#p_role_base{faction_id=RoleFaction}}->
                    case mod_map_role:get_role_base(TargetRoleID) of
                        {ok,#p_role_base{faction_id=TargetRoleFaction}}->
                            check_map_fight_2(RoleFaction,TargetRoleFaction);
                        _ ->
                            {error, ?_LANG_SYSTEM_ERROR}
                    end;
                _ ->
                    {error, ?_LANG_SYSTEM_ERROR}
            end;
        #r_warofmonster_map_info{is_opening=false}->
            {error, ?_LANG_WAROFMONSTER_FIGHT_FB_CLOSED};
        _ ->
            true
    end.
check_map_fight_2(RoleFaction,TargetRoleFaction)->
    case RoleFaction=:=TargetRoleFaction of
        true->
            {error, ?_LANG_WAROFMONSTER_FIGHT_SAME_FACTION};
        _ ->
            true
    end.

%% 玩家跳转进入战场地图进程
get_map_name_to_enter(RoleID)->
    case get({?WAROFMONSTER_MAP_NAME_TO_ENTER,RoleID}) of
        {_RoleID,FbMapProcessName}->
            FbMapProcessName;
        _ ->
            undefined
    end.

clear_map_enter_tag(_RoleId)->
    ignore.

set_map_enter_tag(RoleID,BattleMapName)->
    Val = {RoleID,BattleMapName},
    put({?WAROFMONSTER_MAP_NAME_TO_ENTER,RoleID},Val).


%% @doc ServerNpc死亡
hook_server_npc_dead(ServerNpcID, _ServerNpcTypeID)->
    case is_in_fb_map() of
        true->
            del_warofmonster_fb_guard_info(ServerNpcID);
        _ ->
            ignore
    end.


%% @doc 怪物死亡
hook_monster_dead(ActorType,KillerActorID,MonsterTypeId)->
    case get_warofmonster_map_info() of
        #r_warofmonster_map_info{is_opening=true,fb_faction_id=FactionId}=OldMapInfo->
            #r_warofmonster_map_info{faction_level=FactionLevel,faction_score=OldFactionScore}=OldMapInfo,
            {AddScore,Silver,Prestage} = get_score_reward_by_monster(MonsterTypeId),
            
            if
                AddScore>0->
                    %%增加势力积分
                    NewFactionScore=OldFactionScore+AddScore,
                    set_warofmonster_map_info(OldMapInfo#r_warofmonster_map_info{faction_score=NewFactionScore}),
                    notify_faction_score(NewFactionScore),
                    
                    %%增加个人积分
                    hook_monster_dead_2(ActorType,KillerActorID,{AddScore,Silver,Prestage}),
                    
                    %%判断比赛是否胜利，是否可以提升等级
                    case judge_fb_result(FactionId,FactionLevel,NewFactionScore) of
                        {true,UpLevel}->
                            notify_battle_result(true,UpLevel,NewFactionScore);
                        false -> ignore
                    end;
                true->
                    ignore
            end;
        _ ->
            ignore
    end.
hook_monster_dead_2(ActorType,KillerActorID,{AddScore,Silver,Prestage})->
    %%增加个人积分
    case ActorType of
        role->
            %%玩家击杀，增加全部积分
            case mod_map_role:get_role_base(KillerActorID) of
                {ok,#p_role_base{role_name=RoleName}}->
                    hook_monster_dead_by_role(KillerActorID,RoleName,{AddScore,Silver,Prestage});
                _ ->
                    ignore
            end;
        server_npc ->
            %%ServerNpc击杀，增加部分积分
            case mod_server_npc:get_server_npc_state(KillerActorID) of
                #server_npc_state{server_npc_info=ServerNpcInfo}->
                    #p_server_npc{npc_kind_id=NpcKindId} = ServerNpcInfo,
                    case NpcKindId of
                        ?SERVER_NPC_KIND_FB_SUPER_GUARD->
                            ignore;
                        _ ->
                            hook_monster_dead_by_server_npc(ServerNpcInfo,{AddScore,Silver,Prestage})
                    end;
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.

hook_monster_dead_by_server_npc(ServerNpcInfo,{AddScore1,AddSilver1,Prestage1})->
    #p_server_npc{npc_id=NpcId,type_id=GuardTypeId,npc_kind_id=NpcKindId} = ServerNpcInfo,
    [NpcRewardRateList] = ?find_config(fb_server_npc_reward_rate),
    case lists:keyfind(GuardTypeId, 1, NpcRewardRateList) of
        {_,Rate} ->
            AddScore2 = AddScore1*Rate div 100,
            AddSilver2 = AddSilver1*Rate div 100,
            Prestage2 = Prestage1*Rate div 100,
            {ok,AllInvestSum,RoleInvestList} = get_role_invest_list(NpcId,GuardTypeId),
            
            ScoreRewardList = [AddScore2,AddSilver2,Prestage2],
            [ hook_score_reward_to_role(RoleID,RoleInvest,AllInvestSum,ScoreRewardList,NpcKindId)||{RoleID,RoleInvest}<-RoleInvestList],
            
            sort_battle_rank();
        _ ->
            ignore
    end.
    
hook_monster_dead_by_role(RoleID,RoleName,{AddScore,AddSilver,AddPrestage})->
    
    OldMapInfo = get_warofmonster_map_info(),                                                                                          
    hook_score_reward_to_role_2(RoleID,RoleName,OldMapInfo,AddScore),
    hook_score_reward_to_role_3(RoleID,AddScore,AddSilver,AddPrestage,?GAIN_TYPE_ROLE),
    
    sort_battle_rank(),
    ok.

hook_score_reward_to_role(RoleID,RoleInvest,AllInvestSum,ScoreRewardList,NpcKindId)->
    [AddScore3,AddSilver3,Prestage3] = [ common_tool:ceil( V*RoleInvest div AllInvestSum )||V<-ScoreRewardList],
    case mod_map_role:get_role_base(RoleID) of
        {ok,#p_role_base{role_name=RoleName}}->
            OldMapInfo = get_warofmonster_map_info(),
            hook_score_reward_to_role_2(RoleID,RoleName,OldMapInfo,AddScore3),
            case NpcKindId of
                ?SERVER_NPC_KIND_FB_TOWER->
                    GainType = ?GAIN_TYPE_TOWER;
                ?SERVER_NPC_KIND_FB_TRAP->
                    GainType = ?GAIN_TYPE_TRAP
            end,
            hook_score_reward_to_role_3(RoleID,AddScore3,AddSilver3,Prestage3,GainType);
        _ ->
            ignore
    end.

hook_score_reward_to_role_2(RoleID,RoleName,OldMapInfo,AddScore)->
    #r_warofmonster_map_info{score_list=ScoreList} = OldMapInfo,
    case lists:keyfind(RoleID, #p_warofmonster_rank.role_id, ScoreList) of
        #p_warofmonster_rank{score=OldScore}->
            next;
        _ ->
            OldScore = 0
    end,
    Now = common_tool:now(),
    NewScore = (OldScore+AddScore),
    NewRank = #p_warofmonster_rank{role_id=RoleID,role_name=RoleName,score=NewScore,
                                 update_time=Now},
    ScoreList2 = lists:keystore(RoleID, #p_warofmonster_rank.role_id, ScoreList, NewRank),
    set_warofmonster_map_info(OldMapInfo#r_warofmonster_map_info{score_list=ScoreList2}),
    
    R2 = #m_warofmonster_change_toc{change_type=[?CHANGE_TYPE_MY_SCORE],my_score=NewScore},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFMONSTER, ?WAROFMONSTER_CHANGE, R2),
    ok.

hook_score_reward_to_role_3(RoleID,AddScore,AddSilver,Prestage,GainType)->
    %%奖励钱币、声望
    TransFun = fun()-> 
                       MoneyType = silver_bind,
                       common_bag2:t_gain_money(MoneyType, AddSilver, RoleID, ?GAIN_TYPE_SILVER_WAROFMONSTER_REWARD),
                       common_bag2:t_gain_prestige(Prestage, RoleID, ?GAIN_TYPE_PRESTIGE_WAROFMONSTER)
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,RoleAttr2}} ->
            
            case get_warofmonster_role_info(RoleID) of
                undefined->
                    NewRoleInfo=#r_warofmonster_role_info{my_score=AddScore,my_prestige=Prestage,my_silver=AddSilver};
                #r_warofmonster_role_info{my_score=MyScore1,my_prestige=MyPrestige1,my_silver=MySilver1}=OldRoleInfo ->
                    NewRoleInfo=OldRoleInfo#r_warofmonster_role_info{my_score=(AddScore+MyScore1),
                                                                     my_prestige=(Prestage+MyPrestige1),
                                                                     my_silver=(AddSilver+MySilver1)}
            end,
            set_warofmonster_role_info(RoleID,NewRoleInfo),
            
            common_misc:send_role_silver_change(RoleID,RoleAttr2),
            common_misc:send_role_prestige_change(RoleID, RoleAttr2),
            
            %%通知奖励
            R3 = #m_warofmonster_gain_toc{type=GainType,my_score=AddScore,my_exp=0,my_prestige=Prestage,my_silver=AddSilver},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFMONSTER, ?WAROFMONSTER_GAIN, R3);
        {atomic,{error,ErrReason}} ->
            ?ERROR_MSG("hook_score_reward_to_role_3 err,ErrReason=~w",[ErrReason]);
        {aborted, AbortErr}->
            ?ERROR_MSG("hook_score_reward_to_role_3 err,AbortErr=~w",[AbortErr])
    end.

sort_battle_rank()->
    case get_warofmonster_map_info() of
        #r_warofmonster_map_info{score_list=ScoreList,rank_data=OldRankList}=BattleMapInfo->
            {ok,ScoreList2,NewRankList} = get_new_rank_list(ScoreList,true),
            set_warofmonster_map_info(BattleMapInfo#r_warofmonster_map_info{score_list=ScoreList2,rank_data=NewRankList}),
            if
                OldRankList=:=NewRankList->
                    ignore;
                true->
                    notify_battle_rank(NewRankList)
            end;
        _ ->
            ignore
    end.


get_score_reward_by_monster(MonsterTypeId) when is_integer(MonsterTypeId)->
    [MonsterRewards] = ?find_config(fb_monster_rewards),
    case lists:keyfind(MonsterTypeId, 1, MonsterRewards) of
        {MonsterTypeId,Score,Silver,Prestage}->
            {Score,Silver,Prestage};
        false->
            {0,0,0}
    end.

hook_role_enter(RoleID,_MapID)->
   case get_warofmonster_map_info() of
       #r_warofmonster_map_info{}=BattleMapInfo->
           hook_role_enter_2(RoleID,BattleMapInfo);
       _ ->
           remove_pve_buff(RoleID)
   end.
hook_role_enter_2(RoleID,BattleMapInfo)->
    case BattleMapInfo of
        #r_warofmonster_map_info{is_opening=true,cur_role_list=CurRoleList,
                              max_role_num=MaxRoleNum, 
                              enter_role_list=EnterRoleList,
                              next_refresh_time=NextRefreshTime,
                              fb_faction_id=FbFactionId,faction_level=FactionLevel,
                              faction_score=FactionScore,
                              score_list=ScoreList,rank_data=RankData}->
            mod_role2:modify_pk_mode_for_role(RoleID,?PK_PEACE),
            
            case mod_map_role:get_role_base(RoleID) of
                {ok, #p_role_base{faction_id=RoleFaction,family_id=FamilyId}}->
                    next;
                _ ->
                    RoleFaction = FamilyId = 0
            end,
            NewRoleList = [{RoleID,FamilyId}|CurRoleList],
            NewRoleNum = length(NewRoleList),
            NewMaxRoleNum = erlang:max(MaxRoleNum,NewRoleNum),
            
            assert_role_faction(RoleFaction,FbFactionId),
            %%同步入口信息
            syn_warofmonster_sub_entrance_info(FbFactionId,NewRoleNum),
            
            %%记录进入地图的总人数
            case lists:member(RoleID, EnterRoleList) of
                true->
                    EnterRoleList2 = EnterRoleList;
                _ ->
                    EnterRoleList2 = [{RoleID,FamilyId}|EnterRoleList]
            end,
            
            set_warofmonster_map_info(BattleMapInfo#r_warofmonster_map_info{cur_role_list=NewRoleList,max_role_num=NewMaxRoleNum,
                                                                      enter_role_list=EnterRoleList2}),
             
            
            %%发送副本的信息
            case get_warofmonster_time_data() of
                #r_warofmonster_time{start_time = StartTime,end_time = EndTime} ->
                    next;
                _ ->
                    StartTime = 0,EndTime = 0
            end,
            case lists:keyfind(RoleID, #p_warofmonster_rank.role_id, ScoreList) of
                #p_warofmonster_rank{order=MyRank,score=MyScore}->
                    next;
                _ ->
                    MyRank = 0,
                    MyScore = 0
            end,
            
            %% 插入加经验列表
            insert_interval_exp_list(RoleID),

            UpgradeNeedScore = get_faction_upgrade_need_score(FactionLevel),
           
            {NextGoldBuffID,NeedCostGold} = next_can_buy_buff(RoleID,?BUY_BUFF_TYPE_GOLD),
            R1 = #m_warofmonster_info_toc{fb_start_time=StartTime,fb_end_time=EndTime,
                                          next_refresh_time=NextRefreshTime,
                                          faction_score=FactionScore,upgrade_need_score=UpgradeNeedScore,
                                          my_score=MyScore,my_rank=MyRank,
                                          next_gold_buff_id=NextGoldBuffID,need_cost_gold=NeedCostGold},
            R2 = #m_warofmonster_rank_toc{ranks=RankData}, 
            
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFMONSTER, ?WAROFMONSTER_ENTER, #m_warofmonster_enter_toc{}),
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFMONSTER, ?WAROFMONSTER_INFO, R1),
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFMONSTER, ?WAROFMONSTER_RANK, R2),
			
            ok;
        _ ->
            do_warofmonster_quit_2(RoleID),
            ?ERROR_MSG("副本关闭了，还有人进来！RoleID=~w",[RoleID])
    end.
hook_role_quit(RoleID)->
    case get_warofmonster_map_info() of
        #r_warofmonster_map_info{is_opening=true,fb_faction_id=FbFactionId,cur_role_list=CurRoleList}=MapInfo->
            NewRoleList = lists:keydelete(RoleID, 1, CurRoleList),
            NewRoleNum = length(NewRoleList),
            syn_warofmonster_sub_entrance_info(FbFactionId,NewRoleNum),
            
            set_warofmonster_map_info(MapInfo#r_warofmonster_map_info{cur_role_list=NewRoleList}),
            
            %% 移出加经验列表
            delete_interval_exp_list(RoleID),
            ok;
        _ ->
            ignore
    end.

hook_role_before_quit(_RoleID)->
    ok.

hook_role_dead(_DeadRoleID, _SActorID, _SActorType)->
    case is_opening_battle() of
        true->
            ignore;
        _ ->
            ignore
    end.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%%@interface 进入地图
do_warofmonster_enter({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    case catch check_warofmonster_enter(RoleID,DataIn) of
        {ok,FactionId}->
            do_warofmonster_enter_2(RoleID,FactionId);
        {error,ErrCode,Reason}->
            R2 = #m_warofmonster_enter_toc{err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.
    

do_warofmonster_enter_2(RoleID,FactionId)->
    %%地图跳转
    FBMapId = lists:nth(FactionId, ?WAROFMONSTER_MAP_ID_LIST),
    {Tx,Ty} = get_fb_born_points(),
    
    BattleMapName = get_fb_map_name_by_faction(FactionId),
    set_map_enter_tag(RoleID,BattleMapName),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID, FBMapId, Tx, Ty),
    ok.

%%@interface 退出地图
do_warofmonster_quit({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    case catch check_warofmonster_quit(RoleID,DataIn) of
        ok->
            do_warofmonster_quit_2(RoleID);
        {error,ErrCode,Reason}->
            R2 = #m_warofmonster_quit_toc{err_code=ErrCode,reason=Reason},
			?UNICAST_TOC(R2)
    end.

do_warofmonster_quit_2(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{state=?ROLE_STATE_DEAD}->%%死亡状态
            mod_role2:relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, RoleID, ?RELIVE_TYPE_ORIGINAL_FREE);
        _ ->
            ignore
    end,
	common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?WAROFMONSTER,?WAROFMONSTER_QUIT,#m_warofmonster_quit_toc{}),
    {DestMapId,TX,TY} = get_warofmonster_return_pos(RoleID),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapId, TX, TY),
    ok.

%%@interface 培养守卫
do_warofmonster_grow_guard({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_warofmonster_grow_guard_tos{grow_type=GrowType,guard_id=GuardId} = DataIn,
    case catch check_warofmonster_guard_info(GuardId) of
        {ok,GuardInfo}->
            case catch do_warofmonster_grow_guard_2(RoleID,GrowType,GuardId,GuardInfo) of
                {ok,IsUpgrade,GuardLevel,CurEnergy,MaxEnergy}->
                    R2 = #m_warofmonster_grow_guard_toc{grow_type=GrowType,guard_id=GuardId,is_upgrade=IsUpgrade,guard_level=GuardLevel,
                                                        cur_energy=CurEnergy,max_energy=MaxEnergy};
                {ok,CurHp,MaxHp}->
                    R2 = #m_warofmonster_grow_guard_toc{grow_type=GrowType,guard_id=GuardId,cur_hp=CurHp,max_hp=MaxHp};
                {error,ErrCode,Reason}->
                    R2 = #m_warofmonster_grow_guard_toc{grow_type=GrowType,guard_id=GuardId,err_code=ErrCode,reason=Reason}
            end;
        {error,ErrCode,Reason}->
            R2 = #m_warofmonster_grow_guard_toc{grow_type=GrowType,guard_id=GuardId,err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

do_warofmonster_grow_guard_2(RoleID,GrowType,GuardId,GuardInfo)->
    case GrowType of
        1-> %%培养能量
            do_warofmonster_grow_guard_2_1(RoleID,GuardId,GuardInfo);
        2-> %%加血
            do_warofmonster_grow_guard_2_2(RoleID,GuardId,GuardInfo)
    end.

do_warofmonster_grow_guard_2_1(RoleID,GuardId,GuardInfo)->
    #r_warofmonster_guard_info{type_id=GuardTypeId,cur_energy=CurEnergy,max_energy=MaxEnergy} = GuardInfo,
    [GuardEnergyList] = ?find_config(fb_server_npc_energy_conf),
    #r_server_npc_energy{cost_type=CostType,cost_money=CostMoney,per_add_energy=PerAddEnergy,max_energy=MaxEnergy,
                         level=Level,
                         next_level_type_id=NextLvTypeId} = lists:keyfind(GuardTypeId,#r_server_npc_energy.type_id,GuardEnergyList),
    
    if
        NextLvTypeId=:=0 ->
            ?THROW_ERR( ?ERR_WAROFMONSTER_GROW_GUARD_LEVEL_FULL );
        true->
            next
    end,
    
    TransFun = fun()-> t_grow_guard(RoleID,CostType,CostMoney,GuardId) end,
    case common_transaction:t( TransFun ) of
        {atomic,  {ok,CostType,RoleAttr2,ServerNpcInfo}} ->
            NewEnergy = CurEnergy+PerAddEnergy,
            IsUpgrade = NewEnergy>=MaxEnergy andalso NextLvTypeId>0,
            case IsUpgrade of
                true->
                    #r_server_npc_energy{max_energy=NewMaxEnergy,
                         level=NewLevel} = lists:keyfind(NextLvTypeId,#r_server_npc_energy.type_id,GuardEnergyList),
                    upgrade_fb_guard(GuardId,ServerNpcInfo,NextLvTypeId);
                _ ->
                    NewLevel = Level,
                    NewMaxEnergy = MaxEnergy,
                    {ok,InvestList2} = get_new_invest_list(RoleID,CostMoney,GuardInfo),
                    NewGuardInfo = GuardInfo#r_warofmonster_guard_info{cur_energy=NewEnergy,max_energy=NewMaxEnergy,invest_list=InvestList2},
                    set_warofmonster_fb_guard_info(GuardId,NewGuardInfo)
            end,
            if
                CostType =:= silver_any ->
                    common_misc:send_role_silver_change(RoleID,RoleAttr2);
                true->
                    common_misc:send_role_gold_change(RoleID,RoleAttr2)
            end,
            {ok,IsUpgrade,NewLevel,NewEnergy,NewMaxEnergy};
        {aborted, AbortErr} ->
            parse_aborted_err(AbortErr)
    end.

get_new_invest_list(RoleID,CostMoney,GuardInfo) when CostMoney>0->
    #r_warofmonster_guard_info{invest_list=InvestList} = GuardInfo,
    case lists:keyfind(RoleID, 1, InvestList) of
        {RoleID,OldVal}->
            NewVal = OldVal+CostMoney,
            InvestList2 = lists:keystore(RoleID, 1, InvestList, {RoleID,NewVal});
        false->
            InvestList2 = [{RoleID,CostMoney}|InvestList]
    end,
    {ok,InvestList2}.

do_warofmonster_grow_guard_2_2(_RoleID,_GuardId,_GuardInfo)->
    ?THROW_ERR( ?ERR_WAROFMONSTER_METHOD_NOT_SUPPORT ),
    ok.

%%升级箭塔等设施
upgrade_fb_guard(GuardId,OldServerNpcInfo,NextLvTypeId)->
    case del_warofmonster_fb_guard_info(GuardId) of
        #r_warofmonster_guard_info{invest_list=InvestList}->
            next;
        _ ->
            InvestList = []
    end,
    mod_server_npc:delete_server_npc(GuardId),
    #p_server_npc{reborn_pos=Pos} = OldServerNpcInfo,
    
    #map_state{mapid=MapID,map_name=MapName} = mgeem_map:get_state(),
    {ok,NewServerNpcInfo} = get_server_npc_info(NextLvTypeId,MapID,Pos),
    #p_server_npc{npc_id=NewGuardId,type_id=GuardTypeId} = NewServerNpcInfo,
    
    %%继承上一级别的投资列表
    NewGuardInfo = new_warofmonster_guard_info(NewGuardId,GuardTypeId,InvestList),
    set_warofmonster_fb_guard_info(NewGuardId,NewGuardInfo),
    mod_server_npc:init_map_server_npc(MapName, MapID, [NewServerNpcInfo]),
    ok.

t_grow_guard(RoleID,CostType,CostMoney,GuardId) ->
    if
        CostType =:= silver_any ->
            ConsumeLogType = ?CONSUME_TYPE_SILVER_WAROFMONSTER_GROW_GUARD;
        true->
            ConsumeLogType = ?CONSUME_TYPE_GOLD_WAROFMONSTER_GROW_GUARD
    end,
    case mod_server_npc:get_server_npc_state(GuardId)of
        #server_npc_state{server_npc_info=ServerNpcInfo}->
            next;
        _ ->
            ServerNpcInfo = null,
            ?THROW_ERR( ?ERR_WAROFMONSTER_GROW_GUARD_NOT_EXISTS )
    end,
    
    case common_bag2:t_deduct_money(CostType,CostMoney,RoleID,ConsumeLogType) of
        {ok,RoleAttr2}->
            {ok,CostType,RoleAttr2,ServerNpcInfo};
        {error,silver_any}->
            ?THROW_ERR( ?ERR_WAROFMONSTER_GROW_GUARD_SILVER_NOT_ENOUGH );
        {error,gold_any}->
            ?THROW_ERR( ?ERR_WAROFMONSTER_GROW_GUARD_GOLD_NOT_ENOUGH );
        {error,gold_unbind}->
            ?THROW_ERR( ?ERR_WAROFMONSTER_GROW_GUARD_GOLD_NOT_ENOUGH );
        {error, Reason} ->
            ?THROW_ERR(?ERR_OTHER_ERR, Reason)
    end.

%%@interface 返回守卫的具体信息
do_warofmonster_guard_info({Unique, Module, Method, DataIn, _RoleID, PID, _Line})->
    #m_warofmonster_guard_info_tos{guard_id=GuardId} = DataIn,
    case catch check_warofmonster_guard_info(GuardId) of
        {ok,GuardInfo}->
            #r_warofmonster_guard_info{cur_energy=CurEnergy,max_energy=MaxEnergy} = GuardInfo,
            R2 = #m_warofmonster_guard_info_toc{guard_id=GuardId,cur_energy=CurEnergy,max_energy=MaxEnergy};
        {error,ErrCode,Reason}->
            R2 = #m_warofmonster_guard_info_toc{guard_id=GuardId,err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

check_warofmonster_guard_info(GuardId)->
    case is_in_fb_map() of
        true->
            next;
        _ ->
            ?THROW_ERR( ?ERR_WAROFMONSTER_NOT_IN_MAP )
    end,
    case mod_server_npc:get_server_npc_state(GuardId)of
        #server_npc_state{server_npc_info=#p_server_npc{type_id=GuardTypeId}}->
            ok;
        _ ->
            GuardTypeId = null,
            ?THROW_ERR( ?ERR_WAROFMONSTER_GROW_GUARD_NOT_EXISTS )
    end,
    case get_warofmonster_fb_guard_info(GuardId) of
        #r_warofmonster_guard_info{}=GuardInfo->
            next;
        _ ->
            GuardInfo = new_warofmonster_guard_info(GuardId,GuardTypeId,[])
    end,
    {ok,GuardInfo}.

new_warofmonster_guard_info(GuardId,GuardTypeId,InvestList) when is_list(InvestList)->
    [GuardEnergyList] = ?find_config(fb_server_npc_energy_conf),
    #r_server_npc_energy{max_energy=MaxEnergy} = lists:keyfind(GuardTypeId,#r_server_npc_energy.type_id,GuardEnergyList),
    #r_warofmonster_guard_info{id=GuardId,type_id=GuardTypeId,cur_energy=0,max_energy=MaxEnergy,invest_list=InvestList}.

%%@interface 召唤守卫
do_warofmonster_summon_guard({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_warofmonster_summon_guard_tos{npc_id=NpcId} = DataIn,
    case catch check_warofmonster_summon_guard(RoleID,DataIn) of
        {ok,GuardInfo}->
            case do_warofmonster_summon_guard_2(RoleID,GuardInfo) of
                ok->
                    R2 = #m_warofmonster_summon_guard_toc{npc_id=NpcId};
                {error,ErrCode,Reason}->
                    R2 = #m_warofmonster_summon_guard_toc{npc_id=NpcId,err_code=ErrCode,reason=Reason}
            end;
        {error,ErrCode,Reason}->
            R2 = #m_warofmonster_summon_guard_toc{npc_id=NpcId,err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

do_warofmonster_summon_guard_2(RoleID,GuardInfo)->
    TransFun = fun()-> t_warofmonster_summon_guard(RoleID) end,
    case common_transaction:t( TransFun ) of
        {atomic, {ok,RoleAttr2}} ->
            common_misc:send_role_gold_change(RoleID,RoleAttr2),
            
            %%召唤超级守卫
            {GuardTypeID,Tx,Ty,Dir,LiveTime} = GuardInfo,
            Pos = #p_pos{tx = Tx,ty = Ty,dir = Dir},
            #map_state{mapid=MapID,map_name=MapName} = mgeem_map:get_state(),
            case mod_map_role:get_role_base(RoleID) of
                {ok,#p_role_base{role_name=CallerName}}->
                    next;
                _ ->
                    CallerName = undefined
            end,
            {ok,ServerNpcInfo} = get_server_npc_info(GuardTypeID,MapID,Pos,CallerName),
            
            add_warofmonster_live_guard(MapName, MapID,LiveTime,ServerNpcInfo),
            
            ok;
        {aborted, AbortErr} ->
            parse_aborted_err(AbortErr)
    end.

get_server_npc_info(GuarderTypeID,MapID,Pos)->
    get_server_npc_info(GuarderTypeID,MapID,Pos,undefined).
get_server_npc_info(GuardTypeID,MapID,Pos,CallerName)->    
    [NpcBaseInfo] = common_config_dyn:find(server_npc, GuardTypeID),
    case CallerName of
        undefined->
            GuarderName = NpcBaseInfo#p_server_npc_base_info.npc_name;
        _ ->
            GuarderName = common_misc:format_lang(<<"~s的守卫">>, [CallerName])
    end,
    ServerNpcInfo = #p_server_npc{
                      %% 使用怪物的id
                      npc_id = mod_map_monster:get_max_monster_id_form_process_dict(),
                      type_id = NpcBaseInfo#p_server_npc_base_info.type_id,
                      npc_name = GuarderName,
                      npc_type = NpcBaseInfo#p_server_npc_base_info.npc_type,
                      npc_kind_id = NpcBaseInfo#p_server_npc_base_info.npc_kind_id,
                      max_mp= NpcBaseInfo#p_server_npc_base_info.max_mp,
                      state = ?FIRST_BORN_STATE,
                      max_hp = NpcBaseInfo#p_server_npc_base_info.max_hp,
                      map_id = MapID,
                      reborn_pos = Pos,
                      level= NpcBaseInfo#p_server_npc_base_info.level,
                      npc_country = NpcBaseInfo#p_server_npc_base_info.npc_country,
                      is_undead = NpcBaseInfo#p_server_npc_base_info.is_undead,
                      move_speed = NpcBaseInfo#p_server_npc_base_info.move_speed
                     },
    {ok,ServerNpcInfo}.

t_warofmonster_summon_guard(RoleID)->
    ConsumeLogType = ?CONSUME_TYPE_GOLD_WAROFMONSTER_CALL_GUARD,
    [{DeductType,DeductGold}] = ?find_config(fb_call_guard_cost),
    case common_bag2:t_deduct_money(DeductType,DeductGold,RoleID,ConsumeLogType) of
        {ok,RoleAttr2}->
            {ok,RoleAttr2};
        {error,gold_any}->
            ?THROW_ERR( ?ERR_WAROFMONSTER_SUMMON_GUARD_GOLD_NOT_ENOUGH );
        {error, Reason} ->
            ?THROW_ERR(?ERR_OTHER_ERR, Reason)
    end.



check_warofmonster_summon_guard(_RoleID,DataIn)->
    #m_warofmonster_summon_guard_tos{npc_id=NpcId} = DataIn,
    case is_in_fb_map() of
        true->
            next;
        _ ->
            ?THROW_ERR( ?ERR_WAROFMONSTER_BUY_BUFF_NOT_IN_MAP )
    end,
    
    [NpcGuardList] = ?find_config(fb_call_guard_list),
    case lists:keyfind(NpcId, 1, NpcGuardList) of
        {NpcId,GuardTypeID,{Tx,Ty},Dir,LiveTime}->
            case lists:keymember(NpcId,1,mcm:npc_tiles(mgeem_map:get_mapid())) of
                true ->
                    GuardInfo = {GuardTypeID,Tx,Ty,Dir,LiveTime};
                _ ->
                    GuardInfo = null,
                    ?THROW_ERR( ?ERR_WAROFMONSTER_SUMMON_GUARD_NOT_EXISTS )
            end,
            case get(?WAROFMONSTER_LIVE_GUARD_LIST)of
                undefined-> ignore;
                GardTypeIdList->
                    case lists:member(GuardTypeID, GardTypeIdList) of
                        true->
                            ?THROW_ERR( ?ERR_WAROFMONSTER_SUMMON_GUARD_DUPLICATED );
                        _ ->
                            next
                    end
            end;
        false ->
            GuardInfo = null,
            ?THROW_ERR( ?ERR_WAROFMONSTER_SUMMON_GUARD_INVALID_ID )
    end,
    {ok,GuardInfo}.


%%获取副本返回的位置
get_warofmonster_return_pos(RoleID)->
    %%好吧，踢回京城
    common_map:get_map_return_pos_of_jingcheng(RoleID).



%%对所有的人进行奖励，并踢出地图
reward_and_kick_all_roles()->
    %%获取连胜奖励列表
    #r_warofmonster_map_info{enter_role_list=EnterRoleList } = get_warofmonster_map_info(),
    
    %%删除字典信息
    lists:foreach(
      fun({RoleID,_}) ->
              erase({?WAROFMONSTER_ROLE_INFO,RoleID})
      end, EnterRoleList),
    
    ?TRY_CATCH( do_battle_fb_log() ),
    
    %%踢人
    erlang:send_after(3000, self(), {mod,?MODULE,{kick_all_roles}}),
    ok.

do_kick_all_roles()->
    RoleIDList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              do_warofmonster_quit_2(RoleID)
      end, RoleIDList).
 


%% --------------------------------------------------------------------
%%  内部的二级API
%% --------------------------------------------------------------------
assert_role_level(RoleAttr)->
    #p_role_attr{level=RoleLevel} = RoleAttr,
    [MinRoleLevel] = ?find_config(fb_min_role_level),
    if
        MinRoleLevel>RoleLevel->
            ?THROW_ERR( ?ERR_WAROFMONSTER_ENTER_LV_LIMIT );
        true->
            next
    end,
    ok.

assert_role_jingjie(RoleAttr)->
    #p_role_attr{jingjie=Jingjie} = RoleAttr,
    [MinRoleTitle] = ?find_config(fb_min_role_jingjie),
    if
        MinRoleTitle>Jingjie->
            ?THROW_ERR( ?ERR_WAROFMONSTER_ENTER_JINGJIE_LIMIT );
        true->
            next
    end,
    ok.
assert_role_enter_faction(RoleFaction)->
    [EntranceMapIdList] = ?find_config(entrance_map_id),
    EntranceMapId = lists:nth(RoleFaction, EntranceMapIdList),
    CurMapId = mgeem_map:get_mapid(),
    if
        CurMapId=:=EntranceMapId->
            next;
        true->
            ?THROW_ERR( ?ERR_WAROFMONSTER_ENTER_FACTION_LIMIT )
    end,
    ok.

assert_role_faction(RoleFaction,FbFactionId)->
    if
        RoleFaction=:=FbFactionId->
            next;
        true->
            ?THROW_ERR( ?ERR_WAROFMONSTER_ENTER_FACTION_LIMIT )
    end,
    ok.

get_fb_min_role_jingjie_str()->
    [MinRoleTitle] = ?find_config(fb_min_role_jingjie),
    common_title:get_jingjie_name(MinRoleTitle).

check_warofmonster_enter(RoleID,_DataIn)->
    [EnableNationBattle] = ?find_config(enable_warofmonster),
    if
        EnableNationBattle=:=true->
            next;
        true->
            ?THROW_ERR( ?ERR_WAROFMONSTER_DISABLE )
    end,
    
    {ok,#p_role_base{faction_id=RoleFaction}} = mod_map_role:get_role_base(RoleID),
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    assert_role_level(RoleAttr),
    assert_role_jingjie(RoleAttr),
    assert_role_enter_faction(RoleFaction),
    
    case is_in_fb_map() of
        true->
            ?THROW_ERR( ?ERR_WAROFMONSTER_ENTER_IN_BATTLE );
        _ ->
            next
    end,
    #map_state{map_type=MapType} = mgeem_map:get_state(),
    if
        MapType=:=?MAP_TYPE_COPY->
            ?THROW_ERR( ?ERR_WAROFMONSTER_ENTER_FB_LIMIT );
        true->
            next
    end,
    %%检查入口信息
    case get_warofmonster_entrance_info() of
        undefined->
            req_warofmonster_entrance_info(),
            ?THROW_ERR( ?ERR_WAROFMONSTER_ENTER_CLOSING );
        #r_warofmonster_entrance_info{is_opening=true}->
            next;
        _ ->
            req_warofmonster_entrance_info(),
            ?THROW_ERR( ?ERR_WAROFMONSTER_ENTER_CLOSING )
    end,
    
    
    %%检查人数
    case get_warofmonster_sub_entrance_info(RoleFaction) of
        undefined->
            req_warofmonster_sub_entrance_info(RoleFaction),
            ?THROW_ERR( ?ERR_WAROFMONSTER_ENTER_CLOSING );
        #r_warofmonster_sub_entrance_info{map_role_num=CurRoleNum}->
            [{NormalMaxRoleNum,_AllMaxRoleNum}] = ?find_config(limit_fb_role_num),
           
            if
                        CurRoleNum>=NormalMaxRoleNum->
                            ?THROW_ERR( ?ERR_WAROFMONSTER_ENTER_MAX_ROLE_NUM );
                        true->
                            next
                    end;
        _ ->
            ?THROW_ERR( ?ERR_WAROFMONSTER_ENTER_CLOSING )
    end,
    {ok,RoleFaction}.


check_warofmonster_quit(_RoleID,_DataIn)->
    case is_in_fb_map() of
        true->
            next;
        _->
            ?THROW_ERR( ?ERR_WAROFMONSTER_QUIT_NOT_IN_MAP )
    end,
    ok.


%%--------------------------------  战场入口消息的代码，可复用  [start]--------------------------------


%%请求更新入口信息
req_warofmonster_entrance_info()->
    send_master_map_msg( {req_warofmonster_entrance_info} ).

req_warofmonster_sub_entrance_info(FactionId)->
    send_slave_map_msg(FactionId,{req_warofmonster_sub_entrance_info}).

do_req_warofmonster_entrance_info()->
    case get_warofmonster_map_info() of
        #r_warofmonster_map_info{is_opening=IsOpening}->
            EntranceInfo = #r_warofmonster_entrance_info{is_opening=IsOpening},
            init_warofmonster_entrance_info(EntranceInfo),
            ok;
        _ ->
            ignore
    end.

do_req_warofmonster_sub_entrance_info()->
    case get_warofmonster_map_info() of
        #r_warofmonster_map_info{fb_faction_id=FbFactionId,cur_role_list=CurRoleList}->
            AllRoleNum = length(CurRoleList),
            syn_warofmonster_sub_entrance_info(FbFactionId,AllRoleNum),
            ok;
        _ ->
            ignore
    end.

%%同步更新入口信息
%%  包括更新到王城、Slave进程
init_warofmonster_entrance_info(EntranceInfo) when is_record(EntranceInfo,r_warofmonster_entrance_info)->
    [EntranceMapIdList] = ?find_config(entrance_map_id),
    lists:foreach(
      fun(EntranceMapId)->
              SendInfo = {mod,?MODULE,{init_warofmonster_entrance_info,EntranceInfo}},
              case global:whereis_name( common_map:get_common_map_name(EntranceMapId) ) of
                  undefined->
                      ignore;
                  MapPID->
                      MapPID ! SendInfo
              end
      end, EntranceMapIdList).

syn_warofmonster_sub_entrance_info(FbFactionId,AllRoleNum) ->
    SubEntranceInfo = #r_warofmonster_sub_entrance_info{map_role_num=AllRoleNum},
    [EntranceMapIdList] = ?find_config(entrance_map_id),
    EntranceMapId = lists:nth(FbFactionId, EntranceMapIdList),
    SendInfo = {mod,?MODULE,{syn_warofmonster_sub_entrance_info,FbFactionId,SubEntranceInfo}},
    case global:whereis_name( common_map:get_common_map_name(EntranceMapId) ) of
        undefined->
            ignore;
        MapPID->
            MapPID ! SendInfo
    end.

do_syn_warofmonster_sub_entrance_info(FactionId,SubEntranceInfo)->
    set_warofmonster_sub_entrance_info(FactionId,SubEntranceInfo),
    ok.

do_init_warofmonster_entrance_info(EntranceInfo) when is_record(EntranceInfo,r_warofmonster_entrance_info)->
    put(?WAROFMONSTER_ENTRANCE_INFO,EntranceInfo),
    ok.

do_update_warofmonster_entrance_info(ValList) when is_list(ValList)->
    case get(?WAROFMONSTER_ENTRANCE_INFO) of
        #r_warofmonster_entrance_info{}= OldInfo->
            EntranceInfo =
                lists:foldl(
                  fun(E,AccIn)-> 
                          {EType,EVal} = E,
                          case EType of
                              is_opening->
                                  AccIn#r_warofmonster_entrance_info{is_opening=EVal}
                          end
                  end, OldInfo, ValList),
            put(?WAROFMONSTER_ENTRANCE_INFO,EntranceInfo),
            ok;
        _ ->
            ignore
    end,
    ok.

%%--------------------------------  战场入口消息的代码，可复用  [end]--------------------------------

%%--------------------------------  定时战场的代码，可复用  [start]--------------------------------

is_opening_battle()->
    case get_warofmonster_map_info() of
        #r_warofmonster_map_info{is_opening=IsOpening}->
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
            R1 = #r_warofmonster_time{date = Date,
                                      start_time = StartTimeSeconds,end_time = EndTimeSeconds,
                                      next_bc_start_time = NextBcStartTime,
                                      next_bc_end_time = NextBcEndTime,
                                      next_bc_process_time = NextBcProcessTime,
                                      before_interval = BeforeInterval,
                                      close_interval = CloseInterval,
                                      process_interval = ProcessInterval},
            put(?WAROFMONSTER_TIME_DATA,R1),
            {ok,StartTimeSeconds};
        {error,Reason}->
            {error,Reason}
    end.
   
%%--------------------------------  定时战场的代码，可复用  [end]--------------------------------

%%--------------------------------  战场广播的代码，可复用  [start]--------------------------------
%% 副本开起提前广播开始消息
%% Record 结构为 r_warofmonster_time
%% 返回 new r_warofmonster_time
do_fb_open_before_broadcast(NowSeconds,Record) ->
    #r_warofmonster_time{
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
                       common_misc:format_lang(?_LANG_WAROFMONSTER_PRESTART,[StartTimeStr,MinJingjieStr]);
                   _ ->
                       common_misc:format_lang(?_LANG_WAROFMONSTER_STARTED,[MinJingjieStr])
               end,
           FactionId = get_fb_faction_id(),
           catch common_broadcast:bc_send_msg_faction(FactionId,?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,BeforeMessage),
           set_warofmonster_time_data( Record#r_warofmonster_time{
                                                                  next_bc_start_time = NowSeconds + BeforeInterval} );
       true ->
           Record
    end.
%% 副本开启过程中广播处理
%% Record 结构为 r_warofmonster_time
%% 返回
do_fb_open_process_broadcast(NowSeconds,Record) ->
    #r_warofmonster_time{
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
            ProcessMessage = common_misc:format_lang(?_LANG_WAROFMONSTER_STARTED,[MinJingjieStr]),
            FactionId = get_fb_faction_id(),
            catch common_broadcast:bc_send_msg_faction(FactionId,?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,ProcessMessage),
            set_warofmonster_time_data( Record#r_warofmonster_time{
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
               common_misc:format_lang(?_LANG_WAROFMONSTER_CLOSED_TIME,[NextStartTimeStr]);
           true ->
               ?_LANG_WAROFMONSTER_CLOSED_FINAL
        end,
    FactionId = get_fb_faction_id(),
    catch common_broadcast:bc_send_msg_faction(FactionId,?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,EndMessageF).

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
    lists:foreach(
      fun(E)->
              FbMapName = common_map:get_common_map_name(E),
              case global:whereis_name( FbMapName ) of
                  undefined->
                      ignore;
                  MapPID->
                      erlang:send(MapPID,{mod,?MODULE,Msg})
              end
      end, ?WAROFMONSTER_MAP_ID_LIST).

%%将消息发送到战场的Slave地图进程
send_slave_map_msg(FactionId,Msg)->
    BattleMapName = get_fb_map_name_by_faction(FactionId),
    case global:whereis_name( BattleMapName ) of
        undefined->
            ignore;
        MapPID->
            erlang:send(MapPID,{mod,?MODULE,Msg})
    end.


%%GM开启副本
gm_open_warofmonster(Second)->
	%%GM命令，手动开启
	TimeData = get_warofmonster_time_data(),
	StartTime2 = common_tool:now(),
	[FbGmOpenLastTime] = ?find_config(fb_gm_open_last_time),
	EndTime2 = StartTime2 + FbGmOpenLastTime,
	TimeData2 = TimeData#r_warofmonster_time{date=date(),start_time=StartTime2 + Second,end_time=EndTime2},
	set_warofmonster_time_data(TimeData2).


%%开启副本
open_warofmonster()->   
    FbFactionId = get_fb_faction_id(),
	%%TODO 爵位系统已经屏蔽
    FbFactionLevel = 0,
    
    set_warofmonster_map_info(#r_warofmonster_map_info{is_opening=true,fb_faction_id=FbFactionId,faction_level=FbFactionLevel}),
    
    EntranceInfo = #r_warofmonster_entrance_info{is_opening=true},
    init_warofmonster_entrance_info(EntranceInfo),
    
    init_warofmonster_monster_info(),
    ok.


%%关闭副本
close_warofmonster()->
    %%清除怪物，计算家族积分
    mod_map_monster:delete_all_monster(),
    notify_battle_result(),
    %%calc_family_score(),
    
    BattleMapInfo = get_warofmonster_map_info(),
    set_warofmonster_map_info(BattleMapInfo#r_warofmonster_map_info{is_opening=false,next_refresh_time=0}),
    
    EntranceInfo = #r_warofmonster_entrance_info{is_opening=false},
    init_warofmonster_entrance_info(EntranceInfo),
    
    reward_and_kick_all_roles(),
    
    {ok,NextStartTimeSeconds} = reset_battle_open_times(),
    do_fb_close_broadcast(NextStartTimeSeconds),
    
    ok.


%%--------------------------------  战场开/关的代码，可复用 [end] --------------------------------

init_warofmonster_monster_info()->
    erlang:send(self(), {mod,?MODULE,{refresh_warofmonster_monster}}),
    ok.
 

%%解析错误码
parse_aborted_err(AbortErr)->
    case AbortErr of
        {error,ErrCode,_Reason} when is_integer(ErrCode) ->
            AbortErr;
        {bag_error,{not_enough_pos,_BagID}}->
            {error,?ERR_OTHER_ERR,undefined};
        {bag_error,num_not_enough}->
            {error,?ERR_OTHER_ERR,undefined};
        {error,AbortReason} when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        AbortReason when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        _ ->
            ?ERROR_MSG(" aborted,AbortErr=~w,stack=~w",[AbortErr,erlang:get_stacktrace()]),
            {error,?ERR_SYS_ERR,undefined}
    end.
 
 

%%判断当前副本属于哪个国家
get_fb_faction_id()->
    CurFbMapId = mgeem_map:get_mapid(),
    get_fb_faction_id(CurFbMapId).
get_fb_faction_id(CurFbMapId)->    
    {_,FbFactionId} = lists:keyfind(CurFbMapId, 1, ?WAROFMONSTER_MAP_ID_LIST_2),
    FbFactionId.

 

%%获取新的积分排名列表
get_new_rank_list(ScoreList,IsSortAll) when is_list(ScoreList)->
    ScoreList2 =  lists:sort(
                    fun(E1,E2)->
                            #p_warofmonster_rank{score=S1,update_time=U1} = E1,
                            #p_warofmonster_rank{score=S2,update_time=U2} = E2,
                            if
                                S1>S2-> true;
                                S1=:=S2-> U1<U2;
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
                  {Order+1,[E#p_warofmonster_rank{order=Order}|RankAcc]}
          end, {1,[]}, PartScoreList),
    {ok,ScoreList2,NewRankList}.

%%@doc 更新怪物的下次刷新时间
notify_battle_refresh_time(RefreshTime)->
    RoleIDList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              R2 = #m_warofmonster_change_toc{change_type=[?CHANGE_TYPE_REFRESH_TIME],next_refresh_time=RefreshTime},
              common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFMONSTER, ?WAROFMONSTER_CHANGE, R2)
      end, RoleIDList). 

%%@doc 通知战场结果
notify_battle_result()->
    case get_warofmonster_map_info() of
        #r_warofmonster_map_info{faction_level=UpLevel, faction_score=FactionScore} ->
            notify_battle_result(false,UpLevel,FactionScore);
        _ ->
            ignore
    end.

notify_battle_result(IsSuccess,UpLevel,FactionScore) when is_boolean(IsSuccess)->
    case get_warofmonster_map_info() of
        #r_warofmonster_map_info{notify_result_times=0}=OldMapInfo ->
            RoleIDList = mod_map_actor:get_in_map_role(),
            Result = if IsSuccess-> ?RESULT_TYPE_WIN; true-> ?RESULT_TYPE_FAIL end,
            
            set_warofmonster_map_info(OldMapInfo#r_warofmonster_map_info{notify_result_times=1,
                                                                         fb_result=Result}),
            
            lists:foreach(
              fun(RoleID) ->
                      case get_warofmonster_role_info(RoleID) of
                          #r_warofmonster_role_info{my_score=MyScore,my_prestige=MyPrestige,my_silver=MySilver}->
                              next;
                          _ ->
                              MyScore=MyPrestige=MySilver=0
                      end,
                      R2 = #m_warofmonster_result_toc{faction_juewei=UpLevel,result=Result,faction_score=FactionScore,
                                                      my_score=MyScore,my_prestige=MyPrestige,my_silver=MySilver},
                      common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFMONSTER, ?WAROFMONSTER_RESULT, R2)
              end, RoleIDList);
        _ ->
            ignore
    end.

%%@doc 通知积分排行的更新
notify_battle_rank(NewRankList)->
    RoleIDList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              R2 = #m_warofmonster_rank_toc{ranks=NewRankList},
              common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFMONSTER, ?WAROFMONSTER_RANK, R2)
      end, RoleIDList). 

%%@doc 通知势力积分的更新
notify_faction_score(FactionScore) when is_integer(FactionScore)->
    RoleIDList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              R2 = #m_warofmonster_change_toc{change_type=[?CHANGE_TYPE_FACTION_SCORE],faction_score=FactionScore},
              common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFMONSTER, ?WAROFMONSTER_CHANGE, R2)
      end, RoleIDList). 

get_faction_upgrade_need_score(FactionLevel)->
    [FactionLvScoreList] = ?find_config(fb_faction_level_score),
    {_,UpLevel,NeedScore} =  lists:keyfind(FactionLevel, 1, FactionLvScoreList),
    if
        UpLevel>0-> 
            NeedScore;
        true->
            0
    end.

judge_fb_result(FactionId,FactionLevel,NewFactionScore)->
    [FactionLvScoreList] = ?find_config(fb_faction_level_score),
    case lists:keyfind(FactionLevel, 1, FactionLvScoreList) of
        {_,UpLevel,NeedScore} when UpLevel>0 andalso NewFactionScore>=NeedScore-> 
            %%可以提升等级啦
            Now = common_tool:now(),
            R2db = #r_faction_info{faction_id=FactionId,juewei_level=UpLevel,update_time=Now},
            db:dirty_write(?DB_FACTION_INFO, R2db),
            {true,UpLevel};
        _->
            false
    end.


do_warofmonster_buy_buff({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    case catch check_warofmonster_buy_buff(RoleID,DataIn) of
        {ok,MoneyType,BuyBuffID,CostMoney}->
            TransFun = fun()-> 
                               t_deduct_buy_buff_money(MoneyType,CostMoney,RoleID)
                       end,
            case common_transaction:t( TransFun ) of
                {atomic, {ok,RoleAttr2}} ->
                    case MoneyType of
                        ?BUY_BUFF_TYPE_SILVER->
                            common_misc:send_role_silver_change(RoleID,RoleAttr2);
                        ?BUY_BUFF_TYPE_GOLD->
                            common_misc:send_role_gold_change(RoleID,RoleAttr2)
                    end,
                    
                    remove_pve_buff(MoneyType,RoleID),
                    RealAddBuffList = fb_buff_mapping(MoneyType,BuyBuffID),
                    mod_role_buff:del_buff_by_type(RoleID,RealAddBuffList),
                    {NextBuffID,_NextCostMoney} = next_can_buy_buff(RoleID,MoneyType),
                    R2 = #m_warofmonster_buy_buff_toc{type=MoneyType,next_buff_id=NextBuffID,
                                                      cost_money=CostMoney};
                {aborted, AbortErr} ->
                    {error,ErrCode,Reason} = parse_aborted_err(AbortErr),
                    R2 = #m_warofmonster_buy_buff_toc{type=MoneyType,err_code=ErrCode,reason=Reason}
            end;
        {error,ErrCode,Reason}->
            R2 = #m_warofmonster_buy_buff_toc{err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

check_warofmonster_buy_buff(RoleID,DataIn)->
    #m_warofmonster_buy_buff_tos{type=MoneyType} = DataIn,
    case is_in_fb_map() of
        true->
            next;
        _ ->
            ?THROW_ERR( ?ERR_WAROFMONSTER_BUY_BUFF_NOT_IN_MAP )
    end,
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{}->
            next;
        _ ->
            ?THROW_ERR( ?ERR_WAROFMONSTER_BUY_BUFF_NOT_IN_MAP )
    end,
    case next_can_buy_buff(RoleID,MoneyType) of
        {0,0} -> %%不能再购买buff
            CostMoney = NextBuffID = null,
            ?THROW_ERR( ?ERR_WAROFMONSTER_BUY_BUFF_NOT_IN_MAP );
        {NextBuffID,CostMoney} ->
            next
    end,
    {ok,MoneyType,NextBuffID,CostMoney}.

remove_pve_buff(MoneyType,RoleID) ->
    BuffIDList = pve_buff_mapping_list(MoneyType),
    mod_pve_fb:remove_pve_fb_buffs(RoleID, BuffIDList).

remove_pve_buff(RoleID) ->
    GoldBuffIDList = pve_buff_mapping_list(?BUY_BUFF_TYPE_GOLD),
    mod_pve_fb:remove_pve_fb_buffs(RoleID, GoldBuffIDList).

pve_buff_mapping_list(MoneyType) ->
    [BuffMapping] = 
        case MoneyType of
            ?BUY_BUFF_TYPE_SILVER ->
                ?find_config(fb_silver_buff_mapping);
            ?BUY_BUFF_TYPE_GOLD ->
                ?find_config(fb_gold_buff_mapping)
        end,
    lists:flatten(BuffMapping).

pve_buff_list(MoneyType) ->
    [FbBuffList] = ?find_config(fb_buff_list),
    case lists:keyfind(MoneyType,1,FbBuffList) of
        {MoneyType,BuffIDList,CostList} ->
            {BuffIDList,CostList};
        _ ->
            undefined
    end.


%% 副本购买的BUFF实际上添加和删除的buff列表
fb_buff_mapping(MoneyType,BuffID) ->
    [BuffMapping] = 
        case MoneyType of
            ?BUY_BUFF_TYPE_SILVER ->
                ?find_config(fb_silver_buff_mapping);
            ?BUY_BUFF_TYPE_GOLD ->
                ?find_config(fb_gold_buff_mapping)
        end,
    case lists:filter(fun(BuffIDList) ->
                              lists:member(BuffID, BuffIDList)
                      end, BuffMapping) of
        [] ->
            ?ERROR_MSG("fb_buff_mapping error:~w",[{MoneyType,BuffID}]),
            [BuffID];
        [AddBuffIDList|_] ->
            AddBuffIDList
    end.

%% 玩家可以购买的buffID
%% return {NextBuffID,Cost}
next_can_buy_buff(RoleID,MoneyType) ->
    case pve_buff_list(MoneyType) of
        {BuffIDList,CostList} ->
            case mod_map_role:get_role_base(RoleID) of
                {ok, #p_role_base{buffs=RoleBuffs}}->
                    case has_buy_buff_in_role(RoleBuffs,BuffIDList,MoneyType) of
                        false->
                            {erlang:hd(BuffIDList),erlang:hd(CostList)};
                        HasBuyBuffID ->
                            case HasBuyBuffID =:= lists:last(BuffIDList) of
                                true ->
                                    {0,0};
                                false ->
                                    Nth = common_tool:index_of_lists(HasBuyBuffID,BuffIDList) + 1,
                                    {lists:nth(Nth,BuffIDList),lists:nth(Nth,CostList)}
                            end
                    end;
                _ ->
                    ?THROW_ERR( ?ERR_WAROFMONSTER_BUY_BUFF_NOT_IN_MAP )
            end;
        _ ->
            ?THROW_ERR( ?ERR_WAROFMONSTER_BUY_BUFF_INVALID_BUFF )
    end.

%%检查玩家身上是否有指定BuffID列表
%% return false | BuffID
has_buy_buff_in_role(_RoleBuffs,[],_MoneyType)->
    false;
has_buy_buff_in_role(RoleBuffs,[H|T],MoneyType)->
    case lists:keyfind(H, #p_actor_buf.buff_id, RoleBuffs) of
        false->
            has_buy_buff_in_role(RoleBuffs,T,MoneyType);
        _ ->
            case pve_buff_list(MoneyType) of
                undefined ->
                    ?ERROR_MSG("has_buy_buff_in_role error:~w",[MoneyType]),
                    false;
                {BuffIDList,_CostList} ->
                    case lists:member(H, BuffIDList) of
                        true ->
                            H;
                        false ->
                            has_buy_buff_in_role(RoleBuffs,T,MoneyType)
                    end
            end
    end.   
    
%%扣除钱币/元宝
t_deduct_buy_buff_money(BuyBuffType,DeductMoney,RoleID)->
    case BuyBuffType of
        ?BUY_BUFF_TYPE_SILVER->
            MoneyType = silver_any,
            ConsumeLogType = ?CONSUME_TYPE_SILVER_PVE_FB_BUY_BUFF;
        ?BUY_BUFF_TYPE_GOLD ->
            MoneyType = gold_any,
            ConsumeLogType = ?CONSUME_TYPE_GOLD_PVE_FB_BUY_BUFF
    end,
    case common_bag2:t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeLogType) of
        {ok,RoleAttr2}->
            {ok,RoleAttr2};
        {error,silver_any}->
            ?THROW_ERR( ?ERR_WAROFMONSTER_BUY_BUFF_SILVER_NOT_ENOUGH );
        {error,gold_any}->
            ?THROW_ERR( ?ERR_WAROFMONSTER_BUY_BUFF_GOLD_NOT_ENOUGH );
        {error, Reason} ->
            ?THROW_ERR(?ERR_OTHER_ERR, Reason);
        _ ->
            ?THROW_SYS_ERR()
    end. 

%%@doc 获取各个玩家在这个守卫上的投资列表
%%  注意，守卫升级以后，投资是可以累加的
get_role_invest_list(GuardId,GuardTypeId)->
    case get_warofmonster_fb_guard_info(GuardId) of
        #r_warofmonster_guard_info{invest_list=InvestList,type_id=GuardTypeId}->
            AllInvestSum = lists:sum( [ Cost||{_,Cost}<-InvestList ] ),
            {ok,AllInvestSum,InvestList};
        _ ->
            {ok,0,[]}
    end.

%%记录战场的日志
do_battle_fb_log()->
    case get_warofmonster_time_data() of
        #r_warofmonster_time{start_time = StartTime,end_time = EndTime} ->
            case get_warofmonster_map_info() of
                #r_warofmonster_map_info{max_role_num=MaxRoleNum,fb_faction_id=FbFactionId,fb_result=FbResult}->
                    MapId = mgeem_map:get_mapid(),
                    BattleFbLog = #r_warofmonster_fb_log{faction_id=FbFactionId,map_id=MapId,start_time=StartTime, end_time=EndTime, 
                                                         fb_result=FbResult, max_role_num=MaxRoleNum },
                    common_general_log_server:log_warofmonster_fb(BattleFbLog);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.


%%获取怪物根据地图人数的出生个数限制
get_monster_born_num_by_role(RoleNum) when is_integer(RoleNum)->
    [MonsterBornNumByRoleList] = ?find_config(monster_born_num_by_role),
    get_monster_born_num_by_role_2(RoleNum,MonsterBornNumByRoleList).

get_monster_born_num_by_role_2(_RoleNum,[])->
    6;
get_monster_born_num_by_role_2(RoleNum,[H|T])->
    {MinRoleNum,MaxRoleNum,BornNum} = H,
    if
        RoleNum>=MinRoleNum andalso MaxRoleNum>=RoleNum->
            BornNum;
        true->
            get_monster_born_num_by_role_2(RoleNum,T)
    end.