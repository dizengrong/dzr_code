%%% -------------------------------------------------------------------
%%% Author  : liuwei
%%% Description :角色等级排行榜
%%% 
%%% Created : 2010-10-9
%%% -------------------------------------------------------------------
-module(ranking_equip_refining).

-include("mgeew.hrl").


-export([
         init/1,
         rank/0,
         update/1,
         cmp/2,
         send_ranking_info/6,
         init2/4,
         rank2/3,
         update2/4,
         get_role_rank/1,
         do_rank_activity/0,
		get_rank/0
        ]).
%%
%%================API FUCTION=======================
%%
init(RankInfo) ->
    init2(RankInfo,?MODULE,?DB_EQUIP_REFINING_RANK_P,fun(E1,E2) -> cmp(E1,E2) end).


init2(RankInfo,ModuleName,DBName,CmpFun) ->
    RankSize = RankInfo#p_ranking.capacity,
    case db:dirty_match_object(DBName,#p_equip_rank{_ = '_'}) of
        [] ->
            read_rank_data(ModuleName,RankSize);
        RoleRankList ->
            rank2(ModuleName,DBName,CmpFun),
            NewList = lists:foldr(
                        fun(EquipRank,Acc) -> 
                                [{EquipRank,EquipRank#p_equip_rank.goods_id}|Acc]
                        end,[],RoleRankList),
            ranking_minheap:new_heap(ModuleName,ModuleName,RankSize,NewList)
    end.


rank() ->
    rank2(?MODULE,?DB_EQUIP_REFINING_RANK_P,fun(E1,E2) -> cmp(E1,E2) end).


rank2(ModuleName,DBName,CmpFun) ->
    List = db:dirty_match_object(DBName,#p_equip_rank{_ = '_'}),
    List2 = lists:foldr(
              fun(EquipRank,Acc) ->
                      {RoleID,GoodsID} = EquipRank#p_equip_rank.goods_id,
                      case get_equip_info(RoleID,GoodsID) of             
                          {error,Reason} ->
                              ?INFO_MSG("equip not found ,reason=~w",[Reason]),
                              db:dirty_delete_object(DBName,EquipRank),
                              Acc;
                          {ok,GoodsInfo} ->
                              case GoodsInfo#p_goods.typeid =:= EquipRank#p_equip_rank.type_id of
                                  true ->
                                      EquipRank2 = get_equip_rank(GoodsInfo),
                                      RoleID = GoodsInfo#p_goods.roleid,
                                      if
                                          RoleID =:= undefined ->
                                              NewRoleName = EquipRank#p_equip_rank.role_name,
                                              NewFactionID =  EquipRank#p_equip_rank.faction_id;
                                          true ->
                                              case db:dirty_read(?DB_ROLE_BASE,RoleID) of
                                                  [RoleBase] ->
                                                      NewRoleName = RoleBase#p_role_base.role_name,
                                                      NewFactionID = RoleBase#p_role_base.faction_id;
                                                  _ ->
                                                      NewRoleName = EquipRank#p_equip_rank.role_name,
                                                      NewFactionID =  EquipRank#p_equip_rank.faction_id
                                              end
                                      end,
                                      NewEquipRank = EquipRank2#p_equip_rank{role_id = RoleID,role_name = NewRoleName,faction_id = NewFactionID},
                                      [NewEquipRank|Acc];
                                  false ->
                                      db:dirty_delete_object(DBName,EquipRank),
                                      Acc
                              end
                      end
              end,[],List),
    ?DEBUG("~w",[List2]),
    List3 = lists:sort(CmpFun,List2),
    {_,List4} = lists:foldl(
              fun(EquipRank,{Rank,Acc}) ->
                      NewEquipRank = EquipRank#p_equip_rank{ranking = Rank},
                      db:dirty_write(DBName,NewEquipRank),
                      {Rank-1,[NewEquipRank|Acc]}
              end,{length(List3),[]},List3),
    List5 = lists:foldr(
              fun(EquipRank,Acc) -> 
                      {_,GoodsID}=EquipRank#p_equip_rank.goods_id,
                      [EquipRank#p_equip_rank{goods_id=GoodsID}|Acc]
              end,[],List4),
    put({ModuleName,ranking_info_list},List5),
    
	
	case ranking_minheap:get_max_heap_size(ModuleName) of
		undefined ->
			ignore;
		RankSize ->
			ranking_minheap:clear_heap(ModuleName),
			NewList = lists:foldr(
						fun(EquipRank2,Acc2) -> 
								[{EquipRank2,EquipRank2#p_equip_rank.goods_id}|Acc2]
						end,[],List4),
			ranking_minheap:new_heap(ModuleName,ModuleName,RankSize,NewList)
	end.


-define(TASK_EQUIP_TYPE_LIST,[30101102,30101202,30101302,30101402]).
update({GoodsInfo,RoleID}) ->
    update2({GoodsInfo,RoleID},?MODULE,?DB_EQUIP_REFINING_RANK_P,fun(E1,E2) -> cmp(E1,E2) end).


update2({GoodsInfo,RoleID},ModuleName,DBName,CmpFun) ->
    case lists:member(GoodsInfo#p_goods.typeid, ?TASK_EQUIP_TYPE_LIST) of
        true ->
            {fail,?_LANG_RANKING_EQUIP_IS_TASK_EQUIP};
        false ->
            #p_goods{id=GoodsID, roleid=OwnerID, type=GoodsType} = GoodsInfo,
            case OwnerID =:= RoleID andalso GoodsType =:= 3 of
                false ->
                    {fail,?_LANG_RANKING_EQUIP_NOT_EXIST};
                true ->
                    EquipRankTmp = get_equip_rank(GoodsInfo),
                    case db:dirty_read(?DB_ROLE_BASE,RoleID) of
                        [] ->
                            {fail,?_LANG_RANKING_EQUIP_NOT_EXIST};
                        [RoleBase] ->
                            #p_role_base{role_name = RoleName, faction_id = FactionID} = RoleBase,
                            EquipRank = EquipRankTmp#p_equip_rank{role_id = RoleID,role_name = RoleName,faction_id = FactionID},
                            case judge_inrank_and_nochange(GoodsID,EquipRank,ModuleName,DBName) of
                                true ->
                                    {fail,?_LANG_RANKING_EQUIP_NO_CHANGE};
                                false ->
                                    case ranking_minheap:update_heap(EquipRank,{RoleID,GoodsID},DBName,ModuleName,ModuleName) of
										{fail,undefined} ->
											?ERROR_MSG("杯具，排行榜:~w有问题，重新初始化数据",[ModuleName]),
											?TRY_CATCH(mgeew_ranking:init_all_module2(mgeew_ranking:get_rankid_by_module_name(ModuleName)));
										{fail,out_of_rank} ->
                                            {fail,?_LANG_RANKING_EQUIP_OUT_RANK};
                                        _ ->
                                            rank_without_update(ModuleName,DBName,CmpFun),
                                            ok
                                    end
                            end
                    end
            end
    end.


cmp(EquipRefiningRank1, EquipRefiningRank2) ->
    ?DEBUG(" ~w     ~w",[EquipRefiningRank1, EquipRefiningRank2]),
    #p_equip_rank{refining_score = Refining1,stone_score = Stone1,quality = Quality1,colour = Colour1} = EquipRefiningRank1,
    #p_equip_rank{refining_score = Refining2,stone_score = Stone2,quality = Quality2,colour = Colour2} = EquipRefiningRank2,
    mgeew_ranking:cmp([{Refining1,Refining2},{Colour1,Colour2},{Quality1,Quality2},{Stone1,Stone2}]).
get_rank() ->
	get({?MODULE,ranking_info_list}).

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
    #p_equip_rank{ranking=Ranking,type_id=TypeId,colour=Color,quality=Quality,goods_id=GoodsId,
                  role_id=RoleID,role_name=RoleName,faction_id=FactionId,refining_score=Score} = Rec,
    #p_rank_row{row_id=Ranking,role_id=RoleID,
                elements=[RoleName,"",common_misc:get_faction_name(FactionId),  
                          common_tool:to_list(Score)],
                int_list=[TypeId,Color,Quality,GoodsId]}.


get_role_rank(RoleID) ->
    ?DEBUG("~w",[RoleID]),
    case db:dirty_match_object(?DB_EQUIP_REFINING_RANK_P,#p_equip_rank{role_id = RoleID, _ = '_'}) of
        [] ->
            undefined;
        EquipRankList ->
            ?DEBUG("~w",[EquipRankList]),
            lists:foldr( 
              fun(EquipRank,Acc) ->
                      ?DEBUG("~w",[EquipRank]),
                      #p_equip_rank{refining_score = Score,ranking = Rank} = EquipRank,
                      RoleRank = #p_role_all_rank{ int_key_value=Score, ranking = Rank},
                      [RoleRank|Acc]
              end,[],EquipRankList)
    end.

do_rank_activity()->
    List1 = get({?MODULE,ranking_info_list}),
    List2 = 
        lists:foldl(
          fun(RankInfo,TmpList)->
                  RoleID = RankInfo#p_equip_rank.role_id,
                  Ranking = RankInfo#p_equip_rank.ranking,
                  case lists:keyfind(1, RoleID, TmpList) of
                      {RoleID,OldRanking}->
                          case OldRanking=<Ranking of
                              true->TmpList;
                              false->[{RoleID,Ranking}|lists:delete({RoleID,OldRanking},List1)]
                          end;
                      false->[{RoleID,Ranking}|TmpList]
                  end
          end, [], List1),
    mgeew_ranking:send_ranking_activity(?RANK_EQUIP_REFINING_KEY,List2).
%%
%%================LOCAL FUCTION=======================
%%
read_rank_data(ModuleName,RankSize) ->
    ranking_minheap:new_heap(ModuleName,RankSize).
    

judge_inrank_and_nochange(GoodsID,EquipRank,ModuleName,DBName) ->
    case get({ModuleName,key,GoodsID}) of
        undefined ->
            false;
        Index ->
            case get({ModuleName,Index}) of
                undefined ->
                    false;
                {OldEquipRank,_} ->
                    case EquipRank#p_equip_rank.refining_score =:=
                        OldEquipRank#p_equip_rank.refining_score of
                        true ->
                            false;
                        false ->
                            db:dirty_write(DBName,EquipRank),
                            true
                    end
            end
    end.
                            
          
%%直接读数据库中的数据然后排序        
rank_without_update(ModuleName,DBName,CmpFun) ->                
    List = db:dirty_match_object(DBName,#p_equip_rank{_ = '_'}),
    List2 = lists:sort(CmpFun,List),
    {_,List3} = lists:foldl(
              fun(EquipRank,{Rank,Acc}) ->
                      NewEquipRank = EquipRank#p_equip_rank{ranking = Rank},
                      db:dirty_write(DBName,NewEquipRank),
                      {Rank-1,[NewEquipRank|Acc]}
              end,{length(List2),[]},List2),
     List4 = lists:foldr(
              fun(EquipRank,Acc) -> 
                      {_,GoodsID}=EquipRank#p_equip_rank.goods_id,
                      [EquipRank#p_equip_rank{goods_id=GoodsID}|Acc]
              end,[],List3),
    put({ModuleName,ranking_info_list},List4).



get_equip_rank(GoodsInfo) ->
    #p_goods{refining_index = Refining,stones = Stones,typeid = TypeID,id = GoodsID,roleid=RoleID,
             reinforce_rate = ReinforceScore,quality = Quality,current_colour = Colour} = GoodsInfo,
    QualityScore = get_quality_score(Quality),
    StoneScore = get_stone_score(Stones,0),
    RefiningScore = get_refining_score(Refining,TypeID,Colour),
    #p_equip_rank{
                   goods_id = {RoleID,GoodsID},
                   type_id = TypeID,
                   reinforce_score = ReinforceScore,
                   stone_score = StoneScore,
                   refining_score = RefiningScore,
                   quality = QualityScore,
                   colour = Colour}.

get_quality_score(Quality) when is_integer(Quality) ->
    Quality;
get_quality_score(_) ->
    0.

get_stone_score(undefined,Score) ->
    Score;
get_stone_score([],Score) ->
    Score;
get_stone_score([Stone|List],Score) ->
    NewScore = Stone#p_goods.level + Score,
    get_stone_score(List,NewScore).

get_refining_score(Refining,TypeID,Colour) when is_integer(Refining) ->
    LevelScore = trunc(TypeID/100000) rem 100 ,
    Refining + LevelScore + Colour;
get_refining_score(_,_,_) ->
    0.


%%获取玩家装备的信息。背包重构后不能直接在数据里匹配直接找到物品的信息
get_equip_info(RoleID,GoodsID) ->    
    case db:dirty_read(?DB_ROLE_ATTR,RoleID) of
        [] ->
            {error,role_attr_not_found};
        [RoleAttr] ->
            Equips = RoleAttr#p_role_attr.equips,
            case lists:keyfind(GoodsID,#p_goods.id,Equips) of
                false ->
                    get_equip_info2(RoleID,GoodsID);
                GoodsInfo ->
                    {ok,GoodsInfo}
            end
    end.
                              
get_equip_info2(RoleID,GoodsID) ->
    BagList = [1,2,3,5,6,7,8,9],
    get_equip_info3(RoleID,GoodsID,BagList).


get_equip_info3(_RoleID,_GoodsID,[]) ->
    {error,equip_not_found};
get_equip_info3(RoleID,GoodsID,[BagID|BagList]) ->
    case db:dirty_read(?DB_ROLE_BAG_P,{RoleID,BagID}) of
        [] ->
            get_equip_info3(RoleID,GoodsID,BagList);
        [BagInfo] ->
            GoodsList = BagInfo#r_role_bag.bag_goods, 
            case lists:keyfind(GoodsID,#p_goods.id,GoodsList) of
                false ->
                    get_equip_info3(RoleID,GoodsID,BagList);
                GoodsInfo ->
                    {ok,GoodsInfo}
            end
    end.
