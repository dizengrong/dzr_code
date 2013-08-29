%%% -------------------------------------------------------------------
%%% Author  : xierongfeng
%%% Description : 宠物BUFF模块
%%%
%%% Created : 2013-5-21
%%% -------------------------------------------------------------------
-module (mod_pet_buff).

-export ([add_buff/2, add_buff/3, del_buff/2, del_buff_by_type/2]).

-export ([add_buff2/2, add_buff2/3, del_buff2/2]).

-export ([handle/2, recalc/1]).

-include ("mgeer.hrl").

-define(_common_error,	?DEFAULT_UNIQUE,	?COMMON,	?COMMON_ERROR,		#m_common_error_toc).%}
-define(_buff_effect,						?FIGHT,     ?FIGHT_BUFF_EFFECT, #m_fight_buff_effect_toc).%}

add_buff(Pet, Buffs) ->
	add_buff(Pet, Buffs, {pet, Pet#p_pet.pet_id}).

add_buff(Pet, BuffID, ByWho) when is_integer(BuffID) ->
    add_buff(Pet, [BuffID], ByWho);
add_buff(Pet, Buffs = [B|_], ByWho) when is_record(B, p_buf) ->
	reload_pet_and_role_base(Pet#p_pet.role_id, Pet, add_buff2(Pet, Buffs, ByWho));
add_buff(Pet, Buffs = [B|_], ByWho)  when is_integer(B) ->
	reload_pet_and_role_base(Pet#p_pet.role_id, Pet, add_buff2(Pet, Buffs, ByWho));
add_buff(Pet, _, _) -> Pet.

add_buff2(Pet, Buffs) ->
	add_buff2(Pet, Buffs, {pet, Pet#p_pet.pet_id}).

add_buff2(Pet, BuffIDs = [B|_], ByWho) when is_integer(B) ->
	add_buff2(Pet, [begin 
		[Buff] = common_config_dyn:find(buffs, BuffID), Buff 
	end||BuffID <- BuffIDs], ByWho);
add_buff2(Pet, Buffs, ByWho) ->
	#p_pet{pet_id = PetID, role_id = RoleID} = Pet,
	lists:foldl(fun
		(Buff, PetAcc) ->
			#p_buf{buff_id = BuffID, buff_type = BuffType} = Buff,
			NewActorBuff = transform(PetID, Buff, ByWho),
			#p_actor_buf{value = NewValue, end_time = NewEndtime} = NewActorBuff,
			case BuffType == 0 orelse 
					lists:keyfind(BuffType, #p_actor_buf.buff_type, PetAcc#p_pet.buffs) of
				OldActorBuff when is_record(OldActorBuff, p_actor_buf) ->
					#p_actor_buf{value = OldValue, end_time = OldEndtime} = OldActorBuff,
					case {NewValue, NewEndtime} > {OldValue, OldEndtime} of
						true ->
							cancel_buff(RoleID, OldActorBuff),
							start_buff(RoleID, NewActorBuff, Buff),
							calc(PetAcc, '-', OldActorBuff, '+', NewActorBuff);
						_ ->
							PetAcc
					end;
				_ ->
					case BuffType == 0 andalso
							lists:keyfind(BuffID, #p_actor_buf.buff_id, PetAcc#p_pet.buffs) of
						OldActorBuff2 when is_record(OldActorBuff2, p_actor_buf) ->
							#p_actor_buf{value = OldValue, end_time = OldEndtime} = OldActorBuff2,
							case {NewValue, NewEndtime} > {OldValue, OldEndtime} of
								true ->
									cancel_buff(RoleID, OldActorBuff2),
									start_buff(RoleID, NewActorBuff, Buff),
									calc(PetAcc, '-', OldActorBuff2, '+', NewActorBuff);
								_ ->
									PetAcc
							end;
						_ ->
							start_buff(RoleID, NewActorBuff, Buff),
							calc(PetAcc, '+', NewActorBuff)
					end
			end
	end, Pet, Buffs).

del_buff(Pet, BuffID) when is_integer(BuffID) ->
    del_buff(Pet, [BuffID]);
del_buff(Pet, BuffIDs = [B|_]) when is_integer(B) ->
	reload_pet_and_role_base(Pet#p_pet.role_id, Pet, del_buff2(Pet, BuffIDs));
del_buff(Pet, _) -> Pet.

del_buff2(Pet, BuffIDs) ->
	#p_pet{role_id = RoleID, buffs = OldBuffs} = Pet,
	lists:foldl(fun
		(BuffID, PetAcc) ->
			case lists:keyfind(BuffID, #p_actor_buf.buff_id, OldBuffs) of
				OldActorBuff when is_record(OldActorBuff, p_actor_buf) ->
					cancel_buff(RoleID, OldActorBuff),
					calc(PetAcc, '-', OldActorBuff);
				_ ->
					PetAcc
			end
	end, Pet, BuffIDs).

del_buff_by_type(Pet, Buff) when not is_list(Buff) ->
	del_buff_by_type(Pet, [Buff]);
del_buff_by_type(Pet, [Int]) when Int == 0; Int == -1 -> %% del all buffs
	#p_pet{role_id = RoleID} = Pet,
    {DelAnyBuff, Pet2} = lists:foldl(fun
		(ActorBuff, {DelAnyBuffTmp, PetAcc}) ->
			[Buff] = common_config_dyn:find(buffs, ActorBuff#p_actor_buf.buff_id),
			if 
				Int ==  0 andalso (Buff#p_buf.is_debuff orelse Buff#p_buf.can_remove);
				Int == -1 andalso  Buff#p_buf.is_debuff ->
					cancel_buff(RoleID, ActorBuff),
					{true, calc(PetAcc, '-', ActorBuff)};
				true ->
					{DelAnyBuffTmp, PetAcc}
			end
    end, {false, Pet}, Pet#p_pet.buffs),
    DelAnyBuff andalso reload_pet_and_role_base(RoleID, Pet, Pet2);
del_buff_by_type(Pet, BuffTypes) ->
    #p_pet{role_id = RoleID, buffs = ActorBuffs} = Pet,
    {DelAnyBuff, Pet2} = lists:foldl(fun
		(BuffType, {DelAnyBuffTmp, PetAcc}) ->
	        case lists:keyfind(BuffType, #p_actor_buf.buff_type, ActorBuffs) of
				ActorBuff when is_record(ActorBuff, p_actor_buf) ->
					cancel_buff(RoleID, ActorBuff),
					{true, calc(PetAcc, '-', ActorBuff)};
				_ ->
					{DelAnyBuffTmp, PetAcc}
	        end
    end, {false, Pet}, BuffTypes),
    DelAnyBuff andalso reload_pet_and_role_base(RoleID, Pet, Pet2).

reload_pet_and_role_base(RoleID, OldPet, NewPet) ->
	mod_role_pet:update_role_base(RoleID, '-', OldPet, '+', NewPet),
	mod_pet_attr:reload_pet_info(NewPet),
	NewPet.

transform(PetID, Buff, {FromActorType, FromActorID}) ->
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
		actor_id        = PetID,
		actor_type      = ?TYPE_PET,
		from_actor_id   = FromActorID,
		from_actor_type = mof_common:actor_type_int(FromActorType),
		remain_time     = Buff#p_buf.last_value,
		start_time      = NowTime,
		end_time        = EndTime,
		value           = Buff#p_buf.value
    }.

calc(Pet, Op1, Buff1, Op2, Buff2) ->
	calc(calc(Pet, Op1, Buff1), Op2, Buff2).

calc(Pet1, '+', ActorBuff) ->
	Pet2  = Pet1#p_pet{buffs = [ActorBuff|Pet1#p_pet.buffs]},
	mod_pet_attr:calc(Pet2, '+', mod_buff_attr:transform(ActorBuff));
calc(Pet1, '-', ActorBuff) ->
	Pet2  = Pet1#p_pet{buffs = 
		lists:keydelete(ActorBuff#p_actor_buf.buff_id, #p_actor_buf.buff_id, Pet1#p_pet.buffs)},
	mod_pet_attr:calc(Pet2, '-', mod_buff_attr:transform(ActorBuff)).

start_buff(RoleID, ActorBuff = #p_actor_buf{buff_id=BuffID, 
		actor_id=PetID, remain_time=RemainTime, end_time=EndTime}, Buff) ->
	NowTime = common_tool:now(),
	DestPID = global:whereis_name(mgeer_role:proc_name(RoleID)),
	Message = {buff_timeout, pet, PetID, BuffID},
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
			mod_role_tab:put(RoleID, {buff_timer, pet, PetID, BuffID}, BuffTimer),
			ActorBuff;
		BufTime == undefined ->
			ActorBuff;
		true ->
			undefined
	end.

cancel_buff(RoleID, #p_actor_buf{buff_id=BuffID, actor_id=PetID}) ->
	case mod_role_tab:erase(RoleID, {buff_timer, pet, PetID, BuffID}) of
		Timer when is_reference(Timer) ->
			erlang:cancel_timer(Timer);
		_ ->
			ignore
	end.

handle({buff_timeout, TimerRef, PetID, BuffID}, _State) ->
	RoleID = get(role_id),
	Pet    = mod_role_tab:get(RoleID, {?ROLE_PET_INFO, PetID}),
	OldActorBuff = lists:keyfind(BuffID, #p_actor_buf.buff_id, Pet#p_pet.buffs),
	case is_record(OldActorBuff, p_actor_buf) andalso 
			mod_role_tab:erase(RoleID, {buff_timer, pet, PetID, BuffID}) of
		TimerRef ->
			[Buff] = common_config_dyn:find(buffs, BuffID),
			NewActorBuff = start_buff(RoleID, OldActorBuff, Buff),
			Pet2 = if
				not is_record(NewActorBuff, p_actor_buf) ->
					calc(Pet, '-', OldActorBuff);
				true ->
					keyreplace(NewActorBuff, Pet)
			end,
			case Buff#p_buf.last_type of 
				?BUFF_LAST_TYPE_REAL_INTERVAL_TIME ->
					mod_role_tab:put(RoleID, {?ROLE_PET_INFO, PetID}, Pet2),
					{ok, Func} = mod_skill_manager:get_buff_func_by_type(Buff#p_buf.buff_type),
					handle_buff_func({Func, Pet2, Buff#p_buf.absolute_or_rate, OldActorBuff});
				_ ->
					mod_pet_attr:reload_pet_info(Pet2),
					mod_role_pet:update_role_base(RoleID, '-', Pet, '+', Pet2)
			end;
		_ ->
			ignore
	end;

handle({reduce_hp, RoleID, PetID, Damage, Buff}, MapState) ->
	#p_actor_buf{from_actor_id = FromActorID, from_actor_type = FromActorType} = Buff,
    mgeem_map:do_broadcast_insence_include([{role, RoleID}], ?_buff_effect{
		buff_effect = [#p_buff_effect{
			effect_type  = ?BUFF_INTERVAL_EFFECT_REDUCE_HP, 
			effect_value = Damage, 
			buff_type    = Buff#p_actor_buf.buff_type
		}],
		actor_id    = PetID,
		actor_type  = ?TYPE_PET,
		src_id      = FromActorID,
		src_type    = FromActorType
	}, MapState),
	FromActorType2 = mof_common:actor_type_atom(FromActorType),
    mod_map_pet:pet_reduce_hp(Damage, PetID, FromActorID, FromActorType2);

handle(_, _) -> ignore.

handle_buff_func({poisoning, Pet, Aor, ActorBuff}) ->
	#p_pet{role_id = RoleID, pet_id = PetID, max_hp = MaxHP} = Pet,
	#p_actor_buf{value = Value} = ActorBuff,
	Damage = case Aor of 
        ?TYPE_ABSOLUTE -> 
            Value;
        ?TYPE_PERCENT -> 
            common_tool:ceil(MaxHP * Value / 10000 ) 
    end,
    mgeem_map:send({mod, ?MODULE, {reduce_hp, RoleID, PetID, Damage, ActorBuff}});

handle_buff_func({burning, Pet, Aor, ActorBuff}) ->
	#p_pet{role_id = RoleID, pet_id = PetID, max_hp = MaxHP} = Pet,
	#p_actor_buf{value = Value} = ActorBuff,
	Damage = case Aor of 
        ?TYPE_ABSOLUTE -> 
            Value;
        ?TYPE_PERCENT -> 
            common_tool:ceil(MaxHP * Value / 10000)
    end,
    mgeem_map:send({mod, ?MODULE, {reduce_hp, RoleID, PetID, Damage, ActorBuff}});

handle_buff_func(_) -> ignore.

keyreplace(Buff, Pet) when is_record(Buff, p_actor_buf) ->
	NewBuffs = lists:keyreplace(Buff#p_actor_buf.buff_id, 
					#p_actor_buf.buff_id, Pet#p_pet.buffs, Buff),
	Pet#p_pet{buffs = NewBuffs};
keyreplace(_, Pet) -> Pet.

recalc(PetInfo) ->
	RoleID = PetInfo#p_pet.role_id,
	lists:foldl(fun(ActorBuff, PetAcc) ->
		cancel_buff(RoleID, ActorBuff),
		[Buff] = common_config_dyn:find(buffs, ActorBuff#p_actor_buf.buff_id),
		case start_buff(RoleID, ActorBuff, Buff) of
			ActorBuff when is_record(ActorBuff, p_actor_buf) ->
				calc(PetAcc, '+', ActorBuff);
			_ ->
				PetAcc
		end
	end, PetInfo#p_pet{buffs = []}, PetInfo#p_pet.buffs).