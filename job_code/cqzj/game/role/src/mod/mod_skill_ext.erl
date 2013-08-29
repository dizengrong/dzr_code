%%% -------------------------------------------------------------------
%%% Author  : xierongfeng
%%% Description : 主动技能的效果扩展
%%%
%%% Created : 2013-6-26
%%% -------------------------------------------------------------------
-module(mod_skill_ext).

-export([init/2, delete/1, delete/3, delete2/3, fetch/1, fetch/2, store/3, store2/3, change_skill/3]).

-include("mgeer.hrl").

init(RoleID, Rec) when is_record(Rec, r_skill_ext) ->
	mod_role_tab:put({r_skill_ext, RoleID}, Rec);
init(RoleID, _) ->
	mod_role_tab:put({r_skill_ext, RoleID}, #r_skill_ext{}).

delete(RoleID) ->
	mod_role_tab:get({r_skill_ext, RoleID}).

fetch(RoleID) -> 
	case mod_role_tab:get({r_skill_ext, RoleID}) of
		Rec when is_record(Rec, r_skill_ext) -> 
			Rec;
		_ ->
			#r_skill_ext{}
	end.

fetch(RoleID, SkillID) -> 
	#r_skill_ext{ext_list = ExtList} = fetch(RoleID),
	case lists:keyfind(SkillID, 1, ExtList) of
		{_, ExtTuples} -> ExtTuples;
		_ -> []
	end.

store(RoleID, SkillID, ExtTuples) ->
	#r_skill_ext{ext_list = OldExtList} = fetch(RoleID),
	NewExtList = store2(SkillID, OldExtList, ExtTuples),
	mod_role_tab:put({r_skill_ext, RoleID}, #r_skill_ext{ext_list = NewExtList}).

store2(SkillID, OldExtList, ExtTuples) ->
	OldExtTuples = case lists:keyfind(SkillID, 1, OldExtList) of
		{_, OldExtTuples2} -> OldExtTuples2;
		_Others            -> []
	end,
	NewExtTuples = lists:foldl(fun
		({Key, Val}, Acc) ->
			lists:keystore(Key, 1, Acc, {Key, Val})
	end, OldExtTuples, ExtTuples),
	lists:keystore(SkillID, 1, OldExtList, {SkillID, NewExtTuples}).

delete(RoleID, SkillID, Pattern) ->
	#r_skill_ext{ext_list = OldExtList} = fetch(RoleID),
	NewExtList = delete2(SkillID, OldExtList, Pattern),
	mod_role_tab:put({r_skill_ext, RoleID}, #r_skill_ext{ext_list = NewExtList}).

delete2(SkillID1, OldExtList, Pattern) ->
	lists:map(fun
		({SkillID2, OldExtTuples}) when SkillID1 == '_'; SkillID1 == SkillID2 ->
			NewExtTuples = lists:foldr(fun
				({Key, Val}, Acc) ->
					case Key of
						{_, DeleteClass} when Pattern == {'_', DeleteClass} ->
							Acc;
						{DeleteType, _}  when Pattern == {DeleteType, '_'} ->
							Acc;
						_ when Pattern == {'_', '_'} ->
							Acc;
						_ ->
							[{Key, Val}|Acc]
					end
			end, [], OldExtTuples),
			{SkillID2, NewExtTuples};
		(Others) -> 
			Others
	end, OldExtList).

change_skill(SBInfo, SLInfo, []) -> 
	{SBInfo, SLInfo};
change_skill(SBInfo, SLInfo, ChangeTuples) ->
	lists:foldl(fun
		({{Type, _Class}, Args}, {SBAcc, SLAcc}) ->
			{handle_ext({Type, Args}, SBAcc), handle_ext({Type, Args}, SLAcc)};
		({Type, Args}, {SBAcc, SLAcc}) ->
			{handle_ext({Type, Args}, SBAcc), handle_ext({Type, Args}, SLAcc)}
	end, {SBInfo, SLInfo}, ChangeTuples).

handle_ext({add_buff, Buffs}, SLInfo) when is_record(SLInfo, p_skill_level) ->
	OldBuffs = SLInfo#p_skill_level.buffs,
	NewBuffs = lists:foldr(fun
		(Buff, Acc) ->
			lists:keystore(Buff#p_buf.buff_id, #p_buf.buff_id, Acc, Buff)
	end, OldBuffs, Buffs),
	SLInfo#p_skill_level{buffs = NewBuffs};

handle_ext({add_buff_value, AddList}, SLInfo) when is_record(SLInfo, p_skill_level) ->
	OldBuffs = SLInfo#p_skill_level.buffs,
	NewBuffs = lists:foldr(fun
		(Buff, Acc) ->
			#p_buf{buff_id = BuffID, value = AddValue} = Buff,
			case lists:keyfind(BuffID, #p_buf.buff_id, Acc) of
				OldBuff when is_record(OldBuff, p_buf) ->
					NewBuff = OldBuff#p_buf{value = OldBuff#p_buf.value + AddValue},
					lists:keyreplace(BuffID, #p_buf.buff_id, Acc, NewBuff);
				false -> 
					[Buff|Acc]
			end
	end, OldBuffs, AddList),
	SLInfo#p_skill_level{buffs = NewBuffs};

handle_ext({add_effect, Effects}, SLInfo) when is_record(SLInfo, p_skill_level) ->
	OldEffects = SLInfo#p_skill_level.effects,
	NewEffects = lists:foldr(fun
		(Effect, Acc) ->
			lists:keystore(Effect#p_effect.calc_type, #p_effect.calc_type, Acc, Effect)
	end, OldEffects, Effects),
	SLInfo#p_skill_level{effects = NewEffects};

handle_ext({add_effect_value, AddList}, SLInfo) when is_record(SLInfo, p_skill_level) ->
	OldEffects = SLInfo#p_skill_level.effects,
	NewEffects = lists:foldl(fun
		(Effect, Acc) ->
			#p_effect{calc_type = CalcType, absolute_or_rate = Aor, value = AddValue} = Effect,
			case find_effect(CalcType, Aor, Acc) of
				OldEffect when is_record(OldEffect, p_effect) ->
					NewEffect = OldEffect#p_effect{value = OldEffect#p_effect.value + AddValue},
					lists:keyreplace(OldEffect#p_effect.effect_id, #p_effect.effect_id, Acc, NewEffect);
				_ ->
					[Effect|Acc]
			end
	end, OldEffects, AddList),
	SLInfo#p_skill_level{effects = NewEffects};

handle_ext({add_effect_prob, AddList}, SLInfo) when is_record(SLInfo, p_skill_level) ->
	OldEffects = SLInfo#p_skill_level.effects,
	NewEffects = lists:foldl(fun
		(Effect, Acc) ->
			#p_effect{calc_type = CalcType, absolute_or_rate = Aor, probability = AddProb} = Effect,
			case find_effect(CalcType, Aor, Acc) of
				OldEffect when is_record(OldEffect, p_effect) ->
					NewEffect = OldEffect#p_effect{probability = OldEffect#p_effect.probability + AddProb},
					lists:keyreplace(OldEffect#p_effect.effect_id, #p_effect.effect_id, Acc, NewEffect);
				_ ->
					[Effect|Acc]
			end
	end, OldEffects, AddList),
	SLInfo#p_skill_level{effects = NewEffects};

handle_ext(_Others, Skill) -> Skill.

find_effect(_CalcType, _Aor, []) -> false;
find_effect(CalcType, Aor, [Effect|T]) ->
	if
		CalcType == Effect#p_effect.calc_type, Aor == Effect#p_effect.absolute_or_rate ->
			Effect;
		true ->
			find_effect(CalcType, Aor, T)
	end.