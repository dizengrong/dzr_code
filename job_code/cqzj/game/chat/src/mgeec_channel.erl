-module(mgeec_channel).

-behavior(gen_server).

-include("mgeec.hrl").

-record(state, {channel_sign, channel_type, channel_info, pnum=1, sub_process_list=[], role_nums=0}).

-export([start_link/1, init/1]).

-export([handle_info/2, handle_cast/2, handle_call/3, terminate/2, code_change/3]).

start_link(ChannelInfo) ->

    ChannelSign = ChannelInfo#p_channel_info.channel_sign,

    StartResult = 
        gen_server:start_link({global, ChannelSign}, 
                              ?MODULE,
                              [ChannelSign, ChannelInfo], 
                              []),
    {ok, _Pid} = 
        case StartResult of
            {ok, ServerPid} ->
                {ok, ServerPid};
            {error,{already_started, ServerPid}} ->
                {ok, ServerPid};
            Other ->
                ?ERROR_MSG("~ts:~w", ["创建频道失败了", Other]),
                Other
        end.

init([ChannelSign, ChannelInfo]) ->

    %%?DEV("~ts", ["一个频道被创建了"]),

    ChannelType = ChannelInfo#p_channel_info.channel_type,
    PNum = mgeec_misc:get_channel_sub_pnum(ChannelType),

    erlang:process_flag(trap_exit, true),

    SubProcessList = 
        lists:foldl(
          fun(ID, Result) ->

                  StartResult = mgeec_channel_extend:start_link(ChannelSign, ID),
                  SubPid = 
                      case StartResult of
                          {ok, Pid} ->
                              Pid;
                          {error,{already_started, Pid}} ->
                              Pid;
                          Other ->
                              ?ERROR_MSG("~ts:~w", ["创建频道子进程失败了", Other]),
                              throw(Other),
                              0
                      end,

                  [{ID, SubPid}|Result]

          end, [], lists:seq(1, PNum)),

    {ok, #state{channel_sign=ChannelSign, 
                channel_type = ChannelType,
                channel_info=ChannelInfo, 
                pnum=PNum, 
                sub_process_list=SubProcessList}}.

handle_info(_Info, State) ->
    %%?DEV("~ts:~w", ["收到未知的消息(handle_info)", Info]),
    {noreply, State}.

handle_cast({make_extend_relive, ExtendID, RoleList}, State) ->

    %%?DEV("~ts:~w", ["扩展进程报告它关闭了，需要重启, 扩展ID", ExtendID]),
    ChannelSign = State#state.channel_sign,

    {ok, Pid} = mgeec_channel_extend:start_link(ChannelSign, ExtendID),

    #state{sub_process_list=SubProcessList} = State,
    DelSubPList = lists:keydelete(ExtendID, 1, SubProcessList),
    NewSubPList = [{ExtendID, Pid}|DelSubPList],

    gen_server:cast(Pid, {relive, RoleList}),

    {noreply, State#state{sub_process_list=NewSubPList}};

handle_cast({broadcast, Module, Method, DataRecord, IgnoreRoleIDList}, State) ->
    
    #state{sub_process_list=SubProcessList} = State,

    lists:foreach(
      fun({_, Pid}) ->
              %%?DEV("~ts:~w", ["发送其他广播信息给扩展进程", Pid]),
              gen_server:cast(Pid, {broadcast, Module, Method, DataRecord, IgnoreRoleIDList})
      end, SubProcessList),
    
    {noreply, State};

handle_cast({chat, FromRoleID, RoleChatInfo, Msg}, State) ->
    
    #state{sub_process_list=SubProcessList,channel_type = _ChannelType} = State,
    lists:foreach(
      fun({_, Pid}) ->
              %%?DEV("~ts:~w", ["发送频道聊天给扩展进程", Pid]),
              gen_server:cast(Pid, {chat, FromRoleID, RoleChatInfo, Msg})
      end, SubProcessList),
    
    {noreply, State};

handle_cast({offline_notify, RoleID}, State) ->
    
    ChannelSign = State#state.channel_sign,
    ChannelType = State#state.channel_type,
    
    do_minus_online_num(ChannelSign),

    Module = ?CHAT,
    Method = ?CHAT_STATUS_CHANGE,
    DataRecord = 
        #m_chat_status_change_toc{role_id=RoleID,
                                  channel_type=ChannelType,
                                  channel_sign=ChannelSign,
                                  status=?CHAT_STATUS_OFFLINE},
    
    Result = handle_cast({leave, RoleID}, State),

    handle_cast({broadcast, Module, Method, DataRecord}, State),
    
    Result;

handle_cast({leave, RoleID}, State) ->

    ChannelExtendProcesName = get(RoleID),
    ChannelSign = State#state.channel_sign,
    gen_server:cast({global, ChannelExtendProcesName}, {leave, RoleID}),

    erase(RoleID),

    mgeec_misc:del_channel_role(ChannelSign, RoleID),

    RoleNums = State#state.role_nums - 1,
    if
        RoleNums =< 0 ->
            clear(State),
            {stop, normal, State};
        true ->
            {noreply, State#state{role_nums=RoleNums}}
    end;

handle_cast({online_notify, RoleID}, State) ->
    
    ChannelSign = State#state.channel_sign,
    ChannelType = State#state.channel_type,
    
    Module = ?CHAT,
    Method = ?CHAT_STATUS_CHANGE,
    DataRecord = 
        #m_chat_status_change_toc{role_id=RoleID,
                                  channel_type=ChannelType,
                                  channel_sign=ChannelSign,
                                  status=?CHAT_STATUS_ONLINE},
    
    handle_cast({broadcast, Module, Method, DataRecord}, State);

handle_cast({join, RoleID, RoleName, RoleChatInfo, Pid, ExtendID}, State) ->
    
    ChannelSign = State#state.channel_sign,
    ExtendPName = mgeec_misc:get_channel_extend_pname(ChannelSign, ExtendID),
    put(RoleID, ExtendPName),
    gen_server:cast({global, ExtendPName}, 
                    {join, RoleID, RoleName, RoleChatInfo, Pid}),
    
    RoleNums = State#state.role_nums + 1,
    {noreply, State#state{role_nums=RoleNums}};

handle_cast(_Info, State) ->
    %%?DEV("~ts:~w", ["收到未知的消息(handle_cast)", Info]),
    {noreply, State}.
   
handle_call(_Info, _From, State) ->
    %%?DEV("~ts:~w", ["收到未知的消息(handle_call)", Info]),
    {reply, ok, State}.

terminate(_Reason, _State) ->
    %%?DEV("~ts:~w", ["频道进程即将关闭", Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

clear(State) ->
    %%?DEV("~ts:~w", ["频道进程即将关闭,清理战场中...", State]),
    #state{sub_process_list=SubProcessList, 
           channel_sign=ChannelSign} = State,

    lists:foreach(
      fun({_, Pid}) ->
              exit(Pid, kill)
      end, SubProcessList),
    
    ets:delete(?ETS_CHANNEL_COUNTER, ChannelSign),
    ets:delete(?ETS_CHANNEL_ROLE, ChannelSign).

do_minus_online_num(ChannelSign) ->
    case db:dirty_read(?DB_CHAT_CHANNELS, ChannelSign) of
        [ChannelInfo] ->
            OnlineNum = ChannelInfo#p_channel_info.online_num-1,
            NewChannelInfo = ChannelInfo#p_channel_info{online_num=OnlineNum},
            db:dirty_write(?DB_CHAT_CHANNELS, NewChannelInfo),
            NewChannelInfo;
        [] ->
            ?ERROR_MSG("~ts", ["没有找到频道的基本信息"]),
            {error, empty}
    end.
