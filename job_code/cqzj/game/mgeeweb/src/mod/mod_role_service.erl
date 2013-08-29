%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  1 Mar 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_role_service).

-include("mgeeweb.hrl").
-include("role_misc.hrl").
%% API
-export([
         get/3
        ]).

get("/set_conlogin/" ++ _, Req, _) ->
    do_set_conlogin(Req);
get("/clear_person_ybc" ++ _, Req, _) ->
    do_clear_person_ybc(Req);
get("/clear_family_ybc" ++ _, Req, _) ->
    do_clear_family_ybc(Req);
get("/clear_item_stall_state" ++ _, Req, _) ->
    do_clear_item_stall_state(Req);
get("/clear_exchange_state" ++ _, Req, _) ->
    do_clear_exchange_state(Req);
get("/clear_arena_state" ++ _, Req, _) ->
    do_clear_arena_state(Req);
get("/clear_login_punish" ++ _, Req, _) ->
    clear_login_punish(Req);
get("/refresh_rnkm_mirror" ++ _, Req, _) ->
    refresh_rnkm_mirror(Req);
get("/refresh_clgm_mirror" ++ _, Req, _) ->
    refresh_clgm_mirror(Req);
get("/set_pay_gift_status" ++ _, Req, _) ->
    set_pay_gift_status(Req);
get("/get_role_nuqi" ++ _, Req, _) ->
    get_role_nuqi(Req);
get("/get_role_mission_id" ++ _, Req, _) ->
    get_role_mission_id(Req);
get("/recalc_attr" ++ _, Req, _) ->
    recalc_attr(Req);

get(_, Req, _) ->
    Req:not_found().

%% 清理交易状态异常
do_clear_exchange_state(Req) ->
    Get = Req:parse_qs(),
    RoleId = common_tool:to_integer(proplists:get_value("role_id", Get)),
    case db:dirty_read(?DB_ROLE_STATE, RoleId) of
        [] ->
            mgeeweb_tool:return_json_error(Req);
        [RoleState] ->
            db:dirty_write(?DB_ROLE_STATE, RoleState#r_role_state{exchange=false}),
            mgeeweb_tool:return_json_ok(Req)
    end.

%% 清理擂台状态
do_clear_arena_state(Req)->
    case global:whereis_name(mod_arena_manager) of
        undefined->
            mgeeweb_tool:return_json_error(Req);
        Pid->
            SendInfo = {clear_arena_data},
            erlang:send(Pid,SendInfo),
            mgeeweb_tool:return_json_ok(Req)
    end.

clear_login_punish(Req)->
    Get = Req:parse_qs(),
    RoleID = common_tool:to_integer(proplists:get_value("role_id", Get)),
    
    case global:whereis_name(global_gateway_server) of
        undefined->
            ignore;
        PID->
            PID ! {clear_login, RoleID}
    end,
    mgeeweb_tool:return_json_ok(Req).

%% 清理道具摆摊状态异常
do_clear_item_stall_state(Req) ->
    Get = Req:parse_qs(),
    RoleId = common_tool:to_integer(proplists:get_value("role_id", Get)),
    case common_misc:send_to_rolemap(RoleId, {mod_stall, {clear_item_stall_state, RoleId}}) of
        ignore ->
            mgeeweb_tool:return_json_error(Req);
        _ ->
            mgeeweb_tool:return_json_ok(Req)
    end.

%% 清理玩家个人拉镖状态
do_clear_person_ybc(Req) ->
    Get= Req:parse_qs(),
    RoleID = common_tool:to_integer(proplists:get_value("role_id", Get)),
    case db:dirty_read(?DB_YBC_UNIQUE, {0,1, RoleID}) of
        [] ->
            db:transaction(
              fun() -> 
                      [RoleState] = db:read(?DB_ROLE_STATE, RoleID, write), 
                      case lists:member(RoleState#r_role_state.ybc, [1,3,4]) of
                          true ->
                              db:write(?DB_ROLE_STATE, RoleState#r_role_state{ybc=0}, write);
                          false ->
                              ignore
                      end
              end),    
            ignore;
        [#r_ybc_unique{id=YbcID}] ->
            db:dirty_delete(?DB_YBC_UNIQUE, {0,1,RoleID}),
            db:dirty_delete(?DB_YBC, YbcID),
            db:transaction(
              fun() -> 
                      [RoleState] = db:read(?DB_ROLE_STATE, RoleID, write), 
                      db:write(?DB_ROLE_STATE, RoleState#r_role_state{ybc=0}, write) 
              end)            
    end,
    mgeeweb_tool:return_json_ok(Req).

%% 清理玩家个人的家族镖状态
do_clear_family_ybc(Req) ->
    Get= Req:parse_qs(),
    RoleID = common_tool:to_integer(proplists:get_value("role_id", Get)),
    case db:dirty_read(?DB_ROLE_BASE, RoleID) of
        [] ->
            ignore;
        [#p_role_base{family_id=FamilyID}] when FamilyID > 0 ->
            case db:dirty_read(?DB_YBC_UNIQUE, {FamilyID, 2, RoleID}) of
                [] ->
                    clear_family_ybc_state(RoleID);   
                _ ->
                    ignore
            end;
        _ ->
           clear_family_ybc_state(RoleID)
    end,
    mgeeweb_tool:return_json_ok(Req).

clear_family_ybc_state(RoleID) ->
    db:transaction(
      fun() -> 
              [RoleState] = db:read(?DB_ROLE_STATE, RoleID, write), 
              if RoleState#r_role_state.ybc =:= ?ROLE_STATE_YBC_FAMILY ->
                     db:write(?DB_ROLE_STATE, RoleState#r_role_state{ybc=0}, write);
                 true ->
                     ignore
              end
      end).

do_set_conlogin(_Req) ->
    % Get= Req:parse_qs(),
    % Day = common_tool:to_integer(proplists:get_value("day", Get)),
    % RoleID = common_tool:to_integer(proplists:get_value("role_id", Get)),
    todo.
    
%%TODO:
refresh_rnkm_mirror(Req) ->
	_RoleID = common_tool:to_integer(proplists:get_value("role_id", Req:parse_qs())),
	mgeeweb_tool:return_json_ok(Req).

%%TODO:
refresh_clgm_mirror(Req) ->
	_RoleID = common_tool:to_integer(proplists:get_value("role_id", Req:parse_qs())),
	mgeeweb_tool:return_json_ok(Req).

recalc_attr(Req) ->
	RoleID = common_tool:to_integer(proplists:get_value("role_id", Req:parse_qs())),
  case global:whereis_name(mgeer_role:proc_name(RoleID)) of
    undefined ->
      mgeeweb_tool:return_json_error(Req);
    Pid ->
      Fun = fun
        () ->
          mod_role_attr:reload_role_base(mod_role_attr:recalc(RoleID))
      end,
      Pid ! {apply, Fun},
      mgeeweb_tool:return_json_ok(Req)
  end.

set_pay_gift_status(Req) ->
	RoleID = common_tool:to_integer(proplists:get_value("role_id", Req:parse_qs())),
	case mod_role_tab:get({r_pay_data, RoleID}) of
		PayDataRec when erlang:is_record(PayDataRec,r_pay_data) ->
			PayDataRec1 = PayDataRec#r_pay_data{has_get_first_pay_gift = true},
			mod_role_tab:put({r_pay_data, RoleID}, PayDataRec1);
		_ ->
			set_pay_gift_status_1(RoleID,Req)
	end,
	mgeeweb_tool:return_json_ok(Req).

set_pay_gift_status_1(RoleID,Req) ->
	case db:dirty_read(db_role_misc, RoleID) of
		[RoleMisc] ->
			case lists:keyfind(r_pay_data, 1, RoleMisc#r_role_misc.tuples) of
				false ->
					mgeeweb_tool:return_json_error(Req);
				Rec ->
					NewRec = Rec#r_pay_data{has_get_first_pay_gift=true},
					NewTuples = lists:keystore(r_pay_data, 1, NewRec, RoleMisc#r_role_misc.tuples),
					db:dirty_write(db_role_misc, RoleMisc#r_role_misc{tuples=NewTuples})
			end;
		_ ->
			mgeeweb_tool:return_json_error(Req)
	end.

get_role_mission_id(Req) ->
  try 
    RoleID = common_tool:to_integer(proplists:get_value("role_id", Req:parse_qs())),
    MissionIdJson = case db:dirty_read(db_mission_data, RoleID) of
        [#r_db_mission_data{} = MissionData] -> 
            MissionList = MissionData#r_db_mission_data.mission_data#mission_data.mission_list,
            lists:map(fun(H) ->
                H#p_mission_info.id
            end, MissionList);
        [] -> []
    end, 
    AllJson = [{result,suc},{data,MissionIdJson}],
    mgeeweb_tool:return_json(AllJson,Req)
  catch
    _:_Reason ->
      mgeeweb_tool:return_json([{result,suc},{data,[]}],Req)
  end.

get_role_nuqi(Req) ->
	try 
		RoleID = common_tool:to_integer(proplists:get_value("role_id", Req:parse_qs())),
		SkillJson=get_role_nuqi_skill(RoleID),
		AllJson = [{result,suc},{data,SkillJson}],
		mgeeweb_tool:return_json(AllJson,Req)
	catch
		_:_Reason ->
			mgeeweb_tool:return_json([{result,suc},{data,[]}],Req)
	end.

get_role_nuqi_skill(RoleID) ->
	[#p_role_attr{category=Category}] = db:dirty_read(db_role_attr,RoleID),
	case  get_role_skill_list(RoleID) of
		SkillList when is_list(SkillList) ->
			NuqiSkillList = cfg_skill_life:get_one_key_learn_nuqi_skill(Category),
			SkillInfo = 
				lists:foldl(fun(H, Acc) ->
									SkillID1 = H#r_role_skill_info.skill_id,
									case lists:member(SkillID1, NuqiSkillList) of
										true -> [[{skill_id,H#r_role_skill_info.skill_id},{level,H#r_role_skill_info.cur_level}]|Acc];
										false -> Acc
									end
							end, [], SkillList),
			?DBG(SkillInfo),
			SkillInfo;
		_ ->
			[]
	end.


get_role_skill_list(RoleID) ->
	case mod_role_tab:get(RoleID, {?role_skill, RoleID}) of
		undefined ->
			case catch db:dirty_read(db_role_skill,RoleID) of
				[#r_role_skill{skill_list=SkillList}] ->
					SkillList;
				_ ->
					false
			end;
		SkillList ->
			SkillList
	end.
