-module(ranking_rece_flowers_today).

-include("mgeew.hrl").

-export([init/1, update/1,cmp/2,send_ranking_info/6,get_ranking_info/0,get_role_rank/1]).
-export([rank/0]).

init(_RankInfo) ->
    case db:dirty_match_object(?DB_ROLE_RECE_FLOWERS_TODAY_RANK_P,#p_role_rece_flowers_today_rank{_ = '_'}) of
        [] ->
            put({?MODULE,ranking_info_list},[]);
        RoleReceRankxList ->
            {ok,ReceList} = do_rank(RoleReceRankxList),
            put({?MODULE,ranking_info_list},ReceList)
    end.

rank()->
    uncompleted.

do_rank(RoleReceRankxList) ->
    RoleReceRankxList1 = lists:sort(fun(E1,E2) -> cmp(E1,E2) end,RoleReceRankxList),
    {Length,RoleReceRankxList2} =
        case erlang:length(RoleReceRankxList1) of
            R when R > 100 ->
                 {100, lists:sublist(RoleReceRankxList1, R-100+1, 100)};
                R ->
                 {R,RoleReceRankxList1}
        end,
    {_,RoleReceRankxList3} =
        lists:foldl(
          fun(ReceRank,{Rank,Acc}) ->
                  {Rank-1,[ReceRank#p_role_rece_flowers_today_rank{ranking = Rank,title=""}|Acc]}
          end,{Length,[]},RoleReceRankxList2),
    {ok,RoleReceRankxList3}.

update({RoleBase,RoleAttr,AddCharm})->
    #p_role_base{role_id=RoleID,role_name=RoleName,sex=Sex,faction_id=FactionID,
                 family_id=FamilyID,family_name=FamilyName}= RoleBase,
    #p_role_attr{level=Level} = RoleAttr,
    update({RoleID,RoleName,Sex,Level,FactionID,FamilyID,FamilyName,AddCharm});
update({RoleID,RoleName,Sex,Level,FactionID,FamilyID,FamilyName,AddCharm})
  when Sex =:= 2 andalso AddCharm > 0 ->
    NewRoleReceRank = case db:dirty_read(?DB_ROLE_RECE_FLOWERS_TODAY_RANK_P,RoleID ) of
                          [OldRoleReceRank] ->
                          	OldCharm = OldRoleReceRank#p_role_rece_flowers_today_rank.charm,
				OldRoleReceRank#p_role_rece_flowers_today_rank{charm=OldCharm+AddCharm};
                   	   _ ->				
       				 #p_role_rece_flowers_today_rank{role_id = RoleID,
                                	        role_name = RoleName,
                                        	level = Level,
                                        	charm = AddCharm,
                                        	faction_id = FactionID,
                                        	family_id = FamilyID,
                                        	family_name = FamilyName}
		      end,
    db:dirty_write(?DB_ROLE_RECE_FLOWERS_TODAY_RANK_P,NewRoleReceRank),	                         
    RoleReceRankxList = 
             db:dirty_match_object(?DB_ROLE_RECE_FLOWERS_TODAY_RANK_P,#p_role_rece_flowers_today_rank{_ = '_'}),
    ?DEBUG("RoleGiveRankList:~w~n",[RoleReceRankxList]),
    {ok,NewList} = do_rank(RoleReceRankxList),
    put({?MODULE,ranking_info_list},NewList);
update({RoleID,_RoleName,_Sex,_Level,_FactionID,_FamilyID,_FamilyName,_AddCharm})->
    List = get({?MODULE,ranking_info_list}),
    {ok,NewList} = do_rank(lists:keydelete(RoleID,2,List)),
    put({?MODULE,ranking_info_list},NewList),
    db:dirty_delete(?DB_ROLE_RECE_FLOWERS_TODAY_RANK_P,RoleID);
update(_) ->
    ignore.

cmp(RoleGiveRank1,RoleGiveRank2) ->
    #p_role_rece_flowers_today_rank{role_id = RoleID1,level = Level1,charm = Charm1} = RoleGiveRank1,
    #p_role_rece_flowers_today_rank{role_id = RoleID2,level = Level2,charm = Charm2} = RoleGiveRank2,
    mgeew_ranking:cmp([{Charm1,Charm2},{Level1,Level2},{RoleID2,RoleID1}]). 
   
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
    #p_role_rece_flowers_today_rank{ranking=Ranking,role_id=RoleID,role_name=RoleName,family_id=FamilyId,
                                        family_name=FamilyName,faction_id=FactionId,charm=Score,title=Title} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,common_tool:to_list(Score),FamilyName,
                          common_misc:get_faction_name(FactionId), Title],
                int_list=[FamilyId]}.

get_ranking_info() ->
    get({?MODULE,ranking_info_list}).

get_role_rank(RoleID) ->
    RoleGiveRankingInfoList = get({?MODULE,ranking_info_list}),
    case lists:keyfind(RoleID,#p_role_rece_flowers_today_rank.role_id,RoleGiveRankingInfoList) of
        false ->
            undefined;
        GiveRankInfo ->
            #p_role_rece_flowers_today_rank{ranking = Rank,charm = Charm} = GiveRankInfo,
            #p_role_all_rank{ int_key_value=Charm, ranking = Rank}
    end.
