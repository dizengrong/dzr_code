%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc hook地图中玩家的各种信息
%%%
%%% @end
%%% Created :  6 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(hook_map_role).

-include("mgeem.hrl").

%% API
-export([
         role_dead/4,
         role_pos_change/4,
         role_been_dizzy/3,
         kick_role/1,
         role_exit/1,
         attack/3,
         be_attacked/4,
         role_quit/1,
         role_offline/1,
         role_online/7,
         map_enter/3,
         hook_change_map_by_call/2,
         notify_family_contribute_change/2,
         done_family_ybc/2,
         sex_change/2,
         role_reduce_hp/3,
         before_role_quit/3,
         vip_upgrade/3
        ]).

-define(map_handler(MapID), (cfg_map_module:module(MapID))).

%% 角色宗族拉镖完成了
done_family_ybc(RoleID, _RoleName) ->
    ?TRY_CATCH( mod_accumulate_exp:role_do_family_ybc(RoleID) ),
    ok.


%%角色死亡
%% RoleID  死亡角色ID
%% SrcActorID 谁导致角色死亡
%% 导致角色死亡的actor的类型: role monster pet
role_dead(RoleID, RoleMapInfo, SActorID, SActorType) ->
    MapState = mgeem_map:get_state(),
    #map_state{mapid=CurrentMapId} = MapState,
    #p_map_role{pos=Pos} = RoleMapInfo,
    #p_pos{tx=TX, ty=TY} = Pos,
    %% 商贸玩家死亡，删除商贸商票处理
    if MapState#map_state.mapid =:= ?COUNTRY_TREASURE_MAP_ID ->
            next;
       true ->
            catch mod_trading:hook_role_dead(RoleID,RoleMapInfo,SActorID,SActorType)
    end,
    FuncList = [
                fun()-> mod_arena:hook_role_dead(RoleID,RoleMapInfo,CurrentMapId) end,
                fun()-> mod_hero_fb:hook_role_dead(RoleID) end,
                fun()-> mod_examine_fb:hook_role_dead(RoleID) end,
                fun()-> mod_scene_war_fb:hook_role_dead(RoleID,RoleMapInfo) end,
                fun()-> mod_nationbattle_fb:hook_role_dead(RoleID, SActorID, SActorType) end,
				fun()-> mod_crown_arena_cull_fb:hook_role_dead(RoleID, SActorID, SActorType) end,
                fun()-> mod_warofking:hook_role_dead(RoleID, SActorID, SActorType) end,
                fun()-> mod_warofmonster:hook_role_dead(RoleID, SActorID, SActorType) end,
				fun()-> mod_crown_arena_fb:hook_role_dead(RoleID, SActorID, SActorType) end,
                fun()-> mod_bigpve_fb:hook_role_dead(RoleID, SActorID, SActorType) end,
                fun()-> mod_country_treasure:hook_role_dead(RoleID, SActorID, SActorType) end,
				fun()-> mod_map_event:notify({role, RoleID}, {role_dead, SActorID, SActorType}) end,
				fun()-> mod_trading:hook_role_dead(RoleID, SActorID, SActorType) end,
                fun()-> mod_tower_fb:hook_role_dead([RoleID, SActorID, SActorType]) end
               ],
    [?HOOK_CATCH(F) || F <- FuncList],

    %% 安全区判断
	Flag = lists:member({TX,TY}, mcm:reado_tiles(CurrentMapId)),
    case SActorType of
        role ->
            case mod_map_actor:get_actor_mapinfo(SActorID, SActorType) of
                undefined ->
                    ignore;
                SRoleMapInfo ->
                    role_dead2(RoleMapInfo, SRoleMapInfo, MapState, Flag)
            end;
        pet ->
             case mod_map_actor:get_actor_mapinfo(SActorID, SActorType) of
                 undefined ->
                     ignore;
                 #p_map_pet{role_id=SRoleID} = _PetMapInfo ->
                     case mod_map_actor:get_actor_mapinfo(SRoleID, role) of
                         undefined ->
                             ignore;
                         SRoleMapInfo ->
                             role_dead2(RoleMapInfo, SRoleMapInfo, MapState, Flag)
                     end
            end;
        _ ->
            ignore
    end,
    ok.

role_dead2(RoleMapInfo, SRoleMapInfo, MapState, Flag) ->
    #map_state{mapid=MapID} = MapState,
    #p_map_role{role_id=RoleID, role_name=RoleName, family_id=FamilyID, faction_id=FactionID, gray_name=GrayName} = RoleMapInfo,
    #p_map_role{role_id=SRoleID, role_name=SRoleName, family_id=SFamilyID, faction_id=SFactionID} = SRoleMapInfo,    

    case common_config_dyn:find(fb_map,MapID) of
        [#r_fb_map{is_dead_letter=false}] ->
            Flag2 = true;
        _ ->
            Flag2 = Flag
    end,
    %%计算是否可能会产生功勋值
    mod_gongxun:change(RoleID, FactionID, FamilyID, SRoleID, SFactionID, SFamilyID, Flag2),
    %%死亡的一些广播
    mod_dead_broadcast:role_killed(RoleID, RoleName, FactionID,  SRoleID, SRoleName, SFactionID, MapID, Flag2),
    %%PK计算
    mod_pk:kill(RoleID, FactionID, GrayName, SRoleID, SFactionID, Flag2),
    %%添加仇人
    add_enemy(RoleID, SRoleID, role, Flag2, FactionID),
    mod_role_busy:stop(RoleID),
    ok.

%% @doc 角色位置发生了变化
role_pos_change(RoleID, TX, TY, DIR) ->
    mod_role_busy:stop(RoleID),
    %% 清除角色特殊状态
    mod_map_role:clear_role_spec_state(RoleID),
    mod_map_role:clear_role_spec_buff_when_move(RoleID),
	mod_map_event:notify({role, RoleID}, {role_pos_change, TX, TY, DIR}),
    ok.


%%角色被人击晕
role_been_dizzy(RoleID, _SrcActorID, _SrcActorType) ->
    mod_role_busy:stop(RoleID),
    %%mod_warofcity:break(RoleID),
    ok.


%%角色被T下线
kick_role(RoleID) ->
    mod_role_busy:stop(RoleID),
    ok.

%%角色离开地图
role_exit(RoleID) ->
    mod_role_busy:stop(RoleID),
	mod_crown_arena_fb:role_exit(RoleID),
	mod_crown_arena_cull_fb:role_exit(RoleID),
    ok.

%% @doc 退出地图前hook，该hook修改base、attr等仍有效
before_role_quit(RoleID, MapID, _DestMapID) ->
    FuncList = [
                fun() -> mod_mission_fb:hook_role_before_quit(RoleID)           end,
                fun() -> mod_pve_fb:hook_role_before_quit(RoleID)               end,
                fun() -> mod_arena:hook_role_before_quit(RoleID)                end,
                fun() -> mod_examine_fb:hook_role_before_quit(RoleID)           end,
                fun() -> mod_warofking:hook_role_before_quit(RoleID)            end,
                fun() -> mod_warofmonster:hook_role_before_quit(RoleID)         end,
                fun() -> mod_bigpve_fb:hook_role_before_quit(RoleID)            end,
                fun() -> mod_guard_fb:hook_role_before_quit(RoleID)             end,
                fun() -> mod_nationbattle_fb:hook_role_before_quit(RoleID)      end,
                fun() -> mod_country_treasure:hook_role_before_quit(RoleID)     end,
				fun() -> mod_mirror_fb:hook_role_before_quit(RoleID, MapID)     end,
                fun() -> mod_spring:hook_role_quit(RoleID)                      end,
				fun() -> mod_map_event:notify({role, RoleID}, before_role_quit) end,
                fun() -> ?map_handler(MapID):handle({before_role_quit, RoleID}) end
               ],
    [?HOOK_CATCH(F) || F <- FuncList],
    ok.

role_quit(RoleID) ->
    MapID = mgeem_map:get_mapid(),
    FuncList = [
                fun() -> mod_role_busy:stop(RoleID)                      end,
                fun() -> mod_hero_fb:hook_role_quit(RoleID)              end,
				fun() -> mod_crown_arena_cull_fb:hook_role_quit(RoleID)  end,
                fun() -> mod_examine_fb:hook_role_quit(RoleID)           end,
                fun() -> mod_mine_fb:hook_role_quit(RoleID)              end,
                fun() -> mod_mission_fb:hook_role_quit(RoleID)           end,
                fun() -> mod_arena:hook_role_quit(RoleID)                end,
                fun() -> mod_nationbattle_fb:hook_role_quit(RoleID)      end,
                fun() -> mod_crown_arena_fb:hook_role_quit(RoleID)       end,
                fun() -> mod_country_treasure:hook_role_quit(RoleID)     end,
                fun() -> mod_pve_fb:hook_role_quit(RoleID)               end,
                fun() -> mod_bigpve_fb:hook_role_quit(RoleID)            end,
                fun() -> mod_tower_fb:hook_role_quit(RoleID)             end,
                fun() -> mod_warofking:hook_role_quit(RoleID)            end,
                fun() -> mod_warofmonster:hook_role_quit(RoleID)         end,
                fun() -> ?map_handler(MapID):handle({role_quit, RoleID}) end
               ],
    [?HOOK_CATCH(F) || F <- FuncList],
    ok.


%% @doc 角色发起攻击操作
attack(RoleID, TargetAttr, SkillBaseInfo) ->
    mod_role_busy:stop(RoleID),
    %%mod_warofcity:break(RoleID),
    %% 减攻击装备耐久
    mod_map_role:reduce_equip_endurance(RoleID, true),
    %% 清除角色某些特殊BUFF，如隐身，特殊的持续加血
    mod_map_role:clear_role_spec_buff_when_attack(RoleID),
    %% 更新角色攻击状态时间
	case is_record(TargetAttr, actor_fight_attr) of
		true ->
			TargetType = mof_common:actor_type_atom(TargetAttr#actor_fight_attr.actor_type),
			TargetID   = TargetAttr#actor_fight_attr.actor_id;
		_ ->
			TargetType = undefined,
			TargetID   = undefined
	end,
    mod_map_role:update_role_fight_time(RoleID, TargetType, TargetID, SkillBaseInfo#p_skill.effect_type),
	mod_map_event:notify({role, RoleID}, attack),
    ok.

%% @doc 角色被攻击
be_attacked(RoleID, SActorID, SActorType, SkillEffectType) ->
    %% 更新角色攻击状态时间
    mod_map_role:update_role_fight_time(RoleID, SActorType, SActorID, SkillEffectType),
    %% 清除打坐状态
    mod_map_role:clear_role_spec_state(RoleID),
    %% 减装备耐久度
    mod_map_role:reduce_equip_endurance(RoleID, false),
    ok.

%% 添加仇人
add_enemy(RoleID, SrcActorID, SrcActorType, Flag, FactionID) ->
    case global:whereis_name(mod_friend_server) of
        undefined ->
            ignore;
        _ ->
            IsWarOfFaction = mod_map_role:is_in_waroffaction(FactionID),
            global:send(mod_friend_server, {add_enemy, RoleID, SrcActorID, SrcActorType, Flag, IsWarOfFaction})
    end.

%% @doc 进入地图
map_enter(RoleID, RoleMapInfo, MapID) ->
    FuncList = [
                fun()-> mod_map_role:hook_role_enter_map(RoleID, MapID) end, 
                fun()-> mod_country_treasure:hook_role_map_enter(RoleID,MapID) end, 
                fun()-> mod_scene_war_fb:hook_role_enter_map(RoleID, MapID) end, 
                fun()-> mod_hero_fb:hook_role_enter(RoleID, MapID)  end,
                fun()-> mod_examine_fb:hook_role_enter(RoleID, MapID)  end, 
                fun()-> mod_spring:hook_role_enter(RoleID, MapID)  end,
                fun()-> mod_guard_fb:hook_role_enter(RoleID, MapID)  end, 
                fun()-> mod_mine_fb:hook_role_enter(RoleID, MapID)  end, 
                fun()-> mod_mission_fb:hook_role_enter(MapID)   end, 
                fun()-> mod_arena:hook_role_enter(RoleID, MapID)  end, 
                fun()-> mod_nationbattle_fb:hook_role_enter(RoleID, MapID)  end, 
                fun()-> mod_crown_arena_cull_fb:hook_role_enter(RoleID, MapID)  end,
				fun()-> mod_crown_arena_fb:hook_role_enter(RoleID, MapID)  end, 
				fun()-> mod_nimbus:hook_role_enter(RoleID, RoleMapInfo,MapID)  end, 
                fun()-> mod_warofking:hook_role_enter(RoleID, MapID)  end, 
                fun()-> mod_warofmonster:hook_role_enter(RoleID, MapID)  end, 
                fun()-> mod_bigpve_fb:hook_role_enter(RoleID, MapID)  end,
                fun()-> mod_tower_fb:hook_role_enter(RoleID, MapID) end, 
                fun()-> mod_pve_fb:hook_role_enter(RoleID, MapID)  end, 
				fun()-> mod_cang_bao_tu_fb:hook_role_enter_map(RoleID, MapID)  end,
				fun()-> mod_mirror_fb:hook_role_map_enter(RoleID, MapID) end,    
                fun()-> mod_driver:hook_role_enter(RoleID, MapID)  end,
                fun()-> (cfg_map_module:module(MapID)):handle({role_enter, RoleID, MapID}) end
               ],
    [?HOOK_CATCH(F) || F <- FuncList],

    catch mod_map_bonfire:send_bonfire_info(RoleID),
    ok.

%% @doc 角色下线hook
role_offline(RoleID) ->
	MapID = mgeem_map:get_mapid(),
    {ok,#p_role_base{faction_id = FactionId}} = mod_map_role:get_role_base(RoleID), 
    {ok,#p_role_attr{jingjie = Jingjie}} = mod_map_role:get_role_attr(RoleID), 
    %%下线时检查，避免一个月没登录的玩家登陆后加入排行榜后会再被清除掉
    catch check_unactivity_role_back(RoleID),
    %% 交易角色下线处理
    catch mod_exchange:role_offline(RoleID),
	catch mod_crown_arena_fb:role_offline(RoleID),
    %% 摊位角色下线处理
    catch mod_stall:role_offline(RoleID),
	catch mod_crown_arena_cull_fb:role_offline(RoleID),
    %% 下线提醒
    catch offline_nofity(RoleID),
    %% 组队下线处理 以及 队友招募下线处理
    catch hook_map_team:role_offline(RoleID),
    %% 场景大战副本
    catch mod_scene_war_fb:hook_role_offline(RoleID),
    catch mod_cang_bao_tu_fb:hook_role_offline(RoleID),
    catch mod_spring:hook_role_offline(RoleID),
    catch mod_bomb_fb:handle({role_offline, RoleID}),
    %% 当前国家玩家在线榜
    case common_config_dyn:find(etc,do_faction_online_role_rank_map_id) of
        [FactionOnlineRoleRankMapId] ->
            catch global:send(common_map:get_common_map_name(FactionOnlineRoleRankMapId),
                              {mod_role2,{admin_quit_faction_online_rank,
                                          {RoleID,FactionId,FactionOnlineRoleRankMapId}}});
        _ ->
            ignore
    end,
	MinArenaTitle = mod_arena_misc:get_min_arena_title(),
    if
        Jingjie>=MinArenaTitle->
            case mod_map_role:get_role_map_ext_info(RoleID) of
                {ok,#r_role_map_ext{arena_chllg_status=Status}} when  Status=:=1 -> %%正在被百强挑战的过程中下线了
                    ?TRY_CATCH( global:send(mod_arena_manager,{to_chllger_offline,RoleID}),Err2 );
                _ ->
                    ignore
            end,
            ?TRY_CATCH( global:send(mod_arena_manager,{update_hero_online,RoleID,false}),Err3 );
        true->
            ignore
    end,
	catch mod_mirror_fb:hook_role_offline(RoleID, MapID),
    ok.

%% @doc 角色上线hook
role_online(RoleID, PID, RoleBase, RoleAttr, MapID, Line, IsFirstEnter) ->
	mod_map_role:del_role_exit_game_mark(RoleID),
	#p_role_base{role_name=RoleName, faction_id=FactionID, family_id=FamilyID, team_id=TeamID} = RoleBase,
    #p_role_attr{level=Level, office_id=OfficeID,jingjie=Jingjie} = RoleAttr,
	case IsFirstEnter of
		true ->
    		?TRY_CATCH( mod_accumulate_exp:role_online(RoleID) ),
    		%% 注册玩家分线
    		common_misc:set_role_line_by_id(RoleID, Line),
		    %% 相关上线提醒
		    online_nofity(RoleID, RoleBase, RoleAttr),
		    %% 注册宗族进程
		    global:send(mod_family_manager, {role_online, RoleID, FamilyID}),
		    %% 发送排行榜配置
		    global:send(mgeew_ranking, {send_ranking_to_role, RoleID}),
			 %% 
		    global:send(mgeew_crown_arena_server, {role_online, RoleID}),
		    %% 场景大战副本
		    catch mod_scene_war_fb:hook_role_online(RoleID),
		    %% 组队重新登陆处理
		    catch hook_map_team:role_online(RoleID,TeamID),
		    %% 好友离线请求
		    gen_server:cast({global, mod_friend_server}, {offline_request, RoleID, Line}),
		    %% 技能上次使用登时
		    mod_skill:init_skill_last_use_time(RoleID, Line),
		    %% 商贸活动初始化
		    catch mod_trading:hook_first_enter_map(RoleID,RoleBase),
		    %% 对玩家宗族技能的校验
		    catch mod_skill:verify_family_skill(RoleID,RoleBase),
            %% 自动召唤宠物
            catch mod_map_pet:auto_summon_role_pet(RoleID, mgeem_map:get_state()),
		    %% 有无系统BUFF
		    catch global:send(mgeew_system_buff, {role_online, RoleID, PID, FactionID, FamilyID}),
		    %% 离线官职指派请求
		    catch common_office:role_online(RoleID),
		    %% 上线广播
		    mod_role2:online_broadcast(RoleID, RoleName, PID, OfficeID, FactionID, Level),
		    %% 当前国家在线玩家榜
		    case common_config_dyn:find(etc,do_faction_online_role_rank_map_id) of
		        [FactionOnlineRoleRankMapId] ->
		            catch global:send(common_map:get_common_map_name(FactionOnlineRoleRankMapId),
		                              {mod_role2,{admin_join_faction_online_rank,
		                                          {RoleID,RoleName,FactionID,RoleAttr#p_role_attr.level,FactionOnlineRoleRankMapId}}});
		        _ ->
		            ignore
		    end,
			MinArenaTitle = mod_arena_misc:get_min_arena_title(),
		    if
		        Jingjie>=MinArenaTitle->
					?TRY_CATCH( global:send(mod_arena_manager,{update_hero_online,RoleID,true}),Err2 );
		        true->
		            ignore
		    end,
			catch mod_pk:login_pk_init(RoleID),
		    catch mod_cang_bao_tu_fb:hook_role_online(RoleID),
			catch mod_mirror_fb:hook_role_online(RoleID, MapID);
		_ ->
			LastUseTime  = mof_fight_time:get_last_skill_time(role, RoleID),
            LastUseTime2 = lists:zf(fun
                ({SkillID, UseTime}) when is_integer(SkillID) ->
                    {true, #p_skill_time{skill_id=SkillID, last_use_time=UseTime}};
                (_) ->
                    false
            end, LastUseTime),
            DataRecord = #m_skill_use_time_toc{skill_time=LastUseTime2, server_time=common_tool:now()},
            common_misc:unicast(Line, RoleID, ?DEFAULT_UNIQUE, ?SKILL, ?SKILL_USE_TIME, DataRecord)
	end,
    %%篝火
    mod_map_bonfire:send_bonfire_info(RoleID),
	mod_caishen:role_online(RoleID),
    %% 通知玩家当前正在或将要开始的活动
    mod_activity:hook_role_online(RoleID),
    ?TRY_CATCH( mod_exchange_active_deal:hook_role_notify(RoleID,Level),Err4 ),
	?TRY_CATCH(mod_skill:cast_reduce_skill_cdtime(RoleID),Err10),
    ok.

%% 上线提醒
online_nofity(RoleID, RoleBase, _RoleAttr) ->
    %% 好友上线提醒
    gen_server:cast({global, mod_friend_server}, {online_notice, RoleID}),
    %% 宗族上线提醒
    common_family:nofity_role_online(RoleBase#p_role_base.family_id, RoleID).

%% 下线提醒
offline_nofity(RoleID) ->
    %% 好友下线提醒
    gen_server:cast({global, mod_friend_server}, {offline_notice, RoleID}),
    %% 宗族下线提醒
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    #p_role_base{family_id=FamilyID} = RoleBase,
    common_family:nofity_role_offline(FamilyID, RoleID),
    ok.

check_unactivity_role_back(RoleID) ->
    case db:dirty_read(?DB_ROLE_EXT, RoleID) of
        [] ->
            ignore;
        [RoleExt] ->
            Now = common_tool:now(),
            LastOfflineTime = RoleExt#p_role_ext.last_offline_time,
            case LastOfflineTime =:= undefined 
                        orelse Now - LastOfflineTime < 2592000 of
                true ->
                    ignore;    
                false ->
                    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
                    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
                    #p_role_base{pk_points = PkPoint,faction_id=FactionID,family_name=FamilyName} = RoleBase,
                    #p_role_attr{role_name=RoleName,level=Level,exp=Exp,category=Category,gongxun=GongXun} = RoleAttr,
                    RankSendInfo1 = {RoleID,Level,Exp,RoleName,Category},
                    common_rank:update_element( ranking_role_level, RankSendInfo1),
                    RankSendInfo2 = {RoleID,RoleName,Level,Exp,GongXun,FactionID,FamilyName},
                    common_rank:update_element( ranking_role_gongxun,RankSendInfo2),
                   
                    RankSendInfo3 = {RoleID,RoleName,PkPoint,FactionID,FamilyName},
                    common_rank:update_element( ranking_role_world_pkpoint,RankSendInfo3),
                    common_rank:update_element( ranking_role_pkpoint,RankSendInfo3)
            end
    end.

%% 玩家被召集传送前处理
%% 宗族召集，宗族拉镖召集，王座争霸战召集，宗族令召集，国王令召集
hook_change_map_by_call(Type,RoleId) ->
    ?DEBUG("~ts,Type=~w,RoleId=~w",["玩家被召集hook",Type,RoleId]),
    catch mod_scene_war_fb:do_cancel_role_sw_fb(RoleId),
    ok.

notify_family_contribute_change(RoleID,NewFamilyContrb)->
    R = #p_role_attr_change { change_type = ?ROLE_FAMILY_CONTRIBUTE_CHANGE, new_value = NewFamilyContrb },
    R_TOC = #m_role2_attr_change_toc{ roleid = RoleID, changes = [R] },
    common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?ROLE2,?ROLE2_ATTR_CHANGE,R_TOC).

sex_change(RoleID, NewSex) ->
   ChatRolePName = common_misc:chat_get_role_pname(RoleID),
   ?TRY_CATCH( global:send(ChatRolePName,{change_sex, NewSex}),Err2),
   ok.

%% @doc 角色掉血
role_reduce_hp(RoleMapInfo, SActorID, SActorType) ->
    %% 攻击者灰名
    catch mod_gray_name:change(RoleMapInfo, SActorID, SActorType),
    #p_map_role{role_id=RoleID} = RoleMapInfo,
    mod_role_busy:stop(RoleID),
    ok.

vip_upgrade(RoleID,OldLevel,NewLevel) ->
    if
        NewLevel>OldLevel-> %%玩家的VIP等级升级了
            hook_mission_event:hook_vip_up(RoleID, NewLevel),
            mod_horse_racing:hook_vip_up(RoleID, NewLevel),
            mod_lianqi:renew_role_lianqi_info(RoleID, true),
			mod_caishen:renew_role_caishen_info(RoleID, true),
			mod_egg_shop:hook_vip_up(RoleID, OldLevel, NewLevel),
			?TRY_CATCH(mod_open_activity:hook_vip_level_event(RoleID, NewLevel)),
			?TRY_CATCH(hook_guide_tip:hook_buy_guide_mission(RoleID),Err1),
            %% 完成成就
            mod_achievement2:achievement_update_event(RoleID, 43005, NewLevel),
            ok;
        true->
            ignore
    end.
