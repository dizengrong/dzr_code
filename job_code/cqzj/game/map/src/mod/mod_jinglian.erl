%%% @author fsk 
%%% @doc
%%%     装备精炼
%%% @end
%%% Created : 2012-10-11
%%%-------------------------------------------------------------------
-module(mod_jinglian).

-include("mgeem.hrl").

-export([
			jinglian/1,
			jinglian_info/1,
			calc_equip_second_attr/3,
			cast_jinglian_all/2,
			is_jinglian_put_id/1,
			jinglian_min_role_level/0,
			get_jinglian_info/1
		]).


-define(ERR_JINGLIAN_FULL_JINGLIAN_LEVEL,817001).%%精炼满级
-define(ERR_JINGLIAN_NOT_ENOUGH_LEVEL,817002).%%等级不足
-define(ERR_JINGLIAN_RATE_FAIL,817003).%%精炼概率性失败
-define(ERR_JINGLIAN_ERROR_PUT_ID,817004).%%装别部位错误

jinglian({Unique, Module, Method, DataIn, RoleID, PID}) ->
	#m_equip_jinglian_tos{put_id=PutID,auto_buy=AutoBuy,use_gold=UseGold} = DataIn,
	TransFun = fun
		()-> 
			t_jinglian(RoleID,PutID,AutoBuy,UseGold)
	end,
	case common_transaction:t( TransFun ) of
		{atomic, {ok,OldRoleJinglian,NewRoleJinglian,NewRoleAttr2,IsJinglianSucc,UpdateList,DeleteList,DeductGoodsDetail,CostGold}} ->
			common_misc:send_role_gold_change(RoleID,NewRoleAttr2),
			common_misc:del_goods_notify(PID,DeleteList),
			common_misc:update_goods_notify(PID,UpdateList),
			lists:foreach(fun
				({TypeID,Num}) ->
					?TRY_CATCH( common_item_logger:log(RoleID,TypeID,Num,undefined,?LOG_ITEM_TYPE_JINGLIAN_LOST) )
			end, DeductGoodsDetail),
			case IsJinglianSucc of
				true ->
					WholeJinglianLevel     = whole_jinglian_level(NewRoleJinglian),
					MaxFullJinglianLevel = cfg_jinglian:max_full_level(),
					case WholeJinglianLevel >= MaxFullJinglianLevel of
						true ->
							mod_achievement2:achievement_update_event(RoleID, 13003, 1);
						false ->
							ignore
					end,
					?UNICAST_TOC(#m_equip_jinglian_toc{
						p_jl                 = p_jinglian(NewRoleJinglian, PutID, NewRoleAttr2#p_role_attr.level),
						cost_gold            = CostGold,
						pjwa                 = p_jinglian_whole_attr(NewRoleJinglian),
						put_id               = PutID,
						whole_jinglian_level = WholeJinglianLevel
					}),
					case lists:keyfind(PutID, #p_goods.loadposition, NewRoleAttr2#p_role_attr.equips) of
						Equip when is_record(Equip, p_goods) ->
							{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
							OldEquipAttrs  = mod_role_equip:equip_attrs(PutID, OldRoleJinglian, Equip),
							NewEquipAttrs  = mod_role_equip:equip_attrs(PutID, NewRoleJinglian, Equip),
							NewRoleBase    = mod_role_attr:calc(RoleBase, '-', OldEquipAttrs, '+', NewEquipAttrs),
							mod_role_attr:reload_role_base(NewRoleBase);
						_ ->
							ignore
					end;
				false ->
					?UNICAST_TOC(#m_equip_jinglian_toc{err_code=?ERR_JINGLIAN_RATE_FAIL})
			end;
		{aborted, {error,ErrCode,Reason}} ->
			?UNICAST_TOC(#m_equip_jinglian_toc{err_code=ErrCode,reason=Reason});
		{aborted, Reason} ->
			?ERROR_MSG("jinglian error,Reason:~w",[Reason]),
			?UNICAST_TOC(#m_equip_jinglian_toc{err_code=?ERR_SYS_ERR})
	end.
t_jinglian(RoleID,PutID,AutoBuy,UseGold) ->
	{ok,#p_role_attr{level=RoleLevel}=RoleAttrTmp} = mod_map_role:get_role_attr(RoleID),
	assert_jinglian(RoleLevel,PutID),
	{ok, #r_jinglian{jinglian_puts=JinglianPuts}=RoleJinglian} = get_jinglian_info(RoleID),
	#p_jinglian{jinglian_level=JinglianLevel,max_jinglian_level=MaxJinglianLevel,
				base_succ_rate=BaseSuccRate,
				cost_item=CostItem,cost_item_num=CostItemNum} = p_jinglian(RoleJinglian,PutID,RoleLevel),
	case JinglianLevel >= MaxJinglianLevel of
		true ->
			?THROW_ERR(?ERR_JINGLIAN_FULL_JINGLIAN_LEVEL);
		false ->
			next
	end,
	case BaseSuccRate >= 100 of
		true ->
			RoleAttr = RoleAttrTmp,
			IsJinglianSucc = true;
		false ->
			OneGoldRate = cfg_jinglian:one_gold_add_rate(),
			GoldLimit = cfg_jinglian:rate_100_gold(),
			case is_integer(UseGold) andalso UseGold >= 0 andalso UseGold =< GoldLimit of
				true ->
					case UseGold =:= GoldLimit of
						true ->
							NewBaseSuccRate = 100;
						false ->
							NewBaseSuccRate = BaseSuccRate + OneGoldRate * UseGold
					end;
				false ->
					NewBaseSuccRate = 0,
					?ERROR_MSG("UseGold=~w",[UseGold]),
					?THROW_SYS_ERR()
			end,
			RoleAttr = RoleAttrTmp,

			common_bag2:check_money_enough_and_throw(gold_unbind, UseGold, RoleID), 
			IsJinglianSucc = (NewBaseSuccRate >= common_tool:random(1,100))
	end,
	MaterialList = [{CostItem,CostItemNum,_Color=0}],
	{DeductGoodsDetail,NeedCostGoldUnbind,NeedCostGoldAny} = mod_qianghua:get_deduct_goods_detail(RoleID,MaterialList),
	case (NeedCostGoldUnbind > 0 orelse NeedCostGoldAny > 0) andalso AutoBuy =:= false of
		true ->
			NeedCostGoldAny1 = 0,
			NewRoleAttr2 = DeleteList = UpdateList = null,
			throw({error,?ERR_MATERIAL_NOT_ENOUGH,NeedCostGoldUnbind+NeedCostGoldAny});
		false ->
			{ok,UpdateList,DeleteList} = mod_qianghua:t_deduct_material_goods(RoleID,DeductGoodsDetail),
			NeedCostGoldAny1 = NeedCostGoldAny,
			NeedCostGoldUnbind1 = NeedCostGoldUnbind + UseGold,
			if
				NeedCostGoldUnbind1 > 0 andalso NeedCostGoldAny1 > 0 ->
					common_bag2:check_money_enough_and_throw(NeedCostGoldAny1, NeedCostGoldUnbind1, RoleID);
				NeedCostGoldUnbind1 > 0 ->
					common_bag2:check_money_enough_and_throw(gold_unbind, NeedCostGoldUnbind1, RoleID);
				NeedCostGoldAny1 > 0 ->
					common_bag2:check_money_enough_and_throw(gold_any, NeedCostGoldAny1, RoleID);
				true -> ok
			end,
			NewRoleAttr2 = RoleAttr
	end,

	case IsJinglianSucc of
		true ->
			NewJinglianPuts = lists:keystore(PutID,#r_jinglian_put.put_id,JinglianPuts,#r_jinglian_put{put_id=PutID,jinglian_level=JinglianLevel+1}),
			NewRoleJinglian = RoleJinglian#r_jinglian{jinglian_puts=NewJinglianPuts},
			t_set_jinglian_info(RoleID,NewRoleJinglian);
		false ->
			NewRoleJinglian = RoleJinglian
	end,

	if
		NeedCostGoldUnbind > 0 andalso NeedCostGoldAny1 > 0 ->
			case common_bag2:t_deduct_money(NeedCostGoldAny1,NeedCostGoldUnbind,NewRoleAttr2,?CONSUME_TYPE_GOLD_EQUIP_REINFORCE_AUTO_BUY) of
				{ok,NewRoleAttr3}->
					next;
				{error,gold_unbind}->
					NewRoleAttr3 = NewRoleAttr2,
					?THROW_ERR(?ERR_GOLD_NOT_ENOUGH);
				{error, Reason1} ->
					NewRoleAttr3 = NewRoleAttr2,
					?THROW_ERR(?ERR_OTHER_ERR, Reason1)
			end;
		NeedCostGoldUnbind > 0 ->
			case common_bag2:t_deduct_money(gold_unbind,NeedCostGoldUnbind,NewRoleAttr2,?CONSUME_TYPE_GOLD_EQUIP_REINFORCE_AUTO_BUY) of
				{ok,NewRoleAttr3}->
					next;
				{error,gold_unbind}->
					NewRoleAttr3 = NewRoleAttr2,
					?THROW_ERR(?ERR_GOLD_NOT_ENOUGH);
				{error, Reason1} ->
					NewRoleAttr3 = NewRoleAttr2,
					?THROW_ERR(?ERR_OTHER_ERR, Reason1)
			end;
		NeedCostGoldAny1 > 0 ->
			case common_bag2:t_deduct_money(gold_any,NeedCostGoldAny1,NewRoleAttr2,?CONSUME_TYPE_GOLD_EQUIP_REINFORCE_AUTO_BUY) of
				{ok,NewRoleAttr3}->
					next;
				{error,gold_any}->
					NewRoleAttr3 = NewRoleAttr2,
					?THROW_ERR(?ERR_GOLD_NOT_ENOUGH);
				{error, Reason2} ->
					NewRoleAttr3 = NewRoleAttr2,
					?THROW_ERR(?ERR_OTHER_ERR, Reason2)
			end;
		true ->
			NewRoleAttr3 = NewRoleAttr2
	end,

	mod_map_role:set_role_attr(RoleID,NewRoleAttr3),
	{ok,RoleJinglian,NewRoleJinglian,NewRoleAttr3,IsJinglianSucc,UpdateList,DeleteList,DeductGoodsDetail,NeedCostGoldUnbind+NeedCostGoldAny+UseGold}.		

%% 查询精炼信息
jinglian_info({Unique, Module, Method, DataIn, RoleID, PID}) ->
	#m_equip_jinglian_info_tos{put_id=PutID} = DataIn,
	case catch check_jinglian_info(RoleID,PutID) of
		{ok,RoleLevel} ->
			{ok, RoleJinglian} = get_jinglian_info(RoleID),
			PJl = p_jinglian(RoleJinglian,PutID,RoleLevel),
			R2 = #m_equip_jinglian_info_toc{put_id=PutID,p_jl=PJl};
		_ ->
			R2 = #m_equip_jinglian_info_toc{err_code=?ERR_JINGLIAN_NOT_ENOUGH_LEVEL}
	end,
	?UNICAST_TOC(R2).

check_jinglian_info(RoleID,PutID) ->
	{ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	assert_jinglian(RoleLevel,PutID),
	{ok,RoleLevel}.

p_jinglian(RoleJinglian,PutID,RoleLevel) ->
	#r_jinglian{jinglian_puts=JinglianPuts} = RoleJinglian,
	JinglianLevel          = put_id_jinglian_level(PutID,JinglianPuts),
	MaxJinglianLevel       = cfg_jinglian:max_level(RoleLevel),
	MinRoleLevel           = cfg_jinglian:jinglian_max_level_to_role_min_level(MaxJinglianLevel),
	AttrAdd                = cfg_jinglian:add_attr(PutID, JinglianLevel),
	BaseSuccRate           = cfg_jinglian:up_rate(JinglianLevel),
	{CostItem,CostItemNum} = cfg_jinglian:up_cost(JinglianLevel),
	NextAttrAdd            = cfg_jinglian:add_attr(PutID, JinglianLevel + 1),
	#p_jinglian{
		jinglian_level     = JinglianLevel,
		max_jinglian_level = MaxJinglianLevel,
		min_role_level     = MinRoleLevel,
		attr_add           = AttrAdd,
		next_attr_add      = NextAttrAdd,
		base_succ_rate     = BaseSuccRate,
		cost_item          = CostItem,
		cost_item_num      = CostItemNum,
		put_id             = PutID
	}.

%% 玩家上线/等级变化推所有精炼属性
cast_jinglian_all(RoleID,RoleLevel) ->
	case RoleLevel >= jinglian_min_role_level() of
		true ->
			{ok, RoleJinglian} = get_jinglian_info(RoleID),
			AllPutWhere = cfg_jinglian:all_puts(),
			PJls = [p_jinglian(RoleJinglian,PutID,RoleLevel)||PutID<-AllPutWhere],
			R2 = #m_equip_jinglian_all_toc{
				p_jls                = PJls,
				whole_jinglian_level = whole_jinglian_level(RoleJinglian),
				pjwa                 = p_jinglian_whole_attr(RoleJinglian)
			},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EQUIP, ?EQUIP_JINGLIAN_ALL, R2);
		_ ->
			ignore
	end.

%% 当前全套精炼等级
whole_jinglian_level(RoleJinglian) ->
	AllPutWhere = cfg_jinglian:all_puts(),
	#r_jinglian{jinglian_puts=JinglianPuts} = RoleJinglian,
	AllJinglianLevel = [put_id_jinglian_level(PutID,JinglianPuts)||PutID<-AllPutWhere],
	lists:min(AllJinglianLevel).

p_jinglian_whole_attr(RoleJinglian) ->
	#r_jinglian{jinglian_puts=JinglianPuts}=RoleJinglian,
	% WholeJinglianLevel = whole_jinglian_level(RoleJinglian),
	[#p_jinglian_whole_attr{put_id=PutID, whole_attr = 0} ||#r_jinglian_put{put_id=PutID}<-JinglianPuts].


put_id_jinglian_level(PutID,JinglianPuts) ->
	case lists:keyfind(PutID, #r_jinglian_put.put_id, JinglianPuts) of
		false ->
			0;
		#r_jinglian_put{jinglian_level=JinglianLevel} ->
			JinglianLevel
	end.

	
assert_jinglian(RoleLevel,PutID) ->
	assert_role_level(RoleLevel),
	assert_put_id(PutID),
	ok.

is_jinglian_put_id(PutID) ->
	lists:member(PutID, cfg_jinglian:all_puts()).

jinglian_min_role_level() ->
	cfg_jinglian:open_level().
	
assert_put_id(PutID) ->
	case is_jinglian_put_id(PutID) of
		true ->
			ok;
		false ->
			?THROW_ERR(?ERR_JINGLIAN_ERROR_PUT_ID)
	end.

assert_role_level(RoleLevel) ->
	case RoleLevel >= jinglian_min_role_level() of
		true ->
			ok;
		false ->
			?THROW_ERR(?ERR_JINGLIAN_NOT_ENOUGH_LEVEL)
	end.

t_set_jinglian_info(RoleID, JinglianInfo) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,RoleExtInfo} ->
			NewRoleExtInfo = RoleExtInfo#r_role_map_ext{jinglian=JinglianInfo},
			mod_map_role:t_set_role_map_ext_info(RoleID, NewRoleExtInfo),
			ok;
		_ ->
			?ERROR_MSG("RoleID=~w, JinglianInfo=~w error",[RoleID, JinglianInfo]),
			?THROW_SYS_ERR()
	end.

get_jinglian_info(RoleID) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{jinglian=JinglianInfo}} ->
			{ok, JinglianInfo};
		_ ->
			{error, not_found}
	end.

%% 计算装备精炼二级属性
calc_equip_second_attr(RoleJinglian, SoltNum, EquipProp) when is_record(RoleJinglian, r_jinglian) ->
	#r_jinglian{jinglian_puts = JinglianPuts} = RoleJinglian,
	case put_id_jinglian_level(SoltNum,JinglianPuts) > 0 of
		true ->
			#r_jinglian{jinglian_puts = JinglianPuts} = RoleJinglian,
			JinglianLevel      = put_id_jinglian_level(SoltNum, JinglianPuts),
			PutAttrAdd         = cfg_jinglian:add_attr(SoltNum, JinglianLevel),
			WholeJinglianLevel = whole_jinglian_level(RoleJinglian),
			{WholeAtt, WholeHp, WholePDef, WholeMDef}  = cfg_jinglian:whole_add_attr(WholeJinglianLevel),
			#p_property_add{
				max_physic_att = MaxPhyAttack,
				min_physic_att = MinPhyAttack,
				max_magic_att  = MaxMagicAttack,
				min_magic_att  = MinMagicAttack,
				physic_def     = PhyDefence,
				magic_def      = MagicDefence,
				blood          = MaxHP
			} = EquipProp,
			EquipProp#p_property_add{
				max_physic_att = attr_add(MaxPhyAttack,PutAttrAdd) + WholeAtt,
				min_physic_att = attr_add(MinPhyAttack,PutAttrAdd) + WholeAtt,
				max_magic_att  = attr_add(MaxMagicAttack,PutAttrAdd) + WholeAtt,
				min_magic_att  = attr_add(MinMagicAttack,PutAttrAdd) + WholeAtt,
				physic_def     = attr_add(PhyDefence,PutAttrAdd) + WholePDef,
				magic_def      = attr_add(MagicDefence,PutAttrAdd) + WholeMDef,
				blood          = attr_add(MaxHP,PutAttrAdd) + WholeHp
			};
		_ ->
			EquipProp
	end;
calc_equip_second_attr(_RoleJinglian, _SoltNum, EquipProp) -> EquipProp.

attr_add(0, _AttrAdd) -> 0;
attr_add(Value,AttrAdd) -> Value + AttrAdd.
	% Value + common_tool:floor(Value*AttrAdd/100).

