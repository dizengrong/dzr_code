%% Author: xierongfeng
%% Created: 2013-2-28
%% Description: 冲锋、急进
-module(mof_charge).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([handle/6]).

%%
%% API Functions
%%
handle(Caster, Target, Pos, SkillBaseInfo1, SkillLevelInfo1, MapState) ->
	{CasterAttr, TargetAttr, SkillBaseInfo2, SkillLevelInfo2} = 
		mof_before_attack:handle(Caster, Target, Pos, SkillBaseInfo1, SkillLevelInfo1, MapState),
	#actor_fight_attr{actor_id=CasterID, actor_type=CasterType} = CasterAttr,
	#actor_fight_attr{actor_id=TargetID, actor_type=TargetType} = TargetAttr,
	CasterTypeAtom = mof_common:actor_type_atom(CasterType),
	TargetTypeAtom = mof_common:actor_type_atom(TargetType),
	mod_map_role:do_skill_charge(CasterID, CasterTypeAtom, TargetID, TargetTypeAtom, MapState),
	case SkillBaseInfo2#p_skill.contain_common_attack of
		true ->
			mof_normal_attack:handle2(CasterAttr, TargetAttr, Pos, SkillBaseInfo2, SkillLevelInfo2, MapState);
		_ ->
			mof_skill_attack:handle2(CasterAttr, TargetAttr, Pos, SkillBaseInfo2, SkillLevelInfo2, MapState)
	end.



%%
%% Local Functions
%%

