-module(common_behavior).

-include("define.hrl").
-include("common_server.hrl").
-include("log_consume_type.hrl").


-compile(export_all).
-export([send/1]).



send({account_login, _AccountName, _IPTuple}) ->
    ignore;
send({account_init, _AccountName}) ->
    ignore;
send({account_logout, _AccountName, _LoginTime, _IfEnterGame}) ->
    ignore;
send({role_level, _RoleID, _RoleLevel}) ->
    ignore;
send({role_login, _RoleID, _AccountName, _IPTuple}) ->
    ignore;
send({role_logout, _RoleID, _AccountName, _LoginTime}) ->
    ignore;
send({role_new, _AccountName, _PRole}) ->
    ignore;



send({consume_gold, _RoleName,_AccountName,_Level,_ConsumeLog}) ->
    ignore;
send({pay_log, {_AccountName,_RoleID,_RoleName,_OrderId,_PayMoney,_PayGold,_PayTime,_Year,_Month,_Day,_Hour,_Level,_PayDateTime,_OnlineDay} }) ->
    ignore;
send(Other) ->
    ?ERROR_MSG("~ts:~w", ["发送行为日志有错误", Other]).



%%--------------------------------------------------------------------------------------------------
%%向行为日志发送日志数据
%%Module Method DataRecord 请自行在 common.doc/trunk/proto/behavior/behavior.proto定义
behavior_log(Module, Method, DataRecord) ->
    %%检查行为日志缓存进程是否启动了
    case global:whereis_name(behavior_cache_server) of
        undefined ->
            %%根据是否开启behavior来决定日志的类型
            ?ERROR_MSG("~ts", ["行为日志缓存服务没有启动:behavior_cache_server"]);
        PID ->
           PID ! {behavior, {Module, Method, DataRecord}}
    end.


