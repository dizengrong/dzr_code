%%%----------------------------------------------------------------------
%%% Author  : fsk
%%% Created : 2012-04-01
%%% Description: 外挂处理
%%%----------------------------------------------------------------------
-module(mgeeg_hook).
-include("mgeeg.hrl").
-export([
         legal_all_packet_speed/3, 
         legal_method_packet_speed/2,
         record_packet_detail/2,
		 clear_method_packet_detail/0
        ]).
%% 具体包记录 
-define(method_packet, method_packet).

%% ====================================================================
%% API functions
%% ====================================================================
%% 发包速度是否合法(所有包)
legal_all_packet_speed(RoleID,DifTime,SumPacket) ->
	MaxSpeedLimit = 
		(case common_config_dyn:find(etc, all_packet_speed_limit) of
			[] ->
				20; %%极限
			[SpeedLimit] ->
				SpeedLimit
		end) * map_packet_speed_limit(),
	Legal = (SumPacket / DifTime) =< MaxSpeedLimit,
	case Legal of
		true ->
			show_packet_log(RoleID,DifTime,SumPacket,MaxSpeedLimit,_Method=0);
		false ->
			?ERROR_MSG("玩家[~w]在地图[~w]发包速度过快给踢掉了,[~w]秒发包个数[~w],平均每秒[~w](每秒包数限制[~w])",
					   [RoleID,erlang:get(cur_map_id),DifTime,SumPacket,SumPacket/DifTime,MaxSpeedLimit])
	end,
	Legal.

%% 发包速度是否合法(某些接口)
legal_method_packet_speed(RoleID,DifTime) ->
	case common_config_dyn:find(etc, method_packet_speed_limit) of
		[] ->
			true;
		[MethodList] ->
			MapSpeedLimit = map_packet_speed_limit(),
			lists:all(fun({Method,MaxSpeedLimitTmp})->
							  SumPacket = get_method_sum_packet(Method),
							  MaxSpeedLimit = MaxSpeedLimitTmp * MapSpeedLimit,
							  Legal = (SumPacket / DifTime) =< MaxSpeedLimit,
							  case Legal of
								  true ->
									  show_packet_log(RoleID,DifTime,SumPacket,MaxSpeedLimit,Method);
								  false ->
									  ?ERROR_MSG("玩家[~w]在地图[~w]发包速度过快给踢掉了,[~w]秒发包个数[~w],平均每秒[~w],Method[~w]",
												 [RoleID,erlang:get(cur_map_id),DifTime,SumPacket,SumPacket/DifTime,Method])
							  end,
							  Legal
					  end, MethodList)
	end.

%% 记录发包情况
record_packet_detail(Method,_Record) ->
	case get_method_packet_speed_limit(Method) of
		undefined ->
			ignore;
		_SpeedLimit ->
			case erlang:get(?method_packet) of
				undefined->
					common_misc:update_dict_queue(?method_packet,{Method,1});
				MethodPacketList ->
					case lists:keyfind(Method, 1, MethodPacketList) of
						false ->
							common_misc:update_dict_queue(?method_packet,{Method,1});
						{Method,SumPacket} ->
							MethodPacketList2 = lists:keystore(Method, 1, MethodPacketList, {Method,SumPacket+1}),
							erlang:put(?method_packet,MethodPacketList2)
					end
			end
	end.

%% 清除所有方法的发包情况
clear_method_packet_detail() ->
	erlang:erase(?method_packet).

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
map_packet_speed_limit() ->
	case common_config_dyn:find(etc, map_packet_speed_limit) of
		[] -> 1;
		[List] ->
			MapID = erlang:get(cur_map_id),
			case lists:keyfind(MapID, 1, List) of
				false -> 1;
				{MapID,Multi} ->
					Multi
			end
	end.

%% 获取某个方法的发包数
get_method_sum_packet(Method) ->
	case erlang:get(?method_packet) of
		undefined->
			0;
		MethodPacketList ->
			case lists:keyfind(Method, 1, MethodPacketList) of
				false ->
					0;
				{Method,SumPacket} ->
					SumPacket
			end
	end.

%% 获取某个方法的发包限制
get_method_packet_speed_limit(Method) ->
	case common_config_dyn:find(etc, method_packet_speed_limit) of
		[] ->
			undefined;
		[MethodList] ->
			case lists:keyfind(Method, 1, MethodList) of
				false ->
					undefined;
				{Method,SpeedLimit} ->
					SpeedLimit
			end
	end.

show_packet_log(RoleID,DifTime,SumPacket,MaxSpeedLimit,Method) ->
	case common_config_dyn:find(etc, show_packet_log_roles) of
		[] ->
			nil;
		[LogRoles] ->
			case lists:member(RoleID, LogRoles) of
				true ->
					?ERROR_MSG("玩家[~w]在地图[~w]发包情况:[~w]秒发包个数[~w],平均每秒[~w],(接口[~w]每秒包数限制[~w])",
							   [RoleID,erlang:get(cur_map_id),DifTime,SumPacket,SumPacket/DifTime,Method,MaxSpeedLimit]);
				false ->
					nil
			end
	end.