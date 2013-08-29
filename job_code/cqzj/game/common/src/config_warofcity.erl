%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  3 Nov 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(config_warofcity).

%% API
-export([
         get_apply_level/1,
         get_apply_money/1,
         get_reward_id/2
        ]).

get_apply_level(10260) ->
    4;
get_apply_level(_) ->
    error.

get_apply_money(10260) ->
    400 * 100;
get_apply_money(_) ->
    error.


%% 获取连续占领奖励

%% 太平村
get_reward_id(0, 7) ->
    1;
get_reward_id(0, 14) ->
    1;
get_reward_id(0, 21) ->
    1;
get_reward_id(0, 28) ->
    1;
get_reward_id(0, 56) ->
    1;

%% 横涧山
get_reward_id(1, 7) ->
    1;
get_reward_id(1, 14) ->
    1;
get_reward_id(1, 21) ->
    1;
get_reward_id(1, 28) ->
    1;
get_reward_id(1, 56) ->
    1;


%% 京城
get_reward_id(100, 7) ->
    1;
get_reward_id(100, 14) ->
    1;
get_reward_id(100, 21) ->
    1;
get_reward_id(100, 28) ->
    1;
get_reward_id(100, 56) ->
    1;

%% 鄱阳湖
get_reward_id(101, 7) ->
    1;
get_reward_id(101, 14) ->
    1;
get_reward_id(101, 21) ->
    1;
get_reward_id(101, 28) ->
    1;
get_reward_id(101, 56) ->
    1;

%% 平江
get_reward_id(102, 7) ->
    1;
get_reward_id(102, 14) ->
    1;
get_reward_id(102, 21) ->
    1;
get_reward_id(102, 28) ->
    1;
get_reward_id(102, 56) ->
    1;

%% 杏花岭
get_reward_id(103, 7) ->
    1;
get_reward_id(103, 14) ->
    1;
get_reward_id(103, 21) ->
    1;
get_reward_id(103, 28) ->
    1;
get_reward_id(103, 56) ->
    1;


%% 西凉
get_reward_id(104, 7) ->
    1;
get_reward_id(104, 14) ->
    1;
get_reward_id(104, 21) ->
    1;
get_reward_id(104, 28) ->
    1;
get_reward_id(104, 56) ->
    1;


get_reward_id(_, _) ->
    throw({error, wrong_get_reward_config_param}).    
