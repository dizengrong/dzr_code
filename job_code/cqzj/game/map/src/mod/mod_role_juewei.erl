%% Author: xierongfeng
%% Created: 2012-11-16
%% Description: 爵位系统(新)
-module(mod_role_juewei).

-define(_common_error,		?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR,	#m_common_error_toc).%}
-define(_juewei_info,		?DEFAULT_UNIQUE, ?JUEWEI, ?JUEWEI_INFO,		#m_juewei_info_toc).%}
-define(_juewei_upgrade,	?DEFAULT_UNIQUE, ?JUEWEI, ?JUEWEI_UPGRADE,	#m_juewei_upgrade_toc).%}
-define(_equip_update,		?DEFAULT_UNIQUE, ?EQUIP, ?EQUIP_UPDATE,		#m_equip_update_toc).%}

-record(r_upgrade_req, {
	exp      = 0, 				%%经验
	prestige = 0,				%%声望
	gongxun  = 0,				%%功勋
	jingjie  = 0,				%%境界
	progress = 0				%%实力副本进度
}).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([init/2, delete/1, handle/1, recalc/2, is_suppressed/2]).

%%
%% API Functions
%%
init(_RoleID, Rec) when is_record(Rec, r_role_juewei) ->
	put(r_role_juewei, Rec);
init(_RoleID, _Rec) ->
	ignore.

delete(_RoleID) ->
	erase(r_role_juewei).

%% 是否被压制了
is_suppressed(CasterJuewei, TargetJuewei) ->
	case CasterJuewei > TargetJuewei of
		true  -> common_tool:random(1, 10000) < 10000*cfg_juewei:suppress_rate(CasterJuewei, TargetJuewei);
		false -> false
	end.

handle({_Unique, ?JUEWEI, ?JUEWEI_INFO, _DataIn, RoleID, PID, _Line}) ->
	{ok, #p_role_attr{
		juewei = RoleJuewei
	}} = mod_map_role:get_role_attr(RoleID),
	#r_role_juewei{
		exp      = JueweiExp, 
		prestige = JueweiPrestige
	} = case get(r_role_juewei) of
		undefined ->
			#r_role_juewei{};
		Rec ->
			Rec
	end,
	common_misc:unicast2(PID, ?_juewei_info{
		exp      = JueweiExp,
		prestige = JueweiPrestige,
		juewei   = RoleJuewei
	});

handle({_Unique, ?JUEWEI, ?JUEWEI_INJECT, #m_juewei_inject_tos{
		exp      = AddExp,
		prestige = AddPrestige
	}, RoleID, PID, _Line}) when AddExp >=0, AddPrestige >= 0  ->
	{ok, RoleAttr = #p_role_attr{
		exp          = RoleExp, 
		cur_prestige = RolePrestige,
		juewei       = RoleJuewei
	}} = mod_map_role:get_role_attr(RoleID),
	#r_role_juewei{
		exp      = JueweiExp, 
		prestige = JueweiPrestige
	} = case get(r_role_juewei) of
		undefined ->
			#r_role_juewei{};
		Rec ->
			Rec
	end,
	MaxJuewei = cfg_juewei:max_juewei(),
	if
		RoleJuewei >= MaxJuewei ->
			common_misc:unicast2(PID, ?_common_error{error_str = <<"已经达到最高官职">>});
		RoleExp < AddExp ->
			common_misc:unicast2(PID, ?_common_error{error_str = <<"经验不足">>});
		RolePrestige < AddPrestige ->
			common_misc:unicast2(PID, ?_common_error{error_str = <<"声望不足">>});
		true ->
			NewRoleExp        = RoleExp        - AddExp,
			NewRolePrestige   = RolePrestige   - AddPrestige,
			NewJueweiExp      = JueweiExp      + AddExp,
			NewJueweiPrestige = JueweiPrestige + AddPrestige,
			ChangeList  = [
				#p_role_attr_change{change_type=?ROLE_EXP_CHANGE,          new_value=NewRoleExp},
				#p_role_attr_change{change_type=?ROLE_CUR_PRESTIGE_CHANGE, new_value=NewRolePrestige}
			],
			common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
			mod_role_tab:put({?role_attr, RoleID}, RoleAttr#p_role_attr{
				exp          = NewRoleExp,
				cur_prestige = NewRolePrestige
			}),
			put(r_role_juewei, #r_role_juewei{
				exp      = NewJueweiExp,
				prestige = NewJueweiPrestige
			}),
			common_misc:unicast2(PID, ?_juewei_info{
				exp      = NewJueweiExp,
				prestige = NewJueweiPrestige,
				juewei   = RoleJuewei
			})
	end;

handle({auto_upgrade_juewei,RoleID}) ->
    auto_upgrade_juewei(RoleID);

handle({_Unique, ?JUEWEI, ?JUEWEI_UPGRADE, _DataIn, RoleID, PID, _Line}) ->
	{ok, RoleAttr = #p_role_attr{
		gongxun = Gongxun,
		jingjie = Jingjie,
		juewei  = Juewei
	}} = mod_map_role:get_role_attr(RoleID),
	#r_role_juewei{
		exp      = Exp, 
		prestige = Prestige
	} = case get(r_role_juewei) of
		undefined ->
			#r_role_juewei{};
		Rec ->
			Rec
	end,
	UpgradeReq = #r_upgrade_req{
		exp      = Exp,
		prestige = Prestige,
		gongxun  = Gongxun,
		jingjie  = Jingjie,
		progress = get_hero_fb_progress(RoleID)
	},
	case check_can_upgrade(Juewei, UpgradeReq) of
		{error, Msg} ->
			common_misc:unicast2(PID, ?_common_error{error_str = Msg});
		{ok, _NewExp, NewPrestige, NewJuewei} ->
			do_upgrade_juewei(RoleAttr, NewPrestige, NewJuewei)
	end.

do_upgrade_juewei(RoleAttr, NewPrestige, NewJuewei) ->
	put(r_role_juewei, #r_role_juewei{prestige = NewPrestige}),
	#p_role_attr{role_id = RoleID, juewei = OldJuewei, equips = _OldEquips, category = Category} = RoleAttr,
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	% case make_juewei_equip(RoleID, cfg_juewei:equip(NewJuewei)) of
	% 	NewEquip when is_record(NewEquip, p_goods) ->
	% 		OldEquip    = lists:keyfind(?PUT_JINGJIE, #p_goods.loadposition, OldEquips),
	% 		NewEquips   = [NewEquip|lists:keydelete(?PUT_JINGJIE, #p_goods.loadposition, OldEquips)],
	% 		NewRoleAttr = RoleAttr#p_role_attr{
	% 			exp          = NewExp,
	% 			cur_prestige = NewPrestige,
	% 			juewei       = NewJuewei,
	% 			equips       = NewEquips
	% 		},
	% 		NewRoleBase = mod_role_equip:calc(RoleBase, '-', OldEquip, '+', NewEquip),
	% 		common_misc:unicast({role, RoleID}, ?_equip_update{equips = [NewEquip]});
	% 	undefined ->
	% 		NewRoleAttr = RoleAttr#p_role_attr{
	% 			exp          = NewExp,
	% 			cur_prestige = NewPrestige,
	% 			juewei       = NewJuewei
	% 		},
	% 		NewRoleBase = RoleBase
	% end,
	NewRoleAttr = RoleAttr#p_role_attr{
		juewei       = NewJuewei
	},
	NewRoleBase = RoleBase,
	common_misc:role_attr_change_notify({role, RoleID}, RoleID, [
		#p_role_attr_change{change_type=?ROLE_JUEWEI_ATTR_CHANGE,	new_value=NewJuewei}
	]),
	mod_role_tab:put({?role_attr, RoleID}, NewRoleAttr),
	common_misc:unicast({role, RoleID}, ?_juewei_info{
		prestige = NewPrestige,
		juewei   = NewJuewei
	}),
	common_misc:unicast({role, RoleID}, ?_juewei_upgrade{}),
	%% 完成成就
	mod_achievement2:achievement_update_event(RoleID, 44004, {1, NewJuewei}),
	NewRoleBase2 = mod_role_attr:calc(NewRoleBase, 
		'-', cfg_juewei:attrs(OldJuewei, Category), '+', cfg_juewei:attrs(NewJuewei, Category)),
	mod_role_attr:reload_role_base(NewRoleBase2),

	mod_map_role:update_map_role_info(RoleID, [{#p_map_role.juewei, NewJuewei}]),
	ok.

auto_upgrade_juewei(RoleID) ->
	{ok, RoleAttr = #p_role_attr{
		juewei  = Juewei
	}} = mod_map_role:get_role_attr(RoleID),
	#r_role_juewei{
		prestige = Prestige
	} = case get(r_role_juewei) of
		undefined ->
			#r_role_juewei{};
		Rec ->
			Rec
	end,
	NextJuewei  = cfg_juewei:next_juewei(Juewei),
	do_upgrade_juewei(RoleAttr, Prestige, NextJuewei).

recalc(RoleBase, RoleAttr) ->
	mod_role_attr:calc(RoleBase, '+', cfg_juewei:attrs(RoleAttr#p_role_attr.juewei,RoleAttr#p_role_attr.category)).

%%
%% Local Functions
%%
get_hero_fb_progress(RoleID) ->
	case mod_hero_fb:get_role_hero_fb_info(RoleID, ?HERO_FB_MODE_TYPE_NORMAL) of
		{ok, FbInfo} ->
			FbInfo#p_role_hero_fb_info.progress;
		_ ->
			0
	end.

check_can_upgrade(Juewei, UpgradeReq1) ->
	case Juewei >= cfg_juewei:max_juewei() of
		true ->
			{error, <<"已经升到最高官职">>};
		_ ->
			NextJuewei  = cfg_juewei:next_juewei(Juewei),
			UpgradeReq2 = cfg_juewei:upgrade_req(NextJuewei),
			if
				UpgradeReq1#r_upgrade_req.exp < UpgradeReq2#r_upgrade_req.exp ->
					{error, <<"经验不足">>};
				UpgradeReq1#r_upgrade_req.prestige < UpgradeReq2#r_upgrade_req.prestige ->
					{error, <<"声望不足">>};
				UpgradeReq1#r_upgrade_req.gongxun < UpgradeReq2#r_upgrade_req.gongxun ->
					{error, <<"功勋不足">>};
				UpgradeReq1#r_upgrade_req.jingjie < UpgradeReq2#r_upgrade_req.jingjie ->
					{error, <<"境界不足">>};
				% UpgradeReq1#r_upgrade_req.progress < UpgradeReq2#r_upgrade_req.progress ->
				% 	{error, <<"神兽副本进度不足">>};
				true ->
					{ok, UpgradeReq1#r_upgrade_req.exp - UpgradeReq2#r_upgrade_req.exp,
					 UpgradeReq1#r_upgrade_req.prestige - UpgradeReq2#r_upgrade_req.prestige,
                     NextJuewei}
			end
	end.

% make_juewei_equip(_RoleID, 0) ->
% 	undefined;
% make_juewei_equip(RoleID, EquipTypeID) ->
% 	CreateInfo = #r_equip_create_info{
%         role_id     = RoleID, 
%         num         = 1, 
%         typeid      = EquipTypeID, 
%         bind        = true,
%         sub_quality = 5,
%         color       = 3, 
%         quality     = 2, 
%         punch_num   = 0,
%         bag_id      = 0,
%         bagposition = 0
%     },
%     {ok, [Equip]} = common_bag2:creat_equip_without_expand(CreateInfo),
% 	Equip#p_goods{id=mod_bag:get_new_goodsid(RoleID), loadposition=?PUT_ADORN}.
