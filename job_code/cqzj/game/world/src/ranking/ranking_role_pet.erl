%%% -------------------------------------------------------------------
%%% Author  : liuwei
%%% Description :异兽总分榜
%%% 
%%% Created : 2011-3-11
%%% -------------------------------------------------------------------
-module(ranking_role_pet).
-include("mgeew.hrl").
-export([
         init/1,
         rank/0,
         update/1,
         cmp/2,
         send_ranking_info/6,
         get_role_rank/1,
         do_rank_activity/0,
		 get_pet_rank/2
        ]).
%%
%%================API FUCTION=======================
%%
init(RankInfo) ->
    init2(RankInfo,?MODULE,?DB_ROLE_PET_RANK_P,fun(E1,E2) -> cmp(E1,E2) end).

init2(RankInfo,ModuleName,DBName,CmpFun) ->
    RankSize = RankInfo#p_ranking.capacity,
    case db:dirty_match_object(DBName,#p_role_pet_rank{_ = '_'}) of
        [] ->
            read_rank_data(ModuleName,RankSize);
        RoleRankList ->
            rank2(ModuleName,DBName,CmpFun),
            NewList = lists:foldr(
                        fun(PetRank,Acc) -> 
                                [{PetRank,PetRank#p_role_pet_rank.pet_id}|Acc]
                        end,[],RoleRankList),
            ranking_minheap:new_heap(ModuleName,ModuleName,RankSize,NewList)
    end.

rank() ->
    rank2(?MODULE,?DB_ROLE_PET_RANK_P,fun(E1,E2) -> cmp(E1,E2) end).

rank2(ModuleName,DBName,CmpFun) ->
	List = db:dirty_match_object(DBName,#p_role_pet_rank{_ = '_'}),
	List2 = lists:foldr(
			  fun(PetRank,Acc) ->
					  PetID = PetRank#p_role_pet_rank.pet_id,
					  case db:dirty_read(?DB_PET_P,PetID) of             
						  [] ->
							  db:dirty_delete_object(DBName,PetRank),
							  Acc;
						  [PetInfo] ->
							  NewPetRank = get_pet_rank(PetInfo,PetRank),
							  case PetInfo#p_pet.role_id  =:= PetRank#p_role_pet_rank.role_id of
								  false ->
									  db:dirty_delete_object(DBName,PetRank),
									  Acc;
								  true ->
									  [NewPetRank|Acc]
							  end
					  end
			  end,[],List),
	List3 = lists:sort(CmpFun,List2),
	{_,List4} = lists:foldl(
				  fun(PetRank,{Rank,Acc}) ->
						  NewPetRank = PetRank#p_role_pet_rank{ranking = Rank},
						  db:dirty_write(DBName,NewPetRank),
						  {Rank-1,[NewPetRank|Acc]}
				  end,{length(List3),[]},List3),
	
    put({ModuleName,ranking_info_list},List4),
    
    case ranking_minheap:get_max_heap_size(ModuleName) of
        undefined ->
			ignore;
        RankSize ->
            ranking_minheap:clear_heap(ModuleName),
            NewList = lists:foldr(
                        fun(PetRank2,Acc2) -> 
                                [{PetRank2,PetRank2#p_role_pet_rank.pet_id}|Acc2]
                        end,[],List4),
            ranking_minheap:new_heap(ModuleName,ModuleName,RankSize,NewList)
    end.

update({PetID,RoleID}) ->
      case db:dirty_read(?DB_ROLE_BASE,RoleID) of
        [] ->
             {fail,?_LANG_PET_NOT_EXIST};
        [#p_role_base{role_name=RoleName,faction_id=FactionID}] ->
            case db:dirty_read(?DB_PET_P, PetID) of
                [] ->
                    {fail,?_LANG_PET_NOT_EXIST};
                [PetInfo] ->
                    case PetInfo#p_pet.role_id =:= RoleID of
                        true ->
                            update2({PetInfo,RoleID,RoleName,FactionID},?MODULE,?DB_ROLE_PET_RANK_P,fun(E1,E2) -> cmp(E1,E2) end);
                        false ->
                            {fail,?_LANG_PET_NOT_EXIST}
                    end
            end
      end.

update2({PetInfo,RoleID,RoleName,FactionID},ModuleName,DBName,CmpFun) ->
    PetRank = #p_role_pet_rank{role_id=RoleID,role_name=RoleName,faction_id=FactionID},
    NewPetRank = get_pet_rank(PetInfo, PetRank),
    PetID = PetInfo#p_pet.pet_id,
    case judge_inrank_and_nochange(PetID,NewPetRank,ModuleName,DBName) of
        true ->
            {fail,?_LANG_RANKING_PET_NO_CHANGE};
        false ->
            case ranking_minheap:update_heap(NewPetRank,PetID,DBName,ModuleName,ModuleName) of
				{fail,undefined} ->
					?ERROR_MSG("杯具，排行榜:~w有问题，重新初始化数据",[ModuleName]),
					?TRY_CATCH(mgeew_ranking:init_all_module2(mgeew_ranking:get_rankid_by_module_name(ModuleName)));
                {fail,out_of_rank} ->
                    {fail,?_LANG_RANKING_PET_OUT_RANK};
                _ ->
                    rank_without_update(ModuleName,DBName,CmpFun),
                    ok
            end
    end.

cmp(PetRank1, PetRank2) ->
    #p_role_pet_rank{score = Score1,color = Color1,understanding = Under1,level = Level1} = PetRank1,
    #p_role_pet_rank{score = Score2,color = Color2,understanding = Under2,level = Level2} = PetRank2,
    mgeew_ranking:cmp([{Score1,Score2},{Color1,Color2},{Under1,Under2},{Level1,Level2}]).

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
    #p_role_pet_rank{ranking=Ranking,pet_id=PetId,pet_name=PetName,pet_type_name=PetTypeName,role_id=RoleID,
                     role_name=RoleName,faction_id=FactionId,score=Score,color=Color} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[PetName,RoleName,common_misc:get_faction_name(FactionId),PetTypeName,
                          common_tool:to_list(Score)
                         ],
                int_list=[PetId,Color]}.

get_role_rank(RoleID) ->
    case db:dirty_match_object(?DB_ROLE_PET_RANK_P,#p_role_pet_rank{role_id = RoleID, _ = '_'}) of
        [] ->
            undefined;
        PetRankList ->
            lists:foldr( 
              fun(PetRank,Acc) ->
                      #p_role_pet_rank{score = Score,ranking = Rank} = PetRank,
                      RoleRank = #p_role_all_rank{int_key_value=Score, ranking = Rank},
                      [RoleRank|Acc]
              end,[],PetRankList)
    end.

do_rank_activity()->
    List1 = get({?MODULE,ranking_info_list}),
    List2 = 
        lists:foldl(
          fun(RankInfo,TmpList)->
                  RoleID = RankInfo#p_role_pet_rank.role_id,
                  Ranking = RankInfo#p_role_pet_rank.ranking,
                  case lists:keyfind(1, RoleID, TmpList) of
                      {RoleID,OldRanking}->
                          case OldRanking=<Ranking of
                              true->TmpList;
                              false->[{RoleID,Ranking}|lists:delete({RoleID,OldRanking},List1)]
                          end;
                      false->[{RoleID,Ranking}|TmpList]
                  end
          end, [], List1),
    mgeew_ranking:send_ranking_activity(?RANK_PET_KEY,List2).
    
%%
%%================LOCAL FUCTION=======================
%%
read_rank_data(ModuleName,RankSize) ->
    put({ModuleName,ranking_info_list},[]),
    ranking_minheap:new_heap(ModuleName,RankSize).
    

judge_inrank_and_nochange(PetID,PetRank,ModuleName,DBName) ->
    case get({ModuleName,key,PetID}) of
        undefined ->
            false;
        Index ->
            case get({ModuleName,Index}) of
                undefined ->
                    false;
                {OldPetRank,_} ->
                    case PetRank#p_role_pet_rank.score =:=
                        OldPetRank#p_role_pet_rank.score of
                        true ->
                            true;
                        false ->
                            db:dirty_write(DBName,PetRank),
                            false
                    end
            end
    end.
          
%%直接读数据库中的数据然后排序        
rank_without_update(ModuleName,DBName,CmpFun) ->                
    List = db:dirty_match_object(DBName,#p_role_pet_rank{_ = '_'}),
    List2 = lists:sort(CmpFun,List),
    {_,List3} = lists:foldl(
              fun(PetRank,{Rank,Acc}) ->
                      NewPetRank = PetRank#p_role_pet_rank{ranking = Rank},
                      db:dirty_write(DBName,NewPetRank),
                      {Rank-1,[NewPetRank|Acc]}
              end,{length(List2),[]},List2),
    put({ModuleName,ranking_info_list},List3).
                              
get_pet_rank(PetInfo, PetRank) ->
	#p_pet{pet_id=PetID,
		   role_id=RoleID,
		   type_id=TypeID,
		   color=Color,
		   understanding=UnderStanding,
		   level=Level,
		   phy_attack=PAA,
		   magic_attack=MAA,
		   pet_name=PetName,
		   attack_type=AttackType,
		   skills=Skills} = PetInfo,
	#p_pet_base_info{pet_name=Name} = cfg_pet:get_base_info(TypeID),
	SkillScore = lists:foldr(
				   fun(#p_pet_skill{skill_id=SkillID},Acc) ->
						   Acc + get_skill_score(SkillID)
				   end,0,Skills),
	TotalScore = 
		case AttackType of
			1 -> PAA + SkillScore;
			2 -> MAA + SkillScore
		end,
	PetRank#p_role_pet_rank{pet_id=PetID,
							pet_type_name=Name,
							score=TotalScore,
							color=Color,
							understanding=UnderStanding,
							level=Level,
							pet_name=PetName,
							role_id=RoleID}.

get_skill_score(SkillID) ->
    List = [chu_ji_pet_skill_type,zhong_ji_pet_skill_type,gao_ji_pet_skill_type,ding_ji_pet_skill_type],
    get_skill_score_2(List,SkillID).

get_skill_score_2([],_) ->
	0;
get_skill_score_2([Key|List],SkillID) ->
	case common_config_dyn:find(pet_etc,Key) of
		[] ->
			0;
		[{Score,List2}] ->
			case lists:member(SkillID, List2) of
				false ->
					get_skill_score_2(List,SkillID);
				true ->
					Score
			end
	end.
