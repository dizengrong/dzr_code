-module(mod_nuqi_huoling).

-include("mgeer.hrl").

-export([
	init/2,
	delete/1,
	fetch/1,
	handle/1,
	recalc/2,
	hook_skill_use/4,
	do_huoling_info/1,
	add_yihuo_element/3,
	add_yihuo/4,
	hook_role_online/1,
	get_huoling_level/1
]).

-record(huoling_attr_deduct, {
	%%silver_any:绑定银两, gold_unbind:元宝, gold_bind:礼券
	type = silver_any,
	cost = 0,
	%%暴击
	double_attack = 0,
	%%物防
	physic_def = 0,
	%%法防
	magic_def = 0,
	%%攻击
	attack = 0,
	%%生命
	max_hp = 0,
	%%怒伤
	crit = 0,
	%%需要火灵形态
	need_huoling_shape = 0,
	need_items = []%%%  {道具id, 道具个数}
}).

-record(yihuo_base_info, {
	name = "明心自然",%%异火名字
	typeid = 0,%%类型id
	color = 2,%%颜色
	miss = 0,%%闪避
	tough = 0,%%坚韧
	hit_rate = 0,%%命中
	max_exp = 0,%%经验达到多少就会变成下一品质
	eat_exp = 0,%%被吞噬时转换成多少经验,
	color_name = "蓝色"%%异火颜色名字
}).

init(RoleID, Rec) when is_record(Rec, r_nuqi_huoling) ->
	mod_role_tab:put({r_nuqi_huoling, RoleID}, Rec);
init(RoleID, _) ->
	mod_role_tab:put({r_nuqi_huoling, RoleID}, #r_nuqi_huoling{}).

delete(RoleID) ->
	mod_role_tab:get({r_nuqi_huoling, RoleID}).

fetch(RoleID) -> 
	Huoling = case mod_role_tab:get({r_nuqi_huoling, RoleID}) of
		Rec when is_record(Rec, r_nuqi_huoling) -> Rec;
		_ -> #r_nuqi_huoling{}
	end,
	Date = erlang:date(),
	YihuoTimes = cfg_nuqi_huoling:random_yihuo_times(),
	case Date == Huoling#r_nuqi_huoling.yihuo_random_date of
		true -> Huoling;
		false -> 
			Huoling#r_nuqi_huoling{
				yihuo_random_times = YihuoTimes,
				yihuo_random_date = Date
			}
	end.

save(RoleID, Rec) when is_record(Rec, r_nuqi_huoling) ->
	mod_role_tab:put({r_nuqi_huoling, RoleID}, Rec).

get_huoling_level(RoleID) ->
	#r_nuqi_huoling{level = AttrLevel} = fetch(RoleID),
	AttrLevel.

handle({huoling, RoleID}) -> 
	Huoling = fetch(RoleID),
	Elements = lists:map(fun(H) ->
		{H, 100000}
	end, ?YIHUO_ElEMENTS),

	NewHuoling = Huoling#r_nuqi_huoling{
		yihuo_elements = Elements
	},
	save(RoleID, NewHuoling),
	do_huoling_info(RoleID);

handle({_Unique, ?HUOLING, ?HUOLING_INFO, _DataIn, RoleID, _PID, _Line}) ->
	do_huoling_info(RoleID);
handle({_Unique, ?HUOLING, ?HUOLING_ATTR_UPGRADE, _DataIn, RoleID, _PID, _Line}) ->
	do_huoling_attr_upgrade(RoleID);
handle({_Unique, ?HUOLING, ?HUOLING_SKILL_LEARN, DataIn, RoleID, _PID, _Line}) ->
	do_huoling_skill_learn(DataIn, RoleID);
handle({_Unique, ?HUOLING, ?YIHUO_RANDOM, _DataIn, RoleID, _PID, _Line}) ->
	do_yihuo_random(RoleID);
handle({_Unique, ?HUOLING, ?YIHUO_JINGLIAN, DataIn, RoleID, _PID, _Line}) ->
	JingLianType = DataIn#m_yihuo_jinglian_tos.type,
	do_yihuo_jinglian(JingLianType, RoleID);
handle({_Unique, ?HUOLING, ?YIHUO_AUTO_EAT, DataIn, RoleID, _PID, _Line}) ->
	do_yihuo_auto_eat(DataIn, RoleID);
handle({_Unique, ?HUOLING, ?YIHUO_EQUIP, DataIn, RoleID, _PID, _Line}) ->
	#m_yihuo_equip_tos{type = Type, yihuo_id = YihuoID, pos = Pos} = DataIn,
	do_yihuo_equip(Type, YihuoID, RoleID, Pos);
handle(_) -> ignore.

%----------------------华丽的分割线----------------------

hook_skill_use(RoleID, SkillBaseInfo, CasterAttr, TargetAttr) ->
	SkillID = SkillBaseInfo#p_skill.id,
	% case SkillID =/= 1 andalso (not mod_role_skill:is_nuqi_skill(SkillID)) of
	case mod_role_skill:is_nuqi_skill(SkillID) of
		true ->
			#r_nuqi_huoling{skills = HuolingSkills} = fetch(RoleID),

			lists:foreach(fun(HuoSkill) ->
				HuoSkillID = HuoSkill#p_role_skill.skill_id,
				HuoSkillLevel = HuoSkill#p_role_skill.cur_level, 
				case mod_skill_manager:get_skill_level_info(HuoSkillID, HuoSkillLevel) of
					{ok, SkillLevelInfo} -> 
						Buffs = SkillLevelInfo#p_skill_level.buffs,
    					% mod_role_buff:add_buff(TargetID, Buffs),
    					mof_buff:add_buff(CasterAttr, TargetAttr, Buffs),
						ignore;
					_ -> ignore
				end
			end, HuolingSkills);
		false -> ignore
	end.

add_yihuo_element(RoleID, ItemTypeID, ItemNum) ->
	Huoling = #r_nuqi_huoling{} = fetch(RoleID),
	{ElementType, ItemTypeID} = lists:keyfind(ItemTypeID, 2, cfg_nuqi_huoling:is_huoling_element_item_id()),
	NewHuoling1 = save_yihuo_elements(Huoling, ElementType, ItemNum),
	NewElements = NewHuoling1#r_nuqi_huoling.yihuo_elements,
	NewHuoling2 = Huoling#r_nuqi_huoling{
		yihuo_elements = NewElements
	},
	save(RoleID, NewHuoling2),
	do_huoling_info(RoleID).

add_yihuo(RoleID, ItemBaseInfo, UseNum, TypeID) ->
	Huoling = #r_nuqi_huoling{} = fetch(RoleID),
	Color = ItemBaseInfo#p_item_base_info.colour,
	Level = ItemBaseInfo#p_item_base_info.requirement#p_use_requirement.min_level, 
	{NewHuoling1, UseNum1} = lists:foldl(fun(_H, {Huoling1, UsedNum}) ->
		#r_nuqi_huoling{bag_yihuos = BagYihuos} = Huoling1,

		case check_bag_max_num(RoleID, BagYihuos) of
			true -> 
				{MaxId1, Huoling2} = new_yihuo_detail_id(Huoling1), 
				NewYihuo =  #p_yihuo_detail{
					id = MaxId1, 
					exp = 0, 
					level = Level,
					typeid = TypeID, 
					color = Color
				},
				NewBagYihuos = [NewYihuo|Huoling2#r_nuqi_huoling.bag_yihuos],
				Huoling3 = Huoling2#r_nuqi_huoling{
					bag_yihuos = NewBagYihuos,
					yihuo_max_id = MaxId1
				},
				{Huoling3, UsedNum + 1};
			{error, _} ->
				{Huoling1, UsedNum}
		end
	end, {Huoling, 0}, lists:seq(1, UseNum)),

	save(RoleID, NewHuoling1),
	do_huoling_info(RoleID),
	{NewHuoling1, UseNum - UseNum1}.

hook_role_online(RoleID) ->
	#r_nuqi_huoling{level = AttrLevel} = fetch(RoleID),
	case cfg_nuqi_huoling:get_huoling_shape(AttrLevel) of
		false -> ignore;
		ShapeNum when is_integer(ShapeNum) ->
			mgeem_map:send({apply, mod_map_role, 
				do_update_role_skin, [RoleID, [{#p_skin.halo, ShapeNum}]]})
	end.

do_huoling_info(RoleID) ->
	Huoling = fetch(RoleID),
    DataRecord = #m_huoling_info_toc{
    	attr_level = Huoling#r_nuqi_huoling.level, 
    	skills = Huoling#r_nuqi_huoling.skills,
    	equiped_yihuos = Huoling#r_nuqi_huoling.equiped_yihuos,
    	bag_yihuos = Huoling#r_nuqi_huoling.bag_yihuos,
    	yihuo_elements = Huoling#r_nuqi_huoling.yihuo_elements,
    	yihuo_random_times = Huoling#r_nuqi_huoling.yihuo_random_times,
    	huoling_slot = get_huoling_shape(RoleID) - 1
    },
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HUOLING, ?HUOLING_INFO, DataRecord).

do_huoling_attr_upgrade(RoleID) ->
	Huoling = #r_nuqi_huoling{level = AttrLevel} = fetch(RoleID),
	NewAttrLevel = AttrLevel + 1,
	case check_huoling_attr_upgrade(RoleID, Huoling, NewAttrLevel) of
		true ->	
			{ok, #p_role_attr{category = Category}} = mod_map_role:get_role_attr(RoleID),

			HuolingAttrDeduct = #huoling_attr_deduct{
			} =  cfg_nuqi_huoling:attr_deduct(AttrLevel),

			NewHuolingAttrDeduct = #huoling_attr_deduct{
				need_items = NeedItems,
				type = Type, 
				cost = Cost
			} =  cfg_nuqi_huoling:attr_deduct(NewAttrLevel),

			lists:foreach(fun({NeedItem, NeedNum}) ->
				ok = mod_bag:use_item(RoleID, NeedItem, NeedNum, ?LOG_ITEM_TYPE_XIANG_QIAN_SHI_QU)
			end, NeedItems),

			LogType = case Type of
				silver_any -> ?CONSUME_TYPE_SILVER_HUOLING_ATTR_UPGRADE;
				gold_any -> ?CONSUME_TYPE_GOLD_HUOLING_ATTR_UPGRADE;
				gold_unbind ->	?CONSUME_TYPE_GOLD_HUOLING_ATTR_UPGRADE
			end,
			case cfg_nuqi_huoling:get_huoling_shape(NewAttrLevel) of
				false -> ignore;
				ShapeNum when is_integer(ShapeNum) ->
					mgeem_map:send({apply, mod_map_role, 
						do_update_role_skin, [RoleID, [{#p_skin.halo, ShapeNum}]]})
			end,
			common_bag2:use_money(RoleID, Type, Cost, LogType),
			save(RoleID, Huoling#r_nuqi_huoling{level = NewAttrLevel}),

			OldAttrList = get_attr_upgrade_attr_list(HuolingAttrDeduct, Category),
			AttrList = get_attr_upgrade_attr_list(NewHuolingAttrDeduct, Category),
			mgeer_role:send_reload_base(RoleID, '-', OldAttrList, '+', AttrList),

			catch mod_role_event:notify(RoleID, {?ROLE_EVENT_HUO_LING, NewAttrLevel}),
				
			% mgeer_role:send_reload_base(RoleID, '+', AttrList),

			Rec = #m_huoling_attr_upgrade_toc{attr_level = NewAttrLevel}, 
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HUOLING, ?HUOLING_ATTR_UPGRADE, Rec);
		{error, Reason} ->
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR, #m_common_error_toc{error_str = Reason})
	end.

do_huoling_skill_learn(DataIn, RoleID) ->
	OldSkillID = DataIn#m_huoling_skill_learn_tos.skill_id,
	% NextSkillLevel = DataIn#m_huoling_skill_learn_tos.skill_level,
	Huoling = #r_nuqi_huoling{} = fetch(RoleID),

	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	HuolingSkillInfo = get_huoling_skill_info(RoleID, OldSkillID),
	OldSkillLevel = HuolingSkillInfo#p_role_skill.cur_level,
	NextSkillLevel = OldSkillLevel + 1,

	Flag = check_huoling_skill_learn(RoleAttr, OldSkillID, NextSkillLevel, Huoling),
	case Flag of
		true ->	
			SkillLevelInfo = mod_role_skill:get_skill_level_info2(OldSkillID, NextSkillLevel),

			common_bag2:use_money(RoleID, silver_any, SkillLevelInfo#p_skill_level.need_silver, ?CONSUME_TYPE_SILVER_HUOLING_SKILL_LEARN),
			use_skill_item(RoleID, SkillLevelInfo),

			SkillID = SkillLevelInfo#p_skill_level.skill_id,
			SkillLevel = SkillLevelInfo#p_skill_level.level,

			OldBloodLine = cfg_nuqi_huoling:add_nuqi_percent(OldSkillID, OldSkillLevel),
			AddBloodLine = cfg_nuqi_huoling:add_nuqi_percent(SkillID, SkillLevel),

			OldAttrList = [{#p_role_base.bloodline, OldBloodLine}],
			NewAttrList = [{#p_role_base.bloodline, AddBloodLine}],

			mgeer_role:send_reload_base(RoleID, '+', NewAttrList, '-', OldAttrList),

			RoleSkill = #p_role_skill{
				skill_id = SkillID,
				cur_level = NextSkillLevel
			},

    		NewSkills = case lists:keymember(SkillID, #p_role_skill.skill_id, Huoling#r_nuqi_huoling.skills) of
    				true -> lists:keyreplace(SkillID, #p_role_skill.skill_id, Huoling#r_nuqi_huoling.skills, RoleSkill);
    				false -> [RoleSkill|Huoling#r_nuqi_huoling.skills]
    		end, 

    		NewHuoling = Huoling#r_nuqi_huoling{
    			skills = NewSkills
    		},
    		save(RoleID, NewHuoling),

			Rec = #m_huoling_skill_learn_toc{skill = RoleSkill}, 
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HUOLING, ?HUOLING_SKILL_LEARN, Rec);
		{error, Reason} ->
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR, #m_common_error_toc{error_str = Reason})
	end.

do_yihuo_random(RoleID) ->
	Huoling = #r_nuqi_huoling{yihuo_random_times = RandomTimes} = fetch(RoleID),
	case check_yihuo_random({Huoling , RoleID}) of
		{error, Reason} ->
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR, #m_common_error_toc{error_str = Reason});
		true ->
			{ok, #p_role_attr{level = RoleLevel}} = mod_map_role:get_role_attr(RoleID),
			Cost = cfg_nuqi_huoling:random_yihuo_element_money(RandomTimes, RoleLevel),
			MoneyType = silver_any,
			LogType = ?CONSUME_TYPE_SILVER_YIHUO_RANDOM,
			common_bag2:use_money(RoleID, MoneyType, Cost, LogType),

			ElementType = common_tool:random(1, length(?YIHUO_ElEMENTS)),
			NewHuoling1 = save_yihuo_elements(Huoling, ElementType, 1),
			NewElements = NewHuoling1#r_nuqi_huoling.yihuo_elements,
			NewHuoling2 = Huoling#r_nuqi_huoling{
				yihuo_random_times = Huoling#r_nuqi_huoling.yihuo_random_times - 1,
				yihuo_elements = NewElements
			},
			save(RoleID, NewHuoling2),
			Rec = #m_yihuo_random_toc{
				yihuo_elements = NewElements,
				yihuo_random_times = NewHuoling2#r_nuqi_huoling.yihuo_random_times
			}, 
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?HUOLING, ?YIHUO_RANDOM, Rec)
	end.

do_yihuo_jinglian(JingLianType, RoleID) ->
	Huoling = fetch(RoleID),
	MoneyType = case JingLianType of
		?YIHUO_JINGLIAN_SUPER ->
			LogType = ?CONSUME_TYPE_GOLD_YIHUO_JINGLIAN,
			gold_unbind;
		?YIHUO_JINGLIAN_NORMAL -> 
			LogType = ?CONSUME_TYPE_SILVER_YIHUO_RANDOM,
			silver_any
	end,
	DeductNum = cfg_nuqi_huoling:jinglian_yihuo_element_num(),
	Cost = cfg_nuqi_huoling:jinglian_cost(),

	case check_yihuo_jinglian(Huoling, RoleID, MoneyType, Cost, DeductNum) of
		{error, Reason} ->
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR, #m_common_error_toc{error_str = Reason});
		true ->
			common_bag2:use_money(RoleID, MoneyType, Cost, LogType),
			NewHuoling = cost_jinglian_element(Huoling, DeductNum),
			YihuoDetail = create_yihuo_by_jinglian(RoleID, JingLianType),
			case YihuoDetail of
				false -> 
					save(RoleID, NewHuoling),
					Rec = #m_yihuo_jinglian_toc{
						succ = false,
						bag_yihuos = NewHuoling#r_nuqi_huoling.bag_yihuos, 
						yihuo_elements = NewHuoling#r_nuqi_huoling.yihuo_elements
					}, 
					common_misc:unicast(
						{role, RoleID}, 
						?DEFAULT_UNIQUE, 
						?HUOLING, 
						?YIHUO_JINGLIAN,
						Rec
					),
					Reason = <<"精炼失败!">>,
					common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR, #m_common_error_toc{error_str = Reason});
				#yihuo_base_info{typeid = Typeid, color = Color} ->
					{MaxId, NewHuoling1} = new_yihuo_detail_id(NewHuoling), 
					NewYihuo =  #p_yihuo_detail{
						id = MaxId, 
						exp = 0, 
						level = 1,
						typeid = Typeid, 
						color = Color
					},
					NewBagYihuos = [NewYihuo|NewHuoling1#r_nuqi_huoling.bag_yihuos],

					NewHuoling2 = NewHuoling1#r_nuqi_huoling{
						bag_yihuos = NewBagYihuos
					},
					save(RoleID, NewHuoling2),

					Rec = #m_yihuo_jinglian_toc{
						succ = true,
						bag_yihuos = NewBagYihuos, 
						yihuo_elements = NewHuoling2#r_nuqi_huoling.yihuo_elements,
						new_yihuo = NewYihuo
					},
					common_misc:unicast(
						{role, RoleID}, 
						?DEFAULT_UNIQUE, 
						?HUOLING, 
						?YIHUO_JINGLIAN,
						Rec
					)
			end
	end.

yihuo_eat_loop(Yihuo, EatExp) ->
	#p_yihuo_detail{
		typeid = TypeID,
		color = Color,
		level = Level,
		exp = Exp
	} = Yihuo,
	#yihuo_base_info{
		max_exp = MaxExp
	} = cfg_nuqi_huoling:yihuo_base_info(TypeID, Color, Level),

	EatExp1 = EatExp + Exp,

	case EatExp1 >= MaxExp of
		true ->
			case cfg_nuqi_huoling:yihuo_base_info(TypeID, Color, Level + 1) of
				false -> 
					case cfg_nuqi_huoling:yihuo_base_info(TypeID, Color + 1, 1) of
						false -> Yihuo;
						#yihuo_base_info{} -> 
							NewYihuo = Yihuo#p_yihuo_detail{
								color = Color + 1, 
								level = 1,
								exp = 0
							},
							yihuo_eat_loop(NewYihuo, EatExp1 - MaxExp)
					end;
				#yihuo_base_info{} -> 
					NewYihuo = Yihuo#p_yihuo_detail{level = Level + 1, exp = 0}, 
					yihuo_eat_loop(NewYihuo, EatExp1 - MaxExp)
			end;
		false ->
			Yihuo#p_yihuo_detail{exp = EatExp1}
	end.

do_yihuo_auto_eat(_DataIn, RoleID) ->
	Huoling = #r_nuqi_huoling{bag_yihuos = BagYihuos} = fetch(RoleID),

	{MissYihuos, ToughYihuos, HitRateYihuos} = 
	lists:foldl(fun(H, {TempMiss, TempTough, TempHitRate}) ->
		#p_yihuo_detail{typeid = TypeID} = H,
		case TypeID of
			?YIHUO_MISS -> 
				{[H|TempMiss], TempTough, TempHitRate};
			?YIHUO_TOUGH -> 
				{TempMiss, [H|TempTough], TempHitRate};
			?YIHUO_HIT_RATE -> 
				{TempMiss, TempTough, [H|TempHitRate]}
		end
	end, {[], [], []}, BagYihuos),

	[NewMissYihuos, NewToughYihuos, NewHitRateYihuos] = lists:map(fun(K) ->
		K1 = lists:sort(fun(A, B) ->
				{A#p_yihuo_detail.color, A#p_yihuo_detail.level, A#p_yihuo_detail.exp} 
					> 
				{B#p_yihuo_detail.color, B#p_yihuo_detail.level, B#p_yihuo_detail.exp}
			end, K),
		K2 = lists:foldl(fun(H, TempYihuos1) ->
			case TempYihuos1 of
				[] -> [H];
				[Yihuo] ->
					#p_yihuo_detail{
						typeid = TypeID1,
						color = Color1,
						level = Level1,
						exp = Exp1
					} = H,
					#yihuo_base_info{
						eat_exp = EatExp
					} = cfg_nuqi_huoling:yihuo_base_info(TypeID1, Color1, Level1),
					[yihuo_eat_loop(Yihuo, EatExp + Exp1)]
			end
		end, [], K1), 
		case K1 =/= [] andalso K2 =/= [] of
			true -> 
				[OldMaxYihuo|_] = K1,
				[NewMaxYihuo] = K2,
				NewTypeID = NewMaxYihuo#p_yihuo_detail.typeid, 
				NewColor = NewMaxYihuo#p_yihuo_detail.color,
				NewLevel = NewMaxYihuo#p_yihuo_detail.level,

				NewYihuoBaseInfo = cfg_nuqi_huoling:yihuo_base_info(NewTypeID, NewColor, NewLevel),
				YihuoName = NewYihuoBaseInfo#yihuo_base_info.name,
				ColorName = NewYihuoBaseInfo#yihuo_base_info.color_name,

				if
					NewMaxYihuo#p_yihuo_detail.color =/= OldMaxYihuo#p_yihuo_detail.color 
						orelse
					NewMaxYihuo#p_yihuo_detail.level =/= OldMaxYihuo#p_yihuo_detail.level ->
						Str = common_misc:format_lang(<<"恭喜你，异火【~s】升到~s~s级！">>, [YihuoName,ColorName, integer_to_list(NewLevel)]),
						common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR, #m_common_error_toc{error_str = Str});
					NewMaxYihuo#p_yihuo_detail.exp =/=  OldMaxYihuo#p_yihuo_detail.exp ->
						NewExp = NewMaxYihuo#p_yihuo_detail.exp - OldMaxYihuo#p_yihuo_detail.exp,
						Str = common_misc:format_lang(<<"【~s】吞噬获得~s点经验！">>, [YihuoName, integer_to_list(NewExp)]),
						common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR, #m_common_error_toc{error_str = Str});
					true -> ignore
				end;
			_ -> ignore
		end,
		K2
	end, [MissYihuos, ToughYihuos, HitRateYihuos]),
	NewYihuos = NewMissYihuos ++ NewToughYihuos ++ NewHitRateYihuos,

	NewHuoling = Huoling#r_nuqi_huoling{bag_yihuos = NewYihuos},
	save(RoleID, NewHuoling),

	Rec = #m_yihuo_auto_eat_toc{
		bag_yihuos = NewYihuos
	},
	common_misc:unicast(
		{role, RoleID}, 
		?DEFAULT_UNIQUE, 
		?HUOLING, 
		?YIHUO_AUTO_EAT,
		Rec
	).

do_yihuo_equip(Type, YihuoID, RoleID, Pos) ->
	%%1:装上  2:卸下
	case Type of
		1 -> do_yihuo_puton(YihuoID, RoleID, Pos);
		2 -> do_yihuo_putout(YihuoID, RoleID)
	end.

do_yihuo_puton(YihuoID, RoleID, Pos) ->
	Yihuo = #r_nuqi_huoling{equiped_yihuos = EquipYihuos, bag_yihuos = BagYihuos} = fetch(RoleID),
	case check_yihuo_puton(YihuoID,Yihuo, RoleID, Pos) of
		{error, Reason} -> 
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR, #m_common_error_toc{error_str = Reason});
		true ->
			YihuoDetail1 = #p_yihuo_detail{} = lists:keyfind(YihuoID, #p_yihuo_detail.id, BagYihuos),

			case lists:keyfind(Pos, #p_yihuo_detail.pos, EquipYihuos) of
				ChangeDetail = #p_yihuo_detail{} ->
					DeductTypeID1 = ChangeDetail#p_yihuo_detail.typeid,
					DeductColor1 = ChangeDetail#p_yihuo_detail.color,
					DeductLevel1 = ChangeDetail#p_yihuo_detail.level,
					DeductAttrList = get_attr_yihuo_base_info(DeductTypeID1, DeductColor1, DeductLevel1),

					EquipYihuos1 = EquipYihuos -- [ChangeDetail],
					BagYihuos1 = [ChangeDetail|BagYihuos];
				false -> 
					%%判断相同类型
					TypeID1 = YihuoDetail1#p_yihuo_detail.typeid,
					case lists:keyfind(TypeID1, #p_yihuo_detail.typeid, EquipYihuos) of
						ChangeDetail1 = #p_yihuo_detail{} ->
							DeductTypeID2 = ChangeDetail1#p_yihuo_detail.typeid,
							DeductColor2 = ChangeDetail1#p_yihuo_detail.color,
							DeductLevel2 = ChangeDetail1#p_yihuo_detail.level,

							DeductAttrList = get_attr_yihuo_base_info(DeductTypeID2, DeductColor2, DeductLevel2),
							EquipYihuos1 = EquipYihuos -- [ChangeDetail1],
							BagYihuos1 = [ChangeDetail1|BagYihuos];
						false ->
							DeductAttrList = [],
							EquipYihuos1 = EquipYihuos,
							BagYihuos1 = BagYihuos
					end
			end,
			YihuoDetail = YihuoDetail1#p_yihuo_detail{pos = Pos},

			NewEquipYihuos = [YihuoDetail|EquipYihuos1],

			NewBagYihuos = lists:keydelete(YihuoDetail#p_yihuo_detail.id, #p_yihuo_detail.id, BagYihuos1),

			NewYihuo = Yihuo#r_nuqi_huoling{
				equiped_yihuos = NewEquipYihuos,
				bag_yihuos = NewBagYihuos
			},
			
			TypeID = YihuoDetail#p_yihuo_detail.typeid,
			Color = YihuoDetail#p_yihuo_detail.color,
			Level = YihuoDetail#p_yihuo_detail.level,
			AttrList = get_attr_yihuo_base_info(TypeID, Color, Level),
			mgeer_role:send_reload_base(RoleID, '+', AttrList, '-', DeductAttrList),

			save(RoleID, NewYihuo),
			Rec = #m_yihuo_equip_toc{
				equiped_yihuos = NewEquipYihuos,
				bag_yihuos = NewBagYihuos
			},
			common_misc:unicast(
				{role, RoleID}, 
				?DEFAULT_UNIQUE, 
				?HUOLING, 
				?YIHUO_EQUIP,
				Rec
			)
	end.

do_yihuo_putout(YihuoID, RoleID) ->
	Yihuo = #r_nuqi_huoling{equiped_yihuos = EquipYihuos, bag_yihuos = BagYihuos} = fetch(RoleID),
	case check_yihuo_putout(YihuoID,Yihuo, RoleID) of
		{error, Reason} -> 
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR, #m_common_error_toc{error_str = Reason});
		true ->
			YihuoDetail = #p_yihuo_detail{} = lists:keyfind(YihuoID, #p_yihuo_detail.id, EquipYihuos),
			NewBagYihuos = [YihuoDetail|BagYihuos],
			NewEquipYihuos = EquipYihuos -- [YihuoDetail],
			NewYihuo = Yihuo#r_nuqi_huoling{
				equiped_yihuos = NewEquipYihuos,
				bag_yihuos = NewBagYihuos
			},

			TypeID = YihuoDetail#p_yihuo_detail.typeid,
			Color = YihuoDetail#p_yihuo_detail.color,
			Level = YihuoDetail#p_yihuo_detail.level,
			AttrList = get_attr_yihuo_base_info(TypeID, Color, Level),
			mgeer_role:send_reload_base(RoleID, '-', AttrList),

			save(RoleID, NewYihuo),
			Rec = #m_yihuo_equip_toc{
				equiped_yihuos = NewEquipYihuos,
				bag_yihuos = NewBagYihuos
			},
			common_misc:unicast(
				{role, RoleID}, 
				?DEFAULT_UNIQUE, 
				?HUOLING, 
				?YIHUO_EQUIP,
				Rec
			)
	end.

save_yihuo_elements(Huoling, ElementType, SaveNum) ->
	Elements = Huoling#r_nuqi_huoling.yihuo_elements,
	NewNum = case lists:keyfind(ElementType, 1, Elements) of
		false -> SaveNum;
		{_, Num} -> Num + SaveNum
	end,
	Huoling#r_nuqi_huoling{
		yihuo_elements = lists:keystore(ElementType, 1, Elements, {ElementType, NewNum})
	}.

cost_jinglian_element(Huoling, DeductNum) ->
	Elements = Huoling#r_nuqi_huoling.yihuo_elements,
	NewElemenst = lists:map(fun({Type, Num}) ->
		{Type, Num - DeductNum}
	end, Elements),
	Huoling#r_nuqi_huoling{yihuo_elements = NewElemenst}.

create_yihuo_by_jinglian(_RoleID, JingLianType) ->
	RandomType = common_tool:random(1, 3),

	RandomNum = common_tool:random(1, 100),
	RateList = case JingLianType of
		?YIHUO_JINGLIAN_SUPER -> cfg_nuqi_huoling:jinglian_super_rate();
		?YIHUO_JINGLIAN_NORMAL -> cfg_nuqi_huoling:jinglian_normal_rate()
	end, 
	{Color, _} = lists:foldl(fun({ColorNum, RateNum}, {PreColor, PreRate}) ->
		if PreColor == 0 ->
			case RateNum + PreRate > RandomNum of
				true -> {ColorNum, RateNum + PreRate};
				false -> {PreColor, RateNum + PreRate}
			end;
		true -> {PreColor, PreRate}
		end
	end, {0, 0}, RateList),
	cfg_nuqi_huoling:yihuo_base_info(RandomType, Color, 1).

check_list(CheckList) ->
	lists:foldl(
		fun(_Check, {error, Msg}) ->
			{error, Msg};
		(Check, true) ->
			Check()
	end, true, CheckList).

check_huoling_attr_upgrade(RoleID, _Huoling, AttrLevel) ->
	HuolingAttrDeduct = cfg_nuqi_huoling:attr_deduct(AttrLevel),
	CheckList = [
		fun() -> check_attr_deduct(AttrLevel) end,
		fun() -> check_huoling_shape(RoleID, HuolingAttrDeduct) end,
		fun() -> check_huoling_need_items(RoleID, HuolingAttrDeduct) end
	],
	check_list(CheckList).

check_yihuo_puton(YihuoID, Yihuo, RoleID, Pos) ->
	#r_nuqi_huoling{equiped_yihuos = _EquipYihuos, bag_yihuos = BagYihuos} = Yihuo,
	CheckList = [
		fun() -> check_yihuo_shape(YihuoID, Yihuo, RoleID, Pos) end, 
		fun() -> check_yihuo_exists(YihuoID,BagYihuos) end
	],
	check_list(CheckList).

check_yihuo_putout(YihuoID, Yihuo, RoleID) ->
	#r_nuqi_huoling{equiped_yihuos = EquipYihuos, bag_yihuos = BagYihuos} = Yihuo,
	CheckList = [
		fun() -> check_yihuo_exists(YihuoID,EquipYihuos) end,
		fun() -> check_bag_max_num(RoleID, BagYihuos) end
	],
	check_list(CheckList).

check_attr_deduct(AttrLevel) ->
	case cfg_nuqi_huoling:attr_deduct(AttrLevel) of
		#huoling_attr_deduct{} -> true;
		max -> {error, <<"火灵等级已经达到最高">>}
	end.

check_huoling_shape(RoleID, HuolingAttrDeduct) ->
	#huoling_attr_deduct{
		need_huoling_shape = NeedHuolingShape
	} = HuolingAttrDeduct,
	HuolingShape = get_huoling_shape(RoleID),
	case HuolingShape >= NeedHuolingShape of
		true -> true;
		false -> {error, <<"火灵形态不足">>}
	end.

check_huoling_need_items(RoleID, HuolingAttrDeduct) ->
	#huoling_attr_deduct{
		need_items = NeedItems
	} = HuolingAttrDeduct,
	case lists:all(fun(H) ->
		{ItemID, ItemNum} = H,
		{ok, ExistItemNum} = mod_bag:get_goods_num_by_typeid(RoleID, ItemID),
		ExistItemNum >= ItemNum
	end, NeedItems) of
		true -> true;
		false -> {error, <<"道具不足">>}
	end.

check_yihuo_shape(_YihuoID, _Yihuo, RoleID, Pos) ->
	case get_huoling_shape(RoleID) >= (Pos + 1)
		andalso Pos > 0
	of
		true -> true;
		false -> {error, <<"装备失败,怒气技能形态不够">>}
	end. 

check_yihuo_exists(YihuoID,Yihuos) ->
	case lists:keyfind(YihuoID, #p_yihuo_detail.id, Yihuos) of
		false -> {error, <<"您没有该异火">>};
		#p_yihuo_detail{} -> true
	end.

check_yihuo_jinglian(Huoling, RoleID, MoneyType, Cost, DeductNum) ->
	#r_nuqi_huoling{bag_yihuos = BagYihuos} = Huoling,
	CheckList = [
		fun() -> check_yihuo_element_num(Huoling, RoleID, DeductNum) end,
		fun() -> check_role_money(RoleID, MoneyType, Cost) end,
		fun() -> check_bag_max_num(RoleID, BagYihuos) end
	],
	check_list(CheckList).

check_yihuo_random({Huoling, RoleID}) ->
	{ok, #p_role_attr{level = RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	#r_nuqi_huoling{yihuo_random_times = RandomTimes} = Huoling,
	MoneyNum = cfg_nuqi_huoling:random_yihuo_element_money(RandomTimes, RoleLevel),
	CheckList = [
		fun() -> check_yihuo_times(Huoling) end,
		fun() -> check_role_money(RoleID, silver_any, MoneyNum) end
	],
	check_list(CheckList).

check_bag_max_num(_RoleID, BagYihuos) ->
	case length(BagYihuos) >= cfg_nuqi_huoling:bag_max_num() of
		true -> {error, <<"异火背包空间不足">>};
		false -> true
	end.


check_yihuo_element_num(Huoling, _RoleID, DeductNum) ->
	YihuoElements = Huoling#r_nuqi_huoling.yihuo_elements, 
	Flag = lists:all(fun(H) ->
		Element = lists:keyfind(H, 1, YihuoElements),
		case Element of
			false -> false;
			{_, ElementNum} -> 
				ElementNum >= DeductNum
		end
	end, ?YIHUO_ElEMENTS),
	case Flag of
		false ->{error, <<"灵元数量不够">>};
		% false ->true;
		true -> true
	end.

check_yihuo_times(Huoling) ->
	YihuoRandomTimes = Huoling#r_nuqi_huoling.yihuo_random_times,
	case YihuoRandomTimes > 0 of
		true -> true;
		false -> {error, <<"亲,今天随机异火的次数已经用完">>}
	end.

check_role_money(RoleID, MoneyType, Cost) ->
	case common_bag2:check_money_enough(MoneyType,Cost,RoleID) of
		true -> true;
		false -> 
			case MoneyType of
				silver_any -> {error, <<"铜钱不足">>};
				gold_any -> {error, <<"礼券不足">>};
				gold_unbind -> {error, <<"元宝不足">>}
			end
	end.

check_huoling_skill_learn(RoleAttr, OldSkillID, NextSkillLevel, Huoling) ->
	SkillList = Huoling#r_nuqi_huoling.skills,
	RoleID = RoleAttr#p_role_attr.role_id,
	HuolingSkillInfo = get_huoling_skill_info(RoleID, OldSkillID),
	SkillLevel = HuolingSkillInfo#p_role_skill.cur_level,
	SkillBaseInfo  = mod_role_skill:get_skill_base_info(OldSkillID),
	SkillLevelInfo = mod_role_skill:get_skill_level_info2(OldSkillID, NextSkillLevel),
	CheckList = [
		fun() -> 
			case NextSkillLevel > SkillLevel of
				true -> true;
				false -> {error, <<"无法进行此操作">>}
			end
		end,
		fun() -> check_is_huoling_skill(OldSkillID) end, 
		fun() -> check_skill_max_level(RoleAttr, SkillLevel, SkillBaseInfo, SkillLevelInfo, SkillList) end, 
		fun() -> check_need_attr_level(SkillBaseInfo, Huoling) end,
		fun() -> check_skill_precondition(RoleAttr, SkillLevel, SkillBaseInfo, SkillLevelInfo, SkillList) end,
		fun() -> check_role_silver(RoleAttr, SkillLevel, SkillBaseInfo, SkillLevelInfo, SkillList) end,
		fun() -> check_need_item(RoleAttr, SkillLevel, SkillBaseInfo, SkillLevelInfo, SkillList) end
	],
	check_list(CheckList).

check_is_huoling_skill(SkillID) ->
	case lists:member(SkillID, cfg_nuqi_huoling:is_huoling_skill()) of
		true -> true;
		false -> {error, <<"该技能不是火灵技能">>}
	end.

check_skill_max_level(_RoleAttr, SkillLevel, SkillBaseInfo, _SkillLevelInfo, _SkillList) ->
	% SkillID = SkillBaseInfo#p_skill.id,
	SkillLevel < SkillBaseInfo#p_skill.max_level 
	orelse {error, ?_LANG_SKILL_LEVEL_IS_MAXLEVEL}.

check_need_attr_level(SkillBaseInfo, Huoling) ->
	#r_nuqi_huoling{level = HuolingLevel} = Huoling,
	SkillID = SkillBaseInfo#p_skill.id,
	NeedLevel = cfg_nuqi_huoling:yihuo_skill_need_attr_level(SkillID),
	case HuolingLevel >= NeedLevel of
		true -> true;
		% false -> true
		false -> {error, <<"火灵等级不足">>}
	end.

check_skill_precondition(_RoleAttr, _SkillLevel, _SkillBaseInfo, SkillLevelInfo, SkillList) ->
	mod_role_skill:check_skill_precondition(_RoleAttr, _SkillLevel, _SkillBaseInfo, SkillLevelInfo, SkillList).

check_role_silver(RoleAttr, _SkillLevel, _SkillBaseInfo, SkillLevelInfo, _SkillList) ->
	mod_role_skill:check_role_silver(RoleAttr, _SkillLevel, _SkillBaseInfo, SkillLevelInfo, _SkillList).

check_need_item(RoleAttr, _SkillLevel, _SkillBaseInfo, SkillLevelInfo, _SkillList) ->
	RoleID   = RoleAttr#p_role_attr.role_id,
	NeedItem = SkillLevelInfo#p_skill_level.need_item,
	NeedNum  = SkillLevelInfo#p_skill_level.need_num,

	% get_need_item_num(RoleID, NeedItem) >= NeedNum orelse true.
	get_need_item_num(RoleID, NeedItem) >= NeedNum orelse {error, <<"道具不足">>}.

use_skill_item(RoleID, SkillLevelInfo) ->
	NeedItem = SkillLevelInfo#p_skill_level.need_item,
	NeedNum  = SkillLevelInfo#p_skill_level.need_num,
	common_transaction:t(fun
		() ->
			{ok,FinalUpdateList,FinalDeleteList} = mod_bag:decrease_goods_by_typeid(RoleID, NeedItem, NeedNum),
	        UpL = lists:foldl(fun(Goods, Acc) -> [Goods#p_goods{current_num=0}|Acc] end,FinalUpdateList,FinalDeleteList),
	        common_misc:update_goods_notify({role,RoleID}, UpL)
	end).

get_need_item_num(RoleID, ItemType) ->
	{ok, GoodsNum} = mod_bag:get_goods_num_by_typeid([1,2,3], RoleID, ItemType),
	GoodsNum.

get_huoling_skill_info(RoleID, SkillID) ->
	#r_nuqi_huoling{skills = SkillList} = fetch(RoleID),
    case lists:keyfind(SkillID, #p_role_skill.skill_id, SkillList) of
        SkillInfo when is_record(SkillInfo, p_role_skill) ->
            SkillInfo;
        _ ->
        	% #p_skill{category = Category} = mod_role_skill:get_skill_base_info(SkillID),
            #p_role_skill{skill_id = SkillID, cur_level = 0}
    end.

get_huoling_shape(RoleID) ->
	% cfg_nuqi_huoling:get_equip_slot_num(AttrLevel).
	NuqiSkillRec = mod_role_skill:get_role_nuqi_skill_info(RoleID),
	NuqiSkillId = NuqiSkillRec#r_role_skill_info.skill_id,
	mod_role_skill:get_nuqi_skill_shape_num(NuqiSkillId).

get_attr_yihuo_base_info(TypeID, Color, Level) ->
	YihuoBaseInfo = cfg_nuqi_huoling:yihuo_base_info(TypeID, Color, Level),
	[
		{#p_role_base.miss, YihuoBaseInfo#yihuo_base_info.miss},
		{#p_role_base.tough, YihuoBaseInfo#yihuo_base_info.tough},
		{#p_role_base.hit_rate, YihuoBaseInfo#yihuo_base_info.hit_rate}
	].

get_attr_upgrade_attr_list(HuolingAttrDeduct, Category) ->
	Attr1 = case Category of
		1 -> 
			[
			    {#p_role_base.max_phy_attack, HuolingAttrDeduct#huoling_attr_deduct.attack},
			    {#p_role_base.min_phy_attack, HuolingAttrDeduct#huoling_attr_deduct.attack}
			];
		3 -> 
			[
			    {#p_role_base.max_magic_attack, HuolingAttrDeduct#huoling_attr_deduct.attack},
			    {#p_role_base.min_magic_attack, HuolingAttrDeduct#huoling_attr_deduct.attack}
			]
	end,
	Attr2 =   
	[
	    {#p_role_base.double_attack, HuolingAttrDeduct#huoling_attr_deduct.double_attack},
	    {#p_role_base.phy_defence, HuolingAttrDeduct#huoling_attr_deduct.physic_def},
	    {#p_role_base.magic_defence, HuolingAttrDeduct#huoling_attr_deduct.magic_def},
	    {#p_role_base.max_hp, HuolingAttrDeduct#huoling_attr_deduct.max_hp},
	    {#p_role_base.crit, HuolingAttrDeduct#huoling_attr_deduct.crit}
	],
	Attr1 ++ Attr2.



%%登陆时重新计算属性的调用接口
recalc(RoleBase, _RoleAttr) ->
	RoleID = RoleBase#p_role_base.role_id,
	#r_nuqi_huoling{
		level = AttrLevel,
		skills = Skills, 
		equiped_yihuos = EquipYihuos
	} = fetch(RoleID),
	{ok, #p_role_attr{category = Category}} = mod_map_role:get_role_attr(RoleID),

	HuolingAttrDeduct = #huoling_attr_deduct{
	} = cfg_nuqi_huoling:attr_deduct(AttrLevel),
	AttrList1 = get_attr_upgrade_attr_list(HuolingAttrDeduct, Category),

	AttrList2 = lists:map(fun(H) ->
		SkillID = H#p_role_skill.skill_id,
		SkillLevel = H#p_role_skill.cur_level,
		AddBloodLine = cfg_nuqi_huoling:add_nuqi_percent(SkillID, SkillLevel),
		{#p_role_base.bloodline, AddBloodLine}
	end, Skills),

	AttrList3 = lists:foldl(fun(H, Acc) ->
		TypeID = H#p_yihuo_detail.typeid,
		Color = H#p_yihuo_detail.color,
		Level = H#p_yihuo_detail.level,
		Acc ++ get_attr_yihuo_base_info(TypeID, Color, Level)
	end, [], EquipYihuos),

	AttrList4 = AttrList1 ++ AttrList2 ++ AttrList3,

    mod_role_attr:calc(RoleBase, '+', AttrList4).

 new_yihuo_detail_id(Huoling) ->
 	MaxId = Huoling#r_nuqi_huoling.yihuo_max_id + 1,
 	NewHuoling = Huoling#r_nuqi_huoling{
 		yihuo_max_id = MaxId
 	},
 	{MaxId, NewHuoling}.



