%%% @author fsk 
%%% @doc
%%%     玩家每日累计充值奖励
%%% @end
%%% Created : 2012-6-14
%%%-------------------------------------------------------------------
-module(mod_daily_pay).
-compile(export_all).

-include("mgeem.hrl").

-export([
		 handle/1
		]).

%% 系统错误默认=1
-define(ERR_DAILY_REWARD_HAS_REWARD,562101).%%已经领取奖励或不能领奖
-define(ERR_DAILY_REWARD_MAX_BAG_NUM,562102). %%背包空间不足

-define(TYPE_480,1).
-define(TYPE_1280,2).
-define(TYPE_2580,3).
-define(TYPE_5180,4).

-define(PAY_480,480).
-define(PAY_1280,1280).
-define(PAY_2580,2580).
-define(PAY_5180,5180).

-define(STATUS_NOT_REWARD,0).
-define(STATUS_CAN_REWARD,1).
-define(STATUS_HAS_REWARD,2).


%%
%% API Functions
%%
handle({_,?ACTIVITY,?ACTIVITY_DAILY_PAY_REWARD,_,_,_}=Info)->
	do_daily_pay_reward(Info);
handle({_,?ACTIVITY,?ACTIVITY_DAILY_PAY_NOTIFY,_,RoleID,_})->
	daily_pay_notify(RoleID,_IsOnlinePay=false);
handle({daily_pay_notify, RoleID, IsOnlinePay}) ->
    daily_pay_notify(RoleID,IsOnlinePay);
handle(Msg) ->
	?ERROR_MSG("uexcept msg = ~w",[Msg]).

hook_role_level_change(RoleID,Level) ->
	hook_role_online(RoleID,Level).
hook_role_online(RoleID,Level) ->
	[MinLevel] = common_config_dyn:find(daily_pay_reward,min_level),
	case Level >= MinLevel of
		true ->
			daily_pay_notify(RoleID,false);
		false ->
			ignore
	end.

daily_pay_notify(RoleID,IsOnlinePay) ->
	{RewardTypeStatusList,_AllRewarded} = get_reward_type_status_list(RoleID,IsOnlinePay),
	{ok,RewardListConf} = today_pay_reward_conf(),
	PNotify =
		lists:map(fun({Type,{TotalPrice,RewardItemList}}) ->
						  case lists:keyfind(Type, 1, RewardTypeStatusList) of
							  false ->
								  Status = ?STATUS_NOT_REWARD;
							  {_,Status} ->
								  next
						  end,
						  #p_daily_pay_notify{type=Type,status=Status,total_price=TotalPrice,reward_list=RewardItemList}
				  end, RewardListConf),
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_DAILY_PAY_NOTIFY,#m_activity_daily_pay_notify_toc{notify=PNotify}).


%%
%% Local Functions
%%
do_daily_pay_reward({Unique, Module, Method, DataIn, RoleID, PID}) ->
	#m_activity_daily_pay_reward_tos{type=Type} = DataIn,
	case catch check_reward(RoleID,Type) of
		{error,ErrCode,_ErrReason} ->
			?UNICAST_TOC(#m_activity_daily_pay_reward_toc{type=Type,succ=false,reason_code=ErrCode});
		{ok,NewRoleDailyPayRewardInfo} ->
			TransFun = fun()-> 
							   t_reward(RoleID,Type,NewRoleDailyPayRewardInfo)
					   end,
			case db:transaction( TransFun ) of
				{atomic, {ok,RewardGoodsList,RewardItemList}} ->
					common_misc:update_goods_notify(PID,RewardGoodsList),
					lists:foreach(
					  fun(#p_reward_prop{prop_id=TypeID,prop_num=Num}) ->
							  ?TRY_CATCH(common_item_logger:log(RoleID,TypeID,Num,undefined,?LOG_ITEM_TYPE_GET_DAILY_PAY_REWARD))
					  end,RewardItemList),
					?UNICAST_TOC(#m_activity_daily_pay_reward_toc{type=Type});
				{aborted, {throw,{bag_error,{not_enough_pos,_}}}} ->
					?UNICAST_TOC(#m_activity_daily_pay_reward_toc{type=Type,succ=false,reason_code=?ERR_DAILY_REWARD_MAX_BAG_NUM});
				{aborted, {throw,{error,ErrCode,undefined}}} ->
					?UNICAST_TOC(#m_activity_daily_pay_reward_toc{type=Type,succ=false,reason_code=ErrCode});
				{aborted, Reason} ->
					?ERROR_MSG("reward error,Reason:~w",[Reason]),
					?UNICAST_TOC(#m_activity_daily_pay_reward_toc{type=Type,succ=false,reason_code=?ERR_SYS_ERR})
			end
	end.

check_reward(RoleID,Type) ->
	{ok, #r_role_daily_pay_reward{reward_list=RewardList}=RoleDailyPayRewardInfo}
		= get_role_daily_pay_reward_info(RoleID),
	Now = common_tool:now(),
	{RewardTypeStatusList,_AllRewarded} = get_reward_type_status_list(RoleID,false),
	NewRewardList =
		case lists:keyfind(Type, 1, RewardTypeStatusList) of
			false ->
				?THROW_ERR(?ERR_DAILY_REWARD_HAS_REWARD);
			{_,Status} when Status =/= ?STATUS_CAN_REWARD ->
				?THROW_ERR(?ERR_DAILY_REWARD_HAS_REWARD);
			_ ->
				case lists:keyfind(Type, 1, RewardList) of
					false ->
						[{Type,Now}|RewardList];
					_ ->
						lists:keyreplace(Type,1,RewardList,{Type,Now})
				end
			end,
	{ok,RoleDailyPayRewardInfo#r_role_daily_pay_reward{reward_list=NewRewardList}}.

t_reward(RoleID,Type,RoleDailyPayRewardInfo) ->
	RewardItemList = reward_list_conf(Type),
	{ok,RewardGoodsList} = common_bag2:t_reward_prop(RoleID, RewardItemList),
	t_set_role_daily_pay_reward_info(RoleID, RoleDailyPayRewardInfo),
	{ok,RewardGoodsList,RewardItemList}.
	
reward_list_conf(Type) ->
	{ok,RewardListConf} = today_pay_reward_conf(),
	case lists:keyfind(Type, 1, RewardListConf) of
		false ->
			?THROW_SYS_ERR();
		{Type,{_TotalPrice,RewardItemList}} ->
			RewardItemList
	end.

%% return {RewardTypeStatusList,AllRewarded}
get_reward_type_status_list(RoleID,IsOnlinePay) ->
	{ok, #r_role_daily_pay_reward{reward_list=RewardList}} = get_role_daily_pay_reward_info(RoleID),
	TodaySumPay = role_today_sum_pay(RoleID,IsOnlinePay,erlang:date()),
	{ok,RewardListConf} = today_pay_reward_conf(),
	{RewardTypeStatusList,RewardCount} = 
		lists:foldl(fun({PayType,_},{Acc,AccRewardCount}) ->
							SumPayConf = type_mapping_gold(PayType),
							case TodaySumPay >= SumPayConf of
								true ->
									case today_has_reward(PayType,RewardList) of
										false -> {[{PayType,?STATUS_CAN_REWARD}|Acc],AccRewardCount};
										_ -> {[{PayType,?STATUS_HAS_REWARD}|Acc],AccRewardCount+1}
									end;
								false -> {[{PayType,?STATUS_NOT_REWARD}|Acc],AccRewardCount}
							end
					end, {[],0}, RewardListConf),
	{RewardTypeStatusList,_AllRewarded=(RewardCount=:=erlang:length(RewardListConf))}. 

type_mapping_gold(Type) when Type =:= ?TYPE_480 ->
	?PAY_480;
type_mapping_gold(Type) when Type =:= ?TYPE_1280 ->
	?PAY_1280;
type_mapping_gold(Type) when Type =:= ?TYPE_2580 ->
	?PAY_2580;
type_mapping_gold(Type) when Type =:= ?TYPE_5180 ->
	?PAY_5180.

%% 今天是否已经领取奖励
today_has_reward(Type,RewardList) ->
	case lists:keyfind(Type, 1, RewardList) of
		false ->
			false;
		{Type,LastRewardTime} ->
			common_time:is_today(LastRewardTime)
	end.

role_today_sum_pay(RoleID,_IsOnlinePay,Today) ->
	case db:dirty_read(?DB_ROLE_ACCGOLD, RoleID) of
		[]->
			0;
		[#r_role_accgold{consume_list=ConsumeListOld}]->
			case lists:keyfind(Today, 1, ConsumeListOld) of
				false->
					0;
				{_,UsedGold} ->
					UsedGold
			end
	end.

today_pay_reward_conf() ->
	OpenDay = common_config:get_opened_days(),
	[DailyPayReward] = common_config_dyn:find(daily_pay_reward,daily_pay_reward),
	case lists:keyfind(OpenDay, 1, DailyPayReward) of
		false ->
			Key = OpenDay rem erlang:length(DailyPayReward),
			case lists:keyfind(Key, 1, DailyPayReward) of
				false ->
					{_,RewardConf} = lists:nth(1, DailyPayReward);
				{_,RewardConf} ->
					next
			end;
		{_,RewardConf} ->
			next
	end,
	{ok,RewardConf}.

set_role_daily_pay_reward_info(RoleID, RoleDailyPayRewardInfo) ->
	case common_transaction:t(
		   fun()-> 
				   t_set_role_daily_pay_reward_info(RoleID, RoleDailyPayRewardInfo)
		   end
							 ) of
		{atomic, ok} ->
			ok;
		{aborted, Error} -> 
			?ERROR_MSG("~ts:~w", ["设置玩家每日累计充值奖励领取数据时系统错误", Error]),
			{error, fail}
	end.

t_set_role_daily_pay_reward_info(RoleID, RoleDailyPayRewardInfo) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,RoleExtInfo} ->
			NewRoleExtInfo = RoleExtInfo#r_role_map_ext{daily_pay_reward=RoleDailyPayRewardInfo},
			mod_map_role:t_set_role_map_ext_info(RoleID, NewRoleExtInfo),
			ok;
		_ ->
			?THROW_SYS_ERR()
	end.

get_role_daily_pay_reward_info(RoleID) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{daily_pay_reward=RoleDailyPayRewardInfo}} ->
			{ok, RoleDailyPayRewardInfo};
		_ ->
			?ERROR_MSG("get_role_daily_pay_reward_info error,RoleID=~w",[RoleID]),
			?THROW_SYS_ERR()
	end.


