%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2010, 
%%% @doc
%%%
%%% @end
%%% Created : 29 Nov 2010 by  <>
%%%-------------------------------------------------------------------
-module(config_item).

-export([get_cd_time/1]).

get_cd_time(1) ->
    6000;
get_cd_time(2) ->
    6000;
get_cd_time(3) ->
    5000;
get_cd_time(4) ->
    6000;
get_cd_time(5) ->
    1000;
get_cd_time(6) ->
    1000;
get_cd_time(15) ->
    5000;
get_cd_time(17) ->
    5000;
get_cd_time(_) ->
    0.
