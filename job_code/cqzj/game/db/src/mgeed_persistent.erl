-module(mgeed_persistent).

-include("mgeed.hrl").

-export([load_account_data/1, persistent_account_info/1]).

-define(WRITE_ROLE_RECORD(Table,Rec),
        case Rec of
            undefined-> ignore;
            _ -> db:dirty_write(Table,Rec)
        end
       ).
-define(READ_ROLE_RECORD(Table,Rec),
        case db:dirty_read(Table, RoleID) of
            [] -> Rec = undefined;
            [Rec] -> next
        end
       ).

-define(READ_ROLE_DEF_RECORD(Table,RecDefine,Rec),
        case db:dirty_read(Table, RoleID) of
            [] -> Rec = #RecDefine{role_id=RoleID}; %%赋予默认值
            [Rec] -> next
        end
       ).

-define(WRITE_ROLE_DEF_RECORD(Tab,RecDefine,Rec),
         if
             Rec =:= undefined->
                 ignore;
             is_record(Rec,RecDefine) ->
                 db:dirty_write(Tab,Rec);
             true->
                 ?ERROR_MSG("persistent record error,Tab=~w,Rec=~w",[Tab,Rec]),
                 ignore
         end).

%%@doc 获取玩家数据
load_account_data(RoleID) ->
    {ok,RoleDetail} = do_get_role_detail(RoleID),
    
    ?READ_ROLE_RECORD( ?DB_ROLE_ACCUMULATE_P, RoleAccumulateInfo),
    ?READ_ROLE_RECORD( ?DB_ROLE_HERO_FB_P, RoleHeroFbInfo),
    ?READ_ROLE_RECORD( ?DB_ROLE_BOX_P, RoleBoxInfo),
    ?READ_ROLE_RECORD( ?DB_ROLE_GOAL_P, RoleGoalInfo),
    ?READ_ROLE_RECORD( ?DB_SHORTCUT_BAR_P, RoleShortcut),
    
    ?READ_ROLE_DEF_RECORD( ?DB_PET_TRAINING_P,r_pet_training, PetTrainingInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_GROW_P, r_role_grow,RoleGrowInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_GUIDE_TIP_P,r_role_guide_tip, RoleGuideInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_ENERGY_DRUG_USAGE_P, r_role_energy_drug_usage, RoleEnergyUsageInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_LIANQI_P, r_role_lianqi,RoleLianqiInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_CAISHEN_P, r_role_caishen,RoleCaishenInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_PRESENT_P, r_role_present,RolePresentInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_EXAMINE_FB_P, r_role_examine_fb,RoleExamineFbInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_SHENQI_P, r_role_shenqi,RoleShenqiInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_BAG_SHOP_P, r_role_bag_shop,RoleBagShopInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_VIP_P, r_role_vip,RoleVipInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_MINE_FB_P, r_role_mine_fb,RoleMineFbInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_DAILY_PAY_REWARD_P, r_role_daily_pay_reward,RoleDailyPayReward),
	?READ_ROLE_DEF_RECORD( ?DB_GUIDE_P,r_guide, Guide),
	?READ_ROLE_DEF_RECORD( ?DB_ROLE_LOTO_P, r_role_loto,RoleLotoInfo),
	?READ_ROLE_DEF_RECORD( ?DB_ROLE_TILI_P, r_role_tili,RoleTili),
	?READ_ROLE_DEF_RECORD( ?DB_ITEM_USE_LIMIT_P, r_item_use_limit,ItemUseLimit),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_ACCESS_GUIDE_P, r_access_guide,RoleAccessGuideInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_DAILY_MISSION_P, r_role_daily_mission,RoleDailyMissionInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_GUARD_FB_P, r_role_guard_fb,RoleGuardFbInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_JINGLIAN_P, r_jinglian, JinglianInfo),
	?READ_ROLE_DEF_RECORD( ?DB_ROLE_SWL_MISSION_P, r_role_swl_mission, RoleSwlMissionInfo),
    ?READ_ROLE_DEF_RECORD( ?DB_ROLE_TOWER_P, r_role_tower_fb, RoleTowerFbInfo),

    case db:dirty_read(?DB_ROLE_MONSTER_DROP_P, RoleID) of
        [] ->
            RoleMonsterDrop = undefined;
        [#r_role_monster_drop{kill_times=[]}] ->
            db:dirty_delete(?DB_ROLE_MONSTER_DROP_P, RoleID),
            RoleMonsterDrop = undefined;
        [RoleMonsterDrop] ->
            ok
	end,
	RoleMapExtInfo = #r_role_map_ext{buy_back_goods=[],training_pets=PetTrainingInfo,role_grow=RoleGrowInfo,
									 role_guide=RoleGuideInfo,energy_drug_usage=RoleEnergyUsageInfo, 
									 lianqi=RoleLianqiInfo, caishen=RoleCaishenInfo, guide=Guide,
									 role_present=RolePresentInfo,role_examine_fb=RoleExamineFbInfo,shenqi=RoleShenqiInfo,
									 bag_shop=RoleBagShopInfo,swl_mission=RoleSwlMissionInfo,
									 vip=RoleVipInfo,role_mine_fb=RoleMineFbInfo,daily_pay_reward=RoleDailyPayReward,
									 role_tili=RoleTili,item_use_limit=ItemUseLimit,
									 access_guide=RoleAccessGuideInfo,daily_mission=RoleDailyMissionInfo,role_loto=RoleLotoInfo,
									 role_guard_fb=RoleGuardFbInfo,jinglian=JinglianInfo,role_tower_fb_info=RoleTowerFbInfo},
	
    case db:dirty_read(?DB_ROLE_SKILL_P, RoleID) of
        [] ->
            RoleSkillList = [];
        [#r_role_skill{skill_list = RoleSkillList}] ->
            ok
    end,
    case db:dirty_read(?DB_MISSION_DATA_P, RoleID) of
        [] ->
            RoleMissionData = #mission_data{last_store_time=common_tool:now()};
        [MissionDBData] ->
            RoleMissionData = (MissionDBData#r_db_mission_data.mission_data)#mission_data{last_store_time=common_tool:now()}
    end,
    
    #p_role{base=#p_role_base{family_id=FamilyID}} = RoleDetail,
    case FamilyID > 0 of
        true ->
            case db:dirty_read(?DB_FAMILY, FamilyID) of
                [FamilyInfo] -> next;
                _ -> FamilyInfo = undefined
            end;
        false ->
            FamilyInfo = undefined
    end,

	RoleMisc = case db:dirty_read(?DB_ROLE_MISC_P, RoleID) of
        [] ->
            #r_role_misc{role_id=RoleID, tuples=[]};
        [RoleMisc2] ->
			RoleMisc2
    end,
	
	PetProcessInfo = get_role_pet_process_info(RoleID),
	#r_account_full_info{role_id=RoleID, role_detail=RoleDetail, pet_process_info=PetProcessInfo,
						 accumulate_info=RoleAccumulateInfo,
						 skill_list=RoleSkillList,  hero_fb_info=RoleHeroFbInfo,
						 role_monster_drop=RoleMonsterDrop, refining_box_info=RoleBoxInfo,
						 mission_data=RoleMissionData, 
                         % achievement_info=RoleAchievementInfo,
						 goal_info=RoleGoalInfo,shortcut_bar=RoleShortcut,
						 map_ext_info=RoleMapExtInfo,
						 family_info=FamilyInfo, role_misc=RoleMisc
						}.

%% 玩家信息
do_get_role_detail(RoleID) ->
    [RoleBase] = db:dirty_read(?DB_ROLE_BASE, RoleID),
    [RoleAttr] = db:dirty_read(?DB_ROLE_ATTR, RoleID),
	RoleAttr2  = case common_config:get_agent_name() of
		Agent when Agent == "pengyou";
				   Agent == "qq" ->
            case cfg_cheat:is_cheater(RoleBase#p_role_base.account_name) of
                true ->
                    RoleAttr;
                false ->
			         RoleAttr#p_role_attr{gold = mod_qq_api:get_balance(RoleID)}
            end;
		_ ->
			RoleAttr
	end,
    [RolePos] = db:dirty_read(?DB_ROLE_POS, RoleID),
    [RoleFight] = db:dirty_read(?DB_ROLE_FIGHT, RoleID),
    [RoleExt] = db:dirty_read(?DB_ROLE_EXT, RoleID),
    RoleDetail = #p_role{base=RoleBase, fight=RoleFight, pos=RolePos, attr=RoleAttr2, ext=RoleExt},
    {ok,RoleDetail}.

%% 宠物信息
get_role_pet_process_info(RoleID) ->
    PetGrowInfo           = get_role_pet_grow_info(RoleID),
    {PetBagInfo,PetsInfo} = get_pet_bag_and_pets_info(RoleID),
    ?READ_ROLE_DEF_RECORD(?DB_PET_TASK, r_pet_task, PetTaskRec),
	#r_pet_process_info{
        pet_bag   = PetBagInfo,
        pet_grow  = PetGrowInfo,
        pet_info  = PetsInfo,
        pet_task  = PetTaskRec}.

get_pet_bag_and_pets_info(RoleID) ->
    case db:dirty_read(?DB_ROLE_PET_BAG_P,RoleID) of
        [] ->
            BagInfo = #p_role_pet_bag{content=?DEFAULT_PET_BAG_CONTENT,role_id=RoleID,pets=[],hidden_pets=[],show_list=[]};
        [BagInfo] ->
            ignore
    end,
    Pets = BagInfo#p_role_pet_bag.pets,
    PetsInfo = get_pets_info(Pets,[]),
    {BagInfo,PetsInfo}.

get_pets_info([],PetsInfo) ->
    PetsInfo;
get_pets_info([#p_pet_id_name{pet_id=PetID}|Pets],PetsInfo) ->
    case db:dirty_read(?DB_PET_P, PetID) of
        [] ->
            get_pets_info(Pets,PetsInfo);
        [PetInfo] ->
            get_pets_info(Pets,[PetInfo|PetsInfo])
    end.

get_role_pet_grow_info(RoleID) ->
    case db:dirty_read(?DB_ROLE_PET_GROW,RoleID) of 
        [] ->
            GrowInfo=#p_role_pet_grow{role_id=RoleID},
            db:dirty_write(?DB_ROLE_PET_GROW,GrowInfo),
            {GrowInfo,undefined};
        [GrowInfo] ->
            case GrowInfo#p_role_pet_grow.state =:= 4 of
                true ->
                    OverTick = GrowInfo#p_role_pet_grow.grow_over_tick,
                    {GrowInfo,OverTick};
                false ->
                    {GrowInfo,undefined}
            end
    end.

%%@doc 持久化玩家数据
persistent_account_info(AccountFullInfo)->
    #r_account_full_info{
        role_id           = RoleID, 
        role_detail       = #p_role{
            attr  = RoleAttr, 
            base  = RoleBase, 
            fight = RoleFight, 
            pos   = RolePos
        }, 
        bag               = RoleBagInfoList,
        accumulate_info   = RoleAccumulateInfo,
        skill_list        = RoleSkillList,  
        hero_fb_info      = RoleHeroFbInfo,
        role_monster_drop = RoleMonsterDrop, 
        refining_box_info = RoleBoxInfo,
        mission_data      = RoleMissionData,
        goal_info         = RoleGoalInfo,
        shortcut_bar      = RoleShortcut,
        % achievement_info  = RoleAchievementInfo,
        map_ext_info      = RoleMapExtInfo, 
        role_misc         = RoleMisc
    } = AccountFullInfo,
    
    db:dirty_write(?DB_ROLE_ATTR,  RoleAttr),
    db:dirty_write(?DB_ROLE_BASE,  RoleBase),
    db:dirty_write(?DB_ROLE_FIGHT, RoleFight),
    db:dirty_write(?DB_ROLE_POS,   RolePos),
    
    case db:transaction(fun()-> 
        common_bag2:t_persistent_role_bag_info(RoleBagInfoList) 
    end) of
        {atomic, _} ->
            ok;
        {aborted, _Error} ->
            error
    end,
    
    if
        RoleMissionData == undefined -> ignore;
        true ->
            db:dirty_write(?DB_MISSION_DATA_P, #r_db_mission_data{role_id=RoleID, mission_data=RoleMissionData})
    end,
    db:dirty_write(?DB_ROLE_SKILL_P, #r_role_skill{role_id=RoleID, skill_list=RoleSkillList}),
    
    ?WRITE_ROLE_RECORD(?DB_ROLE_ACCUMULATE_P  , RoleAccumulateInfo),
    ?WRITE_ROLE_RECORD(?DB_ROLE_HERO_FB_P     , RoleHeroFbInfo),
    ?WRITE_ROLE_RECORD(?DB_ROLE_MONSTER_DROP_P, RoleMonsterDrop),
    ?WRITE_ROLE_RECORD(?DB_ROLE_BOX_P         , RoleBoxInfo),
    ?WRITE_ROLE_RECORD(?DB_ROLE_GOAL_P        , RoleGoalInfo),
    ?WRITE_ROLE_RECORD(?DB_SHORTCUT_BAR_P     , RoleShortcut),
    ?WRITE_ROLE_RECORD(?DB_ROLE_MISC_P        , RoleMisc),
	
    case RoleMapExtInfo of
        undefined->
            ignore;
		#r_role_map_ext{
            training_pets       = TrainingPets,
            role_grow           = RoleGrowInfo,
            role_guide          = RoleGuideInfo, 
            energy_drug_usage   = RoleEnergyUsageInfo,
            lianqi              = RoleLianqiInfo, 
            caishen             = RoleCaishenInfo,
            role_present        = RolePresentInfo,
            role_examine_fb     = RoleExamineFbInfo,
            shenqi              = RoleShenqiInfo,
            bag_shop            = RoleBagShopInfo,
            swl_mission         = RoleSwlMissionInfo,
            vip                 = RoleVipInfo,
            role_mine_fb        = RoleMineFbInfo,
            daily_pay_reward    = RoleDailyPayReward,
            role_tili           = RoleTili,
            item_use_limit      = ItemUseLimit,
            guide               = Guide,
            role_loto           = RoleLotoInfo,
            access_guide        = RoleAccessGuideInfo,
            daily_mission       = RoleDailyMissionInfo,
            role_guard_fb       = RoleGuardFbInfo,
            jinglian            = JinglianInfo,
            role_tower_fb_info  = RoleTowerFbInfo
        } ->
            ?WRITE_ROLE_DEF_RECORD(?DB_GUIDE_P                 , r_guide                 , Guide ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_LOTO_P             , r_role_loto             , RoleLotoInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_PET_TRAINING_P          , r_pet_training          , TrainingPets ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_GROW_P             , r_role_grow             , RoleGrowInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_GUIDE_TIP_P        , r_role_guide_tip        , RoleGuideInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_ENERGY_DRUG_USAGE_P, r_role_energy_drug_usage, RoleEnergyUsageInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_LIANQI_P           , r_role_lianqi           , RoleLianqiInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_CAISHEN_P          , r_role_caishen          , RoleCaishenInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_PRESENT_P          , r_role_present          , RolePresentInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_EXAMINE_FB_P       , r_role_examine_fb       , RoleExamineFbInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_SHENQI_P           , r_role_shenqi           , RoleShenqiInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_BAG_SHOP_P         , r_role_bag_shop         , RoleBagShopInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_VIP_P              , r_role_vip              , RoleVipInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_MINE_FB_P          , r_role_mine_fb          , RoleMineFbInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_DAILY_PAY_REWARD_P , r_role_daily_pay_reward , RoleDailyPayReward ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_TILI_P             , r_role_tili             , RoleTili ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ITEM_USE_LIMIT_P        , r_item_use_limit        , ItemUseLimit ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_ACCESS_GUIDE_P     , r_access_guide          , RoleAccessGuideInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_DAILY_MISSION_P    , r_role_daily_mission    , RoleDailyMissionInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_GUARD_FB_P         , r_role_guard_fb         , RoleGuardFbInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_JINGLIAN_P              , r_jinglian              , JinglianInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_SWL_MISSION_P      , r_role_swl_mission      , RoleSwlMissionInfo ),
            ?WRITE_ROLE_DEF_RECORD(?DB_ROLE_TOWER_P            , r_role_tower_fb         , RoleTowerFbInfo)
    end,
    ok.    



