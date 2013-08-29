%% Author: XieRongFeng
%% Created: 2012-11-5
%% Description: 人物基础属性模块
-module(mod_role_base).

-include("mgeer.hrl").

-import (common_tool, [ceil/1]).

-export([upgrade/2, transform/1, recalc/2]).

upgrade(OldRoleBase, NewRoleBase) ->
	OldBaseAttrs = [
		{#p_role_base.str,  OldRoleBase#p_role_base.base_str},
		{#p_role_base.int2, OldRoleBase#p_role_base.base_int},
		{#p_role_base.con,  OldRoleBase#p_role_base.base_con},
		{#p_role_base.dex,  OldRoleBase#p_role_base.base_dex},
		{#p_role_base.men,  OldRoleBase#p_role_base.base_men}
	],
	NewBaseAttrs = [
		{#p_role_base.str,  NewRoleBase#p_role_base.base_str},
		{#p_role_base.int2, NewRoleBase#p_role_base.base_int},
		{#p_role_base.con,  NewRoleBase#p_role_base.base_con},
		{#p_role_base.dex,  NewRoleBase#p_role_base.base_dex},
		{#p_role_base.men,  NewRoleBase#p_role_base.base_men}
	],
	NewRoleBase2 = mod_role_attr:calc(NewRoleBase, '-', OldBaseAttrs, '+', NewBaseAttrs),
	mod_role_attr:reload_role_base(NewRoleBase2),
	NewRoleBase2.

transform(RoleBase) ->
	[
		{#p_role_base.min_phy_attack,	ceil(1.3*RoleBase#p_role_base.str)},
		{#p_role_base.max_phy_attack,	ceil(1.3*RoleBase#p_role_base.str)},
		{#p_role_base.min_magic_attack, ceil(1.3*RoleBase#p_role_base.int2)},
		{#p_role_base.max_magic_attack, ceil(1.3*RoleBase#p_role_base.int2)},
		{#p_role_base.phy_defence,   	ceil(1.1*RoleBase#p_role_base.dex)},
		{#p_role_base.magic_defence,	ceil(1.1*RoleBase#p_role_base.men)},
		{#p_role_base.max_hp,			ceil(5.0*RoleBase#p_role_base.con)},
		{#p_role_base.max_mp,			ceil(0.1*RoleBase#p_role_base.con)}
	].

recalc(RoleBase, _RoleAttr) ->
	RoleBase2 = RoleBase#p_role_base{
		str  = 0,
		int2 = 0,
		con  = 0,
		dex  = 0,
		men  = 0	
	},
	BaseAttrs = [
		{#p_role_base.str,  RoleBase#p_role_base.base_str},
		{#p_role_base.int2, RoleBase#p_role_base.base_int},
		{#p_role_base.con,  RoleBase#p_role_base.base_con},
		{#p_role_base.dex,  RoleBase#p_role_base.base_dex},
		{#p_role_base.men,  RoleBase#p_role_base.base_men}
	],
	mod_role_attr:calc(RoleBase2, '+', BaseAttrs).