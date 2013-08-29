%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     对mnesia和mysql进行简单压力测试
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------

-module(test_common_behavior).

%%
%% Include files
%%
 
 
-define( INFO(F,D),io:format(F, D) ).
-compile(export_all).
-include("common.hrl").

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%


test_send_account()->
	AccountName = <<"aison01">>,
	common_behavior:send({account_init, AccountName}).


test_send_consume_gold()->
	RoleName = "aison01",
	AccountName = "aison01",
	Level = 2,
	ConsumeLog = #r_consume_log{ role_id=1, use_bind=10,use_unbind=0, 
					mtime=common_tool:now(), mtype=1001, mdetail="wuzesen test", item_id=0, item_amount=0} ,
	common_behavior:send({consume_gold, RoleName,AccountName,Level,ConsumeLog}).


test_send_pay_log(IsFirst)->
    AccountName = "aison01",
    OrderID = common_tool:to_list( common_tool:now2() ),
    
    Level = 4,
    PayMoney = 10,
    PayGold = 100,
    PayTime = common_tool:now(),
    Year = 2010,
    Month = 11,
    Day = 15,
    Hour =21,
    
    common_behavior:send({pay_log, {AccountName,OrderID,PayMoney,PayGold,PayTime,Year, Month, Day, Hour,Level,IsFirst} }).



