%%%-------------------------------------------------------------------
%%% @author liuwei <liuwei@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     背包操作的内部接口
%%% @end
%%% Created : 2010-12-1
%%%-------------------------------------------------------------------
-module(mod_bag).

-include("mgeem.hrl").
-define(ROLE_BAG_TRANSACTION,role_bag_transaction).
-define(MAP_BAG_PERSISTENT_INTEEVAL,30).
-define(ROLE_DEPOSITORY_LIST,role_depository_list).    %%角色仓库的字典Key
-define(ROLE_BAG_LIST,role_bag_list).    %%角色背包概况列表的字典Key
 
-define(ROLE_BAG_LIST_BK,role_bag_list_bk).
-define(ROLE_BAG_BK,role_bag_bk).

-define(UNDEFINED,undefined).

-define(TIMESUP_BAG_ID_LIST,[2,3]).  %%有实效限制的背包id列表
-define(role_bag_max_goodsid,role_bag_max_goodsid).

-export([
        %% 使用道具的接口，包括记录日志和更新客户端(不要再使用其他的方法来做了)
        use_item/4,
        use_item/5,
        add_items/3,
        add_items2/3
    ]).

-export([
         get_goods_num_by_typeid/2,
         get_goods_num_by_typeid/3,
         get_goods_num_by_typeid/4,
         get_goods_num/1,
         get_bind_goods_num/1,
         init_role_bag_info/1,
         get_role_bag_info/1,
         get_bag_goods_list/1,
         get_bag_goods_list/2,
         get_bag_info_by_id/2,
         get_role_bag_transfer_info/1,
         get_role_bag_dicts/1,
         clear_role_bag_info/1,
         check_stone_inbag/1,
         check_inbag/2,
         check_inbag/3,
         check_inbag_by_typeid/2,
         check_inbag_by_typeid_endtime/3,
         check_indepot_by_typeid/2,
         judge_bag_exist/2,
         create_goods/2,
         create_goods/3,
         create_goods_by_p_goods_and_id/2,
         create_goods_by_p_goods_and_id/4,
         create_goods_by_p_goods/2,
         create_goods_by_p_goods/3,
         create_goods_by_p_goods/4,
         delete_goods/2,
         delete_depositroy_goods/3,
         delete_goods_by_typeid/2,
         update_goods/2,
         swap_goods/4,
         divide_goods/5,
         get_goods_by_position/3,
         get_goods_by_id/2,
         get_dirty_goods_by_id/2,
         get_goods_by_typeid/3,
         create_bag/2,
         delete_bag/5,
         tidy_bag/2,
         get_empty_bag_pos/2,
         get_empty_bag_pos/3,
         decrease_goods/2,
         decrease_goods_by_typeid/3,
         decrease_goods_by_typeid/4,
         decrease_goods_by_typeid/5,
         decrease_goods_by_typeid_endtime/4,
         get_role_depot_info/1,
         create_p_goods/2,
         check_bags_times_up/4,
         update_bag_info_by_id/3,
         get_role_bag_persistent_info/1,
		 bag_extend_row/3
        ]).
-export([delete_depositroy_goods_by_typeid/2,
         delete_goods_from_bag_depositroy_by_typeid/2,
         check_indepot_by_id/2,
         get_empty_bag_pos_num/2,
		 get_new_goodsid/1]).

     
%%@doc  初始化玩家背包信息,第一次进入地图时使用
%%@param RoleID::integer()  角色ID  RoleBagInfo  玩家背包进程字典信息
%%@return  
init_role_bag_info(RoleBagInfoList) -> 
    lists:foreach(fun({Key,Value}) -> put(Key,Value) end,RoleBagInfoList),
    ok.

%%@doc 玩家背包进程字典的数据
get_role_bag_dicts(RoleID) ->
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            KeyL1=[];
        IDList1 ->
            KeyL1 = lists:foldl(
                      fun({BagID,_},AccIn)->
                              [{?ROLE_BAG,RoleID,BagID}|AccIn];
                         (_,AccIn)->
                              AccIn
                      end, [{?ROLE_BAG_LIST,RoleID}], IDList1)
    end,
    case get({?ROLE_DEPOSITORY_LIST,RoleID}) of
        undefined ->
            KeyL2=[];
        IDList2 ->
            KeyL2 = lists:foldl(
                      fun({BagID,_},AccIn)->
                              [{?ROLE_BAG,RoleID,BagID}|AccIn];
                         (_,AccIn)->
                              AccIn
                      end, [{?ROLE_DEPOSITORY_LIST,RoleID}], IDList2)
    end,
    KeyList = lists:merge([KeyL1,KeyL2]),
    MaxID = get({?role_bag_max_goodsid,RoleID}),
    [{{?role_bag_max_goodsid,RoleID},MaxID}| [ {Key,erlang:get(Key)} ||Key<-KeyList ]].

%%@doc 从地图节点信息中删除玩家背包信息
clear_role_bag_info(RoleID) ->
    erase({?role_bag_max_goodsid,RoleID}),
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            ignore;
        IDList ->
            erase({?ROLE_BAG_LIST,RoleID}),
            [ erase({?ROLE_BAG,RoleID,BagID}) ||{BagID,_}<-IDList]
    end,
    case get({?ROLE_DEPOSITORY_LIST,RoleID}) of
        undefined ->
            ignore;
        IDList2 ->
            erase({?ROLE_DEPOSITORY_LIST,RoleID}),
            [ erase({?ROLE_BAG,RoleID,BagID}) ||{BagID,_}<-IDList2]
    end.

%%@doc 获取玩家背包中的物品列表，包括背包/扩展背包/仓库的物品
%%@return   {error,Reason} | {ok,AllGoodsList}
get_bag_goods_list(RoleID) ->
    get_bag_goods_list(RoleID,true).

get_bag_goods_list(RoleID,IsIncludeDepository) ->
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            {error,no_role_bag_info};
        IDList ->
            BagGoodsList = lists:foldr(
                             fun({BagID,_Detail},Acc) ->
                                     {_Content,_OutUseTime,_UsedPositionList,GoodsList,_Modified} = get({?ROLE_BAG,RoleID,BagID}),
                                     lists:concat([Acc,GoodsList])
                             end,[],IDList),
            case IsIncludeDepository of
                true->
                    case get({?ROLE_DEPOSITORY_LIST,RoleID}) of
                        undefined->
                            {ok,BagGoodsList};
                        DeptIDList->
                            AllGoodsList = lists:foldr(
                                             fun({BagID,_Detail},Acc) ->
                                                     {_Content,_OutUseTime,_UsedPositionList,GoodsList,_Modified} = get({?ROLE_BAG,RoleID,BagID}),
                                                     lists:concat([Acc,GoodsList])
                                             end,BagGoodsList,DeptIDList),
                            {ok,AllGoodsList}
                    end;
                false->
                    {ok,BagGoodsList}
            end
    end.
            

%%获取背包相关信息，背包列表和所有的物品信息
get_role_bag_info(RoleID) ->
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            {error,no_role_bag_info};
        IDList ->
            AllGoodsList = lists:foldr(
                            fun({BagID,_Detail},Acc) ->
                                    List = get({?ROLE_BAG,RoleID,BagID}),
                                    [{?ROLE_BAG,BagID,List}|Acc]
                            end,[],IDList),
            {ok,{?ROLE_BAG_LIST,IDList},AllGoodsList}
    end.

%%获取切换地图时需要传送到下个地图的背包数据
get_role_bag_transfer_info(RoleID) ->
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            {error,no_role_bag_info};
        IDList ->
            MaxID = get({?role_bag_max_goodsid,RoleID}),
            List = [{{?ROLE_BAG_LIST,RoleID},IDList},{{?role_bag_max_goodsid,RoleID},MaxID}],
            List2 = lists:foldr(
                      fun({BagID,_Detail},Acc) ->
                              Info = get({?ROLE_BAG,RoleID,BagID}),
                              [{{?ROLE_BAG,RoleID,BagID},Info}|Acc]
                      end,List,IDList),
            case get({?ROLE_DEPOSITORY_LIST,RoleID}) of
                undefined ->
                    {error,no_role_bag_info};
                IDList2 ->
                    List3 = [{{?ROLE_DEPOSITORY_LIST,RoleID},IDList2}|List2],
                    List4 = lists:foldr(
                              fun({BagID2,_Detail2},Acc2) ->
                                      Info2 = get({?ROLE_BAG,RoleID,BagID2}),
                                      [{{?ROLE_BAG,RoleID,BagID2},Info2}|Acc2]
                              end,List3,IDList2),
                    {ok,List4}
            end
    end.
    

%%@doc 判断某个物品是否在玩家的背包中，检查所有背包（包含扩展背包）
check_inbag(RoleID,GoodsID) ->
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            {error,not_found};
        IDList ->
            check_inbag2(GoodsID,RoleID,IDList)
    end.


%%@doc 判断某个物品是否在玩家的背包中
%%@return {ok,GoodsInfo} | {error,Error}
check_inbag(RoleID,GoodsID,BagID) ->
    case get({?ROLE_BAG,RoleID,BagID}) of
        undefined ->
            {error,not_found};
        {_Content,_OutUseTime,_UsedPositionList,GoodsList,_Modified} ->
            check_inbag2(GoodsID,GoodsList)
    end.

%%@doc 判断玩家的背包中是否包含宝石，如果有返回一个找到的该类型物品的信息
%%@return {ok,GoodsInfo} | false
check_stone_inbag(RoleID) ->
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            false;
        BagIDlist ->
            check_stone_inbag_2(RoleID,BagIDlist)
    end.

check_stone_inbag_2(_RoleID,[]) ->
    false;
check_stone_inbag_2(RoleID,[{BagID,_}|BagBasicList]) ->
    case get({?ROLE_BAG,RoleID,BagID}) of
        undefined ->
            check_stone_inbag_2(RoleID,BagBasicList);
        {_Content,_OutUseTime,_UsedPositionList,GoodsList,_Modifiled} ->
            case check_stone_inbag_3(RoleID,GoodsList) of
                {ok,GoodsInfo}->
                    {ok,GoodsInfo};
                _ ->
                    check_stone_inbag_2(RoleID,BagBasicList)
            end    
    end.

check_stone_inbag_3(_RoleID,[])->
    {error,not_found};
check_stone_inbag_3(RoleID,[GoodsInfo|T]) ->
    #p_goods{type=Type,typeid=PropTypeId} = GoodsInfo,
    case (?TYPE_STONE =:= Type) andalso (0=:=GoodsInfo#p_goods.end_time) andalso (PropTypeId=/=23100001)of
        true ->
            {ok,GoodsInfo};
        false ->
            check_stone_inbag_3(RoleID,T)
    end.


%%@doc 判断玩家的背包中是否包含某种物品，如果有返回一个找到的该类型物品的信息列表
%%@return {ok, FoundGoodsList} | false
check_inbag_by_typeid(RoleID,TypeID) ->
    check_inbag_by_typeid_endtime(RoleID,TypeID,0).

check_inbag_by_typeid_endtime(RoleID,TypeID,EndTime) ->
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            false;
        IDlist ->
            check_inbag_by_typeid_endtime2(RoleID,TypeID,EndTime,IDlist,[])
    end.

%% @doc 判断玩家的仓库中是否包含某种物品，如果有返回一个找到的该类型物品的信息
check_indepot_by_typeid(RoleID,TypeID) ->
    case get({?ROLE_DEPOSITORY_LIST,RoleID}) of
        undefined ->
            false;
        IDlist ->
            check_inbag_by_typeid_endtime2(RoleID,TypeID,0,IDlist,[])
    end.

%% @doc 判断玩家的仓库中是否包含此ID的物品，如果有返回一个找到的该类型物品的信息
check_indepot_by_id(RoleID, GoodsID) ->
    case get({?ROLE_DEPOSITORY_LIST,RoleID}) of
        undefined ->
            {error,goods_not_found};
        IDList2 ->
            lists:foldl(
              fun({BagID2,_Detail2},Acc2) ->
                      case Acc2 of
                          {ok,_GoodsInfo2} ->
                              Acc2;
                          {error,goods_not_found} ->
                              {_Content2,_OutUseTime2,_UsedPositionLis2t,GoodsList2,_} = get({?ROLE_BAG,RoleID,BagID2}),
                              case lists:keyfind(GoodsID,#p_goods.id,GoodsList2) of
                                  false ->
                                      {error,goods_not_found};
                                  GoodsInfo2 ->
                                      {ok,GoodsInfo2}
                              end
                      end
              end, {error,goods_not_found} , IDList2)
    end.

%%@doc 批量创建物品，返回成功则表示全部创建成功，否则全部都不会创建
%% 包括记录日志和通知客户端物品的变动
%%@param   RoleID               角色ID
%%@param   ItemInfoList  [{物品类型id, 数量, 物品类别(TYPE_ITEM | TYPE_EQUIP | TYPE_STONE), 是否绑定(true | false)}]
%%@return  {true, GoodsList} | {error,Reason}
add_items(_RoleID, [], _LogType) ->
    {true, []};
add_items(RoleID, ItemInfoList, LogType) ->
    GoodsCreateInfoList = common_misc:get_items_create_info(RoleID, ItemInfoList),
    add_items2(RoleID, GoodsCreateInfoList, LogType).

%%@doc 批量创建物品，返回成功则表示全部创建成功，否则全部都不会创建
%% 包括记录日志和通知客户端物品的变动
%%@param   RoleID               角色ID
%%@param   GoodsCreateInfoList  创建信息的列表 [#r_goods_create_info{}]
%%@return  {true, GoodsList} | {error,Reason}
add_items2(RoleID, GoodsCreateInfoList, LogType) ->
    Fun = fun() -> mod_bag:create_goods(RoleID, GoodsCreateInfoList) end,
    case common_transaction:t(Fun) of
        {aborted, {error, _Reason}} ->
            {error, ?_LANG_BAG_ERROR};
        {aborted,{bag_error,{not_enough_pos,_}}} ->
            {error, ?_LANG_GOODS_BAG_NOT_ENOUGH};
        {aborted, _} ->
            {error, ?_LANG_BAG_ERROR};
        {atomic, {ok, GoodsList}} -> 
            common_misc:update_goods_notify({role, RoleID}, GoodsList),
            common_item_logger:log(RoleID, GoodsList, LogType),
            {true, GoodsList}
    end.


%%@doc 批量创建物品，返回成功则表示全部创建成功，否则全部都不会创建
%%@param   RoleID               角色ID
%%@param   GoodsCreateInfoList  创建信息的列表 可以自己加
%%@return  {ok,NewGoodsInfoList}创建成功以后的物品的信息列表 | {error,Reason}
create_goods(RoleID,GoodsCreateInfoList) when is_list(GoodsCreateInfoList) ->
    role_bag_info_backup(RoleID),
    GoodsList = lists:foldl(
                           fun(GoodsCreateInfo,Acc) ->
								   NewGoodsCreateInfo = mod_cang_bao_tu_fb:hook_gaoji_cang_bao_tu(GoodsCreateInfo),
                                   {ok,TmpGoodsList} = create_p_goods(RoleID, NewGoodsCreateInfo),
                                   lists:append(TmpGoodsList,Acc)
                           end,[],GoodsCreateInfoList),
    [Good|NewGoodList] = lists:sort(fun(Good1,Good2) -> cmp(Good1,Good2) end, GoodsList),
    NewGoodsList2 = tidy_merge_goods([Good],NewGoodList),
    create_goods_by_p_goods(RoleID,NewGoodsList2);

%%同上，不过是创建单个物品，所以对应的@param和@return 都不是list
%%@param  RoleID :: integer()
%%@param  GoodsCreateInfo ::  #r_item_create_info|#r_stone_create_info|#r_equip_create_info
create_goods(RoleID,GoodsCreateInfo) ->
    role_bag_info_backup(RoleID),
	NewGoodsCreateInfo = mod_cang_bao_tu_fb:hook_gaoji_cang_bao_tu(GoodsCreateInfo),
    {ok,GoodsList} =  create_p_goods(RoleID, NewGoodsCreateInfo),
    [Good|NewGoodList] = lists:sort(fun(Good1,Good2) -> cmp(Good1,Good2) end, GoodsList),
    NewGoodsList2 = tidy_merge_goods([Good],NewGoodList),
    create_goods_by_p_goods(RoleID,NewGoodsList2).

%%同上，不过是创建单个物品，所以对应的@param和@return 都不是list
%%@param  RoleID :: integer()
%%@param  GoodsCreateInfo ::  #r_item_create_info|#r_stone_create_info|#r_equip_create_info
create_goods(RoleID,BagId,GoodsCreateInfo) ->
	role_bag_info_backup(RoleID),
	NewGoodsCreateInfo = mod_cang_bao_tu_fb:hook_gaoji_cang_bao_tu(GoodsCreateInfo),
	{ok,GoodsList} =  create_p_goods(RoleID, NewGoodsCreateInfo),
	[Good|NewGoodList] = lists:sort(fun(Good1,Good2) -> cmp(Good1,Good2) end, GoodsList),
	NewGoodsList2 = tidy_merge_goods([Good],NewGoodList),
	AccList = 
		lists:foldl(
		  fun(Record,Acc) ->
				  {ok, ResultList} = create_goods_by_p_goods(RoleID,BagId,Record),
				  lists:append([ResultList,Acc])
		  end,[],NewGoodsList2),
	{ok,AccList}.


%%@doc 批量创建物品,这里只是给每件物品设置bagid，position和goodsid
%%@param   RoleID               角色ID
%%@param   GoodsInfoList        #p_goods的列表
%%@return  {ok,NewGoodsInfoList}创建成功以后的物品的信息列表 | {error,Reason}
create_goods_by_p_goods(RoleID, GoodsInfoList) when is_list(GoodsInfoList) ->
    role_bag_info_backup(RoleID),
    {NewGoodsInfoList,GoodsInfoList2} = atmoic_merge(RoleID, GoodsInfoList),
    PosNum = length(GoodsInfoList2),
    case get_empty_bag_pos(RoleID,PosNum) of
        {ok,PosNum,PosList} ->
           {[],NewGoodsInfoList2} = lists:foldl(
                                     fun(GoodsInfo,{[{BagID,Pos}|PosList2],Acc}) ->
                                             GoodsID = get_new_goodsid(RoleID),
                                             NewGoodsInfo = GoodsInfo#p_goods{id=GoodsID,bagid=BagID,bagposition=Pos,roleid=RoleID},
                                             add_new_goods(RoleID,BagID,Pos,NewGoodsInfo),
                                             {PosList2,[NewGoodsInfo|Acc]}
                                     end,{PosList,[]},GoodsInfoList2),
            {ok,lists:append(NewGoodsInfoList,NewGoodsInfoList2)};
        {error,Reason} ->
            throw({bag_error,Reason})
    end;
%%在背包中创建物品
create_goods_by_p_goods(RoleID,GoodsInfo) when is_record(GoodsInfo,p_goods)->
	role_bag_info_backup(RoleID),
	case atmoic_merge(RoleID,GoodsInfo) of
	{ok,NewGoodsInfo} ->
		{ok,[NewGoodsInfo]};
	_ ->
		case get_empty_bag_pos(RoleID,1) of
		{ok,1,[{BagID,Pos}]} ->
			GoodsID = get_new_goodsid(RoleID),
			NewGoodsInfo2 = GoodsInfo#p_goods{id=GoodsID,bagid=BagID,bagposition=Pos,roleid=RoleID},
			add_new_goods(RoleID,BagID,Pos,NewGoodsInfo2),                        
			{ok,[NewGoodsInfo2]};
		{error,Reason} ->
			throw({bag_error,Reason})
		end
	end.

%%@doc  在指定的背包id中创建物品
create_goods_by_p_goods(RoleID,BagID,GoodsInfo) when is_record(GoodsInfo,p_goods)->
    role_bag_info_backup(RoleID),
    case get_empty_bag_pos(RoleID,BagID,1) of
        {ok,1,[{BagID,Pos}]} ->
            GoodsID = get_new_goodsid(RoleID),
            NewGoodsInfo = GoodsInfo#p_goods{id=GoodsID,bagid=BagID,bagposition=Pos,roleid=RoleID},
            add_new_goods(RoleID,BagID,Pos,NewGoodsInfo),                        
            {ok,[NewGoodsInfo]};
        {error,Reason} ->
            throw({bag_error,Reason})
    end.

%%@doc  在指定的背包id中创建物品
create_goods_by_p_goods(RoleID,BagID,Pos,GoodsInfo) when is_record(GoodsInfo,p_goods)->
    role_bag_info_backup(RoleID),
    case get_goods_by_position(BagID, Pos, RoleID) of
        false ->
            GoodsID = get_new_goodsid(RoleID),
            NewGoodsInfo = GoodsInfo#p_goods{id=GoodsID,bagid=BagID,bagposition=Pos,roleid=RoleID},
            add_new_goods(RoleID,BagID,Pos,NewGoodsInfo),                        
            {ok,[NewGoodsInfo]};
        _ ->
            throw({bag_error,position_used})
    end.

%% @doc 根据p_goods创建在背包中创建道具，不重新生成ID
create_goods_by_p_goods_and_id(RoleID, GoodsInfoList) when is_list(GoodsInfoList) ->
    role_bag_info_backup(RoleID),
    {NewGoodsInfoList,GoodsInfoList2} = atmoic_merge(RoleID,GoodsInfoList),
    PosNum = length(GoodsInfoList2),
    case get_empty_bag_pos(RoleID,PosNum) of
        {ok,PosNum,PosList} ->
            {[],NewGoodsInfoList2} = lists:foldl(
                                       fun(GoodsInfo,{[{BagID,Pos}|PosList2],Acc}) ->
                                               #p_goods{id=GoodsID} = GoodsInfo,
                                               NewGoodsInfo = GoodsInfo#p_goods{id=GoodsID,bagid=BagID,bagposition=Pos,roleid=RoleID},
                                               add_new_goods(RoleID,BagID,Pos,NewGoodsInfo),
                                               {PosList2,[NewGoodsInfo|Acc]}
                                       end,{PosList,[]},GoodsInfoList2),
            {ok,lists:append(NewGoodsInfoList,NewGoodsInfoList2)};
        {error,Reason} ->
            throw({bag_error,Reason})
    end;

create_goods_by_p_goods_and_id(RoleID, GoodsInfo) ->
    create_goods_by_p_goods_and_id(RoleID, [GoodsInfo]).

%% @doc 根据p_goods在背包指定创建道具，不重新生成ID
create_goods_by_p_goods_and_id(RoleID,BagID,Pos,GoodsInfo) when is_record(GoodsInfo,p_goods)->
    role_bag_info_backup(RoleID),
    case get_goods_by_position(BagID, Pos, RoleID) of
        false ->
            #p_goods{id=GoodsID} = GoodsInfo,
            NewGoodsInfo = GoodsInfo#p_goods{id=GoodsID,bagid=BagID,bagposition=Pos,roleid=RoleID},
            add_new_goods(RoleID,BagID,Pos,NewGoodsInfo),                        
            {ok,[NewGoodsInfo]};
        _ ->
            throw({bag_error,position_used})
    end.

%%@doc 批量删除物品，成功则全部删除，否则都不会删除
%%@param   RoleID               角色ID
%%@param   GoodsIDList|GoodsID          要删除的物品ID的列表 | 要删除的物品ID
%%@return  {ok,OldGoodsInfoList}被删除的物品之前的信息 | {error,Reason}
delete_goods(RoleID,GoodsIDList) when is_list(GoodsIDList) ->
    role_bag_info_backup(RoleID),
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            throw({bag_error,goods_not_found});
        IDList ->
            OldGoodsInfoList = lists:foldr(
                                 fun(GoodsID,Acc) ->
                                         case lists:foldl(
                                                fun({BagID,_Detail},Acc2) ->
                                                        case Acc2 of
                                                            {ok,_GoodsInfo} ->
                                                                Acc2;
                                                            _ ->
                                                                delete_goods(RoleID,BagID,GoodsID)
                                                        end
                                                end,{error,goods_not_found},IDList) of
                                             {ok,GoodsInfo} ->
                                                 [GoodsInfo|Acc];
                                             {error,Reason} ->
                                                 throw({bag_error,Reason})
                                         end
                                 end,[],GoodsIDList),
            {ok,OldGoodsInfoList}
    end;
delete_goods(RoleID,GoodsID) when is_integer(GoodsID) ->
    role_bag_info_backup(RoleID),
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            throw({bag_error,goods_not_found});
        IDList ->
            case lists:foldl(
                   fun({BagID,_Detail},Acc) ->
                           case Acc of
                               {ok,_GoodsInfo} ->
                                   Acc;
                               _ ->
                                   delete_goods(RoleID,BagID,GoodsID)
                           end
                   end,{error,goods_not_found},IDList) of
                {ok,GoodsInfo} ->
                    {ok,[GoodsInfo]};
                {error,Reason} ->
                    throw({bag_error,Reason})
            end
    end.
delete_goods(RoleID,BagID,GoodsID) ->
    role_bag_info_backup(RoleID),
    {_Content,_OutUseTime,_UsedPositionList,GoodsList,_} = get({?ROLE_BAG,RoleID,BagID}),
    Index = #p_goods.id,
    case lists:keyfind(GoodsID,Index,GoodsList) of
        false ->
            {error,goods_not_found};
        GoodsInfo ->
            delete_exist_goods(GoodsInfo,RoleID,BagID),
            {ok,GoodsInfo}
    end.


%%@doc 根据类型删除仓库中的物品
%%@return {ok,DelGoodsList}
delete_depositroy_goods_by_typeid(RoleID,TypeID) when is_integer(RoleID),is_integer(TypeID) ->
    role_bag_info_backup(RoleID),
    DelGoodsList = lists:foldl(fun(BagID,Acc)->
                                   case  get({?ROLE_BAG,RoleID,BagID}) of
                                       undefined ->
                                           Acc;
                                       {_Content,_OutUseTime,_UsedPositionList,GoodsList,_} ->
                                           MatchGoodsList = lists:filter(fun(G)->
                                                                             G#p_goods.typeid =:= TypeID
                                                                         end, GoodsList),
                                           lists:foreach(fun(G)->
                                                             delete_exist_goods(G,RoleID,BagID)
                                                         end, MatchGoodsList),
                                           lists:merge(Acc, MatchGoodsList)
                                   end
                               end, [], ?DEPOT_BAG_ID_LIST),
    {ok,DelGoodsList}.

delete_depositroy_goods(RoleID,BagID,GoodsID) ->
    role_bag_info_backup(RoleID),
    case  get({?ROLE_BAG,RoleID,BagID}) of
        undefined ->
            throw({bag_error,bag_not_exist});
        {_Content,_OutUseTime,_UsedPositionList,GoodsList,_} ->
            case lists:keyfind(GoodsID,#p_goods.id,GoodsList) of
                false ->
                    throw({bag_error,goods_not_found});
                GoodsInfo ->
                    delete_exist_goods(GoodsInfo,RoleID,BagID),
                    {ok,[GoodsInfo]}
            end
    end.

%%@doc 删除背包内的所有某种类型物品
%%@param   RoleID               角色ID
%%@param   TypeID               物品类型ID
%%@return  {ok,OldGoodsInfoList}被删除的物品之前的信息 | {error,Reason}
delete_goods_by_typeid(RoleID,TypeID) ->
    role_bag_info_backup(RoleID),
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            throw({bag_error,goods_not_found});
        IDList ->
            List = lists:foldl(
                     fun({BagID,_Detail},Acc) ->
                             {_Content,_OutUseTime,_UsedPositionList,GoodsList,_} = get({?ROLE_BAG,RoleID,BagID}),  
                             lists:foldr(
                               fun(GoodsInfo,Acc2) ->
                                       case GoodsInfo#p_goods.typeid =:= TypeID of
                                           true ->
                                               delete_exist_goods(GoodsInfo,RoleID,BagID),
                                               [GoodsInfo|Acc2];
                                           false ->
                                               Acc2
                                       end
                               end,Acc,GoodsList)
                     end,[],IDList),
            {ok,List}
    end.


%%@doc 批量更新物品，成功则全部跟新，返回跟新前和更新后的相关的物品信息的列表，每件更新的物品必须存在才能更新
%%@param   RoleID                角色ID
%%@param   GoodsInfoList         要跟新的物品#p_goods的列表
%%@return  {ok,OldGoodsInfoList，NewGoodsInfo}被跟新的物品之前的信息和之后的信息 | {error,Reason}
update_goods(RoleID,GoodsInfoList) when is_list(GoodsInfoList) ->
    role_bag_info_backup(RoleID),
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            throw({bag_error,goods_not_found});
        IDList ->
            OldGoodsInfoList = lists:foldl(
                                 fun(GoodsInfo,Acc) ->
                                         case lists:foldl(
                                                fun({BagID,_Detail},Acc2) ->
                                                        case Acc2 of
                                                            {ok,_GoodsInfo2} ->
                                                                Acc2;
                                                            _ ->
                                                                update_goods(RoleID,BagID,GoodsInfo)
                                                        end
                                                end,{error,goods_not_found},IDList) of
                                             {ok,OldGoodsInfo} ->
                                                 [OldGoodsInfo|Acc];
                                             {error,Reason} ->
                                                 throw({bag_error,Reason})
                                         end
                                 end,[],GoodsInfoList),
            {ok,OldGoodsInfoList}
    end;
%%doc  同上，单个跟新物品，不过返回值也是一个list
update_goods(RoleID,GoodsInfo) ->
    role_bag_info_backup(RoleID),
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            throw({bag_error,goods_not_found});
        IDList ->
            case lists:foldl(
                   fun({BagID,_Detail},Acc) ->
                           case Acc of
                               {ok,_GoodsInfo2} ->
                                   Acc;
                               _ ->
                                   update_goods(RoleID,BagID,GoodsInfo)
                           end
                   end,{error,goods_not_found},IDList) of
                {ok,OldGoodsInfo} ->
                    {ok,[OldGoodsInfo]};
                {error,Reason} ->
                    throw({bag_error,Reason})
            end
    end.
   
   
update_goods(RoleID,BagID,GoodsInfo) ->
    case GoodsInfo#p_goods.current_num > 0 of
        true ->

            {Content,OutUseTime,UsedPositionList,GoodsList,_} = get({?ROLE_BAG,RoleID,BagID}),
            Index = #p_goods.id,
            case lists:keyfind(GoodsInfo#p_goods.id,Index,GoodsList) of
                false ->
                    {error,goods_not_found};
                OldGoodsInfo ->
                    NewGoodsList = lists:keyreplace(GoodsInfo#p_goods.id,Index,GoodsList,GoodsInfo),
                    put({?ROLE_BAG,RoleID,BagID},{Content,OutUseTime,UsedPositionList,NewGoodsList,true}),
                    {ok,OldGoodsInfo}
            end;
        false ->
            throw({bag_error,goods_num_is_zero})
    end.


%%@doc 移动背包内物品的位置(对应的实际逻辑操作可能是换位置，合并等)
swap_goods(GoodsID1, Position2, BagID2, RoleID) ->
    role_bag_info_backup(RoleID),
    case get_goods_by_id(RoleID,GoodsID1) of
        {error,goods_not_found} ->
            throw({bag_error,goods_not_found});
        {ok,GoodsInfo} ->
            case get_goods_by_position(BagID2, Position2, RoleID) of
                false ->
                    move_to_empty_position(GoodsInfo, Position2, BagID2, RoleID);
                DestGoodsInfo ->
                    case GoodsID1 =:= DestGoodsInfo#p_goods.id of
                        true ->
                            throw({bag_error,can_not_merge_same_goods});
                        false ->
                            ignore
                    end,
                    case check_can_merge(GoodsInfo,DestGoodsInfo) of
                        true ->
                            Num = GoodsInfo#p_goods.current_num,
                            DestNum =  DestGoodsInfo#p_goods.current_num,
                            case Num + DestNum =< ?MAX_OVER_LAP of
                                true ->
                                    merge_goods(GoodsInfo, DestGoodsInfo, RoleID);
                                false ->
                                    merge_goods(GoodsInfo, DestGoodsInfo, ?MAX_OVER_LAP-DestNum, RoleID)
                            end;
                        false ->
                            change_position(GoodsInfo, DestGoodsInfo, RoleID)
                    end
            end
    end.
                    
            
divide_goods(GoodsID1, DivideNum, Position2, BagID2, RoleID) ->
    role_bag_info_backup(RoleID),
    case get_goods_by_id(RoleID,GoodsID1) of
        {error,goods_not_found} ->
            throw({bag_error,goods_not_found});
        {ok,GoodsInfo} ->
            case GoodsInfo#p_goods.current_num > DivideNum 
                                       andalso DivideNum > 0 
                                       andalso check_can_divide(GoodsInfo) of
                true ->
                    case get_goods_by_position(BagID2, Position2, RoleID) of
                        false ->
                            divide_goods2(GoodsInfo,DivideNum,BagID2,Position2,RoleID);
                        DestGoodsInfo ->
                            case GoodsID1 =:= DestGoodsInfo#p_goods.id of
                                true ->
                                    throw({bag_error,can_not_merge_same_goods});
                                false ->
                                    ignore
                            end,
                            case check_can_merge(GoodsInfo,DestGoodsInfo) of
                                true ->
                                    DestNum = DestGoodsInfo#p_goods.current_num,
                                    case DivideNum + DestNum =< ?MAX_OVER_LAP of
                                        true ->
                                            merge_goods(GoodsInfo, DestGoodsInfo, DivideNum, RoleID);
                                        false ->
                                            merge_goods(GoodsInfo, DestGoodsInfo, ?MAX_OVER_LAP-DestNum, RoleID)
                                    end;
                                false ->
                                    throw({bag_error,invail_data})
                            end
                    end;
                false ->
                    throw({bag_error,invail_data})
            end
    end.

divide_goods2(GoodsInfo,DivideNum,BagID,Position,RoleID) ->
    GoodsID = get_new_goodsid(RoleID),
    OldNum = GoodsInfo#p_goods.current_num,
    NewGoodsInfo1 = GoodsInfo#p_goods{current_num=OldNum-DivideNum},
    NewGoodsInfo2 = GoodsInfo#p_goods{id = GoodsID, current_num=DivideNum, bagid=BagID, bagposition=Position},
    add_new_goods(RoleID,BagID,Position,NewGoodsInfo2),
    OldBagID = GoodsInfo#p_goods.bagid,
    {Content,OutUseTime,UsedPositionList,GoodsList,_} = get({?ROLE_BAG,RoleID,OldBagID}),
    NewGoodsList = lists:keyreplace(GoodsInfo#p_goods.id,#p_goods.id,GoodsList,NewGoodsInfo1),
    put({?ROLE_BAG,RoleID,OldBagID},{Content,OutUseTime,UsedPositionList,NewGoodsList,true}),
    {ok,NewGoodsInfo1,NewGoodsInfo2}.



%%doc 获取玩家指定背包的指定位置上的物品信息，如果没有物品返回false，背包不存在则跑出异常
get_goods_by_position(BagID, Position, RoleID) ->
    case get({?ROLE_BAG,RoleID,BagID}) of
        undefined ->
            throw({bag_error,bag_not_exist});
        {Content,_OutUseTime,_UsedPositionList,GoodsList,_} ->
            case Content >= Position of
                true ->
                    Index = #p_goods.bagposition,
                    lists:keyfind(Position,Index,GoodsList);
                false ->
                    throw({bag_error,bag_not_pos})
            end
    end.

%% @doc 根据物品ID获取物品信息，赃读数据库，包括背包以及仓库，天工炉 {ok, GoodsInfo} | {error, Reason}
get_dirty_goods_by_id(RoleID, GoodsID) ->
    case db:dirty_read(?DB_ROLE_BAG_BASIC_P, RoleID) of
        [] ->
            ?ERROR_MSG("~ts", ["赃读玩家背包列表为空"]),
            {error, system_error};
        [BagInfoRecord] ->
            #r_role_bag_basic{bag_basic_list=BagInfoList} = BagInfoRecord,

            get_dirty_goods_by_id2(RoleID, GoodsID, BagInfoList)
    end.

get_dirty_goods_by_id2(_RoleID, _GoodsID, []) ->
    {error, not_found};
get_dirty_goods_by_id2(RoleID, GoodsID, [{BagID, _BagType, _DueTime, _Rows, _Columns, _GridNumber}|T]) ->
    RoleBagKey = {RoleID, BagID},

    case db:dirty_read(?DB_ROLE_BAG_P, RoleBagKey) of
        [] ->
            get_dirty_goods_by_id2(RoleID, GoodsID, T);

        [#r_role_bag{bag_goods=GoodsList}] ->
            case lists:keyfind(GoodsID, #p_goods.id, GoodsList) of
                false ->
                    get_dirty_goods_by_id2(RoleID, GoodsID, T);

                GoodsInfo ->
                    {ok, GoodsInfo}
            end
    end.

%%doc 根据物品ID或者物品信息 {ok,GoodsInfo} | {error,Reason}
get_goods_by_id(RoleID,GoodsID) ->            
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            {error,goods_not_found};
        IDList ->
           Ret = lists:foldl(
              fun({BagID,_Detail},Acc) ->
                      case Acc of
                          {ok,_GoodsInfo} ->
                              Acc;
                          {error,goods_not_found} ->
                              {_Content,_OutUseTime,_UsedPositionList,GoodsList,_} = get({?ROLE_BAG,RoleID,BagID}),
                              Index = #p_goods.id,
                              case lists:keyfind(GoodsID,Index,GoodsList) of
                                  false ->
                                      {error,goods_not_found};
                                  GoodsInfo ->
                                      {ok,GoodsInfo}
                              end
                      end
              end, {error,goods_not_found}, IDList),

            case Ret of
                {error,goods_not_found} ->
                    case get({?ROLE_DEPOSITORY_LIST,RoleID}) of
                        undefined ->
                            {error,goods_not_found};
                        IDList2 ->
                            lists:foldl(
                              fun({BagID2,_Detail2},Acc2) ->
                                      case Acc2 of
                                          {ok,_GoodsInfo2} ->
                                              Acc2;
                                          {error,goods_not_found} ->
                                              {_Content2,_OutUseTime2,_UsedPositionLis2t,GoodsList2,_} = get({?ROLE_BAG,RoleID,BagID2}),
                                              case lists:keyfind(GoodsID,#p_goods.id,GoodsList2) of
                                                  false ->
                                                      {error,goods_not_found};
                                                  GoodsInfo2 ->
                                                      {ok,GoodsInfo2}
                                              end
                                      end
                              end, {error,goods_not_found} , IDList2)
                    end;
                {ok,GoodsInfo} ->
                    {ok,GoodsInfo}
            end                    
    end.

get_goods_num(GoodsList) ->
    get_goods_num(GoodsList, 0).

get_goods_num([], Num) -> Num;
get_goods_num([Goods | Rest], Num) ->
    get_goods_num(Rest, Num + Goods#p_goods.current_num).

get_bind_goods_num(GoodsList) ->
    get_bind_goods_num(GoodsList, 0).

get_bind_goods_num([], Num) -> Num;
get_bind_goods_num([Goods | Rest], Num) ->
    AddNum = case Goods#p_goods.bind of
        false -> 0;
        true  -> Goods#p_goods.current_num
    end,
    get_bind_goods_num(Rest, Num + AddNum).

get_goods_by_typeid(RoleID,TypeID,BagIDs) ->
    {ok,lists:foldl(
          fun(BagID,AccList1) ->
                  case get({?ROLE_BAG,RoleID,BagID}) of
                      undefined ->
                          AccList1;
                      {_Content,_OutUseTime,_UsedPositionList,GoodsList,_} ->
                          lists:foldl(
                            fun(Goods,AccList2) ->
                                    if Goods#p_goods.typeid =:= TypeID ->
                                            [Goods|AccList2];
                                       true ->
                                            AccList2
                                    end
                            end,AccList1,GoodsList)
                  end
          end,[],BagIDs)}.

%%@doc 获取需要持久化的玩家的背包信息，并设置持久化标志位
%%@return list()
get_role_bag_persistent_info(RoleID) ->
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            IDList = [];
        IDList ->
            ignore
    end,
    
    case get({?ROLE_DEPOSITORY_LIST,RoleID}) of
        undefined ->
            IDList2 = [];
        IDList2 ->
            ignore
    end,
    
    BagsList = lists:foldl(
      fun({BagID,_Detail},Acc) ->
              case get_role_bag_persistent_info_2(RoleID,BagID) of
                  ignore ->
                      Acc;
                  Info ->
                      [Info|Acc]
              end
      end,[],lists:append(IDList, IDList2)),
    BagMaxId = get({?role_bag_max_goodsid,RoleID}),
    [{{?role_bag_max_goodsid,RoleID},BagMaxId}|BagsList].

get_role_bag_persistent_info_2(RoleID,BagID) ->
    case get({?ROLE_BAG,RoleID,BagID}) of
        undefined ->
            ?ERROR_MSG("error when persistent_map_role_bag_info,roleid=~w,bagid=~w",[RoleID,BagID]),
            ignore;
        {Content,OutUseTime,UsedPositionList,GoodsList,Modified} ->
            case Modified of
                true ->
                    erlang:put({?ROLE_BAG,RoleID,BagID}, {Content,OutUseTime,UsedPositionList,GoodsList,false}),
                    #r_role_bag{role_bag_key={RoleID,BagID},bag_goods=GoodsList};
                false ->
                    ignore
            end
    end.

%%@doc 持久化玩家的背包信息到数据库
%% role_bag_info_persistent(RoleID) ->
%%     case get({?ROLE_BAG_LIST,RoleID}) of
%%         undefined ->
%%             ignore;
%%         IDList ->
%%             lists:foreach(
%%               fun({BagID,_Detail}) ->
%%                       persistent_map_role_bag_info(RoleID,BagID)
%%               end,IDList)
%%     end,
%%     case get({?ROLE_DEPOSITORY_LIST,RoleID}) of
%%         undefined ->
%%             ignore;
%%         IDList2 ->
%%             lists:foreach(
%%               fun({BagID,_Detail}) ->
%%                       persistent_map_role_bag_info(RoleID,BagID)
%%               end,IDList2)
%%     end.
%% 
%% 
%% persistent_map_role_bag_info(RoleID,BagID) ->
%%     case get({?ROLE_BAG,RoleID,BagID}) of
%%         undefined ->
%%             ?ERROR_MSG("error when persistent_map_role_bag_info,roleid=~w,bagid=~w",[RoleID,BagID]);
%%         {Content,OutUseTime,UsedPositionList,GoodsList,Modified} ->
%%             case Modified of
%%                 true ->
%%                     mgeem_persistent:role_bag_persistent(#r_role_bag{role_bag_key={RoleID,BagID},bag_goods=GoodsList}),
%%                     erlang:put({?ROLE_BAG,RoleID,BagID}, {Content,OutUseTime,UsedPositionList,GoodsList,false});
%%                 false ->
%%                     ignore
%%             end
%%     end.

%% @doc 更新背包信息
update_bag_info_by_id(RoleID, BagID, BagInfo) ->
    case get({?ROLE_BAG_LIST, RoleID}) of
        undefined ->
            throw({bag_error, system_error});
        RoleBagList ->
            RoleBagList2 = lists:keyreplace(BagID, 1, RoleBagList, {BagID, BagInfo}),
            put({?ROLE_BAG_LIST, RoleID}, RoleBagList2),
            update_bag_info_by_id2(RoleID, BagID, BagInfo)
    end.
update_bag_info_by_id2(RoleID, BagID, BagInfo) ->
    {_BagID, _BagTypeID, _OutUseTime, _Rows, _Clowns,GridNumber} = BagInfo,
    case get({?ROLE_BAG, RoleID, BagID}) of
        undefined ->
            throw({bag_error, system_error});
        {_, OutUseTime, UsedPositionList, GoodsList, _} ->
            put({?ROLE_BAG, RoleID, BagID}, {GridNumber, OutUseTime, UsedPositionList, GoodsList, true})
    end.

%%doc 创建新的背包，使用扩展背包或者添加仓库
create_bag(RoleID,{BagID,BagTypeID,OutUseTime,Rows,Clowns,GridNumber}) ->
    role_bag_info_backup(RoleID),
    case get({?ROLE_BAG,RoleID,BagID}) of
        undefined ->
            case common_bag2:is_depository_bag(BagID) of 
                true ->
                    case get({?ROLE_DEPOSITORY_LIST,RoleID}) of
                        undefined ->
                            throw({bag_error,system_error});
                        IDList ->
                            NewList = [{BagID, {BagID,BagTypeID,OutUseTime,Rows,Clowns,GridNumber}}|IDList],
                            put({?ROLE_DEPOSITORY_LIST,RoleID},lists:sort(fun(E1,E2)-> common_bag2:baglist_cmp(E1,E2) end,NewList)),
                            put({?ROLE_BAG,RoleID,BagID}, {GridNumber,OutUseTime,[],[],true})
                    end;
                false ->
                    case get({?ROLE_BAG_LIST,RoleID}) of
                        undefined ->
                            throw({bag_error,system_error});
                        IDList ->
                            %% 玩家使用扩展背包，直接在主背包扩展位置
                            MainBagID = 1,
                            {MainBagID,{MainBagID,MainTypeID,MainOutUseTime,_MainRows,MainClowns,MainGridNumber}} = lists:keyfind(MainBagID,1,IDList),
                            IDList2 = lists:keydelete(MainBagID,1,IDList),
                            case (MainGridNumber + GridNumber) rem MainClowns of
                                0 ->
                                    MainRows2 = (MainGridNumber + GridNumber) div MainClowns;
                                _ ->
                                    MainRows2 = (MainGridNumber + GridNumber) div MainClowns + 1
                            end,
                            NewList = [{MainBagID, {MainBagID,MainTypeID,MainOutUseTime,MainRows2,MainClowns,MainGridNumber + GridNumber}}|IDList2],
                            put({?ROLE_BAG_LIST,RoleID},lists:sort(fun(E1,E2)-> common_bag2:baglist_cmp(E1,E2) end,NewList)),
                            {_OldGridNumber,OldOutUseTime,MainUsedPositionList,MainGoodsList,MainModified} = get({?ROLE_BAG,RoleID,MainBagID}),
                            put({?ROLE_BAG,RoleID,MainBagID},{MainGridNumber + GridNumber,OldOutUseTime,MainUsedPositionList,MainGoodsList,MainModified})
                    end
            end;
        _ ->
            throw({bag_error,bag_exist})
    end.


%%doc 删除背包，去掉扩展背包时使用
delete_bag(RoleID, MainBagID, MainRows, MainClowns, MainGridNumber) ->
    role_bag_info_backup(RoleID),
    case get({?ROLE_BAG,RoleID,MainBagID}) of
        undefined ->
            throw({bag_error,bag_not_exist});
        {_Content,OutUseTime,UsedPosList,GoodsList,Modified} ->
           put({?ROLE_BAG,RoleID,MainBagID},{MainGridNumber,OutUseTime,UsedPosList,GoodsList,Modified})
    end,
    IDList = get({?ROLE_BAG_LIST,RoleID}),
    case lists:keyfind(MainBagID,1,IDList) of
        false ->
            throw({bag_error,system_error});
        {MainBagID,{MainBagID,MainTypeID,MainOutUseTime,_OldMainRows,_OldMainClowns,_OldMainGridNumber}} ->
            IDList2 = lists:keydelete(MainBagID,1,IDList),
            put({?ROLE_BAG_LIST,RoleID},[{MainBagID,{MainBagID,MainTypeID,MainOutUseTime,MainRows,MainClowns,MainGridNumber}}|IDList2])
    end.


%%doc 整理背包
%%param roleid  bagid
%%return  {ok,NewGoodsList} 
tidy_bag(RoleID, BagID) ->
    role_bag_info_backup(RoleID),
    case get({?ROLE_BAG,RoleID,BagID}) of
        undefined ->
            throw({bag_error,bag_not_exist});
        {Content,OutUseTime,_UsedPosList,GoodsList,_Modified} ->
            case length(GoodsList) > 0 of
                true ->
                    [Good|NewGoodList] = lists:sort(fun(Good1,Good2) -> cmp(Good1,Good2) end, GoodsList),
                    NewGoodList2 = tidy_merge_goods([Good],NewGoodList),
                    {Pos,NewGoodsList3} = lists:foldr(
                                          fun(TmpGood,{Pos,List}) ->
                                                  {Pos+1,[TmpGood#p_goods{bagposition = Pos}|List]}
                                          end,{1,[]},NewGoodList2),
                    NewUsedPositionList = lists:seq(1,Pos-1),
                    put({?ROLE_BAG,RoleID,BagID},{Content,OutUseTime,NewUsedPositionList,NewGoodsList3,true}),
                    {ok,NewGoodsList3};
              _ ->
                    {ok,[]}
            end
    end.

get_goods_num_by_typeid(RoleID, TypeID) ->
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            {ok, 0};
        BagList ->
            BagIDList = lists:map(fun({BagID, _})-> BagID end, BagList),
            get_goods_num_by_typeid(BagIDList, RoleID, TypeID)
    end.

%% @doc 根据typeid获取物品个数 {ok, Num}
get_goods_num_by_typeid(BagIDList, RoleID, TypeID) ->
    lists:foldl(
    fun(BagID, Result) ->
        case get({?ROLE_BAG, RoleID, BagID}) of
            undefined ->
                Result;
            {_Content, _OutUseTime, _UsedPositionList, GoodsList, _Modifiled} ->
                lists:foldl(
                fun(GoodsInfo, Result2) ->
                     {ok, Num} = Result2,
                     CheckTypeID = GoodsInfo#p_goods.typeid,
                     if
                         TypeID =:= CheckTypeID ->
                             CurrentNum = GoodsInfo#p_goods.current_num,
                             {ok, Num+CurrentNum};
                         true ->
                             Result2
                     end
                end, Result, GoodsList)
        end
    end, {ok, 0}, BagIDList).

get_goods_num_by_typeid(BagIDList, RoleID, TypeID, Bind) ->
    {ok, 
     lists:foldl(
       fun(BagID, AccNum) ->
               case get({?ROLE_BAG, RoleID, BagID}) of
                   undefined ->
                       AccNum;
                   {_Content, _OutUseTime, _UsedPositionList, GoodsList, _Modifiled} ->
                       lists:foldl(
                         fun(GoodsInfo, AccNum2) ->
                                 if
                                     TypeID =:= GoodsInfo#p_goods.typeid andalso Bind =:= GoodsInfo#p_goods.bind ->
                                         AccNum2 + GoodsInfo#p_goods.current_num;
                                     true ->
                                         AccNum2
                                 end
                         end, AccNum, GoodsList)
               end
       end, 0, BagIDList)}.

%%=================LOCAL FUNCTION==========================
create_p_goods(RoleID, Info) ->
    #r_goods_create_info{bind=Bind, bag_id=BagID, position=Pos, type=Type, type_id=TypeID, start_time=StartTime, end_time=EndTime,
                        num=Num, color=Color, quality=Quality, punch_num=PunchNum, property=Property, rate=Rate, result=Result,
                        result_list=ResultList, interface_type=InterfaceType,sub_quality = SubQuality,use_pos=UsePosList} = Info,

    %%增加创建物品时负数的判断
    case Num =< 0 of
        true ->
            ?ERROR_MSG("创建物品时，传递的个数为0, call stack: ~w", [erlang:get_stacktrace()]),
            throw({bag_error,goods_not_found});
        false ->
            ignore
    end,

    case Type of
        ?TYPE_ITEM ->
            Info2 = #r_item_create_info{role_id=RoleID, bag_id=BagID, bagposition=Pos, num=Num, typeid=TypeID, bind=Bind,
                                        start_time=StartTime, end_time=EndTime, color=Color,use_pos=UsePosList},
            mod_item:create_item(Info2);
        ?TYPE_STONE ->
            Info2 = #r_stone_create_info{role_id=RoleID, bag_id=BagID, bagposition=Pos, num=Num, typeid=TypeID, bind=Bind,
                                          start_time=StartTime, end_time=EndTime},
            mod_stone:creat_stone(Info2);
        ?TYPE_EQUIP ->
            Info2 = #r_equip_create_info{role_id=RoleID, bag_id=BagID, bagposition=Pos, num=Num, typeid=TypeID, bind=Bind,sub_quality = SubQuality,
                                         start_time=StartTime, end_time=EndTime, color=Color, quality=Quality, punch_num=PunchNum,
                                         property=Property, rate=Rate, result=Result, result_list=ResultList, interface_type=InterfaceType},
            mod_equip:creat_equip(Info2)
    end.

%%@doc 在对玩家背包进行操作前 备份背包信息
role_bag_info_backup(RoleID) -> 
    case get(?ROLE_BAG_TRANSACTION) of
        undefined ->
            throw({bag_error,no_transaction});
        true ->
            case get(bag_locked_role_idlist) of
                undefined ->
                    put(bag_locked_role_idlist,[RoleID]),
                    role_bag_info_backup2(RoleID);
                RoleIDList ->
                    case lists:member(RoleID,RoleIDList) of
                        false ->
                            put(bag_locked_role_idlist,[RoleID|RoleIDList]),
                            role_bag_info_backup2(RoleID);
                        _ ->
                            ignore
                    end
            end
    end.

role_bag_info_backup2(RoleID) ->
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            ?INFO_MSG("can not find role bag list when role_bag_info_backup, role_id=~w",[RoleID]),
            ignore;
        List ->
            put({?ROLE_BAG_LIST_BK,RoleID},List),
            lists:foreach(
              fun({BagID,_BagBasic}) ->
                      BakRoleBag = get({?ROLE_BAG,RoleID,BagID}),
                      put({?ROLE_BAG_BK,RoleID,BagID},BakRoleBag)
              end,List)
    end.


check_inbag2(_GoodsID,_RoleID,[]) ->
    {error,not_found};
check_inbag2(GoodsID,RoleID,[{BagID,_Detail}|IDList]) ->
    case check_inbag(RoleID,GoodsID,BagID) of
        {error,not_found} ->
            check_inbag2(GoodsID,RoleID,IDList);
        {ok,GoodsInfo} ->
            {ok,GoodsInfo}
    end.

check_inbag2(_GoodsID,[]) ->
    {error,not_found};
check_inbag2(GoodsID,[GoodsInfo|List]) ->
    case GoodsInfo#p_goods.id =:= GoodsID of
        true ->
            {ok,GoodsInfo};
        false ->
            check_inbag2(GoodsID,List)
    end.

check_inbag_by_typeid_endtime2(_RoleID,_TypeID,_EndTime,[],[]) ->
    false;
check_inbag_by_typeid_endtime2(_RoleID,_TypeID,_EndTime,[],FoundGoodsList) ->
    {ok,FoundGoodsList};
check_inbag_by_typeid_endtime2(RoleID,TypeID,EndTime,[{BagID,_}|BagBasicList],FoundGoodsList) ->
    case get({?ROLE_BAG,RoleID,BagID}) of
        undefined ->
            check_inbag_by_typeid_endtime2(RoleID,TypeID,EndTime,BagBasicList,FoundGoodsList);
        {_Content,_OutUseTime,_UsedPositionList,GoodsList,_Modifiled} ->
            NewFoundGoodsList = check_inbag_by_typeid_endtime3(RoleID,TypeID,EndTime,GoodsList,FoundGoodsList),
            check_inbag_by_typeid_endtime2(RoleID,TypeID,EndTime,BagBasicList,NewFoundGoodsList)    
    end.

check_inbag_by_typeid_endtime3(_RoleID,_TypeID,_EndTime,[],FoundGoodsList) ->
    FoundGoodsList;
check_inbag_by_typeid_endtime3(RoleID,TypeID,EndTime,[GoodsInfo|GoodsInfoList],FoundGoodsList) ->
    case (TypeID =:= GoodsInfo#p_goods.typeid) andalso (EndTime=:=GoodsInfo#p_goods.end_time orelse EndTime =:=0 ) of
        true ->
            check_inbag_by_typeid_endtime3(RoleID,TypeID,EndTime,GoodsInfoList,[GoodsInfo|FoundGoodsList]);
        false ->
            check_inbag_by_typeid_endtime3(RoleID,TypeID,EndTime,GoodsInfoList,FoundGoodsList)
    end.

judge_bag_exist(RoleID,BagID) ->
    case get({?ROLE_BAG,RoleID,BagID}) of
        undefined ->
            false;
        _ ->
            true
    end.


%%doc  获取玩家背包中指定数目的空格
get_empty_bag_pos(RoleID,PosNum) ->
    case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            {error,role_bag_not_found};
        List ->
            get_empty_bag_pos2(RoleID,PosNum,{0,[]},List)
    end.  

get_empty_bag_pos2(_RoleID,_PosNum,{_Sum,_PosList} ,[]) ->
    {error,{not_enough_pos,0}};
get_empty_bag_pos2(RoleID,PosNum,{Sum,PosList} ,[{BagID,_}|List]) ->
	case get({?ROLE_BAG,RoleID,BagID}) of
	undefined ->
		throw({bag_error,system_error});
	{Content,_OutUseTime,UsedPositionList,_GoodsList,_Modified} ->
		case length(UsedPositionList) =:= Content of
		true ->
			get_empty_bag_pos2(RoleID,PosNum,{Sum,PosList},List);
		false ->
			{NewSum,NewPosList} = get_empty_bag_pos3(RoleID,BagID,PosNum,{Sum,PosList},0,UsedPositionList,Content),
			case NewSum =:= PosNum of
			true ->
				{ok,NewSum,NewPosList};
			false ->
				get_empty_bag_pos2(RoleID,PosNum,{NewSum,NewPosList},List)
			end
		end
	end.
    
get_empty_bag_pos3(_RoleID,_BagID,_PosNum,{Sum,PosList},LastPos,_UsedPosList,Content) when LastPos =:= Content->
    {Sum,PosList};
get_empty_bag_pos3(_RoleID,BagID,PosNum,{Sum,PosList},LastPos,[],Content) ->
    case PosNum - Sum > Content - LastPos of
        true ->
            TmpNum = Content - LastPos;
        false ->
            TmpNum = PosNum - Sum
    end,
    case TmpNum > 0 of
        true -> 
            lists:foldl(fun(Pos,{Sum2,PosList2}) -> {Sum2+1,[{BagID,Pos}|PosList2]} end,{Sum,PosList},lists:seq(LastPos+1,LastPos+TmpNum));  
        false ->
            {Sum,PosList}
    end;
get_empty_bag_pos3(RoleID,BagID,PosNum,{Sum,PosList},LastPos,[UsedPos|UsedPosList],Content) ->
    case UsedPos - LastPos > 1 of
        false ->
            get_empty_bag_pos3(RoleID,BagID,PosNum,{Sum,PosList},UsedPos,UsedPosList,Content);
        true ->
            case UsedPos-LastPos-1 >= PosNum - Sum of
                true ->
                    TmpNum = PosNum - Sum;
                _ ->
                    TmpNum = UsedPos - LastPos - 1
            end,

            {NewSum,NewPosList} = lists:foldl(
                                    fun(Pos,{Sum2,PosList2}) -> 
                                            {Sum2+1,[{BagID,Pos}|PosList2]} 
                                    end,{Sum,PosList},lists:seq(LastPos+1,LastPos+TmpNum)),
            case NewSum =:= PosNum of
                true ->
                    {NewSum,NewPosList};
                false ->
                    get_empty_bag_pos3(RoleID,BagID,PosNum,{NewSum,NewPosList},UsedPos,UsedPosList,Content)
            end
    end.
        
%%doc 获取指定背包的剩余空格
get_empty_bag_pos_num(RoleID,BagID)->
    case get({?ROLE_BAG,RoleID,BagID}) of
        undefined ->
            throw({bag_error,system_error});
        {Content,_OutUseTime,UsedPositionList,_GoodsList,_Modified} ->
            UsedSize = length(UsedPositionList),
            AllSize = Content,
            {ok,AllSize-UsedSize}
    end.
    
%%doc 获取特定的背包中指定数目的空格
get_empty_bag_pos(RoleID,BagID,PosNum) ->
    case get({?ROLE_BAG,RoleID,BagID}) of
        undefined ->
            throw({bag_error,system_error});
        {Content,_OutUseTime,UsedPositionList,_GoodsList,_Modified} ->
            {Sum,PosList} = get_empty_bag_pos3(RoleID,BagID,PosNum,{0,[]},0,UsedPositionList,Content),
            case Sum =:= PosNum of
                true ->
                    {ok, Sum,PosList };
                false ->
                    {error,{not_enough_pos,BagID}}
            end
    end.
    

add_new_goods(RoleID,BagID,Pos,GoodsInfo) ->
    case GoodsInfo#p_goods.current_num < 1 orelse GoodsInfo#p_goods.current_num > ?MAX_OVER_LAP of
        true ->
            throw({bag_error,goods_not_found});
        false ->
            {Content,OutUseTime,UsedPositionList,GoodsList,_} = get({?ROLE_BAG,RoleID,BagID}),
            NewUsedPositionList = lists:sort([Pos|UsedPositionList]),
            put({?ROLE_BAG,RoleID,BagID}, {Content,OutUseTime,NewUsedPositionList,[GoodsInfo|GoodsList],true})
    end.


delete_exist_goods(GoodsInfo,RoleID,BagID) ->
    Pos = GoodsInfo#p_goods.bagposition,
    {Content,OutUseTime,UsedPositionList,GoodsList,_Modified} = get({?ROLE_BAG,RoleID,BagID}),
    NewUsedPositionList = lists:delete(Pos,UsedPositionList),
    NewGoodsList = lists:delete(GoodsInfo,GoodsList),
    put({?ROLE_BAG,RoleID,BagID}, {Content,OutUseTime,NewUsedPositionList,NewGoodsList,true}).

check_can_merge(Info) ->
    Type = Info#p_goods.type,
    TypeID = Info#p_goods.typeid,
    Num = Info#p_goods.current_num,
    case Type of
        ?TYPE_EQUIP ->
            false;
        ?TYPE_ITEM ->
            [BaseInfo] = common_config_dyn:find_item(TypeID),
            #p_item_base_info{usenum=UseNum,is_overlap=IsOverlap}=BaseInfo,
            UseNum =:= 1 andalso IsOverlap =:= 1 andalso Num < ?MAX_OVER_LAP;
        ?TYPE_STONE ->
            Num < ?MAX_OVER_LAP
    end.
check_can_merge(Info1,Info2) ->
    #p_goods{bind = Bind1, end_time  = EndTime1,
             type = Type1, typeid = TypeID1 ,start_time = StartTime1} = Info1,
    #p_goods{bind = Bind2, end_time  = EndTime2,
             type = _Type2, typeid = TypeID2, start_time = StartTime2} = Info2,
    case TypeID1 =:= TypeID2 
	andalso Bind1 =:= Bind2 
	andalso StartTime1 =:= StartTime2 
	andalso EndTime1 =:= EndTime2 of
	true ->
            check_can_merge1(Type1, TypeID1);
	false ->
            ?DEBUG("diff type , type1 = ~p,type2 = ~p",[TypeID1,TypeID2]),
            false
    end.

check_can_merge1(Type1, TypeID1) ->
    case Type1 of
        ?TYPE_EQUIP ->
            false;
        ?TYPE_ITEM ->
            [BaseInfo] = common_config_dyn:find_item(TypeID1),
            #p_item_base_info{usenum=UseNum,is_overlap=IsOverlap}=BaseInfo,
            UseNum =:= 1 andalso IsOverlap =:= 1;
        ?TYPE_STONE ->
            true
    end.


move_to_empty_position(GoodsInfo, Position, BagID, RoleID) ->
    OldBagID = GoodsInfo#p_goods.bagid,
    NewGoodsInfo = GoodsInfo#p_goods{bagid=BagID,bagposition=Position},
    delete_exist_goods(GoodsInfo,RoleID,OldBagID),
    add_new_goods(RoleID,BagID,Position,NewGoodsInfo),
    {ok,none,NewGoodsInfo}.


merge_goods(GoodsInfo1, GoodsInfo2, DivideNum, RoleID) ->
    BagID1 = GoodsInfo1#p_goods.bagid,
    BagID2 = GoodsInfo2#p_goods.bagid,
    #p_goods{current_num=Num1} = GoodsInfo1,
    #p_goods{current_num=Num2} = GoodsInfo2,
    NewGoodsInfo1 = GoodsInfo1#p_goods{current_num=Num1-DivideNum},
    NewGoodsInfo2 = GoodsInfo2#p_goods{current_num=Num2+DivideNum},
    {Content1,OutUseTime1,UsedPositionList1,GoodsList1,_} = get({?ROLE_BAG,RoleID,BagID1}),
    case BagID1 =:= BagID2 of
        true ->
            NewGoodsList = lists:keyreplace(GoodsInfo1#p_goods.id,#p_goods.id,GoodsList1,NewGoodsInfo1),
            NewGoodsList2 = lists:keyreplace(GoodsInfo2#p_goods.id, #p_goods.id, NewGoodsList, NewGoodsInfo2),
            put({?ROLE_BAG,RoleID,BagID1},{Content1,OutUseTime1,UsedPositionList1,NewGoodsList2,true});
        false ->
            {Content2,OutUseTime2,UsedPositionList2,GoodsList2,_} = get({?ROLE_BAG,RoleID,BagID2}),
            NewGoodsList1 = lists:keyreplace(GoodsInfo1#p_goods.id,#p_goods.id,GoodsList1,NewGoodsInfo1),
            NewGoodsList2 = lists:keyreplace(GoodsInfo2#p_goods.id,#p_goods.id,GoodsList2,NewGoodsInfo2),
            put({?ROLE_BAG,RoleID,BagID1},{Content1,OutUseTime1,UsedPositionList1,NewGoodsList1,true}),
            put({?ROLE_BAG,RoleID,BagID2},{Content2,OutUseTime2,UsedPositionList2,NewGoodsList2,true})
    end,
    {ok, NewGoodsInfo1, NewGoodsInfo2}.

merge_goods(GoodsInfo1, GoodsInfo2, RoleID) ->
    Num1 = GoodsInfo1#p_goods.current_num,
    Num2 = GoodsInfo2#p_goods.current_num,
    BagID1 = GoodsInfo1#p_goods.bagid,
    BagID2 = GoodsInfo2#p_goods.bagid,
    NewGoodsInfo = GoodsInfo2#p_goods{current_num = Num1 + Num2},
    delete_exist_goods(GoodsInfo1,RoleID,BagID1),
    {Content,OutUseTime,UsedPositionList,GoodsList,_} = get({?ROLE_BAG,RoleID,BagID2}),
    NewGoodsList = lists:keyreplace(GoodsInfo2#p_goods.id,#p_goods.id,GoodsList,NewGoodsInfo),
    put({?ROLE_BAG,RoleID,BagID2},{Content,OutUseTime,UsedPositionList,NewGoodsList,true}),
    {ok,none,NewGoodsInfo}.
    
change_position(GoodsInfo1, GoodsInfo2, RoleID) ->
    BagID1 = GoodsInfo1#p_goods.bagid,
    BagID2 = GoodsInfo2#p_goods.bagid,
    Pos1 = GoodsInfo1#p_goods.bagposition,
    Pos2 = GoodsInfo2#p_goods.bagposition,
    Index = #p_goods.bagposition,
    NewGoodsInfo1 = GoodsInfo1#p_goods{bagid=BagID2,bagposition=Pos2},
    NewGoodsInfo2 = GoodsInfo2#p_goods{bagid=BagID1,bagposition=Pos1},
    {Content1,OutUseTime1,UsedPositionList1,GoodsList1,_} = get({?ROLE_BAG,RoleID,BagID1}),
    
    case BagID1 =:= BagID2 of
        true ->
            NewGoodsList1 = lists:keyreplace(GoodsInfo1#p_goods.bagposition,Index,GoodsList1,NewGoodsInfo2),
            NewGoodsList2 = lists:keyreplace(GoodsInfo2#p_goods.bagposition,Index,NewGoodsList1,NewGoodsInfo1),
            put({?ROLE_BAG,RoleID,BagID1},{Content1,OutUseTime1,UsedPositionList1,NewGoodsList2,true});
        _ ->
            {Content2,OutUseTime2,UsedPositionList2,GoodsList2,_} = get({?ROLE_BAG,RoleID,BagID2}),
            NewGoodsList1 = lists:keyreplace(GoodsInfo1#p_goods.bagposition,Index,GoodsList1,NewGoodsInfo2),
            NewGoodsList2 = lists:keyreplace(GoodsInfo2#p_goods.bagposition,Index,GoodsList2,NewGoodsInfo1),
            put({?ROLE_BAG,RoleID,BagID1},{Content1,OutUseTime1,UsedPositionList1,NewGoodsList1,true}),
            put({?ROLE_BAG,RoleID,BagID2},{Content2,OutUseTime2,UsedPositionList2,NewGoodsList2,true})
    end,
    {ok,NewGoodsInfo1,NewGoodsInfo2}.



check_can_divide(GoodsInfo) ->
    #p_goods{
              type = Type,
              typeid = TypeID
            } = GoodsInfo,
    case Type of
	?TYPE_EQUIP ->
            false;
	?TYPE_ITEM ->
            [BaseInfo] = common_config_dyn:find_item(TypeID),
            #p_item_base_info{usenum = UseNum} = BaseInfo,
            case UseNum of
		1 ->
                    true;
		_ ->
                    false
            end;
	_ ->
            true
    end.


%%根据type和是否是药品来排序
cmp(Good1,Good2) ->
    #p_goods{type=Type1,typeid=TypeID1}=Good1,
    #p_goods{type=Type2,typeid=TypeID2}=Good2,
    if Type1 < Type2 ->
            true;
       Type1 > Type2 ->
            false;
       Type1 =:= Type2 andalso Type1 =:= ?TYPE_ITEM ->
            R1 = TypeID1 div 100000,
            R2 = TypeID2 div 100000,
            if R1 =:= 102 andalso R2 =:= 102 ->
                    cmp2(Good1,Good2);
               R1 =:= 102 ->
                    true;
               R2 =:= 102 ->
                    false;
               true ->
                    cmp2(Good1,Good2)
            end;
       true ->
            cmp2(Good1,Good2)
    end.
            
%根据typeid来排序
cmp2(Good1,Good2) ->
    #p_goods{typeid=TypeID1}=Good1,
    #p_goods{typeid=TypeID2}=Good2,
    if
       TypeID1 < TypeID2 ->
            true;
       TypeID1 > TypeID2 ->
            false;
       true ->
            cmp3(Good1,Good2)
    end.

%绑定的放前面
cmp3(Good1,Good2) ->
    case Good1#p_goods.bind =:= true andalso Good2#p_goods.bind =:= false of
        true ->
            true;
        false ->
            case Good1#p_goods.bind =:= false andalso Good2#p_goods.bind =:= true of
                true ->
                    false;
               false ->
                   cmp4(Good1,Good2)
           end
    end.

%根据开始时间排序
cmp4(Good1,Good2) ->
    case Good1#p_goods.start_time < Good2#p_goods.start_time of
        true ->
            true;
        false ->
            case Good1#p_goods.start_time > Good2#p_goods.start_time of
                true ->
                    false;
                false ->
                    cmp5(Good1,Good2)
            end
    end.


%根据结束时间排序,如时间一样则用当前个数排序
cmp5(Good1,Good2) ->
    case Good1#p_goods.end_time < Good2#p_goods.end_time of
        true ->
            true;
        false ->
            case Good1#p_goods.end_time > Good2#p_goods.end_time of
                true ->
                    false;
                false ->
                    Good1#p_goods.current_num >= Good2#p_goods.current_num
            end
    end.

tidy_merge_goods(GoodsList,[]) ->
    GoodsList;
tidy_merge_goods(List,[Good|GoodsList]) ->
   [MergeGood|List2] = List,
    case check_can_merge(MergeGood,Good) of
        true ->
            Num1 = MergeGood#p_goods.current_num,
            Num2 = Good#p_goods.current_num,
            case Num1 + Num2 =< ?MAX_OVER_LAP of
                true ->
                    NewMergeGood =  MergeGood#p_goods{current_num = Num1 + Num2},
                    tidy_merge_goods([NewMergeGood|List2],GoodsList);
                false ->
                    NewMergeGood =  MergeGood#p_goods{current_num = ?MAX_OVER_LAP},
                    NewGood = Good#p_goods{current_num = Num1 + Num2 - ?MAX_OVER_LAP},
                    tidy_merge_goods([NewGood,NewMergeGood|List2],GoodsList)
            end;
        false ->
            tidy_merge_goods([Good|List],GoodsList)
    end.

%%@doc 减少物品的个数
%%参数RoleID角色id,[{Goods,Reduce_Num}|...]，Goods为要减少个数个的p_goods,Reduce_Num为需要减少的个数
%%返回{ok，NewGoodsList},返回减少了个数的新的p_goods，当个数为0时就删除这个物品并返回undefined
decrease_goods(RoleID,OperateGoodsList) ->
    {ok,
     [begin case Goods#p_goods.current_num-ReNum of
                R when R =< 0 ->
                    delete_goods(RoleID,Goods#p_goods.id),
                    undefined;
                R when R > 0 ->
                    NewGoods = Goods#p_goods{current_num = R},
                    update_goods(RoleID,NewGoods),
                    NewGoods
            end
      end || {Goods,ReNum} <- OperateGoodsList]
    }.

%% @doc 使用道具，包括通知客户端和记录日志（不是事务的哦）
%% @param RoleID 玩家ID
%% @param ItemTypeID 物品类型ID
%% @param Num 要扣除的物品的数量
%% @param LogType 用具记录日志
%% @return 失败返回：{error, num_not_enough}
%%         成功返回：ok
use_item(RoleID, ItemTypeID, Num, LogType) ->
    use_item(RoleID, [1,2,3], ItemTypeID, Num, LogType).

%% @doc 使用道具，包括通知客户端和记录日志（不是事务的哦）
%% @param RoleID 玩家ID
%% @param ItemTypeID 物品类型ID
%% @param BagIDList 背包的id列表
%% @param Num 要扣除的物品的数量
%% @param LogType 用具记录日志
%% @return 失败返回：{error, num_not_enough}
%%         成功返回：ok
use_item(RoleID, BagIDList, ItemTypeID, Num, LogType) ->
    case use_item_endtime(RoleID, BagIDList, ItemTypeID, 0, Num) of
        {error, num_not_enough} ->
            {error, num_not_enough};
        {ok, UpdateList, DeleteList} ->
            case UpdateList of
                [] -> ignore;
                _ ->
                    common_item_logger:log(RoleID, UpdateList, LogType),
                    common_misc:update_goods_notify({role, RoleID}, UpdateList)
            end,
            case DeleteList of
                [] -> ignore;
                _ ->
                    common_item_logger:log(RoleID, DeleteList, LogType),
                    common_misc:del_goods_notify({role, RoleID}, DeleteList)
            end,
            ok
    end.

use_item_endtime(RoleID, BagIDList, TypeID, EndTime, Num) ->
    case decrease_goods_by_typeid_endtime2(RoleID,BagIDList,TypeID,EndTime,Num,true) of
         {0,FinalDeleteList,FinalUpdateList} ->
             {ok,FinalUpdateList,FinalDeleteList};
         {RestNum,DeleteList,UpdateList} ->
             case decrease_goods_by_typeid_endtime2(RoleID,BagIDList,TypeID,EndTime,RestNum,false) of
                 {0,DeleteList2,UpdateList2} ->
                     {ok,lists:append(UpdateList,UpdateList2),lists:append(DeleteList,DeleteList2)};
                 _ ->
                     {error, num_not_enough}
             end
    end.


%%@doc 减少玩家指定背包中的一类型物品，默认只在背包、扩展背包中扣除
%%@param RoleID 玩家ID
%%@param ItemTypeID 物品的ID
%%@param ItemEndTime 物品的终止时间
%%@param Num 要扣除的物品的数量
decrease_goods_by_typeid(RoleID,ItemTypeID,Num) ->
    decrease_goods_by_typeid_endtime(RoleID,ItemTypeID,0,Num).

decrease_goods_by_typeid_endtime(RoleID,ItemTypeID,ItemEndTime,Num) ->
    decrease_goods_by_typeid_endtime(RoleID,[1,2,3],ItemTypeID,ItemEndTime,Num).

%%@doc 减少玩家指定背包中的一类型物品
%%参数：RoleID,BagIDList(玩家指定的一些背包的id，允许传不存在的背包),TypeID(物品的类型id),Num(数量)
%%返回   {ok,UpdateList,DeleteList}  
decrease_goods_by_typeid(RoleID,BagIDList,TypeID,Num) ->
    decrease_goods_by_typeid_endtime(RoleID,BagIDList,TypeID,0,Num).

decrease_goods_by_typeid_endtime(RoleID,BagIDList,TypeID,EndTime,Num) ->
    role_bag_info_backup(RoleID),
    case decrease_goods_by_typeid_endtime2(RoleID,BagIDList,TypeID,EndTime,Num,true) of
         {0,FinalDeleteList,FinalUpdateList} ->
             {ok,FinalUpdateList,FinalDeleteList};
         {RestNum,DeleteList,UpdateList} ->
             case decrease_goods_by_typeid_endtime2(RoleID,BagIDList,TypeID,EndTime,RestNum,false) of
                 {0,DeleteList2,UpdateList2} ->
                     {ok,lists:append(UpdateList,UpdateList2),lists:append(DeleteList,DeleteList2)};
                 _ ->
                     throw({bag_error,num_not_enough})
             end
    end.
%%@doc 减少玩家指定背包中的一类型物品
%%参数：RoleID,BagIDList(玩家指定的一些背包的id，允许传不存在的背包),TypeID(物品的类型id),Num(数量)
%%返回   {ok,UpdateList,DeleteList} 
decrease_goods_by_typeid(RoleID,BagIDList,TypeID,Num, Bind) ->
     role_bag_info_backup(RoleID),
      case decrease_goods_by_typeid_endtime2(RoleID,BagIDList,TypeID,0,Num,Bind) of
         {0,FinalDeleteList,FinalUpdateList} ->
              {ok,FinalUpdateList,FinalDeleteList};
          _ ->
               throw({bag_error,num_not_enough})
     end.

decrease_goods_by_typeid_endtime2(RoleID,BagIDList,TypeID,EndTime,Num,Bind) ->
    lists:foldl(
           fun(BagID,{RestNum,DeleteList,UpdateList}) ->
                   case RestNum of
                       0 ->
                           {RestNum,DeleteList,UpdateList};
                       _ ->
                           case decrease_goods_by_typeid_endtime3(RoleID,BagID,TypeID,EndTime,RestNum,Bind) of
                               {0,DeleteList2,UpdateList2} ->
                                   {0,lists:append(DeleteList, DeleteList2),lists:append(UpdateList, UpdateList2)};
                               {RestNum2,DeleteList2,UpdateList2} ->
                                   {RestNum2,lists:append(DeleteList, DeleteList2),lists:append(UpdateList, UpdateList2)}
                           end
                   end       
           end, {Num,[],[]}, BagIDList).

decrease_goods_by_typeid_endtime3(RoleID,BagID,TypeID,EndTime,Num,Bind) ->
    case get({?ROLE_BAG,RoleID,BagID}) of
        undefined ->
            {Num,[],[]};
        {_Content,_OutUseTime,_UsedPositionList,GoodsList,_Modified} ->
            lists:foldl(
              fun(GoodsInfo,{RestNum,DeleteList,UpdateList}) ->
                      case RestNum of
                          0 ->
                              {RestNum,DeleteList,UpdateList};
                          _ -> 
                              case (GoodsInfo#p_goods.typeid =:= TypeID) andalso (EndTime=:=GoodsInfo#p_goods.end_time orelse EndTime =:=0 )  of
                                  true ->
                                      case GoodsInfo#p_goods.bind of
                                          Bind ->
                                              decrease_goods_by_typeid4(RestNum,DeleteList,UpdateList,RoleID,BagID,GoodsInfo);
                                          _ ->
                                              {RestNum,DeleteList,UpdateList}
                                      end;
                                  _ ->
                                      {RestNum,DeleteList,UpdateList}
                              end
                      end      
              end, {Num,[],[]}, GoodsList)
    end.
           

decrease_goods_by_typeid4(Num,DeleteList,UpdateList,RoleID,BagID,GoodsInfo) ->
    CurNum = GoodsInfo#p_goods.current_num,
    case CurNum =< Num of
        true ->
            delete_exist_goods(GoodsInfo,RoleID,BagID),
            {Num-CurNum,[GoodsInfo#p_goods{current_num=0}|DeleteList],UpdateList};
        false ->
            {Content,OutUseTime,UsedPositionList,GoodsList,_Modified} = get({?ROLE_BAG,RoleID,BagID}),
            NewGoodsList = lists:keyreplace(GoodsInfo#p_goods.id,#p_goods.id,GoodsList,GoodsInfo#p_goods{current_num=CurNum-Num}),
            put({?ROLE_BAG,RoleID,BagID},{Content,OutUseTime,UsedPositionList,NewGoodsList,true}),
            {0,DeleteList,[GoodsInfo#p_goods{current_num=CurNum-Num}|UpdateList]}
    end.    

              
   

%%doc 获取一个新的物品id
get_new_goodsid(RoleID) ->
    case get({?role_bag_max_goodsid,RoleID}) of
        ?UNDEFINED ->
            throw({bag_error,must_create_goods_in_map});
        MaxID ->
            put({?role_bag_max_goodsid,RoleID},MaxID+1),
            MaxID+1
    end.

%%doc 获取玩家仓库信息
get_role_depot_info(RoleID) ->
    case get({?ROLE_DEPOSITORY_LIST,RoleID}) of
        undefined ->
            {error,no_role_bag_info};
        IDList ->
            AllGoodsList = lists:foldr(
                             fun({BagID,_Detail},Acc) ->
                                     {_Content,_OutUseTime,_UsedPositionList,GoodsList,_} = 
                                         get({?ROLE_BAG,RoleID,BagID}),
                                     [{?ROLE_BAG,BagID,GoodsList}|Acc]
                             end,[],IDList),
            {ok,{?ROLE_DEPOSITORY_LIST,IDList},AllGoodsList}
    end.

%%doc 获取玩玩家背包的信息
get_bag_info_by_id(RoleID,BagID) ->
     case get({?ROLE_BAG_LIST,RoleID}) of
        undefined ->
            {error,no_role_bag_info};
        IDList ->
             case lists:keyfind(BagID,1,IDList) of
                 false ->
                     {error,no_role_bag_info};
                 {BagID,Detail} ->
                     Detail
             end
     end.

%%doc 生成新物品的时候自动合并
atmoic_merge(RoleID,GoodsInfoList) when is_list(GoodsInfoList) ->
    lists:foldl(
      fun(GoodsInfo,{NewGoodsInfoList,OldGoodsInfoList}) ->
              case atmoic_merge(RoleID,GoodsInfo) of
                  {ok,NewGoodsInfo} ->
                      {[NewGoodsInfo|NewGoodsInfoList],lists:delete(GoodsInfo,OldGoodsInfoList)};
                  {error,_} ->
                      {NewGoodsInfoList,OldGoodsInfoList}
              end
      end,{[],GoodsInfoList},GoodsInfoList);
%%doc 生成新物品的时候自动合并
atmoic_merge(RoleID,GoodsInfo) ->
    case check_can_merge(GoodsInfo) of
        true ->
           case check_inbag_by_typeid(RoleID,GoodsInfo#p_goods.typeid) of
               false ->
                   {error,can_not_merge};
               {ok,GoodsList} ->
                   Num = GoodsInfo#p_goods.current_num,
                   %%处理物品数量异常的判断
                   case Num > ?MAX_OVER_LAP orelse Num < 1 of
                       true ->
                           throw({bag_error,goods_not_found});
                       false ->
                           ignore
                   end,
                   lists:foldl(
                     fun(GoodsInfo2,Acc) ->
                             case Acc of
                                 {error,_} ->
                                     Num2 = GoodsInfo2#p_goods.current_num,
                                     case GoodsInfo2#p_goods.bagid < 5
                                         andalso Num2 + Num =< ?MAX_OVER_LAP 
                                         andalso check_can_merge(GoodsInfo,GoodsInfo2) of
                                         true ->
                                             NewGoodsInfo = GoodsInfo2#p_goods{current_num=Num2+Num},
                                             GoodsID = GoodsInfo2#p_goods.id,
                                             BagID =  GoodsInfo2#p_goods.bagid,
                                             {Content,OutUseTime,UsedPositionList,GoodsList2,_} = get({?ROLE_BAG,RoleID,BagID}),
                                             NewGoodsList = lists:keyreplace(GoodsID,#p_goods.id,GoodsList2,NewGoodsInfo),
                                             put({?ROLE_BAG,RoleID,BagID}, {Content,OutUseTime,UsedPositionList,NewGoodsList,true}),
                                             {ok,NewGoodsInfo};
                                         false ->
                                             Acc
                                     end;
                                 {ok,_} ->
                                     Acc
                             end
                     end, {error,can_not_merge},GoodsList)
           end;                          
        false ->
            {error,can_not_merge}
    end.


%% BagID1是源背包  BagID2是目标背包
%% 为真的条件：目标背包未超时 且（源背包未超时 或 目标背包位置没有物品）
check_bags_times_up(BagID1,BagID2,RoleID,Position2)->
    %%源背包是否超时    
    Check1 =lists:all(fun(BagID)-> BagID=/=BagID1 end, ?TIMESUP_BAG_ID_LIST) orelse if_bag_times_up(RoleID,BagID1),
    %%目标背包是否超时
    Check2 =lists:all(fun(BagID)-> BagID=/=BagID2 end, ?TIMESUP_BAG_ID_LIST) orelse if_bag_times_up(RoleID,BagID2),
    %%if_dest_pos_empty:目标背包位置是否有物品
    Check2 andalso (Check1 orelse if_dest_pos_empty(BagID2, Position2, RoleID)).

if_bag_times_up(RoleID,BagID)->
    ?DEBUG("check bag times up:~w~n",[BagID]),
    {BagID,_BagTypeID,OutUseTime,_Rows,_Clowns}=get_bag_info_by_id(RoleID,BagID),
    ?DEBUG("OutUseTime:~w~n",[OutUseTime]),
    OutUseTime=:=0 orelse OutUseTime>common_tool:now().

if_dest_pos_empty(BagID, Position, RoleID)->
    ?DEBUG("check pos empty:~w~n",[BagID]),
    case get_goods_by_position(BagID, Position, RoleID) of
                      false->true;
                      _->false
                  end.

%% 从玩家背包，仓库中删除物品
delete_goods_from_bag_depositroy_by_typeid(RoleID, TypeID) when is_integer(RoleID),is_integer(TypeID) ->
    role_bag_info_backup(RoleID),
    DelDepotBagIDList = 
        case get({?ROLE_BAG_LIST,RoleID}) of
            undefined ->
                ?DEPOT_BAG_ID_LIST;
            BagList ->
                BagIDList = lists:map(fun({BagID, _})-> BagID end, BagList),
                lists:append(BagIDList, ?DEPOT_BAG_ID_LIST)
        end,
    DelGoodsList = 
        lists:foldl(
          fun(BagID,Acc) ->
                  case get({?ROLE_BAG,RoleID,BagID}) of
                      undefined ->
                          Acc;
                      {_Content,_OutUseTime,_UsedPositionList,GoodsList,_} ->
                          lists:foldr(
                            fun(GoodsInfo,Acc2) ->
                                    case GoodsInfo#p_goods.typeid =:= TypeID of
                                        true ->
                                            delete_exist_goods(GoodsInfo,RoleID,BagID),
                                            [GoodsInfo|Acc2];
                                        false ->
                                            Acc2
                                    end
                            end,Acc,GoodsList)
                  end
          end,[],DelDepotBagIDList),
    {ok,DelGoodsList}.

%% 使用扩展背包行重置进程字典数据
-define(MAIN_BAG_ID,1).
bag_extend_row(RoleID,MainBagBasicInfo,MainGridNumber) ->
	role_bag_info_backup(RoleID),
	case get({?ROLE_BAG_LIST,RoleID}) of
		undefined ->
			?THROW_SYS_ERR();
		RoleBagList ->
			RoleBagList2 = lists:keydelete(?MAIN_BAG_ID,1,RoleBagList),
			RoleBagList3 = [{?MAIN_BAG_ID,MainBagBasicInfo}|RoleBagList2],
			put({?ROLE_BAG_LIST,RoleID},lists:sort(fun(E1,E2)-> common_bag2:baglist_cmp(E1,E2) end,RoleBagList3)),
			{_OldGridNumber,OldOutUseTime,MainUsedPositionList,MainGoodsList,MainModified} = get({?ROLE_BAG,RoleID,?MAIN_BAG_ID}),
			put({?ROLE_BAG,RoleID,?MAIN_BAG_ID},{MainGridNumber,OldOutUseTime,MainUsedPositionList,MainGoodsList,MainModified})
	end.
