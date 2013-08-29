%%% @author fsk 
%%% @doc
%%%     玩家/异兽合体
%%%     说明：镜像不自动添加扣取灵气buff
%%% @end
%%% Created : 2012-8-13
%%%-------------------------------------------------------------------
-module(mod_role_pet_mix).

-include("mgeem.hrl").

-export([
			handle/1,
			handle/2,
			pet_hidden/1,
			calc_role_pet_mix_second_level_attr/2,
			is_pet_hidden/2
		]).


-define(ERR_PET_MIX_NOT_ENOUGH_MP,6346001).%%灵气值不足
-define(ERR_PET_MIX_NOT_SUMMONED_PET,6346002).%%没有出战的异兽
-define(ERR_PET_MIX_ERROR_IN_MIRROR_FB,6346003).%%镜像中不能进行合体离体操作
-define(ERR_PET_EXIST_BUFFCANT_MIX, 6346004).%%在某种buff的时候不能合体/立体

-define(ERR_PET_HIDDEN_ERROR_PET_HAS_HIDDEN,6347001).%%异兽已经附身
-define(ERR_PET_HIDDEN_ERROR_PET_NO_HIDDEN,6347002).%%异兽没有附身
-define(ERR_PET_HIDDEN_ERROR_PET_HAS_SUMMONED,6347003).%%异兽跟随中
-define(ERR_PET_HIDDEN_ERROR_PET_NOT_FOUND,6347004).%%没有该异兽
-define(ERR_PET_HIDDEN_ERROR_PET_HIDDEN_NUM_LIMIT,6347005).%%玩家等级附身异兽个数已满或境界不足
-define(ERR_PET_HIDDEN_ERROR_PET_HIDDEN_CATEGORY_TYPE_LIMIT,6347006).%%只能附身不同职业类型的异兽
-define(ERR_PET_HIDDEN_ERROR_PET_HIDDEN_NOT_SUMMONED_PET,6347007).%%没有跟随的异兽，不能附身

-define(CAST_PET_MIX_ERROR(RoleID,R),common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?PET,?PET_MIX,R)).
-define(CAST_PET_HIDDEN_ERROR(RoleID,R),common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?PET,?PET_HIDDEN,R)).

-define(_common_error,	?DEFAULT_UNIQUE,	?COMMON,	?COMMON_ERROR,	#m_common_error_toc).%}

handle(Msg,_State) ->
	handle(Msg).
handle(Msg) ->
	?ERROR_MSG("~ts:~w",["未知消息", Msg]).

pet_hidden({Unique, Module, Method, PetID, HiddenState, RoleID, PID, Line, MapState}) ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	case catch check_pet_hidden(RoleID,RoleBase,PetID,HiddenState) of
		{error,ErrCode,_ErrReason} when ErrCode > 0 ->
			?UNICAST_TOC(#m_pet_hidden_toc{err_code=ErrCode});
		{error,ErrCode,ErrReason} when ErrCode == 0 ->
			common_misc:unicast2(PID, ?_common_error{error_code = ErrCode, error_str = ErrReason});
		{ok,HiddenPets,PetBagInfo,_PetInfo, IsSummoned} ->
			case IsSummoned of
				true -> 
					case mod_map_pet:do_call_back(Unique, 
						#m_pet_call_back_tos{pet_id=PetID,is_hidden=true}, RoleID, Line, MapState) of
						true ->
							?CAST_PET_HIDDEN_ERROR(RoleID,#m_pet_hidden_toc{pet_id=PetID,state=HiddenState});
						false ->
							?CAST_PET_HIDDEN_ERROR(RoleID,#m_pet_hidden_toc{err_code=?ERR_SYS_ERR})
					end;
					% mod_map_pet:do_call_back(Unique, 
					% 	#m_pet_call_back_tos{pet_id=PetID,is_hidden=false}, RoleID, Line, MapState),
					% NewPetBagInfo = mod_map_pet:get_role_pet_bag_info(RoleID),
					% do_pet_hidden(RoleID,PetID,HiddenState,HiddenPets,NewPetBagInfo);
				false ->
					do_pet_hidden(RoleID,RoleBase,PetID,HiddenState,HiddenPets,PetBagInfo)
			end
	end.

do_pet_hidden(RoleID,RoleBase,PetID,HiddenState,HiddenPets,PetBagInfo) ->
	PetInfo  = mod_map_pet:get_pet_info(RoleID, PetID),
	TransFun = fun()-> 
					   t_pet_hidden(RoleID,PetID,HiddenState,HiddenPets,PetBagInfo)
			   end,
	case common_transaction:t( TransFun ) of
		{atomic, {ok, NewPetBagInfo}} ->
			NewRoleBase    = case HiddenState of
				?NO_HIDDEN_STATE ->
					mod_role_pet:calc(RoleBase, PetBagInfo, [{'-', PetInfo}]);
				_ ->
					mod_role_pet:calc(RoleBase, NewPetBagInfo, [{'+', PetInfo}])
			end,
			NewRoleBase2 = mod_map_pet:remove_pet_buff_add_to_owner(NewRoleBase, PetInfo),
			mod_role_attr:reload_role_base(NewRoleBase2),
			%% 完成成就
			mod_achievement2:achievement_update_event(RoleID, 22002, length(NewPetBagInfo#p_role_pet_bag.hidden_pets)),
            #p_role_pet_bag{summoned_pet_id = SummonedPetID, hidden_pets = HiddenPets2} = NewPetBagInfo,
            ActivePets = case SummonedPetID of
                       undefined -> erlang:length(HiddenPets2);
                       _         -> erlang:length(HiddenPets2) + 1
                   end,
            mod_qrhl:send_event(RoleID, pet, ActivePets),
            mod_role_event:notify(RoleID, {?ROLE_EVENT_PET_CZ, NewPetBagInfo}),
			Msg = #m_pet_bag_info_toc{info=NewPetBagInfo},
			common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_BAG_INFO, Msg),
			?CAST_PET_HIDDEN_ERROR(RoleID,#m_pet_hidden_toc{pet_id=PetID,state=HiddenState});
		{aborted, {error,ErrCode,undefined}} ->
			?CAST_PET_HIDDEN_ERROR(RoleID,#m_pet_hidden_toc{err_code=ErrCode});
		{aborted, Reason} ->
			?ERROR_MSG("pet_hidden error,Reason:~w",[Reason]),
			?CAST_PET_HIDDEN_ERROR(RoleID,#m_pet_hidden_toc{err_code=?ERR_SYS_ERR})
	end.

check_pet_hidden(RoleID,RoleBase,PetID,HiddenState) ->
	PetBagInfo = mod_map_pet:get_role_pet_bag_info(RoleID),
	#p_role_pet_bag{hidden_pets=HiddenPets, summoned_pet_id=SummonedPetID} = PetBagInfo, 
	IsHidden = 
		case HiddenPets of
			undefined -> false;
			_ -> lists:member(PetID, HiddenPets)
		end,
	if
		IsHidden andalso HiddenState =:= ?HIDDEN_STATE ->
		   ?THROW_ERR(?ERR_PET_HIDDEN_ERROR_PET_HAS_HIDDEN);
		IsHidden =:= false andalso HiddenState =:= ?NO_HIDDEN_STATE ->
		   ?THROW_ERR(?ERR_PET_HIDDEN_ERROR_PET_NO_HIDDEN);
		HiddenState =:= ?HIDDEN_STATE ->
			case lists:keymember(?BUFF_ID_LI_HUN, 
					#p_actor_buf.buff_id, RoleBase#p_role_base.buffs) of
				true ->
					?THROW_ERR(0, <<"中了离魂术时，不能附身宠物">>);
				_ ->
					next
			end;
		true ->
			next
	end,

	% case PetID =:= SummonedPetID of
	% 	true ->
	% 	   ?THROW_ERR(?ERR_PET_HIDDEN_ERROR_PET_HAS_SUMMONED);
	% 	false ->
	% 		next
	% end,
	case mod_map_pet:check_role_has_pet(RoleID,PetID) of
		{ok,PetInfo} ->
			next;
		_ ->
			PetInfo = null,
			?THROW_ERR(?ERR_PET_HIDDEN_ERROR_PET_NOT_FOUND)
	end,
	case HiddenState =:= ?HIDDEN_STATE  of
		true ->
			MaxHiddenPetNum = role_can_hidden_pet_num(RoleID),
			case length(lists:delete(SummonedPetID,HiddenPets)) >= MaxHiddenPetNum of
				true ->
					?THROW_ERR(?ERR_PET_HIDDEN_ERROR_PET_HIDDEN_NUM_LIMIT);
				false ->
					next
			end,
			% assert_sum_category_type(PetInfo,HiddenPets);
			next;
		false ->
			next
	end,
	{ok,HiddenPets,PetBagInfo,PetInfo, PetID =:= SummonedPetID}.

% assert_sum_category_type(PetInfo,HiddenPets) ->
% 	RoleID = PetInfo#p_pet.role_id,
% 	PetCategoryType = pet_category_type(PetInfo#p_pet.type_id),
% 	case lists:any(fun(PetID) ->
% 						   #p_pet{type_id=HiddenPetTypeID} = mod_map_pet:get_pet_info(RoleID, PetID),
% 						   HiddenPetCategoryType = pet_category_type(HiddenPetTypeID),
% 						   PetCategoryType =:= HiddenPetCategoryType
% 				   end, HiddenPets) of
% 		true ->
% 			?THROW_ERR(?ERR_PET_HIDDEN_ERROR_PET_HIDDEN_CATEGORY_TYPE_LIMIT);
% 		false ->
% 			next
% 	end.

t_pet_hidden(RoleID,PetID,HiddenState,HiddenPets,PetBagInfo) ->
	NewHiddenPets =
		case HiddenState of
			?NO_HIDDEN_STATE ->
				lists:delete(PetID, HiddenPets);
			_ ->
				[PetID|lists:delete(PetID, HiddenPets)]
		end,
	NewPetBagInfo = PetBagInfo#p_role_pet_bag{hidden_pets=NewHiddenPets},
	mod_map_pet:set_role_pet_bag_info(RoleID, NewPetBagInfo),
	{ok, NewPetBagInfo}.

%% 计算玩家出战(合体/离体)异兽攻击属性加成
calc_role_pet_mix_second_level_attr(RoleAttr,EquipsSecondAttr) ->
	#p_role_attr{role_id=RoleID,category=Category} = RoleAttr,
	case calc_pet_mix_fight_attr(RoleID,Category,EquipsSecondAttr) of
		{ok,NewEquipsSecondAttr} ->
			calc_pet_hidden_fight_attr(RoleID,Category,NewEquipsSecondAttr);
		_ ->
			undefined
	end.

calc_pet_mix_fight_attr(RoleID,Category,EquipsSecondAttr) ->
	case mod_map_pet:get_summoned_pet_info(RoleID) of
		undefined -> 
			{ok,EquipsSecondAttr};
		{PetID,PetInfo} ->
			{AttackArg,DefenceArg,HpArg} = pet_mix_fight_attr_arg(PetID,PetInfo),
			calc_pet_fight_attr(PetInfo,EquipsSecondAttr,Category,{AttackArg,DefenceArg,HpArg})
	end.

calc_pet_hidden_fight_attr(RoleID,Category,EquipsSecondAttr) ->
	case mod_map_pet:get_role_pet_bag_info(RoleID) of
		#p_role_pet_bag{hidden_pets=HiddenPets} ->
			{ok,lists:foldl(fun(PetID,AccEquipsSecondAttr) ->
									case mod_role_tab:get({?ROLE_SUMMONED_PET_ID,RoleID}) of
										PetID ->
											AccEquipsSecondAttr;
										_ ->
											case mod_map_pet:get_pet_info(RoleID, PetID) of
												undefined ->
													?ERROR_MSG("get_pet_info not found:~w",[{RoleID,PetID}]),
													AccEquipsSecondAttr;
												PetInfo ->
													FightAttrArg1 = pet_hidden_fight_attr_arg(PetInfo#p_pet.period),
													% FightAttrArg2 = cfg_pet_qinmidu:get_hidden_fight_attr_arg(PetInfo#p_pet.qinmidu),
													FightAttrArg2 = 0,
													FightAttrArg3 = FightAttrArg1 + FightAttrArg2,
													{ok,NewEquipsSecondAttr} = calc_pet_fight_attr(PetInfo,AccEquipsSecondAttr,Category,
														{FightAttrArg3,FightAttrArg3,FightAttrArg3}),
													NewEquipsSecondAttr
											end
									end
							end,EquipsSecondAttr,HiddenPets)};
		_ ->
			%%TODO镜像问题
			{ok,EquipsSecondAttr}
	end.

calc_pet_fight_attr(PetInfo,EquipsSecondAttr,Category,{AttackArg,DefenceArg,HpArg}) ->
	#p_pet{
		max_hp        = PetMaxHP, 
		phy_defence   = PetPhyDefence,
		magic_defence = PetMagicDefence,
		phy_attack    = PetPhyAttack,
		magic_attack  = PetMagicAttack
	} = PetInfo,
	case PetInfo#p_pet.attack_type of
		1 -> %% 物攻
			PetAttack = PetPhyAttack;
		2 -> 
			PetAttack = PetMagicAttack
	end,
	#role_second_level_attr{
		max_phy_attack   = MaxPhyAttack,
		min_phy_attack   = MinPhyAttack,
		max_magic_attack = MaxMagicAttack,
		min_magic_attack = MinMagicAttack,
		phy_defence      = PhyDefence,
		magic_defence    = MagicDefence,
		max_hp           = MaxHP
	} = EquipsSecondAttr,
	NewPetAttack = common_tool:to_integer(PetAttack*AttackArg),
	case Category =:= ?CATEGORY_WARRIOR
			 orelse Category =:= ?CATEGORY_HUNTER of
		true ->
			NewMinPhyAttack   = MinPhyAttack + NewPetAttack,
			NewMaxPhyAttack   = MaxPhyAttack + NewPetAttack,
			NewMinMagicAttack = MinMagicAttack,
			NewMaxMagicAttack = MaxMagicAttack;
		false ->
			NewMinPhyAttack   = MinPhyAttack,
			NewMaxPhyAttack   = MaxPhyAttack,
			NewMinMagicAttack = MinMagicAttack + NewPetAttack,
			NewMaxMagicAttack = MaxMagicAttack + NewPetAttack
	end,
	{ok,EquipsSecondAttr#role_second_level_attr{
			max_phy_attack   = NewMaxPhyAttack,
			min_phy_attack   = NewMinPhyAttack,
			max_magic_attack = NewMaxMagicAttack,
			min_magic_attack = NewMinMagicAttack,
			phy_defence      = PhyDefence+common_tool:to_integer(PetPhyDefence*DefenceArg),
			magic_defence    = MagicDefence+common_tool:to_integer(PetMagicDefence*DefenceArg),
			max_hp           = MaxHP+common_tool:to_integer(PetMaxHP*HpArg)
    }}.
%% 异兽战斗属性百分比参数 (到这里了就是宠物一定至少是跟随状态了)
pet_mix_fight_attr_arg(_PetID,PetInfo) ->
	% #p_pet{period=PetPeriod} = PetInfo,
	Arg1 = cfg_pet:get_summoned_arg(),
	% Arg1 = NoMixStateArg + cfg_pet_qinmidu:get_summon_fight_attr_arg(PetPeriod, PetInfo#p_pet.qinmidu),
	{AttackArg, DefenceArg, HpArg} = mod_pet_hun:get_fight_arg_to_role(PetInfo),
	{AttackArg + Arg1, DefenceArg + Arg1, HpArg + Arg1}.


pet_hidden_fight_attr_arg(_PetPeriod) ->
	cfg_pet:get_hidden_arg().


%% 异兽是否附身 
is_pet_hidden(RoleID,PetID) ->
	PetBagInfo = mod_map_pet:get_role_pet_bag_info(RoleID),
	case PetBagInfo#p_role_pet_bag.hidden_pets of
		undefined -> false;
		HiddenPets -> lists:member(PetID, HiddenPets)
	end.

%% 玩家可附身的异兽个数
role_can_hidden_pet_num(RoleID) ->
	% {ok,#p_role_attr{level = RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	VipLevel     = mod_vip:get_role_vip_level(RoleID),
	NuqiSkillRec = mod_role_skill:get_role_nuqi_skill_info(RoleID),
	ShapeNum     = mod_role_skill:get_nuqi_skill_shape_num(NuqiSkillRec#r_role_skill_info.skill_id),
	cfg_pet:get_max_hidden(ShapeNum, VipLevel).
	% cfg_pet:get_max_hidden(RoleLevel, VipLevel).
	% cfg_jingjie:get_possessed_pet(RoleJingjie).
	
% %% 异兽职业类型
% pet_category_type(PetTypeID) ->
% 	PetBaseInfo = cfg_pet:get_base_info(PetTypeID),
% 	PetBaseInfo#p_pet_base_info.category_type.
