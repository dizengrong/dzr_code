%% Author: dizengrong
%% Created: 2012-11-12
%% @doc: 这里实现的是t6项目中宠物兽魂模块

-module (mod_pet_hun).

-include("mgeem.hrl").

-compile(export_all).

-export([handle/3]).

%% export for role_misc callback
-export([init/2, delete/1]).

-define(ROLE_PET_HUN_DATA, role_pet_hun_data).

-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, Method, Msg)).

-define(HUN_POS_ATT, 	1).		%% 攻击兽魂
-define(HUN_POS_DEF, 	2).		%% 防御兽魂
-define(HUN_POS_HP, 	3).		%% 气血兽魂

%% ======================== error msg ==============================
-define(ERR_REACH_MAX_LEVEL, "该兽魂已达最高等级了").
-define(ERR_NO_HUN_LI_DAN,   "您的背包中没有魂力丹").


init(RoleID, RolePetHunRec) ->
	case RolePetHunRec of
		false ->	
			RolePetHunRec1 = #r_role_pet_hun{
				role_id = RoleID
			};
		_ ->
			RolePetHunRec1 = RolePetHunRec
	end,
	set_role_pet_hun_info(RoleID, RolePetHunRec1).

delete(RoleID) ->
	erlang:erase({?ROLE_PET_HUN_DATA, RoleID}).

%% =========================== 进程字典操作接口 ==========================	
set_role_pet_hun_info(RoleID, RolePetHunRec) ->
	erlang:put({?ROLE_PET_HUN_DATA, RoleID}, RolePetHunRec).

set_role_pet_hun_info(RoleID, PetId, PetHunRec) ->
	RolePetHunRec  = get_role_pet_hun_info(RoleID),
	Datas          = RolePetHunRec#r_role_pet_hun.datas,
	Datas1         = lists:keystore(PetId, 1, Datas, {PetId, PetHunRec}),
	RolePetHunRec1 = RolePetHunRec#r_role_pet_hun{datas = Datas1},
	set_role_pet_hun_info(RoleID, RolePetHunRec1).

get_role_pet_hun_info(RoleID) ->
	case erlang:get({?ROLE_PET_HUN_DATA, RoleID}) of
		undefined ->
			#r_role_pet_hun{
				role_id = RoleID
			};
		Rec ->
			Rec
	end.

get_pet_hun_info(RoleID, PetId) ->
	RolePetHunRec = get_role_pet_hun_info(RoleID),
	Datas         = RolePetHunRec#r_role_pet_hun.datas,
	case lists:keyfind(PetId, 1, Datas) of
		false ->
			PetHunRec      = #p_pet_hun{},
			Datas1         = lists:keystore(PetId, 1, Datas, {PetId, PetHunRec}),
			RolePetHunRec1 = RolePetHunRec#r_role_pet_hun{datas = Datas1},
			set_role_pet_hun_info(RoleID, RolePetHunRec1);
		{PetId, PetHunRec} ->
			ok
	end,
	PetHunRec.
%% =========================== 进程字典操作接口 ==========================	

%% =========================== handle 处理 ===============================
handle(Method, RoleID, DataIn) ->
	case Method of
		?PET_HUN_INFO ->
			do_get_info(RoleID, DataIn);
		?PET_UP_HUN ->	
			do_up_hun(RoleID, DataIn)
	end.
%% =========================== handle 处理 ===============================


%% =========================== PET_HUN_INFO 处理 =========================
do_get_info(RoleID, DataIn) ->
	PetId     = DataIn#m_pet_hun_info_tos.pet_id,
	PetHunRec = get_pet_hun_info(RoleID, PetId),
	send_hun_info_to_client(RoleID, PetId, PetHunRec).
	
send_hun_info_to_client(RoleID, PetId, PetHunRec) ->
	Msg = #m_pet_hun_info_toc{
		pet_id      = PetId, 
		data        = PetHunRec,
		att_add     = trunc(cfg_pet_hun:get_mix_add(PetHunRec#p_pet_hun.att_hun_lv)*100),
		def_add     = trunc(cfg_pet_hun:get_mix_add(PetHunRec#p_pet_hun.def_hun_lv)*100),
		ph_add      = trunc(cfg_pet_hun:get_mix_add(PetHunRec#p_pet_hun.hp_hun_lv)*100),
		max_att_exp = cfg_pet_hun:get_level_up_exp(PetHunRec#p_pet_hun.att_hun_lv),
		max_def_exp = cfg_pet_hun:get_level_up_exp(PetHunRec#p_pet_hun.def_hun_lv),
		max_ph_exp  = cfg_pet_hun:get_level_up_exp(PetHunRec#p_pet_hun.hp_hun_lv)
	},
	?MOD_UNICAST(RoleID, ?PET_HUN_INFO, Msg).
%% =========================== PET_HUN_INFO 处理 =========================

%% =========================== PET_UP_HUN 处理 =========================
do_up_hun(RoleID, DataIn) ->
	PetId     = DataIn#m_pet_up_hun_tos.pet_id,
	HunPos    = DataIn#m_pet_up_hun_tos.where,
	IsAutoBuy = DataIn#m_pet_up_hun_tos.auto_buy,
	PetHunRec = get_pet_hun_info(RoleID, PetId),

	Ret = case up_hun_common_check(RoleID, PetHunRec, HunPos, IsAutoBuy) of
		{error, Reason0} ->
			{error, Reason0};
		true ->
			do_up_hun_help(HunPos, PetHunRec)
	end,
	case Ret of
		{error, Reason} ->
			common_misc:send_common_error(RoleID, 0, Reason);
		{IsLevelUp, _NewLv, PetHunRec1} ->
			set_role_pet_hun_info(RoleID, PetId, PetHunRec1),
			send_hun_info_to_client(RoleID, PetId, PetHunRec1),
			case IsAutoBuy of
				1 -> 
					Cost    = get_hun_li_dan_price(HunPos),
					LogType = ?CONSUME_TYPE_GOLD_BUY_HUN_LI_DAN,
					true    = common_bag2:use_money(RoleID, gold_any, Cost, LogType);
				0 ->
					TypeID  = get_hun_li_dan_type_id(HunPos),
					LogType = ?LOG_ITEM_TYPE_UP_PET_HUN_LOST,
					ok      = mod_bag:use_item(RoleID, TypeID, 1, LogType)
			end,
			case IsLevelUp of
				true ->
					%% 完成成就
					case is_all_full_level(PetHunRec1) of
						true -> 
							mod_achievement2:achievement_update_event(RoleID, 31001, 1),
							mod_achievement2:achievement_update_event(RoleID, 32001, 1);
						false -> ignore
					end,
					mod_map_pet:check_if_should_update_role_attr(RoleID, PetId);
				false -> ignore
			end
	end.

%% 检查看是否所有的兽魂都满级了 
is_all_full_level(PetHunRec) ->
	FullLv = cfg_pet_hun:get_misc(max_hun_lv),
	((PetHunRec#p_pet_hun.att_hun_lv >= FullLv) andalso 
	 	(PetHunRec#p_pet_hun.def_hun_lv >= FullLv) andalso 
	 	(PetHunRec#p_pet_hun.hp_hun_lv >= FullLv)). 


do_up_hun_help(HunPos, PetHunRec) ->
	AddExp = cfg_pet_hun:get_misc(hun_li_dan_exp),
	CurExp = get_hun_exp(PetHunRec, HunPos),
	CurLv  = get_hun_level(PetHunRec, HunPos),
	LvUpNeedExp = cfg_pet_hun:get_level_up_exp(CurLv),
	case CurExp + AddExp >= LvUpNeedExp of
		true -> 
			NewExp    = CurExp + AddExp - LvUpNeedExp,
			NewLv     = CurLv + 1,
			IsLevelUp = true;
		false ->
			NewExp    = CurExp + AddExp,
			NewLv     = CurLv,
			IsLevelUp = false
	end,
	{IsLevelUp, NewLv, set_hun_new_exp_and_lv(PetHunRec, HunPos, NewExp, NewLv)}.

up_hun_common_check(RoleID, PetHunRec, HunPos, IsAutoBuy) ->
	HunLv    = get_hun_level(PetHunRec, HunPos),
	MaxHunLv = cfg_pet_hun:get_misc(max_hun_lv),
	if
		HunLv >= MaxHunLv -> 
			{error, ?ERR_REACH_MAX_LEVEL};
		IsAutoBuy == 1 ->
			Cost = get_hun_li_dan_price(HunPos),
			case common_bag2:check_money_enough(gold_any, Cost, RoleID) of
				false ->
					{error, ?_LANG_SHOP_ENOUGH_GOLD};
				true ->
					true
			end;
		true -> %% IsAutoBuy == false
			TypeID = get_hun_li_dan_type_id(HunPos),
			case mod_bag:check_inbag_by_typeid(RoleID, TypeID) of
				false ->
					{error, ?ERR_NO_HUN_LI_DAN};
				_ ->
					true
			end
	end.

get_hun_li_dan_type_id(?HUN_POS_ATT) ->
	cfg_pet_hun:get_misc(att_hun_li_dan_item_type_id);
get_hun_li_dan_type_id(?HUN_POS_DEF) ->
	cfg_pet_hun:get_misc(def_hun_li_dan_item_type_id);
get_hun_li_dan_type_id(?HUN_POS_HP) ->
	cfg_pet_hun:get_misc(hp_hun_li_dan_item_type_id).

get_hun_li_dan_price(?HUN_POS_ATT) ->
	cfg_pet_hun:get_misc(att_hun_li_dan_price);
get_hun_li_dan_price(?HUN_POS_DEF) ->
	cfg_pet_hun:get_misc(def_hun_li_dan_price);
get_hun_li_dan_price(?HUN_POS_HP) ->
	cfg_pet_hun:get_misc(hp_hun_li_dan_price).
%% =========================== PET_UP_HUN 处理 =========================

%% =========================== 附身、合体加成 处理 =====================
add_pet_hun_attr(PetInfoRec) ->
	RoleID    = PetInfoRec#p_pet.role_id,
	PetId     = PetInfoRec#p_pet.pet_id,
	PetHunRec = get_pet_hun_info(RoleID, PetId),

	case mod_role_pet_mix:is_pet_hidden(RoleID, PetId) of
		true -> 
			AttAddRate = cfg_pet_hun:get_hidden_add(PetHunRec#p_pet_hun.att_hun_lv),
			DefAddRate = cfg_pet_hun:get_hidden_add(PetHunRec#p_pet_hun.def_hun_lv),
			HpAddRate  = cfg_pet_hun:get_hidden_add(PetHunRec#p_pet_hun.hp_hun_lv);
		false ->
			AttAddRate = 0,
			DefAddRate = 0,
			HpAddRate  = 0
	end,

	PetInfoRec#p_pet{
		max_hp        = trunc((HpAddRate  + 1) * PetInfoRec#p_pet.max_hp),
		phy_attack    = trunc((AttAddRate + 1) * PetInfoRec#p_pet.phy_attack),
		phy_defence   = trunc((DefAddRate + 1) * PetInfoRec#p_pet.phy_defence),
		magic_defence = trunc((DefAddRate + 1) * PetInfoRec#p_pet.magic_defence)
	}.

%% 获取兽魂给角色的加成小数: {攻击加成, 防御加成, 气血加成}.
get_fight_arg_to_role(PetInfoRec) ->	
	RoleID    = PetInfoRec#p_pet.role_id,
	PetId     = PetInfoRec#p_pet.pet_id,
	PetHunRec = get_pet_hun_info(RoleID, PetId),
	case mod_map_pet:is_pet_summoned(RoleID, PetId) of
		true ->
			{cfg_pet_hun:get_summon_add_to_role(PetHunRec#p_pet_hun.att_hun_lv),
			 cfg_pet_hun:get_summon_add_to_role(PetHunRec#p_pet_hun.def_hun_lv),
			 cfg_pet_hun:get_summon_add_to_role(PetHunRec#p_pet_hun.hp_hun_lv)};
		false ->
			{0,0,0}
	end.

%% =========================== 附身、合体加成 处理 =====================
	
%% =========================== local functions =========================
get_hun_level(PetHunRec, ?HUN_POS_ATT) -> PetHunRec#p_pet_hun.att_hun_lv;
get_hun_level(PetHunRec, ?HUN_POS_DEF) -> PetHunRec#p_pet_hun.def_hun_lv;
get_hun_level(PetHunRec, ?HUN_POS_HP) -> PetHunRec#p_pet_hun.hp_hun_lv.
	
get_hun_exp(PetHunRec, ?HUN_POS_ATT) -> PetHunRec#p_pet_hun.att_hun_exp;
get_hun_exp(PetHunRec, ?HUN_POS_DEF) -> PetHunRec#p_pet_hun.def_hun_exp;
get_hun_exp(PetHunRec, ?HUN_POS_HP) -> PetHunRec#p_pet_hun.hp_hun_exp.

set_hun_new_exp_and_lv(PetHunRec, ?HUN_POS_ATT, NewExp, NewLv) ->
	PetHunRec#p_pet_hun{att_hun_exp = NewExp, att_hun_lv = NewLv};
set_hun_new_exp_and_lv(PetHunRec, ?HUN_POS_DEF, NewExp, NewLv) ->
	PetHunRec#p_pet_hun{def_hun_exp = NewExp, def_hun_lv = NewLv};
set_hun_new_exp_and_lv(PetHunRec, ?HUN_POS_HP, NewExp, NewLv) ->
	PetHunRec#p_pet_hun{hp_hun_exp = NewExp, hp_hun_lv = NewLv}.
%% =========================== local functions =========================
