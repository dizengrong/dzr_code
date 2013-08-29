%%%-------------------------------------------------------------------
%%% @author  chenrong
%%% @doc
%%% 天焚炼气塔
%%% @end
%%% Created : 3 Mar 2012 by  <chenrong>
%%%-------------------------------------------------------------------

-module(mod_lianqi).

-include("mgeem.hrl").

-export([handle/1]).

-export([role_online/1,
         renew_role_lianqi_info/2,
		 refresh_daily_counter_times/2]).

-define(NORMAL_FETCH, 1). %% 普通领取
-define(FORCE_FETCH, 2).  %% 强领

-define(ERR_LIANQI_NOT_ENOUGH_FETCH_NUM, 100). %% 今天领取经验的次数已经用完，请明天再继续
-define(ERR_LIANQI_NOT_ENOUGH_FORCE_FETCH_NUM, 101). %% 今天强领经验的次数已经用完，请明天再继续
-define(ERR_LIANQI_STILL_IN_COOL_TIME, 102). %% 冷却时间未结束，不能领取经验
-define(ERR_LIANQI_NOT_ENOUGH_GOLD, 103). %% 元宝不足，无法强领经验
-define(ERR_LIANQI_NOT_FOUND_EXP, 104). %% 玩家境界不足，没找到对应的经验（指玩家没境界，无法领取经验）
-define(ERR_LIANQI_EXP_FULL, 105). %%  当前经验已储满，升级后才能获得经验
-define(ERR_LIANQI_VIPLEVEL_NOT_ENOUGH, 106). %%  VIP等级不够，无法强领经验
-define(ERR_LIANQI_VOUTCHES_NOT_ENOUGH, 107). %%  礼券不足

handle({_, ?LIANQI, ?LIANQI_INFO, _, _, _, _} = Info) ->
    do_lianqi_info(Info);

handle({_, ?LIANQI, ?LIANQI_FETCH, _, _, _, _} = Info) ->
    do_lianqi_fetch(Info);

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

%% 查询天焚炼气塔的信息
do_lianqi_info({Unique, Module, Method, _DataIn, RoleID, _PID, Line}) ->
    case catch check_lianqi_info(RoleID) of
        {ok, LianqiInfo, Exp, {MulitNum,Gold}} ->
            #r_role_lianqi{next_fetch_time=NextFetchTime, acc_fetch_num=AccFetchNum,acc_force_fetch_num=AccForceNum} = LianqiInfo,
            DataRecord = #m_lianqi_info_toc{next_exp=Exp, next_fetch_time=NextFetchTime,can_fetch_num=AccFetchNum,
                                            next_force_fetch_gold=Gold, can_force_fetch_num=AccForceNum,every_force_fetch_num=MulitNum},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord),
            mod_role_cd:send_cd_info_to_client(RoleID, 11);
        {error, ErrCode, Reason} ->
            ErrRecord = #m_lianqi_info_toc{err_code=ErrCode, reason=Reason},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord)
    end.

check_lianqi_info(RoleID) ->
    case renew_role_lianqi_info(RoleID, false) of
        ok ->
            next;
        _ ->
            ?THROW_SYS_ERR()
    end,
    
    case get_lianqi_info(RoleID) of
        {ok, LianqiInfo} ->
            case mod_map_role:get_role_attr(RoleID) of
                {ok, RoleAttr} ->
                    case common_config_dyn:find(lianqi, {exp, RoleAttr#p_role_attr.level}) of
                        [Exp] ->
                            {MulitNum,Gold} = get_deduct_gold(LianqiInfo#r_role_lianqi.today_force_fetch_num + 1),
                            {ok, LianqiInfo, Exp, {MulitNum,Gold}};
                        _ ->
                            ?THROW_ERR(?ERR_LIANQI_NOT_FOUND_EXP)
                    end;
                _ ->
                    ?THROW_SYS_ERR()
            end;
        _ ->
            ?THROW_SYS_ERR()
    end.

%% 普通领取经验
do_lianqi_fetch({Unique, Module, Method, DataIn, RoleID, _PID, Line}) ->
    #m_lianqi_fetch_tos{op_type=OpType} = DataIn,
    case OpType of
        ?NORMAL_FETCH ->
            do_lianqi_nomal_fetch({Unique, Module, Method, DataIn, RoleID, _PID, Line});
        ?FORCE_FETCH ->
            do_lianqi_force_fetch({Unique, Module, Method, DataIn, RoleID, _PID, Line});
        _ ->
            ErrRecord = #m_lianqi_fetch_toc{err_code=?ERR_SYS_ERR},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord)
    end.

do_lianqi_nomal_fetch({Unique, Module, Method, DataIn, RoleID, _PID, Line}) ->
    case catch check_do_lianqi_normal_fetch(RoleID) of
         {ok, LianqiInfo} ->
            do_lianqi_normal_fetch_2({Unique, Module, Method, DataIn, RoleID, _PID, Line}, LianqiInfo);
        {error, ErrCode, Reason} ->
            ErrRecord = #m_lianqi_fetch_toc{err_code=ErrCode, reason=Reason, op_type=DataIn#m_lianqi_fetch_tos.op_type},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord)
    end.

check_do_lianqi_normal_fetch(RoleID) ->
    case renew_role_lianqi_info(RoleID, false) of
        ok ->
            next;
        _ ->
            ?THROW_SYS_ERR()
    end,
    
    LianqiInfo = 
        case get_lianqi_info(RoleID) of
            {ok, LianqiInfoT} ->
                case mod_role_cd:is_in_cd(RoleID, 11) of
                    true  -> ?THROW_ERR(?ERR_LIANQI_STILL_IN_COOL_TIME);
                    false -> LianqiInfoT
                end;
                % NowSeconds = common_tool:now(),
                % if LianqiInfoT#r_role_lianqi.acc_fetch_num =< 0 ->
                %        ?THROW_ERR(?ERR_LIANQI_NOT_ENOUGH_FETCH_NUM);
                %    LianqiInfoT#r_role_lianqi.next_fetch_time > NowSeconds ->
                %        ?THROW_ERR(?ERR_LIANQI_STILL_IN_COOL_TIME);
                %    true ->
                %        LianqiInfoT
                % end;
            _ ->
                ?THROW_SYS_ERR()
        end,
    {ok, LianqiInfo}.

do_lianqi_normal_fetch_2({Unique, Module, Method, DataIn, RoleID, _PID, Line}, LianqiInfo) ->
    case common_transaction:transaction(
           fun() -> 
                   case mod_map_role:get_role_map_ext_info(RoleID) of
                       {ok,RoleExtInfo} ->
                           {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
                           [Exp] = common_config_dyn:find(lianqi, {exp, RoleAttr#p_role_attr.level}),
                           #r_role_lianqi{today_fetch_num=TodayFetchNum, acc_fetch_num=AccFetchNum} = LianqiInfo,
                           CoolTime = get_cool_time(TodayFetchNum + 1),
                           Now = common_tool:now(),
                           NextFetchTime = 
                               case (AccFetchNum - 1) =< 0 of
                                   true ->
                                       Now;
                                   _ ->
                                       Now + CoolTime
                               end,
                            mod_role_cd:add_cd_time(RoleID, 11, CoolTime),
                           NewLianqiInfo = LianqiInfo#r_role_lianqi{today_fetch_num=TodayFetchNum+1, acc_fetch_num=AccFetchNum-1,
                                                                    last_fetch_time=Now,
                                                                    next_fetch_time=NextFetchTime},
                           mod_map_role:t_set_role_map_ext_info(RoleID, RoleExtInfo#r_role_map_ext{lianqi=NewLianqiInfo}),
                           ExpAddResult = mod_map_role:t_add_exp(RoleID, Exp),
                           {ok, NewLianqiInfo, Exp, ExpAddResult};
                       _ ->
                           {error, not_found}
                   end
           end
    ) of
        {aborted, ?_LANG_ROLE2_ADD_EXP_EXP_FULL} ->
            DataRecord = #m_role2_exp_full_toc{text=?_LANG_ROLE2_ADD_EXP_EXP_FULL},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_EXP_FULL, DataRecord),
            ErrRecord = #m_lianqi_fetch_toc{err_code=?ERR_LIANQI_EXP_FULL,op_type=DataIn#m_lianqi_fetch_tos.op_type},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord);
        {aborted, Error} ->
            ?ERROR_MSG("~ts:~w", ["获取普通天焚炼气塔经验系统错误", Error]),
            ErrRecord = #m_lianqi_fetch_toc{err_code=?ERR_SYS_ERR,op_type=DataIn#m_lianqi_fetch_tos.op_type},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord);
        {atomic, {ok, NewLianqiInfo, Exp1, ExpAddResult}} ->
            Exp2 = common_tool:ceil(Exp1),
            do_after_exp_add(RoleID, Exp2 ,ExpAddResult),
            
            %% 特殊任务事件
            hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_LIANQI),
            hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_LIANQI),
            
            {MulitNum,GoldNeed} = get_deduct_gold(NewLianqiInfo#r_role_lianqi.today_force_fetch_num + 1),
            DataRecord = #m_lianqi_fetch_toc{op_type=DataIn#m_lianqi_fetch_tos.op_type,
                                             next_exp=Exp2,
                                             next_fetch_time=0,%NewLianqiInfo#r_role_lianqi.next_fetch_time,
                                             can_fetch_num=NewLianqiInfo#r_role_lianqi.acc_fetch_num,
                                             next_force_fetch_gold=GoldNeed,
                                             can_force_fetch_num=NewLianqiInfo#r_role_lianqi.acc_force_fetch_num,
                                             use_gold=0,every_force_fetch_num=MulitNum},
 			mod_daily_counter:set_mission_remain_times(RoleID, 1012, NewLianqiInfo#r_role_lianqi.acc_fetch_num,true),
            common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord),
            mod_role_cd:send_cd_info_to_client(RoleID, 11)
    end.

%% 强领经验
do_lianqi_force_fetch({Unique, Module, Method, DataIn, RoleID, _PID, Line}) ->
    case catch check_do_lianqi_force_fetch(RoleID) of
         {ok, LianqiInfo, DeductType} ->
            do_lianqi_force_fetch_2({Unique, Module, Method, DataIn, RoleID, _PID, Line}, LianqiInfo, DeductType);
        {error, ErrCode, Reason} ->
            ErrRecord = #m_lianqi_fetch_toc{err_code=ErrCode, reason=Reason, op_type=DataIn#m_lianqi_fetch_tos.op_type},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord)
    end.

check_do_lianqi_force_fetch(RoleID) ->
    case renew_role_lianqi_info(RoleID, false) of
        ok ->
            next;
        _ ->
            ?THROW_SYS_ERR()
    end,
	case get_vip_force_fetch_times(RoleID) of
		{ok,VipForceFetchTimes} when VipForceFetchTimes>0 ->							   
			ignore;
		_ ->
			?THROW_ERR(?ERR_LIANQI_VIPLEVEL_NOT_ENOUGH)
	end,   
	LianqiInfo = 
		case get_lianqi_info(RoleID) of
			{ok, LianqiInfoT} ->
				if LianqiInfoT#r_role_lianqi.acc_force_fetch_num =< 0 ->					   
					   ?THROW_ERR(?ERR_LIANQI_NOT_ENOUGH_FORCE_FETCH_NUM);
				   true ->
					   LianqiInfoT
				end;
			_ ->
				?THROW_SYS_ERR()
		end,
    
    [ConsumeItemTypeID] = common_config_dyn:find(lianqi, exp_force_fetch_consume_item),
    {ok, GoodsNums} = mod_bag:get_goods_num_by_typeid([1,2,3], RoleID, ConsumeItemTypeID),
    case GoodsNums > 0 of
        true ->
            DeductType = item;        
        false ->
            case mod_map_role:get_role_attr(RoleID) of
                {ok, RoleAttr} ->
                    {_MulitNum,GoldNeed} = get_deduct_gold(LianqiInfo#r_role_lianqi.today_force_fetch_num + 1),
                    if RoleAttr#p_role_attr.gold >= GoldNeed ->
                           next;
                       true ->
                           ?THROW_ERR(?ERR_LIANQI_NOT_ENOUGH_GOLD)
                    end;
                _ ->
                    ?THROW_SYS_ERR()
            end,
            DeductType = gold
    end,
    {ok, LianqiInfo, DeductType}.


get_vip_force_fetch_times(RoleID) ->
	RoleVipLevel = mod_vip:get_role_vip_level(RoleID),
	[ForceTimes] = common_config_dyn:find(lianqi, {exp_force_fetch_num, RoleVipLevel}),
	{ok,ForceTimes}.


do_lianqi_force_fetch_2({Unique, Module, Method, DataIn, RoleID, PID, Line}, LianqiInfo, DeductType) ->
    case common_transaction:transaction(
           fun() -> 
                   case mod_map_role:get_role_map_ext_info(RoleID) of
                       {ok,RoleExtInfo} ->
                           {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
                           case DeductType of
                               item ->
                                   [ConsumeItemTypeID] = common_config_dyn:find(lianqi, exp_force_fetch_consume_item),
                                   {ok, UpList, DelList} = mod_bag:decrease_goods_by_typeid(RoleID, ConsumeItemTypeID, 1),
                                  {MulitNum,_} = get_deduct_gold(LianqiInfo#r_role_lianqi.today_force_fetch_num + 1),
								   DeductData = {item, UpList, DelList, ConsumeItemTypeID, 1};
                               gold ->
                                   %% 扣除元宝
								   {MulitNum,GoldNeed} = get_deduct_gold(LianqiInfo#r_role_lianqi.today_force_fetch_num + 1),
								   case common_bag2:t_deduct_money(gold_unbind, GoldNeed, RoleID, ?CONSUME_TYPE_GOLD_LIANQI_FORCE_FETCH_EXP) of
									   {ok, NewRoleAttr} ->
										   DeductData = {gold, GoldNeed, NewRoleAttr};
									   {error,_} ->
										   DeductData = null,
										   ?THROW_ERR(?ERR_LIANQI_VOUTCHES_NOT_ENOUGH)
								   end
                           end,
                           [Exp] = common_config_dyn:find(lianqi, {exp, RoleAttr#p_role_attr.level}),
                           NewExp = Exp * MulitNum,
                           #r_role_lianqi{today_force_fetch_num=TodayForceFetchNum, acc_force_fetch_num=AccForceFetchNum} = LianqiInfo,
                           NewLianqiInfo = LianqiInfo#r_role_lianqi{today_force_fetch_num=TodayForceFetchNum+1, 
                                                                    acc_force_fetch_num=AccForceFetchNum-1,
                                                                    last_force_fetch_time=common_tool:now()},
                           mod_map_role:t_set_role_map_ext_info(RoleID, RoleExtInfo#r_role_map_ext{lianqi=NewLianqiInfo}),
                           ExpAddResult = mod_map_role:t_add_exp(RoleID, NewExp),
                           {ok, NewLianqiInfo, DeductData, Exp, NewExp, ExpAddResult};
                       _ ->
                           {error, not_found}
                   end
           end
    ) of
        {aborted, ?_LANG_ROLE2_ADD_EXP_EXP_FULL} ->
            DataRecord = #m_role2_exp_full_toc{text=?_LANG_ROLE2_ADD_EXP_EXP_FULL},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_EXP_FULL, DataRecord),
            ErrRecord = #m_lianqi_fetch_toc{err_code=?ERR_LIANQI_EXP_FULL,op_type=DataIn#m_lianqi_fetch_tos.op_type},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord);
        {aborted,{error, ErrorCode,_Reason}} ->
            ErrRecord = #m_lianqi_fetch_toc{err_code=ErrorCode,op_type=DataIn#m_lianqi_fetch_tos.op_type},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord);
        {aborted, Error} ->
            ?ERROR_MSG("~ts: role_id : ~w , error : ~w", ["获取强领天焚炼气塔经验系统错误 ", RoleID, Error]),
            ErrRecord = #m_lianqi_fetch_toc{err_code=?ERR_SYS_ERR,op_type=DataIn#m_lianqi_fetch_tos.op_type},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, ErrRecord);
        {atomic, {ok, NewLianqiInfo, DeductData, NextExp, ExpAdd1, ExpAddResult}} ->
            ExpAdd2 = common_tool:ceil(ExpAdd1),
            do_after_exp_add(RoleID, ExpAdd2, ExpAddResult),
            %% 特殊任务事件
            hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_LIANQI),
            mod_random_mission:handle_event(RoleID, ?RAMDOM_MISSION_EVENT_10),
            %% 完成成就
            mod_achievement2:achievement_update_event(RoleID, 31005, 1),
            mod_achievement2:achievement_update_event(RoleID, 32005, 1),
            mod_achievement2:achievement_update_event(RoleID, 43003, 1),
            mod_achievement2:achievement_update_event(RoleID, 44006, 1),
            %% 完成活动
            hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_LIANQI),
            case DeductData of
                {gold, DeductGold, NewRoleAttr} ->
                    %% 元宝消耗通知
                    notify_gold_change(RoleID, NewRoleAttr),
                    ConsumeGoodNum = 0;
                {item, UpList, DelList, ConsumeItemTypeID, 1} ->
                    ConsumeGoodNum = 1,
                    DeductGold = 0,
                    common_misc:update_goods_notify(PID, UpList),
                    common_misc:del_goods_notify(PID, DelList),
                    common_item_logger:log(RoleID,ConsumeItemTypeID,1,undefined,?LOG_ITEM_TYPE_LIANQI_CONSUME)
            end,
            {MulitNum,NextGoldNeed} = get_deduct_gold(NewLianqiInfo#r_role_lianqi.today_force_fetch_num + 1),
            DataRecord = #m_lianqi_fetch_toc{op_type=DataIn#m_lianqi_fetch_tos.op_type,
                                             next_exp=NextExp,
                                             next_fetch_time=NewLianqiInfo#r_role_lianqi.next_fetch_time,
                                             can_fetch_num=NewLianqiInfo#r_role_lianqi.acc_fetch_num,
                                             next_force_fetch_gold=NextGoldNeed,
                                             can_force_fetch_num=NewLianqiInfo#r_role_lianqi.acc_force_fetch_num,
                                             use_gold=DeductGold, consume_item_num=ConsumeGoodNum,every_force_fetch_num=MulitNum},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord)
    end.

notify_gold_change(RoleID,NewRoleAttr) ->
    ChangeList = [#p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value=NewRoleAttr#p_role_attr.gold},
                  #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.gold_bind}],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList).

%%给玩家增加经验后的处理
do_after_exp_add(RoleID,ExpAdd,ExpAddResult) when is_integer(ExpAdd)->
    case ExpAddResult of
        {exp_change, Exp} ->
            
            ExpChange = #p_role_attr_change{change_type=?ROLE_EXP_CHANGE, new_value=Exp},
            DataRecord = #m_role2_attr_change_toc{roleid=RoleID, changes=[ExpChange]},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, DataRecord),
            hook_activity_schedule:hook_exp_change(RoleID, ExpAdd);
        
        {level_up, Level, RoleAttr, RoleBase} ->
            mod_map_role:do_after_level_up(Level, RoleAttr, RoleBase, ExpAdd, ?DEFAULT_UNIQUE, true),
            hook_activity_schedule:hook_exp_change(RoleID, ExpAdd);
        _ ->
            ignore
    end.

%% 玩家上线时 更新玩家的累积可领取，强领经验的次数
role_online(RoleID) ->
    renew_role_lianqi_info(RoleID, false).

refresh_daily_counter_times(RoleID,RemainTimes) when erlang:is_integer(RemainTimes) ->
	case get_lianqi_info(RoleID) of
		{ok,LianqiInfo} ->
			NewLianqiInfo = 
				case RemainTimes > 0 of
					true -> 
						update_role_lianqi_info(RoleID, LianqiInfo#r_role_lianqi{acc_fetch_num=RemainTimes}),
						IsNotyfy = true,
						LianqiInfo#r_role_lianqi{acc_fetch_num=RemainTimes};
					_ -> 
						IsNotyfy = false,
						LianqiInfo
				end,
			mod_daily_counter:set_mission_remain_times(RoleID, 1012, NewLianqiInfo#r_role_lianqi.acc_fetch_num,IsNotyfy);
		_ ->
			ignore
	end.

renew_role_lianqi_info(RoleID, IsVipLevelUpgrade) ->
	case get_lianqi_info(RoleID) of 
		{ok, LianqiInfo} ->
			[NormalFetchNum] = common_config_dyn:find(lianqi, exp_normal_fetch_num),
			VipLevel = mod_vip:get_role_vip_level(RoleID),
			[ForceFetchNum] = common_config_dyn:find(lianqi, {exp_force_fetch_num, VipLevel}),
			%% 跨周时清除玩家的累积次数，以周一为开始
			{LastResetDate, _} = common_tool:seconds_to_datetime(LianqiInfo#r_role_lianqi.last_reset_time),
			{Status, NewLianqiInfo} = 
				case common_time:is_in_same_week(date(), LastResetDate) of
					false -> 
						case LastResetDate of
							{1970, 1, 1} ->     %%玩家第一次闭关
								DateDif = 1;
							_ ->
								DateDif = calendar:day_of_the_week(date())
						end,
						{true, LianqiInfo#r_role_lianqi{acc_fetch_num=NormalFetchNum * DateDif, acc_force_fetch_num=ForceFetchNum * DateDif,
														today_fetch_num=0, today_force_fetch_num=0,
														last_reset_time=common_tool:now()}};
					true ->  
						%% 跨天时，累积之间未使用的次数
						LastResetDiffDays = common_time:diff_date(date(), LastResetDate),
						LianqiInfo1 = LianqiInfo#r_role_lianqi{acc_fetch_num=LianqiInfo#r_role_lianqi.acc_fetch_num + NormalFetchNum * LastResetDiffDays,
															   acc_force_fetch_num=LianqiInfo#r_role_lianqi.acc_force_fetch_num + ForceFetchNum * LastResetDiffDays},
						case {LastResetDiffDays > 0, IsVipLevelUpgrade} of
							{true, _} ->
								{true, LianqiInfo1#r_role_lianqi{today_fetch_num=0, today_force_fetch_num=0, last_reset_time=common_tool:now()}};
							{false, true} ->
								%% 同一天内，vip等级提升时
								{true, LianqiInfo1#r_role_lianqi{acc_force_fetch_num=LianqiInfo#r_role_lianqi.acc_force_fetch_num + ForceFetchNum, last_reset_time=common_tool:now()}};
							{false, false} ->
								{false, LianqiInfo1}
						end
				end,
			if Status =:= true ->
				   mod_daily_counter:set_mission_remain_times(RoleID, 1012, NewLianqiInfo#r_role_lianqi.acc_fetch_num,true),
				   update_role_lianqi_info(RoleID, NewLianqiInfo);
			   true ->
				   ignore
			end,
			ok;
		_ ->
			?ERROR_MSG("~ts:~w", ["获取玩家的焚天炼气信息出错", not_found]),
			ignore
	end.

update_role_lianqi_info(RoleID, NewLianqiInfo) ->
    case common_transaction:transaction(
           fun() -> 
                   case mod_map_role:get_role_map_ext_info(RoleID) of
                       {ok,RoleExtInfo} ->
                           NewRoleExtInfo = RoleExtInfo#r_role_map_ext{lianqi=NewLianqiInfo},
                           mod_map_role:t_set_role_map_ext_info(RoleID, NewRoleExtInfo),
                           ok;
                       _ ->
                           {error ,not_found} 
                   end
           end
    ) of
        {atomic, ok} ->
            ok;
        {aborted, Error} -> 
            ?ERROR_MSG("~ts:~w", ["更新天焚炼气塔系统错误", Error]),
            {error, fail}
    end.                     

get_lianqi_info(RoleID) ->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,RoleExtInfo} ->
            #r_role_map_ext{lianqi=LianqiRecord} = RoleExtInfo,
            {ok, LianqiRecord};
        _ ->
            {error, not_found_lianqi}
    end.

get_deduct_gold(ForceFetchNum) ->
    [ForceHighNum] = common_config_dyn:find(lianqi, exp_force_fetch_threshold),
    Num = 
        case ForceFetchNum > ForceHighNum of
            true ->
                ForceHighNum;
            _ ->
                ForceFetchNum
        end,
    [{AddNum,Gold}] = common_config_dyn:find(lianqi, {exp_force_gold, Num}),
	{AddNum,Gold}.

get_cool_time(FetchNum) ->
    [CoolHighNum] = common_config_dyn:find(lianqi, exp_fetch_threshold),
    Num = 
        case FetchNum > CoolHighNum of
            true ->
                CoolHighNum;
            _ ->
                FetchNum
        end,
    [CoolTime] = common_config_dyn:find(lianqi, {exp_cool_time, Num}),
    CoolTime.