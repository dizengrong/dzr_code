%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     背包/背包操作的外部接口
%%% @end
%%% Created : 2010-12-1
%%%-------------------------------------------------------------------
-module(common_bag2).


%% API
-export([
         get_bag_goods_list/2,
         create_item/1,
         creat_stone/1,
         creat_equip_without_expand/1,
         init_role_bag_info/2,
         baglist_cmp/2,
         is_depository_bag/1,
         hook_create_equip/1
        ]).
-export([
         t_persistent_role_bag_info/1,
         t_new_role_bag/1,
         t_new_role_bag_basic/1
         ]).
-export([ 
         check_money_enough/3,
         check_money_enough_and_throw/3,
         %% 使用钱的接口，包括记录日志、通知客户端和修改进程字典数据
         %% 2012-11-1 added by dizengrong
         use_money/4,
         add_money/4,
         t_reward_prop/2,t_reward_prop/3,
         t_deduct_money/4,
         t_deduct_money/6,
         t_gain_money/4
         ]).

-export([add_prestige/3, 
         t_gain_prestige/3,
         use_prestige/3,
         t_deduct_prestige/3,
         check_prestige_enough/2
         ]).

-export([add_yueli/3, 
         t_gain_yueli/3,
         t_deduct_yueli/3,
         check_yueli_enouth/2
         ]).

-export([
         on_transaction_begin/0,
         on_transaction_commit/0,
         on_transaction_rollback/0
        ]).

%% ====================================================================
%% Macro
%% ====================================================================
-define(ROLE_BAG_TRANSACTION,role_bag_transaction).
-define(ROLE_BAG_LIST_BK,role_bag_list_bk).
-define(ROLE_BAG_BK,role_bag_bk).
-define(ROLE_DEPOSITORY_LIST,role_depository_list).    %%角色仓库的字典Key
-define(ROLE_BAG_LIST,role_bag_list).    %%角色背包概况列表的字典Key
-define(MAX_ID(Id1,Id2),if Id1>Id2-> Id1;true-> Id2 end).
-define(role_bag_max_goodsid,role_bag_max_goodsid).

-define(UNDEFINED,undefined).

-define(CAN_OVERLAP,1).
-define(NOT_OVERLAP,2).

-define(THROW_ERR(ErrCode),throw({error,ErrCode,undefined})).
-define(THROW_ERR(ErrCode,ErrReason),throw({error,ErrCode,ErrReason})).
%%常见错误类型
-define(ERR_OK, 0). %%OK
-define(ERR_SYS_ERR, 1).    %%系统错误
-define(ERR_OTHER_ERR, 2).  %%其他错误，具体原因见Reason
-define(ERR_INTERFACE_ERR, 3).  %%接口错误

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").
-include("common_server.hrl").

%% ====================================================================
%% API Functions
%% ====================================================================

on_transaction_begin() ->
    case get(?ROLE_BAG_TRANSACTION) of
        ?UNDEFINED ->
            put(?ROLE_BAG_TRANSACTION,true);
        _ ->
            do_delete_bag_transaction_info(),
            ?ERROR_MSG("transaction error,reason=nesting_transaction,strace=~w",[erlang:get_stacktrace()]),
            throw(nesting_transaction)
    end.


on_transaction_commit() ->
    do_delete_bag_transaction_info().


on_transaction_rollback() ->
    erase(?ROLE_BAG_TRANSACTION),
    case get(bag_locked_role_idlist) of
        ?UNDEFINED ->
            ignore;
        RoleIDList ->
            erase(bag_locked_role_idlist),
            [ begin do_rollback_role_bag_info(RoleID),do_clear_bag_backup_info(RoleID) end
              ||RoleID<-RoleIDList ]
    end.


%%@doc 创建道具
%%@spec create_item(CreateInfo::#r_item_create_info()) -> {ok,GoodsList} | {error,typeid_not_found}
create_item(CreateInfo)when is_record(CreateInfo,r_item_create_info) ->
    #r_item_create_info{role_id=RoleID,bag_id=BagID,bagposition=BagPos,
                        num=Num,typeid=TypeID,bind=Bind,color=Color,
                        start_time=StartTime,end_time=EndTime,use_pos=UsePosList} = CreateInfo,
    case common_config_dyn:find_item(TypeID) of
        [] ->
            {error,typeid_not_found};
        [BaseInfo] ->
            #p_item_base_info{sell_type=SellType,
                              sell_price=SellPrice,
                              itemname=ItemName,
                              usenum=UseNum,
                              is_overlap=IsOverlap,
                              effects=Effects,
                              colour=InitColour}=BaseInfo,
            {NewStartTime,NewEndTime}=
                if StartTime =:= 0 andalso EndTime =/= 0 ->
                       {common_tool:now(),common_tool:now()+EndTime};
                   true ->
                       {StartTime,EndTime}
                end,    
            Endurance =
                if erlang:is_list(Effects) ->
                       Effect = 
                           case lists:keyfind(15,2,Effects) of
                               false ->
                                   lists:keyfind(17,2,Effects);
                               EffectTmp ->
                                   EffectTmp
                           end,
                       if Effect =:= false ->
                              0;
                          true ->
                              ConfigID = list_to_integer(Effect#p_item_effect.parameter),
                              [Config] = common_config_dyn:find(bighpmp,ConfigID),
                              Config#r_big_hp_mp.total
                       end;
                   true ->
                       0
                end,
            NewColour = case Color of 0 -> InitColour; Color -> Color end,
            case UsePosList =:= [] of
                true ->
                    case common_config_dyn:find(cang_bao_tu_fb,{drop_item_use_pos,TypeID}) of
                        [DropItemUsePosList] ->
                            OpenedDays = common_config:get_opened_days(),
                            NewUsePosList = 
                                lists:foldl(
                                  fun({MinOpenedDays,MaxOpenedDays,SubDropItemUsePosList},AccNewUsePosList) -> 
                                          case AccNewUsePosList =:= [] 
                                                   andalso OpenedDays >= MinOpenedDays 
                                                   andalso (MaxOpenedDays =:= 0 orelse MaxOpenedDays >= OpenedDays) of
                                              true ->
                                                  {DropItemUseMapId,DropItemUseTx,DropItemUseTy} = lists:nth(common_tool:random(1, erlang:length(SubDropItemUsePosList)), SubDropItemUsePosList),
                                                  [DropItemUseMapId,DropItemUseTx,DropItemUseTy];
                                              _ ->
                                                  AccNewUsePosList
                                          end
                                  end, [], DropItemUsePosList);
                        _ ->
                            NewUsePosList = []
                    end;
                _ ->
                    NewUsePosList = UsePosList
            end,
            GoodsTmp= #p_goods{type=?TYPE_ITEM, typeid = TypeID,roleid = RoleID , 
                               bagid = BagID, bagposition = BagPos ,bind = Bind , 
                               end_time = NewEndTime,current_colour =NewColour,sell_type = SellType, 
                               sell_price = SellPrice,start_time=NewStartTime,
                               name=ItemName, current_endurance=Endurance,endurance=Endurance,
                               use_pos=NewUsePosList},
            GoodsList = case IsOverlap =:= ?CAN_OVERLAP andalso UseNum =:= 1 of
                            true ->
                                case Num rem ?MAX_OVER_LAP of
                                    0 -> 
                                        lists:duplicate(Num div ?MAX_OVER_LAP,
                                                        GoodsTmp#p_goods{current_num=?MAX_OVER_LAP});
                                    R -> [GoodsTmp#p_goods{current_num=R}|
                                                              lists:duplicate(Num div ?MAX_OVER_LAP,
                                                                              GoodsTmp#p_goods{current_num=?MAX_OVER_LAP})]
                                end;
                            false ->
                                lists:duplicate(Num,GoodsTmp#p_goods{current_num=1})
                        end,
            {ok,GoodsList}
    end.

%%@doc 创建宝石
%%@spec create_stone/1 -> {ok,GoodsList} | {error,typeid_not_found}
creat_stone(CreatInfo)when erlang:is_record(CreatInfo,r_stone_create_info) ->
    #r_stone_create_info{role_id=RoleID,bag_id=BagID,bagposition=BagPos,
                         num=Num,typeid=TypeID,bind=Bind,start_time=StartTime,
                         end_time=EndTime}=CreatInfo,
    case common_config_dyn:find_stone(TypeID) of
        [] ->
            {error,typeid_not_found};
        [BaseInfo] ->
            {NewStartTime,NewEndTime}=
                if StartTime =:= 0 andalso EndTime =/= 0 ->
                        {common_tool:now(),common_tool:now()+EndTime};
                   true ->
                        {StartTime,EndTime}
                end, 
            #p_stone_base_info{sell_type=SellType,
                               sell_price=SellPrice,
                               stonename=StoneName,
                               colour=InitColour,
                               level=Level}=BaseInfo,
            GoodsTmp = #p_goods{type = ?TYPE_STONE ,typeid = TypeID,roleid = RoleID ,
                                bagposition = BagPos ,bind = Bind, current_colour =InitColour,level = Level,bagid = BagID,
                                start_time=NewStartTime,end_time=NewEndTime,
                                add_property = BaseInfo#p_stone_base_info.level_prop,
                                sell_type = SellType, sell_price = SellPrice,name=StoneName},
            GoodsList = 
                case Num rem ?MAX_OVER_LAP of
                    0 -> 
                        lists:duplicate(Num div ?MAX_OVER_LAP,
                                        GoodsTmp#p_goods{current_num=?MAX_OVER_LAP});
                    R ->
                        [GoodsTmp#p_goods{current_num=R}|
                         lists:duplicate(Num div ?MAX_OVER_LAP,GoodsTmp#p_goods{current_num=?MAX_OVER_LAP})]
                end,
            {ok,GoodsList}
    end.

%%@doc 创建装备 （没有进行装备扩展属性的设置）
%%@spec creat_equip_without_expand/1 -> {ok,GoodsList} | {error,typeid_not_found}
creat_equip_without_expand(CreateInfo) when is_record(CreateInfo,r_equip_create_info) ->
    #r_equip_create_info{role_id=RoleID,bag_id=BagID,bagposition=BagPos,num=Num,
                         typeid=TypeID,bind=Bind,start_time=StartTime,end_time=EndTime,
                         color=Color,quality=Quality,punch_num = PunchNum,sub_quality = SubQuality,
                         property=Pro,rate=Rate,result=Result,result_list=ResultList
                        }=CreateInfo,
    case common_config_dyn:find_equip(TypeID) of
        [BaseInfo] ->
            {NewStartTime,NewEndTime}=
                if StartTime =:= 0 andalso EndTime =/= 0 ->
                       {common_tool:now(),common_tool:now()+EndTime};
                   true ->
                       {StartTime,EndTime}
                end, 
			#p_equip_base_info{property=Prop,sell_type=SellType,sell_price=SellPrice, 
                               equipname=Name,endurance=Endurance}=BaseInfo,
            NewProp = if Pro =:= undefined -> Prop;true -> Pro end,
            NewResultList = if ResultList =:= undefined -> [];true -> ResultList end, 

            GoodsTmp = #p_goods{typeid = TypeID,roleid = RoleID ,bagposition = BagPos ,bind = Bind , 
                                add_property = NewProp,start_time = NewStartTime,end_time = NewEndTime, 
                                current_colour = Color,quality = Quality,current_endurance = Endurance ,
                                bagid = BagID, type = ?TYPE_EQUIP,sell_type = SellType,stones=[], 
                                sell_price = SellPrice,name = Name,loadposition = 0,punch_num = PunchNum, endurance = Endurance,
                                level = (BaseInfo#p_equip_base_info.requirement)#p_use_requirement.min_level,
                                reinforce_rate=Rate,reinforce_result=Result,reinforce_result_list=NewResultList,
                                equip_bind_attr = [],sub_quality = SubQuality,exp = 0, next_level_exp = 0,whole_attr = []},
            GoodsTmp2 = hook_create_equip(GoodsTmp),
            {ok, lists:duplicate(Num,GoodsTmp2#p_goods{current_num=1})};
        [] ->
            {error,typeid_not_found}
    end.

%% 判断装备是否是套装，创建装备时需要处理套装信息
%% 返回 #p_goods
hook_create_equip(#p_goods{type = ?TYPE_EQUIP, current_colour = Color}=EquipGoods) ->
    case common_config_dyn:find(equip_whole_attr, {equip_id,EquipGoods#p_goods.typeid,Color}) of
        [WholeId] ->
            case common_config_dyn:find(equip_whole_attr,{equip_whole_base_info,WholeId}) of
                [EquipWholeInfo] when erlang:is_record(EquipWholeInfo,r_equip_whole_info) ->
                    WholeAttrList = [#p_equip_whole_attr{id = WholeId,
                                                         attr_code = REquipWholeAttr#r_equip_whole_attr.attr_code,
                                                         value = REquipWholeAttr#r_equip_whole_attr.attr_value,
                                                         attr_index = REquipWholeAttr#r_equip_whole_attr.attr_index,
                                                         active_number = REquipWholeAttr#r_equip_whole_attr.active_number,
                                                         attr_type = REquipWholeAttr#r_equip_whole_attr.attr_type,
                                                         active = 0,
                                                         number = 0
                                                         }||REquipWholeAttr <- EquipWholeInfo#r_equip_whole_info.add_attr_list],
                    EquipGoods#p_goods{whole_attr = WholeAttrList};
                _ ->
                    EquipGoods
            end;
        _ ->
            EquipGoods
    end;

hook_create_equip(EquipGoods) ->
    EquipGoods.

%%@doc 事务内持久化背包数据
t_persistent_role_bag_info(RoleBagInfoList) when is_list(RoleBagInfoList)->
    [ persistent_bag_info(BagInfo) ||BagInfo<-RoleBagInfoList ].
persistent_bag_info(BagInfo) when is_record(BagInfo,r_role_bag)->
    db:write(?DB_ROLE_BAG_P,BagInfo,write);
persistent_bag_info({{?role_bag_max_goodsid,_},_BagMaxId}) ->
    ignore;
persistent_bag_info(_) ->
    ignore.


%%@doc 事务内初始化Role的 DB_ROLE_BAG表
t_new_role_bag(RoleID) ->
    InitBagIdList = ?INIT_BAG_ID_LIST,
    [ do_t_new_role_bag(RoleID,BagID)||BagID<- InitBagIdList].

%%@doc 事务内初始化Role的DB_ROLE_BAG_BASIC表
t_new_role_bag_basic(RoleID)->
    %%  [{bag_id,bag_type_id,due_time,rows,columns,grid_number}]
    BasicList = ?BAG_DEF_LIST, 
    Record = #r_role_bag_basic{role_id=RoleID,bag_basic_list=BasicList},
    db:write(?DB_ROLE_BAG_BASIC_P, Record, write).

%%@doc 异步方式，获取玩家的全部背包信息
%%@param RoleID::integer()  角色ID
%%@return   
get_bag_goods_list(RoleID,ReplyMsgTag)-> 
    async_call_map_process(RoleID,{get_bag_goods_list,[RoleID],ReplyMsgTag}).


%%
%% Local Functions
%%

do_t_new_role_bag(RoleID,BagID)->
    Record = #r_role_bag{
                         role_bag_key = {RoleID,BagID},
                         bag_goods = [] },
    db:write(?DB_ROLE_BAG_P, Record, write).

%%@doc 异步方式地调用Map进程，并返回指定的CallbackInfo消息类型
%%  TIP:调用者和接收者必须是同一个gen_server
async_call_map_process(RoleID,{Func,Args,ReplyMsgTag})->
    ReceiverPID = self(),
    mgeer_role:send(RoleID, {mod_bag_handler,{ReceiverPID,Func,Args,ReplyMsgTag}}).



%%@doc 背包操作失败的时候直接回滚回备份的背包数据
do_rollback_role_bag_info(RoleID) ->
    case  get({?ROLE_BAG_LIST_BK,RoleID}) of
        ?UNDEFINED ->
            ignore;
        BakList ->
            put({role_bag_list,RoleID},BakList),
            lists:foreach(
              fun({BagID,_BagBasic}) ->
                      BakRoleBag = get({?ROLE_BAG_BK,RoleID,BagID}),
                      put({role_bag,RoleID,BagID},BakRoleBag)
              end,BakList)
    end.


do_delete_bag_transaction_info() ->
    erase(?ROLE_BAG_TRANSACTION),
    case get(bag_locked_role_idlist) of
        ?UNDEFINED ->
            ignore;
        RoleIDList ->
            erase(bag_locked_role_idlist),
            [ do_clear_bag_backup_info(RoleID) || RoleID<-RoleIDList ]
    end.


do_clear_bag_backup_info(RoleID) ->
    case  get({?ROLE_BAG_LIST_BK,RoleID}) of
        ?UNDEFINED ->
            ignore;
        BakList ->
            erase({?ROLE_BAG_LIST_BK,RoleID}),
            lists:foreach(
              fun({BagID,_BagBasic}) -> erase({?ROLE_BAG_BK,RoleID,BagID}) 
              end, BakList)
    end.



baglist_cmp({BagID1,_},{BagID2,_}) ->
    BagID1 < BagID2.

-define(IS_DEPOT_BAG(BagID),BagID>5).

%%@doc 判断背包ID是否为仓库的背包
is_depository_bag(BagID)->
    ?IS_DEPOT_BAG(BagID).


%%@doc  初始化玩家背包信息,第一次进入地图时使用
%%@param RoleID::integer()  角色ID
%%@return   
init_role_bag_info(RoleID,RoleAttr) when is_integer(RoleID) ->
    Fun = fun()->
                  case db:read(?DB_ROLE_BAG_BASIC_P,RoleID,write) of
                      [] ->
                          throw({bag_error,no_bag_basic_data});
                      [ #r_role_bag_basic{bag_basic_list=BagBasicList} ]->
                          %%去掉扩展背包
                          NormalBagBasicList = lists:filter(fun(E)-> element(1,E)<2 orelse element(1,E)>4 end, BagBasicList),
                          
                          {BagList,DepositList} = lists:foldl(
                                                    fun(BagBasic,{Acc1,Acc2})-> 
                                                            BagID = element(1,BagBasic),
                                                            if
                                                                ?IS_DEPOT_BAG(BagID)->          %%仓库
                                                                    {Acc1,[{BagID,BagBasic}|Acc2]};
                                                                true->                          %%主背包、法宝空间
                                                                    {[{BagID,BagBasic}|Acc1],Acc2}
                                                            end     
                                                    end, {[], []}, NormalBagBasicList),
                          
                          BagInfoList = [{{?ROLE_BAG_LIST,RoleID},lists:sort(fun(E1,E2) -> baglist_cmp(E1,E2) end,BagList)}],
                          BagInfoList2 = [{{?ROLE_DEPOSITORY_LIST,RoleID},lists:sort(fun(E1,E2) -> baglist_cmp(E1,E2) end,DepositList)}|BagInfoList],
                          {BagInfoList3,GoodsIDList,MaxID2} = 
                              lists:foldl(
                                fun( E,{AccBagList,AccIDList,AccMaxID}) ->
                                        {BagID,_BagTypeID,OutUseTime,_Rows,_Clowns,GridNumber} = E,
                                        case db:read(?DB_ROLE_BAG_P,{RoleID,BagID},write) of
                                            [] ->
                                                throw({bag_error,no_bagid_data});
                                            [BagInfo] ->
                                                Content = GridNumber,   %%Content = Rows * Clowns,
                                                GoodsList = BagInfo#r_role_bag.bag_goods,
                                                {UsedPositionList,AccIDList2} = get_used_position_list(GoodsList,AccIDList),
                                                MaxID = get_bag_max_goodsid(GoodsList,0),
                                                AccMaxID2 = ?MAX_ID(MaxID,AccMaxID),
                                                AccBagList2 = [{{?ROLE_BAG,RoleID,BagID},{Content,OutUseTime,UsedPositionList,GoodsList,false}}|AccBagList],
                                                {AccBagList2,AccIDList2,AccMaxID2}
                                        end
                                end,{BagInfoList2,[],0},NormalBagBasicList),
                          
                          MaxID3 = update_bag_max_goodsid_by_equips_and_stall(RoleID,GoodsIDList,MaxID2,RoleAttr),
                          {BagBasicList,[{{?role_bag_max_goodsid,RoleID},MaxID3}|BagInfoList3]}
                  end
          end,
    case db:transaction(Fun) of
        {atomic,Info} ->
            {ok,Info};
        {aborted,Reason} ->
            ?ERROR_MSG("init role bag data error when first enter,roleid=~w,reason=~w",[RoleID,Reason]),
            {error,Reason}
    end.

get_used_position_list(GoodsList,IDList) ->
    {PosList,NewIDList} = 
        lists:foldl(
          fun(GoodsInfo,{Acc,Acc2}) ->
                  Pos = GoodsInfo#p_goods.bagposition,
                  ID = GoodsInfo#p_goods.id,
                  case lists:member(ID,Acc2) of
                      true ->
                          db:abort(bag_data_error);
                      false ->
                          {[Pos|Acc],[ID|Acc2]}
                  end
          end,{[],IDList},GoodsList),
    {lists:sort(PosList),NewIDList}.

get_bag_max_goodsid([],MaxId) ->
    MaxId;
get_bag_max_goodsid([#p_goods{id=Id}|T],MaxId) ->
    MaxId2 = ?MAX_ID(Id,MaxId),
    get_bag_max_goodsid(T,MaxId2).

get_max_and_id_list(_RoleID,MaxId,IdList,undefined,_Type)->
    {MaxId,IdList};
get_max_and_id_list(_RoleID,MaxId,IdList,[],_Type)->
    {MaxId,IdList};
get_max_and_id_list(RoleID,MaxId,IdList,[#p_goods{id=Id}=Goods|T],Type)->
    case lists:member(Id, IdList) of
        true->
            case Type of
                equips->
                    ?ERROR_MSG("玩家身上有物品数据异常,RoleID=~w,Goods=~w",[RoleID,Goods]),
                    db:abort(bag_data_error);
                stalls->
                    ?ERROR_MSG("玩家摆摊有物品数据异常,RoleID=~w,Goods=~w",[RoleID,Goods]),
                    db:abort(bag_data_error)
            end;
        _ ->
            ignore
    end,
    get_max_and_id_list_2(RoleID,Id,MaxId,IdList,T,Type).

get_max_and_id_list_2(RoleID,Id,MaxId,IdList,T,Type)->  
    MaxId2 = ?MAX_ID(Id,MaxId),
    get_max_and_id_list(RoleID,MaxId2,[Id|IdList],T,Type).

update_bag_max_goodsid_by_equips_and_stall(RoleID,IDList,MaxIDOld,RoleAttr)->
    #p_role_attr{equips=Equips} = RoleAttr,
    {MaxID2,IDList2} = get_max_and_id_list(RoleID,0,IDList,Equips,equips),
    Stalls = db:match_object(?DB_STALL_GOODS,#r_stall_goods{_='_', role_id=RoleID},read),
    StallGoodsList = [ Goods||#r_stall_goods{goods_detail=Goods}<-Stalls],
    {MaxID4,_} = get_max_and_id_list(RoleID,MaxID2,IDList2,StallGoodsList,stalls),
    ?MAX_ID(MaxIDOld,MaxID4).

t_reward_prop(RoleID,RewardPropList)->
    %%默认使用怪物掉落的接口类型
    t_reward_prop(RoleID,RewardPropList,monster_flop).

%%@doc 通用的奖励物品的接口
t_reward_prop(_RoleID,[],_InterfaceType)->
    ignore;
t_reward_prop(RoleID,RewardProp,InterfaceType) when is_record(RewardProp,p_reward_prop)->
    %%单个奖励
    #p_reward_prop{prop_id=PropID,prop_type=PropType,prop_num=PropNum,bind=IsBind} = RewardProp,
    {Color,Quality,SubQuality} = get_quality_by_reward_prop(RewardProp),
    
    CreateInfo = #r_goods_create_info{bind=IsBind,type=PropType, type_id=PropID, start_time=0, end_time=0, 
                                      num=PropNum, color=Color, quality=Quality, sub_quality=SubQuality,
                                      punch_num=0,interface_type=InterfaceType},
    mod_bag:create_goods(RoleID,CreateInfo);
t_reward_prop(RoleID,RewardPropList,InterfaceType) when is_list(RewardPropList)->
    %%多个奖励
    NewTotalGoodsList = 
        lists:foldl(
          fun(E,AccIn)-> 
                  {ok,NwGoodsList} = t_reward_prop(RoleID,E,InterfaceType),
                  lists:merge(AccIn, NwGoodsList)
          end, [], RewardPropList),
    {ok,NewTotalGoodsList}.

get_quality_by_reward_prop(RewardProp)->
    #p_reward_prop{prop_type=PropType,color=ColorArg} = RewardProp,
    if
        ColorArg =:= undefined ->
            Color = 0;
        true ->
            %%默认是0，这样就按照装备的配置中指定颜色来赠送
            Color = ColorArg
    end,
    
    case PropType of
        ?TYPE_EQUIP ->
            {Quality,SubQuality} = mod_refining_tool:get_equip_quality_by_color(Color);
        _ ->
            SubQuality = 1,
            Quality = ?QUALITY_GENERAL
    end,
    {Color,Quality,SubQuality}.


%% @doc 增加钱币、元宝的接口，包括记录消费日志、更新数据以及通知客户端
%% (实现内部包涵事务，调用者不能在事务内调用该方法)
%% @parm RoleID 玩家id
%% @parm MoneyType 消费的金钱类型：silver_unbind, silver_bind, gold_unbind, gold_bind
%% @parm GainMoney 增加金额
%% @parm ConsumeLogType 用于记录日志
%% @return {ok, RoleAttr}
add_money(RoleID, MoneyType, GainMoney, ConsumeLogType) ->
    Fun = fun() ->
        t_gain_money(MoneyType, GainMoney, RoleID, ConsumeLogType)
    end,
    {atomic, {ok, RoleAttr}} = common_transaction:t(Fun),
    case ((MoneyType == gold_unbind) orelse (MoneyType == gold_bind)) of
        true ->  common_misc:send_role_gold_change(RoleID, RoleAttr);
        false -> common_misc:send_role_silver_change(RoleID, RoleAttr)
    end,
    {ok, RoleAttr}.


%%@doc 通用的获取钱币、元宝的接口，包括记录消费日志
t_gain_money(MoneyType,GainMoney,RoleID,ConsumeLogType) when is_integer(RoleID) andalso GainMoney>=0->
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    case t_gain_money(MoneyType,GainMoney,RoleAttr,ConsumeLogType) of
        {ok,RoleAttr2} ->
            mod_map_role:set_role_attr(RoleID,RoleAttr2),
            {ok,RoleAttr2};
        {error,MoneyType}->
            {error,MoneyType}
    end;
t_gain_money(MoneyType,GainMoney,RoleAttr,ConsumeLogType) when is_record(RoleAttr,p_role_attr) andalso GainMoney>=0->
    #p_role_attr{role_id=RoleID,silver_bind=SilverBind,
                 gold=GoldUnBind,gold_bind=GoldBind} = RoleAttr,
    case MoneyType of
        %%!!! T6没有不绑定铜钱, 故改为铜钱
        % silver_unbind->
        %     common_consume_logger:gain_silver({RoleID, 0, GainMoney, ConsumeLogType,""}),
        %     NewUnBind = (SilverUnbind+GainMoney),
        %     {ok,RoleAttr#p_role_attr{silver=NewUnBind}};
        silver_unbind->
            common_consume_logger:gain_silver({RoleID, GainMoney, 0, ConsumeLogType,""}),
            NewBind = (SilverBind+GainMoney),
            {ok,RoleAttr#p_role_attr{silver_bind=NewBind}};
        silver_bind->
            common_consume_logger:gain_silver({RoleID, GainMoney, 0, ConsumeLogType,""}),
            NewBind = (SilverBind+GainMoney),
            {ok,RoleAttr#p_role_attr{silver_bind=NewBind}};
        gold_unbind->
            common_consume_logger:gain_gold({RoleID, 0, GainMoney, ConsumeLogType,""}),
            NewUnBind = (GoldUnBind+GainMoney),
            {ok,RoleAttr#p_role_attr{gold=erlang:trunc(NewUnBind)}};
        gold_bind->
            common_consume_logger:gain_gold({RoleID, GainMoney,0 , ConsumeLogType,""}),
            NewBind = (GoldBind+GainMoney),
            {ok,RoleAttr#p_role_attr{gold_bind=erlang:trunc(NewBind)}}
    end.

check_money_enough(MoneyType,DeductMoney,RoleID)when is_integer(RoleID)->
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    check_money_enough(MoneyType,DeductMoney,RoleAttr);
check_money_enough(silver_unbind,DeductMoney,RoleAttr)when is_record(RoleAttr,p_role_attr)->
    #p_role_attr{silver=SilverUnbind,silver_bind=SilverBind} = RoleAttr,
    (SilverUnbind+SilverBind)>=DeductMoney;
    %%T6, 没有不绑定铜钱!!!
    % #p_role_attr{silver=SilverUnbind} = RoleAttr,
    % SilverUnbind>=DeductMoney;
check_money_enough(silver_any,DeductMoney,RoleAttr)when is_record(RoleAttr,p_role_attr)->
    #p_role_attr{silver_bind=SilverBind} = RoleAttr,
    SilverBind>=DeductMoney;
check_money_enough(gold_unbind,DeductMoney,RoleAttr)when is_record(RoleAttr,p_role_attr)->
    #p_role_attr{gold=GoldUnbind} = RoleAttr,
    GoldUnbind>=DeductMoney;
check_money_enough(gold_any,DeductMoney,RoleAttr)when is_record(RoleAttr,p_role_attr)->
    #p_role_attr{gold_bind=GoldBind} = RoleAttr,
    GoldBind>=DeductMoney;

    % #p_role_attr{gold=GoldUnbind,gold_bind=GoldBind} = RoleAttr,
    % (GoldUnbind+GoldBind)>=DeductMoney;
%%当前仅限于扣除元宝
check_money_enough(DeductAny,DeductUnbind,RoleAttr)when is_record(RoleAttr,p_role_attr)->
    #p_role_attr{gold=GoldUnbind,gold_bind=GoldBind} = RoleAttr,
    (GoldUnbind >= DeductUnbind) andalso (GoldBind >= DeductAny).
    % (GoldUnbind >= DeductUnbind) andalso ( (GoldUnbind + GoldBind - DeductUnbind - DeductAny) >= 0).

check_money_enough_and_throw(MoneyType,DeductMoney,RoleID)when is_integer(RoleID) ->
   {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    check_money_enough_and_throw(MoneyType,DeductMoney,RoleAttr);
check_money_enough_and_throw(MoneyType,DeductMoney,RoleAttr)when is_record(RoleAttr,p_role_attr) ->
    case check_money_enough(MoneyType,DeductMoney,RoleAttr) of
        true ->
            [];
        false ->
            case MoneyType of
                silver_any->
                    ErrReason = common_tool:get_format_lang_resources(<<"铜币不足，需要~s铜币">>,[DeductMoney]);
                silver_unbind ->
                    ErrReason = common_tool:get_format_lang_resources(<<"铜币不足，需要~s铜币">>,[DeductMoney]);
                gold_any ->
                    ErrReason = common_tool:get_format_lang_resources(<<"礼券不足，需要~s礼券">>,[DeductMoney]);
                gold_unbind ->
                    ErrReason = common_tool:get_format_lang_resources(<<"元宝不足，需要~s元宝">>,[DeductMoney]);
                _ ->
                    ErrReason = common_tool:get_format_lang_resources(<<"元宝及礼券不足，需要~s元宝和~s礼券">>,[DeductMoney, MoneyType])
            end,
            ?THROW_ERR(?ERR_OTHER_ERR, ErrReason)
    end.

%% @doc 使用钱的接口(包括记录日志，更新客户端，设置进程字典数据)
%% （内部有事务处理，调用方不能在事务内调用该方法）
%% @parm RoleID 玩家id
%% @parm MoneyType 消费的金钱类型：silver_unbind, silver_any, gold_unbind, gold_any
%% @parm Cost 消费金额
%% @parm LogType 用于记录日志
%% @return true如果成功，否则{error, Reason}
use_money(RoleID, MoneyType, Cost, LogType) ->
  Fun = fun() ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    case t_deduct_money(MoneyType, Cost, RoleAttr, LogType, 0, 0) of
        {ok, RoleAttr2} ->
            mod_map_role:set_role_attr(RoleID, RoleAttr2),
            case ((MoneyType == gold_unbind) orelse (MoneyType == gold_any)) of
                true ->  common_misc:send_role_gold_change(RoleID, RoleAttr2);
                false -> common_misc:send_role_silver_change(RoleID, RoleAttr2)
            end,
            true;
        {error, Reason} ->
            {error, Reason}
    end
  end,
  {atomic, Return} = common_transaction:t(Fun),
  Return.


%%@doc 通用的扣除钱币、元宝的接口，包括记录消费日志
%% 如果ConsumeLogType == no_log, 则不记录日志(这个主要是考虑到执行事务回滚时不应记录日志的)
%% ConsumeLogType可以为一个整型的Type， 也可以是: {LogType, MDetail::string() 操作内容}
t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeLogType) when DeductMoney>=0->
	t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeLogType,0,1).
t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeLogType,ItemId,ItemAmount) when is_integer(RoleID) andalso DeductMoney>=0->
	{ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    case DeductMoney > 0 of
        true ->
            case t_deduct_money(MoneyType,DeductMoney,RoleAttr,ConsumeLogType,ItemId,ItemAmount) of
                {ok,RoleAttr2} ->
                    mod_map_role:set_role_attr(RoleID, RoleAttr2), 
                    {ok,RoleAttr2};
                {error, Reason}->
                    {error, Reason}
            end;
        false ->
            {ok,RoleAttr}
    end;
%%钱币
%%T6, 没有不绑定铜钱!!!
t_deduct_money(silver_unbind,DeductMoney,RoleAttr,ConsumeLogType,ItemId,ItemAmount) when is_record(RoleAttr,p_role_attr) andalso DeductMoney>=0->
    t_deduct_money(silver_any,DeductMoney,RoleAttr,ConsumeLogType,ItemId,ItemAmount);
    % #p_role_attr{role_id=RoleID,silver=SilverUnbind} = RoleAttr,
    % if
    %     SilverUnbind>=DeductMoney->
    %         case ConsumeLogType of
    %             no_log -> ignore;
    %             _ ->
    %                 case ConsumeLogType of
    %                     {Type, LogDetailStr} ->
    %                    common_consume_logger:use_silver({RoleID,0,DeductMoney,Type,LogDetailStr,ItemId,ItemAmount});
    %                     _ ->
    %                          common_consume_logger:use_silver({RoleID,0,DeductMoney,ConsumeLogType,"",ItemId,ItemAmount})
    %                 end
    %         end,
    %         NewUnBind = (SilverUnbind-DeductMoney),
    %         {ok,RoleAttr#p_role_attr{silver=NewUnBind}};
    %     true ->
    %         {error, ?_LANG_NOT_ENOUGH_SILVER}
    % end;
%%钱币,优先消耗铜钱
%%T6, 没有不绑定铜钱!!!
t_deduct_money(silver_any,DeductMoney,RoleAttr,ConsumeLogType,ItemId,ItemAmount) when is_record(RoleAttr,p_role_attr) andalso DeductMoney>=0->
    #p_role_attr{role_id=RoleID,silver_bind=SilverBind} = RoleAttr,
    % silver=SilverUnbind,
    if
        SilverBind>=DeductMoney->
            case ConsumeLogType of
                no_log -> ignore;
                _ ->    
                    case ConsumeLogType of
                        {Type, LogDetailStr} ->
                             common_consume_logger:use_silver({RoleID,DeductMoney,0,Type,LogDetailStr,ItemId,ItemAmount});
                        _ ->
                             common_consume_logger:use_silver({RoleID,DeductMoney,0,ConsumeLogType,"",ItemId,ItemAmount})
                    end
           
            end,
            NewBind = (SilverBind-DeductMoney),
            {ok,RoleAttr#p_role_attr{silver_bind=NewBind}};
        true ->
            {error, ?_LANG_NOT_ENOUGH_SILVER}
    end;

    % #p_role_attr{role_id=RoleID,silver=SilverUnbind,silver_bind=SilverBind} = RoleAttr,
    % if
    %     SilverBind>=DeductMoney->
    %         case ConsumeLogType of
    %             no_log -> ignore;
    %             _ ->    
    %                 case ConsumeLogType of
    %                     {Type, LogDetailStr} ->
    %                          common_consume_logger:use_silver({RoleID,DeductMoney,0,Type,LogDetailStr,ItemId,ItemAmount});
    %                     _ ->
    %                          common_consume_logger:use_silver({RoleID,DeductMoney,0,ConsumeLogType,"",ItemId,ItemAmount})
    %                 end
           
    %         end,
    %         NewBind = (SilverBind-DeductMoney),
    %         {ok,RoleAttr#p_role_attr{silver_bind=NewBind}};
    %     (SilverUnbind+SilverBind)>=DeductMoney->
    %         case ConsumeLogType of
    %             no_log -> ignore;
    %             _ -> 
    %                 case ConsumeLogType of
    %                     {Type, LogDetailStr} ->
    %                          common_consume_logger:use_silver({RoleID,SilverBind,(DeductMoney-SilverBind),Type,LogDetailStr,ItemId,ItemAmount});
    %                     _ ->
    %                          common_consume_logger:use_silver({RoleID,SilverBind,(DeductMoney-SilverBind),ConsumeLogType,"",ItemId,ItemAmount})
    %                 end
           
    %         end,
    %         NewBind = 0,
    %         NewUnBind = (SilverUnbind+SilverBind) - DeductMoney,
    %         {ok,RoleAttr#p_role_attr{silver_bind=NewBind,silver=NewUnBind}};
    %     true ->
    %         {error, ?_LANG_NOT_ENOUGH_SILVER}
    % end;
%%不绑定元宝
t_deduct_money(gold_unbind,DeductMoney,RoleAttr,ConsumeLogType,ItemId,ItemAmount) when is_record(RoleAttr,p_role_attr) andalso DeductMoney>=0->
	case DeductMoney > 0 of
        true ->
            #p_role_attr{role_id=RoleID,gold=GoldUnbind} = RoleAttr,
            case mod_qq_helper:check_buy_goods(RoleID, GoldUnbind, DeductMoney) of
        		ok ->
                    Token = mod_qq_helper:get_buy_goods_token(RoleID, DeductMoney, true),
                    case mod_qq_helper:wait_buy_goods_callback(5000, Token) of
                        {true, Amt} ->
                            case ConsumeLogType of
                                no_log -> ignore;
                                _ -> 
                                    case ConsumeLogType of
                                        {Type, LogDetailStr} ->
                                             common_consume_logger:use_gold({RoleID, 0, Amt, Type,LogDetailStr,ItemId,ItemAmount});
                                        _ ->
                                             common_consume_logger:use_gold({RoleID, 0, Amt, ConsumeLogType,"",ItemId,ItemAmount})
                                    end
                            end,
                            NewBind = (GoldUnbind-Amt),
                            {ok, RoleAttr#p_role_attr{gold=erlang:trunc(NewBind)}};
                        {false, Reason} ->
                            ?ERROR_MSG("Request QQ use gold failed, reason: ~w", [Reason]),
                            {error, Reason}
                    end;
        		{error, Reason} ->
        			{error, Reason}
        	end;
        false ->
            {ok, RoleAttr}
    end;

%%元宝,优先消耗绑定元宝
%%Note:由于接入QQ接口,  gold_any只扣除绑定的元宝/礼券, 跟元宝没关系
t_deduct_money(gold_any,DeductMoney,RoleAttr,ConsumeLogType,ItemId,ItemAmount) when is_record(RoleAttr,p_role_attr) andalso DeductMoney>=0->
    #p_role_attr{role_id=RoleID ,gold_bind=GoldBind} = RoleAttr,
    if
        GoldBind>=DeductMoney->
            case ConsumeLogType of
                no_log -> ignore;
                _ -> 
                    case ConsumeLogType of
                        {Type, LogDetailStr} ->
                             common_consume_logger:use_gold({RoleID, DeductMoney, 0, Type,LogDetailStr,ItemId,ItemAmount});
                        _ ->
                             common_consume_logger:use_gold({RoleID, DeductMoney, 0, ConsumeLogType,"",ItemId,ItemAmount})
                    end
            end,
            NewBind = (GoldBind-DeductMoney),
            {ok, RoleAttr#p_role_attr{gold_bind=erlang:trunc(NewBind)}};
        true ->
          {error, ?_LANG_ROLE_MONEY_NOT_ENOUGH_GOLD_BIND}
    end;

%%需要消耗两种元宝, 有需求先扣除未绑定元宝, 再扣除any的元宝, 为避免消耗, 增加该接口
%%Note:由于接入QQ接口,  gold_any只扣除绑定的元宝/礼券, 跟元宝没关系
t_deduct_money(DeductGoldAny,DeductGoldUnBind,RoleAttr,ConsumeLogType,ItemId,ItemAmount) when is_record(RoleAttr,p_role_attr) andalso DeductGoldAny>=0 andalso DeductGoldUnBind>=0->
	#p_role_attr{gold_bind=GoldBind} = RoleAttr,
    case GoldBind >= DeductGoldAny of
        false ->
            {error, ?_LANG_ROLE_MONEY_NOT_ENOUGH_GOLD_ANY};
        true ->
            RoleAttr1 = RoleAttr#p_role_attr{gold_bind = erlang:trunc(GoldBind-DeductGoldAny)},
            t_deduct_money(gold_unbind,DeductGoldUnBind,RoleAttr1,ConsumeLogType,ItemId,ItemAmount)
    end.

%% 加声望
add_prestige(RoleID, GainPrestige, PrestigeLogType) ->
    Fun = fun() -> t_gain_prestige(GainPrestige,RoleID,PrestigeLogType) end,
    {atomic, {ok, NewRoleAttr}} = common_transaction:t(Fun),
    ChangeList = [#p_role_attr_change{
                      change_type = ?ROLE_SUM_PRESTIGE_CHANGE, 
                      new_value   = NewRoleAttr#p_role_attr.sum_prestige
                  },
                  #p_role_attr_change{
                      change_type = ?ROLE_CUR_PRESTIGE_CHANGE, 
                      new_value   = NewRoleAttr#p_role_attr.cur_prestige
                  }],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList).

%% 获得声望
t_gain_prestige(GainPrestige,RoleID,PrestigeLogType) when is_integer(RoleID)->
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    case t_gain_prestige(GainPrestige,RoleAttr,PrestigeLogType) of
        {ok,RoleAttr2} ->
            mod_map_role:set_role_attr(RoleID,RoleAttr2),
            {ok,RoleAttr2};
        _ ->
            {error,not_found}
    end;
t_gain_prestige(GainPrestigeTmp,RoleAttr,PrestigeLogType) when is_record(RoleAttr,p_role_attr)->
	GainPrestige = common_tool:ceil(GainPrestigeTmp),
	#p_role_attr{role_id=RoleID,sum_prestige=SumPrestige,cur_prestige=CurPrestige} = RoleAttr,
    common_prestige_logger:gain_prestige({RoleID,GainPrestige,PrestigeLogType,""}),
	{ok,RoleAttr#p_role_attr{sum_prestige=SumPrestige + GainPrestige,cur_prestige=CurPrestige + GainPrestige}}.


%% 扣取声望封装
use_prestige(RoleID, DeductPrestige, PrestigeLogType) ->
  Fun = fun() -> t_deduct_prestige(DeductPrestige,RoleID,PrestigeLogType) end,
    {atomic, {ok, NewRoleAttr}} = common_transaction:t(Fun),
    ChangeList = [#p_role_attr_change{
                      change_type = ?ROLE_SUM_PRESTIGE_CHANGE, 
                      new_value   = NewRoleAttr#p_role_attr.sum_prestige
                  },
                  #p_role_attr_change{
                      change_type = ?ROLE_CUR_PRESTIGE_CHANGE, 
                      new_value   = NewRoleAttr#p_role_attr.cur_prestige
                  }],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList).

%% 扣取声望
t_deduct_prestige(DeductPrestige,RoleID,PrestigeLogType) when is_integer(RoleID)->
	{ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    case t_deduct_prestige(DeductPrestige,RoleAttr,PrestigeLogType) of
        {ok,RoleAttr2} ->
            mod_map_role:set_role_attr(RoleID,RoleAttr2),
            {ok,RoleAttr2};
        {error,not_enough}->
            {error,not_enough}
    end;
t_deduct_prestige(DeductPrestigeTmp,RoleAttr,PrestigeLogType) when is_record(RoleAttr,p_role_attr)->
	DeductPrestige = common_tool:ceil(DeductPrestigeTmp),
	#p_role_attr{role_id=RoleID,cur_prestige=CurPrestige} = RoleAttr,
	case CurPrestige - DeductPrestige of
		NewCurPrestige when NewCurPrestige >= 0 ->
            common_prestige_logger:use_prestige({RoleID,DeductPrestige,PrestigeLogType,""}),
			{ok,RoleAttr#p_role_attr{cur_prestige=NewCurPrestige}};
		_ ->
			{error,not_enough}
	end.

%% 判断声望是否足够
check_prestige_enough(RoleID, DeductPrestige) when is_integer(RoleID) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    check_prestige_enough(RoleAttr, DeductPrestige);
check_prestige_enough(RoleAttr, DeductPrestige) ->
    (RoleAttr#p_role_attr.cur_prestige >= DeductPrestige).

add_yueli(RoleID, AddYueli, LogType) ->
    Fun = fun() -> t_gain_yueli(AddYueli, RoleID, LogType) end,
    {atomic, {ok, NewRoleAttr}} = common_transaction:t(Fun),
    
    ChangeList = [#p_role_attr_change{
                      change_type = ?ROLE_YUELI_ATTR_CHANGE, 
                      new_value   = NewRoleAttr#p_role_attr.yueli
                  }],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList).            

%% 获得阅历
t_gain_yueli(GainYueli,RoleID,YueliLogType) when is_integer(RoleID)->
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    case t_gain_yueli(GainYueli,RoleAttr,YueliLogType) of
        {ok,RoleAttr2} ->
            mod_map_role:set_role_attr(RoleID,RoleAttr2),
            {ok,RoleAttr2};
        _ ->
            {error,not_found}
    end;
t_gain_yueli(GainYueliTmp,RoleAttr,YueliLogType) when is_record(RoleAttr,p_role_attr)->
  GainYueli = common_tool:ceil(GainYueliTmp),
  #p_role_attr{role_id=RoleID,yueli=Yueli} = RoleAttr,
    common_yueli_logger:gain_yueli({RoleID,GainYueli,YueliLogType,""}),
  {ok,RoleAttr#p_role_attr{yueli=Yueli + GainYueli}}.
  
%% 扣取阅历
t_deduct_yueli(DeductYueli,RoleID,YueliLogType) when is_integer(RoleID)->
  {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    case t_deduct_yueli(DeductYueli,RoleAttr,YueliLogType) of
        {ok,RoleAttr2} ->
            mod_map_role:set_role_attr(RoleID,RoleAttr2),
            {ok,RoleAttr2};
        {error,not_enough}->
            {error,not_enough}
    end;
t_deduct_yueli(DeductYueliTmp,RoleAttr,YueliLogType) when is_record(RoleAttr,p_role_attr)->
  DeductYueli = common_tool:ceil(DeductYueliTmp),
  #p_role_attr{role_id=RoleID,yueli=Yueli} = RoleAttr,
  case Yueli - DeductYueli of
    NewYueli when NewYueli >= 0 ->
            common_yueli_logger:use_yueli({RoleID,DeductYueli,YueliLogType,""}),
      {ok,RoleAttr#p_role_attr{yueli=NewYueli}};
    _ ->
      {error,not_enough}
  end.

%% 判断阅历是否足够
check_yueli_enouth(RoleID, Cost) when is_integer(RoleID) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    check_yueli_enouth(RoleAttr, Cost);
check_yueli_enouth(RoleAttr, Cost) ->
      (RoleAttr#p_role_attr.yueli >= Cost).