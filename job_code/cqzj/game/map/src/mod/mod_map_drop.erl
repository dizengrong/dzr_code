%% Author: liuwei
%% Created: 2010-5-26
%% Description: TODO: Add description to mod_map_drop
-module(mod_map_drop).

% -include("mgeem.hrl").
-include("mission.hrl").

-export([
         init/0,
         handle/2,
         monster_drop_thing/6,
         get_new_dropthing_id/0,
         get_dropthing_by_slice_list/2,
         dropthing_no_protect/5,
         do_pick_dropthing_return/4,
         drop_silver/2,
		 loop/0
        ]).

-export([
		 get_monster_drop_prop_list/1,
         set_role_monster_drop/2,
         clear_role_monster_drop/1,
         get_role_monster_drop/1]).

-export([
         is_in_team_drop_map/0]).

-define(ETS_DROPTHING_COUNTER,dropthing_counter).
-define(PICK_DISTANCE, 10).

%% 保护时间只对藏宝图有效
-define(DROPTHING_PROTECT_OVER_TIME, 60). %%60秒
-define(DROPTHING_QUIT_MAP_TIME, 300). %%300秒
-define(MAX_ITEM_LEN, 50). %% DROPTHING_PROTECT_QUEUE DROPTHING_QUIT_MAP_QUEUE 中每个元素最大长度 保证一秒内最多只处理这么多个掉落

-define(DROPTHING_PROTECT_QUEUE, dropthing_protect_queue).
-define(DROPTHING_QUIT_MAP_QUEUE, dropthing_quit_map_queue).

-record(monster_drop_broadcast,{monster_type,content,goods_type_list}).

%%
%% API Functions
%%
init() ->
    case ets:info(?ETS_DROPTHING_COUNTER) of
        undefined ->
            ets:new(?ETS_DROPTHING_COUNTER,[set,public, named_table]);
        _ ->
            nil
    end.

handle(Msg,State) ->
    do_handle(Msg, State).

loop() ->
	catch check_protect_queue(),
	catch check_quit_map_queue().

%%@doc 判断是否在组队掉落的地图中
is_in_team_drop_map()->
    MapId = mgeem_map:get_mapid(),
    mod_scene_war_fb:is_scene_war_fb_map_id(MapId).

dropthing_no_protect(RoleID, DropThingList, ActorID, ActorType, State) ->
    do_dropthing(RoleID, DropThingList, ActorID, ActorType, State).

get_new_dropthing_id() ->
    MapName = mgeem_map:get_mapname(),
    case ets:lookup(?ETS_DROPTHING_COUNTER, MapName) of
        [] ->
            ets:insert(?ETS_DROPTHING_COUNTER, {MapName,2}),
            1;
        [{MapName,ID}] ->
            ets:insert(?ETS_DROPTHING_COUNTER, {MapName, ID+1}),
            ID
    end.

get_dropthing_by_slice_list(RoleID,AllSlice) ->
    IsInTeamDropMap = is_in_team_drop_map(),
    get_dropthing_by_slice_list_2(AllSlice,RoleID,IsInTeamDropMap).

get_dropthing_by_slice_list_2(AllSlice,_RoleID,false)->
    lists:foldl(
      fun(SliceName, Acc) ->
              case get({dropthing,SliceName}) of
                  undefined ->
                      Acc;
                  DropList ->
                      common_tool:combine_lists(DropList, Acc)
              end
      end, [], AllSlice);
get_dropthing_by_slice_list_2(AllSlice,RoleID,true)->
    lists:foldl(
      fun(SliceName, Acc) ->
              case get({dropthing,SliceName}) of
                  undefined ->
                      Acc;
                  DropList ->
                      DropList2 = 
                          lists:filter(
                            fun(E)-> 
                                    #p_map_dropthing{ismoney=IsMoney,roles=Roles}=E,
                                    IsMoney orelse lists:member(RoleID, Roles)
                            end, DropList),
                      common_tool:combine_lists(DropList2, Acc)
              end
      end, [], AllSlice).

%%@doc 怪物掉落物品并通知world那边怪物死亡
%%@param RoleID 打死怪物的玩家 
monster_drop_thing({_ActorID,server_npc}, _MonsterBaseInfo, _MonsterID, _, _RebornPos, _FirstEnemy) ->
    ignore;
monster_drop_thing({RoleID,role}, MonsterBaseInfo, MonsterID, 
           {mission_call_monster,CallRoleId,CallUseTypeId}, RebornPos, _FirstEnemy) ->
    %% 18号任务模型，即使怪物被别的其它玩家杀死也是可以完成任务的
    ?TRY_CATCH(
      mgeer_role:absend(CallRoleId,{mod_mission_handler,
        {listener_dispatch, monster_dead, CallRoleId, MonsterBaseInfo#p_monster_base_info.typeid}})
      ,CallMonsterDoMissionErr),

    ?TRY_CATCH(
      mgeer_role:absend(CallRoleId,{mod_mission_handler,
        {listener_dispatch, monster_dead, CallRoleId, ?MISSION_FREE_MONSTER_ID}})
      ,CallMonsterDoMissionErr1),

    case mod_map_actor:get_actor_mapinfo(CallRoleId,role) of
        undefined ->
            Flag = false;
        #p_map_role{pos=RolePos} ->
            case erlang:abs(RolePos#p_pos.tx - RebornPos#p_pos.tx) =< 10 
                     andalso erlang:abs(RolePos#p_pos.ty - RebornPos#p_pos.ty) =< 10 of
                true ->
                    Flag = true;
                _ ->
                    Flag = false
            end
    end,
    case common_config_dyn:find(cang_bao_tu_fb, {call_monster_drop_item_id,CallUseTypeId}) of
        [{DropItemTypeId,ItemNumber,ItemBindWeight,GetWeight}] ->
            case Flag of
                true ->
                    case GetWeight >= common_tool:random(1, 10000) of
                        true ->
                            ItemBind = 
                                if ItemBindWeight =:= 0 ->
                                       false;
                                   ItemBindWeight =:= 10000 ->
                                       true;
                                   true ->
                                       common_tool:random(1, 10000) >= ItemBindWeight 
                                end,
                            [DropItemBase] = common_config_dyn:find_item(DropItemTypeId),
                            CallMonsterMissionListDropthingList = 
                                [#p_map_dropthing{ id = mod_map_drop:get_new_dropthing_id(), 
                                                   roles = [CallRoleId],
                                                   num = ItemNumber,
                                                   goodstype = ?TYPE_ITEM,
                                                   goodstypeid = DropItemTypeId,
                                                   drop_property = #p_drop_property{bind =ItemBind,
                                                                                    colour=DropItemBase#p_item_base_info.colour,
                                                                                    quality=1,hole_num=0,use_bind=0},
                                                   bind= ItemBind,
                                                   colour= DropItemBase#p_item_base_info.colour}];
                        _ ->
                            CallMonsterMissionListDropthingList = []
                    end;
                _ ->
                    CallMonsterMissionListDropthingList = []
            end;
        _ ->
            CallMonsterMissionListDropthingList = []
    end,
    monster_drop_thing({RoleID,role}, MonsterBaseInfo, MonsterID,CallMonsterMissionListDropthingList);
monster_drop_thing({RoleID,role}, MonsterBaseInfo, MonsterID, _SpecialData, _RebornPos,_FirstEnemy) ->
    monster_drop_thing({RoleID,role}, MonsterBaseInfo, MonsterID,[]).
monster_drop_thing({RoleID,role}, MonsterBaseInfo, MonsterID,CallMonsterMissionListDropthingList) ->
    #p_monster_base_info{typeid = MonsterTypeID,min_money = MinMoney,max_money = MaxMoney,
						 level=Level, rarity=Rarity,
                         monstername=MonsterName} = MonsterBaseInfo,
    FcmIndex = common_misc:get_role_fcm_cofficient(RoleID),
    LevelIndex = mod_map_monster:get_role_level_index(RoleID, MonsterTypeID, Level, Rarity),
    EnergyIndex = mod_map_monster:get_role_energy_index(RoleID),
    
    %%活动期间内可获得奖品
    ?TRY_CATCH( hook_activity_map:hook_monster_drop(RoleID,MonsterTypeID,EnergyIndex) ),
    
    IsInTeamDropMap = is_in_team_drop_map() andalso Rarity=:=?BOSS,
    
	DropInfoList = get_monster_dropinfo_list(MonsterTypeID),
    DropThingList = get_monster_dropthing_list(IsInTeamDropMap,MonsterTypeID, DropInfoList,RoleID,MinMoney,MaxMoney, FcmIndex, LevelIndex, EnergyIndex),
    DropThingList2 = lists:append([CallMonsterMissionListDropthingList,DropThingList]),
    ?TRY_CATCH( mod_hero_fb:hook_monster_drop(MonsterTypeID, MonsterName, DropThingList2),Err2 ),
    do_dropthing(IsInTeamDropMap, RoleID,DropThingList2,MonsterID,{monster,MonsterTypeID}, mgeem_map:get_state()).


%%
%% Local Functions
%%
do_handle({Unique, ?MAP, Method, DataIn, RoleID, PID}, State) ->
    case Method of 
        ?MAP_DROPTHING_PICK ->
            pick_dropthing(Unique,DataIn,RoleID,PID,State);
        _ ->
            nil
    end;

do_handle({dropthing,RoleID,DropThingList}, State) ->
    F = fun(Drop) -> 
                Drop#p_map_dropthing{id=get_new_dropthing_id()}
        end,
    do_dropthing(RoleID,[F(I)|| I <- DropThingList],RoleID,role, State);


do_handle({pick_dropthing_return,Succ,DropThing, RoleID}, State) ->
    do_pick_dropthing_return(Succ,DropThing, RoleID, State);

do_handle({dropthing_quit,DropThing}, State) ->
    do_dropthing_quit(DropThing,State);

do_handle(Msg,_State) ->
    ?INFO_MSG("unexcept msg",[Msg]).


do_pick_dropthing_return(Succ,DropThing, RoleID, State) ->
    #p_map_dropthing{pos = Pos,id = ID, goodstypeid = ItemTypeId} = DropThing,
    case Succ of
        true ->
            #p_pos{tx = TX, ty = TY} = Pos,
            #map_state{offsetx = OffsetX, offsety = OffsetY} = State,
            hook_pick_dropthing_succ(RoleID, ItemTypeId),
            do_dropthing_quit(TX, TY, OffsetX, OffsetY, [DropThing]);
        false ->
            case get({drop,ID}) of
                undefined ->
                    nil;
                _ ->
                    put({drop,ID},{unpick,DropThing})
            end
    end.

%% 玩家拾取掉落成功后的处理
hook_pick_dropthing_succ(RoleID, ItemTypeId) ->
    case mgeem_map:get_mapid() == cfg_bomb_fb:map_id() of
        true ->
            common_misc:common_broadcast_item_get(RoleID, ItemTypeId, mod_bomb_fb);
        _ -> ignore
    end.

do_dropthing(RoleID,DropThingList,ActorID,ActorType, State)->
    do_dropthing(false,RoleID,DropThingList,ActorID,ActorType, State).

do_dropthing(_,_,[],_,_,_) ->
    nil;
do_dropthing(IsInTeamDropMap,RoleID,DropThingList,ActorID,ActorType, State) ->
	ActorType2 = 
	case ActorType of
		{monster,_} ->
			monster;
		_ ->
			ActorType
	end,
    case mod_map_actor:get_actor_txty_by_id(ActorID,ActorType2) of
        undefined ->
            nil;
        {TX,TY} ->
            do_dropthing2(IsInTeamDropMap,TX,TY,RoleID,ActorID,ActorType,DropThingList,State)
    end.

do_dropthing2(IsInTeamDropMap,TX,TY,RoleID,ActorID,ActorType,DropThingList,State) ->
    Num = length(DropThingList),
    #map_state{mapid = MapID, offsetx = OffsetX, offsety = OffsetY} = State,
    PosList = get_droppos_list(MapID,TX,TY,Num),
    case do_monster_dead_must_drop(ActorType,DropThingList) of
        {MustDropList,OtherDropList} ->
            AllDropList = MustDropList++OtherDropList;
        AllDropList ->
            next
    end,
    {_,NewDropTingList} = 
        lists:foldl(
          fun(DropThing,{RestPosList,NewDropTingList}) ->
                  case length(RestPosList) > 0 of
                      true ->
                          [{X, Y}|NewRestPosList] = RestPosList,
                          Pos = #p_pos{tx = X, ty = Y, dir = 1},
                          NewDropThing = DropThing#p_map_dropthing{pos = Pos},
                          case get({ref2,X,Y}) of
                              undefined ->
                                  put({ref2,X,Y},{dropthing,[NewDropThing]});
                              {dropthing,Ref2List} when is_list(Ref2List) ->
                                  put({ref2,X,Y},{dropthing,[NewDropThing|Ref2List]})
                          end,
                          Slice = mgeem_map:get_slice_by_txty(X, Y, OffsetX, OffsetY),
                          case get({dropthing,Slice}) of
                              undefined ->
                                  put({dropthing,Slice},[NewDropThing]);
                              Ref2List2 when is_list(Ref2List2) ->
                                  put({dropthing,Slice},[NewDropThing|Ref2List2]) 
                          end,
                          ID = NewDropThing#p_map_dropthing.id,
                          put({drop,ID},{unpick,NewDropThing}),
                          {NewRestPosList,[NewDropThing|NewDropTingList]};
                      false ->
                          {[],NewDropTingList}
                  end
          end, {PosList,[]}, AllDropList),
	set_protect_queue(?DROPTHING_PROTECT_OVER_TIME, {TX, TY, [I#p_map_dropthing.id || I <- NewDropTingList]}),
    AllSlice = mgeem_map:get_9_slice_by_txty(TX,TY,OffsetX,OffsetY),
    InSceneRoleList = mgeem_map:get_all_in_sence_user_by_slice_list(AllSlice),
    
    do_dropthing_enter_broadcast(IsInTeamDropMap,InSceneRoleList,NewDropTingList),
    
    case ActorType of
		{monster,_} ->
			?TRY_CATCH( do_drop_broadcast(RoleID,ActorID,NewDropTingList),ErrDropBc );
        monster ->
            ?TRY_CATCH( do_drop_broadcast(RoleID,ActorID,NewDropTingList),ErrDropBc );
        _ ->
            ignore
    end,
    NewDropTingList.

do_monster_dead_must_drop({monster,MonsterID},DropThingList) -> 
[MonsterMustDropItem] = common_config_dyn:find(monster_dead_drop,drop_item),
	MustDropItem =
	case lists:keyfind(MonsterID, 1, MonsterMustDropItem) of
		false ->
			[];
		{_,Value} ->
			Value
	end,
	lists:foldl(fun(DropThing,Acc) -> 
						{MustDropList,Other} = Acc,
						#p_map_dropthing{goodstypeid=TypeID} = DropThing,
						case lists:member(TypeID, MustDropItem) of
							true ->
								{[DropThing|MustDropList],lists:delete(DropThing, Other)};
							false ->
								Acc
						end
						end, {[],DropThingList}, DropThingList);
do_monster_dead_must_drop(_MonsterID,DropThingList) ->
	DropThingList.
	
	

do_dropthing_enter_broadcast(false,InSceneRoleList,DropTingList)->
    Record = #m_map_dropthing_enter_toc{dropthing = DropTingList},
    mgeem_map:broadcast(InSceneRoleList, ?DEFAULT_UNIQUE, ?MAP, ?MAP_DROPTHING_ENTER, Record);
do_dropthing_enter_broadcast(_IsInTeamDropMap=true,_InSceneRoleList,DropTingList)->
    {DropMoneyList,DropPropList} = 
        lists:partition(
          fun(#p_map_dropthing{ismoney=IsMoney})->
                  IsMoney
          end, DropTingList),
    
    %%分类出每个玩家对应的组队掉落的物品
    RoleDropThingList = 
        case DropPropList of
            []->
                case DropMoneyList=:=[] of
                    true->
                        [];
                    false->
                        [#p_map_dropthing{roles=Roles}|_]=DropMoneyList,
                        [{Role,DropMoneyList}||Role<-Roles]
                end;
            _->
                lists:foldl(
                  fun(E,AccIn)-> 
                          #p_map_dropthing{roles=[Role|_T]}=E,
                          case lists:keyfind(Role, 1, AccIn) of
                              false->
                                  NewRoleDropProps = {Role,[E|DropMoneyList]};
                              {_,OldList}->
                                  NewRoleDropProps = {Role,[E|OldList]}
                          end,
                          lists:keystore(E, 1, AccIn, NewRoleDropProps)
                  end, [], DropPropList)
        end,
    %%每个组队的玩家只广播属于自己的掉落物品
    lists:foreach(
      fun({RoleID2,DropTingList2})->
              Record = #m_map_dropthing_enter_toc{dropthing = DropTingList2},
              mgeem_map:broadcast([RoleID2], ?DEFAULT_UNIQUE, ?MAP, ?MAP_DROPTHING_ENTER, Record)
      
      end, RoleDropThingList),
    ok.


do_drop_broadcast(RoleID,MonsterID,DropTingList) ->
    #monster_state{monster_info=MonsterInfo} = mod_map_monster:get_monster_state(MonsterID),
    MonsterType = MonsterInfo#p_monster.typeid,
    case common_config_dyn:find(monster_drop_broadcast,MonsterType) of
        [] ->
            ignore;
        [#monster_drop_broadcast{content=Content,goods_type_list=GoodsTypeList}] ->
            DropTypeIDList =
                lists:foldl(
                  fun(#p_map_dropthing{goodstypeid=GoodsTypeID, goodstype=GoodsType, colour=Colour}, Acc) ->
                          case lists:member(GoodsTypeID, GoodsTypeList) of
                              true ->
                                  [{GoodsTypeID, GoodsType, Colour}|Acc];
                              _ ->
                                  Acc
                          end
                  end, [], DropTingList),
            
            case DropTypeIDList of
                [] ->
                    ignore;
                _ ->
                    DropNameList = mod_hero_fb:get_drop_goods_name(DropTypeIDList),
                    {ok, #p_role_base{role_name=RoleName, faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
                    
                    Msg = common_misc:format_lang(Content, [mod_hero_fb:get_role_name_color(RoleName, FactionID), DropNameList]),
                    
                    common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD, Msg)
            end
    end.

do_dropthing_quit(DropThing,State) when is_record(DropThing,p_map_dropthing)->
    #p_map_dropthing{pos = Pos } = DropThing,
    #p_pos{tx = TX, ty = TY} = Pos,
    #map_state{offsetx = OffsetX, offsety = OffsetY} = State,
    do_dropthing_quit(TX, TY, OffsetX, OffsetY, [DropThing]).

do_dropthing_quit(TX, TY, OffsetX, OffsetY, DropThingList) ->
    AllSlice = mgeem_map:get_9_slice_by_txty(TX,TY,OffsetX,OffsetY),
    RoleList = mgeem_map:get_all_in_sence_user_by_slice_list(AllSlice),
    
    lists:foreach(
      fun(Slice) ->
              case get({dropthing,Slice}) of
                  undefined ->
                      nil;
                  Ref2List when is_list(Ref2List) ->
                      Ref2List2 = lists:foldl(
                                    fun(Arg,Acc) ->
                                            lists:keydelete(Arg#p_map_dropthing.id, #p_map_dropthing.id, Acc)        
                                    end, Ref2List,DropThingList),
                      put({dropthing,Slice},Ref2List2)
              end
      end,AllSlice),
    IDList =
        lists:foldl(
          fun(DropThing,Acc) ->
                  #p_map_dropthing{
                                   id = ID,
                                   pos = Pos
                                  } = DropThing,
                  #p_pos{tx = X, ty = Y} = Pos,
                  case get({ref2,X,Y}) of
                      undefined ->
                          nil;
                      {dropthing,Ref2List3} when is_list(Ref2List3) ->
                          Ref2List4 = lists:keydelete(DropThing#p_map_dropthing.id, #p_map_dropthing.id, Ref2List3),
                          put({ref2,X,Y},{dropthing,Ref2List4})
                  end,
                  case get({drop,ID}) of
                      undefined ->
                          Acc;
                      _ ->
                          [ID|Acc]
                  end
          end, [], DropThingList),
    lists:foreach(
      fun(DropThing) ->
              #p_map_dropthing{id = ID} = DropThing,
              erase({drop,ID})
      end, DropThingList),
    case length(IDList) > 0 of
        true ->
            Record = #m_map_dropthing_quit_toc{dropthingid = IDList},
            mgeem_map:broadcast(RoleList, ?DEFAULT_UNIQUE, ?MAP, ?MAP_DROPTHING_QUIT, Record);
        false ->
            nil
    end.

do_dropthing_quit(TX, TY, OffsetX, OffsetY, DropThingList, RolePid) ->
    AllSlice = mgeem_map:get_9_slice_by_txty(TX,TY,OffsetX,OffsetY),
    RoleList = mgeem_map:get_all_in_sence_user_by_slice_list(AllSlice),
    lists:foreach(
      fun(Slice) ->
              case get({dropthing,Slice}) of
                  undefined ->
                      nil;
                  Ref2List when is_list(Ref2List) ->
                      Ref2List2 = lists:foldl(
                                    fun(Arg,Acc) ->
                                            lists:keydelete(Arg#p_map_dropthing.id, #p_map_dropthing.id, Acc)
                                    end, Ref2List,DropThingList),
                      put({dropthing,Slice},Ref2List2)
              end
      end,AllSlice),
    NewRoleList =
        lists:foldl(
          fun(Role,Acc)->
                  case Role =:= RolePid of
                      true->
                          Acc;
                      false ->
                          [Role|Acc]
                  end
          end, [], RoleList),
    IDList =
        lists:foldl(
          fun(DropThing,Acc) ->
                  #p_map_dropthing{
                                   id = ID,
                                   pos = Pos
                                  } = DropThing,
                  #p_pos{tx = X, ty = Y} = Pos,
                  case get({ref2,X,Y}) of
                      undefined ->
                          nil;
                      {dropthing,Ref2List3} when is_list(Ref2List3) ->
                          Ref2List4 = lists:keydelete(DropThing#p_map_dropthing.id, #p_map_dropthing.id, Ref2List3),
                          put({ref2,X,Y},{dropthing,Ref2List4})
                  end,
                  case get({drop,ID}) of
                      undefined ->
                          Acc;
                      _ ->
                          [ID|Acc]
                  end
          end, [], DropThingList),                                                            
    lists:foreach(
      fun(DropThing) ->
              #p_map_dropthing{id = ID} = DropThing,
              erase({drop,ID})
      end, DropThingList),
    case length(IDList) > 0 of
        true ->
            Record = #m_map_dropthing_quit_toc{dropthingid = IDList},
            mgeem_map:broadcast(NewRoleList, ?DEFAULT_UNIQUE, ?MAP, ?MAP_DROPTHING_QUIT, Record);
        false ->
            nil
    end.


do_dropthing_pick_protect_over(DropThingList) 
  when is_list(DropThingList)->
    lists:foreach(
      fun(DropThing) ->
              #p_map_dropthing{id = ID,goodstypeid = GoodsTypeId} = DropThing,
              case GoodsTypeId =:= 12600001 of
                  true ->
                      nil;
                  _ ->
                      case get({drop,ID}) of
                          undefined ->
                              nil;
                          {_A,_} ->
                              NewDropThing = DropThing#p_map_dropthing{roles = []},
                              put({drop,ID},{_A,NewDropThing})
                      end
              end
      end, DropThingList).

pick_dropthing(Unique, DataIn, RoleID, PID, State) ->
    #m_map_dropthing_pick_tos{dropthingid = ID} = DataIn,
    Ret = 
        case get({drop,ID}) of
            undefined ->
                {fail,?_LANG_DROPTHING_NOT_FOUND};
			{picking, _DropThing} ->
				{fail,?_LANG_DROPTHING_BUSING};
            {unpick,DropThing} ->
                #p_map_dropthing{roles = RoleList,goodstype=GoodsType,goodstypeid = GoodsTypeId} = DropThing,
                NewRoleList =
                    case RoleList of
                        [] ->
                            [RoleID];
                        _ ->
                            RoleList
                    end,
				%% 保护时间只对藏宝图有效
                case intlist_keyfind(RoleID, NewRoleList) =:= false andalso GoodsTypeId =:= 10410015 of
                    true ->
                        {fail,?_LANG_DROPTHING_PICK_PROTECEED};
                    _ ->
                        case check_inpick_distance(RoleID,DropThing) of
                            true ->
                                #map_state{offsetx = OffsetX, offsety = OffsetY} = State,
                                case GoodsType of
                                    ?DROPTHING_TYPE_HEROBOX->
                                        pick_hero_box(Unique, RoleID, DropThing, PID );
                                    ?DROPTHING_TYPE_KINGBOX->
                                        pick_king_box(Unique, RoleID, DropThing, PID );
                                    _ ->
										put({drop,ID}, {picking, DropThing}),
                                        pick(Unique,RoleID,DropThing,OffsetX,OffsetY, PID)
                                end;
                            false ->
                                {fail,?_LANG_DROPTHING_TOO_FAR_AWAY}
                        end
                end;
            _ ->
                {fail,?_LANG_DROPTHING_NOT_FOUND}
        end,
    case Ret of
        {fail,Reason} ->
            DataRecord = #m_map_dropthing_pick_toc{succ = false, reason = Reason,dropthingid = ID},
            common_misc:unicast({role, RoleID}, Unique, ?MAP, ?MAP_DROPTHING_PICK, DataRecord);
        _ ->
            nil
    end.


intlist_keyfind(Key,List) ->
    lists:foldl(
      fun(Value,Acc)->
              Acc orelse Value =:= Key
      end, false, List).


check_inpick_distance(RoleID,DropThing) ->
    Pos = DropThing#p_map_dropthing.pos,
    #p_pos{tx = TX, ty = TY} = Pos,
    ActorPos = mod_map_actor:get_actor_txty_by_id(RoleID,role),
    case ActorPos of
        {X,Y} ->
            abs(TX - X) =< ?PICK_DISTANCE andalso abs(TY - Y) =< ?PICK_DISTANCE;
        _ ->
            false
    end.

%%拾取境界副本的宝箱
pick_hero_box(Unique, _RoleID, DropThing, PID )->
    #p_map_dropthing{id = ID } = DropThing,
    %%mod_hero_fb:hook_pick_box(RoleID,DropThing),
    R3 = #m_map_dropthing_pick_toc{succ = true, pick_type=?PICK_TYPE_HERO_BOX, goods = undefined, num=1, dropthingid = ID},
    Module = ?MAP,
    Method = ?MAP_DROPTHING_PICK,
    ?UNICAST_TOC( R3 ),
    ok.

%%拾取王座争霸战的密匣
pick_king_box(Unique, RoleID, DropThing, PID )->
    #p_map_dropthing{id = ID } = DropThing,
    mod_warofking:hook_pick_king_box(RoleID,DropThing),
    
    R3 = #m_map_dropthing_pick_toc{succ = true, pick_type=?PICK_TYPE_KING_BOX, goods = undefined, num=1, dropthingid = ID},
    Module = ?MAP,
    Method = ?MAP_DROPTHING_PICK,
    ?UNICAST_TOC( R3 ),
    ok.


%%@param 当goodstype=11，表示特殊的道具——宝箱
pick(Unique, RoleID, DropThing, OffsetX, OffsetY, PID) ->
    #p_map_dropthing{
                     id = ID,
                     ismoney = IsMoney,
                     bind=Bind,
                     money = Money,
                     pos = Pos
                    } = DropThing,
    if
        IsMoney->
            #p_pos{tx = TX, ty = TY} = Pos,
            pick_silver(Bind, Unique, RoleID, Money, ID),
            do_dropthing_quit(TX,TY,OffsetX, OffsetY, [DropThing],PID),
            ok;
        true->
			mgeer_role:run(RoleID, fun() ->
            	mod_goods:pick_dropthing(DropThing,Unique,RoleID)
			end)
    end.     

pick_silver(Bind,  Unique, RoleID, AddNum, ID) ->
    case common_transaction:transaction(
           fun() ->
                   common_consume_logger:gain_silver(
                     {RoleID, 
                      0, 
                      AddNum, 
                      ?GAIN_TYPE_SILVER_FROM_PICKUP,
                      ""
                     }),
                   {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
                   if Bind =:= true ->
                           common_consume_logger:gain_silver({RoleID, AddNum, 0, ?GAIN_TYPE_SILVER_FROM_PICKUP,""}),
                           SilverBind = RoleAttr#p_role_attr.silver_bind,
                           NewSilverBind = SilverBind + AddNum,
                           Result = {silver_bind, NewSilverBind,1},
                           NewRoleAttr = RoleAttr#p_role_attr{silver_bind = NewSilverBind};
                       true ->
                           common_consume_logger:gain_silver({RoleID, 0, AddNum, ?GAIN_TYPE_SILVER_FROM_PICKUP,""}),
                           Silver = RoleAttr#p_role_attr.silver,
                           NewSilver = Silver + AddNum,
                           Result = {silver, NewSilver,2},
                           NewRoleAttr = RoleAttr#p_role_attr{silver = NewSilver}
                   end,
                   mod_map_role:set_role_attr(RoleID, NewRoleAttr),
                   Result
           end) of
        {atomic, {_, NewNum,MoneyType}} ->
            %% MoneyType 1绑定 2不绑定
            Data = #m_map_dropthing_pick_toc{money = NewNum, dropthingid = ID,add_money = AddNum,money_type = MoneyType},
            common_misc:unicast({role,RoleID}, Unique, ?MAP, ?MAP_DROPTHING_PICK, Data);
        {aborted, Reason} ->
            ?ERROR_MSG("拾取钱币失败,RoleID:~w AddNum:~w Reason:~w",[RoleID, AddNum, Reason])
    end.

get_droppos_list(MapID,TX,TY,Num) ->
    List = [{-1,0},{1,0},{0,-1},{0,1},
            {-1,-1},{1,-1},{-1,1},{1,1},
            {0,0},
            {-2,0},{2,0},{0,-2},{0,2},
            {-2,-1},{-2,1},{2,-1},{2,1},
            {-1,-2},{1,-2},{-1,2},{1,2},
            {-2,-2},{2,-2},{2,-2},{2,2}],
    {PosList,Count} = 
        lists:foldl(
          fun({X,Y},{PosList,Count})->
                  case Count >= Num of
                      true ->
                          {PosList,Count};
                      false ->
                          XX = TX + X,
                          YY = TY + Y,
                          case mcm:is_walkable(MapID,{XX,YY}) of 
                              false ->
                                  {PosList,Count};
                              _ ->
                                  case get({ref2,XX,YY}) of
                                      undefined ->
                                          {[{XX,YY}|PosList],Count+1};
                                      _ ->
                                          {PosList,Count}
                                  end
                          end
                  end
          end,{[],0}, List),
    case Count =:= Num of
        true->
            PosList;
        false ->
            {PosList3,_Count3} = 
                lists:foldl(
                  fun({X,Y},{PosList2,Count2})->
                          case Count2 >= Num of
                              true ->
                                  {PosList2,Count2};
                              false ->
                                  XX = TX + X,
                                  YY = TY + Y,
                                  case mcm:is_walkable(MapID,{XX,YY}) of 
                                      false ->
                                          {PosList2,Count2};
                                      _ ->
                                          case get({ref2,XX,YY}) of
                                              undefined ->
                                                  {PosList2,Count2};
                                              _ ->
                                                  {[{XX,YY}|PosList2],Count2+1}
                                          end
                                  end
                          end
                  end,{PosList,Count}, List),
            PosList3
    end.

%%@doc 获取简单的怪物掉落物品的列表
%%@return {ok,DropPropList}
get_monster_drop_prop_list(MonsterTypeID) when is_integer(MonsterTypeID)->
	DropInfoList = get_monster_dropinfo_list(MonsterTypeID),
	DropPropList = lists:foldl(
					 fun(E,AccIn)->
							 case get_monster_drop_prop_list_2(E) of
								 false-> AccIn;
								 DropProp->
									 [DropProp|AccIn]
							 end
					 end, [], DropInfoList),
	{ok,DropPropList}.
get_monster_drop_prop_list_2(DropInfo)->
	#p_drop_info{drops = SingleDropList, rate = Rate, max_num = MaxNum, drop_mode = DropMode } = DropInfo,
	Rand = random:uniform(10000),
	case Rate >= Rand of
		true->
			SeedNum = lists:sum( [ Wt||#p_single_drop{weight=Wt}<-SingleDropList ] ),
			Rand2 = random:uniform(SeedNum),
			case catch get_monster_drop_prop_list_3(SingleDropList,Rand2,MaxNum,DropMode,0) of
				{ok,DropProp}->  
					DropProp;
				_ ->
					false
			end;
		_ ->
			false
	end.
get_monster_drop_prop_list_3([],_,_,_,_AccSum)->
	false;
get_monster_drop_prop_list_3([SingleDrop|T],Rand2,MaxNum,DropMode,AccSum)->
	#p_single_drop{type = PropType, typeid = PropTypeID,weight = W} = SingleDrop,
	Sum2 = AccSum + W,
	case Sum2 >= Rand2 of
		true ->
			Num = common_tool:random(1,MaxNum),
			case erlang:is_record(DropMode, p_drop_mode) of
				true ->
					DropProperty = get_drop_mode_property(DropMode),
					#p_drop_property{bind=IsBind,colour=Color} = DropProperty;
				_ ->
					IsBind = true,
					case PropType of
						?TYPE_ITEM ->
							[#p_item_base_info{colour = Color}] = common_config_dyn:find_item(PropTypeID);
						?TYPE_STONE ->
							[#p_stone_base_info{colour = Color}] = common_config_dyn:find_stone(PropTypeID);
						_ ->
							Color = ?COLOUR_WHITE
					end
			end,
			{ok,#p_reward_prop{prop_id=PropTypeID,prop_type=PropType,prop_num=Num,bind=IsBind,color=Color}};
		_ ->
			get_monster_drop_prop_list_3(T,Rand2,MaxNum,DropMode,Sum2)
	end. 

%%获取怪物的掉落物品列表
%%@return [#p_map_dropthing]
get_monster_dropthing_list(IsInTeamDropMap,MonsterTypeID, DropInfoList,RoleID, MinMoney, MaxMoney, FcmIndex, LevelIndex, EnergyIndex) ->
    PickRoleList = common_misc:team_get_can_pick_goods_role(RoleID),
    %%掉钱币
    DropMoneyList =
        case MaxMoney < MinMoney orelse MinMoney =:= 0 of
            false ->
                Money = common_tool:random(MinMoney,MaxMoney),
                DropID = mod_map_drop:get_new_dropthing_id(),
                DropMoney = #p_map_dropthing{
                  id = DropID,
                  ismoney = true,
                  roles = PickRoleList,
                  num = 1,
                  bind = true,
                  money = Money},
                [DropMoney];
            true ->
                []
        end,
    MapID = mgeem_map:get_mapid(),
    case common_config_dyn:find(monster_drop_times, {MapID, MonsterTypeID}) of 
        [] ->
            MonsterDropTypeID = undefined,
            DropInfoList2 = DropInfoList;
        [{MaxKill, [{MonsterDropGroup, MonsterDropTypeID}]}] ->
            KillTimes = get_role_monster_drop_times(RoleID, {MapID, MonsterTypeID}),
            case KillTimes >= MaxKill of 
                true ->
                    {_, DropInfoList2} = lists:foldl(
                                           fun(#p_drop_info{drops=Drops}=Drop, {CurGroup, InfoList}) ->
                                                   case CurGroup =:= MonsterDropGroup of 
                                                       true ->
                                                           case lists:keyfind(MonsterDropTypeID, #p_single_drop.typeid, Drops) of 
                                                               false ->
                                                                   {CurGroup+1, [Drop|InfoList]};
                                                               D ->
                                                                   {CurGroup+1, [Drop#p_drop_info{drops=[D], rate=10000}|InfoList]}
                                                           end;
                                                       _ ->
                                                           {CurGroup+1, [Drop|InfoList]}
                                                   end
                                           end, {1, []}, DropInfoList);
                _ ->
                    DropInfoList2 = DropInfoList
            end
    end,
    %%掉落道具
    DropThingList2 =
        lists:foldl(
          fun(DropInfo,AccList) ->
                  case IsInTeamDropMap of
                      true->
                          lists:foldl(
                            fun(PickRoleId,AccInTeam)-> 
                                    get_monster_dropthing_list2(RoleID,DropInfo,AccInTeam,[PickRoleId], FcmIndex, LevelIndex, EnergyIndex)		  
                            end, AccList, PickRoleList);
                      _ ->
                          get_monster_dropthing_list2(RoleID,DropInfo,AccList,PickRoleList, FcmIndex, LevelIndex, EnergyIndex)
                  end
          end, DropMoneyList, DropInfoList2),
    case MonsterDropTypeID of 
        undefined ->
            ignore;
        _ ->
            case lists:keyfind(MonsterDropTypeID, #p_map_dropthing.goodstypeid, DropThingList2) of 
                false ->
                    add_role_monster_drop_times(RoleID, {MapID, MonsterTypeID});
                _ ->
                    reset_role_monster_drop_times(RoleID, {MapID, MonsterTypeID})
            end 
    end,
    DropThingList2.

get_monster_dropthing_list2(RoleID,DropInfo,DropAccList,PickRoleList, FcmIndex, LevelIndex, EnergyIndex) ->
    #p_drop_info{
                 drops = SingleDropList,
                 rate = Rate,
                 max_num = MaxNum,
                 drop_mode = DropMode
                } = DropInfo,
    Rate2 = Rate * FcmIndex * LevelIndex * EnergyIndex,
    Rand = random:uniform(10000),
    
    case Rate2 >= Rand of
        true->
            SeedNum = lists:foldl(
                        fun(SingleDroup,Acc) ->
                                Acc+ SingleDroup#p_single_drop.weight
                        end,0,SingleDropList),
            Rand2 = random:uniform(SeedNum),
            case catch lists:foldl(
                   fun(SingleDrop,{Sum,_DropThing}) ->
                           get_monster_dropthing_list3(RoleID,
													   SingleDrop,
                                                       Sum,
                                                       _DropThing,
                                                       Rand2,
                                                       MaxNum,
                                                       PickRoleList,
                                                       DropMode)    
                   end, {0,undefined}, SingleDropList)
                of
                {ok,DropThing} when is_record(DropThing,p_map_dropthing) ->  
                    [DropThing|DropAccList];
                {ok,TeamDropList} when is_list(TeamDropList)->
                    lists:merge(TeamDropList, DropAccList);
                {_,undefined} ->
                    DropAccList
            end;
        false ->
            DropAccList
    end.


get_monster_dropthing_list3(RoleID,SingleDrop,Sum,_DropThing,Rand2,MaxNum,PickRoleList,DropMode) ->
    #p_single_drop{type = Type, typeid = TypeID,weight = W} = SingleDrop,
    Sum2 = Sum + W,
    case Sum2 >= Rand2 of
		true ->
			case drop_call_monster_item(RoleID,TypeID) of
				true ->
					{Sum2,_DropThing};
				false ->
					Num = common_tool:random(1,round(MaxNum)),
					case erlang:is_record(DropMode, p_drop_mode) =:= true of
						true ->
							DropProperty = get_drop_mode_property(DropMode);
						_ ->
							case Type of
								?TYPE_ITEM ->
									[#p_item_base_info{colour = ItemColour}] = common_config_dyn:find_item(TypeID);
								?TYPE_STONE ->
									[#p_stone_base_info{colour = ItemColour}] = common_config_dyn:find_stone(TypeID);
								_ ->
									ItemColour = 1
							end,
							DropProperty = #p_drop_property{bind = false,colour = ItemColour, quality = 1, use_bind=0}
					end,
					MapDropThingList = get_monster_dropthing_list4(PickRoleList,Num,Type,TypeID,DropProperty),
					throw({ok,MapDropThingList})
			end;
        false ->
            {Sum2,_DropThing}
    end.

%%进行组队掉落的特殊处理，每个组队的成员都可以看到和捡到属于自己的物品
%%@param 当Type=GoodsType=11表示它是特殊道具——宝箱。
get_monster_dropthing_list4(PickRoleList,Num,Type,TypeID,DropProperty)->
    ID = mod_map_drop:get_new_dropthing_id(),
    #p_map_dropthing{ id = ID, roles = PickRoleList,
                      num = Num,
                      goodstype = Type,
                      goodstypeid = TypeID,
                      drop_property = DropProperty,
                      bind=DropProperty#p_drop_property.bind,
                      colour=DropProperty#p_drop_property.colour}.

%%掉落的是怪物召唤道具，则直接使用
drop_call_monster_item(RoleID,TypeID) ->
	case common_config_dyn:find_item(TypeID) of
		[] ->
			false;
		[ItemBaseInfo] ->
			#p_item_base_info{effects=Effects}=ItemBaseInfo,
			case Effects of
				[#p_item_effect{funid=FunID,parameter=MonsterTypeID}|_] ->
					case common_config_dyn:find(item_effect,FunID) of
						[{_,item_call_monster}] ->
							?TRY_CATCH(mod_map_monster:call_monster_around_role(RoleID,common_tool:to_integer(MonsterTypeID),1200)),
							true;
						_ ->
							false
					end;
				_ ->
					false
			end
	end.

get_drop_mode_property(DropMode)
  when erlang:is_record(DropMode, p_drop_mode)->
    Pro = #p_drop_property{},
    Rate = DropMode#p_drop_mode.bind_rate,
    UseBind = DropMode#p_drop_mode.use_bind,
    Rand = random:uniform(100),
    case Rand > Rate of
        true ->
            get_drop_mode_property2(#p_drop_mode.unbind_colour,
                                    DropMode,
                                    Pro#p_drop_property{bind = false, use_bind = UseBind});
        false ->           
            get_drop_mode_property2(#p_drop_mode.bind_colour,
                                    DropMode,
                                    Pro#p_drop_property{bind = true, use_bind = UseBind})
    end;
get_drop_mode_property(_) ->
    #p_drop_property{bind = false,colour = 1, quality = 1, use_bind=0}.

get_drop_mode_property2(#p_drop_mode.bind_colour,DropMode, Pro) ->
    {P,_} = get_drop_property(DropMode#p_drop_mode.bind_colour),
    P1 = case P of undefined -> 1;P -> P end,
    get_drop_mode_property2(#p_drop_mode.bind_quality,
                            DropMode, 
                            Pro#p_drop_property{colour=P1});
get_drop_mode_property2(#p_drop_mode.bind_quality,DropMode,Pro) ->
    {P,_} = get_drop_property(DropMode#p_drop_mode.bind_quality),
    P1 = case P of undefined -> 1;P -> P end,
    get_drop_mode_property2(#p_drop_mode.bind_hole,
                            DropMode, 
                            Pro#p_drop_property{quality=P1});
get_drop_mode_property2(#p_drop_mode.bind_hole,DropMode,Pro) ->
    {P,_} = get_drop_property(DropMode#p_drop_mode.bind_hole),
    P1 = case P of undefined -> 0;P -> P end,
    Pro#p_drop_property{hole_num=P1};

get_drop_mode_property2(#p_drop_mode.unbind_colour,DropMode, Pro) ->
    {P,_} = get_drop_property(DropMode#p_drop_mode.unbind_colour),
    P1 = case P of undefined -> 1;P -> P end,
    get_drop_mode_property2(#p_drop_mode.unbind_quality,
                            DropMode, 
                            Pro#p_drop_property{colour=P1});
get_drop_mode_property2(#p_drop_mode.unbind_quality,DropMode,Pro) ->
    {P,_} = get_drop_property(DropMode#p_drop_mode.unbind_quality),
    P1 = case P of undefined -> 1;P -> P end,
    get_drop_mode_property2(#p_drop_mode.unbind_hole,
                            DropMode, 
                            Pro#p_drop_property{quality=P1});
get_drop_mode_property2(#p_drop_mode.unbind_hole,DropMode,Pro) ->
    {P,_} = get_drop_property(DropMode#p_drop_mode.unbind_hole),
    P1 = case P of undefined -> 0;P -> P end,
    Pro#p_drop_property{hole_num=P1}.

get_drop_property([]) ->
    {undefined,undefined};
get_drop_property(Addition)
  when is_list(Addition) ->
    Sum = lists:foldl(
            fun({_,_,R},Acc) ->
                    R+Acc
            end,0,Addition),
    Rate = random:uniform(Sum),
    catch lists:foldl(
      fun({_,P1,S1},{P2,S2}) ->
              if (S1+S2) > Rate ->
                     throw({P1,S1});
                 true ->
                     {P2,S1+S2}
              end
      end,{undefined,0},Addition).

drop_silver(_Pos, 0) ->
    ignore;
drop_silver(Pos,Num) ->
    #p_pos{tx=X,ty=Y}=Pos,
    #map_state{mapid = MapID, offsetx = OffsetX, offsety = OffsetY} = mgeem_map:get_state(),
    DropMoney = 
        #p_map_dropthing{roles = [],
                         id = mod_map_drop:get_new_dropthing_id(),
                         ismoney = true, 
						 bind = true, 
                         pos = Pos,
                         num = 1,
                         money = Num},
    case mcm:is_walkable(MapID, {X,Y}) of
        false ->
            error;
        _ ->
            case get({ref2,X,Y}) of
                undefined ->
                    put({ref2,X,Y},{dropthing,[DropMoney]});
                {dropthing,Ref2List} when is_list(Ref2List) ->
                    put({ref2,X,Y},{dropthing,[DropMoney|Ref2List]})
            end,
            Slice = mgeem_map:get_slice_by_txty(X, Y, OffsetX, OffsetY),
            case get({dropthing,Slice}) of
                undefined ->
                    put({dropthing,Slice},[DropMoney]);
                Ref2List2 when is_list(Ref2List2) ->
                    put({dropthing,Slice},[DropMoney|Ref2List2]) 
            end,
            put({drop,DropMoney#p_map_dropthing.id},{unpick,DropMoney}),
			set_quit_map_queue(?DROPTHING_QUIT_MAP_TIME, {X, Y, [DropMoney#p_map_dropthing.id]}),
            AllSlice = mgeem_map:get_9_slice_by_txty(X,Y,OffsetX,OffsetY),
            RoleList = mgeem_map:get_all_in_sence_user_by_slice_list(AllSlice),
            Record = #m_map_dropthing_enter_toc{dropthing = [DropMoney]},
            mgeem_map:broadcast(RoleList, ?DEFAULT_UNIQUE, ?MAP, ?MAP_DROPTHING_ENTER, Record)
    end.

%% ========================================================================

%% @doc 初始化角色打怪未掉落纪录
set_role_monster_drop(RoleID, DropInfo) ->
    {atomic, _} = common_transaction:t(fun() -> t_set_role_monster_drop(RoleID, DropInfo) end).

t_set_role_monster_drop(RoleID, DropInfo) ->
    mod_map_role:update_role_id_list_in_transaction(RoleID, ?role_monster_drop, ?role_monster_drop_copy),
    erlang:put({?role_monster_drop, RoleID}, DropInfo).

%% @doc 清除角色打怪未掉落纪录
clear_role_monster_drop(RoleID) ->
    erlang:erase({?role_monster_drop, RoleID}).

%% @doc 获取角色打怪未掉落纪录
get_role_monster_drop(RoleID) ->
    case erlang:get({?role_monster_drop, RoleID}) of
        undefined ->
            {error, not_found};
        DropInfo ->
            {ok, DropInfo}
    end.

%% @doc 获取打某个怪未掉落的数据
get_role_monster_drop_times(RoleID, {MapID, MonsterTypeID}) ->
    case get_role_monster_drop(RoleID) of
        {error, _} ->
            0;
        {ok, #r_role_monster_drop{kill_times=KillTimes}} ->
            case lists:keyfind({MapID, MonsterTypeID}, 1, KillTimes) of
                false ->
                    0;
                {_, Times} ->
                    Times
            end 
    end.

%% @doc 增加角色打某个怪未掉落的次数
add_role_monster_drop_times(RoleID, {MapID, MonsterTypeID}) ->
    case get_role_monster_drop(RoleID) of
        {error, _} ->
            DropInfo2 = #r_role_monster_drop{role_id=RoleID, kill_times=[{{MapID, MonsterTypeID}, 1}]};
        {ok, #r_role_monster_drop{kill_times=KillTimes}=DropInfo} ->
            case lists:keyfind({MapID, MonsterTypeID}, 1, KillTimes) of
                false ->
                    Add = {{MapID, MonsterTypeID}, 1};
                {_, Times} ->
                    Add = {{MapID, MonsterTypeID}, Times+1}
            end,
            DropInfo2 = DropInfo#r_role_monster_drop{kill_times=[Add|lists:keydelete({MapID, MonsterTypeID}, 1, KillTimes)]}
    end,
    set_role_monster_drop(RoleID, DropInfo2).

%% @doc 重置角色打某个怪的未掉落次数
reset_role_monster_drop_times(RoleID, {MapID, MonsterTypeID}) ->    
    case get_role_monster_drop(RoleID) of
        {error, _} ->
            ignore;
        {ok, #r_role_monster_drop{kill_times=KillTimes}=DropInfo} ->
            DropInfo2 = DropInfo#r_role_monster_drop{kill_times=lists:keydelete({MapID, MonsterTypeID}, 1, KillTimes)},
            set_role_monster_drop(RoleID, DropInfo2)
    end.

check_protect_queue() ->
	Map = mgeem_map:get_mapid(),
	Queue = get({?DROPTHING_PROTECT_QUEUE, Map}),
	check_protect_queue(Map, Queue).

check_protect_queue(_Map, undefined) ->
	pass;
check_protect_queue(_Map, {0, []}) ->
	pass;
check_protect_queue(Map, {Len, List}) ->
	{Head, [{_Num, Time, Tail}]} = lists:split(Len - 1, List),
	case mgeem_map:get_now() >= Time of
		true ->
			catch do_protect_queue(Tail),
			put({?DROPTHING_PROTECT_QUEUE, Map}, {Len -1, Head});
		false ->
			pass
	end.



check_quit_map_queue() ->
	Map = mgeem_map:get_mapid(),
	Queue = get({?DROPTHING_QUIT_MAP_QUEUE, Map}),
	check_quit_map_queue(Map, Queue).
	
check_quit_map_queue(_Map, undefined) ->
	pass;
check_quit_map_queue(_Map, {0, []}) ->
	pass;
check_quit_map_queue(Map, {Len, List}) ->
	{Head, [{_Num, Time, Tail}]} = lists:split(Len - 1, List),
	case mgeem_map:get_now() >= Time of
		true ->
			catch do_quit_map_queue(Tail),
			put({?DROPTHING_QUIT_MAP_QUEUE, Map}, {Len - 1, Head});
		false ->
			pass
	end.


%% get({?DROPTHING_PROTECT_QUEUE, Map}) = {Num, List}
%% List : [Element, Element...]
%% Element : {Num, Time, [Drop...]}
%% Drop : {Tx, Ty, DropIdList}
%% DropIdList : [int()....]
set_protect_queue(TimeReval, {Tx, Ty, DropIdList}) ->
	NextTime = mgeem_map:get_now() + TimeReval,
	Map = mgeem_map:get_mapid(),
	case get({?DROPTHING_PROTECT_QUEUE, Map}) of
		L when L == undefined orelse L == {0, []} ->
			put({?DROPTHING_PROTECT_QUEUE, Map}, {1, [{1, NextTime, [{Tx, Ty, DropIdList}]}]});
		{TotalNum, [{Num, Time, H}| T] = List} ->
			case Num >= ?MAX_ITEM_LEN orelse Time /= NextTime of
				true ->
					put({?DROPTHING_PROTECT_QUEUE, Map}, {TotalNum + 1, [{1, NextTime, [{Tx, Ty, DropIdList}]} | List]});
				_ ->
					put({?DROPTHING_PROTECT_QUEUE, Map}, {TotalNum, [{Num + 1, NextTime, [{Tx, Ty, DropIdList} | H]} | T]})
			end
	end.

set_quit_map_queue(TimeReval, {Tx, Ty, DropIdList}) ->
	Map = mgeem_map:get_mapid(),
	NextTime = mgeem_map:get_now() + TimeReval,
	case get({?DROPTHING_QUIT_MAP_QUEUE, Map}) of
		L when L == undefined orelse L == {0, []} ->
			put({?DROPTHING_QUIT_MAP_QUEUE, Map}, {1, [{1, NextTime, [{Tx, Ty, DropIdList}]}]});
		{TotalNum, [{Num, Time, H} | T] = List} -> 
			case Num >= ?MAX_ITEM_LEN orelse Time /= NextTime of
				true ->
					put({?DROPTHING_QUIT_MAP_QUEUE, Map}, {TotalNum + 1, [{1, NextTime, [{Tx, Ty, DropIdList}]} | List]});
				_ ->
					put({?DROPTHING_QUIT_MAP_QUEUE, Map}, {TotalNum, [{Num + 1, NextTime, [{Tx, Ty, DropIdList} | H]} | T]})
			end
	end.

do_protect_queue(DropThingList) ->
	F = fun({Tx, Ty, DropIdList}) ->
				DropList = lists:foldl(fun(I, Acc) -> case get({drop, I}) of undefined -> Acc; {_, Val} -> [Val | Acc] end end, [], DropIdList),
				?TRY_CATCH( do_dropthing_pick_protect_over(DropList) ),
				%% 把保护计时结束后又没有拾取的放入到quit_map_queue
				set_quit_map_queue(?DROPTHING_QUIT_MAP_TIME - ?DROPTHING_PROTECT_OVER_TIME, {Tx, Ty, DropIdList})
		end,
	lists:foreach(F, DropThingList).

do_quit_map_queue(DropThingList) ->
	#map_state{offsetx = OffsetX, offsety = OffsetY} = mgeem_map:get_state(),
	F = fun({Tx, Ty, DropIdList}) ->
				DropList = lists:foldl(fun(I, Acc) -> case get({drop, I}) of undefined -> Acc; {_, Val} -> [Val | Acc] end end, [], DropIdList),
				?TRY_CATCH( do_dropthing_quit(Tx, Ty, OffsetX, OffsetY, DropList) )
		end,
	lists:foreach(F, DropThingList).

get_monster_dropinfo_list(MonsterTypeID)->
  case cfg_monster_drop:find(MonsterTypeID) of
    [#p_monster_drop_info{droplist = DropInfoList}]->
      DropInfoList;
    _ ->
      []
  end.

