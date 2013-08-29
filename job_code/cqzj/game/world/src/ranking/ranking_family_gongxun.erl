%%% -------------------------------------------------------------------
%%% Author  : liuwei
%%% Description :角色等级排行榜
%%% 
%%% Created : 2010-10-9
%%% -------------------------------------------------------------------
-module(ranking_family_gongxun).

-include("mgeew.hrl").


-export([
         init/1,
         rank/0,
         send_ranking_info/6,
         handle/1,
         do_rank_activity/0
        ]).

%%
%%================API FUCTION=======================
%%
init(_RankInfo) ->
    put({{?MODULE,1},ranking_info_list},[]),
    put({{?MODULE,2},ranking_info_list},[]),
    put({{?MODULE,3},ranking_info_list},[]),
    PersistentSeconds = common_time:diff_next_weekdaytime(6,18,0)-30,
    case PersistentSeconds < 0 of
        true ->
            PersistentSeconds2 = PersistentSeconds+7*24*60;
        false ->
            PersistentSeconds2 = PersistentSeconds
    end,
    erlang:send_after((PersistentSeconds2+7*24*60)*1000,self(),{ranking_handle,?MODULE,persistent_family_gongxun_rank}),
    rank().


rank() ->
    rank2(1),
    rank2(2),
    rank2(3),
    persistent_family_gongxun_rank2().


rank2(FactionID) ->
    Sql = io_lib:format("select family_id,family_name,owner_role_name,level,cur_members,active_points,gongxun from t_family_summary where faction_id = ~w order by gongxun desc, cur_members desc, active_points desc, family_id asc limit 20",[FactionID]),
    case mod_mysql:select(Sql) of
        {ok, FamilyRankListTmp} ->
            ?DEBUG("~w",[FamilyRankListTmp]),
            {_,FamilyRankList} = lists:foldr(
                                   fun([FID,FName,RoleName,Level,Members,Active,GongXun],{Rank,Acc}) ->
                                           Date = get_date(),
                                           Pattern = #p_family_gongxun_persistent_rank{family_id=FID,date=Date,_='_'},
                                           case db:dirty_match_object(?DB_FAMILY_GONGXUN_PERSISTENT_RANK_P,Pattern) of
                                               [] ->
                                                   LastRanking = 0,
                                                   LastGongXun = 0;
                                               [Info] ->
                                                   LastRanking = Info#p_family_gongxun_persistent_rank.ranking,
                                                   LastGongXun = Info#p_family_gongxun_persistent_rank.total_gongxun
                                           end,
                                           FamilyActiveRank=#p_family_gongxun_rank{
                                             family_id=FID, 
                                             family_name=FName, 
                                             owner_role_name=RoleName, 
                                             level=Level,
                                             ranking = Rank,
                                             member_count = Members,
                                             active = Active,
                                             gongxun = GongXun,
                                             lastweek_ranking = LastRanking,
                                             lastweek_gongxun = LastGongXun},
                                           {Rank-1,[FamilyActiveRank|Acc]}
                                   end,{length(FamilyRankListTmp),[]},FamilyRankListTmp),
            ?DEBUG("~w",[FamilyRankList]),
            put({{?MODULE,FactionID},ranking_info_list},FamilyRankList);
        _ ->
            ?INFO_MSG("mysql read family data error",[])
    end.

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
    #p_family_gongxun_rank{ranking=Ranking,family_id=FmlId,family_name=FmlName,gongxun = GongXun,lastweek_ranking = LastRanking, lastweek_gongxun = LastGongXun} = Rec,
    case LastRanking of
        undefined -> LastRanking2 = 0;
        _ -> LastRanking2 = LastRanking
    end,
    #p_rank_row{row_id=Ranking,
                elements=[FmlName,common_tool:to_list(GongXun),common_tool:to_list(LastRanking),  
                          common_tool:to_list(LastGongXun) ],
                int_list=[FmlId,LastRanking2]
               }.



handle(persistent_family_gongxun_rank) ->
    persistent_family_gongxun_rank();
handle(_Info) -> 
    ?ERROR_MSG("unexcept msg",[_Info]).
    

%%
%%=============LOCAL  FUNCTION=======================
%%
persistent_family_gongxun_rank() ->  
    rank(),
    persistent_family_gongxun_rank2(),
    PersistentSeconds = 60 * 60 * 24 * 7 - 30,
    erlang:send_after(PersistentSeconds*1000,self(),{ranking_handle,?MODULE,persistent_family_gongxun_rank}).

persistent_family_gongxun_rank2() ->
    Date = get_date() + 7,  
    lists:foreach(
      fun(FactionID) ->
              FamilyGongXunRankInfoList = get({{?MODULE,FactionID},ranking_info_list}),
              lists:foreach(
                fun(FamilyGongXun) ->
                        #p_family_gongxun_rank{
                                               family_id=FID, 
                                               ranking = Rank,
                                               gongxun = GongXun} = FamilyGongXun,
                        FamilyGongXunPerSistent = #p_family_gongxun_persistent_rank{
                                                                                    key = FID * 10000 + Date,
                                                                                    family_id = FID,
                                                                                    ranking = Rank,
                                                                                    total_gongxun = GongXun,
                                                                                    date = Date},
                        db:dirty_write(?DB_FAMILY_GONGXUN_PERSISTENT_RANK_P,FamilyGongXunPerSistent)
                end,FamilyGongXunRankInfoList)
      end,lists:seq(1,3)).
  
    
get_date() ->
    {Year,Month,Day} = date(),
    WeekDay = calendar:day_of_the_week({Year,Month,Day}),
    {Hour,_,_} = time(),
    Days = calendar:date_to_gregorian_days(Year, Month, Day),
    case WeekDay of
        6 ->
            case Hour >= 18 of
                true->
                    Days;
                false ->
                    Days - 7
            end;
        7 ->
            Days - 1;
        _ ->
            Days - WeekDay -1
    end.

do_rank_activity() ->
    ignore.
