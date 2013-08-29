%%% -------------------------------------------------------------------
%%% Author  : xiaosheng
%%% Description : 宗族变更
%%%
%%% Created : 2010-7-22
%%% -------------------------------------------------------------------
-module(hook_family_change).
-export([
         hook/2
        ]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").

%% --------------------------------------------------------------------
%% Function: hook/1
%% Description: hook检查口
%% Parameter: int() NewFamilyID 新宗族ID
%% Parameter: record() OldRoleBase #p_role_base 未改变宗族前的角色信息
%% Returns: ok
%% --------------------------------------------------------------------
hook(change, {RoleID, NewFamilyID, OldFamilyID}) ->
    hook_mission(NewFamilyID, OldFamilyID, RoleID),
    hook_chat(NewFamilyID, OldFamilyID, RoleID),
    case (NewFamilyID > 0) of 
        true ->  %% 完成成就
            case common_misc:is_role_online(RoleID) of
                true ->
                    mod_achievement2:achievement_update_event(RoleID, 41004, 1);
                false ->
                    mod_offline_event:add_event(RoleID, ?OFFLINE_EVENT_TYPE_JOIN_FAMILY, 1)
            end;
        false ->
            ignore
    end,
    ok.


%% ====================================================================
%% 第三方hook代码放置在此
%% ====================================================================

%%任务
hook_mission(NewFamilyID, OldFamilyID, RoleID) ->
   Msg =  {mod_mission_handler, {listener_dispatch, family_changed, RoleID, NewFamilyID, OldFamilyID}},
   mgeer_role:absend(RoleID, Msg).

%%聊天
hook_chat(NewFamilyID, OldFamilyID, RoleName) ->
    if
        OldFamilyID =/= 0 ->
            common_misc:chat_leave_family_channel(RoleName, OldFamilyID);
        true ->
            ignore
    end,

    if
        NewFamilyID =/= 0 ->
            common_misc:chat_join_family_channel(RoleName, NewFamilyID);
        true ->
            ignore
    end.

