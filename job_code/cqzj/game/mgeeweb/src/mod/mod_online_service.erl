-module(mod_online_service).
-include("mgeeweb.hrl").
-compile([export_all]).

%%后台所有使用的都是AccountName与AccountId,没有使用Role
get(Req)->
    Qs = Req:parse_qs(),
    Method = got(method,Qs),
    case Method of 
	view_all_online ->
	    Result = return_online_ids();
	kick ->
	    Result = kick_user(Qs);
	_ ->
	    Result = "{'status':'Unknow Command'}"
    end,
    Req:ok({"text/html; charset=utf-8", [{"Server","Mochiweb-Test"}],Result}).
       
	
kick_user(Qs)->
    Uid = got(roleid,Qs),
    ?DEBUG("kick_user: ~w",[Uid]),
    UserThread = get_process_by_rid(Uid),
    ?DEBUG("role_line_process_name ~w ",[UserThread]),
    DistProcess  = (catch global:send(UserThread,{kick_by_admin})),
    ?DEBUG("踢人结果kick :~w",[DistProcess]),
    "{\"result\":\"ok\"}".

%% not available
return_online_ids()->    
    "[1,2,3,5]".
        

get_process_by_rid(Roleid)->
    common_misc:get_role_line_process_name(Roleid).



got(Index,PropList)->
    if is_atom(Index) ->
	    IndexStr = atom_to_list(Index),
	    common_tool:to_atom(proplists:get_value(IndexStr,PropList));
       true -> 
	    proplists:get_value(Index,PropList)
    end.

