%% Author: Andrew
%% Created: 2012-10-30
%% Description: 地图事件管理器
-module(mod_map_event).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([notify/2, 
		 add_handler/2, 
		 add_handler/3, 
		 delete_handler/1, 
		 delete_handler/2, 
		 delete_handler/3, 
		 swap_handler/3, 
		 get_handlers/1]).



%%
%% API Functions
%%
notify(Who, Event) ->
	case get({handlers, Who}) of
		undefined ->
			ignore;
		Handlers ->
			lists:foreach(fun
				({Handler, Args}) ->
					Handler:handle_event(Who, Event, Args);
				(Handler) ->
					Handler:handle_event(Who, Event)
			end, Handlers)
	end.

add_handler(Who, Handler) ->
	put({handlers, Who}, [Handler|lists:delete(Handler, get_handlers(Who))]).

add_handler(Who, Handler, Args) ->
	put({handlers, Who}, [{Handler, Args}|get_handlers(Who)]).

delete_handler(Who) ->
	erase({handlers, Who}).

delete_handler(Who, Handler1) ->
	put({handlers, Who}, lists:filter(fun
		({Handler2, _Args}) when Handler2 == Handler1 ->
			false;
		(Handler2) when Handler2 == Handler1 ->
			false;
		(_) ->
			true
	end, get_handlers(Who))).

delete_handler(Who, Handler1, Args1) ->
	put({handlers, Who}, lists:filter(fun
		({Handler2, Args2}) when Handler2 == Handler1, Args2 == Args1 ->
			false;
		(_) ->
			true
	end, get_handlers(Who))).

swap_handler(Who, H1, H2) ->
	put({handlers, Who}, [case H of H1 -> H2; Any -> Any end||H<-get_handlers(Who)]).

get_handlers(Who) ->
	case get({handlers, Who}) of undefined -> []; Handlers -> Handlers end.

%%
%% Local Functions
%%
