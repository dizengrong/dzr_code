%%%-------------------------------------------------------------------
%%% @author LinRuirong <linruirong@gmail.com>
%%% @copyright (C) 2010, Mingchao
%%% @doc
%%%		玩家称号管理（用于游戏后台）
%%% @end
%%% Created :2010-12-27
%%%-------------------------------------------------------------------
-module(admin_title).

-include("mgeew.hrl").

%% API
-export([
         handle_call/1
        ]).


handle_call(Info) ->
    do_handle_call(Info).

%%处理给玩家加自定义称号
do_handle_call({add_manual_title,TitleData}) ->
	{RoleID,TitleName,TitleColor,ShowChat,ShowSence,AutoTimeOut,Time} = TitleData,
	Type = ?TITLE_MANUAL,
	?DEBUG("Type=~w ,RoleID=~w ,TitleData=~w,",[Type,RoleID,TitleData]),
    common_title_srv:add_title(Type,RoleID,{Type,TitleName,TitleColor,ShowChat,ShowSence,AutoTimeOut,Time});

%%处理删除玩自定义称号
do_handle_call({remove_manual_title,TitleID,RoleID}) ->
	?DEBUG("TitleID=~w ,RoleID=~w",[TitleID,RoleID]),
    common_title_srv:remove_by_titleid(TitleID,RoleID);

do_handle_call(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知消息", Info]).


