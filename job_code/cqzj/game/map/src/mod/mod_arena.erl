%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     战神塔
%%% @end
%%% Created : 2011-6-16
%%%-------------------------------------------------------------------
-module(mod_arena).

-include("arena.hrl").

-export([
         handle/1,
         handle/2
        ]).


-export([
         is_arena_map_id/1,
         is_arena_watcher/1,
         is_arena_fighter/1,
         is_in_arena_single_map/0,
         is_in_arena_map/0,
         check_map_fight/1,
         assert_valid_map_id/1,
         get_arena_map_name/1,
         get_map_name_to_enter/1,set_map_enter_tag/2,
         get_role_chllg_score/3,
         clear_map_enter_tag/1
        ]).

-export([
         loop/2,
         hook_role_quit/1,
         hook_role_before_quit/1,
         hook_role_enter/2,
         hook_role_dead/3,
         hook_role_relive/3
        ]).
 
%% ====================================================================
%% Macro
%% ====================================================================
-define(ARENA_MAP_INFO,arena_map_info).

-define(ARENA_WATCHER_STAT_INFO,arena_watcher_stat_info).

-define(ARENA_MAP_NAME_TO_ENTER(RoleID),{arena_map_name_to_enter,RoleID}).
-define(CURRENT_ARENA_TIMER,current_arena_timer).

-define(MAX_PARTAKE_TIMES,15).  %%每天最多参与次数

-define(CHALLENGE_MONEY_TYPE_GOLD,1).
-define(CHALLENGE_MONEY_TYPE_SILVER,2).
-define(CONFIG_NAME,arena).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).


%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).


handle({_, ?ARENA, ?ARENA_ANNOUNCE,_,_,_,_}=Info) ->
    %% 摆擂/挑擂
    do_arena_announce(Info);
handle({_, ?ARENA, ?ARENA_CHALLENGE,_,_,_,_}=Info) ->
    %% 百强挑战
    do_arena_challenge(Info);
handle({_, ?ARENA, ?ARENA_CHLLG_ANSWER,_,_,_,_}=Info) ->
    %% 对邀请挑战的应答
    do_arena_chllg_answer(Info);
handle({_, ?ARENA, ?ARENA_WATCH,_,_,_,_}=Info) ->
    %% 观看战斗
    do_arena_watch(Info);
handle({_, ?ARENA, ?ARENA_QUIT,_,_,_,_}=Info) ->
    %% 退出擂台
    do_arena_quit(Info);
handle({_, ?ARENA, ?ARENA_ASSIST,_,_,_,_}=Info) ->
    %% 辅助功能
    do_arena_assist(Info);
handle({_, ?ARENA, ?ARENA_READY_ANSWER,_,_,_,_}=Info) ->
    %% 对申请开战的回复
    do_arena_ready_answer(Info);

handle({init_arena_map_info,ArenaInfo}) ->
    do_init_arena_map_info(ArenaInfo);
handle({init_arena_challenge_info,ChallengeInfo}) ->
    put(?ARENA_CHALLENGE_INFO,ChallengeInfo);
handle({gm_set_arena_score, RoleID, Val}) ->
    do_gm_set_arena_score(RoleID,Val);
handle({gm_set_arena_partake_times, RoleID, Val}) ->
    do_gm_set_arena_partake_times(RoleID,Val);
handle({gm_set_arena_conwin_times, _RoleID, _Val}) ->
    ignore;
handle({change_arena_status,ArenaInfo}) ->
    do_change_arena_status(ArenaInfo);
handle({arena_timeout,Status}) ->
    %% 竞技场定时器的超时处理
    do_arena_timeout(Status);
handle({create_map_succ, Key}) ->
    do_create_copy_finish(Key);

handle({inner_arena_chllg_invite,ChllgID,ToChllgRoleId,MoneyType,ChllgMoney}) ->
    %%在被挑战方的地图进程中处理
    do_inner_arena_chllg_invite(ChllgID,ToChllgRoleId,MoneyType,ChllgMoney);
    %%在挑战方的地图进程中处理
handle({inner_arena_chllg_answer,Action,ChallengeInfo}) ->
    do_inner_arena_chllg_answer(Action,ChallengeInfo);

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).


assert_valid_map_id(DestMapID)->
    case is_arena_map_id(DestMapID) of
        true->
            ok;
        _ ->
            ?ERROR_MSG("严重，试图进入错误的地图,DestMapID=~w",[DestMapID]),
            throw({error,error_map_id,DestMapID})
    end.

check_map_fight(RoleID)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{type=Type,status=Status,owner_id=OwnerId,challenger_id=ChllgId}->
            if
                Status=:=?STATUS_PREPARE->
                    {error, ?_LANG_ARENA_IN_PREPARE_TIME};
                Status=/=?STATUS_FIGHT->
                    {error, ?_LANG_ARENA_IN_SAFE_TIME};
                Type =:= ?TYPE_ONE2ONE andalso (RoleID=/=OwnerId) andalso (RoleID=/=ChllgId)->
                    {error, ?_LANG_ARENA_WATCHER_NO_FIGHT};
                Type =:= ?TYPE_HERO2HERO andalso (RoleID=/=OwnerId) andalso (RoleID=/=ChllgId)->
                    {error, ?_LANG_ARENA_WATCHER_NO_FIGHT};
                true->
                    true
            end;
        _ ->
            true 
    end.

%%@doc 判断是否在竞技场地图
is_in_arena_map()->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{}->
            true;
        _ ->
            false
    end.

%%@doc 判断是否在单人的比赛擂台
is_in_arena_single_map()->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{type=Type} when Type=:=?TYPE_ONE2ONE orelse Type=:=?TYPE_HERO2HERO->
            true;
        _ ->
            false
    end.

%%@doc 是否是竞技场中的参战者
is_arena_fighter(RoleID)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{type=?TYPE_ONE2ONE,owner_id=OwnerId,challenger_id=ChllgId}->
            (RoleID=:=OwnerId) orelse (RoleID=:=ChllgId);
        #p_arena_info{type=?TYPE_HERO2HERO,owner_id=OwnerId,challenger_id=ChllgId}->
            (RoleID=:=OwnerId) orelse (RoleID=:=ChllgId);
        _ ->
            false
    end.


%%@doc 是否是单人擂台中的观众
is_arena_watcher(RoleID)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{type=?TYPE_ONE2ONE,owner_id=OwnerId,challenger_id=ChllgId} ->
            RoleID=/=OwnerId andalso RoleID=/=ChllgId;
        #p_arena_info{type=?TYPE_HERO2HERO,owner_id=OwnerId,challenger_id=ChllgId} ->
            RoleID=/=OwnerId andalso RoleID=/=ChllgId;
        _ ->
            false
    end.


is_arena_map_id(DestMapId)->
    [MapList] = ?find_config( arena_map_list),
    lists:keyfind(DestMapId,1,MapList) =/= false.

get_arena_map_name(ArenaID) ->
    lists:concat(["map_arena_", ArenaID]).

%%@doc 获取竞技场对应的地图ID
get_arena_map_id(ArenaId) ->
    [SiteList] = ?find_config( arena_site),
    get_arena_map_id_2(SiteList,ArenaId).

get_arena_map_id_2([],_ArenaId)->
    0;
get_arena_map_id_2([H|T],ArenaId)->
    {MinArenaId,MaxArenaId,_Type,MapId} = H,
    case ArenaId>=MinArenaId andalso MaxArenaId>=ArenaId of
        true->
            MapId;
        _ ->
            get_arena_map_id_2(T,ArenaId)
    end.

%%获取竞技场的死亡重生的位置
get_arena_return_pos(RoleID)->
    case db:dirty_read(?DB_ROLE_ARENA,RoleID) of
        [#r_role_arena{return_map_id=ReturnMapID,return_pos=ReturnPos}] when ReturnMapID>0 ->
            case is_valid_map_for_arena(ReturnMapID) andalso is_record(ReturnPos,p_pos) of
                true->
                    #p_pos{tx=TX,ty=TY} = ReturnPos,
                    {ReturnMapID,TX,TY};
                _ ->
                    common_map:get_map_return_pos_of_jingcheng(RoleID)
            end;
        _ ->
            %%好吧，踢回京城
            common_map:get_map_return_pos_of_jingcheng(RoleID)
    end.

is_valid_map_for_arena(MapID)->
    IsInMissionFB = mod_mission_fb:is_mission_fb_map_id(MapID),
    IsInArenaFB = is_arena_map_id(MapID),
    IsInCountryTreasure = mod_country_treasure:is_in_treasure_fb_map_id(MapID),
    if
        IsInMissionFB orelse IsInArenaFB orelse IsInCountryTreasure ->
            false;
        true->
            true
    end.


%%@doc 更新竞技场状态，给外部地图进程调用
update_arena_status(ArenaMapName,ArenaInfo) when is_list(ArenaMapName)->
    global:send(ArenaMapName, {mod, ?MODULE, {change_arena_status,ArenaInfo}}).

%%地图跳转前，获得这条友进入的竞技场地图名称
get_map_name_to_enter(RoleID)->
    get(?ARENA_MAP_NAME_TO_ENTER(RoleID)).

clear_map_enter_tag(RoleID)->
    erase(?ARENA_MAP_NAME_TO_ENTER(RoleID)).


set_map_enter_tag(RoleID,ArenaMapName)->
    put(?ARENA_MAP_NAME_TO_ENTER(RoleID),ArenaMapName).

%%@doc 更新竞技场的玩家数据到DB中！
update_role_arena_data(RoleID,ArenaId,ArenaType,PartakeType)when is_integer(ArenaId)->
    {CurMapID,CurPos} = get_curr_map_pos(RoleID),
    
    R1 = mod_arena_misc:get_role_arena_record(RoleID),
    case PartakeType of
        ?PARTTAKE_TYPE_WATCHER->
            R2 = R1#r_role_arena{arena_id=ArenaId,partake_type=PartakeType,
                                 return_map_id=CurMapID,return_pos=CurPos};
        _ ->
            Today = date(),
            case ArenaType of
                ?TYPE_ONE2ONE->
                    OldPartakeTimes = mod_arena_misc:get_arena_partake_times_today(RoleID),
                    R2 = R1#r_role_arena{arena_id=ArenaId,partake_type=PartakeType,
                                         return_map_id=CurMapID,return_pos=CurPos,
                                         partake_date=Today,partake_times=(OldPartakeTimes+1)
                                        };
                ?TYPE_HERO2HERO->
                    case PartakeType of
                        ?PARTTAKE_TYPE_OWNER->
                            BeChllgedTimes = mod_arena_misc:get_arena_be_chllged_times_today(RoleID),
                            R2 = R1#r_role_arena{arena_id=ArenaId,partake_type=PartakeType,
                                                 return_map_id=CurMapID,return_pos=CurPos,
                                                 be_chllged_date=Today,be_chllged_times=BeChllgedTimes+1
                                                };
                        ?PARTTAKE_TYPE_CHALLENGER->
                            ChllgTimes = mod_arena_misc:get_arena_chllg_times_today(RoleID),
                            R2 = R1#r_role_arena{arena_id=ArenaId,partake_type=PartakeType,
                                                 return_map_id=CurMapID,return_pos=CurPos,
                                                 chllg_date=Today,chllg_times=ChllgTimes+1
                                                }
                    end
            end
    end,
    db:dirty_write(?DB_ROLE_ARENA,R2).

%%@doc 初始化地图信息(摆擂之后调用)
do_init_arena_map_info(Info) when is_record(Info,p_arena_info)->
    do_change_arena_status(Info).

%%@doc GM命令
do_gm_set_arena_score(RoleID,MyTotalScore) when is_integer(MyTotalScore)->
    R1 = mod_arena_misc:get_role_arena_record(RoleID),
    R2 = R1#r_role_arena{total_score=MyTotalScore},
    db:dirty_write(?DB_ROLE_ARENA,R2),
    
    {ok,#p_role_attr{jingjie=Jingjie}} = mod_map_role:get_role_attr(RoleID),
    case is_integer(Jingjie) andalso Jingjie>0 of
        true->
            mod_arena_misc:update_hero_score_to_manager([{RoleID,MyTotalScore}]);
        _ ->
            %%还没闯关，忽略更新排行榜
            ignore
    end,
    ok.

do_gm_set_arena_partake_times(RoleID,Val) when is_integer(Val)->
    R1 = mod_arena_misc:get_role_arena_record(RoleID),
    R2 = R1#r_role_arena{partake_times=Val},
    db:dirty_write(?DB_ROLE_ARENA,R2).

loop(_MapId,_Now)->
    ignore.

hook_role_quit(RoleID)->
    case get(?ARENA_MAP_INFO) of
        undefined->
            ignore;
        #p_arena_info{type=?TYPE_HERO2HERO}=ArenaMapInfo->
            do_hook_role_quit_2_one(RoleID,ArenaMapInfo);
        #p_arena_info{type=?TYPE_ONE2ONE}=ArenaMapInfo->
            do_hook_role_quit_2_one(RoleID,ArenaMapInfo);
        _ ->
            ignore
    end.


do_hook_role_quit_2_one(RoleID,ArenaMapInfo)->
    case ArenaMapInfo of
        #p_arena_info{status=?STATUS_ANNOUNCE}->
            do_hook_role_quit_announce(RoleID,ArenaMapInfo);
        #p_arena_info{status=?STATUS_PREPARE}->
            do_hook_role_quit_parepare(RoleID,ArenaMapInfo);
        #p_arena_info{status=?STATUS_FIGHT}->
            do_hook_role_quit_fight(RoleID,ArenaMapInfo);
        #p_arena_info{status=?STATUS_BLANK}->
            ignore;
        #p_arena_info{status=?STATUS_FINISH}->
            do_hook_role_quit_finish(RoleID,ArenaMapInfo);
        _ ->
            ignore
    end.

%% 摆擂期间有人退出
do_hook_role_quit_announce(RoleID,CurrInfo)->
    #p_arena_info{status=?STATUS_ANNOUNCE,owner_id=OwnerId}=CurrInfo,
    if
        RoleID=:=OwnerId->
            ArenaInfo=CurrInfo#p_arena_info{status=?STATUS_FINISH,result=?RESULT_QUIT_ANNOUNCE},
            do_change_arena_status(ArenaInfo);
        true->
            ignore
    end.

%% 备战期间有人退出
do_hook_role_quit_parepare(RoleID,CurrInfo)->
    #p_arena_info{owner_id=OwnerId,challenger_id=ChllId}=CurrInfo,
    if
        RoleID=:=OwnerId->
            ArenaInfo=CurrInfo#p_arena_info{status=?STATUS_FINISH,result=?RESULT_QUIT_PREPARE_OWNER},
            do_change_arena_status(ArenaInfo);
        RoleID=:=ChllId->
            ArenaInfo=CurrInfo#p_arena_info{status=?STATUS_FINISH,result=?RESULT_QUIT_PREPARE_CHALLENGER},
            do_change_arena_status(ArenaInfo);
        true->
            ignore
    end.
%% 战斗期间有人退出
do_hook_role_quit_fight(RoleID,CurrInfo)->
    #p_arena_info{owner_id=OwnerId,challenger_id=ChllId}=CurrInfo,
    if
        RoleID=:=OwnerId->
            ArenaInfo=CurrInfo#p_arena_info{status=?STATUS_FINISH,result=?RESULT_QUIT_FIGHT_OWNER},
            do_change_arena_status(ArenaInfo);
        RoleID=:=ChllId->
            ArenaInfo=CurrInfo#p_arena_info{status=?STATUS_FINISH,result=?RESULT_QUIT_FIGHT_CHALLENGER},
            do_change_arena_status(ArenaInfo);
        true->
            ignore
    end.

%% 结束期间有人退出
do_hook_role_quit_finish(_RoleID,CurrInfo)->
    case mgeem_map:get_all_roleid() of
        []->
            %%直接清场，结束本次比赛
            #p_arena_info{id=Id}=CurrInfo,
            NewArenaInfo=#p_arena_info{id=Id,status=?STATUS_BLANK},
            do_change_arena_status(NewArenaInfo);
        _RoleIds ->
            ignore
    end.

hook_role_before_quit(RoleID)->
    do_hook_quit_for_actor(RoleID).

%%修改参与者的PK模式
do_hook_quit_for_actor(RoleID)->
    case is_arena_fighter(RoleID) of
        true->
            %%修改PK模式
            mod_role2:modify_pk_mode_for_role(RoleID,?PK_FACTION),
            ok;
        _ ->
            ignore
    end.

hook_role_enter(RoleID,_MapID)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{status=?STATUS_BLANK}->
            ignore;
        #p_arena_info{type=?TYPE_ONE2ONE}=ArenaInfo->
            hook_role_enter_2_one(RoleID,ArenaInfo);
        #p_arena_info{type=?TYPE_HERO2HERO}=ArenaInfo->
            hook_role_enter_2_one(RoleID,ArenaInfo);
        _ ->
            ignore
    end.


hook_role_enter_2_one(RoleID,ArenaInfo)->
    #p_arena_info{owner_id=OwnerId,challenger_id=ChllgId} = ArenaInfo,
    case RoleID=:=OwnerId orelse RoleID=:=ChllgId of
        true->
            %%参与者自动下马
            ShouldMountDown = true;
        _ ->
            %%记录观众次数
            ShouldMountDown = false,
            update_watcher_stat_info(RoleID)
    end,
    hook_role_enter_step_2(RoleID,ArenaInfo,ShouldMountDown).

hook_role_enter_step_2(RoleID,ArenaInfo,_ShouldMountDown)->
    case get(?ARENA_CHALLENGE_INFO)of
        #r_arena_challenge_info{money_type=MoneyType,chllg_money=ChllgMoney}->
            R2 = #m_arena_update_toc{arena_info=ArenaInfo,money_type=MoneyType,chllg_money=ChllgMoney};
        _ ->
            R2 = #m_arena_update_toc{arena_info=ArenaInfo}
    end,
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_UPDATE, R2),
    ok.

hook_role_relive(_RoleID,_RoleBase,_MapId)->
    ignore.


hook_role_dead(RoleID,_RoleMapInfo,MapID)->
    case get(?ARENA_MAP_INFO) of
        undefined->
            ignore;
        #p_arena_info{status=?STATUS_FIGHT}=ArenaMapInfo->
            hook_role_dead_2_one(RoleID,ArenaMapInfo);
        _ ->
            ?ERROR_MSG("坑爹啦，竞技场里面没有战斗，也有人挂掉！{RoleID,MapID}=~w",[{RoleID,MapID}]),
            ignore
    end.

hook_role_dead_2_one(RoleID,CurrInfo)->
    #p_arena_info{owner_id=OwnerId,challenger_id=ChllId}=CurrInfo,
    if
        RoleID=:=OwnerId->
            ArenaInfo=CurrInfo#p_arena_info{status=?STATUS_FINISH,result=?RESULT_WIN_CHALLENGER},
            do_change_arena_status(ArenaInfo);
        RoleID=:=ChllId->
            ArenaInfo=CurrInfo#p_arena_info{status=?STATUS_FINISH,result=?RESULT_WIN_OWNER},
            do_change_arena_status(ArenaInfo);
        true->
            ?ERROR_MSG("坑爹啦，观众打酱油的也会挂掉！{RoleID,CurrInfo}=~w",[{RoleID,CurrInfo}]),
            ignore
    end.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------


get_curr_map_pos(RoleID)->
    MapId = mgeem_map:get_mapid(),
    case mod_map_role:get_role_pos(RoleID) of
        {ok, Pos}->
            {MapId,Pos};
        _ ->
            {MapId,undefined}
    end.

send_to_arena_manager(Info)->
    case global:whereis_name(mod_arena_manager) of
        undefined->
            ?ERROR_MSG("严重,mod_arena_manager is down!!",[]);
        Pid->
            erlang:send(Pid,Info)
    end.

assert_inviter_state(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        undefined->
            next;
        RoleMapInfo when is_record(RoleMapInfo,p_map_role)->
            case RoleMapInfo#p_map_role.state of
                ?ROLE_STATE_NORMAL ->%%正常状态
                    next;
                ?ROLE_STATE_DEAD ->
                    ?THROW_ERR(?ERR_ARENA_INVITER_STATE_DEAD);
                ?ROLE_STATE_STALL_SELF ->
                    ?THROW_ERR(?ERR_ARENA_INVITER_STATE_IN_STALL);
                ?ROLE_STATE_STALL ->
                    ?THROW_ERR(?ERR_ARENA_INVITER_STATE_IN_STALL);
                ?ROLE_STATE_YBC_FAMILY ->
                    ?THROW_ERR(?ERR_ARENA_INVITER_STATE_IN_YBC);
                ?ROLE_STATE_COLLECT ->
                    ?THROW_ERR(?ERR_ARENA_INVITER_STATE_IN_COLLECT);
                _S->
                    next
            end
    end,
    
    case mod_horse_racing:is_role_in_horse_racing(RoleID) of
        true ->
            ?THROW_ERR(?ERR_ARENA_INVITER_STATE_IN_HORSE_RACING);
        _ ->
            ignore
    end,

    case mod_trading_common:get_role_trading(RoleID) of
        undefined->
            next;
        _ ->
            ?THROW_ERR(?ERR_ARENA_INVITER_STATE_IN_TRADING)
    end,
    ok.

assert_role_state(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        undefined->
            next;
        RoleMapInfo when is_record(RoleMapInfo,p_map_role)->
            case RoleMapInfo#p_map_role.state of
                ?ROLE_STATE_NORMAL ->%%正常状态
                    next;
                ?ROLE_STATE_DEAD ->
                    ?THROW_ERR(?ERR_ARENA_ROLE_STATE_DEAD);
                ?ROLE_STATE_STALL_SELF ->
                    ?THROW_ERR(?ERR_ARENA_ROLE_STATE_IN_STALL);
                ?ROLE_STATE_STALL ->
                    ?THROW_ERR(?ERR_ARENA_ROLE_STATE_IN_STALL);
                ?ROLE_STATE_YBC_FAMILY ->
                    ?THROW_ERR(?ERR_ARENA_ROLE_STATE_IN_YBC);
                ?ROLE_STATE_COLLECT ->
                    ?THROW_ERR(?ERR_ARENA_ROLE_STATE_IN_COLLECT);
                _S->
                    next
            end
    end,
    
    case mod_horse_racing:is_role_in_horse_racing(RoleID) of
        true ->
            ?THROW_ERR(?ERR_ARENA_ROLE_STATE_IN_HORSE_RACING);
        _ ->
            ignore
    end,
    case mod_trading_common:get_role_trading(RoleID) of
        undefined->
            next;
        _ ->
            ?THROW_ERR(?ERR_ARENA_ROLE_STATE_IN_TRADING)
    end,
    case mod_map_role:is_role_fighting(RoleID) of
        true ->
            ?THROW_ERR(?ERR_ARENA_ROLE_STATE_IN_FIGHTING);
        false ->
            next
    end,
    case mod_map_team:is_in_recuitment_state(RoleID) of
        true ->
            ?THROW_ERR(?ERR_ARENA_ROLE_STATE_IN_RECRUITMENT);
        false ->
            next
    end,
    ok.

assert_inviter_title(RoleID,Type)->
    [TitleLimitList] = ?find_config(arena_title_limit),
    {_Type,OwnerTitleLimit,_WatcherTitleLimit} = lists:keyfind(Type, 1, TitleLimitList),
    {ok,#p_role_attr{jingjie=Jingjie}} = mod_map_role:get_role_attr(RoleID),
    assert_value_limit(Jingjie,OwnerTitleLimit,?ERR_ARENA_INVITER_TITLE_LIMIT).

assert_inviter_level(RoleID,Type)->
    [LvLimitList] = ?find_config(arena_lv_limit),
    {_,OwnerLvLimit,_WatcherLvLimit} = lists:keyfind(Type, 1, LvLimitList),
    {ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    assert_value_limit(RoleLevel,OwnerLvLimit,?ERR_ARENA_INVITER_LV_LIMIT).

assert_role_title(RoleID,Type,IsWatcher)->
    [TitleLimitList] = ?find_config(arena_title_limit),
    {_Type,OwnerTitleLimit,WatcherTitleLimit} = lists:keyfind(Type, 1, TitleLimitList),
    {ok,#p_role_attr{jingjie=Jingjie}} = mod_map_role:get_role_attr(RoleID),
    case IsWatcher of
        true->
            assert_value_limit(Jingjie,WatcherTitleLimit,?ERR_ARENA_WATCH_TITLE_LIMIT);
        _ ->
            assert_value_limit(Jingjie,OwnerTitleLimit,?ERR_ARENA_ROLE_TITLE_LIMIT)
    end.

assert_role_level(RoleID,Type,IsWatcher)->
    [LvLimitList] = ?find_config(arena_lv_limit),
    {_,OwnerLvLimit,WatcherLvLimit} = lists:keyfind(Type, 1, LvLimitList),
    {ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    case IsWatcher of
        true->
            assert_value_limit(RoleLevel,WatcherLvLimit,?ERR_ARENA_WATCH_LV_LIMIT);
        _ ->
            assert_value_limit(RoleLevel,OwnerLvLimit,?ERR_ARENA_ROLE_LV_LIMIT)
    end.

assert_value_limit(RoleLv,LvLimit,ErrCode)->    
    case RoleLv>=LvLimit of
        true->
            next;
        _ ->
            ?THROW_ERR(ErrCode)
    end,
    ok.

assert_not_in_arena_map()->
    MapId = mgeem_map:get_mapid(),
    case is_arena_map_id(MapId) of
        true->
            ?THROW_ERR(?ERR_ARENA_ROLE_STATE_IN_ARENA_FB);
        _ ->
            next
    end.

-define(ARENA_CHALLENGE_ROLE_TIME,arena_challenge_role_time).
set_role_chllg_interval_time(RoleID)->
    Now = common_tool:now(),
    put({?ARENA_CHALLENGE_ROLE_TIME,RoleID},Now).
assert_role_chllg_interval(RoleID)->
    case get({?ARENA_CHALLENGE_ROLE_TIME,RoleID}) of
        undefined->
            next;
        Time ->
            Now = common_tool:now(),
            if
                Now>Time+10->
                    next;
                true->
                    ?THROW_ERR(?ERR_ARENA_CHALLENGE_ROLE_INTERVAL)
             end
    end,        
    ok.

%%副本状态下，不能参与竞技场
assert_inviter_not_in_fb_map()->
    case mgeem_map:get_state() of
        #map_state{mapid=MapID,map_type=MapType} ->
            IsInArenaFB = is_arena_map_id(MapID),
            IsInFbMap = MapType=:=?MAP_TYPE_COPY,
            IsInWarofkingFb = mod_warofking:is_fb_map_id(MapID),
            if
                IsInArenaFB ->
                    ?THROW_ERR(?ERR_ARENA_INVITER_STATE_IN_ARENA_FB);
                IsInFbMap ->
                    ?THROW_ERR(?ERR_ARENA_INVITER_STATE_IN_FB);
                IsInWarofkingFb->
                    ?THROW_ERR(?ERR_ARENA_INVITER_STATE_IN_FB);
                true->
                    next
            end;
        _ ->
            next
    end,
    ok.

%%副本状态下，不能参与竞技场
assert_role_not_in_fb_map()->
    case mgeem_map:get_state() of
        #map_state{mapid=MapID,map_type=MapType} ->
            IsInArenaFB = is_arena_map_id(MapID),
            IsInFbMap = MapType=:=?MAP_TYPE_COPY,
            IsInWarofkingFb = mod_warofking:is_fb_map_id(MapID),
            if
                IsInArenaFB ->
                    ?THROW_ERR(?ERR_ARENA_ROLE_STATE_IN_ARENA_FB);
                IsInFbMap ->
                    ?THROW_ERR(?ERR_ARENA_ROLE_STATE_IN_FB);
                IsInWarofkingFb->
                    ?THROW_ERR(?ERR_ARENA_ROLE_STATE_IN_FB);
                true->
                    next
            end;
        _ ->
            next
    end,
    ok.



assert_role_partake_times(RoleID)->
    PartakeTimes = mod_arena_misc:get_arena_partake_times_today(RoleID),
    if
        PartakeTimes>=?MAX_PARTAKE_TIMES->
            ?THROW_ERR(?ERR_ARENA_ROLE_TAKEPART_MAX_TIMES);
        true->
            next
    end,
    {ok,PartakeTimes}.


check_announce_condition(RoleID,DataIn)->
    #m_arena_announce_tos{id=ArenaId,action=ActionType} = DataIn,
    if
        ArenaId>0-> next;
        true->
            ?THROW_ERR(?ERR_INTERFACE_ERR)
    end,
    Type = get_arena_type(ArenaId),
    assert_role_level(RoleID,Type,false),
    assert_role_title(RoleID,Type,false),
    assert_role_state(RoleID),
    assert_role_not_in_fb_map(),
    assert_not_in_arena_map(),
    {ok,PartakeTimes} = assert_role_partake_times(RoleID),
    
    {ok,PartakeTimes,ActionType}.


%%更新本竞技场地图的定时器
%% 切换为指定的Status之后，需要启用的定时器
do_update_arena_timer(Status,Result)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{sub_type=SubType}->
            case get(?CURRENT_ARENA_TIMER) of
                undefined->
                    ignore;
                TimerRefOld->
                    erlang:cancel_timer(TimerRefOld)
            end,
            do_update_arena_timer_2(Status,SubType,Result);
        _->
            ?ERROR_MSG("do_change_arena_timer!!Status=~w",[Status])
    end.
do_update_arena_timer_2(?STATUS_BLANK,_SubType,_Result)->
    ignore;
do_update_arena_timer_2(Status,SubType,Result)->
    [TimeLimitList] = ?find_config(arena_time_limit),  
    case lists:keyfind({SubType,Status}, 1, TimeLimitList) of
        {_,SecondsLimit} ->
            IsResultForQuitAnnouce = (Result=:=?RESULT_QUIT_ANNOUNCE) orelse (Result=:=?RESULT_ANNOUNCE_TIMEOUT)
                                         orelse (Result=:=?RESULT_INVITE_REJECT) orelse (Result=:=?RESULT_INVITE_INVALID),
            case Status=:=?STATUS_FINISH andalso IsResultForQuitAnnouce=:=true of
                true->
                    self() ! {mod,?MODULE,{arena_timeout,Status}};
                _ ->
                    TimeAfter = SecondsLimit*1000,
                    TimerRefNew = erlang:send_after(TimeAfter,self(),{mod,?MODULE,{arena_timeout,Status}}),
                    put(?CURRENT_ARENA_TIMER,TimerRefNew)
            end;
        _Val ->
            ignore
    end.

get_status_time_limit(SubType,Status)->
    [TimeLimitList] = ?find_config(arena_time_limit),  
    case lists:keyfind({SubType,Status}, 1, TimeLimitList) of
        {_,SecondsLimit} ->
            SecondsLimit;
        _ ->
            0
    end.

%%处理竞技场的状态超时，即某个状态的持续时间已到期
do_arena_timeout(Status) when is_integer(Status)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{id=Id,status=CurrentStatus} when (CurrentStatus=:=Status)->
            do_arena_timeout_2(Id,Status);
        Val->
            %%状态非预期
            ?ERROR_MSG("do_arena_timeout error,状态非预期!!{Status,Val}=~w",[{Status,Val}])
    end.

do_arena_timeout_2(Id,?STATUS_ANNOUNCE)->
    ArenaInfo=#p_arena_info{id=Id,status=?STATUS_FINISH,result=?RESULT_ANNOUNCE_TIMEOUT},
    do_change_arena_status(ArenaInfo);
do_arena_timeout_2(Id,?STATUS_PREPARE)->
    ArenaInfo=#p_arena_info{id=Id,status=?STATUS_FIGHT},
    do_change_arena_status(ArenaInfo);
do_arena_timeout_2(Id,?STATUS_FIGHT)->
    do_arena_fight_result(),
    ArenaInfo=#p_arena_info{id=Id,status=?STATUS_FINISH,result=?RESULT_DRAW},
    do_change_arena_status(ArenaInfo);
do_arena_timeout_2(Id,?STATUS_FINISH)->
    %%开始清场，直接将地图中的所有人都踢回原处
    RoleIdList = mgeem_map:get_all_roleid(),
    lists:foreach(
      fun(RoleID)->
              R2 = #m_arena_quit_toc{type=?QUIT_TYPE_CLEAR},
              common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_QUIT, R2),
              do_arena_quit_2(RoleID,false)
      end, RoleIdList),
    ArenaInfo=#p_arena_info{id=Id,status=?STATUS_BLANK},
    do_change_arena_status(ArenaInfo).

do_arena_fight_result()->
    ok.

%%广播update的接口给本地图（竞技场地图）的人。 
broadcast_update(#p_arena_info{status=Status} = ArenaInfo)->
    broadcast_to_world(Status,ArenaInfo),
    case get(?ARENA_CHALLENGE_INFO)of
        #r_arena_challenge_info{money_type=MoneyType,chllg_money=ChllgMoney}->
            R2 = #m_arena_update_toc{arena_info=ArenaInfo,money_type=MoneyType,chllg_money=ChllgMoney};
        _ ->
            R2 = #m_arena_update_toc{arena_info=ArenaInfo}
    end,
    mgeem_map:broadcast_to_whole_map(?ARENA, ?ARENA_UPDATE, R2).

%%对世界、中央频道的广播
broadcast_to_world(?STATUS_ANNOUNCE,#p_arena_info{sub_type=?SUBTYPE_ONE2ONE}=ArenaInfo)->
    #p_arena_info{type=Type,owner_name=OwnerName,owner_faction=OwnerFaction} = ArenaInfo,
    BcMessage = common_misc:format_lang(?_LANG_ARENA_ANNOUNCE_ONE2ONE,[common_misc:get_role_name_color(OwnerName,OwnerFaction),Type] ),
    common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CENTER],?BC_MSG_TYPE_CHAT_WORLD,BcMessage),%%20级以下收到此消息不显示
    ok;
broadcast_to_world(?STATUS_ANNOUNCE,#p_arena_info{sub_type=?SUBTYPE_HERO2HERO}=ArenaInfo)->
    #p_arena_info{id=ArenaId,owner_name=OwnerName,owner_faction=OwnerFaction} = ArenaInfo,
    BcMessage = common_misc:format_lang(?_LANG_ARENA_ANNOUNCE_HERO2HERO,[common_misc:get_role_name_color(OwnerName,OwnerFaction),ArenaId] ),
    common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CENTER],?BC_MSG_TYPE_CHAT_WORLD,BcMessage),%%20级以下收到此消息不显示
    ok;
broadcast_to_world(?STATUS_PREPARE,#p_arena_info{type=?TYPE_ONE2ONE}=ArenaInfo)->
    #p_arena_info{id=ArenaId,owner_name=OwnerName,owner_faction=OwnerFaction,challenger_name=ChllgName,challenger_faction=ChllgFaction} = ArenaInfo,
    BcMessage = common_misc:format_lang(?_LANG_ARENA_PREPARE_ONE2ONE,[common_misc:get_role_name_color(ChllgName,ChllgFaction),
                                                                      common_misc:get_role_name_color(OwnerName,OwnerFaction),ArenaId] ),
    common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CENTER],?BC_MSG_TYPE_CHAT_WORLD,BcMessage),%%20级以下收到此消息不显示
    ok;
broadcast_to_world(?STATUS_PREPARE,#p_arena_info{type=?TYPE_HERO2HERO}=ArenaInfo)->
    #p_arena_info{id=ArenaId,owner_name=OwnerName,owner_faction=OwnerFaction,challenger_name=ChllgName,challenger_faction=ChllgFaction} = ArenaInfo,
    BcMessage = common_misc:format_lang(?_LANG_ARENA_PREPARE_HERO2HERO,[common_misc:get_role_name_color(ChllgName,ChllgFaction),
                                                                      common_misc:get_role_name_color(OwnerName,OwnerFaction),ArenaId] ),
    common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CENTER],?BC_MSG_TYPE_CHAT_WORLD,BcMessage),%%20级以下收到此消息不显示
    ok;
broadcast_to_world(?STATUS_FINISH,#p_arena_info{result=Result}=ArenaInfo)->
    #p_arena_info{type=Type,owner_id=OwnerId,owner_name=OwnerName,owner_faction=OwnerFaction,
                  challenger_id=ChllgId,challenger_name=ChllgName,challenger_faction=ChllgFaction} = ArenaInfo,    
    if
        Result=:=?RESULT_WIN_OWNER orelse
        Result=:=?RESULT_QUIT_FIGHT_CHALLENGER ->
            broadcast_result_to_world(Type,OwnerId,OwnerName,OwnerFaction,ChllgName,ChllgFaction);
        Result=:=?RESULT_WIN_CHALLENGER orelse
        Result=:=?RESULT_QUIT_FIGHT_OWNER ->
            broadcast_result_to_world(Type,ChllgId,ChllgName,ChllgFaction,OwnerName,OwnerFaction);
        true->
            ignore
    end;
broadcast_to_world(_,_ArenaInfo)->
    ignore.

broadcast_result_to_world(?TYPE_ONE2ONE,WinerId,WinnerName,WinnerFaction,LostName,LostFaction)->
    BcMessage = common_misc:format_lang(?_LANG_ARENA_FINISH_ONE2ONE,
                                        [common_misc:get_role_name_color(WinnerName,WinnerFaction),
                                         common_misc:get_role_name_color(LostName,LostFaction)] ),
    broadcast_result_to_world_2(BcMessage,WinerId,WinnerName,WinnerFaction);
broadcast_result_to_world(?TYPE_HERO2HERO,WinerId,WinnerName,WinnerFaction,LostName,LostFaction)->
    BcMessage = common_misc:format_lang(?_LANG_ARENA_FINISH_HERO2HERO,
                                        [common_misc:get_role_name_color(WinnerName,WinnerFaction),
                                         common_misc:get_role_name_color(LostName,LostFaction)] ),
    broadcast_result_to_world_2(BcMessage,WinerId,WinnerName,WinnerFaction).    

broadcast_result_to_world_2(BcMessage,_WinerId,_WinnerName,_WinnerFaction)->
    common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CENTER],?BC_MSG_TYPE_CHAT_WORLD,BcMessage),
    ok.

do_change_arena_status(#p_arena_info{status=Status,result=Result}=ArenaInfo)->
    Now = common_tool:now(),
    
    ?TRY_CATCH( do_change_local_arena_status(Status,Now,ArenaInfo),Err1 ),
    ?TRY_CATCH( send_to_arena_manager({change_arena_status,ArenaInfo}),Err2 ),
    ?TRY_CATCH( do_update_arena_timer(Status,Result),Err3).    


do_change_local_arena_status(?STATUS_ANNOUNCE=Status,Now,#p_arena_info{sub_type=SubType}=ChangeArenaInfo)->
    TimeLimit = get_status_time_limit(SubType,Status),
    CurrInfo2 = ChangeArenaInfo#p_arena_info{start_time=Now,change_time=Now,time_limit=TimeLimit},
    ?TRY_CATCH( broadcast_update(CurrInfo2) ),
    init_arena_dict(),

    put(?ARENA_MAP_INFO,CurrInfo2);
do_change_local_arena_status(?STATUS_PREPARE=Status,Now,#p_arena_info{id=ArenaId}=ChangeArenaInfo)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{id=ArenaId,sub_type=SubType}=CurrInfo->
            TimeLimit = get_status_time_limit(SubType,Status),
            #p_arena_info{challenger_id=ChllgerId,challenger_head=Head,challenger_faction=FactionId,challenger_team=ChllgTeam,
                          challenger_name=RoleName} = ChangeArenaInfo,
            CurrInfo2 = CurrInfo#p_arena_info{status=?STATUS_PREPARE,challenger_id=ChllgerId,
                                              challenger_head=Head,challenger_faction=FactionId,challenger_team=ChllgTeam,
                                              challenger_name=RoleName,change_time=Now,time_limit=TimeLimit},
            
            ?TRY_CATCH( broadcast_update(CurrInfo2) ),
            put(?ARENA_MAP_INFO,CurrInfo2);
        _->
            ?ERROR_MSG("change_arena_status error!!ChangeArenaInfo=~w",[ChangeArenaInfo])
    end;
do_change_local_arena_status(?STATUS_FIGHT=Status,Now,#p_arena_info{id=ArenaId}=ChangeArenaInfo)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{id=ArenaId,sub_type=SubType}=CurrInfo->
            TimeLimit = get_status_time_limit(SubType,Status),
            CurrInfo2 = CurrInfo#p_arena_info{status=Status,change_time=Now,time_limit=TimeLimit},
            ?TRY_CATCH( broadcast_update(CurrInfo2) ),
            put(?ARENA_MAP_INFO,CurrInfo2),
            ok;
        _->
            ?ERROR_MSG("change_arena_status error!!ChangeArenaInfo=~w",[ChangeArenaInfo])
    end;
do_change_local_arena_status(?STATUS_FINISH=Status,Now,#p_arena_info{id=ArenaId,result=Result}=ChangeArenaInfo)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{id=ArenaId,sub_type=SubType}=CurrInfo->
            %%当前阶段可能是摆擂阶段、备战阶段、战斗阶段
            process_arena_result(CurrInfo,Now,Result),
            TimeLimit = get_status_time_limit(SubType,Status),
            CurrInfo2 = CurrInfo#p_arena_info{status=Status,change_time=Now,time_limit=TimeLimit,result=Result},
            ?TRY_CATCH( broadcast_update(CurrInfo2) ),
            put(?ARENA_MAP_INFO,CurrInfo2),
            ok;
        _->
            ?ERROR_MSG("change_arena_status error!!ChangeArenaInfo=~w",[ChangeArenaInfo])
    end;
do_change_local_arena_status(?STATUS_BLANK,Now,#p_arena_info{id=ArenaId}=ChangeArenaInfo)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{id=ArenaId,type=Type}->
            CurrInfo2 = ChangeArenaInfo#p_arena_info{type=Type,change_time=Now,time_limit=0},
            ?TRY_CATCH( broadcast_update(CurrInfo2) ),
            put(?ARENA_MAP_INFO,CurrInfo2),
            init_arena_dict(),
            ok;
        _->
            ?ERROR_MSG("change_arena_status error!!ChangeArenaInfo=~w",[ChangeArenaInfo])
    end.

get_partake_level(OwnerId,ChallengerId)->
    {
      get_partake_level_2(OwnerId),
      get_partake_level_2(ChallengerId) 
    }.

get_partake_level_2(undefined)->
    0;
get_partake_level_2(0)->
    0;
get_partake_level_2(RoleID)->
    case mod_map_role:get_role_attr(RoleID) of
        {ok,#p_role_attr{level=RoleLevel}} ->
            RoleLevel;
        _ ->
            0
    end.

get_watcher_stat_info()->
    case get(?ARENA_WATCHER_STAT_INFO) of
        {WatchTimes,WatcherList} ->
            WatcherNum = length(WatcherList),
            {WatchTimes,WatcherNum};
        _V ->
            {0,0}
    end.

%%战斗结束，更新相应日志和积分累计
process_arena_result(CurrInfo,Now,Result)->
    #p_arena_info{id=ArenaId,status=CurrStatus,owner_id=OwnerId,owner_faction=OwnerFaction,owner_name=OwnerName,
                  challenger_id=ChallengerId,challenger_name=ChallengerName,challenger_faction=ChallengerFaction,
                  type=Type,sub_type=SubType}=CurrInfo,

    {OwnerLevel,ChllgLevel} = get_partake_level(OwnerId,ChallengerId),
    {WatchTimes,WatcherNum} = get_watcher_stat_info(),
    RecLog = #r_arena_result_log{arena_id=ArenaId,log_time=Now,type=Type,sub_type=SubType,
                                 owner_id=OwnerId,owner_name=OwnerName,owner_faction=OwnerFaction,owner_level=OwnerLevel,
                                 challenger_id=ChallengerId,challenger_name=ChallengerName,challenger_faction=ChallengerFaction,challenger_level=ChllgLevel,
                                 watcher_num=WatcherNum,watch_times=WatchTimes,result=Result},
    ?TRY_CATCH( common_general_log_server:log_arena_result(RecLog),Err1 ),
    
    case Type of
        ?TYPE_ONE2ONE->
            %%更新擂主/挑战者的积分，只有进入了战斗状态，才开始计算积分。
            case CurrStatus=:=?STATUS_FIGHT orelse CurrStatus=:=?STATUS_PREPARE of
                true->
                    ?TRY_CATCH( update_arena_one2one_score(CurrInfo,Result,{OwnerLevel,ChllgLevel}),Err2);
                _ ->
                    ignore
            end;
        ?TYPE_HERO2HERO->
            mod_arena_misc:process_arena_h2h_result(CurrInfo,Result),
            ok
    end.

update_arena_one2one_score(CurrInfo,Result,{OwnerLevel,ChllgLevel})->
    #p_arena_info{owner_id=OwnerId,challenger_id=ChllgId}=CurrInfo,
    {OwnerScore,ChallengerScore} = compute_arena_one2one_score(OwnerId,ChllgId,Result),
    
    update_role_arena_score(owner,OwnerId,OwnerLevel,ChllgId,{OwnerScore,ChallengerScore},CurrInfo,Result),
    update_role_arena_score(challenger,ChllgId,ChllgLevel,OwnerId,{ChallengerScore,OwnerScore},CurrInfo,Result),
    ok.


update_role_arena_score(PartakeType,RoleID,_RoleLevel,_ChllgId,{MyScore,OpponentScore},CurrInfo,Result) when is_atom(PartakeType)->
    #p_arena_info{id=Id}=CurrInfo,
    case db:dirty_read(?DB_ROLE_ARENA,RoleID) of
        [#r_role_arena{total_score=OldScore1}=OldRec1] ->
            MyTotalScore = (OldScore1+MyScore),
            R1 = OldRec1#r_role_arena{arena_id=Id,curr_score=MyScore,total_score=MyTotalScore},
            db:dirty_write(?DB_ROLE_ARENA,R1),
            
            ScoreInfo1 = {MyScore,OpponentScore,MyTotalScore},
            mod_arena_misc:send_role_arena_result(CurrInfo, Result, RoleID, ScoreInfo1),
            mod_arena_misc:update_hero_score_to_manager([{RoleID,MyTotalScore}]);
        _->
            ?ERROR_MSG("update_role_arena_score error,RoleID=~w",[RoleID]),
            error
    end.

%%对竞技场积分奖励的计算公式
compute_arena_one2one_score(OwnerId,ChllgId,Result) when is_integer(Result)->
    compute_arena_one2one_score_2(OwnerId, ChllgId, Result).

compute_arena_one2one_score_2(OwnerId, ChllgId, Result) ->
    {OwnerLevel,ChllgLevel} = get_partake_level(OwnerId,ChllgId),
    OwnerScore = case OwnerId=:=undefined orelse OwnerId=:= 0 of
                     true->
                         0;
                     _ ->
                         [OwnerScoreConfList] =  ?find_config(arena_score_one2one_owner),
                         compute_arena_score_3(Result,OwnerScoreConfList,(OwnerLevel-ChllgLevel))
                 end,
    ChllgScore = case ChllgId=:=undefined orelse ChllgId=:= 0 of
                     true->
                         0;
                     _ ->
                         [ChllgScoreConfList] =  ?find_config(arena_score_one2one_challenger),
                         compute_arena_score_3(Result,ChllgScoreConfList,(ChllgLevel-OwnerLevel))
                 end,
    {OwnerScore,ChllgScore}.

compute_arena_score_3(Result,ScoreConfList,LevelDiff)->
    case lists:keyfind(Result, 1, ScoreConfList) of
        {_,Score} when is_integer(Score)->
            Score;
        {_,ScoreList} when is_list(ScoreList)->
            compute_arena_score_4(ScoreList,LevelDiff);
        _ ->
            ?ERROR_MSG("error1,{Result,ScoreConfList,LevelDiff}=~w",[Result,ScoreConfList,LevelDiff]),
            0
    end.
compute_arena_score_4([],_Diff)->
    ?ERROR_MSG("error2,LevelDiff=~w",[_Diff]),
    0;
compute_arena_score_4([H|T],LevelDiff)->
    {Min,Max,Score}= H,
    case LevelDiff>=Min andalso LevelDiff=<Max of
        true->
            Score;
        _ ->
            compute_arena_score_4(T,LevelDiff)
    end.

%%@doc 根据当前所在地图，判断竞技场消费配置
get_consume_config(ArenaId)->
    Type = get_arena_type(ArenaId),
    get_consume_config_by_type(Type).
    
get_consume_config_by_type(Type)->    
    [ConsumeConfigList] = ?find_config(arena_consume),
    lists:keyfind(Type,1,ConsumeConfigList).


%%@interface 包括摆擂/挑擂
do_arena_announce({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_arena_announce_tos{id=Id,action=ActionType} = DataIn,
    case catch check_announce_condition(RoleID,DataIn) of
        {ok,PartakeTimes,ActionType}->
            case ActionType of
                ?ANNOUNCE_TYPE_OWN->
                    do_arena_announce_own_1([Unique, Module, Method, DataIn, RoleID, PID],PartakeTimes);
                ?ANNOUNCE_TYPE_CHLLG->
                    do_arena_announce_chllg_1([Unique, Module, Method, DataIn, RoleID, PID])
            end;
        {error,ErrCode,Reason}->
            send_to_arena_manager({announce_response,Id}),
            R2 = #m_arena_announce_toc{id=Id,action=ActionType,error_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

%%摆擂
do_arena_announce_own_1([Unique, Module, Method, DataIn, RoleID, PID],PartakeTimes)->
    #m_arena_announce_tos{id=Id} = DataIn,
    if
        PartakeTimes>0->
            {_,NeedSilver,_} = get_consume_config(Id);
        true->
            NeedSilver = 0
    end,
    do_arena_announce_own_2([Unique, Module, Method, DataIn, RoleID, PID],NeedSilver).

do_arena_announce_own_2([Unique, Module, Method, DataIn, RoleID, PID],NeedSilver)->
    #m_arena_announce_tos{id=Id} = DataIn,
    {ok,RoleBase} = mod_map_role:get_role_base(RoleID),
    TransFun = fun()-> 
                       mod_arena_misc:t_deduct_announce_money(RoleID,NeedSilver)
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,RoleAttr2}}->
            %%先扣钱币
            if
                NeedSilver>0->
                    common_misc:send_role_silver_change(RoleID,RoleAttr2),
                    SilverSysMsg = common_misc:format_lang(?_LANG_ARENA_ANNOUNCE_COST_MONEY, [ common_misc:format_silver(NeedSilver) ]),
                    common_broadcast:bc_send_msg_role(RoleID, [?BC_MSG_TYPE_SYSTEM], SilverSysMsg);
                true->
                    ignore
            end,
            %%跳转地图
            case do_annouce_own_enter_map(RoleID,RoleBase,Id,?SUBTYPE_ONE2ONE) of
                ok->
                    modify_arena_pk_mode(Id,RoleID),
                    ?UNICAST_TOC(#m_arena_announce_toc{id=Id});
                {error,ErrCode}->
                    send_to_arena_manager({announce_response,Id}),
                    ?UNICAST_TOC(#m_arena_announce_toc{id=Id,error_code=ErrCode})
            end;
        {aborted,{error,ErrCode,ErrReason}}-> 
            send_to_arena_manager({announce_response,Id}),
            R2 = #m_arena_announce_toc{id=Id,error_code=ErrCode,reason=ErrReason},
            ?UNICAST_TOC(R2)
    end.

%%@doc 摆擂成功，直接传入竞技场地图
do_annouce_own_enter_map(RoleID,RoleBase,ArenaId,SubType)->
    do_annouce_own_enter_map(RoleID,RoleBase,ArenaId,SubType,undefined).

do_annouce_own_enter_map(RoleID,RoleBase,ArenaId,SubType,ChallengeInfo)when is_record(RoleBase,p_role_base), is_integer(ArenaId)->
    ArenaMapName = get_arena_map_name(ArenaId),
    ArenaMapId = get_arena_map_id(ArenaId),
    CreateMapInfo = {RoleID,RoleBase,ArenaId,SubType,ArenaMapId,ArenaMapName,ChallengeInfo},
    case global:whereis_name(ArenaMapName) of
        undefined->
            %% 异步创建副本地图
            log_async_create_copy(RoleID, CreateMapInfo),
            mod_map_copy:async_create_copy(ArenaMapId, ArenaMapName, ?MODULE, RoleID),
            ok;
        _PID->
            do_annouce_own_enter_map_2(CreateMapInfo),
            ok
    end.

do_create_copy_finish(Key) ->
    case get_async_create_copy_info(Key) of
        undefined ->
            ignore;
        Info ->
            do_annouce_own_enter_map_2(Info)
    end.

log_async_create_copy(RoleID, Info) ->
    erlang:put({arena_fb_create_key, RoleID}, Info).
get_async_create_copy_info(RoleID) ->
    erlang:get({arena_fb_create_key, RoleID}).

do_annouce_own_enter_map_2({RoleID,RoleBase,ArenaId,SubType,ArenaMapId,ArenaMapName,ChallengeInfo}) when is_record(RoleBase,p_role_base)->
    #p_role_base{role_name=RoleName,head=RoleHead,faction_id=RoleFaction,team_id=RoleTeam} = RoleBase,
    
    ArenaType = get_arena_type(ArenaId),
    InitMapInfo = #p_arena_info{id=ArenaId,type=ArenaType,sub_type=SubType,status=?STATUS_ANNOUNCE,result=0,
                             owner_id=RoleID,owner_head=RoleHead,owner_faction=RoleFaction,owner_team=RoleTeam,
                             owner_name=RoleName},
    %% 初始化任务副本地图信息
    global:send(ArenaMapName, {mod, ?MODULE, {init_arena_map_info,InitMapInfo}}),
    
    %% 记录上一次的位置
    update_role_arena_data(RoleID,ArenaId,ArenaType,?PARTTAKE_TYPE_OWNER),
    
    %% 传送到竞技场
    set_map_enter_tag(RoleID,ArenaMapName),
    {_, TX, TY} = common_misc:get_born_info_by_map(ArenaMapId),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_ARENA_FB, RoleID, ArenaMapId, TX, TY),
    
    %% 如果挑战者信息不为空，则传送挑战者
    case ChallengeInfo of
        #r_arena_challenge_info{chllg_id=ChllgId}->
            global:send(ArenaMapName, {mod, ?MODULE, {init_arena_challenge_info,ChallengeInfo}}),
            %%让挑战者传入地图
            SendMsg = {inner_arena_chllg_answer,?ANSWER_ACTION_AGREE,ChallengeInfo},
            common_misc:send_to_rolemap_mod(ChllgId, ?MODULE, SendMsg),
            ok;
        _ ->
            ok
    end.

%%挑擂
do_arena_announce_chllg_1([Unique, Module, Method, DataIn, RoleID, PID])->
    #m_arena_announce_tos{id=Id,action=ActionType} = DataIn,
            {ok,RoleBase} = mod_map_role:get_role_base(RoleID),
            case do_announce_chllg_enter_map(RoleID,RoleBase,Id) of
                ok->
                    modify_arena_pk_mode(Id,RoleID),
                    ?UNICAST_TOC(#m_arena_announce_toc{id=Id,action=ActionType});
                {error,ErrCode}->
                    send_to_arena_manager({challenge_response,Id}),
                    ?UNICAST_TOC(#m_arena_announce_toc{id=Id,action=ActionType,error_code=ErrCode})
            end,
    ok.

do_announce_chllg_enter_map(RoleID,RoleBase,ArenaId) when is_integer(ArenaId)->
    ArenaMapName = get_arena_map_name(ArenaId),
    ArenaMapId = get_arena_map_id(ArenaId),
    case global:whereis_name(ArenaMapName) of
        undefined->
            {error,?ERR_ARENA_MAP_NOT_EXISTS};
        _PID->
            do_announce_chllg_enter_map_2(RoleID,RoleBase,ArenaId,ArenaMapId,ArenaMapName)
    end.

do_announce_chllg_enter_map_2(RoleID,RoleBase,ArenaId,ArenaMapId,ArenaMapName) when is_record(RoleBase,p_role_base)->
    #p_role_base{role_name=RoleName,head=RoleHead,faction_id=RoleFaction,team_id=RoleTeam} = RoleBase,
    ArenaInfo=#p_arena_info{id=ArenaId,status=?STATUS_PREPARE,challenger_id=RoleID,
                            challenger_head=RoleHead, challenger_faction=RoleFaction,challenger_team=RoleTeam,
                            challenger_name=RoleName},
    %% 改变副本状态
    update_arena_status(ArenaMapName,ArenaInfo),

    %% 记录上一次的位置
    ArenaType = get_arena_type(ArenaId),
    update_role_arena_data(RoleID,ArenaId,ArenaType,?PARTTAKE_TYPE_CHALLENGER),

    %% 传送到竞技场
    set_map_enter_tag(RoleID,ArenaMapName),
    {_, TX, TY} = common_misc:get_born_info_by_map(ArenaMapId),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_ARENA_FB, RoleID, ArenaMapId, TX, TY),
    ok.



%%@interface 指名挑战
do_arena_challenge({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_arena_challenge_tos{role_id=ToChllgRoleId,money_type=MoneyType,chllg_money=ChllgMoney} = DataIn,
    case catch check_challenge_condition(RoleID,DataIn) of
        ok->
            TransFun = fun()->
                               mod_arena_misc:t_deduct_challenge_money(RoleID,MoneyType,ChllgMoney)
                       end,
            case common_transaction:t( TransFun ) of
                {atomic,{ok,RoleAttr2}}->
                    mod_arena_misc:send_role_chllg_money_change(MoneyType,RoleID,RoleAttr2),
                    %%一定要先扣钱，之后再返回
                    set_role_chllg_interval_time(RoleID),
                    SendMsg = {inner_arena_chllg_invite,RoleID,ToChllgRoleId,MoneyType,ChllgMoney},
                    common_misc:send_to_rolemap_mod(ToChllgRoleId, ?MODULE, SendMsg),
                    ?UNICAST_TOC(#m_arena_challenge_toc{role_id=ToChllgRoleId,action=0});
                {aborted,{error,ErrCode,Reason}}->
                    ?UNICAST_TOC(#m_arena_challenge_toc{role_id=ToChllgRoleId,error_code=ErrCode,reason=Reason})
            end;
        {error,ErrCode,Reason}->
            ?UNICAST_TOC(#m_arena_challenge_toc{role_id=ToChllgRoleId,error_code=ErrCode,reason=Reason})
    end.


%%@doc 从被挑战者身上获取挑战积分
get_role_chllg_score(ToChllgRoleId,MoneyType,ChllgMoney)->
    TotalScore = mod_arena_misc:get_arena_total_score(ToChllgRoleId),
    get_chllg_score(MoneyType,ChllgMoney,TotalScore).

%%获取挑战积分积分的规则
get_chllg_score(?CHALLENGE_MONEY_TYPE_GOLD,ChllgMoney,TotalScore) when ChllgMoney>=50 ->
    %%每增加1元宝，可多获得对方1%的积分
    MinScore = TotalScore div 5,
    MaxScore = TotalScore div 2,
    RealScore1 = TotalScore*(ChllgMoney-50) div 100 + MinScore,
    if RealScore1>MaxScore -> MaxScore;true-> RealScore1 end;
get_chllg_score(?CHALLENGE_MONEY_TYPE_SILVER,ChllgMoney,TotalScore) when ChllgMoney>=50000->
    %%每增加1金，可多获得对方2%的积分
    MinScore = TotalScore div 5,
    MaxScore = TotalScore div 2,
    RealScore1 = TotalScore*(ChllgMoney-50000) div 500000 + MinScore,
    if RealScore1>MaxScore -> MaxScore;true-> RealScore1 end;
get_chllg_score(_,_,_) ->
    0.

check_challenge_condition(RoleID,DataIn)->
    #m_arena_challenge_tos{role_id=ToChllgRoleId,money_type=MoneyType,chllg_money=ChllgMoney} = DataIn,
    if
        ChllgMoney=<0->
            ?THROW_ERR(?ERR_ARENA_CHALLENGE_CHLLG_MONEY_LESS_THAN_ZERO);
        MoneyType =:=?CHALLENGE_MONEY_TYPE_GOLD andalso ChllgMoney<50->
            ?THROW_ERR(?ERR_ARENA_CHALLENGE_CHLLG_GOLD_LESS_THAN_50);
        MoneyType =:=?CHALLENGE_MONEY_TYPE_SILVER andalso ChllgMoney<50000->
            ?THROW_ERR(?ERR_ARENA_CHALLENGE_CHLLG_SILVER_LESS_THAN_5);
        true->
            next
    end,
    Type = ?TYPE_HERO2HERO,
    assert_role_level(RoleID,Type,false),
    assert_role_title(RoleID,Type,false),
    assert_role_state(RoleID),
    assert_role_not_in_fb_map(),
    assert_not_in_arena_map(),
    assert_role_chllg_interval(RoleID),
    
    %%检查对手是否在线
    case common_misc:is_role_online(ToChllgRoleId) of
        true->
            next;
        _ ->
            ?THROW_ERR( ?ERR_ARENA_CHALLENGE_ROLE_NOT_ONLINE )
    end,
    
    %%检查玩家的金额是否足够
    case MoneyType of
        ?CHALLENGE_MONEY_TYPE_SILVER->
            case common_bag2:check_money_enough(silver_any, ChllgMoney, RoleID) of
                true->
                    next;
                _ ->
                    ?THROW_ERR(?ERR_ARENA_CHALLENGE_CHLLG_SILVER_NOT_ENOUGH)
            end;
        ?CHALLENGE_MONEY_TYPE_GOLD->
            case common_bag2:check_money_enough(gold_unbind, ChllgMoney, RoleID) of
                true->
                    next;
                _ ->
                    ?THROW_ERR(?ERR_ARENA_CHALLENGE_CHLLG_GOLD_NOT_ENOUGH)
            end
    end,
    %%检查挑战次数、被挑战次数
    case mod_arena_misc:get_arena_chllg_times_today(RoleID)>=10 of
        true->
            ?THROW_ERR(?ERR_ARENA_CHALLENGE_CHLLG_TIMES_OVER_MAX);
        _ ->
            next
    end,
    case mod_arena_misc:get_arena_be_chllged_times_today(ToChllgRoleId)>=5 of
        true->
            ?THROW_ERR(?ERR_ARENA_CHALLENGE_BE_CHLLGED_TIMES_OVER_MAX);
        _ ->
            next
    end,
    ok.

%%@interface 对邀请挑战的应答
%%@param ChallengeAnswerInfo 
%%      注意，这个是由mod_arena_manger传递的数据
do_arena_chllg_answer({Unique, Module, Method, DataIn, RoleID, PID, ChallengeAnswerInfo})->
    #m_arena_chllg_answer_tos{chllg_id=ChllgId,action=Action} = DataIn,
    {ArenaId,MoneyType,ChllgMoney} = ChallengeAnswerInfo,
    
    ChllgScore = get_role_chllg_score(RoleID,MoneyType,ChllgMoney),
    ChallengeInfo = #r_arena_challenge_info{arena_id=ArenaId,owner_id=RoleID,chllg_id=ChllgId,money_type=MoneyType,
                                            chllg_money=ChllgMoney,chllg_score=ChllgScore},
    update_arena_chllg_status(RoleID,0),
    case Action of
        ?ANSWER_ACTION_AGREE->
            case catch check_answer_condition(RoleID,DataIn) of
                ok->
                    %%B被挑战方，作为擂主传入地图
                    {ok,RoleBase} = mod_map_role:get_role_base(RoleID),
                    case do_annouce_own_enter_map(RoleID,RoleBase,ArenaId,?SUBTYPE_HERO2HERO,ChallengeInfo) of
                        ok->
                            modify_arena_pk_mode(ArenaId,RoleID),
                            ?UNICAST_TOC(#m_arena_chllg_answer_toc{chllg_id=ChllgId});
                        {error,ErrCode}->
                            ?UNICAST_TOC(#m_arena_chllg_answer_toc{chllg_id=ChllgId,error_code=ErrCode})
                    end;
                {error,ErrCode,Reason}->
                    ?UNICAST_TOC(#m_arena_chllg_answer_toc{chllg_id=ChllgId,error_code=ErrCode,reason=Reason})
            end;
        ?ANSWER_ACTION_REJECT->
            %% 选择拒绝，B被挑战方扣除全部挑战积分，获得50%的金额。
            GainMoney = (ChllgMoney div 2),
            TransFun = fun()->
                               mod_arena_misc:t_gain_challenge_money(RoleID,MoneyType,GainMoney)
                       end,
            case common_transaction:t( TransFun ) of
                {atomic,{ok,RoleAttr2}}->
                    mod_arena_misc:send_role_chllg_money_change(MoneyType,RoleID,RoleAttr2),
                    
                    case db:dirty_read(?DB_ROLE_ARENA,RoleID) of
                        [#r_role_arena{total_score=OldScore}=OldArenaRec] when OldScore>1 ->
                            DeductScore = ChllgScore,
                            NewScore = (OldScore-DeductScore),
                            db:dirty_write(?DB_ROLE_ARENA,OldArenaRec#r_role_arena{total_score=NewScore}),
                            mod_arena_misc:update_hero_score_to_manager([{RoleID,NewScore}]),
                            ok;
                        _->     
                            DeductScore = 0,
                            ignore
                    end,
                    
                    SendMsg = {inner_arena_chllg_answer,Action,ChallengeInfo},
                    common_misc:send_to_rolemap_mod(ChllgId, ?MODULE, SendMsg),
                    ChllgResult = #p_arena_chllg_result{chllg_score=(-DeductScore),money_type=MoneyType,chllg_money=GainMoney},
                    ?UNICAST_TOC(#m_arena_chllg_answer_toc{chllg_id=ChllgId,action=Action,chllg_result=ChllgResult});
                {aborted,{error,ErrCode,Reason}}->
                    ?UNICAST_TOC(#m_arena_chllg_answer_toc{chllg_id=ChllgId,action=Action,error_code=ErrCode,reason=Reason})
            end;
        ?ANSWER_ACTION_GIVEUP->
            %% 选择放弃，B被挑战方被系统扣除2%的积分
            case db:dirty_read(?DB_ROLE_ARENA,RoleID) of
                [#r_role_arena{total_score=OldScore}=OldArenaRec] when OldScore>1 ->
                    DeductScore = if 
                                      ChllgScore>50-> ChllgScore div 50;
                                      true-> 1
                                  end,
                    NewScore = (OldScore-DeductScore),
                    db:dirty_write(?DB_ROLE_ARENA,OldArenaRec#r_role_arena{total_score=NewScore}),
                    mod_arena_misc:update_hero_score_to_manager([{RoleID,NewScore}]),
                    ok;
                _->     
                    DeductScore = 0,
                    ignore
            end,
            
            SendMsg = {inner_arena_chllg_answer,Action,ChallengeInfo},
            common_misc:send_to_rolemap_mod(ChllgId, ?MODULE, SendMsg),
            ChllgResult = #p_arena_chllg_result{chllg_score=(-DeductScore)},
            ?UNICAST_TOC(#m_arena_chllg_answer_toc{chllg_id=ChllgId,action=Action,chllg_result=ChllgResult})
    end.

%%@doc 更新标记被挑战者的状态
%%@param Status： 0=正常，1=被挑战中
update_arena_chllg_status(RoleID,Status) when is_integer(Status)->
    TransFun = fun()-> 
                       {ok,RoleMapExt1} = mod_map_role:get_role_map_ext_info(RoleID),
                       RoleMapExt2=RoleMapExt1#r_role_map_ext{arena_chllg_status=Status},
                       mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt2)        
               end,
    case common_transaction:t( TransFun ) of
        {atomic,_ } ->
            ok;
        {aborted, AbortErr} ->
            ?ERROR_MSG("AbortErr=~w",[AbortErr])
    end,
    ok.


%%@param ChllgID 挑战者
%%@param ToChllgRoleId 被挑战者
do_inner_arena_chllg_invite(ChllgId,ToChllgRoleId,MoneyType,ChllgMoney)->
    case catch check_inner_arena_chllg_invite(ToChllgRoleId) of
        ok->
            %%修改被挑战次数
            Today = date(),
            BeChllgedTimes = mod_arena_misc:get_arena_be_chllged_times_today(ToChllgRoleId),
            OldArenaRec = mod_arena_misc:get_role_arena_record(ToChllgRoleId),
            db:dirty_write(?DB_ROLE_ARENA,OldArenaRec#r_role_arena{
                                    be_chllged_date=Today,be_chllged_times=BeChllgedTimes+1}),
            %%标记当前正在被百强挑战
            update_arena_chllg_status(ToChllgRoleId,1),
            
            ChllgScore = get_role_chllg_score(ToChllgRoleId,MoneyType,ChllgMoney),
            R2 = #m_arena_chllg_invite_toc{chllg_id=ChllgId,money_type=MoneyType,
                                           chllg_money=ChllgMoney,chllg_score=ChllgScore},
            common_misc:unicast({role, ToChllgRoleId}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_CHLLG_INVITE, R2);
        {error,ErrCode,Reason}->
            %%需要给挑战方返回挑战金额
            ChallengeInfo = #r_arena_challenge_info{owner_id=ToChllgRoleId,chllg_id=ChllgId,money_type=MoneyType,
                                                    chllg_money=ChllgMoney},
            SendMsg = {inner_arena_chllg_answer,?ANSWER_ACTION_SYS_CHECK,ChallengeInfo},
            common_misc:send_to_rolemap_mod(ChllgId, ?MODULE, SendMsg),

            R2 = #m_arena_challenge_toc{role_id=ChllgId,error_code=ErrCode,reason=Reason},
            common_misc:unicast({role, ChllgId}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_CHALLENGE, R2)
    end.

do_inner_arena_chllg_answer(?ANSWER_ACTION_SYS_CHECK=Action,ChallengeInfo)->
    %%系统检查不符合条件
    #r_arena_challenge_info{chllg_id=ChllgId,money_type=MoneyType,chllg_money=ChllgMoney} = ChallengeInfo,
    TransFun = fun()->
                       ReturnChllgMoney = ChllgMoney,
                       mod_arena_misc:t_gain_challenge_money(ChllgId,MoneyType,ReturnChllgMoney)
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,RoleAttr2}}->
            mod_arena_misc:send_role_chllg_money_change(MoneyType,ChllgId,RoleAttr2),
            ok;
        {aborted,{error,ErrCode,Reason}}->
            R2 = #m_arena_challenge_toc{role_id=ChllgId,action=Action,error_code=ErrCode,reason=Reason},
            common_misc:unicast({role, ChllgId}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_CHALLENGE, R2)
    end,
    ok;
do_inner_arena_chllg_answer(?ANSWER_ACTION_REJECT=Action,ChallengeInfo)->
    %%拒绝——A挑战方，返回50%的金额，获得全部挑战积分
    #r_arena_challenge_info{owner_id=ToChllgId,chllg_id=ChllgId,money_type=MoneyType,chllg_money=ChllgMoney,chllg_score=ChllgScore} = ChallengeInfo,
    ChllgMoney2 = ChllgMoney div 2,
    TransFun = fun()->
                       mod_arena_misc:t_gain_challenge_money(ChllgId,MoneyType,ChllgMoney2)
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,RoleAttr2}}->
            mod_arena_misc:send_role_chllg_money_change(MoneyType,ChllgId,RoleAttr2),
            
            %%修改挑战次数
            Today = date(),
            #r_role_arena{total_score=OldScore} = OldArenaRec = mod_arena_misc:get_role_arena_record(ChllgId),
            ChllgTimes = mod_arena_misc:get_arena_chllg_times_today(ChllgId),
            NewScore = OldScore+ChllgScore,
            db:dirty_write(?DB_ROLE_ARENA,OldArenaRec#r_role_arena{chllg_date=Today,
                                                                   total_score=NewScore,
                                                                   chllg_times=ChllgTimes+1}),
            mod_arena_misc:update_hero_score_to_manager([{ChllgId,NewScore}]),
            
            %%将奖罚结果提示A挑战方
            ChllgResult = #p_arena_chllg_result{money_type=MoneyType,chllg_money=(-ChllgMoney2),chllg_score=ChllgScore},
            R2 = #m_arena_challenge_toc{role_id=ToChllgId,action=Action,chllg_result=ChllgResult},
            common_misc:unicast({role, ChllgId}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_CHALLENGE, R2);
        {aborted,{error,ErrCode,Reason}}->
            R2 = #m_arena_challenge_toc{role_id=ChllgId,action=Action,error_code=ErrCode,reason=Reason},
            common_misc:unicast({role, ChllgId}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_CHALLENGE, R2)
    end,
    ok;
do_inner_arena_chllg_answer(?ANSWER_ACTION_GIVEUP=Action,ChallengeInfo)->
    %%放弃——A挑战方，被系统扣除1%的钱（即返回99%的钱）
    #r_arena_challenge_info{owner_id=ToChllgId,chllg_id=ChllgId,money_type=MoneyType,
                            chllg_money=ChllgMoney} = ChallengeInfo,
    if 
        ChllgMoney<100 -> DeductMoney = 1;
        true->
            DeductMoney = ChllgMoney div 100
    end,
    TransFun = fun()->
                       ReturnChllgMoney = ChllgMoney-DeductMoney,
                       mod_arena_misc:t_gain_challenge_money(ChllgId,MoneyType,ReturnChllgMoney)
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,RoleAttr2}}->
            mod_arena_misc:send_role_chllg_money_change(MoneyType,ChllgId,RoleAttr2),
            
            %%修改挑战次数
            Today = date(),
            OldArenaRec = mod_arena_misc:get_role_arena_record(ChllgId),
            ChllgTimes = mod_arena_misc:get_arena_chllg_times_today(ChllgId),
            db:dirty_write(?DB_ROLE_ARENA,OldArenaRec#r_role_arena{chllg_date=Today,
                                                                   chllg_times=ChllgTimes+1}),
            
            %%将奖罚结果提示A挑战方
            ChllgResult = #p_arena_chllg_result{money_type=MoneyType,chllg_money=(-DeductMoney),chllg_score=0},
            R2 = #m_arena_challenge_toc{role_id=ToChllgId,action=Action,chllg_result=ChllgResult},
            common_misc:unicast({role, ChllgId}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_CHALLENGE, R2);
        {aborted,{error,ErrCode,Reason}}->
            R2 = #m_arena_challenge_toc{role_id=ChllgId,action=Action,error_code=ErrCode,reason=Reason},
            common_misc:unicast({role, ChllgId}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_CHALLENGE, R2)
    end,
    ok;

%%被挑战者应答成功后，对挑战方的处理
do_inner_arena_chllg_answer(?ANSWER_ACTION_AGREE=Action,ChallengeInfo)->
    #r_arena_challenge_info{arena_id=ArenaId,owner_id=ToChllgId,chllg_id=ChllgId} = ChallengeInfo,
    %%将回应结果提示A挑战方
    R2 = #m_arena_challenge_toc{role_id=ToChllgId,action=Action},
    common_misc:unicast({role, ChllgId}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_CHALLENGE, R2),
    
    %%作为挑战者传入地图
    case mod_map_role:get_role_base(ChllgId) of
        {ok,RoleBase}->
            case do_announce_chllg_enter_map(ChllgId,RoleBase,ArenaId) of
                ok->
                    %%修改挑战次数
                    Today = date(),
                    OldArenaRec = mod_arena_misc:get_role_arena_record(ChllgId),
                    ChllgTimes = mod_arena_misc:get_arena_chllg_times_today(ChllgId),
                    db:dirty_write(?DB_ROLE_ARENA,OldArenaRec#r_role_arena{chllg_date=Today,
                                                                           chllg_times=ChllgTimes+1}),
                    
                    modify_arena_pk_mode(ArenaId,ChllgId),
                    ok;
                {error,ErrCode}->
                    ?ERROR_MSG("ErrCode=~w",[ErrCode])
            end;
        _ ->
            ignore
    end.

check_inner_arena_chllg_invite(ToChllgRoleId)->
    Type = ?TYPE_HERO2HERO,
    assert_inviter_level(ToChllgRoleId,Type),
    assert_inviter_title(ToChllgRoleId,Type),
    assert_inviter_state(ToChllgRoleId),
    assert_inviter_not_in_fb_map(),

    %%检查被挑战次数
    case mod_arena_misc:get_arena_be_chllged_times_today(ToChllgRoleId)>=5 of
        true->
            ?THROW_ERR(?ERR_ARENA_CHALLENGE_BE_CHLLGED_TIMES_OVER_MAX);
        _ ->
            next
    end,
    ok.
    

%%应答失败，则改变此擂台的状态
%% update_arena_status_after_answer_error(Id,Result)->
%%     %%改变副本状态
%%     ArenaInfo = #p_arena_info{id=Id,status=?STATUS_FINISH,result=Result},
%%     update_arena_status( get_arena_map_name(Id) ,ArenaInfo).

check_answer_condition(RoleID,_DataIn)->
    assert_role_state(RoleID),
    assert_role_not_in_fb_map(),
    assert_role_level(RoleID,?TYPE_HERO2HERO,false),
    assert_role_title(RoleID,?TYPE_HERO2HERO,false),
    assert_role_partake_times(RoleID),
    ok.

%%@interface 观战
do_arena_watch({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_arena_watch_tos{id=Id} = DataIn,
    case catch check_watch_condition(RoleID,DataIn) of
        ok->
            case do_watch_enter_map(RoleID,Id) of
                ok->
                    ?UNICAST_TOC(#m_arena_watch_toc{id=Id});
                {error,ErrCode}->
                    ?UNICAST_TOC(#m_arena_watch_toc{id=Id,error_code=ErrCode})
            end;
        {error,ErrCode,Reason}->
            ?UNICAST_TOC(#m_arena_watch_toc{id=Id,error_code=ErrCode,reason=Reason})
    end.


check_watch_condition(RoleID,DataIn)->
    #m_arena_watch_tos{id=Id} = DataIn,
    case get_arena_type(Id) of
        ?TYPE_ONE2ONE->
            next;
        ?TYPE_HERO2HERO->
            next;
        _ ->
            ?THROW_ERR(?ERR_ARENA_WATCH_TYPE_LIMIT)
    end,
    Type = get_arena_type(Id),
    assert_role_state(RoleID),
    assert_role_not_in_fb_map(),
    assert_role_level(RoleID,Type,true),
    assert_role_title(RoleID,Type,true),
    ok.

%%观众进入竞技场
do_watch_enter_map(RoleID,ArenaId) when is_integer(ArenaId)->
    ArenaMapName = get_arena_map_name(ArenaId),
    ArenaMapId = get_arena_map_id(ArenaId),
    case global:whereis_name(ArenaMapName) of
        undefined->
            {error,?ERR_ARENA_MAP_NOT_EXISTS};
        _PID->
            do_watch_enter_map_2(RoleID,ArenaId,ArenaMapId,ArenaMapName)
    end.

do_watch_enter_map_2(RoleID,ArenaId,ArenaMapId,ArenaMapName)->
    %% 传送到新地图，不同国家有不同的地点
    {ok,#p_role_base{faction_id=FactionId}} = mod_map_role:get_role_base(RoleID),
    [BornPointList] = ?find_config({arena_transfer, ArenaMapId}),

    %% 记录上一次的位置
    ArenaType = get_arena_type(ArenaId),
    update_role_arena_data(RoleID,ArenaId,ArenaType,?PARTTAKE_TYPE_WATCHER),

    %% 传送到竞技场
    set_map_enter_tag(RoleID,ArenaMapName),
    {_FactionId,{TX,TY}} = lists:keyfind(FactionId,1,BornPointList),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_ARENA_FB, RoleID, ArenaMapId, TX, TY),
    ok.

%%更新观众统计信息
update_watcher_stat_info(RoleID)->
    case get(?ARENA_WATCHER_STAT_INFO) of
        {WatchTimes,RoleList}->
            List1 = lists:delete(RoleID, RoleList),
            D2 = {WatchTimes+1,[RoleID|List1]},
            put(?ARENA_WATCHER_STAT_INFO,D2);
        _ ->
            D2 = {1,[RoleID]},
            put(?ARENA_WATCHER_STAT_INFO,D2)
    end.


%%@interface 退出
do_arena_quit({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    case catch check_quit_condition(RoleID) of
        ok->
            #m_arena_quit_tos{type=QuitType}= DataIn,
            case QuitType of
                ?QUIT_TYPE_RELIVE->
                    do_arena_quit_2(RoleID,true);
                _->
                    do_arena_quit_2(RoleID,false)
            end,
            ?UNICAST_TOC(#m_arena_quit_toc{type=QuitType});
        {error,ErrCode,Reason}->
            ?UNICAST_TOC(#m_arena_quit_toc{error_code=ErrCode,reason=Reason})
    end.

%%直接踢回原处，包括复活
do_arena_quit_2(RoleID,true)->
    do_hook_quit_for_actor(RoleID),
    mod_role2:relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, RoleID, ?RELIVE_TYPE_HOME_FREE_FULL);
do_arena_quit_2(RoleID,_IsRelive)->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{state=?ROLE_STATE_DEAD}->%%死亡状态
            do_arena_quit_2(RoleID,true);
        _ ->
            do_hook_quit_for_actor(RoleID),
            {DestMapId,TX,TY} = get_arena_return_pos(RoleID),
            mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapId, TX, TY)
    end.

check_quit_condition(_RoleID)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{}->
            next;
        _->
            ?THROW_ERR( ?ERR_ARENA_ROLE_NOT_IN_MAP )
    end,
    ok.


%%@interface 辅助功能
do_arena_assist({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_arena_assist_tos{action=Action} = DataIn,
    if
        Action=:=?ASSIST_ACTION_ADD_HP->
            do_arena_assist_addhp(Action,Unique, Module, Method, RoleID, PID);
        Action=:=?ASSIST_ACTION_REQ_READY->
            do_arena_assist_ready(Action,Unique, Module, Method, RoleID, PID);
        true->
            R2 = #m_arena_assist_toc{action=Action,error_code=?ERR_INTERFACE_ERR},
            ?UNICAST_TOC(R2)
    end.

%%补血补蓝
do_arena_assist_addhp(Action,Unique, Module, Method, RoleID, PID)->    
    case catch check_assist_addhp_condition(RoleID) of
        ok->
            {_,_,NeedSilver} = get_consume_config( get_arena_id_in_map() ),
            TransFun = fun()-> 
                               mod_arena_misc:t_deduct_addhp_money(RoleID,NeedSilver)
                       end,
            case common_transaction:t( TransFun ) of
                {atomic,{ok,RoleAttr2}}->
                    add_full_hp_mp(RoleID),
                    common_misc:send_role_silver_change(RoleID,RoleAttr2),
                    ?UNICAST_TOC( #m_arena_assist_toc{action=Action} );
                {aborted,{error,{common_error, ErrStr},_ErrReason}}-> 
                    common_misc:send_common_error(RoleID, 0, ErrStr);
                {aborted,{error,ErrCode,ErrReason}}-> 
                    R2 = #m_arena_assist_toc{error_code=ErrCode,reason=ErrReason},
                    ?UNICAST_TOC(R2)
            end;
        {error,ErrCode,Reason}->
            ?UNICAST_TOC(#m_arena_assist_toc{action=Action,error_code=ErrCode,reason=Reason})
    end.

%%申请提前开战
do_arena_assist_ready(Action,Unique, Module, Method, RoleID, PID)->    
    case catch check_assist_ready_condition(RoleID) of
        ok->
            case get(?ARENA_MAP_INFO) of
                #p_arena_info{owner_id=OwnerId,challenger_id=ChllgId} = ArenaInfo->
                    case RoleID of
                        OwnerId->
                            ReadyType = ?PARTTAKE_TYPE_OWNER;
                        ChllgId->
                            ReadyType = ?PARTTAKE_TYPE_CHALLENGER
                    end,
                    do_arena_assist_ready_one(ReadyType,ArenaInfo);
                _ ->
                    error
            end,
            ?UNICAST_TOC( #m_arena_assist_toc{action=Action} );
        {error,ErrCode,Reason}->
            ?UNICAST_TOC(#m_arena_assist_toc{action=Action,error_code=ErrCode,reason=Reason})
    end.

do_arena_assist_ready_one(ReadyType,ArenaInfo)->
    #p_arena_info{id=Id,type=Type,owner_id=OwnerId,owner_faction=OwnerFaction,owner_name=OwnerName,
                  challenger_id=ChllgId,challenger_faction=ChllgFaction,challenger_name=ChllgName} = ArenaInfo,
    R1=#m_arena_ready_invite_toc{id=Id,type=Type},

    case ReadyType of
        ?PARTTAKE_TYPE_OWNER->
            R2 = R1#m_arena_ready_invite_toc{ready_type=ReadyType,ready_id=OwnerId,
                                            ready_faction=OwnerFaction,ready_name=OwnerName},
            common_misc:unicast({role, ChllgId}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_READY_INVITE, R2);
        ?PARTTAKE_TYPE_CHALLENGER->
            R2 = R1#m_arena_ready_invite_toc{ready_type=ReadyType,ready_id=ChllgId,
                                            ready_faction=ChllgFaction,ready_name=ChllgName},
            common_misc:unicast({role, OwnerId}, ?DEFAULT_UNIQUE, ?ARENA, ?ARENA_READY_INVITE, R2)
    end.


%%@doc 获取当前地图中的竞技场ID
get_arena_id_in_map()->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{id=Id}->
            Id;
        _->
            undefined
    end.

check_assist_addhp_condition(_RoleID)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{status=Status}->
            if
                Status =:= ?STATUS_FIGHT ->
                    ?THROW_ERR(?ERR_ARENA_ASSIST_WHILE_FIGHT);
                true->
                    next
            end;
        _->
            ?THROW_ERR(?ERR_ARENA_ROLE_NOT_IN_MAP)
    end,
    ok.

check_assist_ready_condition(RoleID)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{status=Status,owner_id=OwnerId,challenger_id=ChallengerId}->
            if
                Status =:= ?STATUS_FIGHT ->
                    ?THROW_ERR(?ERR_ARENA_READY_STATE_IN_FIGHT);
                Status =/= ?STATUS_PREPARE ->
                    ?THROW_ERR(?ERR_ARENA_READY_STATE_ERROR);
                is_integer(OwnerId) andalso is_integer(ChallengerId) andalso OwnerId>0 andalso ChallengerId>0 ->
                    if
                        (RoleID =/= OwnerId andalso RoleID =/=ChallengerId)->
                            ?THROW_ERR(?ERR_ARENA_READY_ONLY_LEADER);
                        true->
                            next
                    end;
                true->
                    ?THROW_SYS_ERR()
            end;
        _->
            ?THROW_ERR(?ERR_ARENA_ROLE_NOT_IN_MAP)
    end,
    ok.

%%@interface 对申请开战的回复
do_arena_ready_answer({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_arena_ready_answer_tos{id=Id,action=Action} =DataIn,
    case Action of
        ?ANSWER_ACTION_AGREE->
            case catch check_ready_answer_condition(RoleID) of
                ok->
                    ArenaInfo=#p_arena_info{id=Id,status=?STATUS_FIGHT},
                    do_change_arena_status(ArenaInfo);
                {error,ErrCode,Reason}->
                    ?UNICAST_TOC(#m_arena_ready_answer_toc{id=Id,error_code=ErrCode,reason=Reason})
            end;
        ?ANSWER_ACTION_REJECT->
            %%直接忽视
            ?UNICAST_TOC(#m_arena_ready_answer_toc{id=Id})
    end.

check_ready_answer_condition(RoleID)->
    case get(?ARENA_MAP_INFO) of
        #p_arena_info{status=Status,owner_id=OwnerId,challenger_id=ChallengerId}->
            if
                Status =:= ?STATUS_FIGHT ->
                    ?THROW_ERR(?ERR_ARENA_READY_STATE_IN_FIGHT);
                Status =/= ?STATUS_PREPARE ->
                    ?THROW_ERR(?ERR_ARENA_READY_STATE_ERROR);
                is_integer(OwnerId) andalso is_integer(ChallengerId) andalso OwnerId>0 andalso ChallengerId>0 ->
                    if
                        (RoleID =:= OwnerId) orelse (RoleID =:=ChallengerId)->
                            next;
                        true->
                            ?THROW_ERR(?ERR_ARENA_WATCHER_REQ_READY)
                    end;
                true->
                    ?THROW_SYS_ERR()
            end;
        _->
            ?THROW_ERR(?ERR_ARENA_ROLE_NOT_IN_MAP)
    end,
    ok.


%% --------------------------------------------------------------------
%%  内部的二级API
%% --------------------------------------------------------------------


%%@doc 事务外的补血补蓝
add_full_hp_mp(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{max_hp=MaxHp,max_mp=MaxMp}->
            mod_map_role:do_role_add_hp(RoleID, MaxHp, RoleID),
            mod_map_role:do_role_add_mp(RoleID, MaxMp, RoleID),
            ok;
        _ ->
            ignore
    end.




%%修改PK模式
modify_arena_pk_mode(_Id,RoleID)->
    mod_role2:modify_pk_mode_for_role(RoleID,?PK_ALL).


init_arena_dict()->
    erase(?ARENA_WATCHER_STAT_INFO),
    ok.


get_arena_type(Id)->
    mod_arena_misc:get_arena_type(Id).
