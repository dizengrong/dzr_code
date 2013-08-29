%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  7 Dec 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_ybc_family).

%% API
-export([
         handle/2,return_family_ybc_silver_and_reward/5
        ]).

-include("mgeem.hrl").

handle(Info, _State) ->
    do_handle_info(Info).

do_handle_info({family_ybc_publish, FamilyPID, RoleID, Yajin, Module, Method, RB, RoleIDList}) ->
    do_family_ybc_publish(FamilyPID, RoleID, Yajin, Module, Method, RB, RoleIDList);
do_handle_info({family_ybc_commit, RoleID, YbcID, FamilyPID}) ->
    do_family_ybc_commit(RoleID, YbcID, FamilyPID);
do_handle_info({family_ybc_collect, Module, Method, RB, RoleIDList}) ->
    do_family_ybc_collect(Module, Method, RB, RoleIDList);
do_handle_info({family_ybc_agree_publish, FamilyPID, RoleID, NeedSilver}) ->
    do_family_ybc_agree_publish(FamilyPID, RoleID, NeedSilver);
do_handle_info({family_ybc_sure, FamilyPID, YbcCreateInfo}) ->
    do_family_ybc_sure(FamilyPID, YbcCreateInfo);
do_handle_info({family_ybc_invite, RoleIDList, Module, Method, RB}) ->
    do_family_ybc_invite(RoleIDList, Module, Method, RB);
do_handle_info({ybc_timeout_delete, YbcID}) ->
    do_family_ybc_timeout_delete(YbcID);
do_handle_info({family_ybc_agree_collect, Unique, Module, Method, RoleID, PID, MapID, TX, TY}) ->
    do_family_ybc_agree_collect(Unique, Module, Method, RoleID, PID, MapID, TX, TY);
do_handle_info({get_list, YbcID, _RoleID, Unique, Module, Method, PID}) ->
    do_get_list(YbcID, Unique, Module, Method, PID);
do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知的消息", Info]).

do_ybc_agree_collect_check(RoleID) ->
    %% 检查状态
    {ok, #p_role_base{status=Status}} = mod_map_role:get_role_base(RoleID),
    [#r_role_state{stall_self=StallSelf, ybc=Ybc,trading=Trading}] = db:dirty_read(?DB_ROLE_STATE, RoleID),
    MapID = mgeem_map:get_mapid(),
    [JailMapID] = common_config_dyn:find(jail, jail_map_id),
    case Status =:= ?ROLE_STATE_DEAD 
		orelse StallSelf =:= true 
		orelse (Ybc =/= undefined andalso Ybc =/= 0)  
		orelse Trading =:= 1
        orelse MapID =:= JailMapID
    of
        true ->
            if Trading =:= 1 ->
                    throw({error, ?_LANG_FAMILY_YBC_ALREADY_IN_TRADING_WHEN_AGREE_COLLECT});
               JailMapID =:= MapID ->
                    throw({error, ?_LANG_FAMILY_YBC_IN_JAIL});
               true ->
                    case Status =:= ?ROLE_STATE_DEAD of
                        true ->
                            Reason = io_lib:format(?_LANG_FAMILY_YBC_SPECIAL_STATUS_CANNT_ACCEPT_COLLECT, [common_role:get_state_string(Status)]),
                            erlang:throw({error, Reason});
                        false ->
                            %%检查是否已经处于拉镖状态中
                            case Ybc =/= undefined andalso Ybc > 0 of
                                true ->
                                    erlang:throw({error, ?_LANG_FAMILY_YBC_ALREADY_IN_YBC_WHEN_AGREE_COLLECT});
                                false ->
                                    ok
                            end
                    end
            end;
        false ->
            ok
    end,
    ok.

%% 同意被族长召集
do_family_ybc_agree_collect(Unique, Module, Method, RoleID, PID, MapID, TX, TY) ->
    case catch do_ybc_agree_collect_check(RoleID) of
        ok ->                
            mod_map_actor:handle({change_map_by_call,?CHANGE_MAP_FAMILY_YBC_CALL,RoleID}, mgeem_map:get_state()),
            mod_map_role:do_change_map(RoleID, MapID, TX, TY, ?CHANGE_MAP_TYPE_NORMAL),
            RC = #m_map_change_map_toc{mapid=MapID, tx=TX, ty=TY},
            common_misc:unicast2(PID, ?DEFAULT_UNIQUE, ?MAP, ?MAP_CHANGE_MAP, RC),
            ok;
        {error, Error} ->
            do_ybc_agree_collect_error(Unique, Module, Method, Error, PID);
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["处理同意家族拉镖拉人", Error]),
            do_ybc_agree_collect_error(Unique, Module, Method, ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_AGREE_COLLECT, PID)
    end,
    ok.

do_ybc_agree_collect_error(Unique, Module, Method, Reason, PID) ->
    R = #m_family_ybc_accept_collect_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, R).


do_get_list(YbcID, Unique, Module, Method, PID) ->
    case mod_map_ybc:get_ybc_full_info(YbcID) of
        undefined ->
            %% 当玩家跟镖车不同地图时，刷新返回错误信息，前端可设置本身状态为远离
            Record = #m_family_ybc_list_toc{succ=false, reason=?_LANG_FAMILY_YBC_NOT_FOUND},
            common_misc:unicast2(PID, Unique, Module, Method, Record);
        #r_ybc{creator_id=CreatorId, role_list=RoleList} ->
            #p_pos{tx=YTX, ty=YTY} = mod_map_actor:get_actor_pos(YbcID, ybc),
            Members = lists:foldl(
                        fun({RID, RoleName, _, _, _}, Acc) ->
                                case mod_map_actor:get_actor_pos(RID, role) of
                                    undefined ->
                                        RoleChatProcess = common_misc:chat_get_role_pname(RID),
                                        case global:whereis_name(RoleChatProcess) of
                                            undefined ->
                                                State = ?YBC_FAMILY_MEMBER_STATUS_OFFLINE;
                                            _ ->
                                                State = ?YBC_FAMILY_MEMBER_STATUS_FARAWAY
                                        end;
                                    #p_pos{tx=TX, ty=TY} ->
                                        case erlang:abs(TX-YTX) < 15 andalso erlang:abs(TY-YTY) < 15 of
                                            true ->
                                                State = ?YBC_FAMILY_MEMBER_STATUS_NORMAL;
                                            false ->
                                                State = ?YBC_FAMILY_MEMBER_STATUS_FARAWAY
                                        end
                                end,
                                R = #p_family_ybc_member_info{role_id=RID, role_name=RoleName,
                                                              status=State},
                                [R | Acc]
                        end, [], RoleList),
            Record = #m_family_ybc_list_toc{leader_role_id=CreatorId,members=Members},
            common_misc:unicast2(PID, Unique, Module, Method, Record)
    end.

do_family_ybc_timeout_delete(YbcID) ->
    mod_map_ybc:do_del_ybc(YbcID).

do_family_ybc_invite(RoleIDList, Module, Method, RB) ->
    %% 获取家族拉镖发布NPC的位置
    {TX, TY} = common_npc:get_family_publish_npc_pos(),
    %% 过滤所有不在本地图或者不在NPC附近的玩家
    RoleIDList2 = lists:filter(
                    fun(RoleID) ->
                            case mod_map_actor:get_actor_pos(RoleID, role) of
                                undefined ->
                                    false;
                                #p_pos{tx=RTX, ty=RTY} ->
                                    %% 判断是否在NPC附近
                                    (erlang:abs(RTX - TX) < 12) andalso (erlang:abs(RTY - TY) < 12)
                            end
                    end, RoleIDList),
    mgeem_map:broadcast(RoleIDList2, Module, Method, RB).

do_family_ybc_sure(FamilyPID, YbcCreateInfo) ->
    case db:transaction(fun() -> t_ybc_sure(YbcCreateInfo) end) of
        {atomic, {YbcID, YbcInfo}} ->
            FamilyPID ! {ybc_sure_succ, YbcID},
            mod_map_ybc:do_enter(YbcInfo),
            mod_map_ybc:addto_ybc_list(YbcID), 
            ok;
        {aborted, Error} ->
            case erlang:is_binary(Error) of
                true ->
                    Reason = Error;
                false ->
                    case Error of
                        {recreate, YbcID, YbcInfo} ->
                            ?ERROR_MSG("~ts:~w", ["镖车已经存在", YbcInfo]),
                            mod_map_ybc:addto_ybc_list(YbcID),
                            mod_map_ybc:do_enter(YbcInfo),
                            Reason = "镖车已经存在";
                        _ ->
                            ?ERROR_MSG("~ts:~w", ["确认发布镖车时发生系统错误", Error]),
                            Reason = ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_SURE
                    end
            end,
            FamilyPID ! {ybc_sure_failed, Reason}
    end.


t_ybc_sure(YbcCreateInfo) -> 
    {TX, TY} = common_npc:get_family_publish_npc_pos(),
    {ok, #p_pos{tx=RTX, ty=RTY}} = mod_map_role:get_role_pos(YbcCreateInfo#p_ybc_create_info.creator_id),
    case erlang:abs(RTX - TX) > 12 orelse erlang:abs(RTY - TY) > 12 of
        true ->
            db:abort(?_LANG_FAMILY_YBC_NOT_NEAR_NPC_WHEN_SURE);
        false ->
            ok
    end,
    {YbcID, YbcInfo} = mod_map_ybc:t_do_create_ybc(YbcCreateInfo),
    {YbcID, YbcInfo}.


%% 族员同意加入镖车队伍
do_family_ybc_agree_publish(FamilyPID, RoleID, NeedSilver) ->
    case catch do_family_ybc_agree_publish_check(RoleID) of
        ok ->
            case db:transaction(fun() -> t_do_family_ybc_agree_publish(RoleID, NeedSilver) end) of
                {atomic, RoleAttr} ->
                    FamilyPID ! {ybc_agree_publish_succ, RoleID, RoleAttr, NeedSilver},
                    ok;
                {aborted, Error} ->
                    case erlang:is_binary(Error) of
                        true ->
                            Reason = Error;
                        false ->
                            ?ERROR_MSG("~ts:~w", ["同意加入家族拉镖发生系统错误", Error]),
                            Reason = ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_AGREE_PUBLISH
                    end,
                    FamilyPID ! {ybc_agree_publish_failed, RoleID, Reason}
            end;
        {error, Reason} ->
            FamilyPID ! {ybc_agree_publish_failed, RoleID, Reason};
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["同意加入家族拉镖发生系统错误", Error]),
            Reason = ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_AGREE_PUBLISH,
            FamilyPID ! {ybc_agree_publish_failed, RoleID, Reason}
    end,
    ok.

%% 加入队伍后要扣除钱币
t_do_family_ybc_agree_publish(RoleID, NeedSilver) ->
    case mod_map_role:get_role_attr(RoleID) of
        {ok, #p_role_attr{silver=Silver} = RoleAttr} ->
            case Silver >= NeedSilver of
                true ->
                    {ok, #p_role_base{status=Status}} = mod_map_role:get_role_base(RoleID),
                    case Status =:= ?ROLE_STATE_DEAD of
                        true ->
                            Reason = io_lib:format(?_LANG_FAMILY_YBC_SPECIAL_STATUS_CANNT_ACCEPT_PUBLISH, 
                                                   [common_role:get_state_string(Status)]),
                            db:abort(common_tool:to_binary(Reason));
                        false ->
                            ok
                    end,    
                    [#r_role_state{stall_self=StallSelf, ybc=Ybc} = RoleState] = db:read(?DB_ROLE_STATE, RoleID, write),
                    case StallSelf of 
                        true ->
                            Reason2 = io_lib:format(?_LANG_FAMILY_YBC_SPECIAL_STATUS_CANNT_ACCEPT_PUBLISH, 
                                                    [common_role:get_state_string(?ROLE_STATE_STALL_SELF)]),
                            db:abort(common_tool:to_binary(Reason2));
                        _ ->
                            ok
                    end,                    
                    %%检查是否已经处于拉镖状态中
                    case Ybc =/= undefined andalso Ybc > 0 of
                        true ->
                            db:abort(?_LANG_FAMILY_YBC_ALREADY_IN_YBC_WHEN_AGREE_PUBLISH);
                        false ->
                            ok
                    end,
                    common_consume_logger:use_silver({RoleID, 0, NeedSilver, ?CONSUME_TYPE_SILVER_FAMILY_YBC, ""}),
                    db:write(?DB_ROLE_STATE, RoleState#r_role_state{ybc=?ROLE_STATE_YBC_FAMILY}, write),
                    NewRoleAttr = RoleAttr#p_role_attr{silver=Silver - NeedSilver},
                    mod_map_role:set_role_attr(RoleID, NewRoleAttr),
                    NewRoleAttr;
                false -> 
                    db:abort(common_tool:to_binary(io_lib:format(?_LANG_FAMILY_YBC_SILVER_NOT_ENOUGH_WHEN_AGREE_PUBLISH,[common_misc:format_silver(NeedSilver-Silver)])))
            end;
        {error, _} ->
            db:abort(?_LANG_FAMILY_YBC_ROLE_NOT_ONLINE_WHEN_AGREE_PUBLISH)
    end.

do_family_ybc_agree_publish_check(RoleID) ->
    case mod_map_role:get_role_base(RoleID) of
        {ok, #p_role_base{faction_id=FactionID, status=Status}} ->
            [#r_role_state{stall_self=StallSelf, ybc=Ybc}] = db:dirty_read(?DB_ROLE_STATE, RoleID),
            case Status =:= ?ROLE_STATE_DEAD of
                true ->
                    Reason = io_lib:format(?_LANG_FAMILY_YBC_SPECIAL_STATUS_CANNT_ACCEPT_PUBLISH, 
                                           [common_role:get_state_string(Status)]),
                    db:abort(common_tool:to_binary(Reason));
                false ->
                    ok
            end,    
            case StallSelf of 
                true ->
                    Reason2 = io_lib:format(?_LANG_FAMILY_YBC_SPECIAL_STATUS_CANNT_ACCEPT_PUBLISH, 
                                            [common_role:get_state_string(?ROLE_STATE_STALL_SELF)]),
                    db:abort(common_tool:to_binary(Reason2));
                _ ->
                    ok
            end,
            %%检查是否已经处于拉镖状态中
            case Ybc =/= undefined andalso Ybc > 0 of
                true ->
                    db:abort(?_LANG_FAMILY_YBC_ALREADY_IN_YBC_WHEN_AGREE_PUBLISH);
                false ->
                    ok
            end,
            MapID = mgeem_map:get_mapid(),
            %% 检查玩家是否在史可法附近
            {YMapID, {YTX, YTY}} = common_npc:get_family_ybc_publish_pos(FactionID),
            {ok, #p_pos{tx=TX, ty=TY}} = mod_map_role:get_role_pos(RoleID),
            case erlang:abs(TX - YTX) < 15 andalso erlang:abs(TY - YTY) < 15 andalso MapID =:= YMapID of
                true ->
                    ok;
                false ->
                    throw({error, ?_LANG_FAMILY_YBC_POS_NOT_IN_SENCE_WHEN_AGREE_PUBLISH})
            end;
        {error, _} ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_ROLE_NOT_ONLINE_WHEN_AGREE_PUBLISH})
    end.


%%家族接镖之前的拉人
do_family_ybc_collect(Module, Method, RB, RoleIDList) ->
    %% 获取家族拉镖发布NPC的位置
    {TX, TY} = common_npc:get_family_publish_npc_pos(),
    %% 过滤所有不在本地图或者不在NPC附近的玩家
    RoleIDList2 = lists:filter(
                    fun(RoleID) ->
                            case mod_map_actor:get_actor_pos(RoleID, role) of
                                undefined ->
                                    true;
                                #p_pos{tx=RTX, ty=RTY} ->
                                    %% 判断是否在NPC附近
                                    not ((erlang:abs(RTX - TX) < 12) andalso (erlang:abs(RTY - TY) < 12))
                            end
                    end, RoleIDList),
    %% 通知玩家召集
    lists:foreach(
      fun(MemberID) -> 
              common_misc:unicast({role,MemberID},?DEFAULT_UNIQUE,Module,Method,RB)
      end, RoleIDList2).

t_do_family_ybc_publish(RoleID, Yajin) ->
    %% 如果玩家下线了这里是undefined，也是没有关系的
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    #p_role_attr{silver=Silver} = RoleAttr,
    case Yajin > Silver of
        true ->
            db:abort(common_tool:to_binary(io_lib:format(?_LANG_FAMILY_YBC_NOT_ENOUGH_MONEY_FOR_PUBLISH, [common_tool:silver_to_string(Yajin)])));
        false ->
            ok
    end,    
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    #p_role_base{status=Status} = RoleBase,
    [#r_role_state{stall_self=StallSelf, ybc=Ybc} = RoleState] = db:read(?DB_ROLE_STATE, RoleID, write),
    case Status =:= ?ROLE_STATE_DEAD of
        true ->
            Reason = io_lib:format(?_LANG_FAMILY_YBC_SPECIAL_STATUS_CANNT_PUBLISH, [common_role:get_state_string(Status)]),
            db:abort(common_tool:to_binary(Reason));
        false ->
            ok
    end,    
    case StallSelf of 
        true ->
            Reason2 = io_lib:format(?_LANG_FAMILY_YBC_SPECIAL_STATUS_CANNT_PUBLISH, [common_role:get_state_string(?ROLE_STATE_STALL_SELF)]),
            db:abort(common_tool:to_binary(Reason2));
        _ ->
            ok
    end,
    %%检查是否已经处于拉镖状态中
    case Ybc =/= undefined andalso Ybc > 0 of
        true ->
            db:abort(?_LANG_FAMILY_YBC_ALREADY_IN_YBC_WHEN_AGREE_PUBLISH);
        false ->
            ok
    end,
    common_consume_logger:use_silver({RoleID, 0, Yajin, ?CONSUME_TYPE_SILVER_FAMILY_YBC, ""}),
    RoleAttr2 = RoleAttr#p_role_attr{silver=Silver - Yajin},
    mod_map_role:set_role_attr(RoleID, RoleAttr2),
    db:write(?DB_ROLE_STATE, RoleState#r_role_state{ybc=?ROLE_STATE_YBC_FAMILY}, write),
    RoleAttr2.


%% 家族镖车发布后，需要通知在NPC附近的玩家来参与拉镖
do_family_ybc_publish(FamilyPID, RoleID, Yajin, Module, Method, RB, RoleIDList) ->
    case db:transaction(fun() -> t_do_family_ybc_publish(RoleID, Yajin) end) of
        {atomic, RoleAttr} ->
            FamilyPID ! {ybc_publish_succ, RoleAttr},
            %% 获取家族拉镖发布NPC的位置
            {TX, TY} = common_npc:get_family_publish_npc_pos(),
            %% 过滤所有不在本地图或者不在NPC附近的玩家
            lists:foreach(
              fun(RID) ->
                      case mod_map_actor:get_actor_pos(RID, role) of
                          undefined ->
                              common_misc:unicast({role, RID}, ?DEFAULT_UNIQUE, Module, Method,
                                                  RB#m_family_ybc_publish_toc{is_alert=false}),
                              false;
                          #p_pos{tx=RTX, ty=RTY} ->
                              %% 判断是否在NPC附近
                              case (erlang:abs(RTX - TX) < 12) andalso (erlang:abs(RTY - TY) < 12) of
                                  true ->
                                      common_misc:unicast({role, RID}, ?DEFAULT_UNIQUE, Module, Method,
                                                          RB#m_family_ybc_publish_toc{is_alert=true});
                                  false ->
                                      common_misc:unicast({role, RID}, ?DEFAULT_UNIQUE, Module, Method,
                                                          RB#m_family_ybc_publish_toc{is_alert=false})
                              end
                      end
              end, RoleIDList),
            ok;
        {aborted, Error} ->
            case erlang:is_binary(Error) of
                true ->
                    Reason = Error;
                false ->
                    ?ERROR_MSG("~ts:~w", ["发布镖车时扣除玩家钱币出错", Error]),
                    Reason = ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_REDUCE_SILVER_ON_PUBLISH
            end,
            FamilyPID ! {ybc_publish_failed, Reason}
    end.


%% 家族镖车交镖                                
do_family_ybc_commit(RoleID, YbcID, FamilyPID) ->
    case catch do_family_ybc_commit_check(RoleID, YbcID) of
        ok ->            
            %% 遍历获取哪些家族成员在NPC附近，直接加钱即可，状态更新暂时有家族去处理（事务过程尽量不要放在地图中进行）
            case mod_map_ybc:get_ybc_full_info(YbcID) of
                undefined ->
                    FamilyPID ! {ybc_commit_error, ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_COMMIT};
                #r_ybc{role_list=RoleList, create_time=CreatorTime} ->
                    TimeOut = common_tool:now() - CreatorTime > 3600,
                    do_family_ybc_commit2(RoleList, TimeOut, FamilyPID),
                    FamilyPID ! {ybc_commit_succ, RoleList, RoleList, TimeOut}
            end;
        {error, Error} ->            
            FamilyPID ! {ybc_commit_error, Error};
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts:~w", ["检查家族镖车能否交镖时发生系统错误", Error]),
            FamilyPID ! {ybc_commit_error, ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_COMMIT}
    end.   

do_family_ybc_commit2(RoleList, TimeOut, FamilyPID) ->    
    lists:foreach(
      fun({RID, RName, RLevel, _SB, Silver}) ->
              case TimeOut of
                  true ->
                      ignore;
                  false ->
                      %% 退押金 并 奖励铜钱
					  RewardBindSilver = common_ybc:get_family_ybc_reward(RLevel),
                      case mod_map_role:get_role_attr(RID) of
                          {error, role_not_found} -> %%族员没在本地图
                              common_misc:send_to_rolemap(RID, {mod_map_role, {return_family_ybc_silver_and_reward, RID, RName, FamilyPID, Silver, RewardBindSilver}});
                          {ok, _RoleAttr} ->
                              return_family_ybc_silver_and_reward(RID,RName,FamilyPID,Silver,RewardBindSilver)
                      end
              end
      end, RoleList).

get_ybc_silver_multiple() ->
    1.

%% 检查家族镖车任务能否提交
do_family_ybc_commit_check(RoleID, YbcID) ->
    {ok, #p_role_base{faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
    TargetMapID = common_ybc:get_ybc_commit_mapid(FactionID),
    {NTX, NTY} = common_npc:get_family_ybc_npc_pos(),
    case TargetMapID =:= mgeem_map:get_mapid() of
        true ->
            ok;
        false ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_CREATOR_NOT_NEAR_NPC})
    end,
    %% 族长的位置是否在NPC附近
    case mod_map_actor:get_actor_pos(RoleID, role) of
        undefined ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_CREATOR_NOT_ONLINE});
        #p_pos{tx=RTX, ty=RTY} ->
            case (erlang:abs(NTX-RTX) < 12) andalso (erlang:abs(NTY - RTY) < 12) of
                true ->
                    ok;
                false ->
                    erlang:throw({error, ?_LANG_FAMILY_YBC_CREATOR_NOT_NEAR_NPC})
            end
    end,
    %% 镖车是否在NPC附近
    case mod_map_actor:get_actor_pos(YbcID, ybc) of
        undefined ->
            erlang:throw({error, ?_LANG_FAMILY_YBC_YBC_NOT_NEAR_NPC});
        #p_pos{tx=YTX, ty=YTY} ->
            case (erlang:abs(NTX-YTX) < 12) andalso (erlang:abs(NTY - YTY) < 12) of
                true ->
                    ok;
                false ->
                    erlang:throw({error, ?_LANG_FAMILY_YBC_YBC_NOT_NEAR_NPC})
            end
    end,
    ok.

return_family_ybc_silver_and_reward(RoleID,RoleName,FamilyPID,Silver,RewardSilverBind) ->
    case common_transaction:transaction(fun() -> t_return_family_ybc_silver_and_reward(RoleID,Silver,RewardSilverBind) end) of
        {atomic, _} ->
            {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
            ChangeList = [
                          #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value=RoleAttr#p_role_attr.silver},
                          #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value=RoleAttr#p_role_attr.silver_bind}],
            common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
            %% 添加一个hook，用于通知某些模块某个角色完成家族拉镖了
            hook_map_role:done_family_ybc(RoleID, RoleName);
        {aborted, Error} ->
            ?ERROR_MSG("~ts:~w", ["检查家族镖车能否交镖时发生系统错误", Error]),
            FamilyPID ! {ybc_commit_error, ?_LANG_FAMILY_YBC_SYSTEM_ERROR_WHEN_COMMIT}
    end.

t_return_family_ybc_silver_and_reward(RoleID,Silver,RewardSilverBind) ->
    {ok, #p_role_attr{silver=OldSilver,silver_bind=OldSilverBind} = RoleAttr} = mod_map_role:get_role_attr(RoleID),
    mod_map_role:set_role_attr(RoleID, RoleAttr#p_role_attr{silver=OldSilver + get_ybc_silver_multiple() * Silver,silver_bind=OldSilverBind + RewardSilverBind}),
    common_consume_logger:gain_silver({RoleID, RewardSilverBind, Silver, ?GAIN_TYPE_SILVER_FAMILY_YBC, ""}).

