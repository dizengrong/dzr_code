%%% @author fsk 
%%% @doc
%%%     装备续期
%%% @end
%%% Created : 2012-7-10
%%%-------------------------------------------------------------------
-module(mod_equip_renewal).

-include("mgeem.hrl").

-export([
			is_equip_forever/1,
			is_equip_expire/1,
			equip_renewal_conf/1,
			t_forever_equip/1,
			handle/1,
			handle/2
		]).

-define(CONFIG_NAME,equip_renewal).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

-define(ERR_RENEWAL_ITEM_NOT_IN_BAG,815001).%%背包没该道具
-define(ERR_RENEWAL_NOT_ENOUGH_GOLD,815002).%%元宝不足
-define(ERR_RENEWAL_NOT_NEED_RENEWAL,815003).%%不需要升级

-define(RENEWAL_TYPE_7,1).
-define(RENEWAL_TYPE_30,2).
-define(RENEWAL_TYPE_90,3).
-define(RENEWAL_TYPE_0,9).

handle(Msg,_State) ->
	handle(Msg).

handle({_,?EQUIP, ?EQUIP_RENEWAL, _,_,_}=Info) ->
	equip_renewal(Info);
handle(Info) ->
	?ERROR_MSG("receive unknown message,Info=~w",[Info]),
	ignore.

equip_renewal({Unique, Module, Method, DataIn, RoleID, PID}) ->
	#m_equip_renewal_tos{equipid=EquipID,renewal_type=RenewalType} = DataIn,
	case catch check_equip_renewal(RoleID,EquipID,RenewalType) of
		{error,ErrCode,Reason} ->
			?UNICAST_TOC(#m_equip_renewal_toc{err_code=ErrCode,reason=Reason});
		{ok,EquipInfo,MoneyType,CostMoney} ->
			TransFun = fun()-> 
							   t_equip_renewal(RoleID,EquipInfo,MoneyType,CostMoney,RenewalType)
					   end,
			case common_transaction:t( TransFun ) of
				{atomic, {ok,NewEquipInfo,NewCostMoney,UpdateList,DeleteList,VoucherNum,VoucherTypeID,RoleAttr}} ->
					common_misc:del_goods_notify(PID,DeleteList),
					common_misc:update_goods_notify(PID,UpdateList),
					case VoucherNum > 0 of
						true ->
							?TRY_CATCH( common_item_logger:log(RoleID,VoucherTypeID,VoucherNum,undefined,?LOG_ITEM_TYPE_EQUIP_RENEWAL_VOUCHER_LOST) );
						false ->
							nil
					end,
					case RoleAttr of
						null -> nil;
						_ -> 
							common_misc:send_role_gold_change(RoleID,RoleAttr)
					end,
					?UNICAST_TOC(#m_equip_renewal_toc{equip=NewEquipInfo,renewal_type=RenewalType,cost_gold=NewCostMoney,
													  voucher_typeid=VoucherTypeID,voucher_num=VoucherNum});
				{aborted, AbortErr} ->
					{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
					?UNICAST_TOC(#m_equip_renewal_toc{err_code=ErrCode,reason=Reason})
			end
	end.

t_equip_renewal(RoleID,EquipInfo,MoneyType,CostMoney,RenewalType) ->
	{NewCostMoney,UpdateList,DeleteList,VoucherNum,VoucherTypeID} = t_deduct_equip_renewal_voucher(CostMoney,RoleID),
	case NewCostMoney > 0 of
		true ->
			case common_bag2:t_deduct_money(MoneyType, NewCostMoney, RoleID, ?CONSUME_TYPE_GOLD_EQUIP_RENEWAL) of
				{ok,RoleAttr} ->
					next;
				{error, Reason} ->
					RoleAttr = null,
					?THROW_ERR( ?ERR_OTHER_ERR, Reason )
			end;
		false ->
			RoleAttr = null
	end,
	Now = common_tool:now(),
	#p_goods{end_time=EndTime} = EquipInfo,
	case RenewalType of
		?RENEWAL_TYPE_7 ->
			NewStartTime = Now,
			NewEndTime = erlang:max(Now,EndTime) + 7*24*3600;
		?RENEWAL_TYPE_30 ->
			NewStartTime = Now,
			NewEndTime = erlang:max(Now,EndTime) + 30*24*3600;
		?RENEWAL_TYPE_90 ->
			NewStartTime = Now,
			NewEndTime = erlang:max(Now,EndTime) + 90*24*3600;
		?RENEWAL_TYPE_0 ->
			NewStartTime = NewEndTime = 0
	end,
	NewEquipInfo = EquipInfo#p_goods{start_time=NewStartTime,end_time=NewEndTime},
	mod_bag:update_goods(RoleID,NewEquipInfo),
	{ok,NewEquipInfo,NewCostMoney,UpdateList,DeleteList,VoucherNum,VoucherTypeID,RoleAttr}.

%%扣除抵用元宝卷
%% {返回还需要扣除的元宝,UpdateList,DeleteList}
t_deduct_equip_renewal_voucher(CostMoney,RoleID) ->
	[{TypeID,Price}] = ?find_config(equip_renewal_voucher),
	case mod_bag:check_inbag_by_typeid(RoleID,TypeID) of
		{ok,FoundGoodsList} ->
			BagNum = mod_bigpve_fb:get_material_num_in_bag(FoundGoodsList),
			NeedNum = CostMoney div Price,
			DeductNum = erlang:min(NeedNum,BagNum),
			{ok,UpdateList,DeleteList} = mod_bag:decrease_goods_by_typeid(RoleID,TypeID,DeductNum),
			{CostMoney - (DeductNum * Price),UpdateList,DeleteList,DeductNum,TypeID};
		_  ->
			{CostMoney,[],[],0,TypeID}
	end.

check_equip_renewal(RoleID,EquipID,RenewalType) ->
	case mod_bag:check_inbag(RoleID,EquipID) of
		{ok,EquipInfo} ->
			next;
		_ ->
			EquipInfo = null,
			?THROW_ERR(?ERR_RENEWAL_ITEM_NOT_IN_BAG)
	end,
	%%是否需要续期
	case is_equip_forever(EquipInfo) of
		true ->
			?THROW_ERR(?ERR_RENEWAL_NOT_NEED_RENEWAL);
		false ->
			next
	end,
	#p_goods{typeid=TypeID} = EquipInfo,
	{ok,{_,RenewalTypeList,_,_}} = equip_renewal_conf(TypeID),
	case lists:keyfind(RenewalType, 1, RenewalTypeList) of
		false ->
			MoneyType = CostMoney = null,
			?THROW_CONFIG_ERR();
		{_,{MoneyType,CostMoney}} ->
			next
	end,
	{ok,EquipInfo,MoneyType,CostMoney}.

equip_renewal_conf(TypeID) ->
	[EquipRenewalConfList] = ?find_config(equip_renewal),
	case lists:keyfind(TypeID, 1, EquipRenewalConfList) of
		false -> 
			EquipRenewalConf = null,
			?THROW_CONFIG_ERR();
		EquipRenewalConf -> 
			next
	end,
	{ok,EquipRenewalConf}.

%%解析错误码
parse_aborted_err(AbortErr)->
	case AbortErr of
		{error,ErrCode,_Reason} when is_integer(ErrCode) ->
			AbortErr;
		{bag_error,{not_enough_pos,_BagID}}->
			{error,?ERR_OTHER_ERR,undefined};
		{bag_error,num_not_enough}->
			{error,?ERR_OTHER_ERR,undefined};
		{error,AbortReason} when is_binary(AbortReason) ->
			{error,?ERR_OTHER_ERR,AbortReason};
		AbortReason when is_binary(AbortReason) ->
			{error,?ERR_OTHER_ERR,AbortReason};
		_ ->
			?ERROR_MSG("aborted,AbortErr=~w,stack=~w",[AbortErr,erlang:get_stacktrace()]),
			{error,?ERR_SYS_ERR,undefined}
	end.

%% 装备是否永久
is_equip_forever(EquipInfo) ->
	#p_goods{start_time=StartTime,end_time=EndTime} = EquipInfo,
	StartTime =:= 0 andalso EndTime =:= 0.
%% 装备是否过期
is_equip_expire(EquipInfo) ->
	#p_goods{end_time=EndTime} = EquipInfo,
	EndTime < common_tool:now().

%% 永久化装备
t_forever_equip(EquipInfo) ->
	case is_equip_forever(EquipInfo) of
		true -> EquipInfo;
		false ->
			#p_goods{typeid=TypeID,start_time=StartTime,reinforce_result=ReinforceResult} = EquipInfo,
			case catch equip_renewal_conf(TypeID) of
				{ok,{_,_,HourConf,ReinforceResultConf}} ->
					Now = common_tool:now(),
					case Now-StartTime =< HourConf*3600 andalso ReinforceResult >= ReinforceResultConf of
						true ->
							EquipInfo#p_goods{start_time=0,end_time=0};
						false -> EquipInfo
					end;
				_ -> EquipInfo
			end
	end.
	
