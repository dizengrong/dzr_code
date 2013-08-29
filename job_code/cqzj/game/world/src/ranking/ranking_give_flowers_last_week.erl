%%% -------------------------------------------------------------------
%%% Author  : caisiqiang
%%% Description :上周送花排行榜
%%% 
%%% Created : 2011-01-20
%%% -------------------------------------------------------------------
-module(ranking_give_flowers_last_week).

-include("mgeew.hrl").

-export([init/1,rank/0, update/1,cmp/2,send_ranking_info/6,get_role_rank/1]).

%%数据初始化  本周信息在数据库中  上周信息在进程中
init(_RankInfo) ->
    case db:dirty_match_object(?DB_ROLE_GIVE_FLOWERS_LAST_WEEK_RANK_P,#p_role_give_flowers_last_week_rank{_ = '_'}) of
        [] ->
            put({?MODULE,ranking_info_list},[]);
        RoleGiveRankxList ->
            {ok,GiveList} = do_rank(RoleGiveRankxList),
            put({?MODULE,ranking_info_list},GiveList)
    end.

%%更新上周排行榜
%%rank()判断更新时间
rank() ->
    {H,M,_} = erlang:time(),
    ?DEBUG("H:~w,M:~w~n",[H,M]),
    case calendar:day_of_the_week(date()) of
        1->
                case (H =:= 0 andalso M < 5)  of
                        true->
                                %%更新数据库的数据到进程
                                rank2();
                        false->
                                ignore
                end;
        _->
                ignore
    end.

rank2() ->
    case db:dirty_match_object(?DB_ROLE_GIVE_FLOWERS_THIS_WEEK_RANK_P,#p_role_give_flowers_this_week_rank{_ = '_'}) of
        []->
            put({?MODULE,ranking_info_list},[]),
			OldLastWeekRoleRankList = db:dirty_match_object(?DB_ROLE_GIVE_FLOWERS_LAST_WEEK_RANK_P,#p_role_give_flowers_last_week_rank{ _ = '_'}),
        	lists:foreach(fun(OldLastWeekRank) -> db:dirty_delete_object(?DB_ROLE_GIVE_FLOWERS_LAST_WEEK_RANK_P,OldLastWeekRank) end, OldLastWeekRoleRankList);
        ThisWeekRankList ->
            LastWeekRankList=this_week_to_last_week_rank(ThisWeekRankList),
            {ok,GiveList} = do_rank(LastWeekRankList),
            lists:foreach(fun(OldThisWeekRank) -> db:dirty_delete_object(?DB_ROLE_GIVE_FLOWERS_THIS_WEEK_RANK_P,OldThisWeekRank) end, ThisWeekRankList),
            put({?MODULE,ranking_info_list},GiveList),   
            OldLastWeekRoleRankList = db:dirty_match_object(?DB_ROLE_GIVE_FLOWERS_LAST_WEEK_RANK_P,#p_role_give_flowers_last_week_rank{ _ = '_'}),
			lists:foreach(fun(OldLastWeekRank) -> db:dirty_delete_object(?DB_ROLE_GIVE_FLOWERS_LAST_WEEK_RANK_P,OldLastWeekRank) end, OldLastWeekRoleRankList),
            lists:foreach(fun(GiveFlowers)->db:dirty_write(?DB_ROLE_GIVE_FLOWERS_LAST_WEEK_RANK_P,GiveFlowers) end,GiveList)
    end.

this_week_to_last_week_rank(List)when is_list(List) ->
    lists:map(
      fun(ThisWeekRank) ->
              #p_role_give_flowers_this_week_rank{ranking=Ranking,
                                              role_id=RoleID,
                                              role_name=RoleName,
                                              level=Level,
                                              score=Score,
                                              family_id=FamilyID,
                                              family_name=FamilyName,
                                              faction_id=FactionID,
                                              title=_Title}=ThisWeekRank,
              LastWeekRank =
                  #p_role_give_flowers_last_week_rank{ranking= Ranking,
                                                      role_id= RoleID,
                                                      role_name= RoleName,
                                                      level = Level,
                                                      score = Score,
                                                      family_id = FamilyID,
                                                      family_name = FamilyName,
                                                      faction_id = FactionID,
                                                      title = ""},
              LastWeekRank
      end,List);
this_week_to_last_week_rank(_) ->
    [].

do_rank(LastWeekRankList) ->
    LastWeekRankList1 = lists:sort(fun(E1,E2) -> cmp(E1,E2) end,LastWeekRankList),
    {Length,LastWeekRankList2} =
        case erlang:length(LastWeekRankList1) of
            R when R > 100 ->
                 {100, lists:sublist(LastWeekRankList1, R-100+1, 100)};
                R ->
                 {R,LastWeekRankList1}
        end,
    {_,LastWeekRankList3} =
        lists:foldl(
          fun(GiveRank,{Rank,Acc}) ->
                  {Rank-1,[GiveRank#p_role_give_flowers_last_week_rank{ranking = Rank,title=""}|Acc]}
          end,{Length,[]},LastWeekRankList2),
    {ok,LastWeekRankList3}.


cmp(RoleGiveRank1,RoleGiveRank2) ->
    #p_role_give_flowers_last_week_rank{role_id = RoleID1,level = Level1,score = Score1} = RoleGiveRank1,
    #p_role_give_flowers_last_week_rank{role_id = RoleID2,level = Level2,score = Score2} = RoleGiveRank2,
    mgeew_ranking:cmp([{Score1,Score2},{Level1,Level2},{RoleID2,RoleID1}]).

update(reset) ->
	RankList = db:dirty_match_object(?DB_ROLE_GIVE_FLOWERS_LAST_WEEK_RANK_P,#p_role_give_flowers_last_week_rank{ _ = '_'}),
	SortList = do_rank(RankList),
	put({?MODULE,ranking_info_list},SortList);
update(_) ->
    ignore.

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
    #p_role_give_flowers_last_week_rank{ranking=Ranking,role_id=RoleID,role_name=RoleName,family_id=FamilyId,
                                        family_name=FamilyName,faction_id=FactionId,score=Score,title=Title} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,common_tool:to_list(Score),FamilyName,
                          common_misc:get_faction_name(FactionId), Title],
                int_list=[FamilyId]}.

get_role_rank(RoleID) ->
    List = get({?MODULE,ranking_info_list}),
    case lists:keyfind(RoleID,#p_role_give_flowers_last_week_rank.role_id,List) of
        false ->           
            undefined;          
        GiveRankInfo ->
            #p_role_give_flowers_last_week_rank{ranking = Rank,score = Score} = GiveRankInfo,
            #p_role_all_rank{ int_key_value=Score, ranking = Rank}
    end.       

