%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 12 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(hook_family).

-include("mgeew.hrl").

%% API
-export([
         create/1,
         update/1,
         delete/1,
         combine/2,
         hook_family_conbtribute_change/2,
         role_contribution_change/2,
         join_family/3,
         quit_family/2,
         level_up/2
        ]).

create(FamilyInfo) ->
    ?TRY_CATCH(  join_family(FamilyInfo#p_family_info.create_role_id, FamilyInfo#p_family_info.family_id, FamilyInfo) , Error1),
    ?TRY_CATCH(  mod_family_data_server:create(FamilyInfo) , Error2),
    ok.


update(FamilyInfo) ->
    ?TRY_CATCH(  mod_family_data_server:update(FamilyInfo) , Error1),
    ok.


delete(FamilyID) ->
    ?TRY_CATCH(  mod_family_skill:delete_family_skill(FamilyID) , Error1),
    ?TRY_CATCH(  mod_family_depot:delete_depot(FamilyID) , Error2),
    ?TRY_CATCH(  mod_family_data_server:delete(FamilyID) , Error3),
    ?TRY_CATCH(  common_family:kick_member_in_map_online(FamilyID) , Error4),
    ?TRY_CATCH(  mod_family_shop:delete(FamilyID) , Error5),
    ok.
    
combine(CombineFamily,TargetFamily) ->
    ?TRY_CATCH(  mod_family_data_server:combine(CombineFamily,TargetFamily) , Error1),
    ok.

hook_family_conbtribute_change(RoleID,NewFamilyContrb)->
    ?TRY_CATCH(  notify_family_contribute_change(RoleID,NewFamilyContrb) , Error1),
    ok.

join_family(RoleID, FamilyID, _FamilyInfo) ->
    ?TRY_CATCH(  hook_mission(FamilyID, 0, RoleID) , Error3),
    ?TRY_CATCH(  hook_chat(FamilyID, 0, RoleID) , Error4),
    ?TRY_CATCH(  family_changed(FamilyID, RoleID) , Error5),
    ok.

%%任务
hook_mission(NewFamilyID, OldFamilyID, RoleID) ->
   Msg = {mod_mission_handler, {listener_dispatch, family_changed, RoleID, NewFamilyID, OldFamilyID}},
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

quit_family(RoleID, FamilyID) ->
    ?TRY_CATCH(  hook_mission(0, FamilyID, RoleID) , Error1),
    ?TRY_CATCH(  hook_chat(0, FamilyID, RoleID) , Error2),
    ?TRY_CATCH(  family_changed(0, RoleID) , Error3),
    ok.

%% 玩家宗族发生变化了
family_changed(NewFamilyID, RoleID)->
    R = #m_role2_attr_change_toc{roleid = RoleID,changes = [#p_role_attr_change{change_type = ?ROLE_FAMILYID_CHANGE,new_value = NewFamilyID}]},
    common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?ROLE2,?ROLE2_ATTR_CHANGE,R).

role_contribution_change(_RoleID, _NewContribution) ->
	todo.
level_up(_Members, _Level) ->
    ignore.

notify_family_contribute_change(RoleID,NewFamilyContrb)->
    %%通知map
    mgeer_role:absend(RoleID, {change_attr,family_contribute,RoleID,NewFamilyContrb}),    
    R = #p_role_attr_change { change_type = ?ROLE_FAMILY_CONTRIBUTE_CHANGE, new_value = NewFamilyContrb },
    R_TOC = #m_role2_attr_change_toc{ roleid = RoleID, changes = [R] },
    common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?ROLE2,?ROLE2_ATTR_CHANGE,R_TOC).
