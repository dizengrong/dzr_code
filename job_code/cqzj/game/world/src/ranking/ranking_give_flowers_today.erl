-module(ranking_give_flowers_today).

-include("mgeew.hrl").

-export([init/1, update/1,cmp/2,send_ranking_info/6,get_ranking_info/0,get_role_rank/1]).
-export([rank/0]).

init(_RankInfo) ->
    case db:dirty_match_object(?DB_ROLE_GIVE_FLOWERS_TODAY_RANK_P,#p_role_give_flowers_today_rank{_ = '_'}) of
        [] ->
            put({?MODULE,ranking_info_list},[]);
        RoleRankInfoList ->
            {ok,GiveList} = do_rank(RoleRankInfoList),
            put({?MODULE,ranking_info_list},GiveList)
    end.

rank()->
    uncompleted.

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
                 {Rank-1,[ReceRank#p_role_give_flowers_today_rank{ranking = Rank,title=""}|Acc]}                             
          end,{Length,[]},RoleGiveRankxList2),                                          
    {ok,RoleGiveRankxList3}.                                                            	
update({RoleBase,RoleAttr,AddScore})->
    #p_role_base{role_id=RoleID,role_name=RoleName,sex=Sex,faction_id=FactionID,
                 family_id=FamilyID,family_name=FamilyName}= RoleBase,
    #p_role_attr{level=Level} = RoleAttr,
    update({RoleID,RoleName,Sex,Level,FactionID,FamilyID,FamilyName,AddScore});
update({RoleID,RoleName,Sex,Level,FactionID,FamilyID,FamilyName,AddScore})
  when Sex =:= 1 andalso AddScore>0 ->
    NewRoleGiveRank = case db:dirty_read(?DB_ROLE_GIVE_FLOWERS_TODAY_RANK_P,RoleID) of
                          [OldRoleGiveRank] ->
                              OldScore = OldRoleGiveRank#p_role_give_flowers_today_rank.score,
                              OldRoleGiveRank#p_role_give_flowers_today_rank{score=OldScore+AddScore};
                          _->
                              #p_role_give_flowers_today_rank{role_id = RoleID,
                                                              role_name = RoleName,
                                                              level = Level,
                                                              score = AddScore,
                                                              faction_id = FactionID,
                                                              family_id = FamilyID,
                                                              family_name = FamilyName}
                      end,
    db:dirty_write(?DB_ROLE_GIVE_FLOWERS_TODAY_RANK_P,NewRoleGiveRank),
    RoleGiveRankxList =     
        db:dirty_match_object(?DB_ROLE_GIVE_FLOWERS_TODAY_RANK_P,#p_role_give_flowers_today_rank{_='_'}),
    ?DEBUG("RoleGiveRankList:~w~n",[RoleGiveRankxList]),
    {ok,NewList} = do_rank(RoleGiveRankxList),
    put({?MODULE,ranking_info_list},NewList);
update({RoleID,_RoleName,_Sex,_Level,_FactionID,_FamilyID,_FamilyName,_Score})->
    List = get({?MODULE,ranking_info_list}),
    {ok,NewList} = do_rank(lists:keydelete(RoleID,2,List)),
    put({?MODULE,ranking_info_list},NewList),
    db:dirty_delete(?DB_ROLE_GIVE_FLOWERS_TODAY_RANK_P,RoleID);
update(_) ->
    ignore.

cmp(RoleGiveRank1,RoleGiveRank2) ->
    #p_role_give_flowers_today_rank{role_id = RoleID1,level = Level1,score = Score1} = RoleGiveRank1,
    #p_role_give_flowers_today_rank{role_id = RoleID2,level = Level2,score = Score2} = RoleGiveRank2,
    mgeew_ranking:cmp([{Score1,Score2},{Level1,Level2},{RoleID2,RoleID1}]). 
 
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
    #p_role_give_flowers_today_rank{ranking=Ranking,role_id=RoleID,role_name=RoleName,family_id=FamilyId,
                                        family_name=FamilyName,faction_id=FactionId,score=Score,title=Title} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,common_tool:to_list(Score),FamilyName,
                          common_misc:get_faction_name(FactionId), Title],
                int_list=[FamilyId]}.   

get_ranking_info() ->
    get({?MODULE,ranking_info_list}).

get_role_rank(RoleID) ->
    RoleGiveRankingInfoList = get({?MODULE,ranking_info_list}),
    case lists:keyfind(RoleID,#p_role_give_flowers_today_rank.role_id,RoleGiveRankingInfoList) of
        false ->
            undefined;
        GiveRankInfo ->
            #p_role_give_flowers_today_rank{ranking = Rank,score = Score} = GiveRankInfo,
            #p_role_all_rank{ int_key_value=Score, ranking = Rank}
    end.
