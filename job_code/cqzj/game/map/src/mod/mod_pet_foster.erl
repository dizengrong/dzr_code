%% Author: dizengrong
%% Created: 2012-11-12
%% @doc: 这里实现的是t6项目中宠物培养模块

-module (mod_pet_foster).

-include("mgeem.hrl").

-compile(export_all).

-export([handle/6]).

-define(UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, Method, Msg)).

-define(ERR_VIP_NOT_ENOUGH, "VIP等级不足，不能使用此培养类型").
-define(ERR_ALL_ATTR_IS_FULL, "您所有的属性值已到达培养上限了，无需培养").


-define(FOSTER_TYPE_NORMAL, 	1). %% 普通培养
-define(FOSTER_TYPE_NORMAL2, 	2). %% 加强培养
-define(FOSTER_TYPE_ADVANCED, 	3). %% 高级培养
-define(FOSTER_TYPE_BEST, 		4). %% 白金培养
% -define(FOSTER_TYPE_BEST2, 		5). %% 至尊培养

-define(ATTR_ID_STR, 				1). 		%% 力量属性
-define(ATTR_ID_INT2, 				2). 		%% 智力属性
-define(ATTR_ID_CON, 				3). 		%% 体质属性
-define(ATTR_ID_DEX, 				4). 		%% 敏捷属性
-define(ATTR_ID_MEN, 				5). 		%% 精神属性

%% 处理来自客户端的请求
handle(_Unique, Method, DataIn, RoleID, _PID, _Line) ->
	case Method of
		?PET_REFRESH_FOSTER ->
			req_refresh_foster(RoleID, DataIn);
		?PET_SAVE_FOSTER ->
			case DataIn#m_pet_save_foster_tos.op_type of
				1 -> 
					req_save_foster(RoleID, DataIn);
				2 ->
					req_cancel_foster(RoleID, DataIn)
			end;
		?PET_FOSTER_SHOW ->
			req_foster_show(RoleID, DataIn)
	end.

req_foster_show(RoleID, DataIn) ->
	PetId        = DataIn#m_pet_foster_show_tos.pet_id,
	PetInfoRec   = mod_map_pet:get_pet_info(RoleID, PetId),
	send_foster_show_to_client(RoleID, PetInfoRec).

send_foster_show_to_client(RoleID, PetInfoRec) ->
	PetId      = PetInfoRec#p_pet.pet_id,
	Period     = PetInfoRec#p_pet.period,
	VipLv      = mod_vip:get_role_vip_level(RoleID),
	AttrLimits = get_foster_limits(Period, VipLv),

	ShowData  = get_foster_show_data(PetInfoRec#p_pet.category_type, AttrLimits, PetInfoRec#p_pet.foster),
	MoneyData = get_foster_money_data(VipLv, Period),
	Msg = #m_pet_foster_show_toc{
		pet_id     = PetId,
		show_data  = ShowData,
		money_data = MoneyData
	},
	?UNICAST(RoleID, ?PET_FOSTER_SHOW, Msg).

get_foster_show_data(CategoryType, AttrLimits, FosterAttrRec) ->
	get_foster_show_data(CategoryType, AttrLimits, FosterAttrRec, []).

get_foster_show_data(_CategoryType, [], _FosterAttrRec, ShowData) -> ShowData;
get_foster_show_data(CategoryType, [{AttrId, MaxValue} | Rest], FosterAttrRec, ShowData) ->
	if
		AttrId == ?ATTR_ID_INT2 andalso (CategoryType == 1 orelse CategoryType == 2) ->
			get_foster_show_data(CategoryType, Rest, FosterAttrRec, ShowData);
		AttrId == ?ATTR_ID_STR andalso (CategoryType == 3 orelse CategoryType == 4) ->
			get_foster_show_data(CategoryType, Rest, FosterAttrRec, ShowData);
		true ->
			Data = #p_pet_foster_data{
				type = AttrId, 
				cur_value = get_foster_value(AttrId, FosterAttrRec),
				max_value = MaxValue
			},
			ShowData1 = [Data | ShowData],
			get_foster_show_data(CategoryType, Rest, FosterAttrRec, ShowData1)
	end.

get_foster_money_data(VipLv, Period) ->
	AllGoldFosterType = [?FOSTER_TYPE_NORMAL2, ?FOSTER_TYPE_ADVANCED,
						 ?FOSTER_TYPE_BEST],
	Fun = fun(FosterType, Acc) ->
		Gold = cfg_pet_foster:get_cost_by_gold(FosterType),
		VipLimit = cfg_pet_foster:get_vip_require(FosterType),
		case VipLv >= VipLimit of
			true -> %% 客户端要求那培养类型从低到高的发送
				Acc ++ [#p_grow_money{type = FosterType, value = Gold}];
			false ->
				Acc
		end
	end,
	SilverCost = cfg_pet_foster:get_cost_by_silver(Period),
	Acc0 = [#p_grow_money{type = ?FOSTER_TYPE_NORMAL, value = SilverCost}],
	lists:foldl(Fun, Acc0, AllGoldFosterType).

get_foster_value(?ATTR_ID_STR, FosterAttrRec) -> FosterAttrRec#p_foster_attr.str;
get_foster_value(?ATTR_ID_INT2, FosterAttrRec) -> FosterAttrRec#p_foster_attr.int2;
get_foster_value(?ATTR_ID_CON, FosterAttrRec) -> FosterAttrRec#p_foster_attr.con;
get_foster_value(?ATTR_ID_DEX, FosterAttrRec) -> FosterAttrRec#p_foster_attr.dex;
get_foster_value(?ATTR_ID_MEN, FosterAttrRec) -> FosterAttrRec#p_foster_attr.men.

req_refresh_foster(RoleID, DataIn) ->
	PetId = DataIn#m_pet_refresh_foster_tos.pet_id,
	FosterType = DataIn#m_pet_refresh_foster_tos.foster_type,

	Ret = case refresh_foster_check(RoleID, PetId, FosterType) of
		{error, Reason} ->
			{error, Reason};
		ok ->
			clear_tmp_foster(RoleID, PetId),
			PetInfoRec = mod_map_pet:get_pet_info(RoleID, PetId),
			case FosterType of
				?FOSTER_TYPE_NORMAL ->
					refresh_foster_by_silver(RoleID, PetInfoRec, FosterType);
				_ ->
					refresh_foster_by_gold(RoleID, PetInfoRec, FosterType)
			end
	end,
	case Ret of
		{error, Reason1} ->
			common_misc:send_common_error(RoleID, 0, Reason1);
		{ok, FosterAttrRec} ->
			set_tmp_foster(RoleID, PetId, FosterAttrRec),
			Msg = #m_pet_refresh_foster_toc{
				pet_id        = PetId,
				foster_result = FosterAttrRec
			},
			?UNICAST(RoleID, ?PET_REFRESH_FOSTER, Msg),
			req_save_foster(RoleID, #m_pet_save_foster_tos{pet_id = PetId, op_type = 1})
	end.

%% 使用银币培养
refresh_foster_by_silver(RoleID, PetInfoRec, FosterType) ->
	Period  = PetInfoRec#p_pet.period,
	Cost    = cfg_pet_foster:get_cost_by_silver(Period),
	LogType = ?CONSUME_TYPE_SILVER_PET_FOSTER_COST,
	case common_bag2:use_money(RoleID, silver_any, Cost, LogType) of
		{error, Reason} ->
			{error, Reason};
		true ->
			do_refresh_foster(RoleID, PetInfoRec, FosterType)
	end.

refresh_foster_by_gold(RoleID, PetInfoRec, FosterType) ->
	Cost = cfg_pet_foster:get_cost_by_gold(FosterType),
	LogType = ?CONSUME_TYPE_GOLD_PET_FOSTER_COST,
	case common_bag2:use_money(RoleID, gold_unbind, Cost, LogType) of
		{error, Reason} ->
			{error, Reason};
		true ->
			do_refresh_foster(RoleID, PetInfoRec, FosterType)
	end.

get_foster_limits(Period, VipLv) ->
	case VipLv > 0 of 
		true  -> cfg_pet_foster:get_vip_limit(VipLv);
		false -> cfg_pet_foster:get_period_limit(Period)
	end.

refresh_foster_check(RoleID, PetId, FosterType) ->
	VipLv        = mod_vip:get_role_vip_level(RoleID),
	VipRequire = cfg_pet_foster:get_vip_require(FosterType),
	HasPet = mod_map_pet:check_role_has_pet(RoleID, PetId),
	if
		HasPet == error ->
			{error, ?_LANG_PET_NOT_EXIST};
		VipLv < VipRequire ->
			{error, ?ERR_VIP_NOT_ENOUGH};
		true ->
			{ok, PetInfoRec} = HasPet,
			OldFosterAttrRec = PetInfoRec#p_pet.foster,
			Period           = PetInfoRec#p_pet.period,
			AttrLimits       = get_foster_limits(Period, VipLv),
			Str              = OldFosterAttrRec#p_foster_attr.str,
			Int2             = OldFosterAttrRec#p_foster_attr.int2,
			Con              = OldFosterAttrRec#p_foster_attr.con,
			Dex              = OldFosterAttrRec#p_foster_attr.dex,
			Men              = OldFosterAttrRec#p_foster_attr.men,
			AttrList         = [{?ATTR_ID_STR, Str}, {?ATTR_ID_INT2, Int2}, 
								{?ATTR_ID_CON, Con}, {?ATTR_ID_DEX, Dex}, 
								{?ATTR_ID_MEN, Men}],
			Fun = fun({AttrId, OldAttr}, IsAllFull) ->
				{_, Max}    = lists:keyfind(AttrId, 1, AttrLimits),
				((OldAttr >= Max) andalso IsAllFull)
			end,
			case lists:foldl(Fun, true, AttrList) of
				true -> %% 所有的属性都已经满啦
					{error, ?ERR_ALL_ATTR_IS_FULL};
				false ->
					case Period < 5 of
						true -> {error, "宠物要达到5阶才开启培养功能"};
						false -> ok
					end
			end
	end.

do_refresh_foster(RoleID, PetInfoRec, FosterType) ->
	OldFosterAttrRec = PetInfoRec#p_pet.foster,
	Str              = OldFosterAttrRec#p_foster_attr.str,
	Int2             = OldFosterAttrRec#p_foster_attr.int2,
	Con              = OldFosterAttrRec#p_foster_attr.con,
	Dex              = OldFosterAttrRec#p_foster_attr.dex,
	Men              = OldFosterAttrRec#p_foster_attr.men,
	case PetInfoRec#p_pet.category_type == 1 orelse 
		 PetInfoRec#p_pet.category_type == 2 of
		true -> %% 物攻型，无智力
			AttrList = [{?ATTR_ID_STR, Str}, {?ATTR_ID_CON, Con}, {?ATTR_ID_DEX, Dex}, {?ATTR_ID_MEN, Men}];
		false -> %% 魔攻型，无力量
			AttrList = [{?ATTR_ID_INT2, Int2}, {?ATTR_ID_CON, Con}, {?ATTR_ID_DEX, Dex}, {?ATTR_ID_MEN, Men}]
	end,
	
	VipLv            = mod_vip:get_role_vip_level(RoleID),
	Period           = PetInfoRec#p_pet.period,
	AttrLimits       = get_foster_limits(Period, VipLv),

	Fun = fun(_, {FosterAttrRec, LeftAttrList})->
		{AttrId, OldAttr} = attr_change_random(LeftAttrList),
		%% NewChangeAttr是变动的值
		NewChangeAttr  = do_foster_single_attr({AttrId, OldAttr}, AttrLimits, FosterType),
		LeftAttrList1  = lists:keydelete(AttrId, 1, LeftAttrList),
		FosterAttrRec1 = erlang:setelement(attr_id_2_foster_attr_field(AttrId), FosterAttrRec, NewChangeAttr),
		{FosterAttrRec1, LeftAttrList1}
	end,
	HowmanyChanged = cfg_pet_foster:foster_change(FosterType),
	{FosterAttrRec2, _} = lists:foldl(Fun, {#p_foster_attr{_ = 0}, AttrList}, lists:seq(1, HowmanyChanged)),
	{ok, FosterAttrRec2}.

attr_id_2_foster_attr_field(?ATTR_ID_STR) -> #p_foster_attr.str;
attr_id_2_foster_attr_field(?ATTR_ID_INT2) -> #p_foster_attr.int2;
attr_id_2_foster_attr_field(?ATTR_ID_CON) -> #p_foster_attr.con;
attr_id_2_foster_attr_field(?ATTR_ID_DEX) -> #p_foster_attr.dex;
attr_id_2_foster_attr_field(?ATTR_ID_MEN) -> #p_foster_attr.men.

%% 属性是否改变的随机，改变返回true，否则返回false
attr_change_random(LeftAttrList) ->
	Choose = common_tool:random(1, length(LeftAttrList)),
	lists:nth(Choose, LeftAttrList).

%% 按概率算出差值
do_foster_single_attr({AttrId, OldAttr}, AttrLimits, FosterType) ->
	Weights       = cfg_pet_foster:foster_attr_val(FosterType),
	{FloatVal, _} = common_tool:random_from_tuple_weights(Weights, 2),
	{_, Max}      = lists:keyfind(AttrId, 1, AttrLimits),
	NewAttr = OldAttr + FloatVal,
	if
		NewAttr > Max ->
			NewAttr1 = Max;
		true ->
			NewAttr1 = NewAttr
	end,
	NewAttr1 - OldAttr.

%% 保存培养的属性
req_save_foster(RoleID, DataIn) -> 
	PetId = DataIn#m_pet_save_foster_tos.pet_id,
	case get_tmp_foster(RoleID, PetId) of
		undefined ->
			?ERROR_MSG("player ~w not refresh pet ~w foster?", [RoleID, PetId]);
		FosterAttrRec -> 
			PetInfoRec = mod_map_pet:get_pet_info(RoleID, PetId),
			case PetInfoRec#p_pet.category_type == 1 orelse 
				 PetInfoRec#p_pet.category_type == 2 of
				true -> %% 物攻型，无智力
					FosterAttrRec1 = FosterAttrRec#p_foster_attr{int2 = 0};
				false -> %% 魔攻型，无力量
					FosterAttrRec1 = FosterAttrRec#p_foster_attr{str = 0}
			end,
			PetInfoRec1 = PetInfoRec#p_pet{
				foster = foster_attr_adder(FosterAttrRec1, PetInfoRec#p_pet.foster)
			},
			mod_map_pet:set_pet_info(PetId, PetInfoRec1),
			mod_map_pet:calc_pet_attr_toc(RoleID, PetInfoRec1),
			%% fixme:服务端不想一培养就去做可能发生的宠物给角色属性加成的改变
			% mod_map_pet:check_if_should_update_role_attr(RoleID, PetId),
			clear_tmp_foster(RoleID, PetId),
			Msg = #m_pet_save_foster_toc{
				pet_id   = PetId,
				op_type  = 1,
				err_code = 0
			},
			?UNICAST(RoleID, ?PET_SAVE_FOSTER, Msg),
			send_foster_show_to_client(RoleID, PetInfoRec1)
	end.

req_cancel_foster(RoleID, DataIn) ->
	PetId = DataIn#m_pet_save_foster_tos.pet_id,
	clear_tmp_foster(RoleID, PetId),
	Msg = #m_pet_save_foster_toc{
		pet_id   = PetId,
		op_type  = 2,
		err_code = 0
	},
	?UNICAST(RoleID, ?PET_SAVE_FOSTER, Msg).

foster_attr_adder(R1, R2) ->
	#p_foster_attr{
		str  = erlang:max(0, (R1#p_foster_attr.str + R2#p_foster_attr.str)),
		int2 = erlang:max(0, (R1#p_foster_attr.int2 + R2#p_foster_attr.int2)),
		con  = erlang:max(0, (R1#p_foster_attr.con + R2#p_foster_attr.con)),
		dex  = erlang:max(0, (R1#p_foster_attr.dex + R2#p_foster_attr.dex)),
		men  = erlang:max(0, (R1#p_foster_attr.men + R2#p_foster_attr.men))
	}.

%% ===============================================================
%% 将刷新的培养数据放入进程字典中保存起来
set_tmp_foster(RoleID, PetId, FosterAttrRec) ->
	erlang:put({pet_foster_tmp, RoleID, PetId}, FosterAttrRec).

get_tmp_foster(RoleID, PetId) ->
	erlang:get({pet_foster_tmp, RoleID, PetId}).

clear_tmp_foster(RoleID, PetId) ->
	erlang:erase({pet_foster_tmp, RoleID, PetId}).
