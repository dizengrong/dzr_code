%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(common_stat).

%%
%% Include files
%%
%%
%% Include files
%%

 
-define(IS_STAT_OPEN,false).
-include("mm_define.hrl").


%%
%% Exported Functions
%%
-export([stat_method/2]).
-export([]).

%%
%% API Functions
%%

-define(NOT_STAT_MODULE_LIST,[?MAP,?BGP,?CHAT,?SYSTEM,?NPC,?MOVE,?AUTH,?ROLE,?LOGIN,?ROLE2,?FIGHT,?MONSTER]).

stat_method(_,_)->
    ignore.
%% stat_method(?SYSTEM,_)->
%%     ignore;
%% stat_method(?CHAT,_)->
%%     ignore;
%% stat_method(?MOVE,_)->
%%     ignore;
%% stat_method(?MISSION,_)->
%%     ignore;
%% stat_method(Module,Method)->
%%     case ?IS_STAT_OPEN andalso not lists:member(Module, ?NOT_STAT_MODULE_LIST) of
%%         true-> 
%%            catch erlang:send(mgeeg_stat_server, {stat_method,Method});
%%         _ ->
%%             ignore
%%     end.

