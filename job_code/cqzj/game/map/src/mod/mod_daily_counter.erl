%% Author: lijianjun
%% Created: 2013-1-28
%% Description:  活动次数统计
-module(mod_daily_counter).

%%
%% Include files
%%
-include("mgeem.hrl").
%%
%% Exported Functions
%%
-export([
		 handle/1,
		 handle/2,
		 init/2,
		 delete/1,
		 get_mission_remain_times/2,
		 add_mission_remain_times/3,
		 reset_role_daily_counter_info/2,
		 set_mission_remain_times/4,
		 hook_role_online/1
		]).

-define(daily_counter_conf,daily_counter_conf).
%%
%% API Functions
%%
handle(Msg,_State)->
	handle(Msg).
handle({_,?DAILY_COUNTER,?DAILY_COUNTER_INFO,_,_,_,_}=Msg)->
	do_daily_counter_info(Msg);
handle({gm_set_daily_counter_times, RoleID, Val1,Val2}) ->
	set_mission_remain_times(RoleID,Val1,Val2,true),
	refresh_daily_counter_times(RoleID,Val1,Val2);
handle({gm_reload_daily_counter_conf, RoleID, _Val1}) ->
	reload_daily_daily_counter_conf(RoleID);
handle(Other) ->
	?ERROR_MSG("~ts:~w",["未知消息", Other]).
hook_role_online(RoleID) ->
	refresh_all_daily_counter_times(RoleID).

refresh_all_daily_counter_times(RoleID) ->
	DailyCounterList = cfg_daily_counter:daily_counter(),
	lists:foreach(fun({ActivityID,_,_,_,_})->
						  refresh_daily_counter_times(RoleID,ActivityID,0)
				  end, DailyCounterList).

refresh_daily_counter_times(RoleID,ActivityID,Cnt) ->
	try
		DailyCounterList = cfg_daily_counter:daily_counter(),
		case lists:keyfind(ActivityID, 1, DailyCounterList) of
			{_,_,_,Mod,_} ->
				Mod:refresh_daily_counter_times(RoleID,Cnt);
			_ ->
				ignore
		end
	catch
		T:E -> 
			?ERROR_MSG("刷新~p次数出现问题:~p ~p ~p", [ActivityID,T, E, erlang:get_stacktrace()])
	end.

	
	
init(RoleID, Rec) when is_record(Rec, r_daily_counter) ->
	mod_role_tab:put({?daily_counter, RoleID}, Rec);
init(RoleID, _Rec) ->
	mod_role_tab:put({?daily_counter, RoleID}, #r_daily_counter{}).
delete(RoleID) ->
	mod_role_tab:erase({?daily_counter, RoleID}).
%%
%% Local Functions
%%
%%增加活动次数
add_mission_remain_times(RoleID,ActivityID,Count) ->
	case get_role_daily_counter_info(RoleID,ActivityID) of
		{ok,DailyInfo} ->
			NewDailyInfo = DailyInfo#r_daily_counter_item{activity_id=ActivityID,remain_times=DailyInfo#r_daily_counter_item.remain_times+Count};
		_ ->
			NewDailyInfo = #r_daily_counter_item{activity_id=ActivityID,remain_times=Count}
	end,
	set_role_daily_counter_info(RoleID,NewDailyInfo).

%%设置活动次数
set_mission_remain_times(RoleID,ActivityID,Count,IsNotity) ->
	case get_role_daily_counter_info(RoleID,ActivityID) of
		{ok,DailyInfo} ->
			NewDailyInfo = DailyInfo#r_daily_counter_item{activity_id=ActivityID,remain_times=Count};
		_ ->
			NewDailyInfo = #r_daily_counter_item{activity_id=ActivityID,remain_times=Count}
	end,
	set_role_daily_counter_info(RoleID,NewDailyInfo),
	if
		IsNotity =:= true ->
			R = #m_daily_counter_info_toc{daily_info_item=[#p_daily_info_item{activity_id=ActivityID,remain_times = NewDailyInfo#r_daily_counter_item.remain_times}]},
			common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?DAILY_COUNTER, ?DAILY_COUNTER_INFO, R);
		true ->
			ignore
	end.

%%获取活动次数
get_mission_remain_times(RoleID,ActivityID) ->
	case get_role_daily_counter_info(RoleID,ActivityID) of
		{ok,DailyInfo} ->
			{ok,DailyInfo#r_daily_counter_item.remain_times};
		_ ->
			{error,not_found}
	end.
%%重置活动次数
reset_role_daily_counter_info(RoleID,ActivityID) ->
	case  fetch_daily_counter_conf(RoleID,ActivityID) of
		{_,_,_,_,MaxTimes} ->
			NewDailyCounterItem = #r_daily_counter_item{
												   activity_id=ActivityID,
												   max_times=MaxTimes,
												   remain_times=MaxTimes,
												   last_refresh_time = common_tool:now()
												  },
			set_role_daily_counter_info(RoleID,NewDailyCounterItem),
			{ok,NewDailyCounterItem};
		_ ->
			{error,not_found}
	end.

%%刷新活动次数
try_refresh_role_daily_counter_info(RoleID,ActivityID,E) ->
	case  fetch_daily_counter_conf(RoleID,ActivityID) of
		{_,_,{day,{}},_,_} ->
			{ok,E};
		{_,_,{day,RefreshTime},_,_} ->
			reset_role_daily_counter_info_by_time(RoleID,ActivityID,RefreshTime,E);
		{_,_,{week,{}},_,_} ->
			{ok,E};
		{_,_,{week,RefreshTime},_,_} ->
			{LastRefreshDate, _} = common_tool:seconds_to_datetime(E#r_daily_counter_item.last_refresh_time),
			case common_time:is_in_same_week(date(), LastRefreshDate) of
				true ->
					reset_role_daily_counter_info_by_time(RoleID,ActivityID,RefreshTime,E);
				false ->
					{ok,E}
			end;
		_ ->
			{ok,E}
	end.

reset_role_daily_counter_info_by_time(RoleID,ActivityID,RefreshTime,E) ->
	{LastRefreshDate,_} = common_tool:seconds_to_datetime(E#r_daily_counter_item.last_refresh_time),
	case LastRefreshDate =/= date() andalso RefreshTime =< time() of
		true ->
			case reset_role_daily_counter_info(RoleID,ActivityID) of
				{ok,E1} ->
					{ok,E1};
				_ ->
					{ok,E}
			end;
		_  ->
			{ok,E}
	end.

%%@interface
do_daily_counter_info({Unique, Module, Method, DataIn, RoleID, PID, _Line}=_Msg) ->
	#m_daily_counter_info_tos{activity_id=ActivityIDs} =  DataIn,
	case catch check_do_daily_counter_info(RoleID,ActivityIDs) of
		{ok,_ActivityIDs} ->
			R = do_daily_counter_info_2(RoleID,ActivityIDs);
		{error,ErrCode,Reason}->
			R = #m_daily_counter_info_toc{error_code=ErrCode,reason = Reason}
	end,
	?UNICAST_TOC(R).

do_daily_counter_info_3(RoleID,ActivityID)->
	case catch get_role_daily_counter_info(RoleID,ActivityID) of
		{ok,#r_daily_counter_item{} = E} ->
			{ok,DailyCounterInfo} = try_refresh_role_daily_counter_info(RoleID,ActivityID,E),
			{ok,#p_daily_info_item{activity_id=ActivityID,remain_times = DailyCounterInfo#r_daily_counter_item.remain_times}};
		{error,not_found} ->
			case reset_role_daily_counter_info(RoleID,ActivityID) of
				{ok,DailyCounterInfo} ->
					{ok,#p_daily_info_item{activity_id=ActivityID,remain_times = DailyCounterInfo#r_daily_counter_item.max_times}};
				Error -> 
					?ERROR_MSG("ERR~ts:~w", ["重置活动次数统计系统错误", Error]),
					{ok,#p_daily_info_item{activity_id=ActivityID}}
			end;
		{error,_ErrCode,Reason} ->
			?ERROR_MSG("ERR~ts:~w", ["获取活动次数统计系统错误", Reason]),
			{ok,#p_daily_info_item{activity_id=ActivityID}};
		Reason ->
			?ERROR_MSG("ERR~ts:~w", ["获取活动次数统计系统错误", Reason]),
			{ok,#p_daily_info_item{activity_id=ActivityID}}
	end.

do_daily_counter_info_2(RoleID,ActivityIDs) ->
	DailyItems = lists:foldl(fun(ActivityID,AccIn) ->
									 case catch do_daily_counter_info_3(RoleID,ActivityID) of
										 {ok,DailyItemInfo} ->
											 [DailyItemInfo|AccIn];
										 _ ->
											 AccIn
									 end
							 end, [], ActivityIDs),
	#m_daily_counter_info_toc{daily_info_item=DailyItems}.

reload_daily_daily_counter_conf(RoleID) ->
	DailyCounterConf = fetch_local_daily_counter_conf(RoleID),
	put(?daily_counter_conf,DailyCounterConf).

fetch_local_daily_counter_conf(RoleID) ->
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	DailyCounterConf = cfg_daily_counter:daily_counter(),
	lists:map(fun({ActivityID,ActivityName,RefreshTime,Mod,_} = E) ->
					  case cfg_daily_counter:daily_counter_vip(ActivityID,VipLevel) of
						  [RealTimes] ->
							  {ActivityID,ActivityName,RefreshTime,Mod,RealTimes};
						  _ ->
							  E
					  end
			  end, DailyCounterConf).
%%读取配置项
fetch_daily_counter_conf(RoleID,ActivityID)->
	reload_daily_daily_counter_conf(RoleID),
	case get(?daily_counter_conf) of
		undefined ->
			%%[DailyCounterConf] = common_config_dyn:find(etc, daily_counter),
			DailyCounterConf = fetch_local_daily_counter_conf(RoleID),
			put(?daily_counter_conf,DailyCounterConf);
		DailyCounterConf ->
			ignore
	end,
	case lists:keyfind(ActivityID, 1, DailyCounterConf) of
		false ->
			{error,not_found};
		Conf ->
			Conf
	end.
%%获取玩家活动次数信息
get_role_daily_counter_info(RoleID) ->
	case mod_role_tab:get({?daily_counter,RoleID}) of
		undefined ->
			{error,not_found};
		Rec ->
			{ok,Rec}
	end.

get_role_daily_counter_info(RoleID,ActivityID) ->
	case get_role_daily_counter_info(RoleID) of
		{ok,RoleDailyCounterInfo} ->
			#r_daily_counter{daily_counter_list = RoleDailyItems} = RoleDailyCounterInfo,
			case lists:keyfind(ActivityID, #r_daily_counter_item.activity_id, RoleDailyItems) of
				false ->
					{error,not_found};
				RoleCounterInfo ->
					{ok,RoleCounterInfo}
			end;
		_ ->
			{error,not_found}
	end.


set_role_daily_counter_info(RoleID, DailyCounterItem) ->
	case get_role_daily_counter_info(RoleID) of
		{ok,#r_daily_counter{daily_counter_list = RoleDailyCntItems}} ->
			NewRoleDailyCntItems = lists:keystore(DailyCounterItem#r_daily_counter_item.activity_id, #r_daily_counter_item.activity_id, RoleDailyCntItems, DailyCounterItem),			
			NewRoleDailyCnt = #r_daily_counter{daily_counter_list=NewRoleDailyCntItems};
		_ ->
			NewRoleDailyCnt = #r_daily_counter{daily_counter_list=[DailyCounterItem]}
	end,
	mod_role_tab:put({?daily_counter,RoleID},NewRoleDailyCnt).

check_do_daily_counter_info(RoleID,ActivityIDs) ->
	case erlang:is_list(ActivityIDs) of
		true ->
			lists:foreach(fun(ActivityID)->
								  refresh_daily_counter_times(RoleID,ActivityID,0)
						  end, ActivityIDs),
			{ok,ActivityIDs};
		_ ->
			?THROW_ERR_REASON(<<"前端协议错误，请更新前端">>)
	end.
