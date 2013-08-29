%% Author: ldk
%% Created: 2012-8-22  等级排行总榜，不分职业
%% Description: TODO: Add description to ranking_role_level_all
-module(ranking_role_level_all).

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
		 rank/1,
		 send_ranking_info/6,
		 get_role_rank/1
		 ]).

%%
%% API Functions
%%
init(_RankInfo) ->
%%     RankSize = RankInfo#p_ranking.capacity,
	ignore.

rank() ->
	ignore.
rank(RankList) ->
    RankList2 = lists:sort(fun(E1,E2) -> cmp(E1,E2) end,RankList),
	RankList3 = lists:reverse(RankList2),
	{_,RankList4} = 
	lists:foldl(fun(RankData,Acc) ->
						{RankID,Ranks} = Acc,
						{RankID+1,lists:append(Ranks, [RankData#p_role_level_rank{ranking=RankID}])}
						end, {1,[]}, lists:sublist(RankList3, 50)),
	put({?MODULE,ranking_info_list},RankList4).
	
get_role_rank(RoleID) ->
	case get({?MODULE,ranking_info_list}) of
		undefined ->
			undefined;
		RoleRankList ->
			case lists:keyfind(RoleID, #p_role_level_rank.role_id, RoleRankList) of
				#p_role_level_rank{level = Level,ranking = Rank} ->
					#p_role_all_rank{ int_key_value=Level, ranking = Rank};
				_ ->
					undefined
			end
	end.

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
    #p_role_level_rank{ranking=Ranking,role_id=RoleID,role_name=RoleName,faction_id=FactionId,family_name=FamilyName,level=Level,category=Category} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,common_misc:get_faction_name(FactionId),FamilyName,
                          common_tool:to_list(Level),common_misc:get_category_name(Category)
                         ]}.

cmp(RoleLevelRank1, RoleLevelRank2) ->
    ?DEBUG(" ~w     ~w",[RoleLevelRank1, RoleLevelRank2]),
    #p_role_level_rank{level = Level1, exp = Exp1,  role_id = RoleID1} = RoleLevelRank1,
    #p_role_level_rank{level = Level2, exp = Exp2,  role_id = RoleID2} = RoleLevelRank2,
    mgeew_ranking:cmp([{Level1,Level2},{Exp1,Exp2},{RoleID2,RoleID1}]).
