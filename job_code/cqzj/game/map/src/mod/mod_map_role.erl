%% Author: liuwei
%% Created: 2010-9-15
%% Description: TODO: Add description to mod_map_role
-module(mod_map_role).

-include("mgeem.hrl").  

%% 内部接口，进程字典实现
-export([
         init/0,
         set_role_detail/2,
		 set_role_mirror_detail/2,
         get_role_base/1, 
         get_role_attr/1,
         set_role_base/2,
         set_role_attr/2,
         set_role_attr_no_t/2,
         get_role_pos/1,
         get_role_goal/1,
         set_role_goal/2,
         set_role_pos_detail/2,
         get_role_pos_detail/1,
         get_role_state/1,
         set_role_state/2,
         set_role_fight/2,
         get_role_fight/1
         ]).
-export([
         persistent_role_detail/1,
         clear_role_spec_state/1,
         clear_role_timer/1,
		 clear_dict_info/1,
		 add_mp/3
         ]).

-export([
         handle/2
         ]).

-export([
         update_role_id_list_in_transaction/3,
         role_base_attr_persistent/0,
         get_map_faction_id/1,
         
         level_up/5,
         t_add_exp/2,
         do_after_level_up/6,
         t_level_up/5,
         get_relive_silver/4,
         do_skill_charge/5,
         dead_punish/5,
         do_role_reduce_mp/3,
         update_map_role_info/1,
         update_map_role_info/2,
         do_update_map_role_info/1,
         do_update_map_role_info/2,
         do_update_map_role_info/3,
         do_update_role_skin/2,
         reduce_equip_endurance/2,
         kick_role/2,kick_role/3,
         enter_exception/6,
         diff_map_change_pos/4,
         do_role_add_hp/3,
         do_role_add_mp/3,
         diff_map_change_pos/5,
         do_role_reduce_hp/6,
         do_role_reduce_hp_no_dead/4,
         do_change_map/5,
         do_role_recover/4,
         update_role_fight_time/4,
         is_role_fighting/1,
         update_offline_time_and_ip/2,
         update_online_time/1,
         map_enter_broadcast/2,
         clear_role_spec_buff_when_attack/1,
         clear_role_spec_buff_when_move/1,
		 clear_all_debuff/1,
         is_in_waroffaction/1,
         do_add_exp/2,
         is_role_exit_game/1,
         do_reset_role_energy/2,
         do_monster_dead_add_exp/6,
         t_add_role_energy/2,
         do_change_titlename_ex/4
        ]).

-export([
         add_exp/2,
         add_buff/2,
         call_ybc_mission_status/1,
         get_role_accumulate_exp/1,
         set_role_accumulate_exp/2,
         update_role_attr/2,
         add_nuqi/2,
         add_max_nuqi/1,
         clean_role_nuqi/2
        ]).

-export([erase_role_map_ext_info/1,
         set_role_map_ext_info/2,
         get_role_map_ext_info/1,
         t_set_role_map_ext_info/2]).

-export([
         hook_role_enter_map/2,
         remove_noattack_buff/2,
		 send_role_hmn_change/2,
         set_role_exit_game_mark/1,
		 del_role_exit_game_mark/1,
		 role_dead_normal/3,
         make_new_map_role/3,
         make_map_role_update_list/2
        ]).

%%do_attr_change/1跟attr_change/1的区别在于前者是同步调用，后者是异步调用（通过发送消息）

-define(PK_STATE_RED, 2).
-define(PK_STATE_YELLOW, 1).
-define(PK_STATE_WHITE, 0).
 
-define(AUTO_RELIVE_TIME, 600000).
-define(RELIVE_TYPE, [1, 2, 3]).
-define(CLEAR_FIGHT_STATE_DIFF, 10).
-define(ROLE_BASE_ATTR_PERSISTENT_INTERVAL, 300).

%%死亡类型定义
-define(DEAD_TYPE_NORMAL, 0).
-define(DEAD_TYPE_HERO_FB, 1). %% 在境界副本死亡
-define(DEAD_TYPE_DIE_TOGETHER, 2). %% 同归于尽死亡
-define(DEAD_TYPE_PET_REBORN_BUFF, 3). %% 死亡的时候有异兽重生BUFF
-define(DEAD_TYPE_ARENA_FB_SINGLE, 4). %% 在个人擂台死亡
-define(DEAD_TYPE_ARENA_FB_TEAM, 5). %% 在组队擂台死亡
-define(DEAD_TYPE_NATIONBATTLE_FB, 6). %% 在上古战场死亡
-define(DEAD_TYPE_ARENABATTLE_FB, 7). %% 在战神坛死亡
-define(DEAD_TYPE_WAROFKING_FB, 8). %% 在王座争霸战中死亡
-define(DEAD_TYPE_EXAMINE_FB, 9). %% 在检验副本死亡
-define(DEAD_TYPE_BIGPVE_FB, 10). %% 在魔龙巢穴死亡
-define(DEAD_TYPE_WAROFMONSTER_FB, 11). %% 在怪物攻城战中死亡
-define(DEAD_TYPE_MIRROR_FB, 12). %% 在离线PVP中死亡
-define(DEAD_TYPE_GUARD_FB, 13). %% 在魔尊洞窟中死亡
-define(DEAD_TYPE_BOMB_FB, 14). %% 在炸宝副本中死亡
-define(DEAD_TYPE_TOWER_FB, 15). %% 在玄冥塔副本中死亡
-define(DEAD_TYPE_COUNTRY_TREASURE, 16). %% 在mod_country_treasure中死亡

%%
%% ========================== API Functions ===========================
%%

init() ->
    erlang:put(?role_id_list_in_transaction, []).


set_role_detail(RoleID, RoleDetail) ->
    #r_role_map_detail{
               base = RoleBase,attr = RoleAttr,accumulate_info = AccumulateInfo,
               hero_fb_info = RoleHeroFbInfo,role_monster_drop = DropInfo,refining_box_info = RefiningBoxInfo, goal_info = RoleGoalInfo, 
               achievement_info = _AchievementInfo,team_info = TeamInfo,map_ext_info = MapExtInfo,skill_list = SkillList,
               pos=RolePos,role_fight=RoleFight} = RoleDetail,
	TeamID = case TeamInfo of
		#r_role_team{team_id=TeamID2} ->
			TeamProcName = common_misc:get_team_proccess_name(TeamID2),
			case global:whereis_name(TeamProcName) of
				undefined ->
					0;
				_ ->
					TeamID2
			end;
		_ ->
			0
	end,
    mod_role_tab:put({?role_base, RoleID}, RoleBase#p_role_base{team_id=TeamID}),
    mod_role_tab:put({?role_attr, RoleID}, RoleAttr),
    mod_role_tab:put({?role_pos, RoleID}, RolePos),
    mod_role_tab:put({?role_fight, RoleID}, RoleFight),
    case is_record(RoleGoalInfo, r_goal) of
        true ->
            mod_role_tab:put({?role_goal_info, RoleID}, RoleGoalInfo);
        false ->
            mod_role_tab:put({?role_goal_info, RoleID}, #r_goal{role_id = RoleID})
    end,
    erlang:put({?role_accumulate_exp, RoleID}, AccumulateInfo),
    mgeem_persistent:role_pos_persistent(RolePos),
    mod_treasbox:init_role_treasbox_info(RoleID,RefiningBoxInfo),
    % mod_achievement:init_role_achievement_info(RoleID,AchievementInfo),
	if 
		TeamID > 0 ->
    		mod_map_team:init_role_team_info(RoleID, TeamInfo);
		true ->
			ignore
	end,
    %% 初始化角色英雄副本信息
    mod_hero_fb:init_role_hero_fb_info(RoleID, RoleAttr, RoleHeroFbInfo),
    mod_map_drop:set_role_monster_drop(RoleID, DropInfo),
    init_role_map_ext_info(RoleID,MapExtInfo),
    mod_role_skill:init_role_skill_list(RoleID, SkillList),
    ok.

set_role_mirror_detail(RoleID, RoleDetail) ->
	#r_role_map_detail{base = RoleBase,
					   attr = RoleAttr,
					   skill_list = SkillList,
					   pos=RolePos,
					   role_fight=RoleFight,
					   map_ext_info=MapExtInfo} = RoleDetail,
	mod_role_tab:put({?role_base, RoleID}, RoleBase),
	mod_role_tab:put({?role_attr, RoleID}, RoleAttr),
	mod_role_tab:put({?role_pos, RoleID}, RolePos),
	mod_role_tab:put({?role_fight, RoleID}, RoleFight),
	mod_role_skill:init_role_skill_list(RoleID, SkillList),
	init_role_map_ext_info(RoleID,MapExtInfo),
	ok.

set_role_pos_detail(RoleID, RolePos) when erlang:is_record(RolePos, p_role_pos) ->
    update_role_id_list_in_transaction(RoleID, ?role_pos, ?role_pos_copy),
    mod_role_tab:put({?role_pos, RoleID}, RolePos).

get_role_pos_detail(RoleID) ->
    case mod_role_tab:get({?role_pos, RoleID}) of
        undefined ->
            {error, role_not_found};
        Value ->
            {ok, Value}
    end.
%% 获得角色累积经验的相关信息
get_role_accumulate_exp(RoleID) ->
    case erlang:get({?role_accumulate_exp, RoleID}) of
        undefined ->
            {error, role_not_found};
        Value ->
            {ok, Value}
    end.

%% 设置玩家的目标信息
set_role_goal(RoleID, RoleGoalInfo) ->
    % update_role_id_list_in_transaction(RoleID, ?role_goal_info, ?role_goal_info_copy),
    mod_role_tab:put({?role_goal_info, RoleID}, RoleGoalInfo).

get_role_goal(RoleID) ->
    {ok, mod_role_tab:get({?role_goal_info, RoleID})}.

set_role_accumulate_exp(RoleID, AccumulateExpInfo) ->
    update_role_id_list_in_transaction(RoleID, ?role_accumulate_exp, ?role_accumulate_exp_copy),
    erlang:put({?role_accumulate_exp, RoleID}, AccumulateExpInfo).

get_role_base(RoleID) ->
    case mod_role_tab:get({?role_base, RoleID}) of
        undefined ->
            {error, role_not_found};
        Value ->
            {ok, Value}
    end.
get_role_attr(RoleID) ->
    case mod_role_tab:get({?role_attr, RoleID}) of
        undefined ->
            {error, role_not_found};
        Value ->
            {ok, Value}
    end.

set_role_base(RoleID, RoleBase) ->
    %% ！！！一定要先执行update才进行put，update里面会先备份数据，且进程字典存储结构必须为{*, RoleID}，{*_copy, RoleID}
    update_role_id_list_in_transaction(RoleID, ?role_base, ?role_base_copy),
    mod_role_tab:put({?role_base, RoleID}, RoleBase).
    
set_role_attr(RoleID, RoleAttr) ->
    update_role_id_list_in_transaction(RoleID, ?role_attr, ?role_attr_copy),
    mod_role_tab:put({?role_attr, RoleID}, RoleAttr).

%% 无需外层包裹事务的设置角色属性数据的方法
set_role_attr_no_t(RoleID, RoleAttr) ->
    {atomic, _} = common_transaction:t(fun() -> set_role_attr(RoleID, RoleAttr) end).

set_role_fight(RoleId, RoleFight) ->
    case common_role:is_in_role_transaction() of
        true ->
            t_set_role_fight(RoleId, RoleFight);
        _ ->
            {atomic, _} = common_transaction:t(fun() -> t_set_role_fight(RoleId, RoleFight) end)
    end.

t_set_role_fight(RoleId, RoleFight) ->
    update_role_id_list_in_transaction(RoleId, ?role_fight, ?role_fight_copy),
    mod_role_tab:put({?role_fight, RoleId}, RoleFight).

get_role_fight(RoleId) ->
    case mod_role_tab:get({?role_fight, RoleId}) of
        undefined ->
            {error, not_found};
        RoleFight ->
            {ok, RoleFight}
    end.

persistent_role_detail(RoleID) ->
    %% 持久化
    {ok, RoleBase} = get_role_base(RoleID),
    {ok, RoleAttr} = get_role_attr(RoleID),
    {ok, RoleFight} = get_role_fight(RoleID),
	{ok, RolePos0} = get_role_pos_detail(RoleID),
    MapRoleInfo = mod_map_actor:get_actor_mapinfo(RoleID, role),
    RolePos = case MapRoleInfo of
		undefined ->
			RolePos0;
		#p_map_role{pos=Pos} ->
			RolePos0#p_role_pos{pos=Pos}
	end,
    RoleBagInfoList = mod_bag:get_role_bag_persistent_info(RoleID),
    case get_role_goal(RoleID) of
        {ok, RoleGoalInfo}  ->
            ignore;
        _ ->
            RoleGoalInfo =undefined
    end,
    case MapRoleInfo of
        #p_map_role{hp=HP, mp=MP, nuqi = Nuqi} ->
            RoleFight2 = RoleFight#p_role_fight{hp=HP, mp=MP, nuqi = Nuqi};
        _ ->
            RoleFight2 = RoleFight
    end,
    case get_role_accumulate_exp(RoleID) of
        {ok, RoleAccumulateInfo} ->
            ok;
        _ ->
            RoleAccumulateInfo = undefined
    end,
    case get_role_map_ext_info(RoleID) of
        {ok,RoleMapExtInfo}->
            ok;
        _->
            RoleMapExtInfo = undefined
    end,
    RoleMissionData = mod_mission_data:get_mission_data(RoleID),
    RoleHeroFbInfo = case mod_hero_fb:get_role_all_hero_fb_info(RoleID) of
		{ok, RoleHeroFbInfo2} -> 
			RoleHeroFbInfo2;
		_ -> 
			undefined
	end,
	RoleDetail = #p_role{base=RoleBase, attr=RoleAttr, fight=RoleFight2, pos=RolePos},
	RoleMonsterDrop = case mod_map_drop:get_role_monster_drop(RoleID) of
		{ok, RoleMonsterDrop2} ->
			RoleMonsterDrop2;
		_ ->
			undefined
	end,
	RoleBoxInfo = case  mod_treasbox:get_role_treasbox_info(RoleID) of
		{ok, RoleBoxInfo2} ->
			RoleBoxInfo2;
		_ ->
			undefined
	end,
	RoleSkillList = mod_role_skill:get_role_skill_list(RoleID),
	RoleShortcut = mod_shortcut:get_role_shortcut_bar(RoleID),  
	% RoleAchievementInfo = case mod_achievement:get_role_achievement_info(RoleID) of
	% 	{ok, RoleAchievementInfo2} ->
	% 		RoleAchievementInfo2;
	% 	_ ->
	% 		undefined
	% end,
	RoleMisc = mod_role_misc:delete(RoleID),
	%%清理并持久化
	mod_map_pet:persistent_pet_process_info(RoleID),
    AccountFullInfo = #r_account_full_info{
        role_id           = RoleID, 
        role_detail       = RoleDetail, 
        bag               = RoleBagInfoList,
        accumulate_info   = RoleAccumulateInfo,
        skill_list        = RoleSkillList,  
        hero_fb_info      = RoleHeroFbInfo,
        role_monster_drop = RoleMonsterDrop,
        refining_box_info = RoleBoxInfo,
        mission_data      = RoleMissionData, 
        % achievement_info  = RoleAchievementInfo,
        goal_info         = RoleGoalInfo,
        shortcut_bar      = RoleShortcut,
        map_ext_info      = RoleMapExtInfo, 
        role_misc         = RoleMisc
    },
	mgeed_persistent:persistent_account_info(AccountFullInfo).
	

set_role_state(RoleID, RoleState) ->
    mod_role_tab:put({?role_state, RoleID}, RoleState).

get_role_state(RoleID) ->
    case mod_role_tab:get({?role_state, RoleID}) of
        undefined ->
            {error, system_error};
        RoleState ->
            {ok, RoleState}
    end.

%%type, true, attack, false, defen
reduce_equip_endurance(RoleID, Type) ->
    case Type of
        true ->
            reduce_equip_endurance2_1(RoleID);
        false ->
            reduce_equip_endurance2_2(RoleID)
    end.


%%踢玩家掉线
kick_role(RoleID, Line,Reason) ->
    hook_map_role:kick_role(RoleID),
    Pid = get({roleid_to_pid,RoleID}),
    case Pid of
        undefined ->
            nil;
		mirror ->
			ignore;
        _ ->
            erase({roleid_to_pid,RoleID}),
            mgeem_router:kick_role(RoleID, Line, Reason)
    end.
kick_role(RoleID, Line) ->
    kick_role(RoleID, Line,not_valid_client).

%%@doc 发送HP/MP/Nuqi的更新到前端
send_role_hmn_change(RoleID, RoleMapInfo)->
	mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo),
	Record = #m_role2_hp_toc{
        hp = RoleMapInfo#p_map_role.hp,
        mp = RoleMapInfo#p_map_role.mp,
        nq = RoleMapInfo#p_map_role.nuqi
    },
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_HP, Record).

get_role_pos(RoleID) ->
    case mod_map_actor:get_actor_pos(RoleID, role) of
        undefined ->
            {error, not_found};
        RolePos ->
            {ok, RolePos}
    end.

%% add caochuncheng 2010-09-20
enter_exception(Unique, Pid, RoleID, RoleMapInfo, Line, State) ->
    Record = #m_map_enter_toc{succ=false},
    common_misc:unicast(Line, RoleID, Unique, ?MAP, ?MAP_ENTER, Record),
    Pid ! {sure_enter_map_need_change_pos, erlang:self()},

    #p_map_role{faction_id=FactionID} = RoleMapInfo,
    mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo),

    MapID = State#map_state.mapid,
    HomeMapID = common_misc:get_home_mapid(FactionID, MapID),
    {_, TX2, TY2} = common_misc:get_born_info_by_map(HomeMapID),
    diff_map_change_pos(?CHANGE_MAP_TYPE_RETURN_HOME, RoleID, HomeMapID, TX2, TY2).

%%无论玩家使用何种方式走路，每经过一格都必须要发一次消息给服务端
handle({Unique, Module, ?MOVE_WALK, DataIn, RoleID, _PID, Line}, State) -> 
    do_walk({Unique, Module, ?MOVE_WALK, DataIn, RoleID, Line}, State);
handle({_Unique, ?MOVE, ?MOVE_WALK_PATH, DataIn, RoleID, _PID, _Line}, State) ->
    do_walk_path(?MOVE, ?MOVE_WALK_PATH, DataIn, RoleID, State);
%%复活处理
handle({relive, RoleID, Type, RoleReliveInfo, Unique}, State) ->
    do_relive(RoleID, Type, RoleReliveInfo, Unique, State);
handle({role_reduce_hp, RoleID, Decrement, SrcActorName, SrcActorID, SrcActorType}, State) ->
    do_role_reduce_hp(RoleID, Decrement, SrcActorName, SrcActorID, SrcActorType, State);
handle({role_add_hp, RoleID, Increment, SRoleID}, _State) ->
    do_role_add_hp(RoleID, Increment, SRoleID);    
handle({role_add_mp, RoleID, Increment, RoleID}, _State) ->
    do_role_add_mp(RoleID, Increment, RoleID);
%% 杀死怪物加经验
handle({monster_dead_add_exp, RoleID, Add, MonsterType, RoleState, KillFlag, EnergyIndex}, _State) ->
    do_monster_dead_add_exp(RoleID, Add, MonsterType, RoleState, KillFlag, EnergyIndex);
handle({add_exp, RoleID, Add}, _State) ->
    do_add_exp(RoleID, Add);
handle({gm_level_up, RoleAttr, RoleBase, Level, Level2, Exp}, _State) ->
    level_up(RoleAttr, RoleBase, Level, Level2, Exp);
%% 升级
handle({level_up,RoleID,RoleAttr, RoleBase},_State) ->
    do_level_up(RoleID,RoleAttr, RoleBase);
%%回城
handle({return_home, RoleID}, State) ->
    catch mod_scene_war_fb:do_cancel_role_sw_fb(RoleID),
    do_return_home(RoleID, State);

%%送回太平村
handle({return_peace_village, RoleID},_State) ->
    do_return_peace_village(RoleID);

%% mgeem_map发送过来的，最终是通过monitor来实现的
handle({role_exit, RoleID}, State) ->
	set_role_exit_game_mark(RoleID),
    %% 角色下线HOOK
    hook_map_role:role_offline(RoleID),
    %% 退出地图
    mod_map_actor:do_quit(RoleID, role, State);

%%全地图随机移动
handle({random_move, RoleID}, State) ->
    do_random_move(RoleID, State);
%% 追踪玩家
handle({trace_role, Unique, Module, Method, PID, {TargetID, TargetName, GoodsID, Num}}, _State) ->
    do_trace_role(Unique, Module, Method, PID, TargetID, TargetName, GoodsID, Num);

%%随机移动技能
handle({skill_transfer,ActorID, ActorType,DistRound}, State) ->
    do_skill_transfer(ActorID, ActorType,DistRound,State);
%%冲锋技能
handle({skill_charge,SrcActorID, SrcActorType,ActorID,ActorType}, State) ->
    do_skill_charge(SrcActorID, SrcActorType, ActorID, ActorType, State);
handle({bubble_msg, RoleID, Line, DataIn}, State) ->
    do_bubble_msg(RoleID, Line, DataIn, State);
handle({change_cur_title, RoleID, TitleID, TitleName, Color}, State) ->
    do_change_titlename(RoleID, TitleID, TitleName, Color, State);

%%家族成员传动参与boss战
handle({family_member_enter_map_copy,RoleID,R},_State)->
    do_handle_family_member_enter_mapcopy(RoleID,R);

%%宗族令
handle({family_membergather,RoleID,R},_State)->
    do_handle_family_member_gather(RoleID,R);

handle({educate_dead_call_help,RoleID,R},_State)->
    do_handle_educate_help_call(RoleID,R);

%%把玩家踢出宗族地图
handle({family_member_cast_to_born_place,RoleID,R},_State)->
    do_handle_cast_member_to_born_palce(RoleID,R);

%%地图跳转，只打个标记，不发跳转消息到客户端
handle({change_map, RoleID, MapID, TX, TY, ChangeMapType}, _State) ->
    do_change_map(RoleID, MapID, TX, TY, ChangeMapType);

%% 自动复活
handle({auto_relive, RoleID}, State) ->
    mod_role2:do_relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, RoleID, ?RELIVE_TYPE_HOME_FREE_FULL, State);
%% 开始启动减PK值计时
handle({reduce_pk_point_start, RoleID}, _State) ->
    mod_pk:reduce_pk_point_start(RoleID);
%% 定时减PK值
handle({reduce_pk_point, RoleID, Reduce, ReduceType}, _State) ->
    mod_pk:reduce_pk_point(RoleID, Reduce, ReduceType);
%% 取消灰名
handle({cancel_gray_name, RoleID}, _State) ->
    mod_gray_name:cancel_gray_name(RoleID);
%% 加功勋
handle({add_gongxun, RoleID, Add}, _State) ->
    mod_gongxun:add_gongxun(RoleID, Add);
%% 返还完成宗族拉镖族员押金
handle({return_family_ybc_silver_and_reward, RoleID, RoleName, FamilyPID, Silver, RewardSilverBind}, _State) ->
    mod_ybc_family:return_family_ybc_silver_and_reward(RoleID,RoleName,FamilyPID,Silver, RewardSilverBind);
%% 减功勋
handle({reduce_gongxun, RoleID, Reduce}, _State) ->
    mod_gongxun:reduce_gongxun(RoleID, Reduce);
%% 添加BUFF
handle({add_buff, RoleID, SActorID, SActorType, AddBuffs}, _State) ->
    mod_role_buff:add_buff(RoleID, AddBuffs, {SActorType, SActorID});
%% 移除BUFF
handle({remove_buff, RoleID, _SActorID, _SActorType, RemoveBuffs}, _State) ->
    mod_role_buff:del_buff_by_type(RoleID, RemoveBuffs);

%% 稍后刷新玩家的BUFFS
%% 某人被外国人杀了
handle({killed_by_foreigner, RoleID, FactionID, MapID, TX, TY}, _State) ->
    put({killed_by_foreigner, MapID, TX, TY}, {RoleID, FactionID}),
    %% 5分钟后清掉标记
    erlang:send_after(60*1000, self(), {mod_map_role, {erase_killed_by_foreigner, MapID, TX, TY}});
%% 清除标记
handle({erase_killed_by_foreigner, MapID, TX, TY}, _State) ->
    erase({killed_by_foreigner, MapID, TX, TY});
%% 进入地图广播
handle({map_enter_broadcast, RoleID, MFID, Msg}, _State) ->
    do_map_enter_broadcast(RoleID, MFID, Msg);
%% 技能返回经验
handle({skill_return_exp, RoleID}, _MapState) ->
    do_skill_return_exp(RoleID);
handle({reset_role_energy, RoleID}, _MapState) ->
    do_reset_role_energy(RoleID);
%%扣钱接口
handle({reduce_money, Request}, _State) ->
    mod_role_money:do_reduce_money(Request);
handle({add_money, Request}, _State) ->
    mod_role_money:do_add_money(Request);
%%警惕！此处是GM指令专用
handle({set_money, Request}, _State) ->
    mod_role_money:do_set_money(Request);
% handle({change_money, Request}, _State) ->
%     mod_role_money:do_change_money(Request);
handle({moral_value_to_pkpoint, MoralPID, RoleID, MoralValue, Msg}, _State) ->
    do_moral_value_to_pkpoint(MoralPID, RoleID, MoralValue, Msg);

handle({gm_set_energy, {RoleID, Energy}}, _State) ->
    do_gm_set_enery(RoleID, Energy);
    
%% 玩家改名
handle({rename_notify, RoleID, RoleName},_State) ->
    do_rename_notify(RoleID, RoleName);


handle(Msg,_State) ->
    ?ERROR_MSG("uexcept msg = ~w",[Msg]).

%%
%% ========================= Local Functions ==================================
%%
%% 追踪玩家
do_trace_role(Unique, Module, Method, PID, TargetID, TargetName, GoodsID, Num) ->
    case mod_map_role:get_role_pos(TargetID) of
        {ok, #p_pos{tx=TX, ty=TY}} ->
            DataRecord = #m_item_trace_toc{goods_id=GoodsID, goods_num=Num, target_name=TargetName,
                                           target_mapid=mgeem_map:get_mapid(), target_tx=TX, target_ty=TY},
            common_misc:unicast2(PID, Unique, Module, Method, DataRecord);
        {error, _} ->
            R = #m_item_trace_toc{succ=false, reason=?_LANG_ITEM_TRACE_ROLE_NOT_FOUND},
            common_misc:unicast2(PID, Unique, Module, Method, R)
    end.    

%% 玩家改名后要通知玩家并广播告诉九宫格内的玩家
do_rename_notify(RoleID, RoleName) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            ok;
        RoleMapInfo  ->
            mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo#p_map_role{role_name=RoleName}),
            R = #m_map_update_actor_mapinfo_toc{actor_id=RoleID, actor_type=?TYPE_ROLE, role_info=RoleMapInfo#p_map_role{role_name=RoleName}},
            mgeem_map:do_broadcast_insence_include([{role, RoleID}], ?MAP, ?MAP_UPDATE_ACTOR_MAPINFO, R, mgeem_map:get_state())
    end. 

do_handle_cast_member_to_born_palce(RoleID,R)->
    #m_map_change_map_toc{
			   mapid = MapID,
			   tx = X,
			   ty = Y
			 } = R,
    diff_map_change_pos(RoleID,MapID,X,Y).
%% 宗族活动召集,通过宗族地图NPC发布召集信息
do_handle_family_member_enter_mapcopy(RoleID,R)->
    hook_map_role:hook_change_map_by_call(?CHANGE_MAP_FAMILY_NPC_CALL,RoleID),
    #m_map_change_map_toc{mapid = MapID,tx=TX,ty=TY} = R,
    diff_map_change_pos(RoleID,MapID,TX,TY).

%% 宗族令召集
do_handle_family_member_gather(RoleID,R)->
    hook_map_role:hook_change_map_by_call(?CHANGE_MAP_FAMILY_GATHER_CALL,RoleID),
    #m_map_change_map_toc{mapid = MapID, tx=TX,ty = TY} = R,
    diff_map_change_pos(RoleID,MapID,TX,TY).

%% 师徒死亡召集
do_handle_educate_help_call(RoleID,R)->
    hook_map_role:hook_change_map_by_call(?CHANGE_MAP_EDUCATE_HELP_CALL,RoleID),
    #m_map_change_map_toc{mapid = MapID, tx=TX,ty = TY} = R,
    diff_map_change_pos(RoleID,MapID,TX,TY).

do_walk({Unique, Module, Method, DataIn, RoleID, Line}, State) ->
    #m_move_walk_tos{pos=#p_pos{tx=TX, ty=TY, dir=DIR}} = DataIn,
    case mod_map_actor:get_actor_pos(RoleID, role) of
        undefined ->
            ?ERROR_MSG("~ts [~w] : ~ts", ["踢掉玩家", RoleID, "原因是没有发现玩家的位置"]), 
            kick_role(RoleID, Line);
        #p_pos{tx=OldTX, ty=OldTY} ->
            %%判断移动是否合法
            case erlang:abs(OldTX - TX) =< 1 andalso erlang:abs(OldTY - TY) =< 1 of
                true ->
                    do_walk2(Unique, Module, Method, State#map_state.mapid, {TX, TY, DIR}, RoleID, Line);
                false ->
                    sync_role_pos(RoleID, Line)
            end
    end.
do_walk2(_Unique, _Module, _Method, MapID, {TX, TY, DIR}, RoleID, Line) ->
    %%判断安全区
    case mcm:is_walkable(MapID, {TX, TY}) of
        false ->
            ?ERROR_MSG("~ts: ~w ~w", ["玩家由于走到一个不可走的格子上而被踢掉了", TX, TY]), 
            kick_role(RoleID, Line);
        _ ->
            do_walk3(RoleID, TX, TY, DIR)
    end. 
do_walk3(RoleID, TX, TY, DIR) ->
    %% get user's cur slice
    %% update user's slice when needed
    hook_map_role:role_pos_change(RoleID, TX, TY, DIR),
    mod_map_actor:update_slice_by_txty(RoleID, role, TX, TY, DIR).
    %mod_map_pet:update_role_pet_slice(RoleID, TX, TY, DIR).


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

%% @doc 角色复活
do_relive(RoleID, ReliveType, RoleReliveInfo, Unique, MapState) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            ignore;
        RoleMapInfo ->
            #p_map_role{pos=Pos} = RoleMapInfo,
            %% 清掉角色所占的位置
            #p_pos{tx=TX, ty=TY} = Pos,
            mod_map_actor:deref_tile_pos(RoleID, role, TX, TY),
            %% 设置角色血量
            {HP, _MP} = RoleReliveInfo,
            {ok, RoleFight} = get_role_fight(RoleID),
            RoleFight2 = RoleFight#p_role_fight{hp=HP},
            RoleMapInfo2 = RoleMapInfo#p_map_role{hp=HP,last_walk_path=undefined, state=?ROLE_STATE_NORMAL, gray_name=false},
            ?TRY_CATCH( mod_map_pet:auto_summon_role_pet(RoleID, MapState)),
            MapId = mgeem_map:get_mapid(),
            if
                MapId == ?NEW_COMER_MAP_ID ->
                    do_relive_original(RoleID, RoleMapInfo2, RoleFight2, MapState, Unique);
                ReliveType =:= ?RELIVE_TYPE_ORIGINAL_FREE; 
                ReliveType =:= ?RELIVE_TYPE_ORIGINAL_SILVER;
                ReliveType =:= ?RELIVE_TYPE_ORIGINAL_GOLD ->
                    case cfg_relive:relive_pos(MapId, ReliveType) of
                        {TX2, TY2} ->
                            RelivePos = #p_pos{tx=TX2, ty=TY2},
                            RoleMapInfo3 = RoleMapInfo2#p_map_role{pos = RelivePos},
                            do_relive_original(RoleID, RoleMapInfo3, RoleFight2, MapState, Unique),
                            mod_map_actor:same_map_change_pos(RoleID, role, TX2, TY2, ?CHANGE_POS_TYPE_RELIVE, MapState);
                        _ ->
                            do_relive_original(RoleID, RoleMapInfo2, RoleFight2, MapState, Unique)
                    end;
                true ->
                    do_relive_back_home(RoleID, RoleMapInfo2, RoleFight2, MapState, Unique)
            end
    end.

%% @doc 原地复活
do_relive_original(RoleID, RoleMapInfo, RoleFight, MapState, Unique) ->
    set_role_fight(RoleID, RoleFight),
    mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo),
    {ok, RolePos} = mod_map_role:get_role_pos_detail(RoleID),
    #p_map_role{pos=Pos} = RoleMapInfo,
    RolePos2 = RolePos#p_role_pos{pos=Pos},
    DataRecord = #m_role2_relive_toc{succ=true, 
                                     map_changed=false, 
                                     map_role=RoleMapInfo,
                                     role_pos=RolePos2, 
                                     role_fight=RoleFight},
    common_misc:unicast({role, RoleID}, Unique, ?ROLE2, ?ROLE2_RELIVE, DataRecord),

    AllNewSlice = mgeem_map:get_9_slice_by_actorid_list([{role, RoleID}], MapState),
    relive_slice_enter(RoleID, AllNewSlice),
    ok.

%% 平江地图ID
-define(pingjianid(FactionID), 10000 + FactionID * 1000 + 102).
%% 京城地图ID
-define(jingchengid(FactionID), 10000 + FactionID * 1000 + 100).

%% @doc 获取死亡回城点
get_relive_home_mapid(RoleMapInfo, MapID, PKPoints) ->
    [JailPKPoint] = common_config_dyn:find(jail, jail_in_pkpoints),
    InJail = mod_jail:check_in_jail(MapID),
    
    if PKPoints >= JailPKPoint ->
            get_relive_home_mapid_jail(RoleMapInfo, InJail);
       PKPoints >= ?RED_NAME_PKPOINT andalso InJail ->
            get_relive_home_mapid_jail(RoleMapInfo, InJail);
       true->
           case common_config_dyn:find(fb_map,MapID) of
               [#r_fb_map{can_relive_home=true,module=Module}] ->
                   Module:get_relive_home_pos(RoleMapInfo, MapID);
               _ ->
                   get_relive_home_mapid_normal(RoleMapInfo, MapID)
           end
    end.

%%默认回各国王城出生点
get_relive_home_mapid_normal(RoleMapInfo, MapID) ->
    #p_map_role{faction_id=FactionID} = RoleMapInfo,
    HomeMapID = common_misc:get_home_mapid(FactionID, MapID),
    common_misc:get_born_info_by_map(HomeMapID).


get_relive_home_mapid_jail(RoleMapInfo, IsInJail) ->
    %% 进入监狱发送信件
    case IsInJail of
        true ->
            ignore;
        _ ->
            #p_map_role{role_id=RoleID, role_name=RoleName} = RoleMapInfo,
            Letter = common_letter:create_temp(?JAIL_LETTER, [RoleName]),
            common_letter:sys2p(RoleID, Letter, "来自监狱长的信件", 3)
    end,

    [JailMapID] = common_config_dyn:find(jail, jail_map_id),
    [{TX, TY}] = common_config_dyn:find(jail, jail_map_born_point),
    {JailMapID, TX, TY}.

%% @doc 回城复活
do_relive_back_home(RoleID, RoleMapInfo, RoleFight, MapState, Unique) ->
    #map_state{mapid=MapID} = MapState,
    %% 取消师徒副本
    %%catch mod_educate_fb:do_cancel_role_educate_fb(RoleID),
    %% 获取主城ID
    #p_map_role{hp=HP, mp=MP, pk_point=PKPoints} = RoleMapInfo,
    {HomeMapID, TX, TY} = get_relive_home_mapid(RoleMapInfo, MapID, PKPoints),
    {ok, RolePos} = mod_map_role:get_role_pos_detail(RoleID),
    case MapID =:= HomeMapID of
        true ->
            RoleFight2 = RoleFight#p_role_fight{hp=HP, mp=MP},
            RolePos2 = RolePos#p_role_pos{map_id=MapID, pos=#p_pos{tx=TX, ty=TY, dir=0}},

            mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo),
            set_role_fight(RoleID, RoleFight2),

            DataRecord = #m_role2_relive_toc{succ=true, map_changed=false, map_role=RoleMapInfo, role_pos=RolePos2, role_fight=RoleFight2},
            common_misc:unicast({role, RoleID}, Unique, ?ROLE2, ?ROLE2_RELIVE, DataRecord),
            %% 同地图跳转
            mod_map_actor:same_map_change_pos(RoleID, role, TX, TY, ?CHANGE_POS_TYPE_RELIVE, MapState);

        _ ->
            RolePos2 = RolePos#p_role_pos{map_id=HomeMapID, pos=#p_pos{tx=TX, ty=TY, dir=0}},
            mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo),
            set_role_fight(RoleID, RoleFight),

            DataRecord = #m_role2_relive_toc{succ=true, map_changed=true, map_role=RoleMapInfo, role_pos=RolePos2, role_fight=RoleFight},
            common_misc:unicast({role, RoleID}, Unique, ?ROLE2, ?ROLE2_RELIVE, DataRecord),
            %% 不同地图跳转
            diff_map_change_pos(?CHANGE_MAP_TYPE_RELIVE, RoleID, HomeMapID, TX, TY)
    end,
    ok.

%%玩家不死的扣血
do_role_reduce_hp_no_dead(RoleID, Decrement, SActorID, SActorType) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            nil;
        RoleMapInfo ->
            ?TRY_CATCH(hook_map_role:role_reduce_hp(RoleMapInfo, SActorID, SActorType),Err1),
            NewHP = max(0, RoleMapInfo#p_map_role.hp - Decrement),
            NewNQ = min(cfg_role_nuqi:max_nuqi(), RoleMapInfo#p_map_role.nuqi+2),
            NewRoleMapInfo = RoleMapInfo#p_map_role{hp = NewHP, nuqi = NewNQ},
            mod_map_actor:set_actor_mapinfo(RoleID, role, NewRoleMapInfo),
            send_role_hmn_change(RoleID, NewRoleMapInfo),
            ok
    end.

%%玩家扣血
do_role_reduce_hp(RoleID, Decrement, SActorName, SActorID, SActorType, MapState) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        RoleMapInfo when RoleMapInfo#p_map_role.state =/= ?ROLE_STATE_DEAD ->
            ?TRY_CATCH(hook_map_role:role_reduce_hp(RoleMapInfo, SActorID, SActorType),Err1),
            NewHP = max(0, RoleMapInfo#p_map_role.hp - Decrement),
            case lists:keymember(?BUF_TYPE_NO_NUQI, #p_actor_buf.buff_type, RoleMapInfo#p_map_role.state_buffs) of
                true -> 
                    NewNQ = RoleMapInfo#p_map_role.nuqi;
                false ->
                    NewNQ = min(cfg_role_nuqi:max_nuqi(), RoleMapInfo#p_map_role.nuqi+cfg_role_nuqi:underattack_nuqi())
            end,

            NewRoleMapInfo = RoleMapInfo#p_map_role{hp = NewHP, nuqi = NewNQ},
            mod_map_actor:set_actor_mapinfo(RoleID, role, NewRoleMapInfo),
            send_role_hmn_change(RoleID, NewRoleMapInfo),
			case RoleMapInfo#p_map_role.hp =< Decrement of
			true ->
				case RoleMapInfo#p_map_role.is_mirror orelse mod_mirror:is_mirror(SActorType, SActorID) of
				true ->
					erlang:send(self(), {mod, mod_mirror_fb, {role_dead, RoleID, RoleMapInfo, SActorID, SActorType, SActorName}});
				false ->
					role_dead(RoleID, RoleMapInfo#p_map_role{hp=0,nuqi=0}, SActorID, SActorType, SActorName, MapState#map_state.mapid)
				end;
			_ ->
				ignore
			end;
        _ ->
            ignore
    end.

%%玩家加血
do_role_add_hp(RoleID, Add, _SActorID) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            ignore;
        RoleMapInfo = #p_map_role{hp = HP, max_hp = MaxHP} ->
            NewHP = min(MaxHP, HP + Add),
            NewRoleMapInfo = RoleMapInfo#p_map_role{hp = NewHP},
            mod_map_actor:set_actor_mapinfo(RoleID, role, NewRoleMapInfo),
            send_role_hmn_change(RoleID, NewRoleMapInfo)
    end.

%%玩家加蓝
do_role_add_mp(RoleID, Add, _SActorID) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            ignore;
        RoleMapInfo = #p_map_role{mp = MP, max_mp = MaxMP} ->
            NewMP = min(MaxMP, MP + Add),
            NewRoleMapInfo = RoleMapInfo#p_map_role{mp = NewMP},
            mod_map_actor:set_actor_mapinfo(RoleID, role, NewRoleMapInfo),
            send_role_hmn_change(RoleID, NewRoleMapInfo)
    end.

do_role_reduce_mp(RoleID, Reduce, _SActorID) when Reduce > 0 ->
	case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            ignore;
        RoleMapInfo = #p_map_role{mp = MP} ->
            NewMP = max(0, MP - Reduce),
            NewRoleMapInfo = RoleMapInfo#p_map_role{mp = NewMP},
            mod_map_actor:set_actor_mapinfo(RoleID, role, NewRoleMapInfo),
            send_role_hmn_change(RoleID, NewRoleMapInfo)
    end;
do_role_reduce_mp(_RoleID, _Reduce, _SActorID) ->
	ignore.

%%自动回血回蓝回怒气
do_role_recover(RoleID,RoleMapInfo,MapID,Now) ->
    case get_role_base(RoleID) of
        {ok, RoleBase} ->
        	#p_map_role{state = State, hp = OldHP, max_hp = MaxHP, nuqi = OldNuqi} = RoleMapInfo,
            #p_role_base{hp_recover_speed = HPRecoverSpeed} = RoleBase,
            RecoverHP = case State of
                ?ROLE_STATE_DEAD ->
                    0;
                ?ROLE_STATE_ZAZEN ->
                    
                    common_tool:ceil(MaxHP*25/10000+HPRecoverSpeed+10);
                _ ->
                    HPRecoverSpeed
            end,
            RoleMapInfo2 = add_hp(RoleID, RoleMapInfo, RecoverHP),
            RoleMapInfo3 = do_role_recover_nuqi(RoleID, RoleMapInfo2, MapID, Now),
            if
                RoleMapInfo3#p_map_role.nuqi =/= OldNuqi;
                RoleMapInfo3#p_map_role.hp =/= OldHP ->
                    send_role_hmn_change(RoleID, RoleMapInfo3);
                true->
                    ignore
            end;
        _ ->
            ignore
    end.

do_role_recover_nuqi(RoleID, RoleMapInfo, MapID, Now) ->
    #p_pos{tx = X, ty = Y} = RoleMapInfo#p_map_role.pos,
    OldNuqi = RoleMapInfo#p_map_role.nuqi,
	AddNuqi = get_nuqi_recover_speed(RoleID, MapID, {X, Y}, Now),
    MaxNuqi = cfg_role_nuqi:max_nuqi(),
    if
        AddNuqi > 0, OldNuqi < MaxNuqi ->
            RoleMapInfo#p_map_role{nuqi=min(MaxNuqi, OldNuqi+AddNuqi)};
        AddNuqi < 0, OldNuqi > 0 ->
            RoleMapInfo#p_map_role{nuqi=max(0, OldNuqi+AddNuqi)};
        true ->
            RoleMapInfo
    end.

add_hp(_RoleID, RoleMapInfo, Add) ->
    #p_map_role{hp=HP, max_hp=MaxHP} = RoleMapInfo,
    
    case HP =< 0 orelse HP =:= MaxHP of
        true ->
            RoleMapInfo;
        _ ->
            HP2 = HP + Add,
            case HP2 >= MaxHP of
                true ->
                    HP3 = MaxHP;
                _ ->
                    HP3 = HP2
            end,
            
            RoleMapInfo#p_map_role{hp=HP3}
    end.

add_mp(_RoleID, RoleMapInfo, Add) ->
    #p_map_role{mp=MP, max_mp=MaxMP, state=State} = RoleMapInfo, 
    case State =:= ?ROLE_STATE_DEAD orelse MP =:= MaxMP of
        true ->
            RoleMapInfo;
        _ ->
            MP2 = MP + Add,
            case MP2 >= MaxMP of
                true ->
                    MP3 = MaxMP;
                _ ->
                    MP3 = MP2
            end,
            
            RoleMapInfo#p_map_role{mp=MP3}
    end.


%%清除玩家的计时器
clear_role_timer(RoleState) ->    
    #r_role_state2{
        gray_name_timer_ref = GrayTimer,
        pkpoint_timer_ref   = PKPointTimer
    } = RoleState,
    GrayTime = case erlang:is_reference(GrayTimer) andalso erlang:cancel_timer(GrayTimer) of
        false ->
            0;
        T1 ->
            T1
    end,
    PKTime = case erlang:is_reference(PKPointTimer) andalso erlang:cancel_timer(PKPointTimer) of
        false ->
            0;
        T2 ->
            T2
    end,
    {ok, GrayTime, PKTime}.

clear_dict_info(RoleID) ->
    PID = erlang:erase({roleid_to_pid,RoleID}),
    erlang:erase({role_msg_queue, PID}),
    erlang:erase({pid_to_roleid, PID}),
    erlang:erase({change_map_type, RoleID}),
    erlang:erase({fb_id, RoleID}),
    erlang:erase({attack_count, RoleID}),
    erlang:erase({defen_count, RoleID}),
    erlang:erase({change_map_quit, RoleID}),
    mod_role_on_zazen:del_zazen_total_exp(RoleID),
    mof_common:erase_role_fight_attr(RoleID),
    ok.

do_level_up(RoleID, RoleAttr, RoleBase) ->
    {ok, RoleFight} = get_role_fight(RoleID),
    MaxHP           = RoleBase#p_role_base.max_hp,
    MaxMP           = RoleBase#p_role_base.max_mp,
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            nil;
        MapRoleInfo ->
            mof_common:erase_role_fight_attr(RoleID),
            Level          = RoleAttr#p_role_attr.level,
            NewMapRoleInfo = MapRoleInfo#p_map_role{
               hp             = MaxHP,
               mp             = MaxMP,
               max_hp         = MaxHP,
               max_mp         = MaxMP,
               level          = Level
            },
            mod_map_actor:set_actor_mapinfo(RoleID, role, NewMapRoleInfo),
			NewRoleFight = RoleFight#p_role_fight{hp = MaxHP, mp = MaxMP},
            Changes = [
                #p_role_attr_change{change_type = ?ROLE_HP_CHANGE, new_value = MaxHP},
                #p_role_attr_change{change_type = ?ROLE_MP_CHANGE, new_value = MaxMP}
            ],
            set_role_fight(RoleID, NewRoleFight),
			Record = #m_role2_attr_change_toc{roleid=RoleID, changes=Changes},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, Record)
    end.            

update_map_role_info(RoleID) ->
    mgeem_map:send({apply, ?MODULE, do_update_map_role_info, [RoleID]}).
update_map_role_info(RoleID, NewValueList) ->
    mgeem_map:send({apply, ?MODULE, do_update_map_role_info, [RoleID, NewValueList]}).

do_update_map_role_info(RoleID) when is_integer(RoleID) ->
    {ok, RoleBase} = get_role_base(RoleID),
    {ok, RoleAttr} = get_role_attr(RoleID),
    UpdateList     = make_map_role_update_list(RoleBase, RoleAttr),
    do_update_map_role_info(RoleID, UpdateList).

-define(_update_role_toc(Update, KeyVal), Toc#m_map_update_role_toc{
    update_list = [Update|Toc#m_map_update_role_toc.update_list], KeyVal}).
-define(_update_role_toc(Update), Toc#m_map_update_role_toc{
    update_list = [Update|Toc#m_map_update_role_toc.update_list]}).

do_update_map_role_info(RoleID, UpdateList) when is_integer(RoleID) ->
    do_update_map_role_info(RoleID, mod_map_actor:get_actor_mapinfo(RoleID, role), UpdateList).

do_update_map_role_info(RoleID, OldMapRole, UpdateList) when is_record(OldMapRole, p_map_role) ->
    {UpdateToc, NewMapRole} = lists:foldl(fun
        ({Index = #p_map_role.state_buffs, NewBuffs}, {Toc, Acc}) ->
            OldBuffs   = OldMapRole#p_map_role.state_buffs,
            OldBuffIDs = [ID||#p_actor_buf{buff_id=ID}<-OldBuffs],
            NewBuffIDs = [ID||#p_actor_buf{buff_id=ID}<-NewBuffs],
            case NewBuffIDs == OldBuffIDs of
                true -> {Toc, Acc};
                false ->
                    {?_update_role_toc({Index, 1}, buffs = NewBuffs), Acc#p_map_role{state_buffs = NewBuffs}}
            end;
        ({Index = #p_map_role.skin, NewSkin}, {Toc, Acc}) ->
            OldSkin = OldMapRole#p_map_role.skin,
            case NewSkin == OldSkin of
                true -> {Toc, Acc};
                false ->
                    {?_update_role_toc({Index, 1}, skin = NewSkin), Acc#p_map_role{skin = NewSkin}}
            end;
        ({Index, NewVal}, {Toc, Acc}) ->
            OldVal = element(Index, OldMapRole),
            case NewVal == OldVal of
                true -> {Toc, Acc};
                false ->
                    {?_update_role_toc({Index, NewVal}), setelement(Index, Acc, NewVal)}
            end
    end, {#m_map_update_role_toc{role_id = RoleID}, OldMapRole}, UpdateList),
    if
        UpdateToc#m_map_update_role_toc.update_list =/= [] ->
            mgeem_map:do_broadcast_insence_include(
                [{role, RoleID}], ?MAP, ?MAP_UPDATE_ROLE, UpdateToc);
        true ->
            ignore
    end,
    mod_map_actor:set_actor_mapinfo(RoleID, role, NewMapRole),
    mof_common:erase_role_fight_attr(RoleID);
do_update_map_role_info(RoleID, OldMapRole, _UpdateList) ->
    ?ERROR_MSG("do_update_map_role_info error: ~p ~p", [RoleID, OldMapRole]).

make_map_role_update_list(RoleBase, RoleAttr) ->
    RateAttr = case RoleBase#p_role_base.rate_attrs of
        undefined ->
            #p_rate_attrs{};
        Others ->
            Others
    end,
    MaxHpRate = RateAttr#p_rate_attrs.blood_rate,
    MaxMpRate = RateAttr#p_rate_attrs.magic_rate,
    [
        {#p_map_role.faction_id,        RoleBase#p_role_base.faction_id},
        {#p_map_role.family_id,         RoleBase#p_role_base.family_id},
        {#p_map_role.family_name,       RoleBase#p_role_base.family_name},
        {#p_map_role.max_hp,            trunc(RoleBase#p_role_base.max_hp*(1+MaxHpRate/10000))},
        {#p_map_role.max_mp,            trunc(RoleBase#p_role_base.max_mp*(1+MaxMpRate/10000))},
        {#p_map_role.state_buffs,       RoleBase#p_role_base.buffs},
        {#p_map_role.move_speed,        RoleBase#p_role_base.move_speed},
        {#p_map_role.team_id,           RoleBase#p_role_base.team_id},
        {#p_map_role.pk_point,          RoleBase#p_role_base.pk_points},
        {#p_map_role.state,             RoleBase#p_role_base.status},
        {#p_map_role.gray_name,         RoleBase#p_role_base.if_gray_name},
        {#p_map_role.cur_title,         RoleBase#p_role_base.cur_title},
        {#p_map_role.cur_title_color,   RoleBase#p_role_base.cur_title_color},
        {#p_map_role.skin,              RoleAttr#p_role_attr.skin},
        {#p_map_role.level,             RoleAttr#p_role_attr.level},
        {#p_map_role.jingjie,           RoleAttr#p_role_attr.jingjie}
    ].
    
make_new_map_role(MapRole, RoleBase, RoleAttr) ->
    lists:foldl(fun
        ({Index, NewVal}, MapRoleAcc) ->
            setelement(Index, MapRoleAcc, NewVal)
    end, MapRole, make_map_role_update_list(RoleBase, RoleAttr) ).

do_update_role_skin(RoleID, NewValueList) when is_list(NewValueList) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    OldSkin = RoleAttr#p_role_attr.skin,
    NewSkin = lists:foldl(fun
        ({Index, Value}, RoleSkinAcc) ->
            setelement(Index, RoleSkinAcc, Value)
    end, OldSkin, NewValueList),
    mod_role_tab:put({?role_attr, RoleID}, RoleAttr#p_role_attr{skin = NewSkin}),
    MapRole = mod_map_actor:get_actor_mapinfo(RoleID, role),
    mod_map_actor:set_actor_mapinfo(RoleID, role, MapRole#p_map_role{skin = NewSkin}),
    mgeem_map:do_broadcast_insence_include([{role, RoleID}], 
        ?MAP, ?MAP_UPDATE_ROLE, 
        #m_map_update_role_toc{
            role_id     = RoleID, 
            update_list = [{#p_map_role.skin, 1}], 
            skin        = NewSkin
        }).

%% 当前怒气槽与怒气数量的实现：
%% #p_role_fight.nuqi字段记录的是未满的那个怒气槽的怒气（单个的）
add_nuqi(RoleID, AddNuqi) when AddNuqi =/= 0 ->
    RoleMapInfo = mod_map_actor:get_actor_mapinfo(RoleID, role),
	MaxNuqi = cfg_role_nuqi:max_nuqi(),
	OldNuqi = RoleMapInfo#p_map_role.nuqi,
	NewNuqi = OldNuqi+AddNuqi,
	if
		NewNuqi < 0 ->
			{error, nuqi_not_enough};
		OldNuqi < MaxNuqi; AddNuqi < 0 ->
			NewNuqi2 = min(MaxNuqi, NewNuqi),
            NewRoleMapInfo = RoleMapInfo#p_map_role{nuqi=NewNuqi2},
            mod_map_actor:set_actor_mapinfo(RoleID, role, NewRoleMapInfo),
            send_role_hmn_change(RoleID, NewRoleMapInfo);
		true ->
			ok
	end;
add_nuqi(_RoleID, _AddNuqi) ->
	ignore.

add_max_nuqi(RoleID) ->
    add_nuqi(RoleID, 1000000).

%% 清除玩家的的怒气
%% Why: 1:爵位压制
clean_role_nuqi(RoleID, _Why) ->
    RoleMapInfo    = mod_map_actor:get_actor_mapinfo(RoleID, role),
    NewRoleMapInfo = RoleMapInfo#p_map_role{nuqi=0},
    mod_map_actor:set_actor_mapinfo(RoleID, role, NewRoleMapInfo),
    send_role_hmn_change(RoleID, NewRoleMapInfo).

get_nuqi_recover_speed(RoleID, MapID, XY, Now) ->
    case cfg_nuqi_pool:is_nuqi_pool_fb(MapID) of
        true -> 
            cfg_nuqi_pool:nuqi_recover_speed(MapID, XY) * 5;
        _ ->
            case is_role_fighting(RoleID, Now) of
                true -> 0;
                _ ->
                    cfg_role_nuqi:default_nuqi_recover_speed()
            end
    end.

%%同步玩家位置
sync_role_pos(RoleID, Line) ->
    case  mod_map_actor:get_actor_pos(RoleID, role) of
        undefined ->
            kick_role(RoleID, Line);
        Pos ->
            mod_map_actor:erase_actor_pid_lastwalkpath(RoleID, role),
            mod_map_actor:erase_actor_pid_lastkeypath(RoleID, role),
            DataRecord = #m_move_sync_toc{roleid=RoleID, pos=Pos},
            mgeem_map:do_broadcast_insence_include([{role, RoleID}], ?MOVE, ?MOVE_SYNC, DataRecord,mgeem_map:get_state())
    end.


reduce_equip_endurance2_1(RoleID) ->
    case get({attack_count, RoleID}) of
        undefined ->
            put({attack_count, RoleID}, 1);
        Num when Num+1 =:= 200 ->
            put({attack_count, RoleID}, 0),
            Reduce = get_endurance_reduce_num(RoleID, Num, attack),
            mod_equip_endurance:decrease(RoleID, {point, Reduce});
        Num ->
            put({attack_count, RoleID}, Num+1)
    end.

reduce_equip_endurance2_2(RoleID) ->
    case get({defen_count, RoleID}) of
        undefined ->
            put({defen_count, RoleID}, 1);
        Num when Num+1 =:= 200 ->
            put({defen_count, RoleID}, 0),
            Reduce = get_endurance_reduce_num(RoleID, Num, defen),
            mod_equip_endurance:decrease(RoleID, {point, Reduce});
        Num ->
            put({defen_count, RoleID}, Num+1)
    end.

%% @doc 每秒最多只能减一点耐久
get_endurance_reduce_num(RoleID, Num, attack) ->
    Now = common_tool:now(),
    R   = case get({last_en_reduce_time_attack, RoleID}) of
        undefined ->
            Num;
        Time ->
            case Num > Now - Time of
                true ->
                    Now - Time;
                _ ->
                    Num
            end
    end,
    put({last_en_reduce_time_attack, RoleID}, Now),
    R;
get_endurance_reduce_num(RoleID, Num, defen) ->
    Now = common_tool:now(),
    R   = case get({last_en_reduce_time_defen, RoleID}) of
        undefined ->
            Num;
        Time ->
            case Num > Now - Time of
                true ->
                    Now - Time;
                _ ->
                    Num
            end
    end,
    put({last_en_reduce_time_defen, RoleID}, Now),
    R.

relive_slice_enter(_, AllSlice) when erlang:length(AllSlice) =:= 0 ->
    ignore;
relive_slice_enter(RoleID, AllSlice) ->
    Module = ?ROLE2, 
    Method = ?ROLE2_RELIVE,
    AroundRoles = mgeem_map:get_all_in_sence_user_by_slice_list(AllSlice),
    Role2 = mod_map_actor:get_actor_mapinfo(RoleID, role),  
    DataRecord2 = #m_role2_relive_toc{return_self=false, map_role=Role2},
    AroundRoles2 = lists:delete(RoleID, AroundRoles),
    mgeem_map:broadcast(AroundRoles2, ?DEFAULT_UNIQUE, Module, Method, DataRecord2).



do_random_move(RoleID, State) ->
    Pos = mod_map_actor:get_actor_pos(RoleID, role),
    #p_pos{tx=TX, ty=TY} = Pos,
    #map_state{grid_width=GridWidth, grid_height=GridHeight} = State,
    {X, Y} = get_random_tx_ty(State#map_state.mapid, TX, TY, GridWidth, GridHeight, 1),
    mod_map_actor:same_map_change_pos(RoleID, role, X, Y, ?CHANGE_POS_TYPE_NORMAL, State).

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


do_return_home(RoleID, State) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            ?ERROR_MSG("do_return_home, cant find role mapinfo, roleid: ~w", [RoleID]);
        RoleMapInfo ->
            FactionID = RoleMapInfo#p_map_role.faction_id,
            MapID = State#map_state.mapid,
            HomeMapID = common_misc:get_home_mapid(FactionID, MapID),
            case MapID =:= HomeMapID of
                true ->
                    {MapID, TX, TY} = common_misc:get_born_info_by_map(MapID),
                    mod_map_actor:same_map_change_pos(RoleID, role, TX, TY, ?CHANGE_POS_TYPE_NORMAL, State);
                false ->
                    {HomeMapID, TX, TY} = common_misc:get_born_info_by_map(HomeMapID),
                    diff_map_change_pos(?CHANGE_MAP_TYPE_RETURN_HOME, RoleID, HomeMapID, TX, TY)
            end
    end.

do_return_peace_village(RoleID)->
    MapID = 10260, %%王城
    {MapID, TX, TY} = common_misc:get_born_info_by_map(MapID),
    diff_map_change_pos(RoleID, MapID, TX, TY).

diff_map_change_pos(RoleID, MapID, TX, TY) ->
    put({enter, RoleID}, {MapID, TX, TY}),
	mod_map_event:notify({role, RoleID}, change_map),
    DataRecord = #m_map_change_map_toc{mapid=MapID, tx=TX, ty=TY},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MAP, ?MAP_CHANGE_MAP, DataRecord).

diff_map_change_pos(ChangeType, RoleID, MapID, TX, TY) ->
    case mgeem_map:get_map_type(MapID) of 
        ?MAP_TYPE_COPY->
            case mod_horse_racing:is_role_in_horse_racing(RoleID) of 
                true ->
                    DataRecord = #m_map_change_map_toc{succ=false, reason=?_LANG_MAP_CHANGE_MAP_IN_HORSE_RACING_STATE},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MAP, ?MAP_CHANGE_MAP, DataRecord);
                false ->
                    diff_map_change_pos_2(ChangeType, RoleID, MapID, TX, TY)
            end;
        _ ->
            diff_map_change_pos_2(ChangeType, RoleID, MapID, TX, TY)
    end.

diff_map_change_pos_2(ChangeType, RoleID, MapID, TX, TY)->    
    %%跨地图传送类型
    put({change_map_type, RoleID}, ChangeType),
    %%打个标记，非跳转点进行跳转需要这一步
    put({enter, RoleID}, {MapID, TX, TY}),
    mod_map_event:notify({role, RoleID}, change_map),
    DataRecord = #m_map_change_map_toc{mapid=MapID, tx=TX, ty=TY},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?MAP, ?MAP_CHANGE_MAP, DataRecord).

do_skill_transfer(ActorID, ActorType,DistRound,State) ->
    Pos = mod_map_actor:get_actor_pos(ActorID,ActorType),
    #p_pos{tx = TX, ty = TY} = Pos,
    {TX2,TY2} = get_random_tx_ty_in_distround(State#map_state.mapid, TX, TY , DistRound, 0),
    mod_map_actor:same_map_change_pos(ActorID, ActorType, TX2, TY2, ?CHANGE_POS_TYPE_NORMAL, State).

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
                    {_, {NewTX,NewTY}} = get_charge_tx_ty(TX,TY,DestTX,DestTY),
                    case NewTX =:= TX andalso NewTY =:= TY of
                        true ->
                            nil;
                        false ->
							mod_map_actor:same_map_change_pos(ActorID,ActorType,NewTX,NewTY,?CHANGE_POS_TYPE_CHARGE,State,DestActorID,DestActorType)
                    end
            end
    end.

get_charge_tx_ty(TX,TY,DestTX,DestTY) ->
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
              case mcm:safe_type(mgeem_map:get_mapid(), {TX, TY}) of
                  undefined ->
                      {Acc0,Acc1};
                  safe ->
                      get_charge_tx_ty2(X,Y,TX,TY,Acc0,Acc1);
                  not_safe ->
                      get_charge_tx_ty2(X,Y,TX,TY,Acc0,Acc1);
                  _ ->
                      case get({ref,TX,TY}) of
						  undefined ->
							  get_charge_tx_ty2(X,Y,TX,TY,Acc0,Acc1);
                          [] ->
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

do_bubble_msg(RoleID, Line, DataIn, State) ->
    Msg = DataIn#m_bubble_send_tos.msg,
    Type = DataIn#m_bubble_send_tos.action_type,
    ToRoleID = DataIn#m_bubble_send_tos.to_role_id,
    case mod_map_actor:get_actor_txty_by_id(RoleID, role) of
        {TX2, TY2}->
            {ok, RoleBase} = mod_map_role:get_role_base(RoleID),

            DataRecord = #m_bubble_msg_toc{
              actor_type=1, 
              actor_id=RoleID, 
              actor_name=RoleBase#p_role_base.role_name,
              actor_sex=RoleBase#p_role_base.sex,
              actor_faction=RoleBase#p_role_base.faction_id,
              action_type = Type,
              actor_head=RoleBase#p_role_base.head,
              msg=Msg,
              to_role_id=ToRoleID},

            OffsetX = State#map_state.offsetx,
            OffsetY = State#map_state.offsety,
            AllSlice = mgeem_map:get_9_slice_by_txty(TX2, TY2, OffsetX, OffsetY),
            RoleIDList = mgeem_map:get_all_in_sence_user_by_slice_list(AllSlice),
            mgeem_map:broadcast(RoleIDList, 
                                  ?DEFAULT_UNIQUE, 
                                  ?BUBBLE, 
                                  ?BUBBLE_MSG, 
                                  DataRecord),
            case Type of
                1->global:send(mgeel_stat_server,{big_face,Msg});
                _->ignore
            end;
        undefined ->
            mod_map_role:kick_role(RoleID, Line)
    end.


do_change_titlename(RoleID, TitleID, TitleName, TitleColor, State) ->
    {ok, RoleBase} = get_role_base(RoleID),
    #p_role_base{cur_title=OldTitleName} = RoleBase,
    RoleTitles = common_title:get_role_sence_titles(RoleID),

    %% 如果当前的称号还有效的话，就不换了
    case lists:keyfind(OldTitleName, #p_title.name, RoleTitles) of
        false ->
            change_titlename(RoleID, RoleBase, TitleID, TitleName, TitleColor, State);
        _ -> ignore
    end.

%% 用于强行更换玩家称号显示
do_change_titlename_ex(RoleID, TitleID, TitleName, TitleColor) ->
    {ok, RoleBase} = get_role_base(RoleID),
    #p_role_base{cur_title=OldTitleName} = RoleBase,

    case OldTitleName =/= TitleName of
        true ->
            change_titlename(RoleID, RoleBase, TitleID, TitleName, TitleColor, mgeem_map:get_state());
        _ ->
            ignore
    end.

change_titlename(RoleID, RoleBase, TitleID, TitleName, TitleColor, _State) ->
    RoleBase2 = RoleBase#p_role_base{cur_title=TitleName, cur_title_color=TitleColor},
    common_transaction:transaction(fun() ->set_role_base(RoleID, RoleBase2) end),
    
    DataRecord = #m_title_change_cur_title_toc{succ=true, id=TitleID, color=TitleColor},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?TITLE, ?TITLE_CHANGE_CUR_TITLE, DataRecord),

    update_map_role_info(RoleID, 
        [
            {#p_map_role.cur_title, TitleName},
            {#p_map_role.cur_title_color, TitleColor}
        ]
    ).
    % mod_map_role:update_map_role_info(RoleID, [{#p_map_role.qq_yvip, mod_map_actor:get_map_qq_yvip(RoleID)}]).
    
    % NewMapInfo = MapInfo#p_map_role{cur_title=TitleName,cur_title_color=TitleColor},
    % mod_map_actor:set_actor_mapinfo(RoleID,role,NewMapInfo),

    % Record = #m_map_update_actor_mapinfo_toc{
	%     actor_id = RoleID,
	%     actor_type = ?TYPE_ROLE,
	%     role_info = NewMapInfo
	% },
	% mgeem_map:send({broadcast_in_sence_include,
	% 	[RoleID], ?MAP, ?MAP_UPDATE_ACTOR_MAPINFO, Record}).

role_dead(RoleID, RoleMapInfo1, SActorID, SActorType, SActorName, MapID) ->
    case common_transaction:transaction(
           fun() ->
                   t_do_role_dead(RoleID)
           end)
    of
        {atomic, {ok, RoleBase}} ->
            %%召回出战中的异兽
            catch mod_map_pet:role_pet_quit(RoleID),
			RoleMapInfo2 = RoleMapInfo1#p_map_role{hp=0,state=?ROLE_STATE_DEAD,gray_name=false},
			mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo2),
            Record = #m_map_update_actor_mapinfo_toc{actor_id=RoleID, actor_type=?TYPE_ROLE, role_info=RoleMapInfo2},
        	mgeem_map:do_broadcast_insence_include([{role, RoleID}], ?MAP, ?MAP_UPDATE_ACTOR_MAPINFO, Record),
			%%死亡广播
            MapState = mgeem_map:get_state(),
            ToOther = #m_role2_dead_other_toc{roleid=RoleID},
            mgeem_map:do_broadcast_insence([{role, RoleID}], ?ROLE2, ?ROLE2_DEAD_OTHER, ToOther, MapState),
            IsInArenaSingleMap = mod_arena:is_in_arena_single_map(),
            IsInJail = mod_jail:check_in_jail(MapID),
            %% PK值达到一定数量时，直接在监狱复活
            #p_role_base{pk_points=PKPoints} = RoleBase,
            [JailPKPoints] = common_config_dyn:find(jail, jail_in_pkpoints),

            SActorName2 = get_killer_name(SActorID, SActorType, SActorName),
            if
                IsInArenaSingleMap->
                    %% 个人擂台
                    Record = #m_role2_dead_toc{killer=SActorName2, dead_type=?DEAD_TYPE_ARENA_FB_SINGLE},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_DEAD, Record);
                
                PKPoints >= JailPKPoints andalso (not IsInJail) ->
                    %% 抓进监狱广播
                    #p_role_base{faction_id=FactionID, role_name=RoleName} = RoleBase,
                    case SActorType of
                        server_npc ->
                            Msg = common_misc:format_lang(?_LANG_JAIL_KILL_BY_SERVER_NPC, [RoleName]);
                        role -> 
                            Msg = common_misc:format_lang(?_LANG_JAIL_KILL_BY_PLAYER, [SActorName, RoleName]);
                        _ ->
                            Msg = common_misc:format_lang(?_LANG_JAIL_KILL_BY_MONSTER, [RoleName])
                    end,
                    common_broadcast:bc_send_msg_faction(FactionID, [?BC_MSG_TYPE_CENTER, ?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD, Msg),
					mod_role2:relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, RoleID, ?RELIVE_TYPE_HOME_FREE_FULL);
                true ->
                    mgeer_role:send(RoleID, {apply, ?MODULE, role_dead_normal, [RoleID, SActorName2, true]})
            end,
            %%死亡hook
            catch hook_map_role:role_dead(RoleID, RoleMapInfo1, SActorID, SActorType);
        {aborted, Error} ->
            ?ERROR_MSG("do_role_dead2, error: ~w", [Error]),
            ignore
    end.

role_dead_normal(RoleID, SActorName2, HookRoleDead)->
    HookRoleDead andalso mod_role2:hook_role_dead(RoleID),
    #map_state{mapid = MapID} = MapState = mgeem_map:get_state(),
    DeadType = case common_config_dyn:find(fb_map, MapID) of
        [#r_fb_map{module=FbModule}]->
            case FbModule of
                mod_hero_fb             -> ?DEAD_TYPE_HERO_FB;
                mod_examine_fb          -> ?DEAD_TYPE_EXAMINE_FB;
                mod_nationbattle_fb     -> ?DEAD_TYPE_NATIONBATTLE_FB;
                mod_crown_arena_fb      -> ?DEAD_TYPE_ARENABATTLE_FB;
                mod_crown_arena_cull_fb -> ?DEAD_TYPE_ARENABATTLE_FB;
                mod_warofking           -> ?DEAD_TYPE_WAROFKING_FB;
                mod_warofmonster        -> ?DEAD_TYPE_WAROFMONSTER_FB;
                mod_bigpve_fb           -> ?DEAD_TYPE_BIGPVE_FB;
                mod_guard_fb            -> ?DEAD_TYPE_GUARD_FB;
                mod_bomb_fb             -> ?DEAD_TYPE_BOMB_FB;
                mod_country_treasure    -> ?DEAD_TYPE_COUNTRY_TREASURE;
                mod_tower_fb            -> ?DEAD_TYPE_TOWER_FB;
                _                       -> ?DEAD_TYPE_NORMAL
            end;
        _ ->
            ?DEAD_TYPE_NORMAL
    end,
    Toc = if
        DeadType =/= ?DEAD_TYPE_NORMAL ->
            #m_role2_dead_toc{killer=SActorName2, dead_type=DeadType};
        true ->
            %%获取原地健康复活需要钱币
            {ok, #p_role_base{faction_id=FactionID}} = get_role_base(RoleID),
            {ok, #p_role_attr{equips=Equips, level=Level}} = get_role_attr(RoleID),
            SilverNeed = get_relive_silver(FactionID, Level, Equips, MapState),
            #m_role2_dead_toc{killer=SActorName2, relive_type=?RELIVE_TYPE, relive_silver=SilverNeed}
    end,
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_DEAD, Toc),
	case get({auto_relive_timer_ref, RoleID}) of
		undefined ->
			%% 记录角色死亡时间
			if
				DeadType =/= ?DEAD_TYPE_NORMAL ->
					put({role_dead_time, RoleID}, 0),
					ReliveTime = ?AUTO_RELIVE_TIME;
				true ->
					put({role_dead_time, RoleID}, common_tool:now()),
					ReliveTime = cfg_relive:original_time(MapID)
			end,
			is_integer(ReliveTime) andalso begin
				TimerRef = erlang:send_after(ReliveTime*1000, self(), {mod_map_role, {auto_relive, RoleID}}),
		    	put({auto_relive_timer_ref, RoleID}, TimerRef)
			end;
		_ ->
			ignore
	end,
    ok.

t_do_role_dead(RoleID) ->
    {ok, RoleBase} = get_role_base(RoleID),
    
    RoleBase2 = RoleBase#p_role_base{status=?ROLE_STATE_DEAD, if_gray_name=false},
    set_role_base(RoleID, RoleBase2),
    
    {ok, RoleBase2}.

%% @doc 死亡惩罚
dead_punish(_RoleID, RoleMapInfo, SActorType, MapState, _Flag) ->
    %% 掉落：银两或道具，国战期间，参战双方不掉落
    #map_state{mapid=MapID} = MapState,
    %%减装备耐久度
    IsInArenaFB = mod_arena:is_in_arena_map(),
    IsInNationBattleMap = mod_nationbattle_fb:is_in_fb_map(),
	IsInArenaBattleMap = mod_crown_arena_fb:is_in_fb_map(),
    case IsInArenaFB orelse IsInNationBattleMap orelse IsInArenaBattleMap of
        true->
            ignore;
        _ ->
            dead_reduce_equip_endurance(RoleMapInfo, SActorType, MapID)
    end.

dead_reduce_equip_endurance(RoleMapInfo, SActorType, MapID) ->
    %%获取耐久度减少的比例，随PK值及攻击角色而变
    Rate = get_reduce_endurance_rate(RoleMapInfo, SActorType, MapID),
    mod_equip_endurance:decrease(RoleMapInfo#p_map_role.role_id, {rate, Rate}).

%% @doc 获取耐久度掉落概率
get_reduce_endurance_rate(RoleMapInfo, SrcActorType, MapID) ->
    #p_map_role{pk_point=PKPoint, faction_id=FactionID} = RoleMapInfo,
    %% 是否在国内，以及是国战期间，概率不同
    case common_misc:if_in_self_country(FactionID, MapID) of
        true ->
            case is_in_waroffaction_dirty(FactionID, MapID) of
                true ->
                    Rate = 100 / 70;
                _ ->
                    Rate = 2
            end;
        _ ->
            case is_in_waroffaction_dirty(FactionID, MapID) of
                true ->
                    Rate = 100 / 45;
                _ ->
                    Rate = 100 / 30
            end
    end,
    %% PK值状况，被谁杀死影响倍数
    PKState = get_pk_state(PKPoint),
    if
        PKState =:= ?PK_STATE_RED andalso SrcActorType =:= role ->
            Rate * 2;
        PKState =:= ?PK_STATE_YELLOW andalso SrcActorType =:= role ->
            Rate * 1.5;
        PKState =:= ?PK_STATE_RED andalso SrcActorType =:= monster ->
            Rate * 1.5;
        PKState =:= ?PK_STATE_YELLOW andalso SrcActorType =:= monster ->
            Rate * 1.3;
        true ->
            Rate
    end.

%% @doc 是否国战，以及是否参战国
is_in_waroffaction(_FactionID) ->
    false.
%%     case mod_waroffaction:get_attack_faction_id() of
%%         FactionID ->
%%             true;
%%         _ ->
%%             case mod_waroffaction:get_defence_faction_id() of
%%                 FactionID ->
%%                     true;
%%                 _ ->
%%                     false
%%             end
%%     end.

%% @doc 是否国战，赃读数据库
is_in_waroffaction_dirty(_FactionID, _MapID) ->
    false.
%%     case db:dirty_read(?DB_WAROFFACTION, 1) of
%%         [WarInfo] ->
%%             #r_waroffaction{defence_faction_id=DFactionID, attack_faction_id=AFactionID} = WarInfo,
%%             [WarMapList] = common_config_dyn:find(etc, {waroffaction_map_id, DFactionID}),
%%             lists:member(MapID, WarMapList) andalso (FactionID =:= DFactionID orelse FactionID =:= AFactionID);
%%         _ ->
%%             false
%%     end.

%%------------------------------------------------------------------------------------------------------------------
%%玩家增加经验
add_exp(RoleID,Increment) ->
    self() ! {mod_map_role, {add_exp, RoleID, Increment}}.

add_buff(RoleID, BuffDetail) ->
    mod_role_buff:add_buff(RoleID, [BuffDetail]).

call_ybc_mission_status(RoleID) ->
    Proc = common_misc:get_world_role_process_name(RoleID),
    gen_server:call({global,Proc},{ybc_mission_status,RoleID}).


%%ChangeMapType: 地图跳转类型，定义见common.hrl，暂时只有镖车用到
do_change_map(RoleID, MapID, TX, TY, ChangeMapType) ->
    put({enter, RoleID}, {MapID, TX, TY}),
    put({change_map_type, RoleID}, ChangeMapType),
	mod_map_event:notify({role, RoleID}, change_map).


get_pk_state(PKPoint) ->
    if
        PKPoint > 19 ->
            ?PK_STATE_RED;
        PKPoint > 0 ->
            ?PK_STATE_YELLOW;
        true ->
            ?PK_STATE_WHITE
    end.

do_monster_dead_add_exp(RoleID, Add, MonsterType, RoleState, KillFlag, EnergyIndex) ->
    %% 任务计算怪物时，按最后一刀的功击体来计算
    case KillFlag of
        true ->
            hook_monster_dead_exp:hook({RoleID, MonsterType, Add});
        _ ->
            next
    end,
    %% 当组队时，队员死亡不可以获取经验
    if RoleState =:= ?ROLE_STATE_DEAD ->
           ignore;
       true ->
            if EnergyIndex >= 1 ->
                    do_add_exp(RoleID, Add);
               true ->
                    case do_add_exp(RoleID, Add, false) of
                        {ok, normal} ->
                            %% notify
                            DataRecord = #m_role2_add_exp_toc{exp = Add, type = ?ROLE2_ADD_EXP_TYPE_NO_ENERGY},
                            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ADD_EXP, DataRecord);
                        _ ->
                            ignore
                    end
            end,
           ok
    end,
    try
        %% 玩家精力值小于1时，已在怪物那里直接加了经验
        case EnergyIndex >= 1 of
            true ->
				case mod_map_pet:get_pet_exp(RoleID,Add) of
					undefined ->
						ignore;
					Add2 ->
						mod_map_pet:add_pet_exp(RoleID, common_tool:ceil(Add2),true)
				end;
            _ ->
                ignore
        end
    catch
        _:Error ->
            ?ERROR_MSG("add_pet_exp when role add monster dead exp, error: ~w, stacktrace: ~w", [Error, erlang:get_stacktrace()])
    end.

    
%%增加经验
do_add_exp(RoleID, Add) ->
    case do_add_exp(RoleID, Add, true) of
        {ok, _} ->
            ok;
        Error ->
            Error
    end.

do_add_exp(RoleID, Add, MustNotifyChange) ->
    %% 防止出现小数点
    Add2 = common_tool:ceil(Add),
    case common_transaction:transaction(
           fun() ->
                   t_add_exp(RoleID, Add2)
           end)
    of
        {atomic, {exp_change, Exp}} ->
            if MustNotifyChange ->
                    ExpChange = #p_role_attr_change{change_type=?ROLE_EXP_CHANGE, new_value=Exp},
                    DataRecord = #m_role2_attr_change_toc{roleid=RoleID, changes=[ExpChange]},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, DataRecord);
               true ->
                    ignore
            end,
            hook_activity_schedule:hook_exp_change(RoleID, Add2),
            {ok, normal};

        {atomic, {level_up, Level, RoleAttr, RoleBase}} ->
            do_after_level_up(Level, RoleAttr, RoleBase, Add2, ?DEFAULT_UNIQUE, true),
            hook_activity_schedule:hook_exp_change(RoleID, Add2),
            {ok, level_up};
        %% 悲剧的写法
        {aborted, ?_LANG_ROLE2_ADD_EXP_EXP_FULL} ->
            DataRecord = #m_role2_exp_full_toc{text=?_LANG_ROLE2_ADD_EXP_EXP_FULL},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_EXP_FULL, DataRecord),
            {fail,?_LANG_ROLE2_ADD_EXP_EXP_FULL};

        {aborted, Reason} when is_binary(Reason) ->
            {fail,Reason};
        {aborted, Reason} ->
            ?ERROR_MSG("do_add_exp, reason: ~w", [Reason]),
            {fail,Reason}                                      
    end.

%%level: 原等级，roleattr, rolebase：新的角色属性，online: 角色是否在线
do_after_level_up(Level, RoleAttr, RoleBase, Add, Unique, Online) ->
    #p_role_attr{role_id=RoleID, role_name=RoleName, level=Level2, exp=Exp, next_level_exp=NextLevelExp, 
                 remain_skill_points=RemainSkillPoint} = RoleAttr,
    #p_role_base{faction_id=FactionID, max_hp=MaxHP, max_mp=MaxMP} = RoleBase,
    
    %% 升级时进行持久化，25级以上才进行立即持久化
    case Level2>= 25  of
        true->
            mgeem_persistent:role_base_attr_bag_persistent(RoleBase, RoleAttr);
        _ ->
            ignore
    end,

    %%通知排行榜，20级以上才通知排行榜
    case Level2 >= 20 of
        true ->
            #p_role_attr{category=Category} = RoleAttr,
            RankSendInfo = {RoleID,Level2,Exp,RoleName,Category},
            common_rank:update_element( ranking_role_level, RankSendInfo),
            ok;
        _ ->
            ignore
    end,

    %%玩家升级hook触发点~~大家可以往 hook_level_change 模块 里面堆自己的代码 别在这里
    %%该函数返回ok
    hook_level_change:hook({RoleID, Level, Level2, FactionID}),
    %%发送等级信件
    case common_config_dyn:find(etc, is_send_level_mail)of
        [true]->
            send_level_up_mail(RoleID, RoleName, Level, Level2);
        _ ->
            ignore
    end,
    case Online of
        true ->
            %%通知地图角色升级
            mgeem_map:send({mod_map_role, {level_up, RoleID, RoleAttr, RoleBase}}),
            %%升级消息通知
            DataRecord = #m_role2_levelup_toc{
              level          = Level2,
              maxhp          = MaxHP,
              maxmp          = MaxMP,
              skill_points   = RemainSkillPoint,
              exp            = Exp,
              next_level_exp = NextLevelExp,
              total_add_exp  = Add
             },
            common_misc:unicast({role, RoleID}, Unique, ?ROLE2, ?ROLE2_LEVELUP, DataRecord),
            
            %%前10级自动加属性点后通知新的rolebase
            [AutoAddAttrRoleLevel] = common_config_dyn:find(etc,auto_add_attr_role_level),
            case Level2 < AutoAddAttrRoleLevel of
                true ->
                    DataRecord2 = #m_role2_base_reload_toc{role_base=RoleBase},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_BASE_RELOAD, DataRecord2);
                false ->
                    ignore
            end,

            %% 20级以下不广播特级消息，前端不播特效。。。
            case Level2 < 20 of
                true ->
                    ignore;
                _ ->
                    ToOther = #m_role2_levelup_other_toc{roleid=RoleID},
                    mgeem_map:broadcast([RoleID], ?ROLE2, ?ROLE2_LEVELUP_OTHER, ToOther)
            end,
            ok;
        _ ->
            ignore
    end.

t_add_exp(RoleID, 0) -> 
    {ok, RoleAttr} = get_role_attr(RoleID),
    {exp_change, RoleAttr#p_role_attr.exp};
    
t_add_exp(RoleID, Add) when Add > 0 ->
    Add2 = common_tool:ceil(Add),
    case get_role_attr(RoleID) of
        {ok, RoleAttr} ->
            #p_role_attr{exp=Exp, level=Level, next_level_exp=NextLevelExp} = RoleAttr,
            %% 当前经验如果已经储满的话，则不能再获得经验
            case Exp >= NextLevelExp * ?ROLE_EXP_FULL_BEYOND_MULTIPLE andalso Add > 0 of
                true ->
                    common_transaction:abort(?_LANG_ROLE2_ADD_EXP_EXP_FULL);
                _ ->
                    ok
            end,
            Exp2 = Exp + Add2,
            case Exp2 >= NextLevelExp of
                true ->
                    [AutoLevelUp] = common_config_dyn:find(etc, auto_level_up),
                    case Level < AutoLevelUp of
                        true ->
                            AddExpResult = t_auto_level_up(RoleAttr, Exp2),
                            case AddExpResult of
                                {error, skill_not_satify} ->
                                    t_add_exp2(RoleAttr, Exp2);
                                _ ->
                                    AddExpResult
                            end;
                        _ ->
                            t_add_exp2(RoleAttr, Exp2)
                    end;
                _ ->
                    t_add_exp2(RoleAttr, Exp2)
            end;
        _ -> common_transaction:abort(<<"未知错误，获取不到RoleAttr">>)
    end.

t_add_exp2(RoleAttr, Exp) ->
    RoleAttr2 = RoleAttr#p_role_attr{exp=Exp},
    set_role_attr(RoleAttr#p_role_attr.role_id, RoleAttr2),
    {exp_change, Exp}.

t_auto_level_up(RoleAttr, Exp) ->
    #p_role_attr{role_id=RoleID, level=Level} = RoleAttr,
    {ok, RoleBase} = get_role_base(RoleID),
    {Level2, Exp2} = mod_exp:get_new_level(Exp, Level),
    t_level_up(RoleAttr, RoleBase, Level, Level2, Exp2).
 
send_level_up_mail(RoleID, _RoleName, _Level, Level2) ->
    if
        Level2 =:= 30 ->
            Text = common_letter:create_temp(?LEVEL_THIRTY_LETTER,[]);
        Level2 =:= 35 ->
            Text = common_letter:create_temp(?LEVEL_THIRTY_FIVE_LETTER,[]);
        Level2 =:= 39 ->
            Text = common_letter:create_temp(?LEVEL_THIRTY_NINE_LETTER,[]);
        true ->
            Text = 0
    end,
    
    case Text =/= 0 of
        true ->
            common_letter:sys2p(RoleID,Text,"快速升级提示",5);
        _ ->
            ignore
    end.

level_up(RoleAttr, RoleBase, Level, Level2, Exp) ->
    case db:transaction(
           fun() ->
                   t_level_up(RoleAttr, RoleBase, Level, Level2, Exp)
           end)
    of
        {atomic, {level_up, Level, RoleAttr2, RoleBase2}} ->
            do_after_level_up(Level, RoleAttr2, RoleBase2, Exp, ?DEFAULT_UNIQUE, true);
        {atomic, {error, skill_not_satify}} ->
            RoleID = RoleBase#p_role_base.role_id,
            DataRecord = #m_common_error_toc{error_str = <<"怒气技能形态不满足">>},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR, DataRecord);
        {aborted, R} ->
            ?ERROR_MSG("level_up, r: ~w", [R])
    end.

t_level_up(RoleAttr, RoleBase, Level, Level2, Exp) ->
	#p_role_attr{role_id = RoleID, category = Category} = RoleAttr,
    SkillSatisfy = case cfg_role_attr:up_req_skill(Category, Level) of
        [] -> true;
        ReqSkills ->
            RoleSkills = mod_role_skill:get_role_skill_list(RoleID),
            lists:any(fun
                (ReqSkillID) ->
                    lists:keymember(ReqSkillID, #r_role_skill_info.skill_id, RoleSkills)
            end, ReqSkills)
    end,
    if
        SkillSatisfy ->
        	{BaseStr, BaseDex, BaseInt, BaseMen, BaseCon} = cfg_role_attr:get_new_attr_points(Level2),
            [#p_level_exp{exp = NextExp}] = common_config_dyn:find(level, Level2),
        	RoleAttr2 = RoleAttr#p_role_attr{level=Level2, exp=Exp, next_level_exp=NextExp},
        	RoleBase2 = case Category =:= 1 orelse Category =:= 2 of
        		true ->
        			RoleBase#p_role_base{
        				base_str=BaseStr,
        				base_con=BaseCon,
        				base_dex=BaseDex,
        				base_men=BaseMen
        			};
        		false ->
        			RoleBase#p_role_base{
        				base_int=BaseInt,
        				base_con=BaseCon,
        				base_dex=BaseDex,
        				base_men=BaseMen
        			}
        	end,
        	%% 重算属性
            mod_role_tab:put({?role_attr, RoleID}, RoleAttr2),
            RoleBase3 = mod_role_base:upgrade(RoleBase, RoleBase2),
            {level_up, Level, RoleAttr2, RoleBase3};
        true ->
            {error, skill_not_satify}
    end.

%%10级以下玩家免费复活
get_relive_silver(_FactionID, Level, _Equips, _MapState) when Level =< 10 ->
    0;
get_relive_silver(_FactionID, Level, Equips, MapState) ->
    MapId = MapState#map_state.mapid,
    case Equips =:= undefined of
        true ->
            Equips2 = [];
        _ ->
            Equips2 = Equips
    end,
    
    AllIndex =
        lists:foldl(
          fun(Equip, I) ->
                  RefinIndex = Equip#p_goods.refining_index,
                  I + RefinIndex
          end, 10, Equips2),
    SilverNeed = if MapId =:= ?COUNTRY_TREASURE_MAP_ID ->
                        ReliveSilver = common_tool:ceil(AllIndex*Level/10),
                        if ReliveSilver < 20 ->
                               20;
                           true ->
                               ReliveSilver
                        end;
                    true ->
                        common_tool:ceil(AllIndex*Level/2)
                 end,
	case cfg_relive:original_silver(MapId) of
		undefined ->
			SilverNeed;
		{_, DeductSilver} ->
			DeductSilver
	end.

update_role_id_list_in_transaction(RoleId, Key, KeyBk) ->
    case erlang:get(?role_id_list_in_transaction) of
        undefined ->
            erlang:throw({error, not_in_transaction});
        BkList ->
            case lists:member({RoleId, Key, KeyBk}, BkList) of
                true ->
                    ignore;
                _ ->
                    erlang:put(?role_id_list_in_transaction, [{RoleId, Key, KeyBk}|BkList]),
                    OldValue = case mod_role_tab:backup({Key, RoleId}) of
                        undefined -> erlang:get({Key, RoleId});
                        Value -> Value
                    end,
                    OldValue =/= undefined andalso erlang:put({KeyBk, RoleId}, OldValue)
            end
    end.

%% @doc 更新角色战斗时间，用于战斗状态判定
%% @spec 只有与玩家战斗的时候才会更新此状态
update_role_fight_time(RoleID, ActorType, ActorID, SkillEffectType) ->
    case not (ActorType == role andalso ActorID == RoleID) andalso 
         SkillEffectType =/= ?SKILL_EFFECT_TYPE_FRIEND andalso
         SkillEffectType =/= ?SKILL_EFFECT_TYPE_FRIEND_ROLE of
        true ->
            put({role_fight_time, RoleID}, common_tool:now());
        _ ->
            ignore
    end.

%% @doc 是否处于战斗状态
is_role_fighting(RoleID) ->
    case get({role_fight_time, RoleID}) of
        undefined ->
            false;
        FightTime ->
            not (common_tool:now() - FightTime >= ?CLEAR_FIGHT_STATE_DIFF)
    end.

is_role_fighting(RoleID, Now) ->
    case get({role_fight_time, RoleID}) of
        undefined ->
            false;
        FightTime ->
            not (Now - FightTime >= ?CLEAR_FIGHT_STATE_DIFF)
    end.

%%@doc 更新最后一次登录时间
update_online_time(RoleID)->
    [RoleExt] = db:dirty_read(?DB_ROLE_EXT, RoleID),
    RoleExt2 = RoleExt#p_role_ext{last_login_time=common_tool:now()},
    db:dirty_write(?DB_ROLE_EXT, RoleExt2).

%% @doc 纪录角色下线时间及IP
update_offline_time_and_ip(RoleID, ClientIP) ->
    {ok, RoleAttr} = get_role_attr(RoleID),
    RoleAttr2 = RoleAttr#p_role_attr{last_login_ip=common_tool:ip_to_str(ClientIP)},
    common_transaction:transaction(fun() -> mod_map_role:set_role_attr(RoleID, RoleAttr2) end),
    
    [RoleExt] = db:dirty_read(?DB_ROLE_EXT, RoleID),
    RoleExt2 = RoleExt#p_role_ext{last_offline_time=common_tool:now()},
    db:dirty_write(?DB_ROLE_EXT, RoleExt2).

%%同步角色某些属性更新到map
update_role_attr({family_contribute,Value},RoleID) ->
    {ok, RoleAttr} = get_role_attr(RoleID),
    RoleAttr2 = RoleAttr#p_role_attr{family_contribute=Value},
    common_transaction:transaction(fun() -> mod_map_role:set_role_attr(RoleID, RoleAttr2) end).


hook_role_enter_map(RoleID, MapID)->
    catch map_enter_broadcast(RoleID, MapID),
    case common_misc:is_in_noattack_buff_valid_map(MapID) of
        true->
            ignore;
        _ ->
            remove_noattack_buff(RoleID,?_LANG_ROLE2_REMOVE_NOATTACK_BUFF_MAP)
    end.

%%@doc 删除免战牌的BUFF
remove_noattack_buff(RoleID,Reason) when is_binary(Reason)->
    %%  {1041, add_noattack}, 
    NoAttackBuffType = 1041,
    case mod_map_role:get_role_base(RoleID) of
        {ok,#p_role_base{buffs=RoleBuffs}}->
            case lists:any(fun(E)->#p_actor_buf{buff_type=BuffType} = E, BuffType=:=NoAttackBuffType end, RoleBuffs) of
                true->
                    mod_role_buff:del_buff_by_type(RoleID, NoAttackBuffType),
                    common_broadcast:bc_send_msg_role(RoleID, [?BC_MSG_TYPE_SYSTEM,?BC_MSG_TYPE_CENTER], Reason),
                    ok;
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.
    
%% @doc 进入地图广播，外国人进入本国地图，及满足一定条件
map_enter_broadcast(RoleID, MapID) ->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    #p_role_base{role_name=RoleName, faction_id=FactionID} = RoleBase,
    
    %% 中立区、副本或本国不用广播
    case get_map_faction_id(MapID) of
        {ok, copy_or_neutral} ->
            ignore;
        {ok, FactionID} ->
            ignore;
        {ok, MFID} ->
            {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
            #p_role_attr{gongxun=GongXun} = RoleAttr,
            
            %% 战功低于50不用广播
            case GongXun >= 50 of
                true ->
                    map_enter_broadcast2(RoleID, RoleName, FactionID, MapID, MFID, GongXun);
                _ ->
                    ignore
            end
    end.

map_enter_broadcast2(RoleID, RoleName, FactionID, MapID, MFID, GongXun) ->
    FactionName = common_misc:get_faction_name(FactionID),
    MapName = common_map:get_map_str_name(MapID),
    
    if
        GongXun < 100 ->
            Msg = io_lib:format("~s危险人物[~s]在~s出没，广大势力成员请做好防范工作", [FactionName, RoleName, MapName]);
        GongXun < 200 ->
            Msg = io_lib:format("~s丧心病狂[~s]在~s出没，广大势力成员请做好防范工作", [FactionName, RoleName, MapName]);
        true ->
            Msg = io_lib:format("~s杀人狂魔[~s]在~s出没，广大势力成员请做好防范工作", [FactionName, RoleName, MapName])
    end,
    Msg2 = lists:flatten(Msg),

    TimerRef = erlang:send_after(10000, self(), {mod_map_role, {map_enter_broadcast, RoleID, MFID, Msg2}}),
    put({map_enter_broadcast_timer, RoleID}, TimerRef).

do_map_enter_broadcast(RoleID, MFID, Msg) ->
    common_broadcast:bc_send_msg_faction(MFID, ?BC_MSG_TYPE_CENTER, ?BC_MSG_SUB_TYPE, Msg),
    common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_CENTER, Msg).

%% @doc 根据地图ID获取国家ID
get_map_faction_id(MapID) ->
    case MapID rem 10000 div 1000 of
        0 ->
            {ok, copy_or_neutral};
        FID ->
            {ok, FID}
    end.

%% 删除所有减益buff
clear_all_debuff(RoleID) ->
	case mod_map_actor:get_actor_mapinfo(RoleID, role) of
		undefined ->
			ok;
		MapRoleInfo ->
			#p_map_role{role_id=RoleID, state_buffs=Buffs} = MapRoleInfo,
			RemoveList =
				lists:foldl(
				  fun(#p_actor_buf{buff_id=BuffID,buff_type=BuffType}, Acc) ->
						  [#p_buf{is_debuff=IsDebuff}] = common_config_dyn:find(buffs,BuffID),
						  case IsDebuff of
							  true ->
								  [BuffType|Acc];
							  _ ->
								  Acc
						  end
				  end, [], Buffs),
			mgeer_role:send(RoleID, {mod_map_role, {remove_buff, RoleID, RoleID, role, RemoveList}})
	end.

%% @doc 清除角色身上特殊BUFF，移动时则删除
clear_role_spec_buff_when_move(RoleID) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            ok;
        MapRoleInfo ->
            #p_map_role{role_id=RoleID, state_buffs=Buffs} = MapRoleInfo,
            RemoveList =
                lists:foldl(
                  fun(ActorBuff, Acc) ->
                          BuffId = ActorBuff#p_actor_buf.buff_id,
                          %%隐身，特殊的持续加血
                          case BuffId of
                              ?BUFF_TYPE_HIDDEN_NOT_MOVE->
                                  [BuffId|Acc];
                              ?BUFF_TYPE_ADD_HP_NOT_MOVE->
                                  [BuffId|Acc];
                              _ ->
                                  Acc
                          end
                  end, [], Buffs),
            mod_role_buff:del_buff(RoleID, RemoveList)
    end.

%% @doc 清除角色身上特殊BUFF,主动攻击时则删除           
clear_role_spec_buff_when_attack(RoleID) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            ok;
        MapRoleInfo ->
            #p_map_role{role_id=RoleID, state_buffs=Buffs} = MapRoleInfo,
            RemoveList =
                lists:foldl(
                  fun(ActorBuff, Acc) ->
                          BuffId = ActorBuff#p_actor_buf.buff_id,
                          %%隐身，特殊的持续加血
                          case BuffId of
                              ?BUFF_TYPE_HIDDEN->
                                  [BuffId|Acc];
                              ?BUFF_TYPE_HIDDEN_NOT_MOVE->
                                  [BuffId|Acc];
                              ?BUFF_TYPE_ADD_HP_NOT_MOVE->
                                  [BuffId|Acc];
                              _ ->
                                  Acc
                          end
                  end, [], Buffs),
            mod_role_buff:del_buff(RoleID, RemoveList)
    end.

%% @doc 清除角色的特殊状态，如打坐
clear_role_spec_state(RoleID) ->
    RoleMapInfo = mod_map_actor:get_actor_mapinfo(RoleID, role),
    case RoleMapInfo of
        undefined ->
            ?ERROR_MSG("~ts:~w", ["清理角色状态信息失败了,找不到玩家地图信息", RoleID]);
        RoleMapInfo ->
            #p_map_role{role_id=RoleID, state=State} = RoleMapInfo,
            case State of
                ?ROLE_STATE_ZAZEN ->
                    mod_role_tab:update_element(RoleID, p_role_base, {#p_role_base.status, ?ROLE_STATE_NORMAL}),
                    mod_map_actor:set_actor_mapinfo(RoleID, role, RoleMapInfo#p_map_role{state=?ROLE_STATE_NORMAL}),
                    SumExp = mod_role_on_zazen:del_zazen_total_exp(RoleID),
                    ToSelf = #m_role2_zazen_toc{status=false, sum_exp=SumExp},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ZAZEN, ToSelf),
                    ToOther = #m_role2_zazen_toc{roleid=RoleID, return_self=false, status=false},
                    mgeem_map:do_broadcast_insence([{role, RoleID}], ?ROLE2, ?ROLE2_ZAZEN, ToOther, mgeem_map:get_state()),
                    remove_zazen_buff(RoleID);
                _ ->
                    ok
            end
    end. 

%% @doc 清除打坐buff
remove_zazen_buff(RoleID) ->
    mod_role_buff:del_buff(RoleID, 10532).

%% @doc 角色attr、base定时持久化
role_base_attr_persistent() ->
    Now = common_tool:now(),
    case get(role_base_attr_last_persistent_time) of
        undefined ->
            role_base_attr_persistent2(Now);
        Time ->
            case Now - Time >= ?ROLE_BASE_ATTR_PERSISTENT_INTERVAL of
                true ->
                    role_base_attr_persistent2(Now);
                _ ->
                    ignore
            end
    end.

role_base_attr_persistent3(RoleID, RoleAttr, _Now)->
    case get_role_base(RoleID) of
        {ok, RoleBase} ->
            {ok, RoleFight} = get_role_fight(RoleID),
            mgeem_persistent:role_fight_persistent(RoleFight),
            mgeem_persistent:role_base_attr_bag_persistent(RoleBase, RoleAttr),
            case get_role_accumulate_exp(RoleID) of
                {ok, RoleAccumulateExp} ->
                    mgeem_persistent:role_accumulate_exp_persistent(RoleAccumulateExp);
                _ ->
                    ignore
            end,
            catch mod_mission_data:persistent(RoleID),
            case mod_map_drop:get_role_monster_drop(RoleID) of
                {ok, DropInfo} ->
                    mgeem_persistent:role_monster_drop_persistent(DropInfo);
                _ ->
                    ignore
            end,
			%% 持久化角色Refining Box信息
            case mod_treasbox:get_role_treasbox_info(RoleID) of
                {ok, RoleBoxInfo} ->
                    mgeem_persistent:role_treasbox_persistent(RoleBoxInfo);
                _ ->
                    ignore
            end,
            %% 持久化
            case get_role_goal(RoleID) of
                {ok, RoleGoalInfo} ->
                    mgeem_persistent:role_goal_persistent(RoleGoalInfo);
                _ ->
                    ignore
            end,
            %% 持久化玩家技能
            case mod_skill:get_role_skill_list(RoleID) of
                [] ->
                    ignore;
                SkillList ->
                    mgeem_persistent:role_skill_list_persistent(RoleID, SkillList)
            end,
            %% 玩家地图扩展信息定时持久化
            case get_role_map_ext_info(RoleID) of
                {ok,RoleMapExtInfo}->
                    mgeem_persistent:role_map_ext_info_persistent(RoleID,RoleMapExtInfo);
                _->
                    ignore
            end,
            ok;
        _ ->
            ?ERROR_MSG("~ts: ~w", ["地图在线列表中，存在不在线的角色ID：", RoleID])
    end.

role_base_attr_persistent2(Now) ->
    PersistentRemFlag = get_role_info_persistent_rem_flag(),
    [begin
         case get_role_attr(RoleID) of
             {ok, #p_role_attr{level=Level} = RoleAttr} ->
                 %% 10级以下不做定时持久化，防止推量过猛的问题
                 case Level >= 10 of
                     true ->
                         case RoleID rem 5 =:= PersistentRemFlag of
                             true ->
                                 role_base_attr_persistent3(RoleID, RoleAttr, Now);
                             false ->
                                 ignore
                         end;
                     
                     false ->
                         ignore
                 end;
             _ ->
                 ?ERROR_MSG("~ts: ~w", ["地图在线列表中，存在不在线的角色ID：", RoleID])
         end
     end|| RoleID <- mgeem_map:get_all_roleid()],
    set_role_info_persistent_rem_flag(PersistentRemFlag+1),
    put(role_base_attr_last_persistent_time, Now).

get_role_info_persistent_rem_flag() ->
    case erlang:get(role_info_persistent_rem_flag) of
        IntFlag when is_integer(IntFlag) ->
            IntFlag;
        _ ->
            0
    end.
set_role_info_persistent_rem_flag(F) ->
    erlang:put(role_info_persistent_rem_flag, F rem 5). 

%% @doc 师徒值兑换PK点
do_moral_value_to_pkpoint(MoralPID, RoleID, MoralValue, Msg) ->
    case common_transaction:transaction(
           fun() ->
                   {ok, RoleBase} = get_role_base(RoleID),
                   #p_role_base{pk_points=PKPoints} = RoleBase,

                   ReducePoint = MoralValue div 10,
                   case PKPoints - ReducePoint < 0 of
                       true ->
                           PKPoints2 = 0;
                       _ ->
                           PKPoints2 = PKPoints - ReducePoint
                   end,

                   RoleBase2 = RoleBase#p_role_base{pk_points=PKPoints2},
                   set_role_base(RoleID, RoleBase2),

                   {ok, MoralValue-(PKPoints-PKPoints2)*10, PKPoints-PKPoints2, PKPoints2}
           end)
    of
        {atomic, {ok, ReturnPoint, ReducePoint, PKPoint2}} -> 
            update_map_role_info(RoleID, [{#p_map_role.pk_point, PKPoint2}]),
            MoralPID ! {moral_value_to_pkpoint_succ, RoleID, ReturnPoint, ReducePoint, Msg},
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("do_moral_value_to_pkpoint, error: ~w", [Error]),
            MoralPID ! {moral_value_to_pkpoint_fail, RoleID, MoralValue, Msg}
    end.

%% @doc 设置角色退出游戏标记
set_role_exit_game_mark(RoleID) ->
    erlang:put({exit_game, RoleID}, true).

del_role_exit_game_mark(RoleID) ->
	erlang:erase({exit_game, RoleID}).

%% @doc 角色是否退出游戏
is_role_exit_game(RoleID) ->
    case erlang:get({exit_game, RoleID}) of
        undefined ->
            false;
        _ ->
            true
    end.

%% @doc 获取杀手姓名
get_killer_name(ActorID, ActorType, ActorName) ->
    case ActorType of
        pet ->
            case mod_map_actor:get_actor_mapinfo(ActorID, pet) of
                undefined ->
                    ActorName;
                #p_map_pet{role_id=MasterID} ->
                    case mod_map_role:get_role_base(MasterID) of
                        {ok, MasterBase} ->
                            MasterBase#p_role_base.role_name;
                        _ ->
                            ActorName
                    end
            end;
        _ ->
            ActorName
    end.

%% @doc 重置精力值
do_reset_role_energy(RoleID, Now) ->
    {ok, RoleFight} = get_role_fight(RoleID),
    #p_role_fight{energy=Energy, energy_remain=EnergyRemain} = RoleFight,
    
    case EnergyRemain + Energy >= ?MAX_REMAIN_ENERGY of
        true ->
            EnergyRemain2 = ?MAX_REMAIN_ENERGY;
        _ ->
            EnergyRemain2 = Energy + EnergyRemain
    end,
    
    RoleFight2 = RoleFight#p_role_fight{energy=?DEFAULT_ENERGY, energy_remain=EnergyRemain2, time_reset_energy=Now},
    set_role_fight(RoleID, RoleFight2),
    
    ChangeAttList = [#p_role_attr_change{change_type=?ROLE_ENERGY_CHANGE, new_value=?DEFAULT_ENERGY},
                     #p_role_attr_change{change_type=?ROLE_ENERGY_REMAIN_CHANGE, new_value=EnergyRemain2}],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList).

do_reset_role_energy(RoleID) ->
    {ok, RoleFight} = get_role_fight(RoleID),
    set_role_fight(RoleID, RoleFight#p_role_fight{energy=?DEFAULT_ENERGY}),
    ChangeAttList = [#p_role_attr_change{change_type=?ROLE_ENERGY_CHANGE, new_value=?DEFAULT_ENERGY}],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList).

t_add_role_energy(RoleID, EnergyAdd) ->
    {ok, RoleFight} = get_role_fight(RoleID),
    #p_role_fight{energy=Energy} = RoleFight,
    NewEnergy = 
        case Energy + EnergyAdd >= ?DEFAULT_ENERGY of
            true ->
                ?DEFAULT_ENERGY;
            false ->
                Energy + EnergyAdd
        end,
    set_role_fight(RoleID, RoleFight#p_role_fight{energy=NewEnergy}),
    ChangeAttList = [#p_role_attr_change{change_type=?ROLE_ENERGY_CHANGE, new_value=NewEnergy}],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList),
    {ok, NewEnergy}.

%% @doc 技能返回经验
do_skill_return_exp(_RoleID) ->
    %%代码已废弃
    ignore.

%% @doc 玩家进程字典数据相关处理       
%% @doc 初始化玩家地图进程字典信息，进入地图调用
init_role_map_ext_info(RoleId, ExpInfo) ->
    case ExpInfo of
        undefined ->
            ignore;
        _ ->
            mod_role_tab:put({?role_map_ext, RoleId}, ExpInfo)
    end.
%% @doc 获取玩家地图进程字典扩展信息
get_role_map_ext_info(RoleId) ->
    case mod_role_tab:get({?role_map_ext, RoleId}) of
        undefined ->
            {error, not_found};
        ExtInfo ->
            {ok,ExtInfo}
    end.
%% @doc 清楚玩家地图进程字典信息
erase_role_map_ext_info(RoleId) ->
    mod_role_tab:erase({?role_map_ext, RoleId}).

%% @doc 事务写地图进程字典玩家扩展信息
t_set_role_map_ext_info(RoleId, ExtInfo) ->
    update_role_id_list_in_transaction(RoleId, ?role_map_ext, ?role_map_ext_copy),
    mod_role_tab:put({?role_map_ext, RoleId}, ExtInfo).

%% @doc 
set_role_map_ext_info(RoleId, ExpInfo) ->
    case common_transaction:transaction(
           fun() ->
                   t_set_role_map_ext_info(RoleId,ExpInfo)
           end)
    of
        {atomic, _} ->
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("set_role_map_ext_info, error: ~w", [Error]),
            error
    end.

do_gm_set_enery(RoleID, Energy) ->
    {ok, RoleFight} = get_role_fight(RoleID),
    set_role_fight(RoleID, RoleFight#p_role_fight{energy=Energy}),
    ChangeAttList = [#p_role_attr_change{change_type=?ROLE_ENERGY_CHANGE, new_value=Energy}],
    DataRecord = #m_role2_attr_change_toc{roleid=RoleID, changes=ChangeAttList},
    Info = {role_msg, ?ROLE2, ?ROLE2_ATTR_CHANGE, DataRecord},
    common_misc:chat_cast_role_router(RoleID, Info).
