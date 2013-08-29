%%%-------------------------------------------------------------------
%%% @author chenrong
%%% @doc
%%%     经验多多
%%% @end
%%% Created : 2012-04-18
%%%-------------------------------------------------------------------
-module(activity_exp_rank).

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
    common_activity_rank:init_activity_data(Type, ?MODULE, ?DB_ACTIIVITY_EXP_RANK_P, 
                                            ScheduleSetting#r_activity_setting.rank_size).

update(RoleID, ExpChange) when ExpChange > 0 ->
    case db:dirty_read(?DB_ROLE_BASE, RoleID) of
        [#p_role_base{faction_id=FactionID, role_name=RoleName}] ->
            NewRoleRankInfo = 
                case lists:member(RoleID, common_activity_rank:get_rank_id_list(?MODULE)) of
                    false ->
                        Score = calc_score(ExpChange),
                        #r_activity_rank{role_id=RoleID, role_name=RoleName, faction_id=FactionID, is_qualified=is_qualified(Score),
                                                value=ExpChange, score=Score};
                    true ->
                        RankInfo = common_activity_rank:get_rank_info(?MODULE, RoleID),
                        NewExp = RankInfo#r_activity_rank.value + ExpChange,
                        Score = calc_score(NewExp),
                        RankInfo#r_activity_rank{role_name=RoleName, faction_id=FactionID, is_qualified=is_qualified(Score),
                                                        value=NewExp, score=Score}
                end,
            common_activity_rank:update(?MODULE, NewRoleRankInfo);
        _ ->
            ignore
    end;
update(_,_) ->
    ignore.

calc_score(Exp) ->
    Exp div 100000.

is_qualified(Score) ->
    [#r_activity_setting{qualified_value=QualifiedValue}] = common_config_dyn:find(activity_schedule, ?ACTIVITY_SCHEDULE_EXP),
    Score >= QualifiedValue.
    
persist_data() ->
    common_activity_rank:persist_data(?MODULE, ?DB_ACTIIVITY_EXP_RANK_P).
