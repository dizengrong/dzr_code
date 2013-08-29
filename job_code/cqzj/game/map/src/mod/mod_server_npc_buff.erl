%%% -------------------------------------------------------------------
%%% Author  : xierongfeng
%%% Description : SERVER NPC BUFF模块
%%%
%%% Created : 2013-5-21
%%% -------------------------------------------------------------------
-module (mod_server_npc_buff).

-export ([add_buff/3, add_buff/4, del_buff/2, del_buff_by_type/2]).

-export ([add_buff2/4, del_buff2/2]).

-export ([handle/2]).

-include ("mgeem.hrl").

-define(_buff_effect, ?FIGHT, ?FIGHT_BUFF_EFFECT, #m_fight_buff_effect_toc).%}

add_buff(ServerNpcID, ServerNpcState, Buffs) ->
  add_buff(ServerNpcID, ServerNpcState, Buffs, {server_npc, ServerNpcID}).

add_buff(ServerNpcID, ServerNpcState, BuffID, ByWho) when is_integer(BuffID) ->
    add_buff(ServerNpcID, ServerNpcState, [BuffID], ByWho);
add_buff(ServerNpcID, ServerNpcState, Buffs, ByWho) when is_list(Buffs), Buffs =/= [] ->
  NewServerNpcState = add_buff2(ServerNpcID, ServerNpcState, Buffs, ByWho),
  mod_server_npc:set_server_npc_state(ServerNpcID, NewServerNpcState);
add_buff(_ServerNpcID, ServerNpcState, _, _) -> ServerNpcState.

add_buff2(ServerNpcID, ServerNpcState, BuffIDs = [B|_], ByWho) when is_integer(B) ->
  add_buff2(ServerNpcID, ServerNpcState, [begin 
    [Buff] = common_config_dyn:find(buffs, BuffID), Buff 
  end||BuffID <- BuffIDs], ByWho);
add_buff2(ServerNpcID, ServerNpcState, Buffs, ByWho) ->
  #server_npc_state{server_npc_info = OldServerNpc, buf_timer_ref = OldTimers} = ServerNpcState,
  case OldServerNpc#p_server_npc.state of
    ?DEAD_STATE -> 
      ServerNpcState;
    _ ->
      {NewTimers, NewServerNpc} = add_buff3(ServerNpcID, OldTimers, OldServerNpc, Buffs, ByWho),
      ServerNpcState#server_npc_state{server_npc_info = NewServerNpc, buf_timer_ref = NewTimers}
  end.

add_buff3(ServerNpcID, OldTimers, OldServerNpc, Buffs, ByWho) ->
  lists:foldl(fun
    (Buff, {TimerAcc, ServerNpcAcc}) ->
      #p_buf{buff_id = BuffID, buff_type = BuffType, level = BuffLv} = Buff,
      NewActorBuff = transform(ServerNpcID, Buff, ByWho),
      case BuffType == 0 orelse 
          lists:keyfind(BuffType, #p_actor_buf.buff_type, ServerNpcAcc#p_server_npc.buffs) of
        OldActorBuff when is_record(OldActorBuff, p_actor_buf) ->
          [OldBuff] = common_config_dyn:find(buffs, BuffID),
          if
            BuffLv > OldBuff#p_buf.level ->
              {_, TimerAcc2} = start_buff(
              cancel_buff(TimerAcc, OldActorBuff), NewActorBuff, Buff),
              ServerNpcAcc2  = calc(ServerNpcAcc, '-', OldActorBuff, '+', NewActorBuff);
            true ->
              TimerAcc2     = TimerAcc,
              ServerNpcAcc2 = ServerNpcAcc
          end;
        _ ->
          case BuffType =/= 0 orelse
              lists:keyfind(BuffID, #p_actor_buf.buff_id, ServerNpcAcc#p_pet.buffs) of
            OldActorBuff2 when is_record(OldActorBuff2, p_actor_buf) ->
              #p_actor_buf{value = OldValue, end_time = OldEndtime} = OldActorBuff2,
              #p_actor_buf{value = NewValue, end_time = NewEndtime} = NewActorBuff,
              case {NewValue, NewEndtime} > {OldValue, OldEndtime} of
                true ->
                  {_, TimerAcc2} = start_buff(
                  cancel_buff(TimerAcc, OldActorBuff2), NewActorBuff, Buff),
                  ServerNpcAcc2  = calc(ServerNpcAcc, '-', OldActorBuff2, '+', NewActorBuff);
                _ ->
                  {_, TimerAcc2} = TimerAcc,
                  ServerNpcAcc2  = ServerNpcAcc
              end;
            _ ->
              {_, TimerAcc2} = start_buff(TimerAcc, NewActorBuff, Buff),
              ServerNpcAcc2  = calc(ServerNpcAcc, '+', NewActorBuff)
          end
      end,
      {TimerAcc2, ServerNpcAcc2}
  end, {OldTimers, OldServerNpc}, Buffs).

del_buff(ServerNpcState, BuffID) when is_integer(BuffID) ->
  del_buff(ServerNpcState, [BuffID]);
del_buff(ServerNpcState, BuffIDs = [B|_]) when is_integer(B) ->
  NewServerNpcState = del_buff2(ServerNpcState, BuffIDs),
  mod_server_npc:set_server_npc_state(NewServerNpcState);
del_buff(ServerNpcState, _) -> ServerNpcState.

del_buff2(ServerNpcState, BuffIDs) ->
  #server_npc_state{server_npc_info = OldServerNpc, buf_timer_ref = OldTimers} = ServerNpcState,
    case OldServerNpc#p_server_npc.state of
      ?DEAD_STATE -> 
        ServerNpcState;
      _ ->
        {NewTimers, NewServerNpc} = del_buff3(OldTimers, OldServerNpc, BuffIDs),
        ServerNpcState#server_npc_state{server_npc_info = NewServerNpc, buf_timer_ref = NewTimers}
  end.

del_buff3(OldTimers, OldServerNpc, BuffIDs) ->
  OldBuffs = OldServerNpc#p_server_npc.buffs,
  lists:foldl(fun
    (BuffID, {TimerAcc, ServerNpcAcc}) ->
      case lists:keyfind(BuffID, #p_actor_buf.buff_id, OldBuffs) of
        OldActorBuff when is_record(OldActorBuff, p_actor_buf) ->
          {cancel_buff(TimerAcc, OldActorBuff), calc(ServerNpcAcc, '-', OldActorBuff)};
        _ ->
          {TimerAcc, ServerNpcAcc}
      end
  end, {OldTimers, OldServerNpc}, BuffIDs).

del_buff_by_type(ServerNpcState, Buff) when not is_list(Buff) ->
  del_buff_by_type(ServerNpcState, [Buff]);
del_buff_by_type(ServerNpcState, [Int]) when Int == 0; Int == -1 -> %% del all buffs
  #server_npc_state{server_npc_info = OldServerNpc, buf_timer_ref = OldTimers} = ServerNpcState,
  case OldServerNpc#p_server_npc.state of
    ?DEAD_STATE -> 
      ServerNpcState;
    _ ->
      {NewTimers, NewServerNpc} = lists:foldl(fun
        (ActorBuff, {TimerAcc, ServerNpcAcc}) ->
          [Buff] = common_config_dyn:find(buffs, ActorBuff#p_actor_buf.buff_id),
          if 
            Int ==  0 andalso (Buff#p_buf.is_debuff orelse Buff#p_buf.can_remove);
            Int == -1 andalso  Buff#p_buf.is_debuff ->
              {cancel_buff(TimerAcc, ActorBuff), calc(ServerNpcAcc, '-', ActorBuff)};
            true ->
              {TimerAcc, ServerNpcAcc}
          end
      end, {OldTimers, OldServerNpc}, OldServerNpc#p_server_npc.buffs),
      ServerNpcState#server_npc_state{server_npc_info = NewServerNpc, buf_timer_ref = NewTimers}
  end;
del_buff_by_type(ServerNpcState, BuffTypes) ->
  #server_npc_state{server_npc_info = OldServerNpc, buf_timer_ref = OldTimers} = ServerNpcState,
  case OldServerNpc#p_server_npc.state of
    ?DEAD_STATE -> 
      ServerNpcState;
    _ ->
      ActorBuffs = OldServerNpc#p_server_npc.buffs,
      {NewTimers, NewServerNpc} = lists:foldl(fun
        (BuffType, {TimerAcc, ServerNpcAcc}) ->
          case lists:keyfind(BuffType, #p_actor_buf.buff_type, ActorBuffs) of
            ActorBuff when is_record(ActorBuff, p_actor_buf) ->
              {cancel_buff(TimerAcc, ActorBuff), calc(ServerNpcAcc, '-', ActorBuff)};
            _ ->
              {TimerAcc, ServerNpcAcc}
          end
      end, {OldTimers, OldServerNpc}, BuffTypes),
      ServerNpcState#server_npc_state{server_npc_info = NewServerNpc, buf_timer_ref = NewTimers}
  end.

transform(ServerNpcID, Buff, {FromActorType, FromActorID}) ->
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
    actor_id        = ServerNpcID,
    actor_type      = ?TYPE_SERVER_NPC,
    from_actor_id   = FromActorID,
    from_actor_type = mof_common:actor_type_int(FromActorType),
    remain_time     = Buff#p_buf.last_value,
    start_time      = NowTime,
    end_time        = EndTime,
    value           = Buff#p_buf.value
  }.

calc(ServerNpc, Op1, Buff1, Op2, Buff2) ->
  calc(calc(ServerNpc, Op1, Buff1), Op2, Buff2).

calc(ServerNpc1, '+', ActorBuff) ->
  ServerNpc2 = ServerNpc1#p_server_npc{buffs = [ActorBuff|ServerNpc1#p_server_npc.buffs]},
  mod_server_npc_attr:calc(ServerNpc2, '+', mod_buff_attr:transform(ActorBuff));
calc(ServerNpc1, '-', ActorBuff) ->
  ServerNpc2 = ServerNpc1#p_server_npc{buffs = 
    lists:keydelete(ActorBuff#p_actor_buf.buff_id, #p_actor_buf.buff_id, ServerNpc1#p_server_npc.buffs)},
  mod_server_npc_attr:calc(ServerNpc2, '-', mod_buff_attr:transform(ActorBuff)).

start_buff(BuffTimers, ActorBuff = #p_actor_buf{buff_id=BuffID, 
    actor_id=ServerNpcID, remain_time=RemainTime, end_time=EndTime}, Buff) ->
  NowTime = common_tool:now(),
  DestPID = self(),
  Message = {buff_timeout, server_npc, ServerNpcID, BuffID},
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

handle({buff_timeout, TimerRef, ServerNpcID, BuffID}, _State) ->
  case mod_server_npc:get_server_npc_state(ServerNpcID) of
    ServerNpcState = #server_npc_state{server_npc_info = OldServerNpc, buf_timer_ref = OldTimers} ->
      OldActorBuff = lists:keyfind(BuffID, #p_actor_buf.buff_id, OldServerNpc#p_server_npc.buffs),
      case is_record(OldActorBuff, p_actor_buf) andalso
          OldServerNpc#p_server_npc.state =/= ?DEAD_STATE andalso 
          lists:keyfind(BuffID, 1, OldTimers) of
        {BuffID, TimerRef} ->
          [Buff] = common_config_dyn:find(buffs, BuffID),
          {NewActorBuff, NewTimers} = start_buff(OldTimers, OldActorBuff, Buff),
          NewServerNpc = if
            not is_record(NewActorBuff, p_actor_buf) ->
              calc(OldServerNpc, '-', OldActorBuff);
            true ->
              keyreplace(NewActorBuff, OldServerNpc)
          end,
          NewServerNpcState = ServerNpcState#server_npc_state{
            server_npc_info = NewServerNpc, buf_timer_ref = NewTimers},
          mod_server_npc:set_server_npc_state(ServerNpcID, NewServerNpcState),
          case Buff#p_buf.last_type of 
            ?BUFF_LAST_TYPE_REAL_INTERVAL_TIME ->
              {ok, Func} = mod_skill_manager:get_buff_func_by_type(Buff#p_buf.buff_type),
              handle_buff_func({Func, 
                NewServerNpcState, Buff#p_buf.absolute_or_rate, OldActorBuff});
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

handle_buff_func({poisoning, ServerNpcState, Aor, ActorBuff}) ->
  #p_actor_buf{value = Value} = ActorBuff,
  Damage = case Aor of 
    ?TYPE_ABSOLUTE -> 
        Value;
    ?TYPE_PERCENT -> 
      #server_npc_state{server_npc_info = ServerNpc} = ServerNpcState,
        common_tool:ceil(ServerNpc#p_server_npc.max_hp * Value / 10000 ) 
  end,
  reduce_hp(ServerNpcState, Damage, ActorBuff);

handle_buff_func({burning, ServerNpcState, Aor, ActorBuff}) ->
  #p_actor_buf{value = Value} = ActorBuff,
  Damage = case Aor of 
    ?TYPE_ABSOLUTE -> 
        Value;
    ?TYPE_PERCENT -> 
        #server_npc_state{server_npc_info = ServerNpc} = ServerNpcState,
        common_tool:ceil(ServerNpc#p_server_npc.max_hp * Value / 10000 ) 
  end,
  reduce_hp(ServerNpcState, Damage, ActorBuff);

handle_buff_func(_) -> ignore.

keyreplace(Buff, ServerNpc) when is_record(Buff, p_actor_buf) ->
  NewBuffs = lists:keyreplace(Buff#p_actor_buf.buff_id, 
    #p_actor_buf.buff_id, ServerNpc#p_server_npc.buffs, Buff),
  ServerNpc#p_server_npc{buffs = NewBuffs};
keyreplace(_, ServerNpc) -> ServerNpc.

reduce_hp(ServerNpcState, Damage, Buff) ->
  #server_npc_state{server_npc_info = ServerNpc} = ServerNpcState,
  ServerNpcID = ServerNpc#p_server_npc.npc_id,
  #p_actor_buf{from_actor_id = FromActorID, from_actor_type = FromActorType} = Buff,
    mgeem_map:do_broadcast_insence_include([{server_npc, ServerNpcID}], ?_buff_effect{
    buff_effect = [#p_buff_effect{
      effect_type  = ?BUFF_INTERVAL_EFFECT_REDUCE_HP, 
      effect_value = Damage, 
      buff_type    = Buff#p_actor_buf.buff_type
    }],
    actor_id    = ServerNpcID,
    actor_type  = ?TYPE_SERVER_NPC,
    src_id      = FromActorID,
    src_type    = FromActorType
  }),
  FromActorType2 = mof_common:actor_type_atom(FromActorType),
  mod_server_npc:attack_server_npc(ServerNpcState, {FromActorID, FromActorType2, Damage}).
