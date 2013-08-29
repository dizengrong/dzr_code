%%% @author fsk 
%%% @doc
%%%     日常循环任务
%%% @end
%%% Created : 2012-9-14
%%%-------------------------------------------------------------------
-module(mod_daily_mission).
-export([
			handle/1,
			handle/2,
			hook_monster_dead/2,
			hook_role_level_change/2,
			hook_role_online/2
		]).
-export([
			daily_mission_info/1,
			daily_mission_refresh/1,
			daily_mission_finish/1,
			refresh_daily_counter_times/2
		]).

-include("mgeem.hrl").
-record(r_daily_mission,{level_section,daily_mission_loop_times=0,monster_level_probality=[],monster_level_list=[],reduce_monster_level_cost,give_lowest_monster_level_times,
						 reward_level_probality,reward_level_list=[],promote_reward_level_cost,give_highest_reward_level_times,
						 direct_finish_cost,last_rewards
						 }).

-define(CONFIG_NAME,daily_mission).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

%% 0=刷怪物难度星级,1=刷奖励星级
-define(REFRESH_MONSTER_LEVEL,0).
-define(REFRESH_REWARD_LEVEL,1).

%% 0=直接完成本环循环任务/正常完成本环循环任务,1=一键最优完成剩余任务次数,2=领取完成所有任务的附加奖励
-define(FINISH_MISSION,0).
-define(FINISH_MISSION_PERFECT_REWARD,1).
-define(FINISH_MISSION_LAST_REWARD,2).

-define(ERR_DAILY_MISSION_NOT_OPEN,553000).%%日常循环任务功能未开启
-define(ERR_DAILY_MISSION_HAS_FINISH_ALL_MISSION,553001).%%今天已经做完所有日常循环任务
-define(ERR_DAILY_MISSION_NOT_FINISH_ALL_MISSION,553002).%%今天还没做完所有日常循环任务，不能领取附加奖励
-define(ERR_DAILY_MISSION_HAS_GOT_LAST_REWARDS,553003).%%今天已经领取了附加奖励

handle(Msg,_State) ->
	handle(Msg).
handle({get_daily_mission,RoleID}) ->
	{ok, _DailyMissionInfo} = get_daily_mission_info(RoleID);
handle({set_daily_mission,RoleID,DailyMissionInfo}) ->
	case common_transaction:t(fun() -> 
									  t_set_daily_mission_info(RoleID,DailyMissionInfo)
							  end) of
		{atomic, _} ->
			cast_daily_mission_info(DailyMissionInfo),
			ok;
		Reason ->
			?ERROR_MSG("set_daily_mission error,RoleID=~w,DailyMissionInfo=~w,Reason=~w",[RoleID,DailyMissionInfo,Reason])
	end;
handle({set_finish_times,RoleID,FinishTimes}) ->
	case common_transaction:t(fun() -> 
									  {ok, DailyMissionInfo} = get_daily_mission_info(RoleID),
									  NewDailyMissionInfo = DailyMissionInfo#r_role_daily_mission{finish_times=FinishTimes,
																								  got_last_rewards=false,
																								  refresh_monster_level_times=0,
																								  kill_monster_num=0,
																								  last_time=mgeem_map:get_now(),
																								  refresh_reward_level_times=0},
									  t_set_daily_mission_info(RoleID,NewDailyMissionInfo),
									  {ok,NewDailyMissionInfo}
							  end) of
		{atomic, {ok,NewDailyMissionInfo}} ->
			cast_daily_mission_info(NewDailyMissionInfo);
		Reason ->
			?ERROR_MSG("set_finish_times error,RoleID=~w,FinishTimes=~w,Reason=~w",[RoleID,FinishTimes,Reason])
	end;
handle(Msg) ->
	?ERROR_MSG("~ts:~w",["未知消息", Msg]).

refresh_daily_counter_times(RoleID,RemainTimes) when erlang:is_integer(RemainTimes) ->
	{ok,#p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
	[MinLevel] = ?find_config(open_min_role_level),
	case Level >= MinLevel of
		true ->
			case get_daily_mission_info(RoleID) of
				{ok,#r_role_daily_mission{finish_times=FinishTimes,last_time=LastTime,kill_monster_num=KillMonsterNum,role_level=RoleLevelTmp}=DailyMissionInfo} ->
					RealRemainTimes = 
						case common_time:is_today(LastTime) of
							true ->
								RoleLevel = 
									case KillMonsterNum > 0 of
										true -> 
											RoleLevelTmp;
										false -> 
											Level
									end,
								get_daily_mission_times(RoleID,DailyMissionInfo,RemainTimes,FinishTimes,RoleLevel);
							false ->
								get_loop_times(Level) 
						end;
				_ ->
					RealRemainTimes = get_daily_mission_times(RemainTimes,Level)
			end,
			mod_daily_counter:set_mission_remain_times(RoleID, ?ROLE2_DAILY_MISSION_FINISH, RealRemainTimes, false);
		_ ->
			ignore
	end.

get_daily_mission_times(RemainTimes,Level) ->
	LoopTimes = abs(get_loop_times(Level)),
	case RemainTimes > 0 of
		true ->
			LoopTimes - RemainTimes;
		_ ->
			LoopTimes
	end.

get_loop_times(Level) ->
	[DailyMissionConfList] = ?find_config(daily_mission),
	case catch get_daily_mission_config(DailyMissionConfList,Level) of
		#r_daily_mission{daily_mission_loop_times=LoopTimes}  ->
			LoopTimes;
		_ ->
			0
	end.	

get_daily_mission_times(RoleID,DailyMissionInfo,RemainTimes,FinishTimes,RoleLevel) ->
	LoopTimes = abs(get_loop_times(RoleLevel)),
	case RemainTimes > 0 of
		true ->
			set_daily_mission_info(RoleID, DailyMissionInfo#r_role_daily_mission{finish_times=LoopTimes-RemainTimes}),
			LoopTimes - RemainTimes;
		_ ->
			LoopTimes - FinishTimes
	end.

hook_monster_dead(RoleID,TypeID) ->
	{ok,#p_role_attr{level=Level2}} = mod_map_role:get_role_attr(RoleID),
	
	case is_open_daily_mission(Level2) of
		true ->
			case get_daily_mission_info(RoleID) of
				{ok,DailyMissionInfo} ->
					#r_role_daily_mission{finish_times=FinishTimes,kill_monster_num=KillMonsterNum,last_time=LastTime,
										  monster_level=MonsterLevel,monster_index=MonsterIndex,role_level=RoleLevel} = DailyMissionInfo,
					case is_open_daily_mission(RoleLevel) of
						true ->
							DailyMissionConf = get_daily_mission_config(DailyMissionInfo),
							#r_daily_mission{daily_mission_loop_times=LoopTimes} = DailyMissionConf,
							PMonster = p_daily_mission_monster(RoleID,MonsterLevel,MonsterIndex,KillMonsterNum,DailyMissionConf),
							#p_daily_mission_monster{monster_typeid=MonsterTypeID,monster_total_num=MonsterTotalNum} = PMonster,
							case FinishTimes < LoopTimes andalso common_time:is_today(LastTime) of
								true ->
									case TypeID =:= MonsterTypeID andalso KillMonsterNum < MonsterTotalNum of
										true ->
											NewKillMonsterNum = KillMonsterNum + 1,
											NewDailyMissionInfo = DailyMissionInfo#r_role_daily_mission{kill_monster_num=NewKillMonsterNum,last_time=mgeem_map:get_now()},
											set_daily_mission_info(RoleID,NewDailyMissionInfo),
											[#p_monster_base_info{monstername=MonsterName}] = cfg_monster:find(MonsterTypeID),
											cast_daily_mission_notify(RoleID,false,MonsterName,NewKillMonsterNum,MonsterTotalNum);
										false ->
											ignore
									end;
								false ->
									ignore
							end;
						false ->
							ignore
					end;
				_ ->
					ignore
			end;
		_ ->
			ignore
	end.

hook_role_online(RoleID,Level) ->
	hook_role_level_change(RoleID,Level).
hook_role_level_change(RoleID,Level) ->
	case is_open_daily_mission(Level) of
		true ->
			case get_daily_mission_info(RoleID) of
				{ok,#r_role_daily_mission{got_last_rewards=GotLastRewards,last_time=LastTime}} ->
					case common_time:is_today(LastTime) andalso GotLastRewards of
						true ->
							ignore;
						false ->
							cast_daily_mission_notify(RoleID,true,undefined,0,0)
					end;
				false ->
					ignore
			end;
		false ->
			ignore
	end.

is_open_daily_mission(Level) ->
	[MinRoleLevel] = ?find_config(open_min_role_level),
	Level >= MinRoleLevel.

daily_mission_info({Unique, Module, Method, RoleID, PID}) ->
	case catch cast_daily_mission_info(RoleID) of
		{error,ErrCode,_} ->
			?UNICAST_TOC(#m_role2_daily_mission_info_toc{err_code=ErrCode});
		_ ->
			ignore
	end.

daily_mission_refresh({Unique, Module, Method, RoleID, OpType, PID}) ->
	case get_daily_mission_info(RoleID) of
		{ok,DailyMissionInfo} ->
			if
				OpType =:= ?REFRESH_MONSTER_LEVEL ->
					daily_mission_refresh_monster(DailyMissionInfo,{Unique, Module, Method, RoleID, OpType, PID});
				OpType =:= ?REFRESH_REWARD_LEVEL ->
					daily_mission_refresh_reward(DailyMissionInfo,{Unique, Module, Method, RoleID, OpType, PID});
				true ->
					?UNICAST_TOC(#m_role2_daily_mission_refresh_toc{err_code=?ERR_INTERFACE_ERR})
			end;
		_ ->
			?UNICAST_TOC(#m_role2_daily_mission_refresh_toc{err_code=?ERR_SYS_ERR})
	end.

daily_mission_refresh_monster(DailyMissionInfo,{Unique, Module, Method, RoleID, OpType, PID}) ->
	TransFun = fun()-> t_daily_mission_refresh_monster(DailyMissionInfo) end,
	case common_transaction:t( TransFun ) of
		{atomic, {ok,RoleAttr,RefreshCost,NewMonsterLevel,MonsterIndex,KillMonsterNum,DailyMissionConf}} ->
			common_misc:send_role_gold_change(RoleID,RoleAttr),
			PMonster = p_daily_mission_monster(RoleID,NewMonsterLevel,MonsterIndex,KillMonsterNum,DailyMissionConf),
			%% 完成成就
			case OpType of
				?REFRESH_MONSTER_LEVEL ->
					mod_achievement2:achievement_update_event(RoleID, 11005, 1);
				?REFRESH_REWARD_LEVEL ->
					mod_achievement2:achievement_update_event(RoleID, 12004, 1)
			end,
			?UNICAST_TOC(#m_role2_daily_mission_refresh_toc{op_type=OpType,monster=PMonster}),
			?ROLE_SYSTEM_BROADCAST(RoleID,lists:concat(["刷新成功，消耗", RefreshCost, "礼券"])),
			ok;
		{aborted, AbortErr} ->
			{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
			?UNICAST_TOC(#m_role2_daily_mission_refresh_toc{op_type=OpType,err_code=ErrCode,reason=Reason})
	end.

t_daily_mission_refresh_monster(DailyMissionInfo) ->
	#r_role_daily_mission{last_time=LastTime,role_id=RoleID,monster_level=MonsterLevel,refresh_monster_level_times=RefreshTimes} = DailyMissionInfo,
	assert_new_day(LastTime),
	DailyMissionConf = get_daily_mission_config(DailyMissionInfo),
	#r_daily_mission{monster_level_list=MonsterLevelList,reduce_monster_level_cost=RefreshCost,
					 give_lowest_monster_level_times=TimesLimit} = DailyMissionConf,
	case common_bag2:t_deduct_money(gold_any, RefreshCost, RoleID, ?CONSUME_TYPE_DAILY_MISSION_REFRESH_MONSTER) of
		{ok,RoleAttr} ->
			next;
		{error, Reason} ->
			RoleAttr = null,
			?THROW_ERR(?ERR_OTHER_ERR, Reason)
	end,
	MinMonsterLevel = element(1, lists:last(MonsterLevelList)),
	NewMonsterLevel = 
		case RefreshTimes >= TimesLimit of
			true ->
				%%给最低难度的怪物星级
				MinMonsterLevel;
			false ->
				{_,_,Rate} = lists:keyfind(MonsterLevel, 1, MonsterLevelList),
				case common_tool:random(1,10000) =< Rate of
					true ->
						erlang:max(MinMonsterLevel, (MonsterLevel - 1));
					false ->
						MonsterLevel
				end
		end,
	{_,MonsterList,_} = lists:keyfind(NewMonsterLevel, 1, MonsterLevelList),
	MonsterIndex = element(1, common_tool:random_element(MonsterList)),
	KillMonsterNum = 0,
	NewDailyMissionInfo = DailyMissionInfo#r_role_daily_mission{kill_monster_num=KillMonsterNum,last_time=mgeem_map:get_now(),
						  monster_index=MonsterIndex,monster_level=NewMonsterLevel,refresh_monster_level_times=RefreshTimes+1},
	t_set_daily_mission_info(RoleID, NewDailyMissionInfo),
	{ok,RoleAttr,RefreshCost,NewMonsterLevel,MonsterIndex,KillMonsterNum,DailyMissionConf}.

daily_mission_refresh_reward(DailyMissionInfo,{Unique, Module, Method, RoleID, OpType, PID}) ->
	TransFun = fun()-> t_daily_mission_refresh_reward(DailyMissionInfo) end,
	case common_transaction:t( TransFun ) of
		{atomic, {ok,RoleAttr,RefreshCost,NewRewardLevel,DailyMissionConf}} ->
			common_misc:send_role_silver_change(RoleID,RoleAttr),
			PRewards = p_daily_mission_reward(NewRewardLevel,DailyMissionConf),
			?UNICAST_TOC(#m_role2_daily_mission_refresh_toc{op_type=OpType,rewards=PRewards}),
			?ROLE_SYSTEM_BROADCAST(RoleID,lists:concat(["刷新成功，消耗", RefreshCost, "礼券"])),
			ok;
		{aborted, AbortErr} ->
			{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
			?UNICAST_TOC(#m_role2_daily_mission_refresh_toc{op_type=OpType,err_code=ErrCode,reason=Reason})
	end.

t_daily_mission_refresh_reward(DailyMissionInfo) ->
	#r_role_daily_mission{role_id=RoleID,last_time=LastTime,reward_level=RewardLevel,refresh_reward_level_times=RefreshTimes} = DailyMissionInfo,
	assert_new_day(LastTime),
	DailyMissionConf = get_daily_mission_config(DailyMissionInfo),
	#r_daily_mission{reward_level_list=RewardLevelList,promote_reward_level_cost=RefreshCost,
					 give_highest_reward_level_times=TimesLimit} = DailyMissionConf,
	case common_bag2:t_deduct_money(gold_any, RefreshCost, RoleID, ?CONSUME_TYPE_DAILY_MISSION_REFRESH_REWARD) of
		{ok,RoleAttr} ->
			next;
		{error, Reason} ->
			RoleAttr = null,
			?THROW_ERR(?ERR_OTHER_ERR, Reason)
	end,
	common_misc:send_role_gold_change(RoleID,RoleAttr),
	MaxRewardLevel = element(1, lists:last(RewardLevelList)),
	NewRewardLevel = 
		case RefreshTimes >= TimesLimit of
			true ->
				%%给最高的奖励星级
				MaxRewardLevel;
			false ->
				{_,_,Rate} = lists:keyfind(RewardLevel, 1, RewardLevelList),
				case common_tool:random(1,10000) =< Rate of
					true ->
						erlang:min(MaxRewardLevel, (RewardLevel + 1));
					false ->
						RewardLevel
				end
		end,
	NewDailyMissionInfo = DailyMissionInfo#r_role_daily_mission{last_time=mgeem_map:get_now(),
						  reward_level=NewRewardLevel,refresh_reward_level_times=RefreshTimes+1},
	t_set_daily_mission_info(RoleID, NewDailyMissionInfo),
	{ok,RoleAttr,RefreshCost,NewRewardLevel,DailyMissionConf}.

daily_mission_finish({Unique, Module, Method, RoleID, OpType, PID}) ->
	case get_daily_mission_info(RoleID) of
		{ok,DailyMissionInfo} ->
			Ret = if
				OpType =:= ?FINISH_MISSION ->
					finish_mission(DailyMissionInfo,{Unique, Module, Method, RoleID, OpType, PID});
				OpType =:= ?FINISH_MISSION_PERFECT_REWARD ->
					finish_mission_perfect_reward(DailyMissionInfo,{Unique, Module, Method, RoleID, OpType, PID});
				OpType =:= ?FINISH_MISSION_LAST_REWARD ->
					finish_mission_last_reward(DailyMissionInfo,{Unique, Module, Method, RoleID, OpType, PID});
				true ->
					?UNICAST_TOC(#m_role2_daily_mission_finish_toc{err_code=?ERR_INTERFACE_ERR}),
					false
			end,
			case Ret of
				{ok, true} ->
					hook_mission_event:hook_special_event(RoleID,?MISSION_EVENT_FINISH_DAILY_MISSION),
					%% 完成成就
					mod_achievement2:achievement_update_event(RoleID, 43002, 1),
					hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_TONG_JI_LING),
					ok;
				_ -> ignore
			end;
		_ ->
			?UNICAST_TOC(#m_role2_daily_mission_finish_toc{err_code=?ERR_SYS_ERR})
	end.

finish_mission(DailyMissionInfo,{Unique, Module, Method, RoleID, OpType, PID}) ->
	TransFun = fun()-> t_finish_mission(DailyMissionInfo) end,
	case common_transaction:t( TransFun ) of
		{atomic, {ok,RoleAttr,RewardGoodsList,RewardPropList,NewDailyMissionInfo2}} ->
			case RoleAttr =/= null of
				true ->
					common_misc:send_role_gold_change(RoleID,RoleAttr);
				false ->
					ignore
			end,
			common_misc:update_goods_notify(PID,RewardGoodsList),
			lists:foreach(
			  fun(#p_reward_prop{prop_id=TypeID,prop_num=Num}) ->
					  ?TRY_CATCH(common_item_logger:log(RoleID,TypeID,Num,undefined,?LOG_ITEM_TYPE_DAILY_MISSION_FINISH_MISSION))
			  end,RewardPropList),
			?UNICAST_TOC(#m_role2_daily_mission_finish_toc{op_type=OpType}),
			cast_daily_mission_info(NewDailyMissionInfo2),
			{ok, true};
		{aborted, AbortErr} ->
			{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
			?UNICAST_TOC(#m_role2_daily_mission_finish_toc{op_type=OpType,err_code=ErrCode,reason=Reason})
	end.

t_finish_mission(DailyMissionInfo) ->
	#r_role_daily_mission{finish_times=FinishTimes,kill_monster_num=KillMonsterNum,role_id=RoleID,last_time=LastTime,
						  reward_level=RewardLevel,monster_level=MonsterLevel,monster_index=MonsterIndex} = DailyMissionInfo,
	assert_new_day(LastTime),
	DailyMissionConf = get_daily_mission_config(DailyMissionInfo),
	PMonster = p_daily_mission_monster(RoleID,MonsterLevel,MonsterIndex,KillMonsterNum,DailyMissionConf),
	#p_daily_mission_monster{monster_total_num=TotalNum} = PMonster,
	#p_daily_mission_reward{rewards=RewardPropList} = p_daily_mission_reward(RewardLevel,DailyMissionConf),
	#r_daily_mission{direct_finish_cost={MoneyType,Cost},daily_mission_loop_times=LoopTimes} = DailyMissionConf,
	case FinishTimes >= LoopTimes of
		true ->
			?THROW_ERR(?ERR_DAILY_MISSION_HAS_FINISH_ALL_MISSION);
		false ->
			next
	end,
	case KillMonsterNum >= TotalNum of
		true ->
			RoleAttr = null;
		false ->
			case common_bag2:t_deduct_money(MoneyType, Cost, RoleID, ?CONSUME_TYPE_GOLD_DAILY_MISSION_DIRECT_FINISH) of
				{ok,RoleAttr} ->
					next;
				{error, Reason} ->
					RoleAttr = null,
					?THROW_ERR(?ERR_OTHER_ERR, Reason)
			end
	end,
	{ok,RewardGoodsList} = common_bag2:t_reward_prop(RoleID, RewardPropList),
	NewDailyMissionInfo = DailyMissionInfo#r_role_daily_mission{finish_times=FinishTimes+1,
																kill_monster_num=0,last_time=mgeem_map:get_now()},
	{ok,NewDailyMissionInfo2} = t_refresh_daily_mission(NewDailyMissionInfo),
	mod_daily_counter:set_mission_remain_times(RoleID, ?ROLE2_DAILY_MISSION_FINISH, LoopTimes-FinishTimes-1, true),
	t_set_daily_mission_info(RoleID,NewDailyMissionInfo2),
	{ok,RoleAttr,RewardGoodsList,RewardPropList,NewDailyMissionInfo2}.

finish_mission_perfect_reward(DailyMissionInfo,{Unique, Module, Method, RoleID, OpType, PID}) ->
	TransFun = fun()-> t_finish_mission_perfect_reward(DailyMissionInfo) end,
	case common_transaction:t( TransFun ) of
		{atomic, {ok,RoleAttr,RewardGoodsList,TotalRewardPropList,NewDailyMissionInfo2}} ->
			common_misc:send_role_gold_change(RoleID,RoleAttr),
			common_misc:update_goods_notify(PID,RewardGoodsList),
			lists:foreach(
			  fun(#p_reward_prop{prop_id=TypeID,prop_num=Num}) ->
					  ?TRY_CATCH(common_item_logger:log(RoleID,TypeID,Num,undefined,?LOG_ITEM_TYPE_DAILY_MISSION_FINISH_MISSION))
			  end,TotalRewardPropList),
			cast_daily_mission_info(NewDailyMissionInfo2),
			?UNICAST_TOC(#m_role2_daily_mission_finish_toc{op_type=OpType}),
			{ok, true};
		{aborted, AbortErr} ->
			{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
			?UNICAST_TOC(#m_role2_daily_mission_finish_toc{op_type=OpType,err_code=ErrCode,reason=Reason})
	end.

t_finish_mission_perfect_reward(DailyMissionInfo) ->
	#r_role_daily_mission{finish_times=FinishTimes,last_time=LastTime,role_id=RoleID} = DailyMissionInfo,
	assert_new_day(LastTime),
	DailyMissionConf = get_daily_mission_config(DailyMissionInfo),
	#r_daily_mission{reward_level_list=RewardLevelList,daily_mission_loop_times=LoopTimes} = DailyMissionConf,
	[{MoneyType,PreCost}] = ?find_config(perfect_finish_mission_cost),
	DiffTimes = LoopTimes - FinishTimes,
	case DiffTimes =< 0 of
		true ->
			?THROW_ERR(?ERR_DAILY_MISSION_HAS_FINISH_ALL_MISSION);
		false ->
			next
	end,
	MaxRewardLevel = element(1, lists:last(RewardLevelList)),
	#p_daily_mission_reward{rewards=RewardPropList} = p_daily_mission_reward(MaxRewardLevel,DailyMissionConf),
	case common_bag2:t_deduct_money(MoneyType, PreCost*DiffTimes, RoleID, ?CONSUME_TYPE_GOLD_DAILY_MISSION_PERFECT_REWARD) of
		{ok,RoleAttr} ->
			next;
		{error, Reason} ->
			RoleAttr = null,
			?THROW_ERR(?ERR_OTHER_ERR, Reason)
	end,
	TotalRewardPropList = [RewardProp#p_reward_prop{prop_num=PropNum*DiffTimes}||#p_reward_prop{prop_num=PropNum}=RewardProp<-RewardPropList],
	{ok,RewardGoodsList} = common_bag2:t_reward_prop(RoleID, TotalRewardPropList),
	NewDailyMissionInfo = DailyMissionInfo#r_role_daily_mission{finish_times=LoopTimes,
																kill_monster_num=0,last_time=mgeem_map:get_now()},
	{ok,NewDailyMissionInfo2} = t_refresh_daily_mission(NewDailyMissionInfo),
	t_set_daily_mission_info(RoleID,NewDailyMissionInfo2),
	mod_daily_counter:set_mission_remain_times(RoleID, ?ROLE2_DAILY_MISSION_FINISH,0, true),
	{ok,RoleAttr,RewardGoodsList,TotalRewardPropList,NewDailyMissionInfo2}.

finish_mission_last_reward(DailyMissionInfo,{Unique, Module, Method, RoleID, OpType, PID}) ->
	TransFun = fun()-> t_finish_mission_last_reward(DailyMissionInfo) end,
	case common_transaction:t( TransFun ) of
		{atomic, {ok,RewardGoodsList,LastRewards}} ->
			common_misc:update_goods_notify(PID,RewardGoodsList),
			lists:foreach(
			  fun(#p_reward_prop{prop_id=TypeID,prop_num=Num}) ->
					  ?TRY_CATCH(common_item_logger:log(RoleID,TypeID,Num,undefined,?LOG_ITEM_TYPE_DAILY_MISSION_FINISH_MISSION))
			  end,LastRewards),
			?UNICAST_TOC(#m_role2_daily_mission_finish_toc{op_type=OpType}),
			{ok, true};
		{aborted, AbortErr} ->
			{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
			?UNICAST_TOC(#m_role2_daily_mission_finish_toc{op_type=OpType,err_code=ErrCode,reason=Reason})
	end.

t_finish_mission_last_reward(DailyMissionInfo) ->
	#r_role_daily_mission{role_id=RoleID,last_time=LastTime,got_last_rewards=GotLastRewards,finish_times=FinishTimes} = DailyMissionInfo,
	assert_new_day(LastTime),
	DailyMissionConf = get_daily_mission_config(DailyMissionInfo),
	#r_daily_mission{last_rewards=LastRewards,daily_mission_loop_times=LoopTimes} = DailyMissionConf,
	case LoopTimes > FinishTimes of
		true ->
			?THROW_ERR(?ERR_DAILY_MISSION_NOT_FINISH_ALL_MISSION);
		false ->
			next
	end,
	case GotLastRewards of
		true ->
			?THROW_ERR(?ERR_DAILY_MISSION_HAS_GOT_LAST_REWARDS);
		false ->
			next
	end,
	{ok,RewardGoodsList} = common_bag2:t_reward_prop(RoleID, LastRewards),
	NewDailyMissionInfo = DailyMissionInfo#r_role_daily_mission{got_last_rewards=true,last_time=mgeem_map:get_now()},
	t_set_daily_mission_info(RoleID,NewDailyMissionInfo),
	{ok,RewardGoodsList,LastRewards}.	

%% 重新刷新日常任务
t_refresh_daily_mission(DailyMissionInfo) ->
	#r_role_daily_mission{role_id=RoleID} = DailyMissionInfo,
	{ok,#p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
	DailyMissionConf = get_daily_mission_config(DailyMissionInfo),
	#r_daily_mission{monster_level_probality=MonsterLevelPro,reward_level_probality=RewardLevelPro,
					 monster_level_list=MonsterLevelList} = DailyMissionConf,
	MonsterLevel= get_level_probality(MonsterLevelPro),
	RewardLevel= get_level_probality(RewardLevelPro),
	{_,MonsterList,_} = lists:keyfind(MonsterLevel, 1, MonsterLevelList),
	MonsterIndex = element(1,common_tool:random_element(MonsterList)),
	NewDailyMissionInfo = DailyMissionInfo#r_role_daily_mission{role_level=Level,monster_index=MonsterIndex,monster_level=MonsterLevel,
																refresh_monster_level_times=0,refresh_reward_level_times=0,
																reward_level=RewardLevel,kill_monster_num=0,last_time=mgeem_map:get_now()},
	{ok,NewDailyMissionInfo}.

%% 在刷新和领奖时判断是否新的一天
assert_new_day(LastTime) ->
	case common_time:is_today(LastTime) of
		true ->
			next;
		false ->
			?THROW_ERR_REASON("数据已经发生了变化，请关闭本界面，再打开操作")
	end.

get_level_probality(LevelPro) ->	
	WtList = [Wt||{_,Wt}<-LevelPro],
	WtIdx = common_tool:random_from_weights(WtList, true),	
	{Level,_} = lists:nth(WtIdx, LevelPro),
	Level.

cast_daily_mission_notify(RoleID,IsOpen,MonsterName,KillMonsterNum,MonsterTotalNum) ->
	R2 = #m_role2_daily_mission_notify_toc{monster_name=MonsterName,is_open=IsOpen,monster_total_num=MonsterTotalNum,kill_monster_num=KillMonsterNum},
	common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?ROLE2,?ROLE2_DAILY_MISSION_NOTIFY,R2).
	
cast_daily_mission_info(RoleID) when is_integer(RoleID) ->
	case get_daily_mission_info(RoleID) of
		{ok,DailyMissionInfo} ->
			cast_daily_mission_info(DailyMissionInfo);
		_ ->
			?THROW_SYS_ERR()
	end;
cast_daily_mission_info(DailyMissionInfoTmp) when is_record(DailyMissionInfoTmp, r_role_daily_mission)->
	#r_role_daily_mission{role_id=RoleID,last_time=LastTime,finish_times=FinishTimes,
						  got_last_rewards=GotLastRewards} = DailyMissionInfoTmp,
	case common_time:is_today(LastTime) of
		true ->
			DailyMissionInfo = DailyMissionInfoTmp,
			NewFinishTimes = FinishTimes;
		false ->
			DailyMissionInfoTmp2 = DailyMissionInfoTmp#r_role_daily_mission{finish_times=0,got_last_rewards=false},
			{ok,DailyMissionInfo} = t_refresh_daily_mission(DailyMissionInfoTmp2),
			set_daily_mission_info(RoleID,DailyMissionInfo),
			NewFinishTimes = 0
	end,
	#r_role_daily_mission{role_id=RoleID,kill_monster_num=KillMonsterNum,
						  monster_index=MonsterIndex,monster_level=MonsterLevel,reward_level=RewardLevel} = DailyMissionInfo,
	DailyMissionConf = get_daily_mission_config(DailyMissionInfo),
	[{_,PerCost}] = ?find_config(perfect_finish_mission_cost),
	#r_daily_mission{direct_finish_cost={_,DirectFinishCost},reduce_monster_level_cost=ReduceMonsterLevelCost,
					 promote_reward_level_cost=PromoteRewardLevelCost,last_rewards=LastRewards,
					 daily_mission_loop_times=LoopTimes} = DailyMissionConf,
	PMonster = p_daily_mission_monster(RoleID,MonsterLevel,MonsterIndex,KillMonsterNum,DailyMissionConf),
	PRewards = p_daily_mission_reward(RewardLevel,DailyMissionConf),
	R2 = #m_role2_daily_mission_info_toc{finish_times=NewFinishTimes,max_times=LoopTimes,
										 perfect_finish_mission_cost=PerCost*(LoopTimes-NewFinishTimes),
										 direct_finish_cost=DirectFinishCost,reduce_monster_level_cost=ReduceMonsterLevelCost,
										 promote_reward_level_cost=PromoteRewardLevelCost,
										 last_rewards=LastRewards,monster=PMonster,rewards=PRewards,
										 got_last_rewards=GotLastRewards
										},
	common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?ROLE2,?ROLE2_DAILY_MISSION_INFO,R2).

p_daily_mission_monster(RoleID,MonsterLevel,MonsterIndex,KillMonsterNum,DailyMissionConf) ->
	#r_daily_mission{monster_level_list=MonsterLevelList} = DailyMissionConf,
	case lists:keyfind(MonsterLevel, 1, MonsterLevelList) of
		false ->
			?ERROR_MSG("p_daily_mission_monster error,MonsterLevel=~w,DailyMissionConf=~w",[MonsterLevel,DailyMissionConf]),
			?THROW_ERR(?ERR_CONFIG_ERR);
		{_,MonsterList,_} ->
			case lists:keyfind(MonsterIndex, 1, MonsterList) of
				false ->
					?ERROR_MSG("p_daily_mission_monster error,MonsterLevel=~w,MonsterIndex=~w,MonsterList=~w",[MonsterLevel,MonsterIndex,MonsterList]),
					MonsterConf = lists:nth(1, MonsterList);
				MonsterConf ->
					next
			end,
			{_,MonsterTypeID,TotalNum,Map,TX,TY} = MonsterConf,
			NewMapID = 
				case is_integer(Map) of
					true -> Map;
					false ->
						{ok,#p_role_base{faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
						erlang:element(2,lists:keyfind(FactionID,1,Map))
				end,
			#p_daily_mission_monster{kill_monster_num=KillMonsterNum,monster_level=MonsterLevel,monster_typeid=MonsterTypeID,
									 monster_map_tx=TX,monster_map_ty=TY,monster_mapid=NewMapID,monster_total_num=TotalNum}
	end.

p_daily_mission_reward(RewardLevel,DailyMissionConf) ->
	#r_daily_mission{reward_level_list=RewardLevelList} = DailyMissionConf,
	case lists:keyfind(RewardLevel, 1, RewardLevelList) of
		false ->
			?ERROR_MSG("p_daily_mission_monster error,RewardLevel=~w,DailyMissionConf=~w",[RewardLevel,DailyMissionConf]),
			?THROW_ERR(?ERR_CONFIG_ERR);
		{_,RewardPropList,_} ->
			#p_daily_mission_reward{reward_level=RewardLevel,rewards=RewardPropList}
	end.

t_set_daily_mission_info(RoleID, DailyMissionInfo) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,RoleExtInfo} ->
			NewDailyMissionInfo = RoleExtInfo#r_role_map_ext{daily_mission=DailyMissionInfo},
			mod_map_role:t_set_role_map_ext_info(RoleID, NewDailyMissionInfo),
			ok;
		Reason ->
			?ERROR_MSG("t_set_daily_mission_info error,RoleID=~w,DailyMissionInfo=~w,Reason=~w",[RoleID,DailyMissionInfo,Reason]),
			?THROW_SYS_ERR()
	end.

set_daily_mission_info(RoleID, DailyMissionInfo) ->
	case common_transaction:t(fun() -> 
									  t_set_daily_mission_info(RoleID, DailyMissionInfo),
									  ok
							  end) of
		{atomic, ok} ->
			ok;
		Reason ->
			?ERROR_MSG("set_daily_mission_info,RoleID=~w,DailyMissionInfo=~w,Reason=~w",[RoleID,DailyMissionInfo,Reason])
	end.

get_daily_mission_info(RoleID) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{daily_mission=DailyMissionInfo}} ->
			{ok, DailyMissionInfo};
		_ ->
			{error, not_found}
	end.

get_daily_mission_config(DailyMissionInfo) ->
	#r_role_daily_mission{role_id=RoleID,last_time=LastTime,kill_monster_num=KillMonsterNum,
						  role_level=RoleLevelTmp} = DailyMissionInfo,
	{ok,#p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
	[DailyMissionConfList] = ?find_config(daily_mission),
	case common_time:is_today(LastTime) of
		true ->
			RoleLevel = 
				case KillMonsterNum > 0 of
					true -> RoleLevelTmp;
					false -> Level
				end;
		false ->
			RoleLevel = Level
	end,
	get_daily_mission_config(DailyMissionConfList,RoleLevel).

get_daily_mission_config([], _RoleLevel) ->
	% ?ERROR_MSG("not find config data, RoleLevel: ~w", [RoleLevel]),
	?THROW_ERR(?ERR_DAILY_MISSION_NOT_OPEN);
get_daily_mission_config([H|T],RoleLevel) ->
	#r_daily_mission{level_section={MinLevel,MaxLevel}} = H,
	case RoleLevel >= MinLevel andalso RoleLevel =< MaxLevel of
		true ->
			H;
		false ->
			get_daily_mission_config(T,RoleLevel)
	end.

%%解析错误码
parse_aborted_err(AbortErr)->
    case AbortErr of
        {error,ErrCode,_Reason} when is_integer(ErrCode) ->
            AbortErr;
        {bag_error,{not_enough_pos,_BagID}}->
            {error,?ERR_OTHER_ERR,<<"您的背包空间不足，赶紧去整理背包吧">>};
        {bag_error,num_not_enough}->
            {error,?ERR_OTHER_ERR,<<"您的背包空间不足，赶紧去整理背包吧">>};
        {error,AbortReason} when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        AbortReason when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        _ ->
            ?ERROR_MSG(" aborted,AbortErr=~w,stack=~w",[AbortErr,erlang:get_stacktrace()]),
            {error,?ERR_SYS_ERR,undefined}
    end.