%%% -------------------------------------------------------------------
%%% Author  : caisiqiang
%%% Description :上周鲜花排行榜
%%% 
%%% Created : 2011-01-20
%%% -------------------------------------------------------------------
-module(ranking_rece_flowers_last_week).

-include("mgeew.hrl").

-export([init/1,rank/0, update/1,cmp/2,send_ranking_info/6,get_role_rank/1]).

%%
%%================API FUCTION=======================
%%

%%数据初始化  本周信息在数据库中  上周信息在进程中
init(_RankInfo) ->
    case db:dirty_match_object(?DB_ROLE_RECE_FLOWERS_LAST_WEEK_RANK_P,#p_role_rece_flowers_last_week_rank{_ = '_'}) of
        [] ->
            put({?MODULE,ranking_info_list},[]);
        RoleReceRankxList ->
            {ok,ReceList} = do_rank(RoleReceRankxList),
            put({?MODULE,ranking_info_list},ReceList)
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

%%
%%================LOCAL FUCTION=======================
%%

%%rank2()更新本周数据到上周数据和进程
rank2() ->
    case db:dirty_match_object(?DB_ROLE_RECE_FLOWERS_THIS_WEEK_RANK_P,#p_role_rece_flowers_this_week_rank{_ = '_'}) of
	[]->
	    put({?MODULE,ranking_info_list},[]),
		OldLastWeekRoleRankList = db:dirty_match_object(?DB_ROLE_RECE_FLOWERS_LAST_WEEK_RANK_P,#p_role_rece_flowers_last_week_rank{ _ = '_'}),
        lists:foreach(fun(OldLastWeekRank) -> db:dirty_delete_object(?DB_ROLE_RECE_FLOWERS_LAST_WEEK_RANK_P,OldLastWeekRank) end, OldLastWeekRoleRankList);
	ThisWeekRankList ->
        LastWeekRankList= this_week_to_last_week_rank(ThisWeekRankList),
        {ok,ReceList} = do_rank(LastWeekRankList),
		lists:foreach(fun(OldThisWeekRank) -> db:dirty_delete_object(?DB_ROLE_RECE_FLOWERS_THIS_WEEK_RANK_P,OldThisWeekRank) end, ThisWeekRankList),
        put({?MODULE,ranking_info_list},ReceList),
		OldLastWeekRoleRankList = db:dirty_match_object(?DB_ROLE_RECE_FLOWERS_LAST_WEEK_RANK_P,#p_role_rece_flowers_last_week_rank{ _ = '_'}),
		lists:foreach(fun(OldLastWeekRank) -> db:dirty_delete_object(?DB_ROLE_RECE_FLOWERS_LAST_WEEK_RANK_P,OldLastWeekRank) end, OldLastWeekRoleRankList),
        lists:foreach(fun(ReceFlowers)-> db:dirty_write(?DB_ROLE_RECE_FLOWERS_LAST_WEEK_RANK_P,ReceFlowers) end,ReceList)
    end.

this_week_to_last_week_rank(List)when is_list(List) ->
    lists:map(
      fun(ThisWeekRank) ->
              #p_role_rece_flowers_this_week_rank{ranking=Ranking,
                                              role_id=RoleID,
                                              role_name=RoleName,
                                              level=Level,
                                              charm=Charm,
                                              family_id=FamilyID,
                                              family_name=FamilyName,
                                              faction_id=FactionID,
                                              title=_Title}=ThisWeekRank,
              LastWeekRank =
                  #p_role_rece_flowers_last_week_rank{ranking= Ranking,
                                                      role_id= RoleID,
                                                      role_name= RoleName,
                                                      level = Level,
                                                      charm = Charm,
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
          fun(ReceRank,{Rank,Acc}) ->
                  {Rank-1,[ReceRank#p_role_rece_flowers_last_week_rank{ranking = Rank,title=""}|Acc]}
          end,{Length,[]},LastWeekRankList2),
    {ok,LastWeekRankList3}.


cmp(RoleReceRank1,RoleReceRank2) ->
    #p_role_rece_flowers_last_week_rank{role_id = RoleID1,level = Level1,charm = Charm1} = RoleReceRank1,
    #p_role_rece_flowers_last_week_rank{role_id = RoleID2,level = Level2,charm = Charm2} = RoleReceRank2,
    mgeew_ranking:cmp([{Charm1,Charm2},{Level1,Level2},{RoleID2,RoleID1}]).

update(reset) ->
	RankList = db:dirty_match_object(?DB_ROLE_RECE_FLOWERS_LAST_WEEK_RANK_P,#p_role_rece_flowers_last_week_rank{ _ = '_'}),
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
    #p_role_rece_flowers_last_week_rank{ranking=Ranking,role_id=RoleID,role_name=RoleName,family_id=FamilyId,
                                        family_name=FamilyName,faction_id=FactionId,charm=Score,title=Title} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,common_tool:to_list(Score),FamilyName,
                          common_misc:get_faction_name(FactionId), Title],
                int_list=[FamilyId]}.


get_role_rank(RoleID) ->
    List = get({?MODULE,ranking_info_list}),
    case lists:keyfind(RoleID,#p_role_rece_flowers_last_week_rank.role_id,List) of
        false ->
            undefined;
        GiveRankInfo ->
            #p_role_rece_flowers_last_week_rank{ranking = Rank,charm = Charm} = GiveRankInfo,
            #p_role_all_rank{ int_key_value=Charm, ranking = Rank}
    end.
