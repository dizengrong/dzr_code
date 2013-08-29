%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     每天凌晨0点执行的的hook
%%%     这里应尽量少处理事情
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(hook_at_oclock).
-export([hook/1]).

%%
%% Include files
%%
-include("mgeem.hrl").


%% ====================================================================
%% API functions
%% ====================================================================

hook( [] )->
    ignore;
hook( MapRoleIDList )->
    ?TRY_CATCH( do_reset_role_energy( MapRoleIDList ),Err1 ),
    ?TRY_CATCH( do_reset_role_actpoint( MapRoleIDList ),Err2 ),
    ?TRY_CATCH( do_reset_time_gift( MapRoleIDList ),Err3 ),
    ?TRY_CATCH( do_reset_mission( MapRoleIDList ),Err4 ),
    ok.

%%每天凌晨重置玩家的活跃度
do_reset_role_actpoint( MapRoleIDList )->
    hook_activity_task:reset_all_online_actpoint( MapRoleIDList ).

%%每天凌晨重置玩家的精力值
do_reset_role_energy( MapRoleIDList ) when is_list(MapRoleIDList)->
    Now = common_tool:now(),
    lists:foreach(
      fun(RoleID) ->
          mod_map_role:do_reset_role_energy(RoleID, Now)
      end, MapRoleIDList).

do_reset_time_gift( MapRoleIDList) when is_list(MapRoleIDList) ->
    lists:foreach(
      fun(RoleID) ->
          mod_time_gift:send_time_gift(RoleID),
          mod_share_invite:send_init(RoleID)
      end, MapRoleIDList).

do_reset_mission( MapRoleIDList) when is_list(MapRoleIDList) ->
    VS = mod_mission_data:get_vs(),
    lists:foreach(
      fun(RoleID) ->
          mission_model_common:reload_at_oclock(RoleID, VS)
      end, MapRoleIDList).
