%%%-------------------------------------------------------------------
%%% @author fangshaokong
%%% @copyright (C) 2012
%%% @doc
%%%     战斗力排行榜
%%% @end
%%% Created : 2011-6-16
%%%-------------------------------------------------------------------
-module(ranking_fighting_power).
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
         update/1, 
         cmp/2,
         send_ranking_info/6,
         get_role_rank/1
        ]).

%%
%%===================== API Functions =========================
%%
init(RankInfo) ->
	case db:dirty_match_object(?DB_ROLE_FIGHTING_POWER_RANK_P,#p_role_fighting_power_rank{_ = '_'}) of
		[] ->
			RankSize = RankInfo#p_ranking.capacity,
			rank(RankSize);
		List ->
			put({?MODULE,ranking_info_list},sort(List))
	end,
	ranking_fighting_power_yesterday:init().
rank() ->
	rank(50).

rank(RankSize)->
	db:clear_table(?DB_ROLE_FIGHTING_POWER_RANK_P),
	case db:dirty_match_object(?DB_ROLE_LEVEL_RANK,#p_role_level_rank{_ = '_'}) of
		[] ->
			put({?MODULE,ranking_info_list},[]);
		List ->
			List1 = 
				lists:foldl(
				  fun(#p_role_level_rank{role_id=RoleID},Acc) ->
						  case common_misc:get_dirty_role_base(RoleID) of
							  {ok,RoleBase} ->
								  case common_misc:get_dirty_role_attr(RoleID) of
									  {ok,RoleAttr} ->
										  case common_misc:get_dirty_role_pos(RoleID) of
											  {ok, #p_role_pos{map_id=MapID}} ->
												  case common_config_dyn:find(etc,role_in_maps_not_rank) of
													  [] ->
														  [update({RoleBase,RoleAttr}) | Acc];
													  [RoleInMapsNotRank] ->
														  case lists:member(MapID, RoleInMapsNotRank) of
															  false ->
																  [update({RoleBase,RoleAttr}) | Acc];
															  true ->
																  Acc
														  end
												  end;
											  _ ->
												  Acc
										  end;
									  _ ->
										  Acc
								  end;
							  _ ->
								  Acc
						  end
				  end,[],List),
			List2 = lists:sublist(sort(List1), RankSize),
			[db:dirty_write(?DB_ROLE_FIGHTING_POWER_RANK_P,RoleRank)||RoleRank<-List2],
			common_title_srv:add_title(?TITLE_ROLE_FIGHTING_POWER,0,List2),    
			put({?MODULE,ranking_info_list},List2)
	end.

update({RoleBase, RoleAttr})->
	#p_role_base{
		role_id     = RoleID,
		role_name   = RoleName,
		faction_id  = FactionID,
		family_id   = FamilyID,
		family_name = FamilyName,
		buffs       = OldBuffs
	}= RoleBase,
	#p_role_attr{level = Level} = RoleAttr,
	RoleBase2 = lists:foldl(fun
		(BuffID, RoleBaseAcc) ->
			case lists:keyfind(BuffID, #p_actor_buf.buff_id, OldBuffs) of
				OldActorBuff when is_record(OldActorBuff, p_actor_buf) ->
					mod_role_buff:calc(RoleBaseAcc, '-', OldActorBuff);
				_ ->
					RoleBaseAcc
			end
	end, RoleBase, cfg_zhanli:exclude_buffs()),
	FightingPower = common_role:get_fighting_power(RoleBase2, RoleAttr),
	RoleRank = #p_role_fighting_power_rank{
		role_id        = RoleID,
		role_name      = RoleName,
		level          = Level,
		fighting_power = FightingPower,
		faction_id     = FactionID,
		family_id      = FamilyID,
		family_name    = FamilyName,
		category       = RoleAttr#p_role_attr.category,
		sex            = RoleBase#p_role_base.sex
	},
	RoleRank.

sort(List) ->
	List1 = lists:sort(fun(E1,E2) -> cmp(E1,E2) end,List),
	{_,List2} = lists:foldl(
				  fun(RoleRank,{Rank,Acc})->
						  TitleName = common_title:get_title_name_of_rank(?TITLE_ROLE_FIGHTING_POWER,Rank),
						  {Rank-1,[RoleRank#p_role_fighting_power_rank{ranking = Rank, title=TitleName}|Acc]}
				  end,{length(List1),[]},List1),
	List2.

cmp(RoleRank1,RoleRank2) ->
	#p_role_fighting_power_rank{role_id = RoleID1,level = Level1,fighting_power = FightingPower1} = RoleRank1,
	#p_role_fighting_power_rank{role_id = RoleID2,level = Level2,fighting_power = FightingPower2} = RoleRank2,
	mgeew_ranking:cmp([{FightingPower1,FightingPower2},{Level1,Level2},{RoleID2,RoleID1}]). 

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
	#p_role_fighting_power_rank{
		ranking=Ranking,role_id=RoleID,role_name=RoleName,family_id=FamilyId,
		family_name=FamilyName,faction_id=FactionId,fighting_power=FightingPower,
		title=Title, sex = Sex, category = Category} = Rec,
	#p_rank_row{row_id=Ranking,role_id=RoleID,
				elements=[RoleName,common_tool:to_list(FightingPower),FamilyName,
						  common_misc:get_faction_name(FactionId), Title, Sex, Category],
				int_list=[FamilyId]}.

get_role_rank(RoleID) ->
	RoleRankList = get({?MODULE,ranking_info_list}),
	case lists:keyfind(RoleID,#p_role_fighting_power_rank.role_id,RoleRankList) of
		false ->
			undefined;
		RoleRank ->
			#p_role_fighting_power_rank{ranking = Rank,fighting_power = FightingPower} = RoleRank,
			#p_role_all_rank{int_key_value=FightingPower, ranking = Rank}
	end.
