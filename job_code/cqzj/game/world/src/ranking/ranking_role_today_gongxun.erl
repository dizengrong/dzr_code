%% Author: liuwei
%% Created: 2010-12-17
%% Description: 今日护国英雄榜
-module(ranking_role_today_gongxun).

%%
%% Include files
%%
-include("mgeew.hrl").
%%
%% Exported Functions
%%
-export([
         init/1,
         rank/0,
         update/1,
         cmp/2,  
         send_ranking_info/6,
         get_role_rank/1
        ]).

%%
%% API Functions
%%
init(RankInfo) ->
    RankSize = RankInfo#p_ranking.capacity,
    init2(RankSize,1),
    init2(RankSize,2),
    init2(RankSize,3).
  

rank() ->
    rank2(1),
    rank2(2),
    rank2(3).


update({add,Change,RoleID,RoleName,Level,Exp,FactionID,FamilyName}) ->
    
    case ranking_minheap:key_find({?MODULE,FactionID},RoleID) of
        undefined ->
            %  ?DEBUG("family name = ~w",[FamilyName]),
            RoleLevelRank = #p_role_gongxun_rank{
                                                 role_id = RoleID,
                                                 level = Level,
                                                 exp = Exp,
                                                 gongxun = Change,
                                                 role_name = RoleName,
                                                 faction_id = FactionID, 
                                                 family_name = FamilyName},
            ranking_minheap:update_heap(RoleLevelRank,RoleID,?DB_ROLE_TODAY_GONGXUN_RANK_P,?MODULE,{?MODULE,FactionID});
        {Rank,_} ->
            % ?ERROR_MSG("~w",[Rank]),
            OldGongXun = Rank#p_role_gongxun_rank.gongxun,
            RoleLevelRank = Rank#p_role_gongxun_rank{gongxun=OldGongXun+Change},
            ranking_minheap:update_heap(RoleLevelRank,RoleID,?DB_ROLE_TODAY_GONGXUN_RANK_P,?MODULE,{?MODULE,FactionID})
    end;
update({reduce,Change,RoleID}) ->
    case db:dirty_read(?DB_ROLE_BASE,RoleID) of
        [] ->
            ignore;
        [#p_role_base{faction_id = FactionID}] ->
            case ranking_minheap:key_find({?MODULE,FactionID},RoleID) of
                undefined ->
                    ignore;
                {Rank,_} ->
                    OldGongXun = Rank#p_role_gongxun_rank.gongxun,
                    RoleLevelRank = Rank#p_role_gongxun_rank{gongxun=OldGongXun-Change},
                    ranking_minheap:update_heap(RoleLevelRank,RoleID,?DB_ROLE_TODAY_GONGXUN_RANK_P,?MODULE,{?MODULE,FactionID})
            end
    end.

send_ranking_info(Unique, Module, Method, RoleID, PID, RankID)->
	case common_misc:get_dirty_role_base(RoleID) of
		{ok,RoleBase} ->
			FactionID = RoleBase#p_role_base.faction_id,
			case get({{?MODULE,FactionID},ranking_info_list}) of
				undefined ->
					RankRows = [];
				RoleRankList ->
					RankRows = transform_row(RoleRankList)
			end,
			R2 = #m_ranking_get_rank_toc{rank_id=RankID,rows=RankRows},
			?UNICAST_TOC(R2);
		_ ->
			ignore
	end.

transform_row(undefined)->
    [];
transform_row(RoleRankList) when is_list(RoleRankList)->
    [ transform_row(Rec) ||Rec<-RoleRankList];
transform_row(Rec)->
    #p_role_gongxun_rank{ranking=Ranking,role_id=RoleID,role_name=RoleName,family_name=FamilyName,
                         level=Level,gongxun=Score,title=Title} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,FamilyName,common_tool:to_list(Level),  
                          common_tool:to_list(Score), Title
                         ]}.


get_role_rank(RoleID) ->
    case db:dirty_read(?DB_ROLE_TODAY_GONGXUN_RANK_P,RoleID) of
        [] ->
            undefined;
        [RoleLevelRank] ->
            #p_role_gongxun_rank{gongxun = GongXun,ranking = Rank} = RoleLevelRank,
            #p_role_all_rank{ int_key_value=GongXun, ranking = Rank}
    end.
   

cmp(E1,E2) ->
    ranking_role_gongxun:cmp(E1,E2).

%%
%% Local Functions
%%
init2(RankSize,FactionID) ->
    RoleRankList = db:dirty_match_object(?DB_ROLE_TODAY_GONGXUN_RANK_P,#p_role_gongxun_rank{faction_id = FactionID, _ = '_'}),
    rank2(FactionID),
    NewList = lists:foldr(
                fun(RoleGongXunRank,Acc) -> 
                        [{RoleGongXunRank,RoleGongXunRank#p_role_gongxun_rank.role_id}|Acc]
                end,[],RoleRankList),
    ranking_minheap:new_heap(?MODULE,{?MODULE,FactionID},RankSize,NewList).
                    

rank2(FactionID) ->
    List = db:dirty_match_object(?DB_ROLE_TODAY_GONGXUN_RANK_P,#p_role_gongxun_rank{faction_id = FactionID, _ = '_'}),
    List2 = lists:foldr(
              fun(RoleGongXunRank,Acc) ->
                      GongXun = RoleGongXunRank#p_role_gongxun_rank.gongxun,
                      case GongXun > 0 of
                          true ->
                              [RoleGongXunRank|Acc];
                          false ->
                              db:dirty_delete_object(?DB_ROLE_TODAY_GONGXUN_RANK_P,RoleGongXunRank),
                              Acc 
                      end
              end,[],List),
    List3 = lists:sort(fun(E1,E2) -> cmp(E1,E2) end,List2),
    {H,M,_} = erlang:time(),
    %%判断在凌晨12点刷新时清空当天的榜并保存到昨天的榜上
    case (H =:= 23 andalso M > 55) orelse (H =:= 0 andalso M < 5)  of
        true ->
             {_,List4} = lists:foldl(
                          fun(RoleGongXunRank,{Rank,Acc}) ->
                                  NewRoleGongXunRank = RoleGongXunRank#p_role_gongxun_rank{ranking = Rank},
                                  {Rank-1,[NewRoleGongXunRank|Acc]}
                          end,{length(List3),[]},List3),
            lists:foreach(fun(Obj) -> db:dirty_delete_object(?DB_ROLE_TODAY_GONGXUN_RANK_P,Obj) end,List),
            put({{?MODULE,FactionID},ranking_info_list},[]),
            ranking_role_yesterday_gongxun:update(List4,FactionID),
            case ranking_minheap:get_max_heap_size({?MODULE,FactionID}) of
                undefined ->
                    ignore;
                RankSize ->  
                    ranking_minheap:clear_heap({?MODULE,FactionID}),
                    ranking_minheap:new_heap({?MODULE,FactionID},RankSize)
            end;
        false ->
            {_,List4} = lists:foldl(
                          fun(RoleGongXunRank,{Rank,Acc}) ->
                                  NewRoleGongXunRank = RoleGongXunRank#p_role_gongxun_rank{ranking = Rank},
                                  db:dirty_write(?DB_ROLE_TODAY_GONGXUN_RANK_P,NewRoleGongXunRank),
                                  {Rank-1,[NewRoleGongXunRank|Acc]}
                          end,{length(List3),[]},List3),
            put({{?MODULE,FactionID},ranking_info_list},List4),
            case ranking_minheap:get_max_heap_size({?MODULE,FactionID}) of
                undefined ->
                    ignore;
                RankSize ->
                    ranking_minheap:clear_heap({?MODULE,FactionID}),
                    NewList = lists:foldr(
                                fun(RoleGongXunRank2,Acc2) -> 
                                        [{RoleGongXunRank2,RoleGongXunRank2#p_role_gongxun_rank.role_id}|Acc2]
                                end,[],List4),
                    ranking_minheap:new_heap(?MODULE,{?MODULE,FactionID},RankSize,NewList)
            end
    end.

  
