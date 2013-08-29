-module(mgeec_channel_extend).

-behavior(gen_server).

-include("mgeec.hrl").

-record(state, {channel_sign, id}).
-record(chat_extend_role, {role_id, role_name, role_info, pid}).

-export([start_link/2, init/1]).

-export([handle_info/2, handle_cast/2, handle_call/3, terminate/2, code_change/3]).

start_link(ChannelSign, ExtendID) ->
    ExtendPName = mgeec_misc:get_channel_extend_pname(ChannelSign, ExtendID),
    mgeec_misc:set_channel_extend_counter(ChannelSign, ExtendID, 0),
    {ok, _Pid} = gen_server:start_link({global, ExtendPName}, ?MODULE,[ChannelSign, ExtendID],[]).

init([ChannelSign, ExtendID]) ->
    %%?DEV("~ts:~w", ["创建了一个扩展频道,ID为", ExtendID]),
    {ok, #state{id=ExtendID, channel_sign=ChannelSign}}.

handle_info(Info, State) ->
    ?ERROR_MSG("~ts:~w", ["收到未知的消息(handle_info)", Info]),
    {noreply, State}.

handle_cast({chat, FromRoleID, FromRoleChatInfo, Msg}, State) ->
    #state{channel_sign=ChannelSign}=State,
    List = erlang:get(),
    %%?DEV("~ts:~w", ["扩展进程玩家列表", List]),
    lists:foreach(
      fun({_, ToRole}) ->
              do_chat(ChannelSign, Msg, ToRole, FromRoleID, FromRoleChatInfo)
      end, List),
    {noreply, State};

handle_cast({broadcast, Module, Method, DataRecord, IgnoreRoleIDList}, State) ->
    List = erlang:get(),
    %%?DEV("~ts:~w", ["扩展进程玩家列表", List]),
    do_broadcast(List, Module, Method, DataRecord, IgnoreRoleIDList),
    {noreply, State};

handle_cast({join, RoleID, RoleName, RoleChatInfo, Pid}, State) ->
    #state{id=ExtendID, channel_sign=ChannelSign}=State,
    %%?DEV("~ts:~w ~ts:~w ~ts:~w", ["玩家", RoleID, " 加入了扩展进程", ExtendID, "玩家ID", RoleID]),
    Result = mgeec_misc:update_channel_extend_counter(ChannelSign, ExtendID, 1),
    if Result =/= false ->
           erlang:put(get_dict_key(RoleID), #chat_extend_role{role_id=RoleID, 
                                                              role_name=RoleName,
                                                              role_info=RoleChatInfo, 
                                                              pid=Pid});
       true ->
           ignore
    end,
    %%?DEV("~ts:~w", ["进程字典", get()]),
    mgeec_misc:update_channel_extend_counter(ChannelSign, ExtendID, 1),
    {noreply, State};

handle_cast({leave, RoleID}, State) ->
    %%?DEV("~ts:~w", ["离开扩展进程", RoleID]),
    #state{id=ExtendID, channel_sign=ChannelSign}=State,
    mgeec_misc:update_channel_extend_counter(ChannelSign, ExtendID, -1),
    erlang:erase(get_dict_key(RoleID)),
    {noreply, State};
    
handle_cast({relive, RoleList}, State) ->
    #state{id=ExtendID, channel_sign=ChannelSign}=State,
    mgeec_misc:set_channel_extend_counter(ChannelSign, ExtendID, erlang:length(RoleList)),
    lists:foreach(
      fun({RoleDictKey, ExtendRole}) ->
              put(RoleDictKey, ExtendRole)
      end, RoleList),
    {noreply, State};

handle_cast(_Info, State) ->
    %%?DEV("~ts:~w", ["收到未知的消息(handle_cast)", Info]),
    {noreply, State}.
   
handle_call(_Info, _From, State) ->
    %%?DEV("~ts:~w", ["收到未知的消息(handle_call)", Info]),
    {reply, ok, State}.

terminate(_Reason, State) ->
    %%?DEV("~ts:~w ~w", ["频道扩展进程即将关闭", Reason, State]),
    #state{id=ExtendID, channel_sign=ChannelSign}=State,
    catch gen_server:cast({global, ChannelSign}, {make_extend_relive, ExtendID, get()}),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


do_chat(ChannelSign, Msg, ToRoleExtendInfo, FromRoleID, FromRoleChatInfo) 
  when erlang:is_record(ToRoleExtendInfo, chat_extend_role) ->
    %%?DEV("~ts:~w", ["广播频道聊天给玩家", ToRoleExtendInfo]),
    #chat_extend_role{role_id=SendToRoleID,
                      pid=RolePid} = ToRoleExtendInfo,
    if
        SendToRoleID =:= FromRoleID ->
            ignore;
        true ->
            DataRecord = 
                #m_chat_in_channel_toc{succ=true, 
                                       msg=Msg,
                                       channel_sign=ChannelSign,
                                       role_info=FromRoleChatInfo,
                                       tstamp=common_tool:now()},
            mgeec_misc:cast_role_router({pid, RolePid}, 
                                        {channel_msg, FromRoleChatInfo, DataRecord})
    end;

do_chat(_ChannelSign, _Msg, _ToRoleExtendInfo, _FromRoleID, _FromRoleChatInfo) ->
    %%?DEV("~ts:~w", ["字段值忽略广播", ToRoleExtendInfo]),
    ignore.

do_broadcast([], _Module, _Method, _DataRecord, _IgnoreRoleIDList) ->
    complete;

do_broadcast([{_, ToRoleExtendInfo}|List], 
             Module, 
             Method, 
             DataRecord, 
             [])
  when erlang:is_record(ToRoleExtendInfo, chat_extend_role) ->
    RolePid = ToRoleExtendInfo#chat_extend_role.pid,
    mgeec_misc:cast_role_router(
        {pid, RolePid}, 
        {broadcast_msg, Module, Method, DataRecord}),
    do_broadcast(List, Module, Method, DataRecord, []);

do_broadcast([{_, ToRoleExtendInfo}|List], 
             Module, 
             Method, 
             DataRecord, 
             IgnoreRoleIDList) 
  when erlang:is_record(ToRoleExtendInfo, chat_extend_role) ->
    RolePid = ToRoleExtendInfo#chat_extend_role.pid,
    RoleID = ToRoleExtendInfo#chat_extend_role.role_id,
    case lists:member(RoleID, IgnoreRoleIDList) of
        false ->
            NewIgnoreRoleIDList = IgnoreRoleIDList,
            mgeec_misc:cast_role_router(
                {pid, RolePid}, 
                {broadcast_msg, Module, Method, DataRecord});
        true ->
            NewIgnoreRoleIDList = lists:delete(RoleID, IgnoreRoleIDList),
            ignore
    end,
    do_broadcast(List, Module, Method, DataRecord, NewIgnoreRoleIDList);

do_broadcast([_|List], Module, Method, DataRecord, IgnoreRoleIDList) ->
    do_broadcast(List, Module, Method, DataRecord, IgnoreRoleIDList).

get_dict_key(RoleID) ->
    erlang:list_to_atom(lists:concat(["dict_", RoleID])).
