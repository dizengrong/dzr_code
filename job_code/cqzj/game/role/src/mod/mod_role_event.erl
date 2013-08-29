-module(mod_role_event).

-export([
	notify/2, 
	add_handler/3, 
	delete_handler/3, 
	swap_handler/4, 
	get_handlers/2
]).

-include("mgeer.hrl").

notify(RoleID, Event) when RoleID > 0 ->
	EventTag = element(1, Event),
	case get_handlers(RoleID, EventTag) of
		undefined -> ignore;
		Handlers  ->
			lists:foreach(fun
				({Handler, Args}) ->
					Handler:handle_event(RoleID, Event, Args)
			end, Handlers)
	end;
notify(_, _) -> ignore.

add_handler(RoleID, EventTag, {Handler, Args}) ->
	swap_handler(RoleID, EventTag, Handler, {Handler, Args}).

delete_handler(RoleID, EventTag, {Handler, Args}) ->
	mod_role_tab:put(RoleID, {event_handlers, EventTag}, 
		lists:delete({Handler, Args}, 1, get_handlers(RoleID, EventTag)));
delete_handler(RoleID, EventTag, Handler) ->
	mod_role_tab:put(RoleID, {event_handlers, EventTag}, 
		lists:keydelete(Handler, 1, get_handlers(RoleID, EventTag))).

swap_handler(RoleID, EventTag, {H1, A1}, {H2, A2}) ->
	mod_role_tab:put(RoleID, {event_handlers, EventTag}, 
		[{H2, A2}|lists:delete({H1, A1}, 1, get_handlers(RoleID, EventTag))]);
swap_handler(RoleID, EventTag, H1, {H2, A2}) ->
	mod_role_tab:put(RoleID, {event_handlers, EventTag}, 
		[{H2, A2}|lists:keydelete(H1, 1, get_handlers(RoleID, EventTag))]).

get_handlers(RoleID, EventTag) ->
	case mod_role_tab:get(RoleID, {event_handlers, EventTag}) of
		undefined -> [];
		Handlers  -> Handlers
	end.

%%
%% Local Functions
%%
