%%%----------------------------------------------------------------------
%%% File    : mgeed_mnesia.erl
%%% Author  : Liangliang
%%% Created : 2010-01-02
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------


-module(mgeed_mnesia).

-include("mgeed.hrl").

-export([
         init/0,
         init_db/0,
         master_init_once/0,
         cluster_init_once/0,
         table_defines/0
        ]).

-define(DEF_DISK_TABLE(Type,Rec),
        [{disc_copies, [node()]},
         {type, Type},
         {record_name, Rec},
         {attributes, record_info(fields, Rec)}
        ]).


init() ->
    do_init(),
    prepare(),
    wait_for_tables(),
    mod_mnesia_init:init(),
    ok.
                      


do_init() ->
    case mnesia:system_info(extra_db_nodes) of
        [] ->
            mnesia:create_schema([node()]);
        _ ->
            ok
    end,
    application:start(mnesia, permanent),
    mnesia:change_table_copy_type(schema, node(), disc_copies).


master_init_once() ->
    case mnesia:system_info(is_running) of
	no ->
            ok;
	yes ->
            mnesia:stop()
    end,
    mnesia:create_schema([node()]).

cluster_init_once() ->
    case mnesia:system_info(is_running) of
	no ->
            ok;
	yes ->
            mnesia:stop()
    end,
    mnesia:delete_schema([node()]).


prepare() ->
    case mnesia:system_info(is_running) of
        yes -> 
            ok;
        no -> 
            throw({error, mnesia_not_running})
    end,
    MnesiaDir = dir() ++ "/",
    case filelib:ensure_dir(MnesiaDir) of
        {error, Reason} ->
            throw({error, {cannot_create_mnesia_dir, MnesiaDir, Reason}});
        ok -> 
            ok
    end.


dir() -> 
    mnesia:system_info(directory).


init_db() ->
	[ mnesia:create_table(Tab, Definition) ||{Tab, Definition}<-table_defines() ],
	db_loader:init_map_tables(),
	db_loader:init_world_tables(),
	lists:foreach(fun(MysqlTab) -> 
		MnesiaTab = case lists:reverse(erlang:atom_to_list(MysqlTab)) of
			"p_"++MysqlTab2 ->
				erlang:list_to_atom(lists:reverse(MysqlTab2));
			MysqlTab2 ->
				erlang:list_to_atom(lists:reverse(MysqlTab2))
		end,
		db_subscriber:start(MnesiaTab, MysqlTab)
	end, mysql_persistent_config:tables()),
	ok.


wait_for_tables() ->
    init_db(),
    mnesia:wait_for_tables(mnesia:system_info(local_tables), infinity),
    ok.


table_defines() ->
    [
      {?DB_ROLE_BASE_P, [
                      {attributes, record_info(fields, p_role_base)},
                      {record_name, p_role_base},
                      {index, [role_name, account_name]},
                      {disc_copies, [node()]}
                     ]},
      
      {?DB_ROLE_FACTION_P,
       ?DEF_DISK_TABLE(set,r_role_faction)},
      {?DB_ACCOUNT_P,
       ?DEF_DISK_TABLE(set,r_account)},
      {?DB_ROLE_ATTR_P,
       ?DEF_DISK_TABLE(set,p_role_attr)},
      {?DB_ROLE_NAME_P,
       ?DEF_DISK_TABLE(set,r_role_name)},
      {?DB_ROLE_FIGHT_P,
       ?DEF_DISK_TABLE(set,p_role_fight)},
      {?DB_ROLE_POS_P,
       ?DEF_DISK_TABLE(set,p_role_pos)},
      {?DB_ROLE_EXT_P,
       ?DEF_DISK_TABLE(set,p_role_ext)},
      {?DB_ROLEID_COUNTER_P,
       ?DEF_DISK_TABLE(set,r_roleid_counter)},
      {?DB_ROLE_STATE_P,
       ?DEF_DISK_TABLE(set,r_role_state)},
      {?DB_MONSTERID_COUNTER_P,
       ?DEF_DISK_TABLE(set,r_monsterid_counter)},
      {?DB_MONSTER_PERSISTENT_INFO_P,
       ?DEF_DISK_TABLE(set,r_monster_persistent_info)},
      
      
     {?DB_STALL_P, [
                  {disc_copies, [node()]},
                  {type, set},
                  {index, [mapid, mode]},
                  {record_name, r_stall},
                  {attributes, record_info(fields, r_stall)}
                 ]},
     {?DB_STALL_SILVER_P, [
                         {disc_copies, [node()]},
                         {type, set},
                         {record_name, r_stall_silver},
                         {attributes, record_info(fields, r_stall_silver)}
                        ]},
     {?DB_STALL_GOODS_P, [
                        {disc_copies, [node()]},
                        {type, set},
                        {record_name, r_stall_goods},
                        {index, [role_id]},
                        {attributes, record_info(fields, r_stall_goods)}
                       ]},
     {?DB_STALL_GOODS_TMP_P, [
                            {disc_copies, [node()]},
                            {type, set},
                            {record_name, r_stall_goods},
                            {index, [role_id]},
                            {attributes, record_info(fields, r_stall_goods)}
                           ]},

     {?DB_ROLE_BAG_P, 
      [ {disc_copies, [node()]},
        {type, set}, 
        {record_name, r_role_bag},
        {attributes, record_info(fields, r_role_bag)} ]},
     {?DB_ROLE_BAG_BASIC_P, 
      [ {disc_copies, [node()]},
        {type, set}, 
        {record_name, r_role_bag_basic},
        {attributes, record_info(fields, r_role_bag_basic)} ]},
     {?DB_FRIEND_P, 
      [ {disc_copies, [node()]},
        {type, bag }, 
        {record_name, r_friend}, 
        {attributes, record_info(fields, r_friend)} ]}, 
     {?DB_ROLE_SKILL_P, 
      [ {disc_copies, [node()]}, 
        {type, set}, 
        {record_name, r_role_skill}, 
        {attributes, record_info(fields, r_role_skill)} ]},
     %%任务
     {?DB_MISSION_DATA_P,
      [ {disc_copies, [node()]}, 
        {type, set}, 
        {record_name, r_db_mission_data}, 
        {attributes, record_info(fields, r_db_mission_data)} ]},

     {?DB_SHORTCUT_BAR_P,
      [ {disc_copies, [node()]}, 
        {type, set},
        {record_name, r_shortcut_bar}, 
        {attributes, record_info(fields, r_shortcut_bar)} ]},
     {?DB_BROADCAST_MESSAGE_P,
      [{disc_copies, [node()]},
       {type, set},
       {index, [msg_type,expected_time,send_flag]},
       {record_name, r_broadcast_message}, 
       {attributes, record_info(fields, r_broadcast_message)}]},
     %%家族相关蟿
     {?DB_FAMILY_P, 
      [ {disc_copies, [node()]},
        {type, set},
        {record_name, p_family_info},
        {attributes, record_info(fields, p_family_info)}
      ]},
     {?DB_FAMILY_EXT_P, 
      [ {disc_copies, [node()]},
        {type, set},
        {record_name, r_family_ext},
        {attributes, record_info(fields, r_family_ext)}
      ]},
     {?DB_FAMILY_NAME_P,
      ?DEF_DISK_TABLE(set,r_family_name)},
     {?DB_FAMILY_COUNTER_P, 
      [ {disc_copies, [node()]},
        {type, set},
        {record_name, r_family_counter},
        {attributes, record_info(fields, r_family_counter)}
      ]},
     {?DB_FAMILY_INVITE_P, 
      [ {disc_copies, [node()]},
        {type, bag},
        {record_name, p_family_invite_info},
        {attributes, record_info(fields, p_family_invite_info)}
      ]},
     {?DB_FAMILY_REQUEST_P, 
      [ {disc_copies, [node()]},
        {type, bag},
        {record_name, p_family_request_info},
        {attributes, record_info(fields, p_family_request_info)}
      ]},
     %% 聊天模块
     {?DB_CHAT_CHANNEL_ROLES_P, 
      [ {disc_copies, [node()]},
        {type, bag},
        {record_name, p_chat_channel_role_info},
        {attributes, record_info(fields, p_chat_channel_role_info)}
      ]},
     {?DB_CHAT_ROLE_CHANNELS_P, 
      [ {disc_copies, [node()]},
        {type, bag},
        {record_name, r_chat_role_channel_info},
        {attributes, record_info(fields, r_chat_role_channel_info)}
      ]},
     {?DB_CHAT_CHANNELS_P, 
      [ {disc_copies, [node()]},
        {type, set},
        {record_name, p_channel_info},
        {attributes, record_info(fields, p_channel_info)}
      ]},
     {?DB_BAN_CHAT_USER_P, 
      [ {disc_copies, [node()]},
        {type, set},
        {record_name, r_ban_chat_user},
        {attributes, record_info(fields, r_ban_chat_user)}
      ]},
     {?DB_FCM_DATA_P, 
      [ {disc_copies, [node()]},
        {type, set},
        {record_name, r_fcm_data},
        {attributes, record_info(fields, r_fcm_data)}
      ]},

     {?DB_KEY_PROCESS, 
      [ {ram_copies, [node()]},
        {type, set},
        {record_name, r_key_process},
        {attributes, record_info(fields, r_key_process)}
      ]},
     {?DB_SYSTEM_CONFIG_P, 
      [ {disc_copies, [node()]},
        {type, set},
        {record_name, r_sys_config},
        {attributes, record_info(fields, r_sys_config)}
      ]},
     
     {?DB_ROLE_LEVEL_RANK_P, 
      [{record_name, p_role_level_rank},
       {attributes, record_info(fields, p_role_level_rank)},
       {disc_copies, [node()]}
      ]},
     {
       ?DB_NORMAL_TITLE_P,
       [{record_name, p_title},
        {attributes, record_info(fields, p_title)},
        {disc_copies, [node()]}]
     },
     {
       ?DB_SPEC_TITLE_P,
       [{record_name, p_title},
        {attributes, record_info(fields, p_title)},
        {disc_copies, [node()]}]
     },
     {
       ?DB_TITLE_COUNTER_P,
       [{record_name, r_title_counter},
        {attributes, record_info(fields, r_title_counter)},
        {disc_copies, [node()]}]
     },
     {?DB_ROLE_PKPOINT_RANK_P, 
      [{record_name, p_role_pkpoint_rank},
       {attributes, record_info(fields, p_role_pkpoint_rank)},
       {disc_copies, [node()]}
      ]
     },
     {?DB_ROLE_WORLD_PKPOINT_RANK_P, 
      [{record_name, p_role_pkpoint_rank},
       {attributes, record_info(fields, p_role_pkpoint_rank)},
       {disc_copies, [node()]}
      ]
     },
     {?DB_FAMILY_ACTIVE_RANK_P, 
      [{record_name, p_family_active_rank},
       {attributes, record_info(fields, p_family_active_rank)},
       {disc_copies, [node()]}
      ]
     },
     {?DB_EQUIP_REFINING_RANK_P, 
      [{record_name, p_equip_rank},
       {attributes, record_info(fields, p_equip_rank)},
       {disc_copies, [node()]}
      ]
     },
     {?DB_EQUIP_REINFORCE_RANK_P, 
      [{record_name, p_equip_rank},
       {attributes, record_info(fields, p_equip_rank)},
       {disc_copies, [node()]}
      ]
     },
     {?DB_EQUIP_STONE_RANK_P, 
      [{record_name, p_equip_rank},
       {attributes, record_info(fields, p_equip_rank)},
       {disc_copies, [node()]}
      ]
     },
     {?DB_ROLE_GONGXUN_RANK_P, 
      [{record_name, p_role_gongxun_rank},
       {attributes, record_info(fields, p_role_gongxun_rank)},
       {disc_copies, [node()]}
      ]
     },
     {?DB_ROLE_TODAY_GONGXUN_RANK_P, 
      [{record_name, p_role_gongxun_rank},
       {attributes, record_info(fields, p_role_gongxun_rank)},
       {disc_copies, [node()]}
      ]
     },
     {?DB_ROLE_YESTERDAY_GONGXUN_RANK_P, 
      [{record_name, p_role_gongxun_rank},
       {attributes, record_info(fields, p_role_gongxun_rank)},
       {disc_copies, [node()]}
      ]
     },
     {?DB_FAMILY_GONGXUN_PERSISTENT_RANK_P,
      [{record_name, p_family_gongxun_persistent_rank},
       {attributes, record_info(fields, p_family_gongxun_persistent_rank)},
       {disc_copies, [node()]}
      ]
     },
     {?DB_ROLE_PET_RANK_P, 
      [{record_name, p_role_pet_rank},
       {attributes, record_info(fields, p_role_pet_rank)},
       {disc_copies, [node()]}
      ]},
     {?DB_BAN_USER_P,
      [ {disc_copies,[node()]},
	{type,set},
	{record_name,r_ban_user},
	{attributes,record_info(fields,r_ban_user)}
      ]
     },

     {?DB_BAN_IP_P,
      [{disc_copies,[node()]},
       {type,set},
       {record_name,r_ban_ip},
       {attributes,record_info(fields,r_ban_ip)}
      ]
     },
     {?DB_PAY_LOG_P, 
      [
       {disc_copies, [node()]},
       {type, set},
       {record_name, r_pay_log},
       {attributes, record_info(fields, r_pay_log)}
      ]},
     {?DB_PAY_LOG_INDEX_P, 
      [
       {disc_copies, [node()]},
       {type, set},
       {record_name, r_pay_log_index},
       {attributes, record_info(fields, r_pay_log_index)}
      ]},

     {?DB_SKILL_TIME_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, r_skill_time},
       {attributes, record_info(fields, r_skill_time)}
      ]
     },

     {?DB_FACTION_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, p_faction},
       {attributes, record_info(fields, p_faction)}
      ]
     },
      {?DB_WAROFFACTION_RECORD_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, p_waroffaction_record},
       {attributes, record_info(fields, p_waroffaction_record)}
      ]
     },
      {?DB_WAROFFACTION_COUNTER_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, r_waroffaction_counter},
       {attributes, record_info(fields, r_waroffaction_counter)}
      ]
     },
     {?DB_WAROFKING_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, db_warofking},
       {attributes, record_info(fields, db_warofking)}
      ]},
     {?DB_YBC_P, 
      [{record_name, r_ybc},
       {attributes, record_info(fields, r_ybc)},
       {disc_copies, [node()]}
      ]
     },
     {?DB_YBC_INDEX_P, 
      [{record_name, r_ybc_index},
       {attributes, record_info(fields, r_ybc_index)},
       {disc_copies, [node()]}
      ]
     },
     {?DB_YBC_UNIQUE_P, 
      [{record_name, r_ybc_unique},
       {attributes, record_info(fields, r_ybc_unique)},
       {disc_copies, [node()]}
      ]
     },
     {?DB_YBC_PERSON_P, 
      [{record_name, r_ybc_person},
       {attributes, record_info(fields, r_ybc_person)},
       {disc_copies, [node()]}
      ]},
      {?DB_CONFIG_SYSTEM_P,
        ?DEF_DISK_TABLE(set,r_config_system)
	   },
      %%记录系统维护的配置表，不持久化
      {?DB_CONFIG_MATAIN,
      [ {ram_copies, [node()]}, 
        {type, set},
        {record_name, r_config_matain}, 
        {attributes, record_info(fields, r_config_matain)} ]},
      
     {?DB_EQUIP_ONEKEY_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, r_equip_onekey},
       {attributes, record_info(fields, r_equip_onekey)}
      ]},
     {?DB_EVENT_STATE_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, r_event_state},
       {attributes, record_info(fields, r_event_state)}
      ]},
     {?DB_COUNTER_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, r_counter},
       {attributes, record_info(fields, r_counter)}
      ]},
     
     %% 平台赠送礼券
     {?DB_PLATFORM_POINT_LOG_P,
        ?DEF_DISK_TABLE(set,r_platform_point_log)},
     
     %% 排行榜奖励
     {?DB_ROLE_RANKREWARD_P,
        ?DEF_DISK_TABLE(set,r_role_rankreward)},
     %% 商贸活动
     {?DB_ROLE_TRADING_P,
        ?DEF_DISK_TABLE(set,r_role_trading)},
     %% 宗族仓库
     {?DB_FAMILY_DEPOT_P,
        ?DEF_DISK_TABLE(set,r_family_depot)},
     %% 宗族的资产表
     {?DB_FAMILY_ASSETS_P,
        ?DEF_DISK_TABLE(set,r_family_assets)},
     %% 宗族商店
     {?DB_FAMILY_SHOP_P,
        ?DEF_DISK_TABLE(set,r_family_shop)},
     {?DB_FAMILY_COLLECT_ROLE_PRIZE_INFO_P,
        ?DEF_DISK_TABLE(set,p_family_collect_role_prize_info)},
     %% 神秘商店
    {?DB_SHOP_BUY_INFO_P,
            ?DEF_DISK_TABLE(set,r_shop_buy_info)},
     %% 鲜花
     {?DB_ROLE_RECEIVE_FLOWERS_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, r_receive_flowers},
       {attributes, record_info(fields, r_receive_flowers)}
      ]},
     {?DB_ROLE_GIVE_FLOWERS_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, r_give_flowers},
       {attributes, record_info(fields, r_give_flowers)}
      ]},
     {?DB_ROLE_GIVE_FLOWERS_RANK_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, p_role_give_flowers_rank},
       {attributes, record_info(fields, p_role_give_flowers_rank)}
      ]},
     {?DB_ROLE_GIVE_FLOWERS_TODAY_RANK_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, p_role_give_flowers_today_rank},
       {attributes, record_info(fields, p_role_give_flowers_today_rank)}
      ]},
     {?DB_ROLE_GIVE_FLOWERS_YESTERDAY_RANK_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, p_role_give_flowers_yesterday_rank},
       {attributes, record_info(fields, p_role_give_flowers_yesterday_rank)}
      ]},
      {?DB_ROLE_GIVE_FLOWERS_LAST_WEEK_RANK_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, p_role_give_flowers_last_week_rank},
       {attributes, record_info(fields, p_role_give_flowers_last_week_rank)}
      ]},
      {?DB_ROLE_GIVE_FLOWERS_THIS_WEEK_RANK_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, p_role_give_flowers_this_week_rank},
       {attributes, record_info(fields, p_role_give_flowers_this_week_rank)}
      ]},
     {?DB_ROLE_RECE_FLOWERS_RANK_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, p_role_rece_flowers_rank},
       {attributes, record_info(fields, p_role_rece_flowers_rank)}
      ]},
     {?DB_ROLE_RECE_FLOWERS_TODAY_RANK_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, p_role_rece_flowers_today_rank},
       {attributes, record_info(fields, p_role_rece_flowers_today_rank)}
      ]},
     {?DB_ROLE_RECE_FLOWERS_YESTERDAY_RANK_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, p_role_rece_flowers_yesterday_rank},
       {attributes, record_info(fields, p_role_rece_flowers_yesterday_rank)}
      ]},
     {?DB_ROLE_RECE_FLOWERS_LAST_WEEK_RANK_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, p_role_rece_flowers_last_week_rank},
       {attributes, record_info(fields, p_role_rece_flowers_last_week_rank)}
      ]},
     {?DB_ROLE_RECE_FLOWERS_THIS_WEEK_RANK_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, p_role_rece_flowers_this_week_rank},
       {attributes, record_info(fields, p_role_rece_flowers_this_week_rank)}
      ]},
     {?DB_MONEY_EVENT_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, r_money_event},
       {attributes, record_info(fields, r_money_event)}
      ]},
     {?DB_MONEY_EVENT_COUNTER_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, r_money_event_counter},
       {attributes, record_info(fields, r_money_event_counter)}
      ]},
     {?DB_USER_EVENT_COUNTER_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, r_user_event_counter},
       {attributes, record_info(fields, r_user_event_counter)}
      ]},
     {?DB_USER_EVENT_P,
      [{disc_copies, [node()]},
       {type, set},
       {record_name, r_user_event},
       {attributes, record_info(fields, r_user_event)}
      ]},
	  {?DB_ROLE_CONSUME_TODAY_RANK_P, 
	   [{record_name, p_role_consume_today_rank},
		{attributes, record_info(fields, p_role_consume_today_rank)},
		{disc_copies, [node()]}
	   ]},
	  {?DB_ROLE_CONSUME_YESTERDAY_RANK_P, 
	   [{record_name, p_role_consume_today_rank},
		{attributes, record_info(fields, p_role_consume_today_rank)},
		{disc_copies, [node()]}
	   ]},
     %% 玩家活动状态表
     {?DB_ROLE_ACTIVITY_P,
      ?DEF_DISK_TABLE(set, r_role_activity)},
     %% 记录玩家充值活动情况的表
     {?DB_PAY_ACTIVITY_P, 
      ?DEF_DISK_TABLE(set, r_pay_activity)}, 
     %% 国战   
     {?DB_WAROFFACTION_P,
      ?DEF_DISK_TABLE(set,r_waroffaction)},
     %%异兽
     {?DB_PET_P,
      ?DEF_DISK_TABLE(set, p_pet)},
     {?DB_ROLE_PET_GROW,
      ?DEF_DISK_TABLE(set, p_role_pet_grow )},
     {?DB_ROLE_PET_BAG_P,
      ?DEF_DISK_TABLE(set, p_role_pet_bag)},
	 {?DB_PET_EGG_P,
      ?DEF_DISK_TABLE(set, p_role_pet_egg_type_list)},
     {?DB_PET_TASK,
      ?DEF_DISK_TABLE(set, r_pet_task)},
     {?DB_USER_DATA_LOAD_MAP_P,
      ?DEF_DISK_TABLE(set, r_user_data_load_map)},
     {?DB_SPY_P,
      ?DEF_DISK_TABLE(set, r_spy)},
     %% 赠品模块
     {?DB_ROLE_PRESENT_P,
      ?DEF_DISK_TABLE(set, r_role_present)},     
     {?DB_ROLE_PRESENT_REDBAG_P,
      ?DEF_DISK_TABLE(set, r_role_present_redbag)},     
     %% 宗族技能模块
     {?DB_FAMILY_SKILL_RESEARCH_P,
      ?DEF_DISK_TABLE(set, r_family_skill_research)},   
     %% 日常活动/福利模块
     {?DB_ROLE_ACTIVITY_TASK_P,
      ?DEF_DISK_TABLE(set, r_role_activity_task)}, 
     {?DB_ROLE_ACTIVITY_BENEFIT_P,
      ?DEF_DISK_TABLE(set, r_role_activity_benefit)}, 
     {?DB_SYSTEM_NOTICE_P,
      ?DEF_DISK_TABLE(set,r_system_notice)},
     %% 玩家参与宗族活动的记录
     {?DB_ROLE_FAMILY_PARTTAKE_P,
      ?DEF_DISK_TABLE(set,r_role_family_parttake)},
     %% 离线消息
     {?DB_OFFLINE_MSG_P,
      ?DEF_DISK_TABLE(set,r_offline_msg)},
     {?DB_ROLE_ACCUMULATE_EXP_P,
      ?DEF_DISK_TABLE(set,r_role_accumulate_exp)},
     {?DB_ROLE_ACCUMULATE_P,?DEF_DISK_TABLE(set,r_role_accumutlate)},
     {?DB_COMMON_LETTER_P, 
      ?DEF_DISK_TABLE(set,r_common_letter)},
     {?DB_PERSONAL_LETTER_P,
      ?DEF_DISK_TABLE(set,r_personal_letter)},
     {?DB_PUBLIC_LETTER_P,
      ?DEF_DISK_TABLE(set,r_public_letter)},
     {?DB_WORLD_COUNTER_P,
      ?DEF_DISK_TABLE(set,r_world_counter)},
     %% 场景大战副本
     {?DB_SCENE_WAR_FB_P,?DEF_DISK_TABLE(set,r_scene_war_fb)},
     %% 玩家礼包表
     {?DB_ROLE_GIFT_P,?DEF_DISK_TABLE(set,r_role_gift)},
     {?DB_ROLE_HERO_FB_P,?DEF_DISK_TABLE(set, r_hero_fb)},
     %% 英雄副本
     {?DB_HERO_FB_RECORD_P, ?DEF_DISK_TABLE(set, r_hero_fb_record)},
     %% 任务任务副本
     {?DB_ROLE_MISSION_FB_P, ?DEF_DISK_TABLE(set, r_role_mission_fb)},
     %% 竞技场
     {?DB_ROLE_ARENA_P, ?DEF_DISK_TABLE(set, r_role_arena)},
     %%禁言配置表
     {?DB_BAN_CONFIG_P,?DEF_DISK_TABLE(set,r_ban_config)},
     {?DB_ROLE_MONSTER_DROP_P, ?DEF_DISK_TABLE(set, r_role_monster_drop)},
     
     %%上古战场的奖励数据
     {?DB_ROLE_NATIONBATTLE_P, ?DEF_DISK_TABLE(set, r_role_nationbattle)},
     {?DB_ROLE_NPC_DEAL_P, ?DEF_DISK_TABLE(set, r_role_npc_deal)},
     %% 开箱子表
     {?DB_ROLE_BOX_P,?DEF_DISK_TABLE(set,r_role_box)},
     {?DB_BOX_GOODS_LOG_P,?DEF_DISK_TABLE(set,r_box_goods_log)},
	   %%神游三界/月光宝盒表
     {?DB_TREASBOX_LOG_P,?DEF_DISK_TABLE(bag,p_treasbox_log)},
     %% 传奇目标
     {?DB_ROLE_GOAL_P, ?DEF_DISK_TABLE(set, r_goal)},
     {?DB_ACTIVITY_REWARD_P,?DEF_DISK_TABLE(set,r_activity_reward)},
     {?DB_PAY_FAILED_P, ?DEF_DISK_TABLE(set, r_pay_failed)},
     {?DB_ACCOUNT_REBIND_P, ?DEF_DISK_TABLE(set, r_account_rebind)},
     %% 全服成就表
     {?DB_ACHIEVEMENT_RANK_P,?DEF_DISK_TABLE(set,r_achievement_rank)},
     %% 异兽扩展信息
     {?DB_PET_TRAINING_P,?DEF_DISK_TABLE(set,r_pet_training)},
     %% 宗族捐献
     {?DB_FAMILY_DONATE_P,?DEF_DISK_TABLE(set,r_family_donate)},
     %% 人物培养
     {?DB_ROLE_GROW_P,?DEF_DISK_TABLE(set,r_role_grow)},
     %% 引导性提示
     {?DB_ROLE_GUIDE_TIP_P,?DEF_DISK_TABLE(set,r_role_guide_tip)},
     %% 精力丹使用记录
     {?DB_ROLE_ENERGY_DRUG_USAGE_P,?DEF_DISK_TABLE(set,r_role_energy_drug_usage)},
	 %% 天焚炼气塔领取记录
     {?DB_ROLE_LIANQI_P,?DEF_DISK_TABLE(set,r_role_lianqi)},
     %% 初出茅庐境界榜
     {?DB_ROLE_JINGJIE_RANK_P,?DEF_DISK_TABLE(set,p_jingjie_rank)},
     {?DB_ROLE_JINGJIE_RANK_YESTERDAY_P,?DEF_DISK_TABLE(set,p_jingjie_rank_yesterday)},
     %% 战斗力排行榜表
     {?DB_ROLE_FIGHTING_POWER_RANK_P,?DEF_DISK_TABLE(set,p_role_fighting_power_rank)},
     {?DB_ROLE_FIGHTING_POWER_RANK_YESTERDAY_P,?DEF_DISK_TABLE(set,p_role_fighting_power_rank_yesterday)},
     %% 财神到领取记录
     {?DB_ROLE_CAISHEN_P,?DEF_DISK_TABLE(set,r_role_caishen)},
     %% 富甲天下定时活动排名
     {?DB_ACTIIVITY_SILVER_RANK_P,?DEF_DISK_TABLE(set,r_activity_rank)},
     %% 经验多多定时活动排名
     {?DB_ACTIIVITY_EXP_RANK_P,?DEF_DISK_TABLE(set,r_activity_rank)},
     %% 神兵之王定时活动排名
     {?DB_ACTIIVITY_EQUIP_RANK_P,?DEF_DISK_TABLE(set,r_activity_rank)},
     %% 毁灭之王定时活动排名
     {?DB_ACTIIVITY_BOSS_RANK_P,?DEF_DISK_TABLE(set,r_activity_rank)},
          %% 特殊活动，信件奖励
     {?DB_SPECIAL_REWARD_P,?DEF_DISK_TABLE(set,r_special_reward)},
     %% 定时活动领取记录
     {?DB_ACTIVITY_RANK_REWARD_P,?DEF_DISK_TABLE(set,r_activity_rank_reward)},
     %% 开服活动
     {?DB_OPEN_ACTIVITY_P,?DEF_DISK_TABLE(set,r_open_activity)},
     %% 检验副本表
     {?DB_ROLE_EXAMINE_FB_P, ?DEF_DISK_TABLE(set,r_role_examine_fb)},
     %% 金矿之战的玩家表
     {?DB_ROLE_MINE_FB_P, ?DEF_DISK_TABLE(set,r_role_mine_fb)},
     %% 金矿之战的矿工数据表
     {?DB_MINER_DATA_P, ?DEF_DISK_TABLE(set,r_miner_data)},
	 %% 神器
     {?DB_ROLE_SHENQI_P,?DEF_DISK_TABLE(set,r_role_shenqi)},
     %% 玩家限量抢购
     {?DB_ROLE_BAG_SHOP_P,?DEF_DISK_TABLE(set,r_role_bag_shop)},
     %% VIP
     {?DB_ROLE_VIP_P,?DEF_DISK_TABLE(set,r_role_vip)},
     %% 玩家每日累计充值奖励领取记录
     {?DB_ROLE_DAILY_PAY_REWARD_P,?DEF_DISK_TABLE(set,r_role_daily_pay_reward)},
     %% 国家等级信息
     {?DB_FACTION_INFO_P,?DEF_DISK_TABLE(set,r_faction_info)},
     %%钦点美人
     {?DB_HORSE_RACING_P, ?DEF_DISK_TABLE(set,r_horse_racing)},
     %% 钦点美人奖励表
     {?DB_HORSE_RACING_REWARD_P, ?DEF_DISK_TABLE(set,r_horse_racing_reward)},
     %% 钦点美人全服所有玩家的日志
     {?DB_HORSE_RACING_ALL_LOG_P, ?DEF_DISK_TABLE(set,r_horse_racing_all_log)}, 
      %% 累计元宝消费表
     {?DB_ROLE_ACCGOLD_P,?DEF_DISK_TABLE(set,r_role_accgold)},
	 %%个人排名镜像表
	 {?DB_RNKM_MIRROR_P, ?DEF_DISK_TABLE(set,r_rnkm_mirror)},
	 {?DB_RNKM_ROLE_P, ?DEF_DISK_TABLE(set,r_rnkm_role)},
	 %%擂台赛镜像表
	 {?DB_CLGM_MIRROR_P, ?DEF_DISK_TABLE(set,r_clgm_mirror)},
	 {?DB_CLGM_ROLE_P, ?DEF_DISK_TABLE(set,r_clgm_role)},
	 {?DB_CLGM_GIVEN_EQUIP_P, ?DEF_DISK_TABLE(set,r_clgm_given_equip)},
	 %%体力表
	 {?DB_ROLE_TILI_P, ?DEF_DISK_TABLE(set,r_role_tili)},
	 %%特殊道具每天使用次数表
	 {?DB_ITEM_USE_LIMIT_P, ?DEF_DISK_TABLE(set,r_item_use_limit)},
	  %% 产出告知完成记录
     {?DB_ROLE_ACCESS_GUIDE_P,?DEF_DISK_TABLE(set,r_access_guide)},
	  %%目标，成就，封神引导
		{?DB_GUIDE_P,?DEF_DISK_TABLE(set,r_guide)},
	  %% 日常循环任务表
     {?DB_ROLE_DAILY_MISSION_P,?DEF_DISK_TABLE(set,r_role_daily_mission)},
	  %% VIP转盘
	 {?DB_ROLE_LOTO_P,
	  ?DEF_DISK_TABLE(set, r_role_loto)},
	  %% 魔尊洞窟表
     {?DB_ROLE_GUARD_FB_P,?DEF_DISK_TABLE(set,r_role_guard_fb)},
	  %% 精炼
     {?DB_JINGLIAN_P,?DEF_DISK_TABLE(set,r_jinglian)},
	 {?DB_ROLE_MISC_P, ?DEF_DISK_TABLE(set,r_role_misc)},
	  %% 神王令表
     {?DB_ROLE_SWL_MISSION_P,?DEF_DISK_TABLE(set,r_role_swl_mission)},
     %% 离线事件表
     {?DB_OFFLINE_EVENT_P,?DEF_DISK_TABLE(set, r_offline_event)},
     %% 玄冥塔
     {?DB_ROLE_TOWER_P, ?DEF_DISK_TABLE(set, r_role_tower_fb)},
     %% 玄冥塔最佳排名
     {?DB_BEST_TOWER_P, ?DEF_DISK_TABLE(set, r_best_tower_fb)}
    ].
