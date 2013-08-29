%%%-------------------------------------------------------------------
%%% @author Liangliang <Liangliang@gmail.com>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 18 Sep 2010 by Liangliang <Liangliang@gmail.com>
%%%-------------------------------------------------------------------
-module(mgeeg_tcp_client).

-behaviour(gen_server).

-include("mgeeg.hrl"). 

%% API
-export([start_link/2]).

-export([
         init/1, 
         handle_call/3,
         handle_cast/2, 
         handle_info/2, 
         terminate/2, 
         code_change/3
        ]).

-define(state_wait_for_handshaking, wait_for_handshaking).

-define(state_wait_for_authkey, wait_for_authkey).

-define(state_wait_for_enter_map, wait_for_enter_map).

-define(state_init_distribution, state_init_distribution).

-define(state_normal_game, normal_game).

-define(HEARTBEAT_MAX_FAILED_TIME, 8).

-define(LOOP_TICKET, 1000).

-define(FCM_KICK_TIME, 3 * 3600).
-define(MIX_STATE,1). %%合体

-record(state, {
          socket, 
          account, 
          role_id, 
          ip, 
          last_heartbeat_time, 
          heartbeat_failed_time=0, 
          line, 
          last_packet_time,
          sum_packet=0,
          reg_name,
          fsm_state=?state_wait_for_authkey,
          last_fsm_state_time=0 %%最后一次状态改变时间
         }).

-define(OFFLINE_REASON_TCP_CLOSED, 0).

%% ====================================================================
%% Macro
%% ====================================================================
-define(account_name,account_name).
-define(role_name,role_name).
-define(role_bag_max_goodsid,role_bag_max_goodsid).

%%%===================================================================

start_link(ClientSocket, Line) ->
    gen_server:start_link(?MODULE, [ClientSocket, Line], [{spawn_opt, [{min_heap_size, 10*1024},{min_bin_vheap_size, 10*1024}]}]).

%%--------------------------------------------------------------------

init([ClientSocket, Line]) ->
    erlang:process_flag(trap_exit, true),
    clear_enter_map_status(),
    case inet:peername(ClientSocket) of
        {ok, {IP, _}} ->
            erlang:put(socket, ClientSocket),
            erlang:send_after(60 * 1000, erlang:self(), minute_check),
            {ok, #state{socket=ClientSocket, line=Line, ip=IP, last_packet_time=common_tool:now()}};
        {error, Reason} ->
            {stop, inet:format_error(Reason)}
    end.

%%--------------------------------------------------------------------
handle_call(login_again, _From, State) ->
    do_terminate(login_again, State),
    {stop, normal, ok,  State};

handle_call({check_real_online,CheckRoleID}, _From, State) ->
	#state{role_id=RoleID} = State,
	Reply = do_check_real_online(RoleID,CheckRoleID),
	{reply, Reply, State};

handle_call(Request, From, State) ->
    ?ERROR_MSG("~ts: ~w from ~w", ["未知的call", Request, From]),
    Reply = ok,
    {reply, Reply, State}.

handle_cast(Msg, State) ->
    ?ERROR_MSG("~ts: ~w", ["未知的cast", Msg]),
    {noreply, State}.

do_check_real_online(RoleID,CheckRoleID)->
	case erlang:get(offline_status) of
		true->
			false;
		_ ->
			CheckRoleID=:=RoleID
	end.

%%--------------------------------------------------------------------

%%@return {ok,RegName} | error
check_and_register_name(RoleID)->
	RegName = common_misc:get_role_line_process_name(RoleID),    
	case global:register_name(RegName, self()) of
		yes->
			{ok,RegName};
		no->
			error
	end.

do_login_by_wait(Unique, AccountName, RoleID, IP, Socket, State, Count)->
	timer:sleep(1000),
    do_login(Unique, AccountName, RoleID, IP, Socket, State, Count+1).

do_login(_Unique, _AccountName, _RoleID, _IP, _Socket, State, 35) ->
    do_terminate(login_again_error, State),
	{stop, normal, State};
do_login(Unique, AccountName, RoleID, IP, Socket, State, Count) ->
	case do_login_again(RoleID) of
		ok ->
			case check_and_register_name(RoleID) of
				{ok,RegName}->
            		do_login2(Unique, AccountName, RoleID, IP, Socket, State#state{reg_name=RegName});
				error->
					?DBG("brushgold,check_and_register_name fail"),
					do_login_by_wait(Unique, AccountName, RoleID, IP, Socket, State, Count)
			end;
        {error, Reason} ->
            do_terminate(Reason, State),
            {stop, normal, State}
    end.

do_login2(Unique, AccountName, RoleID, IP, Socket, State) ->
    %% 加载角色数据，修改为call的方式去直接加载了
    %%db_loader:load_role_data(AccountName, RoleID),
    set_account_name(AccountName),
    
    common_role_tracer:online(RoleID, IP),
    %% 认证成功，等待进入地图请求
    case init_fcm(AccountName,RoleID,common_config:get_agent_name()) of
        ok ->
            do_login3(Unique, AccountName, RoleID, Socket, State);
        {error, fcm_kick_off_not_enough_off_time} ->
            ?DBG("fcm_kick_off_not_enough_off_time,RoleID=~w",[RoleID]),
            do_terminate(fcm_kick_off_not_enough_off_time, State),
            {stop, normal, State};
        {ok, need_fcm, TotalOnlineTime} ->
            %% 进入游戏后多久弹出第一次防沉迷时间
            [FirstNotifyFcmTime] = common_config_dyn:find(etc, first_notify_fcm_time),
            %% 在线多就之后被防沉迷， 被防沉迷后多就才能重新上线
            [FcmKickTime] = common_config_dyn:find(etc, fcm_kick_time),
            %% 第一次防沉迷的消息
            erlang:send_after(FirstNotifyFcmTime * 1000, erlang:self(), {notify_fcm, TotalOnlineTime + FirstNotifyFcmTime}),
            erlang:send_after((FcmKickTime - TotalOnlineTime) * 1000, erlang:self(), fcm_kick_time),
            
            do_login3(Unique, AccountName, RoleID, Socket, State)
    end.

do_login3(Unique, AccountName, RoleID, Socket, State)->
    ClientSocket = State#state.socket,
    prim_inet:async_recv(Socket, 0, -1),
    #state{ip = IP, line = Line} = State,
	RolePid = global:whereis_name(common_tool:int_to_atom(RoleID)),
    if
		RolePid == undefined ->
			AccountData = do_handle_account_data(RoleID),
			#r_account_full_info{role_detail=RoleDetail} = AccountData,
		    #p_role{base=#p_role_base{role_name=RoleName}} = RoleDetail,
		    set_role_name(RoleName),
		    case catch reply_after_auth_succ(ClientSocket, Unique, RoleID, AccountData) of
		        ok ->
		            NewState = State#state{account=AccountName, role_id=RoleID, fsm_state=?state_wait_for_enter_map},
		            {noreply, NewState};
		        {error,Reason} ->
		            do_terminate(Reason, State),
		            {stop, normal, State}
		    end;
		true ->
			{BagDicts, RoleDetail} = gen_server:call(RolePid, {login_again, RoleID, self(), Line, IP}),
			BagBasicList = lists:foldl(fun
				({{role_bag_list, _}, Basic}, Acc) ->
					 Acc ++ [Basic2||{_ID, Basic2}<-Basic];
				({{role_depository_list, _}, Basic}, Acc) ->
					 Acc ++ [Basic2||{_ID, Basic2}<-Basic];
				(_, Acc) ->
					 Acc
			end, [], BagDicts),
			Bags = get_bag_contents(RoleID, BagBasicList, BagDicts),
			set_role_name(RoleDetail#p_role.base#p_role_base.role_name),
			FamilyID = RoleDetail#p_role.base#p_role_base.family_id,
			[FamilyInfo] = case FamilyID > 0 of
				true ->
					db:dirty_read(?DB_FAMILY, FamilyID);
				false ->
					[undefined]
			end,
            DataRecord = #m_auth_key_toc{succ=true, bags=Bags, role_details=RoleDetail, family=FamilyInfo, server_time=common_tool:now()},
            put(role_details, RoleDetail),
			mgeeg_packet:send(ClientSocket, Unique, ?AUTH, ?AUTH_KEY, DataRecord),
            case common_config:is_client_stat_open() of
                true->
                    %%发送统计开关的消息
                    RecordStat = #m_stat_config_toc{is_open=true},
                    mgeeg_packet:send(ClientSocket, Unique, ?STAT, ?STAT_CONFIG, RecordStat);
                _ ->
                    ignore
            end,
			NewState = State#state{account=AccountName, role_id=RoleID, fsm_state=?state_wait_for_enter_map},
			{noreply, NewState}
	end.

%%@return {IsCacheData,AccountData}
do_handle_account_data(RoleID) ->
	AccountData = mgeed_persistent:load_account_data(RoleID),
	#r_account_full_info{role_id=RoleID, role_detail=RoleDetail, map_ext_info=MapExtInfoOld,
						 pet_process_info=PetProcessInfo, family_info=FamilyInfo1} = AccountData,
    RoleDetail2 = do_role_detail_exception_process(RoleDetail),
    
    #p_role{ext=RoleExt, fight=RoleFight,attr=RoleAttr, base=RoleBase} = RoleDetail2,
    #p_role_attr{level=Level} = RoleAttr,
	#p_role_base{family_id=FamilyID} = RoleBase,
	
    case FamilyID > 0 andalso FamilyInfo1 =:= undefined of
        true ->
            case db:dirty_read(?DB_FAMILY, FamilyID) of
                [FamilyInfo2] -> next;
                _ -> FamilyInfo2 = FamilyInfo1
            end;
        false ->
            FamilyInfo2 = FamilyInfo1
    end,
    
    OffLineTime = {RoleExt#p_role_ext.last_offline_time div 1000000, 
                   RoleExt#p_role_ext.last_offline_time rem 1000000, 0},
    {OffLineDate, _} = calendar:now_to_local_time(OffLineTime),
    Now = common_tool:now(),
    NowDate = common_time:time_to_date(Now),
    RoleFight2 = init_role_energy(RoleFight, Now, NowDate),
    RoleDetail3 =
        case NowDate =:= OffLineDate of
            true ->
                RoleDetail2#p_role{fight=RoleFight2};
            false ->
                common_letter:init_role_letter(RoleID),
                RoleAttr2 = RoleAttr#p_role_attr{active_points=0},
                RoleDetail2#p_role{fight=RoleFight2, attr=RoleAttr2}
        end,
    case (RoleDetail2#p_role.base)#p_role_base.team_id =/= 0 of
        true ->
            RoleTeamInfo = #r_role_team{role_id = RoleID,team_id = (RoleDetail3#p_role.base)#p_role_base.team_id};
        _ ->
            RoleTeamInfo = #r_role_team{role_id = RoleID}
    end,
    RoleMapInfo     = get_role_map_info_by_role_detail(RoleDetail3,PetProcessInfo),
    RoleMapInfo2    = fix_role_map_info(RoleMapInfo,MapExtInfoOld#r_role_map_ext.vip),
    MapExtInfo2     = fix_map_ext_info(MapExtInfoOld,Level),
    PetProcessInfo1 = init_pet_process_info(PetProcessInfo, RoleExt#p_role_ext.last_offline_time, Now),
    AccountData#r_account_full_info{
            role_detail      = RoleDetail3, 
            role_map_info    = RoleMapInfo2, 
            team_info        = RoleTeamInfo,
            family_info      = FamilyInfo2,
            map_ext_info     = MapExtInfo2,
            pet_process_info = PetProcessInfo1
    }.

%% OffLineTime上一次下线时间，LoginTime本次登录时间
%% 这里做的逻辑包括：
%%      1.宠物下线时，每10min减一定的亲密度值
init_pet_process_info(PetProcessInfo, _LastOffLineTime, _LoginTime) ->
    PetInfoRecs    = PetProcessInfo#r_pet_process_info.pet_info,
    PetBagRec      = PetProcessInfo#r_pet_process_info.pet_bag,
    PetIdNameRecs  = PetBagRec#p_role_pet_bag.pets,
    NewPetsInfo      = PetInfoRecs,
    NewPetIdNameRecs = PetIdNameRecs,
    PetProcessInfo#r_pet_process_info{
        pet_info = NewPetsInfo,
        pet_bag = PetBagRec#p_role_pet_bag{pets = NewPetIdNameRecs}
    }.

do_handle_data(Socket, IP, DataBin, State, Fcm) when Fcm =:= ?state_wait_for_authkey ->
    case do_auth_key(DataBin) of
        {error, Unique, Reason} ->
            ClientSocket = State#state.socket,
            reply_after_auth_failed(ClientSocket, Unique, Reason),
            do_terminate(error_auth_key, State),
			{stop, normal, State#state{fsm_state=?state_wait_for_enter_map}};
        {ok, Unique, AccountName, RoleID} ->
            do_login(Unique, AccountName, RoleID, IP, Socket, State, 1)
    end;
do_handle_data(Socket, _IP, DataBin, State, Fcm) when Fcm =:= ?state_wait_for_enter_map ->
    #state{role_id=RoleID, line=Line, ip=IP} = State,
	RolePid = global:whereis_name(common_tool:int_to_atom(RoleID)),
    {Unique, Module, Method, DataRecord} = mgeeg_packet:unpack(DataBin),
    case Module =:= ?MAP andalso Method =:= ?MAP_ENTER of
        true when RolePid == undefined ->
            %%进入地图/然后在world中注册角色进程
            map_socket(Line, RoleID, Socket, self()),
            case do_enter_map(Unique, self(), DataRecord, RoleID, Line, IP) of
                {ok,MapID} ->
                    %%注册玩家进程完成，等待确认进入地图
					erlang:put(cur_map_id, MapID),
                    NewState = State#state{fsm_state=?state_init_distribution},
                    {noreply, NewState};
                {error, cant_get_role_map} ->
                    do_terminate(mgeem_router_not_found, State),
                    {stop, normal, State};
                {error,Reason} ->
                    do_terminate(Reason, State),
                    {stop, normal, State}
            end;
		true ->
			put(role_pid, RolePid),
			RoleDetail = erase(role_details),
			add_online(RoleDetail, IP, Line),
			map_socket(Line, RoleID, Socket, self()),
			[MapID, MapPID] = gen_server:call(RolePid, {get, [map_id, map_pid]}),
			erlang:put(cur_map_id, MapID),
			MapPID ! {mod_map_actor, {login_again, RoleID, self(), Line}},
			%% 通知聊天
			#p_role{attr= RoleAttr, base=RoleBase, ext=RoleExt} = RoleDetail,
		    RoleChatData = get_role_chat_data(RoleID, RoleBase, RoleAttr, RoleExt),
		    catch global:send(mgeec_client_manager, {online, self(), RoleID, RoleChatData}),
            NewState = State#state{fsm_state=?state_init_distribution},
            {noreply, NewState};
        false ->
            {noreply, State}
    end;
do_handle_data(Socket, _IP, DataBin, State, Fcm) when Fcm =:= ?state_normal_game ->
    #state{sum_packet=SumPacket, line=Line, role_id=RoleID, socket=_Socket} = State,
    {Unique, Module, Method, Record} = mgeeg_packet:unpack(DataBin),
    prim_inet:async_recv(Socket, 0, -1),
    case Module =:= ?CHAT of
        true ->
            case erlang:get(chat_pid) of
                undefined ->
                    %% 聊天进程尚未初始化好，先缓存聊天请求
                    case erlang:get(chat_cache) of
                        undefined ->
                            erlang:put(chat_cache, [{Method, Module, RoleID, Record, erlang:self(), Unique}]);
                        List ->
                            erlang:put(chat_cache, [{Method, Module, RoleID, Record, erlang:self(), Unique} | List])
                    end,
                    ok;
                ChatPID ->
                    ChatPID ! {Method, Module, RoleID, Record, erlang:self(), Unique}
            end;
        false ->
            %% 当前是否正在切换地图
            case is_enter_map_status() of
                true ->
                    case Module =:= ?MAP andalso (Method =:= ?MAP_ENTER andalso Method =:= ?MAP_TRANSFER)  of
                        true ->
                            ignore;
                        false ->
                            mgeeg_router:router({Unique, Module, Method, Record, RoleID, self(), Line})
                    end;
                false ->
                    case Module =:= ?MAP andalso (Method =:= ?MAP_ENTER andalso Method =:= ?MAP_TRANSFER) of
                        true ->
                            set_enter_map_status(),                
                            mgeeg_router:router({Unique, Module, Method, Record, RoleID, self(), Line});
                        false ->
                            mgeeg_router:router({Unique, Module, Method, Record, RoleID, self(), Line}),
							case erlang:is_record(Record, m_map_enter_tos) of
								true ->
									erlang:put(cur_map_id,Record#m_map_enter_tos.map_id);
								false ->
									ignore
							end
                    end
            end
    end,
    NewState = State#state{last_heartbeat_time=common_tool:now(), 
                           heartbeat_failed_time=0, sum_packet=SumPacket+1},
	mgeeg_hook:record_packet_detail(Method,Record),
    {noreply, NewState}.

is_enter_map_status() ->
    erlang:get(is_enter_map).
set_enter_map_status() ->
    erlang:put(is_enter_map, true).
clear_enter_map_status() ->
    erlang:put(is_enter_map, false).

%% 处理防沉迷请求结果,httpc发起的
handle_info({http, {_, FcmHttpResult}}, #state{account=AccountName, socket=Socket} = State) ->
    ?ERROR_MSG("~p", [FcmHttpResult]),
    case FcmHttpResult of
        {Succ, _, Result} ->
            case Succ of
                {_, 200, "OK"} ->
                    Result2 = common_tool:to_integer(Result),
                    case common_fcm:get_fcm_validation_tip(Result2) of
                        true ->
                            %% 通知客户端结果
                            R = #m_system_set_fcm_toc{succ=true},
                            common_fcm:set_account_fcm(AccountName),
                            ok;
                        {false, Reason} ->
                            R = #m_system_set_fcm_toc{succ=false, reason=Reason}
                    end,
                    mgeeg_packet:packet_encode_send(Socket, ?DEFAULT_UNIQUE, ?SYSTEM,
                                                        ?SYSTEM_SET_FCM, R),
                    ok;
                _ ->
                    ?ERROR_MSG("~ts:~p", ["请求平台验证防沉迷出错", Succ]),
                    R = #m_system_set_fcm_toc{succ=false, reason=?_LANG_FCM_SYSTEM_ERROR_WHEN_REQUEST_PLATFORM},
                    mgeeg_packet:packet_encode_send(Socket, ?DEFAULT_UNIQUE, ?SYSTEM,
                                                        ?SYSTEM_SET_FCM, R)
            end;
        _ ->
            R = #m_system_set_fcm_toc{succ=false, reason=?_LANG_FCM_SYSTEM_ERROR_WHEN_REQUEST_PLATFORM},
            mgeeg_packet:packet_encode_send(Socket, ?DEFAULT_UNIQUE, ?SYSTEM,
                                                ?SYSTEM_SET_FCM, R)
    end,
    {noreply, State};

handle_info({inet_async, Socket, _Ref, {ok, Data}}, #state{ip=IP, fsm_state=FSM} = State) ->
    Rtn = do_handle_data(Socket, IP, Data, State, FSM),    
    Rtn;
handle_info({inet_async, _Socket, _Ref, {error, closed}}, State) ->
%%     case State#state.fsm_state of
%%         ?state_normal_game ->
%%             erlang:put(offline_status, true),
%%             erlang:send_after(10 * 1000, erlang:self(), real_offline),
%%             {noreply, State};
%%         _ ->
%%             
%%     end
	do_terminate(tcp_closed, State),
    {stop, normal, State};
    
handle_info({inet_async, _Socket, _Ref, {error, Reason}}, State) ->
    ?ERROR_MSG("~ts:~w", ["Socket出错", Reason]),
    do_terminate(tcp_error, State),
    {stop, normal, State};

handle_info(real_offline, State) ->
    do_terminate(tcp_closed, State),
    {stop, normal, State};

handle_info({notify_fcm, TotalOnlineTime}, #state{account=AccountName, socket=Socket} = State) ->
    case db:dirty_read(?DB_FCM_DATA, common_tool:to_binary(AccountName)) of
        [#r_fcm_data{passed=true}] ->
            ignore;
        _ ->
			case common_config:is_fcm_open() of
				false ->
					ignore;
				true ->
					[NotifyIntervalTime] = common_config_dyn:find(etc, notify_fcm_interval_time),
					[FcmKickTime] = common_config_dyn:find(etc, fcm_kick_time),
					erlang:send_after(NotifyIntervalTime * 1000, erlang:self(), {notify_fcm, TotalOnlineTime + NotifyIntervalTime}),
					DataRecord = #m_system_fcm_toc{total_time=TotalOnlineTime, info="", remain_time=FcmKickTime-TotalOnlineTime},
					mgeeg_packet:packet_encode_send(Socket, ?DEFAULT_UNIQUE, ?SYSTEM, ?SYSTEM_FCM, DataRecord)
			end
    end,
    {noreply, State};        

handle_info(fcm_kick_time, #state{account=AccountName} = State) ->
    %%判断玩家是否通过了防沉迷，没有则直接T下线
    [FcmData] = db:dirty_read(?DB_FCM_DATA, common_tool:to_binary(AccountName)),
    #r_fcm_data{passed=Passed} = FcmData,
    %%踢玩家下线时先判断防沉迷是否已经打开了
    case Passed orelse common_config:is_fcm_open() =:= false of
        true ->
            {noreply, State};
        false ->            
            do_terminate(fcm_kick_off, State),
            {stop, normal, State}
    end;

handle_info(loop, State) ->
    #state{role_id=RoleID, last_packet_time=LastPacketTime, last_heartbeat_time=LastHeartbeatTime} = State,
    %% 一定时间内如果收不到玩家的心跳包，则直接踢掉玩家
	Now = common_tool:now(),
    case Now - LastHeartbeatTime > 60 of
		true ->
			do_terminate(no_heartbeat, State),
			{stop, normal, State};
		false ->
			DifTime = Now - LastPacketTime,
			case DifTime > 10  of
				true ->
					case mgeeg_hook:legal_all_packet_speed(RoleID,DifTime,State#state.sum_packet) =:= true
							 andalso mgeeg_hook:legal_method_packet_speed(RoleID,DifTime) =:= true of
                        true ->
							mgeeg_hook:clear_method_packet_detail(),
                            erlang:send_after(?LOOP_TICKET, self(), loop),
                            {noreply, State#state{sum_packet=0, last_packet_time=Now}};
						false ->
                            do_terminate(too_many_packet, State),
                            {stop, normal, State}
                    end;
                false ->
                    erlang:send_after(?LOOP_TICKET, self(), loop),
                    {noreply, State}
            end
    end;

handle_info(minute_check, State) ->
    case State of
        #state{fsm_state = ?state_wait_for_authkey} ->
            do_terminate(admin_kick, State),
            {stop, normal, State};
        _ -> 
            %%erlang:send_after(600 * 1000, erlang:self(), minute_check),
            %%do_minute_dump(),
            {noreply, State}
    end;

handle_info({message, Unique, Module, Method, DataRecord}, #state{socket=Socket} = State) ->
    case erlang:get(offline_status) of
        true ->
            {noreply, State};
        _ ->
            %%?DEBUG("~w", [{message, Unique, Module, Method, DataRecord}]),
            case catch  mgeeg_packet:packet_encode(Unique, Module, Method, DataRecord) of
                {'EXIT', Error} ->
                    ?ERROR_MSG("~ts:~w ~w", ["编码数据包出错", Error, {Module, Method, DataRecord}]),
                    {noreply, State};
                Bin ->
                    case erlang:is_port(Socket) of
                        true ->
                            erlang:port_command(Socket, Bin),
                            {noreply, State};
                        false ->
                            do_terminate(tcp_closed, State),
                            {stop, normal, State}
                    end
            end
    end;

handle_info({binary, Bin},  #state{socket=Socket} = State) ->
    case erlang:get(offline_status) of
        true ->
            {noreply, State};
        _ ->
            case erlang:is_port(Socket) of
                true ->
                    erlang:port_command(Socket, Bin),
                    {noreply, State};
                false ->
                    do_terminate(tcp_error, State),
                    {stop, normal, State}
            end
    end;

handle_info({binaries, Bins},  #state{socket=Socket} = State) ->
    case erlang:get(offline_status) of
        true ->
            {noreply, State};
        _ ->
            case erlang:is_port(Socket) of
                true ->
                    [begin
                         erlang:port_command(Socket, Bin)
                     end || Bin <- Bins],
                    {noreply, State};
                false ->
                    do_terminate(tcp_error, State),
                    {stop, normal, State}
            end
    end;

handle_info({inet_reply, _Sock, ok}, State) ->
    {noreply, State};

handle_info({inet_reply, _Sock, Result}, State) ->
    ?ERROR_MSG("~ts:~p", ["socket发送结果", Result]),
    do_terminate(tcp_send_error, State),
    {stop, normal, State};

handle_info({chat_process, PID, ChannelList}, State) ->
    SuccDataRecord =  #m_chat_auth_toc{succ=true, channel_list=ChannelList, black_list=[], gm_auth=[]},
    Socket = erlang:get(socket),
    case catch mgeeg_packet:packet_encode(?DEFAULT_UNIQUE, ?CHAT, ?CHAT_AUTH, SuccDataRecord) of
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w ~w", ["编码数据包出错", Error, {?CHAT, ?CHAT_AUTH, SuccDataRecord}]);
        Bin ->
            case erlang:is_port(Socket) of
                true ->
                    erlang:port_command(Socket, Bin, [force]);
                false ->
                    ignore
            end
    end,
    erlang:put(chat_pid, PID),
    case erlang:get(chat_cache) of
        undefined ->
            ingnore;
        List ->
            lists:foreach(
              fun(M) ->
                      PID ! M
              end, List)
    end,
    {noreply, State};

handle_info(start, #state{socket=Socket} = State) ->
    prim_inet:async_recv(Socket, 0, -1),
    {noreply, State};

handle_info({router_to_map, Msg}, State) ->
    case erlang:get(map_pid) of
        undefined ->
			common_misc:print_pay_error_msg("map_pid没找到",Msg),
            ignore;
        PID ->
            PID ! Msg
    end,
    {noreply, State};

handle_info({sure_enter_map_need_change_pos, MapPID}, State) ->
    case erlang:get(map_pid) of
        undefined ->  
            erlang:put(map_pid, MapPID),
            prim_inet:async_recv(State#state.socket, 0, -1),
            case common_config:is_debug() of
                true ->
                    ok;
                false ->
                    erlang:send_after(?LOOP_TICKET, self(), loop)
            end;
        _ ->
            erlang:put(map_pid, MapPID),
            prim_inet:async_recv(State#state.socket, 0, -1),
            ignore
    end,
    clear_enter_map_status(),
    case State#state.fsm_state =:= ?state_init_distribution of
        true ->            
            NewState = State#state{fsm_state=?state_normal_game, last_heartbeat_time=common_tool:now(), last_packet_time=common_tool:now()},
            {noreply, NewState};
        false ->
            {noreply, State}
    end;

handle_info({sure_enter_map, MapPID}, State) ->
    case erlang:get(map_pid) of
        undefined ->        
%%             global:send(global_gateway_server, {new_client, State#state.role_id, erlang:self()}),
            erlang:put(map_pid, MapPID),
            prim_inet:async_recv(State#state.socket, 0, -1),
             case common_config:is_debug() of
                true ->
                    ok;
                false ->
                    erlang:send_after(?LOOP_TICKET, self(), loop)
            end;
        _ ->
            erlang:put(map_pid, MapPID),
            prim_inet:async_recv(State#state.socket, 0, -1),
            ignore
    end,
    clear_enter_map_status(),
    case State#state.fsm_state =:= ?state_init_distribution of
        true ->            
            NewState = State#state{fsm_state=?state_normal_game, last_heartbeat_time=common_tool:now(), last_packet_time=common_tool:now()},
            {noreply, NewState};
        false ->
            {noreply, State}
    end;

handle_info({enter_map_failed, _}, State) ->
    ?ERROR_MSG("~ts", ["玩家进入地图失败，原因：地图无法启动"]),
    do_terminate(enter_map_failed, State),
    {stop, normal, State};

%%后台的踢人接口
handle_info({kick_by_admin},State)->
    do_terminate(admin_kick,State),
    {stop,normal,State};

handle_info({'EXIT', _, role_map_process_not_found}, State) ->
    do_terminate(role_map_process_not_found, State),
    {stop, normal, State};

handle_info({'EXIT', _, Reason}, State) ->
    do_terminate(Reason, State),
    {stop, normal, State};
handle_info({debug, Unique, Module, Method, Record}, State) ->
    RoleID = State#state.role_id,
    Line = State#state.line,
    mgeeg_router:router({Unique, Module, Method, Record, RoleID, self(), Line}),
    {noreply, State};

handle_info(Info, State) ->
    ?ERROR_MSG("~ts:~w", ["未知的消息", Info]),
    {noreply, State}.

%%--------------------------------------------------------------------

terminate(Reason, State) ->
    case get(already_do_terminate) of
        true ->
            ignore;
        _ ->
            do_terminate(Reason, State)
    end,
    ok.

do_terminate(Reason, State) ->
    #state{socket=Socket, role_id=RoleID, reg_name=RegName, ip=IP, line=Line, fsm_state=FsmState} = State,
    Account = get_account_name(),
    case RegName of
        undefined ->
            ignore;
        _ ->
            global:unregister_name(RegName)
    end,       
    case Account of
        undefined ->
            ignore;
		_ ->
            RoleName = get_role_name(),
            case is_integer(RoleID) andalso RoleID>0 andalso RoleName=/=undefined of
                true->
                    %% 通知聊天
                    catch global:send(mgeec_client_manager, {offline, RoleID, RoleName});
                _ ->
                    ignore
            end
    end,
    common_role_tracer:offline(RoleID, Reason),
	
    case Reason =:= tcp_closed of
        true ->
            case Account of
                undefined ->
                    ok;
                _ ->
                    common_general_log_server:log_user_offline(#r_user_offline{account_name=Account, 
                                                                               offline_time=common_tool:now(),
                                                                               offline_reason_no=?OFFLINE_REASON_TCP_CLOSED})
            end;
        false ->
            case  common_line:get_exit_info(Reason) of
                {_, {ErrorNo, ErrorInfo}} ->
                    case ErrorNo of
                        10017 ->
                            [#r_fcm_data{offline_time=OffLineTime}] = db:dirty_read(?DB_FCM_DATA, common_tool:to_binary(Account)),
                            OffLineTimeTotal = common_tool:now() - OffLineTime,
                            NeedTime = 5 * 3600 - OffLineTimeTotal,
                            Hour = NeedTime div 3600,
                            Min = (NeedTime rem 3600) div 60,
                            ErrorInfo2 = io_lib:format("您的累计下线时间不满5小时，为了保证您能正常游戏，请您稍后登陆。还需要等待~p时~p分", [Hour, Min]);
                        _ ->
                            ErrorInfo2 = ErrorInfo
                    end,
                    %% 通知客户端退出的原因
                    kick_role(ErrorNo, ErrorInfo2, Socket),
                    case Account of
                        undefined ->
                            ignore;
                        _ ->
                            common_general_log_server:log_user_offline(#r_user_offline{account_name=Account, 
                                                                                       offline_time=common_tool:now(),
                                                                                       offline_reason_no=ErrorNo})
                    end;
                false ->
                    ?ERROR_MSG("网关账号退出原因异常:~w ~w", [Reason, erlang:get_stacktrace()]),
                    ?ERROR_MSG("网关玩家退出原因异常:RoleID=~w,Line=~w,State=~w", [RoleID,Line,State])
            end            
    end,    
    %% 等待1秒钟，尽可能的让socket中的数据发送完成，socket不用关闭了，本进程退出后会自动关闭
    timer:sleep(1000),
	if 
		Reason == login_again ->
			ignore;
		FsmState == ?state_normal_game ->
			remove_online(RoleID),
			NameU = mgeeg_unicast:process_name(Line),
			case global:whereis_name(NameU) of
				undefined ->
					ignore;
				PIDU ->
					PIDU ! {erase, RoleID, self()}
			end,
			mgeeg_role_sock_map ! {erase, RoleID, self()};       
		FsmState == ?state_wait_for_handshaking ->
			?ERROR_MSG("~ts IP=~p", ["退出时尚未发出握手请求", IP]),
			ok;
		FsmState == ?state_wait_for_authkey ->
			?ERROR_MSG("~ts IP=~p", ["退出时尚未发出auth_key请求", IP]),
			ok;
		FsmState == ?state_wait_for_enter_map ->
			?ERROR_MSG("~ts RoleID=~w", ["退出时尚未发出enter_map请求",RoleID]),
			ok;
		FsmState == ?state_init_distribution ->
			remove_online(RoleID),
			?ERROR_MSG("~ts", ["退出时已经收到enter_map请求，但是没有分线进程还没确认进入地图，可能是进入地图时出错"]);
		true ->
			ignore
	end,
    put(already_do_terminate, true),
    ok.

%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%==================================================================

%% 验证key
do_auth_key(Bin) ->
    case mgeeg_packet:unpack(Bin) of
        {Unique, _Module, _Method, #m_auth_key_tos{account_name=Account, key=Key, role_id=RoleID}}->
			case gen_server:call({global, mgeel_key_server}, 
                                 {auth_key,  erlang:list_to_binary(Account), RoleID, Key}) of
                ok ->
                    {ok, Unique, common_tool:to_binary(Account), RoleID};
                {error, Msg} ->
                    {error, Unique, Msg}
            end;
        _Other ->
            {error, ?DEFAULT_UNIQUE, ?_LANG_AUTH_WRONG_PACKET}
    end.

%%获取玩家背包内容
get_bag_contents(RoleID,BagBasicList,BagsList)->
    [  begin
           Key = {?ROLE_BAG,RoleID,BagID},
           case lists:keyfind(Key, 1, BagsList) of
               {{_, RoleID, BagID},{_Content,OutUseTime,_UsedPositionList,GoodsList, _}}->
                   %%主背包
                   #p_bag_content{bag_id=BagID, goods= GoodsList, rows=Rows, columns= Columns, typeid=BagTypeID,grid_number=GridNumber};
               false->
                   %%扩展背包
                   #p_bag_content{bag_id=BagID,goods = [],rows = Rows,columns = Columns,
                                  typeid = BagTypeID,grid_number = GridNumber}
           end
       end||{BagID,BagTypeID,OutUseTime,Rows,Columns,GridNumber} <-BagBasicList, BagID<5 ].


%%帐号认证成功之后发给客户端的信息
reply_after_auth_succ(ClientSocket, Unique, RoleID, AccountFullInfo1)->
    #r_account_full_info{role_id=RoleID,role_detail=RoleDetail3,family_info=FamilyInfo} = AccountFullInfo1,
    #p_role{attr=RoleAttr} = RoleDetail3,
    
    case common_bag2:init_role_bag_info(RoleID,RoleAttr) of
        {ok,{BagBasicList,BagsListInfo1}}->
            
            AccountFullInfo2 = AccountFullInfo1#r_account_full_info{bag=BagsListInfo1,bag_dicts=undefined},
            [{{?role_bag_max_goodsid,_RoleID},_} | BagsList] = BagsListInfo1,
            set_account_full_info(AccountFullInfo2),
            Bags = get_bag_contents(RoleID, BagBasicList, BagsList),
            DataRecord= #m_auth_key_toc{succ=true, bags=Bags, role_details=RoleDetail3, family=FamilyInfo, server_time=common_tool:now()},
			mgeeg_packet:send(ClientSocket, Unique, ?AUTH, ?AUTH_KEY, DataRecord),
            
            case common_config:is_client_stat_open() of
                true->
                    %%发送统计开关的消息
                    RecordStat = #m_stat_config_toc{is_open=true},
                    mgeeg_packet:send(ClientSocket, Unique, ?STAT, ?STAT_CONFIG, RecordStat);
                _ ->
                    ignore
            end,
            ok;
        {error, Reason} ->
            ?ERROR_MSG("玩家背包数据异常，RoleID=~w,Reason=~w", [RoleID, Reason]),
            {error,bag_data_error}
    end.
 


%%帐号认证失败，发给客户端的信息
reply_after_auth_failed(ClientSocket, Unique, Reason) ->
    Rtn = #m_auth_key_toc{succ=false, reason=Reason},
    mgeeg_packet:packet_encode_send(ClientSocket, Unique, ?AUTH, ?AUTH_KEY, Rtn).


%%映射socket
map_socket(Line, RoleID, ClientSock, PID)->
    NameU = mgeeg_unicast:process_name(Line),
    global:send(NameU, {role, RoleID, PID, ClientSock}),
    mgeeg_role_sock_map ! {role, RoleID, PID, ClientSock}.



init_role_energy(RoleFight, Now, NowDate) when is_record(RoleFight,p_role_fight)->
    #p_role_fight{role_id=RoleID, energy=Energy, energy_remain=EnergyRemain, time_reset_energy=TimeReset} = RoleFight,
    NowDays = calendar:date_to_gregorian_days(NowDate),
    ResetDate = common_time:time_to_date(TimeReset),
    ResetDays = calendar:date_to_gregorian_days(ResetDate),

    case NowDate =:= ResetDate of
        true ->
            RoleFight;
        _ ->
            EnergyRemain2 = Energy + EnergyRemain + (NowDays-ResetDays-1) * ?DEFAULT_ENERGY,
            case EnergyRemain2 >= ?MAX_REMAIN_ENERGY of
                true ->
                    EnergyRemain3 = ?MAX_REMAIN_ENERGY;
                _ ->
                    EnergyRemain3 = EnergyRemain2
            end,

            RoleFight2 = RoleFight#p_role_fight{energy=?DEFAULT_ENERGY, energy_remain=EnergyRemain3, time_reset_energy=Now},
            db:dirty_write(?DB_ROLE_FIGHT, RoleFight2),
            
            ChangeAttList = [#p_role_attr_change{change_type=?ROLE_ENERGY_CHANGE, new_value=?DEFAULT_ENERGY},
                             #p_role_attr_change{change_type=?ROLE_ENERGY_REMAIN_CHANGE, new_value=EnergyRemain3}],
            common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList),
            RoleFight2
    end.


get_role_map_info_by_role_detail(RoleDetail,PetProcessInfo) ->
    #p_role{
        base  = RoleBase, 
        fight = RoleFight, 
        pos   = RolePos, 
        attr  = RoleAttr
    } = RoleDetail,
    #p_role_base{
        role_id         = RoleID, 
        role_name       = RoleName, 
        faction_id      = FactionID, 
        team_id         = TeamID, 
        family_id       = FamilyID,
        family_name     = FamilyName, 
        max_hp          = MaxHP, 
        max_mp          = MaxMP, 
        move_speed      = MoveSpeed, 
        cur_title       = CurTitle,
        cur_title_color = Color, 
        pk_points       = PkPoint, 
        if_gray_name    = IfGrayName, 
        buffs           = Buffs, 
        status          = State
    } = RoleBase,
    #p_role_attr{
        level           = Level, 
        skin            = Skin, 
        show_cloth      = ShowCloth, 
        jingjie         = Jingjie,
        juewei          = Juewei
    } = RoleAttr,
    #p_role_pos{
        pos = Pos
    } = RolePos,
    #p_role_fight{
        hp = HP, 
        mp = MP,
        nuqi = Nuqi
    } = RoleFight,
	#r_pet_process_info{
        pet_bag = #p_role_pet_bag{
            summoned_pet_id = SummonedPetID,
            pets            = Pets
    }} = PetProcessInfo,
	SummonedPetTypeID = case lists:keyfind(SummonedPetID, #p_pet_id_name.pet_id, Pets) of
    	false -> 
            0;
    	Pet -> 
            Pet#p_pet_id_name.type_id
    end,
    %%拼凑玩家在地图中的信息
    #p_map_role{
        role_id             = RoleID, 
        role_name           = RoleName,
        faction_id          = FactionID,
        cur_title           = CurTitle , 
        cur_title_color     = Color, 
        family_id           = FamilyID,
        family_name         = FamilyName,
        pos                 = Pos, 
        hp                  = HP, 
        max_hp              = MaxHP,
        mp                  = MP, 
        max_mp              = MaxMP, 
        skin                = Skin, 
        move_speed          = MoveSpeed, 
        team_id             = TeamID, 
        level               = Level, 
        pk_point            = PkPoint, 
        gray_name           = IfGrayName,
        state_buffs         = Buffs, 
        state               = State, 
        show_cloth          = ShowCloth,
        sex                 = RoleBase#p_role_base.sex, 
        category            = RoleAttr#p_role_attr.category,
        summoned_pet_id     = SummonedPetID,
        summoned_pet_typeid = SummonedPetTypeID,
        jingjie             = Jingjie, 
        qq_yvip             = mod_map_actor:get_map_qq_yvip(RoleID),
        nuqi                = Nuqi,
        juewei              = Juewei
    }.

%%是否普通地图（非副本地图）
is_normal_map(MapID) when is_integer(MapID)->
    Idx = MapID rem 10000 div 1000,
    Idx >0;
is_normal_map(_MapID) ->
    false.

%%在分布式系统中初始化角色信息：进入地图/注册world role进程
do_enter_map(Unique, PID, _DataRecord, RoleID, Line, ClientIP)->
    AccountFullInfo = #r_account_full_info{
		role_detail	  = RoleDetail, 
		role_map_info = RoleMapInfo
	} = erase_account_full_info(),
    #p_role{attr= RoleAttr, base=RoleBase, ext=RoleExt, pos=RolePos} = RoleDetail,
    #p_role_pos{map_id=MapID, map_process_name=MapName1} = RolePos,
    
	
	case mgeer_role:start(RoleID, AccountFullInfo, PID, Line, ClientIP) of
	{_, RolePid} when is_pid(RolePid) ->
		put(role_pid, RolePid),
		%%统计玩家进入游戏窗口
	    common_admin_hook:hook({enter_flash_game, RoleID,ClientIP}),
	    add_online(RoleDetail, ClientIP, Line),
		MapName2 = case is_normal_map(MapID) of
	        true when not ?IS_SOLO_FB(MapID) -> %%防止在副本中退出可能导致进错地图
	            common_map:get_common_map_name(MapID);
	        _ when ?IS_SOLO_FB(MapID) ->
	            mgeer_role:proc_name(RoleID);
			_ ->
				MapName1
	    end,
		
	    do_send_to_map(Unique, PID, RoleMapInfo, Line, MapName2),
	    
	    %% 通知聊天
	    RoleChatData = get_role_chat_data(RoleID,RoleBase,RoleAttr,RoleExt),
	    catch global:send(mgeec_client_manager, {online, PID, RoleID, RoleChatData}),
	    {ok,MapID};
	_ ->
		{error, cant_start_role_process}
	end.

get_role_chat_data(RoleID,RoleBase,RoleAttr,RoleExt)->
    #p_role_base{role_name=RoleName,faction_id=FactionId,family_id=FamilyId,team_id=TeamId,sex=Sex,head=Head} = RoleBase,
    #p_role_attr{office_name=OfficeName,level=Level} = RoleAttr,
    #p_role_ext{signature=Signature} = RoleExt,
    #r_role_chat_data{role_id=RoleID,role_name=RoleName,faction_id=FactionId,
                      family_id=FamilyId,team_id=TeamId,sex=Sex,level=Level,
                      office_name=OfficeName,head=Head,signature=Signature}.

%%发送进入地图的消息
do_send_to_map(Unique, PID, RoleMapInfo, Line, MapName) when is_record(RoleMapInfo, p_map_role)->
    Info = {first_enter, {Unique, PID, RoleMapInfo, Line}},
    case global:whereis_name(MapName) of
        MapPid when is_pid(MapPid)->
            MapPid ! Info,
            MapPid;
        undefined->
%%             FactionID = RoleMapInfo#p_map_role.faction_id,
%%             MapID = 10000 + FactionID * 1000, %%太平村地图ID
            HomeCityMapName = common_misc:get_map_name(10250),
            global:send(HomeCityMapName, Info)
    end.

%% 初始化防沉迷信息
init_fcm(_AccountNameTmp,_RoleID,"qq") ->
    ok;
init_fcm(AccountNameTmp,RoleID,_Agent) ->
    AccountName = common_tool:to_binary(AccountNameTmp),
    Now = common_tool:now(), 
	erlang:put(last_record_fcm_time, Now),
	case db:dirty_read(?DB_FCM_DATA, AccountName) of
		[] ->
			db:dirty_write(?DB_FCM_DATA, #r_fcm_data{account=AccountName}),
			ok;
		[#r_fcm_data{offline_time=OffLineTimeFcm, passed=Passed, total_online_time=TotalOnlineTime} = FcmData] ->
			case common_config:is_fcm_open() of
				false ->
					db:dirty_write(?DB_FCM_DATA, FcmData#r_fcm_data{total_online_time=0, offline_time=Now}),
					ok;
				true when Passed ->
					ok;
				true ->
					case db:dirty_read(?DB_ROLE_EXT, RoleID) of
						[#p_role_ext{last_offline_time=OffLineTime}]->
							next;
						_ ->
							OffLineTime = OffLineTimeFcm
					end,
					%%如果离线时间超过5小时或者隔天登陆，持续在线时间清零
					OffLineTimeTotal = common_tool:now() - OffLineTime,
					OffLineDate = common_time:time_to_date(OffLineTime),
					{NowDate, _} = erlang:localtime(),
					case OffLineTimeTotal >= ?FCM_OFFLINE_TIME orelse OffLineDate =/= NowDate of
						true ->
							db:dirty_write(?DB_FCM_DATA, FcmData#r_fcm_data{total_online_time=0}),
							{ok, need_fcm, 0};
						false ->
							case TotalOnlineTime >= ?FCM_KICK_TIME of
								true ->
									{error, fcm_kick_off_not_enough_off_time};
								false ->
									{ok, need_fcm, TotalOnlineTime}
							end
					end
			end
	end.

%% 踢掉玩家
kick_role(ErrorNo, ErrorInfo, Socket) ->
    case erlang:is_port(Socket) of
        true ->
            R = #m_system_error_toc{error_info=lists:flatten(ErrorInfo), error_no=ErrorNo},
            mgeeg_packet:packet_encode_send(Socket, ?DEFAULT_UNIQUE, ?SYSTEM, ?SYSTEM_ERROR, R);
        false ->
            ignore
    end.
%% T掉上次登录的角色
do_login_again(RoleID) ->
	RegName = common_misc:get_role_line_process_name(RoleID), 
	case global:whereis_name(RegName) of
		undefined ->
			ok;
		Pid ->
			do_login_again_2(RoleID,Pid)
	end.
do_login_again_2(RoleID,Pid)->
	erlang:monitor(process, Pid),
	%% 10秒之后强制kill ，
	case catch gen_server:call(Pid, login_again, 10000) of
		ok ->
			ok;
		_ ->
			erlang:exit(Pid, kill),
			ok
	end,
	catch global:send(global_gateway_server, {log_login_again, RoleID}),
	receive
		{'DOWN', _, process, _, _} ->
			%%刷新登陆的固定增加1秒
			timer:sleep(1000),
			ok;
		Info ->
			?ERROR_MSG("~ts:~p", ["重复登录时收到意外消息", Info]),
			{error, login_again_error}
		after 10000 ->
			{error, login_again_timeout}
	end.

%% @doc 加入在线列表
add_online(RoleDetail, ClientIP,Line)->
    #p_role{base=RoleBase,attr=RoleAttr} = RoleDetail,
    #p_role_base{role_id=RoleID,account_name=AccountName,role_name=RoleName,faction_id=FactionID,family_id=FamilyID} = RoleBase,
    #p_role_attr{level=Level} = RoleAttr,
    gen_server:call({global, mgeew_online}, 
                    {online, AccountName, RoleID, RoleName, Level, FactionID, FamilyID, ClientIP, Line}).

%% @doc 移出在线列表
remove_online(RoleID) ->
    gen_server:call({global, mgeew_online}, {offline, RoleID}).
 
                
% do_minute_dump() ->
%     case get_account_name() of
%         undefined->
%             ignore;
%         AccountName->
%             case db:dirty_read(?DB_FCM_DATA, AccountName) of
%                 [] ->
%                     db:dirty_write(?DB_FCM_DATA, #r_fcm_data{total_online_time=60, account=AccountName});        
%                 [#r_fcm_data{total_online_time=TotalOnlineTime, passed=Passed} = FcmData] ->
%                     case Passed of
%                         true ->
%                             ignore;
%                         false ->
%                             db:dirty_write(?DB_FCM_DATA, FcmData#r_fcm_data{total_online_time=TotalOnlineTime + 60})
%                     end
%             end
%     end.
                 

%% 角色信息的异常处理
do_role_detail_exception_process(RoleDetail) ->
    #p_role{base=RoleBase, fight=RoleFight, attr=RoleAttr, pos=RolePos, ext=RoleExt} = RoleDetail,
    #p_role_base{role_id=RoleID, status=Status} = RoleBase,
    #p_role_fight{hp=HP} = RoleFight,
    
    case RoleAttr of
        #p_role_attr{level=0}->
            RoleAttr2 = RoleAttr#p_role_attr{level=1};
        _ ->
            RoleAttr2 = RoleAttr
    end,  
    case RoleExt of
        undefined->
            [RoleExt2] = db:dirty_read(?DB_ROLE_EXT, RoleID);
        _ ->
            RoleExt2 = RoleExt
    end,
    
    case mgeeg_map_handler:update_map_info(RoleID,RoleBase,RoleAttr2,RolePos) of
        {ok,RolePos2,RoleBase2}->
            next;
        RolePos2 ->
            RoleBase2 = RoleBase
    end,
    RoleDetail2 = RoleDetail#p_role{ attr=RoleAttr2, pos=RolePos2, base=RoleBase2, ext=RoleExt2},
    case Status =:= ?ROLE_STATE_DEAD orelse HP =< 0 of
        true ->
            %% 新手村或是桃花涧中死亡或是异常断线不能回主城
            IsReturnToHome = not (RolePos2#p_role_pos.map_id == 10001 orelse RolePos2#p_role_pos.map_id == 10250),
            do_role_exit_exception2(RoleDetail2, IsReturnToHome);
        _ ->
            RoleDetail2
    end.

do_role_exit_exception2(RoleDetail, IsReturnToHome) ->
    %%这里可能需要对境界副本进行特殊处理
    #p_role{base=RoleBase, fight=RoleFight, pos=RolePos} = RoleDetail,
    #p_role_base{faction_id=FactionID, max_hp=MaxHP, max_mp=MaxMP} = RoleBase,
    #p_role_pos{map_id=MapID, map_process_name=OldMapPName} = RolePos,
    RoleFight2 = RoleFight#p_role_fight{hp=MaxHP, mp=MaxMP},
    case IsReturnToHome of
        true ->
            HomeMapID           = common_misc:get_home_mapid(FactionID, MapID),
            {HomeMapID, TX, TY} = common_misc:get_born_info_by_map(HomeMapID),
            Pos                 = #p_pos{tx=TX, ty=TY, px=0, py=0, dir=0},
            MapPName            = common_map:get_common_map_name(HomeMapID),
            RolePos2            = RolePos#p_role_pos{map_process_name=MapPName, old_map_process_name=OldMapPName, map_id=HomeMapID, pos=Pos};
        false ->
            RolePos2 =  RolePos
    end,
    RoleBase2 = RoleBase#p_role_base{status=?ROLE_STATE_NORMAL},
    RoleDetail#p_role{fight=RoleFight2, pos=RolePos2, base=RoleBase2}.

erase_account_full_info() ->
	erlang:erase(account_name_full_info).

set_account_full_info(Info) ->
    erlang:put(account_name_full_info, Info).


get_account_name()->
    erlang:get(?account_name).

set_account_name(AccountName)->
    erlang:put(?account_name,AccountName).

get_role_name()->
    erlang:get(?role_name).

set_role_name(RoleName)->
    erlang:put(?role_name,RoleName).

fix_map_ext_info(MapExtInfoOld,Level)->
    #r_role_map_ext{role_grow=RoleGrowInfoOld} = MapExtInfoOld,
    case RoleGrowInfoOld of
        undefined->
            MapExtInfoOld;
        #r_role_grow{sum_grow_val=SumGrowValOld} ->
            SumGrowVal = fix_sum_grow_val(SumGrowValOld,Level),
            RoleGrowInfo = RoleGrowInfoOld#r_role_grow{sum_grow_val=SumGrowVal},
            MapExtInfoOld#r_role_map_ext{role_grow=RoleGrowInfo}
    end.

fix_role_map_info(RoleMapInfo,VipInfo)->
    RoleMapInfo#p_map_role{vip_level=VipInfo#r_role_vip.vip_level}.

%%@doc 修正玩家的培养值可能异常的问题
fix_sum_grow_val(undefined,_Level)->
    undefined;
fix_sum_grow_val(SumGrowValOld,Level)->
    case SumGrowValOld of
        #r_grow_add_val{str=Str,int=Int,con=Con,dex=Dex,men=Men} ->
            {_,MaxVal} = common_role:get_grow_level_max_limit(Level),
            AddStr = common_role:get_grow_safe_val(MaxVal, Str),
            AddInt = common_role:get_grow_safe_val(MaxVal, Int),
            AddCon = common_role:get_grow_safe_val(MaxVal, Con),
            AddDex = common_role:get_grow_safe_val(MaxVal, Dex),
			AddMen = common_role:get_grow_safe_val(MaxVal, Men),
            SumGrowVal = #r_grow_add_val{str=AddStr,int=AddInt,con=AddCon,dex=AddDex,men=AddMen};
        _ ->
            ?ERROR_MSG("fix_sum_grow_val error,SumGrowValOld=~w",[SumGrowValOld]),
            SumGrowVal = undefined
    end,
    SumGrowVal.
