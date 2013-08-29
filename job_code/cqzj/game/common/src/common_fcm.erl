%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  3 Jan 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_fcm).

%% API
-export([
         get_fcm_validation_tip/1,
         set_fcm_flag/1,
         set_account_fcm/1
        ]).

-include("common.hrl").

set_fcm_flag(true) ->
    db:dirty_write(?DB_CONFIG_SYSTEM_P, #r_config_system{key=fcm, value=true});
set_fcm_flag(_) ->
    db:dirty_write(?DB_CONFIG_SYSTEM_P, #r_config_system{key=fcm, value=false}).


get_fcm_validation_tip(1) ->
    true;
get_fcm_validation_tip(2) ->
    {false, "未满十八周岁"};
get_fcm_validation_tip(-1) ->
    {false, "参数不全"};
get_fcm_validation_tip(-2) ->
    {false, "验证失败"};
get_fcm_validation_tip(-4) ->
    true;
get_fcm_validation_tip(-5) ->
    {false, "登记防沉迷资料失败，请稍后重试"};
get_fcm_validation_tip(-6) ->
    {false, "系统错误"};
get_fcm_validation_tip(-3) ->
    {false, "提供的身份证号码不合法"};
get_fcm_validation_tip(_R) ->
    {false, "系统错误"}.


set_account_fcm(AccountName) ->
    db:dirty_write(?DB_FCM_DATA, #r_fcm_data{account=common_tool:to_binary(AccountName), passed=true}).


