%% 怒神修炼
-module (mod_rage_practice).
-include("mgeer.hrl").

-export ([init_rage_practice/2, delete_rage_practice/1, handle/1, 
		  recalc/2, handle_event/3, hook_role_online/1, gm_activate_slot/1]).


-define (STATUS_NOT_ACTIVATE, 	0).  %% 未激活
-define (STATUS_ACTIVATED, 		1).  %% 已激活

-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?RAGE_PRACTICE, Method, Msg)).

-record(rage_prac_conf, {
	slot_id    = 0,		%% 槽位id = 形态id*100 + 从1开始的编号. (形态id为1，2，3，4)
	level      = 0,
	attr_type  = 0,
	attr_value = 0
	}).

init_rage_practice(RoleID, RagePracticeRec) ->
	case RagePracticeRec of 
		false -> 
			RagePracticeRec1 = #r_rage_practice{
				cur_inactivated_slot_id = cfg_rage_practice:next_slot(0)
			};
		_ -> RagePracticeRec1 = RagePracticeRec
	end,
	set_rage_practice_rec(RoleID, RagePracticeRec1).

delete_rage_practice(RoleID) ->
	mod_role_tab:erase(RoleID, r_rage_practice).

set_rage_practice_rec(RoleID, RagePracticeRec) ->
	mod_role_tab:put(RoleID, r_rage_practice, RagePracticeRec),
	RagePracticeRec.

set_rage_practice_rec(RoleID, RagePracticeRec, NewRageSlotRec) ->
	NewList = lists:keystore(NewRageSlotRec#rage_slot.slot_id, #rage_slot.slot_id, 
							 RagePracticeRec#r_rage_practice.list, NewRageSlotRec),
	set_rage_practice_rec(RoleID, RagePracticeRec#r_rage_practice{list = NewList}).

get_rage_practice_rec(RoleID) ->
	mod_role_tab:get(RoleID, r_rage_practice).

get_rage_slot_rec(RoleID, SlotId) when is_integer(RoleID) ->
	RagePracticeRec = get_rage_practice_rec(RoleID),
	get_rage_slot_rec(RagePracticeRec, SlotId);
get_rage_slot_rec(RagePracticeRec, SlotId) ->
	case lists:keyfind(SlotId, #rage_slot.slot_id, RagePracticeRec#r_rage_practice.list) of
		false ->
			#rage_slot{slot_id = SlotId, status = ?STATUS_NOT_ACTIVATE};
		RageSlotRec -> RageSlotRec
	end.

handle({_Unique, _Module, ?RAGE_PRACTICE_OP, DataIn, RoleID, _PID, _Line}) ->
	SlotId = DataIn#m_rage_practice_op_tos.slot_id,
	case DataIn#m_rage_practice_op_tos.option of
		2 -> 
			do_level_up_slot(RoleID, SlotId);
		3 ->
			do_level_up_slot_loop(RoleID, SlotId)
	end;
handle({_Unique, _Module, ?RAGE_PRACTICE_INFO, DataIn, RoleID, _PID, _Line}) ->
	case DataIn#m_rage_practice_info_tos.layer_id of
	0 -> 
		send_rage_slots_to_client(RoleID, 1),
		send_rage_slots_to_client(RoleID, 2),
		send_rage_slots_to_client(RoleID, 3),
		send_rage_slots_to_client(RoleID, 4);
	LayerId ->
		send_rage_slots_to_client(RoleID, LayerId)
	end.

hook_role_online(RoleID) ->
	start_event(RoleID).
%% ==========================================================================
do_level_up_slot(RoleID, SlotId) ->
	RagePracticeRec            = get_rage_practice_rec(RoleID),
	RageSlotRec                = get_rage_slot_rec(RagePracticeRec, SlotId),
	CurLv                      = RageSlotRec#rage_slot.level,
	{CostPrestige, CostSilver} = cfg_rage_practice:level_up_cost(SlotId, CurLv),
	IsMoneyEnough              = common_bag2:check_money_enough(silver_any, CostSilver, RoleID),
	IsPrestigeEnough           = common_bag2:check_prestige_enough(RoleID, CostPrestige),
	LayerId                    = get_layer_id(SlotId),
	MaxSlotLv                  = cfg_rage_practice:max_slot_level(LayerId),
	{ok, #p_role_attr{category = Category}} = mod_map_role:get_role_attr(RoleID),
	Ret = if
		RageSlotRec#rage_slot.status == ?STATUS_NOT_ACTIVATE ->
			{error, <<"槽位未激活">>};
		IsMoneyEnough == false -> 
			{error, ?_LANG_NOT_ENOUGH_SILVER};
		IsPrestigeEnough == false ->
			{error, <<"声望不足">>};
		RageSlotRec#rage_slot.level >= MaxSlotLv ->
			{error, <<"槽位等级已满">>};
		true -> true
	end,
	case Ret of
		{error, Reason} -> common_misc:send_common_error(RoleID, 0, Reason);
		true ->
			true=common_bag2:use_money(RoleID, silver_any, CostSilver, ?CONSUME_TYPE_SILVER_UPGRAGE_RAGE_SLOT),
			common_bag2:use_prestige(RoleID, CostPrestige, ?USE_TYPE_PRESTIGE_UPGRADE_RAGE_SLOT),
			NewRageSlotRec     = RageSlotRec#rage_slot{level = RageSlotRec#rage_slot.level + 1},
			NewRagePracticeRec = set_rage_practice_rec(RoleID, RagePracticeRec, NewRageSlotRec),
			hook_rage_slot_level_up(RoleID, SlotId, CurLv, NewRageSlotRec#rage_slot.level, NewRagePracticeRec),
			{_Slots, IsAllFull} = check_all_slots(LayerId, Category, NewRagePracticeRec),
			case  CurLv + 1 == MaxSlotLv andalso IsAllFull of
					true -> 
						if  LayerId == 4  -> 
								common_misc:common_broadcast_other(RoleID,{LayerId},?MODULE),
					        	common_misc:common_broadcast_other(RoleID,{4, LayerId},?MODULE);
					        true ->
					        	common_misc:common_broadcast_other(RoleID,{LayerId},?MODULE)
					    end;
				_ ->
					noop
			end,
			Msg = #m_rage_practice_op_toc{option = 2, slot_id = SlotId},
			?MOD_UNICAST(RoleID, ?RAGE_PRACTICE_OP, Msg),
			send_rage_slots_to_client(RoleID, LayerId, NewRagePracticeRec)
	end.

%% 验证是否都到满级
check_all_slots(LayerId, Category, RagePracticeRec) ->
	Fun = fun(SlotId, {SlotsAcc, AllFullAcc}) ->
		RageSlotRec = get_rage_slot_rec(RagePracticeRec, SlotId),
		case get_layer_id(RageSlotRec#rage_slot.slot_id) == LayerId of
			true ->
				CurLv                      = RageSlotRec#rage_slot.level,
				{CostPrestige, CostSilver} = cfg_rage_practice:level_up_cost(SlotId, CurLv),
				case RageSlotRec#rage_slot.status of
					?STATUS_NOT_ACTIVATE ->
						SlotConfRec = cfg_rage_practice:slot_conf(SlotId, 1, Category);
					_ ->
						SlotConfRec = cfg_rage_practice:slot_conf(SlotId, CurLv, Category)
				end,
				MaxSlotLv                  = cfg_rage_practice:max_slot_level(LayerId),
				R = #p_rage_slot{
					slot_id       = SlotId,
					status        = RageSlotRec#rage_slot.status,
					level         = CurLv,
					is_full_level = (CurLv >= 0) andalso (CurLv >= MaxSlotLv),
					need_prestige = CostPrestige,
					need_silver   = CostSilver,
					attr_type     = SlotConfRec#rage_prac_conf.attr_type,
					attr_value    = SlotConfRec#rage_prac_conf.attr_value,
					next_value    = case CurLv >= MaxSlotLv of
						true ->
							SlotConfRec#rage_prac_conf.attr_value;
						_ ->
							(cfg_rage_practice:slot_conf(SlotId, CurLv+1, Category))#rage_prac_conf.attr_value
					end
				},
				{[R | SlotsAcc], AllFullAcc andalso R#p_rage_slot.is_full_level};
			false ->
				{SlotsAcc, AllFullAcc}
		end
	end,
	lists:foldl(Fun, {[], true}, cfg_rage_practice:layer_slots(LayerId)).
	

%%一键升级
do_level_up_slot_loop(RoleID,SlotId) ->
	RagePracticeRec            = get_rage_practice_rec(RoleID),
	RageSlotRec                = get_rage_slot_rec(RagePracticeRec, SlotId),
	CurLv                      = RageSlotRec#rage_slot.level,
	{CostGold} 				   = cfg_rage_practice:level_up_cost_loop(SlotId, CurLv),
	IsMoneyEnough              = common_bag2:check_money_enough(gold_unbind, CostGold, RoleID),
	LayerId                    = get_layer_id(SlotId),
	MaxSlotLv                  = cfg_rage_practice:max_slot_level(LayerId),
	{ok, #p_role_attr{category = Category}} = mod_map_role:get_role_attr(RoleID),
	Ret = if
		RageSlotRec#rage_slot.status == ?STATUS_NOT_ACTIVATE ->
			{error, <<"槽位未激活">>};
		IsMoneyEnough == false -> 
			{error, ?_LANG_NOT_ENOUGH_GOLD};
		RageSlotRec#rage_slot.level >= MaxSlotLv ->
			{error, <<"槽位等级已满">>};
		true -> true
	end,
	case Ret of
		{error, Reason} -> common_misc:send_common_error(RoleID, 0, Reason);
		true ->
			true=common_bag2:use_money(RoleID, gold_unbind, CostGold, ?CONSUME_TYPE_GOLD_UPGRAGE_RAGE_SLOT),
			NewRageSlotRec     = RageSlotRec#rage_slot{level = MaxSlotLv},
			NewRagePracticeRec = set_rage_practice_rec(RoleID, RagePracticeRec, NewRageSlotRec),
			hook_rage_slot_level_up(RoleID, SlotId, CurLv, NewRageSlotRec#rage_slot.level, NewRagePracticeRec),
			common_misc:common_broadcast_other(RoleID,[LayerId],?MODULE),
			{_Slots, IsAllFull} = check_all_slots(LayerId, Category, NewRagePracticeRec),
			case  CurLv + 1 == MaxSlotLv andalso LayerId == 4 andalso IsAllFull of 
					true ->
							common_misc:common_broadcast_other(RoleID,{4, LayerId},?MODULE);
					_ 	 ->
							noop
			end,
			Msg = #m_rage_practice_op_toc{option = 3, slot_id = SlotId},
			?MOD_UNICAST(RoleID, ?RAGE_PRACTICE_OP, Msg),
			send_rage_slots_to_client(RoleID, LayerId, NewRagePracticeRec)
	end. 

hook_rage_slot_level_up(RoleID, SlotId, OldLv, NewLv, RagePracticeRec) ->
	LayerId        = get_layer_id(SlotId),
	MaxSlotLv      = cfg_rage_practice:max_slot_level(LayerId),
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	{ok, #p_role_attr{category = Category}} = mod_map_role:get_role_attr(RoleID),
	OldSlotConfRec = cfg_rage_practice:slot_conf(SlotId, OldLv, Category),
	NewSlotConfRec = cfg_rage_practice:slot_conf(SlotId, NewLv, Category),
	case OldLv > 0 of
		true ->
			NewAddAttr = [{NewSlotConfRec#rage_prac_conf.attr_type, NewSlotConfRec#rage_prac_conf.attr_value - OldSlotConfRec#rage_prac_conf.attr_value}];
		false ->
			NewAddAttr = [{NewSlotConfRec#rage_prac_conf.attr_type, NewSlotConfRec#rage_prac_conf.attr_value}]
	end,
	NewRoleBase    = mod_role_attr:calc(RoleBase, '+', mod_role_attr:transform(NewAddAttr)),

	case NewLv < MaxSlotLv of
		true ->
			NewRoleBase2 = NewRoleBase;
		false ->
			Fun = fun(SlotId2, AllFullAcc) ->
				RageSlotRec = get_rage_slot_rec(RagePracticeRec, SlotId2),
				(RageSlotRec#rage_slot.level >= MaxSlotLv) andalso AllFullAcc
			end,
			case lists:foldl(Fun, true, cfg_rage_practice:layer_slots(LayerId)) of
				false ->
					NewRoleBase2 = NewRoleBase;
				true ->
					AddAttrList2 = get_extral_add([{LayerId, true}]),
					NewRoleBase2 = mod_role_attr:calc(NewRoleBase, '+', mod_role_attr:transform(AddAttrList2))
			end
	end,
	mod_role_attr:reload_role_base(NewRoleBase2).

send_rage_slots_to_client(RoleID, LayerId) ->
	RagePracticeRec = get_rage_practice_rec(RoleID),
	send_rage_slots_to_client(RoleID, LayerId, RagePracticeRec).
send_rage_slots_to_client(RoleID, LayerId, RagePracticeRec) ->
	{ok, #p_role_attr{category = Category}} = mod_map_role:get_role_attr(RoleID),
	{Slots, IsAllFull} = check_all_slots(LayerId, Category, RagePracticeRec),
	case IsAllFull of
		true  -> {AddMiss, AddDoubleAtt, AddHitRate, AddTough} = cfg_rage_practice:extral_add(LayerId);
		false -> AddMiss = 0, AddDoubleAtt = 0, AddHitRate = 0, AddTough = 0
	end,
	Msg = #m_rage_practice_info_toc{
		layer_id          = LayerId,
		slots             = Slots,
		is_all_full_level = IsAllFull,
		extral_add1       = AddMiss,
		extral_add2       = AddDoubleAtt,
		extral_add3       = AddHitRate,
		extral_add4       = AddTough
	},
	?MOD_UNICAST(RoleID, ?RAGE_PRACTICE_INFO, Msg).


recalc(RoleBase = #p_role_base{role_id = RoleID}, #p_role_attr{category = Category}) ->
	RagePracticeRec = get_rage_practice_rec(RoleID),
	Fun = fun(RageSlotRec, {AttrAcc, FullLvAcc}) ->
		SlotId      = RageSlotRec#rage_slot.slot_id,
		CurLv       = RageSlotRec#rage_slot.level,
		SlotConfRec = cfg_rage_practice:slot_conf(SlotId, CurLv, Category),
		AddAttr     = [{SlotConfRec#rage_prac_conf.attr_type, SlotConfRec#rage_prac_conf.attr_value}],
		AttrAcc1    = AddAttr ++ AttrAcc,
		LayerId     = get_layer_id(SlotId),
		MaxSlotLv   = cfg_rage_practice:max_slot_level(LayerId),
		case lists:keyfind(LayerId, 1, FullLvAcc) of
			false -> 
				FullLvAcc1 = lists:keystore(LayerId, 1, FullLvAcc, {LayerId, (CurLv>=MaxSlotLv)});
			{LayerId, IsAllFull} ->
				FullLvAcc1 = lists:keystore(LayerId, 1, FullLvAcc, {LayerId, IsAllFull andalso (CurLv>=MaxSlotLv)})
		end,
		{AttrAcc1, FullLvAcc1}
	end,
	{AddAttrList1, FullLvList} = lists:foldl(Fun, {[], []}, RagePracticeRec#r_rage_practice.list), 
	RoleBase2    = mod_role_attr:calc(RoleBase, '+', mod_role_attr:transform(AddAttrList1)),
	AddAttrList2 = get_extral_add(FullLvList),
	RoleBase3    = mod_role_attr:calc(RoleBase2, '+', mod_role_attr:transform(AddAttrList2)),
	RoleBase3.

get_extral_add(FullLvList) ->
	get_extral_add(FullLvList, []).

get_extral_add([], Acc) -> Acc;
get_extral_add([{LayerId, IsAllFull} | Rest], Acc) ->	
	Acc1 = case IsAllFull of
		true ->
			{AddMiss, AddDoubleAtt, AddHitRate, AddTough} = cfg_rage_practice:extral_add(LayerId),
			AttrList = [{#p_property_add.dodge, AddMiss}, {#p_property_add.dead_attack, AddDoubleAtt},
						{#p_property_add.hit_rate, AddHitRate}, {#p_property_add.tough, AddTough}],
			% [AttrList | Acc];
			Acc ++ AttrList;
		false -> Acc
	end,
	get_extral_add(Rest, Acc1).
%% ==========================================================================
get_layer_id(SlotId) -> SlotId div 100.


%% ===================================================================
%% ========================激活处理===================================
start_event(RoleID) ->
	RagePracticeRec = get_rage_practice_rec(RoleID),
	start_event(RoleID, RagePracticeRec).
start_event(RoleID, RagePracticeRec) ->
	case RagePracticeRec#r_rage_practice.cur_inactivated_slot_id of
		0 -> ignore;
		CurInactivatedSlotId ->
			Events = cfg_rage_practice:events(CurInactivatedSlotId),
			add_event_handler(RoleID, Events, CurInactivatedSlotId),
			trigger_event(RoleID, Events, CurInactivatedSlotId)
	end.


add_event_handler(RoleID, Events, CurInactivatedSlotId) ->
	lists:foreach(fun
		({EventTag, Args}) ->
			mod_role_event:add_handler(RoleID, EventTag, {?MODULE, {Args, CurInactivatedSlotId}})
	end, Events).

delete_event_handler(RoleID, EventTag) ->
	mod_role_event:delete_handler(RoleID, EventTag, ?MODULE).

gm_activate_slot(RoleID) ->
	RagePracticeRec  = get_rage_practice_rec(RoleID),
	RagePracticeRec1 = activate_slot(RoleID, RagePracticeRec),
	start_event(RoleID, RagePracticeRec1).

%%激活槽位
activate_slot(RoleID, RagePracticeRec) ->
	CurInactivatedSlotId = RagePracticeRec#r_rage_practice.cur_inactivated_slot_id,
	RageSlotRec = #rage_slot{
		slot_id = CurInactivatedSlotId,
		status  = ?STATUS_ACTIVATED,
		level   = cfg_rage_practice:default_level()
	},
	RagePracticeRec1 = RagePracticeRec#r_rage_practice{
		list = [RageSlotRec | RagePracticeRec#r_rage_practice.list],
		cur_inactivated_slot_id = cfg_rage_practice:next_slot(CurInactivatedSlotId)
	},
	set_rage_practice_rec(RoleID, RagePracticeRec1),
	send_rage_slots_to_client(RoleID, get_layer_id(CurInactivatedSlotId)),
	hook_rage_slot_level_up(RoleID, CurInactivatedSlotId, 0, 1, RagePracticeRec1),
	RagePracticeRec1.

trigger_event(RoleID, Events, CurInactivatedSlotId) ->
	lists:foreach(fun
		({?ROLE_EVENT_VIP_LV, Args}) ->
			VipLevel = mod_vip:get_role_vip_level(RoleID),
			handle_event(RoleID, {?ROLE_EVENT_VIP_LV, VipLevel}, {Args, CurInactivatedSlotId});
		({PetEvent, Args}) when PetEvent == ?ROLE_EVENT_PET_GET;
								PetEvent == ?ROLE_EVENT_PET_LV;
								PetEvent == ?ROLE_EVENT_PET_ZZ;
								PetEvent == ?ROLE_EVENT_PET_WX ->
			PetBag = mod_map_pet:get_role_pet_bag_info(RoleID),
			lists:foreach(fun
				(#p_pet_id_name{pet_id = PetID}) ->
					PetInfo = mod_map_pet:get_pet_info(RoleID, PetID),
					handle_event(RoleID, {PetEvent, PetInfo}, {Args, CurInactivatedSlotId})
			end, PetBag#p_role_pet_bag.pets);
		({?ROLE_EVENT_PET_CZ, Args}) ->
			PetBag = mod_map_pet:get_role_pet_bag_info(RoleID),
			handle_event(RoleID, {?ROLE_EVENT_PET_CZ, PetBag}, {Args, CurInactivatedSlotId});
		({?ROLE_EVENT_PET_GROW, Args}) ->
			{GrowInfo, _} = mod_pet_grow:get_role_pet_grow_info(RoleID),
			handle_event(RoleID, {?ROLE_EVENT_PET_GROW, GrowInfo}, {Args, CurInactivatedSlotId});
		({?ROLE_EVENT_SKILL_LV, Args}) ->
			SkillList = lists:foldr(fun
		    	(#r_role_skill_info{skill_id = SkillID, cur_level = CurLevel}, Acc) ->
					[ #p_role_skill{skill_id = SkillID, cur_level = CurLevel}|Acc]
			end, [], mod_role_skill:get_role_skill_list(RoleID)),
			handle_event(RoleID, {?ROLE_EVENT_SKILL_LV, SkillList}, {Args, CurInactivatedSlotId});
		({?ROLE_EVENT_FASHION_GET, Args}) ->
			#r_role_fashion{
				fashion = Fashion,
				wings   = Wings,
				mounts  = Mounts
			} = mod_role_fashion:fetch(RoleID),
			handle_event(RoleID, {?ROLE_EVENT_FASHION_GET, Fashion}, {Args, CurInactivatedSlotId}),
			handle_event(RoleID, {?ROLE_EVENT_FASHION_GET, Wings}, {Args, CurInactivatedSlotId}),
			handle_event(RoleID, {?ROLE_EVENT_FASHION_GET, Mounts}, {Args, CurInactivatedSlotId});
		({?ROLE_EVENT_EQUIP_PUT, {Num, Args}}) ->
			handle_event(RoleID, {?ROLE_EVENT_EQUIP_PUT, RoleID}, {{Num, Args}, CurInactivatedSlotId});
		({?ROLE_EVENT_GEMS_PUT, {Num, Args}}) ->
			GemHoles = mod_equip_gems:get_role_gems_info(RoleID),
			handle_event(RoleID, {?ROLE_EVENT_GEMS_PUT, GemHoles}, {{Num, Args}, CurInactivatedSlotId});
		({?ROLE_EVENT_PET_JUEJI, Args}) ->
			MaxPetJuejiLevel = mod_pet_skill:get_max_role_pet_jueji(RoleID),
			handle_event(RoleID, {?ROLE_EVENT_PET_JUEJI, MaxPetJuejiLevel}, {Args, CurInactivatedSlotId});
		({?ROLE_EVENT_HUO_LING, Args}) ->
			HouLing = mod_nuqi_huoling:get_huoling_level(RoleID),
			handle_event(RoleID, {?ROLE_EVENT_HUO_LING, HouLing}, {Args, CurInactivatedSlotId});
		({?ROLE_EVENT_PET_EQUIP, Args}) ->
			Fun = fun(#p_pet_id_name{pet_id = PetId}, IsTrigged) ->
				case IsTrigged of
					true -> true;
					false ->
						PetInfo = mod_map_pet:get_pet_info(RoleID, PetId),
						handle_event(RoleID, {?ROLE_EVENT_PET_EQUIP, PetInfo}, {Args, CurInactivatedSlotId})
				end
			end,
			case mod_map_pet:get_role_pet_bag_info(RoleID) of
				undefined  -> ignore;
				PetBagInfo ->
					lists:foldl(Fun, false, PetBagInfo#p_role_pet_bag.pets)
			end;
		({?ROLE_EVENT_EQUIP_PUT, Args}) ->
			{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
			lists:foreach(fun
				(Equip) ->
					handle_event(RoleID, {?ROLE_EVENT_EQUIP_PUT, Equip}, {Args, CurInactivatedSlotId})
			end, RoleAttr#p_role_attr.equips);
		({?ROLE_EVENT_FU_WEN, Args}) ->
			Fun = fun(RuneInfo, IsTrigged) ->
				case IsTrigged of
					true -> true;
					false ->
						Data = {RuneInfo#p_rune.level, mod_rune_altar:get_rune_colour(RuneInfo#p_rune.typeid)},
						handle_event(RoleID, {?ROLE_EVENT_FU_WEN, Data}, {Args, CurInactivatedSlotId})
				end
			end,
			lists:foldl(Fun, false, mod_rune_altar:get_loaded(RoleID));
		(_) -> ignore
	end, Events).

%%判断形态激活条件
check_layer_require(RoleID, LayerId) ->
	NuqiSkillRec 	= mod_role_skill:get_role_nuqi_skill_info(RoleID),
	SKillId      	= NuqiSkillRec #r_role_skill_info.skill_id,
	ShapeNum 	 	= mod_role_skill:get_nuqi_skill_shape_num(SKillId),
	if ShapeNum >= LayerId ->
			true;
		true ->
			false
	end.


handle_event(RoleID, {EventTag, EventArgs}, {Args, CurInactivatedSlotId}) ->
	RagePracticeRec = get_rage_practice_rec(RoleID),
	case CurInactivatedSlotId == RagePracticeRec#r_rage_practice.cur_inactivated_slot_id of
		true ->
			case do_handle_event({EventTag, EventArgs}, Args) of
				true ->
					LayerId = get_layer_id(CurInactivatedSlotId),
					case check_layer_require(RoleID, LayerId) of
						true ->
							delete_event_handler(RoleID, EventTag),
							RagePracticeRec1 = activate_slot(RoleID, RagePracticeRec),
							start_event(RoleID, RagePracticeRec1),
							true;
						_ 	 ->
							false
					end;
				_ ->
					false
			end;
		false -> 
			% delete_event_handler(RoleID, EventTag),
			false
	end.

do_handle_event({?ROLE_EVENT_EQUIP_PUT, Equip}, {Num, Args}) when is_integer(Num) ->
	case is_integer(Equip) orelse check_equip(Equip, Args) of
		true ->
			RoleID = if
				is_integer(Equip) ->
					Equip;
				true ->
					Equip#p_goods.roleid
			end,
			{ok, RoleAttr}  = mod_map_role:get_role_attr(RoleID),
			SatisfyEquipNum = lists:foldl(fun
				(Equip1, Sum) ->
					case check_equip(Equip1, Args) of
						true -> Sum + 1;
						_    -> Sum
					end
			end, 0, RoleAttr#p_role_attr.equips),
			(SatisfyEquipNum >= Num);
		_ ->
			false
	end;

do_handle_event({?ROLE_EVENT_EQUIP_PUT, Equip}, Args) ->
	check_equip(Equip, Args);

do_handle_event({?ROLE_EVENT_FASHION_GET, Fashion}, Args) ->
	check_fashion(Fashion, Args);

do_handle_event({?ROLE_EVENT_VIP_LV, VipLevel}, Args) ->
	check_vip_level(VipLevel, Args);


%%宠物获得
do_handle_event({?ROLE_EVENT_PET_GET, Pet}, Args) ->
	check_pet(Pet, Args);

%%宠物升级
do_handle_event({?ROLE_EVENT_PET_LV, Pet}, Args) ->
	check_pet(Pet, Args);

%%宠物资质
do_handle_event({?ROLE_EVENT_PET_ZZ, Pet}, Args) ->
	check_pet(Pet, Args);

%%宠物悟性
do_handle_event({?ROLE_EVENT_PET_WX, Pet}, Args) ->
	check_pet(Pet, Args);


do_handle_event({?ROLE_EVENT_PET_CZ, PetBag}, Args) ->
	check_pet_bag(PetBag, Args);

do_handle_event({?ROLE_EVENT_PET_GROW, GrowInfo}, Args) ->
	check_pet_grow(GrowInfo, Args);

do_handle_event({?ROLE_EVENT_PET_EQUIP, [Pet, Equip]}, {Num, Args}) when is_integer(Num) ->
	case check_equip(Equip, Args) of
		true ->
			SatisfyEquipNum = lists:foldl(fun
				(Equip1, Sum) when is_record(Equip1, p_goods) ->
					case check_equip(Equip1, Args) of
						true -> Sum + 1;
						_    -> Sum
					end;
				(_, Sum) -> Sum
			end, 0, tuple_to_list(Pet#p_pet.equips)),
			(SatisfyEquipNum >= Num);
		_ ->
			ignore
	end;

do_handle_event({?ROLE_EVENT_PET_EQUIP, [_Pet, Equip]}, Args) ->
	check_equip(Equip, Args);
do_handle_event({?ROLE_EVENT_PET_EQUIP, Pet}, {Num, Args}) ->
	SatisfyEquipNum = lists:foldl(fun
		(Equip1, Sum) when is_record(Equip1, p_goods) ->
			case check_equip(Equip1, Args) of
				true -> Sum + 1;
				_    -> Sum
			end;
		(_, Sum) -> Sum
	end, 0, tuple_to_list(Pet#p_pet.equips)),
	(SatisfyEquipNum >= Num);

do_handle_event({?ROLE_EVENT_EQUIP, Equip}, Args) ->
	check_equip(Equip, Args);

do_handle_event({?ROLE_EVENT_GEMS_PUT, GemHoles}, {Num, Args}) when is_integer(Num) ->
	check_gem_holes(GemHoles, Args) >= Num;

do_handle_event({?ROLE_EVENT_SKILL_LV, Skills}, Args) ->
	check_skills(Skills, Args);

do_handle_event({?ROLE_EVENT_PET_JUEJI, PetJuejiLevel}, Args) ->
	check_pet_jueji(PetJuejiLevel, Args);

do_handle_event({?ROLE_EVENT_FU_WEN, Fuwen}, Args) ->
	check_fu_wen(Fuwen, Args);

do_handle_event({?ROLE_EVENT_HUO_LING, HouLing}, Args) ->
	check_huo_ling(HouLing, Args);

do_handle_event(_Event, _Args) -> ignore.


check_equip(Equip, Args) ->
	lists:all(fun
		({position, Pos}) ->
			Equip#p_goods.loadposition == Pos;
		({color, Color}) ->
			Equip#p_goods.current_colour >= Color;
		({level, Level}) ->
			Equip#p_goods.level >= Level;
		({qianghua, Level}) ->
			Equip#p_goods.reinforce_result >= Level;
		({upgrade, Upgrade}) ->
			[#p_equip_base_info{upgrade_num=UpgradeNum}] = common_config_dyn:find_equip(Equip#p_goods.typeid),
			UpgradeNum >= Upgrade;
		(_) ->
			false
	end, Args).

check_fashion(Fashion, Args) ->
	lists:all(fun
		({type, Type}) ->
			Fashion#r_fashion.type == Type;
		({rank, Rank}) ->
			Fashion#r_fashion.rank >= Rank;
		(_) ->
			false
	end, Args).

check_vip_level(VipLevel, [{level, Level}]) ->
	VipLevel >= Level.


check_pet(Pet, Args) ->
	lists:all(fun
		({type, Type}) ->
			Pet#p_pet.type_id == Type;
		({color, Color}) ->
			Pet#p_pet.color == Color;
		({level, Level}) ->
			Pet#p_pet.level >= Level;
		({zz_amount, ZzAmount}) ->
			mod_pet_aptitude:get_pet_total_aptitude(Pet) >= ZzAmount;
		({wx, Wx}) ->
			Pet#p_pet.understanding >= Wx;
		(_) -> false
	end, Args).

check_gem_holes(GemHoles, Args) ->
	case lists:keytake(index, 1, Args) of
		{value, {index, Index}, Args2} ->
			check_gem_holes2(element(Index, GemHoles), Args2);
		_ ->
			[_|AllGemHoles] = tuple_to_list(GemHoles),
			check_gem_holes2(lists:flatten(AllGemHoles), Args)
	end.

check_gem_holes2(GemHoles, Args) ->
	lists:foldl(fun
		(GemHole, Sum) ->
			case check_gem(GemHole, Args) of
				true  -> Sum + 1;
				false -> Sum
			end
	end, 0, GemHoles).

check_gem(#p_gem_hole{gem_typeid=GemTypeID}, [{level, Level}]) ->
	mod_equip_gems:get_gem_level(GemTypeID) >= Level.

check_skills(Skills, [{level, SkillLevel}]) ->
	lists:any(fun
		(#p_role_skill{cur_level = CurLevel}) ->
			CurLevel >= SkillLevel
	end, Skills).

check_pet_bag(PetBag, [{amount, Amount}]) ->
	case PetBag of
		#p_role_pet_bag{summoned_pet_id = SummonPetID, hidden_pets = HiddenPets} ->
			if SummonPetID > 0 -> 1; true -> 0 end + length(HiddenPets) >= Amount;
		_ -> 
			false
	end.

check_pet_grow(GrowInfo, [{level, Level}]) ->
	GrowInfo#p_role_pet_grow.con_level           >= Level andalso
	GrowInfo#p_role_pet_grow.phy_attack_level    >= Level andalso
	GrowInfo#p_role_pet_grow.magic_attack_level  >= Level andalso
	GrowInfo#p_role_pet_grow.phy_defence_level   >= Level andalso
	GrowInfo#p_role_pet_grow.magic_defence_level >= Level.

check_pet_jueji(PetJuejiLevel, [{level, Level}]) ->
	PetJuejiLevel >= Level.	

check_fu_wen({FuwenLevel, FuwenColor}, Args) ->
	lists:all(fun
		({level, Level}) ->
			FuwenLevel >= Level;
		({color, Color}) ->
			FuwenColor >= Color;
		(_) ->
			false
	end, Args).		

check_huo_ling(HouLingLevel, [{level, Level}]) ->
	HouLingLevel >= Level.