-module(mod_equip_endurance).

-define(_common_error,		?DEFAULT_UNIQUE,	?COMMON,	?COMMON_ERROR,				#m_common_error_toc).%}
-define(_equip_fix,			?DEFAULT_UNIQUE,	?EQUIP,		?EQUIP_FIX,					#m_equip_fix_toc).%}
-define(_endurance_change,	?DEFAULT_UNIQUE,	?EQUIP,		?EQUIP_ENDURANCE_CHANGE,	#m_equip_endurance_change_toc).%}

-include("mgeer.hrl").

-export ([handle/1, decrease/2]).

handle({_Unique, ?EQUIP, ?EQUIP_FIX, _DataRecord, RoleID, PID, _Line}) ->
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    FixCost = lists:foldl(fun
    	(Equip, CostSum) ->
    		case Equip#p_goods.current_endurance >= Equip#p_goods.endurance of
    			true ->
    				CostSum;
    			false ->
    				fix_cost(Equip) + CostSum
    		end 
    end, 0, RoleAttr#p_role_attr.equips),
    NewSilver = RoleAttr#p_role_attr.silver_bind - FixCost,
    case NewSilver >= 0 of
		true ->
			Fun =
				fun() ->
						{ok, NewEquips, FixedEquips} = do_fix(RoleAttr),
						NewRoleAttr = RoleAttr#p_role_attr{equips = NewEquips, silver_bind = NewSilver},
						mod_map_role:set_role_attr(RoleID, NewRoleAttr),
						common_consume_logger:use_silver({RoleID, FixCost, 0, ?CONSUME_TYPE_SILVER_FIX_EQUIP, ""}),
						{ok,NewRoleAttr, FixedEquips}
				end,
			case common_transaction:t(Fun) of
				{abort,Reason} ->
					common_misc:unicast2(PID, ?_equip_fix{succ=false,reason=Reason});
				{atomic,{ok,NewRoleAttr, FixedEquips}} -> 
					L = [#p_equip_endurance_info{
							equip_id = E#p_goods.id, 
							num      = E#p_goods.current_endurance, 
							max_num  = E#p_goods.endurance} || E <- FixedEquips],
					common_misc:unicast2(PID, ?_equip_fix{equip_list = L, bind_silver = NewSilver}),
					common_misc:send_role_silver_change(RoleID,NewRoleAttr)
			end;

    	false ->
    		common_misc:unicast2(PID, ?_common_error{error_str = ?_LANG_NOT_ENOUGH_SILVER})
    end.

fix_cost(#p_goods{current_endurance = CurrEndurance, 
		endurance = MaxEndurance, level = Level, current_colour = Color}) ->
    IncreaseEndurance = MaxEndurance - CurrEndurance,
    common_tool:ceil(
    	(math:pow(Level/5, 2)+math:pow((Color-1), 4)*10) * 0.5*IncreaseEndurance/MaxEndurance ).

do_fix(RoleAttr) ->
	#p_role_attr{role_id = RoleID, equips = OldEquips} = RoleAttr,
	{OpList, NewEquips} = lists:foldl(fun
		(OldEquip, {OpListAcc, EquipAcc}) ->
			NewEquip = OldEquip#p_goods{current_endurance = OldEquip#p_goods.endurance},
			OpListAcc2 = if 
				OldEquip#p_goods.current_endurance =< 0,
				NewEquip#p_goods.current_endurance  > 0 ->
					[{'+', NewEquip}|OpListAcc];
				true ->
					OpListAcc
			end,
			{OpListAcc2, [NewEquip|EquipAcc]}
	end, {[], []}, OldEquips),
	NewEquips2  = update_role_base(RoleID, OpList, OldEquips, NewEquips),
	FixedEquips = lists:foldl(fun
		(Equip, Acc) when Equip#p_goods.current_endurance < Equip#p_goods.endurance ->
			[lists:keyfind(Equip#p_goods.id, #p_goods.id, NewEquips2)|Acc];
		(_Equip, Acc) ->
			Acc
	end, [], OldEquips),
	{ok, NewEquips2, FixedEquips}.	    

decrease(RoleID, Points) ->
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	OldEquips      = RoleAttr#p_role_attr.equips,
	{OpList, NewEquips} = lists:foldl(fun
		(OldEquip, {OpListAcc, EquipAcc}) ->
			NewEquip = decrease2(OldEquip, Points),
			OpListAcc2 = if 
				OldEquip#p_goods.current_endurance  > 0,
				NewEquip#p_goods.current_endurance =< 0 ->
					[{'-', OldEquip}|OpListAcc];
				true ->
					OpListAcc
			end,
			{OpListAcc2, [NewEquip|EquipAcc]}
	end, {[], []}, OldEquips),
	NewEquips2 = update_role_base(RoleID, OpList, OldEquips, NewEquips),
	mod_role_tab:put({?role_attr, RoleID}, RoleAttr#p_role_attr{equips = NewEquips2}),
	ChangeEquips = lists:foldl(fun
		(Equip, Acc) when Equip#p_goods.current_endurance > 0 ->
			[lists:keyfind(Equip#p_goods.id, #p_goods.id, NewEquips2)|Acc];
		(_Equip, Acc) ->
			Acc
	end, [], OldEquips),
	ChangeEquips == [] orelse 
	case ChangeEquips of
		[] -> ignore;
		_ ->
			L = [#p_equip_endurance_info{
							equip_id = E#p_goods.id, 
							num      = E#p_goods.current_endurance, 
							max_num  = E#p_goods.endurance} || E <- ChangeEquips],
			common_misc:unicast({role, RoleID}, ?_endurance_change{equip_list = L})
	end.

decrease2(Equip = #p_goods{current_endurance = Endurance}, {point, Points}) ->
	Equip#p_goods{current_endurance = max(0, Endurance - Points)};
decrease2(Equip = #p_goods{current_endurance = Endurance}, {rate, Rate}) ->
	Equip#p_goods{current_endurance = max(0, common_tool:ceil(Endurance - Endurance*Rate))}.

update_role_base(RoleID, OpList, OldEquips, NewEquips) ->
	if
		OpList =/= [] ->
			{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
			{ok, NewEquips2, ActivateSuit} = mod_equip_suit:update(OldEquips, NewEquips),
			NewRoleBase = ActivateSuit(mod_role_equip:calc(RoleBase, OpList)),
		    mod_role_attr:reload_role_base(NewRoleBase);
		true ->
			NewEquips2 = NewEquips
	end,
	NewEquips2.

