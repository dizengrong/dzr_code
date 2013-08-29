%%%-------------------------------------------------------------------
%%% @author chenrong
%%% @doc
%%%     毁灭之王
%%% @end
%%% Created : 2012-05-31
%%%-------------------------------------------------------------------
-module(activity_boss_rank).

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
    common_activity_rank:init_activity_data(Type, ?MODULE, ?DB_ACTIIVITY_BOSS_RANK_P, 
                                            ScheduleSetting#r_activity_setting.rank_size).

update(RoleID, MonsterTypeID) ->
    case db:dirty_read(?DB_ROLE_BASE, RoleID) of
        [#p_role_base{faction_id=FactionID, role_name=RoleName}] ->
            NewRoleRankInfo = 
                case lists:member(RoleID, common_activity_rank:get_rank_id_list(?MODULE)) of
                    false ->
                        Score = calc_score([MonsterTypeID]),
                        #r_activity_rank{role_id=RoleID, role_name=RoleName, faction_id=FactionID, is_qualified=is_qualified(Score),
                                                value=[MonsterTypeID], score=Score};
                    true ->
                        RankInfo = common_activity_rank:get_rank_info(?MODULE, RoleID),
                        NewMonsterList = [MonsterTypeID | RankInfo#r_activity_rank.value],
                        Score = RankInfo#r_activity_rank.score + calc_score([MonsterTypeID]),
                        RankInfo#r_activity_rank{role_name=RoleName, faction_id=FactionID, is_qualified=is_qualified(Score),
                                                        value=NewMonsterList, score=Score}
                end,
            common_activity_rank:update(?MODULE, NewRoleRankInfo);
        _ ->
            ignore
    end.

-define(HERO_FB_BOSS_LIST, [10801001,10802001,10803001,10804001,10805001,10806001,10807001,10808001,10809001,10810001,10811001,10812001,
                            10813001,10814001,10815001,10816001,10817001,10818001,10819001,10820001,10821001,10822001,10823001,10824001,
                            10825001,10826001,10827001,10828001,10829001,10830001,10831001,10832001,10833001,10834001,10835001,10836001,
                            10837001,10838001,10839001,10840001,10841001,10842001,10843001,10844001,10845001,10846001,10847001,10848001,
                            10849001,10850001,10851001,10852001,10853001,10854001,10855001,10856001,10857001,10858001,10859001,10860001,
                            10861001,10862001,10863001,10864001,10865001,10866001,10867001,10868001,10869001,10870001]).

-define(EXAMINE_FB_BOSS_LIST, [10401002,10404002,10407002,10402002,10405002,10408002,10403002,10406002,10409002,10503001,10503002,
                               10503003,10503004,10503005]).

-define(NOT_CALC_SCORE_BOSS_LIST, [11501101,11651101]).

-define(WORLD_BOSS_LIST, [30402101,30502101,30602101,30612101,30802101,30812101]). %% 世界boss

calc_score(MonsterList) ->
    lists:foldl(
      fun(MonsterTypeID, Acc) ->
              case lists:member(MonsterTypeID, ?NOT_CALC_SCORE_BOSS_LIST) of
                  true ->
                      0 + Acc;
                  false ->
                      case lists:member(MonsterTypeID, ?WORLD_BOSS_LIST) of
                          true ->
                              5 + Acc;
                          false ->
                              case lists:member(MonsterTypeID, ?HERO_FB_BOSS_LIST) orelse lists:member(MonsterTypeID, ?EXAMINE_FB_BOSS_LIST) of
                                  true ->
                                      10 + Acc;
                                  false ->
                                      2 + Acc
                              end
                      end
              end
      end, 0, MonsterList).

is_qualified(Score) ->
    [#r_activity_setting{qualified_value=QualifiedValue}] = common_config_dyn:find(activity_schedule, ?ACTIVITY_SCHEDULE_BOSS),
    Score >= QualifiedValue.
    
persist_data() ->
    common_activity_rank:persist_data(?MODULE, ?DB_ACTIIVITY_BOSS_RANK_P).
