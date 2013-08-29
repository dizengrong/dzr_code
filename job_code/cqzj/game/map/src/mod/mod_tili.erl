%%% @author fsk 
%%% @doc
%%%     体力模块
%%% @end
%%% Created : 2012-8-13
%%%-------------------------------------------------------------------
-module(mod_tili).

-include("mgeem.hrl").

-export([
			handle/1,
			handle/2,
			buy_tili/1,
			p_tili_info/1,
			t_buy_tili/1,
			hook_role_online/1,
			use_tili_card/2,
			use_tili_card/3,
			free_add_tili/2,
			auto_recover_tili/1,
			get_total_tili_card_tili/1,
			get_total_tili_role_can_buy/1,
			need_tili_card/1
		]).
-export([
			get_role_tili/1,
			reduce_role_tili/2,
			reduce_role_tili/3,
			cast_role_tili_info/1
		]).

-define(CONFIG_NAME,tili).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

-define(ERR_TILI_TODAY_BUY_FULL_TIMES,548001).%%今天购买次数已满

-define(TILI_CARD_ITEM_ID, 10100092).

handle(Msg,_State) ->
	handle(Msg).

handle({set_role_tili,RoleID,Tili}) ->
	case common_transaction:t(fun() -> 
									  {ok, RoleTili} = get_tili_info(RoleID),
									  NewRoleTili = RoleTili#r_role_tili{cur_tili=Tili},
									  t_set_tili_info(RoleID,NewRoleTili),
									  {ok,NewRoleTili}
							  end) of
		{atomic, {ok,NewRoleTili}} ->
			cast_role_tili_info(NewRoleTili);
		Reason ->
			?ERROR_MSG("set_role_tili error,RoleID=~w,Tili=~w,Reason=~w",[RoleID,Tili,Reason])
	end.

%% 计算玩家背包中所有体力卡的总体力
get_total_tili_card_tili(RoleID) ->
	{ok, Num} = mod_bag:get_goods_num_by_typeid([1], RoleID, ?TILI_CARD_ITEM_ID),
	tili_from_card() * Num.

%% 获取玩家当前能够购买的体力
get_total_tili_role_can_buy(RoleID) ->
	AddTili       = tili_from_card(),
	{ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
	#p_role_attr{gold=GoldUnbind,gold_bind=GoldBind} = RoleAttr,
	case mod_shop:get_goods_price(?TILI_CARD_ITEM_ID) of
		{gold_unbind, Price} ->
			(GoldUnbind div Price) * AddTili;
		{gold_any, Price} ->
			(GoldBind div Price) * AddTili
	end.

%% 计算消耗CostTili点体力，需要多少张体力卡
need_tili_card(CostTili) ->
	common_misc:ceil_div(CostTili, tili_from_card()).

tili_from_card() ->
	[ItemBaseInfo] = common_config_dyn:find(item, ?TILI_CARD_ITEM_ID),
	#p_item_base_info{effects = [#p_item_effect{parameter = AddTiliStr}]} = ItemBaseInfo,
	erlang:list_to_integer(AddTiliStr).

auto_add_tili(AddTili,LastAutoIncreaseTime,RoleID) ->
	case common_transaction:t(fun() -> t_add_tili(auto,AddTili,LastAutoIncreaseTime,RoleID) end) of
		{atomic, {ok,RoleTili}} ->
			cast_role_tili_info(RoleTili);
		Reason ->
			?ERROR_MSG("auto_add_tili error,AddTili=~w,LastAutoIncreaseTime=~w,RoleID=~w,Reason=~w",
					   [AddTili,LastAutoIncreaseTime,RoleID,Reason])
	end.

get_role_tili(RoleID) ->
	case get_tili_info(RoleID) of
		{ok, #r_role_tili{cur_tili=CurTili}} ->
			CurTili;
		_ ->
			0
	end.

reduce_role_tili(RoleID,ReduceTili) ->
	reduce_role_tili(RoleID,ReduceTili,true).
reduce_role_tili(RoleID,ReduceTili,Notify) ->
	{ok, #r_role_tili{cur_tili=CurTili}=RoleTili} = get_tili_info(RoleID),
	case ReduceTili > CurTili of
		true ->
			?ERROR_MSG("扣除玩家~w体力失败，体力~w不足:~w",[RoleID,CurTili,ReduceTili]);
		false ->
			TransFun = fun() -> 
							   NewRoleTili = RoleTili#r_role_tili{cur_tili=CurTili-ReduceTili},
							   t_set_tili_info(RoleID,NewRoleTili),
							   {ok,NewRoleTili}
					   end,
			case common_transaction:t(TransFun) of
				{atomic, {ok,NewRoleTili}} ->
					case Notify of
						true ->
							cast_role_tili_info(NewRoleTili);
						false ->
							ignore
					end;
				Reason ->
					?ERROR_MSG("set_role_tili error,RoleID=~w,ReduceTili=~w,Reason=~w",[RoleID,ReduceTili,Reason])
			end
	end.
	
%% 自动恢复体力
auto_recover_tili(RoleID) ->
	[{Interval,AddTiti,TiliLimit}] = ?find_config(auto_increase_tili),
	Now = mgeem_map:get_now(),
	case get_tili_info(RoleID) of
		{ok, #r_role_tili{cur_tili=CurTili,last_auto_increase_time=LastAutoIncreaseTime}} ->
			case CurTili >= TiliLimit of
				true ->
					ignore;
				false ->
					case Now - LastAutoIncreaseTime >= Interval of
						true ->
							auto_add_tili(AddTiti,Now,RoleID);
						false ->
							ignore
					end
			end;
		_ -> ignore
	end.

hook_role_online(RoleID) ->
	{ok, #r_role_tili{last_auto_increase_time=LastAutoIncreaseTime}=RoleTili} = get_tili_info(RoleID),
	[{Interval,AddTiti,_TiliLimit}] = ?find_config(auto_increase_tili),
	Now = common_tool:now(),
	DiffSeconds = Now - LastAutoIncreaseTime,
	TotalAddTiti = DiffSeconds div Interval * AddTiti,
	NewLastAutoIncreaseTime = Now - DiffSeconds rem Interval,
	case TotalAddTiti > 0 of
		true ->
			auto_add_tili(TotalAddTiti,NewLastAutoIncreaseTime,RoleID);
		false ->
			cast_role_tili_info(RoleTili)
	end.

%% 使用体力卡加体力
use_tili_card(RoleID,AddTili) ->
	{ok,#r_role_tili{cur_tili=CurTili,last_auto_increase_time=LastAutoIncreaseTime}=RoleTili} = get_tili_info(RoleID),
	[{_,_,TiliLimit}] = ?find_config(auto_increase_tili),
	case CurTili >= TiliLimit of
		true ->
			?THROW_ERR_REASON(lists:concat(["体力已达到最大值",TiliLimit,"，不需要再使用体力卡"]));
		false ->
			t_add_tili(auto,AddTili,LastAutoIncreaseTime,RoleTili)
	end.

use_tili_card(RoleID,AddTili,UseNum) ->
	{ok,#r_role_tili{cur_tili=CurTili,last_auto_increase_time=LastAutoIncreaseTime}=RoleTili} = get_tili_info(RoleID),
	[{_,_,TiliLimit}] = ?find_config(auto_increase_tili),
	ActullyUsed = (TiliLimit - CurTili) div AddTili,
	case ActullyUsed >= UseNum of
		true  -> UseNum1 = UseNum;
		false -> UseNum1 = ActullyUsed
	end,
	case CurTili >= TiliLimit of
		true ->
			?THROW_ERR_REASON(lists:concat(["体力已达到最大值",TiliLimit,"，不需要再使用体力卡"]));
		false ->
			{ok,RoleTili2} = t_add_tili(auto,AddTili*UseNum1,LastAutoIncreaseTime,RoleTili),
			{ok,RoleTili2,UseNum1}
	end.

%% 加体力
free_add_tili(RoleID,AddTili) ->
	{ok,#r_role_tili{cur_tili=CurTili,last_auto_increase_time=LastAutoIncreaseTime}=RoleTili} = get_tili_info(RoleID),
	[{_,_,TiliLimit}] = ?find_config(auto_increase_tili),
	case CurTili >= TiliLimit of
		true ->
			ignore;
			% ?THROW_ERR_REASON(lists:concat(["体力已达到最大值",TiliLimit]));
		false ->
			{ok,NewRoleTili} = t_add_tili(free,AddTili,LastAutoIncreaseTime,RoleTili),
			cast_role_tili_info(NewRoleTili)
	end.

buy_tili({Unique, Module, Method, RoleID, PID}) ->
	TransFun = fun()-> 
					   t_buy_tili(RoleID)
			   end,
	case common_transaction:t( TransFun ) of
		{atomic, {ok,NewRoleTili,NewRoleAttr}} ->
			case NewRoleAttr of
				null -> nil;
				_ -> common_misc:send_role_gold_change(RoleID,NewRoleAttr)
			end,
			cast_role_tili_info(NewRoleTili),
			?UNICAST_TOC(#m_role2_buy_tili_toc{});
		{aborted, {error,ErrCode,undefined}} ->
			?UNICAST_TOC(#m_role2_buy_tili_toc{err_code=ErrCode});
		{aborted, {error,ErrCode,Reason}} ->
			?UNICAST_TOC(#m_role2_buy_tili_toc{err_code=ErrCode, reason = Reason});
		{aborted, Reason} ->
			?ERROR_MSG("buy_tili error,Reason:~w",[Reason]),
			?UNICAST_TOC(#m_role2_buy_tili_toc{err_code=?ERR_SYS_ERR})
	end.

p_tili_info(RoleID) when is_integer(RoleID) ->
	case get_tili_info(RoleID) of
		{ok, RoleTili} ->
			p_tili_info(RoleTili);
		_ ->
			#p_tili_info{}
	end;
p_tili_info(RoleTili) when is_record(RoleTili, r_role_tili)->
	#r_role_tili{role_id=RoleID,cur_tili=CurTili,last_buy_time=LastBuyTime,today_buy_times=TodayBuyTimes}=RoleTili,
	[{_Interval,_AddTiti,TiliLimit}] = ?find_config(auto_increase_tili),
	[{AddTili,{_MoneyType,CostMoneyConf}}] = ?find_config(buy_tili),
	NewTodayBuyTimes = today_buy_times(TodayBuyTimes,LastBuyTime),
	CostMoney = buy_tili_cost(NewTodayBuyTimes+1,CostMoneyConf),
	BuyTimesLimit = buy_times_limit(RoleID),
	#p_tili_info{cur_tili=CurTili,max_tili=TiliLimit,can_buy_tili=AddTili,today_buy_times=NewTodayBuyTimes,
				 max_buy_times=BuyTimesLimit,buy_need_gold=CostMoney}.

t_buy_tili(RoleID) ->
	{ok,#r_role_tili{last_buy_time=LastBuyTime,last_auto_increase_time=LastAutoIncreaseTime,today_buy_times=TodayBuyTimes}=RoleTili} = get_tili_info(RoleID),
	NewTodayBuyTimes = today_buy_times(TodayBuyTimes,LastBuyTime) + 1,
	[{AddTili,{MoneyType,CostMoneyConf}}] = ?find_config(buy_tili),
	CostMoney = buy_tili_cost(NewTodayBuyTimes,CostMoneyConf),
	BuyTimesLimit = buy_times_limit(RoleID),
	case NewTodayBuyTimes > BuyTimesLimit of
		true ->
			?THROW_ERR(?ERR_TILI_TODAY_BUY_FULL_TIMES);
		false ->
			next
	end,
	case common_bag2:t_deduct_money(MoneyType, CostMoney, RoleID, ?CONSUME_TYPE_GOLD_BUY_TILI) of
		{ok,NewRoleAttr} ->
			next;
		_Reason ->
			NewRoleAttr = null,
			?THROW_ERR(?ERR_GOLD_NOT_ENOUGH)
	end,
	{ok,NewRoleTili} = t_add_tili(buy,AddTili,LastAutoIncreaseTime,RoleTili),
	{ok,NewRoleTili,NewRoleAttr}.

%% AddType = auto | buy | free
t_add_tili(AddType,AddTili,NewLastAutoIncreaseTime,RoleID) when is_integer(RoleID) ->
	{ok,RoleTili} = get_tili_info(RoleID),
	t_add_tili(AddType,AddTili,NewLastAutoIncreaseTime,RoleTili);
t_add_tili(AddType,AddTili,NewLastAutoIncreaseTime,RoleTili) ->
	#r_role_tili{role_id=RoleID,cur_tili=CurTili,last_buy_time=LastBuyTime,today_buy_times=TodayBuyTimes}=RoleTili,
	Now = mgeem_map:get_now(),
	case AddType of
		buy ->
			NewCurTili = CurTili+AddTili,
			NewLastBuyTime = Now,
			NewTodayBuyTimes = today_buy_times(TodayBuyTimes,LastBuyTime) + 1;
		free ->
			[{_Interval,_AddTiti,TiliLimit}] = ?find_config(auto_increase_tili),
			NewCurTili = erlang:min(CurTili+AddTili, TiliLimit),
			NewLastBuyTime = LastBuyTime,
			NewTodayBuyTimes = TodayBuyTimes;
		_ ->
			[{_Interval,_AddTiti,TiliLimit}] = ?find_config(auto_increase_tili),
			NewCurTili = 
				case CurTili >= TiliLimit of
					true -> CurTili;
					false ->
						erlang:min(CurTili+AddTili,TiliLimit)
				end,
			NewLastBuyTime = LastBuyTime,
			NewTodayBuyTimes = TodayBuyTimes
	end,
	NewRoleTili = RoleTili#r_role_tili{cur_tili=NewCurTili,last_auto_increase_time=NewLastAutoIncreaseTime,
									   last_buy_time=NewLastBuyTime,today_buy_times=NewTodayBuyTimes},
	t_set_tili_info(RoleID,NewRoleTili),		
	{ok,NewRoleTili}.		


cast_role_tili_info(RoleID) when is_integer(RoleID) ->
	{ok,RoleTili} = get_tili_info(RoleID),
	cast_role_tili_info(RoleTili);
cast_role_tili_info(RoleTili) when is_record(RoleTili, r_role_tili)->
	PTiliInfo = p_tili_info(RoleTili),
	R = #m_role2_tili_info_toc{p_tili=PTiliInfo},
	common_misc:unicast({role,RoleTili#r_role_tili.role_id},?DEFAULT_UNIQUE,?ROLE2,?ROLE2_TILI_INFO,R).

t_set_tili_info(RoleID, TiliInfo) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,RoleExtInfo} ->
			NewRoleExtInfo = RoleExtInfo#r_role_map_ext{role_tili=TiliInfo},
			mod_map_role:t_set_role_map_ext_info(RoleID, NewRoleExtInfo),
			ok;
		Reason ->
			?ERROR_MSG("t_set_tili_info error,RoleID=~w,TiliInfo=~w,Reason=~w",[RoleID,TiliInfo,Reason]),
			?THROW_SYS_ERR()
	end.

get_tili_info(RoleID) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{role_tili=TiliInfo}} ->
			{ok, TiliInfo};
		_ ->
			{error, not_found}
	end.

%% 今天购买的次数
today_buy_times(TodayBuyTimes,LastBuyTime) ->
	case common_time:is_today(LastBuyTime) of
		true ->
			TodayBuyTimes;
		false ->
			0
	end.

%% 购买消耗
buy_tili_cost(TodayBuyTimes,CostMoneyConf) ->
	case lists:keyfind(TodayBuyTimes,1,CostMoneyConf) of
		false ->
			{_,CostMoney} = lists:last(CostMoneyConf),
			CostMoney;
		{_,CostMoney} ->
			CostMoney
	end.

%% 最大购买次数
buy_times_limit(RoleID) ->
	[BuyTimesLimitConf] = ?find_config(buy_tili_times_limit),
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	{_,BuyTimesLimit} = lists:keyfind(VipLevel,1,BuyTimesLimitConf),
	BuyTimesLimit.
