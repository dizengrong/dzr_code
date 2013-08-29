%%% -------------------------------------------------------------------
%%% Author  : xiaosheng
%%% Description : 怪物死亡经验的hook
%%%     哥们，如果组队的队员打怪，那么都可以调用到这里的hook。所以任务计数器同时有效
%%%
%%%
%%% Created : 2010-6-5
%%% -------------------------------------------------------------------
-module(hook_monster_dead_exp).
-export([
         hook/1
        ]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% -include("mgeem.hrl").
-include("mission.hrl").

%% --------------------------------------------------------------------
%% Function: hook/1
%% Description: hook检查口
%% Parameter: int() RoleId 角色id
%% Parameter: int() MonsterType 怪物类型 怪物类型是与怪物等级直接挂钩的
%% Returns: ok
%% --------------------------------------------------------------------
%%检查
hook({RoleId, MonsterType,_AddExp}) ->
    hook_mission(RoleId, MonsterType).


%% ====================================================================
%% 第三方hook代码放置在此
%% ====================================================================

%%任务
hook_mission(RoleID, MonsterType) ->
    Msg =  {mod_mission_handler, {listener_dispatch, monster_dead, RoleID, MonsterType}},
    mgeer_role:absend(RoleID, Msg),

    Msg1 =  {mod_mission_handler, {listener_dispatch, monster_dead, RoleID, ?MISSION_FREE_MONSTER_ID}},
    mgeer_role:absend(RoleID, Msg1).

