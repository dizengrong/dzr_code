%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 21 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeeweb_get).

-include("mgeeweb.hrl").

%% API
-export([
         handle/3
        ]).

%%处理
handle("crossdomain.xml", Req, _DocRoot) ->
	CrossdomainXML = "
<cross-domain-policy>
<allow-http-request-headers-from domain=\"*\" headers=\"*\" secure=\"true\"/>
<allow-access-from domain=\"*\"/>
</cross-domain-policy>",
	mgeeweb_tool:return_xml({auto_head, CrossdomainXML}, Req);
	
handle(Path, Req, DocRoot) ->
    ?DEBUG("~ts:~s ~p ~s", ["Web访问", Path, Req, DocRoot]),
    get(Path, Req, DocRoot).



%%实际的get处理
get(?WEB_MODULE_BASEINFO ++ _Remain, Req, _DocRoot) ->
    Rtn = mod_game_service:get_baseinfo(),
    
    mgeeweb_tool:return_json(Rtn, Req);
get(?WEB_MODULE_NODES, Req, _DocRoot) ->
    Rtn = mod_game_service:get_nodes(),
    
    mgeeweb_tool:return_json(Rtn, Req);
get(?WEB_MODULE_USER, Req, _DocRoot) ->
    mod_user_service:get(Req);
get("gm_role", Req, _DocRoot) ->
    QueryString = Req:parse_qs(),
    Rtn = mod_gm_service:handle(create_gm_role,QueryString),

    mgeeweb_tool:return_json(Rtn, Req);
get(?WEB_MODULE_SERVER, Req, _) ->
    Version = erlang:system_info(otp_release),
    
    Rtn = [{"erlang_version", common_tool:to_binary(Version)}],
    mgeeweb_tool:return_json(Rtn, Req);
get(?WEB_MODULE_EVENT ++ RemainPath, Req, DocRoot) ->
    mod_event_service:get(RemainPath, Req, DocRoot);
get(?WEB_MODULE_API ++ RemainPath, Req, DocRoot) ->
    mod_api_service:get(RemainPath, Req, DocRoot);
get(?WEB_MODULE_BROADCAST ++ RemainPath, Req, DocRoot) ->
    mod_broadcast_service:handle(RemainPath, Req, DocRoot);
get("qq"++RemainPath, Req, DocRoot) ->
	mod_qq_service:get(RemainPath, Req, DocRoot);
get("pay_first" ++ RemainPath, Req, DocRoot) ->
    mod_pay_first_service:get(RemainPath, Req, DocRoot);
get("pay" ++ RemainPath, Req, DocRoot) ->
    mod_pay_service:get(RemainPath, Req, DocRoot);
get("email" ++ RemainPath, Req, DocRoot) ->
    mod_email_service:get(RemainPath, Req, DocRoot);
get("ban"++_RemainPath,Req,_DocRoot)->
    mod_ban_service:get(Req);
get("online"++_Remain,Req,_DocRoot)->
    mod_online_service:get(Req);
get("account" ++ RemainPath, Req, DocRoot) ->
    mod_account_service:get(RemainPath, Req, DocRoot);
get("server" ++ RemainPath, Req, DocRoot) ->
    mod_server_service:get(RemainPath, Req, DocRoot);
get("login" ++ RemainPath, Req, DocRoot) ->
    mod_login_service:get(RemainPath, Req, DocRoot);

get("family" ++ RemainPath, Req, _DocRoot) ->
    mod_family_service:get(RemainPath, Req);

get("ybc" ++ RemainPath, Req, DocRoot) ->
    mod_ybc_service:get(RemainPath, Req, DocRoot);

get("guotan" ++ RemainPath, Req, DocRoot) ->
    mod_guotan_service:get(RemainPath, Req, DocRoot);

get("activity" ++ RemainPath,Req,DocRoot)->
    mod_activity_service:get(RemainPath,Req,DocRoot);


get("setting" ++ RemainPath, Req, Doc) ->
    mod_setting_service:get(RemainPath, Req, Doc);

get("role" ++ RemainPath, Req, Doc) ->
    mod_role_service:get(RemainPath, Req, Doc);

get("system" ++ RemainPath, Req, Doc) ->
    mod_system_service:get(RemainPath, Req, Doc);

get("test" ++ RemainPath, Req, Doc) ->
    mod_test_service:get(RemainPath, Req, Doc);

get("rank/" ++ RemainPath, Req, DocRoot) ->
    mod_rank_service:get(RemainPath, Req, DocRoot);

get("mount" ++ RemainPath, Req, DocRoot) ->
    mod_role_mount:get(RemainPath, Req, DocRoot);
get("fashion" ++ RemainPath, Req, DocRoot) ->
    mod_role_fashion:get(RemainPath, Req, DocRoot);
get(_, Req, _) ->
    Req:not_found().

