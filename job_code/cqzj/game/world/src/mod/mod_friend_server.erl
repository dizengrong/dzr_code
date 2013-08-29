%%% -------------------------------------------------------------------
%%% Author  : Luo.JCheng
%%% Description :
%%%
%%% Created : 2010-7-26
%%% -------------------------------------------------------------------
-module(mod_friend_server).

-behaviour(gen_server).
-include("mgeew.hrl").  

-export([
         start_link/0, 
         start/0,
         online_notice/1,
         offline_notice/1,
         upgrade_notice/3,
         offline_request/2,
         add_friendly/4, 
         add_friend/3,
         get_dirty_friend_list/1,
         relative_modify/4,
         get_dirty_friend_info/2,
         get_friend_type/2,
         get_friend_base_info_by_friendly/1
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).
-record(p_level_exp, {level, exp}).
-record(friend_state, {}).

-define(SERVER, mod_friend_server).
-define(TYPE_NORELA, 0).
-define(TYPE_FRIEND, 1).
-define(TYPE_BLACK, 2).
-define(TYPE_ENEMY, 3).
-define(FRIEND_NUM_LIMITED, 200).
-define(BLACK_LIMITED, 10).
-define(ENEMY_LIMITED, 50).
%% 接受好友祝福次数字典 
-define(DICT_FRIEND_CONGRATULA, friend_congratula).
%% 发送好友祝福次数字典 
-define(DICT_SEND_FRIEND_CONGRATULA, send_friend_congratula).
-define(AD_ROLE_LIST, ad_role_list).
-define(OFFLINE_ADD_LIST, offline_add_list).
-define(MAX_ADVERTISE_REQUEST, 3).

%%%===================================================================
%%% API
%%%===================================================================

start() ->
    {ok, _} = supervisor:start_child(mgeew_sup, 
                                     {?MODULE,
                                      {?MODULE, start_link, []},
                                      transient, brutal_kill, worker, [?MODULE]
                                     }).

%%上线提醒
online_notice(RoleID) ->
    catch gen_server:cast({global, ?SERVER}, {online_notice, RoleID}).

%%离线通知
offline_notice(RoleID) ->
    catch gen_server:cast({global, ?SERVER}, {offline_notice, RoleID}).

%%升级提醒
upgrade_notice(RoleID,OldLevel,NewLevel) ->
    catch gen_server:cast({global, ?SERVER}, {upgrade_notice, RoleID,OldLevel,NewLevel}).

%%离线请求
offline_request(RoleID, Line) ->
    catch gen_server:cast({global, ?SERVER}, {offline_request, RoleID, Line}).

%%添加好友度
add_friendly(RoleID, FriendID, Friendly, Type) ->
    catch gen_server:cast({global, ?SERVER}, {add_friendly, RoleID, FriendID, Friendly, Type}).

%%relative: 1、师徒关系
%%第一RoleID是师傅的id
add_friend(RoleID, FriendID, Relative) ->
    gen_server:call({global, ?SERVER}, {add_friend, RoleID, FriendID, Relative}).

%%state 1:出师 2:断绝师徒关系
%%第一RoleID是师傅的id
relative_modify(RoleID, FriendID, Relative, State) ->
    gen_server:call({global, ?SERVER}, {relative_modify, RoleID, FriendID, Relative, State}).

%%%===================================================================
%%% callback function
%%%===================================================================

start_link() ->
    gen_server:start_link({global, ?SERVER}, ?MODULE, [], []).

init([]) ->
    ets:new(friend_request, [bag, protected, named_table]),
    %% 随机种子
    random:seed(now()),
    {ok, #friend_state{}}.

handle_call(Request, _From, State) ->
    ?DEBUG("handle_call, request: ~w", [Request]),

    Reply = do_handle_call(Request),
    {reply, Reply, State}.

handle_cast(Msg, State) ->
    ?DEBUG("handle_cast, msg: ~w", [Msg]),

    do_handle_cast(Msg),
    {noreply, State}.

handle_info(Info, State) ->
    ?DEBUG("handle_info, info: ~w", [Info]),

    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% internal function================================
do_handle_info({Unique, Module, ?FRIEND_REQUEST, DataIn, RoleID, _PID, Line}) ->
    do_request(Unique, Module, ?FRIEND_REQUEST, DataIn, RoleID, Line);
do_handle_info({Unique, Module, ?FRIEND_ACCEPT, DataIn, RoleID, _PID, Line}) ->
    do_accept(Unique, Module, ?FRIEND_ACCEPT, DataIn, RoleID, Line);
do_handle_info({Unique, Module, ?FRIEND_REFUSE, DataIn, RoleID, _PID, Line}) ->
    do_refuse(Unique, Module, ?FRIEND_REFUSE, DataIn, RoleID, Line);
do_handle_info({Unique, Module, ?FRIEND_BLACK, DataIn, RoleID, _PID, Line}) ->
    do_black(Unique, Module, ?FRIEND_BLACK, DataIn, RoleID, Line);
do_handle_info({Unique, Module, ?FRIEND_DELETE, DataIn, RoleID, PID, _Line}) ->
    do_delete(Unique, Module, ?FRIEND_DELETE, DataIn, RoleID, PID);
do_handle_info({Unique, Module, ?FRIEND_LIST, DataIn, RoleID, _PID, Line}) ->
    do_list(Unique, Module, ?FRIEND_LIST, DataIn, RoleID, Line);
do_handle_info({Unique, Module, ?FRIEND_INFO, DataIn, RoleID, _PID, Line}) ->
    do_info(Unique, Module, ?FRIEND_INFO, DataIn, RoleID, Line);
do_handle_info({Unique, Module, ?FRIEND_MODIFY, DataIn, RoleID, _PID, Line}) ->
    do_modify(Unique, Module, ?FRIEND_MODIFY, DataIn, RoleID, Line);
do_handle_info({Unique, Module, ?FRIEND_GET_INFO, DataIn, RoleID, _PID, Line}) ->
    do_get_info(Unique, Module, ?FRIEND_GET_INFO, DataIn, RoleID, Line);
do_handle_info({Unique, Module, ?FRIEND_RECOMMEND, _DataIn, RoleID, _PID, Line}) ->
    do_recommend(Unique, Module, ?FRIEND_RECOMMEND, RoleID, Line);
do_handle_info({Unique, Module, ?FRIEND_CONGRATULATION, DataIn, RoleID, PID, _Line}) ->
    do_congratula(Unique, Module, ?FRIEND_CONGRATULATION, DataIn, RoleID, PID);
%do_handle_info({Unique, Module, ?FRIEND_VISIT, DataIn, RoleID, PID, _Line}) ->
%    do_visit(Unique, Module, ?FRIEND_VISIT, DataIn, RoleID, PID);
do_handle_info({Unique, Module, ?FRIEND_ADVERTISE, _DataIn, RoleID, PID, _Line}) ->
    do_advertise(Unique, Module, ?FRIEND_ADVERTISE, RoleID, PID);

do_handle_info({add_enemy, RoleID, TargetID, TargetType, Flag, IsWarOfFaction}) ->
    do_add_enemy(RoleID, TargetID, TargetType, Flag, IsWarOfFaction);
do_handle_info({add_friendly, RoleID, FriendID, Friendly, Type}) ->
    do_add_friendly(RoleID, FriendID, Friendly, Type);
do_handle_info({vip_active, RoleID, RoleName, VipLevel}) ->
    do_vip_active(RoleID, RoleName, VipLevel);

%% 送花增加好友度处理
do_handle_info({give_flower,GiveRoleId,ReceiveRoleId,FlowerItemId}) ->
    do_give_flower(GiveRoleId,ReceiveRoleId,FlowerItemId);
%% 副本增加好友度处理
do_handle_info({fb_activity,RoleIdList,FbType}) ->
    do_fb_activity(RoleIdList,FbType);

do_handle_info({_Unique, _Module, _Method, _DataIn, _RoleID, _PID, _Line}) ->
    ?ERROR_MSG("do_handle_info, unknow method or data", []).

do_handle_cast({online_notice, RoleID}) ->
    do_online_notice(RoleID);
do_handle_cast({offline_notice, RoleID}) ->
    do_offline_notice(RoleID);
do_handle_cast({upgrade_notice, RoleID,OldLevel,NewLevel}) ->
    do_upgrade_notice(RoleID,OldLevel,NewLevel);
do_handle_cast({offline_request, RoleID, Line}) ->
    do_offline_request(RoleID, Line);
do_handle_cast({add_friendly, RoleID, FriendID, Friendly, Type}) ->
    do_add_friendly(RoleID, FriendID, Friendly, Type).

do_handle_call({relative_modify, RoleID, FriendID, Relative, State}) ->
    do_relative_modify(RoleID, FriendID, Relative, State);
do_handle_call({add_friend, RoleID, FriendID, Relative}) ->
    do_add_friend(RoleID, FriendID, Relative).

do_relative_modify(RoleID, FriendID, Relative, State) ->
    case db:transaction(
           fun() ->
                   t_do_relative_modify(RoleID, FriendID, Relative, State)
           end)
    of
        {atomic, {Rela1, Rela2}} ->
            D1 = #m_friend_change_relative_toc{role_id=FriendID, relative=Rela1},
            ?INFO_MSG("D1:~w~n",[D1]),
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_CHANGE_RELATIVE, D1),
            D2 = #m_friend_change_relative_toc{role_id=RoleID, relative=Rela2},
            ?INFO_MSG("D2:~w~n",[D2]),
            common_misc:unicast({role, FriendID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_CHANGE_RELATIVE, D2),
            ok;
        {aborted, R} ->
            ?DEBUG("do_relative_modify, r: ~w", [R]),
            {error, ?_LANG_SYSTEM_ERROR}
    end.

t_do_relative_modify(RoleID, FriendID, Relative, State) ->
    FriendInfo = t_get_friend_info(RoleID, FriendID),
    db:delete_object(?DB_FRIEND, FriendInfo, write),
    if
        Relative =:= 1 andalso State =:= 1 ->
            Rela = FriendInfo#r_friend.relative,
            FriendInfo2 = FriendInfo#r_friend{relative=lists:delete(2, Rela)},
            db:write(?DB_FRIEND, FriendInfo2, write),
            {lists:delete(2, Rela), []};
        Relative =:= 1 andalso State =:= 2 ->
            Rela = FriendInfo#r_friend.relative,
            FriendInfo2 = FriendInfo#r_friend{relative=lists:delete(2, Rela)}, 

            FriendInfo3 = t_get_friend_info(FriendID, RoleID),
            db:delete_object(?DB_FRIEND, FriendInfo3, write),
            Rela2 = FriendInfo3#r_friend.relative,
            FriendInfo4 = FriendInfo3#r_friend{relative=lists:delete(1, Rela2)},
            db:write(?DB_FRIEND, FriendInfo2, write),
            db:write(?DB_FRIEND, FriendInfo4, write),
            {lists:delete(2, Rela), lists:delete(1, Rela2)}
    end.

do_add_friend(RoleID, FriendID, Relative) ->
    %%特殊关系不考虑好友数限制
    case if_can_accept2(RoleID, FriendID, false) of
        {false, Reason} ->
            {error, Reason};
        {true, FriendType} ->
            case db:transaction(
                   fun() ->
                           t_do_accept(RoleID, FriendID, FriendType, Relative)
                   end)
            of
                {atomic, {RSelf, ROther}} ->
                    %%如果原来是好友则只是关系改变
                    case FriendType of
                        ?TYPE_FRIEND ->
                            %%这个处理有点郁闷
                            Rela = (RSelf#m_friend_accept_toc.friend_info)#p_friend_info.relative,
                            Rela2 = (ROther#m_friend_accept_toc.friend_info)#p_friend_info.relative,
                            D1 = #m_friend_change_relative_toc{role_id=FriendID, relative=Rela},
                            D2 = #m_friend_change_relative_toc{role_id=RoleID, relative=Rela2},
                            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_CHANGE_RELATIVE, D1),
                            common_misc:unicast({role, FriendID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_CHANGE_RELATIVE, D2);
                        _ ->
                            RSelf2 = RSelf#m_friend_accept_toc{return_self=false},
                            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_ACCEPT, RSelf2),
                            common_misc:unicast({role, FriendID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_ACCEPT, ROther)
                    end,
                    % catch hook_add_friend:hook({RoleID,RoleID,FriendID}),
                    friendly_add_notify(RoleID, FriendID, 999, 0),
                    ok;
                {aborted, R} ->
                    ?ERROR_MSG("do_add_friend, r: ~w", [R]),
                    {error, ?_LANG_SYSTEM_ERROR}
            end
    end.

%%添加仇人
do_add_enemy(RoleID, TargetID, TargetType, Flag, IsWarOfFaction) ->
    case if_can_add_enemy(RoleID, TargetID, TargetType) of
        {false, ?_LANG_FRIEND_ENEMY_FRIEND} ->
            %% 在竞技区杀死好友不扣好友度
            case Flag of
                true ->
                    ignore;
                _ ->
                    %% 被好友恶意杀死扣好友度
                    case do_add_friendly(RoleID, TargetID, -5, 3) of
                        {ok, 0} ->
                            ignore;
                        {ok, Add} ->
                            %% 通知
                            Msg = lists:flatten(io_lib:format(?_LANG_FRIEND_KILL_FRIEND, [abs(Add)])),
                            common_broadcast:bc_send_msg_role(TargetID, ?BC_MSG_TYPE_SYSTEM, Msg);
                        _ ->
                            ignore
                    end
            end;
        {false, Reason} ->
            ?DEBUG("add_enemy, reason: ~w", [Reason]),
            ok;
        {true, FriendType} ->
            case IsWarOfFaction of
                true ->
                    ignore;
                _ ->
                    do_add_enemy2(RoleID, TargetID, FriendType)
            end
    end.
do_add_enemy2(RoleID, TargetID, FriendType) ->
    case db:transaction(
           fun() -> 
                   t_add_enemy(RoleID, TargetID, FriendType)
           end)
    of
        {aborted, R} ->
            ?DEBUG("do_add_enemy2, r: ~w", [R]),
            ok;
        {atomic, DataRecord} ->
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_ENEMY, DataRecord)
    end.

%% @doc 离线请求
do_offline_request(RoleID, Line) ->
    RequestList = ets:lookup(friend_request, RoleID),
    InfoList =
        lists:foldl(
          fun({_, RequestID}, Acc) ->
                  try
                      {ok, RoleBase} = common_misc:get_dirty_role_base(RequestID),
                      {ok, RoleAttr} = common_misc:get_dirty_role_attr(RequestID),
                      RequestInfo = #p_simple_friend_info{rolename=RoleBase#p_role_base.role_name,
                                                          faction_id=RoleBase#p_role_base.faction_id,
                                                          is_online=if_online(RequestID),
                                                          head=RoleBase#p_role_base.head,
                                                          level=RoleAttr#p_role_attr.level},
                      [RequestInfo | Acc]
                  catch
                      _ : R ->
                          ?ERROR_MSG("do_offline_request, r: ~w", [R]),
                          Acc
                  end
          end, [], RequestList),
    case length(InfoList) > 0 of
        true ->
            DataRecord = #m_friend_offline_request_toc{request_list=InfoList},
            common_misc:unicast(Line, RoleID, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_OFFLINE_REQUEST, DataRecord);
        _ ->
            ok
    end.

%% @doc 加好友度 type: 方式，1、组队，2、聊天,3增加减少好友度  4一起完成副本增加好友度
do_add_friendly(RoleID, FriendID, Add, Type) ->
    try
        FriendInfo = get_dirty_friend_info(RoleID, FriendID),
        FriendInfo2 = get_dirty_friend_info(FriendID, RoleID),
        {Date, _} = calendar:now_to_local_time(now()),
        Result =
            case Type of
                1 -> %% 1 组队增加好友度
                    do_add_friendly2_1(Add, Date, FriendInfo, FriendInfo2);
                2 -> %% 2 聊天增好友度
                    do_add_friendly2_2(Add, Date, FriendInfo, FriendInfo2);
                3 -> %% 3 增加减少好友度
                    do_add_friendly2_3(Add, FriendInfo, FriendInfo2);
                4 -> %% 5 一起完成副本增加好友度
                    do_add_friendly2_4(Add, Date, FriendInfo, FriendInfo2)
            end,
        
        case Result of
            {ok, Friendly2} ->
                #r_friend{friendly=Friendly} = FriendInfo,
                %% 好友等级变动提示
                friendly_add_notify(RoleID, FriendID, Friendly, Friendly2),
                
                %% 通知前端耐久度变化
                DataRecord = #m_friend_add_friendly_toc{role_id=FriendID, friendly=Friendly2},
                DataRecord2 = #m_friend_add_friendly_toc{role_id=RoleID, friendly=Friendly2},
                common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_ADD_FRIENDLY, DataRecord),
                common_misc:unicast({role, FriendID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_ADD_FRIENDLY, DataRecord2),

                {ok, Friendly2-Friendly};
            _ ->
                error
        end
    catch
        _ : R ->
            ?ERROR_MSG("do_add_friendly, error: ~w", [R]),
            error
    end.
do_add_friendly2_1(Add, Date, FriendInfo, FriendInfo2) ->
    %% 上次加好友度的日期以及已加的点数
    [MaxFriendly] = common_config_dyn:find(friend,max_friendly),
    NewFriendly = 
        case FriendInfo#r_friend.friendly + Add >= MaxFriendly of
            true ->
                MaxFriendly;
            _ ->
                FriendInfo#r_friend.friendly + Add
        end,
    case FriendInfo#r_friend.team_time of
        undefined ->
            db:dirty_delete_object(?DB_FRIEND, FriendInfo),
            db:dirty_delete_object(?DB_FRIEND, FriendInfo2),
            db:dirty_write(?DB_FRIEND, FriendInfo#r_friend{friendly=NewFriendly,team_time={Date, 1}}),
            db:dirty_write(?DB_FRIEND, FriendInfo2#r_friend{friendly=NewFriendly,team_time={Date, 1}}),
            {ok, NewFriendly};
        {Date2, Times} ->
            %% 组队每天最多增10点
            [{_,_,MaxAddTimes}] = common_config_dyn:find(friend,add_friendly_by_team),
            case Date =/= Date2 orelse Times < MaxAddTimes of
                true ->
                    db:dirty_delete_object(?DB_FRIEND, FriendInfo),
                    db:dirty_delete_object(?DB_FRIEND, FriendInfo2),
                    db:dirty_write(?DB_FRIEND, FriendInfo#r_friend{friendly=NewFriendly,team_time={Date, Times+1}}),
                    db:dirty_write(?DB_FRIEND, FriendInfo2#r_friend{friendly=NewFriendly, team_time={Date, Times+1}}),
                    {ok, NewFriendly};
                false ->
                    {error, reach_limited}
            end
    end.
do_add_friendly2_2(Add, Date, FriendInfo, FriendInfo2) ->
    [MaxFriendly] = common_config_dyn:find(friend,max_friendly),
    NewFriendly = 
        case FriendInfo#r_friend.friendly + Add >= MaxFriendly of
            true ->
                MaxFriendly;
            _ ->
                FriendInfo#r_friend.friendly + Add
        end,
    case FriendInfo#r_friend.chat_time of
        undefined ->
            db:dirty_delete_object(?DB_FRIEND, FriendInfo),
            db:dirty_delete_object(?DB_FRIEND, FriendInfo2),
            db:dirty_write(?DB_FRIEND, FriendInfo#r_friend{friendly=NewFriendly,chat_time={Date, 1}}),
            db:dirty_write(?DB_FRIEND, FriendInfo2#r_friend{friendly=NewFriendly,chat_time={Date, 1}}),
            {ok, NewFriendly};
        {Date2, Times} ->
            case Date =/= Date2 orelse Times < 10 of
                true ->
                    db:dirty_delete_object(?DB_FRIEND, FriendInfo),
                    db:dirty_delete_object(?DB_FRIEND, FriendInfo2),
                    db:dirty_write(?DB_FRIEND, FriendInfo#r_friend{friendly=NewFriendly,chat_time={Date, Times+1}}),
                    db:dirty_write(?DB_FRIEND, FriendInfo2#r_friend{friendly=NewFriendly,chat_time={Date, Times+1}}),
                    {ok,NewFriendly};
                false ->
                    {error, reach_limited}
            end
    end.
do_add_friendly2_3(Add, FriendInfo, FriendInfo2) ->
    case FriendInfo#r_friend.friendly + Add < 0 of
        true ->
            Add2 = -FriendInfo#r_friend.friendly;
        _ ->
            Add2 = Add
    end,
    [MaxFriendly] = common_config_dyn:find(friend,max_friendly),
    NewFriendly = 
        case FriendInfo#r_friend.friendly + Add2 >= MaxFriendly of
            true ->
                MaxFriendly;
            _ ->
                FriendInfo#r_friend.friendly + Add2
        end,
    db:dirty_delete_object(?DB_FRIEND, FriendInfo),
    db:dirty_delete_object(?DB_FRIEND, FriendInfo2),
    db:dirty_write(?DB_FRIEND, FriendInfo#r_friend{friendly=NewFriendly}),
    db:dirty_write(?DB_FRIEND, FriendInfo2#r_friend{friendly=NewFriendly}),
    {ok,NewFriendly}.

do_add_friendly2_4(Add, Date, FriendInfo, FriendInfo2) ->
    %% 上次加好友度的日期以及已加的点数
    [MaxFriendly] = common_config_dyn:find(friend,max_friendly),
    NewFriendly = 
        case FriendInfo#r_friend.friendly + Add >= MaxFriendly of
            true ->
                MaxFriendly;
            _ ->
                FriendInfo#r_friend.friendly + Add
        end,
    case FriendInfo#r_friend.fb_time of
        undefined ->
            db:dirty_delete_object(?DB_FRIEND, FriendInfo),
            db:dirty_delete_object(?DB_FRIEND, FriendInfo2),
            db:dirty_write(?DB_FRIEND, FriendInfo#r_friend{friendly=NewFriendly,team_time={Date, 1}}),
            db:dirty_write(?DB_FRIEND, FriendInfo2#r_friend{friendly=NewFriendly,team_time={Date, 1}}),
            {ok, NewFriendly};
        {Date2, Times} ->
            %% 组队每天最多增10点
            [{_,MaxAddTimes}] = common_config_dyn:find(friend,add_friendly_by_fb),
            case Date =/= Date2 orelse Times < MaxAddTimes of
                true ->
                    db:dirty_delete_object(?DB_FRIEND, FriendInfo),
                    db:dirty_delete_object(?DB_FRIEND, FriendInfo2),
                    db:dirty_write(?DB_FRIEND, FriendInfo#r_friend{friendly=NewFriendly,team_time={Date, Times+1}}),
                    db:dirty_write(?DB_FRIEND, FriendInfo2#r_friend{friendly=NewFriendly, team_time={Date, Times+1}}),
                    {ok, NewFriendly};
                false ->
                    {error, reach_limited}
            end
    end.

%% @doc 离线提醒
do_offline_notice(RoleID) ->
    case get_in_friend_list(RoleID) of
        {error, R} ->
            ?DEBUG("offline_notice, r: ~w", [R]),
            ok;
        FriendList ->
            ?DEBUG("do_offline_notice, friendlist: ~w", [FriendList]),
            lists:foreach(
              fun(FriendInfo) ->
                      #r_friend{roleid=FriendID} = FriendInfo,
                      DataRecord = #m_friend_offline_toc{roleid=RoleID},
                      catch common_misc:unicast({role, FriendID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_OFFLINE, DataRecord)
              end, FriendList)
    end,
    
    %% 把好友祝福纪录清掉
    erase({?DICT_FRIEND_CONGRATULA, RoleID}).

%%上线提醒
do_online_notice(RoleID) ->
    case get_in_friend_list(RoleID) of
        {error, _} ->
            ok;
        FriendList ->
            lists:foreach(
              fun(FriendInfo) ->
                      #r_friend{roleid=FriendID} = FriendInfo,
                      DataRecord = #m_friend_online_toc{roleid=RoleID},
                      common_misc:unicast({role, FriendID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_ONLINE, DataRecord)
              end, FriendList)
    end,
    L = get_offline_add_list(RoleID),
    case L of
        [] ->
            ignore;
        AddList ->
            lists:foreach(
              fun({Type, TargetID}) ->
                      {ok, #p_role_base{role_name=TargetName}} = common_misc:get_dirty_role_base(TargetID),
                      if Type =:= accept ->
                              Msg = common_tool:get_format_lang_resources(?_LANG_FRIEND_ONLINE_ACCEPT,[TargetName]);
                         true ->
                              Msg = common_tool:get_format_lang_resources(?_LANG_FRIEND_ONLINE_REFUSE,[TargetName])
                      end,
                      common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, lists:flatten(Msg))
              end, AddList)
    end,
    offline_add_list_clear(RoleID).

%% @doc 好友升级提醒
do_upgrade_notice(RoleID, OldLevel, NewLevel) ->
    %% 升级提醒
    case get_in_friend_list(RoleID) of
        {error, R} ->
            ?DEBUG("on_upgrade_notice, r: ~w", [R]),
            ok;
        FriendList ->
            ?DEBUG("do_upgrade_notice, friendlist: ~w", [FriendList]),
            lists:foreach(
              fun(FriendInfo) ->
                      #r_friend{roleid=FriendID} = FriendInfo,
                      DataRecord = #m_friend_upgrade_toc{roleid=RoleID,oldlevel=OldLevel,newlevel=NewLevel},
                      common_misc:unicast({role, FriendID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_UPGRADE, DataRecord)
              end, FriendList)
    end,
	
	%% 好友祝福
	case NewLevel >= 20 of
		true ->
			put({?DICT_FRIEND_CONGRATULA, RoleID}, {NewLevel, []});
		_ ->
			nil
	end,
	put({?DICT_SEND_FRIEND_CONGRATULA, RoleID}, {NewLevel, []}).

%%获取玩家的'好友基本信息'
do_get_info(Unique, Module, Method, DataIn, RoleID, Line) ->
    #m_friend_get_info_tos{roleid=Role} = DataIn,
    Info = (catch get_friend_info(Role, 4, 0, [])),
    Record = 
        if erlang:is_record(Info,p_friend_info) =:= true ->
                #m_friend_get_info_toc{roleinfo=Info};
           true ->
                #m_friend_get_info_toc{roleinfo=undefined}
        end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, Record).

%% @doc 请求加好友
do_request(Unique, Module, Method, DataIn, RoleID, Line) ->
    #m_friend_request_tos{name=TargetName} = DataIn,
    
    try
        TargetID = common_misc:get_roleid(TargetName),
        %%
        case TargetID of
            0 ->
                throw(?_LANG_FRIEND_ROLE_NOT_EXIST);
            _ ->
                ok
        end,
        %% 不能邀请自己为好友
        case RoleID =:= TargetID of
            true ->
                throw(?_LANG_FRIEND_REQUEST_SELF);
            _ ->
                ok
        end,
        %% 检测是否能请求，好友数量是为已经满，仇人、黑名单等
        case if_can_request(RoleID, TargetID) of
            true ->
                ok;
            {false, Reason} ->
                throw(Reason)
        end,
        %% 是否已经发送过请求
        case if_in_request_list(TargetID, RoleID) of
            true ->
                throw(?_LANG_FRIEND_REQUEST_ALREADY);
            _ ->
                ok
        end,
        %% 
        do_request2(Unique, Module, Method, RoleID, TargetID, TargetName, Line)
    catch
        _ : R when is_binary(R) ->
            do_request_error(Unique, Module, Method, RoleID, TargetName, R, Line);
        T : R ->
            ?ERROR_MSG("do_request, error, type: ~w, reason: ~w", [T, R]),
            do_request_error(Unique, Module, Method, RoleID, TargetName, ?_LANG_SYSTEM_ERROR, Line)
    end.

do_request2(Unique, Module, Method, RoleID, TargetID, TargetName, Line) ->
    {ok, RoleBase} = common_misc:get_dirty_role_base(RoleID),
    #p_role_base{role_name=RoleName} = RoleBase, 
    [#r_sys_config{sys_config=SysConfig}] = db:dirty_read(?DB_SYSTEM_CONFIG, TargetID),
    #p_sys_config{accept_friend_request=AcceptRequest} = SysConfig,
    %% 是否接收好友请求
    case AcceptRequest of
        true ->
            %% 插入请求列表
            ets:insert(friend_request, {TargetID, RoleID}),

            SendSelf = #m_friend_request_toc{name=TargetName, return_self=true},
            SendTarget = #m_friend_request_toc{name=RoleName, return_self=false},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, SendSelf),
            common_misc:unicast({role, TargetID}, ?DEFAULT_UNIQUE, Module, Method, SendTarget);
        _ ->
            do_request_error(Unique, Module, Method, RoleID, TargetName, ?_LANG_FRIEND_TARGET_REFUSE, Line),
            %% 发送消息给被请求方，主动拒绝
            Msg = lists:flatten(io_lib:format("[~s]请求加你为好友，已被自动拒绝", [RoleName])),
            common_broadcast:bc_send_msg_role(TargetID, ?BC_MSG_TYPE_SYSTEM, Msg)
    end.

do_request_error(Unique, Module, Method, RoleID, TargetName, Reason, Line) ->
    R = #m_friend_request_toc{succ=false, name=TargetName, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%% @doc 接受请求
do_accept(Unique, Module, Method, DataIn, RoleID, Line) ->
    #m_friend_accept_tos{name=RequestName} = DataIn,
    case common_misc:get_roleid(RequestName) of
        {error, Reason} ->
            do_accept_error(Unique, Module, Method, RoleID, RequestName, Reason, Line);
        RequestID ->
            do_accept2(Unique, Module, Method, RoleID, RequestID, RequestName, Line)
    end.
do_accept2(Unique, Module, Method, RoleID, RequestID, RequestName, Line) ->
    %%是否接受过邀请
    case if_in_request_list(RoleID, RequestID) of
        true ->
            %%在请求列表中删除
            ets:delete_object(friend_request, {RoleID, RequestID}),
            %%friendtype, 之前的好友类型，只有可能是没关系或黑名单
            case if_can_accept(RoleID, RequestID) of
                {true, FriendType} ->
                    do_accept3(Unique, Module, Method, RoleID, RequestID, RequestName, FriendType, Line);
                {false, Reason} ->
                    do_accept_error(Unique, Module, Method, RoleID, RequestName, Reason, Line)
            end;
        false ->
            do_accept_error(Unique, Module, Method, RoleID, RequestName, ?_LANG_FRIEND_NO_REQUEST, Line)
    end.
do_accept3(Unique, Module, Method, RoleID, RequestID, RequestName, FriendType, Line) ->
    case db:transaction(
           fun() ->
                   t_do_accept(RoleID, RequestID, FriendType, 0)
           end)
    of
        {aborted, Reason} ->
            ?ERROR_MSG("do_accept3, reason: ~w", [Reason]),
            do_accept_error(Unique, Module, Method, RoleID, RequestName, ?_LANG_SYSTEM_ERROR, Line);
        {atomic, {SendSelf, SendOther}} ->
            %%通知客户端
            common_misc:unicast(Line, RoleID, Unique, Module, Method, SendSelf),
            case common_misc:is_role_online(RequestID) of
                true ->
                    common_misc:unicast({role, RequestID}, ?DEFAULT_UNIQUE, Module, Method, SendOther),
                    case FriendType of
                        %%如果原来是黑名单，则通知聊天进程删除黑名单
                        ?TYPE_BLACK ->
                            PID = common_misc:chat_get_role_pname(RequestID),
                            (catch global:send(PID, {del_black, RoleID}));
                        _ ->
                            ignore
                    end;
                _ ->
                    offline_add_list_insert(RequestID, {accept, RoleID})
            end,
            % (catch hook_add_friend:hook({RoleID, RequestID, RoleID})),
            friendly_add_notify(RoleID, RequestID, 999, 0)
    end.

do_accept_error(Unique, Module, Method, RoleID, TargetName, Reason, Line) ->
    R = #m_friend_accept_toc{succ=false, name=TargetName, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_refuse(Unique, Module, Method, DataIn, RoleID, Line) ->
    #m_friend_refuse_tos{name=RequestName} = DataIn,
    case common_misc:get_roleid(RequestName) of
        {error, Reason} ->
            do_refuse_error(Unique, Module, Method, RoleID, RequestName, Reason, Line);
        RequestID ->
            do_refuse2(Unique, Module, Method, RoleID, RequestID, RequestName, Line)
    end.
do_refuse2(Unique, Module, Method, RoleID, RequestID, RequestName, Line) ->
    %%对方是否发出过邀请
    case if_in_request_list(RoleID, RequestID) of
        true ->
            case common_misc:get_dirty_role_base(RoleID) of
                {ok, RoleBase} ->
                    ets:delete_object(friend_request, {RoleID, RequestID}),
                    SendOther = #m_friend_refuse_toc{return_self=false, name=RoleBase#p_role_base.role_name},
                    case common_misc:is_role_online(RequestID) of
                        true ->
                            common_misc:unicast({role, RequestID}, ?DEFAULT_UNIQUE, Module, Method, SendOther);
                        _ ->
                            offline_add_list_insert(RequestID, {refuse, RoleID})
                    end;
                _ ->
                    do_refuse_error(Unique, Module, Method, RoleID, RequestName, ?_LANG_SYSTEM_ERROR, Line)
            end;
        false ->
            do_refuse_error(Unique, Module, Method, RoleID, RequestName, ?_LANG_FRIEND_NO_REQUEST, Line)
    end.

do_refuse_error(Unique, Module, Method, RoleID, RequestName, Reason, Line) ->
    ?DEBUG("do_refuse_error, reason: ~w", [Reason]),
    R = #m_friend_refuse_toc{succ=false, reason=Reason, name=RequestName},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

do_black(Unique, Module, Method, DataIn, RoleID, Line) ->
    #m_friend_black_tos{name=TargetName} = DataIn,
    ?DEBUG("do_black, targetname: ~w", [TargetName]),
    case common_misc:get_roleid(TargetName) of
        {error, Reason} ->
            do_black_error(Unique, Module, Method, RoleID, Reason, Line);
        TargetID ->
            case TargetID =:= RoleID of
                true ->
                    do_black_error(Unique, Module, Method, RoleID, ?_LANG_FRIEND_BLACK_ADDSELF, Line);
                false ->
                    do_black2(Unique, Module, Method, RoleID, TargetID, Line, TargetName)
            end
    end.
%%添加仇人，如果之前是好友或仇人的话要删除原记录
do_black2(Unique, Module, Method, RoleID, TargetID, Line, TargetName) ->
    case if_can_add_black(RoleID, TargetID) of
        {false, Reason} ->
            do_black_error(Unique, Module, Method, RoleID, Reason, Line);
        {true, FriendType, FriendInfo} ->
            case db:transaction(
                  fun() ->
                          t_do_black(RoleID, TargetID, FriendType, FriendInfo)
                  end)
            of
                {aborted, R} ->
                    ?DEBUG("do_black2, r: ~w", [R]),
                    do_black_error(Unique, Module, Method, RoleID, ?_LANG_SYSTEM_ERROR, Line);
                {atomic, {DataRecord, RoleName}} ->
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord),

                    %%如果是好友，则通知客户端删去好友
                    case FriendType of
                        ?TYPE_FRIEND ->
                            SendTarget = #m_friend_black_toc{name=RoleName, return_self=false},
                            common_misc:unicast({role, TargetID}, ?DEFAULT_UNIQUE, Module, Method, SendTarget);
                        _ ->
                            ok
                    end,
                    
                    %%通知聊天进程添加黑名单
                    PID = common_misc:chat_get_role_pname(RoleName),
                    global:send(PID, {add_black, TargetName})
            end
    end.

do_black_error(Unique, Module, Method, RoleID, Reason, Line) ->
    ?DEBUG("do_black_error, reason: ~w", [Reason]),
    R = #m_friend_black_toc{succ=false, reason=Reason, return_self=true},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%% @doc 删除好友，特殊关系的好友需解除关系后方能删除
do_delete(Unique, Module, Method, DataIn, RoleID, PID) ->
    DataRecord =
        try
            #m_friend_delete_tos{roleid=DelFriendID} = DataIn,

            Pattern = #r_friend{roleid=RoleID, friendid=DelFriendID, _='_'},
            case db:dirty_match_object(?DB_FRIEND, Pattern) of
                [] ->
                    ok;
                [RFriend] ->
                    do_delete2(RoleID, DelFriendID, RFriend)
            end,
            #m_friend_delete_toc{roleid=DelFriendID}
        catch
            _:Reason when is_binary(Reason) ->
                #m_friend_delete_toc{succ=false, reason=Reason};
            _:Reason ->
                ?ERROR_MSG("do_delete, error: ~w", [Reason]),
                #m_friend_delete_toc{succ=false, reason=?_LANG_SYSTEM_ERROR}
        end,
    
    common_misc:unicast2(PID, Unique, Module, Method, DataRecord).

do_delete2(RoleID, DelFriendID, RFriend) ->
    #r_friend{relative=Rela, type=Type} = RFriend,
    case Rela of
        [] ->
            db:dirty_delete_object(?DB_FRIEND, RFriend),
            case Type of
                ?TYPE_FRIEND ->
                    Pattern = #r_friend{roleid=DelFriendID, friendid=RoleID, _='_'},
                    case db:dirty_match_object(?DB_FRIEND, Pattern) of
                        [] ->
                            ok;
                        [R] ->
                            db:dirty_delete_object(?DB_FRIEND, R),
                            ToFriend = #m_friend_delete_toc{return_self=false, type=?TYPE_FRIEND, roleid=RoleID},
                            common_misc:unicast({role, DelFriendID}, ?DEFAULT_UNIQUE, ?FRIEND, ?FRIEND_DELETE, ToFriend)
                    end;
                ?TYPE_BLACK ->
                    PID = common_misc:chat_get_role_pname(RoleID),
            catch global:send(PID, {del_black, DelFriendID});
                _ ->
                    ignore
            end,
            ok;
        _ ->
            throw(?_LANG_FRIEND_DEL_SPEC_RELA)
    end.

%%初始化
do_list(Unique, Module, Method, _DataIn, RoleID, Line) ->
    case get_friend_list(RoleID) of
        {error, R} ->
            do_list_error(Unique, Module, Method, RoleID, R, Line);
        FriendList ->
            try
                InfoList = 
                    lists:foldl(
                      fun(E,AccIn)->
                              #r_friend{friendid=FriendID, type=Type, friendly=Friendly, relative=Rela} = E,
                              case get_friend_info(FriendID, Type, Friendly, Rela) of
                                  undefined->
                                      AccIn;
                                  FInfo->
                                      [FInfo|AccIn]
                              end
                      end, [], FriendList),
                DataRecord = #m_friend_list_toc{friend_list=InfoList},
                common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord)
            catch
                _ : Reason ->
                    ?ERROR_MSG("do_list, reason: ~w", [Reason]),
                    do_list_error(Unique, Module, Method, RoleID, Reason, Line)
            end
    end.

do_list_error(Unique, Module, Method, RoleID, Reason, Line) ->
    ?DEBUG("do_list_error, reason: ~w", [Reason]),
    DataRecord = #m_friend_list_toc{succ=false, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord).

%%查看好友额外信息
do_info(Unique, Module, Method, DataIn, RoleID, Line) ->
    #m_friend_info_tos{roleid=TargetID} = DataIn,
    ?DEBUG("do_info, targetid: ~w", [TargetID]),
    R = 
        case get_friend_type(RoleID, TargetID) of
            {error, Reason} ->
                ?DEBUG("do_info, reason: ~w", [Reason]),
                #m_friend_info_toc{succ = false, reason = ?_LANG_SYSTEM_ERROR};
            {?TYPE_NORELA, _} ->
                #m_friend_info_toc{succ = false, reason = ?_LANG_FRIEND_NO_FRIEND};
            _ ->
                case common_misc:get_dirty_role_ext(TargetID) of
                    {ok, FriendExt} ->
                        case common_misc:get_dirty_role_attr(TargetID) of
                            {ok, FriendAttr} ->
                                Equip = FriendAttr#p_role_attr.equips,
                                #m_friend_info_toc{friend_info=FriendExt, equips=Equip};
                            {error, _} ->
                                #m_friend_info_toc{succ=false, reason=?_LANG_SYSTEM_ERROR}
                        end;
                    {error, _} ->
                        #m_friend_info_toc{succ=false, reason=?_LANG_SYSTEM_ERROR}
                end
        end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%%修改个人额外信息
do_modify(Unique, Module, Method, DataIn, RoleID, Line) ->
    #m_friend_modify_tos{info=RoleExt} = DataIn,
    ?DEBUG("do_modify, roleext: ~w", [RoleExt]),
    case db:transaction(
           fun() ->
                   t_do_modify(RoleID, RoleExt)
           end)
    of
        {atomic, _} ->
            ReturnSelf  = #m_friend_modify_toc{info=RoleExt},
            ToOther = #m_friend_modify_toc{return_self=false, info=RoleExt},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, ReturnSelf),
            %%广播给好友
            case get_in_friend_list(RoleID) of
                {error, _} ->
                    ok;
                FriendList ->
                    lists:foreach(
                      fun(FriendInfo) ->
                              #r_friend{roleid=FriendID} = FriendInfo,
                              common_misc:unicast({role, FriendID}, ?DEFAULT_UNIQUE, Module, Method, ToOther)
                      end, FriendList)
            end;
        {aborted, R} ->
            ?DEBUG("do_modify, r: ~w", [R]),
            ReturnSelf = #m_friend_modify_toc{succ=false, reason=?_LANG_SYSTEM_ERROR},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, ReturnSelf)
    end.

%% @doc 推荐好友
do_recommend(Unique, Module, Method, RoleID, Line) ->
    try
        Pattern = #r_role_online{_='_'},
        RoleList = db:dirty_match_object(?DB_USER_ONLINE, Pattern),

        RecommendList = get_recomment_list(RoleID, RoleList, []),

        DataRecord = #m_friend_recommend_toc{friend_info=RecommendList},
        common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord)
    catch
        _:R ->
            ?ERROR_MSG("do_recommend, r: ~w", [R]),
            DataRecord2 = #m_friend_recommend_toc{succ=false, reason=?_LANG_SYSTEM_ERROR},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord2)
    end.

%% @doc 好友祝福
do_congratula(Unique, Module, Method, DataIn, RoleID, PID) ->
    #m_friend_congratulation_tos{to_friend_id=ToFriendID, congratulation=Congra} = DataIn,

    case catch check_can_congratula(RoleID, ToFriendID) of
        ok ->
            do_congratula2(Unique, Module, Method, RoleID, ToFriendID, Congra, PID);
        {error, Reason} ->
            do_congratula_error(Unique, Module, Method, Reason, PID)
    end.

do_congratula2(Unique, Module, Method, RoleID, ToFriendID, Congra, PID) ->
	{FriendRoleLevel, CongratulaList} = get({?DICT_FRIEND_CONGRATULA, ToFriendID}),
    Counter = length(CongratulaList) + 1,
	
	case get({?DICT_SEND_FRIEND_CONGRATULA, RoleID}) of
		undefined ->
			#p_role_attr{level=RoleLevel} = mod_role_tab:get({?role_attr, RoleID}),
			SendCongratulaList = [];
		{RoleLevel, SendCongratulaList} ->
			next
	end,
    SendCounter = length(SendCongratulaList) + 1,
	
	#p_role_base{role_name=RoleName} = mod_role_tab:get({?role_base, RoleID}),
	#p_role_base{role_name=FriendName} = mod_role_tab:get({?role_base, ToFriendID}),
    %% 增加好友度
    [AddCongratulaFriendly] = common_config_dyn:find(friend,add_friendly_by_congratula),
    do_add_friendly(RoleID, ToFriendID, AddCongratulaFriendly, 3),
    %% 前10个发送祝福的好友能获得经验
	case Counter =< 10 of
		true ->
			FriendExpGet = calc_congratula_exp(FriendRoleLevel),
		    put({?DICT_FRIEND_CONGRATULA, ToFriendID}, {FriendRoleLevel, [RoleID|CongratulaList]}),
			catch common_misc:add_exp_unicast(ToFriendID, FriendExpGet);
		_ ->
			nil
	end,
	case SendCounter =< 10 of
		true ->
			ExpGet = calc_congratula_exp(RoleLevel),
		    put({?DICT_SEND_FRIEND_CONGRATULA, RoleID}, {RoleLevel, [ToFriendID|SendCongratulaList]}),
			catch common_misc:add_exp_unicast(RoleID, ExpGet);
		false ->
			nil
	end,
	ReturnSelf = #m_friend_congratulation_toc{from_friend=FriendName, hyd_add=AddCongratulaFriendly},
    ToFriend = #m_friend_congratulation_toc{return_self=false, hyd_add=AddCongratulaFriendly,
                                            from_friend=RoleName, congratulation=Congra},
    common_misc:unicast2(PID, Unique, Module, Method, ReturnSelf),
    common_misc:unicast({role, ToFriendID}, ?DEFAULT_UNIQUE, Module, Method, ToFriend).

%% <60级升级所需经验*0.2％
%% >=60级升级所需经验*0.13％ 
calc_congratula_exp(RoleLevel) ->
	Exp = 
		case common_config_dyn:find(level, RoleLevel) of
			[RecLevelExp] ->
				RecLevelExp#p_level_exp.exp;
			_ ->
				0
		end,
	if
		RoleLevel < 60 ->
			common_tool:floor(Exp * 0.002);
		RoleLevel >= 60 ->
			common_tool:floor(Exp * 0.0013);
		true ->
			0
	end.
    
do_congratula_error(Unique, Module, Method, Reason, PID) ->
    DataRecord = #m_friend_congratulation_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, DataRecord).

%% @doc 一键征友
do_advertise(Unique, Module, Method, RoleID, PID) ->
    case catch check_can_advertise(RoleID) of 
        ok ->
            common_misc:unicast2(PID, Unique, Module, Method, #m_friend_advertise_toc{}),
            case get_advertise_role_list() of
                [] ->
                    advertise_role_list_insert(RoleID);
                AdRoleList ->
                    do_advertise2(RoleID, AdRoleList)
            end;
        {error, Reason} when is_binary(Reason) ->
            DataRecord = #m_friend_advertise_toc{succ=false, reason=Reason},
            common_misc:unicast2(PID, Unique, Module, Method, DataRecord);
        Error ->
            ?ERROR_MSG("do_advertise, error: ~w", [{Error}]),
            DataRecord = #m_friend_advertise_toc{succ=false, reason=?_LANG_SYSTEM_ERROR},
            common_misc:unicast2(PID, Unique, Module, Method, DataRecord)
    end.

do_advertise2(RoleID, [{RoleID, _}|T]) ->
    do_advertise2(RoleID, T);
do_advertise2(RoleID, [{FriendID, _}|T]) ->
    case if_can_accept(RoleID, FriendID) of
        {true, _} ->
            case do_add_friend(RoleID, FriendID, []) of 
                ok ->
                    advertise_role_list_delete(FriendID);
                _ ->
                    do_advertise2(RoleID, T)
            end;
        _ ->
            do_advertise2(RoleID, T)
    end;
do_advertise2(RoleID, []) ->
    advertise_role_list_insert(RoleID).

%% @doc 是否可以一鍵征友
check_can_advertise(RoleID) ->
    case if_friend_full(RoleID) of 
        true ->
            ok;
        {false, Reason} ->
            erlang:throw({error, Reason})
    end.

%% @doc 判断是否要发送祝福
check_can_congratula(RoleID, ToFriendID) ->
    {_FriendLevel, CongratulaList} =
        case get({?DICT_FRIEND_CONGRATULA, ToFriendID}) of
            undefined ->
                throw({error, ?_LANG_FRIEND_CONGRATULA_TIME_PASS});
            {L, C} ->
                {L, C}
        end,

    case lists:member(RoleID, CongratulaList) of
        true ->
            throw({error, ?_LANG_FRIEND_CONGRATULA_EVER_CONGRATULA});
        _ ->
            ok
    end,

    case get_friend_type(RoleID, ToFriendID) of
        {?TYPE_FRIEND, _} ->
            ok;
        _ ->
            throw({error, ?_LANG_FRIEND_CONGRATULA_NOT_YOUR_FRIEND})
    end,

    ok.

t_do_modify(RoleID, RoleExt) ->
	OldRoleExt = mod_role_tab:get({role_ext, RoleID}),
    #p_role_ext{signature=Sign, birthday=Birthday, constellation=Constell,
     country=Country, province=Province, city=City, sex=Sex} = RoleExt,
    NewRoleExt = OldRoleExt#p_role_ext{signature=Sign, birthday=Birthday, constellation=Constell,
                                       country=Country, province=Province, city=City, sex=Sex},
    mod_role_tab:put({?role_attr, RoleID}, NewRoleExt).

%%如果原来在黑名单中要删除原记录
t_add_enemy(RoleID, TargetID, FriendType) ->
    case FriendType of
        ?TYPE_BLACK ->
            t_delete_friend(RoleID, TargetID, FriendType, 0, []);
        _ ->
            ok
    end,
    t_add_friend(RoleID, TargetID, ?TYPE_ENEMY, 0, []),
    FriendList = 
        case get_friend_list(RoleID, ?TYPE_ENEMY) of
            {error, R} ->
                db:abort(R);
            List ->
                List
        end,
    case length(FriendList) >= ?ENEMY_LIMITED of
        true ->
            [H | _T] = FriendList,
            t_delete_friend(H);
        false ->
            ok
    end,
    #m_friend_enemy_toc{enemy_info=get_friend_info(TargetID, ?TYPE_ENEMY, 0, [])}.

%%是否能添加仇人，好友不加入仇人
if_can_add_enemy(RoleID, TargetID, TargetType) ->
    case RoleID =:= TargetID of
        true ->
            {false, ?_LANG_FRIEND_ENEMY_ADD_FRIEND};
        _ ->
            case TargetType of
                role ->
                    case get_friend_type(RoleID, TargetID) of
                        {error, R} ->
                            {false, R};
                        {?TYPE_ENEMY, _} ->
                            {false, ?_LANG_FRIEND_ALREADY_ENEMY};
                        {?TYPE_FRIEND, _} ->
                            {false, ?_LANG_FRIEND_ENEMY_FRIEND};
                        {FriendType, _} ->
                            {true, FriendType}
                    end;
                _ ->
                    {false, ?_LANG_FRIEND_ENEMY_BAD_TYPE}
            end
    end.

if_online(RoleID) ->
    case db:dirty_read(?DB_USER_ONLINE, RoleID) of
        [] ->
            false;
        _ ->
            true
    end.

t_do_black(RoleID, TargetID, FriendType, FriendInfo) ->
    case FriendType of
        ?TYPE_FRIEND ->
            t_delete_friend(FriendInfo),
            FriendInfo2 = t_get_friend_info(TargetID, RoleID),
            t_delete_friend(FriendInfo2);
        ?TYPE_ENEMY ->
            t_delete_friend(FriendInfo);
        _ ->
            ok
    end,
    t_add_friend(RoleID, TargetID, ?TYPE_BLACK, 0, []),
    %%超过人数限制，则删除最早的记录
    FriendList = 
        case get_friend_list(RoleID, ?TYPE_BLACK) of
            {error, R} ->
                db:abort(R);
            List ->
                List
        end,
    case length(FriendList) >= ?BLACK_LIMITED of
        true ->
            [H | _T] = FriendList,
            t_delete_friend(H);
        false ->
            ok
    end,
    RoleBase = mod_role_tab:get({?role_base, RoleID}),
    {#m_friend_black_toc{friend_info=get_friend_info(TargetID, ?TYPE_BLACK, 0, []), return_self=true},
     RoleBase#p_role_base.role_name}.

if_can_add_black(RoleID, TargetID) ->
    case get_friend_type(RoleID, TargetID) of
        {error, Reason} ->
            {false, Reason};
        {?TYPE_BLACK, _} ->
            {false, ?_LANG_FRIEND_BLACK_ALREADY};
        {?TYPE_NORELA, _} ->
            {true, ?TYPE_NORELA, 0};
        {FriendType, FriendInfo} ->
            case FriendInfo#r_friend.relative of
                [] ->
                    {true, FriendType, FriendInfo};
                _ ->
                    {false, ?_LANG_FRIEND_BLACK_SPEC_RELA}
            end
    end.

t_do_accept(RoleID, TargetID, FriendType, Relative) ->
    case FriendType of
        %%如果原来是在黑名单中，则应删除该纪录
        ?TYPE_BLACK ->
            t_delete_friend(TargetID, RoleID, ?TYPE_BLACK, 0, []);
        ?TYPE_FRIEND when Relative =/= 0 ->
            FriendInfo = t_get_friend_info(RoleID, TargetID),
            FriendInfo2 = t_get_friend_info(TargetID, RoleID),
            t_delete_friend(FriendInfo),
            t_delete_friend(FriendInfo2);
        _ ->
            ok
    end,

    case Relative of
        1 ->
            t_add_friend(RoleID, TargetID, ?TYPE_FRIEND, 0, [2]),
            t_add_friend(TargetID, RoleID, ?TYPE_FRIEND, 0, [1]),
            Rela1 = [2],
            Rela2 = [1];
        _ ->
            t_add_friend(RoleID, TargetID, ?TYPE_FRIEND, 0, []),
            t_add_friend(TargetID, RoleID, ?TYPE_FRIEND, 0, []),
            Rela1 = [],
            Rela2 = []
    end,       

    {#m_friend_accept_toc{friend_info=get_friend_info(TargetID, ?TYPE_FRIEND, 0, Rela1)},
     #m_friend_accept_toc{friend_info=get_friend_info(RoleID, ?TYPE_FRIEND, 0, Rela2), return_self=false}}.

t_delete_friend(Record) ->
    db:delete_object(?DB_FRIEND, Record, write).

t_delete_friend(RoleID, FriendID, FriendType, Friendly, Relative) ->                
    Record = #r_friend{roleid = RoleID, friendid = FriendID, type = FriendType, friendly = Friendly, relative=Relative},
    db:delete_object(?DB_FRIEND, Record, write).

t_add_friend(RoleID, FriendID, FriendType, Friendly, Relative) ->
    Record = #r_friend{roleid = RoleID, friendid = FriendID, type = FriendType, friendly = Friendly, relative=Relative},
    db:write(?DB_FRIEND, Record, write).

get_friend_info(FriendID, FriendType, Friendly, Rela) ->
    try
        case db:dirty_read(?DB_ROLE_BASE, FriendID) of
            [FriendBase]->
                case db:dirty_read(?DB_ROLE_ATTR, FriendID) of
                    [FriendAttr]->
                        case db:dirty_read(?DB_ROLE_EXT, FriendID) of
                            [FriendExt] ->
				Vip_level2=
					case db:dirty_read(?DB_ROLE_VIP_P, FriendID) of
						[#r_role_vip{vip_level=Vip_level}] ->
							Vip_level;
						_ ->
							0
					end,
                                #p_friend_info{
                                               roleid=FriendID,
                                               rolename=FriendBase#p_role_base.role_name,
                                               type=FriendType,
                                               faction_id=FriendBase#p_role_base.faction_id,
                                               sex=FriendBase#p_role_base.sex,
                                               family_name=FriendBase#p_role_base.family_name,
                                               level=FriendAttr#p_role_attr.level,
                                               friendly=Friendly,
                                               is_online=if_online(FriendID),
                                               sign=FriendExt#p_role_ext.signature,
                                               relative=Rela,
                                               head=FriendBase#p_role_base.head,
										       birthday=FriendExt#p_role_ext.birthday,
										       province=FriendExt#p_role_ext.province,
										       vip_level=Vip_level2,
										       city=FriendExt#p_role_ext.city,
											   category=FriendAttr#p_role_attr.category
                                              };
                            _ ->
                                undefined
                        end;
                    _ ->
                        undefined
                end;
            _ ->
                undefined
        end
    catch
        _ : R ->
            ?ERROR_MSG("get_friend_info, friendid: ~w, r: ~w", [FriendID, R]),
            throw(?_LANG_SYSTEM_ERROR)
    end.

%%检测基本跟好友请求一样
if_can_accept(RoleID, TargetID) ->
    case if_friend_full(RoleID) of
        true ->
            case if_friend_full(TargetID) of
                true ->
                    if_can_accept2(RoleID, TargetID, true);
                {false, R} ->
                    ?DEBUG("if_can_request, reason: ~w", [R]),
                    {false, ?_LANG_FRIEND_TARGET_FULL}
            end;
        {false, Reason} ->
            {false, Reason}
    end.
%%特殊处理下吧。。。FLAG, true: 正常加好友，false: 特殊方式
if_can_accept2(RoleID, TargetID, Flag) ->
    case get_friend_type(RoleID, TargetID) of
        {error, Reason} ->
            {false, Reason};
        {?TYPE_FRIEND, _} ->
            case Flag of
                true ->
                    {false, ?_LANG_FRIEND_FRIEND_ALREADY};
                false ->
                    {true, ?TYPE_FRIEND}
            end;
        {?TYPE_ENEMY, _} ->
            {false, ?_LANG_FRIEND_IN_ENEMY};
        {?TYPE_BLACK, _} ->
            {false, ?_LANG_FRIEND_IN_BLACK};
        _ ->
            if_can_accept3(RoleID, TargetID)
    end.
if_can_accept3(RoleID, TargetID) ->
    case get_friend_type(TargetID, RoleID) of
        {error, Reason} ->
            {false, Reason};
        {?TYPE_ENEMY, _} ->
            {false, ?_LANG_FRIEND_IN_TARGET_ENEMY};
        {FriendType, _} ->
            %%如果是好友的话返回当前类型，以处处理
            {true, FriendType}
    end.

%% @doc 是否已经在请求列表中
if_in_request_list(RoleID, TargetID) ->
    RequestList = ets:lookup(friend_request, RoleID),
    lists:member({RoleID, TargetID}, RequestList).

%% @doc 检测能否发送好友请求
if_can_request(RoleID, TargetID) ->
    case if_friend_full(RoleID) of
        true ->
            case if_friend_full(TargetID) of
                true ->
                    if_can_request2(RoleID, TargetID);
                {false, _R} ->
                    {false, ?_LANG_FRIEND_TARGET_FULL}
            end;
        {false, Reason} ->
            {false, Reason}
    end.
%%不能添加敌人为好友，如果自己在对方的黑名单中也不能添加
if_can_request2(RoleID, TargetID) ->
    case get_friend_type(RoleID, TargetID) of
        {error, Reason} ->
            {false, Reason};
        {?TYPE_FRIEND, _} ->
            {false, ?_LANG_FRIEND_FRIEND_ALREADY};
        {?TYPE_ENEMY, _} ->
            {false, ?_LANG_FRIEND_TARGET_ENEMY};
        _ ->
            if_can_request3(RoleID, TargetID)
    end.
if_can_request3(RoleID, TargetID) ->
    case get_friend_type(TargetID, RoleID) of
        {error, Reason} ->
            {false, Reason};
        {?TYPE_BLACK, _} ->
            {false, ?_LANG_FRIEND_IN_TARGET_BLACK};
        {?TYPE_ENEMY, _} ->
            {false, ?_LANG_FRIEND_IN_TARGET_ENEMY};
        _ ->
            true
    end.

t_get_friend_info(RoleID, FriendID) ->
    Pattern = #r_friend{roleid=RoleID, friendid=FriendID, _='_'},
    [FriendInfo] = db:match_object(?DB_FRIEND, Pattern, write),
    FriendInfo.

%% @doc 赃读好友详细信息
get_dirty_friend_info(RoleID, FriendID) ->
    Pattern = #r_friend{roleid=RoleID, friendid=FriendID, _='_'},
    [FriendInfo] = db:dirty_match_object(?DB_FRIEND, Pattern),
    FriendInfo.

get_friend_type(RoleID, FriendID) ->
    Pattern = #r_friend{roleid = RoleID, friendid = FriendID, _ = '_'},
    case catch db:dirty_match_object(?DB_FRIEND, Pattern) of
        {'EXIT', _} ->
            {error, ?_LANG_SYSTEM_ERROR};
        [] ->
            {?TYPE_NORELA, 0};
        [FriendInfo] ->
            {FriendInfo#r_friend.type, FriendInfo}
    end.    

if_friend_full(RoleID) ->
    case get_friend_list(RoleID, ?TYPE_FRIEND) of
        {error, Reason} ->
            {false, Reason};
        FriendList ->
            case length(FriendList) < ?FRIEND_NUM_LIMITED of
                true ->
                    true;
                false ->
                    {false, ?_LANG_FRIEND_FRIEND_FULL}
            end
    end.

get_friend_list(RoleID) ->
    case db:dirty_read(?DB_FRIEND, RoleID) of
        {'EXIT', R} ->
            ?DEBUG("get_friend_list, reason: ~w", [R]),
            {error, ?_LANG_SYSTEM_ERROR};
        FriendList ->
            FriendList
    end.

get_dirty_friend_list(RoleID) ->
    get_friend_list(RoleID, ?TYPE_FRIEND).

get_friend_list(RoleID, FriendType) ->
    Pattern = #r_friend{roleid = RoleID, type = FriendType, _ = '_'},
    case catch db:dirty_match_object(?DB_FRIEND, Pattern) of
        {'EXIT', R} ->
            ?DEBUG("get_friend_list, r: ~w", [R]),
            {error, ?_LANG_SYSTEM_ERROR};
        FriendList ->
            FriendList
    end.

%% @doc 在别人的列表
get_in_friend_list(RoleID) ->
    Pattern = #r_friend{friendid=RoleID, _='_'},

    case catch db:dirty_match_object(?DB_FRIEND, Pattern) of
        {'EXIT', _} ->
            {error, ?_LANG_SYSTEM_ERROR};
        FriendList ->
            FriendList
    end.

%% @doc 获取推荐列表
get_recomment_list(_RoleID, [], RecommentList) ->
    RecommentList;
get_recomment_list(RoleID, [#r_role_online{role_id=TRoleID}|T], RecommentList) ->
    case RoleID =:= TRoleID of
        true ->
            get_recomment_list(RoleID, T, RecommentList);
        _ ->
            case erlang:length(RecommentList) >= 5 of
                true ->
                    RecommentList;
                _ ->
                    case if_select(30) of
                        true ->
                            [TRoleAttr] = db:dirty_read(?DB_ROLE_ATTR, TRoleID),
							[TRoleBase] = db:dirty_read(?DB_ROLE_BASE, TRoleID),
                            #p_role_attr{role_name=TRoleName, level=TLevel} = TRoleAttr,
                            #p_role_base{faction_id=FactionID,family_name=FamilyName} = TRoleBase,
                            RecommentList2 = [#p_recommend_member_info{role_id=TRoleID,
																	   faction_id=FactionID,
																	   family_name=FamilyName,
																	    role_name=TRoleName, level=TLevel}|RecommentList],
                            get_recomment_list(RoleID, T, RecommentList2);
                        _ ->
                            get_recomment_list(RoleID, T, RecommentList)	
                    end
            end
    end.
                            
%% @doc 是否选中
if_select(Rate) ->
    Rate =< random:uniform(100).

%% @doc 好友等级变动提示
%% 暂时屏蔽
friendly_add_notify(_RoleID, _FriendID, _Friendly, _Friendly2) ->
%%     #r_friend_base_info{friend_level = FriendLevel} = get_friend_base_info_by_friendly(Friendly),
%%     #r_friend_base_info{friend_level = FriendLevel2,friend_title = Desc,add_attr = AttackAdd} = get_friend_base_info_by_friendly(Friendly2),
%%     case FriendLevel =:= FriendLevel2 of
%%         true ->
%%             ignore;
%%         _ ->
%%             {ok, {SelfLetter, FriendLetter}, {SelfMsg, FriendMsg}} = get_notify_letter_and_msg(RoleID, FriendID, Desc, AttackAdd),
%%             %% 添加好友时做特殊处理，交友时如果当前好友列表不为空，则不发信息
%%             case Friendly2 of
%%                 0 ->
%%                     case if_send_notify_letter(RoleID) of
%%                         true ->
%%                             %% 信件
%%                             common_letter:sys2p(RoleID, SelfLetter, ?_LANG_FRIEND_LETTER_TITLE, 1);
%%                         _ ->
%%                             ignore
%%                     end,
%%                     case if_send_notify_letter(FriendID) of
%%                         true ->
%%                             common_letter:sys2p(FriendID, FriendLetter, ?_LANG_FRIEND_LETTER_TITLE, 1);
%%                         _ ->
%%                             ignore
%%                     end;
%%                 _ ->
%%                     common_letter:sys2p(RoleID, SelfLetter, ?_LANG_FRIEND_LETTER_TITLE, 1),
%%                     common_letter:sys2p(FriendID, FriendLetter, ?_LANG_FRIEND_LETTER_TITLE, 1)
%%             end,
%%             %% 提示，两人国家不同不给提示
%%             case if_send_notify_msg(RoleID, FriendID) of
%%                 true ->
%%                     common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, SelfMsg),
%%                     common_broadcast:bc_send_msg_role(FriendID, ?BC_MSG_TYPE_SYSTEM, FriendMsg);
%%                 _ ->
%%                     ignore
%%             end
%%     end,
    ok.

%% @doc 是否发送系统提示
%% if_send_notify_msg(RoleID, FriendID) ->
%%     {ok, #p_role_base{faction_id=FactionID}} = common_misc:get_dirty_role_base(RoleID),
%%     {ok, #p_role_base{faction_id=FriendFactionID}} = common_misc:get_dirty_role_base(FriendID),
%%      
%%     FactionID =:= FriendFactionID.

%% @doc 是否发送提示信件
%% if_send_notify_letter(RoleID) ->
%%     case get_friend_list(RoleID, ?TYPE_FRIEND) of
%%         [_] ->
%%             true;
%%         _ ->
%%             false
%%     end.

%% 根据好友度获得好友配置基本信息记录
get_friend_base_info_by_friendly(Friendly) ->
    [FriendBaseInfoList] = common_config_dyn:find(friend,friend_base_info),
    case lists:foldl(
           fun(FriendBaseInfo,AccFriendBaseInfo) ->
                   case AccFriendBaseInfo =:= undefined andalso Friendly >=  FriendBaseInfo#r_friend_base_info.min_friendly
                       andalso Friendly =< FriendBaseInfo#r_friend_base_info.max_friendly of
                       true ->
                           FriendBaseInfo;
                       _ ->
                           AccFriendBaseInfo
                   end
           end,undefined,FriendBaseInfoList) of
        undefined ->
            case FriendBaseInfoList =/= [] of
                true ->
                    lists:nth(1,FriendBaseInfoList);
                _ ->
                    undefined
            end;
        AccFriendBaseInfoT ->
            AccFriendBaseInfoT
    end.

%% @doc 获取信件及提示信息
%% get_notify_letter_and_msg(RoleID, FriendID, Desc, AttackAdd) ->
%%     {ok, #p_role_base{role_name=RoleName}} = common_misc:get_dirty_role_base(RoleID),
%%     {ok, #p_role_base{role_name=FriendName}} = common_misc:get_dirty_role_base(FriendID),
%%     
%%     {ok,
%%      {common_letter:create_temp(?FRIEND_LEVEL_CHANGE_LETTER,[RoleName, FriendName, Desc, AttackAdd]),
%%       common_letter:create_temp(?FRIEND_LEVEL_CHANGE_LETTER,[FriendName, RoleName, Desc, AttackAdd])},
%%      {common_tool:get_format_lang_resources(?_LANG_FRIEND_LEVEL_CHANGE_MESSAGE, [FriendName, Desc, AttackAdd]),
%%       common_tool:get_format_lang_resources(?_LANG_FRIEND_LEVEL_CHANGE_MESSAGE, [RoleName, Desc, AttackAdd])}}.

%% @doc 开通VIP通知好友
do_vip_active(RoleID, RoleName, _VipLevel) ->
    case get_dirty_friend_list(RoleID) of
        {error, _} ->
            ignore;
        FriendList ->
            Notice = lists:flatten(io_lib:format(?_LANG_VIP_ACTIVE_FRINED, [RoleName])),
            lists:foreach(
              fun(#r_friend{friendid=FriendID}) ->
                      common_broadcast:bc_send_msg_role(FriendID, ?BC_MSG_TYPE_POP, Notice)
              end, FriendList)
    end.

check_is_friend(RoleId,FriendRoleId) ->
    case db:dirty_match_object(?DB_FRIEND,#r_friend{roleid=RoleId, friendid=FriendRoleId, _='_'}) of
        [FriendInfo] when erlang:is_record(FriendInfo,r_friend) ->
            true;
        _ ->
            false
    end.

%% 送花增加好友度处理
do_give_flower(GiveRoleId,ReceiveRoleId,FlowerItemId) ->
    %% 判断是否是好友
    ?DEBUG("~ts,GiveRoleId=~w,ReceiveRoleId=~w,FlowerItemId=~w",["送花增加好友度处理",GiveRoleId,ReceiveRoleId,FlowerItemId]),
    case db:dirty_match_object(?DB_FRIEND,#r_friend{roleid=GiveRoleId, friendid=ReceiveRoleId, _='_'}) of
        [FriendInfo] when erlang:is_record(FriendInfo,r_friend) ->
            [FlowerList] = common_config_dyn:find(friend,add_friendly_by_flower),
            case lists:keyfind(FlowerItemId,1,FlowerList) of
                {FlowerItemId,Add} ->
                    do_add_friendly(GiveRoleId,ReceiveRoleId, Add, 3);
                _ ->
                    ignore
            end;
        _ ->
            false
    end.
%% 副本增加好友度处理
do_fb_activity(RoleIdList,FbType) ->
    ?DEBUG("~ts,RoleIdList=~w,FbType=~w",["副本增加好友度处理",RoleIdList,FbType]),
    FriendList = [{RoleIdA, RoleIdB} 
                  || RoleIdA <- RoleIdList,
                     RoleIdB <- RoleIdList,
                     RoleIdA =/= RoleIdB,
                     check_is_friend(RoleIdA,RoleIdB) =:= true
                 ],
    %% 过虑
    FriendList2 = 
        lists:foldl(
          fun({RoleIdAT,RoleIdBT},AccFriendList) ->
                  case lists:member({RoleIdAT,RoleIdBT},AccFriendList) 
                      orelse lists:member({RoleIdBT,RoleIdAT},AccFriendList) of
                      true ->
                          AccFriendList;
                      _ ->
                          [{RoleIdAT,RoleIdBT}|AccFriendList]
                  end           
          end,[],FriendList),
    ?DEBUG("~ts,FriendList=~w,FriendList2=~w",["副本增加好友度处理",FriendList,FriendList2]),
    [{FbAdd,_FbTimes}] = common_config_dyn:find(friend,add_friendly_by_fb),
    lists:foreach(
      fun(RoleIdC,RoleIdD) ->
              do_add_friendly(RoleIdC,RoleIdD,FbAdd,4)
      end,FriendList),
    ok.

%% ========================================================
%% 征友列表相关操作
%% ===========================start

set_advertise_role_list(RoleIDList) ->
    ?ERROR_MSG("~w", [{RoleIDList}]),
    erlang:put(?AD_ROLE_LIST, RoleIDList).

get_advertise_role_list() ->
    case erlang:get(?AD_ROLE_LIST) of
        undefined ->
            [];
        L ->
            L
    end.

advertise_role_list_insert(RoleID) ->
    L = get_advertise_role_list(),
    RequestCount =
        lists:foldl(
          fun({ID, _}, Acc) ->
                  case ID =:= RoleID of
                      true ->
                          Acc + 1;
                      _ ->
                          Acc
                  end
          end, 0, L),
    case RequestCount > ?MAX_ADVERTISE_REQUEST of
        true ->
            igore;
        _ ->
            set_advertise_role_list([{RoleID, RequestCount+1}|L])
    end.

advertise_role_list_delete(RoleID) ->
    L = get_advertise_role_list(),
    set_advertise_role_list(lists:keydelete(RoleID, 1, L)).

%% ===========================end

%% ========================================================
%% 离线被加好友相关操作
%% ===========================start

get_offline_add_list(RoleID) ->
    case erlang:get({?OFFLINE_ADD_LIST, RoleID}) of
        undefined ->
            [];
        L ->
            L
    end.

set_offline_add_list(RoleID, List) ->
    erlang:put({?OFFLINE_ADD_LIST, RoleID}, List).

offline_add_list_insert(RoleID, {Type, TargetID}) ->
    L = get_offline_add_list(RoleID),
    set_offline_add_list(RoleID, [{Type, TargetID}|L]).

offline_add_list_clear(RoleID) ->
    erlang:erase({?OFFLINE_ADD_LIST, RoleID}).

%% ===========================end
