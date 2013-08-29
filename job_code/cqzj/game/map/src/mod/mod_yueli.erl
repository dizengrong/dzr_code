%%%-------------------------------------------------------------------
%%% 阅历模块
%%%-------------------------------------------------------------------
-module(mod_yueli).

-include("mgeem.hrl").
-export([
			handle/1,
			handle/2
		]).
-export([
			add_yueli/3
		]).
handle(Msg,_State) ->
	handle(Msg).
handle({gm_set_yueli,RoleID,Yueli}) ->
    gm_set_yueli(RoleID,Yueli);

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

gm_set_yueli(RoleID,Yueli) ->
	case common_transaction:transaction(
		   fun() ->
                   {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
                   NewRoleAttr = RoleAttr#p_role_attr{yueli = Yueli},
                   mod_map_role:set_role_attr(RoleID,NewRoleAttr),
                   {ok,NewRoleAttr}
		   end)
		of
		{atomic, {ok, NewRoleAttr}} ->
			common_misc:send_role_yueli_change(RoleID,NewRoleAttr);
		{aborted, Reason} ->
			?ERROR_MSG("gm_set_yueli error, reason: ~w", [Reason])
	end.

add_yueli(RoleID,AddYueli,LogType) ->
	case common_transaction:transaction(
		   fun() ->
				   common_bag2:t_gain_yueli(AddYueli,RoleID,LogType)
		   end)
		of
		{atomic, {ok, NewRoleAttr}} ->
			common_misc:send_role_yueli_change(RoleID,NewRoleAttr);
		{aborted, Reason} ->
			?ERROR_MSG("add_yueli error, reason: ~w", [Reason])
	end.