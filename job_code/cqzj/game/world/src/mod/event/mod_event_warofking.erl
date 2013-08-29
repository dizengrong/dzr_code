%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  7 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_event_warofking).

%%-behaviour(mod_event).

-include("mgeew.hrl").

%% Corba callbacks
-export([
         init_config/0,
         handle_info/1,
         handle_call/1,
         handle_msg/1,
         reload_config/1
        ]).

%%--------------------------------------------------------------------
init_config() ->   
    ok.

handle_info(Info) ->
    do_handle_info(Info),
    ok.

handle_call(Request) ->
    do_handle_call(Request).

handle_msg(_Msg) ->
    ok.

reload_config(_Config) ->
    ok.


%% 管理后台接口
do_handle_call(Request) ->
    ?ERROR_MSG("~ts:~w", ["未知的CALL调用", Request]).

do_handle_info(begin_war) ->
    do_begin_war();

do_handle_info(end_war) ->
    do_end_war();

do_handle_info(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知得消息", Info]).


%%@doc 真正的开始王座争霸战的战斗了
do_begin_war() ->
    FactionIdList = [1,2,3],
    lists:foreach(
      fun(E)->
              common_warofking:set_begin_war(E)
      end, FactionIdList),
    ok.


%%@doc 通知地图，战斗结束了
do_end_war() ->
    FactionIdList = [1,2,3],
    lists:foreach(
      fun(E)->
              common_warofking:set_end_war(E)
      end, FactionIdList),
    ok. 
 

 