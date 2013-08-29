%% Author: dizengrong
%% Created: 2013-5-3
%% @doc: t6宠物技能

-module (mod_pet_skill).
-include("mgeem.hrl").
-compile(export_all).

-define(MOD_UNICAST(RoleID, Method, Msg), common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, Method, Msg)).
-define(_pet_info,	?DEFAULT_UNIQUE,	?PET,	?PET_INFO,	#m_pet_info_toc).%}

%% 获取玩家绝技的
get_max_role_pet_jueji(RoleID) ->
	case mod_map_pet:get_role_pet_bag_info(RoleID) of
		undefined -> 0;
		PetBagInfo ->
			Fun = fun(#p_pet_id_name{pet_id = PetId}, Acc) -> 
				PetInfo = mod_map_pet:get_pet_info(RoleID, PetId),
				max(PetInfo#p_pet.jueji#p_pet_jue_ji.level, Acc) end,
			lists:foldl(Fun, 0, PetBagInfo#p_role_pet_bag.pets)
	end.

do_learn_skill(RoleID, DataIn) ->
	PetInfo = mod_map_pet:get_pet_info(RoleID, DataIn#m_pet_learn_skill_tos.pet_id),
	SkillID = DataIn#m_pet_learn_skill_tos.skill_id,
	Ret = case SkillID == PetInfo#p_pet.jueji#p_pet_jue_ji.skill_id of
		true  -> learn_jueji(RoleID, PetInfo);
		false -> learn_other_skill(RoleID, DataIn, PetInfo)
	end,
	case Ret of
		{ok, NewPetInfo} ->
			Msg = #m_pet_learn_skill_toc{
				succ   = true,
				succ2  = true,
				pet_id = NewPetInfo#p_pet.pet_id,
				skills = NewPetInfo#p_pet.skills,
				tricks = NewPetInfo#p_pet.tricks,
				jueji  = NewPetInfo#p_pet.jueji
			},
			?MOD_UNICAST(RoleID, ?PET_LEARN_SKILL, Msg);
		{error, Reason} ->
			common_misc:send_common_error(RoleID, 0, Reason)
	end.

%% 提升绝技等级，只能一级一级的提升
learn_jueji(RoleID, PetInfo) ->
	SkillID   = PetInfo#p_pet.jueji#p_pet_jue_ji.skill_id,
	NextLevel = PetInfo#p_pet.jueji#p_pet_jue_ji.level + 1,
	{ok, SkillLevelInfo} = mod_skill_manager:get_skill_level_info(SkillID, PetInfo#p_pet.jueji#p_pet_jue_ji.level),
	case check_learn_skill(RoleID, SkillID, SkillLevelInfo, jueji) of
		{error, Reason} -> {error, Reason};
		true -> 
			CurMaxLevel = cfg_pet_jueji:max_jueji_level(PetInfo#p_pet.level),
			case PetInfo#p_pet.jueji#p_pet_jue_ji.level >= CurMaxLevel of
				true  -> {error, <<"该宠物等级下绝技不能升级了，请先提升宠物等级">>};
				false ->
					learn_skill_cost(RoleID, SkillLevelInfo,?CONSUME_TYPE_SILVER_PET_LEARN_JUEJI,?LOG_ITEM_TYPE_LOST_PET_JUEJI_LEARN),
					NewJueji   = PetInfo#p_pet.jueji#p_pet_jue_ji{level = NextLevel},
					NewPetInfo = PetInfo#p_pet{jueji = NewJueji},
					CurLevel =  common_tool:to_list( PetInfo#p_pet.jueji#p_pet_jue_ji.level),
					[#p_skill{name=SkillName}] = common_config_dyn:find(skill,SkillID),
					FormatText = common_tool:to_list(SkillName) ++ 
													 ":Lv" ++ CurLevel ++ "->Lv" ++ common_tool:to_list(NextLevel),
					?TRY_CATCH(mod_map_pet:write_pet_action_log(NewPetInfo,RoleID,?PET_ACTION_TYPE_LEARN_JUEJI,
													 "异兽绝技提升",SkillID,FormatText)),
					mod_pet_attr:reload_pet_info(NewPetInfo),
					mod_role_event:notify(RoleID, {?ROLE_EVENT_PET_JUEJI, NextLevel}),
					{ok, NewPetInfo}
			end
	end.

%% 学习天赋技能
learn_other_skill(RoleID, DataIn, PetInfo) ->
	SkillID = DataIn#m_pet_learn_skill_tos.skill_id,
	{ok, SkillLevelInfo} = mod_skill_manager:get_skill_level_info(SkillID, 1),
	#r_pet_skill{skill_type=SkillType} = cfg_pet_skill:skill_info(SkillID),
	
	case check_learn_skill(RoleID, SkillID, SkillLevelInfo, SkillType) of
		{error, Reason} -> {error, Reason};
		true -> 
			learn_skill_cost(RoleID, SkillLevelInfo,?CONSUME_TYPE_SILVER_PET_LEARN_SKILL,?LOG_ITEM_TYPE_LOST_PET_SKILL_LEARN),
			{ok, NewPetInfo} = case SkillType > 100 of
				true ->
					learn_trick_skill(RoleID, PetInfo, SkillID, SkillType);
				false ->
					learn_normal_skill(RoleID, PetInfo, SkillID, SkillType)
			end,
			[#p_skill{name=SkillName}] = common_config_dyn:find(skill,SkillID),
			mod_map_pet:write_pet_action_log(NewPetInfo,RoleID,?PET_ACTION_TYPE_LEARN_SKILL,"异兽学技能",SkillID,SkillName), 
			{ok, NewPetInfo}
	end.

%% 学习天赋技能
learn_trick_skill(RoleID, PetInfo, SkillID, SkillType) ->
	%% todo:这里的SkillLevel以后会改
	SkillLevel = case SkillID rem 100000 of
		N when N =< 3 -> 1; 
		N when N =< 6 -> 2; 
		N when N =< 9 -> 3; 
		N when N =< 12 -> 4
    end,
    {OldTrick, OtherTricks} = case lists:keytake(SkillType, #p_pet_skill.skill_type, PetInfo#p_pet.tricks) of
    	{value, OldTrick2, OtherTricks2} ->
    		{OldTrick2, OtherTricks2};
    	_ ->
    		{undefined, PetInfo#p_pet.tricks}
    end,
	NewTrick    = #p_pet_skill{skill_id=SkillID, skill_type=SkillType,skill_level = SkillLevel},
	NewPetInfo1 = PetInfo#p_pet{tricks = [NewTrick|OtherTricks]},
	NewPetInfo2 = reload_pet_and_role_base(RoleID, NewPetInfo1,
		get_pet_trick_buffs(OldTrick), get_pet_trick_buffs(NewTrick)),
	%% 完成成就
    mod_achievement2:achievement_update_event(RoleID, 32004, length([NewTrick|OtherTricks])),
	{ok, NewPetInfo2}.

%% 学习普通技能
learn_normal_skill(RoleID, PetInfo, SkillID, SkillType) ->
	{OldSkill, OtherSkills} = case lists:keytake(SkillType, #p_pet_skill.skill_type, PetInfo#p_pet.skills) of
    	{value, OldSkill2, OtherSkills2} ->
    		{OldSkill2, OtherSkills2};
    	_ ->
    		{undefined, PetInfo#p_pet.skills}
    end,
    NewSkill    = #p_pet_skill{skill_id = SkillID,skill_type = SkillType},
	NewPetInfo1 = PetInfo#p_pet{skills=[NewSkill|OtherSkills]},
	NewPetInfo2 = reload_pet_and_role_base(RoleID, NewPetInfo1,
		get_pet_skill_buffs(OldSkill), get_pet_skill_buffs(NewSkill)),
	{ok, NewPetInfo2}.

learn_skill_cost(RoleID, SkillLevelInfo,LogType1,LogType2) ->
	CostSilver   = SkillLevelInfo#p_skill_level.need_silver,
	CostItemType = SkillLevelInfo#p_skill_level.need_item,
	CostItemNum  = SkillLevelInfo#p_skill_level.need_num,
	true         = common_bag2:use_money(RoleID, silver_any, CostSilver, LogType1),
	ok           = mod_bag:use_item(RoleID, CostItemType, CostItemNum, LogType2),
    ok.

check_learn_skill(RoleID, SkillID, SkillLevelInfo, SkillType) ->
	CostSilver   = SkillLevelInfo#p_skill_level.need_silver,
	CostItemType = SkillLevelInfo#p_skill_level.need_item,
	CostItemNum  = SkillLevelInfo#p_skill_level.need_num,
	case common_bag2:check_money_enough(silver_any, CostSilver, RoleID) of
		false -> {error, ?_LANG_NOT_ENOUGH_SILVER};
		true  -> 
			case mod_bag:get_goods_num_by_typeid([1,2,3], RoleID, CostItemType) of
				{ok, Num} when Num >= CostItemNum ->
					if
						SkillType == jueji -> 
							true;
						SkillType > 100 -> %% 确定是天赋技能
							{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
							RoleCategory   = RoleAttr#p_role_attr.category,
						    check_trick_attack_type(RoleCategory, SkillID);
						true -> 
							true
					end;
				_ -> {error, <<"学习需要的道具不足">>}
			end
	end.

check_trick_attack_type(RoleCategory, SkillID) ->
	%% t6中宠物学习的天赋技能的类别要跟角色的职业类型一致
    case RoleCategory =:= 1 orelse RoleCategory =:= 2 of
        true  -> RoleAttackType = 1;
        false -> RoleAttackType = 2
    end,
	[AttackTypeList] = common_config_dyn:find(pet_etc,{pet_trick_attack_type,RoleAttackType}),
	case lists:member(SkillID, AttackTypeList) of
        true  -> true;
        false -> {error, ?_LANG_PET_LEARN_SKILL_ERROR_ATTACKTYPE}
    end.

%% 绝技提升品质
do_up_jueji_quality(RoleID, DataIn) ->
	PetId       = DataIn#m_pet_jueji_up_quality_tos.pet_id,
	PetInfo     = mod_map_pet:get_pet_info(RoleID, PetId),
	case check_up_quality(RoleID, PetInfo) of
		{error, Reason} -> common_misc:send_common_error(RoleID, 0, Reason);
		{ok, NextQuality} ->
			up_jueji_quality_cost(RoleID, NextQuality),
			case common_tool:random(1, 100) =< cfg_pet_jueji:up_quality_rate(PetInfo#p_pet.jueji#p_pet_jue_ji.quality) of
				true -> 
					NewJueji   = PetInfo#p_pet.jueji#p_pet_jue_ji{quality = NextQuality},
					NewPetInfo = PetInfo#p_pet{jueji = NewJueji},
					PrevColorName = common_misc:get_color_name(PetInfo#p_pet.jueji#p_pet_jue_ji.quality),
					NextColorName = common_misc:get_color_name(NextQuality),
					catch mod_map_pet:write_pet_action_log(NewPetInfo,RoleID,?PET_ACTION_TYPE_JUEJI_QUALITY,
													 "绝技提升品质",NextQuality,
													 "颜色："++ PrevColorName ++ "->" ++ NextColorName  ),
					mod_map_pet:set_pet_info(PetId, NewPetInfo),
					Msg = #m_pet_jueji_up_quality_toc{
						pet_id  = PetId,
						quality = NextQuality
					},
					?MOD_UNICAST(RoleID, ?PET_JUEJI_UP_QUALITY, Msg),
					ok;
				false -> 
					common_misc:send_common_error(RoleID, 0, <<"运气差了点啊，提升品质失败">>)
			end
	end.

up_jueji_quality_cost(RoleID, NextQuality) ->
	{{CostItemType, CostItemNum}, CostSilver, _} = cfg_pet_jueji:up_quality_require(NextQuality),
	LogType1 = ?CONSUME_TYPE_SILVER_PET_LEARN_SKILL,
	LogType2 = ?LOG_ITEM_TYPE_UP_PET_JUEJI_QUALITY,
	true     = common_bag2:use_money(RoleID, silver_any, CostSilver, LogType1),
	ok       = mod_bag:use_item(RoleID, CostItemType, CostItemNum, LogType2),
    ok.

check_up_quality(RoleID, PetInfo) ->
	NextQuality = get_next_quality(PetInfo#p_pet.jueji#p_pet_jue_ji.quality),
	case NextQuality of
		full_quality -> {error, <<"宠物绝技品质已满，无需提升了">>};
		_ ->
			{{CostItemType, CostItemNum}, 
			 CostSilver, _NeedUseTimes} = cfg_pet_jueji:up_quality_require(NextQuality),
			case common_bag2:check_money_enough(silver_any, CostSilver, RoleID) of
				false -> {error, ?_LANG_NOT_ENOUGH_SILVER};
				true  -> 
					case mod_bag:get_goods_num_by_typeid([1,2,3], RoleID, CostItemType) of
						{ok, Num} when Num >= CostItemNum ->
							{ok, NextQuality};
						_ -> 
							{error, <<"需要的道具不足">>}
					end
			end
	end.


get_next_quality(CurrentQuality) ->
	case CurrentQuality of
		?COLOUR_GREEN 	-> ?COLOUR_BLUE;
		?COLOUR_BLUE 	-> ?COLOUR_PURPLE;
		?COLOUR_PURPLE 	-> ?COLOUR_ORANGE;
		?COLOUR_ORANGE 	-> ?COLOUR_GOLD;
		?COLOUR_GOLD 	-> ?COLOUR_RED;
		?COLOUR_RED 	-> full_quality
	end.

get_pet_trick_buffs(#p_pet_skill{skill_id = SkillID}) ->
    case common_config_dyn:find(pet_etc, {pet_trick_skill_type, SkillID}) of
        [add_buff_to_role] ->
            {get_skill_buffs(SkillID), []};
        [add_buff_to_pet] ->
            {[], get_skill_buffs(SkillID)};
        _ ->
            {[], []}
    end;
get_pet_trick_buffs(_) -> {[], []}.

get_pet_skill_buffs(#p_pet_skill{skill_id = SkillID, skill_type = SkillType}) ->
    case common_config_dyn:find(pet_etc, {pet_skill_type, SkillType}) of
        [add_buff_to_role] ->
            {get_skill_buffs(SkillID), []};
        [add_buff_to_pet] ->
            {[], get_skill_buffs(SkillID)};
        _ ->
            {[], []}
    end;
get_pet_skill_buffs(_) -> {[], []}.

get_skill_buffs(SkillID) ->
	[SkillLevelList] = common_config_dyn:find(skill_level, SkillID),
    SkillLevelInfo = lists:keyfind(1, #p_skill_level.level, SkillLevelList),
    SkillLevelInfo#p_skill_level.buffs.

reload_pet_and_role_base(RoleID, OldPet, 
		{OldRoleBuffs, OldPetBuffs}, {NewRoleBuffs, NewPetBuffs}) ->
	NewPet = mod_pet_buff:add_buff2(
		mod_pet_buff:del_buff2(OldPet, OldPetBuffs), NewPetBuffs),
	mod_pet_attr:reload_pet_info(NewPet),
	PetBag = mod_map_pet:get_role_pet_bag_info(RoleID),
	case mod_role_pet:is_pet_equipped(OldPet, PetBag) of
		true ->
			{ok, RoleBase1} = mod_map_role:get_role_base(RoleID),
			RoleBase2 = mod_role_buff:add_buff2(
				mod_role_buff:del_buff2(RoleBase1, OldRoleBuffs), NewRoleBuffs),
			RoleBase3 = mod_role_pet:calc(
				RoleBase2, PetBag, [{'-', OldPet}, {'+', NewPet}]),
			mod_role_attr:reload_role_base(RoleBase3);
		false ->
			ignore
	end,
	NewPet.
