-module(mod_ban_service).
-include("mgeeweb.hrl").
-compile([export_all]).


get(Req)->
    Qs = Req:parse_qs(),
    Obj = got(obj,Qs),
    Method = got(method,Qs),
    %% Id = hit(id,Qs),
    case Obj of 
	user ->
	    handle_user(Method,Req);
	ip ->
	    handle_ip(Method,Req)
    end.

post(ban_chat,Req)->
    QueryString = Req:parse_post(),
    Method = get_param("method",QueryString),
    handle_chat(Method,Req,QueryString).

%%@doc 禁言
handle_chat(Method,Req,QueryString)->
    ?DEBUG("handle_chat,Method=~p",[Method]),
    case Method of 
        "list" ->
            handle_chat_list(Req,QueryString);
        "ban"->
            handle_chat_ban(Req,QueryString);
        "unban"->
            handle_chat_unban(Req,QueryString)
    end.
    

%%@doc 封禁账户
handle_user(Method,Req)->
    case Method of 
	view ->
	    handle_user_view(Req);
	update->
	    handle_user_update(Req);
	del->
	    handle_user_del(Req)
    end.


%%@doc 封禁IP
handle_ip(Method,Req)->
    case Method of 
	view ->
	    handle_ip_view(Req);
	update->
	    handle_ip_update(Req);
	del->
	    handle_ip_del(Req)
    end.


%% ====================================================================
%% Local Functions
%% ====================================================================

handle_chat_list(Req,_QueryString)->
    List = mod_chat_ban:list_user(),
    case List of
        []-> 
            mgeeweb_tool:return_json([],Req);
        _ -> 
            JSonList = [ mgeeweb_tool:transfer_to_json(Rec) ||Rec<-List ],
            ?DEBUG("JSonList=~p",[JSonList]),
            mgeeweb_tool:return_json(JSonList,Req)
    end.

handle_chat_ban(Req,QueryString)->
    RoleName = get_param("rolename",QueryString),
    RoleId = get_param_int("roleid",QueryString),
    Duration = get_param_int("duration",QueryString),
    Reason = get_param("reason",QueryString),
    ?DEBUG("{RoleId,RoleName,Duration,Reason}=~p",[{RoleId,RoleName,Duration,Reason}]),
    mod_chat_ban:ban_by_gm(RoleId,RoleName,Duration,Reason),
    mgeeweb_tool:return_json_ok(Req).

handle_chat_unban(Req,QueryString)->
    RoleId = get_param_int("roleid",QueryString),
    mod_chat_ban:unban(RoleId),
    mgeeweb_tool:return_json_ok(Req).

%% currently only return all datas to the front
handle_user_view(Req)->
    Pattern = #r_ban_user{
      _='_'
     },
    List = db:dirty_match_object(?DB_BAN_USER,Pattern),
    RecList = [ [{rolename,Ele#r_ban_user.rolename},{deadline,Ele#r_ban_user.deadline},{adminid,Ele#r_ban_user.adminid}] ||Ele <- List ],
    Result = common_json2:to_json(RecList),
    mgeeweb_tool:return_string(Result,Req).
    
handle_user_update(Req)->
    Qs = Req:parse_qs(),
    Instant = #r_ban_user{
      rolename = got("rolename",Qs),
      deadline = got("deadline",Qs),
      adminid = got("adminid",Qs)
     },
    db:dirty_write(?DB_BAN_USER,Instant),
    String = "{\"result\":\"ok\"}",
    mgeeweb_tool:return_string(String,Req).

handle_user_del(Req)->
    Qs = Req:parse_qs(),
    Rolename = got("rolename",Qs),


    ?DEBUG("all_keys :~w",[proplists:get_keys(Qs)]),
    ?DEBUG("rolename:~w",[Rolename]),
    Result = db:dirty_delete(?DB_BAN_USER,Rolename),
    String = "{\"result\":\""++common_tool:to_list(Result)++"\"}",
    mgeeweb_tool:return_string(String,Req).



%% ip
handle_ip_view(Req)->
    Pattern = #r_ban_ip{
      _ = '_'
     },
    ResultLists = db:dirty_match_object(?DB_BAN_IP,Pattern),
    RecList =  [[{ip,Ele#r_ban_ip.ip},{deadline,Ele#r_ban_ip.deadline},{adminid,Ele#r_ban_ip.adminid}] ||Ele <- ResultLists ],
    Result = common_json2:to_json(RecList),
    mgeeweb_tool:return_string(Result,Req).

    
handle_ip_update(Req)->
    Qs = Req:parse_qs(),
    Pattern = #r_ban_ip{
      ip = got("ip",Qs),
      deadline = got("deadline",Qs),
      adminid = got("adminid",Qs)
     },
    db:dirty_write(?DB_BAN_IP,Pattern),
    String = "{\"result\":\"ok\"}",
    mgeeweb_tool:return_string(String,Req).
    
    
handle_ip_del(Req)->
    Qs = Req:parse_qs(),
    Ip  = got("ip",Qs),
    db:dirty_delete(?DB_BAN_IP,Ip),
    String  ="{\"result\":\"ok\"}",
    mgeeweb_tool:return_string(String,Req).

get_param(Param,QueryString)->
    proplists:get_value(Param,QueryString).

get_param_int(Param,QueryString)->
    common_tool:to_integer( get_param(Param,QueryString) ).

got(Index,Prop)->
    if is_atom(Index)->
	    common_tool:to_atom(proplists:get_value(atom_to_list(Index),Prop));
       true ->
	    common_tool:to_list(proplists:get_value(Index,Prop))
    end.


	     
	




    
    

    
    
    
    




