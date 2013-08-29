%%% @author fsk 
%%% @doc
%%%     时装装备强化
%%% @end
%%% Created : 2012-6-28
%%%-------------------------------------------------------------------
-module(mod_qianghua).

-include("mgeem.hrl").
-include("refining.hrl").

-export([
			handle/1,
			handle/2,
			can_qianghua/2,
			fix_fashion_level/1,
			get_deduct_goods_detail/2,
			t_deduct_material_goods/2,
			give_qianghua_level/1,
			reset_equip_bind_attr/2,
			cross_equip_upgrade_mission/3
			% equip_update_mission/2
		]).

-record(r_equip_upgrade,{typeid,reinforce_result_limit,target_typeid,target_color,reduce_arg1,reduce_arg2,keep_level_cost_gold,material_list}).

-record(reinforce_conf, {
		put_on_lv     = 0, 		%% 穿戴等级
		add           = 0, 		%% 每级强化加点
		
		prestige_cost = 0, 		%% 升级扣取的声望基数
		prestige_arg1 = 0, 		%% 参数1
		prestige_arg2 = 0, 		%% 参数2
		prestige_arg3 = 0, 		%% 参数3
		
		silver_cost   = 0, 		%% 升级扣取的声望基数
		silver_arg1   = 0, 		%% 参数1
		silver_arg2   = 0, 		%% 参数2
		silver_arg3   = 0 		%% 参数3
	}).

-define(ERR_QIANGHUA_NOT_LEGAL_EQUIP,813001).%%该装备不能强化
-define(ERR_QIANGHUA_NOT_ENOUGH_GOLD,813002).%%礼券不足
-define(ERR_QIANGHUA_NOT_ENOUGH_SILVER,813003).%%钱币不足
-define(ERR_QIANGHUA_NOT_ENOUGH_MATERIAL_ITEM,813004).%%材料不足
-define(ERR_QIANGHUA_MAX_BAG_NUM,813005). %%背包空间不足
-define(ERR_QIANGHUA_EQUIP_NOT_IN_BAG,813006). %%背包没该装备
-define(ERR_QIANGHUA_NOT_ENOUGH_PRESTIGE,813007).%%声望不足
-define(ERR_QIANGHUA_NOT_ENOUGH_REINFORCE_RESULT,813008).%%装备强化等级不够，不能进阶
-define(ERR_QIANGHUA_NOT_ENOUGH_ROLE_LEVEL,813009).%%强化等级不能高于玩家等级
-define(ERR_QIANGHUA_UPGRADE_NOT_ENOUGH_ROLE_LEVEL,813010).%%玩家等级必须大于强化目标装备的穿戴等级
-define(ERR_QIANGHUA_EQUIP_NOT_IN_BODY,813011). %%身上没该装备
-define(ERR_QIANGHUA_EQUIP_REINFORCE_FAIL,813012). %%强化概率性失败
-define(ERR_QIANGHUA_EQUIP_NOT_FOREVER,813013). %%非永久装备不能进阶
-define(ERR_QIANGHUA_EQUIP_NOT_LOADED,813014). %%身上没有该装备

-define(IN_BAG,0).%%在背包强化
-define(IN_BODY,1).%%在身上强化

-define(OP_TYPE_UPGRADE,0).%%进阶
-define(OP_TYPE_UPGRADE_COLOR,1).%%提色

-define(EQUIP_REINFORCE_PROTECT_LEVEL,20).%%强化成功率保护等级（小于等于20级100%成功)

handle(Msg,_State) ->
	handle(Msg).

handle({_,?EQUIP, ?EQUIP_REINFORCE, _,_,_}=Info) ->
	equip_reinforce(Info);
handle({_,?EQUIP, ?EQUIP_UPGRADE, _,_,_}=Info) ->
	equip_upgrade(Info);
handle(Info) ->
	?ERROR_MSG("receive unknown message,Info=~w",[Info]),
	ignore.

%% 装备是否可强化
can_qianghua(TypeID,Type) when Type =:= ?TYPE_EQUIP ->
	cfg_qianghua:can_qianghua(TypeID);
can_qianghua(_TypeID,_Type) ->
	false.

equip_reinforce({Unique, Module, Method, DataIn, RoleID, PID}) ->
	#m_equip_reinforce_tos{equipid=QianghuaEquipID,num=Num,pos=Pos,auto_buy=AutoBuy,gold_reinforce=GoldReinforce} = DataIn,
	case catch check_equip_reinforce(RoleID,QianghuaEquipID,Num,Pos) of
		{error,ErrCode,Reason} ->
			?UNICAST_TOC(#m_equip_reinforce_toc{err_code=ErrCode,reason=Reason});
		{ok,QianghuaEquipInfo} ->
			TransFun = fun()-> 
							   t_equip_reinforce(RoleID,QianghuaEquipInfo,Num,Pos,AutoBuy,GoldReinforce)
					   end,
			case common_transaction:t( TransFun ) of
				{atomic, {ok,FinalRoleAttr,FinalQianghuaEquipInfo,_FinalPrestigeCost,FinalSilverCost,AddReinforceResult,_IsBreak,DeleteList,UpdateList,DeductGoodsDetail,NeedCostGold,IsSuccess,SucTimes}} ->
					common_misc:del_goods_notify(PID,DeleteList),
					common_misc:update_goods_notify(PID,UpdateList),
					case DeductGoodsDetail of
						null -> nil;
						_ ->
							lists:foreach(
							  fun({TypeID,NeedNum}) ->
									  ?TRY_CATCH( common_item_logger:log(RoleID,TypeID,NeedNum,undefined,?LOG_ITEM_TYPE_EQUIP_REINFORCE_AUTO_BUY) )
							  end,DeductGoodsDetail)
					end,
					#p_role_attr{gold=Gold,gold_bind=GoldBind,
								 silver=Silver,silver_bind=SilverBind, 
								 sum_prestige=SumPrestige,cur_prestige=CurPrestige} = FinalRoleAttr,
					ChangeAttList = [#p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE,new_value=GoldBind},
									 #p_role_attr_change{change_type=?ROLE_GOLD_CHANGE,new_value=Gold},
									 #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE,new_value=SilverBind},
									 #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE,new_value=Silver},
									 #p_role_attr_change{change_type=?ROLE_SUM_PRESTIGE_CHANGE,new_value=SumPrestige},
									 #p_role_attr_change{change_type=?ROLE_CUR_PRESTIGE_CHANGE,new_value=CurPrestige}
									],
					common_misc:role_attr_change_notify({pid, PID}, RoleID, ChangeAttList),
					Text = 
						case NeedCostGold > 0 of
							true -> lists:concat(["，礼券",NeedCostGold]);
							false -> ""
						end,
					case IsSuccess of
						true ->
							?ROLE_SYSTEM_BROADCAST(RoleID,common_misc:format_lang("强化~w级，成功~w级，消耗钱币~s~s。",[AddReinforceResult,SucTimes,common_misc:format_silver(FinalSilverCost),Text])),
							?UNICAST_TOC(#m_equip_reinforce_toc{equip=FinalQianghuaEquipInfo,pos=Pos}),
							case Pos of
								?IN_BODY -> 
									mod_role_event:notify(RoleID, {?ROLE_EVENT_EQUIP_PUT, FinalQianghuaEquipInfo}),
									update_role_base(RoleID, QianghuaEquipInfo, FinalQianghuaEquipInfo);
								_ -> nil
							end,
							hook_qianghua:hook_equip_qianghua(RoleID, FinalQianghuaEquipInfo,FinalRoleAttr#p_role_attr.equips);
						false ->
							?ROLE_SYSTEM_BROADCAST(RoleID,common_misc:format_lang("强化失败，消耗钱币~s~s。",[common_misc:format_silver(FinalSilverCost),Text])),
							?UNICAST_TOC(#m_equip_reinforce_toc{err_code=?ERR_QIANGHUA_EQUIP_REINFORCE_FAIL})
					end,
					%% 特殊任务事件
    				hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_REINFORCE),
					mod_random_mission:handle_event(RoleID,?RAMDOM_MISSION_EVENT_7);
				{atomic, {ok,FinalRoleAttr,FinalQianghuaEquipInfo,_ReturnPrestige,ReturnSilver}} ->
					common_misc:send_role_silver_change(RoleID,FinalRoleAttr),
					common_misc:send_role_gold_change(RoleID,FinalRoleAttr),
					Text = case ReturnSilver > 0 of
							   true -> lists:concat(["，返还钱币",common_misc:format_silver(ReturnSilver)]);
							   false -> ""
						   end,
					mod_random_mission:handle_event(RoleID,?RAMDOM_MISSION_EVENT_7),
					%% 特殊任务事件
    				hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_REINFORCE),
					?ROLE_SYSTEM_BROADCAST(RoleID,common_misc:format_lang("强化重置成功~s",[Text])),
					?UNICAST_TOC(#m_equip_reinforce_toc{equip=FinalQianghuaEquipInfo,pos=Pos}),
					case Pos of
						?IN_BODY -> 
							mod_role_event:notify(RoleID, {?ROLE_EVENT_EQUIP_PUT, FinalQianghuaEquipInfo}),
							update_role_base(RoleID, QianghuaEquipInfo, FinalQianghuaEquipInfo);
						_ -> nil
					end;
				{aborted, {error,?ERR_QIANGHUA_NOT_ENOUGH_MATERIAL_ITEM,NeedCostGold}} ->
					?UNICAST_TOC(#m_equip_reinforce_toc{err_code=?ERR_QIANGHUA_NOT_ENOUGH_MATERIAL_ITEM,need_gold=NeedCostGold});
				{aborted, AbortErr} ->
					{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
					case ErrCode == 4 of
						true -> %% 坑爹的配置错误
							?ERROR_MSG("cfg_qianghua config error: ~w", [Reason]);
						false -> ok
					end,
					?UNICAST_TOC(#m_equip_reinforce_toc{err_code=ErrCode,reason=Reason})
			end
	end.

check_equip_reinforce(RoleID,QianghuaEquipID,Num,Pos) ->
	case Num < 0 of
		true -> ?THROW_SYS_ERR();
		false -> next
	end,
	if
		Pos =:= ?IN_BAG ->
			case mod_bag:check_inbag(RoleID,QianghuaEquipID) of
				{ok,QianghuaEquipInfo} ->
					next;
				_ ->
					QianghuaEquipInfo = null,
					?THROW_ERR(?ERR_QIANGHUA_EQUIP_NOT_IN_BAG)
			end;
		Pos =:= ?IN_BODY ->
			{ok,#p_role_attr{equips=Equips}} = mod_map_role:get_role_attr(RoleID),
			case lists:keyfind(QianghuaEquipID, #p_goods.id, Equips) of
				false ->
					QianghuaEquipInfo = null,
					?THROW_ERR(?ERR_QIANGHUA_EQUIP_NOT_IN_BODY);
				QianghuaEquipInfo ->
					next
			end;
		true ->
			QianghuaEquipInfo = null,
			?THROW_SYS_ERR()
	end,
	#p_goods{typeid=TypeID,type=Type}=QianghuaEquipInfo,
	case can_qianghua(TypeID,Type) of
		true ->
			{ok,QianghuaEquipInfo};
		false ->
			?THROW_ERR(?ERR_QIANGHUA_NOT_LEGAL_EQUIP)
	end.

t_equip_reinforce(RoleID,#p_goods{id=ID,typeid=TypeID,reinforce_result=ReinforceResult}=QianghuaEquipInfo,Num,Pos,AutoBuy,GoldReinforce) when Num > 0 ->
	{ok,#p_role_attr{level=RoleLevel,equips=Equips}=RoleAttrTmp} = mod_map_role:get_role_attr(RoleID),
	case t_equip_reinforce_cost_item(RoleID,RoleAttrTmp,TypeID,AutoBuy) of
		nil -> 
			DeleteList = UpdateList = DeductGoodsDetail = null,
			NeedCostGold = 0,
			RoleAttr = RoleAttrTmp;
		{ok,RoleAttr,DeleteList,UpdateList,DeductGoodsDetail,NeedCostGold} ->
			next
	end,
	AddReinforceResult = erlang:min((RoleLevel - ReinforceResult),Num),
	case AddReinforceResult =:= 0 of
		true ->
			?THROW_ERR(?ERR_QIANGHUA_NOT_ENOUGH_ROLE_LEVEL);
		false ->
			next
	end,
	case catch
					lists:foldl(fun(_I,{AccQianghuaEquipInfo,AccRoleAttr,AccPrestigeCost,AccSilverCost,AccAddReinforceResult,AccGoldCost,AccReiforceSucTimes})->
										{IsSuccess,NewAccRoleAttr,NeedCostGold1} = t_equip_reinforce_success_probability(RoleID,AccRoleAttr,GoldReinforce,AccQianghuaEquipInfo#p_goods.reinforce_result),
										{NewQianghuaEquipInfo1,NewPrestigeCost,NewSilverCost} = reset_equip_bind_attr(AccQianghuaEquipInfo,_AddReinforceResult=1),
										case IsSuccess of
												true ->
													NewQianghuaEquipInfo = NewQianghuaEquipInfo1,
													NewAccReiforceSucTimes = AccReiforceSucTimes + 1;
												_ ->
													NewQianghuaEquipInfo = AccQianghuaEquipInfo,
													NewAccReiforceSucTimes = AccReiforceSucTimes
											end,
										NewAccGoldCost = AccGoldCost + NeedCostGold1,
										case t_deduct_cost(prestige,NewPrestigeCost,NewAccRoleAttr) of
											{ok,NewRoleAttr} ->
												case t_deduct_cost(silver,NewSilverCost,NewRoleAttr) of
													{ok,NewRoleAttr2} ->
														{NewQianghuaEquipInfo,NewRoleAttr2,
														 AccPrestigeCost+NewPrestigeCost,
														 AccSilverCost+NewSilverCost,
														 AccAddReinforceResult+1,NewAccGoldCost,NewAccReiforceSucTimes};
													_ ->
														throw({silver_not_enough,AccQianghuaEquipInfo,NewAccRoleAttr,AccPrestigeCost,AccSilverCost,AccAddReinforceResult,NewAccGoldCost,NewAccReiforceSucTimes})
												end;
											_ ->
												throw({prestige_not_enough,AccQianghuaEquipInfo,NewAccRoleAttr,AccPrestigeCost,AccSilverCost,AccAddReinforceResult,NewAccGoldCost,NewAccReiforceSucTimes})
										end
								end,{QianghuaEquipInfo,RoleAttr,0,0,0,0,0},lists:seq(1, AddReinforceResult)) of
		{error,ErrCode,Reason}->
			IsBreak = FinalPrestigeCost = FinalQianghuaEquipInfo = FinalRoleAttr = FinalAddReinforceResult = FinalSilverCost= NotEnough = FinalGoldCost = FinalSucTimes = null,
			throw({error,ErrCode,Reason});
		{NotEnough,FinalQianghuaEquipInfo,FinalRoleAttr,FinalPrestigeCost,FinalSilverCost,FinalAddReinforceResult,FinalGoldCost,FinalSucTimes} ->
			IsBreak = true;
		{FinalQianghuaEquipInfo,FinalRoleAttr,FinalPrestigeCost,FinalSilverCost,FinalAddReinforceResult,FinalGoldCost,FinalSucTimes} ->
			IsBreak = false, NotEnough = null
	end,
	case FinalQianghuaEquipInfo =:= QianghuaEquipInfo of
		true ->
			case NotEnough of
				prestige_not_enough ->
					?THROW_ERR(?ERR_QIANGHUA_NOT_ENOUGH_PRESTIGE);
				silver_not_enough ->
					?THROW_ERR(?ERR_QIANGHUA_NOT_ENOUGH_SILVER);
				_ ->
					next
			end;
		false ->
			next
	end,
	%%非永久装备判断是否可永久化
	ForeverFinalQianghuaEquipInfo = mod_equip_renewal:t_forever_equip(FinalQianghuaEquipInfo),
	case FinalSucTimes > 0 of
		true ->
			IsSuc = true,
			case Pos of
				?IN_BAG ->
					NewFinalRoleAttr2 = FinalRoleAttr,
					mod_bag:update_goods(RoleID,ForeverFinalQianghuaEquipInfo);
				?IN_BODY ->
					NewFinalRoleAttr2 = FinalRoleAttr#p_role_attr{equips=[ForeverFinalQianghuaEquipInfo|lists:keydelete(ID,#p_goods.id,Equips)]}
			end;
		false ->
			IsSuc = false,
			NewFinalRoleAttr2 = FinalRoleAttr
	end,
	mod_map_role:set_role_attr(RoleID, NewFinalRoleAttr2),
	{ok,NewFinalRoleAttr2,ForeverFinalQianghuaEquipInfo,FinalPrestigeCost,FinalSilverCost,FinalAddReinforceResult,IsBreak,DeleteList,UpdateList,DeductGoodsDetail,NeedCostGold+FinalGoldCost,IsSuc,FinalSucTimes};

%% 归零
t_equip_reinforce(RoleID,#p_goods{id=ID,typeid=TypeID,reinforce_result=ReinforceResult}=QianghuaEquipInfo,Num,Pos,_AutoBuy,GoldReinforce) when Num =:= 0 ->
	case ReinforceResult =:= 0 of
		true -> ?THROW_ERR_REASON(<<"不需要强化重置">>);
		false -> next
	end,

	VipLevel = mod_vip:get_role_vip_level(RoleID),
	DeductGold = cfg_qianghua:gold_reinforce_cost(VipLevel),
	if
		GoldReinforce ->
			common_bag2:check_money_enough_and_throw(gold_unbind,DeductGold,RoleID);
		true ->
			ok
	end, 

	{ReturnPrestige,ReturnSilver} = calc_return_cost(QianghuaEquipInfo, GoldReinforce, VipLevel),
	{ok,#p_role_attr{equips=Equips}=RoleAttr} = mod_map_role:get_role_attr(RoleID),
	{ok,PrestigeRoleAttr} = t_return_cost(prestige,ReturnPrestige,RoleAttr),
	{ok,FinalRoleAttr} = t_return_cost(silver,ReturnSilver,PrestigeRoleAttr),
	[#p_equip_base_info{property=Property}] = common_config_dyn:find_equip(TypeID),
	FinalQianghuaEquipInfo = QianghuaEquipInfo#p_goods{add_property=Property,reinforce_result=0,equip_bind_attr=[]},
	case Pos of
		?IN_BAG ->
			NewFinalRoleAttr = FinalRoleAttr,
			mod_bag:update_goods(RoleID,FinalQianghuaEquipInfo);
		?IN_BODY ->
			NewFinalRoleAttr = FinalRoleAttr#p_role_attr{equips=[FinalQianghuaEquipInfo|lists:keydelete(ID,#p_goods.id,Equips)]}
	end,
	mod_map_role:set_role_attr(RoleID, NewFinalRoleAttr),

	FinalRoleAttr2 = if
		GoldReinforce ->
			{ok, FinalRoleAttr1} = common_bag2:t_deduct_money(gold_unbind,DeductGold,RoleID, ?CONSUME_TYPE_GOLD_EQUIP_GUILIN), 
			FinalRoleAttr1;
		true ->
			NewFinalRoleAttr
	end,

	{ok,FinalRoleAttr2,FinalQianghuaEquipInfo,ReturnPrestige,ReturnSilver}.

%% 强化成功率
%% return false | {true,RoleAttr}
t_equip_reinforce_success_probability(RoleID,RoleAttr,GoldReinforce,ReinforceResult) ->
	#p_role_attr{gold_bind=GoldBind}=RoleAttr,
	TotalSuccessPro = 
		case ReinforceResult =< ?EQUIP_REINFORCE_PROTECT_LEVEL of
			true -> 100;
			_ ->
				{_, Time}     = erlang:localtime(),
				SuccessPro    = cfg_qianghua:get_qianghua_succ_probability(Time),
				VipLevel      = mod_vip:get_role_vip_level(RoleID),
				SuccessProAdd = cfg_qianghua:get_qianghua_succ_vip_add(VipLevel),
				SuccessPro + SuccessProAdd
		end,
	case 100 - TotalSuccessPro of
		DiffPro when DiffPro > 0 ->
			case GoldReinforce of
				true ->
					NeedCostGold = erlang:min(GoldBind, DiffPro),
					case common_bag2:t_deduct_money(gold_any,NeedCostGold,RoleAttr,?CONSUME_TYPE_GOLD_EQUIP_REINFORCE_SUCCESS_PROBABILITY) of
						{ok,NewRoleAttr}->
							next;
						{error,gold_any}->
							NewRoleAttr = RoleAttr;
						{error, _Reason} ->
							NewRoleAttr = RoleAttr
					end,
					NewTotalSuccessPro = TotalSuccessPro + NeedCostGold;
				false ->
					NeedCostGold = 0,
					NewTotalSuccessPro = TotalSuccessPro,
					NewRoleAttr = RoleAttr
			end;
		_ ->
			NeedCostGold = 0,
			NewTotalSuccessPro = TotalSuccessPro,
			NewRoleAttr = RoleAttr
	end,
	{NewTotalSuccessPro >= common_tool:random(0, 100),NewRoleAttr,NeedCostGold}.


%% 强化消耗材料
t_equip_reinforce_cost_item(_RoleID,_RoleAttr,_TypeID,_AutoBuy) ->
	nil.
	% case ?find_config(qianghua_cost_item) of
	% 	[] -> nil;
	% 	[CostItemConf] ->
	% 		case lists:filter(fun({TypeList,_}) ->
	% 								  lists:member(TypeID, TypeList)
	% 						  end, CostItemConf) of
	% 			[] -> nil;
	% 			[{_,MaterialList}] -> 
	% 				{DeductGoodsDetail,NeedCostGoldUnbind,NeedCostGoldAny} = get_deduct_goods_detail(RoleID,MaterialList),
	% 				case (NeedCostGoldUnbind > 0 orelse NeedCostGoldAny > 0) andalso AutoBuy =:= false of
	% 					true ->
	% 						throw({error,?ERR_QIANGHUA_NOT_ENOUGH_MATERIAL_ITEM,NeedCostGoldUnbind+NeedCostGoldAny});
	% 					false ->
	% 						case NeedCostGoldUnbind > 0 of
	% 							true ->
	% 								case common_bag2:t_deduct_money(gold_unbind,NeedCostGoldUnbind,RoleAttr,?CONSUME_TYPE_GOLD_EQUIP_REINFORCE_AUTO_BUY) of
	% 									{ok,NewRoleAttr}->
	% 										next;
	% 									{error,gold_unbind}->
	% 										NewRoleAttr = RoleAttr,
	% 										?THROW_ERR(?ERR_QIANGHUA_NOT_ENOUGH_GOLD)
	% 								end;
	% 							false ->
	% 								NewRoleAttr = RoleAttr
	% 						end,
	% 						case NeedCostGoldAny > 0 of
	% 							true ->
	% 								case common_bag2:t_deduct_money(gold_any,NeedCostGoldAny,NewRoleAttr,?CONSUME_TYPE_GOLD_EQUIP_REINFORCE_AUTO_BUY) of
	% 									{ok,NewRoleAttr2}->
	% 										next;
	% 									{error,gold_any}->
	% 										NewRoleAttr2 = NewRoleAttr,
	% 										?THROW_ERR(?ERR_QIANGHUA_NOT_ENOUGH_GOLD)
	% 								end;
	% 							false ->
	% 								NewRoleAttr2 = NewRoleAttr
	% 						end,
	% 						{ok,UpdateList,DeleteList} = t_deduct_material_goods(RoleID,DeductGoodsDetail),
	% 						{ok,NewRoleAttr2,DeleteList,UpdateList,DeductGoodsDetail,NeedCostGoldUnbind+NeedCostGoldAny}
	% 				end
	% 		end
	% end.

t_return_cost(prestige,Return,RoleID) ->
	common_bag2:t_gain_prestige(Return,RoleID,?GAIN_TYPE_PRESTIGE_EQUIP_REINFORCE_RETURN);
t_return_cost(silver,Return,RoleID) ->
	common_bag2:t_gain_money(silver_bind,Return,RoleID,?GAIN_TYPE_SILVER_EQUIP_REINFORCE_RETURN).

t_deduct_cost(prestige,Cost,RoleAttr) ->
	common_bag2:t_deduct_prestige(Cost,RoleAttr,?USE_TYPE_PRESTIGE_EQUIP_REINFORCE);
t_deduct_cost(silver,Cost,RoleAttr) ->
	common_bag2:t_deduct_money(silver_any,Cost,RoleAttr,?CONSUME_TYPE_SILVER_EQUIP_QIANGHUA).

equip_upgrade({Unique, Module, Method, DataIn, RoleID, PID}) ->
	#m_equip_upgrade_tos{op_type=OpType,equipid=QianghuaEquipID,auto_buy=AutoBuy,keep_level=KeepLevel,pos=Pos,rate=Rate} = DataIn,
	case catch check_equip_upgrade(RoleID,QianghuaEquipID,Pos,OpType) of
		{error,ErrCode,Reason} ->
			?UNICAST_TOC(#m_equip_upgrade_toc{err_code=ErrCode,reason=Reason});
		{ok,QianghuaEquipInfo,EquipUpgradeConf} ->
			TransFun = fun()-> 
							   t_equip_upgrade(RoleID,QianghuaEquipInfo,EquipUpgradeConf,AutoBuy,KeepLevel,Pos,Rate)
					   end,
			case common_transaction:t( TransFun ) of
				{atomic, {ok,ActivateSuit,RoleAttr,DeleteList,UpdateList,TargetEquipInfo,DeductGoodsDetail,NeedCostGold}} ->
					#p_goods{name=Name,current_colour=Color}=TargetEquipInfo,
					GoodsName = common_misc:format_goods_name_colour(Color,Name),
					OpTypeStr =
						case OpType of
							?OP_TYPE_UPGRADE_COLOR -> 
								hook_qianghua:hook_equip_upgrade_color(RoleID, TargetEquipInfo),
								"提色";
							_ -> 
								hook_qianghua:hook_equip_upgrade(RoleID, TargetEquipInfo),
								"进阶"
						end,
					Text = lists:concat([OpTypeStr,"成功，恭喜您获得",GoodsName]),
					common_misc:send_role_gold_change(RoleID,RoleAttr),
					case NeedCostGold > 0 of
						true ->
							Text1 = lists:concat([Text,"，消耗礼券",NeedCostGold]);
						false ->
							Text1 = Text
					end,
					?ROLE_SYSTEM_BROADCAST(RoleID,Text1),
					common_misc:del_goods_notify(PID,DeleteList),
					common_misc:update_goods_notify(PID,UpdateList),
					lists:foreach(
					  fun({TypeID,NeedNum}) ->
							  ?TRY_CATCH( common_item_logger:log(RoleID,TypeID,NeedNum,undefined,?LOG_ITEM_TYPE_EQUIP_UPGRADE_AUTO_BUY) )
					  end,DeductGoodsDetail),
					?TRY_CATCH( common_item_logger:log(RoleID,TargetEquipInfo,?LOG_ITEM_TYPE_GET_EQUIP_UPGRADE) ),
					?UNICAST_TOC(#m_equip_upgrade_toc{op_type=OpType,pos=Pos,equip=TargetEquipInfo}),
					case Pos of
						?IN_BODY ->
							mod_role_event:notify(RoleID, {?ROLE_EVENT_EQUIP_PUT, TargetEquipInfo}),
							{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
							update_role_base(ActivateSuit(RoleBase), QianghuaEquipInfo, TargetEquipInfo);
						_ -> nil
					end,
					catch mod_open_activity:hook_whole_event(RoleID);
				{aborted, {error,?ERR_QIANGHUA_NOT_ENOUGH_MATERIAL_ITEM,NeedCostGold}} ->
					?UNICAST_TOC(#m_equip_upgrade_toc{op_type=OpType,err_code=?ERR_QIANGHUA_NOT_ENOUGH_MATERIAL_ITEM,need_gold=NeedCostGold});
				{aborted, AbortErr} ->
					{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
					?UNICAST_TOC(#m_equip_upgrade_toc{op_type=OpType,err_code=ErrCode,reason=Reason})
			end
	end.

check_equip_upgrade(RoleID,QianghuaEquipID,Pos,OpType) ->
	{ok,#p_goods{typeid=TypeID,reinforce_result=ReinforceResult}=QianghuaEquipInfo} 
		= check_equip_reinforce(RoleID,QianghuaEquipID,0,Pos),
	%%非永久装备不能进阶
	case mod_equip_renewal:is_equip_forever(QianghuaEquipInfo) of
		true -> next;
		false -> ?THROW_ERR(?ERR_QIANGHUA_EQUIP_NOT_FOREVER)
	end,
	case OpType of
		?OP_TYPE_UPGRADE_COLOR -> 
			EquipUpgradeConf = cfg_qianghua:get_color_upgrade(TypeID);
		_ -> 
			EquipUpgradeConf = cfg_qianghua:get_equip_upgrade(TypeID)
	end,

	#r_equip_upgrade{reinforce_result_limit=Limit,target_typeid=TargetTypeID}=EquipUpgradeConf,
	[EquipBaseInfo] = common_config_dyn:find_equip(TargetTypeID),
	%%玩家等级必须大于目标装备穿戴等级
	case role_level(RoleID) < (EquipBaseInfo#p_equip_base_info.requirement)#p_use_requirement.min_level of
		true ->
			?THROW_ERR(?ERR_QIANGHUA_UPGRADE_NOT_ENOUGH_ROLE_LEVEL);
		false ->
			next
	end,
	case ReinforceResult < Limit of
		true ->
			?THROW_ERR(?ERR_QIANGHUA_NOT_ENOUGH_REINFORCE_RESULT);
		false ->
			{ok,QianghuaEquipInfo,EquipUpgradeConf}
	end.

t_equip_upgrade(RoleID,QianghuaEquipInfo,EquipUpgradeConf,AutoBuy,KeepLevel,Pos,Rate) ->
	#r_equip_upgrade{keep_level_cost_gold=KeepLevelCostGold,material_list=MaterialList}=EquipUpgradeConf,
	{DeductGoodsDetail,NeedCostGoldUnbind,NeedCostGoldAny} = get_deduct_goods_detail(RoleID,MaterialList),
	case (NeedCostGoldUnbind > 0 orelse NeedCostGoldAny > 0) andalso AutoBuy =:= false of
		true ->
			throw({error,?ERR_QIANGHUA_NOT_ENOUGH_MATERIAL_ITEM,NeedCostGoldUnbind+NeedCostGoldAny});
		false ->
			{ok,#p_role_attr{equips=Equips, skin=Skin}=RoleAttr} = mod_map_role:get_role_attr(RoleID),

			GoldUnBind0 = case KeepLevel of
				true  -> KeepLevelCostGold;
				false -> 0
			end,
			GoldUnBind = case NeedCostGoldUnbind > 0 of
				true  -> NeedCostGoldUnbind + GoldUnBind0;
				false -> GoldUnBind0
			end,

			GoldAny = case NeedCostGoldAny > 0 of
				true ->
					NeedCostGoldAny;
				false ->
					0
			end,
			common_bag2:check_money_enough_and_throw(GoldAny,GoldUnBind,RoleID), 
			{ok,UpdateList,DeleteList2} = t_deduct_material_goods(RoleID,DeductGoodsDetail),
			{ok,TargetEquipInfo} = t_create_equip(RoleID,QianghuaEquipInfo,EquipUpgradeConf,KeepLevel,Rate),
			#p_goods{id=QianghuaEquipID,loadposition=LoadPosition} = QianghuaEquipInfo,
			case GoldUnBind > 0 of
				true ->
					case common_bag2:t_deduct_money(GoldAny,GoldUnBind,RoleAttr,?CONSUME_TYPE_GOLD_EQUIP_UPGRADE_AUTO_BUY) of
						{ok,NewRoleAttr3}->
							next;
						{error, Reason} ->
							NewRoleAttr3 = RoleAttr,
					 		?THROW_ERR(?ERR_OTHER_ERR, Reason)
					end;
				false ->
					case common_bag2:t_deduct_money(gold_any,GoldAny,RoleAttr,?CONSUME_TYPE_GOLD_EQUIP_UPGRADE_AUTO_BUY) of
						{ok,NewRoleAttr3}->
							next;
						{error, Reason} ->
							NewRoleAttr3 = RoleAttr,
					 		?THROW_ERR(?ERR_OTHER_ERR, Reason)
					end
			end,
			case Pos of
				?IN_BAG ->
					{ok,DeleteList} = mod_bag:delete_goods(RoleID,QianghuaEquipInfo#p_goods.id),
					{ok,[NewTargetEquipInfo|_]} = mod_bag:create_goods_by_p_goods(RoleID,TargetEquipInfo),
					ActivateSuit = undefined,
					NewRoleAttr4 = NewRoleAttr3;
				?IN_BODY ->
					DeleteList = [],
					NewTargetEquipInfo = TargetEquipInfo#p_goods{id=QianghuaEquipID,loadposition=LoadPosition},
					NewEquips = [NewTargetEquipInfo|lists:keydelete(QianghuaEquipID, #p_goods.id, Equips)],
					{ok, NewEquips2, ActivateSuit} = mod_equip_suit:update(Equips, NewEquips),
					NewSkin = case LoadPosition of
						?PUT_ARM ->
							Skin#p_skin{weapon=NewTargetEquipInfo#p_goods.typeid};
						_ ->
							Skin
					end,
					NewRoleAttr4 = NewRoleAttr3#p_role_attr{equips=NewEquips2, skin=NewSkin}
			end,
			mod_map_role:set_role_attr(RoleID, NewRoleAttr4),
			{ok,ActivateSuit,NewRoleAttr4,lists:flatten([DeleteList,DeleteList2]),lists:flatten([UpdateList,NewTargetEquipInfo]),NewTargetEquipInfo,DeductGoodsDetail,NeedCostGoldUnbind+NeedCostGoldAny}
	end.
t_create_equip(RoleID,QianghuaEquipInfo,EquipUpgradeConf,KeepLevel,Rate) ->
	#p_goods{reinforce_result=ReinforceResult}=QianghuaEquipInfo,
	#r_equip_upgrade{target_typeid=TargetTypeID,target_color=TargetColor,reduce_arg1=Arg1,reduce_arg2=Arg2}=EquipUpgradeConf,
	{Quality,SubQuality} = mod_refining_tool:get_equip_quality_by_color(TargetColor),
	CreateInfo=#r_equip_create_info{role_id=RoleID,bag_id=0,bagposition=0,
									num=1,typeid=TargetTypeID,
									bind=true,start_time=0,end_time=0,
									color=TargetColor,quality=Quality,sub_quality=SubQuality},
	case common_bag2:creat_equip_without_expand(CreateInfo) of
		{ok,[TargetGoods|_T]} ->
			next;
		_ ->
			TargetGoods = null,
			?THROW_SYS_ERR()
	end,
	ReduceReinforceResult = 
		case KeepLevel of
			true -> 0;
			false ->
%% 				LevelUpWeightsList = cfg_qianghua:get_upgrade_level_down_rate((EquipUpgradeConf#r_equip_upgrade.reinforce_result_limit div 10)+1),
%% 				{Weight,_} = common_tool:random_from_tuple_weights(LevelUpWeightsList, 2),
				common_tool:ceil((Arg1+common_tool:ceil((ReinforceResult-Arg2)/5))*Rate)
		end,
	{NewTargetGoods,_,_} = reset_equip_bind_attr(TargetGoods#p_goods{reinforce_result=ReinforceResult},-ReduceReinforceResult),
	{ok,NewTargetGoods}.

reset_equip_bind_attr(QianghuaEquipInfo,AddReinforceResult) ->
	#p_goods{typeid=TypeID,level=Level,reinforce_result=ReinforceResult,equip_bind_attr=PEquipBindAttrList,add_property=AddProperty} = QianghuaEquipInfo,
	RecordInfo = record_info(fields,p_property_add),
	[EquipBaseInfo] = common_config_dyn:find_equip(TypeID),
	NewReinforceResult = ReinforceResult+AddReinforceResult,
	{REquipBindAttrList,TotalPrestigeCost,TotalSilverCost} = 
		lists:foldl(fun(E,{Acc,AccTotalPrestigeCost,AccTotalSilverCost}) ->
							Key = lists:nth(E-1, RecordInfo),
							case cfg_qianghua:get_property_mapping(Key) of
								false ->
									{Acc,AccTotalPrestigeCost,AccTotalSilverCost};
								AttrCode ->
									Val = erlang:element(E,AddProperty),
									case Val > 0 of
										true ->
											case lists:keyfind(AttrCode, #r_equip_bind_attr.attr_code, Acc) of
												false ->
													{LevelAddValue,PrestigeCost,SilverCost} = qianghua_add_property_conf(TypeID,AttrCode,Level,NewReinforceResult),
													{[#r_equip_bind_attr{attr_code=AttrCode,level=1,add_type=1,value=LevelAddValue*NewReinforceResult}|Acc],
													 AccTotalPrestigeCost+PrestigeCost,AccTotalSilverCost+SilverCost};
												_ ->
													{Acc,AccTotalPrestigeCost,AccTotalSilverCost}
											end;
										false ->
											{Acc,AccTotalPrestigeCost,AccTotalSilverCost}
									end
							end
					end,{[],0,0},lists:seq(2,erlang:tuple_size(AddProperty))),
	QianghuaEquipInfo2 = mod_refining_bind:count_bind_add_attr(
						   equip_bind_attr_p2r(PEquipBindAttrList),del,EquipBaseInfo,QianghuaEquipInfo#p_goods{equip_bind_attr=[]}),
	QianghuaEquipInfo3 = mod_refining_bind:count_bind_add_attr(
						   REquipBindAttrList,add,EquipBaseInfo,QianghuaEquipInfo2),
	{QianghuaEquipInfo3#p_goods{bind=true,reinforce_result=NewReinforceResult},TotalPrestigeCost,TotalSilverCost}.

equip_bind_attr_p2r(PEquipBindAttrList) ->
	lists:map(fun(#p_equip_bind_attr{attr_code=AttrCode,attr_level=AttrLevel,type=Type,value=Value}) ->
		#r_equip_bind_attr{attr_code=AttrCode,level=AttrLevel,add_type=Type,value=Value}
	end,PEquipBindAttrList).

%% 计算归零返还的费用
%% return {ReturnPrestige,ReturnSilver}
calc_return_cost(QianghuaEquipInfo, GoldReinforce, VipLevel) ->
	#p_goods{typeid=TypeID,level=Level,reinforce_result=ReinforceResult,equip_bind_attr=PEquipBindAttrList} = QianghuaEquipInfo,
	{PrestigePre,SilverPre} = cfg_qianghua:get_misc(GoldReinforce),
	{PrestigeVipPre, SilverVipPre} = cfg_qianghua:get_vip_misc(VipLevel),

	{ReturnPrestigePre,ReturnSilverPre} = 
		lists:foldl(fun(L,{AccPrestige,AccSilver}) ->
							{PrestigePxre0,TotalSilverPre0} = 					   
								lists:foldl(fun(#p_equip_bind_attr{attr_code=AttrCode},{AccPrestige0,AccSilver0}) ->
													{_,CostPrestige,CostSilver} = qianghua_add_property_conf(TypeID,AttrCode,Level,L),
													{CostPrestige+AccPrestige0,CostSilver+AccSilver0}
											end,{0,0},PEquipBindAttrList),
							{PrestigePxre0+AccPrestige,TotalSilverPre0+AccSilver}
					end,{0,0},lists:seq(1,ReinforceResult)),
	{common_tool:ceil(ReturnPrestigePre*(PrestigePre + PrestigeVipPre)),common_tool:ceil(ReturnSilverPre*(SilverPre + SilverVipPre))}.

%% return {LevelAddValue,CostPrestige,CostSilver}
qianghua_add_property_conf(TypeID,AttrCode,Level,ReinforceResult) ->
	ReinforceConfRec = cfg_qianghua:qianghua_add_property(TypeID, AttrCode, Level),
	%% 升级扣取的费用基数*参数1+强化等级^参数2*参数3
	BasePrestigeCost = ReinforceConfRec#reinforce_conf.prestige_cost,
	PrestigeArg1     = ReinforceConfRec#reinforce_conf.prestige_arg1,
	PrestigeArg2     = ReinforceConfRec#reinforce_conf.prestige_arg2,
	PrestigeArg3     = ReinforceConfRec#reinforce_conf.prestige_arg3,

	BaseSilverCost = ReinforceConfRec#reinforce_conf.silver_cost,
	SilverArg1     = ReinforceConfRec#reinforce_conf.silver_arg1,
	SilverArg2     = ReinforceConfRec#reinforce_conf.silver_arg2,
	SilverArg3     = ReinforceConfRec#reinforce_conf.silver_arg3,
	{ReinforceConfRec#reinforce_conf.add,
	 common_tool:ceil(BasePrestigeCost*PrestigeArg1+math:pow(ReinforceResult,PrestigeArg2)*PrestigeArg3),
	 common_tool:ceil(BaseSilverCost*SilverArg1+math:pow(ReinforceResult,SilverArg2)*SilverArg3)}.

get_deduct_goods_detail(RoleID,MaterialList) ->
	lists:foldl(
	  fun({MaterialTypeID,NeedNum,Color},{AccGoodsList,AccNeedCostGold,AccNeedCostGoldAny}) ->
			  case mod_bag:check_inbag_by_typeid(RoleID,MaterialTypeID) of
				  {ok,FoundGoodsList} ->
					  BagNum = get_material_num_in_bag(FoundGoodsList,Color),
					  case BagNum - NeedNum of
						  RemainNum when RemainNum >= 0 ->
							  {[{MaterialTypeID,NeedNum}|AccGoodsList],AccNeedCostGold,AccNeedCostGoldAny};
						  RemainNum ->
							  case mod_shop:get_goods_price(MaterialTypeID) of
								  {MoneyType, NeedCostGold} -> next;
								  _ -> 
									  MoneyType = NeedCostGold = null,
									  ?THROW_ERR(?ERR_CONFIG_ERR)
							  end,
							  
							  case MoneyType of
								  gold_any ->
									  {[{MaterialTypeID,BagNum}|AccGoodsList],AccNeedCostGold,AccNeedCostGoldAny+(NeedCostGold*erlang:abs(RemainNum))};
								  _ ->
									  {[{MaterialTypeID,BagNum}|AccGoodsList],AccNeedCostGold+(NeedCostGold*erlang:abs(RemainNum)),AccNeedCostGoldAny}
							  end
					  end;
				  _  ->
					  case mod_shop:get_goods_price(MaterialTypeID) of
						  {MoneyType, NeedCostGold} -> next;
						  _ -> 
							  MoneyType = NeedCostGold = null,
							  ?THROW_ERR(?ERR_CONFIG_ERR)
					  end,
					  case MoneyType of
						  gold_any ->
							  {AccGoodsList,AccNeedCostGold,AccNeedCostGoldAny+(NeedCostGold*erlang:abs(NeedNum))};
						  _ ->
							  {AccGoodsList,AccNeedCostGold+(NeedCostGold*erlang:abs(NeedNum)),AccNeedCostGoldAny}
					  end
			  end
	  end,{[],0,0},MaterialList).

t_deduct_material_goods(RoleID,DeductGoodsDetail) when length(DeductGoodsDetail) > 0 ->
	{UpdateList,DeleteList} = 
		lists:foldl(fun({DelGoodsTypeID,DelGoodsNumber},{UpListAcc,DelListAcc})-> 
							{ok,UpList,DelList} = mod_bag:decrease_goods_by_typeid(RoleID,DelGoodsTypeID,DelGoodsNumber),
							{lists:merge(UpList,UpListAcc),lists:merge(DelList,DelListAcc)}
					end,{[],[]},DeductGoodsDetail),
	{ok,UpdateList,DeleteList};
t_deduct_material_goods(_RoleID,_DeductGoodsDetail) ->
	{ok,[],[]}.

get_material_num_in_bag(Goods,NeedColor) when is_record(Goods,p_goods)->
	#p_goods{current_num=Num,current_colour=Color}=Goods,
	case Color >= NeedColor of
		true -> Num;
		false -> 0
	end;
get_material_num_in_bag(FoundGoodsList,NeedColor) when is_list(FoundGoodsList)->
	lists:foldl(fun(E,AccIn)-> 
						#p_goods{current_num=Num,current_colour=Color}=E,
						case Color >= NeedColor of
							true -> AccIn + Num;
							false -> AccIn
						end
				end, 0, FoundGoodsList).

role_level(RoleID) ->
	{ok,#p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
	Level.

%%解析错误码
parse_aborted_err(AbortErr)->
	case AbortErr of
		{error,4, {Id, AttrCode, Level}} ->
			?ERROR_MSG("cfg_qianghua强化配置错误！{Id, AttrCode, Level} = {~w, ~w, ~w}", [Id, AttrCode, Level]),
			AbortReason = common_misc:format_lang("强化配置错误, 装备id：~p, 属性id: ~p, 等级: ~p",  [Id, AttrCode, Level]),
			{error,?ERR_OTHER_ERR,AbortReason};
		{error,ErrCode,_Reason} when is_integer(ErrCode) ->
			AbortErr;
		{bag_error,{not_enough_pos,_BagID}}->
			{error,?ERR_OTHER_ERR,undefined};
		{bag_error,num_not_enough}->
			{error,?ERR_OTHER_ERR,undefined};
		{error,AbortReason} when is_binary(AbortReason) ->
			{error,?ERR_OTHER_ERR,AbortReason};
		AbortReason when is_binary(AbortReason) ->
			{error,?ERR_OTHER_ERR,AbortReason};
		_ ->
			?ERROR_MSG("aborted,AbortErr=~w,stack=~w",[AbortErr,erlang:get_stacktrace()]),
			{error,?ERR_SYS_ERR,undefined}
	end.

%% return #p_goods
fix_fashion_level(Goods) ->
	#p_goods{typeid=TypeID,level=Level}=Goods,
	FixFashionList = [37000002,37000009,37000016,37000023,37000030,37000037,37200002,37200009,37200016,37200023,37200030,37200037,37300016,37300023],
	case lists:member(TypeID, FixFashionList) of
		true ->
			case common_config_dyn:find_equip(TypeID) of
				[#p_equip_base_info{requirement=#p_use_requirement{min_level=MinLevel}}]->
					case Level =/= MinLevel of
						true ->
							Goods#p_goods{level=MinLevel};
						false -> Goods
					end;
				_ -> Goods
			end;
		false ->
			Goods
	end.

give_qianghua_level(TypeID) ->
	cfg_qianghua:get_give_qianghua_level(TypeID).

cross_equip_upgrade_mission(RoleID, NeedUpgradeNum, NeedSlotNum) ->
	{ok,#p_role_attr{equips=Equips}} = mod_map_role:get_role_attr(RoleID),
	{ok, GoodsList} = mod_bag:get_bag_goods_list(RoleID),
	lists:any(fun(H) ->
		case H#p_goods.type == 3 of
			true ->
				[#p_equip_base_info{
					upgrade_num = UpgradeNum, 
					slot_num = SlotNum
				}] = common_config_dyn:find_equip(H#p_goods.typeid),

				NeedSlotNum == SlotNum andalso UpgradeNum >= NeedUpgradeNum;
			false -> false
		end
	end, Equips ++ GoodsList).

update_role_base(RoleID, OldEquip, NewEquip) ->
	mod_role_equip:update_role_base(RoleID, '-', OldEquip, '+', NewEquip).
