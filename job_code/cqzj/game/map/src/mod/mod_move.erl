%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     mod_move
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mod_move).

-include("mgeem.hrl").

-export([handle/2]).
-export([do_random_move/2,do_skill_transfer/4,do_skill_charge/5]).

%% ====================================================================
%% API functions
%% ====================================================================
%%无论玩家使用何种方式走路，每经过一格都必须要发一次消息给服务端
handle({Unique, Module, ?MOVE_WALK, DataIn, RoleID, _PID, Line}, State) -> 
    do_walk({Unique, Module, ?MOVE_WALK, DataIn, RoleID, Line}, State);
handle({_Unique, ?MOVE, ?MOVE_WALK_PATH, DataIn, RoleID, _PID, _Line}, State) ->
    do_walk_path(?MOVE, ?MOVE_WALK_PATH, DataIn, RoleID, State);
handle(Info,_State) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).


%%@doc 全地图随机移动
do_random_move(RoleID, State) ->
    Pos = mod_map_actor:get_actor_pos(RoleID, role),
    #p_pos{tx=TX, ty=TY} = Pos,
    #map_state{grid_width=GridWidth, grid_height=GridHeight} = State,
    {X, Y} = get_random_tx_ty(State#map_state.mapid, TX, TY, GridWidth, GridHeight, 1),
    mod_map_actor:same_map_change_pos(RoleID, role, X, Y, ?CHANGE_POS_TYPE_NORMAL, State).


%%@doc 随机移动技能——瞬移
do_skill_transfer(ActorID, ActorType,DistRound,State) ->
    Pos = mod_map_actor:get_actor_pos(ActorID,ActorType),
    #p_pos{tx = TX, ty = TY} = Pos,
    {TX2,TY2} = get_random_tx_ty_in_distround(State#map_state.mapid, TX, TY , DistRound, 0),
    mod_map_actor:same_map_change_pos(ActorID, ActorType, TX2, TY2, ?CHANGE_POS_TYPE_NORMAL, State).


%%@doc 冲锋技能
do_skill_charge(ActorID, ActorType,DestActorID,DestActorType,State) ->
    case mod_map_actor:get_actor_pos(ActorID,ActorType) of
        undefined ->
            ignore;
        Pos ->
            #p_pos{tx = TX, ty = TY} = Pos,
            case mod_map_actor:get_actor_pos(DestActorID,DestActorType) of
                undefined ->
                    ignore;
                DestPos ->
                    #p_pos{tx = DestTX, ty = DestTY} = DestPos,
                    {_, {NewTX,NewTY}} = get_charge_tx_ty(State#map_state.mapid,TX,TY,DestTX,DestTY),
                    case NewTX =:= TX andalso NewTY =:= TY of
                        true ->
                            nil;
                        false ->
							mod_map_actor:same_map_change_pos(ActorID,ActorType,NewTX,NewTY,?CHANGE_POS_TYPE_CHARGE,State,DestActorID,DestActorType)
                    end
            end
    end.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

do_walk({Unique, Module, Method, DataIn, RoleID, Line}, State) ->
    #m_move_walk_tos{pos=#p_pos{tx=TX, ty=TY, dir=DIR}} = DataIn,
    case mod_map_actor:get_actor_pos(RoleID, role) of
        undefined ->
            ?ERROR_MSG("~ts [~w] : ~ts", ["踢掉玩家", RoleID, "原因是没有发现玩家的位置"]), 
            %%mod_map_role:kick_role(RoleID, Line);
            ignore;
        #p_pos{tx=OldTX, ty=OldTY} ->
            %%判断移动是否合法
            case erlang:abs(OldTX - TX) =< 1 andalso erlang:abs(OldTY - TY) =< 1 of
                true ->
                    do_walk2(Unique, Module, Method, State#map_state.mapid, {TX, TY, DIR}, RoleID, Line);
                false ->
                    sync_role_pos(RoleID, Line)
            end
    end.
do_walk2(_Unique, _Module, _Method, MapID, {TX, TY, DIR}, RoleID, _Line) ->
    %%判断安全区
    case mcm:is_walkable(MapID, {TX, TY}) of
        false ->
            ?ERROR_MSG("~ts:~w ~w ~w", ["玩家由于走到一个不可走的格子上而被踢掉了", mgeem_map:get_mapid(), TX, TY]);
%%             mod_map_role:kick_role(RoleID, Line, walk_error_pos);
        _ ->
            hook_map_role:role_pos_change(RoleID, TX, TY, DIR),
            mod_map_actor:update_slice_by_txty(RoleID, role, TX, TY, DIR)
    end. 

%%处理玩家走路路径信息
do_walk_path(?MOVE, ?MOVE_WALK_PATH, DataIn, RoleID, State) ->
    %%这里将来可能需要做检查，以防外挂恶意构造
    #map_state{offsetx=OffsetX, offsety=OffsetY} = State,
    mod_map_actor:set_actor_pid_lastwalkpath(RoleID, role, DataIn#m_move_walk_path_tos.walk_path),
    DataOther = #m_move_walk_path_toc{
      roleid=RoleID,
      walk_path=DataIn#m_move_walk_path_tos.walk_path
     },
    
    %%理论上这里应该不需要判断，因为这个位置实际上是已经验证过了的
    case mod_map_actor:get_actor_txty_by_id(RoleID, role) of
        {TX, TY}->
            %% ?DEBUG("~ts ~w ~w", ["获得玩家当前的格子位置", TX, TY]),
            AllSlice = mgeem_map:get_9_slice_by_txty(TX, TY, OffsetX, OffsetY),
            InSlice = mgeem_map:get_slice_by_txty(TX, TY, OffsetX, OffsetY),
            %%判断位置，有多种原因可能造成计算出的slice是undefined
            case AllSlice =/= undefined andalso InSlice =/= undefined of
                true ->
                    AroundSlices = lists:delete(InSlice, AllSlice),
                    RoleIDList1 = lists:delete(RoleID,mod_map_actor:slice_get_roles(InSlice)),
                    RoleIDList2 = mgeem_map:get_all_in_sence_user_by_slice_list(AroundSlices),
                    mgeem_map:broadcast(RoleIDList1, RoleIDList2, ?DEFAULT_UNIQUE, 
                                          ?MOVE, ?MOVE_WALK_PATH, DataOther);
                false ->
                    ignore
            end;
        undefined ->
            ignore
    end.


get_random_tx_ty(_MapID, TX, TY, _GridWidth, _GridHeight, 20) ->
    {TX, TY};
get_random_tx_ty(MapID, TX, TY, GridWidth, GridHeight, N) ->
    X = random:uniform(GridWidth) div ?TILE_SIZE,
    Y = random:uniform(GridHeight) div ?TILE_SIZE,
    case mcm:safe_type(MapID, {X, Y}) of
        undefined ->
            get_random_tx_ty(MapID, TX, TY, GridWidth, GridHeight, N+1);
        safe ->
            {X, Y};
        _ ->
            case get({ref, X, Y}) of
                [] ->
                    {X, Y};
				undefined ->
					{X, Y};
                _ ->
                    get_random_tx_ty(MapID, TX, TY, GridWidth, GridHeight, N+1)
            end
    end.


%%连续20次不能随机到可走点的话随机回原点
get_random_tx_ty_in_distround(_MapID, TX, TY , _DistRound, 20) ->
    {TX,TY};
get_random_tx_ty_in_distround(MapID, TX, TY , DistRound, Num) ->
    X = random:uniform(DistRound*2+1) - DistRound + TX,
    Y = random:uniform(DistRound*2+1) - DistRound + TY,
    case mcm:safe_type(MapID, {X, Y}) of
        undefined ->
            get_random_tx_ty_in_distround(MapID, TX, TY , DistRound, Num+1);
        safe ->
            {X, Y};
        _ ->
            case get({ref, X, Y}) of
                [] ->
                    {X,Y};
				undefined ->
					{X, Y};
                _ ->
                    get_random_tx_ty_in_distround(MapID, TX, TY , DistRound, Num+1)
            end
    end.



get_charge_tx_ty(MapID,TX,TY,DestTX,DestTY) ->
    OldDis =  abs(DestTX - TX) + abs(DestTY - TY),
    List = lists:foldr(
             fun(X,Acc0) ->
                     lists:foldr(
                       fun(Y,Acc1) ->
                               [{X,Y}|Acc1]
                       end,Acc0,[DestTY-1,DestTY,DestTY+1])
             end,[],[DestTX-1,DestTX,DestTX+1]),
    lists:foldr(
      fun({X ,Y}, {Acc0,Acc1}) ->
              case mcm:safe_type(MapID,{TX, TY}) of
                  undefined ->
                      {Acc0,Acc1};
                  safe ->
                      get_charge_tx_ty2(X,Y,TX,TY,Acc0,Acc1);
                  not_safe ->
                      get_charge_tx_ty2(X,Y,TX,TY,Acc0,Acc1);
                  _ ->
                      case get({ref,TX,TY}) of
                          [] ->
                              get_charge_tx_ty2(X,Y,TX,TY,Acc0,Acc1);
						  undefined ->
							  get_charge_tx_ty2(X,Y,TX,TY,Acc0,Acc1);
                          _ ->
                              {Acc0,Acc1}
                      end
              end
      end,{OldDis,{DestTX,DestTY}},List).
get_charge_tx_ty2(X,Y,TX,TY,Acc0,Acc1) ->
    Dis = abs(X - TX) + abs(Y - TY),
    case Dis < Acc0 of
        true ->
            {Dis,{X,Y}};              
        false ->
            {Acc0,Acc1}
    end.


%%同步玩家位置
sync_role_pos(RoleID, Line) ->
    case  mod_map_actor:get_actor_pos(RoleID, role) of
        undefined ->
            mod_map_role:kick_role(RoleID, Line);
        Pos ->
            mod_map_actor:erase_actor_pid_lastwalkpath(RoleID, role),
            mod_map_actor:erase_actor_pid_lastkeypath(RoleID, role),
            DataRecord = #m_move_sync_toc{roleid=RoleID, pos=Pos},
            mgeem_map:do_broadcast_insence_include([{role, RoleID}], ?MOVE, ?MOVE_SYNC, DataRecord,mgeem_map:get_state())
    end.


