% Author: liuwei
%% Created: 2010-5-13
%% Description: TODO: Add description to mod_goods
-module(mod_goods).

-include("mgeem.hrl").
-include("refining.hrl").

-export([
         handle/1,
         pick_dropthing/3,
         t_drop_goods/6,
         get_dirty_equip_by_id/2,
         get_equip_by_id/2,
		 get_equip_by_typeid/2
        ]).

%%
%% API Functions
%%

handle({Unique, ?GOODS, Method, DataRecord, RoleID, PID, Line}) ->
    case Method of
        ?GOODS_INFO ->
            do_get(Unique, ?GOODS, Method, DataRecord, RoleID,Line);
        ?GOODS_SWAP ->
            do_swap(Unique, ?GOODS, Method, DataRecord, RoleID,Line);
        ?GOODS_INBAG_LIST ->
            do_list(Unique, ?GOODS, Method, DataRecord, RoleID, Line);
        ?GOODS_DESTROY ->
            do_destroy(Unique, ?GOODS, Method, DataRecord, RoleID, Line);
        ?GOODS_DIVIDE ->
            do_divide(Unique, ?GOODS, Method, DataRecord, RoleID, Line);
        ?GOODS_TIDY ->           
            do_tidy(Unique, ?GOODS, Method, DataRecord, RoleID, Line);
        ?GOODS_SHOW_GOODS ->
            do_show_goods(Unique, ?GOODS, Method, DataRecord, RoleID, PID, Line);
        _ ->
            nil
    end;

handle({get_goods_info, RoleID, TargetID, GoodsID, Type, Line, Unique}) ->
    do_get_goods_info(RoleID, TargetID, GoodsID, Type, Line, Unique);
                    
handle(Info) ->
    ?ERROR_MSG("mod_goods, unknow info: ~w", [Info]).

t_change_goods_owner({RoleID, GoodsID})
  when is_integer(RoleID) , is_integer(GoodsID) ->
    {ok,Info} = mod_refining_bag:get_drop_goods(GoodsID),
    NewInfo = Info#p_goods{roleid = RoleID, state=?GOODS_STATE_NORMAL},
    t_change_goods_owner({RoleID, NewInfo});
t_change_goods_owner({RoleID, GoodsInfo})
  when is_integer(RoleID), is_record(GoodsInfo, p_goods) ->
    #p_goods{type = Type,typeid = TypeId,bind=Bind,current_num = Number} = GoodsInfo,
    case Type of
        ?TYPE_EQUIP ->
            {ok,[NewInfo]} = mod_bag:create_goods_by_p_goods(RoleID,GoodsInfo),
            {NewInfo,GoodsInfo};
        ?TYPE_ITEM ->
            [BaseInfo] = common_config_dyn:find_item(TypeId),
            if BaseInfo#p_item_base_info.is_overlap =:= 2->
                    {ok,[NewInfo]} = mod_bag:create_goods_by_p_goods(RoleID,GoodsInfo),
                    {NewInfo,GoodsInfo};
               true ->
                    CreateInfo = #r_goods_create_info{bind=Bind, type=?TYPE_ITEM, type_id=TypeId, num=Number},
                    {ok,[NewInfo]} = mod_bag:create_goods(RoleID,CreateInfo),
                    {NewInfo,GoodsInfo}
            end;
        ?TYPE_STONE ->
            CreateInfo2 = #r_goods_create_info{bind=Bind, type=?TYPE_STONE, type_id=TypeId, num=Number},
            {ok,[NewInfo]} = mod_bag:create_goods(RoleID,CreateInfo2),
            {NewInfo,GoodsInfo};
        Reason ->
            common_transaction:aobrt(Reason)
    end.

%% @doc 获取指定角色、ID物品信息
do_get(Unique, Module, Method, DataIn, RoleID, Line) ->
    #m_goods_info_tos{target_id=TargetID} = DataIn,
    case common_misc:is_role_online(TargetID) of
        true ->
            get_online_role_goods_info(Unique, Module, Method, DataIn, RoleID, Line);
        false ->
            get_offline_role_goods_info(Unique, Module, Method, DataIn, RoleID, Line)
    end.

get_online_role_goods_info(Unique, Module, Method, DataIn, RoleID, Line) ->
    #m_goods_info_tos{id=GoodsID, target_id=TargetID, type=Type} = DataIn,
    case mod_bag:get_goods_by_id(TargetID, GoodsID) of
        {error, _} ->
            case get_equip_by_id(TargetID, GoodsID) of
                {error, _} ->
                    %% 发送到指定角色所在地图
                    mgeer_role:send(TargetID, {mod_goods, {get_goods_info, RoleID, TargetID, GoodsID, Type, Line, Unique}});
                {ok, GoodsInfo} ->
                    do_get_unicast(Unique, Module, Method, RoleID, Line, GoodsInfo, Type)
            end;
        {ok, GoodsInfo} ->
            do_get_unicast(Unique, Module, Method, RoleID, Line, GoodsInfo, Type)
    end.
    
get_offline_role_goods_info(Unique, Module, Method, DataIn, RoleID, Line) ->
    %% 查找下线玩家的信息
    #m_goods_info_tos{id=GoodsID, target_id=TargetID, type=Type} = DataIn,
    case mod_bag:get_dirty_goods_by_id(TargetID, GoodsID) of
        {ok, GoodsInfo} ->
            do_get_unicast(Unique, Module, Method, RoleID, Line, GoodsInfo, Type);
        {error, _} ->
            case get_dirty_equip_by_id(TargetID, GoodsID) of
                {error, _} ->
                    ignore;
                {ok, GoodsInfo} ->
                    do_get_unicast(Unique, Module, Method, RoleID, Line, GoodsInfo, Type)
            end
    end.

do_get_unicast(Unique, Module, Method, RoleID, Line, GoodsInfo, Type) ->
    DataRecord = #m_goods_info_toc{info=GoodsInfo, type=Type, goods_id=GoodsInfo#p_goods.id},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, DataRecord).

do_swap(Unique, Module, Method, DataRecord, RoleID,Line) ->
    #m_goods_swap_tos{id1=GoodsID, position2=Position2, bagid2=BagID2} = DataRecord,
    case mod_bag:check_inbag(RoleID, GoodsID) of
        {ok, GoodsInfo} ->
            case mod_bag:check_bags_times_up(GoodsInfo#p_goods.bagid,BagID2,RoleID,Position2) of
                true->
                    case db:transaction(
                           fun() ->
                                   mod_bag:swap_goods(GoodsID, Position2, BagID2, RoleID)
                           end)
                        of
                        {atomic, {ok, none, Goods2}} ->
                            hook_prop:hook(create, [Goods2]),
                            Data = #m_goods_swap_toc{succ=true, goods1=GoodsInfo#p_goods{id=0}, goods2=Goods2};
                        {atomic, {ok, Goods1, Goods2}} ->
                            hook_prop:hook(create, [Goods1]),
                            hook_prop:hook(create, [Goods2]),
                            Data = #m_goods_swap_toc{succ=true, goods1=Goods1, goods2=Goods2};
                        {aborted, Error} ->
                            ?ERROR_MSG("do_swap, error: ~w", [Error]),
                            Data = #m_goods_swap_toc{succ=false, reason=?_LANG_SYSTEM_ERROR}
                    end;
                false->
                    Data = #m_goods_swap_toc{succ=false,reason=?_LANG_ITEM_MOVE_EXTAND_BAG_TIMES_UP}
            end;
        _ ->
            Data = #m_goods_swap_toc{succ=false, reason=?_LANG_SYSTEM_ERROR}
    end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, Data).
    
do_list(Unique, Module, Method, DataRecord, RoleID, Line) ->
    #m_goods_inbag_list_tos{bagid=BagID} = DataRecord, 

    GoodsList =  mod_refining_bag:get_goods_by_bag_id(RoleID, BagID),
    Data = #m_goods_inbag_list_toc{bagid=BagID, goods=GoodsList},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, Data).

%%@doc 丢弃物品
do_destroy(Unique, Module, Method, DataRecord, RoleID, Line) ->
    #m_goods_destroy_tos{id=GoodID} = DataRecord,
    case db:transaction(
           fun() ->
                   t_destroy_good(GoodID, RoleID)
           end)
        of
        {aborted, Reason} when is_binary(Reason)->
            Data = #m_goods_destroy_toc{succ = false,reason = Reason};
        {aborted, Reason} ->
            ?ERROR_MSG("destroy_goods transaction fail, reason = ~p", [Reason]),
            Data = #m_goods_destroy_toc{succ = false,reason = ?_LANG_SYSTEM_ERROR};
        {atomic, {ok, GoodsID,GoodsInfo}} ->
            catch do_log_destroy_item(RoleID,GoodsInfo),
            hook_prop:hook(decreate, [GoodsInfo]),
            %% add by caochuncheng 玩家商贸商票销毁处理
            catch mod_trading:hook_drop_trading_bill_item(RoleID,GoodsInfo#p_goods.typeid),
            %%catch mod_educate_fb:hook_role_drop_goods(RoleID,GoodsInfo),
            Data = #m_goods_destroy_toc{succ = true,id = GoodsID};
        {atomic, {ok, GoodsID, _NewSkin, GoodsInfo,use_equip}} ->
            hook_prop:hook(decreate, [GoodsInfo]),
            Data = #m_goods_destroy_toc{succ = true,id = GoodsID}
    end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, Data).

do_show_goods(Unique, Module, Method, DataIn, RoleID, PID, Line) ->
    #m_goods_show_goods_tos{goods_id=GoodsID} = DataIn,

    case mod_bag:check_inbag(RoleID, GoodsID) of
        {ok, GoodsInfo} ->
            do_show_goods2(Unique, Module, Method, PID, RoleID, GoodsInfo, DataIn, Line);
        {error, _} ->
            {ok, #p_role_attr{equips=Equips}} = mod_map_role:get_role_attr(RoleID),
            case lists:keyfind(GoodsID, #p_goods.id, Equips) of
                false ->
                    do_show_goods_error(Unique, Module, Method, ?_LANG_GOODS_NOT_IN_BAG, PID);
                GoodsInfo ->
                    do_show_goods2(Unique, Module, Method, PID, RoleID, GoodsInfo, DataIn, Line)
            end
    end,
    ok.

do_show_goods2(Unique, Module, Method, PID, RoleID, GoodsInfo, DataIn, Line) ->
    try
        ChatPName = common_misc:chat_get_role_pname(RoleID),
        case global:whereis_name(ChatPName) of
            undefined ->
                do_show_goods_error(Unique, Module, Method, ?_LANG_SYSTEM_ERROR, PID);
            RPID ->
                case global:whereis_name(mgeec_goods_cache) of
                    undefined ->
                        do_show_goods_error(Unique, Module, Method, ?_LANG_SYSTEM_ERROR, PID);
                    CPID ->
                        {ok, #p_role_base{role_name=RoleName, sex=Sex}} = mod_map_role:get_role_base(RoleID),

                        #p_goods{type=Type, typeid=TypeID} = GoodsInfo,
                        case Type of
                            ?TYPE_ITEM ->
                                {ok, #p_item_base_info{itemname=GoodsName}} = mod_item:get_item_baseinfo(TypeID);
                            ?TYPE_STONE ->
                                {ok, #p_stone_base_info{stonename=GoodsName}} = mod_stone:get_stone_baseinfo(TypeID);
                            _ ->
                                {ok, #p_equip_base_info{equipname=GoodsName}} = mod_equip:get_equip_baseinfo(TypeID)
                        end,

                        %% 缓存该物品
                        CPID ! {insert_goods, RoleID, RoleName, Sex, GoodsName, GoodsInfo, DataIn, RPID, PID, Unique, Line, self()}
                end
        end
    catch
        _:E ->
            ?ERROR_MSG("do_show_goods2, error: ~w", [E]),
            do_show_goods_error(Unique, Module, Method, ?_LANG_SYSTEM_ERROR, PID)
    end.
            

do_show_goods_error(Unique, Module, Method, Reason, PID) ->
    DataRecord = #m_goods_show_goods_toc{succ=false, reason=Reason},
    common_misc:unicast2(PID, Unique, Module, Method, DataRecord).

t_destroy_good(GoodsID, RoleID) ->
    case mod_bag:check_inbag(RoleID, GoodsID) of
        {ok, GoodsInfo} ->
            case GoodsInfo#p_goods.state of
                ?GOODS_STATE_IN_STALL->
                    db:abort(<<"放在摊位中的物品不能丢弃">>);
                _ ->
                    next
            end,
            [CanNotDropList] = common_config_dyn:find(item_special, can_not_drop_list),
            case lists:member(GoodsInfo#p_goods.typeid, CanNotDropList) of
                true ->
                     db:abort(?_LANG_ITEM_CAN_NOT_DROP);
                false ->
                    next
            end,
            mod_bag:delete_goods(RoleID, GoodsID),
            %% add by caochuncheng 添加商贸hook
            mod_trading:hook_t_drop_trading_bill_item(RoleID,GoodsInfo#p_goods.typeid),
            {ok, GoodsID,GoodsInfo};
        _ ->
            t_destroy_good2(GoodsID, RoleID)
     end.
t_destroy_good2(GoodsID, RoleID) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    EquipList = RoleAttr#p_role_attr.equips,

    case lists:keyfind(GoodsID, #p_goods.id, EquipList) of
        false ->
            db:abort(?_LANG_GOODS_NOT_IN_BAG);
        EquipInfo ->
            EquipList2 = lists:keydelete(GoodsID, #p_goods.id, EquipList),
            RoleAttr2 = RoleAttr#p_role_attr{equips=EquipList2},

            {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
            SlotNum = EquipInfo#p_goods.loadposition,
            RoleBase2 = mod_equip:cut_weapon_type(SlotNum, RoleBase),
            {ok, RoleAttr3, Skin} = 
                mod_equip:get_role_skin_change_info(RoleAttr2, SlotNum, EquipInfo#p_goods.typeid),
            mod_map_role:set_role_attr(RoleID, RoleAttr3),
            mod_map_role:set_role_base(RoleID, RoleBase2),

            {ok, GoodsID, Skin,EquipInfo, use_equip}
    end.

do_divide(Unique, Module, Method, DataRecord, RoleID,Line) ->
    #m_goods_divide_tos{id = GoodsID, num = DivideNum, 
                        bagid = BagID, bagposition = NewPosition} = DataRecord,
    
    if
        is_integer(DivideNum) andalso DivideNum>0 andalso DivideNum<?MAX_USE_NUM ->
            case db:transaction(
                   fun() ->
                           t_divide_goods(GoodsID, DivideNum, BagID, NewPosition, RoleID)
                   end)
                of
                {aborted, Reason} when is_binary(Reason)->
                    Data = #m_goods_divide_toc{succ = false, reason = Reason};
                {aborted, Reason} ->
                    ?ERROR_MSG("do_divide, error: ~w", [Reason]),
                    Data = #m_goods_divide_toc{succ = false, reason = ?_LANG_SYSTEM_ERROR};
                {atomic, {ok, Goods1,Goods2}} -> 
                    Data = #m_goods_divide_toc{succ = true,  goods1 = Goods1, goods2 = Goods2}
            end;
        true->
            Data = #m_goods_divide_toc{succ=false, reason=?_LANG_GOODS_SPLIT_ILLEGAL_NUM}
    end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, Data).

t_divide_goods(GoodsID, DivideNum, BagID, NewPosition, RoleID) ->
    mod_bag:divide_goods(GoodsID, DivideNum, NewPosition, BagID, RoleID).

%%玩家捡物品
pick_dropthing(DropThing,Unique,RoleID) ->
    GoodsID = DropThing#p_map_dropthing.goodsid,
    case (is_integer(GoodsID) andalso GoodsID > 0) of
        true ->
            %% 此物品一般是打死玩家，玩家掉落的，此物品拾取不需要创建p_goods
            %% 只需修改p_goods
            pick_dropthing2(DropThing,Unique,RoleID);
        false ->
            %% 一般的怪物掉落的物品处理，需要创建此物品
            pick_dropthing3(DropThing,Unique,RoleID)
    end.

%% 此物品一般是打死玩家，玩家掉落的，此物品拾取不需要创建p_goods
%% 只需修改p_goods
pick_dropthing2(DropThing,Unique,RoleID) ->
    #p_map_dropthing{id=ID,goodsid = GoodsID} = DropThing,
    ?DEBUG("~ts,GoodsID=~w",["掉落物品已经创建，拾取时只需修改相关信息", GoodsID]),
    {Result,Data} = 
        case common_transaction:transaction(
               fun() -> 
                       t_change_goods_owner({RoleID,GoodsID}) 
               end) of
            {atomic, {NewInfo,OldInfo}} ->
                pick_goods_log([NewInfo#p_goods{current_num=OldInfo#p_goods.current_num}]),
                ?DEBUG("~ts,RoleID=~w,Goods=~w",["玩家获取到的物品信息昿",RoleID,NewInfo]),
				mgeem_map:send({mod_map_drop, {pick_dropthing_return, true, DropThing, RoleID}}),
                hook_prop:hook(create, [NewInfo]),
                %% add by caochuncheng 2010-12-09 添加拾取物品通知队员消息
                ?TRY_CATCH(do_pick_dropthing_notify(RoleID, NewInfo#p_goods{current_num=OldInfo#p_goods.current_num}),Err1),
                %% add by caochuncheng 2011-04-21 添加场景大战拾取物品世界通知
                ?TRY_CATCH(do_pick_dropthing_world_notify(RoleID,NewInfo#p_goods{current_num=OldInfo#p_goods.current_num}),Err2),
                %%catch do_destroy_item_logger(RoleID,NewInfo),
                %% 从掉落物列表中删掉该物品
                mod_refining_bag:delete_drop_goods(OldInfo#p_goods.id),
                {ok,#m_map_dropthing_pick_toc{succ = true, goods = NewInfo, num=OldInfo#p_goods.current_num, dropthingid = ID}};
            {aborted, {throw, {bag_error, {not_enough_pos,_BagID}}}} ->
				mgeem_map:send({mod_map_drop, {pick_dropthing_return, false, DropThing, RoleID}}),
                {error, pick_dropthing_error(ID, ?_LANG_DROPTHING_BAG_FULL)};
			{aborted,{bag_error,not_enough_pos}}->
				mgeem_map:send({mod_map_drop, {pick_dropthing_return, false, DropThing, RoleID}}),
                {error, pick_dropthing_error(ID, ?_LANG_DROPTHING_BAG_FULL)};
            {aborted, Reason} ->
                ?ERROR_MSG("~ts,DropThing=~w,Unique=~w,RoleID=~w,Reason=~w",["获取怪物掉落物品失败",DropThing,Unique,RoleID,Reason]),
				mgeem_map:send({mod_map_drop, {pick_dropthing_return, false, DropThing, RoleID}}),
				{error, pick_dropthing_error(ID,Reason)}
        end,
    common_misc:unicast({role,RoleID}, Unique, ?MAP,?MAP_DROPTHING_PICK, Data),
    Result.


pick_dropthing3(DropThing,Unique,RoleID) ->
    #p_map_dropthing{id=ID,num=Num} = DropThing,
    ?DEBUG("~ts,DropThing=~w",["掉落物品还没有创建，拾取时需要创建此物品相关信息",DropThing]),
    {Result,Data} = 
        case common_transaction:transaction(
               fun() -> 
                       t_creat_drop_goods(RoleID,DropThing) 
               end) of
            {aborted, {bag_error, {not_enough_pos,_BagID}}} ->
				mgeem_map:send({mod_map_drop, {pick_dropthing_return, false, DropThing, RoleID}}),
                {error, pick_dropthing_error(ID, ?_LANG_DROPTHING_BAG_FULL)};
            {aborted, Reason}->
                ?ERROR_MSG("~ts,DropThing=~w,Unique=~w,RoleID=~w,Reason=~w",["获取怪物掉落物品失败",DropThing,Unique,RoleID,Reason]),
				mgeem_map:send({mod_map_drop, {pick_dropthing_return, false, DropThing, RoleID}}),
				{error,pick_dropthing_error(ID,Reason)};
            {atomic, Info} ->
                pick_goods_log([Info#p_goods{current_num=Num}]),
				mgeem_map:send({mod_map_drop, {pick_dropthing_return, true, DropThing, RoleID}}),
                hook_prop:hook(create, [Info]),
                %% add by caochuncheng 2010-12-09 添加拾取物品通知队员消息
                ?TRY_CATCH(do_pick_dropthing_notify(RoleID, Info#p_goods{current_num=Num}),Err1),
                %% add by caochuncheng 2011-04-21 添加场景大战拾取物品世界通知
                ?TRY_CATCH(do_pick_dropthing_world_notify(RoleID,Info#p_goods{current_num=Num}),Err2),
                %%catch do_destroy_item_logger(RoleID,Info),
                ?TRY_CATCH(do_pick_boss_dropthing_notify(RoleID,Info),Err3),
                {ok,#m_map_dropthing_pick_toc{succ = true, goods = Info, num=Num, dropthingid = ID}}
        end,
    common_misc:unicast({role,RoleID}, Unique, ?MAP,?MAP_DROPTHING_PICK,Data),
    Result.


pick_dropthing_error(ID, Reason)when is_binary(Reason) ->
    #m_map_dropthing_pick_toc{succ = false, reason = Reason, dropthingid = ID};
pick_dropthing_error(ID,_Reason) ->
    #m_map_dropthing_pick_toc{succ = false, reason = ?_LANG_SYSTEM_ERROR, dropthingid = ID}.

%%@doc 记录拾取物品的道具日志
pick_goods_log(GoodsList) ->
	MapID = mgeem_map:get_mapid(),
	BombMapId = cfg_bomb_fb:map_id(),
	LogType = 
		case MapID =:= BombMapId of
			true ->
				?LOG_ITEM_TYPE_BOMB_SHI_QU_HUO_DE;
			_ ->
				?LOG_ITEM_TYPE_SHI_QU_HUO_DE
		end,
	lists:foreach(
	  fun(Goods) ->
			  #p_goods{roleid=RoleID}=Goods,
			  common_item_logger:log(RoleID,Goods,LogType)
	  end,GoodsList).


t_creat_drop_goods(RoleID,DropThing)
  when is_record(DropThing,p_map_dropthing) ->
    #p_map_dropthing{num = Num,goodstype = Type,bind = Bind,
                     goodstypeid = TypeID,drop_property = DropProperty} = DropThing,
    case t_creat_drop_goods2(RoleID,Type,TypeID,Num,DropProperty,Bind) of
        {ok, Info} ->
			Info;
        {error, Reason} ->
            common_transaction:abort(Reason)
    end.

t_creat_drop_goods2(RoleID,Type,TypeID,Num,DropProperty,Bind)
  when is_record(DropProperty,p_drop_property) ->
    ?DEBUG("~ts:[~w]~n",["the drop good type picked is", Type]),
    case Type of
        ?TYPE_ITEM ->
            CreateInfo = #r_goods_create_info{bind=Bind, type=?TYPE_ITEM, type_id=TypeID, num=Num, use_pos = []},
            {ok,[NewInfo]} = mod_bag:create_goods(RoleID,CreateInfo),
            {ok,NewInfo};
        ?TYPE_STONE ->
            CreateInfo2 = #r_goods_create_info{bind=Bind, type=?TYPE_STONE, type_id=TypeID, num=Num},
            {ok,[NewInfo]} = mod_bag:create_goods(RoleID,CreateInfo2),
            {ok,NewInfo};
        ?TYPE_EQUIP  ->
            t_creat_drop_goods3(RoleID, Type, TypeID, Num, DropProperty);
        Error ->
            common_transaction:abort(Error)
    end.

t_creat_drop_goods3(RoleID, Type, TypeID, Num, DropProperty) ->
	[BaseInfo] = common_config_dyn:find_equip(TypeID),
	{Quality,SubQuality} = mod_refining_tool:get_equip_quality_by_color(DropProperty#p_drop_property.colour),
	NewGoods = #p_goods{
						   type = Type,
						   roleid = RoleID,
						   typeid = TypeID,
						   start_time= 0,
						   end_time = 0,
						   current_num = Num,
						   sell_type = BaseInfo#p_equip_base_info.sell_type,
						   sell_price = BaseInfo#p_equip_base_info.sell_price,
						   name = BaseInfo#p_equip_base_info.equipname,
						   level =(BaseInfo#p_equip_base_info.requirement)#p_use_requirement.min_level, 
						   loadposition = 0,
						   current_endurance = BaseInfo#p_equip_base_info.endurance,
						   add_property=BaseInfo#p_equip_base_info.property,
						   endurance = BaseInfo#p_equip_base_info.endurance,
						   bind=DropProperty#p_drop_property.bind,
						   use_bind=1,
						   current_colour=DropProperty#p_drop_property.colour,
						   quality=Quality,sub_quality = SubQuality,quality_rate = 0,
						   punch_num=DropProperty#p_drop_property.hole_num,
						   reinforce_rate=0,reinforce_result=0,reinforce_result_list=[],
						   stones=[],
						   equip_bind_attr = [],
						   exp = 0,
						   next_level_exp = 0},
	{ok,[NewGood2]} = mod_bag:create_goods_by_p_goods(RoleID,NewGoods),
	{ok,NewGood2}.
%% --------------------------------------------------------------------
%%背包整理
%% --------------------------------------------------------------------

do_tidy(Unique, Module, Method, DataRecord, RoleID, Line) ->
    #m_goods_tidy_tos{bagid = BagID} = DataRecord, 

    case db:transaction(fun() -> t_dity_bag(RoleID,BagID) end) of
        {aborted, Reason} ->
            ?ERROR_MSG("get_goods transaction fail, reason = ~p", [Reason]),
            Data = #m_goods_tidy_toc{bagid = BagID, goods=[]};
        {atomic, {ok, GoodsList}} ->
            Data = #m_goods_tidy_toc{bagid = BagID, goods = GoodsList}
    end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, Data).

t_dity_bag(RoleID,BagID) ->
    mod_bag:tidy_bag(RoleID, BagID).

t_drop_goods([], UpdateList, DelList, DropThingList, RoleAttr, RoleBase) ->
    {UpdateList, DelList, DropThingList, RoleAttr, RoleBase};
t_drop_goods([H|T], UpdateList, DelList, DropThingList, RoleAttr, RoleBase) ->
    %% 构造掉落物信息
    #p_goods{roleid=RoleID, bagid=BagID, current_num=CurrentNum}=H,
    %% 数量大于5的物品，最多只能掉落5个
    case CurrentNum > ?MAX_DROP_NUM of
        true ->
            DropNum = ?MAX_DROP_NUM,
            UpdateList2 = [H#p_goods{current_num=CurrentNum-DropNum}|UpdateList],
            DelList2 = DelList;
        _ ->
            DropNum = CurrentNum,
            UpdateList2 = UpdateList,
            DelList2 = [H|DelList]
    end,
    %% 构造掉落物信息
    GoodsId = mod_refining_bag:get_drop_goods_max_id(),
    DropGoods = #p_map_dropthing{
          roles = [],
          num = DropNum,
          goodsid = GoodsId,
          colour = H#p_goods.current_colour,
          goodstype = H#p_goods.type,
          goodstypeid = H#p_goods.typeid,
          drop_property = #p_drop_property {
                             bind = H#p_goods.bind,
                             colour = H#p_goods.current_colour,
                             quality = H#p_goods.quality,
                             hole_num = H#p_goods.punch_num
                           }
     },
    %% 放进掉落物列表 
    NewGoods = H#p_goods{id=GoodsId, roleid=-100, bagid=0, bagposition=0, loadposition=0, current_num=DropNum},
    mod_refining_bag:put_drop_goods(GoodsId,NewGoods),
    %% 身上跟背包的东西不同处理
    case BagID =:= 0 of
        true ->
            %%更新角色属性
            Equips = RoleAttr#p_role_attr.equips,
            Equips2 = lists:keydelete(H#p_goods.id, #p_goods.id, Equips),
            RoleAttr2 = RoleAttr#p_role_attr{equips=Equips2},
            
            SlotNum = H#p_goods.loadposition,
            RoleBase2 = mod_equip:cut_weapon_type(SlotNum, RoleBase),
            {ok,RoleAttr3,_} =
                mod_equip:get_role_skin_change_info(RoleAttr2, SlotNum, 0);
        false ->
            %% 背包里面东西的话则需要将位子置空
            case DropNum =:= CurrentNum of
                true ->
                    mod_bag:delete_goods(RoleID, H#p_goods.id),
                    hook_prop:hook(decreate, [H]);
                _ ->
                    mod_bag:update_goods(RoleID, H#p_goods{current_num=CurrentNum-DropNum})
            end,
            RoleAttr3 = RoleAttr,
            RoleBase2 = RoleBase
    end,
    t_drop_goods(T, UpdateList2, DelList2, [DropGoods|DropThingList], RoleAttr3, RoleBase2).
%% add by caochuncheng 2011-04-21 添加场景大战拾取物品世界通知
do_pick_dropthing_world_notify(RoleId,Goods) ->
    case mod_scene_war_fb:get_sw_fb_dict(mgeem_map:get_mapid()) of
        undefined ->
            ok;
        _ ->
            case Goods#p_goods.current_colour >= ?COLOUR_BLUE of
                true ->
                    mod_scene_war_fb:hook_role_pick_dropthing(RoleId,Goods);
                false ->
                    ok
            end
    end.

%% 拾取世界boss掉落的物品世界广播
do_pick_boss_dropthing_notify(_RoleID,#p_goods{name=_Name,current_colour=_Color}) ->
	ok.
%% 	case common_config_dyn:find(dynamic_monster,boss_group_mapid_list) of
%% 		[BossMapIDList] ->
%% 			MapID = mgeem_map:get_mapid(),
%% 			case lists:member(MapID, BossMapIDList) andalso Color >= ?COLOUR_PURPLE of
%% 				true ->
%% 					{ok,#p_role_attr{role_name=RoleName}} = mod_map_role:get_role_attr(RoleID),
%% 					{ok,#p_role_base{faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
%% 					?WORLD_CHAT_BROADCAST(common_misc:format_lang(?_LANG_BOSS_GROUP_PICK_DROPTHING_NOTIFY,
%% 																  [common_misc:get_role_name_color(RoleName,FactionID),
%% 																   common_map:get_map_str_name(MapID),
%% 																   common_misc:format_goods_name_colour(Color,Name)]));
%% 				false ->
%% 					nil
%% 			end;
%% 		_ ->
%% 			nil
%% 	end.
%% add by caochuncheng 2010-12-09 添加拾取物品通知队员消息
do_pick_dropthing_notify(RoleId,Goods) ->
    ?DEBUG("~ts,RoleId=~w,Goods=~w",["玩家拾取物品信息",RoleId,Goods]),
    if Goods#p_goods.current_colour >= ?COLOUR_GREEN ->
            do_pick_dropthing_notify2(RoleId,Goods);
       true ->
            TypeId = Goods#p_goods.typeid,
            case common_config_dyn:find(drop_goods_notify,TypeId) of
                [1] ->
                    do_pick_dropthing_notify2(RoleId,Goods);
                _ ->
                    ignore
            end
    end.
do_pick_dropthing_notify2(RoleId,Goods) ->
    case mod_map_actor:get_actor_mapinfo(RoleId,role) of
        undefined ->
            ignore;
        MapRoleInfo ->
            ?DEBUG("~ts,MapRoleInfo=~w",["玩家拾取物品信息",MapRoleInfo]),
            if MapRoleInfo#p_map_role.team_id =/= 0 ->
                    do_pick_dropthing_notify3(RoleId,Goods,MapRoleInfo);
               true ->
                    ignore
            end
    end.
do_pick_dropthing_notify3(RoleId,Goods,MapRoleInfo) ->
    RoleIdList = common_misc:team_get_team_member(RoleId),
    ?DEBUG("~ts,RoleIdList=~w",["玩家拾取物品信息，队员信息",RoleIdList]),
    if RoleIdList =/= [] ->
            do_pick_dropthing_notify4(RoleId,Goods,MapRoleInfo,RoleIdList);
       true ->
            ignore
    end.
do_pick_dropthing_notify4(_RoleId,Goods,MapRoleInfo,RoleIdList) ->
    RoleName = common_tool:to_list(MapRoleInfo#p_map_role.role_name),
    GoodsName = common_goods:get_notify_goods_name(Goods),
    Message = lists:flatten(io_lib:format(?_LANG_DROPTHING_TEAM_MEMBER_MSG,[RoleName,GoodsName])),
    %% 只广播给队友
    TeamRoleIdList = lists:filter(fun(ID) -> ID =/= _RoleId end, RoleIdList), 
    catch common_broadcast:bc_send_msg_role(TeamRoleIdList,?BC_MSG_TYPE_SYSTEM,Message),
    ok.


%% 丢弃道具的日志信息
do_log_destroy_item(RoleId,Goods) ->
    common_item_logger:log(RoleId,Goods,?LOG_ITEM_TYPE_SHOU_DONG_DIU_QI).


%% @doc 查看角色身上是否有穿某件装备
get_equip_by_id(RoleID, EquipID) ->
    case mod_map_role:get_role_attr(RoleID) of
        {error, _} ->
            {error, role_not_found};
        {ok, RoleAttr} ->
            #p_role_attr{equips=Equips} = RoleAttr,

            case lists:keyfind(EquipID, #p_goods.id, Equips) of
                false ->
                    {error, equip_not_found};
                EquipInfo ->
                    {ok, EquipInfo}
            end
    end.

%% @doc 查看角色身上是否有穿某件装备
get_equip_by_typeid(RoleID, ItemTypeID) ->
    case mod_map_role:get_role_attr(RoleID) of
        {error, _} ->
            {error, role_not_found};
        {ok, RoleAttr} ->
            #p_role_attr{equips=Equips} = RoleAttr,

            case lists:keyfind(ItemTypeID, #p_goods.typeid, Equips) of
                false ->
                    {error, equip_not_found};
                EquipInfo ->
                    {ok, EquipInfo}
            end
    end.

%% @doc 查看角色身上是否有穿某件装备
get_dirty_equip_by_id(RoleID, EquipID) ->
    case common_misc:get_dirty_role_attr(RoleID) of
        {error, _} ->
            {error, role_not_found};
        {ok, RoleAttr} ->
            #p_role_attr{equips=Equips} = RoleAttr,

            case lists:keyfind(EquipID, #p_goods.id, Equips) of
                false ->
                    {error, equip_not_found};
                EquipInfo ->
                    {ok, EquipInfo}
            end
    end.

%% @doc 查询某玩家的某件物品
do_get_goods_info(RoleID, TargetID, GoodsID, Type, Line, Unique) ->
    case mod_bag:get_goods_by_id(TargetID, GoodsID) of
        {ok, GoodsInfo} ->
            DataRecord = #m_goods_info_toc{info=GoodsInfo, type=Type, goods_id=GoodsID};
        {error, _} ->
            case get_equip_by_id(TargetID, GoodsID) of
                {error, _} ->
                    DataRecord = do_get_goods_info2(TargetID, GoodsID, Type);
                {ok, GoodsInfo} ->
                    DataRecord = #m_goods_info_toc{info=GoodsInfo, type=Type, goods_id=GoodsID}
            end
    end,
    common_misc:unicast(Line, RoleID, Unique, ?GOODS, ?GOODS_INFO, DataRecord).

do_get_goods_info2(RoleID, GoodsID, Type) ->
    case mod_bag:get_dirty_goods_by_id(RoleID, GoodsID) of
        {ok, GoodsInfo} ->
            #m_goods_info_toc{info=GoodsInfo, type=Type, goods_id=GoodsID};
        {error, _} ->
            case get_dirty_equip_by_id(RoleID, GoodsID) of
                {ok, GoodsInfo} ->
                    #m_goods_info_toc{info=GoodsInfo, type=Type, goods_id=GoodsID};
                _ ->
                    #m_goods_info_toc{succ=false, reason=?_LANG_GOODS_NOT_IN_BAG, goods_id=GoodsID}
            end
    end.
