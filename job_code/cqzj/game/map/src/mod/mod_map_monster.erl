%% Author: liuwei
%% Created: 2010-5-26
%% Description: TODO: Add description to mod_map_monster
-module(mod_map_monster).

-include("mgeem.hrl").

-define(PATROL_RATE,85).

%% 怪物出生死亡广播：全服广播
-define(BROADCAST_CHANNEL_WORLD, 1).
%% 国家广播
-define(BROADCAST_CHANNEL_FACTION, 2).

-define(monster_id_list,monster_id_list).

-define(MAX_MONSTER_ID,max_monster_id).
-define(MONSTER_BORN_CONDITION, monster_born_condition).
-define(CHECK_RARITY_BOSS_AI(Rarity),((Rarity=:=?BOSS) orelse (Rarity=:=?HUMAN_HELPER) orelse (Rarity=:=?BOSS_HELPER))).

-export([
         handle/2,
         monster_attr_change/3,
         update_monster_mapinfo/1,
         monster_transfer/4,
         loop_ms/1
        ]).

-export([
         do_monster_recover_max/1,
         get_monster_id_list/0,
         attack_monster/2,
         get_monster_state/1,
         set_monster_state/2,  
         reduce_hp/4,
         reduce_hp/6,
         set_next_work/3,
         set_next_work/4,
         update_next_work/3,
         update_next_work/4,
         delete_role_from_monster_enemy_list/3,
         monster_delete/1,
         get_role_level_index/4,
         get_role_energy_index/1,
         do_monster_recover/1,
         init/1,
         delete_all_monster/0
        ]).

-export([
		 init_map_monster/3,
         init_map_monster/2,
         init_monster_id_list/0,
         dirty_get_monster_persistent_info/1,
         get_max_monster_id_form_process_dict/0,
         create_family_boss/4,
         init_educate_fb_map_monster/4,
         get_hp_recover/3,
         init_call_fb_monster/3,
         init_call_fb_monster/4,
		 call_monster_around_role/3
        ]).

%%
%% ========================= API Functions =================================
%%
%%
%%==============================API FUNCTION========================
%%

set_next_work(MonsterID,AddTick,Msg) ->
    Now = common_tool:now2(),
    State = get_monster_state(MonsterID),
    LastWorkTick =  State#monster_state.next_work_tick,
    case Now - LastWorkTick < ?MIN_MONSTER_WORK_TICK of
        true ->
            NewTick = LastWorkTick + AddTick;
        false ->
            NewTick = Now + AddTick
    end,
    set_monster_state(MonsterID,State#monster_state{next_work_tick = NewTick,next_work_truple = Msg}).


set_next_work(MonsterID,AddTick,Msg,State) ->
    Now = common_tool:now2(),
    LastWorkTick = State#monster_state.next_work_tick,
    case Now - LastWorkTick < ?MIN_MONSTER_WORK_TICK of
        true ->
            NewTick = LastWorkTick + AddTick;
        false ->
            NewTick = Now + AddTick
    end,
    set_monster_state(MonsterID,State#monster_state{next_work_tick = NewTick,next_work_truple = Msg}).

update_next_work(MonsterID,NewTick,Msg) ->
    State = get_monster_state(MonsterID),
    set_monster_state(MonsterID,State#monster_state{next_work_tick = NewTick,next_work_truple = Msg}).


update_next_work(MonsterID,NewTick,Msg,State) ->
    set_monster_state(MonsterID,State#monster_state{next_work_tick = NewTick,next_work_truple = Msg}).


set_monster_state(MonsterID,State) ->
    put({monster_state,MonsterID},State).

get_monster_state(MonsterID) ->
    get({monster_state,MonsterID}).

get_monster_id_list() ->
    case erlang:get(?monster_id_list) of
      undefined -> [];
      Ret -> Ret
    end.

init_monster_id_list() ->
    erlang:put(?monster_id_list,[]).

init_map_monster(MapProcessName, MapID, Monsters) ->
	case lists:keyfind(MapID, 1, Monsters) of
		false ->
			init_map_monster(MapProcessName, MapID);
		{MapID, Monsters2} ->
			handle({dynamic_create_monster2, Monsters2}, 
				   #map_state{mapid=MapID, map_name=MapProcessName})
	end.
init_map_monster(MapProcessName, MapID) ->
  case cfg_monster_helper:can_init(MapID) andalso mcm:monster_tiles(MapID) of
    MonsterTiles when MonsterTiles == false;
                      MonsterTiles == [] ->
      case cfg_monster_helper:creation(MapID) of
        [] ->
          ignore;
        Creation ->
          handle(Creation, mgeem_map:get_state())
      end;
    MonsterTiles ->
      lists:foreach(fun
        ({MonsterType,Tx,Ty}) ->
          case get_monster_born_condition(MonsterType) of
              [] ->
                MonsterInfo = #p_monster{
                  reborn_pos = #p_pos{tx = Tx,ty = Ty,dir = 1},
                  monsterid  = get_max_monster_id_form_process_dict(),
                  typeid     = MonsterType,
                  mapid      = MapID
                },
                %% 判断副本中怪物能否重生
                MonsterCreateType = case common_config_dyn:find(fb_map,MapID) of
                  [#r_fb_map{can_monster_reborn=false}]->
                      ?MONSTER_CREATE_TYPE_MANUAL_CALL;
                  _ -> 
                      case ?IS_SOLO_FB(MapID) of 
                        true  -> ?MONSTER_CREATE_TYPE_MANUAL_CALL;
                        false -> ?MONSTER_CREATE_TYPE_NORMAL
                      end
                end,
                init([MonsterInfo, MonsterCreateType, MapID, MapProcessName, undefined, ?FIRST_BORN_STATE, null]);
              ConditionList ->
                set_monster_born_condition(MonsterType, ConditionList)
          end
      end, MonsterTiles)
  end.

%%@doc 手动召唤方式来出生怪物
init_call_fb_monster(MapProcessName,MapID,MonsterList)->
	init_call_fb_monster(MapProcessName,MapID,MonsterList,0).
init_call_fb_monster(MapProcessName,MapID,MonsterList,LiveTime)->
    [init([MonsterInfo,?MONSTER_CREATE_TYPE_MANUAL_CALL, MapID, MapProcessName, undefined, ?FIRST_BORN_STATE, null, LiveTime])
    ||MonsterInfo<-MonsterList].

init_educate_fb_map_monster(MapProcessName, MapID, MonsterList,MonsterType) ->
    lists:foreach(
     fun(MonsterInfo) ->
             CallBackFun = fun() ->
                                   global:send(MapProcessName, {mod_educate_fb, {monster_dead,MonsterType}})
                           end,
             init([MonsterInfo,?MONSTER_CREATE_TYPE_MANUAL_CALL, MapID, MapProcessName, CallBackFun, ?FIRST_BORN_STATE, null])
     end,MonsterList).


dirty_get_monster_persistent_info(MonsterID) ->
    db:dirty_read(?DB_MONSTER_PERSISTENT_INFO, MonsterID).

dirty_get_monster_persistent_info(TypeID,Key) ->
    db:dirty_match_object(?DB_MONSTER_PERSISTENT_INFO,#r_monster_persistent_info{typeid=TypeID, key=Key, _='_'}).


get_max_monster_id_from_mnesia() ->
    TableName = ?DB_MONSTERID_COUNTER,
    case get(?MAX_MONSTER_ID) of
        undefined ->
            MaxID = 1;
        ID ->
            MaxID = ID + 1
    end,
    Parrten = #r_monsterid_counter{id = 1 , _ = '_'},
    case db:transaction( 
           fun() ->
                   case db:match_object(TableName, Parrten, write) of
                       [] ->
                           Record = #r_monsterid_counter{id = 1,last_monster_id = MaxID},
                           db:write(TableName, Record, write),
                           MaxID;
                       [Record] ->
                           #r_monsterid_counter{last_monster_id = LastID} = Record,
                           MaxID2 = erlang:max(LastID+1,MaxID),
                           NewRecord = Record#r_monsterid_counter{last_monster_id = MaxID2},
                           db:write(TableName, NewRecord, write),
                           MaxID2
                   end
           end) of
        {atomic,MaxID3} ->
            put(?MAX_MONSTER_ID,MaxID3),
            MaxID3;
        {aborted,_} ->
            throw({error,get_max_monster_id_fail})
    end.

get_max_monster_id_form_process_dict() ->
    case get(?MAX_MONSTER_ID) of
        undefined ->
            MaxID = 1;
        ID ->
            MaxID = ID + 1
    end,
    put(?MAX_MONSTER_ID,MaxID),
    MaxID.



%%暂时不做检查
check_family_boss_alive()->
    false.

create_family_boss(Type, FamilyID, MonsterType, _Fun) ->
    case check_family_boss_alive() of
        true->
            ignore;
        _ ->
            create_family_boss_2(Type,FamilyID,MonsterType)
    end.

create_family_boss_2(Type,FamilyID,MonsterType)->
    [{MapID,Tx,Ty}] = common_config_dyn:find(server_pos,family_boss_born),
    
    Pos = #p_pos{tx=Tx, ty=Ty},
    MapName = common_map:get_family_map_name(FamilyID),
    
    case Type of 
        common ->
            %%普通boss的死亡回调函数
            CallBackFun = fun() ->
                                  FamilyPName = common_misc:make_family_process_name(FamilyID),
                                  RoleIDList = mod_map_actor:get_in_map_role(),
                                  
                                  RoleNum = erlang:length(RoleIDList),
                                  global:send(FamilyPName, {common_boss_dead, RoleNum, RoleIDList})
                          end;
        uplevel ->
            %%升级boss的死亡回调函数
            CallBackFun = fun() ->
                                  FamilyPName = common_misc:make_family_process_name(FamilyID),                                  
                                  RoleIDList = mod_map_actor:get_in_map_role(),
                                  
                                  RoleNum = erlang:length(RoleIDList),
                                  global:send(FamilyPName, {uplevel_boss_dead, RoleNum, RoleIDList})
                          end
    end,
    case dirty_get_monster_persistent_info(MonsterType,FamilyID) of
        [] ->
            MonsterID = get_max_monster_id_from_mnesia();
        [PersistentInfo] ->
            MonsterID = PersistentInfo#r_monster_persistent_info.monsterid;
        [PersistentInfo|L] ->
            MonsterID = PersistentInfo#r_monster_persistent_info.monsterid,
            lists:foreach(fun(Obj) -> db:dirty_delete_object(?DB_MONSTER_PERSISTENT_INFO, Obj) end, L)
    end,
    MonsterInfo = #p_monster{reborn_pos = Pos,
                             monsterid = MonsterID,
                             typeid = MonsterType,
                             mapid = MapID},
    init([MonsterInfo, ?MONSTER_CREATE_TYPE_MANUAL_CALL, MapID, MapName, CallBackFun, ?FIRST_BORN_STATE, FamilyID]),
    ok.


init([MonsterInfo, CreateType, MapID, MapName, PostDeadFunc, MonsterState, SpecialData]) ->
    init([MonsterInfo, CreateType, MapID, MapName, PostDeadFunc, MonsterState, SpecialData, 0]);
%% LiveTime 表示生存时间,0表示不自动消失
init([MonsterInfo, CreateType, MapID, MapName, PostDeadFunc, MonsterState, SpecialData, LiveTime]) ->
    #p_monster{typeid = Type, monsterid = MonsterId} = MonsterInfo,
    case judge_monster_in_map(MonsterId) of
        true ->
            nil;
        false ->
            case common_config_dyn:find(boss_ai,Type) of
                [] ->
                    AIInfo = undefined;
                [AIInfo] ->
                    next
            end,
            case common_config_dyn:find(monster_change,Type) of
                [MonsterChangeInfoT] when erlang:is_record(MonsterChangeInfoT,r_monster_change_info) ->
                    MonsterChangeInfo = MonsterChangeInfoT;
                _ ->
                    MonsterChangeInfo = undefined
            end,
            ReBornPos = MonsterInfo#p_monster.reborn_pos,
            NewRebornPos = ReBornPos#p_pos{dir=common_tool:random(0, 7)},
            MonsterInfo2 = MonsterInfo#p_monster{typeid=Type, state=MonsterState,reborn_pos=NewRebornPos},
            NewState = #monster_state{
              monster_info = MonsterInfo2,
              post_dead_fun=PostDeadFunc,
              ai_info = AIInfo,
              mapname = MapName,
              map_id = MapID,
              create_type = CreateType,
              created_time = common_tool:now(),%% erlang:now() 修改为common_tool:now() by caochuncheng 2011-08-14
              next_work_tick = 0,
              special_data = SpecialData,
              first_attack_time = 0,
              monster_change_info = MonsterChangeInfo
             },
            List = get_monster_id_list(),
            erlang:put(?monster_id_list,[MonsterId|List]),
            if
                LiveTime>0 ->
                    erlang:send_after(LiveTime * 1000, self(), {mod_map_monster,{timeout,MonsterId}});
                true->
                    ignore
            end,
            set_next_work(MonsterId,1000,loop,NewState)
    end.

work(MonsterID,NowTime) ->
    State = get_monster_state(MonsterID),

    case judge_time_to_work(NowTime,State) of
        true ->
            case State#monster_state.next_work_truple of
                loop ->
                    loop(State);
                _ ->
                    nil
            end;
        false ->
            %%如果本次怪物不进行任何操作，则下个怪物直接继续使用NowTime,减少now函数的调用
            ignore
    end.


reduce_hp(MonsterID, FinalValue, SrcID, SrcType) ->
	reduce_hp(MonsterID, FinalValue, SrcID, SrcType, _IsRoleFight=false, _SkillID=0).
reduce_hp(MonsterID, FinalValue, SrcID, SrcType, IsRoleFight, SkillID) ->
    State = get_monster_state(MonsterID),
    attack_monster(State,{SrcID,SrcType,FinalValue},IsRoleFight,SkillID).


delete_role_from_monster_enemy_list(MonsterID,ActorID,ActorType) ->
    State = get_monster_state(MonsterID),
    #monster_state{monster_info = MonsterInfo} = State,
    Key = {ActorID,ActorType},
    case get({enemy_level,MonsterID,Key}) of
        undefined ->
            NewMonsterInfo =  MonsterInfo;
        ?FIRST_ENEMY_LEVEL ->
            First_Enemies = MonsterInfo#p_monster.first_enemies,
            NewEnemies = lists:keydelete(Key, 2, First_Enemies),
            NewMonsterInfo =  MonsterInfo#p_monster{first_enemies = NewEnemies};
        ?SECOND_ENEMY_LEVEL ->
            Second_Enemies = MonsterInfo#p_monster.second_enemies,
            NewEnemies = lists:keydelete(Key, 2, Second_Enemies),
            NewMonsterInfo =  MonsterInfo#p_monster{second_enemies = NewEnemies};
        ?THIRD_ENEMY_LEVEL ->
            Third_Enemies = MonsterInfo#p_monster.third_enemies,
            NewEnemies = lists:keydelete(Key, 2, Third_Enemies),
            NewMonsterInfo =  MonsterInfo#p_monster{third_enemies = NewEnemies}
    end,
    erase_monster_enemy(MonsterID,Key),
    set_monster_state(MonsterID,State#monster_state{monster_info = NewMonsterInfo}).

monster_attr_change(MonsterID, ?BLOOD, NewValue) ->
	case mod_map_actor:get_actor_mapinfo(MonsterID, monster) of
		undefined ->
			nil;
		MonsterMapInfo ->
			NewMonsterMapInfo = MonsterMapInfo#p_map_monster{hp = NewValue},
			mod_map_actor:set_actor_mapinfo(MonsterID, monster, NewMonsterMapInfo)
	end;    
monster_attr_change(_MonsterID, _, _NewValue) ->
	ignore.

update_monster_mapinfo(MonsterInfo) ->
    #p_monster{
                buffs = Buffs,
                hp = Hp,
                max_hp = MaxHp,
                mp = Mp,
                max_mp = MaxMp,
                state = MonsterState,
                monsterid = MonsterID
              } = MonsterInfo,
    case mod_map_actor:get_actor_mapinfo(MonsterID,monster) of
        undefined ->
            nil;
        MonsterMapInfo ->
            NewMapInfo = MonsterMapInfo#p_map_monster{
                           state_buffs = Buffs,
                           hp = Hp,
                           max_hp = MaxHp,
                           mp = Mp,
                           max_mp = MaxMp,
                           state = MonsterState},

            #p_map_monster{monsterid=MonsterID, state_buffs=OldBuffs} = MonsterMapInfo,
            case OldBuffs =/= Buffs of
                true ->
                    DataRecord = #m_map_update_actor_mapinfo_toc{
                                                                 actor_id = MonsterID,
                                                                 actor_type = ?TYPE_MONSTER,
                                                                 monster_info = NewMapInfo},
                    mgeem_map:do_broadcast_insence_include([{monster, MonsterID}], ?MAP, ?MAP_UPDATE_ACTOR_MAPINFO, DataRecord, mgeem_map:get_state());
                _ ->
                    ignore
            end,

            mod_map_actor:set_actor_mapinfo(MonsterID,monster, NewMapInfo)
    end.

monster_transfer(_MonsterPos,DestPos,MonsterID,MonsterState) ->
    #p_pos{tx=NewTX, ty=NewTY, dir=_NewDIR} = DestPos,
    mod_map_actor:same_map_change_pos(MonsterID, monster, NewTX, NewTY, 1, mgeem_map:get_state()),
    set_next_work(MonsterID,0,loop,MonsterState).


%%广播消息给怪物周围玩家
handle({monster_broadcast, MonsterID, Module, Method, DataRecord}, State) ->
    mgeem_map:do_broadcast_insence_include([{monster,MonsterID}], Module, Method, DataRecord, State);
%%handle({create_monster, PID, {Tx, Ty}, ReplyInfo, MonsterList}, State) ->
%%    MapID = State#map_state.mapid,
%%    create_monster({PID, {Tx, Ty}, MonsterList, ReplyInfo, MapID});
handle({timeout,MonsterID}, _) ->
     monster_delete(MonsterID);
handle({delete_all_monster}, _) ->
     delete_all_monster();    
handle({reduce_hp,MonsterID, FinalValue, SrcID, SrcType},_) ->
    reduce_hp(MonsterID, FinalValue, SrcID, SrcType);

handle({dynamic_create_boss_group,MonsterList,Key},MapState)->
    #map_state{mapid=MapId, map_name=MapProcessName} = MapState,
    MonsterIDList = 
    lists:foldl(
      fun({MonsterTypeId, TX, TY},MonsterIDList) ->
              MonsterInfo = 
                  #p_monster{reborn_pos=#p_pos{tx=TX, ty=TY, dir=1},
                             monsterid=get_max_monster_id_form_process_dict(),
                             typeid=MonsterTypeId,
                             mapid=MapId},
               init([MonsterInfo,?MONSTER_CREATE_TYPE_MANUAL_CALL, MapId, MapProcessName, undefined, ?FIRST_BORN_STATE, null]),
              [MonsterInfo#p_monster.monsterid|MonsterIDList]
      end,[], MonsterList),
    NewMonsterIDList = MonsterIDList++ get_boss_group_id_list(Key),
    case NewMonsterIDList=/=[] of
        true->
            set_boss_group_id_list(Key,NewMonsterIDList);
        false->
            ignore
    end;

handle({dynamic_create_monster2, MonsterList}, MapState) ->
    #map_state{mapid=MapId, map_name=MapProcessName} = MapState,
    lists:foreach(
      fun({MonsterTypeId, TX, TY}) ->
              MonsterInfo = 
                  #p_monster{reborn_pos=#p_pos{tx=TX, ty=TY, dir=1},
                             monsterid=get_max_monster_id_form_process_dict(),
                             typeid=MonsterTypeId,
                             mapid=MapId},
               init([MonsterInfo,?MONSTER_CREATE_TYPE_MANUAL_CALL, MapId, MapProcessName, undefined, ?FIRST_BORN_STATE, null])
      end, MonsterList);

handle({dynamic_create_monster, CreateData}, _State) ->
	try 
        {MonsterTypeID, MonsterID, MonsterCreateType, SpecialData, BornTX, BornTY, MonsterState, DeadFun} = CreateData,
		MapID = mgeem_map:get_mapid(),
		Pos = #p_pos{tx = BornTX, ty = BornTY, dir = 1},
		MonsterInfo = #p_monster{reborn_pos = Pos,
						  monsterid =  MonsterID,
						  typeid = MonsterTypeID,
						  mapid = MapID},
		MapProcessName = common_misc:get_map_name(MapID),
		init([MonsterInfo, MonsterCreateType, MapID, MapProcessName, DeadFun, MonsterState, SpecialData])
	catch
		_:Error ->
			?ERROR_MSG("~ts:~w ~w ~w", ["动态创建怪物出错", Error, CreateData, erlang:get_stacktrace()])
	end;

handle({dynamic_summon_monster, MonsterType, Num, Tx, Ty, LiveTime}, State) ->
    try 
        lists:foreach(
          fun(_) ->
                  Pos = #p_pos{tx=Tx, ty=Ty, dir = 1},
                  MonsterID =   get_max_monster_id_form_process_dict(),
                  MonsterInfo = #p_monster{reborn_pos = Pos,
                                           monsterid = MonsterID,
                                           typeid = MonsterType,
                                           mapid = State#map_state.mapid},
                  init([MonsterInfo, ?MONSTER_CREATE_TYPE_MANUAL_CALL, State#map_state.mapid, State#map_state.map_name, undefined, ?FIRST_BORN_STATE, undefined]),
                  case is_integer(LiveTime) andalso LiveTime > 0 of
                      true ->
                          erlang:send_after(LiveTime * 1000, self(), {mod_map_monster,{timeout,MonsterID}});
                      false ->
                          ignore
                  end
          end, lists:seq(1, Num))
    catch
        _:Error ->
            ?ERROR_MSG("~ts:~w ~w ~w", ["召唤怪物出错", MonsterType, Error, erlang:get_stacktrace()])
    end;

handle({dynamic_delete_boss_group,Key},_State)->
    case get_boss_group_id_list(Key) of
        MonsterIDList when is_list(MonsterIDList),length(MonsterIDList)>0 ->
            lists:foreach(fun(MonsterID)-> 
                                  ?TRY_CATCH(monster_delete(MonsterID),Err)
                          end,MonsterIDList),
            set_boss_group_id_list(Key,[]);
        _->ignore
    end;

handle({dynamic_delete_monster, MonsterID}, _State) ->
	try 
		monster_delete(MonsterID)
	catch
		_:Error ->
			?ERROR_MSG("~ts:~w ~w ~w", ["动态删除怪物出错", Error, MonsterID, erlang:get_stacktrace()])
	end;

handle({create_monster_if_not_exists, Monsters}, MapState) ->
	#map_state{mapid=MapID, map_name=MapProcessName} = MapState,
    lists:foreach(fun
      ({MonsterID, MonsterTypeID, TX, TY}) ->
        case judge_monster_in_map(MonsterID) of
            false ->
              MonsterInfo = #p_monster{
                reborn_pos = #p_pos{tx=TX, ty=TY, dir=1},
                monsterid  = MonsterID,
                typeid     = MonsterTypeID,
                mapid      = MapID
              },
              init([MonsterInfo, ?MONSTER_CREATE_TYPE_MANUAL_CALL, MapID, MapProcessName, undefined, ?FIRST_BORN_STATE, null]);
            _ ->
              ignore
        end
      end, Monsters);
handle({create_monster_as_mission_accept, MissionIDs}, MapState) ->
  lists:foreach(fun
      (MissionID) ->
          Key      = create_monster_if_not_exists,
          Creation = lists:keyfind(Key, 1, cfg_mission:after_mission_accept(MissionID)),
          handle(Creation, MapState)
  end, MissionIDs);

handle(Msg,_State) ->
    ?ERROR_MSG("uexcept msg = ~w",[Msg]).

%%
%%============================== Local Functions =============================================
%%

loop_ms(NowMsec) ->
    [ work(MonsterID, NowMsec) ||MonsterID<- get_monster_id_list()],
    ok.


judge_time_to_work(NowTime,State) ->
    NextTick = State#monster_state.next_work_tick,
    NowTime >= NextTick.

loop(State) ->     
	MonsterInfo = State#monster_state.monster_info,          
	CreateType = State#monster_state.create_type,
	#p_monster{monsterid=MonsterID, state=MonsterState, move_speed=MoveSpeed, attack_speed=AttackSpeed, hp=Hp} = MonsterInfo,
	%% add by caochuncheng 2011-08-14 添加出生一定时间内变形的怪物处理
	
	case State#monster_state.monster_change_info =/= undefined 
								 andalso erlang:is_record(State#monster_state.monster_change_info,r_monster_change_info)
								 andalso mgeem_map:get_now2() > (State#monster_state.created_time + 
																						 (State#monster_state.monster_change_info)#r_monster_change_info.dont_interval_seconds) * 1000 of
		true -> %% 需要特殊处理
			case MonsterState of
				?DEAD_STATE when CreateType =:= ?MONSTER_CREATE_TYPE_NORMAL->
					reborn(State);
				?RETURN_STATE ->
					return(State);
				_ ->
					do_monster_change_loop(State)
			end;
		_ ->
			case (AttackSpeed =:= 0 orelse (MonsterState =/= ?FIGHT_STATE andalso MoveSpeed =:= 0))
					 andalso MonsterState =/= ?FIRST_BORN_STATE andalso MonsterState =/= ?DEAD_STATE of
				true ->
					set_next_work(MonsterID, 1000, loop, State);
				_ ->
					case MonsterState of
						?GUARD_STATE when Hp > 0 ->
							guard(State);
						?FIGHT_STATE ->
							fight(State);
						?DEAD_STATE when CreateType =:= ?MONSTER_CREATE_TYPE_NORMAL->
							reborn(State);
						?RETURN_STATE ->
							return(State);
						?FIRST_BORN_STATE ->
							reborn(State);
						?PATROL_STATE ->
							patrol(State);
						_ ->
							monster_delete(MonsterID)
					end
			end
	end.
%% add by caochuncheng 2011-08-14 处理怪物出生一定时间内变形功能
do_monster_change_loop(State) ->
    OldMonsterInfo = State#monster_state.monster_info,
	MonsterChangeInfo = State#monster_state.monster_change_info,
    if MonsterChangeInfo#r_monster_change_info.next_monster_type_id > 0 -> %% 出生新的怪物
            monster_delete(OldMonsterInfo#p_monster.monsterid),%% 删除旧的怪物
            #map_state{mapid = MapId,map_name = MapProcessName} = mgeem_map:get_state(),
            NewMonsterInfo = #p_monster{
              reborn_pos = OldMonsterInfo#p_monster.reborn_pos,
              monsterid = get_max_monster_id_form_process_dict(),
              typeid = MonsterChangeInfo#r_monster_change_info.next_monster_type_id,
              mapid = MapId},
            %% 判断副本中怪物能否重生
            case common_config_dyn:find(fb_map,MapId) of
                [#r_fb_map{can_monster_reborn=false}]->
                    MonsterCreateType = ?MONSTER_CREATE_TYPE_MANUAL_CALL;
                _ ->
                    MonsterCreateType = ?MONSTER_CREATE_TYPE_NORMAL
            end,
            init([NewMonsterInfo, MonsterCreateType, MapId, MapProcessName, undefined, ?FIRST_BORN_STATE, null]),
            hook_map_monster:monster_change();
       MonsterChangeInfo#r_monster_change_info.next_monster_type_id =:= 0 -> %% 怪物消失
           monster_delete(OldMonsterInfo#p_monster.monsterid);
        true ->
            set_next_work(OldMonsterInfo#p_monster.monsterid,1000,loop,State)
    end.

guard(State) ->
    #monster_state{monster_info=MonsterInfo,monster_change_info = MonsterChangeInfo} = State,
    MonsterID = MonsterInfo#p_monster.monsterid,
    case State#monster_state.monster_change_info =/= undefined 
        andalso erlang:is_record(MonsterChangeInfo,r_monster_change_info)
        andalso mgeem_map:get_now2() =< (State#monster_state.created_time + MonsterChangeInfo#r_monster_change_info.dont_interval_seconds) * 1000 of
        true ->
            set_next_work(MonsterID,(State#monster_state.created_time + MonsterChangeInfo#r_monster_change_info.dont_interval_seconds) * 1000 
                          - mgeem_map:get_now2(),loop,State);
        _ ->
            #p_monster{typeid=TypeID} = MonsterInfo,
            [BaseInfo] = cfg_monster:find(TypeID),
            AILevel = BaseInfo#p_monster_base_info.ai_type,
            case AILevel of
                ?FIRST_AI_LEVEL ->
                    %%非主动攻击类型的怪物,一定概率去巡逻
                    case random:uniform(100) > ?PATROL_RATE of
                        true ->
                            begin_to_patrol(MonsterID,State);
                        false ->
                            set_next_work(MonsterID,5000,loop,State)
                    end;
                ?SECOND_AI_LEVEL ->
					InWarOfMonster = mod_warofmonster:is_in_fb_map(),
					InGuardFb = mod_guard_fb:is_in_fb_map(),
                    if
						InWarOfMonster =:= true ->
                            %%怪物攻城战中做特殊处理
                            guard_warofmonster(MonsterID,BaseInfo,TypeID,State);
						InGuardFb =:= true ->
                            %%魔尊洞窟中做特殊处理
                            guard_guard_fb(MonsterID,BaseInfo,TypeID,State);
                        true ->
                            guard_role(MonsterID,BaseInfo,TypeID,State)
                    end;
                _ ->
                    set_next_work(MonsterID,?INFINITY_TICK,loop,State)
            end
    end.

%%怪物攻城战中的警戒
%%      先攻击ServerNPC，再攻击玩家
guard_warofmonster(MonsterID,BaseInfo,TypeID,State)->
    GuardRadius = BaseInfo#p_monster_base_info.guard_radius,
    case get_monster_9_slice_server_npcs(MonsterID) of
        [] ->
            guard_role(MonsterID,BaseInfo,TypeID,State);
        SenceActorList ->
            case find_in_guardradius_server_npc_list(SenceActorList,MonsterID,GuardRadius) of
                {[],_} ->
                    guard_role(MonsterID,BaseInfo,TypeID,State);
                {ActorIdList,_} ->
                    try
                        begin_to_fight(MonsterID,State,ActorIdList,server_npc,BaseInfo#p_monster_base_info.rarity)
                    catch
                        T:Error->
                            #monster_state{ai_info = AIInfo } = State,
                            ?ERROR_MSG("{T,Error}=~w,BaseInfo=~w,AIInfo=~w",[{T,Error},BaseInfo,AIInfo])
                    end
            end
    end.

%% 魔尊洞窟中的警戒(全地图)
%% 先攻击圣女护卫，再攻击玩家，最后攻击圣女
guard_guard_fb(MonsterID,BaseInfo,TypeID,State)->
	GuardRadius = BaseInfo#p_monster_base_info.guard_radius,
	case mod_server_npc:get_server_npc_id_list() of
		[] ->
			guard_all_role(MonsterID,BaseInfo,TypeID,State);
		SenceActorList ->
			guard_guard_fb2(GuardRadius,SenceActorList,MonsterID,BaseInfo,TypeID,State,[guard,goddess])
	end.
guard_guard_fb2(_GuardRadius,_SenceActorList,_MonsterID,_BaseInfo,_TypeID,_State,[]) ->
	ignore;
guard_guard_fb2(GuardRadius,SenceActorList,MonsterID,BaseInfo,TypeID,State,[H|T]) ->
	case find_in_guardradius_server_npc_list(SenceActorList,MonsterID,GuardRadius,H) of
		{[],_} ->
			case guard_all_role(MonsterID,BaseInfo,TypeID,State) of
				[] ->
					guard_guard_fb2(GuardRadius,SenceActorList,MonsterID,BaseInfo,TypeID,State,T);
				_ ->
					ingore
			end;
		{ActorIdList,_} ->
			try
				begin_to_fight(MonsterID,State,ActorIdList,server_npc,BaseInfo#p_monster_base_info.rarity)
			catch
				T:Error->
					#monster_state{ai_info = AIInfo } = State,
					?ERROR_MSG("{T,Error}=~w,BaseInfo=~w,AIInfo=~w",[{T,Error},BaseInfo,AIInfo])
			end
	end.

guard_all_role(MonsterID,BaseInfo,TypeID,State)->
    case mod_map_actor:get_in_map_role() of
        [] ->
            set_next_work(MonsterID,3000,loop,State),
			[];
        SliceRoleList ->
            guard_normal(SliceRoleList,MonsterID,BaseInfo,TypeID,State)
    end.

guard_role(MonsterID,BaseInfo,TypeID,State)->
    case get_monster_9_slice_roles(MonsterID) of
        [] ->
            set_next_work(MonsterID,3000,loop,State),
			[];
        SliceRoleList ->
		    guard_normal(SliceRoleList,MonsterID,BaseInfo,TypeID,State)
    end.

guard_normal(SliceRoleList,MonsterID,BaseInfo,TypeID,State) ->
	GuardRadius = BaseInfo#p_monster_base_info.guard_radius,
	case find_in_guardradius_role_list(SliceRoleList,MonsterID,GuardRadius,TypeID) of
		{[],_} ->
			set_next_work(MonsterID,1000,loop,State),
			[];
		{ActorIdList,_} ->
			try
				begin_to_fight(MonsterID,State,ActorIdList,role,BaseInfo#p_monster_base_info.rarity)
			catch
				T:Error->
					#monster_state{ai_info = AIInfo } = State,
					?ERROR_MSG("{T,Error}=~w,BaseInfo=~w,AIInfo=~w",[{T,Error},BaseInfo,AIInfo])
			end
	end.

get_monster_9_slice_roles(MonsterID) ->
    Slices =  mgeem_map:get_9_slice_by_actorid_list([{monster,MonsterID}],mgeem_map:get_state()),
    mgeem_map:get_all_in_sence_user_by_slice_list(Slices).

get_monster_9_slice_server_npcs(MonsterID) ->
    Slices =  mgeem_map:get_9_slice_by_actorid_list([{monster,MonsterID}],mgeem_map:get_state()),
    mgeem_map:get_all_in_sence_server_npc_by_slice_list(Slices).

-define(MONSTER_ENEMY_KIND_OF_COLLECTING_ROLE,collecting_role).
%%找出是否有在警戒范围内的玩家
find_in_guardradius_role_list(SenceActorList,MonsterID,GuardRadius,MonsterType) ->
    MonsterPos = mod_map_actor:get_actor_pos(MonsterID,monster),
    case common_config_dyn:find(monster_etc,{monster_enemy_kind,MonsterType}) of
        [] ->
          find_normal_enemy(SenceActorList,MonsterPos,GuardRadius);
        [?MONSTER_ENEMY_KIND_OF_COLLECTING_ROLE] ->
          find_collecting_enemy(SenceActorList,MonsterPos,GuardRadius);
        _ ->
            []
    end.

find_in_guardradius_server_npc_list(SenceActorList,MonsterID,GuardRadius) ->
	find_in_guardradius_server_npc_list(SenceActorList,MonsterID,GuardRadius,undefined).
find_in_guardradius_server_npc_list(SenceActorList,MonsterID,GuardRadius,Target) ->
    MonsterPos = mod_map_actor:get_actor_pos(MonsterID,monster),
    lists:foldl(
      fun(ActorID, {Acc,Acc2}) ->
              case mod_map_actor:get_actor_mapinfo(ActorID,server_npc) of
                  undefined ->
                      {Acc,Acc2};
                  ServerNpcMapInfo ->  
                      NpcKindId = ServerNpcMapInfo#p_map_server_npc.npc_kind_id,
					  NpcType = ServerNpcMapInfo#p_map_server_npc.npc_type,
                      case is_server_npc_kind_can_attack(NpcKindId,NpcType,Target) 
                               andalso judge_in_distance(MonsterPos,ServerNpcMapInfo#p_map_server_npc.pos,GuardRadius) of
                          false ->
                              {Acc,[ActorID|Acc2]};
                          true ->
                              {[ActorID|Acc],Acc2}
                      end
              end
      end, {[],[]}, SenceActorList).

is_server_npc_kind_can_attack(NpcKindId,NpcType,Target)->
	InWarOfMonster = mod_warofmonster:is_in_fb_map(),
	InGuardFb = mod_guard_fb:is_in_fb_map(),
	if
		InWarOfMonster =:= true ->
			NpcKindId =:= ?SERVER_NPC_KIND_FB_SUPER_GUARD orelse NpcKindId =:= ?SERVER_NPC_KIND_FB_TOWER;
		InGuardFb =:= true ->
			if
				Target =:= guard ->
					NpcType =:= ?SERVER_NPC_TYPE_MONSTER_SLAYER andalso NpcKindId =/= ?SERVER_NPC_KIND_FB_TRAP;
				Target =:= goddess ->
					NpcType =:= ?SERVER_NPC_TYPE_UNMOVE andalso NpcKindId =/= ?SERVER_NPC_KIND_FB_TRAP;
				true ->
					false
			end;
		true ->
			false
	end.

%%普通的方式，把地图中找到的玩家列为攻击对象
find_normal_enemy(SenceActorList,MonsterPos,GuardRadius) ->
    lists:foldr(
      fun(ActorID, {Acc,Acc2}) ->
              case mod_map_actor:get_actor_mapinfo(ActorID,role) of
                  undefined ->
                      {Acc,Acc2};
                  RoleMapInfo ->  
                      case RoleMapInfo#p_map_role.state =/= ?ROLE_STATE_DEAD 
                          andalso RoleMapInfo#p_map_role.state =/= ?ROLE_STATE_STALL
                          andalso judge_in_distance(MonsterPos,RoleMapInfo#p_map_role.pos,GuardRadius) of
                          false ->
                              {Acc,[ActorID|Acc2]};
                          true ->
                              {[ActorID|Acc],Acc2}
                      end

              end
      end, {[],[]}, SenceActorList).


%%找出旁边的在进行采集的玩家
find_collecting_enemy(SenceActorList,MonsterPos,GuardRadius) ->
      lists:foldr(
      fun(ActorID, {Acc,Acc2}) ->
              case mod_map_actor:get_actor_mapinfo(ActorID,role) of
                  undefined ->
                      {Acc,Acc2};
                  RoleMapInfo ->  
                      case RoleMapInfo#p_map_role.state == ?ROLE_STATE_COLLECT
                          andalso judge_in_distance(MonsterPos,RoleMapInfo#p_map_role.pos,GuardRadius) of
                          false ->
                              {Acc,[ActorID|Acc2]};
                          true ->
                              {[ActorID|Acc],Acc2}
                      end

              end
      end, {[],[]}, SenceActorList).


begin_to_patrol(MonsterID,State) ->
    MonsterInfo = State#monster_state.monster_info,
    BornPos = MonsterInfo#p_monster.reborn_pos,
    TX = BornPos#p_pos.tx,
    TY = BornPos#p_pos.ty,
    X = random:uniform(4) - 2,
    Y = random:uniform(4) - 2,
    PatrolPos = BornPos#p_pos{tx = TX + X, ty = TY + Y},
    NewMonsterInfo = MonsterInfo#p_monster{state = ?PATROL_STATE},
    set_next_work(MonsterID,?MIN_MONSTER_WORK_TICK,loop,State#monster_state{monster_info=NewMonsterInfo,patrol_pos=PatrolPos}).


patrol(State) ->
    #monster_state{patrol_pos = PatrolPos, monster_info = MonsterInfo} = State,
    MoveSpeed = MonsterInfo#p_monster.move_speed,
    MonsterID = MonsterInfo#p_monster.monsterid,
    MonsterPos = mod_map_actor:get_actor_pos(MonsterID,monster),
    case MonsterPos#p_pos.tx =:= PatrolPos#p_pos.tx
        andalso  MonsterPos#p_pos.ty =:= PatrolPos#p_pos.ty of
        true ->
            NewMonsterInfo = MonsterInfo#p_monster{state = ?GUARD_STATE},
            set_next_work(MonsterID,3000,loop,State#monster_state{monster_info=NewMonsterInfo,patrol_pos=undefined,walk_path=[]});
        false ->
            do_start_walk(MonsterPos,PatrolPos,MonsterID,MoveSpeed,State)
    end.


fight(State)->
    #monster_state{monster_info = MonsterInfo, 
                   create_type = _CreateType} = State,
    #p_monster{typeid=TypeID} = MonsterInfo,
    [BaseInfo] = cfg_monster:find(TypeID),
    Rarity = BaseInfo#p_monster_base_info.rarity,
    ActivityRadius = BaseInfo#p_monster_base_info.activity_radius,
   
    #p_monster{reborn_pos = BornPos,  monsterid = MonsterID} = MonsterInfo,
    MonsterPos = mod_map_actor:get_actor_pos(MonsterID,monster),

    case judge_in_distance(MonsterPos, BornPos, ActivityRadius) of
        true ->
            fight2(MonsterPos,MonsterInfo,Rarity,State);
        false ->
            return_born_pos(BornPos,MonsterPos,MonsterInfo,State)
    end.


fight2(MonsterPos,MonsterInfo,Rarity,State) ->
    if
        ?CHECK_RARITY_BOSS_AI( Rarity ) ->
            NewState = State#monster_state{touched_ai_condition_list = []},
            case judge_touch_off_boss_ai(MonsterInfo,State) of
                {[],[],[]} ->
                    fight3(MonsterPos,MonsterInfo,normal,NewState);
                {SkillList,TalkList,NpcTalkList}->
                    execute_boss_ai(SkillList,MonsterInfo,MonsterPos,NewState),     
                    execute_monster_talk(MonsterInfo#p_monster.monsterid,TalkList),
                    execute_npc_talk(MonsterInfo#p_monster.monsterid,NpcTalkList)
            end;
        true->
            fight3(MonsterPos,MonsterInfo,normal,State)
    end.

fight3(MonsterPos,MonsterInfo,Parm,State) ->
    #p_monster{typeid=TypeID} = MonsterInfo,
    [BaseInfo] = cfg_monster:find(TypeID),
    GuardRadius =  BaseInfo#p_monster_base_info.guard_radius,
    AttentionRadius = BaseInfo#p_monster_base_info.attention_radius,
    AttackType = BaseInfo#p_monster_base_info.attacktype,
    BornPos = MonsterInfo#p_monster.reborn_pos, 
    
    NewMonsterInfo1 = update_enemies_lists(MonsterInfo,AttentionRadius),
    #p_monster{
                monsterid = MonsterID,
                first_enemies = Fir_Enemies,
                second_enemies = Sec_Enemies,
                third_enemies = Thr_Enemies,
                move_speed = MoveSpeed,
                attack_speed = AttackSpeed
              } = NewMonsterInfo1,
    case get_enemy_role(MonsterID,[Fir_Enemies,Sec_Enemies,Thr_Enemies], []) of
        {no, Enemy} ->
            [Thr_Enemies2, Sec_Enemies2, Fir_Enemies2] = Enemy,
            MonsterInfoTmp = NewMonsterInfo1#p_monster{first_enemies=Fir_Enemies2,
                                                       second_enemies=Sec_Enemies2,
                                                       third_enemies=Thr_Enemies2},
            case judge_in_distance(BornPos,MonsterPos,GuardRadius) of
                false ->
                    return_born_pos(BornPos,MonsterPos,MonsterInfoTmp,State);
                true ->
                    NewMonsterInfo2 = MonsterInfoTmp#p_monster{state = ?GUARD_STATE},
                    set_next_work(MonsterID,0,loop,State#monster_state{monster_info = NewMonsterInfo2})
            end;
        {Role, _} ->
            {DestActorID,DestActorType} =  Role#p_enemy.actor_key,
            DestActorPos =  mod_map_actor:get_actor_pos(DestActorID,DestActorType),
            Now = common_tool:now(),
            case Parm of
                transfer ->
                    mod_map_monster:monster_transfer(MonsterPos,DestActorPos,MonsterID,
                                                     State#monster_state{monster_info = NewMonsterInfo1,last_attack_time = Now});
                normal ->
                    case AttackType of
                        ?MONSTER_ATTACK_TYPE_PHY ->
                            SkillID = 1,
                            AttAckDis = 1;
                        ?MONSTER_ATTACK_TYPE_PHY_FAR ->
                            SkillID = 2,
                            AttAckDis = 10;
                        ?MONSTER_ATTACK_TYPE_MAGIC ->
                            SkillID = 3,
                            AttAckDis = 1;
                        ?MONSTER_ATTACK_TYPE_MAGIC_FAR ->
                            SkillID = 4,
                            AttAckDis = 10
                    end,
                    SkillLevel = 1,
                    case judge_in_distance(MonsterPos, DestActorPos, AttAckDis) of
                        true ->
                            attack_enemy(State#monster_state{monster_info = NewMonsterInfo1,last_attack_time = Now}, 
                                        MonsterID, DestActorID,DestActorType, AttackSpeed,{SkillID,SkillLevel});
                        false ->
                            case MoveSpeed =:= 0 of
                                true ->
                                    set_next_work(MonsterID, 1000, loop, State#monster_state{monster_info = NewMonsterInfo1});
                                _ ->
                                    do_start_walk(MonsterPos,DestActorPos,MonsterID,MoveSpeed,State#monster_state{monster_info = NewMonsterInfo1})
                            end
                    end;
                {SkillID,SkillLevel,ResetAttackTime} ->
                    case ResetAttackTime of
                        true -> 
                            attack_enemy(State#monster_state{monster_info = NewMonsterInfo1,last_attack_time = Now}, 
                                        MonsterID, DestActorID,DestActorType, AttackSpeed,{SkillID,SkillLevel});
                        false ->
                            NewLastAttackTime = State#monster_state.last_attack_time - 1,
                            attack_enemy(State#monster_state{monster_info = NewMonsterInfo1,last_attack_time = NewLastAttackTime}, 
                                        MonsterID, DestActorID,DestActorType, AttackSpeed,{SkillID,SkillLevel})
                    end
            end
    end.

%%@doc 检查BOSS匹配的AI
judge_touch_off_boss_ai(MonsterInfo,State) ->
    AIInfo = State#monster_state.ai_info,
    case AIInfo of
        undefined ->
            {[],[],[]};
        _ ->
            ConditionList = AIInfo#p_boss_ai_plan.conditions,
            judge_touch_off_boss_ai_2(ConditionList,MonsterInfo,State)
    end.

judge_touch_off_boss_ai_2([],_MonsterInfo,_State)->
    {[],[],[]};
judge_touch_off_boss_ai_2([Condition|T],MonsterInfo,State)->
    #p_boss_ai_condition{condition_id=ConditionID} = Condition,
    Rand = common_tool:random(1,10000),
    case judge_touch_off_boss_ai_3(ConditionID,Condition,State,MonsterInfo,Rand) of
        {ok,ShouldContinue} ->
            case judge_touch_off_boss_ai_4(Condition,Rand) of
                {SkillList,TalkList,NpcTalkList}->
                    {SkillList,TalkList,NpcTalkList};
                false->
                    case ShouldContinue of
                        continue-> judge_touch_off_boss_ai_2(T,MonsterInfo,State);
                        _ -> {[],[],[]}
                    end
            end;
        _->
            judge_touch_off_boss_ai_2(T,MonsterInfo,State)
    end.


judge_touch_off_boss_ai_3(?AI_CONDICTION_NORMAL_ATTACK,_Condition,_State,_MonsterInfo,_Rand)->     %%普通攻击
    {ok,continue};
judge_touch_off_boss_ai_3(?AI_CONDICTION_NORMAL_HEATED=ConditionID,_Condition,State,_MonsterInfo,_Rand) ->  %%普通被攻击 
    TouchedAiConditionList = State#monster_state.touched_ai_condition_list,
    case lists:keyfind(ConditionID,2,TouchedAiConditionList) of
        false ->
            false;
        _ ->
            {ok,continue}
    end;
judge_touch_off_boss_ai_3(?AI_CONDICTION_BLOOD_RATE=ConditionID,Condition,State,_MonsterInfo,_)-> %%血量上限少于XX时出发条件
    {Percent} = Condition#p_boss_ai_condition.parm,
    TouchedAiConditionList = State#monster_state.touched_ai_condition_list,
    case lists:keyfind({ConditionID,Percent},2,TouchedAiConditionList) of
        false->
            false;
        _ ->
            {ok,not_continue}
    end;
judge_touch_off_boss_ai_3(?AI_CONDICTION_NO_ATTACK_IN_TIMES,Condition,State,_MonsterInfo,_Rand)-> %%X秒内无法进行正常攻击
    case State#monster_state.last_attack_time of
        undefined ->
            false;
        LastAttackTime ->
            Now = common_tool:now(),
            {TimeInterval} =  Condition#p_boss_ai_condition.parm,
            case Now - LastAttackTime >= TimeInterval  andalso Now - LastAttackTime - TimeInterval =< 1 of
                true-> {ok,not_continue};
                _-> false
            end
    end;
judge_touch_off_boss_ai_3(?AI_CONDICTION_SEARCH_WALK_ERROR,_Condition,State,_MonsterInfo,_Rand)->    %%寻路异常
    LastEnemyPos = State#monster_state.last_enemy_pos,
    WalkPath =  State#monster_state.walk_path,
    case WalkPath =:= [] andalso LastEnemyPos =/= undefined of
        true-> {ok,not_continue};
        _-> false
    end;
judge_touch_off_boss_ai_3(?AI_CONDICTION_TICK_INTERVAL,Condition,_State,MonsterInfo,Rand)->    %%战斗中每间隔X秒触发
    Now = common_tool:now(),
    case get({boss_ai_tick_interval,MonsterInfo#p_monster.monsterid}) of
        undefined ->
            put({boss_ai_tick_interval,MonsterInfo#p_monster.monsterid},Now),
            false;
        Tick ->
            {Interval} = Condition#p_boss_ai_condition.parm,
            case Now - Tick >= Interval of
                true ->
                    #p_boss_ai_condition{rate=Rate} = Condition,
                    case Rand =< Rate of
                        true->
                            %%只有真正命中这个AI的时候，才对时间清零
                            put({boss_ai_tick_interval,MonsterInfo#p_monster.monsterid},Now),
                            {ok,not_continue};
                        _ ->
                            false
                    end;
                false ->
                    false
            end
    end;
judge_touch_off_boss_ai_3(ConditionID,_Condition,State,_MonsterInfo,_Rand) when (ConditionID=:=?AI_CONDICTION_FIRST_BE_ATTACKED) 
    orelse (ConditionID=:=?AI_CONDICTION_BEGIN_FIGHT) ->   
    TouchedAiConditionList = State#monster_state.touched_ai_condition_list,
    case lists:keyfind(ConditionID,2,TouchedAiConditionList) of
        false ->
            false;
        _ ->
            {ok,not_continue}
    end;
judge_touch_off_boss_ai_3(_ConditionID,_,_,_,_)->
    false.

judge_touch_off_boss_ai_4(Condition,Rand)->
    #p_boss_ai_condition{rate=Rate} = Condition,
    case Rand =< Rate of
        true ->
            #p_boss_ai_condition{skills=Skills,talks=Talks,total_weight=TotalWeight,npc_talks=NpcTalks} = Condition,
            Talk = get_boss_talk(Talks),
            case Skills of
                []->    %%只有对话
                    {[],Talk,NpcTalks};
                _ ->    %%技能+对话
                    RandomWt = common_tool:random(1,TotalWeight),
                    {get_ai_skill_from_weight(Skills,RandomWt,0),Talk,NpcTalks}
            end;
        _ ->
            false
    end.

get_ai_skill_from_weight([],_RandomWt,_)->
    undefined;
get_ai_skill_from_weight([Skill|T],RandomWt,Acc)->
    NewWeight = Acc+Skill#p_boss_ai_skill.weight,
    case NewWeight >= RandomWt of
        true->
            Skill;
        _ ->
            get_ai_skill_from_weight(T,RandomWt,NewWeight)
    end.
 

%%执行第一个匹配的BOSS-AI
execute_boss_ai(undefined,MonsterInfo,_,State) ->
	NewState = State#monster_state{touched_ai_condition_list=[]},
	set_monster_state(MonsterInfo#p_monster.monsterid,NewState),
    NewState;
execute_boss_ai([],MonsterInfo,_,State) ->
	NewState = State#monster_state{touched_ai_condition_list=[]},
	set_monster_state(MonsterInfo#p_monster.monsterid,NewState),
    NewState;
execute_boss_ai(SkillList,MonsterInfo,MonsterPos,State) ->
    case SkillList of
        [SkillInfo|_T]->
            next;
        SkillInfo when is_record(SkillInfo,p_boss_ai_skill)->
            ok
    end,
    #p_boss_ai_skill{skill_id = SkillID,skill_level = SkillLevel,
                     parm = Parm,reset_attacktime = ResetAttackTime} = SkillInfo,
    
    case SkillID of
        ?SKILL_SUMMON ->
            summon_monster(Parm,MonsterInfo,MonsterPos,State#monster_state{touched_ai_condition_list=[]});
        ?SKILL_TRANSFER ->
            fight3(MonsterPos,MonsterInfo,transfer,State#monster_state{touched_ai_condition_list=[]});
        _ ->
            fight3(MonsterPos,MonsterInfo,{SkillID,SkillLevel,ResetAttackTime},State#monster_state{touched_ai_condition_list=[]})
    end.

execute_monster_talk(MonsterId,TalkList) when is_integer(MonsterId)->
    case TalkList of
        [Talk|_T]-> 
            next;
        Talk when is_record(Talk,p_monster_talk)->
             next;           
        _-> Talk=undefined
    end,
    case Talk of
        #p_monster_talk{talk=TalkContent,show_type=ShowType} ->
            TalkRecord = #m_monster_talk_toc{monster_id=MonsterId,show_type=ShowType,content=TalkContent},
            mgeem_map:do_broadcast_insence_include([{monster, MonsterId}], ?MONSTER, ?MONSTER_TALK, TalkRecord, mgeem_map:get_state()),
            ok;
        _ ->
            ignore
    end.
execute_npc_talk(MonsterId,TalkList) when is_integer(MonsterId)->
    lists:foreach(
      fun(Talk)-> 
              case Talk of
                  #p_npc_talk{talk_id=TalkId,npc_id=NpcId}->
                      R2 = #m_fb_npc_talk_toc{npc_id=NpcId,talk_id=TalkId},
                      mgeem_map:do_broadcast_insence_include([{monster, MonsterId}], ?FB_NPC, ?FB_NPC_TALK, R2, mgeem_map:get_state()),
                      ok;
                  _ ->
                      ignore
              end
      end , TalkList).

%%@doc 根据概率获取一句BOSS对话
%%@return undefined || binary()
get_boss_talk(undefined) ->
    undefined;
get_boss_talk([]) ->
    undefined;
get_boss_talk([Talk|T]) ->
    #p_monster_talk{rate=Rate} = Talk,
    case random:uniform(10000) =< Rate of
        true ->
            Talk;
        false ->
            get_boss_talk(T)
    end.


reborn(State)->
    #monster_state{       
                   deadtime = DeadTime,
                   monster_info = MonsterInfo} = State,
    #p_monster{typeid=TypeID} = MonsterInfo,
    case cfg_monster:find(TypeID) of
        [] ->
            set_next_work(MonsterInfo#p_monster.monsterid,500000,loop);
        [BaseInfo] ->
            case judge_can_reborn(BaseInfo,MonsterInfo,DeadTime) of
                true ->
                    reborn_monster(BaseInfo, State);
                false ->
                    nil 
            end
    end.


%%判断怪物能否出生
judge_can_reborn(BaseInfo,MonsterInfo,DeadTime) ->
    MonsterID = MonsterInfo#p_monster.monsterid,
    RefreshInfo = BaseInfo#p_monster_base_info.refresh,
    RefreshType = RefreshInfo#p_refresh_info.refresh_type,
    case RefreshType of
        ?REFRESH_BY_INTERVAL ->
            Interval = RefreshInfo#p_refresh_info.refresh_interval,
            Now = common_tool:now(),
            case DeadTime of
                undefined ->
                    true;
                _ ->
                    case Now - DeadTime >= Interval of
                        true ->
                            true;
                        false ->
                            set_next_work(MonsterID,(Interval-Now+DeadTime)*1000,loop),
                            false
                    end
            end;
       ?REFRESH_BY_TIMEBUCKET ->
            case judge_in_timebucket(BaseInfo,MonsterInfo,DeadTime,RefreshInfo) of
                true ->
                    true;
                false ->
                    set_next_work(MonsterID,5000,loop),
                    false
            end;
        _ ->
            %%TODO judge can reborn with other reborn kind
            set_next_work(MonsterID,5000,loop),
            false
    end.

judge_in_timebucket(_BaseInfo,_MonsterInfo,DeadTime,RefreshInfo) ->
	Interval = RefreshInfo#p_refresh_info.refresh_interval,
	_RefreshStartYear = RefreshInfo#p_refresh_info.refresh_start_year,
	_RefreshEndYear = RefreshInfo#p_refresh_info.refresh_end_year,
	RefreshStartMonth = RefreshInfo#p_refresh_info.refresh_start_month,
	RefreshEndMonth = RefreshInfo#p_refresh_info.refresh_end_month,
	RefreshStartDay = RefreshInfo#p_refresh_info.refresh_start_day,
	RefreshEndDay = RefreshInfo#p_refresh_info.refresh_end_day,
	RefreshStartWeekDay = RefreshInfo#p_refresh_info.refresh_start_weekday,
	RefreshEndWeekDay = RefreshInfo#p_refresh_info.refresh_end_weekday,
	RefreshStartHour = RefreshInfo#p_refresh_info.refresh_start_hour,
	RefreshEndHour = RefreshInfo#p_refresh_info.refresh_end_hour,
	RefreshStartMinute = RefreshInfo#p_refresh_info.refresh_start_minute,
	RefreshEndMinute = RefreshInfo#p_refresh_info.refresh_end_minute,
	_RefreshStartTime = RefreshInfo#p_refresh_info.active_time,
	_RefreshEndTime = RefreshInfo#p_refresh_info.start_time,
	_ActivTime = RefreshInfo#p_refresh_info.active_time,
	{Year,Month,Day} = erlang:date(),
	{Hour,Minute,_Second}= erlang:time(),
	WeekDay = calendar:day_of_the_week(Year, Month, Day),
	case RefreshStartMonth =< Month andalso RefreshEndMonth >= Month andalso
			 RefreshStartDay =< Day andalso RefreshEndDay >= Day andalso
			 RefreshStartWeekDay =< WeekDay andalso RefreshEndWeekDay >= WeekDay andalso
			 RefreshStartHour =< Hour andalso RefreshEndHour >= Hour andalso
			 RefreshStartMinute =< Minute andalso RefreshEndMinute >= Minute of
		true ->
			case Interval of
				0 ->
					DeadTime =:= undefined;
				_ ->
					Now = common_tool:now(),
					case DeadTime of
						undefined ->
							true;
						_ ->
							Now - DeadTime >= Interval
					end
			end;
		false ->
			false 
	end.


%%怪物出生
reborn_monster(BaseInfo, State) ->
	#monster_state{
					  monster_info = MonsterInfo,
					  special_data=SpecialData} = State,
	
	#p_monster_base_info{
							rarity = Rarity,
							monstername = MonsterName,
							min_attack = MinAttack,                                 
							max_attack = MaxAttack,     
							phy_defence = PhyDefence,                   
							magic_defence = MagDefence,         
							blood_resume_speed = HpResume,
							magic_resume_speed = MpResume,
							dead_attack = DeadAttack,            
							lucky = Lucky,
							move_speed = MoveSpeed,            
							attack_speed = AttackSpeed,
							miss = Dodge,                      
							no_defence = NoDefence,                 
							max_hp = MaxHp,
							max_mp = MaxMp,
							phy_anti=PhyAnti,
							magic_anti=MagicAnti,
							poisoning_resist=PoiResist,
							dizzy_resist=DizResist,
							freeze_resist=FreResist,
							hit_rate=HitRate,
							block = Block,
							wreck = Wreck,
							tough = Tough,
							vigour = Vigour,
							week = Week,
							molder = Molder,
							hunger = Hunger,
							bless = Bless,
							crit = Crit,
							bloodline = Bloodline,
							phy_hurt_rate=PhyHurtRate,
							magic_hurt_rate=MagicHurtRate
						} = BaseInfo,
	
	#p_monster{mapid = MapID, typeid = Type, monsterid = MonsterID, reborn_pos = Pos} = MonsterInfo,
	RandDirPos = Pos#p_pos{dir = random:uniform(8)-1} ,
	NewMonsterMapInfo = #p_map_monster{monsterid = MonsterID, 
									   max_hp = MaxHp, 
									   max_mp = MaxMp, 
									   mapid = MapID, 
									   move_speed = MoveSpeed, 
									   hp = MaxHp, 
									   mp = MaxMp, 
									   pos = RandDirPos,
									   typeid = Type,
									   state = ?GUARD_STATE
									  },
	
	NewPos = mod_map_actor:get_unref_pos(NewMonsterMapInfo#p_map_monster.pos,0,7,4),
	NewMonsterMapInfo2 = NewMonsterMapInfo#p_map_monster{pos = NewPos},
	case monster_reborn(MonsterID, NewMonsterMapInfo2) of
		ok ->
			NewMonsterInfo = 
				MonsterInfo#p_monster{monstername = MonsterName,
									  min_attack = MinAttack,                                 
									  max_attack = MaxAttack,                                
									  phy_defence = PhyDefence,                   
									  magic_defence = MagDefence,         
									  blood_resume_speed = HpResume,
									  magic_resume_speed = MpResume,
									  dead_attack = DeadAttack,            
									  lucky = Lucky,
									  move_speed = MoveSpeed,            
									  attack_speed = AttackSpeed,
									  miss = Dodge,                      
									  no_defence = NoDefence, 
									  hp = MaxHp,
									  mp = MaxMp,
									  max_hp = MaxHp,
									  max_mp = MaxMp,
									  pos = NewPos,
									  phy_anti=PhyAnti,
									  magic_anti=MagicAnti,
									  first_enemies = [],
									  second_enemies = [],
									  third_enemies = [],
									  buffs = [],
									  state =?GUARD_STATE,
									  poisoning_resist=PoiResist,
									  dizzy_resist=DizResist,
									  freeze_resist=FreResist,
									  hit_rate=HitRate,
									  block = Block,
									  wreck = Wreck,
									  tough = Tough,
									  vigour = Vigour,
									  week = Week,
									  molder = Molder,
									  hunger = Hunger,
									  bless = Bless,
									  crit = Crit,
									  bloodline = Bloodline,
									  phy_hurt_rate=PhyHurtRate,
									  magic_hurt_rate=MagicHurtRate
									 },
			NewState = State#monster_state{
											  monster_info = NewMonsterInfo,
											  buf_timer_ref = [],
											  walk_path = [],
											  touched_ai_condition_list = [],
											  last_enemy_pos = undefined,
											  last_attack_time = undefined},
			erase_monster_enemy(MonsterID),
			write_monster_persistent_info(NewState),
			case Rarity of
				?BOSS ->
					write_boss_reborn_log(NewMonsterInfo,SpecialData);
				_ ->
					ignore
			end,
			
			catch hook_monster_born(MonsterInfo, BaseInfo),
			set_next_work(MonsterID,?MIN_MONSTER_WORK_TICK,loop,NewState);
		_R ->
			%%?ERROR_MSG("怪物出生异常,~w",[_R]),
			set_next_work(MonsterID,1000,loop,State)
	end.

monster_reborn(MonsterID, MonsterMapInfo) ->
    MapState = mgeem_map:get_state(),
    mod_map_actor:do_enter(0, MonsterID, MonsterID, monster, MonsterMapInfo, 0, MapState).


write_boss_reborn_log(MonsterInfo,SpecialData) -> 
    case is_integer(SpecialData) of
        true->
            SpecialID = SpecialData;
        _ ->
            SpecialID = 0
    end,
    BossLog = #r_log_boss_state{
                                boss_id = MonsterInfo#p_monster.monsterid,
                                boss_type = MonsterInfo#p_monster.typeid,
                                boss_name = MonsterInfo#p_monster.monstername,
                                map_id = MonsterInfo#p_monster.mapid,
                                special_id=SpecialID,
                                ext = SpecialData,
                                boss_state = ?GUARD_STATE,
                                mtime = common_tool:now()
                               },
    common_general_log_server:log_boss(BossLog).


erase_monster_enemy(MonsterID) ->
    case get({monster_enemy,MonsterID}) of
        undefined ->
            nil;
        List ->
            lists:foreach(fun(Key)-> erase({enemy_level,MonsterID,Key}) end,List)
    end,
    put({monster_enemy,MonsterID},[]).

erase_monster_enemy(MonsterID,Key) ->
    case get({monster_enemy,MonsterID}) of
        undefined ->
            nil;
        List ->
            
            put({monster_enemy,MonsterID},lists:delete(Key,List))
    end,
    erase({enemy_level,MonsterID,Key}).

set_monster_enemy(MonsterID,Key,Level) ->
    case get({monster_enemy,MonsterID}) of
        undefined ->
            put({monster_enemy,MonsterID},[Key]),
            put({enemy_level,MonsterID,Key},Level);
        List ->
            case lists:member(Key,List) of
                true ->
                    nil;
                false ->
                    put({monster_enemy,MonsterID},[Key|List])
            end,
            put({enemy_level,MonsterID,Key},Level)
    end.


%%开始攻击
begin_to_fight(MonsterID,State,ActorIdList,ActorType,Rarity) ->
    
    #monster_state{
                   ai_info = AIInfo,
                   monster_info = MonsterInfo
                  } = State,
    NewMonsterInfo = init_enemies_lists(MonsterInfo,ActorIdList,ActorType),
    Now = common_tool:now(),
    case ?CHECK_RARITY_BOSS_AI( Rarity ) andalso AIInfo =/= undefined of
        true ->
            ConditionList = AIInfo#p_boss_ai_plan.conditions,
            case lists:keyfind(?AI_CONDICTION_BEGIN_FIGHT, #p_boss_ai_condition.condition_id, ConditionList) of
                false ->
                    AiCondition = [];
                _ ->
                     AiCondition = [{condition,?AI_CONDICTION_BEGIN_FIGHT}]
            end,
            erase({boss_ai_tick_interval,MonsterID});
        _ ->
            AiCondition = []
    end,
    NewState = State#monster_state{monster_info = NewMonsterInfo,last_attack_time = Now,touched_ai_condition_list = AiCondition},
    set_next_work(MonsterID,?MIN_MONSTER_WORK_TICK,loop,NewState).

%% %%主动怪检测到周围有玩家时初始化怪物仇恨列表
%% init_enemies_lists(MonsterInfo,RoleList) ->
%%     MonsterID = MonsterInfo#p_monster.monsterid,
%%     NewEnemies =
%%         lists:foldl(
%%           fun(RoleID,Third_Enemies) -> 
%%                   EnemyRole = #p_enemy{
%%                                        actor_key = {RoleID,role},
%%                                        total_hurt = 0,
%%                                        last_att_time = common_tool:now()
%%                                       },
%%                   case get({?ROLE_SUMMONED_PET_ID,RoleID}) of
%%                       undefined ->
%%                           Enemy = [EnemyRole];
%%                       PetID ->
%%                           EnemyPet = #p_enemy{
%%                                               actor_key = {PetID,pet},
%%                                               total_hurt = 0,
%%                                               last_att_time = common_tool:now()
%%                                              },
%%                           case random:uniform(2) of
%%                               1 ->
%%                                   Enemy = [EnemyRole,EnemyPet];
%%                               2 ->
%%                                   Enemy = [EnemyPet,EnemyRole]
%%                           end,
%%                           set_monster_enemy(MonsterID, {PetID,pet}, ?THIRD_ENEMY_LEVEL)
%%                   end,
%%                   set_monster_enemy(MonsterID, {RoleID,role}, ?THIRD_ENEMY_LEVEL),
%%                   lists:append(Enemy, Third_Enemies)
%%           end, [], RoleList),
%%     MonsterInfo#p_monster{third_enemies = NewEnemies,state = ?FIGHT_STATE}.


%%主动怪检测到周围有玩家时初始化怪物仇恨列表
init_enemies_lists(MonsterInfo,ActorIdList,ActorType)->
    MonsterID = MonsterInfo#p_monster.monsterid,
    NewEnemies =
        lists:foldl(
          fun(ActorID,Third_Enemies) -> 
                  Key = {ActorID,ActorType},
                  Enemy = #p_enemy{
                                   actor_key = Key,
                                   total_hurt = 0,
                                   last_att_time = common_tool:now()
                                  },
                  set_monster_enemy(MonsterID, Key, ?THIRD_ENEMY_LEVEL),
                  [Enemy|Third_Enemies]
          end, [], ActorIdList),
    MonsterInfo#p_monster{third_enemies = NewEnemies,state = ?FIGHT_STATE}.



%%跟新怪物仇恨列表
update_enemies_lists(MonsterInfo,AttentionRadius) ->
    MonsterID = MonsterInfo#p_monster.monsterid,
    MonsterPos = mod_map_actor:get_actor_pos(MonsterID,monster),  
    MonsterInfo2 = update_first_enemy_list(MonsterInfo,AttentionRadius,MonsterID,MonsterPos),
    MonsterInfo3 = update_second_enemy_list(MonsterInfo2,AttentionRadius,MonsterID,MonsterPos),
    update_third_enemy_list(MonsterInfo3,AttentionRadius,MonsterID,MonsterPos).


%%跟新1级仇恨列表
update_first_enemy_list(MonsterInfo,AttentionRadius,_MonsterID,MonsterPos) ->
    MonsterID = MonsterInfo#p_monster.monsterid,
    First_Enemies = MonsterInfo#p_monster.first_enemies,
    SecondEnemies =  MonsterInfo#p_monster.second_enemies,  
    case First_Enemies of
        [] ->
            MonsterInfo;
        _List ->
            {NewFirstList,NewSecondList} = 
                lists:foldl(
                  fun(Info,{Acc,Acc2}) ->
                          #p_enemy{actor_key = Key} = Info,
                          {ActorID,ActorType} = Key,
                          ActorPos = get_enemy_pos(ActorID,ActorType),
                         case judge_in_distance(MonsterPos,ActorPos,AttentionRadius) andalso
                              mod_server_npc:check_enemy_can_attack(ActorID,ActorType) of
                              false ->
                                  erase_monster_enemy(MonsterID,Key),
                                  {lists:delete(Info, Acc),Acc2};
                              true ->
                                  Now =  common_tool:now(),
                                  LastAttackTime =  Info#p_enemy.last_att_time,
                                  case Now - LastAttackTime > 10 of
                                      true ->
                                          set_monster_enemy(MonsterID, Key, ?SECOND_ENEMY_LEVEL),
                                          NewAcc = lists:delete(Info, Acc),
                                          NewAcc2 = [Info|Acc2],
                                          {NewAcc,NewAcc2};
                                      false ->
                                          {Acc,Acc2}
                                  end
                          end
                  end, {First_Enemies,SecondEnemies}, First_Enemies),
            %%TODO sort with total_hurt
            MonsterInfo#p_monster{first_enemies = NewFirstList,second_enemies = NewSecondList}
    end.


%%跟新2级仇恨列表
update_second_enemy_list(MonsterInfo,AttentionRadius,_MonsterID,MonsterPos)->
    MonsterID = MonsterInfo#p_monster.monsterid,
    SecondEnemies =  MonsterInfo#p_monster.second_enemies,
    case SecondEnemies of
        [] ->
            MonsterInfo;
        _List ->
            NewList = 
                lists:foldl(
                  fun(Info,Acc) ->
                           #p_enemy{actor_key = Key} = Info,
                          {ActorID,ActorType} = Key,
                          ActorPos = get_enemy_pos(ActorID,ActorType),
                          case judge_in_distance(MonsterPos,ActorPos,AttentionRadius) andalso
                              mod_server_npc:check_enemy_can_attack(ActorID,ActorType) of
                              false ->
                                  erase_monster_enemy(MonsterID,Key),
                                  lists:delete(Info, Acc);
                              true ->
                                  Acc
                          end
                  end, SecondEnemies, SecondEnemies),
            %%TODO sort with total_hurt
            MonsterInfo#p_monster{second_enemies = NewList}
    end.
%%跟新3级仇恨列表
update_third_enemy_list(MonsterInfo,AttentionRadius,_MonsterID,MonsterPos)->
    MonsterID = MonsterInfo#p_monster.monsterid,
    MonsterType = MonsterInfo#p_monster.typeid,
    ThirdEnemies =  MonsterInfo#p_monster.third_enemies,
    case ThirdEnemies of
        [] ->
            MonsterInfo;
        _List ->
            NewList = 
                lists:foldl(
                  fun(Info,Acc) ->
                          #p_enemy{actor_key = Key} = Info,
                          {ActorID,ActorType} = Key,
                          case common_config_dyn:find(monster_etc,{monster_enemy_update_kind,MonsterType}) of
                              [] ->
                                  check_normal_enemy(ActorID,ActorType,AttentionRadius,MonsterID,MonsterPos,Key,Info, Acc);
                              [?MONSTER_ENEMY_KIND_OF_COLLECTING_ROLE] ->
                                  check_collecting_enemy(ActorID,ActorType,AttentionRadius,MonsterID,MonsterPos,Key,Info, Acc);
                              _ ->
                                  lists:delete(Info, Acc)
                          end
                  end, ThirdEnemies, ThirdEnemies),
            %%TODO sort with total_hurt
            MonsterInfo#p_monster{third_enemies = NewList}
    end.


check_normal_enemy(ActorID,ActorType,AttentionRadius,MonsterID,MonsterPos,Key,Info, Acc) ->
    ActorPos = mod_map_actor:get_actor_pos(ActorID,ActorType),
    case judge_in_distance(MonsterPos,ActorPos,AttentionRadius) andalso
             mod_server_npc:check_enemy_can_attack(ActorID,ActorType) of
        false ->
            erase_monster_enemy(MonsterID,Key),
            lists:delete(Info, Acc);
        true ->
            Acc
    end.

%%更新仇恨列表的时候去掉非采集状态玩家
check_collecting_enemy(ActorID,role,AttentionRadius,MonsterID,MonsterPos,Key,Info, Acc) ->
    case mod_map_actor:get_actor_mapinfo(ActorID,role) of
        undefined ->
            lists:delete(Info, Acc);
        #p_map_role{state=RoleState,pos=ActorPos} ->
            case judge_in_distance(MonsterPos,ActorPos,AttentionRadius) andalso
                     RoleState =:= ?ROLE_STATE_COLLECT of
                false ->
                    erase_monster_enemy(MonsterID,Key),
                    lists:delete(Info, Acc);
                true ->
                    Acc
            end
    end;
check_collecting_enemy(_ActorID,_,_AttentionRadius,_MonsterID,_MonsterPos,_Key,Info, Acc) ->
    lists:delete(Info, Acc).


%%被攻击时刷新仇恨列表
addto_enemies_lists(MonsterInfo,ActorID,ActorType,ReduceHP) ->
    MonsterID = MonsterInfo#p_monster.monsterid,
    case get({enemy_level,MonsterID,{ActorID,ActorType}}) of
        undefined ->
            addto_enemylist({ActorID,ActorType},ReduceHP,MonsterInfo);
        ?FIRST_ENEMY_LEVEL ->
            addto_enemylist2({ActorID,ActorType},ReduceHP,MonsterInfo);
        ?SECOND_ENEMY_LEVEL ->
            addto_enemylist3({ActorID,ActorType},ReduceHP,MonsterInfo);
        ?THIRD_ENEMY_LEVEL ->
            addto_enemylist4({ActorID,ActorType},ReduceHP,MonsterInfo)
    end.  
%% %%添加到1级仇恨列表
%% addto_enemylist(Key, ReduceHP,MonsterInfo) ->
%%     {ActorID,ActorType} = Key,
%%     EnemyInfo1 = [#p_enemy{
%%                            actor_key = Key,
%%                            total_hurt = ReduceHP,
%%                            last_att_time =  common_tool:now()}],
%%     case ActorType of
%%         role ->
%%             case get({?ROLE_SUMMONED_PET_ID,ActorID}) of
%%                 undefined ->
%%                     EnemyInfo2 = [],
%%                     EnemyInfo3 = EnemyInfo1;
%%                 PetID ->
%%                     case mod_map_actor:get_actor_mapinfo(ActorID,pet) of
%%                         #p_map_pet{level=Level} when Level > 15 ->  %%不攻击15级以前的异兽
%%                             EnemyInfo3 = EnemyInfo1, 
%%                             EnemyInfo2 = [#p_enemy{
%%                                                    actor_key = {PetID,pet},
%%                                                    total_hurt = 0,
%%                                                    last_att_time =  common_tool:now()}];
%%                         _ ->
%%                             EnemyInfo2 = [],
%%                             EnemyInfo3 = EnemyInfo1
%%                     end
%%             end;
%%         pet ->
%%             case mod_map_actor:get_actor_mapinfo(ActorID,pet) of
%%                 undefined ->
%%                     EnemyInfo3 = EnemyInfo1,
%%                     EnemyInfo2 = [];
%%                 #p_map_pet{role_id=RoleID,level=Level} when Level > 15 ->   %%不攻击15级以前的异兽
%%                     EnemyInfo3 = EnemyInfo1,
%%                     EnemyInfo2 = [#p_enemy{
%%                                            actor_key = {RoleID,role},
%%                                            total_hurt = 0,
%%                                            last_att_time =  common_tool:now()}];
%%                 #p_map_pet{role_id=RoleID} ->
%%                     EnemyInfo3 = [],
%%                     EnemyInfo2 = [#p_enemy{
%%                                            actor_key = {RoleID,role},
%%                                            total_hurt = 0,
%%                                            last_att_time =  common_tool:now()}]
%%             end
%%     end,
%%     case random:uniform(2) of
%%         1 ->
%%             EnemyInfo = lists:append(EnemyInfo3,EnemyInfo2);
%%         2 ->
%%             EnemyInfo = lists:append(EnemyInfo2,EnemyInfo3)
%%     end,
%%     MonsterID = MonsterInfo#p_monster.monsterid,
%%     FirstEnemies = MonsterInfo#p_monster.first_enemies,
%%     NewFirstEnemines = lists:append(FirstEnemies,EnemyInfo),
%%     set_monster_enemy(MonsterID, Key,?FIRST_ENEMY_LEVEL),
%%     MonsterInfo#p_monster{first_enemies = NewFirstEnemines}.
%%添加到1级仇恨列表
addto_enemylist(Key, ReduceHP,MonsterInfo) ->
    MonsterID = MonsterInfo#p_monster.monsterid,
    EnemyInfo = #p_enemy{
                                 actor_key = Key,
                                 total_hurt = ReduceHP,
                                 last_att_time =  common_tool:now()},
    FirstEnemies = MonsterInfo#p_monster.first_enemies,
    NewFirstEnemines = lists:append(FirstEnemies,[EnemyInfo]),
    set_monster_enemy(MonsterID, Key,?FIRST_ENEMY_LEVEL),
    MonsterInfo#p_monster{first_enemies = NewFirstEnemines}.
%%跟新1级仇恨列表
addto_enemylist2(Key,ReduceHP,MonsterInfo) ->
    FirstEnemies = MonsterInfo#p_monster.first_enemies,
    NewEnemies = 
        case lists:keyfind(Key, 2, FirstEnemies) of
            false ->
                ?INFO_MSG("unexcept! ~w ~w",[FirstEnemies,Key]),
                FirstEnemies;
            EnemyInfo ->
                Hurt = EnemyInfo#p_enemy.total_hurt,
                NewEnemyInfo = 
                    EnemyInfo#p_enemy{
                                              total_hurt = ReduceHP + Hurt,
                                              last_att_time = common_tool:now()},
                lists:keyreplace(Key, 2, FirstEnemies, NewEnemyInfo)
        end,
    MonsterInfo#p_monster{first_enemies = NewEnemies}.
%%从2级仇恨列表添加到1级仇恨列表
addto_enemylist3(Key,ReduceHP,MonsterInfo) ->
    MonsterID = MonsterInfo#p_monster.monsterid,
    FirstEnemies = MonsterInfo#p_monster.first_enemies,
    SecondEnemies = MonsterInfo#p_monster.second_enemies,
    case lists:keyfind(Key, 2,SecondEnemies) of
        false ->
            ?INFO_MSG("unexcept!~w ~w",[SecondEnemies,Key]),
            NewFirstEnemines = FirstEnemies;
        EnemyInfo ->
            Hurt = EnemyInfo#p_enemy.total_hurt,
            NewEnemyInfo = EnemyInfo#p_enemy{total_hurt = ReduceHP + Hurt,last_att_time = common_tool:now()},           
            NewFirstEnemines = lists:append(FirstEnemies,[NewEnemyInfo])
    end,
    NewSecondEnemies = lists:keydelete(Key, 2, SecondEnemies),
    set_monster_enemy(MonsterID, Key, ?FIRST_ENEMY_LEVEL),
    MonsterInfo#p_monster{first_enemies = NewFirstEnemines,second_enemies = NewSecondEnemies}.
%%从3级仇恨列表添加到1级仇恨列表
addto_enemylist4(Key,ReduceHP,MonsterInfo) ->
    MonsterID = MonsterInfo#p_monster.monsterid,
    FirstEnemies = MonsterInfo#p_monster.first_enemies,
    ThirdEnemies = MonsterInfo#p_monster.third_enemies,
    case lists:keyfind(Key, 2,ThirdEnemies) of
        false ->
            ?INFO_MSG("unexcept! ~w ~w",[ThirdEnemies,Key]),
            NewFirstEnemines = FirstEnemies;
        EnemyInfo ->
            Hurt = EnemyInfo#p_enemy.total_hurt,
            NewEnemyInfo = EnemyInfo#p_enemy{total_hurt = ReduceHP + Hurt,last_att_time = common_tool:now()},
            NewFirstEnemines = lists:append(FirstEnemies,[NewEnemyInfo])
    end,
    NewThirdEnemies = lists:keydelete(Key, 2, ThirdEnemies),
    set_monster_enemy(MonsterID, Key, ?FIRST_ENEMY_LEVEL),
    MonsterInfo#p_monster{first_enemies = NewFirstEnemines,third_enemies = NewThirdEnemies}.


%%获取一个仇恨列表里的攻击目标
get_enemy_role(_MonsterID,[], Acc) ->
    {no, Acc};
get_enemy_role(MonsterID,[Enemies|T], Acc) ->
    case Enemies of
        [] ->
            get_enemy_role(MonsterID,T, [[]|Acc]);
        List ->
            [Role|_] = List,
            {Role, Acc}
    end.


%%怪物攻击玩家或者异兽
attack_enemy(State,MonsterID,ActorID,ActorType,AttackSpeed,{SkillID,SkillLevel}) ->
    DataIn = {ActorID,{SkillID,SkillLevel},ActorType},  
    self() ! {mod, mof_fight_handler,{monster_attack, ?FIGHT, ?FIGHT_ATTACK, DataIn, MonsterID}},
    set_next_work(MonsterID,round(1360000/AttackSpeed), loop,State#monster_state{walk_path = []}).


%%攻击怪物
attack_monster(State,{ActorID,ActorType,ReduceHP}) ->
	attack_monster(State,{ActorID,ActorType,ReduceHP},_IsRoleFight=false,_SkillID=0).
attack_monster(State,{ActorID,ActorType,ReduceHP},IsRoleFight,SkillID) ->
    case ActorType of
        role ->
            attack_monster_2(State,ActorID,ActorType,ReduceHP,IsRoleFight,SkillID);
        server_npc->
            attack_monster_2(State,ActorID,ActorType,ReduceHP,_IsRoleFight=false,_SkillID=0);
		_ ->
			ingore
    end.

%% IsRoleFight = true时，表示玩家攻击怪物，不发monster_dead协议
attack_monster_2(State,ActorID,ActorType,ReduceHP,IsRoleFight,SkillID)->
    #monster_state{
                  ai_info = AIInfo,
                  last_attack_time = LastAttackTime,
                  touched_ai_condition_list = AiConditionList,
                  monster_info = MonsterInfo,
                  first_attack_time = FirstAttackTime,
                  monster_change_info = MonsterChangeInfo,
                  created_time = CreatedTime
                 } = State,
    #p_monster{
                state = MonsterState,
                monsterid = MonsterID,
                hp = HP,
				max_hp = MaxHP
              } = MonsterInfo,
    case MonsterState =:= ?DEAD_STATE of
        false ->
            NowSeconds = common_tool:now(),
            NewHp = HP - ReduceHP,
            case ActorType of
                role->
			         mod_bigpve_fb:hook_monster_reduce_hp(MonsterID,ActorID,ReduceHP,NewHp,MaxHP);
                _ ->
                    ignore
            end,
            %% add by caochuncheng 2011-08-13 判断是否需要加入怪物仇恨列表
            case MonsterChangeInfo =/= undefined 
                andalso erlang:is_record(MonsterChangeInfo,r_monster_change_info)
                andalso MonsterChangeInfo#r_monster_change_info.is_attack =:= 1
                andalso NowSeconds =< CreatedTime + MonsterChangeInfo#r_monster_change_info.dont_interval_seconds of
                true -> %% 不需要加入怪物仇恨列表
                    IsMonsterChangeState = true;
                _ ->
                    IsMonsterChangeState = false
            end,
            
            case mod_map_actor:get_actor_mapinfo(ActorID,ActorType) of
                #p_map_server_npc{is_undead=true}->
                    MonsterInfo3 = MonsterInfo; %%无敌的NPC就不加入到仇恨列表中
                _ ->
                    MonsterInfo3 = addto_enemies_lists(MonsterInfo,ActorID,ActorType,ReduceHP)
            end,
            
            case AIInfo of
                undefined ->
                    NewAiCondition = AiConditionList;
                _ ->
                    ConditionList = AIInfo#p_boss_ai_plan.conditions,
                    Ret = lists:foldl(
                            fun(Condition,Acc) ->
                                    case Acc of
                                        undefined ->
                                            case Condition#p_boss_ai_condition.condition_id of
                                                ?AI_CONDICTION_BLOOD_RATE ->
                                                    MaxHP = MonsterInfo3#p_monster.max_hp,
                                                    {Percent} =  Condition#p_boss_ai_condition.parm,
                                                    TouchHP = MaxHP*Percent/10000,
                                                    case NewHp < TouchHP andalso HP >= TouchHP of
                                                        true ->
                                                            {condition,{?AI_CONDICTION_BLOOD_RATE,Percent}};
                                                        false ->
                                                            Acc
                                                    end;
                                                ?AI_CONDICTION_NORMAL_HEATED ->
                                                    {condition,?AI_CONDICTION_NORMAL_HEATED};
                                                ?AI_CONDICTION_FIRST_BE_ATTACKED ->
                                                    case MonsterState of
                                                        ?GUARD_STATE ->
                                                            {condition,?AI_CONDICTION_FIRST_BE_ATTACKED};
                                                        _ ->
                                                            Acc
                                                    end;
                                                 ?AI_CONDICTION_BEGIN_FIGHT ->
                                                    case MonsterState of
                                                        ?GUARD_STATE ->
                                                            {condition,?AI_CONDICTION_BEGIN_FIGHT};
                                                        _ ->
                                                            Acc
                                                    end;
                                                 ?AI_CONDICTION_TICK_INTERVAL ->
                                                    %%erase({boss_ai_tick_interval,MonsterID}),
                                                    Acc;
                                                _ ->
                                                    Acc
                                            end;
                                        _ ->
                                            Acc
                                    end
                            end, undefined, ConditionList),
                    case Ret of
                        undefined ->
                            NewAiCondition = AiConditionList;
                        _ ->
                            NewAiCondition = [Ret|AiConditionList]
                    end
            end,
            case NewHp =< 0 of
                true ->
                    monster_attr_change(MonsterID,?BLOOD,0),         
                    MonsterInfo4 = MonsterInfo3#p_monster{state= ?DEAD_STATE},
                    monster_dead(ActorID,ActorType, State#monster_state{monster_info = MonsterInfo4},IsRoleFight,SkillID);
                false ->
                    monster_attr_change(MonsterID,?BLOOD,NewHp),
                    case IsMonsterChangeState =:= true of
                        true ->
                            NewMonsterState = MonsterInfo3#p_monster.state,
                            NextWorkTick = State#monster_state.next_work_tick;
                        _ ->
                            case MonsterState of
                                ?RETURN_STATE ->
                                    NewMonsterState = ?RETURN_STATE,
                                    NextWorkTick = State#monster_state.next_work_tick;
                                ?GUARD_STATE ->
                                    NewMonsterState = ?FIGHT_STATE,
                                    NextWorkTick = common_tool:now2() + 200;
                                ?PATROL_STATE ->
                                    NewMonsterState = ?FIGHT_STATE,
                                    NextWorkTick = common_tool:now2() + 200;
                                _ ->
                                    NewMonsterState = ?FIGHT_STATE,
                                    NextWorkTick = State#monster_state.next_work_tick
                            end
                    end,
                    MonsterInfo4 = MonsterInfo3#p_monster{hp = NewHp, state = NewMonsterState},
                    case LastAttackTime of
                        undefined ->
                            NewLastAttackTime = NowSeconds;
                        _ ->
                            NewLastAttackTime = LastAttackTime
                    end,
                    NewState = State#monster_state{
                                 monster_info = MonsterInfo4, 
                                 touched_ai_condition_list = NewAiCondition,
                                 last_attack_time = NewLastAttackTime,
                                 first_attack_time = if FirstAttackTime =:= 0 -> NowSeconds; true -> FirstAttackTime end
                                },
                    update_next_work(MonsterID,NextWorkTick,loop,NewState)
            end;
        true ->
			ignore
    end.

%%怪物死亡
monster_dead(ActorID,ActorType,State,IsRoleFight,SkillID)->
    #monster_state{
                   monster_info = MonsterInfo,
                   buf_timer_ref = RefList,
                   post_dead_fun=PostDeadFun,
                   create_type=CreateType,
                   special_data=SpecialData
                  } = State,
    #p_monster{monsterid = MonsterID,
               mapid = MapID,
               first_enemies = FirstEnemy,
               max_hp = _MaxHP,
               reborn_pos = RebornPos,
			   typeid=MonsterTypeID} = MonsterInfo,
	[#p_monster_base_info{exp=Exp,level=Level,rarity=Rarity,
						  min_drop_mp=MinDropMP,max_drop_mp=MaxDropMP}=BaseInfo] 
		= cfg_monster:find(MonsterTypeID),
    
    catch [  erlang:cancel_timer(Ref)||{_, Ref}<-RefList ],
    
    FirstEnemy2 = get_new_first_enemy_list_when_monster_dead(FirstEnemy),
    MonsterType = MonsterInfo#p_monster.typeid,

    MapState = mgeem_map:get_state(),
    
    case ActorType of
        role->
            add_exp(ActorID,FirstEnemy2,MonsterType,MonsterID,MapID,Exp, Level, Rarity),
            %%杀死某个怪物，会减攻击者一点精力值
            catch decrease_role_energy(ActorID,MonsterTypeID);
        _ ->
            ignore
    end,
     
    case FirstEnemy2 of
        [#p_enemy{actor_key=DropOwner}|_] ->
            next;
        [] -> %%假设抽仇恨列表为空，则为击杀者
            DropOwner = {ActorID,ActorType}
    end,
    
    KillerActor = {ActorID,ActorType},
    ?TRY_CATCH( hook_monster_dead(KillerActor,DropOwner, MonsterInfo, BaseInfo) ),
	
	mod_map_event:delete_handler({monster, MonsterID}),

    mod_map_actor:do_dead(MonsterID, monster, MapState),
	
	case ActorType of
		role->
			case mod_map_actor:get_actor_mapinfo(ActorID, role) of
				#p_map_role{summoned_pet_typeid=SummonedPetTypeID} ->
					case cfg_pet:get_base_info(SummonedPetTypeID) of
						[] -> PetCategoryType = 0;
						#p_pet_base_info{category_type=PetCategoryType} ->
							next
					end,
					R2 = #m_monster_dead_toc{
            monsterid         = MonsterID,
            role_id           = ActorID,
            src_type          = ?TYPE_ROLE,
            pet_category_type = PetCategoryType,
            skillid           = SkillID,
            mp                = 0
          },
					case mod_nimbus:hook_monster_dead(ActorID,MinDropMP,MaxDropMP) of
						{ok,DropMp} ->
							DataRecord = R2#m_monster_dead_toc{mp=DropMp};
						_ ->
							DataRecord = R2
					end;
				_ ->
					DataRecord = #m_monster_dead_toc{monsterid=MonsterID}
			end;
		_ ->
			DataRecord = #m_monster_dead_toc{monsterid=MonsterID}
	end,
	#p_pos{tx=TX, ty=TY} = mod_map_actor:get_actor_pos(MonsterID, monster),
	if
		IsRoleFight ->
			mof_common:add_already_dead({TX, TY, ?MONSTER, ?MONSTER_DEAD, DataRecord});
		true ->
			mgeem_map:do_broadcast_insence_by_txty(TX, TY, ?MONSTER, ?MONSTER_DEAD, DataRecord, MapState)
	end,
    NowTime = common_tool:now(),
    try
        case ActorType of
            role->
                DropThingList = mod_map_drop:monster_drop_thing(DropOwner, BaseInfo, MonsterID, SpecialData, RebornPos, FirstEnemy2),
                log_drop_thing(DropThingList,MapID),
                case Rarity of
                    ?BOSS->
                        case is_list(DropThingList) of
                            true->
                                catch write_boss_dead_log(MonsterInfo,SpecialData,DropThingList,ActorID,NowTime);
                            _ ->
                                catch write_boss_dead_log(MonsterInfo,SpecialData,[],ActorID,NowTime)
                        end;
                    _ ->
                        ignore
                end;
            _ ->
                ignore
        end
    catch
        _:Error2 ->
            ?ERROR_MSG("drop_thing, error: ~w, stacktrace: ~w", [Error2, erlang:get_stacktrace()])
    end,
    
    case erlang:is_function(PostDeadFun) of
        true ->
            try
                PostDeadFun()
            catch
                _:Error3 ->
                    ?ERROR_MSG("dead callbak function, error: ~w, stacktrace: ~w", [Error3, erlang:get_stacktrace()]),
                    []
            end;
        false ->
            ignore
    end,
    case CreateType of
        ?MONSTER_CREATE_TYPE_MANUAL_CALL ->
            write_monster_persistent_info(State#monster_state{monster_info = MonsterInfo,deadtime = NowTime}),
            monster_delete(MonsterID,IsRoleFight);
        ?MONSTER_CREATE_TYPE_NORMAL->
            NewState = State#monster_state{monster_info = MonsterInfo,deadtime = NowTime, buf_timer_ref = []},
            try 
                mod_map_actor:do_quit(MonsterID, monster, MapState, IsRoleFight)
            catch
                _:Error4 ->
                    ?ERROR_MSG("monster dead quit, error: ~w, stacktrace: ~w", [Error4, erlang:get_stacktrace()]),
                    []
            end,
            set_next_work(MonsterID, 1000, loop,NewState)
    end.


%%怪物死亡时把一级仇恨列表中异兽造成的伤害全部算到主人身上去
get_new_first_enemy_list_when_monster_dead(FirstEnemyList) ->
    lists:foldr(
      fun(Enemy,Acc) ->
              #p_enemy{actor_key={ActorID,ActorType},total_hurt=Hurt}=Enemy,
              case ActorType of
                  pet ->
                      case mod_map_actor:get_actor_mapinfo(ActorID,ActorType) of
                          undefined ->
                              Acc;
                          #p_map_pet{role_id=RoleID} ->
                              case lists:keyfind({RoleID,role}, #p_enemy.actor_key, Acc) of
                                  false ->
                                      [Enemy#p_enemy{actor_key={RoleID,role}}|Acc];
                                  Enemy2 ->
                                      OldHurt = Enemy2#p_enemy.total_hurt,
                                      NewEnemy = Enemy2#p_enemy{total_hurt=OldHurt+Hurt},
                              lists:keyreplace({ActorID,ActorType}, #p_enemy.actor_key, Acc, NewEnemy)
                              end
                      end;
                  role ->
                      case mod_map_actor:get_actor_mapinfo(ActorID,ActorType) of
                          undefined ->
                              lists:keydelete({ActorID,ActorType}, #p_enemy.actor_key, Acc);
                          #p_map_role{role_id=RoleID} ->
                              case lists:keyfind({RoleID,role}, #p_enemy.actor_key, Acc) of
                                  false ->
                                      [Enemy#p_enemy{actor_key={RoleID,role}}|Acc];
                                  Enemy2 ->
                                      OldHurt = Enemy2#p_enemy.total_hurt,
                                      NewEnemy = Enemy2#p_enemy{total_hurt=OldHurt+Hurt},
                              lists:keyreplace({ActorID,ActorType}, #p_enemy.actor_key, Acc, NewEnemy)
                              end
                      end;
                  _ ->
                      case lists:keyfind({ActorID,ActorType}, #p_enemy.actor_key, Acc) of
                          false ->
                              [Enemy|Acc];
                          Enemy2 ->
                              OldHurt = Enemy2#p_enemy.total_hurt,
                              NewEnemy = Enemy2#p_enemy{total_hurt=OldHurt+Hurt},
                              lists:keyreplace({ActorID,ActorType}, #p_enemy.actor_key, Acc, NewEnemy)
                      end
              end
      end,[],FirstEnemyList).
                            


write_boss_dead_log(MonsterInfo,SpecialData,DropThingList,RoleID,NowTime) ->
    case is_integer(SpecialData) of
        true->
            SpecialID = SpecialData;
        _ ->
            SpecialID = 0
    end,
    ItemList = lists:foldr(
            fun(DropInfo,Acc) ->
                #p_map_dropthing{goodstype=Type,goodstypeid=TypeID,num=Num,drop_property=Property} = DropInfo,
                Item = #r_log_boss_item_drop{item_type=Type, item_typeid=TypeID, num=Num},
                case Property of
                    undefined ->
                        Item2 = Item;
                    _ ->
                         Color = Property#p_drop_property.colour,
                        Quality = Property#p_drop_property.quality,
                        Item2 = Item#r_log_boss_item_drop{color=Color,quality=Quality}
                end,
                [Item2|Acc]
    end,[],DropThingList),
    BossLog = #r_log_boss_state{
                                boss_id = MonsterInfo#p_monster.monsterid,
                                boss_type = MonsterInfo#p_monster.typeid,
                                boss_name = MonsterInfo#p_monster.monstername,
                                map_id = MonsterInfo#p_monster.mapid,
                                special_id=SpecialID,
                                ext = SpecialData,
                                boss_state = ?DEAD_STATE,
                                mtime = NowTime,
                                drop_item = ItemList,
                                last_hurt_player = RoleID
                               },
    common_general_log_server:log_boss(BossLog).


monster_delete(MonsterID) ->
	monster_delete(MonsterID,false).
monster_delete(MonsterID,IsRoleFight) ->
    mod_map_actor:do_quit(MonsterID, monster, mgeem_map:get_state(),IsRoleFight),
    erlang:put(?monster_id_list,lists:delete(MonsterID,get_monster_id_list())),
    case get({monster_enemy,MonsterID}) of
        undefined ->
            nil;
        List2 ->
            erase({monster_enemy,MonsterID}),
            lists:foreach(fun(RoleID) -> erase({enemy_level,MonsterID,RoleID}) end,List2)
        end,
    erase({monster_state,MonsterID}).

%%判断是否在范围内
judge_in_distance(MonsterPos, ActorPos, Distance) ->
    case MonsterPos =:= undefined orelse ActorPos =:= undefined of
        false ->
            #p_pos{tx = Tx1, ty = Ty1} = MonsterPos,
            #p_pos{tx = Tx2, ty = Ty2} = ActorPos,
            X = abs(Tx1 - Tx2),
            Y = abs(Ty1 - Ty2),
            X =< Distance andalso Y =< Distance;
        true ->
            false
    end.

%%怪物行走
do_start_walk(MonsterPos,RolePos,MonsterID,Speed,State) ->
    #monster_state{monster_info=MonsterInfo} = State,
    #p_monster{typeid=TypeID} = MonsterInfo,
    
    case is_not_move_monster(TypeID) of
        true->
            set_next_work(MonsterID, 1000, loop, State);
        _ ->
            do_start_walk2(MonsterPos,RolePos,MonsterID,Speed,State)
    end.
    
do_start_walk2(MonsterPos,RolePos,MonsterID,Speed,State)->
    #monster_state{walk_path=WalkPath, monster_info=MonsterInfo, last_enemy_pos=LastEnemyPos} = State,
    #p_monster{typeid=TypeID} = MonsterInfo,
    [#p_monster_base_info{rarity=Rarity}] = cfg_monster:find(TypeID),
    if
        ?CHECK_RARITY_BOSS_AI( Rarity ) ->
            MonsterInfo = State#monster_state.monster_info,
            MonsterState = MonsterInfo#p_monster.state,
            case MonsterState of
                ?FIGHT_STATE ->
                    case RolePos =:= LastEnemyPos of
                        true ->
                            do_start_walk3(WalkPath,MonsterPos,RolePos,MonsterID,Speed,State,boss);
                        false ->
                            do_start_walk3([],MonsterPos,RolePos,MonsterID,Speed,State,boss)
                    end;
                 _ ->
                    do_start_walk3(WalkPath,MonsterPos,RolePos,MonsterID,Speed,State,normal)
            end;
        true ->
            do_start_walk3(WalkPath,MonsterPos,RolePos,MonsterID,Speed,State,normal)
    end.


do_start_walk3(WalkPath,MonsterPos,RolePos,MonsterID,Speed,MonsterState,boss) ->
    case WalkPath of
        [] ->
            mod_monster_walk:second_level_walk(MonsterPos, RolePos, MonsterID,Speed, MonsterState);
        [WalkPos|NewWalkPath] when is_list(NewWalkPath)->
            mod_monster_walk:walk_inpath(MonsterPos,WalkPos,NewWalkPath, MonsterID, Speed, RolePos, MonsterState)   
    end;
do_start_walk3(WalkPath,MonsterPos,RolePos,MonsterID,Speed,MonsterState,_) ->
    case WalkPath of
        [] ->
            mod_monster_walk:first_level_walk(MonsterPos, RolePos, MonsterID,Speed, MonsterState);
        [WalkPos|NewWalkPath] ->
            mod_monster_walk:walk_inpath(MonsterPos,WalkPos,NewWalkPath, MonsterID, Speed, RolePos, MonsterState)   
    end.


%%怪物返回出生点
return(State)->
    #monster_state{monster_info = MonsterInfo} = State,
    #p_monster{reborn_pos = BornPos, hp=Hp, monsterid = MonsterID, move_speed = MoveSpeed,typeid=MonsterType} = MonsterInfo,
    MonsterPos = mod_map_actor:get_actor_pos(MonsterID,monster),
    case judge_in_distance(MonsterPos,BornPos,1) of
        true ->
			case common_config_dyn:find(monster_etc,{monster_return_recover_hp,MonsterType}) of
				[] ->
					NewHp = Hp;
				[Percent] ->
					MaxHp = MonsterInfo#p_monster.max_hp,
					Hp2 = trunc(MaxHp * Percent / 10000),
					case Hp2 > Hp of
						true ->
							monster_attr_change(MonsterID,?BLOOD,MaxHp),
							NewHp = Hp2;
						false ->
							NewHp = Hp
					end
			end,
            NewMonsterInfo = MonsterInfo#p_monster{
                                                   hp = NewHp, 
                                                   state = ?GUARD_STATE,
                                                   first_enemies = [],
                                                   second_enemies = [],
                                                   third_enemies = []},
            erase_monster_enemy(MonsterID),
            NewState = State#monster_state{monster_info = NewMonsterInfo,last_attack_time = undefined},
            set_next_work(MonsterID,0,loop,NewState);
        false ->
            do_start_walk(MonsterPos,BornPos,MonsterID,MoveSpeed,State)
    end.


%%怪物返回出生点
return_born_pos(BornPos,MonsterPos,MonsterInfo,State) ->
    #p_monster{typeid = MonsterTypeID,
               monsterid = MonsterID,
               move_speed = MoveSpeed} = MonsterInfo,
    NewMonsterInfo = MonsterInfo#p_monster{state = ?RETURN_STATE},
    do_start_walk(MonsterPos,BornPos,MonsterID,MoveSpeed,State#monster_state{monster_info = NewMonsterInfo}),
    %%BOSS在返回出生点的时候，可以自动满血
    case cfg_monster:find(MonsterTypeID) of
        [#p_monster_base_info{rarity=?BOSS}]->
            case mod_warofmonster:is_in_fb_map() orelse mod_guard_fb:is_in_fb_map() of
                true-> ignore;
                _ ->
                    do_monster_recover_max(MonsterID)
            end;
        _ ->
            ignore
    end.


%%根据怪物以及仇恨列表算各个玩家分到的经验
add_exp(_KillerId,FirstEnemyList,MonsterType,MonsterID,MapID,TotalExpArg, Level, Rarity) ->
    TotalExp = hook_activity_map:hook_monster_dead_exp(MonsterType, TotalExpArg),
    case mod_map_actor:get_actor_pos(MonsterID,monster) of
        undefined ->
            nil;
        MonsterPos ->
            #p_pos{tx = Tx, ty = Ty} = MonsterPos,
            {HurtList,AllHurt} =
                lists:foldl(
                  fun(Enemy,{Acc,AccHurt})->
                          case Enemy of
                              #p_enemy{actor_key = {RoleID,role},total_hurt = TotalHurt}->
                                  {[{RoleID,TotalHurt}|Acc],TotalHurt + AccHurt};
                              _ -> {Acc,AccHurt}
                          end
                  end, {[],0}, FirstEnemyList),
            case AllHurt > 0 of
                true ->
                    {RoleExpList, {MostHurtRoleID, _}} = 
                        lists:foldr(
                          fun({RoleID, Hurt}, {Acc, {MostHurtID, H}}) ->
                                  Exp = TotalExp*(Hurt/AllHurt)*mod_normal_skill:get_hook_skill_effect_value(RoleID),
                                  EnergyIndex = get_role_energy_index(RoleID),
                                  Exp1 = get_kill_monster_buff_add_exp(RoleID, Exp),
                                  RoleExp = #r_monster_role_exp{role_id=RoleID, exp=common_tool:ceil(Exp1*EnergyIndex), energy_index=EnergyIndex},
                                  %% 如果玩家因精力值惩罚无法获得经验，则把经验直接加到异兽上
                                  case EnergyIndex < 1 of
                                      true ->
                                          PetExp = mod_team_exp:get_vip_exp(RoleID, Exp),
                                          PetExp2 = mod_team_exp:get_multi_exp(RoleID, PetExp, ?EXP_BUFF_TYPE),
                                          PetExp3 = mod_team_exp:get_exp_after_punish(RoleID, MonsterType, Level, Rarity, PetExp2),
										  case mod_map_pet:get_pet_exp(RoleID,PetExp3) of
											  undefined ->
												  ignore;
											  PetExp4 ->
												  mod_map_pet:add_pet_exp(RoleID, common_tool:ceil(PetExp4),true)
										  end;
                                      _ ->
                                          ignore
                                  end,
                                  case Hurt > H of
                                      true ->
                                          {[RoleExp|Acc], {RoleID, Hurt}};
                                      _ ->
                                          {[RoleExp|Acc], {MostHurtID, H}}
                                  end
                          end, {[], {0, 0}}, HurtList),
                    MonsterExp = #r_monster_exp{killer_id=MostHurtRoleID,map_id = MapID,
                                                monster_id = MonsterID,monster_type = MonsterType,
                                                monster_tx = Tx,monster_ty = Ty,role_exp_list = RoleExpList,
                                                monster_level=Level, monster_rarity=Rarity},
                    mod_team_exp:handle({add_exp, [MonsterExp]});
                false ->
                    nil
            end
    end.

get_kill_monster_buff_add_exp(RoleID, Exp) ->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    Fun = fun(ActorBuff, Acc) ->
        BuffId      = ActorBuff#p_actor_buf.buff_id,
        [BufDetail] = common_config_dyn:find(buffs, BuffId),
        case BufDetail#p_buf.buff_type of
            ?BUFF_TYPE_KILL_MONSTER_EXP ->
                Acc + BufDetail#p_buf.value;
            _ ->
                Acc
        end
    end,
    AddArg = lists:foldl(Fun, 0, RoleBase#p_role_base.buffs),
    Exp * (1 + AddArg/10000).


%%获取召唤怪物的位置，可能是配置为固定位置
get_summon_monster_pos(MonsterTypeID,MonsterPos)->
	case common_config_dyn:find(monster_etc, summon_monster_pos) of
		[MonsterPosList]->
			case lists:keyfind(MonsterTypeID, 1, MonsterPosList) of
				{_,Tx,Ty}->
					next;
				_ ->
					#p_pos{tx = Tx, ty = Ty} = MonsterPos
  			end;
		_ ->
			#p_pos{tx = Tx, ty = Ty} = MonsterPos
	end,
	{Tx,Ty}.

%%@doc 召唤BOSS
summon_monster(undefined,_,_,State) ->
    State;
summon_monster({MonsterTypeID,Num,LiveTime},MonsterInfo,MonsterPos,State) ->
	{Tx,Ty} = get_summon_monster_pos(MonsterTypeID,MonsterPos),
	
    erlang:send_after(1000, self(),{mod_map_monster,{dynamic_summon_monster, MonsterTypeID, Num, Tx, Ty, LiveTime}}),
     MonsterID = MonsterInfo#p_monster.monsterid,
%%     DataRecord = #m_monster_summon_toc{monster_id = MonsterID},
%%     MapState = mgeem_map:get_state(),
%%     mgeem_map:do_broadcast_insence_include([{monster,MonsterID}], ?MONSTER, ?MONSTER_SUMMON, DataRecord, MapState),
    set_next_work(MonsterID,?MIN_MONSTER_WORK_TICK,loop,State).

%% @doc 获取等级惩罚系数
get_role_level_index(RoleID, MonsterTypeID, MonsterLevel, MonsterRarity) ->
    %% 特殊的怪物不受等级惩罚
    [SpecMonsterList] = common_config_dyn:find(etc, spec_monster_list),
    case lists:member(MonsterTypeID, SpecMonsterList) of
        true ->
            1;
        _ ->
            case mod_map_role:get_role_attr(RoleID) of
                {ok, RoleAttr} ->
                    RoleLevel = RoleAttr#p_role_attr.level,
                    LevelDiff = RoleLevel - MonsterLevel,
                    if
                        MonsterRarity =:= ?BOSS andalso LevelDiff < 25 ->
                            1;
                        MonsterRarity =:= ?BOSS andalso LevelDiff < 50 ->
                            0.5;
                        MonsterRarity =:= ?BOSS ->
                            0.00001;
                        LevelDiff < -11 ->
                            0.2;
                        LevelDiff < 200 ->
                            1;
                        true ->
                            0.00001
                    end;
                _ ->
                    1
            end
    end.

write_monster_persistent_info(MonsterState) ->
    #monster_state{monster_info=MonsterInfo, create_type=CreateType, special_data=Key} = MonsterState,
    case CreateType of
        ?MONSTER_CREATE_TYPE_MANUAL_CALL when is_integer(Key)->
            #p_monster{monsterid=MonsterID,typeid=TypeID,hp=HP,mp=MP,state=State} = MonsterInfo,
            Persistent=#r_monster_persistent_info{typeid=TypeID, key=Key, monsterid=MonsterID, state=State, hp=HP, mp=MP},
            db:dirty_write(?DB_MONSTER_PERSISTENT_INFO,Persistent);
        _ ->
            nil
    end.


judge_monster_in_map(MonsterID) ->
    lists:member(MonsterID,get_monster_id_list()).

-define(NO_DECREASE_ROLE_ENERGY_MONSTER_LIST,[10501103,10501104,10501105,10501106]).
%%一些怪物不扣精力值
decrease_role_energy(RoleID,MonsterTypeID) ->
    case lists:member(MonsterTypeID, ?NO_DECREASE_ROLE_ENERGY_MONSTER_LIST) of
        false ->
            decrease_role_energy_2(RoleID);
        _ ->
            ignore
    end.

decrease_role_energy_2(RoleID) ->
    {ok, RoleFight} = mod_map_role:get_role_fight(RoleID),
    Energy = RoleFight#p_role_fight.energy,
    
    case Energy - 1 >= 0 of
        true ->
            Energy2 = Energy -1;
        _ ->
            Energy2 = 0
    end,
    
    RoleFight2 = RoleFight#p_role_fight{energy=Energy2},
    mod_map_role:set_role_fight(RoleID, RoleFight2),
    case Energy2 =:= Energy of
        true ->
            ok;
        _ -> 
            AttrChange = #p_role_attr_change{change_type=10, new_value=Energy2},
            DataRecord = #m_role2_attr_change_toc{roleid=RoleID, changes=[AttrChange]},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, DataRecord)
    end.

get_role_energy_index(RoleID) ->
	case mod_map_role:get_role_fight(RoleID) of
		{error, not_found} ->
			0.00001;
		{ok, RoleFight} ->
			Energy = RoleFight#p_role_fight.energy,
			case Energy =:= 0 of
				true ->
					0.00001;
				_ ->
					1
			end
	end.

do_monster_recover_max(MonsterID) ->
    case mod_map_actor:get_actor_mapinfo(MonsterID, monster) of
        undefined ->
            ignore;
        MonsterMapInfo ->
            case get_monster_state(MonsterID) of
                undefined ->
                    ignore;
                MonsterState ->
                    #p_map_monster{hp=HP, mp=MP, max_hp=MaxHP, max_mp=MaxMP} = MonsterMapInfo,
                    #monster_state{monster_info=MonsterInfo} = MonsterState,

                    case HP =:= MaxHP andalso MP =:= MaxMP of
                        true ->
                            ignore;
                        _ ->
                            MonsterMapInfo2 = MonsterMapInfo#p_map_monster{hp=MaxHP, mp=MaxMP},
                            MonsterInfo2 = MonsterInfo#p_monster{hp=MaxHP, mp=MaxMP},
                            MonsterState2 = MonsterState#monster_state{monster_info=MonsterInfo2},
                            
                            set_monster_state(MonsterID, MonsterState2),
                            mod_map_actor:set_actor_mapinfo(MonsterID, monster, MonsterMapInfo2)
                    end
            end
    end.

do_monster_recover(MonsterID) ->
    case mod_map_actor:get_actor_mapinfo(MonsterID, monster) of
        undefined ->
            ignore;
        MonsterMapInfo ->
            case get_monster_state(MonsterID) of
                undefined ->
                    ignore;
                MonsterState ->
                    #p_map_monster{hp=HP, mp=MP, max_hp=MaxHP, max_mp=MaxMP} = MonsterMapInfo,
                    #monster_state{monster_info=MonsterInfo} = MonsterState,
                    #p_monster{typeid=TypeID} = MonsterInfo,
                    [MonsterBaseInfo] = cfg_monster:find(TypeID),
                    #p_monster_base_info{blood_resume_speed=HPRecover, magic_resume_speed=MPRecover} = MonsterBaseInfo,

                    case HP =:= MaxHP andalso MP =:= MaxMP of
                        true ->
                            ignore;
                        _ ->
                            HPRecover2 = get_hp_recover(HP, MaxHP, HPRecover),
                            case HP + HPRecover2 >= MaxHP of
                                true ->
                                    HP2 = MaxHP;
                                _ ->
                                    HP2 = HP + HPRecover2
                            end,
                            
                            case MP + MPRecover >= MaxMP of
                                true ->
                                    MP2 = MaxMP;
                                _ ->
                                    MP2 = MP + MPRecover
                            end,
                            MonsterMapInfo2 = MonsterMapInfo#p_map_monster{hp=HP2, mp=MP2},
                            MonsterInfo2 = MonsterInfo#p_monster{hp=HP2, mp=MP2},
                            MonsterState2 = MonsterState#monster_state{monster_info=MonsterInfo2},
                            
                            set_monster_state(MonsterID, MonsterState2),
                            mod_map_actor:set_actor_mapinfo(MonsterID, monster, MonsterMapInfo2)
                    end
            end
    end.

%% @doc 获取回血量
get_hp_recover(HP, MaxHP, HPRecover) ->
    HPRate = (HP/MaxHP) * 100,
    
    if
        HPRate < 40 ->
            HPRecover;
        HPRate < 70 ->
            common_tool:ceil(HPRecover*2/3);
        true ->
            common_tool:ceil(HPRecover*1/3)
    end.

%% @doc 怪物出生HOOK
hook_monster_born(MonsterInfo, MonsterBaseInfo) ->
    #p_monster{monsterid=MonsterID, typeid=TypeID, state=MonsterState} = MonsterInfo,
    #p_monster_base_info{rarity=Rarity, monstername=MonsterName} = MonsterBaseInfo,
    %% 怪物加成
    catch mod_monster_addition:hook_monster_born(MonsterID, TypeID), 
    %% 怪物出生广播，普通怪，怪物第一次出生不广播
    case  Rarity =:= ?NORMAL orelse MonsterState =:= ?FIRST_BORN_STATE of
        true ->
            ignore;
        _ ->
            case common_config_dyn:find(monster_born_and_dead_broadcast, TypeID) of
                [] ->
                    ignore;
                [BroadcastInfo] ->
                    #map_state{mapid=MapID} = mgeem_map:get_state(),
                    MapName = common_map:get_map_str_name(MapID),
                    #r_monster_born_and_dead_broadcast{born_broadcast=BornBroadcast, broadcast_channel=Channel} = BroadcastInfo,
                    Msg = get_broadcast_msg(BornBroadcast, MonsterName, MapName, ""),
                    monster_born_and_dead_broadcast(MapID, Channel, lists:flatten(Msg))
            end
    end.

%% @doc 怪物死亡hook
hook_monster_dead({KillActorID,server_npc},DropOwner, MonsterInfo, MonsterBaseInfo) ->
    hook_map_monster:monster_dead(server_npc,KillActorID,DropOwner, MonsterInfo, MonsterBaseInfo);
hook_monster_dead({KillRoleID,role}, DropOwner, MonsterInfo, MonsterBaseInfo) ->
    #p_monster{monsterid=MonsterID, typeid=TypeID} = MonsterInfo,
    #p_monster_base_info{rarity=Rarity, monstername=MonsterName} = MonsterBaseInfo,
    born_condition_hook_monster_dead(MonsterID, TypeID),
    hook_map_monster:monster_dead(role,KillRoleID, DropOwner,MonsterInfo, MonsterBaseInfo),

    %% 怪物出生广播，普通怪，怪物第一次出生不广播
    case Rarity =:= ?NORMAL of
        true ->
            ignore;
        _ ->
            case common_config_dyn:find(monster_born_and_dead_broadcast, TypeID) of
                [] ->
                    ignore;
                [BroadcastInfo] ->
                    #map_state{mapid=MapID} = mgeem_map:get_state(),
                    MapName = common_map:get_map_str_name(MapID),
                    {ok, RoleBase} = mod_map_role:get_role_base(KillRoleID),
                    #r_monster_born_and_dead_broadcast{dead_broadcast=DeadBroadcast, broadcast_channel=Channel} = BroadcastInfo,
                    Msg = get_broadcast_msg(DeadBroadcast, MonsterName, MapName, RoleBase#p_role_base.role_name),
                    monster_born_and_dead_broadcast(MapID, Channel, lists:flatten(Msg))
            end
    end. 

monster_born_and_dead_broadcast(MapID, Channel, Msg) ->
    case Channel of
        ?BROADCAST_CHANNEL_WORLD ->
            common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER], ?BC_MSG_TYPE_CHAT_WORLD, Msg);
        _ ->
            case mod_map_role:get_map_faction_id(MapID) of
                {ok, copy_or_neutral} ->
                    ignore;
                {ok, FactionID} ->
                    common_broadcast:bc_send_msg_faction(FactionID, [?BC_MSG_TYPE_CENTER], ?BC_MSG_TYPE_CHAT_WORLD, Msg)
            end,
            ok
    end.


get_enemy_pos(ActorID,ActorType) when (ActorType==role) orelse (ActorType==server_npc) ->
    mod_map_actor:get_actor_pos(ActorID,ActorType);
get_enemy_pos(PetID,pet) ->
    case mod_map_actor:get_actor_mapinfo(PetID,pet) of
        undefined ->
            undefined;
        #p_map_pet{role_id=RoleID} ->
            mod_map_pet:get_pet_pos_from_owner(RoleID)
    end.

get_broadcast_msg(Msg, MonsterName, MapName, KillerName) ->
    Msg2 = re:replace(Msg, "monster", MonsterName, [{return,list}]),
    Msg3 = re:replace(Msg2, "map", MapName, [{return,list}]),
    re:replace(Msg3, "role", KillerName, [{return,list}]).


log_drop_thing(DropThingList,MapID)->
    case is_list(DropThingList) of
        true->
            case get_map_fb_code(MapID)  of 
                {ok,FbCode}->
                    lists:foreach(
                      fun(MapDropthing)->
                              case check_item_need_log(MapDropthing) of
                                  true->
                                      DropThingLog =
                                          #r_fb_drop_thing_log{
                                                               type_id=MapDropthing#p_map_dropthing.goodstypeid,
                                                               map_id = MapID,
                                                               drop_time=common_tool:now(),
                                                               fb_type=FbCode
                                                              },
                                      common_general_log_server:log_fb_drop_thing(DropThingLog);
                                  false->ignore                                                     
                              end
                      end,DropThingList);                            
                _->ignore
            end;
        false->ignore
    end.

get_map_fb_code(MapID)->
    case common_config_dyn:find(fb_map,MapID) of
        [#r_fb_map{fb_code=FbCode}] when FbCode>0->
            {ok,FbCode};
        _ ->
            false
    end.

check_item_need_log(MapDropthing)->
    if 
        (MapDropthing#p_map_dropthing.goodstypeid>=10200001 
                                          andalso MapDropthing#p_map_dropthing.goodstypeid=<10200008)->
            false;
        (MapDropthing#p_map_dropthing.goodstype>3) ->
            false;
        (MapDropthing#p_map_dropthing.goodstype=:=3 andalso MapDropthing#p_map_dropthing.colour=:=1) ->
            false;
        true->true
    end.
            
%% @doc 删除本地图所有怪物
delete_all_monster() ->
    lists:foreach(
      fun(MonsterID) ->
              monster_delete(MonsterID)
      end, get_monster_id_list()).

%% @doc 获取怪物的出生条件
get_monster_born_condition(MonsterTypeID) ->
    case common_config_dyn:find(monster_born_condition, {born_condition, MonsterTypeID}) of
        [] ->
            [];
        [L] ->
            L
    end.

%% @doc 获取怪物被哪些怪物作为出生条件
get_monster_be_born_condition(MonsterTypeID) ->
    case common_config_dyn:find(monster_born_condition, {be_condition, MonsterTypeID}) of
        [] ->
            [];
        [L] ->
            L
    end.

%% @doc 初始化怪物出生条件
init_monster_born_condition(MonsterTypeID) ->
    case get_monster_born_condition(MonsterTypeID) of
        [] ->
            ignore;
        L ->
            set_monster_born_condition(MonsterTypeID, L)
    end.

%% @doc 设置怪物的出生条件
set_monster_born_condition(MonsterTypeID, ConditionList) ->
    erlang:put({?MONSTER_BORN_CONDITION, MonsterTypeID}, ConditionList).

%% @doc 获取怪物出生条件
get_monster_born_condition_current(MonsterTypeID) ->
    erlang:get({?MONSTER_BORN_CONDITION, MonsterTypeID}).

%% @doc 怪物死亡hook
born_condition_hook_monster_dead(_DeadMonsterID, DeadMonsterTypeID) ->
    case get_monster_be_born_condition(DeadMonsterTypeID) of
        [] ->
            ignore;
        MonsterTypeIDList ->
            lists:foreach(
              fun(MonsterTypeID) ->
                      born_condition_hook_monster_dead2(MonsterTypeID, DeadMonsterTypeID)
              end, MonsterTypeIDList)
    end.

born_condition_hook_monster_dead2(MonsterTypeID, DeadMonsterTypeID) ->
    case get_monster_born_condition_current(MonsterTypeID) of
        undefined ->
            ignore;
        [] ->
            ignore;
        ConditionList ->
            case lists:foldl(
                   fun({TypeID, Num}, CL) ->
                           case TypeID =:= DeadMonsterTypeID of
                               true when Num =:= 1 ->
                                   CL;
                               true ->
                                   [{TypeID, Num-1}|CL];
                               _ ->
                                   [{TypeID, Num}|CL]
                           end
                   end, [], ConditionList) 
            of
                [] ->
                    #map_state{mapid=MapID, map_name=MapProcessName} = mgeem_map:get_state(),
					{_, TX, TY} = lists:keyfind(MonsterTypeID, 1, mcm:monster_tiles(MapID)),
                    MonsterInfo = #p_monster{
                      reborn_pos=#p_pos{tx=TX, ty=TY, dir=1},
                      monsterid=get_max_monster_id_form_process_dict(),
                      typeid=MonsterTypeID, 
                      mapid = MapID},
                    init([MonsterInfo, ?MONSTER_CREATE_TYPE_MANUAL_CALL, MapID, MapProcessName, undefined, ?FIRST_BORN_STATE, null]),
                    init_monster_born_condition(MonsterTypeID);
                ConditionList2 ->
                    set_monster_born_condition(MonsterTypeID, ConditionList2)
            end
    end.


set_boss_group_id_list(Key,List)->
    erlang:put({boss_group,Key},List).

get_boss_group_id_list(Key)->
    case erlang:get({boss_group,Key}) of
        undefined->[];
        L->L
    end.

%%@doc 判断是否为不移动的怪物
is_not_move_monster(TypeID)->
    case common_config_dyn:find(monster_etc, monster_not_move) of
        [MonsterList]->
            lists:member(TypeID, MonsterList);
        _ ->
            false
    end.

%% 在玩家附近召唤怪物
call_monster_around_role(RoleID,MonsterTypeID,LiveTime) ->
	#map_state{mapid=MapID, map_name=MapProcessName} = mgeem_map:get_state(),
	{ok, #p_pos{tx=TX, ty=TY}} = mod_map_role:get_role_pos(RoleID),
	MonsterList=[#p_monster{reborn_pos=#p_pos{tx=TX+common_tool:random(-2,2),ty=TY+common_tool:random(-2,2)},
							  monsterid=mod_map_monster:get_max_monster_id_form_process_dict(),
							  typeid=MonsterTypeID,mapid=MapID}],
	mod_map_monster:init_call_fb_monster(MapProcessName,MapID,MonsterList,LiveTime).
