%%% -------------------------------------------------------------------
%%% Author  : liuwei
%%% Description :角色等级排行榜
%%% 
%%% Created : 2010-10-9
%%% -------------------------------------------------------------------
-module(ranking_role_world_pkpoint).

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
    case db:dirty_match_object(?DB_ROLE_WORLD_PKPOINT_RANK_P,#p_role_pkpoint_rank{_ = '_'}) of
        [] ->
            read_rank_data(RankSize);
        RoleRankList ->
            rank(),
            NewList = lists:foldr(
                        fun(RoleWorldPkPointRank,Acc) -> 
                                [{RoleWorldPkPointRank,RoleWorldPkPointRank#p_role_pkpoint_rank.role_id}|Acc]
                        end,[],RoleRankList),
            ranking_minheap:new_heap(?MODULE,?MODULE,RankSize,NewList)
    end.


rank() ->
    List = db:dirty_match_object(?DB_ROLE_WORLD_PKPOINT_RANK_P,#p_role_pkpoint_rank{_ = '_'}),
	TmpList = delete_unactivity_from_rank_list(List),
    List2 = lists:foldr(
              fun(RoleWorldPkPointRank,Acc) ->
                      RoleID = RoleWorldPkPointRank#p_role_pkpoint_rank.role_id,
                      case common_misc:get_dirty_role_base(RoleID) of
                          {ok,RoleBase} ->
                              NewFamilyName =  RoleBase#p_role_base.family_name,
                              NewPkPoint = RoleBase#p_role_base.pk_points;
                          _ ->
                              NewFamilyName = "null",
                              NewPkPoint =  0
                      end,
                      %%PK值少于18的不列入恶人榜
                      case NewPkPoint >= 18 of
                          true ->
                              NewRoleWorldPkPointRank=RoleWorldPkPointRank#p_role_pkpoint_rank{pk_points=NewPkPoint,family_name=NewFamilyName},
                              [NewRoleWorldPkPointRank|Acc];
                          false ->
                              db:dirty_delete_object(?DB_ROLE_WORLD_PKPOINT_RANK_P,RoleWorldPkPointRank),
                              Acc
                      end
              end,[],TmpList),
    ?DEBUG("~w",[List2]),
    List3 = lists:sort(fun(E1,E2) -> cmp(E1,E2) end,List2),
    {_,List4} = lists:foldl(
              fun(RoleWorldPkPointRank,{Rank,Acc}) ->
                      TitleName = common_title:get_title_name_of_rank(?TITLE_WORLD_PKPOINT_RANK,Rank),
                      NewRoleWorldPkPointRank = RoleWorldPkPointRank#p_role_pkpoint_rank{ranking = Rank,title=TitleName},
                      db:dirty_write(?DB_ROLE_WORLD_PKPOINT_RANK_P,NewRoleWorldPkPointRank),
                      {Rank-1,[NewRoleWorldPkPointRank|Acc]}
              end,{length(List3),[]},List3),
    put({?MODULE,ranking_info_list},List4),
    
    case  ranking_minheap:get_max_heap_size(?MODULE) of
        undefined ->
            ignore;
        RankSize ->
            ranking_minheap:clear_heap(?MODULE),
            NewList = lists:foldr(
                        fun(RoleWorldPkPointRank2,Acc2) -> 
                                [{RoleWorldPkPointRank2,RoleWorldPkPointRank2#p_role_pkpoint_rank.role_id}|Acc2]
                        end,[],List4),
            ranking_minheap:new_heap(?MODULE,?MODULE,RankSize,NewList)
    end,
    common_title_srv:add_title(?TITLE_WORLD_PKPOINT_RANK,0,List4).
        
   
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
    ranking_minheap:update_heap(RolePkPointRank,RoleID,?DB_ROLE_WORLD_PKPOINT_RANK_P,?MODULE,?MODULE).  
 


cmp(RolePkPointRank1, RolePkPointRank2) ->
    ?DEBUG(" ~w     ~w",[RolePkPointRank1, RolePkPointRank2]),
    #p_role_pkpoint_rank{pk_points = PkPoint1, role_id = RoleID1} = RolePkPointRank1,
    #p_role_pkpoint_rank{pk_points = PkPoint2, role_id = RoleID2} = RolePkPointRank2,
    mgeew_ranking:cmp([{PkPoint1,PkPoint2},{RoleID1,RoleID2}]).

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
    #p_role_pkpoint_rank{ranking=Ranking,role_id=RoleID,role_name=RoleName,faction_id=FactionId,pk_points = PKPoint,title=Title} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,common_misc:get_faction_name(FactionId),common_tool:to_list(PKPoint),Title
                         ]}.

get_role_rank(RoleID) ->
    case db:dirty_read(?DB_ROLE_WORLD_PKPOINT_RANK_P,RoleID) of
        [] ->
            undefined;
        [RoleLevelRank] ->
            #p_role_pkpoint_rank{pk_points = PKPoint,ranking = Rank} = RoleLevelRank,
            #p_role_all_rank{ int_key_value=PKPoint, ranking = Rank}
    end.
%%
%%================LOCAL FUCTION=======================
%%
read_rank_data(RankSize) ->
    ranking_minheap:new_heap(?MODULE,RankSize),
    case db:dirty_match_object(?DB_ROLE_BASE,#p_role_base{_ = '_'}) of
        [] ->
            nil;
        List -> 
            lists:foreach(fun(RoleBase) -> update(RoleBase) end,List)
    end,
    rank().
    
                          
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

    
