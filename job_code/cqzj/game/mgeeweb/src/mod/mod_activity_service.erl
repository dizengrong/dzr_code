%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     活动配置的相关接口
%%% @end
%%% Created : 2010-11-17
%%%-------------------------------------------------------------------
-module(mod_activity_service).


%% --------------------------------------------------------------------
%% include_once files
%% --------------------------------------------------------------------
-include("mgeeweb.hrl").



%%
%% Exported Functions
%%
-export([get/3]).
-compile(export_all).
-export([]).


%% ====================================================================
%% API Functions
%% ====================================================================
get(Path,Req,DocRoot)->
    try
        do_get(Path,Req,DocRoot)
    catch
        _:Reason->
            ?ERROR_MSG("do_get error,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()]),
            mgeeweb_tool:return_json_error(Req)
    end.


%%获取活动配置文件
do_get("/activity_define"++_R, Req, _DocRoot) ->
    do_get_activity_define(Req);
%% 开启双倍Buff
do_get("/admin_start_world_buff/", Req, _DocRoot) ->
    admin_start_world_buff(Req);
do_get(Path, Req, DocRoot) ->
    ?ERROR_MSG("~ts : ~w ~w", ["未知的请求", Path, DocRoot]),
    mgeeweb_tool:return_json_error(Req).


do_get_activity_define(Req)->
    QueryString = Req:parse_qs(),
    ConfigKey = get_param_int("key", QueryString),
    Result = do_get_activity_config(ConfigKey),
    Req:ok({"text/html; charset=utf-8", [{"Server","MCCQ"}],Result}).

do_get_activity_config(Key)->
    case common_config_dyn:find(activity_define,Key) of
        []->
            common_json2:to_json("");
        [ConfigList] when is_list(ConfigList)->
            List2 = lists:map(fun(E)-> 
                                      {IsOpen,StartTime,EndTime,Rec} = E, 
                                      RecList = case is_list(Rec) of
                                                    true->
                                                        [ mgeeweb_tool:transfer_to_json(R) ||R<-Rec];
                                                    _ ->
                                                        [ mgeeweb_tool:transfer_to_json(Rec) ]
                                                end,
                                      
                                      TupleList = [{is_open,IsOpen},{start_time,date_to_string(StartTime)},{end_time,date_to_string(EndTime)},
                                                   {rec,RecList}],
                                      TupleList
                              end, ConfigList),
            common_json2:to_json(List2);
        _ ->
            []
    end.

date_to_string(DateTime)->
    {{Y,M,D},{HH,MM,SS}} = DateTime,
    lists:flatten( io_lib:format("~w-~w-~w ~w:~w:~w",[Y,M,D,HH,MM,SS]) ).


get_param_int(Key,QueryString)->
    common_tool:to_integer( proplists:get_value(Key, QueryString) ).

admin_start_world_buff(Req) ->
    QueryString = Req:parse_qs(),
    StartH = mgeeweb_tool:get_int_param("startH", QueryString),
    StartM = mgeeweb_tool:get_int_param("startM", QueryString),
    EndH = mgeeweb_tool:get_int_param("endH", QueryString),
    EndM = mgeeweb_tool:get_int_param("endM", QueryString),
    
    case global:whereis_name(mgeew_system_buff) of
        undefined ->
            ignore;
        PID ->
            PID ! {admin_open_world_exp_buff, {StartH,StartM}, {EndH,EndM}},
            mgeeweb_tool:return_json_ok(Req)
    end.
