%%% @author fsk 
%%% @doc
%%%     神王令任务
%%% @end
%%% Created : 2012-12-3
%%%-------------------------------------------------------------------
-module(mod_swl_mission).
-export([
			handle/1,
			handle/2,
			hook_monster_dead/2,
			hook_role_online/2,
			hook_role_level_change/2
		]).
-export([
			get_swl_mission_config/0,
			swl_mission_reward/2,
			find_config/1,
			refresh_daily_counter_times/2
		]).

-include("mgeem.hrl").
-define(CONFIG_NAME,swl_mission).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

-define(ERR_SWL_MISSION_NOT_OPEN,127000).%%功能未开启

%% 操作类型[0=发布查询,1=发布,2=领取查询,3=领取,4=立即完成,5=领取奖励]
-define(OP_TYPE_PUBLISH_QUERY,0).
-define(OP_TYPE_PUBLISH,1).
-define(OP_TYPE_FETCH_QUERY,2).
-define(OP_TYPE_FETCH,3).
-define(OP_TYPE_FINISH,4).
-define(OP_TYPE_REWARD,5).

%% state:0=可领取,1=进行中,2=可领奖
-define(CAN_FETCH,0).
-define(DOING,1).
-define(CAN_REWARD,2).

handle(Msg,_State) ->
	handle(Msg).
handle({swl_reset,RoleID}) ->
	TransFun = 
		fun() -> 
				NewSwlMissionInfo = #r_role_swl_mission{role_id=RoleID},
				t_set_swl_mission_info(RoleID,NewSwlMissionInfo),
				ok
		end,
	case common_transaction:t(TransFun) of
		{atomic, ok} ->
			ok;
		Reason ->
			?ERROR_MSG("swl_reset ERROR=~w",[Reason])
	end;
handle({_Unique, _Module, ?SWL_MISSION_FETCH_LIST, _DataIn, RoleID, PID, _Line}) ->
	{ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	send2manager({mission_fetch_list,RoleLevel,PID});
handle({Unique, Module, ?SWL_MISSION_OPERATE, DataIn, RoleID, PID, _Line}) ->
	swl_mission_operate({Unique,Module,?SWL_MISSION_OPERATE,DataIn,RoleID,PID});
handle({finish_publish_swl_mission,RoleID,SwlID}) ->
	finish_publish_swl_mission(RoleID,SwlID);
handle({operate_fetch,RoleID,SwlID,PID}) ->
    operate({?DEFAULT_UNIQUE,?SWL_MISSION,?SWL_MISSION_OPERATE,RoleID,SwlID,?OP_TYPE_FETCH,PID});
handle(Msg) ->
	?ERROR_MSG("~ts:~w",["未知消息", Msg]).

hook_role_online(RoleID,Level) ->
	send2manager({role_online,RoleID}),
	hook_role_level_change(RoleID,Level).
hook_role_level_change(RoleID,Level) ->
	case is_open_swl_mission(Level) of
		true ->
			case get_swl_mission_info(RoleID) of
				{ok,#r_role_swl_mission{last_time=LastTime,publish_times=PublishTimes,
										fetch_times=FetchTimes,fetch_logs=FetchLogs}} ->
					#r_swl_mission{max_publish_times=MaxPublishTimes,max_fetch_times=MaxFetchTimes} = get_swl_mission_config(RoleID),
					case is_newday(LastTime) of
						true ->
							cast_swl_mission_notify(RoleID,true,undefined,0,0);
						false ->
							case PublishTimes < MaxPublishTimes orelse FetchTimes < MaxFetchTimes of
								true ->
									cast_swl_mission_notify(RoleID,true,undefined,0,0);
								false ->
									IsAllReward = 
										lists:all(fun(#r_swl_log{state=State}) ->
														  State =:= ?CAN_FETCH
												  end, FetchLogs),
									case IsAllReward of
										false ->
											cast_swl_mission_notify(RoleID,true,undefined,0,0);
										true ->
											ignore
									end
							end
					end;
				_ ->
					ignore
			end;
		false ->
			ignore
	end.

hook_monster_dead(RoleID,TypeID) ->
	case is_fb_map() of
		false ->
			case get_swl_mission_info(RoleID) of
				{ok,SwlMissionInfo} ->
					#r_role_swl_mission{fetch_logs=FetchLogs} = SwlMissionInfo,
					NewFetchLogs =
						lists:foldl(fun(#r_swl_log{swl_id=SwlID,state=?DOING=State}=SwlLog,Acc) ->
											#p_swl_mission_monster{monster_typeid=MonsterTypeID,kill_monster_num=KillMonsterNum,monster_total_num=MonsterTotalNum,is_timeout=IsTimeOut}=p_swl_mission_monster(RoleID,SwlLog,?OP_TYPE_FETCH_QUERY),
											case IsTimeOut =:= true orelse TypeID =/= MonsterTypeID of
												true -> Acc;
												false ->
													[#p_monster_base_info{monstername=MonsterName}] = cfg_monster:find(MonsterTypeID),
													case KillMonsterNum+1 >= MonsterTotalNum of
														true -> 
															NewKillMonsterNum = 0,
															cast_swl_mission_notify(RoleID,false,MonsterName,KillMonsterNum+1,MonsterTotalNum),
															swl_mission_finished_event(RoleID),
															NewState = ?CAN_REWARD;
														false -> 
															NewKillMonsterNum = KillMonsterNum+1,
															cast_swl_mission_notify(RoleID,false,MonsterName,NewKillMonsterNum,MonsterTotalNum),
															NewState = State
													end,
													NewSwlLog = SwlLog#r_swl_log{state=NewState,kill_monster_num=NewKillMonsterNum},
													lists:keyreplace(SwlID, #r_swl_log.swl_id, Acc, NewSwlLog)
											end;
									   (_,Acc) -> Acc
									end, FetchLogs, FetchLogs),
					case NewFetchLogs =/= FetchLogs of
						true ->
							NewSwlMissionInfo = SwlMissionInfo#r_role_swl_mission{fetch_logs=NewFetchLogs},
							set_swl_mission_info(RoleID,NewSwlMissionInfo),
							{ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
							cast_operate_info(RoleID,RoleLevel,NewSwlMissionInfo,_SwlID=0,?OP_TYPE_FETCH_QUERY);
						false ->
							ignore
					end;
				_ ->
					ignore
			end;
		_ ->
			ignore
	end.

refresh_daily_counter_times(RoleID,RemainTimes) ->
	case catch get_swl_mission_config(RoleID) of
		#r_swl_mission{max_publish_times=MaxPublishTimes} ->
			ActivityID = common_tool:to_integer(common_tool:to_list(?SWL_MISSION_OPERATE) ++ common_tool:to_list(?OP_TYPE_PUBLISH)),
			case get_swl_mission_info(RoleID) of
				{ok,SwlMissionInfoTmp} ->
					IsNewDay = is_newday(SwlMissionInfoTmp#r_role_swl_mission.last_time),
					%%隔天重置数据
					case IsNewDay of
						true ->
							SwlMissionInfo = #r_role_swl_mission{role_id=RoleID},
							RealRemainTimes = 
								case  RemainTimes > 0 of
									true ->
										RemainTimes;
									_ ->
										MaxPublishTimes
								end,
							set_swl_mission_info(RoleID,SwlMissionInfo);
						false ->
							SwlMissionInfo = SwlMissionInfoTmp,
							RealRemainTimes = 
								case  RemainTimes > 0 of
									true ->
										RemainTimes;
									_ ->
										MaxPublishTimes - SwlMissionInfo#r_role_swl_mission.publish_times
								end
					end,
					mod_daily_counter:set_mission_remain_times(RoleID, ActivityID, RealRemainTimes, false);
				_ ->
					mod_daily_counter:set_mission_remain_times(RoleID, ActivityID, MaxPublishTimes, false)
			end;
		_ ->
			ignore
	end.

swl_mission_operate({Unique,Module,Method,DataIn,RoleID,PID}) ->
	#m_swl_mission_operate_tos{op_type=OpType,swl_id=SwlID} = DataIn,
	if
		OpType =:= ?OP_TYPE_PUBLISH_QUERY ->
			operate_info({Unique,Module,Method,RoleID,OpType,PID});
		OpType =:= ?OP_TYPE_FETCH_QUERY ->
			operate_info({Unique,Module,Method,RoleID,OpType,PID});
		OpType =:= ?OP_TYPE_PUBLISH ->
			operate({Unique,Module,Method,RoleID,SwlID,OpType,PID});
		OpType =:= ?OP_TYPE_FETCH ->
            {ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
            send2manager({check_swl_fetch_num,RoleID,RoleLevel,SwlID,PID});
		OpType =:= ?OP_TYPE_FINISH ->
			finish_reward({Unique,Module,Method,RoleID,SwlID,OpType,PID});
		OpType =:= ?OP_TYPE_REWARD ->
			finish_reward({Unique,Module,Method,RoleID,SwlID,OpType,PID});
		true ->
			?ERROR_MSG("swl_mission_publish ERROR,RoleID=~w,OpType=~w",[RoleID,OpType])
	end.

operate_info({_Unique,_Module,_Method,RoleID,OpType,_PID}) ->
	{ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	case get_swl_mission_info(RoleID) of
		{ok,SwlMissionInfo} ->
			cast_operate_info(RoleID,RoleLevel,SwlMissionInfo,_SwlID=0,OpType);
		_ ->
			?ERROR_MSG("publish_info ERROR=~w",[RoleID])
	end.

cast_operate_info(RoleID,RoleLevel,SwlMissionInfoTmp,SwlID,OpType) ->
	R2 =
		case is_open_swl_mission(RoleLevel) of
			true ->
				IsNewDay = is_newday(SwlMissionInfoTmp#r_role_swl_mission.last_time),
				%%隔天重置数据
				case IsNewDay of
					true ->
						InitSwlMissionInfo = #r_role_swl_mission{role_id=RoleID},
						set_swl_mission_info(RoleID,InitSwlMissionInfo),
						SwlMissionInfo = InitSwlMissionInfo;
					false ->
						SwlMissionInfo = SwlMissionInfoTmp
				end,
				#r_role_swl_mission{publish_times=PublishTimes,publish_logs=PublishLogs,
									fetch_times=FetchTimes,fetch_logs=FetchLogs} = SwlMissionInfo,
				#r_swl_mission{max_publish_times=MaxPublishTimes,max_fetch_times=MaxFetchTimes,swls=Swls} = get_swl_mission_config(RoleID),
				Logs = 
					lists:map(fun({SwlID2,_,_,_})->
									  Exp = swl_mission_reward(SwlID2,RoleLevel),
									  Logs = 
										  case is_publish_operate(OpType) of
											  true -> PublishLogs;
											  false -> FetchLogs
										  end,
									  Log = lists:keyfind(SwlID2, #r_swl_log.swl_id, Logs),
									  case Log =/= false of
										  true ->
											  Monster = p_swl_mission_monster(RoleID,Log,OpType),
											  #r_swl_log{swl_id=SwlID2,num=Num,finish_num=FinishNum,state=State}=Log,
											  case is_publish_operate(OpType) of
												  true -> NewState = ?CAN_FETCH;
												  false -> NewState = State
											  end,
											  #p_swl_mission_operate_log{swl_id=SwlID2,num=Num,finish_num=FinishNum,exp=Exp,state=NewState,monster=Monster};
										  false ->
											  #p_swl_mission_operate_log{swl_id=SwlID2,num=0,finish_num=0,exp=Exp,state=?CAN_FETCH}
									  end
							  end, Swls),
				{Times,MaxTimes} =
					case is_publish_operate(OpType) of
						true ->
							{PublishTimes,MaxPublishTimes};
						false -> 
							{FetchTimes,MaxFetchTimes}
					end,
				#m_swl_mission_operate_toc{swl_id=SwlID,times=Times,max_times=MaxTimes,op_type=OpType,logs=Logs};
			false ->
				#m_swl_mission_operate_toc{err_code=?ERR_SWL_MISSION_NOT_OPEN}
		end,
	common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?SWL_MISSION,?SWL_MISSION_OPERATE,R2).

operate({Unique,Module,Method,RoleID,SwlID,OpType,PID}) ->
	TransFun = fun()-> t_operate(RoleID,SwlID,OpType) end,
	case common_transaction:t( TransFun ) of
		{atomic, {ok,NewSwlMissionInfo,RoleLevel,UpList,DelList}} ->
			case OpType of
				?OP_TYPE_PUBLISH ->
					%%发送给manager随机加经验
					RewardExp = swl_mission_reward(SwlID,RoleLevel),
					send2manager({publish_swl_mission,RoleID,SwlID,RewardExp,RoleLevel}),
					hook_activity_task:done_task(RoleID, ?ACTIVITY_TASK_SWL);
				?OP_TYPE_FETCH -> 
					%%发送给manager减少可领取神王令个数
					send2manager({reduce_swl_fetch_num,RoleID,RoleLevel,SwlID}),
					hook_activity_task:done_task(RoleID, ?ACTIVITY_TASK_SWL)
			end,
			common_misc:del_goods_notify(PID,DelList),
			common_misc:update_goods_notify(PID,UpList),
			cast_operate_info(RoleID,RoleLevel,NewSwlMissionInfo,SwlID,OpType);
		{aborted, AbortErr} ->
			{error,ErrCode,Reason} = common_misc:parse_aborted_err(AbortErr),
			?UNICAST_TOC(#m_swl_mission_operate_toc{op_type=OpType,err_code=ErrCode,reason=Reason})
	end.

t_operate(RoleID,SwlID,OpType) ->
	{ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	case is_open_swl_mission(RoleLevel) of
		true ->
			case get_swl_mission_info(RoleID) of
				{ok,#r_role_swl_mission{last_time=LastTime,publish_times=PublishTimes,publish_logs=PublishLogs,
										fetch_times=FetchTimes,fetch_logs=FetchLogs}=SwlMissionInfo} ->
					assert_operate_time(LastTime),
					#r_swl_mission{max_publish_times=MaxPublishTimes,max_fetch_times=MaxFetchTimes,swls=Swls} = get_swl_mission_config(RoleID),
					case lists:keyfind(SwlID,1,Swls) of
						false -> Swl=null,?THROW_ERR_REASON(<<"没该神王令">>);
						Swl -> next
					end,
					case OpType of
						?OP_TYPE_PUBLISH ->
							{ok,UpList,DelList} = mod_bag:decrease_goods_by_typeid(RoleID,SwlID,1),
							Times = PublishTimes,
							MaxTimes = MaxPublishTimes,
							Logs = PublishLogs;
						?OP_TYPE_FETCH ->
							UpList=DelList=[],
							Times = FetchTimes,
							MaxTimes = MaxFetchTimes,
							Logs = FetchLogs
					end,
					case is_times_limit(Times,MaxTimes,LastTime) of
						true -> ?THROW_ERR_REASON(<<"次数已满">>);
						false -> next
					end,
					Now = mgeem_map:get_now(),
					NewLogs = 
						case lists:keyfind(SwlID,#r_swl_log.swl_id,Logs) of
							false ->
								[#r_swl_log{swl_id=SwlID,num=1,state=?DOING} | Logs];
							#r_swl_log{num=Num,state=State,last_kill_time=LastKillTime}=SwlLog ->
								case OpType of
									?OP_TYPE_FETCH ->
										TimeLimit = ?find_config(fetch_mission_seconds_limit),
										IsTimeout = TimeLimit < (mgeem_map:get_now()-LastKillTime),
										case State =/= ?CAN_FETCH andalso IsTimeout =:= false of
											true -> ?THROW_ERR_REASON(<<"状态错误">>);
											false -> next
										end,
										NewState=?DOING,
										MonsterList = erlang:element(4, Swl),
										MonsterIndex = erlang:element(1,common_tool:random_element(MonsterList));
									_ -> NewState=State,MonsterIndex = 0
								end,
								NewNum =
									case is_newday(LastTime) of
										true -> 1;
										false -> Num+1
									end,
								lists:keyreplace(SwlID, #r_swl_log.swl_id, Logs, SwlLog#r_swl_log{num=NewNum,state=NewState,
																								  monster_index=MonsterIndex,last_kill_time=Now,kill_monster_num=0})
						end,
					case OpType of
						?OP_TYPE_PUBLISH ->
							NewSwlMissionInfo = SwlMissionInfo#r_role_swl_mission{last_time=Now,publish_times=PublishTimes+1,
																				  publish_logs=NewLogs},
							ActivityID = common_tool:to_integer(common_tool:to_list(?SWL_MISSION_OPERATE) ++ common_tool:to_list(?OP_TYPE_PUBLISH)),
							mod_daily_counter:set_mission_remain_times(RoleID, ActivityID, MaxPublishTimes-PublishTimes-1, true);
						?OP_TYPE_FETCH -> 
							NewSwlMissionInfo = SwlMissionInfo#r_role_swl_mission{last_time=Now,fetch_times=FetchTimes+1,
																				  fetch_logs=NewLogs}
					end,
					t_set_swl_mission_info(RoleID, NewSwlMissionInfo),
					{ok,NewSwlMissionInfo,RoleLevel,UpList,DelList};
				_ ->
					?THROW_SYS_ERR()
			end;
		false ->
			?THROW_ERR(?ERR_SWL_MISSION_NOT_OPEN)
	end.

%% 完成神王令任务的事件
swl_mission_finished_event(_RoleID) -> ok.
	% hook_activity_task:done_task(RoleID, ?ACTIVITY_TASK_SWL).

finish_reward({Unique,Module,Method,RoleID,SwlID,OpType,PID}) ->
	TransFun = fun()-> t_finish_reward(RoleID,SwlID,OpType) end,
	case common_transaction:t( TransFun ) of
		{atomic, {ok,NewSwlMissionInfo,RoleLevel,NewRoleAttr,DeductMoney}} ->
			case OpType of
				?OP_TYPE_REWARD ->
					RewardExp = swl_mission_reward(SwlID,RoleLevel),
					?TRY_CATCH(mod_map_role:do_add_exp(RoleID,RewardExp));
				?OP_TYPE_FINISH ->
					swl_mission_finished_event(RoleID);
				_ -> ignore
			end,
			case NewRoleAttr of
				null -> ingore;
				_ ->
					?ROLE_SYSTEM_BROADCAST(RoleID,lists:concat(["立即完成神王令任务，消耗",DeductMoney,"元宝"])),
					common_misc:send_role_gold_change(RoleID,NewRoleAttr)
			end,
			cast_operate_info(RoleID,RoleLevel,NewSwlMissionInfo,SwlID,OpType);
		{aborted, AbortErr} ->
			{error,ErrCode,Reason} = common_misc:parse_aborted_err(AbortErr),
			?UNICAST_TOC(#m_swl_mission_operate_toc{op_type=OpType,err_code=ErrCode,reason=Reason})
	end.

t_finish_reward(RoleID,SwlID,OpType) ->
	{ok,#p_role_attr{level=RoleLevel}=RoleAttr} = mod_map_role:get_role_attr(RoleID),
	case get_swl_mission_info(RoleID) of
		{ok,#r_role_swl_mission{last_time=LastTime,fetch_logs=Logs}=SwlMissionInfo} ->
			assert_operate_time(LastTime),
			#r_swl_mission{swls=Swls} = get_swl_mission_config(RoleID),
			case lists:keyfind(SwlID,1,Swls) of
				false -> Swl=null,?THROW_SYS_ERR();
				Swl -> next
			end,
			NewLogs = 
				case lists:keyfind(SwlID,#r_swl_log.swl_id,Logs) of
					false ->
						NewRoleAttr = DeductMoney = null,
						?THROW_SYS_ERR();
					#r_swl_log{finish_num=FinishNum,state=State}=SwlLog ->
						case OpType of
							?OP_TYPE_FINISH ->
								case State =/= ?DOING of
									true -> ?THROW_ERR_REASON("状态错误");
									false -> next
								end,
								{MoneyType,DeductMoney} = erlang:element(3, Swl),
								case common_bag2:t_deduct_money(MoneyType, DeductMoney, RoleAttr, ?CONSUME_TYPE_GOLD_FINISH_SWL_MISSION) of
									{ok,NewRoleAttr} ->
										mod_map_role:set_role_attr(RoleID,NewRoleAttr);
									{error, Reason} ->
										NewRoleAttr = null,
										?THROW_ERR(?ERR_OTHER_ERR, Reason)
								end,								
								NewFinishNum = FinishNum+1,
								NewState = ?CAN_REWARD;
							?OP_TYPE_REWARD ->
								case State =/= ?CAN_REWARD of
									true -> ?THROW_ERR_REASON("状态错误");
									false -> next
								end,
								NewRoleAttr = DeductMoney = null,
								NewFinishNum = FinishNum,
								NewState = ?CAN_FETCH
						end,
						lists:keyreplace(SwlID, #r_swl_log.swl_id, Logs, SwlLog#r_swl_log{monster_index=0,kill_monster_num=0,last_kill_time=0,finish_num=NewFinishNum,state=NewState})
				end,
			NewSwlMissionInfo = SwlMissionInfo#r_role_swl_mission{last_time=mgeem_map:get_now(),fetch_logs=NewLogs},
			t_set_swl_mission_info(RoleID, NewSwlMissionInfo),
			{ok,NewSwlMissionInfo,RoleLevel,NewRoleAttr,DeductMoney};
		_ ->
			?THROW_SYS_ERR()
	end.
	
p_swl_mission_monster(RoleID,FetchLog,OpType) ->
	#r_swl_log{swl_id=SwlID,state=State,monster_index=MonsterIndex,kill_monster_num=KillMonsterNum,last_kill_time=LastKillTime} = FetchLog,
	case State =:= ?DOING andalso is_publish_operate(OpType) =:= false of
		true ->
			#r_swl_mission{swls=Swls} = get_swl_mission_config(RoleID),
			MonsterList = erlang:element(4, lists:keyfind(SwlID, 1, Swls)),
			case lists:keyfind(MonsterIndex, 1, MonsterList) of
				false -> Monster = lists:nth(1, MonsterList);
				Monster -> next
			end,
			{_,MonsterTypeID,MonsterTotalNum,Map} = Monster,
			MapID = 
				case is_integer(Map) of
					true -> Map;
					false ->
						{ok,#p_role_base{faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
						erlang:element(2,lists:keyfind(FactionID,1,Map))
				end,
			TimeLimit = ?find_config(fetch_mission_seconds_limit),
			IsTimeout = TimeLimit < (mgeem_map:get_now()-LastKillTime),
			#p_swl_mission_monster{kill_monster_num=KillMonsterNum,monster_mapid=MapID,
								   monster_total_num=MonsterTotalNum,monster_typeid=MonsterTypeID,
								   is_timeout=IsTimeout};
		_ -> undefined
	end.

finish_publish_swl_mission(RoleID,SwlID) ->
	case get_swl_mission_info(RoleID) of
		{ok,#r_role_swl_mission{publish_logs=Logs}=SwlMissionInfo} ->
			case lists:keyfind(SwlID,#r_swl_log.swl_id,Logs) of
				false ->
					ignore;
				#r_swl_log{finish_num=FinishNum}=SwlLog ->
					NewLogs =
						lists:keyreplace(SwlID, #r_swl_log.swl_id, Logs, 
										 SwlLog#r_swl_log{last_kill_time=mgeem_map:get_now(),finish_num=FinishNum+1,state=?CAN_FETCH}),
					NewSwlMissionInfo=SwlMissionInfo#r_role_swl_mission{publish_logs=NewLogs},
					set_swl_mission_info(RoleID, NewSwlMissionInfo)
			end;
		_ ->
			ignore
	end.

is_fb_map() ->
	?IS_FB_MAP(mgeem_map:get_mapid()).

is_open_swl_mission(Level) ->
	[MinRoleLevel] = ?find_config(open_min_role_level),
	Level >= MinRoleLevel.
cast_swl_mission_notify(RoleID,IsOpen,MonsterName,KillMonsterNum,MonsterTotalNum) ->
	R2 = #m_swl_mission_notify_toc{monster_name=MonsterName,is_open=IsOpen,
										   monster_total_num=MonsterTotalNum,kill_monster_num=KillMonsterNum},
	common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?SWL_MISSION,?SWL_MISSION_NOTIFY,R2).

t_set_swl_mission_info(RoleID, SwlMissionInfo) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,RoleExtInfo} ->
			NewSwlMissionInfo = RoleExtInfo#r_role_map_ext{swl_mission=SwlMissionInfo},
			mod_map_role:t_set_role_map_ext_info(RoleID, NewSwlMissionInfo),
			ok;
		Reason ->
			?ERROR_MSG("t_set_swl_mission_info error,RoleID=~w,SwlMissionInfo=~w,Reason=~w",[RoleID,SwlMissionInfo,Reason]),
			?THROW_SYS_ERR()
	end.

set_swl_mission_info(RoleID, SwlMissionInfo) ->
	case common_transaction:t(fun() -> 
									  t_set_swl_mission_info(RoleID, SwlMissionInfo),
									  ok
							  end) of
		{atomic, ok} ->
			ok;
		Reason ->
			?ERROR_MSG("set_swl_mission_info,RoleID=~w,SwlMissionInfo=~w,Reason=~w",[RoleID,SwlMissionInfo,Reason])
	end.

get_swl_mission_info(RoleID) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{swl_mission=SwlMissionInfo}} ->
			{ok, SwlMissionInfo};
		_ ->
			{error, not_found}
	end.

get_swl_mission_config() ->
	[SwlMissionList] = ?find_config(swl_mission),
	SwlMissionList.
get_swl_mission_config(RoleID) ->
	{ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	SwlMissionList = get_swl_mission_config(),
	get_swl_mission_config(SwlMissionList,RoleLevel).

get_swl_mission_config([],_) ->
	?THROW_ERR(?ERR_SWL_MISSION_NOT_OPEN);
get_swl_mission_config([H|T],RoleLevel) ->
	#r_swl_mission{level_section={MinLevel,MaxLevel}} = H,
	case RoleLevel >= MinLevel andalso RoleLevel =< MaxLevel of
		true ->
			H;
		false ->
			get_swl_mission_config(T,RoleLevel)
	end.

is_publish_operate(OpType) ->
	lists:member(OpType,[?OP_TYPE_PUBLISH_QUERY,?OP_TYPE_PUBLISH]).

is_newday(LastTime) ->
	not common_time:is_today(LastTime).

is_times_limit(Times,MaxTimes,LastTime) ->
	case common_time:is_today(LastTime) of
		true -> Times >= MaxTimes;
		false -> false
	end.

assert_operate_time(LastTime) ->
	case is_newday(LastTime) of
		true -> next;
		false ->
			[{StartTime,EndTime}] = ?find_config(mission_time_section),
			Time = time(),
			case Time >= StartTime andalso Time =< EndTime of
				true -> next;
				false -> ?THROW_ERR_REASON("神王令活动时间已经结束")
			end
	end.

swl_mission_reward(SwlID,RoleLevel) ->
	[MissionReward] = ?find_config(swl_mission_reward),
	case lists:keyfind(SwlID, 1, MissionReward) of
		false -> 0;
		{_,Multi} ->
			[MissionBaseExp] = ?find_config(swl_mission_base_exp),
			case lists:keyfind(RoleLevel, 1, MissionBaseExp) of
				false -> 0;
				{_,BaseExp} -> common_tool:ceil(Multi * BaseExp)
			end
	end.

find_config(Key) ->
	?find_config(Key).

%%将消息发送到mod_swl_mission_manager
send2manager(Info)->
    case global:whereis_name( mod_swl_mission_manager ) of
        undefined->
            ?ERROR_MSG("send2manager error",[]);
        PID->
            PID ! Info
    end.