%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     节日活动期间的地图Hook接口
%%% @end
%%% Created : 2011-01-10
%%%-------------------------------------------------------------------
-module(hook_activity_map).

-export([hook_collect/1,hook_hero_fb/1,hook_mission/2]).
-export([hook_ybc_person/1]).
-export([hook_monster_drop/3]).
-export([hook_monster_dead_exp/2]).

-include("mgeem.hrl").


%%%===================================================================
%%% Macro
%%%===================================================================
-define(DO_HOOK_ACTIVITY_FUN(ConfigKey,ActKeyList,Fun),
    case common_config_dyn:find(activity_define,ConfigKey) of
        []-> 
            [];
        [ActKeyList] ->
            lists:foldl(fun(ActKey,Acc)-> 
                                             case Fun of
                                                 []->Acc;
                                                 List-> lists:concat([List,Acc])
                                             end 
                                     end, [], ActKeyList)
    end).

-define(DO_HOOK_PROP_AWARD(ConfigKey,IsUpdateRoleGoods),
        %% 注意，该API只会获取配置项中的第一个匹配record
        case common_activity:get_activity_config_by_name(ConfigKey) of
            [AwardConf] when is_record(AwardConf,r_activity_common_award)->
                do_common_prop_award(RoleID,AwardConf,IsUpdateRoleGoods);
            _ ->
                []
        end ).


%%%===================================================================
%%% API
%%%===================================================================

%%@doc 活动期间的大明英雄副本的道具奖励
hook_hero_fb(RoleID)->
    ?DO_HOOK_PROP_AWARD( activity_hero_fb,true ).

%%@doc 活动期间的任务道具奖励
hook_mission(RoleID,?ACTIVITY_TASK_SHOUBIAN)->
    ?DO_HOOK_PROP_AWARD( activity_shoubian,true );
hook_mission(RoleID,?ACTIVITY_TASK_SPY)->
    ?DO_HOOK_PROP_AWARD( activity_spy,true );
hook_mission(_RoleID,_)->
    ignore.

%%@doc 活动期间的采集道具奖励
hook_collect(RoleID)->
    ?DO_HOOK_PROP_AWARD( activity_collect,false ).

%%@doc 活动期间的个人拉镖的道具奖励
hook_ybc_person(RoleID)->
    case common_activity:get_activity_config_by_name(activity_ybc_person) of
        [ActivityRecord]->
            #r_activity_person_ybc_award{award_prop_list=AwardPropList} = ActivityRecord,
            hook_ybc_person_2(RoleID,AwardPropList);
        _ ->
            ignore
    end.
hook_ybc_person_2(_RoleID,undefined)->
    ignore;
hook_ybc_person_2(_RoleID,[])->
    ignore;
hook_ybc_person_2(RoleID,AwardPropList)->
    try
      GoodsList = do_add_prop(RoleID,AwardPropList),
      do_update_role_goods(RoleID,GoodsList)
    catch
        _:Reason->
          ?ERROR_MSG_STACK("hook_ybc_person error",Reason)
    end.


%%@doc 活动期间的打怪奖励
hook_monster_drop(RoleID,MonsterTypeID,EnergyIndex)->
    try
        GoodsList1 = ?DO_HOOK_ACTIVITY_FUN(monster_award_with_energy,ActKeyList1,do_hook_monster_drop_1(RoleID,MonsterTypeID,EnergyIndex,ActKey)),
        GoodsList2 = ?DO_HOOK_ACTIVITY_FUN(monster_award_one,ActKeyList2,do_hook_monster_drop_2(RoleID,MonsterTypeID,ActKey)),
        GoodsList3 = ?DO_HOOK_ACTIVITY_FUN(monster_award_multi,ActKeyList3,do_hook_monster_drop_3(RoleID,MonsterTypeID,ActKey)),
        
        GoodsList = lists:concat([GoodsList1,GoodsList2,GoodsList3]),
        do_update_role_goods(RoleID,GoodsList)
    catch
        _:Reason->
            ?ERROR_MSG_STACK("activity hook_monster_drop error",Reason)
    end.



%% @doc 活动期间怪物经验奖励
hook_monster_dead_exp(MonsterType, GainExp) ->
    try
      %% 宗族经验奖励
      case common_activity:get_activity_config_by_name(activity_family_boss) of
          [ActivityRecord] when is_record(ActivityRecord,r_activity_family_award)->
              do_hook_family_boss(MonsterType,GainExp,ActivityRecord);
          _ ->
              GainExp
      end
    %% 此处暂时不处理普通怪物经验奖励!
    catch
        _:Reason ->
          ?ERROR_MSG_STACK("activity hook_monster_dead error", Reason)
    end.
    
%% ====================================================================
%% Internal functions
%% ====================================================================

%% 处理宗族BOSS的奖励
do_hook_family_boss(MonsterType,GainExp,ActivityRecord)->
    %% 1.判断活动配置
    case ActivityRecord of
        #r_activity_family_award{monster_list=MonsterTypeIDList,award_expr_times=Times} when (Times>=1)-> 
            case lists:member(MonsterType, MonsterTypeIDList) of
                true->
                    %%?INFO_MSG("Times=~w",[Times]),
                    GainExp*Times;
                _ ->
                    GainExp
            end;
        _ ->
            GainExp
    end.


%%@doc 更新玩家的奖励物品列表
do_update_role_goods(RoleID,GoodsList) when is_list(GoodsList)->
    case GoodsList of
        []-> ignore;
        _ ->
            lists:foreach(fun(E)-> 
                              #p_goods{name=Name,current_colour=Color}=E,
                              GoodsName = common_misc:format_goods_name_colour(Color,Name),
                              Tip = common_misc:format_lang(<<"恭喜你获得~ts">>, [GoodsName]),
                              common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, Tip)
                          end, GoodsList),
            common_misc:update_goods_notify({role,RoleID}, GoodsList)
    end.

%%处理通用的道具奖励
do_common_prop_award(RoleID,#r_activity_common_award{award_rate=AwardRate}=AwardConf,IsUpdateRoleGoods) 
  when is_boolean(IsUpdateRoleGoods)->
    if
        AwardRate =:= undefined->
            [];
        AwardRate =:= 0 ->
            [];
        true->
            case common_tool:random(1,100) > AwardRate of
                true->
                    [];
                _ ->
                    #r_activity_common_award{award_item_id=ItemTypeID,award_num=Num,bind_type=Bind}=AwardConf,
                    PropList = [#r_award_prop{item_id=ItemTypeID,num=Num,bind=Bind}],
                    GoodsList = do_add_prop(RoleID,PropList),
                    case IsUpdateRoleGoods of
                        true->
                            do_update_role_goods(RoleID,GoodsList);
                        _ ->
                            GoodsList
                    end
            end
    end.

%% 1.怪物的掉落奖励，只掉一种道具（需判断玩家精力值的怪物奖励）
do_hook_monster_drop_1(RoleID,MonsterTypeID,EnergyIndex,ActKey)->
    case common_activity:get_activity_config(ActKey) of
        [#r_activity_monster_award_one{monster_list=MonsterTypeIDList,award_rate=AwardRate}=AwardConf]-> 
            case AwardRate >= common_tool:random(1,100) andalso lists:member(MonsterTypeID, MonsterTypeIDList) of 
                true->
                    case EnergyIndex=:=1 of
                        true->
                            do_hook_monster_drop_item(RoleID,AwardConf);
                        _ ->
                            ?ERROR_MSG("EnergyIndex=~w",[EnergyIndex]),
                            []
                    end;
                _ ->
                    []
            end;
        _ ->
            []
    end.

%% 2.怪物的掉落奖励，只掉一种道具（不判断玩家精力值的怪物奖励）
do_hook_monster_drop_2(RoleID,MonsterTypeID,ActKey)->
    case common_activity:get_activity_config_list(ActKey) of
        AwardConfList when is_list(AwardConfList) andalso length(AwardConfList)>0 ->
            MatchConf = match_award_one_config(AwardConfList,MonsterTypeID),
            case MatchConf of
                #r_activity_monster_award_one{award_rate=AwardRate}->
                    case AwardRate >= common_tool:random(1,100) of 
                        true->
                            do_hook_monster_drop_item(RoleID,MatchConf);
                        _ ->
                            []
                    end;
                _ ->
                    []
            end;
        _Other ->
            []
    end.

%% 3.怪物的掉落奖励，可以掉落多种（不判断玩家精力值的怪物奖励）
do_hook_monster_drop_3(RoleID,MonsterTypeID,ActKey)->
    case common_activity:get_activity_config_list(ActKey) of
        AwardConfList when is_list(AwardConfList) andalso length(AwardConfList)>0 ->
            MatchConf = match_award_multi_config(AwardConfList,MonsterTypeID),
            case MatchConf of
                #r_activity_monster_award_multi{award_rate=AwardRate}->
                    case AwardRate >= common_tool:random(1,100) of 
                        true->
                            do_hook_monster_drop_item(RoleID,MatchConf);
                        _ ->
                            []
                    end;
                _ ->
                    []
            end;
        _Other ->
            []
    end.

match_award_multi_config([],_MonsterTypeID)->
    [];
match_award_multi_config([H|T],MonsterTypeID)->
    #r_activity_monster_award_multi{monster_list=MonsterTypeIDList}=H,
    case lists:member(MonsterTypeID, MonsterTypeIDList) of
        true->
            H;
        _ ->
            match_award_multi_config(T,MonsterTypeID)
    end.

match_award_one_config([],_MonsterTypeID)->
    [];
match_award_one_config([H|T],MonsterTypeID)->
    #r_activity_monster_award_one{monster_list=MonsterTypeIDList}=H,
    case lists:member(MonsterTypeID, MonsterTypeIDList) of
        true->
            H;
        _ ->
            match_award_one_config(T,MonsterTypeID)
    end.

do_hook_monster_drop_item(RoleID,AwardConf) when is_record(AwardConf,r_activity_monster_award_one)->
    #r_activity_monster_award_one{award_item_id=ItemTypeID,award_num=Num,bind_type=Bind}=AwardConf,
    PropList = [#r_award_prop{item_id=ItemTypeID,num=Num,bind=Bind}],
    do_add_prop(RoleID,PropList);
do_hook_monster_drop_item(RoleID,AwardConf) when is_record(AwardConf,r_activity_monster_award_multi)->
    #r_activity_monster_award_multi{award_prop_list=PropList1,award_type=AwardType}=AwardConf,
    case AwardType of
        1->
            PropList = [get_random_prop(PropList1)];
        2->
            PropList = PropList1
    end,
    do_add_prop(RoleID,PropList).

%%根据权重，随机获取奖励的道具
get_random_prop(PropList1)->
    ItemWeightList = lists:sort(fun({_,W1},{_,W2})-> W1<W2 end, 
                                [{ItemID,W}||#r_award_prop{item_id=ItemID,weight=W}<-PropList1]
                               ),
    WeightSum = lists:sum( [W||#r_award_prop{weight=W}<-PropList1] ),
    RandomRate = common_tool:random(1,WeightSum),
    MatchProp = get_match_prop( RandomRate,ItemWeightList ),
    lists:keyfind(MatchProp, #r_award_prop.item_id, PropList1).

%%@return integer() 道具ID
get_match_prop(_RandomRate,[{L,_Weight}])->
    L;
get_match_prop(RandomRate,[{L1,Wt1},{L2,Wt2}|T]) when is_integer(RandomRate)->
    if
        RandomRate=<Wt1->
            L1;
        true->
            T2 = [{L2,Wt1+Wt2}|T],
            get_match_prop(RandomRate,T2)
    end.
    
%%@doc 判断道具/装备/宝石类型
%%@return integer()
get_prop_type(ItemTypeID)->
    ItemTypeID div 10000000.
    
%%@doc 增加道具
do_add_prop(RoleID,AwardPropList) when is_list(AwardPropList)->  
    case db:transaction(
           fun() ->
               GoodsInfoList =
                 lists:foldl(fun(E,AccIn)-> 
                                 #r_award_prop{item_id=ItemTypeID,num=Num,bind=Bind} = E,
                                 Type = get_prop_type(ItemTypeID),
                                 CreateInfo = #r_goods_create_info{type=Type,type_id=ItemTypeID,num=Num,
                                                                   bind=Bind,start_time=0,end_time=0},
                                 {ok,GoodsList} = mod_bag:create_goods(RoleID,CreateInfo),
                                 lists:merge(AccIn, GoodsList)
                             end, [], AwardPropList),
               {ok,GoodsInfoList}
           end)
        of 
        {aborted,{throw,{bag_error,{not_enough_pos,_BagID}}=R}} ->
            common_broadcast:bc_send_msg_role(RoleID,?BC_MSG_TYPE_SYSTEM,<<"您的背包已满，无法赠送节日活动的物品。">>),
            ?DEBUG("do_add_prop error,Reason=~w",[R]),
            [];
        {aborted, Reason} ->
            ?ERROR_MSG("do_add_prop error,Reason=~w",[Reason]),
            [];
        {atomic, {ok,GoodsInfoList}} ->
            do_item_log(RoleID,AwardPropList),
            GoodsInfoList
    end.

%%记录道具日志
do_item_log(RoleID,AwardPropList) ->
    lists:foreach(fun(E)-> 
                      #r_award_prop{item_id=ItemTypeID,num=Num,bind=Bind} = E,
                      common_item_logger:log(RoleID, ItemTypeID,Num,Bind,?LOG_ITEM_TYPE_GAIN_ACTIVITY_GET)
                  end, AwardPropList).
    


