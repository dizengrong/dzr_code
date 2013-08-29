%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     网关中对地图的特殊处理
%%% @end
%%% Created : 2011-7-14
%%%-------------------------------------------------------------------
-module(mgeeg_map_handler).

-include("mgeeg.hrl"). 

-export([update_map_info/4,
         del_sw_fb_buffs/1]).

%% ====================================================================
%% API functions
%% ====================================================================

update_map_info(RoleId,RoleBase1,RoleAttr1,RolePos1)->
    RolePos2 = do_update_map_info_of_fb(RoleId,RoleBase1,RolePos1),
    do_check_map_info(RoleId, RoleBase1, RoleAttr1, RolePos2).


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------


%% @doc 在副本中下线的处理， 返回新的RolePos
%% add by caochuncheng
%% modified by wuzesen
do_update_map_info_of_fb(RoleId,RoleBase,RolePos) ->
    #p_role_pos{map_id = MapId} = RolePos,
    IsSceneFbMapId = is_scenefb_map_id(MapId),
    IsArenaMapId = is_arena_map_id(MapId),
    IsFamilyWar = is_family_war_map_id(MapId),
    if 
        MapId =:= 10300 ->  %%宗族地图
            RolePos;
        MapId =:= 10001 orelse MapId =:= 10250 ->  %% 新手村或是桃花涧 
            RolePos;
        MapId =:= ?COUNTRY_TREASURE_MAP_ID orelse MapId =:= 10501 
		  orelse MapId =:= 10502 orelse MapId =:= 10507 
		  orelse MapId =:= 10508 orelse MapId =:= 10509->  %%回到京城或太平村
            do_update_map_info_final(RoleId,RoleBase,RolePos);
        IsSceneFbMapId =:= true ->
            do_update_map_info_of_sw_fb(RoleId, RoleBase, RolePos);
        IsArenaMapId =:= true->
            do_update_map_info_of_arena(RoleId, RoleBase, RolePos);
        IsFamilyWar ->%%如果下线了 直接踢回京城 无论宗族战是否还在继续
            do_update_map_info_final(RoleId,RoleBase,RolePos);
		MapId =:= 10505 ->
			do_update_map_info_of_10505(RoleId,RoleBase,RolePos);
		true ->
			do_update_map_info_other(RoleId, RoleBase, RolePos, MapId)
	end.

%%@doc 最后的处理，回到京城
do_update_map_info_final(RoleId,RoleBase,RolePos) ->
    #p_role_base{faction_id = FactionId} = RoleBase,
    MapId = common_misc:get_home_map_id(FactionId),
    do_update_map_info_final_2(RoleId,RoleBase,MapId,RolePos).

%%@doc 最后的处理，回到太平村、或涿鹿、或京城
do_update_map_info_final(RoleId, RoleBase, Level, RolePos) ->
    #p_role_base{faction_id = FactionID} = RoleBase,
    case Level < 10 of
        true ->
            MapID = common_misc:get_newcomer_mapid(FactionID);
        _ ->
            #p_role_pos{map_id = MapId} = RolePos,
            IsInHeroFbMap = is_hero_fb_map_id(MapId),
            %% 当玩家低于20级，而且在境界副本中离线后，就返回涿鹿
            if IsInHeroFbMap andalso Level < 20 ->
                   MapID = common_misc:get_newcomer_mapid(FactionID);
               true ->
                   MapID = common_misc:get_home_map_id(FactionID)
            end
    end,
    do_update_map_info_final_2(RoleId,RoleBase,MapID,RolePos).

do_update_map_info_final_2(RoleId,RoleBase,MapIdParam,RolePos)->    
    #p_role_base{faction_id = FactionID} = RoleBase,
    case common_misc:get_born_info_by_map(MapIdParam) of
        {MapId,Tx,Ty} ->
            next;
        _ ->
            JingDuMapId = common_misc:get_home_map_id(FactionID),
            {MapId,Tx,Ty} = common_misc:get_born_info_by_map(JingDuMapId)
    end,
            
    Pos = #p_pos{tx = Tx, ty = Ty},
    MapProcessName = common_misc:get_common_map_name(MapId),
    NewRolePos = RolePos#p_role_pos{map_id = MapId,pos = Pos},
    ReturnRolePos = update_role_new_pos_in_db_2(RoleId,NewRolePos,MapProcessName,RolePos),
    case common_config_dyn:find(pve_fb,fb_buy_buff_list) of        
        []->                                                             
            ReturnRolePos;                                               
        [BuffIdList]->                     
            #p_role_base{buffs=RoleBuffs1} = RoleBase,
            case RoleBuffs1 of
                []->
                    ReturnRolePos;
                _ ->
                    RoleBuffs2 = del_sw_fb_buffs(RoleBuffs1,BuffIdList),          
                    {ok,ReturnRolePos,RoleBase#p_role_base{buffs=RoleBuffs2}}    
            end
    end.                           

%% 藏宝图副本
do_update_map_info_of_10505(RoleId,RoleBase,RolePos) ->
    case global:whereis_name(RolePos#p_role_pos.map_process_name) of
        undefined ->
            #p_role_base{faction_id = FactionId} = RoleBase,
            MapId = common_misc:get_home_map_id(FactionId),
            {_MapId,Tx,Ty} = common_misc:get_born_info_by_map(MapId),
            Pos = #p_pos{tx = Tx, ty = Ty},
            NewRolePos = RolePos#p_role_pos{map_id = MapId,pos = Pos},
            update_role_new_pos_in_db(RoleId,NewRolePos,RolePos);
        _ ->
            RolePos
    end.

%%删除场景副本中购买的BUFF
del_sw_fb_buffs(RoleBuffs1)->
    case common_config_dyn:find(pve_fb,fb_buy_buff_list) of        
        []->                                                             
            RoleBuffs1;                                               
        [BuffIdList]->                     
            del_sw_fb_buffs(RoleBuffs1,BuffIdList)
    end.  
del_sw_fb_buffs(RoleBuffs1,BuffIdList)->
    lists:foldl(                                             
      fun(E,AccIn)->                                         
              #p_actor_buf{buff_id=BuffId} = E,              
              case lists:member(BuffId, BuffIdList) of       
                  true-> AccIn;                              
                  _ ->                                       
                      [E|AccIn]                              
              end                                            
      end, [], RoleBuffs1).

%% 场景大战副本
do_update_map_info_of_sw_fb(RoleId, RoleBase, RolePos) ->
    case db:dirty_read(?DB_SCENE_WAR_FB, RoleId) of
        {'EXIT', Error} ->
            ?ERROR_MSG("~ts,Error=~w",["场景大战副本地图的记录出错",Error]),
            do_update_map_info_final(RoleId,RoleBase,RolePos);
        [] ->
            do_update_map_info_final(RoleId,RoleBase,RolePos);
        [SceneWarFbRecord] when erlang:is_record(SceneWarFbRecord,r_scene_war_fb) ->
            #r_scene_war_fb{map_id = MapId,pos = Pos,fb_map_name = FbMapProcessName} = SceneWarFbRecord,
            [#p_role_ext{last_offline_time = LastOfflineTime}] = db:dirty_read(?DB_ROLE_EXT,RoleId),
            IsFbMapProcess = 
                case global:whereis_name(FbMapProcessName) of
                    undefined ->
                        false;
                    _ ->
                        true
                end,
            [KeepOfflineSeconds] = common_config_dyn:find(scene_war_fb,sw_fb_keep_offline_seconds),
            NowSeconds = common_tool:now(),
            if RoleBase#p_role_base.team_id =/= 0 andalso IsFbMapProcess =:= true->
                    RolePos;
               (KeepOfflineSeconds + LastOfflineTime) >= NowSeconds andalso IsFbMapProcess =:= true->
                    RolePos;
               true ->
                    MapProcessName = common_misc:get_common_map_name(MapId),
                    NewRolePos = RolePos#p_role_pos{map_id = MapId,pos = Pos},
                    update_role_new_pos_in_db_2(RoleId,NewRolePos,MapProcessName,RolePos)
            end;
        _Other ->
            do_update_map_info_final(RoleId,RoleBase,RolePos)
    end.

%% 竞技场副本
do_update_map_info_of_arena(RoleId, RoleBase, RolePos)->
    case db:dirty_read(?DB_ROLE_ARENA,RoleId) of
        [#r_role_arena{return_map_id=ReturnMapID,return_pos=ReturnPos}] when ReturnMapID>0 ->
            case is_arena_map_id(ReturnMapID) of
                true->
                    do_update_map_info_final(RoleId,RoleBase,RolePos);
                _ ->
                    NewRolePos = RolePos#p_role_pos{role_id=RoleId,map_id=ReturnMapID,pos=ReturnPos},
                    update_role_new_pos_in_db(RoleId,NewRolePos,RolePos)
            end;
        _ ->
            %%好吧，踢回京城
            do_update_map_info_final(RoleId,RoleBase,RolePos)
    end.


%% @doc 判断地图是否存在
do_check_map_info(RoleId, RoleBase, RoleAttr, RolePos) ->
    case db:transaction(
           fun() ->
                   [RolePos2] = db:read(?DB_ROLE_POS, RoleId, write),
                   RolePos2
           end)
        of
        {atomic, RolePos2} ->
            %% 地图不在了的话，踢出副本
            case ?IS_SOLO_FB(RolePos2#p_role_pos.map_id) orelse 
					 global:whereis_name(RolePos2#p_role_pos.map_process_name) =/= undefined of
                true ->
                    RolePos;
                _ ->
                    do_update_map_info_final(RoleId, RoleBase, RoleAttr#p_role_attr.level, RolePos)
            end;
        {aborted, Error} ->
            ?ERROR_MSG("do_check_map_info, error: ~w", [Error]),
            RolePos
    end.


%% 在外国出生则传送回边城
do_update_map_info_other(RoleId, RoleBase, RolePos, MapId) ->
    #p_role_base{faction_id=FactionID} = RoleBase,
    case common_misc:if_in_self_country(FactionID, MapId) of
        true ->
            RolePos;
        _ ->
            case if_in_neutral_area(MapId) of
                true ->
                    RolePos;
                _ ->
                    {DestMapID, TX, TY} = get_biancheng_born_point(FactionID),
                    NewRolePos = RolePos#p_role_pos{map_id=DestMapID,pos=#p_pos{tx=TX, ty=TY} },
                    
                    update_role_new_pos_in_db(RoleId,NewRolePos,RolePos)
            end
    end.



%%数据库中修改地图信息,事务
update_role_new_pos_in_db(RoleId,NewRolePos,OldRolePos)->
    #p_role_pos{map_id=NewMapID} = NewRolePos,
    MapProcessName = common_misc:get_common_map_name(NewMapID),
    update_role_new_pos_in_db_2(RoleId,NewRolePos,MapProcessName,OldRolePos).
    
update_role_new_pos_in_db_2(RoleId,RolePos,MapProcessName,OldRolePos) ->
    case db:transaction(
           fun() -> 
                   [#p_role_pos{map_process_name=OldName}] = db:read(?DB_ROLE_POS, RoleId, write),
                   R = RolePos#p_role_pos{role_id=RoleId, map_process_name=MapProcessName, old_map_process_name=OldName},
                   db:write(?DB_ROLE_POS, R, write)
           end) of
        {atomic, ok} ->
            RolePos#p_role_pos{role_id=RoleId, map_process_name=MapProcessName};
        {aborted, Error} ->
            ?ERROR_MSG("update_role_map_process_name, error: ~w", [Error]),
            OldRolePos
    end.


%%@doc 判断是否是场景副本的地图
is_scenefb_map_id(MapId)->
    [SwFbMapIdList] = common_config_dyn:find(scene_war_fb,sw_fb_mcm),
    case lists:keyfind(MapId,#r_sw_fb_mcm.fb_map_id,SwFbMapIdList) of
        false ->
            false;
        #r_sw_fb_mcm{fb_map_id = MapId} ->
            true;
        _ ->
            false
    end.


%%@doc 判断是否是竞技场地图
is_arena_map_id(MapId)->
    [MapList] = common_config_dyn:find(arena, arena_map_list),
    lists:keyfind(MapId,1,MapList) =/= false.

%%@doc 检测是否是宗族战地图
is_family_war_map_id(MapID) ->
    MapID =:= 10301.
%% @doc 获取边城出生点
get_biancheng_born_point(FactionID) ->
	MapID = common_misc:get_home_map_id(FactionID),
%%     MapID = 10000 + FactionID * 1000 + 105,
    common_misc:get_born_info_by_map(MapID).


%% @doc 是否在中立区或副本
if_in_neutral_area(MapID) ->
    MapID div 1000 =:= 10.


is_hero_fb_map_id(DestMapID)-> 
    mod_hero_fb:is_hero_fb_map_id(DestMapID).

