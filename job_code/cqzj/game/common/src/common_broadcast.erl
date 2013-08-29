%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     通用的消息广播接口
%%% @end
%%% Created : 2010-12-1
%%%-------------------------------------------------------------------
-module(common_broadcast).

-include("common.hrl").
-include("common_server.hrl").


%% 消息广播接口
-export([bc_send_msg_world/4,
         bc_send_msg_world/3,
         bc_send_msg_faction/5,
         bc_send_msg_faction/4,
         bc_send_msg_family/4,
         bc_send_msg_team/4,
         bc_send_msg_role/3,
         bc_send_msg_role/4,
         bc_send_msg_world/6,
         bc_send_msg_faction/7,
         bc_send_msg_family/7,
         bc_send_msg_team/7,
         bc_send_msg_role/7,
         bc_send_cycle_msg_world/6,
         bc_send_cycle_msg_faction/7,
         bc_send_cycle_msg_family/7,
         bc_send_cycle_msg_team/7,
         bc_send_cycle_msg_role/7,
         bc_send_msg_world_include_goods/7,
         bc_send_msg_faction_include_goods/8]).


%% 消息广播接口

%% 消息类型——
%%        2905:操作消息,2906:系统消息,2908:喇叭消息,2909:中央广播消息,2910:聊天频道消息,2911:弹窗消息
%% 消息子类型 ——
%%        2912:表示没有消息子类型；聊天频道消息子类型：2915世界,2916国家,2917家族,2918组队

%% -define(BC_MSG_TYPE_OPERATE, 2905).
%% -define(BC_MSG_TYPE_SYSTEM, 2906).
%% -define(BC_MSG_TYPE_COUNTDOWN, 2907).
%% -define(BC_MSG_TYPE_ALL, 2908).
%% -define(BC_MSG_TYPE_CENTER, 2909).
%% -define(BC_MSG_TYPE_CHAT, 2910).
%% -define(BC_MSG_TYPE_POP, 2911).
%% -define(BC_MSG_SUB_TYPE, 2912).
%% -define(BC_MSG_TYPE_COUNTDOWN_DUNGEON, 2913).
%% -define(BC_MSG_TYPE_COUNTDOWN_TASK, 2914).
%% -define(BC_MSG_TYPE_CHAT_WORLD, 2915).
%% -define(BC_MSG_TYPE_CHAT_COUNTRY, 2916).
%% -define(BC_MSG_TYPE_CHAT_FAMILY, 2917).
%% -define(BC_MSG_TYPE_CHAT_TEAM, 2918).

%% world
%% boss群用的接口  弹出框提示
bc_send_msg_world(TypeList,SubType,Content,ExtList) when is_list(TypeList)  ->
    Msg = #m_broadcast_general_toc{type=TypeList, sub_type=SubType, content=Content, ext_info_list=ExtList},
    common_misc:chat_broadcast_to_world(?BROADCAST, ?BROADCAST_GENERAL, Msg).
bc_send_msg_world(Type,SubType,Content) when is_integer(Type) ->
    Record = #m_broadcast_general_tos{type = Type,sub_type = SubType,content = Content,
                                      role_list = [],is_world = true,country_id = 0,
                                      famliy_id = 0,team_id = 0},
    broadcast_send_message(?BROADCAST_GENERAL,Record);
bc_send_msg_world(TypeList, SubType, Content) when is_list(TypeList) ->
    Msg = #m_broadcast_general_toc{type=TypeList, sub_type=SubType, content=Content},
    common_misc:chat_broadcast_to_world(?BROADCAST, ?BROADCAST_GENERAL, Msg).

bc_send_msg_world_include_goods(Type, SubType, Content, RoleID, RoleName, Sex, GoodsList) when is_integer(Type) ->
    bc_send_msg_world_include_goods([Type], SubType, Content, RoleID, RoleName, Sex, GoodsList);
bc_send_msg_world_include_goods(TypeList, SubType, Content, RoleID, RoleName, Sex, GoodsList) when is_list(TypeList) ->
    case global:whereis_name(mgeec_goods_cache) of
        undefined ->
            ?ERROR_MSG("悲剧，mgeec_goods_cache挂了!!!", []);
        PID ->
            PID ! {bc_send_msg_world, TypeList, SubType, Content, RoleID, RoleName, Sex, GoodsList}
    end.

%% faction
bc_send_msg_faction(FactionId,TypeList,SubType,Content,ExtList) when is_list(TypeList) ->
    Msg = #m_broadcast_general_toc{type=TypeList, sub_type=SubType, content=Content,ext_info_list=ExtList},
    common_misc:chat_broadcast_to_faction(FactionId, ?BROADCAST, ?BROADCAST_GENERAL, Msg).

bc_send_msg_faction(FactionId,Type,SubType,Content) when is_integer(Type) ->
    Record = #m_broadcast_general_tos{type = Type,sub_type = SubType,content = Content,
                                      role_list = [],is_world = false,country_id = FactionId,
                                      famliy_id = 0,team_id = 0},
    broadcast_send_message(?BROADCAST_GENERAL,Record);
bc_send_msg_faction(FactionID, TypeList, SubType, Content) when is_list(TypeList) ->
    Msg = #m_broadcast_general_toc{type=TypeList, sub_type=SubType, content=Content},
    common_misc:chat_broadcast_to_faction(FactionID, ?BROADCAST, ?BROADCAST_GENERAL, Msg).

bc_send_msg_faction_include_goods(FactionID, Type, SubType, Content, RoleID, RoleName, Sex, GoodsList) when is_integer(Type) ->
    bc_send_msg_faction_include_goods(FactionID, [Type], SubType, Content, RoleID, RoleName, Sex, GoodsList);
bc_send_msg_faction_include_goods(FactionID, TypeList, SubType, Content, RoleID, RoleName, Sex, GoodsList) when is_list(TypeList) ->
    case global:whereis_name(mgeec_goods_cache) of
        undefined ->
            ?ERROR_MSG("悲剧，mgeec_goods_cache挂了!!!", []);
        PID ->
            PID ! {bc_send_msg_faction, FactionID, TypeList, SubType, Content, RoleID, RoleName, Sex, GoodsList}
    end.

%% family
bc_send_msg_family(FamilyId,Type,SubType,Content) when is_integer(Type) ->
    Record = #m_broadcast_general_tos{type = Type,sub_type = SubType,content = Content,
                                      role_list = [],is_world = false,country_id = 0,
                                      famliy_id = FamilyId,team_id = 0},
    broadcast_send_message(?BROADCAST_GENERAL,Record);
bc_send_msg_family(FamilyId, TypeList, SubType, Content) when is_list(TypeList) ->
    Msg = #m_broadcast_general_toc{type=TypeList, sub_type=SubType, content=Content},
    common_misc:chat_broadcast_to_family(FamilyId, ?BROADCAST, ?BROADCAST_GENERAL, Msg).

%% team
bc_send_msg_team(TeamId,Type,SubType,Content) when is_integer(Type) ->
    Record = #m_broadcast_general_tos{type = Type,sub_type = SubType,content = Content,
                                      role_list = [],is_world = false,country_id = 0,
                                      famliy_id = 0,team_id = TeamId},
    broadcast_send_message(?BROADCAST_GENERAL,Record).

%% role
%% @param RoleID ::integer() | list() 玩家ID或者玩家ID的列表
%% @param TypeOrList ::integer() | list() 频道ID或频道ID的列表
bc_send_msg_role(RoleID,TypeOrList,Content) ->
    bc_send_msg_role(RoleID,TypeOrList,?BC_MSG_SUB_TYPE,Content).
bc_send_msg_role(RoleID,Type,SubType,Content) when is_integer(Type) ->
    case RoleID of
        RoleID when is_list(RoleID) ->
            RoleList = RoleID;
        _ ->
            RoleList = [RoleID]
    end,
    if RoleList =/= [] ->
           Record = #m_broadcast_general_tos{type = Type,sub_type = SubType,content = Content,
                                             role_list = RoleList,is_world = false,country_id = 0,
                                             famliy_id = 0,team_id = 0},
           broadcast_send_message(?BROADCAST_GENERAL,Record);
       true ->
           ignore
    end;
bc_send_msg_role(RoleID,TypeList,SubType,Content) when is_list(TypeList) ->
    Msg = #m_broadcast_general_toc{type=TypeList, sub_type=SubType, content=Content},
    common_misc:chat_broadcast_to_role(RoleID, ?BROADCAST, ?BROADCAST_GENERAL, Msg).

bc_send_msg_world(Type,SubType,Content,Id,CountdownTime,CurrDountdownTime) ->
    Record = #m_broadcast_countdown_tos{type = Type,sub_type = SubType,content = Content,id = Id,
                                        countdown_time = CountdownTime,current_countdown_time = CurrDountdownTime,
                                        role_list = [],is_world = true,country_id = 0,
                                        famliy_id = 0,team_id = 0},
    broadcast_send_message(?BROADCAST_COUNTDOWN,Record).
bc_send_msg_faction(FactionId,Type,SubType,Content,Id,CountdownTime,CurrDountdownTime) ->
    Record = #m_broadcast_countdown_tos{type = Type,sub_type = SubType,content = Content,id = Id,
                                        countdown_time = CountdownTime,current_countdown_time = CurrDountdownTime,
                                        role_list = [],is_world = false,country_id = FactionId,
                                        famliy_id = 0,team_id = 0},
    broadcast_send_message(?BROADCAST_COUNTDOWN,Record).
bc_send_msg_family(FamilyId,Type,SubType,Content,Id,CountdownTime,CurrDountdownTime) ->
    Record = #m_broadcast_countdown_tos{type = Type,sub_type = SubType,content = Content,id = Id,
                                        countdown_time = CountdownTime,current_countdown_time = CurrDountdownTime,
                                        role_list = [],is_world = false,country_id = 0,
                                        famliy_id = FamilyId,team_id = 0},
    broadcast_send_message(?BROADCAST_COUNTDOWN,Record).
bc_send_msg_team(TeamId,Type,SubType,Content,Id,CountdownTime,CurrDountdownTime) ->
    Record = #m_broadcast_countdown_tos{type = Type,sub_type = SubType,content = Content,id = Id,
                                        countdown_time = CountdownTime,current_countdown_time = CurrDountdownTime,
                                        role_list = [],is_world = false,country_id = 0,
                                        famliy_id = 0,team_id = TeamId},
    broadcast_send_message(?BROADCAST_COUNTDOWN,Record).
bc_send_msg_role(RoleID,Type,SubType,Content,Id,CountdownTime,CurrDountdownTime) ->
    case RoleID of
        RoleID when is_list(RoleID) ->
            RoleList = RoleID;
        _ ->
            RoleList = [RoleID]
    end,
    if RoleList =/= [] ->
            Record = #m_broadcast_countdown_tos{type = Type,sub_type = SubType,content = Content,id = Id,
                                                countdown_time = CountdownTime,current_countdown_time = CurrDountdownTime,
                                                role_list = RoleList,is_world = false,country_id = 0,
                                                famliy_id = 0,team_id = 0},
            broadcast_send_message(?BROADCAST_COUNTDOWN,Record);
       true ->
            ignore
    end.

%% 消息类型——
%%        2905:操作消息,2906:系统消息,2908:喇叭消息,2909:中央广播消息,2910:聊天频道消息,2911:弹窗消息
%% 消息子类型 ——
%%        2912:表示没有消息子类型；聊天频道消息子类型：2915世界,2916国家,2917家族,2918组队
%% Content消息内容 ,
%% StartTime开始时间,格式为：common_tool:now()
%% EndTime结束时间,格式为：common_tool:now()
%% IntervalTime间隔时间 单位：秒
bc_send_cycle_msg_world(Type,SubType,Content,StartTime,EndTime,IntervalTime) ->
    Record = #m_broadcast_cycle_tos{type = Type,sub_type = SubType,content = Content,
                                    send_type = 1,start_time = StartTime,
                                    end_time = EndTime,interval = IntervalTime,
                                    role_list = [],is_world = true,country_id = 0,
                                    famliy_id = 0,team_id = 0},
    broadcast_send_message(?BROADCAST_CYCLE,Record).
bc_send_cycle_msg_faction(FactionId,Type,SubType,Content,StartTime,EndTime,IntervalTime) ->
    Record = #m_broadcast_cycle_tos{type = Type,sub_type = SubType,content = Content,
                                    send_type = 1,start_time = StartTime,
                                    end_time = EndTime,interval = IntervalTime,
                                    role_list = [],is_world = false,country_id = FactionId,
                                    famliy_id = 0,team_id = 0},
    broadcast_send_message(?BROADCAST_CYCLE,Record).
bc_send_cycle_msg_family(FamilyId,Type,SubType,Content,StartTime,EndTime,IntervalTime) ->
    Record = #m_broadcast_cycle_tos{type = Type,sub_type = SubType,content = Content,
                                    send_type = 1,start_time = StartTime,
                                    end_time = EndTime,interval = IntervalTime,
                                    role_list = [],is_world = false,country_id = 0,
                                    famliy_id = FamilyId,team_id = 0},
    broadcast_send_message(?BROADCAST_CYCLE,Record).
bc_send_cycle_msg_team(TeamId,Type,SubType,Content,StartTime,EndTime,IntervalTime) ->
    Record = #m_broadcast_cycle_tos{type = Type,sub_type = SubType,content = Content,
                                    send_type = 1,start_time = StartTime,
                                    end_time = EndTime,interval = IntervalTime,
                                    role_list = [],is_world = false,country_id = 0,
                                    famliy_id = 0,team_id = TeamId},
    broadcast_send_message(?BROADCAST_CYCLE,Record).
bc_send_cycle_msg_role(RoleID,Type,SubType,Content,StartTime,EndTime,IntervalTime) ->
    case RoleID of
        RoleID when is_list(RoleID) ->
            RoleList = RoleID;
        _ ->
            RoleList = [RoleID]
    end,
    if RoleList =/= [] ->
            Record = #m_broadcast_cycle_tos{type = Type,sub_type = SubType,content = Content,
                                            send_type = 1,start_time = StartTime,
                                            end_time = EndTime,interval = IntervalTime,
                                            role_list = RoleList,is_world = false,country_id = 0,
                                            famliy_id = 0,team_id = 0},
            broadcast_send_message(?BROADCAST_CYCLE,Record);
       true ->
            ignore
    end.
broadcast_send_message(Method,Record) ->
    global:send("mod_broadcast_server",{0, ?BROADCAST, Method, Record}).

