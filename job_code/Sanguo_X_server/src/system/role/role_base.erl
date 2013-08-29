%% Author: dzr
%% Created: 2012-3-30
%% Description: mercenary base subsystem
-module(role_base).

-include("common.hrl").

-export([get_all_roles/1, get_employed_roles/1, get_employed_role_rec/2,
		 get_employed_id_list/1, get_main_role_rec/1, get_fired_list/1,
		 get_all_role_id_list/1, get_on_battle_list/1, add_exp/2, 
		 calc_combat_point/1, get_all_fight_ability/1, fire/2, employ/2,
		 init_new_role/3,get_weiwang/1,add_hp/2
		 ]).

-compile(export_all).

%% 获取所有的佣兵，包括解雇的
get_all_roles(PlayerId) ->
	RoleRecList = role_db:get_roles(PlayerId),
	init_raw_role(RoleRecList).

%% 获取已雇佣的角色记录，若不存在则返回none
-spec get_employed_role_rec(player_id(), role_id()) -> role() | none.
get_employed_role_rec(PlayerId, RoleId) ->
	case role_db:get_role(PlayerId, RoleId) of
		[] -> none;
		RoleRecList ->
			[RoleRec] = init_raw_role(RoleRecList),
			case RoleRec#role.gd_isFired of
				0 -> RoleRec;
				1 -> none
			end
	end.

get_fired_role_rec(PlayerId, RoleId) ->
	case role_db:get_role(PlayerId, RoleId) of
		[] -> none;
		RoleRecList ->
			[RoleRec] = init_raw_role(RoleRecList),
			case RoleRec#role.gd_isFired of
				1 -> RoleRec;
				0 -> none
			end
	end.

get_main_role_rec(PlayerId) ->
	Fun = fun(RoleRec, Val) ->
		case RoleRec#role.gd_roleRank of
			1 -> RoleRec;
			0 -> Val
		end
	end,
	lists:foldl(Fun, none, get_all_roles(PlayerId)).

get_employed_id_list(PlayerId) ->
	Fun = fun(RoleRec) ->
		{_PlayerId, RoleId} = RoleRec#role.key,
		RoleId
	end,
	[Fun(Rec) || Rec <- get_employed_roles(PlayerId)].

get_employed_roles(PlayerId) ->
	Pred = fun(RoleRec) -> RoleRec#role.gd_isFired == 0 end,
	lists:filter(Pred, get_all_roles(PlayerId)).

get_employed_role_num(PlayerId) ->
	length(get_employed_roles(PlayerId)).	

%% 获取所有已解雇的角色列表
get_fired_list(PlayerId) ->
	Pred = fun(RoleRec) -> RoleRec#role.gd_isFired == 1 end,
	lists:filter(Pred, get_all_roles(PlayerId)).

%% 获取所有的角色id的列表，包括已解雇的
get_all_role_id_list(PlayerId) ->
	Fun = fun(RoleRec) ->
		{_PlayerId, RoleId} = RoleRec#role.key,
		RoleId
	end,
	[Fun(Rec) || Rec <- get_all_roles(PlayerId)].

get_on_battle_list(PlayerId) ->
	Filter = fun(RoleRec) -> RoleRec#role.gd_isBattle =/= 0 end,
	lists:filter(Filter, get_employed_roles(PlayerId)).

calc_combat_point(RoleRec) ->
	%% TO-DO: 计算角色的战斗力
	
	%% 战斗力公式=0.4×攻击+0.18×平均防御+0.16×气血+0.22×速度+1.2×命中+1.2×闪避+0.88×致命+0.96×暴击+0.96×幸运+1.2×格挡+1.4×反击+1.2×破甲
	case RoleRec#role.gd_careerID =:= ?CAREER_HUWEI orelse RoleRec#role.gd_careerID =:= ?CAREER_MENGJIANG of
		true ->
			Att = RoleRec#role.p_att;
		false ->
			Att = RoleRec#role.m_att
	end,
	Point = Att*0.4+(RoleRec#role.m_def+RoleRec#role.p_def)/2*0.18+RoleRec#role.gd_maxHp*0.16+RoleRec#role.gd_speed*0.22
		+RoleRec#role.gd_mingzhong*1.2+RoleRec#role.gd_shanbi*1.2+RoleRec#role.gd_zhiming*0.88+RoleRec#role.gd_baoji*0.96
		+RoleRec#role.gd_xingyun*0.96+RoleRec#role.gd_gedang*1.2+RoleRec#role.gd_fanji*1.4+RoleRec#role.gd_pojia*1.2,
	round(Point).

get_all_fight_ability(PlayerId) ->
	Fun = fun(OnBattleRoleRec, Total) ->
		Total + calc_combat_point(OnBattleRoleRec)
	end,
	lists:foldl(Fun, 0, get_on_battle_list(PlayerId)).

employ(PlayerId, RoleId) ->
	AllRoles = role_db:get_roles(PlayerId),
	case lists:keyfind({PlayerId, RoleId}, 2, AllRoles) of
		false -> %% 从来没有雇用过的
			case check_employ_requirement(PlayerId, RoleId) of
				true -> 
					employ_cost(PlayerId, RoleId),
					NewRoleRec = init_new_role(PlayerId, RoleId, 0),
					role_db:insert_role_rec(PlayerId, NewRoleRec),
					%% 第一次雇佣送一套初级装备
					create_items(PlayerId,RoleId),
					mod_achieve:employNotify(PlayerId),
					true;
				{false, ErrCode} ->
					{false, ErrCode}
			end;
		ExistRoleRec when (ExistRoleRec#role.gd_isFired == 1) -> %% 雇佣曾经解雇的
			case check_employ_requirement(PlayerId, RoleId) of
				true -> 
					employ_cost(PlayerId, RoleId),
					role_db:update_role_elements(PlayerId, ExistRoleRec#role.key, [{#role.gd_isFired, 0}]),
					mod_achieve:employNotify(PlayerId),
					true;
				{false, ErrCode} ->
					{false, ErrCode}
			end;
		_ -> 
			{false, ?ERR_UNKNOWN}
	end.

employ_cost(PlayerId, RoleId) ->
	{_, JunweiReq, SilverReq} = data_role:requirement(RoleId),
	mod_economy:use_silver(PlayerId, SilverReq, ?SILVER_EMPLOY_ROLE),
	role_data_base:use_junwei(PlayerId, JunweiReq).

%% RoleRank为0表示不是主角色，为1是主角色
init_new_role(PlayerId, RoleId, RoleRank) ->
	RoleModeRec = data_role:get(RoleId),
	TotalExp    = data_exp:get_total(RoleModeRec#role.gd_roleLevel),
	SkillList   = init_new_role_skill(RoleModeRec#role.gd_skill, []),
	%% 一个角色出来时送2个技能孔（此时该角色的天赋总和开启的技能孔不会到达2个）
	SkillList1 = role_skill:gen_skill(2, false, SkillList, []),
	%% 初始化血量
	% [_AddedLiliang, _AddedYuansheng, AddedTipo, _AddedMinjie, AddedHp2] = 
	% 	[util:ceil(A * RoleModeRec#role.gd_roleLevel) || A <- data_role:get_base_attri_added(RoleId)],
	% Tipo      = RoleModeRec#role.gd_tipo + AddedTipo,
	% TipoTalent  = RoleModeRec#role.gd_tipoTalent,
	% AddedHp    = util:ceil(data_role:get_added_hp(Tipo, TipoTalent)) + AddedHp2,
	% ?INFO(role,"SkillList = ~w",[SkillList1 ++ SkillList]),
	% UpdateAttriRec = get_skill_added(SkillList1 ++ SkillList),
	% CurrentHp = RoleModeRec#role.gd_maxHp + AddedHp + UpdateAttriRec#role_update_attri.gd_maxHp,

	RoleModeRec#role{
		key         = {PlayerId, RoleId}, 
		gd_exp      = TotalExp, 
		gd_skill    = SkillList1 ++ SkillList,
		% gd_currentHp = CurrentHp,
		gd_roleRank = RoleRank
	}.

%% 初始化时一个角色时，只有主角色有一个天赋技能
%% 所有的角色都会有一个无双技能的
init_new_role_skill([], Result) -> Result;
init_new_role_skill([SkillModeId | Rest], Result) ->
	SkillUid    = uid_server:get_seq_num(?UID_SKILL),
	SkillTuple = {SkillUid, SkillModeId, 0},
	init_new_role_skill(Rest, [SkillTuple | Result]).


fire(PlayerId, RoleId) ->
	case get_employed_role_rec(PlayerId, RoleId) of
		none -> 
			false;
		RoleRec ->
			case RoleRec#role.gd_isFired == 0 andalso 
				 RoleRec#role.gd_roleRank == 0 andalso
				 RoleRec#role.gd_isBattle == 0  of
				false ->
					?ERR(role, "cannot fire role ~w", [RoleId]),
					false;
				true ->
					%% TO-DO: 脱下装备
					case length(mod_items:getRoleItems(PlayerId,RoleId)) =:= 0 of
						true ->
							role_db:update_role_elements(PlayerId, RoleRec#role.key, [{#role.gd_isFired, 1}]),
							true;
						false ->
							{fail,?ERR_ROLE_HAS_ITEMS}
					end
			end
	end.

add_exp(RoleRec, AddedExp) ->
	{PlayerId, RoleId} = RoleRec#role.key,
	MainRoleRec = get_main_role_rec(PlayerId),
	%% 其他角色的等级不能超过主角色的等级
	case (RoleRec#role.gd_roleRank == 1) orelse 
		 (RoleRec#role.gd_roleLevel < MainRoleRec#role.gd_roleLevel) of
		false ->
			 ?INFO(role,"mer role level bigger than main role"),
			 ?ERR(todo,"tell client"),
			 false;
		true ->
			{_, MaxLv} = data_system:get(12),
			case RoleRec#role.gd_roleLevel == MaxLv of
				true -> 
					?INFO(role,"mer role level reach the max"),
					false;
				_ -> 
					TotalExp0 = RoleRec#role.gd_exp + AddedExp,
					case TotalExp0 >= data_exp:get_total(MaxLv) of
						true -> TotalExp = data_exp:get_total(MaxLv);
						_ -> TotalExp = TotalExp0
					end,
                    %% 计算新的TotalExp对应新的等级，计算的时候做了校验：佣兵等级不能高于主角
					[NewLevel,NewTotalExp] = get_new_exp_and_level(RoleRec#role.gd_roleLevel, 
                        TotalExp, RoleRec#role.gd_roleRank, MainRoleRec#role.gd_roleLevel),
					if
						NewLevel == RoleRec#role.gd_roleLevel -> 
							NewRoleRec = RoleRec#role{gd_exp = NewTotalExp};
						NewLevel > RoleRec#role.gd_roleLevel -> 
							%% 通知成就模块，佣兵升级了
							case RoleRec#role.gd_roleRank == 1 of
								true ->
									mod_achieve:mainRoleLevelNotify(PlayerId,NewLevel);
								false ->
									void
							end,
							mod_achieve:roleLevelNotify(PlayerId,RoleId,NewLevel),
							NewRoleRec0 = RoleRec#role{gd_exp = NewTotalExp, gd_roleLevel = NewLevel},
							NewRoleRec = role_level_up(NewRoleRec0)
					end,
					role_db:update_role_elements(PlayerId, RoleRec#role.key, 
								[{#role.gd_roleLevel, NewLevel}, {#role.gd_exp, NewTotalExp}]),

					?INFO(role, "role ~w add exp: ~w, new total exp: ~w", 
						  [RoleRec#role.key, AddedExp, NewTotalExp]),
					{true, NewRoleRec}
			end
	end.

role_level_up(RoleRec) ->
	%% TO-DO:升级时不必全部重新计算就该角色的属性，只需要初始化必须的字段
	%% 也许使用init_raw_role_fields函数就可以了
	erlang:hd(init_raw_role([RoleRec#role{p_att=0,m_att=0,gd_maxHp=0,gd_currentHp=0}])).

%% 计算TotoalExp经验对应的新等级：
%% 考虑佣兵等级不能超过主角
get_new_exp_and_level(Level, TotalExp ,RoleType, MainRoleLevel)->
    NewLevel = add_exp_help(Level, TotalExp),
    %% 如果是主角或者主角等级不小于佣兵新等级则正常返回
    %% 否则返回主角等级和该等级的最大经验
    case RoleType == 1 orelse MainRoleLevel >= NewLevel of 
        true ->
            [NewLevel, TotalExp];
        false ->
            ?INFO(role,"get_new_exp_and_level,mercenary level(~w) is more high than 
                mainRole(~w)",[NewLevel,MainRoleLevel]),
            [MainRoleLevel,data_exp:get_total(MainRoleLevel+1)-1]
    end.

%% return: NewLevel
add_exp_help(Level, TotalExp) ->
    ExpLevel = data_exp:get_total(Level),
    if 
        TotalExp >  ExpLevel->
            add_exp_help(Level+1, TotalExp);
        TotalExp < ExpLevel ->
            Level-1;
        TotalExp == ExpLevel ->
            Level
    end.

add_hp(RoleRec, HpAdd) ->
	{PlayerId, _RoleId} = RoleRec#role.key,
	MaxHp = RoleRec#role.gd_maxHp,
	NewHp = RoleRec#role.gd_currentHp + HpAdd,
	case NewHp > MaxHp of
		true ->
			CurrentHp = MaxHp;
		false ->
			CurrentHp = NewHp
	end,
	NewRoleRec = RoleRec#role{gd_currentHp = CurrentHp},
	role_db:update_role_elements(PlayerId, RoleRec#role.key, [{#role.gd_currentHp, CurrentHp}]),
	{true,NewRoleRec}.


change_battle_state(PlayerId, RoleId, IsBattle) ->
	case get_employed_role_rec(PlayerId, RoleId) of
		none -> 
			{false, ?ERR_UNKNOWN};
		RoleRec ->
			OnBattleRoleRecList = get_on_battle_list(PlayerId),
			Size = length(OnBattleRoleRecList),
			%% 出战武将个数不大于3
			case (RoleRec#role.gd_isBattle == 0 andalso IsBattle > 0 andalso Size < 3) orelse
				 (RoleRec#role.gd_isBattle > 0 andalso IsBattle == 0) of
				true ->
					case IsBattle > 0 of
						true ->
							BattlePos = 
								case Size of
									1 -> 1;
									2 -> 3
								end;
						false ->
							BattlePos = 0,
							reset_battle_position(OnBattleRoleRecList, RoleId, RoleRec#role.gd_isBattle)
					end,
					role_db:update_role_elements(PlayerId, RoleRec#role.key, [{#role.gd_isBattle, BattlePos}]),
					{true, RoleRec#role{gd_isBattle = BattlePos}};
				false ->
					{false, ?ERR_UNKNOWN}
			end
	end.

%% 当一个佣兵从出战变为不出战时，调用这个来重排所有出战佣兵的站位
%% 第一个参数为出战佣兵列表，第二个为出战状态改变的佣兵id，第三个为他之前的站位
%% 出战佣兵列表中站位大于BattlePos的佣兵站位都要减1
%% （这样做的目的是保证站位是按1依次递增的）
reset_battle_position([], _, _) -> ok;
reset_battle_position([RoleRec | Rest], ChangedRoleId, BattlePos) ->
	{PlayerId, RoleId} = RoleRec#role.key,
	case RoleId == ChangedRoleId orelse RoleRec#role.gd_roleRank =:= 1 of
		true -> 
			ok;
		_ ->
			case RoleRec#role.gd_isBattle < BattlePos of
				true -> ok;
				false ->
					NewBattlePos = BattlePos,
					role_db:update_role_elements(PlayerId, RoleRec#role.key, [{#role.gd_isBattle, NewBattlePos}])
			end
	end,
	reset_battle_position(Rest, ChangedRoleId, BattlePos).

%% 初始化一个裸角色佣兵的属性
init_raw_role(RoleRecList) ->
	Fun = fun(RoleRec) ->
		?INFO(role,"RoleRec = ~w",[RoleRec]),
		%% 血量
		case RoleRec#role.gd_currentHp /= RoleRec#role.gd_maxHp of
			true ->
				% role_db:update_role_elements(PlayerId, RoleRec#role.key, [{#role.gd_currentHp, RoleRec#role.gd_maxHp}]),
				NewRoleRec = RoleRec#role{gd_currentHp = RoleRec#role.gd_maxHp};
			false ->
				NewRoleRec = RoleRec
		end,
		NewRoleRec
		% case RoleRec2#role.gd_currentHp > RoleRec2#role.gd_maxHp of
		% 	true ->
		% 		role_db:update_role_elements(PlayerId, RoleRec2#role.key, [{#role.gd_currentHp, RoleRec2#role.gd_maxHp}]),
		% 		NewRoleRec = RoleRec2#role{gd_currentHp = RoleRec2#role.gd_maxHp};
		% 	false ->
		% 		NewRoleRec = RoleRec2
		% end,
		% NewRoleRec
	end,

	[Fun(init_raw_role_fields(Role)) || Role <- RoleRecList].


% get_online_total_added_attri(PS, MerId) ->
% 	%% 这里添加其他数据的加成
% 	Attri1 = mod_items:cal_attribute(PS#player_status.items_pid, MerId),
% 	Attri2 = mod_holy:get_holy_add_attr(PS#player_status.holy_pid),
% 	Attri3 = mod_pet_extend:get_mer_attri_add_by_pet(PS#player_status.pet_pid),
%     Attri4 = mod_tattoo:get_added_mer_attrib(PS, MerId),

%     AttrList = [Attri1, Attri2, Attri3, Attri4],
%     lists:foldl(fun util:list_add/2, lists:duplicate(17, 0), AttrList).

get_offline_total_added_attri(RoleRecFirst) ->
	{PlayerId,RoleId} = RoleRecFirst#role.key,
	?INFO(role,"RoleId = ~w,RoleLevel =~w",[RoleId,RoleRecFirst#role.gd_roleLevel]),
	%% 装备加成
	ItemAttr     = mod_items:getRoleAttr(PlayerId, RoleId, RoleRecFirst#role.gd_roleLevel),
	%% 官职加成
	OfficialAttr = mod_official:get_added_attri(PlayerId),
	%% 威望加成
	WeiwangAttri = get_added_weiwang_attri(RoleRecFirst),
	E            = role_util:role_update_attri_add([ItemAttr, OfficialAttr, WeiwangAttri]),
	
	%% 根据是否为主角来进行坐骑加成
	RoleModeRec = data_role:get(RoleId),
	case RoleModeRec#role.gd_roleRank of
		1 -> role_util:role_update_attri_add(E, mod_horse:get_added_attri(PlayerId));
		0 -> E
	end.

	% HolyAttribute = mod_holy:get_mer_attri_add_by_holy(PlayerId),
	% PetAttribute = mod_pet_extend:get_mer_attri_add_by_pet_offline(PlayerId),
 %    TattooAttribute = mod_tattoo:get_added_mer_attrib(PlayerId, MerId),

 %    AttrList = [EquipAttribute, HolyAttribute, PetAttribute, TattooAttribute],
 %    lists:foldl(fun util:list_add/2, lists:duplicate(17, 0), AttrList).



%% do something to initilize role record field
%% IMPORTANT: MerRec must be just from cache, and not do any initilize
%% 你必须遵守这条规则，主要是因为佣兵的培养数据就是保存在数据库表gd_role中的
%% gd_strong, gd_intelligence, gd_constitution, gd_accurate中，
%% 所以你必须保证记录mercenary中的这4个字段的值只是对应培养的数据
%% becareful fire and employ function called this function

%% 传入的RoleRec是从ETS中取得的持久性数据，全是一阶的，二阶字段全部为0，所以可把RoleRec当一阶使用
%% 计算属性时是动态的，应先处理好一阶属性的叠加，然后再利用一阶属性计算二阶属性的得益
init_raw_role_fields(RoleRec) ->
	{PlayerId, RoleId} = RoleRec#role.key,
	RoleModeRec = data_role:get(RoleId),

	[AddedLiliang, AddedYuansheng, AddedTipo, AddedMinjie, AddedHp2] = 
		[util:ceil(A * RoleRec#role.gd_roleLevel) || A <- data_role:get_base_attri_added(RoleId)],
	%% 被动技能的加成
	UpdateAttriRec = get_skill_added(RoleRec#role.gd_skill),
	%% 4个基本一阶属性（一介属性在这里叠加好）
	Liliang   = RoleModeRec#role.gd_liliang + RoleRec#role.gd_fliliang + AddedLiliang + UpdateAttriRec#role_update_attri.gd_liliang,
	Yuansheng = RoleModeRec#role.gd_yuansheng + RoleRec#role.gd_fyuansheng + AddedYuansheng + UpdateAttriRec#role_update_attri.gd_yuansheng,
	Tipo      = RoleModeRec#role.gd_tipo + RoleRec#role.gd_ftipo + AddedTipo + UpdateAttriRec#role_update_attri.gd_tipo,
	Minjie    = RoleModeRec#role.gd_minjie + RoleRec#role.gd_fminjie + AddedMinjie + UpdateAttriRec#role_update_attri.gd_minjie,
	%% 4个基本一阶属性对应的天赋
	LiliangTalent   = RoleModeRec#role.gd_liliangTalent + RoleRec#role.gd_tliliang,
	YuanshengTalent = RoleModeRec#role.gd_yuanshengTalent + RoleRec#role.gd_tyuansheng,
	TipoTalent      = RoleModeRec#role.gd_tipoTalent + RoleRec#role.gd_ttipo,
	MinjieTalent    = RoleModeRec#role.gd_minjieTalent + RoleRec#role.gd_tminjie,
	%% 一阶属性转换得到的二阶属性得益
	AddedHp    = util:ceil(data_role:get_added_hp(Tipo, TipoTalent)) + AddedHp2,
	AddedPAtt  = util:ceil(data_role:get_added_p_att(Liliang, LiliangTalent)),
	AddedPDef  = util:ceil(data_role:get_added_p_def(Liliang, LiliangTalent)),
	AddedMAtt  = util:ceil(data_role:get_added_m_att(Yuansheng, YuanshengTalent)),
	AddedMDef  = util:ceil(data_role:get_added_m_def(Yuansheng, YuanshengTalent)),
	AddedSpeed = util:ceil(data_role:get_added_speed(Minjie, MinjieTalent)),

	%% 首先计算一阶属性
	RoleRecFirst = RoleRec#role{
			gd_roleLevel       = data_role:get_level(RoleRec#role.gd_exp),
			gd_liliang         = Liliang,
			gd_yuansheng       = Yuansheng,
			gd_tipo            = Tipo,
			gd_minjie          = Minjie,
			gd_liliangTalent   = LiliangTalent,
			gd_yuanshengTalent = YuanshengTalent,
			gd_tipoTalent      = TipoTalent,
			gd_minjieTalent    = MinjieTalent,

			gd_speed           = 0,
			gd_mingzhong       = 0,
			gd_shanbi          = 0,	
			gd_baoji           = 0,
			gd_xingyun         = 0,
			gd_zhiming         = 0,
			gd_gedang          = 0,	
			gd_fanji           = 0,
			gd_pojia           = 0
			},

	
	% CurrentHp = RoleRec#role.gd_currentHp+RoleModeRec#role.gd_currentHp + AddedHp,
	% CurrentHp = RoleRec#role.gd_currentHp,

	%% 其他装备、坐骑、官职、威望的加成(以一阶属性作判断)
	TotalAddedAttri = get_offline_total_added_attri(RoleRecFirst),
	%% 全套强化加成率（作用于TotalAddedAttri）
	{SpeedRate,AttRate,PdefRate,MdefRate} = mod_items:getIntenAllRate(PlayerId,RoleId),
	%% 其他模块的加成乘以全套强化加成率
	% OfflineAddAttri = TotalAddedAttri#role_update_attri{
	% 	gd_speed = round(TotalAddedAttri#role_update_attri.gd_speed * (1+SpeedRate)),
	% 	p_att 	 = round(TotalAddedAttri#role_update_attri.p_att * (1+AttRate)),
	% 	m_att 	 = round(TotalAddedAttri#role_update_attri.m_att * (1+AttRate)),
	% 	p_def 	 = round(TotalAddedAttri#role_update_attri.p_def * (1+PdefRate)),
	% 	m_def 	 = round(TotalAddedAttri#role_update_attri.m_def * (1+MdefRate))
	% },

	%% 在一介属性上添加上二介属性得益以及二介属性
	RoleRec1 = update_attri(RoleRecFirst, TotalAddedAttri),  %% 其他模块的加成
	RoleRec2 = update_attri(RoleRec1, UpdateAttriRec),		 %% 技能加成
	%% 添加模型本身属性和二介属性得益
	%% p_att,m_att,maxHp,currentHp添加了RoleRec里的加成，是为了Gm加攻加血的，以后要删掉
	MaxHp = RoleRec2#role.gd_maxHp+RoleModeRec#role.gd_maxHp + AddedHp + UpdateAttriRec#role_update_attri.gd_maxHp,
	RoleRecSum = RoleRec2#role{
		gd_currentHp       = MaxHp,
		gd_maxHp           = MaxHp,
		p_att              = round((RoleModeRec#role.p_att + RoleRec2#role.p_att + AddedPAtt)* (1+AttRate)),
		p_def              = round((RoleModeRec#role.p_def + RoleRec2#role.p_def + AddedPDef)*(1+PdefRate)),
		m_att              = round((RoleModeRec#role.m_att + RoleRec2#role.m_att + AddedMAtt)* (1+AttRate)),
		m_def              = round((RoleModeRec#role.m_def + RoleRec2#role.m_def + AddedMDef)* (1+MdefRate)),
		gd_speed           = round((RoleModeRec#role.gd_speed + RoleRec2#role.gd_speed + AddedSpeed)* (1+SpeedRate)),
		gd_mingzhong       = RoleModeRec#role.gd_mingzhong + RoleRec2#role.gd_mingzhong,
		gd_shanbi          = RoleModeRec#role.gd_shanbi + RoleRec2#role.gd_shanbi,	
		gd_baoji           = RoleModeRec#role.gd_baoji + RoleRec2#role.gd_baoji,
		gd_xingyun         = RoleModeRec#role.gd_xingyun + RoleRec2#role.gd_xingyun,
		gd_zhiming         = RoleModeRec#role.gd_zhiming + RoleRec2#role.gd_zhiming,
		gd_gedang          = RoleModeRec#role.gd_gedang + RoleRec2#role.gd_gedang,	
		gd_fanji           = RoleModeRec#role.gd_fanji + RoleRec2#role.gd_fanji,
		gd_pojia           = RoleModeRec#role.gd_pojia + RoleRec2#role.gd_pojia
	},
	RoleRecSum. 

get_skill_added(SkillList) ->
	Fun = fun({_, SkillModeId, _}, UpdateAttriRec) ->
		SkillInfo = data_skill:skill_info(SkillModeId),
		case (SkillInfo#skill_info.effect == ?SKILL_EFFECT_FIXED) of
			true ->
				Rec = data_skill:get_role_added_attri(SkillModeId),
				role_util:role_update_attri_add(UpdateAttriRec, Rec);
			false ->
				UpdateAttriRec
		end
	end,
	lists:foldl(Fun, #role_update_attri{}, SkillList).


%% add additional attribute to mercenary, and return new #mercenary{}
update_attri(RoleRec, Attri) ->
	?INFO(role, "update_attri: ~w, role: ~w", [Attri, RoleRec]),
	RoleRec#role{
		gd_liliang   = RoleRec#role.gd_liliang + Attri#role_update_attri.gd_liliang,
		gd_yuansheng = RoleRec#role.gd_yuansheng + Attri#role_update_attri.gd_yuansheng,
		gd_tipo      = RoleRec#role.gd_tipo + Attri#role_update_attri.gd_tipo,
		gd_minjie    = RoleRec#role.gd_minjie + Attri#role_update_attri.gd_minjie,
		gd_speed     = RoleRec#role.gd_speed + Attri#role_update_attri.gd_speed,
		gd_baoji     = RoleRec#role.gd_baoji + Attri#role_update_attri.gd_baoji,
		gd_shanbi    = RoleRec#role.gd_shanbi + Attri#role_update_attri.gd_shanbi,
		gd_gedang    = RoleRec#role.gd_gedang + Attri#role_update_attri.gd_gedang,
		gd_mingzhong = RoleRec#role.gd_mingzhong + Attri#role_update_attri.gd_mingzhong,
		gd_zhiming   = RoleRec#role.gd_zhiming + Attri#role_update_attri.gd_zhiming,
		gd_xingyun   = RoleRec#role.gd_xingyun + Attri#role_update_attri.gd_xingyun,
		gd_fanji     = RoleRec#role.gd_fanji + Attri#role_update_attri.gd_fanji,
		gd_pojia     = RoleRec#role.gd_pojia + Attri#role_update_attri.gd_pojia,
		gd_currentHp = RoleRec#role.gd_currentHp + Attri#role_update_attri.gd_currentHp,
		gd_maxHp     = RoleRec#role.gd_maxHp + Attri#role_update_attri.gd_maxHp,
		p_def        = RoleRec#role.p_def + Attri#role_update_attri.p_def,
		m_def        = RoleRec#role.m_def + Attri#role_update_attri.m_def,
		p_att        = RoleRec#role.p_att + Attri#role_update_attri.p_att,
		m_att        = RoleRec#role.m_att + Attri#role_update_attri.m_att
	}.


check_employ_requirement(PlayerId, RoleId) ->
	%% TO-DO: 添加佣兵招募的条件检测
	{OfficialPosReq, JunweiReq, SilverReq} = data_role:requirement(RoleId),
	case mod_economy:check_silver(PlayerId, SilverReq) of
		false -> {false, ?ERR_NOT_ENOUGH_SILVER};
		true -> 
			Ret = case JunweiReq > 0 of
				true -> 
					case role_data_base:check_junwei(PlayerId, JunweiReq) of
						true -> true;
						false -> {false, ?ERR_NOT_ENOUGH_JUN_WEI}
					end;
				false ->
					true
			end,
			case Ret of
				true -> 
					case OfficialPosReq =< mod_official:get_official_position(PlayerId) of
						true -> true;
						false -> {false, ?ERR_NOT_ENOUGH_GUAN_ZHI}
					end;
				_ -> Ret
			end
	end.

get_weiwang(PlayerId) ->
	RoleRec = get_main_role_rec(PlayerId),
	RoleLevel = RoleRec#role.gd_roleLevel,
	Normal2_skill_level = role_skill:get_normal2_skill_level(RoleRec),
	Special_skill_level = role_skill:get_special_skill_level(RoleRec),
	SumFirstAttri = getSumFirstAttri(RoleRec),
	if  (RoleLevel >= 100) 
		andalso (Normal2_skill_level >=10) 
		andalso (Special_skill_level >=10)
		andalso (SumFirstAttri >= 500) ->
			5;
		(RoleLevel >= 80) 
		andalso (Normal2_skill_level >=8)
		andalso (Special_skill_level >=8)
		andalso (SumFirstAttri >= 400) ->
			4;
		(RoleLevel >= 60) 
		andalso (Normal2_skill_level >=6)
		andalso (Special_skill_level >=6)
		andalso (SumFirstAttri >= 300) ->
			3;
		(RoleLevel >= 40) 
		andalso (Normal2_skill_level >=4) ->
			2;
		RoleLevel >= 10 ->
			1;
		true ->
			0
	end.

get_weiwang_by_roleRec(RoleRec)->
	RoleLevel = RoleRec#role.gd_roleLevel,
	Normal2_skill_level = role_skill:get_normal2_skill_level(RoleRec),
	Special_skill_level = role_skill:get_special_skill_level(RoleRec),
	SumFirstAttri = getSumFirstAttri(RoleRec),
	if  (RoleLevel >= 100) 
		andalso (Normal2_skill_level >=10) 
		andalso (Special_skill_level >=10)
		andalso (SumFirstAttri >= 500) ->
			5;
		(RoleLevel >= 80) 
		andalso (Normal2_skill_level >=8)
		andalso (Special_skill_level >=8)
		andalso (SumFirstAttri >= 400) ->
			4;
		(RoleLevel >= 60) 
		andalso (Normal2_skill_level >=6)
		andalso (Special_skill_level >=6)
		andalso (SumFirstAttri >= 300) ->
			3;
		(RoleLevel >= 40) 
		andalso (Normal2_skill_level >=4) ->
			2;
		RoleLevel >= 10 ->
			1;
		true ->
			0
	end.

get_added_weiwang_attri(RoleRec) ->
	WeiwangLevel = get_weiwang_by_roleRec(RoleRec),
	case WeiwangLevel >=1 of
		true ->
			?INFO(role,"******WeiwangLevel = ~w",[WeiwangLevel]),
			data_role:get_weiwang_attri(WeiwangLevel);
		false ->
			#role_update_attri{}
	end.
		
getSumFirstAttri(RoleRec) ->
	Liliang = RoleRec#role.gd_liliang,
	Yuansheng = RoleRec#role.gd_yuansheng,
	Tipo = RoleRec#role.gd_tipo,
	Minjie = RoleRec#role.gd_minjie,
	Liliang+Yuansheng+Tipo+Minjie.

create_items(PlayerId,RoleId) ->
	RoleRec = data_role:get(RoleId),
	case RoleRec#role.gd_careerID of
		1 ->
			Weapon = 10;
		2 ->
			Weapon = 9;
		_Else ->
			Weapon = 11
	end,
	mod_items:createItemsOnRole(PlayerId,RoleId,[{4,1},{5,1},{6,1},{7,1},{8,1},{Weapon,1}],?ITEM_FROM_EMPLOY).