%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2011, 
%%% @doc
%%%
%%% @end
%%% Created : 24 May 2011 by  <>
%%%-------------------------------------------------------------------
-module(ranking_hero_fb).

-include("mgeew.hrl").

-export([
         init/1,
         update/1,
         rank/0,
         send_ranking_info/6,
         get_role_rank/1]).

rank()->
    uncompleted.

init(_RankInfo) ->
    RecordList = db:dirty_match_object(?DB_HERO_FB_RECORD_P, #r_hero_fb_record{_='_'}),
    RecordList2 =
        lists:map(
          fun(#r_hero_fb_record{barrier_id=BarrierID, best_record=BestRecord}) ->
                  [#p_hero_fb_record{role_id=ID, role_name=RoleName,
                                     faction_id=FactionID, score=Score}|_] = BestRecord,
                  
                  #p_hero_fb_rank{ranking=BarrierID, barrier_id=BarrierID, role_id=ID,
                                  role_name=RoleName, faction_id=FactionID, score=Score}
          end, RecordList),
    RecordList3 = lists:keysort(#p_hero_fb_rank.barrier_id, RecordList2),
    put({?MODULE, ranking_info_list}, RecordList3).

update({BarrierID, Record}) ->
    #p_hero_fb_record{role_id=ID, role_name=RoleName,
                      faction_id=FactionID, score=Score} = Record,
    RankRecord = #p_hero_fb_rank{ranking=BarrierID, barrier_id=BarrierID, role_id=ID,
                                 role_name=RoleName, faction_id=FactionID, score=Score},
    
    RecordList = get({?MODULE, ranking_info_list}),
    RecordList2 = [RankRecord|lists:keydelete(BarrierID, #p_hero_fb_rank.barrier_id, RecordList)],
    RecordList3 = lists:keysort(#p_hero_fb_rank.barrier_id, RecordList2),
    {_,RecordList4} = lists:foldl(
          fun(E,AccIn)->
                  {Num,ListAcc} = AccIn,
                  List2 = [E#p_hero_fb_rank{ranking=Num}|ListAcc],
                  {Num-1,List2}
          end,{length(RecordList3),[]}, RecordList3),
    put({?MODULE, ranking_info_list}, RecordList4).

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
    #p_hero_fb_rank{ranking=Ranking,role_id=RoleID,role_name=RoleName,faction_id=FactionId,
                    barrier_id=BarrierId,score=Score} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,common_misc:get_faction_name(FactionId)],
                int_list=[BarrierId,Score]}.

get_role_rank(RoleID) ->
    get_role_rank_2(RoleID,get({?MODULE, ranking_info_list})).

get_role_rank_2(_RoleID,undefined)->
    undefined;
get_role_rank_2(RoleID,RecordList)->
    lists:foldl(
      fun(#p_hero_fb_rank{ranking=Ranking,barrier_id=BarrierId, role_id=RID}, Acc) ->
              case RoleID =:= RID of
                  true ->
                      [#p_role_all_rank{ int_key_value=get_barrier_name(BarrierId), ranking=Ranking}|Acc];
                  _ ->
                      Acc
              end
      end, [], RecordList).

%%@doc 根据BarrierId，获取对应是第几关
get_barrier_name(Id)->
    BarrierInfo = cfg_hero_fb:barrier_info(?HERO_FB_MODE_TYPE_NORMAL, Id),
    BarrierInfo#r_hero_fb_barrier_info.barrier.
