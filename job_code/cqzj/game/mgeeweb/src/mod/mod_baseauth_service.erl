%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 21 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_baseauth_service).

%% API
-export([
         cookie/1,
         ticket/1,
         do/1
        ]).


%% 进行认证
do(Req) ->
    Post = Req:parse_post(),
    UserName = proplists:get_value("username", Post),
    Password = proplists:get_value("password", Post),
    case UserName =:= "admin" andalso Password =:= "admin" of
        true ->            
            {1, get_ticket(1)};
        false ->
            false
    end.
    

%%cookie方式认证
cookie(Req) ->
    UID = Req:get_cookie_value("uid"),
    Ticket = Req:get_cookie_value("ticket"),
    check_ticket(UID, Ticket).


%% ticket认证
ticket(Req) ->
    Query = Req:parse_qs(),
    UID = proplists:get_value("uid", Query),
    Ticket = proplists:get_value("ticket", Query),
    check_ticket(UID, Ticket).


%%验证ticket
check_ticket(UID, Ticket) ->
    MD5 = get_ticket(UID),
    MD5 =:= string:to_upper(common_tool:to_list(Ticket)).


get_ticket(UID) ->
    string:to_upper(common_tool:md5(lists:concat([UID, "thisisamd5key!"]))).
