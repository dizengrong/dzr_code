%%%-------------------------------------------------------------------
%%% @author Liangliang <Liangliang@gmail.com> 
%%% @copyright (C) 2010, Liangliang 
%%% @doc 
%%% 
%%% @end 
%%% Created :  4 Jun 2010 by Liangliang <Liangliang@gmail.com> 
%%%------------------------------------------------------------------- 
-module(mod_map_actor). 
 
-include("mgeem.hrl"). 
 
%% API 
-export([ 
         handle/2, 
         do_enter/7,
         do_dead/3,
         do_quit/3,
         do_quit/4,
		 do_mirror_quit/3
        ]). 

%% 内部接口，进程字典实现
-export([ 
         get_actor_mapinfo/2, 
         set_actor_mapinfo/3, 
         get_actor_pos/2, 
         set_actor_pos/6, 
         get_actor_slice/2, 
         set_actor_slice/3,
         erase_actor_pid_lastwalkpath/2,
         set_actor_pid_lastwalkpath/3,
         erase_actor_pid_lastkeypath/2,
         set_actor_pid_lastkeypath/3,
         set_actor_pos_after_dir_change/3
        ]).

%%地图跳转相关
-export([
         do_change_map_quit/7,
         same_map_change_pos/6,
         same_map_change_pos/8,
         is_change_map_quit/1
        ]).

-export([
         auto_recover/2,
         get_actor_txty_by_id/2,
         deref_tile_pos/4, 
         ref_tile_pos/4, 
         slice_get_roles/1, 
         slice_get_monsters/1, 
         slice_get_server_npc/1,
         slice_join/3, 
         slice_leave/3, 
         update_slice_by_txty/7, 
         update_slice_by_txty/5, 
         get_unref_pos/4, 
         init_in_map_role/0, 
         get_in_map_role/0, 
         clear_other_faction_role/0,
         get_map_qq_yvip/1
        ]). 
 
-define(in_map_role, in_map_role). 
-define(change_map_quit, change_map_quit). 
 
handle(Info, State) -> 
    do_handle(Info, State). 
 
%%================================二级常用API============================= 
 
get_actor_txty_by_id(RoleID, role) -> 
    case get_actor_mapinfo(RoleID, role) of 
        undefined -> 
            undefined; 
        #p_map_role{pos=#p_pos{tx=TX, ty=TY}} -> 
            {TX, TY} 
    end;
get_actor_txty_by_id(MonsterID, monster) -> 
    case get_actor_mapinfo(MonsterID, monster) of 
        undefined -> 
            undefined; 
        #p_map_monster{pos=#p_pos{tx=TX, ty=TY}} -> 
            {TX, TY} 
    end; 
get_actor_txty_by_id(ID, ybc) -> 
    case get_actor_mapinfo(ID, ybc) of 
        undefined -> 
            undefined; 
        #p_map_ybc{pos=#p_pos{tx=TX, ty=TY}} -> 
            {TX, TY} 
    end; 
get_actor_txty_by_id(ID, server_npc) -> 
    case get_actor_mapinfo(ID, server_npc) of 
        undefined -> 
            undefined; 
        #p_map_server_npc{pos=#p_pos{tx=TX, ty=TY}} -> 
            {TX, TY} 
    end; 
get_actor_txty_by_id(ID, pet) -> 
    case get_actor_mapinfo(ID, pet) of 
        undefined -> 
            undefined; 
        #p_map_pet{role_id=RoleID} -> 
            get_actor_txty_by_id(RoleID, role) 
    end. 
 
%%设置actor在地图中的基本信息 
set_actor_mapinfo(ActorID, ActorType, undefined) -> 
    ?ERROR_MSG("set_actor_mapinfo when mapinfo is undefined ~w ~w",[ActorID, ActorType]); 
set_actor_mapinfo(RoleID, role, ActorMapInfo) -> 
    erlang:put({map_roleinfo, RoleID}, ActorMapInfo); 
set_actor_mapinfo(ID, ybc, MapInfo) -> 
    erlang:put({ybc_mapinfo, ID}, MapInfo); 
set_actor_mapinfo(MonsterID, monster, ActorMapInfo) -> 
    erlang:put({map_monsterinfo, MonsterID}, ActorMapInfo); 
set_actor_mapinfo(ServerNpcId,server_npc,ActorMapInfo) -> 
    erlang:put({map_server_npc_info,ServerNpcId},ActorMapInfo); 
set_actor_mapinfo(PetID,pet,ActorMapInfo) ->
    erlang:put({map_pet_info,PetID},ActorMapInfo).
 
get_actor_mapinfo(RoleID, role) ->
    erlang:get({map_roleinfo, RoleID});
get_actor_mapinfo(ID, ybc) -> 
    erlang:get({ybc_mapinfo, ID}); 
get_actor_mapinfo(MonsterID, monster) -> 
    erlang:get({map_monsterinfo, MonsterID}); 
get_actor_mapinfo(ServerNpcId,server_npc) -> 
    erlang:get({map_server_npc_info,ServerNpcId}); 
get_actor_mapinfo(PetID,pet) -> 
    erlang:get({map_pet_info,PetID}). 
 
erase_actor_mapinfo(RoleID, role) ->
    erlang:erase({map_roleinfo, RoleID});
erase_actor_mapinfo(MonsterID, monster) -> 
    erlang:erase({map_monsterinfo, MonsterID}); 
erase_actor_mapinfo(ID, ybc) -> 
    erlang:erase({ybc_mapinfo, ID}); 
erase_actor_mapinfo(ServerNpcId, server_npc) -> 
    erlang:erase({map_server_npc_info,ServerNpcId}); 
erase_actor_mapinfo(PetID, pet) -> 
    erlang:erase({map_pet_info,PetID}).
 
get_map_qq_yvip(RoleID) ->
    {ok, IsYellowVip, IsYellowYearVip, YellowVipLevel} = mod_qq_cache:get_vip(RoleID),
    case IsYellowVip of 
        true when IsYellowYearVip ->
            QQYvip = YellowVipLevel + 100;
        true when (not IsYellowYearVip) ->
            QQYvip = YellowVipLevel;
        false -> QQYvip = 0
    end,
    QQYvip.
 
%%获得、设置actor所在的位置，包括位置 
get_actor_pos(RoleID, role) -> 
    case get_actor_mapinfo(RoleID, role) of 
        undefined -> 
            undefined; 
        #p_map_role{pos=Pos} -> 
            Pos 
    end;
get_actor_pos(MonsterID, monster) -> 
    case get_actor_mapinfo(MonsterID, monster) of 
        undefined -> 
            undefined; 
        #p_map_monster{pos=Pos} -> 
            Pos 
    end; 
get_actor_pos(YbcID, ybc) -> 
    case get_actor_mapinfo(YbcID, ybc) of 
        undefined -> 
            undefined; 
        #p_map_ybc{pos=Pos} -> 
            Pos 
    end; 
get_actor_pos(ServerNpcId,server_npc) -> 
    case get_actor_mapinfo(ServerNpcId,server_npc) of 
        undefined -> 
            undefined; 
        #p_map_server_npc{pos = Pos} -> 
            Pos 
    end; 
get_actor_pos(PetID,pet) -> 
    case get_actor_mapinfo(PetID,pet) of 
        undefined -> 
            undefined; 
        #p_map_pet{role_id = RoleID} -> 
            %%异兽的位置和其主人的位置一样 
            get_actor_pos(RoleID,role) 
    end. 
 
set_actor_pos(RoleID, role, TX, TY, DIR, SliceChange) -> 
    OldRoleMapInfo = get_actor_mapinfo(RoleID,role), 
    #p_pos{tx=OldTX, ty=OldTY} = OldRoleMapInfo#p_map_role.pos, 
    LastWalkPath = OldRoleMapInfo#p_map_role.last_walk_path, 
    case LastWalkPath =:= undefined of 
        true -> 
            LastWalkPath2 = LastWalkPath; 
        _ -> 
            Path = LastWalkPath#p_walk_path.path, 
            Path2 = get_new_walk_path(Path, #p_map_tile{tx=TX, ty=TY}), 
            LastWalkPath2 = LastWalkPath#p_walk_path{path=Path2} 
    end, 
    deref_tile_pos(RoleID, role, OldTX, OldTY), 
    ref_tile_pos(RoleID, role, TX, TY), 
    NewRoleMapInfo = OldRoleMapInfo#p_map_role{pos=#p_pos{tx=TX, ty=TY, dir=DIR}, last_walk_path=LastWalkPath2},
    case SliceChange of 
        true ->
            mod_role_tab:update_element(RoleID, p_role_pos, [
                {#p_role_pos.pos, #p_pos{tx=TX, ty=TY, dir=DIR} }
            ]),
            mod_role_tab:update_element(RoleID, p_role_fight, [
                {#p_role_fight.hp, NewRoleMapInfo#p_map_role.hp},
                {#p_role_fight.mp, NewRoleMapInfo#p_map_role.mp}
            ]);
        false -> 
            ignore 
    end, 
    set_actor_mapinfo(RoleID,role,NewRoleMapInfo); 
set_actor_pos(MonsterID, monster, TX, TY, DIR, _SliceChange) -> 
    OldMonsterMapInfo = get_actor_mapinfo(MonsterID,monster), 
    #p_pos{tx=OldTX, ty=OldTY} = OldMonsterMapInfo#p_map_monster.pos, 
    deref_tile_pos(MonsterID, monster, OldTX, OldTY), 
    ref_tile_pos(MonsterID, monster, TX, TY), 
    Pos = #p_pos{tx=TX, ty=TY, dir=DIR}, 
    NewMonsterMapInfo = OldMonsterMapInfo#p_map_monster{pos = Pos}, 
    set_actor_mapinfo(MonsterID,monster,NewMonsterMapInfo); 
set_actor_pos(ID, ybc, TX, TY, DIR, SilceChange) -> 
    OldMapInfo = get_actor_mapinfo(ID, ybc), 
    #p_pos{tx=OldTX, ty=OldTY} = OldMapInfo#p_map_ybc.pos, 
    deref_tile_pos(ID, ybc, OldTX, OldTY), 
    ref_tile_pos(ID, ybc, TX, TY), 
    Pos = #p_pos{tx=TX, ty=TY, dir=DIR}, 
    NewMapInfo = OldMapInfo#p_map_ybc{pos=Pos}, 
    case SilceChange of 
        true -> 
            mod_map_ybc:update_ybc_info(ID, NewMapInfo); 
        false -> 
            ignore 
    end, 
    set_actor_mapinfo(ID, ybc, NewMapInfo); 
set_actor_pos(ServerNpcId,server_npc,TX,TY,DIR,_SliceChange) -> 
    OldServerNpcMapInfo = get_actor_mapinfo(ServerNpcId,server_npc), 
    #p_pos{tx=OldTX,ty=OldTY} = OldServerNpcMapInfo#p_map_server_npc.pos, 
    deref_tile_pos(ServerNpcId, server_npc, OldTX, OldTY), 
    ref_tile_pos(ServerNpcId, server_npc, TX, TY), 
    Pos = #p_pos{tx=TX, ty=TY, dir=DIR}, 
    NewServerNpcMapInfo = OldServerNpcMapInfo#p_map_server_npc{pos = Pos}, 
    set_actor_mapinfo(ServerNpcId,server_npc,NewServerNpcMapInfo); 
set_actor_pos(_PetID,pet,_TX,_TY,_DIR,_SliceChange) -> 
    ok.
 
erase_actor_week(ActorID, ActorType) ->
	mod_buff:del_week(ActorType, ActorID).

erase_actor_pos(RoleID, role) -> 
    case get_actor_pos(RoleID, role) of 
        undefined -> 
            ok; 
        #p_pos{tx=TX, ty=TY} -> 
            deref_tile_pos(RoleID, role, TX, TY), 
            erase(RoleID) 
    end;
erase_actor_pos(MonsterID, monster) -> 
    case get_actor_pos(MonsterID, monster) of 
        undefined -> 
            ok; 
        #p_pos{tx=TX, ty=TY} -> 
            deref_tile_pos(MonsterID, monster, TX, TY), 
            erase(MonsterID) 
    end; 
erase_actor_pos(YbcID, ybc) -> 
    case get_actor_pos(YbcID, ybc) of 
        undefined -> 
            ok; 
        #p_pos{tx=TX, ty=TY} -> 
            deref_tile_pos(YbcID, ybc, TX, TY), 
            erase(YbcID) 
     end; 
erase_actor_pos(ServerNpcId,server_npc) -> 
    case get_actor_pos(ServerNpcId, server_npc) of 
        undefined -> 
            ok; 
        #p_pos{tx=TX, ty=TY} -> 
            deref_tile_pos(ServerNpcId, server_npc, TX, TY), 
            erase(ServerNpcId) 
    end; 
erase_actor_pos(_PetID, pet) -> 
    ok. 
 
%%为格子打上标记以便标示是否已经有人站在一个格子上了 
deref_tile_pos(ActorID, ActorType, TX, TY) -> 
    case get({ref, TX, TY}) of 
        [] -> 
            ignore; 
		undefined -> 
            ignore; 
        List -> 
            New = lists:delete({ActorType, ActorID}, List), 
            put({ref, TX, TY}, New)
    end. 
ref_tile_pos(ActorID, ActorType, TX, TY) -> 
    case get({ref,TX,TY}) of 
        undefined -> 
             put({ref, TX, TY}, [{ActorType,ActorID}]); 
        List -> 
            case lists:member({ActorType, ActorID}, List) of 
                true -> 
                    New = List; 
                false -> 
                    New = [{ActorType, ActorID}|List] 
            end, 
            put({ref, TX, TY}, New) 
    end. 
 
 
slice_join(SliceName,RoleID,role) -> 
    case get({slice_role,SliceName}) of 
        undefined -> 
            put({slice_role,SliceName},[RoleID]); 
        List -> 
            put({slice_role,SliceName},[RoleID|List]) 
    end; 
slice_join(SliceName, ID, ybc) -> 
    L = slice_get_ybcs(SliceName), 
    case lists:member(ID, L) of 
        true -> 
            ignore; 
        false -> 
            erlang:put({slice_ybc, SliceName}, [ID | L]) 
    end; 
slice_join(SliceName,MonsterID,monster) -> 
    case get({slice_monster,SliceName}) of 
        undefined -> 
            put({slice_monster,SliceName},[MonsterID]); 
        List -> 
            put({slice_monster,SliceName},[MonsterID|List]) 
    end; 
slice_join(SliceName,ServerNpcId,server_npc) -> 
    case get({slice_server_npc,SliceName}) of 
        undefined -> 
            put({slice_server_npc,SliceName},[ServerNpcId]); 
        List -> 
            put({slice_server_npc,SliceName},[ServerNpcId|List]) 
    end;
slice_join(SliceName,PetID,pet) -> 
    case get({slice_pet,SliceName}) of 
        undefined -> 
            put({slice_pet,SliceName},[PetID]); 
        List -> 
            put({slice_pet,SliceName},[PetID|List]) 
    end. 
 
 
slice_leave(SliceName,RoleID,role) -> 
    case get({slice_role,SliceName}) of 
        undefined -> 
            ?INFO_MSG("role slice_leave error ~w ~w ",[SliceName,RoleID]); 
        List -> 
            put({slice_role,SliceName},my_list_delete(RoleID,List)) 
    end;
slice_leave(SliceName, ID, ybc) -> 
    erlang:put({slice_ybc, SliceName}, my_list_delete(ID, slice_get_ybcs(SliceName))); 
slice_leave(SliceName,MonsterID,monster) -> 
    case get({slice_monster,SliceName}) of 
        undefined -> 
            ?INFO_MSG("monster slice_leave error ~w ~w ",[SliceName,MonsterID]); 
        List -> 
            put({slice_monster,SliceName},my_list_delete(MonsterID,List)) 
    end; 
slice_leave(SliceName,ServerNpcId,server_npc) -> 
    case get({slice_server_npc,SliceName}) of 
        undefined -> 
            ?INFO_MSG("server_npc slice_leave error ~w ~w ",[SliceName,ServerNpcId]); 
        List -> 
            put({slice_server_npc,SliceName},my_list_delete(ServerNpcId,List)) 
    end; 
slice_leave(SliceName,PetID,pet) -> 
    case get({slice_pet,SliceName}) of 
        undefined -> 
            ?INFO_MSG("pet slice_leave error ~w ~w ",[SliceName,PetID]); 
        List -> 
            put({slice_pet,SliceName},my_list_delete(PetID,List)) 
    end. 
 
my_list_delete(Elem,List) when is_integer(Elem) -> 
    NewList = lists:delete(Elem, List), 
    case lists:member(Elem, NewList) of 
        false -> 
            NewList; 
        _ -> 
            my_list_delete(Elem, NewList) 
    end. 
 
slice_get_roles(SliceName) -> 
    case erlang:get({slice_role,SliceName}) of
        undefined -> [];
        Ret -> Ret
    end.
slice_get_monsters(SliceName) -> 
    erlang:get({slice_monster,SliceName}). 
slice_get_ybcs(SliceName) -> 
    case erlang:get({slice_ybc, SliceName}) of
	undefined ->
		[];
	List ->
		List
	end. 
slice_get_server_npc(SliceName) -> 
    erlang:get({slice_server_npc,SliceName}). 
slice_get_pets(SliceName) -> 
    erlang:get({slice_pet,SliceName}).
 
 
%%设置、获取以及删除actor所在的slice 
set_actor_slice(ActorID, role, Slice) -> 
    put({slice_role, ActorID}, Slice);
set_actor_slice(ActorID, ybc, Slice) -> 
    erlang:put({slice_ybc, ActorID}, Slice); 
set_actor_slice(ActorID, monster, Slice) -> 
    put({slice_monster, ActorID}, Slice); 
set_actor_slice(ServerNpcId,server_npc,Slice) -> 
    put({slice_server_npc, ServerNpcId}, Slice); 
set_actor_slice(PetID,pet,Slice) -> 
    put({slice_pet, PetID}, Slice).
 
get_actor_slice(ActorID, role) -> 
    get({slice_role, ActorID}); 
get_actor_slice(ActorID, ybc) -> 
    erlang:get({slice_ybc, ActorID}); 
get_actor_slice(ActorID, monster) -> 
    get({slice_monster, ActorID}); 
get_actor_slice(ServerNpcId, server_npc) -> 
    get({slice_server_npc, ServerNpcId}); 
get_actor_slice(PetID, pet) -> 
    get({slice_pet, PetID}). 
 
erase_actor_slice(ActorID, role) -> 
    erase({slice_role, ActorID});
erase_actor_slice(ActorID, ybc) -> 
    erlang:erase({slice_ybc, ActorID}); 
erase_actor_slice(ActorID, monster) -> 
    erase({slice_monster, ActorID}); 
erase_actor_slice(ServerNpcId, server_npc) -> 
    erase({slice_server_npc, ServerNpcId}); 
erase_actor_slice(PetID, pet) -> 
    erase({slice_pet, PetID}). 
 
get_unref_pos(DestPos,10,_,_) -> 
    DestPos; 
get_unref_pos(DestPos,0,Dis1,Dis2) -> 
    #p_pos{tx=TX, ty=TY} = DestPos, 
    case get({ref,TX,TY}) of
		undefined -> 
            DestPos; 
        [] -> 
            DestPos; 
        _ -> 
            get_unref_pos2(DestPos,0,Dis1,Dis2) 
    end; 
get_unref_pos(DestPos,Num,Dis1,Dis2) -> 
    get_unref_pos2(DestPos,Num,Dis1,Dis2). 
 
get_unref_pos2(DestPos,Num,Dis1,Dis2) -> 
    #p_pos{tx=TX, ty=TY} = DestPos, 
    AddTX = random:uniform(Dis1), 
    AddTY = random:uniform(Dis1), 
    NewTX = TX + AddTX - Dis2, 
    NewTY = TY + AddTY - Dis2, 
    case mcm:safe_type(mgeem_map:get_mapid(), {NewTX, NewTY}) of 
        undefined -> 
            get_unref_pos(DestPos,Num+1,Dis1,Dis2); 
        _ -> 
            case get({ref,NewTX,NewTY}) of 
				undefined -> 
            		DestPos#p_pos{tx = NewTX,ty = NewTY}; 
                [] -> 
                    DestPos#p_pos{tx = NewTX,ty = NewTY}; 
                _ -> 
                    get_unref_pos(DestPos,Num+1,Dis1,Dis2) 
            end 
    end. 
 
slice_enter(RoleID, DelSlices, NewSlices, RoleListForDel, RoleListForNew) -> 
	slice_enter(RoleID, DelSlices, NewSlices, RoleListForDel, RoleListForNew, undefined, undefined).
slice_enter(RoleID, DelSlices, NewSlices, RoleListForDel, RoleListForNew, MonsterForDel, ServerNpcForDel) -> 
    Module = ?MAP, 
    Method = ?MAP_SLICE_ENTER, 
    Monsters = lists:foldr(fun(Slice,Acc) -> lists:append(slice_get_monsters(Slice),Acc) end,[], NewSlices), 
    AllStall = get_dolls_by_slice_list(NewSlices), 
    AllDropthing = mod_map_drop:get_dropthing_by_slice_list(RoleID,NewSlices),
    AllCollect = mod_map_collect:get_collect_by_slice_list(NewSlices), 
    RoleMapInfos = get_actor_mapinfo_by_idlist(RoleListForNew,role, NewSlices),
    MonsterMapInfos = get_actor_mapinfo_by_idlist(Monsters,monster,NewSlices), 
    YbcIDs = lists:foldr(fun(Slice,Acc) -> lists:append(slice_get_ybcs(Slice),Acc) end, [], NewSlices), 
    Ybcs = lists:foldl( 
             fun(YbcID, Acc) -> 
                     case get_actor_mapinfo(YbcID, ybc) of 
                         undefined -> 
                             Acc; 
                         YbcMapInfo -> 
                             [YbcMapInfo | Acc] 
                     end 
             end, [], YbcIDs), 
    %% add by caochuncheng Server NPC模型 
    ServerNpcIdList = lists:foldr(fun(Slice,Acc) -> lists:append(slice_get_server_npc(Slice),Acc) end,[], NewSlices), 
    MapServerNpcInfos = get_actor_mapinfo_by_idlist(ServerNpcIdList,server_npc,NewSlices), 
    PetIDList = lists:foldr(fun(Slice,Acc) -> lists:append(slice_get_pets(Slice),Acc) end,[], NewSlices), 
    MapPetInfos = get_actor_mapinfo_by_idlist(PetIDList,pet,NewSlices), 
	
    DelMonsters1 = lists:foldl(fun(Slice,Acc) -> lists:append(slice_get_monsters(Slice),Acc) end,[], DelSlices), 
	DelMonsters = lists:delete(MonsterForDel, DelMonsters1),
    DelServerNpcs1 = lists:foldl(fun(Slice,Acc) -> lists:append(slice_get_server_npc(Slice),Acc) end,[], DelSlices), 
	DelServerNpcs = lists:delete(ServerNpcForDel, DelServerNpcs1),
    DelYbcs = lists:foldr(fun(Slice,Acc) -> lists:append(slice_get_ybcs(Slice),Acc) end, [], DelSlices), 
    DelPets =  lists:foldl(fun(Slice,Acc) -> lists:append(slice_get_pets(Slice),Acc) end,[], DelSlices), 
    DelPets2 = lists:delete(mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}), DelPets), 
    DelStalls = [ ID||#p_map_doll{role_id=ID}<-get_dolls_by_slice_list(DelSlices) ], 
    DelDropthings = [ ID||#p_map_dropthing{id=ID}<-mod_map_drop:get_dropthing_by_slice_list(RoleID,DelSlices) ],
    DelGrafts = [ ID||#p_map_collect{id=ID}<-mod_map_collect:get_collect_by_slice_list(DelSlices) ], 
    
    DataRecord = #m_map_slice_enter_toc{return_self=true, roles=RoleMapInfos, monsters=MonsterMapInfos, 
                                        server_npcs = MapServerNpcInfos, ybcs=Ybcs, pets = MapPetInfos, 
                                        dropthings = AllDropthing,grafts=AllCollect, dolls=AllStall, 
                                        del_roles=RoleListForDel, del_monsters=DelMonsters, 
                                        del_server_npcs=DelServerNpcs, del_ybcs=DelYbcs, del_dolls=DelStalls, 
                                        del_dropthings=DelDropthings, del_grafts=DelGrafts, del_pets=DelPets2 
                                       }, 
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, Module, Method, DataRecord). 
 
update_slice_by_txty(ActorID,ActorType, NewTX, NewTY, DIR) -> 
    State = mgeem_map:get_state(), 
    OffsetX = State#map_state.offsetx, 
    OffsetY = State#map_state.offsety, 
    update_slice_by_txty(ActorID,ActorType, NewTX, NewTY, OffsetX, OffsetY, DIR). 
 
 
%%根据玩家当前所在位置更新slice 
update_slice_by_txty(ActorID,ActorType, NewTX, NewTY, OffsetX, OffsetY, DIR) -> 
    NewSlice = mgeem_map:get_slice_by_txty(NewTX, NewTY, OffsetX, OffsetY), 
    case get_actor_slice(ActorID, ActorType) of 
        undefined -> 
            set_actor_slice(ActorID, ActorType, NewSlice), 
            slice_join(NewSlice, ActorID, ActorType), 
            set_actor_pos(ActorID, ActorType, NewTX, NewTY, DIR, true); 
        OldSlice -> 
            if 
                NewSlice =/= OldSlice -> 
                    SliceChange = true, 
                    %% 在这里通知客户端actor的变化：哪些离开了、哪些进入了 
                    do_slice_change_notify(ActorID, ActorType, NewTX, NewTY, NewSlice, OldSlice, OffsetX, OffsetY), 
                    set_actor_slice(ActorID, ActorType, NewSlice), 
                    slice_join(NewSlice, ActorID, ActorType), 
                    slice_leave(OldSlice, ActorID, ActorType), 
					if 
						ActorType == role -> 
							case mod_map_pet:get_summoned_pet_info(ActorID) of 
								undefined -> 
									ignore; 
								{PetID,_PetInfo} -> 
									set_actor_slice(PetID, pet, NewSlice), 
									slice_join(NewSlice, PetID, pet), 
									slice_leave(OldSlice, PetID, pet) 
							end; 
						true -> 
							ignore 
					end; 
                true -> 
                    SliceChange = false, 
                    ignore 
            end, 
            set_actor_pos(ActorID, ActorType, NewTX, NewTY, DIR, SliceChange) 
    end. 
 
 
%% 任何actor的slice发生变化后都需要通知客户端：某个actor进入你的九宫格、某些actor退出了你的九宫格 
do_slice_change_notify(ActorID, ActorType, TX, TY, _NewSlice, _OldSlice, OffsetX, OffsetY) -> 
    #p_pos{tx=OldTX, ty=OldTY} = get_actor_pos(ActorID, ActorType), 
    AllSliceOld = mgeem_map:get_9_slice_by_txty(OldTX,OldTY,OffsetX,OffsetY), 
    AllSliceNew = mgeem_map:get_9_slice_by_txty(TX, TY, OffsetX, OffsetY), 
 
    NewSlices = lists:filter( 
                  fun(T) -> 
                          case lists:member(T, AllSliceOld) of 
                              true -> 
                                  false; 
                              false -> 
                                  true 
                          end 
                  end, AllSliceNew), 
    DelSlices = lists:filter( 
                  fun(T) -> 
                          case lists:member(T, AllSliceNew) of 
                              true -> 
                                  false; 
                              false -> 
                                  true 
                          end 
                  end, AllSliceOld), 
    %% 通知DelSlices 里面的人删除掉我 
    RoleListForDel = mgeem_map:get_all_in_sence_user_by_slice_list(DelSlices), 
     %% 通知NewSlices 里面的人我来了 
    RoleListForNew = mgeem_map:get_all_in_sence_user_by_slice_list(NewSlices), 
    case ActorType of 
        monster -> 
            RD = #m_map_slice_enter_toc{del_monsters=[ActorID]}, 
            mgeem_map:broadcast(RoleListForDel, ?DEFAULT_UNIQUE, ?MAP, ?MAP_SLICE_ENTER, RD), 
            MapInfo = get_actor_mapinfo(ActorID, ActorType), 
            
            #p_map_monster{hp=Hp,max_hp=MaxHp} = MapInfo,
            MapInfo2 = MapInfo#p_map_monster{hp=trunc(Hp),max_hp=trunc(MaxHp)},
            
            RN = #m_map_slice_enter_toc{monsters=[MapInfo2]}, 
            mgeem_map:broadcast(RoleListForNew, ?DEFAULT_UNIQUE, ?MAP, ?MAP_SLICE_ENTER, RN); 
        ybc -> 
            RD = #m_map_slice_enter_toc{del_ybcs=[ActorID]}, 
            mgeem_map:broadcast(RoleListForDel, ?DEFAULT_UNIQUE, ?MAP, ?MAP_SLICE_ENTER, RD), 
            MapInfo = get_actor_mapinfo(ActorID, ActorType), 
            RN = #m_map_slice_enter_toc{ybcs=[MapInfo]}, 
            mgeem_map:broadcast(RoleListForNew, ?DEFAULT_UNIQUE, ?MAP, ?MAP_SLICE_ENTER, RN); 
        role -> 
            {PetIDs,PetMapInfos} = mod_map_pet:get_role_pet_map_info_list(ActorID), 
            RD = #m_map_slice_enter_toc{del_roles=[ActorID],del_pets=PetIDs}, 
            mgeem_map:broadcast(RoleListForDel, ?DEFAULT_UNIQUE, ?MAP, ?MAP_SLICE_ENTER, RD), 
            MapInfo = get_actor_mapinfo(ActorID, ActorType), 
            MapInfo2 = MapInfo#p_map_role{pos=#p_pos{tx=TX, ty=TY, dir=2}}, 
            RN = #m_map_slice_enter_toc{roles=[MapInfo2],pets=PetMapInfos}, 
            mgeem_map:broadcast(RoleListForNew, ?DEFAULT_UNIQUE, ?MAP, ?MAP_SLICE_ENTER, RN), 
            %% 如果是玩家则特殊处理 
            slice_enter(ActorID, DelSlices, NewSlices, RoleListForDel, RoleListForNew);
        server_npc -> 
            RD = #m_map_slice_enter_toc{del_server_npcs=[ActorID]}, 
            mgeem_map:broadcast(RoleListForDel, ?DEFAULT_UNIQUE, ?MAP, ?MAP_SLICE_ENTER, RD), 
            MapInfo = get_actor_mapinfo(ActorID, ActorType), 
            RN = #m_map_slice_enter_toc{server_npcs=[MapInfo]}, 
            mgeem_map:broadcast(RoleListForNew, ?DEFAULT_UNIQUE, ?MAP, ?MAP_SLICE_ENTER, RN); 
        pet -> 
            RD = #m_map_slice_enter_toc{del_pets=[ActorID]}, 
            mgeem_map:broadcast(RoleListForDel, ?DEFAULT_UNIQUE, ?MAP, ?MAP_SLICE_ENTER, RD), 
            MapInfo = get_actor_mapinfo(ActorID, ActorType), 
            RN = #m_map_slice_enter_toc{pets=[MapInfo]}, 
            mgeem_map:broadcast(RoleListForNew, ?DEFAULT_UNIQUE, ?MAP, ?MAP_SLICE_ENTER, RN)
    end, 
    ok. 
 
 
record_role_in_map(ActorID) -> 
    L = get_in_map_role(),
    case lists:member(ActorID, L) of
        true ->
            ignore;
        false ->
            erlang:put(?in_map_role, [ActorID | L])
    end.
record_role_out_map(ActorID) -> 
    L = erlang:get(?in_map_role), 
    erlang:put(?in_map_role, lists:delete(ActorID, L)).
 
init_in_map_role() -> 
    erlang:put(?in_map_role, []). 
get_in_map_role() -> 
    case erlang:get(?in_map_role) of
        undefined -> [];
        Ret -> Ret
    end.
 
 
%%玩家进入地图后注册玩家的信息，都是通过进程字典来是实现的 
register_actor(Pid, ActorID, ActorType, ActorMapInfo, Slice) -> 
    set_actor_mapinfo(ActorID, ActorType, ActorMapInfo), 
    case ActorType of 
		role when Pid == mirror -> 
			erlang:put({pid_to_roleid, Pid}, ActorID),
			put({roleid_to_pid,ActorID},Pid),
			mod_mirror:register({role, ActorID}),
            #p_pos{tx=TX, ty=TY, dir=DIR} = ActorMapInfo#p_map_role.pos;
        role -> 
            erlang:put({role_msg_queue, Pid}, []),
			erlang:put({pid_to_roleid, Pid}, ActorID),
			put({roleid_to_pid,ActorID},Pid), 
			record_role_in_map(ActorID), 
			#p_pos{tx=TX, ty=TY, dir=DIR} = ActorMapInfo#p_map_role.pos;
        monster -> 
            #p_pos{tx=TX, ty=TY, dir=DIR} = ActorMapInfo#p_map_monster.pos; 
        ybc -> 
            #p_pos{tx=TX, ty=TY, dir=DIR} = ActorMapInfo#p_map_ybc.pos; 
        server_npc -> 
            #p_pos{tx=TX, ty=TY, dir=DIR} = ActorMapInfo#p_map_server_npc.pos; 
        pet when Pid == mirror ->
			mod_mirror:register({pet, ActorID}),
            #p_pos{tx=TX, ty=TY, dir=DIR} = ActorMapInfo#p_map_pet.pos;
		pet -> 
            #p_pos{tx=TX, ty=TY, dir=DIR} = ActorMapInfo#p_map_pet.pos
    end, 
    set_actor_pos(ActorID, ActorType, TX, TY, DIR, true), 
    set_actor_slice(ActorID, ActorType, Slice). 
 
 
%% actor退出地图时要清理一些数据 
unregister_actor(ActorID, ActorType) -> 
    ?TRY_CATCH( unregister_actor_catch(ActorID, ActorType) ),
	erase_actor_week(ActorID, ActorType),
    erase_actor_pos(ActorID, ActorType), 
    erase_actor_slice(ActorID, ActorType), 
    erase_actor_mapinfo(ActorID, ActorType), 
    erase_actor_skill_time(ActorID, ActorType).

unregister_actor_catch(ActorID, ActorType) ->
	case ActorType of
		role ->
			case mod_mirror:is_mirror(ActorType, ActorID) of
				false ->
					record_role_out_map(ActorID),
					mod_map_role:clear_dict_info(ActorID);
				true ->
					ignore
			end;
		_ ->
			nil
	end.
 
%% @doc 同个地图跳转 
%% ChangeType: 1、普通跳转，2、冲锋 
same_map_change_pos(ActorID, ActorType, TX, TY, ChangeType, State) -> 
	same_map_change_pos(ActorID, ActorType, TX, TY, ChangeType, State, undefined, undefined).
same_map_change_pos(ActorID, ActorType, TX, TY, ChangeType, State, DestActorID, DestActorType) -> 
    case get_actor_mapinfo(ActorID, ActorType) of 
        undefined -> 
            error; 
        MapInfo -> 
            {TX2, TY2} = get_empty_pos_around(State#map_state.mapid, TX, TY), 
            case ActorType of 
                role -> 
                    Pos = MapInfo#p_map_role.pos, 
                    Pos2 = Pos#p_pos{tx=TX2, ty=TY2}, 
                    case ChangeType of 
                        ?CHANGE_POS_TYPE_RELIVE -> 
                            MapInfo2 = MapInfo#p_map_role{state=?ROLE_STATE_NORMAL, last_walk_path=undefined, pos=Pos2}; 
                        _ -> 
                            MapInfo2 = MapInfo#p_map_role{last_walk_path=undefined, pos=Pos2} 
                    end, 
 
                    DataRecord = #m_map_change_pos_toc{tx=TX2, ty=TY2, change_type=ChangeType}, 
                    common_misc:unicast({role, ActorID}, ?DEFAULT_UNIQUE, ?MAP, ?MAP_CHANGE_POS, DataRecord); 
                monster -> 
                    Pos = MapInfo#p_map_monster.pos, 
                    Pos2 = Pos#p_pos{tx=TX2, ty=TY2}, 
                    MapInfo2 = MapInfo#p_map_monster{last_walk_path=undefined, pos=Pos2}
            end, 
 
            %% 进入新的slice 
            #map_state{offsetx=OffsetX, offsety=OffsetY} = State, 
 
            #p_pos{tx=OldTX, ty=OldTY} = get_actor_pos(ActorID, ActorType), 
            AllSliceOld = mgeem_map:get_9_slice_by_txty(OldTX, OldTY, OffsetX, OffsetY), 
            AllSliceNew = mgeem_map:get_9_slice_by_txty(TX2, TY2, OffsetX, OffsetY), 
            %% 通知DelSlices 里面的人删除掉我 
            RoleListForDel = mgeem_map:get_all_in_sence_user_by_slice_list(AllSliceOld), 
            %% 通知NewSlices 里面的人我来了 
            RoleListForNew = mgeem_map:get_all_in_sence_user_by_slice_list(AllSliceNew), 
 
            case ActorType of 
				role -> 
					RoleListForDel1 = lists:delete(ActorID,RoleListForDel),
					case ChangeType of 
						?CHANGE_POS_TYPE_CHARGE -> 
							if
								DestActorType =:= role ->
									RoleListForDel2 = lists:delete(DestActorID,RoleListForDel1),
									MonsterForDel2 = ServerNpcForDel2 = undefined;
								DestActorType =:= monster ->
									RoleListForDel2 = RoleListForDel1,
									MonsterForDel2 = DestActorID,
									ServerNpcForDel2 = undefined;
								DestActorType =:= server_npc ->
									RoleListForDel2 = RoleListForDel1,
									MonsterForDel2 = undefined,
									ServerNpcForDel2 = DestActorID;
								true ->
									RoleListForDel2 = RoleListForDel1,
									MonsterForDel2 = ServerNpcForDel2 = undefined
							end;
						_ ->
							MonsterForDel2 = ServerNpcForDel2 = undefined,
							RoleListForDel2 = RoleListForDel1
					end,
                    {PetIDList,MapPets} = mod_map_pet:get_role_pet_map_info_list(ActorID), 
                    RD = #m_map_slice_enter_toc{del_roles=[ActorID],del_pets=PetIDList}, 
                    RN = #m_map_slice_enter_toc{return_self=false, roles=[MapInfo2], pets=MapPets, enter_type=ChangeType, src_pos=MapInfo#p_map_role.pos};
                monster -> 
					MonsterForDel2 = ServerNpcForDel2 = undefined,
                    RoleListForDel2 = RoleListForDel,
                    RD = #m_map_slice_enter_toc{del_monsters=[ActorID]}, 
                    RN = #m_map_slice_enter_toc{monsters=[MapInfo2]}
            end, 
            mgeem_map:broadcast(RoleListForDel2, ?DEFAULT_UNIQUE, ?MAP, ?MAP_SLICE_ENTER, RD), 
            mgeem_map:broadcast(RoleListForNew, ?DEFAULT_UNIQUE, ?MAP, ?MAP_SLICE_ENTER, RN), 
 
            Slice = get_actor_slice(ActorID, ActorType), 
            NewSlice = mgeem_map:get_slice_by_txty(TX2, TY2, OffsetX, OffsetY), 
            %% 获取镖车的位置，提示给玩家 
            case ActorType == role andalso not MapInfo#p_map_role.is_mirror of 
                true -> 
                    mod_map_ybc:notify_role_ybc_pos(ActorID); 
                _ -> 
                    ignore 
            end, 
            case Slice =:= NewSlice of 
                true -> 
                    set_actor_pos(ActorID, ActorType, TX2, TY2, 2, false); 
                _ -> 
                    set_actor_slice(ActorID, ActorType, NewSlice), 
                    slice_join(NewSlice, ActorID, ActorType), 
                    slice_leave(Slice, ActorID, ActorType), 
                    %% 如果是玩家则特殊处理 
                    if 
						ActorType == role -> 
                            case mod_map_pet:get_summoned_pet_info(ActorID) of 
                                undefined -> 
                                    ignore; 
                                {PetID,_PetInfo} -> 
                                    set_actor_slice(PetID, pet, NewSlice), 
                                    slice_join(NewSlice, PetID, pet), 
                                    slice_leave(Slice, PetID, pet) 
                            end, 
                            slice_enter(ActorID, AllSliceOld, AllSliceNew, RoleListForDel2, RoleListForNew, MonsterForDel2, ServerNpcForDel2); 
                        true -> 
                            ignore 
                    end, 
                    set_actor_pos(ActorID, ActorType, TX2, TY2, 2, true) 
            end, 
            set_actor_mapinfo(ActorID, ActorType, MapInfo2) 
    end. 
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 内部API 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
 
 
 
%%无论玩家使用何种方式走路，每经过一格都必须要发一次消息给服务端 
 
do_handle({Unique, ?MAP, ?MAP_UPDATE_ACTOR_MAPINFO, DataIn, RoleID}, _State) -> 
    do_update_actor_mapinfo(Unique, ?MAP, ?MAP_UPDATE_ACTOR_MAPINFO, DataIn, RoleID); 
do_handle({unregister_actor, ActorID, ActorType}, _State) -> 
    unregister_actor( ActorID, ActorType); 

%%玩家从地图上消失前重新登录游戏
do_handle({login_again, RoleID, PID, Line}, MapState) ->
    erlang:monitor(process, PID),
	erlang:put({roleid_to_pid, RoleID}, PID),
	erlang:put({pid_to_roleid, PID}, RoleID),
	erlang:put({role_msg_queue, PID}, []),
	#map_state{mapid=MapID, offsetx=OffsetX, offsety=OffsetY} = MapState,
	RoleMapInfo = get_actor_mapinfo(RoleID, role),
	#p_pos{tx=TX, ty=TY} = RoleMapInfo#p_map_role.pos,
    InSlice      = mgeem_map:get_slice_by_txty(TX, TY, OffsetX, OffsetY),
    AllSlice     = mgeem_map:get_9_slice_by_txty(TX, TY, OffsetX, OffsetY),
    InRoles      = lists:delete(RoleID, slice_get_roles(InSlice)),
    AroundSlices = lists:delete(InSlice, AllSlice),
    AroundRoles  = mgeem_map:get_all_in_sence_user_by_slice_list(AroundSlices),
    Roles        = lists:append([AroundRoles, InRoles]),
    Monsters     = lists:foldr(fun
        (Slice,Acc) -> 
            lists:append(slice_get_monsters(Slice),Acc) 
    end,[],AllSlice),
    YbcIDs = lists:foldr(fun
        (Slice,Acc) -> 
            lists:append(slice_get_ybcs(Slice),Acc) 
    end, [], AllSlice),
    Ybcs = lists:foldl(fun
        (YbcID, Acc) ->
            case get_actor_mapinfo(YbcID, ybc) of
                undefined ->
                    Acc;
                YbcMapInfo ->
                    [YbcMapInfo | Acc]
            end
     end, [], YbcIDs),
    PetIDList = lists:foldr(fun
        (Slice,Acc) -> 
            lists:append(slice_get_pets(Slice),Acc) 
        end,[], AllSlice),
    AllStall        = get_dolls_by_slice_list(AllSlice),
    AllDropthing    = mod_map_drop:get_dropthing_by_slice_list(RoleID,AllSlice),
    AllCollect      = mod_map_collect:get_collect_by_slice_list(AllSlice), 
    RoleMapInfos    = get_actor_mapinfo_by_idlist(Roles,role,AllSlice), 
    MapPetInfos     = get_actor_mapinfo_by_idlist(PetIDList,pet,AllSlice),
    MonsterMapInfos = get_actor_mapinfo_by_idlist(Monsters,monster,AllSlice), 
    ServerNpcIdList = lists:foldr(fun
        (Slice,Acc) -> 
            lists:append(slice_get_server_npc(Slice), Acc) 
    end,[],AllSlice), 
    MapServerNpcInfos = get_actor_mapinfo_by_idlist(ServerNpcIdList,server_npc,AllSlice), 
    {ok, RolePos}     = mod_map_role:get_role_pos_detail(RoleID),
    DataRecord        = #m_map_enter_toc{
        pos           = RolePos, 
        ybcs          = Ybcs,
        pets          = MapPetInfos, 
        dolls         = AllStall, 
        roles         = RoleMapInfos, 
        grafts        = AllCollect,
        monsters      = MonsterMapInfos, 
        dropthings    = AllDropthing, 
        server_npcs   = MapServerNpcInfos, 
        role_map_info = RoleMapInfo
    }, 
    PID ! {sure_enter_map, erlang:self()},
	common_misc:unicast2_direct(PID, ?DEFAULT_UNIQUE, ?MAP, ?MAP_ENTER, DataRecord),
	#p_role_pet_bag{
		summoned_pet_id = SummonedPetID
	} = mod_role_tab:get({?ROLE_PET_BAG_INFO, RoleID}),
	SummonToc = #m_pet_summon_toc{
		pet_info = mod_role_tab:get(RoleID, {?ROLE_PET_INFO, SummonedPetID})
	},
	common_misc:unicast2_direct(PID, ?DEFAULT_UNIQUE, ?PET, ?PET_SUMMON, SummonToc),
	case RoleMapInfo#p_map_role.summoned_pet_id of
		PetID when is_integer(PetID), PetID > 0 ->
			EnterToc = #m_pet_enter_toc{pets = [get_actor_mapinfo(PetID, pet)]},
			common_misc:unicast2_direct(PID, ?DEFAULT_UNIQUE, ?PET, ?PET_ENTER, EnterToc);
		_ ->
			ignore
	end,
	PetBag = #m_pet_bag_info_toc{info=mod_role_tab:get({?ROLE_PET_BAG_INFO, RoleID})},
	common_misc:unicast2_direct(PID, ?DEFAULT_UNIQUE, ?PET, ?PET_BAG_INFO, PetBag),
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	hook_map_role:role_online(RoleID, PID,  
		RoleBase, RoleAttr, MapState#map_state.mapid, Line, false),
	hook_map_role:map_enter(RoleID, RoleMapInfo, MapID),
	mgeer_role:send(RoleID, {role_online, RoleID, false});

%%玩家首次进入地图处理（登陆游戏之后的首次进入地图） 
do_handle({first_enter, {Unique, PID, RoleMapInfo, Line}}, State) ->
    erlang:monitor(process, PID), 
	RoleID = RoleMapInfo#p_map_role.role_id,
	erase({enter, RoleID}),
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    NewRoleMapInfo = if
        RoleAttr#p_role_attr.level > 1 ->
            NewRoleBase = mod_role_attr:recalc(RoleBase, RoleAttr),
            mod_role_attr:reload_role_base(NewRoleBase, false),
            mod_map_role:make_new_map_role(RoleMapInfo, NewRoleBase, RoleAttr);
        true ->
            RoleMapInfo
    end,
    do_enter(Unique, PID, RoleID, role, [{role_map_info, NewRoleMapInfo}], Line, State),
	hook_map_role:role_online(RoleID, PID,  
		RoleBase, RoleAttr, State#map_state.mapid, Line, true),
	mgeer_role:send(RoleID, {role_online, RoleID, true}); 
    
%%玩家每次进入地图处理 
do_handle({enter, Unique, PID, RoleID, RoleMapInfo, Line}, State) -> 
    do_enter(Unique, PID, RoleID, role, RoleMapInfo, Line, State); 
do_handle({ybc_enter, YbcID, YbcMapInfo, YbcMapExt}, State) -> 
    do_enter(0, YbcID, YbcID, ybc, {YbcMapInfo, YbcMapExt}, 0, State); 
%%玩家或者怪物退出地图 
do_handle({quit,ActorID, ActorType}, State) -> 
    do_quit(ActorID, ActorType, State); 
%%玩家或者怪物的死亡处理 
do_handle({dead, ActorID, ActorType}, State) -> 
    do_dead(ActorID, ActorType, State); 
%%设置地图保护时间 -- T除别国玩家 
do_handle({set_map_protected, Key, StartTime, FactionID, ReasonCode}, _State) -> 
    set_map_protected(Key, StartTime, FactionID, ReasonCode); 
 
%% 玩家宗族拉镖召集，王座争霸战召集传送前处理操作 
%% 如取消息在线打坐，即出副本等 
do_handle({change_map_by_call, Type, RoleId}, _State) -> 
    hook_map_role:hook_change_map_by_call(Type,RoleId); 
 
do_handle(Info, State) -> 
    ?ERROR_MSG("~ts:~w, ~w", ["未知的请求信息", Info, State]). 
 
 
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%内部二级API 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
do_change_map_quit(role, ChangeMapType, RoleID, NewMapPName, NewMapID, NewPos, State) -> 
    ?TRY_CATCH( mod_map_ybc:ybc_change_map(ChangeMapType, RoleID, NewMapPName, NewMapID, NewPos) ), 
    set_change_map_quit(RoleID, NewMapID), 
    do_quit(RoleID, role, State). 
 
do_enter(Unique, PID, ActorID, ActorType, MapInfo, Line, State) -> 
	MapID = State#map_state.mapid,
    case ActorType of
		role when PID == mirror -> 
            #p_map_role{pos=#p_pos{tx=TX, ty=TY}} = MapInfo, 
            {TX2, TY2} = get_empty_pos_around(MapID, TX, TY),
            MapInfo3 = MapInfo#p_map_role{pos=#p_pos{tx=TX2, ty=TY2, dir=4}};
        role -> 
            %%如果是角色，则需要注册分线得信息 
            common_misc:set_role_line_by_id(ActorID, Line),
			lists:foreach(fun
				({last_skill_time, LastSkillTime}) ->
				 	mof_fight_time:set_last_skill_time(role, ActorID, LastSkillTime);
				({{map_pet_info,PetID}, MapPetInfo}) ->
				 	set_actor_mapinfo(PetID, pet, MapPetInfo);
                ({gray_time, GrayTime}) when GrayTime > 0 ->
                    GrayRef = erlang:send_after(GrayTime,self(),{mod_map_role, {cancel_gray_name, ActorID}}), 
                    put(gray_name_timer_ref, GrayRef);
                ({pk_time, PKTime}) when PKTime > 0 ->
                    PKPointRef = erlang:send_after(PKTime,self(),{mod_map_role, {reduce_pk_point, ActorID, 1, ?PK_POINT_REDUCE_TYPE_PER_TEN_MIN}}),
                    put(pkpoint_timer_ref, PKPointRef); 
                ({role_state, RoleState}) ->
                    RoleState2 = RoleState#r_role_state2{
                        gray_name_timer_ref = erase(gray_name_timer_ref),
                        pkpoint_timer_ref   = erase(pkpoint_timer_ref)
                    },
                    mod_map_role:set_role_state(ActorID, RoleState2);
				(_) ->
				 	ignore
			end, MapInfo),
            {role_map_info, MapInfo2} = lists:keyfind(role_map_info, 1, MapInfo), 
            ApplyAfterEnterMap = lists:keyfind(apply_after_enter_map, 1, MapInfo),
			MapState = #map_state{mapid=MapID} = mgeem_map:get_state(),
			mgeer_role:send(ActorID, 
                {enter_map, self(), MapState, ApplyAfterEnterMap}),
            #p_map_role{pos=#p_pos{tx=TX, ty=TY}} = MapInfo2, 
            {TX2, TY2} = get_empty_pos_around(MapID, TX, TY),
            MapInfo3 = MapInfo2#p_map_role{pos=#p_pos{tx=TX2, ty=TY2, dir=4}};
        monster -> 
            #p_map_monster{pos=#p_pos{tx=TX2, ty=TY2}} = MapInfo, 
            MapInfo3 = MapInfo; 
        ybc -> 
            {MapInfo3,TX2,TY2} = do_enter_ybc(ActorID,MapInfo); 
        %% add by caochuncheng 添加Server NPC 进入地图显示处理 
		server_npc -> 
			#p_map_server_npc{pos = #p_pos{tx = TX2, ty =TY2}} = MapInfo, 
			MapInfo3 = MapInfo; 
		pet -> 
			#p_map_pet{pos = #p_pos{tx = TX2, ty =TY2}} = MapInfo, 
			MapInfo3 = MapInfo
    end, 
    case mcm:is_walkable(MapID, {TX2, TY2}) of 
        false when ActorType =:= role -> 
            mod_map_role:enter_exception(Unique, PID, ActorID, MapInfo3, Line, State); 
        _ -> 
            Ret = do_enter(Unique, PID, ActorID, ActorType, TX2, TY2, MapInfo3, Line, State), 
            %%异兽要跟随玩家进入新的地图 
			if
				ActorType == role ->
					mod_map_pet:role_pet_enter(MapInfo3); 
                true -> 
                    ignore 
            end, 
            Ret 
    end. 
 
do_enter_ybc(YbcID,MapInfo)-> 
    try 
        do_enter_ybc_2(YbcID,MapInfo) 
    catch 
        _:_Reason-> 
            {YbcMapInfo,_YbcMapExt} = MapInfo, 
            #p_map_ybc{pos=#p_pos{tx=TX2, ty=TY2}} = YbcMapInfo, 
            {YbcMapInfo,TX2,TY2} 
    end. 
 
do_enter_ybc_2(_YbcID,#p_map_ybc{pos=#p_pos{tx=TX2, ty=TY2}}=MapInfo)-> 
    {MapInfo,TX2,TY2}; 
do_enter_ybc_2(YbcID,{YbcMapInfo,YbcMapExt}) when is_record(YbcMapInfo,p_map_ybc)-> 
    #p_map_ybc{pos=#p_pos{tx=TX2, ty=TY2}} = YbcMapInfo, 
    #r_map_ybc_ext{buff_timer_list=BuffTimerList} = YbcMapExt, 
    %%重新设置YBC的buff计时器 
    BuffTimerList2 = lists:foldl(fun(E,Acc)-> 
                                       #r_buff_timer_info{time=Time ,msg=Msg} = E, 
                                       if 
                                           Time>0-> 
                                               BuffTimerRef = erlang:send_after(Time,self(),Msg), 
                                               TimerInfo2 = E#r_buff_timer_info{timer_ref=BuffTimerRef}, 
                                               [TimerInfo2|Acc]; 
                                           true -> 
                                               Acc 
                                       end 
                               end, [], BuffTimerList), 
    mod_ybc_buff:save_buff_timer_list(YbcID,BuffTimerList2), 
 
    {YbcMapInfo,TX2,TY2}. 
 
%%处理进入地图请求 
do_enter(Unique, PID, ActorID, ActorType, TX, TY, MapInfo, Line, State) ->
    #map_state{offsetx=OffsetX, offsety=OffsetY, map_name=MapProcessName, mapid=MapID} = State, 
    %%计算九宫格
    case mgeem_map:get_9_slice_by_txty(TX, TY, OffsetX, OffsetY) of
        undefined ->
            %%直接同步到本地图的出生点？还是直接踢掉？ 
            ignore; 
        AllSlice -> 
            InSlice = mgeem_map:get_slice_by_txty(TX, TY, OffsetX, OffsetY), 
            register_actor(PID, ActorID, ActorType, MapInfo, InSlice),
            %%这里特殊处理，因为可能玩家意外退出（如分线挂）没有推出地图，为避免重复所以先退出slice再 进入slice
            slice_leave(InSlice, ActorID,ActorType), 
            slice_join(InSlice, ActorID,ActorType), 
            case ActorType of 
                role when is_pid(PID) -> 
                    %%更新角色位置及进程名 
                    Pos = MapInfo#p_map_role.pos,
                    mgeem_router:update_role_map_process_name(ActorID, MapProcessName, MapID, Pos), 
					do_enter_role(ActorID, MapInfo, Unique, InSlice, AllSlice, Line, State);
				role when PID == mirror ->
                    do_enter_role(ActorID, MapInfo, Unique, InSlice, AllSlice, Line, State);
                monster ->
                    do_enter_monster(MapInfo, InSlice, AllSlice);
                ybc ->
                    do_enter_ybc(MapInfo, InSlice, AllSlice);
                server_npc ->
                    do_enter_server_npc(MapInfo, InSlice, AllSlice);
                pet ->
                    do_enter_pet(MapInfo, InSlice, AllSlice)
            end,
            ok
    end.
do_enter_role(RoleID, RoleMapInfo, Unique, InSlice, AllSlice, _Line, MapState) ->
	#map_state{mapid=MapID} = MapState,
    Module = ?MAP, 
    Method = ?MAP_ENTER,
    %%获得所在九宫格中的所有玩家
    InRoles = lists:delete(RoleID, slice_get_roles(InSlice)),
    AroundSlices = lists:delete(InSlice, AllSlice),
    AroundRoles = mgeem_map:get_all_in_sence_user_by_slice_list(AroundSlices),
    Roles = lists:append([AroundRoles, InRoles]),
    Monsters = lists:foldr(fun(Slice,Acc) -> lists:append(slice_get_monsters(Slice),Acc) end,[],AllSlice),
    YbcIDs = lists:foldr(fun(Slice,Acc) -> lists:append(slice_get_ybcs(Slice),Acc) end, [], AllSlice),
	Ybcs = lists:foldl(
             fun(YbcID, Acc) ->
                     case get_actor_mapinfo(YbcID, ybc) of
                         undefined ->
                             Acc;
                         YbcMapInfo ->
                             [YbcMapInfo | Acc]
                     end
             end, [], YbcIDs),
    PetIDList = lists:foldr(fun(Slice,Acc) -> lists:append(slice_get_pets(Slice),Acc) end,[], AllSlice),
    MapPetInfos = get_actor_mapinfo_by_idlist(PetIDList,pet,AllSlice),
    %%告诉其他玩家某个人进来了
    DataRecord2 = #m_map_enter_toc{return_self=false, roles=[RoleMapInfo]},
    mgeem_map:broadcast(InRoles, AroundRoles, ?DEFAULT_UNIQUE, Module, Method, DataRecord2),
    %%找出周围所有的摊位
    AllStall = get_dolls_by_slice_list(AllSlice),
    AllDropthing = mod_map_drop:get_dropthing_by_slice_list(RoleID,AllSlice),
    AllCollect = mod_map_collect:get_collect_by_slice_list(AllSlice), 
	RolePos = #p_role_pos{
		role_id	= RoleID,
		map_id	= MapID,
		pos		= RoleMapInfo#p_map_role.pos
    },
    %%发给玩家，告诉玩家周围有哪些人 哪些怪物  哪些摊位  哪些掉落物 
    RoleMapInfos = get_actor_mapinfo_by_idlist(Roles,role,AllSlice), 
    MonsterMapInfos = get_actor_mapinfo_by_idlist(Monsters,monster,AllSlice), 
 
    %% add by caochuncheng Server NPC模型 
    ServerNpcIdList = lists:foldr(fun(Slice,Acc) -> lists:append(slice_get_server_npc(Slice),Acc) end,[],AllSlice), 
	MapServerNpcInfos = get_actor_mapinfo_by_idlist(ServerNpcIdList,server_npc,AllSlice), 
    DataRecord = #m_map_enter_toc{roles = RoleMapInfos, monsters=MonsterMapInfos, 
                                  server_npcs = MapServerNpcInfos, 
                                  grafts=AllCollect,ybcs=Ybcs,pets=MapPetInfos, 
                                  pos=RolePos, dropthings = AllDropthing, dolls=AllStall, role_map_info=RoleMapInfo}, 
    case get({roleid_to_pid,RoleID}) of 
        undefined -> 
            mod_map_role:kick_role(RoleID); 
		mirror ->
			ignore;
        Pid -> 
            Pid ! {sure_enter_map, erlang:self()}, 
            %% Hack 防止进入新场景后还是会收到旧场景的怪物等等的广播信息 
            common_misc:unicast2(Pid, Unique, Module, Method, DataRecord), 
            mod_map_ybc:notify_role_ybc_pos(RoleID), 
            %% 进入地图hook 
            hook_map_role:map_enter(RoleID, RoleMapInfo, MapID) 
    end. 

do_enter_monster(MonsterMapInfo, InSlice, AllSlice) ->
    Module = ?MONSTER, 
    Method = ?MONSTER_ENTER,
    InRoles = slice_get_roles(InSlice),
    AroundSlices = lists:delete(InSlice, AllSlice),
    AroundRoles = mgeem_map:get_all_in_sence_user_by_slice_list(AroundSlices),
    DataRecord2 = #m_monster_enter_toc{monsters=[MonsterMapInfo]},
    mgeem_map:broadcast(InRoles, AroundRoles, ?DEFAULT_UNIQUE, Module, Method, DataRecord2).

do_enter_ybc(YbcMapInfo, InSlice, AllSlice) ->
    mod_map_ybc:init_enter(YbcMapInfo#p_map_ybc.ybc_id, YbcMapInfo#p_map_ybc.creator_id),
    Module = ?YBC, 
    Method = ?YBC_ENTER,
    InRoles = slice_get_roles(InSlice),
    AroundSlices = lists:delete(InSlice, AllSlice),
    AroundRoles = mgeem_map:get_all_in_sence_user_by_slice_list(AroundSlices),
    DataRecord2 = #m_ybc_enter_toc{ybc_info=YbcMapInfo},
    mgeem_map:broadcast(InRoles, AroundRoles, ?DEFAULT_UNIQUE, Module, Method, DataRecord2).

do_enter_server_npc(MapServerNpcInfo, InSlice, AllSlice) ->
    Module = ?SERVER_NPC, 
    Method = ?SERVER_NPC_ENTER,
    InRoles = slice_get_roles(InSlice),
    AroundSlices = lists:delete(InSlice, AllSlice),
    AroundRoles = mgeem_map:get_all_in_sence_user_by_slice_list(AroundSlices),
    DataRecord = #m_server_npc_enter_toc{server_npcs=[MapServerNpcInfo]},
    mgeem_map:broadcast(InRoles, AroundRoles, ?DEFAULT_UNIQUE, Module, Method, DataRecord).

do_enter_pet(MapPetInfo, InSlice, AllSlice) ->
    Module = ?PET, 
    Method = ?PET_ENTER, 
    InRoles = slice_get_roles(InSlice), 
    AroundSlices = lists:delete(InSlice, AllSlice), 
    AroundRoles = mgeem_map:get_all_in_sence_user_by_slice_list(AroundSlices), 
    DataRecord = #m_pet_enter_toc{pets=[MapPetInfo]}, 
    mgeem_map:broadcast(InRoles, AroundRoles, ?DEFAULT_UNIQUE, Module, Method, DataRecord). 

%%镜像退出地图
do_mirror_quit(ActorID, ActorType, State) ->
	case get_actor_pos(ActorID, ActorType) of 
	undefined -> 
		ignore;
	#p_pos{tx=TX, ty=TY} -> 
		#map_state{offsetx=OffsetX, offsety=OffsetY} = State,
		Slice = mgeem_map:get_slice_by_txty(TX, TY, OffsetX, OffsetY),            
		%%一定要退出九宫格
		slice_leave(Slice, ActorID, ActorType),
		case ActorType of
		role ->
			mod_map_pet:mirror_pet_quit(ActorID);
		_ ->
			ignore
		end,
		AllSlice = mgeem_map:get_9_slice_by_txty(TX, TY, OffsetX, OffsetY),
		case AllSlice =/= undefined andalso Slice =/= undefined of
		true ->
			AroundSlices = lists:delete(Slice, AllSlice),
			do_quit2(ActorID, ActorType, Slice, AroundSlices, false);
		false ->
			ignore
		end       
	end,
	unregister_actor(ActorID,ActorType).

%%退出地图 
do_quit(ActorID, ActorType, State) -> 
	do_quit(ActorID, ActorType, State, false).
do_quit(ActorID, ActorType, State, IsRoleFight) -> 
    case ActorType of 
        role -> 
            case get({roleid_to_pid,ActorID}) of 
                undefined -> 
                    nil;
				mirror ->
					throw({error, is_mirror});%%因为会持久化数据，不允许对镜像调用该方法
                _Pid -> 
                    ignore
            end; 
        _ -> 
            ignore 
    end, 
    case get_actor_pos(ActorID, ActorType) of 
        undefined -> 
			ignore;
        #p_pos{tx=TX, ty=TY} -> 
			?TRY_CATCH(do_quit_catch(ActorID,ActorType,State,TX,TY,IsRoleFight))
    end,
    unregister_actor(ActorID,ActorType).

do_quit_catch(ActorID,ActorType,State,TX,TY,IsRoleFight)->
    #map_state{offsetx=OffsetX, offsety=OffsetY} = State,
    Slice = mgeem_map:get_slice_by_txty(TX, TY, OffsetX, OffsetY), 
    %%一定要退出九宫格
    slice_leave(Slice, ActorID, ActorType),
    case ActorType of
        role ->
            %%把技能的使用时间存进数据库
            LastUseTime = mof_fight_time:get_last_skill_time(ActorType, ActorID),
            SkillTime = #r_skill_time{role_id=ActorID, last_use_time=LastUseTime},
            db:dirty_write(?DB_SKILL_TIME, SkillTime),
            %%异兽需要跟随玩家一起退出地图 
            ?TRY_CATCH( mod_map_pet:role_pet_quit(ActorID) ,"严重问题",ErrType2,ErrReason2), 
            ?TRY_CATCH( hook_map_role:role_quit(ActorID) ,"严重问题",ErrType4,ErrReason4); 
        _ ->
            ignore
    end,                            
    try 
        AllSlice = mgeem_map:get_9_slice_by_txty(TX, TY, OffsetX, OffsetY),
        case AllSlice =/= undefined andalso Slice =/= undefined of
            true ->
                AroundSlices = lists:delete(Slice, AllSlice),
                do_quit2(ActorID, ActorType, Slice, AroundSlices, IsRoleFight);
            false ->
                ignore
        end
    catch EE:EEE ->
              ?ERROR_MSG("~ts:~p ~p ~p ~p ~p ~p ~p ~p", ["严重问题", TX, TY,  
                                                         OffsetX, OffsetY, ActorType, State#map_state.mapid, EE, EEE])
    end.

do_quit2(ActorID, role, InSlice, AroundSlices, IsRoleFight) ->
    Module = ?MAP, 
    Method = ?MAP_QUIT,
    do_quit3(Module, Method, ActorID, role, InSlice, AroundSlices, IsRoleFight);
do_quit2(ActorID, ybc, InSlice, AroundSlices, IsRoleFight) ->
    Module = ?YBC,
    Method = ?YBC_QUIT,
    do_quit3(Module, Method, ActorID, ybc, InSlice, AroundSlices, IsRoleFight);
do_quit2(ActorID, monster, InSlice, AroundSlices, IsRoleFight) ->
    Module = ?MONSTER,
    Method = ?MONSTER_QUIT,
    do_quit3(Module, Method, ActorID, monster, InSlice, AroundSlices, IsRoleFight);
do_quit2(ActorID, server_npc, InSlice, AroundSlices, IsRoleFight) ->
    Module = ?SERVER_NPC, 
    Method = ?SERVER_NPC_QUIT,
    do_quit3(Module, Method, ActorID, server_npc, InSlice, AroundSlices, IsRoleFight);
do_quit2(ActorID, pet, InSlice, AroundSlices, IsRoleFight) ->
    Module = ?PET, 
    Method = ?PET_QUIT, 
    do_quit3(Module, Method, ActorID, pet, InSlice, AroundSlices, IsRoleFight).
 
do_quit3(Module, Method, ActorID, ActorType, InSlice, AroundSlices, IsRoleFight) -> 
    InRoles = slice_get_roles(InSlice),
    AroundRoles = mgeem_map:get_all_in_sence_user_by_slice_list(AroundSlices), 
    case ActorType of 
        role -> 
            DataRecord = #m_map_quit_toc{roleid=ActorID};
        monster ->
            DataRecord = #m_monster_quit_toc{monsterid=ActorID}; 
        ybc -> 
            DataRecord = #m_ybc_quit_toc{ybc_id=ActorID}; 
        server_npc -> 
            DataRecord = #m_server_npc_quit_toc{npc_ids = [ActorID]}; 
        pet -> 
            DataRecord = #m_pet_quit_toc{pet_id = ActorID} 
    end, 
	%%玩家攻击怪物死亡不发m_monster_quit_toc协议
	case IsRoleFight =:= true andalso ActorType =:= monster of
		true ->
			ignore;
		_ ->
    		%%广播通知其他玩家某个actor退出了 
    		mgeem_map:broadcast(InRoles, AroundRoles, ?DEFAULT_UNIQUE, Module, Method, DataRecord) 
 	end.
 
%%处理actor死亡 
do_dead(ActorID, ActorType, _State) -> 
    case get_actor_mapinfo(ActorID, ActorType) of 
        undefined -> 
            nil; 
        OldMapInfo -> 
            case ActorType of 
                role ->  
                    NewMapInfo = OldMapInfo#p_map_role{hp=0 ,state = ?ROLE_STATE_DEAD};
                monster -> 
                    NewMapInfo = OldMapInfo#p_map_monster{state=?DEAD_STATE, hp=0}; 
                ybc -> 
                    NewMapInfo = OldMapInfo#p_map_ybc{status=?DEAD_STATE, hp=0}; 
                server_npc -> 
                    NewMapInfo = OldMapInfo#p_map_server_npc{state=?DEAD_STATE, hp=0}; 
                pet -> 
                    NewMapInfo = OldMapInfo#p_map_pet{state=?DEAD_STATE, hp=0}
            end, 
 
            set_actor_mapinfo(ActorID, ActorType, NewMapInfo) 
    end. 
 
 
get_actor_mapinfo_by_idlist(RoleList,role,AllSlice) -> 
    lists:foldr( 
      fun(RoleID,Acc2) -> 
              case get_actor_mapinfo(RoleID,role) of 
                  undefined -> 
                      %%如果找不到玩家的地图信息，则让玩家推出该slice 
                      lists:foreach(fun(SliceName) ->slice_leave(SliceName,RoleID,role) end, AllSlice), 
                      Acc2; 
                  RoleMapinfo -> 
                      [RoleMapinfo|Acc2] 
              end 
      end,[],RoleList); 
get_actor_mapinfo_by_idlist(MonsterList,monster,_AllSlice) -> 
    lists:foldr( 
      fun(MonsterID,Acc2) -> 
              case get_actor_mapinfo(MonsterID,monster) of 
                  undefined -> 
                      Acc2; 
                  MonsterMapinfo -> 
                      [MonsterMapinfo|Acc2] 
              end 
      end,[],MonsterList); 
get_actor_mapinfo_by_idlist(ServerNpcIdList,server_npc,_AllSlice) -> 
    lists:foldr( 
      fun(ServerNpcId,Acc) -> 
              case get_actor_mapinfo(ServerNpcId,server_npc) of 
                  undefined -> 
                      Acc; 
                  MapServerNpcinfo -> 
                      [MapServerNpcinfo|Acc] 
              end 
      end,[],ServerNpcIdList); 
get_actor_mapinfo_by_idlist(PetIdList,pet,_AllSlice) -> 
    lists:foldr( 
      fun(PetId,Acc) -> 
              case get_actor_mapinfo(PetId,pet) of 
                  undefined -> 
                      Acc; 
                  MapPetinfo -> 
                      [MapPetinfo|Acc] 
              end 
      end,[],PetIdList). 
 
 
%%设置、获得以及删除actor的最后移动路径 
set_actor_pid_lastwalkpath(RoleID, role, Path) -> 
    case get_actor_mapinfo(RoleID,role) of 
        undefined-> 
            ?INFO_MSG("~ts:RoleID = ~w ,path = ~w",["设置玩家的最后移动路异常",RoleID,Path]); 
        OldRoleMapInfo -> 
            NewRoleMapInfo = OldRoleMapInfo#p_map_role{last_walk_path=Path}, 
            set_actor_mapinfo(RoleID,role,NewRoleMapInfo) 
     end. 
erase_actor_pid_lastwalkpath(RoleID, role) -> 
    case get_actor_mapinfo(RoleID,role) of 
        %%这里需要处理一下，为什么没用？重启了？是不是要初始化一些东西？ 
        undefined -> 
            ok; 
        OldRoleMapInfo -> 
            NewRoleMapInfo = OldRoleMapInfo#p_map_role{last_walk_path=undefined}, 
            set_actor_mapinfo(RoleID,role,NewRoleMapInfo) 
    end. 
 
 
%%设置、删除actor的最后键盘移动路径 
set_actor_pid_lastkeypath(RoleID, role, Path) -> 
    case get_actor_mapinfo(RoleID,role) of 
        undefined-> 
            ?INFO_MSG("~ts:RoleID = ~w ,path = ~w",["设置玩家的最后移动路异常",RoleID,Path]); 
        OldRoleMapInfo -> 
            NewRoleMapInfo = OldRoleMapInfo#p_map_role{last_key_path=Path}, 
            set_actor_mapinfo(RoleID,role,NewRoleMapInfo) 
  end. 
erase_actor_pid_lastkeypath(RoleID, role) -> 
    case get_actor_mapinfo(RoleID,role) of 
        undefined -> 
            ok; 
        OldRoleMapInfo -> 
            NewRoleMapInfo = OldRoleMapInfo#p_map_role{last_key_path=undefined}, 
            set_actor_mapinfo(RoleID,role,NewRoleMapInfo) 
    end. 
 
set_actor_pos_after_dir_change(RoleID,role,Pos) -> 
    OldRoleMapInfo = mod_map_actor:get_actor_mapinfo(RoleID,role), 
    NewRoleMapInfo = OldRoleMapInfo#p_map_role{pos=Pos}, 
    mod_map_actor:set_actor_mapinfo(RoleID,role,NewRoleMapInfo); 
set_actor_pos_after_dir_change(MonsterID,monster,Pos) -> 
    OldMonsterMapInfo = mod_map_actor:get_actor_mapinfo(MonsterID,monster), 
    NewMonsterMapInfo = OldMonsterMapInfo#p_map_monster{pos=Pos}, 
    mod_map_actor:set_actor_mapinfo(MonsterID,monster,NewMonsterMapInfo); 
set_actor_pos_after_dir_change(ServerNpcID,server_npc,Pos) -> 
   OldServerNpcMapInfo = mod_map_actor:get_actor_mapinfo(ServerNpcID,server_npc), 
    NewServerNpcMapInfo = OldServerNpcMapInfo#p_map_server_npc{pos=Pos}, 
    mod_map_actor:set_actor_mapinfo(ServerNpcID,server_npc,NewServerNpcMapInfo); 
set_actor_pos_after_dir_change(PetID,pet,Pos) -> 
    OldPetMapInfo = mod_map_actor:get_actor_mapinfo(PetID,pet), 
    NewPetMapInfo = OldPetMapInfo#p_map_pet{pos=Pos}, 
    mod_map_actor:set_actor_mapinfo(PetID,pet,NewPetMapInfo); 
set_actor_pos_after_dir_change(_,_,_) -> 
   ignore. 
 
 
 
 
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%获得slice列表中的所有摊位列表 
get_dolls_by_slice_list(AllSlice) -> 
    lists:foldl( 
      fun(SliceName, Acc) -> 
              case mgeem_map:get_slice_dolls(SliceName) of 
                  undefined -> 
                      Acc; 
                  Stalls -> 
                      common_tool:combine_lists(Stalls, Acc) 
              end 
      end, [], AllSlice). 
 
do_update_actor_mapinfo(Unique, Moudle, Method, DataIn, RoleID) -> 
    #m_map_update_actor_mapinfo_tos{actor_id = ActorID,actor_type = ActorType} = DataIn, 
    case ActorType of 
        ?TYPE_ROLE -> 
            MapRoleInfo = get_actor_mapinfo(ActorID, role), 
            Record = #m_map_update_actor_mapinfo_toc{ 
              actor_id = ActorID, 
              actor_type = ActorType, 
              role_info = MapRoleInfo}; 
        ?TYPE_MONSTER -> 
            MapMonsterInfo =  get_actor_mapinfo(ActorID, monster), 
            Record = #m_map_update_actor_mapinfo_toc{ 
              actor_id = ActorID, 
              actor_type = ActorType, 
              monster_info = MapMonsterInfo}; 
        ?TYPE_YBC -> 
            MapInfo =  get_actor_mapinfo(ActorID, ybc), 
            Record = #m_map_update_actor_mapinfo_toc{ 
              actor_id = ActorID, 
              actor_type = ActorType, 
              ybc_info = MapInfo}; 
        ?TYPE_SERVER_NPC -> 
            MapServerNpcInfo = get_actor_mapinfo(ActorID,server_npc), 
            Record = #m_map_update_actor_mapinfo_toc{ 
              actor_id = ActorID, 
              actor_type = ActorType, 
              server_npc = MapServerNpcInfo}; 
        ?TYPE_PET -> 
            MapPetInfo = get_actor_mapinfo(ActorID,pet), 
            Record = #m_map_update_actor_mapinfo_toc{ 
              actor_id = ActorID, 
              actor_type = ActorType, 
              pet_info = MapPetInfo}; 
        _ -> 
             Record = nil 
    end, 
    case Record of 
        nil -> 
            nil; 
        _ -> 
            common_misc:unicast({role, RoleID}, Unique, Moudle, Method, Record) 
    end. 
 
 
 
get_new_walk_path(Path, Tile) -> 
    case Path of 
        true -> 
            []; 
        [_H] -> 
            Path; 
        _ -> 
            [First, Second|T] = Path, 
            case Second =:= Tile of 
                false -> 
                    [Tile|lists:delete(First, Path)]; 
                _ -> 
                    [Tile|T] 
            end 
    end. 
  
erase_actor_skill_time(ActorID, role) -> 
    mof_fight_time:erase_last_skill_time(role, ActorID);
erase_actor_skill_time(_ActorID, _ActorType) -> 
    ignore. 

auto_recover(MapID, NowSecs) when NowSecs rem 5 == 0 -> 
    %% 角色的自动回血回蓝
    lists:foreach(fun
        (RoleID) ->
            RoleMapInfo = get_actor_mapinfo(RoleID, role),
            mod_tili:auto_recover_tili(RoleID),
            mod_map_role:do_role_recover(RoleID, RoleMapInfo, MapID, NowSecs),
            mod_role_on_zazen:add_zazen_exp(RoleID, RoleMapInfo)
    end, get_in_map_role()),
	
	%% 角色镜像的自动回血 
	lists:foreach(fun
        ({role, RoleID}) -> 
            RoleMapInfo = get_actor_mapinfo(RoleID, role),
			mod_map_role:do_role_recover(RoleID, RoleMapInfo, MapID, NowSecs);
		(_) ->
			ignore
	end, mod_mirror:mirrors()),

	%% 怪物的自动回血 
	lists:foreach(fun
        (MonsterID) -> 
			mod_map_monster:do_monster_recover(MonsterID) 
	end, mod_map_monster:get_monster_id_list()), 
	
	%% NPC的自动回血 
	lists:foreach(fun
        (ServerNpcID) -> 
			mod_server_npc:do_server_npc_recover(ServerNpcID) 
	end, mod_server_npc:get_server_npc_id_list());
auto_recover(_MapID, _NowSecs) -> ignore.
 
 
 
%%特殊状态下清理其他国家的玩家 
clear_other_faction_role() -> 
    case get(?back_faction_time) of 
        undefined ->%%不是国战 
            clear_other_faction_role_2(); 
        Time ->%%国战 
            case common_tool:now() >= Time of 
                true -> 
                    FactionID = get(?defen_faction_id), 
                    do_clear_other_faction_role(FactionID, ?MAP_PROTECT_RC_FACTION_WAR), 
                    erase(?defen_faction_id), 
                    erase(?back_faction_time), 
                    true; 
                _ -> 
                    clear_other_faction_role_2() 
            end 
    end. 
 
clear_other_faction_role_2() -> 
    case get_map_protected() of 
        false -> 
            ignore; 
        {true, Key, FactionID, ReasonCode} -> 
            do_clear_other_faction_role(FactionID, ReasonCode), 
            del_map_protected(Key); 
        Other -> 
            ?ERROR_MSG("~ts:~w", ["清理别国玩家数据有错", Other]), 
            ignore 
    end. 
 
do_clear_other_faction_role(FactionID, ReasonCode) -> 
    MapID = mgeem_map:get_mapid(), 
    lists:foreach( 
    fun(RoleID) -> 
          case mod_map_actor:get_actor_mapinfo(RoleID, role) of 
              undefined -> 
                  ignore; 
              #p_map_role{faction_id=FactionID} -> 
                  ignore; 
              #p_map_role{faction_id=RoleFactionID} -> 
                  case get_map_protected_tips(ReasonCode) of 
                      ignore -> 
                          ignore; 
                      Notify -> 
                          common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_CENTER, Notify), 
                          common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, Notify) 
                  end, 
                  HomeMapID = common_misc:get_home_mapid(RoleFactionID, MapID), 
                  {_, TX, TY} = common_misc:get_born_info_by_map(HomeMapID), 
                  mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_RETURN_HOME, RoleID, HomeMapID, TX, TY) 
          end 
    end, mod_map_actor:get_in_map_role()). 
 
get_map_protected_tips(ReasonCode) -> 
    case ReasonCode of 
        ?MAP_PROTECT_RC_FACTION_WAR -> 
            ignore; 
        ?MAP_PROTECT_RC_FACTION_YBC -> 
            ?_LANG_PERSON_YBC_CLEAR_OTHER_FACTION_ROLE 
    end. 
 
del_map_protected(Key) -> 
    case get(?map_protected_time) of 
        undefined -> 
            List = []; 
        List -> 
            ok 
    end, 
    NewList = lists:keydelete(Key, 1, List), 
    put(?map_protected_time, NewList), 
    NewList. 
 
set_map_protected(Key, StartTime, FactionID, ReasonCode) -> 
    List = del_map_protected(Key), 
    NewList = [{Key, StartTime, FactionID, ReasonCode}|List], 
    put(?map_protected_time, NewList). 
get_map_protected() ->
    Now = common_tool:now(),
    case get(?map_protected_time) of
        undefined ->
            false;
        List ->
            lists:foldl(fun(Data, Result) ->
                {Key, StartTime, FactionID, ReasonCode} = Data,
                if
                     StartTime =< Now ->
                        del_map_protected(Key),
                        {true, Key, FactionID, ReasonCode};
                     true ->
                        Result
                end  
            end, false, List)
    end.

%% @doc 在指定点周围寻找一个最近可走点
get_empty_pos_around(MapID, TX, TY) ->
    case mcm:safe_type(MapID, {TX, TY}) of
        undefined ->
            get_empty_pos_around2(MapID, TX, TY);
        _ ->
            case get({ref, TX, TY}) of
				undefined ->
                    {TX, TY};
                [] ->
                    {TX, TY};
                _ ->
                    get_empty_pos_around2(MapID, TX, TY)
            end
    end.

get_empty_pos_around2(MapID, TX, TY) ->
    %% 半径为10格，找不到的话则返回原点
    case mod_spiral_search:get_walkable_pos(MapID, TX, TY, 10) of
        {error, _} ->
            {TX, TY};
        {TX2, TY2} ->
            {TX2, TY2}
    end.
        
%% @doc 
set_change_map_quit(RoleID, DestMapID) ->
    erlang:put({?change_map_quit, RoleID}, DestMapID).

is_change_map_quit(RoleID) ->
    case erlang:get({?change_map_quit, RoleID}) of
        undefined ->
            false;
        DestMapID ->
            {true, DestMapID}
    end.
