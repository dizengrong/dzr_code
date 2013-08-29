%%% -------------------------------------------------------------------
%%% Author  : liuwei
%%% Description :角色等级排行榜
%%% 
%%% Created : 2010-10-9
%%% -------------------------------------------------------------------
-module(ranking_family_active).

-include("mgeew.hrl").


-export([
         init/1,
         rank/0,
         send_ranking_info/6,
         do_rank_activity/0,
		get_rank/0
        ]).

%%
%%================API FUCTION=======================
%%
init(_RankInfo) ->
    put({?MODULE,ranking_info_list},[]),
    rank().


rank() ->
    Sql = io_lib:format("select family_id,family_name,faction_id,owner_role_name,level,cur_members,active_points from t_family_summary order by level desc, active_points desc, cur_members desc, family_id asc limit 50",[]),
    case mod_mysql:select(Sql) of
        {ok, FamilyRankListTmp} ->
            {_,FamilyRankList} = lists:foldr(
                               fun([FID,FName,FactionID,RoleName,Level,Members,Active],{Rank,Acc}) ->
                                       FamilyActiveRank=#p_family_active_rank{
                                         family_id=FID, 
                                         family_name=FName, 
                                         owner_role_name=RoleName, 
                                         level=Level,
                                         ranking = Rank,
                                         member_count = Members,
                                         faction_id = FactionID,
                                         active = Active},
                                       {Rank-1,[FamilyActiveRank|Acc]}
                               end,{length(FamilyRankListTmp),[]},FamilyRankListTmp),
            put({?MODULE,ranking_info_list},FamilyRankList);
        _ ->
            ?INFO_MSG("mysql read family data error",[])
    end.

get_rank() ->
	case get({?MODULE,ranking_info_list}) of
        undefined->
            [];
        RoleRankList ->
            RoleRankList
    end.

send_ranking_info(Unique, Module, Method, _RoleID, PID, RankID)->
    case get({?MODULE,ranking_info_list}) of
        undefined->
            RankRows = [];
        RoleRankList ->
            RankRows = transform_row(RoleRankList)
    end,
    R2 = #m_ranking_get_rank_toc{rank_id=RankID,rows=RankRows},
    ?UNICAST_TOC(R2).

transform_row(undefined)->
    [];
transform_row(RoleRankList) when is_list(RoleRankList)->
    [ transform_row(Rec) ||Rec<-RoleRankList];
transform_row(Rec)->
    #p_family_active_rank{ranking=Ranking,family_id=FamilyId,family_name=FName,level=Level,owner_role_name=OwnerName,
                          active=Active,faction_id = FactionId  } = Rec,
    #p_rank_row{row_id=Ranking,
                elements=[FName,common_tool:to_list(Level),OwnerName,common_tool:to_list(Active),
                          common_misc:get_faction_name(FactionId)],
                int_list=[FamilyId]}.

do_rank_activity() ->
    ignore.
