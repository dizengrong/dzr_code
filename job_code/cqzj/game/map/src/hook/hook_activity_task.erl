%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     hook_activity_task 跟日常活动、日常福利、玩家的活跃度有关的Hook
%%% @end
%%% Created : 2010-11-17
%%%-------------------------------------------------------------------
-module(hook_activity_task).
-include("mgeem.hrl").

-define(MAX_ROLE_ACTPOINT,27).  %%玩家的最高活跃度

%% API
-export([
         handle/2,
         done_task/2,
         reset_all_online_actpoint/1
        ]). 

handle({done_task,{RoleID,ActivityKey}},_State)->
    done_task(RoleID,ActivityKey);
handle(Msg,_State)->
    ?ERROR_MSG("unknown message,Msg=~w",[Msg]),
    ignore.

%%%===================================================================
%%% API
%%%===================================================================

%%@doc 每天凌晨重置在线玩家的活跃度
reset_all_online_actpoint( MapRoleIDList ) when is_list(MapRoleIDList)->
    lists:foreach(fun(RoleID)-> 
                          db:dirty_delete(?DB_ROLE_ACTIVITY_BENEFIT,RoleID),
                          TransFun = fun()-> 
                                             case mod_map_role:get_role_attr(RoleID) of
                                                 {ok,RoleAttr} ->
                                                     RoleAttr2 = RoleAttr#p_role_attr{active_points=0},
                                                     mod_map_role:set_role_attr(RoleID,RoleAttr2);
                                                 _ ->
                                                     ignore
                                             end
                                     end,
                          case common_transaction:transaction( TransFun ) of
                              {atomic, _} ->
                                  notify_ap_change(RoleID,0);
                              {aborted, Error} ->
                                  ?ERROR_MSG_STACK("reset_all_online_actpoint error",Error)
                          end  
                  end, MapRoleIDList).

%%@doc 玩家完成相应的任务, 增加活跃度，设置任务的完成次数、日常任务福利
done_task(RoleID, ActTaskID) -> 
    try
        case lists:member(ActTaskID, cfg_activity:all_activity()) of
            true ->
                mod_daily_activity:do_finish_task(RoleID, ActTaskID);
            false ->
                ignore
        end
    catch
        Type:Reason->
            ?ERROR_MSG("ActTaskID: ~w, Type: ~w, Reason: ~w, stack: ~w", 
                        [ActTaskID, Type, Reason, erlang:get_stacktrace()])
    end.

%% ====================================================================
%% Internal functions
%% ====================================================================
%%@doc 通知前端更新活跃度
notify_ap_change(RoleID,NewActivePt)->
    ChangeAttList = [#p_role_attr_change{change_type=?ROLE_ACTIVE_POINTS_CHANGE,new_value=NewActivePt}],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeAttList).

 
