%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc 国战模块
%%%
%%% @end
%%% Created : 10 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_waroffaction).

%% API
-export([
         is_in_waroffaction/1,
		 is_in_waroffaction_dirty/2,
         check_in_waroffaction_time/0,
         handle/2,
         change_war_stage/0,
         add_waroffaction_npc_gongxun/2,
         get_waroffaction_stage/0,
         get_attack_faction_id/0,
         waroffaction_npc_dead/3,
         get_defence_faction_id/0,
         get_win_faction_id/0,
         get_lose_faction_id/0,
         write_waroffaction_record/2,
         send_waroffaction_count_down/2,
         hook_role_map_enter/1,
         get_waroffaction_declare_info/1,
         hook_role_online/2,
         get_waroffaction_start_time/1,
         init/1
        ]).

-export([
            test_declare_war/2,
            test_buy_guarder/2
        ]).

-include("mgeem.hrl").

-record(r_waroffaction_guarder_info, {type_id, silver, level, map_id, born_pos_list, key}).

-define(WAROFFACTION_ATTACK_FACTION_ID,waroffaction_attack_faction_id).
-define(WAROFFACTION_DEFENCE_FACTION_ID,waroffaction_defence_faction_id).

-define(WAROFFACTION_WIN_FACTION_ID,waroffaction_win_faction_id).
-define(WAROFFACTION_LOSE_FACTION_ID,waroffaction_lose_faction_id).

-define(CONVENE_TYPE_FACTION,1).
-define(CONVENE_TYPE_FAMILY,2).

-define(ROAD_BLOCK_TYPE,{waroffaction_guarder,10}).
-define(LEFT_GUARDER_TYPE,{waroffaction_guarder,1}).
-define(RIGHT_GUARDER_TYPE,{waroffaction_guarder,2}).

handle(Info, State) ->
    %?DEBUG("~ts ~w", ["收到消息", Info]),
    do_handle_info(Info, State).

%%获取国战信息
do_handle_info({Unique, ?WAROFFACTION, ?WAROFFACTION_WARINFO, DataIn, RoleID, _PID, Line}, _State) ->
    do_get_warinfo(DataIn,Line,RoleID,Unique);
%%宣战
do_handle_info({Unique, ?WAROFFACTION, ?WAROFFACTION_DECLARE, DataIn, RoleID, _PID, Line}, _State) ->
    Record = do_declare(DataIn, RoleID),
    %?ERROR_MSG(" $$$$$$$$$$$  ~w",[Record]),
    common_misc:unicast(Line, RoleID, Unique, ?WAROFFACTION, ?WAROFFACTION_DECLARE, Record);
%%购买守卫或设施等
do_handle_info({Unique, ?WAROFFACTION, ?WAROFFACTION_BUY_GUARDER, DataIn, RoleID, _PID, Line}, _State) ->
    do_buy_guader(Line, RoleID, Unique, DataIn);
%%查看国战记录
do_handle_info({Unique, ?WAROFFACTION, ?WAROFFACTION_RECORD, DataIn, RoleID, _PID, Line}, _State) ->
    do_get_record(Line, RoleID, Unique, DataIn);
%% 同意召集
do_handle_info({Unique, ?WAROFFACTION, ?WAROFFACTION_GATHER_CONFIRM, DataIn, RoleID, PID, _Line}, State) ->
    do_gather_confirm(Unique, ?WAROFFACTION, ?WAROFFACTION_GATHER_CONFIRM, RoleID, DataIn, PID, State);

do_handle_info({get_waroffaction_info,Record,Line,RoleID,Unique}, _State) ->
    LeftGuader = get(?LEFT_GUARDER_TYPE),
    RightGuarder = get(?RIGHT_GUARDER_TYPE),
    Record2 = Record#m_waroffaction_warinfo_toc{left_guarder_level = LeftGuader,right_guarder_level = RightGuarder},
    common_misc:unicast(Line, RoleID, Unique, ?WAROFFACTION, ?WAROFFACTION_WARINFO, Record2);
%%进入国战准备阶段
do_handle_info({begin_apply,AttackFactionID,DefenceFactionID}, _State) ->
    %?ERROR_MSG("war faction begin_apply ~w ~w",[AttackFactionID,DefenceFactionID]),
    do_war_apply(AttackFactionID,DefenceFactionID);
%%国战开始
do_handle_info({begin_war,AttackFactionID,DefenceFactionID}, _State) ->
    do_begin_war(AttackFactionID,DefenceFactionID);
%%国战时间结束，只发送到防守方的京城地图
do_handle_info(end_war_when_time_out, _State) ->
    do_end_war_when_time_out();
%%国战结束后发到防守方平江地图的消息
do_handle_info(waroffaction_end, _State) ->
    do_waroffaction_end();
%%国战第一阶段的循环广播，只发送到平江地图广播
do_handle_info({waroffaction_cycle_broadcast,AttackFactionID,DefenceFactionID}, _State) ->
    NowStage = get_waroffaction_stage(),
    case NowStage =:= ?WAROFFACTION_FIRST_STAGE orelse NowStage =:= ?WAROFFACTION_READY_STAGE of
        true ->
            do_waroffaction_cycle_broadcast(AttackFactionID,DefenceFactionID);
        _ ->
            ignore
    end;
do_handle_info({born_waroffaction_guarder_npc, Line, Unique, RoleID, FactionID, MapID, MapName, GuarderInfo, RoleName},_State) ->
    do_born_waroffaction_guarder_npc(Line, Unique, RoleID, FactionID, MapID, MapName, GuarderInfo, RoleName);
do_handle_info(waroffaction_tower_dead, _State) ->
    do_waroffaction_tower_dead();
do_handle_info(waroffaction_general_dead, _State) ->
    do_waroffaction_general_dead();
do_handle_info(waroffaction_flag_dead, _State) ->
    do_waroffaction_flag_dead();
do_handle_info(Info,_State) ->
    ?ERROR_MSG("unknown msg ~w",[Info]),
    ignore.


 
%%判断国战是否已经开始了
check_in_waroffaction_time() ->  
    case get(?WAROFFACTION_STAGE) of
        ?WAROFFACTION_FIRST_STAGE ->
            true;
        ?WAROFFACTION_SECOND_STAGE ->
            true;
        ?WAROFFACTION_THIRD_STAGE ->
            true;
        _ ->
            false
    end.


%%获取目前国战的阶段
get_waroffaction_stage() ->
    get(?WAROFFACTION_STAGE).

%%获取攻击方国家的ID
get_attack_faction_id() ->
    get(?WAROFFACTION_ATTACK_FACTION_ID).

%%获取防守方国家的ID
get_defence_faction_id() ->
    get(?WAROFFACTION_DEFENCE_FACTION_ID).

%%获取国战胜利的国家ID    
get_win_faction_id() ->
    erlang:get(?WAROFFACTION_WIN_FACTION_ID).

%%获取国战失败的国家ID    
get_lose_faction_id() ->
    erlang:get(?WAROFFACTION_LOSE_FACTION_ID).


%%国战阶段转变，自动根据当前的阶段转换到下一个阶段
change_war_stage() ->
    case get(?WAROFFACTION_STAGE) of
        undefined ->
            set_war_stage(?WAROFFACTION_READY_STAGE);
        ?WAROFFACTION_READY_STAGE ->
            set_war_stage(?WAROFFACTION_FIRST_STAGE);
        ?WAROFFACTION_FIRST_STAGE ->
            set_war_stage(?WAROFFACTION_SECOND_STAGE);
        ?WAROFFACTION_SECOND_STAGE ->
            set_war_stage(?WAROFFACTION_THIRD_STAGE);
        ?WAROFFACTION_THIRD_STAGE ->
            set_war_stage(?WAROFFACTION_END_STAGE);
        ?WAROFFACTION_END_STAGE ->
            erase(?WAROFFACTION_STAGE)
    end. 

set_war_stage(Stage) ->
    put(?WAROFFACTION_STAGE,Stage).

do_get_warinfo(_DataIn,Line,RoleID,Unique) ->
    %?ERROR_MSG("do_get_warinfo $$$$$$$$",[]),
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        undefined ->
            ignore;
        MapInfo ->
            FactionID = MapInfo#p_map_role.faction_id,
            
            {Silver,MaxGuarderLevel,DeclareFlag1,DeclareFlag2,WarTime,IsAttackFaction,DestFactionID} = get_warinfo2(FactionID),
            RoadBlock = get(?ROAD_BLOCK_TYPE),       
            Record = #m_waroffaction_warinfo_toc{faction_id = FactionID, 
                                                 dest_faction_id= DestFactionID,
                                                 next_war_tick = WarTime,
                                                 is_attack_faction = IsAttackFaction,
                                                 declare_war1 = DeclareFlag1,
                                                 declare_war2 = DeclareFlag2,
                                                 silver = Silver,
                                                 max_guarder_level = MaxGuarderLevel,
                                                 road_block = RoadBlock},
            PingJiangMapName = get_pingjiang_map_name_by_factionid(FactionID),
            global:send(PingJiangMapName,{mod_waroffaction,{get_waroffaction_info,Record,Line,RoleID,Unique}})
    end.


get_warinfo2(FactionID) ->
    [FactionInfo] = db:dirty_read(?DB_FACTION,FactionID),
    Silver = FactionInfo#p_faction.silver,
    MaxGuarderLevel = FactionInfo#p_faction.guarder_level,
    {Year,Month,Day} = date(),
    NowDay = calendar:date_to_gregorian_days(Year,Month,Day),
    LastAttackDay = FactionInfo#p_faction.last_attack_day,
    LastDefenceDay = FactionInfo#p_faction.last_defence_day,
    [DestFactionID1,DestFactionID2] = lists:delete(FactionID,[1,2,3]),
    [DestFactionInfo1] = db:dirty_read(?DB_FACTION,DestFactionID1),
    [DestFactionInfo2] = db:dirty_read(?DB_FACTION,DestFactionID2),
    {WarTime,IsAttackFaction,DestFactionID} = get_war_time(LastAttackDay,LastDefenceDay,NowDay,Year,Month,Day,DestFactionInfo1,DestFactionInfo2),
    %?ERROR_MSG("44444444444444444   ~w",[DestFactionID]),
    case (LastAttackDay =:= undefined orelse NowDay - LastAttackDay >= 3)
         andalso (LastDefenceDay =:= undefined orelse NowDay - LastDefenceDay >= 1) of
        true ->
            case (DestFactionInfo1#p_faction.last_defence_day =:= undefined orelse NowDay - DestFactionInfo1#p_faction.last_defence_day >= 1)
                andalso (DestFactionInfo1#p_faction.last_attack_day =:= undefined orelse NowDay - DestFactionInfo1#p_faction.last_attack_day >= 1) of
                true ->
                    DeclareFlag1 = true;
                false ->
                    DeclareFlag1 = false
            end,
            case (DestFactionInfo2#p_faction.last_defence_day =:= undefined orelse NowDay - DestFactionInfo2#p_faction.last_defence_day >= 1)
                andalso (DestFactionInfo2#p_faction.last_attack_day =:= undefined orelse NowDay - DestFactionInfo2#p_faction.last_attack_day >= 1) of
                true ->
                    DeclareFlag2 = true;
                false ->
                    DeclareFlag2 = false
            end;
        false ->
            DeclareFlag1 = false,
            DeclareFlag2 = false
    end,
    {Silver,MaxGuarderLevel,DeclareFlag1,DeclareFlag2,WarTime,IsAttackFaction,DestFactionID}.
                    
get_war_time(LastAttackDay,LastDefenceDay,NowDay,Year,Month,Day,DestFactionInfo1,DestFactionInfo2) ->
    {H,_M,_S} = time(),
    case LastAttackDay =:= NowDay - 1 of
        true ->
            case H < 20 of
                true ->
                    LastDefenceDay1 = DestFactionInfo1#p_faction.last_defence_day,
                    LastDefenceDay2 = DestFactionInfo2#p_faction.last_defence_day,
                    case LastAttackDay of
                        LastDefenceDay1 ->
                            DestFactionID = DestFactionInfo1#p_faction.faction_id;
                        LastDefenceDay2 ->
                            DestFactionID = DestFactionInfo2#p_faction.faction_id;
                        _ ->
                            DestFactionID = undefined
                    end,
                    {common_tool:datetime_to_seconds({{Year,Month,Day},{20,0,0}}),true,DestFactionID};
                false ->
                    {0,false,undefined}
            end;
        false ->
            case LastDefenceDay =:= NowDay - 1 of
                true ->
                    case H < 20 of
                        true ->
                            LastAttackDay1 = DestFactionInfo1#p_faction.last_attack_day,
                            LastAttackDay2 = DestFactionInfo2#p_faction.last_attack_day,
                            case LastDefenceDay of
                                LastAttackDay1 ->
                                    DestFactionID = DestFactionInfo1#p_faction.faction_id;
                                LastAttackDay2 ->
                                    DestFactionID = DestFactionInfo2#p_faction.faction_id;
                                _ ->
                                    DestFactionID = undefined
                            end,
                            {common_tool:datetime_to_seconds({{Year,Month,Day},{20,0,0}}),false,DestFactionID};
                        false ->
                            {0,false,undefined}
                    end;
                false ->
                    case LastAttackDay =:= NowDay of
                        true ->
                            %%明天的19点半开始，所以用今天的日期加上一天的秒数，防止跨月甚至跨年
                            LastDefenceDay1 = DestFactionInfo1#p_faction.last_defence_day,
                            LastDefenceDay2 = DestFactionInfo2#p_faction.last_defence_day,
                            case LastAttackDay of
                                LastDefenceDay1 ->
                                    DestFactionID = DestFactionInfo1#p_faction.faction_id;
                                LastDefenceDay2 ->
                                    DestFactionID = DestFactionInfo2#p_faction.faction_id;
                                _ ->
                                    DestFactionID = undefined
                            end,
                            {common_tool:datetime_to_seconds({{Year,Month,Day},{20,0,0}}) + 24*60*60, true, DestFactionID};
                        false ->
                            case LastDefenceDay =:= NowDay of
                                true ->
                                    LastAttackDay1 = DestFactionInfo1#p_faction.last_attack_day,
                                    LastAttackDay2 = DestFactionInfo2#p_faction.last_attack_day,
                                    case LastDefenceDay of
                                        LastAttackDay1 ->
                                            DestFactionID = DestFactionInfo1#p_faction.faction_id;
                                        LastAttackDay2 ->
                                            DestFactionID = DestFactionInfo2#p_faction.faction_id;
                                        _ ->
                                            DestFactionID = undefined
                                    end,
                                    {common_tool:datetime_to_seconds({{Year,Month,Day},{20,0,0}}) + 24*60*60, false, DestFactionID};
                                false ->
                                    {0,false,undefined}
                            end
                    end
            end
    end.

%%进入国战准备阶段
do_war_apply(AttackFactionID,DefenceFactionID) ->
    db:dirty_write(?DB_WAROFFACTION,#r_waroffaction{key=1,war_status=?WAROFFACTION_READY_STAGE, attack_faction_id=AttackFactionID,defence_faction_id=DefenceFactionID}),
    set_war_stage(?WAROFFACTION_READY_STAGE),
    erlang:put(?WAROFFACTION_ATTACK_FACTION_ID,AttackFactionID),
    erlang:put(?WAROFFACTION_DEFENCE_FACTION_ID,DefenceFactionID),
    
    waroffaction_server_npc_born(),
    
    case check_map_is_pingjiang(mgeem_map:get_mapid()) of
        true ->
            erlang:send_after(5*60*1000,self(),{mod_waroffaction,{waroffaction_cycle_broadcast,AttackFactionID,DefenceFactionID}});
        false ->
            DefenceFactionName = get_faction_name_by_id(DefenceFactionID),
            AttackFactionName = get_faction_name_by_id(AttackFactionID),
            Content = common_tool:to_list(AttackFactionName) ++ "将于20:00开始进攻" ++ common_tool:to_list(DefenceFactionName) ++ "，请广大势力成员做好战争准备，\\n国战胜利的所有势力成员获得2个小时的双倍经验时间。",
            common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_WORLD,common_tool:to_list(Content)),
            broadcast_count_down_info(AttackFactionID,DefenceFactionID,1,"平江哨塔")
    end,
    ok.


%%根据当前地图的ID检查当前地图有关国战的NPC是否存在，平江检查箭塔，京城检查张将军和国旗
waroffaction_server_npc_born() ->
    MapState = mgeem_map:get_state(),
    MapID = MapState#map_state.mapid,
    List = get_waroffaction_npc_typeid_list(MapID),
    NpcIDList = mod_server_npc:get_server_npc_id_list(),
%%       ?ERROR_MSG("2222222222222,~w",[{NpcIDList}]),
    lists:foreach(
      fun(NpcTypeID) ->
              Ret = lists:foldl(
                    fun(NpcID,Acc) ->
                        case Acc of
                            error ->
                                NpcState = mod_server_npc:get_server_npc_state(NpcID),
                                NpcInfo = NpcState#server_npc_state.server_npc_info,
                                case NpcTypeID =:= NpcInfo#p_server_npc.type_id of
                                    true ->
                                        reborn_war_npc_when_dead(NpcState);
                                    false ->
                                        Acc
                                end;
                            _ ->
                                Acc
                        end
                end,error,NpcIDList),
              case Ret of
                  error ->
%%                       ?ERROR_MSG("444444444444,~w",[{NpcTypeID,MapID}]),
                      born_waroffaction_server_npc(NpcTypeID,MapID);
                  _ ->
                      ignore
              end
      end,List).
        
%%复活被杀死的国战NPC,设置为马上复活
reborn_war_npc_when_dead(NpcState) ->
    NpcInfo = NpcState#server_npc_state.server_npc_info,
    case NpcInfo#p_server_npc.state =:= ?DEAD_STATE of
        true ->
            Now = common_tool:now2(),
            mod_server_npc:update_next_work(NpcInfo#p_server_npc.npc_id,Now,loop,NpcState#server_npc_state{deadtime=undefined}),
            ok;
        false ->
            ok
    end.
  

%%重生国战流程需要的NPC
born_waroffaction_server_npc(GuarderTypeID,MapID) ->
    [GuarderInfo] = common_config_dyn:find(waroffaction_guarder,GuarderTypeID),
    [{Tx,Ty,Dir}] = GuarderInfo#r_waroffaction_guarder_info.born_pos_list,
%%      ?ERROR_MSG("555555555555555,~w",[GuarderInfo]),
    [NpcBaseInfo] = common_config_dyn:find(server_npc, GuarderTypeID),
    Pos = #p_pos{tx = Tx,ty = Ty,dir = Dir},
    ServerNpcInfo = #p_server_npc{
                                  %% 使用怪物的id
                                  npc_id = mod_map_monster:get_max_monster_id_form_process_dict(),
                                  type_id = NpcBaseInfo#p_server_npc_base_info.type_id,
                                  npc_name = NpcBaseInfo#p_server_npc_base_info.npc_name,
                                  npc_type = NpcBaseInfo#p_server_npc_base_info.npc_type,
                                  max_mp= NpcBaseInfo#p_server_npc_base_info.max_mp,
                                  state = ?DEAD_STATE,
                                  max_hp = NpcBaseInfo#p_server_npc_base_info.max_hp,
                                  map_id = MapID,
                                  reborn_pos = Pos,
                                  level= NpcBaseInfo#p_server_npc_base_info.level,
                                  npc_country = NpcBaseInfo#p_server_npc_base_info.npc_country,
                                  is_undead = NpcBaseInfo#p_server_npc_base_info.is_undead,
                                  move_speed = NpcBaseInfo#p_server_npc_base_info.move_speed
                                 },
    MapName = common_map:get_common_map_name(MapID),
    mod_server_npc:init_map_server_npc(MapName, MapID, [ServerNpcInfo]),
%%       ?ERROR_MSG("66666666666666666,~w",[ServerNpcInfo]),
    ok.
  

%%根据地图ID获取国战相关的NPC（包括瞭望塔，将军和国旗）
get_waroffaction_npc_typeid_list(MapID) ->
    case MapID of
        10260 ->
            [get_genernal_typeid_by_mapid(MapID),21202001];   %%蚩尤京城张将军和国旗
        _ ->
              []
    end.


get_genernal_typeid_by_mapid(MapID) ->
    case get({genernal_typeid,MapID}) of
        undefined ->
            Level = get_waroffaction_npc_level_by_server_start_time(),
            [TypeID] = common_config_dyn:find(waroffaction_etc,{genernal_typeid,MapID,Level}),
            put({genernal_typeid,MapID},TypeID),
            TypeID;
        TypeID ->
            TypeID
    end.


% get_tower_typeid_by_mapid(MapID) ->
%     case get({tower_typeid,MapID}) of
%         undefined ->
%             Level = get_waroffaction_npc_level_by_server_start_time(),
%             [TypeID] = common_config_dyn:find(waroffaction_etc,{genernal_typeid,MapID,Level}),
%             put({tower_typeid,MapID},TypeID),
%             TypeID;
%         TypeID ->
%             TypeID
%     end.



get_waroffaction_npc_level_by_server_start_time() ->
    [{{Year,Month,Day},_}] = common_config_dyn:find_common(server_start_datetime),
    IntervalDays = calendar:date_to_gregorian_days(date()) - calendar:date_to_gregorian_days({Year,Month,Day}),
    case IntervalDays =< 7 of
        true ->
            Level = 1;
        false ->
            case IntervalDays =< 14 of
                true ->
                    Level = 2;
                false ->
                    Level = 3
            end
    end,
    Level.


%%国战正式开始开始进入第一阶段
do_begin_war(AttackFactionID,DefenceFactionID) ->
    set_war_stage(?WAROFFACTION_FIRST_STAGE),
    erlang:put(?WAROFFACTION_ATTACK_FACTION_ID,AttackFactionID),
    erlang:put(?WAROFFACTION_DEFENCE_FACTION_ID,DefenceFactionID),
    case db:dirty_read(?DB_WAROFFACTION,1) of
        [] ->
            ?ERROR_MSG("r_waroffaction error,no data",[]),
             db:dirty_write(?DB_WAROFFACTION,#r_waroffaction{key=1,war_status=?WAROFFACTION_FIRST_STAGE, attack_faction_id=AttackFactionID,defence_faction_id=DefenceFactionID});
        [Info] ->
            db:dirty_write(?DB_WAROFFACTION,Info#r_waroffaction{war_status=?WAROFFACTION_FIRST_STAGE})
    end,
    MapState = mgeem_map:get_state(),
    MapID = MapState#map_state.mapid,
    case check_map_is_pingjiang(MapID) of
        true ->
            set_tower_can_attack(MapID);
        false ->
            AttackFactionID = get_attack_faction_id(),
            DefenceFactionID = get_defence_faction_id(),
            %?ERROR_MSG("######   ~w  ~w",[AttackFactionID,DefenceFactionID]),
            broadcast_count_down_info(AttackFactionID,DefenceFactionID,2,"平江哨塔")
    end,
    ok.


%%设置平江的瞭望塔为可攻击
set_tower_can_attack(MapID) ->
    NpcTypeIDList = get_waroffaction_npc_typeid_list(MapID),
    set_npc_undead_state(NpcTypeIDList,false).
   
%%设置京城的将军为可攻击
set_general_can_attack() ->
     DefenceFactionID = get_defence_faction_id(),
     GeneralID = get_general_npc_type_id(DefenceFactionID),
     set_npc_undead_state([GeneralID],false).
%%设置京城的国旗为可攻击
set_faction_flag_can_attack() ->
    DefenceFactionID = get_defence_faction_id(),
    FactionFlagID = get_faction_flag_npc_type_id(DefenceFactionID),
    set_npc_undead_state([FactionFlagID],false).  
%%判断是不是平江
check_map_is_pingjiang(MapID) ->
    MapID =:= 10261.
%%根据国家ID获取将军的type_id
get_general_npc_type_id(_FactionID) ->
    get_genernal_typeid_by_mapid(10260).
%%根据国家ID获取国旗的type_id
get_faction_flag_npc_type_id(FactionID) ->
    case FactionID of
        1 -> 21202001;
        2 -> 22202001;
        3 -> 23202001
    end.


%%设置为可攻击状态
set_npc_undead_state(NpcTypeIDList,DeadFlag) when is_list(NpcTypeIDList) ->
    NpcIDList = mod_server_npc:get_server_npc_id_list(),
    lists:foreach(
      fun(NpcID) ->
              NpcState = mod_server_npc:get_server_npc_state(NpcID),
              NpcInfo = NpcState#server_npc_state.server_npc_info,
              case lists:member(NpcInfo#p_server_npc.type_id, NpcTypeIDList) of
                  true ->
                      set_npc_undead_state(NpcState,DeadFlag);
                  false ->
                      ignore
              end
      end,NpcIDList);
set_npc_undead_state(NpcState,DeadFlag) ->
    NewNpcInfo = (NpcState#server_npc_state.server_npc_info)#p_server_npc{is_undead=DeadFlag},
    NewNpcState = NpcState#server_npc_state{server_npc_info=NewNpcInfo},
    case mod_map_actor:get_actor_mapinfo(NewNpcInfo#p_server_npc.npc_id,server_npc) of
        undefined ->
            ignore;
        NpcMapinfo ->
            mod_map_actor:set_actor_mapinfo(NewNpcInfo#p_server_npc.npc_id,server_npc, NpcMapinfo#p_map_server_npc{is_undead=DeadFlag})
    end,
    mod_server_npc:set_server_npc_state(NewNpcInfo#p_server_npc.npc_id,NewNpcState).
  

%%国战期间,当影响国战进程的NPC死亡时的逻辑处理
waroffaction_npc_dead(NpcTypeID,_NpcID,RoleID) ->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        undefind ->
            RoleName = "";
        RoleMapInfo ->
            RoleName = RoleMapInfo#p_map_role.role_name
    end,
    MapID = mgeem_map:get_mapid(),
    TypeIDList = get_waroffaction_npc_typeid_list(MapID),
    case lists:member(NpcTypeID,TypeIDList) of
        true ->
            DefenceFactionID = get_defence_faction_id(),
            GeneralID = get_general_npc_type_id(DefenceFactionID),
            FactionFlagID = get_faction_flag_npc_type_id(DefenceFactionID),
            case NpcTypeID of
                GeneralID ->
                    general_dead(RoleName);
                FactionFlagID ->
                    faction_flag_dead(RoleName);
                _ ->
                    tower_dead(RoleName)
            end;
        false ->
            ignore
    end.


%%瞭望塔被摧毁时逻辑处理
tower_dead(_RoleName) ->
    AttackFactionID = get_attack_faction_id(),
    DefenceFactionID = get_defence_faction_id(),
    JingChengMapName = get_jingcheng_map_name_by_factionid(DefenceFactionID),
    set_war_stage(?WAROFFACTION_SECOND_STAGE),
    DefenceFactionName = get_faction_name_by_id(DefenceFactionID),
    AttackContent = DefenceFactionName ++ "平江哨塔已被摧毁，大家攻进" ++ DefenceFactionName ++ "京城，\\n击杀敌方禁卫将军，夺取下一阶段的胜利！",
    DefenceContent = "平江哨塔已被摧毁，请大家做好防御措施，保护禁卫将军！",
    common_broadcast:bc_send_msg_faction(AttackFactionID,[?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_COUNTRY,common_tool:to_list(AttackContent)),
    common_broadcast:bc_send_msg_faction(DefenceFactionID,[?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_COUNTRY,DefenceContent),
    global:send(JingChengMapName, {mod_waroffaction,waroffaction_tower_dead}).
     


%% %%判断是否所有的瞭望塔都被摧毁
%% check_no_tower_left(NpcID,TypeIDList) ->
%%     NpcIDList = mod_server_npc:get_server_npc_id_list(),
%%     lists:foldr(
%%       fun(NpcID2,Acc) ->
%%               case Acc =:= true orelse NpcID2 =:= NpcID of
%%                   true ->
%%                       Acc;
%%                   false ->
%%                       NpcState = mod_server_npc:get_server_npc_state(NpcID),
%%                       NpcInfo = NpcState#server_npc_state.server_npc_info,
%%                       lists:member(NpcInfo#p_server_npc.type_id, TypeIDList)  
%%               end
%%       end,false,NpcIDList).


%%京城收到平江瞭望塔全部摧毁的消息
do_waroffaction_tower_dead() ->
    set_war_stage(?WAROFFACTION_SECOND_STAGE),
    set_general_can_attack(),
    AttackFactionID = get_attack_faction_id(),
    DefenceFactionID = get_defence_faction_id(),
    case db:dirty_read(?DB_WAROFFACTION,1) of
        [] ->
            ?ERROR_MSG("r_waroffaction error,no data",[]),
            db:dirty_write(?DB_WAROFFACTION,#r_waroffaction{key=1,war_status=?WAROFFACTION_SECOND_STAGE, attack_faction_id=AttackFactionID,defence_faction_id=DefenceFactionID});
        [Info] ->
            db:dirty_write(?DB_WAROFFACTION,Info#r_waroffaction{war_status=?WAROFFACTION_SECOND_STAGE})
    end,
    broadcast_count_down_info(AttackFactionID,DefenceFactionID,2,"禁卫将军"),
    ok.


%%将军被杀的时候的逻辑处理
general_dead(RoleName) ->
    set_faction_flag_can_attack(),
    AttackFactionID = get_attack_faction_id(),
    DefenceFactionID = get_defence_faction_id(),
    PingJiangMapName = get_pingjiang_map_name_by_factionid(DefenceFactionID),
    set_war_stage(?WAROFFACTION_THIRD_STAGE),
    broadcast_count_down_info(AttackFactionID,DefenceFactionID,2,"国旗"),
    case db:dirty_read(?DB_WAROFFACTION,1) of
        [] ->
            ?ERROR_MSG("r_waroffaction error,no data",[]),
            db:dirty_write(?DB_WAROFFACTION,#r_waroffaction{key=1,war_status=?WAROFFACTION_THIRD_STAGE, attack_faction_id=AttackFactionID,defence_faction_id=DefenceFactionID});
        [Info] ->
            db:dirty_write(?DB_WAROFFACTION,Info#r_waroffaction{war_status=?WAROFFACTION_THIRD_STAGE})
    end,
    DefenceFactionName = get_faction_name_by_id(DefenceFactionID),
    AttackFactionName = get_faction_name_by_id(AttackFactionID),
    AttackContent = DefenceFactionName ++ "禁卫将军已被我国勇士<font color=\"#FFFF00\">[" ++ common_tool:to_list(RoleName) ++ "]</font>击杀，胜利就在眼前，\\n请大家攻入京城王宫，摧毁" ++ DefenceFactionName ++ "国旗，夺取最终的胜利。",
    DefenceContent = "禁卫将军已被敌对势力玩家击杀，请所有势力成员坚守最后的防线，阻止" ++ AttackFactionName ++ "摧毁国 旗。",
    common_broadcast:bc_send_msg_faction(AttackFactionID,[?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_COUNTRY,common_tool:to_list(AttackContent)),
    common_broadcast:bc_send_msg_faction(DefenceFactionID,[?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_COUNTRY,DefenceContent),
    global:send(PingJiangMapName, {mod_waroffaction,waroffaction_general_dead}),
    ok.

%%平江收到将军被杀的时候的逻辑处理
do_waroffaction_general_dead() ->
    set_war_stage(?WAROFFACTION_THIRD_STAGE).


%%国旗被砍以后的逻辑处理
faction_flag_dead(RoleName) ->
    end_war_when_national_flag_down(),
    AttackFactionID = get_attack_faction_id(),
    DefenceFactionID = get_defence_faction_id(),
    PingJiangMapName = get_pingjiang_map_name_by_factionid(DefenceFactionID),
    set_war_stage(?WAROFFACTION_END_STAGE),
    DefenceFactionName = get_faction_name_by_id(DefenceFactionID),
    AttackContent = DefenceFactionName ++ "国旗被<font color=\"#FFFF00\">[" ++ common_tool:to_list(RoleName) ++ "]</font>摧毁，我国获得本次国战胜利，\\n所有势力成员获得2个小时的双倍经验时间！" ,
    DefenceContent = "虽然大家英勇奋战，但是无奈敌对势力实力太强，本次国战失败，\\n希望大家知耻而后勇，下次国战的时候一雪前耻!",
    common_broadcast:bc_send_msg_faction(AttackFactionID,[?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_COUNTRY,common_tool:to_list(AttackContent)),
    common_broadcast:bc_send_msg_faction(DefenceFactionID,[?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_COUNTRY,common_tool:to_list(DefenceContent)),
    broadcast_count_down_info(AttackFactionID,DefenceFactionID,3,""),
    db:dirty_delete(?DB_WAROFFACTION,1),
    global:send(PingJiangMapName, {mod_waroffaction,waroffaction_flag_dead}),
    ok.


%%平江收到国旗被砍倒的时候的逻辑处理
do_waroffaction_flag_dead() ->
    broadcast_back_faction_msg(),
    ok.


%%砍倒守方旗子，结束国战
end_war_when_national_flag_down() ->
    AttackFactionID = erlang:get(?WAROFFACTION_ATTACK_FACTION_ID),
    DefenceFactionID = erlang:get(?WAROFFACTION_DEFENCE_FACTION_ID),
    erlang:put(?WAROFFACTION_WIN_FACTION_ID,AttackFactionID),
    erlang:put(?WAROFFACTION_LOSE_FACTION_ID,DefenceFactionID),
    DefenceFactionName = get_faction_name_by_id(DefenceFactionID),
    AttackRecord = "我国成功摧毁" ++ DefenceFactionName ++ "国旗，本次国战胜利", 
    write_waroffaction_record(AttackFactionID,AttackRecord),
    AttackFactionName = get_faction_name_by_id(AttackFactionID),
    DefenceRecord = "我国未能抵挡" ++ AttackFactionName ++"的进攻，本次国战失败",
    write_waroffaction_record(DefenceFactionID,DefenceRecord),
    war_over(AttackFactionID,DefenceFactionID,AttackFactionID),
    ok.

%%国战时间到，结束国战
do_end_war_when_time_out() ->
    case erlang:get(?WAROFFACTION_WIN_FACTION_ID) of
        undefined ->
            AttackFactionID = erlang:get(?WAROFFACTION_ATTACK_FACTION_ID),
            DefenceFactionID = erlang:get(?WAROFFACTION_DEFENCE_FACTION_ID),
            erlang:put(?WAROFFACTION_WIN_FACTION_ID,DefenceFactionID),
            erlang:put(?WAROFFACTION_LOSE_FACTION_ID,AttackFactionID),
            DefenceFactionName = get_faction_name_by_id(DefenceFactionID),
            AttackRecord = "由于遭遇顽强抵抗，我国未能摧毁" ++ DefenceFactionName ++ "国旗，本次国战失败", 
            write_waroffaction_record(AttackFactionID,AttackRecord),
            AttackFactionName = get_faction_name_by_id(AttackFactionID),
            DefenceRecord = "感谢大家的英勇奋战，" ++ AttackFactionName ++"国的入侵未能得逞，我国所有势力成员获得2个小时的双倍经验时间。",
            write_waroffaction_record(DefenceFactionID,common_tool:to_list(DefenceRecord)),
            common_broadcast:bc_send_msg_faction(AttackFactionID,[?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_COUNTRY,AttackRecord),
            common_broadcast:bc_send_msg_faction(DefenceFactionID,[?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_COUNTRY,DefenceRecord),
            war_over(AttackFactionID,DefenceFactionID,DefenceFactionID);
        _ ->
            DefenceFactionID = erlang:get(?WAROFFACTION_DEFENCE_FACTION_ID)
    end,
    PingJiangMapName = get_pingjiang_map_name_by_factionid(DefenceFactionID),
    catch global:send(PingJiangMapName,{mod_waroffaction,waroffaction_end}),
    war_over_when_time_out2(),
    ok.


war_over_when_time_out2() ->
    reset_war_server_npc(),
    clear_waroffaction_guarder(),
    db:dirty_delete(?DB_WAROFFACTION,1),
    erlang:erase(?WAROFFACTION_ATTACK_FACTION_ID),
    erlang:erase(?WAROFFACTION_DEFENCE_FACTION_ID),
    erlang:erase(?WAROFFACTION_WIN_FACTION_ID),
    erlang:erase(?WAROFFACTION_LOSE_FACTION_ID),
    erlang:erase(?ROAD_BLOCK_TYPE),
    erlang:erase(?LEFT_GUARDER_TYPE),
    erlang:erase(?RIGHT_GUARDER_TYPE),
    erlang:erase(?WAROFFACTION_STAGE).


%%杀死国战时的NPC后根据目标类型计算国战期间的功勋
add_waroffaction_npc_gongxun(AttackRoleID, NpcTypeID) ->
    [ServerNpcBaseInfo] = common_config_dyn:find(server_npc,NpcTypeID),  
    {ok, #p_role_base{faction_id=RoleFactionID,family_id=FamilyID}}  = mod_map_role:get_role_base(AttackRoleID),
    AttackFactionID = get(?WAROFFACTION_ATTACK_FACTION_ID),
    case RoleFactionID =:= AttackFactionID of
        true ->
            case ServerNpcBaseInfo#p_server_npc_base_info.gongxun of
                0 ->
                    ignore;
                GongXun ->
                    RoleIDList = mod_map_actor:get_in_map_role(),
                    common_family:info(FamilyID, {add_gongxun, GongXun}),
                    lists:foreach(
                      fun(RoleID) ->
                              case mod_map_actor:get_actor_mapinfo(RoleID,role) of
                                  undefined ->
                                      ignore;
                                  #p_map_role{faction_id=FactionID} when FactionID =:= AttackFactionID->
                                       mod_gongxun:add_gongxun(RoleID, GongXun);
                                  _ ->
                                      ignore
                              end
                      end,RoleIDList)
            end;
        false ->
            ignore
    end.


send_waroffaction_count_down(RoleID,FactionID) ->
     case db:dirty_read(?DB_WAROFFACTION, 1) of
        [] ->
            ignore;
        [#r_waroffaction{attack_faction_id=AFactionID, defence_faction_id=DFactionID, war_status=Stage}] ->
            case FactionID =:= AFactionID orelse FactionID =:= DFactionID of
                true ->
                    {H,M,S} = time(),
                    case Stage of
                        ?WAROFFACTION_READY_STAGE ->
                            Type = 1,
                            Seconds = (59 - M) * 60 + 60-S,
                            Target = "平江哨塔";
                        ?WAROFFACTION_FIRST_STAGE ->
                            Type = 2,
                            Seconds = (20-H) * 60 * 60 + (59 - M) * 60 + 60-S,
                            Target = "平江哨塔";
                        ?WAROFFACTION_SECOND_STAGE ->
                            Type = 2,
                            Seconds = (20-H) * 60 * 60 + (59 - M) * 60 + 60-S,
                            Target = "禁卫将军";
                        ?WAROFFACTION_THIRD_STAGE ->
                            Type = 2,
                            Seconds = (20-H) * 60 * 60 + (59 - M) * 60 + 60-S,
                            Target = "国旗"
                    end,
                    case Target of
                        [] ->
                            Target2 = [];
                        _ ->
                            DefenceFactionName = common_misc:get_faction_name(DFactionID),
                            Target2 = io_lib:format("~s~s", [DefenceFactionName, Target])
                    end,
                    Record = #m_waroffaction_count_down_toc{attack_faction_id=AFactionID, defence_faction_id=DFactionID,
                                                            type=Type,tick=Seconds,current_target=Target2},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFFACTION, ?WAROFFACTION_COUNT_DOWN, Record),
                    ok;
                false ->
                    ignore
            end     
    end.


broadcast_count_down_info(AttackFactionID,DefenceFactionID,Type,Target) ->
    {H,M,S} = time(),
    case Type of
        1 ->
            Seconds = (59 - M) * 60 + 60-S;
        2 ->
            Seconds = (20-H) * 60 * 60 + (59 - M) * 60 + 60-S;
        _ ->
            Seconds = 0
    end,
    case Target of
        [] ->
            Target2 = [];
        _ ->
            DefenceFactionName = common_misc:get_faction_name(DefenceFactionID),
            Target2 = io_lib:format("~s~s", [DefenceFactionName, Target])
    end,
    Record = #m_waroffaction_count_down_toc{attack_faction_id=AttackFactionID, defence_faction_id=DefenceFactionID,
                                            type=Type,tick=Seconds,current_target=Target2},
    common_misc:chat_broadcast_to_faction(AttackFactionID, ?WAROFFACTION, ?WAROFFACTION_COUNT_DOWN, Record),
    common_misc:chat_broadcast_to_faction(DefenceFactionID, ?WAROFFACTION, ?WAROFFACTION_COUNT_DOWN, Record).
    %?ERROR_MSG("############  ~w",[Record]).
     
%%=============LOCAL FUNCTION============================

%%国战宣战
do_declare(DataIn, RoleID) ->
    case calendar:day_of_the_week(date()) of
        5 ->
            #m_waroffaction_declare_toc{succ=false,reason=?_LANG_WAROFFACTION_CAN_NOT_DECLARE_ON_FRIDAY};
        _ ->
            #m_waroffaction_declare_tos{defence_faction_id = DefenceFactionID} = DataIn,
            case mod_map_actor:get_actor_mapinfo(RoleID,role) of
                undefined ->
                    #m_waroffaction_declare_toc{succ=false,reason=?_LANG_SYSTEM_ERROR};
                RoleMapInfo ->
                    #p_map_role{faction_id = AttackFactionID} = RoleMapInfo,
                    case db:dirty_read(?DB_FACTION,AttackFactionID) of
                        [] ->
                            #m_waroffaction_declare_toc{succ=false,reason=?_LANG_SYSTEM_ERROR};
                        [AttackFactionInfo] ->
                            NowDay = calendar:date_to_gregorian_days(date()),
                            %%自己宣战以后3天内不能再宣战，被宣战的当天也不能宣战
                            case (AttackFactionInfo#p_faction.last_attack_day =:= undefined orelse NowDay - AttackFactionInfo#p_faction.last_attack_day >= 3)
                                     andalso (AttackFactionInfo#p_faction.last_defence_day =:= undefined orelse NowDay - AttackFactionInfo#p_faction.last_defence_day >= 2) of
                                false ->
                                    #m_waroffaction_declare_toc{succ=false,reason=?_LANG_WAROFFACTION_DECLARE_DAY_LESS_THAN_SEVEN};
                                true ->
                                    do_declare2(RoleID, AttackFactionID, DefenceFactionID, RoleMapInfo, NowDay, AttackFactionInfo)
                            end
                    end
            end
    end.


do_declare2(RoleID, AttackFactionID, DefenceFactionID, RoleMapInfo, NowDay, AttackFactionInfo) ->  
    case db:dirty_read(?DB_FACTION,DefenceFactionID) of
        [] ->
            #m_waroffaction_declare_toc{succ=false,reason=?_LANG_SYSTEM_ERROR};
        [DefenceFactionInfo] ->
            case (DefenceFactionInfo#p_faction.last_defence_day =:= undefined orelse NowDay - DefenceFactionInfo#p_faction.last_defence_day >= 2)
                    andalso (DefenceFactionInfo#p_faction.last_attack_day =:= undefined orelse NowDay - DefenceFactionInfo#p_faction.last_attack_day >= 1) of
                false ->
                    #m_waroffaction_declare_toc{succ=false,reason=?_LANG_WAROFFACTION_DEFENCE_DAY_LESS_THAN_THREE};
                true ->
                    OfficeInfo = AttackFactionInfo#p_faction.office_info,
                    
                    %%判断宣战的玩家是否是国王或者天纵神将
                    case OfficeInfo#p_office.king_role_id =:= RoleID orelse 
                                                 common_office:get_general_roleid(OfficeInfo#p_office.offices) =:= RoleID of
                        true ->
                            do_declare3(RoleID, AttackFactionID, DefenceFactionID, RoleMapInfo, NowDay, AttackFactionInfo,DefenceFactionInfo);
                        false ->
                            #m_waroffaction_declare_toc{succ=false,reason=?_LANG_WAROFFACTION_DECLARE_NOT_ENOUGH_RIGHT}
                    end
            end
    end.


do_declare3(RoleID, AttackFactionID, DefenceFactionID, RoleMapInfo, _NowDay, AttackFactionInfo,_DefenceFactionInfo) ->
    %%国战宣战费10锭钱币
    case AttackFactionInfo#p_faction.silver < 100000 of
        true ->
            #m_waroffaction_declare_toc{succ=false,reason=?_LANG_WAROFFACTION_FACTION_SILVER_NOT_ENOUGH};
        false ->
            case decute_faction_silver(AttackFactionID,100000) of
                {ok,NewSilver} ->
                    %% 宣战纪录
                    common_misc:set_event_state({waroffaction_declare, AttackFactionID}, {DefenceFactionID, calendar:local_time()}),
                    global:send(mgeew_event, {mod_event_waroffaction, {declare_war, AttackFactionID, DefenceFactionID, RoleID, RoleMapInfo#p_map_role.role_name}}),
                    OfficeInfo = AttackFactionInfo#p_faction.office_info,
                    case OfficeInfo#p_office.king_role_id =:= RoleID of
                        true ->
                            OfficeName = "国王";
                        false ->
                            OfficeName = " 天纵神将"
                    end,
                    RoleName = RoleMapInfo#p_map_role.role_name,
                    DefenceFactionName = get_faction_name_by_id(DefenceFactionID),
                    AttackRecord = OfficeName ++ "<font color=\"#FFFF00\">[" ++ common_tool:to_list(RoleName) ++ "]</font>花费10锭钱币向" ++ DefenceFactionName ++ "发动国战",
                    write_waroffaction_record(AttackFactionID,AttackRecord),
                    AttackFactionName = get_faction_name_by_id(AttackFactionID),
                    DefenceRecord = AttackFactionName ++ "<font color=\"#FFFF00\">[" ++ common_tool:to_list(RoleName) ++ "]</font>花费10锭钱币向我国发动国战！",
                    write_waroffaction_record(DefenceFactionID,DefenceRecord),
                    broadcast_war_declare_information(OfficeName,AttackFactionName, DefenceFactionName,RoleMapInfo#p_map_role.role_name),
                    #m_waroffaction_declare_toc{succ=true,silver=NewSilver};   
                {error,Reason} ->
                    #m_waroffaction_declare_toc{succ=false,reason=Reason}
            end
    end.


%%广播国战宣战的信息
broadcast_war_declare_information(OfficeName,AttackFactionName, DefenceFactionName,RoleName) ->
    Days = calendar:date_to_gregorian_days(date()) + 1,
    {_Y,Month,Day} = calendar:gregorian_days_to_date(Days), 
    Content = common_tool:to_list(AttackFactionName) ++ common_tool:to_list(OfficeName) ++ "<font color=\"#FFFF00\">[" ++ common_tool:to_list(RoleName) ++ "]</font>向"
                  ++ common_tool:to_list(DefenceFactionName) ++ "发动国战，战争将于~p月~p日20:00开始，\\n胜利国家势力成员获得额外的双倍经验奖励。",
    Content2 = io_lib:format(Content, [Month,Day]),
    common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_WORLD,common_tool:to_list(Content2)).



%%查看国战记录
do_get_record(Line, RoleID, Unique, _DataIn) ->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        undefined ->
            ignore;
        #p_map_role{faction_id=FactionID} ->
            
            RecordList = db:dirty_match_object(?DB_WAROFFACTION_RECORD,#p_waroffaction_record{faction_id=FactionID,_='_'}),
            Record = #m_waroffaction_record_toc{records=RecordList},
           % ?ERROR_MSG("$$$$$$$$$  ~w",[Record]),
            common_misc:unicast(Line, RoleID, Unique, ?WAROFFACTION, ?WAROFFACTION_RECORD, Record)
    end.
    

%%国战准备阶段时购买国战守卫和拒马等东西
do_buy_guader(Line, RoleID, Unique, DataIn) ->
    #m_waroffaction_buy_guarder_tos{guarder_type=GuarderType}=DataIn,
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        undefined ->
            do_buy_guader_error(Unique, ?_LANG_SYSTEM_ERROR, RoleID, Line, GuarderType);
        RoleMapInfo ->
            #p_map_role{faction_id = AttackFactionID} = RoleMapInfo,
            case db:dirty_read(?DB_FACTION,AttackFactionID) of
                [] ->
                    do_buy_guader_error(Unique, ?_LANG_SYSTEM_ERROR, RoleID, Line, GuarderType);
                [AttackFactionInfo] ->
                    OfficeInfo = AttackFactionInfo#p_faction.office_info,
                    %%判断招募的玩家是否是国王或者天纵神将
                    case OfficeInfo#p_office.king_role_id =:= RoleID orelse 
                                                 common_office:get_general_roleid(OfficeInfo#p_office.offices) =:= RoleID of
                        true ->
                            do_buy_guader2(Line, Unique, GuarderType, RoleID, AttackFactionID, RoleMapInfo, AttackFactionInfo);
                        false ->
                            do_buy_guader_error(Unique, ?_LANG_WAROFFACTION_BUY_GUARDER_FACTION_RIGHT_NOT_ENOUGH, RoleID, Line, GuarderType)  
                    end
            end
    end.


do_buy_guader2(Line, Unique, GuarderType, RoleID, AttackFactionID, RoleMapInfo, AttackFactionInfo) ->
    [GuarderInfo] = common_config_dyn:find(waroffaction_guarder,GuarderType),
    case AttackFactionInfo#p_faction.silver >= GuarderInfo#r_waroffaction_guarder_info.silver of
        true ->
            case check_guard_level(GuarderInfo,AttackFactionInfo) of
                true ->
                    MapID = GuarderInfo#r_waroffaction_guarder_info.map_id,
                    MapName = common_map:get_common_map_name(MapID),
                    global:send(MapName,{mod_waroffaction,{born_waroffaction_guarder_npc, Line, Unique, RoleID, AttackFactionID, MapID, MapName, GuarderInfo,RoleMapInfo#p_map_role.role_name}});
                false ->
                    %?ERROR_MSG("check_guard_level error",[]),
                    do_buy_guader_error(Unique, ?_LANG_SYSTEM_ERROR, RoleID, Line, GuarderType)  
            end;
        false ->
            do_buy_guader_error(Unique, ?_LANG_WAROFFACTION_FACTION_SILVER_NOT_ENOUGH, RoleID, Line, GuarderType)  
    end.


            
do_buy_guader_error(Unique, Reason, RoleID, Line, GuarderType) ->
      %?ERROR_MSG(" $$$$$$$$$$$    do_buy_guader_error ########  ~w",[Reason]),
    R = #m_waroffaction_buy_guarder_toc{succ=false, reason=Reason, guarder_type=GuarderType},
    common_misc:unicast(Line, RoleID, Unique, ?WAROFFACTION, ?WAROFFACTION_BUY_GUARDER, R).

check_guard_level(GuarderInfo,AttackFactionInfo) ->
    %?ERROR_MSG("~w ~w",[GuarderInfo,AttackFactionInfo]),
    case GuarderInfo#r_waroffaction_guarder_info.level of
        0 ->
            true;
        Level ->
            AttackFactionInfo#p_faction.guarder_level >= Level
    end.



    
%%检查是否能购买守卫和拒马等
check_can_bug_guarder(Type) ->
    %%判断是否在国战准备时间
    case get_waroffaction_stage() of
        ?WAROFFACTION_READY_STAGE ->
            %%判断是否已经召唤过了
            case erlang:get({waroffaction_guarder,Type}) of
                undefined ->
                    ok;
                _ ->
                    {error,?_LANG_FACTION_GUARDER_ALREADLY_EXIST}
            end;
        _ ->
            {error,?_LANG_FACTION_BUY_GUARDER_TIME_WRONG}
    end.


do_born_waroffaction_guarder_npc(Line, Unique, RoleID, FactionID, MapID, MapName, GuarderInfo, RoleName) ->
    GuarderType = GuarderInfo#r_waroffaction_guarder_info.type_id,
    %?ERROR_MSG("^^^^^^^ do_born_waroffaction_guarder_npc  ~w",[GuarderInfo]),
    case check_can_bug_guarder(GuarderInfo#r_waroffaction_guarder_info.key) of
        ok ->
            BornPosList = GuarderInfo#r_waroffaction_guarder_info.born_pos_list,
            [NpcBaseInfo] = common_config_dyn:find(server_npc, GuarderType),
            ServerNpcList = 
                lists:foldr(
                  fun({Tx,Ty,Dir},Acc) ->
                          Pos = #p_pos{tx = Tx,ty = Ty,dir = Dir},
                          ServerNpcInfo = #p_server_npc{
                                                        %% 使用怪物的id
                                                        npc_id = mod_map_monster:get_max_monster_id_form_process_dict(),
                                                        type_id = NpcBaseInfo#p_server_npc_base_info.type_id,
                                                        npc_name = NpcBaseInfo#p_server_npc_base_info.npc_name,
                                                        npc_type = NpcBaseInfo#p_server_npc_base_info.npc_type,
                                                        max_mp= NpcBaseInfo#p_server_npc_base_info.max_mp,
                                                        state = ?DEAD_STATE,
                                                        max_hp = NpcBaseInfo#p_server_npc_base_info.max_hp,
                                                        map_id = MapID,
                                                        reborn_pos = Pos,
                                                        level= NpcBaseInfo#p_server_npc_base_info.level,
                                                        npc_country = NpcBaseInfo#p_server_npc_base_info.npc_country,
                                                        is_undead = NpcBaseInfo#p_server_npc_base_info.is_undead,
                                                        move_speed = NpcBaseInfo#p_server_npc_base_info.move_speed
                                                       },
                          [ServerNpcInfo|Acc]
                  end,[],BornPosList),
            mod_server_npc:init_map_server_npc(MapName, MapID, ServerNpcList),
            Silver = GuarderInfo#r_waroffaction_guarder_info.silver,
            put({waroffaction_guarder,GuarderInfo#r_waroffaction_guarder_info.key},GuarderInfo#r_waroffaction_guarder_info.level),
            global:send(mgeew_office,{deduct_faction_silver_buy_guarder,FactionID,Silver,RoleID}),
            write_record_when_buy_guarder(RoleID,FactionID,GuarderInfo, NpcBaseInfo#p_server_npc_base_info.npc_name,RoleName),
            R = #m_waroffaction_buy_guarder_toc{succ=true,guarder_type=GuarderType},
            common_misc:unicast(Line, RoleID, Unique, ?WAROFFACTION, ?WAROFFACTION_BUY_GUARDER, R);
        {error,Reason} ->
            do_buy_guader_error(Unique, Reason, RoleID, Line, GuarderType)
    end.


%%购买国战守卫的时候的记录
write_record_when_buy_guarder(RoleID,FactionID,GuarderInfo,NpcName,RoleName) ->
    case common_office:get_king_roleid(FactionID) of
        RoleID ->
            OfficeName = "国王";
        _ ->
            OfficeName = "天纵神将"
    end,
    
    Cost = common_tool:silver_to_string(GuarderInfo#r_waroffaction_guarder_info.silver),
    Record = OfficeName ++ "<font color=\"#FFFF00\">[" ++ common_tool:to_list(RoleName) ++ "]</font>花费" ++ Cost ++ "钱币招募" ++ NpcName,
    write_waroffaction_record(FactionID,Record).
    
                

%%扣除国库钱币
decute_faction_silver(FactionID,DecuteNum) ->
    case db:transaction(
           fun() ->
                   [FactionInfo] = db:read(?DB_FACTION,FactionID),
                   NewSilver = FactionInfo#p_faction.silver - DecuteNum,
                   case NewSilver >= 0 of
                       true ->
                           NewSilver;
                       false ->
                           db:abort(?_LANG_WAROFFACTION_FACTION_SILVER_NOT_ENOUGH)
                   end
           end) of
        {aborted, Reason} ->
            {error,Reason};
        {atomic, Silver} ->
            {ok,Silver}
    end.


%%国战开战前10分钟到第一阶段结束时每5分钟一次的广播
do_waroffaction_cycle_broadcast(AttackFactionID,DefenceFactionID) ->
    erlang:send_after(5*60*1000,self(),{mod_waroffaction,{waroffaction_cycle_broadcast,AttackFactionID,DefenceFactionID}}),
   
    DefenceFactionName = get_faction_name_by_id(DefenceFactionID),
    AttackContent = "请参战势力成员前往" ++ DefenceFactionName ++ "国夺取平江石桥，并破坏" ++ DefenceFactionName ++ "哨塔。",
    DefenceContent = "请参战势力成员前往平江石桥进行防守，防止敌人破坏平江哨塔。",
    common_broadcast:bc_send_msg_faction(AttackFactionID,[?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_COUNTRY,AttackContent),
    common_broadcast:bc_send_msg_faction(DefenceFactionID,[?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_COUNTRY,DefenceContent),
    
    ok.
    

get_faction_name_by_id(FactionID) ->
    case FactionID of
        1 ->"<font color=\"#00FF00\">西夏</font>";
        2 ->"<font color=\"#F600FF\">南诏</font>";
        3 ->"<font color=\"#00CCFF\">东周</font>"
    end.

%%国战结束后平江地图相关的逻辑处理
do_waroffaction_end() ->
   war_over_when_time_out2().


%%重生或重置瞭望塔，将军，国旗
reset_war_server_npc() ->
    MapID = mgeem_map:get_mapid(),
    WaroffactionNpcTypeIDList = get_waroffaction_npc_typeid_list(MapID),
    waroffaction_server_npc_born(),
    set_npc_undead_state(WaroffactionNpcTypeIDList,true),
    ok.

%%国战结束  
war_over(AttackFactionID,DefenceFactionID,WinFactionID) ->
    do_result_of_faction_info(WinFactionID,AttackFactionID,DefenceFactionID),
    add_double_exp_buff(WinFactionID),
    %% 回城广播
    broadcast_back_faction_msg(),
    %% 删除宣战纪录
    common_misc:del_event_state({waroffaction_declare, AttackFactionID}),
    ok.


get_pingjiang_map_name_by_factionid(FactionID) ->
    case FactionID of
        1 ->
            common_misc:get_map_name(11102);
        2 ->
            common_misc:get_map_name(12102);
        3 ->
            common_misc:get_map_name(13102)
    end.
get_jingcheng_map_name_by_factionid(FactionID) ->
    case FactionID of
        1 ->
            common_misc:get_map_name(11100);
        2 ->
            common_misc:get_map_name(12100);
        3 ->
            common_misc:get_map_name(13100)
    end.


%%清理掉国战召唤的国战守卫和拒马
clear_waroffaction_guarder() ->
    NpcIDList = mod_server_npc:get_server_npc_id_list(),
    FactionID = get_defence_faction_id(),
    lists:foreach(
      fun(NpcID) ->
                TypeIDList = get_waroffaction_guarder_type_idlist(FactionID),
                NpcState = mod_server_npc:get_server_npc_state(NpcID),
                NpcInfo = NpcState#server_npc_state.server_npc_info,
                case lists:member(NpcInfo#p_server_npc.type_id, TypeIDList) of
                    true ->
                        mod_server_npc:delete_server_npc(NpcID);
                    false ->
                        ignore
                end
      end,NpcIDList).


%%根据国家ID获取这个国家的所有国战守卫和拒马的type_id
get_waroffaction_guarder_type_idlist(FactionID) ->
%%     case FactionID of
%%         1 -> [21201001,21211100,21212100,21211110,21212110,21211120,21212120,21211130,21212130,21211140,21212140,21211150,21212150,21211160,21212160];
%%         2 -> [22201001,22211100,22212100,22211110,22212110,22211120,22212120,22211130,22212130,22211140,22212140,22211150,22212150,22211160,22212160];
%%         3 -> [22201001,23211100,23212100,23211110,23212110,23211120,23212120,23211130,23212130,23211140,23212140,23211150,23212150,23211160,23212160]
%%         common_config_dyn:find({waroffaction_guarder_type_idlist,FactionID})
%%     end.
      [List] = common_config_dyn:find(waroffaction_etc,{waroffaction_guarder_type_idlist,FactionID}),
      List.

%%计算国战后两个国家的国家信息，包括钱币，胜利次数等
do_result_of_faction_info(WinFactionID,AttackFactionID,DefenceFactionID) ->
    case db:transaction(
           fun() ->
                   [AttackFactionInfo] = db:read(?DB_FACTION,AttackFactionID),
                   [DefenceFactionInfo] = db:read(?DB_FACTION,DefenceFactionID),
                   case WinFactionID =:= AttackFactionID of
                       true ->
                           Silver = trunc(DefenceFactionInfo#p_faction.silver / 10),
                           change_winner_faction_info(AttackFactionInfo,Silver),
                           change_loser_faction_info(DefenceFactionInfo,Silver);
                       false ->
                           Silver = trunc(AttackFactionInfo#p_faction.silver / 10),
                           change_winner_faction_info(DefenceFactionInfo,Silver),
                           change_loser_faction_info(AttackFactionInfo,Silver)
                   end
           end) of
        {aborted,_Reason} ->
            ignore;
        {atomic,_} ->
            ok
    end.
              
%%跟新国战胜利方的相关国战信息
change_winner_faction_info(FactionInfo,Silver) ->
    NewSilver = FactionInfo#p_faction.silver + Silver,
    NewAllSucc = FactionInfo#p_faction.succ_times_waroffaction + 1,
    NewPersistSucc = FactionInfo#p_faction.persist_succ_times_waroffaction + 1,
    KingTokenUsedLog = FactionInfo#p_faction.king_token_used_log,
    NewPersistFail = 0,
   case FactionInfo#p_faction.war_point of
        0 ->
            NewPoint = 0;
        Point ->
            NewPoint = Point - 1
    end,
    MaxGuarderLevel = get_max_level_by_war_point(NewPoint),
    NewFactionInfo = FactionInfo#p_faction{
                       silver=NewSilver,
                       succ_times_waroffaction = NewAllSucc,
                       persist_succ_times_waroffaction = NewPersistSucc,
                       persist_fail_times_waroffaction = NewPersistFail,
                       guarder_level = MaxGuarderLevel,
                       war_point = NewPoint,
                       %% 国战后国王令使用次数清0
                       king_token_used_log=KingTokenUsedLog#p_king_token_used_log{king_used_counter=0,
                                                                                 general_used_counter=0}},
    db:write(?DB_FACTION,NewFactionInfo,write).


%%跟新国战失败方的相关国战信息
change_loser_faction_info(FactionInfo,Silver) ->
    NewSilver = FactionInfo#p_faction.silver - Silver,
    NewAllFail = FactionInfo#p_faction.fail_times_waroffaction + 1,
    NewPersistFail = FactionInfo#p_faction.persist_fail_times_waroffaction + 1,
    KingTokenUsedLog = FactionInfo#p_faction.king_token_used_log,
    NewPersistSucc = 0,
     case FactionInfo#p_faction.war_point of
        10 ->
            NewPoint = 10;
        Point ->
            NewPoint = Point + 1
    end,
    MaxGuarderLevel = get_max_level_by_war_point(NewPoint),
    NewFactionInfo = FactionInfo#p_faction{
                       fail_times_waroffaction = NewAllFail,
                       silver = NewSilver,
                       persist_succ_times_waroffaction = NewPersistSucc,
                       persist_fail_times_waroffaction = NewPersistFail,
                       guarder_level = MaxGuarderLevel,
                       war_point = NewPoint,
                       %% 国战后国王令使用次数清0
                       king_token_used_log=KingTokenUsedLog#p_king_token_used_log{king_used_counter=0,
                                                                                  general_used_counter=0}},
    db:write(?DB_FACTION,NewFactionInfo,write).

get_max_level_by_war_point(NewPoint) ->
    case NewPoint of
        0 -> 1;
        1 -> 1;
        2 -> 2;
        3 -> 3;
        4 -> 4;
        5 -> 5;
        6 -> 6;
        _ -> 7
    end.


%%国战胜利的国家2小时内经验翻倍
add_double_exp_buff(WinFactionID) ->
    common_buff:add_faction_multiple_exp(WinFactionID, 2, 2*60*60).


%% 国战记录
write_waroffaction_record(FactionID,Content) ->
    Fun = 
        fun() ->
        ID = get_max_war_record_id(?DB_WAROFFACTION_COUNTER),
        Now = common_tool:now(),
        Record = #p_waroffaction_record{id=ID,faction_id=FactionID,tick=Now,content=Content},
        db:dirty_write(?DB_WAROFFACTION_RECORD,Record)
    end,
    erlang:spawn(Fun).

get_max_war_record_id(TableName) ->
    Parrten = #r_waroffaction_counter{key = 1 , _ = '_'},
    case db:transaction( 
           fun() ->
                   case db:match_object(TableName, Parrten, write) of
                       [] ->
                           ?DEBUG("no data",[]),
                           Record = #r_waroffaction_counter{key = 1,last_record_id = 1},
                           db:write(TableName, Record, write),
                           1;
                       [Record] ->
                           #r_waroffaction_counter{last_record_id = LastID} = Record,
                           NewRecord = Record#r_waroffaction_counter{last_record_id = LastID+1},
                           db:write(TableName, NewRecord, write),
                           LastID+1
                   end
           end) of
        {atomic,ID} ->
            ID;
        {aborted,_} ->
            throw({error,get_max_monster_id_fail})
    end.
        

%% @doc 同意召集
do_gather_confirm(Unique, Module, Method, RoleID, DataIn, PID, #map_state{mapid=MapID}=MapState) ->
    #m_waroffaction_gather_confirm_tos{mapid=KingMapID, tx=TX, ty=TY} = DataIn,
    %% 是否能够传送，状态检测
    case check_can_gather_confirm(RoleID, KingMapID, MapID) of
        ok ->
            hook_map_role:hook_change_map_by_call(?CHANGE_MAP_WAROFFACTION_CALL,RoleID),
            DataRecord = #m_waroffaction_gather_confirm_toc{},
            common_misc:unicast2(PID, Unique, Module, Method, DataRecord),

            case KingMapID =:= MapID of
                true ->
                    case mod_spiral_search:get_walkable_pos(MapID, TX, TY, 10) of
                        {error, _} ->
                            TX2 = TX,
                            TY2 = TY;
                        {TX2, TY2} ->
                            ok
                    end,

                    mod_map_actor:same_map_change_pos(RoleID, role, TX2, TY2, ?CHANGE_POS_TYPE_NORMAL, MapState);
                _ ->
                    mod_map_role:diff_map_change_pos(RoleID, KingMapID, TX, TY)
            end;

        {error, Reason} ->
            DataRecord = #m_waroffaction_gather_confirm_toc{succ=false, reason=Reason},
            common_misc:unicast2(PID, Unique, Module, Method, DataRecord)
    end.

check_can_gather_confirm(RoleID, KingMapID, MapID) ->
    %% 监狱不能传送
    case mod_jail:check_in_jail(MapID) of
        true ->
            {error, ?_LANG_WAROFFACTION_GATHER_CONFIRM_IN_JAIL};
        _ ->
            case mod_map_actor:get_actor_mapinfo(RoleID, role) of
                undefined ->
                    {error, ?_LANG_SYSTEM_ERROR};
                RoleMapInfo ->
                    #p_map_role{faction_id=FactionID, state=State, level=Level} = RoleMapInfo,
                    %% 一些特殊状态不能接受
                    case State =:= ?ROLE_STATE_DEAD orelse State =:= ?ROLE_STATE_STALL 
						 orelse mod_horse_racing:is_role_in_horse_racing(RoleID) of

                        true ->
                            {error, ?_LANG_WAROFFACTION_GATHER_CONFIRM_SPEC_STATE};

                        _ ->
                            [LimitLevel] =  common_config_dyn:find(map_level_limit, KingMapID),
                            case Level < LimitLevel of
                                true ->
                                    {error, ?_LANG_WAROFFACTION_GATHER_CONFIRM_LEVEL_NOT_ENOUGH};

                                _ ->
                                    check_can_gather_confirm2(FactionID)
                            end
                    end
            end
    end.

%% 召集令5分钟过期
-define(king_token_time_over, 5*60).

%% 是否国战期间
check_can_gather_confirm2(FactionID) ->
    case db:dirty_read(?DB_WAROFFACTION, 1) of
        [] ->
            {error, ?_LANG_WAROFFACTION_GATHER_CONFIRM_NOT_IN_WAR};

        [#r_waroffaction{attack_faction_id=AFactionID, defence_faction_id=DFactionID}] ->
            case AFactionID =:= FactionID orelse DFactionID =:= FactionID of
                true ->
                    [#p_faction{king_token_used_log=UsedLog}] = db:dirty_read(?DB_FACTION, FactionID),
                    #p_king_token_used_log{king_last_used_time=KingUsedTime, general_last_used_time=GeneralUsedTime} = UsedLog,
                    %% 
                    Now = common_tool:now(),
                    case Now - KingUsedTime > ?king_token_time_over andalso Now - GeneralUsedTime > ?king_token_time_over of
                        true ->
                            {error, ?_LANG_WAROFFACTION_GATHER_CONFIRM_TIME_OVER};
                        _ ->
                            ok
                    end;

                _ ->
                    {error, ?_LANG_WAROFFACTION_GATHER_CONFIRM_NOT_IN_WAR}
            end
    end.

%% @doc 广播回城消息
broadcast_back_faction_msg() ->
    DefenceFID = get_defence_faction_id(),
    %% 十秒倒计时
    DataRecord = #m_waroffaction_count_down_toc{tick=30, type=4}, 
    lists:foreach(
      fun(RoleID) ->
              case mod_map_actor:get_actor_mapinfo(RoleID, role) of
                  undefined ->
                      ignore;
                  #p_map_role{faction_id=DefenceFID} ->
                      ignore;
                  _ ->
                      common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFFACTION, ?WAROFFACTION_COUNT_DOWN, DataRecord)
              end
      end, mod_map_actor:get_in_map_role()),
    %% 在地图打个标记
    put(?back_faction_time, common_tool:now()+30),
    %% 防守国ID放到进程字典，防止时间到了之前的被清掉
    put(?defen_faction_id, DefenceFID).

%% @doc 角色进入地图hook
hook_role_map_enter(RoleMapInfo) ->
    case get(?back_faction_time) of
        undefined ->
            ignore;
        Time ->
            Now = common_tool:now(),
            case Time > Now of
                true ->
                    DFID = get(?defen_faction_id),
                    #p_map_role{faction_id=FID, role_id=RoleID} = RoleMapInfo,

                    case DFID =:= FID of
                        true ->
                            ignore;
                        _ ->
                            DataRecord = #m_waroffaction_count_down_toc{tick=Time-Now, type=4},
                            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?WAROFFACTION, ?WAROFFACTION_COUNT_DOWN, DataRecord)
                    end;
                _ ->
                    ignore
            end
    end.

%% @doc 获取某个国家的宣战状态
get_waroffaction_declare_info(FactionID) ->
    get_waroffaction_declare_info2(FactionID, [1, 2, 3]).

get_waroffaction_declare_info2(_FactionID, []) ->
    {ok, no_declare};
get_waroffaction_declare_info2(FactionID, [AttackFID|T]) ->
    case common_misc:get_event_state({waroffaction_declare, AttackFID}) of
        {false, _} ->
            get_waroffaction_declare_info2(FactionID, T);

        {ok, #r_event_state{data=Data}} ->
            {DefenceFID, DeclareTime} = Data,
            if
                FactionID =:= AttackFID ->
                    {ok, {attack, DefenceFID, DeclareTime}};
                FactionID =:= DefenceFID ->
                    {ok, {defence, AttackFID, DeclareTime}};
                true ->
                    get_waroffaction_declare_info2(FactionID, T)
            end
    end.

%% @doc 角色上线hook
hook_role_online(RoleID, FactionID) ->
    case get_waroffaction_declare_info(FactionID) of
        {ok, {attack, DefenceFID, DeclareTime}} ->
            {{Y, M, D}, _} = DeclareTime,
            {Y2, M2, D2} = get_next_day(Y, M, D),
            DefenceFName = get_faction_name_by_id(DefenceFID),
            Msg = lists:flatten(io_lib:format(?_LANG_WAROFFACTION_ROLE_ONLINE_ATTACK, [DefenceFName, Y2, M2, D2, DefenceFName])),
            common_broadcast:bc_send_msg_role(RoleID, [?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD, Msg);
        {ok, {defence, AttackFID, DeclareTime}} ->
            {{Y, M, D}, _} = DeclareTime,
            {Y2, M2, D2} = get_next_day(Y, M, D),
            AttackFName = get_faction_name_by_id(AttackFID),
            Msg = lists:flatten(io_lib:format(?_LANG_WAROFFACTION_ROLE_ONLINE_DEFENCE, [AttackFName, Y2, M2, D2])),
            common_broadcast:bc_send_msg_role(RoleID, [?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD, Msg);
        _ ->
            ignore
    end.

get_next_day(Y, M, D) ->
    LastDay = calendar:last_day_of_the_month(Y, M),
    if
        D =:= LastDay andalso M =:= 12 ->
            {Y+1, M+1, 1};
        D =:= LastDay ->
            {Y, M+1, 1};
        true ->
            {Y, M, D+1}
    end.

%% @doc 获取国战开始时间
get_waroffaction_start_time(FactionID) ->
    case get_waroffaction_declare_info(FactionID) of
        {ok, no_declare} ->
            false;
        {ok, {_, _, {DeclareDate, _}}} ->
            {NowDate, _} = calendar:local_time(),
            [{{WarStartHour, WarStartMin}, _}] = common_config_dyn:find(spy, waroffaction_time),
            if
                %% 今天宣战，明天开始国战
                DeclareDate =:= NowDate ->
                    {tomorrow, WarStartHour, WarStartMin};
                true ->
                    {today, WarStartHour, WarStartMin}
            end
    end.
  

%%初始化国战的将军和哨塔，根据开服天数来初始化
init(_MapID) ->
    case common_config_dyn:find(etc,is_waroffaction_open) of
        [IsOpen] ->
            case IsOpen of
                true ->
                    waroffaction_server_npc_born();
                _->
                    ignore
            end;
        _->
            ignore
    end,
    ok.

%% @doc 是否国战，以及是否参战国
is_in_waroffaction(FactionID) ->
    case mod_waroffaction:get_attack_faction_id() of
        FactionID ->
            true;
        _ ->
            case mod_waroffaction:get_defence_faction_id() of
                FactionID ->
                    true;
                _ ->
                    false
            end
    end.

is_in_waroffaction_dirty(_FactionID,_MapID) ->
	false.

%%====================== test  code================================

test_declare_war(RoleID,DefenceFactionID) ->
    common_misc:send_to_rolemap(RoleID, {0, ?WAROFFACTION, ?WAROFFACTION_DECLARE, 
                                          #m_waroffaction_declare_tos{defence_faction_id = DefenceFactionID}, 
                                          RoleID, self(), 1}),
    ok.


test_buy_guarder(RoleID,TypeID) ->
    common_misc:send_to_rolemap(RoleID, {0, ?WAROFFACTION, ?WAROFFACTION_BUY_GUARDER, 
                                          #m_waroffaction_buy_guarder_tos{guarder_type=TypeID}, 
                                          RoleID, self(), 1}),
    ok.
                               
                    
