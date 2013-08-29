%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010
%%% @doc
%%%     昨日百强榜,属于镜像类型的数据榜
%%% @end
%%% Created : 2011-6-16
%%%-------------------------------------------------------------------
-module(ranking_fighting_power_yesterday).

-include("mgeew.hrl").

-export([
		 init/0,
         init/1,
         snapshot/0,
         cmp/2,
         rank/0,
         get_rank_id/0,
         send_ranking_info/6
        ]).
-define(SNAPSHOT_MODULE,ranking_fighting_power).

%%
%%===================== API Functions =========================
%%

get_rank_id()->
    11002.
init() ->
	init(default).
init(_RankInfo) ->
    case get_rank_data_from_db() of
        []->
            check_update_snapshot();
        RankList->
            sort_and_send_rank_list(RankList)
    end.

rank()->
    %%镜像数据不需要排序
    ignore.

cmp(RoleRank1,RoleRank2) ->
    #p_role_fighting_power_rank_yesterday{role_id = RoleID1,level = Level1,fighting_power = FightingPower1} = RoleRank1,
    #p_role_fighting_power_rank_yesterday{role_id = RoleID2,level = Level2,fighting_power = FightingPower2} = RoleRank2,
    mgeew_ranking:cmp([{FightingPower1,FightingPower2},{Level1,Level2},{RoleID2,RoleID1}]). 

check_update_snapshot()->
    {OpenDate,_} = common_config:get_open_day(),
    OpenTime = common_tool:datetime_to_seconds({OpenDate,{0,0,0}}),
    Now = common_tool:now(),
    if Now - OpenTime =< 86400*2 ->
           ignore;
       true->
           snapshot()
    end.

snapshot()->
    case get({?SNAPSHOT_MODULE,ranking_info_list}) of
        undefined->
            ignore;
        RankListSnap ->
            RankList = transform_snapshot_data(RankListSnap),
            RankList2 = sort_and_send_rank_list(RankList),
            save2db(RankList2)
    end.

send_ranking_info(Unique, Module, Method, _RoleID, PID, RankID)->
    RoleRankList = get({?MODULE,ranking_info_list}),
    RankRows = transform_row(RoleRankList),
    R2 = #m_ranking_get_rank_toc{rank_id=RankID,rows=RankRows},
    ?UNICAST_TOC(R2).


transform_row(undefined)->
    [];
transform_row(RoleRankList) when is_list(RoleRankList)->
    [ transform_row(Rec) ||Rec<-RoleRankList];
transform_row(Rec)->
    #p_role_fighting_power_rank_yesterday{ranking=Ranking,role_id=RoleID,role_name=RoleName,fighting_power=PowerScore,
        faction_id=FactionId,silver=Silver, sex = Sex, category = Category} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,common_misc:get_faction_name(FactionId),
                          common_tool:to_list(PowerScore),
                          common_tool:to_list(Silver), Sex, Category
                         ],int_list=[]}.

transform_snapshot_data(List) when is_list(List)->
    %%策划的特殊处理，因为奖励只计算百强榜里面的最高奖励
    MaxRankLevel = get_rank_max_level(),
    [
     begin
         RankId = get_rank_id(),
         Silver = mod_rankreward_server:get_reward_silver(RankId,Level,Ranking),
         #p_role_fighting_power_rank_yesterday{
            ranking=Ranking,role_id=RoleID,role_name=RoleName,
            fighting_power=PowerScore,level=Level,
            faction_id=FactionId,jingjie=MaxRankLevel,silver=Silver,
            sex = Sex, category = Category}
     end || #p_role_fighting_power_rank{ranking=Ranking,role_id=RoleID,role_name=RoleName,
                                        fighting_power=PowerScore,level=Level,
                                        faction_id=FactionId, sex = Sex, category = Category}<- List
    ].

%%
%%====================== Local Functions =======================
%% 

%%获取排行榜中的最高境界
get_rank_max_level()->
    case get({ranking_role_level_all,ranking_info_list}) of
        undefined->
            20; %%异常情况下的默认值
        []->
            20; %%异常情况下的默认值
        RoleRankList ->
            LevelList = [ Level || #p_role_level_rank{level=Level}<- RoleRankList],
            lists:max( LevelList ) 
    end.

%%数据持久化到DB中
save2db(RankList)->
    case get_rank_data_from_db() of
        []->
            next;
        OldList->
            lists:foreach(
              fun(E1)->
                      db:dirty_delete_object(?DB_ROLE_FIGHTING_POWER_RANK_YESTERDAY_P,E1)
              end, OldList)
    end,
    lists:foreach(
      fun(E2)->
              db:dirty_write(?DB_ROLE_FIGHTING_POWER_RANK_YESTERDAY_P, E2)
      end, RankList).


%%排序排行榜数据，并发送到mod_rankreward_server
sort_and_send_rank_list(RankList)->
    RankList2 = lists:sort(fun(E1,E2) -> cmp(E2,E1) end,RankList),
    put({?MODULE,ranking_info_list},RankList2),
    ?TRY_CATCH( global:send(mod_rankreward_server, {snapshot,?MODULE,RankList2}) ),
    RankList2.

%%从DB中获取排行数据
get_rank_data_from_db()->
    db:dirty_match_object(?DB_ROLE_FIGHTING_POWER_RANK_YESTERDAY_P,#p_role_fighting_power_rank_yesterday{_ = '_'}).
