%%%-------------------------------------------------------------------
%%% @author liuwei <>
%%% @copyright (C) 2011, liuwei
%%% @doc
%%% Created : 9 May 2011 by liuwei <>
%%%-------------------------------------------------------------------
-module(mod_family_collect_service).

%% API
-export([get/3]).

-include("mgeeweb.hrl").

get("/open_family_collect/", Req, _DocRoot) ->
    do_open_family_collect(Req);
get("/end_family_collect/", Req, _DocRoot) ->
    do_end_family_collect(Req);
get(_, Req, _DocRoot) ->
    Req:not_found().


%% 访问形式: /event/family_collect/open_family_collect/?family_id
do_open_family_collect(Req) ->
     Get = Req:parse_qs(),
    FamilyID = common_tool:to_integer( proplists:get_value("family_id", Get)),
    case FamilyID of
        0 ->
            mgeeweb_tool:return_json_ok(Req);
        _ ->
            Name = lists:concat(["map_family_", FamilyID]),
            catch global:send(Name, {mod_family_collect,family_collect_begin}),
            mgeeweb_tool:return_json_ok(Req)
    end.


%% 访问形式: /event/family_collect/end_family_collect/?family_id
do_end_family_collect(Req) ->
    Get = Req:parse_qs(),
    FamilyID = common_tool:to_integer( proplists:get_value("family_id", Get)),
    case FamilyID of
        0 ->
            mgeeweb_tool:return_json_ok(Req);
        _ ->
            Name = lists:concat(["map_family_", FamilyID]),
            catch global:send(Name, {mod_family_collect,family_collect_end}),
            mgeeweb_tool:return_json_ok(Req)
    end.
    
