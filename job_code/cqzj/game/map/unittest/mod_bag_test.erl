%%%-------------------------------------------------------------------
%%% @author liuwei <liuwei@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     背包操作的内部接口的测试 
%%% @end
%%% Created : 2010-12-1
%%%-------------------------------------------------------------------
-module(mod_bag_test).


-include("mgeem.hrl").
-define(ROLE_BAG_TRANSACTION,role_bag_transaction).
-define(MAP_BAG_PERSISTENT_INTEEVAL,30).

-include_lib("eunit/include/eunit.hrl").
-define(TPRINT(Format, Args),
        io:format(lists:concat(["\t",?MODULE,":",?LINE," ",Format]), Args)).

-compile(export_all).

test_suite()->
    ok = test_clear_role_bag_info(1),
    ok = test_check_inbag(1,1),
    ok = test_check_inbag(1,1,1),
    ok = test_check_inbag_by_typeid(1,1),
    ok = test_create_goods(1),
    ok = test_create_goods_by_p_goods(1,1),
    ok = test_create_goods_by_p_goods(1,1,1),
    ok = test_delete_goods(1,1),
    
    ok = test_delete_goods_by_typeid(1,1),
    ok = test_update_goods(1),
    ok = test_swap_goods(1,1,1,1),
    ok = test_divide_goods(1,1,2,1,1),
    ok = test_get_goods_by_id(1,1),
    ok = test_create_bag(1,{3,0,0,6,7}),
    ok = test_delete_bag(1,1),
    ok = test_tidy_bag(1,1),
    ok = test_init_role_bag_info(),
    ok = test_max_goods_id(),
    ok.

get_test_role_name()->
    RoleName = lists:concat(["test_",common_tool:now()]),
    RoleName.

test_get_bag_goods_list()->
    {RoleID,_RoleName} = test_init_role(),
    ok = mod_bag:init_role_bag_info(RoleID),
    
    {ok,GoodsList} = mod_bag:get_bag_goods_list(RoleID),
    ?assert( length(GoodsList) >0 ).

test_init_role()->
    erase(),
    RoleName = get_test_role_name(),
    BinRoleName = common_tool:to_binary(RoleName),
    Res = gen_server:call({global,mgeel_account_server}, {add, BinRoleName,BinRoleName, 1, 1, 
                                                          1, 1, 1}),
    #m_role_add_toc{succ=true,result=[Role]} =Res,
    #p_role{base=#p_role_base{role_id=RoleID}} = Role,
    ?TPRINT("RoleID=~w,RoleName=~s~n",[RoleID,RoleName]),
    {RoleID,RoleName}.

test_rollback()->
    {RoleID,_RoleName} = test_init_role(),
    ok = mod_bag:init_role_bag_info(RoleID),
    
    {_,_,_,GoodsList,_} = get({role_bag,RoleID,1}),
    ?assert( length(GoodsList) ==1 ),
    [#p_goods{id=GoodsID}] = GoodsList,
    ?assert( GoodsID ==1 ),
    
    CreateInfo1 = #r_goods_create_info{bind=true, bag_id=1, position=1, type=?TYPE_ITEM, type_id=10200001, start_time=common_tool:now(), end_time=0,
                                      num=1, color=1 },
    CreateInfo2 = #r_goods_create_info{bind=true, bag_id=1, position=1, type=9999999, type_id=10200002, start_time=common_tool:now(), end_time=0,
                                      num=1, color=1 },
    
    TransResult = db:transaction( 
                    fun() ->
                            mod_bag:create_goods(RoleID,[CreateInfo1]),
                            mod_bag:create_goods(RoleID,[CreateInfo2])
                    end),
    {aborted,_Reason} = TransResult,
    
    {_,_,_,GoodsList2,_} = get({role_bag,RoleID,1}),
    ?assert( length(GoodsList2) ==1 ),
    [#p_goods{id=GoodsID2}] = GoodsList2,
    ?assert( GoodsID2 ==1 ).

%%@doc 测试初始化玩家背包
test_init_role_bag_info()->
    {RoleID,_RoleName} = test_init_role(),
    
    %%初始化背包
    ok = mod_bag:init_role_bag_info(RoleID).

test_get_empty_bag_pos()->
    {RoleID,_RoleName} = test_init_role(),
    ok = mod_bag:init_role_bag_info(RoleID),
    PosCount = 41,
    {ok,PosCount,_List} = mod_bag:get_empty_bag_pos(RoleID,PosCount),
    ?TPRINT("get_empty_bag_pos for PosCount=~w ok~n",[PosCount]),
    
    PosUseList1 = lists:seq(1, 42),
    PosUseList2 = lists:delete(5, lists:delete(3, PosUseList1)),
    PosUseList3 = lists:delete(7, PosUseList2),
    
    CreateInfoList = 
        [ 
         #r_goods_create_info{bind=true, bag_id=1, position=PosUse, type=?TYPE_ITEM, type_id=10200002, start_time=common_tool:now(), end_time=0,
                              num=1, color=1 }
                             || PosUse<-PosUseList3 ], 
    ?TPRINT("length of CreateInfoList =~w~n",[length(CreateInfoList)]),
    TransResult = db:transaction( 
                    fun() ->
                            [ mod_bag:create_goods(RoleID,[CreateInfo])|| CreateInfo<-CreateInfoList]
                    end),
    {atomic, _} = TransResult, 
    ?TPRINT("TransResult is atomic ~n",[]),
    {ok,2,[{1,42},{1,41}]} = mod_bag:get_empty_bag_pos(RoleID,2),
    
    {Content,OutUseTime,UsedPositionList,GoodsList,Tag} = get({role_bag,RoleID,1}),
    
    UsedPositionList2 = lists:delete(25, lists:delete(23, UsedPositionList)),
    UsedPositionList3 = lists:append(UsedPositionList2, [41,42]),
    put({role_bag,RoleID,1},{Content,OutUseTime,UsedPositionList3,GoodsList,Tag}),
    {ok,2,[{1,25},{1,23}]} = mod_bag:get_empty_bag_pos(RoleID,2),
    ok.

test_max_goods_id()->
    %%1)set up context
    RoleID = common_tool:now(),
    BagID = 1,
    {atomic,ok} = db:transaction(fun()-> 
                                         common_bag2:t_new_role_bag(RoleID),
                                         common_bag2:t_new_role_bag_basic(RoleID),
                                         ok
                                 end),
    
    erase(),
    RecordBagBasic = #r_role_bag_basic{role_id=RoleID,bag_basic_list=[{1,0,0,6,7,42},{5,0,0,3,3,9},{6,0,0,6,7,42}] },
    db:dirty_write(?DB_ROLE_BAG_BASIC_P,RecordBagBasic),
    RecordBag = {r_role_bag,{RoleID,BagID},
                 [{p_goods,1,1,1,2,20,1,1,1,10200001,true,0,0,1,0,
                   <<229,190,174,229,158,139,233,135,145,229,136,155,232,141,
                     175>>,
                   undefined,undefined,undefined,undefined,undefined,0,
                   undefined,0,undefined,undefined,undefined,undefined,0,0,
                   undefined,undefined,0,0,undefined,undefined,undefined,0},
                  {p_goods,2,1,1,3,20,1,1,1,10200005,true,0,0,1,0,
                   <<229,190,174,229,158,139,229,134,133,229,138,155,232,141,
                     175,230,176,180>>,
                   undefined,undefined,undefined,undefined,undefined,0,
                   undefined,0,undefined,undefined,undefined,undefined,0,0,
                   undefined,undefined,0,0,undefined,undefined,undefined,0}]},
    db:dirty_write(?DB_ROLE_BAG_P,RecordBag),
    
    %%2)call
    mod_bag:init_role_bag_info(RoleID),
    
    MaxID = get({role_bag_max_goodsid,RoleID}),
    ?TPRINT("MaxID=~w~n",[MaxID]),
    
    %%3)assert
    ?assert( MaxID==2 ).


test_clear_role_bag_info(RoleID)->
    mod_bag:clear_role_bag_info(RoleID),
    ok.

test_check_inbag(RoleID,GoodsID,BagID) ->
    erase(),
    mod_bag:init_role_bag_info(RoleID),
    put({role_bag,RoleID,BagID}, {42,0,[1],[#p_goods{id=GoodsID}],false}),
    case mod_bag:check_inbag(RoleID,GoodsID,BagID) of
        false ->
            {error,test_check_inbag_3_failed};
        {ok,_GoodsInfo} ->
            ok
    end.


test_check_inbag(RoleID,GoodsID) ->
    erase(),
    mod_bag:init_role_bag_info(RoleID),
    put({role_bag_list,RoleID},[{1, {1,0,0,6,7,42}},{2,{2,0,0,6,7,42}}]),
    put({role_bag,RoleID,2}, {42,0,[1],[#p_goods{id=GoodsID}],false}),
    case mod_bag:check_inbag(RoleID,GoodsID) of
        false ->
            {error,test_check_inbag_2_failed};
        {ok,_GoodsInfo} ->
            ok
    end.


test_check_inbag_by_typeid(RoleID,TypeID) ->
    erase(),
    mod_bag:init_role_bag_info(RoleID),
    put({role_bag_list,RoleID},[{1, {1,0,0,6,7,42}},{2,{2,0,0,6,7,42}}]),
    put({role_bag,RoleID,1}, {42,0,[1],[#p_goods{id=1111,typeid=TypeID}],false}),
    case mod_bag:check_inbag_by_typeid(RoleID,TypeID) of
        false ->
            {error,test_check_inbag_by_typeid_2_failed};
        {ok,_GoodsInfo} ->
            ok
    end.


test_swap_goods(GoodsID1, Position2, BagID2, RoleID) ->
    erase(),
    mod_bag:init_role_bag_info(RoleID),
    put({role_bag_list,RoleID},[{1, {1,0,0,6,7,42}},{2,{2,0,0,6,7,42}}]),
    put({role_bag,RoleID,BagID2}, {42,0,[1,Position2],[#p_goods{id=GoodsID1,current_num = 5,type=?TYPE_ITEM,typeid=10200001,bagid=BagID2,bagposition=1},#p_goods{id=1111,typeid=11110002,bagid=BagID2,bagposition=Position2}],false}),
    
    TransResult = db:transaction( 
                    fun() ->
                            mod_bag:swap_goods(GoodsID1, Position2, BagID2, RoleID)
                    end),
    {atomic, _} = TransResult, ok.


test_divide_goods(GoodsID1, DivideNum, Position2, BagID2, RoleID) ->
    erase(),
    mod_bag:init_role_bag_info(RoleID),
    put({role_bag_list,RoleID},[{1, {1,0,0,6,7,42}},{2,{2,0,0,6,7,42}}]),
    put({role_bag,RoleID,1}, {42,0,[1],[#p_goods{id=GoodsID1,type=?TYPE_ITEM, typeid=10200001,bagid=1,bagposition=1,current_num=50}],false}),
    
    TransResult = db:transaction( 
                    fun() ->
                            mod_bag:divide_goods(GoodsID1, DivideNum, Position2, BagID2, RoleID)
                    end),
    {atomic, _} = TransResult, ok.


test_create_bag(RoleID,{BagID,BagTypeID,OutUseTime,Rows,Clowns}) ->
    erase(),
    mod_bag:init_role_bag_info(RoleID),
    put({role_bag_list,RoleID},[{1, {1,0,0,6,7,42}},{2,{2,0,0,6,7,42}}]),
    
    TransResult = db:transaction( 
                    fun() ->
                            mod_bag:create_bag(RoleID,{BagID,BagTypeID,OutUseTime,Rows,Clowns})
                    end),
    {atomic, _} = TransResult, ok.




test_delete_bag(RoleID, _BagID) ->   
    erase(),
    mod_bag:init_role_bag_info(RoleID), 
    
    put({role_bag_list,RoleID},[{1, {1,0,0,7,7,48}},{2,{2,0,0,1,7,6}}]),
    put({role_bag,RoleID,1}, {42,0,[],[],false}),
    TransResult = db:transaction( 
                    fun() ->
                            mod_bag:delete_bag(RoleID,1,6,7,42)
                    end),
    {atomic, _} = TransResult, ok.


test_tidy_bag(RoleID, BagID) ->
    erase(),
    mod_bag:init_role_bag_info(RoleID),
    put({role_bag_list,RoleID},[{BagID, {BagID,0,0,6,7,42}}]),
    put({role_bag,RoleID,BagID}, {42,0,[3,5],[#p_goods{id=1123,type=?TYPE_ITEM,current_num = 1,typeid=10200001,bagid=BagID,bagposition=3},#p_goods{id=1111,type=?TYPE_ITEM,current_num = 1,typeid=10200001,bagid=BagID,bagposition=5}],false}),
    
    TransResult = db:transaction( 
                    fun() ->
                            mod_bag:tidy_bag(RoleID,BagID)
                    end),
    {atomic, _} = TransResult, ok.


test_get_goods_by_id(RoleID,GoodsID) ->
    erase(),
    mod_bag:init_role_bag_info(RoleID),
    put({role_bag_list,RoleID},[{1, {1,0,0,6,7,42}}]),
    put({role_bag,RoleID,1}, {42,0,[3,5],[#p_goods{id=GoodsID,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=3},#p_goods{id=1111,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=5}],false}),
    
    TransResult = db:transaction( 
                    fun() ->
                            mod_bag:get_goods_by_id(RoleID,GoodsID)
                    end),
    {atomic, _} = TransResult, ok.


test_create_goods(RoleID) ->
    erase(),
    
    mod_bag:init_role_bag_info(RoleID),
    CreateInfo = #r_goods_create_info{bind=true, bag_id=1, position=1, type=?TYPE_ITEM, type_id=10200001, start_time=common_tool:now(), end_time=0,
                                      num=1, color=1 },
    
    put({role_bag_list,RoleID},[{1, {1,0,0,6,7,42}}]),
    put({role_bag,RoleID,1}, {42,0,[3,5],
                              [#p_goods{id=223,current_num = 1,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=3},
                               #p_goods{id=1111,current_num = 5,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=5}],
                              false}),
    
    TransResult = db:transaction( 
                    fun() ->
                            mod_bag:create_goods(RoleID,[CreateInfo])
                    end),
    {atomic, _} = TransResult, ok.




test_create_goods_by_p_goods(RoleID,BagID) ->
    erase(),
    mod_bag:init_role_bag_info(RoleID),
    put({role_bag_list,RoleID},[{1, {1,0,0,6,7,42}}]),
    put({role_bag,RoleID,1}, {42,0,[3,5],
                              [#p_goods{id=223,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=3},
                               #p_goods{id=1111,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=5}],
                              false}),
    
    GoodsInfo = #p_goods{id=223,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=3},
    TransResult = db:transaction( 
                    fun() ->
                            mod_bag:create_goods_by_p_goods(RoleID,BagID,GoodsInfo)
                    end),
    {atomic, _} = TransResult, ok.


test_create_goods_by_p_goods(RoleID,BagID,Pos) ->   
    erase(),
    mod_bag:init_role_bag_info(RoleID),
    put({role_bag_list,RoleID},[{1, {1,0,0,6,7,42}}]),
    put({role_bag,RoleID,1}, {42,0,[3,5],
                              [#p_goods{id=223,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=3},
                               #p_goods{id=1111,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=5}],
                              false}),
    
    GoodsInfo = #p_goods{id=223,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=3},
    
    TransResult = db:transaction( 
                    fun() ->
                            mod_bag:create_goods_by_p_goods(RoleID,BagID,Pos,GoodsInfo)
                    end),
    {atomic, _} = TransResult, ok.


test_delete_goods(RoleID,GoodsID) ->
    erase(),
    mod_bag:init_role_bag_info(RoleID),
    put({role_bag_list,RoleID},[{1, {1,0,0,6,7,42}}]),
    put({role_bag,RoleID,1}, {42,0,[3,5],[#p_goods{id=GoodsID,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=3},#p_goods{id=1111,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=5}],false}),
    
    TransResult = db:transaction( 
                    fun() ->
                            mod_bag:delete_goods(RoleID,GoodsID)
                    end),
    {atomic, _} = TransResult, ok.



test_update_goods(RoleID) ->
    erase(),
    mod_bag:init_role_bag_info(RoleID),
    put({role_bag_list,RoleID},[{1, {1,0,0,6,7,42}}]),
    put({role_bag,RoleID,1}, {42,0,[3,5],[#p_goods{id=11121,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=3},#p_goods{id=1111,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=5}],false}),
    NewGoodsInfo = #p_goods{id=11121,type=?TYPE_ITEM,typeid=10200001,bagid=1,bagposition=3,current_num=15},
    
    TransResult = db:transaction( 
                    fun() ->
                            mod_bag:update_goods(RoleID,NewGoodsInfo)
                    end),
    {atomic, _} = TransResult, ok.


test_delete_goods_by_typeid(RoleID,TypeID) ->
    erase(),
    mod_bag:init_role_bag_info(RoleID),
    put({role_bag_list,RoleID},[{1, {1,0,0,6,7,42}}]),
    put({role_bag,RoleID,1}, {42,0,[3,5],[#p_goods{id=11221,type=?TYPE_ITEM,typeid=TypeID,bagid=1,bagposition=3},#p_goods{id=1111,type=?TYPE_ITEM,typeid=TypeID,bagid=1,bagposition=5}],false}),
    
    TransResult = db:transaction( 
                    fun() ->
                            mod_bag:delete_goods_by_typeid(RoleID,TypeID)
                    end),
    {atomic, _} = TransResult, ok.

