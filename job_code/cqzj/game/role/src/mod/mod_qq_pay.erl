%% Author: fsk
%% Created: 2013-4-15
%% Description:
-module(mod_qq_pay).

%%
%% Include files
%%
-include("mgeer.hrl").
-include("activity.hrl").

%%
%% Exported Functions
%%
-export([
	pay/3
]).

%%
%% API Functions
pay(RoleAttr,PayGold,IsFirstPay) ->
	#p_role_attr{role_id=RoleID,role_name=RoleName} = RoleAttr,
	mod_vip:pay_add_jifen(RoleID,PayGold),
	pay_log(RoleAttr,PayGold,IsFirstPay),
    catch global:send(mgeew_special_activity, {2,RoleID, PayGold}),
	catch common_activity:stat_special_activity(?SPEND_SUM_PAY_KEY,{RoleID,PayGold}),
	catch common_activity:stat_special_activity(?SPEND_ONCE_PAY_KEY,{RoleID,PayGold}),
	%%mgeer_role:absend(RoleID, {mod_conlogin, {payed, RoleID}}),
%% 	mgeer_role:absend(RoleID, {mod_daily_pay, {daily_pay_notify, RoleID, _IsOnlinePay=true}}),
	send_pay_letter(RoleID,RoleName,PayGold,IsFirstPay),
	ok.
%%
%% Local Functions
%%

%% 信件
send_pay_letter(RoleID,RoleName,PayGold,IsFirstPay) ->
	{Year, Month, Day} = erlang:date(),
	Content = common_letter:create_temp(?RECHARGE_SUCCESS_LETTER, [RoleName, PayGold]),
	common_letter:sys2p(RoleID,Content,?_LANG_LEETER_PAY_SUCCESS,14),
	case IsFirstPay of
		true ->
			Text = common_letter:create_temp(?PAY_FIRST_LETTER, [RoleName, Year, Month, Day]),
			common_letter:sys2p(RoleID, Text, ?_LANG_PAY_FIRST_TITLE, 14);
		false ->
			ignore
	end.

%% 充值记录可能会不准确
pay_log(RoleAttr,PayGold,IsFirstPay) ->
	PayTime = common_tool:now(),
	PayMoney = PayGold,
	#p_role_attr{role_id=RoleID,level=RoleLevel}=RoleAttr,
	{ok, #p_role_base{role_id=RoleID,role_name=RoleName,account_name=AccountName}} = mod_map_role:get_role_base(RoleID),
	{Year,Month,Day}=erlang:date(),
	{Hour,_,_}=erlang:time(),
	OrderID = common_tool:to_integer(lists:concat([RoleID,PayTime])),
	case db:dirty_read(?DB_PAY_LOG_INDEX, 1) of
		[] ->
			ID = 1;
		[#r_pay_log_index{value=ID}] ->
			next
	end,
	NewID = ID + 1,
	PayLog=#r_pay_log{id=NewID,order_id=OrderID,role_id=RoleID,role_name=RoleName,
					  account_name=AccountName,pay_time=PayTime,pay_gold=PayGold,
					  pay_money=PayMoney,year=Year,month=Month,day=Day,hour=Hour,
					  is_first=IsFirstPay,role_level=RoleLevel},
	db:dirty_write(?DB_PAY_LOG, PayLog),
	db:dirty_write(?DB_PAY_LOG_INDEX, #r_pay_log_index{id=1, value=NewID}),
	?ERROR_MSG("玩家在线充值：RoleID=~w, PayGold=~w, Year=~w, Month=~w, Day=~w, Hour=~w",[RoleID, PayGold, Year, Month, Day, Hour]).

