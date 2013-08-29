-module (role_skill).

-include("common.hrl").

-compile(export_all).

-spec talent_changed_notify(player_id(), role_id()) ->
	{false, err_code()} | no_change | {true, NewAddedSkillList::list()}.
talent_changed_notify(PlayerId, RoleId) ->
	case role_base:get_employed_role_rec(PlayerId, RoleId) of
		none -> 
			{false, ?ERR_MER_NOT_EXIST};
		%% 只有非主角色才有技能孔的
		RoleRec when RoleRec#role.gd_roleRank == 0 -> 
			TotalTalent = role_talent:get_total_talent(RoleRec),
			NewHoleNums = get_skill_hole_nums(TotalTalent),
			OldHoleNums = get_skill_hole_nums(RoleRec),
			if
				NewHoleNums > OldHoleNums ->
					add_skill_hole(RoleRec, NewHoleNums - OldHoleNums);
				true ->
					no_change
			end;
		_ ->
			no_change
	end. 

%% 把某一技能升到N级
-spec add_skill_exp_to_n(player_id(), role_id(), integer(), integer()) -> any().
add_skill_exp_to_n(PlayerId, _RoleId, ChangeSkillModeId, Level) ->
	case role_base:get_main_role_rec(PlayerId) of
		none -> 
			{false, ?ERR_MER_NOT_EXIST}; 
		RoleRec ->
			Fun = fun({_SkillUid, SkillModeId, _SkillExp}) ->
				SkillModeId div 1000 =:= ChangeSkillModeId div 1000 andalso
				SkillModeId rem 1000 =:= ChangeSkillModeId rem 1000
			end,
			case lists:filter(Fun, RoleRec#role.gd_skill) of
				[] ->
					void,
					?INFO(role1,"Skill Not Found,skill = ~w",[RoleRec#role.gd_skill]);
				[{SkillUid, SkillModeId, _SkillExp}| _Res] ->
					NewSkillModeId = (ChangeSkillModeId div 10)*10 + Level,
					SkillTuple = {SkillUid, NewSkillModeId, 0},
					NewSkillList = lists:keystore(SkillUid, 1, RoleRec#role.gd_skill, SkillTuple),
					role_db:update_role_elements(PlayerId, RoleRec#role.key, [{#role.gd_skill, NewSkillList}]),
					{_PlayerId,RoleId} = RoleRec#role.key,
					mod_role:update_attri_notify(PlayerId,RoleId),
					mod_task:update_skill_task(PlayerId,NewSkillModeId),
					IsInGuild = guild:is_in_guild(PlayerId),
					{ok, Packet} = pt_15:write(15002, {RoleId, NewSkillList, IsInGuild}),
					lib_send:send_by_id(PlayerId, Packet),
					?INFO(role1,"HAVE UPDATE SKILL = ~w",[SkillModeId])
			end
	end.

-spec add_skill_exp(player_id(), role_id(), integer(), integer()) ->
	{false, err_code()} | 
	{true, NotifyType::leve_up|no_level_up|reach_max_level, skill_tuple()}.
add_skill_exp(PlayerId, RoleId, SkillUid, AddedExp) ->
	case role_base:get_employed_role_rec(PlayerId, RoleId) of
		none -> 
			{false, ?ERR_MER_NOT_EXIST}; 
		RoleRec ->
			case lists:keyfind(SkillUid, 1, RoleRec#role.gd_skill) of
				false ->
					?ERR(role, "player's role ~w has not learn that skill: ~w", [RoleId, SkillUid]),
					{false, ?ERR_UNKNOWN};
				{SkillUid, SkillModeId, SkillExp} ->
					SkillInfo = data_skill:skill_info(SkillModeId),
					if
						(SkillInfo#skill_info.next_skill_id == 0) ->
							{true, reach_max_level, {SkillUid, SkillModeId, SkillExp}};
						(SkillInfo#skill_info.type /= ?SKILL_GIFT) ->
							TotalExp = AddedExp + SkillExp,
							case TotalExp >= SkillInfo#skill_info.level_up_exp of
								true -> 
									SkillTuple = level_up_skill(SkillUid, TotalExp, SkillInfo),
									{_ID,SKillID,_EXp} = SkillTuple,
									mod_task:update_skill_task(PlayerId,SKillID),
									Ret = {true, leve_up, SkillTuple};
								false ->
									SkillTuple = {SkillUid, SkillModeId, TotalExp},
									Ret = {true, no_level_up, SkillTuple}
							end,
							NewSkillList = lists:keystore(SkillUid, 1, RoleRec#role.gd_skill, SkillTuple),
							role_db:update_role_elements(PlayerId, RoleRec#role.key, [{#role.gd_skill, NewSkillList}]),
							mod_role:update_attri_notify(PlayerId,RoleId),
							Ret;
						true -> %% 天赋技能不能升级，客户端不应该发这种请求！
							{false, ?ERR_UNKNOWN}
					end
			end
	end.


level_up_skill(SkillUid, TotalExp, SkillInfo) ->
	NewSkillExp = TotalExp - SkillInfo#skill_info.level_up_exp,
	{SkillUid, SkillInfo#skill_info.next_skill_id, NewSkillExp}.

add_skill_hole(RoleRec, AddedNum) ->
	SkillList = gen_skill(AddedNum, false, RoleRec#role.gd_skill, []),
	NewSkill = lists:append(SkillList, RoleRec#role.gd_skill),
	{PlayerId, RoleId} = RoleRec#role.key,
	role_db:update_role_elements(PlayerId, RoleRec#role.key, [{#role.gd_skill, NewSkill}]),
	mod_role:update_attri_notify(PlayerId,RoleId),
	{true, NewSkill}.

add_main_role_skill(PlayerId, SkillModeId) ->
	SkillUid = uid_server:get_seq_num(?UID_SKILL),
	SkillTuple = {SkillUid, SkillModeId, 0},
	RoleRec = role_base:get_main_role_rec(PlayerId),
	NewSkills = [SkillTuple | RoleRec#role.gd_skill],
	{PlayerId, RoleId} = RoleRec#role.key,
	role_db:update_role_elements(PlayerId, RoleRec#role.key, [{#role.gd_skill, NewSkills}]),
	mod_role:update_attri_notify(PlayerId,RoleId),
	{true, RoleId, SkillTuple}.

refresh_skill(PlayerId, RoleId, ReservedSkillUidList) ->
	case role_base:get_employed_role_rec(PlayerId, RoleId) of
		none -> 
			{false, ?ERR_MER_NOT_EXIST}; 
		RoleRec when (RoleRec#role.gd_roleRank == 0) ->
			case check_refresh_skill(PlayerId, RoleRec, ReservedSkillUidList) of
				true ->
					refresh_skill_cost(PlayerId, RoleRec, ReservedSkillUidList),
					NewSkills = do_refresh_skill(RoleRec#role.gd_skill, ReservedSkillUidList, []),
					role_db:update_role_elements(PlayerId, RoleRec#role.key, [{#role.gd_skill, NewSkills}]),
					mod_role:update_attri_notify(PlayerId,RoleId),
					{true, NewSkills};
				{false, ErrCode} -> {false, ErrCode}
			end;
		_ ->
			{false, ?ERR_UNKNOWN}
	end.

%% 执行刷新技能时保证每次刷新的那个技能不会和其他的技能是同属性的
%% 参数：
%% 		SkillTupleList：为所有的技能
%%		ReservedSkillUidList：为第一个参数中要保留的技能的uid的列表
%%		NewSkills：为SkillTupleList中保留的技能和不能被刷新的技能，以及刷新过的技能
%% 返回：
%%		NewSkills
do_refresh_skill([], _ReservedSkillUidList, NewSkills) -> NewSkills;
do_refresh_skill([SkillTuple | Rest] = SkillTupleList, ReservedSkillUidList, NewSkills) ->
	{SkillUid, SkillModeId, _} = SkillTuple,
	SkillInfo = data_skill:skill_info(SkillModeId),

	case lists:member(SkillUid, ReservedSkillUidList) orelse 
		 (SkillInfo#skill_info.type /= ?SKILL_NORMAL) of
		true -> SkillTuple1 = SkillTuple;
		false ->
			NewSkillModeId = rank_skill(SkillTupleList ++ NewSkills),
			SkillTuple1 = {SkillUid, NewSkillModeId, 0}
	end,
	do_refresh_skill(Rest, ReservedSkillUidList, [SkillTuple1 | NewSkills]).

check_refresh_skill(PlayerId, RoleRec, ReservedSkillUidList) ->
	%% 判断保留的技能uid是否都是该角色的，并且都是普通技能
	Fun = fun(SkillUid, Acc) ->
		case lists:keyfind(SkillUid, 1, RoleRec#role.gd_skill) of
			false -> false;
			{SkillUid, SkillModeId, _SkillExp} ->
				SkillInfo = data_skill:skill_info(SkillModeId),
				case SkillInfo#skill_info.type of
					?SKILL_NORMAL -> Acc;
					_ -> false
				end
		end
	end,
	case lists:foldl(Fun, true, ReservedSkillUidList) of
		true -> 
			ReservedNum = length(ReservedSkillUidList),
			SkillHoles = get_skill_hole_nums(RoleRec),
			Ret = case ReservedNum of
				0 -> true;
				SkillHoles -> {false, ?ERR_UNKNOWN};
				_ ->
					Cost1 = data_skill:get_fixed_cost(ReservedNum),
					case mod_economy:check_bind_gold(PlayerId, Cost1) of
						true -> true;
						false -> {false, ?ERR_NOT_ENOUGH_GOLD}
					end
			end,
			case Ret of
				true ->
					Cost2 = data_skill:get_refresh_cost(SkillHoles - ReservedNum),
					case mod_economy:check_silver(PlayerId, Cost2) of
						true -> true;
						false -> {false, ?ERR_NOT_ENOUGH_SILVER}
					end;
				_ -> Ret
			end;
		false -> {false, ?ERR_UNKNOWN}
	end.

refresh_skill_cost(PlayerId, RoleRec, ReservedSkillUidList) ->
	ReservedNum = length(ReservedSkillUidList),
	SkillHoles = get_skill_hole_nums(RoleRec),
	case ReservedNum of
		0 -> ok;
		_ ->
			Cost1 = data_skill:get_fixed_cost(ReservedNum),
			mod_economy:use_bind_gold(PlayerId, Cost1, ?GOLD_FIX_SKILL_COST)
	end,
	Cost2 = data_skill:get_refresh_cost(SkillHoles - ReservedNum),
	mod_economy:use_silver(PlayerId, Cost2, ?SILVER_REFRESH_SKILL).


%% ============================== local function ==============================
%% 该函数保证不产生和传递进来的OldSkillList中同类的技能
%% 并且新生产的技能也不会是同类的
%% 参数说明：
%% 		AddedNum：		要产生的技能的个数
%%		KeepEmpty：		是否保持技能孔中的技能为孔
%%		OldSkillList：	已有的旧的技能列表，用来区分不产生同属性的技能
%% 		SkillList： 	为新的技能列表
gen_skill(0, _KeepEmpty, _OldSkillList, SkillList) -> SkillList;
gen_skill(AddedNum, KeepEmpty, OldSkillList, SkillList) ->
	SkillUid = uid_server:get_seq_num(?UID_SKILL),
	case KeepEmpty of
		false -> 
			SkillModeId = rank_skill(OldSkillList),
			SkillTuple = {SkillUid, SkillModeId, 0};
		true ->  
			SkillTuple = {SkillUid, 0, 0}
	end,
	gen_skill(AddedNum - 1, KeepEmpty, [SkillTuple | OldSkillList], [SkillTuple | SkillList]).

%% 产生一个与OldSkillList中不同种技能属性的技能模型id
%% 这里只是对普通技能而言的
rank_skill(OldSkillList) ->
	Fun1 = fun({_, SkillModeId, _}, ClassSet) ->
		SkillInfo = data_skill:skill_info(SkillModeId),
		case SkillInfo#skill_info.type of
			?SKILL_NORMAL -> sets:add_element(SkillInfo#skill_info.class_id, ClassSet);
			_ -> ClassSet
		end
	end,
	OldSkillClassSet = lists:foldl(Fun1, sets:new(), OldSkillList),
	LeftSkillClass = sets:to_list(sets:subtract(sets:from_list(data_skill:get_all_skill_class()), OldSkillClassSet)),
	SkillClassId = rand_skill_class(LeftSkillClass),
	SkillModeId = rand_skill_mode_id(data_skill:all_normal_skill(SkillClassId)),

	SkillModeId.

%% 随机得到一个技能属性id
rand_skill_class(LeftSkillClass) ->
	Fun = fun(SkillClassId, {T, L}) ->
		Rate = data_skill:get_skill_class_rate(SkillClassId),
		{T + Rate, [{T + Rate, SkillClassId} | L]}
	end,
	{Total, RateTuple} = lists:foldl(Fun, {0, []}, LeftSkillClass),
	RateTuple1 = lists:reverse(RateTuple),
	N = util:rand(1, Total),
	rand_skill_class_help(N, RateTuple1).
rand_skill_class_help(_N, []) -> exit("This cannot happen");
rand_skill_class_help(N, [{Num, SkillClassId} | Rest]) ->
	case N =< Num of
		true -> SkillClassId;
		false ->
			rand_skill_class_help(N, Rest)
	end.

%% 随机得到一个技能模型id
rand_skill_mode_id(SkillModeIdList) ->
	Fun = fun(SkillModeId, {T, L}) ->
		Rate = data_skill:get_skill_rate(SkillModeId),
		{T + Rate, [{T + Rate, SkillModeId} | L]}
	end,	
	{Total, RateTuple} = lists:foldl(Fun, {0, []}, SkillModeIdList),
	RateTuple1 = lists:reverse(RateTuple),
	N = util:rand(1, Total),
	rand_skill_help(N, RateTuple1).
rand_skill_help(_N, []) -> exit("This cannot happen");
rand_skill_help(N, [{Num, SkillModeId} | Rest]) ->
	case N =< Num of
		true -> SkillModeId;
		false ->
			rand_skill_help(N, Rest)
	end. 

%% 只获取武将的一个无双技能的SkillTuple
find_role_special_skill(RoleRec) ->
	?INFO(role,"skill is ~w",[RoleRec]),
	SkillTupleList = RoleRec#role.gd_skill,
	Fun = fun({_SkillUid, SkillModeId, _SkillExp}) ->
		SkillInfo = data_skill:skill_info(SkillModeId),
		(SkillInfo#skill_info.type == ?SKILL_SPECIAL)
	end,
	
	[SkillTuple | _] = lists:filter(Fun, SkillTupleList),
	SkillTuple.



%% 技能列表中只有主角有一个天赋技能且是固定的，
%% 所有角色都有一个无双技能，其他都可以从技能孔中得到 
get_skill_hole_nums(RoleRec) when is_record(RoleRec, role) -> 
	Fun = fun({_, SkillModeId, _}, T) ->
		SkillInfo = data_skill:skill_info(SkillModeId),
		case SkillInfo#skill_info.type of
			?SKILL_NORMAL -> T + 1;
			_ -> T
		end
	end,
	lists:foldl(Fun, 0, RoleRec#role.gd_skill);
%% 根据总的天赋值获取对应的技能孔(有2个一开始送的技能孔)	
get_skill_hole_nums(TotalTalent) ->
	data_skill:get_skill_hole_nums(TotalTalent div 4) + 2.

%% 获取主角的普通主动技能的最低等级
get_normal2_skill_level(RoleRec) ->
	SkillTuple = RoleRec#role.gd_skill,
	?INFO(role,"SkillTuple = ~w",[SkillTuple]),
	FilterList = lists:filter(fun({_,SkillModeId,_}) -> SkillInfo = data_skill:skill_info(SkillModeId),
		SkillInfo#skill_info.type =:= ?SKILL_NORMAL2 end,SkillTuple),
	Fun = fun({_,SkillModeId,_},T) ->
		SkillLevel = SkillModeId rem 10 ,
		case T >= SkillLevel of
			true -> 
				SkillLevel;
			false ->
				T
		end
	end,
	lists:foldl(Fun,10,FilterList).

%% 获取主角的无双技能最低等级
get_special_skill_level(RoleRec) ->
	{_,SkillModeId,_} = find_role_special_skill(RoleRec),
	SkillModeId rem 10.