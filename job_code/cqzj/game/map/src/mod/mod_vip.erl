%%% @author fsk 
%%% @doc
%%%     VIP模块
%%% @end
%%% Created : 2012-8-22
%%%-------------------------------------------------------------------
-module(mod_vip).

-export([
         handle/1,
         handle/2,
         is_role_vip/1,
         get_role_vip_level/1,
         get_vip_level_info/1,
		 get_dirty_role_vip_level/1,
		 set_role_vip_info/2,
         get_role_vip_info/1,
		 assert_use_vip_card/1,
		 add_jifen/2,
		 pay_add_jifen/2,
		 add_vip_buff/2,
		 do_buy_buff_succ/2
		]).

-export([
         get_vip_pet_understand_rate/1,
         get_vip_shop_discount/1,
         is_map_transfer_free/1
		]).

-export([
		 hook_use_gold/1,
         hook_role_online/1
        ]).

-include("mgeem.hrl").

%% 系统错误默认=1
-define(CONFIG_NAME,vip).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

-define(ERR_VIP_REMOTE_DEPOT_LEVEL_NOT_ENOUGH, 74001). %%VIP等级不够，不能开通远程仓库
-define(ERR_VIP_REMOTE_DEPOT_MAX_DEPOT, 74002). %%你已经开通了所有仓库，不能继续开通
-define(ERR_VIP_REMOTE_DEPOT_NOT_ENOUGH_GOLD, 74003). %%你当前元宝不足，不能开通远程仓库
-define(ERR_SUPER_VIP_HAS_REWARD,74004).%%已经领取VIP特权奖励
-define(ERR_SUPER_VIP_MAX_BAG_NUM,74005). %%背包空间不足
-define(ERR_SUPER_VIP_CAN_BUY_BUFF,74006). %%Vip等级不足，无法购买buff
-define(ERR_SUPER_VIP_NO_BUFF_FREE_TIME,74007). %%今天已经领取完免费Buff次数了
-define(ERR_SUPER_VIP_NOT_ENOUGH_GOLD,74008). %%元宝不足，无法购买Buff
-define(ERR_SUPER_VIP_MAX_BUFF_HOUR,74009). %%该Buff时间已满，今天无需再买Buff了

-define(ERR_SUPER_VIP_NOT_VIP,740809). %%不是VIP
-define(ERR_SUPER_VIP_LOTO_TIMES_FULL,740810). %%vip转盘次数已满
-define(ERR_SUPER_VIP_LOTO_NOT_ENOUGH_VIP_SILVER,740811).	%%vip币不够
-define(ERR_SUPER_VIP_LOTO_ALREADY_LOCKED,740812).	%%已开始转盘，不能再刷新
-define(ERR_SUPER_VIP_LOTO_NOT_ENOUGH,740813).	%%元宝不足

-define(vip_multiple_exp_type, 1050).

%% 最小的VIP特权等级
-define(DEFAULT_SUPER_VIP_LEVEL,4).
-define(FULL_SUPER_VIP_LEVEL,10).
-define(VIP3,3).

-define(TYPE_DAILY,1).
-define(TYPE_WEEKLY,2).

-define(NOTIFY_TYPE_TRANSFER_FREE, 1).
-define(NOTIFY_TYPE_TRANSFER_NORMAL, 2).

-define(OP_BUFF_INFO, 1).
-define(OP_BUY_BUFF, 2).

-define(BUY_TYPE_ONE, 1).
-define(BUY_TYPE_TWO, 2).
-define(BUY_TYPE_THREE, 3).
-define(BUY_TYPE_FOUR, 4).

-define(VIP_SILVER, 11000109).
-define(JUNIOR_TIMES,5).
-define(SENIOR_TIMES,5).
-define(ADVANCE_TIMES,2).
-define(MIN_VIP_SILVER_CONSUME,1).		%%第一次转盘消耗的vip币
-define(TOLER_VIP_SILVER_CONSUME,1).	
-define(BROADCAST_VIP_LEVEL,[1,3,6]).
handle(Msg,_State) ->
	handle(Msg).

handle({_,?VIP, ?VIP_SUPER_INFO, _,_,_,_,_}=Info) ->
	vip_info(Info);
handle({_,?VIP, ?VIP_STOP_NOTIFY, _,_,_,_,_}=Info) ->
    vip_stop_notify(Info);
handle({_,?VIP, ?VIP_REWARD, _,_,_,_,_}=Info) ->
    reward(Info);
handle({_,?VIP, ?VIP_REMOTE_DEPOT,_,_,_,_,_}=Info) ->
    remote_depot(Info);
handle({_,?VIP, ?VIP_BUY_BUFF,_,_,_,_,_}=Info) ->
    vip_buy_buff(Info);
handle({Unique, Module, ?VIP_LOTO_INFO, DataIn, RoleID, PID, _Line, _MapState}) ->
	do_vip_loto_info({Unique, Module, ?VIP_LOTO_INFO, DataIn, RoleID, PID, _Line});
handle({Unique, Module, ?VIP_LOTO_TURN, DataIn, RoleID, PID,_Line, _MapState}) ->
	do_vip_loto_turn({Unique, Module, ?VIP_LOTO_TURN, DataIn, RoleID, PID, _Line});
handle({Unique, Module, ?VIP_LOTO_REFRESH, DataIn, RoleID, PID, _Line, _MapState}) ->
	do_vip_loto_refresh({Unique, Module, ?VIP_LOTO_REFRESH, DataIn, RoleID, PID});


handle({add_jifen,RoleID,AddJifen})->
	?TRY_CATCH(add_jifen(RoleID,AddJifen));
%% 清理积分卡使用次数
handle({clear_vip_card_times,RoleID})->
	clear_vip_card_times(RoleID);
handle(Info) ->
    ?ERROR_MSG("mod_vip, unknow info: ~w", [Info]).

%% 是否免费传送
is_map_transfer_free(RoleID) ->
	case get_role_vip_info(RoleID) of
		{ok, VipInfo} ->
			#r_role_vip{event_log=EventLog, vip_level=VipLevel} = VipInfo,
			[FreeVipLevel] = ?find_config(free_mission_transfer_vip_level),
			case VipLevel >= FreeVipLevel of
				true ->
					true;
				false ->
					{MissionTransferTimes,LastTime} = get_event_log(mission_transfer, EventLog),
					NewMissionTransferTimes = 	
						case common_time:is_today(LastTime) of
							true ->
								MissionTransferTimes + 1;
							false ->
								1
						end,
					case get_vip_level_info(VipLevel) of
						#r_vip_level_info{mission_transfer_times=MaxMissionTransferTimes} ->
							case MaxMissionTransferTimes >= NewMissionTransferTimes of
								true ->
									NewEventLog = set_event_log(mission_transfer, EventLog, NewMissionTransferTimes),
									NewVipInfo = VipInfo#r_role_vip{event_log=NewEventLog},
									set_role_vip_info(RoleID,NewVipInfo,true),
									true;
								false ->
									false
							end;
						_ ->
							false
					end
			end;
		_ ->
			false
	end.

%% 角色上线，把VIP数据推过去 TODO考虑不推
hook_role_online(RoleID) ->
	cast_vip_info(RoleID).

vip_info({_Unique, _Module, _Method, _DataIn, RoleID, _PID, _Line, _State}) ->
	cast_vip_info(RoleID).

vip_stop_notify({Unique, Module, Method, DataIn, RoleID, PID, _Line, _State}) ->
	#m_vip_stop_notify_tos{notify_type=NotifyType} = DataIn,
	case common_transaction:t(
		   fun() ->
				   {ok,VipInfo} = get_role_vip_info(RoleID),
				   NewVipInfo = 
					   case NotifyType of
						   ?NOTIFY_TYPE_TRANSFER_FREE ->
							   VipInfo#r_role_vip{is_transfer_notice_free=false};
						   _ ->
							   VipInfo#r_role_vip{is_transfer_notice=false}
					   end,
				   t_set_role_vip_info(RoleID, NewVipInfo)
		   end)
		of
		{atomic, _} ->
			?UNICAST_TOC(#m_vip_stop_notify_toc{notify_type=NotifyType});
		{aborted, Error} ->
			?ERROR_MSG("do_vip_stop_notify, error: ~w", [Error]),
			?UNICAST_TOC(#m_vip_stop_notify_toc{err_code=?ERR_SYS_ERR})
	end.

%% @doc 查询转盘信息
do_vip_loto_info({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
	#m_vip_loto_info_tos{op_type=OpType} = DataIn,
	{ok,TotalVipSilverNum} = mod_bag:get_goods_num_by_typeid([1], RoleID, ?VIP_SILVER),
	[TotalLotoTimes] = common_config_dyn:find(vip,loto_times),
	[ConsumeGold] = common_config_dyn:find(vip, consume_gold),
	case check_vip_loto_info(RoleID) of
		{error,not_vip} ->
			[NotVipLotoRewardList] = common_config_dyn:find(vip, not_vip_loto_reward),
			RewardListToC = transform_reward_list(NotVipLotoRewardList, []),
			R2 = #m_vip_loto_info_toc{op_type=OpType,total_vip_silver=TotalVipSilverNum,consume_vip_silver=?MIN_VIP_SILVER_CONSUME,
									  remain_times=TotalLotoTimes,rewards=RewardListToC,consume_gold=ConsumeGold},
			?UNICAST_TOC(R2);
		_ ->
			{ok,LotoInfo} = get_role_loto_info(RoleID),
			#r_role_loto{remain_times=RemainTimes,junior_reward_list=JuniorRewardList,
						 senior_reward_list=SeniorRewardList,advance_reward_list=AdvanceRewardList} = LotoInfo,
			ConsumeVipSilver = ?MIN_VIP_SILVER_CONSUME + (TotalLotoTimes - RemainTimes) * ?TOLER_VIP_SILVER_CONSUME,
			RewardList = lists:flatten([JuniorRewardList,SeniorRewardList,AdvanceRewardList]),
			RewardListToC = transform_reward_list(RewardList, []),
			R2 = #m_vip_loto_info_toc{op_type=OpType,total_vip_silver=TotalVipSilverNum,consume_vip_silver=ConsumeVipSilver,
									  remain_times=RemainTimes,rewards=RewardListToC,consume_gold=ConsumeGold},			
			?UNICAST_TOC(R2)
	end.	

check_vip_loto_info(RoleID) ->
	{ok,LotoInfo} = get_role_loto_info(RoleID),
	#r_role_loto{last_time=LastTime} = LotoInfo,
	case LastTime =:= erlang:date() of
		true ->
			next;
		_ ->
			init_role_loto_info(RoleID)
	end.
	
%% @doc 开始转盘
do_vip_loto_turn({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
	#m_vip_loto_turn_tos{op_type=OpType} = DataIn,
	case catch check_vip_loto_turn(RoleID) of
		{error, ErrCode, Reason} ->
			R2 = #m_vip_loto_turn_toc{op_type=OpType,err_code=ErrCode,reason=Reason},
			?UNICAST_TOC(R2);
		_ ->
			case OpType of
				1 ->
					do_vip_loto_turn2({Unique, Module, Method, DataIn, RoleID, PID, _Line});
				_ ->
					do_vip_loto_turn3({Unique, Module, Method, DataIn, RoleID, PID, _Line})
			end
	end.

do_vip_loto_turn2({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
	#m_vip_loto_turn_tos{op_type=OpType} = DataIn,
	{ok,Reward,CurLotoTimes,RemainTimes,JuniorRewardList,SeniorRewardList,AdvanceRewardList} = get_loto_reward(RoleID),
	#r_loto_reward{reward_id=RewardID,reward_type=RewardType,reward_num=RewardNum,is_gain=_IsGain,is_bind=IsBind} = Reward,
	ConsumeVipSilverNum = ?MIN_VIP_SILVER_CONSUME + (CurLotoTimes - 1) * ?TOLER_VIP_SILVER_CONSUME,
	NextConsumeVipSilverNum = ?MIN_VIP_SILVER_CONSUME + CurLotoTimes * ?TOLER_VIP_SILVER_CONSUME,
	{ok,TotalVipSilverNum} = mod_bag:get_goods_num_by_typeid([1], RoleID, ?VIP_SILVER),
	ConsumeGold = (ConsumeVipSilverNum - TotalVipSilverNum) * 2,
	TransFun =
		fun() ->
				{ok,UpdateList,DeleteList} = mod_bag:decrease_goods_by_typeid(RoleID, ?VIP_SILVER, ConsumeVipSilverNum),
				GoodsCreateInfo = #r_goods_create_info{bind=IsBind,type_id=RewardID,type=RewardType,num=RewardNum},
				{ok,NewGoodsList} = mod_bag:create_goods(RoleID, 1, GoodsCreateInfo),
				{ok,DeleteList,UpdateList,NewGoodsList}
		end,
	case catch common_transaction:t(TransFun) of
		{atomic,{ok,DeleteList,UpdateList,[GoodsInfo | _T]}} ->
			set_role_loto_info(RoleID,{true,erlang:date(),RemainTimes-1,JuniorRewardList,SeniorRewardList,AdvanceRewardList}),
			common_item_logger:log(RoleID, ?VIP_SILVER, ConsumeVipSilverNum, undefined, ?LOG_ITEM_TYPE_VIP_LOTO_VIP_SILVER_LOST),
			common_item_logger:log(RoleID, RewardID,RewardNum,IsBind,?LOG_ITEM_TYPE_GET_VIP_LOTO_REWARD),
			common_misc:update_goods_notify({role,RoleID}, UpdateList++ DeleteList),		
			{ok,VipSilverNum} = mod_bag:get_goods_num_by_typeid([1], RoleID, ?VIP_SILVER),
			
			RewardToC = #p_vip_loto{reward_id=RewardID,reward_num=RewardNum,is_gain=true},
			R2 = #m_vip_loto_turn_toc{op_type=OpType,total_vip_silver=VipSilverNum,consume_vip_silver=NextConsumeVipSilverNum,
									  remain_times=RemainTimes-1,reward=RewardToC,goods_info=GoodsInfo,consume_gold=ConsumeGold},
			?UNICAST_TOC(R2);
		{aborted, {bag_error,num_not_enough}} ->
			R2 = #m_vip_loto_turn_toc{op_type=OpType,err_code=?ERR_SUPER_VIP_LOTO_NOT_ENOUGH_VIP_SILVER,consume_gold=ConsumeGold},
			?UNICAST_TOC(R2);
		{aborted, {error,ErrCode,Reason}} ->
			R2 = #m_vip_loto_turn_toc{op_type=OpType,err_code=ErrCode,reason=Reason,consume_gold=ConsumeGold},
			?UNICAST_TOC(R2);
		{aborted, Reason} ->
			?ERROR_MSG("vip loto error: ~w", [Reason]),
			R2 = #m_vip_loto_turn_toc{op_type=OpType,err_code=?ERR_SYS_ERR,consume_gold=ConsumeGold},
			?UNICAST_TOC(R2)
	end.

do_vip_loto_turn3({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->
	#m_vip_loto_turn_tos{op_type=OpType} = DataIn,
	{ok,Reward,CurLotoTimes,RemainTimes,JuniorRewardList,SeniorRewardList,AdvanceRewardList} = get_loto_reward(RoleID),
	#r_loto_reward{reward_id=RewardID,reward_type=RewardType,reward_num=RewardNum,is_gain=_IsGain,is_bind=IsBind} = Reward,
	ConsumeVipSilverNum = ?MIN_VIP_SILVER_CONSUME + (CurLotoTimes-1) * ?TOLER_VIP_SILVER_CONSUME,
	NextConsumeVipSilverNum = ?MIN_VIP_SILVER_CONSUME + CurLotoTimes * ?TOLER_VIP_SILVER_CONSUME,
	{ok,TotalVipSilverNum} = mod_bag:get_goods_num_by_typeid([1], RoleID, ?VIP_SILVER),
	TransFun =
		fun() ->	
				if
					TotalVipSilverNum =< 0 ->
						ConsumeGold = ConsumeVipSilverNum * 2,
						{UpdateList,DeleteList} = {[],[]};
					true ->
						ConsumeGold = (ConsumeVipSilverNum-TotalVipSilverNum) * 2,
						{ok,UpdateList,DeleteList} = mod_bag:decrease_goods_by_typeid(RoleID, ?VIP_SILVER, TotalVipSilverNum)
				end,

				common_bag2:check_money_enough_and_throw(gold_unbind,ConsumeGold,RoleID),

				GoodsCreateInfo = #r_goods_create_info{bind=IsBind,type_id=RewardID,type=RewardType,num=RewardNum},
				{ok,NewGoodsList} = mod_bag:create_goods(RoleID, 1, GoodsCreateInfo),

				case common_bag2:t_deduct_money(gold_unbind,ConsumeGold,RoleID,?CONSUME_TYPE_GOLD_VIP_LOTO_TURN) of
					{ok,RoleAttr2} ->
						RoleAttr2;
					{error, Reason} ->
						RoleAttr2 = null,
						?THROW_ERR(?ERR_OTHER_ERR, Reason);
					_ ->
						RoleAttr2 = null,
						?THROW_ERR(?ERR_SUPER_VIP_LOTO_NOT_ENOUGH)
				end,
				
				{ok,ConsumeGold,RoleAttr2,UpdateList,DeleteList,NewGoodsList}
		end,
	case catch common_transaction:t(TransFun) of
		{atomic,{ok,ConsumeGold,RoleAttr2,UpdateList,DeleteList,[GoodsInfo | _T]}} ->
			common_misc:send_role_gold_change(RoleID, RoleAttr2),
			set_role_loto_info(RoleID,{true,erlang:date(),RemainTimes-1,JuniorRewardList,SeniorRewardList,AdvanceRewardList}),
			if
				UpdateList =:= [] andalso DeleteList =:= [] ->
					ignore;
				true ->
					common_item_logger:log(RoleID, ?VIP_SILVER, TotalVipSilverNum, undefined, ?LOG_ITEM_TYPE_VIP_LOTO_VIP_SILVER_LOST),
					common_item_logger:log(RoleID, RewardID,RewardNum,IsBind,?LOG_ITEM_TYPE_GET_VIP_LOTO_REWARD),
					common_misc:update_goods_notify({role,RoleID}, UpdateList++DeleteList)
			end,
			RewardToC = #p_vip_loto{reward_id=RewardID,reward_num=RewardNum,is_gain=true},
			{ok,VipSilverNum} = mod_bag:get_goods_num_by_typeid([1], RoleID, ?VIP_SILVER),
			R2 = #m_vip_loto_turn_toc{op_type=OpType,total_vip_silver=VipSilverNum,consume_vip_silver=NextConsumeVipSilverNum,
									  remain_times=RemainTimes-1,reward=RewardToC,goods_info=GoodsInfo,consume_gold=ConsumeGold},
			?UNICAST_TOC(R2);
		{aborted, {error,ErrCode,Reason}} ->
			R2 = #m_vip_loto_turn_toc{op_type=OpType,err_code=ErrCode,reason=Reason},
			?UNICAST_TOC(R2);
		{aborted, Reason} ->
			?ERROR_MSG("vip loto error: ~w", [Reason]),
			R2 = #m_vip_loto_turn_toc{op_type=OpType,err_code=?ERR_SYS_ERR},
			?UNICAST_TOC(R2)
	end.
check_vip_loto_turn(RoleID) ->
	RoleVip = get_role_vip_level(RoleID),
	if
		RoleVip =< 0 ->
			?THROW_ERR(?ERR_SUPER_VIP_NOT_VIP);
		true ->
			next
	end,
	{ok,#r_role_loto{last_time=LastTime,remain_times=RemainTimes}} = get_role_loto_info(RoleID),
	case erlang:date() =:= LastTime of
		true ->
			NewRemainTimes = RemainTimes;
		_ ->
			NewRemainTimes = common_config_dyn:find(vip, loto_times)
	end,
	if
		NewRemainTimes =< 0 ->
			?THROW_ERR(?ERR_SUPER_VIP_LOTO_TIMES_FULL);
		true ->
			next
	end.

%% vip转盘奖励刷新
do_vip_loto_refresh({Unique, Module, Method, DataIn, RoleID, PID}) ->
	#m_vip_loto_refresh_tos{op_type=OpType} = DataIn,
	case check_vip_loto_refresh(RoleID) of
		{error,not_vip} ->
			R2 = #m_vip_loto_refresh_toc{op_type=OpType,err_code=?ERR_SUPER_VIP_NOT_VIP},
			?UNICAST_TOC(R2);
		{error,already_locked} ->
			R2 = #m_vip_loto_refresh_toc{op_type=OpType,err_code=?ERR_SUPER_VIP_LOTO_ALREADY_LOCKED},
			?UNICAST_TOC(R2);
		_ ->
			do_vip_loto_refresh2({Unique, Module, Method, DataIn, RoleID, PID})
	end.

do_vip_loto_refresh2({Unique, Module, Method, DataIn, RoleID, PID}) ->
	#m_vip_loto_refresh_tos{op_type=OpType} = DataIn,
	case OpType of
		%%成为vip的时候刷新奖励列表，这里不消耗元宝
		0 ->
			ConsumeGold = 0;
		_ ->
			[ConsumeGold] = common_config_dyn:find(vip, consume_gold)
	end,
	TransFun = 
		fun() ->
				case ConsumeGold of
					0 ->
						{ok,ConsumeGold,null};
					_ ->
						common_bag2:check_money_enough_and_throw(gold_any,ConsumeGold,RoleID),
						case common_bag2:t_deduct_money(gold_any, ConsumeGold, RoleID, ?CONSUME_TYPE_GOLD_VIP_LOTO_REFRESH) of
							{ok,RoleAttr2} ->
								{ok,ConsumeGold,RoleAttr2};
							{error, Reason} ->
								?THROW_ERR(?ERR_OTHER_ERR, Reason);
							_ ->
								?THROW_ERR(?ERR_SUPER_VIP_LOTO_NOT_ENOUGH)
						end
				end				
		end,
	case common_transaction:t(TransFun) of
		{atomic,{ok,ConsumeGold,RoleAttr2}} ->
			case RoleAttr2 of
				null ->
					ignore;
				_ ->
					common_misc:send_role_gold_change(RoleID, RoleAttr2)
			end,
			{ok,LotoInfo} = init_role_loto_info(RoleID),
			#r_role_loto{remain_times=RemainTimes,
						 junior_reward_list=JuniorRewardList,
						 senior_reward_list=SeniorRewardList,
						 advance_reward_list=AdvanceRewardList}=LotoInfo,
			
			{ok,TotalVipSilver} = mod_bag:get_goods_num_by_typeid([1], RoleID, ?VIP_SILVER),
			[TotalLotoTimes] = common_config_dyn:find(vip, loto_times),
			ConsumeVipSilver = ?MIN_VIP_SILVER_CONSUME + (TotalLotoTimes - RemainTimes) * ?TOLER_VIP_SILVER_CONSUME,
			RewardList = lists:flatten([JuniorRewardList,SeniorRewardList,AdvanceRewardList]),
			RewardListToC = transform_reward_list(RewardList,[]),
			R2 = #m_vip_loto_refresh_toc{op_type=OpType,total_vip_silver=TotalVipSilver,consume_vip_silver=ConsumeVipSilver,
										 remain_times=RemainTimes,rewards=RewardListToC,consume_gold=ConsumeGold},
			?UNICAST_TOC(R2);
		{aborted, {error,ErrCode,Reason}} ->
			R2 = #m_vip_loto_refresh_toc{op_type=OpType,err_code=ErrCode,reason=Reason},
			?UNICAST_TOC(R2);
		{aborted, Reason} ->
			?ERROR_MSG("vip loto refresh, error: ~w", [Reason]),
			R2 = #m_vip_loto_refresh_toc{op_type=OpType,err_code=?ERR_SYS_ERR},
			?UNICAST_TOC(R2)
	end.
check_vip_loto_refresh(RoleID) ->
	RoleVipLevel = get_role_vip_level(RoleID),
	if
		RoleVipLevel =< 0 ->
			{error, not_vip};
		true ->
			{ok,LotoInfo} = get_role_loto_info(RoleID),
			#r_role_loto{is_lock=IsLock} = LotoInfo,
			case IsLock of
				true ->
					{error, already_locked};
				_ ->
					ok
			end
	end.

%% @doc 获取玩家vip转盘信息
get_role_loto_info(RoleID) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{role_loto=RoleLotoInfo}} ->
			{ok,RoleLotoInfo};
		_ ->
			init_role_loto_info(RoleID)
	end.

%% @doc 设置玩家vip转盘信息
set_role_loto_info(RoleID,{IsLock,LastTime,RemainTimes,JuniorRewardList,SeniorRewardList,AdvanceRewardList}) ->
	TransFun = 
		fun() ->
				t_set_role_loto_info(RoleID,{IsLock,LastTime,RemainTimes,JuniorRewardList,SeniorRewardList,AdvanceRewardList})
		end,
	case common_transaction:t( TransFun ) of
        {atomic, ok} ->
            ok;
        {aborted, Error} -> 
            ?ERROR_MSG("set_role_loto_info error,Error=~w", [Error]),
            {error, fail}
    end.

t_set_role_loto_info(RoleID,{IsLock,LastTime,RemainTimes,JuniorRewardList,SeniorRewardList,AdvanceRewardList}) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{role_loto=OldLotoInfo}=OldRoleExtInfo} ->
			NewLotoInfo = OldLotoInfo#r_role_loto{is_lock=IsLock,last_time=LastTime,remain_times=RemainTimes,
												  junior_reward_list=JuniorRewardList,
												  senior_reward_list=SeniorRewardList,
												  advance_reward_list=AdvanceRewardList},
			NewRoleExtInfo = OldRoleExtInfo#r_role_map_ext{role_loto=NewLotoInfo},
			mod_map_role:t_set_role_map_ext_info(RoleID, NewRoleExtInfo),
			ok;
		_ ->
            ?THROW_SYS_ERR()
	end.

%% 获取此次转盘所得的奖励
get_loto_reward(RoleID) ->
	{ok,#r_role_loto{remain_times=RemainTimes1,junior_reward_list=JuniorRewardList1,
				 senior_reward_list=SeniorRewardList1,advance_reward_list=AdvanceRewardList1}} = get_role_loto_info(RoleID),
	case {JuniorRewardList1,SeniorRewardList1,AdvanceRewardList1} of
		{undefined,undefined,undefined} ->
			{ok,#r_role_loto{remain_times=RemainTimes,junior_reward_list=JuniorRewardList,
				 senior_reward_list=SeniorRewardList,advance_reward_list=AdvanceRewardList}} = init_role_loto_info(RoleID);
		_ ->
			RemainTimes=RemainTimes1,
			JuniorRewardList=JuniorRewardList1,
			SeniorRewardList=SeniorRewardList1,
			AdvanceRewardList=AdvanceRewardList1
	end,
	[TotalLotoTimes] = common_config_dyn:find(vip, loto_times),
	CurLotoTimes =  TotalLotoTimes - RemainTimes + 1,
	if
		CurLotoTimes>=1 andalso CurLotoTimes=<5 ->
			JuniorRewardList2 = [JuniorReward || JuniorReward <- JuniorRewardList, JuniorReward#r_loto_reward.is_gain=:=false],
			Reward = common_tool:random_from_tuple_weights(JuniorRewardList2, #r_loto_reward.weight),
			NewReward = Reward#r_loto_reward{is_gain=true},
			NewJuniorRewardList = get_new_reward_list(Reward,NewReward,JuniorRewardList),
			{ok,Reward,CurLotoTimes,RemainTimes,NewJuniorRewardList,SeniorRewardList,AdvanceRewardList};
		CurLotoTimes>=6 andalso CurLotoTimes=<10 ->
			SeniorRewardList2 = [SeniorReward || SeniorReward <- SeniorRewardList, SeniorReward#r_loto_reward.is_gain=:=false],
			Reward = common_tool:random_from_tuple_weights(SeniorRewardList2, #r_loto_reward.weight),
			NewReward = Reward#r_loto_reward{is_gain=true},
			NewSeniorRewardList = get_new_reward_list(Reward,NewReward,SeniorRewardList),
			{ok,Reward,CurLotoTimes,RemainTimes,JuniorRewardList,NewSeniorRewardList,AdvanceRewardList};
		CurLotoTimes>=11 andalso CurLotoTimes=<12 ->
			AdvanceRewardList2 = [AdvanceReward || AdvanceReward <- AdvanceRewardList, AdvanceReward#r_loto_reward.is_gain=:=false],
			Reward = common_tool:random_from_tuple_weights(AdvanceRewardList2, #r_loto_reward.weight),
			NewReward = Reward#r_loto_reward{is_gain=true},
			NewAdvanceRewardList = get_new_reward_list(Reward,NewReward,AdvanceRewardList),
			{ok,Reward,CurLotoTimes,RemainTimes,JuniorRewardList,SeniorRewardList,NewAdvanceRewardList};
		true ->
			?THROW_ERR(?SYSTEM_ERROR)
	end.

%% 将奖励列表中所获奖励的 is_gain 字段置为 true
get_new_reward_list(OldReward,NewReward,OldRewardList) ->
	[case Reward of
		 OldReward ->
			 NewReward;
		 _ ->
			 Reward
	 end || Reward <- OldRewardList].

%% @doc初始化玩家vip转盘信息
init_role_loto_info(RoleID) ->
	{JuniorRewardList,SeniorRewardList,AdvanceRewardList} = get_role_loto_reward_list(RoleID),
	[TotalTimes] = common_config_dyn:find(vip, loto_times),
	LotoInfo = #r_role_loto{role_id=RoleID,is_lock=false,last_time=erlang:date(),remain_times=TotalTimes,
							junior_reward_list=JuniorRewardList,senior_reward_list=SeniorRewardList,advance_reward_list=AdvanceRewardList},
	set_role_loto_info(RoleID,{false,erlang:date(),TotalTimes,JuniorRewardList,SeniorRewardList,AdvanceRewardList}),
	{ok,LotoInfo}.

%% 将奖励列表转换为p_vip_loto格式
transform_reward_list([], NewRewardList) ->
	NewRewardList;
transform_reward_list([H | RewardListT], NewRewardList) ->
	#r_loto_reward{reward_id=RewardID,reward_num=RewardNum,is_gain=IsGain} = H,
	Reward = #p_vip_loto{reward_id=RewardID,reward_num=RewardNum,is_gain=IsGain},
	transform_reward_list(RewardListT, [Reward | NewRewardList]).

%% 获取此次vip转盘的奖励列表
get_role_loto_reward_list(RoleID) ->
	{MinLevel,MaxLevel} = get_role_loto_reward_section(RoleID),
	[{JuniorRewardList,SeniorRewardList,AdvanceRewardList}] = common_config_dyn:find(vip, {vip_loto,MinLevel,MaxLevel}),
	
	JuniorRewardList2 = get_role_loto_reward_list2(?JUNIOR_TIMES,JuniorRewardList),
	SeniorRewardList2 = get_role_loto_reward_list2(?SENIOR_TIMES,SeniorRewardList),
	AdvanceRewardList2 = get_role_loto_reward_list2(?ADVANCE_TIMES,AdvanceRewardList),
	{JuniorRewardList2,SeniorRewardList2,AdvanceRewardList2}.
get_role_loto_reward_list2(RewardNum,RewardList) ->
	{_,_,NewRewardList} = 
		lists:foldl(
		  fun(_,{RewardNum2,FromList,ToList}) ->
				  if
					  RewardNum2 > 0 ->
						  Reward = common_tool:random_from_tuple_weights(FromList, #r_loto_reward.weight),
						  ToList2 = [Reward | ToList],
						  FromList2 = lists:delete(Reward, FromList),
						  {RewardNum2-1,FromList2,ToList2};
					  true ->
						  ToList2 = ToList,
						  FromList2 = FromList,
						  {RewardNum2,FromList2,ToList2}
				  end
		  end, {RewardNum,RewardList,[]}, RewardList),
	NewRewardList.

%% 获取玩家的等级所在的奖励区间
get_role_loto_reward_section(RoleID) ->
	{ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	[RewardSectionList] = common_config_dyn:find(vip, loto_reward_section),
	[JingJieSection] = [{MinLevel,MaxLevel} || {MinLevel,MaxLevel} <- RewardSectionList,RoleLevel>=MinLevel,RoleLevel=<MaxLevel],
	JingJieSection.

remote_depot({Unique, Module, Method, _DataIn, RoleID, PID, Line, MapState}) ->
	case catch check_remote_depot(RoleID) of
		{error,ErrCode,_ErrReason} ->
			?UNICAST_TOC(#m_vip_remote_depot_toc{err_code=ErrCode});
		{ok,VipInfo,RemoteDepotFee} ->
			case common_transaction:t(
				   fun() ->
				   		   common_bag2:check_money_enough_and_throw(gold_unbind,RemoteDepotFee,RoleID),
						   #r_role_vip{remote_depot_num=RemoteDepotNum} = VipInfo,
						   NewRemoteDepotNum = RemoteDepotNum+1,
						   NewVipInfo = VipInfo#r_role_vip{remote_depot_num=NewRemoteDepotNum},
						   t_set_role_vip_info(RoleID, NewVipInfo),
						   case common_bag2:t_deduct_money(gold_unbind,RemoteDepotFee,RoleID,?CONSUME_TYPE_GOLD_VIP_REMOTE_DEPOT) of
							   {ok,RoleAttr}->
								   next;
							   {error, Reason} ->
							   		RoleAttr = null,
							   		?THROW_ERR(?ERR_OTHER_ERR, Reason);
							   _ ->
								   RoleAttr = null,
								   ?THROW_ERR(?ERR_VIP_REMOTE_DEPOT_NOT_ENOUGH_GOLD)
						   end,
						   {ok,NewVipInfo,RoleAttr,NewRemoteDepotNum}
				   end)
				of 
				{atomic, {ok,NewVipInfo,RoleAttr,NewRemoteDepotNum}} ->
					%% VIP信息变动
					cast_vip_info(NewVipInfo),
					?UNICAST_TOC(#m_vip_remote_depot_toc{}),
					common_misc:send_role_gold_change(RoleID,RoleAttr),
					case mod_bag:judge_bag_exist(RoleID, NewRemoteDepotNum+5) of
						true ->
							ignore;
						_ ->
							mod_depot:handle({?DEFAULT_UNIQUE,?DEPOT,?DEPOT_DREDGE,#m_depot_dredge_tos{bagid=NewRemoteDepotNum+5},RoleID,PID,Line,MapState})
					end;
				{aborted, {error,ErrCode,undefined}} ->
					?UNICAST_TOC(#m_vip_remote_depot_toc{err_code=ErrCode});
				{aborted, {error, ErrorCode, ErrorStr}} ->
					common_misc:send_common_error(RoleID, ErrorCode, ErrorStr);
				{aborted, Reason} ->
					?ERROR_MSG("buy_tili error,Reason:~w",[Reason]),
					?UNICAST_TOC(#m_vip_remote_depot_toc{err_code=?ERR_SYS_ERR})
			end
	end.

check_remote_depot(RoleID) ->
	{ok,#r_role_vip{remote_depot_num=RemoteDepot,vip_level=VipLevel}=VipInfo} = get_role_vip_info(RoleID),
	[MinVipLevel] = ?find_config(remote_depot_min_level),
	case VipLevel < MinVipLevel of
		true ->
			?THROW_ERR(?ERR_VIP_REMOTE_DEPOT_LEVEL_NOT_ENOUGH);
		false ->
			next
	end,
	[MaxRemoteDepotNum] = ?find_config(max_remote_depot_num),
	case RemoteDepot >= MaxRemoteDepotNum of
		true ->
			?THROW_ERR(?ERR_VIP_REMOTE_DEPOT_MAX_DEPOT);
		_ ->
			next
	end,
	[RemoteDepotFee] = ?find_config({remote_depot_fee,RemoteDepot}),
	{ok,VipInfo,RemoteDepotFee}.
			
%% 领取每日/每周道具奖励
reward({Unique, Module, Method, DataIn, RoleID, PID, _Line, _State})->
	#m_vip_reward_tos{type=Type} = DataIn,
	case catch check_reward(RoleID,Type) of
		{error,ErrCode,_ErrReason} ->
			?UNICAST_TOC(#m_vip_reward_toc{type=Type,err_code=ErrCode});
		{ok,VipLevel,EventLog,VipInfo} ->
			TransFun = fun()-> 
							   t_reward(RoleID,Type,VipLevel,EventLog,VipInfo)
					   end,
			case db:transaction( TransFun ) of
				{atomic, {ok,RewardGoodsList,RewardItemList}} ->
					common_misc:update_goods_notify(PID,RewardGoodsList),
					lists:foreach(
					  fun(#p_reward_prop{prop_id=TypeID,prop_num=Num}) ->
							  ?TRY_CATCH(common_item_logger:log(RoleID,TypeID,Num,undefined,?LOG_ITEM_TYPE_GET_SUPER_VIP_REWARD))
					  end,RewardItemList),
					?UNICAST_TOC(#m_vip_reward_toc{type=Type});
				{aborted, {throw,{bag_error,{not_enough_pos,_}}}} ->
					?UNICAST_TOC(#m_vip_reward_toc{type=Type,err_code=?ERR_SUPER_VIP_MAX_BAG_NUM});
				{aborted, {throw,{error,ErrCode,undefined}}} ->
					?UNICAST_TOC(#m_vip_reward_toc{type=Type,err_code=ErrCode});
				{aborted, Reason} ->
					?ERROR_MSG("reward error,RoleID:~w,Type:~w,Reason:~w",[RoleID,Type,Reason]),
					?UNICAST_TOC(#m_vip_reward_toc{type=Type,err_code=?ERR_SYS_ERR})
			end
	end.

check_reward(RoleID,Type) ->
	{ok, #r_role_vip{vip_level=VipLevel,event_log=EventLog}=VipInfo} = get_role_vip_info(RoleID),
	{_,LastDailyTime} = get_event_log(get_daily_reward,EventLog),
	{_,LastWeeklyTime} = get_event_log(get_weekly_reward,EventLog),
	if
		Type =:= ?TYPE_WEEKLY ->
			case has_get_weekly_reward(LastWeeklyTime) of
				true ->
					?THROW_ERR(?ERR_SUPER_VIP_HAS_REWARD);
				false ->
					next
			end;
		true ->
			case has_get_daily_reward(LastDailyTime) of
				true ->
					?THROW_ERR(?ERR_SUPER_VIP_HAS_REWARD);
				false ->
					next
			end
	end,
	{ok,VipLevel,EventLog,VipInfo}.

has_get_daily_reward(LastDailyTime) ->
	common_time:is_today(LastDailyTime).
has_get_weekly_reward(LastWeeklyTime) ->
	{LastWeeklyDate,_} = common_tool:seconds_to_datetime(LastWeeklyTime),
	common_time:week_of_year2() =:= common_time:week_of_year2(LastWeeklyDate).

t_reward(RoleID,Type,VipLevel,EventLog,VipInfo) ->
	#r_vip_level_info{daily_reward=DailyReward,weekly_reward=WeeklyReward} = get_vip_level_info(VipLevel),
	if
		Type =:= ?TYPE_WEEKLY ->
			NewEventLog = set_event_log(get_weekly_reward, EventLog, 1),
			RewardItemList = WeeklyReward;
		true ->
			NewEventLog = set_event_log(get_daily_reward, EventLog, 1),
			RewardItemList = DailyReward
	end,
	{ok,RewardGoodsList} = common_bag2:t_reward_prop(RoleID, RewardItemList),
	NewVipInfo = VipInfo#r_role_vip{event_log=NewEventLog},
	t_set_role_vip_info(RoleID, NewVipInfo),
	{ok,RewardGoodsList,RewardItemList}.

%% 购买VIP BUFF
vip_buy_buff({Unique, Module, Method, DataIn, RoleID, PID, _Line, _State})->
	#m_vip_buy_buff_tos{op_type=OpType,buy_type=BuyType} = DataIn,
    case OpType of
        ?OP_BUFF_INFO ->
            buff_info({Unique,Module,Method,OpType,RoleID,PID});
        ?OP_BUY_BUFF ->
            do_buy_buff({Unique,Module,Method,BuyType,RoleID,PID});
        _ ->
            ?UNICAST_TOC(#m_vip_buy_buff_toc{err_code=?ERR_SYS_ERR})
    end.

buff_info({Unique,Module,Method,OpType,RoleID,PID}) ->
	case get_vip_current_buff_list(RoleID,buff) of
		[] ->
			BuyBuffID = 0;
		BuffList ->
			BuyBuffID = hd(BuffList)
	end,
	case get_vip_current_buff_list(RoleID,exp_buff) of
		[] ->
			BuyExpBuffID = 0;
		ExpBuffList ->
			BuyExpBuffID = hd(ExpBuffList)
	end,
	?UNICAST_TOC(#m_vip_buy_buff_toc{op_type=OpType,free_buff_times=get_remain_free_buff_times(RoleID,buff),buff_id=BuyBuffID,
									 free_exp_buff_times=get_remain_free_buff_times(RoleID,exp_buff),exp_buff_id=BuyExpBuffID}),
	
	ok.

%% BuffType = buff | exp_buff
get_remain_free_buff_times(RoleID,BuffType) ->
	{ok, #r_role_vip{event_log=EventLog}} = get_role_vip_info(RoleID),
	[{MaxBuffTimes,MaxExpBuffTimes}] = ?find_config(free_buff_times),
	case BuffType of
		exp_buff ->
			MaxGetFreeBuffTimes = MaxBuffTimes,
			GetFreeBuff = get_free_buff;
		_ ->
			MaxGetFreeBuffTimes = MaxExpBuffTimes,
			GetFreeBuff = get_free_exp_buff
	end,
	{TodayGetFreeBuffTimes,LastTime} = get_event_log(GetFreeBuff, EventLog),
	case common_time:is_today(LastTime) of
		true ->
			MaxGetFreeBuffTimes - TodayGetFreeBuffTimes;
		false ->
			MaxGetFreeBuffTimes
	end.

do_buy_buff({Unique,Module,Method,BuyType,RoleID,PID}) ->
	case common_transaction:transaction(fun()-> t_do_buy_buff(RoleID, BuyType) end) of
		{atomic, Status} ->
			case Status of
				{ok,RoleAttr} ->
					common_misc:send_role_gold_change(RoleID, RoleAttr);
				_ ->
					ignore
			end,
			do_buy_buff_succ(RoleID,BuyType);
		{aborted, {error,ErrCode,Reason}} ->
			?UNICAST_TOC(#m_vip_buy_buff_toc{op_type=?OP_BUY_BUFF,err_code=ErrCode,reason=Reason});
		{aborted, Err} ->
			?ERROR_MSG(" vip buy buff Error: ~w", [Err]),
			?UNICAST_TOC(#m_vip_buy_buff_toc{op_type=?OP_BUY_BUFF,err_code=?ERR_SYS_ERR})
	end.

do_buy_buff_succ(RoleID,BuyType) ->
	add_vip_buff(RoleID, BuyType),
	case get_vip_current_buff_list(RoleID,buff) of
		[] ->
			BuyBuffID = 0;
		BuffList ->
			BuyBuffID = hd(BuffList)
	end,
	case get_vip_current_buff_list(RoleID,exp_buff) of
		[] ->
			BuyExpBuffID = 0;
		ExpBuffList ->
			BuyExpBuffID = hd(ExpBuffList)
	end,
	R = #m_vip_buy_buff_toc{op_type=?OP_BUY_BUFF,buy_type=BuyType,
							free_buff_times=get_remain_free_buff_times(RoleID,buff),buff_id=BuyBuffID,
							free_exp_buff_times=get_remain_free_buff_times(RoleID,exp_buff),exp_buff_id=BuyExpBuffID},
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?VIP, ?VIP_BUY_BUFF,R).

t_do_buy_buff(RoleID, BuyType) ->
	case get_role_vip_level(RoleID) > 0 of
		true ->
			ok;
		_ ->
			?THROW_ERR(?ERR_SUPER_VIP_CAN_BUY_BUFF)
	end,
	RemainTime = get_role_vip_buff_last_value(RoleID,BuyType),
	MaxEndTimeSeconds = common_tool:datetime_to_seconds({erlang:date(), {23,59,59}}),
	case common_tool:now() + RemainTime >= MaxEndTimeSeconds of
		true ->
			?THROW_ERR(?ERR_SUPER_VIP_MAX_BUFF_HOUR);
		_ ->
			ok
	end,
	BuffType = buff_type(BuyType),
	case {get_remain_free_buff_times(RoleID,BuffType) > 0, (BuyType =:= ?BUY_TYPE_ONE orelse BuyType =:= ?BUY_TYPE_THREE)} of
		{true, true} ->
			{ok, #r_role_vip{event_log=EventLog}=VipInfo} = get_role_vip_info(RoleID),
			GetFreeBuff = 
				case BuffType of
					exp_buff ->
						get_free_buff;
					_ ->
						get_free_exp_buff
				end,
			{GetFreeBuffTimes,_} = get_event_log(GetFreeBuff, EventLog),
			NewEventLog = set_event_log(GetFreeBuff, EventLog, GetFreeBuffTimes+1),
			t_set_role_vip_info(RoleID, VipInfo#r_role_vip{event_log=NewEventLog});
		_ ->
			{MoneyType, DeductMoney} = get_buy_buff_cost(BuyType),
			case common_bag2:t_deduct_money(MoneyType, DeductMoney, RoleID, ?CONSUME_TYPE_GOLD_VIP_BUY_BUFF) of
				{ok,RoleAttr2} ->
					{ok,RoleAttr2};
				{error, Reason} ->
					?THROW_ERR(?ERR_OTHER_ERR, Reason);
				_ ->
					?THROW_ERR(?ERR_SUPER_VIP_NOT_ENOUGH_GOLD)
			end
	end.

get_buy_buff_cost(BuyType) ->
    case ?find_config({buy_buff,BuyType}) of
        [] ->
            ?THROW_SYS_ERR();
        [{MoneyType, DeductMoney}] ->
            {MoneyType, DeductMoney}
    end.

add_vip_buff(RoleID, BuyType) -> 
    BuffIDList = get_vip_current_buff_list(RoleID,buff_type(BuyType)),
    BuffDetailList = get_buff_detail_list(RoleID, BuyType, BuffIDList),
    mod_role_buff:add_buff(RoleID, BuffDetailList),
    ok.

%% BuffType = buff | exp_buff
get_vip_current_buff_list(RoleID,BuffType) ->
    VipLevel = get_role_vip_level(RoleID),
    {ok,#p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
	[BuffConf] = ?find_config({BuffType,VipLevel}),
    get_can_buy_buff_list(Level,BuffConf).

get_can_buy_buff_list(_,[]) ->
	[];
get_can_buy_buff_list(Level, [{MinLevel,MaxLevel,BuffIdList}|T]) ->
	if Level >= MinLevel andalso MaxLevel >= Level ->
		   BuffIdList;
	   true ->
		   get_can_buy_buff_list(Level, T)
	end.

buff_type(BuyType) ->
	case BuyType =:= ?BUY_TYPE_ONE orelse BuyType =:= ?BUY_TYPE_TWO of
		true -> buff;
		false -> exp_buff
	end.

get_buff_detail_list(RoleID,BuyType,BuffIdList) ->
    Multiple = 
        case BuyType of
            ?BUY_TYPE_ONE ->
                1;
            ?BUY_TYPE_TWO ->
                24;
            ?BUY_TYPE_THREE ->
                1;
            ?BUY_TYPE_FOUR ->
                24;
            _ ->
                1
        end,
    RemainTime = get_role_vip_buff_last_value(RoleID,BuyType),
    lists:map(
      fun(BuffID) ->
              {ok, #p_buf{last_value=LastTime}=BuffDetail} = mod_skill_manager:get_buf_detail(BuffID),
              MaxEndTimeSeconds = common_tool:datetime_to_seconds({erlang:date(), {23,59,59}}),
              NewLastTime = erlang:min(RemainTime+erlang:trunc(LastTime*Multiple), MaxEndTimeSeconds-common_tool:now()),
              BuffDetail#p_buf{last_value=erlang:max(NewLastTime,0)}
      end, BuffIdList).

-define(VIP_BUFF_ADD_ATTACK_TYPE(BuffType), 
		case BuffType of
			buff -> 5101;
			_ -> 1050
		end).
get_role_vip_buff_last_value(RoleID,BuyType) ->
	BuffType = buff_type(BuyType),
    {ok, #p_role_base{buffs=Buffs}} = mod_map_role:get_role_base(RoleID),
    case lists:keyfind(?VIP_BUFF_ADD_ATTACK_TYPE(BuffType), #p_actor_buf.buff_type, Buffs) of
        false ->
            0;
        #p_actor_buf{end_time=EndTime} ->
            EndTime - common_tool:now()
    end.

%% 设置角色VIP信息
set_role_vip_info(RoleID,VipInfo)->
	set_role_vip_info(RoleID,VipInfo,false).
set_role_vip_info(RoleID,VipInfo,IsNotify)->
    case common_transaction:t(
           fun() ->
                   t_set_role_vip_info(RoleID, VipInfo)
           end)
    of
        {atomic, _} ->
            case IsNotify of
                true ->
					cast_vip_info(VipInfo);
                _ ->
                    ignore
            end,
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("set_role_vip_info, error: ~w", [Error]),
            error
    end.

%% 获取商店折扣
get_vip_shop_discount(RoleID) ->
	case get_role_vip_level(RoleID) of
		VipLevel when VipLevel =:= 0 ->
			100;
		VipLevel ->
			LevelInfo = get_vip_level_info(VipLevel),
			LevelInfo#r_vip_level_info.shop_discount
	end.

%% 获取VIP异兽提悟概率提升
get_vip_pet_understand_rate(RoleID) ->
	VipLevel = get_role_vip_level(RoleID),
	case VipLevel > 0 of
		true ->
			LevelInfo = get_vip_level_info(VipLevel),
			LevelInfo#r_vip_level_info.pet_understanding_rate;
		_ ->
			0
	end.

%% 赃读VIP等级
get_dirty_role_vip_level(RoleID) ->
	case db:dirty_read(?DB_ROLE_VIP_P, RoleID) of
		[] ->
			0;
		[#r_role_vip{vip_level=Level}] ->
			Level
	end.

%% 是否VIP
is_role_vip(RoleID) ->
	case get_role_vip_info(RoleID) of
		{ok, VipInfo} ->
			VipInfo#r_role_vip.vip_level>0;
		_ ->
			false
	end.

%% 获取VIP等级信息
get_vip_level_info(VipLevel) ->
    case ?find_config({vip_level_info,VipLevel}) of
		[] -> undefined;
		[LevelInfo] -> LevelInfo
	end.

cast_vip_info(RoleID) when is_integer(RoleID) ->
	case get_role_vip_info(RoleID) of
		{ok, VipInfo} when is_record(VipInfo, r_role_vip) ->
			cast_vip_info(VipInfo);
		_ ->
			ignore
	end;
cast_vip_info(VipInfo) ->
	#r_role_vip{role_id=RoleID,vip_level=VipLevel,jifen=Jifen,is_transfer_notice_free=false,is_transfer_notice=false,
				remote_depot_num=RemoteDepotNum,event_log=EventLog} = VipInfo,
	case get_vip_level_info(VipLevel) of
		undefined -> MaxMissionTransferTimes = 0;
		#r_vip_level_info{mission_transfer_times=MaxMissionTransferTimes} ->
			next
	end,
	{MissionTransferTimes,LastTime} = get_event_log(mission_transfer, EventLog),
	RemainMissionTransferTimes = 	
		case common_time:is_today(LastTime) of
			true ->
				MaxMissionTransferTimes - MissionTransferTimes;
			false ->
				MaxMissionTransferTimes
		end,
	NextLevelJifen     = vip_level_jifen(VipLevel+1),
	{_,LastDailyTime}  = get_event_log(get_daily_reward,EventLog),
	{_,LastWeeklyTime} = get_event_log(get_weekly_reward,EventLog),
	HasGetWeeklyReward = has_get_weekly_reward(LastWeeklyTime),
	HasGetDailyReward  = has_get_daily_reward(LastDailyTime),
	PRoleVip = #p_role_vip{role_id=RoleID,vip_level=VipLevel,jifen=Jifen,next_level_jifen=NextLevelJifen,
						   next_level_pay_gold=next_level_pay_gold(Jifen,NextLevelJifen),
						   mission_transfer_times=RemainMissionTransferTimes,is_transfer_notice_free=true,
						   is_transfer_notice=true,remote_depot_num=RemoteDepotNum,
						   has_get_weekly_reward=HasGetWeeklyReward,has_get_daily_reward=HasGetDailyReward},
	R = #m_vip_info_toc{vip_info=PRoleVip},
	common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?VIP,?VIP_INFO,R).

t_set_role_vip_info(RoleID, VipInfo) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,RoleExtInfo} ->
			NewRoleExtInfo = RoleExtInfo#r_role_map_ext{vip=VipInfo},
			mod_map_role:t_set_role_map_ext_info(RoleID, NewRoleExtInfo),
			ok;
		_ ->
			?THROW_SYS_ERR()
	end.

get_role_vip_info(RoleID) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{vip=VipInfo}} ->
			{ok, VipInfo};
		_ ->
			?ERROR_MSG("get_role_vip_info error,RoleID=~w",[RoleID]),
			?THROW_SYS_ERR()
	end.

%% 是否可使用积分卡
assert_use_vip_card(RoleID) ->
	{ok, #r_role_vip{vip_level=VipLevel,event_log=EventLog}=VipInfo} = get_role_vip_info(RoleID),
	{HasUseNum,LastUseTime} = get_event_log(vip_card, EventLog),
	case get_vip_level_info(VipLevel) of
		undefined ->
			[Limit] = ?find_config(daily_vip_card_use_limit);
		#r_vip_level_info{daily_vip_card_use_limit=Limit} ->
			next
	end,
	case common_time:is_today(LastUseTime) of
		true ->
			NewHasUseNum = HasUseNum + 1;
		false ->
			NewHasUseNum = 1
	end,
	case NewHasUseNum > Limit of
		true ->
			?THROW_ERR(lists:concat(["您每天使用积分卡次数不能超过",Limit,"次，可升级VIP等级获取更多的积分卡使用次数！"]));
		false ->
			NewEventLog = set_event_log(vip_card, EventLog, NewHasUseNum),
			{ok,VipInfo#r_role_vip{event_log=NewEventLog}}
	end.

hook_use_gold(RecList) ->
	lists:foreach(
	  fun(Rec) ->
			  #r_consume_log{type=Type,role_id=RoleID,use_bind=UseBind,use_unbind=UseUnbind,mtype=MType}=Rec,
			  case Type=:=gold of
				  true ->
					  IsDeductType = lists:member(MType, ?CIRCULATE_LOG_TYPE),
					  IsPayType = lists:member(MType, ?PAY_LOG_TYPE),
					  AddJifen = 
						  if
							  IsDeductType =:= false andalso UseUnbind > 0 ->
								  consume_conversion_jifen(UseUnbind);
							  IsPayType =:= true ->
								  pay_conversion_jifen((erlang:abs(UseBind)+erlang:abs(UseUnbind)));
							  true ->
								  0
						  end,
					  use_gold_add_jifen(RoleID,AddJifen);
				  false ->
					  ignore
			  end
	  end, RecList).

get_event_log(Key,EventLog) ->
	case lists:keyfind(Key, 1, EventLog) of
		false -> {0,0};
		{_,Count,LastTime} -> {Count,LastTime}
	end.

set_event_log(Key,EventLog,NewCount) ->
	Now = mgeem_map:get_now(),
	case lists:keyfind(Key, 1, EventLog) of
		false -> 
			[{Key,1,Now}|EventLog];
		_ ->
			[{Key,NewCount,Now}|lists:keydelete(Key,1,EventLog)]
	end.

vip_level_jifen(VipLevel) ->
	case get_vip_level_info(VipLevel) of
		undefined ->
			(get_vip_level_info(?FULL_SUPER_VIP_LEVEL))#r_vip_level_info.need_jifen;
		#r_vip_level_info{need_jifen=NeedJifen} ->
			NeedJifen
	end.

%% 到下一VIP等级需要消费的元宝
next_level_pay_gold(Jifen,NextLevelJifen) ->
	[Conversion] = ?find_config(consume_conversion_jifen),
	common_tool:ceil((NextLevelJifen - Jifen) * Conversion).

%% 返回VIP等级（0-12）
get_role_vip_level(RoleID) when is_integer(RoleID) ->
	{ok, VipInfo} = get_role_vip_info(RoleID),
	get_role_vip_level(VipInfo);
get_role_vip_level(VipInfo) ->
	VipInfo#r_role_vip.vip_level.

%% return {NewLevel,NewJifen}
calc_add_jifen(VipLevel,Jifen,AddJifen) ->
	TotalJifen = AddJifen + Jifen,
	case VipLevel =:= ?FULL_SUPER_VIP_LEVEL of
		true ->
			{VipLevel, TotalJifen};
		false ->
			NextLevel = VipLevel + 1,
			#r_vip_level_info{need_jifen=NextNeedJifen} = get_vip_level_info(NextLevel),
			case TotalJifen >= NextNeedJifen of
				true ->
					RemainJifen = TotalJifen - NextNeedJifen,
					calc_add_jifen(NextLevel, NextNeedJifen, RemainJifen);
				false ->
					{VipLevel, TotalJifen}
			end
	end.

clear_vip_card_times(RoleID) ->
	{ok, #r_role_vip{event_log=EventLog}=VipInfo} = get_role_vip_info(RoleID),
	set_role_vip_info(RoleID,VipInfo#r_role_vip{event_log=lists:keydelete(vip_card, 1, EventLog)},true).

%%更新vip多倍经验buff，添加vip称号
vip_level_up(RoleID,VipLevel) ->
	#r_vip_level_info{multi_exp_buff_id=ExpBuffID} = get_vip_level_info(VipLevel),
	case ExpBuffID > 0 of
		true ->
			mod_role_buff:del_buff_by_type(RoleID,?vip_multiple_exp_type),
			mod_role_buff:add_buff(RoleID,ExpBuffID);
		false ->
			ignore
	end,
	upgrade_vip_title(RoleID,VipLevel),
	mod_role_event:notify(RoleID, {?ROLE_EVENT_VIP_LV, VipLevel}),
	mod_map_role:update_map_role_info(RoleID, [{#p_map_role.vip_level, VipLevel}]).

upgrade_vip_title(RoleID,VipLevel) ->
	#r_vip_level_info{title_name=TitleName,color=Color} = get_vip_level_info(VipLevel),
	%% 添加VIP称号
	case TitleName =:= "" of
		true ->
			ignore;
		_ ->
			common_title_srv:add_title(?TITLE_VIP, RoleID, {TitleName, Color})
	end.

%% 当前VIP特权等级所需的积分
%% 消耗的元宝换算成积分
consume_conversion_jifen(Gold) ->
	[Conversion] = ?find_config(consume_conversion_jifen),
	common_tool:floor(Gold / Conversion).

pay_conversion_jifen(Gold) ->
	[Conversion] = ?find_config(pay_conversion_jifen),
	common_tool:floor(Gold / Conversion).

use_gold_add_jifen(RoleID,AddJifen) when AddJifen > 0 ->
	%% 有可能是离线充值，也要加积分
	case common_misc:is_role_online2(RoleID) of
		true ->
			mgeer_role:absend(RoleID,{mod,mod_vip,{add_jifen,RoleID,AddJifen}});
		false ->
			case db:dirty_read(?DB_ROLE_VIP_P,RoleID) of
				[VipInfo] ->
					{ok,NewVipInfo,OldVipLevel,NewVipLevel} = t_add_jifen(VipInfo,AddJifen),
					db:dirty_write(?DB_ROLE_VIP_P,NewVipInfo),
					case NewVipLevel > OldVipLevel of
						true ->
							upgrade_vip_title(RoleID, NewVipLevel);
						false ->
							ignore
					end;
				_ ->
					?ERROR_MSG("use_gold_add_jifen error,RoleID=~w,AddJifen=~w",[RoleID,AddJifen])
			end
	end;
use_gold_add_jifen(_RoleID,_AddJifen) ->
	ignore.

%% 玩家在不在线
pay_add_jifen(_RoleID, PayGold) when PayGold =< 0 -> ok;
pay_add_jifen(RoleID, PayGold) ->
	try
		AddJifen = pay_conversion_jifen(PayGold),
		use_gold_add_jifen(RoleID, AddJifen)
	catch
		Type:Error ->
			?ERROR_MSG("role ~w pay_add_jifen error: ~w, type: ~w", [RoleID, Error, Type])
	end.
	

add_jifen(RoleID,AddJifen) when is_integer(RoleID) ->
	{ok,VipInfo} = get_role_vip_info(RoleID),
	add_jifen(VipInfo,AddJifen);
add_jifen(VipInfo,AddJifen) ->
	#r_role_vip{role_id=RoleID} = VipInfo,
	{ok,NewVipInfo,OldVipLevel,NewVipLevel} = t_add_jifen(VipInfo,AddJifen),
	set_role_vip_info(VipInfo#r_role_vip.role_id,NewVipInfo,true),
	case NewVipLevel > OldVipLevel of
		true ->
			hook_map_role:vip_upgrade(RoleID,OldVipLevel,NewVipLevel),
			lists:member(NewVipLevel, ?BROADCAST_VIP_LEVEL) andalso ?TRY_CATCH(do_vip_up_broadcast(RoleID,NewVipLevel)),
			vip_level_up(RoleID,NewVipLevel);
		false ->
			ignore
	end.

do_vip_up_broadcast(RoleID,NewVipLevel) ->
	{ok,#p_role_base{role_name = RoleName}} = mod_map_role:get_role_base(RoleID), 
	Message = common_misc:format_lang(?_LANG_VIP_UP_BROADCAST_MSG, [RoleName,common_tool:to_list(NewVipLevel)]),
	common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,Message),
	common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_SUB_TYPE,Message).
	
%% return {ok,NewVipInfo,OldVipLevel,NewVipLevel}
t_add_jifen(VipInfo,AddJifen) ->
	#r_role_vip{vip_level=VipLevel,jifen=Jifen,remote_depot_num=RemoteDepotNum} = VipInfo,
	{NewVipLevel,NewJifen} = calc_add_jifen(VipLevel, Jifen, AddJifen),
	NewRemoteDepotNum = 
		case NewVipLevel > VipLevel of
			true ->
				[MinVipLevel] = ?find_config(remote_depot_min_level),
				case RemoteDepotNum =:= 0 andalso NewVipLevel >= MinVipLevel of
					true -> 1;
					_ -> RemoteDepotNum
				end;
			false ->
				RemoteDepotNum
		end,
	{ok,VipInfo#r_role_vip{remote_depot_num=NewRemoteDepotNum,vip_level=NewVipLevel,jifen=NewJifen},
	 VipLevel,NewVipLevel}.
	
