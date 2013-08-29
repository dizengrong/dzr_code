%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc 初始化mnesia数据
%%%
%%% @end
%%% Created :  3 Dec 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_mnesia_init).

%% API
-export([init/0]).

-include("mnesia.hrl").

init() ->
    init_data_once().

init_data_once() ->
    init_ybc_unique(),
    init_system_config(),
    ok.

%%初始化系统配置信息
init_system_config() ->
    db:transaction(
      fun() ->
              case db:read(?DB_CONFIG_SYSTEM_P, has_init, write) of
                  [] ->
                      %%尚未初始化,写入初始化标志
                      ok = db:write(?DB_CONFIG_SYSTEM_P, {r_config_system, has_init, true}, write),
                      %%是否打开防沉迷
                      ok = db:write(?DB_CONFIG_SYSTEM_P, {r_config_system, fcm, false}, write),
                      ok = db:write(?DB_CONFIG_SYSTEM_P, {r_config_system, open_pay_first, true}, write),
                      ok;
                  _ ->
                      ignore
              end
      end).
              


init_ybc_unique() ->
    db:transaction(
      fun() ->
              case db:read(?DB_YBC_INDEX_P, 1, write) of
                  [] ->
                      db:write(?DB_YBC_INDEX_P, #r_ybc_index{id=1, value=1}, write);
                  [_] ->
                      ignore
              end
      end).
