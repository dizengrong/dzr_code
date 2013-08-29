%%% -------------------------------------------------------------------
%%% Author  : liuwei
%%% Description :我的排行榜
%%% 
%%% Created : 2010-10-9
%%% -------------------------------------------------------------------
-module(ranking_role_all_rank).

-include("mgeew.hrl").


-export([
         send_role_all_ranking_info/4
        ]).

-define(SELF_RANK_MODULES,[
                           {ranking_role_level,<<"角色等级榜">>,<<"等级">>},
                           {ranking_role_world_pkpoint,<<"世界恶人榜">>,<<"PK值">>},
                           {ranking_role_pkpoint,<<"势力恶人榜">>,<<"PK值">>},
                           {ranking_equip_refining,<<"神兵总分榜">>,<<"装备评分">>},
                           {ranking_equip_reinforce,<<"强化排行榜">>,<<"强化系数">>},
                           {ranking_equip_stone,<<"镶嵌排行榜">>,<<"镶嵌系数">>},
                           {ranking_role_gongxun,<<"势力战功榜">>,<<"战功">>},
                           {ranking_give_flowers,<<"送花谱">>,<<"送花得分">>},
                           {ranking_give_flowers_today,<<"今日送花榜">>,<<"送花得分">>},
                           {ranking_give_flowers_yesterday,<<"昨日送花榜">>,<<"送花得分">>},
                           {ranking_give_flowers_last_week,<<"上周送花榜">>,<<"送花得分">>},
                           {ranking_rece_flowers,<<"百花谱">>,<<"魅力值">>},
                           {ranking_rece_flowers_today,<<"今日鲜花榜">>,<<"魅力值">>},
                           {ranking_rece_flowers_yesterday,<<"昨日鲜花榜">>,<<"魅力值">>},
                           {ranking_rece_flowers_last_week,<<"上周鲜花榜">>,<<"魅力值">>},
                           {ranking_role_pet,<<"异兽总分榜">>,<<"总分">>},
                           {ranking_hero_fb,<<"霸主榜">>,<<"关数">>}
                          ]).

%%
%%================API FUCTION=======================
%%   
%%发送角色等级排行榜详细信息
send_role_all_ranking_info(RoleID,Line,DataIn,Unique) ->
    #m_ranking_role_all_rank_tos{role_id = DestRoleID} = DataIn,
    case DestRoleID =:= 0 orelse DestRoleID =:= undefined of
        true ->
            DestRoleID2 = RoleID;
        false ->
            DestRoleID2 = DestRoleID
    end,
    RankList = lists:foldl(
                 fun({ModuleName,RankName,KeyName},Acc) ->
                         case ModuleName:get_role_rank(DestRoleID2) of
                             undefined ->
                                 Acc;
                             List when is_list(List) ->
                                 lists:foldl(
                                   fun(RankTmp,Acc2) ->
                                           merge_rank(RankTmp,RankName,KeyName,Acc2)
                                   end,Acc,List);
                             Rank ->
                                 merge_rank(Rank,RankName,KeyName,Acc)
                         end
                 end,[],?SELF_RANK_MODULES),
    
    case RoleID =:= DestRoleID of 
        true ->
            Record = #m_ranking_role_all_rank_toc{role_id = DestRoleID2, is_self = true, role_all_ranks = RankList};
        false ->
            [RoleBase] = db:dirty_read(?DB_ROLE_BASE,DestRoleID2),
            [RoleAttr] = db:dirty_read(?DB_ROLE_ATTR,DestRoleID2),
            Level = RoleAttr#p_role_attr.level,
            RoleName = RoleBase#p_role_base.role_name,
            FamilyName = RoleBase#p_role_base.family_name,
            Record = #m_ranking_role_all_rank_toc{role_id = DestRoleID2, is_self = false, role_all_ranks = RankList,
                                                  level = Level,role_name = RoleName, family_name = FamilyName}
    end,
    common_misc:unicast(Line, RoleID, Unique, ?RANKING, ?RANKING_ROLE_ALL_RANK, Record).

merge_rank(Rank,RankName,KeyName,AccIn)->
    case Rank#p_role_all_rank.ranking of
        undefined ->
            AccIn;
        _ ->
            [Rank#p_role_all_rank{rank_name=RankName,key_name=KeyName}|AccIn]
    end.


    
