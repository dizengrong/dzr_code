%%%-------------------------------------------------------------------
%%% @author  caochuncheng
%%% @copyright mcsd (C) 2010, 
%%% @doc
%%% 消息广播处理：一般消息处理
%%% @end
%%% Created : 12 Jul 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_broadcast_general).

-behaviour(gen_server).

%% Include files
-include("mgeew.hrl").
-include("broadcast.hrl").

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link({ProcessName}) ->
    gen_server:start_link({local, erlang:list_to_atom(ProcessName)}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    {ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(Info, State) ->
    ?DEBUG("~ts, Info=~w",["接收到的消息为",Info]),
    do_handle_info(Info, State),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================


%% 一般广播消息处理
do_handle_info({Unique, Module, Method, DataRecord}, State) ->
    do_message(Unique, Module, Method, DataRecord, State);

%% 添加外部操作本进程内部执行接口
do_handle_info({func, Fun, Args}, _State) ->
    Ret =(catch apply(Fun,Args)),
    ?ERROR_MSG("~w",[Ret]);

do_handle_info(Info, _State) ->
    ?ERROR_MSG("~ts,Info=~w",["无法处理此消息", Info]).

do_message(Unique, Module, Method, DataRecord, State) ->
    Type = DataRecord#m_broadcast_general_tos.type,
    do_message_type({Type, Unique, Module, Method, DataRecord, State}).

do_message_type({?BC_MSG_TYPE_SYSTEM, Unique, Module, Method, DataRecord, State}) ->
    do_system_message({Unique, Module, Method, DataRecord, State});
do_message_type({?BC_MSG_TYPE_ALL, Unique, Module, Method, DataRecord, State}) ->
    do_all_message({Unique, Module, Method, DataRecord, State});
do_message_type({?BC_MSG_TYPE_CENTER, Unique, Module, Method, DataRecord, State}) ->
    do_center_message({Unique, Module, Method, DataRecord, State});
do_message_type({?BC_MSG_TYPE_CHAT, Unique, Module, Method, DataRecord, State}) ->
    do_chat_message({Unique, Module, Method, DataRecord, State});
do_message_type({?BC_MSG_TYPE_POP, Unique, Module, Method, DataRecord, State}) ->
    do_pop_message({Unique, Module, Method, DataRecord, State});
do_message_type({?BC_MSG_TYPE_OPERATE, Unique, Module, Method, DataRecord, State}) ->
    do_pop_message({Unique, Module, Method, DataRecord, State});
do_message_type(Info) ->
    ?DEBUG("~ts,Info=~w",["错误消息无法处理",Info]).

%% 系统广播消息
%% 系统消息只能通知给某一个角色
do_system_message({Unique, Module, Method, DataRecord, State}) ->
    SubType = DataRecord#m_broadcast_general_tos.sub_type,
    if SubType =:= ?BC_MSG_SUB_TYPE ->
            do_system_message2({Unique, Module, Method, DataRecord, State});
       true ->
            ?DEBUG("~ts,Message=~w",["系统消息的子类型不合法",DataRecord])
    end.
do_system_message2({Unique, Module, Method, DataRecord, State}) ->
    RoleIdList = DataRecord#m_broadcast_general_tos.role_list,
    if RoleIdList =/= [] andalso erlang:length(RoleIdList) > 0 ->
            do_send_message({role_list, Unique, Module, Method, DataRecord, RoleIdList});
       true ->
            do_system_message3({Unique, Module, Method, DataRecord, State})
    end.
do_system_message3({Unique, Module, Method, DataRecord, State}) ->
    if DataRecord#m_broadcast_general_tos.is_world ->
            do_send_message({world, Unique, Module, Method, DataRecord, 0});
       true ->
            do_system_message4({Unique, Module, Method, DataRecord, State})
    end.
do_system_message4({Unique, Module, Method, DataRecord, State}) ->
    CountryId = DataRecord#m_broadcast_general_tos.country_id,
    if CountryId =/= 0 ->
            do_send_message({country, Unique, Module, Method, DataRecord, CountryId});
       true ->
            do_system_message5({Unique, Module, Method, DataRecord, State})
    end.
do_system_message5({Unique, Module, Method, DataRecord, State}) ->
    FamliyId = DataRecord#m_broadcast_general_tos.famliy_id,
    if FamliyId =/= 0 ->
            do_send_message({famliy, Unique, Module, Method, DataRecord,FamliyId});
       true ->
            do_system_message6(Unique, Module, Method, DataRecord, State)
    end.

do_system_message6(Unique, Module, Method, DataRecord, _State) ->
    TeamId = DataRecord#m_broadcast_general_tos.team_id,
    if TeamId =/= 0 ->
            do_send_message({team,Unique, Module, Method, DataRecord, TeamId});
       true ->
            ?DEBUG("~ts,DataRecord=~w",["无法处理此系统消息",DataRecord])
    end.

%% 喇叭消息全服角色广播通知
do_all_message({Unique, Module, Method, DataRecord, _State}) ->
    %% 调用聊天服务器的世界接口去通知
    do_send_message({world, Unique, Module, Method, DataRecord, 0}).

%% 中央广播消息全服角色广播通知
do_center_message({Unique, Module, Method, DataRecord, _State}) ->
    %% 调用聊天服务器的世界接口去通知
    RoleIdList = DataRecord#m_broadcast_general_tos.role_list,
    CountryId = DataRecord#m_broadcast_general_tos.country_id,
    FamliyId = DataRecord#m_broadcast_general_tos.famliy_id,
    TeamId = DataRecord#m_broadcast_general_tos.team_id,
    IsWorld =  DataRecord#m_broadcast_general_tos.is_world,
    if RoleIdList =/= [] andalso erlang:length(RoleIdList) > 0 ->
            do_send_message({role_list, Unique, Module, Method, DataRecord, RoleIdList});
       CountryId =/= 0 ->
            do_send_message({country, Unique, Module, Method, DataRecord, CountryId});
       FamliyId =/= 0 ->
            do_send_message({famliy, Unique, Module, Method, DataRecord,FamliyId});
       TeamId =/= 0 ->
            do_send_message({team,Unique, Module, Method, DataRecord, TeamId});
       IsWorld =:= true ->
            do_send_message({world, Unique, Module, Method, DataRecord, 0});
       true ->
            ?DEBUG("~ts,DataRecord=~w",["无法处理此中央消息",DataRecord])
    end.

do_chat_message({Unique, Module, Method, DataRecord, State}) ->
    SubType = DataRecord#m_broadcast_general_tos.sub_type,
    
    do_chat_message_type({SubType,Unique, Module, Method, DataRecord, State}).


do_chat_message_type({?BC_MSG_TYPE_CHAT_WORLD,Unique, Module, Method, DataRecord, State}) ->
    do_chat_message2({Unique, Module, Method, DataRecord, State});
do_chat_message_type({?BC_MSG_TYPE_CHAT_COUNTRY,Unique, Module, Method, DataRecord, State}) ->
    do_chat_message2({Unique, Module, Method, DataRecord, State});
do_chat_message_type({?BC_MSG_TYPE_CHAT_FAMILY,Unique, Module, Method, DataRecord, State}) ->
    do_chat_message2({Unique, Module, Method, DataRecord, State});
do_chat_message_type({?BC_MSG_TYPE_CHAT_TEAM,Unique, Module, Method, DataRecord, State}) ->
    do_chat_message2({Unique, Module, Method, DataRecord, State});
do_chat_message_type(Info) ->
    ?DEBUG("~ts,Info=~w",["聊天消息广播子类型出错",Info]).

do_chat_message2({Unique, Module, Method, DataRecord, _State}) ->
    RoleIdList = DataRecord#m_broadcast_general_tos.role_list,
    CountryId = DataRecord#m_broadcast_general_tos.country_id,
    FamliyId = DataRecord#m_broadcast_general_tos.famliy_id,
    TeamId = DataRecord#m_broadcast_general_tos.team_id,
    IsWorld =  DataRecord#m_broadcast_general_tos.is_world,
    if RoleIdList =/= [] andalso erlang:length(RoleIdList) > 0 ->
            do_send_message({role_list, Unique, Module, Method, DataRecord, RoleIdList});
       CountryId =/= 0 ->
            do_send_message({country, Unique, Module, Method, DataRecord, CountryId});
       FamliyId =/= 0 ->
            do_send_message({famliy, Unique, Module, Method, DataRecord,FamliyId});
       TeamId =/= 0 ->
            do_send_message({team,Unique, Module, Method, DataRecord, TeamId});
       IsWorld =:= true ->
            do_send_message({world, Unique, Module, Method, DataRecord, 0});
       true ->
            ?DEBUG("~ts,DataRecord=~w",["无法处理此聊天消息",DataRecord])
    end.
        
%% 弹窗消息广播处理
do_pop_message({Unique, Module, Method, DataRecord, State}) ->
    SubType = DataRecord#m_broadcast_general_tos.sub_type,
    if SubType =:= ?BC_MSG_SUB_TYPE ->
            do_pop_message2({Unique, Module, Method, DataRecord, State});
       true ->
            ?DEBUG("~ts,Message=~w",["弹窗消息的子类型不合法",DataRecord])
    end.
do_pop_message2({Unique, Module, Method, DataRecord, State}) ->
    RoleIdList = DataRecord#m_broadcast_general_tos.role_list,
    if RoleIdList =/= [] andalso erlang:length(RoleIdList) > 0 ->
            do_send_message({role_list, Unique, Module, Method, DataRecord, RoleIdList});
       true ->
            do_pop_message3({Unique, Module, Method, DataRecord, State})
    end.
do_pop_message3({Unique, Module, Method, DataRecord, State}) ->
    if DataRecord#m_broadcast_general_tos.is_world ->
            do_send_message({world, Unique, Module, Method, DataRecord, 0});
       true ->
            do_pop_message4({Unique, Module, Method, DataRecord, State})
    end.
do_pop_message4({Unique, Module, Method, DataRecord, State}) ->
    CountryId = DataRecord#m_broadcast_general_tos.country_id,
    if CountryId =/= 0 ->
            do_send_message({country, Unique, Module, Method, DataRecord, CountryId});
       true ->
            do_pop_message5({Unique, Module, Method, DataRecord, State})
    end.
do_pop_message5({Unique, Module, Method, DataRecord, State}) ->
    FamliyId = DataRecord#m_broadcast_general_tos.famliy_id,
    if FamliyId =/= 0 ->
            do_send_message({famliy, Unique, Module, Method, DataRecord,FamliyId});
       true ->
            do_pop_message6(Unique, Module, Method, DataRecord, State)
    end.

do_pop_message6(Unique, Module, Method, DataRecord, _State) ->
    TeamId = DataRecord#m_broadcast_general_tos.team_id,
    if TeamId =/= 0 ->
            do_send_message({team,Unique, Module, Method, DataRecord, TeamId});
       true ->
            ?DEBUG("~ts,DataRecord=~w",["无法处理此弹窗消息",DataRecord])
    end.


%% 根据角色列表发送数据到客户端
do_send_message({role_list, Unique, Module, Method, DataRecord, RoleIdList}) ->
    Type = DataRecord#m_broadcast_general_tos.type,
    SubType = DataRecord#m_broadcast_general_tos.sub_type,
    Content = DataRecord#m_broadcast_general_tos.content,
    Message = #m_broadcast_general_toc{type = [Type],sub_type = SubType,content = Content},
    lists:foreach(fun(RoleId) ->
                          case common_misc:is_role_online(RoleId) of
                              false -> ignore;
                              true ->
                                  Line = common_misc:get_role_line_by_id(RoleId),
                                  common_misc:unicast(Line, RoleId, Unique, Module, Method, Message)
                          end
                  end,RoleIdList);
%% 根据世界频道发送数据到客户端
do_send_message({world, _Unique, Module, Method, DataRecord, _World}) ->
    Type = DataRecord#m_broadcast_general_tos.type,
    SubType = DataRecord#m_broadcast_general_tos.sub_type,
    Content = DataRecord#m_broadcast_general_tos.content,
    Message = #m_broadcast_general_toc{type = [Type],sub_type = SubType,content = Content},
    ?DEBUG("~ts,Message=~w",["接收世界广播消息为：",Message]),
    common_misc:chat_broadcast_to_world(Module, Method, Message);

%% 根据国家频道发送数据到客户端
do_send_message({country, _Unique, Module, Method, DataRecord, CountryId}) ->
    Type = DataRecord#m_broadcast_general_tos.type,
    SubType = DataRecord#m_broadcast_general_tos.sub_type,
    Content = DataRecord#m_broadcast_general_tos.content,
    Message = #m_broadcast_general_toc{type = [Type],sub_type = SubType,content = Content},
    ?DEBUG("~ts,Message=~w,CountryId=~w",["接收国家广播消息为：",Message,CountryId]),
    common_misc:chat_broadcast_to_faction(CountryId, Module, Method, Message);

%% 根据宗族频道发送数据到客户端
do_send_message({famliy, _Unique, Module, Method, DataRecord,FamliyId}) ->
    Type = DataRecord#m_broadcast_general_tos.type,
    SubType = DataRecord#m_broadcast_general_tos.sub_type,
    Content = DataRecord#m_broadcast_general_tos.content,
    Message = #m_broadcast_general_toc{type = [Type],sub_type = SubType,content = Content},
    ?DEBUG("~ts,Message=~w,FamliyId=~w",["接收家族广播消息为：",Message,FamliyId]),
    common_misc:chat_broadcast_to_family(FamliyId, Module, Method, Message);
%% 根据队伍发送数据到客户端
do_send_message({team, _Unique, Module, Method, DataRecord, TeamId}) ->
    Type = DataRecord#m_broadcast_general_tos.type,
    SubType = DataRecord#m_broadcast_general_tos.sub_type,
    Content = DataRecord#m_broadcast_general_tos.content,
    Message = #m_broadcast_general_toc{type = [Type],sub_type = SubType,content = Content},
    ?DEBUG("~ts,Message=~w,TeamId=~w",["接收组队广播消息为：",Message,TeamId]),
    common_misc:chat_broadcast_to_team(TeamId, Module, Method, Message).
