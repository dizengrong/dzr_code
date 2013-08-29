%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     任务更新的hook
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(hook_mission_update).
-export([
	hook/3, 
	create_monster/2,
	create_monster_if_not_exists/2,
	update_grafts/3,
	add_nuqi/2,
    cross_jingjie_mission/2,
    cross_equip_upgrade_mission/2,
    change_nuqi_shape_temp/2
]).

%%
%% Include files
%%
-include("mission.hrl"). 


%% ====================================================================
%% API functions
%% ====================================================================

%%@doc 任务的hook入口
hook(HookType,RoleID,MissionBaseInfo) ->
    #mission_base_info{id=MissionID,faction=FactionId,type=MissionType,max_do_times=MaxDoTimes} = MissionBaseInfo,
    {ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    do_hook(HookType,FactionId,{RoleID,RoleLevel,MissionID,MissionType,MaxDoTimes}).
        

%%call backs
%%任务已接受：
do_hook(mission_accept,_FactionId,MissionLogArgs) ->
	{RoleID,_RoleLevel,MissionID,_MissionType,_MaxDoTimes} = MissionLogArgs,
	case cfg_mission:after_mission_accept(MissionID) of
		MFAs when is_list(MFAs) ->
			?TRY_CATCH(after_mission_accept(RoleID, MFAs));
		_ ->
			ignore
	end,
    common_mission_logger:log_accept(MissionLogArgs);

%%任务已取消：
do_hook(mission_cancel,_FactionId,{RoleID,_,MissionID,_,_}=MissionLogArgs)->
	mod_mission_change_skin:hook_cancel_mission(RoleID,MissionID),
    common_mission_logger:log_cancel(MissionLogArgs);

%%任务已完成(处于可提交状态，但未提交)：
do_hook(mission_finish,_FactionId, MissionLogArgs) ->
    common_mission_logger:log_finish(MissionLogArgs);

%%任务已提交，即领奖
do_hook(mission_commit,_FactionId,{RoleID,_RoleLevel,MissionID,?MISSION_TYPE_LOOP,_}) ->
    %% 循环任务只处理活动奖励，不记录日志啦
	%%hook_mission_goal(RoleID,MissionID),
	mod_mission_change_skin:hook_finish_mission(RoleID,MissionID),
    ?TRY_CATCH( do_hook_commit_loop_mission(RoleID, MissionID) );
do_hook(mission_commit,_FactionId, {RoleID,_,MissionID,_,_}=MissionLogArgs) ->
    {RoleID,_RoleLevel,MissionID,_MissionType,_MaxDoTimes} = MissionLogArgs,

    case cfg_mission:after_mission_commit(MissionID) of
        MFAs when is_list(MFAs) ->
            ?TRY_CATCH(after_mission_commit(RoleID, MFAs));
        _ ->
            ignore
    end,

    %% 只记录非循环任务
    common_mission_logger:log_commit(MissionLogArgs).



%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%%@doc 完 成循环任务之后，增加相应活跃度
do_hook_commit_loop_mission(RoleID, MissionID)->
    %% 20002 守边 
    %% 20003 刺探
    SpecialActIDList = [
                        ?ACTIVITY_TASK_SHOUBIAN,
                        ?ACTIVITY_TASK_SPY],
    do_hook_commit_loop_mission_2(RoleID,MissionID,SpecialActIDList).

%%@param RoleID::integer()
%%@param MissionID::integer()
%%@param SpecialActIDList::list()
do_hook_commit_loop_mission_2(_RoleID,_MissionID,[])->
    ok;
do_hook_commit_loop_mission_2(RoleID,MissionID,[SpecialActTaskID|T])->
    case lists:member(MissionID, get_missn_id_list(SpecialActTaskID)) of
        true->  
            hook_activity_task:done_task(RoleID,SpecialActTaskID),
            hook_activity_map:hook_mission(RoleID,SpecialActTaskID),
            ok;
        _ ->
            do_hook_commit_loop_mission_2(RoleID,MissionID,T)
    end.

%%@doc 从任务配置中获取对应的任务ID列表
%%     任务对应的key配置在activity_mission.config中
get_missn_id_list(Key)->
    case common_config_dyn:find(activity_mission,Key) of
        [#r_activity_mission{mission_id_list=MissionIDList}] ->
            MissionIDList;
        _ ->
            []
    end.

after_mission_accept(_RoleID, []) ->
	ignore;
after_mission_accept(RoleID, [MFA|T]) ->
	case MFA of
		{F, A} ->
			apply(?MODULE, F, [RoleID, A]);
		{M, F, A} ->
			apply(M, F, [RoleID, A])
	end,
	after_mission_accept(RoleID, T).

after_mission_commit(_RoleID, []) ->
    ignore;
after_mission_commit(RoleID, [MFA|T]) ->
    case MFA of
        {F, A} ->
            apply(?MODULE, F, [RoleID | A]);
        {M, F, A} ->
            apply(M, F, [RoleID | A])
    end,
    after_mission_commit(RoleID, T).

% examine_fb_handle(_RoleID, []) ->
%     ignore;
% examine_fb_handle(RoleID, [MFA|T]) ->
%     case MFA of
%         {F, A} ->
%             apply(?MODULE, F, [RoleID | A]);
%         {M, F, A} ->
%             apply(M, F, [RoleID | A])
%     end,
%     examine_fb_handle(RoleID, T).

create_monster(_RoleID, Monsters) ->
	mgeem_map:absend({mod_map_monster, {dynamic_create_monster2, Monsters}}).

create_monster_if_not_exists(_RoleID, Monsters) ->
	mgeem_map:absend({mod_map_monster, {create_monster_if_not_exists, Monsters}}).

update_grafts(_RoleID, MapID, PointID) ->
	mod_map_collect:update_grafts(MapID, PointID).

add_nuqi(RoleID, AddNuqi) ->
	mod_map_role:add_nuqi(RoleID, AddNuqi).

cross_jingjie_mission(RoleID, BarrierID) ->
    case mod_hero_fb:cross_jingjie_mission(RoleID, BarrierID, ?HERO_FB_MODE_TYPE_NORMAL) of
        true ->
            % hook_mission_event:hook_jingjie(RoleID, BarrierID);
            mgeer_role:absend(RoleID, {apply, hook_mission_event, hook_jingjie, [RoleID, BarrierID]});
        false ->  ignore
    end.

cross_equip_upgrade_mission(RoleID, {UpgradeNum, SlotNum}) -> 
    case mod_qianghua:cross_equip_upgrade_mission(RoleID, UpgradeNum, SlotNum) of
        true ->
            mgeer_role:absend(RoleID, {apply, hook_mission_event, hook_equip_upgrade, [RoleID, SlotNum]});
        false -> ignore
    end.

%%[{change_nuqi_shape_temp, {怒气id, 怒气等级, 持续时间(秒数)}}]
change_nuqi_shape_temp(RoleID, _) ->
    {ok, #p_role_attr{category = Category}} = mod_map_role:get_role_attr(RoleID),
    {SkillID, SkillLevel, Time} = cfg_mission:change_nuqi_shape_temp(Category),
    mod_skill:change_skill_level_temp(RoleID),
    mod_skill_shape_tiyan:start_skill_shape_temp(RoleID, SkillID, SkillLevel, Time).
