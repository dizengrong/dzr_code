
%%%-------------------------------------------------------------------
%%% @author Liangliang <Liangliang@gmail.com>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  9 Jun 2010 by Liangliang <Liangliang@gmail.com>
%%%-------------------------------------------------------------------
-module(common_misc).

-include("common.hrl").
-include("common_server.hrl").

-export([
         manage_applications/6, 
         start_applications/1, 
         stop_applications/1
        ]).

-export([check_in_special_time/2]).

-export([send_role_silver_change/2,
         send_role_gold_change/2,
         send_role_prestige_change/2,
         send_role_yueli_change/2,
         send_role_medals_change/2,
		 send_role_gold_silver_change/2
        ]).

-export([
         get_prop_type/1,
         get_team_proccess_name/1,
         get_home_mapid/2,
         get_home_born/0,
         get_level_base_hp/1,
         get_level_base_mp/1,
         get_role_fcm_cofficient/1,
         get_common_map_name/1,
         get_role_detail/1,
		 get_newcomer_mapid/1,
         get_home_map_id/1,
         gene_tcp_client_socket_name/1,
         whereis_name/1,
         register/3,
         unicast/6,
         unicast/5,
         unicast/2,
         broadcast/4,
         broadcast/5,
         broadcast/6,
         broadcast_to_line/4,
         broadcast_include_self/4,
         send_to_rolemap/2,
         send_to_rolemap/3,
         send_to_rolemap_mod/3,
         diff_time/1,
         diff_time/2,
         diff_time/3,
         diff_g_seconds/1,
         get_dirty_rolename/1,
         get_dirty_role_attr/1,
         get_dirty_role_base/1,
         get_dirty_role_pos/1,
         get_dirty_role_fight/1,
         get_dirty_role_ext/1,
         get_dirty_mapid_by_roleid/1,
         get_iso_index_mid_vertex/3,
		 get_dir/2,
         get_role_line_by_id/1,
         set_role_line_by_id/2,
         remove_role_line_by_id/1,
         get_max_role_id/0,
         tcp_name/3,
         get_map_name/1,
		 is_role_on_map/1,
		 is_role_on_gateway/1,
		 is_role_on_gateway/2,
         is_role_online/1,
		 is_role_online2/1,
         get_online_role_ip/1,
         is_role_fighting/1,
         is_role_auto_stalling/1,
         is_role_exchanging/1,
         unicast2/5,
         unicast2_direct/5,
         is_abort/1,
         get_roleid/1,
         team_add_role_exp/1,
         team_get_can_pick_goods_role/1,
         team_get_team_member/1,
         new_goods_notify/2,
         del_goods_notify/2,
         update_goods_notify/2,
         get_born_info_by_map/1,
         role_attr_change_notify/3,
         do_calculate_equip_refining_index/1,
         get_dirty_role_state/1,
         if_friend/2,
         if_reach_day_friendly_limited/3,
         get_role_map_process_name/1,
         make_common_monster_process_name/4,
         make_summon_monster_process_name/1,
         make_family_boss_process_name/2,
         make_family_process_name/1,
         get_role_line_process_name/1,
         if_in_self_country/2,
         if_in_enemy_country/2,
         format_silver/2,
         format_silver/1,
         format_lang/2,
         get_dirty_stall_goods/1,
         get_dirty_bag_goods/1,
         is_role_data_loaded/1,
         get_event_state/1,
         set_event_state/2,
         del_event_state/1,
         dirty_get_new_counter/1,
         trans_get_new_counter/1,
         
         done_task/2,
         check_distance/6,
         send_to_map/2,
         format_goods_name_colour/2,
         get_equip_ring_color/1,
         if_in_neutral_area/1,
         is_in_noattack_buff_valid_map/1,
         send_to_map_mod/3,
         check_time_conflict/5,
         get_end_time/3,
         get_stall_map_pid/1,
         get_stall_map_id/1,
         get_jingcheng_mapid/1,
         generate_map_id_by_faction/2,
         get_all_map_pid/0,
         get_role_name_color/2,
         notify_del_equip/2,
         get_all_online_roleid/0,
		 get_equip_quality_by_color/1,
		 send_common_error/3,
         term_to_string/1,
         get_mail_items_create_info/2,
         get_items_create_info/2,
         parse_aborted_err/1,
		 get_color_name/1,
		 get_color_by_quality/1,
		 get_color_name_by_quality/1
        ]).

-export([update_dict_queue/2,
         update_dict_set/2]).

-export([
         check_name/1,
         get_role_pid/1,
         get_roleid_by_accountname/1,
         get_faction_name/1,
		 get_category_name/1,
         get_faction_color_name/1,
         get_map_faction_id/1,
         add_exp_unicast/2,
		 role_total_pay_gold/1,
         ceil_div/2
        ]).

-export([chat_get_role_pname/1,
         chat_join_team_channel/2,
         chat_join_family_channel/2,
         chat_leave_team_channel/2,
         chat_leave_family_channel/2,
         chat_get_world_channel_pname/0,
         chat_get_faction_channel_pname/1,
         chat_get_family_channel_pname/1,
         chat_get_team_channel_pname/1,
         chat_get_world_channel_info/0,
         chat_get_faction_channel_info/1,
         chat_get_family_channel_info/1,
         chat_get_team_channel_info/1,
         
         chat_broadcast_to_world/3,
         chat_broadcast_to_faction/4,
         chat_broadcast_to_family/4,
         chat_broadcast_to_team/4,
         
         chat_broadcast_to_world/4,
         chat_broadcast_to_faction/5,
         chat_broadcast_to_family/5,
         chat_broadcast_to_team/5,
         chat_broadcast_to_role/4,
         chat_cast_role_router/2
         ]).

-export([print_pay_error_msg/2,
         get_collect_break_msg/2]).
-export([format_goods_name/1, common_broadcast_item_get/3, common_broadcast_other/3]).


%% 这个接口是对各个系统的物品的广播
%% Where参数可以设置为每个模块的?MODULE，然后在配置文件cfg_broadcast中添加说明
common_broadcast_item_get(RoleID, ItemTypeId, Where) when is_integer(RoleID) ->
    {ok, #p_role_base{role_name = RoleName}} = mod_map_role:get_role_base(RoleID),
    common_broadcast_item_get(RoleName, ItemTypeId, Where);
common_broadcast_item_get(RoleName, ItemTypeId, Where) ->  
    try  
        [#p_item_base_info{itemname=Itemname}] = common_config_dyn:find(item, ItemTypeId),
        case cfg_broadcast:center_broadcast(ItemTypeId, Itemname, RoleName, Where) of
            ignore -> ignore;
            Msg1 ->
                catch ?WORLD_CENTER_BROADCAST(Msg1)
        end,
        case cfg_broadcast:chat_broadcast(ItemTypeId, Itemname, RoleName, Where) of
            ignore -> ignore;
            Msg2 ->
                catch ?WORLD_CHAT_BROADCAST(Msg2)
        end
    catch 
        Type:Error ->  
            ?ERROR_MSG("common broadcast error, type: ~w, error: ~w", [Type, Error])
    end. 

%% 这个接口和common_broadcast_item_get类似，Datas可以为每个系统自定义的数据格式，然后传给配置
common_broadcast_other(RoleID, Datas, Where) when is_integer(RoleID) ->
    {ok, #p_role_base{role_name = RoleName}} = mod_map_role:get_role_base(RoleID),
    common_broadcast_other(RoleName, Datas, Where);
common_broadcast_other(RoleName, Datas, Where) ->
    try
        case cfg_broadcast:center_broadcast(Datas, RoleName, Where) of
            ignore -> ignore;
            Msg1 ->
                catch ?WORLD_CENTER_BROADCAST(Msg1)
        end,
        case cfg_broadcast:chat_broadcast(Datas, RoleName, Where) of
            ignore -> ignore;
            Msg2 ->
                catch ?WORLD_CHAT_BROADCAST(Msg2)
        end
    catch
        Type:Error ->  
            ?ERROR_MSG("common broadcast error, type: ~w, error: ~w, stacktrace:~w", [Type, Error, erlang:get_stacktrace()])
    end. 

%% 对A除以B的商向上取整
ceil_div(A, B) ->
    C = A div B,
    case A rem B == 0 of
        true -> C;
        false -> C + 1
    end.
%%@doc 发送元宝更新的通知,发送钱币更新的通知
send_role_gold_silver_change(RoleID,RoleAttr)when is_integer(RoleID)->
    #p_role_attr{silver=Silver,silver_bind=SilverBind,gold=Gold,gold_bind=GoldBind} = RoleAttr,
    ChangeAttList = [#p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE,new_value=SilverBind},
                     #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE,new_value=Silver},
					 #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE,new_value=GoldBind},
                     #p_role_attr_change{change_type=?ROLE_GOLD_CHANGE,new_value=Gold}
                     ],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList).

%%@doc 发送钱币更新的通知
send_role_silver_change(RoleID,RoleAttr)when is_integer(RoleID)->
    #p_role_attr{silver=Silver,silver_bind=SilverBind} = RoleAttr,
    ChangeAttList = [#p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE,new_value=SilverBind},
                     #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE,new_value=Silver}
                     ],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList).

%%@doc 发送元宝更新的通知
send_role_gold_change(RoleID,RoleAttr)when is_integer(RoleID)->
    #p_role_attr{gold=Gold,gold_bind=GoldBind} = RoleAttr,
    ChangeAttList = [#p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE,new_value=GoldBind},
                     #p_role_attr_change{change_type=?ROLE_GOLD_CHANGE,new_value=Gold}
                    ],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList).
%%@doc 发送声望更新的通知
send_role_prestige_change(RoleID,RoleAttr) when erlang:is_integer(RoleID) ->
    #p_role_attr{sum_prestige=SumPrestige,cur_prestige=CurPrestige} = RoleAttr,
    ChangeAttList = [#p_role_attr_change{change_type=?ROLE_SUM_PRESTIGE_CHANGE,new_value=SumPrestige},
                     #p_role_attr_change{change_type=?ROLE_CUR_PRESTIGE_CHANGE,new_value=CurPrestige}
                    ],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList).

%%@doc 发送阅历更新的通知
send_role_yueli_change(RoleID,RoleAttr) when erlang:is_integer(RoleID) ->
    #p_role_attr{yueli=Yueli} = RoleAttr,
    ChangeAttList = [#p_role_attr_change{change_type=?ROLE_YUELI_ATTR_CHANGE,new_value=Yueli}],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList).

send_role_medals_change(RoleID,RoleAttr) when is_record(RoleAttr,p_role_attr)->
    #p_role_attr{medals=Medals} = RoleAttr,
    send_role_medals_change(RoleID,Medals);
send_role_medals_change(RoleID,Medals) when is_list(Medals)->
    R2 = #m_role2_medal_change_toc{roleid=RoleID,medals=Medals},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_MEDAL_CHANGE, R2).
    
%%加经验接口放在world是很扯淡的事情
%%角色里的加经验代码将会移动到这里 这个接口实现后可认为是事务安全的
add_exp_unicast(RoleID, ExpNum) ->
    send_to_rolemap(RoleID, {mod_map_role, {add_exp, RoleID, ExpNum}}).

get_faction_name(FactionID) ->
    proplists:get_value(FactionID, [{1, <<"西夏">>},
                                    {2, <<"南诏">>},
                                    {3, <<"东周">>}
                                    ]).
    % proplists:get_value(FactionID, [{1, <<"蚩尤">>},
    %                                 {2, <<"神农">>},
    %                                 {3, <<"轩辕">>}
    %                                 ]).
get_category_name(Category) ->
    proplists:get_value(Category, [{1, <<"武者">>},
                                    {2, <<"武者">>},
                                    {3, <<"法师">>},
                                  {4, <<"法师">>}
                                    ]).
	% proplists:get_value(Category, [{1, <<"玄武">>},
 %                                    {2, <<"白虎">>},
 %                                    {3, <<"朱雀">>},
	% 								{4, <<"青龙">>}
 %                                    ]).
get_faction_color_name(1)->
    ?_LANG_COLOR_FACTION_1;
get_faction_color_name(2)->
    ?_LANG_COLOR_FACTION_2;
get_faction_color_name(3)->
    ?_LANG_COLOR_FACTION_3.


%%检查一个名字是否合法（关键字过滤判断)
check_name(Name) ->
    lists:any(
      fun(P) ->
              case re:run(Name, P) of
                  nomatch ->
                      false;
                  _ ->
                      true
              end
      end, data_filter:name()).



chat_cast_role_router(RoleName_RoleID, RouterData) ->

    RoleProcessName = chat_get_role_pname(RoleName_RoleID),
    case global:whereis_name(RoleProcessName) of
        undefined ->
            {error, not_exists};
        Pid ->
            gen_server:cast(Pid, {router, RouterData}),
            {ok, Pid}
    end.

%%@doc 获取玩家的聊天节点进程名字
chat_get_role_pname(RoleID) when erlang:is_integer(RoleID) ->
    case catch get_dict_role_base(RoleID) of
        {ok,#p_role_base{role_name=RoleName}}->
            next;
        _ ->
            {ok, #p_role_base{role_name=RoleName}} = get_dirty_role_base(RoleID)
    end,
    lists:concat(["chat_role_", common_tool:to_list(RoleName)]);

chat_get_role_pname(RoleName) when erlang:is_list(RoleName) ->
    lists:concat(["chat_role_", RoleName]);

chat_get_role_pname(RoleName) when erlang:is_binary(RoleName) ->
    lists:concat(["chat_role_", common_tool:to_list(RoleName)]).

chat_get_world_channel_pname() ->
    ?CHANNEL_SIGN_WORLD.
chat_get_world_channel_info() ->
    ChannelSign = chat_get_world_channel_pname(),
    ChannelInfo = #p_channel_info{channel_sign=ChannelSign, 
                                  channel_type=?CHANNEL_TYPE_WORLD, 
                                  channel_name=?_LANG_CHANNEL_WORLD},
    {ChannelSign, ChannelInfo}.

%%聊天广播接口
chat_broadcast_to_world(Module, Method, DataRecord) ->
    ChannelPName = chat_get_world_channel_pname(),
    do_chat_broadcast_to_channel(ChannelPName, 
                                 Module, 
                                 Method, 
                                 DataRecord, 
                                 []).

chat_broadcast_to_world(Module, Method, DataRecord, IgnoreRoleIDList) ->
    ChannelPName = chat_get_world_channel_pname(),
    do_chat_broadcast_to_channel(ChannelPName, 
                                 Module, 
                                 Method, 
                                 DataRecord, 
                                 IgnoreRoleIDList).

chat_get_faction_channel_pname(FactionID) ->
    lists:concat([?CHANNEL_SIGN_FACTION, "_", FactionID]).

chat_get_faction_channel_info(FactionID) ->
    ChannelSign = chat_get_faction_channel_pname(FactionID),
    ChannelInfo = #p_channel_info{channel_sign=ChannelSign, 
                                  channel_type=?CHANNEL_TYPE_FACTION, 
                                  channel_name=?_LANG_CHANNEL_FACTION},
    {ChannelSign, ChannelInfo}.

chat_broadcast_to_faction(FactionID, Module, Method, DataRecord) ->
    ChannelPName = chat_get_faction_channel_pname(FactionID),
    do_chat_broadcast_to_channel(ChannelPName, 
                                 Module, 
                                 Method, 
                                 DataRecord, 
                                 []).

chat_broadcast_to_faction(FactionID, Module, Method, DataRecord, IgnoreRoleIDList) ->
    ChannelPName = chat_get_faction_channel_pname(FactionID),
    do_chat_broadcast_to_channel(ChannelPName, 
                                 Module, 
                                 Method, 
                                 DataRecord, 
                                 IgnoreRoleIDList).

chat_get_family_channel_pname(FamilyID) ->
    lists:concat([?CHANNEL_SIGN_FAMILY, "_", FamilyID]).
chat_get_family_channel_info(FamilyID) ->
    ChannelSign = chat_get_family_channel_pname(FamilyID),
    ChannelInfo = #p_channel_info{channel_sign=ChannelSign, 
                                  channel_type=?CHANNEL_TYPE_FAMILY, 
                                  channel_name=?_LANG_CHANNEL_FAMILY},
    {ChannelSign, ChannelInfo}.

chat_broadcast_to_family(FamilyID, Module, Method, DataRecord) ->
    ChannelPName = chat_get_family_channel_pname(FamilyID),
    do_chat_broadcast_to_channel(ChannelPName, 
                                 Module, 
                                 Method, 
                                 DataRecord, 
                                 []).

chat_broadcast_to_family(FamilyID, Module, Method, DataRecord, IgnoreRoleIDList) ->
    ChannelPName = chat_get_family_channel_pname(FamilyID),
    do_chat_broadcast_to_channel(ChannelPName, 
                                 Module, 
                                 Method, 
                                 DataRecord, 
                                 IgnoreRoleIDList).

chat_get_team_channel_pname(TeamID) ->
    lists:concat([?CHANNEL_SIGN_TEAM, "_", TeamID]).
chat_get_team_channel_info(TeamID) ->
    ChannelSign = chat_get_team_channel_pname(TeamID),
    ChannelInfo = #p_channel_info{channel_sign=ChannelSign, 
                                  channel_type=?CHANNEL_TYPE_TEAM, 
                                  channel_name=?_LANG_CHANNEL_TEAM},
    {ChannelSign, ChannelInfo}.

chat_broadcast_to_team(TeamID, Module, Method, DataRecord) ->
    ChannelPName = chat_get_team_channel_pname(TeamID),
    do_chat_broadcast_to_channel(ChannelPName, 
                                 Module, 
                                 Method, 
                                 DataRecord, 
                                 []).

chat_broadcast_to_team(TeamID, Module, Method, DataRecord, IgnoreRoleIDList) ->
    ChannelPName = chat_get_team_channel_pname(TeamID),
    do_chat_broadcast_to_channel(ChannelPName, 
                                 Module, 
                                 Method, 
                                 DataRecord, 
                                 IgnoreRoleIDList).

chat_join_team_channel(RoleName, TeamID) ->
    RoleChatPName = chat_get_role_pname(RoleName),
    gen_server:cast({global, RoleChatPName}, 
                    {router, {join_channel, team, TeamID}}).

chat_leave_team_channel(RoleName, TeamID) ->
    RoleChatPName = chat_get_role_pname(RoleName),
    gen_server:cast({global, RoleChatPName}, 
                    {router, {leave_channel, team, TeamID}}).

chat_join_family_channel(RoleName, FamilyID) ->
    RoleChatPName = chat_get_role_pname(RoleName),
    gen_server:cast({global, RoleChatPName}, 
                    {router, {join_channel, family, FamilyID}}).

chat_leave_family_channel(RoleName, FamilyID) ->
    RoleChatPName = chat_get_role_pname(RoleName),
    gen_server:cast({global, RoleChatPName}, 
                    {router, {leave_channel, family, FamilyID}}).

do_chat_broadcast_to_channel(ChannelPName, 
                             Module, 
                             Method, 
                             DataRecord, 
                             IgnoreRoleIDList) ->
    gen_server:cast({global, ChannelPName}, 
                    {broadcast, Module, Method, DataRecord, IgnoreRoleIDList}).

chat_broadcast_to_role(RoleID, Module, Method, DataRecord) ->
    chat_cast_role_router(RoleID, {broadcast_msg, Module, Method, DataRecord}).

get_born_info_by_map(MapID) ->
	case mcm:born_tiles(MapID) of
		[{TX, TY}|_] ->
            {MapID, TX, TY};
        _ ->
            error
    end.

manage_applications(Iterate, Do, Undo, SkipError, ErrorTag, Apps) ->
    Iterate(fun (App, Acc) ->
                    case Do(App) of
                        ok -> [App | Acc];
                        {error, {SkipError, _}} -> Acc;
                        {error, Reason} ->
                            lists:foreach(Undo, Acc),
                            throw({error, {ErrorTag, App, Reason}})
                    end
            end, [], Apps),
    ok.

start_applications(Apps) ->
    manage_applications(fun lists:foldl/3,
                        fun application:start/1,
                        fun application:stop/1,
                        already_started,
                        cannot_start_application,
                        Apps).

stop_applications(Apps) ->
    manage_applications(fun lists:foldr/3,
                        fun application:stop/1,
                        fun application:start/1,
                        not_started,
                        cannot_stop_application,
                        Apps).

tcp_name(Prefix, IPAddress, Port)
  when is_atom(Prefix) andalso is_number(Port) ->
    list_to_atom(
      lists:flatten(
        io_lib:format("~w_~s:~w",
                      [Prefix, inet_parse:ntoa(IPAddress), Port]))).


%% get the pid of a registered name
whereis_name({local, Atom}) -> 
    erlang:whereis(Atom);

whereis_name({global, Atom}) ->
    global:whereis_name(Atom).

register(local, Name, Pid) ->
    erlang:register(Name, Pid);
register(global, Name, Pid) ->
    global:register_name(Name, Pid).


gene_tcp_client_socket_name(LSock) ->
    io_lib:format("mgee_tcp_client_~w", [LSock]).


%%--------------------------------------------------------------------------------------
%% 处理玩家所在分线信息
%%--------------------------------------------------------------------------------------
get_role_line_process_name(RoleID) ->
    common_tool:list_to_atom(lists:concat(["mgeeg_account_", RoleID])).
%%获得玩家分线 
get_role_line_by_id(RoleID) ->
    common_role_line_map:get_role_line(RoleID).
%%设置玩家分线
set_role_line_by_id(RoleID, Line) ->
    common_role_line_map ! {set, RoleID, Line}.
%%移除玩家分线
remove_role_line_by_id(RoleID) ->
    common_role_line_map ! {remove, RoleID}.

unicast2(PID, Unique, Module, Method, R) ->
    case erlang:get({pid_to_roleid, PID}) of
        undefined ->
            PID ! {message, Unique, Module, Method, R};
		_ when PID == mirror ->
			ignore;
        _ ->
            Binary = mgeeg_packet:packet_encode(Unique, Module, Method, R),
            mgeem_map:update_role_msg_queue(PID, Binary),
            ok
    end.

%%@doc 直接发送消息到网关，不在Map进行并包处理。
%%     一般只有在退出地图的时候需要用到
unicast2_direct({role, RoleID}, Unique, Module, Method, R2C) when is_integer(RoleID) ->
    case erlang:get({roleid_to_pid, RoleID}) of
        undefined ->
            case common_misc:get_role_line_by_id(RoleID) of
                false ->
                    broadcast([RoleID], Unique, Module, Method, R2C),
                    ignore;
                Line  ->
                    Name = lists:concat(["unicast_server_", Line]),
                    catch global:send(Name, {message, RoleID, Unique, Module, Method, R2C})
            end;
		mirror ->
			ignore;
        {PID, in_role_process} ->
            PID ! {message, Unique, Module, Method, R2C};
        PID ->
            PID ! {message, Unique, Module, Method, R2C}
    end;
unicast2_direct(PID, Unique, Module, Method, R2C) when is_pid(PID) ->
    PID ! {message, Unique, Module, Method, R2C};
unicast2_direct(_, _Unique, _Module, _Method, _R2C) ->
    ignore.

    

unicast(Line, RoleID, Unique, Module, Method, DataRecord) 
  when is_integer(RoleID) ->
    case erlang:get({roleid_to_pid, RoleID}) of
        undefined ->
            Name = lists:concat(["unicast_server_", Line]),
            catch global:send(Name, {message, RoleID, Unique, Module, Method, DataRecord});
		mirror ->
			ignore;
		{PID, in_role_process} ->
			PID ! {message, Unique, Module, Method, DataRecord};
        PID ->
            Binary = mgeeg_packet:packet_encode(Unique, Module, Method, DataRecord),
            mgeem_map:update_role_msg_queue(PID, Binary)
    end,
    ok;
unicast(_, _, _, _, _, _) ->
    ok.

unicast({role, RoleID}, Unique, Module, Method, DataRecord) when is_integer(RoleID) ->
    case erlang:get({roleid_to_pid, RoleID}) of
        undefined ->
            case common_misc:get_role_line_by_id(RoleID) of
                false ->
                    broadcast([RoleID], Unique, Module, Method, DataRecord),
                    ignore;
                Line  ->
                    Name = lists:concat(["unicast_server_", Line]),
                    catch global:send(Name, {message, RoleID, Unique, Module, Method, DataRecord})
            end;
		mirror ->
			ignore;
		{PID, in_role_process} ->
			PID ! {message, Unique, Module, Method, DataRecord};
        PID ->
            Binary = mgeeg_packet:packet_encode(Unique, Module, Method, DataRecord),
            mgeem_map:update_role_msg_queue(PID, Binary)
    end.

%% Todo 需要兼容world/login
unicast(RoleID, Binary) when erlang:is_integer(RoleID) andalso erlang:is_binary(Binary) ->
    case erlang:get({roleid_to_pid, RoleID}) of
        undefined ->
            ?ERROR_MSG("~ts:~p", ["地图中没有找到对应的玩家", RoleID]),
            ok;
		mirror ->
			ignore;
		{PID, in_role_process} ->
			PID ! {binary, Binary};
        PID ->
            mgeem_map:update_role_msg_queue(PID, Binary)
    end;
unicast(PID, Binary) when erlang:is_pid(PID) andalso erlang:is_binary(Binary) ->
    mgeem_map:update_role_msg_queue(PID, Binary);
unicast(Line, UnicastList) when is_list(UnicastList) andalso erlang:length(UnicastList) > 0 ->
    case erlang:get(is_map_process) of
        undefined ->
            Name = lists:concat(["unicast_server_", Line]),
            case global:whereis_name(Name) of
                undefined ->
                    ignore;
                PID ->
                    PID ! {send_multi, UnicastList}
            end;
        _ ->
            [begin                 
                 case erlang:get({roleid_to_pid, RoleID}) of
                     undefined ->
                         unicast({role, RoleID}, Unique, Module, Method, DataRecord);
					 mirror ->
						 ignore;
					 {PID, in_role_process} ->
						 PID ! {message, Unique, Module, Method, DataRecord};
                     PID ->
                         Binary = mgeeg_packet:packet_encode(Unique, Module, Method, DataRecord),
                         mgeem_map:update_role_msg_queue(PID, Binary)
                 end
             end || #r_unicast{roleid = RoleID, module = Module, unique = Unique, method = Method, record = DataRecord} <- UnicastList],
            ok
    end;
unicast(_, _) ->
    ignore.


broadcast_to_line(RoleIDlist, Module, Method, DataRecord)
  when is_list(RoleIDlist) andalso is_integer(Module) andalso is_integer(Method) ->
    case erlang:length(RoleIDlist) > 0 of 
        true ->
            Lines = common_role_line_map:get_lines(),
            %%?ERROR_MSG("~w", [Lines]),
            lists:foreach(
              fun(Line) ->
                      Name=lists:concat(["unicast_server_", Line]),
                      case global:whereis_name(Name) of
                          undefined ->
                              ?ERROR_MSG("~ts ~w", ["分线的unicast进程down了", Line]),
                              ignore;
                          PID ->
                              PID ! {send, RoleIDlist, ?DEFAULT_UNIQUE, Module, Method, DataRecord}
                      end
              end, Lines
             );
        false ->
            ignore
    end.

%%向各个分线广播，带有优先级的
broadcast(RoleIDListPrior, RoleIDList2, _Unique, _Module, _Method, _DataRecord)
  when erlang:length(RoleIDListPrior) =:= 0 andalso erlang:length(RoleIDList2) =:= 0 ->
    ignore;
broadcast(RoleIDListPrior, RoleIDList2, Unique, Module, Method, DataRecord)
  when is_list(RoleIDListPrior) andalso is_integer(Module) andalso is_integer(Method) ->
    Lines = common_role_line_map:get_lines(),
    lists:foreach(
      fun(Line) ->
              Name = lists:concat(["unicast_server_", Line]),
              case global:whereis_name(Name) of
                  undefined ->
                      ?ERROR_MSG("unicast server on line ~p is down", [Line]),
                      ignore;
                  PID ->
                      PID ! {send, RoleIDListPrior, RoleIDList2, Unique, Module, Method, DataRecord}
              end
      end, Lines).


broadcast(RoleIDList, _Unique, _Module, _Method, _DataRecord)
  when erlang:length(RoleIDList) =:= 0 ->
    ignore;
broadcast(RoleIDList, Unique, Module, Method, DataRecord)
  when is_list(RoleIDList) andalso is_integer(Module) andalso is_integer(Method) ->
    Lines = common_role_line_map:get_lines(),
    lists:foreach(
      fun(Line) ->
              Name = lists:concat(["unicast_server_", Line]),
              case global:whereis_name(Name) of
                  undefined ->
                      ?ERROR_MSG("unicast server on line ~p is down", [Line]),
                      ignore;
                  PID ->
                      PID ! {send, RoleIDList, Unique, Module, Method, DataRecord}
              end
      end, Lines).


%%通过地图服务器广播信息
broadcast(RoleID, Module, Method, DataRecord) 
  when is_integer(RoleID) andalso is_integer(Module) andalso is_integer(Method)  ->
    ?DEBUG("broadcast to round roles,Module = ~p,Method = ~p , Data = ~p",
           [Module, Method, DataRecord]),
    case get_role_map_process_name(RoleID) of
        {ok, MapName} ->
            case global:whereis_name(MapName) of
                undefined ->
                    ?ERROR_MSG("map ~p not started !!!", [MapName]),
                    ignore;
                PID ->
                    PID ! {broadcast_in_sence, [RoleID], Module, Method, DataRecord}
            end,
            ok;
        {error, Reason} ->
            ?ERROR_MSG("broadcast error :~p role:[~p] module:~p method:~p", 
                       [Reason, RoleID, Module, Method]),
            ignore
    end.


broadcast_include_self(RoleID, Module, Method, DataRecord) 
  when is_integer(RoleID) andalso is_integer(Module) andalso is_integer(Method) ->
    ?DEBUG("broadcast to round roles,Module = ~p,Method = ~p , Data = ~p",
           [Module, Method, DataRecord]),
    case get_role_map_process_name(RoleID) of
        {ok, MapName} ->
            case global:whereis_name(MapName) of
                undefined ->
                    ?ERROR_MSG("map ~p not started !!!", [MapName]),
                    ignore;
                PID ->
                    PID ! {broadcast_in_sence_include, [RoleID], Module, Method, DataRecord}
            end,
            ok;
        {error, Reason} ->
            ?ERROR_MSG("broadcast error :~p role:[~p] module:~p method:~p", 
                       [Reason, RoleID, Module, Method]),
            ignore
    end.


get_map_name(MAPID) ->
    lists:concat([mgee_map_, MAPID]).

diff_time(0) ->
    0;
diff_time(Time) when is_integer(Time) ->
    common_tool:now() - Time;
diff_time(Time) ->
    diff_time(erlang:now(), Time).

diff_time(Time1, Time2) ->
    diff_time(Time1, Time2, 1000000).

diff_time(Time1, Time2, TimeChange) ->
    TimeDiff = timer:now_diff(Time1, Time2),
    erlang:round(TimeDiff/TimeChange).

diff_g_seconds(Seconds) ->
    LocalTime = calendar:local_time(),
    GSeconds = calendar:datetime_to_gregorian_seconds(LocalTime),
    GSeconds - Seconds.


get_role_map_process_name(RoleID) ->
    case db:dirty_read(?DB_ROLE_POS, RoleID) of
        [] ->
            {error, role_map_process_name_not_found};
        [#p_role_pos{map_process_name=MapProcessName}] ->
            {ok, MapProcessName}
    end.

%% 有时一些消息 是在玩家下线后收到的 依然要被处理 那么使用该方法 会始终发送数据到地图
send_to_rolemap(strict, RoleID, Msg) ->
    case get_role_map_process_name(RoleID) of
        {ok, MapName} ->
            case global:whereis_name(MapName) of
                undefined ->
                    ?ERROR_MSG("~ts:~w !!!", ["地图进程没有找到", MapName]),
                    ignore;
                PID ->
                    PID ! Msg
            end,
            ok;
        {error, role_map_process_name_not_found} ->
            ?DEBUG("~ts:~w", ["玩家地图信息不存在，将直接发送到mgeem_router", RoleID]),
            global:send(mgeem_router, {role_offline_msg, RoleID, Msg});
        {error, _Reason} ->
            ignore
    end.

%% 发送消息到用户的地图进程
send_to_rolemap(RoleID, Msg) when is_integer(RoleID) ->
    case get({roleid_to_pid, RoleID}) of
        RolePid when is_pid(RolePid) ->
           self() ! Msg;
        _ ->
            send_to_rolemap2(RoleID, Msg)
    end.

send_to_rolemap2(RoleID, Msg) when is_integer(RoleID) ->
    RegName = common_misc:get_role_line_process_name(RoleID),
    case global:whereis_name(RegName) of
        undefined ->
            %%?ERROR_MSG("~ts:~p ~w", ["玩家网关进程不存在", AccountName, Msg]),
			common_misc:print_pay_error_msg("玩家网关进程不存在",Msg),
            ignore;
        PID ->
            PID ! {router_to_map, Msg}
    end.

%%@doc 将消息发给玩家所在地图进程，并有指定的模块去处理
send_to_rolemap_mod(RoleID,Mod,Msg) when is_integer(RoleID) ->
    send_to_rolemap(RoleID, {mod,Mod,Msg}).

send_to_map_mod(MapID,Mod,Msg) ->
    send_to_map(MapID, {mod,Mod,Msg}).

send_to_map(MapID, Info) ->
    MapName = get_map_name(MapID),
    case global:whereis_name(MapName) of
        undefined ->
            ?ERROR_MSG("~ts:~w !!!", ["地图进程没有找到", MapName]),
            {false, map_process_not_found};
        PID ->
            PID ! Info,
            ok
    end.

get_dirty_rolename(RoleID)->
    case get_dirty_role_base(RoleID) of
        {ok, #p_role_base{role_name=RoleName}} -> 
            RoleName;
        _ -> 
            ""
    end.

get_dirty_role_attr(RoleID) ->
    Flag = case mod_role_tab:is_exist(RoleID) of
        true ->
            case mod_role_tab:get({?role_attr, RoleID}) of
                #p_role_attr{} = RoleAttr ->
                    {ok, RoleAttr};
                _ ->
                    undefined
            end;
        false ->
            undefined
    end, 
    case Flag of
        {ok, _} = R ->
            R;
        undefined ->
            case catch db:dirty_read(?DB_ROLE_ATTR, RoleID) of
                {'EXIT', Reason} ->
                    ?ERROR_MSG("mnesia dirty read exit:~p", [Reason]),
                    {error, system_error};
                [] ->
                    ?INFO_MSG("role attr not found ~p", [RoleID]),
                    {error, not_found};
                [RoleAttr1] ->
                    {ok, RoleAttr1}
            end
    end.

%%获取地图进程字典中的RoleBase
get_dict_role_base(RoleID) when is_integer(RoleID)->
    case mod_role_tab:get({?role_base, RoleID}) of
        undefined ->
            {error, role_not_found};
        Value ->
            {ok, Value}
    end.

get_dirty_role_base(RoleID) ->
    Flag = case mod_role_tab:is_exist(RoleID) of
        true ->
            case mod_role_tab:get({?role_base, RoleID}) of
                #p_role_base{} = RoleBase ->
                    {ok, RoleBase};
                _ ->
                    undefined
            end;
        false ->
            undefined
    end, 
    case Flag of
        {ok, _} = R ->
            R;
        undefined ->
            case catch db:dirty_read(?DB_ROLE_BASE, RoleID) of
                {'EXIT', Reason} ->
                    ?ERROR_MSG("mnesia dirty read exit:~p", [Reason]),
                    {error, system_error};
                [] ->
                    ?INFO_MSG("role base not found ~p", [RoleID]),
                    {error, not_found};
                [RoleBase1] ->
                    {ok, RoleBase1}
            end
    end.

%% 脏读获取玩家当前位置信息
get_dirty_role_pos(RoleID) ->
    case catch db:dirty_read(?DB_ROLE_POS, RoleID) of
        {'EXIT', Reason} ->
            ?ERROR_MSG("mnesia dirty read exit:~p", [Reason]),
            {error, system_error};
        [] ->
            ?INFO_MSG("role attr pos not found ~p", [RoleID]),
            {error, not_found};
        [RolePos] ->
            {ok, RolePos}
    end.
%% 脏读获取玩家当前战斗信息
get_dirty_role_fight(RoleID) ->
    case catch db:dirty_read(?DB_ROLE_FIGHT, RoleID) of
        {'EXIT', Reason} ->
            ?ERROR_MSG("mnesia dirty read exit:~p", [Reason]),
            {error, system_error};
        [] ->
            ?INFO_MSG("role attr fight not found ~p", [RoleID]),
            {error, not_found};
        [RoleFight] ->
            {ok, RoleFight}
    end.
%% 脏读获取玩家当前额外属性
get_dirty_role_ext(RoleID) ->
    case catch db:dirty_read(?DB_ROLE_EXT, RoleID) of
        {'EXIT', Reason} ->
            ?ERROR_MSG("mnesia dirty read exit:~p", [Reason]),
            {error, system_error};
        [] ->
            ?INFO_MSG("role attr ext not found ~p", [RoleID]),
            {error, not_found};
        [RoleExt] ->
            {ok, RoleExt}
    end.
%%脏读获取玩家当前的地图信息
get_dirty_mapid_by_roleid(RoleID) ->
    case catch db:dirty_read(?DB_ROLE_POS, RoleID) of
        {'EXIT', Reason} ->
            ?ERROR_MSG("mnesia dirty read exit:~p", [Reason]),
            {error, system_error};
        [] ->
            ?INFO_MSG("role pos not found ~p", [RoleID]),
            {error, not_found};
        [RolePos] ->
            {ok, RolePos#p_role_pos.map_id}
    end.

%%获取最大的玩家id
get_max_role_id() ->
   case  db:transaction( 
           fun() ->
                    db:read(?DB_ROLEID_COUNTER, 1)
           end)
   of
       {aborted, Reason} -> 
           ?ERROR_MSG("~ts:~p",["Mnesia 读取失败", Reason]),
           {error, system_error};
       {atomic, []} ->
           ?ERROR_MSG("~ts",["没有找到最大玩家id"]),
           {error, not_found};
       {atomic, [#r_roleid_counter{last_role_id=N}]} ->
           {ok, N}
   end.

check_distance(TX, TY, TTX, TTY, MaxX, MaxY) ->
    {PX, PY} = common_misc:get_iso_index_mid_vertex(TX, 0, TY),
    {TPX, TPY} = common_misc:get_iso_index_mid_vertex(TTX, 0, TTY),
    erlang:abs(PX - TPX) < MaxX andalso erlang:abs(PY - TPY) < MaxY.
    

-spec(index2flat(X :: integer(), Y :: integer(), Z :: integer()) -> tuple()).
index2flat(X, Y, Z) ->
    X2 = X - Z,
    Y2 = Y * ?CORRECT_VALUE + (X + Z) * 0.5,
    {X2 * ?TILE_SIZE, Y2 * ?TILE_SIZE}.

-spec(get_iso_index_mid_vertex(X :: integer(), Y :: integer(), Z :: integer()) -> tuple()).
get_iso_index_mid_vertex(X, Y, Z) ->
    {X2, Y2} = index2flat(X, Y, Z),
    Y3 = round(Y2 + ?TILE_SIZE / 2),
    {X2, Y3}.

get_dir(#p_pos{tx=X1, ty=Y1}, #p_pos{tx=X2, ty=Y2}) ->
	get_dir({X1, Y1}, {X2, Y2});
	
get_dir({X1, Y1}, {X2, Y2}) ->
	X = X2 - X1,
	Y = Y2 - Y1,
	Xabs = abs(X),
	Yabs = abs(Y),
	if
		Xabs > 2*Yabs, X > 0 ->
			3;
		Xabs > 2*Yabs, X < 0 ->
			7;
		Yabs > 2*Xabs, Y > 0 ->
			5;
		Yabs > 2*Xabs, Y < 0 ->
			1;
		X >= 0, Y >= 0 ->
			4;
		X >= 0, Y < 0 ->
			2;
		X < 0+1, Y >= 0 ->
			6;
		X < 0, Y < 0 ->
			0
	end.


%%判断角色是否在线
is_role_online(RoleID) ->
    case db:dirty_read(?DB_USER_ONLINE, RoleID) of
        [] ->
            false;
        _ ->
            true
    end.

%%@doc 玩家是否在本地图上
is_role_on_map(RoleID)->
	case mod_map_actor:get_actor_mapinfo(RoleID,role) of
		#p_map_role{} ->
			true;
		_ ->
			false
	end.

%%@doc 玩家是否在指定的网关进程上
is_role_on_gateway(RoleID,GatewayPID)->
	RegName = get_role_line_process_name(RoleID),
    case global:whereis_name(RegName) of
		GatewayPID->
			true;
		_ ->
			false
	end.
is_role_on_gateway(RoleID)->
	RegName = get_role_line_process_name(RoleID),
    case global:whereis_name(RegName) of
		undefined ->
            false;
        _PID ->
			true
	end.
is_role_online2(RoleID)->
	is_role_on_gateway(RoleID).

%%获取在线玩家的登录IP
%%@return tuple() eg: {127.0.0.1}
get_online_role_ip(RoleID) when is_integer(RoleID)->
    case db:dirty_read(?DB_USER_ONLINE, RoleID) of
        [Record] ->
            Record#r_role_online.login_ip;
        _->
            undefined
    end.

get_all_online_roleid() ->
    case catch db:dirty_match_object(?DB_USER_ONLINE, #r_role_online{_='_'}) of
        [_|_] = L ->
            [R#r_role_online.role_id || R <- L];
        _ ->
            []
    end.

is_role_data_loaded(RoleID) ->
    case db:dirty_read(?DB_USER_DATA_LOAD_MAP_P, RoleID) of
        [] ->
            false;
        _ ->
            true
    end.


%%是否玩家处于战斗状态
is_role_fighting(RoleID) ->
    case catch db:dirty_read(?DB_ROLE_STATE, RoleID) of
        {'EXIT', Detail} ->
            ?ERROR_MSG("~ts:~p -> ~w", ["脏读玩家状态信息出错", RoleID, Detail]),
            false;
        [#r_role_state{fight=Fight}] ->
            Fight =:= true;
        [] ->
            false
    end.

%%是否玩家处于托管摆摊中
is_role_auto_stalling(RoleID) ->
    case catch db:dirty_read(?DB_ROLE_STATE, RoleID) of
        {'EXIT', Detail} ->
            ?ERROR_MSG("~ts:~p -> ~w", ["脏读玩家状态信息出错", RoleID, Detail]),
            false;
        [#r_role_state{stall_auto=StallAuto}] ->
            StallAuto =:= true;
        [] ->
            false
    end.

%%是否玩家正处于交易状态
is_role_exchanging(RoleID) ->
    case catch db:dirty_read(?DB_ROLE_STATE, RoleID) of
        {'EXIT', Detail} ->
            ?ERROR_MSG("~ts:~p -> ~w", ["脏读玩家状态信息出错", RoleID, Detail]),
            false;
        [#r_role_state{exchange=Exchange}] ->
            Exchange =:= true;
        [] ->
            false
    end.

is_abort(Fun) when is_function(Fun) ->
    case Fun() of
    {aborted, _} ->
        true;
    _ ->
        false
    end;
is_abort(Tuple) when is_tuple(Tuple) ->
    case Tuple of
    {aborted, _} ->
        true;
    _ ->
        false
    end.

-spec(get_roleid(string()|binary())-> integer()).
get_roleid(Name) when is_list(Name) ->
    BinName = list_to_binary(Name),
    get_roleid(BinName);
get_roleid(Name) when is_binary(Name) ->
    case db:dirty_read(?DB_ROLE_NAME, Name) of
        [#r_role_name{role_id=RoleID}] ->
            RoleID;
        _ ->
            0
    end.

-spec(get_roleid_by_accountname(string()|binary())-> integer()).
get_roleid_by_accountname(Name) when is_list(Name) ->
    BinName = list_to_binary(Name),
    get_roleid_by_accountname(BinName);
get_roleid_by_accountname(Name) when is_binary(Name) ->
    Pattern = #p_role_base{account_name= Name,_ = '_'},
    
    case catch (db:dirty_match_object(?DB_ROLE_BASE,Pattern)) of
    [R] -> R#p_role_base.role_id;
    RoleList when is_list(RoleList) andalso length(RoleList)>1 ->
        [ RoleID||#p_role_base{role_id=RoleID}<- RoleList];
    Other -> ?DEBUG("~nOther:~p~n",[Other]),0
    end.    

get_role_pid(RoleID) ->
    case erlang:get({roleid_to_pid, RoleID}) of 
        {PID, in_role_process} -> PID;
        PID -> PID
    end.

%% 队伍经验接口
%% MonsterExpList 结构为 [r_monster_exp,r_monster_exp,]
%% id,唯一标记，killer_id 杀死怪物的RoleId, map_id 地图id monster_id  怪物id, ,monster_type 怪物类型 
%% monster_tx,monster_ty 怪物死亡坐标，role_exp_list 获取得经验的玩家记录类型r_monster_role_exp
%% team_exp_list  队伍经验记录r_monster_team_exp
%% -record(r_monster_exp,{id,killer_id,map_id,monster_id,monster_type,monster_tx,monster_ty,role_exp_list,team_exp_list}).
%% 怪物经验玩家经验记录
%% -record(r_monster_role_exp,{role_id,exp}).
%% 队伍经验记录,team_sub_list 队伍成员经验记录列表r_monster_team_sub_exp
%% -record(r_monster_team_exp,{team_id,team_sub_list}).
%% role_id 角色id,exp 角色所得经验
%% -record(r_monster_team_sub_exp,{role_id, exp, team_id, team_exp, level,kill_flag,status}).
team_add_role_exp(MonsterExpList) ->
    catch global:send("mod_team_exp_server",{add_role_exp, MonsterExpList}).
%% 此接口只能在地图进程使用
%% 获取当前什么玩家可以拾取怪物掉落的物品
%% 返回的结果为一个玩家ID列表 [RoleId,RoleId2,RoleId3,...]
team_get_can_pick_goods_role(RoleId) ->
    case mod_map_role:get_role_base(RoleId) of
        {ok,RoleBase} ->
            case RoleBase#p_role_base.team_id =/= 0 of
                true ->
                    team_get_can_pick_goods_role2(RoleId);
                _ ->
                    [RoleId]
            end;
        _ ->
            [RoleId]
    end. 
team_get_can_pick_goods_role2(RoleId) ->
    case mod_map_team:get_role_team_info(RoleId) of
        {ok,MapTeamInfo} ->
            case MapTeamInfo#r_role_team.team_id =/= 0
                                             andalso erlang:length(MapTeamInfo#r_role_team.role_list) > 0
                                             andalso MapTeamInfo#r_role_team.pick_type =:= 1 of
                true ->
                    [TeamRoleInfo#p_team_role.role_id || TeamRoleInfo <- MapTeamInfo#r_role_team.role_list];
                _ ->
                    [RoleId]
            end;
        _ ->
            [RoleId]
    end.

%% @doc 根据角色id获取当前角色的队伍的队伍成员（包括自己），只能在map中使用
%% @result [RoleId, RoleId2, ...] | []
team_get_team_member(RoleId) ->
    case mod_map_role:get_role_base(RoleId) of
        {ok,RoleBase} ->
            case RoleBase#p_role_base.team_id =/= 0 of
                true ->
                    team_get_team_member2(RoleId);
                _ ->
                    []
            end;
        _ ->
            []
    end. 
team_get_team_member2(RoleId) ->
    case mod_map_team:get_role_team_info(RoleId) of
        {ok,MapTeamInfo} ->
            case MapTeamInfo#r_role_team.team_id =/= 0
                                             andalso erlang:length(MapTeamInfo#r_role_team.role_list) > 0 of
                true ->
                    [TeamRoleInfo#p_team_role.role_id || TeamRoleInfo <- MapTeamInfo#r_role_team.role_list];
                _ ->
                    []
            end;
        _ ->
            []
    end.
%% UnicastArg 可以是下面几种情况
%% {role, RoleId}
%% {line, Line, RoleId}
%% {socket, Line, Socket}
del_goods_notify(UnicastArg, GoodsData) ->
     GoodsList = 
        case GoodsData of
            GoodsData when is_record(GoodsData, p_goods) ->
                [GoodsData];
            GoodsData when is_list(GoodsData) ->
                GoodsData;
            _Other ->
                []
        end,
	 NewGoodsList = [R#p_goods{current_num = 0} || R<-GoodsList],
	 if NewGoodsList =/=  [] ->
			do_goods_notify(UnicastArg, NewGoodsList);
		true ->
			ignore
	 end,
	 ok.

%% UnicastArg 可以是下面几种情况
%% {role, RoleId}
%% {line, Line, RoleId}
%% {socket, Line, Socket}
new_goods_notify(UnicastArg, GoodsData) ->
    update_goods_notify(UnicastArg, GoodsData).


%% UnicastArg 可以是下面几种情况
%% {role, RoleId}
%% {line, Line, RoleId}
%% {socket, Line, Socket}
update_goods_notify(UnicastArg, GoodsData) ->
    GoodsList = 
        case GoodsData of
            GoodsData when is_record(GoodsData, p_goods) ->
                [GoodsData];
            GoodsData when is_list(GoodsData) ->
                GoodsData;
            _Other ->
                []
        end,
	if GoodsList =/= [] ->
		   do_goods_notify(UnicastArg, GoodsList);
	   true ->
		   ignore
	end,
	ok.


%% UnicastArg 可以是下面几种情况
%% {role, RoleId}
%% {line, Line, RoleId}
%% {socket, Line, Socket}
do_goods_notify(UnicastArg, GoodsList) ->
    DataRecord = #m_goods_update_toc{goods = GoodsList},
    case UnicastArg of
        PID when erlang:is_pid(PID) ->
            unicast2(PID, ?DEFAULT_UNIQUE, ?GOODS, ?GOODS_UPDATE, DataRecord);
        {role, RoleId} ->
            unicast({role, RoleId}, ?DEFAULT_UNIQUE, ?GOODS, ?GOODS_UPDATE, DataRecord);
        {line, Line, RoleId} ->
            unicast(Line, RoleId, ?DEFAULT_UNIQUE, ?GOODS, ?GOODS_UPDATE, DataRecord);
        {socket, Line, Socket} ->
            unicast(Line, Socket, ?DEFAULT_UNIQUE, ?GOODS, ?GOODS_UPDATE, DataRecord)
    end.


%% 角色属性变化通知接口
%% UnicastArg 可以是下面几种情况
%% {role, RoleId}
%% {line, Line, RoleId}
%% {socket, Line, Socket}
%% {pid, PID}
role_attr_change_notify(UnicastArg, RoleId, ChangeAttList) ->
    DataRecord = #m_role2_attr_change_toc{roleid = RoleId, changes = ChangeAttList},
    case UnicastArg of
        {role, RoleId} ->
            unicast({role, RoleId}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, DataRecord);
        {line, Line, RoleId} ->
            unicast(Line, RoleId, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, DataRecord);
        {socket, Line, Socket} ->
            unicast(Line, Socket, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, DataRecord);
        {pid, PID} ->
            unicast2(PID, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, DataRecord)
    end.

%%@doc 获取指定玩家的摆摊物品
get_dirty_stall_goods(RoleID) ->
    Pattern = #r_stall_goods{role_id = RoleID, _ = '_'},
    case catch db:dirty_match_object(?DB_STALL_GOODS, Pattern) of
        StallRecList when is_list(StallRecList) ->
            GoodsList = [ Goods ||#r_stall_goods{goods_detail=Goods}<-StallRecList],
            {ok, GoodsList};
        _ ->
            {error, ?_LANG_SYSTEM_ERROR}
    end.

%% 计算装备的精炼系数
%% 旧的 精炼系数 公式 =（颜色值 - 1） + （品质值 -1） + 强化等级 + 绑定等级（最高级） + 打孔数 + 五行等级
%% 新的 精炼系数 公式 = （颜色值 - 1） + （品质值 -1） + 强化等级 + 绑定等级（最高级） +　镶嵌石头个数 +　镶嵌石头（最高级）　＋五行等级
%% 装备的五行等级暂时没有不用处理
%% 输入参数 p_goods
%% 返回结果 {ok,NewEquipGoods}
%%         {error,ErrorCode}
%% ErrorCode = {1,不是装备}
do_calculate_equip_refining_index(EquipGoods) ->
    case catch do_calculate_equip_refining_index2(EquipGoods) of
        {error,ErrorCode} ->
            {error,ErrorCode};
        {ok} ->
            do_calculate_equip_refining_index3(EquipGoods)
    end.
do_calculate_equip_refining_index2(EquipGoods) ->
    EquipType = EquipGoods#p_goods.type,
    if EquipType =/= 3 ->
            erlang:throw({error,1});%% 此物品类型不是装备
       true ->
            next
    end,
    {ok}.
do_calculate_equip_refining_index3(EquipGoods) ->
    Colour = do_calculate_eri_filter_number(EquipGoods#p_goods.current_colour),%% 当前颜色
    Quality = do_calculate_eri_filter_number(EquipGoods#p_goods.quality),%% 品质
    ReinforceResult = do_calculate_eri_filter_number(EquipGoods#p_goods.reinforce_result),%% 强化等级
    ReinforceLevel = if ReinforceResult > 0 ->
                            erlang:trunc(ReinforceResult / 10);
                        true ->
                             0
                     end,
    %%PunchNum = do_calculate_eri_filter_number(EquipGoods#p_goods.punch_num), %% 打孔数
    BindAttrList = EquipGoods#p_goods.equip_bind_attr,%% 绑定等级（最高级）
    MaxBindLevel = case BindAttrList of
                       undefined -> 0;
                       [] -> 0;
                       _ ->
                           lists:foldl(fun(R,BindLevel) ->
                                               if R#p_equip_bind_attr.attr_level > BindLevel ->
                                                       R#p_equip_bind_attr.attr_level;
                                                  true ->
                                                       BindLevel
                                               end
                                       end,0,BindAttrList)
                   end,
    StoneNum = do_calculate_eri_filter_number(EquipGoods#p_goods.stone_num),%% 镶嵌石头个数
    Stones = if erlang:is_list(EquipGoods#p_goods.stones) ->
                     EquipGoods#p_goods.stones;
                true ->
                     []
             end,
    %% 镶嵌石头（最高级
    MaxStoneLevel = 
        lists:foldl(fun(Stone,StoneLevel) ->
                            if Stone#p_goods.level > StoneLevel ->
                                    Stone#p_goods.level;
                               true ->
                                    StoneLevel
                            end
                    end, 0, Stones),
    RefiningIndex = (Colour - 1) +  (Quality - 1) + ReinforceLevel + MaxBindLevel + StoneNum + MaxStoneLevel,
    ?DEBUG("~ts,EquipGoods=~w,RefiningIndex=~w",["计算装备的精炼系数结果为：",EquipGoods,RefiningIndex]),
    {ok,EquipGoods#p_goods{refining_index = RefiningIndex}}.

do_calculate_eri_filter_number(Number) ->
    if erlang:is_integer(Number) ->
            Number;
       true ->
            0
    end.
            
get_dirty_role_state(RoleID) ->
    case catch db:dirty_read(?DB_ROLE_STATE, RoleID) of
        {'EXIT', R} ->
            ?DEBUG("get_dirty_role_state, r: ~w", [R]),
            {error, ?_LANG_SYSTEM_ERROR};
        [] ->
            {error, ?_LANG_SYSTEM_ERROR};
        [RoleState] ->
            {ok, RoleState}
    end.                           

get_newcomer_mapid(_) ->
	10250.

get_home_map_id(_FactionID) ->
	10260.

if_friend(RoleID, FriendID) ->
    Pattern = #r_friend{roleid=RoleID, friendid=FriendID, type=1, _='_'},
    case catch db:dirty_match_object(?DB_FRIEND, Pattern) of
        [_F] ->
            true;
        R ->
            ?DEBUG("if_friend, r: ~w", [R]),
            false
    end.

%%type, 方式：1、组队，2、聊天
if_reach_day_friendly_limited(RoleID, FriendID, Type) ->
    Pattern = #r_friend{roleid=RoleID, friendid=FriendID, _='_'},
    case catch db:dirty_match_object(?DB_FRIEND, Pattern) of
        [FriendInfo] ->
            case Type of
                1 ->
                    if_reach_day_friendly_limited2_1(FriendInfo);
                2 ->
                    if_reach_day_friendly_limited2_2(FriendInfo)
            end;
        R ->
            ?DEBUG("if_reach_day_friendly_limited, r: ~w", [R]),
            true
    end.
if_reach_day_friendly_limited2_1(FriendInfo) ->
    TeamTime = FriendInfo#r_friend.team_time,
    case TeamTime =:= undefined of
        true ->
            false;
        false ->
            {Date, Times} = TeamTime,
            {Date2, _} = calendar:now_to_local_time(now()),
            not(Date =/= Date2 orelse Times < 20)
    end.
if_reach_day_friendly_limited2_2(FriendInfo) ->
    ChatTime = FriendInfo#r_friend.chat_time,
    case ChatTime =:= undefined of
        true ->
            false;
        false ->
            {Date, Times} = ChatTime,
            {Date2, _} = calendar:now_to_local_time(now()),
            not(Date =/= Date2 orelse Times < 10)
    end.

make_family_map_name(FamilyID) ->
    lists:concat(["map_family_", FamilyID]).


%%构造一个唯一的普通怪物进程名称 
make_common_monster_process_name(MonsterType, MapProcessName, Tx, Ty) ->
    lists:concat([monster_, MonsterType, MapProcessName, Tx,Ty]).

%%构造一个唯一的召唤怪物进程名称 
make_summon_monster_process_name(Tick) ->
    lists:concat([monster_, Tick]).


%%构造一个唯一的家族boss进程名称
make_family_boss_process_name(FamilyID, MonsterType) ->
    MapName = make_family_map_name(FamilyID),
    lists:concat([monster_, MapName, MonsterType]).

%%获取家族进程名称
make_family_process_name(FamilyID) ->
    lists:concat(["family_", FamilyID]).

%%获取玩家防沉迷系数
get_role_fcm_cofficient(RoleID) ->
    %%如果防沉迷没有打开，就不用惩罚了
	case common_config:is_fcm_open() of
        true ->
            case catch mod_map_role:get_role_base(RoleID) of
                {ok,RoleBase} ->
                    get_role_fcm_cofficient2(RoleBase);
                _ ->
                    case db:dirty_read(?DB_ROLE_BASE, RoleID) of
                        [RoleBase] ->
                            get_role_fcm_cofficient2(RoleBase);
                        _ ->
                            1
                    end
            end;        
        false ->
            1
    end.
get_role_fcm_cofficient2(RoleBase) ->
    AccountName = RoleBase#p_role_base.account_name,
    case db:dirty_read(?DB_FCM_DATA, AccountName) of
        [FCMData] ->
            get_role_fcm_cofficient3(FCMData);
        _ ->
            1
    end.
get_role_fcm_cofficient3(FCMData) ->
    #r_fcm_data{total_online_time=TotalOnlineTime, passed=Passed} = FCMData,

    %%如果通过防沉迷验证的话，没有防沉迷惩罚
    case Passed =:= true of
        true ->
            1;
        _ ->
            if
                %%大于5小时，获得经验为0，装备掉落概率为0
                TotalOnlineTime >= 5 * 3600 ->
                    0.00001;

                %%大于3小时小于5小时，经验、装备掉落率减半
                TotalOnlineTime >= 3 * 3600 ->
                    0.5;

                %%无惩罚
                true ->
                    1
            end
    end.


%%获取角色详细信息
get_role_detail(RoleID) ->
    {ok, RoleBase} = common_misc:get_dirty_role_base(RoleID),
    {ok, RoleAttr} = common_misc:get_dirty_role_attr(RoleID),
    {ok, RoleExt} = common_misc:get_dirty_role_ext(RoleID),
    
    case common_misc:get_dirty_role_pos(RoleID) of
        {ok, RolePos} ->
            ignore;
        _ ->
            RolePos = undefined
    end,
    case common_misc:get_dirty_role_fight(RoleID) of
        {ok, RoleFight} ->
            next;
        _ ->
            RoleFight = undefined
    end,
    
    #p_role{base=RoleBase, fight=RoleFight, pos=RolePos, attr=RoleAttr, ext=RoleExt}.

%%判断玩家所在地图是否是在自己国家
if_in_self_country(FactionID, MapID) ->
    case MapID rem 10000 div 1000 of
        FactionID ->
            true;
        _ ->
            false
    end.

%%判断玩家所在地图是否是在敌国
if_in_enemy_country(RoleFaction, MapID) when is_integer(RoleFaction) ->
    FactionTag = (MapID rem 10000 div 1000),
    (FactionTag>=1) andalso (FactionTag=<3) andalso (FactionTag=/=RoleFaction).


get_common_map_name(MAPID) when is_integer(MAPID) ->
    lists:concat([mgee_map_, MAPID]).

get_map_faction_id(MapID) ->
    MapID div 1000 rem 10.

format_silver(_Name, 0) ->
    "";
format_silver(Name, Num) ->
	lists:concat([Name,Num,"铜"]).

format_silver(Num) ->
	lists:concat([Num,"铜"]).

%%@doc 格式化多语言支持的消息
%%@spec format_lang(Message::binary(),Argument::list())-> binary()
format_lang(Message,Argument) when is_list(Argument)->
    lists:flatten(io_lib:format(Message,Argument) ).

%%@doc 从数据库获取玩家的背包物品列表（非实时）
%%@spec get_dirty_bag_goods/1 -> {ok,GoodsList}->{error,not_found}
get_dirty_bag_goods(RoleID)->
    case db:dirty_read(?DB_ROLE_BAG_BASIC_P,RoleID) of
        [] -> 
            {error,not_found};
        [ #r_role_bag_basic{bag_basic_list=BagBasicList} ]->
            GoodsList = [ get_dirty_bag_goods_2(RoleID,BagBasic)||BagBasic<-BagBasicList],
            {ok,lists:flatten(GoodsList)}
    end.
get_dirty_bag_goods_2(RoleID,BagBasic)->
        BagID = element(1,BagBasic),
        BagKey = {RoleID,BagID},
        case db:dirty_read(?DB_ROLE_BAG_P,BagKey) of
             [] ->
                  [];
             [BagInfo] ->
                  BagInfo#r_role_bag.bag_goods
        end.
    
get_level_base_hp(Level) ->
    ?BASE_ROLE_MAX_HP + 10 * Level.

get_level_base_mp(Level) ->
    ?BASE_ROLE_MAX_MP + 100 * Level.

%%通用的全局活动状态表-比如国运-国探
get_event_state(Key) ->
    case db:dirty_read(?DB_EVENT_STATE, Key) of
        [] ->
            {false, []};
        [Data] ->
            {ok, Data}
    end.

set_event_state(Key, Data) ->
    NewEventData = #r_event_state{key=Key, data=Data},
    db:dirty_write(?DB_EVENT_STATE, NewEventData).

del_event_state(Key) ->
    db:dirty_delete(?DB_EVENT_STATE, Key).

%%非获得新的ID
dirty_get_new_counter(Key) ->
    case db:dirty_read(?DB_COUNTER, Key) of
        [] ->
            NewCounterNum = 1,
            NewRecord = #r_counter{key=Key, value=NewCounterNum};
        [Counter] ->
            NewCounterNum = Counter#r_counter.value + 1,
            NewRecord = Counter#r_counter{value=NewCounterNum}
    end,
    db:dirty_write(?DB_COUNTER, NewRecord),
    {ok, NewCounterNum}.

%%事务获得新的ID
trans_get_new_counter(Key) ->
    Result = 
    db:transaction(fun() ->
        case db:read(?DB_COUNTER, Key, read) of
            [] ->
                NewCounterNum = 1,
                NewRecord = #r_counter{key=Key, value=NewCounterNum};
            [Counter] ->
                NewCounterNum = Counter#r_counter.value + 1,
                NewRecord = Counter#r_counter{value=NewCounterNum}
        end,
        db:write(?DB_COUNTER, NewRecord, write),
        NewCounterNum
    end),

    case Result of
        {atomic, NewCounterNum} ->
            {ok, NewCounterNum};
        {aborted, Reason} ->
            {false, Reason}
    end.

%%@doc 增加玩家的活跃度
done_task(RoleID,ActivityKey) when is_integer(ActivityKey) ->
    common_misc:send_to_rolemap(RoleID, {mod,hook_activity_task,{done_task,{RoleID,ActivityKey}}}).   

%%@doc 将数据值更新到进程字典的队列
update_dict_queue(TheKey,Val)->
    case get(TheKey) of
        undefined ->
            put(TheKey, [Val]);
        Queues ->
            put( TheKey,[ Val|Queues ] )
    end.

%%@doc 将数据值更新到进程字典的Set中
update_dict_set(TheKey,Val)->
    case get(TheKey) of
        undefined ->
            put(TheKey, [Val]);
        Sets1 ->
            Sets2 = lists:delete(Val, Sets1),
            put( TheKey,[ Val|Sets2 ] )
    end.

%% @doc 获取回城点
get_home_mapid(_, _) ->
	10260.

get_home_born() ->
    [{TX, TY}|_] = mcm:born_tiles(10260),
    {10260, TX, TY}.

get_jingcheng_mapid(_FactionID) ->
	10260.

generate_map_id_by_faction(FactionID, SubMapID) ->
    10000 + FactionID * 1000 + SubMapID.

%%是否在中立区
if_in_neutral_area(10123) ->
    true;
if_in_neutral_area(MapID) ->
    MapID div 100 =:= 102.

%%是否可以使用免战buff的地图ID
is_in_noattack_buff_valid_map(MapID) when is_integer(MapID)->
    %%是否在中立地图
    if_in_neutral_area(MapID).

get_all_map_pid() ->
    F = fun("mgee_map_" ++ _ = Map) ->
                global:whereis_name(Map);
           ("mgee_mission_fb_map_" ++ _ = Map) ->
                global:whereis_name(Map);
           ("map_" ++ _ = Map) ->
                global:whereis_name(Map);
           (_) ->
                undefined
        end,
    [Pid || Map <- global:registered_names(), undefined =/= (Pid = F(Map))].

-define(FACTION_HONGWU, 1).
-define(FACTION_YONGLE, 2).
-define(FACTION_WANLI, 3).

%% @doc 获取角色名字，包含国家颜色
get_role_name_color(RoleName, FactionID) ->
    case FactionID of
        ?FACTION_HONGWU ->
            io_lib:format("<font color=\"#00FF00\">[~s]</font>", [RoleName]);
        ?FACTION_YONGLE ->
            io_lib:format("<font color=\"#F600FF\">[~s]</font>", [RoleName]);
        _ ->
            io_lib:format("<font color=\"#00CCFF\">[~s]</font>", [RoleName])
    end.

%%@doc 获取物品的类型ID
%%     这里对策划的ID配置规则有要求！！
get_prop_type(PropTypeID) when is_integer(PropTypeID)->
    PropTypeID div 10000000.

get_team_proccess_name(TeamId) ->
    lists:concat([team_,TeamId]).

%%格式化物品名字的颜色
format_goods_name_colour(Colour,Name) ->
    if Colour =:= ?COLOUR_WHITE ->
            lists:append(["<font color=\"#FFFFFF\">【",common_tool:to_list(Name),"】</font>"]);
       Colour =:= ?COLOUR_GREEN->
            lists:append(["<font color=\"#12CC95\">【",common_tool:to_list(Name),"】</font>"]);
       Colour =:= ?COLOUR_BLUE->
            lists:append(["<font color=\"#0D79FF\">【",common_tool:to_list(Name),"】</font>"]);
       Colour =:= ?COLOUR_PURPLE->
            lists:append(["<font color=\"#FE00E9\">【",common_tool:to_list(Name),"】</font>"]);
       Colour =:= ?COLOUR_ORANGE->
            lists:append(["<font color=\"#FF7E00\">【",common_tool:to_list(Name),"】</font>"]);
       Colour =:= ?COLOUR_GOLD->
            lists:append(["<font color=\"#FFD700\">【",common_tool:to_list(Name),"】</font>"]);
       true ->
            lists:append(["<font color=\"#FFFFFF\">【",common_tool:to_list(Name),"】</font>"])
    end.

-define(equip_ring_color_gold, 3).
-define(equip_ring_color_oranger, 2).
-define(equip_ring_color_purple, 1).
-define(equip_ring_color_white, 0).

%% @doc 获取装备光环颜色
get_equip_ring_color(EquipsList) ->
    {PurpleNum, OrangerNum, GoldNum} =
        lists:foldl(
          fun(Equip, {PurpleCount, OrangeCounter, GoldCount}) ->
                  #p_goods{loadposition=LoadPosition, current_colour=Colour} = Equip,
                  %% 时装及特殊装备不计入考虑范围
                  case LoadPosition =:= 7 orelse LoadPosition =:= 8 orelse LoadPosition =:= 14 of
                      true ->
                          {PurpleCount, OrangeCounter, GoldCount};
                      _ ->
                          case Colour of
                              ?COLOUR_PURPLE ->
                                  {PurpleCount+1, OrangeCounter, GoldCount};
                              ?COLOUR_ORANGE ->
                                  {PurpleCount, OrangeCounter+1, GoldCount};
                              ?COLOUR_GOLD ->
                                  {PurpleCount, OrangeCounter, GoldCount+1};
                              _ ->
                                  {PurpleCount, OrangeCounter, GoldCount}
                          end
                  end
          end, {0, 0, 0}, EquipsList),
    %% 5件以上紫色，紫光；橙色，橙光；金色，金光
    EquipRingColor =
        if
            GoldNum >= 5 ->
                ?equip_ring_color_gold;
            GoldNum + OrangerNum >= 5 ->
                ?equip_ring_color_oranger;
            GoldNum + OrangerNum + PurpleNum >= 5 ->
                ?equip_ring_color_purple;
            true ->
                ?equip_ring_color_white
        end,
    {ok, EquipRingColor}.


%%@doc 检查是否在当天的规定时间段内
%%@param    参数均为{时,分,秒}
%%@return   bool()
check_in_special_time({SH,SI,SS}, {EH,EI,ES})->
    {H, I, S} = erlang:time(),
    StartSeconds = SH*3600 + SI*60 + SS,
    EndSeconds = EH*3600 + EI*60 + ES,
    NowSeconds = H*3600 + I*60 + S,
    (NowSeconds>=StartSeconds) andalso (EndSeconds>=NowSeconds).

%% @doc 检测时间是否冲突
%%LastTime秒
check_time_conflict(StartHour, StartMin, LastTime, CheckHour, CheckMin) ->
    StartTime = StartHour * 60 + StartMin,
    EndTime = StartTime + LastTime,
    CheckTime = CheckHour * 60 + CheckMin,
    
    case CheckTime >= StartTime andalso CheckTime =< EndTime of
        true ->
            error;
        _ ->
            ok
    end.

%%LastTime秒
get_end_time(StartH, StartM, LastTime) ->
    EndH = StartH+((StartM + LastTime div 60) div 60),
    EndM = (StartM + LastTime div 60) rem 60,
    {EndH, EndM}.

get_stall_map_id(RoleID) ->
    case db:dirty_read(?DB_STALL, RoleID) of
        [] ->
            {error, not_found};
        [#r_stall{mapid=MapID}] ->
            {ok, MapID}
    end.

%% @doc 获取指定角色摆摊所在地图进程
get_stall_map_pid(RoleID) ->
    case db:dirty_read(?DB_STALL, RoleID) of
        [] ->
            {error, not_found};
        [#r_stall{mapid=MapID}] ->
            MapPName = common_misc:get_map_name(MapID),
            case global:whereis_name(MapPName) of
                undefined ->
                    {error, not_found};
                PID ->
                    {ok, PID}
            end
    end.

%% 某些情况下需要强制删除玩家身上的某件装备
notify_del_equip(RoleID, SlotNum) when erlang:is_integer(SlotNum) ->
    notify_del_equip(RoleID, [SlotNum]);
notify_del_equip(RoleID, SlotNums) ->
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EQUIP, ?EQUIP_DEL, #m_equip_del_toc{slot_nums=SlotNums}),
    ok.


%% 装备的颜色计算装备的品质和子品质
%% 返回 {Quality,SubQuality}
get_equip_quality_by_color(Color) ->
    [ColorToQualityList] = common_config_dyn:find(refining,color_to_quality),
    case lists:keyfind(Color,1,ColorToQualityList) of
        false ->
            Quality = 1,
            SubQuality = 1;
        {Color,Quality,SubQuality} ->
            ignore
    end,
    {Quality,SubQuality}.

print_pay_error_msg(Reason,Msg) ->
	case Msg of
		{mod_map_role,{add_money, {_RoleID, _, _, {pay_add_gold,_,_}, {pay_add_gold,_,_},_}}} ->
			?ERROR_MSG("充值出错：Reason:~w,Msg:~w",[Reason,Msg]);
		_ ->
			nil
	end.

get_collect_break_msg(SrcActorID, SrcActorType) when erlang:is_integer(SrcActorID) ->
    case SrcActorType of
        role ->
            case mod_map_actor:get_actor_mapinfo(SrcActorID,role) of
                #p_map_role{role_name = SActorName} ->
                    lists:flatten(io_lib:format(?_LANG_COLLECT_BREAK_BY_ATTACKED,[SActorName]));
                _ ->
                    ?_LANG_COLLECT_BREAK
            end;
        _ ->
            ?_LANG_COLLECT_BREAK
    end;
get_collect_break_msg(SrcActorName, SrcActorType) ->
    case SrcActorType of
        role ->
            lists:flatten(io_lib:format(?_LANG_COLLECT_BREAK_BY_ATTACKED,[SrcActorName]));
        _ ->
            ?_LANG_COLLECT_BREAK
    end.

format_goods_name(GoodsList) ->
    lists:foldl(
      fun({TypeID,Type,Num},Names) ->
              Name = 
                  case Type of
                      ?TYPE_EQUIP ->
                          [BaseInfo]=common_config_dyn:find_equip(TypeID),
                          BaseInfo#p_equip_base_info.equipname;
                      ?TYPE_ITEM ->
                          [BaseInfo]=common_config_dyn:find_item(TypeID),
                          BaseInfo#p_item_base_info.itemname;
                      ?TYPE_STONE ->
                          [BaseInfo]=common_config_dyn:find_stone(TypeID),
                          BaseInfo#p_stone_base_info.stonename
                  end,
              concat(["\n",binary_to_list(Name),"×",Num,Names])
      end,"",GoodsList).
concat(List) when is_list(List)->
    lists:concat(List).   

%% 公用解析错误码
parse_aborted_err(AbortErr)->
    case AbortErr of
        {error,ErrCode,_Reason} when is_integer(ErrCode) ->
            AbortErr;
        {bag_error,{not_enough_pos,_BagID}}->
            {error,2,<<"您的背包空间不足，赶紧去整理背包吧">>};
        {bag_error,num_not_enough}->
            {error,2,<<"背包找不到该道具或装备">>};
        {error,AbortReason} when is_binary(AbortReason) ->
            {error,2,AbortReason};
        AbortReason when is_binary(AbortReason) ->
            {error,2,AbortReason};
        _ ->
            ?ERROR_MSG(" aborted,AbortErr=~w,stack=~w",[AbortErr,erlang:get_stacktrace()]),
            {error,1,undefined}
    end.

%% 玩家总充值元宝
role_total_pay_gold(RoleID) ->
	case db:dirty_read(?DB_PAY_ACTIVITY_P, RoleID) of
		[] -> 0;
		[#r_pay_activity{all_pay_gold=AllPayGold}] ->
			AllPayGold
	end.

send_common_error(RoleID, ErrorCode, ErrorStr) ->
    Msg = #m_common_error_toc{
        error_code = ErrorCode,
        error_str  = ErrorStr
    },
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, 
                        ?COMMON, ?COMMON_ERROR, Msg).

%% term序列化，term转换为string格式，e.g., [{a},1] => "[{a},1]"
term_to_string(Term) ->
    lists:flatten(io_lib:format("~w", [Term])).    

%% CreateInfoList: [#r_goods_create_info{}]
get_mail_items_create_info(RoleID, CreateInfoList) ->
    get_mail_items_create_info(RoleID, CreateInfoList, []).

get_mail_items_create_info(_RoleID, [], GoodsList) -> GoodsList;
get_mail_items_create_info(RoleID, [CreateInfo | Rest], GoodsList) ->
    {ok, GoodsList1} = mod_bag:create_p_goods(RoleID, CreateInfo),
    {_, GoodsList3} = lists:foldl(fun(Goods, {IdNum, GoodsList2}) ->
        Goods2        = Goods#p_goods{id = IdNum},
        {IdNum+1, [Goods2|GoodsList2]}
    end, {1, []}, GoodsList1),
    % Goods2        = Goods#p_goods{id = 1},
    get_mail_items_create_info(RoleID, Rest, GoodsList3 ++ GoodsList).


%% AwardItems: [{ItemId, Num, ItemType, IsBind}]
%% return: CreateInfoList: [#r_goods_create_info{}]
get_items_create_info(RoleID, AwardItems) ->
    get_items_create_info(RoleID, AwardItems, []).

get_items_create_info(_RoleID, [], RecList) -> RecList;
get_items_create_info(RoleID, [Award | Rest], RecList) ->
    {ItemId, Num, ItemType, IsBind} = Award,
    CreateItem = #r_goods_create_info{
        num      = Num,
        type_id  = ItemId,
        type     = ItemType,
        bind     = IsBind,
        bag_id   = 1,
        position = 1
    },
    get_items_create_info(RoleID, Rest, [CreateItem | RecList]).

get_color_name_by_quality(Quality) ->
	Color = get_color_by_quality(Quality),
	get_color_name(Color).
	
get_color_by_quality(Quality) ->
	[Quality2ColorList] = common_config_dyn:find(refining,quality_to_color),
	case catch lists:partition(
		   fun({MinQuality,MaxQuality,_Color}) ->
				   Quality =< MaxQuality andalso  Quality >= MinQuality end,
		   Quality2ColorList) of
		{[{_,_,Color}],_} ->
			Color;
		_ -> 1
	end.

get_color_name(Color) ->
	case Color of
		?COLOUR_WHITE ->
			"白色";
		?COLOUR_GREEN ->
			"绿色";
		?COLOUR_BLUE ->
			"蓝色";
		?COLOUR_PURPLE ->
			"紫色";
		?COLOUR_ORANGE ->
			"橙色";
		?COLOUR_GOLD ->
			"金色";
		_ ->
			"未知颜色"
	end.
	
