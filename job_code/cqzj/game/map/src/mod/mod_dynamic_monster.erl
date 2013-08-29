%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2011, 
%%% @doc
%%%
%%% @end
%%% Created : 21 Jul 2011 by  <>
%%%-------------------------------------------------------------------
-module(mod_dynamic_monster).

-include("mgeem.hrl").
-include("dynamic_monster.hrl").

-define(check_boss_group_init_interval,10000).

%% API
-export([
         handle/1,
         handle/2
        ]).


-export([
         hook_map_init/1,
         hook_map_loop/1]).


%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).

handle(Msg) ->
    ?ERROR_MSG("uexcept msg = ~w",[Msg]).


%% @doc 地图每秒循环
hook_map_loop(Now) ->
    hook_dynamic_monster(Now),
    ok.

%%处理活动期间的动态出生的怪物
%%      活动怪物在服务器重启后只能出生一次
hook_dynamic_monster(Now)->
    case get_activity_monster_list() of
        [] ->
            ignore;
        [{StartTime, R}|TActivityList] ->
            if StartTime > Now ->
                   ignore;
               true ->
                   hook_dynamic_monster2(R, TActivityList)
            end
    end.
hook_dynamic_monster2(R, TActivityList) ->
    #r_activity_dynamic_monster{type=Type, config_key=ConfigKey} = R,
    if 
        Type =:= ?TYPE_BORN_NOTICE ->
            common_map:dynamic_create_monster(notice, ConfigKey);
        true ->
            common_map:dynamic_create_monster(monster, ConfigKey)
    end,
    set_activity_monster_list(TActivityList).

   

%% @doc 地图初始化hook   ================================================
hook_map_init(?DEFAULT_MAPID) ->
    case common_config_dyn:find(activity_define, ?ACTIVITY_CONFIG_KEY) of
        [ActKeyList] when is_list(ActKeyList) ->
            [hook_map_init_1(ActKey)||ActKey<-ActKeyList];
        _ ->
            ignore
    end;
hook_map_init(_MapId) ->
    ignore. 

hook_map_init_1(ActKey)->
    case common_config_dyn:find(activity_define, ActKey) of
        [] ->
            ignore;
        [ConfigList] ->
            Now = common_tool:now(),
            hook_map_init_2(ConfigList,Now, [])
    end.

%%-----------初始化动态生成怪列表---------------------
hook_map_init_2([], _Now, []) ->
    ignore;
hook_map_init_2([], _Now, ActivityList) ->
    %%初始化并设置活动怪物的列表
    set_activity_monster_list(lists:keysort(1, ActivityList));

hook_map_init_2([H|T], Now, ActivityList) ->
    case H of
        {true, StartTime, _EndTime, #r_activity_dynamic_monster{type=Type}=Record} when (Type =:= ?TYPE_BORN_NOTICE andalso Type =:= ?TYPE_BORN_MONSTER)->
            StartTimeStamp = common_tool:datetime_to_seconds(StartTime),
            if StartTimeStamp > Now ->
                   hook_map_init_2(T, Now, [{StartTimeStamp, Record}|ActivityList]);
               true ->
                   hook_map_init_2(T, Now, ActivityList)
            end;
        _ ->
            hook_map_init_2(T, Now, ActivityList)
    end.


%%设置活动怪物的列表（跟boss_group无关）
set_activity_monster_list(List) ->
    erlang:put(?ACTIVITY_MONSTER_LIST, List).

get_activity_monster_list() ->
    case erlang:get(?ACTIVITY_MONSTER_LIST) of
        undefined ->
            [];
        L ->
            L
    end.

