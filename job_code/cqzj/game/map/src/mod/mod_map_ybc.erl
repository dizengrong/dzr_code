%% Author: xianorngMai
%% Created: 2010-8-13
%% Description: 运镖车

-module(mod_map_ybc).

-include("mgeem.hrl").

-export([
         handle/2,
         init/2,
         loop/0,
         loop_ms/1,         
         terminate/0,
         ybc_change_map/5,
         del_ybc/1,
         reduce_hp/4,
         update_ybc_info/2,
         addto_ybc_list/1,
         init_enter/2,
         reborn/2,
         get_ybc_full_info/1,
         notify_role_ybc_pos/1,
         t_do_create_ybc/1,
         do_enter/1,
         do_del_ybc/1,
         get_new_ybc_info/2,
         get_person_ybc_id/1,
         reset_ybc_pos/4,
         do_timeout_ybc/1%%43992服出现了大量镖车堵塞 开放此接口以删除镖车
        ]).

-export([
         test_create/2,
         test_del/2,
         test_walk/3,
         test_change_map/4
        ]).

-define(ybc_id_list, ybc_id_list).

-define(ybc_walk_queue, ybc_walk_queue).


%%------------------------------------------------------------------------------------------
test_change_map(MapID, TMapID, Pos, YbcID) ->
    global:send(common_map:get_common_map_name(MapID), {?MODULE, {test_change_map, TMapID, Pos, YbcID}}),
    ok.

test_create(MapID, RoleID) ->
    {ok, #p_role_base{role_name=RoleName}} = mod_map_role:get_role_base(RoleID),
    {ok, #p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
    YbcCreateInfo = #p_ybc_create_info{role_list=[{RoleID, RoleName, Level, 0, 50000}], max_hp=1000,
                                       move_speed=100, name= <<"test">>,
                                       create_type=1, creator_id=RoleID, group_type=1,
                                       group_id=0, color=1, create_time=common_tool:now(),
                                       end_time=common_tool:now() + 86400,
                                       can_attack=true, buffs=[],
                                       recover_speed=100, magic_defence=100,
                                       physical_defence=100},
    global:send(common_map:get_common_map_name(MapID), {?MODULE, {create_ybc, YbcCreateInfo}}).


test_del(MapID, YbcID) ->
    global:send(common_map:get_common_map_name(MapID), {?MODULE, {del_ybc, YbcID}}).

test_walk(MapID, YbcID, {TX, TY}) ->
    global:send(common_map:get_common_map_name(MapID), {?MODULE, {test_walk, YbcID, {TX, TY}}}).

reborn(MapName, YbcID) ->
    global:send(MapName, {?MODULE, {reborn, YbcID}}).
%%------------------------------------------------------------------------------------------

init(MapID, _MapName) ->
    YbcList = get_ybc_list_from_db(MapID),
    YbcIDList = lists:foldl(
                  fun(#r_ybc{ybc_id=YbcID}, Acc) ->
                          [YbcID | Acc]
                  end, [], YbcList),
    %% 初始化镖车列表
    init_ybc_list(YbcIDList),
    %% 初始化镖车所在slice和位置信息
    init_ybc_slice(YbcList),
    lists:foreach(
      fun(YbcID) ->
              %% 初始化镖车走路信息
              init_ybc_walk_info(YbcID)
      end, YbcIDList),
    %% 初始化镖车走路队列信息
    ok.

notify_role_ybc_pos(RoleID) ->
    case db:dirty_read(?DB_ROLE_STATE, RoleID) of
        [RoleState]->
            notify_role_ybc_pos_2(RoleID,RoleState);
        _ ->
            ignore
    end.
    
notify_role_ybc_pos_2(RoleID,RoleState)->    
    YbcState = RoleState#r_role_state.ybc,
    Key = 
    case YbcState of
        1 ->
            {0, 1, RoleID};
        3 ->
            {0, 1, RoleID};
        4 ->
            {0, 1, RoleID};
        ?ROLE_STATE_YBC_FAMILY ->
            {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
            {RoleBase#p_role_base.family_id, 2, RoleID};
        _ ->
            ignore
    end,
    if
        Key =:= ignore ->
            ignore;
        true ->
            case db:dirty_read(?DB_YBC_UNIQUE, Key) of
                [] ->
                    ignore;
                [UniqueData] ->
                    YbcID = UniqueData#r_ybc_unique.id,
                    case mod_map_actor:get_actor_txty_by_id(YbcID, ybc) of
                        undefined ->
                            [YbcInfo] = db:dirty_read(?DB_YBC, YbcID),
                            #p_pos{tx=TX, ty=TY} = YbcInfo#r_ybc.pos,
                            MapID = YbcInfo#r_ybc.map_id;
                        {TX, TY} ->
                            MapID = mgeem_map:get_mapid()
                    end,
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?YBC, ?YBC_NOTIFY_POS, #m_ybc_notify_pos_toc{tx=TX, ty=TY, map_id=MapID})
            end
    end.

handle(Info, _State) ->
    do_handle(Info).

do_handle({create_ybc, YbcInfo}) ->
    create_ybc(YbcInfo);
do_handle({create_ybc, YbcInfo, From}) ->
    create_ybc_reply(YbcInfo, From);
do_handle({test_walk, YbcID, {TX, TY}}) ->
    do_test_walk(YbcID, TX, TY);
do_handle({test_change_map, MapID, Pos, YbcID}) ->
    do_test_change_map(MapID, Pos, YbcID);

%%换地图必须改变镖车的地图ID
%%TODO 可能还有其他进程字典数据要清理?
do_handle({del_ybc, YbcID}) ->
    do_del_ybc(YbcID);

do_handle({update_ybc_map_info, YbcID, YbcInfo}) ->
    do_update_ybc_map_info(YbcID, YbcInfo);

%%增加buff
do_handle({add_buff, SrcActorID, SrcActorType, AddBuffs, YbcID}) ->
    do_add_buff(SrcActorID, SrcActorType, AddBuffs, YbcID);
%%删除buff
do_handle({remove_buff, SrcActorID, SrcActorType, RemoveList, YbcID}) ->
    do_remove_buff(SrcActorID, SrcActorType, RemoveList, YbcID);

do_handle({reborn, YbcID}) ->
    do_reborn(YbcID);

do_handle(Info) ->
    ?ERROR_MSG("~ts:~w", ["未知的镖车消息", Info]).

do_remove_buff(SrcActorID, SrcActorType, RemoveList, YbcID)->
    YbcMapInfo = mod_map_actor:get_actor_mapinfo(YbcID, ybc),
    case YbcMapInfo of
        undefined ->
            ignore;
        _ ->
            NewYbcMapInfo = mod_ybc_buff:remove_buff(SrcActorID, SrcActorType, RemoveList, YbcID, YbcMapInfo),
            mod_map_actor:set_actor_mapinfo(YbcID, ybc, NewYbcMapInfo),
            %%目前只实现更新速度的buff
            #p_map_ybc{ybc_id=YbcID,move_speed=MoveSpeed} = NewYbcMapInfo,
            broadcast_ybc_speed(SrcActorID,YbcID,MoveSpeed)
    
    end.

do_add_buff(SrcActorID, SrcActorType, AddBuffs, YbcID)->
    YbcMapInfo = mod_map_actor:get_actor_mapinfo(YbcID, ybc),
    case YbcMapInfo of
        undefined ->
            ignore;
        _ ->
            NewYbcMapInfo = mod_ybc_buff:add_buff(SrcActorID, SrcActorType, AddBuffs, YbcID, YbcMapInfo),
            mod_map_actor:set_actor_mapinfo(YbcID, ybc, NewYbcMapInfo),
            %%目前只实现更新速度的buff
            #p_map_ybc{ybc_id=YbcID,move_speed=MoveSpeed} = NewYbcMapInfo,
            broadcast_ybc_speed(SrcActorID,YbcID,MoveSpeed)
    
    end.


%%广播镖车的移动速度
broadcast_ybc_speed(RoleID,YbcID,MoveSpeed)->
    State = mgeem_map:get_state(),
    RecordData = #m_ybc_speed_toc{ybc_id=YbcID,move_speed=MoveSpeed},
    mgeem_map:do_broadcast_insence_include([{role,RoleID}], ?YBC, ?YBC_SPEED, RecordData, State).


%% 伤害HP
reduce_hp(ActorID, Reduce, SrcActorID, pet) ->
    case mod_map_actor:get_actor_mapinfo(SrcActorID, pet) of
        undefined ->
            ignore;
        PetMapInfo ->
            RoleID = PetMapInfo#p_map_pet.role_id,
            reduce_hp(ActorID, Reduce, RoleID, role) 
    end;
reduce_hp(ActorID, Reduce, SrcActorID, role) ->
    YbcMapInfo = mod_map_actor:get_actor_mapinfo(ActorID, ybc),
    case YbcMapInfo of
        undefined ->
            ignore;
        _ ->
            HP = YbcMapInfo#p_map_ybc.hp,
            CreatorID = YbcMapInfo#p_map_ybc.creator_id,
            {ok, AttackorRoleBase} = mod_map_role:get_role_base(SrcActorID),
            AttackorFactionID = AttackorRoleBase#p_role_base.faction_id,
                        case HP > Reduce of
                true ->
                    YbcFactionID = YbcMapInfo#p_map_ybc.faction_id,
                    if
                        YbcFactionID =:= AttackorFactionID ->
                            set_gray_name(SrcActorID);
                        true ->
                            ignore
                    end,
                    catch common_broadcast:bc_send_msg_role(CreatorID,?BC_MSG_TYPE_CENTER, 
                                                       ?_LANG_YBC_BE_ATTACKING),
					%%个人镖车第一次受到攻击时，向宗族成员发求救信息
					GroupType = YbcMapInfo#p_map_ybc.group_type,
					Pos = YbcMapInfo#p_map_ybc.pos,
					YbcID = YbcMapInfo#p_map_ybc.ybc_id,
					catch send_sos_to_family(CreatorID,GroupType,Pos,YbcID),
                    NewYbcMapInfo = YbcMapInfo#p_map_ybc{hp=HP-Reduce},
                    mod_map_actor:set_actor_mapinfo(ActorID, ybc, NewYbcMapInfo);
                false ->
                    case YbcMapInfo#p_map_ybc.color of
                        5 ->
                            {ok,#p_role_base{role_name=CreatorName}} = mod_map_role:get_role_base(CreatorID),
                            {ok,#p_role_base{role_name=SrcActorName}} = mod_map_role:get_role_base(SrcActorID),
                            BroadcastMsg = common_misc:format_lang(?_LANG_YBC_YELLOW_DEAD,[SrcActorName,CreatorName]),
                            catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT_WORLD, BroadcastMsg),
                            catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD, BroadcastMsg);
                        _ ->
                            catch common_broadcast:bc_send_msg_role(CreatorID,?BC_MSG_TYPE_CENTER, 
                                                               ?_LANG_YBC_DEAD)
                    end,
                    do_ybc_dead(ActorID, YbcMapInfo, SrcActorID)
            end
    end;
reduce_hp(_ActorID, _Reduce, _SrcActorID, _) ->
    ignore.

do_update_ybc_map_info(YbcID, YbcInfo) ->
    set_ybc_full_info(YbcID, YbcInfo).    
    
update_ybc_info(ID, YbcMapInfo) ->
    mgeem_persistent:ybc_persistent(ID, YbcMapInfo).


get_role_ybc_id(RoleID) ->
    erlang:get({role_ybc_id, RoleID}).
set_role_ybc_id(RoleID, YbcID) ->
    erlang:put({role_ybc_id, RoleID}, YbcID).


do_test_change_map(MapID, Pos, YbcID) ->
    ybc_change_map3(YbcID, mod_map_actor:get_actor_mapinfo(YbcID, ybc), common_map:get_common_map_name(MapID), MapID, Pos),
    ok.
reset_ybc_pos(YbcID, NewPos, NewMapPName, NewMapID) ->
    case mod_map_actor:get_actor_mapinfo(YbcID, ybc) of
        undefined ->
            ignore;
        YbcMapInfo ->
            #p_pos{tx=TX, ty=TY} = NewPos,
            %% 编辑地图的时候要保证跳转点周围的所有点都是可走的
            Pos = NewPos#p_pos{tx=TX, ty=TY},
            NewYbcMapInfo = YbcMapInfo#p_map_ybc{pos=Pos},
            BuffTimerList = mod_ybc_buff:clear_buff_timer_list(YbcID),
            delfrom_ybc_list(YbcID),
            clear_ybc_full_info(YbcID),
            %% 退出旧地图
            mod_map_actor:do_quit(YbcID, ybc, mgeem_map:get_state()),
            mgeem_persistent:ybc_persistent(YbcID, NewMapID, NewYbcMapInfo),
            %% 通知进入新地图
            NewYbcMapExt = #r_map_ybc_ext{buff_timer_list=BuffTimerList},
            catch global:send(NewMapPName, {mod_map_actor, {ybc_enter, YbcID, NewYbcMapInfo,NewYbcMapExt}}),
            ok
    end.

ybc_change_map(ChangeMapType, RoleID, NewMapPName, NewMapID, NewPos) ->
    case ChangeMapType of
        ?CHANGE_MAP_TYPE_NORMAL ->
            %% 只有正常的跨地图镖车才会跟过去 
            case get_role_ybc_id(RoleID) of
                undefined ->
                    ignore;
                YbcID ->
                    case mod_map_actor:get_actor_mapinfo(YbcID, ybc) of
                        undefined ->
                            ignore;
                        YbcMapInfo ->
                            ybc_change_map2(RoleID, YbcID, YbcMapInfo, NewMapPName, NewMapID, NewPos)
                    end
            end;
        _ ->
            ignore
    end,
    ignore.

ybc_change_map2(RoleID, YbcID, YbcMapInfo, NewMapProcessName, NewMapID, NewPos) ->
	#p_pos{tx = RoleTX, ty = RoleTY} = mod_map_actor:get_actor_pos(RoleID, role),
	#p_pos{tx = TX, ty = TY} = YbcMapInfo#p_map_ybc.pos,
	OldMapID = mgeem_map:get_mapid(),
	%% 角色通过跳转点跳转时 镖车要达到一定距离才能跟着切换
	case YbcMapInfo#p_map_ybc.group_type of
		2 ->
			case (NewMapID =:= 10250 andalso OldMapID =:= 10260) orelse
					 			(NewMapID =:= 10251 andalso OldMapID =:= 10250)
						of
				true ->
					case erlang:abs(RoleTX - TX) =< (?YBC_CHANGE_MAP_DISTANCE * 2) andalso erlang:abs(RoleTY - TY) =< (?YBC_CHANGE_MAP_DISTANCE * 2) of
						true ->
							ybc_change_map3(YbcID, YbcMapInfo, NewMapProcessName, NewMapID, NewPos);
						false ->
							ignore
					end;
				false ->
					ignore
			end;
		_ ->
			case erlang:abs(RoleTX - TX) =< ?YBC_CHANGE_MAP_DISTANCE andalso erlang:abs(RoleTY - TY) =< ?YBC_CHANGE_MAP_DISTANCE of
				true ->
					case (NewMapID =:= 10250 andalso OldMapID =:= 10260) orelse
							 (NewMapID =:= 10251 andalso OldMapID =:= 10250)
						of
						true ->
							ybc_change_map3(YbcID, YbcMapInfo, NewMapProcessName, NewMapID, NewPos);
						false ->
							ignore
					end;
				_ ->
					ignore
			end
	end.

ybc_change_map3(YbcID, YbcMapInfo, NewMapPName, NewMapID, NewPos) ->
    #p_pos{tx=TX, ty=TY} = NewPos,
    %% 编辑地图的时候要保证跳转点周围的所有点都是可走的
    Pos = NewPos#p_pos{tx=TX, ty=TY},
    NewYbcMapInfo = YbcMapInfo#p_map_ybc{pos=Pos},
    BuffTimerList = mod_ybc_buff:clear_buff_timer_list(YbcID),
    delfrom_ybc_list(YbcID),
    clear_ybc_full_info(YbcID),
    %% 退出旧地图
    mod_map_actor:do_quit(YbcID, ybc, mgeem_map:get_state()),
    mgeem_persistent:ybc_persistent(YbcID, NewMapID, NewYbcMapInfo),
    %% 通知进入新地图
    NewYbcMapExt = #r_map_ybc_ext{buff_timer_list=BuffTimerList},
    catch global:send(NewMapPName, {mod_map_actor, {ybc_enter, YbcID, NewYbcMapInfo,NewYbcMapExt}}),
    ok.

del_ybc(YbcID)->
    [YbcInfo] = db:dirty_read(?DB_YBC, YbcID),
    MapID = YbcInfo#r_ybc.map_id,
    global:send(common_map:get_common_map_name(MapID), {?MODULE, {del_ybc, YbcID}}).

loop() ->
    loop_status_check(),    
    ok.

loop_ms(NowMsec) ->
    [ work(YbcID, NowMsec) ||YbcID<- get_ybc_list()],
    ok.

get_new_ybc_info(YbcInfo, YbcMapInfo) ->
    #p_map_ybc{ybc_id=YbcID,
               status=Status,
               hp=HP,
               max_hp=MaxHP,
               pos=Pos,
               move_speed=MoveSpeed,
               name=Name,
               create_type=CreateType,
               creator_id=CreatorID,
               color=Color,
               create_time=CreateTime,
               end_time=EndTime,
               buffs=Buffs,
               group_id=GroupID,
               group_type=GroupType,
               can_attack=CanAttack,
               level=YbcLevel
              } = YbcMapInfo,
    
    YbcInfo#r_ybc{ybc_id=YbcID, status=Status,
                  hp=HP,
                  max_hp=MaxHP,
                  pos=Pos,
                  move_speed=MoveSpeed,
                  name=Name,
                  create_type=CreateType,
                  creator_id=CreatorID,
                  color=Color,
                  create_time=CreateTime,
                  end_time=EndTime,
                  buffs=Buffs,
                  group_id=GroupID,
                  group_type=GroupType,
                  can_attack=CanAttack,
                  level=YbcLevel
                 }.


terminate() ->
    List = get_ybc_list(),
    lists:foreach(
      fun(YbcID) ->       
              db:transaction(fun() ->
                                     case db:read(?DB_YBC, YbcID, write) of
                                         [] ->
                                             ignore;
                                         [YbcInfo] ->
                                             YbcMapInfo = mod_map_actor:get_actor_mapinfo(YbcID, ybc),
                                             NewYbcInfo = get_new_ybc_info(YbcInfo, YbcMapInfo),
                                             db:write(?DB_YBC, NewYbcInfo, write)
                                     end
                             end)
      end, List).

%% 检查所有镖车的状态
loop_status_check() ->
    List = get_ybc_list(),
    Now = common_tool:now(),
    lists:foreach(
      fun(YbcID) ->
              case  mod_map_actor:get_actor_mapinfo(YbcID, ybc) of
                  undefined ->
                      ignore;
                  YbcMapInfo ->
                      #p_map_ybc{pos=Pos, end_time=EndTime} = YbcMapInfo,
                      %% 判断镖车是否已经到了消失时间了
                      case Now > EndTime of
                          true ->
                              %% 镖车时间到了，直接删除掉
                              do_timeout_ybc(YbcID);
                          false ->
                              case get_ybc_full_info(YbcID) of
                                  undefined ->
                                      set_ybc_full_info(YbcID, db:dirty_read(?DB_YBC, YbcID)),
                                      ignore;
                                  YbcFullInfo ->
                                      RoleIDList = YbcFullInfo#r_ybc.role_list,
                                      #p_pos{tx=TX, ty=TY} = Pos,
                                      MapID = mgeem_map:get_mapid(),
                                      YbcPosVo = #m_ybc_pos_toc{ybc_id=YbcID, map_id=MapID, tx=TX, ty=TY},

                                      RoleList = lists:foldl(
                                                   fun({RID, RName, _Level, _SB, _S}, Acc) ->
                                                           case mod_map_actor:get_actor_txty_by_id(RID, role) of
                                                               {RTX, RTY} ->
                                                                   %% 镖车全地图广播
                                                                   common_misc:unicast({role, RID}, 
                                                                                       ?DEFAULT_UNIQUE, 
                                                                                       ?YBC, ?YBC_POS, YbcPosVo),
                                                                   case (erlang:abs(TX - RTX) > ?YBC_WALK_ALLOW_DISTANCE)  orelse 
                                                                       (erlang:abs(TY - RTY) > ?YBC_WALK_ALLOW_DISTANCE) 
                                                                   of
                                                                       true ->
                                                                           [{RID, RName} | Acc];
                                                                       false ->
                                                                           Acc
                                                                   end;
                                                                _ ->
                                                                  [{RID, RName} | Acc]
                                                           end
                                                   end, [], RoleIDList),
                                      case erlang:length(RoleList) > 0 of
                                          true ->                                              
                                              set_ybc_stop(YbcID, YbcMapInfo, RoleList);
                                          false ->
                                              set_ybc_normal(YbcID, YbcMapInfo)
                                      end
                              end
                      end
              end
    end,  List),
    ok.


%% 状态的变化先保存在进程字典中，地图退出时，或者交任务等等才会持久化
set_ybc_stop(YbcID, YbcMapInfo, IfFarAway) ->    
    Status = YbcMapInfo#p_map_ybc.status,
    %% 清理掉镖车走路信息
    init_ybc_walk_info(YbcID),
    if
        Status =:= ?YBC_STATUS_STOP ->
            ignore;
        true ->       
            case IfFarAway of
                [] ->
                    ignore;
                RoleList2 ->
                    GroupType = YbcMapInfo#p_map_ybc.group_type,
                    case GroupType =:= 1 of
                        true ->
                            [{RID, _}] = IfFarAway,
                            common_misc:unicast({role, RID}, ?DEFAULT_UNIQUE, ?YBC, ?YBC_FARAWAY, 
                                                #m_ybc_faraway_toc{map_id=mgeem_map:get_mapid(), pos=YbcMapInfo#p_map_ybc.pos}),
                            catch common_broadcast:bc_send_msg_role([RID], ?BC_MSG_TYPE_CENTER, ?_LANG_YBC_PERSON_FARAWAY);
                        false -> 
                            RoleList = [RID || {RID, _RName} <- RoleList2],
                            RoleMsg = ?_LANG_FAMILY_YBC_FARAWAY_SELF,
                            lists:foreach(
                              fun({RID, RName}) ->
                                      catch common_broadcast:bc_send_msg_role([RID],?BC_MSG_TYPE_CENTER, RoleMsg),
                                      RoleMsgOther = common_misc:format_lang(?_LANG_FAMILY_YBC_FARAWAY_OTHER, [RName]),
                                      catch common_broadcast:bc_send_msg_role(lists:delete(RID, RoleList), 
                                                                         ?BC_MSG_TYPE_CENTER, RoleMsgOther)
                              end, RoleList2),
                            ok
                    end
            end,
            mod_map_actor:set_actor_mapinfo(YbcID, ybc, YbcMapInfo#p_map_ybc{status=?YBC_STATUS_STOP})
    end.

set_ybc_normal(YbcID, YbcMapInfo) ->
    mod_map_actor:set_actor_mapinfo(YbcID, ybc, YbcMapInfo#p_map_ybc{status=?YBC_STATUS_NORMAL}).
    

work(YbcID,NowMsec) ->
    case mod_map_actor:get_actor_mapinfo(YbcID, ybc) of
        undefined ->
            ignore;
        YbcMapInfo ->
            #p_map_ybc{creator_id=RoleID, pos=Pos, status=Status} = YbcMapInfo,
            case Status =:= ?YBC_STATUS_NORMAL of
                true ->
                    do_walk(YbcID, Pos, RoleID, NowMsec);
                false ->
                    ignore
            end
    end.

do_test_walk(YbcID, TX, TY) ->
    Now = common_tool:now2(),
    YbcMapInfo = mod_map_actor:get_actor_mapinfo(YbcID, ybc),
    #p_map_ybc{pos=Pos} = YbcMapInfo,
    do_walk2(YbcID, #p_pos{tx=TX, ty=TY, dir=0}, Pos, Now).
    

%% 另外在保存镖车的状态在地图中，如上次走路的时间等等
do_walk(YbcID, Pos, RoleID, Now) ->    
    TargetPos = mod_map_actor:get_actor_pos(RoleID, role),
    %% 对应的玩家可能已经跳转地图了
    case TargetPos =:= undefined of
        true ->
            ignore;
        false ->
            do_walk2(YbcID, TargetPos, Pos, Now)
    end.

init_enter(YbcID, CreatorID) ->
    set_role_ybc_id(CreatorID, YbcID),
    [YbcInfo] = db:dirty_read(?DB_YBC, YbcID),
    set_ybc_full_info(YbcID, YbcInfo),
    set_ybc_walk_info(YbcID, #p_ybc_walk_info{last_walk_time=0, next_walk_time=0}),
    addto_ybc_list(YbcID).


get_ybc_walk_info(YbcID) ->
    erlang:get({ybc_walk_info, YbcID}).
set_ybc_walk_info(YbcID, WalkInfo) ->
    erlang:put({ybc_walk_info, YbcID}, WalkInfo).
init_ybc_walk_info(YbcID) ->
    erlang:put({ybc_walk_info, YbcID}, #p_ybc_walk_info{last_path=[], last_walk_time=0, next_walk_time=0}).
erase_ybc_walk_info(YbcID) ->
    erlang:erase({ybc_walk_info, YbcID}).

do_walk2(YbcID, TargetPos, Pos, Now) ->
    case get_ybc_walk_info(YbcID) of
        undefined ->
            ignore;
        YbcWalkInfo ->
            #p_ybc_walk_info{next_walk_time=NextWalkTime} = YbcWalkInfo,
            case NextWalkTime =:= undefined orelse NextWalkTime =:= 0 orelse NextWalkTime < Now of
                true ->
                    case mod_map_actor:get_actor_mapinfo(YbcID, ybc) of
                        undefined ->
                            ignore;
                        YbcMapInfo ->
                            do_walk3(YbcID, YbcWalkInfo, YbcMapInfo, TargetPos, Pos, Now)
                    end;
                false ->
                    ignore
            end
    end.

do_walk3(YbcID, YbcWalkInfo, YbcMapInfo, TargetPos, Pos, Now) ->
    #p_pos{tx=TX, ty=TY} = Pos,
    #p_pos{tx=TTX, ty=TTY} = TargetPos,
    case (erlang:abs(TX - TTX) < 4 andalso erlang:abs(TY - TTY) < 4) orelse
        (erlang:abs(TX-TTX) > ?YBC_WALK_ALLOW_DISTANCE ) orelse (erlang:abs(TY -TTY) > ?YBC_WALK_ALLOW_DISTANCE)
    of
        true ->
            case (erlang:abs(TX - TTX) < 4 andalso erlang:abs(TY - TTY) < 4) of
                true ->
                    set_ybc_stop(YbcID, YbcMapInfo, []);
                false ->
                    RoleID = YbcMapInfo#p_map_ybc.creator_id,
                    {ok, #p_role_base{role_name=RoleName}} = mod_map_role:get_role_base(RoleID),
                    set_ybc_stop(YbcID, YbcMapInfo, [{RoleID, RoleName}])
            end;
        false ->
            #p_ybc_walk_info{last_path=LastPathTmp, last_target_pos=LastTargetPos} = YbcWalkInfo,
			if
				LastPathTmp =:= undefined ->
					LastPath = [];
				true ->
					LastPath = LastPathTmp
			end,
            case length(LastPath) < 2 of
                true ->
                    %% 寻路
                    case mod_walk:get_walk_path(Pos, TargetPos) of
                        {ok, [_|Path]} when is_list(Path) ->
                            case erlang:length(Path) < 2 of
                                true ->
                                    delay_next_walk_time(YbcID,YbcWalkInfo,Now);
                                false ->
                                    do_walk4(YbcID, TargetPos, YbcWalkInfo, YbcMapInfo, Path, Now)
                            end;
                        Error ->
                            ?ERROR_MSG("~ts:~w", ["镖车寻路出错", Error]),
                            delay_next_walk_time(YbcID,YbcWalkInfo,Now)
                    end;
                false ->                   
                    case LastTargetPos =/= TargetPos of
                        true ->
                            %% 寻路
                            case mod_walk:get_walk_path(Pos, TargetPos) of
                                {ok, [_|Path]} when is_list(Path) ->
                                    case erlang:length(Path) < 2 of
                                        true ->
                                             delay_next_walk_time(YbcID,YbcWalkInfo,Now);
                                        false ->
                                             do_walk4(YbcID, TargetPos, YbcWalkInfo, YbcMapInfo, Path, Now)
                                    end;
                                Error ->
                                    ?ERROR_MSG("~ts:~w", ["镖车寻路出错", Error]),
                                     delay_next_walk_time(YbcID,YbcWalkInfo,Now)
                            end;
                        false ->
                            do_walk4(YbcID, TargetPos, YbcWalkInfo, YbcMapInfo, LastPath, Now)
                    end
            end
    end.


do_walk4(YbcID, TargetPos, YbcWalkInfo, YbcMapInfo, [WalkPos|LastPath], Now) ->    
    #p_map_ybc{move_speed=Speed} = YbcMapInfo,
    {TX, TY, DIR} = WalkPos,
    
    %% 判断Slice的变化
    {OldTX,OldTY} = case mod_map_actor:get_actor_txty_by_id(YbcID, ybc) of
                        undefined ->
                            {TX,TY};
                        {X,Y} ->
                            {X,Y}
                    end,
    #map_state{offsetx=OffsetX, offsety=OffsetY} = mgeem_map:get_state(),
    AllSliceOld = mgeem_map:get_9_slice_by_txty(OldTX,OldTY,OffsetX,OffsetY),
    AllSliceNew = mgeem_map:get_new_around_slice(TX, TY, OldTX, OldTY, OffsetX, OffsetY),
    AllSlice = common_tool:combine_lists(AllSliceOld,AllSliceNew),
    InSlice = mgeem_map:get_slice_by_txty(TX, TY, OffsetX, OffsetY),
    WalkPos2 = #p_pos{tx=TX,ty=TY, dir=DIR},
    DataRecord = #m_ybc_walk_toc{ybc_id=YbcID, pos = WalkPos2},
    case AllSlice =/= undefined andalso InSlice =/= undefined of
        true ->
            AroundSlices = lists:delete(InSlice, AllSlice),
            RoleIDList1 = mod_map_actor:slice_get_roles(InSlice),
            RoleIDList2 = mgeem_map:get_all_in_sence_user_by_slice_list(AroundSlices),
            mgeem_map:broadcast(RoleIDList1, RoleIDList2, ?DEFAULT_UNIQUE, 
                                  ?YBC, ?YBC_WALK, DataRecord);
        false ->
            ?INFO_MSG("unexcept error!",[])
    end,
    NeedTime = mod_walk:get_move_speed_time(Speed, DIR),
    PlanWalkTime = YbcWalkInfo#p_ybc_walk_info.next_walk_time,
    case Now - PlanWalkTime < 100 of
        true ->
            NewNextWalkTime = PlanWalkTime + NeedTime;
        false ->
            NewNextWalkTime = Now + NeedTime
    end,
    set_ybc_walk_info(YbcID, YbcWalkInfo#p_ybc_walk_info{last_path=LastPath, 
                                                         last_target_pos=TargetPos, 
                                                         next_walk_time=NewNextWalkTime,
                                                         last_walk_time=Now}),
    mod_map_actor:update_slice_by_txty(YbcID, ybc, TX, TY, OffsetX, OffsetY, DIR).


%%镖车寻路异常或者被堵住时 让其寻路暂停1秒
delay_next_walk_time(YbcID,YbcWalkInfo,Now) ->
    set_ybc_walk_info(YbcID, YbcWalkInfo#p_ybc_walk_info{next_walk_time=Now + 1000}).


%% 镖车重新进入地图，需要判断哪些已经无用该删除了
init_ybc_slice(YbcList) ->
    lists:foreach(
      fun(YbcInfo) ->
              do_enter(YbcInfo)
      end, YbcList).

get_person_ybc_id(RoleID) ->
    case db:dirty_read(?DB_YBC_UNIQUE, {0, 1, RoleID}) of
        [] ->
            0;
        [#r_ybc_unique{id=ID}] ->
            ID
    end.

do_ybc_dead(YbcID, _YbcMapInfo, RoleID) ->
	%% 广播镖车的死亡信息
	mgeem_map:do_broadcast_insence_include([{ybc, YbcID}], ?YBC, ?YBC_DEAD, #m_ybc_dead_toc{ybc_id=YbcID}, mgeem_map:get_state()),
	case db:dirty_read(?DB_YBC, YbcID) of
		[#r_ybc{role_list=RoleList, level=Level, faction_id=FactionID, group_id=GroupID, group_type=GroupType, creator_id=CreatorID}] ->
			SilverAll = lists:foldl(
						  fun({_RID, _RName, _RLevel, SB, _Silver}, Acc) ->
								  Acc + SB
						  end, 0, RoleList), 
			{ok, #p_role_base{faction_id=SrcFactionID}} = mod_map_role:get_role_base(RoleID),
			case Level > 30 of
				true ->
					KillTimes = mod_ybc_person:get_role_kill_times(RoleID, date(),2),
					[AllowKillTimes] = common_config_dyn:find(personybc, kill_times),
					case KillTimes >= AllowKillTimes of
						true ->
							?ROLE_SYSTEM_BROADCAST(RoleID,"你今日劫镖次数已达3次上限，无法获取收益");
						false ->
							mod_ybc_person:add_role_kill_times(RoleID, CreatorID, date(), 1, 2),
							mod_ybc_person:add_role_kill_times(CreatorID, RoleID, date(), 1, 1),
							do_reward_silver(RoleID,SrcFactionID, FactionID, SilverAll)
					end;
				false ->
					ignore
			end,            
			%% 处理PK情况
			case SrcFactionID =:= FactionID of
				true ->
					mod_pk:kill_faction_ybc(RoleID),
					ok;
				false ->
					ignore
			end,
			case GroupType of
				2 ->
					common_family:info(GroupID, {ybc_dead, YbcID, RoleList});
				1 ->
					mod_ybc_person:killed(YbcID);
				_ ->
					ignore
			end,
			mod_ybc_person:reset_role_speed(CreatorID),
			%% 更新镖车状态
			db:dirty_delete(?DB_YBC, YbcID),
			db:dirty_delete(?DB_YBC_UNIQUE, {GroupID, GroupType, CreatorID}),
			%% 镖车列表中删除
			delfrom_ybc_list(YbcID),
			%% 地图中退出
			mod_map_actor:do_quit(YbcID, ybc, mgeem_map:get_state());
		_ ->
			%% 镖车列表中删除
			delfrom_ybc_list(YbcID),
			%% 地图中退出
			mod_map_actor:do_quit(YbcID, ybc, mgeem_map:get_state()),
			ignore
	end,
	ok.

do_reward_silver(RoleID,SrcFactionID, FactionID, SilverAll) ->
	DropSilver = get_drop_silver(SrcFactionID, FactionID, SilverAll),
	{ok,#p_role_attr{silver_bind=SilverBind}=RoleAttr} = mod_map_role:get_role_attr(RoleID),
	NewRoleAttr = RoleAttr#p_role_attr{silver_bind=SilverBind+DropSilver},
	case catch common_transaction:t(fun()-> 
											mod_map_role:set_role_attr(RoleID,NewRoleAttr)
									end) of
		{atomic,_} ->
			common_misc:send_role_gold_silver_change(RoleID, NewRoleAttr),
			?ROLE_SYSTEM_BROADCAST(RoleID,common_misc:format_lang("劫镖收获钱币~s",[common_misc:format_silver(DropSilver)]));
		{aborted, Error} -> 
			?ERROR_MSG("ERR~ts:~w", ["设置劫镖收益钱币系统错误", Error])
	end.

get_drop_silver(SrcFactionID, FactionID, AllSilver) ->
    Random = common_tool:random(1, 100),
    case SrcFactionID =:= FactionID of
        true ->
            case Random > 0 andalso Random < 80 of
                true ->
                    Silver = AllSilver * 0.1;
                false ->
                    Silver = 0
            end;
        false ->
            Silver = get_drop_silver_difference_faction(Random, AllSilver)
    end,
    common_tool:ceil(Silver).

get_drop_silver_difference_faction(Random, AllSilver) when Random =< 50 ->
    AllSilver * 0.3;
get_drop_silver_difference_faction(Random, AllSilver) when Random =< 80 ->
    AllSilver * 0.5;
get_drop_silver_difference_faction(Random, AllSilver) when Random =< 95 ->
    AllSilver * 0.8;
get_drop_silver_difference_faction(Random, AllSilver) when Random =< 100 ->
    AllSilver.

    

do_del_ybc(YbcID) ->
    case db:dirty_read(?DB_YBC, YbcID) of
        [_] ->
            %% 数据库中删除
            del_ybc_from_db(YbcID);
        _ ->
            ignore
    end,
    delfrom_ybc_list(YbcID),
    clear_ybc_full_info(YbcID),
    mod_map_actor:do_quit(YbcID, ybc, mgeem_map:get_state()),
    erase_ybc_walk_info(YbcID),
    delete_person_ybc_sos_dict(YbcID),
    ok.

do_timeout_ybc(YbcID) ->
    case db:dirty_read(?DB_YBC, YbcID) of
        [#r_ybc{role_list=RoleList, creator_id=CreatorID} = YbcInfo] ->
            YbcGroup = YbcInfo#r_ybc.group_type,
            if
                YbcGroup =:= 1 ->
                    catch common_letter:sys2p(CreatorID, ?_LANG_YBC_TIMEOUT_LETTER_CONTENT_PERSON, ?_LANG_YBC_TIMEOUT_LETTER_TITLE),
					mod_ybc_person:timeout(YbcID);
                true ->
                    catch common_letter:sys2p(CreatorID, ?_LANG_YBC_TIMEOUT_LETTER_CONTENT_FAMILY, ?_LANG_YBC_TIMEOUT_LETTER_TITLE),
                    common_family:info(YbcInfo#r_ybc.group_id, {ybc_timeout, RoleList})
            end,
            %% 更新镖车状态
            db:dirty_write(?DB_YBC, YbcInfo#r_ybc{status=?YBC_STATUS_TIMEOUT_DEL});
        _ ->            
            ignore
    end,
    %% 镖车列表中删除
    delfrom_ybc_list(YbcID),
    clear_ybc_full_info(YbcID),
    %% 地图中退出
    mod_map_actor:do_quit(YbcID, ybc, mgeem_map:get_state()),
    erase_ybc_walk_info(YbcID),
    ok.

%% 从数据库中读取镖车列表
get_ybc_list_from_db(MapID) ->
    List = db:dirty_match_object(?DB_YBC, #r_ybc{_='_', map_id=MapID}),
    %% 过滤掉非正常状态的镖车
    lists:filter(
      fun(#r_ybc{status=Status}) ->
              Status =:= ?YBC_STATUS_NORMAL
      end, List).
del_ybc_from_db(YbcID) ->
    %% 尝试从进程字典读取一些信息
    case get_ybc_full_info(YbcID) of
        undefined ->
            case db:dirty_read(?DB_YBC, YbcID) of
                [#r_ybc{group_type=GroupType, group_id=GroupID, creator_id=CreatorID}] ->
                    db:dirty_delete(?DB_YBC_UNIQUE, {GroupID, GroupType, CreatorID});
                [] ->
                    ignore
            end;
        #r_ybc{group_type=GroupType, group_id=GroupID, creator_id=CreatorID} ->
            db:dirty_delete(?DB_YBC_UNIQUE, {GroupID, GroupType, CreatorID})
    end,
    db:dirty_delete(?DB_YBC, YbcID).


get_ybc_full_info(YbcID) ->
    erlang:get({ybc_full_info, YbcID}).
set_ybc_full_info(YbcID, YbcFullInfo) ->
    erlang:put({ybc_full_info, YbcID}, YbcFullInfo).
clear_ybc_full_info(YbcID) ->
    erlang:erase({ybc_full_info, YbcID}).


init_ybc_list(IDList) ->
    erlang:put(?ybc_id_list, IDList).
addto_ybc_list(YbcID) ->
    L = erlang:get(?ybc_id_list),
    case lists:member(YbcID, L) of
        true ->
            ignore;
        false ->
            erlang:put(?ybc_id_list, [YbcID | L])
    end.
delfrom_ybc_list(YbcID) ->
    erlang:put(?ybc_id_list, lists:delete(YbcID, erlang:get(?ybc_id_list))).
get_ybc_list() ->
    erlang:get(?ybc_id_list).




do_enter(YbcInfo) ->
    #r_ybc{ybc_id=YbcID, status=Status,
           hp=HP,
           max_hp=MaxHP,
           pos=Pos,
           move_speed=MoveSpeed,
           name=Name,
           create_type=CreateType,
           creator_id=CreatorID,
           color=Color,
           create_time=CreateTime,
           end_time=EndTime,
           buffs=Buffs,
           group_id=GroupID,
           group_type=GroupType,
           physical_defence=PD,
           magic_defence=MD,
           faction_id=FactionID,
           recover_speed=RS,
           can_attack=CanAttack,
           level=YbcLevel
           } = YbcInfo,
    YbcMapInfo = #p_map_ybc{
      ybc_id=YbcID,
      status=Status,
      hp=HP,
      max_hp=MaxHP,
      pos=Pos,
      move_speed=MoveSpeed,
      name=Name,
      create_type=CreateType,
      creator_id=CreatorID,
      color=Color,
      create_time=CreateTime,
      end_time=EndTime,
      buffs=Buffs,
      group_id=GroupID,
      group_type=GroupType,
      faction_id=FactionID,
      can_attack=CanAttack,
      physical_defence=PD,
      recover_speed=RS,
      magic_defence=MD,
      level=YbcLevel
     },
    set_role_ybc_id(CreatorID, YbcID), 
    init_ybc_walk_info(YbcID),
    set_ybc_full_info(YbcID, YbcInfo),
    case Status =/= ?YBC_STATUS_KILLED andalso EndTime > common_tool:now() of
        true ->
            mod_map_actor:do_enter(0, YbcID, YbcID, ybc, YbcMapInfo, 0, mgeem_map:get_state());
        false ->
            do_del_ybc(YbcID)
    end.

do_reborn(YbcID) ->
    case db:dirty_read(?DB_YBC, YbcID) of
        [] ->
            ignore;
        [YbcInfo] ->
            do_enter(YbcInfo),
            addto_ybc_list(YbcID)
    end.

%% YbcInfo -> p_ybc_create_info
create_ybc(YbcCreateInfo) ->
    case db:transaction(
           fun() -> t_do_create_ybc(YbcCreateInfo) end) 
    of
        {atomic, {YbcID, YbcInfo}} ->            
            do_enter(YbcInfo),
            addto_ybc_list(YbcID),
            ok;
        {aborted, Error} ->
            case Error of
                {recreate, YbcID, YbcInfo} ->
                    ?ERROR_MSG("~ts:~w", ["镖车已经存在", YbcInfo]),
                    addto_ybc_list(YbcID),
                    do_enter(YbcInfo);
                _ ->
                    ?ERROR_MSG("~ts:~w", ["创建镖车出错", Error])
            end,
            error
    end,    
    ok.

create_ybc_reply(YbcCreateInfo, From) ->
    case db:transaction(
           fun() -> t_do_create_ybc(YbcCreateInfo) end) 
    of
        {atomic, {YbcID, YbcInfo}} ->   
            From ! {create_ybc_succ, YbcID},
            do_enter(YbcInfo),
            addto_ybc_list(YbcID),
            ok;
        {aborted, Error} ->
            case Error of
                {recreate, YbcID, YbcInfo} ->
                    From ! {create_ybc_succ, YbcID},
                    ?ERROR_MSG("~ts:~w", ["镖车已经存在", YbcInfo]),
                    addto_ybc_list(YbcID),
                    do_enter(YbcInfo);
                _ ->
                    From ! {create_ybc_failed, YbcCreateInfo#p_ybc_create_info.creator_id},
                    ?ERROR_MSG("~ts:~w", ["创建镖车出错", Error])
            end,
            error
    end,    
    ok.


t_do_create_ybc(YbcInfo) ->
    #p_ybc_create_info{group_type=GroupType, group_id=GroupID, creator_id=CreatorID,
                       max_hp=MaxHP, create_type=CreateType, color=Color,
                       move_speed=MoveSpeed, name=Name, create_time=CreateTime,
                       end_time=EndTime, buffs=Buffs, recover_speed=RecoverSpeed,
                       magic_defence=MagicDefence, physical_defence=PhysicalDefence,
                       faction_id=FactionID,
                       can_attack=CanAttack,
                      role_list=RoleList,level=YbcLevel} = YbcInfo,
    %% 判断对应镖车是否已经存在，每个对象只有一个镖车
    case db:read(?DB_YBC_UNIQUE, {GroupID, GroupType, CreatorID}, write) of
        [] ->
            ok;
        [#r_ybc_unique{id=YbcID}] ->
            [Info] = db:read(?DB_YBC, YbcID, read),
            db:abort({recreate, YbcID, Info})
    end,
    [#r_ybc_index{value=OldID}] = db:read(?DB_YBC_INDEX, 1, write),
    NewID = OldID + 1,
    db:write(?DB_YBC_INDEX, #r_ybc_index{id=1, value=NewID}, write),
    db:write(?DB_YBC_UNIQUE, #r_ybc_unique{unique={GroupID, GroupType, CreatorID}, id=NewID}, write),
    MapID = mgeem_map:get_mapid(),
    %% 一定要获取最实时的数据，或者固定在史可法附近
    Pos = mod_map_actor:get_actor_pos(CreatorID, role),
    R = #r_ybc{ybc_id=NewID, status=?YBC_STATUS_NORMAL, faction_id=FactionID,
               pos=Pos, move_speed=MoveSpeed,group_type=GroupType, group_id=GroupID, creator_id=CreatorID,
               create_type=CreateType, color=Color, name=Name, create_time=CreateTime,
               end_time=EndTime, buffs=Buffs, recover_speed=RecoverSpeed, can_attack=CanAttack,
                magic_defence=MagicDefence, physical_defence=PhysicalDefence, 
              role_list=RoleList, map_id=MapID, hp=MaxHP, max_hp=MaxHP, level=YbcLevel},
    db:write(?DB_YBC, R, write),
    {NewID, R}.


set_gray_name(AttackorID) ->
    AttackorMapInfo = mod_map_actor:get_actor_mapinfo(AttackorID, role),
    {ok, RoleBase} = mod_map_role:get_role_base(AttackorID),
    PKPoint = RoleBase#p_role_base.pk_points,

    case AttackorMapInfo of
        undefined ->
            ignore;
        _ when PKPoint < 18 ->
            GrayName = AttackorMapInfo#p_map_role.gray_name,
            if
                GrayName =:= false ->
                    mod_gray_name:do_gray_name(AttackorID, AttackorMapInfo);
                true ->
                    ignore
            end;
        _ ->
            ignore
    end.

send_sos_to_family(RoleID,GroupType,Pos,YbcID) ->
	if
		GroupType =:= 1 -> %%只针对个人镖车
			case mod_map_role:get_role_base(RoleID) of
				{ok, RoleBase} ->
					#p_role_base{family_id=FamilyID,role_name=RoleName} = RoleBase,
					case FamilyID > 0 of
						true ->
							case erlang:get(person_ybc_sos) of
								undefined ->
									send_sos_to_family2(FamilyID,RoleID,RoleName,Pos,YbcID);
								Val ->
									case lists:keyfind(YbcID,1,Val) of
										{YbcID,true} ->
											ignore;
										false ->
											send_sos_to_family2(FamilyID,RoleID,RoleName,Pos,YbcID)
									end
							end;
						false ->
							ignore
					end;
				{error, role_not_found} ->
					ignore
			end;
		true ->
			ignore
	end.

send_sos_to_family2(FamilyID,RoleID,RoleName,Pos,YbcID) ->
	common_misc:update_dict_queue(person_ybc_sos,{YbcID,true}),
	MapID = mgeem_map:get_mapid(),
	common_family:info(FamilyID, {person_ybc_sos,RoleID,RoleName,Pos,MapID}).

delete_person_ybc_sos_dict(YbcID) ->
	case erlang:get(person_ybc_sos) of
		undefined ->
			ignore;
		Val ->
			erlang:put(person_ybc_sos,lists:keydelete(YbcID,1,Val))
	end.
