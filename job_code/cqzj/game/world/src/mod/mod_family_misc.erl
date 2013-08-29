%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     宗族工具模块
%%%     注意:: 该模块属于mod_family的子模块，只能在mod_family中被调用！
%%% @end
%%% Created : 2011-03-01
%%%-------------------------------------------------------------------
-module(mod_family_misc).
-include("mgeew.hrl").
-include("mgeew_family.hrl").



%% API
-export([get_uplevel_boss_money/1,get_uplevel_boss_ac/1,get_uplevel_boss_fc/1,get_common_boss_fc/1]).
-export([get_common_boss_ac/1,get_common_boss_money/1,get_uplevel_boss_type/1,get_common_boss_type/1]).
-export([get_uplevel_money/1,get_uplevel_activepoints/1,get_resume_points/1,get_resume_silver/1]).

-export([get_common_boss_exp_base/1]).

%% ====================================================================
%% API functions
%% ====================================================================

get_family_boss_config(Level) ->
	[ConfigList] = common_config_dyn:find(family_boss,family_boss),
	lists:keyfind(Level,#r_family_boss_config.level,ConfigList).

get_uplevel_boss_money(Level) ->
    #r_family_boss_config{uplevel_boss_money=V} = get_family_boss_config(Level),
    V.

get_uplevel_boss_ac(Level) ->
    #r_family_boss_config{uplevel_boss_ap=V} = get_family_boss_config(Level),
    V.

get_uplevel_boss_fc(Level) ->
    #r_family_boss_config{uplevel_boss_fc=V} = get_family_boss_config(Level),
    V.

get_common_boss_fc(Level) ->
    #r_family_boss_config{common_boss_fc=V} = get_family_boss_config(Level),
    V.  

get_common_boss_ac(Level) ->
    #r_family_boss_config{common_boss_ap=V} = get_family_boss_config(Level),
    V.

get_common_boss_money(Level) ->
    #r_family_boss_config{common_boss_money=V} = get_family_boss_config(Level),
    V.

%%根据宗族等级，获取BOSS_TYPE
get_uplevel_boss_type(Level) ->
    #r_family_boss_config{uplevel_boss_type=V} = get_family_boss_config(Level),
    V.

get_common_boss_type(Level) ->
    #r_family_boss_config{common_boss_type=V} = get_family_boss_config(Level),
    V.


%%升级到指定级别需要的宗族资金
get_uplevel_money(Level) ->
    #r_family_config{uplevel_money=V} = cfg_family:level_config(Level),
    V.


%%升级到指定级别需要的宗族繁荣度
get_uplevel_activepoints(Level) ->     
    #r_family_config{uplevel_ap=V} = cfg_family:level_config(Level),
    V.

%%获取每天宗族地图消耗的宗族繁荣度
get_resume_points(Level) ->
    #r_family_config{daily_maintain_ap=V} = cfg_family:level_config(Level),
    V.

%%获取每天宗族地图消耗的宗族财富
get_resume_silver(Level) ->
    #r_family_config{daily_maintain_money=V} = cfg_family:level_config(Level),
    V.



%%参数是目前宗族的等级
get_common_boss_exp_base(Level)->
    case Level of 
    1->
        5;
    2 ->
        7;
    3 ->
        9;
    4 ->
        12;
    5 ->
        15;
    6 ->
        18;
    InvalidRequest ->
        ?DEBUG("宗族不正确调用~p",[InvalidRequest]),
        0
    end.



