%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2010, 
%%% @doc
%%% 热更新配置文件模块
%%% 在此模块添加需要热更新的配置文件和实现
%%% @end
%%% Created : 20 Dec 2010 by  <caochuncheng2002@gmail.com>
%%%-------------------------------------------------------------------
-module(common_config_update).

-include("common.hrl").
-include("common_server.hrl").

-export([
         update/1
        ]).

%% 接口描述
%% common_config_update:update({refining_forging_config}). 更新天工炉炼制配置文件
%% common_config_update:update({trading_config,Type}).更新商贸活动配置文件 all,trading trading_goods

update(Info) ->
    try 
        do_update(Info)
    catch
        Error:Reason ->
            ?ERROR_MSG("~ts,Info=~w,Error=~w,Reason=~w",["热更新配置文件出错",Info,Error,Reason])
    end.
            
do_update({refining_forging_config}) ->
    do_refining_forging_config();

do_update({trading_config,Type}) ->
    do_trading_config(Type);

do_update(Info) ->
    ?ERROR_MSG("~ts,Info=~w",["无法执行此更新操作",Info]).

%% 获取当前所有地图进程名称
get_all_online_map_process_name() ->
    Pattern = #r_map_online{_='_'},
    case db:dirty_match_object(?DB_MAP_ONLINE,Pattern) of
        []-> [];
        RecList ->
            [R#r_map_online.map_name || R <-RecList]
    end.


%% 天工炉炼制配置文件更新操作
do_refining_forging_config() ->
    MapNameList = get_all_online_map_process_name(),
    lists:foreach(
      fun(MapProcessName) ->
              global:send(MapProcessName, {mod_refining_forging,{reload_forging_config}})
      end,MapNameList).

%% 商贸活动配置文件更新操作
%% 更新商贸活动配置文件 all,trading trading_goods
do_trading_config(Type) ->
    MapNameList = get_all_online_map_process_name(),
    lists:foreach(
      fun(MapProcessName) ->
              global:send(MapProcessName, {mod_trading,{reload_trading_config,Type}})
      end,MapNameList).
