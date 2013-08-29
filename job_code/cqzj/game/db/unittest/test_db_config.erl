%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_db_config).
-include("mnesia.hrl").


%%
%% Include files
%%


%%%%%%%%%%%%%%%%% 友情提示
%% gen_defines()用于生成表定义文件
%% gen_config()用于生成 db.config

%%
%% Exported Functions
%%
-export([]).
-compile(export_all).
-define( INFO(F,D),io:format(F, D) ).
-define( GET_ATTRS(Rec),get_attrs(Rec,record_info(fields,Rec)) ).

gen_defines()->
    Bytes = io_lib:format("~p", [table_defines()]),
    file:write_file("/data/table_defines.txt", list_to_binary(Bytes) ),
    ok.

bag_table_defines()->
	[{db_friend,?GET_ATTRS(r_friend)},
	 {db_chat_channel_roles,?GET_ATTRS(p_chat_channel_role_info)},
	 {db_chat_role_channels,?GET_ATTRS(r_chat_role_channel_info)},
	 {db_family_invite,?GET_ATTRS(p_family_invite_info)},
	 {db_family_request,?GET_ATTRS(p_family_request_info)}
	].

%%
%% API Functions
%%
table_defines()->
    [{db_role_faction,?GET_ATTRS(r_role_faction)},
     {db_account,?GET_ATTRS(r_account)},
     {t_log_super_item,?GET_ATTRS(p_goods)},
     {db_role_attr,?GET_ATTRS(p_role_attr)},
     {db_role_base,?GET_ATTRS(p_role_base)},
     {db_role_fight,?GET_ATTRS(p_role_fight)},
     {db_role_pos,?GET_ATTRS(p_role_pos)},
     {db_role_ext,?GET_ATTRS(p_role_ext)},
     {db_roleid_counter,?GET_ATTRS(r_roleid_counter)},
     {db_monster_persistent_info,?GET_ATTRS(r_monster_persistent_info)},
     {db_monsterid_couter,?GET_ATTRS(r_monsterid_counter)},
     {db_role_state,?GET_ATTRS(r_role_state)},
     {db_stall,?GET_ATTRS(r_stall)},
     {db_stall_silver,?GET_ATTRS(r_stall_silver)},
     {db_stall_goods,?GET_ATTRS(r_stall_goods)},
     {db_stall_goods_tmp,?GET_ATTRS(r_stall_goods)},
     {goods_map,?GET_ATTRS(p_goods)},
     {db_role_bag,?GET_ATTRS(r_role_bag)},
     {role_buffs,?GET_ATTRS(r_role_buf)},

     {letter_sender,?GET_ATTRS(r_letter_sender)},
     {letter_receiver,?GET_ATTRS(r_letter_receiver)},
     {db_shortcut_bar,?GET_ATTRS(r_shortcut_bar)},
     {db_broadcast_message,?GET_ATTRS(r_broadcast_message)},
     {db_family,?GET_ATTRS(p_family_info)},
     {db_family_ext,?GET_ATTRS(r_family_ext)},
     {db_family_summary,?GET_ATTRS(p_family_summary)},
     {db_family_counter,?GET_ATTRS(r_family_counter)},
     {db_chat_channels,?GET_ATTRS(p_channel_info)},
     {db_fcm_data,?GET_ATTRS(r_fcm_data)},
     {db_key_process,?GET_ATTRS(r_key_process)},
     {db_system_config,?GET_ATTRS(r_sys_config)},
     {db_role_level_rank,?GET_ATTRS(p_role_level_rank)},
     {db_normal_title,?GET_ATTRS(p_title)},
     {db_spec_title,?GET_ATTRS(p_title)},
     {db_title_counter,?GET_ATTRS(r_title_counter)},
     {db_role_pkpoint_rank,?GET_ATTRS(p_role_pkpoint_rank)},
     {db_role_world_pkpoint_rank,?GET_ATTRS(p_role_pkpoint_rank)},
     {db_family_active_rank,?GET_ATTRS(p_family_active_rank)},
     {db_equip_refining_rank,?GET_ATTRS(p_equip_rank)},
     {db_equip_reinforce_rank,?GET_ATTRS(p_equip_rank)},
     {db_equip_stone_rank,?GET_ATTRS(p_equip_rank)},
     {db_role_gongxun_rank,?GET_ATTRS(p_role_gongxun_rank)},
     {db_family_gongxun_persistent_rank,
      ?GET_ATTRS(p_family_gongxun_persistent_rank)},
     {db_ban_user,?GET_ATTRS(r_ban_user)},
     {db_ban_ip,?GET_ATTRS(r_ban_ip)},
     {db_pay_log,?GET_ATTRS(r_pay_log)},
     {db_pay_log_index,?GET_ATTRS(r_pay_log_index)},
     {db_faction,?GET_ATTRS(p_faction)},
     {?DB_PET,?GET_ATTRS(p_pet)}
    ].


get_attrs(Record,Fields)->
	AttrList = [ {R,int} || R<-Fields],
	[{type, set},
	 {record_name,Record},
 	{attributes, AttrList }].