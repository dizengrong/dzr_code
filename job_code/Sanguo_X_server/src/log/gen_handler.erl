-module(gen_handler).

-include("common.hrl").
-behaviour(gen_event).

-export([init/1, terminate/2, handle_event/2, handle_info/2, handle_call/2, code_change/3]).


init(Node) ->
	{ok, Node}.

handle_call(_Request, _State) ->
	{ok, _State}.

handle_event(Event = {Type, _GL, _},Node) ->
	if (Type == error orelse Type == warning_msg orelse Type == info_msg) -> 
		gen_event:notify({error_logger, Node}, Event);
	true ->
		ok
	end,
	{ok, Node}.
			
handle_info(_Info, _State) ->
	{ok, _State}.

terminate(_Arg, _State) ->
	ok.

code_change(_OldVsn, _State, _Extra) ->
	{ok, _State}.

%===================================================================================================
% internal function
%===================================================================================================




