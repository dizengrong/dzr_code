%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2011, 
%%% @doc
%%%
%%% @end
%%% Created : 18 May 2011 by  <>
%%%-------------------------------------------------------------------
-module(mod_stall_list).

-include("mgeem.hrl").

-export([
         handle/1,
         init/1]).

-export([
         stall_list_refresh/0,
         stall_list_insert/1,
         stall_list_delete/1,
         stall_list_update/1,
         stall_list_get/1]).

-export([hook_map_loop/2]).

-record(r_stall_list_item, {id, role_id, goods_id, typeid, category, sub_category, level, num, price, price_type, color, pro}).

-define(STALL_LIST_ID, stall_list_id).
-define(CACHE_LIST, cache_list).
-define(GID2ID, gid2id).
-define(CACHE_SORT_TYPE, cache_sort_type).
%% 市场类型
%% 200、灵石 100、杂货 300、装备－特殊
-define(STALL_LIST_TYPE_STONE, 200).
-define(STALL_LIST_TYPE_ITEM_OTHER, 100).
-define(STALL_LIST_TYPE_EQUIP_SPEC, 300).
%% 每页数目
-define(PAGE_COUNT, 10).
%% 
-define(DEFAULT_MAP_NAME, "mgee_map_10700").

-define(STALL_LIST_TAB, db_stall_list).
-define(MAX_DUMP_RECORD_COUNT, 500).
%% 缓存5S
-define(CACHE_TIME, 5).
%% ======================================================
%% api func
%% ======================================================

init(?DEFAULT_MAPID) ->
    do_stall_list_refresh();
init(_MapId) ->
    ignore.

hook_map_loop(MapId, Now) when MapId =:= ?DEFAULT_MAPID ->
    CacheList =
        lists:foldl(
          fun({SortType, CacheTime}, Acc) ->
                  case Now - CacheTime >= ?CACHE_TIME of
                      true ->
                          clear_cache(SortType),
                          Acc;
                      _ ->
                          [{SortType, CacheTime}|Acc]
                  end
          end, [], get_cache_list()),
    set_cache_list(CacheList);
hook_map_loop(_MapId, _Now) ->
    ignore.

stall_list_refresh() ->
    case global:whereis_name(?DEFAULT_MAP_NAME) of
        undefined ->
            ignore;
        PID ->
            PID ! {mod_stall_list, {stall_list_refresh}}
    end.

stall_list_insert(StallGoodsList) ->
    case global:whereis_name(?DEFAULT_MAP_NAME) of
        undefined ->
            ignore;
        PID ->
            PID ! {mod_stall_list, {stall_list_insert, StallGoodsList}}
    end.

stall_list_delete(StallGoodsList) ->
    case global:whereis_name(?DEFAULT_MAP_NAME) of
        undefined ->
            ignore;
        PID ->
            PID ! {mod_stall_list, {stall_list_delete, StallGoodsList}}
    end.

stall_list_update(StallGoods) ->
    case global:whereis_name(?DEFAULT_MAP_NAME) of
        undefined ->
            ignore;
        PID ->
            PID ! {mod_stall_list, {stall_list_update, StallGoods}}
    end.

stall_list_get(SortType) ->
    case get_cache(SortType) of
        false ->
            do_select_stall_list(SortType);
        {ok, MaxPage, StallList} ->
            {ok, MaxPage, StallList}
    end.

handle({stall_list_insert, StallGoodsList}) ->
    do_stall_list_insert(StallGoodsList);
handle({stall_list_delete, StallGoodsList}) ->
    do_stall_list_delete(StallGoodsList);
handle({stall_list_update, StallGoods}) ->
    do_stall_list_update(StallGoods);
handle({stall_list_refresh}) ->
    do_stall_list_refresh().

%% ======================================================
%% interval func
%% ======================================================

do_stall_list_refresh() ->
    do_clear_stall_list(),
    Now = common_tool:now(),
    StallList = db:dirty_match_object(?DB_STALL, #r_stall{_='_'}),
    StallList2 =
        lists:foldl(
          fun(#r_stall{role_id=RoleId,start_time=StartTime,time_hour=TimeHour, remain_time=RemainTime}, AccStallList) ->
                  case RemainTime>0 andalso (TimeHour-(Now-StartTime) > 0) of
                      true ->
                          StallGoodsList = db:dirty_match_object(?DB_STALL_GOODS, #r_stall_goods{role_id=RoleId, _='_'}),
                          if
                              StallGoodsList =:= [] ->
                                  AccStallList;
                              true ->
                                  lists:foldl(
                                    fun(StallGoods, Acc) ->
                                            StallListItem = get_stall_list_item(StallGoods),
                                            [_H|T] = erlang:tuple_to_list(StallListItem),
                                            [T|Acc]
                                    end, AccStallList, StallGoodsList)
                          end;
                      _ ->
                          AccStallList
                  end
          end, [], StallList),
    do_dump_stall_list(StallList2).

do_stall_list_insert(StallGoodsList) ->
    StallList =
        lists:foldl(
          fun(StallGoods, AccStallList) ->
                  StallListItem = get_stall_list_item(StallGoods),
                  [_H|T] = erlang:tuple_to_list(StallListItem),
                  [T|AccStallList]
          end, [], StallGoodsList),
    do_dump_stall_list(StallList).

do_stall_list_delete(StallGoodsList) ->
    IdList =
        lists:foldl(
          fun(#r_stall_goods{role_id=RoleId, goods_detail=#p_goods{id=GId}}, AccIdList) ->
                  case get_id_by_goods_id({RoleId, GId}) of
                      {ok, Id} ->
                          clear_gid2id({RoleId, GId}),
                          [Id|AccIdList];
                      _ ->
                          AccIdList
                  end
          end, [], StallGoodsList),
    do_delete_stall_list(IdList).

%% @doc 目前只有数量的更新
do_stall_list_update(StallGoods) ->
    #r_stall_goods{role_id=RoleId, goods_detail=#p_goods{id=GId}} = StallGoods,
    case get_id_by_goods_id({RoleId, GId}) of
        {ok, Id} ->
            StallListItem = get_stall_list_item(StallGoods, update),
            do_update_stall_list(Id, StallListItem);
        _ ->
            {error, not_found}
    end.

%% @doc 获取道具分类
get_item_category(Type, TypeId) ->
    if
        Type =:= ?TYPE_STONE ->
            get_stone_item_category();
            ?STALL_LIST_TYPE_STONE;
        Type =:= ?TYPE_EQUIP ->
            {ok, #p_equip_base_info{kind=Kind}} = mod_equip:get_equip_baseinfo(TypeId),
            get_equip_stall_list_category(Kind);
        true ->
            get_item_stall_list_category(TypeId)
    end.

get_item_stall_list_category(TypeId) ->
	KindId = TypeId div 1000,
	KindId1 = TypeId div 100,
	case common_config_dyn:find(stall_list, {typeid_2_stall_kind, KindId1}) of
		[StallKind1] ->
			StallKind1;
		_ ->
			case common_config_dyn:find(stall_list, {typeid_2_stall_kind, KindId}) of
				[StallKind] ->
					StallKind;
				_ ->
					get_default_item_category()
			end
	end.

get_equip_stall_list_category(Kind) ->
    case common_config_dyn:find(stall_list, {equip_kind_2_stall_kind, Kind}) of
        [StallKind] ->
            StallKind;
        _ ->
            get_default_item_category()
    end.

get_default_item_category() ->
    [Category] = common_config_dyn:find(stall_list, default_category),
    Category.

get_stone_item_category() ->
    [Category] = common_config_dyn:find(stall_list, stone_category),
    Category.

get_stall_list_item(StallGoods) ->
    get_stall_list_item(StallGoods, new).

get_stall_list_item(StallGoods, Mod) ->
    #r_stall_goods{role_id=RoleId, stall_price=Price, price_type=PriceType, goods_detail=GoodsDetail} = StallGoods,
    if GoodsDetail#p_goods.type =:= ?TYPE_EQUIP ->
            {ok, EquipBaseInfo} = mod_equip:get_equip_baseinfo(GoodsDetail#p_goods.typeid),
            Pro = EquipBaseInfo#p_equip_base_info.protype;
       true ->
            Pro = undefined
    end,
    if Mod =:= new ->
            Id = get_stall_list_id(),
            set_gid2id({RoleId, GoodsDetail#p_goods.id}, Id);
       true ->
            Id = undefined
    end,
    ItemCategory = get_item_category(GoodsDetail#p_goods.type, GoodsDetail#p_goods.typeid),
    if GoodsDetail#p_goods.level > 200 ->
            Level = 0;
       true ->
            Level = GoodsDetail#p_goods.level
    end,
    #r_stall_list_item{id=Id,
                       role_id=RoleId,
                       goods_id=GoodsDetail#p_goods.id,
                       typeid=GoodsDetail#p_goods.typeid,
                       category=get_category(ItemCategory),
                       sub_category=get_sub_category(ItemCategory),
                       level=Level,
                       num=GoodsDetail#p_goods.current_num,
                       price=Price,
                       price_type=PriceType,
                       color=GoodsDetail#p_goods.current_colour,
                       pro=Pro}.

%% ====================================================================
%% sql func
%% ===================================================================
do_clear_stall_list() ->
    try
        mod_mysql:update(lists:flatten(io_lib:format("truncate table ~w", [?STALL_LIST_TAB])))
    catch
        _:Reason ->
            ?ERROR_MSG("do clear doll list error, reason: ~w stack: ~w", [Reason, erlang:get_stacktrace()])
    end.

do_dump_stall_list(StallList) ->
    case erlang:is_list(StallList) andalso erlang:length(StallList)>0 of
        true->
            try
                mod_mysql:batch_insert(?STALL_LIST_TAB, record_info(fields, r_stall_list_item), StallList, ?MAX_DUMP_RECORD_COUNT)
            catch
                _:Reason->
                    ?ERROR_MSG("do dump doll list error, reason: ~w stack: ~w", [Reason, erlang:get_stacktrace()])
            end;
        false->
            ignore
    end.

do_delete_stall_list(IdList) ->
    try
        IdListStr = string:join(lists:map(fun(Id) -> common_tool:to_list(Id) end, IdList), ","),
        Sql = lists:flatten(io_lib:format("delete from ~w where id in (~s)", [?STALL_LIST_TAB, IdListStr])),
        mod_mysql:delete(Sql)
    catch
        _:Reason ->
            ?ERROR_MSG("do delete doll list error, reason: ~w, stack: ~w", [Reason, erlang:get_stacktrace()])
    end.

do_update_stall_list(Id, StallListItem) ->
    try
        Sql = lists:flatten(io_lib:format("update ~w set num = '~w' where id = '~w'", [?STALL_LIST_TAB, StallListItem#r_stall_list_item.num, Id])),
        mod_mysql:update(Sql)
    catch
        _:Reason ->
            ?ERROR_MSG("do update doll list error, reason: ~w, stack: ~w", [Reason, erlang:get_stacktrace()])
    end.

do_select_stall_list(SortType) ->
    {SelectSql, CountSql} = gen_select_sql_str(SortType),
    case mod_mysql:select(SelectSql) of
        {ok, StallList} ->
            case mod_mysql:select(CountSql) of
                {ok, [[TotalNum]]} ->
                    do_select_stall_list2(SortType, StallList, TotalNum);
                TotalListError ->
                    ?ERROR_MSG("get total num error: ~w", [{TotalListError}])
            end;
        StallListError ->
            ?ERROR_MSG("get doll list error: ~w", [{StallListError}]),
            ok
    end.

do_select_stall_list2(SortType, StallList, TotalNum) ->
    StallList2 =
        lists:foldr(
          fun([_Id, RoleId, GId|_T], AccStallList) ->
                  case db:dirty_read(?DB_STALL_GOODS, {RoleId, GId}) of
                      [] ->
                          AccStallList;
                      [Goods] ->
                          #r_stall_goods{stall_price=Price, price_type=PriceType, goods_detail=GoodsDetail} = Goods,
                          {ok, #p_role_base{role_name=RoleName}} = common_misc:get_dirty_role_base(RoleId),
                          if GoodsDetail#p_goods.level >= 200 ->
                                  Level = 0;
                             true ->
                                  Level = GoodsDetail#p_goods.level 
                          end,
                          [#p_stall_list_item{role_id=RoleId,
                                              role_name=RoleName,
                                              price=Price,
                                              price_type=PriceType,
                                              goods_detail=GoodsDetail#p_goods{level=Level}}|AccStallList]
                  end
          end, [], StallList),
    MaxPage = common_tool:ceil(TotalNum/?PAGE_COUNT),
    set_cache(SortType, MaxPage, StallList2),
    {ok, MaxPage, StallList2}.

get_sub_category(Category) ->
    if Category =:= undefined ->
            undefined;
       Category rem 100 =:= 0 ->
            undefined;
       true ->
            Category
    end.

get_category(undefined) ->
    undefined;
get_category(Category) ->
    Category div 100 * 100.

gen_select_sql_str(SortType) ->
    Category = get_category(SortType#r_sort_type.category),
    SubCate = get_sub_category(SortType#r_sort_type.category),
    SortType2 = SortType#r_sort_type{category=Category, sub_category=SubCate},
    {_, Condition} =
        lists:foldl(
          fun(Value, {AccField, AccSql}) ->
                  if AccField =:= #r_sort_type.typeid andalso Value =/= undefined ->
                          IdListStr = string:join(lists:map(fun(Id) -> common_tool:to_list(Id) end, Value), ","),
                          {AccField+1, io_lib:format("~s and typeid in (~s) ", [AccSql, IdListStr])};
                     AccField =:= #r_sort_type.category andalso Value =/= undefined ->
                          {AccField+1, io_lib:format("~s and category = ~w ", [AccSql, Value])};
                     AccField =:= #r_sort_type.sub_category andalso Value =/= undefined ->
                          {AccField+1, io_lib:format("~s and sub_category = ~w ", [AccSql, Value])};
                     AccField =:= #r_sort_type.min_level andalso Value =/= undefined ->
                          {AccField+1, io_lib:format("~s and level >= ~w ", [AccSql, Value])};
                     AccField =:= #r_sort_type.max_level andalso Value =/= undefined ->
                          {AccField+1, io_lib:format("~s and level <= ~w ", [AccSql, Value])};
                     AccField =:= #r_sort_type.color andalso Value =/= undefined ->
                          {AccField+1, io_lib:format("~s and color = ~w ", [AccSql, Value])};
                     AccField =:= #r_sort_type.pro andalso Value =/= undefined ->
                          {AccField+1, io_lib:format("~s and pro = ~w ", [AccSql, Value])};
                     true ->
                          {AccField+1, AccSql}
                  end
          end, {1, ""}, erlang:tuple_to_list(SortType2)),
    OrderStr = if SortType#r_sort_type.sort_type =:= ?SORT_TYPE_NUM ->
                       "order by num";
                  SortType#r_sort_type.sort_type =:= ?SORT_TYPE_LEVEL ->
                       "order by level";
                  SortType#r_sort_type.gold_first ->
                       "order by price_type desc, price";
                  true ->
                       "order by price_type, price"
               end,
    ReverStr = if SortType#r_sort_type.is_reverse ->
                       "desc";
                  true ->
                       ""
               end,
    IndexStart = (SortType#r_sort_type.page - 1) * ?PAGE_COUNT,
    IndexEnd = ?PAGE_COUNT,
    SelectSqlStr = lists:flatten(io_lib:format("select * from ~w where 1 ~s ~s ~s limit ~w, ~w", [?STALL_LIST_TAB, Condition, OrderStr, ReverStr, IndexStart, IndexEnd])),
    CountSqlStr = lists:flatten(io_lib:format("select count(*) from ~w where 1 ~s", [?STALL_LIST_TAB, Condition])),
    {SelectSqlStr, CountSqlStr}. 

%% ====================================================================
%% dict func
%% ===================================================================

get_stall_list_id() ->
    case erlang:get(?STALL_LIST_ID) of
        undefined ->
            erlang:put(?STALL_LIST_ID, 2),
            1;
        ID ->
            erlang:put(?STALL_LIST_ID, ID + 1),
            ID
    end.

set_gid2id({RoleId, GId}, Id) ->
    erlang:put({?GID2ID, {RoleId, GId}}, Id).

clear_gid2id({RoleId, GId}) ->
    erlang:erase({?GID2ID, {RoleId, GId}}).

get_id_by_goods_id({RoleId, GId}) ->
    case erlang:get({?GID2ID, {RoleId, GId}}) of
        undefined ->
            {error, not_found};
        Id ->
            {ok, Id}
    end.

set_cache_list(CacheList) ->
    erlang:put(?CACHE_LIST, CacheList).

get_cache_list() ->
    case erlang:get(?CACHE_LIST) of
        undefined ->
            [];
        L ->
            L
    end.

clear_cache(SortType) ->
    erlang:erase({?CACHE_SORT_TYPE, SortType}).

get_cache(SortType) ->
    case erlang:get({?CACHE_SORT_TYPE, SortType}) of
        undefined ->
            false;
        {MaxPage, StallList} ->
            {ok, MaxPage, StallList}
    end.

set_cache(SortType, MaxPage, StallList) ->
    CacheList = get_cache_list(),
    set_cache_list([{SortType, common_tool:now()}|CacheList]),
    erlang:put({?CACHE_SORT_TYPE, SortType}, {MaxPage, StallList}).