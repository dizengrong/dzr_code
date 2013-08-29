%% Author: liuwei
%% Created: 2010-12-17
%% Description: 昨日护国英雄榜
-module(ranking_role_yesterday_gongxun).

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
         send_ranking_info/6,
         get_role_rank/1,
         update/2,
         do_rank_activity/0
        ]).

%%
%% API Functions
%%
init(_RankInfo) ->
    init2(1),
    init2(2),
    init2(3).

rank() ->
    ignore.

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
            nil
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
    case db:dirty_read(?DB_ROLE_YESTERDAY_GONGXUN_RANK_P,RoleID) of
        [] ->
            undefined;
        [RoleLevelRank] ->
            #p_role_gongxun_rank{gongxun = GongXun,ranking = Rank} = RoleLevelRank,
            #p_role_all_rank{ int_key_value=GongXun, ranking = Rank}
    end.
   

update(RoleGongXunRankList,FactionID) ->
    OldRoleRankList = db:dirty_match_object(?DB_ROLE_YESTERDAY_GONGXUN_RANK_P,#p_role_gongxun_rank{faction_id = FactionID, _ = '_'}),
    lists:foreach(fun(OldRank) -> db:dirty_delete_object(?DB_ROLE_YESTERDAY_GONGXUN_RANK_P,OldRank) end, OldRoleRankList),
    lists:foreach(fun(Rank) -> db:dirty_write(?DB_ROLE_YESTERDAY_GONGXUN_RANK_P,Rank) end, RoleGongXunRankList),
    put({{?MODULE,FactionID},ranking_info_list},RoleGongXunRankList).

    

%%
%% Local Functions
%%

init2(FactionID) ->
    RoleRankList = db:dirty_match_object(?DB_ROLE_YESTERDAY_GONGXUN_RANK_P,#p_role_gongxun_rank{faction_id = FactionID, _ = '_'}),
  %  ?ERROR_MSG("^^^^^^^^^^^^  ~w   ~w",[RoleRankList,FactionID]),
    put({{?MODULE,FactionID},ranking_info_list},RoleRankList).

do_rank_activity() ->
    ignore.
