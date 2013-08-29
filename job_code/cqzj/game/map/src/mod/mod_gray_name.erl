%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2010, 
%%% @doc
%%%
%%% @end
%%% Created :  9 Dec 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_gray_name).

-include("mgeem.hrl").

-export([change/3, cancel_gray_name/1, login_gray_name_init/1, do_gray_name/2]).

-define(GRAY_NAME_INTERVAL, 20).

%% @doc 玩家灰名
%% RoleID：被攻击玩家，SActorID：攻击发起人
change(RoleID, SActorID, SActorType) when erlang:is_integer(RoleID) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            ignore;
        RoleMapInfo ->
            change(RoleMapInfo, SActorID, SActorType)
    end;
change(RoleMapInfo, SActorID, SActorType) when erlang:is_record(RoleMapInfo, p_map_role) ->
    #p_map_role{role_id=RoleID} = RoleMapInfo,
    case SActorType of
        role ->
            %% 对自己施放技能不会灰名
            case SActorID =:= RoleID of
                true ->
                    ignore;
                _ ->
                    change2(RoleMapInfo, SActorID)
            end;
        pet ->
            case mod_map_actor:get_actor_mapinfo(SActorID, SActorType) of
                undefined ->
                    ignore;
                PetMapInfo ->
                    SActorID2 = PetMapInfo#p_map_pet.role_id,
                    change(RoleID, SActorID2, role)
            end;
        _ ->
            ignore
    end;
%% @doc NPC被攻击玩家灰名
change(NpcMapInfo, SActorID, SActorType) ->
    case SActorType of
        role ->
            #p_map_server_npc{npc_country=NpcCountry} = NpcMapInfo,
            case mod_map_actor:get_actor_mapinfo(SActorID, SActorType) of
                #p_map_role{faction_id=NpcCountry}=SActorMapInfo ->
                    do_gray_name(SActorID, SActorMapInfo);
                _ ->
                    ignore
            end;
        pet ->
            case mod_map_actor:get_actor_mapinfo(SActorID, SActorType) of
                undefined ->
                    ignore;
                PetMapInfo ->
                    SActorID2 = PetMapInfo#p_map_pet.role_id,
                    change(NpcMapInfo, SActorID2, role)
            end;
        _ ->
            ignore
    end.

change2(RoleMapInfo, SRoleID) ->
    case mod_map_actor:get_actor_mapinfo(SRoleID, role) of
        undefined ->
            ignore;
        SRoleMapInfo ->
            change3(RoleMapInfo, SRoleMapInfo)
    end.

change3(RoleMapInfo, SRoleMapInfo) ->
    #p_map_role{pk_point=PKPoint, gray_name=GrayName, faction_id=FactionID, pos=Pos, is_mirror=IsRoleMirror} = RoleMapInfo,
    #p_map_role{role_id=SRoleID, pk_point=SPKPoint, faction_id=SFactionID, is_mirror=IsSRoleMirror} = SRoleMapInfo,
    #p_pos{tx=TX, ty=TY} = Pos,

	MapID = mgeem_map:get_mapid(),
    case IsRoleMirror orelse IsSRoleMirror orelse lists:member({TX,TY}, mcm:reado_tiles(MapID)) of
        true ->
            Flag = true;
        _ ->
            Flag = false
    end,

    %% 攻击双方红名，或者被攻击对象灰名，攻击者都不会灰名
    case SPKPoint > ?RED_NAME_PKPOINT orelse PKPoint > ?RED_NAME_PKPOINT
        orelse GrayName =:= true orelse FactionID =/= SFactionID
        orelse Flag =:= true
    of
        true ->
            ignore;
        _ ->
            do_gray_name(SRoleID, SRoleMapInfo)
    end.

%% @doc 取消灰名
cancel_gray_name(RoleID) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            ignore;
        RoleMapInfo ->
            #p_map_role{gray_name=GrayName} = RoleMapInfo,
            
            case GrayName of
                true ->
                    do_cancel_gray_name(RoleMapInfo);
                _ ->
                    ignore
            end
    end.

%% @doc 角色登陆时灰名相关处理
login_gray_name_init(RoleID) ->
    case mod_map_role:get_role_state(RoleID) of
        {error, _} ->
            ignore;
        {ok, RoleState} ->
            #r_role_state2{gray_name_time=GrayNameTime} = RoleState,
            
            Now = common_tool:now(),
            case Now - GrayNameTime >= ?GRAY_NAME_TIME of
                true ->
                    cancel_gray_name(RoleID);
                _ ->
                    erlang:send_after((Now-GrayNameTime)*1000, self(), {mod_map_role, {cancel_gray_name, RoleID}})
            end
    end.

do_cancel_gray_name(RoleMapInfo) ->
    #p_map_role{role_id=RoleID} = RoleMapInfo,

    case common_transaction:transaction(
           fun() ->
                   t_do_cancel_gray_name(RoleID)
           end)
    of
        {atomic, _} ->
            RoleMapInfo2 = RoleMapInfo#p_map_role{gray_name=false},
            mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo2),

            DataRecord = #m_role2_gray_name_toc{roleid=RoleID, if_gray_name=false},
			mgeem_map:send({broadcast_in_sence_include,
	                [RoleID], ?ROLE2, ?ROLE2_GRAY_NAME, DataRecord}),
            ok;
        {aborted, Reason} ->
            ?ERROR_MSG("do_cancel_gray_name, error: ~w", [Reason])
    end.

t_do_cancel_gray_name(RoleID) ->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    
    RoleBase2 = RoleBase#p_role_base{if_gray_name=false},
    mod_map_role:set_role_base(RoleID, RoleBase2).

do_gray_name(RoleID, RoleMapInfo) ->
    #p_map_role{gray_name=GrayName, pk_point=PKPoints, state=RoleState} = RoleMapInfo,
    
    if
        GrayName orelse PKPoints >= ?RED_NAME_PKPOINT orelse RoleState =:= ?ROLE_STATE_DEAD ->
            ignore;
        true ->
            do_gray_name2(RoleID, RoleMapInfo)
    end.

do_gray_name2(RoleID, RoleMapInfo) ->
    {ok, RoleState} = mod_map_role:get_role_state(RoleID),
    #r_role_state2{gray_name_time=GrayNameTime} = RoleState,
    case common_tool:now() - GrayNameTime >= ?GRAY_NAME_INTERVAL of
        true ->
            case common_transaction:transaction(
                   fun() ->
                           t_do_gray_name(RoleID)
                   end)
            of
                {atomic, _} ->
                    RoleMapInfo2 = RoleMapInfo#p_map_role{gray_name=true},
                    mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo2),
                    DataRecord = #m_role2_gray_name_toc{roleid=RoleID, if_gray_name=true},
                    mgeem_map:do_broadcast_insence_include([{role, RoleID}], ?ROLE2, ?ROLE2_GRAY_NAME, DataRecord, mgeem_map:get_state()),
                    #r_role_state2{gray_name_timer_ref=TimerRef} = RoleState,
                    case TimerRef of
                        undefined ->
                            ok;
                        _ ->
                            erlang:cancel_timer(TimerRef)
                    end,
                    TimerRef2 = erlang:send_after(?GRAY_NAME_TIME, self(), {mod_map_role, {cancel_gray_name, RoleID}}),
                    RoleState2 = RoleState#r_role_state2{gray_name_time=common_tool:now(), gray_name_timer_ref=TimerRef2},
                    mod_map_role:set_role_state(RoleID, RoleState2);
                {aborted, Reason} ->
                    ?ERROR_MSG("do_gray_name, error: ~w", [Reason])
            end;
        _ ->
            ignore
    end.

t_do_gray_name(RoleID) ->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),

    RoleBase2 = RoleBase#p_role_base{last_gray_name=common_tool:now(), if_gray_name=true},
    mod_map_role:set_role_base(RoleID, RoleBase2).
