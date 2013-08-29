%%%-------------------------------------------------------------------
%%% @author chenrong
%%% @doc
%%%     富甲天下
%%% @end
%%% Created : 2012-04-18
%%%-------------------------------------------------------------------
-module(activity_silver_rank).

-include("mgeew.hrl").

-export([
         init/2,
         update/2,
         persist_data/0
        ]).

%%
%%================API FUCTION=======================
%%
init(Type, ScheduleSetting) ->
    common_activity_rank:init_activity_data(Type, ?MODULE, ?DB_ACTIIVITY_SILVER_RANK_P, 
                                            ScheduleSetting#r_activity_setting.rank_size).

update(RoleID, SilverChange) ->
    NewSilverChange = erlang:abs(SilverChange),
    case db:dirty_read(?DB_ROLE_BASE, RoleID) of
        [#p_role_base{faction_id=FactionID, role_name=RoleName}] ->
            NewRoleRankInfo = 
                case lists:member(RoleID, common_activity_rank:get_rank_id_list(?MODULE)) of
                    false ->
                        Score = calc_score(NewSilverChange),
                        #r_activity_rank{role_id=RoleID, role_name=RoleName, faction_id=FactionID, is_qualified=is_qualified(Score),
                                                value=NewSilverChange, score=Score};
                    true ->
                        RankInfo = common_activity_rank:get_rank_info(?MODULE, RoleID),
                        NewSilver = RankInfo#r_activity_rank.value + NewSilverChange,
                        Score = calc_score(NewSilver),
                        RankInfo#r_activity_rank{role_name=RoleName, faction_id=FactionID, is_qualified=is_qualified(Score),
                                                        value=NewSilver, score=Score}
                end,
            common_activity_rank:update(?MODULE, NewRoleRankInfo);
        _ ->
            ignore
    end.

calc_score(Silver) ->
    Silver div 10000.

is_qualified(Score) ->
    [#r_activity_setting{qualified_value=QualifiedValue}] = common_config_dyn:find(activity_schedule, ?ACTIVITY_SCHEDULE_SILVER),
    Score >= QualifiedValue.
    
persist_data() ->
    common_activity_rank:persist_data(?MODULE, ?DB_ACTIIVITY_SILVER_RANK_P).
