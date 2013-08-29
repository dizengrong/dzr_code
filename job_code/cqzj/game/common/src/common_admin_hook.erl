-module(common_admin_hook).
-export([
	 hook/1
	]).
-include("common.hrl").
-include("common_server.hrl").

%% API

hook(HookMessage)->    
    case HookMessage of 
        {accept_first_task,RoleID}->
            AbsIP = get_role_ip(RoleID),
            global:send(mgeew_behavior_log_server,{accept_first_task,RoleID,AbsIP});
        {enter_flash_game,RoleID,ClientIP}->
            AbsIP = get_role_ip_2(ClientIP),
            global:send(mgeew_behavior_log_server,{enter_flash_game,RoleID,AbsIP});
        Other ->
            ?ERROR_MSG("hook error message,~w",[ Other ]),
            ignore
    end.
        

get_role_ip(RoleID)->
    get_role_ip_2( common_misc:get_online_role_ip(RoleID) ).

get_role_ip_2(ClientIP)->
    case ClientIP of
        undefined->
            {127,0,0,1};
        Val -> 
            Val
    end.

