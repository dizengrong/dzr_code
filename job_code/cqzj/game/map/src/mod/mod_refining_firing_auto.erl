%%%-------------------------------------------------------------------
%%% @author  <chenrong@4399.com>
%%% @doc 锻造的一键提升
%%%-------------------------------------------------------------------
-module(mod_refining_firing_auto).

%% INCLUDE
-include("mgeem.hrl").
-include("refining.hrl").

%% API
-export([
		 do_handle_info/1
		]).

-define(JUNIOR_REINFORCE_STUFF_ID, 10401001).
-define(SENIOR_REINFORCE_STUFF_ID, 10401002).
-define(JUNIOR_UPPROP_STUFF_ID, 10410006).
-define(SENIOR_UPPROP_STUFF_ID, 10410007).
-define(JUNIOR_PUNCH_STUFF_ID, 10600001).
-define(MIDDLE_PUNCH_STUFF_ID, 10600002).
-define(SENIOR_PUNCH_STUFF_ID, 10600003).

%% Error Code
-define(ERR_REFINING_AUTO_TYPE, 10). %% 不支持该锻造类型
-define(ERR_REFINING_AUTO_NOT_EQUIP, 11). %% 该物品不是装备
-define(ERR_REFINING_AUTO_CAN_NOT_MANY_EQUIP, 12). %% 装备不在背包里
-define(ERR_REFINING_AUTO_NOT_ENOUGH_BAG_POS, 13).%%背包空间不足
-define(ERR_REFINING_AUTO_IN_EXCHANGE_STATE, 14).%%交易状态下不能使用锻造

-define(ERR_REFINING_AUTO_REINFORCE_MOUNT, 101). %% 坐骑不能强化
-define(ERR_REFINING_AUTO_REINFORCE_FASHION, 102). %% 时装不能强化
-define(ERR_REFINING_AUTO_REINFORCE_ADORN, 103). %% 特殊装备不能强化
-define(ERR_REFINING_AUTO_REINFORCE_NO_UPGRADE, 104). %% 当前星级已经强化至最高，不需要升级了
-define(ERR_REFINING_AUTO_REINFORCE_ACHIEVE_TARGET_LEVEL, 105). %% 当前星级已经达到目标等级，不需要强化
-define(ERR_REFINING_AUTO_REINFORCE_NOT_ENOUGH_SILVER, 106). %% 钱币不足，强化中止
-define(ERR_REFINING_AUTO_REINFORCE_NOT_ENOUGH_GOLD, 107). %% 元宝不足，强化中止

-define(ERR_REFINING_AUTO_UPPROP_MOUNT, 201). %% 坐骑不能精炼
-define(ERR_REFINING_AUTO_UPPROP_FASHION, 202). %% 时装不能精炼
-define(ERR_REFINING_AUTO_UPPROP_ADORN, 203). %% 特殊装备不能精炼
-define(ERR_REFINING_AUTO_UPPROP_NOT_BIND, 204). %% 装备提升洗炼附加属性级别时，装备没有洗炼过
-define(ERR_REFINING_AUTO_UPPROP_NO_BIND_ATTR, 205). %% 装备提升洗炼附加属性级别时，装备没有洗炼属性
-define(ERR_REFINING_AUTO_UPPROP_UPGRADE_FULL, 206). %% 所有洗炼属性已经达到最大值，无法继续提升
-define(ERR_REFINING_AUTO_UPPROP_CODE_ERROR, 207). %% 装备洗炼时装备类型编码出错
-define(ERR_REFINING_AUTO_UPPROP_ACHIEVE_TARGET_LEVEL, 208). %% 所有洗炼属性已经达到目标等级，不需要精炼
-define(ERR_REFINING_AUTO_UPPROP_GOODS_ID_ERROR, 209). %% 装备洗炼时，洗炼材料不合法
-define(ERR_REFINING_AUTO_UPPROP_NOT_ENOUGH_SILVER, 210). %% 钱币不足，精炼中止
-define(ERR_REFINING_AUTO_UPPROP_NOT_ENOUGH_GOLD, 211). %% 元宝不足，精炼中止
-define(ERR_REFINING_AUTO_UPPROP_ATTR_NOT_CHANGE_AND_NOT_ENOUGH_SILVER, 212). %% 装备提升洗炼附加属性级别失败，级别没有变化, 且钱币不足
-define(ERR_REFINING_AUTO_UPPROP_ATTR_NOT_CHANGE_AND_NOT_ENOUGH_GOLD, 213). %% 装备提升洗炼附加属性级别失败，级别没有变化, 且元宝不足
-define(ERR_REFINING_AUTO_UPPROP_CODE_DUPLICATE_ERROR, 214). %% 装备的属性有重复，洗炼失败

-define(ERR_REFINING_AUTO_PUNCH_MOUNT, 301). %% 坐骑不能打孔
-define(ERR_REFINING_AUTO_PUNCH_FASHION, 302). %% 时装不能打孔
-define(ERR_REFINING_AUTO_PUNCH_ADORN, 303). %% 特殊装备不能打孔
-define(ERR_REFINING_AUTO_PUNCH_MAX_HOLE, 304). %% 当前装备已经开满了6个镶嵌孔
-define(ERR_REFINING_AUTO_PUNCH_STUFF_LEVEL_TOO_LOW, 305). %% 打孔符等级过低
-define(ERR_REFINING_AUTO_PUNCH_ACHIEVE_TARGET_LEVEL, 306). %% 当前装备已达到目标的孔数，不需要打孔
-define(ERR_REFINING_AUTO_PUNCH_NOT_ENOUGH_SILVER, 307). %% 钱币不足，打孔中止
-define(ERR_REFINING_AUTO_PUNCH_NOT_ENOUGH_GOLD, 308). %% 元宝不足，打孔中止

-define(NOTIFY_REFINING_FIRING_AUTO_RESULT(NewUpgradeLevel), 
	Record = #m_refining_firing_auto_toc{error_code=ErrorCode,
										 reason = undefined,
										 op_type = DataRecord#m_refining_firing_auto_tos.op_type,
										 sub_op_type = DataRecord#m_refining_firing_auto_tos.sub_op_type,
										 firing_equip = DataRecord#m_refining_firing_auto_tos.firing_equip,
										 new_list = [],
										 del_list = DelList,
										 update_list = UpList,
										 upgrade_level = NewUpgradeLevel,
										 silver = RoleAttr#p_role_attr.silver - NewRoleAttr#p_role_attr.silver,
										 silver_bind = RoleAttr#p_role_attr.silver_bind - NewRoleAttr#p_role_attr.silver_bind,
										 gold = RoleAttr#p_role_attr.gold - NewRoleAttr#p_role_attr.gold,
										 gold_bind = RoleAttr#p_role_attr.gold_bind - NewRoleAttr#p_role_attr.gold_bind
										},
	common_misc:unicast2(PID, Unique, Module, Method, Record)).

%%%===================================================================
%%% API
%%%===================================================================
do_handle_info({Unique, ?REFINING, ?REFINING_FIRING_AUTO, DataRecord, RoleId, PId, Line}) ->
	do_refining_firing_auto({Unique, ?REFINING, ?REFINING_FIRING_AUTO, DataRecord, RoleId, PId, Line});

do_handle_info(Info) ->
	?ERROR_MSG("~ts,Info=~w",["一键锻造模块无法处理此消息",Info]),
	error.

do_refining_firing_auto({Unique, Module, Method, DataRecord, RoleId, PID, Line}) ->
	case catch check_can_refining_firing(RoleId) of
		ok ->
			#m_refining_firing_auto_tos{op_type = OpType} = DataRecord,
			case OpType of
				?FIRING_OP_TYPE_REINFORCE -> %% 强化
					do_refining_firing_auto_reinforce({Unique, Module, Method, DataRecord, RoleId, PID, Line});
				?FIRING_OP_TYPE_UPPROP -> %% 精炼
                    do_refining_firing_auto_upprop({Unique, Module, Method, DataRecord, RoleId, PID, Line});
				?FIRING_OP_TYPE_PUNCH -> %% 打孔
					do_refining_firing_auto_punch({Unique, Module, Method, DataRecord, RoleId, PID, Line});
				_ ->
					do_refining_firing_error(Unique, Module, Method, DataRecord, PID, ?ERR_REFINING_AUTO_TYPE, undefined)
			end;
		{error, ErrCode, Reason} ->
			do_refining_firing_error(Unique, Module, Method, DataRecord, PID, ErrCode, Reason)
	end.

check_can_refining_firing(RoleID) ->
	[RoleState2] = db:dirty_read(?DB_ROLE_STATE, RoleID),
	#r_role_state{exchange=Exchange} = RoleState2,
	if	Exchange ->
			?THROW_ERR(?ERR_REFINING_AUTO_IN_EXCHANGE_STATE);
		true ->
			ok
	end.

do_refining_firing_error(Unique, Module, Method, DataRecord, PID, ErrorCode, Reason) ->
	ErrRecord = #m_refining_firing_auto_toc{error_code=ErrorCode,
											reason = Reason,
											op_type = DataRecord#m_refining_firing_auto_tos.op_type,
											sub_op_type = DataRecord#m_refining_firing_auto_tos.sub_op_type,
											firing_equip = DataRecord#m_refining_firing_auto_tos.firing_equip,
											upgrade_level = DataRecord#m_refining_firing_auto_tos.upgrade_level},
	common_misc:unicast2(PID, Unique, Module, Method, ErrRecord).

%%一键强化
do_refining_firing_auto_reinforce({Unique, Module, Method, DataRecord, RoleId, PID, _Line}) ->
	case catch check_can_auto_reinforce(RoleId, DataRecord) of
		{error, ErrCode, Reason} ->
			do_refining_firing_error(Unique, Module, Method, DataRecord, PID, ErrCode, Reason);
		{ok, EquipGoods} ->
			do_auto_reinforce({Unique, Module, Method, DataRecord, RoleId, PID, _Line}, EquipGoods)
	end.

check_can_auto_reinforce(RoleId, DataRecord) ->
	#m_refining_firing_auto_tos{upgrade_level=UpgradeLevel,firing_equip = FiringEquip} = DataRecord,
	EquipGoods = check_equip_need_reinforce(RoleId, FiringEquip, UpgradeLevel),
	{ok, EquipGoods}.

%% 检查是否有要强化的装备
check_equip_need_reinforce(RoleId, FiringEquip, UpgradeLevel) ->
	EquipGoods = check_equip_type(reinforce,RoleId,FiringEquip),
	{EquipReinforceLevel, EquipReinforceGrade} = get_equip_reinforce_level_grade(EquipGoods),
	case (EquipReinforceLevel =:= ?REINFORCE_MAX_LEVEL andalso EquipReinforceGrade =:= ?REINFORCE_MAX_GRADE) of
		true ->
			?THROW_ERR(?ERR_REFINING_AUTO_REINFORCE_NO_UPGRADE);
		_ ->
			next
	end,
	case EquipGoods#p_goods.reinforce_result >= UpgradeLevel of
		true ->
			?THROW_ERR(?ERR_REFINING_AUTO_REINFORCE_ACHIEVE_TARGET_LEVEL);
		false ->
			next
	end,
	EquipGoods.

do_auto_reinforce({Unique, Module, Method, DataRecord, RoleId, PID, Line}, EquipGoods) ->
	RoleAttr = get_role_attr(RoleId),
	%%获取背包中已有的强化石
	JuniorReinforceNum = get_firing_stuff_num(RoleId, ?JUNIOR_REINFORCE_STUFF_ID),
	SeniorReinforceNum = get_firing_stuff_num(RoleId, ?SENIOR_REINFORCE_STUFF_ID),
	{Status, NewRoleAttr, NewReinforceResult, NewJuniorReinforceNum, NewSeniorReinforceNum, IsBuyStuffWithBindMoney, TotalReinforceFee} =
		calc_final_equip_reinforce_result(RoleAttr, EquipGoods, EquipGoods#p_goods.reinforce_result,
										  DataRecord#m_refining_firing_auto_tos.upgrade_level, JuniorReinforceNum, 
										  SeniorReinforceNum, false, 0),
	
	case common_transaction:transaction(
		   fun() -> 
				   t_auto_reinforce(RoleId, RoleAttr, NewRoleAttr, EquipGoods, NewReinforceResult, 
									NewJuniorReinforceNum, JuniorReinforceNum,
									NewSeniorReinforceNum, SeniorReinforceNum, 
									IsBuyStuffWithBindMoney, TotalReinforceFee)
		   end) of
		{aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> 
                    ?THROW_ERR(?ERR_REFINING_AUTO_NOT_ENOUGH_BAG_POS);
                _ ->
                    ?THROW_SYS_ERR()
            end;
		{atomic, {ok, NewEquipGoods, DelList, UpdateList, JuniorDelList, SeniorDelList}} ->
			%% 道具变化通知
			UpList = [NewEquipGoods | UpdateList],
			catch common_misc:update_goods_notify({line, Line, RoleId},UpList),
			catch common_misc:del_goods_notify({line, Line, RoleId},DelList),
			%% 钱币变化通知
			catch mod_refining:do_refining_deduct_fee_notify(RoleId,{line, Line, RoleId}),
			%% 元宝变化通知
			catch mod_refining:do_refining_deduct_gold_notify(RoleId,{line, Line, RoleId}),
			%% 道具消费日志
			log_stuff_usage(RoleId,JuniorDelList,?LOG_ITEM_TYPE_QIANG_HUA_SHI_QU),
			log_stuff_usage(RoleId,SeniorDelList,?LOG_ITEM_TYPE_QIANG_HUA_SHI_QU),
			catch common_item_logger:log(RoleId,NewEquipGoods,1,?LOG_ITEM_TYPE_QIANG_HUA_HUO_DE),
			
			ErrorCode = 
				case Status of 
					not_enough_silver ->
						?ERR_REFINING_AUTO_REINFORCE_NOT_ENOUGH_SILVER;
					not_enough_gold ->
						?ERR_REFINING_AUTO_REINFORCE_NOT_ENOUGH_GOLD;
					succ ->
						?ERR_OK;
					_ ->
						?ERR_SYS_ERR
				end,
			?NOTIFY_REFINING_FIRING_AUTO_RESULT(NewReinforceResult),
			mod_refining_firing:hook_refining_firing_reinforce(RoleId,EquipGoods,NewEquipGoods)
	end.

t_auto_reinforce(RoleId, RoleAttr, NewRoleAttr, EquipGoods, NewReinforceResult, 
				 NewJuniorReinforceNum, JuniorReinforceNum,
				 NewSeniorReinforceNum, SeniorReinforceNum, 
				 IsBuyStuffWithBindMoney, TotalReinforceFee) ->
	%%扣除玩家已有的强化石
	{JuniorUpList, JuniorDelList} = deduct_goods_by_typeid(RoleId, ?JUNIOR_REINFORCE_STUFF_ID, JuniorReinforceNum - NewJuniorReinforceNum),
	{SeniorUpList, SeniorDelList} = deduct_goods_by_typeid(RoleId, ?SENIOR_REINFORCE_STUFF_ID, SeniorReinforceNum - NewSeniorReinforceNum),
	
	%%更新玩家的强化属性
	IsUseBindJuniorStuff = is_use_bind_stuff(JuniorUpList, JuniorDelList),
	IsUseBindSeniorStuff = is_use_bind_stuff(SeniorUpList, SeniorDelList),
	EquipGoods2 = 
		%% 装备是否使用了铜钱元宝来购买强化石，或者用了绑定的强化石
		case EquipGoods#p_goods.bind =/= true andalso (IsBuyStuffWithBindMoney =:= true orelse IsUseBindJuniorStuff orelse IsUseBindSeniorStuff)  of
			true ->
				case mod_refining_bind:do_equip_bind_for_reinforce(EquipGoods) of
					{error,_IndexErrorCode} ->
						EquipGoods#p_goods{bind=true};
					{ok,BindGoods} ->
						BindGoods
				end;
			_ ->
				EquipGoods
		end,
	
	{ok, NewEquipGoods, DelList, UpdateList} =
		case EquipGoods#p_goods.reinforce_result >= NewReinforceResult of
			true ->
				mod_bag:update_goods(RoleId,EquipGoods2),
				{ok,EquipGoods2,
				 lists:append(JuniorDelList, SeniorDelList),
				 lists:append(JuniorUpList, SeniorUpList)};
			false ->
				mod_refining_firing:do_t_refining_firing_reinforce2(RoleId,EquipGoods2,NewReinforceResult,
																	lists:append(JuniorDelList, SeniorDelList),
																	lists:append(JuniorUpList, SeniorUpList))
		end,
	case RoleAttr#p_role_attr.gold =/= NewRoleAttr#p_role_attr.gold of
		true -> 
			UnbindGoldCost = RoleAttr#p_role_attr.gold - NewRoleAttr#p_role_attr.gold,
			case mod_qq_helper:check_buy_goods(RoleId, RoleAttr#p_role_attr.gold, UnbindGoldCost) of
				ok ->
					Token = mod_qq_helper:get_buy_goods_token(RoleId, UnbindGoldCost, true),
					case mod_qq_helper:wait_buy_goods_callback(5000, Token) of
						{true, Amt} ->
							RoleTab = mod_role_tab:name(RoleId),
							ets:update_counter(RoleTab, p_role_attr, {#p_role_attr.gold, -Amt, 0, 0}),
							ok;
						{error, Reason} ->
							?THROW_ERR(?ERR_OTHER_ERR, Reason)
					end;
				{error, Reason} ->
					?THROW_ERR(?ERR_OTHER_ERR, Reason)
			end;
		false ->
			ok
	end,
	%%元宝，钱币消费记录
	log_money_usage(reinforce, RoleId, RoleAttr, NewRoleAttr, TotalReinforceFee),
	{ok, NewEquipGoods, DelList, UpdateList, JuniorDelList, SeniorDelList}.

calc_final_equip_reinforce_result(RoleAttr, EquipGoods, ReinforceResult,
								  TargetUpgradeLevel, JuniorReinforceNum, SeniorReinforceNum, 
								  IsBuyStuffWithBindMoney, TotalReinforceFee) ->
	%% 查找出当前强化装备需要的材料配置
	EquipReinforceLevel = ReinforceResult div 10, 
	EquipReinforceGrade = ReinforceResult rem 10,
	{ReinforceStuffTypeId,ReinforceStuffLevel,ReinforceStuffNeedNum} = mod_refining_firing:get_reinforce_stuff_config(EquipReinforceLevel, EquipReinforceGrade),
	{AutoBuyNum, NewJuniorReinforceNum, NewSeniorReinforceNum} = calc_auto_buy_reinforce_stuff_num(ReinforceStuffTypeId, ReinforceStuffNeedNum, JuniorReinforceNum, SeniorReinforceNum),
	%%计算本次强化，花费金钱、元宝
	ReinforceFee = calc_refining_fee(equip_reinforce_fee,EquipGoods, ReinforceStuffLevel),
	{SilverFee, SilverBindFee, GoldFee, GoldBindFee} = calc_refining_need_money(ReinforceStuffTypeId, AutoBuyNum, ReinforceFee),
	
	#p_role_attr{silver=Silver, silver_bind=SilverBind, gold=Gold, gold_bind=GoldBind} = RoleAttr,
	case {Silver + SilverBind < SilverFee + SilverBindFee, Gold < GoldFee, Gold + GoldBind < GoldFee + GoldBindFee} of
		{true, _, _} ->
			{not_enough_silver, RoleAttr, ReinforceResult, JuniorReinforceNum, SeniorReinforceNum, IsBuyStuffWithBindMoney, TotalReinforceFee};
		{false, true, _} ->
			{not_enough_gold, RoleAttr, ReinforceResult, JuniorReinforceNum, SeniorReinforceNum, IsBuyStuffWithBindMoney, TotalReinforceFee};
		{false, false, true} ->
			{not_enough_gold, RoleAttr, ReinforceResult, JuniorReinforceNum, SeniorReinforceNum, IsBuyStuffWithBindMoney, TotalReinforceFee};
		{false, false, false} ->
			%% 新的强化结果
			NewIsBuyStuffWithBindMoney =
				if IsBuyStuffWithBindMoney =:= false andalso EquipGoods#p_goods.bind =:= false ->
					   is_buy_stuff_with_bind_money(RoleAttr, ReinforceStuffTypeId, AutoBuyNum);
				   true ->
					   IsBuyStuffWithBindMoney
				end,
			{Silver2, SilverBind2} = mod_role2:calc_rest_money(Silver, SilverBind, SilverFee + SilverBindFee),
			{Gold2, GoldBind2} = mod_role2:calc_rest_money(Gold - GoldFee, GoldBind, GoldBindFee),
			NewRoleAttr = RoleAttr#p_role_attr{silver=Silver2, silver_bind=SilverBind2, gold=Gold2, gold_bind=GoldBind2},
			NewReinforceResult = mod_refining_firing:calc_new_reinforce_result(EquipGoods, ReinforceStuffLevel),
			NewEquipGoods = EquipGoods#p_goods{reinforce_result =  NewReinforceResult},
			if NewReinforceResult >= TargetUpgradeLevel ->
				   {succ, NewRoleAttr, NewReinforceResult, NewJuniorReinforceNum, NewSeniorReinforceNum, NewIsBuyStuffWithBindMoney, TotalReinforceFee+ReinforceFee};
			   true ->
				   calc_final_equip_reinforce_result(NewRoleAttr, NewEquipGoods, NewReinforceResult,
													 TargetUpgradeLevel, NewJuniorReinforceNum, NewSeniorReinforceNum, 
													 NewIsBuyStuffWithBindMoney, TotalReinforceFee+ReinforceFee)
			end 
	end.

%% 计算单次强化需自动购买强化石的数量
calc_auto_buy_reinforce_stuff_num(ReinforceStuffTypeId, ReinforceStuffNeedNum, JuniorReinforceNum, SeniorReinforceNum) ->
	if ReinforceStuffTypeId =:= ?JUNIOR_REINFORCE_STUFF_ID ->
		   if ReinforceStuffNeedNum =< JuniorReinforceNum ->
				  {0, JuniorReinforceNum - ReinforceStuffNeedNum, SeniorReinforceNum};
			  true ->
				  {ReinforceStuffNeedNum - JuniorReinforceNum, 0, SeniorReinforceNum}
		   end;
	   ReinforceStuffTypeId =:= ?SENIOR_REINFORCE_STUFF_ID ->
		   if ReinforceStuffNeedNum =< SeniorReinforceNum ->
				  {0, JuniorReinforceNum, SeniorReinforceNum - ReinforceStuffNeedNum};
			  true ->
				  {ReinforceStuffNeedNum - SeniorReinforceNum, JuniorReinforceNum, 0}
		   end
	end.

%% 一键精炼
do_refining_firing_auto_upprop({Unique, Module, Method, DataRecord, RoleId, PID, Line}) ->
	case catch check_can_auto_upprop(RoleId, DataRecord) of
		{error, ErrCode, Reason} ->
			do_refining_firing_error(Unique, Module, Method, DataRecord, PID, ErrCode, Reason);
		{ok, EquipGoods} ->
			do_auto_upprop({Unique, Module, Method, DataRecord, RoleId, PID, Line}, EquipGoods)
	end.

check_can_auto_upprop(RoleId, DataRecord) ->
	#m_refining_firing_auto_tos{upgrade_level=UpgradeLevel,firing_equip = FiringEquip} = DataRecord,
	EquipGoods = check_equip_need_upprop(RoleId, FiringEquip, UpgradeLevel),
	{ok, EquipGoods}.

check_equip_need_upprop(RoleId, FiringEquip, UpgradeLevel) ->
	EquipGoods = check_equip_type(upprop,RoleId,FiringEquip),
	
    case EquipGoods#p_goods.bind =:= true of
        true ->
            next;
        _ ->
			?THROW_ERR(?ERR_REFINING_AUTO_UPPROP_NOT_BIND)
    end,
    case  EquipGoods#p_goods.equip_bind_attr =/= undefined
        andalso EquipGoods#p_goods.equip_bind_attr =/= [] of
        true ->
            next;
        _ ->
			?THROW_ERR(?ERR_REFINING_AUTO_UPPROP_NO_BIND_ATTR)
    end,
    %% 检查装备绑定属性是不是满级
    [EquipBindAttrList] =  common_config_dyn:find(equip_bind,equip_bind_attr),
    CheckEquipBindAttrList = 
        lists:map(
          fun(AttrRecord) ->
                  MaxBindAttrLevel = lists:max(
                                       [R2#r_equip_bind_attr.level || 
                                           R2 <- EquipBindAttrList, 
                                           R2#r_equip_bind_attr.attr_code =:= AttrRecord#p_equip_bind_attr.attr_code]),
                  case MaxBindAttrLevel =:= AttrRecord#p_equip_bind_attr.attr_level of
                      true ->
                          1;
                      false ->
                          2
                  end
          end,EquipGoods#p_goods.equip_bind_attr),
    case lists:member(2,CheckEquipBindAttrList) of
        true ->
            next;
        _ ->
			?THROW_ERR(?ERR_REFINING_AUTO_UPPROP_UPGRADE_FULL)
    end,
	case is_achieve_target_upprop_level(EquipGoods#p_goods.equip_bind_attr, UpgradeLevel) of
		true ->
			?THROW_ERR(?ERR_REFINING_AUTO_UPPROP_ACHIEVE_TARGET_LEVEL);
		false ->
			ignore
	end,
	
	[EquipBaseInfo] = common_config_dyn:find_equip(EquipGoods#p_goods.typeid),
    [BindEquipList] = common_config_dyn:find(equip_bind,equip_bind_equip),
    _BindEquipRecord = 
        case [BindEquipRecordT || 
                 BindEquipRecordT <- BindEquipList, 
                 BindEquipRecordT#r_equip_bind_equip.equip_code =:= EquipBaseInfo#p_equip_base_info.slot_num,
                 BindEquipRecordT#r_equip_bind_equip.protype =:= EquipBaseInfo#p_equip_base_info.protype ] of
            [BindEquipRecordTT] ->
                BindEquipRecordTT;
            _ ->
				?THROW_ERR(?ERR_REFINING_AUTO_UPPROP_CODE_ERROR)
        end,
	case mod_refining_firing:check_equip_upprop_has_duplicate(EquipGoods#p_goods.equip_bind_attr) of
		true ->
			?THROW_ERR(?ERR_REFINING_AUTO_UPPROP_CODE_DUPLICATE_ERROR);
		false ->
			next
	end,
	EquipGoods.

do_auto_upprop({Unique, Module, Method, DataRecord, RoleId, PID, Line}, EquipGoods) ->
	RoleAttr = get_role_attr(RoleId),
	JuniorUppropNum = get_firing_stuff_num(RoleId, ?JUNIOR_UPPROP_STUFF_ID),
	SeniorUppropNum = get_firing_stuff_num(RoleId, ?SENIOR_UPPROP_STUFF_ID),
	{Status, NewRoleAttr, NewUppropBindAttr, NewJuniorUppropNum, NewSeniorUppropNum, TotalUppropFee} =
		calc_final_equip_upprop_result(RoleAttr, EquipGoods, EquipGoods#p_goods.equip_bind_attr,
									   DataRecord#m_refining_firing_auto_tos.upgrade_level, 
									   JuniorUppropNum, SeniorUppropNum, 0),
	
	case common_transaction:transaction(
		   fun() -> 
				   t_auto_upprop(RoleId, RoleAttr, NewRoleAttr, EquipGoods, NewUppropBindAttr, 
									NewJuniorUppropNum, JuniorUppropNum,
									NewSeniorUppropNum, SeniorUppropNum, 
									TotalUppropFee)
		   end) of
		{aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> 
                    ?THROW_ERR(?ERR_REFINING_AUTO_NOT_ENOUGH_BAG_POS);
                _ ->
                    ?THROW_SYS_ERR()
            end;
		{atomic, {ok, NewEquipGoods, DelList, UpdateList, JuniorDelList, SeniorDelList}} ->
			%% 道具变化通知
			UpList = [NewEquipGoods| UpdateList],
			catch common_misc:update_goods_notify({line, Line, RoleId},UpList),
			catch common_misc:del_goods_notify({line, Line, RoleId},DelList),
			%% 钱币变化通知
			catch mod_refining:do_refining_deduct_fee_notify(RoleId,{line, Line, RoleId}),
			%% 元宝变化通知
			catch mod_refining:do_refining_deduct_gold_notify(RoleId,{line, Line, RoleId}),
			%% 道具消费日志
			log_stuff_usage(RoleId,JuniorDelList,?LOG_ITEM_TYPE_ZHONG_XIN_BANG_DING_SHI_QU),
			log_stuff_usage(RoleId,SeniorDelList,?LOG_ITEM_TYPE_ZHONG_XIN_BANG_DING_SHI_QU),
			
			OldAttrLevelSum = sum_equip_bind_attr_level(EquipGoods#p_goods.equip_bind_attr),
			NewAttrLevelSum = sum_equip_bind_attr_level(NewUppropBindAttr),
			ErrorCode = 
				case {Status, OldAttrLevelSum =:= NewAttrLevelSum} of 
					{not_enough_silver, true} ->
						?ERR_REFINING_AUTO_UPPROP_ATTR_NOT_CHANGE_AND_NOT_ENOUGH_SILVER;
					{not_enough_silver, false} ->
						?ERR_REFINING_AUTO_UPPROP_NOT_ENOUGH_SILVER;
					{not_enough_gold, true} ->
						?ERR_REFINING_AUTO_UPPROP_ATTR_NOT_CHANGE_AND_NOT_ENOUGH_GOLD;
					{not_enough_gold, false} ->
						?ERR_REFINING_AUTO_UPPROP_NOT_ENOUGH_GOLD;
					{succ, _} ->
						?ERR_OK;
					_ ->
						?ERR_SYS_ERR
				end,
			NewMinBindAttrLevel = mod_refining_firing:get_upprop_min_bind_attr_level(NewUppropBindAttr),
			?NOTIFY_REFINING_FIRING_AUTO_RESULT(NewMinBindAttrLevel)
	end.

t_auto_upprop(RoleId, RoleAttr, NewRoleAttr, EquipGoods, NewEquipBindAttrList, 
			  NewJuniorUppropNum, JuniorUppropNum,NewSeniorUppropNum, SeniorUppropNum, 
			  TotalUppropFee) ->
	%%元宝，钱币消费记录
	log_money_usage(upprop, RoleId, RoleAttr, NewRoleAttr, TotalUppropFee),
	%% 扣除金钱
	mod_map_role:set_role_attr(RoleId, NewRoleAttr),
	
	{JuniorUpList, JuniorDelList} = deduct_goods_by_typeid(RoleId, ?JUNIOR_UPPROP_STUFF_ID, JuniorUppropNum - NewJuniorUppropNum),
	{SeniorUpList, SeniorDelList} = deduct_goods_by_typeid(RoleId, ?SENIOR_UPPROP_STUFF_ID, SeniorUppropNum - NewSeniorUppropNum),
	EquipGoods2 = 
		case mod_refining_bind:do_equip_bind_for_equip_bind_up_attr(EquipGoods,NewEquipBindAttrList) of
			{error,_BindErrorCode} ->
				EquipGoods;
			{ok,EquipGoods2T} ->
				EquipGoods2T
		end,
	%% 计算装备精炼系数
	NewEquipGoods= 
		case common_misc:do_calculate_equip_refining_index(EquipGoods2) of
			{error,_ErrorIndexCode} ->
				EquipGoods2;
			{ok, EquipGoods3} ->
				EquipGoods3
		end,
	mod_bag:update_goods(RoleId,NewEquipGoods),
	{ok, NewEquipGoods, lists:append(JuniorDelList, SeniorDelList), lists:append(JuniorUpList, SeniorUpList), JuniorDelList, SeniorDelList}.

calc_final_equip_upprop_result(RoleAttr, EquipGoods, CurrentEquipBindAttr, TargetUpgradeLevel,
							   JuniorUppropNum, SeniorUppropNum, TotalUppropFee) ->
	MinBindAttrLevel = mod_refining_firing:get_upprop_min_bind_attr_level(CurrentEquipBindAttr),
	BindItemRecord = get_upprop_stuff_config(MinBindAttrLevel),
	{AutoBuyNum, NewJuniorUppropNum, NewSeniorUppropNum} = 
		calc_auto_buy_upprop_stuff_num(BindItemRecord, JuniorUppropNum, SeniorUppropNum),
	
	UppropFee = calc_refining_fee(equip_bind_upgrade_fee,EquipGoods, BindItemRecord#r_equip_bind_item.item_level),
	{SilverFee, SilverBindFee, GoldFee, GoldBindFee} = calc_refining_need_money(BindItemRecord#r_equip_bind_item.item_id, AutoBuyNum, UppropFee),
	#p_role_attr{silver=Silver, silver_bind=SilverBind, gold=Gold, gold_bind=GoldBind} = RoleAttr,
	case {Silver + SilverBind < SilverFee + SilverBindFee, Gold < GoldFee, Gold + GoldBind < GoldFee + GoldBindFee} of
		{true, _, _} ->
			{not_enough_silver, RoleAttr, CurrentEquipBindAttr, JuniorUppropNum, SeniorUppropNum, TotalUppropFee};
		{false, true, _} ->
			{not_enough_gold, RoleAttr, CurrentEquipBindAttr, JuniorUppropNum, SeniorUppropNum, TotalUppropFee};
		{false, false, true} ->
			{not_enough_gold, RoleAttr, CurrentEquipBindAttr, JuniorUppropNum, SeniorUppropNum, TotalUppropFee};
		{false, false, false} ->
			{Silver2, SilverBind2} = mod_role2:calc_rest_money(Silver, SilverBind, SilverFee + SilverBindFee),
			{Gold2, GoldBind2} = mod_role2:calc_rest_money(Gold - GoldFee, GoldBind, GoldBindFee),
			NewRoleAttr = RoleAttr#p_role_attr{silver=Silver2, silver_bind=SilverBind2, gold=Gold2, gold_bind=GoldBind2},
			MaxPossibleLevel = mod_refining_firing:get_upprop_max_possible_level(BindItemRecord),
			case mod_refining_firing:calc_new_upprop_result(CurrentEquipBindAttr, BindItemRecord, MaxPossibleLevel) of
				{succ, NewEquipBindAttrList} ->
					case is_achieve_target_upprop_level(NewEquipBindAttrList, TargetUpgradeLevel) of
						true ->
							{succ, NewRoleAttr, NewEquipBindAttrList, 
							 NewJuniorUppropNum, NewSeniorUppropNum, 
							 TotalUppropFee+UppropFee};
						false ->
							calc_final_equip_upprop_result(NewRoleAttr, EquipGoods, NewEquipBindAttrList, TargetUpgradeLevel,
														   NewJuniorUppropNum, NewSeniorUppropNum, TotalUppropFee+UppropFee)
					end;
				fail ->
					calc_final_equip_upprop_result(NewRoleAttr, EquipGoods, CurrentEquipBindAttr, TargetUpgradeLevel,
							   NewJuniorUppropNum, NewSeniorUppropNum, TotalUppropFee+UppropFee)
			end
	end.

is_achieve_target_upprop_level(EquipBindAttr, UpgradeLevel) ->
	lists:all(fun(AttrRecord)-> AttrRecord#p_equip_bind_attr.attr_level >= UpgradeLevel end, EquipBindAttr).

get_upprop_stuff_config(MinBindAttrLevel) ->
	case mod_refining_firing:get_upprop_stuff_config(MinBindAttrLevel) of
		{error, equip_bind_goods_id_error} ->
			?THROW_ERR(?ERR_REFINING_AUTO_UPPROP_GOODS_ID_ERROR);
		Config ->
			Config
	end.

%% 计算单次强化需自动购买强化石的数量
calc_auto_buy_upprop_stuff_num(BindItemRecord, JuniorUppropNum, SeniorUppropNum) ->
	UppropStuffTypeId = BindItemRecord#r_equip_bind_item.item_id, 
	UppropStuffNeedNum = BindItemRecord#r_equip_bind_item.item_num,
	if UppropStuffTypeId =:= ?JUNIOR_UPPROP_STUFF_ID ->
		   if UppropStuffNeedNum =< JuniorUppropNum ->
				  {0, JuniorUppropNum - UppropStuffNeedNum, SeniorUppropNum};
			  true ->
				  {UppropStuffNeedNum - JuniorUppropNum, 0, SeniorUppropNum}
		   end;
	   UppropStuffTypeId =:= ?SENIOR_UPPROP_STUFF_ID ->
		   if UppropStuffNeedNum =< SeniorUppropNum ->
				  {0, JuniorUppropNum, SeniorUppropNum - UppropStuffNeedNum};
			  true ->
				  {UppropStuffNeedNum - SeniorUppropNum, JuniorUppropNum, 0}
		   end
	end.

%% 一键打孔
do_refining_firing_auto_punch({Unique, Module, Method, DataRecord, RoleId, PID, Line}) ->
	case catch check_can_auto_punch(RoleId, DataRecord) of
		{error, ErrCode, Reason} ->
			do_refining_firing_error(Unique, Module, Method, DataRecord, PID, ErrCode, Reason);
		{ok, EquipGoods} ->
			do_auto_punch({Unique, Module, Method, DataRecord, RoleId, PID, Line}, EquipGoods)
	end.

check_can_auto_punch(RoleId, DataRecord) ->
	#m_refining_firing_auto_tos{upgrade_level=UpgradeLevel,firing_equip = FiringEquip} = DataRecord,
	EquipGoods = check_equip_need_punch(RoleId, FiringEquip, UpgradeLevel),
	{ok, EquipGoods}.

check_equip_need_punch(RoleId, FiringEquip, UpgradeLevel) ->
	EquipGoods = check_equip_type(punch,RoleId,FiringEquip),
	
	if EquipGoods#p_goods.punch_num >= ?MAX_PUNCH_NUM ->
		   ?THROW_ERR(?ERR_REFINING_AUTO_PUNCH_MAX_HOLE);
       true ->
            next
    end,
	if EquipGoods#p_goods.punch_num >= UpgradeLevel ->
		   ?THROW_ERR(?ERR_REFINING_AUTO_PUNCH_ACHIEVE_TARGET_LEVEL);
       true ->
            next
    end,
	[PunchKindList] = common_config_dyn:find(refining,punch_kind_list),
	[EquipBaseInfo] = common_config_dyn:find_equip(EquipGoods#p_goods.typeid),
    case lists:member(EquipBaseInfo#p_equip_base_info.kind,PunchKindList) of
        true ->
            next;
        false ->
			?THROW_ERR(?ERR_REFINING_AUTO_PUNCH_STUFF_LEVEL_TOO_LOW)
    end,
	
	EquipGoods.

do_auto_punch({Unique, Module, Method, DataRecord, RoleId, PID, Line}, EquipGoods) ->
	RoleAttr = get_role_attr(RoleId),
	JuniorPunchNum = get_firing_stuff_num(RoleId, ?JUNIOR_PUNCH_STUFF_ID),
	MiddlePunchNum = get_firing_stuff_num(RoleId, ?MIDDLE_PUNCH_STUFF_ID),
	SeniorPunchNum = get_firing_stuff_num(RoleId, ?SENIOR_PUNCH_STUFF_ID),
	{Status, NewRoleAttr, NewPunchResult, NewJuniorPunchNum, NewMiddlePunchNum, NewSeniorPunchNum, IsBuyStuffWithBindMoney, TotalPunchFee} =
		calc_final_equip_punch_result(RoleAttr, EquipGoods, EquipGoods#p_goods.punch_num,
										  DataRecord#m_refining_firing_auto_tos.upgrade_level, 
										  JuniorPunchNum, MiddlePunchNum, SeniorPunchNum,
										  false, 0),
	
	case common_transaction:transaction(
		   fun() -> 
				   t_auto_punch(RoleId, RoleAttr, NewRoleAttr, EquipGoods, NewPunchResult, 
				 NewJuniorPunchNum, JuniorPunchNum,
				 NewMiddlePunchNum, MiddlePunchNum,
				 NewSeniorPunchNum, SeniorPunchNum, 
				 IsBuyStuffWithBindMoney, TotalPunchFee)
		   end) of
		{aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> 
                    ?THROW_ERR(?ERR_REFINING_AUTO_NOT_ENOUGH_BAG_POS);
                _ ->
                    ?THROW_SYS_ERR()
            end;
		{atomic, {ok, NewEquipGoods, DelList, UpdateList, JuniorDelList, MiddleDelList, SeniorDelList}} ->
			%% 道具变化通知
			UpList = [NewEquipGoods| UpdateList],
			catch common_misc:update_goods_notify({line, Line, RoleId},[NewEquipGoods| UpdateList]),
			catch common_misc:del_goods_notify({line, Line, RoleId},DelList),
			%% 钱币变化通知
			catch mod_refining:do_refining_deduct_fee_notify(RoleId,{line, Line, RoleId}),
			%% 元宝变化通知
			catch mod_refining:do_refining_deduct_gold_notify(RoleId,{line, Line, RoleId}),
			%% 道具消费日志
			log_stuff_usage(RoleId,JuniorDelList,?LOG_ITEM_TYPE_KAI_KONG_SHI_QU),
			log_stuff_usage(RoleId,MiddleDelList,?LOG_ITEM_TYPE_KAI_KONG_SHI_QU),
			log_stuff_usage(RoleId,SeniorDelList,?LOG_ITEM_TYPE_KAI_KONG_SHI_QU),
			catch common_item_logger:log(RoleId,NewEquipGoods,1,?LOG_ITEM_TYPE_KAI_KONG_HUO_DE),
			
			ErrorCode = 
				case Status of 
					not_enough_silver ->
						?ERR_REFINING_AUTO_PUNCH_NOT_ENOUGH_SILVER;
					not_enough_gold ->
						?ERR_REFINING_AUTO_PUNCH_NOT_ENOUGH_GOLD;
					succ ->
						?ERR_OK;
					_ ->
						?ERR_SYS_ERR
				end,
			?NOTIFY_REFINING_FIRING_AUTO_RESULT(NewPunchResult)
	end.

t_auto_punch(RoleId, RoleAttr, NewRoleAttr, EquipGoods, NewPunchResult, 
			 NewJuniorPunchNum, JuniorPunchNum,
			 NewMiddlePunchNum, MiddlePunchNum,
			 NewSeniorPunchNum, SeniorPunchNum, 
			 IsBuyStuffWithBindMoney, TotalPunchFee) ->
	%%元宝，钱币消费记录
	log_money_usage(punch, RoleId, RoleAttr, NewRoleAttr, TotalPunchFee),
	%% 扣除金钱
	mod_map_role:set_role_attr(RoleId, NewRoleAttr),
	
	{JuniorUpList, JuniorDelList} = deduct_goods_by_typeid(RoleId, ?JUNIOR_PUNCH_STUFF_ID, JuniorPunchNum - NewJuniorPunchNum),
	{MiddleUpList, MiddleDelList} = deduct_goods_by_typeid(RoleId, ?MIDDLE_PUNCH_STUFF_ID, MiddlePunchNum - NewMiddlePunchNum),
	{SeniorUpList, SeniorDelList} = deduct_goods_by_typeid(RoleId, ?SENIOR_PUNCH_STUFF_ID, SeniorPunchNum - NewSeniorPunchNum),
	
	IsUseBindJuniorStuff = is_use_bind_stuff(JuniorUpList, JuniorDelList),
	IsUseBindMiddleStuff = is_use_bind_stuff(MiddleUpList, MiddleDelList),
	IsUseBindSeniorStuff = is_use_bind_stuff(SeniorUpList, SeniorDelList),
	
    EquipGoods2 = EquipGoods#p_goods{punch_num = NewPunchResult},
    EquipGoods3 = 
		case (EquipGoods#p_goods.bind =:= false andalso 
									 (IsBuyStuffWithBindMoney =:= true orelse
										  IsUseBindJuniorStuff orelse 
										  IsUseBindMiddleStuff orelse 
										  IsUseBindSeniorStuff)) of
            true ->
                case mod_refining_bind:do_equip_bind_for_punch(EquipGoods2) of
                    {error,_ErrorBindCode} ->
                        EquipGoods2#p_goods{bind = true};
                    {ok,BindGoods} ->
                        BindGoods
                end;
            false ->
                EquipGoods2
        end,
    
    %% 计算装备精炼系数
    NewEquipGoods = 
        case common_misc:do_calculate_equip_refining_index(EquipGoods3) of
            {error,_ErrorIndexCode} ->
                EquipGoods3;
            {ok, EquipGoods4T} ->
                EquipGoods4T
        end,
    mod_bag:update_goods(RoleId,NewEquipGoods),
	DelList = lists:append([JuniorDelList, MiddleDelList, SeniorDelList]),
	UpdateList = lists:append([JuniorUpList, MiddleUpList, SeniorUpList]),
	{ok, NewEquipGoods, DelList, UpdateList, JuniorDelList, MiddleUpList, SeniorDelList}.

calc_final_equip_punch_result(RoleAttr, EquipGoods, EquipPunchNum, TargetUpgradeLevel,
							  JuniorPunchNum, MiddlePunchNum, SeniorPunchNum,
							  IsBuyStuffWithBindMoney, TotalPunchFee) ->
	{PunchStuffTypeId,PunchLevel} = get_punch_stuff_config(EquipGoods#p_goods.punch_num),
	{AutoBuyNum, NewJuniorPunchNum, NewMiddlePunchNum, NewSeniorPunchNum} = 
		calc_auto_buy_punch_stuff_num(PunchStuffTypeId, 1, JuniorPunchNum, MiddlePunchNum, SeniorPunchNum),
	
	PunchFee = calc_refining_fee(equip_punch_fee,EquipGoods, PunchLevel),
	{SilverFee, SilverBindFee, GoldFee, GoldBindFee} = calc_refining_need_money(PunchStuffTypeId, AutoBuyNum, PunchFee),
	
	#p_role_attr{silver=Silver, silver_bind=SilverBind, gold=Gold, gold_bind=GoldBind} = RoleAttr,
	case {Silver + SilverBind < SilverFee + SilverBindFee, Gold < GoldFee, Gold + GoldBind < GoldFee + GoldBindFee} of
		{true, _, _} ->
			{not_enough_silver, RoleAttr, EquipPunchNum, JuniorPunchNum, MiddlePunchNum, SeniorPunchNum, IsBuyStuffWithBindMoney, TotalPunchFee};
		{false, true, _} ->
			{not_enough_gold, RoleAttr, EquipPunchNum, JuniorPunchNum, MiddlePunchNum, SeniorPunchNum, IsBuyStuffWithBindMoney, TotalPunchFee};
		{false, false, true} ->
			{not_enough_gold, RoleAttr, EquipPunchNum, JuniorPunchNum, MiddlePunchNum, SeniorPunchNum, IsBuyStuffWithBindMoney, TotalPunchFee};
		{false, false, false} ->
			NewIsBuyStuffWithBindMoney =
				if IsBuyStuffWithBindMoney =:= false andalso EquipGoods#p_goods.bind =:= false ->
					   is_buy_stuff_with_bind_money(RoleAttr, PunchStuffTypeId, AutoBuyNum);
				   true ->
					   IsBuyStuffWithBindMoney
				end,
			{Silver2, SilverBind2} = mod_role2:calc_rest_money(Silver, SilverBind, SilverFee + SilverBindFee),
			{Gold2, GoldBind2} = mod_role2:calc_rest_money(Gold - GoldFee, GoldBind, GoldBindFee),
			NewRoleAttr = RoleAttr#p_role_attr{silver=Silver2, silver_bind=SilverBind2, gold=Gold2, gold_bind=GoldBind2},
			{_, NewPunchResult} = mod_refining_firing:calc_new_punch_result(EquipGoods),
			NewEquipGoods = EquipGoods#p_goods{punch_num =  NewPunchResult},
			if NewPunchResult >= TargetUpgradeLevel ->
				   {succ, NewRoleAttr, NewPunchResult, NewJuniorPunchNum, NewMiddlePunchNum, NewSeniorPunchNum, NewIsBuyStuffWithBindMoney, TotalPunchFee+PunchFee};
			   true ->
				   calc_final_equip_punch_result(NewRoleAttr, NewEquipGoods, NewPunchResult, TargetUpgradeLevel,
												 NewJuniorPunchNum, NewMiddlePunchNum, NewSeniorPunchNum, 
												 NewIsBuyStuffWithBindMoney, TotalPunchFee+PunchFee)
			end 
	end.

calc_auto_buy_punch_stuff_num(PunchStuffTypeId,PunchStuffNeedNum,JuniorPunchNum,MiddlePunchNum,SeniorPunchNum) ->
	if PunchStuffTypeId =:= ?JUNIOR_PUNCH_STUFF_ID ->
		   if PunchStuffNeedNum =< JuniorPunchNum ->
				  {0, JuniorPunchNum - PunchStuffNeedNum, MiddlePunchNum, SeniorPunchNum};
			  true ->
				  {1, 0, MiddlePunchNum, SeniorPunchNum}
		   end;
	   PunchStuffTypeId =:= ?MIDDLE_PUNCH_STUFF_ID ->
		   if PunchStuffNeedNum =< MiddlePunchNum ->
				  {0, JuniorPunchNum, MiddlePunchNum - PunchStuffNeedNum, SeniorPunchNum};
			  true ->
				  {1, JuniorPunchNum, 0, SeniorPunchNum}
		   end;
	   PunchStuffTypeId =:= ?SENIOR_PUNCH_STUFF_ID ->
		   if PunchStuffNeedNum =< SeniorPunchNum ->
				  {0, JuniorPunchNum, MiddlePunchNum, SeniorPunchNum - PunchStuffNeedNum};
			  true ->
				  {1, JuniorPunchNum, MiddlePunchNum, 0}
		   end
	end.

get_punch_stuff_config(EquipPunchNum) ->
	case catch mod_refining_firing:get_punch_stuff_config(EquipPunchNum) of
		{error, _, 0} ->
			?THROW_SYS_ERR();
		false ->
			?THROW_SYS_ERR();
		Config ->
			Config
	end.

%%=============================
%% Common Function
%%=============================
%%获取背包中已有的锻造材料
get_firing_stuff_num(RoleID, StuffTypeId) ->
	case mod_bag:get_goods_by_typeid(RoleID,StuffTypeId,[1,2,3]) of
		{ok, []} ->
			0;
		{ok, GoodList} ->
			GoodsNum = 
				lists:foldl(
				  fun(Goods, AccNum) -> 
						  Goods#p_goods.current_num + AccNum 
				  end, 0, GoodList),
			GoodsNum
	end.

get_firing_stuff_price(StuffTypeId, AutoBuyNum) ->
    %% 按照商城-锻造价格
	case mod_shop:get_goods_price_ex(80111,StuffTypeId) of
		{ok, {PriceBind, gold, Price}} ->
			{PriceBind, gold, Price * AutoBuyNum};
		{ok, {PriceBind, silver, Price}} ->
			{PriceBind, silver, Price * AutoBuyNum};
		_ ->
			?THROW_SYS_ERR()
	end.

calc_firing_stuff_price(PriceBind, gold, Price) ->
	if PriceBind =:= 3 ->
		   {0,0,Price,0};
	   true ->
		   {0,0,0,Price}
	end;
calc_firing_stuff_price(PriceBind, silver, Price) ->
	if PriceBind =:= 3 ->
		   {Price,0,0,0};
	   true ->
		   {0,Price,0,0}
	end.

get_equip_reinforce_level_grade(EquipGoods) ->
	{EquipGoods#p_goods.reinforce_result div 10, EquipGoods#p_goods.reinforce_result rem 10}.

get_role_attr(RoleId) ->
	case mod_map_role:get_role_attr(RoleId) of
		{ok, RoleAttr} ->
			RoleAttr;
		_ ->
			?THROW_SYS_ERR()
	end.

log_money_usage(Type, RoleId, OldRoleAttr, NewRoleAttr, Fee) ->
	{CONSUME_TYPE_EQUIP_FEE, CONSUME_SILVER_AUTO_BUY_STUFF, CONSUME_GOLD_AUTO_BUY_STFF} = 
		case Type of
			reinforce ->
				{?CONSUME_TYPE_SILVER_EQUIP_REINFORCE, ?CONSUME_TYPE_SILVER_AUTO_BUY_REINFORCE_STUFF, ?CONSUME_TYPE_GOLD_AUTO_BUY_REINFORCE_STUFF};
			upprop ->
				{?CONSUME_TYPE_SILVER_EQUIP_BIND, ?CONSUME_TYPE_SILVER_AUTO_BUY_UPPROP_STUFF, ?CONSUME_TYPE_GOLD_AUTO_BUY_UPPROP_STUFF};
			punch ->
				{?CONSUME_TYPE_SILVER_EQUIP_PUNCH, ?CONSUME_TYPE_SILVER_AUTO_BUY_PUNCH_STUFF, ?CONSUME_TYPE_GOLD_AUTO_BUY_PUNCH_STUFF}
		end,
	Gold = OldRoleAttr#p_role_attr.gold - NewRoleAttr#p_role_attr.gold,
	GoldBind = OldRoleAttr#p_role_attr.gold_bind - NewRoleAttr#p_role_attr.gold_bind,
	Silver = OldRoleAttr#p_role_attr.silver - NewRoleAttr#p_role_attr.silver,
	SilverBind = OldRoleAttr#p_role_attr.silver_bind - NewRoleAttr#p_role_attr.silver_bind,
	common_consume_logger:use_gold({RoleId, GoldBind, Gold, CONSUME_GOLD_AUTO_BUY_STFF, ""}),
	
	%% 先扣除买石头的费用，再扣除操作费用
	AutoBuyFee = Silver + SilverBind - Fee,
	case {AutoBuyFee > 0 , AutoBuyFee >= SilverBind} of
		{true, true} ->
			common_consume_logger:use_silver({RoleId, SilverBind, (Silver - Fee), CONSUME_SILVER_AUTO_BUY_STUFF, ""}),	
			common_consume_logger:use_silver({RoleId, 0, Fee, CONSUME_TYPE_EQUIP_FEE, ""});
		{true, false} ->
			common_consume_logger:use_silver({RoleId, AutoBuyFee, 0, CONSUME_SILVER_AUTO_BUY_STUFF, ""}),	
			common_consume_logger:use_silver({RoleId, (SilverBind-AutoBuyFee), Silver, CONSUME_TYPE_EQUIP_FEE, ""});
		{false, _} ->
			common_consume_logger:use_silver({RoleId, 0, 0, CONSUME_SILVER_AUTO_BUY_STUFF, ""}),
		   common_consume_logger:use_silver({RoleId, SilverBind, Silver, CONSUME_TYPE_EQUIP_FEE, ""})
	end.

check_equip_type(Type, RoleId, FiringEquip) ->
	case FiringEquip#p_refining.firing_type =:= ?FIRING_TYPE_TARGET 
									andalso FiringEquip#p_refining.goods_type =:= ?TYPE_EQUIP of
		true ->
			next;
		false ->
			?THROW_ERR(?ERR_REFINING_AUTO_NOT_EQUIP)
	end,
	EquipGoods=
		case mod_bag:check_inbag(RoleId,FiringEquip#p_refining.goods_id) of
			{ok,EquipGoodsT} ->
				EquipGoodsT;
			_  ->
				?THROW_ERR(?ERR_REFINING_AUTO_CAN_NOT_MANY_EQUIP)
		end,
	check_equip_can_refining(Type, EquipGoods),
	EquipGoods.

check_equip_can_refining(reinforce, EquipGoods) ->
	check_equip_can_refining2(EquipGoods, ?ERR_REFINING_AUTO_REINFORCE_MOUNT, ?ERR_REFINING_AUTO_REINFORCE_FASHION, ?ERR_REFINING_AUTO_REINFORCE_ADORN);
check_equip_can_refining(upprop, EquipGoods) ->
	check_equip_can_refining2(EquipGoods, ?ERR_REFINING_AUTO_UPPROP_MOUNT, ?ERR_REFINING_AUTO_UPPROP_FASHION, ?ERR_REFINING_AUTO_UPPROP_ADORN);
check_equip_can_refining(punch, EquipGoods) ->
	check_equip_can_refining2(EquipGoods, ?ERR_REFINING_AUTO_PUNCH_MOUNT, ?ERR_REFINING_AUTO_PUNCH_FASHION, ?ERR_REFINING_AUTO_PUNCH_ADORN).

check_equip_can_refining2(EquipGoods, ERR_REFINING_AUTO_MOUNT, ERR_REFINING_AUTO_FASHION, ERR_REFINING_AUTO_ADORN) ->
    [EquipBaseInfo] = common_config_dyn:find_equip(EquipGoods#p_goods.typeid),
    if EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
           ?THROW_ERR(ERR_REFINING_AUTO_MOUNT);
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
           ?THROW_ERR(ERR_REFINING_AUTO_FASHION);
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
           ?THROW_ERR(ERR_REFINING_AUTO_ADORN);
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_JINGJIE ->
           ?THROW_ERR(ERR_REFINING_AUTO_ADORN);
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_SHENQI ->
           ?THROW_ERR(ERR_REFINING_AUTO_ADORN);
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MARRY ->
           ?THROW_ERR(ERR_REFINING_AUTO_ADORN);
       true ->
           next
    end,
	[SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
	case lists:member(EquipGoods#p_goods.typeid,SpecialEquipList) of
		true ->
			?THROW_ERR(ERR_REFINING_AUTO_ADORN);
		_ ->
			next
	end.

log_stuff_usage(RoleId,DelList,LogType) ->
	if DelList =/= [] ->
		   [StuffGoods | _T] = DelList,
		   catch common_item_logger:log(RoleId,StuffGoods,erlang:length(DelList),LogType);
	   true ->
		   ignore
	end.

deduct_goods_by_typeid(RoleId, StuffTypeId, DeductNum) ->
	case DeductNum > 0 of
		true ->
			{ok, UpList3, DelList3} = 
				mod_bag:decrease_goods_by_typeid(RoleId, StuffTypeId, DeductNum),
			{UpList3, DelList3};
		false ->
			{[],[]}
	end.

%% 是否使用了绑定的钱币或元宝去购买
is_buy_stuff_with_bind_money(RoleAttr, StuffTypeId, AutoBuyNum) ->
	IsHasSilverBind = RoleAttr#p_role_attr.silver_bind > 0,
	IsHasGoldBind = RoleAttr#p_role_attr.gold_bind > 0,
	if AutoBuyNum > 0 ->
		   case {get_firing_stuff_price(StuffTypeId, AutoBuyNum), IsHasSilverBind, IsHasGoldBind} of 
			   {{PriceBind, gold, Price}, _, true} when PriceBind =/= 3 andalso Price > 0 ->
				   true;
			   {{PriceBind, silver, Price}, true, _} when PriceBind =/= 3 andalso Price > 0 ->
				   true;
			   _ ->
				   false
		   end;
	   true ->
		   false
	end.

calc_refining_fee(Type,EquipGoods, Level) ->
	case catch mod_refining:get_refining_fee(Type,EquipGoods, Level) of
		{error, _, _} ->
			?THROW_SYS_ERR();
		Fee ->
			Fee
	end.

%% 计算单次锻造需消耗的钱币与元宝
%% 高级强化石只能用元宝来购买的
%% 费用包括： 锻造所需的操作费用 + 购买锻造材料的费用
calc_refining_need_money(StuffTypeId, AutoBuyNum, RefiningFee) ->
	{PriceBind, MoneyType, Price} = get_firing_stuff_price(StuffTypeId, AutoBuyNum),
	{SilverFee, SilverBindFee, GoldFee, GoldBindFee} = calc_firing_stuff_price(PriceBind, MoneyType, Price),
	SilverBind = RefiningFee + SilverBindFee,
	{SilverFee, SilverBind, GoldFee, GoldBindFee}.

%% 是否使用了背包中绑定的材料
is_use_bind_stuff(UpList, DelList) ->
	lists:any(fun(Goods) -> Goods#p_goods.bind =:= true end, UpList) orelse 
		lists:any(fun(Goods) -> Goods#p_goods.bind =:= true end, DelList).

sum_equip_bind_attr_level(AttrList) ->
	lists:foldl(
	  fun(Attr, Acc) -> Attr#p_equip_bind_attr.attr_level + Acc end, 0, AttrList). 
