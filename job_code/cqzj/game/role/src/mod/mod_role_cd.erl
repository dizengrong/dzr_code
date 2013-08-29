%% 一个通用的cd模块

-module (mod_role_cd).
-include("mgeer.hrl").

-export ([handle/1, add_cd/2, add_cd/3, is_in_cd/2, add_cd_time/3,
		  send_cd_info_to_client/2, clear_cd/2]).

%% mod_role_misc的回调方法
-export([init_role_cd/2, delete_role_cd/1]).

-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?CD, Method, Msg)).

%% ==========================================================
init_role_cd(RoleID, RoleCdRec) ->
	case is_record(RoleCdRec, r_role_cd) of
		false ->
			RoleCdRec1 = #r_role_cd{};
		_ ->
			RoleCdRec1 = RoleCdRec
	end,
	set_role_cd_rec(RoleID, RoleCdRec1).

delete_role_cd(RoleID) ->
	mod_role_tab:erase(RoleID, role_cd).

set_role_cd_rec(RoleID, RoleCdRec) ->
	mod_role_tab:put(RoleID, role_cd, RoleCdRec).

get_role_cd_rec(RoleID) ->
	mod_role_tab:get(RoleID, role_cd).

get_cd_rec(RoleID, CdType) ->
	RoleCdRec = get_role_cd_rec(RoleID),
	case lists:keyfind(CdType, #cd.cd_type, RoleCdRec#r_role_cd.cd_list) of
		false ->
			#cd{cd_type = CdType};
		CdRec -> 
			reset_if_cd_over(RoleID, CdRec)
	end.

set_cd_rec(RoleID, NewCdRec) ->
	RoleCdRec = get_role_cd_rec(RoleID),
	CdList = lists:keystore(NewCdRec#cd.cd_type, #cd.cd_type, RoleCdRec#r_role_cd.cd_list, NewCdRec),
	RoleCdRec2 = RoleCdRec#r_role_cd{cd_list = CdList},
	set_role_cd_rec(RoleID, RoleCdRec2).

%% retrun new CdRec
reset_if_cd_over(RoleID, CdRec) ->
	case CdRec#cd.cd_end_time =/= 0 andalso common_tool:now() >= CdRec#cd.cd_end_time of
		true ->
			NewCdRec = reset_cd(CdRec),
			set_cd_rec(RoleID, NewCdRec),
			NewCdRec;
		false -> CdRec
	end.


reset_cd(CdRec)	-> CdRec#cd{acc_add_times = 0, cd_end_time = 0, is_in_cd = 0}.
%% ==========================================================

handle({_Unique, _Module, ?CD_INFO, DataIn, RoleID, _PID, _Line}) ->
	send_cd_info_to_client(RoleID, DataIn#m_cd_info_tos.cd_type);

handle({_Unique, _Module, ?CD_CLEAR, DataIn, RoleID, _PID, _Line}) ->
	CdType = DataIn#m_cd_clear_tos.cd_type,
	case clear_cd(RoleID, CdType) of
		{error, Reason} -> common_misc:send_common_error(RoleID, 0, Reason);
		true -> send_cd_info_to_client(RoleID, CdType)
	end.

send_cd_info_to_client(RoleID, CdType) ->
	CdRec = get_cd_rec(RoleID, CdType),
	Msg = #m_cd_info_toc{
		cd_type     = CdRec#cd.cd_type,
		cd_end_time = CdRec#cd.cd_end_time,
		is_in_cd    = CdRec#cd.is_in_cd
	},
	?MOD_UNICAST(RoleID, ?CD_INFO, Msg).

%% add cd time
add_cd(RoleID, CdType) ->
	add_cd(RoleID, CdType, 0).
%% Times是第几次操作了，有些系统根据操作次数加不同的cd时间的
add_cd(RoleID, CdType, Times) ->
	AddCd = cfg_cd:add_cd(CdType, Times),
	add_cd_time(RoleID, CdType, AddCd).

add_cd_time(RoleID, CdType, AddCd) ->
	CdRec = get_cd_rec(RoleID, CdType),
	case is_in_cd(CdRec) of
		false -> 
			Now = common_tool:now(),
			case CdRec#cd.cd_end_time > 0 of
				true  -> NewEndTime = CdRec#cd.cd_end_time + AddCd;
				false -> NewEndTime = Now + AddCd
			end,
			InCdTime = cfg_cd:in_cd_time(CdType),
			case NewEndTime - Now >= InCdTime of
				true -> %% 达到冷却累计时间了，要冷却
					NewCdRec = CdRec#cd{
						cd_end_time = NewEndTime,
						is_in_cd    = 1
					};
				false ->
					NewCdRec = CdRec#cd{
						cd_end_time = NewEndTime
					}
			end,
			set_cd_rec(RoleID, NewCdRec);
		true -> %% 在cd中是无法操作的，因此忽略
			ignore
	end.

%% return true if in cd, otherwise return false
is_in_cd(RoleID, CdType) ->
	is_in_cd(get_cd_rec(RoleID, CdType)).
is_in_cd(CdRec) ->
	(CdRec#cd.is_in_cd == 1).
	
%% clear cd time if there is any
clear_cd(RoleID, CdType) ->
	CdRec = get_cd_rec(RoleID, CdType),
	case is_in_cd(CdRec) of
		false -> {error, <<"不在冷却中，无需清除">>};
		true ->
			{MoneyType, Cost} = cfg_cd:clear_cd_cost(CdType),
			LogType           = get_clear_cd_consume_log(MoneyType),
			case common_bag2:use_money(RoleID, MoneyType, Cost, LogType) of
				{error, Reason} -> {error, Reason};
				true -> 
					set_cd_rec(RoleID, reset_cd(CdRec)),
					true
			end
	end.

get_clear_cd_consume_log(silver_any) -> ?CONSUME_TYPE_SILVER_CLEAR_CD;
get_clear_cd_consume_log(_) -> ?CONSUME_TYPE_GOLD_CLEAR_CD.