%%%-------------------------------------------------------------------
%%% @author xierongfeng
%%%-------------------------------------------------------------------
-module(hook_role).

-include("mgeer.hrl").


%% API
-export([
		 online/2,
		 offline/1,
         init/0,
         terminate/0
        ]).

online(RoleID, IsFirstEnter) -> 
	PID = get('PID'),
	{ok, #p_role_attr{level=Level,category=Category}} = mod_map_role:get_role_attr(RoleID),
	{ok, RoleBase = #p_role_base{}} = mod_map_role:get_role_base(RoleID),

	case IsFirstEnter of
		true ->
			catch mod_map_role:update_online_time(RoleID),
			mod_pk:login_pk_init(RoleID),
			mod_pet_grow:hook_role_online(RoleID),
			mod_role_buff:hook_role_online(RoleID),
			?TRY_CATCH(mod_horse_racing:hook_role_online(RoleID),Err7);
		_ ->
			mod_horse_racing:horse_racing_exit(RoleID, PID)
	end,
	%% mod_role_signin:get_continue_info(RoleID),
	mod_time_gift:send_time_gift(RoleID),
	mod_level_gift:send_role_level_gift(RoleID),
	common_title:send_sence_titles(RoleID),
	mod_system:sys_config_init(RoleID, PID),
	mod_shortcut:shortcut_init(RoleID, Category, PID),
	mod_role_skill:hook_role_online(RoleID, PID),
    mod_gray_name:login_gray_name_init(RoleID),
    mod_vip:hook_role_online(RoleID),
    mod_swl_mission:hook_role_online(RoleID, Level),
	mod_qq:send_yvip_to_client(RoleID, true),
	mod_yvip_activity:notice_activity(RoleID),
	mod_daily_counter:hook_role_online(RoleID),
	mod_open_activity:hook_role_online(RoleID),
    mod_share_invite:cast_share_invite_info(RoleID),
    mod_role_mount:notice_last_mount(RoleID),
    mod_pet_training:init_pet_training(RoleID),
    mod_consume_task:hook_role_online(RoleID),
    mod_rage_practice:hook_role_online(RoleID),
	
	FuncList = [
                fun()-> mod_mission_auto:check_auto_mission_finish(RoleID) end,
                fun()-> mod_examine_fb:hook_role_online(RoleID, Level) end,
                fun()-> mod_present:hook_role_online(RoleID) end,
				fun()-> mod_newcomer:hook_role_online(RoleID) end,
				fun()-> mod_activity:send_dingzi_info_to_client(RoleID) end,
				fun()-> mod_map_pet:send_role_pet_bag_info(RoleID) end,
				fun()-> mod_fulu:send_fulu_to_client(RoleID) end
               ],
    [?HOOK_CATCH(F) || F <- FuncList],
	?TRY_CATCH(mod_tili:hook_role_online(RoleID),Err9),
	?TRY_CATCH(hook_guide_tip:hook_buy_guide_mission(RoleID),Err11),
	?TRY_CATCH(mod_access_guide:cast_access_guide_info(RoleID),Err12),
	?TRY_CATCH(mod_daily_mission:hook_role_online(RoleID,Level),Err13),
	?TRY_CATCH(mod_jinglian:cast_jinglian_all(RoleID,Level),Err14),
	?TRY_CATCH(common_title:hook_role_online(RoleID),Err15),
	?TRY_CATCH(mod_nuqi_huoling:hook_role_online(RoleID),Err16),
	%% 检查唐僧任务状态
	?TRY_CATCH(mod_mission_change_skin:hook_reload_mission(RoleBase),ErrMiss),
	ok.
	% ?TRY_CATCH(mod_skill_shape_tiyan:hook_online(RoleID,Category),Err15).

offline(RoleID) ->
    mod_map_role:set_role_exit_game_mark(RoleID),
	{ok, RoleState} = mod_map_role:get_role_state(RoleID),
	#r_role_state2{client_ip=ClientIP} = RoleState,
    catch mod_map_role:update_offline_time_and_ip(RoleID, ClientIP),
	catch mod_role_buff:hook_role_offline(RoleID),
	catch mod_open_activity:hook_role_offline(RoleID),
	?TRY_CATCH(mod_horse_racing:hook_role_offline(RoleID), Err4),
	?TRY_CATCH(mod_guard_fb:hook_role_quit(RoleID),Err6),
	?TRY_CATCH(mod_examine_fb:hook_role_offline(RoleID),Err7),
	mod_map_role:persistent_role_detail(RoleID).

init() ->
    ?TRY_CATCH(mod_refining_bag:init_drop_goods_id(),Err1),
	ok.

terminate() ->
	RoleID = get(role_id),
	case mod_map_role:is_role_exit_game(RoleID) of
		false ->
			offline(RoleID);
		true ->
			ignore
	end,
	ok.
