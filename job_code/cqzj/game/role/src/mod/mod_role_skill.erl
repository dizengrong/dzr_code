%%% -------------------------------------------------------------------
%%% Author  : xierongfeng
%%% Description : 玩家技能学习模块
%%%
%%% Created : 2013-5-21
%%% -------------------------------------------------------------------
-module (mod_role_skill).

-include("mgeer.hrl").

-define(_common_error,			?DEFAULT_UNIQUE,	?COMMON,	?COMMON_ERROR,			#m_common_error_toc).%}
-define(_skill_learn,			?DEFAULT_UNIQUE,	?SKILL,		?SKILL_LEARN,			#m_skill_learn_toc).%}
-define(_skill_getskills,		?DEFAULT_UNIQUE,	?SKILL, 	?SKILL_GETSKILLS,		#m_skill_getskills_toc).%}
-define(_skill_use_time,		?DEFAULT_UNIQUE,	?SKILL, 	?SKILL_USE_TIME,		#m_skill_use_time_toc).%}
-define(_skill_one_key_learn,	?DEFAULT_UNIQUE,	?SKILL,		?SKILL_ONE_KEY_LEARN,	#m_skill_one_key_learn_toc).%}
-define(_skill_imme_buy,		?DEFAULT_UNIQUE,	?SKILL, 	?SKILL_IMME_BUY, 		#m_skill_imme_buy_toc).%}
-define(_skill_shape_tiyan,		?DEFAULT_UNIQUE,	?SKILL, 	?SKILL_SHAPE_TIYAN, 	#m_skill_shape_tiyan_toc).%}
-define(_attr_change,			?DEFAULT_UNIQUE,	?ROLE2, 	?ROLE2_ATTR_CHANGE, 	#m_role2_attr_change_toc).%}
-define(_goods_update,			?DEFAULT_UNIQUE,	?GOODS,		?GOODS_UPDATE,			#m_goods_update_toc).%}

-export([
	handle/1,
	hook_role_online/2, 
	init_role_skill_list/2, 
	get_role_skill_list/1, 
	get_role_nuqi_skill_info/1,
	get_skill_level_info2/2, 
	check_skill_precondition/5, 
	check_role_silver/5,
	get_skill_base_info/1,
	is_nuqi_skill/1,
	get_nuqi_skill_shape_num/1,
	get_role_nuqi_skill_info_persistent/1
	]).

hook_role_online(RoleID, PID) ->
    handle({?DEFAULT_UNIQUE, ?SKILL, ?SKILL_GETSKILLS, undefined, RoleID, PID, 0}).

handle({_Unique, ?SKILL, ?SKILL_LEARN, DataIn, RoleID, PID, _Line}) ->
	init_temp_bag(),
	#m_skill_learn_tos{skill_id = SkillID, auto_buy = _AutoBuy} = DataIn,
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	OldSkillList   = get_role_skill_list(RoleID), 

	OldSkillLevel = get_role_skill_level(SkillID, OldSkillList),
	hook_nuqi_skill_event(RoleID, SkillID, OldSkillLevel),
    case check_upgrade_skill(RoleAttr, OldSkillList, SkillID) of
    	{error, Reason} ->
    		common_misc:unicast2(PID, ?_common_error{error_str = Reason});
    	{ok, SkillLevelInfo} ->
    		{ok, NewRoleAttr, NewSkillList} = 
    			do_upgrade_skill(RoleAttr, OldSkillList, SkillLevelInfo),

			SkillLevel = SkillLevelInfo#p_skill_level.level,
			NewSkillID = SkillLevelInfo#p_skill_level.skill_id,
			TempGoodsList = get_temp_bag(),
			pay_and_update_skills(RoleID, RoleAttr, NewRoleAttr,  NewSkillList),
			?TRY_CATCH(do_normal_skill_action_log(RoleAttr,NewSkillID,SkillLevel,OldSkillList,TempGoodsList)),
			LearnSkill = #p_role_skill{skill_id = NewSkillID, cur_level = SkillLevel},
			common_misc:unicast2(PID, ?_skill_learn{skill = LearnSkill}),
			upgrade_skill_success(RoleID, OldSkillList, [LearnSkill]),
			if
				SkillID =/= NewSkillID -> mod_nuqi_huoling:do_huoling_info(RoleID);
				true -> ignore
			end,
			hook_nuqi_skill_event(RoleID, NewSkillID, SkillLevel)
    end;

handle({_Unique, ?SKILL, ?SKILL_ONE_KEY_LEARN, DataIn, RoleID, PID, _Line}) ->
	init_temp_bag(),
	#m_skill_one_key_learn_tos{learn_type = LearnType} = DataIn,
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	OldSkillList   = get_role_skill_list(RoleID),
  	GroupSkills    = group_skills(RoleAttr#p_role_attr.category, LearnType, OldSkillList),
    {ok, NewRoleAttr, NewSkillList,AccUpgradeSkillList} = do_upgrade_skills(RoleAttr, OldSkillList, GroupSkills,[]),
	
	UpdateSkills = lists:foldl(fun
		(SkillID, Acc) ->
			NewSkill = lists:keyfind(SkillID, #r_role_skill_info.skill_id, NewSkillList),
			OldSkill = lists:keyfind(SkillID, #r_role_skill_info.skill_id, OldSkillList),
			case NewSkill =/= OldSkill of
				true ->
					SkillLevel = NewSkill#r_role_skill_info.cur_level,
					[#p_role_skill{skill_id = SkillID, cur_level = SkillLevel}|Acc];
				_ ->
					Acc
			end
	end, [], GroupSkills),
	case UpdateSkills of
		[] ->
			common_misc:unicast2(PID, ?_common_error{error_str = <<"当前没有可以升级的技能">>});
		_ ->
			TempGoodsList = get_temp_bag(),
			pay_and_update_skills(RoleID, RoleAttr, NewRoleAttr, NewSkillList),
			?TRY_CATCH(do_skill_action_log(RoleAttr,AccUpgradeSkillList,OldSkillList,NewSkillList,TempGoodsList)),
			common_misc:unicast2(PID, ?_skill_one_key_learn{update_skills = UpdateSkills}),
			upgrade_skill_success(RoleID, OldSkillList, UpdateSkills)
	end;

handle({_Unique, ?SKILL, ?SKILL_IMME_BUY, DataIn, RoleID, PID, _Line}) ->
	SkillID        = DataIn#m_skill_imme_buy_tos.dest_skill_id,
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	OldSkillList   = get_role_skill_list(RoleID),
	case check_buy_skill(RoleAttr, OldSkillList, SkillID) of
    	{error, Reason} ->
    		common_misc:unicast2(PID, ?_common_error{error_str = Reason});
    	{ok, NeedGold, SkillLevelInfo} ->
    		case do_buy_skill(RoleID, NeedGold, OldSkillList, SkillLevelInfo) of
    			{ok, SkillLevel} ->
    				BuySkill = #p_role_skill{skill_id = SkillID, cur_level = SkillLevel},
					common_misc:unicast2(PID, ?_skill_imme_buy{skill = BuySkill}),
					upgrade_skill_success(RoleID, OldSkillList, [BuySkill]);
				{error, Reason} ->
					common_misc:unicast2(PID, ?_common_error{error_str = Reason})
			end
    end;

handle({_Unique, ?SKILL, ?SKILL_GETSKILLS, _DataIn, RoleID, PID, _Line}) ->
    SkillList = lists:foldr(fun
    	(#r_role_skill_info{skill_id = SkillID, cur_level = CurLevel}, Acc) ->
			[ #p_role_skill{skill_id = SkillID, cur_level = CurLevel}|Acc]
	end, [], get_role_skill_list(RoleID)),
    common_misc:unicast2(PID, ?_skill_getskills{skills = SkillList});

handle({_Unique, ?SKILL, ?SKILL_FULU_OP, DataIn, RoleID, _PID, _Line}) ->
	mod_fulu:handle({?SKILL, ?SKILL_FULU_OP, DataIn, RoleID});

handle({_Unique, ?SKILL, ?SKILL_FULU_INFO, DataIn, RoleID, _PID, _Line}) ->
	mod_fulu:handle({?SKILL, ?SKILL_FULU_INFO, DataIn, RoleID});

handle(_) -> ignore.

do_skill_action_log(RoleAttr,AccUpgradeSkillList,OldSkillList,NewSkillList,TempGoodsList) ->
	FirstSkillID = lists:last( AccUpgradeSkillList),
	FirstSkillInfo = get_role_skill_info(FirstSkillID,OldSkillList),
	LastSkillInfoID = lists:nth(1, AccUpgradeSkillList),
	LastSkillInfo = get_role_skill_info(LastSkillInfoID,NewSkillList),
	ToJsonList = lists:foldl(fun({GoodsType,GoodsNum,_},AccIn) -> 
									 RemainNum = get_temp_goods_num(RoleAttr#p_role_attr.role_id,GoodsType),
									 [[GoodsType,GoodsNum - RemainNum]|AccIn]
							 end, [], TempGoodsList),
	LogRecord = #r_skill_action_log{
					role_id = RoleAttr#p_role_attr.role_id,
					role_name = RoleAttr#p_role_attr.role_name,		
					old_skill = FirstSkillInfo#r_role_skill_info.skill_id,
					old_level = FirstSkillInfo#r_role_skill_info.cur_level,
					op_type = 2,
					cur_level=LastSkillInfo#r_role_skill_info.cur_level,
					cur_skill=LastSkillInfo#r_role_skill_info.skill_id,
					item_info=common_json2:to_json(ToJsonList),
					time = common_tool:now()
	},
	
	common_general_log_server:log_skill_action(LogRecord),
	ok.
do_normal_skill_action_log(RoleAttr,SkillID,SkillLevel,OldSkillList,TempGoodsList) ->
	OldSkillLevel = get_role_skill_level(SkillID, OldSkillList),
	LogRecord = #r_skill_action_log{
					role_id = RoleAttr#p_role_attr.role_id,
					role_name = RoleAttr#p_role_attr.role_name,		
					old_skill = SkillID,
					old_level = OldSkillLevel,
					op_type = 1,
					time = common_tool:now()
	},
	ToJsonList = lists:foldl(fun({GoodsType,GoodsNum,_},AccIn) -> 
									 RemainNum = get_temp_goods_num(RoleAttr#p_role_attr.role_id,GoodsType),
									 [[GoodsType,GoodsNum - RemainNum]|AccIn]
							 end, [], TempGoodsList),
	NewLogRecord = 
		LogRecord#r_skill_action_log{
					cur_level = SkillLevel,
					cur_skill = SkillID,
					item_info = common_json2:to_json(ToJsonList)
	},
	common_general_log_server:log_skill_action(NewLogRecord).

check_upgrade_skill(RoleAttr, SkillList, SkillID) ->
	SkillLevel     = get_role_skill_level(SkillID, SkillList),
	SkillBaseInfo  = get_skill_base_info(SkillID),
	SkillLevelInfo = get_skill_level_info(SkillID, SkillLevel + 1),
	CheckList = [
		fun check_skill_max_level/5,
		fun check_skill_precondition/5,
		fun check_role_category/5, 
		fun check_role_jingjie/5,
		fun check_role_level/5,
		fun check_role_silver/5, 
		fun check_role_exp/5,
		fun check_need_item/5,
		fun check_need_nuqi_style/5
	],
	Result = lists:foldl(fun
		(_Check, {error, Msg}) ->
			{error, Msg};
		(Check, _) ->
			Check(RoleAttr, SkillLevel, SkillBaseInfo, SkillLevelInfo, SkillList)
	end, true, CheckList),
	case Result of
		{error, Msg} -> 
			{error, Msg};
		_Others ->
			{ok, SkillLevelInfo}
	end.

check_buy_skill(RoleAttr, SkillList, SkillID) ->
	SkillLevel     = get_role_skill_level(SkillID, SkillList),
	SkillBaseInfo  = get_skill_base_info(SkillID),
	SkillLevelInfo = get_skill_level_info(SkillID, SkillLevel + 1),
	CheckList = [
		fun check_role_category/5, 
		fun check_buy_skill_level/5,
		fun check_buy_skill_gold/5
	],
	Result = lists:foldl(fun
		(_Check, {error, Msg}) ->
			{error, Msg};
		(Check, _) ->
			Check(RoleAttr, SkillLevel, SkillBaseInfo, SkillLevelInfo, SkillList)
	end, true, CheckList),
	case Result of
		{error, Msg} -> 
			{error, Msg};
		_Others ->
			NeedGold = cfg_skill_life:get_imme_buy_gold(SkillID, SkillLevel, SkillID),
			{ok, NeedGold, SkillLevelInfo}
	end.

check_skill_max_level(_RoleAttr, SkillLevel, SkillBaseInfo, _SkillLevelInfo, _SkillList) ->
	SkillID = SkillBaseInfo#p_skill.id,
	case is_nuqi_skill(SkillID) andalso is_nuqi_skill(SkillID + 1) of
		true  -> true;
		false ->
			SkillLevel < SkillBaseInfo#p_skill.max_level 
			orelse {error, ?_LANG_SKILL_LEVEL_IS_MAXLEVEL}
	end.

check_skill_precondition(_RoleAttr, _SkillLevel, _SkillBaseInfo, SkillLevelInfo, SkillList) ->
	Satisfy = lists:all(fun
		(#p_skill_precondition{skill_id = SkillID1, skill_level = SkillLevel1}) ->
			case lists:keyfind(SkillID1, #r_role_skill_info.skill_id, SkillList) of
				#r_role_skill_info{cur_level = SkillLevel2} ->
					SkillLevel2 >= SkillLevel1;
				_ ->
					false
			end
	end, SkillLevelInfo#p_skill_level.pre_condition),
	Satisfy orelse {error, ?_LANG_SKILL_PRE_SKILL_LEVEL_NOT_ENOUGH}.

check_role_category(RoleAttr, _SkillLevel, SkillBaseInfo, _SkillLevelInfo, _SkillList) ->
 	RoleAttr#p_role_attr.category == SkillBaseInfo#p_skill.category 
 	orelse {error, <<"非法操作">>}.

check_role_jingjie(RoleAttr, _SkillLevel, _SkillBaseInfo, SkillLevelInfo, _SkillList) ->
 	RoleAttr#p_role_attr.jingjie >= SkillLevelInfo#p_skill_level.premise_role_jingjie 
 	orelse {error, ?_LANG_SKILL_ROLE_JINGJIE_NOT_ENOUGH}.

 check_role_level(RoleAttr, _SkillLevel, _SkillBaseInfo, SkillLevelInfo, _SkillList) ->
 	RoleAttr#p_role_attr.level >= SkillLevelInfo#p_skill_level.premise_role_level 
 	orelse {error, ?_LANG_SKILL_ROLE_LEVEL_NOT_ENOUGH}.

check_role_silver(RoleAttr, _SkillLevel, _SkillBaseInfo, SkillLevelInfo, _SkillList) ->
 	RoleAttr#p_role_attr.silver_bind >= SkillLevelInfo#p_skill_level.need_silver 
 	orelse {error, ?_LANG_SKILL_REST_SILVER_NOT_ENOUGH}.
 
check_role_exp(RoleAttr, _SkillLevel, _SkillBaseInfo, SkillLevelInfo, _SkillList) ->
	RoleAttr#p_role_attr.exp >= SkillLevelInfo#p_skill_level.consume_exp 
	orelse {error, ?_LANG_SKILL_REST_EXP_NOT_ENOUGH}.

check_need_item(RoleAttr, _SkillLevel, _SkillBaseInfo, SkillLevelInfo, _SkillList) ->
	RoleID   = RoleAttr#p_role_attr.role_id,
	NeedItem = SkillLevelInfo#p_skill_level.need_item,
	NeedNum  = SkillLevelInfo#p_skill_level.need_num,
	get_temp_goods_num(RoleID, NeedItem) >= NeedNum orelse {error, <<"道具不足">>}.

check_need_nuqi_style(RoleAttr, SkillLevel, SkillBaseInfo, _SkillLevelInfo, _SkillList) ->
	RoleID 			= RoleAttr#p_role_attr.role_id,
	NuqiSkillRec 	= get_role_nuqi_skill_info(RoleID),
	SKillID1      	= NuqiSkillRec #r_role_skill_info.skill_id,
	ShapeNum 	 	= get_nuqi_skill_shape_num(SKillID1),
	SkillID2 		= SkillBaseInfo#p_skill.id,
	RuleList		= cfg_skill_life:get_limit_by_nuqi(SkillID2),
	if ShapeNum > 0 ->
			{_Nuqi,Limit}   = lists:keyfind(ShapeNum, 1, RuleList),
			Limit >= SkillLevel orelse {error, <<"怒气技形态未达标">>};
		true ->
			{error, <<"怒气技形态未达标">>}
	end.
 
check_buy_skill_level(_RoleAttr, SkillLevel, SkillBaseInfo, _SkillLevelInfo, SkillList) ->
	SkillID = SkillBaseInfo#p_skill.id,
	if
		SkillLevel > 0 -> 
			{error, <<"已经学习了该技能">>};
		true ->
			case is_nuqi_skill(SkillID) andalso is_nuqi_skill(SkillID + 1) of
				true ->
					SkillIDIndex = #r_role_skill_info.skill_id,
					(lists:keymember(SkillID + 1, SkillIDIndex, SkillList) orelse
					 lists:keymember(SkillID + 2, SkillIDIndex, SkillList)) 
					andalso {error, <<"已经学习了更高形态的技能">>};
				_ ->
					{error, <<"不能购买该技能">>}
			end
	end.

check_buy_skill_gold(RoleAttr, SkillLevel, SkillBaseInfo, _SkillLevelInfo, _SkillList) ->
	SkillID  = SkillBaseInfo#p_skill.id,
	NeedGold = cfg_skill_life:get_imme_buy_gold(SkillID, SkillLevel, SkillID),
	RoleAttr#p_role_attr.gold >= NeedGold orelse {error, <<"元宝不足">>}.

do_upgrade_skill(OldRoleAttr, OldSkillList, SkillLevelInfo) ->
	#p_skill_level{
		skill_id    = SkillID,
		level       = SkillLevel, 
		category    = Category,
		need_item   = NeedItem,
		need_num    = NeedNum,
		need_silver = NeedSilver,
		consume_exp = NeedExp
	} = SkillLevelInfo,
	SkillInfo = #r_role_skill_info{
		skill_id  = SkillID,
		cur_level = SkillLevel,
		category  = Category
	},
	del_temp_goods_num(NeedItem, NeedNum),
	NewRoleAttr  = OldRoleAttr#p_role_attr{
		silver_bind = OldRoleAttr#p_role_attr.silver_bind - NeedSilver,
		exp         = OldRoleAttr#p_role_attr.exp         - NeedExp},
	NewSkillList = keystore(SkillID, OldSkillList, SkillInfo),
	{ok, NewRoleAttr, NewSkillList}.

do_buy_skill(RoleID, NeedGold, OldSkillList, SkillLevelInfo) ->
	#p_skill_level{
		skill_id    = SkillID,
		level       = SkillLevel, 
		category    = Category
	} = SkillLevelInfo,
	SkillInfo = #r_role_skill_info{
		skill_id  = SkillID, 
		cur_level = SkillLevel, 
		category  = Category
	},
	NewSkillList = keystore(SkillID, OldSkillList, SkillInfo),
	case common_bag2:use_money(RoleID, 
			gold_unbind, NeedGold, skill_imme_buy_log_type(SkillID)) of
		true -> 
			set_role_skill_list(RoleID, NewSkillList),
			{ok, SkillLevel};
		{error, Reason} -> 
			{error, Reason}
	end.

keystore(SkillID, OldSkillList, SkillInfo) ->
	SkillIDIndex  = #r_role_skill_info.skill_id,
	case is_nuqi_skill(SkillID) of
		true ->
			DelSkillID   = get_del_skill_id(SkillID, OldSkillList),
			NewSkillList = lists:keydelete(DelSkillID, SkillIDIndex, OldSkillList),
			lists:keystore(SkillID, SkillIDIndex, NewSkillList, SkillInfo);
		false ->
			lists:keystore(SkillID, SkillIDIndex, OldSkillList, SkillInfo)
	end.

do_upgrade_skills(RoleAttr, SkillList, [],AccUpgradeSkillList) -> 
	{ok, RoleAttr, SkillList,AccUpgradeSkillList};
do_upgrade_skills(OldRoleAttr, OldSkillList, [UpgradeSkillID|T],AccUpgradeSkillList) ->
	case check_upgrade_skill(OldRoleAttr, OldSkillList, UpgradeSkillID) of
		{ok, SkillLevelInfo} ->
			{ok, NewRoleAttr, NewSkillList} = 
				do_upgrade_skill(OldRoleAttr, OldSkillList, SkillLevelInfo),
			do_upgrade_skills(NewRoleAttr, NewSkillList, [UpgradeSkillID|T],[UpgradeSkillID|AccUpgradeSkillList]);
		_ ->
			do_upgrade_skills(OldRoleAttr, OldSkillList, T,AccUpgradeSkillList)
	end.

pay_and_update_skills(RoleID, OldRoleAttr, NewRoleAttr,  NewSkillList) ->
	common_transaction:t(fun
		() ->
			pay_items(RoleID, erase_temp_bag()),
			pay_silver_exp(RoleID, OldRoleAttr, NewRoleAttr),
			set_role_skill_list(RoleID, NewSkillList)	
	end).

init_role_skill_list(RoleID, SkillList) ->
    mod_role_tab:put(RoleID, {?role_skill, RoleID}, SkillList).

get_role_nuqi_skill_info(RoleID) ->
	SkillList = get_role_skill_list(RoleID),
	{true, NuqiSkillRec} = lists:foldl(fun(H, {Flag, SkillRec}) ->
		case Flag of
			true -> {Flag, SkillRec};
			false -> 
				{is_nuqi_skill(H#r_role_skill_info.skill_id), H}
		end
	end, {false, 0}, SkillList),
	NuqiSkillRec.

get_role_nuqi_skill_info_persistent(RoleID) ->
	% SkillList = get_role_skill_list(RoleID),
	SkillList = case get_role_skill_list(RoleID)  of
		[] -> 
			[#r_role_skill{skill_list = SL1}] =  db:dirty_read(db_role_skill, RoleID),
			SL1;
		SL2 -> SL2
	end,
	{true, NuqiSkillRec} = lists:foldl(fun(H, {Flag, SkillRec}) ->
		case Flag of
			true -> {Flag, SkillRec};
			false -> 
				{is_nuqi_skill(H#r_role_skill_info.skill_id), H}
		end
	end, {false, 0}, SkillList),
	NuqiSkillRec.

get_role_skill_list(RoleID) ->
    case mod_role_tab:get(RoleID, {?role_skill, RoleID}) of
        undefined -> [];
        SkillList -> SkillList
    end.

set_role_skill_list(RoleID, SkillList) ->
	mod_role_tab:put(RoleID, {?role_skill, RoleID}, SkillList).

get_role_skill_info(SkillID, SkillList) ->
    case lists:keyfind(SkillID, #r_role_skill_info.skill_id, SkillList) of
        SkillInfo when is_record(SkillInfo, r_role_skill_info) ->
            SkillInfo;
        _ ->
        	#p_skill{category = Category} = get_skill_base_info(SkillID),
            #r_role_skill_info{skill_id = SkillID, cur_level = 0, category = Category}
    end.

get_role_skill_level(SkillID, SkillList) ->
	(get_role_skill_info(SkillID, SkillList))#r_role_skill_info.cur_level.

get_skill_base_info(SkillID) ->
	[SkillBaseInfo] = common_config_dyn:find(skill, SkillID),
	SkillBaseInfo.

get_skill_level_info(SkillID, SkillLv) ->
	case is_nuqi_skill(SkillID) andalso is_nuqi_skill(SkillID + 1) of
		true ->
			#p_skill{max_level = MaxLevel} = get_skill_base_info(SkillID),
			case SkillLv > MaxLevel of
				true ->
					get_skill_level_info2(SkillID + 1, 1);
				_ ->
					get_skill_level_info2(SkillID, SkillLv)
			end;
		_ ->
			get_skill_level_info2(SkillID, SkillLv)
	end.

get_skill_level_info2(SkillID, SkillLv) when SkillLv > 0 ->
	case common_config_dyn:find(skill_level, SkillID) of
		[SkillLevelInfos] -> 
			lists:keyfind(SkillLv, #p_skill_level.level, SkillLevelInfos);
		_ -> 
			undefined
	end.

get_skill_buffs(SkillID, SkillLv) when SkillLv > 0 ->
	case get_skill_level_info2(SkillID, SkillLv) of
		#p_skill_level{buffs = Buffs} -> Buffs;
		_ -> []
	end;
get_skill_buffs(_, _) -> [].


init_temp_bag() ->
	put({?MODULE, temp_bag}, []).

erase_temp_bag() ->
	erase({?MODULE, temp_bag}).

get_temp_bag() ->
	case get({?MODULE, temp_bag}) of
		undefined -> [];
		TempBag   -> TempBag
	end.

set_temp_bag(TempBag) ->
	put({?MODULE, temp_bag}, TempBag).

get_temp_goods_num(RoleID, ItemType) ->
	TempBag = get_temp_bag(),
	case lists:keyfind(ItemType, 1, TempBag) of
		{ItemType, GoodsNum, UsedNum} ->
			GoodsNum - UsedNum;
		false ->
			{ok, GoodsNum} = mod_bag:get_goods_num_by_typeid([1,2,3], RoleID, ItemType),
			set_temp_bag([{ItemType, GoodsNum, 0}|TempBag]),
			GoodsNum
	end.

del_temp_goods_num(ItemType, ItemNum) ->
	OldTempBag = get_temp_bag(),
	{ItemType, GoodsNum, UsedNum} = lists:keyfind(ItemType, 1, OldTempBag),
	NewTempBag = lists:keyreplace(ItemType, 
		1, OldTempBag, {ItemType, GoodsNum, UsedNum + ItemNum}),
	set_temp_bag(NewTempBag).

pay_silver_exp(RoleID, OldRoleAttr, NewRoleAttr) ->
	UseSilver = OldRoleAttr#p_role_attr.silver_bind - NewRoleAttr#p_role_attr.silver_bind,
	UseExp    = OldRoleAttr#p_role_attr.exp         - NewRoleAttr#p_role_attr.exp,
	UseSilver > 0 andalso log_use_silver(RoleID, UseSilver),
	AttrChanges1 = if
		UseSilver > 0 ->
			[#p_role_attr_change{
				change_type = ?ROLE_SILVER_CHANGE, 
				new_value   = NewRoleAttr#p_role_attr.silver
			},
			#p_role_attr_change{
				change_type = ?ROLE_SILVER_BIND_CHANGE, 
				new_value   = NewRoleAttr#p_role_attr.silver_bind
			}];
		true ->
			[]
	end,
	AttrChanges2 = if
		UseExp > 0 ->
			[#p_role_attr_change{
				change_type = ?ROLE_EXP_CHANGE, 
				new_value   = NewRoleAttr#p_role_attr.exp
			}|AttrChanges1];
		true ->
			AttrChanges1
	end,
	if
		AttrChanges2 =/= [] ->
			common_misc:unicast({role, RoleID}, ?_attr_change{roleid = RoleID, changes = AttrChanges2}),
			mod_map_role:set_role_attr(RoleID, NewRoleAttr);
		true ->
			ignore
	end.

log_use_silver(RoleID, UseSilver) ->
	common_consume_logger:use_silver({RoleID, UseSilver, 0, ?CONSUME_TYPE_SILVER_UP_SKILL, ""}).

pay_items(RoleID, SkillItems) ->
	{UpdateGoods2, DeleteGoods2} = lists:foldl(fun
		({ItemType, _GoodsNum, UseNum}, {UpdateGoodsAcc, DeleteGoodsAcc}) ->
			{ok, UpdateGoods, DeleteGoods} = 
				mod_bag:decrease_goods_by_typeid(RoleID, [1,2,3], ItemType, UseNum),
			log_use_items(RoleID, ItemType, UseNum),
			UpdateGoodsAcc2 = lists:foldl(fun
				(Goods, UpdateGoodsAcc1) ->
					case lists:keymember(Goods#p_goods.id, #p_goods.id, UpdateGoods) 
							orelse lists:keymember(Goods#p_goods.id, #p_goods.id, DeleteGoods) of
						true ->
							UpdateGoodsAcc1;
						_ ->
							[Goods|UpdateGoodsAcc1]
					end
			end, [], UpdateGoodsAcc),
			{UpdateGoods++UpdateGoodsAcc2, DeleteGoods++DeleteGoodsAcc}
	end, {[], []}, SkillItems),
	UpdateGoods3 = lists:foldl(fun
		(Goods, UpdateGoodsAcc) ->
			[Goods#p_goods{current_num = 0}|UpdateGoodsAcc]
	end, UpdateGoods2, DeleteGoods2),
	common_misc:unicast({role, RoleID}, ?_goods_update{goods = UpdateGoods3}).

log_use_items(RoleID, ItemType, UseNum) ->
	common_item_logger:log(RoleID, ItemType, UseNum, undefined, ?LOG_ITEM_TYPE_LOST_SKILL_LEARN).

group_skills(Category, 1, _SkillList) ->
	case Category of
		1 ->
			[90100001, 90100002, 90100003, 90100004, 90100005, 90100006];
		3 ->
			[90200001, 90200002, 90200003, 90200004, 90200005, 90200006]
	end;
group_skills(Category, 2, SkillList) ->
	SkillIDIndex = #r_role_skill_info.skill_id,
	GroupSkills  = case Category of
		1 ->
			[91000001, 91000002, 91000003, 91000004];
		3 ->
			[92000001, 92000002, 92000003, 92000004]
	end,
	lists:foldl(fun
		(SkillID, []) ->
			case lists:keymember(SkillID, SkillIDIndex, SkillList) of
				true ->
					lists:seq(SkillID, lists:last(GroupSkills));
				_ ->
					[]
			end;
		(_SkillID, Acc) -> Acc
	end, [], GroupSkills).

upgrade_skill_success(RoleID, OldSkillList, UpgradeSkills) ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	{UpdateRoleBase, NewRoleBase} = lists:foldl(fun
		(#p_role_skill{skill_id = SkillID, cur_level = NewLevel}, {UpdateFlag, RoleBaseAcc}) ->
			SkillIDIndex = #r_role_skill_info.skill_id,
			OldLevel = case lists:keyfind(SkillID, SkillIDIndex, OldSkillList) of
				#r_role_skill_info{cur_level = OldLevel1} -> OldLevel1;
				_ -> 0
			end,
			DelSkillID = get_del_skill_id(SkillID, OldSkillList),
			hook_skill_learn:hook(
				{RoleID, DelSkillID, SkillID, NewLevel}, OldLevel =< 0 andalso NewLevel > 0),
			case get_skill_base_info(SkillID) of
				#p_skill{attack_type = ?ATTACK_TYPE_PASSIVE} ->
					OldBuffs = get_skill_buffs(SkillID, OldLevel),
					NewBuffs = get_skill_buffs(SkillID, NewLevel),
					{true, mod_role_buff:add_buff2(
						mod_role_buff:del_buff2(RoleBaseAcc, OldBuffs), NewBuffs)};
				_ ->
					{UpdateFlag, RoleBaseAcc}
			end
	end, {false, RoleBase}, UpgradeSkills),
	mod_role_event:notify(RoleID, {?ROLE_EVENT_SKILL_LV, UpgradeSkills}),
	UpdateRoleBase andalso mod_role_attr:reload_role_base(NewRoleBase).

get_del_skill_id(SkillID, SkillList) -> 
	get_del_nuqi_skill_id(SkillID, SkillList).

get_del_nuqi_skill_id(SkillID, SkillList) ->
	LowLvSkillID = SkillID - 1,
	is_nuqi_skill(SkillID) andalso is_nuqi_skill(LowLvSkillID) andalso
	case lists:keymember(LowLvSkillID, #r_role_skill_info.skill_id, SkillList) of
		true  -> LowLvSkillID;
		false ->
			get_del_nuqi_skill_id(LowLvSkillID, SkillList)
	end.

is_nuqi_skill(91000001) -> true;
is_nuqi_skill(91000002) -> true;
is_nuqi_skill(91000003) -> true;
is_nuqi_skill(91000004) -> true;
is_nuqi_skill(92000001) -> true;
is_nuqi_skill(92000002) -> true;
is_nuqi_skill(92000003) -> true;
is_nuqi_skill(92000004) -> true;
is_nuqi_skill(_)        -> false.

skill_imme_buy_log_type(DestSkillID) ->
	if 
		DestSkillID =:= 91000001 orelse DestSkillID =:= 92000001 ->
			?CONSUME_TYPE_GOLD_SKILL_IMME_BUY_SHAP1;
		DestSkillID =:= 91000002 orelse DestSkillID =:= 92000002 ->
			?CONSUME_TYPE_GOLD_SKILL_IMME_BUY_SHAP2;
		DestSkillID =:= 91000003 orelse DestSkillID =:= 92000003 ->
			?CONSUME_TYPE_GOLD_SKILL_IMME_BUY_SHAP3;
		true ->
			?CONSUME_TYPE_GOLD_SKILL_IMME_BUY_SHAP4
	end.

hook_nuqi_skill_event(RoleID, SkillID, SkillLevel) ->
	case is_nuqi_skill(SkillID) of
		true -> 
			hook_mission_event:hook_nuqi_skill_upgrade(RoleID, SkillID, SkillLevel),
			hook_mission_event:hook_nuqi_shape_upgrade(RoleID, SkillID);
		false -> ignore
	end.

get_nuqi_skill_shape_num(NuqiSkillID) ->
	case is_nuqi_skill(NuqiSkillID) of
		true -> NuqiSkillID rem 10;
		false -> 0
	end.


