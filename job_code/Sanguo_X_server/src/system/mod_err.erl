%% Author: cjr
%% Created: 2011-10-19
%% Description: define common error interface

-module(mod_err).

%%
%% Include files
%%
-include("common.hrl").


-export([send_error/4,  send_err/3, send_err_by_id/2, send_err/2]).

send_error(pid,Send_pid, Error_mod,Error_code) ->
	{ok, Bin} = pt_err:write(10999,{Error_mod,Error_code}),
	?INFO(to_client_err,"~w, ~w, ~w", [Send_pid, Error_mod,Error_code]),
	lib_send:send(Send_pid, Bin);
	
send_error(name,Send_name,Error_mod,Error_code)->
	{ok, Bin} = pt_err:write(10999,{Error_mod,Error_code}),
	?INFO(to_client_err,"~w, ~w, ~w", [Send_name, Error_mod,Error_code]),
	lib_send:send_to_nick(Send_name,Bin).

send_err(PlayerId, ErrorMod, ErrorCode) ->
	{ok, Bin} = pt_err:write(10999, {ErrorMod, ErrorCode}),
	lib_send:send_by_id(PlayerId,Bin).

send_err(PlayerId, ErrorCode) ->
	{ok, Bin} = pt_err:write(10999, {0, ErrorCode}),
	lib_send:send_by_id(PlayerId, Bin).

send_err_by_id(PlayerId, ErrorCode) ->
	{ok, Bin} = pt_err:write(10999, {0, ErrorCode}),
	lib_send:send_by_id(PlayerId, Bin).

