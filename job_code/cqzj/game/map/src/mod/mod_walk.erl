-module(mod_walk).

-include("mgeem.hrl").

-export([
         get_walk_path/2,
         get_broadcast_need_data/5,
         get_move_speed_time/2,
         get_straight_line_path/3,
         get_senior_path/2
        ]).


%%----------------------------------------------------------------
%% 获得走路路径  先采用直线，不行再走高级寻路
%% @SearchMapData 一块用来搜索的数据
%% @CurrentPos 当前位置#p_pos
%% @GotoPos 要前往的位置#p_pos
%%----------------------------------------------------------------
get_walk_path(CurrentPos, GotoPos) ->
    case get_straight_line_path(CurrentPos, GotoPos, []) of
        false ->
            get_senior_path(CurrentPos, GotoPos);
        {ok,Path} ->
            {ok, Path}
    end.


%%----------------------------------------------------------------
%% 直线寻路
%% @CurrentPos 当前位置#p_pos
%% @GotoPos 要前往的位置#p_pos
%% @Path路径信息
%%----------------------------------------------------------------
get_straight_line_path(CurrentPos,GotoPos,Path) ->
    get_straight_line_path(CurrentPos,GotoPos,Path,{-10000,-10000}).


get_straight_line_path(CurrentPos,GotoPos,Path,{LastTx,LastTy}) ->
    #p_pos{tx = Tx1, ty = Ty1, dir=Dir1} = CurrentPos,
    #p_pos{tx = Tx2, ty = Ty2, dir = Dir2} = GotoPos,
    case Tx1 =:= Tx2 andalso Ty1 =:= Ty2 of
        true ->
            {ok,lists:reverse([{Tx2,Ty2,Dir2}|Path])};
        false ->
            PosList = get_straight_line_pos_list(Tx1, Ty1, Tx2, Ty2),
            case get_empty_grid(mgeem_map:get_mapid(), PosList) of
                false ->
                    false;
               #p_pos{tx=Tx,ty=Ty} = NextPos ->
                    case Tx =:= LastTx andalso Ty =:= LastTy of
                        true ->
                            false;
                        false ->
                           
                            get_straight_line_path(NextPos,GotoPos,[{Tx1,Ty1,Dir1}|Path],{Tx1,Ty1})
                    end
            end
    end.

%%----------------------------------------------------------------
%% 高级寻路，目前用的使用A*寻路
%% @CurrentPos 当前位置#p_pos
%% @GotoPos 要前往的位置#p_pos
%%----------------------------------------------------------------
get_senior_path(CurrentPos, GotoPos)->
   case mod_astar_pathfinding:find_path(CurrentPos, GotoPos) of
       false ->
           false;
       Path ->
           {ok,Path}
    end.

%%----------------------------------------------------------------
%% 获得广播走路所需要的数据
%% @CurrentPos 当前位置#p_pos
%% @NextPos 下一个格子的pos
%% @OffsetX 一个格子大小
%% @OffsetY 一个格子大小
%% @WalkSpeed 走路速度
%%----------------------------------------------------------------
get_broadcast_need_data(CurrentPos, NextPos, OffsetX, OffsetY, WalkSpeed) ->
    #p_pos{tx = OldTX, ty = OldTY, dir = _OldDIR} = CurrentPos,
    #p_pos{tx = NewTX, ty = NewTY, dir = NewDIR} = NextPos,
    
    AllSliceOld = mgeem_map:get_9_slice_by_txty(OldTX, OldTY, OffsetX, OffsetY),
    AllSliceNew = mgeem_map:get_new_around_slice(NewTX, NewTY, OldTX, OldTY, OffsetX, OffsetY),
    
    AllSlice = common_tool:combine_lists(AllSliceOld, AllSliceNew),
    InSlice = mgeem_map:get_slice_by_txty(NewTX, NewTY, OffsetX, OffsetY),
    
    MoveSpeed = get_move_speed_time(WalkSpeed, NewDIR),
    
    case AllSlice =/= undefined andalso InSlice =/= undefined of
        true ->
            AroundSlices = lists:delete(InSlice, AllSlice),
            FirstBroadCastRoleIDList = mod_map_actor:slice_get_roles(InSlice),
            SecondBroadCastRoleIDList = mgeem_map:get_all_in_sence_user_by_slice_list(AroundSlices),
            {ok, MoveSpeed, FirstBroadCastRoleIDList, SecondBroadCastRoleIDList};
        false ->
            {error, empty_role_list}
    end.

get_empty_grid(_MapID, []) ->
    false;

get_empty_grid(MapID, [{X,Y,Dir}|List]) ->
    case mcm:is_walkable(MapID,{X,Y}) of 
        false ->
            get_empty_grid(MapID,List);
        _ ->
            #p_pos{tx = X, ty = Y, dir = Dir}
    end.


get_move_speed_time(Speed,DIR) ->
    if
        DIR =:= 0 orelse DIR =:= 4 orelse DIR =:= 2 orelse DIR =:= 6 -> 
            common_tool:ceil(73425/Speed);
        true -> 
            common_tool:ceil(51902/Speed)
    end.

   
get_straight_line_pos_list(Tx1, Ty1, Tx2, Ty2) ->
    case Tx1 < Tx2 of
        true ->
            case Ty1 < Ty2 of
                true ->
                    [{Tx1+1, Ty1+1, 4}, {Tx1+1, Ty1, 3}, {Tx1, Ty1+1, 5}];
                false ->
                    case Ty1 > Ty2 of
                        true ->
                            [{Tx1+1, Ty1-1, 2}, {Tx1+1, Ty1, 3}, {Tx1, Ty1-1, 1}];
                        false ->
                            [{Tx1+1, Ty1, 3}, {Tx1+1, Ty1-1, 2}, {Tx1+1, Ty1+1, 4}]
                    end
            end;
        false ->
            case Tx1 > Tx2 of
                true ->
                    case Ty1 < Ty2 of
                        true ->
                            [{Tx1-1, Ty1+1, 6}, {Tx1-1, Ty1, 7}, {Tx1, Ty1+1, 5}];
                        false ->
                            case Ty1 > Ty2 of
                                true ->
                                    [{Tx1-1, Ty1-1, 0}, {Tx1, Ty1-1, 1}, {Tx1-1, Ty1, 7}];
                                false ->
                                    [{Tx1-1, Ty1, 7}, {Tx1-1, Ty1-1, 0}, {Tx1-1, Ty1+1, 6}]
                            end
                    end;
                false ->
                    case Ty1 < Ty2 of
                        true ->
                            [{Tx1, Ty1+1, 5}, {Tx1+1, Ty1+1, 4}, {Tx1-1, Ty1+1, 6}];
                        false ->
                            [{Tx1, Ty1-1, 1}, {Tx1-1, Ty1-1, 0}, {Tx1+1, Ty1-1, 2}]
                    end
            end
    end.
