%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test_mgeew_pay_server
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_mgeew_pay_server).

%%
%% Include files
%%
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
t_pay()->
    AccountName = "aison01",
    OrderID = common_tool:to_list( common_tool:now2() ),
    
    PayMoney = 10,
    PayGold = 100,
    PayTime = common_tool:now(),
    Year = 2010,
    Month = 11,
    Day = 15,
    Hour =21,
    
    case global:whereis_name(mgeew_pay_server) of
        undefined ->
            ?INFO("~ts", ["充值进程没有启动，world可能down了"]);
        PID ->
            gen_server:call(PID, {pay, OrderID, AccountName, PayTime, PayGold, PayMoney, {Year, Month, Day, Hour}})
    end.
    