-module(hook_register_ok).
-include("mgeel.hrl").
-export([hook/1]).


-define(ITEM_TYPE_ID_JIANGHU_BAODIAN,12100001). %%江湖宝典


hook(NewRoleList) ->
    [RoleInfo|_] = NewRoleList,
    gift_hook(RoleInfo),
    ok.  

gift_hook(RoleInfo) ->
    %%?ERROR_MSG("RoleInfo=~w",[RoleInfo]),
    add_gift_for_role(RoleInfo#p_role.base).
    
add_gift_for_role(RoleBase) ->
    BagID = 1,
    #p_role_base{role_id=RoleID}=RoleBase,
    case common_config_dyn:find(etc,is_gift_jianghu_baodian) of
        [true] ->
            %%江湖宝典
            ItemBaodian1 = get_create_item_info(RoleID,?ITEM_TYPE_ID_JIANGHU_BAODIAN,1),
            {ok,GoodsListBaodian1} = common_bag2:create_item(ItemBaodian1),
            GoodsList = lists:concat([GoodsListBaodian1]),
            add_gift_goods(RoleID,BagID,GoodsList);
        _ ->
            ok
    end,
    case common_config_dyn:find(etc,is_beta_server) of
        [true] -> %% 封测服
            case common_config_dyn:find(etc, {create_role,item_id}) of
                [BetaItemId] ->
                    BetaItemInfo = get_create_item_info(RoleID,BetaItemId,2),
                    {ok,GoodsListBeta} = common_bag2:create_item(BetaItemInfo),
                    add_gift_goods(RoleID,BagID,GoodsListBeta);
                _ ->
                    next
            end;
        _ ->
            ok
    end,
    ok.

get_create_item_info(RoleID,TypeID,BagPosition)->
    #r_item_create_info{role_id=RoleID,bag_id=1,bagposition=BagPosition,
                        num=1,typeid=TypeID,bind=true,color=1,start_time=0,end_time=0}.

%%@doc 新增新手礼品
add_gift_goods(RoleID,BagID,GoodsList) when is_list(GoodsList)->
    NewGoodsList = init_goods_list(GoodsList,[]),                                            
    RoleBagKey = {RoleID,BagID},
    Record = #r_role_bag{role_bag_key=RoleBagKey,bag_goods=NewGoodsList},
    
    case db:transaction( fun() -> 
                                 db:write(?DB_ROLE_BAG_P, Record,write)
                         end) of
        {aborted, Error} ->    
            ?ERROR_MSG("赠送新手礼包出错!,Error=~w,stacktrace=~w",[Error,erlang:get_stacktrace()]),
            {error,Error};
        {atomic, ok} ->
            lists:foreach(fun(Goods)->
                                  common_item_logger:log_with_level(RoleID,0,Goods,?LOG_ITEM_TYPE_GET_SYSTEM)
                          end, GoodsList),
            ok
    end.

%%@doc 为新手的物品初始化goodID
init_goods_list([],Result)->
    Result;
init_goods_list([GoodsRec|TGoodsList],Result)->
    DefGoodsID = length(Result)+1,
    R = init_goods_id( GoodsRec,DefGoodsID ),
    init_goods_list(TGoodsList,[R|Result]).
    
init_goods_id( #p_goods{id=GoodsID} = GoodsRec,DefGoodsID )->
    case GoodsID of
        undefined->
            GoodsRec#p_goods{id=DefGoodsID };
        _ ->
            GoodsRec
    end.



