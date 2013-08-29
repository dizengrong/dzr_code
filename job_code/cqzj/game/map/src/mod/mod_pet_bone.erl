%% Author: dizengrong
%% Created: 2012-10-31
%% @doc: 这里实现的是t6项目中异兽兽骨模块

-module(mod_pet_bone).

-include("mgeem.hrl").

-export([handle_client_req/6
	]).

-define(UP_TYPE_NORMAL,			1).	%% 普通方式提升兽骨
-define(UP_TYPE_GOLD,			2).	%% 元宝方式提升兽骨

-define(ITEM_PET_BONE_MATERIAL,	14110004). %% 兽骨丹物品id

%% 兽骨位置定义
-define(BONE_POS_HEAD,			1). %% 头部
-define(BONE_POS_NECK,			2). %% 颈部
-define(BONE_POS_BODY,			3). %% 身体
-define(BONE_POS_LEG,			4). %% 腿部
-define(BONE_POS_WAIST,			5). %% 腰部
-define(BONE_POS_HAND,			6). %% 手部

-define(ERR_NO_PET_BONE_MATERIAL, 	<<"没有可用的兽骨丹">>).
%%-define(ERR_PET_BONE_UP, 			<<"兽骨等级不能超过宠物的阶位">>).
-define(ERR_PET_BONE_LV_FULL, 		<<"兽骨等级已满">>).



handle_client_req(Unique, Method, DataIn, RoleID, _PID, Line) ->
	case Method of
		?PET_BONE_UP -> %% 锻炼兽骨
			req_up_bone(Unique, DataIn, RoleID, Line)
	end.

%% TO-DO:
%% 		因为兽骨各部位修炼等级影响宠物装备的加成系数，
%% 		所以要在修炼等级升级时处理宠物属性的改变
req_up_bone(Unique, DataIn, RoleID, Line) ->
	PetId   = DataIn#m_pet_bone_up_tos.pet_id,
	BonePos = DataIn#m_pet_bone_up_tos.pos,
	PetRec  = mod_map_pet:get_pet_info(RoleID,PetId),
		
	Ret = case up_bone_common_check(PetRec, BonePos) of
		{error, Reason} -> {error, Reason};
		ok ->
			case DataIn#m_pet_bone_up_tos.type of
				?UP_TYPE_NORMAL ->
					up_bone_by_item(RoleID, PetRec, BonePos);
				?UP_TYPE_GOLD ->
					up_bone_by_gold(RoleID, PetRec, BonePos)
			end
	end,
	case Ret of
		{error, Reason1} ->
			Msg = #m_pet_bone_up_toc{
				succ   = false,
				reason = Reason1
			};
		{ok, IsLevelUpped, NewPetRec} ->
			Msg = #m_pet_bone_up_toc{
				succ   = true,
				pet_id = PetId,
				bone   = NewPetRec#p_pet.bone
			},
			%% 完成成就
			case DataIn#m_pet_bone_up_tos.type of
				?UP_TYPE_GOLD -> 
					mod_achievement2:achievement_update_event(RoleID, 23004, 1),
                    mod_achievement2:achievement_update_event(RoleID, 24006, 1),
                    mod_achievement2:achievement_update_event(RoleID, 32002, 1);
                _ -> ignore
            end,
			case IsLevelUpped of
				true -> 
					pet_bone_level_up_event(RoleID, BonePos, PetRec, NewPetRec);
				false -> 
					mod_map_pet:set_pet_info(PetId, NewPetRec)
			end
	end,
	common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_BONE_UP, Msg).

%% 宠物的兽骨升级的事件
pet_bone_level_up_event(RoleID, BonePos, OldPetRec, NewPetRec) ->
	%% 兽骨升级了，会影响宠物所穿装备的属性加成
	OldBoneLv  = get_bone_lv(BonePos, OldPetRec#p_pet.bone),
	NewBoneLv  = get_bone_lv(BonePos, NewPetRec#p_pet.bone),
	PetEquip   = get_pet_equip(BonePos, NewPetRec#p_pet.equips),
	NewPetRec2 = mod_pet_attr:calc(NewPetRec, 
					'-', mod_pet_equip:equip_attrs(PetEquip, OldBoneLv), 
					'+', mod_pet_equip:equip_attrs(PetEquip, NewBoneLv)),
	mod_pet_attr:reload_pet_info(NewPetRec2),
	mod_role_pet:update_role_base(RoleID, '-', OldPetRec, '+', NewPetRec2),
	%% 完成成就
	case get_all_min_level(NewPetRec#p_pet.bone) >= cfg_bone:get_misc(max_level) of
		true ->
			mod_achievement2:achievement_update_event(RoleID, 31002, 1);
		false -> ignore
	end,
	ok.

get_all_min_level(PetBoneRec) ->
	lists:min([PetBoneRec#p_pet_bone.head_lv, PetBoneRec#p_pet_bone.body_lv,
			   PetBoneRec#p_pet_bone.leg_lv, PetBoneRec#p_pet_bone.waist_lv,
			   PetBoneRec#p_pet_bone.neck_lv, PetBoneRec#p_pet_bone.hand_lv]).

up_bone_by_item(RoleID, PetRec, BonePos) ->
	Item = ?ITEM_PET_BONE_MATERIAL,
	case mod_bag:check_inbag_by_typeid(RoleID, Item) of
		false ->
			{error, ?ERR_NO_PET_BONE_MATERIAL};
		_ ->
			LogType = ?LOG_ITEM_TYPE_UP_PET_BONE_LOST,
			ok      = mod_bag:use_item(RoleID, Item, 1, LogType),
			{IsLevelUpped, NewPetRec} = add_bone_exp(PetRec, BonePos, cfg_bone:get_misc(shougu_dan_gain_exp)),
			{ok, IsLevelUpped, NewPetRec}
	end.

add_bone_exp(PetRec, BonePos, AddExp) -> 
	PetBoneRec = PetRec#p_pet.bone,
	Period     = PetRec#p_pet.period,
	case BonePos of
		?BONE_POS_HEAD ->
			OldExp          = PetBoneRec#p_pet_bone.head_exp,
			OldLv           = PetBoneRec#p_pet_bone.head_lv,
			{NewLv, NewExp} = add_bone_exp_help(OldExp, OldLv, AddExp, Period),
			NewPetBoneRec   = PetBoneRec#p_pet_bone{head_exp = NewExp, head_lv = NewLv};
		?BONE_POS_BODY ->
			OldExp          = PetBoneRec#p_pet_bone.body_exp,
			OldLv           = PetBoneRec#p_pet_bone.body_lv,
			{NewLv, NewExp} = add_bone_exp_help(OldExp, OldLv, AddExp, Period),
			NewPetBoneRec   = PetBoneRec#p_pet_bone{body_exp = NewExp, body_lv = NewLv};
		?BONE_POS_LEG ->
			OldExp          = PetBoneRec#p_pet_bone.leg_exp,
			OldLv           = PetBoneRec#p_pet_bone.leg_lv,
			{NewLv, NewExp} = add_bone_exp_help(OldExp, OldLv, AddExp, Period),
			NewPetBoneRec   = PetBoneRec#p_pet_bone{leg_exp = NewExp, leg_lv = NewLv};
		?BONE_POS_WAIST ->
			OldExp          = PetBoneRec#p_pet_bone.waist_exp,
			OldLv           = PetBoneRec#p_pet_bone.waist_lv,
			{NewLv, NewExp} = add_bone_exp_help(OldExp, OldLv, AddExp, Period),
			NewPetBoneRec   = PetBoneRec#p_pet_bone{waist_exp = NewExp, waist_lv = NewLv};
		?BONE_POS_NECK ->
			OldExp          = PetBoneRec#p_pet_bone.neck_exp,
			OldLv           = PetBoneRec#p_pet_bone.neck_lv,
			{NewLv, NewExp} = add_bone_exp_help(OldExp, OldLv, AddExp, Period),
			NewPetBoneRec   = PetBoneRec#p_pet_bone{neck_exp = NewExp, neck_lv = NewLv};
		?BONE_POS_HAND ->
			OldExp          = PetBoneRec#p_pet_bone.hand_exp,
			OldLv           = PetBoneRec#p_pet_bone.hand_lv,
			{NewLv, NewExp} = add_bone_exp_help(OldExp, OldLv, AddExp, Period),
			NewPetBoneRec   = PetBoneRec#p_pet_bone{hand_exp = NewExp, hand_lv = NewLv}
	end,
	IsLevelUpped = (NewLv =/= OldLv),
	{IsLevelUpped, PetRec#p_pet{bone = NewPetBoneRec}}.

add_bone_exp_help(OldExp, OldLv, AddExp, _Period) ->
	TotalExp    = OldExp + AddExp,
	LevelUpNeed = cfg_bone:get_exp(OldLv),
	case TotalExp >= LevelUpNeed of
		true -> 
			NewLv = OldLv + 1,
			case NewLv >= cfg_bone:get_misc(max_level) of
				true  -> NewExp = 0;
				false -> NewExp = TotalExp - LevelUpNeed
			end;
		false ->
			NewLv  = OldLv,
			NewExp = TotalExp
	end,
	{NewLv, NewExp}.

up_bone_by_gold(RoleID, PetRec, BonePos) ->
	LogType = ?CONSUME_TYPE_GOLD_BUG_PET_BONE_ITEM,
	case common_bag2:use_money(RoleID, gold_any, cfg_bone:get_misc(gold_cost), LogType) of
		true ->
			{IsLevelUpped, NewPetRec} = add_bone_exp(PetRec, BonePos, cfg_bone:get_misc(gold_gain_exp)),
			{ok, IsLevelUpped, NewPetRec};
		{error, Reason} ->
			{error, Reason}
	end.

%% 策划说去掉兽骨升级的宠物阶数控制
up_bone_common_check(PetRec, BonePos) ->
	Level = get_bone_lv(BonePos, PetRec#p_pet.bone),
	case Level >= cfg_bone:get_misc(max_level) of
		true -> {error, ?ERR_PET_BONE_LV_FULL};
		false -> ok
	end.

get_bone_lv(BonePos, PetBone) ->
	case BonePos of
		?BONE_POS_HEAD ->
			PetBone#p_pet_bone.head_lv;
		?BONE_POS_BODY ->
			PetBone#p_pet_bone.body_lv;
		?BONE_POS_LEG ->
			PetBone#p_pet_bone.leg_lv;
		?BONE_POS_WAIST ->
			PetBone#p_pet_bone.waist_lv;
		?BONE_POS_NECK ->
			PetBone#p_pet_bone.neck_lv;
		?BONE_POS_HAND ->
			PetBone#p_pet_bone.hand_lv
	end.

get_pet_equip(BonePos, PetEquips) ->
	case BonePos of
		?BONE_POS_HEAD ->
			PetEquips#p_pet_equips.head;
		?BONE_POS_BODY ->
			PetEquips#p_pet_equips.body;
		?BONE_POS_LEG ->
			PetEquips#p_pet_equips.leg;
		?BONE_POS_WAIST ->
			PetEquips#p_pet_equips.waist;
		?BONE_POS_NECK ->
			PetEquips#p_pet_equips.neck;
		?BONE_POS_HAND ->
			PetEquips#p_pet_equips.hand
	end.
