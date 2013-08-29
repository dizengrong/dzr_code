-module(mod_buff).
-include("mgeem.hrl").
-export([
         add_buff_to_actor/6,
         dispel_actor_fight_buffs/4,
         dispel_actor_debuffs/4,
         add_buff_to_actor2/5,
		 get_week/3,
		 set_week/3,
		 del_week/2
        ]).

-define(BUFF_DISPEL, 101).
-define(BUFF_KIND_FIGHT, 3).

%%===========================API FUNCTION================================

%%给ACTOR添加BUFF，这里只负责转发，不处理实际逻辑
%%没加啥的话就不用处理了
add_buff_to_actor(_SrcActorID, _SrcActorType, [], _DActorID, _DActorType, _DActorAttr) ->
    ok;

add_buff_to_actor(SrcActorID, SrcActorType, AddBuffs, DActorID, DActorType, DActorAttr) when is_list(AddBuffs) ->
    random:seed(now()),
    %%抗性过滤
    AddBuffs2 =
        lists:foldl(
          fun(Buff, Acc) ->
                  case if_actor_resist(Buff, DActorAttr) of
                      true ->
                          Acc;
                      false ->
                          [Buff|Acc]
                  end
          end, [], AddBuffs),
    add_buff_to_actor2(SrcActorID, SrcActorType, AddBuffs2, DActorID, DActorType);

add_buff_to_actor(SrcActorID, SrcActorType, AddBuffs, DActorID, DActorType, DActorAttr) ->
    add_buff_to_actor(SrcActorID, SrcActorType, [AddBuffs], DActorID, DActorType, DActorAttr).

add_buff_to_actor2(SrcActorID, SrcActorType, AddBuffs, DActorID, monster) ->
	MonsterState = mod_map_monster:get_monster_state(DActorID),
	mod_monster_buff:add_buff(DActorID, MonsterState, AddBuffs, {SrcActorType, SrcActorID});
add_buff_to_actor2(SrcActorID, SrcActorType, AddBuffs, DActorID, server_npc) ->
	ServerNpcState = mod_server_npc:get_server_npc_state(DActorID),
	mod_server_npc_buff:add_buff(DActorID, ServerNpcState, AddBuffs, {SrcActorType, SrcActorID});
add_buff_to_actor2(SrcActorID, SrcActorType, AddBuffs, DActorID, ybc) ->
    mod_map_ybc:handle({add_buff,SrcActorID, SrcActorType, AddBuffs, DActorID},mgeem_map:get_state());
add_buff_to_actor2(SrcActorID, SrcActorType, AddBuffs, DActorID, pet) ->
    #p_map_pet{role_id=PetRoleID} = mod_map_actor:get_actor_mapinfo(DActorID, pet),
	mod_map_pet:add_buff(SrcActorID, SrcActorType, AddBuffs, PetRoleID, DActorID);
  
add_buff_to_actor2(SrcActorID, SrcActorType, AddBuffs, DActorID, role) ->
	case lists:any(fun(#p_buf{buff_type=BuffType}) ->
						   {ok,Func} = mod_skill_manager:get_buff_func_by_type(BuffType),
						   Func =:= dizzy
				   end, AddBuffs) of
		true ->
			hook_map_role:role_been_dizzy(DActorID, SrcActorID, SrcActorType);
		false ->
			ignore
	end,
	mod_role_buff:add_buff(DActorID, AddBuffs, {SrcActorType, SrcActorID}).

dispel_actor_fight_buffs(SrcActorID, SrcActorType, DActorID, role) ->
	mod_map_role:remove_buff(DActorID, SrcActorID, SrcActorType, 0);
dispel_actor_fight_buffs(_SrcActorID, _SrcActorType, DActorID, monster) ->
	MonsterState = mod_map_monster:get_monster_state(DActorID),
	mod_monster_buff:del_buff_by_type(MonsterState, [0]);
dispel_actor_fight_buffs(_SrcActorID, _SrcActorType, DActorID, server_npc) ->
	ServerNpcState = mod_server_npc:get_server_npc_state(DActorID),
	mod_server_npc_buff:del_buff_by_type(ServerNpcState, [0]);
dispel_actor_fight_buffs(SrcActorID, SrcActorType, DActorID, ybc) ->
    mod_map_ybc:handle({remove_buff, SrcActorID, SrcActorType, 0, DActorID},mgeem_map:get_state());
dispel_actor_fight_buffs(SrcActorID, SrcActorType, DActorID, pet) ->
	mod_map_pet:remove_buff(SrcActorID, SrcActorType, 0, DActorID).

dispel_actor_debuffs(SrcActorID, SrcActorType, DActorID, role) ->
	mod_map_role:remove_buff(DActorID, SrcActorID, SrcActorType, -1);
dispel_actor_debuffs(_, _, _, _) ->
     ignore.

%%虚弱
get_week(ActorType, ActorID, NowTime) ->
	case get({week, ActorType, ActorID}) of
		undefined ->
			0;
		{_Week, EndTime} when NowTime >= EndTime ->
			erase({week, ActorType, ActorID}),
			0;
		{Week, _} ->
			Week
	end.

set_week(ActorType, ActorID, Week) when Week > 0 ->
	NowTime = common_tool:now(),
	case get({week, ActorType, ActorID}) of
	{Week0, EndTime} when Week0 > Week, EndTime =< NowTime ->
		ignore;
	_ ->
		put({week, ActorType, ActorID}, {Week, NowTime+3})
	end;

set_week(_ActorType, _ActorID, _Week) ->
	ignore.

del_week(ActorType, ActorID) ->
	erase({week, ActorType, ActorID}).

%%===========================LOCAL FUNCTION================================

if_actor_resist(BuffDetail, ActorAttr) ->
    %%获取actor各种抗性。。。
    #actor_fight_attr{dizzy_resist=DizzyResist, freeze_resist=FreezeResist} = ActorAttr,
    %%每种抗性针对一种效果
    #p_buf{absolute_or_rate=AOR, value=Value, buff_type=BuffType} = BuffDetail,
	%%如果是这三个BUFF的话就不用考虑抗性了，前面已经做了处理
    {ok, Func} = mod_skill_manager:get_buff_func_by_type(BuffType), 
	if
		Func == dizzy ->
			AOR =/= ?TYPE_ABSOLUTE andalso not if_active(Value-DizzyResist);
		Func == freeze ->
			AOR =/= ?TYPE_ABSOLUTE andalso not if_active(Value-FreezeResist);
	    true ->
	        false
	end.

if_active(Value) ->
    random:uniform(10000) =< Value.
