%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     宗族在活动期间的特殊处理
%%% @end
%%% Created : 2011-01-10
%%%-------------------------------------------------------------------
-module(hook_activity_family).
-include("mgeew.hrl").

%% API
-export([hook_activity_expr/2,get_common_boss_max_call_count/0]).

%% ====================================================================
%% API functions
%% ====================================================================



%%@doc 活动期间内可活动双倍经验
hook_activity_expr(_RoleID,GainExp)->
    %% 1.判断活动配置
    case common_activity:get_activity_config_by_name(activity_family_boss) of
        [#r_activity_family_award{award_expr_times=Times}] when (Times>=1)-> 
            ?INFO_MSG("Times=~w",[Times]),
            GainExp*Times;
        _ ->
            GainExp
    end.

%%@doc 普通BOSS一天可以召唤的最多次数
get_common_boss_max_call_count()->
    %% 1.判断活动配置
    case common_activity:get_activity_config_by_name(activity_family_boss) of
        [#r_activity_family_award{call_cmm_boss_count=Cnt}]->
            ?INFO_MSG("wuzesen,Cnt=~w",[Cnt]),
            Cnt;
        _ ->
            1
    end.


%% ====================================================================
%% Internal functions
%% ====================================================================

