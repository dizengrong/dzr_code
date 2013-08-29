%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 19 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(hook_fight).

-include("mgeem.hrl").

%% API
-export([
         check_fight_condition/3,
         check_fight_pk_mod/3
        ]).

-define(IF_THEN_ELSE(Condition,DoTrue,DoFalse),
        case Condition of
            true->
                DoTrue;
            _ ->
                DoFalse
        end
       ).

%%检查两人能否进行PK
check_fight_pk_mod(SActorMapInfo, DActorMapInfo, MapID) when is_record(DActorMapInfo, p_map_pet) ->
    DRoleMapInfo = mod_map_actor:get_actor_mapinfo(DActorMapInfo#p_map_pet.role_id, role),
    check_fight_pk_mod(SActorMapInfo, DRoleMapInfo, MapID);
check_fight_pk_mod(SActorMapInfo, DActorMapInfo, MapID) when is_record(DActorMapInfo, p_map_ybc) ->
    DRoleMapInfo = mod_map_actor:get_actor_mapinfo(DActorMapInfo#p_map_ybc.creator_id, role),
    check_fight_pk_mod(SActorMapInfo, DRoleMapInfo, MapID);
check_fight_pk_mod(_SActorMapInfo, undefined, _MapID) ->
	ignore;
check_fight_pk_mod(_SActorMapInfo, DActorMapInfo, _MapID) ->
    #p_map_role{role_id=DActorID, state=_DState} = DActorMapInfo,
    case mod_arena:is_arena_watcher(DActorID) of
        true->
            throw({error, ?_LANG_ARENA_CANNOT_ATTACK_WATCHER_IN_MAP});
        _ ->
            case mod_horse_racing:is_role_in_horse_racing(DActorID) of
                true ->
                    throw({error, ?_LANG_FIGHT_TARGET_HORSE_RACING});
                _ ->
                    ignore
            end
    end.


%%简单当前地图是否允许战斗
check_fight_condition(RoleID,TargetID,TargetType) ->
    case check_fight_condition_2(RoleID,TargetID,TargetType) of
      true ->
        true;
      Error ->
        throw(Error)
    end.

check_fight_condition_2(RoleID,TargetID,TargetType) ->
	?IF_THEN_ELSE( mod_arena:is_in_arena_map(),    %%是否在竞技场中
				   check_map_fight_in_arena(RoleID,TargetID,TargetType),
				   
				   ?IF_THEN_ELSE( mod_nationbattle_fb:is_in_fb_map(),    %%是否在上古战场中
								  check_map_fight_in_nationbattle(RoleID,TargetID,TargetType),
								  ?IF_THEN_ELSE( mod_crown_arena_fb:is_in_fb_map(),    %%是否在战神坛中
												 check_map_fight_in_arenabattle(RoleID,TargetID,TargetType),
												 true
								  )
				   )
	),
	?IF_THEN_ELSE(mod_ybc_person:check_in_ybcing(TargetID,TargetType),
				  check_ybc_fight(RoleID,TargetID,TargetType),true).

check_map_fight_in_arena(RoleID,TargetID,?TYPE_ROLE) when (RoleID=:=TargetID)->
    true;   %%可以给自己施加状态
check_map_fight_in_arena(RoleID,_,_)->
    mod_arena:check_map_fight(RoleID).

check_map_fight_in_nationbattle(_RoleID,TargetID,?TYPE_PET) ->
   mod_crown_arena_cull_fb:is_can_fight(TargetID);
check_map_fight_in_nationbattle(_RoleID,TargetID,?TYPE_ROLE)->
    mod_crown_arena_cull_fb:is_can_fight(TargetID);
check_map_fight_in_nationbattle(_,_,_)->
    true.


check_map_fight_in_arenabattle(_RoleID,TargetID,_Type) ->
    mod_crown_arena_cull_fb:is_can_fight(TargetID).
check_ybc_fight(_RoleID,TargetID,Type) ->
    mod_ybc_person:is_can_fight(TargetID,Type).

