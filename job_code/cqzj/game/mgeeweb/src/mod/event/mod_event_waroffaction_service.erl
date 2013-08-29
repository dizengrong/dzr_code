
-module(mod_event_waroffaction_service).

%% API
-export([get/3]).

-include("mgeeweb.hrl").

get("/get_info", Req, _DocRoot) ->
    do_get_info(Req);
get("/begin_apply/", Req, _) ->
    do_begin_apply(Req);
get("/begin_war/", Req, _) ->
    do_begin_war(Req),
    Req:ok();
get("/end_war/", Req, _) ->
    do_end_war(Req);
get("/reset", Req, _) ->
    do_reset(Req);
get(_, Req, _DocRoot) ->
    Req:not_found().


do_begin_apply(Req) ->
    case global:whereis_name(mgeew_event) of
        undefined ->
            Req:not_found();
        _PID ->
            Get = Req:parse_qs(),
            AttackFactionID = common_tool:to_integer( proplists:get_value("attack_faction_id", Get)),
            DefenceFactionID = common_tool:to_integer( proplists:get_value("defence_faction_id", Get)),
            global:send( mgeew_event, {mod_event_waroffaction, {begin_apply,AttackFactionID,DefenceFactionID}}),
            mgeeweb_tool:return_json_ok(Req)     
    end.


do_end_war(Req) ->
    case global:whereis_name(mgeew_event) of
        undefined ->
            Req:not_found();
        _PID ->
            Get = Req:parse_qs(),
            AttackFactionID = common_tool:to_integer( proplists:get_value("attack_faction_id", Get)),
            DefenceFactionID = common_tool:to_integer( proplists:get_value("defence_faction_id", Get)),
            global:send(mgeew_event, {mod_event_waroffaction, {end_war,AttackFactionID,DefenceFactionID}}),
            mgeeweb_tool:return_json_ok(Req)                    
    end.


do_get_info(Req) ->
    case global:whereis_name(mgeew_event) of
        undefined ->
            Req:not_found();
        _PID ->
            case gen_server:call({global, mgeew_event}, {mod_event_waroffaction, get_info}) of
                no_war ->
                    Req:not_found();
                {AttackFactionID,DefenceFactionID,Seconds} ->
                    Rtn = [{seconds, Seconds}, {attack_faction_id, AttackFactionID}, {defence_faction_id, DefenceFactionID}],
                    mgeeweb_tool:return_json(Rtn, Req)
            end
    end.


do_begin_war(Req) ->
    case global:whereis_name(mgeew_event) of
        undefined ->
            Req:not_found();
        _PID ->
            Get = Req:parse_qs(),
            AttackFactionID = common_tool:to_integer( proplists:get_value("attack_faction_id", Get)),
            DefenceFactionID = common_tool:to_integer( proplists:get_value("defence_faction_id", Get)),
            global:send(mgeew_event, {mod_event_waroffaction, {begin_war,AttackFactionID,DefenceFactionID}}),
            mgeeweb_tool:return_json_ok(Req)          
    end.

do_reset(Req) ->
    case global:whereis_name(mgeew_event) of
        undefined ->
            Req:not_found();
        _PID ->
            global:send(mgeew_event, {mod_event_waroffaction, reset}),                
            mgeeweb_tool:return_json_ok(Req)
    end.


