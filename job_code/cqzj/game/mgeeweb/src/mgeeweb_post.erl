%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 22 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeeweb_post).

-include("mgeeweb.hrl").

%% API
-export([handle/3]).

handle(Path, Req, DocRoot) ->
    post(Path, Req, DocRoot).



post("GmReply",Req,_DocRoot)->
	QueryString = Req:parse_post(),
	ReplyId2 = get_int_param("reply_id",QueryString),
	ReplyId = common_tool:to_integer(ReplyId2),
	RoleId2 = get_int_param("role_id",QueryString),
	RoleId  = common_tool:to_integer(RoleId2), 	
	Content = proplists:get_value("content", QueryString),
	Content1 = base64:decode_to_string(Content),
	Content2 = base64:decode_to_string(Content1),
	
    mod_gm_service:reply_letter(ReplyId,RoleId,Content2),
	mgeeweb_tool:return_json_ok(Req);

post("email/send_email",Req,_DocRoot)->
    mod_email_service:post("/send_email",Req,_DocRoot);

%%批量发信或道具
post("email/send_email_batch",Req,_DocRoot)->
    mod_email_service:post("/send_email_batch",Req,_DocRoot);

post("send_goods",Req,_DocRoot)->
    mod_goods_service:post("/send_goods/",Req,_DocRoot);

%%批量发信或道具
post("send_goods_batch",Req,_DocRoot)->
    mod_goods_service:post("/send_goods_batch/",Req,_DocRoot);

post("send_goods_batch_by_condition",Req,_DocRoot)->
    mod_goods_service:post("/send_goods_batch_by_condition/",Req,_DocRoot);

post("ban/ban_chat",Req,_DocRoot)->
    mod_ban_service:post(ban_chat,Req);

post("gen_map_goway",Req,_DocRoot)->
    mod_system_service:post(gen_map_goway,Req);

post("gamer_title/add_title",Req,_DocRoot)->
    mod_title_service:set_role_manual_title(Req);

post("gamer_title/remove_title",Req,_DocRoot)->
    mod_title_service:remove_role_manual_title(Req);

post("broadcast/copy",Req,_DocRoot)->
    mod_broadcast_service:handle("/copy",Req,_DocRoot);

post(_, Req, _DocRoot) ->
    Req:not_found().

get_int_param(Key,QueryString)->
    Val = proplists:get_value(Key,QueryString),
    common_tool:to_integer(Val).

