%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     金矿之战
%%% @end
%%% Created : 2012-5-18
%%%-------------------------------------------------------------------
-module(mod_mine_fb).

-include("mgeem.hrl").
-export([
         handle/1,
         handle/2
        ]).
 

-export([
         init_miner_maps/0,
         after_fight/4,
		 mirror_fb_stop/1,
         init/2,
         loop/2,
         hook_role_enter/2,
         hook_role_quit/1
        ]).
-export([
         is_in_fb_map/0,
         is_fb_map_id/1,
         assert_valid_map_id/1,
         get_map_name_to_enter/1,set_map_enter_tag/2,
         clear_map_enter_tag/1]).

 
%% ====================================================================
%% Macro
%% ====================================================================
%% 英雄副本地图信息
-define(MINE_FB_MAP_NAME_TO_ENTER(RoleID),{mine_fb_map_name_to_enter,RoleID}).
-define(MINE_FB_MAP_ID,10510).
-define(MINE_FB_MAP_INFO,mine_fb_map_info).
-define(MINE_FB_MINER_DATA_LIST,mine_fb_miner_data_list).
-record(r_mine_fb_map_info,{place_id=0,doll_list=[]}).


-define(DIG_TYPE_START,1).
-define(DIG_TYPE_END,2).

-define(STATUS_NONE,0).
-define(STATUS_DIGING,1).

-define(PK_STATUS_NONE,0).
-define(PK_STATUS_FIGHTING,1).

%%战斗结果：1=胜利，2=失败
-define(FIGHT_RESULT_WIN,1). 
-define(FIGHT_RESULT_FAIL,2).

%%1=更新累计钱币,2=挖矿结束时间的提前通知,3=更新矿工的加成比率
-define(NOTIFY_TYPE_ACCSILVER,1).
-define(NOTIFY_TYPE_TIMEOUT,2).
-define(NOTIFY_TYPE_ADDRATE,3).

-define(OPERATE_TYPE_RENEWAL,2). %%续期
%% 计算采矿积分的列表
-define(INTERVAL_MINE_CALC_LIST, interval_mine_calc_list).
-define(CALC_MINE_INTERVAL, 60).    %%每分钟进行钱币产出的计算
-define(PERSISTENT_FB_DATA_INTERVAL, 55).    %%每55秒进行持久化矿工数据,默认值55
-define(MINE_FB_PERSISTENT_REM_FLAG, mine_fb_persistent_rem_flag).     


-define(CONFIG_NAME,mine_fb).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).



%%错误码
-define(ERR_MINE_FB_ENTER_FB_LIMIT,113001). %%亲，在副本中不能进入金矿之战
-define(ERR_MINE_FB_ENTER_LEVEL_LIMIT,113002). %%亲，只等级不够不能进入金矿之战
-define(ERR_MINE_FB_ENTER_STATE_DEAD,113003).   %%亲，死亡状态下无法进入金矿之战
-define(ERR_MINE_FB_ENTER_STATE_STALL,113004).  %%亲，摆摊状态下无法进入金矿之战
-define(ERR_MINE_FB_ENTER_STATE_DAZEN,113005).  %%亲，打坐状态下无法进入金矿之战
-define(ERR_MINE_FB_ENTER_STATE_TRAINING,113006).   %%亲，训练状态下无法进入金矿之战
-define(ERR_MINE_FB_ENTER_STATE_COLLECT,113007).    %%亲，采集状态下无法进入金矿之战
-define(ERR_MINE_FB_ENTER_STATE_HORSE_RACING,113008).   %%亲，正在钦点美人无法进入金矿之战
-define(ERR_MINE_FB_ENTER_STATE_FIGHTING,113009).   %%亲，PK状态下无法进入金矿之战

-define(ERR_MINE_FB_DIG_END_CD_TIME,113010).    %%抱歉，只有开矿1小时后才能停止挖矿
-define(ERR_MINE_FB_DIG_END_HAS_NOT_STARTED,113011). %%抱歉，您还尚未开矿，无法结束挖矿
-define(ERR_MINE_FB_DIG_START_HAS_STARED,113012). %%抱歉，您已经在挖矿中，不需要重复开矿
-define(ERR_MINE_FB_DIG_END_NO_MINER_DATA,113013). %%抱歉，本矿山中并没有您的矿工，无法结束挖矿
-define(ERR_MINE_FB_DIG_SILVER_NOT_ENOUGH,113014). %%抱歉，您的钱币不足，无法进行开矿
-define(ERR_MINE_FB_DIG_GOLD_NOT_ENOUGH,113015). %%抱歉，您的元宝不足，无法进行开矿
-define(ERR_MINE_FB_DIG_START_NO_SPACE,113016). %%抱歉，该位置已经被使用，不能进行挖矿
-define(ERR_MINE_FB_DIG_START_IN_OTHER_PLACE,113017). %%抱歉，您正在其他矿山挖矿中，不能重复挖矿
-define(ERR_MINE_FB_DIG_START_NOT_IN_PLACE,113018). %%抱歉，只能在矿山中才能进行挖矿
-define(ERR_MINE_FB_DIG_START_MAX_DOLL,113019). %%抱歉，该矿山的矿工已满，请选择其他矿区开矿


-define(ERR_MINE_FB_BLESS_MAX_TIMES,113020). %%亲，您的祝福次数已达到今天的最大次数
-define(ERR_MINE_FB_BLESS_MY_SELF,113021). %%亲，不能对自己进行祝福
-define(ERR_MINE_FB_BLESS_NO_MINER_DATA,113022). %%抱歉，该矿工已经不存在，无法进行祝福
-define(ERR_MINE_FB_BLESS_MAX_ADDRATE,113023). %%抱歉，对方已经达到最高的加成比率限制，不能再进行祝福

-define(ERR_MINE_FB_DISTURB_MAX_TIMES,113024). %%亲，您的干扰次数已达到今天的最大次数
-define(ERR_MINE_FB_DISTURB_MY_SELF,113025). %%亲，不能对自己进行干扰
-define(ERR_MINE_FB_DISTURB_MIN_ADDRATE,113026). %%抱歉，对方已经达到最低的加成比率限制，不能再进行干扰

-define(ERR_MINE_FB_GRAB_MY_SELF,113027). %%亲，不能对自己进行掠夺
-define(ERR_MINE_FB_GRAB_NO_MINER_DATA,113028). %%抱歉，该矿工已经不存在，无法进行掠夺
-define(ERR_MINE_FB_GRAB_MAX_TIMES,113029). %%亲，您的掠夺次数已达到今天的最大次数
-define(ERR_MINE_FB_GRAB_IS_FIGHTING,113030). %%抱歉，该矿工正处于PK状态，无法进行掠夺

-define(ERR_MINE_FB_GRAB_HARVEST_CD_TIMES,113031). %%抱歉，对方处于收获冷却期，无法进行掠夺
-define(ERR_MINE_FB_GRAB_GRAB_CD_TIMES,113032). %%抱歉，对方处于掠夺冷却期，无法进行掠夺

-define(ERR_MINE_FB_HARVEST_IN_CD_TIME,113033). %%还在冷却中，暂时不能进行收获
-define(ERR_MINE_FB_HARVEST_NO_MINER_DATA,113034). %%亲，必须在挖矿后才能进行收获

-define(ERR_MINE_FB_TIME_HOUR_IS_INVALID,113035). %%抱歉，开矿的时间参数是非法的
-define(ERR_MINE_FB_VIEW_NO_MINER_DATA,113036). %%抱歉，该矿工已经不存在，无法进行查看


-define(ERR_MINE_FB_RENEWAL_NO_MINER_DATA,113038). %%亲，必须在开矿后才能进行续期
-define(ERR_MINE_FB_RENEWAL_CD_TIME,113039). %%抱歉，只有在矿工剩余时间小于1小时才能进行续期

-define(ERR_MINE_FB_BE_BLESSED_MAX_TIMES,113040). %%抱歉，该矿工今日已被祝福5次，不能再进行祝福
-define(ERR_MINE_FB_BE_DISTURBED_MAX_TIMES,113041). %%抱歉，该矿工今日已被干扰5次，不能再进行干扰






%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).


handle({_, ?MINE_FB, ?MINE_FB_ENTER,_,_,_,_}=Info) ->
    do_mine_fb_enter(Info);
handle({_, ?MINE_FB, ?MINE_FB_QUIT,_,_,_,_}=Info) ->
    do_mine_fb_quit(Info);
handle({_, ?MINE_FB, ?MINE_FB_DIG,_,_,_,_}=Info) ->
    do_mine_fb_dig(Info); 
handle({_, ?MINE_FB, ?MINE_FB_VIEW,_,_,_,_}=Info) ->
    do_mine_fb_view(Info); 
handle({_, ?MINE_FB, ?MINE_FB_GRAB,_,_,_,_}=Info) ->
    do_mine_fb_grab(Info); 
handle({_, ?MINE_FB, ?MINE_FB_BLESS,_,_,_,_}=Info) ->
    do_mine_fb_bless(Info); 
handle({_, ?MINE_FB, ?MINE_FB_DISTURB,_,_,_,_}=Info) ->
    do_mine_fb_disturb(Info); 
handle({_, ?MINE_FB, ?MINE_FB_HARVEST,_,_,_,_}=Info) ->
    do_mine_fb_harvest(Info); 
handle({_, ?MINE_FB, ?MINE_FB_OPERATE,_,_,_,_}=Info) ->
    do_mine_fb_operate(Info); 

handle({do_persistent_fb_data}) ->
    do_persistent_fb_data();
handle({init_mine_fb_map_info, CreateMapInfo}) ->
    do_init_mine_fb_map_info(CreateMapInfo);
handle({create_map_succ, Key}) ->
    do_create_copy_finish(Key);
handle({do_after_fight,RoleID,MirrorID,MirrorTab,IsRoleWin}) ->
    do_after_fight(RoleID,MirrorID,MirrorTab,IsRoleWin);
handle({do_mirror_fb_stop,RoleID,MirrorInfo}) ->
    do_mirror_fb_stop(RoleID,MirrorInfo);
handle({grab_silver_after_fight,RoleID, MirrorRoleID,Silver}) ->
    grab_silver_after_fight(RoleID, MirrorRoleID, Silver);



handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

init(MapId, MapName) ->
    case is_fb_map_id(MapId) of
        true->
            [MaxPlaceID] = ?find_config(max_place_id),
            PlaceIdList = lists:seq(1, MaxPlaceID),
            PlaceIdMapList = [ {get_mine_fb_map_name(PlaceID),PlaceID}||PlaceID<-PlaceIdList ],
            {_,ThePlaceID} = lists:keyfind(MapName, 1, PlaceIdMapList),
            
            case catch gen_server:call({global, mod_mine_fb_manager}, {get_place_miner_list, ThePlaceID},100000) of
                {ok,MinerDataList} ->
                    init_miner_list(ThePlaceID,MinerDataList);
                _ ->
                    ignore
            end,
            erlang:send_after(?PERSISTENT_FB_DATA_INTERVAL*1000, self(), {mod,?MODULE,{do_persistent_fb_data}});
        _ ->
            ignore
    end.


loop(_MapId,NowSeconds) ->
    case is_in_fb_map() of
        true->
            loop_2(NowSeconds);
        _ ->
            ignore
    end.
loop_2(NowSeconds)->
    %%处理采矿结束
    do_calc_mine_interval(NowSeconds),
    
    case get(?MINE_FB_MINER_DATA_LIST) of
        undefined->
            ignore;
        MinerList->
            [MinerTimeoutNotify] = ?find_config(miner_timeout_notify),
            [ judge_miner_timeout(MinerData,NowSeconds,MinerTimeoutNotify)||MinerData<-MinerList ],
            ok
    end.

do_persistent_fb_data()->
     erlang:send_after(?PERSISTENT_FB_DATA_INTERVAL*1000, self(), {mod,?MODULE,{do_persistent_fb_data}}),
     
     case get(?MINE_FB_MINER_DATA_LIST)of
        undefined->
            ignore;
        List->
            PersistentRemFlag = get_persistent_rem_flag(),
            StoreList = [ MinerData||#r_miner_data{role_id=RoleID}=MinerData<-List, (RoleID rem 10)=:=PersistentRemFlag ],
            do_persitent_data(write,StoreList),
            ok
    end.

 
get_map_name_to_enter(RoleID)->
    get(?MINE_FB_MAP_NAME_TO_ENTER(RoleID)).

clear_map_enter_tag(RoleID)->
    erase(?MINE_FB_MAP_NAME_TO_ENTER(RoleID)).

%% @doc 获取副本地图进程名
get_mine_fb_map_name(PlaceID) when is_integer(PlaceID) ->
    lists:concat(["mine_fb_map_", PlaceID]).

init_miner_maps()->
    [MaxPlaceID] = ?find_config(max_place_id),
    PlaceIdList = lists:seq(1, MaxPlaceID),
    [ create_fb_map(PlaceID) ||PlaceID<-PlaceIdList ],  
    ok.

create_fb_map(PlaceID)->
    FbMapName = get_mine_fb_map_name(PlaceID),
    case mod_map_copy:create_copy(?MINE_FB_MAP_ID, FbMapName) of
        {ok, _MapPID}->
            next;
        _ ->
            ?ERROR_MSG("create_fb_map error,PlaceID=~w",[PlaceID])
    end.

set_map_enter_tag(RoleID,ArenaMapName)->
    put(?MINE_FB_MAP_NAME_TO_ENTER(RoleID),ArenaMapName).

do_create_copy_finish(Key) ->
    case get_async_create_copy_info(Key) of
        undefined ->
            ignore;
        Info ->
            do_mine_fb_enter_2(Info,true)
    end.

assert_valid_map_id(DestMapID)->
    case is_fb_map_id(DestMapID) of
        true->
            ok;
        _ ->
            ?ERROR_MSG("严重，试图进入错误的地图,DestMapID=~w",[DestMapID]),
            throw({error,error_map_id,DestMapID})
    end.


%%@doc 是否在晶矿副本中
is_in_fb_map() ->
    case get_mine_fb_map_info() of
        FbMapInfo when is_record(FbMapInfo,r_mine_fb_map_info)->
            true;
        _R ->
            false
    end.

%%@doc 副本地图结束
mirror_fb_stop(RoleID) ->
	ToRoleID = erase({?MODULE, to_role_id}),
	FromMapID = erase({?MODULE, from_map_id}),
	FromMapName = erase({?MODULE, from_map_name}),
	case global:whereis_name(FromMapName) of
		undefined->
			?ERROR_MSG("mirror_fb_stop1 error,RoleID=~w,FromMapID=~w,FromMapName=~w",[RoleID,FromMapID,FromMapName]);
		FromMapPID->
			FromMapPID ! {mod,?MODULE,{do_mirror_fb_stop,RoleID,ToRoleID}}
	end.

%%@doc 战斗结束的处理
after_fight(RoleID, MirrorID, MirrorTab, IsRoleWin) ->
    case get({from_where, RoleID}) of
        {FromMapID, FromMapName, _Pos}->
            case global:whereis_name(FromMapName) of
                undefined->
                    ?ERROR_MSG("after_fight1 error,RoleID=~w,FromMapID=~w,FromMapName=~w",[RoleID,FromMapID,FromMapName]);
                FromMapPID->
                    FromMapPID ! {mod,?MODULE,{do_after_fight,RoleID,MirrorID,MirrorTab,IsRoleWin}}
            end;
        Where ->
            ?ERROR_MSG("after_fight2 error,RoleID=~w,MirrorInfo=~w,Where=~w",[RoleID,MirrorTab,Where])
    end.

do_mirror_fb_stop(RoleID, MirrorRoleID)->
    case get_miner_data(MirrorRoleID) of 
        {ok,MinerData}->
            %%修改PK状态
            case MinerData of
                #r_miner_data{pk_status=?PK_STATUS_NONE}->
                    ignore;
                _ ->
                    NewMinerData = MinerData#r_miner_data{pk_status=?PK_STATUS_NONE},
                    set_miner_data(MirrorRoleID,NewMinerData)
            end;
        _ ->
            ?ERROR_MSG("do_mirror_fb_stop eror,RoleID=~w",[RoleID])
    end.

do_after_fight(RoleID, MirrorID, MirrorTab, IsRoleWin) ->
	MirrorRoleID = abs(MirrorID),
    [#p_role_base{role_name=MirrorRoleName}] = ets:lookup(MirrorTab, p_role_base),
    
    Result = if IsRoleWin -> ?FIGHT_RESULT_WIN; true-> ?FIGHT_RESULT_FAIL end,
    
    case IsRoleWin of
        true->
            Result = ?FIGHT_RESULT_WIN,
            {ok,Silver} = deduct_mine_silver_after_fight(MirrorRoleID),
            case mod_map_role:get_role_base(RoleID) of
                {ok,_}->
                    grab_silver_after_fight(RoleID,MirrorRoleID,Silver);
                _ ->
                    %%可能在其他地图
                    mgeer_role:send(RoleID, {mod,?MODULE,{grab_silver_after_fight, RoleID, MirrorRoleID,Silver}})
            end;
        _ ->
            Result = ?FIGHT_RESULT_FAIL,
            Silver = 0,
            case get_miner_data(MirrorRoleID) of 
                {ok,MinerData}->
                    %%修改PK状态
                    NewMinerData = MinerData#r_miner_data{pk_status=?PK_STATUS_NONE},
                    set_miner_data(MirrorRoleID,NewMinerData);
                _ ->
                    ?ERROR_MSG("get_miner_data none",[])
            end
    end,
    R2 = #m_mine_fb_battle_toc{result=Result,silver=Silver,opponent_id=MirrorRoleID,opponent_name=MirrorRoleName},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MINE_FB, ?MINE_FB_BATTLE, R2),
	mod_mirror:handle(unsummon, mgeem_map:get_state()),    
	ets:delete(MirrorTab),
	ok.


%%战斗结束后获得钱币
grab_silver_after_fight(RoleID, MirrorRoleID, GrabSilver) when GrabSilver>0->
    MoneyType = silver_bind,
    ConsumeLogType = ?GAIN_TYPE_SILVER_MINE_FB_HARVEST,
    TransFun = fun()-> 
                       common_bag2:t_gain_money(MoneyType, GrabSilver, RoleID, ConsumeLogType)
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,RoleAttr2}} ->
            common_misc:send_role_silver_change(RoleID,RoleAttr2),
            
            #p_role_attr{role_name=RoleName} = RoleAttr2,
            send_miner_grab_title(MirrorRoleID,RoleName,GrabSilver),
            ok;
        {aborted, AbortErr}->
            ?ERROR_MSG("AbortErr=~w",[AbortErr])
    end.

%%战斗结束后扣除矿产
deduct_mine_silver_after_fight(MirrorRoleID)->
    case get_miner_data(MirrorRoleID) of 
        {ok,MinerData}->
            #r_miner_data{acc_silver=AccSilver} = MinerData,
            GrabSilver = AccSilver*40 div 100,
            ResumeSilver = AccSilver-GrabSilver,
            NewMinerData = MinerData#r_miner_data{acc_silver=ResumeSilver,pk_status=?PK_STATUS_NONE},
            set_miner_data(MirrorRoleID,NewMinerData),
            
            notify_miner_silver_update(MirrorRoleID,ResumeSilver),
            {ok,GrabSilver};
        _ ->
            {error,not_found}
    end.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%%@interface 进入矿山地图
do_mine_fb_enter({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_mine_fb_enter_tos{place_id=PlaceID} = DataIn,
    case catch check_do_mine_fb_enter(RoleID,DataIn) of
        {ok,FbMapID,FbMapName}->
            CreateMapInfo = {RoleID,PlaceID,FbMapID,FbMapName},
            case global:whereis_name(FbMapName) of
                undefined->
                    %% 异步创建副本地图
                    log_async_create_copy(RoleID, CreateMapInfo),
                    mod_map_copy:async_create_copy(FbMapID, FbMapName, ?MODULE, RoleID),
                    ok;
                _PID->
                    do_mine_fb_enter_2(CreateMapInfo,false)
            end,
            R2 = #m_mine_fb_enter_toc{place_id=PlaceID};
        {error,ErrCode,Reason}->
            R2 = #m_mine_fb_enter_toc{place_id=PlaceID,err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

do_mine_fb_enter_2(CreateMapInfo,IsInit)->
    {RoleID,_PlaceID,FbMapID,FbMapName} = CreateMapInfo,
    %% 设置地图传送标志
    set_map_enter_tag(RoleID,FbMapName),
    if
        IsInit =:= true->
            global:send(FbMapName, {mod,?MODULE, {init_mine_fb_map_info, CreateMapInfo}});
        true->
            next
    end,
    
    CurMapID = mgeem_map:get_mapid(),
    case is_in_fb_map() of
        true-> 
            ignore;
        _ ->
            case mod_map_actor:get_actor_pos(RoleID, role) of
                undefined->
                    ignore;
                Pos->
                    case get_role_mine_fb_info(RoleID) of
                        {ok,RoleMineFbInfo}->
                            NewInfo = RoleMineFbInfo#r_role_mine_fb{enter_pos = Pos ,enter_mapid = CurMapID},
                            set_role_mine_fb_info(RoleID, NewInfo);
                        _ ->
                            ignore
                    end
            end
    end,
    
    case common_misc:get_born_info_by_map(FbMapID) of
        {_, TX, TY} -> 
            next;
        _ ->
            {TX,TY} = {3,20}
    end,
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, FbMapID, TX, TY),
    ok.

check_do_mine_fb_enter(RoleID,DataIn)->
    #m_mine_fb_enter_tos{place_id=PlaceID} = DataIn,
    [MaxPlaceID] = ?find_config(max_place_id),
    if
        is_integer(PlaceID) andalso PlaceID>0 andalso PlaceID=<MaxPlaceID->
            next;
        true->
            ?THROW_SYS_ERR()
    end,
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    assert_role_level(RoleAttr),
    assert_role_state(RoleID),
    
    #map_state{map_type=MapType} = mgeem_map:get_state(),
    
    if
        MapType=:=?MAP_TYPE_COPY->
            ?THROW_ERR( ?ERR_MINE_FB_ENTER_FB_LIMIT );
        true->
            next
    end,
    
    FbMapName = get_mine_fb_map_name(PlaceID),
    FbMapID = ?MINE_FB_MAP_ID,
    {ok,FbMapID,FbMapName}.

assert_role_state(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        undefined->
            next;
        RoleMapInfo when is_record(RoleMapInfo,p_map_role)->
            case RoleMapInfo#p_map_role.state of
                ?ROLE_STATE_NORMAL ->%%正常状态
                    next;
                ?ROLE_STATE_DEAD ->
                    ?THROW_ERR( ?ERR_MINE_FB_ENTER_STATE_DEAD );
                ?ROLE_STATE_STALL_SELF ->
                    ?THROW_ERR( ?ERR_MINE_FB_ENTER_STATE_STALL );
                ?ROLE_STATE_COLLECT ->
                    ?THROW_ERR( ?ERR_MINE_FB_ENTER_STATE_COLLECT );
                _->
                    next
            end
    end,
    case mod_horse_racing:is_role_in_horse_racing(RoleID) of
        true ->
            ?THROW_ERR( ?ERR_MINE_FB_ENTER_STATE_HORSE_RACING );
        _ ->
            ignore
    end,
    case mod_map_role:is_role_fighting(RoleID) of
        true ->
            ?THROW_ERR( ?ERR_MINE_FB_ENTER_STATE_FIGHTING );
        false -> next
    end,
    case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
        true ->
            ?THROW_ERR(?ERR_OTHER_ERR, ?_LANG_XIANNVSONGTAO_MSG);
        false -> ignore
    end,
    ok.

%%@interface 退出矿山地图
do_mine_fb_quit({Unique, Module, Method, _DataIn, RoleID, PID, _Line})->
    case catch check_do_mine_fb_quit(RoleID) of
        ok->
            case get_role_mine_fb_info(RoleID) of
                {ok,#r_role_mine_fb{enter_pos=EnterPos,enter_mapid=EnterMapID}} when is_integer(EnterMapID) andalso EnterMapID>0
                  andalso is_record(EnterPos,p_pos)->
                    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, EnterMapID, EnterPos#p_pos.tx, EnterPos#p_pos.ty);
                _R2->
                    {DestMapId,TX,TY} = get_mine_fb_return_pos(RoleID),
                    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapId, TX, TY)
            end,
            R2 = #m_mine_fb_quit_toc{};
        {error,ErrCode,Reason}->
            R2 = #m_mine_fb_quit_toc{err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

check_do_mine_fb_quit(_RoleID)->
    ok.


%%@interface 采矿（包括开始/停止）
do_mine_fb_dig({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_mine_fb_dig_tos{dig_type=DigType} = DataIn,
    case catch check_do_mine_fb_dig(DigType,RoleID,DataIn) of
        {ok,?DIG_TYPE_START,RoleName,RolePos,MoneyType,DeductMoney}->
            case catch do_mine_fb_dig_start(RoleID,RoleName,RolePos,DataIn,MoneyType,DeductMoney) of
                {ok,MinerInfo}->
					mod_access_guide:hook({mine_fb,RoleID}),
                    R2 = #m_mine_fb_dig_toc{dig_type=DigType,return_self=true,role_id=RoleID,miner_info=MinerInfo,deduct_silver=DeductMoney},
                    ?UNICAST_TOC(R2);
                {common_error, ErrorCode, ErrorStr} -> 
                    common_misc:send_common_error(RoleID, ErrorCode, ErrorStr);
                {error,ErrCode,Reason}->
                    R2 = #m_mine_fb_dig_toc{dig_type=DigType,return_self=true,err_code=ErrCode,reason=Reason},
                    ?UNICAST_TOC(R2)
            end;
        {ok,?DIG_TYPE_END,PlaceID,HarvestSilver}->
            case catch do_mine_fb_dig_end(RoleID,PlaceID,HarvestSilver,false) of
                ok->
                    R2 = #m_mine_fb_dig_toc{dig_type=DigType,return_self=true,role_id=RoleID,harvest_silver=HarvestSilver};
                {error,ErrCode,Reason}->
                    R2 = #m_mine_fb_dig_toc{dig_type=DigType,return_self=true,err_code=ErrCode,reason=Reason}
            end,
            ?UNICAST_TOC(R2);
        {error,ErrCode,Reason}->
            R2 = #m_mine_fb_dig_toc{dig_type=DigType,return_self=true,err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

%%  开始采矿
do_mine_fb_dig_start(RoleID,RoleName,RolePos,DataIn,MoneyType,DeductMoney)->
    #m_mine_fb_dig_tos{miner_level=MinerLevel,time_hour=TimeHour} = DataIn,
    
    TransFun = fun()-> 
                       t_mine_fb_dig_start(RoleID,MoneyType,DeductMoney,TimeHour)
               end,
    case common_transaction:t( TransFun ) of
        {atomic, {ok,RoleAttr2,PlaceID,StartTime,EndTime}} ->
            %%保存矿工数据
            HarvestCdTime = get_harvest_cd_time(RoleID),
            #p_role_attr{role_name=RoleName,level=RoleLevel,jingjie=RoleJingjie,category=RoleCategory} = RoleAttr2,
            [MinerAddRateList] = ?find_config(miner_add_rate_list),
            case lists:keyfind(MinerLevel, 1, MinerAddRateList) of
                {MinerLevel,AdditionRate,_,_}->
                    next;
                false->
                    AdditionRate=0
            end,
            
            NextHarvestTime = StartTime+HarvestCdTime,
            MinerData = #r_miner_data{status=?STATUS_DIGING, addition_rate=AdditionRate,
                                      role_id=RoleID,miner_place_id=PlaceID,miner_level=MinerLevel,
                                      role_name=RoleName,role_level=RoleLevel,role_jingjie=RoleJingjie,
                                      role_category=RoleCategory,role_pos=RolePos,
                                      start_dig_time=StartTime,end_dig_time=EndTime,
                                      last_harvest_time=0,acc_silver=0,next_harvest_time=NextHarvestTime},
            set_miner_data(RoleID,MinerData),
            do_persitent_data(write,MinerData),
            
            %%标记玩家的矿山ID
            case get_role_mine_fb_info(RoleID) of
                {ok,RoleMineFbInfo} ->
                    NewRoleMineFbInfo = RoleMineFbInfo#r_role_mine_fb{place_id=PlaceID},
                    set_role_mine_fb_info(RoleID, NewRoleMineFbInfo);
                _ ->
                    ignore
            end,
            
            do_fb_minner_log(RoleID,?DIG_TYPE_START),
            
            %%加入到定时计算列表中
            insert_interval_calc_list(RoleID),
            
            common_misc:send_role_silver_change(RoleID,RoleAttr2),
            
            %%发送到Manager
            MinerDigInfo = #r_miner_dig_info{role_id=RoleID,place_id=PlaceID,miner_level=MinerLevel},
            send_fb_manager( {dig_start,MinerDigInfo} ),
            
            {ok,NewMinerInfo} = handle_mine_fb_dig_sure(RoleID,RoleName,RolePos,MinerLevel),
            hook_miner_info_2(RoleID,PlaceID,MinerData),
            {ok,NewMinerInfo};
        {aborted, {error, ErrorCode, ErrorStr}} ->
            {common_error, ErrorCode, ErrorStr};
        {aborted, AbortErr} ->
            parse_aborted_err(AbortErr)
    end.


t_mine_fb_dig_start(RoleID,MoneyType,DeductMoney,TimeHour)->
    common_bag2:check_money_enough_and_throw(MoneyType,DeductMoney,RoleID),

    #r_mine_fb_map_info{place_id=PlaceID} = get_mine_fb_map_info(),
    [Secs3600] = ?find_config(dig_hour_to_seconds),
    StartTime = common_tool:now(),
    EndTime = StartTime+TimeHour*Secs3600,
    {ok,RoleAttr2} = t_deduct_fb_dig_money(RoleID,MoneyType,DeductMoney),
    
    {ok,RoleAttr2,PlaceID,StartTime,EndTime}.

check_do_mine_fb_dig(?DIG_TYPE_START,RoleID,DataIn)->
    #m_mine_fb_dig_tos{miner_level=MinerLevel,time_hour=TimeHour} = DataIn,
   
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        #p_map_role{pos=#p_pos{tx=TX, ty=TY}=RolePos} ->
            next;
        undefined ->
            RolePos=TX=TY=null,
            ?THROW_SYS_ERR()
    end,
    
    {MoneyType,DeductMoney} = get_dig_cost_money(MinerLevel,TimeHour),
    
    %%检查能否摆摊，包括检查周围空间
    case check_space_around(TX, TY) of
        true->
            next;
        _ ->
            ?THROW_ERR(?ERR_MINE_FB_DIG_START_NO_SPACE)
    end,   
    case get_mine_fb_map_info() of
        #r_mine_fb_map_info{place_id=CurPlaceID,doll_list=DollList}->
            [MaxMinerNum] = ?find_config(max_miner_num),
            if
                length(DollList)>=MaxMinerNum->
                    ?THROW_ERR(?ERR_MINE_FB_DIG_START_MAX_DOLL);
                true->
                    next
            end;
        _ ->
            CurPlaceID=null,
            ?THROW_ERR(?ERR_MINE_FB_DIG_START_NOT_IN_PLACE)
    end,
    
    %%检查是否已经正在采矿
    case get_miner_data(RoleID) of
        {error,not_found}->
            next;
        {ok,_MinerData}->
            ?THROW_ERR(?ERR_MINE_FB_DIG_START_HAS_STARED)
    end,
    %%检查玩家副本数据
    case get_role_mine_fb_info(RoleID) of
        {ok,#r_role_mine_fb{place_id=0}} ->
            next;
        {ok,#r_role_mine_fb{place_id=TmpId}} when is_integer(TmpId) andalso CurPlaceID=/=TmpId->
            ?THROW_ERR(?ERR_MINE_FB_DIG_START_IN_OTHER_PLACE);
        _ ->
            next
    end,
    case mod_map_role:get_role_base(RoleID) of
        {ok,#p_role_base{role_name=RoleName}}->
            next;
        _ ->
            RoleName = null,
            ?THROW_SYS_ERR()
    end,
    {ok,?DIG_TYPE_START,RoleName,RolePos,MoneyType,DeductMoney};
check_do_mine_fb_dig(?DIG_TYPE_END,RoleID,_DataIn)->
    %%检查是否正在本地图中
    case get_miner_data(RoleID) of
        {ok,_}->
            next;
        _ ->
            ?THROW_ERR(?ERR_MINE_FB_DIG_END_NO_MINER_DATA)
    end,
    case get_mine_fb_map_info() of
        #r_mine_fb_map_info{place_id=PlaceID}->
            next;
        _ ->
            PlaceID=null,
            ?THROW_ERR(?ERR_MINE_FB_DIG_START_NOT_IN_PLACE)
    end,
    %%检查是否已经正在采矿
    case get_miner_data(RoleID)of
        {ok,#r_miner_data{status=?STATUS_DIGING,start_dig_time=StartDigTime,acc_silver=AccSilver}}->
            Now = common_tool:now(),
            [MinStopDigInterval] = ?find_config(min_stop_dig_interval),
            if
                Now>=StartDigTime+MinStopDigInterval-> %%至少需要1小时才能结束采矿
                    next;       
                true->
                    ?THROW_ERR(?ERR_MINE_FB_DIG_END_CD_TIME)
            end;
        _ ->
            AccSilver = null,
            ?THROW_ERR(?ERR_MINE_FB_DIG_END_HAS_NOT_STARTED)
    end,
    {ok,?DIG_TYPE_END,PlaceID,AccSilver}.



handle_mine_fb_dig_sure(RoleID,RoleName,RolePos,MinerLevel)->
    %%打上标记，进行广播，加入到某个slice里面去
    #p_pos{tx=TX,ty=TY} = RolePos,
    NewDoll = #p_map_doll{role_id=RoleID, role_name=RoleName, doll_name=RoleName, doll_type=?DOLL_TYPE_MINE_FB, 
                          level=MinerLevel, pos=RolePos},
    mod_map_stall:add_doll(TX, TY, NewDoll),
    
    %%增加新的矿工doll
    add_mine_fb_doll(RoleID,NewDoll),
    
    
    %%需要广播通知
    R2C = #m_mine_fb_dig_toc{return_self=false,dig_type=?DIG_TYPE_START,role_id=RoleID,miner_info=NewDoll},
    mgeem_map:do_broadcast_insence([{role, RoleID}], ?MINE_FB, ?MINE_FB_DIG, R2C, mgeem_map:get_state()),
    {ok,NewDoll}.

handle_mine_fb_dig_finish(RoleID)->
    %%删除副本的doll
    {ok,OldStall} = remove_mine_fb_doll(RoleID),
    mod_map_stall:remove_doll(OldStall),
    
    %%需要广播通知
    R2C = #m_mine_fb_dig_toc{return_self=false,dig_type=?DIG_TYPE_END,role_id=RoleID},
    mgeem_map:do_broadcast_insence([{role, RoleID}], ?MINE_FB, ?MINE_FB_DIG, R2C, mgeem_map:get_state()),
    ok.


%%  结束采矿
do_mine_fb_dig_end(RoleID,PlaceID,HarvestSilver,ShouldNotify)->
    IsOnline = common_misc:is_role_online(RoleID),
    TransFun = fun()-> 
           if
               HarvestSilver>0 andalso IsOnline ->
                   case mod_map_role:get_role_attr(RoleID) of
                       {ok,_}->
                           %%立即增加钱币
                           MoneyType = silver_bind,
                           ConsumeLogType = ?GAIN_TYPE_SILVER_MINE_FB_HARVEST,
                           common_bag2:t_gain_money(MoneyType, HarvestSilver, RoleID, ConsumeLogType);
                       _ ->
                           {ok,undefined}
                   end;
                HarvestSilver>0 andalso IsOnline == false ->
                    mod_offline_event:add_event(RoleID, ?OFFLINE_EVENT_TYPE_MINE_END, HarvestSilver),
                    {ok,undefined};
               true->
                   {ok,undefined}
           end
    end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,RoleAttr2}} ->
            ?TRY_CATCH( do_fb_minner_log(RoleID,?DIG_TYPE_END) ),
            
            %%从计算列表中删除
            delete_interval_calc_list(RoleID),
            
            %%删除矿工数据
            del_miner_data(RoleID),
            do_persitent_data(delete,RoleID),
            
            handle_mine_fb_dig_finish(RoleID),
            
            
            %%修改玩家的矿山ID
            case IsOnline of 
                true ->
                    case get_role_mine_fb_info(RoleID) of
                        {ok,RoleMineFbInfo} ->
                            NewRoleMineFbInfo = RoleMineFbInfo#r_role_mine_fb{place_id=0},
                            set_role_mine_fb_info(RoleID, NewRoleMineFbInfo);
                        _ ->
                            ignore
                    end;
                false ->
                    ignore
            end,
            
            case ShouldNotify andalso IsOnline of
                true->
                    R2 = #m_mine_fb_dig_toc{dig_type=?DIG_TYPE_END,return_self=true,role_id=RoleID,harvest_silver=HarvestSilver},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MINE_FB, ?MINE_FB_DIG, R2);
                _ ->
                    ignore
            end,
            
            send_fb_manager({dig_end,RoleID,PlaceID}),
            
            case RoleAttr2 of
                undefined-> ignore;
                _ ->
                    common_misc:send_role_silver_change(RoleID,RoleAttr2)
            end,
            ok;
        {aborted, AbortErr}->
            parse_aborted_err(AbortErr)
    end.


%%@interface 查看别人的矿工信息
do_mine_fb_view({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_mine_fb_view_tos{role_id=ViewRoleID} = DataIn,
    case catch check_do_mine_fb_view(RoleID,ViewRoleID) of
        {ok,MinerInfo}->
            R2 = #m_mine_fb_view_toc{role_id=ViewRoleID,miner_info=MinerInfo};
        {error,ErrCode,Reason}->
            R2 = #m_mine_fb_view_toc{role_id=ViewRoleID,err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).


%%@interface 收获
do_mine_fb_harvest({Unique, Module, Method, _DataIn, RoleID, PID, _Line})->
    case catch check_do_mine_fb_harvest(RoleID) of
        {ok,HarvestSilver,TodayHarvestedTimes}->
            case catch do_mine_fb_harvest_2(RoleID,HarvestSilver,TodayHarvestedTimes) of
                {ok,NextHarvestTime}->
                    R2 = #m_mine_fb_harvest_toc{silver=HarvestSilver,next_harvest_time=NextHarvestTime};
                {error,ErrCode,Reason}->
                    R2 = #m_mine_fb_harvest_toc{err_code=ErrCode,reason=Reason}
            end;
        {error,ErrCode,Reason}->
            R2 = #m_mine_fb_harvest_toc{err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

do_mine_fb_harvest_2(RoleID,HarvestSilver,TodayHarvestedTimes)->
    TransFun = fun()-> 
                     t_mine_fb_harvest(RoleID,HarvestSilver,TodayHarvestedTimes)  
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,RoleAttr2,NextHarvestTime}} ->
            common_misc:send_role_silver_change(RoleID,RoleAttr2),
            {ok,NextHarvestTime};
        {aborted, AbortErr}->
            parse_aborted_err(AbortErr)
    end.

t_mine_fb_harvest(RoleID,HarvestSilver,TodayHarvestedTimes)->
    %%修改收获时间
    Now = common_tool:now(),
    Today = date(),
    NextHarvestTime = Now+get_harvest_cd_time(RoleID),
    {ok,OldMinerData} = get_miner_data(RoleID),
    NewMinerData = OldMinerData#r_miner_data{acc_silver=0,
                                             last_harvest_time=Now,next_harvest_time=NextHarvestTime,
                                             harvested_times={Today,TodayHarvestedTimes+1}},
    set_miner_data(RoleID,NewMinerData),
    
    MoneyType = silver_bind,
    ConsumeLogType = ?GAIN_TYPE_SILVER_MINE_FB_HARVEST,
    {ok,RoleAttr2} = common_bag2:t_gain_money(MoneyType, HarvestSilver, RoleID, ConsumeLogType),
    {ok,RoleAttr2,NextHarvestTime}.

%%@interface 掠夺
do_mine_fb_grab({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_mine_fb_grab_tos{role_id=ToRoleID} = DataIn,
    case catch check_do_mine_fb_grab(RoleID,DataIn) of
        {ok,TodayGrabTimes}->
            [PkMapID] = ?find_config(pk_map_id),
			Mirror = mod_mirror:copy(ToRoleID),
			MirrorTab = ets:new(t_mirror, [public]),
			ets:insert(MirrorTab, Mirror),
			RoleProcName = mgeer_role:proc_name(RoleID),
			RolePID = global:whereis_name(RoleProcName),
			#map_state{mapid=MapID, map_name=MapName} = mgeem_map:get_state(),
			common_misc:send_to_rolemap(RoleID, {mod, mod_mirror_fb, 
				{change_map, RoleID, PkMapID, RolePID, RoleProcName, MirrorTab, [
					{{?MODULE, to_role_id}, ToRoleID}, 
					{{?MODULE, from_map_id}, MapID}, 
					{{?MODULE, from_map_name}, MapName}
				]}
			}),
            
            %%修改对方的PK状态
            {ok,ToRoleMinerData} = get_miner_data(ToRoleID),
            NewToRoleMinerData = ToRoleMinerData#r_miner_data{pk_status=?PK_STATUS_FIGHTING},
            set_miner_data(ToRoleID,NewToRoleMinerData),
            
            Today = date(),
            %%修改今日的掠夺次数
            {ok,RoleMineFbInfo} = get_role_mine_fb_info(RoleID),
            NewTodayGrabTimes=TodayGrabTimes+1,
            NewRoleMineFbInfo = RoleMineFbInfo#r_role_mine_fb{grab_times={Today,NewTodayGrabTimes}},
            set_role_mine_fb_info(RoleID, NewRoleMineFbInfo),
            
            MaxGrabTimes = get_max_grab_times(RoleID),
            R2 = #m_mine_fb_grab_toc{role_id=ToRoleID,grab_times=NewTodayGrabTimes,max_grab_times=MaxGrabTimes};
        {error,ErrCode,Reason}->
            R2 = #m_mine_fb_grab_toc{role_id=ToRoleID,err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

check_do_mine_fb_grab(RoleID,DataIn)->
    #m_mine_fb_grab_tos{role_id=ToRoleID} = DataIn,
    assert_not_myself(RoleID,ToRoleID,?ERR_MINE_FB_GRAB_MY_SELF),
    
    case get_miner_data(ToRoleID) of
        {ok,#r_miner_data{next_harvest_time=NextHarvestTime,pk_status=PkStatus}}->
            Now = common_tool:now(),
            if
                Now>=NextHarvestTime->
                    next;
                true->
                    ?THROW_ERR(?ERR_MINE_FB_GRAB_HARVEST_CD_TIMES)
            end,
            if
                PkStatus=:=?PK_STATUS_FIGHTING->
                    ?THROW_ERR(?ERR_MINE_FB_GRAB_IS_FIGHTING);
                true->
                    next
           end;
        _ ->
            ?THROW_ERR(?ERR_MINE_FB_GRAB_NO_MINER_DATA)
    end,
    %% 检查今日的掠夺次数
    Today = date(),
    MaxGrabTimes = get_max_grab_times(RoleID),
    case get_role_mine_fb_info(RoleID) of
        {ok, #r_role_mine_fb{grab_times={Today,TodayGrabTimes}}}->
            if
                TodayGrabTimes>=MaxGrabTimes->
                    ?THROW_ERR(?ERR_MINE_FB_GRAB_MAX_TIMES);
                true->
                    next
            end;
        _ ->
            TodayGrabTimes=0
    end,
    {ok,TodayGrabTimes}.


%%@interface 祝福
do_mine_fb_bless({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_mine_fb_bless_tos{role_id=ToRoleID} = DataIn,
    case catch check_do_mine_fb_bless(RoleID,DataIn) of
        {ok,TodayBeBlessedTimes,TodayMyBlessTimes}->
            %%修改加成比率
            Today = date(),
            [{ToRoleAddRate,MyRoleAddRate}] = ?find_config(bless_addition_rate),
            
            %%如果自己在本地图有矿工，则可以祝福加成
            case get_miner_data(RoleID) of
                {ok,RoleMinerData} ->
                    #r_miner_data{addition_rate=MyRate1,miner_level=MinerLevel} = RoleMinerData,
                    MaxAddRate = get_max_add_rate(MinerLevel),
                    if
                        (MyRate1+MyRoleAddRate)>MaxAddRate->
                            MyRoleAddRate2C = -1,
                            NewAddRate=MyRate1;
                        true->
                            MyRoleAddRate2C = MyRoleAddRate,
                            NewAddRate=MyRate1+MyRoleAddRate
                    end,
                    NewMyRoleMinerData = RoleMinerData#r_miner_data{addition_rate=NewAddRate},
                    set_miner_data(RoleID,NewMyRoleMinerData),
                    notify_miner_addrate_update(RoleID,NewAddRate);
                _ ->
                    MyRoleAddRate2C = 0
            end,
            case get_miner_data(ToRoleID) of    
                {ok,ToRoleMinerData} ->
                    #r_miner_data{addition_rate=ToRate1} = ToRoleMinerData,
                    NewToAddRate=ToRate1+ToRoleAddRate,
                    NewToRoleMinerData = ToRoleMinerData#r_miner_data{blessed_times={Today,TodayBeBlessedTimes+1},
                                                                      addition_rate=NewToAddRate},
                    set_miner_data(ToRoleID,NewToRoleMinerData),
                    notify_miner_addrate_update(ToRoleID,NewToAddRate);
                _ ->
                    ignore
            end,
            
            %%修改今日的祝福次数
            {ok,RoleMineFbInfo} = get_role_mine_fb_info(RoleID),
            NewTodayBlessTimes=TodayMyBlessTimes+1,
            NewRoleMineFbInfo = RoleMineFbInfo#r_role_mine_fb{bless_times={Today,NewTodayBlessTimes}},
            set_role_mine_fb_info(RoleID, NewRoleMineFbInfo),
            
            %%发送信件
            case mod_map_role:get_role_base(RoleID) of
                {ok,#p_role_base{role_name=OtherRoleName}}->
                    send_miner_bless_title(ToRoleID,OtherRoleName,ToRoleAddRate);
                _ ->
                    ignore
            end,
            
            MaxBlessTimes = get_max_bless_times(RoleID),
            R2 = #m_mine_fb_bless_toc{role_id=ToRoleID,bless_times=NewTodayBlessTimes,max_bless_times=MaxBlessTimes,my_add_rate=MyRoleAddRate2C};
        {error,ErrCode,Reason}->
            R2 = #m_mine_fb_bless_toc{role_id=ToRoleID,err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

check_do_mine_fb_bless(RoleID,DataIn)->
    #m_mine_fb_bless_tos{role_id=ToRoleID} = DataIn,
    assert_not_myself(RoleID,ToRoleID,?ERR_MINE_FB_BLESS_MY_SELF),
    
    Today = date(),
    %%检查对方的次数
    [MaxBeBlessedTimes] = ?find_config(max_blessed_times),
    case get_miner_data(ToRoleID) of
        {ok,#r_miner_data{blessed_times=0}}->
            TodayBeBlessedTimes= 0;
        {ok,#r_miner_data{blessed_times={Today,TodayBeBlessedTimes}}}->
            if
                TodayBeBlessedTimes>=MaxBeBlessedTimes->
                    ?THROW_ERR(?ERR_MINE_FB_BE_BLESSED_MAX_TIMES);
                true->
                    next
            end;
        {ok,#r_miner_data{}}->
            TodayBeBlessedTimes= 0;
        _ ->
            TodayBeBlessedTimes= null,
            ?THROW_ERR(?ERR_MINE_FB_BLESS_NO_MINER_DATA)
    end,
    
    %% 检查对方的加成比率
    {ok,#r_miner_data{addition_rate=AditionRate,miner_level=MinerLevel}}=get_miner_data(ToRoleID),
    [MinerAddRateList] = ?find_config(miner_add_rate_list),
    case lists:keyfind(MinerLevel, 1, MinerAddRateList) of
        {MinerLevel,_,_,MaxAddRate}->
            if
                AditionRate>=MaxAddRate->
                    ?THROW_ERR(?ERR_MINE_FB_BLESS_MAX_ADDRATE);
                true->
                    next
            end;
        false->
            ?THROW_ERR(?ERR_CONFIG_ERR)
    end,
     
     
    %% 检查今日的祝福次数
    MaxBlessTimes = get_max_bless_times(RoleID),
    case get_role_mine_fb_info(RoleID) of
        {ok, #r_role_mine_fb{bless_times={Today,TodayBlessTimes}}}->
            if
                TodayBlessTimes>=MaxBlessTimes->
                    ?THROW_ERR(?ERR_MINE_FB_BLESS_MAX_TIMES);
                true->
                    next
            end;
        _ ->
            TodayBlessTimes=0
    end,
    {ok,TodayBeBlessedTimes,TodayBlessTimes}.


%%获取祝福/干扰的最大加成比率
get_max_add_rate(MinerLevel)->
    [MinerAddRateList] = ?find_config(miner_add_rate_list),
    case lists:keyfind(MinerLevel, 1, MinerAddRateList) of
        {MinerLevel,_,_,MaxAddRate}->
            MaxAddRate;
        false->
            0
    end.


%%@return {MaxGrabTimes,MaxBlessTimes,MaxDisturbTimes}
get_max_op_times(RoleID)->
    VipLevel = mod_vip:get_role_vip_level(RoleID),
    [VipTimesList] = ?find_config(fb_vip_times_list),
    {VipLevel,MaxGrabTimes,MaxBlessTimes,MaxDisturbTimes,_} = lists:keyfind(VipLevel, 1, VipTimesList),
    {MaxGrabTimes,MaxBlessTimes,MaxDisturbTimes}.
    
get_max_grab_times(RoleID)->
    VipLevel = mod_vip:get_role_vip_level(RoleID),
    [VipTimesList] = ?find_config(fb_vip_times_list),
    {VipLevel,MaxGrabTimes,_,_,_} = lists:keyfind(VipLevel, 1, VipTimesList),
    MaxGrabTimes.

get_max_bless_times(RoleID)->
    VipLevel = mod_vip:get_role_vip_level(RoleID),
    [VipTimesList] = ?find_config(fb_vip_times_list),
    {VipLevel,_,MaxBlessTimes,_,_} = lists:keyfind(VipLevel, 1, VipTimesList),
    MaxBlessTimes.

get_max_disturb_times(RoleID)->
    VipLevel = mod_vip:get_role_vip_level(RoleID),
    [VipTimesList] = ?find_config(fb_vip_times_list),
    {VipLevel,_,_,MaxDisturbTimes,_} = lists:keyfind(VipLevel, 1, VipTimesList),
    MaxDisturbTimes.

get_harvest_cd_time(RoleID)-> 
    VipLevel = mod_vip:get_role_vip_level(RoleID),
    [VipTimesList] = ?find_config(fb_vip_times_list),
    {VipLevel,_,_,_,HarvestCdTime} = lists:keyfind(VipLevel, 1, VipTimesList),
    HarvestCdTime.


%%@interface 干扰
do_mine_fb_disturb({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_mine_fb_disturb_tos{role_id=ToRoleID} = DataIn,
    case catch check_do_mine_fb_disturb(RoleID,DataIn) of
        {ok,TodayBeDisturbedTimes,TodayDisturbTimes}->
            %%修改加成比率
            Today = date(),
            [{ToRoleMinusRate,MyRoleAddRate}] = ?find_config(disturb_addition_rate),
            
            %%如果自己在本地图有矿工，则可以干扰加成
            case get_miner_data(RoleID) of
                {ok,RoleMinerData} ->
                    #r_miner_data{addition_rate=MyRate1,miner_level=MinerLevel} = RoleMinerData,
                    MaxAddRate = get_max_add_rate(MinerLevel),
                    if
                        (MyRate1+MyRoleAddRate)>MaxAddRate->
                            MyRoleAddRate2C = -1,
                            NewAddRate=MyRate1;
                        true->
                            MyRoleAddRate2C = MyRoleAddRate,
                            NewAddRate=MyRate1+MyRoleAddRate
                    end, 
                    NewMyRoleMinerData = RoleMinerData#r_miner_data{addition_rate=NewAddRate},
                    set_miner_data(RoleID,NewMyRoleMinerData),
                    notify_miner_addrate_update(RoleID,NewAddRate);
                _ ->
                    MyRoleAddRate2C = 0
            end,
            case get_miner_data(ToRoleID) of    
                {ok,ToRoleMinerData} ->
                    #r_miner_data{addition_rate=ToRate1} = ToRoleMinerData,
                    NewToAddRate = ToRate1-ToRoleMinusRate,
                    NewToRoleMinerData = ToRoleMinerData#r_miner_data{disturbed_times={Today,TodayBeDisturbedTimes+1},
                                                                      addition_rate=NewToAddRate},
                    set_miner_data(ToRoleID,NewToRoleMinerData),
                    notify_miner_addrate_update(ToRoleID,NewToAddRate);
                _ ->
                   ignore
            end, 
            
            
            %%修改今日的干扰次数
            {ok,RoleMineFbInfo} = get_role_mine_fb_info(RoleID),
            NewTodayDisturbTimes = TodayDisturbTimes+1,
            NewRoleMineFbInfo = RoleMineFbInfo#r_role_mine_fb{disturb_times={Today,NewTodayDisturbTimes}},
            set_role_mine_fb_info(RoleID, NewRoleMineFbInfo),
            
            %%发送信件
            case mod_map_role:get_role_base(RoleID) of
                {ok,#p_role_base{role_name=OtherRoleName}}->
                    send_miner_disturb_title(ToRoleID,OtherRoleName,ToRoleMinusRate);
                _ ->
                    ignore
            end,
            
            MaxDisturbTimes = get_max_disturb_times(RoleID),
            R2 = #m_mine_fb_disturb_toc{role_id=ToRoleID,disturb_times=NewTodayDisturbTimes,max_disturb_times=MaxDisturbTimes,my_add_rate=MyRoleAddRate2C};
        {error,ErrCode,Reason}->
            R2 = #m_mine_fb_disturb_toc{role_id=ToRoleID,err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

check_do_mine_fb_disturb(RoleID,DataIn)->
    #m_mine_fb_disturb_tos{role_id=ToRoleID} = DataIn,
    assert_not_myself(RoleID,ToRoleID,?ERR_MINE_FB_DISTURB_MY_SELF),
    
    Today = date(),
    %%检查对方的次数
    [MaxBeDisturbedTimes] = ?find_config(max_disturbed_times),
    case get_miner_data(ToRoleID) of
        {ok,#r_miner_data{disturbed_times=0}}->
            TodayBeDisturbedTimes= 0;
        {ok,#r_miner_data{disturbed_times={Today,TodayBeDisturbedTimes}}}->
            if
                TodayBeDisturbedTimes>=MaxBeDisturbedTimes->
                    ?THROW_ERR(?ERR_MINE_FB_BE_DISTURBED_MAX_TIMES);
                true->
                    next
            end;
        {ok,#r_miner_data{}}->
            TodayBeDisturbedTimes= 0;
        _ ->
            TodayBeDisturbedTimes= null,
            ?THROW_SYS_ERR()
    end,
    
    %% 检查对方的加成比率
    {ok,#r_miner_data{addition_rate=AditionRate,miner_level=MinerLevel}}=get_miner_data(ToRoleID),
    [MinerAddRateList] = ?find_config(miner_add_rate_list),
    case lists:keyfind(MinerLevel, 1, MinerAddRateList) of
        {MinerLevel,_,MinAddRate,_}->
            if
                MinAddRate>=AditionRate->
                    ?THROW_ERR(?ERR_MINE_FB_DISTURB_MIN_ADDRATE);
                true->
                    next
            end;
        false->
            ?THROW_ERR(?ERR_CONFIG_ERR)
    end,
    
    %% 检查今日的干扰次数
    MaxDisturbTimes = get_max_disturb_times(RoleID),
    case get_role_mine_fb_info(RoleID) of
        {ok, #r_role_mine_fb{disturb_times={Today,TodayDisturbTimes}}}->
            if
                TodayDisturbTimes>=MaxDisturbTimes->
                    ?THROW_ERR(?ERR_MINE_FB_DISTURB_MAX_TIMES);
                true->
                    next
            end;
        _ ->
            TodayDisturbTimes=0
    end,
    {ok,TodayBeDisturbedTimes,TodayDisturbTimes}.




%%@interface 秒完、续期等操作
do_mine_fb_operate({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_mine_fb_operate_tos{op_type=OpType} = DataIn,
    case catch check_do_mine_fb_operate(RoleID,DataIn) of
        {ok,?OPERATE_TYPE_RENEWAL,TimeHour,MoneyType,DeductMoney}->
            case catch do_mine_fb_operate_renewal(RoleID,TimeHour,MoneyType,DeductMoney) of
                {ok,NewEndTime}->
                    R2 = #m_mine_fb_operate_toc{op_type=OpType,time_hour=TimeHour,deduct_silver=DeductMoney,
                                                end_dig_time=NewEndTime};
                {error,ErrCode,Reason}->
                    R2 = #m_mine_fb_operate_toc{op_type=OpType,err_code=ErrCode,reason=Reason}
            end;
        {error,ErrCode,Reason}->
            R2 = #m_mine_fb_operate_toc{op_type=OpType,err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).

%%续期
do_mine_fb_operate_renewal(RoleID,TimeHour,MoneyType,DeductMoney)->
    TransFun = fun()-> 
                       t_deduct_fb_dig_money(RoleID,MoneyType,DeductMoney)
               end,
    case common_transaction:t( TransFun ) of
        {atomic, {ok,RoleAttr2}} ->
            %%保存到数据库中
            case get_miner_data(RoleID) of
                {ok,OldRec}->
                    #r_miner_data{end_dig_time=EndTime}= OldRec,
                    [Secs3600] = ?find_config(dig_hour_to_seconds),
                    NewEndTime = EndTime+TimeHour*Secs3600,
                    NewRec = OldRec#r_miner_data{end_dig_time=NewEndTime},
                    set_miner_data(RoleID,NewRec);
                _ ->
                    NewEndTime = 0
            end,
            
            common_misc:send_role_silver_change(RoleID,RoleAttr2),
            {ok,NewEndTime};
        {aborted, AbortErr} ->
            parse_aborted_err(AbortErr)
    end.

check_do_mine_fb_operate(RoleID,DataIn)->
    #m_mine_fb_operate_tos{op_type=OpType} = DataIn,
    
    case OpType of
        ?OPERATE_TYPE_RENEWAL->
            check_do_mine_fb_renewal(RoleID,DataIn);
        _ ->
            ?THROW_ERR(?ERR_INTERFACE_ERR)
    end.
    
check_do_mine_fb_renewal(RoleID,DataIn)->    
    #m_mine_fb_operate_tos{op_type=OpType,time_hour=TimeHour} = DataIn,
    assert_actor_in_map(RoleID),
    
    case get_miner_data(RoleID) of
        {ok,#r_miner_data{status=?STATUS_DIGING,miner_level=MinerLevel,end_dig_time=EndDigTime}}->
            Now = common_tool:now(),
            [MinRenewalDigInterval] = ?find_config(min_renewal_dig_interval),
            if
                Now+MinRenewalDigInterval>=EndDigTime->%%至少需要最后1小时才能结束采矿
                    next;       
                true->
                    ?THROW_ERR(?ERR_MINE_FB_RENEWAL_CD_TIME)
            end;
        _ ->
            MinerLevel = null,
            ?THROW_ERR(?ERR_MINE_FB_RENEWAL_NO_MINER_DATA)
    end,
    
    {MoneyType,DeductMoney} = get_dig_cost_money(MinerLevel,TimeHour),
    
    {ok,OpType,TimeHour,MoneyType,DeductMoney}.


log_async_create_copy(RoleID, Info) ->
    erlang:put({mine_fb_create_key, RoleID}, Info).
get_async_create_copy_info(RoleID) ->
    erlang:get({mine_fb_create_key, RoleID}).

  


%%返回京城出生点
get_mine_fb_return_pos(RoleID)->
    common_map:get_map_return_pos_of_jingcheng(RoleID).



hook_role_enter(RoleID, _MapID)->
    case get_mine_fb_map_info() of
        #r_mine_fb_map_info{place_id=CurrPlaceID}->
            hook_miner_info(RoleID,CurrPlaceID);
        _ ->
            ignore
    end.

hook_miner_info(RoleID,CurrPlaceID)->
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MINE_FB, ?MINE_FB_ENTER, #m_mine_fb_enter_toc{place_id=CurrPlaceID}),
    case get_miner_data(RoleID) of
        {ok,MinerData}->
            hook_miner_info_2(RoleID,CurrPlaceID,MinerData);
        _ ->
            Today = date(),
            {MaxGrabTimes,MaxBlessTimes,MaxDisturbTimes} = get_max_op_times(RoleID),
            case get_role_mine_fb_info(RoleID) of
                {ok, #r_role_mine_fb{place_id=MinerPlaceID1,grab_times=GrabTimes,bless_times=BlessTimes,disturb_times=DisturbTimes}=OldRoleInfo}->
                    if
                        MinerPlaceID1=:=CurrPlaceID->
                            MinerPlaceID2=0,    %%这个矿山实际上没有矿工，跟服务器重启有关
                            NewRoleInfo = OldRoleInfo#r_role_mine_fb{place_id=0},
                            set_role_mine_fb_info(RoleID, NewRoleInfo);
                        true->
                            MinerPlaceID2=MinerPlaceID1
                    end;
                _ ->
                    MinerPlaceID2=GrabTimes=BlessTimes=DisturbTimes=0
            end,
            TodayGrabTimes = get_op_times(GrabTimes,Today),
            TodayBlessTimes = get_op_times(BlessTimes,Today),
            TodayDisturbTimes = get_op_times(DisturbTimes,Today),
            
            
            R2 = #m_mine_fb_info_toc{status=?STATUS_NONE,curr_place_id=CurrPlaceID,miner_place_id=MinerPlaceID2,
                                     grab_times=TodayGrabTimes,bless_times=TodayBlessTimes,disturb_times=TodayDisturbTimes,
                                     max_grab_times=MaxGrabTimes,max_disturb_times=MaxDisturbTimes,max_bless_times=MaxBlessTimes},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MINE_FB, ?MINE_FB_INFO, R2)
    end.

hook_miner_info_2(RoleID,CurrPlaceID,MinerData)->
    #r_miner_data{status=Status1,miner_place_id=MinerPlaceID,miner_level=MinerLevel,addition_rate=AdditionRate,
                  start_dig_time=StartDigTime,end_dig_time=EndDigTime,
                  last_harvest_time=LastHarvestTime,next_harvest_time=NextHarvestTime,
                  acc_silver=AccSilver,grabed_times=GrabedTimes,blessed_times=BlessedTimes,disturbed_times=DisturbedTimes} =MinerData,
    if
        Status1=:=undefined->
            Status2=?STATUS_DIGING;
        true-> 
            Status2 = Status1
    end,
    {MaxGrabTimes,MaxBlessTimes,MaxDisturbTimes} = get_max_op_times(RoleID),
  case get_role_mine_fb_info(RoleID) of
        {ok, #r_role_mine_fb{place_id=MinerPlaceID,grab_times=GrabTimes,bless_times=BlessTimes,disturb_times=DisturbTimes}}->
            next;
        _ ->
            GrabTimes=BlessTimes=DisturbTimes=0
    end,
    
    Today = date(),
    TodayGrabTimes = get_op_times(GrabTimes,Today),
    TodayBlessTimes = get_op_times(BlessTimes,Today),
    TodayDisturbTimes = get_op_times(DisturbTimes,Today),
    
    TodayBeGrabedTimes = get_op_times(GrabedTimes,Today),
    TodayBeBlessedTimes = get_op_times(BlessedTimes,Today),
    TodayBeDisturbedTimes = get_op_times(DisturbedTimes,Today),
    R2 = #m_mine_fb_info_toc{status=Status2,curr_place_id=CurrPlaceID,miner_place_id=MinerPlaceID,
                             miner_level=MinerLevel,addition_rate=AdditionRate,
                             start_dig_time=StartDigTime,end_dig_time=EndDigTime,
                             last_harvest_time=LastHarvestTime,next_harvest_time=NextHarvestTime,
                             acc_silver=AccSilver,
                             grab_times=TodayGrabTimes,bless_times=TodayBlessTimes,disturb_times=TodayDisturbTimes,
                             grabed_times=TodayBeGrabedTimes,blessed_times=TodayBeBlessedTimes,disturbed_times=TodayBeDisturbedTimes,
                             max_grab_times=MaxGrabTimes,max_disturb_times=MaxDisturbTimes,max_bless_times=MaxBlessTimes},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MINE_FB, ?MINE_FB_INFO, R2).
            

get_op_times({Today,Times},Today)->
    Times;
get_op_times({_Today,_Times},_)->
    0;
get_op_times(Times,_) when is_integer(Times)->
    Times.


hook_role_quit(_RoleID)->
    ok.


%% --------------------------------------------------------------------
%%% 内部二级函数
%% --------------------------------------------------------------------
is_fb_map_id(DestMapID)->
    DestMapID =:= ?MINE_FB_MAP_ID.

get_mine_fb_map_info()->
    get(?MINE_FB_MAP_INFO).
set_mine_fb_map_info(BattleMapInfo)->
    put(?MINE_FB_MAP_INFO,BattleMapInfo).


%%初始化数据库中的矿工数据
init_miner_list(PlaceID,MinerDataList)->
    set_mine_fb_map_info(#r_mine_fb_map_info{place_id=PlaceID}),
    [ init_miner_list_2(MinerData) ||MinerData<-MinerDataList ],
    ok.

init_miner_list_2(MinerData)->
    #r_miner_data{role_id=RoleID,role_name=RoleName,role_pos=RolePos,miner_level=MinerLevel} = MinerData,
    MinerData2 = MinerData#r_miner_data{pk_status=?PK_STATUS_NONE},
    set_miner_data(RoleID,MinerData2),
    
    %%加入到定时计算列表中
    insert_interval_calc_list(RoleID),
    handle_mine_fb_dig_sure(RoleID,RoleName,RolePos,MinerLevel),
    ok.

do_init_mine_fb_map_info(CreateMapInfo)->
    {_RoleID,PlaceID,_FbMapID,_FbMapName} = CreateMapInfo,
    set_mine_fb_map_info(#r_mine_fb_map_info{place_id=PlaceID}),
    
    ok.


        
%%检查一个点周围是否有空间摆摊
check_space_around(TX, TY) ->
    List = get_around_txty(TX, TY),
    lists:foldl(
      fun({X, Y}, Acc) ->
              case mod_map_stall:check_point(X, Y) of
                  false ->
                      Acc;
                  true ->
                      false
              end
      end,
      true, List).


%%获得以一个格子为中心的9个格子
get_around_txty(TX, TY) ->
    BeginX = TX - 1,
    EndX = TX + 1,
    BeginY = TY - 1,
    EndY = TY + 1,
    lists:foldl(
      fun(X, Acc) ->
              lists:foldl(
                fun(Y, AccSub) ->
                        [{X, Y} | AccSub]
                end, Acc, lists:seq(BeginY, EndY))
      end, [], lists:seq(BeginX, EndX)).


%%扣除钱币/元宝
t_deduct_fb_dig_money(RoleID,MoneyType,DeductMoney)->
    case MoneyType of
        silver_any->
            ConsumeLogType = ?CONSUME_TYPE_SILVER_MINE_FB_DIG;
        gold_any->
            ConsumeLogType = ?CONSUME_TYPE_SILVER_MINE_FB_DIG
    end,
    case common_bag2:t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeLogType) of
        {ok,RoleAttr2}->
            {ok,RoleAttr2};
        {error,silver_any}->
            ?THROW_ERR( ?ERR_MINE_FB_DIG_SILVER_NOT_ENOUGH );
        {error,gold_any}->
            ?THROW_ERR( ?ERR_MINE_FB_DIG_GOLD_NOT_ENOUGH );
        {error, Reason} ->
            ?THROW_ERR(?ERR_OTHER_ERR, Reason);
        _ ->
            ?THROW_SYS_ERR()
    end. 

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

check_do_mine_fb_view(RoleID,ViewRoleID)->
    assert_actor_in_map(RoleID),
    
    case get_miner_data(ViewRoleID) of
        {ok,#r_miner_data{role_name=RoleName,role_level=RoleLevel,role_jingjie=RoleJingjie,role_category=RoleCategory,
                          miner_level=MinerLevel,acc_silver=AccSilver,start_dig_time=StartTime,end_dig_time=EndTime,
                          last_harvest_time=LastHarvestTime,next_harvest_time=NextHarvestTime,addition_rate=AddRate}}->
            MinerInfo = #p_miner_info{role_id=ViewRoleID,role_name=RoleName,role_level=RoleLevel,role_jingjie=RoleJingjie,role_category=RoleCategory,
                                      miner_level=MinerLevel,acc_silver=AccSilver,start_dig_time=StartTime,end_dig_time=EndTime,
                                      last_harvest_time=LastHarvestTime,next_harvest_time=NextHarvestTime,addition_rate=AddRate},
            {ok,MinerInfo};
        _ ->
            ?THROW_ERR(?ERR_MINE_FB_VIEW_NO_MINER_DATA)
    end.

check_do_mine_fb_harvest(RoleID)->
    assert_actor_in_map(RoleID),
    
    case get_miner_data(RoleID) of
        {ok,#r_miner_data{acc_silver=AccSilver,start_dig_time=StartDigTime,last_harvest_time=LastHarvestTime,
                          harvested_times=Times1}}->
            Now = common_tool:now(),
            %%判断收获的CD时间
            HarvestCdTime = get_harvest_cd_time(RoleID),
            if
                LastHarvestTime=:=0 andalso Now>=(StartDigTime+HarvestCdTime)->
                    next; %%第一次收获离开始挖矿也必须有CD保护
                LastHarvestTime>0 andalso Now>=(LastHarvestTime+HarvestCdTime)->
                    next;
                true->
                    ?THROW_ERR(?ERR_MINE_FB_HARVEST_IN_CD_TIME)
            end,
            Today = date(),
            case Times1 of
                {Today,TodayHarvestedTimes}->
                    next;
                _ ->
                    TodayHarvestedTimes=0
            end,
            {ok,AccSilver,TodayHarvestedTimes};
        _ ->
            ?THROW_ERR(?ERR_MINE_FB_HARVEST_NO_MINER_DATA)
    end.
    


%%计算采矿需要消费的钱币
get_dig_cost_money(MinerLevel,TimeHour) when TimeHour>0->
    [MinerCostList] = ?find_config(miner_cost_list),
    case lists:keyfind(MinerLevel, 1, MinerCostList) of
        {MinerLevel,MoneyType,PerCostMoney,MinHour,MaxHour}->
            if
                is_integer(TimeHour) andalso MaxHour>=TimeHour andalso TimeHour>=MinHour->
                    DeductMoney = PerCostMoney*TimeHour;
                true->
                    DeductMoney = null,
                    ?THROW_ERR(?ERR_MINE_FB_TIME_HOUR_IS_INVALID)
            end;
        false->
            MoneyType = DeductMoney=null,
            ?THROW_CONFIG_ERR()
    end,
    {MoneyType,DeductMoney}.




%% 获取矿工数据
get_miner_data(RoleID) when is_integer(RoleID)->
    case get(?MINE_FB_MINER_DATA_LIST)of
        undefined->
            {error,not_found};
        List->
            case lists:keyfind(RoleID, #r_miner_data.role_id, List) of
                false->
                    {error,not_found};
                MinerData->
                    {ok,MinerData}
            end
    end.

%% 设置矿工数据
set_miner_data(RoleID,MinerData) when is_integer(RoleID),is_record(MinerData,r_miner_data)->
    case get(?MINE_FB_MINER_DATA_LIST)of
        undefined->
            put(?MINE_FB_MINER_DATA_LIST,[MinerData]);
        List->
            List2 = lists:keystore(RoleID, #r_miner_data.role_id, List, MinerData),
            put(?MINE_FB_MINER_DATA_LIST,List2)
    end.

%% 删除矿工数据
del_miner_data(RoleID) when is_integer(RoleID)->
    case get(?MINE_FB_MINER_DATA_LIST)of
        undefined->
            ingore;
        List->
            List2 = lists:keydelete(RoleID, #r_miner_data.role_id, List),
            put(?MINE_FB_MINER_DATA_LIST,List2)
    end.


%%保存玩家的副本数据，主要是操作次数等数据
set_role_mine_fb_info(RoleID, NewInfo)->
    TransFun = fun()-> 
                       t_set_role_mine_fb_info(RoleID, NewInfo)
               end,
    case common_transaction:t( TransFun ) of
        {atomic, ok} ->
            ok;
        {aborted, Error} -> 
            ?ERROR_MSG("set_role_mine_fb_info error,Error=~w", [Error]),
            {error, fail}
    end.

t_set_role_mine_fb_info(RoleID, FbInfo) ->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,RoleExtInfo} ->
            NewRoleExtInfo = RoleExtInfo#r_role_map_ext{role_mine_fb=FbInfo},
            mod_map_role:t_set_role_map_ext_info(RoleID, NewRoleExtInfo),
            ok;
        _ ->
            ?THROW_SYS_ERR()
    end.

get_role_mine_fb_info(RoleID) ->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,#r_role_map_ext{role_mine_fb=FbInfo}} ->
            {ok, FbInfo};
        _ ->
            {error, not_found}
    end.


%%--------------------------------  计算采矿的代码  [start]--------------------------------

%%计算采矿奖励
do_calc_mine_interval(Now) ->
    RoleIDList = get_interval_calc_list(Now),
%%     [CalcMineSilverList] = ?find_config(fb_calc_mine_silver),
    [ do_calc_mine_interval_2(RoleID) ||RoleID<-RoleIDList ].


do_calc_mine_interval_2(RoleID)->
	case get_miner_data(RoleID) of
		{ok,MinerData}->
			#r_miner_data{role_level=RoleLevel,acc_silver=OldSilver,addition_rate=AdditionRate} = MinerData,
			CalcBase = get_level_silver(RoleLevel),
			if
				AdditionRate>-100->
					AddSilver = CalcBase*(100+AdditionRate) div 100,
					NewSilver = (OldSilver+AddSilver),
					MinerData2 = MinerData#r_miner_data{acc_silver=NewSilver},
					set_miner_data(RoleID,MinerData2),
					notify_miner_silver_update(RoleID,NewSilver),
					ok;
				true->
					ignore
			end;
		_ ->
			delete_interval_calc_list(RoleID)
	end.

get_level_silver(RoleLevel) ->
	[SilverList] = ?find_config(fb_calc_mine_silver),
	get_level_silver2(RoleLevel,SilverList).

get_level_silver2(RoleLevel,[Elem|SilverList]) ->
	{MinLevel,MaxLevel,Silver} = Elem,
	case RoleLevel >= MinLevel andalso MaxLevel < RoleLevel of
		true ->
			Silver;
		false ->
			get_level_silver2(RoleLevel,lists:delete(Elem, SilverList))
	end.
	
%% @doc 插入加计算列表
insert_interval_calc_list(RoleID) ->
    List = get_interval_calc_list(RoleID),
    set_interval_calc_list(RoleID, [RoleID|lists:delete(RoleID, List)]).

delete_interval_calc_list(RoleID) ->
    List = get_interval_calc_list(RoleID),
    set_interval_calc_list(RoleID, lists:delete(RoleID, List)).

get_interval_calc_list(RoleID) ->
    Key = RoleID rem ?CALC_MINE_INTERVAL,
    case get({?INTERVAL_MINE_CALC_LIST, Key}) of
        undefined ->
            [];
        List ->
            List
    end.

set_interval_calc_list(RoleID, List) ->
    Key = RoleID rem ?CALC_MINE_INTERVAL,
    put({?INTERVAL_MINE_CALC_LIST, Key}, List).

%%--------------------------------  计算采矿的代码 [end] --------------------------------

%%@doc 判断矿工是否到期、是否即将到期
judge_miner_timeout(#r_miner_data{role_id=RoleID,miner_place_id=PlaceID,end_dig_time=EndDigTime,acc_silver=AccSilver},Now,MinerTimeoutNotify)->
    if
        (Now+MinerTimeoutNotify)=:=EndDigTime->
            notify_miner_timeout_soon(RoleID,EndDigTime);
        Now>EndDigTime->
            %%时间已到，采矿结束
            do_mine_fb_dig_end(RoleID,PlaceID,AccSilver,true);
        true->
            ignore
    end.

assert_actor_in_map(RoleID)->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        #p_map_role{} ->
            next;
        undefined ->
            ?THROW_SYS_ERR()
    end.

assert_role_level(RoleAttr)->
    #p_role_attr{level=Level} = RoleAttr,
    [MinRoleTitle] = ?find_config(fb_min_role_level),
    if
        MinRoleTitle>Level->
            ?THROW_ERR( ?ERR_MINE_FB_ENTER_LEVEL_LIMIT );
        true->
            next
    end.

assert_not_myself(RoleID,ToRoleID,ErrCode) when is_integer(ErrCode)->
    if
        RoleID=/=ToRoleID->
            next;
        true->
            ?THROW_ERR(ErrCode)
    end.

%%将消息发送到mod_mine_fb_manager
send_fb_manager(Info)->
    case global:whereis_name( mod_mine_fb_manager ) of
        undefined->
            ignore;
        PID->
            PID ! Info
    end.

%%判断玩家是否在副本地图中
is_role_in_map(RoleID)->
    RoleIdList = mod_map_actor:get_in_map_role(),
    lists:member(RoleID, RoleIdList).

%%通知累计钱币的更新
notify_miner_silver_update(RoleID,NewSilver)->
    case is_role_in_map(RoleID) of
        true->
            R2 = #m_mine_fb_notify_toc{notify_type=?NOTIFY_TYPE_ACCSILVER,acc_silver=NewSilver},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MINE_FB, ?MINE_FB_NOTIFY, R2);
        _ ->
            ignore
    end.

%%通知矿工结束
notify_miner_timeout_soon(RoleID,EndDigTime)->
    R2 = #m_mine_fb_notify_toc{notify_type=?NOTIFY_TYPE_TIMEOUT,end_dig_time=EndDigTime},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MINE_FB, ?MINE_FB_NOTIFY, R2).

%%通知加成比率的更新
notify_miner_addrate_update(RoleID,AddRate)->
    R2 = #m_mine_fb_notify_toc{notify_type=?NOTIFY_TYPE_ADDRATE,addition_rate=AddRate},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MINE_FB, ?MINE_FB_NOTIFY, R2).

%%增加新的矿工doll
add_mine_fb_doll(RoleID,NewDoll)->
    #r_mine_fb_map_info{doll_list=DollList} = OldMapInfo =get_mine_fb_map_info(),
    NewDollList = [NewDoll|lists:keydelete(RoleID, #p_map_doll.role_id, DollList)],
    set_mine_fb_map_info(OldMapInfo#r_mine_fb_map_info{doll_list=NewDollList}),
    ok.

%%删除旧的矿工doll
remove_mine_fb_doll(RoleID)->
    #r_mine_fb_map_info{doll_list=DollList} = OldMapInfo = get_mine_fb_map_info(),
    OldStall = lists:keyfind(RoleID, #p_map_doll.role_id, DollList),
    NewDollList = lists:keydelete(RoleID,#p_map_doll.role_id, DollList),
    set_mine_fb_map_info(OldMapInfo#r_mine_fb_map_info{doll_list=NewDollList}),
    {ok,OldStall}.

%%%%%%%%%%%% 发送信件
send_miner_grab_title(MinerRoleID,OtherRoleName,GrabSilver) when is_integer(GrabSilver)->
    Title = ?_LANG_MINE_FB_TITLE_GRAB,
    Text = common_letter:create_temp(?MINE_FB_GRAB_LETTER,[OtherRoleName,common_misc:format_silver(GrabSilver)]),
    common_letter:sys2p(MinerRoleID,Text,Title,[],14),
    ok.

send_miner_bless_title(MinerRoleID,OtherRoleName,Rate) when is_integer(Rate)->
    Title = ?_LANG_MINE_FB_TITLE_BLESS,
    Text = common_letter:create_temp(?MINE_FB_BLESS_LETTER,[OtherRoleName,Rate]),
    common_letter:sys2p(MinerRoleID,Text,Title,[],14),
    ok.

send_miner_disturb_title(MinerRoleID,OtherRoleName,Rate) when is_integer(Rate)->
    Title = ?_LANG_MINE_FB_TITLE_DISTURB,
    Text = common_letter:create_temp(?MINE_FB_DISTURB_LETTER,[OtherRoleName,Rate]),
    common_letter:sys2p(MinerRoleID,Text,Title,[],14),
    ok.



%%记录矿工的日志
do_fb_minner_log(RoleID,Type)->
    Today = date(),
    case get_miner_data(RoleID) of
        #r_miner_data{pk_status=PkStatus,miner_place_id=MinerPlaceID,miner_level=MinerLevel,addition_rate=AddRate,
                      role_name=RoleName,role_level=RoleLevel,role_jingjie=RoleJingjie,
                      start_dig_time=StartTime,end_dig_time=EndTime,acc_silver=AccSilver,
                      grabed_times=GrabedTimes,blessed_times=BlessedTimes,disturbed_times=DisturbedTimes,harvested_times=HarvestedTimes}->
            
            TodayGrabedTimes = get_op_times(GrabedTimes,Today),
            TodayBlessedTimes = get_op_times(BlessedTimes,Today),
            TodayDisturbedTimes = get_op_times(DisturbedTimes,Today),
            TodayHarvestedTimes = get_op_times(HarvestedTimes,Today),
            FbLog = #r_mine_fb_log{role_id=RoleID,type=Type,
                                   pk_status=PkStatus,miner_place_id=MinerPlaceID,miner_level=MinerLevel,addition_rate=AddRate,
                                   role_name=RoleName,role_level=RoleLevel,role_jingjie=RoleJingjie,
                                   start_dig_time=StartTime,end_dig_time=EndTime,acc_silver=AccSilver,
                                   grabed_times=TodayGrabedTimes,blessed_times=TodayBlessedTimes,
                                   disturbed_times=TodayDisturbedTimes,harvested_times=TodayHarvestedTimes},
            common_general_log_server:log_mine_fb(FbLog);
        _ ->
            ignore
    end.


%%持久化数据
do_persitent_data(write,Rec) when is_tuple(Rec)->
    do_persitent_data(write,[Rec]);
do_persitent_data(write,List) when is_list(List)->
    case global:whereis_name(mgeed_dict_persistent) of
        undefined->
            ignore;
        PID->
            ReqList = [ {write,?DB_MINER_DATA_P, Rec} ||Rec<-List ],
            PID ! {store_queue, ReqList}
    end;
do_persitent_data(delete,Key)->
    case global:whereis_name(mgeed_dict_persistent) of
        undefined->
            ignore;
        PID->
            ReqList = [{delete,?DB_MINER_DATA_P, Key}],
            PID ! {store_queue, ReqList}
    end.

%%持久化标志，所有数据分10次进行持久化
get_persistent_rem_flag() ->
    case erlang:get(?MINE_FB_PERSISTENT_REM_FLAG) of
        IntFlag when is_integer(IntFlag) ->
            IntFlag;
        _ ->
            IntFlag = 0
    end,
    erlang:put(?MINE_FB_PERSISTENT_REM_FLAG, (IntFlag+1) rem 10),
    IntFlag.


