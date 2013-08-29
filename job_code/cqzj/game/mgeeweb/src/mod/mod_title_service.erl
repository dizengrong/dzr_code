%%%-------------------------------------------------------------------
%%% @author linruirong <linruirong@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     GM的相关逻辑处理
%%% @end
%%% Created : 2010-12-25
%%%-------------------------------------------------------------------
-module(mod_title_service).


%% --------------------------------------------------------------------
%% include_once files
%% --------------------------------------------------------------------
-include("mgeeweb.hrl").



%%
%% Exported Functions
%%
-export([set_role_manual_title/1,remove_role_manual_title/1]).


%% ====================================================================
%% API Functions
%% ====================================================================

%% handle(create_gm_role,QueryString)->
%%     AccountName = proplists:get_value("accname", QueryString),
%%     RoleName = proplists:get_value("rolename", QueryString),
%%     FactionID = mgeeweb_tool:get_int_param("faction", QueryString),
%%     Sex = mgeeweb_tool:get_int_param("sex", QueryString),
%%     create_gm_role(AccountName,RoleName,FactionID,Sex).

%%@doc 给玩家设置自定义称号
set_role_manual_title(Req)->
	QueryString = Req:parse_post(),
	RoleID = mgeeweb_tool:get_int_param("role_id", QueryString),
	TitleName =  proplists:get_value("title", QueryString),
	TitleColor =  proplists:get_value("color", QueryString),
	ShowChat = mgeeweb_tool:get_atom_param("show_in_chat", QueryString),
	ShowSence = mgeeweb_tool:get_atom_param("show_in_sence", QueryString),
	AutoTimeOut = mgeeweb_tool:get_atom_param("auto_timeout", QueryString),
	Time = mgeeweb_tool:get_int_param("timeout_time", QueryString),

	TitleData = {RoleID,TitleName,TitleColor,ShowChat,ShowSence,AutoTimeOut,Time},
	?DEBUG("TitleData=~w",[TitleData]),
    case gen_server:call({global, mgeew_admin_server}, {admin_title,{add_manual_title,TitleData}}) of
        ok ->
            mgeeweb_tool:return_json_ok(Req);
        {error, _Reason} ->
            mgeeweb_tool:return_json_error(Req)
    end.

%%@doc 删除玩家自定义称号
remove_role_manual_title(Req)->
	QueryString = Req:parse_post(),
	RoleID = mgeeweb_tool:get_int_param("role_id", QueryString),
	TitleID = mgeeweb_tool:get_int_param("title_id", QueryString),
	?DEBUG("QueryString=~w, RoleID=~w, TitleID=~w",[QueryString,RoleID,TitleID]),
	case gen_server:call({global, mgeew_admin_server}, {admin_title,{remove_manual_title,TitleID,RoleID}}) of
        ok ->
            mgeeweb_tool:return_json_ok(Req);
        {error, _Reason} ->
            mgeeweb_tool:return_json_error(Req)
    end.


