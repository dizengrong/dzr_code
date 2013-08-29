%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     mod_item_service
%%% @end
%%% Created : 2010-11-17
%%%-------------------------------------------------------------------
-module(mod_item_service).
-include("mgeeweb.hrl").


-define(LIST_TYPE_ITEM,1).    %%类型：道具
-define(LIST_TYPE_STONE,2).   %%类型：宝石
-define(LIST_TYPE_EQUIP,3).   %%类型：装备

-define(IS_OVERLAP,1).
-define(NOT_OVERLAP,2).
%% API
-export([
         load_item_list/0,
         load_map_list/0
        ]). 


%% @doc 获取所有地图列表
load_map_list()->
    MapList = common_config_dyn:list(map_info),
    try
        case MapList of
            []->
                ignore;
            _ ->
                do_truncate_tab(t_map_list),
                do_insert_map_records(MapList)
        end
    catch
        _:Reason->
            ?ERROR_MSG("加载地图列表出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end.

assert_unique_id_list(IdList,ItemList)->
    lists:foldl(
      fun(E,AccIn)->
              Id = erlang:element(2, E),
              case lists:member(Id, AccIn) of
                  true-> 
                      ?ERROR_MSG("load_item_list error, Id=~w is duplicated",[Id]),
                      throw("load_item_list error ,id duplicated");
                  _ ->
                      [Id|AccIn]
              end
      end, IdList, ItemList).

%% @doc 获取所有的道具列表
load_item_list()->
    
    {ok,ItemList} = file:consult(common_config:get_world_config_file_path(item)),
    {ok,EquipList} = file:consult(common_config:get_world_config_file_path(equip)),
    {ok,StoneList} = file:consult(common_config:get_world_config_file_path(stone)),
    
    AllIdList1 = assert_unique_id_list([],ItemList),
    AllIdList2 = assert_unique_id_list(AllIdList1,EquipList),
    assert_unique_id_list(AllIdList2,StoneList),
    
    do_truncate_tab(t_item_list),
    try
        lists:foreach(fun(E)-> 
                              Recs = [ get_item_values(Rec) || Rec<-E ],
                              do_insert_records(Recs)
                      end, 
                      [ItemList,EquipList,StoneList])
    catch
        _:Reason->
            ?ERROR_MSG("加载道具列表出错,Reason=~w,stacktrace=~w",[Reason,erlang:get_stacktrace()])
    end,
    
    ?DEBUG("加载道具列表成功 ok",[]),
    ok.
    
    

%%@spec get_item_values(Rec::record()) -> [typeid,type,item_name,sell_price]
get_item_values(Rec) when is_record(Rec,p_item_base_info)->
    #p_item_base_info{typeid=TypeId,itemname=Name,sell_price=Price,is_overlap = IsOverlap} = Rec,
    [TypeId,?LIST_TYPE_ITEM,Name,Price,IsOverlap];

get_item_values(Rec) when is_record(Rec,p_equip_base_info)->
    #p_equip_base_info{typeid=TypeId,equipname=Name,sell_price=Price} = Rec,
    [TypeId,?LIST_TYPE_EQUIP,Name,Price,?NOT_OVERLAP];

get_item_values(Rec) when is_record(Rec,p_stone_base_info)->
    #p_stone_base_info{typeid=TypeId,stonename=Name,sell_price=Price} = Rec,
    [TypeId,?LIST_TYPE_STONE,Name,Price,?IS_OVERLAP].


%%@doc 清空 t_item_list表
do_truncate_tab(Tab)->
    SqlTruncate = lists:concat(["truncate table ",Tab]),
    mod_mysql:update(SqlTruncate,10000).


do_insert_map_records(MapList)->
    FieldNames = [map_id,map_name],
    BatchFieldValues = [ [ID,Name]||{ID,Name}<-MapList] ,
    
    mod_mysql:batch_insert(t_map_list,FieldNames,BatchFieldValues,3000).


do_insert_records(Records)->
    %%批量插入的数据，目前最大不能超过3M
    FieldNames = [typeid,type,item_name,sell_price,is_overlap],
    BatchFieldValues = Records ,
    
    mod_mysql:batch_insert(t_item_list,FieldNames,BatchFieldValues,3000).
    

