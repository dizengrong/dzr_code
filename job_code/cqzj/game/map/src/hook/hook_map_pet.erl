%%%-------------------------------------------------------------------
%%% @author liuwei <>
%%% @copyright (C) 2010, liuwei
%%% @doc hook地图中异兽的各种信息
%%%-------------------------------------------------------------------
-module(hook_map_pet).

-include("mgeem.hrl").

%% API
-export([
         be_attacked/3,
         on_grow_update/4
        ]).

%%%===================================================================
%%% API
%%%===================================================================

%% @doc 异兽被攻击，被本国玩家攻击会灰名
be_attacked(PetID, SActorID, SActorType) when is_integer(PetID) ->
    case mod_map_actor:get_actor_mapinfo(PetID, pet) of
        undefined ->
            ignore;
        PetMapInfo ->
            be_attacked(PetMapInfo, SActorID, SActorType)
    end;
be_attacked(PetMapInfo, SActorID, SActorType) ->
    RoleID = PetMapInfo#p_map_pet.role_id,
    mod_gray_name:change(RoleID, SActorID, SActorType),
    ok.

%% 训宠能力升级了
on_grow_update(RoleID, GrowLevel, _Type, IsAllLevelFull) ->
    hook_mission_event:hook_pet_grow(RoleID,GrowLevel),
    %% 完成成就
    case IsAllLevelFull of
        true ->
            mod_achievement2:achievement_update_event(RoleID, 42004, 1);
        false -> ignore
    end,
    ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================
