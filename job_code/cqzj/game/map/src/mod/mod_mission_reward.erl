%% Author: chixiaosheng
%% Created: 2011-3-28
%% Description:发放奖励
-module(mod_mission_reward, [RoleID, MissionID, MissionBaseInfo, DORequestRecord]).

%%
%% Include files
%%
-include("mission.hrl").

%%
%% Exported Functions
%%
-export([reward/0]).
-define(INCREASE_VAL(Val), mod_mission_misc:get_increase_val(Val,MultTimes)).

%%
%% API Functions
%%
%% --------------------------------------------------------------------
%% 给与奖励 返回 p_mission_reward_data
%% -------------------------------------------------------------------- 

%%@return #p_mission_reward_data{}
reward() ->
    BigGroup = MissionBaseInfo#mission_base_info.big_group,
    if
        BigGroup =:= 0 ->
            do_give_normal();
        true ->
            do_give_group()
    end.

%%循环任务分组奖励
do_give_group() ->
    BigGroup = MissionBaseInfo#mission_base_info.big_group,
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    Level = RoleAttr#p_role_attr.level,
    Key = {BigGroup, Level},
    RewardList = mod_mission_data:get_setting(group_reward),
    MathReward = lists:keyfind(Key, 1, RewardList),
    case MathReward of
        {Key, Exp, SilverBind, Prestige,PropList, Tili}->
            GoldBind=0;
        {Key, Exp, SilverBind, GoldBind,Prestige,PropList, Tili}->
            next
    end,
        
    
    BaseRewardDataTmp = MissionBaseInfo#mission_base_info.reward_data,
    %% 去掉 attr_reward_formula=?MISSION_ATTR_REWARD_FORMULA_CALC_ALL_TIMES,
    %% 使用任务奖励配置的奖励方式
    BaseRewardData = BaseRewardDataTmp#mission_reward_data{exp=Exp, 
                                                           prestige = Prestige,
                                                           silver_bind=SilverBind,
                                                           gold_bind=GoldBind, 
                                                           tili = Tili}, 
    AttrRewardFormula = BaseRewardData#mission_reward_data.attr_reward_formula,
    PropRewardFormula = BaseRewardData#mission_reward_data.prop_reward_formula,
    {PMissionRewardData, FuncList1} = do_give_attr_reward(AttrRewardFormula, BaseRewardData),
    mod_mission_misc:push_trans_func(RoleID, FuncList1),
    
    SuccTimes = mod_mission_data:get_succ_times(RoleID, MissionBaseInfo),
    PMissionRewardData2 = 
        case lists:keyfind(SuccTimes, 1, PropList) of
            false ->
                PMissionRewardData;
            {SuccTimes, PropRewardBaseList} ->
				Category = RoleAttr#p_role_attr.category,
				CategoryReward = BaseRewardData#mission_reward_data.category_reward,
                {PropRewardList, FuncList2} = do_give_prop_reward(PropRewardFormula, Category, PropRewardBaseList, CategoryReward),
                mod_mission_misc:push_trans_func(RoleID, FuncList2),
                PMissionRewardData#p_mission_reward_data{prop=PropRewardList}
        end,
    PMissionRewardData2.

do_give_normal() ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	Category = RoleAttr#p_role_attr.category,
    BaseRewardData = MissionBaseInfo#mission_base_info.reward_data,
    AttrRewardFormula = BaseRewardData#mission_reward_data.attr_reward_formula,
    PropRewardFormula = BaseRewardData#mission_reward_data.prop_reward_formula,
    
    {PMissionRewardData, FuncList1} = do_give_attr_reward(AttrRewardFormula, BaseRewardData),
    mod_mission_misc:push_trans_func(RoleID,FuncList1),
    
    PropRewardBaseList = BaseRewardData#mission_reward_data.prop_reward,
	CategoryReward = BaseRewardData#mission_reward_data.category_reward,
    {PropRewardList, FuncList2} = do_give_prop_reward(PropRewardFormula, Category, PropRewardBaseList, CategoryReward),
    mod_mission_misc:push_trans_func(RoleID,FuncList2),
    
    PMissionRewardData#p_mission_reward_data{prop=PropRewardList}.
    
do_give_attr_reward(?MISSION_ATTR_REWARD_FORMULA_NO, _) ->
    {#p_mission_reward_data{},[]};
    
do_give_attr_reward(?MISSION_ATTR_REWARD_FORMULA_NORMAL, BaseRewardData) ->
    #mission_reward_data{exp=AddExp,
                         silver=AddSilver,
                         silver_bind=AddSilverBind,
                         gold_bind=AddGoldBind,
                         prestige = Prestige,
                         tili = Tili} = BaseRewardData,
    do_give_attr_reward_2(AddExp, AddSilver, AddSilverBind, AddGoldBind,Prestige, Tili);

do_give_attr_reward(?MISSION_ATTR_REWARD_FORMULA_CALC_ALL_TIMES, BaseRewardData) ->
    #mission_reward_data{rollback_times=RollBackTimes,
                         exp=AddExp,
                         silver=AddSilver,
                         silver_bind=AddSilverBind,
                         gold_bind=AddGoldBind,
                         prestige = Prestige, 
                         tili = Tili} = BaseRewardData,
   
    CurDoneTimes = mod_mission_data:get_succ_times(RoleID, MissionBaseInfo),
    MultTimes = get_multtimes(CurDoneTimes,RollBackTimes),
    
    do_give_attr_reward_2( ?INCREASE_VAL(AddExp), ?INCREASE_VAL(AddSilver), ?INCREASE_VAL(AddSilverBind),AddGoldBind,?INCREASE_VAL(Prestige), ?INCREASE_VAL(Tili));

do_give_attr_reward(?MISSION_ATTR_REWARD_FORMULA_CALC_EXP_TIMES, BaseRewardData) ->
    #mission_reward_data{rollback_times=RollBackTimes,
                         exp=AddExp1,
                         silver=AddSilver1,
                         silver_bind=AddSilverBind1,
                         gold_bind=AddGoldBind1,
                         prestige = Prestige,
                         tili = Tili} = BaseRewardData,
    CurDoneTimes = mod_mission_data:get_succ_times(RoleID, MissionBaseInfo),
    MultTimes = get_multtimes(CurDoneTimes,RollBackTimes),
    
    do_give_attr_reward_2(?INCREASE_VAL(AddExp1),AddSilver1,AddSilverBind1,AddGoldBind1,Prestige,Tili);

%%直接给五行属性
do_give_attr_reward(?MISSION_ATTR_REWARD_FORMULA_WU_XING, _) ->
    Fun = fun() ->
            FineRecord = #m_role2_five_ele_attr_tos{type=0},
            {ok, RoleState} = mod_map_role:get_role_state(RoleID),
            #r_role_state2{pid=PID} = RoleState,
            Line = common_misc:get_role_line_by_id(RoleID),
            mod_role2:handle({?DEFAULT_UNIQUE, ?ROLE2, 
                      ?ROLE2_FIVE_ELE_ATTR, FineRecord, 
                      RoleID, PID, Line, mgeem_map:get_state()})
          end,
    {#p_mission_reward_data{},[{func, Fun}]}.

%%获取翻倍系数
get_multtimes(CurDoneTimes,RollBackTimes)->
    MultTimes = CurDoneTimes rem RollBackTimes,
    if
        MultTimes>0 ->
            MultTimes;
        true->
            RollBackTimes
    end.            

do_give_prop_reward(_PropRewardFormula, Category, PropRewardList, _CategoryReward=true) ->
	[CategoryList] = common_config_dyn:find(etc,category_list),
	NewCategory = 
		case lists:member(Category, CategoryList) of
			false ->
				RCategory = common_tool:random_element(CategoryList),
				mgeer_role:absend(RoleID,{mod_role2,{gm_set_category,RoleID,RCategory}}),
				?ERROR_MSG("杯具,找不到职业=~w,随机给一个职业=~w",[Category,RCategory]),
				RCategory;
			_  ->
				Category
		end,
	Reward = lists:nth(NewCategory,PropRewardList),
	case is_record(Reward,p_mission_prop) of
		true->
			Func = t_add_prop(RoleID,Reward),
			{[Reward],Func};
		_ ->
			{[],[]}
	end;
do_give_prop_reward(PropRewardFormula, _Category, PropRewardList, _CategoryReward=false) ->
	do_give_prop_reward(PropRewardFormula, PropRewardList).
	
%%@return {PropRewardList,FuncList}
do_give_prop_reward(?MISSION_PROP_REWARD_FORMULA_NO,_) ->
    {[],[]};
do_give_prop_reward(_, []) ->
    {[],[]};
%%@return {PropRewardList,FuncList}
do_give_prop_reward(?MISSION_PROP_REWARD_FORMULA_CHOOSE_ONE, PropRewardList) ->
    Reward = mod_mission_misc:get_choose_prop_reward(DORequestRecord,PropRewardList),
    case is_record(Reward,p_mission_prop) of
        true->
            Func = t_add_prop(RoleID,Reward),
            {[Reward],Func};
        _ ->
            {[],[]}
    end;
do_give_prop_reward(?MISSION_PROP_REWARD_FORMULA_CHOOSE_RANDOM, PropRewardList) ->
    Size = length(PropRewardList),
    case Size>0 of
        true->
            RandomIndex = common_tool:random(1,Size),
            Reward = lists:nth(RandomIndex, PropRewardList),
            Func = t_add_prop(RoleID,Reward),
            {[Reward],Func};
        _ ->
            {[],[]}
    end;
do_give_prop_reward(?MISSION_PROP_REWARD_FORMULA_ALL, PropRewardList) ->
    FuncList = lists:foldl(fun(E,AccIn)-> 
                                   Func = t_add_prop(RoleID,E),
                                   [Func|AccIn]
                           end, [], PropRewardList),
    {PropRewardList,FuncList}.
    

%% ====================================================================
%% Internal functions
%% ====================================================================

%% 执行具体属性奖励
do_give_attr_reward_2(AddExp, AddSilver, AddSilverBind, AddGoldBind,Prestige, Tili) ->
    mod_mission_misc:do_give_attr_reward_2(RoleID,AddExp, AddSilver, AddSilverBind, AddGoldBind,Prestige, Tili).

%%@doc 增加道具
t_add_prop(RoleID,PropReward) when is_record(PropReward,p_mission_prop)->
    #p_mission_prop{prop_id=PropID,prop_type=PropType,prop_num=PropNum,bind=IsBind,color=ColorConfigTmp} = PropReward,
    if
        ColorConfigTmp =:= undefined ->
            ColorConfig = 1;
        true ->
            %%默认是0，这样就按照装备的配置中指定颜色来赠送
            ColorConfig = ColorConfigTmp
    end,
    if
        PropType =:= ?TYPE_EQUIP ->
            Color = ColorConfig,
            {Quality,SubQuality} = mod_refining_tool:get_equip_quality_by_color(Color);
        true ->
            SubQuality = 1,
            Color = ColorConfig,
            Quality = 1
    end,
    CreateInfo = #r_goods_create_info{bind=IsBind,type=PropType, type_id=PropID, start_time=0, end_time=0, 
                                      num=PropNum, color=Color, quality=Quality, sub_quality=SubQuality,
                                      punch_num=0,interface_type=give_qianghua_level},
    {ok,NewGoodsList} = mod_bag:create_goods(RoleID,CreateInfo),
    [Goods|_] = NewGoodsList,
    Func = 
        {func,fun()->  
                      common_misc:update_goods_notify({role, RoleID}, NewGoodsList),
                      common_item_logger:log(RoleID,Goods#p_goods{current_num=PropNum},?LOG_ITEM_TYPE_REN_WU_HUO_DE)
         end},
    Func.



