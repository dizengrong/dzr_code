%%%-------------------------------------------------------------------
%%% @author  caochuncheng
%%% @copyright mcsd (C) 2010, 
%%% @doc
%%% 组队经验处理进程
%%% @end
%%% Created : 26 Jun 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_team_exp).

%% Include files
-include("mgeem.hrl").

%% API
-export([
         handle/1,
         get_vip_exp/2,
         get_multi_exp/3,
         get_exp_after_punish/5
        ]).

-define(MONSTER_RARITY_NORMAL, 1).
-define(DEFAULT_MAX_PIXELS, {1002, 580}).
-define(EXP_RULE, [{2, 10}, {3, 15}, {4, 20}, {5, 25}, {6, 30}]).


%%%===================================================================
%%% API
%%%===================================================================

handle(Args) ->
    do_handle(Args).

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({add_exp, ExpRecordList}) ->
    add_exp4(ExpRecordList);
do_handle({add_system_buff, BuffList}) ->
    do_add_system_buff(BuffList);
do_handle({remove_system_buff, family, FamilyID}) ->
    do_remove_system_buff(family, FamilyID);
do_handle({remove_system_buff, faction, FactionID}) ->
    do_remove_system_buff(faction, FactionID);
do_handle({add_world_system_buff, Multiple}) ->
    do_add_world_system_buff(Multiple);
do_handle({remove_world_system_buff}) ->
    do_remove_world_system_buff();

do_handle(Args) ->
    ?ERROR_MSG("mod_tteam_exp, unknow args: ~w", [Args]).

%% @doc 世界经验BUFF
do_add_world_system_buff(Multiple) ->
    erlang:put(world_system_buff, Multiple).

%% @doc 移除世界经验Buff
do_remove_world_system_buff() ->
    erlang:erase(world_system_buff).

%% @doc 添加系统buff
do_add_system_buff(BuffList) ->
    lists:foreach(
      fun({BuffType, ID, Multiple}) ->
              erlang:put({BuffType, ID}, Multiple);
         ({world_multi_exp_buff, Multiple}) ->
              erlang:put(world_system_buff, Multiple)
      end, BuffList).

%% @doc 移除系统buff
do_remove_system_buff(family, FamilyID) ->
    erlang:erase({family, FamilyID});
do_remove_system_buff(faction, FactionID) ->
    erlang:erase({faction, FactionID}).

%% ExpRecordList 结构为 [r_monster_exp,r_monster_exp,]
%% id,唯一标记，killer_id 杀死怪物的RoleId, map_id 地图id monster_id  怪物id, ,monster_type 怪物类型 
%% monster_tx,monster_ty 怪物死亡坐标，role_exp_list 获取得经验的玩家记录类型r_monster_role_exp
%% team_exp_list  队伍经验记录r_monster_team_exp
%% -record(r_monster_exp,{id,killer_id,map_id,monster_id,monster_type,monster_level, monster_rarity,monster_tx,monster_ty,role_exp_list,team_exp_list}).
%% 怪物经验玩家经验记录
%% -record(r_monster_role_exp,{role_id,exp}).
%% 队伍经验记录,team_sub_list 队伍成员经验记录列表r_monster_team_sub_exp
%% -record(r_monster_team_exp,{team_id,team_sub_list}).
%% role_id 角色id,exp 角色所得经验
%% -record(r_monster_team_sub_exp,{role_id, exp, team_id, team_exp, level,kill_flag,status}).
add_exp4(ExpRecordList) ->
    ExpRecordList2 = lists:map(fun(ExpRecord) ->
                                       #r_monster_exp{killer_id = KillerId} = ExpRecord,
                                       TeamExpList = add_exp4_1(ExpRecord,KillerId),
                                       ExpRecord#r_monster_exp{team_exp_list = TeamExpList}
                               end, ExpRecordList),
    add_exp5(ExpRecordList2).
add_exp4_1(ExpRecord,KillerId) ->
    #r_monster_exp{role_exp_list = RoleExpList} = ExpRecord,
    do_exp_list(RoleExpList,KillerId, []).
%% 将此次怪物经验获取者,进行分类,即同一队伍的分组,没有队伍的默认队伍Id为0的组
%% 返回的结果为TeamExpList 结构为 [r_monster_team_exp,r_monster_team_exp....]
%% 队伍经验记录,team_sub_list 队伍成员经验记录列表r_monster_team_sub_exp
%% -record(r_monster_team_exp,{team_id,team_sub_list}).
%% role_id 角色id,exp 角色所得经验
%% -record(r_monster_team_sub_exp,{role_id, exp, team_id, team_exp, level,kill_flag,status}).
do_exp_list([],_KillerId, Result) -> Result;
do_exp_list([H|T],KillerId, Result) ->
    #r_monster_role_exp{role_id = RoleID,exp = Exp, energy_index=EnergyIndex} = H,
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            do_exp_list(T, KillerId, Result);
        RoleMapInfo ->
            case mod_map_actor:get_actor_mapinfo(KillerId, role) of
                undefined ->
                    do_exp_list(T, KillerId, Result);
                KillerMapInfo ->
                    do_exp_list2(T, RoleID, KillerId, Exp, EnergyIndex, Result, RoleMapInfo, KillerMapInfo)
            end
    end.

do_exp_list2(T, RoleID, KillerId, Exp, EnergyIndex, Result, RoleMapInfo, KillerMapInfo) ->
    #p_map_role{team_id=TeamId, level=Level, state=Status} = RoleMapInfo,
    KillerTeamId = KillerMapInfo#p_map_role.team_id,

    KillFlag = if TeamId =:= KillerTeamId 
                  andalso TeamId =/= 0
                  andalso KillerTeamId =/= 0 ->
                       true;
                  KillerId =:= RoleID ->
                       true;
                  true ->
                       false
               end,
    RoleExp = #r_monster_team_sub_exp{role_id = RoleID, 
                                      exp = Exp,
                                      team_id = TeamId, 
                                      team_exp = 0,
                                      level = Level,
                                      kill_flag = KillFlag,
                                      status = Status,
                                      energy_index=EnergyIndex
                                     },
    case lists:keyfind(TeamId,#r_monster_team_exp.team_id,Result) of
        false ->
            MonsterTeamExp = #r_monster_team_exp{team_id = TeamId,team_sub_list = [RoleExp]},
            do_exp_list(T, KillerId, [MonsterTeamExp|Result]);
        TeamExpRecord ->
            #r_monster_team_exp{team_sub_list = TeamSubList} = TeamExpRecord,
            Result2 = lists:keydelete(TeamId, #r_monster_team_exp.team_id, Result),
            TeamExpRecord2 = TeamExpRecord#r_monster_team_exp{team_sub_list = [RoleExp|TeamSubList]},
            do_exp_list(T, KillerId,[TeamExpRecord2|Result2])
    end.

%% ExpRecordList 结构为 [r_monster_exp,r_monster_exp,]
%% id,唯一标记，killer_id 杀死怪物的RoleId, map_id 地图id monster_id  怪物id, ,monster_type 怪物类型 
%% monster_tx,monster_ty 怪物死亡坐标，role_exp_list 获取得经验的玩家记录类型r_monster_role_exp
%% team_exp_list  队伍经验记录r_monster_team_exp
%% -record(r_monster_exp,{id,killer_id,map_id,monster_id,monster_type,monster_level, monster_rarity,monster_tx,monster_ty,role_exp_list,team_exp_list}).
%% 怪物经验玩家经验记录
%% -record(r_monster_role_exp,{role_id,exp}).
%% 队伍经验记录,team_sub_list 队伍成员经验记录列表r_monster_team_sub_exp
%% -record(r_monster_team_exp,{team_id,team_sub_list}).
%% role_id 角色id,exp 角色所得经验
%% -record(r_monster_team_sub_exp,{role_id, exp, team_id, team_exp, level,kill_flag,status}).
add_exp5(ExpRecordList) ->
    lists:foreach(fun(ExpRecord) ->
                          add_exp6(ExpRecord)
                  end, ExpRecordList).


%% id,唯一标记，killer_id 杀死怪物的RoleId, map_id 地图id monster_id  怪物id, ,monster_type 怪物类型 
%% monster_tx,monster_ty 怪物死亡坐标，role_exp_list 获取得经验的玩家记录类型r_monster_role_exp
%% team_exp_list  队伍经验记录r_monster_team_exp
%% -record(r_monster_exp,{id,killer_id,map_id,monster_id,monster_type,monster_level, monster_rarity, monster_tx,monster_ty,role_exp_list,team_exp_list}).
add_exp6(ExpRecord) ->
    #r_monster_exp{team_exp_list = TeamExpList} = ExpRecord,
    TeamExpList2 = lists:map(fun(TeamExpRecord) ->
                                     #r_monster_team_exp{team_id = TeamId,team_sub_list = TeamSubList} = TeamExpRecord,
                                     if TeamId =:= 0 ->
                                             TeamSubList2 = [X#r_monster_team_sub_exp{
                                                               team_exp = X#r_monster_team_sub_exp.exp} || X <- TeamSubList],
                                             TeamExpRecord#r_monster_team_exp{team_sub_list = TeamSubList2};
                                        true ->
                                             add_exp6_1(ExpRecord,TeamExpRecord)
                                     end
                             end, TeamExpList),
    ExpRecord2 = ExpRecord#r_monster_exp{team_exp_list = TeamExpList2},
    %% TODO 每一个用户多条消息合并成一次发送，暂一个用户一条消息发送一次
    add_exp7(ExpRecord2).


%% id,唯一标记，killer_id 杀死怪物的RoleId, map_id 地图id monster_id  怪物id, ,monster_type 怪物类型 
%% monster_tx,monster_ty 怪物死亡坐标，role_exp_list 获取得经验的玩家记录类型r_monster_role_exp
%% team_exp_list  队伍经验记录r_monster_team_exp
%% -record(r_monster_exp,{id,killer_id,map_id,monster_id,monster_type,monster_level, monster_rarity, monster_tx,monster_ty,role_exp_list,team_exp_list}).
add_exp7(ExpRecord) ->
    #r_monster_exp{team_exp_list = TeamExpList} = ExpRecord,
    lists:foreach(fun(TeamExpRecord) ->
                          #r_monster_team_exp{team_sub_list = TeamSubList} = TeamExpRecord,
                          add_exp8(ExpRecord, TeamSubList)
                  end,TeamExpList).
%% 队伍经验记录,team_sub_list 队伍成员经验记录列表r_monster_team_sub_exp
%% -record(r_monster_team_exp,{team_id,team_sub_list}).
%% role_id 角色id,exp 角色所得经验
%% -record(r_monster_team_sub_exp,{role_id, exp, team_id, team_exp, level,kill_flag,status}).
add_exp8(ExpRecord, TeamSubList) ->
    Fun = fun(RoleExp, Acc) ->
      Acc + RoleExp#r_monster_team_sub_exp.level
    end,
    TotalRoleLv = lists:foldl(Fun, 0, TeamSubList),
    TeamLength = length(TeamSubList),
    #r_monster_exp{monster_type = MonsterType, monster_level=MonsterLevel, monster_rarity=MonsterRarity} = ExpRecord,
    lists:foreach(fun(RoleExp) ->
                          #r_monster_team_sub_exp{role_id=RoleID, team_exp=Exp, status=Status, kill_flag=KillFlag,
                                                  level=RoleLevel, energy_index=EnergyIndex} = RoleExp,
              Exp2 = get_vip_exp(RoleID, Exp),
                          %% 多倍经验
                          Exp3 = get_multi_exp(RoleID, Exp2, ?EXP_BUFF_TYPE),
                          %% 经验惩罚
                          Exp4 = get_exp_after_punish(RoleID, MonsterType, MonsterLevel, MonsterRarity, Exp3),
                          case Exp4 =< 0 of
                              true ->
                                  Exp5 = 1;
                              _ ->
                                  Exp5 = Exp4
                          end,
                          AddRate = case TeamLength > 1 of
                            true ->
                              0.1 + RoleLevel/(TotalRoleLv + ((5 - TeamLength) * RoleLevel));
                            false ->
                              0
                          end,
                          Exp6 = trunc((AddRate + 1) * Exp5),
                          mod_map_role:do_monster_dead_add_exp(RoleID, Exp6, MonsterType, Status, KillFlag, EnergyIndex)
                  end,TeamSubList).
%% id,唯一标记，killer_id 杀死怪物的RoleId, map_id 地图id monster_id  怪物id, ,monster_type 怪物类型 
%% monster_tx,monster_ty 怪物死亡坐标，role_exp_list 获取得经验的玩家记录类型r_monster_role_exp
%% team_exp_list  队伍经验记录r_monster_team_exp
%% -record(r_monster_exp,{id,killer_id,map_id,monster_id,monster_type,mnoster_level, monster_rarity, monster_tx,monster_ty,role_exp_list,team_exp_list}).
%% 队伍经验记录,team_sub_list 队伍成员经验记录列表r_monster_team_sub_exp
%% -record(r_monster_team_exp,{team_id,team_sub_list}).
%% role_id 角色id,exp 角色所得经验
%% -record(r_monster_team_sub_exp,{role_id, exp, team_id, team_exp, level,kill_flag,status}).
add_exp6_1(ExpRecord,TeamExpRecord) ->
    #r_monster_exp{map_id=MapID}=ExpRecord,
    #r_monster_team_exp{team_id = TeamId} = TeamExpRecord,
    case global:whereis_name(common_misc:get_team_proccess_name(TeamId))of
        undefined ->
            %% 计算经验时，发送原来是一个队伍的人，解散了队伍，无法从队伍中获取队员信息
            %%　TODO 暂时以列表数据为队员的数据处理，这样会使用没有分配到经验的角色无法获取经验
            %% 后期必须处理
            add_exp6_2(MapID,TeamExpRecord);
        _ ->
            %% TeamName = mod_team_server:get_team_pid_name(TeamId),
            %% TeamMemberList = gen_server:call({global,TeamName},{?TEAM_GET_MEMBER_LIST}),
            %% 将队伍旁边没有打怪的队员加入经验计算
            #r_monster_team_exp{team_id = TeamId,team_sub_list = TeamSubList} = TeamExpRecord,
            TeamMemberList = get_team_memeber_list_by_team_id(TeamSubList),
            TeamSubList2 = do_add_team_member(TeamMemberList, ExpRecord, TeamId, ?DEFAULT_MAX_PIXELS, TeamSubList),
            TeamExpRecord2 = TeamExpRecord#r_monster_team_exp{team_sub_list = TeamSubList2},
            add_exp6_2(MapID,TeamExpRecord2)
    end.
get_team_memeber_list_by_team_id(TeamSubList) ->
    RoleIds = 
        lists:foldl(
          fun(TeamSubRecord,AccRoleIds) ->
                  case AccRoleIds =:= []  of
                      true ->
                          common_misc:team_get_team_member(TeamSubRecord#r_monster_team_sub_exp.role_id);
                      _ ->
                          AccRoleIds
                  end     
          end,[],TeamSubList),
    lists:map(
      fun(RoleID) ->
              Level = 
                  case catch mod_map_role:get_role_attr(RoleID) of
                      {ok,RoleAttr} ->
                          RoleAttr#p_role_attr.level;
                      _ ->
                          1
                  end,
              #p_team_role{
                           role_id = RoleID,
                           level = Level
                          }
      end,RoleIds).
    
    
%% 队伍经验记录,team_sub_list 队伍成员经验记录列表r_monster_team_sub_exp
%% -record(r_monster_team_exp,{team_id,team_sub_list}).
%% role_id 角色id,exp 角色所得经验
%% -record(r_monster_team_sub_exp,{role_id, exp, team_id, team_exp, level,kill_flag,status}).


get_fb_exp_rate(MemberCount,MapID)->
    case mod_scene_war_fb:is_scene_war_fb_map_id(MapID) of
        true->
            mod_scene_war_fb:get_sw_fb_exp_rate(MemberCount,MapID);
        false->
            100
    end.


add_exp6_2(MapID,TeamExpRecord) ->
    #r_monster_team_exp{team_sub_list = TeamSubList} = TeamExpRecord,
    TeamMemberCount = erlang:length(TeamSubList),
    {SumExp,SumLevel} = 
        lists:foldl(fun(TeamSubExpRecord,{AccSumExp,AccSumLevel}) ->
                            AccSumExp2 = TeamSubExpRecord#r_monster_team_sub_exp.exp + AccSumExp,
                            Level = math:pow(TeamSubExpRecord#r_monster_team_sub_exp.level,0.7),
                            AccSumLevel2 = Level + AccSumLevel,
                            {AccSumExp2,AccSumLevel2}
                    end,{0,0},TeamSubList),
    Rate=get_fb_exp_rate(TeamMemberCount,MapID),
    SumExp2 = SumExp * Rate / 100,
    AddRate = case proplists:lookup(TeamMemberCount, ?EXP_RULE) of
                  none ->
                    0;
                  {_Count, ARate} ->
                      ARate
              end,
    SumRate = 1 + AddRate / 100,
    NewSumExp = SumExp2 * SumRate,
    add_exp6_3(TeamExpRecord,SumLevel,NewSumExp).

add_exp6_3(TeamExpRecord,SumLevel,NewSumExp) ->
    #r_monster_team_exp{team_sub_list = TeamSubList} = TeamExpRecord,
    TeamSubList2 = 
        lists:map(fun(TeamSubExpRecord) ->
                          Level = TeamSubExpRecord#r_monster_team_sub_exp.level,
                          Exp = erlang:trunc(NewSumExp * (math:pow(Level,0.7) / SumLevel)),
                          if Exp =:= 0 ->
                                  TeamSubExpRecord#r_monster_team_sub_exp{team_exp = 1};
                             true ->
                                  TeamSubExpRecord#r_monster_team_sub_exp{team_exp = Exp}
                          end
                  end,TeamSubList),
    TeamExpRecord#r_monster_team_exp{team_sub_list = TeamSubList2}.

%% id,唯一标记，killer_id 杀死怪物的RoleId, map_id 地图id monster_id  怪物id, ,monster_type 怪物类型 
%% monster_tx,monster_ty 怪物死亡坐标，role_exp_list 获取得经验的玩家记录类型r_monster_role_exp
%% team_exp_list  队伍经验记录r_monster_team_exp
%% -record(r_monster_exp,{id,killer_id,map_id,monster_id,monster_type,monster_level, monster_rarity, monster_tx,monster_ty,role_exp_list,team_exp_list}).
%% 队伍经验记录,team_sub_list 队伍成员经验记录列表r_monster_team_sub_exp
%% -record(r_monster_team_exp,{team_id,team_sub_list}).
%% role_id 角色id,exp 角色所得经验
%% -record(r_monster_team_sub_exp,{role_id, exp, team_id, team_exp, level,kill_flag,status}).
do_add_team_member([], _ExpRecord, _TeamId, _MaxPixels, TeamSubList) -> TeamSubList;
do_add_team_member([H|T], ExpRecord, TeamId, MaxPixels, TeamSubList) ->
    #r_monster_exp{killer_id = KillerId, map_id = MapId,monster_tx = MosterTx,monster_ty = MosterTy} = ExpRecord,
    RoleID = H#p_team_role.role_id,
    Level = H#p_team_role.level,
    case lists:keyfind(RoleID,#r_monster_team_sub_exp.role_id,TeamSubList) of
        false ->
            case check_team_member(MapId, MosterTx, MosterTy, RoleID, MaxPixels) of
                error ->
                    do_add_team_member(T, ExpRecord, TeamId, MaxPixels, TeamSubList);
                ok ->
                    RoleExp = get_monster_team_sub_exp(RoleID,Level,TeamId,KillerId),
                    do_add_team_member(T, ExpRecord, TeamId, MaxPixels, [RoleExp|TeamSubList])
            end;
        _ ->
            do_add_team_member(T, ExpRecord, TeamId, MaxPixels, TeamSubList)
    end.
get_monster_team_sub_exp(RoleID,Level,TeamId,KillerId) ->
    KillerTeamId = 
        case mod_map_team:get_role_team_info(KillerId) of
            {ok,MapTeamInfo} ->
                MapTeamInfo#r_role_team.team_id;
            _ ->
                0
        end,
    Status = 
        case mod_map_role:get_role_base(RoleID) of
            {ok, RoleBase} ->
                RoleBase#p_role_base.status;
            {error,_Reason} ->
                0
        end,
    KillFlag = if TeamId =:= KillerTeamId 
                      andalso TeamId =/= 0
                      andalso KillerTeamId =/= 0 ->
                      true;
                  KillerId =:= RoleID ->
                      true;
                  true ->
                      false
               end,
    #r_monster_team_sub_exp{role_id = RoleID, 
                            exp = 0,
                            team_id = TeamId, 
                            team_exp = 0,
                            level = Level,
                            kill_flag = KillFlag,
                            status = Status,
                            energy_index=1
                           }.

check_team_member(MapID, MonsterTX, MonsterTY, RoleID, MaxPixels) ->
    case mod_map_actor:get_actor_txty_by_id(RoleID, role) of
        undefined ->
            error;
        {TX, TY} ->
            check_team_member2(MapID, MonsterTX, MonsterTY, RoleID, MaxPixels, TX, TY)
    end.
check_team_member2(_MapId, MosterTx, MosterTy, _RoleId, MaxPixels, Tx, Ty) ->
    {MPx, MPy} = common_misc:get_iso_index_mid_vertex(MosterTx, 0, MosterTy),
    {Px, Py} = common_misc:get_iso_index_mid_vertex(Tx, 0, Ty),
    {MaxPx,MaxPy} = MaxPixels,
    if erlang:abs(MPx - Px) < MaxPx andalso erlang:abs(MPy - Py) < MaxPy ->
            ok;
       true ->
            error
    end.

%% 处理多倍经验状态
get_multi_exp(RoleID, Exp, BuffType) ->
    case mod_map_role:get_role_base(RoleID) of
        {ok,RoleBase} ->
            get_multi_exp2(RoleID,Exp,BuffType,RoleBase);
        _ ->
            Exp
    end.

get_multi_exp2(RoleID,Exp,BuffType,RoleBase) ->
    #p_role_base{family_id=FamilyID, buffs = Buffs, faction_id=FactionID} = RoleBase,
    if erlang:is_list(Buffs) andalso Buffs =/= [] ->
            NewExp =
                lists:foldl(
                  fun(Type,AccExp) ->
                          case lists:keyfind(Type,#p_actor_buf.buff_type,Buffs) of
                              false ->
                                  AccExp;
                              Buff ->
                                  AccExp+get_multi_exp3(RoleID,Exp,RoleBase,Buff)
                          end
                  end, 0, BuffType),
            get_multi_exp5(RoleID, FamilyID, FactionID, Exp) + NewExp;
       true ->
            get_multi_exp5(RoleID, FamilyID, FactionID, Exp)
    end.
    
get_multi_exp3(RoleID,Exp,RoleBase,Buff) ->
    BufId = Buff#p_actor_buf.buff_id,
    case  mod_skill_manager:get_buf_detail(BufId) of
        {ok, Buf} ->
            get_multi_exp4(RoleID,Exp,RoleBase,Buff,Buf);
        {error, not_found} ->
            Exp
    end.
get_multi_exp4(_RoleId,Exp,_RoleBase,_Buff,Buf) ->
    if Buf#p_buf.absolute_or_rate =:= 0 ->
            Exp;
       true ->
            Value = Buf#p_buf.value,
            (Exp * Value)/10000
    end.
get_multi_exp5(_RoleID, FamilyID, FactionID, Exp) ->
    %% buff 系统功能（好友、组队、师徒） 等等都已经计算完了，接下来计算系统Buff            
    case erlang:get({family, FamilyID}) of
        undefined ->
            Exp2 = Exp;
        Multiple ->
            Exp2 = Exp * (Multiple-1) + Exp
    end,
    %% 国家buff
    case erlang:get({faction, FactionID}) of
        undefined ->
            Exp3 = Exp2;
        Multiple2 ->
            Exp3 = Exp * (Multiple2-1) + Exp2
    end,
    %%
    case erlang:get(world_system_buff) of
        undefined ->
            Exp3;
        Multiple3 ->
            Exp * (Multiple3-1) + Exp3
    end.

-define(VIP_MULTI_EXP_TYPE, 1050).
get_vip_exp(RoleID, Exp) ->
    %% VIP在安全挂机地图可以获得全部经验
	MapID = mgeem_map:get_mapid(),
	[SafeMapIDList] = common_config_dyn:find(etc, vip_safe_map),
	IsSafeMap = lists:member(MapID, SafeMapIDList),
	case IsSafeMap andalso mod_vip:is_role_vip(RoleID) of
		true ->
			case mod_map_role:get_role_base(RoleID) of
				{ok,#p_role_base{buffs=Buffs}} ->
					case lists:any(fun(#p_actor_buf{buff_type=BuffType}) ->
										   BuffType =:= ?VIP_MULTI_EXP_TYPE
								   end, Buffs) of
						true ->
							VipLevel = mod_vip:get_role_vip_level(RoleID),
							[VipMultiple] = common_config_dyn:find(etc, {safe_map_vip_multiple,VipLevel}),
							Exp * VipMultiple;
						false ->
							Exp
					end;
				_ ->
					Exp
			end;
		_ ->
			Exp
	end.

%%计算惩罚之后获得的经验，等级惩罚、防沉迷惩罚以及精力
get_exp_after_punish(RoleID, MonsterTypeID, MonsterLevel, MonsterRarity, Exp) ->
    LevelIndex = mod_map_monster:get_role_level_index(RoleID, MonsterTypeID, MonsterLevel, MonsterRarity),
    %% FCMIndex = common_misc:get_role_fcm_cofficient(RoleID),
    %% modifed by liuwei 不计算防沉迷扣经验，被防沉迷时直接不能登录游戏
    FCMIndex = 1,
    common_tool:ceil(Exp*LevelIndex*FCMIndex).
