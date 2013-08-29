%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 19 Dec 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_login_service).

%% API
-export([get/3]).

-include("mgeeweb.hrl").

get("/get_default_faction" ++ _, Req, _) ->
    get_default_faction(Req);
get("/get_one_line" ++ _, Req, _) ->
    get_one_line(Req);
get("/get_key" ++ _, Req, _) ->
    get_key(Req);                  
get(_, Req, _) ->
    Req:not_found().

%% 返回一个国家ID给创建角色页，当做默认的国家
get_default_faction(Req) ->
    FactionID = do_get_faction_id(),
    mgeeweb_tool:return_json([{result, FactionID}], Req).

%% 获取一条分线的信息
get_one_line(Req) ->
    %% line是个p_line_info的结构体
    Line = gen_server:call({global, mgeel_line}, get_one_line, infinity),
    #p_line_info{ip=IP, port=Port} = Line,
    mgeeweb_tool:return_json([{result, succ}, {ip, IP}, {port, Port}], Req).

%%获取一个key
get_key(Req) ->
    Get = Req:parse_qs(),
    RoleID = proplists:get_value("role_id", Get),
    AccountName = proplists:get_value("account", Get),
    case catch gen_server:call({global, mgeel_key_server}, {gen_key, common_tool:to_binary(AccountName), common_tool:to_integer(RoleID)}) of
        {'EXIT', _} ->
            mgeeweb_tool:return_json_error(Req);
        [{Now, Key}, {Now2, Key2}] ->
            mgeeweb_tool:return_json([{line_key, Key}, {line_time, Now}, {chat_key, Key2}, {chat_time, Now2}], Req);
        _ ->
            mgeeweb_tool:return_json_error(Req)
    end.
    


%%获取当前人数最少的国家
do_get_faction_id() ->
    case db:dirty_read(?DB_ROLE_FACTION, 1) of
        [] ->
            Faction1 = 0;
        [#r_role_faction{number=N1}] ->
            Faction1 = N1
    end,
    case db:dirty_read(?DB_ROLE_FACTION, 2) of
        [] ->
            Faction2 = 0;
        [#r_role_faction{number=N2}] ->
            Faction2 = N2
    end,
    case db:dirty_read(?DB_ROLE_FACTION, 3) of
        [] ->
            Faction3 = 0;
        [#r_role_faction{number=N3}] ->
            Faction3 = N3
    end,
    Min = lists:min([Faction1, Faction2, Faction3]),
    case Min of
        Faction1 ->
            1;
        Faction2 ->
            2;
        _ ->
            3
    end.

