%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 11 Mar 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_test_service).

-include("mgeeweb.hrl").

%% API
-export([get/3]).

get("/accumulate_exp" ++ _, Req, _) ->
    do_accumulate_exp(Req);
get("/goal" ++ _, Req, _) ->
    do_goal(Req);
get(_, Req, _) ->
    Req:not_found().

do_goal(Req) ->
    Get = Req:parse_qs(),
    AccountName = common_tool:to_binary(proplists:get_value("account", Get)),
    Days = common_tool:to_integer(proplists:get_value("days", Get)),
    case db:dirty_match_object(?DB_ROLE_BASE, #p_role_base{account_name=AccountName, _='_'}) of
        [] ->
            mgeeweb_tool:return_json_error(Req);
        [#p_role_base{role_name=RoleName}] ->
            RoleID = common_misc:get_roleid(RoleName),
            mgeer_role:absend(RoleID, {mod_goal, {set_role_days, RoleID, Days}}),
            mgeeweb_tool:return_json_ok(Req)
    end.


do_accumulate_exp(Req) ->
    Get = Req:parse_qs(),
    AccountName = common_tool:to_binary(proplists:get_value("account", Get)),
    ID = common_tool:to_integer(proplists:get_value("id", Get)),
    Days = common_tool:to_integer(proplists:get_value("days", Get)),
    Year = common_tool:to_integer(proplists:get_value("year", Get)),
    Month = common_tool:to_integer(proplists:get_value("month", Get)),
    Day = common_tool:to_integer(proplists:get_value("day", Get)),
    case db:dirty_match_object(?DB_ROLE_BASE, #p_role_base{account_name=AccountName, _='_'}) of
        [] ->
            mgeeweb_tool:return_json_error(Req);
        [#p_role_base{role_name=RoleName}] ->
            RoleID = common_misc:get_roleid(RoleName),
            mgeer_role:absend(RoleID, {mod_accumulate_exp, {set_role_acc, RoleID, ID, Days, {Year, Month, Day}}}),
            mgeeweb_tool:return_json_ok(Req)
    end.

