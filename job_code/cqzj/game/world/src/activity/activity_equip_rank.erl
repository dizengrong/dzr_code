%%%-------------------------------------------------------------------
%%% @author chenrong
%%% @doc
%%%     神兵之王
%%% @end
%%% Created : 2012-05-07
%%%-------------------------------------------------------------------
-module(activity_equip_rank).

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
    common_activity_rank:init_activity_data(Type, ?MODULE, ?DB_ACTIIVITY_EQUIP_RANK_P, 
                                            ScheduleSetting#r_activity_setting.rank_size).

update(RoleID, {EquipTypeID, Color}) ->
    case db:dirty_read(?DB_ROLE_BASE, RoleID) of
        [#p_role_base{faction_id=FactionID, role_name=RoleName}] ->
            NewRoleRankInfo = 
                case lists:member(RoleID, common_activity_rank:get_rank_id_list(?MODULE)) of
                    false ->
                        Score = calc_score([{EquipTypeID, Color}]),
                        #r_activity_rank{role_id=RoleID, role_name=RoleName, faction_id=FactionID, is_qualified=is_qualified(Score),
                                                value=[{EquipTypeID, Color}], score=Score};
                    true ->
                        RankInfo = common_activity_rank:get_rank_info(?MODULE, RoleID),
                        NewRankValue = [{EquipTypeID, Color} | RankInfo#r_activity_rank.value],
                        Score = RankInfo#r_activity_rank.score + calc_score([{EquipTypeID, Color}]),
                        RankInfo#r_activity_rank{role_name=RoleName, faction_id=FactionID, is_qualified=is_qualified(Score),
                                                        value=NewRankValue, score=Score}
                end,
            common_activity_rank:update(?MODULE, NewRoleRankInfo);
        _ ->
            ignore
    end.

calc_score(EquipList) ->
    lists:foldl(
      fun({_, Color}, AccScore) ->
            calc_color_score(Color) + AccScore  
      end, 0, EquipList).

calc_color_score(1) ->
    0;
calc_color_score(2) ->
    0;
calc_color_score(3) ->
    4;
calc_color_score(4) ->
    8;
calc_color_score(5) ->
    16;
calc_color_score(_) ->
    0.

is_qualified(Score) ->
    [#r_activity_setting{qualified_value=QualifiedValue}] = common_config_dyn:find(activity_schedule, ?ACTIVITY_SCHEDULE_EQUIP),
    Score >= QualifiedValue.
    
persist_data() ->
    common_activity_rank:persist_data(?MODULE, ?DB_ACTIIVITY_EQUIP_RANK_P).
