%%% -------------------------------------------------------------------
%%% Author  : xierongfeng
%%% Description : 玩家装备模块
%%%
%%% Created : 2013-5-21
%%% -------------------------------------------------------------------
-module (mod_role_equip).

-include("mgeer.hrl").

-define(_common_error,	?DEFAULT_UNIQUE,	?COMMON,	?COMMON_ERROR,		#m_common_error_toc).%}
-define(_equip_load,	?DEFAULT_UNIQUE,	?EQUIP,		?EQUIP_LOAD,		#m_equip_load_toc).%}
-define(_equip_unload,	?DEFAULT_UNIQUE,	?EQUIP, 	?EQUIP_UNLOAD, 		#m_equip_unload_toc).%}
-define(_equip_del,		?DEFAULT_UNIQUE,	?EQUIP, 	?EQUIP_DEL, 		#m_equip_del_toc).%}

-export([handle/1, calc/2, calc/5, calc/3, 
	update_role_base/5, update_role_base/3, equip_attrs/3, recalc/2,check_equip_category/3]).

handle({_Unique, ?EQUIP, ?EQUIP_LOAD, DataRecord, RoleID, PID, _Line}) ->
    #m_equip_load_tos{equipid = EquipID} = DataRecord,
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    case check_equip_load(RoleID, EquipID, RoleAttr) of
    	{ok, EquipGoodsInfo, EquipBase} ->
			case do_load_equip(RoleID, EquipGoodsInfo, EquipBase, RoleAttr, RoleBase) of
				{atomic, {ok, LoadEquip, EquipInBag}} ->
					mod_role_event:notify(RoleID, {?ROLE_EVENT_EQUIP_PUT, LoadEquip}),
					common_misc:unicast2(PID, ?_equip_load{equip1 = LoadEquip, equip2 = EquipInBag});
				{aborted, {bag_error, {not_enough_pos, _BagID}}} ->
					common_misc:unicast2(PID, ?_common_error{error_str = ?_LANG_EQUIP_BAG_FULL});
            	Error ->
            		?ERROR_LOG("role put on equip error: ~p", [Error])
            end;
		{error, Msg} ->
			common_misc:unicast2(PID, ?_common_error{error_str = Msg})
	end;

handle({_Unique, ?EQUIP, ?EQUIP_UNLOAD, DataRecord, RoleID, PID, _Line}) ->
	#m_equip_unload_tos{equipid = EquipID, bagid = BagID, position = Pos} = DataRecord,
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	case do_unload_equip(RoleID, EquipID, BagID, Pos, RoleAttr, RoleBase) of
		{atomic, {ok, SlotNum, UnloadEquip}} ->
			common_misc:unicast2(PID, ?_equip_unload{equip = UnloadEquip}), 
			common_misc:unicast2(PID, ?_equip_del{slot_nums = [SlotNum]});
		{aborted, {bag_error, {not_enough_pos, _BagID}}} ->
			common_misc:unicast2(PID, ?_common_error{error_str = ?_LANG_EQUIP_BAG_FULL});
    	Error ->
            ?ERROR_LOG("role take off equip error: ~p", [Error])
    end.

check_equip_load(RoleID, EquipID, RoleAttr) ->
	case mod_bag:check_inbag(RoleID, EquipID) of
		{ok, EquipGoods = #p_goods{typeid = TypeID, type = ?TYPE_EQUIP}} -> 
			[EquipBase] = common_config_dyn:find_equip(TypeID),
			CheckList   = [
				fun check_equip_map/3,
				fun check_equip_state/3, 
				fun check_equip_time/3, 
				fun check_equip_category/3,
				fun check_equip_req/3
			],
			Result = lists:foldl(fun
				(_Check, {error, Msg}) ->
					{error, Msg};
				(Check, _) ->
					Check(EquipGoods, EquipBase, RoleAttr)
			end, true, CheckList),
			case Result of
				{error, Msg} -> 
					{error, Msg};
				_Others ->
					{ok, EquipGoods, EquipBase}
			end;
		_ -> 
			{error, <<"非法操作">>}
	end.

check_equip_map(_EquipGoods, _EquipBase, _RoleAttr) ->
	not mod_spring:is_in_spring_map() orelse {error, <<"温泉中不能更换装备">>}.

check_equip_state(EquipGoods, #p_equip_base_info{equipname = EquipName}, _RoleAttr) ->
	EquipGoods#p_goods.state == ?GOODS_STATE_NORMAL orelse
		{error, common_misc:format_lang(?_LANG_EQUIP_IS_LOCKED, [EquipName])}.

check_equip_time(EquipGoods, _EquipBase, _RoleAttr) ->
	#p_goods{start_time = StartTime, end_time = EndTime} = EquipGoods,
	NowTime = common_tool:now(),
	if
		(StartTime =:= 0 orelse StartTime =< NowTime),
		(EndTime   =:= 0 orelse EndTime   >= NowTime) ->
			true;
		true ->
			{error, ?_LANG_EQUIP_NOT_IN_USE_TIME}
	end.

check_equip_category(_EquipGoods, 
	#p_equip_base_info{slot_num = SlotNum, kind = Kind}, #p_role_attr{category = Category}) ->
	if
		SlotNum          /= ?PUT_ARM;
		{Kind, Category} == {100,0};
		{Kind, Category} == {101,1};
		{Kind, Category} == {102,2};
		{Kind, Category} == {103,3};
		{Kind, Category} == {104,4} ->
			true;
		true ->
			{error, ?_LANG_EQUIP_CATEGORY_DO_NOT_MEET}
	end.

check_equip_req(_EquipGoods, #p_equip_base_info{requirement = EquipReq}, RoleAttr) ->
	#p_use_requirement{
		min_level       = ReqMinLevel,
		max_level       = ReqMaxLevel,
		min_jingjie     = ReqMinJingjie,
		vip_level_limit = ReqVipLimit,
		category_limit  = ReqCategoryLimit
	} = EquipReq,
	#p_role_attr{
		role_id         = RoleID,
		level           = RoleLevel,
		jingjie         = RoleJingjie,
		category        = RoleCategory
	} = RoleAttr,
	if
		ReqVipLimit > 0 ->
			RoleVipLevel = mod_vip:get_role_vip_level(RoleID),
			RoleVipLevel >= ReqVipLimit orelse {error,?_LANG_EQUIP_VIP_DO_NOT_MEET};
		RoleLevel < ReqMinLevel; RoleLevel > ReqMaxLevel ->
            {error, ?_LANG_EQUIP_LEVEL_DO_NOT_MEET};
        RoleJingjie < ReqMinJingjie ->
            {error, ?_LANG_EQUIP_JINGJIE_DO_NOT_MEET};  
		ReqCategoryLimit == 1 ->
			RoleCategory == 1 orelse RoleCategory == 2  
				orelse {error,?_LANG_EQUIP_CATEGORY_LIMIT_DO_NOT_MEET};
		ReqCategoryLimit == 2 ->
			RoleCategory == 3 orelse RoleCategory == 4  
				orelse {error,?_LANG_EQUIP_CATEGORY_LIMIT_DO_NOT_MEET};
		true ->
			true
	end.

do_load_equip(RoleID, EquipGoodsInfo, EquipBase, RoleAttr1, RoleBase1) ->
	SlotNum   = EquipBase#p_equip_base_info.slot_num,
	EquipKind = EquipBase#p_equip_base_info.kind,
	OldSkin   = RoleAttr1#p_role_attr.skin,
	OldEquips = RoleAttr1#p_role_attr.equips,
	LoadEquip = EquipGoodsInfo#p_goods{
		loadposition = SlotNum, 
		bagposition  = 0, 
		bagid        = 0,
		bind         = true
	},
	{UnloadEquip, NewEquips} = case lists:keytake(SlotNum, #p_goods.loadposition, OldEquips) of
    	false ->
    		{undefined, [LoadEquip|OldEquips]};
    	{value, OldEquip, OldEquips2} ->
    		{mod_equip_suit:deactivate(OldEquip),  [LoadEquip|OldEquips2]}
    end,
	{ok, NewEquips2, ActivateSuit} = mod_equip_suit:update(OldEquips, NewEquips),
    case SlotNum of
    	?PUT_ARM ->
			RoleBase2 = RoleBase1#p_role_base{weapon_type = EquipKind},
			NewSkin   = OldSkin#p_skin{weapon = LoadEquip#p_goods.typeid};
		_ ->
			RoleBase2 = RoleBase1,
			NewSkin	  = OldSkin
	end,
	LoadEquip2 = lists:keyfind(SlotNum, #p_goods.loadposition, NewEquips2),
	RoleAttr2  = RoleAttr1#p_role_attr{skin = NewSkin, equips = NewEquips2},
    common_transaction:t(fun() ->
		{ok, [EquipInBag]} = update_bag(RoleID, EquipGoodsInfo, UnloadEquip),
		mod_map_role:set_role_attr(RoleID, RoleAttr2),
		RoleBase3 = ActivateSuit(RoleBase2),
		RoleBase4 = mod_equip_buff:calc(RoleBase3, '-', UnloadEquip, '+', LoadEquip),
		update_role_base(RoleBase4, '-', UnloadEquip, '+', LoadEquip),
		{ok, LoadEquip2, EquipInBag}
    end).

do_unload_equip(RoleID, EquipID, BagID, Pos, RoleAttr1, RoleBase1) ->
	UnloadEquip = lists:keyfind(EquipID, #p_goods.id, RoleAttr1#p_role_attr.equips),
	SlotNum     = UnloadEquip#p_goods.loadposition,
	OldSkin     = RoleAttr1#p_role_attr.skin,
	OldEquips   = RoleAttr1#p_role_attr.equips,
	NewEquips   = lists:keydelete(SlotNum, #p_goods.loadposition, OldEquips),
	{ok, NewEquips2, ActivateSuit} = mod_equip_suit:update(OldEquips, NewEquips),
	case SlotNum of
		?PUT_ARM ->
			RoleBase2 = RoleBase1#p_role_base{weapon_type = 0},
			NewSkin   = OldSkin#p_skin{weapon = 0};
		_ ->
			RoleBase2 = RoleBase1,
			NewSkin   = OldSkin
	end,
	RoleAttr2 = RoleAttr1#p_role_attr{skin = NewSkin, equips = NewEquips2},
    common_transaction:t(fun() ->
    	UnloadEquip2 = mod_equip_suit:deactivate(UnloadEquip),
		{ok, [UnloadEquip3]} = case BagID of
	        0 ->
	            mod_bag:create_goods_by_p_goods_and_id(RoleID, UnloadEquip2);
	        _ ->
	            mod_bag:create_goods_by_p_goods_and_id(RoleID, BagID, Pos, UnloadEquip2)
	    end,
		mod_map_role:set_role_attr(RoleID, RoleAttr2),
		RoleBase3 = ActivateSuit(RoleBase2),
		RoleBase4 = mod_equip_buff:calc(RoleBase3, '-', UnloadEquip3),
		update_role_base(RoleBase4, '-', UnloadEquip3),
	    {ok, SlotNum, UnloadEquip3}
    end).

update_role_base(RoleID, Op1, Equip1, Op2, Equip2) when is_integer(RoleID) ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	update_role_base(RoleBase, Op1, Equip1, Op2, Equip2);
update_role_base(RoleBase, Op1, Equip1, Op2, Equip2) when is_record(RoleBase, p_role_base) ->
	mod_role_attr:reload_role_base(calc(RoleBase, Op1, Equip1, Op2, Equip2)).

update_role_base(RoleID, Op, Equip) when is_integer(RoleID) ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	update_role_base(RoleBase, Op, Equip);
update_role_base(RoleBase, Op, Equip) when is_record(RoleBase, p_role_base) ->
	mod_role_attr:reload_role_base(calc(RoleBase, Op, Equip)).

calc(RoleBase, OpList) ->
	Transform = transformer(RoleBase#p_role_base.role_id),
	lists:foldl(fun
		({Op, Equip}, RoleBaseAcc) ->
			calc2(RoleBaseAcc, Transform, Op, Equip)
	end, RoleBase, OpList).

calc(RoleBase, Op1, Equip1, Op2, Equip2) -> 
	Transform = transformer(RoleBase#p_role_base.role_id),
	calc2(calc2(RoleBase, Transform, Op1, Equip1), Transform, Op2, Equip2).

calc(RoleBase, Op, Equip) ->
	calc2(RoleBase, transformer(RoleBase#p_role_base.role_id), Op, Equip).

calc2(RoleBase, Transform, Op, Equip) ->
	mod_role_attr:calc(RoleBase, Op, Transform(Equip)).

transformer(RoleID) ->
	{ok, Jinglian} = mod_jinglian:get_jinglian_info(RoleID),
	fun
		(Equip) when is_record(Equip, p_goods) -> 
			SlotNum = case Equip#p_goods.loadposition > 0 of
				true ->
					Equip#p_goods.loadposition;
				false ->
					[EquipBase] = common_config_dyn:find_equip(Equip#p_goods.typeid),
					EquipBase#p_equip_base_info.slot_num
			end,
			equip_attrs(SlotNum, Jinglian, Equip);
		(_) -> []
	end.

update_bag(RoleID, LoadEquip = #p_goods{bagid = BagID, bagposition = Pos}, UnloadEquip) ->
	mod_bag:delete_goods(RoleID, LoadEquip#p_goods.id),
	if
		is_record(UnloadEquip, p_goods) ->
			UnloadEquip2 = UnloadEquip#p_goods{
				loadposition = 0,
				bagid        = 0,
				bagposition  = 0,
				state        = ?GOODS_STATE_NORMAL
			},
			mod_bag:create_goods_by_p_goods_and_id(RoleID, BagID, Pos, UnloadEquip2);
		true ->
			{ok, [LoadEquip#p_goods{id=0}]}
	end.

equip_attrs(SlotNum, Jinglian, #p_goods{
			state             = ?GOODS_STATE_NORMAL,
			add_property      = Prop1, 
			current_endurance = Endurance }) when Endurance > 0 ->
	Prop2 = mod_jinglian:calc_equip_second_attr(Jinglian, SlotNum, Prop1),
	mod_role_attr:transform(Prop2);
equip_attrs(_SlotNum, _Jinglian, _) -> [].

recalc(RoleBase, RoleAttr) ->
	RoleID = RoleBase#p_role_base.role_id,
	#p_role_attr{equips = Equips} = RoleAttr,
	Transform = transformer(RoleID),
	RoleBase2 = lists:foldl(fun(Equip, RoleBaseAcc) ->
		calc2(RoleBaseAcc, Transform, '+', Equip)
	end, RoleBase, Equips),
	RoleBase2.