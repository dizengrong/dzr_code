%% Author: caochuncheng
%% Created: 2011-10-13
%% Description: 使用道具，召唤怪物并打死怪物完成任务(接受任务需要扣取一定的钱币)
%%      model_status: 3个status
%%      listener：必须是道具的侦听器
-module(mission_model_18, [RoleID, MissionID, MissionBaseInfo]).
-behaviour(b_mission_model).

%%
%% Include files
%%
-include("mission.hrl").  
-define(MISSION_MODEL_18_STATUS_DOING, 1). %% 此状态下需要玩家使用道具召唤怪物并打死怪物

%%
%% Exported Functions
%%
-export([
     auth_accept/1,
     auth_show/1,
     do/2,
     cancel/2,
     listener_trigger/3,
     init_pinfo/1]).

%%
%% API Functions
%%
%%@doc 验证是否可接
auth_accept(_PInfo) -> 
	mod_mission_auth:auth_accept(RoleID, MissionBaseInfo).

%%@doc 验证是否可以出现在任务列表
auth_show(_PInfo) -> 
	mod_mission_auth:auth_show(RoleID, MissionBaseInfo).

%%@doc 执行任务 接-做-交
do(PInfo, RequestRecord) ->
    TransFun = 
        fun() ->
                case i_deal_listener(PInfo, RequestRecord) of
                    ignore ->
                        #m_mission_do_toc{
                            id=MissionID,
                            current_status=PInfo#p_mission_info.current_status,
                            pre_status=PInfo#p_mission_info.pre_status,
                            current_model_status=PInfo#p_mission_info.current_model_status,
                            pre_model_status=PInfo#p_mission_info.pre_model_status,
                            code=?MISSION_CODE_SUCC,
                            code_data=[]};
                    NewPInfo ->
                        mission_model_common:common_do(RoleID, MissionID,MissionBaseInfo,RequestRecord, NewPInfo)
                end
        end,
    ?DO_TRANS_FUN( TransFun ).

%%@doc 取消任务
cancel(PInfo, RequestRecord) ->
    TransFun = 
        fun() ->
                case MissionBaseInfo#mission_base_info.big_group > 0 of
                    true ->
                        [CancelCycleCountBigGroupList] = common_config_dyn:find(mission_etc, cancel_cycle_count_biggroup),
                        case lists:member(MissionBaseInfo#mission_base_info.big_group, CancelCycleCountBigGroupList) of
                            true ->
                                mod_mission_data:set_succ_times(RoleID, MissionBaseInfo, 1);
                            _ ->
                                ignore
                        end;
                    _ ->
                        ignore
                end,
                Result = mission_model_common:common_cancel(RoleID, MissionID, MissionBaseInfo, RequestRecord, PInfo),
                %%@doc 删除侦听器
                ListenerList = PInfo#p_mission_info.listener_list,
                i_remove_all_listener(ListenerList),
                
                Result
        end,
    ?DO_TRANS_FUN( TransFun ).

%%@doc 侦听器触发
listener_trigger(ListenerData, PInfo,_TriggerParam) -> 
    TransFun = fun() ->
                       ListenerList = PInfo#p_mission_info.listener_list,
                       ListenerTriggerType = ListenerData#mission_listener_trigger_data.type,
                       ListenerTriggerValue = ListenerData#mission_listener_trigger_data.value,
                       i_trigger(ListenerTriggerType, PInfo, ListenerTriggerValue, ListenerList)
               end,
    ?DO_TRANS_FUN( TransFun ).


%%@doc 如果是刚接任务 加侦听器
i_deal_listener(PInfo, RequestRecord) ->
    CurrentModelStatus = PInfo#p_mission_info.current_model_status,
    MaxModelStatus = MissionBaseInfo#mission_base_info.max_model_status,
    if
        CurrentModelStatus =:= ?MISSION_MODEL_STATUS_FIRST ->
            check_money_enough_and_throw(RoleID),

            ListenerListConfig = MissionBaseInfo#mission_base_info.listener_list,
            ListenerList = 
                lists:map(fun(ListenerDataConfig) ->
                    ListenerType = ListenerDataConfig#mission_listener_data.type,
                    NeedPropTypeID = ListenerDataConfig#mission_listener_data.value,
                    NeedNum = ListenerDataConfig#mission_listener_data.need_num,
                    IntList =  ListenerDataConfig#mission_listener_data.int_list,
                    case ListenerType of
                        ?MISSION_LISTENER_TYPE_GIVE_USE_PROP ->
                            ModelStatusData = lists:nth(CurrentModelStatus + 2,MissionBaseInfo#mission_base_info.model_status_data),
                            case lists:keyfind(NeedPropTypeID,#mission_status_data_use_item.item_id,ModelStatusData#mission_status_data.use_item_point_list) of
                                false ->
                                    UsePosList = [];
                                #mission_status_data_use_item{map_id=UseMapId,tx=UseTx,ty=UseTy} ->
                                    UsePosList = [UseMapId,UseTx,UseTy]
                            end,
                            [GivePropNpcID] = ListenerDataConfig#mission_listener_data.int_list,
                            if  GivePropNpcID =:= RequestRecord#m_mission_do_tos.npc_id ->
                                    mod_mission_misc:give_prop(RoleID, NeedPropTypeID, NeedNum, true, UsePosList),
                                    CurrentNum = 0;
                                true ->
                                    CurrentNum = 0
                            end;
                        _ ->
                            CurrentNum = 0
                    end,
                    %%道具侦听器
                    mod_mission_data:join_to_listener(RoleID, MissionID, ListenerType, NeedPropTypeID),
                    %%直接将玩家侦听器数据设置为已经满足要求
                    #p_mission_listener{type=ListenerType,
                                        value=NeedPropTypeID,
                                        int_list=IntList,
                                        need_num=NeedNum,
                                        current_num=CurrentNum}
                end, ListenerListConfig),
                %%怪物ID/怪物当前数量/所需数量
            case t_deduct_money(RoleID) of
                ok ->
                    next;
                {not_enough_silver,DeductMoney} ->
                    throw({?MISSION_ERROR_MAN, ?MISSION_CODE_AUTHFAIL_ROLE_SILVER_LIMIT, [DeductMoney]});
                {error, Reason} ->
                    ?THROW_ERR(?ERR_OTHER_ERR, Reason)
            end,
            PInfo#p_mission_info{listener_list=ListenerList};
        CurrentModelStatus =:= MaxModelStatus ->
            %%任务即将提交 删除侦听器
            ListenerList = PInfo#p_mission_info.listener_list,
            i_remove_all_listener(ListenerList),
            PInfo;
        true ->
            PInfo
    end.


i_trigger(?MISSION_LISTENER_TYPE_GIVE_USE_PROP, PInfo, GiveUseTypeID, ListenerList) ->
    i_trigger_give_use_prop(ListenerList, PInfo, GiveUseTypeID, 0, 0, [], null);
i_trigger(?MISSION_LISTENER_TYPE_MONSTER, PInfo, DeadMonsterType, ListenerList) ->
    i_trigger_monster(ListenerList, PInfo, DeadMonsterType, 0, 0, [], null).


%% 使用一个赠送的任务道具
i_trigger_give_use_prop([], PInfo, _GiveUseTypeID, TotalNeed, Complete, NewListenerList, MatchListenerData) ->
    NewPInfo = PInfo#p_mission_info{listener_list=NewListenerList},
    MaxModelStauts = MissionBaseInfo#mission_base_info.max_model_status,
    CurrentModelStatus = PInfo#p_mission_info.current_model_status,
    if MatchListenerData =:= null ->%%居然没找到这个侦听器
           ignore;
       TotalNeed =:= Complete andalso  MaxModelStauts =:= CurrentModelStatus->
           ignore;
       TotalNeed =:= Complete ->
           %%切换状态    删除侦听器
           mission_model_common:change_model_status(RoleID, MissionID, MissionBaseInfo, NewPInfo, +1),
           %%发送最后一次的任务侦听器数据
           DataRecord = #m_mission_listener_toc{mission_id=MissionID, listener=MatchListenerData},
           mod_mission_unicast:p_unicast(RoleID, ?DEFAULT_UNIQUE, ?MISSION, ?MISSION_LISTENER, DataRecord),
           mod_mission_unicast:c_unicast(RoleID);
       TotalNeed > Complete ->
            %%单独更新侦听器数据
            mod_mission_data:set_pinfo(RoleID, NewPInfo),
            DataRecord = #m_mission_listener_toc{mission_id=MissionID, listener=MatchListenerData},
            mod_mission_unicast:p_unicast(RoleID, ?DEFAULT_UNIQUE, ?MISSION, ?MISSION_LISTENER, DataRecord),
            mod_mission_unicast:c_unicast(RoleID)
    end;
i_trigger_give_use_prop([ListenerData|ListenerList], PInfo, GiveUseTypeID, TotalNeed,Complete, NewListenerList, MatchListenerData) ->
    NeedGiveUseTypeID = ListenerData#p_mission_listener.value,
    CurrentNum = ListenerData#p_mission_listener.current_num,
    NeedNum = ListenerData#p_mission_listener.need_num,
    if GiveUseTypeID =:= NeedGiveUseTypeID ->
            NewCurrentNum = CurrentNum+1;
        true ->
            NewCurrentNum = CurrentNum
    end,
    if NewCurrentNum >= NeedNum ->
            NewComplete = Complete+1;
       true ->
            NewComplete = Complete
    end,
    NewListenerData = ListenerData#p_mission_listener{current_num=NewCurrentNum},
    if GiveUseTypeID =:= NeedGiveUseTypeID ->
            NewMatchListenerData = NewListenerData;
        true ->
            NewMatchListenerData = MatchListenerData
    end,
    i_trigger_give_use_prop(ListenerList, PInfo, GiveUseTypeID, TotalNeed+1, NewComplete, [NewListenerData|NewListenerList], NewMatchListenerData).

i_trigger_monster([], PInfo, _DeadMonsterType, TotalNeed, Complete, NewListenerList, MatchListenerData) ->
    NewPInfo = PInfo#p_mission_info{listener_list=NewListenerList},
    if MatchListenerData =:= null ->
            %%居然没找到这个侦听器
            ignore;
        TotalNeed =:= Complete ->
            %%切换状态
            %%删除所有侦听器
            i_remove_all_listener(PInfo#p_mission_info.listener_list),
            mission_model_common:change_model_status(RoleID, MissionID, MissionBaseInfo,NewPInfo, +1),
            %%发送最后一次的任务侦听器数据
            DataRecord = #m_mission_listener_toc{mission_id=MissionID, listener=MatchListenerData},
            mod_mission_unicast:p_unicast(RoleID, ?DEFAULT_UNIQUE, ?MISSION, ?MISSION_LISTENER, DataRecord),
            mod_mission_unicast:c_unicast(RoleID);
        TotalNeed > Complete ->
            %%单独更新侦听器数据
            mod_mission_data:set_pinfo(RoleID, NewPInfo),
            DataRecord = #m_mission_listener_toc{mission_id=MissionID, listener=MatchListenerData},
            mod_mission_unicast:p_unicast(RoleID, ?DEFAULT_UNIQUE, ?MISSION, ?MISSION_LISTENER, DataRecord),
            mod_mission_unicast:c_unicast(RoleID)
    end;
i_trigger_monster([ListenerData|ListenerList], PInfo, DeadMonsterType, TotalNeed, Complete, NewListenerList,  MatchListenerData) ->
    NeedMonsterType = ListenerData#p_mission_listener.value,
    CurrentNum = ListenerData#p_mission_listener.current_num,
    NeedNum = ListenerData#p_mission_listener.need_num,
    if DeadMonsterType =:= NeedMonsterType ->
            NewCurrentNum = CurrentNum+1;
        true ->
            NewCurrentNum = CurrentNum
    end,
    if NewCurrentNum >= NeedNum ->
            NewComplete = Complete+1;
        NewCurrentNum < NeedNum ->
            NewComplete = Complete
    end,
    NewListenerData = ListenerData#p_mission_listener{current_num=NewCurrentNum},
    if
        DeadMonsterType =:= NeedMonsterType ->
            NewMatchListenerData = NewListenerData;
        true ->
            NewMatchListenerData = MatchListenerData
    end,
    i_trigger_monster(ListenerList, PInfo, DeadMonsterType, TotalNeed+1, NewComplete, [NewListenerData|NewListenerList], NewMatchListenerData).

%%@doc 删除所有侦听器
i_remove_all_listener(ListenerList) ->
    lists:foreach(fun(ListenerData) ->
        ListenerType = ListenerData#p_mission_listener.type,
        NeedPropTypeID = ListenerData#p_mission_listener.value,
        NeedNum = ListenerData#p_mission_listener.need_num,
        mod_mission_data:remove_from_listener(RoleID, MissionID,ListenerType, NeedPropTypeID),
        case ListenerData#p_mission_listener.type =:= ?MISSION_LISTENER_TYPE_GIVE_USE_PROP of
            true ->
                case mod_bag:check_inbag_by_typeid(RoleID,NeedPropTypeID) of
                    {ok,_FoundGoodsList} ->
                        mod_mission_misc:del_prop(RoleID, NeedPropTypeID, NeedNum);
                    _->
                        ignore
                end;
            _ ->
                ignore
        end
    end, ListenerList).
    
%%@doc 初始化任务pinfo
%%@return #p_mission_info{} | false
init_pinfo(OldPInfo) -> 
    NewPInfo = mission_model_common:init_pinfo(RoleID, OldPInfo, MissionBaseInfo),
    CurrentStatus = NewPInfo#p_mission_info.current_model_status,
    if
        CurrentStatus =/= ?MISSION_MODEL_STATUS_FIRST ->
            NewPInfo;
        true ->
            case auth_show(NewPInfo) of
                true->
                    NewPInfo;
                _ ->
                    false
           end
    end.

check_money_enough_and_throw(RoleID) ->
    case common_config_dyn:find(cang_bao_tu_fb,accept_mission_model_18_cost) of
        [] ->
            ok;
        [{MoneyType,DeductMoney}] ->
            common_bag2:check_money_enough_and_throw(MoneyType,DeductMoney,RoleID)
    end.

t_deduct_money(RoleID)->
	case common_config_dyn:find(cang_bao_tu_fb,accept_mission_model_18_cost) of
		[] ->
			ok;
		[{MoneyType,DeductMoney}] ->
			case common_bag2:t_deduct_money(MoneyType,DeductMoney,RoleID,?CONSUME_TYPE_SILVER_ACCEPT_MISSION_MODEL_18_COST) of
				{ok,RoleAttr}->
					common_misc:send_role_silver_change(RoleID,RoleAttr),
					ok;
                {error, Reason} ->
                    {error, Reason};
				_ ->
					{not_enough_silver,DeductMoney}
			end
	end.