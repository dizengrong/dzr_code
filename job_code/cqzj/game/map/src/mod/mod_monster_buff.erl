%%% -------------------------------------------------------------------
%%% Author  : xierongfeng
%%% Description : 怪物BUFF模块
%%%
%%% Created : 2013-5-21
%%% -------------------------------------------------------------------
-module (mod_monster_buff).

-export ([add_buff/3, add_buff/4, del_buff/2, del_buff_by_type/2]).

-export ([add_buff2/4, del_buff2/2]).

-export ([handle/2]).

-include ("mgeem.hrl").

-define(_buff_effect,	?FIGHT,	?FIGHT_BUFF_EFFECT,	#m_fight_buff_effect_toc).%}

add_buff(MonsterID, MonsterState, Buffs) ->
	add_buff(MonsterID, MonsterState, Buffs, {monster, MonsterID}).

add_buff(MonsterID, MonsterState, BuffID, ByWho) when is_integer(BuffID) ->
    add_buff(MonsterID, MonsterState, [BuffID], ByWho);
add_buff(MonsterID, MonsterState, Buffs, ByWho) when is_list(Buffs), Buffs =/= [] ->
	NewMonsterState = add_buff2(MonsterID, MonsterState, Buffs, ByWho),
	mod_map_monster:set_monster_state(MonsterID, NewMonsterState);
add_buff(_MonsterID, MonsterState, _, _) -> MonsterState.

add_buff2(MonsterID, MonsterState, BuffIDs = [B|_], ByWho) when is_integer(B) ->
	add_buff2(MonsterID, MonsterState, [begin 
		[Buff] = common_config_dyn:find(buffs, BuffID), Buff 
	end||BuffID <- BuffIDs], ByWho);
add_buff2(MonsterID, MonsterState, Buffs, ByWho) ->
	#monster_state{monster_info = OldMonster, buf_timer_ref = OldTimers} = MonsterState,
    case OldMonster#p_monster.state of
        ?DEAD_STATE -> 
        	MonsterState;
        _ ->
			{NewTimers, NewMonster} = add_buff3(MonsterID, OldTimers, OldMonster, Buffs, ByWho),
			MonsterState#monster_state{monster_info = NewMonster, buf_timer_ref = NewTimers}
	end.

add_buff3(MonsterID, OldTimers, OldMonster, Buffs, ByWho) ->
	lists:foldl(fun
		(Buff, {TimerAcc, MonsterAcc}) ->
			#p_buf{buff_id = BuffID, buff_type = BuffType} = Buff,
			NewActorBuff = transform(MonsterID, Buff, ByWho),
			#p_actor_buf{value = NewValue, end_time = NewEndtime} = NewActorBuff,
			case BuffType == 0 orelse 
					lists:keyfind(BuffType, #p_actor_buf.buff_type, MonsterAcc#p_monster.buffs) of
				OldActorBuff when is_record(OldActorBuff, p_actor_buf) ->
					#p_actor_buf{value = OldValue, end_time = OldEndtime} = OldActorBuff,
					case {NewValue, NewEndtime} > {OldValue, OldEndtime} of
						true ->
							{_, TimerAcc2} = start_buff(
								cancel_buff(TimerAcc, OldActorBuff), NewActorBuff, Buff),
							MonsterAcc2    = calc(MonsterAcc, '-', OldActorBuff, '+', NewActorBuff);
						_ ->
							TimerAcc2   = TimerAcc,
							MonsterAcc2 = MonsterAcc
					end;
				_ ->
					case BuffType =/= 0 orelse
							lists:keyfind(BuffID, #p_actor_buf.buff_id, MonsterAcc#p_monster.buffs) of
						OldActorBuff2 when is_record(OldActorBuff2, p_actor_buf) ->
							#p_actor_buf{value = OldValue, end_time = OldEndtime} = OldActorBuff2,
							case {NewValue, NewEndtime} > {OldValue, OldEndtime} of
								true ->
									{_, TimerAcc2} = start_buff(
										cancel_buff(TimerAcc, OldActorBuff2), NewActorBuff, Buff),
									MonsterAcc2    = calc(MonsterAcc, '-', OldActorBuff2, '+', NewActorBuff);
								_ ->
									{_, TimerAcc2} = TimerAcc,
									MonsterAcc2    = MonsterAcc
							end;
						_ ->
							{_, TimerAcc2} = start_buff(TimerAcc, NewActorBuff, Buff),
							MonsterAcc2    = calc(MonsterAcc, '+', NewActorBuff)
					end
			end,
			{TimerAcc2, MonsterAcc2}
	end, {OldTimers, OldMonster}, Buffs).

del_buff(MonsterState, BuffID) when is_integer(BuffID) ->
    del_buff(MonsterState, [BuffID]);
del_buff(MonsterState, BuffIDs = [B|_]) when is_integer(B) ->
	NewMonsterState = del_buff2(MonsterState, BuffIDs),
	mod_map_monster:set_monster_state(NewMonsterState);
del_buff(MonsterState, _) -> MonsterState.

del_buff2(MonsterState, BuffIDs) ->
	#monster_state{monster_info = OldMonster, buf_timer_ref = OldTimers} = MonsterState,
    case OldMonster#p_monster.state of
        ?DEAD_STATE -> 
        	MonsterState;
        _ ->
			{NewTimers, NewMonster} = del_buff3(OldTimers, OldMonster, BuffIDs),
			MonsterState#monster_state{monster_info = NewMonster, buf_timer_ref = NewTimers}
	end.

del_buff3(OldTimers, OldMonster, BuffIDs) ->
	OldBuffs = OldMonster#p_monster.buffs,
	lists:foldl(fun
		(BuffID, {TimerAcc, MonsterAcc}) ->
			case lists:keyfind(BuffID, #p_actor_buf.buff_id, OldBuffs) of
				OldActorBuff when is_record(OldActorBuff, p_actor_buf) ->
					{cancel_buff(TimerAcc, OldActorBuff), calc(MonsterAcc, '-', OldActorBuff)};
				_ ->
					{TimerAcc, MonsterAcc}
			end
	end, {OldTimers, OldMonster}, BuffIDs).

del_buff_by_type(MonsterState, Buff) when not is_list(Buff) ->
	del_buff_by_type(MonsterState, [Buff]);
del_buff_by_type(MonsterState, [Int]) when Int == 0; Int == -1 -> %% del all buffs
    #monster_state{monster_info = OldMonster, buf_timer_ref = OldTimers} = MonsterState,
    case OldMonster#p_monster.state of
        ?DEAD_STATE -> 
        	MonsterState;
        _ ->
			{NewTimers, NewMonster} = lists:foldl(fun
				(ActorBuff, {TimerAcc, MonsterAcc}) ->
					[Buff] = common_config_dyn:find(buffs, ActorBuff#p_actor_buf.buff_id),
					if 
						Int ==  0 andalso (Buff#p_buf.is_debuff orelse Buff#p_buf.can_remove);
						Int == -1 andalso  Buff#p_buf.is_debuff ->
							{cancel_buff(TimerAcc, ActorBuff), calc(MonsterAcc, '-', ActorBuff)};
						true ->
							{TimerAcc, MonsterAcc}
					end
		    end, {OldTimers, OldMonster}, OldMonster#p_monster.buffs),
			MonsterState#monster_state{monster_info = NewMonster, buf_timer_ref = NewTimers}
	end;
del_buff_by_type(MonsterState, BuffTypes) ->
    #monster_state{monster_info = OldMonster, buf_timer_ref = OldTimers} = MonsterState,
    case OldMonster#p_monster.state of
        ?DEAD_STATE -> 
        	MonsterState;
        _ ->
        	ActorBuffs = OldMonster#p_monster.buffs,
			{NewTimers, NewMonster} = lists:foldl(fun
				(BuffType, {TimerAcc, MonsterAcc}) ->
					case lists:keyfind(BuffType, #p_actor_buf.buff_type, ActorBuffs) of
						ActorBuff when is_record(ActorBuff, p_actor_buf) ->
							{cancel_buff(TimerAcc, ActorBuff), calc(MonsterAcc, '-', ActorBuff)};
						_ ->
							{TimerAcc, MonsterAcc}
			        end
		    end, {OldTimers, OldMonster}, BuffTypes),
			MonsterState#monster_state{monster_info = NewMonster, buf_timer_ref = NewTimers}
	end.

transform(MonsterID, Buff, {FromActorType, FromActorID}) ->
	NowTime = common_tool:now(),
	EndTime = if 
		Buff#p_buf.last_type == ?BUFF_LAST_TYPE_FOREVER_TIME;
		Buff#p_buf.last_type == ?BUFF_LAST_TYPE_SUMMONED_PET ->
			undefined;
		true ->
			NowTime + Buff#p_buf.last_value
	end,
    #p_actor_buf{
		buff_id         = Buff#p_buf.buff_id,
		buff_type       = Buff#p_buf.buff_type,
		actor_id        = MonsterID,
		actor_type      = ?TYPE_MONSTER,
		from_actor_id   = FromActorID,
		from_actor_type = mof_common:actor_type_int(FromActorType),
		remain_time     = Buff#p_buf.last_value,
		start_time      = NowTime,
		end_time        = EndTime,
		value           = Buff#p_buf.value
    }.

calc(Monster, Op1, Buff1, Op2, Buff2) ->
	calc(calc(Monster, Op1, Buff1), Op2, Buff2).

calc(Monster1, '+', ActorBuff) ->
	Monster2 = Monster1#p_monster{buffs = [ActorBuff|Monster1#p_monster.buffs]},
	mod_monster_attr:calc(Monster2, '+', mod_buff_attr:transform(ActorBuff));
calc(Monster1, '-', ActorBuff) ->
	Monster2 = Monster1#p_monster{buffs = 
		lists:keydelete(ActorBuff#p_actor_buf.buff_id, #p_actor_buf.buff_id, Monster1#p_monster.buffs)},
	mod_monster_attr:calc(Monster2, '-', mod_buff_attr:transform(ActorBuff)).

start_buff(BuffTimers, ActorBuff = #p_actor_buf{buff_id=BuffID, 
		actor_id=MonsterID, remain_time=RemainTime, end_time=EndTime}, Buff) ->
	NowTime = common_tool:now(),
	DestPID = self(),
	Message = {buff_timeout, monster, MonsterID, BuffID},
	BufTime = case Buff#p_buf.last_type of
		?BUFF_LAST_TYPE_REAL_TIME ->
			EndTime - NowTime;
		?BUFF_LAST_TYPE_FOREVER_TIME ->
			undefined;
		?BUFF_LAST_TYPE_ONLINE_TIME ->
			EndTime > NowTime andalso RemainTime;
		?BUFF_LAST_TYPE_REAL_INTERVAL_TIME ->
			EndTime > NowTime andalso Buff#p_buf.last_interval;
		?BUFF_LAST_TYPE_SUMMONED_PET ->
			undefined
	end,
	if
		is_integer(BufTime), BufTime > 0 ->
			BuffTimer = erlang:start_timer(BufTime*1000, DestPID, Message),
			{ActorBuff, lists:keystore(BuffID, 1, BuffTimers, {BuffID, BuffTimer})};
		BufTime == undefined ->
			{ActorBuff, BuffTimers};
		true ->
			{undefined, BuffTimers}
	end.

cancel_buff(BuffTimers, #p_actor_buf{buff_id=BuffID}) ->
	case lists:keyfind(BuffID, 1, BuffTimers) of
		Timer when is_reference(Timer) ->
			erlang:cancel_timer(Timer),
			lists:keydelete(BuffID, 1, BuffTimers);
		_ ->
			BuffTimers
	end.

handle({buff_timeout, TimerRef, MonsterID, BuffID}, _State) ->
	case mod_map_monster:get_monster_state(MonsterID) of
		MonsterState = #monster_state{monster_info = OldMonster, buf_timer_ref = OldTimers} ->
			OldActorBuff = lists:keyfind(BuffID, #p_actor_buf.buff_id, OldMonster#p_monster.buffs),
			case is_record(OldActorBuff, p_actor_buf) andalso
					OldMonster#p_monster.state =/= ?DEAD_STATE andalso 
					lists:keyfind(BuffID, 1, OldTimers) of
				{BuffID, TimerRef} ->
					[Buff] = common_config_dyn:find(buffs, BuffID),
					{NewActorBuff, NewTimers} = start_buff(OldTimers, OldActorBuff, Buff),
					NewMonster = if
						not is_record(NewActorBuff, p_actor_buf) ->
							calc(OldMonster, '-', OldActorBuff);
						true ->
							keyreplace(NewActorBuff, OldMonster)
					end,
					NewMonsterState = MonsterState#monster_state{
						monster_info = NewMonster, buf_timer_ref = NewTimers},
					mod_map_monster:set_monster_state(MonsterID, NewMonsterState),
					case Buff#p_buf.last_type of 
						?BUFF_LAST_TYPE_REAL_INTERVAL_TIME ->
							{ok, Func} = mod_skill_manager:get_buff_func_by_type(Buff#p_buf.buff_type),
							handle_buff_func({Func, 
								NewMonsterState, Buff#p_buf.absolute_or_rate, OldActorBuff});
						_ ->
							ignore
					end;
				_ ->
					ignore
			end;
		_ ->
			ignore
	end;

handle(_, _) -> ignore.

handle_buff_func({poisoning, MonsterState, Aor, ActorBuff}) ->
	#p_actor_buf{value = Value} = ActorBuff,
	Damage = case Aor of 
        ?TYPE_ABSOLUTE -> 
            Value;
        ?TYPE_PERCENT -> 
        	#monster_state{monster_info = Monster} = MonsterState,
            common_tool:ceil(Monster#p_monster.max_hp * Value / 10000 ) 
    end,
    reduce_hp(MonsterState, Damage, ActorBuff);

handle_buff_func({burning, MonsterState, Aor, ActorBuff}) ->
	#p_actor_buf{value = Value} = ActorBuff,
	Damage = case Aor of 
        ?TYPE_ABSOLUTE -> 
            Value;
        ?TYPE_PERCENT -> 
            #monster_state{monster_info = Monster} = MonsterState,
            common_tool:ceil(Monster#p_monster.max_hp * Value / 10000 ) 
    end,
    reduce_hp(MonsterState, Damage, ActorBuff);

handle_buff_func(_) -> ignore.

keyreplace(Buff, Monster) when is_record(Buff, p_actor_buf) ->
	NewBuffs = lists:keyreplace(Buff#p_actor_buf.buff_id, 
					#p_actor_buf.buff_id, Monster#p_monster.buffs, Buff),
	Monster#p_monster{buffs = NewBuffs};
keyreplace(_, Monster) -> Monster.

reduce_hp(MonsterState, Damage, Buff) ->
	#monster_state{monster_info = Monster} = MonsterState,
	MonsterID = Monster#p_monster.monsterid,
	#p_actor_buf{from_actor_id = FromActorID, from_actor_type = FromActorType} = Buff,
    mgeem_map:do_broadcast_insence_include([{monster, MonsterID}], ?_buff_effect{
		buff_effect = [#p_buff_effect{
			effect_type  = ?BUFF_INTERVAL_EFFECT_REDUCE_HP, 
			effect_value = Damage, 
			buff_type    = Buff#p_actor_buf.buff_type
		}],
		actor_id    = MonsterID,
		actor_type  = ?TYPE_MONSTER,
		src_id      = FromActorID,
		src_type    = FromActorType
	}),
	FromActorType2 = mof_common:actor_type_atom(FromActorType),
	mod_map_monster:attack_monster(MonsterState, {FromActorID, FromActorType2, Damage}).
