%%变身任务
-module(mod_mission_change_skin).
-include("mission.hrl"). 

-export([remove_buff/1]).

-export([hook_accept_mission/2,
		 hook_finish_mission/2,
		 hook_cancel_mission/2,
		 is_doing_change_skin_mission/1,
		 hook_reload_mission/1,
		 handle/2
		]).

handle({is_doing_change_skin_mission,RoleID}, _State) ->
	MissionList = mod_mission_data:get_pinfo_list(RoleID),
	IsDoing = is_doing_change_skin_mission(MissionList),
	?DBG(IsDoing);

handle({FromPID, is_doing_change_skin_mission, RoleID, CastArg, FuncArg}, _State) ->
	Msg = is_doing_change_skin_mission(RoleID),
	FromPID ! {Msg, RoleID, CastArg, FuncArg}.

remove_buff(RoleID) ->
	BuffList = cfg_mission_change_skin:remove_buff_list(),
	common_misc:send_to_rolemap(RoleID, {mod_map_role, {remove_buff, RoleID, RoleID, role, BuffList}}).

hook_accept_mission(RoleID,MissionID) ->
	case lists:member(MissionID, cfg_mission_change_skin:accept_mission_list()) of
		true ->
			% mod_role_pet_mix:auto_pet_mix(RoleID, ?NO_MIX_STATE),
			BuffList = cfg_mission_change_skin:add_buff_list(),
			mod_role_buff:add_buff(RoleID,BuffList);
		false ->
			ignore
	end.

hook_finish_mission(RoleID,MissionID) ->
	case lists:member(MissionID, cfg_mission_change_skin:finish_mission_list()) of
		true ->
			remove_change_skin_buff(RoleID);
		false ->
			ignore
	end.

hook_cancel_mission(RoleID,MissionID) ->
	case lists:member(MissionID, cfg_mission_change_skin:accept_mission_list()) of
		true ->
			remove_change_skin_buff(RoleID);
		false ->
			ignore
	end.

is_doing_change_skin_mission(RoleID) when RoleID < 0 ->
	false;
is_doing_change_skin_mission(RoleID) when is_integer(RoleID) ->
	case mod_map_role:get_role_base(RoleID)of
		{ok,RoleBase} when is_record(RoleBase, p_role_base) ->
			is_doing_change_skin_mission(RoleBase);
		Other ->
			?ERROR_MSG("is_doing_change_skin_mission RoleID=~w,Other=~w",[RoleID,Other]),
			false
	end;
is_doing_change_skin_mission(RoleBase) when is_record(RoleBase, p_role_base) ->
	#p_role_base{buffs=Buffs} = RoleBase,
	[ChangeSkinBuffType] = cfg_mission_change_skin:remove_buff_list(),
	case lists:keyfind(ChangeSkinBuffType, #p_actor_buf.buff_type, Buffs) of
		false ->
			false;
		#p_actor_buf{} ->
			true
	end;
is_doing_change_skin_mission(MissionList) -> 
	lists:any(
	  fun(E)->
			  #p_mission_info{id=Id,current_status=Status} = E,
			  Status>?MISSION_STATUS_NOT_ACCEPT andalso 
				  lists:member(Id, cfg_mission_change_skin:accept_mission_list())
	  end,MissionList).

hook_reload_mission(RoleBase) ->
	#p_role_base{role_id=RoleID,buffs=Buffs} = RoleBase,
	MissionList = mod_mission_data:get_pinfo_list(RoleID),
	case is_doing_change_skin_mission(MissionList) of
		false ->
			BuffList = cfg_mission_change_skin:remove_buff_list(),
			case lists:any(fun(BuffType) ->
								   lists:keymember(BuffType, #p_actor_buf.buff_type, Buffs)
						   end, BuffList) of
				true ->
					remove_change_skin_buff(RoleID);
				false ->
					ignore
			end;
		true ->
			ignore
	end.

remove_change_skin_buff(RoleID) ->
	BuffList = cfg_mission_change_skin:remove_buff_list(),
	mod_role_buff:del_buff_by_type(RoleID,BuffList).


		