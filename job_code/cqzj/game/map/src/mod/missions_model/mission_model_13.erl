%%% @author bisonwu <wuzesen@gmail.com>
%% Created: 2011-6-22
%% Description: 特殊事件的侦听器 - 3次对话 - 中间状态去完成事件
%%      model_status: 必须是3个Status
%%      listener：必须是特殊事件的侦听器
%%          listener_type=5,11
-module(mission_model_13, [RoleID, MissionID, MissionBaseInfo]).
-behaviour(b_mission_model).

%%
%% Include files
%%

-include("mission.hrl").  
%%特殊事件模型的第二个状态
-define(MISSION_MODEL_13_STATUS_DOING, 1).


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
                       ListenerVal = ListenerData#mission_listener_trigger_data.value,
                       i_trigger_event(ListenerList, PInfo, ListenerVal)
               end,
    ?DO_TRANS_FUN( TransFun ).


%%@doc 如果是刚接任务 加侦听器
i_deal_listener(PInfo, _RequestRecord) ->
	CurrentModelStatus = PInfo#p_mission_info.current_model_status,
	MaxModelStatus = MissionBaseInfo#mission_base_info.max_model_status,
	
	if
		CurrentModelStatus =:= ?MISSION_MODEL_STATUS_FIRST ->
			ListenerListConfig = MissionBaseInfo#mission_base_info.listener_list,
			ListenerList = 
				lists:map(fun(ListenerDataConfig) ->
								  #mission_listener_data{type=ListenerType,value=ListenerValue,
														 need_num=NeedNum,int_list=IntList} = ListenerDataConfig,
								  ?TRY_CATCH(assert_complete_mission(ListenerType,RoleID,ListenerValue,NeedNum)),
								  %%道具侦听器
								  mod_mission_data:join_to_listener(RoleID, MissionID, ListenerType, ListenerValue),
								  %%直接将玩家侦听器数据设置为已经满足要求
								  #p_mission_listener{type=ListenerType,
													  value=ListenerValue,
													  int_list=IntList,
													  need_num=NeedNum,
													  current_num=0}
						  end, ListenerListConfig),
			%%怪物ID/怪物当前数量/所需数量
			PInfo#p_mission_info{listener_list=ListenerList};
		CurrentModelStatus =:= ?MISSION_MODEL_13_STATUS_DOING ->
			ListenerListConfig = MissionBaseInfo#mission_base_info.listener_list,
			PropTypeIDList = 
				lists:map(fun(ListenerDataConfig) ->
								  ListenerDataConfig#mission_listener_data.value
						  end, ListenerListConfig),
			throw({?MISSION_ERROR_MAN, ?MISSION_CODE_FAIL_NOT_BUY_NEED_PROP, PropTypeIDList});
		CurrentModelStatus =:= MaxModelStatus ->
			%%任务即将提交 删除侦听器
			ListenerList = PInfo#p_mission_info.listener_list,
			i_remove_all_listener(ListenerList),
			PInfo;
		true ->
			PInfo
	end.

change_status_for_trigger(Listener,PInfo,AddStep) when is_integer(AddStep)->
	ListenerList2=[Listener#p_mission_listener{current_num=1}],
	NewPInfo = PInfo#p_mission_info{listener_list=ListenerList2},
	mission_model_common:change_model_status(RoleID, MissionID, MissionBaseInfo, NewPInfo, AddStep).

i_trigger_event([], _PInfo, _SpecialEventId) ->
	ignore;
i_trigger_event([Listener], PInfo, _SpecialEventId) ->
	MaxModelStauts = MissionBaseInfo#mission_base_info.max_model_status,
	CurrentModelStatus = PInfo#p_mission_info.current_model_status,
	
	if
		MaxModelStauts =:= CurrentModelStatus->
			ignore;
		true->
			change_status_for_trigger(Listener,PInfo,+1)
	end.

%%@doc 删除所有侦听器
i_remove_all_listener(ListenerList) ->
	lists:foreach(
	  fun(ListenerData) ->
			  ListenerType = ListenerData#p_mission_listener.type,
			  ListenerValue = ListenerData#p_mission_listener.value,
			  
			  mod_mission_data:remove_from_listener(
				RoleID, MissionID, 
				ListenerType, ListenerValue)
	  
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

%% 判断任务条件是否满足，满足则完成任务 
%% 装备强化
assert_complete_mission(ListenerType,RoleID,ListenerValue,_NeedNum) 
  when ListenerType =:= ?MISSION_LISTENER_TYPE_EQUIP_QIANGHUA orelse
		   ListenerType =:= ?MISSION_LISTENER_TYPE_MOUNT_QIANGHUA orelse
		   ListenerType =:= ?MISSION_LISTENER_TYPE_FASHION_QIANGHUA ->
	{ok,#p_role_attr{equips=Equips}} = mod_map_role:get_role_attr(RoleID),
	AssertFunc = fun(PGoodsList) ->
						 lists:any(fun(#p_goods{type=Type,typeid=TypeID,reinforce_result=Level}) ->
										   case Type of
											   ?TYPE_EQUIP ->
												   [#p_equip_base_info{slot_num=SlotNum}] = common_config_dyn:find_equip(TypeID),
												   case SlotNum of
													   ?PUT_MOUNT ->
														   Level >= ListenerValue andalso		
															   ListenerType =:= ?MISSION_LISTENER_TYPE_MOUNT_QIANGHUA;
													   ?PUT_FASHION ->
														   Level >= ListenerValue andalso		
															   ListenerType =:= ?MISSION_LISTENER_TYPE_FASHION_QIANGHUA;
													   _ ->
														   Level >= ListenerValue andalso		
															   ListenerType =:= ?MISSION_LISTENER_TYPE_EQUIP_QIANGHUA
												   end;
											   _ ->
												   false
										   end
								   end, PGoodsList)
				 end,
	%%身上装备
	Msg={mod_mission_handler,{listener_dispatch,special_listener_value_up,RoleID,ListenerType,ListenerValue}},
	case AssertFunc(Equips) of
		true ->
			mgeer_role:absend(RoleID,Msg);
		false ->
			%%背包
			case mod_bag:get_bag_goods_list(RoleID,false) of
				{ok,AllGoodsList} ->
					case AssertFunc(AllGoodsList) of
						true ->
							mgeer_role:absend(RoleID,Msg);
						false ->
							ignore
					end;
				_ ->
					ignore
			end
	end;
assert_complete_mission(?MISSION_LISTENER_TYPE_SKILL_UPGRADE,RoleID,ListenerValue,_NeedNum) ->
	RoleSkillList = mod_skill:get_role_skill_list(RoleID),
	case lists:any(fun(#r_role_skill_info{skill_id=SkillID,cur_level=CurLevel})->
					  mod_skill:is_star_skill(RoleID, SkillID) andalso CurLevel >= ListenerValue
					  end,RoleSkillList) of
		true ->
			Msg={mod_mission_handler,{listener_dispatch,special_listener_value_up,RoleID,?MISSION_LISTENER_TYPE_SKILL_UPGRADE,ListenerValue}},
			mgeer_role:absend(RoleID,Msg);
		false ->
			ignore
	end;
assert_complete_mission(_ListenerType,_RoleID,_ListenerValue,_NeedNum) ->
	ignore.





