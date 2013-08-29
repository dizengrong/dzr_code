%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%% Created : 22 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_office_service).

%% API
-export([get/3]).

-include("mgeeweb.hrl").

get("/set_king/", Req, _DocRoot) ->
    do_set_king(Req);
get("/set_faction_silver/", Req, _DocRoot) ->
    do_set_faction_silver(Req);
get(_, Req, _DocRoot) ->
    Req:not_found().


%% 访问形式: /event/office/set_king/?role_id
do_set_king(Req) ->
    case global:whereis_name(mgeew_office) of
        undefined ->
            mgeeweb_tool:process_not_run(Req);
        PID ->
            Get = Req:parse_qs(),
            RoleName = proplists:get_value("role_name", Get),
            case gen_server:call(PID, {set_king, common_tool:to_list(RoleName)}) of
                ok ->
                    mgeeweb_tool:return_json_ok(Req);
                Error ->
                    ?ERROR_MSG("~p", [Error]),
                    mgeeweb_tool:return_json_error(Req)
            end
    end.


do_set_faction_silver(Req) ->
    case global:whereis_name(mgeew_office) of
        undefined ->
            mgeeweb_tool:process_not_run(Req);
        PID ->
            Get = Req:parse_qs(),
            FactionID = common_tool:to_integer( proplists:get_value("faction_id", Get)),
            Silver = common_tool:to_integer( proplists:get_value("silver", Get)),
            case gen_server:call(PID, {set_faction_silver, FactionID, Silver}) of
                ok ->
                    mgeeweb_tool:return_json_ok(Req);
                Error ->
                    ?ERROR_MSG("~p", [Error]),
                    mgeeweb_tool:return_json_error(Req)
            end
    end.
