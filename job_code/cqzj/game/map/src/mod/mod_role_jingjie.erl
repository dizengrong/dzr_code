%% Author: xierongfeng
%% Created: 2012-11-16
%% Description: 境界系统(新)
-module(mod_role_jingjie).

-define(_common_error,			?DEFAULT_UNIQUE, ?COMMON,	?COMMON_ERROR,			#m_common_error_toc).%}
-define(_jingjie_info,			?DEFAULT_UNIQUE, ?JINGJIE,	?JINGJIE_INFO,			#m_jingjie_info_toc).%}
-define(_jingjie_upgrade,		?DEFAULT_UNIQUE, ?JINGJIE,	?JINGJIE_UPGRADE,		#m_jingjie_upgrade_toc).%}
-define(_jingjie_skill_learn,	?DEFAULT_UNIQUE, ?JINGJIE,	?JINGJIE_SKILL_LEARN,	#m_jingjie_skill_learn_toc).%}
-define(_jingjie_skill_list,	?DEFAULT_UNIQUE, ?JINGJIE,	?JINGJIE_SKILL_LIST,	#m_jingjie_skill_list_toc).%}
-define(_equip_update,			?DEFAULT_UNIQUE, ?EQUIP,	?EQUIP_UPDATE,			#m_equip_update_toc).%}

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([init/2, delete/1, handle/1, recalc/2]).

%%
%% API Functions
%%
init(RoleID, Rec) when is_record(Rec, r_role_jingjie) ->
	mod_role_tab:put({r_role_jingjie, RoleID}, Rec);
init(_RoleID, _Rec) ->
	ignore.

delete(RoleID) ->
	mod_role_tab:erase({r_role_jingjie, RoleID}).

handle({_Unique, ?JINGJIE, ?JINGJIE_INFO, _DataIn, RoleID, PID, _Line}) ->
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	RoleJingjieRec = get_role_jingjie_rec(RoleID),
	common_misc:unicast2(PID, ?_jingjie_info{
		exp      = RoleJingjieRec#r_role_jingjie.exp,
		prestige = RoleJingjieRec#r_role_jingjie.prestige,
		skills   = RoleJingjieRec#r_role_jingjie.skills,
		jingjie  = RoleAttr#p_role_attr.jingjie
	});

handle({_Unique, ?JINGJIE, ?JINGJIE_INJECT, #m_jingjie_inject_tos{
			exp      = AddExp,
			prestige = AddPrestige
		}, RoleID, PID, _Line}) when AddExp >= 0, AddPrestige >= 0 ->
	{ok, RoleAttr = #p_role_attr{
		exp          = RoleExp, 
		cur_prestige = RolePrestige,
		jingjie      = RoleJingjie
	}} = mod_map_role:get_role_attr(RoleID),
	RoleJingjieRec = #r_role_jingjie{
		exp      = JingjieExp, 
		prestige = JingjiePrestige
	} = get_role_jingjie_rec(RoleID),
	MaxJingjie = cfg_jingjie:max_jingjie(),
	if
		RoleJingjie >= MaxJingjie ->
			common_misc:unicast2(PID, 
				?_common_error{error_str = <<"已经达到最高境界">>});
		RoleExp < AddExp ->
			common_misc:unicast2(PID, 
				?_common_error{error_str = <<"经验不足">>});
		RolePrestige < AddPrestige ->
			common_misc:unicast2(PID, 
				?_common_error{error_str = <<"声望不足">>});
		true ->
			NewRoleExp         = RoleExp         - AddExp,
			NewRolePrestige    = RolePrestige    - AddPrestige,
			NewJingjieExp      = JingjieExp      + AddExp,
			NewJingjiePrestige = JingjiePrestige + AddPrestige,
			ChangeList  = [
				#p_role_attr_change{
					change_type = ?ROLE_EXP_CHANGE,          
					new_value   = NewRoleExp
				},
				#p_role_attr_change{
					change_type = ?ROLE_CUR_PRESTIGE_CHANGE, 
					new_value   = NewRolePrestige
				}
			],
			common_misc:role_attr_change_notify({pid, PID}, RoleID, ChangeList),
			mod_role_tab:put({?role_attr, RoleID}, RoleAttr#p_role_attr{
				exp          = NewRoleExp,
				cur_prestige = NewRolePrestige
			}),
			put_role_jingjie_rec(RoleID, RoleJingjieRec#r_role_jingjie{
				exp      = NewJingjieExp,
				prestige = NewJingjiePrestige
			}),
			common_misc:unicast2(PID, ?_jingjie_info{
				exp      = NewJingjieExp,
				prestige = NewJingjiePrestige,
				jingjie  = RoleJingjie
			})
	end;

handle({auto_upgrade_jingjie,RoleID}) ->
    auto_upgrade_jingjie(RoleID);

handle({_Unique, ?JINGJIE, ?JINGJIE_UPGRADE, _DataIn, RoleID, PID, _Line}) ->
	{ok, RoleAttr = #p_role_attr{
		level   = RoleLevel,
		jingjie = RoleJingjie
	}} = mod_map_role:get_role_attr(RoleID),

	MaxJingjie  = cfg_jingjie:max_jingjie(),
	NewJingjie  = cfg_jingjie:next_jingjie(RoleJingjie),
	LimitLevel  = cfg_jingjie:get_limit_level(NewJingjie),

    {ok, #p_role_hero_fb_info{ fb_record = RoleFbRecords}} = mod_hero_fb:get_role_hero_fb_info(RoleID, ?HERO_FB_MODE_TYPE_NORMAL),
    BarrierIDList = [BarrierID||#p_hero_fb_barrier{barrier_id=BarrierID}<-RoleFbRecords],
    NewJingjieBarrier = cfg_jingjie:barrier_id(NewJingjie),
    PassFB = lists:member(NewJingjieBarrier, BarrierIDList),
	if
        PassFB =:= false ->
             common_misc:unicast2(PID, 
                ?_common_error{error_str = <<"未达到境界副本通关条件">>});
		RoleJingjie >= MaxJingjie ->
			common_misc:unicast2(PID, 
				?_common_error{error_str = <<"已经达到最高境界">>});
		RoleLevel < LimitLevel ->
			common_misc:unicast2(PID, 
				?_common_error{error_str = <<"升级境界所需的等级不足">>});
		true ->
			do_upgrade_jingjie(RoleAttr, NewJingjie)
	end;

handle({_Unique, ?JINGJIE, ?JINGJIE_SKILL_LEARN, DataIn, RoleID, PID, _Line}) ->
	#m_jingjie_skill_learn_tos{skill_id = SkillID} = DataIn,
	RoleJingjieRec = #r_role_jingjie{
		skills = Skills
	} = get_role_jingjie_rec(RoleID),
	SkillLevel = case lists:keyfind(SkillID, 1, Skills) of
		false -> 0;
		{_, SkillLevel2} ->
			SkillLevel2
	end,
	NextLevel = SkillLevel + 1,
	SkillLevelInfo = case common_config_dyn:find(skill_level, SkillID) of
        []->
            false;
        [SkillLevelList]->
            lists:keyfind(NextLevel, 3, SkillLevelList)
    end,
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	case check_can_learn(RoleAttr, SkillLevelInfo) of
		{error, Reason} ->
			common_misc:unicast2(PID, ?_common_error{error_str = Reason});
		{ok, NeedSilver, NeedExp} ->
			NewRoleSilver = RoleAttr#p_role_attr.silver_bind - NeedSilver,
			NewRoleExp    = RoleAttr#p_role_attr.exp         - NeedExp,
			mod_role_tab:put({?role_attr, RoleID}, RoleAttr#p_role_attr{
				silver_bind = NewRoleSilver, 
				exp         = NewRoleExp
			}),
			common_consume_logger:use_silver({
				RoleID, NeedSilver, 0, ?CONSUME_TYPE_SILVER_UP_SKILL, ""
			}),
			common_misc:role_attr_change_notify({pid, PID}, RoleID, [
				#p_role_attr_change{
					change_type = ?ROLE_SILVER_BIND_CHANGE, 
					new_value   = NewRoleSilver
				},
				#p_role_attr_change{
					change_type = ?ROLE_EXP_CHANGE, 
					new_value   = NewRoleExp
				}
			]),
			put_role_jingjie_rec(RoleID, RoleJingjieRec#r_role_jingjie{
				skills = lists:keyreplace(SkillID, 1, Skills, {SkillID, NextLevel})
			}),
			common_misc:unicast2(PID, ?_jingjie_skill_learn{
				skill_id    = SkillID,
				skill_level = NextLevel
			}),
			{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
			NewRoleBase    = mod_role_attr:calc(RoleBase, 
				'-', skill_attrs({SkillID, SkillLevel}), '+', skill_attrs({SkillID, NextLevel})),
			mod_role_attr:reload_role_base(NewRoleBase)
	end;

handle({_Unique, ?JINGJIE, ?JINGJIE_SKILL_LIST, _DataIn, RoleID, PID, _Line}) ->
	#r_role_jingjie{skills = JingjieSkills} = get_role_jingjie_rec(RoleID),
	common_misc:unicast2(PID, ?_jingjie_skill_list{skills = JingjieSkills}).

do_upgrade_jingjie(RoleAttr, NewJingjie) when is_record(RoleAttr, p_role_attr) ->
	#p_role_attr{role_id = RoleID, 
		jingjie = OldJingjie, equips = OldEquips, category = Category} = RoleAttr,
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	case make_jingjie_equip(RoleID, cfg_jingjie:equip(NewJingjie)) of
		NewEquip when is_record(NewEquip, p_goods) ->
			OldEquip    = lists:keyfind(?PUT_JINGJIE, #p_goods.loadposition, OldEquips),
			NewEquips   = [NewEquip|lists:keydelete(?PUT_JINGJIE, #p_goods.loadposition, OldEquips)],
			NewRoleAttr = RoleAttr#p_role_attr{jingjie = NewJingjie, equips = NewEquips},
			NewRoleBase = mod_role_equip:calc(RoleBase, '-', OldEquip, '+', NewEquip),
			common_misc:unicast({role, RoleID}, ?_equip_update{equips = [NewEquip]});
		undefined ->
			NewRoleAttr = RoleAttr#p_role_attr{jingjie = NewJingjie},
			NewRoleBase = RoleBase
	end,
	mod_role_tab:put({?role_attr, RoleID}, NewRoleAttr),
	NewRoleBase2 = mod_role_attr:calc(NewRoleBase, 
		'-', jingjie_attrs(OldJingjie, Category), '+', jingjie_attrs(NewJingjie, Category)),
	OpenSkills   = cfg_jingjie:open_skill(NewJingjie),
	NewRoleBase3 = lists:foldl(fun
		(OpenSkill, RoleBaseAcc) ->
			mod_role_attr:calc(RoleBaseAcc, '+', skill_attrs(OpenSkill))
	end, NewRoleBase2, OpenSkills),
	mod_role_attr:reload_role_base(NewRoleBase3),
	%% 开启境界技能
	RoleJingjieRec = get_role_jingjie_rec(RoleID),
	JingjieSkills  = RoleJingjieRec#r_role_jingjie.skills ++ OpenSkills,
	put_role_jingjie_rec(RoleID, RoleJingjieRec#r_role_jingjie{skills = JingjieSkills}),
	common_misc:role_attr_change_notify({role, RoleID}, RoleID, [
		#p_role_attr_change{change_type = ?ROLE_JINGJIE_CHANGE, new_value = NewJingjie}
	]),
	common_misc:unicast({role, RoleID}, ?_jingjie_info{jingjie = NewJingjie, skills = JingjieSkills}),
	common_misc:unicast({role, RoleID}, ?_jingjie_upgrade{}),

	mod_map_role:update_map_role_info(RoleID, [{#p_map_role.jingjie, NewJingjie}]),
	ok.

skill_attrs({SkillID, SkillLevel}) ->
	cfg_jingjie:skill_attrs(SkillID, SkillLevel).

jingjie_attrs(Jingjie, Category) ->
	cfg_jingjie:attrs_second(Jingjie, Category).

auto_upgrade_jingjie(RoleID) ->
    {ok, RoleAttr = #p_role_attr{
        level   = RoleLevel,
        jingjie = RoleJingjie
    }} = mod_map_role:get_role_attr(RoleID),
    MaxJingjie  = cfg_jingjie:max_jingjie(),
    NewJingjie  = cfg_jingjie:next_jingjie(RoleJingjie),
    LimitLevel  = cfg_jingjie:get_limit_level(NewJingjie),
    {ok, #p_role_hero_fb_info{ fb_record = RoleFbRecords}} = mod_hero_fb:get_role_hero_fb_info(RoleID, ?HERO_FB_MODE_TYPE_NORMAL), 
    BarrierIDList = [BarrierID||#p_hero_fb_barrier{barrier_id=BarrierID}<-RoleFbRecords],
    NewJingjieBarrier = cfg_jingjie:barrier_id(NewJingjie),
    PassFB = lists:member(NewJingjieBarrier, BarrierIDList),
    if
        PassFB =:= false ->
            common_misc:unicast({role,RoleID}, 
                ?_common_error{error_str = <<"未达到境界副本通关条件">>});
        RoleJingjie >= MaxJingjie ->
            common_misc:unicast({role,RoleID}, 
                ?_common_error{error_str = <<"已经达到最高境界">>});
        RoleLevel < LimitLevel ->
            common_misc:unicast({role,RoleID}, 
                ?_common_error{error_str = <<"升级境界所需的等级不足">>});
        true ->
            do_upgrade_jingjie(RoleAttr, NewJingjie)
    end.

recalc(RoleBase = #p_role_base{role_id = RoleID}, RoleAttr) ->
	#p_role_attr{jingjie=Jingjie, category=Category} = RoleAttr,
	RoleBase2 = mod_role_attr:calc(RoleBase, '+', jingjie_attrs(Jingjie, Category)),
	#r_role_jingjie{skills = Skills} = get_role_jingjie_rec(RoleID),
	RoleBase3 = lists:foldl(fun
		(Skill, RoleBaseAcc) ->
			mod_role_attr:calc(RoleBaseAcc, '+', skill_attrs(Skill))
	end, RoleBase2, Skills),
	RoleBase3.

%%
%% Local Functions
%%
get_role_jingjie_rec(RoleID) ->
	case mod_role_tab:get({r_role_jingjie, RoleID}) of
		undefined ->
			#r_role_jingjie{};
		Rec ->
			Rec
	end.

put_role_jingjie_rec(RoleID, Rec) ->
	mod_role_tab:put({r_role_jingjie, RoleID}, Rec).

check_can_learn(RoleAttr, SkillInfo = #p_skill_level{skill_id = SkillID}) 
  when SkillID == 62000001; SkillID == 62000002; SkillID == 62000003; SkillID == 62000004 ->
	if
		%%t6银两只有绑定的
		RoleAttr#p_role_attr.silver_bind < SkillInfo#p_skill_level.need_silver ->
			{error, <<"银两不足">>};
		RoleAttr#p_role_attr.exp < SkillInfo#p_skill_level.consume_exp ->
			{error, <<"经验不足">>};
		RoleAttr#p_role_attr.jingjie < SkillInfo#p_skill_level.premise_role_jingjie ->
			{error, <<"境界不足">>};
		true ->
			{ok, SkillInfo#p_skill_level.need_silver, SkillInfo#p_skill_level.consume_exp}
	end;
check_can_learn(_RoleAttr, _SkillInfo) ->
	{error, <<"不存在该技能">>}.

make_jingjie_equip(_RoleID, 0) ->
	undefined;
make_jingjie_equip(RoleID, EquipTypeID) ->
	CreateInfo = #r_equip_create_info{
        role_id     = RoleID, 
        num         = 1, 
        typeid      = EquipTypeID, 
        bind        = true,
        sub_quality = 5,
        color       = 3, 
        quality     = 2, 
        punch_num   = 0,
        bag_id      = 0,
        bagposition = 0
    },
    {ok, [Equip]} = common_bag2:creat_equip_without_expand(CreateInfo),
	Equip#p_goods{id=mod_bag:get_new_goodsid(RoleID), loadposition=?PUT_JINGJIE}.