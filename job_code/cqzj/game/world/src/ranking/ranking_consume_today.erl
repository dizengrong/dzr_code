%% Author: whs
%% Created: 2013-5-8
%% Description: TODO: Add description to ranking_xiangqian
-module(ranking_consume_today).

-include("mgeew.hrl").


-export([
         init/1,
         rank/0,
         update/1,
         cmp/2,
         send_ranking_info/6,
		 calc_total_score/1,
		 reset_consume_rank/0,
		 send_reward_letter/0
        ]).

%%
%%================API FUCTION=======================
%%
init(RankInfo) ->
	reset_consume_rank(RankInfo).

init2(RankInfo) ->
    init3(RankInfo,?MODULE,?DB_ROLE_CONSUME_TODAY_RANK_P,fun(E1,E2) -> cmp(E1,E2) end).
init3(RankInfo,ModuleName,DBName,CmpFun) ->
    RankSize = RankInfo#p_ranking.capacity,
    case get_rank_data() of
        [] ->
            read_rank_data(RankSize);
        _ ->
			ranking_minheap:new_heap(?MODULE,RankSize),
			rank2(ModuleName,DBName,CmpFun)
    end.

get_rank_data()->
    db:dirty_match_object(?DB_ROLE_CONSUME_TODAY_RANK_P,#p_role_consume_today_rank{_ = '_'}).

rank() ->
    rank2(?MODULE,?DB_ROLE_CONSUME_TODAY_RANK_P,fun(E1,E2) -> cmp(E1,E2) end).

rank2(ModuleName,DBName,CmpFun) ->
	List = db:dirty_match_object(DBName,#p_role_consume_today_rank{_ = '_'}),
	List1 = lists:sort(CmpFun,List),
	{_,List2} = lists:foldl(
				  fun(ConsumeTodayRank,{Rank,Acc}) ->
						  NewConsumeTodayRank = ConsumeTodayRank#p_role_consume_today_rank{ranking = Rank},
						  db:dirty_write(DBName,NewConsumeTodayRank),
						  {Rank-1,[NewConsumeTodayRank|Acc]}
				  end,{length(List1),[]},List1),
	put({ModuleName,ranking_info_list},List2),
	
	case ranking_minheap:get_max_heap_size(ModuleName) of
		undefined ->
			ignore;
		RankSize ->
			ranking_minheap:clear_heap(ModuleName),
			NewList = lists:foldr(
						fun(PetRank2,Acc2) -> 
								[{PetRank2,PetRank2#p_role_consume_today_rank.role_id}|Acc2]
						end,[],List2),
			ranking_minheap:new_heap(ModuleName,ModuleName,RankSize,NewList)
	end.


update({_RoleID,0,_Now}) ->
	ignore;
update({RoleID,Score,Now}) ->
	RoleConsumeTodayRank = #p_role_consume_today_rank{role_id=RoleID,
											   score=Score,
											   last_update_time = Now}, 
	ranking_minheap:update_heap(RoleConsumeTodayRank,RoleID,?DB_ROLE_CONSUME_TODAY_RANK_P,?MODULE,?MODULE);
update(_) ->
	ignore.

calc_total_score(UseGold) ->
	Score = UseGold * cfg_rank_score:consume_score(gold_unbind),
	Score.

cmp(RoleConsumeTodayRank1, RoleConsumeTodayRank2) ->
	#p_role_consume_today_rank{score=Score1,last_update_time = LastUpdateTime1,ranking = Rank1,role_id = RoleID1} = RoleConsumeTodayRank1,
	#p_role_consume_today_rank{score=Score2,last_update_time = LastUpdateTime2,ranking = Rank2,role_id = RoleID2} = RoleConsumeTodayRank2, 
    NewRank1 =case Rank1 of
                  undefined->999;
                  _->Rank1
              end,
    NewRank2 = case Rank2 of
                   undefined->999;
                   _->Rank2
               end,
    mgeew_ranking:cmp([{Score1,Score2},{LastUpdateTime2,LastUpdateTime1},{NewRank1,NewRank2},{RoleID2,RoleID1}]).


send_ranking_info(Unique, Module, Method, _RoleID, PID, RankID)->
    RoleConsumeTodayRankList = get({?MODULE,ranking_info_list}),
    RankRows = transform_row(RoleConsumeTodayRankList),
    R2 = #m_ranking_get_rank_toc{rank_id=RankID,rows=RankRows},
    ?UNICAST_TOC(R2).

transform_row(undefined)->
    [];
transform_row(RoleRankList) when is_list(RoleRankList)->
    [ transform_row(Rec) ||Rec<-RoleRankList];
transform_row(Rec)->
    #p_role_consume_today_rank{ranking=Ranking,role_id=RoleID,score=Score} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,elements=[common_tool:to_list(Score)]}.

%%重置今日排行榜数据
reset_consume_rank() ->
	{RankInfo,_} = get({rank_info,?CONSUME_TODAY_RANK_ID}),
	case get_rank_data() of
		[] ->
			ignore;
		_ ->
			mnesia:clear_table(?DB_ROLE_CONSUME_TODAY_RANK_P)
	end,
	init2(RankInfo).

reset_consume_rank(RankInfo) ->
	case get_rank_data() of
		[] ->
			ignore;
		_ ->
			mnesia:clear_table(?DB_ROLE_CONSUME_TODAY_RANK_P)
	end,
	init2(RankInfo).
%%
%%================LOCAL FUCTION=======================
%%
read_rank_data(RankSize) ->
	Today = erlang:date(),
	ranking_minheap:new_heap(?MODULE,RankSize),
	case db:dirty_match_object(?DB_ROLE_ACCGOLD,#r_role_accgold{_ = '_'}) of
		[] ->
			nil;
		List -> 
			lists:foreach(fun(#r_role_accgold{role_id=RoleID,consume_list=ConsumeList1,last_consume_time=LastConsumeTime})->
								  case lists:keyfind(Today, 1, ConsumeList1) of
									  false->
										  ignore;
									  {Today,UseGold}->
										  Score = calc_total_score(UseGold),
										  LimitScore = cfg_rank_score:socre_limit(?CONSUME_TODAY_RANK_ID),
										  case Score >= LimitScore of
											  true ->
												  update({RoleID,Score,LastConsumeTime});
											  _ ->
												  ignore
										  end
								  end
						  end,List)
	end,
	rank().


send_reward_letter() ->
	RoleRankList = get({?MODULE,ranking_info_list}),
	mod_rankreward_server:send_consume_reward_letter(?CONSUME_TODAY_RANK_ID,RoleRankList).
