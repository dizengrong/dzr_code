%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  2 Mar 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_system_service).

-include("mgeeweb.hrl").

%% API
-export([
         get/3,
         post/2
        ]).

get("/set_fcm" ++ _, Req, _) ->
    set_fcm(Req);
get("/get_fcm" ++ _, Req, _) ->
    get_fcm(Req);
get("/get_key" ++ _, Req, _) ->
    get_key(Req);
get("/set_guest_mode" ++ _, Req, _) ->
    set_guest_mode(Req);
get("/get_guest_mode" ++ _, Req, _) ->
    get_guest_mode(Req);
get(_, Req, _) ->
    Req:not_found().

post(gen_map_goway,Req)->
    try
        gen_map_goway(Req)
    catch
        _:Reason->
            ?ERROR_MSG("~w error,Reason=~w,stacktrace=~w",[try_do_send_goods,Reason,erlang:get_stacktrace()]),
            mgeeweb_tool:return_json_error(Req)
    end;
post(Path, Req) ->
    ?ERROR_MSG("~ts : ~w ~w", ["未知的请求", Path]),
    mgeeweb_tool:return_json_error(Req).

get_key(Req) ->
    Get = Req:parse_qs(),
    AccountName = common_tool:to_binary(proplists:get_value("account", Get)),
    RoleID = common_tool:to_integer(proplists:get_value("role_id", Get)),
    [{_, LineKey}, {_, ChatKey}] = gen_server:call({global, mgeel_key_server}, {gene_key, AccountName, RoleID}),
    mgeeweb_tool:return_json([{result, ok}, {line_key, LineKey}, {chat_key, ChatKey}], Req).


%% 设置防沉迷开关
set_fcm(Req) ->
    Get = Req:parse_qs(),
    case proplists:get_value("flag", Get) of
        "1" ->
            common_fcm:set_fcm_flag(true);
        _ ->
            common_fcm:set_fcm_flag(false)
    end,
    mgeeweb_tool:return_json_ok(Req).

%% 获取防沉迷状态
get_fcm(Req) ->
    case common_config:is_fcm_open() of
        true ->
            Result = "1";
        false ->
            Result = "0"
    end,
    mgeeweb_tool:return_json([{result, ok}, {fcm, Result}], Req).
%% 设置游客模式
set_guest_mode(Req) ->
    Get = Req:parse_qs(),
    case common_tool:to_integer(proplists:get_value("flag", Get)) of
        1 ->
            IsOpenGuestAccount = true;
        _ ->
            IsOpenGuestAccount = false
    end,
    ModuleName = etc,
    ModuleNameFilePath = common_config:get_root_config_file_path(ModuleName),
    {ok,ModuleDataList} = file:consult(ModuleNameFilePath),
    ModuleDataList2 = 
        lists:foldl(
          fun({Key,Value},Acc) ->
                  case Key of
                      is_open_guest_account ->
                          [{Key,IsOpenGuestAccount}|Acc];
                      _ ->
                          [{Key,Value}|Acc]
                  end
          end,[],ModuleDataList),
    mgeeweb_tool:call_nodes(common_config_dyn,load_gen_src,[ModuleName,ModuleDataList2,ModuleDataList2]),
    mgeeweb_tool:return_json_ok(Req).
%% 获取游客模式
get_guest_mode(Req) ->
    case common_config_dyn:find(etc,is_open_guest_account) of
        [true] ->
            Result = "1";
        _ ->
            Result = "0"
    end,
    mgeeweb_tool:return_json([{result, ok}, {guest_mode, Result}], Req).

%%生成地图流失率数据
gen_map_goway(Req)->
    QueryString = Req:parse_post(),
    case global:whereis_name(mgeew_admin_server) of
        undefined->
            error;
        PID ->
            TimeGapHour = get_param_int("time_gap",QueryString),
            MaxLevel = get_param_int("level",QueryString),
            MapListString = get_param_string("maps", QueryString),
            
            case is_list(MapListString) andalso length(MapListString)>1 of
                true->
                    MapIDList = [ common_tool:to_integer(Str)|| Str<- string:tokens(MapListString, ",") ],
                    erlang:send(PID, {gen_map_goway, MapIDList,TimeGapHour,MaxLevel}),
                    mgeeweb_tool:return_json_ok(Req);
                _ ->
                    ignore,
                    mgeeweb_tool:return_json_ok(Req)
            end
    end.


get_param_int(Key,QueryString)->
    common_tool:to_integer( proplists:get_value(Key, QueryString) ).

get_param_string(Key, QueryString)->
    proplists:get_value(Key, QueryString).





