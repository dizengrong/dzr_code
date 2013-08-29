%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     自动任务的 奖励
%%% @end
%%% Created : 2011-4-20
%%%-------------------------------------------------------------------
-module(mod_mission_auto_reward, [RoleID, MissionID, MissionBaseInfo]).

%%
%% Include files
%%
-include("mission.hrl").

%%
%% Exported Functions
%%
-export([give_auto/1]).

-define(INCREASE_VAL(Val), mod_mission_misc:get_increase_val(Val,MultTimes)).

%%
%% API Functions
%%
%% --------------------------------------------------------------------
%% 给与奖励 返回 p_mission_reward_data
%% -------------------------------------------------------------------- 

%%@return #p_mission_reward_data{}
give_auto(AutoInfo) when is_record(AutoInfo,p_mission_auto) ->
    BigGroup = MissionBaseInfo#mission_base_info.big_group,
    if
        BigGroup =:= 0 ->
            do_give_auto_normal(AutoInfo);
        true ->
            do_give_auto_group(AutoInfo)
    end.


%%普通循环任务的奖励
do_give_auto_normal(AutoInfo) ->
    #p_mission_auto{loop_times=LoopTimes} = AutoInfo,
    BaseRewardData = MissionBaseInfo#mission_base_info.reward_data,
    AttrRewardFormula = BaseRewardData#mission_reward_data.attr_reward_formula,
    
    {PMissionRewardData, FuncList1, LetterCont} = do_give_attr_reward(AttrRewardFormula, BaseRewardData,LoopTimes),
    mod_mission_misc:push_trans_func(RoleID,FuncList1),
    
    send_auto_letter(AutoInfo,LetterCont),
    PMissionRewardData.

%%循环任务分组奖励
%%提醒一下：分组任务的奖励呢，除了prop_reward_formula这个属性值，其他都是读取group_reward.xml的配置
do_give_auto_group(AutoInfo) ->
    #p_mission_auto{loop_times=LoopTimes} = AutoInfo,
    BigGroup = MissionBaseInfo#mission_base_info.big_group,
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    Level = RoleAttr#p_role_attr.level,
    Key = {BigGroup, Level},
    RewardList = mod_mission_data:get_setting(group_reward),
    MathReward = lists:keyfind(Key, 1, RewardList),
    case MathReward of
        {Key, Exp, SilverBind, Prestige,_PropList, Tili}->
            GoldBind=0;
        {Key, Exp, SilverBind, GoldBind,Prestige,_PropList, Tili}->
            next
    end,
    
    %%分组任务，则必须是循环奖励
    BaseRewardDataTmp = MissionBaseInfo#mission_base_info.reward_data,
    BaseRewardData = BaseRewardDataTmp#mission_reward_data{attr_reward_formula=?MISSION_ATTR_REWARD_FORMULA_CALC_ALL_TIMES,
                                                           exp=Exp, 
                                                           prestige=Prestige,
                                                           silver_bind=SilverBind,
                                                           gold_bind=GoldBind, 
                                                           tili = Tili},
    AttrRewardFormula = BaseRewardData#mission_reward_data.attr_reward_formula,
    
    {PMissionRewardData, FuncList1, LetterCont} = do_give_attr_reward(AttrRewardFormula, BaseRewardData,LoopTimes),
    mod_mission_misc:push_trans_func(RoleID, FuncList1),
    
    send_auto_letter(AutoInfo,LetterCont),
    PMissionRewardData.


    
do_give_attr_reward(?MISSION_ATTR_REWARD_FORMULA_NO, _,LoopTimes) ->
    mod_mission_data:set_succ_times(RoleID, MissionBaseInfo, LoopTimes),
    
    {#p_mission_reward_data{},[],[]};
     

do_give_attr_reward(?MISSION_ATTR_REWARD_FORMULA_CALC_ALL_TIMES, BaseRewardData,LoopTimes) ->
    #mission_reward_data{rollback_times=RollBackTimes,
                         exp=AddExp,
                         silver=AddSilver,
                         silver_bind=AddSilverBind,
                         prestige=Prestige, 
                         tili = Tili} = BaseRewardData,
    CurDoneTimes = mod_mission_data:get_succ_times(RoleID, MissionBaseInfo),
    
    {TotalExpSum,TotalSilverSum,TotalSilverBindSum,TotalPrestigeSum, TotalTiliSum, LetterContent1} = 
        lists:foldl(fun(E,AccIn)-> 
                            {ExpSum,SilverSum,SilverBindSum,PrestigeSum,TiliSum, LettAccIn} = AccIn,
                            DoneTimes = CurDoneTimes+E,
                            MultTimes = get_multtimes(DoneTimes,RollBackTimes),
                            
                            ToAddExp = ?INCREASE_VAL(AddExp),
                            ToAddSilver = ?INCREASE_VAL(AddSilver),
                            ToAddSilverBind = ?INCREASE_VAL(AddSilverBind),
                            ToPrestige = ?INCREASE_VAL(Prestige),
                            ToTili = ?INCREASE_VAL(Tili),
                            LetterCont = append_letter_text(LettAccIn,DoneTimes,{ToAddExp,ToAddSilver,ToAddSilverBind,ToPrestige}),
                            
                            {(ExpSum+ToAddExp),
                             (SilverSum+ToAddSilver),(SilverBindSum+ToAddSilverBind),
                             (PrestigeSum + ToPrestige), (TiliSum + ToTili), LetterCont}
                    end, {0,0,0,0,0,""}, lists:seq(1, LoopTimes)),
    LetterContent2 = lists:concat([LetterContent1,"\n\n小提示：循环任务每",RollBackTimes,"次一轮，每轮奖励都是按次数递增的哦！"]),
    mod_mission_data:set_succ_times(RoleID, MissionBaseInfo, LoopTimes),
   
	{R,Func1}=do_give_attr_reward_2(TotalExpSum,TotalSilverSum,TotalSilverBindSum,0,TotalPrestigeSum, TotalTiliSum),
    {R,Func1,LetterContent2}.

%%获取翻倍系数
get_multtimes(CurDoneTimes,RollBackTimes)->
    MultTimes = CurDoneTimes rem RollBackTimes,
    if
        MultTimes>0 ->
            MultTimes;
        true->
            RollBackTimes
    end.   

append_letter_text(LettAccIn,DoneTimes,{ToAddExp,ToAddSilver,ToAddSilverBind,ToPrestige})->
    L1 = lists:concat([LettAccIn,"\n      您委托第",DoneTimes,"次任务，获得"]),
    L2 = case ToAddExp>0 of
             true->
                 lists:concat([L1,ToAddExp,"经验，"]);
             _ ->
                 L1
         end,
    L3 = case ToAddSilver>0 of
             true->
                 lists:concat([L1,ToAddSilver,"钱币，"]);
             _ ->
                 L2
         end,
    L4 = case ToAddSilverBind>0 of
             true->
                 lists:concat([L1,ToAddSilverBind,"铜铜钱，"]);
             _ ->
                 L3
         end,
    L5 = case ToPrestige > 0 of
             true->
                 lists:concat([L1,ToPrestige,"声望，"]);
             _ ->
                 L4
         end,
    L5.
 

%% ====================================================================
%% Internal functions
%% ====================================================================
    
%% 执行具体属性奖励
do_give_attr_reward_2(AddExp,AddSilver,AddSilverBind,AddGoldBind,Prestige, TotalTiliSum)->
	mod_mission_misc:do_give_attr_reward_2(RoleID,AddExp,AddSilver,AddSilverBind,AddGoldBind,Prestige, TotalTiliSum).

%% 发送自动任务的奖励经验
send_auto_letter(AutoInfo,LetterCont)->
    #p_mission_auto{start_time=StartTime,name=Name,total_time=TotalTime} = AutoInfo,
    case LetterCont of
        []->
            ignore;
        _ ->
            case StartTime>0 of
                true->
                    Text = lists:concat(["自动完成：", common_tool:to_list(Name) ,"任务\n",LetterCont]),
                    EndTime = StartTime+TotalTime,
                    Func2 = {func,fun()-> 
                                          common_letter:sys2p(RoleID,Text,"获得委托任务的奖励",[],14,EndTime)
                             end},
                    mod_mission_misc:push_trans_func(RoleID,Func2);
                _ ->
                    ?ERROR_MSG("坑人啊，StartTime=~w,RoleID=~w,MissionBaseInfo=~w",[StartTime,RoleID,MissionBaseInfo])
            end
    end.


