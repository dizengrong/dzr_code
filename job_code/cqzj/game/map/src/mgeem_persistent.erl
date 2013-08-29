%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2010, 
%%% @doc
%%%     用来将地图进程中的玩家数据保存到mnesia中
%%% @end
%%% Created : 21 Dec 2010 by  <>
%%%-------------------------------------------------------------------
-module(mgeem_persistent).

-include("mgeem.hrl").

%% API
-export([
         start/0,
         start_link/0
        ]).

-export([
		 role_base_attr_bag_persistent/2,
		 role_accumulate_exp_persistent/1,
		 role_pos_persistent/1,
		 role_monster_drop_persistent/1,
		 role_treasbox_persistent/1,
		 role_goal_persistent/1,
		 role_skill_list_persistent/2,
		 role_map_ext_info_persistent/2,
		 role_shortcut_bar_persistent/1,
		 role_fight_persistent/1,
		 pet_persistent/1,
		 pet_bag_persistent/1,
		 pet_grow_persistent/1,
		 pet_task_persistent/1
		]).

-export([
         ybc_persistent/2,
         ybc_persistent/3
        ]).

-export([
         mission_data_persistent/2
        ]).
%% Gen Server Call Back
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% Record Defin
-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

start() ->
    {ok, _} = supervisor:start_child(mgeem_sup, {?MODULE,
                                                 {?MODULE, start_link, []},
                                                 transient, brutal_kill, worker, 
                                                 [?MODULE]}).

%%%================镖车模块 - START==================
ybc_persistent(YbcID, YbcMapInfo) ->
    erlang:send(?MODULE, {ybc_persistent, YbcID, YbcMapInfo}).

ybc_persistent(YbcID, MapID, YbcMapInfo) ->
    erlang:send(?MODULE, {ybc_persistent, YbcID, MapID, YbcMapInfo}).

%%%================镖车模块 - END==================

%%%================角色信息 - START==================

role_base_attr_bag_persistent(RoleBase, RoleAttr) ->
    RoleId = RoleBase#p_role_base.role_id,
    
    RoleBagInfoList = mod_bag:get_role_bag_persistent_info(RoleId),
    erlang:erase({?dict_change_tag, ?role_base, RoleId}),
    erlang:erase({?dict_change_tag, ?role_attr, RoleId}),
    erlang:send(?MODULE, {role_base_attr_bag_persistent, RoleBase, RoleAttr, RoleBagInfoList}).

role_accumulate_exp_persistent(RoleAccumulateExp) ->
    erlang:send(?MODULE, {common_persistent, ?DB_ROLE_ACCUMULATE_P, RoleAccumulateExp}).
%% 玩家位置
role_pos_persistent(RolePos) ->
    erlang:send(?MODULE, {common_persistent, ?DB_ROLE_POS, RolePos}).

role_shortcut_bar_persistent(RoleShortCut) ->
    erlang:send(?MODULE, {common_persistent, ?DB_SHORTCUT_BAR_P, RoleShortCut}).
%% 怪物掉落
role_monster_drop_persistent(DropInfo) ->
    erlang:send(?MODULE, {common_persistent, ?DB_ROLE_MONSTER_DROP_P, DropInfo}).
%% 玩家箱子
role_treasbox_persistent(RefiningBoxInfo) ->
    erlang:send(?MODULE, {common_persistent, ?DB_ROLE_BOX_P, RefiningBoxInfo}).
%% 玩家传奇目标
role_goal_persistent(RoleGoal) ->
    erlang:send(?MODULE, {common_persistent, ?DB_ROLE_GOAL_P, RoleGoal}).


%% 玩家扩展信息
role_map_ext_info_persistent(RoleID,RoleMapExtInfo)->
    erlang:send(?MODULE, {role_map_ext_info,RoleID,RoleMapExtInfo}).

%% 玩家技能
role_skill_list_persistent(RoleID, SkillList) ->
    erlang:send(?MODULE, {role_skill_list, RoleID, SkillList}).
%% 战斗信息
role_fight_persistent(RoleFight) ->
    erlang:send(?MODULE, {common_persistent, ?DB_ROLE_FIGHT, RoleFight}).

%% 异兽
pet_persistent({undefined,PetID}) ->
	erlang:send(?MODULE, {pet_delete,PetID});
pet_persistent(PetInfo) ->
	erlang:send(?MODULE, {common_persistent, ?DB_PET_P, PetInfo}).
pet_bag_persistent(PetBagInfo) ->
	erlang:send(?MODULE, {common_persistent, ?DB_ROLE_PET_BAG_P, PetBagInfo}).
pet_grow_persistent(GrowInfo) ->
	erlang:send(?MODULE, {common_persistent, ?DB_ROLE_PET_GROW, GrowInfo}).
pet_task_persistent(PetTaskRec) ->
    erlang:send(?MODULE, {common_persistent, ?DB_PET_TASK, PetTaskRec}).
%%%================角色信息 - END==================

%%%================任务相关 - START==================
mission_data_persistent(RoleID, MissionData) ->
    erlang:send(?MODULE, {mission_data_persistent, RoleID, MissionData}).
%%%================任务相关 - END==================


%% Gen Server Call Back
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({'EXIT', _, Reason}, State) ->
    ?INFO_MSG("~ts:~w", ["持久化进程关闭", Reason]),
    {stop, normal, State};

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%%%================角色信息 - START==================
do_handle_info({role_base_attr_bag_persistent, RoleBase, RoleAttr,RoleBagInfoList}) ->
    do_role_base_attr_bag_persistent(RoleBase, RoleAttr, RoleBagInfoList);
do_handle_info({common_persistent, Tab, Record}) ->
    db_common_persistent(Tab, Record);
do_handle_info({pet_delete, PetID}) ->
    do_pet_delete(PetID);
do_handle_info({role_map_ext_info,RoleID,RoleMapExtInfo}) ->
    do_role_map_ext_info(RoleID,RoleMapExtInfo);
do_handle_info({role_skill_list, RoleID, SkillList}) ->
    do_role_skill_list(RoleID, SkillList);
%%%================角色信息 - END==================

%%%================镖车模块 - START==================
do_handle_info({ybc_persistent, YbcID, YbcMapInfo}) ->
    do_ybc_persistent(YbcID, YbcMapInfo);

do_handle_info({ybc_persistent, YbcID, MapID, YbcMapInfo}) ->
    do_ybc_persistent(YbcID, MapID, YbcMapInfo);
%%%================镖车模块 - END==================

%%%================任务模块 - START==================
do_handle_info({mission_data_persistent, RoleID, MissionData}) ->
    do_mission_data_persistent(RoleID, MissionData);
%%%================任务模块 - END==================


do_handle_info(Info) ->
    ?ERROR_MSG("mgeem_persistent, unknow info: ~w", [Info]).

db_common_persistent(Tab, Record) ->
    case db:transaction(fun() -> db:write(Tab, Record, write) end) of
        {atomic, ok} ->
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("~ts: ~w, ~w, ~w", ["持久化角色信息出错: ", Tab, Error, Record])
    end.

%%%================宠物模块 - START==================
do_pet_delete(PetID) ->
	case db:transaction(
		   fun() -> db:delete(?DB_PET_P, PetID, write) end)
		of
		{atomic, _} ->
			ok;
		{aborted, Error} ->
			?ERROR_MSG("~ts:~w", ["删除宠物信息出错", Error])
	end.

%%%================宠物模块 - END==================

%%%================镖车模块 - START==================
do_ybc_persistent(YbcID, YbcMapInfo) ->
    case db:transaction(fun() ->
            case db:read(?DB_YBC, YbcID, write) of
                [] ->
                    ignore;
                [YbcInfo] ->
                    NewYbcInfo = mod_map_ybc:get_new_ybc_info(YbcInfo, YbcMapInfo),
                    db:write(?DB_YBC, NewYbcInfo, write)
            end
        end)
    of
        {atomic, _} ->
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("~ts:~w ~w", ["持久化镖车信息出错", Error, YbcMapInfo])
    end.

do_ybc_persistent(YbcID, MapID, YbcMapInfo) ->
    case db:transaction(fun() ->
                                case db:read(?DB_YBC, YbcID, write) of
                                    [] ->
                                        ignore;
                                    [YbcInfo] ->
                                        NewYbcInfo = mod_map_ybc:get_new_ybc_info(YbcInfo, YbcMapInfo),
                                        db:write(?DB_YBC, NewYbcInfo#r_ybc{map_id=MapID}, write)
                                end
                        end)
    of
        {atomic, _} ->
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("~ts:~w ~w", ["持久化镖车信息出错", Error, YbcMapInfo])
    end.
%%%================镖车模块 - END==================
%%%================角色信息 - START==================
do_role_skill_list(RoleID, SkillList) ->
    case db:transaction(
           fun() ->
                   db:write(?DB_ROLE_SKILL_P, #r_role_skill{role_id = RoleID,skill_list = SkillList}, write)
           end)
    of
        {atomic, _} ->
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("持久化角色技能列表出错，error: ~w", [{Error, SkillList}])
    end.

-define( DO_PERSISTENT_RECORD(Tab,RecDefine,Rec),
         if
             Rec =:= undefined->
                 ignore;
             Rec =:= #RecDefine{role_id=RoleID} -> %%默认值不存储
                 ignore;
             is_record(Rec,RecDefine) ->
                 do_simple_persistent_record(Tab,Rec);
             true->
                 ?ERROR_MSG("persistent record error,Tab=~w,Rec=~w",[Tab,Rec]),
                 ignore
         end).

%% 默认值也持久化
-define( DO_PERSISTENT_RECORD2(Tab,RecDefine,Rec),
         if
             Rec =:= undefined->
                 ignore;
             is_record(Rec,RecDefine) ->
                 do_simple_persistent_record(Tab,Rec);
             true->
                 ?ERROR_MSG("persistent record error,Tab=~w,Rec=~w",[Tab,Rec]),
                 ignore
         end).
    


%% 玩家地图扩展信息持久化
%% 包括这种信息和那种信息
do_role_map_ext_info(RoleID,RoleMapExtInfo)->
    #r_role_map_ext{training_pets=TrainingPets,role_grow=RoleGrowInfo,
                    role_guide=RoleGuideInfo, energy_drug_usage=RoleEnergyUsageInfo,
                    lianqi=RoleLianqiInfo, caishen=RoleCaishenInfo,
                    role_present=RolePresentInfo,role_examine_fb=RoleExamineFbInfo,shenqi=RoleShenqiInfo,
					bag_shop=RoleBagShopInfo,
					vip=RoleVipInfo,role_mine_fb=RoleMineFbInfo,daily_pay_reward=RoleDailyPayReward,
					role_tili=RoleTili,item_use_limit=ItemUseLimit,
					access_guide=RoleAccessGuideInfo,daily_mission=RoleDailyMissionInfo,
					role_guard_fb=RoleGuardFbInfo,jinglian=JinglianInfo} = RoleMapExtInfo,
	?DO_PERSISTENT_RECORD2( ?DB_PET_TRAINING_P,r_pet_training,TrainingPets ),
    ?DO_PERSISTENT_RECORD( ?DB_ROLE_GROW_P,r_role_grow,RoleGrowInfo ),
    ?DO_PERSISTENT_RECORD( ?DB_ROLE_GUIDE_TIP_P,r_role_guide_tip,RoleGuideInfo ),
    ?DO_PERSISTENT_RECORD( ?DB_ROLE_ENERGY_DRUG_USAGE_P,r_role_energy_drug_usage,RoleEnergyUsageInfo ),
    ?DO_PERSISTENT_RECORD( ?DB_ROLE_LIANQI_P,r_role_lianqi,RoleLianqiInfo ),
    ?DO_PERSISTENT_RECORD( ?DB_ROLE_CAISHEN_P,r_role_caishen,RoleCaishenInfo ),
    ?DO_PERSISTENT_RECORD( ?DB_ROLE_PRESENT_P,r_role_present,RolePresentInfo ),
    ?DO_PERSISTENT_RECORD( ?DB_ROLE_EXAMINE_FB_P,r_role_examine_fb,RoleExamineFbInfo ),
    ?DO_PERSISTENT_RECORD( ?DB_ROLE_SHENQI_P,r_role_shenqi,RoleShenqiInfo ),
    ?DO_PERSISTENT_RECORD( ?DB_ROLE_BAG_SHOP_P,r_role_bag_shop,RoleBagShopInfo ),
    ?DO_PERSISTENT_RECORD( ?DB_ROLE_VIP_P,r_role_vip,RoleVipInfo ),
    ?DO_PERSISTENT_RECORD( ?DB_ROLE_MINE_FB_P,r_role_mine_fb,RoleMineFbInfo ),
    ?DO_PERSISTENT_RECORD( ?DB_ROLE_DAILY_PAY_REWARD_P,r_role_daily_pay_reward,RoleDailyPayReward ),
    ?DO_PERSISTENT_RECORD( ?DB_ROLE_TILI_P,r_role_tili,RoleTili ),
    ?DO_PERSISTENT_RECORD( ?DB_ITEM_USE_LIMIT_P,r_item_use_limit,ItemUseLimit ),
	?DO_PERSISTENT_RECORD( ?DB_ROLE_ACCESS_GUIDE_P,r_access_guide,RoleAccessGuideInfo ),
	?DO_PERSISTENT_RECORD( ?DB_ROLE_DAILY_MISSION_P,r_role_daily_mission,RoleDailyMissionInfo ),
	?DO_PERSISTENT_RECORD( ?DB_ROLE_GUARD_FB_P,r_role_guard_fb,RoleGuardFbInfo ),
	?DO_PERSISTENT_RECORD( ?DB_JINGLIAN_P,r_jinglian,JinglianInfo ),
    ok.

do_simple_persistent_record(Tab,Rec)->
    TransFun = fun()-> 
                       db:write(Tab,Rec,write)
               end,
    case db:transaction( TransFun ) of
        {atomic,_}->
            ok;
        {aborted,Error}->
            ?ERROR_MSG("do_simple_persistent_record error,Tab=~w,Rec=~w,Error=~w", [Tab, Rec,Error])
    end.

%% 部分宗族、官职的数据是不采用 地图中的缓存数据
do_role_base_attr_bag_persistent(RoleBase, RoleAttr, RoleBagInfoList) ->
    case db:transaction(
           fun() -> %%RoleName可能也需要在此进行持久化
                   RoleID = RoleBase#p_role_base.role_id, 
                   [#p_role_base{family_id=FamilyID, family_name=FamilyName, account_name=AccountName}] = db:read(?DB_ROLE_BASE, RoleBase#p_role_base.role_id, write),
                   [#p_role_attr{office_id=OfficeID, 
                                 office_name=OfficeName,
                                 is_payed=IsPayed,
                                 family_contribute=FC}] = db:read(?DB_ROLE_ATTR, RoleID, write),
                   db:write(?DB_ROLE_BASE, RoleBase#p_role_base{family_id=FamilyID, family_name=FamilyName,account_name=AccountName}, write),
                   db:write(?DB_ROLE_ATTR, RoleAttr#p_role_attr{office_id=OfficeID, office_name=OfficeName, is_payed=IsPayed,
                                                                family_contribute=FC}, write),
                   common_bag2:t_persistent_role_bag_info(RoleBagInfoList),
                   ok
           end)
        of
        {atomic, _} ->
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("do_role_base_attr_bag_persistent error,Error=~w", [Error]),
            case Error of
                {no_exists,_}->
                    ?ERROR_MSG("找不到mnesia表，可能world节点挂了!", []);
                _ ->
                    ignore
            end
    end.

%%%================角色信息 - END==================

%%%================任务模块 - START==================
do_mission_data_persistent(RoleID, MissionData) 
  when is_record(MissionData, mission_data) ->
    db:dirty_write(?DB_MISSION_DATA_P, 
                   #r_db_mission_data{
                    role_id=RoleID,
                    mission_data=MissionData});
do_mission_data_persistent(RoleID, MissionData) ->
    ?ERROR_MSG("~ts:RoleID-->~w, MissionData-->~w, Trace:~w", 
               ["试图存储任务数据，但数据非法，不是record mission_data", 
               RoleID, 
               MissionData,
               erlang:get_stacktrace()]).
%%%================任务模块 - END==================
