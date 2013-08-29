%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 28 Feb 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_setting_service).

-include("mgeeweb.hrl").

%% API
-export([
         get/3
        ]).

get("/system_notice" ++ _, Req, _) ->
    do_set_system_notice(Req);
get(_, Req, _) ->
    Req:not_found().

%% 设置系统公告
do_set_system_notice(Req) ->
    case common_shell:update_system_notice() of
        ok->
            mgeeweb_tool:return_json_ok(Req);
        Err->
            ?DBG(Err),
            mgeeweb_tool:return_json_error(Req)
    end.
            

