%% Author: Administrator
%% Created: 2011-2-23
%% Description: TODO: rewrite ranking_flowers
-module(ranking_rece_flowers).
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
%%===================== API Functions =========================
%%

init(RankInfo) ->
    RankSize = RankInfo#p_ranking.capacity,
    case db:dirty_match_object(?DB_ROLE_RECE_FLOWERS_RANK_P,#p_role_rece_flowers_rank{_='_'}) of
        []->
            init_rank_data(RankSize);
        RoleRankList1 ->
            RoleRankList2 = rank2(RoleRankList1),
            common_title_srv:add_title(?TITLE_ROLE_RECE_FLOWERS,0,RoleRankList2),
            NewList = lists:foldr(
                        fun(RoleRank2,Acc2)->
                                [{RoleRank2,RoleRank2#p_role_rece_flowers_rank.role_id}|Acc2] 
                        end,[],RoleRankList2),
            ranking_minheap:new_heap(?MODULE,?MODULE,RankSize,NewList)
    end.

rank()->
    List1 = db:dirty_match_object(?DB_ROLE_RECE_FLOWERS_RANK_P,#p_role_rece_flowers_rank{_ = '_'}),
    List2 = rank2(List1),
    common_title_srv:add_title(?TITLE_ROLE_RECE_FLOWERS,0,List2).     

update({RoleBase,RoleAttr})->
    #p_role_base{role_id=RoleID,role_name=RoleName,sex=Sex,faction_id=FactionID,
                 family_id=FamilyID,family_name=FamilyName}= RoleBase,
    #p_role_attr{level=Level,charm=Charm} = RoleAttr,
    update({RoleID,RoleName,Sex,Level,FactionID,FamilyID,FamilyName,Charm});
update({RoleID,RoleName,Sex,Level,FactionID,FamilyID,FamilyName,Charm})
  when Sex =:= 2 andalso Charm>0 ->
    RoleRank = 
        #p_role_rece_flowers_rank{role_id = RoleID,
                                  role_name = RoleName,
                                  level = Level,
                                  charm = Charm,
                                  faction_id = FactionID,
                                  family_id = FamilyID,
                                  family_name = FamilyName},
    ranking_minheap:update_heap(RoleRank,RoleID,?DB_ROLE_RECE_FLOWERS_RANK_P,?MODULE,?MODULE);

%% 变性后删除数据
update({RoleID,_,_Sex,_Level,_,_,_,_})->
    ranking_minheap:delete(?MODULE,?MODULE,RoleID),
    db:dirty_delete(?DB_ROLE_RECE_FLOWERS_RANK_P,RoleID);
update(_)->
    ignore.

cmp(RoleRank1,RoleRank2) ->
    #p_role_rece_flowers_rank{role_id = RoleID1,level = Level1,charm = Charm1} = RoleRank1,
    #p_role_rece_flowers_rank{role_id = RoleID2,level = Level2,charm = Charm2} = RoleRank2,
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
    #p_role_rece_flowers_rank{ranking=Ranking,role_id=RoleID,role_name=RoleName,family_id=FamilyId,
                                        family_name=FamilyName,faction_id=FactionId,charm=Score,title=Title} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,common_tool:to_list(Score),FamilyName,
                          common_misc:get_faction_name(FactionId), Title],
                int_list=[FamilyId]}.

get_role_rank(RoleID) ->
    RoleRankList = get({?MODULE,ranking_info_list}),
    case lists:keyfind(RoleID,#p_role_rece_flowers_rank.role_id,RoleRankList) of
        false ->
            undefined;
        RoleRank ->
            #p_role_rece_flowers_rank{ranking = Rank,charm = Charm} = RoleRank,
            #p_role_all_rank{int_key_value=Charm, ranking = Rank}
    end.
%%
%%====================== Local Functions =======================
%%

%% 从用户信息表中读数据
init_rank_data(RankSize)->
    ranking_minheap:new_heap(?MODULE,RankSize),
    case db:dirty_match_object(?DB_ROLE_BASE,#p_role_base{sex = 2, _ = '_'}) of
        []->
            put({?MODULE,ranking_info_list},[]);
        List->
            lists:foreach(
              fun(RoleBase) ->
                   {ok,RoleAttr} = common_misc:get_dirty_role_attr(RoleBase#p_role_base.role_id),
                   update({RoleBase,RoleAttr})
              end,List)
    end,
    rank().

rank2(List1)->
    List2 = delete_unactivity_from_rank_list(List1),
    List3 = lists:sort(fun(E1,E2) -> cmp(E1,E2) end,List2),
    {_,List4} = lists:foldl(
                    fun(RoleRank,{Rank,Acc})->
                        TitleName = common_title:get_title_name_of_rank(?TITLE_ROLE_RECE_FLOWERS,Rank),
                        {Rank-1,[RoleRank#p_role_rece_flowers_rank{ranking = Rank, title=TitleName}|Acc]}
                    end,{length(List3),[]},List3),
    put({?MODULE,ranking_info_list},List4),
    case ranking_minheap:get_max_heap_size(?MODULE) of
        undefined ->
            ignore;
        RankSize ->
            ranking_minheap:clear_heap(?MODULE),
            NewList = lists:foldr(
                        fun(RoleRank2,Acc2)->
                                [{RoleRank2,RoleRank2#p_role_rece_flowers_rank.role_id}|Acc2] 
                        end,[],List4),
            ranking_minheap:new_heap(?MODULE,?MODULE,RankSize,NewList)
    end,
    List4.

%%每天凌晨0点刷新排行榜的时候清除1个月内没有登录的玩家
delete_unactivity_from_rank_list(List) ->
    {H,_M,_S} = erlang:time(),
    case H =:= 0 of
        true ->
            ?DEBUG("CLEAN RECE FLOWERS~n",[]),
            Now = common_tool:now(),
            lists:foldr(
              fun(RoleLevelRank,Acc) ->
                      RoleID = RoleLevelRank#p_role_rece_flowers_rank.role_id,
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
    