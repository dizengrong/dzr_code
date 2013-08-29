%%%-------------------------------------------------------------------
%%% @author chenrong
%%% @doc
%%%     定时活动hook
%%% @end
%%% Created : 2012-05-04
%%%-------------------------------------------------------------------
-module(hook_activity_schedule).
-include("mgeem.hrl").
-include("activity.hrl").

%% API
-export([
         hook_exp_change/2,
         hook_gain_silver/1,
         hook_get_equip/3,
         hook_monster_dead/3
        ]). 

check_can_join_activity(ActivityID, RoleID) ->
    case common_activity:check_activity_notice_config(ActivityID) of
        {error, not_found_config} ->
            ignore;
        #r_activity_notice_config{min_jingjie=MinJingjie} ->
            case mod_map_role:get_role_attr(RoleID) of
                {ok, #p_role_attr{jingjie=Jingjie}} ->
                    if Jingjie >= MinJingjie ->
                           case common_misc:get_event_state(schedule_activity) of
                               {ok, #r_event_state{data=#r_schedule_data{activity_id=ActivityID}}} ->
                                   ok;
                               _ ->
                                   ignore
                           end;
                       true ->
                           ignore
                    end;
                _ ->
                    ignore
            end
    end.

hook_exp_change(RoleID, ExpAdd) ->
    case check_can_join_activity(?ACTIVITY_SCHEDULE_EXP, RoleID) of
        ok ->
            global:send(mgeew_activity_schedule, {update_rank_element, {?ACTIVITY_SCHEDULE_EXP, RoleID, ExpAdd}});
        _ ->
            ignore
    end.

%% 可参与富家天下排名的银两消费类型
-define(SILVER_ACTIVITY_SCHEDULE, 
        [?GAIN_TYPE_SILVER_FROM_PICKUP,?GAIN_TYPE_SILVER_MISSION_YBC,?GAIN_TYPE_SILVER_MISSION_NORMAL,
         ?GAIN_TYPE_SILVER_ITEM_USE,?GAIN_TYPE_SILVER_TRADING,
         ?GAIN_TYPE_SILVER_NPC_EXCHANGE,?GAIN_TYPE_SILVER_FAMILY_YBC,
         ?GAIN_TYPE_SILVER_FROM_GOAL,?GAIN_TYPE_SILVER_ARENA_ANNOUNCE,
         ?GAIN_TYPE_SILVER_RANKREWARD_FETCH,?GAIN_TYPE_SILVER_NATIONBATTLE_REWARD,
         ?GAIN_TYPE_SILVRE_FACTION_OFFICE_SALARY,?GAIN_TYPE_SILVER_USE_CANG_BAO_TU,?GAIN_TYPE_SILVER_CAISHEN,
         ?GAIN_TYPE_SILVER_JUEWEI_UPGRADE,?GAIN_TYPE_SILVER_WAROFMONSTER_REWARD,?GAIN_TYPE_SILVER_CROWN_ARENA,
         ?GAIN_TYPE_SILVER_MINE_FB_HARVEST,?GAIN_TYPE_SILVER_MINE_FB_GRAB,?GAIN_TYPE_SILVER_FROM_RNKM,?GAIN_TYPE_SILVER_FROM_CLGM]).

hook_gain_silver(RecList) ->
    case common_activity:check_activity_notice_config(?ACTIVITY_SCHEDULE_SILVER) of
        {error, not_found_config} ->
            ignore;
        #r_activity_notice_config{min_jingjie=MinJingjie} ->
            case common_misc:get_event_state(schedule_activity) of
                {ok, #r_event_state{data=#r_schedule_data{activity_id=?ACTIVITY_SCHEDULE_SILVER}}} ->
                    lists:foreach(
                      fun(Rec) ->
                              #r_consume_log{type=Type,role_id=RoleID,use_bind=UseSilverBind,use_unbind=UseSilverUnbind,mtype=MType}=Rec,
                              {ok, #p_role_attr{jingjie=Jingjie}} = mod_map_role:get_role_attr(RoleID),
                              case Type=:=silver andalso Jingjie >= MinJingjie andalso lists:member(MType, ?SILVER_ACTIVITY_SCHEDULE) of
                                  true ->
                                      global:send(mgeew_activity_schedule, {update_rank_element, {?ACTIVITY_SCHEDULE_SILVER, RoleID, UseSilverBind+UseSilverUnbind}});
                                  false ->
                                      ignore
                              end
                      end, RecList);
                _ ->
                    ignore
            end
    end.

%% 可参与神兵之王排名的装备获得类型
-define(EQUIP_ACTIVITY_TYPE_LIST, 
        [?LOG_ITEM_TYPE_SCENE_WAR_FB_AWARD,?LOG_ITEM_TYPE_GIFT_ITEM_AWARD,
         ?LOG_ITEM_TYPE_SHI_QU_HUO_DE,?LOG_ITEM_TYPE_REN_WU_HUO_DE,?LOG_ITEM_TYPE_BOX_RESTORE_HUO_DE,
         ?LOG_ITEM_TYPE_GIFT_ITEM_AWARD,?LOG_ITEM_TYPE_PAY_FIRST_GIFT_HUO_DE,?LOG_ITEM_TYPE_PAY_GIFT_HUO_DE,
         ?LOG_ITEM_TYPE_HEROFB_BOX_FETCH,?LOG_ITEM_TYPE_GAIN_COLLECT_PURPLE_EQUIP_GIFT,?LOG_ITEM_TYPE_CANG_BAO_TU]).

hook_get_equip(RoleID, {EquipID, Color}, Action) ->
    case lists:member(Action, ?EQUIP_ACTIVITY_TYPE_LIST) of
        true ->
            case check_can_join_activity(?ACTIVITY_SCHEDULE_EQUIP, RoleID) of
                ok ->
                    send_activity_schedule_equip_info(RoleID, {EquipID, Color});
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.

send_activity_schedule_equip_info(RoleID, {EquipID, Color}) ->
    case mod_equip:get_equip_baseinfo(EquipID) of
        {ok, EquipBaseInfo} ->
            case lists:member(EquipBaseInfo#p_equip_base_info.slot_num, 
                              [?PUT_ARM,?PUT_NECKLACE,?PUT_FINGER,?PUT_ARMET,?PUT_BREAST,?PUT_CAESTUS,?PUT_BANGLE,?PUT_HAND,?PUT_SHOES]) of
                true ->
                    global:send(mgeew_activity_schedule, {update_rank_element, {?ACTIVITY_SCHEDULE_EQUIP, RoleID, {EquipID, Color}}});
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.

hook_monster_dead(RoleID, MonsterTypeID, Rarity) ->
    case Rarity of
        ?BOSS ->
            case check_can_join_activity(?ACTIVITY_SCHEDULE_BOSS, RoleID) of
                ok ->
                    global:send(mgeew_activity_schedule, {update_rank_element, {?ACTIVITY_SCHEDULE_BOSS, RoleID, MonsterTypeID}});
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.
