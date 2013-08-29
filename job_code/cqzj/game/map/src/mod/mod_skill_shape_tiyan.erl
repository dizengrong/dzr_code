
-module(mod_skill_shape_tiyan).

-include("mgeem.hrl").

-export([
    init/2,
    delete/1,
    start_skill_shape_temp/4,
    stop_skill_shape_temp/1,
    hook_online/2
]).
% -record(r_role_skill_time_tiyan, {
%     role_id,
%     p_skill,
%     start_time
% }).

init(RoleID, Rec) when is_record(Rec, r_role_skill_time_tiyan) ->
    mod_role_tab:put({r_role_skill_time_tiyan, RoleID}, Rec);
init(RoleID, _) ->
    mod_role_tab:put({r_role_skill_time_tiyan, RoleID}, #r_role_skill_time_tiyan{}).
delete(RoleID) ->
    mod_role_tab:erase({r_role_skill_time_tiyan, RoleID}).

hook_online(RoleID, Category) ->
    case mod_role_tab:get({r_role_skill_time_tiyan, RoleID}) of
        #r_role_skill_time_tiyan{
            p_skill = #r_role_skill_info{skill_id = SkillID, cur_level = SkillLevel},
            start_time = StartTime
        } ->
            {_, _, ContinueTime} = cfg_mission:change_nuqi_shape_temp(Category),
            NowTime = common_tool:now(),
            case (NowTime - StartTime) >= ContinueTime of
                true -> stop_skill_shape_temp(RoleID);
                false -> 
                    erlang:send_after((NowTime - StartTime) * 1000, self(), {apply, ?MODULE, stop_skill_shape_temp, [RoleID]}),
                    Record1 = #m_skill_shape_tiyan_toc{
                        continue_time = (NowTime - StartTime)
                    },
                    common_misc:unicast(443, RoleID, 0, ?SKILL, ?SKILL_SHAPE_TIYAN, Record1),

                    Record2 = #m_skill_learn_toc{
                        succ = true,
                        skill = #p_role_skill{skill_id=SkillID,cur_level=SkillLevel}
                    },
                    common_misc:unicast(443, RoleID, 0, ?SKILL, ?SKILL_LEARN, Record2)
            end;
        _ -> ignore
    end.

stop_skill_shape_temp(RoleID) ->
    case mod_role_tab:get({r_role_skill_time_tiyan, RoleID}) of
        #r_role_skill_time_tiyan{
            p_skill = #r_role_skill_info{
                skill_id = SkillID,
                cur_level = SkillLevel
            }
        } ->
            {ok, #p_skill_level{
                category = Category
            }} = mod_skill_manager:get_skill_level_info(SkillID,SkillLevel),
            #r_role_skill_info{
                skill_id = PreSkillID
            } = mod_skill:get_role_nuqi_skill(RoleID, Category),
            IsNuqiSkill = mod_skill_manager:is_nuqi_skill(Category, SkillID),
            Fun = fun() ->
                case IsNuqiSkill of
                    true ->
                        mod_skill:change_nuqi_shape(RoleID, PreSkillID, SkillID, SkillLevel);
                    false ->
                        mod_skill:t_add_role_skill(RoleID,SkillID,SkillLevel,Category)
                end
            end,
            case common_transaction:t(Fun) of
                {aborted, Reason} ->
                    ?DBG(Reason);
                    % ?SEND_ERR_TOC2(m_skill_learn_toc,Reason);
                {atomic, _} ->
                    NewRec = #r_role_skill_time_tiyan{
                    },
                    mod_role_tab:put({r_role_skill_time_tiyan, RoleID}, NewRec),

                    Record1 = #m_skill_learn_toc{
                        succ = true,
                        skill = #p_role_skill{skill_id=SkillID,cur_level=SkillLevel}
                    },
                    common_misc:unicast(443, RoleID, 0, ?SKILL, ?SKILL_LEARN, Record1)
            end;
        _ ->
            ignore
    end.

start_skill_shape_temp(RoleID, SkillID, SkillLevel, Time) ->
    case mod_skill_manager:get_skill_level_info(SkillID,SkillLevel) of
        {ok, #p_skill_level{
            category = Category
        }} ->
            #r_role_skill_info{
                skill_id = PreSkillID
            } = PreSkillInfo = mod_skill:get_role_nuqi_skill(RoleID, Category),
            IsNuqiSkill = mod_skill_manager:is_nuqi_skill(Category, SkillID),
            Fun = fun() ->
                case IsNuqiSkill of
                    true ->
                        mod_skill:change_nuqi_shape(RoleID, PreSkillID, SkillID, SkillLevel);
                    false ->
                        mod_skill:t_add_role_skill(RoleID,SkillID,SkillLevel,Category)
                end
            end,
            case common_transaction:t(Fun) of
                {aborted, Reason} ->
                    ?DBG(Reason);
                    % ?SEND_ERR_TOC2(m_skill_learn_toc,Reason);
                {atomic, _} ->
                    Record = #r_role_skill_time_tiyan{
                        p_skill = PreSkillInfo,
                        start_time = common_tool:now()
                    },

                    mod_role_tab:put({r_role_skill_time_tiyan, RoleID}, Record),
                    erlang:send_after(Time * 1000, self(), {apply, ?MODULE, stop_skill_shape_temp, [RoleID]}),

                    Record1 = #m_skill_shape_tiyan_toc{
                        continue_time = Time
                    },
                    common_misc:unicast(443, RoleID, 0, ?SKILL, ?SKILL_SHAPE_TIYAN, Record1),

                    Record2 = #m_skill_learn_toc{
                            succ = true,
                            skill = #p_role_skill{skill_id=SkillID,cur_level=SkillLevel}
                    },
                    common_misc:unicast(0, RoleID, ?DEFAULT_UNIQUE, ?SKILL, ?SKILL_LEARN, Record2)

            end;
        _ -> ignore
    end.
