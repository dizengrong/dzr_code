-module (mod_common_map).

-export ([handle/1]).

handle({init, _MapID, _MapName}) ->
	ignore;

handle({role_enter, _RoleID, _MapID}) ->
	ignore;

handle({before_role_quit, _RoleID}) ->
	ignore;

handle({role_quit, _RoleID}) ->
	ignore.

