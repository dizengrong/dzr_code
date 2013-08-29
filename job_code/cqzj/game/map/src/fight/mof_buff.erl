%% Author: xierongfeng
%% Created: 2013-3-5
%% Description: 
-module(mof_buff).

%%
%% Include files
%%
-include("mgeem.hrl").
-include("fight.hrl").

%%
%% Exported Functions
%%
-export([add_buff/3, under_attack/2]).

%%
%% API Functions
%%
add_buff(_CasterAttr, _TargetAttr, []) ->
	ignore;

%%白虎的被动晕眩效果
add_buff(CasterAttr, TargetAttr, [Buff = #p_buf{buff_id=?BUFF_DIZZY}]) ->
	#actor_fight_attr{actor_id = CasterID, buffs = Buffs} = CasterAttr,	
	DizzyReduceCD = lists:keyfind(?BUFF_DIZZY_REDUCE_CD, #p_actor_buf.buff_id, Buffs),
	case is_dizzy_cd(CasterID, DizzyReduceCD) of
		false ->
			set_dizzy_cd(CasterID),
			add_buff2(CasterAttr, TargetAttr, [Buff]);
		_ ->
			ignore
	end;
%%朱雀的被动中毒效果
add_buff(CasterAttr, TargetAttr, [Buff = #p_buf{buff_id=?BUFF_POISONING}]) ->
	case poison_add_hurt(CasterAttr, TargetAttr, Buff) of
		Buff2 when is_record(Buff2, p_buf) ->
			add_buff2(CasterAttr, TargetAttr, [Buff2]);
		_ ->
			ignore
	end;
%%朱雀的力量燃烧效果
add_buff(CasterAttr, TargetAttr, [Buff = #p_buf{buff_id=?BUFF_POISON_ADD_HURT}]) ->
	erase({poison_add_hurt, CasterAttr#actor_fight_attr.actor_id}),
	add_buff2(CasterAttr, TargetAttr, [Buff]);
%%朱雀的冲锋虚弱效果
add_buff(_CasterAttr, TargetAttr, [#p_buf{buff_id=?BUFF_ADD_WEEK, value=Value}]) ->
	#actor_fight_attr{actor_type=TargetTypeInt, actor_id=TargetID} = TargetAttr,
	TargetType = mof_common:actor_type_atom(TargetTypeInt),
	mod_buff:set_week(TargetType, TargetID, Value);
add_buff(CasterAttr, TargetAttr, Buffs) ->
	add_buff2(CasterAttr, TargetAttr, Buffs).

under_attack(TargetAttr, Damage) when TargetAttr#actor_fight_attr.actor_type == ?TYPE_ROLE ->
	under_attack(?BUFF_QINGLONG_SHIELD, TargetAttr, Damage) orelse
	under_attack(?BUFF_BAIHU_SHIELD, 	TargetAttr, Damage) orelse
	under_attack(?BUFF_XUANWU_SHIELD, 	TargetAttr, Damage) orelse
	under_attack(?BUFF_ZHUQUE_SHIELD, 	TargetAttr, Damage);
under_attack(_TargetAttr, _Damage) ->
	false.

%%
%% Local Functions
%%
add_buff2(CasterAttr, TargetAttr, Buffs) ->
	#actor_fight_attr{actor_type=CasterTypeInt, actor_id=CasterID} = CasterAttr,
	#actor_fight_attr{actor_type=TargetTypeInt, actor_id=TargetID} = TargetAttr,
	CasterType = mof_common:actor_type_atom(CasterTypeInt),
	TargetType = mof_common:actor_type_atom(TargetTypeInt),
	mod_buff:add_buff_to_actor(CasterID, CasterType, Buffs, TargetID, TargetType, TargetAttr).

is_dizzy_cd(CasterID, DizzyReduceCD) ->
	case get({last_dizzy_time, CasterID}) of
		undefined ->
			false;
		LastDizzyTime ->
			DizzyCd = case DizzyReduceCD of
				#p_actor_buf{value = Secs} ->
					cfg_fight:dizzy_cd() - Secs;
				_ ->
					cfg_fight:dizzy_cd()
			end,
			common_tool:now() - LastDizzyTime >= DizzyCd
	end.

set_dizzy_cd(CasterID) ->
	put({last_dizzy_time, CasterID}, common_tool:now()).

%%毒伤害叠加
poison_add_hurt(CasterAttr, TargetAttr, Buff) ->
	Buff2 = case lists:keyfind(?BUFF_POISON_ADD_HURT, 
					#p_actor_buf.buff_id, CasterAttr#actor_fight_attr.buffs) of
		#p_actor_buf{value=AddHurtNumMax} ->
			CasterID = CasterAttr#actor_fight_attr.actor_id,
			TargetID = CasterAttr#actor_fight_attr.actor_id,
			TgTuples = case get({poison_add_hurt, CasterID}) of
				undefined ->
					[];
				Tuples ->
					Tuples
			end,
			AddHurtNum = case lists:keyfind(TargetID, 1, TgTuples) of
				false -> 0;
				{_,N} -> N
			end,
			AddHurtNum2 = min(AddHurtNumMax, AddHurtNum+1),
			put({poison_add_hurt, CasterID}, 
				[{TargetID, AddHurtNum2}|lists:keydelete(TargetID, 1, TgTuples)]),
			Buff#p_buf{value=(Buff#p_buf.value*AddHurtNum2)*(1+CasterAttr#actor_fight_attr.poisoning)};
		_ ->
			Buff#p_buf{value=Buff#p_buf.value*(1+CasterAttr#actor_fight_attr.poisoning)}
	end,
	case lists:keyfind(?BUFF_POISONING, 
			#p_actor_buf.buff_id, TargetAttr#actor_fight_attr.buffs) of
		#p_actor_buf{value=PoisonValue} ->
			Buff2#p_buf.value >= PoisonValue andalso Buff2;
		_ ->
			Buff2
	end.

%%青龙盾，加毒抗
under_attack(?BUFF_QINGLONG_SHIELD, TargetAttr, Damage) ->
	Buffs = TargetAttr#actor_fight_attr.buffs,
	case lists:keyfind(?BUFF_QINGLONG_SHIELD, #p_actor_buf.buff_type, Buffs) of
		#p_actor_buf{remain_time=RemainTime1, value=Value} ->
			case lists:keyfind(?BUFF_POISON_RESIST, #p_actor_buf.buff_id, Buffs) of
				#p_actor_buf{remain_time=RemainTime2, value=OldResist} ->
					ignore;
				_ ->
					RemainTime2 = 0, OldResist = 0
			end,
			MaxHP = TargetAttr#actor_fight_attr.max_hp,
			ResistPoison = #p_buf{
				buff_id	   = ?BUFF_POISON_RESIST,
				buff_type  = ?BUFF_POISON_RESIST,
				last_value = max(RemainTime1, RemainTime2), 
				value      = round(OldResist + (Damage/MaxHP)*Value/10000)
			},
			add_buff2(TargetAttr, TargetAttr, [ResistPoison]),
			true;
		false ->
			false
	end;
%%白虎盾，加晕眩
under_attack(?BUFF_BAIHU_SHIELD, TargetAttr, Damage) ->
	Buffs = TargetAttr#actor_fight_attr.buffs,
	case lists:keyfind(?BUFF_BAIHU_SHIELD, #p_actor_buf.buff_type, Buffs) of
		#p_actor_buf{remain_time=RemainTime1, value=Value} ->
			case lists:keyfind(?BUFF_ADD_DIZZY, #p_actor_buf.buff_id, Buffs) of
				#p_actor_buf{remain_time=RemainTime2, value=OldDizzy} ->
					ignore;
				_ ->
					RemainTime2 = 0, OldDizzy = 0
			end,
			MaxHP = TargetAttr#actor_fight_attr.max_hp,
			AddDizzy = #p_buf{
				buff_id	   = ?BUFF_ADD_DIZZY,
				buff_type  = ?BUFF_ADD_DIZZY,
				last_value = max(RemainTime1, RemainTime2), 
				value      = round(OldDizzy + (Damage/MaxHP)*Value/10000)
			},
			add_buff2(TargetAttr, TargetAttr, [AddDizzy]),
			true;
		false ->
			false
	end;
%%玄武盾，加晕抗
under_attack(?BUFF_XUANWU_SHIELD, TargetAttr, Damage) ->
	Buffs = TargetAttr#actor_fight_attr.buffs,
	case lists:keyfind(?BUFF_XUANWU_SHIELD, #p_actor_buf.buff_type, Buffs) of
		#p_actor_buf{remain_time=RemainTime1, value=Value} ->
			case lists:keyfind(?BUFF_DIZZY_RESIST, #p_actor_buf.buff_id, Buffs) of
				#p_actor_buf{remain_time=RemainTime2, value=OldResist} ->
					ignore;
				_ ->
					RemainTime2 = 0, OldResist = 0
			end,
			MaxHP = TargetAttr#actor_fight_attr.max_hp,
			ResistPoison = #p_buf{
				buff_id	   = ?BUFF_DIZZY_RESIST,
				buff_type  = ?BUFF_DIZZY_RESIST,
				last_value = max(RemainTime1, RemainTime2), 
				value      = round(OldResist + (Damage/MaxHP)*Value/10000)
			},
			add_buff2(TargetAttr, TargetAttr, [ResistPoison]),
			true;
		false ->
			false
	end;
%%朱雀盾,加毒伤
under_attack(?BUFF_ZHUQUE_SHIELD, TargetAttr, Damage) ->
	Buffs = TargetAttr#actor_fight_attr.buffs,
	case lists:keyfind(?BUFF_ZHUQUE_SHIELD, #p_actor_buf.buff_type, Buffs) of
		#p_actor_buf{remain_time=RemainTime1, value=Value} ->
			case lists:keyfind(?BUFF_ADD_POISON, #p_actor_buf.buff_id, Buffs) of
				#p_actor_buf{remain_time=RemainTime2, value=OldPoison} ->
					ignore;
				_ ->
					RemainTime2 = 0, OldPoison = 0
			end,
			MaxHP = TargetAttr#actor_fight_attr.max_hp,
			AddPoison = #p_buf{
				buff_id	   = ?BUFF_ADD_POISON,
				buff_type  = ?BUFF_ADD_POISON,
				last_value = max(RemainTime1, RemainTime2), 
				value      = round(OldPoison + (Damage/MaxHP)*Value/10000)
			},
			add_buff2(TargetAttr, TargetAttr, [AddPoison]),
			true;
		false ->
			false
	end.
		