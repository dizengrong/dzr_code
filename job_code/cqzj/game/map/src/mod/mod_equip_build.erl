%%%-------------------------------------------------------------------
%%% @author  caochuncheng
%%% @copyright mcsd (C) 2010, 
%%% @doc
%%% 装备打造处理进程
%%% @end
%%% Created : 28 Jul 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_equip_build).

%% Include files
-include("mgeem.hrl").
-include("equip_build.hrl").
-include("refining.hrl").

%% API
-export([init_ets/0,handle/2]).


-export([do_transaction_dedcut_goods/3,%% 根据物品列表的消耗一定数量的物品，规则是先扣绑定物品再扣不绑定物品
         get_goods_sum/2 %% 获取同类打造材料的总数
        ]).

-export([ %% 铁匠铺共用函数
          get_dirty_equip_build_goods_list/2,
          get_equip_build_material_dict/0,
          count_class_equip_build_goods/2,
          get_equip_build_class_goods/2,
          get_equip_build_bag_id/0,
          get_equip_build_goods/3
        ]).

%%初始化ets表
init_ets() ->
    ok.

%% 消息处理
handle({Unique, ?EQUIP_BUILD, ?EQUIP_BUILD_LIST, DataRecord, RoleId, Pid, Line},_State) ->
    ?DEBUG("equip_build_list",[]),
    do_equip_build_list({Unique,?EQUIP_BUILD,?EQUIP_BUILD_LIST,DataRecord, RoleId, Pid, Line});
handle({Unique, ?EQUIP_BUILD, ?EQUIP_BUILD_BUILD, DataRecord, RoleId, Pid, Line},_State) ->
    do_equip_build_build({Unique,?EQUIP_BUILD,?EQUIP_BUILD_BUILD,DataRecord, RoleId, Pid, Line});
handle({Unique, ?EQUIP_BUILD, ?EQUIP_BUILD_GOODS, DataRecord, RoleId, Pid, Line},_State) ->
    do_equip_build_goods({Unique,?EQUIP_BUILD,?EQUIP_BUILD_GOODS,DataRecord, RoleId, Pid, Line});

handle({Unique, ?EQUIP_BUILD, ?EQUIP_BUILD_QUALITY_GOODS, DataRecord, RoleId, Pid, Line},_State) ->
    mod_equip_change:do_equip_quality_goods({Unique,?EQUIP_BUILD, ?EQUIP_BUILD_QUALITY_GOODS,DataRecord, RoleId, Pid, Line});
%% 品质改造
handle({Unique, ?EQUIP_BUILD, ?EQUIP_BUILD_QUALITY, DataRecord, RoleId, Pid, Line},_State) ->
    mod_equip_change:do_equip_quality({Unique,?EQUIP_BUILD, ?EQUIP_BUILD_QUALITY,DataRecord, RoleId, Pid, Line});
%% 更改签名
handle({Unique, ?EQUIP_BUILD, ?EQUIP_BUILD_SIGNATURE, DataRecord, RoleId, Pid, Line},_State) ->
    mod_equip_change:do_equip_signature({Unique,?EQUIP_BUILD, ?EQUIP_BUILD_SIGNATURE,DataRecord, RoleId, Pid, Line});
%%升级装备信息
handle({Unique, ?EQUIP_BUILD, ?EQUIP_BUILD_UPGRADE_LINK, DataRecord, RoleId, Pid, Line},_State) ->
    mod_equip_change:do_equip_upgrade_link({Unique,?EQUIP_BUILD, ?EQUIP_BUILD_UPGRADE_LINK,DataRecord, RoleId, Pid, Line});
%% 升级材料
handle({Unique, ?EQUIP_BUILD, ?EQUIP_BUILD_UPGRADE_GOODS, DataRecord, RoleId, Pid, Line},_State) ->
    mod_equip_change:do_equip_upgrade_goods({Unique,?EQUIP_BUILD, ?EQUIP_BUILD_UPGRADE_GOODS,DataRecord, RoleId, Pid, Line});
%% 装备升级
handle({Unique, ?EQUIP_BUILD, ?EQUIP_BUILD_UPGRADE, DataRecord, RoleId, Pid, Line},_State) ->
    mod_equip_change:do_equip_upgrade({Unique,?EQUIP_BUILD, ?EQUIP_BUILD_UPGRADE,DataRecord, RoleId, Pid, Line});
%% 装备分解
handle({Unique, ?EQUIP_BUILD, ?EQUIP_BUILD_DECOMPOSE, DataRecord, RoleId, Pid, Line},_State) ->
    mod_equip_change:do_equip_decompose({Unique,?EQUIP_BUILD, ?EQUIP_BUILD_DECOMPOSE,DataRecord, RoleId, Pid, Line});

handle(Info,_State) ->
    ?ERROR_MSG("~ts,Info=~w",["无法处理此消息",Info]).

%% 消息处理
do_equip_build_list({Unique, Module, Method, DataRecord, RoleId, Pid, Line}) ->
    BuildLevel = DataRecord#m_equip_build_list_tos.build_level,
    case get_equip_build_level_record(BuildLevel) of
        {ok,BuildRecord} ->
            do_equip_build_list2({Unique, Module, Method, DataRecord, RoleId, Pid, Line},{BuildRecord});
        {error,Error} ->
            ?DEBUG("~ts,Error=~w",["获取打造列表出错",Error]),
            R = ?_LANG_EQUIP_BUILD_LEVEL_INVALID,
            do_equip_build_list_error({Unique, Module, Method, DataRecord, RoleId, Pid, Line}, R)
    end.
do_equip_build_list2({Unique, Module, Method, DataRecord, RoleId, Pid, Line},{BuildRecord}) ->
    %% 获取可打造的装备，根据装备级别范围查询装备配置表中的符合条件的数据
    case get_equip_build_equip_list(BuildRecord) of
        [] ->
            R = ?_LANG_EQUIP_BUILD_EQUIP_LIST_NULL,
            do_equip_build_list_error({Unique, Module, Method, DataRecord, RoleId, Pid, Line}, R);
        EquipBuildList ->
            do_equip_build_list3({Unique, Module, Method, DataRecord, RoleId, Pid, Line},{BuildRecord,EquipBuildList})
    end.
do_equip_build_list3({Unique, Module, Method, DataRecord, RoleId, _Pid, Line},{_BuildRecord,EquipBuildList}) ->
    BuildLevel = DataRecord#m_equip_build_list_tos.build_level,
%%    BaseList = get_dirty_equip_build_goods_list(?EQUIP_BUILD_BASE,RoleId),
%%    AddList = get_dirty_equip_build_goods_list(?EQUIP_BUILD_ADD,RoleId),
    NewEquipBuildList = [#p_equip_build_equip{type_id=R#p_equip_base_info.typeid,
                                              equip_name = R#p_equip_base_info.equipname,
                                              level =  (R#p_equip_base_info.requirement)#p_use_requirement.min_level,
                                              slot_num =  R#p_equip_base_info.slot_num ,
                                              kind =  R#p_equip_base_info.kind,
                                              material = R#p_equip_base_info.material} || R <- EquipBuildList],
%%    NewBaseList = count_class_equip_build_goods(BaseList,[]),
%%    NewAddList = count_class_equip_build_goods(AddList,[]),
    Message = #m_equip_build_list_toc{ succ = true, build_level = BuildLevel, build_list = NewEquipBuildList},
    common_misc:unicast(Line,RoleId, Unique, Module, Method, Message).

do_equip_build_list_error({Unique, Module, Method, DataRecord, RoleId, _Pid, Line},Reason) ->
    BuildLevel = DataRecord#m_equip_build_list_tos.build_level,
    SendSelf=#m_equip_build_list_toc{succ = false, reason=Reason, build_level=BuildLevel},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).

%% 获取角色背包打造材料信息
do_equip_build_goods({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) ->
    Material = DataRecord#m_equip_build_goods_tos.material,
    MaterialList = get_equip_build_material_dict(),
    NewMaterialList = lists:append([MaterialList,[0]]),
    case lists:member(Material, NewMaterialList) of 
        false ->
            R = ?_LANG_EQUIP_BUILD_GET_GOODS_PARAM_ERROR,
            do_equip_build_goods_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line}, R);
        _ ->
           do_equip_build_goods2({Unique,Module,Method,DataRecord, RoleId, Pid, Line})
    end.
do_equip_build_goods2({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) ->
    Material = DataRecord#m_equip_build_goods_tos.material,
    if Material =:= 0 ->
            do_equip_build_goods3({Unique,Module,Method,DataRecord, RoleId, Pid, Line});
       true ->
            do_equip_build_goods4({Unique,Module,Method,DataRecord, RoleId, Pid, Line})
    end.

do_equip_build_goods3({Unique,Module,Method,DataRecord, RoleId, _Pid, Line}) ->
    Material = DataRecord#m_equip_build_goods_tos.material,
    BaseList = get_dirty_equip_build_goods_list(?EQUIP_BUILD_BASE,RoleId),
    AddList = get_dirty_equip_build_goods_list(?EQUIP_BUILD_ADD,RoleId),
    NewBaseList = count_class_equip_build_goods(BaseList,[]),
    NewAddList = count_class_equip_build_goods(AddList,[]),
    SendSelf=#m_equip_build_goods_toc{succ = true, material= Material, base_list = NewBaseList,add_list = NewAddList},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).

do_equip_build_goods4({Unique,Module,Method,DataRecord, RoleId, _Pid, Line}) ->
    Material = DataRecord#m_equip_build_goods_tos.material,
    BaseList = get_dirty_equip_build_goods_list(?EQUIP_BUILD_BASE,RoleId),
    AddList = get_dirty_equip_build_goods_list(?EQUIP_BUILD_ADD,RoleId),
    NewBaseList = count_class_equip_build_goods(BaseList,[]),
    NewAddList = count_class_equip_build_goods(AddList,[]),
    BaseMaterial = get_equip_build_class_goods(Material,?EQUIP_BUILD_BASE),
    AddMaterial = get_equip_build_class_goods(Material,?EQUIP_BUILD_ADD),
    NewBaseList2 = lists:filter(fun(BR) ->
                                        case lists:keyfind(BR#p_equip_build_goods.type_id,
                                                           #r_equip_build_item.item_id, BaseMaterial) of
                                            false -> false;
                                            _ -> true
                                        end 
                                end,NewBaseList),
    NewAddList2 = lists:filter(fun(AR) ->
                                        case lists:keyfind(AR#p_equip_build_goods.type_id,
                                                           #r_equip_build_item.item_id, AddMaterial) of
                                            false -> false;
                                            _ -> true
                                        end 
                               end,NewAddList),
    SendSelf=#m_equip_build_goods_toc{succ = true, material= Material, base_list = NewBaseList2,add_list = NewAddList2},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).
    
do_equip_build_goods_error({Unique,Module,Method,DataRecord, RoleId, _Pid, Line}, Reason) ->
    Material = DataRecord#m_equip_build_goods_tos.material,
    SendSelf=#m_equip_build_goods_toc{succ = false, reason=Reason, material= Material},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).

%% 打造处理
do_equip_build_build({Unique, Module, Method, DataRecord, RoleId, Pid, Line}) ->
    case catch do_equip_build_build2(RoleId,DataRecord) of
        {error, R} ->
            do_equip_build_build_error({Unique, Module, Method, DataRecord, RoleId, Pid, Line}, R);
        {ok,BuildRecord,EquipBaseInfo,AddGoodsList,AddItem} ->
            do_equip_build_build3({Unique, Module, Method, DataRecord, RoleId, Pid, Line},
                                  {BuildRecord,EquipBaseInfo,AddGoodsList,AddItem})
    end.
do_equip_build_build2(RoleId,DataRecord) ->
    #m_equip_build_build_tos{equip_type_id = EquipTypeId,
                             build_level = BuildLevel,
                             add_type_id=AddTypeId} = DataRecord,
    BuildRecord = 
        case get_equip_build_level_record(BuildLevel) of
            {ok,BuildRecordT} ->
                BuildRecordT;
            {error,_BuildRecordError} ->
                erlang:throw({error,?_LANG_EQUIP_BUILD_LEVEL_INVALID})
        end,
    #r_equip_build{min_level = MinLevel,max_level = MaxLevel} = BuildRecord,
    EquipBaseInfo = 
        case get_equip_build_equip(EquipTypeId, MinLevel, MaxLevel) of
            undefined ->
                erlang:throw({error,?_LANG_EQUIP_BUILD_EQUIP_TYPE_ID_ERROR});
            EquipBaseInfoT ->
                EquipBaseInfoT
        end,
    if AddTypeId =:= 0 ->
            erlang:throw({error,?_LANG_EQUIP_BUILD_GOODS_ENOUGH});
       true ->
            next
    end,
    AddGoodsList = 
        case get_dirty_equip_build_goods(RoleId,AddTypeId) of
            {error,_AddGoodsError} ->
                erlang:throw({error,?_LANG_EQUIP_BUILD_GET_GOODS});
            {ok,AddGoodsListT} ->
                AddGoodsListT
        end,
    AddItem = 
        case get_equip_build_record(AddTypeId) of
            [] ->
                erlang:throw({error,?_LANG_EQUIP_BUILD_GOODS_ENOUGH});
            [AddItemT] ->
                AddItemT
        end,
    {ok,BuildRecord,EquipBaseInfo,AddGoodsList,AddItem}.
do_equip_build_build3({Unique, Module, Method, DataRecord, RoleId, Pid, Line},
                      {BuildRecord,EquipBaseInfo,AddGoodsList,AddItem}) -> 
    #r_equip_build{fee = Fee} = BuildRecord,
    AddGoodsNum = 1,
    case catch do_transaction_build_equip({RoleId,DataRecord,EquipBaseInfo,
                                           AddGoodsList,AddItem,AddGoodsNum,Fee}) of
        {error,R} ->
            ?DEBUG("~ts,Reason=~w",["打造过程出错",R]),
            do_equip_build_build_error({Unique, Module, Method, DataRecord, RoleId, Pid, Line}, R);
        {ok,NewEquip,DelAddGoddsList,UpdateAddGoodsList} ->
            do_equip_build_build4({Unique, Module, Method, DataRecord, RoleId, Pid, Line},
                                  {BuildRecord,NewEquip,DelAddGoddsList,UpdateAddGoodsList})
    end.

do_equip_build_build4({Unique, Module, Method, DataRecord, RoleId, Pid, Line},
                      {BuildRecord,NewEquip,DelAddGoddsList,UpdateAddGoodsList}) ->
    BuildLevel = DataRecord#m_equip_build_build_tos.build_level,
    BuildEquipList = get_equip_build_equip_list(BuildRecord),
    BaseList = get_dirty_equip_build_goods_list(?EQUIP_BUILD_BASE,RoleId),
    AddList = get_dirty_equip_build_goods_list(?EQUIP_BUILD_ADD,RoleId),
    NewEquipBuildList = [#p_equip_build_equip{type_id=R#p_equip_base_info.typeid,
                                              equip_name = R#p_equip_base_info.equipname,
                                              level =  (R#p_equip_base_info.requirement)#p_use_requirement.min_level,
                                              slot_num =  R#p_equip_base_info.slot_num ,
                                              kind =  R#p_equip_base_info.kind,
                                              material =R#p_equip_base_info.material} || R <- BuildEquipList],
    NewBaseList = count_class_equip_build_goods(BaseList,[]),
    NewAddList = count_class_equip_build_goods(AddList,[]),
    BaseGoods = #p_equip_build_goods{type_id=0,name="",current_num = 0},
    AddGoods = 
        if DelAddGoddsList =:= [] ->
                #p_equip_build_goods{type_id=0,name="",current_num = 0};
           true ->
                [TempAddGoods] =  count_class_equip_build_goods(DelAddGoddsList,[]),
                %% 道具消费日志
                catch common_item_logger:log(RoleId,TempAddGoods#p_equip_build_goods.type_id, 
                                             TempAddGoods#p_equip_build_goods.current_num,
                                             undefined,
                                             ?LOG_ITEM_TYPE_DA_ZAO_SHI_QU),
                TempAddGoods
        end,
    NewEquipGoods = #p_equip_build_goods{type_id=NewEquip#p_goods.typeid,name=NewEquip#p_goods.name,
                                         current_num=NewEquip#p_goods.current_num},
    Message = #m_equip_build_build_toc{succ = true, build_level = BuildLevel,
                                       build_list = NewEquipBuildList, base_list = NewBaseList, add_list = NewAddList,
                                       new_equip=NewEquipGoods,base_goods= BaseGoods,add_goods=AddGoods},
    %% 道具消费日志
    common_item_logger:log(RoleId,NewEquip,?LOG_ITEM_TYPE_DA_ZAO_HUO_DE),
    common_misc:unicast(Line,RoleId, Unique, Module, Method, Message),
    do_equip_build_build5({Unique, Module, Method, DataRecord, RoleId, Pid, Line},
                          {NewEquip,DelAddGoddsList,UpdateAddGoodsList}).

%% 通知背包更新相关的数据，钱，材料，新的装备信息
do_equip_build_build5({_Unique, _Module, _Method, _DataRecord, RoleId, _Pid, Line},
                      {NewEquip,DelAddGoddsList,UpdateAddGoodsList}) ->
    UnicastArg = {line, Line, RoleId},
    %% 附加材料
    NotifyAddList = 
        lists:filter(
          fun(R3) -> 
                  case lists:keyfind(R3#p_goods.id,#p_goods.id,UpdateAddGoodsList) of
                      false -> true;
                      _ -> false
                  end
          end,DelAddGoddsList),
    if NotifyAddList =/= [] ->
            ?DEBUG("~ts,NotifyAddList=~w",["删除打造附加材料通知",NotifyAddList]),
            common_misc:del_goods_notify(UnicastArg, NotifyAddList);
       true ->
            ignore
    end,
    if UpdateAddGoodsList =/= [] ->
            ?DEBUG("~ts",["更新打造附加材料通知"]),
            common_misc:update_goods_notify(UnicastArg, UpdateAddGoodsList);
       true ->
            ignore
    end,
    %% 扣费
    case mod_map_role:get_role_attr(RoleId) of
        {ok, RoleAttr} ->
            AttrChangeList = [#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value = RoleAttr#p_role_attr.silver},
                               #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value = RoleAttr#p_role_attr.silver_bind}],
            common_misc:role_attr_change_notify(UnicastArg,RoleId,AttrChangeList);
        {error ,R} ->
            ?ERROR_MSG("~ts,Reason=~w",["获取角色属性出错，打造成功之后无法通知前端钱币变化情况",R])
    end,
	%% 装备打造
    % hook_equip_build:hook({RoleId,NewEquip}),
    %% 新装备
    common_misc:new_goods_notify(UnicastArg,NewEquip),
    %% add by caochuncheng 打造极品装备广播消息
    do_equip_build_build6({RoleId,NewEquip,DelAddGoddsList}).

do_equip_build_build6({RoleId,NewEquip,DelAddGoddsList}) ->
    if NewEquip#p_goods.current_colour >= ?COLOUR_ORANGE ->
            %% 需要广播
            case mod_map_role:get_role_base(RoleId) of
                {ok, RoleBase} ->
                    do_equip_build_build7({RoleId,NewEquip,RoleBase,DelAddGoddsList});
                {error,R} ->
                    ?INFO_MSG("~ts,Error=~w",["打造装备时处理消息广播查询用户信息出错",R]),
                    ignore
            end;
       true ->
            ignore
    end.
do_equip_build_build7({RoleId,NewEquip,RoleBase,DelAddGoddsList}) ->
    FactionName = 
        if RoleBase#p_role_base.faction_id =:= 3 ->
                ?_LANG_COLOR_FACTION_3;
           RoleBase#p_role_base.faction_id =:= 2 ->
                ?_LANG_COLOR_FACTION_2;
           true ->
                ?_LANG_COLOR_FACTION_1
        end,
    EquipName = common_goods:get_notify_goods_name(NewEquip),
    ItemName = 
        case DelAddGoddsList =/= [] of
            true ->
                common_goods:get_notify_goods_name(lists:nth(1,DelAddGoddsList));
            _ ->
                ""
        end,
    CenterMessage = common_tool:get_format_lang_resources(?_LANG_EQUIP_BUILD_EQUIP_BIND_SUCC,[FactionName,RoleBase#p_role_base.role_name,ItemName,EquipName]),
    LeftMessage = common_tool:get_format_lang_resources(?_LANG_EQUIP_BUILD_EQUIP_BIND_LEFT_SUCC,[FactionName,RoleBase#p_role_base.role_name,ItemName]),
    catch common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_SUB_TYPE,CenterMessage),
    catch common_broadcast:bc_send_msg_world_include_goods([?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_WORLD,LeftMessage,
                                                           RoleId,common_tool:to_list(RoleBase#p_role_base.role_name),
                                                           RoleBase#p_role_base.sex,NewEquip),
    ok.


do_equip_build_build_error({Unique, Module, Method, DataRecord, RoleId, _Pid, Line}, Reason) ->
    BuildLevel = DataRecord#m_equip_build_build_tos.build_level,
    SendSelf=#m_equip_build_build_toc{succ = false, reason=Reason, build_level=BuildLevel},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).


%% 装备打造过程处理，即产生新的装备，打造材料的消耗
do_transaction_build_equip({RoleId,DataRecord,EquipBaseInfo,AddGoodsList,AddItem,AddGoodsNum,Fee}) ->
    %% 先根据概率生成打造装备，再统一事务处理操作更新相关信息
    %% 角色名称
    {ok,RoleBase} = mod_map_role:get_role_base(RoleId),
    EquipName = lists:append([common_tool:to_list(RoleBase#p_role_base.role_name), common_tool:to_list(?_LANG_EQUIP_BUILD_EQUIP_NAME_SUFFIX)]),
    %% 计算装备的颜色
    AddTypeId = DataRecord#m_equip_build_build_tos.add_type_id,
    EquipColor = case catch get_equip_color(AddTypeId,AddItem) of
                     {ok,Color} -> Color
                 end,
    ?DEBUG("~ts,EquipColor=~w",["打造装备的颜色",EquipColor]),
    %% 计算装备的品质
    {EquipQuality,EquipSubQuality} = 
        case catch get_equip_quality(EquipColor) of
            {ok, Quality,SubQuality} -> 
                {Quality,SubQuality}
        end,
    ?DEBUG("~ts,EquipQuality=~w,EquipSubQuality=~w",["打造装备的品质",EquipQuality,EquipSubQuality]),
    %% 计算打孔数
    EquipPunchNum = case catch get_equip_punch_num(AddTypeId,AddItem) of
                        {ok,PunchNum} -> PunchNum
                    end,
    ?DEBUG("~ts,EquipPunchNum=~w",["打造装备的打孔数",EquipPunchNum]),
    %% 基础数据
    EquipGoods1 = #p_goods{type = ?TYPE_EQUIP,roleid=RoleId,current_num = 1,state = 0,
                           sell_type = EquipBaseInfo#p_equip_base_info.sell_type,
                           sell_price = EquipBaseInfo#p_equip_base_info.sell_price,
                           typeid = EquipBaseInfo#p_equip_base_info.typeid,
                           name = EquipBaseInfo#p_equip_base_info.equipname,
                           level =(EquipBaseInfo#p_equip_base_info.requirement)#p_use_requirement.min_level, 
                           loadposition = 0,
                           current_endurance = EquipBaseInfo#p_equip_base_info.endurance,
                           add_property=EquipBaseInfo#p_equip_base_info.property,
                           current_colour = EquipColor,
                           punch_num = EquipPunchNum,
                           quality = EquipQuality,
                           sub_quality = EquipSubQuality,
                           endurance = EquipBaseInfo#p_equip_base_info.endurance,
                           reinforce_result_list = [],
                           stones = [],
                           stone_num = 0,
                           equip_bind_attr = [],
                           signature = EquipName,sign_role_id = RoleId},
   %% EquipGoods2 = mod_refining:equip_random_add_property(EquipGoods1), 
        
    EquipGoods3 = mod_refining:equip_colour_quality_add(new,EquipGoods1,1,1,1),
    do_transaction_build_equip2({RoleId,DataRecord,EquipBaseInfo,AddGoodsList,AddItem,AddGoodsNum,Fee},EquipGoods3).

do_transaction_build_equip2({RoleId,DataRecord,_EquipBaseInfo,_AddGoodsList,AddItem,AddGoodsNum,Fee},NewEquipGoods) ->
    case common_transaction:transaction(fun() -> 
                                do_transaction_build_equip3({RoleId,DataRecord,NewEquipGoods,AddItem,AddGoodsNum,Fee}) 
                        end) of
        {atomic,{ok,NewEquip,DelAddGoddsList,UpdateAddGoodsList}} ->
            {ok,NewEquip,DelAddGoddsList,UpdateAddGoodsList};
        {aborted, Reason} ->
            case Reason of 
                {throw,{bag_error,BR}} ->
                    ?DEBUG("~ts,bag_error=~w",["打造装备背操作错误，打造失败",BR]),
                    case BR of
                        {not_enough_pos,_BagID} ->
                            erlang:throw({error,?_LANG_EQUIP_BUILD_BAG_FULL});
                        _ ->
                            erlang:throw({error,?_LANG_EQUIP_BUILD_BUILD_ERROR})
                    end;
                {throw,{error,R}} ->
                    erlang:throw({error,R});
                _ ->
                    ?ERROR_MSG("~ts,Reason=~w",["打造装备生成装备事务过程失败",Reason]),
                    erlang:throw({error,?_LANG_EQUIP_BUILD_BUILD_ERROR})
            end
    end.

do_transaction_build_equip3({RoleId,DataRecord,EquipGoods,AddItem,AddGoodsNum,Fee}) ->
    %% 扣费
    do_transaction_build_equip3_2({RoleId,DataRecord,EquipGoods,AddItem,AddGoodsNum,Fee}),
    %% 更新附加材料
    {ok,NewEquip2,AddEquipBind,DelAddGoodsList,UpdateAddGoodsList} = 
        do_transaction_build_equip3_4({RoleId,DataRecord,EquipGoods,AddItem,AddGoodsNum,Fee}),
    EquipBind = if AddEquipBind -> true; true -> false end,
    %% 产生新装备
    {ok,NewEquip} = do_transaction_build_equip3_1({RoleId,DataRecord,NewEquip2,AddItem,AddGoodsNum,Fee},EquipBind),
    {ok,NewEquip,DelAddGoodsList,UpdateAddGoodsList}.

do_transaction_build_equip3_1({RoleId,_DataRecord,EquipGoods,_AddItem,_AddGoodsNum,_Fee},EquipBind) ->
    ?DEBUG("~ts,RoleId=~w",["打造新装备生成",RoleId]),
    %% 处量装备绑定附加属性
    EquipGoods2 = 
        if EquipBind ->
                case  mod_refining_bind:do_equip_bind_for_equip_build(EquipGoods) of
                    {error,ErrorCode} ->
                        ?ERROR_MSG("~ts,ErrorCode=~w",["打造装备失败，绑定装备出错",ErrorCode]),
                        erlang:throw({error,?_LANG_EQUIP_BUILD_EQUIP_BIND_ERROR});
                    {ok, BindGoods} ->
                        ?DEBUG("~ts,EquipGoods=~w,BindGoods=~w",["打造使用了绑定的材料，执行装备绑定结果",EquipGoods,BindGoods]),
                        BindGoods
                end;
           true ->
                EquipGoods
        end,
    %% 计算装备精炼系数
    EquipGoods3 = 
        case common_misc:do_calculate_equip_refining_index(EquipGoods2) of
            {error,RIErrorCode} ->
                ?DEBUG("~ts,RefiningIndexErrorCode=~w",["计算装备精炼系数出错",RIErrorCode]),
                EquipGoods2;
            {ok, RIGoods} ->
                RIGoods
        end,
    %% 占用那一个背包和格子
    {ok,[EquipGoods5]}= mod_bag:create_goods_by_p_goods(RoleId,EquipGoods3),
    {ok,EquipGoods5}.
%% 扣费
do_transaction_build_equip3_2({RoleId,_DataRecord,_EquipGoods,_AddItem,_AddGoodsNum,Fee}) ->
    EquipConsume = #r_equip_consume{type = build,
                                 consume_type = ?CONSUME_TYPE_SILVER_EQUIP_BUILD,
                                 consume_desc = ""},
    mod_refining:do_refining_deduct_fee(RoleId,Fee,EquipConsume).

%% 更新附加材料
do_transaction_build_equip3_4({RoleId,DataRecord,EquipGoods,AddItem,AddGoodsNum,Fee}) ->
    #r_equip_build_item{item_id=AddTypeId} = AddItem,
    ?DEBUG("~ts,ItemId=~w",["消耗打造的附加材料",AddTypeId]),
    if AddTypeId =/= 0 ->
            BagIdList = get_equip_build_bag_id(),
            AddGoodsList = 
                case mod_refining_bag:get_goods_by_bag_ids_and_type_id(RoleId,BagIdList,AddTypeId) of
                    [] ->
                        ?ERROR_MSG("~ts",["查询角色背包的打造附加材料时出错"]),
                        erlang:throw({error,?_LANG_EQUIP_BUILD_GOODS_ENOUGH});
                    List ->
                        List
                end,
            do_transaction_build_equip3_4_2({RoleId,DataRecord,EquipGoods,AddItem,AddGoodsNum,Fee,AddGoodsList});
       true ->
            ?DEBUG("~ts",["角色打造时没有使用附加材料"]),
            {ok, EquipGoods, false, [],[]}
    end.
do_transaction_build_equip3_4_2({RoleId,_DataRecord,EquipGoods,AddItem,AddGoodsNum,_Fee,AddGoodsList}) ->
    #r_equip_build_item{item_id=AddTypeId} = AddItem,
    case AddGoodsList of
        [] ->
            ?ERROR_MSG("~ts,ItemId=~w",["角色没有打造所需要的附加材料",AddTypeId]),
            erlang:throw({error,?_LANG_EQUIP_BUILD_GOODS_ENOUGH});
        _ ->
            GoodsSum = get_goods_sum(AddGoodsList,0),
            EquipBind = is_use_bind_goods(AddGoodsList),
            NewAddNum = GoodsSum - AddGoodsNum,
            if  NewAddNum =:= 0 ->
                    %%此物品已经没有，必须删除
                    DelAddGoodsIds = [GoodsRecord#p_goods.id || GoodsRecord <- AddGoodsList],
                    mod_bag:delete_goods(RoleId,DelAddGoodsIds),
                    {ok, EquipGoods, EquipBind, AddGoodsList,[]};
                NewAddNum > 0 ->
                    %%更新物品信息
                    {ok,DelList,UpdateList} = do_transaction_dedcut_goods(RoleId,AddGoodsList,AddGoodsNum),
                    {ok, EquipGoods, EquipBind, DelList,UpdateList};
                true ->
                    ?ERROR_MSG("~ts,ItemId=~w",["角色打造所需要的附加材料数量不够",AddTypeId]),
                    erlang:throw({error,?_LANG_EQUIP_BUILD_GOODS_ENOUGH})
            end
    end.
       
%% 消耗打造材料
do_transaction_dedcut_goods(RoleId,GoodsList,GoodsNum) ->
    ?DEBUG("~ts",["处理材料消耗"]),
    {BindList,NotBindList} = lists:partition(fun(GoodsRecord) ->
                                                     GoodsRecord#p_goods.bind =:= true
                                             end, GoodsList),
    BindSum = get_goods_sum(BindList,0),
    NotBindSum = get_goods_sum(NotBindList,0),
    ?DEBUG("~ts,BindSum=~w,NotBindSum=~w",["绑定材料和不绑定材料的总数",BindSum,NotBindSum]),
    if BindSum > 0 ->
            do_transaction_dedcut_goods2(RoleId,GoodsList,GoodsNum,{BindList,NotBindList,BindSum,NotBindSum});
       true ->
            do_transaction_dedcut_goods5(RoleId,GoodsList,GoodsNum,{BindList,NotBindList,BindSum,NotBindSum})
    end.

do_transaction_dedcut_goods2(RoleId,GoodsList,GoodsNum,{BindList,NotBindList,BindSum,NotBindSum}) ->
    NewNum = BindSum - GoodsNum,
    if NewNum =:= 0 ->
            DeleteGoodsIds = [R#p_goods.id || R <- BindList],
            mod_bag:delete_goods(RoleId,DeleteGoodsIds),
            {ok,BindList,[]};
       true ->
            do_transaction_dedcut_goods3(RoleId,GoodsList,GoodsNum,{BindList,NotBindList,BindSum,NotBindSum})
    end.

do_transaction_dedcut_goods3(RoleId,GoodsList,GoodsNum,{BindList,NotBindList,BindSum,NotBindSum}) ->
    NewNum = BindSum - GoodsNum,
    if NewNum > 0 ->
            NewBindList = lists:sort(fun(R1,R2) -> R1#p_goods.current_num > R2#p_goods.current_num end, BindList),
            {0,DelList,UpdateList} = deduct_goods(NewBindList,GoodsNum,[],[]),
            DeleteGoodsIds = 
                lists:foldl(
                  fun(DR,AccList) -> 
                          case lists:keyfind(DR#p_goods.id,#p_goods.id,UpdateList) of
                              false ->
                                  [DR#p_goods.id|AccList];
                              _ ->
                                  ?DEBUG("~ts,P_Goods_ID = ~w",["由更新操作处理",DR#p_goods.id]),
                                  AccList
                          end
                  end,[],DelList),
            mod_bag:delete_goods(RoleId,DeleteGoodsIds),
            mod_bag:update_goods(RoleId,UpdateList),
            {ok,DelList,UpdateList};
        true ->
            do_transaction_dedcut_goods4(RoleId,GoodsList,GoodsNum,{BindList,NotBindList,BindSum,NotBindSum})
    end.

do_transaction_dedcut_goods4(RoleId,_GoodsList,GoodsNum,{BindList,NotBindList,_BindSum,_NotBindSum}) ->
    NewBindList = lists:sort(fun(R1,R2) -> R1#p_goods.current_num > R2#p_goods.current_num end, BindList),
    {NewNum,DelList,UpdateList} = deduct_goods(NewBindList,GoodsNum,[],[]),
    ?DEBUG("~ts,NewNum=~w,DelList=~w,UpdateList=~w",["删除绑定的基础材料",NewNum,DelList,UpdateList]),
    NewNotBindList = lists:sort(fun(R3,R4) -> R3#p_goods.current_num > R4#p_goods.current_num end, NotBindList),
    case deduct_goods(NewNotBindList,NewNum,[],[]) of
        {0,DelList2,UpdateList2} ->
            ?DEBUG("~ts,DelList2=~w,UpdateList2=~w",["删除不绑定的基础材料",DelList2,UpdateList2]),
            NewDelList = lists:append([DelList, DelList2]),
            NewUpdateList = lists:append([UpdateList , UpdateList2]),
            DeleteGoodsIds = 
                lists:foldl(
                  fun(DR,AccList) -> 
                          case lists:keyfind(DR#p_goods.id,#p_goods.id,NewUpdateList) of
                              false ->
                                  [DR#p_goods.id|AccList];
                              _ ->
                                  ?DEBUG("~ts,P_Goods_ID = ~w",["由更新操作处理",DR#p_goods.id]),
                                  AccList
                          end
                  end,[],NewDelList),
            mod_bag:delete_goods(RoleId,DeleteGoodsIds),
            mod_bag:update_goods(RoleId,NewUpdateList),
            {ok,NewDelList,NewUpdateList};
        Error ->
            ?ERROR_MSG("~ts,Error=~w",["材料不够",Error]),
            erlang:throw({error,?_LANG_EQUIP_BUILD_GOODS_ENOUGH})
    end.

    
do_transaction_dedcut_goods5(RoleId,GoodsList,GoodsNum,{BindList,NotBindList,BindSum,NotBindSum}) ->
    NewNum = NotBindSum - GoodsNum,
    if NewNum =:= 0 ->
            DeleteGoodsIds = [R#p_goods.id || R <- NotBindList],
            mod_bag:delete_goods(RoleId,DeleteGoodsIds),
            {ok,NotBindList,[]};
       true ->
            do_transaction_dedcut_goods6(RoleId,GoodsList,GoodsNum,{BindList,NotBindList,BindSum,NotBindSum})
    end.
do_transaction_dedcut_goods6(RoleId,_GoodsList,GoodsNum,{_BindList,NotBindList,_BindSum,NotBindSum}) ->
    NewNum = NotBindSum - GoodsNum,
    if NewNum > 0 ->
            NewNotBindList = lists:sort(fun(R1,R2) -> R1#p_goods.current_num > R2#p_goods.current_num end, NotBindList),
            {0,DelList,UpdateList} = deduct_goods(NewNotBindList,GoodsNum,[],[]),
            DeleteGoodsIds = 
                lists:foldl(
                  fun(DR,AccList) -> 
                          case lists:keyfind(DR#p_goods.id,#p_goods.id,UpdateList) of
                              false ->
                                  [DR#p_goods.id | AccList];
                              _ ->
                                  ?DEBUG("~ts,P_Goods_ID = ~w",["由更新操作处理",DR#p_goods.id]),
                                  AccList
                          end
                  end,[],DelList),
            mod_bag:delete_goods(RoleId,DeleteGoodsIds),
            mod_bag:update_goods(RoleId,UpdateList),
            {ok,DelList,UpdateList};
        true ->
            ?ERROR_MSG("~ts",["材料不够"]),
            erlang:throw({error,?_LANG_EQUIP_BUILD_GOODS_ENOUGH})
    end.

%% 从多个材料物品扣费，先扣最多数量的
deduct_goods([],GoodsNum,DelList,UpdateList) ->
    {GoodsNum,DelList,UpdateList};
deduct_goods([H|T],GoodsNum,DelList,UpdateList) ->
    NewNum = H#p_goods.current_num - GoodsNum,
    if NewNum > 0 ->
            NewH = H#p_goods{current_num = NewNum},
            DelH = H#p_goods{current_num = GoodsNum},
            NewDelList = lists:append(DelList,[DelH]),
            NewUpdateList = lists:append(UpdateList,[NewH]),
            deduct_goods([],0,NewDelList,NewUpdateList);
       NewNum =:= 0 ->
            NewDelList2 = lists:append(DelList,[H]),
            deduct_goods([],0,NewDelList2,UpdateList);
       true ->
            NewDelList3 = lists:append(DelList,[H]),
            NewGoodsNum = GoodsNum -  H#p_goods.current_num,
            deduct_goods(T,NewGoodsNum,NewDelList3,UpdateList)
    end.

%% 获取同类打造材料的总数
get_goods_sum([],Sum) -> Sum;
get_goods_sum([H|T],Sum) ->
    NewSum = Sum + H#p_goods.current_num,
    get_goods_sum(T,NewSum).
    

%% 判断使用的材料中是否有绑定的材料
is_use_bind_goods(GoodsList) ->
    {BindList,_} = lists:partition(fun(GoodsRecord) ->
                                           GoodsRecord#p_goods.bind =:= true
                                   end, GoodsList),
    BindSum = get_goods_sum(BindList,0),
    if BindSum =:= 0  ->
            false;
       true ->
            true
    end.
                         
%% 计算装备的颜色
get_equip_color(AddTypeId,AddItem) ->
    Level = if AddTypeId =:= 0 ->
                    0;
               true ->
                    AddItem#r_equip_build_item.level            
            end,
    [ColorRecord] = 
        case common_config_dyn:find(equip_build,equip_build_equip_color) of
            [ ColorList ] ->
                [R || R <- ColorList, 
                      R#r_equip_build_equip_color.add_goods_level =:= Level];
            _ ->
                erlang:throw({ok,?COLOUR_WHITE})
        end,
    #r_equip_build_equip_color{white = White,green = Green,blue = Blue,
                               purple = Purple,orange = Orange,gold = Gold} = ColorRecord,
    SumNumber = White + Green + Blue + Purple + Orange + Gold,
    RandomNumber = random:uniform(SumNumber),
    if White > 0 andalso RandomNumber =< White ->
            erlang:throw({ok,?COLOUR_WHITE});
       Green > 0 andalso RandomNumber >= (White + 1) 
       andalso RandomNumber =< (White + Green) ->
            erlang:throw({ok,?COLOUR_GREEN});
       Blue > 0 andalso RandomNumber >= (White + Green + 1) 
       andalso RandomNumber =< (White + Green + Blue) ->
            erlang:throw({ok,?COLOUR_BLUE});
       Purple > 0 andalso RandomNumber >= (White + Green + Blue + 1) 
       andalso RandomNumber =< (White + Green + Blue + Purple) ->
            erlang:throw({ok,?COLOUR_PURPLE});
       Orange > 0 andalso RandomNumber >= (White + Green + Blue + Purple + 1) 
       andalso RandomNumber =< (White + Green + Blue + Purple + Orange) ->
            erlang:throw({ok,?COLOUR_ORANGE});
       Gold > 0 andalso RandomNumber >= (White + Green + Blue + Purple + Orange + 1) 
       andalso RandomNumber =< (White + Green + Blue + Purple + Orange + Gold) ->
            erlang:throw({ok,?COLOUR_GOLD});
       true ->
            erlang:throw({ok,?COLOUR_WHITE})
    end.
%% 计算装备的品质和子品质
get_equip_quality(EquipColor) ->
    [QualityRecord] = 
        case common_config_dyn:find(equip_build,equip_build_equip_quality) of
            [ QualityList ] ->
                [R || R <- QualityList, 
                      R#r_equip_build_equip_quality.equip_color =:= EquipColor];
            _ ->
                erlang:throw({ok,?QUALITY_GENERAL,1})
        end,
    [MaxSubQuality] = common_config_dyn:find(refining,equip_change_quality_sub_max_level),
    #r_equip_build_equip_quality{weight = WeightList} = QualityRecord,
    SumQuality = mod_refining:get_random_number(WeightList,0,1),
    Quality = common_tool:ceil(SumQuality / MaxSubQuality),
    SubQuality = 
        case SumQuality rem MaxSubQuality of
            0 ->
                MaxSubQuality;
            SubQualityT ->
                SubQualityT
        end,
    erlang:throw({ok,Quality,SubQuality}).

%% 计算装备的随机打孔数
get_equip_punch_num(AddTypeId,AddItem) ->
    Level = if AddTypeId =:= 0 ->
                    0;
               true -> 
                    AddItem#r_equip_build_item.level         
            end,
    [PunchNumRecord] = 
        case common_config_dyn:find(equip_build,equip_build_equip_punch_num) of
            [ PunchNumList ] ->
                [R || R <- PunchNumList, 
                      R#r_equip_build_equip_punch_num.add_goods_level =:= Level];
            _ ->
                erlang:throw({ok,0})
        end,
    #r_equip_build_equip_punch_num{num_0 = Num0,num_1 = Num1,num_2 = Num2,num_3 = Num3,
                                   num_4 = Num4,num_5 = Num5,num_6 = Num6} = PunchNumRecord,
    SumNumber = Num0 + Num1 + Num2 + Num3 + Num4 + Num5 + Num6,
    RandomNumber = random:uniform(SumNumber),
    if Num0 > 0 andalso RandomNumber =< Num0 ->
            erlang:throw({ok,0});
       Num1 > 0 andalso RandomNumber >= (Num0 + 1)  
       andalso RandomNumber =< (Num0 + Num1) ->
            erlang:throw({ok,1});
       Num2 > 0 andalso RandomNumber >= (Num0 + Num1 + 1)  
       andalso RandomNumber =< (Num0 + Num1 + Num2) ->
            erlang:throw({ok,2});
       Num3 > 0 andalso RandomNumber >= (Num0 + Num1 + Num2 + 1)  
       andalso RandomNumber =< (Num0 + Num1 + Num2 + Num3) ->
            erlang:throw({ok,3});
       Num4 > 0 andalso RandomNumber >= (Num0 + Num1 + Num2 + Num3 + 1)  
       andalso RandomNumber =< (Num0 + Num1 + Num2 + Num3 + Num4) ->
            erlang:throw({ok,4});
       Num5 > 0 andalso RandomNumber >= (Num0 + Num1 + Num2 + Num3 + Num4 + 1)  
       andalso RandomNumber =< (Num0 + Num1 + Num2 + Num3 + Num4 + Num5) ->
            erlang:throw({ok,5});
       Num6 > 0 andalso RandomNumber >= (Num0 + Num1 + Num2 + Num3 + Num4 + Num5 + 1)  
       andalso RandomNumber =< (Num0 + Num1 + Num2 + Num3 + Num4 + Num5 + Num6) ->
            erlang:throw({ok,6});
       true ->
            erlang:throw({ok,0})
    end.
    
%% 获取当前角色背包的打造材料，分类获取，即所有的基础材料，和所有的附加材料
get_dirty_equip_build_goods_list(Type,RoleId) ->
    %% type 1道具 ，2 宝石 ， 3 装备
    TypeIdList = get_equip_build_goods_list(Type),
    BagIdList = get_equip_build_bag_id(),
    ItemIds = [R#r_equip_build_item.item_id || R <- TypeIdList],
    mod_refining_bag:get_goods_by_bag_ids_and_type_ids(RoleId,BagIdList,ItemIds).

%% 根据物品类型ID查询物品记录
get_dirty_equip_build_goods(RoleId,TypeId) ->
    BagIds = get_equip_build_bag_id(),
    case mod_refining_bag:get_goods_by_bag_ids_and_type_id(RoleId,BagIds,TypeId) of
        [] ->
            {error, not_found};
        BuildGoodList ->
            {ok, BuildGoodList}
    end.

%% 获取可打造的装备，根据装备级别范围查询装备配置表中的符合条件的数据
%% 及装备的材质不为0, material =/= 0
get_equip_build_equip_list(BuildRecord) ->
    #r_equip_build{equip_list = EquipList} = BuildRecord,
    BaseInfoList = 
        lists:foldl(
          fun(TypeId,Acc) ->
                  [BaseInfo] = common_config_dyn:find_equip(TypeId),
                  case (BaseInfo#p_equip_base_info.material =/= 0) of
                      true ->
                          [BaseInfo|Acc];
                      _ ->
                          Acc
                  end
          end,[],EquipList),
    lists:reverse(BaseInfoList).
%% 根据道具Id查询角色要打造的装备信息
get_equip_build_equip(TypeId, MinLevel, MaxLevel) ->
    case common_config_dyn:find_equip(TypeId) of
        [BaseInfo] ->
            case (BaseInfo#p_equip_base_info.material =/= 0 
                  andalso (BaseInfo#p_equip_base_info.requirement)#p_use_requirement.min_level >= MinLevel
                  andalso MaxLevel >= (BaseInfo#p_equip_base_info.requirement)#p_use_requirement.min_level) of
                true ->
                    BaseInfo;
                false ->
                    undefined
            end;
        _ ->
            undefined
    end.
           
%% 判断打造级别是否正确
get_equip_build_level_record(BuildLevel) ->
    case common_config_dyn:find(equip_build,equip_build_config) of
        [ ConfigList ] -> 
            case lists:keyfind(BuildLevel,2,ConfigList) of
                false ->
                    {error,not_found};
                Record when erlang:is_record(Record,r_equip_build) ->
                    {ok,Record};
                _ ->
                    {error,record_error}
            end;
        _ -> 
            {error,not_config}
    end.
%% 获取可使用的背包id
get_equip_build_bag_id() ->
    case common_config_dyn:find(equip_build,equip_build_bag_id) of
        [ BagIdList ] ->
            BagIdList;
        _ ->
            ?DEFAULT_EQUIP_BUILD_BAG_ID
    end.

%% 获取所有打造的材料记录,材料类型，1：基础材料，2：附加材料
get_equip_build_goods_list(Type) ->
    case common_config_dyn:find(equip_build,equip_build_material) of
        [ MaterialList ] ->
            [R || R <- MaterialList, R#r_equip_build_item.type =:= Type];
        _ ->
            []
    end.

%% 根据材质，材料类型，1：基础材料，2：附加材料，材料及别获取打造需要的材料记录
get_equip_build_goods(Material,Type,BaseGoodsLevel) ->
    case common_config_dyn:find(equip_build,equip_build_material) of
        [ MaterialList ] ->
            [R || R <- MaterialList, 
                  R#r_equip_build_item.type =:= Type,
                  R#r_equip_build_item.material =:= Material,
                  R#r_equip_build_item.level =:= BaseGoodsLevel];
        _ ->
            []
    end.
%% 获取某一类材质的记录
get_equip_build_class_goods(Material,Type) ->
    case common_config_dyn:find(equip_build,equip_build_material) of
        [ MaterialList ] ->
            [R || R <- MaterialList, 
                  R#r_equip_build_item.type =:= Type,
                  R#r_equip_build_item.material =:= Material];
        _ ->
            []
    end.
%% 根据道具ID，查询打造材料记录
get_equip_build_record(ItemId) ->
    case common_config_dyn:find(equip_build,equip_build_material) of
        [ MaterialList ] ->
            [R || R <- MaterialList, 
                  R#r_equip_build_item.item_id =:= ItemId];
        _ ->
            []
    end.

%% 将角色所有打造材料统计返回，即将同一材料的多组数量统计，使用统一的结构返回
%% 结构为p_equip_build_goods
count_class_equip_build_goods([],Result) -> Result;
count_class_equip_build_goods([H|T],Result) ->
    TypeId = H#p_goods.typeid,
    case lists:keyfind(TypeId, #p_equip_build_goods.type_id, Result) of
        false ->
            R = #p_equip_build_goods{type_id =H#p_goods.typeid,name =H#p_goods.name,
                                        current_num =H#p_goods.current_num},
            count_class_equip_build_goods(T, lists:append([Result,[R]]));
        Record ->
            ResultList = lists:delete(Record, Result),
            NewNum = Record#p_equip_build_goods.current_num + H#p_goods.current_num,
            NewR = Record#p_equip_build_goods{current_num = NewNum},
            count_class_equip_build_goods(T, lists:append([ResultList,[NewR]]))
    end.

%% 获取装备材质字典        
get_equip_build_material_dict() ->   
    case common_config_dyn:find(equip_build,equip_build_material_dict) of
        [ MaterialDictList ] ->
            MaterialDictList;
        _ ->
            ?DEFAULT_EQUIP_BUILD_MATERIAL_DICT
    end.
    
    
