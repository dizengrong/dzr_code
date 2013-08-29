%%% -------------------------------------------------------------------
%%% Author  : liuwei
%%% Description :角色等级排行榜
%%% 
%%% Created : 2010-10-9
%%% -------------------------------------------------------------------
-module(ranking_role_gongxun).

-include("mgeew.hrl").


-export([
         init/1,
         rank/0,
         update/1,
         cmp/2,
         send_ranking_info/6,
         get_role_rank/1,
         do_rank_activity/0
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
    List1 = rank2(1),
    List2 = rank2(2),
    List3 = rank2(3),
    List4 = lists:append([List1, List2, List3]),
    common_title_srv:add_title(?TITLE_ROLE_GONGXUN_RANK,0,List4).

update({RoleBase,RoleAttr}) ->
    #p_role_base{role_id=RoleID,role_name=RoleName,faction_id=FactionID,
                 family_name=FamilyName}= RoleBase,
    #p_role_attr{level=Level,exp=Exp,gongxun=GongXun} = RoleAttr,
    update({RoleID,RoleName,Level,Exp,GongXun,FactionID,FamilyName});
update({RoleID,RoleName,Level,Exp,GongXun,FactionID,FamilyName}) ->
    RoleLevelRank = #p_role_gongxun_rank{
                                         role_id = RoleID,
                                         level = Level,
                                         exp = Exp,
                                         gongxun = GongXun,
                                         role_name = RoleName,
                                         faction_id = FactionID, 
                                         family_name = FamilyName},
    ranking_minheap:update_heap(RoleLevelRank,RoleID,?DB_ROLE_GONGXUN_RANK_P,?MODULE,{?MODULE,FactionID}). 


cmp(RoleGongXunRank1, RoleGongXunRank2) ->
    ?DEBUG(" ~w     ~w",[RoleGongXunRank1, RoleGongXunRank2]),
    #p_role_gongxun_rank{gongxun = GongXun1,level =Level1, exp = Exp1, role_id = RoleID1, ranking=Rank1} = RoleGongXunRank1,
    #p_role_gongxun_rank{gongxun = GongXun2,level =Level2, exp = Exp2, role_id = RoleID2, ranking=Rank2} = RoleGongXunRank2,
    NewRank1 =case Rank1 of
                  undefined->999;
                  _->Rank1
              end,
    NewRank2 = case Rank2 of
                   undefined->999;
                   _->Rank2
               end,
    mgeew_ranking:cmp([{GongXun1,GongXun2},{Level1,Level2},{Exp1,Exp2},{NewRank2,NewRank1},{RoleID1,RoleID2}]).     


send_ranking_info(Unique, Module, Method, RoleID, PID, RankID)->
	case common_misc:get_dirty_role_base(RoleID) of
		{ok,RoleBase} ->
			FactionID = RoleBase#p_role_base.faction_id,
			case get({{?MODULE,FactionID},ranking_info_list}) of
				undefined->
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
    case db:dirty_read(?DB_ROLE_GONGXUN_RANK_P,RoleID) of
        [] ->
            undefined;
        [RoleLevelRank] ->
            #p_role_gongxun_rank{gongxun = GongXun,ranking = Rank} = RoleLevelRank,
            #p_role_all_rank{ int_key_value=GongXun, ranking = Rank}
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
          
            lists:foreach(
              fun(RoleBase) -> 
                      {ok,RoleAttr} = common_misc:get_dirty_role_attr(RoleBase#p_role_base.role_id),
                      update({RoleBase,RoleAttr})
              end,List)
    end,
    rank().
    

init2(RankSize,FactionID) ->
    case db:dirty_match_object(?DB_ROLE_GONGXUN_RANK_P,#p_role_gongxun_rank{faction_id = FactionID, _ = '_'}) of
        [] ->
            read_rank_data(RankSize,FactionID);
        RoleRankList ->
            rank2(FactionID),
            NewList = lists:foldr(
                        fun(RoleGongXunRank,Acc) -> 
                                [{RoleGongXunRank,RoleGongXunRank#p_role_gongxun_rank.role_id}|Acc]
                        end,[],RoleRankList),
            ranking_minheap:new_heap(?MODULE,{?MODULE,FactionID},RankSize,NewList)
    end.
                    

rank2(FactionID) ->
    List = db:dirty_match_object(?DB_ROLE_GONGXUN_RANK_P,#p_role_gongxun_rank{faction_id = FactionID, _ = '_'}),
	TempList = delete_unactivity_from_rank_list(List),
    List2 = lists:foldr(
              fun(RoleGongXunRank,Acc) ->
                      RoleID = RoleGongXunRank#p_role_gongxun_rank.role_id,
                      case common_misc:get_dirty_role_base(RoleID) of
                          {ok,RoleBase} ->
                              NewFamilyName =  RoleBase#p_role_base.family_name,
                              {ok,RoleAttr} = common_misc:get_dirty_role_attr(RoleID),
                              NewLevel = RoleAttr#p_role_attr.level,
                              NewExp = RoleAttr#p_role_attr.exp,
                              NewGongXun = RoleAttr#p_role_attr.gongxun,
                              case NewGongXun > 0 of
                                  true ->
                                      NewRoleGongXunRank = RoleGongXunRank#p_role_gongxun_rank{
                                                             gongxun = NewGongXun,
                                                             family_name = NewFamilyName,
                                                             level = NewLevel, 
                                                             exp = NewExp},
                                      [NewRoleGongXunRank|Acc];
                                  false ->
                                      db:dirty_delete_object(?DB_ROLE_GONGXUN_RANK_P,RoleGongXunRank),
                                      Acc       
                              end;
                          _ ->
                              db:dirty_delete_object(?DB_ROLE_GONGXUN_RANK_P,RoleGongXunRank),
                              Acc       
                      end
              end,[],TempList),
    ?DEBUG("~w",[List2]),
    List3 = lists:sort(fun(E1,E2) -> cmp(E1,E2) end,List2),
    {_,List4} = lists:foldl(
              fun(RoleGongXunRank,{Rank,Acc}) ->
                      TitleName = common_title:get_title_name_of_rank(?TITLE_ROLE_GONGXUN_RANK,Rank),
                      NewRoleGongXunRank = RoleGongXunRank#p_role_gongxun_rank{ranking = Rank,title=TitleName},
                      db:dirty_write(?DB_ROLE_GONGXUN_RANK_P,NewRoleGongXunRank),
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
    end,
   
    List4.

delete_unactivity_from_rank_list(List) ->
    {H,_M,_S} = erlang:time(),
    %%每天凌晨4点刷新排行榜的时候清除1个月内没有登录的玩家
    case H =:= 4 of
        true ->
            Now = common_tool:now(),
            lists:foldr(
              fun(RoleLevelRank,Acc) ->
                      RoleID = RoleLevelRank#p_role_gongxun_rank.role_id,
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

do_rank_activity() ->
    ignore.
