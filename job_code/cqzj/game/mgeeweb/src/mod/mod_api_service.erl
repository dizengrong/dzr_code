%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 28 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_api_service).

-export([get/3]).

-include("mgeeweb.hrl").


%%正常的充值接口
get("/pay/", Req, _DocRoot) ->
    do_pay(Req);
get("/give_bind_gold/", Req, _DocRoot) ->
    do_give_bind_gold(Req);
get(Path, Req, DocRoot) ->
    ?ERROR_MSG("~ts : ~w ~w", ["未知的请求", Path, DocRoot]),
    mgeeweb_tool:return_json_error(Req).


to_money(MoneyArg) when is_float(MoneyArg)->
    MoneyArg;
to_money(MoneyArg)->
    case is_list(MoneyArg) andalso string:str(MoneyArg,".")>0 of
           true->
               erlang:list_to_float(MoneyArg);
           _ ->
               common_tool:to_integer(MoneyArg)
    end.

%%正常的充值接口
do_pay(Req) ->
    Get = Req:parse_qs(),
    %%?ERROR_MSG("pay_money=~w",[proplists:get_value("pay_money", Get)]),
    
    OrderID = proplists:get_value("order_id", Get),
    AcName = proplists:get_value("ac_name", Get),
    PayGold = common_tool:to_integer(proplists:get_value("pay_gold", Get)),
    PayTime = common_tool:to_integer(proplists:get_value("pay_time", Get)),
    PayMoney = to_money(proplists:get_value("pay_money", Get)),
    Year = common_tool:to_integer(proplists:get_value("year", Get)),
    Month = common_tool:to_integer(proplists:get_value("month", Get)),
    Day = common_tool:to_integer(proplists:get_value("day", Get)),
    Hour = common_tool:to_integer(proplists:get_value("hour", Get)),
    timer:sleep(1500),
    %%?ERROR_MSG("~p", [Get]),
    case global:whereis_name(mgeew_pay_server) of
        undefined ->
            ?ERROR_MSG("~ts", ["充值进程没有启动，world可能down了"]),
            mgeeweb_tool:return_json_error(Req);
        PID ->
            case gen_server:call(PID, {pay, OrderID, AcName, PayTime, PayGold, PayMoney, {Year, Month, Day, Hour}}) of
                ok ->
                    mgeeweb_tool:return_json_ok(Req);
                error ->
                    mgeeweb_tool:return_json_error(Req);
                _R ->
                    mgeeweb_tool:return_json([{result,_R}],Req)
            end
    end.


%%活动点数换礼券的接口
do_give_bind_gold(Req) ->
    Get = Req:parse_qs(),
    
    AcName = proplists:get_value("account", Get),
    GiveID = proplists:get_value("giveID", Get),
    BindGold = common_tool:to_integer(proplists:get_value("bindGold", Get)),
    GiveTime = common_tool:to_integer(proplists:get_value("giveTime", Get)),
    ActivePoint = to_money(proplists:get_value("activePoint", Get)),
    Year = common_tool:to_integer(proplists:get_value("year", Get)),
    Month = common_tool:to_integer(proplists:get_value("month", Get)),
    Day = common_tool:to_integer(proplists:get_value("day", Get)),
    Hour = common_tool:to_integer(proplists:get_value("hour", Get)),
    timer:sleep(1500),
    %%?ERROR_MSG("~p", [Get]),
    case global:whereis_name(mgeew_pay_server) of
        undefined ->
            ?ERROR_MSG("~ts", ["充值进程没有启动，world可能down了"]),
            mgeeweb_tool:return_json_error(Req);
        PID ->
            case gen_server:call(PID, {give_bind_gold, GiveID, AcName, GiveTime, BindGold, ActivePoint, {Year, Month, Day, Hour}}) of
                ok ->
                    mgeeweb_tool:return_json_ok(Req);
                error ->
                    mgeeweb_tool:return_json_error(Req);
                _R ->
                    mgeeweb_tool:return_json([{result,_R}],Req)
            end
    end.
    

