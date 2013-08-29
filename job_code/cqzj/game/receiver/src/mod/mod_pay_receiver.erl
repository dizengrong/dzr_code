%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     在Reeiver模块中记录中央后台的充值记录
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mod_pay_receiver).


%% API
-export([write_pay_log/3]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeerec.hrl").


%% ====================================================================
%% API Functions
%% ====================================================================
write_pay_log(AgentID, GameID, Record)->
     #b_pay_log_tos{role_id= RoleID,role_name= RoleName,account_name=AccountName, order_id=OrderId, pay_money=PayMoney, pay_gold=PayGold,give_gold=GiveGold, pay_time=PayTime,
                               pay_date_time= PayDateTime, year=Year, month=Month, day=Day, hour=Hour, role_level=Level, online_day=OnlineDay} = Record,
    SQL = mod_mysql:get_esql_insert(t_log_pay,
                                    [agent_id,server_id,order_id,role_id,role_name,account_name,pay_money,pay_gold,
                                     give_gold,role_level,pay_time,pay_date_time,year,month,day,hour,online_day],
                                    [AgentID,GameID, OrderId,RoleID,RoleName,AccountName, PayMoney*100, PayGold,
                                     GiveGold,Level,PayTime,PayDateTime,Year,Month,Day,Hour,OnlineDay]
                                   ), 
    {ok,_} = mod_mysql:insert(SQL).



