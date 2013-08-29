%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     家族押镖车模块
%%%     注意:: 该模块属于mod_family的子模块，只能在mod_family中被调用！
%%% @end
%%% Created : 2011-01-10
%%%-------------------------------------------------------------------
-module(mod_family_ybc).
-include("mgeew.hrl").
-include("mgeew_family.hrl").

%% 家族拉镖的最小等级
-define(FAMILY_YBC_MIN_LEVEL, 25).

%% 家族镖车相关宏
-define(ybc_roleinfo_list, ybc_roleinfo_list).
-define(ybc_roleinfo_list_last_update_time, ybc_roleinfo_list_last_update_time).

%% API
-export([
         do_handle_info/1,
         check_ybc_status/0
        ]).
-export([method_list/0,msg_tag/0]).


%% 定时检查家族镖的状态
check_ybc_status() ->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    FamilyExt = State#family_state.ext_info,
    case common_tool:now() - FamilyInfo#p_family_info.ybc_begin_time > 7200 
        andalso (FamilyInfo#p_family_info.ybc_begin_time > 0 andalso FamilyExt#r_family_ext.ybc_id >0 ) of
        true ->
            do_ybc_timeout(),
            ok;
        false ->
            ignore
    end.


%% ====================================================================
%% API functions
%% ====================================================================

%%注意，家族拉镖的接口Method和MsgTag都必须同时在此同步！
method_list()->
    [?FAMILY_YBC_PUBLISH,
     ?FAMILY_YBC_LIST,
     ?FAMILY_YBC_COMMIT,
     ?FAMILY_YBC_AGREE_PUBLISH,
     ?FAMILY_YBC_COLLECT,
     ?FAMILY_YBC_ACCEPT_COLLECT,
     ?FAMILY_YBC_KICK,
     ?FAMILY_YBC_ADD_HP,
     ?FAMILY_YBC_ALERT,
     ?FAMILY_YBC_SURE,
     ?FAMILY_YBC_GIVEUP,
     ?FAMILY_YBC_INVITE
    ].
msg_tag()->
    [ybc_agree_publish_succ,
     ybc_agree_publish_failed,
     ybc_agree_publish_timeout,
     ybc_timeout,
     ybc_time_out,
     ybc_publish_succ,
     ybc_publish_failed,
     ybc_publish_timeout,
     ybc_sure_succ,
     ybc_sure_failed,
     ybc_sure_timeout,
     ybc_dead,
     ybc_commit_succ,
     ybc_commit_error,
     ybc_commit_timeout].


%% 申请发布镖车
do_handle_info({Unique, Module, ?FAMILY_YBC_PUBLISH, Record, RoleID, PID, _Line}) ->
    do_ybc_publish(Unique, Module, ?FAMILY_YBC_PUBLISH, Record, RoleID, PID);
do_handle_info({Unique, Module, ?FAMILY_YBC_LIST, _, RoleID, PID, _Line}) ->
    do_ybc_list(Unique, Module, ?FAMILY_YBC_LIST, RoleID, PID);
do_handle_info({Unique, Module, ?FAMILY_YBC_COMMIT, _, RoleID, PID, _Line}) ->
    do_ybc_commit(Unique, Module, ?FAMILY_YBC_COMMIT, RoleID, PID);
do_handle_info({Unique, Module, ?FAMILY_YBC_AGREE_PUBLISH, _, RoleID, PID, _Line}) ->
    do_ybc_agree_publish(Unique, Module, ?FAMILY_YBC_AGREE_PUBLISH, RoleID, PID);
do_handle_info({Unique, Module, ?FAMILY_YBC_COLLECT, Record, RoleID, PID, _Line}) ->
    do_ybc_collect(Unique, Module, ?FAMILY_YBC_COLLECT, Record, RoleID, PID);
do_handle_info({Unique, Module, ?FAMILY_YBC_ACCEPT_COLLECT, _, RoleID, PID, _Line}) ->
    do_ybc_agree_collect(Unique, Module, ?FAMILY_YBC_ACCEPT_COLLECT, RoleID, PID);
do_handle_info({Unique, Module, ?FAMILY_YBC_KICK, Record, RoleID, PID, _Line}) ->
    do_ybc_kick(Unique, Module, ?FAMILY_YBC_KICK, Record, RoleID, PID);
do_handle_info({Unique, Module, ?FAMILY_YBC_ADD_HP, Record, RoleID, PID}) ->
    do_ybc_add_hp(Unique, Module, ?FAMILY_YBC_ADD_HP, Record, RoleID, PID);
do_handle_info({Unique, Module, ?FAMILY_YBC_ALERT, Record, RoleID, PID, _Line}) ->
    do_ybc_alert(Unique, Module, ?FAMILY_YBC_ALERT, Record, RoleID, PID);
do_handle_info({Unique, Module, ?FAMILY_YBC_SURE, _R, RoleID, PID, _Line}) ->
    do_ybc_sure(Unique, Module, ?FAMILY_YBC_SURE, RoleID, PID);
do_handle_info({Unique, Module, ?FAMILY_YBC_GIVEUP, _, RoleID, PID, _Line}) ->
    do_ybc_giveup(Unique, Module, ?FAMILY_YBC_GIVEUP, RoleID, PID);
do_handle_info({Unique, Module, ?FAMILY_YBC_INVITE, _, RoleID, PID, _Line}) ->
    do_ybc_invite(Unique, Module, ?FAMILY_YBC_INVITE, RoleID, PID);


%% 玩家同意加入镖车队伍成功
do_handle_info({ybc_agree_publish_succ, RoleID, RoleAttr, NeedSilver}) ->
    do_ybc_agree_publish_succ(RoleID, RoleAttr, NeedSilver);
do_handle_info({ybc_agree_publish_failed, RoleID, Reason}) ->
    do_ybc_agree_publish_failed(RoleID, Reason);
do_handle_info({ybc_agree_publish_timeout, RoleID}) ->
    do_ybc_agree_publish_timeout(RoleID);

%% 镖车超过24消失了
do_handle_info({ybc_timeout, RoleList}) ->
    do_ybc_timeout(RoleList);

do_handle_info({ybc_time_out}) ->
    do_ybc_timeout();

do_handle_info({ybc_publish_succ, RoleAttr}) ->
    do_ybc_publish_succ(RoleAttr);
do_handle_info({ybc_publish_failed, Reason}) ->
    do_ybc_publish_failed(Reason);
do_handle_info({ybc_publish_timeout}) ->
    do_ybc_publish_timeout();


do_handle_info({ybc_sure_succ, YbcID}) ->
    do_ybc_sure_succ(YbcID);
do_handle_info({ybc_sure_failed, Reason}) ->
    do_ybc_sure_failed(Reason);
do_handle_info({ybc_sure_timeout}) ->
    do_ybc_sure_timeout();
do_handle_info({ybc_dead, YbcID, RoleList}) ->
    do_ybc_dead(YbcID, RoleList);

do_handle_info({ybc_commit_succ, AllRoleList, RoleList, Timeout}) ->
    do_ybc_commit_succ(AllRoleList, RoleList, Timeout);

do_handle_info({ybc_commit_error, Reason}) ->
    do_ybc_commit_failed(Reason);

do_handle_info({ybc_commit_timeout}) ->
    do_ybc_commit_timeout();

do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知信息", Info]).


%% ====================================================================
%% Internal functions
%% ====================================================================

%% 获取国运状态
get_faction_status() ->
    1.


%% 获取所有大于等于某个等级的家族成员列表
get_all_member_level_than_except(Level) ->
    State = mod_family:get_state(),
    Members = State#family_state.family_members,
    lists:foldl(
      fun(#p_family_member_info{role_id=RID, role_level=Lv}, Acc) ->
              case Lv >= Level of
                  true ->
                      [RID | Acc];
                  false ->
                      Acc
              end
      end, [], Members).

%% --------------------- 镖车 -------------------- %%

%% 家族自动通知镖车过期了
do_ybc_timeout() ->
    State = mod_family:get_state(),
    FamilyExt = State#family_state.ext_info,
    FamilyInfo = State#family_state.family_info,
    YbcID = FamilyExt#r_family_ext.ybc_id,    
    log_family_ybc(YbcID,"镖车超过24小时消失了"),
    case db:dirty_read(db_ybc, YbcID) of
        [#r_ybc{role_list=RoleList}] ->
            R = #m_family_ybc_commit_toc{succ=false, reason=?_LANG_FAMILY_YBC_TIME_OUT_24_HOUR},
            lists:foreach(
              fun({RID, _RName, _Level, _SB, _B}) ->
                      db:transaction(fun() -> [RoleState] = db:read(?DB_ROLE_STATE, RID, write),
                                              db:write(?DB_ROLE_STATE, RoleState#r_role_state{ybc=undefined}, write)
                                     end),
                      common_misc:unicast({role, RID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_YBC_COMMIT, R)
              end, RoleList),
            {Date, _} = erlang:localtime(),
            do_ybc_timeout_del(YbcID),
            mod_family:broadcast_to_all_members(?FAMILY, ?FAMILY_YBC_STATUS, #m_family_ybc_status_toc{status=0}),
            mod_family:update_state(State#family_state{ext_info=FamilyExt#r_family_ext{
                                                                  last_ybc_finish_date=Date,
                                                                  last_ybc_begin_time=0,
                                                                  last_ybc_result=failed,ybc_id=0},
                                                       family_info=FamilyInfo#p_family_info{ybc_status=?FAMILY_YBC_STATUS_NOT_BEGIN, 
                                                                                            ybc_begin_time=0}});
        [] ->
            {Date, _} = erlang:localtime(),
            mod_family:broadcast_to_all_members(?FAMILY, ?FAMILY_YBC_STATUS, #m_family_ybc_status_toc{status=0}),
            mod_family:update_state(State#family_state{ext_info=FamilyExt#r_family_ext{last_ybc_finish_date=Date,
                                                                                       last_ybc_result=failed,
                                                                                       last_ybc_begin_time=0,
                                                                                       ybc_id=0},
                                                       family_info=FamilyInfo#p_family_info{ybc_status=?FAMILY_YBC_STATUS_NOT_BEGIN,
                                                                                            ybc_begin_time=0}})
    end.

%% 超时删除镖车
do_ybc_timeout_del(YbcID) ->
    case db:dirty_read(?DB_YBC, YbcID) of
        [] ->
            ignore;
        [#r_ybc{map_id=MapID}] ->
            common_map:info(common_map:get_common_map_name(MapID), {mod_ybc_family, {ybc_timeout_delete, YbcID}})
    end.

%% 地图通知镖车过期了
do_ybc_timeout(RoleList) ->
    State = mod_family:get_state(),
    FamilyExt = State#family_state.ext_info,
    FamilyInfo = State#family_state.family_info,
    YbcID = FamilyExt#r_family_ext.ybc_id,
    case YbcID > 0 of
        true ->
            R = #m_family_ybc_commit_toc{succ=false, reason=?_LANG_FAMILY_YBC_TIME_OUT_24_HOUR},
            lists:foreach(
              fun({RID, _RName, _Level, _SB, _B}) ->
                      db:transaction(fun() -> [RoleState] = db:read(?DB_ROLE_STATE, RID, write),
                                              db:write(?DB_ROLE_STATE, RoleState#r_role_state{ybc=undefined}, write)
                                     end),
                      common_misc:unicast({role, RID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_YBC_COMMIT, R)
              end, RoleList),
            {Date, _} = erlang:localtime(),
            log_family_ybc(YbcID,"镖车超过24小时消失了"),
            mod_family:broadcast_to_all_members(?FAMILY, ?FAMILY_YBC_STATUS, #m_family_ybc_status_toc{status=0}),
            mod_family:update_state(State#family_state{ext_info=FamilyExt#r_family_ext{last_ybc_finish_date=Date,
                                                                                       last_ybc_result=failed,
                                                                                       last_ybc_begin_time=0,
                                                                                       ybc_id=0},
                                                       family_info=FamilyInfo#p_family_info{ybc_status=?FAMILY_YBC_STATUS_NOT_BEGIN, 
                                                                                            ybc_begin_time=0}});
        false ->
            ignore
    end.


do_ybc_dead(YbcID, RoleList) ->
    State = mod_family:get_state(),
    FamilyExt = State#family_state.ext_info,
    FamilyInfo = State#family_state.family_info,
    case FamilyExt#r_family_ext.ybc_id > 0 of
        true ->
            R = #m_family_ybc_commit_toc{succ=false, reason=?_LANG_FAMILY_YBC_DEAD},
            lists:foreach(
              fun({RID, _RName, _Level, _SB, _B}) ->
                      db:transaction(fun() -> [RoleState] = db:read(?DB_ROLE_STATE, RID, write),
                                              db:write(?DB_ROLE_STATE, RoleState#r_role_state{ybc=undefined}, write)
                                     end),
                      common_misc:unicast({role, RID}, ?DEFAULT_UNIQUE, ?FAMILY, ?FAMILY_YBC_COMMIT, R)
              end, RoleList),
            {Date, _} = erlang:localtime(),
            mod_family:broadcast_to_all_members(?FAMILY, ?FAMILY_YBC_STATUS, #m_family_ybc_status_toc{status=0}),
            log_family_ybc(YbcID,lists:concat(
                                   ["镖车被打爆,当前组员有:",string:join([common_tool:to_list(Name) || {_,Name,_,_,_} <- RoleList],",")])),
            mod_family:update_state(State#family_state{ext_info=FamilyExt#r_family_ext{last_ybc_finish_date=Date,
                                                                                       last_ybc_begin_time=0,
                                                                                       last_ybc_result=failed,
                                                                                       ybc_id=0},
                                                       family_info=FamilyInfo#p_family_info{ybc_status=?FAMILY_YBC_STATUS_NOT_BEGIN, 
                                                                                            ybc_begin_time=0}});
        false ->
            ignore
    end.


do_ybc_invite(Unique, Module, Method, RoleID, PID) ->
    case catch do_ybc_invite_check(RoleID) of
        ok ->
            State = mod_family:get_state(),
            R = #m_family_ybc_invite_toc{},
            common_misc:unicast2(PID, Unique, Module, Method, R),
            RB = #m_family_ybc_invite_toc{return_self=false, type=(State#family_state.family_info)#p_family_info.ybc_type,
                                          role_id=(State#family_state.family_info)#p_family_info.ybc_creator_id},
            YbcRoleList = (State#family_state.family_info)#p_family_info.ybc_role_id_list,
            RoleList = lists:delete(RoleID,get_all_member_level_than_except(?FAMILY_YBC_MIN_LEVEL)),
            RoleList2 = lists:filter(
                          fun(RID) ->
                                  not lists:member(RID, YbcRoleList)
                          end, RoleList),
            common_misc:send_to_rolemap(RoleID, {mod_ybc_family, 
                                                 {family_ybc_invite, 
                                                  RoleList2,
                                                  Module, Method, RB}}),
            ok;
        {error, Reason} ->
            do_ybc_invite_error(Unique, Module, Method, Reason, PID);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["邀请族员拉镖发生系统错误", Error]),
            do_ybc_invite_error(Unique, Module, Method, "", PID)
    end.

do_ybc_invite_check(RoleID) ->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    case FamilyInfo#p_family_info.ybc_creator_id =:= RoleID of
        true ->
            ok;
        false ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_NOT_CREATOR_WHEN_INVITE})
    end,
    case FamilyInfo#p_family_info.ybc_status of
        ?FAMILY_YBC_STATUS_NOT_BEGIN ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_NOT_BEGIN_WHEN_INVITE});
        ?FAMILY_YBC_STATUS_DOING ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_DOING_WHEN_INVITE});
        _ ->
            ok
    end,
    ok.

do_ybc_invite_error(Unique, Module, Method, Reason, PID) ->
    R = #m_family_ybc_invite_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).


%%放弃参与拉镖
do_ybc_giveup(Unique, Module, Method, RoleID, PID) ->
    case catch do_ybc_giveup_check(RoleID) of
        ok ->
            State = mod_family:get_state(),
            FamilyInfo = State#family_state.family_info,
            FamilyExt = State#family_state.ext_info,
            %% 必须要记录这个事件
            %% 判断是谁
            CreatorID = FamilyInfo#p_family_info.ybc_creator_id,
            case CreatorID =:= RoleID of
                true ->
                    %% 解散整个队伍
                    NewFamilyInfo = FamilyInfo#p_family_info{ybc_status=?FAMILY_YBC_STATUS_NOT_BEGIN,
                                                             ybc_creator_id=0, ybc_role_id_list=[],
                                                             ybc_begin_time=0, ybc_type=0},
                    NewFamilyExt = FamilyExt#r_family_ext{ybc_role_list=[], last_ybc_begin_time=0},
                    mod_family:update_state(State#family_state{family_info=NewFamilyInfo, ext_info=NewFamilyExt}),
                    RoleList = FamilyExt#r_family_ext.ybc_role_list,
                    %% 退钱和还原角色状态事件托管给mgeew_user_event
                    mgeew_user_event:deposit(?USER_EVENT_TYPE_FAMILY_YBC_CANCEL_ADD_SILVER, RoleList),
                    R = #m_family_ybc_giveup_toc{role_id=RoleID},
                    common_misc:unicast2(PID, Unique, Module, Method, R),
                    RB = #m_family_ybc_giveup_toc{return_self=false, role_id=RoleID},
                    mod_family:broadcast_to_all_members_except(Module, Method, RB, RoleID),
                    log_family_ybc(lists:concat(["创建者", common_tool:to_list(common_misc:get_dirty_rolename(RoleID)),"解散了家族拉镖"])),
                    ok;
                false ->
                    OldYbcRoleIDList = FamilyInfo#p_family_info.ybc_role_id_list,
                    OldYbcRoleList = FamilyExt#r_family_ext.ybc_role_list,
                    {RoleID, RoleSilver} = lists:keyfind(RoleID, 1, OldYbcRoleList),
                    NewFamilyInfo = FamilyInfo#p_family_info{ybc_role_id_list=lists:delete(RoleID, OldYbcRoleIDList)},
                    NewFamilyExt = FamilyExt#r_family_ext{ybc_role_list=lists:keydelete(RoleID, 1, OldYbcRoleList)},
                    mod_family:update_state(State#family_state{family_info=NewFamilyInfo, ext_info=NewFamilyExt}),
                    R = #m_family_ybc_giveup_toc{role_id=RoleID},
                    common_misc:unicast2(PID, Unique, Module, Method, R),
                    log_family_ybc(lists:concat(["玩家",common_tool:to_list(common_misc:get_dirty_rolename(RoleID)),"放弃了拉镖"])),
                    %% 广播通知其他玩家
                    RB = #m_family_ybc_giveup_toc{return_self=false, role_id=RoleID},
                    mod_family:broadcast_to_all_members_except(Module, Method, RB, RoleID),
                    YbcID = FamilyExt#r_family_ext.ybc_id,
                    case YbcID =:= 0 of
                        true -> 
                            %%族长还没领取镖车时放弃，则退还押金
                            %% 退钱和还原角色状态事件托管给mgeew_user_event
                            mgeew_user_event:deposit(?USER_EVENT_TYPE_FAMILY_YBC_GIVEUP_ADD_SILVER, {RoleID, RoleSilver}),
                            common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, ?_LANG_FAMILY_YBC_GIVEUP_GIVE_BACK_COST);
                        false ->
                            db:transaction(fun() ->
                                                   [RoleState] = db:read(?DB_ROLE_STATE, RoleID, write), 
                                                   db:write(?DB_ROLE_STATE, RoleState#r_role_state{ybc=undefined}, write)
                                           end), 
                            case db:transaction(
                                   fun() -> 
                                           [#r_ybc{role_list=RoleList} = YbcInfo] = db:read(?DB_YBC, YbcID, write),
                                           NewYbcInfo = YbcInfo#r_ybc{role_list=lists:keydelete(RoleID, 1, RoleList)},
                                           db:write(?DB_YBC, NewYbcInfo, write),
                                           NewYbcInfo
                                   end) 
                            of 
                                {atomic, NewYbcInfo} ->
                                    common_ybc:update_mapinfo(YbcID, NewYbcInfo);
                                {aborted, Error} ->
                                    ?ERROR_MSG("~ts:~w", ["玩家主动退出镖队后，更新镖队成员出错", Error])
                            end,
                            common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, ?_LANG_FAMILY_YBC_GIVEUP_NO_GIVE_BACK_COST)
                    end,

                    ok
            end,
            ok;
        {error, Reason} ->
            do_ybc_giveup_error(Unique, Module, Method, Reason, PID);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["放弃家族拉镖时发生系统错误", Error]),
            do_ybc_giveup_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_GIVEUP, PID)
    end.

do_ybc_giveup_check(RoleID) ->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    case FamilyInfo#p_family_info.ybc_status of
        ?FAMILY_YBC_STATUS_NOT_BEGIN ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_NOT_BEGIN_WHEN_GIVEUP});
        ?FAMILY_YBC_STATUS_DOING ->
            case FamilyInfo#p_family_info.ybc_creator_id =:= RoleID of
                true ->
                    erlang:throw({error, ?_LANG_FAMILY_YBC_DOING_WHEN_GIVEUP});
                false ->
                    ok
            end;
        _ ->
            ok
    end,
    case lists:member(RoleID, FamilyInfo#p_family_info.ybc_role_id_list) of
        true ->
            ok;
        false ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_NOT_IN_LIST_WHEN_GIVEUP})
    end,
    ok.


do_ybc_giveup_error(Unique, Module, Method, Reason, PID) ->
    R = #m_family_ybc_giveup_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).


do_ybc_sure_timeout() ->
    case get_ybc_sure_request() of
        undefined ->
            ignore;
        {_RoleID, Unique, Module, Method, PID} ->
            clear_ybc_sure_request(),
            do_ybc_sure_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_DO_SURE_TIMEOUT, PID)
    end.

%% 确认开始拉镖
do_ybc_sure(Unique, Module, Method, RoleID, PID) ->
    case catch do_ybc_sure_check(RoleID) of
        ok ->
            State = mod_family:get_state(),
            FamilyExt = State#family_state.ext_info, 
            FamilyInfo = State#family_state.family_info,
            FamilyLevel = FamilyInfo#p_family_info.level,
            FamilyName = FamilyInfo#p_family_info.family_name, 
            FamilyID = FamilyExt#r_family_ext.family_id,
            FactionID = FamilyInfo#p_family_info.faction_id,
            Type = FamilyInfo#p_family_info.ybc_type,
            #family_state{family_info=FamilyInfo, ext_info=FamilyExt} = State,
            RoleIDList = FamilyInfo#p_family_info.ybc_role_id_list,
            RoleList = lists:foldl(
                         fun(RID, Acc) ->
                                 #p_role_attr{role_name=RoleName, level=Level} = mod_role_tab:get({?role_attr, RoleID}),
                                 NeedSilver = get_ybc_yajin(Level, Type),  
                                 [{RID, RoleName, Level, 0, NeedSilver} | Acc]
                         end, [], RoleIDList),                       
            %% 通知地图创建镖车，并异步等待消息返回
            HP = get_family_ybc_hp(Type, FamilyLevel),
            case common_config:is_debug() of
                true ->
                    MoveSpeed = 240;
                false ->
                    MoveSpeed = 70
            end,
            RecoverSpeed = 10,
            MagicDefence = 1000,
            PhysicalDefence = 1000,
            #p_role_attr{level=CreatorLevel} = mod_role_tab:get({?role_attr, RoleID}),
            YbcCreateInfo = #p_ybc_create_info{role_list=RoleList,
                                               create_type=Type,
                                               faction_id=FactionID,
                                               color=1, max_hp=HP,
                                               move_speed=MoveSpeed,
                                               name= lists:concat([common_tool:to_list(FamilyName), "的镖车"]),
                                               creator_id=RoleID, create_time=common_tool:now(),
                                               end_time=common_tool:now() + 7200,
                                               buffs=[], recover_speed=RecoverSpeed,
                                               magic_defence=MagicDefence, physical_defence=PhysicalDefence,
                                               group_type=2, group_id=FamilyID, can_attack=true, level=CreatorLevel},
            common_misc:send_to_rolemap(RoleID, {mod_ybc_family, {family_ybc_sure, erlang:self(), YbcCreateInfo}}),
            set_ybc_sure_request(RoleID, Unique, Module, Method, PID),
            erlang:send_after(5000, erlang:self(), {ybc_sure_timeout});
        {error, Error} ->
            do_ybc_sure_error(Unique, Module, Method, Error, PID);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["确认开始拉镖时发生系统错误", Error])
    end,
    ok.


get_ybc_sure_request() ->
    erlang:get(family_ybc_sure_request).
set_ybc_sure_request(RoleID, Unique, Module, Method, PID) ->
    erlang:put(family_ybc_sure_request, {RoleID, Unique, Module, Method, PID}).
clear_ybc_sure_request() ->
    erlang:erase(family_ybc_sure_request).

do_ybc_sure_check(RoleID) ->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    %% 只有发布人才能确认镖车
    case FamilyInfo#p_family_info.ybc_creator_id =:= RoleID of
        true ->
            ok;
        false ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_NOT_CREATOR_WHEN_SURE})
    end,
    case get_ybc_sure_request() of
        undefined ->
            ok;
        _ ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_DO_WITH_LAST_SURE_REQUEST})
    end,
    ok.


do_ybc_sure_error(Unique, Module, Method, Reason, PID) ->
    R = #m_family_ybc_sure_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).


%% 镖车需要持久化记录一些信息

do_ybc_alert(Unique, Module, Method, Record, RoleID, PID) ->
    #m_family_ybc_alert_tos{role_id=TRoleID} = Record,
    case catch do_ybc_alert_check(RoleID, TRoleID) of
        ok ->
            common_misc:unicast2(PID, Unique, Module, Method, #m_family_ybc_alert_toc{}),
            common_misc:unicast({role, TRoleID}, ?DEFAULT_UNIQUE, Module, Method, #m_family_ybc_alert_toc{return_self=false}),
            ok;
        {error, Error} ->
            do_ybc_alert_error(Unique, Module, Method, Error, PID)
    end.

do_ybc_alert_error(Unique, Module, Method, Reason, PID) ->
    common_misc:unicast2(PID, Unique, Module, Method, #m_family_ybc_alert_toc{succ=false, reason=Reason}).

do_ybc_alert_check(RoleID, TRoleID) ->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    case mod_family:is_owner_or_second_owner(RoleID, FamilyInfo) of
        true ->
            ok;
        false ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_ONLY_OWNER_OR_SECOND_OWNER_CAN_ALERT})
    end,
    case RoleID =:= TRoleID of
        true ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_ALERT_YOUR_SELF});
        false ->
            ok
    end,
    ok.    

%%家族镖车需要交的押金
get_ybc_yajin(Level, Type) ->
    case common_config_dyn:find(family_ybc_money, Level) of
        [] ->
            99999999999;
        [#p_family_ybc_money{common=CommonSilver, advance=AdvanceSilver}] ->
            case Type of
                1 ->
                    CommonSilver;
                _ ->
                    AdvanceSilver
            end
    end.


%% 家族镖车基础血量
-define(FAMILY_YBC_BASIC_HP, 500000).

%% 家族镖车基础等级血量
-define(FAMILY_YBC_LEVEL_HP, 500000).

%% 高级镖车的血量系数
-define(FAMILY_YBC_ADVANCE_HP_RADIO, 10).

get_family_ybc_hp(Type, RoleLevel) ->
    case Type of
        1 ->
            (?FAMILY_YBC_BASIC_HP + ?FAMILY_YBC_LEVEL_HP * RoleLevel);
        2 ->
            ?FAMILY_YBC_ADVANCE_HP_RADIO * (?FAMILY_YBC_BASIC_HP + ?FAMILY_YBC_LEVEL_HP * RoleLevel)
    end.


set_ybc_publish_request_info(Unique, Module, Method, RoleID, PID, Type, NeedSilver) ->
    erlang:put(ybc_publish_request_info, {Unique, Module, Method, RoleID, PID, Type, NeedSilver}).
get_ybc_publish_request_info() ->
    erlang:get(ybc_publish_request_info).
clear_ybc_publish_request_info() ->
    erlang:erase(ybc_publish_request_info).


do_ybc_sure_failed(Reason) ->
    {_RoleID, Unique, Module, Method, PID} = get_ybc_sure_request(),
    clear_ybc_sure_request(),
    %% 创建镖车失败了，把钱币加回去
    do_ybc_sure_error(Unique, Module, Method, Reason, PID).


do_ybc_sure_succ(YbcID) ->
    {RoleID, Unique, Module, Method, PID} = get_ybc_sure_request(),
    clear_ybc_publish_request_info(),
    State = mod_family:get_state(),
    FamilyExt = State#family_state.ext_info, 
    FamilyInfo = State#family_state.family_info,
    NewExt = FamilyExt#r_family_ext{last_ybc_begin_time=common_tool:now(),
                                    ybc_id=YbcID},
    mod_family:update_state(State#family_state{ext_info=NewExt, family_info=FamilyInfo#p_family_info{ybc_status=?FAMILY_YBC_STATUS_DOING, 
                                                                                                     ybc_creator_id=RoleID, 
                                                                                                     ybc_begin_time=common_tool:now()}}), 
    clear_ybc_sure_request(),
    R = #m_family_ybc_sure_toc{},
    common_misc:unicast2(PID, Unique, Module, Method, R),    
    RB = #m_family_ybc_sure_toc{return_self=false},
    mod_family:broadcast_to_all_members_except(Module, Method, RB, RoleID),
    log_family_ybc(YbcID,lists:concat([common_tool:to_list(common_misc:get_dirty_rolename(RoleID)),"创建镖车成功"])),
    ok.


%% 发布镖车处理超时了
do_ybc_publish_timeout() ->
    case get_ybc_publish_request_info() of
        undefined ->
            ignore;        
        {Unique, Module, Method, _RoleID, PID, _Type, _NeedSilver} ->
            do_ybc_publish_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_DO_PUBLISH_TIMEOUT, PID),
            %%清理请求
            clear_ybc_publish_request_info()
    end.

%% 镖车发布成功
do_ybc_publish_succ(RoleAttr) ->
    case get_ybc_publish_request_info() of
        undefined ->
            ignore;        
        {Unique, Module, Method, RoleID, PID, Type, NeedSilver} ->
            %%清理请求
            clear_ybc_publish_request_info(),
            R = #m_family_ybc_publish_toc{silver=NeedSilver, owner_id=RoleID, type=Type},
            common_misc:unicast2(PID, Unique, Module, Method, R), 
            State = mod_family:get_state(),
            FamilyExt = State#family_state.ext_info, 
            FamilyInfo = State#family_state.family_info,
            NewExt = FamilyExt#r_family_ext{ybc_role_list=[{RoleID, NeedSilver}]},
            %% 更改家族拉镖状态
            mod_family:update_state(State#family_state{ext_info=NewExt, family_info=FamilyInfo#p_family_info{
                                                                                      ybc_status=?FAMILY_YBC_STATUS_PUBLISHING, 
                                                                                      ybc_creator_id=RoleID,
                                                                                      ybc_type=Type, 
                                                                                      ybc_role_id_list=[RoleID]}}), 
            #p_role_attr{silver=Silver} = RoleAttr,
            RAttr = #m_role2_attr_change_toc{
              roleid  = RoleID,
              changes = [
                         #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE,new_value=Silver}
                        ]
             },
	    LogContent = lists:concat([common_tool:to_list(common_misc:get_dirty_rolename(RoleID)),"开始发布镖车任务"]),
	    log_family_ybc(LogContent),

            common_misc:unicast2(PID, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, RAttr)
    end,    
    ok.

do_ybc_publish_failed(Reason) ->
    {Unique, Module, Method, _RoleID, PID, _Type, _NeedSilver} = get_ybc_publish_request_info(),
    do_ybc_publish_error(Unique, Module, Method, Reason, PID).

%%发布镖车任务
do_ybc_publish(Unique, Module, Method, Record, RoleID, PID) ->
    #p_role_attr{level=Level} =  mod_role_tab:get({?role_attr, RoleID}),
    %% 可以优化成从家族成员列表来读取
    #m_family_ybc_publish_tos{type=Type} = Record,
    case catch do_ybc_publish_check(RoleID, Level) of
        ok ->            
            NeedSilver = get_ybc_yajin(Level, Type),            
            State = mod_family:get_state(),
            FamilyInfo = State#family_state.family_info,
            %% 判断是族长还是副族长
            case FamilyInfo#p_family_info.owner_role_id =:= RoleID of
                true ->
                    OwnerType = 1;
                false ->
                    OwnerType = 2
            end,
            %% 广播通知玩家
            RB = #m_family_ybc_publish_toc{return_self=false, type=Type, remain_time=3600,silver=NeedSilver,
                                           owner_id=RoleID,
                                           owner_type=OwnerType},
            RoleIDList = lists:delete(RoleID, get_all_member_level_than_except(?FAMILY_YBC_MIN_LEVEL)),
            Info = {family_ybc_publish, self(), RoleID, NeedSilver, Module, Method, RB, RoleIDList},
            common_misc:send_to_rolemap(RoleID, {mod_ybc_family, Info}),
            set_ybc_publish_request_info(Unique, Module, Method, RoleID, PID, Type, NeedSilver),
            erlang:send_after(5000, erlang:self(), {ybc_publish_timeout}),
            ok;
        {error, Reason} ->
            do_ybc_publish_error(Unique, Module, Method, Reason, PID);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["检查家族发布拉镖任务出错", Error]),
            do_ybc_publish_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_CHECK_PUBLISH, PID)
    end,
    ok.

do_ybc_publish_check(RoleID, Level) ->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    %% 检查权限
    case mod_family:is_owner_or_second_owner(RoleID, FamilyInfo) of
        true ->
            ok;
        false ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_ONLY_OWNER_OR_SECOND_OWNER_CAN_PUBLISH})
    end,
    %% 角色升级时一定会进行一次持久化，所以这里可以直接脏读
    #p_role_attr{level=Level} = mod_role_tab:get({?role_attr, RoleID}),
    %% 达到三等初出茅庐才能拉镖
    MinLevel = get_role_min_level(),
    if Level >= MinLevel ->
           next;
       true ->
           ErrorMsg = lists:flatten(io_lib:format(?_LANG_FAMILY_YBC_JINGJIE_LIMIT_WHEN_PUBLISH,
                                                  [MinLevel])),
           erlang:throw({error, ErrorMsg})
    end,
    case Level < ?FAMILY_YBC_MIN_LEVEL of
        true ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_LEVEL_LIMIT_WHEN_PUBLISH});
        false ->
            ok
    end,
    FamilyExt = State#family_state.ext_info,
    LastFinishDate = FamilyExt#r_family_ext.last_ybc_finish_date,
    {Date, _} = calendar:local_time(),
    %% 判断当前是否已经有完成过拉镖，无论是成功或者未成功都算是完成的
    case Date =:= LastFinishDate of
        true ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_ONE_DAY_ONLY_ONE_PUBLISH});
        false ->
            ok
    end,
    %% 判断是否还在处理上一次的发布镖车请求
    case get_ybc_publish_request_info() of
        undefined ->
            ok;
        _ ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_DO_WITH_LAST_PUBLISH_REQUEST})
    end,
    %% 判断是否正在拉镖
    case FamilyInfo#p_family_info.ybc_status of
        ?FAMILY_YBC_STATUS_PUBLISHING ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_ALREADY_IN_PUBLISH});
        ?FAMILY_YBC_STATUS_DOING ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_ALREADY_IN_YBC_DOING_STATUS});
        _ ->
            ok
    end,
    ok.

do_ybc_publish_error(Unique, Module, Method, Reason, PID) ->
    R = #m_family_ybc_publish_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).

get_agree_publish_request(RoleID) ->
    erlang:get({agree_publish_request, RoleID}).
set_agree_publish_request(RoleID, Unique, Module, Method, PID, Yajin) ->
    erlang:put({agree_publish_request, RoleID}, {Unique, Module, Method, PID, Yajin}).
clear_agree_publish_request(RoleID) ->
    erlang:erase({agree_publish_request, RoleID}).

do_ybc_agree_publish_timeout(RoleID) ->
    case get_agree_publish_request(RoleID) of
        undefined ->
            ignore;
        {Unique, Module, Method, PID, _Yajin} ->
            do_ybc_agree_publish_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_AGREE_PUBLISH_TIMEOUT, PID),
            clear_agree_publish_request(RoleID)
    end,
    ok.

do_ybc_agree_publish_failed(RoleID, Reason) ->
    case get_agree_publish_request(RoleID) of
        undefined ->
            ignore;
        {Unique, Module, Method, PID, _Yajin} ->
            do_ybc_agree_publish_error(Unique, Module, Method, Reason, PID),
            clear_agree_publish_request(RoleID)
    end,
    ok.

do_ybc_agree_publish_succ(RoleID, RoleAttr, NeedSilver) ->
    case get_agree_publish_request(RoleID) of
        undefined ->
            ignore;
        {Unique, Module, Method, PID, Yajin} ->
            erlang:send_after(5000, erlang:self(), {ybc_agree_publish_timeout, RoleID}),
            State = mod_family:get_state(),
            FamilyInfo = State#family_state.family_info,
            FamilyExt = State#family_state.ext_info,
            OldYbcMembers = FamilyInfo#p_family_info.ybc_role_id_list,
            YbcRoleList = FamilyExt#r_family_ext.ybc_role_list,
            YbcID = FamilyExt#r_family_ext.ybc_id,
            case lists:member(RoleID, OldYbcMembers) of
                true ->
                    ignore;
                false ->
                    mod_family:update_state(State#family_state{family_info=FamilyInfo#p_family_info{ybc_role_id_list=[RoleID | OldYbcMembers]},
                                                               ext_info=FamilyExt#r_family_ext{ybc_role_list=[{RoleID, NeedSilver} | YbcRoleList]}})
            end,
            Record = #m_role2_attr_change_toc{
              roleid  = RoleID,
              changes = [
                         #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE,new_value=RoleAttr#p_role_attr.silver}
                        ]
             },
            common_misc:unicast2(PID, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, Record),
            R = #m_family_ybc_agree_publish_toc{silver=Yajin, begin_time=0, ybc_role_id_list=[RoleID | OldYbcMembers]},
            common_misc:unicast2(PID, Unique, Module, Method, R),
            RB = #m_family_ybc_agree_publish_toc{return_self=false, 
                                                 silver=Yajin, role_id=RoleID, 
                                                 ybc_role_id_list=[RoleID | OldYbcMembers],
                                                 role_name=RoleAttr#p_role_attr.role_name},
            %% 通知所有已经接镖的玩家
            common_misc:broadcast_to_line(OldYbcMembers, Module, Method, RB),
	    log_family_ybc(YbcID,lists:concat([common_tool:to_list(RoleAttr#p_role_attr.role_name),"加入了拉镖队伍"])),
            clear_agree_publish_request(RoleID)            
    end,
    ok.


%% 家族同意加入镖车队伍
do_ybc_agree_publish(Unique, Module, Method, RoleID, PID) ->
    case catch do_ybc_agree_publish_check(RoleID) of
        {ok, Yajin} ->
            set_agree_publish_request(RoleID, Unique, Module, Method, PID, Yajin),
            common_misc:send_to_rolemap(RoleID, {mod_ybc_family, {family_ybc_agree_publish, erlang:self(), RoleID, Yajin}}),
            erlang:send_after(5000, erlang:self(), {ybc_agree_publish_timeout, RoleID}),
            ok;
        {error, Error} ->
            do_ybc_agree_publish_error(Unique, Module, Method, Error, PID);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["处理玩家同意家族拉镖出错", Error]),
            do_ybc_agree_publish_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_AGREE_PUBLISH, PID)
    end,
    ok.    

do_ybc_agree_publish_check(RoleID) ->
    %% 检查当前家族是否正在接镖中
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    Type = FamilyInfo#p_family_info.ybc_type,
    YbcStatus = FamilyInfo#p_family_info.ybc_status,
    %% 检查是否已经有上一次的请求了
    case get_agree_publish_request(RoleID) of
        undefined ->
            ignore;
        _ ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_DO_WITH_LAST_AGREE_PUBLISH_REQUEST})
    end,
    %% 检查今天是否已经拉过镖
    case mod_family:is_today_not_parttake(RoleID,family_ybc) of
        true->
            ignore;
        _ ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_PARTAKE_TODAY_LIMIT})
    end,
    %% 是否处于发布状态
    case YbcStatus =:= ?FAMILY_YBC_STATUS_PUBLISHING of
        true ->
            ok;
        false ->
            case YbcStatus =:= ?FAMILY_YBC_STATUS_DOING of
                true ->
                    erlang:throw({error, ?_LANG_FAMILY_YBC_DOING_WHEN_AGREE_PUBLISH});
                false ->
                    FamilyExt = State#family_state.ext_info,
                    {Date, _} = erlang:localtime(),
                    case FamilyExt#r_family_ext.last_ybc_finish_date =:= Date of
                        true ->
                            erlang:throw({error, ?_LANG_FAMILY_YBC_NOT_PUBLISHING_WHEN_AGREE_PUBLISH});
                        false ->
                            erlang:throw({error, ?_LANG_FAMILY_YBC_CANCEL_WHEN_AGREE_PUBLISH})
                    end
            end
    end,
    [#r_role_state{ybc=Ybc}] = db:dirty_read(?DB_ROLE_STATE, RoleID),
    %%检查是否已经处于拉镖状态中
    case Ybc =/= undefined andalso Ybc > 0 of
        true ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_ALREADY_IN_YBC_WHEN_AGREE_PUBLISH});
        false ->
            ok
    end,
    #p_role_base{status=Status} =  mod_role_tab:get({?role_base, RoleID}),
    case Status =:= ?ROLE_STATE_DEAD of
        true ->
            Reason = io_lib:format(?_LANG_FAMILY_YBC_SPECIAL_STATUS_CANNT_ACCEPT_PUBLISH, [common_role:get_state_string(Status)]),
            erlang:throw({error, Reason});
        false ->
            ok
    end,
    %% 检查玩家等级是否满足等级
    #p_role_attr{level=Level} =  mod_role_tab:get({?role_attr, RoleID}),
    case Level < ?FAMILY_YBC_MIN_LEVEL of
        true ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_LEVEL_NOT_ENOUGH_WHEN_AGREE_PUBLISH});
        false ->
            ok
    end,
    %% 检查是否已经在镖车队伍中了
    OldYbcMembers = FamilyInfo#p_family_info.ybc_role_id_list,
    case lists:member(RoleID, OldYbcMembers) of
        true ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_ALREADY_IN_ROLE_LIST});
        false ->
            ok
    end,
    {ok, get_ybc_yajin(Level, Type)}.


do_ybc_agree_publish_error(Unique, Module, Method, Reason, PID) ->
    R = #m_family_ybc_agree_publish_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).

save_ybc_commit_request(Unique, Module, Method, RoleID, PID) ->
    erlang:put(ybc_commit_request, {Unique, Module, Method, RoleID, PID}).
get_ybc_commit_request() ->
    erlang:get(ybc_commit_request).
clear_ybc_commit_request() ->
    erlang:erase(ybc_commit_request).


do_ybc_commit_failed(Reason) ->
    {Unique, Module, Method, _RoleID, PID} = get_ybc_commit_request(),
    clear_ybc_commit_request(),
    do_ybc_commit_error(Unique, Module, Method, Reason, PID),
    ok.
do_ybc_commit_succ(AllRoleList, RoleIDList, Timeout) ->
    case Timeout of
        true ->
            do_ybc_commit_succ_timeout(AllRoleList, RoleIDList);
        false ->
            do_ybc_commit_succ_ok(AllRoleList, RoleIDList)
    end,
    ok.

%% 成功交镖但已经超时了
do_ybc_commit_succ_timeout(AllRoleList, RoleList) ->
    case get_ybc_commit_request() of
        undefined ->
            ignore;
        {Unique, Module, Method, RoleID, PID} -> 
            State = mod_family:get_state(),
            FamilyExt = State#family_state.ext_info,
            FamilyInfo = State#family_state.family_info,
            YbcID = FamilyExt#r_family_ext.ybc_id,
            case db:transaction(fun() -> t_do_ybc_commit_timeout(YbcID) end) of
                {atomic, ok} ->
                    FamilyLevel = (State#family_state.family_info)#p_family_info.level,
                    RoleNum = erlang:length(RoleList),
                    %% 超时情况下所有奖励20%
                    FC = common_tool:ceil(0.2 * get_family_ybc_succ_fc()),
                    FamilyMoney = common_tool:ceil(0.2 * get_family_ybc_succ_family_money(RoleNum, FamilyLevel)),
                    ActivePoint = common_tool:ceil(0.2 * get_family_ybc_succ_family_ac(RoleNum, FamilyLevel)),
                    mod_family:do_add_ac(ActivePoint),
                    mod_family:do_add_money(FamilyMoney),
                    %% 超时了
                    {Date, _} = erlang:localtime(),
                    mod_family:update_state(State#family_state{ext_info=FamilyExt#r_family_ext{ybc_id=0,
                                                                                               last_ybc_begin_time=0,
                                                                                               last_ybc_finish_date=Date,
                                                                                               last_ybc_result=timeout
                                                                                              },
                                                               family_info=FamilyInfo#p_family_info{ybc_begin_time=0, ybc_status=?FAMILY_YBC_STATUS_NOT_BEGIN}
                                                              }),  

                    LogResult = lists:foldl(
                                  fun({RID, RName, Level, _, _}, Acc) ->
                                          case lists:keyfind(RID, 1, RoleList) of
                                              false ->
                                                  Exp = 0;
                                              _ ->
                                                  ExpTmp = common_tool:ceil(0.2 * get_ybc_exp(Level, RoleNum)),
                                                  Exp = hook_activity_family:hook_activity_expr(RoleID,ExpTmp),
                                                  mod_family:add_exp_for_role(RID, Exp)
                                          end,
                                          R2 = #m_family_ybc_commit_toc{return_self=false, exp=Exp, silver=0,
                                                                        reason=?_LANG_FAMILY_YBC_TIMEOUT,
                                                                        contribution=FC, family_money=FamilyMoney,
                                                                        active_point=ActivePoint},
                                          mod_family:do_add_contribution(RID, FC),
                                          %%增加3点活跃度
                                          catch common_misc:done_task(RID,?ACTIVITY_TASK_FAMILY_YBC),
                                          %%增加活动记录
                                          mod_family:do_parttake_family_role(RID,family_ybc),
                                          common_misc:unicast({role, RID}, ?DEFAULT_UNIQUE, Module, Method, R2),
                                          lists:concat([Acc, "族员:", common_tool:to_list(RName),"获得奖励:经验值,",Exp,".家族贡献度,",FC])
                                  end, "", AllRoleList),

                    common_misc:send_to_rolemap(RoleID, {mod_map_ybc, {del_ybc, YbcID}}),
		    log_family_ybc(YbcID,lists:concat(["超时完成家族镖车任务,获得奖励的有---",LogResult])),
                    ok;
                {aborted, Error} ->
                    case erlang:is_binary(Error) of
                        true ->
                            Reason = Error;
                        false ->
                            Reason = ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_COMMIT,
                            ?ERROR_MSG("~ts:~w", ["处理完成家族镖车任务时发生系统错误", Error])
                    end,
                    do_ybc_commit_error(Unique, Module, Method, Reason, PID)
            end,
            clear_ybc_commit_request()
    end.

%% 交镖没有超时
do_ybc_commit_succ_ok(AllRoleList, RoleList) ->
    %% 镖车正常完成
    case get_ybc_commit_request() of
        undefined ->
            ignore;
        {Unique, Module, Method, RoleID, PID} ->  
            State = mod_family:get_state(),
            FamilyExt = State#family_state.ext_info,
            FamilyInfo = State#family_state.family_info,
            YbcID = FamilyExt#r_family_ext.ybc_id,
            case db:transaction(fun() -> t_do_ybc_commit(YbcID) end) of
                {atomic, ok} ->                           
                    {Date, _} = erlang:localtime(),
                    mod_family:update_state(State#family_state{ext_info=FamilyExt#r_family_ext{ybc_id=0, 
                                                                                               last_ybc_finish_date=Date,
                                                                                               last_ybc_result=succ,
                                                                                               last_ybc_begin_time=0
                                                                                              },
                                                               family_info=FamilyInfo#p_family_info{ybc_begin_time=0, 
                                                                                                    ybc_status=?FAMILY_YBC_STATUS_NOT_BEGIN}
                                                              }),
                    FamilyLevel = (State#family_state.family_info)#p_family_info.level,
                    RoleNum = erlang:length(RoleList),
                    FamilyMoney = get_family_ybc_succ_family_money(RoleNum, FamilyLevel),
                    ActivePoint = get_family_ybc_succ_family_ac(RoleNum, FamilyLevel),
                    mod_family:do_add_ac(ActivePoint),
                    mod_family:do_add_money(FamilyMoney),

                    FCTmp = get_family_ybc_succ_fc(),
                    LogResult = lists:foldl(
                                  fun({RID, RName, Level, _BSilver, SilverTmp},Acc) ->
                                          case lists:keyfind(RID, 1, RoleList) of
                                              false ->
                                                  Exp = 0,
                                                  Silver = 0,
                                                  FC = 0;
                                              _ ->
                                                  ExpTmp = get_ybc_exp(Level, RoleNum),
                                                  Exp = hook_activity_family:hook_activity_expr(RoleID,ExpTmp),
                                                  mod_family:add_exp_for_role(RID, Exp),
                                                  FC = FCTmp,
                                                  mod_family:do_add_contribution(RID, FC),
                                                  Silver = SilverTmp
                                          end,
                                          %%增加3点活跃度
                                          catch common_misc:done_task(RID,?ACTIVITY_TASK_FAMILY_YBC),
                                          %%增加活动记录
                                          mod_family:do_parttake_family_role(RID,family_ybc),
										  
										  %%家族拉镖的铜钱奖励
										  RewardSilver = common_ybc:get_family_ybc_reward(Level),
                                          R2 = #m_family_ybc_commit_toc{return_self=false, exp=Exp, silver=Silver,
                                                                        contribution=FC, family_money=FamilyMoney,
                                                                        active_point=ActivePoint,reward_silver=RewardSilver},
                                          common_misc:unicast({role, RID}, ?DEFAULT_UNIQUE, Module, Method, R2),
                                          lists:concat([Acc, common_tool:to_list(RName), ",获得经验:", Exp, ",获得钱币:", Silver, ",获得家族贡献:", FC, ",获得钱币奖励:", RewardSilver])
                                  end,"",AllRoleList),
                    log_family_ybc(YbcID,lists:concat(["家族正常完成拉镖任务:获得奖励的有:",LogResult])),
                    StateFinal = mod_family:get_state(),
                    FamilyInfoTemp = StateFinal#family_state.family_info,
                    MembersFinal = StateFinal#family_state.family_members,
                    FamilyInfoFinal = FamilyInfoTemp#p_family_info{members=MembersFinal},
                    mod_family:broadcast_to_all_members(?FAMILY, ?FAMILY_SELF, #m_family_self_toc{family_info=FamilyInfoFinal}),
                    common_misc:send_to_rolemap(RoleID, {mod_map_ybc, {del_ybc, YbcID}}),
                    ok;
                {aborted, Error} ->
                    case erlang:is_binary(Error) of
                        true ->
                            Reason = Error;
                        false ->
                            Reason = ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_COMMIT,
                            ?ERROR_MSG("~ts:~w", ["处理完成家族镖车任务时发生系统错误", Error])
                    end,
                    do_ybc_commit_error(Unique, Module, Method, Reason, PID)
            end,
            clear_ybc_commit_request(),
            ok
    end.

%% 交镖超时了，地图那边卡了？
do_ybc_commit_timeout() ->
    case get_ybc_commit_request() of
        undefined ->
            ignore;
        {Unique, Module, Method, _RoleID, PID} ->
            do_ybc_commit_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_DO_COMMIT_TIMEOUT, PID),
            clear_ybc_commit_request()
    end,
    ok.

%%家族交镖，使用异步方式完成，先发消息给地图，由地图确认哪些玩家可以获取奖励
do_ybc_commit(Unique, Module, Method, RoleID, PID) ->
    case catch do_ybc_commit_check(RoleID) of
        ok ->            
            State = mod_family:get_state(),
            FamilyExt = State#family_state.ext_info,
            YbcID = FamilyExt#r_family_ext.ybc_id,
            FamilyInfo = State#family_state.family_info,
            %% 判断镖车是否已经超过24小时了，如果提交时镖车已经超过24小时了，通常镖车已经在地图中被直接删除
            case common_tool:now() - FamilyExt#r_family_ext.last_ybc_begin_time > 86400 of
                true ->
                    %% 清理所有对应玩家的拉镖状态
                    case db:transaction(fun() -> t_do_ybc_commit_timeout(YbcID) end) of
                        {atomic, ok} ->
                            %% 地图那边已经删除镖车，这便直接完成任务即可
                            mod_family:update_state(State#family_state{ext_info=FamilyExt#r_family_ext{ybc_id=0,
                                                                                                       last_ybc_result=timeout
                                                                                                      },
                                                                       family_info=FamilyInfo#p_family_info{
                                                                                     ybc_begin_time=0, 
                                                                                     ybc_status=?FAMILY_YBC_STATUS_NOT_BEGIN}
                                                                      }), 
                            R = #m_family_ybc_status_toc{status=0},
                            mod_family:broadcast_to_all_members(?FAMILY, ?FAMILY_YBC_STATUS, R),
                            log_family_ybc(YbcID,"超时完成家族镖车任务");
                        {aborted, Error} ->
                            ?ERROR_MSG("~ts:~w", ["处理完成家族镖车任务时发生系统错误", Error]),
                            do_ybc_commit_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_COMMIT, PID)
                    end,
                    ok;
                false ->                
                    case get_ybc_commit_request() of
                        undefined ->
                            %% 一定时间后检查本次操作是否过期了
                            erlang:send_after(8000, self(), {ybc_commit_timeout}),
                            save_ybc_commit_request(Unique, Module, Method, RoleID, PID),
                            common_misc:send_to_rolemap(RoleID, {mod_ybc_family, {family_ybc_commit, RoleID, YbcID, self()}});
                        _ ->
                            do_ybc_commit_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_COMMIT_IN_PROCESSING, PID)
                    end
            end;
        {error, Error} ->
            do_ybc_commit_error(Unique, Module, Method, Error, PID);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["处理完成家族镖车任务时发生系统错误", Error]),
            do_ybc_commit_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_COMMIT, PID)
    end,
    ok.

%% 家族拉镖成功后应该获得的家族贡献度
get_family_ybc_succ_fc() ->
    10.

get_family_ybc_succ_family_money(RoleNum, 0) ->
    erlang:round(RoleNum * 100 * math:pow(0.5, 1.5) + 1000 * 0.5 * 0.5 ) ;
%% 家族拉镖成功后获取的奖励
get_family_ybc_succ_family_money(RoleNum, FamilyLevel) ->
    erlang:round(RoleNum * 100 * math:pow(FamilyLevel, 1.5) + 1000 * FamilyLevel * FamilyLevel).

get_family_ybc_succ_family_ac(RoleNum, 0) ->
    erlang:round(3*0.5 + RoleNum / 3);
get_family_ybc_succ_family_ac(RoleNum, FamilyLevel) ->
    erlang:round(3*FamilyLevel + RoleNum/3).


%% 家族拉镖成功后玩家应该获取的经验奖励
get_ybc_exp(Level, _Num) ->
    800 * common_tool:ceil(math:pow(Level, 1.4) * get_faction_status() * get_time_multi()).


get_time_multi() ->
    {_, {H, _, _}} = calendar:local_time(),
    case H =:= 19 of
        true ->
            1.5;
        false ->
            1
    end.


%%  镖车超时了，押金不退,其他奖励给20%
t_do_ybc_commit_timeout(YbcID) ->
    case db:read(?DB_YBC, YbcID, write) of
        [] ->
            db:abort(?_LANG_FAMILY_YBC_ALREADY_COMMIT);
        [YbcInfo] ->
            #r_ybc{group_type=GroupType, group_id=GroupID, 
                   role_list=AllRoleList,
                   creator_id=CreatorID} = YbcInfo,
            Unique = {GroupID, GroupType, CreatorID},
            db:delete(?DB_YBC_UNIQUE, Unique, write),
            db:delete(?DB_YBC, YbcID, write),
            lists:foreach(
              fun({RID, _, _, _, _}) ->
                      [RoleState] = db:read(?DB_ROLE_STATE, RID, write),
                      db:write(?DB_ROLE_STATE, RoleState#r_role_state{ybc=undefined}, write)
              end, AllRoleList),
            ok
    end.     

%% 镖车没超时
t_do_ybc_commit(YbcID) ->
    case db:read(?DB_YBC, YbcID, write) of
        [] ->
            db:abort(?_LANG_FAMILY_YBC_ALREADY_COMMIT);
        [YbcInfo] ->
            #r_ybc{group_type=GroupType, group_id=GroupID, role_list=AllRoleList,
                   creator_id=CreatorID} = YbcInfo,
            Unique = {GroupID, GroupType, CreatorID},
            db:delete(?DB_YBC_UNIQUE, Unique, write),
            db:delete(?DB_YBC, YbcID, write),
            lists:foreach(
              fun({RID, _, _, _, _}) ->
                      [RoleState] = db:read(?DB_ROLE_STATE, RID, write),
                      db:write(?DB_ROLE_STATE, RoleState#r_role_state{ybc=undefined}, write)
              end, AllRoleList),
            ok
    end.       


do_ybc_commit_error(Unique, Module, Method, Reason, PID) ->     
    R = #m_family_ybc_commit_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).

%% 检查是否能够交镖
do_ybc_commit_check(RoleID) ->
    State = mod_family:get_state(),
    YbcStatus = (State#family_state.family_info)#p_family_info.ybc_status,    
    case YbcStatus =:= ?FAMILY_YBC_STATUS_DOING of
        true ->
            ok;
        false ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_NOTHING_TO_COMMIT})
    end,
    CreatorID = (State#family_state.family_info)#p_family_info.ybc_creator_id,
    case CreatorID =:= RoleID of
        true ->
            ok;
        false ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_ONLY_CREATOR_CAN_COMMIT})
    end,
    ok.


%% 获取镖车中的玩家列表，在家族模块中实现，内部加上简单的缓存
do_ybc_list(Unique, Module, Method, RoleID, PID) ->
    State = mod_family:get_state(),
    FamilyExt = State#family_state.ext_info,
    YbcID = FamilyExt#r_family_ext.ybc_id,
    YbcStatus = (State#family_state.family_info)#p_family_info.ybc_status,
    case YbcStatus =:= ?FAMILY_YBC_STATUS_DOING of
        true ->
            do_ybc_list2(Unique, Module, Method, RoleID, PID, YbcID);
        false ->
            do_ybc_list_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_NOT_DOING, PID)
    end,
    ok.

do_ybc_list2(Unique, Module, Method, RoleID, PID, YbcID) ->
    common_misc:send_to_rolemap(RoleID, {mod_ybc_family, {get_list, YbcID, RoleID, Unique, Module, Method, PID}}).


do_ybc_list_error(Unique, Module, Method, Reason, PID) ->
    R = #m_family_ybc_list_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).

do_ybc_kick(Unique, Module, Method, Record, RoleID, PID) ->
    #m_family_ybc_kick_tos{role_id=TRoleID} = Record,
    case catch do_ybc_kick_check(RoleID, TRoleID) of
        ok ->       
            State = mod_family:get_state(),
            YbcID = (State#family_state.ext_info)#r_family_ext.ybc_id,
            case db:transaction(fun() -> t_do_ybc_kick(YbcID, TRoleID) end) of
                {atomic, NewYbcInfo} ->
                    #p_role_base{role_name=TRoleName} =  mod_role_tab:get({?role_base, TRoleID}),
                    common_misc:unicast2(PID, Unique, Module, Method, #m_family_ybc_kick_toc{role_id=TRoleID, role_name=TRoleName}),
                    RB = #m_family_ybc_kick_toc{return_self=false, role_id=TRoleID, role_name=TRoleName},
                    lists:foreach(
                      fun({RID, _RName, _RLevel, _RSB, _RB}) ->
                              case RID =:= RoleID of
                                  true ->
                                      ignore;
                                  false ->
                                      common_misc:unicast({role, RID}, ?DEFAULT_UNIQUE, Module, Method, RB)
                              end
                      end, NewYbcInfo#r_ybc.role_list),
                    common_misc:unicast({role, TRoleID}, ?DEFAULT_UNIQUE, Module, Method, RB),
                    common_ybc:update_mapinfo(YbcID, NewYbcInfo),
		    Log = lists:concat([common_tool:to_list(TRoleName),"被T出镖车队伍"]),
		    log_family_ybc(YbcID,Log),
                    ok;
                {aborted, Error} ->
                    case erlang:is_binary(Error) of
                        true ->
                            Reason = Error;
                        false ->
                            Reason = ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_KICK,
                            ?ERROR_MSG("~ts:~w", ["处理家族镖车踢人时发生系统错误", Error])
                    end,
                    do_ybc_kick_error(Unique, Module, Method, Reason, PID)
            end,
            ok;
        {error, Error} ->            
            do_ybc_kick_error(Unique, Module, Method, Error, PID);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["处理家族镖车踢人时发生系统错误", Error]),
            do_ybc_kick_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_KICK, PID)
    end,
    ok.

t_do_ybc_kick(YbcID, TRoleID) ->
    [RoleState] = db:read(?DB_ROLE_STATE, TRoleID, write),
    db:write(?DB_ROLE_STATE, RoleState#r_role_state{ybc=undefined}, write),
    [#r_ybc{role_list=RoleList} = YbcInfo] = db:read(?DB_YBC, YbcID, write),
    RoleList2 = lists:keydelete(TRoleID, 1, RoleList),
    db:write(?DB_YBC, YbcInfo#r_ybc{role_list=RoleList2}, write),    
    YbcInfo#r_ybc{role_list=RoleList2}.

do_ybc_kick_check(RoleID, TRoleID) ->
    State = mod_family:get_state(),
    FamilyExt = State#family_state.ext_info,
    FamilyInfo = State#family_state.family_info,
    YbcStatus = FamilyInfo#p_family_info.ybc_status,
    YbcID = FamilyExt#r_family_ext.ybc_id,

    %% 只有族长或者副族长才能T人
    case mod_family:is_owner_or_second_owner(RoleID, FamilyInfo) of
        true ->
            ok;
        false ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_ONLY_OWNER_OR_SECOND_OWNER_CAN_KICK})
    end,
    %% 检查镖车是否正在进行中
    case YbcStatus =:= ?FAMILY_YBC_STATUS_DOING of
        true ->
            ok;
        false ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_NOT_DOING})
    end,
    case RoleID =:= TRoleID of
        true ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_CANNT_KICK_SELF});
        false ->
            ok
    end,
    case db:dirty_read(?DB_YBC, YbcID) of
        [] ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_NOT_DOING});
        [#r_ybc{role_list=RoleList, creator_id=CreatorID}] ->
            case lists:keymember(TRoleID, 1, RoleList) of
                true ->
                    ok;
                false ->
                    erlang:throw({error, ?_LANG_FAMILY_YBC_MEMBER_NOT_IN_ROLELIST})
            end,
            case CreatorID =:= TRoleID of
                true ->
                    erlang:throw({error, ?_LANG_FAMILY_YBC_CANNT_KICK_CREATOR});
                false ->
                    ok
            end
    end,
    ok.



do_ybc_kick_error(Unique, Module, Method, Reason, PID) ->
    R = #m_family_ybc_kick_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).




%% 拉镖前的拉人动作
do_ybc_collect(Unique, Module, Method, Record, RoleID, PID) ->
    #m_family_ybc_collect_tos{content=Content} = Record,
    case catch do_ybc_collect_check(RoleID) of
        ok ->
            State = mod_family:get_state(),
            FamilyInfo = State#family_state.family_info,
            case FamilyInfo#p_family_info.owner_role_id =:= RoleID of
                true ->
                    OwnerType = 1;
                false ->
                    OwnerType = 2
            end,
            R = #m_family_ybc_collect_toc{},
            common_misc:unicast2(PID, Unique, Module, Method, R),
            #p_role_base{role_name=RoleName, faction_id=FactionID} = mod_role_tab:get({?role_base, RoleID}),
            MapID = common_misc:get_home_map_id(FactionID),
            Pos = common_npc:get_family_publish_npc_pos(),
            set_ybc_collect_pos(MapID, Pos),
            RB = #m_family_ybc_collect_toc{map_id=MapID, return_self=false, 
                                           content=Content,
                                           owner_type=OwnerType, owner_name=RoleName},
            RoleIDList = get_all_member_level_than_except(?FAMILY_YBC_MIN_LEVEL),
            common_misc:send_to_rolemap(RoleID, {mod_ybc_family, {family_ybc_collect, Module, Method, RB, RoleIDList}}),
            ok;
        {error, Error} ->
            do_ybc_collect_error(Unique, Module, Method, Error, PID);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["处理家族拉镖拉人动作时发生系统错误", Error]),
            do_ybc_collect_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_COLLECT, PID)
    end,
    ok.

set_ybc_collect_pos(MapID, Pos) ->
    erlang:put(family_ybc_collect_pos, {MapID, Pos}).
get_ybc_collect_pos(FactionID) ->
    [{Tx, Ty}] = common_config_dyn:find(personybc, {family_ybc_collect_pos, FactionID}),
    {common_misc:get_jingcheng_mapid(FactionID), #p_pos{tx=Tx, ty=Ty}}.
%%     {common_misc:get_jingcheng_mapid(FactionID), #p_pos{tx=116, ty=25}}.

do_ybc_collect_check(RoleID) ->
    State = mod_family:get_state(),
    FamilyInfo = State#family_state.family_info,
    case mod_family:is_owner_or_second_owner(RoleID, FamilyInfo) of
        true ->
            ok;
        false ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_ONLY_OWNER_OR_SECOND_OWNER_CAN_COLLECT})
    end,
    FamilyExt = State#family_state.ext_info,
    case FamilyInfo#p_family_info.ybc_status =:= ?FAMILY_YBC_STATUS_DOING of
        true ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_CANNT_COLLECT_WHEN_DOING_YBC});
        false ->
            ignore
    end,
    {Date, _} = erlang:localtime(),
    case Date =:= FamilyExt#r_family_ext.last_ybc_finish_date of
        true ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_ONE_DAY_ONLY_ONE_PUBLISH});
        false ->
            ok
    end,
    #p_role_attr{level=Level} =  mod_role_tab:get({?role_attr, RoleID}),
    case Level < ?FAMILY_YBC_MIN_LEVEL of
        true ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_LEVEL_LIMIT_WHEN_COLLECT});
        false ->
            ok
    end,
    ok.


do_ybc_collect_error(Unique, Module, Method, Reason, PID) ->
    R = #m_family_ybc_collect_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).


%% 家族成功同意被拉过去
do_ybc_agree_collect(Unique, Module, Method, RoleID, PID) ->
    {ok, #p_role_base{faction_id=FactionID}} = common_misc:get_dirty_role_base(RoleID),
    case get_ybc_collect_pos(FactionID) of
        undefined ->
            do_ybc_agree_collect_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_NO_COLLECT_CODE, PID);
        {MapID, Pos} ->
            #p_pos{tx=TX, ty=TY} = Pos, 
            R = #m_family_ybc_accept_collect_toc{},
            common_misc:unicast2(PID, Unique, Module, Method, R),
            common_misc:send_to_rolemap(RoleID, {mod_ybc_family, {family_ybc_agree_collect, Unique, Module, Method, RoleID, PID, MapID, TX, TY}})
    end.

do_ybc_agree_collect_error(Unique, Module, Method, Reason, PID) ->
    R = #m_family_ybc_accept_collect_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).



do_ybc_add_hp(_Unique, _Module, _Method, _Record, _RoleID, _PID) ->
    ok.


%% --------------------- 镖车 -------------------- %%

log_family_ybc(Content)->
    log_family_ybc(undefined,Content).
log_family_ybc(YbcIDArg,Content) ->
    State = mod_family:get_state(),
    try
        FamilyExt = State#family_state.ext_info,
        %%?INFO_MSG("FamilyExt=~w",[FamilyExt]),
        FamilyID = FamilyExt#r_family_ext.family_id,
        %%?INFO_MSG("FamilyID=~w",[FamilyID]),
        case YbcIDArg of
            undefined->
                YbcID = FamilyExt#r_family_ext.ybc_id;
            _ ->
                YbcID = YbcIDArg
        end,
        Log = #r_family_ybc_log{
          ybc_no = YbcID,
          family_id = FamilyID,
          mtime = common_tool:now(),
          content = Content
         },
        %%?INFO_MSG("Log=~w",[Log]),
        common_general_log_server:log_family_ybc(Log)
    catch 
        _:Reason -> 
            ?ERROR_MSG("State=~w, Reason: ~w, strace:~w", [State, Reason, erlang:get_stacktrace()]) 
    end.

get_role_min_level() ->
    case common_config_dyn:find(family_ybc, role_min_level) of 
        [Value] ->
            Value;
        _ ->
            10
    end.