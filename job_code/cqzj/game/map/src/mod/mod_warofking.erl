%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     王座争霸战
%%% @end
%%% Created : 2011-6-16
%%%-------------------------------------------------------------------
-module(mod_warofking).
 
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
         hook_monster_dead/2,
         hook_pick_king_box/2,
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
-define(WAROFKING_MAP_ID_LIST,[11111,12111,13111]).
-define(WAROFKING_MAP_ID_LIST_2,[{11111,1},{12111,2},{13111,3}]).
-define(BATTLE_RANK_LEN,5).
-define(WAROFKING_MAP_NAME_TO_ENTER,warofking_map_name_to_enter).
-define(WAROFKING_ENTRANCE_INFO,warofking_entrance_info).
-define(WAROFKING_SUB_ENTRANCE_INFO,warofking_sub_entrance_info).

%% 加经验间隔
-define(INTERVAL_EXP_LIST, interval_exp_list).

-define(WAROFKING_MAP_INFO,warofking_map_info).
-define(WAROFKING_TIME_DATA,warofking_time_data).
-define(WAROFKING_ROLE_INFO,warofking_role_info).
%% slave_num: 已经开启的子战场的个数
%% split_jingjie: 按境界分流的境界值
-record(r_warofking_entrance_info,{is_opening=false}).
-record(r_warofking_sub_entrance_info,{map_role_num=0}).

-record(r_warofking_map_info,{is_opening=false,max_role_num=0,cur_role_list=[],enter_role_list=[],
                              fb_faction_id=0,next_refresh_time=0,remain_refresh_times=0, 
                              score_list=[], rank_data=[]}).
            %%cur_role_list     记录当前地图的玩家列表 [{RoleID,FamilyID}]
            %%enter_role_list   进入地图的玩家列表[RoleID]
            %%next_refresh_time     下一次怪物的刷新时间
            %%remain_refresh_times  剩余刷新次数
            %%score_list   所有家族的积分列表（>0的积分）
            %%rank_data    当前的杀戮榜结果，每次积分列表更新之后，会相应更新这个排序结果
-record(r_warofking_time,{date = 0,start_time = 0,end_time = 0,
                                 next_bc_start_time = 0,next_bc_end_time = 0,next_bc_process_time = 0,
                                 before_interval = 0,close_interval = 0,process_interval = 0,
                                 kick_role_time = 0}).
-record(r_warofking_role_info,{tmp_box_num=0,protect_box_num=0,last_buy_buff_time=0}).  %%每个玩家的宝匣数量列表
            %%tmp_box_num   临时的宝匣数量
            %%protect_box_num   临时的宝匣数量

-define(CHANGE_TYPE_REFRESH_TIME,1).    %%更新类型：1=只更新刷新时间3=只更新积分3=只更新密匣数量
-define(CHANGE_TYPE_SCORE,2).
-define(CHANGE_TYPE_BOX_NUM,3).
-define(CONFIG_NAME,warofking).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).


%% 对应的活动ID, 与activity_today.config里的一致
-define(WAROFKING_ACTIVITY_ID,10021).


%% ====================================================================
%% Error Code
%% ====================================================================

-define(ERR_WAROFKING_DISABLE,42999).
-define(ERR_WAROFKING_ENTER_CLOSING,42001).
-define(ERR_WAROFKING_ENTER_LV_LIMIT,42002).
-define(ERR_WAROFKING_ENTER_FB_LIMIT,42003).
-define(ERR_WAROFKING_ENTER_FAMILY_LIMIT,42004).
-define(ERR_WAROFKING_ENTER_FACTION_LIMIT,42005).
-define(ERR_WAROFKING_ENTER_IN_BATTLE,42006).
-define(ERR_WAROFKING_ENTER_MAX_ROLE_NUM,42007).
-define(ERR_WAROFKING_ENTER_JINGJIE_LIMIT,42008).
-define(ERR_WAROFKING_QUIT_NOT_IN_MAP,42010).
-define(ERR_WAROFKING_BUY_BUFF_CD_TIME,42011).
-define(ERR_WAROFKING_BUY_BUFF_EXISTS,42012).
-define(ERR_WAROFKING_BUY_BUFF_NOT_IN_MAP,42013).
-define(ERR_WAROFKING_BUY_BUFF_INVALID_BUFF,42014).
-define(ERR_WAROFKING_BUY_BUFF_SILVER_NOT_ENOUGH,42015).
-define(ERR_WAROFKING_BUY_BUFF_GOLD_NOT_ENOUGH,42016).


%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).

handle({_, ?WAROFKING, ?WAROFKING_ENTER,_,_,_,_}=Info) ->
    %% 进入国家战场
    do_warofking_enter(Info);
handle({_, ?WAROFKING, ?WAROFKING_QUIT,_,_,_,_}=Info) ->
    %% 退出国家战场
    do_warofking_quit(Info);
handle({_, ?WAROFKING, ?WAROFKING_BUY_BUFF,_,_,_,_}=Info) ->
    %% 退出国家战场
    do_warofking_buy_buff(Info);

handle({req_warofking_entrance_info}) ->
    do_req_warofking_entrance_info();
handle({req_warofking_sub_entrance_info}) ->
    do_req_warofking_sub_entrance_info();
handle({init_warofking_entrance_info,EntranceInfo}) ->
    do_init_warofking_entrance_info(EntranceInfo);
handle({update_warofking_entrance_info,ValList}) ->
    do_update_warofking_entrance_info(ValList);
handle({syn_warofking_sub_entrance_info,FactionId,SubEntranceInfo}) ->
    do_syn_warofking_sub_entrance_info(FactionId,SubEntranceInfo);
handle({refresh_warofking_monster}) ->
    do_refresh_warofking_monster();
handle({kick_all_roles}) ->
    do_kick_all_roles();

handle({gm_reset_open_times}) ->
    reset_battle_open_times();
handle({gm_open_battle, Second}) ->
    case is_opening_battle() of
        true->
            ignore;
        _ ->
            gm_open_warofking(Second)
    end;
handle({gm_close_battle}) ->
    case is_opening_battle() of
        true->
            TimeData = get_warofking_time_data(),
            TimeData2 = TimeData#r_warofking_time{end_time=common_tool:now()},
            put(?WAROFKING_TIME_DATA,TimeData2),
            
            ok;
        _ ->
            ignore
    end;

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).


init(MapId, _MapName) ->
    case is_fb_map_id(MapId) of
        true->
            FbFactionId = get_fb_faction_id(MapId),
            BattleMapInfo = #r_warofking_map_info{is_opening=false,fb_faction_id=FbFactionId,cur_role_list=[],max_role_num=0,rank_data=[]},
            set_warofking_map_info(BattleMapInfo),
            reset_battle_open_times(),
            ok;
        _ ->
            ignore
    end.


get_warofking_entrance_info()->
    get(?WAROFKING_ENTRANCE_INFO).

get_warofking_sub_entrance_info(FactionId)->
    get({?WAROFKING_SUB_ENTRANCE_INFO,FactionId}).

set_warofking_sub_entrance_info(FactionId,SubEntranceInfo)->
    put({?WAROFKING_SUB_ENTRANCE_INFO,FactionId},SubEntranceInfo).

get_warofking_time_data()->
    get(?WAROFKING_TIME_DATA).
set_warofking_time_data(TimeData2)->
    put(?WAROFKING_TIME_DATA,TimeData2).

get_warofking_role_info(RoleID)->
    get({?WAROFKING_ROLE_INFO,RoleID}).
set_warofking_role_info(RoleID,BattleRoleInfo)->
    put({?WAROFKING_ROLE_INFO,RoleID},BattleRoleInfo).

get_warofking_map_info()->
    get(?WAROFKING_MAP_INFO).
set_warofking_map_info(BattleMapInfo)->
    put(?WAROFKING_MAP_INFO,BattleMapInfo).

loop(_MapId,NowSeconds) ->
    case get_warofking_time_data() of
        #r_warofking_time{date=Date} = NationBattleTimeData ->
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
    case ?find_config(enable_warofking) of
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
    #r_warofking_time{end_time=EndTime} = NationBattleTimeData,
    
    %% 副本开启过程中广播处理
    do_fb_open_process_broadcast(NowSeconds,NationBattleTimeData),
    
    if
        EndTime>0 andalso NowSeconds>=EndTime->
            %% 关闭副本
            close_warofking(),
            
            %% 活动关闭消息的提示
            common_activity:notfiy_activity_end(?WAROFKING_ACTIVITY_ID),
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
    #r_warofking_time{start_time=StartTime, end_time=EndTime} = NationBattleTimeData,
    if
        StartTime>0 andalso NowSeconds>=StartTime->
            open_warofking();
        true->
            %% 活动开始消息通知
            common_activity:notfiy_activity_start({?WAROFKING_ACTIVITY_ID, NowSeconds, StartTime, EndTime}),
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
    lists:member(DestMapId, ?WAROFKING_MAP_ID_LIST).

%% @doc 获取复活的回城点
get_relive_home_pos(_, MapID) ->
    {TX,TY} = get_fb_born_points(), 
    {MapID, TX, TY}.

%%@doc 得到战场的出生点
%%@return   {Tx,Ty}
get_fb_born_points()->
     [FbBornPoints] = ?find_config(fb_born_points),
     common_tool:random_element(FbBornPoints).


%%@doc 根据国家ID获取对应的地图名称
get_fb_map_name_by_faction(FactionId) when is_integer(FactionId) ->
    FBMapId = lists:nth(FactionId, ?WAROFKING_MAP_ID_LIST),
    common_map:get_common_map_name( FBMapId ).

is_in_fb_map()->
    case get(?WAROFKING_MAP_INFO) of
        #r_warofking_map_info{}->
            true;
        _ ->
            false
    end.


check_map_fight(RoleID,TargetRoleID)->
    case get_warofking_map_info() of
        #r_warofking_map_info{is_opening=true}->
            case mod_map_role:get_role_base(RoleID) of
                {ok,#p_role_base{family_id=RoleFamily}}->
                    case mod_map_role:get_role_base(TargetRoleID) of
                        {ok,#p_role_base{family_id=TargetRoleFamily}}->
                            check_map_fight_2(RoleFamily,TargetRoleFamily);
                        _ ->
                            {error, ?_LANG_SYSTEM_ERROR}
                    end;
                _ ->
                    {error, ?_LANG_SYSTEM_ERROR}
            end;
        #r_warofking_map_info{is_opening=false}->
            {error, ?_LANG_WAROFKING_FIGHT_FB_CLOSED};
        _ ->
            true
    end.
check_map_fight_2(RoleFamily,TargetRoleFamily)->
    case RoleFamily=:=TargetRoleFamily of
        true->
            {error, ?_LANG_WAROFKING_FIGHT_SAME_FAMILY};
        _ ->
            true
    end.

%% 玩家跳转进入战场地图进程
get_map_name_to_enter(RoleID)->
    case get({?WAROFKING_MAP_NAME_TO_ENTER,RoleID}) of
        {_RoleID,FbMapProcessName}->
            FbMapProcessName;
        _ ->
            undefined
    end.

clear_map_enter_tag(_RoleId)->
    ignore.

set_map_enter_tag(RoleID,BattleMapName)->
    Val = {RoleID,BattleMapName},
    put({?WAROFKING_MAP_NAME_TO_ENTER,RoleID},Val).


add_score_to_family(FamilyId,FamilyName,AddScore,OldMapInfo) when is_integer(AddScore)->
    #r_warofking_map_info{is_opening=true,score_list=ScoreList} = OldMapInfo,
    case lists:keyfind(FamilyId, #p_warofking_rank.family_id, ScoreList) of
        #p_warofking_rank{score=OldScore}->
            next;
        _ ->
            OldScore = 0
    end,
    Now = common_tool:now(),
    NewScore = (OldScore+AddScore),
    NewRank = #p_warofking_rank{score=NewScore,family_id=FamilyId,family_name=FamilyName,
                                 update_time=Now},
    ScoreList2 = lists:keystore(FamilyId, #p_warofking_rank.family_id, ScoreList, NewRank),
    set_warofking_map_info(OldMapInfo#r_warofking_map_info{score_list=ScoreList2}),
    
    notify_family_score(FamilyId,NewScore),
    
    sort_battle_rank(),
    ok.


%% @doc 怪物死亡
hook_monster_dead(KillerRoleID,MonsterTypeId)->
    case get_warofking_map_info() of
        #r_warofking_map_info{is_opening=true}=OldMapInfo->
            %%增加积分
            case mod_map_role:get_role_base(KillerRoleID) of
                {ok,#p_role_base{family_id=FamilyId,family_name=FamilyName}} when FamilyId>0->
                    add_score_to_family(FamilyId,FamilyName,1,OldMapInfo);
                _ ->
                    ?ERROR_MSG("KillerRoleID no family!",[]),
                    ignore
            end,
            
            %%掉落
            DropNum = get_drop_num(MonsterTypeId),
            do_drop_kingbox(KillerRoleID,DropNum);
        _ ->
            ignore
    end.

%%执行密匣的掉落
do_drop_kingbox(RoleID,DropNum) when DropNum>0->
    [DropBoxItemId] = ?find_config(drop_box_item_id),
    DropThing = #p_map_dropthing{num = 1,roles = [],
                                 colour = 1,goodstype = ?DROPTHING_TYPE_KINGBOX,goodstypeid = DropBoxItemId,
                                 drop_property = #p_drop_property{colour = 1,quality = 1}},
    DropThingList = lists:duplicate(DropNum, DropThing),
    mod_map_drop:handle({dropthing, RoleID, DropThingList}, mgeem_map:get_state());
do_drop_kingbox(_RoleID,_)->
    ignore.

get_drop_num(MonsterTypeId)->
    [FbMonsterList] = ?find_config(fb_monster_list),
    case lists:keyfind(MonsterTypeId, 1, FbMonsterList) of
       {MonsterTypeId,_,DropNumConfig,_}->
            {Min,Max} = DropNumConfig,
            common_tool:random(Min, Max);
        _->
            0
    end.


hook_role_enter(RoleID,_MapID)->
   case get_warofking_map_info() of
       #r_warofking_map_info{}=BattleMapInfo->
           hook_role_enter_2(RoleID,BattleMapInfo);
       _ ->
           ignore
   end.
hook_role_enter_2(RoleID,BattleMapInfo)->
    case BattleMapInfo of
        #r_warofking_map_info{is_opening=true,cur_role_list=CurRoleList,
                              max_role_num=MaxRoleNum, 
                              enter_role_list=EnterRoleList,
                              fb_faction_id=FbFactionId,
                              next_refresh_time=NextRefreshTime,score_list=ScoreList,
                              rank_data=RankData}->
            mod_role2:modify_pk_mode_for_role(RoleID,?PK_FAMILY),
            
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
            syn_warofking_sub_entrance_info(FbFactionId,NewRoleNum),
            
            %%记录进入地图的总人数
            case lists:member(RoleID, EnterRoleList) of
                true->
                    EnterRoleList2 = EnterRoleList;
                _ ->
                    EnterRoleList2 = [{RoleID,FamilyId}|EnterRoleList]
            end,
            
            set_warofking_map_info(BattleMapInfo#r_warofking_map_info{cur_role_list=NewRoleList,max_role_num=NewMaxRoleNum,
                                                                      enter_role_list=EnterRoleList2}),
             
            
            %%发送副本的信息
            case get_warofking_time_data() of
                #r_warofking_time{start_time = StartTime,end_time = EndTime} ->
                    next;
                _ ->
                    StartTime = 0,EndTime = 0
            end,
            case lists:keyfind(FamilyId, #p_warofking_rank.family_id, ScoreList) of
                #p_warofking_rank{score=MyFamilyScore}->
                    next;
                _ ->
                    MyFamilyScore = 0
            end,
            
            case get_warofking_role_info(RoleID) of
                #r_warofking_role_info{tmp_box_num=TmpBoxNum,protect_box_num=ProtectBoxNum}->
                    next;
                _ ->
                    TmpBoxNum = ProtectBoxNum = 0
            end,
            %% 插入加经验列表
            insert_interval_exp_list(RoleID),
           
            R1 = #m_warofking_info_toc{fb_start_time=StartTime,fb_end_time=EndTime,
                                       next_refresh_time=NextRefreshTime,my_family_score=MyFamilyScore,tmp_box_num=TmpBoxNum,protect_box_num=ProtectBoxNum
                                       },
            R2 = #m_warofking_rank_toc{ranks=RankData}, 
            
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFKING, ?WAROFKING_ENTER, #m_warofking_enter_toc{}),
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFKING, ?WAROFKING_INFO, R1),
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFKING, ?WAROFKING_RANK, R2),

            ok;
        _ ->
            do_warofking_quit_2(RoleID),
            ?ERROR_MSG("副本关闭了，还有人进来！RoleID=~w",[RoleID])
    end.
hook_role_quit(RoleID)->
    case get_warofking_map_info() of
        #r_warofking_map_info{is_opening=true,fb_faction_id=FbFactionId,cur_role_list=CurRoleList}=MapInfo->
            NewRoleList = lists:keydelete(RoleID, 1, CurRoleList),
            NewRoleNum = length(NewRoleList),
            syn_warofking_sub_entrance_info(FbFactionId,NewRoleNum),
            
            set_warofking_map_info(MapInfo#r_warofking_map_info{cur_role_list=NewRoleList}),
            
            drop_kingbox_from_role(RoleID),
            [ConfBuffIdList] = ?find_config(fb_buy_buff_list),
            mod_pve_fb:remove_pve_fb_buffs(RoleID, ConfBuffIdList),
            %% 移出加经验列表
            delete_interval_exp_list(RoleID),
            ok;
        #r_warofking_map_info{}->
            [ConfBuffIdList] = ?find_config(fb_buy_buff_list),
            mod_pve_fb:remove_pve_fb_buffs(RoleID, ConfBuffIdList),
            mod_role_buff:del_buff_by_type(RoleID, ?BUFF_TYPE_WAROFKING_PICKER);
        _ ->
            ignore
    end.

hook_role_before_quit(RoleID)->
    case get_warofking_map_info() of
        #r_warofking_map_info{}->
            [ConfBuffIdList] = ?find_config(fb_buy_buff_list),
            mod_pve_fb:remove_pve_fb_buffs(RoleID, ConfBuffIdList),
            mod_role_buff:del_buff_by_type(RoleID, ?BUFF_TYPE_WAROFKING_PICKER);
        _ ->
            ignore
    end.

%%检查玩家身上是否有指定BuffID列表
%%@param RoleID
%%@param BuffIdList
has_same_buff_in_role(_RoleBuffs,[])->
    false;
has_same_buff_in_role(RoleBuffs,[H|T])->
    case lists:keyfind(H, #p_actor_buf.buff_id, RoleBuffs) of
        false->
            has_same_buff_in_role(RoleBuffs,T);
        _ ->
            true
    end.    

%%拾取了王座的宝匣
hook_pick_king_box(RoleID,DropThing)->
    %%先删掉掉落物
    mod_map_drop:handle({dropthing_quit,DropThing}, mgeem_map:get_state()),
    
    case is_opening_battle() of
        true->
            case get_warofking_role_info(RoleID) of
                #r_warofking_role_info{tmp_box_num=TmpBoxNum}=OldRoleInfo->
                    NewRoleInfo = OldRoleInfo#r_warofking_role_info{tmp_box_num=(TmpBoxNum+1)};
                _ ->
                    NewRoleInfo = #r_warofking_role_info{tmp_box_num=1,protect_box_num=0}
            end,
            
            set_warofking_role_info(RoleID,NewRoleInfo),
            notify_my_box_num(RoleID,NewRoleInfo),
            
            [PickerBuffId] = ?find_config(pick_box_buff_id),
            mod_role_buff:del_buff_by_type(RoleID,PickerBuffId);
        _ ->
            ignore
    end.

hook_role_dead(DeadRoleID, _SActorID, _SActorType)->
    case is_opening_battle() of
        true->
            drop_kingbox_from_role(DeadRoleID);
        _ ->
            ignore
    end.

%%@doc 玩家退出地图、死亡的时候掉落宝匣
%%如果玩家拥有临时的宝匣，则需要删除buff，需要掉落宝匣
drop_kingbox_from_role(RoleID)->
    case get_warofking_role_info(RoleID) of
        #r_warofking_role_info{tmp_box_num=TmpBoxNum} = OldRoleInfo when TmpBoxNum>0->
            mod_role_buff:del_buff_by_type(RoleID, ?BUFF_TYPE_WAROFKING_PICKER),
            
            NewRoleInfo = OldRoleInfo#r_warofking_role_info{tmp_box_num=0},
            set_warofking_role_info(RoleID,NewRoleInfo),
            notify_my_box_num(RoleID,NewRoleInfo),
            
            do_drop_kingbox(RoleID,TmpBoxNum);
        _ ->
            ignore
    end.

sort_battle_rank()->
    case get_warofking_map_info() of
        #r_warofking_map_info{score_list=ScoreList,rank_data=OldRankList}=BattleMapInfo->
            {ok,ScoreList2,NewRankList} = get_new_rank_list(ScoreList,true),
            set_warofking_map_info(BattleMapInfo#r_warofking_map_info{score_list=ScoreList2,rank_data=NewRankList}),
            if
                OldRankList=:=NewRankList->
                    ignore;
                true->
                    notify_battle_rank(NewRankList)
            end;
        _ ->
            ignore
    end.

%%获取新的积分排名列表
get_new_rank_list(ScoreList,IsSortAll) when is_list(ScoreList)->
    ScoreList2 =  lists:sort(
                    fun(E1,E2)->
                            #p_warofking_rank{score=S1,update_time=U1} = E1,
                            #p_warofking_rank{score=S2,update_time=U2} = E2,
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
                  {Order+1,[E#p_warofking_rank{order=Order}|RankAcc]}
          end, {1,[]}, PartScoreList),
    {ok,ScoreList2,NewRankList}.

%%@doc 更新积分排行
notify_battle_rank(NewRankList)->
    RoleIdList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              R2 = #m_warofking_rank_toc{ranks=NewRankList},
              common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFKING, ?WAROFKING_RANK, R2)
      end, RoleIdList). 

%%@doc 更新怪物的下次刷新时间
notify_battle_refresh_time(RefreshTime)->
    RoleIdList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              R2 = #m_warofking_change_toc{change_type=?CHANGE_TYPE_REFRESH_TIME,next_refresh_time=RefreshTime},
              common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFKING, ?WAROFKING_CHANGE, R2)
      end, RoleIdList). 

%%@doc 更新本人密匣数量
notify_my_box_num(RoleID,NewRoleInfo)->
    #r_warofking_role_info{tmp_box_num=TmpBoxNum,protect_box_num=ProtectBoxNum} = NewRoleInfo,
    R2 = #m_warofking_change_toc{change_type=?CHANGE_TYPE_BOX_NUM,tmp_box_num=TmpBoxNum,protect_box_num=ProtectBoxNum},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFKING, ?WAROFKING_CHANGE, R2),
    ok.

%%@doc 更新家族的积分
notify_family_score(FamilyId,Score) when is_integer(FamilyId)->
    #r_warofking_map_info{cur_role_list=CurRoleList}=get_warofking_map_info(),
    RoleIdList = [ RoleID || {RoleID,CurFamilyId}<-CurRoleList,CurFamilyId=:=FamilyId ],
    
    lists:foreach(
      fun(E)->
              R2 = #m_warofking_change_toc{change_type=?CHANGE_TYPE_SCORE,my_family_score=Score},
              common_misc:unicast({role, E}, ?DEFAULT_UNIQUE, ?WAROFKING, ?WAROFKING_CHANGE, R2)
      end, RoleIdList),
    ok.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------


do_warofking_enter({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    case catch check_warofking_enter(RoleID,DataIn) of
        {ok,FactionId}->
            do_warofking_enter_2(RoleID,FactionId);
        {error,ErrCode,Reason}->
            R2 = #m_warofking_enter_toc{err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.
    

do_warofking_enter_2(RoleID,FactionId)->
    %%地图跳转
    FBMapId = lists:nth(FactionId, ?WAROFKING_MAP_ID_LIST),
    {Tx,Ty} = get_fb_born_points(),
    
    BattleMapName = get_fb_map_name_by_faction(FactionId),
    set_map_enter_tag(RoleID,BattleMapName),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID, FBMapId, Tx, Ty),
    ok.


do_warofking_quit({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    case catch check_warofking_quit(RoleID,DataIn) of
        ok->
            do_warofking_quit_2(RoleID);
        {error,ErrCode,Reason}->
            R2 = #m_warofking_quit_toc{err_code=ErrCode,reason=Reason},
			?UNICAST_TOC(R2)
    end.

do_warofking_quit_2(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{state=?ROLE_STATE_DEAD}->%%死亡状态
            mod_role2:relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, RoleID, ?RELIVE_TYPE_ORIGINAL_FREE);
        _ ->
            ignore
    end,
	common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?WAROFKING,?WAROFKING_QUIT,#m_warofking_quit_toc{}),
    {DestMapId,TX,TY} = get_warofking_return_pos(RoleID),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapId, TX, TY),
    ok.


do_warofking_buy_buff({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    case catch check_warofking_buy_buff(RoleID,DataIn) of
        {ok,MoneyType,CostMoney,BuffIdList}->
            #m_warofking_buy_buff_tos{type=Type} = DataIn,
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
                    lists:foreach(
                      fun(BuffId)-> 
                              mod_role_buff:del_buff_by_type(RoleID,BuffId)
                      end, BuffIdList),
                    Now = common_tool:now(),
                    
                    %%修改购买BUFF的时间
                    case get_warofking_role_info(RoleID) of
                        #r_warofking_role_info{}=OldRoleInfo->
                            NewRoleInfo = OldRoleInfo#r_warofking_role_info{last_buy_buff_time=Now};
                        _ ->
                            NewRoleInfo = #r_warofking_role_info{last_buy_buff_time=Now}
                    end,
                    set_warofking_role_info(RoleID,NewRoleInfo), 
                    
                    R2 = #m_warofking_buy_buff_toc{type=Type};
                {aborted, AbortErr} ->
                    {error,ErrCode,Reason} = parse_aborted_err(AbortErr),
                    R2 = #m_warofking_buy_buff_toc{type=Type,err_code=ErrCode,reason=Reason}
            end;
        {error,ErrCode,Reason}->
            R2 = #m_warofking_buy_buff_toc{err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).


check_warofking_buy_buff(RoleID,DataIn)->
    #m_warofking_buy_buff_tos{type=Type} = DataIn,
    case is_in_fb_map() of
        true->
            next;
        _ ->
            ?THROW_ERR( ?ERR_WAROFKING_BUY_BUFF_NOT_IN_MAP )
    end,
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{}->
            next;
        _ ->
            ?THROW_ERR( ?ERR_WAROFKING_BUY_BUFF_NOT_IN_MAP )
    end,
    [FbBuffList] = ?find_config(fb_buff_list),
    case lists:keyfind(Type,#r_pve_fb_buff_info.type,FbBuffList) of
        #r_pve_fb_buff_info{money_type=MoneyType,cost_money=CostMoney,buff_id_list=BuffIdList} ->
            ol;
        _ ->
            MoneyType = CostMoney = BuffIdList= null,
            ?THROW_ERR( ?ERR_WAROFKING_BUY_BUFF_INVALID_BUFF )
    end,
    Now = common_tool:now(),
    case get_warofking_role_info(RoleID) of
        #r_warofking_role_info{last_buy_buff_time=LastBuyBuffTime} when LastBuyBuffTime>0->
            [BuyBuffCdTime] = ?find_config(fb_buy_buff_cd_time), 
            if
                Now>(LastBuyBuffTime+BuyBuffCdTime)->
                    next;
                true->
                    ?THROW_ERR( ?ERR_WAROFKING_BUY_BUFF_CD_TIME )
            end;
        _ ->
            next
    end,
    case mod_map_role:get_role_base(RoleID) of
        {ok, #p_role_base{buffs=RoleBuffs}}->
            case has_same_buff_in_role(RoleBuffs,BuffIdList) of
                true->
                    ?THROW_ERR( ?ERR_WAROFKING_BUY_BUFF_EXISTS );
                _ ->
                    next
            end;
        _ ->
            ?THROW_ERR( ?ERR_WAROFKING_BUY_BUFF_NOT_IN_MAP )
    end,
    {ok,MoneyType,CostMoney,BuffIdList}.

%%获取副本返回的位置
get_warofking_return_pos(RoleID)->
    %%好吧，踢回京城
    common_map:get_map_return_pos_of_jingcheng(RoleID).

   



%%对所有的人进行奖励，并踢出地图
reward_and_kick_all_roles()->
    %%获取连胜奖励列表
    #r_warofking_map_info{enter_role_list=EnterRoleList,rank_data=RankData} = get_warofking_map_info(),
    
    %%发送战场的物品奖励信件
    RewardRoleList = send_battle_reward_letter(EnterRoleList,RankData),
    RewardRoleNum = length(RewardRoleList),
    
    case get_winner_family_id(RankData) of
        0->
            do_battle_fb_log(RewardRoleNum);
        FamilyRankInfo->
            ?TRY_CATCH( reward_winner_family(FamilyRankInfo,EnterRoleList,RewardRoleNum) )
    end,
    
    %%删除字典信息
    lists:foreach(
      fun({RoleID,_}) ->
              erase({?WAROFKING_ROLE_INFO,RoleID})
      end, EnterRoleList),
    
    %%踢人
    erlang:send_after(3000, self(), {mod,?MODULE,{kick_all_roles}}),
    ok.

do_kick_all_roles()->
    RoleIdList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              do_warofking_quit_2(RoleID)
      end, RoleIdList).

reward_winner_family(FamilyRankInfo,EnterRoleList,RewardRoleNum) ->
	#p_warofking_rank{family_id=FamilyID} = FamilyRankInfo,
    [#p_family_info{owner_role_id=KingRoleID, family_name=FamilyName, owner_role_name=KingRoleName, 
                    faction_id = FactionID}] = db:dirty_read(?DB_FAMILY, FamilyID),
    %%取消上一节的本国国王，设置本届的国王
    common_office:set_king(KingRoleID, KingRoleName, FactionID),
    %%本门派所有成员获取一个2小时双倍经验buff
    common_buff:add_family_double_exp(family, FamilyID),
    {_, {Hour, Min, _}} = calendar:local_time(),
    Hour2 = Hour + 2,
    case Hour2 >= 24 of
        true ->
            HourEnd = Hour2 - 24;
        false ->
            HourEnd = Hour2
    end,
    
    
    %%所有进入过战场的人都发送通知
    R2C = #m_warofking_result_toc{family_id=FamilyID,family_name=FamilyName,king_name=KingRoleName},
    lists:foreach(
      fun( {RoleID,_} )->
              common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFKING, ?WAROFKING_RESULT, R2C)
      end, EnterRoleList ),
    
    %%记录日志
    ?TRY_CATCH( do_battle_fb_log(FamilyID,FamilyName,KingRoleName,RewardRoleNum) ),
    
    
    ContentMsg = common_misc:format_lang(?_LANG_WAROFKING_WINNER_FAMILY_BC, [Hour, Min, HourEnd, Min]),
    common_broadcast:bc_send_cycle_msg_family(FamilyID, ?BC_MSG_TYPE_CHAT, ?BC_MSG_TYPE_CHAT_FAMILY, ContentMsg, common_tool:now(),
                                              common_tool:now()+ 7200, 600),
    RC = #m_chat_warofking_toc{family_name=FamilyName, role_name=KingRoleName},
    common_misc:chat_broadcast_to_faction(FactionID, ?CHAT, ?CHAT_WAROFKING, RC),
    ok.

%%获取获胜家族ID
 get_winner_family_id([])->
     0;
 get_winner_family_id(RankData) when is_list(RankData)->
      lists:keyfind(1, #p_warofking_rank.order, RankData).




%% --------------------------------------------------------------------
%%  内部的二级API
%% --------------------------------------------------------------------
assert_role_level(RoleAttr)->
    #p_role_attr{level=RoleLevel} = RoleAttr,
    [MinRoleLevel] = ?find_config(fb_min_role_level),
    if
        MinRoleLevel>RoleLevel->
            ?THROW_ERR( ?ERR_WAROFKING_ENTER_LV_LIMIT );
        true->
            next
    end,
    ok.

assert_role_family(FamilyId)->
    if
        is_integer(FamilyId) andalso FamilyId>0 ->
            next;
        true->
            ?THROW_ERR( ?ERR_WAROFKING_ENTER_FAMILY_LIMIT )
    end,
    ok.

assert_role_jingjie(RoleAttr)->
    #p_role_attr{jingjie=Jingjie} = RoleAttr,
    [MinRoleTitle] = ?find_config(fb_min_role_jingjie),
    if
        MinRoleTitle>Jingjie->
            ?THROW_ERR( ?ERR_WAROFKING_ENTER_JINGJIE_LIMIT );
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
            ?THROW_ERR( ?ERR_WAROFKING_ENTER_FACTION_LIMIT )
    end,
    ok.

assert_role_faction(RoleFaction,FbFactionId)->
    if
        RoleFaction=:=FbFactionId->
            next;
        true->
            ?THROW_ERR( ?ERR_WAROFKING_ENTER_FACTION_LIMIT )
    end,
    ok.

get_fb_min_role_jingjie_str()->
    [MinRoleTitle] = ?find_config(fb_min_role_jingjie),
    common_title:get_jingjie_name(MinRoleTitle).

check_warofking_enter(RoleID,_DataIn)->
    [EnableNationBattle] = ?find_config(enable_warofking),
    if
        EnableNationBattle=:=true->
            next;
        true->
            ?THROW_ERR( ?ERR_WAROFKING_DISABLE )
    end,
    
    {ok,#p_role_base{faction_id=RoleFaction,family_id=FamilyId}} = mod_map_role:get_role_base(RoleID),
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    assert_role_level(RoleAttr),
    assert_role_jingjie(RoleAttr),
    assert_role_family(FamilyId),
    assert_role_enter_faction(RoleFaction),
    
    case is_in_fb_map() of
        true->
            ?THROW_ERR( ?ERR_WAROFKING_ENTER_IN_BATTLE );
        _ ->
            next
    end,
    #map_state{mapid=MapID,map_type=MapType} = mgeem_map:get_state(),
    IsInWarofkingFb = is_fb_map_id(MapID),
    
    if
        MapType=:=?MAP_TYPE_COPY->
            ?THROW_ERR( ?ERR_WAROFKING_ENTER_FB_LIMIT );
        IsInWarofkingFb->
            ?THROW_ERR( ?ERR_WAROFKING_ENTER_FB_LIMIT );
        true->
            next
    end,
    %%检查入口信息
    case get_warofking_entrance_info() of
        undefined->
            req_warofking_entrance_info(),
            ?THROW_ERR( ?ERR_WAROFKING_ENTER_CLOSING );
        #r_warofking_entrance_info{is_opening=true}->
            next;
        _ ->
            req_warofking_entrance_info(),
            ?THROW_ERR( ?ERR_WAROFKING_ENTER_CLOSING )
    end,
    
    
    %%检查人数
    case get_warofking_sub_entrance_info(RoleFaction) of
        undefined->
            req_warofking_sub_entrance_info(RoleFaction),
            ?THROW_ERR( ?ERR_WAROFKING_ENTER_CLOSING );
        #r_warofking_sub_entrance_info{map_role_num=CurRoleNum}->
            [{_LimitRoleMode,AllRoleNum,_}] = ?find_config(limit_role_mode),
           
            if
                        CurRoleNum>=AllRoleNum->
                            ?THROW_ERR( ?ERR_WAROFKING_ENTER_MAX_ROLE_NUM );
                        true->
                            next
                    end;
        _ ->
            ?THROW_ERR( ?ERR_WAROFKING_ENTER_CLOSING )
    end,
    {ok,RoleFaction}.


check_warofking_quit(_RoleID,_DataIn)->
    case is_in_fb_map() of
        true->
            next;
        _->
            ?THROW_ERR( ?ERR_WAROFKING_QUIT_NOT_IN_MAP )
    end,
    ok.


%%--------------------------------  战场入口消息的代码，可复用  [start]--------------------------------


%%请求更新入口信息
req_warofking_entrance_info()->
    send_master_map_msg( {req_warofking_entrance_info} ).

req_warofking_sub_entrance_info(FactionId)->
    send_slave_map_msg(FactionId,{req_warofking_sub_entrance_info}).

do_req_warofking_entrance_info()->
    case get_warofking_map_info() of
        #r_warofking_map_info{is_opening=IsOpening}->
            EntranceInfo = #r_warofking_entrance_info{is_opening=IsOpening},
            init_warofking_entrance_info(EntranceInfo),
            ok;
        _ ->
            ignore
    end.

do_req_warofking_sub_entrance_info()->
    case get_warofking_map_info() of
        #r_warofking_map_info{fb_faction_id=FbFactionId,cur_role_list=CurRoleList}->
            AllRoleNum = length(CurRoleList),
            syn_warofking_sub_entrance_info(FbFactionId,AllRoleNum),
            ok;
        _ ->
            ignore
    end.

%%同步更新入口信息
%%  包括更新到王城、Slave进程
init_warofking_entrance_info(EntranceInfo) when is_record(EntranceInfo,r_warofking_entrance_info)->
    [EntranceMapIdList] = ?find_config(entrance_map_id),
    lists:foreach(
      fun(EntranceMapId)->
              SendInfo = {mod,?MODULE,{init_warofking_entrance_info,EntranceInfo}},
              case global:whereis_name( common_map:get_common_map_name(EntranceMapId) ) of
                  undefined->
                      ignore;
                  MapPID->
                      MapPID ! SendInfo
              end
      end, EntranceMapIdList).

syn_warofking_sub_entrance_info(FbFactionId,AllRoleNum) ->
    SubEntranceInfo = #r_warofking_sub_entrance_info{map_role_num=AllRoleNum},
    [EntranceMapIdList] = ?find_config(entrance_map_id),
    EntranceMapId = lists:nth(FbFactionId, EntranceMapIdList),
    SendInfo = {mod,?MODULE,{syn_warofking_sub_entrance_info,FbFactionId,SubEntranceInfo}},
    case global:whereis_name( common_map:get_common_map_name(EntranceMapId) ) of
        undefined->
            ignore;
        MapPID->
            MapPID ! SendInfo
    end.

do_syn_warofking_sub_entrance_info(FactionId,SubEntranceInfo)->
    set_warofking_sub_entrance_info(FactionId,SubEntranceInfo),
    ok.

do_init_warofking_entrance_info(EntranceInfo) when is_record(EntranceInfo,r_warofking_entrance_info)->
    put(?WAROFKING_ENTRANCE_INFO,EntranceInfo),
    ok.

do_update_warofking_entrance_info(ValList) when is_list(ValList)->
    case get(?WAROFKING_ENTRANCE_INFO) of
        #r_warofking_entrance_info{}= OldInfo->
            EntranceInfo =
                lists:foldl(
                  fun(E,AccIn)-> 
                          {EType,EVal} = E,
                          case EType of
                              is_opening->
                                  AccIn#r_warofking_entrance_info{is_opening=EVal}
                          end
                  end, OldInfo, ValList),
            put(?WAROFKING_ENTRANCE_INFO,EntranceInfo),
            ok;
        _ ->
            ignore
    end,
    ok.

%%--------------------------------  战场入口消息的代码，可复用  [end]--------------------------------

%%--------------------------------  定时战场的代码，可复用  [start]--------------------------------

is_opening_battle()->
    case get_warofking_map_info() of
        #r_warofking_map_info{is_opening=IsOpening}->
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
            R1 = #r_warofking_time{date = Date,
                                      start_time = StartTimeSeconds,end_time = EndTimeSeconds,
                                      next_bc_start_time = NextBcStartTime,
                                      next_bc_end_time = NextBcEndTime,
                                      next_bc_process_time = NextBcProcessTime,
                                      before_interval = BeforeInterval,
                                      close_interval = CloseInterval,
                                      process_interval = ProcessInterval},
            put(?WAROFKING_TIME_DATA,R1),
            {ok,StartTimeSeconds};
        {error,Reason}->
            {error,Reason}
    end.


%%--------------------------------  定时战场的代码，可复用  [end]--------------------------------

%%--------------------------------  战场广播的代码，可复用  [start]--------------------------------
%% 副本开起提前广播开始消息
%% Record 结构为 r_warofking_time
%% 返回 new r_warofking_time
do_fb_open_before_broadcast(NowSeconds,Record) ->
    #r_warofking_time{
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
                       common_misc:format_lang(?_LANG_WAROFKING_PRESTART,[StartTimeStr,MinJingjieStr]);
                   _ ->
                       common_misc:format_lang(?_LANG_WAROFKING_STARTED,[MinJingjieStr])
               end,
           FactionId = get_fb_faction_id(),
           catch common_broadcast:bc_send_msg_faction(FactionId,?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,BeforeMessage),
           set_warofking_time_data( Record#r_warofking_time{
                                                                  next_bc_start_time = NowSeconds + BeforeInterval} );
       true ->
           Record
    end.
%% 副本开启过程中广播处理
%% Record 结构为 r_warofking_time
%% 返回
do_fb_open_process_broadcast(NowSeconds,Record) ->
    #r_warofking_time{
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
            ProcessMessage = common_misc:format_lang(?_LANG_WAROFKING_STARTED,[MinJingjieStr]),
            FactionId = get_fb_faction_id(),
            catch common_broadcast:bc_send_msg_faction(FactionId,?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,ProcessMessage),
            set_warofking_time_data( Record#r_warofking_time{
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
               common_misc:format_lang(?_LANG_WAROFKING_CLOSED_TIME,[NextStartTimeStr]);
           true ->
               ?_LANG_WAROFKING_CLOSED_FINAL
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
	[MulExp] = ?find_config(mul_exp),
	RoleIDList = get_interval_exp_list(Now),
	lists:foreach(
	  fun(RoleID) ->
			  case mod_map_actor:get_actor_mapinfo(RoleID, role) of
				  undefined ->
					  delete_interval_exp_list(RoleID);
				  #p_map_role{faction_id=FactionID, level=Level} ->
					  ExpAdd = get_interval_exp_add(FactionID, Level),
					  MulExp2 = 
					  case get_warofking_role_info(RoleID) of
						  #r_warofking_role_info{tmp_box_num=TmpBoxNum}->
							  case TmpBoxNum >= 1 of
								  true ->
									  MulExp;
								  false ->
									  1
							  end;
						  _ ->
							  1
					  end,
					  mod_map_role:do_add_exp(RoleID, ExpAdd*MulExp2)
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
      end, ?WAROFKING_MAP_ID_LIST).

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
gm_open_warofking(Second)->
	%%GM命令，手动开启
	TimeData = get_warofking_time_data(),
	StartTime2 = common_tool:now(),
	[FbGmOpenLastTime] = ?find_config(fb_gm_open_last_time),
	EndTime2 = StartTime2 + FbGmOpenLastTime,
	TimeData2 = TimeData#r_warofking_time{date=date(),start_time=StartTime2 + Second,end_time=EndTime2},
	set_warofking_time_data(TimeData2).


%%开启副本
open_warofking()->   
    [{_,BornTimes}] = ?find_config(fb_monster_born_interval),
    FbFactionId = get_fb_faction_id(),
    
    set_warofking_map_info(#r_warofking_map_info{is_opening=true,fb_faction_id=FbFactionId,remain_refresh_times=BornTimes}),
    %%清除怪物
    mod_map_monster:delete_all_monster(),
    
    EntranceInfo = #r_warofking_entrance_info{is_opening=true},
    init_warofking_entrance_info(EntranceInfo),
    
    %%设置战争开始
    case global:whereis_name( mgeew_event ) of
        undefined->
            ignore;
        PID->
            erlang:send(PID, {mod_event_warofking, begin_war})
    end,
    
    init_warofking_monster_info(),
    ok.


%%关闭副本
close_warofking()->
    %%清除怪物，计算家族积分
    mod_map_monster:delete_all_monster(),
    calc_family_score(),
    
    BattleMapInfo = get_warofking_map_info(),
    set_warofking_map_info(BattleMapInfo#r_warofking_map_info{is_opening=false,next_refresh_time=0,remain_refresh_times=0}),
    
    EntranceInfo = #r_warofking_entrance_info{is_opening=false},
    init_warofking_entrance_info(EntranceInfo),
    
    %%设置战争结束
    case global:whereis_name( mgeew_event ) of
        undefined->
            ignore;
        PID->
            erlang:send(PID, {mod_event_warofking, end_war})
    end,
    
    reward_and_kick_all_roles(),
    
    {ok,NextStartTimeSeconds} = reset_battle_open_times(),
    do_fb_close_broadcast(NextStartTimeSeconds),
    
    ok.


%%--------------------------------  战场开/关的代码，可复用 [end] --------------------------------

init_warofking_monster_info()->
    erlang:send(self(), {mod,?MODULE,{refresh_warofking_monster}}),
    ok.

%%刷新怪物，计算积分
do_refresh_warofking_monster()->
    mod_map_monster:delete_all_monster(),
    ?TRY_CATCH( calc_family_score() ),
    
    case get_warofking_map_info() of
        #r_warofking_map_info{next_refresh_time=NowRefreshTime,remain_refresh_times=OldRemainRefreshTimes}=OldMapInfo->
            NewRemainRefreshTimes = OldRemainRefreshTimes-1,
            %%设置下次的刷新时间
            [{BornInterval,_}] = ?find_config(fb_monster_born_interval),
            NextRefreshTime = common_tool:now() + BornInterval,
            case NewRemainRefreshTimes>0 of
                true->
                    erlang:send_after(BornInterval*1000, self(), {mod,?MODULE,{refresh_warofking_monster}}),
                    notify_battle_refresh_time(NextRefreshTime);
                _ ->
                    ignore
            end,
            
            %%刷新新的一批怪物
            [FbMonsterList] = ?find_config(fb_monster_list),
            FbMonsterConfig = common_tool:random_element( FbMonsterList ),
            {MonsterTypeId,BornNumConfig,_DropNumConfig,BornPointListConf} = FbMonsterConfig,
            #map_state{mapid=MapID, map_name=MapProcessName} = mgeem_map:get_state(),
            case NowRefreshTime of
                0-> %%第一次刷怪物在出生点
                    [FbBornPoints] = ?find_config(fb_born_points),
                    BornPointList = [hd(FbBornPoints)];
                _ ->
                    BornPointList = BornPointListConf
            end,
            
            {ok,#p_pos{tx=TX, ty=TY},MonsterList} = get_born_monster(MapID,MonsterTypeId,BornPointList,BornNumConfig),
            broadcast_in_map( common_misc:format_lang( ?_LANG_WAROFKING_MONSTER_BORN_BC , [TX,TY]) ),
            mod_map_monster:init_call_fb_monster(MapProcessName,MapID,MonsterList),
            
            
            NewMapInfo = OldMapInfo#r_warofking_map_info{next_refresh_time=NextRefreshTime,remain_refresh_times=NewRemainRefreshTimes},
            set_warofking_map_info(NewMapInfo),
            ok;
        _ ->
            ignore
    end.

broadcast_in_map( Msg )->
    RoleIdList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun( RoleID )->
              common_broadcast:bc_send_msg_role(RoleID, [?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_SYSTEM], ?BC_MSG_SUB_TYPE, Msg)
      end, RoleIdList),
    ok.



%%@doc 计算家族的积分
%%     将临时的宝匣变为受保护的宝匣，并且增加对应的积分
calc_family_score()->
    case get_warofking_map_info() of
        #r_warofking_map_info{is_opening=true,score_list=OldScoreList,enter_role_list=AllRoleIdList}=OldMapInfo->
            AddFamilyScoreList = get_add_family_score_list(AllRoleIdList),
            Now = common_tool:now(),
            NewScoreList = 
                lists:foldl(
                  fun(E,AccIn)-> 
                          {FamilyId,FamilyName,AddScore} = E,
                          case lists:keyfind(FamilyId, #p_warofking_rank.family_id, AccIn) of
                              #p_warofking_rank{score=OldScore}->
                                  next;
                              _ ->
                                  OldScore=0
                          end,
                          NewScore=OldScore+AddScore,
                          notify_family_score(FamilyId,NewScore),
                          
                          NewTuple = #p_warofking_rank{ family_id=FamilyId,family_name=FamilyName, score=NewScore,update_time=Now},
                          lists:keystore(FamilyId, #p_warofking_rank.family_id, AccIn, NewTuple)
                  end, OldScoreList, AddFamilyScoreList),
            NewMapInfo = OldMapInfo#r_warofking_map_info{score_list=NewScoreList},
            set_warofking_map_info( NewMapInfo ),
            
            sort_battle_rank();
        _ ->
            ignore
    end.

%%将地图中所有人的临时密匣计算到家族积分中
get_add_family_score_list(RoleIdList) when is_list(RoleIdList)->
    lists:foldl(
      fun({RoleID,_},AccIn)->
              case get_warofking_role_info(RoleID) of
                  #r_warofking_role_info{tmp_box_num=TmpBoxNum,protect_box_num=ProtectBoxNum}=OldRoleInfo when TmpBoxNum>0->
                      case mod_map_role:get_role_base(RoleID) of
                          {ok,#p_role_base{family_id=FamilyId,family_name=FamilyName}} when FamilyId>0->
                              case lists:keyfind(FamilyId, 1, AccIn) of
                                  false-> OldScore=0; 
                                  {FamilyId,_FamilyName,OldScore}->
                                      next
                              end,
                              if
                                  TmpBoxNum>0 ->
                                      %%删除BUFF
                                      mod_role_buff:del_buff_by_type(RoleID, ?BUFF_TYPE_WAROFKING_PICKER);
                                  true->
                                      next
                              end,
                              
                              %%将临时的宝匣变为受保护的宝匣
                              NewRoleInfo = OldRoleInfo#r_warofking_role_info{tmp_box_num=0,protect_box_num=(ProtectBoxNum+TmpBoxNum)},
                              set_warofking_role_info(RoleID,NewRoleInfo),
                              
                              notify_my_box_num(RoleID,NewRoleInfo),
                              
                              AddTmpScore = TmpBoxNum*10,
                              NewTuple = {FamilyId,FamilyName,(OldScore+AddTmpScore)},
                              lists:keystore(FamilyId, 1, AccIn, NewTuple);
                          _->
                              AccIn
                      end;
                  _ ->
                      AccIn
              end  
      end, [], RoleIdList).

%%@return {ok,Pos,MonsterList}
get_born_monster(MapID,MonsterTypeId,BornPointList,BornNumConfig)->
    {MinNum,MaxNum} = BornNumConfig,
    BornNum = common_tool:random(MinNum, MaxNum),
    {TX,TY} = common_tool:random_element( BornPointList ),
    Pos = #p_pos{tx=TX, ty=TY, dir=1},
    
    MonsterList = lists:map(
      fun(_E)->
              #p_monster{reborn_pos=Pos,
                         monsterid=mod_map_monster:get_max_monster_id_form_process_dict(),
                         typeid=MonsterTypeId,
                         mapid=MapID}
      end, lists:seq(1, BornNum)),
    {ok,Pos,MonsterList}.


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



%%记录战场的日志
do_battle_fb_log(RewardRoleNum)->
    do_battle_fb_log(0,<<"">>,<<"">>,RewardRoleNum).
do_battle_fb_log(WinnerFamilyId,WinnerFamilyName,KingName,RewardNum)->
    case get_warofking_time_data() of
        #r_warofking_time{start_time = StartTime,end_time = EndTime} ->
            case get_warofking_map_info() of
                #r_warofking_map_info{max_role_num=MaxRoleNum,fb_faction_id=FbFactionId}->
                    MapId = mgeem_map:get_mapid(),
                    BattleFbLog = #r_warofking_fb_log{
                                                            faction_id=FbFactionId,map_id=MapId,start_time=StartTime, end_time=EndTime, 
                                                            max_role_num=MaxRoleNum,
                                                            winner_family_id=WinnerFamilyId,winner_family_name=WinnerFamilyName,
                                                            king_name=KingName,reward_mail_role_num=RewardNum},
                    common_general_log_server:log_warofking_fb(BattleFbLog);
                _ ->
                    ignore
            end;
        _ ->
            ignore
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
    common_bag2:check_money_enough_and_throw(MoneyType,DeductMoney,RoleID),
    case common_bag2:t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeLogType) of
        {ok,RoleAttr2}->
            {ok,RoleAttr2};
        {error,silver_any}->
            ?THROW_ERR( ?ERR_WAROFKING_BUY_BUFF_SILVER_NOT_ENOUGH );
        {error,gold_any}->
            ?THROW_ERR( ?ERR_WAROFKING_BUY_BUFF_GOLD_NOT_ENOUGH );
        {error, Reason} ->
            ?THROW_ERR(?ERR_OTHER_ERR, Reason);
        _ ->
            ?THROW_SYS_ERR()
    end. 

%%发送战场的物品奖励信件
send_battle_reward_letter(EnterRoleList,RankData) when is_list(EnterRoleList)->
	%%#r_warofking_map_info{cur_role_list=CurRoleList}=get_warofking_map_info(),
	[RewardItemId] = ?find_config(reward_item_id),
	RewardList = lists:usort(EnterRoleList),
	lists:foldl(
	  fun( {RoleID,_},AccIn )-> 
			  {_,FamilyID} = lists:keyfind(RoleID, 1, EnterRoleList),
			  case lists:keyfind(FamilyID, #p_warofking_rank.family_id, RankData) of
				  false -> 
					  AccIn;
				  #p_warofking_rank{order=Order,score=Score} ->
					  case get_warofking_role_info(RoleID) of
						  #r_warofking_role_info{tmp_box_num=TmpBoxNum,protect_box_num=ProtBoxNum} ->
							  Num = TmpBoxNum+ProtBoxNum,
							  %%信件方式赠送物品
							  if
								  Num>0->
									  ?TRY_CATCH( send_battle_reward_letter(RoleID,RewardItemId,Num,{Order,Score}) ),
									  [RoleID|AccIn];
								  true->
									  AccIn
							  end;
						  _ ->
							  AccIn
					  end
			  end
	  end, [],RewardList).
send_battle_reward_letter(RoleID,PropTypeId,Num,{Order,Score}) when is_integer(RoleID),is_integer(Num)->
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
            send_battle_reward_letter_2(RoleID,GoodsList2,Num,{Order,Score});
        {error,Reason}->
            ?ERROR_MSG("send_battle_reward_letter,Reason=~w,RoleID=~w,PropTypeId=~w",[Reason,RoleID,PropTypeId])
    end.
send_battle_reward_letter_2(RoleID,[Goods|_T],Num,{Order,Score}) ->
    Title = ?_LANG_WAROFKING_LETTER_TITLE,
    GoodsNames = [common_goods:get_notify_goods_name(Goods)],
    Text = common_letter:create_temp(?WAROFKING_REWARD_LETTER,[Score,Order,Num,GoodsNames]),
    common_letter:sys2p(RoleID,Text,Title,[Goods],14),
    ok.

%%判断当前副本属于哪个国家
get_fb_faction_id()->
    CurFbMapId = mgeem_map:get_mapid(),
    get_fb_faction_id(CurFbMapId).
get_fb_faction_id(CurFbMapId)->    
    {_,FbFactionId} = lists:keyfind(CurFbMapId, 1, ?WAROFKING_MAP_ID_LIST_2),
    FbFactionId.
