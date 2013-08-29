%%% -------------------------------------------------------------------
%%% Author  : liuwei
%%% Description :角色等级排行榜
%%% 
%%% Created : 2010-10-9
%%% -------------------------------------------------------------------
-module(ranking_equip_reinforce).

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
    ranking_equip_refining:init2(RankInfo,?MODULE,?DB_EQUIP_REINFORCE_RANK_P,fun(E1,E2) -> cmp(E1,E2) end).
 


rank() ->
    ranking_equip_refining:rank2(?MODULE,?DB_EQUIP_REINFORCE_RANK_P,fun(E1,E2) -> cmp(E1,E2) end).


update({GoodsInfo,RoleID}) ->
    ranking_equip_refining:update2({GoodsInfo,RoleID},?MODULE,?DB_EQUIP_REINFORCE_RANK_P,fun(E1,E2) -> cmp(E1,E2) end).
  

cmp(EquipReinforceRank1, EquipReinforceRank2) ->
    ?DEBUG(" ~w     ~w",[EquipReinforceRank1, EquipReinforceRank2]),
    #p_equip_rank{reinforce_score = Reinforce1,stone_score = Stone1,quality = Quality1,colour = Colour1} = EquipReinforceRank1,
    #p_equip_rank{reinforce_score = Reinforce2,stone_score = Stone2,quality = Quality2,colour = Colour2} = EquipReinforceRank2,
    mgeew_ranking:cmp([{Reinforce1,Reinforce2},{Stone1,Stone2},{Quality1,Quality2},{Colour1,Colour2}]).

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
    #p_equip_rank{ranking=Ranking,type_id=TypeId,colour=Color,quality=Quality,goods_id=GoodsId,
                  role_id=RoleID,role_name=RoleName,faction_id=FactionId,reinforce_score=Score} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,"",common_misc:get_faction_name(FactionId),  
                          common_tool:to_list(Score)],
                int_list=[TypeId,Color,Quality,GoodsId]}.
   
get_role_rank(RoleID) ->
    case db:dirty_match_object(?DB_EQUIP_REINFORCE_RANK_P,#p_equip_rank{role_id = RoleID,_='_'}) of
        [] ->
            undefined;
        EquipRankList ->
            lists:foldr( 
              fun(EquipRank,Acc) ->
                      #p_equip_rank{reinforce_score = Score,ranking = Rank} = EquipRank,
                      RoleRank = #p_role_all_rank{ int_key_value=Score, ranking = Rank},
                      [RoleRank|Acc]
              end,[],EquipRankList)
    end.

do_rank_activity()->
    List1 = get({?MODULE,ranking_info_list}),
    List2 = 
        lists:foldl(
          fun(RankInfo,TmpList)->
                  RoleID = RankInfo#p_equip_rank.role_id,
                  Ranking = RankInfo#p_equip_rank.ranking,
                  case lists:keyfind(1, RoleID, TmpList) of
                      {RoleID,OldRanking}->
                          case OldRanking=<Ranking of
                              true->TmpList;
                              false->[{RoleID,Ranking}|lists:delete({RoleID,OldRanking},List1)]
                          end;
                      false->[{RoleID,Ranking}|TmpList]
                  end
          end, [], List1),
    mgeew_ranking:send_ranking_activity(?RANK_EQUIP_REINFORCE_KEY,List2).
