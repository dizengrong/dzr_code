-module(mod_router).
-include("mgeec.hrl").

-export([router/2]).
    
router({?CHAT_IN_CHANNEL, _ModuleID, RoleID, DataRecord, GatewayPID, Unique}, State) ->
    RoleChatInfo = State#chat_role_state.chat_role_info,    
    %%?DEV("~ts:~w", ["收到频道聊天请求", DataRecord]),
    #m_chat_in_channel_tos{channel_sign=ChannelSign, msg=TmpMsg} = DataRecord,
    case mod_chat_gm:cmd(RoleID, TmpMsg) of
        {gm, Msg} ->
            Auth = gm;
        {not_gm, Msg} ->
            Auth = mod_post_auth:auth_chat_in_channel(DataRecord, RoleChatInfo, State)
    end,            
    case Auth of
        gm ->
            SuccDataRecord = 
                #m_chat_in_channel_toc{succ=true, 
                                       msg=Msg,
                                       channel_sign=ChannelSign,
                                       role_info=RoleChatInfo,
                                       tstamp=common_tool:now()
                                      },
            GatewayPID ! {message, Unique, ?CHAT, ?CHAT_IN_CHANNEL, SuccDataRecord},
            NewState = State;
        {false, Reason} ->
            FailDataRecord = 
                #m_chat_in_channel_toc{succ=false, 
                                       channel_sign=ChannelSign,
                                       reason=Reason
                                       },
            GatewayPID ! {message, Unique, ?CHAT, ?CHAT_IN_CHANNEL, FailDataRecord},
            NewState = State;
        true ->
            ?TRY_CATCH( gen_server:cast({global, ChannelSign}, {chat, RoleID, RoleChatInfo, Msg}) ),
            %%?DEV("~ts:~w", ["通知频道进程广播聊天", ]),
            SuccDataRecord = 
                #m_chat_in_channel_toc{succ=true, 
                                       msg=Msg,
                                       channel_sign=ChannelSign,
                                       role_info=RoleChatInfo,
                                       tstamp=common_tool:now()
                                      },
            GatewayPID ! {message, Unique, ?CHAT, ?CHAT_IN_CHANNEL, SuccDataRecord},
            mgeec_logger:log_channel(ChannelSign, RoleChatInfo, Msg),
            %%?DEV("~w", []),
            NewState = State#chat_role_state{last_chat_time=erlang:now()}            
    end,
    NewState;

router({?CHAT_IN_PAIRS, _ModuleID, _RoleID, DataRecord, GatewayPID, Unique}, State) ->
    RoleChatInfo = State#chat_role_state.chat_role_info,    
    %%?DEV("~ts:~w", ["当前玩家数据", RoleChatInfo]),
    %%?DEV("~ts:~w", ["收到私聊请求", DataRecord]),
    #m_chat_in_pairs_tos{to_rolename=ToRoleName, 
                         show_type=ShowType,
                         msg=Msg} = DataRecord,
    Auth = mod_post_auth:auth_chat_in_pairs(DataRecord, RoleChatInfo, State),
    case Auth of
        {false, _FailReasonAtom, FailDataRecord} ->
            GatewayPID ! {message, Unique, ?CHAT, ?CHAT_IN_PAIRS, FailDataRecord},
            NewState = State;
        true ->            
            ToRoleChatInfo = mgeec_misc:d_get_chat_role_info(ToRoleName),
            do_chat_in_pairs(ToRoleChatInfo, Msg, ShowType, RoleChatInfo, GatewayPID, Unique),
            NewState = State#chat_role_state{last_chat_time=erlang:now()}
            
    end,
    NewState;

router({?CHAT_ADD_BLACK, _ModuleID, _RoleID, DataRecord, GatewayPID, Unique}, State) ->

    BlcakRoleName = DataRecord#m_chat_add_black_tos.rolename,
    BlcakRoleChatInfo = mgeec_misc:d_get_chat_role_info(BlcakRoleName),
    
    if
        BlcakRoleChatInfo /= false ->
            BlcakList = get(black_list),
            DelBlackList = lists:keydelete(BlcakRoleName, #p_chat_role.rolename, BlcakList),
            put(black_list, [BlcakRoleChatInfo|DelBlackList]),
            SuccDataRecord = 
                #m_chat_add_black_toc{succ=true,
                                      role_info=BlcakRoleChatInfo},
            GatewayPID ! {message, Unique, ?CHAT, ?CHAT_ADD_BLACK, SuccDataRecord};
        true ->            
            FaildDataRecord = 
                #m_chat_add_black_toc{succ=false,
                                      reason=?_LANG_CHAT_ROLE_NOT_EXISTS},
            GatewayPID ! {message, Unique, ?CHAT, ?CHAT_ADD_BLACK, FaildDataRecord}
    end,
    State;

router({?CHAT_REMOVE_BLACK, _ModuleID, _RoleID, DataRecord, GatewayPID, Unique}, State) ->
    BlcakRoleName = DataRecord#m_chat_remove_black_tos.rolename,
    BlcakRoleChatInfo = mgeec_misc:d_get_chat_role_info(BlcakRoleName),
    if
        BlcakRoleChatInfo /= false ->
            BlcakList = get(black_list),
            NewBlackList = lists:keydelete(BlcakRoleName, #p_chat_role.rolename, BlcakList),
            put(black_list, NewBlackList),

            DataRecord = 
                #m_chat_remove_black_toc{succ=true,
                                         role_info=BlcakRoleChatInfo};
        true ->            
            DataRecord = 
                #m_chat_remove_black_toc{succ=false,
                                         reason=?_LANG_CHAT_ROLE_NOT_EXISTS}
    end,
    GatewayPID ! {message, Unique, ?CHAT, ?CHAT_REMOVE_BLACK, DataRecord},
    State;

router({?CHAT_GET_ROLES, _ModuleID, _RoleID, DataRecord, GatewayPID, Unique}, State) ->
    ChannelSign = DataRecord#m_chat_get_roles_tos.channel_sign,
    Pattern = #p_chat_channel_role_info{channel_sign=ChannelSign, is_online = true, _='_'},
    try
        case db:dirty_read(?DB_CHAT_CHANNELS, ChannelSign) of
            [ChannelInfo] ->
                List =  db:dirty_match_object(?DB_CHAT_CHANNEL_ROLES, Pattern),
                
                DataTOC = 
                    #m_chat_get_roles_toc{succ=true, 
                                          channel_sign=ChannelInfo#p_channel_info.channel_sign,
                                          channel_type=ChannelInfo#p_channel_info.channel_type,
                                          roles=List};

            _ ->
                ?ERROR_MSG("~ts", ["没有找到频道的基本信息"]),
                DataTOC = 
                    #m_chat_get_roles_toc{succ=false, reason=?_LANG_CHANNEL_NOT_EXISTS}
                
        end,
        GatewayPID ! {message, Unique, ?CHAT, ?CHAT_GET_ROLES, DataTOC}
    catch 
        _:Error ->
            GatewayPID ! {message, Unique, ?CHAT, ?CHAT_GET_ROLES, #m_chat_get_roles_toc{succ=false, reason=?_LANG_SYSTEM_ERROR}},            
            ?ERROR_MSG("~ts:~w", ["获取频道玩家列表出错了", Error])
    end,    
    State;

router({?CHAT_GET_GOODS, _ModuleID, _RoleID, DataIn, GatewayPID, Unique}, State) ->
    #m_chat_get_goods_tos{goods_id=GoodsID} = DataIn,

    case mgeec_goods_cache:get_cache_goods(GoodsID) of
        {ok, GoodsInfo} ->
            DataRecord = #m_chat_get_goods_toc{goods_info=GoodsInfo};
        {error, _} ->
            DataRecord = #m_chat_get_goods_toc{succ=false, goods_id=GoodsID, reason=?_LANG_CHAT_GOODS_NOT_FOUND}
    end,
    GatewayPID ! {message, Unique, ?CHAT, ?CHAT_GET_GOODS, DataRecord},
    State;

%%国王禁言
router({?CHAT_KING_BAN, _ModuleID, RoleID, DataIn, GatewayPID, Unique}, State) ->
    #m_chat_king_ban_tos{roleid=DesRoleID,rolename=RoleName,total_times=TotalTimes}=DataIn,
    case common_misc:get_dirty_role_base(RoleID) of
        {error,_Reason} ->
            ignore;
        {ok, #p_role_base{faction_id=FactionID}}->
            case mod_chat_ban:ban_by_king(DesRoleID,RoleName,TotalTimes,?_LANG_CHAT_KING_BAN_REASON,RoleID) of
                {ok,BroadMsg,RTimes} ->
                    common_broadcast:bc_send_msg_faction(FactionID, [?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_COUNTRY,BroadMsg),			
                    RecordData = #m_chat_king_ban_toc{bantimes=RTimes-1};
                {false,Reason} ->
                    RecordData = #m_chat_king_ban_toc{succ=false,reason=Reason,bantimes=0};            
                {error,Error} ->
                    RecordData = #m_chat_king_ban_toc{succ=false,reason=Error,bantimes=100}
            end,
            GatewayPID ! {message, Unique, ?CHAT, ?CHAT_KING_BAN, RecordData}           
    end,
    State;	

router({role_msg, FromRoleChatInfo, DataRecord}, State) ->    
    Auth = check_msg_role(FromRoleChatInfo),
    %%检测角色系统设置，5是自定义类型，表示私聊
    Auth2 = check_channel_config2(5),
    if
        Auth =:= true andalso Auth2 =:= true ->
            FromRoleChatInfo = DataRecord#m_chat_in_pairs_toc.from_role_info,
            FriendID = FromRoleChatInfo#p_chat_role.roleid,
            set_friendly_chat_num(FriendID),
            State#chat_role_state.gateway_pid ! {message, ?DEFAULT_UNIQUE, ?CHAT, ?CHAT_IN_PAIRS, DataRecord};
        true ->
            ignore
    end,

    State;

router({role_msg, Module, Method, DataRecord}, State) ->    
    State#chat_role_state.gateway_pid ! {message, ?DEFAULT_UNIQUE, Module, Method, DataRecord},
    State;

router({channel_msg, FromRoleChatInfo, DataRecord}, State) ->
    Auth = check_msg_role(FromRoleChatInfo),    
    %%检测角色频道设置
    Auth2 = check_channel_config(DataRecord#m_chat_in_channel_toc.channel_sign, State#chat_role_state.channel_list),
    if
        Auth =:= true andalso Auth2 =:= true ->
            State#chat_role_state.gateway_pid ! {message, ?DEFAULT_UNIQUE, ?CHAT, ?CHAT_IN_CHANNEL, DataRecord};
        true ->
            ignore
    end,
    State;

router({broadcast_msg, Module, Method, DataRecord}, State) when Module =:= ?BROADCAST andalso Method =:= ?BROADCAST_GENERAL ->
    %%?DEV("broadcast_msg, datarecord: ~w", [DataRecord]),
    Type = DataRecord#m_broadcast_general_toc.type,    
    %%检测角色系统配置，2909代表中央广播
    Auth = 
        case Type =:= 2909 of
            true ->
                check_channel_config2(6);
            _ ->
                true
        end,    
    case Auth of
        true ->
            State#chat_role_state.gateway_pid ! {message, ?DEFAULT_UNIQUE, Module, Method, DataRecord};
        _ ->
            ignore
    end,
    
    State;

router({broadcast_msg, Module, Method, DataRecord}, State) ->
    State#chat_role_state.gateway_pid ! {message, ?DEFAULT_UNIQUE, Module, Method, DataRecord},
    State;

router({join_channel, team, TeamID}, State) ->
    {ChannelSign, ChannelInfo} = 
        common_misc:chat_get_team_channel_info(TeamID),
    do_join_channel(ChannelSign, ChannelInfo, State);

router({leave_channel, team, TeamID}, State) ->

    {ChannelSign, ChannelInfo} = 
        common_misc:chat_get_team_channel_info(TeamID),

    do_leave_channel(ChannelSign, ChannelInfo, State);

router({join_channel, family, FamilyID}, State) ->

    {ChannelSign, ChannelInfo} = 
        common_misc:chat_get_family_channel_info(FamilyID),

    do_join_channel(ChannelSign, ChannelInfo, State);

router({leave_channel, family, FamilyID}, State) ->

    {ChannelSign, ChannelInfo} = 
        common_misc:chat_get_family_channel_info(FamilyID),

    do_leave_channel(ChannelSign, ChannelInfo, State);

router({level_change, OldLevel, NewLevel, FactionID}, State) ->
    do_level_change_channel(OldLevel, NewLevel, FactionID, State);

router(_Other, State) ->
    %%?DEV("~ts:~w", ["收到未定义的数据，路由信息为", Other]),
    State.

do_chat_in_pairs(false, _Msg, _ShowType, _FromRoleChatInfo, GatewayPID, Unique) ->
    
    FailDataRecord = #m_chat_in_pairs_toc{succ=false, reason=?_LANG_CHAT_ROLE_NOT_EXISTS},
    GatewayPID ! {message, Unique, ?CHAT, ?CHAT_IN_PAIRS, FailDataRecord};

do_chat_in_pairs(ToRoleChatInfo, Msg, ShowType, FromRoleChatInfo, GatewayPID, Unique) ->
    SuccDataRecord = 
        #m_chat_in_pairs_toc{succ=true, 
                             msg=Msg,
                             show_type=ShowType,
                             to_role_info=ToRoleChatInfo,
                             from_role_info=FromRoleChatInfo,
                             tstamp=common_tool:now()
                            },
    GatewayPID ! {message, Unique, ?CHAT, ?CHAT_IN_PAIRS, SuccDataRecord},
    Data = {role_msg, FromRoleChatInfo, SuccDataRecord},

    ToRoleName = ToRoleChatInfo#p_chat_role.rolename,
    ToRoleID = ToRoleChatInfo#p_chat_role.roleid,
    
    %%好友亲密度
    RoleID = FromRoleChatInfo#p_chat_role.roleid,
    do_add_friendly(RoleID, ToRoleID),

    mgeec_misc:cast_role_router({role, ToRoleName}, Data),
    mgeec_logger:log_pairs(ToRoleID, FromRoleChatInfo, Msg).

do_join_channel(ChannelSign, ChannelInfo, State) ->    
    %%?DEBUG("~ts:~w ~w ~w", ["加入频道, 数据", ChannelSign, ChannelInfo, State]),    
    #chat_role_state{channel_list=ChannelList, 
                     role_id=RoleID, 
                     role_chat_data=RoleChatData,
                     chat_role_info=RoleChatInfo} = State,
    #r_role_chat_data{role_name=RoleName} = RoleChatData,
    DataRecord = 
        #m_chat_join_channel_toc{channel_info=ChannelInfo, 
                                 role_info=RoleChatInfo},
    State#chat_role_state.gateway_pid ! {message, ?DEFAULT_UNIQUE, ?CHAT, ?CHAT_JOIN_CHANNEL, DataRecord},
    DelChannelList = lists:keydelete(ChannelSign, #p_channel_info.channel_sign, ChannelList),
    NewChannelList = [ChannelInfo|DelChannelList],
    
    mgeec_misc:set_channel_role(ChannelInfo, RoleID, RoleName, RoleChatInfo, erlang:self()),    
    State#chat_role_state{channel_list=NewChannelList}.

do_leave_channel(ChannelSign, ChannelInfo, State) ->

    #chat_role_state{channel_list=ChannelList, 
                     role_id=RoleID} = State,

    ChannelType = ChannelInfo#p_channel_info.channel_type,

    DataRecord = 
        #m_chat_leave_channel_toc{channel_sign=ChannelSign, 
                                  channel_type=ChannelType},
    State#chat_role_state.gateway_pid ! {message, ?DEFAULT_UNIQUE, ?CHAT, ?CHAT_LEAVE_CHANNEL, DataRecord},
    gen_server:cast({global, ChannelSign}, {leave, RoleID}),    
    NewChannelList = lists:keydelete(ChannelSign, #p_channel_info.channel_sign, ChannelList),
    State#chat_role_state{channel_list=NewChannelList}.

do_level_change_channel(OldLevel, NewLevel, FactionID, State) ->

    OldChannelInfo = mgeec_misc:get_level_channel(OldLevel, FactionID),
    NewChannelInfo = mgeec_misc:get_level_channel(NewLevel, FactionID),
    
    if
        NewChannelInfo =/= false -> 
            #p_channel_info{channel_sign=NewChannelSign, channel_type=NewChannelType} = NewChannelInfo,
            #chat_role_state{role_id=RoleID, role_chat_data=RoleChatData} = State,
            case OldChannelInfo of
                false ->
                    d_new_join_channel(RoleID, NewChannelType, NewChannelSign, RoleChatData),
                    do_join_channel(NewChannelSign, NewChannelInfo, State);
                OldChannelInfo ->
                    #p_channel_info{channel_sign=OldChannelSign, channel_type=OldChannelType} = OldChannelInfo,
                    if
                        OldChannelSign =/= NewChannelSign ->

                            d_quick_channel(RoleID, OldChannelType, OldChannelSign),
                            d_new_join_channel(RoleID, NewChannelType, NewChannelSign, RoleChatData),

                            StateLeaved = do_leave_channel(OldChannelSign, OldChannelInfo, State),
                            do_join_channel(NewChannelSign, NewChannelInfo, StateLeaved);
                        true ->
                            State
                    end
            end;
        true ->
            State
    end.

check_msg_role(FromRoleChatInfo) ->
    BlcakList = get(black_list),
    %%?DEV("~ts:~w", ["玩家屏蔽列表", BlcakList]),
    Result = 
        lists:keyfind(FromRoleChatInfo#p_chat_role.rolename, 
                      #p_chat_role.rolename, 
                      BlcakList),

    if
        Result =:= false ->
            true;
        true ->
            false
    end.



d_quick_channel(RoleID, ChannelType, ChannelSign) ->
     try
         Data = 
             #r_chat_role_channel_info{channel_sign=ChannelSign, 
                                       role_id=RoleID, 
                                       channel_type=ChannelType},
         
         
         db:dirty_delete_object(?DB_CHAT_ROLE_CHANNELS, Data),
         
         Pattern = #p_chat_channel_role_info{channel_sign=ChannelSign, role_id=RoleID, _='_'},
         case  db:dirty_match_object(?DB_CHAT_CHANNEL_ROLES, Pattern) of
             [RoleChannelInfo] ->
                 gen_server:cast({global, ChannelSign}, {quick, RoleID, RoleChannelInfo}),
                 db:dirty_delete_object(?DB_CHAT_CHANNEL_ROLES, RoleChannelInfo);
             [] ->
                 ?ERROR_MSG("~ts", ["玩家退出了频道，清理数据时发现不存在对应的频道信息"])
         end,


         case db:dirty_read(?DB_CHAT_CHANNELS, ChannelSign) of
             [ChannelInfo] ->
                 OnlineNum = ChannelInfo#p_channel_info.online_num-1,
                 TotalNum = ChannelInfo#p_channel_info.total_num-1,
                 NewChannelInfo = ChannelInfo#p_channel_info{online_num=OnlineNum, total_num=TotalNum},
                 db:dirty_write(?DB_CHAT_CHANNELS, NewChannelInfo),


                 Module = ?CHAT,
                 Method = ?CHAT_QUICK,
                 DataRecord = 
                     #m_chat_quick_toc{role_id=RoleID,
                                       channel_sign=ChannelSign,
                                       channel_type=ChannelType},

                 gen_server:cast({global, ChannelSign}, {broadcast, Module, Method, DataRecord});
             [] ->
                 {error, empty}
         end

     catch 
         _:Error ->
             ?ERROR_MSG("~ts:~w", ["脏写玩家频道角色信息出错了", Error]),
             {error, Error}
     end.

d_new_join_channel(RoleID, ChannelType, ChannelSign, RoleChatData) ->
    try
        ChannelData = 
            #r_chat_role_channel_info{channel_sign=ChannelSign, 
                                      role_id=RoleID, 
                                      channel_type=ChannelType},
        
        case db:dirty_match_object(?DB_CHAT_ROLE_CHANNELS, ChannelData) of
            [] ->
                db:dirty_write(?DB_CHAT_ROLE_CHANNELS, ChannelData),
                
                {NewChannelRoleInfo, _} = 
                    mgeec_misc:dn_update_channel_role_info(RoleID, 
                                                           ChannelSign, 
                                                           ChannelType, 
                                                           true, 
                                                           RoleChatData),
                
                Module = ?CHAT,
                Method = ?CHAT_NEW_JOIN,
                DataRecord = 
                    #m_chat_new_join_toc{role_info=NewChannelRoleInfo,
                                         channel_sign=ChannelSign,
                                         channel_type=ChannelType},
                
                gen_server:cast({global, ChannelSign}, {broadcast, Module, Method, DataRecord}),

                 ok;
             Other ->
                 ?ERROR_MSG("~ts:~w", ["处理玩家新加入频道的数据写入，但发现该频道已经有玩家信息了", Other]),
                 {error, exists}
         end
         
     catch 
         _:Error ->
             ?ERROR_MSG("~ts:~w", ["脏写玩家频道角色信息出错了", Error]),
             {error, Error}
     end.

do_add_friendly(RoleID, FriendID) ->
    %% 2 聊天类型
    case common_misc:if_reach_day_friendly_limited(RoleID, FriendID, 2) of
        false ->
            case set_friendly_chat_num(FriendID) of
                true ->
                    catch global:send(mod_friend_server, {add_friendly,RoleID, FriendID,?CHAT_FRIENDLY_ADD_PER_TIME,2});
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.

set_friendly_time(FriendID) ->
    Key = get_friend_time_key(FriendID),
    Time = erlang:now(),
    put(Key, Time),
    Time.

get_friend_time(FriendID) ->
    Key = get_friend_time_key(FriendID),
    Time = get(Key),
    if
        Time =:= undefined ->
            set_friendly_time(FriendID);
        true ->
            Time
    end.

get_friend_time_key(FriendID) ->
    lists:concat(["friendly_time_", FriendID]).

set_friendly_chat_num(FriendID) ->

    %%?DEV("~ts", ["计算亲密度"]),
    Time = get_friend_time(FriendID),
    DiffTime = common_misc:diff_time(Time),
    Key = get_friendly_chat_num_key(FriendID),
    Num = get(Key),
    Num2 = 
        if
            Num =:= undefined ->
                ?CHAT_FRIENDLY_ADD_PER_TIME;
            true ->
                Num+?CHAT_FRIENDLY_ADD_PER_TIME
        end,

    %%?DEV("~ts:~w", ["当前亲密度数量", Num2]),

    if
        DiffTime > ?CHAT_FRIENDLY_TIME ->
            %%?DEV("~ts", ["计算亲密度1111"]),
            set_friendly_time(FriendID),
            put(Key, Num2),
            false;
        true ->
            if
                Num2 =:= ?CHAT_FRIENDLY_NUM_PER_TIME ->
                    %%?DEV("~ts:~w", ["亲密度累加，等于计点值", Num2]),
                    put(Key, Num2),
                    set_friendly_time(FriendID),
                    true;
                Num2 < ?CHAT_FRIENDLY_NUM_PER_TIME ->
                    %%?DEV("~ts:~w", ["亲密度累加，小于计点值", Num2]),
                    put(Key, Num2),
                    set_friendly_time(FriendID),
                    false;
                true ->
                    %%?DEV("~ts", ["亲密度累加，大雨计点值", Num2]),
                    false
            end
    end.

get_friendly_chat_num_key(FriendID) ->
    lists:concat(["friendly_num_", FriendID]).

check_channel_config(ChannelSign, ChannelList) ->
    ChannelType = get_channel_type(ChannelSign, ChannelList),

    if
        ChannelType =:= false ->
            false;
        true ->
            check_channel_config2(ChannelType)
    end.

check_channel_config2(ChannelType) ->
    ChannelConfig = get(channel_config),
    
    lists:nth(ChannelType, ChannelConfig).

%%根据频道标记获取频道类型
get_channel_type(_ChannelSign, []) ->
    false;
get_channel_type(ChannelSign, [H|_T]) when H#p_channel_info.channel_sign =:= ChannelSign ->
    H#p_channel_info.channel_type;
get_channel_type(ChannelSign, [_H|T]) ->
    get_channel_type(ChannelSign, T).

