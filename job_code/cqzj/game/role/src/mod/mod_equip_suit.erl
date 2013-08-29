-module(mod_equip_suit).

-export ([update/2, deactivate/1]).

-include("mgeer.hrl").

update(OldEquips, NewEquips) ->
	{_OldSuitEquips, OldSuitBuffs} = activate_suit(group_equips(OldEquips)),
	{NewSuitEquips,  NewSuitBuffs} = activate_suit(group_equips(NewEquips)),
    update_equips(NewEquips, NewSuitEquips, OldSuitBuffs, NewSuitBuffs).

group_equips(Equips) ->
	lists:foldl(fun
    	(Equip = #p_goods{whole_attr = [EquipSuitAttr|_]}, SuitEquipsAcc1) 
    			when Equip#p_goods.current_endurance > 0,
    				 Equip#p_goods.state == ?GOODS_STATE_NORMAL -> 
    		#p_equip_whole_attr{id = SuitID} = EquipSuitAttr,
            case lists:keytake(SuitID, 1, SuitEquipsAcc1) of
				false ->
					[{SuitID,[Equip]}|SuitEquipsAcc1];
				{value, {SuitID, SuitEquips}, SuitEquipsAcc2} ->
					[{SuitID,[Equip|SuitEquips]}|SuitEquipsAcc2]
			end;
		(_Equip, SuitEquipsAcc1) ->
			SuitEquipsAcc1
    end, [], Equips).

update_equips(Equips, [], [], []) -> {ok, Equips, fun(RoleBase) -> RoleBase end};
update_equips(Equips, SuitEquips, OldSuitBuffs, NewSuitBuffs) ->
	SuitEquips2 = lists:flatten(SuitEquips),
	Equips2 = [case lists:keyfind(Equip#p_goods.id, #p_goods.id, SuitEquips2) of
		false     -> Equip;
		SuitEquip -> SuitEquip
	end||Equip <- Equips],
	ActivateSuit = fun
		(RoleBase) when is_record(RoleBase, p_role_base) ->
			notify({role, RoleBase#p_role_base.role_id}, Equips2),
			mod_role_buff:add_buff2(
				mod_role_buff:del_buff2(RoleBase, OldSuitBuffs), NewSuitBuffs)
	end,
	{ok, Equips2, ActivateSuit}.

activate_suit([]) -> {[], []};
activate_suit(SuitEquipsAcc) ->
    lists:mapfoldl(fun
    	({SuitID, SuitEquips}, BuffAcc1) ->
    		SuitCnt = length(SuitEquips),
    		SuitCfg = get_suit_config(SuitID),
    		lists:mapfoldl(fun
    			(Equip = #p_goods{whole_attr = SuitAttrs}, BuffAcc2) when is_list(SuitAttrs) ->
    				{EquipSuitAttr2, BuffAcc4} = lists:mapfoldl(fun
    					(EquipSuitAttr1, BuffAcc3) ->
    						activate_suit_attr(EquipSuitAttr1, SuitCnt, SuitCfg, BuffAcc3)
    				end, BuffAcc2, SuitAttrs),
    				{Equip#p_goods{whole_attr = EquipSuitAttr2}, BuffAcc4};
    			(Equip, BuffAcc2) ->
    				{Equip, BuffAcc2}
    		end, BuffAcc1, SuitEquips)
    end, [], SuitEquipsAcc).

get_suit_config(SuitID) ->
    case common_config_dyn:find(equip_whole_attr, {equip_whole_base_info, SuitID}) of
    	[SuitCfg] -> SuitCfg;
    	_Others   -> undefined
    end.

activate_suit_attr(EquipSuitAttr, SuitCnt, 
		#r_equip_whole_info{add_attr_list = AddAttrList}, BuffAcc) ->
	#p_equip_whole_attr{
		attr_index = AttrIndex, active_number = ActiveNum} = EquipSuitAttr,
	if
		SuitCnt >= ActiveNum ->
			EquipSuitAttr2 = EquipSuitAttr#p_equip_whole_attr{
				active = ?EQUIP_WHOLE_ATTR_STATUS_ACTIVE,
				number = SuitCnt
			},
			BuffAcc2 = case lists:keyfind(AttrIndex, 
					#r_equip_whole_attr.attr_index, AddAttrList) of
				#r_equip_whole_attr{buff_id = BuffID} ->
					[BuffID | lists:delete(BuffID, BuffAcc)];
				_ ->
					BuffAcc
			end,
			{EquipSuitAttr2, BuffAcc2};
		true ->
			EquipSuitAttr2 = EquipSuitAttr#p_equip_whole_attr{
				active = ?EQUIP_WHOLE_ATTR_STATUS_NOT_ACTIVE,
				number = SuitCnt
			},
			{EquipSuitAttr2, BuffAcc}
	end;
activate_suit_attr(EquipSuitAttr, _, _, BuffAcc) ->
	{EquipSuitAttr, BuffAcc}.

notify({role, RoleID}, Equips) when is_list(Equips) ->
	ChangeList = lists:foldl(fun
  		(#p_goods{id = EquipID, whole_attr = SuitAttrs}, 
  			SuitAttrsAcc1) when is_list(SuitAttrs), SuitAttrs =/= [] -> 
	    	SuitAttrsAcc3 = lists:foldl(fun
				(SuitAttr, SuitAttrsAcc2) ->
					#p_equip_whole_attr{
						attr_code = Code,
						active    = Active,
						number    = Number 
					} = SuitAttr,
					[Code, Active, Number|SuitAttrsAcc2]
			end, [], SuitAttrs),
			SuitAttrsAcc1 ++ [EquipID, length(SuitAttrs)*3|SuitAttrsAcc3];
		(_Equip, SuitAttrsAcc1) ->
			SuitAttrsAcc1
	end, [], Equips),
	common_misc:role_attr_change_notify({role, RoleID}, RoleID, [
      	#p_role_attr_change{
			change_type        = ?ROLE_EQUIP_WHOLE_ATTR_CHANGE,
			new_int_value_list = ChangeList
		}]);
notify(_, _) -> ignore.

deactivate(Equip = #p_goods{whole_attr = SuitAttrs}) when is_list(SuitAttrs), SuitAttrs =/= [] ->
    SuitAttrs2 = [EquipSuitAttr#p_equip_whole_attr{
    	active = ?EQUIP_WHOLE_ATTR_STATUS_NOT_ACTIVE,
        number = 0
    }||EquipSuitAttr <- SuitAttrs],
    Equip#p_goods{whole_attr = SuitAttrs2};
deactivate(Equip) ->
    Equip.