%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2011, 
%%% @doc
%%%
%%% @end
%%% Created : 28 Apr 2011 by  <>
%%%-------------------------------------------------------------------
-module(mod_hero_fb).

-include("mission.hrl").
-export([
         handle/1,
         handle/2
        ]).

-export([
         init_role_hero_fb_info/3,
         set_role_hero_fb_info/3,
         get_role_hero_fb_info/2,
         get_role_all_hero_fb_info/1,
         erase_role_hero_fb_info/1,
         get_hero_fb_map_name/2,
         get_hero_fb_quit_pos/1,
         is_in_hero_fb/1,
         get_drop_goods_name/1,
         get_role_name_color/2
        ]).

-export([
         is_hero_fb_map_id/1,
         assert_valid_map_id/1,
         get_map_name_to_enter/1,
         clear_map_enter_tag/1]).
-export([
         gm_reset_barrier_fight_times/2,
         gm_set_progress/3
         ]).

-export([
         hook_role_quit/1,
         hook_role_enter/2,
         hook_monster_dead/2,
         hook_monster_drop/3,
         hook_role_dead/1,
         cross_jingjie_mission/3,
         build_default_progress/2
        ]).

%% 英雄副本地图信息
-record(r_hero_fb_map_info, {
        barrier_id, 
        model_type = 0,
        map_role_id, 
        total_monster, 
        remain_monster, 
        enter_time, 
        end_time, 
        first_enter}).
%% 每关的基础奖励
% -record(r_barrier_basic_reward,{min_barrier,max_barrier,reward_list}).
%% 翻牌价格配置
% -record(r_barrier_select_money,{min_barrier,max_barrier,can_select,money_list}).

-define(hero_fb_map_info, hero_fb_map_info).
%% 最低排名
-define(max_order, 30).
%% 英雄副本死亡退出
-define(hero_fb_quit_type_relive, 1).
-define(hero_fb_quit_type_normal, 0).
%% 副本完成
-define(fb_quit_status_finish, 0).
%% 副本失败
-define(fb_quit_status_fail, 1).

-define(hero_fb_fail,0).
-define(hero_fb_succ,1).
-define(hero_fb_break,2).

-define(CONFIG_NAME,hero_fb).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

%%宝箱的物品状态定义
-define(BOX_PROP_STATUS_NORMAL,1).    %%正常
-define(BOX_PROP_STATUS_FETCHED,2).   %%已领取

%%宝箱的相关宏定义
-define(HERO_FB_BOX_CUR_REWARD_LIST,hero_fb_box_cur_reward_list).
-define(HERO_FB_ROLE_RECORD_RESULT,hero_fb_role_record_result).
-define(HERO_FB_DROP_BOX_DATA,hero_fb_drop_box_data).
-define(HERO_FB_FINISH_STATE,hero_fb_finish_state).
-define(BOX_SPEC_RATE_TYPE,999).    %%特殊类别的ID
-define(BOX_SPEC_NUM_LIMIT,1).      %%特殊类的个数限制

%%错误码
-define(ERR_HEROFB_BOX_ROLE_ILLEGALITY,1001). %%玩家非法操作
-define(ERR_HEROFB_BOX_NOT_IN_MAP,1002). %%不在个人副本的地图中
-define(ERR_HEROFB_BOX_NO_REWARDS,1003). %%宝箱中没有物品
-define(ERR_HEROFB_BOX_BAG_FULL,1004).  %%玩家的背包已满
-define(ERR_HEROFB_BOX_SILVER_ANY_NOT_ENOUGH,1005). %%没有足够的钱币
-define(ERR_HEROFB_BOX_GOLD_ANY_NOT_ENOUGH,1006). %%没有足够的元宝
-define(ERR_HEROFB_BOX_BAG_NOT_ENGUGHT,1008).  %%玩家的背包不够


-define(ERR_HEROFB_ENTER_TIMES_LIMITED,1100).  %%今天的挑战次数已到最大限制
-define(ERR_HEROFB_ENTER_MIN_LV_LIMITED,1101).  %%必须领取【九等初出茅庐境界】任务后才能开启境界副本（9级可接）
-define(ERR_HEROFB_NOT_IN_SELF_COUNTRY,1102).  %%在外国地图不允许进入副本
-define(ERR_HEROFB_ILLEGAL_ENTER_MAP,1103).  %%当前所在地图不允许进入副本
-define(ERR_HEROFB_ENTER_BARRIER_LOCK,1104).  %%该副本还没开通，不能进行挑战
-define(ERR_HEROFB_ENTER_ROLE_DEAD,1105).  %%死亡状态下不能进入副本
-define(ERR_HEROFB_ENTER_ROLE_STALL,1106).  %%摆摊状态下不能进入副本
-define(ERR_HEROFB_ENTER_ROLE_TRAINING,1107).  %%离线训练状态下不能进入副本
-define(ERR_HEROFB_ENTER_ROLE_FIGHT,1108).  %%战斗状态下不能进入副本
-define(ERR_HEROFB_ENTER_ONE_BARRIER_LIMITED,1109).  %%本关的挑战次数已到上限（5次），每天零点会刷新次数。
-define(ERR_HEROFB_BUY_TIMES_GOLD_ANY_NOT_ENOUGH,1110).  %%您的元宝不足，无法购买挑战次数！
-define(ERR_HEROFB_BUY_TIMES_MAX_LIMIT,1111).  %%今天的购买次数已达限制.
-define(ERR_HEROFB_ENTER_ROLE_HORSE_RACING,1112).  %%在钦点美人中不能进入副本
-define(ERR_HEROFB_ENTER_NO_ENOUGH_TILI,1113).  %%体力值不够，不能进入副本

-define(ERR_HEROFB_REWARD_NO_NORMAL_PROP,1201).  %%宝箱中没有可以奖励物品.
-define(ERR_HEROFB_SELECT_GOLD_NOT_ENOUGH,1206). %%无法翻牌，没有足够的元宝
-define(ERR_HEROFB_REWARD_CANNOT_SELECT,1207).     %%本关不能进行再翻牌.
-define(ERR_HEROFB_REWARD_INVALID_SELECT_TIMES,1208).  %%您已达到最大的翻牌次数.
-define(ERR_HEROFB_SWEEP_BARRIER_NOT_FINISH,1210).  %%该关卡尚未通关，无法进行扫荡


-define(MIN_BARRIER_ONE_STAR,105). %%前五关都是九等
-define(JINGJIE_INTERVAL_ONE_STAR,20). %%相差20个境界只给九等

%% 副本的模式，目前有普通和惊讶模式
-define(ALL_MODEL_TYPES, [0, 1]).

%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).

handle({Unique, Module, ?HERO_FB_PANEL, DataIn, RoleID, PID, _Line, _MapState}) ->
    do_panel(Unique, Module, ?HERO_FB_PANEL, DataIn, RoleID, PID);
handle({Unique, Module, ?HERO_FB_ENTER, DataIn, RoleID, PID, _Line, _MapState}) ->
    do_enter(Unique, Module, ?HERO_FB_ENTER, DataIn, RoleID, PID);
handle({Unique, Module, ?HERO_FB_QUIT, DataIn, RoleID, _PID, _Line, _MapState}) ->
    do_quit(Unique, Module, ?HERO_FB_QUIT, DataIn, RoleID);
% handle({Unique, Module, ?HERO_FB_REWARD, DataIn, RoleID, PID, _Line, _MapState}) ->
%     do_reward(Unique, Module, ?HERO_FB_REWARD, DataIn, RoleID, PID);
handle({Unique, Module, ?HERO_FB_SELECT_REWARD, DataIn, RoleID, PID, _Line, _MapState}) ->
    do_select_reward(Unique, Module, ?HERO_FB_SELECT_REWARD, DataIn, RoleID, PID);
handle({Unique, Module, ?HERO_FB_SWEEP, DataIn, RoleID, PID, _Line, _MapState}) ->
    do_sweep(Unique, Module, ?HERO_FB_SWEEP, DataIn, RoleID, PID);
handle({Unique, Module, ?HERO_FB_ONE_KEY_SWEEP, DataIn, RoleID, PID, _Line, _MapState}) ->
    do_one_key_sweep(Unique, Module, ?HERO_FB_ONE_KEY_SWEEP, DataIn, RoleID, PID);

handle({init_hero_fb_map_info, MapInfo}) ->
    init_npc_talks(MapInfo),
    set_hero_fb_map_info(MapInfo);
handle({RoleID, offline_terminate}) ->
    do_offline_terminate(RoleID);
handle({create_map_succ,RoleID}) ->
    do_async_create_map(RoleID);
handle({RoleID, fb_timeout_kick}) ->
    do_fb_timeout_kick(RoleID);
handle({hero_fb_ranking,Info})->
    do_hero_fb_ranking(Info);
handle({do_barrier_talk,RoleID,NpcId,TalkId})->
    do_barrier_talk(RoleID,NpcId,TalkId);
handle({safe_kill, RoleID})->
    do_safe_kill(RoleID);

handle(Info) ->
    ?ERROR_MSG("mod_hero_fb, unrecognize msg: ~w", [Info]).

%% @doc 物品掉落hook
hook_monster_drop(_MonsterTypeID, _MonsterName, _DropThingList) ->
    ignore.

cross_jingjie_mission(RoleID, BarrierID, ModelType) ->
    {ok,#p_role_hero_fb_info{progress = Progress}} = get_role_hero_fb_info(RoleID, ModelType),
    Progress > BarrierID.


%%将辅助怪物都一一杀掉
clear_assist_monster(BarrierID)->
    case cfg_hero_fb:assist_monster(BarrierID) of
        [] -> ignore;
        AssistMonsterTypeList->
            MonsterIdList = mod_map_monster:get_monster_id_list(),
            lists:foreach(
              fun(E)->
                      clear_assist_monster_2(E,AssistMonsterTypeList)
              end, MonsterIdList),
            ok
    end.
clear_assist_monster_2(E,AssistMonsterTypeList)->
    case mod_map_monster:get_monster_state(E) of
        #monster_state{monster_info=MonsterInfo} ->
            case MonsterInfo of
                #p_monster{typeid=Type}->
                    case lists:member(Type, AssistMonsterTypeList) of
                        true->
                            ?TRY_CATCH( mod_map_monster:monster_delete(E) );
                        _ ->
                            ignore
                    end;
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.

%% @doc 怪物死亡
hook_monster_dead(RoleID, MonsterBaseInfo) ->
    case get_hero_fb_map_info(RoleID) of
        {ok, MapInfo} ->
            case get(?HERO_FB_FINISH_STATE) of
				true->
					ignore;
				_ ->
					hook_monster_dead_2(MonsterBaseInfo,MapInfo)
			end;	
        {error, _} ->
            ignore
    end.

hook_monster_dead_2(MonsterBaseInfo,MapInfo)->
	#r_hero_fb_map_info{map_role_id=RoleID, enter_time=EnterTime, total_monster=TotalMonster, barrier_id=BarrierID} = MapInfo,
	TimeUsed = get_hero_fb_time_used(EnterTime),
	
	#p_monster_base_info{rarity=MonsterRarity} = MonsterBaseInfo,
	case MonsterRarity of
		?BOSS -> clear_assist_monster(BarrierID);
		_     -> ignore
	end,
	
	%% 清完所有怪，计时
	RemainMonsterNum = erlang:length(mod_map_monster:get_monster_id_list()) - 1,
	case RemainMonsterNum =< 0 of
		true ->
			hook_hero_fb:finish_fb(RoleID, BarrierID),
			mod_random_mission:handle_event(RoleID,?RAMDOM_MISSION_EVENT_2),
			hook_all_monster_dead(MapInfo, TimeUsed);
		_ ->
			ignore
	end,
	DataRecord = #m_hero_fb_state_toc{
        total_monsters  = TotalMonster,
        remain_monsters = RemainMonsterNum,
        start_time      = MapInfo#r_hero_fb_map_info.enter_time,
        end_time        = MapInfo#r_hero_fb_map_info.enter_time + get_fb_lasting_time(),
        time_used       = TimeUsed
    },
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HERO_FB, ?HERO_FB_STATE, DataRecord),
	ok.

set_drop_fb_box(RoleID,DropBoxItemId)->
    put(?HERO_FB_DROP_BOX_DATA,{RoleID,DropBoxItemId}),
    ok.

%% @doc 副本的所有怪都挂了
hook_all_monster_dead(MapInfo, TimeUsed) ->
    #r_hero_fb_map_info{map_role_id=RoleID, barrier_id=BarrierID, model_type=ModelType} = MapInfo,
    %% 扣除体力
    mod_tili:reduce_role_tili(RoleID, need_cost_tili(),true),

    %%掉落宝箱
    DropBoxItemId = cfg_hero_fb:get_misc(drop_box_item_id),
    set_drop_fb_box(RoleID,DropBoxItemId),
    %% 增加本关攻击次数
    {ok,_NewTimes,RoleHeroFBInfo, IsFirstTime} = do_add_barrier_fight_times(RoleID,BarrierID,ModelType),

    {ok,RoleAttr= #p_role_attr{jingjie = RoleJingjie, juewei = RoleJuewei}} = mod_map_role:get_role_attr(RoleID),
    
    %%基础分
    {BaseScore,_,_} = cfg_hero_fb:get_misc(fb_star_level),
    {ok,FbScore,StarLevel} = get_barrier_score(RoleID,RoleAttr,BaseScore,BarrierID,ModelType,TimeUsed),
    

    #p_role_hero_fb_info{progress=Progress, rewards=Rewards, fb_record=FBRecordList} = RoleHeroFBInfo,
    %% 一定会有记录 没有就是错的
    Record = lists:keyfind(BarrierID, #p_hero_fb_barrier.barrier_id, FBRecordList),
    case FbScore >= Record#p_hero_fb_barrier.score of
        true->            
            FbRecordList2 = 
            [Record#p_hero_fb_barrier{time_used=TimeUsed,
                                     star_level = StarLevel,
                                     score = FbScore}|lists:delete(Record, FBRecordList)];
        false->
            FbRecordList2 = FBRecordList
    end,
    
    %% 这里是不是首次完成  是首次完成加称号奖励 否则仅奖励
    {ok, Progress2} = get_new_progress(BarrierID, ModelType, Progress),
    %% 奖励
    Rewards2 = get_chapter_reward(Rewards, Progress, Progress2),
    RoleHeroFBInfo2 = RoleHeroFBInfo#p_role_hero_fb_info{
        progress  = Progress2, 
        rewards   = Rewards2, 
        fb_record = FbRecordList2
    },
    set_role_hero_fb_info(RoleID, RoleHeroFBInfo2, true),
    hook_all_monster_dead_2(RoleID,MapInfo,TimeUsed, FbScore,StarLevel,RoleJingjie, RoleJuewei, IsFirstTime).

hook_all_monster_dead_2(RoleID,MapInfo,TimeUsed, FbScore,StarLevel,RoleJingjie, RoleJuewei, IsFirstTime)->
    #r_hero_fb_map_info{barrier_id=BarrierID} = MapInfo,
    
    %%大明英雄福本的活动奖励
    ?TRY_CATCH( hook_activity_map:hook_hero_fb(RoleID) ),
    
    %% 完成境界任务
    mgeer_role:run(RoleID, fun() -> 
        hook_mission_event:hook_jingjie(RoleID, BarrierID),
        hook_mission_event:hook_special_event(RoleID,?MISSION_EVENT_JINGJIE_ENTER)
    end),
    %% 完成成就
    mod_achievement2:achievement_update_event(RoleID, 41006, {1, BarrierID}),

    hook_all_monster_dead_3(RoleID,MapInfo,TimeUsed, FbScore,StarLevel,RoleJingjie, RoleJuewei, IsFirstTime).


%% @doc 怪清完了
hook_all_monster_dead_3(RoleID,MapInfo,TimeUsed, FbScore,StarLevel,RoleJingjie, RoleJuewei, IsFirstTime)->
    #r_hero_fb_map_info{barrier_id=BarrierID, model_type = ModelType} = MapInfo,
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            ignore;
        #p_map_role{role_id=RoleID, role_name=RoleName, faction_id=FactionID}->
            BarrierInfoRec = cfg_hero_fb:barrier_info(ModelType, BarrierID),

            RoleFbRecord = #p_hero_fb_record{role_id=RoleID, 
                                           role_name=RoleName,
                                           faction_id=FactionID,
                                           time_used=TimeUsed,
                                           score = FbScore,
                                           star_level = StarLevel},
            put(?HERO_FB_ROLE_RECORD_RESULT,RoleFbRecord),
            put(?HERO_FB_FINISH_STATE,true),    %%标记副本已经结束
            

            mod_qrhl:send_event(RoleID, jingjie, BarrierID),
            {ok,RewardPropList} = reload_box_prop_list(RoleID,BarrierID,ModelType,StarLevel),
            FBJingjie = BarrierInfoRec#r_hero_fb_barrier_info.jingjie,
            RoleName1 = erlang:binary_to_list(RoleName), 
            case ModelType of
                0 ->
                    NextJingjie  = cfg_jingjie:next_jingjie(RoleJingjie),
                    Upgrade = case NextJingjie =:= FBJingjie of
                        true ->
                            mgeer_role:send(RoleID,{mod_role_jingjie, {auto_upgrade_jingjie,RoleID}}),
                            Msg1 = common_misc:format_lang(<<"【~ts】~ts！">>, [RoleName1, BarrierInfoRec#r_hero_fb_barrier_info.barrier_name]),
                            common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER], 
                                               ?BC_MSG_TYPE_CHAT_WORLD, 
                                               Msg1),
                            Msg2 = common_misc:format_lang(<<"~ts！<font color='#00FF00'><u><a href='event:open|OPEN_HERO_FB_PANEL|0'>我要获得</a></u></font>">>, [Msg1]),
                            common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CHAT], 
                                               ?BC_MSG_TYPE_CHAT_WORLD, 
                                               Msg2),
                            NextJingjie;
                        _ -> 0
                    end;
                1 ->
                    case RoleJuewei == cfg_juewei:max_juewei() of
                        true -> Upgrade = 0;
                        false ->
                            NextJuewei = cfg_juewei:next_juewei(RoleJuewei),
                            Upgrade = case NextJuewei == FBJingjie of
                                true ->
                                    mgeer_role:send(RoleID,{mod_role_juewei, {auto_upgrade_juewei,RoleID}}),
                                    Msg1 = common_misc:format_lang(<<"【~ts】~ts！">>, [RoleName1, BarrierInfoRec#r_hero_fb_barrier_info.barrier_name]),
                                    common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER], 
                                                       ?BC_MSG_TYPE_CHAT_WORLD, 
                                                       Msg1),
                                    Msg2 = common_misc:format_lang(<<"~ts！<font color='#00FF00'><u><a href='event:open|OPEN_HERO_FB_PANEL|1'>我要获得</a></u></font>">>, [Msg1]),
                                    common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CHAT], 
                                                       ?BC_MSG_TYPE_CHAT_WORLD, 
                                                       Msg2),
                                    NextJuewei;
                                false -> 0
                            end
                    end
            end,
            R2C = #m_hero_fb_report_toc{
                model_type     = ModelType,
                barrier_id     = BarrierID,
                fb_record      = RoleFbRecord,
                state          = ?hero_fb_succ,
                prop_list      = [Box#p_hero_fb_box_prop.prop || Box <- RewardPropList],
                remain_times   = StarLevel - 2,
                can_gold_fetch = BarrierInfoRec#r_hero_fb_barrier_info.can_gold_fetch,
                exp            = BarrierInfoRec#r_hero_fb_barrier_info.reward_exp,
                prestige       = BarrierInfoRec#r_hero_fb_barrier_info.reward_prestige,
                silver         = BarrierInfoRec#r_hero_fb_barrier_info.reward_silver,
                items          = [Id || {Id, _, _, _} <- BarrierInfoRec#r_hero_fb_barrier_info.reward_items],
                jingjie        = Upgrade },
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HERO_FB, ?HERO_FB_REPORT, R2C),
            case IsFirstTime of
              true  -> FirstRewardItems = BarrierInfoRec#r_hero_fb_barrier_info.first_battle_items;
              false -> FirstRewardItems = []
            end,
            Fun = fun() -> common_barrier:send_reward(RoleID,  
                                       R2C#m_hero_fb_report_toc.exp, 
                                       R2C#m_hero_fb_report_toc.prestige, 
                                       R2C#m_hero_fb_report_toc.silver, 
                                       FirstRewardItems ++ BarrierInfoRec#r_hero_fb_barrier_info.reward_items) end,
            mgeer_role:run(RoleID, Fun)
    end.

%%@return {ok,Score,Star}
get_barrier_score(_,_,BaseScore,BarrierID,_ModelType,_) when BarrierID=<?MIN_BARRIER_ONE_STAR->
    {ok,BaseScore,3};
get_barrier_score(RoleID,RoleAttr,_BaseScore,BarrierID,ModelType,TimeUsed)->
    get_barrier_score_2(RoleID,RoleAttr,BarrierID,ModelType,TimeUsed).

get_barrier_score_2(RoleID,RoleAttr,BarrierID,ModelType,TimeUsed)->
    %%公式：装备分+战力分+时间分
    #p_role_attr{equips=Equips}=RoleAttr,

    BarrierInfoRec = cfg_hero_fb:barrier_info(ModelType, BarrierID),
    
    EquipColorScore = get_fb_equip_color_score(Equips),
    FightPowerScore = get_fb_fightpower_score(RoleID,BarrierInfoRec,RoleAttr),
    TimeScore = get_fb_time_score(BarrierInfoRec,TimeUsed),
    
    AllScore = erlang:trunc( EquipColorScore+FightPowerScore+TimeScore ),
    {_,SndStar,TrdStar} = cfg_hero_fb:get_misc(fb_star_level),
    if
        AllScore>=TrdStar->
            {ok,AllScore,3};
        AllScore>=SndStar->
            {ok,AllScore,2};
        true->
            {ok,AllScore,1}
    end.

-define(CHECK_FIX_SCORE(Score,FixScore),
        if
            Score>=FixScore-> FixScore;
            Score>0-> Score;
            true-> 1
        end).


%%装备品质分数
get_fb_equip_color_score(Equips)->
    Score = lists:foldl(
      fun(Goods,Acc)->
              case Goods#p_goods.type of 
                  ?TYPE_EQUIP->
                      [EquipBaseInfo] = common_config_dyn:find_equip(Goods#p_goods.typeid),
                      #p_equip_base_info{slot_num=SlotNum} = EquipBaseInfo,
                      #p_goods{current_colour=Colour} = Goods,
                      if
                          SlotNum=:=?PUT_MOUNT orelse SlotNum=:=?PUT_FASHION orelse SlotNum=:=?PUT_ADORN
                              orelse SlotNum=:=?PUT_JINGJIE orelse SlotNum=:=?PUT_SHENQI orelse SlotNum=:=?PUT_LEITAI ->
                              Acc;
                          true->
                              if
                                  Colour<1-> Acc;
                                  true-> 
                                      Acc+(Colour-1)*2 %%%%紫色:6,橙色:8
                              end
                      end;
                  _->Acc
              end     
      end, 0, Equips),
    ?CHECK_FIX_SCORE(Score,100).


%%战斗力
get_fb_fightpower_score(RoleID,BarrierInfoRec,RoleAttr)->
    {ok,RoleBase} = mod_map_role:get_role_base(RoleID),
    FightPower    = common_role:get_fighting_power(RoleBase, RoleAttr),
    Score         = 500*FightPower div BarrierInfoRec#r_hero_fb_barrier_info.expect_power,
    ?CHECK_FIX_SCORE(Score,500).
  

%%时间分数
get_fb_time_score(BarrierInfoRec,TimeUsed)->
    %% TimeUsed 是毫秒 
    TimeUsedSecs = TimeUsed div 1000,
    Score        = BarrierInfoRec#r_hero_fb_barrier_info.expect_time-TimeUsedSecs*16 div 10,
    ?CHECK_FIX_SCORE(Score,200).

%% @doc 排行榜
%% 分数从大到小 即排名从高到低
do_hero_fb_ranking({RoleID,BarrierID,RoleRecord})->
    case db:dirty_read(?DB_HERO_FB_RECORD, BarrierID) of
        [] ->
            RecordList = [];
        [FBRecord] ->
            #r_hero_fb_record{best_record=TmpRecordList} = FBRecord,
            RecordList = lists:reverse(TmpRecordList)
    end,
    %% {flag,order,smallerlist,biggerlist},
    %% flag:是否继续判断，order:排行
    {_,Order,NewRecordList,_,IsUpdate1} = 
        lists:foldl(
          fun(TmpRoleRecord,{Flag,TmpOrder,SmallerList,BiggerList,IsUpdate})->
                  case Flag of
                      false->
                          if RoleRecord#p_hero_fb_record.score=<TmpRoleRecord#p_hero_fb_record.score ->
                                 TmpIsUpdate = 
                                 case lists:keyfind(RoleID, #p_hero_fb_record.role_id, BiggerList) of
                                     false->
                                         true;
                                     _->
                                         false
                                 end,
                                 [H|RestList] = BiggerList,
                                 {true,TmpOrder,[H|SmallerList],RestList,TmpIsUpdate};
                             true->
                                 case TmpRoleRecord#p_hero_fb_record.role_id=:=RoleID of
                                     true->
                                         [_H|RestList] = BiggerList,
                                         {Flag,TmpOrder-1,SmallerList,RestList,IsUpdate};
                                     false->
                                         [H|RestList] = BiggerList,
                                         {Flag,TmpOrder-1,[H|SmallerList],RestList,IsUpdate}
                                 end
                          end;
                      true->
                          [H|RestList] = BiggerList,
                          {Flag,TmpOrder,[H|SmallerList],RestList,IsUpdate}
                  end
          end, {false,erlang:length(RecordList)+1,[],RecordList,true}, RecordList),
    case IsUpdate1=:=true andalso Order=<?max_order of
        true->
            RecordList1 = lists:sublist(
                            lists:sort(
                              fun(E1,E2)-> 
                                      E1#p_hero_fb_record.score>E2#p_hero_fb_record.score 
                              end, 
                              [RoleRecord|NewRecordList]), 
                            ?max_order),
            {RecordList2,_} = 
            lists:foldr(fun(TmpRoleRecord,{TmpRecordList,Rank})-> 
                            {[TmpRoleRecord#p_hero_fb_record{order=Rank}|TmpRecordList],Rank-1}
                        end,{[],erlang:length(RecordList1)}, RecordList1),
            db:dirty_write(?DB_HERO_FB_RECORD,#r_hero_fb_record{barrier_id=BarrierID,best_record = RecordList2}),
            RoleRecord1= RoleRecord#p_hero_fb_record{order=Order};
        false->
            RoleRecord1=RoleRecord
    end, 
    case Order =:=1 of
        true->
            IsBreak = ?hero_fb_break,
            FirstRecord = RoleRecord1,
            %% TODO:先保留关卡霸主的代码，默认只对普通模式关卡进行排序
            #r_hero_fb_barrier_info{barrier=Barrier} = cfg_hero_fb:barrier_info(?HERO_FB_MODE_TYPE_NORMAL, BarrierID),
            %% 广播
            Lang = common_tool:get_format_lang_resources(?_LANG_HERO_FB_BREAK_RECORD, 
                                                         [common_misc:get_faction_name(RoleRecord#p_hero_fb_record.faction_id),
                                                          RoleRecord#p_hero_fb_record.role_name,
                                                          Barrier]),
            common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER,?BC_MSG_TYPE_CHAT], 
                                               ?BC_MSG_TYPE_CHAT_WORLD, 
                                               Lang),
            %% 排行榜
            common_rank:update_element( ranking_hero_fb, {BarrierID, RoleRecord});
        false->
            IsBreak = ?hero_fb_succ,
            [FirstRecord|_]=NewRecordList
    end,
    
    %%发送排行结果（是否成为霸主）
    ReportToc = #m_hero_fb_update_record_toc{barrier_id=BarrierID,
                                             fb_record = RoleRecord1,first_record = FirstRecord,
                                             state = IsBreak},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HERO_FB, ?HERO_FB_UPDATE_RECORD, ReportToc).


do_barrier_talk(RoleID,NpcId,TalkId)->
    R2 = #m_fb_npc_talk_toc{npc_id=NpcId,talk_id=TalkId},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?FB_NPC, ?FB_NPC_TALK, R2),
    ok.


%% 玩家死亡处理
hook_role_dead(RoleID) ->
    case get_hero_fb_map_info(RoleID) of
        {ok, #r_hero_fb_map_info{barrier_id=BarrierID,map_role_id=RoleID}} ->
            R2C = #m_hero_fb_report_toc{barrier_id=BarrierID,state=?hero_fb_fail},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HERO_FB, ?HERO_FB_REPORT, R2C);
        _ ->
            ignore
    end.

%%重新刷新宝箱的道具奖励
%%宝箱的奖励物品=基础奖励+特殊奖励物品
%%@return {ok,prop_list}
reload_box_prop_list(RoleID,BarrierId,ModelType,StarLevel)->
    {ok,NewPropList,NewLotoWtList,CanFetchTimes} = get_reload_box_prop_list(RoleID,BarrierId,ModelType,StarLevel),
    mod_role_tab:put(RoleID, ?HERO_FB_BOX_CUR_REWARD_LIST,{NewPropList,NewLotoWtList,CanFetchTimes,1}),
    % ?ERROR_MSG("HERO_FB_BOX_CUR_REWARD_LIST: ~w", [erlang:get(?HERO_FB_BOX_CUR_REWARD_LIST)]),
    {ok,NewPropList}.
    
get_reload_box_prop_list(RoleID,BarrierId,ModelType,StarLevel)->  
    CanFetchTimes = StarLevel-2, %%例如3星为1次
    #r_hero_fb_barrier_info{barrier=Barrier} = cfg_hero_fb:barrier_info(ModelType, BarrierId),
    
    BoxBasicProps = get_box_basic_props(Barrier, ModelType),
    {ok,NewRewardGoodsList} = get_box_final_reward_list(RoleID,[],BoxBasicProps),
    
    {NewPropList,NewLotoWtList} = lists:foldl(
                                    fun(E,{BoxPropAcc,LotoWtAcc})->
                                            {PropIdx,LotoWeight,Prop} = E,
                                            NewBoxProp = #p_hero_fb_box_prop{prop_idx=PropIdx,prop=Prop,status=?BOX_PROP_STATUS_NORMAL},
                                            {[NewBoxProp|BoxPropAcc],
                                             [{PropIdx,LotoWeight}|LotoWtAcc]}
                                    end, {[],[]}, NewRewardGoodsList),
    {ok,NewPropList,NewLotoWtList,CanFetchTimes}.

get_box_cur_prop_list(RoleID)->
    case mod_role_tab:get(RoleID, ?HERO_FB_BOX_CUR_REWARD_LIST) of
        undefined->
            [];
        RewardPropList->
            RewardPropList
    end.
    
get_box_final_reward_list(_RoleID,AccIn,[])->
    {ok,AccIn};
get_box_final_reward_list(RoleID,AccIn,[H|T])->
	{RewardPropIdx,LotoWeight,IsBind,PropList} = H,
	WtList = lists:map(
			   fun(E)->
					   case E of
						   {_,Wt}-> Wt;
						   #r_reward_prop{weight=Wt}-> Wt
					   end 
			   end, PropList),
	case WtList of
		[] ->
			get_box_final_reward_list(RoleID,AccIn,T);
		_ ->
			WtIdx = common_tool:random_from_weights(WtList, true),
			case lists:nth(WtIdx, PropList) of
				{PropId,_}->
					RewardProp2 = #r_reward_prop{prop_id=PropId,num=1,bind=IsBind, color=0};
				RewardProp->
					PropNum = if RewardProp#r_reward_prop.num>0-> RewardProp#r_reward_prop.num; true-> 1 end,
					RewardProp2 = RewardProp#r_reward_prop{num=PropNum}
			end,
			case mod_gift:get_p_goods_by_reward_prop(RoleID,RewardProp2) of
				{ok,[RewardGoods|_T]} ->
					next;
				_ ->
					?ERROR_MSG("RewardProp=~w",[RewardProp2]),
					RewardGoods = null,
					?THROW_SYS_ERR()
			end,
			
			RewardGoods2 = RewardGoods#p_goods{id=1},
			Result = [{RewardPropIdx,LotoWeight,RewardGoods2}|AccIn],
			get_box_final_reward_list(RoleID,Result,T)
	end.

do_fb_timeout_kick(RoleID)->
    DataIn = #m_hero_fb_quit_tos{quit_type=1},
    erlang:erase(hero_fb_timeout_ref),
    erlang:put(hero_fb_timeout_flag, true),
    do_quit(?DEFAULT_UNIQUE, ?HERO_FB, ?HERO_FB_QUIT, DataIn, RoleID).

%% 设置超时退出timer
set_fb_timeout_timer(RoleID) ->
    case erlang:get(hero_fb_timeout_ref) of
        undefined ->ignore;
        Ref -> erlang:cancel_timer(Ref),erlang:erase(hero_fb_timeout_ref)
    end,
    %% 副本超时时间为10min
    TimerRef = erlang:send_after(get_fb_lasting_time(), self(), {?MODULE, {RoleID, fb_timeout_kick}}),
    erlang:put(hero_fb_timeout_ref, TimerRef).

get_fb_lasting_time() -> 600000.

%% @doc 角色进入地图
hook_role_enter(RoleID,_MapID) ->
    %% 首先删除玩家的变身符添加的buff
    case is_in_hero_fb(RoleID) of
        true ->
            [RemoveBuffTypeList] = common_config_dyn:find(item_change_skin, buff_type_list),
            mod_role_buff:del_buff_by_type(RoleID, RemoveBuffTypeList),
            

            case get_hero_fb_map_info(RoleID) of
                %% 第一次进入，进入后扣次数
                {ok, #r_hero_fb_map_info{barrier_id=BarrierID,model_type=ModelType,map_role_id=RoleID, first_enter=true}=MapInfo} ->
                    %% 因为玩家选择继续通关会导致上一个进程没有关闭，所以这里做一下关闭
                    CurBarrierInfoRec = cfg_hero_fb:barrier_info(ModelType, BarrierID),
                    LastBarrierId = CurBarrierInfoRec#r_hero_fb_barrier_info.last_barrier_id,
                    case LastBarrierId == 0 of
                        true -> ignore;
                        false ->
                            LastBarrierInfoRec = cfg_hero_fb:barrier_info(ModelType, LastBarrierId),
                            LastBarrierMapId = LastBarrierInfoRec#r_hero_fb_barrier_info.map_id,
                            case global:whereis_name(get_hero_fb_map_name(LastBarrierMapId, RoleID)) of
                                undefined -> ignore;
                                LastBarrierPID -> LastBarrierPID ! {?MODULE, {safe_kill, RoleID}}
                            end
                    end,
                    MonsterNum = erlang:length(mod_map_monster:get_monster_id_list()),
                    MapInfo2 = MapInfo#r_hero_fb_map_info{total_monster=MonsterNum, enter_time=common_tool:now(), first_enter=false},
                    set_hero_fb_map_info(MapInfo2),
                    %% 设置副本的超时定时器
                    set_fb_timeout_timer(RoleID),
                    % set_role_hero_fb_info(RoleID, HeroFBInfo1, true),
        			%% 删除结束标志
                    erase(?HERO_FB_FINISH_STATE),
        			erase(?HERO_FB_ROLE_RECORD_RESULT),
                    
                    %% 发送副本状态
                    DataRecord = #m_hero_fb_state_toc{
                      total_monsters  = MonsterNum,
                      remain_monsters = MonsterNum,
                      start_time      = MapInfo2#r_hero_fb_map_info.enter_time,
                      end_time        = MapInfo2#r_hero_fb_map_info.enter_time + get_fb_lasting_time(),
                      time_used       = 0},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HERO_FB, ?HERO_FB_STATE, DataRecord);
                %% 下线后再进入，不扣次数
                {ok, MapInfo} ->
        			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HERO_FB, ?HERO_FB_ENTER, #m_hero_fb_enter_toc{}),
                    #r_hero_fb_map_info{barrier_id=BarrierID, map_role_id=RoleID, total_monster=MonsterNum, enter_time=EnterTime}=MapInfo,
                    case get(?HERO_FB_ROLE_RECORD_RESULT) of
                        undefined->
                            ignore;
                        RoleFbRecord->
                            %%发送上一次的战报
                            BarrierInfoRec = cfg_hero_fb:barrier_info(BarrierID),
                            OldPropList    = get_box_cur_prop_list(RoleID), 
                            R2C = #m_hero_fb_report_toc{
                                barrier_id     = BarrierID,
                                fb_record      = RoleFbRecord,
                                state          = ?hero_fb_succ,
                                prop_list      = OldPropList, 
                                can_gold_fetch = BarrierInfoRec#r_hero_fb_barrier_info.can_gold_fetch,
                                exp            = BarrierInfoRec#r_hero_fb_barrier_info.reward_exp,
                                prestige       = BarrierInfoRec#r_hero_fb_barrier_info.reward_prestige,
                                silver         = BarrierInfoRec#r_hero_fb_barrier_info.reward_silver,
                                items          = [Id || {Id, _, _, _} <- BarrierInfoRec#r_hero_fb_barrier_info.reward_items]},
                            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HERO_FB, ?HERO_FB_REPORT, R2C),
                            Fun = fun() -> common_barrier:send_reward(RoleID,  
                                                       R2C#m_hero_fb_report_toc.exp, 
                                                       R2C#m_hero_fb_report_toc.prestige, 
                                                       R2C#m_hero_fb_report_toc.silver, 
                                                       BarrierInfoRec#r_hero_fb_barrier_info.reward_items) end,
                            mgeer_role:run(RoleID, Fun)
                    end,
                    
                    %% 发送副本状态
                    RemainMonster = erlang:length(mod_map_monster:get_monster_id_list()),
                    
                    DataRecord = #m_hero_fb_state_toc{
                      total_monsters  = MonsterNum,
                      remain_monsters = RemainMonster,
                      start_time      = MapInfo#r_hero_fb_map_info.enter_time,
                      end_time        = MapInfo#r_hero_fb_map_info.enter_time + get_fb_lasting_time(),
                      time_used       = get_hero_fb_time_used(EnterTime)},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HERO_FB, ?HERO_FB_STATE, DataRecord);
                _ ->    
                    ignore
            end;
        false ->
            case erlang:erase(hero_fb_timeout_flag) of
                true ->
                    #p_map_role{faction_id=FactionID} = mod_map_actor:get_actor_mapinfo(RoleID, role),
                    {MapID, TX, TY} = get_hero_fb_quit_pos(FactionID),
                    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, MapID, TX, TY);
                _ -> ignore
            end
    end.


%% @doc 角色退出地图hook
hook_role_quit(RoleID) ->
    case is_in_hero_fb(RoleID) of
        false ->
            ignore;
        true ->
            {ok, HeroFBMapInfo} = get_hero_fb_map_info(RoleID),
            mod_role_tab:erase(RoleID, ?hero_fb_map_info),
            hook_role_quit2(RoleID, HeroFBMapInfo)
    end.

hook_role_quit2(RoleID, HeroFBMapInfo) ->
    #map_state{mapid=MapID, map_name=MapName} = mgeem_map:get_state(),
    case mod_map_actor:is_change_map_quit(RoleID) of
        {true, MapID} ->
            %% 重新打这一章
            catch do_hero_fb_log(HeroFBMapInfo),
            %% 删除所有怪物
            mod_map_monster:delete_all_monster(),
            %% 重新出生怪物
            mod_map_monster:init_monster_id_list(),
            mod_map_monster:init_map_monster(MapName, MapID);
        _ ->
            hook_role_quit3(RoleID, HeroFBMapInfo)
    end.

hook_role_quit3(RoleID, HeroFBMapInfo) ->
    case mod_map_role:is_role_exit_game(RoleID) of
        true ->
            %%第几关之后，玩家退出地图则怪物自动满血
            RecoverHpWhenQuitMap = cfg_hero_fb:get_misc(recover_hp_when_quit_map),
            case HeroFBMapInfo of 
                #r_hero_fb_map_info{ barrier_id=BarrierID } when BarrierID>=RecoverHpWhenQuitMap ->
                    MonsterIdList = mod_map_monster:get_monster_id_list(),
                    ?TRY_CATCH( [ mod_map_monster:do_monster_recover_max(MonsterID)  ||MonsterID<-MonsterIdList ] );
                _ ->
                    next
            end,
            
            %% 玩家在副本中退出地图，地图进程会保持一段时间
            % ProtectTime = cfg_hero_fb:get_misc(offline_protect_time),
            ProtectTime = 9, %% 与玩家进程的保存时间一致，因为现在玩家是否在该副本的数据是作为临时数据记录在玩家的ets表中的
            erlang:send_after(ProtectTime*1000, self(), {mod_hero_fb, {RoleID, offline_terminate}});
        _ ->
            common_map:exit( hero_fb_role_quit ),
            catch do_hero_fb_log(HeroFBMapInfo)
    end.


get_map_name_to_enter(RoleID)->
    {DestMapID, _TX, _TY} = get({enter, RoleID}),
    get_hero_fb_map_name(DestMapID, RoleID).

clear_map_enter_tag(_RoleID)->
    ignore.



%% @doc 打开英雄副本界面
do_panel(Unique, Module, Method, DataIn, RoleID, PID) ->
    ModelType = DataIn#m_hero_fb_panel_tos.model_type,
    case get_role_hero_fb_info(RoleID, ModelType) of
        {ok, RoleHeroFBInfo} ->
            %%获取每关排名
            Info1 = get_role_server_order(RoleID,RoleHeroFBInfo),
            HeroFbInfo2 = refresh_fight_times(Info1),
            % FbChampions = get_fb_champions(HeroFbInfo2),
            DataRecord = #m_hero_fb_panel_toc{hero_fb=HeroFbInfo2};
        _ ->
            DataRecord = #m_hero_fb_panel_toc{succ=false, reason=?_LANG_HERO_FB_PANEL_SYSTEM_ERROR}
    end,
    ?UNICAST_TOC( DataRecord ).


%% @doc 进入副本
do_enter(Unique, Module, Method, DataIn, RoleID, PID) ->
    #m_hero_fb_enter_tos{barrier_id=BarrierID, model_type=ModelType} = DataIn,
    case catch check_can_enter_hero_fb(RoleID, BarrierID, ModelType, false) of
        {ok,BarrierInfo} ->
            {ok, RoleHeroFBInfo} = get_role_hero_fb_info(RoleID, ModelType),
            do_enter2(Unique, Module, Method, RoleID, PID, RoleHeroFBInfo, BarrierID,BarrierInfo);
        {error,ErrCode,Reason}->
            R2 = #m_hero_fb_enter_toc{error_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

log_async_create_map(RoleID, {Unique, Module, Method, RoleID, PID, RoleHeroFBInfo, BarrierID, BarrierMapID, BarrierMapName}) ->
    erlang:put({hero_fb_roleid, RoleID}, {Unique, Module, Method, RoleID, PID, RoleHeroFBInfo, BarrierID, BarrierMapID, BarrierMapName}).
erase_async_create_map_info(RoleID) ->
    erlang:erase({hero_fb_roleid, RoleID}).

do_async_create_map(RoleID) ->
    case erase_async_create_map_info(RoleID) of
        undefined ->
            ignore;
         {Unique, Module, Method, RoleID, PID, RoleHeroFBInfo, BarrierID, BarrierMapID, BarrierMapName} ->
            do_enter3(Unique, Module, Method, RoleID, PID, RoleHeroFBInfo, BarrierID, BarrierMapID, BarrierMapName)
    end.

do_enter2(Unique, Module, Method, RoleID, PID, RoleHeroFBInfo, BarrierID,BarrierInfo) ->
    %% 开启地图
    #r_hero_fb_barrier_info{map_id=BarrierMapID} = BarrierInfo,
    #map_state{mapid=CurrentMapID, map_name=CurrentMapName} = mgeem_map:get_state(),
    %% 如果当前已经在该地图
    case CurrentMapID =:= BarrierMapID of
        true ->
            do_enter3(Unique, Module, Method, RoleID, PID, RoleHeroFBInfo, BarrierID, CurrentMapID, CurrentMapName);
        _ ->
            BarrierMapName = get_hero_fb_map_name(BarrierMapID, RoleID),
            case global:whereis_name(BarrierMapName) of
                undefined ->
                    mod_map_copy:async_create_copy(BarrierMapID, BarrierMapName, ?MODULE, RoleID),
                    log_async_create_map(RoleID, {Unique, Module, Method, RoleID, PID, RoleHeroFBInfo, BarrierID, BarrierMapID, BarrierMapName});
                _MPID ->
                    do_enter3(Unique, Module, Method, RoleID, PID, RoleHeroFBInfo, BarrierID, BarrierMapID, BarrierMapName)
            end
    end.

do_enter3(Unique, Module, Method, RoleID, PID, RoleHeroFBInfo, BarrierID, BarrierMapID, BarrierMapName) ->
    common_misc:unicast2(PID, Unique, Module, Method, #m_hero_fb_enter_toc{}),
    %% 增加活跃度，前再次挑战
    (catch hook_activity_task:done_task(RoleID, ?ACTIVITY_TASK_PERSON_FB)),
    CurMapID = mgeem_map:get_mapid(),
    case is_hero_fb_map_id(CurMapID) of
        true->
            ignore;
        false->
            case  mod_map_actor:get_actor_pos(RoleID, role) of
                undefined->
                    ignore;
                Pos->
                    set_role_hero_fb_info(RoleID, RoleHeroFBInfo#p_role_hero_fb_info{enter_pos = Pos ,enter_mapid = CurMapID}, false)
            end
    end,
    %% 初始化英雄副本地图信息
    ModelType = RoleHeroFBInfo#p_role_hero_fb_info.model_type,
    MapInfo = #r_hero_fb_map_info{
        barrier_id    = BarrierID, 
        model_type    = ModelType, 
        total_monster = 0, 
        map_role_id   = RoleID, 
        enter_time    = common_tool:now(), 
        first_enter   = true
    },
    global:send(BarrierMapName, {mod_hero_fb, {init_hero_fb_map_info, MapInfo}}),
    %% 传送到新地图
    {_, TX, TY} = common_misc:get_born_info_by_map(BarrierMapID),
    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, BarrierMapID, TX, TY).

%% @doc 退出地图
do_quit(Unique, Module, Method, DataIn, RoleID) ->
    case catch check_can_quit_hero_fb(RoleID) of
        {ok, RoleMapInfo} ->
            do_quit2(Unique, Module, Method, DataIn, RoleID, RoleMapInfo);
        {error, Reason} ->
            do_quit_error(RoleID, Unique, Module, Method, Reason)
    end.

do_quit2(Unique, Module, Method, DataIn, RoleID, RoleMapInfo) ->
    common_misc:unicast({role,RoleID}, Unique, Module, Method, #m_hero_fb_quit_toc{}),
    #m_hero_fb_quit_tos{quit_type=QuitType} = DataIn,
    case QuitType of
        %% 在副本死亡退出
        ?hero_fb_quit_type_relive ->
            mod_role2:relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, RoleID, ?RELIVE_TYPE_HOME_FREE_HALF);
        %% 主动退出
        ?hero_fb_quit_type_normal ->
            {ok, HeroFBMapInfo} = get_hero_fb_map_info(RoleID),
            ModelType = HeroFBMapInfo#r_hero_fb_map_info.model_type,
            {ok,#p_role_hero_fb_info{enter_pos=EnterPos,enter_mapid=EnterMapID}}=get_role_hero_fb_info(RoleID, ModelType),
            case is_record(EnterPos,p_pos) 
                     andalso erlang:is_integer(EnterMapID) 
                     andalso EnterMapID>0 of
                true->
                    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, EnterMapID, EnterPos#p_pos.tx, EnterPos#p_pos.ty);
                false->
                    #p_map_role{faction_id=FactionID} = RoleMapInfo,
                    {MapID, TX, TY} = get_hero_fb_quit_pos(FactionID),
                    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, MapID, TX, TY)
            end
    end.


do_quit_error(RoleID, Unique, Module, Method, Reason) ->
    DataRecord = #m_hero_fb_quit_toc{succ=false, reason=Reason},
    common_misc:unicast({role, RoleID}, Unique, Module, Method, DataRecord).

% %% @doc 领取奖励
% do_reward(Unique, Module, Method, DataIn, RoleID, PID) ->
%     #m_hero_fb_reward_tos{reward_id=RewardID} = DataIn,
%     case catch check_can_get_reward(RoleID, RewardID) of
%         {ok, RoleHeroFBInfo} ->
%             do_reward2(Unique, Module, Method, RoleID, PID, RewardID, RoleHeroFBInfo);
%         {error, Reason} ->
%             do_reward_error(Unique, Module, Method, PID, Reason)
%     end.

% do_reward2(Unique, Module, Method, RoleID, PID, RewardID, RoleHeroFBInfo) ->
%     case common_transaction:t(
%            fun() ->
%                    t_do_reward(RoleID, RewardID, RoleHeroFBInfo)
%            end)
%     of
%         {atomic, {GoodsInfo, RoleHeroFBInfo2}} ->
%             Record = #m_hero_fb_reward_toc{},
%             common_misc:unicast2(PID, Unique, Module, Method, Record),
%             % FbChampions = get_fb_champions(RoleHeroFBInfo2),
%             DataRecord = #m_hero_fb_panel_toc{hero_fb=get_role_server_order(RoleID,RoleHeroFBInfo2)},
%             common_misc:unicast2(PID, ?DEFAULT_UNIQUE, ?HERO_FB, ?HERO_FB_PANEL, DataRecord),
%             %% 通知背包变动
%             common_misc:new_goods_notify({role, RoleID}, GoodsInfo);
%         {aborted, {bag_error, _}} ->
%             do_reward_error(Unique, Module, Method, PID, ?_LANG_HERO_FB_REWARD_BAG_FULL);
%         {aborted, Reason} ->
%             ?ERROR_MSG("do_reward2, error, reason: ~w", [Reason]),
%             do_reward_error(Unique, Module, Method, PID, ?_LANG_HERO_FB_REWARD_SYSTEM_ERROR)
%     end.

% do_reward_error(Unique, Module, Method, PID, Reason) ->
%     ?UNICAST_TOC( #m_hero_fb_reward_toc{succ=false, reason=Reason}).

% t_do_reward(RoleID, RewardID, RoleHeroFBInfo) ->
%     #p_role_hero_fb_info{rewards=Rewards} = RoleHeroFBInfo,
%     RoleHeroFBInfo2 = RoleHeroFBInfo#p_role_hero_fb_info{rewards=lists:delete(RewardID, Rewards)},
%     t_set_role_hero_fb_info(RoleID, RoleHeroFBInfo2),
    
%     [RewardList] = ?find_config( chapter_reward),
%     RewardRecord = lists:keyfind(RewardID, #r_item_gift_base.id, RewardList),
%     {ok, GoodsList} = mod_gift:get_p_goods_by_item_gift_base_record(RewardRecord),
%     {ok, GoodsList2} = mod_bag:create_goods_by_p_goods(RoleID, GoodsList),
%     {GoodsList2, RoleHeroFBInfo2}.


% %% @doc 是否可以领取奖励
% check_can_get_reward(RoleID, RewardID) ->
%     {ok, HeroFBMapInfo} = get_hero_fb_map_info(RoleID),
%     {ok, RoleHeroFBInfo} = get_role_hero_fb_info(RoleID, HeroFBMapInfo#r_hero_fb_map_info.model_type),
%     #p_role_hero_fb_info{rewards=Rewards} = RoleHeroFBInfo,
%     case lists:member(RewardID, Rewards) of
%         true ->
%             {ok, RoleHeroFBInfo};
%         _ ->
%             {error, ?_LANG_HERO_FB_REWARD_EVER_GOT}
%     end.

%%@return {ok,RewardPropList}
% check_select_reward(RoleID)->
% 	case mod_bag:get_empty_bag_pos_num(RoleID, 1) of
% 		{ok,Num} when Num>0->
% 			next;
% 		_ ->
% 			?THROW_ERR( ?ERR_HEROFB_BOX_BAG_FULL )
% 	end,
% 	case get(?HERO_FB_BOX_CUR_REWARD_LIST) of
% 		undefined->
% 			?THROW_ERR( ?ERR_HEROFB_BOX_NO_REWARDS );
% 		RewardPropList when is_list(RewardPropList)->
% 			{ok,RewardPropList}
% 	end.

%%@return {ok,LeftBoxPropList}
check_select_reward(RoleID, SelectId)->
    case SelectId>=1 andalso SelectId<6 of
        true->
            next;
        _ ->
            ?THROW_ERR( ?ERR_INTERFACE_ERR )
    end,
    % assert_role_bag(RoleID),
    case mod_role_tab:get(RoleID, ?HERO_FB_BOX_CUR_REWARD_LIST) of
        undefined->
            ?THROW_ERR( ?ERR_HEROFB_BOX_NO_REWARDS );
        {PropList,LotoWtList,CanFetchTimes,CurFetchTimes} when is_list(PropList)->
            LeftBoxPropList = [ E||#p_hero_fb_box_prop{status=?BOX_PROP_STATUS_NORMAL}=E<-PropList],
            case LeftBoxPropList of
                []->
                    ?THROW_ERR( ?ERR_HEROFB_REWARD_NO_NORMAL_PROP );
                _ ->
                    if
                        CanFetchTimes>0->
                            {ok,normal,LeftBoxPropList,LotoWtList};
                        true->
                            {ok,MoneyType,BuyGold} = get_select_money(RoleID, CurFetchTimes),
                            {ok,MoneyType,LeftBoxPropList,LotoWtList,BuyGold}
                    end
            end
    end.
 
get_select_money(RoleID, FetchTimes)->
    case get_hero_fb_map_info(RoleID) of
        {ok, #r_hero_fb_map_info{barrier_id=BarrierID, model_type=ModelType}} ->
            Barrier = get_barrier_by_barrier_id(BarrierID,ModelType),
            case get_select_money_list(Barrier) of
                {false,_}->
                    ?THROW_ERR( ?ERR_HEROFB_REWARD_CANNOT_SELECT );
                {true,MoneyList}->
                    case lists:keyfind(FetchTimes, 1, MoneyList) of
                        {_,MoneyType,MoneyVal}->
                            {ok,MoneyType,MoneyVal};
                        _ ->
                            ?THROW_ERR( ?ERR_HEROFB_REWARD_INVALID_SELECT_TIMES )
                    end
            end;
        _D ->
            ?THROW_ERR( ?ERR_HEROFB_BOX_NOT_IN_MAP )
    end.
get_select_money_list(Barrier) when is_integer(Barrier)->
    cfg_hero_fb:select_money(Barrier).

get_barrier_by_barrier_id(BarrierID, ModelType) when is_integer(BarrierID)->
    BarrierInfoRec = cfg_hero_fb:barrier_info(ModelType, BarrierID),
    BarrierInfoRec#r_hero_fb_barrier_info.barrier.

%% 一键扫荡
do_one_key_sweep(Unique, Module, _Method, DataIn, RoleID, PID) ->
    BarrierIdList = DataIn#m_hero_fb_one_key_sweep_tos.id_list,
    AutoDeductTili = DataIn#m_hero_fb_one_key_sweep_tos.auto_deduct_tili,
    DataIn1 = #m_hero_fb_sweep_tos{auto_deduct_tili=AutoDeductTili},
    do_one_key_sweep_help(BarrierIdList, Unique, Module, DataIn1, RoleID, PID).
do_one_key_sweep_help([], _Unique, _Module, _DataIn, _RoleID, _PID) -> ok;
do_one_key_sweep_help([BarrierID | Rest], Unique, Module, DataIn, RoleID, PID) ->
    DataIn1 = DataIn#m_hero_fb_sweep_tos{barrier_id = BarrierID},
    case do_sweep(Unique, Module, ?HERO_FB_SWEEP, DataIn1, RoleID, PID) of
        true ->
            do_one_key_sweep_help(Rest, Unique, Module, DataIn, RoleID, PID);
        false ->
            ok
    end.

%%扫荡
do_sweep(Unique, Module, Method, DataIn, RoleID, PID)->
	#m_hero_fb_sweep_tos{barrier_id=BarrierId,auto_deduct_tili=AutoDeductTili} = DataIn,
	{SweepSucc, Msg1} = case catch check_do_sweep(RoleID,DataIn) of
        {ok,RewardProps}->
            do_sweep_2(DataIn,RoleID,RewardProps);
        {'EXIT', Reason} ->
            ?ERROR_MSG("sweep exception, Reason: ~w, trace stack: ~w", [Reason, erlang:get_stacktrace()]),
            Msg = #m_hero_fb_sweep_toc{err_code=?ERR_SYS_ERR,barrier_id=BarrierId,auto_deduct_tili=AutoDeductTili},
            {false, Msg};
        {error,ErrCode,Reason}->
            Msg = #m_hero_fb_sweep_toc{err_code=ErrCode,reason=Reason,barrier_id=BarrierId,auto_deduct_tili=AutoDeductTili},
            {false, Msg}
    end,
    ?UNICAST_TOC(Msg1),
    SweepSucc.

do_sweep_2(DataIn,RoleID,RewardProps)->
	#m_hero_fb_sweep_tos{barrier_id=BarrierId,model_type=ModelType,auto_deduct_tili=AutoDeductTili} = DataIn,
	TransFun = fun() -> 
					   t_do_sweep_2(RoleID,RewardProps)
			   end,
	case common_transaction:t( TransFun ) of
		{atomic,{ok,NeedTili,NewGoodsList,NewRoleAttr}}->
			%% 增加本关攻击次数
            {ok,NewFightTimes,HeroFBInfo1, _} = do_add_barrier_fight_times(RoleID,BarrierId,ModelType),
			set_role_hero_fb_info(RoleID, HeroFBInfo1, false),
            BarrierInfoRec = cfg_hero_fb:barrier_info(ModelType, BarrierId),
			%% 发送通关的固定奖励
            common_barrier:send_reward(RoleID, 
                    BarrierInfoRec#r_hero_fb_barrier_info.reward_exp, 
                    BarrierInfoRec#r_hero_fb_barrier_info.reward_prestige, 
                    BarrierInfoRec#r_hero_fb_barrier_info.reward_silver, 
                    BarrierInfoRec#r_hero_fb_barrier_info.reward_items),
			
			%% 增加活跃度，前再次挑战
    		(catch hook_activity_task:done_task(RoleID, ?ACTIVITY_TASK_PERSON_FB)),
%% 			hook_activity_schedule:hook_examine_fb_sweep(RoleID),
			
			common_misc:update_goods_notify({role,RoleID}, NewGoodsList),
			%%扣除体力
			mod_tili:reduce_role_tili(RoleID,NeedTili,true),
%% 			mod_tili:cast_role_tili_info(RoleID),
			case NewRoleAttr of
				undefined-> ignore;
				_ -> common_misc:send_role_gold_change(RoleID, NewRoleAttr)
			end,
            
			Msg = #m_hero_fb_sweep_toc{
                reward_props     = RewardProps,
                reward_exp       = BarrierInfoRec#r_hero_fb_barrier_info.reward_exp,
                barrier_id       = BarrierId,
                auto_deduct_tili = AutoDeductTili,
                fight_times      = NewFightTimes,
                hero_fb          = HeroFBInfo1,
                reward_prestige  = BarrierInfoRec#r_hero_fb_barrier_info.reward_prestige,
                reward_silver    = BarrierInfoRec#r_hero_fb_barrier_info.reward_silver,
                reward_items     = [Id || {Id, _, _, _} <- BarrierInfoRec#r_hero_fb_barrier_info.reward_items]
            },
            {true, Msg};
		{aborted,AbortErr}->
			{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
			Msg = #m_hero_fb_sweep_toc{err_code=ErrCode,reason=Reason,barrier_id=BarrierId,auto_deduct_tili=AutoDeductTili},
            {false, Msg}
	end.

t_do_sweep_2(RoleID,RewardProps) when is_list(RewardProps)->
	{ok,NewGoodsList} = mod_bag:create_goods_by_p_goods(RoleID, RewardProps),
	NeedTili=need_cost_tili(), 
	RoleTili = mod_tili:get_role_tili(RoleID),
	
	case RoleTili>=NeedTili  of
		true->
			NewRoleAttr = undefined;
		_ ->
			%%先买后扣
			{ok,_,NewRoleAttr} = mod_tili:t_buy_tili(RoleID)
	end,
	{ok,NeedTili,NewGoodsList,NewRoleAttr}.

check_do_sweep(RoleID,DataIn)->
	#m_hero_fb_sweep_tos{barrier_id=BarrierId,model_type=ModelType,auto_deduct_tili=AutoDeductTili} = DataIn,
	check_can_enter_hero_fb(RoleID, BarrierId, ModelType, AutoDeductTili),
	assert_role_bag(RoleID),
	
	case mod_map_role:get_role_attr(RoleID) of
		{ok,RoleAttr}-> next;
		_ -> 
			 RoleAttr = null,
			 ?THROW_SYS_ERR()
	end,
	 %%基础分
    {BaseScore,_,_} = cfg_hero_fb:get_misc(fb_star_level),
	{ok,_FbScore,StarLevel} = get_barrier_score(RoleID,RoleAttr,BaseScore,BarrierId,ModelType,0),
	{ok,PropList,LotoWtList,CanFetchTimes} = get_reload_box_prop_list(RoleID,BarrierId,ModelType,StarLevel),
	{ok,RewardProps} = get_reward_props(PropList,LotoWtList,CanFetchTimes,[]),
	{ok,RewardProps}.

get_reward_props(_PropList,_LotoWtList,0,AccIn)->
	{ok,AccIn};
get_reward_props(PropList,LotoWtList,CanFetchTimes,AccIn) when CanFetchTimes>0->
	{ok,RewardPropIdx,LotoRewardProp} = get_loto_reward_prop(PropList,LotoWtList),
	LeftPropList = lists:keydelete(RewardPropIdx, #p_hero_fb_box_prop.prop_idx, PropList),
	get_reward_props(LeftPropList,LotoWtList,CanFetchTimes-1,[LotoRewardProp|AccIn]).

%%@doc 获取最终奖励的物品
get_loto_reward_prop(LeftBoxPropList,AllLotoWtList)->
    LeftPropIdxList = [ PropIdx||#p_hero_fb_box_prop{prop_idx=PropIdx}<-LeftBoxPropList],
    LeftPropLotoWtList = lists:filter(
                        fun({PropIdx,_LotoWt})->
                                lists:member(PropIdx, LeftPropIdxList)
                        end, AllLotoWtList),
    {RewardPropIdx,_} = common_tool:random_from_tuple_weights(LeftPropLotoWtList, 2),
    #p_hero_fb_box_prop{prop=RewardProp} = lists:keyfind(RewardPropIdx, #p_hero_fb_box_prop.prop_idx, LeftBoxPropList),
    {ok,RewardPropIdx,RewardProp}.

assert_role_bag(RoleID)->
	case mod_bag:get_empty_bag_pos_num(RoleID, 1) of
        {ok,Num} when Num>0->
            next;
        _ ->
            ?THROW_ERR( ?ERR_HEROFB_BOX_BAG_FULL )
    end.
%%@interface 选中即抽奖
do_select_reward(Unique, Module, Method, DataIn, RoleID, PID)->
    #m_hero_fb_select_reward_tos{select_id=SelectId} = DataIn,
    case catch check_select_reward(RoleID, SelectId) of
        {ok,normal,LeftBoxPropList,LotoWtList}->
            R2 = do_select_reward_2(RoleID,LotoWtList,LeftBoxPropList, DataIn,PID,free,0);
        {ok,MoneyType,LeftBoxPropList,LotoWtList,BuyGold}->
            R2 = do_select_reward_2(RoleID,LotoWtList,LeftBoxPropList, DataIn,PID,MoneyType,BuyGold);
        {error,ErrCode,Reason}->
            R2 = #m_hero_fb_select_reward_toc{err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC(R2).
    % case catch check_select_reward(RoleID) of
    %     {ok,RewardPropList}->
    %         R2 = do_select_reward_2(RoleID,RewardPropList,PID);
    %     {error,ErrCode,Reason}->
    %         R2 = #m_hero_fb_select_reward_toc{err_code=ErrCode,reason=Reason}
    % end,
    % ?UNICAST_TOC(R2).


% do_select_reward_2(RoleID,RewardPropList,PID)->
% 	TransFun = fun()->
% 					   mod_bag:create_goods_by_p_goods(RoleID, RewardPropList)
% 			   end,
% 	case common_transaction:t( TransFun ) of
% 		{atomic, {ok,NewGoodsList}} ->
% 			%% 道具日志
% 			lists:foreach(
% 			  fun(RewardProp) ->
% 					  common_item_logger:log(RoleID,RewardProp,?LOG_ITEM_TYPE_HEROFB_BOX_FETCH)
% 			  end,RewardPropList),
% 			bc_reward(RoleID,RewardPropList),
% 			%% 通知背包变动
% 			common_misc:new_goods_notify(PID, NewGoodsList),
			
% 			%% 删除掉落物和战绩记录、删除刷宝箱的权重记录
% 			erase(?HERO_FB_BOX_CUR_REWARD_LIST),
% 			%%erase(?HERO_FB_ROLE_RECORD_RESULT),
% 			%%erlang:send(self(),{mod_map_drop,{dropthing_quit,DropThing}}),
% 			#m_hero_fb_select_reward_toc{};
% 		{aborted, {bag_error, _}} ->
% 			#m_hero_fb_select_reward_toc{err_code=?ERR_HEROFB_BOX_BAG_FULL};
% 		{aborted, AbortErr} ->
% 			{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
% 			#m_hero_fb_select_reward_toc{err_code=ErrCode,reason=Reason}
% 	end.

do_select_reward_2(RoleID,LotoWtList,LeftBoxPropList, DataIn,PID, MoneyType, BuyGold)->
     #m_hero_fb_select_reward_tos{select_id=SelectId} = DataIn,
    TransFun = fun()->
                       %%扣元宝
                       case BuyGold>0 of
                           true->
                               {ok,RoleAttr2} = t_deduct_select_money(RoleID,MoneyType,BuyGold);
                           _ ->
                               RoleAttr2 = undefined
                       end,
                       {ok,NewGoodsList,RewardProp,RewardPropIdx} = t_do_select_reward(RoleID,LotoWtList,LeftBoxPropList),
                       t_update_select_prop(RoleID, RewardPropIdx),                
                       {ok,NewGoodsList,RewardProp,RewardPropIdx,RoleAttr2}
               end,
    case common_transaction:t( TransFun ) of
        {atomic, {ok,NewGoodsList,RewardProp,RewardPropIdx,RoleAttr2}} ->
            case should_bc_select_reward(RewardProp,RewardPropIdx) of
                true->
                    case mod_map_role:get_role_base(RoleID) of
                        {ok,#p_role_base{role_name=RoleName}}->
                            GoodsName = common_misc:format_goods_name_colour(RewardProp#p_goods.current_colour,RewardProp#p_goods.name),
                            {ok, #r_hero_fb_map_info{barrier_id=BarrierID,model_type=ModelType}} = get_hero_fb_map_info(RoleID),
                            #r_hero_fb_barrier_info{barrier=Barrier}=cfg_hero_fb:barrier_info(ModelType, BarrierID),
                            Text = common_misc:format_lang(?_LANG_HERO_FB_BC_SELECT_REWARD, [RoleName,Barrier,GoodsName]),
                            ?WORLD_CENTER_BROADCAST(Text), 
                            ok;
                        _ ->
                            ignore
                    end;
                _ ->
                    ignore
            end,
            case RoleAttr2 of
                undefined-> ignore;
                _ ->  common_misc:send_role_gold_change(RoleID,RoleAttr2)
            end,
            
            %% 道具日志
            common_item_logger:log(RoleID,RewardProp,?LOG_ITEM_TYPE_HEROFB_BOX_FETCH),
            common_misc:update_goods_notify(PID, NewGoodsList),
            
            %% 删除掉落物和战绩记录、删除刷宝箱的权重记录
            %%erase(?HERO_FB_BOX_CUR_REWARD_LIST),
            %%erase(?HERO_FB_ROLE_RECORD_RESULT),
            %%erlang:send(self(),{mod_map_drop,{dropthing_quit,DropThing}}),
            {_, _, CanFetchTimes, CurFetchTimes} = mod_role_tab:get(RoleID, ?HERO_FB_BOX_CUR_REWARD_LIST),
             {ok, _, NextGold} = get_select_money(RoleID, CurFetchTimes),
            #m_hero_fb_select_reward_toc{select_id=SelectId,reward_prop=RewardProp,deduct_gold=NextGold,remain_times=CanFetchTimes};
        {aborted, {bag_error, _}} ->
            #m_hero_fb_select_reward_toc{err_code=?ERR_HEROFB_BOX_BAG_FULL};
        {aborted, AbortErr} ->
            {error,ErrCode,Reason} = parse_aborted_err(AbortErr),
            #m_hero_fb_select_reward_toc{err_code=ErrCode,reason=Reason}
    end.
t_update_select_prop(RoleID, SelectId)->
    {PropList,LotoWtList,CanFetchTimes,CurFetchTimes} = mod_role_tab:get(RoleID, ?HERO_FB_BOX_CUR_REWARD_LIST),
    Prop = lists:keyfind(SelectId, #p_hero_fb_box_prop.prop_idx, PropList),
    Prop2 = Prop#p_hero_fb_box_prop{status=?BOX_PROP_STATUS_FETCHED},
    PropList2 = lists:keystore(SelectId, #p_hero_fb_box_prop.prop_idx, PropList, Prop2),
    mod_role_tab:put(RoleID, ?HERO_FB_BOX_CUR_REWARD_LIST,{PropList2,LotoWtList,CanFetchTimes-1,CurFetchTimes+1}).
%%扣除钱币/元宝
t_deduct_select_money(RoleID,MoneyType,DeductMoney) when is_integer(RoleID)->
    ConsumeLogType = ?CONSUME_TYPE_GOLD_HERO_FB_SELECT,
    case common_bag2:t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeLogType) of
        {ok,RoleAttr2}->
            {ok,RoleAttr2};
        {error, Reason} ->
            ?THROW_ERR(?ERR_OTHER_ERR, Reason);
        _ ->
            ?THROW_SYS_ERR()
    end. 

t_do_select_reward(RoleID,AllLotoWtList,LeftBoxPropList)->
    {ok,RewardPropIdx,LotoRewardProp} = get_loto_reward_prop(LeftBoxPropList,AllLotoWtList),
    {ok,NewGoodsList} = mod_bag:create_goods_by_p_goods(RoleID, [LotoRewardProp]),
    {ok,NewGoodsList,LotoRewardProp,RewardPropIdx}.    
%%判断是否进行广播
should_bc_select_reward(RewardProp,RewardPropIdx)->
    #p_goods{current_colour=Color} = RewardProp,
    if
        RewardPropIdx>3 andalso Color>3->
            true;
        true->
            false
    end.    

%% @doc 是否可以退出副本
check_can_quit_hero_fb(RoleID) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            RoleMapInfo = undefined,
            erlang:throw({error, ?_LANG_HERO_FB_QUTI_SYSTEM_ERROR});
        RoleMapInfo ->
            ok
    end,
    case is_in_hero_fb(RoleID) of
        true  -> ok;
        false -> erlang:throw({error, <<"退出请求无效，您不在境界副本中">>})
    end,
    {ok, RoleMapInfo}.

assert_valid_map_id(DestMapID)->
    case is_hero_fb_map_id(DestMapID) of
        true->
            ok;
        _ ->
            ?ERROR_MSG("严重，试图进入错误的地图,DestMapID=~w",[DestMapID]),
            throw({error,error_map_id,DestMapID})
    end.

is_hero_fb_map_id(DestMapID)->
    cfg_hero_fb:is_hero_fb_map_id(DestMapID).

%% @doc 获取英雄副本地图进程名
get_hero_fb_map_name(MapID, RoleID) ->
    lists:concat(["mgee_hero_fb_map_", MapID, "_", RoleID]).

get_barrier_mission_id(BarrierID, FactionID)->
    case cfg_hero_fb:do_mission(BarrierID, FactionID) of
        [] -> {error, not_found};
        MissionID -> {ok, MissionID}
    end.


%%@doc 是否正在接境界任务（武林新秀以上的不算）
is_doing_barrier_mission(RoleID,BarrierID)->
    {ok, #p_role_base{faction_id = FactionID}} = mod_map_role:get_role_base(RoleID),
    case get_barrier_mission_id(BarrierID, FactionID) of
        {ok,MissionID}->
            case mod_mission_data:get_pinfo(RoleID, MissionID) of
                #p_mission_info{current_status=?MISSION_STATUS_DOING} ->
                    true;
                _ ->
                    false
            end;
        _ ->
            false
    end.


%% @doc 检查是否可以进入英雄副本
check_can_enter_hero_fb(RoleID, BarrierID, ModelType, AutoDeductTili) ->
    % case mod_map_actor:get_actor_mapinfo(RoleID, role) of
    %     undefined ->
    %         RoleMapInfo = undefined,
    %         ?THROW_SYS_ERR();
    %     RoleMapInfo ->
    %         ok
    % end,
    
    {ok, Rolebase} = mod_map_role:get_role_base(RoleID),
    FactionID = Rolebase#p_role_base.faction_id,
    RoleState = Rolebase#p_role_base.status,
    % case Level < MinLevel of
    %     true ->
    %         ?THROW_ERR( ?ERR_HEROFB_ENTER_MIN_LV_LIMITED );
    %     _ ->
    %         ok
    % end,
    %% 检查是否副本地图 除英雄副本    
    #map_state{map_type=MapType,mapid=MapID} = mgeem_map:get_state(),
    case MapType of
        ?MAP_TYPE_NORMAL->
            %% 是否在外国
            case common_misc:if_in_enemy_country(FactionID, MapID) of
                true->
                    ?THROW_ERR( ?ERR_HEROFB_NOT_IN_SELF_COUNTRY );
                _ ->
                    next
            end;
        _ ->
            case is_hero_fb_map_id(MapID) of
                true->
                    next;
                false->
                    ?THROW_ERR( ?ERR_HEROFB_ILLEGAL_ENTER_MAP )
            end
    end,
    case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
        true ->
            ?THROW_ERR(?ERR_OTHER_ERR, ?_LANG_XIANNVSONGTAO_MSG);
        false -> ignore
    end,
    %% 角色状态检测
    case RoleState of
        ?ROLE_STATE_DEAD ->
            ?THROW_ERR( ?ERR_HEROFB_ENTER_ROLE_DEAD );
        ?ROLE_STATE_STALL ->
            ?THROW_ERR( ?ERR_HEROFB_ENTER_ROLE_STALL );
        ?ROLE_STATE_FIGHT->
            ?THROW_ERR( ?ERR_HEROFB_ENTER_ROLE_FIGHT );
        _ ->
            ok
    end,
    case mod_horse_racing:is_role_in_horse_racing(RoleID) of
        true ->
            ?THROW_ERR(?ERR_HEROFB_ENTER_ROLE_HORSE_RACING);
        _ ->
            ignore
    end,
    case get_role_hero_fb_info(RoleID, ModelType) of
        {ok, RoleHeroFBInfo} ->
            ok;
        _ ->
            RoleHeroFBInfo = undefined,
            ?THROW_SYS_ERR()
    end,
    %% 关卡有没开通
    #p_role_hero_fb_info{progress=Progress} = RoleHeroFBInfo,
    case BarrierID > Progress of
        true ->
            ?THROW_ERR( ?ERR_HEROFB_ENTER_BARRIER_LOCK );
        _ ->
            ok
    end,
	assert_tili(RoleID,AutoDeductTili),
	
    %% 是否在同一个时间段内
    case cfg_hero_fb:barrier_info(ModelType, BarrierID) of
        []->
            BarrierInfo = null,
            ?THROW_SYS_ERR();
        BarrierInfo-> next
    end,   
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    OpenLv = BarrierInfo#r_hero_fb_barrier_info.open_lv,
    case RoleAttr#p_role_attr.level < OpenLv of
        true ->
            Msg = common_misc:format_lang(<<"无法进入，您需要达到~s级才能进入">>, [erlang:integer_to_list(OpenLv)]),
            ?THROW_ERR(?ERR_OTHER_ERR, Msg);
        _ ->
            ok
    end,
    assert_barrier_fight_times(RoleID,RoleHeroFBInfo,BarrierID),
    {ok,BarrierInfo}.

assert_tili(RoleID,AutoDeductTili) ->
	%%检测体力值是否足够
	RoleTili = mod_tili:get_role_tili(RoleID),
	case AutoDeductTili of
		true ->
			next;
		false ->
			case RoleTili >= need_cost_tili() of
				true ->
					next;
				false ->
					?THROW_ERR(?ERR_HEROFB_ENTER_NO_ENOUGH_TILI)
			end
	end.
assert_barrier_fight_times(RoleID,RoleHeroFBInfo,BarrierID)->
    #p_role_hero_fb_info{last_enter_time=LastEnterTime} = RoleHeroFBInfo,
    case should_reset_barrier_fight_times(LastEnterTime) of
        true->
            %% =====此处会重设副本攻击次数=====
            {ok,NewHeroFBInfo} = do_reset_barrier_fight_times(RoleID,RoleHeroFBInfo);
        _ ->
           NewHeroFBInfo = RoleHeroFBInfo
    end,
	FightTimes = get_fight_times(BarrierID,NewHeroFBInfo),
	case FightTimes > 0 of
		true ->
			next;
		false ->
			?THROW_ERR(?ERR_HEROFB_ENTER_TIMES_LIMITED)
	end,
    ok.

%% @doc 清除角色英雄副本信息
erase_role_hero_fb_info(RoleID) ->
    mod_role_tab:erase({?role_hero_fb, RoleID}).

%% @doc 添加单关攻击次数  不写进程字典  
do_add_barrier_fight_times(RoleID,BarrierID,ModelType)->
    {ok, OldHeroFBInfo} = get_role_hero_fb_info(RoleID,ModelType),
    
    HeroFbRecordList = OldHeroFBInfo#p_role_hero_fb_info.fb_record,
    case lists:keyfind(BarrierID,#p_hero_fb_barrier.barrier_id,HeroFbRecordList) of
        false->
            IsFirstTime = true,
            NewTimes = get_new_fight_times(RoleID,BarrierID,ModelType) - 1,
            NewHeroFbRec = #p_hero_fb_barrier{barrier_id=BarrierID,fight_times=NewTimes};
        #p_hero_fb_barrier{fight_times=Times}=HeroFbRecord->
            IsFirstTime = false,
            NewTimes = get_new_fight_times(RoleID,BarrierID,ModelType,Times),
            NewHeroFbRec = HeroFbRecord#p_hero_fb_barrier{fight_times=NewTimes}
    end,
    
    NewHeroFbRecordList = lists:keystore(BarrierID, #p_hero_fb_barrier.barrier_id, HeroFbRecordList, NewHeroFbRec),
    {ok,NewTimes,OldHeroFBInfo#p_role_hero_fb_info{fb_record=NewHeroFbRecordList}, IsFirstTime}.

get_new_fight_times(_RoleID,BarrierID,ModelType)->
    get_default_barrier_fight_times(BarrierID,ModelType).

get_new_fight_times(RoleID,BarrierID,_ModelType,Times)->
    case is_doing_barrier_mission(RoleID,BarrierID) of
        true->
            Times;
        _ ->
            Times-1
    end.

gm_reset_barrier_fight_times(RoleID,ModelType)->
    {ok, OldHeroFBInfo} = get_role_hero_fb_info(RoleID,ModelType),
    NewHeroFBInfo = OldHeroFBInfo#p_role_hero_fb_info{
        last_enter_time = common_tool:now(),
        today_count     = 0
    },
    do_reset_barrier_fight_times(RoleID,NewHeroFBInfo),
    ok.

gm_set_progress(RoleID, Progress, ModelType) ->
    do_reset_progress(RoleID, Progress, ModelType).
    
do_reset_progress(RoleID, Progress, ModelType) when is_integer(Progress)->
    RoleHeroFBInfo  = build_default_progress(RoleID, ModelType),
    RoleHeroFBInfo1 = RoleHeroFBInfo#p_role_hero_fb_info{progress = Progress},
    set_role_hero_fb_info(RoleID, RoleHeroFBInfo1, true),
    ok.

build_default_progress(RoleID, ModelType) ->
    #p_role_hero_fb_info{
        model_type      = ModelType, 
        role_id         = RoleID,
        last_enter_time = common_tool:now(),
        today_count     = 0,
        progress        = cfg_hero_fb:get_first_barrier_id(ModelType),
        rewards         = [],
        fb_record       = []
    }.

%% @doc 重设单关攻击次数 写进程字典
do_reset_barrier_fight_times(RoleID,HeroFBInfo)->
    ModelType = HeroFBInfo#p_role_hero_fb_info.model_type,
    NewHeroFBInfoList = 
        [begin
             FightTimes = get_default_barrier_fight_times(BarrierID,ModelType),
             HeroFBBarrierInfo#p_hero_fb_barrier{fight_times=FightTimes}
         end
         || #p_hero_fb_barrier{barrier_id=BarrierID}=HeroFBBarrierInfo <-HeroFBInfo#p_role_hero_fb_info.fb_record],
    NewHeroFBInfo = HeroFBInfo#p_role_hero_fb_info{fb_record=NewHeroFBInfoList,last_enter_time=common_tool:now()},
    set_role_hero_fb_info(RoleID, NewHeroFBInfo, false),
    {ok,NewHeroFBInfo}.

get_fight_times(CheckBarrierID,HeroFBInfo) ->
    ModelType = HeroFBInfo#p_role_hero_fb_info.model_type,
	case lists:keyfind(CheckBarrierID, #p_hero_fb_barrier.barrier_id, HeroFBInfo#p_role_hero_fb_info.fb_record) of
		#p_hero_fb_barrier{fight_times=FightTimes} ->
			FightTimes;
		_ ->
			get_default_barrier_fight_times(CheckBarrierID, ModelType)
	end.

%%@doc 获取每一关的默认次数
get_default_barrier_fight_times(BarrierID,ModelType)->
    BarrierInfo = cfg_hero_fb:barrier_info(ModelType, BarrierID),
    BarrierInfo#r_hero_fb_barrier_info.fight_times.


should_get_role_order()->
    cfg_hero_fb:get_misc(should_get_role_order) == 1.

%% 找出玩家每一关的排名
get_role_server_order(RoleID,RoleHeroFbInfo)->
    case should_get_role_order() of
        true->
            get_role_server_order_2(RoleID,RoleHeroFbInfo);
        _ ->
            RoleHeroFbInfo
    end.
    
get_role_server_order_2(RoleID,RoleHeroFbInfo)->
    #p_role_hero_fb_info{fb_record=RoleHeroFbList} = RoleHeroFbInfo,
    RoleHeroFbList1 =
    [begin
         Order = 
             case db:dirty_read(?DB_HERO_FB_RECORD,BarrierID) of
                 []->0;
                 [#r_hero_fb_record{best_record=RecordList}]->
                     case lists:keyfind(RoleID, #p_hero_fb_record.role_id, RecordList) of
                         false->0;
                         #p_hero_fb_record{order=_Order}->_Order
                     end
             end,
         RoleHeroFb#p_hero_fb_barrier{order=Order}
     end||#p_hero_fb_barrier{barrier_id=BarrierID} = RoleHeroFb<-RoleHeroFbList],
    RoleHeroFbInfo#p_role_hero_fb_info{fb_record=RoleHeroFbList1}.

% %%获取每一关的霸主
% get_fb_champions(RoleHeroFbInfo)->
%     #p_role_hero_fb_info{fb_record=RoleFbRecords} = RoleHeroFbInfo,
%     BarrierIDList = [BarrierID||#p_hero_fb_barrier{barrier_id=BarrierID}<-RoleFbRecords],
%     lists:foldl(
%       fun(BarrierID,AccIn)->
%               case db:dirty_read(?DB_HERO_FB_RECORD,BarrierID) of
%                   []->
%                       AccIn;
%                   [#r_hero_fb_record{best_record=RecordList}]->
%                       case RecordList of
%                           [#p_hero_fb_record{role_name=RoleName}|_T] ->
%                               [#p_hero_fb_champion{barrier_id=BarrierID,role_name=RoleName}|AccIn];
%                           _ ->
%                               AccIn
%                       end
%               end 
%       end, [], BarrierIDList).

refresh_fight_times(RoleHeroFBInfo)->
    #p_role_hero_fb_info{role_id=RoleID,last_enter_time=LastEnterTime} = RoleHeroFBInfo,
    
    case should_reset_barrier_fight_times(LastEnterTime) of
        true->
            {ok,RoleHeroFBInfo1} = do_reset_barrier_fight_times(RoleID,RoleHeroFBInfo),
            RoleHeroFBInfo1;
        _ ->
            RoleHeroFBInfo
    end.

should_reset_barrier_fight_times(LastEnterTime)->
    not common_tool:check_if_same_day(LastEnterTime, common_tool:now()).
    % Today = date(),
    % ZeroHourTime = common_tool:datetime_to_seconds({Today,{0,0,0}}),
    
    % if
    %     (LastEnterTime>=ZeroHourTime)-> 
    %         false;
    %     true->
    %         true
    % end.

%%@doc 初始化设置玩家的境界副本数据
init_role_hero_fb_info(RoleID,_ , OldRHeroFbRec) when is_record(OldRHeroFbRec, r_hero_fb) ->
    [set_role_hero_fb_info(RoleID,HeroFbInfo,false) || HeroFbInfo <- OldRHeroFbRec#r_hero_fb.fb_info_list];
init_role_hero_fb_info(RoleID,_ , undefined)->
   [do_reset_progress(RoleID, cfg_hero_fb:get_first_barrier_id(ModelType), ModelType) || ModelType <- ?ALL_MODEL_TYPES].

    
%% @doc 获取角色副本信息
get_role_all_hero_fb_info(RoleID) ->
    Fun = fun(ModelType) ->
        {ok, HeroFBInfo} = get_role_hero_fb_info(RoleID, ModelType),
        HeroFBInfo
    end,

    AllHeroFBInfo = [Fun(ModelType) || ModelType <- ?ALL_MODEL_TYPES],
    RHeroFbRec = #r_hero_fb{
        role_id      = RoleID,
        fb_info_list = AllHeroFBInfo
    },
    {ok, RHeroFbRec}.

get_role_hero_fb_info(RoleID, ModelType) ->
    case mod_role_tab:get(RoleID, {?role_hero_fb, ModelType}) of
        undefined ->
            {error, not_found};
        RoleHeroFBInfo ->
            #p_role_hero_fb_info{role_id=RoleID, last_enter_time=LastEnterTime} = RoleHeroFBInfo,
            EnterDate = common_time:time_to_date(LastEnterTime),
            Today = erlang:date(),
            case EnterDate =:= Today andalso LastEnterTime =/= 0 of
                true ->
                    RoleHeroFBInfo2 = RoleHeroFBInfo;
                _ ->
                    RoleHeroFBInfo2 = RoleHeroFBInfo#p_role_hero_fb_info{today_count=0},
                    set_role_hero_fb_info(RoleID, RoleHeroFBInfo2, false)
            end,
            {ok,RoleHeroFBInfo2}
    end.

%% @doc 设置角色副本信息
set_role_hero_fb_info(RoleID, RoleHeroFB2, IsNotify) ->
    TransFun = fun() ->
                       t_set_role_hero_fb_info(RoleID, RoleHeroFB2)
               end,
    case common_transaction:t( TransFun ) of
        {atomic, _} ->
            case IsNotify of
                true ->
                    % FbChampions = get_fb_champions(RoleHeroFB2),
                    DataRecord = #m_hero_fb_panel_toc{hero_fb=get_role_server_order(RoleID,RoleHeroFB2)},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HERO_FB, ?HERO_FB_PANEL, DataRecord);
                _ ->
                    ignore
            end,
            ok;
        {aborted, Reason} ->
            ?ERROR_MSG("set_role_hero_fb_info, error, reason: ~w", [Reason]),
            error
    end.

%% @doc 
t_set_role_hero_fb_info(RoleID, RoleHeroFB) ->
    mod_map_role:update_role_id_list_in_transaction(RoleID, ?role_hero_fb, ?role_hero_fb_copy),
    mod_role_tab:put(RoleID, {?role_hero_fb, RoleHeroFB#p_role_hero_fb_info.model_type}, RoleHeroFB).

init_npc_talks(_MapInfo)-> ok.
    % #r_hero_fb_map_info{map_role_id=RoleID,barrier_id=BarrierId} = MapInfo,
    % case ?find_config({barrier_talk,BarrierId}) of
    %     [BarrierTalkList]->
    %         lists:foreach(
    %           fun(E)->
    %                   #r_hero_fb_barrier_talk{delay_time=DelayTime,npc_id=NpcId,talk_id=TalkId} =E,
    %                   if
    %                       DelayTime>0->
    %                           erlang:send_after(DelayTime*1000, self(), {mod,?MODULE,{do_barrier_talk,RoleID,NpcId,TalkId}});
    %                       true->
    %                           ignore
    %                   end
    %           end,BarrierTalkList);
    %     _ ->
    %         ignore
    % end.

%% @doc 设置英雄副本地图信息
set_hero_fb_map_info(MapInfo) ->
    #r_hero_fb_map_info{map_role_id=RoleID} = MapInfo,
    mod_role_tab:put(RoleID, ?hero_fb_map_info, MapInfo).

%% @doc 获取英雄副本地图信息
get_hero_fb_map_info(RoleID) ->
    case mod_role_tab:get(RoleID, ?hero_fb_map_info) of
        undefined ->
            {error, not_found};
        MapInfo ->
            {ok, MapInfo}
    end.    


%% @doc 计算闯关时间(ms)
get_hero_fb_time_used(EnterTime) ->
    common_tool:now() - EnterTime.

%% @doc 获取下一关卡ID
get_new_progress(BarrierID, ModelType, Progress) ->
    case Progress > BarrierID of
        true -> {ok, Progress};
        _    ->
            BarrierInfo = cfg_hero_fb:barrier_info(ModelType, BarrierID),
            {ok, BarrierInfo#r_hero_fb_barrier_info.next_barrier_id}
    end.

%% @doc 获取排名 排名为从分数低到高
%% get_rank_order(Score, Order, [#p_hero_fb_record{score=Sc}|T]) ->
%%     case Score =< Sc of
%%         true ->
%%             {ok, Order};
%%         _ ->
%%             get_rank_order(Score, Order-1, T)
%%     end;
%% get_rank_order(_Score, Order, []) ->
%%     {ok, Order}.

%% @doc 获取掉落物名称
get_drop_goods_name(DropTypeIDList) ->
    DropNameList =
        lists:map(
          fun({TypeID, Type, Colour}) ->
                  case Type of
                      ?TYPE_EQUIP ->
                          {ok, #p_equip_base_info{equipname=GoodsName, colour=BColour}} = mod_equip:get_equip_baseinfo(TypeID);
                      ?TYPE_STONE ->
                          {ok, #p_stone_base_info{stonename=GoodsName, colour=BColour}} = mod_stone:get_stone_baseinfo(TypeID);
                      _ ->
                          {ok, #p_item_base_info{itemname=GoodsName, colour=BColour}} = mod_item:get_item_baseinfo(TypeID)
                  end,

                  case Colour of
                      ?COLOUR_WHITE ->
                          Colour2 = BColour;
                      _ ->
                          Colour2 = Colour
                  end,
                  
                  case Colour2 of
                      ?COLOUR_GREEN->
                          io_lib:format("<font color=\"#12CC95\">【~s】</font>", [GoodsName]);
                      ?COLOUR_BLUE->
                          io_lib:format("<font color=\"#0D79FF\">【~s】</font>", [GoodsName]);
                      ?COLOUR_PURPLE->
                          io_lib:format("<font color=\"#FE00E9\">【~s】</font>", [GoodsName]);
                      ?COLOUR_ORANGE->
                          io_lib:format("<font color=\"#FF7E00\">【~s】</font>", [GoodsName]);
                      ?COLOUR_GOLD->
                          io_lib:format("<font color=\"#FFD700\">【~s】</font>", [GoodsName]);
                      _ ->
                          io_lib:format("<font color=\"#FFFFFF\">【~s】</font>", [GoodsName])
                  end
          end, DropTypeIDList),
    
    string:join(DropNameList, "、"). 

%% @doc 获取跳转点位置
get_hero_fb_quit_pos(FactionID) ->
    PosList = cfg_hero_fb:get_misc(npc_pos),
    {_, {MapID, TX, TY}} = lists:keyfind(FactionID, 1, PosList),
    {MapID, TX, TY}.

%% 各国ID
-define(faction_hongwu, 1).
-define(faction_yongle, 2).
-define(faction_wanli, 3).

%% @doc 获取角色名字，包涵国家颜色
get_role_name_color(RoleName, FactionID) ->
    case FactionID of
        ?faction_hongwu ->
            io_lib:format("<font color=\"#00FF00\">[~s]</font>", [RoleName]);
        ?faction_yongle ->
            io_lib:format("<font color=\"#F600FF\">[~s]</font>", [RoleName]);
        _ ->
            io_lib:format("<font color=\"#00CCFF\">[~s]</font>", [RoleName])
    end.

%% @doc 下线保护时间到，如果角色不在副本中杀掉副本地图进程
do_offline_terminate(RoleID) ->
    case get_hero_fb_map_info(RoleID) of
        {ok, MapInfo} ->
            case mod_map_actor:get_in_map_role() of
                [] ->
                    common_map:exit( hero_fb_role_quit ),
                    catch do_hero_fb_log(MapInfo);
                _ ->
                    ignore
            end;
        _ ->
            common_map:exit( hero_fb_role_quit )
    end.

do_safe_kill(_RoleID) ->
    common_map:exit( hero_fb_role_quit ).

%% @doc 是否在英雄副本中
is_in_hero_fb(RoleID) ->
    CurMapId = mgeem_map:get_mapid(),
    case get_hero_fb_map_info(RoleID) of
        {ok, HeroFBMapInfo} ->
            ModelType = HeroFBMapInfo#r_hero_fb_map_info.model_type,
            BarrierID = HeroFBMapInfo#r_hero_fb_map_info.barrier_id,
            BarrierInfoRec = cfg_hero_fb:barrier_info(ModelType, BarrierID),
            (BarrierInfoRec#r_hero_fb_barrier_info.map_id == CurMapId);
        _ ->
            false
    end.

%% @doc 通关奖励，首次完成一章会得到奖励
get_chapter_reward(Rewards, Progress, Progress2) ->
    OldChapter = Progress div 100,
    NewChapter = Progress2 div 100,
    case OldChapter =:= NewChapter of
        true ->
            Rewards;
        _ ->
            [OldChapter|Rewards]
    end.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%% @doc 英雄副本日志
do_hero_fb_log(HeroFBMapInfo) ->
    #r_hero_fb_map_info{map_role_id=RoleID, barrier_id=BarrierID, enter_time=EnterTime} = HeroFBMapInfo,
    RemainMonster = erlang:length(mod_map_monster:get_monster_id_list()),
    case RemainMonster =:= 0 of
        true ->
            Status = ?fb_quit_status_finish;
        _ ->
            Status = ?fb_quit_status_fail
    end,
    {ok, #p_role_base{role_name=RoleName, faction_id=FactionID}} = common_misc:get_dirty_role_base(RoleID),
    {A, B, _} = EnterTime,
    EnterTime2 = A * 1000000 + B,
    StopTime = common_tool:now(),

    PersonalFBLog = #r_hero_fb_log{role_id=RoleID,
                                       role_name=RoleName,
                                       faction_id=FactionID,
                                       fb_id=BarrierID,
                                       start_time=EnterTime2,
                                       end_time=StopTime,
                                       status=Status},
    common_general_log_server:log_hero_fb(PersonalFBLog).



%%解析错误码
parse_aborted_err(AbortErr)->
    case AbortErr of
        {error,ErrCode,_Reason} when is_integer(ErrCode) ->
            AbortErr;
        {error,AbortReason} when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        AbortReason when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
		{bag_error,_} ->
			{error,?ERR_HEROFB_BOX_BAG_NOT_ENGUGHT,<<"背包空间不够">>};
        _ ->
            ?ERROR_MSG(" aborted,AbortErr=~w,stack=~w",[AbortErr,erlang:get_stacktrace()]),
            {error,?ERR_SYS_ERR,undefined}
    end.


%% 获取指定关数的所有普通道具列表
get_box_basic_props(Barrier, ModelType)->
    cfg_hero_fb:basic_reward(Barrier, ModelType).

%% 成功过关后扣取的体力值
need_cost_tili() ->
    cfg_hero_fb:get_misc(need_cost_tili).
    