-module(mod_pay_first_service).

-export([get/3]).

-include("mgeeweb.hrl").

get("/get_flag/", Req, _) ->
    Flag = common_config:is_activity_pay_first_open(),
    Result = [{result, ok}, {flag, Flag}],
    mgeeweb_tool:return_json(Result, Req);
get("/close/", Req, _) ->
    case common_config:set_activity_pay_first_flag(false)  of
        {atomic, ok} ->
            mgeeweb_tool:return_json_ok(Req);
        {aborted, Error} ->
            ?ERROR_MSG("~ts:~w", ["关闭首充活动出错", Error]),
            mgeeweb_tool:return_json_error(Req)
    end;
get("/open/", Req, _) ->
    ?ERROR_MSG("~p", [Req]),
    case common_config:set_activity_pay_first_flag(true)  of
        {atomic, ok} ->
            mgeeweb_tool:return_json_ok(Req);
        {aborted, Error} ->
            ?ERROR_MSG("~ts:~w", ["开启首充活动出错", Error]),
            mgeeweb_tool:return_json_error(Req)
    end;
get(_, Req, _) ->
    Req:not_found().

            
