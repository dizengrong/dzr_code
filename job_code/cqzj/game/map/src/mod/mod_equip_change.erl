%%%-------------------------------------------------------------------
%%% @author  caochuncheng
%%% @copyright mcsd (C) 2010, 
%%% @doc
%%% 装备改造
%%% 装备品质改造，更改签名，装备升级，装备分解
%%% @end
%%% Created : 16 Aug 2010 by  <>
%%%-------------------------------------------------------------------
-module(mod_equip_change).

%% Include files
-include("mgeem.hrl").
-include("equip_build.hrl").
-include("refining.hrl").
%% API
-export([do_transaction_consume_goods/4,do_check_matrail_bind/1]).

-export([
         do_equip_quality_goods/1,
         do_equip_quality/1,
         do_equip_signature/1,
         do_equip_upgrade_link/1,
         do_equip_upgrade_goods/1,
         do_equip_upgrade/1,
         do_equip_decompose/1,
         equip_reinforce_property_add/2,
         equip_stone_property_add/1
        ]).

%% 品质材料
do_equip_quality_goods({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) ->
    Material =  DataRecord#m_equip_build_quality_goods_tos.material,
    MaterialList = mod_equip_build:get_equip_build_material_dict(),
    NewMaterialList = lists:append([MaterialList,[0]]),
    case lists:member(Material, NewMaterialList) of 
        false ->
            ?DEBUG("~ts,Material=~w",["材质参数不合法",Material]),
            R = ?_LANG_EQUIP_CHANGE_Q_PARAM_ERROR,
            do_equip_quality_goods_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},R);
        true ->
            do_equip_quality_goods2({Unique,Module,Method,DataRecord, RoleId, Pid, Line})
    end.

do_equip_quality_goods2({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) ->
    Material = DataRecord#m_equip_build_quality_goods_tos.material,
    if Material =:= 0 ->
            do_equip_quality_goods3({Unique,Module,Method,DataRecord, RoleId, Pid, Line});
       true ->
            do_equip_quality_goods4({Unique,Module,Method,DataRecord, RoleId, Pid, Line})
    end.
do_equip_quality_goods3({Unique,Module,Method,DataRecord, RoleId, _Pid, Line}) ->
    Material = DataRecord#m_equip_build_quality_goods_tos.material,
    AddList = mod_equip_build:get_dirty_equip_build_goods_list(?EQUIP_BUILD_PINZHI,RoleId),
    NewAddList = mod_equip_build:count_class_equip_build_goods(AddList,[]),
    SendSelf=#m_equip_build_quality_goods_toc{succ = true, material= Material,add_list = NewAddList},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).

do_equip_quality_goods4({Unique,Module,Method,DataRecord, RoleId, _Pid, Line}) ->
    Material = DataRecord#m_equip_build_quality_goods_tos.material,
    AddList = mod_equip_build:get_dirty_equip_build_goods_list(?EQUIP_BUILD_PINZHI,RoleId),
    NewAddList = mod_equip_build:count_class_equip_build_goods(AddList,[]),
    AddMaterial = mod_equip_build:get_equip_build_class_goods(Material,?EQUIP_BUILD_PINZHI),
    NewAddList2 = lists:filter(fun(AR) ->
                                        case lists:keyfind(AR#p_equip_build_goods.type_id,
                                                           #r_equip_build_item.item_id, AddMaterial) of
                                            false -> false;
                                            _ -> true
                                        end 
                               end,NewAddList),
    SendSelf=#m_equip_build_quality_goods_toc{succ = true, material= Material,add_list = NewAddList2},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).

do_equip_quality_goods_error({Unique,Module,Method,DataRecord, RoleId, _Pid, Line},Reason) ->
    Material =  DataRecord#m_equip_build_quality_goods_tos.material,
    SendSelf=#m_equip_build_quality_goods_toc{succ = false, reason=Reason, material= Material},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).
%% 品质改造
do_equip_quality({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) ->
    case catch do_equip_quality2({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) of 
        {error,Error} ->
            ?DEBUG("~ts,Error=~w",["装备品质改造验证出错",Error]),
            do_equip_quality_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error);
        {ok, EquipGoods,AddItemRecord} ->
            do_equip_quality3({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                             EquipGoods,AddItemRecord)
    end.
do_equip_quality2({_Unique,_Module,_Method,DataRecord, RoleId, _Pid, _Line}) ->
    EquipId = DataRecord#m_equip_build_quality_tos.equip_id,
    AddTypeId = DataRecord#m_equip_build_quality_tos.add_type_id,
    EquipGoods = 
        case get_dirty_goods_by_id(RoleId,EquipId) of
            {error, E} ->
                ?DEBUG("~ts,Error=~w",["查询需要改造品质装备信息出错",E]),
                erlang:throw({error,?_LANG_EQUIP_CHANGE_Q_PARAM_EQUIP});
            {ok, EGoods} ->
                EGoods
        end,
    TypeId = EquipGoods#p_goods.typeid,
    EquipInfo = 
        case common_config_dyn:find_equip(TypeId) of
            [] ->
                ?DEBUG("~ts",["查询不到装备的基本信息"]),
                erlang:throw({error,?_LANG_EQUIP_CHANGE_Q_PARAM_EQUIP});
            [EInfo] ->
                EInfo
        end,
    if EquipInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
            erlang:throw({error,?_LANG_EQUIP_CHANGE_Q_MOUNT_ERROR});
       EquipInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
            erlang:throw({error,?_LANG_EQUIP_CHANGE_Q_FASHION_ERROR});
       EquipInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
            erlang:throw({error,?_LANG_EQUIP_CHANGE_Q_ADORN_ERROR});
       true ->
            next
    end,
    [SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
    case lists:member(EquipGoods#p_goods.typeid,SpecialEquipList) of
        true ->
            erlang:throw({error,?_LANG_EQUIP_CHANGE_Q_ADORN_ERROR});
        _ ->
            next
    end,
    [MaxSubQuality] = common_config_dyn:find(refining,equip_change_quality_sub_max_level),
    if EquipGoods#p_goods.quality =:= ?QUALITY_PERFECT 
       andalso EquipGoods#p_goods.sub_quality =:= MaxSubQuality ->
            ?DEBUG("~ts,EquipQuality=~w",["装备品质等级已经最高级，不需要改造",EquipGoods#p_goods.quality]),
            erlang:throw({error,?_LANG_EQUIP_CHANGE_Q_FULL});
       true ->
            next
    end,
    
    if AddTypeId =:= 0 ->
            ?DEBUG("~ts,AddTypeId=~w",["附加材料不合法",AddTypeId]),
            erlang:throw({error,?_LANG_EQUIP_CHANGE_Q_PARAM_GOODS});
       true ->
            next
    end,
    Material = EquipInfo#p_equip_base_info.material,
    AddItemRecord = 
        case mod_equip_build:get_equip_build_class_goods(Material,?EQUIP_BUILD_PINZHI) of
            [] ->
                ?DEBUG("~ts,Material=~w",["根据装备的材质询不到可用的附加材料",Material]),
                erlang:throw({error,?_LANG_EQUIP_CHANGE_Q_PARAM_EQUIP});
            TypeIdList ->
                case lists:keyfind(AddTypeId,#r_equip_build_item.item_id,TypeIdList) of
                    false ->
                        ?DEBUG("~ts,Material=~w,AddTypeId=~w",["附加材料跟装备所需的附加材料不合法",Material,AddTypeId]),
                        erlang:throw({error,?_LANG_EQUIP_CHANGE_Q_PARAM_GOODS});
                    R ->
                        R
                end
        end,
    AddGoodsLevel = AddItemRecord#r_equip_build_item.level,
    {MaxQuality2,MaxSubQuality2} = get_equip_change_max_quality(AddGoodsLevel),
    if EquipGoods#p_goods.quality >= MaxQuality2 
       andalso EquipGoods#p_goods.sub_quality >= MaxSubQuality2 ->
            ?DEBUG("~ts,MaxQuality=~w,EquipQuality=~w",["附加材料级别不合法",MaxQuality2,EquipGoods#p_goods.quality]),
            erlang:throw({error,?_LANG_EQUIP_CHANGE_Q_NOT_UPDATE});
       true ->
            next
    end,
    [QualityRecord] = get_equip_change_quality_record(AddGoodsLevel),
    {ok,EquipGoods,QualityRecord}.

do_equip_quality3({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods,AddItemRecord) ->
    AddItemLevel = AddItemRecord#r_equip_build_change_quality.item_level,
    AddItemNum = AddItemRecord#r_equip_build_change_quality.item_num,
	case catch mod_refining:get_refining_fee(equip_quality_fee, EquipGoods, AddItemLevel, AddItemNum) of
		{error,Error,0} ->
			?DEBUG("~ts,Error=~w",["计算装备品质改造费用时出错",Error]),
            do_equip_quality_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error);
		Fee ->
			do_equip_quality4({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                             EquipGoods,AddItemRecord,Fee)
	end.
do_equip_quality4({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods,AddItemRecord,Fee) ->
    AddItemLevel = AddItemRecord#r_equip_build_change_quality.item_level,
    {NewQuality,NewSubQuality} = get_equip_change_quality(AddItemLevel),
    %% 装备品质级别不降低 3,优质
    ProtectLevel = get_equip_change_quality_protect_level(),
    EquipQuality = EquipGoods#p_goods.quality,
    NewQuality2 = 
        if EquipQuality >= ProtectLevel 
           andalso NewQuality >= ProtectLevel ->
                NewQuality;
           EquipQuality >= ProtectLevel
           andalso NewQuality < ProtectLevel ->
                ProtectLevel;
           true ->
                NewQuality
        end,
    ?DEBUG("~ts,EquipQuality=~w,ProtectLevel=~w,NewQuality=~w,NewQuality2=~w",["计算最新品质数据",EquipQuality,ProtectLevel,NewQuality,NewQuality2]),
    do_equip_quality5({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                      EquipGoods,AddItemRecord,NewQuality2,NewSubQuality,Fee).

do_equip_quality5({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                             EquipGoods,AddItemRecord,NewQuality,NewSubQuality,Fee) ->
    case catch do_transaction_equip_change_quality(RoleId,DataRecord,EquipGoods,
                                                   AddItemRecord,NewQuality,NewSubQuality,Fee) of
        {error,Error} ->
            ?DEBUG("~ts,Error=~w",["计算装备品质改造执行事务操作",Error]),
            do_equip_quality_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error),
            do_equip_chang_deduct_fee_notify(RoleId, Line);
        {ok, Reason,NewEquip,DelAddGoddsList,UpdateAddGoodsList} ->
            do_equip_quality6({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Reason,
                              NewEquip,DelAddGoddsList,UpdateAddGoodsList)
    end.
%% 改造成功通知处理
do_equip_quality6({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Reason,
                              NewEquip,DelAddGoddsList,UpdateAddGoodsList) ->
    [AddGoods] =  mod_equip_build:count_class_equip_build_goods(DelAddGoddsList,[]),
    AddList = mod_equip_build:get_dirty_equip_build_goods_list(?EQUIP_BUILD_PINZHI,RoleId),
    NewAddList = mod_equip_build:count_class_equip_build_goods(AddList,[]),
    SendSelf = #m_equip_build_quality_toc{succ = true,
                                          reason = Reason,
                                          equip = NewEquip,
                                          add_list = NewAddList,
                                          add_goods = AddGoods},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf),
    do_equip_quality7({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                              NewEquip,DelAddGoddsList,UpdateAddGoodsList).
%% 通知背包材料更新
do_equip_quality7({_Unique,_Module,_Method,_DataRecord, RoleId, _Pid, Line},
                              _NewEquip,DelAddGoddsList,UpdateAddGoodsList) ->
    %% 基础材料
    NotifyBaseList = lists:filter(fun(R) -> 
                                          case lists:keyfind(R#p_goods.id,#p_goods.id,UpdateAddGoodsList) of
                                              false -> true;
                                              _ -> false
                                          end
                                  end,DelAddGoddsList),
    if NotifyBaseList =/= [] ->
            ?DEBUG("~ts",["扣除品质改造基础材料通知"]),
            common_misc:del_goods_notify({line, Line, RoleId}, NotifyBaseList);
       true ->
            ignore
    end,
    if UpdateAddGoodsList =/= [] ->
            common_misc:update_goods_notify({line, Line, RoleId},UpdateAddGoodsList);
       true ->
            next
    end,
    %% 道具消费日志
    [UseGoods] = mod_equip_build:count_class_equip_build_goods(DelAddGoddsList,[]),
    catch common_item_logger:log(RoleId,UseGoods#p_equip_build_goods.type_id, 
                                        UseGoods#p_equip_build_goods.current_num,
                                 undefined,?LOG_ITEM_TYPE_TI_SHENG_PIN_ZHI_SHI_QU),
    %% 通知钱变化
    do_equip_chang_deduct_fee_notify(RoleId, Line).
%% 装备品质改造事务操作
do_transaction_equip_change_quality(RoleId,DataRecord,EquipGoods ,AddItemRecord,NewQuality,NewSubQuality,Fee) ->
     case common_transaction:transaction(fun() -> 
                                   do_transaction_equip_change_quality2(
                                     RoleId,DataRecord,EquipGoods,
                                     AddItemRecord,NewQuality,NewSubQuality,Fee)
                            end) of
        {atomic,{ok,R,NewEquip,DelAddGoddsList,UpdateAddGoodsList}} ->
            {ok,R,NewEquip,DelAddGoddsList,UpdateAddGoodsList};
        {aborted, Reason} ->
            case Reason of 
                {throw,{error,R}} ->
                    erlang:throw({error,R});
                _ ->
                    ?DEBUG("~ts,Reason=~w",["装备品质改造失败",Reason]),
                    erlang:throw({error,?_LANG_EQUIP_CHANGE_Q_EXCEPTION})
            end
    end.
do_transaction_equip_change_quality2(RoleId,DataRecord,EquipGoods,AddItemRecord,NewQuality,NewSubQuality,Fee) ->
    %% 扣费
    EquipConsume = #r_equip_consume{type = quality,
                                    consume_type = ?CONSUME_TYPE_SILVER_EQUIP_QUALITY,
                                    consume_desc = ""},
    mod_refining:do_refining_deduct_fee(RoleId,Fee,EquipConsume),
    %% 扣除材料
    TypeId = DataRecord#m_equip_build_quality_tos.add_type_id,
    ItemNum = AddItemRecord#r_equip_build_change_quality.item_num,
    BagIdList = mod_equip_build:get_equip_build_bag_id(),
    case do_transaction_consume_goods(RoleId,BagIdList,TypeId,ItemNum) of
        {error,Error} ->
            ?DEBUG("~ts,Error=~w",["扣除材料出错",Error]),
            erlang:throw({error,Error});
        {ok,DelGoodsList,UpdateGoodsList} ->
            do_transaction_equip_change_quality3(RoleId,EquipGoods,NewQuality,NewSubQuality,DelGoodsList,UpdateGoodsList)
    end.
do_transaction_equip_change_quality3(RoleId,EquipGoods,NewQuality,NewSubQuality,DelGoodsList,UpdateGoodsList) ->
    MatrailBind1 = do_check_matrail_bind(DelGoodsList),
    MatrailBind2 = do_check_matrail_bind(UpdateGoodsList),
    MatrailBind =
        if MatrailBind1 orelse MatrailBind2 ->
                true;
           true ->
                false
        end,
    %% 生成新品质装备
    BagIds = mod_equip_build:get_equip_build_bag_id(),
    NewEquip = 
        case mod_refining_bag:get_goods_by_bag_ids_and_goods_id(RoleId,BagIds,EquipGoods#p_goods.id) of
            {ok,Equip} ->
                Equip;
            {error,Error} ->
                ?DEBUG("~ts,Error=~w",["获取装备信息出错",Error]),
                EquipGoods
        end,
    NewEquip2 = mod_refining:equip_colour_quality_add(mod,NewEquip,NewEquip#p_goods.current_colour,NewQuality,NewSubQuality),
    NewEquip3 = 
    if MatrailBind ->
            case mod_refining_bind:do_equip_bind_for_quality(NewEquip2) of
                {error,ErrorCode} ->
                    ?INFO_MSG("~ts,ErrorCode=~w",["装备品质改造时，当材料是绑定的，装备是不绑定时，处理绑定出错，只是做绑定处理，没有附加属性",ErrorCode]),
                    NewEquip2#p_goods{bind=true};
                {ok,BindGoods} ->
                    BindGoods
            end;
       true ->
            NewEquip2
    end,
    NewEquip4 = case common_misc:do_calculate_equip_refining_index(NewEquip3) of
                    {error,RIErrorCode} ->
                        ?DEBUG("~ts,RefiningIndexErrorCode=~w",["计算装备精炼系数出错",RIErrorCode]),
                        NewEquip3;
                    {ok, NewEquipGoods} ->
                        NewEquipGoods
                end,
    %% 占用那一个背包和格子
    mod_bag:update_goods(RoleId,NewEquip4),
    do_transaction_equip_change_quality4(RoleId,EquipGoods,NewQuality,DelGoodsList,UpdateGoodsList,NewEquip4).

do_transaction_equip_change_quality4(_RoleId,EquipGoods,NewQuality,DelGoodsList,UpdateGoodsList,NewEquip) ->
    OldQuality = EquipGoods#p_goods.quality,
    if NewQuality > OldQuality ->
            Reason = ?_LANG_EQUIP_CHANGE_Q_SUCC,
            {ok,Reason,NewEquip,DelGoodsList,UpdateGoodsList};
       true ->
            ?DEBUG("~ts",["装备品质改造失败，品质无法提升."]),
            Reason = ?_LANG_EQUIP_CHANGE_Q_NO_CHANGE,
            {ok,Reason,NewEquip,DelGoodsList,UpdateGoodsList}
    end.
do_equip_quality_error({Unique,Module,Method,_DataRecord, RoleId, _Pid, Line},Reason) ->
    SendSelf=#m_equip_build_quality_toc{succ = false, reason=Reason},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).


%% 更改签名
do_equip_signature({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) ->
    case catch do_equip_signature2({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) of
        {error,Error} ->
            ?DEBUG("~ts,Error=~w",["装备更改签名检验出错",Error]),
            do_equip_signature_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error);
        {ok,EquipGoods} ->
            do_equip_signature3({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods)
    end.
do_equip_signature2({_Unique,_Module,_Method,DataRecord, RoleId, _Pid, _Line}) ->
    EquipId = DataRecord#m_equip_build_signature_tos.equip_id,
    EquipGoods = case get_dirty_goods_by_id(RoleId,EquipId) of
                     {ok,Equip} ->
                         Equip;
                     {error,Error} ->
                         ?DEBUG("~ts,Error=~w",["获取需要更改装备签名的数据出错",Error]),
                         erlang:throw({error,?_LANG_EQUIP_CHANGE_S_PARAM_ERROR})
                 end,
    SignRoleId = EquipGoods#p_goods.sign_role_id,
    if SignRoleId =/= 0 andalso SignRoleId =:= RoleId ->
            ?DEBUG("~ts",["装备的签名和此角色一样，不需要重复签名"]),
            erlang:throw({error,?_LANG_EQUIP_CHANGE_S_EXIST_SIGN});
       true ->
            next
    end,
    [EquipInfo] = common_config_dyn:find_equip(EquipGoods#p_goods.typeid),
    if EquipInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
            erlang:throw({error,?_LANG_EQUIP_CHANGE_S_MOUNT_ERROR});
       EquipInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
            erlang:throw({error,?_LANG_EQUIP_CHANGE_S_FASHION_ERROR});
       EquipInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
            erlang:throw({error,?_LANG_EQUIP_CHANGE_S_ADORN_ERROR});
       true ->
            next
    end,
    [SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
    case lists:member(EquipGoods#p_goods.typeid,SpecialEquipList) of
        true ->
            erlang:throw({error,?_LANG_EQUIP_CHANGE_S_ADORN_ERROR});
        _ ->
            next
    end,
    {ok,EquipGoods}.
do_equip_signature3({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods) ->
	case catch mod_refining:get_refining_fee(equip_signature_fee, EquipGoods) of
		{error,Error,0} ->
			?DEBUG("~ts,Error=~w",["计算装备更改签名费用时出错",Error]),
            do_equip_signature_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error);
		Fee ->
			do_equip_signature4({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Fee)
	end.
do_equip_signature4({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Fee) ->
    case catch do_t_equip_change_signature(RoleId,DataRecord,Fee) of
        {error,Error} ->
            ?DEBUG("~ts,Error=~w",["签名出错",Error]),
            do_equip_signature_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error),
            do_equip_chang_deduct_fee_notify(RoleId, Line);
        {ok,NewEquip} ->
            do_equip_signature5({Unique,Module,Method,DataRecord, RoleId, Pid, Line},NewEquip)
    end.
do_equip_signature5({Unique,Module,Method,_DataRecord, RoleId, _Pid, Line},NewEquip) ->
    SendSelf = #m_equip_build_signature_toc{succ = true,equip = NewEquip},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf),
    do_equip_chang_deduct_fee_notify(RoleId, Line).
    
%% 装备更改签名事务操作
do_t_equip_change_signature(RoleId,DataRecord,Fee) ->
     case common_transaction:transaction(fun() -> 
                                 do_t_equip_change_signature2(RoleId,DataRecord,Fee)
                         end) of
        {atomic,{ok,NewEquip}} ->
            {ok,NewEquip};
        {aborted, Reason} ->
            case Reason of 
                {throw,{error,R}} ->
                    erlang:throw({error,R});
                _ ->
                    ?DEBUG("~ts,Reason=~w",["装备更改签名失败",Reason]),
                    erlang:throw({error,?_LANG_EQUIP_CHANGE_S_EXCEPTION})
            end
    end.
do_t_equip_change_signature2(RoleId,DataRecord,Fee) ->
    %% 扣费
    EquipConsume = #r_equip_consume{type = signature,
                                    consume_type = ?CONSUME_TYPE_SILVER_EQUIP_SIGNATURE,
                                    consume_desc = ""},
    mod_refining:do_refining_deduct_fee(RoleId,Fee,EquipConsume),
    EquipId = DataRecord#m_equip_build_signature_tos.equip_id,
    {ok,RoleBase} = mod_map_role:get_role_base(RoleId),
    RoleName = lists:append([common_tool:to_list(RoleBase#p_role_base.role_name), common_tool:to_list(?_LANG_EQUIP_CHANGE_S_SUFFIX)]),
    BagIds = mod_equip_build:get_equip_build_bag_id(),
    NewEquip = 
        case mod_refining_bag:get_goods_by_bag_ids_and_goods_id(RoleId,BagIds,EquipId) of
            {ok,Equip} ->
                Equip#p_goods{signature = RoleName,sign_role_id = RoleId};
            {error,Error} ->
                ?DEBUG("~ts,Error=~w",["获取更改签名装备信息出错",Error]),
                erlang:throw({error,?_LANG_EQUIP_CHANGE_S_EXCEPTION})
        end,
    mod_bag:update_goods(RoleId,NewEquip),
    {ok,NewEquip}.
    
do_equip_signature_error({Unique,Module,Method,_DataRecord, RoleId, _Pid, Line},Reason) ->
    SendSelf=#m_equip_build_signature_toc{succ = false, reason=Reason},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).
%% 升级装备信息
do_equip_upgrade_link({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) ->
    case catch do_equip_upgrade_link2({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) of
        {error,Error} ->
            ?DEBUG("~ts,Error=~w",["获取升级装备信息检查出错",Error]),
            do_equip_upgrade_link_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error);
        {ok,EquipGoods,NewEquipInfo} ->
            ?DEBUG("~ts,EquipGoods=~w",["查询的装备信息如下",EquipGoods]),
            do_equip_upgrade_link3({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods,NewEquipInfo)
    end.
do_equip_upgrade_link2({_Unique,_Module,_Method,DataRecord, RoleId, _Pid, _Line}) ->
    EquipId = DataRecord#m_equip_build_upgrade_link_tos.equip_id,
    EquipGoods = case get_dirty_goods_by_id(RoleId,EquipId) of
                     {ok,Equip} ->
                         Equip;
                     {error,Error} ->
                         ?DEBUG("~ts,Error=~w",["获取需要升级的装备信息的数据出错",Error]),
                         erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR})
                 end,
    LinkFile = common_config:get_world_config_file_path(equip_link),
    EquipLinkList = 
        case file:consult(LinkFile) of
            {ok, [List]} ->
                List;
            E ->
                ?ERROR_MSG("~ts,File=~w,Error=~w",["无法读取装备升级配置文件",LinkFile,E]),
                erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR})
        end,
    EquipTypeId = EquipGoods#p_goods.typeid,
    NextTypeId = case get_next_equip_type_id(EquipTypeId,EquipLinkList) of
                     0 ->
                         ?DEBUG("~ts,EquipTypeId=~w",["装备无法升级",EquipTypeId]),
                         erlang:throw({error,?_LANG_EQUIP_CHANGE_U_NOT_UPGRADE});
                     -1 ->
                         ?DEBUG("~ts,EquipTypeId=~w",["装备已经满级，不能再升级",EquipTypeId]),
                         erlang:throw({error,?_LANG_EQUIP_CHANGE_U_FULL_LEVEL});
                     -2 ->
                         ?DEBUG("~ts,EquipTypeId=~w",["装备升级配置文件配置出错，一种装备出现多种升级可能",EquipTypeId]),
                         erlang:throw({error,?_LANG_EQUIP_CHANGE_U_CONGIG});
                     NextTypeID ->
                         ?DEBUG("~ts,EquipTypeId=~w,NextTypeID=~w",["",EquipTypeId,NextTypeID]),
                         NextTypeID
                 end,
    EquipInfo =
        case common_config_dyn:find_equip(NextTypeId) of
            [EquipInfoT] ->
                EquipInfoT;
            _ ->
                erlang:throw({error,?_LANG_EQUIP_CHANGE_U_NEW_EQUIP})
        end,
    IsQuality = DataRecord#m_equip_build_upgrade_link_tos.is_quality,
    if IsQuality ->
            if EquipGoods#p_goods.quality =:= ?QUALITY_GENERAL ->
                    ?DEBUG("~ts",["装备升级，选择保留品质，但装备是普通的，不需要只留，参数错误"]),
                    erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR});
               EquipGoods#p_goods.quality =:= ?QUALITY_WELL
               andalso EquipGoods#p_goods.current_colour =/= ?COLOUR_WHITE->
                    ?DEBUG("~ts",["装备升级，选择保留品质，但装备是精良，且不是白色，参数错误"]),
                    erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR});
               true ->
                    next
            end;
       true ->
            next
    end,
    IsReinforce = DataRecord#m_equip_build_upgrade_link_tos.is_reinforce,
    if IsReinforce ->
            if EquipGoods#p_goods.reinforce_result > 0 ->
                    next;
               true ->
                    ?DEBUG("~ts",["装备升级，选择保留强化，但装备是没有强化过，参数错误"]),
                    erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR})
            end;
       true ->
            next
    end,  
    IsBindAttr = DataRecord#m_equip_build_upgrade_link_tos.is_bind_attr,
    if IsBindAttr ->
            if erlang:is_list(EquipGoods#p_goods.equip_bind_attr)
               andalso erlang:length(EquipGoods#p_goods.equip_bind_attr) > 0 ->
                    next;
               true ->
                    ?DEBUG("~ts",["装备升级，选择保留绑定属性，但装备是没有绑定属性过，参数错误"]),
                    erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR})
            end;
       true ->
            next
    end,             
    {ok,EquipGoods,EquipInfo}.

do_equip_upgrade_link3({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods,NewEquipInfo) ->
    NewGoods = #p_goods{id = EquipGoods#p_goods.id,
                        bagposition = EquipGoods#p_goods.bagposition,
                        bagid = EquipGoods#p_goods.bagid,
                        type = 3,roleid=RoleId,current_num = 1,state = 0,
                        sell_type = NewEquipInfo#p_equip_base_info.sell_type,
                        sell_price = NewEquipInfo#p_equip_base_info.sell_price,
                        typeid = NewEquipInfo#p_equip_base_info.typeid,
                        name = NewEquipInfo#p_equip_base_info.equipname,
                        level =(NewEquipInfo#p_equip_base_info.requirement)#p_use_requirement.min_level, 
                        endurance = NewEquipInfo#p_equip_base_info.endurance,
                        loadposition = 0,
                        current_endurance = NewEquipInfo#p_equip_base_info.endurance,
                        sub_quality = EquipGoods#p_goods.sub_quality,
                        quality_rate = 0,
                        bind = EquipGoods#p_goods.bind,
                        current_colour = EquipGoods#p_goods.current_colour,
                        embe_pos = EquipGoods#p_goods.embe_pos,
                        embe_equipid = EquipGoods#p_goods.embe_equipid,
                        forge_num = EquipGoods#p_goods.forge_num,
                        stone_num = EquipGoods#p_goods.stone_num,
                        punch_num = EquipGoods#p_goods.punch_num,
                        add_property=NewEquipInfo#p_equip_base_info.property,
                        stones = EquipGoods#p_goods.stones,
                        signature = EquipGoods#p_goods.signature,
                        sign_role_id = EquipGoods#p_goods.sign_role_id,
                        equip_bind_attr =[],
                        reinforce_result_list = EquipGoods#p_goods.reinforce_result_list,
                        use_bind = EquipGoods#p_goods.use_bind},
    do_equip_upgrade_link4({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods,NewEquipInfo,NewGoods).
do_equip_upgrade_link4({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods,NewEquipInfo,NewEquipGoods) ->
    IsQuality = DataRecord#m_equip_build_upgrade_link_tos.is_quality,
    IsReinforce = DataRecord#m_equip_build_upgrade_link_tos.is_reinforce,
    IsBindAttr = DataRecord#m_equip_build_upgrade_link_tos.is_bind_attr,
    Quality = get_equip_quality_by_upgrade(IsQuality,EquipGoods),
    {ReinforceResult,ReinforceRate,ReinforceResultList} =
        get_equip_reinforce_by_upgrade(IsReinforce,EquipGoods),
    NewGoods = NewEquipGoods#p_goods{
                 quality = Quality,
                 reinforce_result = ReinforceResult,
                 reinforce_rate = ReinforceRate,
                 reinforce_result_list = ReinforceResultList},
    %%OldWholeAttr = EquipGoods#p_goods.whole_attr,
    NewGoods3 = NewGoods,
    NewGoods4 = 
        if IsBindAttr ->
                NewGoods3#p_goods{equip_bind_attr = EquipGoods#p_goods.equip_bind_attr};
           true ->
                %% 显示升级后的装备信息，如果没有选择保留绑定属性，不需要添加
                NewGoods3
                %% NewGoods#p_goods{equip_bind_attr = EquipGoods#p_goods.equip_bind_attr}
        end,
    do_equip_upgrade_link5({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods,NewEquipInfo,NewGoods4).

do_equip_upgrade_link5({Unique,Module,Method,_DataRecord, RoleId, _Pid, Line},_EquipGoods,NewEquipInfo,NewEquipGoods) ->
    %% 颜色品质处理
    NewGoods2 = mod_refining:equip_colour_quality_add(new,NewEquipGoods,1,1,1),
    %% 强化处理
    NewGoods3 = equip_reinforce_property_add(NewGoods2,NewEquipInfo),
    %% 宝石处理
    NewGoods4 = 
        if NewGoods3#p_goods.stones =/= undefined ->
                equip_stone_property_add(NewGoods3);
           true ->
                NewGoods3
        end,
    %% 绑定处理
    NewGoods5 = mod_refining_bind:do_equip_bind_for_equip_upgrade(NewGoods4,NewEquipInfo),
    
    %% 精炼系数处理
    NewGoods7 = case common_misc:do_calculate_equip_refining_index(NewGoods5) of
                    {error,ErrorCode} ->
                        ?DEBUG("~ts,ErrorCode=~w",["计算装备精炼系数出错",ErrorCode]),
                        NewGoods5;
                    {ok,NewGoods6} ->
                        NewGoods6
                end,
    SendSelf = #m_equip_build_upgrade_link_toc{succ = true,new_equip = NewGoods7},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).

do_equip_upgrade_link_error({Unique,Module,Method,_DataRecord, RoleId, _Pid, Line},Reason) ->
    SendSelf=#m_equip_build_upgrade_link_toc{succ = false, reason=Reason},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).
%% 升级材料
do_equip_upgrade_goods({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) ->
    case catch do_equip_upgrade_goods2({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) of
        {error,Error} ->
            do_equip_upgrade_goods_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error);
        {ok} ->
            do_equip_upgrade_goods3({Unique,Module,Method,DataRecord, RoleId, Pid, Line})
    end.
do_equip_upgrade_goods2({_Unique,_Module,_Method,DataRecord, _RoleId, _Pid, _Line}) ->
    Material =  DataRecord#m_equip_build_upgrade_goods_tos.material,
    MaterialList = mod_equip_build:get_equip_build_material_dict(),
    NewMaterialList = lists:append([MaterialList,[0]]),
    case lists:member(Material, NewMaterialList) of 
        false ->
            ?DEBUG("~ts,Material=~w",["材质参数不合法",Material]),
            erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR});
        true ->
            next
    end,
    {ok}.
do_equip_upgrade_goods3({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) ->
    Material = DataRecord#m_equip_build_upgrade_goods_tos.material,
    if Material =:= 0 ->
            do_equip_upgrade_goods4({Unique,Module,Method,DataRecord, RoleId, Pid, Line});
       true ->
            do_equip_upgrade_goods5({Unique,Module,Method,DataRecord, RoleId, Pid, Line})
    end.
do_equip_upgrade_goods4({Unique,Module,Method,DataRecord, RoleId, _Pid, Line}) ->
    Material = DataRecord#m_equip_build_upgrade_goods_tos.material,
    BaseList = mod_equip_build:get_dirty_equip_build_goods_list(?EQUIP_BUILD_BASE,RoleId),
    AddList = mod_equip_build:get_dirty_equip_build_goods_list(?EQUIP_BUILD_ADD,RoleId),
    QualityList = mod_equip_build:get_dirty_equip_build_goods_list(?EQUIP_BUILD_PINZHI,RoleId),
    NewBaseList = mod_equip_build:count_class_equip_build_goods(BaseList,[]),
    NewAddList = mod_equip_build:count_class_equip_build_goods(AddList,[]),
    NewQualityList =  mod_equip_build:count_class_equip_build_goods(QualityList,[]),
    SendSelf=#m_equip_build_upgrade_goods_toc{succ = true, material= Material,
                                              base_list = NewBaseList, 
                                              add_list = NewAddList,
                                              quality_list=NewQualityList},
    BagIdList = mod_equip_build:get_equip_build_bag_id(),
    ReinforcIdList = get_equip_reinforce_material(),
    ReinforceList = get_dirty_goods(RoleId,ReinforcIdList,BagIdList),
    Reinforce = mod_equip_build:count_class_equip_build_goods(ReinforceList,[]),
    SendSelf2 = SendSelf#m_equip_build_upgrade_goods_toc{reinforce = Reinforce},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf2).

do_equip_upgrade_goods5({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) ->
    Material = DataRecord#m_equip_build_upgrade_goods_tos.material,
    BaseList = mod_equip_build:get_dirty_equip_build_goods_list(?EQUIP_BUILD_BASE,RoleId),
    NewBaseList = mod_equip_build:count_class_equip_build_goods(BaseList,[]),
    BaseMaterial = mod_equip_build:get_equip_build_class_goods(Material,?EQUIP_BUILD_BASE),
    NewBaseList2 = lists:filter(fun(BR) ->
                                        case lists:keyfind(BR#p_equip_build_goods.type_id,
                                                           #r_equip_build_item.item_id,BaseMaterial) of
                                            false -> false;
                                            _ -> true
                                        end 
                                end,NewBaseList),
    AddList = mod_equip_build:get_dirty_equip_build_goods_list(?EQUIP_BUILD_ADD,RoleId),
    NewAddList = mod_equip_build:count_class_equip_build_goods(AddList,[]),
    AddMaterial = mod_equip_build:get_equip_build_class_goods(Material,?EQUIP_BUILD_ADD),
    NewAddList2 = lists:filter(fun(AR) ->
                                        case lists:keyfind(AR#p_equip_build_goods.type_id,
                                                           #r_equip_build_item.item_id, AddMaterial) of
                                            false -> false;
                                            _ -> true
                                        end 
                               end,NewAddList),
    QualityList = mod_equip_build:get_dirty_equip_build_goods_list(?EQUIP_BUILD_PINZHI,RoleId),
    NewQualityList = mod_equip_build:count_class_equip_build_goods(QualityList,[]),
    QualityMaterial = mod_equip_build:get_equip_build_class_goods(Material,?EQUIP_BUILD_PINZHI),
    NewQualityList2 = lists:filter(fun(AR) ->
                                        case lists:keyfind(AR#p_equip_build_goods.type_id,
                                                           #r_equip_build_item.item_id, QualityMaterial) of
                                            false -> false;
                                            _ -> true
                                        end 
                               end,NewQualityList),
    SendSelf=#m_equip_build_upgrade_goods_toc{succ = true, material= Material,
                                              base_list = NewBaseList2,add_list = NewAddList2, quality_list=NewQualityList2},
    do_equip_upgrade_goods6({Unique,Module,Method,DataRecord, RoleId, Pid, Line},SendSelf).

do_equip_upgrade_goods6({Unique,Module,Method,_DataRecord, RoleId, _Pid, Line},SendSelf) ->
    BagIdList = mod_equip_build:get_equip_build_bag_id(),
    ReinforcIdList = get_equip_reinforce_material(),
    ReinforceList = get_dirty_goods(RoleId,ReinforcIdList,BagIdList),
    Reinforce = mod_equip_build:count_class_equip_build_goods(ReinforceList,[]),
    SendSelf2 = SendSelf#m_equip_build_upgrade_goods_toc{reinforce = Reinforce},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf2).

do_equip_upgrade_goods_error({Unique,Module,Method,DataRecord, RoleId, _Pid, Line},Reason) ->
    Material = DataRecord#m_equip_build_upgrade_goods_tos.material,
    SendSelf=#m_equip_build_upgrade_goods_toc{succ = false, reason=Reason,material= Material},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).
%% 装备升级
do_equip_upgrade({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) ->
    case catch do_equip_upgrade2({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) of
        {error,Error} ->
            ?DEBUG("~ts,Error=~w",["装备升级检验出错",Error]),
            do_equip_upgrade_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error);
        {ok,EquipGoods,EquipInfo,NextEquipInfo,BaseRecord,QualityRecord,ReinforceRecord,BindRecord} ->
            do_equip_upgrade3({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                             EquipGoods,EquipInfo,NextEquipInfo,BaseRecord,
                              QualityRecord,ReinforceRecord,BindRecord)
    end.

do_equip_upgrade2({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) ->
    EquipId = DataRecord#m_equip_build_upgrade_tos.equip_id,
    EquipGoods = case get_dirty_goods_by_id(RoleId,EquipId) of
                     {ok,Equip} ->
                         Equip;
                     {error,Error} ->
                         ?DEBUG("~ts,Error=~w",["获取需要升级的装备信息的数据出错",Error]),
                         erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR})
                 end,
    LinkFile = common_config:get_world_config_file_path(equip_link),
    EquipLinkList = 
        case file:consult(LinkFile) of
            {ok, [List]} ->
                List;
            E ->
                ?ERROR_MSG("~ts,File=~w,Error=~w",["无法读取装备升级配置文件",LinkFile,E]),
                erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR})
        end,
    do_equip_upgrade2_1({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods,EquipLinkList).

do_equip_upgrade2_1({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods,EquipLinkList) ->
    EquipTypeId = EquipGoods#p_goods.typeid,
    NextEquipTypeId = case get_next_equip_type_id(EquipTypeId,EquipLinkList) of
                          0 ->
                              ?DEBUG("~ts,EquipTypeId=~w",["装备无法升级",EquipTypeId]),
                              erlang:throw({error,?_LANG_EQUIP_CHANGE_U_NOT_UPGRADE});
                          -1 ->
                              ?DEBUG("~ts,EquipTypeId=~w",["装备已经满级，不能再升级",EquipTypeId]),
                              erlang:throw({error,?_LANG_EQUIP_CHANGE_U_FULL_LEVEL});
                          -2 ->
                              ?DEBUG("~ts,EquipTypeId=~w",["装备升级配置文件配置出错，一种装备出现多种升级可能",EquipTypeId]),
                              erlang:throw({error,?_LANG_EQUIP_CHANGE_U_CONGIG});
                          NextTypeId ->
                              ?DEBUG("~ts,EquipTypeId=~w,NextTypeID=~w",["",EquipTypeId,NextTypeId]),
                              NextTypeId
                      end,
    NewTypeId = DataRecord#m_equip_build_upgrade_tos.new_type_id,
    if NextEquipTypeId =/= NewTypeId ->
            ?DEBUG("~ts,ParamNextTypeId=~w,NextId=~w",["装备升级目标id不合法",NewTypeId,NextEquipTypeId]),
            erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR});
       true ->
            next
    end,
    EquipInfo =
        case common_config_dyn:find_equip(EquipTypeId) of
            [EquipInfoT] ->
                EquipInfoT;
            _ ->
                erlang:throw({error,?_LANG_EQUIP_CHANGE_U_NEW_EQUIP})
        end,
    NextEquipInfo = 
        case common_config_dyn:find_equip(NewTypeId) of
            [NextEquipInfoT] ->
                NextEquipInfoT;
            _ ->
                erlang:throw({error,?_LANG_EQUIP_CHANGE_U_NEW_EQUIP})
        end,
    do_equip_upgrade2_2({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                        EquipGoods,EquipInfo,NextEquipInfo).

do_equip_upgrade2_2({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                    EquipGoods,EquipInfo,NextEquipInfo) ->
    BaseTypeId = DataRecord#m_equip_build_upgrade_tos.base_type_id,
    EquipMaterial = NextEquipInfo#p_equip_base_info.material,
    EquipLevel = (NextEquipInfo#p_equip_base_info.requirement)#p_use_requirement.min_level,
    [BaseRecord] = 
        case common_config_dyn:find(equip_change,equip_upgrade_base_material) of
            [ BMList ] -> 
                [R || R <- BMList, 
                      EquipLevel >= R#r_equip_upgrade_base_material.min_level,
                      EquipLevel =< R#r_equip_upgrade_base_material.max_level
                ];
            _ -> 
                ?DEBUG("~ts,BaseTypeId=~w,EquipMaterial=~w,EquipLevel=~w",["装备升级基础材料不合法1",BaseTypeId,EquipMaterial,EquipLevel]),
                erlang:throw({error,?_LANG_EQUIP_CHANGE_U_BASE_ERROR})
        end,
    BaseLevel = BaseRecord#r_equip_upgrade_base_material.item_level,
    BaseItem = 
        case mod_equip_build:get_equip_build_goods(EquipMaterial,?EQUIP_BUILD_BASE,BaseLevel) of
            [] ->
                ?DEBUG("~ts,EquipMaterial=~w,BaseLevel=~w",["装备升级基础材料不合法2",EquipMaterial,BaseLevel]),
                erlang:throw({error, ?_LANG_EQUIP_CHANGE_U_BASE_ERROR});
            [BItem] ->
                BItem
        end,
    if BaseItem#r_equip_build_item.item_id =/= BaseTypeId ->
            ?DEBUG("~ts,BaseTypeId=~w,BaseItemId=~w",["装备升级基础材料不合法3",BaseTypeId,BaseItem#r_equip_build_item.item_id]),
            erlang:throw({error,?_LANG_EQUIP_CHANGE_U_BASE_ERROR});
       true ->
            next
    end,
    do_equip_upgrade2_3({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                    EquipGoods,EquipInfo,NextEquipInfo,BaseRecord).
do_equip_upgrade2_3({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                    EquipGoods,EquipInfo,NextEquipInfo,BaseRecord) ->
    EquipQuality = EquipGoods#p_goods.quality,
    EquipMaterial = NextEquipInfo#p_equip_base_info.material,
    QualityTypeId = DataRecord#m_equip_build_upgrade_tos.quality_type_id,
    QualityRecord = 
    if QualityTypeId =:= 0 ->
            undefined;
       true ->
            if EquipQuality =:= ?QUALITY_GENERAL ->
                    ?DEBUG("~ts,EquipQuality=~w",["此装备升级时，不需要选择保留品质",EquipQuality]),
                    erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR});
               EquipQuality =:= ?QUALITY_WELL
               andalso EquipGoods#p_goods.current_colour =/= ?COLOUR_WHITE->
                    ?DEBUG("~ts,EquipQuality=~w,Colour=~w",["此装备升级时，不需要选择保留品质",EquipQuality,EquipGoods#p_goods.current_colour]),
                    erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR});
               true ->
                    next
            end,
            [QRecord] = 
                case common_config_dyn:find(equip_change,equip_upgrade_quality_material) of
                    [ QMList ] ->
                        [R || R <- QMList,
                              R#r_equip_upgrade_quality_material.quality =:= EquipQuality
                        ];
                    _ ->
                        ?DEBUG("~ts,EquipQuality=~w",["装备升级保留品质材料不合法1",EquipQuality]),
                        erlang:throw({error,?_LANG_EQUIP_CHANGE_U_QUALITY_ERROR})
                end,
            QualityLevel = QRecord#r_equip_upgrade_quality_material.item_level,
            QualityItem = 
                case mod_equip_build:get_equip_build_goods(EquipMaterial,?EQUIP_BUILD_PINZHI,QualityLevel) of
                    [] ->
                        ?DEBUG("~ts,EquipMaterial=~w,BaseLevel=~w",["装备升级保留品质材料不合法2",EquipMaterial,QualityLevel]),
                        erlang:throw({error, ?_LANG_EQUIP_CHANGE_U_QUALITY_ERROR});
                    [QItem] ->
                        QItem
                end,
            if QualityItem#r_equip_build_item.item_id =/= QualityTypeId ->
                    ?DEBUG("~ts,QualityTypeId=~w,QualityItem=~w",["装备升级保留品质材料不合法3",QualityTypeId,QualityItem]),
                    erlang:throw({error, ?_LANG_EQUIP_CHANGE_U_QUALITY_ERROR});
               true ->
                    next
            end,
            QRecord
    end,
    do_equip_upgrade2_4({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                        EquipGoods,EquipInfo,NextEquipInfo,BaseRecord,QualityRecord).

do_equip_upgrade2_4({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                    EquipGoods,EquipInfo,NextEquipInfo,BaseRecord,QualityRecord) ->
    ReinforceTypeId = DataRecord#m_equip_build_upgrade_tos.reinforce_type_id,
    ReinforceResult = EquipGoods#p_goods.reinforce_result,
    EquipReinforceLevel = 
        if ReinforceResult =/= 0 andalso ReinforceResult =/= undefined ->
                erlang:trunc(ReinforceResult / 10);
           true->
                0
        end,
    ReinforceRecord = 
        if ReinforceTypeId =:= 0 orelse EquipReinforceLevel =:= 0 ->
                undefined;
           true ->
                if EquipReinforceLevel > 0 ->
                        next;
                   true ->
                        ?DEBUG("~ts,ReinforceResult=~w",["此装备升级时，不需要选择保留强化",ReinforceResult]),
                        erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR})
                end,
                [RRecord] = 
                    case common_config_dyn:find(equip_change,equip_upgrade_reinforce_material) of
                        [ RMList ] ->
                            [R || R <- RMList,
                                  R#r_equip_upgrade_reinforce_material.reinforce =:= EquipReinforceLevel
                            ];
                        _ ->
                            ?DEBUG("~ts,ReinforceLevel=~w",["装备升级保留强化材料不合法1",EquipReinforceLevel]),
                            erlang:throw({error,?_LANG_EQUIP_CHANGE_U_REINFORCE_ERROR})
                    end,
                ReinforceLevel = RRecord#r_equip_upgrade_reinforce_material.item_level,
                [ReinforceItem] = 
                    case common_config_dyn:find(equip_change,equip_reinforce_material) of
                        [ MList ] ->
                            [R1 || R1 <- MList,
                                   R1#r_equip_reinforce_material.item_level =:= ReinforceLevel
                            ];
                        _ ->
                            ?DEBUG("~ts,ReinforceLevel=~w",["装备升级保留强化材料不合法2",ReinforceLevel]),
                            erlang:throw({error,?_LANG_EQUIP_CHANGE_U_REINFORCE_ERROR})
                    end,
                if ReinforceItem#r_equip_reinforce_material.type_id =/= ReinforceTypeId ->
                        ?DEBUG("~ts,ReinforceTypeId=~w",["装备升级保留强化材料不合法3",ReinforceTypeId]),
                         erlang:throw({error,?_LANG_EQUIP_CHANGE_U_REINFORCE_ERROR});
                   true->
                        next
                end,
                RRecord
        end,
    do_equip_upgrade2_5({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                        EquipGoods,EquipInfo,NextEquipInfo,BaseRecord,
                        QualityRecord,ReinforceRecord).
do_equip_upgrade2_5({Unique,Module,Method,DataRecord, RoleId, Pid,Line},
                        EquipGoods,EquipInfo,NextEquipInfo,BaseRecord,
                        QualityRecord,ReinforceRecord) ->
    do_equip_upgrade2_6({Unique,Module,Method,DataRecord,RoleId,Pid,Line},
                        EquipGoods,EquipInfo,NextEquipInfo,BaseRecord,
                        QualityRecord,ReinforceRecord).

do_equip_upgrade2_6({_Unique,_Module,_Method,DataRecord, _RoleId, _Pid, _Line},
                    EquipGoods,EquipInfo,NextEquipInfo,BaseRecord,
                    QualityRecord,ReinforceRecord) ->
    BindTypeId = DataRecord#m_equip_build_upgrade_tos.bind_attr_type_id,
    EquipBindAttr = EquipGoods#p_goods.equip_bind_attr,
    EquipMaterial = NextEquipInfo#p_equip_base_info.material,
    BindRecord = 
        if BindTypeId =:= 0 ->
                undefined;
           true ->
                if erlang:is_list(EquipBindAttr)
                   andalso erlang:length(EquipBindAttr) > 0 ->
                        next;
                   true ->
                        ?DEBUG("~ts,EquipBindAttr=~w",["此装备升级时，不需要选择保留绑定属性",EquipBindAttr]),
                        erlang:throw({error,?_LANG_EQUIP_CHANGE_U_PARAM_ERROR})
                end,
                MaxBindLevel = 
                    lists:foldl(fun(R,BindLevel) ->
                                        if R#p_equip_bind_attr.attr_level > BindLevel ->
                                                R#p_equip_bind_attr.attr_level;
                                           true ->
                                                BindLevel
                                        end
                                end,0,EquipBindAttr),
                [BRecord] = 
                    case common_config_dyn:find(equip_change,equip_upgrade_bind_material) of
                        [ BMList ] ->
                            [R || R <- BMList,
                                  R#r_equip_upgrade_bind_material.bind_level =:= MaxBindLevel
                            ];
                        _ ->
                            ?DEBUG("~ts,MaxBindLevel=~w",["装备升级保留绑定属性材料不合法1",MaxBindLevel]),
                            erlang:throw({error,?_LANG_EQUIP_CHANGE_U_BIND_ERROR})
                    end,
                BindItemLevel = BRecord#r_equip_upgrade_bind_material.item_level,
                BindItem = 
                    case mod_equip_build:get_equip_build_goods(EquipMaterial,?EQUIP_BUILD_ADD,BindItemLevel) of
                        [] ->
                            ?DEBUG("~ts,EquipMaterial=~w,BindItemLevel=~w",["装备升级保留绑定属性材料不合法2",EquipMaterial,BindItemLevel]),
                            erlang:throw({error, ?_LANG_EQUIP_CHANGE_U_BIND_ERROR});
                        [BItem] ->
                            BItem
                    end,
                if BindItem#r_equip_build_item.item_id =/= BindTypeId ->
                        ?DEBUG("~ts,BindTypeId=~w,BindItem=~w",["装备升级保留绑定属性材料不合法3",BindTypeId,BindItem]),
                        erlang:throw({error, ?_LANG_EQUIP_CHANGE_U_BIND_ERROR});
                   true ->
                        next
                end,
                BRecord
        end,
    {ok,EquipGoods,EquipInfo,NextEquipInfo,BaseRecord,QualityRecord,ReinforceRecord,BindRecord}.

do_equip_upgrade3({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                  EquipGoods,EquipInfo,NewEquipInfo,BaseRecord,
                  QualityRecord,ReinforceRecord,BindRecord) ->
    %% 验证通过，根据条件生成新的装备
    NewGoods = #p_goods{id =EquipGoods#p_goods.id,type = 3,roleid=RoleId,
                        current_num = 1,state = 0,
                        bagposition = EquipGoods#p_goods.bagposition,
                        bagid = EquipGoods#p_goods.bagid,
                        sell_type = NewEquipInfo#p_equip_base_info.sell_type,
                        sell_price = NewEquipInfo#p_equip_base_info.sell_price,
                        typeid = NewEquipInfo#p_equip_base_info.typeid,
                        name = NewEquipInfo#p_equip_base_info.equipname,
                        level =(NewEquipInfo#p_equip_base_info.requirement)#p_use_requirement.min_level, 
                        endurance = NewEquipInfo#p_equip_base_info.endurance,
                        loadposition = 0,
                        current_endurance = NewEquipInfo#p_equip_base_info.endurance,
                        bind = EquipGoods#p_goods.bind,
                        current_colour = EquipGoods#p_goods.current_colour,
                        embe_pos = EquipGoods#p_goods.embe_pos,
                        embe_equipid = EquipGoods#p_goods.embe_equipid,
                        sub_quality = EquipGoods#p_goods.sub_quality,
                        quality_rate = 0,
                        forge_num = EquipGoods#p_goods.forge_num,
                        stone_num = EquipGoods#p_goods.stone_num,
                        punch_num = EquipGoods#p_goods.punch_num,
                        add_property=NewEquipInfo#p_equip_base_info.property,
                        stones = EquipGoods#p_goods.stones,
                        signature = EquipGoods#p_goods.signature,
                        sign_role_id = EquipGoods#p_goods.sign_role_id,
                        equip_bind_attr = [],
                        reinforce_result_list = EquipGoods#p_goods.reinforce_result_list,
                        use_bind = EquipGoods#p_goods.use_bind},
    do_equip_upgrade4({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                      EquipGoods,EquipInfo,NewEquipInfo,BaseRecord,
                      QualityRecord,ReinforceRecord,BindRecord,NewGoods).
do_equip_upgrade4({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                  EquipGoods,EquipInfo,NewEquipInfo,BaseRecord,
                  QualityRecord,ReinforceRecord,BindRecord,NewEquipGoods) ->
    %% 装备品质
    QualityTypeId = DataRecord#m_equip_build_upgrade_tos.quality_type_id,
    QualityFlag = if QualityTypeId =/= 0 -> true; true -> false end,
    Quality = get_equip_quality_by_upgrade(QualityFlag,EquipGoods),
    %% 装备强化
    ReinforceTypeId = DataRecord#m_equip_build_upgrade_tos.reinforce_type_id,
    ReinforceFlag = if ReinforceTypeId =/= 0 -> true; true -> false end,
    {ReinforceResult,ReinforceRate,ReinforceResultList} =
        get_equip_reinforce_by_upgrade(ReinforceFlag,EquipGoods),
    NewGoods = NewEquipGoods#p_goods{
                 quality = Quality,
                 reinforce_result = ReinforceResult,
                 reinforce_rate = ReinforceRate,
                 reinforce_result_list = ReinforceResultList},
    %% 装备绑定属性
    BindTypeId = DataRecord#m_equip_build_upgrade_tos.bind_attr_type_id,
    BindFlag = if BindTypeId =/= 0 -> true; true -> false end,
    NewGoods2 = get_equip_bind_attr_by_upgrade(BindFlag,NewGoods,EquipGoods,NewEquipInfo),
    do_equip_upgrade5({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                      EquipGoods,EquipInfo,NewEquipInfo,BaseRecord,
                      QualityRecord,ReinforceRecord,BindRecord,NewGoods2).

do_equip_upgrade5({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                  EquipGoods,EquipInfo,NewEquipInfo,BaseRecord,
                  QualityRecord,ReinforceRecord,BindRecord,NewEquipGoods) ->
	case catch mod_refining:get_refining_fee(equip_upgrade_fee, NewEquipGoods) of
		{error,Error,0} ->
			?DEBUG("~ts,Error=~w",["计算装备升级费用时出错",Error]),
            do_equip_upgrade_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error);
		Fee ->
			do_equip_upgrade6({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                               EquipGoods,EquipInfo,NewEquipInfo,BaseRecord,
                               QualityRecord,ReinforceRecord,BindRecord,NewEquipGoods,Fee)
	end.
do_equip_upgrade6({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                  EquipGoods,EquipInfo,NewEquipInfo,BaseRecord,
                  QualityRecord,ReinforceRecord,BindRecord,NewEquipGoods,Fee) ->
    case catch do_transaction_equip_upgrade(RoleId,DataRecord,EquipGoods,
                                            EquipInfo,NewEquipInfo,BaseRecord,
                                            QualityRecord,ReinforceRecord,BindRecord,NewEquipGoods,Fee) of
        {error,Error} ->
            do_equip_upgrade_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error);
        {ok,Equip,DelBaseList,UpdateBaseList, DelQualityList,
         UpdateQualityList,DelReinList,UpdateReinList,
         DelFiveList,UpdateFiveList,DelBindList,UpdateBindList} ->
            %% 道具消费日志
            common_item_logger:log(RoleId,EquipGoods,?LOG_ITEM_TYPE_ZHUANG_BEI_SHENG_JI_SHI_QU),
            do_equip_upgrade7({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                              Equip,DelBaseList,UpdateBaseList, DelQualityList,
                              UpdateQualityList,DelReinList,UpdateReinList,
                              DelFiveList,UpdateFiveList,DelBindList,UpdateBindList)
    end.

do_equip_upgrade7({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                  Equip,DelBaseList,UpdateBaseList, DelQualityList,
                  UpdateQualityList,DelReinList,UpdateReinList,
                  DelFiveList,UpdateFiveList,DelBindList,UpdateBindList) ->
    BaseList = mod_equip_build:get_dirty_equip_build_goods_list(?EQUIP_BUILD_BASE,RoleId),
    AddList = mod_equip_build:get_dirty_equip_build_goods_list(?EQUIP_BUILD_ADD,RoleId),
    QualityList = mod_equip_build:get_dirty_equip_build_goods_list(?EQUIP_BUILD_PINZHI,RoleId),
    NewBaseList = mod_equip_build:count_class_equip_build_goods(BaseList,[]),
    NewAddList = mod_equip_build:count_class_equip_build_goods(AddList,[]),
    NewQualityList = mod_equip_build:count_class_equip_build_goods(QualityList,[]),
    BagIdList = mod_equip_build:get_equip_build_bag_id(),
    ReinforcIdList = get_equip_reinforce_material(),
    ReinforceList = get_dirty_goods(RoleId,ReinforcIdList,BagIdList),
    Reinforce = mod_equip_build:count_class_equip_build_goods(ReinforceList,[]),
    SendSelf=#m_equip_build_upgrade_toc{succ = true, 
                                        base_list = NewBaseList, 
                                        add_list = NewAddList,
                                        reinforce = Reinforce,
                                        quality_list = NewQualityList,
                                        equip = Equip
                                       },
    do_equip_upgrade8({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                      Equip,DelBaseList,UpdateBaseList, DelQualityList,
                      UpdateQualityList,DelReinList,UpdateReinList,
                      DelFiveList,UpdateFiveList,DelBindList,UpdateBindList,SendSelf).
do_equip_upgrade8({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                      Equip,DelBaseList,UpdateBaseList, DelQualityList,
                      UpdateQualityList,DelReinList,UpdateReinList,
                      DelFiveList,UpdateFiveList,DelBindList,UpdateBindList,SendSelf) ->
    [BaseGoods] = mod_equip_build:count_class_equip_build_goods(DelBaseList,[]),
    %% 道具消费日志
    catch common_item_logger:log(RoleId,BaseGoods#p_equip_build_goods.type_id, 
                                        BaseGoods#p_equip_build_goods.current_num,
                                 undefined,?LOG_ITEM_TYPE_ZHUANG_BEI_SHENG_JI_SHI_QU),
    SendSelf2 = SendSelf#m_equip_build_upgrade_toc{base_goods = BaseGoods},
    SendSelf3 = 
        if DelQualityList =/= [] ->
                [QualityGoods] = mod_equip_build:count_class_equip_build_goods(DelQualityList,[]),
                %% 道具消费日志
                catch common_item_logger:log(RoleId,QualityGoods#p_equip_build_goods.type_id, 
                                                    QualityGoods#p_equip_build_goods.current_num,
                                                    undefined,?LOG_ITEM_TYPE_ZHUANG_BEI_SHENG_JI_SHI_QU),
                SendSelf2#m_equip_build_upgrade_toc{quality_goods = QualityGoods};
           true ->
                SendSelf2
        end,
    SendSelf4 = 
        if DelReinList =/= [] ->
                [ReinGoods] = mod_equip_build:count_class_equip_build_goods(DelReinList,[]),
                %% 道具消费日志
                catch common_item_logger:log(RoleId,ReinGoods#p_equip_build_goods.type_id, 
                                                    ReinGoods#p_equip_build_goods.current_num,
                                                    undefined,?LOG_ITEM_TYPE_ZHUANG_BEI_SHENG_JI_SHI_QU),
                SendSelf3#m_equip_build_upgrade_toc{reinforce_goods = ReinGoods};
           true ->
                SendSelf3
        end,
    SendSelf5 =
        if DelFiveList =/= [] ->
                [FiveGoods] = mod_equip_build:count_class_equip_build_goods(DelFiveList,[]),
                %% 道具消费日志
                common_item_logger:log(RoleId,FiveGoods,?LOG_ITEM_TYPE_ZHUANG_BEI_SHENG_JI_SHI_QU),
                SendSelf4#m_equip_build_upgrade_toc{five_ele_goods = FiveGoods};
           true ->
                SendSelf4
        end,
    SendSelf6 =
        if DelBindList =/= [] ->
                [BindGoods] = mod_equip_build:count_class_equip_build_goods(DelBindList,[]),
                %% 道具消费日志
                catch common_item_logger:log(RoleId, BindGoods#p_equip_build_goods.type_id, 
                                             BindGoods#p_equip_build_goods.current_num,
                                             undefined,?LOG_ITEM_TYPE_ZHUANG_BEI_SHENG_JI_SHI_QU),
                SendSelf5#m_equip_build_upgrade_toc{bind_attr_goods = BindGoods};
           true ->
                SendSelf5
        end,
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf6),
    %% 道具消费日志
    common_item_logger:log(RoleId,Equip,?LOG_ITEM_TYPE_ZHUANG_BEI_SHENG_JI_HUO_DE),
    do_equip_upgrade9({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                      Equip,DelBaseList,UpdateBaseList, DelQualityList,
                      UpdateQualityList,DelReinList,UpdateReinList,
                      DelFiveList,UpdateFiveList,DelBindList,UpdateBindList).
do_equip_upgrade9({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                  Equip,DelBaseList,UpdateBaseList, DelQualityList,
                  UpdateQualityList,DelReinList,UpdateReinList,
                  DelFiveList,UpdateFiveList,DelBindList,UpdateBindList) ->
    %% 通知钱变化
    do_equip_chang_deduct_fee_notify(RoleId, Line),
    common_misc:update_goods_notify({line, Line, RoleId},Equip),
    %% 基础材料
    NotifyDelList = lists:filter(fun(R) -> 
                                          case lists:keyfind(R#p_goods.id,#p_goods.id,UpdateBaseList) of
                                              false -> true;
                                              _ -> false
                                          end
                                  end,DelBaseList),
    if NotifyDelList =/= [] ->
            ?DEBUG("~ts",["扣除装备升级基础材料通知"]),
            common_misc:del_goods_notify({line, Line, RoleId}, NotifyDelList);
       true ->
            ignore
    end,
    if UpdateBaseList =/= [] ->
            common_misc:update_goods_notify({line, Line, RoleId},UpdateBaseList);
       true ->
            next
    end,
    do_equip_upgrade10({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                       DelQualityList,UpdateQualityList,DelReinList,UpdateReinList,
                       DelFiveList,UpdateFiveList,DelBindList,UpdateBindList).
do_equip_upgrade10({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                       DelQualityList,UpdateQualityList,DelReinList,UpdateReinList,
                       DelFiveList,UpdateFiveList,DelBindList,UpdateBindList) ->
    %% 保留品质材料
    NotifyDelList = lists:filter(fun(R) -> 
                                          case lists:keyfind(R#p_goods.id,#p_goods.id,UpdateQualityList) of
                                              false -> true;
                                              _ -> false
                                          end
                                  end,DelQualityList),
    if NotifyDelList =/= [] ->
            ?DEBUG("~ts",["扣除装备升级保留品质材料材料通知"]),
            common_misc:del_goods_notify({line, Line, RoleId}, NotifyDelList);
       true ->
            ignore
    end,
    if UpdateQualityList =/= [] ->
            common_misc:update_goods_notify({line, Line, RoleId},UpdateQualityList);
       true ->
            next
    end,
    do_equip_upgrade11({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                       DelReinList,UpdateReinList,DelFiveList,UpdateFiveList,
                       DelBindList,UpdateBindList).
do_equip_upgrade11({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                   DelReinList,UpdateReinList,DelFiveList,UpdateFiveList,
                   DelBindList,UpdateBindList) ->
    %% 保留强化材料
    NotifyDelList = lists:filter(fun(R) -> 
                                          case lists:keyfind(R#p_goods.id,#p_goods.id,UpdateReinList) of
                                              false -> true;
                                              _ -> false
                                          end
                                  end,DelReinList),
    if NotifyDelList =/= [] ->
            ?DEBUG("~ts",["扣除装备升级保留强化材料材料通知"]),
            common_misc:del_goods_notify({line, Line, RoleId}, NotifyDelList);
       true ->
            ignore
    end,
    if UpdateReinList =/= [] ->
            common_misc:update_goods_notify({line, Line, RoleId},UpdateReinList);
       true ->
            next
    end,
    do_equip_upgrade12({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                       DelFiveList,UpdateFiveList,DelBindList,UpdateBindList).
do_equip_upgrade12({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                       DelFiveList,UpdateFiveList,DelBindList,UpdateBindList) ->
    %% 保留五行材料
    NotifyDelList = lists:filter(fun(R) -> 
                                          case lists:keyfind(R#p_goods.id,#p_goods.id,UpdateFiveList) of
                                              false -> true;
                                              _ -> false
                                          end
                                 end,DelFiveList),
    if NotifyDelList =/= [] ->
            ?DEBUG("~ts",["扣除装备升级保留五行材料材料通知"]),
            common_misc:del_goods_notify({line, Line, RoleId}, NotifyDelList);
       true ->
            ignore
    end,
    if UpdateFiveList =/= [] ->
            common_misc:update_goods_notify({line, Line, RoleId},UpdateFiveList);
       true ->
            next
    end,
    do_equip_upgrade13({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                       DelBindList,UpdateBindList).
do_equip_upgrade13({_Unique,_Module,_Method,_DataRecord, RoleId, _Pid, Line},
                       DelBindList,UpdateBindList) ->
    %% 保留五行材料
    NotifyDelList = lists:filter(fun(R) -> 
                                         case lists:keyfind(R#p_goods.id,#p_goods.id,UpdateBindList) of
                                             false -> true;
                                             _ -> false
                                         end
                                 end,DelBindList),
    if NotifyDelList =/= [] ->
            ?DEBUG("~ts",["扣除装备升级保留绑定属性材料材料通知"]),
            common_misc:del_goods_notify({line, Line, RoleId}, NotifyDelList);
       true ->
            ignore
    end,
    if UpdateBindList =/= [] ->
            common_misc:update_goods_notify({line, Line, RoleId},UpdateBindList);
       true ->
            next
    end,
    ok.
do_equip_upgrade_error({Unique,Module,Method,_DataRecord, RoleId, _Pid, Line},Reason) ->
    SendSelf=#m_equip_build_upgrade_toc{succ = false, reason=Reason},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).

do_transaction_equip_upgrade(RoleId,DataRecord,EquipGoods,
                             EquipInfo,NewEquipInfo,BaseRecord,
                             QualityRecord,ReinforceRecord,BindRecord,NewEquipGoods,Fee) ->
    case common_transaction:transaction(fun() -> 
            do_transaction_equip_upgrade2(RoleId,DataRecord,EquipGoods,
                                          EquipInfo,NewEquipInfo,BaseRecord,
                                          QualityRecord,ReinforceRecord,BindRecord,NewEquipGoods,Fee)
                        end) of
        {atomic,{ok,Equip,DelBaseList,UpdateBaseList, DelQualityList,
                 UpdateQualityList,DelReinList,UpdateReinList,
                 DelFiveList,UpdateFiveList,DelBindList,UpdateBindList}} ->
            {ok,Equip,DelBaseList,UpdateBaseList, DelQualityList,
             UpdateQualityList,DelReinList,UpdateReinList,
             DelFiveList,UpdateFiveList,DelBindList,UpdateBindList};
        {aborted, Reason} ->
            case Reason of 
                {throw,{error,R}} ->
                    erlang:throw({error,R});
                _ ->
                    ?DEBUG("~ts,Reason=~w",["装备升级失败",Reason]),
                    erlang:throw({error,?_LANG_EQUIP_CHANGE_U_EXCEPTION})
            end
    end.
do_transaction_equip_upgrade2(RoleId,DataRecord,_EquipGoods,
                                        _EquipInfo,NewEquipInfo,BaseRecord,
                                        QualityRecord,ReinforceRecord,BindRecord,NewEquipGoods,Fee) ->
    %% 扣费
    EquipConsume = #r_equip_consume{type = upgrade,
                                    consume_type = ?CONSUME_TYPE_SILVER_EQUIP_UPGRADE,
                                    consume_desc = ""},
    mod_refining:do_refining_deduct_fee(RoleId,Fee,EquipConsume),
    %% 扣费材料
    BagIdList = mod_equip_build:get_equip_build_bag_id(),
    BaseNumber = BaseRecord#r_equip_upgrade_base_material.number,
    BaseTypeId = DataRecord#m_equip_build_upgrade_tos.base_type_id,
    {DelBaseList,UpdateBaseList} = 
        case do_transaction_consume_goods(RoleId,BagIdList,BaseTypeId,BaseNumber) of
            {error,Error} ->
                ?DEBUG("~ts,Error=~w",["扣除基础材料出错",Error]),
                erlang:throw({error,Error});
            {ok,DBList,UBList} ->
                {DBList,UBList}
        end,
    {DelQualityList,UpdateQualityList} = 
        if QualityRecord =:= undefined ->
                {[],[]};
           true ->
                QualityNumber = QualityRecord#r_equip_upgrade_quality_material.number,
                QualityTypeId = DataRecord#m_equip_build_upgrade_tos.quality_type_id,
                case do_transaction_consume_goods(RoleId,BagIdList,QualityTypeId,QualityNumber) of
                    {error,QError} ->
                        ?DEBUG("~ts,Error=~w",["扣除保留品质材料出错",QError]),
                        erlang:throw({error,QError});
                    {ok,DQList,UQList} ->
                        {DQList,UQList}
                end
        end,
    {DelReinList,UpdateReinList} = 
        if ReinforceRecord =:= undefined ->
                {[],[]};
           true ->
                ReinNumber = ReinforceRecord#r_equip_upgrade_reinforce_material.number,
                ReinforceTypeId = DataRecord#m_equip_build_upgrade_tos.reinforce_type_id,
                case do_transaction_consume_goods(RoleId,BagIdList,ReinforceTypeId,ReinNumber) of
                    {error,RError} ->
                        ?DEBUG("~ts,Error=~w",["扣除保留强化材料出错",RError]),
                        erlang:throw({error,RError});
                    {ok,DRList,URList} ->
                        {DRList,URList}
                end
        end,
    {DelBindList,UpdateBindList} = 
        if BindRecord =:= undefined ->
                {[],[]};
           true ->
                BindNumber = BindRecord#r_equip_upgrade_bind_material.number,
                BindTypeId = DataRecord#m_equip_build_upgrade_tos.bind_attr_type_id,
                case do_transaction_consume_goods(RoleId,BagIdList,BindTypeId,BindNumber) of
                    {error,BError} ->
                        ?DEBUG("~ts,Error=~w",["扣除保留绑定属性材料出错",BError]),
                        erlang:throw({error,BError});
                    {ok,DBindList,UBindList} ->
                        {DBindList,UBindList}
                end
        end,
    do_transaction_equip_upgrade3(RoleId,NewEquipInfo,NewEquipGoods,DelBaseList,UpdateBaseList,
                                 DelQualityList,UpdateQualityList,DelReinList,UpdateReinList,
                                 DelBindList,UpdateBindList).
do_transaction_equip_upgrade3(RoleId,NewEquipInfo,NewEquipGoods,DelBaseList,UpdateBaseList,
                              DelQualityList,UpdateQualityList,DelReinList,UpdateReinList,
                              DelBindList,UpdateBindList) ->
    MatrailBind1 = do_check_matrail_bind(DelBaseList),
    MatrailBind2 = do_check_matrail_bind(UpdateBaseList),
    MatrailBind3 = do_check_matrail_bind(DelQualityList),
    MatrailBind4 = do_check_matrail_bind(UpdateQualityList),
    MatrailBind5 = do_check_matrail_bind(DelReinList),
    MatrailBind6 = do_check_matrail_bind(UpdateReinList),
    MatrailBind9 = do_check_matrail_bind(DelBindList),
    MatrailBind10 = do_check_matrail_bind(UpdateBindList),
    
    MatrailBind = 
        if MatrailBind1 orelse MatrailBind2
           orelse MatrailBind3
           orelse MatrailBind4
           orelse MatrailBind5
           orelse MatrailBind6
           orelse MatrailBind9
           orelse MatrailBind10 ->
                true;
           true ->
                false
        end,
    ?DEBUG("~ts,MatrailBind=~w",["装备升级时，材料是否是绑定的",MatrailBind]),
    do_transaction_equip_upgrade4(RoleId,NewEquipInfo,NewEquipGoods,DelBaseList,UpdateBaseList,
                                  DelQualityList,UpdateQualityList,DelReinList,UpdateReinList,
                                  DelBindList,UpdateBindList,MatrailBind).

do_transaction_equip_upgrade4(RoleId,NewEquipInfo,NewEquipGoods,DelBaseList,UpdateBaseList,
                              DelQualityList,UpdateQualityList,DelReinList,UpdateReinList,
                              DelBindList,UpdateBindList,MatrailBind) ->
    %% 新装备处理
    %% 颜色品质处理
    NewGoods = mod_refining:equip_colour_quality_add(new,NewEquipGoods,1,1,1),
    %% 强化处理
    NewGoods2 = equip_reinforce_property_add(NewGoods,NewEquipInfo),
    %% 宝石处理
    NewGoods3 = 
        if NewGoods2#p_goods.stones =/= undefined ->
                equip_stone_property_add(NewGoods2);
           true ->
                NewGoods2
        end,
    %% 绑定处理
    NewGoods4 = mod_refining_bind:do_equip_bind_for_equip_upgrade(NewGoods3,NewEquipInfo),
    ?DEBUG("~ts,EquipOld=~w,EquipNew=~w",["装备升级前后绑定属性处理结果",NewGoods3,NewGoods4]),
    %% 装备五行属性
    %% 材料绑定处理
    NewGoods5 =
        if MatrailBind ->
                case mod_refining_bind:do_equip_bind_for_upgrade(NewGoods4) of 
                    {error,BindErrorCode} ->
                        ?INFO_MSG("~ts,BindErrorCode",["装备升级时，当材料是绑定的，装备是不绑定时，处理绑定出错，只是做绑定处理，没有附加属性",BindErrorCode]),
                        NewGoods4#p_goods{bind=true};
                    {ok,BindGoods} ->
                        BindGoods
                end;
           true ->
                NewGoods4
        end,
    %% 精炼系数处理
    NewGoods6 = case common_misc:do_calculate_equip_refining_index(NewGoods5) of
                    {error,ErrorCode} ->
                        ?DEBUG("~ts,ErrorCode=~w",["计算装备精炼系数出错",ErrorCode]),
                        NewGoods5;
                    {ok,RefiningIndexGoods} ->
                        RefiningIndexGoods
                end,
    mod_bag:update_goods(RoleId,NewGoods6),
    {ok,NewGoods6,DelBaseList,UpdateBaseList, DelQualityList,
     UpdateQualityList,DelReinList,UpdateReinList,
     DelBindList,UpdateBindList}.
%% 装备分解
do_equip_decompose({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) ->
    case catch do_equip_decompose2({Unique,Module,Method,DataRecord, RoleId, Pid, Line}) of
        {error,Error} ->
            do_equip_decompose_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error);
        {ok,EquipGoods,EquipInfo} ->
            do_equip_decompose3({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods,EquipInfo)
    end.
do_equip_decompose2({_Unique,_Module,_Method,DataRecord, RoleId, _Pid, _Line}) ->
    EquipId = DataRecord#m_equip_build_decompose_tos.equip_id,
    EquipGoods = case get_dirty_goods_by_id(RoleId,EquipId) of
                     {ok,Equip} ->
                         Equip;
                     {error,Error} ->
                         ?DEBUG("~ts,Error=~w",["获取需要装备分解的数据出错",Error]),
                         erlang:throw({error,?_LANG_EQUIP_CHANGE_D_PARAM_ERROR})
                 end,
    TypeId = EquipGoods#p_goods.typeid,
    EquipInfo = 
        case common_config_dyn:find_equip(TypeId) of
            [EquipInfoT] ->
                EquipInfoT;
            _ ->
                erlang:throw({error,?_LANG_EQUIP_CHANGE_D_PARAM_ERROR})
        end,
	if EquipInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
            erlang:throw({error,?_LANG_EQUIP_CHANGE_D_MOUNT_ERROR,0});
       EquipInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
            erlang:throw({error,?_LANG_EQUIP_CHANGE_D_FASHION_ERROR,0});
       EquipInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
            erlang:throw({error,?_LANG_EQUIP_CHANGE_D_ADORN_ERROR,0});
       true ->
            next
    end,
    [SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
    case lists:member(EquipGoods#p_goods.typeid,SpecialEquipList) of
        true ->
            erlang:throw({error,?_LANG_EQUIP_CHANGE_D_ADORN_ERROR});
        _ ->
            next
    end,
	if EquipInfo#p_equip_base_info.material > 0 ->
            next;
       true ->
            erlang:throw({error,?_LANG_EQUIP_CHANGE_D_ADORN_ERROR})
    end,
    if erlang:is_integer(EquipGoods#p_goods.stone_num) 
       andalso EquipGoods#p_goods.stone_num > 0 ->
            ?DEBUG("~ts，STONE_NUM=~w",["装备不能分解，需要将宝石全部拆卸才能分解",EquipGoods#p_goods.stone_num]),
            erlang:throw({error,?_LANG_EQUIP_CHANGE_D_STONE_ERROR});
       true ->
            next
    end,
    Color = EquipGoods#p_goods.current_colour,
    MinColor = get_equip_decompose_min_color(),
    if Color >= MinColor ->
            next;
       true ->
            ?DEBUG("~ts,Color=~w,MinColor=~w",["装备颜色低于分解颜色最低值不可分解",Color,MinColor]),
            erlang:throw({error,?_LANG_EQUIP_CHANGE_D_COLOR})
    end,
    {ok,EquipGoods,EquipInfo}.
do_equip_decompose3({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods,EquipInfo) ->
	case catch mod_refining:get_refining_fee(equip_decompose_fee, EquipGoods) of
		{error,Error,0} ->
			?DEBUG("~ts,Error=~w",["计算装备分解费用时出错",Error]),
            do_equip_decompose_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error);
		Fee ->
			 do_equip_decompose4({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods,EquipInfo,Fee)
	end.
do_equip_decompose4({Unique,Module,Method,DataRecord, RoleId, Pid, Line},EquipGoods,EquipInfo,Fee) ->
    case catch do_t_equip_change_decompose(RoleId,DataRecord,EquipGoods,EquipInfo,Fee) of
        {error,Error} ->
            ?DEBUG("~ts,Error=~w",["装备分解出错",Error]),
            do_equip_decompose_error({Unique,Module,Method,DataRecord, RoleId, Pid, Line},Error);
        {ok,Reason,AddGoodsList,AddNumber} ->
            do_equip_decompose5({Unique,Module,Method,DataRecord, RoleId, Pid, Line},
                                EquipGoods,Reason,AddGoodsList,AddNumber)
    end.
do_equip_decompose5({Unique,Module,Method,_DataRecord, RoleId, _Pid, Line},
                    EquipGoods,Reason,AddGoodsList,AddNumber) ->
    SendSelf = #m_equip_build_decompose_toc{succ = true,reason =Reason},
    SendSelf2 = if AddGoodsList =:= [] ->
                     SendSelf;
                   true ->
                        [AddGoods] =  mod_equip_build:count_class_equip_build_goods(AddGoodsList,[]),
                        %% 道具消费日志
                        catch common_item_logger:log(RoleId,AddGoods#p_equip_build_goods.type_id,
                                                            AddNumber,
                                                     undefined,?LOG_ITEM_TYPE_ZHUANG_BEI_FEN_JIE_HUO_DE),
                        SendSelf#m_equip_build_decompose_toc{add_goods = AddGoods#p_equip_build_goods{current_num = AddNumber}}
                end,
    common_misc:unicast(Line,RoleId, Unique, Module, Method, SendSelf2),
    do_equip_chang_deduct_fee_notify(RoleId, Line),
    do_equip_decompose6(RoleId,Line,EquipGoods,AddGoodsList).

do_equip_decompose6(RoleId,Line,EquipGoods,AddGoodsList) ->
    UnicastArg = {line, Line, RoleId},
    if AddGoodsList =:= [] ->
            ignore;
       true ->
            common_misc:new_goods_notify(UnicastArg,AddGoodsList)
    end,
    %% 道具消费日志
    common_item_logger:log(RoleId,EquipGoods,?LOG_ITEM_TYPE_ZHUANG_BEI_FEN_JIE_SHI_QU),
    common_misc:del_goods_notify(UnicastArg,EquipGoods).
%% 装备分解事务操作
do_t_equip_change_decompose(RoleId,DataRecord,EquipGoods,EquipInfo,Fee) ->
     case common_transaction:transaction(fun() -> 
                                   do_t_equip_change_decompose2(RoleId,DataRecord,EquipGoods,EquipInfo,Fee)
                            end) of
        {atomic,{ok,Reason,AddGoodsList,AddNumber}} ->
            {ok,Reason,AddGoodsList,AddNumber};
        {aborted, Reason} ->
            case Reason of 
                {throw,{bag_error,BR}} ->
                    ?DEBUG("~ts,bag_error=~w",["装备分解背操作错误，装备分解失败",BR]),
                    case BR of
                        {not_enough_pos,_BagID} ->
                            erlang:throw({error,?_LANG_EQUIP_CHANGE_D_ERROR_BAG});
                        _ ->
                            erlang:throw({error,?_LANG_EQUIP_CHANGE_D_EXCEPTION})
                    end;
                {throw,{error,R}} ->
                    erlang:throw({error,R});
                _ ->
                    ?DEBUG("~ts,Reason=~w",["装备分解失败",Reason]),
                    erlang:throw({error,?_LANG_EQUIP_CHANGE_D_EXCEPTION})
            end
    end.
do_t_equip_change_decompose2(RoleId,DataRecord,EquipGoods,EquipInfo,Fee) ->
    %% 扣费
    EquipConsume = #r_equip_consume{type = decompose,
                                    consume_type = ?CONSUME_TYPE_SILVER_EQUIP_DECOMPOSE,
                                    consume_desc = ""},
    mod_refining:do_refining_deduct_fee(RoleId,Fee,EquipConsume),
    EquipMaterial = EquipInfo#p_equip_base_info.material,
    %%EquipLevel = EquipGoods#p_goods.level,
    EquipBind = EquipGoods#p_goods.bind,
    RefiningIndex = EquipGoods#p_goods.refining_index,
    ?DEBUG("~ts,RefiningIndex=~w",["分解的装备的精炼系数为",RefiningIndex]),
    {AddTypeId,AddNumber} = get_equip_change_decompose_add_item(EquipMaterial,RefiningIndex),
    %% 产生新物品
    if AddTypeId =:= 0 ->
            EquipId = DataRecord#m_equip_build_decompose_tos.equip_id,
            mod_bag:delete_goods(RoleId,EquipId),
            {ok,?_LANG_EQUIP_CHANGE_D_FAIL,[],0};
       true ->
            do_t_equip_change_decompose3(RoleId,DataRecord,EquipGoods,AddTypeId,AddNumber,EquipBind)
    end.
do_t_equip_change_decompose3(RoleId,DataRecord,_EquipGoods,AddTypeId,AddNumber,Bind) ->
    EquipId = DataRecord#m_equip_build_decompose_tos.equip_id,
    AddGoodsList = 
        if AddTypeId =/= 0 ->
                CreateInfo2 = #r_goods_create_info{bind=Bind, type=?TYPE_ITEM, type_id=AddTypeId, num=AddNumber},
                {ok,AddGoodsListT} = mod_bag:create_goods(RoleId,CreateInfo2),
                AddGoodsListT;
           true ->
                []
        end,
    mod_bag:delete_goods(RoleId,EquipId),
    {ok,?_LANG_EQUIP_CHANGE_D_SUCC,AddGoodsList,AddNumber}.

do_equip_decompose_error({Unique,Module,Method,_DataRecord, RoleId, _Pid, Line},Reason) ->
    SendSelf=#m_equip_build_decompose_toc{succ = false, reason=Reason},
    common_misc:unicast(Line,RoleId, Unique, Module, Method,SendSelf).

%% 根据物品id获取物品详细信息
get_dirty_goods_by_id(RoleId,GoodsId) ->
    BagIds = mod_equip_build:get_equip_build_bag_id(),
    mod_refining_bag:get_goods_by_bag_ids_and_goods_id(RoleId,BagIds,GoodsId).

%% 获取附加材料级别对应的装备品质记录
get_equip_change_quality_record(AddGoodsLevel) ->
    case common_config_dyn:find(equip_change,equip_build_change_quality) of
        [ List ] -> 
            [R || R <- List, 
                  R#r_equip_build_change_quality.item_level =:= AddGoodsLevel];
        _ -> 
            []
    end.
%% 装备品质级别不降低 3,优质
get_equip_change_quality_protect_level() ->
    case common_config_dyn:find(equip_change,equip_change_quality_protect_level) of
        [ Value ] -> 
            Value;
        _ -> 
            ?QUALITY_GOOD
    end.

%% 根据装备品质改概率计算造品质
get_equip_change_quality(AddGoodsLevel) ->
    case catch get_equip_change_quality2(AddGoodsLevel) of
        {ok,Quality,SubQuality} ->
            {Quality,SubQuality}
    end.
get_equip_change_quality2(AddGoodsLevel) ->
    [Record] = 
    case common_config_dyn:find(equip_change,equip_build_change_quality) of
        [ List ] -> 
            [R || R <- List, 
                  R#r_equip_build_change_quality.item_level =:= AddGoodsLevel];
        _ -> 
            erlang:throw({ok,?QUALITY_GENERAL,0})
    end,
    [MaxSubQuality] = common_config_dyn:find(refining,equip_change_quality_sub_max_level),
    #r_equip_build_change_quality{weight = WeightList} = Record,
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
%% 获取附加材料可提升的最高品质级别
get_equip_change_max_quality(AddGoodsLevel) ->
    case catch get_equip_change_max_quality2(AddGoodsLevel) of
        {ok, MaxQuality,MaxSubQuality} ->
            {MaxQuality,MaxSubQuality}
    end.
get_equip_change_max_quality2(AddGoodsLevel) ->
    [Record] = 
    case common_config_dyn:find(equip_change,equip_build_change_quality) of
        [ List ] -> 
            [R || R <- List, 
                  R#r_equip_build_change_quality.item_level =:= AddGoodsLevel];
        _ -> 
            erlang:throw({ok,?QUALITY_GENERAL,1})
    end,
    [MaxSubQuality] = common_config_dyn:find(refining,equip_change_quality_sub_max_level),
    #r_equip_build_change_quality{weight = WeightList} = Record,
    {SumQuality,_Index} = 
        lists:foldl(
          fun(Weight,{Acc,AccIndex}) ->
                  if Weight =/= 0 ->
                          {AccIndex,AccIndex + 1};
                     true ->
                          {Acc,AccIndex + 1}
                  end
          end,{0,1},WeightList),
    Quality = common_tool:ceil(SumQuality / MaxSubQuality),
    SubQuality = 
        case SumQuality rem MaxSubQuality of
            0 ->
                MaxSubQuality;
            SubQualityT ->
                SubQualityT
        end,
    erlang:throw({ok,Quality,SubQuality}).

    
%% 根据精炼系数获取装备可能分解到的附加材料
%% 返回值为：{ItemTypeId,ItemNumber}
%% 如果没有记录值为:{0,0}
get_equip_change_decompose_add_item(EquipMaterial,RefiningIndex) ->
    case catch get_equip_change_decompose_add_item2(RefiningIndex) of
        {ok,ItemLevel,ItemNum} ->
            case mod_equip_build:get_equip_build_goods(EquipMaterial,?EQUIP_BUILD_ADD,ItemLevel) of
                [] ->
                    {0,0};
                [Record] ->
                    {Record#r_equip_build_item.item_id,ItemNum}
            end
    end.

get_equip_change_decompose_add_item2(RefiningIndex) ->
    [Record] = 
        case common_config_dyn:find(equip_change,equip_decompose_add_material) of
            [ List ] -> 
                [R || R <- List, 
                      RefiningIndex >= R#r_equip_decompose_add_material.min_index,
                      RefiningIndex =< R#r_equip_decompose_add_material.max_index
                ];
            _ -> 
                erlang:throw({ok,0,0})
        end,
    #r_equip_decompose_add_material{item_0 = Item_0,item_1 = Item_1,
                                    item_2 = Item_2,item_3 = Item_3,
                                    item_4 = Item_4,item_5 = Item_5,
                                    item_6 = Item_6,number = Number} = Record,
    SumNumber = Item_0 + Item_1 + Item_2 + Item_3 + Item_4 + Item_5 + Item_6,
    RandomNumber = random:uniform(SumNumber),
    if Item_0 > 0 andalso RandomNumber =< Item_0 ->
            erlang:throw({ok, 0, 0});
       Item_1 > 0 andalso  RandomNumber >= (Item_0 + 1)
       andalso RandomNumber =< (Item_0 + Item_1) ->
            erlang:throw({ok,1,Number});
       Item_2 > 0 andalso  RandomNumber >= (Item_0 + Item_1 + 1)
       andalso RandomNumber =< (Item_0 + Item_1 + Item_2) ->
            erlang:throw({ok,2,Number});
       Item_3 > 0 andalso  RandomNumber >= (Item_0 + Item_1 + Item_2 + 1)
       andalso RandomNumber =< (Item_0 + Item_1 + Item_2 + Item_3) ->
            erlang:throw({ok,3,Number});
       Item_4 > 0 andalso  RandomNumber >= (Item_0 + Item_1 + Item_2 + Item_3 + 1)
       andalso RandomNumber =< (Item_0 + Item_1 + Item_2 + Item_3 + Item_4) ->
            erlang:throw({ok,4,Number});
       Item_5 > 0 andalso  RandomNumber >= (Item_0 + Item_1 + Item_2 + Item_3 + Item_4 + 1)
       andalso RandomNumber =< (Item_0 + Item_1 + Item_2 + Item_3 + Item_4 + Item_5) ->
            erlang:throw({ok,5,Number});
       Item_6 > 0 andalso  RandomNumber >= (Item_0 + Item_1 + Item_2 + Item_3 + Item_4 + Item_5 + 1)
       andalso RandomNumber =< (Item_0 + Item_1 + Item_2 + Item_3 + Item_4 + Item_5 + Item_6) ->
            erlang:throw({ok,6,Number});
       true ->
            erlang:throw({ok, 0, 0})
    end.

%% 扣除物品
%% 公用的扣除物品方法
%% Param RoleId 角色id
%%       BagIdList 背包id列表，即从什么背包时扣除物品
%%       TypeId 物品类型
%%       ItemNum 扣除数量
%% 成功返回 {ok,DelGoodsList,UpdateGoodsList}
%% DelGoodsList 删除的物品信息，UpdateGoodsList更新的物品信息
%% 失败抛出异常 
%% erlang:throw({error,Reason})
%% Reason可以直接给前端显示
do_transaction_consume_goods(RoleId,BagIdList,TypeId,ItemNum) ->
    GoodsList = 
        case mod_refining_bag:get_goods_by_bag_ids_and_type_id(RoleId,BagIdList,TypeId) of
            [] ->
                ?ERROR_MSG("~ts",["查询角色背包的打造附加材料时，为空"]),
                erlang:throw({error,?_LANG_EQUIP_BUILD_GOODS_ENOUGH});
            List when erlang:is_list(List) ->
                List
        end,
    do_transaction_consume_goods2(RoleId,BagIdList,TypeId,ItemNum,GoodsList).
do_transaction_consume_goods2(RoleId,_BagIdList,TypeId,ItemNum,GoodsList) ->
    case GoodsList of
        [] ->
            ?ERROR_MSG("~ts,ItemId=~w",["角色没有打造所需要的材料",TypeId]),
            erlang:throw({error,?_LANG_EQUIP_BUILD_GOODS_ENOUGH});
        _ ->
            GoodsSum = mod_equip_build:get_goods_sum(GoodsList,0),
            ?DEBUG("~ts,GoodsSumNumber=~w,ItemNumber=~w",["物品总数量",GoodsSum,ItemNum]),
            NewNum = GoodsSum - ItemNum,
            if  NewNum =:= 0 ->
                    %%此物品已经没有，必须删除
                    DeleteGoodsIds = [GoodsRecord#p_goods.id || GoodsRecord <- GoodsList],
                    mod_bag:delete_goods(RoleId,DeleteGoodsIds),
                    {ok,GoodsList,[]};
                NewNum > 0 ->
                    %%更新物品信息
                    {ok,DelList,UpdateList} = mod_equip_build:do_transaction_dedcut_goods(RoleId,GoodsList,ItemNum),
                    {ok,DelList,UpdateList};
                true ->
                    ?ERROR_MSG("~ts,ItemId=~w",["角色打造所需要的材料数量不够",TypeId]),
                    erlang:throw({error,?_LANG_EQUIP_BUILD_GOODS_ENOUGH})
            end
    end.
%% 从扣除的材料中判断材料是否是绑定的
do_check_matrail_bind(MaterialGoodsList) ->
    if erlang:is_list(MaterialGoodsList) ->
            if  MaterialGoodsList =:= [] ->
                    false;
                true ->
                    do_check_matrail_bind2(MaterialGoodsList)
            end;
       true ->
            false
    end.
do_check_matrail_bind2(MaterialGoodsList) ->  
    BindList = lists:filter(fun(Goods) ->
                                    Goods#p_goods.bind
                            end,MaterialGoodsList),
    if BindList =:= [] ->
            false;
       true ->
           true
    end. 
            
%% 扣费通知
do_equip_chang_deduct_fee_notify(RoleId, Line) ->
    UnicastArg = {line, Line, RoleId},
    case mod_map_role:get_role_attr(RoleId) of
        {ok, RoleAttr} ->
            AttrChangeList = [#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value = RoleAttr#p_role_attr.silver},
                              #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value = RoleAttr#p_role_attr.silver_bind}],
            common_misc:role_attr_change_notify(UnicastArg,RoleId,AttrChangeList);
        {error ,R} ->
            ?ERROR_MSG("~ts,Reason=~w",["获取角色属性出错，装备改造失败之后无法通知前端钱币变化情况",R])
    end.

%% 获取装备分解装备颜色最低级别
get_equip_decompose_min_color() ->
    case common_config_dyn:find(equip_change,equip_decompose_color_min_level) of
        [ Color ] -> 
            Color;
        _ -> 
           ?DEFAULT_EQUIP_DECOMPOSE_COLOR_MIN_LEVEL
    end.


% 根据装备类型id和装备升级链表数据获取装备升级的类型id
get_next_equip_type_id(TypeId,LinkList) ->
    RsList = lists:map(fun(SubList) ->
                               get_next_equip_type_id2(TypeId,SubList)
                       end,LinkList),
    NewRsList = [R || R <- RsList,R =/= 0,R =/= -1],
    if NewRsList =:= [] ->
            NewRsList1 =[R1 || R1 <- RsList,R1 =/= 0],                
            if NewRsList1 =:= [] ->
                    0; %% 在装备升级配置中查找不到
               true ->
                    -1 %% 装备不能升级
            end;
       true ->
            if erlang:length(NewRsList) =:= 1 ->
                    [NextTypeId] = NewRsList,
                    NextTypeId; %% 装备升级新的装备类型id
               true ->
                    -2 %% 装备升级配置出错
            end
    end.
get_next_equip_type_id2(TypeId,LinkList) ->
    Index = get_next_equip_type_id3(LinkList,TypeId,false,0),
    if Index =:= 0 ->
            0;
       true ->
            {_List1,List2} = lists:split(Index, LinkList),
            if List2 =:= [] ->
                    -1;
               true ->
                    [H|_T] = List2,
                    H
            end
    end.
get_next_equip_type_id3([],_TypeId,_Flag,Index) ->           
    Index;
get_next_equip_type_id3(_,_TypeId,true,Index) ->
    Index;
get_next_equip_type_id3([H|T],TypeId,Flag,Index) ->
    NewIndex = Index + 1,
    if H =:= TypeId ->
            get_next_equip_type_id3(T,TypeId,true,NewIndex);
       true ->
            get_next_equip_type_id3(T,TypeId,Flag,NewIndex)
    end.


%% 装备强化属性处理
equip_reinforce_property_add(EquipGoods,EquipBaseInfo) ->
    EquipPro = EquipGoods#p_goods.add_property,
    BasePro = EquipBaseInfo#p_equip_base_info.property,
    MainProperty = BasePro#p_property_add.main_property,
    ReinforceRate = EquipGoods#p_goods.reinforce_rate,
    NewEquipPro=mod_refining:change_main_property(MainProperty,EquipPro,BasePro,0,ReinforceRate),
    EquipGoods#p_goods{add_property = NewEquipPro}.
%% 宝石加成处理
equip_stone_property_add(EquipGoods) ->
    Stones = EquipGoods#p_goods.stones,
    equip_stone_property_add2(Stones,EquipGoods).
equip_stone_property_add2([],EquipGoods) ->
    EquipGoods;
equip_stone_property_add2([H|T],EquipGoods) ->
    StoneTypeId = H#p_goods.typeid,
    {ok,StoneBaseInfo} = mod_stone:get_stone_baseinfo(StoneTypeId),
    NewEquipGoods = equip_stone_property_add3(StoneBaseInfo,EquipGoods),
    equip_stone_property_add2(T,NewEquipGoods).

equip_stone_property_add3(StoneBaseInfo,EquipGoods) ->
    EquipPro = EquipGoods#p_goods.add_property,
    StoneBasePro = StoneBaseInfo#p_stone_base_info.level_prop,
    SeatList =
        case equip_stone_property_add4(StoneBasePro#p_property_add.main_property) of
            SeatR when is_integer(SeatR) andalso SeatR > 1 ->
                [SeatR];
            SeatR when is_list(SeatR) ->
                SeatR;
            _ ->
                ?INFO_MSG("~ts,EquipGoods=~w,StoneBaseInfo=~w",["装备升级时，处理宝石数据遇到不可处理的宝石数据",EquipGoods,StoneBaseInfo]),
                []
        end,
    NewEquipPro = lists:foldl(
                    fun(Seat,AccPro) ->
                            Value = erlang:element(Seat, AccPro) + erlang:element(Seat,StoneBasePro),
                            erlang:setelement(Seat, AccPro, Value)
                    end,EquipPro,SeatList),
    EquipGoods#p_goods{add_property = NewEquipPro}.
equip_stone_property_add4(Main) ->
    [List] = common_config_dyn:find(refining,main_property),
    proplists:get_value(Main, List).


get_dirty_goods(RoleId,TypeIdList,BagIdList) ->
    mod_refining_bag:get_goods_by_bag_ids_and_type_ids(RoleId,BagIdList,TypeIdList).
   
%% 装备强化材料类型id
get_equip_reinforce_material() ->
    case common_config_dyn:find(equip_change,equip_reinforce_material) of
        [ List ] -> 
            [R#r_equip_reinforce_material.type_id || R <- List];
        _ -> 
           []
    end.

%% 装备升级根据条件重新获取装备的品质
%% Flag 是否选择保留品质
%% EquipGoods p_goods
%% 返回 Quality
get_equip_quality_by_upgrade(Flag,EquipGoods) ->
    #p_goods{quality=Quality, current_colour=Color} = EquipGoods,

    if
        Flag =:= true ->
            EquipGoods#p_goods.quality;

        Quality > ?QUALITY_GENERAL andalso Color =:= ?COLOUR_WHITE  ->
            EquipGoods#p_goods.quality - 1;

        Quality > ?QUALITY_WELL ->
            EquipGoods#p_goods.quality - 1;

        true ->
            EquipGoods#p_goods.quality
    end.

%% 根据升级操作重新获取装备的强化属性
%% Flag 是否选择保留强化属性
%% EquipGoods p_goods
%% 返回结果为 {ReinforceResult,ReinforceRate,ReinforceResultList}
get_equip_reinforce_by_upgrade(_Flag,EquipGoods) ->
    ReinforceResultList = 
        case EquipGoods#p_goods.reinforce_result_list of
            undefined ->
                [];
            _ ->
                EquipGoods#p_goods.reinforce_result_list
        end,
    {EquipGoods#p_goods.reinforce_result, 
     EquipGoods#p_goods.reinforce_rate,ReinforceResultList}.

%% 装备升级时根据条件重新获取装备绑定属性
%% Flag 是否选择保留绑定属性
%% 返回 p_goods
get_equip_bind_attr_by_upgrade(Flag,NewGoods,EquipGoods,NewEquipInfo) ->
    case Flag of
        true ->
            NewGoods#p_goods{equip_bind_attr=EquipGoods#p_goods.equip_bind_attr};
        false ->
            EquipBindAttr = EquipGoods#p_goods.equip_bind_attr,
            if erlang:is_list(EquipBindAttr)
               andalso erlang:length(EquipBindAttr) > 0 ->
                    %% 没有选择保留绑定属性，重新按一定的概率生成绑定属性
                    mod_refining_bind:do_equip_rebind_for_equip_upgrade(NewGoods,NewEquipInfo);
               true ->
                    NewGoods
            end
            %% NewGoods#p_goods{equip_bind_attr = EquipGoods#p_goods.equip_bind_attr}
    end.
