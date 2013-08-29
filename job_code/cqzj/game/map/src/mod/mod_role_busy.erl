%% Author: xierongfeng
%% Created: 2013-2-17
%% Description: 对玩家采集、使用特殊道具等进程的封装
-module(mod_role_busy).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([set/2, unset/1, stop/1, check/1]).

%%
%% API Functions
%%
set(RoleID, PID) ->
	put({busy, RoleID}, PID).

unset(RoleID) ->
	erase({busy, RoleID}).

stop(RoleID) ->
	case get({busy, RoleID}) of
		undefined ->
			ignore;
		PID ->
			PID ! stop
	end.
  
check(RoleID) ->
	PID = get({busy, RoleID}),
	case is_pid(PID) andalso is_process_alive(PID) of
		true ->
			{error, <<"另一个动作正在进行中">>};
		_ ->
			ok
	end.


%%
%% Local Functions
%%

