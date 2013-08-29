%%% -------------------------------------------------------------------
%%% Author  : liuwei
%%% Description :角色等级排行榜
%%% 
%%% Created : 2010-10-9
%%% -------------------------------------------------------------------
-module(ranking_role_pkpoint).

-include("mgeew.hrl").


-export([
         init/1,
         rank/0,
         update/1,
         cmp/2,
         send_ranking_info/6,
         get_role_rank/1
        ]).
%%
%%================API FUCTION=======================
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


update(RoleBase) when is_record(RoleBase,p_role_base) ->
    #p_role_base{role_id=RoleID,role_name=RoleName,faction_id=FactionID,
                 pk_points = PkPoint,family_name=FamilyName}= RoleBase,
    update({RoleID,RoleName,PkPoint,FactionID,FamilyName});
update({RoleID,RoleName,PkPoint,FactionID,FamilyName}) ->
    RolePkPointRank = #p_role_pkpoint_rank{
                                           role_id = RoleID,
                                           pk_points = PkPoint,
                                           role_name = RoleName,
                                           faction_id = FactionID, 
                                           family_name = FamilyName},
    ranking_minheap:update_heap(RolePkPointRank,RoleID,?DB_ROLE_PKPOINT_RANK_P,?MODULE,{?MODULE,FactionID}).


cmp(RolePkPointRank1, RolePkPointRank2) ->
    ?DEBUG(" ~w     ~w",[RolePkPointRank1, RolePkPointRank2]),
    #p_role_pkpoint_rank{pk_points = PkPoint1, role_id = RoleID1} = RolePkPointRank1,
    #p_role_pkpoint_rank{pk_points = PkPoint2, role_id = RoleID2} = RolePkPointRank2,
    mgeew_ranking:cmp([{PkPoint1,PkPoint2},{RoleID1,RoleID2}]).     

send_ranking_info(Unique, Module, Method, RoleID, PID, RankID)->
    case common_misc:get_dirty_role_base(RoleID) of
        {ok,RoleBase} ->
            FactionID = RoleBase#p_role_base.faction_id,
            RoleRankList =  get({{?MODULE,FactionID},ranking_info_list}),
            
            RankRows = transform_row(RoleRankList),
            R2 = #m_ranking_get_rank_toc{rank_id=RankID,rows=RankRows},
            ?UNICAST_TOC(R2);
        _ ->
            nil
    end.

transform_row(undefined)->
    [];
transform_row(RoleRankList) when is_list(RoleRankList)->
    [ transform_row(Rec) ||Rec<-RoleRankList];
transform_row(Rec)->
    #p_role_pkpoint_rank{ranking=Ranking,role_id=RoleID,role_name=RoleName,family_name=FmlName,pk_points = PKPoint,title=Title} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,FmlName,common_tool:to_list(PKPoint),Title
                         ]}.


get_role_rank(RoleID) ->
    case db:dirty_read(?DB_ROLE_PKPOINT_RANK_P,RoleID) of
        [] ->
            undefined;
        [RoleLevelRank] ->
            #p_role_pkpoint_rank{pk_points = PKPoint,ranking = Rank} = RoleLevelRank,
            #p_role_all_rank{ int_key_value=PKPoint, ranking = Rank}
    end.
   
%%
%%================LOCAL FUCTION=======================
%%
read_rank_data(RankSize,FactionID) ->
    ranking_minheap:new_heap({?MODULE,FactionID}, RankSize),
    case db:dirty_match_object(?DB_ROLE_BASE,#p_role_base{faction_id = FactionID, _ = '_'}) of
        [] ->
            nil;
        List -> 
            lists:foreach(fun(RoleBase) -> update(RoleBase) end,List)
    end,
    rank().
    

init2(RankSize,FactionID) ->
    case db:dirty_match_object(?DB_ROLE_PKPOINT_RANK_P,#p_role_pkpoint_rank{faction_id = FactionID, _ = '_'}) of
        [] ->
            read_rank_data(RankSize,FactionID);
        RoleRankList ->
            rank2(FactionID),
            NewList = lists:foldr(
                        fun(RolePkPointRank,Acc) -> 
                                [{RolePkPointRank,RolePkPointRank#p_role_pkpoint_rank.role_id}|Acc]
                        end,[],RoleRankList),
            ranking_minheap:new_heap(?MODULE,{?MODULE,FactionID},RankSize,NewList)
    end.
                    

rank2(FactionID) ->
    List = db:dirty_match_object(?DB_ROLE_PKPOINT_RANK_P,#p_role_pkpoint_rank{faction_id = FactionID, _ = '_'}),
	TmpList = delete_unactivity_from_rank_list(List),
    List2 = lists:foldr(
              fun(RolePkPointRank,Acc) ->
                      RoleID = RolePkPointRank#p_role_pkpoint_rank.role_id,
                      case common_misc:get_dirty_role_base(RoleID) of
                          {ok,RoleBase} ->
                              NewFamilyName =  RoleBase#p_role_base.family_name,
                              NewPkPoint = RoleBase#p_role_base.pk_points;
                          _ ->
                              NewFamilyName = "null",
                              NewPkPoint = 0
                      end,
                      %%PK值少于18的不列入恶人榜
                      case NewPkPoint >= 18 of
                          true ->
                              NewRolePkPointRank = RolePkPointRank#p_role_pkpoint_rank{pk_points = NewPkPoint,family_name = NewFamilyName},
                              [NewRolePkPointRank|Acc];
                          false ->
                              db:dirty_delete_object(?DB_ROLE_PKPOINT_RANK_P,RolePkPointRank),
                              Acc
                      end
              end,[],TmpList),
    ?DEBUG("~w",[List2]),
    List3 = lists:sort(fun(E1,E2) -> cmp(E1,E2) end,List2),
	ListWorldPkPointRank=get({ranking_role_world_pkpoint,ranking_info_list}),
	?DEBUG("ListWorldPkPointRank:~w~n",[ListWorldPkPointRank]),
    {_,List4} = lists:foldl(
              fun(RolePkPointRank,{Rank,Acc}) ->
					  Title = get_role_pkpoint_rank_title(ListWorldPkPointRank,RolePkPointRank#p_role_pkpoint_rank.role_id),
                      NewRolePkPointRank = RolePkPointRank#p_role_pkpoint_rank{ranking = Rank, title = Title},
                      db:dirty_write(?DB_ROLE_PKPOINT_RANK_P,NewRolePkPointRank),
                      {Rank-1,[NewRolePkPointRank|Acc]}
              end,{length(List3),[]},List3),
    put({{?MODULE,FactionID},ranking_info_list},List4),
    
    case  ranking_minheap:get_max_heap_size({?MODULE,FactionID}) of
        undefined ->
            ignore;
        RankSize ->       
            ranking_minheap:clear_heap({?MODULE,FactionID}),
            NewList = lists:foldr(
                        fun(RolePkPointRank2,Acc2) -> 
                                [{RolePkPointRank2,RolePkPointRank2#p_role_pkpoint_rank.role_id}|Acc2]
                        end,[],List4),
            ranking_minheap:new_heap(?MODULE,{?MODULE,FactionID},RankSize,NewList)
    end.

get_role_pkpoint_rank_title(undefined,_RoleID)->
    "";
get_role_pkpoint_rank_title([],_RoleID)->
    "";
get_role_pkpoint_rank_title(ListWorldPkPointRank,RoleID)->
	case lists:keyfind(RoleID,#p_role_pkpoint_rank.role_id,ListWorldPkPointRank) of
		false->
			"";
		WorldPkPointRecord->
			?DEBUG("title ~w~n",[WorldPkPointRecord#p_role_pkpoint_rank.title]),
			WorldPkPointRecord#p_role_pkpoint_rank.title
	end.
   
delete_unactivity_from_rank_list(List) ->
    {H,_M,_S} = erlang:time(),
    %%每天凌晨4点刷新排行榜的时候清除1个月内没有登录的玩家
    case H =:= 4 of
        true ->
            Now = common_tool:now(),
            lists:foldr(
              fun(RoleLevelRank,Acc) ->
                      RoleID = RoleLevelRank#p_role_pkpoint_rank.role_id,
                      case db:dirty_read(db_role_ext,RoleID) of
                          [] ->
                              Acc;
                          [RoleExt] ->
                              LastOfflineTime = RoleExt#p_role_ext.last_offline_time,
                              
                              case LastOfflineTime =:= undefined 
                                       orelse Now - LastOfflineTime < 2592000 of
                                  true ->
                                      [RoleLevelRank|Acc];
                                  false ->
                                      Acc
                              end
                      end
              end,[],List);
        false ->
            List
    end.


