%% Author: xierongfeng
%% Created: 2012-10-30
%% Description: 技能吟唱
-module(mof_skill_cast).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([handle/6, handle/2, handle_event/2, is_casting/2, stop/2]).

%%
%% API Functions
%%
handle(Caster, Target, Pos, SkillBaseInfo1, SkillLevelInfo1, MapState) ->
	is_record(Caster, p_map_role) 
		andalso get({enter, Caster#p_map_role.role_id}) =/= undefined
		andalso throw({error, <<"正在进行地图跳转，不能施放该技能">>}),
	{CasterAttr, TargetAttr, _SkillBaseInfo2, SkillLevelInfo2} = 
		mof_before_attack:handle(Caster, Target, Pos, SkillBaseInfo1, SkillLevelInfo1, MapState),
	#actor_fight_attr{actor_id = CasterID, actor_type = CasterTypeInt} = CasterAttr,
	CasterType = mof_common:actor_type_atom(CasterTypeInt),
	mod_map_event:add_handler({CasterType, CasterID}, ?MODULE),
	#p_skill_level{cast_time=CastTime, channel_times=ChannelTimes} = SkillLevelInfo2,
	put({?MODULE, CasterType, CasterID}, {SkillLevelInfo1, common_tool:now()+CastTime*ChannelTimes/1000}),
	case CasterTypeInt of
		?TYPE_MONSTER ->
			mod_map_monster:update_next_work(CasterID, common_tool:now2()+CastTime, loop);
		?TYPE_SERVER_NPC ->
			mod_server_npc:update_next_work(CasterID, common_tool:now2()+CastTime, loop);
		_ ->
			ignore
	end,
	lists:foreach(fun(Effect) ->
		mof_effect:handle(CasterAttr, TargetAttr, att_result(TargetAttr), Effect, MapState)
	end, SkillLevelInfo2#p_skill_level.effects),
	mof_buff:add_buff(CasterAttr, CasterAttr, SkillLevelInfo2#p_skill_level.buffs),
	Msg = {skill_attack, Caster, Target, Pos, 1, CasterAttr, TargetAttr},
	if
		ChannelTimes > 0 -> handle(Msg, MapState);
		true -> erlang:send_after(CastTime, self(), {mod, ?MODULE, Msg})
	end,
	ignore.

att_result(TargetAttr) when is_record(TargetAttr, actor_fight_attr) ->
	#p_attack_result{
		dest_id      = TargetAttr#actor_fight_attr.actor_id,
		dest_type    = TargetAttr#actor_fight_attr.actor_type,
		result_type  = ?RESULT_TYPE_REDUCE_HP
	};
att_result(_TargetAttr) -> #p_attack_result{}.

handle({skill_attack, {CasterType, CasterID}, {TargetType, TargetID}, Pos, AttackNum}, MapState) ->
	Caster = mod_map_actor:get_actor_mapinfo(CasterID, CasterType),
	Target = mod_map_actor:get_actor_mapinfo(TargetID, TargetType),
	CasterAttr = mof_common:get_fight_attr(Caster),
	TargetAttr = mof_common:get_fight_attr(Target),
	handle({skill_attack, Caster, Target, Pos, AttackNum, CasterAttr, TargetAttr}, MapState);

handle({skill_attack, {CasterType, CasterID}, Target, Pos, AttackNum}, MapState) ->
	Caster = mod_map_actor:get_actor_mapinfo(CasterID, CasterType),
	CasterAttr = mof_common:get_fight_attr(Caster),
	TargetAttr = mof_common:get_fight_attr(Target),
	handle({skill_attack, Caster, Target, Pos, AttackNum, CasterAttr, TargetAttr}, MapState);

handle({skill_attack, Caster, Target, Pos, AttackNum, CasterAttr, TargetAttr}, MapState) when is_record(CasterAttr, actor_fight_attr) ->
	#actor_fight_attr{actor_id = CasterID, actor_type = CasterTypeInt} = CasterAttr,
	CasterType = mof_common:actor_type_atom(CasterTypeInt),
	case get({?MODULE, CasterType, CasterID}) of
		{#p_skill_level{skill_id=SkillID, level=SkillLevel, cast_time=CastTime, channel_times=ChannelTimes}, _} ->
			{SkillBaseInfo, SkillLevelInfo} = get_inner_skill(Caster, SkillID, SkillLevel),
			SkillPos = mof_common:get_skill_pos(SkillBaseInfo, Caster, Target, Pos, undefined),
			Result = mof_skill_attack:handle2(CasterAttr, TargetAttr, SkillPos, SkillBaseInfo, SkillLevelInfo, MapState),
			CasterPos  = mof_common:get_pos(Caster),
			CasterInfo = {CasterTypeInt, CasterID, CasterPos},
			case TargetAttr of
				#actor_fight_attr{actor_type=TargetTypeInt, actor_id=TargetID} ->
					TargetType = mof_common:actor_type_atom(TargetTypeInt),
					Msg = {skill_attack, {CasterType, CasterID}, {TargetType, TargetID}, Pos, AttackNum+1};
				_ ->
					TargetTypeInt = 0, TargetID = 0,
					Msg = {skill_attack, {CasterType, CasterID}, Target, Pos, AttackNum+1}
			end,
			TargetInfo = {TargetTypeInt, TargetID, SkillPos},
			Dir = common_misc:get_dir(CasterPos, SkillPos),
			mof_fight_handler:handle_result(CasterInfo, TargetInfo, SkillID, Dir, Result, MapState),
			mof_fight_handler:handle_already_dead(erase(already_dead), MapState),
			if
				AttackNum < ChannelTimes ->
					erlang:send_after(CastTime, self(), {mod, ?MODULE, Msg});
				true ->
					stop(CasterType, CasterID),
					erase({?MODULE, CasterType, CasterID})
			end;
		_ ->
			ignore
	end;

handle(_Msg, _MapState) ->
	ignore.

get_inner_skill(Caster, SkillID, SkillLevel) ->
	InnerSkillID = cfg_fight:get_inner_skill(SkillID),
	{ok, SkillBaseInfo1} = mod_skill_manager:get_skill_info(InnerSkillID),
	{ok, SkillLevelInfo1} = mod_skill_manager:get_skill_level_info(InnerSkillID, SkillLevel),
	{SkillBaseInfo2, SkillLevelInfo2} = mof_before_attack:change_skill(Caster, 
		mof_common:get_fight_attr(Caster), SkillBaseInfo1, SkillLevelInfo1),
	{SkillBaseInfo2#p_skill{id = SkillID}, SkillLevelInfo2#p_skill_level{skill_id = SkillID}}.

stop(CasterType, CasterID) ->
	mod_map_event:delete_handler({CasterType, CasterID}, ?MODULE),
	case erase({?MODULE, CasterType, CasterID}) of
		{#p_skill_level{buffs=Buffs}, _} ->
			mod_role_buff:del_buff(CasterID, [BuffID||#p_buf{buff_id=BuffID}<-Buffs]);
		_ ->
			ignore
	end.

handle_event({CasterType, CasterID}, attack) ->
	stop(CasterType, CasterID);

handle_event({role, RoleID}, {role_pos_change, _TX, _TY, _DIR}) ->
	case get({?MODULE, role, RoleID}) of
		{#p_skill_level{skill_id=SkillID}, _} ->
			case cfg_fight:can_move_when_cast(SkillID) of
				false ->
					stop(role, RoleID);
				_ ->
					ignore
			end;
		_ ->
			ignore
	end;

handle_event({role, RoleID}, before_role_quit) ->
	stop(role, RoleID);

handle_event({role, RoleID}, {role_dead, _CasterID, _CasterType}) ->
	stop(role, RoleID);

handle_event({role, RoleID}, change_map) ->
	stop(role, RoleID);

handle_event(_, _) ->
	ignore.

is_casting(CasterType, CasterID) ->
	case get({?MODULE, CasterType, CasterID}) of
		{_, EndTime} ->
			case common_tool:now() > EndTime of
				true ->
					stop(CasterType, CasterID),
					false;
				_ ->
					true
			end;
		_ ->
			false
	end.
	

%%
%% Local Functions
%%
