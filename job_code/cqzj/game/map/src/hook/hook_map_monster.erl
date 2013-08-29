%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     怪物的相关hook，包括怪物死亡
%%%     问题1：如果队员打怪，是否会调用到这里的hook？
%%% @end
%%% Created : 2011-6-18
%%%-------------------------------------------------------------------
-module(hook_map_monster).

-include("mgeem.hrl").

%% API
-export([
         monster_dead/5,
         monster_change/0
        ]).

%%%===================================================================
%%% API
%%%===================================================================
monster_dead(server_npc,KillActorID, _DropOwner, MonsterInfo, MonsterBaseInfo)->
    #p_monster{typeid=TypeID} = MonsterInfo,
    FuncList = [
                fun()->  mod_warofmonster:hook_monster_dead(server_npc,KillActorID,TypeID) end,
                fun()->  mod_guard_fb:hook_monster_dead(MonsterBaseInfo) end
               ],
    [?HOOK_CATCH(F) || F <- FuncList],
    ok;
monster_dead(role,KillerRoleID, DropOwner,MonsterInfo, MonsterBaseInfo) when is_record(MonsterInfo,p_monster)->
    #p_monster{monsterid=MonsterID, typeid=TypeID, max_hp=MaxHP, pos=Pos} = MonsterInfo,
    #p_monster_base_info{rarity=Rarity, monstername=MonsterName,level=MonsterLevel} = MonsterBaseInfo,
    {DropOwnerID,_ActorType} = DropOwner,
    FuncList = [
                fun()->  mod_hero_fb:hook_monster_dead(KillerRoleID, MonsterBaseInfo)  end,
                fun()->  mod_tower_fb:hook_monster_dead(KillerRoleID, mgeem_map:get_mapid()) end,
                fun()->  mod_examine_fb:hook_monster_dead(KillerRoleID, MonsterBaseInfo)  end,
                fun()->  mod_guard_fb:hook_monster_dead(MonsterBaseInfo)  end,
                fun()->  mod_mission_fb:hook_monster_dead(MonsterBaseInfo)  end,
                fun()->  mod_scene_war_fb:hook_monster_dead({TypeID, MonsterName, Rarity,MonsterLevel})  end,
                fun()->  mod_monster_addition:hook_monster_dead(MonsterID, TypeID)  end,
                fun()->  mod_map_family:hook_monster_dead(DropOwnerID, TypeID, MonsterName) end,
                fun()->  mod_bigpve_fb:hook_monster_dead(KillerRoleID,MonsterID,TypeID,MaxHP,MonsterName,Pos) end,
                fun()->  mod_warofking:hook_monster_dead(DropOwnerID,TypeID) end,
                fun()->  mod_warofmonster:hook_monster_dead(role,KillerRoleID,TypeID) end, 
                fun()->  hook_activity_schedule:hook_monster_dead(DropOwnerID, TypeID, Rarity) end,
                fun()->  mod_daily_mission:hook_monster_dead(KillerRoleID,TypeID) end,
				fun()->  mod_swl_mission:hook_monster_dead(KillerRoleID,TypeID) end,
                fun()->  mod_map_event:notify({role, KillerRoleID}, {monster_dead, MonsterInfo, MonsterBaseInfo}) end,
                fun()->  mod_activity_boss:hook_monster_dead({KillerRoleID,TypeID, MonsterName,MonsterLevel}) end,
				fun()->  kill_monster_add_nuqi(KillerRoleID, TypeID) end
               ],
    [?HOOK_CATCH(F) || F <- FuncList],
    Rarity =/= ?NORMAL andalso mod_role_event:notify(KillerRoleID, {?ROLE_EVENT_KILL_BOSS, TypeID}),
    ok.
        
monster_change()->
    ok.

kill_monster_add_nuqi(RoleId, MonsterTypeID) ->
    case cfg_role_nuqi:kill_monster_nuqi(MonsterTypeID) of
        0 -> ignore;
        AddNuqi ->
            mod_map_role:add_nuqi(RoleId, AddNuqi)
    end.