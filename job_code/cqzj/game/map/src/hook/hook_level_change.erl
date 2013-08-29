%%% -------------------------------------------------------------------
%%% Author  : xiaosheng
%%% Description : 等级变更通知
%%%
%%% Created : 2010-6-4
%%% -------------------------------------------------------------------
-module(hook_level_change).
-export([
         hook/1,
         hook_mission/2
        ]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").

%% --------------------------------------------------------------------
%% Function: hook/1
%% Description: hook检查口
%% Parameter: int() RoleID 角色id
%% Parameter: int() OldLevel 旧等级
%% Parameter: int() NewLevel 新等级
%% Returns: ok
%% --------------------------------------------------------------------
%%检查
hook({RoleID, OldLevel, NewLevel, FactionID}) ->
    hook_log_level(RoleID, NewLevel, FactionID),
    hook_chat(RoleID, OldLevel, NewLevel, FactionID),
    hook_behavior(RoleID, NewLevel),
    hook_mission(RoleID,NewLevel),
    hook_qrhl(RoleID,NewLevel),
	hook_nimbus(RoleID,OldLevel,NewLevel),
    hook_friend(RoleID,OldLevel,NewLevel),
    hook_family(RoleID,OldLevel,NewLevel),
    hook_exchange_active_deal(RoleID,OldLevel,NewLevel),
	mod_map_pet:hook_role_level_change(RoleID),
	mod_access_guide:cast_access_guide_info(RoleID),
    mod_daily_mission:hook_role_level_change(RoleID,NewLevel),
	mod_guard_fb:hook_role_level_change(RoleID,NewLevel),
	mod_swl_mission:hook_role_level_change(RoleID,NewLevel),
	mod_jinglian:cast_jinglian_all(RoleID,NewLevel),
    mod_goal2:role_level_change(RoleID,NewLevel),
    mod_share_invite:cast_share_invite_info(RoleID),


%%    mod_role_signin:get_continue_info(RoleID),

	%%玩家25级自动加入家族
	hook_auto_join_family(OldLevel, NewLevel, RoleID),

    % mod_level_gift:send_role_level_gift(RoleID),
%% 取消等级礼包，改为用称号礼包
    hook_level_gift(RoleID),
    hook_accumulate_exp(RoleID,NewLevel),
    % hook_goal(RoleID,NewLevel),
    %% 当前国家玩家在线榜
    case common_config_dyn:find(etc,do_faction_online_role_rank_map_id) of
        [FactionOnlineRoleRankMapId] ->
            {ok, #p_role_attr{role_name = RoleName}} = mod_map_role:get_role_attr(RoleID),
            catch global:send(common_map:get_common_map_name(FactionOnlineRoleRankMapId),
                              {mod_role2,{admin_uplevel_faction_online_rank,
                                          {RoleID,RoleName,FactionID,NewLevel,FactionOnlineRoleRankMapId}}});
        _ ->
            ignore
    end,
	hook_guide_tip:hook_buy_guide_mission(RoleID),
    mod_equip_gems:role_level_up(RoleID, NewLevel),
    mod_examine_fb:role_level_up(RoleID, NewLevel),
    mod_share_invite:level_upgrade_award(RoleID, NewLevel),
    mod_activity:send_dingzi_info_to_client(RoleID),
    ok.


%% ====================================================================
%% 第三方hook代码放置在此
%% ====================================================================

hook_exchange_active_deal(RoleID,_OldLevel,NewLevel)->
    ?TRY_CATCH( mod_exchange_active_deal:hook_role_notify(RoleID,NewLevel) ).

%%累积经验
hook_accumulate_exp(RoleID,NewLevel)->
    case NewLevel>19 of
        true ->
            ?TRY_CATCH( mod_accumulate_exp:do_update_lv(RoleID,NewLevel));
        false ->
            ignore
    end.

%%记录玩家的级别更新日志
hook_log_level(RoleID, NewLevel, FactionID)->
    Now = common_tool:now(),
    R2 = #r_role_level_log{role_id=RoleID,faction_id=FactionID,level=NewLevel,log_time=Now},
    common_general_log_server:log_role_level(R2).

%%触发任务更新
hook_mission(RoleID,NewLevel) ->
   Msg =  {mod_mission_handler, {listener_dispatch, role_level_up, RoleID, NewLevel}},
   mgeer_role:absend(RoleID, Msg).

%% 七日好礼
hook_qrhl(RoleID, NewLevel) ->
    mod_qrhl:send_event(RoleID, shengji, NewLevel).

%%行为日志
hook_behavior(RoleID, RoleLevel) ->
    common_behavior:send({role_level, RoleID, RoleLevel}).

%%同等级聊天频道变化
hook_chat(RoleID, OldLevel, NewLevel, FactionID) ->
    RouterData = {level_change, OldLevel, NewLevel, FactionID},
    common_misc:chat_cast_role_router(RoleID, RouterData).

hook_nimbus(RoleID,_OldLevel,_NewLevel) ->
	mod_nimbus:hook_change_level(RoleID).
hook_friend(RoleID,OldLevel,NewLevel) ->
    gen_server:cast({global, mod_friend_server}, {upgrade_notice, RoleID, OldLevel, NewLevel}).

hook_family(RoleID,_OldLevel,NewLevel)->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    FamilyId = RoleBase#p_role_base.family_id,
    if FamilyId > 0 ->
	    ?DEBUG("memberuplevelhookfamily2 ",[]),
	    global:send(mod_family_manager,{member_levelup,FamilyId,RoleID,NewLevel});
       true ->
	    ignore
    end.

hook_auto_join_family(OldLevel, NewLevel, RoleID) ->
	case NewLevel >= 25 andalso OldLevel < 25 of
		true ->
			global:send(mod_family_manager, {auto_join_family, RoleID});
		false ->
			[]
	end.

hook_level_gift(RoleID) ->
    mgeer_role:absend(RoleID, {apply, mod_level_gift, send_role_level_gift, [RoleID]}).

% mod_level_gift:send_role_level_gift(RoleID),