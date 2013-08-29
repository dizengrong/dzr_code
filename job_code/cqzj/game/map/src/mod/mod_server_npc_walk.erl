%% Author: liuwei
%% Created: 2011-1-3
%% Description: TODO: Add description to mod_server_npc_walk
-module(mod_server_npc_walk).

-include("mgeem.hrl").

-export([
         first_level_walk/5,
         second_level_walk/5,
         walk_inpath/7
        ]).


%%按照寻路除的路径走路，如果遇到阻挡则重新寻路
walk_inpath(_ServerNpcPos,WalkPos,NewWalkPath, ServerNpcID, Speed, DestPos, ServerNpcState) ->
    MapState = mgeem_map:get_state(),
    #map_state{offsetx=OffsetX, offsety=OffsetY} = MapState,
    server_npc_walk_pos(WalkPos,ServerNpcID,OffsetX,OffsetY,Speed,DestPos,
                        ServerNpcState#server_npc_state{last_enemy_pos = DestPos, walk_path = NewWalkPath}).


%%最简单的走路，直接往目标点方向最近的点走，遇到阻挡时使用寻路
first_level_walk(ServerNpcPos, DestPos, ServerNpcID,Speed, ServerNpcState) ->
    ServerNpcInfo = ServerNpcState#server_npc_state.server_npc_info,
    case ServerNpcInfo#p_server_npc.state of
        ?RETURN_STATE ->
            case mod_walk:get_straight_line_path(ServerNpcPos,DestPos,[]) of
                false ->
                    mod_server_npc:server_npc_transfer(ServerNpcPos,DestPos,ServerNpcID,ServerNpcState);
                {ok,[_,WalkPos|Path]} ->
                    walk_inpath(ServerNpcPos,WalkPos,Path, ServerNpcID, Speed, DestPos, ServerNpcState)
            end; 
        _ ->
            case mod_walk:get_walk_path(ServerNpcPos,DestPos) of
                false ->
                    mod_server_npc:set_next_work(ServerNpcID,500,loop,ServerNpcState);
                {ok,[_,WalkPos|Path]} ->
                    walk_inpath(ServerNpcPos,WalkPos,Path, ServerNpcID, Speed, DestPos, ServerNpcState)
            end
    end.

%%NPC在战斗中是直接采用高级寻路
second_level_walk(NpcPos, DestPos, NpcID,Speed, ServerNpcState) ->
    case mod_walk:get_senior_path(NpcPos,DestPos) of
        false ->
			?ERROR_MSG("second_level_walk error,MapID:~w NpcID:~w,NpcPos:~w,DestPos:~w",[mgeem_map:get_mapid(),NpcID,NpcPos,DestPos]),
            mod_server_npc:set_next_work(NpcID,500,loop,ServerNpcState);
        {ok,[_,WalkPos|Path]} ->
            walk_inpath(NpcPos,WalkPos,Path, NpcID, Speed, DestPos, ServerNpcState)
    end.


%%怪物走路，从一个点走到另外一个点
server_npc_walk_pos(WalkPos, ServerNpcID, OffsetX, OffsetY, Speed, _DestPos, ServerNpcState) ->
    
    {TX, TY, DIR} = WalkPos,
    {OldTX,OldTY} = case mod_map_actor:get_actor_txty_by_id(ServerNpcID,server_npc) of
                        undefined ->
                            {TX,TY};
                        {X,Y} ->
                            {X,Y}
                    end,
    AllSliceOld = mgeem_map:get_9_slice_by_txty(OldTX,OldTY,OffsetX,OffsetY),
    AllSliceNew = mgeem_map:get_new_around_slice(TX, TY, OldTX, OldTY, OffsetX, OffsetY),
    AllSlice = common_tool:combine_lists(AllSliceOld,AllSliceNew),
    InSlice = mgeem_map:get_slice_by_txty(TX, TY, OffsetX, OffsetY),
    ServerNpcMapInfo = mod_map_actor:get_actor_mapinfo(ServerNpcID,server_npc),
    MoveSpeed = mod_walk:get_move_speed_time(Speed,DIR),
    
    NewServerNpcInfo = ServerNpcMapInfo#p_map_server_npc{move_speed = MoveSpeed+?MIN_MONSTER_WORK_TICK},
    DataRecord = #m_server_npc_walk_toc{server_npc_info = NewServerNpcInfo, pos = #p_pos{tx=TX,ty=TY,dir=DIR}},
    case AllSlice =/= undefined andalso InSlice =/= undefined of
        true ->
            AroundSlices = lists:delete(InSlice, AllSlice),
            RoleIDList1 = mod_map_actor:slice_get_roles(InSlice),
            RoleIDList2 = mgeem_map:get_all_in_sence_user_by_slice_list(AroundSlices),
            mgeem_map:broadcast(RoleIDList1, RoleIDList2, ?DEFAULT_UNIQUE, 
                                 ?SERVER_NPC, ?SERVER_NPC_WALK, DataRecord);
           % ?DEBUG(" ~w ",[WalkPos]);
        false ->
            ?INFO_MSG("unexcept error!",[])
    end,
    mod_map_actor:update_slice_by_txty(ServerNpcID,server_npc, TX, TY, OffsetX, OffsetY, DIR),
    mod_server_npc:set_next_work(ServerNpcID,MoveSpeed,loop,ServerNpcState).

