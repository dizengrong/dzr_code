%% Author: liuwei
%% Created: 2010-6-21
%% Description: TODO: Add description to mod_skill
-module(mod_skill).

-include("mgeem.hrl").

-export([
         init_skill_last_use_time/2,
         verify_family_skill/2,
         clear_family_skill/1
        ]).

-export([
         get_role_skill_level/2,
         get_role_skill_list/1,
         get_role_skill_info/2,
         erase_role_skill_list/1,
		 delete_role_skill_info/2,
		 can_reduce_skill_cd_time/1,
		 cast_reduce_skill_cdtime/1,
         change_skill_level_temp/1,
         change_skill_level_temp/2,
         change_skill_level_temp/3,
         change_skill_level_temp/4,
         get_role_nuqi_skill/2,
         change_nuqi_shape/4
		]).

-export([
			is_star_skill/2
		]).


-define(CATEGORY_FAMILY_SKILL,7).   %%宗族技能的类型
-define(ERR_GOODS_NUM_NOT_ENOUGH,1001).   %%技能道具不足

change_skill_level_temp(_MissionID, RoleID) ->
    change_skill_level_temp(RoleID).

change_skill_level_temp(RoleID) ->
    case mod_role_tab:get({r_role_skill_time_tiyan, RoleID}) of
        #r_role_skill_time_tiyan{
            p_skill = #r_role_skill_info{
                skill_id = SkillID,  
                cur_level = SkillLevel
            }
        } ->
            change_skill_level_temp(RoleID, SkillID, SkillLevel);
        _ -> ignore
    end.

change_skill_level_temp(RoleID, _MissionID, SkillID, SkillLevel) ->
    change_skill_level_temp(RoleID, SkillID, SkillLevel).
%%暂时修改技能等级
change_skill_level_temp(RoleID, SkillID, SkillLevel) ->
    {ok, #p_role_attr{
        category = RoleCategory
    }} = mod_map_role:get_role_attr(RoleID),
    {ok, #p_skill{
        category = SkillCategory
    }} = mod_skill_manager:get_skill_info(SkillID),

    case RoleCategory == SkillCategory of
        true ->
            IsNuqiSkill = mod_skill_manager:is_nuqi_skill(RoleCategory, SkillID),
                Fun = fun() ->
                    #r_role_skill_info{
                        skill_id = PreSkillID,
                        cur_level = PreLevel
                    } = get_role_nuqi_skill(RoleID, RoleCategory),
                    case IsNuqiSkill of
                        true ->
                            change_nuqi_shape(RoleID, PreSkillID, SkillID, SkillLevel);
                        false ->
                            t_add_role_skill(RoleID,SkillID,SkillLevel,RoleCategory)
                    end,
                    RoleSkill = #r_role_skill_info{
                        skill_id = PreSkillID,
                        cur_level = PreLevel
                    },

                    case mod_role_tab:get({r_role_skill_time_tiyan, RoleID}) of
                        #r_role_skill_time_tiyan{
                            p_skill = #r_role_skill_info{}
                        } -> 
                            mod_role_tab:put({r_role_skill_time_tiyan, RoleID}, #r_role_skill_time_tiyan{});
                        _ ->  
                            mod_role_tab:put({r_role_skill_time_tiyan, RoleID}, 
                                #r_role_skill_time_tiyan{
                                    p_skill = RoleSkill
                                }
                            )
                    end
                end,
                case common_transaction:t(Fun) of
                    {aborted, Reason} ->
                        ?DBG(Reason);
                        % ?SEND_ERR_TOC2(m_skill_learn_toc,Reason);
                    {atomic, _} ->
                        Record = #m_skill_learn_toc{
                            succ = true,
                            skill = #p_role_skill{skill_id=SkillID,cur_level=SkillLevel}
                        },
                        common_misc:unicast(0, RoleID, ?DEFAULT_UNIQUE, ?SKILL, ?SKILL_LEARN, Record)
                end;
        _ -> ignore
    end.

t_add_role_skill(RoleID,SkillID,CurLevel,Category) ->
    Record = #r_role_skill_info{
                           skill_id = SkillID,
                           cur_level = CurLevel,
                           category = Category},
    update_role_skill_info(RoleID, Record).

get_role_nuqi_skill(RoleID, Category) ->
    SkillList = get_role_skill_list(RoleID),

    NuqiSkillList = cfg_skill_life:get_one_key_learn_nuqi_skill(Category),

    [SkillInfo] = lists:foldl(fun(H, Acc) ->
        SkillID1 = H#r_role_skill_info.skill_id,
        case lists:member(SkillID1, NuqiSkillList) of
            true -> [H|Acc];
            false -> Acc
        end
    end, [], SkillList),
    SkillInfo.

%% @doc 技能上次使用时间
init_skill_last_use_time(RoleID, Line) ->
    case catch db:dirty_read(?DB_SKILL_TIME, RoleID) of
        [#r_skill_time{last_use_time=LastUseTime}] ->
            mof_fight_time:set_last_skill_time(role, RoleID, LastUseTime),
            ServerTime = common_tool:now(),
            LastUseTime2 = lists:zf(fun
                ({SkillID, {A, B, _}}) when is_integer(SkillID) ->
                    {true, #p_skill_time{skill_id=SkillID, last_use_time=A*1000000+B}};
                (_) ->
                    false
            end, LastUseTime),
            DataRecord = #m_skill_use_time_toc{skill_time=LastUseTime2, server_time=ServerTime},
            common_misc:unicast(Line, RoleID, ?DEFAULT_UNIQUE, ?SKILL, ?SKILL_USE_TIME, DataRecord);
        _ ->
            ok
    end.

%% 通知玩家当前可减少的CD时间
cast_reduce_skill_cdtime(RoleID) ->
	case mod_map_actor:get_actor_mapinfo(RoleID, role) of
		#p_map_role{state_buffs=Buffs} ->
			ReduceSeconds = can_reduce_skill_cd_time(Buffs) div 1000,
			R2 = #m_role2_reduce_skill_cdtime_toc{reduce_seconds=ReduceSeconds},
			common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?ROLE2,?ROLE2_REDUCE_SKILL_CDTIME,R2);
		_ ->
			ignore
	end.
	
can_reduce_skill_cd_time(Buffs) ->
	lists:foldl(fun(Buff,Acc) ->
						#p_actor_buf{buff_type=BuffType,value=Value} = Buff,
						{ok, Func} = mod_skill_manager:get_buff_func_by_type(BuffType),
						case Func =:= reduce_skill_cd of
							true ->
								Acc+Value;
							false ->
								Acc
						end
				end, 0, Buffs).

%%@doc 校验玩家的宗族技能（若离开宗族，则需要清空原宗族技能）
verify_family_skill(RoleID,#p_role_base{family_id=FamilyID})->
    case FamilyID>0 of
        true->
            ignore;
        _->
            clear_family_skill(RoleID)
    end.
    

%%@doc 清空玩家本人的宗族技能（在离开宗族之后）
%%@return ok | {error,Reason}
clear_family_skill(RoleID)->
    TransFun = 
        fun() ->
                SkillList = get_role_skill_list(RoleID),
                SkillList2 =
                    lists:foldl(
                      fun(#r_role_skill_info{category=?CATEGORY_FAMILY_SKILL}, Acc) ->
                              Acc;
                         (Skill, Acc) ->
                              [Skill|Acc]
                      end, [], SkillList),

                case erlang:length(SkillList) =:= erlang:length(SkillList2) of
                    true ->
                        {ok, no_skill};
                    _ ->
                        {ok, skill_deleted}
                end
        end,
    case common_transaction:transaction(TransFun) of
        {atomic, {ok,no_skill}} ->
            ok;
        {atomic, {ok,skill_deleted}} ->
            Msg = ?_LANG_FAMKLY_SKILL_WHEN_LEAVE_FAMILY,
            common_broadcast:bc_send_msg_role(RoleID,[?BC_MSG_TYPE_SYSTEM,?BC_MSG_TYPE_CENTER],Msg),

            case get_role_all_skill_level(RoleID) of
                {fail,Reason1} ->
                    ?ERROR_MSG_STACK("clear_family_skill",Reason1),
                    ignore;
                SkillLevelList ->
                    R2 = #m_skill_getskills_toc{skills=SkillLevelList},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?SKILL, ?SKILL_GETSKILLS, R2)
            end;
        {aborted, Reason} ->
            ?ERROR_MSG_STACK("clear_family_skill",Reason),
            {error,Reason}
    end.

%%改变怒气技能的形态, 如:怒气技能升阶, 怒气技能的立即购买功能
change_nuqi_shape(RoleID, PreSkillID, NextSkillID, NextSkillLevel) ->
    SkillList = get_role_skill_list(RoleID),
    {ok, #r_role_skill_info{} = SkillInfo} = get_role_skill_info(RoleID, PreSkillID),
    NewSkillInfo = #r_role_skill_info{
        skill_id = NextSkillID, 
        cur_level = NextSkillLevel, 
        category = SkillInfo#r_role_skill_info.category
    },
    SkillList1 = [NewSkillInfo | SkillList -- [SkillInfo]],

    set_role_skill_list(RoleID, SkillList1),
    {ok, NewSkillInfo}.

get_role_all_skill_level(RoleID) ->
    SkillList = get_role_skill_list(RoleID),
    lists:foldr(
      fun(RoleSkillInfo, Acc) ->
              #r_role_skill_info{skill_id=SkillID, cur_level=CurLevel} = RoleSkillInfo, 
              [#p_role_skill{skill_id=SkillID,cur_level=CurLevel}|Acc]
      end, [], SkillList).

%% @doc 获取角色技能列表
get_role_skill_list(RoleID) ->
    case mod_role_tab:get(RoleID, {?role_skill, RoleID}) of
        undefined ->
            [];
        SkillList ->
            SkillList
    end.

%% @doc 设置角色技能列表
set_role_skill_list(RoleID, SkillList) ->
    mod_map_role:update_role_id_list_in_transaction(RoleID, ?role_skill, ?role_skill_copy),
    mod_role_tab:put(RoleID, {?role_skill, RoleID}, SkillList).

%% @doc 清除角色技能列表
erase_role_skill_list(RoleID) ->
    mod_role_tab:erase(RoleID, {?role_skill, RoleID}).

%% @doc 获取角色某技能信息
get_role_skill_info(RoleID, SkillId) ->
    case lists:keyfind(SkillId,#r_role_skill_info.skill_id,get_role_skill_list(RoleID)) of
        false ->
            {error, not_found};
        SkillInfo when erlang:is_record(SkillInfo,r_role_skill_info) ->
            {ok,SkillInfo};
        _ ->
            {error, not_found}
    end.

delete_role_skill_info(RoleID, SkillId) ->
    SkillList = get_role_skill_list(RoleID),
    set_role_skill_list(RoleID, lists:keydelete(SkillId, #r_role_skill_info.skill_id, SkillList)).

%% @doc 更新玩家技能信息
update_role_skill_info(RoleID, SkillInfo) ->
    SkillList = get_role_skill_list(RoleID),
    SkillList2 = [SkillInfo|lists:keydelete(SkillInfo#r_role_skill_info.skill_id, #r_role_skill_info.skill_id, SkillList)],
    set_role_skill_list(RoleID, SkillList2).

%% @doc 获取角色某技能等级
get_role_skill_level(RoleID, SkillId) ->
	case get_role_skill_info(RoleID, SkillId) of
    	{ok, SInfo} ->
    		{ok, SInfo#r_role_skill_info.cur_level};
    	_ ->
            {ok, 0}
	end.

%% 是否星宿技能
is_star_skill(RoleID,SkillID) ->
	{ok,#p_role_attr{category=Category}} = mod_map_role:get_role_attr(RoleID),
	MinStarSkillID = Category*10000000+101001,
	MaxStarSkillID = Category*10000000+101008,
	SkillID >= MinStarSkillID andalso SkillID =< MaxStarSkillID.
	
	
