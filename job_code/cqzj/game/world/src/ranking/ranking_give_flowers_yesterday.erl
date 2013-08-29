-module(ranking_give_flowers_yesterday).

-include("mgeew.hrl"). 

-export([init/1,rank/0, update/1,cmp/2,send_ranking_info/6,get_role_rank/1,do_rank_activity/0]).

init(_RankInfo) ->
    case db:dirty_match_object(?DB_ROLE_GIVE_FLOWERS_YESTERDAY_RANK_P,
                               #p_role_give_flowers_yesterday_rank{_ = '_'}) 
    of
        [] ->
            put({?MODULE,ranking_info_list},[]);
        RoleRankInfoList ->
	    {ok,GiveList} = do_rank(RoleRankInfoList),
            put({?MODULE,ranking_info_list},GiveList)
    end.


do_rank(RoleGiveRankxList) ->
    RoleGiveRankxList1 = lists:sort(fun(E1,E2) -> cmp(E1,E2) end,RoleGiveRankxList),
    {Length,RoleGiveRankxList2} =
        case erlang:length(RoleGiveRankxList1) of
            R when R > 100 ->
                 {100, lists:sublist(RoleGiveRankxList1, R-100+1, 100)};
                R ->
                 {R,RoleGiveRankxList1}
        end,
    {_,RoleGiveRankxList3} =
        lists:foldl(
          fun(ReceRank,{Rank,Acc}) ->
                 {Rank-1,[ReceRank#p_role_give_flowers_yesterday_rank{ranking = Rank,title=case Rank of 1 -> "";_ -> "" end}|Acc]}
          end,{Length,[]},RoleGiveRankxList2),
    {ok,RoleGiveRankxList3}.


cmp(RoleGiveRank1,RoleGiveRank2) ->
    #p_role_give_flowers_yesterday_rank{role_id = RoleID1,level = Level1,score = Score1} = RoleGiveRank1,
    #p_role_give_flowers_yesterday_rank{role_id = RoleID2,level = Level2,score = Score2} = RoleGiveRank2,
    mgeew_ranking:cmp([{Score1,Score2},{Level1,Level2},{RoleID2,RoleID1}]).

    
rank() ->
    {H,M,_} = erlang:time(),
    ?DEBUG("H:~w,M:~w~n",[H,M]),
    case (H =:= 0 andalso M < 5)  of
        true ->
            OldGiveYesterDayRankList = db:dirty_match_object(?DB_ROLE_GIVE_FLOWERS_YESTERDAY_RANK_P,#p_role_give_flowers_yesterday_rank{ _ = '_'}),
            lists:foreach(fun(OldGiveYesterDayRank) -> db:dirty_delete_object(?DB_ROLE_GIVE_FLOWERS_YESTERDAY_RANK_P,OldGiveYesterDayRank) end, OldGiveYesterDayRankList),
			
            List = ranking_give_flowers_today:get_ranking_info(),

	    %% begin 添加信息到本周送花榜数据库       
	    today_to_this_week_rank(List),            
	    %% end                                    

            NewListTmp = today_to_yesterday_rank(List),
            {ok,NewList} = do_rank(NewListTmp),
            put({?MODULE,ranking_info_list},NewList),
            OldGiveToDayRankList = db:dirty_match_object(?DB_ROLE_GIVE_FLOWERS_TODAY_RANK_P,#p_role_give_flowers_today_rank{ _ = '_'}),
            lists:foreach(fun(OldGiveToDayRank) -> db:dirty_delete_object(?DB_ROLE_GIVE_FLOWERS_TODAY_RANK_P,OldGiveToDayRank) end, OldGiveToDayRankList),
            put({ranking_give_flowers_today,ranking_info_list},[]),
            common_title_srv:add_title(?TITLE_ROLE_GIVE_FLOWERS_YESTERDAY,0,NewList);
        false ->
            ignore
    end.

update(reset) ->
	RankList = db:dirty_match_object(?DB_ROLE_GIVE_FLOWERS_YESTERDAY_RANK_P,#p_role_give_flowers_yesterday_rank{ _ = '_'}),
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
    #p_role_give_flowers_yesterday_rank{ranking=Ranking,role_id=RoleID,role_name=RoleName,family_id=FamilyId,
                                        family_name=FamilyName,faction_id=FactionId,score=Score,title=Title} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,common_tool:to_list(Score),FamilyName,
                          common_misc:get_faction_name(FactionId), Title],
                int_list=[FamilyId]}.

do_rank_activity()->
    List1 = get({?MODULE,ranking_info_list}),
    List2 = [{RankInfo#p_role_give_flowers_yesterday_rank.role_id,RankInfo#p_role_give_flowers_yesterday_rank.ranking}||RankInfo<-List1],
    mgeew_ranking:send_ranking_activity(?RANK_YDAY_GIVE_FLOWER_KEY,List2).


%%将今日送花榜写入本周送花榜数据表                                                      
today_to_this_week_rank(List)when is_list(List) ->                                      
    lists:foreach(                                                                          
      fun(ToDayRank) ->                                                                 
              #p_role_give_flowers_today_rank{ranking=Ranking,                          
                                              role_id=RoleID,                           
                                              role_name=RoleName,                       
                                              level=Level,                              
                                              score=Score,                              
                                              family_id=FamilyID,                       
                                              family_name=FamilyName,                   
                                              faction_id=FactionID,                     
                                              title=_Title}=ToDayRank,                  
                                                                                        
              case db:dirty_read(?DB_ROLE_GIVE_FLOWERS_THIS_WEEK_RANK_P,RoleID) of        
                        []->                                                            
                                NewScore = Score;                                       
                        [ThisWeekRoleGive]->   
			 	#p_role_give_flowers_this_week_rank{score = OldScore} = ThisWeekRoleGive,                                      
                                NewScore = Score + OldScore                  
		end,                                                                                                                                              
                ThisWeekRank =                                                          
                  #p_role_give_flowers_this_week_rank{ranking= Ranking,                 
                                                      role_id= RoleID,                  
                                                      role_name= RoleName,              
                                                      level = Level,                    
                                                      score=NewScore,                   
                                                      family_id = FamilyID,             
                                                      family_name = FamilyName,         
                                                      faction_id = FactionID,           
                                                      title=""},                        
                                                                                        
                                                                                        
              db:dirty_write(?DB_ROLE_GIVE_FLOWERS_THIS_WEEK_RANK_P,ThisWeekRank)         
                                                                                        
      end,List);                                                                        
today_to_this_week_rank(_) ->                                                           
    [].                                                                                 

today_to_yesterday_rank(List)when is_list(List) ->
    lists:map(
      fun(ToDayRank) ->
              #p_role_give_flowers_today_rank{ranking=Ranking,
                                              role_id=RoleID,
                                              role_name=RoleName,
                                              level=Level,     
                                              score=Score,                       
                                              family_id=FamilyID,                    
                                              family_name=FamilyName,                    
                                              faction_id=FactionID,                     
                                              title=_Title}=ToDayRank,
              YesterDayRank = 
                  #p_role_give_flowers_yesterday_rank{ranking= Ranking,
                                                      role_id= RoleID,                     
                                                      role_name= RoleName,                 
                                                      level = Level,                         
                                                      score = Score,                      
                                                      family_id = FamilyID,                 
                                                      family_name = FamilyName,                    
                                                      faction_id = FactionID,                    
                                                      title = case Ranking of 1 -> "";_ -> "" end},
              db:dirty_write(?DB_ROLE_GIVE_FLOWERS_YESTERDAY_RANK_P,YesterDayRank),
              YesterDayRank
      end,List);
today_to_yesterday_rank(_) ->
    [].

get_role_rank(RoleID) ->
    List = get({?MODULE,ranking_info_list}),
    case lists:keyfind(RoleID,#p_role_give_flowers_yesterday_rank.role_id,List) of
        false ->
            undefined;
        GiveRankInfo ->
            #p_role_give_flowers_yesterday_rank{ranking = Rank,score = Score} = GiveRankInfo,
            #p_role_all_rank{ int_key_value=Score, ranking = Rank}
    end.
