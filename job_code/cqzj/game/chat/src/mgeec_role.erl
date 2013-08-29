-module(mgeec_role).

-behavior(gen_server).

-include("mgeec.hrl").

-export([start_link/1, init/1]).

-export([handle_info/2, handle_cast/2, handle_call/3, terminate/2, code_change/3]).

-define(MGEEC_ROLE_STATE, mgeec_role_state).


start_link({RoleID, RoleName, ChatRolePName, ChatInitData, GatewayPID}) ->
    StartResult = 
        gen_server:start_link({global, ChatRolePName},
                              ?MODULE, [ChatInitData, RoleID, RoleName, ChatRolePName, GatewayPID], 
                              []),
    case StartResult of
        {ok, Pid} ->
            {ok, Pid};
        {error,{already_started, Pid}} ->
            {ok, Pid};
        Other ->
            ?ERROR_MSG("~ts:~w", ["创建角色进程失败了", Other]),
            throw(Other)
    end.

init([ChatInitData, RoleID, RoleName, ChatRolePName, GatewayPID]) ->
    %%?DEV("~ts:~w", ["玩家进程初始化了, 玩家信息", ChatInitData]),
    ClientIP = 0,
    erlang:process_flag(trap_exit, true),
    {RoleChatData, ChatRoleInfo, ChannelList} = ChatInitData,
    %%初始化角色黑名单列表
    init_role_balck_list(RoleID),
    %%初始化角色的频道设置，开启或关闭情况
    init_role_channel_config(RoleID),
    State = #chat_role_state{
                             channel_list = ChannelList,
                             role_chat_data = RoleChatData,
                             chat_role_info = ChatRoleInfo,
                             client_ip=ClientIP, 
                             role_id=RoleID, 
                             role_name=RoleName,
                             process_name=ChatRolePName,
                             last_chat_time={0, 0, 0}, 
                             gateway_pid=GatewayPID},
    {ok, State}.

handle_info({'EXIT', _, {socket_send_error, _Reason}}, State) ->
    %%?DEBUG("~ts:~w", ["玩家退出，原因是发包出错", Reason]),
    {stop, normal, State};

handle_info({'EXIT', _Pid, offline}, State) ->
    {stop, normal, State};

handle_info({'EXIT', _PID, normal}, State) ->
    {stop, normal, State};

handle_info({set_channels, RoleID, RoleName, RoleChatInfo, Pid, NewChannelList}, State) ->
    lists:foreach(
      fun(Item) ->
              mgeec_misc:set_channel_role(Item, 
                                          RoleID,
                                          RoleName,
                                          RoleChatInfo, 
                                          Pid)
      end, NewChannelList),
    {noreply, State};
handle_info({set_gateway_pid, GatewayPID}, State) ->
    {noreply, State#chat_role_state{gateway_pid=GatewayPID}};
handle_info(Binary, State)when is_binary(Binary) ->
    State#chat_role_state.gateway_pid ! {binary, Binary},
    {noreply, State};

handle_info({kick, _Reason}, State) ->
    %%?DEV("~ts:~w", ["玩家被T下线,原因", Reason]),
    {stop, normal, State};

handle_info({add_black, BlackName}, State) ->
    do_add_black(BlackName),
    {noreply, State};

handle_info({del_black, BlackID}, State) ->
    do_del_black(BlackID),
    {noreply, State};

handle_info({channel_config_change, NewConfig}, State) ->
    do_channel_config_change(NewConfig),
    {noreply, State};

handle_info({update_title, NewTitle}, State) ->
    NewState = do_update_title(State, NewTitle),
    {noreply, NewState};

handle_info({change_sex, NewSex}, State) ->
	NewState = do_change_sex(State, NewSex),
    {noreply, NewState};

handle_info({router, RouterData}, State) ->
    #chat_role_state{role_id=RoleID, gateway_pid=GatewayPID} = State,
    {Unique, Module, Method, DataRecord} = RouterData,
    RouterData2 = {Method, Module, RoleID, DataRecord, GatewayPID, Unique},

    NewState = mod_router:router(RouterData2, State),
    {noreply, NewState};

handle_info({Method, Module, RoleID, Record, GatewayPID, Unique}, State) ->
    NewState = mod_router:router({Method, Module, RoleID, Record, GatewayPID, Unique}, State),
    {noreply, NewState};

handle_info({reduce_role_money_succ, _RoleID, _RoleAttr, _Rtn}, State) ->
    {noreply, State};

handle_info(Info, State) ->
    ?ERROR_MSG("~ts:~w", ["收到未知的消息(handle_info)", Info]),
    {noreply, State}.

handle_cast({router, RouterData}, State) ->
    %%?DEV("~ts:~w", ["执行路由数据", RouterData]),
    NewState = mod_router:router(RouterData, State),
    %%?DEV("~ts:~w", ["执行路由后新状态数据", NewState]),
    {noreply, NewState};
    
handle_cast(Info, State) ->
    ?ERROR_MSG("~ts:~w", ["收到未知的消息(handle_cast)", Info]),
    {noreply, State}.

handle_call(login_again, _From, State) ->
    %%?DEV("~ts:~w", ["玩家重复登录", State]),
    {stop, normal, ok, State};
   
handle_call(_Info, _From, State) ->
    %%?DEV("~ts:~w", ["收到未知的消息(handle_call)", Info]),
    {reply, ok, State}.

terminate(_Reason, State) ->
    %%?DEV("~ts:~w ~ts:~w", ["玩家退出聊天室", Reason, "退出时状态数据", State]),
    RoleID = State#chat_role_state.role_id,    
    ChannelList = State#chat_role_state.channel_list,

    lists:foreach(
      fun(Channel) ->
              ChannelSign = Channel#p_channel_info.channel_sign,
              ChannelType = Channel#p_channel_info.channel_type,
              case ChannelType of
                  ?CHANNEL_TYPE_LEVEL ->
                      write_role_offline_to_db(RoleID, ChannelSign),
                      gen_server:cast({global, ChannelSign}, 
                                      {offline_notify, RoleID});
                  _ ->
                      gen_server:cast({global, ChannelSign}, 
                                      {leave, RoleID})
              end
      end, ChannelList),

    ok.

write_role_offline_to_db(RoleID, ChannelSign) ->
    Pattern = #p_chat_channel_role_info{channel_sign=ChannelSign, role_id=RoleID, _='_'},
    case  db:dirty_match_object(?DB_CHAT_CHANNEL_ROLES, Pattern) of
        [RoleChannelInfo] ->
            NewRoleChannelInfo = RoleChannelInfo#p_chat_channel_role_info{is_online=false},
            db:dirty_delete_object(?DB_CHAT_CHANNEL_ROLES, RoleChannelInfo),
            db:dirty_write(?DB_CHAT_CHANNEL_ROLES, NewRoleChannelInfo),
            
            [ChannelInfo] = db:dirty_read(?DB_CHAT_CHANNELS, ChannelSign),
            OnlineNum = ChannelInfo#p_channel_info.online_num-1,
            NewChannelInfo = ChannelInfo#p_channel_info{online_num=OnlineNum},
            db:dirty_write(?DB_CHAT_CHANNELS, NewChannelInfo);
        [] ->
            ignore
    end.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%==================================internal function================================

%%更新聊天中的角色的称号前缀
do_update_title(State, Titles) ->
    NewRoleChatInfo = (State#chat_role_state.chat_role_info)#p_chat_role{titles=Titles},
    State#chat_role_state{chat_role_info=NewRoleChatInfo}.

%%改变聊天中的角色的性别
do_change_sex(State, NewSex) ->
	NewRoleChatInfo = (State#chat_role_state.chat_role_info)#p_chat_role{sex=NewSex},
    State#chat_role_state{chat_role_info=NewRoleChatInfo}.	
  
init_role_balck_list(RoleID) ->
    %%获取角色好友黑名单
    Pattern = #r_friend{roleid=RoleID, type=2, _='_'},
    case catch db:dirty_match_object(?DB_FRIEND, Pattern) of
        {'EXIT', _R} ->
            %%?DEV("init_role_black_list, r: ~w", [R]),
            BlackList2 = [];
        [] ->
            BlackList2 = [];
        BlackList ->
            BlackList2 = BlackList
    end,
    %%?DEV("init_role_black_list, blacklist2: ~w", [BlackList2]),
    
    %%加入聊天黑名单
    ChatBlackList =
        lists:foldl(
          fun(BlackInfo, Acc) ->
                  BlackID = BlackInfo#r_friend.friendid,
                  
                  case mgeec_misc:d_get_chat_role_info(BlackID) of
                      false ->
                          Acc;
                      ChatInfo ->
                          [ChatInfo|Acc]
                  end
          end, [],  BlackList2),
    %%?DEV("init_role_black_list, chatblacklist: ~w", [ChatBlackList]),
    
    put(black_list, ChatBlackList).

%%添加黑名单
do_add_black(BlackName) ->
    BlackChatInfo = mgeec_misc:d_get_chat_role_info(BlackName),
    
    case BlackChatInfo of
        false ->
            ok;
        _ ->
            BlackList = get(black_list),
            DelBlackList = lists:keydelete(BlackName, #p_chat_role.rolename, BlackList),
            put(black_list, [BlackChatInfo|DelBlackList])
    end.

do_del_black(BlackID) ->
    BlackList = get(black_list),
    put(black_list, lists:keydelete(BlackID, #p_chat_role.roleid, BlackList)).

init_role_channel_config(RoleID) ->
    case catch db:dirty_read(?DB_SYSTEM_CONFIG, RoleID) of
        {'EXIT', _} ->
            put(channel_config, [true, true, true, true, true, true]);
        [] ->
            put(channel_config, [true, true, true, true, true, true]);
        [#r_sys_config{sys_config=SysConfig}] ->
            #p_sys_config{private_chat=PrivateChat, nation_chat=NationChat, family_chat=FamilyChat,
                          world_chat=WorldChat, team_chat=TeamChat, center_broadcast=CenterBroadcast} = SysConfig,
            put(channel_config, [WorldChat, NationChat, FamilyChat, TeamChat, PrivateChat, CenterBroadcast])
    end.

do_channel_config_change(NewConfig) ->
    put(channel_config, NewConfig).
