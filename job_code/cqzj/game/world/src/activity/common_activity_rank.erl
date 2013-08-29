%%%-------------------------------------------------------------------
%%% @author chenrong
%%% @doc
%%%     定时活动的进程字典模块，记录上榜的排名信息，所有玩家的活动信息
%%% @end
%%% Created : 2012-04-18
%%%-------------------------------------------------------------------

-module(common_activity_rank).

-include("mgeew.hrl").

%% 进程字典操作方法
-export([get_rank_list/1,
         get_top_rank_list/1,
         update/2,
         get_rank_info/2,
         get_rank_id_list/1
         ]).

%% 公用的方法 (具体逻辑处理)
-export([get_qualified_rank_list/1,
         init_activity_data/4,
         get_my_rank_info/2,
         get_near_rank_info/2,
         persist_data/2]).

init_dict(Module, RankInfoList, TopRankList, RankSize) ->
    set_rank_size(Module,RankSize),
    lists:foreach(
      fun(RankInfo) ->
              set_rank_info(Module, RankInfo)
      end, RankInfoList),
    set_top_rank_id_list(Module, lists:map(fun(RankInfo)-> RankInfo#r_activity_rank.role_id end, TopRankList)),
    ok. 

clear_dict(Module) ->
    lists:foreach(
      fun(RoleID) ->
           erlang:erase({Module, RoleID})   
      end,get_rank_id_list(Module)),
    set_rank_id_list(Module, []),
    set_top_rank_id_list(Module, []),
    ok.
 
set_rank_size(Module, RankSize) ->
    erlang:put({Module, size}, RankSize).

get_rank_size(Module) ->
    case erlang:get({Module, size}) of
        undefined ->
            10;
        Size ->
            Size
    end.

set_rank_info(Module, RankInfo) ->
    case lists:member(RankInfo#r_activity_rank.role_id, get_rank_id_list(Module)) of
        true ->
            ignore;
        false ->
            set_rank_id_list(Module, [RankInfo#r_activity_rank.role_id | get_rank_id_list(Module)])
    end,
    erlang:put({Module, RankInfo#r_activity_rank.role_id}, RankInfo).
 
get_rank_info(Module, RoleID) ->
    erlang:get({Module, RoleID}).

set_rank_id_list(Module, IDList) ->
    erlang:put({Module, id_list}, IDList).

get_rank_id_list(Module) ->
    case erlang:get({Module, id_list}) of
        undefined ->
            [];
        IDList ->
            IDList
    end.

set_top_rank_id_list(Module, TopRankIDList) ->
%%     ?DBG("error set top_rank id list ~w", [TopRankIDList]),
    erlang:put({Module, top_id_list}, TopRankIDList).

get_top_rank_id_list(Module) ->
    case erlang:get({Module, top_id_list}) of
        undefined ->
            [];
        IDList ->
            IDList
    end.
    
get_rank_list(Module) ->
    lists:map(fun(RoleID) -> get_rank_info(Module, RoleID) end, get_rank_id_list(Module)).

get_top_rank_list(Module) ->
    lists:map(fun(RoleID) -> get_rank_info(Module, RoleID) end, get_top_rank_id_list(Module)).

update(Module, RankInfo) ->
    if RankInfo#r_activity_rank.is_qualified =:= true ->
           set_rank_info(Module, RankInfo),
           NewTopRankList = lists:keystore(RankInfo#r_activity_rank.role_id, #r_activity_rank.role_id, get_top_rank_list(Module), RankInfo),
           NewTopRankList1 = sort_top_rank_list(NewTopRankList),
           RankSize = get_rank_size(Module),
           {_, NewTopRankIDList} =
               lists:foldl(
                 fun(NewRankInfo, {Index, AccTopIDList}) ->
                         OldRankInfo = get_rank_info(Module, NewRankInfo#r_activity_rank.role_id),
                         if Index > RankSize ->
                                set_rank_info(Module, NewRankInfo#r_activity_rank{ranking=0}),
                                update_change_list(Module, NewRankInfo#r_activity_rank.role_id),
                                {Index, AccTopIDList};
                            NewRankInfo#r_activity_rank.role_id =:= OldRankInfo#r_activity_rank.role_id 
                                orelse NewRankInfo#r_activity_rank.ranking =/= Index ->
                                set_rank_info(Module, NewRankInfo#r_activity_rank{ranking=Index}),
                                update_change_list(Module, NewRankInfo#r_activity_rank.role_id),
                                {Index + 1, [NewRankInfo#r_activity_rank.role_id|AccTopIDList]};
                            true ->
                                {Index + 1, [NewRankInfo#r_activity_rank.role_id|AccTopIDList]}
                         end
                 end, {1, []}, NewTopRankList1),
           set_top_rank_id_list(Module, lists:reverse(NewTopRankIDList)),
           ok;
       true ->
           set_rank_info(Module, RankInfo),
           update_change_list(Module, RankInfo#r_activity_rank.role_id)
    end,
    ok.

sort_top_rank_list(TopRankList) ->
    lists:sort(
      fun(R1, R2) ->
              R1#r_activity_rank.score >= R2#r_activity_rank.score
      end, TopRankList).

update_change_list(Module, RoleID) ->
    erlang:put({Module, change_list}, 
               lists:keystore(RoleID, 2, get_change_id_list(Module), {Module, RoleID})).

get_change_id_list(Module) ->
    case erlang:get({Module, change_list}) of
        undefined ->
            [];
        List ->
            List
    end.

clear_change_id_list(Module) ->
    erlang:erase({Module, change_list}).

get_change_rank_list(Module) ->
    lists:map(fun({_, RoleID}) -> get_rank_info(Module, RoleID) end, get_change_id_list(Module)).


%%=================公用的方法 (具体逻辑处理)===================
%% 获得达标的玩家列表 且有排名
get_qualified_rank_list(RankList) ->
    lists:filter(fun(Rank) -> Rank#r_activity_rank.is_qualified andalso Rank#r_activity_rank.ranking > 0 end, RankList).

init_activity_data(clear, Module, DBName, Size) ->
    db:clear_table(DBName),
    clear_dict(Module),
    init_dict(Module, [], [], Size),
    ok;

init_activity_data(load, Module, DBName, Size) ->
    clear_dict(Module),
    case db:dirty_match_object(DBName,#r_activity_rank{_ = '_'}) of
        [] ->
            init_dict(Module, [], [],Size);
        RankInfoList ->
            TopRankList= 
                lists:sublist(
                  lists:keysort(#r_activity_rank.ranking, get_qualified_rank_list(RankInfoList)), 
                  Size),
            init_dict(Module, RankInfoList, TopRankList, Size)
    end;

init_activity_data(Type, Module, DBName, _) ->
    ?ERROR_MSG("定时活动初始化数据失败 错误类型：~w",[{Type, Module, DBName}]).

get_my_rank_info(Module, RoleID) ->
    case get_rank_info(Module, RoleID) of
        undefined ->
            #r_activity_rank{role_id=RoleID};
        RankInfo ->
            RankInfo
    end.

get_near_rank_info(Module, RoleID) ->
    MyRank = get_my_rank_info(Module, RoleID),
    MyRanking = MyRank#r_activity_rank.ranking,
    [#r_activity_setting{view_rank_size=ViewSize}] = common_config_dyn:find(activity_schedule, ?ACTIVITY_SCHEDULE_SILVER),
    {_, NearRankList} = 
        lists:foldr(
          fun(RankInfo, {AccSize, AccList}) ->
                  if AccSize =:= 0 ->
                         {0, AccList};
                     AccSize > 0 andalso MyRanking =:= 0 ->
                         {AccSize-1, [RankInfo|AccList]};
                     AccSize > 0 andalso MyRanking >= RankInfo#r_activity_rank.ranking ->
                         {AccSize-1, [RankInfo|AccList]};
                     true ->
                         {AccSize, AccList}
                  end
          end, {ViewSize,[]}, get_top_rank_list(Module)),
    lists:filter(fun(E) -> E#r_activity_rank.role_id =/= RoleID end, NearRankList).

persist_data(ModuleName, DBName) ->
    lists:foreach(
      fun(RankInfo) ->
              db:dirty_write(DBName, RankInfo)
      end, get_change_rank_list(ModuleName)),
    clear_change_id_list(ModuleName),
    ok.