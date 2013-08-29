-module(hook_mission_fb).

-compile([export_all]).
%%
-include("mission.hrl"). 

%%%暂时只是用于进去战役副本第一关释放牛逼怒气技能的特殊处理.................
hook_enter(RoleID, FbID) ->
	mod_skill:change_skill_level_temp(RoleID),
	Missions = cfg_mission_fb:after_enter(FbID),
	lists:foreach(fun(H) ->
		{MissionID, MFAs} = H, 
		case is_list(MFAs) andalso exist_mission(MissionID, RoleID) of
			true -> ?TRY_CATCH(examine_fb_handle(RoleID, MFAs));
			false -> []
		end
	end, Missions).

hook_quit(RoleID, FbID) ->
	mod_skill:change_skill_level_temp(RoleID),
	Missions = cfg_mission_fb:after_quit(FbID),
	lists:foreach(fun(H) ->
		{MissionID, MFAs} = H, 
		case exist_mission(MissionID, RoleID) of
			true -> ?TRY_CATCH(examine_fb_handle(RoleID, MFAs));
			false -> []
		end
	end, Missions).

exist_mission(MissionID, RoleID) ->
	Fun = fun() -> mod_mission_data:get_pinfo(RoleID, MissionID) end,
    case common_transaction:t(Fun) of
        {atomic, #p_mission_info{id = MissionID1}} ->  MissionID == MissionID1;
        _ -> false
    end.

examine_fb_handle(_RoleID, []) ->
	ignore;
examine_fb_handle(RoleID, [MFA|T]) ->
	case MFA of
		{F, A} ->
			apply(?MODULE, F, [RoleID | A]);
		{M, F, A} ->
			apply(M, F, [RoleID | A])
	end,
	examine_fb_handle(RoleID, T).