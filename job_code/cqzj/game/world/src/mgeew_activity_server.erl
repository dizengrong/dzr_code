%%% -------------------------------------------------------------------
%%% Author  : markycai
%%% Description : 活动编辑器进程
%%%
%%% Created : 2011-6-30
%%% -------------------------------------------------------------------
-module(mgeew_activity_server).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").

%% --------------------------------------------------------------------
%% External exports
-export([start/0,
         start_link/0,
         check_sum_pay/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% External functions
%% ====================================================================

start()->
    {ok,_} = supervisor:start_child(mgeew_sup,{?MODULE,
                                               {?MODULE,start_link,[]},
                                               permanent,30000, worker,
                                               [?MODULE]}).

start_link()->
    gen_server:start_link({global,?MODULE}, ?MODULE, [], []).

check_sum_pay(StartTime,EndTime,RoleID)->
    MatchHead = #r_pay_log{_='_',role_id = '$1',pay_time='$2',pay_gold='$3'},
    Guard = [{'=:=','$1',RoleID},{'>','$2',StartTime},{'<','$2',EndTime}],
    GoldList=
    case db:dirty_select(?DB_PAY_LOG,[{MatchHead, Guard, ['$3']}]) of
        _GoldList when is_list(_GoldList) ->
            _GoldList;
        _->throw({error,"没有充值数据"})
    end,
    ?DEBUG("GOLDLIST:~w~n",[GoldList]),
    SumGold = lists:sum(GoldList),
    SumGold.


    
%% ====================================================================
%% Server functions
%% ====================================================================

init([]) ->
    %%init_activity_config(),
    {ok, []}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(Reason, State) ->
   ?INFO_MSG("terminate : ~w , reason: ~w", [Reason, State]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%% 排行榜发来榜单数据
do_handle_info({stat_ranking,Info})->
   catch do_stat_ranking(Info);

%% 玩家参加活动行为
do_handle_info({stat_pay,Info})->
    do_stat_pay(Info);

do_handle_info({stat_other,Info})->
    do_stat_other(Info);

do_handle_info({Unique, Module, Method, Record, RoleID, PID, Line}=Info) ->
        case Method of
            ?SPECIAL_ACTIVITY_GET_PRIZE ->
                %% 玩家领取奖励行为  
                do_get_prize(Unique, Module, Method, Record, RoleID, PID, Line);
            ?SPECIAL_ACTIVITY_LIST->
                %% 玩家获取活动列表
                do_get_list(Unique, Module, Method, Record, RoleID, PID, Line);
            ?SPECIAL_ACTIVITY_DETAIL->
                %% 玩家获取活动详情
                do_get_detail(Unique, Module, Method, Record, RoleID, PID, Line);
            _ ->
                ?ERROR_MSG("~ts:~w", ["未知消息", Info])
        end;

do_handle_info({fix_reward,RoleIDList,ActivityKeyList})->
    fix_reward(RoleIDList,ActivityKeyList);

%% 地图返回处理结果
%% 领取累计充值奖励处理结果
do_handle_info({map_get_prize,Info})->
    do_map_get_prize(Info);

do_handle_info(Msg)->
    ?ERROR_MSG("无法识别:~w~n",[Msg]).


%% ================= 服务端计算奖励 ==========================

%%-------------------充值消费类-----------------------------
%% 达成条件后暂时不告诉前端，要玩家刷新面板的时候才告知前端

do_stat_pay({ActivityKey,{RoleID,Element}})->
    case catch check_join_activity(ActivityKey,RoleID,Element) of
        {ok,Reward}->
            update_reward(RoleID,Reward);
        {error,_Reason}->
            ignore;
        {exit,Reward} when is_record(Reward,r_reward_info) ->
            update_reward(RoleID,Reward);
        Msg->
            ?ERROR_MSG("未知数据 Msg:~w~n",[Msg])
    end.
 

%%---------------排行榜类 --------------------------------------

do_stat_ranking({ActivityKey,RankList})->
    {ok,Config} = common_activity:get_config(ActivityKey,ranking_activity),
    ConditionList = Config#r_ranking_activity.condition_prize,
    Reward = #r_reward_info{reward_key=ActivityKey,log_time=common_tool:now()},
    lists:foreach(fun({RoleID,Rank})->
                          NewReward = Reward#r_reward_info{reward_info=Rank},
                         {ok,ConditionID} = common_activity:get_highest_condition(ActivityKey,ConditionList,Rank),
                         if ConditionID > 0 ->
                                update_reward(RoleID,NewReward#r_reward_info{able=ConditionID});
                            true->ignore
                          end
                  end,RankList).


%% ----------------特殊类 ------------------------
do_stat_other({ActivityKey,{RoleID,GoodsInfo}})->
    case catch check_join_activity(ActivityKey,RoleID,GoodsInfo) of
        {ok,Reward}->
            update_reward(RoleID,Reward),
            case get_detail_toc(ActivityKey,RoleID) of
                {ok,RDetail}->
                    common_misc:unicast({role, RoleID},?DEFAULT_UNIQUE, ?SPECIAL_ACTIVITY, ?SPECIAL_ACTIVITY_DETAIL, RDetail);
                Msg->?ERROR_MSG("获取详细信息错误:~w~n",[Msg])
             end;
        {error,Reason}->
            R = #m_special_activity_stat_toc{succ=false, reason=Reason},
            common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?SPECIAL_ACTIVITY,?SPECIAL_ACTIVITY_STAT,R)
    end.

%% ================= 客户端发送行为处理   ======================
%% 包括 1.领奖请求  2.获取活动列表  3.获取详情 4.参与活动
%% --------点击获取奖励------------
do_get_prize(Unique, Module, Method, DataIn, RoleID, _Pid, Line)->
    #m_special_activity_get_prize_tos{activity_key=ActivityKey,condition_id=ConditionID}=DataIn,    
    ?ERROR_MSG("ActivityKey:~w~n",[ActivityKey]),
    case do_get_prize1({ActivityKey,ConditionID,RoleID}) of
        {ok,GoodsList}->
            common_misc:send_to_rolemap(RoleID,{mod_special_activity,{get_prize,{ActivityKey,ConditionID,RoleID,GoodsList}}});
        {error,Reason}->
            R = #m_special_activity_get_prize_toc{succ=false,reason=Reason},
            common_misc:unicast(Line,RoleID, Unique, Module, Method,R)
    end.
%% @spec do_get_prize1({ActivityKey,RoleID})-> {ok,GoodsList}|{error,Reason}
do_get_prize1({ActivityKey,ConditionID,RoleID})->
    case do_get_prize2({ActivityKey,ConditionID,RoleID}) of
        {ok,_}->
            case create_prize(ActivityKey,ConditionID,RoleID) of
                GoodsList when is_list(GoodsList) andalso GoodsList=/=[]->
                    {ok,GoodsList};
                _->{error,"系统错误"}
            end;
        {error,Reason}->
            ?ERROR_MSG("无法领取物品，错误原因：~w~n",[Reason]),
            {error,Reason}
    end.
%% 检查奖励
do_get_prize2({ActivityKey,ConditionID,RoleID})->
    case check_request({ActivityKey,RoleID},common_tool:now()) of
        ok->
            case catch check_get_activity_reward(ActivityKey,ConditionID,RoleID) of
                {ok,_}->
                    {ok,ok};
                _Msg->
                    ?ERROR_MSG("ERROR:~w~n",[_Msg]),
                    {error,"不符合领奖条件"}
            end;
        _->{error,"距离上次请求时限未过"}
    end.    


%% ---------------------打开面板获取列表-----------------------------
do_get_list(Unique, Module, Method, DataIn, RoleID, _Pid, Line)->
    #m_special_activity_list_tos{activity_key=ActivityKey}= DataIn,
    ActivityList = 
        lists:foldr(fun({Key,ConfigFile},Acc)->
                            case catch common_activity:get_config(Key,ConfigFile) of
                                {ok,Config}->
                                    case catch  common_activity:check_config_time(ConfigFile,visible,Config) of
                                        {error,_Reason}->Acc;
                                        _->[Key|Acc]
                                    end;
                                _->Acc
                            end
                    end, [],?ACTIVITY_CONFIG_LIST),
    R=#m_special_activity_list_toc{key_list=ActivityList},
    common_misc:unicast(Line,RoleID, Unique, Module, Method,R),
    case length(ActivityList)>0 of
        true->
            ActivityKey1=
                case lists:member(ActivityKey, ActivityList) of
                    true->ActivityKey;
                    false->
                        [TempKey|_]=ActivityList,
                        TempKey
                end,
            case get_detail_toc(ActivityKey1,RoleID) of
                {ok,RDetail}->
                    common_misc:unicast(Line, RoleID,?DEFAULT_UNIQUE, ?SPECIAL_ACTIVITY, ?SPECIAL_ACTIVITY_DETAIL, RDetail);
                Msg->?ERROR_MSG("获取详细信息错误:~w~n",[Msg])
             end;
        false->
            ignore
    end.

%% -------------获取详细信息------------------------------
do_get_detail(Unique, Module, Method, DataIn, RoleID, _Pid, Line)->
    #m_special_activity_detail_tos{activity_key=ActivityKey}=DataIn, 
    case get_detail_toc(ActivityKey,RoleID) of
        {ok,R}->
            common_misc:unicast(Line, RoleID, Unique, Module, Method, R);
        _->
            R=#m_special_activity_detail_toc{succ=false,reason="无法获取活动详细信息"},
            common_misc:unicast(Line,RoleID, Unique, Module, Method,R)
    end.
%% 获取返回客户端的record

get_detail_toc(ActivityKey,RoleID)->
    case lists:keyfind(ActivityKey, 1, ?ACTIVITY_CONFIG_LIST) of
        false->{error,"找不到配置？"};
        {ActivityKey,FileName}->
            case common_config_dyn:find(FileName,ActivityKey) of
                [Config]->get_detail_toc(FileName,ActivityKey,RoleID,Config);
                []->{error,"找不到配置？"}
            end
    end. 

%% create the fucking toc!!
-define(GET_DETAIL_TOC(FileName,ActivityKey,RoleID,Config,ActivityRecord),
    R=#m_special_activity_detail_toc{activity_key = ActivityKey,
                                     title=Config#ActivityRecord.activity_title,
                                     text=Config#ActivityRecord.activity_text,
                                     activity_start_time=common_activity:convert_time(Config#ActivityRecord.activity_start_time),
                                     activity_end_time=common_activity:convert_time(Config#ActivityRecord.activity_end_time),
                                     reward_start_time = common_activity:convert_time(Config#ActivityRecord.reward_start_time),
                                     reward_end_time = common_activity:convert_time(Config#ActivityRecord.reward_end_time),
                                     condition_list=show_activity_condition_toc(FileName,ActivityKey,Config,RoleID),
                                     limit = Config#ActivityRecord.limit},
    {ok,R}).

-define(SHOW_ACTIVITY_CONDITION_TOC(AcitivityKey,ConditionID,ConditionList),
    lists:map(
      fun(Condition)->
              #p_activity_condition{
                                    condition_id = Condition#r_condition_prize.condition_id,
                                    condition = create_condition_str(ActivityKey,Condition#r_condition_prize.condition), 
                                    multi = Condition#r_condition_prize.multi,
                                    simple_goods = create_simple_goods(Condition#r_condition_prize.prize_goods),
                                    able =  create_client_button_stat(ConditionID,Condition#r_condition_prize.condition_id)
                                   }        
      end,ConditionList)
). 
   
create_simple_goods(PrizeGoodsList)->
    lists:map(fun(PrizeGoods)->
                      #p_activity_prize_goods{
                                              type_id=PrizeGoods#r_prize_goods.type_id,
                                              num=PrizeGoods#r_prize_goods.num,
                                              color=PrizeGoods#r_prize_goods.color,
                                              quality = PrizeGoods#r_prize_goods.quality,
                                              bind= PrizeGoods#r_prize_goods.bind,
                                              last_time=PrizeGoods#r_prize_goods.last_time 
                                             }
              end,PrizeGoodsList).

get_detail_toc(spend_activity,ActivityKey,RoleID,Config)-> 
    ?GET_DETAIL_TOC(spend_activity,ActivityKey,RoleID,Config,r_spend_activity);
get_detail_toc(ranking_activity,ActivityKey,RoleID,Config)->
    ?GET_DETAIL_TOC(ranking_activity,ActivityKey,RoleID,Config,r_ranking_activity);
get_detail_toc(other_activity,ActivityKey,RoleID,Config)->
    ?GET_DETAIL_TOC(other_activity,ActivityKey,RoleID,Config,r_other_activity).
    


%% 消费类活动获取详情
show_activity_condition_toc(spend_activity,ActivityKey,Config,RoleID)->
    StartTime = common_activity:convert_time(Config#r_spend_activity.activity_start_time),
    EndTime = common_activity:convert_time(Config#r_spend_activity.activity_end_time),
    {ok,ConditionID} =
        case get_reward(RoleID,ActivityKey,StartTime,EndTime) of
            {ok,Reward}->
                case catch common_activity:check_config_time(spend_activity,reward,Config) of
                    {ok,_,_}->{ok,Reward#r_reward_info.able};
                    _->{ok,?UNABLE}
                end;
            no_record->{ok,?UNABLE}
        end,
    ConditionList = Config#r_spend_activity.condition_prize,
    ?SHOW_ACTIVITY_CONDITION_TOC(AcitivityKey,ConditionID,ConditionList);   

%% 排行榜类活动获取详情
show_activity_condition_toc(ranking_activity,ActivityKey,Config,RoleID)->
    StartTime = common_activity:convert_time(Config#r_ranking_activity.activity_end_time)-300,    
    EndTime =  common_activity:convert_time(Config#r_ranking_activity.activity_end_time)+300,
    {ok,ConditionID} = 
        case get_reward(RoleID,ActivityKey,StartTime,EndTime) of
            {ok,TmpReward}->
                case catch common_activity:check_config_time(ranking_activity,reward,Config) of
                    {ok,_,_}->{ok,TmpReward#r_reward_info.able};
                    _->{ok,?UNABLE}
                end;
            no_record->{ok,?UNABLE}
        end,
    ConditionList = Config#r_ranking_activity.condition_prize,
    ?SHOW_ACTIVITY_CONDITION_TOC(AcitivityKey,ConditionID,ConditionList);

%% 特殊类活动获取详情
show_activity_condition_toc(other_activity,ActivityKey,Config,RoleID)->
    StartTime = common_activity:convert_time(Config#r_other_activity.activity_start_time),
    EndTime = common_activity:convert_time(Config#r_other_activity.activity_end_time),
    {ok,ConditionID} =
        case get_reward(RoleID,ActivityKey,StartTime,EndTime) of
            {ok,Reward}->
                case catch common_activity:check_config_time(other_activity,reward,Config) of
                    {ok,_,_}->{ok,Reward#r_reward_info.able};
                    _->{ok,?UNABLE}
                end;
            no_record->{ok,?UNABLE}
        end,
    ConditionList = Config#r_other_activity.condition_prize,
    ?SHOW_ACTIVITY_CONDITION_TOC(AcitivityKey,ConditionID,ConditionList).


%% 前端button状态
%% 当玩家有可领奖励的时候  要判断一下，更高的奖励显示未完成，更低的奖励显示不可领
create_client_button_stat(AbleID,CurrentID)->
    if AbleID =:=?UNABLE ->
           ?UNREACH;
       AbleID =:=?DONE->
           ?FINISH;
       AbleID =:=CurrentID->
           ?CANGET;
       AbleID>CurrentID ->
           ?UNREACH;
       AbleID<CurrentID ->
           ?CANNOT;
       true->
           ?CANNOT
    end.
       

%% 拼装一下条件  给前端显示用
create_condition_str(?SPEND_SUM_PAY_KEY,Condition)->
    lists:flatten(io_lib:format("累计充值~w元宝",[Condition]));
create_condition_str(?SPEND_ONCE_PAY_KEY,Condition)->
    lists:flatten(io_lib:format("单笔充值~w元宝",[Condition]));
create_condition_str(?SPEND_USE_GOLD_KEY,Condition)->
    lists:flatten(io_lib:format("累计消费~w元宝",[Condition]));
create_condition_str(?RANK_ROLE_LEVEL_KEY,{StartLevel,EndLevel})->
    case StartLevel=:=EndLevel of
        true->lists:flatten(io_lib:format("第~w名",[StartLevel]));
        false->lists:flatten(io_lib:format("第~w名至第~w名",[StartLevel,EndLevel]))
    end;
create_condition_str(?RANK_EQUIP_REFINING_KEY,{StartLevel,EndLevel})->
    case StartLevel=:=EndLevel of
        true->lists:flatten(io_lib:format("第~w名",[StartLevel]));
        false->lists:flatten(io_lib:format("第~w名至第~w名",[StartLevel,EndLevel]))
    end;
create_condition_str(?RANK_EQUIP_REINFORCE_KEY,{StartLevel,EndLevel})->
    case StartLevel=:=EndLevel of
        true->lists:flatten(io_lib:format("第~w名",[StartLevel]));
        false->lists:flatten(io_lib:format("第~w名至第~w名",[StartLevel,EndLevel]))
    end;
create_condition_str(?RANK_EQUIP_STONE_KEY,{StartLevel,EndLevel})->
    case StartLevel=:=EndLevel of
        true->lists:flatten(io_lib:format("第~w名",[StartLevel]));
        false->lists:flatten(io_lib:format("第~w名至第~w名",[StartLevel,EndLevel]))
    end;
create_condition_str(?RANK_PET_KEY,{StartLevel,EndLevel})->
    case StartLevel=:=EndLevel of
        true->lists:flatten(io_lib:format("第~w名",[StartLevel]));
        false->lists:flatten(io_lib:format("第~w名至第~w名",[StartLevel,EndLevel]))
    end;
create_condition_str(?RANK_YDAY_GIVE_FLOWER_KEY,{StartLevel,EndLevel})->
    case StartLevel=:=EndLevel of
        true->lists:flatten(io_lib:format("第~w名",[StartLevel]));
        false->lists:flatten(io_lib:format("第~w名至第~w名",[StartLevel,EndLevel]))
    end;
create_condition_str(?RANK_YDAY_RECV_FLOWER_KEY,{StartLevel,EndLevel})->
    case StartLevel=:=EndLevel of
        true->lists:flatten(io_lib:format("第~w名",[StartLevel]));
        false->lists:flatten(io_lib:format("第~w名至第~w名",[StartLevel,EndLevel]))
    end;
create_condition_str(?OTHER_EQUIP_REINFORCE_KEY,{EquipID,ReinForceResult})->
    [EquipBaseInfo] = common_config_dyn:find_equip(EquipID),
    EquipName = EquipBaseInfo#p_equip_base_info.equipname,
    Level = ReinForceResult div 10,
    Star = ReinForceResult rem 10,
    lists:flatten(io_lib:format("~s达到~w级~w星",[EquipName,Level,Star])).
    



%%-------------end -----------------------------
%%=============== 处理地图发送结果 ======================
%% 禁止某玩家某活动
ban_reward(Reward,RoleID) when is_record(Reward,r_reward_info)->
    update_reward(RoleID,Reward#r_reward_info{able=?BAN}).

%%领取累计充值结果
%% 如果出错  要禁领！  防刷
do_map_get_prize({succ,RoleID,ActivityKey,ConditionID})->
    case catch get_prize_succ(ActivityKey,ConditionID,RoleID) of
        {ok,Reward}->
            update_reward(RoleID,Reward),
            {ok,R}= get_detail_toc(ActivityKey,RoleID),
            common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?SPECIAL_ACTIVITY,?SPECIAL_ACTIVITY_DETAIL,R);
        {error,Reward}->
            ban_reward(Reward,RoleID),
            ?ERROR_MSG("居然错了！检查！Reward:~w~n",[Reward]),
            R=#m_special_activity_get_prize_toc{succ=false,reason="领取奖励错误"},
            common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE, ?SPECIAL_ACTIVITY, ?SPECIAL_ACTIVITY_GET_PRIZE, R);
        Msg->
            Reward=#r_reward_info{reward_key=ActivityKey,able=?BAN},
            ban_reward(Reward,RoleID),
            ?ERROR_MSG("可能是代码问题！检查！~w~n",[Msg]),
            R=#m_special_activity_get_prize_toc{succ=false,reason="领取奖励错误"},
            common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE, ?SPECIAL_ACTIVITY, ?SPECIAL_ACTIVITY_GET_PRIZE, R)
    end,
    erlang:erase({ActivityKey,RoleID});
do_map_get_prize({fail,RoleID,ActivityKey,_ConditionID})->
    erlang:erase({ActivityKey,RoleID}).

%%---------------领取成功处理 ----------------------------

get_prize_succ(ActivityKey,ConditionID,RoleID)->
     %%配置文件
    {ok,FileName}=common_activity:get_config_filename(ActivityKey),
    {ok,Config} =common_activity:get_config(ActivityKey,FileName),
    get_type_prize_succ(FileName,ActivityKey,Config,ConditionID,RoleID).


get_type_prize_succ(spend_activity,ActivityKey,Config,ConditionID,RoleID)->
    StartTime = common_activity:convert_time(Config#r_spend_activity.activity_start_time),
    EndTime = common_activity:convert_time(Config#r_spend_activity.activity_end_time),
    Limit = Config#r_spend_activity.limit,
    ConditionList = Config#r_spend_activity.condition_prize,
    Condition =
        case lists:keyfind(ConditionID, 2, ConditionList) of
            TmpCondition when is_record(TmpCondition,r_condition_prize)->
                TmpCondition;
            false->throw({error,"地图返回数据有误，找不到配置！"})
        end,
    Reward = 
        case get_reward(RoleID,ActivityKey,StartTime,EndTime) of
            no_record->
                throw({error,"地图返回领取奖励结果有误，请检查！！"});
            {ok,TmpReward}->
                TmpReward
        end,
    %%获取新的得奖信息
    {ok,NewReward}=reflash_reward(ActivityKey,Reward,Condition),
    case Limit of
        ?LIMIT->
            throw({ok,NewReward});
        ?UNLIMIT->
            next
    end,
    {Arg}=NewReward#r_reward_info.reward_info,
    {ok,NewConditionID} =common_activity:get_highest_condition(ActivityKey,ConditionList,Arg),
    {ok,NewReward#r_reward_info{able = NewConditionID}};

get_type_prize_succ(ranking_activity,ActivityKey,Config,_ConditionID,RoleID)->
    ActStartTime= common_activity:convert_time(Config#r_ranking_activity.activity_end_time)-300,
    ActEndTime = common_activity:convert_time(Config#r_ranking_activity.activity_end_time)+300,
    case get_reward(RoleID,ActivityKey,ActStartTime,ActEndTime) of
        no_record->
            {error,"地图返回领取奖励结果有误，请检查！！"};
        {ok,TmpReward}->
            {ok,TmpReward#r_reward_info{recv_times=1,able=?DONE}}
    end;

get_type_prize_succ(other_activity,ActivityKey,Config,_ConditionID,RoleID)->
    StartTime = common_activity:convert_time(Config#r_other_activity.activity_start_time),
    EndTime = common_activity:convert_time(Config#r_other_activity.activity_end_time),
    
    case get_reward(RoleID,ActivityKey,StartTime,EndTime) of
        no_record->
            throw({error,"地图返回领取奖励结果有误，请检查！！"});
        {ok,TmpReward}->
            RecvTime = TmpReward#r_reward_info.recv_times,
            {ok,TmpReward#r_reward_info{recv_times=RecvTime+1,able=?UNABLE}}
    end.


%% 更新得奖记录
reflash_reward(?SPEND_SUM_PAY_KEY,Reward,Condition)->
    NewRecvTimes = Reward#r_reward_info.recv_times+1,
    {SumGold} = Reward#r_reward_info.reward_info,
    GoalGold = Condition#r_condition_prize.condition,
    {ok,Reward#r_reward_info{recv_times=NewRecvTimes,
                                able=?DONE,
                                reward_info={SumGold-GoalGold}}};
reflash_reward(?SPEND_ONCE_PAY_KEY,Reward,_Condition)->
    NewRecvTimes = Reward#r_reward_info.recv_times+1,
    {ok, Reward#r_reward_info{recv_times=NewRecvTimes,
                                able=?DONE,
                                reward_info={0}}};
reflash_reward(?SPEND_USE_GOLD_KEY,Reward,Condition)->
    NewRecvTimes = Reward#r_reward_info.recv_times+1,
    {SumGold} = Reward#r_reward_info.reward_info,
    GoalGold = Condition#r_condition_prize.condition,
    {ok, Reward#r_reward_info{recv_times=NewRecvTimes,
                                able=?DONE,
                                reward_info={SumGold-GoalGold}}}.




%% 获取那个奖励要判断啊  就只有达成条件的检查不同
check_get_activity_reward(ActivityKey,ConditionID,RoleID)->
    %%配置文件
    {ok,FileName}=common_activity:get_config_filename(ActivityKey),
    {ok,Config} =common_activity:get_config(ActivityKey,FileName),
    check_type_activity_reward(FileName,ActivityKey,Config,ConditionID,RoleID).

check_type_activity_reward(spend_activity,ActivityKey,Config,ConditionID,RoleID)->
    %%是否到领取时间
    {ok,_,_} = common_activity:check_config_time(spend_activity,reward,Config),   
    ActStartTime= common_activity:convert_time(Config#r_spend_activity.activity_start_time),
    ActEndTime = common_activity:convert_time(Config#r_spend_activity.activity_end_time),
    %%是否有记录
    NewReward = 
    case get_reward(RoleID,ActivityKey,ActStartTime,ActEndTime) of
        no_record ->
            throw({error,"数据库找不到数据，悲剧啊"});
        {ok,Reward}->
           Reward
    end,
    case NewReward#r_reward_info.able =:=?BAN of
        true->throw({error,"该用户被禁止领取物品，请检查"});
        false->next
    end,
    %%是否已达成活动
    case NewReward#r_reward_info.able =:=?DONE andalso Config#r_spend_activity.limit=:=?LIMIT of
        true->throw({error,"达到领取次数上限"});
        false->next
    end,
    %% 是否条件满足
    ConditionList = Config#r_spend_activity.condition_prize,
    Condition =
    case lists:keyfind(ConditionID, 2, ConditionList) of
        _Condition when is_record(_Condition,r_condition_prize)->
            _Condition;
        false->throw({error,"找不到配置"})
    end,
    {Arg}=NewReward#r_reward_info.reward_info,
    case common_activity:check_config_condition(ActivityKey,Condition,Arg) of
        true->next;
        false->throw({error,"不满足奖励条件"})
    end,
    %% 是否领取过
    case NewReward#r_reward_info.recv_times>0 of
        true->next;
        false->throw({ok,NewReward#r_reward_info{able=ConditionID}})
    end,
    %% 是否无限  
    case Config#r_spend_activity.limit of 
        ?UNLIMIT->throw({ok,NewReward#r_reward_info{able=ConditionID}});
        _->throw({error,"达到领取次数上限"})
    end;

check_type_activity_reward(ranking_activity,ActivityKey,Config,ConditionID,RoleID)->
    %%是否到领取时间
    {ok,_,_} = common_activity:check_config_time(ranking_activity,reward,Config), 
    %%是否有记录
    ActStartTime= common_activity:convert_time(Config#r_ranking_activity.activity_end_time)-300,
    ActEndTime = common_activity:convert_time(Config#r_ranking_activity.activity_end_time)+300,
    NewReward = 
    case get_reward(RoleID,ActivityKey,ActStartTime,ActEndTime) of
        no_record ->
            throw({error,"数据库找不到数据，悲剧啊"});
        {ok,Reward}->
           Reward
    end,
    case NewReward#r_reward_info.able =:=?BAN of
        true->throw({error,"该用户被禁止领取物品，请检查"});
        false->next
    end,
    %%是否已达成活动
    case NewReward#r_reward_info.able =:=?DONE of
        true->throw({error,"达到领取次数上限"});
        false->next
    end,
    %% 是否条件满足
    ConditionList = Config#r_ranking_activity.condition_prize,
    Condition = 
    case lists:keyfind(ConditionID, 2, ConditionList) of
        _Condition when is_record(_Condition,r_condition_prize)->
            _Condition;
        false->throw({error,"找不到配置"})
    end,
    Rank=NewReward#r_reward_info.reward_info,
    case common_activity:check_config_condition(ActivityKey,Condition,Rank) of
        true->{ok,NewReward#r_reward_info{able=ConditionID}};
        false->{error,"不满足条件"}
    end;

check_type_activity_reward(other_activity,ActivityKey,Config,_ConditionID,RoleID)->
    %%是否到领取时间
    {ok,_,_} = common_activity:check_config_time(other_activity,reward,Config),
    ActStartTime = common_activity:convert_time(Config#r_other_activity.activity_start_time),
    ActEndTime = common_activity:convert_time(Config#r_other_activity.activity_end_time),
    %%是否有记录
    NewReward = 
    case get_reward(RoleID,ActivityKey,ActStartTime,ActEndTime) of
        no_record ->
            throw({error,"数据库找不到数据，悲剧啊"});
        {ok,Reward}->
           Reward
    end,
    case NewReward#r_reward_info.able >0 of
        true->{ok,ok};
        false->{error,"不满足领取条件"}
    end.


%% 
%% 不同活动获取的reward不同
get_current_reward(?SPEND_SUM_PAY_KEY,RoleID,StartTime,EndTime,Gold)->
    case get_reward(RoleID,?SPEND_SUM_PAY_KEY,StartTime,EndTime) of
        no_record->
            #r_reward_info{reward_key = ?SPEND_SUM_PAY_KEY,
                      log_time = common_tool:now(),
                      reward_info={Gold},
                      recv_times=0,
                      able=?UNABLE};
        {ok,OldReward}->
            {OldSumGold}=OldReward#r_reward_info.reward_info,
            OldReward#r_reward_info{reward_info={OldSumGold+Gold},
                               log_time = common_tool:now()}
    end;
get_current_reward(?SPEND_ONCE_PAY_KEY,RoleID,StartTime,EndTime,Gold)->
    case get_reward(RoleID,?SPEND_ONCE_PAY_KEY,StartTime,EndTime) of
        no_record->
            #r_reward_info{reward_key = ?SPEND_ONCE_PAY_KEY,
                      log_time = common_tool:now(),
                      reward_info={Gold},
                      recv_times=0,
                      able=?UNABLE};
        {ok,Reward}->
            {OldGold}=Reward#r_reward_info.reward_info,
            MaxGold = if OldGold>Gold -> OldGold; 
                         true->Gold
                      end,
            Reward#r_reward_info{reward_info={MaxGold},
                            log_time = common_tool:now()}
    end;
get_current_reward(?SPEND_USE_GOLD_KEY,RoleID,StartTime,EndTime,Gold)->
    case get_reward(RoleID,?SPEND_USE_GOLD_KEY,StartTime,EndTime) of
        no_record->
            #r_reward_info{reward_key = ?SPEND_USE_GOLD_KEY,
                      log_time = common_tool:now(),
                      reward_info={Gold},
                      recv_times=0,
                      able=?UNABLE};
        {ok,OldReward}->
            {OldSumGold}=OldReward#r_reward_info.reward_info,
            OldReward#r_reward_info{reward_info={OldSumGold+Gold},
                                log_time = common_tool:now()}
    end.
%% -------------------------------------------------------------


%% ------检查累计充值活动-------
%% @spec check_join_activity(Key:int(),RoleID:int(),AddGold:int())->
%%               {ok,Reward}|{error,Reason}|{exit,Reward}
check_join_activity(?SPEND_SUM_PAY_KEY,RoleID,AddGold)->
    %%配置文件
    {ok,ConfigName} = common_activity:get_config_filename(?SPEND_SUM_PAY_KEY),
    {ok,Config} = common_activity:get_config(?SPEND_SUM_PAY_KEY,ConfigName),
    {ok,StartTime,EndTime} = common_activity:check_config_time(ConfigName,activity,Config),

    %%是否有记录
    NewReward = get_current_reward(?SPEND_SUM_PAY_KEY,RoleID,StartTime,EndTime,AddGold),
    %%是否已达成活动且活动是有次数限制的
    case NewReward#r_reward_info.able =:=?DONE andalso Config#r_spend_activity.limit=:=?LIMIT of
        true->throw({exit,NewReward});
        false->next
    end,
    case NewReward#r_reward_info.able=:=?BAN of
        true->throw({exit,NewReward});
        false->next
    end,
    {Arg}=NewReward#r_reward_info.reward_info,
    %% 是否满足金额
    ConditionList = Config#r_spend_activity.condition_prize,
    {ok,ConditionID}=common_activity:get_highest_condition(?SPEND_SUM_PAY_KEY,ConditionList,Arg),
    if is_integer(ConditionID) andalso ConditionID>0 ->
           {ok,NewReward#r_reward_info{able=ConditionID}};
       true->
           {exit,NewReward#r_reward_info{able=?UNABLE}}
    end;

%% ------- 检查累计消费 ---------------
check_join_activity(?SPEND_USE_GOLD_KEY,RoleID,{Bind,UnBind})->
   %% 是否充值
    case Bind>0 orelse UnBind > 0 of
        true->
            next;
        false->
            throw({error,"非消费记录"})
    end,
    check_join_activity(?SPEND_USE_GOLD_KEY,RoleID,Bind+UnBind);
check_join_activity(?SPEND_USE_GOLD_KEY,RoleID,Gold)->
    %%配置文件
    {ok,ConfigName} = common_activity:get_config_filename(?SPEND_USE_GOLD_KEY),
    {ok,Config} = common_activity:get_config(?SPEND_USE_GOLD_KEY,ConfigName),
    {ok,StartTime,EndTime} = common_activity:check_config_time(ConfigName,activity,Config),
    NewReward = get_current_reward(?SPEND_USE_GOLD_KEY,RoleID,StartTime,EndTime,Gold),
    %%是否已达成活动且活动是有次数限制的
    case NewReward#r_reward_info.able =:=?DONE andalso Config#r_spend_activity.limit=:=?LIMIT of
        true->throw({exit,NewReward});
        false->next
    end,
    case NewReward#r_reward_info.able=:=?BAN of
        true->throw({exit,NewReward});
        false->next
    end,
    {Arg}=NewReward#r_reward_info.reward_info,
    %% 是否满足金额
    ConditionList = Config#r_spend_activity.condition_prize,
    {ok,ConditionID}=common_activity:get_highest_condition(?SPEND_USE_GOLD_KEY,ConditionList,Arg),
    if is_integer(ConditionID) andalso ConditionID>0 ->
           {ok,NewReward#r_reward_info{able=ConditionID}};
       true->
           {exit,NewReward#r_reward_info{able=?UNABLE}}
    end;

%% ------检查单笔充值最高----------
check_join_activity(?SPEND_ONCE_PAY_KEY,RoleID,Gold)->
    %%配置文件
    {ok,ConfigName} = common_activity:get_config_filename(?SPEND_ONCE_PAY_KEY),
    {ok,Config} = common_activity:get_config(?SPEND_ONCE_PAY_KEY,ConfigName),
    {ok,StartTime,EndTime} = common_activity:check_config_time(ConfigName,activity,Config),
    %%是否够钱    
    ConditionList = Config#r_spend_activity.condition_prize,
    %%这个id也许给以后做前端缓存用
    ConditionID = 
        lists:foldl(
          fun(Condition,Acc)-> 
                  if Acc =:= 0 andalso
                         Gold>=Condition#r_condition_prize.condition ->
                         Condition#r_condition_prize.condition_id;
                     true->Acc
                  end
          end,0,ConditionList),
    if is_integer(ConditionID) andalso ConditionID>0 ->
           next;
       true->
           throw({error,"金额未够"})
    end,
    %%是否有记录    
    NewReward = get_current_reward(?SPEND_ONCE_PAY_KEY,RoleID,StartTime,EndTime,Gold),
    %%是否已达成活动
    case NewReward#r_reward_info.able =:=?DONE andalso Config#r_spend_activity.limit=:=?LIMIT of
        true->throw({exit,NewReward});
        false->next
    end,
    case NewReward#r_reward_info.able=:=?BAN of
        true->{exit,NewReward};
        false->{ok,NewReward#r_reward_info{able=ConditionID}}
    end;

%% ------检查指定强化 ---------------
check_join_activity(?OTHER_EQUIP_REINFORCE_KEY,RoleID,GoodsInfo)->
    %% 配置文件
    {ok,Config} = common_activity:get_config(?OTHER_EQUIP_REINFORCE_KEY,other_activity),
    {ok,StartTime,EndTime} = common_activity:check_config_time(other_activity,activity,Config),
    %%是否绑定
    case GoodsInfo#p_goods.bind of
        true->next;
        false->throw({error,"绑定装备才能参与活动"})
    end,
    ConditionList = Config#r_other_activity.condition_prize,
    #p_goods{id=GoodsID,typeid=TypeID,reinforce_result=ReinForceResult} = GoodsInfo,
    {ok,ConditionID} = common_activity:get_highest_condition(?OTHER_EQUIP_REINFORCE_KEY,ConditionList,{TypeID,ReinForceResult}),
    case ConditionID>0 of
        true->next;
        false->throw({error,"装备不够条件"})
    end,
    %% 检查现在数据
    {ok,Reward} = 
    case get_reward(RoleID,?OTHER_EQUIP_REINFORCE_KEY,StartTime,EndTime) of
        no_record->
            NewReward =
            #r_reward_info{reward_key = ?OTHER_EQUIP_REINFORCE_KEY,
                      log_time = common_tool:now(),
                      reward_info=[],
                      recv_times=0,
                      able=0},
            throw({ok,NewReward});
        {ok,_Reward}->
            {ok,_Reward}
    end,
    case Reward#r_reward_info.able>0 of
        true->throw({error,"请先领取完奖励再参与活动"});
        false->next
    end,
    case Reward#r_reward_info.able=:=?DONE of
        true->throw({error,"活动已完成"});
        false->next
    end,
    case Reward#r_reward_info.able=:=?BAN of
        true->throw({error,"您的活动出现异常，请联系管理员"});
        false->next
    end,
    %% 当物品是否已参与
    InfoList = Reward#r_reward_info.reward_info,
    case lists:member(GoodsID, InfoList) of
         true->throw({error,"装备已参与活动"});
         false->next
    end,
    {ok,Reward#r_reward_info{reward_info=[GoodsID|InfoList],able=ConditionID}};



%% -----------指定镶嵌---------
check_join_activity(?OTHER_EQUIP_STONE_KEY,RoleID,GoodsInfo)->
    %% 配置文件
    {ok,Config} = common_activity:get_config(?OTHER_EQUIP_STONE_KEY,other_activity),
    {ok,StartTime,EndTime} = common_activity:check_config_time(other_activity,activity,Config),
    %%是否绑定
    case GoodsInfo#p_goods.bind of
        true->next;
        false->throw({error,"绑定装备才能参与活动"})
    end,
    ConditionList = Config#r_other_activity.condition_prize,
    #p_goods{id=GoodsID,typeid=TypeID,stones=Stones} = GoodsInfo,
    
    {ok,ConditionID} = common_activity:get_highest_condition(?OTHER_EQUIP_STONE_KEY,ConditionList,{TypeID,length(Stones)}),
    case ConditionID>0 of
        true->next;
        false->throw({error,"装备不够条件"})
    end,
    %% 检查现在数据
    {ok,Reward} = 
    case get_reward(RoleID,?OTHER_EQUIP_STONE_KEY,StartTime,EndTime) of
        no_record->
            NewReward =
            #r_reward_info{reward_key = ?OTHER_EQUIP_STONE_KEY,
                      log_time = common_tool:now(),
                      reward_info=[],
                      recv_times=0,
                      able=0},
            throw({ok,NewReward});
        {ok,_Reward}->
            {ok,_Reward}
    end,
    case Reward#r_reward_info.able>0 of
        true->throw({error,"请先领取完奖励再参与活动"});
        false->next
    end,
    case Reward#r_reward_info.able=:=?DONE of
        true->throw({error,"活动已完成"});
        false->next
    end,
    case Reward#r_reward_info.able=:=?BAN of
        true->throw({error,"您的活动出现异常，请联系管理员"});
        false->next
    end,
    %% 当物品是否已参与
    InfoList = Reward#r_reward_info.reward_info,
    case lists:member(GoodsID, InfoList) of
         true->throw({error,"装备已参与活动"});
         false->next
    end,
    {ok,Reward#r_reward_info{reward_info=[GoodsID|InfoList],able=ConditionID}};

check_join_activity(Msg,RoleID,Msg)->
    ?ERROR_MSG("跳过检查条件Msg:~w,RoleID:~w,Msg:~w~n",[Msg,RoleID,Msg]),
    {error,"检查条件被跳过"}.



%%=============== 数据库操作 ==============================
get_reward(RoleID,ActivityKey,StartTime,EndTime)->
    case db:dirty_read(?DB_ACTIVITY_REWARD,RoleID) of
        [ActReward]->
            case lists:keyfind(ActivityKey, 2, ActReward#r_activity_reward.reward_list) of
                Reward when erlang:is_record(Reward,r_reward_info)->
                    case StartTime<Reward#r_reward_info.log_time 
                        andalso Reward#r_reward_info.log_time < EndTime of
                        true->{ok,Reward};
                        false->no_record
                    end;
                _->no_record
            end;
        _-> no_record
    end.

update_reward(RoleID,Reward)->
    NewRewardList = 
    case db:dirty_read(?DB_ACTIVITY_REWARD,RoleID) of
        [ActReward]->
            RewardList= ActReward#r_activity_reward.reward_list,
            ActivityKey=Reward#r_reward_info.reward_key,
            case lists:keyfind(ActivityKey, 2, RewardList) of
                OldReward when is_record(OldReward,r_reward_info)->
                    [Reward|lists:delete(OldReward, RewardList)];
                _->[Reward|RewardList]
            end;
        _->[Reward]
    end,
    db:dirty_write(?DB_ACTIVITY_REWARD,#r_activity_reward{role_id=RoleID,reward_list=NewRewardList}).


fix_reward(_RoleIDList,_ActivityKeyList)->
    shit.
%%======================  创建物品 =============================


-define(GET_CONFIG_CONDITIONLIST(Config,ConfigRecord),
        Config#ConfigRecord.condition_prize).
get_config_conditionlist(ranking_activity,Config)->
    ?GET_CONFIG_CONDITIONLIST(Config,r_ranking_activity);
get_config_conditionlist(spend_activity,Config)->
    ?GET_CONFIG_CONDITIONLIST(Config,r_spend_activity);
get_config_conditionlist(other_activity,Config)->
    ?GET_CONFIG_CONDITIONLIST(Config,r_other_activity).

create_prize(ActivityKey,ConditionID,RoleID)->
    {ok,ConfigName} = common_activity:get_config_filename(ActivityKey),
    {ok,Config} = common_activity:get_config(ActivityKey,ConfigName),
    ConditionList =get_config_conditionlist(ConfigName,Config),
    PrizeGoodsList =
        case lists:keyfind(ConditionID, 2, ConditionList) of
            Condition when is_record(Condition,r_condition_prize) ->
                Condition#r_condition_prize.prize_goods;
            false->
                []
        end,
    case is_list(PrizeGoodsList) andalso length(PrizeGoodsList)>0 of
        true->
            lists:foldl(
              fun(PrizeGoods,Acc)->
                      case create_goods(RoleID,PrizeGoods) of
                          {ok,OldGoodsList}->
                              lists:foldl(
                                fun(G,Acc1)->
                                        [G#p_goods{id=1,bagposition=1,bagid=9999}|Acc1]
                                end, Acc, OldGoodsList);
                          {error,Reason}->
                              ?ERROR_MSG("创建物品失败：Reason:~w,PrizeGoods:~w~n",[Reason,PrizeGoods]),
                              Acc
                      end
            end, [], PrizeGoodsList);
        false->
            {error,"没有奖励列表"}
    end.

create_goods(RoleID,PrizeGoods)->
    #r_prize_goods{type_id=TypeID,type=Type,num=Num,bind=Bind,color = Color,quality=Quality,last_time =LastTime}=PrizeGoods,
    {StartTime,EndTime} =  
        case LastTime of
            0 ->{0,0};
            _ ->
                TmpTime= common_tool:now(),
                {TmpTime,TmpTime+LastTime}
        end,
    case Type of
        ?TYPE_ITEM ->
            Info = #r_item_create_info{role_id=RoleID, bag_id=0,  num=Num, typeid=TypeID, bind=Bind,
                                       start_time=StartTime, end_time=EndTime},
            common_bag2:create_item(Info);
        ?TYPE_STONE ->
            Info = #r_stone_create_info{role_id=RoleID, bag_id=0,  num=Num, typeid=TypeID, bind=Bind,
                                        start_time=StartTime, end_time=EndTime},
            common_bag2:creat_stone(Info);
        ?TYPE_EQUIP ->
            %%equip 需要加颜色  否则默认color=0会报错，没有color=0的装备
            Info = #r_equip_create_info{role_id=RoleID, bag_id=0,  num=Num, typeid=TypeID, bind=Bind,
                                        start_time=StartTime, end_time=EndTime,color=Color,quality=Quality},
            common_bag2:creat_equip_without_expand(Info)
    end.
    
%% ========================= 进程字典 ===========================
%% 用于临时记录领取物品请求 防刷
check_request(Key,Value)->
    case get(Key) of
        Time when is_integer(Time)->
            case Value-Time>?REQUEST_LAST_TIME of
                true->put(Key,Value),ok;
                false->waiting
            end;
        _->put(Key,Value),ok
    end.


