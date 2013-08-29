%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 24 Feb 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_system_notice).

-include("mgeem.hrl").

%% API
-export([
         get_notice/0,
         init/0,
         handle/1
        ]).

init() ->
    case db:dirty_read(?DB_SYSTEM_NOTICE_P, 1) of
        [] ->
            set_notice([]);
        [#r_system_notice{notice=Notice}] ->
            set_notice(Notice)
    end.

handle({update_notice, Notice}) ->
    set_notice(Notice);
handle(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知消息", Info]).


set_notice(Notice) ->
    erlang:put(system_notice, Notice).
get_notice() ->
    erlang:get(system_notice).
