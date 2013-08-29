%%% -------------------------------------------------------------------
%%% Author  : xiaosheng
%%% Description : 学习技能
%%%
%%% Created : 2010-9-5
%%% -------------------------------------------------------------------
-module(hook_skill_learn).
-export([
         hook/1,
         hook/2,
         upgrade_jingjie_skill/1,
         change_system_config/1
         % change_max_nuqi/3
        ]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeem.hrl").

upgrade_jingjie_skill({_RoleID, _SkillID, _CurLevel}) ->
    ok.

%% --------------------------------------------------------------------
%% Function: hook/1
%% Description: hook检查口
%% Parameter: int() RoleID 角色id
%% Parameter: int() SkillID 技能ID
%% Parameter: int() CurLevel 当前等级
%% Returns: ok
%% --------------------------------------------------------------------
%%检查
hook({RoleID, DelSkillID, SkillID, CurLevel}) ->
	hook({RoleID, DelSkillID, SkillID, CurLevel}, CurLevel == 1).
hook({RoleID, DelSkillID, SkillID, CurLevel}, ChangeSysCfg) ->
	if 
		not ChangeSysCfg -> 
			ignore;
		SkillID == 90100001;
		SkillID == 90100002;
		SkillID == 90100003;
		SkillID == 90100004;
		SkillID == 90200001;
		SkillID == 90200002;
		SkillID == 90200003;
		SkillID == 90200004 ->
			change_system_config({RoleID, SkillID, SkillID, CurLevel});
		SkillID == 91000002;
		SkillID == 91000003;
		SkillID == 91000004;
		SkillID == 92000002;
		SkillID == 92000003;
		SkillID == 92000004 ->
			change_system_config({RoleID, DelSkillID, SkillID, CurLevel});
		true ->
			ignore
	end,
	?TRY_CATCH(mod_examine_fb:hook_skill_upgrade(RoleID, SkillID, CurLevel)),
	hook_mission_event:hook_skill_upgrade(RoleID,CurLevel),

    SkillBaseList = common_config_dyn:list(skill),
    case lists:keyfind(SkillID, 2, SkillBaseList) of
        #p_skill{kind = ?SKILL_KIND_CATEGORY} ->
            mod_qrhl:send_event(RoleID, skill, CurLevel);
        _ ->
            ignore
    end,
    % change_max_nuqi(RoleID, SkillID, CurLevel),
    ok.

% change_max_nuqi(RoleID, SkillID, CurLevel) ->
%     case cfg_role_nuqi:add_nuqi(SkillID, CurLevel) of
%     	MaxNuqi when MaxNuqi < 0 ->
%     		mod_map_role:change_max_nuqi(RoleID, -MaxNuqi);
%     	_ ->
%     		ignore
%     end.

change_system_config({RoleID, DelSkillID, SkillID, CurLevel}) ->
	[#r_sys_config{sys_config=SysConfig}] = db:dirty_read(?DB_SYSTEM_CONFIG, RoleID),
	SkillList1 = SysConfig#p_sys_config.skill_list,
	AutoNuqiShow = SysConfig#p_sys_config.auto_use_nuqi_skill,
	NewSkill  = #p_role_skill{skill_id=SkillID, cur_level=CurLevel},
	IsNuqiSkill = cfg_fight:is_nuqi_skill(SkillID),

	SkillList2 = case IsNuqiSkill andalso is_integer(DelSkillID) of
		true ->
			SkillList11 = SkillList1 -- [lists:keyfind(DelSkillID, #p_role_skill.skill_id, SkillList1)],
			case AutoNuqiShow of
				true -> [NewSkill | SkillList11];
				false -> SkillList11
			end;
		false ->
			[NewSkill | SkillList1]
	end,

	SysConfig2 = SysConfig#p_sys_config{skill_list=SkillList2},
	db:dirty_write(?DB_SYSTEM_CONFIG, #r_sys_config{roleid=RoleID, sys_config=SysConfig2}),
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, 
		?SYSTEM, ?SYSTEM_CONFIG, #m_system_config_toc{sys_config=SysConfig2}).