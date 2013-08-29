%% Author: liuwei
%% Created: 2010-5-26
%% Description: TODO: Add description to mod_monster_walk
-module(mod_monster_walk).

-include("mgeem.hrl").

-export([
         first_level_walk/5,
         second_level_walk/5,
         walk_inpath/7
        ]).


%%按照寻路除的路径走路，如果遇到阻挡则重新寻路
walk_inpath(_MonsterPos,WalkPos,NewWalkPath, MonsterID, Speed, DestPos, MonsterState) ->
    MapState = mgeem_map:get_state(),
    #map_state{offsetx=OffsetX, offsety=OffsetY} = MapState,
    monster_walk_pos(WalkPos,MonsterID,OffsetX,OffsetY,Speed,DestPos,
                     MonsterState#monster_state{last_enemy_pos = DestPos, walk_path = NewWalkPath}).


%%低级寻路，对巡逻和返回装他的怪物的只做直线寻路处理
first_level_walk(MonsterPos, DestPos, MonsterID,Speed, MonsterState) ->
    MonsterInfo = MonsterState#monster_state.monster_info,
    case MonsterInfo#p_monster.state of
        ?PATROL_STATE ->
            case mod_walk:get_straight_line_path(MonsterPos,DestPos,[]) of
                false ->
                    NewMonsterInfo =  MonsterInfo#p_monster{state = ?GUARD_STATE},
                    NewMonsterState = MonsterState#monster_state{monster_info=NewMonsterInfo,patrol_pos=undefined,walk_path=[]},
                    mod_map_monster:set_next_work(MonsterID,3000,loop,NewMonsterState);
                {ok,[_,WalkPos|Path]} ->
                    walk_inpath(MonsterPos,WalkPos,Path, MonsterID, Speed, DestPos, MonsterState)
            end;
        ?RETURN_STATE ->
            case mod_walk:get_straight_line_path(MonsterPos,DestPos,[]) of
                false ->
                    mod_map_monster:monster_transfer(MonsterPos,DestPos,MonsterID,MonsterState);
                {ok,[_,WalkPos|Path]} ->
                    walk_inpath(MonsterPos,WalkPos,Path, MonsterID, Speed, DestPos, MonsterState)
            end; 
        _ ->
            case mod_walk:get_walk_path(MonsterPos,DestPos) of
                false ->
                    mod_map_monster:set_next_work(MonsterID,500,loop,MonsterState#monster_state{walk_path=[]});
                {ok,[_R,WalkPos|Path]} ->
                    walk_inpath(MonsterPos,WalkPos,Path, MonsterID, Speed, DestPos, MonsterState)
            end
    end.


%%BOSS在战斗中是直接采用高级寻路
second_level_walk(MonsterPos, DestPos, MonsterID,Speed, MonsterState) ->
    case mod_walk:get_senior_path(MonsterPos,DestPos) of
        false ->
			?ERROR_MSG("second_level_walk error,MapID:~w MonsterID:~w,MonsterPos:~w,DestPos:~w",[mgeem_map:get_mapid(),MonsterID,MonsterPos,DestPos]),
            mod_map_monster:set_next_work(MonsterID,500,loop,MonsterState);
        {ok,[_,WalkPos|Path]} ->
            walk_inpath(MonsterPos,WalkPos,Path, MonsterID, Speed, DestPos, MonsterState)
    end.


%%怪物走路，从一个点走到另外一个点
monster_walk_pos(WalkPos, MonsterID, OffsetX, OffsetY, Speed, _DestPos, MonsterState) ->
    
    {TX, TY, DIR} = WalkPos,
    {OldTX,OldTY} = case mod_map_actor:get_actor_txty_by_id(MonsterID,monster) of
                        undefined ->
                            {TX,TY};
                        {X,Y} ->
                            {X,Y}
                    end,
    AllSliceOld = mgeem_map:get_9_slice_by_txty(OldTX,OldTY,OffsetX,OffsetY),
    AllSliceNew = mgeem_map:get_new_around_slice(TX, TY, OldTX, OldTY, OffsetX, OffsetY),
    AllSlice = common_tool:combine_lists(AllSliceOld,AllSliceNew),
    InSlice = mgeem_map:get_slice_by_txty(TX, TY, OffsetX, OffsetY),
    MonsterMapInfo = mod_map_actor:get_actor_mapinfo(MonsterID,monster),
    
    case catch mod_walk:get_move_speed_time(Speed,DIR) of
        MoveSpeed when is_integer(MoveSpeed)->
            next;
        _ ->
            ?ERROR_MSG("monster_walk_pos,Speed=~w,DIR=~w",[Speed,DIR]),
            MoveSpeed = 100
    end,
    
    NewMonsterInfo1 = MonsterMapInfo#p_map_monster{move_speed = MoveSpeed+?MIN_MONSTER_WORK_TICK},
    #p_map_monster{hp=Hp,max_hp=MaxHp} = NewMonsterInfo1,
    NewMonsterInfo2 = NewMonsterInfo1#p_map_monster{hp=trunc(Hp),max_hp=trunc(MaxHp)},
    
    DataRecord = #m_monster_walk_toc{monsterinfo = NewMonsterInfo2, pos = #p_pos{tx=TX,ty=TY,dir=DIR}},
    case AllSlice =/= undefined andalso InSlice =/= undefined of
        true ->
            AroundSlices = lists:delete(InSlice, AllSlice),
            RoleIDList1 = mod_map_actor:slice_get_roles(InSlice),
            RoleIDList2 = mgeem_map:get_all_in_sence_user_by_slice_list(AroundSlices),
            
            try
               mgeem_map:broadcast(RoleIDList1, RoleIDList2, ?DEFAULT_UNIQUE, 
                                 ?MONSTER, ?MONSTER_WALK, DataRecord)
            catch
                _:Reason->
                    ?DBG("DataRecord=~w,Reason=~w",[DataRecord,Reason])
            end;
           % ?DEBUG(" ~w ",[WalkPos]);
        false ->
            ?INFO_MSG("unexcept error!",[])
    end,
    mod_map_actor:update_slice_by_txty(MonsterID,monster, TX, TY, OffsetX, OffsetY, DIR),
    mod_map_monster:set_next_work(MonsterID,MoveSpeed,loop,MonsterState).

