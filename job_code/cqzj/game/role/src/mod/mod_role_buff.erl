%%% -------------------------------------------------------------------
%%% Author  : xierongfeng
%%% Description : 玩家BUFF模块
%%%
%%% Created : 2013-5-21
%%% -------------------------------------------------------------------

-module(mod_role_buff).

-define(_common_error,	?DEFAULT_UNIQUE,	?COMMON,	?COMMON_ERROR,		#m_common_error_toc).%}
-define(_buff_effect,						?FIGHT,     ?FIGHT_BUFF_EFFECT, #m_fight_buff_effect_toc).%}

-export([add_buff/2, add_buff/3, del_buff/2, del_buff_by_type/2]).
-export([add_buff2/2, add_buff2/3, del_buff2/2, has_buff/2, has_any_buff/2]).
-export([handle/2, hook_role_online/1, hook_role_offline/1, hook_mirror_enter/1,  calc/3, recalc/2]).

-include("mgeer.hrl").

add_buff(RoleID, Buff) ->
	add_buff(RoleID, Buff, {role, RoleID}).

add_buff(RoleID, BuffID, ByWho) when is_integer(BuffID) ->
    add_buff(RoleID, [BuffID], ByWho);
add_buff(RoleID, Buffs,  ByWho) when is_list(Buffs), Buffs =/= [] ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	mod_role_attr:reload_role_base(add_buff2(RoleBase, Buffs, ByWho));
add_buff(_, _, _) -> ignore.

add_buff2(RoleBase, [])    -> RoleBase;
add_buff2(RoleBase, Buffs) ->
	add_buff2(RoleBase, Buffs, {role, RoleBase#p_role_base.role_id}).

add_buff2(RoleBase, BuffIDs = [B|_], ByWho) when is_integer(B) ->
	add_buff2(RoleBase, [begin 
		[Buff] = common_config_dyn:find(buffs, BuffID), Buff 
	end||BuffID <- BuffIDs], ByWho);
add_buff2(RoleBase1, Buffs, ByWho) ->
	RoleID = RoleBase1#p_role_base.role_id,	
	lists:foldl(fun
		(Buff, RoleBaseAcc) ->
			#p_buf{buff_id = BuffID, buff_type = BuffType} = Buff,
			NewActorBuff = transform(RoleID, Buff, ByWho),
			#p_actor_buf{value = NewValue, end_time = NewEndtime} = NewActorBuff,
			case BuffType == 0 orelse 
					lists:keyfind(BuffType, #p_actor_buf.buff_type, RoleBaseAcc#p_role_base.buffs) of
				OldActorBuff when is_record(OldActorBuff, p_actor_buf) ->
					#p_actor_buf{value = OldValue, end_time = OldEndtime} = OldActorBuff,
					case Buff#p_buf.kind of
						?BUFF_KIND_ADD_UP_TIME -> 
							cancel_buff(OldActorBuff),
							NewActorBuff2 = NewActorBuff#p_actor_buf{
								end_time = NewEndtime + max(0, OldEndtime - common_tool:now())
							},
							start_buff(NewActorBuff2, Buff),
							calc(RoleBaseAcc, '-', OldActorBuff, '+', NewActorBuff2);
						_ ->
							case {NewValue, NewEndtime} > {OldValue, OldEndtime} of
								true ->
									cancel_buff(OldActorBuff),
									start_buff(NewActorBuff, Buff),
									calc(RoleBaseAcc, '-', OldActorBuff, '+', NewActorBuff);
								_ ->
									RoleBaseAcc
							end
					end;
				_ ->
					case BuffType == 0 andalso 
							lists:keyfind(BuffID, #p_actor_buf.buff_id, RoleBaseAcc#p_role_base.buffs) of
						OldActorBuff2 when is_record(OldActorBuff2, p_actor_buf) ->
							#p_actor_buf{value = OldValue, end_time = OldEndtime} = OldActorBuff2,
							case {NewValue, NewEndtime} > {OldValue, OldEndtime} of
								true ->
									cancel_buff(OldActorBuff2),
									start_buff(NewActorBuff, Buff),
									calc(RoleBaseAcc, '-', OldActorBuff2, '+', NewActorBuff);
								_ ->
									RoleBaseAcc
							end;
						_ ->
							start_buff(NewActorBuff, Buff),
							calc(RoleBaseAcc, '+', NewActorBuff)
					end	
			end
	end, RoleBase1, Buffs).

del_buff(RoleID, BuffID) when is_integer(BuffID) ->
    del_buff(RoleID, [BuffID]);
del_buff(RoleID, BuffIDs = [B|_]) when is_integer(B) ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	mod_role_attr:reload_role_base(del_buff2(RoleBase, BuffIDs));
del_buff(_, _) -> ignore.

del_buff2(RoleBase, [])      -> RoleBase;
del_buff2(RoleBase, BuffIDs) ->
	#p_role_base{buffs = OldBuffs} = RoleBase,
	lists:foldl(fun
		(BuffID, RoleBaseAcc) ->
			case lists:keyfind(BuffID, #p_actor_buf.buff_id, OldBuffs) of
				OldActorBuff when is_record(OldActorBuff, p_actor_buf) ->
					cancel_buff(OldActorBuff),
					calc(RoleBaseAcc, '-', OldActorBuff);
				_ ->
					RoleBaseAcc
			end
	end, RoleBase, BuffIDs).

del_buff_by_type(RoleID, Buff) when not is_list(Buff) ->
	del_buff_by_type(RoleID, [Buff]);
del_buff_by_type(RoleID, [Int]) when Int == 0; Int == -1 -> %% del all buffs
	{ok, RoleBase1} = mod_map_role:get_role_base(RoleID),
    {DelAnyBuff, RoleBase2} = lists:foldl(fun
		(ActorBuff, {DelAnyBuffTmp, RoleBaseAcc}) ->
			[Buff] = common_config_dyn:find(buffs, ActorBuff#p_actor_buf.buff_id),
			if 
				Int ==  0 andalso (Buff#p_buf.is_debuff orelse Buff#p_buf.can_remove);
				Int == -1 andalso  Buff#p_buf.is_debuff ->
					cancel_buff(ActorBuff),
					{true, calc(RoleBaseAcc, '-', ActorBuff)};
				true ->
					{DelAnyBuffTmp, RoleBaseAcc}
			end
    end, {false, RoleBase1}, RoleBase1#p_role_base.buffs),
    DelAnyBuff andalso mod_role_attr:reload_role_base(RoleBase2);
del_buff_by_type(RoleID, BuffTypes) when is_list(BuffTypes), BuffTypes =/= [] ->
	{ok, RoleBase1} = mod_map_role:get_role_base(RoleID),
    #p_role_base{buffs = ActorBuffs} = RoleBase1,
    {DelAnyBuff, RoleBase2} = lists:foldl(fun
		(BuffType, {DelAnyBuffTmp, RoleBaseAcc}) ->
	        case lists:keyfind(BuffType, #p_actor_buf.buff_type, ActorBuffs) of
				ActorBuff when is_record(ActorBuff, p_actor_buf) ->
					cancel_buff(ActorBuff),
					{true, calc(RoleBaseAcc, '-', ActorBuff)};
				_ ->
					{DelAnyBuffTmp, RoleBaseAcc}
	        end
    end, {false, RoleBase1}, BuffTypes),
    DelAnyBuff andalso mod_role_attr:reload_role_base(RoleBase2);
del_buff_by_type(_RoleID, _BuffTypes) -> ignore.

has_buff(RoleID, BuffID) ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	lists:keymember(BuffID, #p_actor_buf.buff_id, RoleBase#p_role_base.buffs).

has_any_buff(RoleID, BuffIDList) ->
	case mod_map_role:get_role_base(RoleID) of
		{ok, RoleBase} ->
			has_any_buff2(RoleBase#p_role_base.buffs, BuffIDList);
		_ ->
			false
	end.

has_any_buff2(_, []) -> false;
has_any_buff2(ActorBuffList, [BuffID | Rest]) ->
	case lists:keymember(BuffID, #p_actor_buf.buff_id, ActorBuffList) of
		true -> {true, BuffID};
		false -> has_any_buff2(ActorBuffList, Rest)
	end.

calc(RoleBase, Op1, Buff1, Op2, Buff2) ->
	calc(calc(RoleBase, Op1, Buff1), Op2, Buff2).

calc(RoleBase1, '+', ActorBuff) ->
	RoleBuffs1 = RoleBase1#p_role_base.buffs,
	RoleBase2  = RoleBase1#p_role_base{buffs = [ActorBuff|RoleBuffs1]},
	RoleBase3  = mod_role_attr:calc(RoleBase2, '+', mod_buff_attr:transform(ActorBuff)),
	mod_special_buff:calc(RoleBase3, '+', ActorBuff);
calc(RoleBase1, '-', ActorBuff) ->
	RoleBuffs1 = RoleBase1#p_role_base.buffs,
	RoleBase2  = RoleBase1#p_role_base{buffs = 
		lists:keydelete(ActorBuff#p_actor_buf.buff_id, #p_actor_buf.buff_id, RoleBuffs1)},
	RoleBase3  = mod_role_attr:calc(RoleBase2, '-', mod_buff_attr:transform(ActorBuff)),
	mod_special_buff:calc(RoleBase3, '-', ActorBuff).

transform(RoleID, Buff, {FromActorType, FromActorID}) ->
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
		actor_id        = RoleID,
		actor_type      = ?TYPE_ROLE,
		from_actor_id   = FromActorID,
		from_actor_type = mof_common:actor_type_int(FromActorType),
		remain_time     = Buff#p_buf.last_value,
		start_time      = NowTime,
		end_time        = EndTime,
		value           = Buff#p_buf.value
    }.

start_buff(ActorBuff = #p_actor_buf{buff_id=BuffID, 
		actor_id=RoleID, remain_time=RemainTime, end_time=EndTime}, Buff) ->
	NowTime = common_tool:now(),
	DestPID = global:whereis_name(mgeer_role:proc_name(RoleID)),
	Message = {buff_timeout, role, RoleID, BuffID},
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
			mod_role_tab:put(RoleID, {buff_timer, role, RoleID, BuffID}, BuffTimer),
			ActorBuff;
		BufTime == undefined ->
			ActorBuff;
		true ->
			undefined
	end.

cancel_buff(#p_actor_buf{buff_id=BuffID, actor_id=RoleID}) ->
	case mod_role_tab:erase(RoleID, {buff_timer, role, RoleID, BuffID}) of
		Timer when is_reference(Timer) ->
			erlang:cancel_timer(Timer);
		_ ->
			ignore
	end.

handle({buff_timeout, TimerRef, RoleID, BuffID}, _State) ->
	{ok, RoleBase1} = mod_map_role:get_role_base(RoleID),
	OldActorBuff = lists:keyfind(BuffID, #p_actor_buf.buff_id, RoleBase1#p_role_base.buffs),
	case is_record(OldActorBuff, p_actor_buf) andalso 
			mod_role_tab:erase(RoleID, {buff_timer, role, RoleID, BuffID}) of
		TimerRef ->
			[Buff] = common_config_dyn:find(buffs, BuffID),
			NewActorBuff = start_buff(OldActorBuff, Buff),
			RoleBase2 = if
				not is_record(NewActorBuff, p_actor_buf) ->
					RB2 = calc(RoleBase1, '-', OldActorBuff),
					mod_role_attr:reload_role_base(RB2),
					RB2;
				true ->
					keyreplace(NewActorBuff, RoleBase1)
			end,
			case Buff#p_buf.last_type of
				?BUFF_LAST_TYPE_REAL_INTERVAL_TIME ->
					mod_role_tab:put({?role_base, RoleID}, RoleBase2),
					{ok, Func} = mod_skill_manager:get_buff_func_by_type(Buff#p_buf.buff_type),
					handle_buff_func({Func, 
						RoleBase2, Buff#p_buf.absolute_or_rate, OldActorBuff});
				_ ->
					mod_role_attr:reload_role_base(RoleBase2)
			end;
		_ ->
			ignore
	end;

handle({reduce_hp, RoleID, Damage, Buff}, MapState) ->
	#p_actor_buf{from_actor_id = FromActorID, from_actor_type = FromActorType} = Buff,
    mgeem_map:do_broadcast_insence_include([{role, RoleID}], ?_buff_effect{
		buff_effect = [#p_buff_effect{
			effect_type  = ?BUFF_INTERVAL_EFFECT_REDUCE_HP, 
			effect_value = Damage, 
			buff_type    = Buff#p_actor_buf.buff_type
		}],
		actor_id    = RoleID,
		actor_type  = ?TYPE_ROLE,
		src_id      = FromActorID,
		src_type    = FromActorType
	}, MapState),
	FromActorType2 = mof_common:actor_type_atom(FromActorType),
    mod_map_role:do_role_reduce_hp(RoleID, 
    	Damage, "", FromActorID, FromActorType2, MapState);

handle({add_hp, RoleID, AddHP0, Vigour, Buff}, MapState) ->
	Week  = mod_buff:get_week(role, RoleID, common_tool:now()),
	AddHP = AddHP0*(1+Vigour/10000-Week/10000),
	#p_actor_buf{from_actor_id = FromActorID, from_actor_type = FromActorType} = Buff,
    mgeem_map:do_broadcast_insence_include([{role, RoleID}], ?_buff_effect{
		buff_effect = [#p_buff_effect{
			effect_type  = ?BUFF_INTERVAL_EFFECT_ADD_HP, 
			effect_value = AddHP, 
			buff_type    = Buff#p_actor_buf.buff_type
		}],
		actor_id    = RoleID,
		actor_type  = ?TYPE_ROLE,
		src_id      = FromActorID,
		src_type    = FromActorType
	}, MapState),
    mod_map_role:do_role_add_hp(RoleID, AddHP, FromActorID);

handle(Msg, _) ->
	?ERROR_MSG("unhandled, msg: ~w", [Msg]).

handle_buff_func({poisoning, RoleBase, Aor, ActorBuff}) ->
	#p_role_base{role_id = RoleID, 
		max_hp = MaxHP, poisoning_resist = Resist} = RoleBase,
	#p_actor_buf{value = Value} = ActorBuff,
	Damage = case Aor of 
        ?TYPE_ABSOLUTE -> 
            common_tool:ceil(Value * (1 - Resist/100));
        ?TYPE_PERCENT -> 
            common_tool:ceil(MaxHP * Value / 10000 * (1 - Resist/100)) 
    end,
    mgeem_map:send({mod, ?MODULE, {reduce_hp, RoleID, Damage, ActorBuff}});

handle_buff_func({burning, RoleBase, Aor, ActorBuff}) ->
	#p_role_base{role_id = RoleID, max_hp = MaxHP} = RoleBase,
	#p_actor_buf{value = Value} = ActorBuff,
	Damage = case Aor of 
        ?TYPE_ABSOLUTE -> 
            Value;
        ?TYPE_PERCENT -> 
            common_tool:ceil(MaxHP * Value / 10000)
    end,
    mgeem_map:send({mod, ?MODULE, {reduce_hp, RoleID, Damage, ActorBuff}});

handle_buff_func({add_hp, RoleBase, Aor, ActorBuff}) ->
	#p_role_base{role_id = RoleID, max_hp = MaxHP, vigour = Vigour} = RoleBase,
	#p_actor_buf{value = Value} = ActorBuff,
	AddHP = case Aor of 
		?TYPE_ABSOLUTE -> 
			Value;
		?TYPE_PERCENT ->
			common_tool:ceil(MaxHP * Value / 10000)
	end,
    mgeem_map:send({mod, ?MODULE, {add_hp, RoleID, AddHP, Vigour, ActorBuff}});

handle_buff_func({add_nuqi, RoleBase, _Aor, ActorBuff}) ->
	#p_role_base{role_id = RoleID} = RoleBase,
	#p_actor_buf{value = Value} = ActorBuff,
	mgeem_map:run(fun() -> mod_map_role:add_nuqi(RoleID, Value) end);

handle_buff_func(Msg) ->
	?ERROR_MSG("unhandled buff function, msg: ~w", [Msg]).

hook_role_online(RoleID) ->
	NowTime = common_tool:now(),
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	{BuffTimeout, NewRoleBase} = lists:foldl(fun
		(ActorBuff, {BuffTimeoutTmp, RoleBaseAcc}) ->
			#p_actor_buf{buff_id = BuffID, remain_time = RemainTime, end_time = EndTime} = ActorBuff, 
			[Buff] = common_config_dyn:find(buffs, BuffID),
			IsOnlineBuff = Buff#p_buf.last_type == ?BUFF_LAST_TYPE_ONLINE_TIME,
			if
				is_integer(EndTime) andalso EndTime < NowTime; 
				IsOnlineBuff andalso RemainTime =< 0 ->
					{true, calc(RoleBaseAcc, '-', ActorBuff)};
				true ->
					ActorBuff2 = case IsOnlineBuff of
						true ->
							start_buff(ActorBuff#p_actor_buf{end_time = NowTime + RemainTime}, Buff);
						_ ->
							start_buff(ActorBuff, Buff)
					end,
					{BuffTimeoutTmp, keyreplace(ActorBuff2, RoleBaseAcc)}
			end
	end, {false, RoleBase}, RoleBase#p_role_base.buffs),
	if
		BuffTimeout ->
			mod_role_attr:reload_role_base(NewRoleBase);
		true ->
			mod_role_tab:put({?role_base, RoleID}, NewRoleBase)
	end.

hook_role_offline(RoleID) ->
	NowTime = common_tool:now(),
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	RoleBuffs = lists:foldl(fun
		(ActorBuff, BuffsAcc) ->
			#p_actor_buf{buff_id = BuffID, end_time = EndTime} = ActorBuff, 
			[Buff] = common_config_dyn:find(buffs, BuffID),
			case Buff#p_buf.last_type of
				?BUFF_LAST_TYPE_ONLINE_TIME ->
					[ActorBuff#p_actor_buf{remain_time = EndTime - NowTime}|BuffsAcc];
				_ ->
					[ActorBuff|BuffsAcc]
			end
	end, [], RoleBase#p_role_base.buffs),
	mod_role_tab:put({?role_base, RoleID}, RoleBase#p_role_base{buffs = RoleBuffs}).

hook_mirror_enter(RoleBase) ->
	NowTime = common_tool:now(),
	lists:foldl(fun
		(ActorBuff, RoleBaseAcc) ->
			#p_actor_buf{buff_id = BuffID, end_time = EndTime} = ActorBuff, 
			if
				is_integer(EndTime) andalso EndTime < NowTime ->
					calc(RoleBaseAcc, '-', ActorBuff);
				true ->
					case common_config_dyn:find(buffs, BuffID) of
						[Buff] ->
							keyreplace(start_buff(ActorBuff, Buff), RoleBaseAcc);
						_ ->
							RoleBaseAcc
					end
			end
	end, RoleBase, RoleBase#p_role_base.buffs).

keyreplace(Buff, RoleBase) when is_record(Buff, p_actor_buf) ->
	NewBuffs = lists:keyreplace(Buff#p_actor_buf.buff_id, 
					#p_actor_buf.buff_id, RoleBase#p_role_base.buffs, Buff),
	RoleBase#p_role_base{buffs = NewBuffs};
keyreplace(_, RoleBase) -> RoleBase.

recalc(RoleBase, _RoleAttr) ->
	lists:foldl(fun(ActorBuff, RoleBaseAcc) ->
		cancel_buff(ActorBuff),
		case common_config_dyn:find(buffs, ActorBuff#p_actor_buf.buff_id) of
			[Buff] ->
				case start_buff(ActorBuff, Buff) of
					ActorBuff when is_record(ActorBuff, p_actor_buf) ->
						calc(RoleBaseAcc, '+', ActorBuff);
					_ ->
						RoleBaseAcc
				end;
			_ ->
				RoleBaseAcc
		end
	end, RoleBase#p_role_base{buffs = []}, RoleBase#p_role_base.buffs).