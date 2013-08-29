%% Author: xierongfeng
%% Created: 2012-11-16
%% Description: 排行榜崇拜、鄙视功能
-module(mod_role_worship).

-define(_worship_do, ?DEFAULT_UNIQUE, ?WORSHIP, ?WORSHIP_DO, #m_worship_do_toc).
-define(_common_error, ?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR, #m_common_error_toc).

-define(TYPE_WORSHIP, 1).
-define(TYPE_DISDAIN, 2).

%%
%% Include files
%%
-include("mgeem.hrl").

-define(T_WORSHIP, t_worship).
-record(r_worship, {role_id, worship_count=0, disdain_count=0}).

%%
%% Exported Functions
%%
-export([start/0, init/2, count/1, delete/1, get_worship_info/2, handle/1]).
%%
%% API Functions
%%
start() ->
	ets:new(?T_WORSHIP, [named_table, public, {keypos, #r_worship.role_id}]).

init(RoleID, Rec) when is_record(Rec, r_role_worship) ->
	mod_role_tab:put({r_role_worship, RoleID}, Rec);
init(_RoleID, _) ->
	ignore.

delete(RoleID) ->
	mod_role_tab:erase({r_role_worship, RoleID}).

count(RoleID) ->
	case ets:lookup(?T_WORSHIP, RoleID) of
		[#r_worship{worship_count=WorshipCount, disdain_count=DisdainCount}] ->
			{ok, WorshipCount, DisdainCount};
		_ ->
			{ok, 0, 0}
	end.

update(RoleID, List) ->
	case ets:member(?T_WORSHIP, RoleID) of
		false ->
			Worship = lists:foldl(fun
				({K, V}, Rec) ->
					 setelement(K, Rec, V)
			end, #r_worship{role_id=RoleID}, List),
			ets:insert(?T_WORSHIP, Worship);
		_ ->
			ets:update_counter(?T_WORSHIP, RoleID, List)
	end.

get_worship_info(RoleID, TargetRoleID) ->
	RoleWorship = #r_role_worship{
		worship_roles = WorshipRoles,
		disdain_roles = DisdainRoles
	} = case mod_role_tab:get({r_role_worship, RoleID}) of
		Rec = #r_role_worship{date=Date} -> 
			case date() == Date of
				true -> Rec;
				_    -> #r_role_worship{}
			end;
		undefined -> 
			#r_role_worship{}
	end,
	CanWorship = case lists:member(TargetRoleID, WorshipRoles) of
		true ->
			1;
		false ->
			case lists:member(TargetRoleID, DisdainRoles) of
				true ->
					2;
				false ->
					0
			end
	end,
	{ok, RoleWorship, CanWorship, 
	 	cfg_worship:max_times() - length(WorshipRoles) - length(DisdainRoles)}.

handle({_Unique, ?WORSHIP, ?WORSHIP_DO, DataIn, RoleID, PID, _Line}) ->
	#m_worship_do_tos{type = WorshipType, target_roleid = TargetRoleID1} = DataIn,
	TargetRoleID2 = abs(TargetRoleID1),
	{ok, RoleWorship, CanWorship1, RemTimes} = get_worship_info(RoleID, TargetRoleID2),
	if
		CanWorship1 > 0 ->
			common_misc:unicast2(PID, ?_common_error{error_str = <<"今天已评价过此玩家">>});
		RemTimes =< 0 ->
			common_misc:unicast2(PID, ?_common_error{error_str = <<"今日评价次数已达上限">>});
		true ->
			{CanWorship2, UpdateKey} = case WorshipType of
				?TYPE_WORSHIP ->
					{1, #r_worship.worship_count};
				?TYPE_DISDAIN ->
					{2, #r_worship.disdain_count}
			end,
			update(TargetRoleID2, [{UpdateKey, 1}]),
			{ok, WorshipCount, DisdainCount} = count(TargetRoleID2),
			common_misc:unicast({role, RoleID}, ?_worship_do{
				target_roleid = TargetRoleID1,
				worship_info  = #p_worship_info{
					can_worship   = CanWorship2,
					rem_times     = RemTimes - 1,
					worship_count = WorshipCount,
					disdain_count = DisdainCount
				}
			}),
			NewRoleWorship = case WorshipType of
				?TYPE_WORSHIP ->
					RoleWorship#r_role_worship{
						worship_roles = [TargetRoleID2|RoleWorship#r_role_worship.worship_roles]
					};
				?TYPE_DISDAIN ->
					RoleWorship#r_role_worship{
						disdain_roles = [TargetRoleID2|RoleWorship#r_role_worship.disdain_roles]
					}
			end,
			mod_role_tab:put({r_role_worship, RoleID}, NewRoleWorship)
	end.

%%
%% Local Functions
%%
