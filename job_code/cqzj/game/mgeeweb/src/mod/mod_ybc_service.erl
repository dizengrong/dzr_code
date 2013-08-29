%%%-------------------------------------------------
%%% @author <linruirong@gmail.com>   
%%% @copyright (C) 2010, gmail.com        
%%% @doc                                     
%%%     mod_ybc                 
%%% @end                                     
%%% Created : 2011-01-13                     
%%%-------------------------------------------------

-module(mod_ybc_service).

-include("mgeeweb.hrl").


%%API

-export([get/3,do_get/3]).

get(Path,Req,DocRoot)->
    try
        do_get(Path,Req,DocRoot)
    catch
        _:Reason->
            ?ERROR_MSG("do_get error,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()]),
            mgeeweb_tool:return_json_error(Req)
    end.

%%开启国运
do_get("/admin_start_faction_ybc/", Req, _DocRoot) ->
    admin_start_faction_ybc(Req);


do_get("/user_state/"++RoleIDStr,Req,_DocRoot)->
    get_user_state(RoleIDStr,Req);

do_get("/clear_state/", Req, _DocRoot) ->
    global:send(mgeem_router, {admin_msg, clear_ybc_state}),
    mgeeweb_tool:return_json_ok(Req);

do_get("/syn_ybc_pos/", Req, _DocRoot) ->
    QueryString = Req:parse_qs(),
    RoleID = mgeeweb_tool:get_int_param("role_id", QueryString),
    global:send(mgeem_router, {admin_msg, {syn_ybc_pos, RoleID}}),
    mgeeweb_tool:return_json_ok(Req);
  
do_get(Path, Req, _DocRoot) ->
    QueryString = Req:parse_qs(),
    ?DEBUG("error mod_ybc no match path=~w, QueryString=~w ",[Path,QueryString]).



get_user_state(RoleIDStr,Req)->
    RoleID = common_tool:to_integer(RoleIDStr),
    Res = db:dirty_read(db_role_state,RoleID),
    if length(Res) =:= 0 ->
	    Result = [{status,no}];
       true->
	    [R | _]  = Res,
	    Result = [
		      {status,yes},
		      {role_id,R#r_role_state.role_id},
		      {stall_auto,R#r_role_state.stall_auto},
		      {stall_self,R#r_role_state.stall_self},
		      {fight,R#r_role_state.fight},
		      {sitdown,R#r_role_state.sitdown},
		      {normal,R#r_role_state.normal},
		      {exchange,R#r_role_state.exchange},
		      {ybc,R#r_role_state.ybc},
		      {trading,R#r_role_state.trading}
		      ]
    end,
    JsonStr = common_json2:to_json(Result),
    mgeeweb_tool:return_string(JsonStr,Req).


admin_start_faction_ybc(Req)->
	QueryString = Req:parse_qs(),
	FactionId = mgeeweb_tool:get_int_param("factionId", QueryString),
    StartH = mgeeweb_tool:get_int_param("startH", QueryString),
    StartM = mgeeweb_tool:get_int_param("startM", QueryString),
    
	MapId = 10260, 
	MapName = common_misc:get_common_map_name(MapId),
	case global:whereis_name(MapName) of 
		undefind ->
			ignore;
		_ ->
			global:send(MapName,{mod_ybc_person,{admin_start_faction_ybc,FactionId,StartH,StartM}}),
			mgeeweb_tool:return_json_ok(Req)
	end.
                     
                 
