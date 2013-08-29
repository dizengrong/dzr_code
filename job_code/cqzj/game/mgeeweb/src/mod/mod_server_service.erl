%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 19 Dec 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_server_service).

%% API
-export([get/3]).

-include("mgeeweb.hrl").

%% 提供给PHP的用于测试mochiweb服务是否正常
get("/is_ok/", Req, _) ->
    mgeeweb_tool:return_json_ok(Req);
get("/get_key" ++ _, Req, _) ->
    get_key(Req);
get("/get_80_line", Req, _) ->
    case catch gen_server:call({global, mgeel_line}, get_80_line) of
        {ok, Result} ->
            case Result of
                [] ->
                    mgeeweb_tool:return_json_error(Req);
                {IP, Port} ->
                    Result2 = [{result, ok}, {ip, IP}, {port, Port}],
                    mgeeweb_tool:return_json(Result2, Req)
            end;
        Error ->
            ?ERROR_MSG("~ts:~p", ["获取一条80端口的分线出错", Error]),
            mgeeweb_tool:return_json_error(Req)
    end;
get(_, Req, _) ->
    Req:not_found().


%% 获取key，用于分线重连
get_key(Req) ->
    Get = Req:parse_qs(),
    AccountName = common_tool:to_binary(proplists:get_value("account", Get)),
    RoleID = common_tool:to_integer(proplists:get_value("role_id", Get)),
    [{_Now, Key}, {_Now2, Key2}] = gen_server:call({global, mgeel_key_server}, {gen_key, AccountName, RoleID}),
    mgeeweb_tool:return_json([{result, ok}, {line_key, Key}, {chat_key, Key2}], Req).
    


