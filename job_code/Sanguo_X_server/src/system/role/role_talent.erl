-module (role_talent).

-include("common.hrl").

-define(TALENT_CARD, 	294).	%% 天赋卡的物品id

-compile(export_all).

up_talent(PlayerId, RoleId, _AttriId, _IsProtected, AutoUseCard) ->
	RoleRec    = role_base:get_employed_role_rec(PlayerId, RoleId),
	CostGold   = data_system:get(4),
	CostSilver = data_role:get_up_talent_cost(get_total_upped_talent(RoleRec) div 4),
	Ret = case mod_economy:check_silver(PlayerId, CostSilver) of
		false ->
			{false, ?ERR_NOT_ENOUGH_SILVER};
		true ->
			case AutoUseCard of
				1 -> 
					case mod_economy:check_bind_gold(PlayerId, CostGold) of
						true ->
							true;
						false ->
							{false, ?ERR_NOT_ENOUGH_GOLD}
					end;
				0 ->
					CheckCard = mod_items:has_items(PlayerId, ?TALENT_CARD, 1),
					case CheckCard of
						true ->
							true;
						false ->
							{false, ?ERR_NO_TALENT_CARD}
					end
			end
	end,
	case Ret of
		{false, _ErrCode} -> ok;
		_ ->
			{TotalUpLiliang, 
			 TotalUpYuansheng, 
			 TotalUpTipo, 
			 TotalUpMinjie} = truncate_talent(up_talent(RoleRec), RoleRec),
			Updates = [{#role.gd_tliliang, TotalUpLiliang},
					   {#role.gd_tyuansheng, TotalUpYuansheng},
					   {#role.gd_ttipo, TotalUpTipo},
					   {#role.gd_tminjie, TotalUpMinjie}],
			role_db:update_role_elements(PlayerId, RoleRec#role.key, Updates), 
			case AutoUseCard of
				1 ->
					mod_economy:use_bind_gold(PlayerId, CostGold, ?GOLD_TALENT_CARD_COST);
				0 ->
					mod_items:useNumByItemID(PlayerId, ?TALENT_CARD, 1)
			end,
			mod_economy:use_silver(PlayerId, CostSilver, ?SILVER_UP_TALENT)
	end,
	Ret.

% up_talent(RoleRec, OldAttri) ->
% 	{PlayerId, _RoleId} = RoleRec#role.key,
% 	case AttriId of
% 		?TALENT_LILIANG ->
% 			RecIndex      = #role.gd_tliliang, 
% 			OldTotalAdded = RoleRec#role.gd_tliliang,
% 			OldAttri      = RoleRec#role.gd_liliangTalent;
% 		?TALENT_YUANSHENG ->
% 			RecIndex      = #role.gd_tyuansheng, 
% 			OldTotalAdded = RoleRec#role.gd_tyuansheng,
% 			OldAttri      = RoleRec#role.gd_yuanshengTalent;
% 		?TALENT_TIPO ->
% 			RecIndex      = #role.gd_ttipo, 
% 			OldTotalAdded = RoleRec#role.gd_ttipo,
% 			OldAttri      = RoleRec#role.gd_tipoTalent;
% 		?TALENT_MINJIE ->
% 			RecIndex      = #role.gd_tminjie, 
% 			OldTotalAdded = RoleRec#role.gd_tminjie,
% 			OldAttri      = RoleRec#role.gd_minjieTalent
% 	end,
% 	case OldAttri < ?MAX_UP_TALENT of
% 		true ->
% 			AddedTalent = do_up_talent(OldAttri),
% 			case (OldAttri + AddedTalent1) > ?MAX_UP_TALENT of
% 				true ->
% 					AddedTalent2 = ?MAX_UP_TALENT - OldAttri;
% 				false ->
% 					AddedTalent2 = AddedTalent1
% 			end,
% 			TotalAdded = OldTotalAdded + AddedTalent2,
% 			role_db:update_role_elements(PlayerId, RoleRec#role.key, [{RecIndex, TotalAdded}]),
% 			{true, AddedTalent2, TotalAdded};
% 		false ->
% 			{false, ?ERR_TALENT_FULL}
% 	end.

up_talent(RoleRec) ->
	AverageAdded  = get_total_upped_talent(RoleRec) div 4,
	TalentRateRec = data_role:get_talent_up_rate(RoleRec#role.gd_careerID),
	UpLiliang     = do_up_talent(AverageAdded, TalentRateRec#talent_rate.liliang),
	UpYuansheng   = do_up_talent(AverageAdded, TalentRateRec#talent_rate.yuansheng),
	UpTipo        = do_up_talent(AverageAdded, TalentRateRec#talent_rate.liliang),
	UpMinjie      = do_up_talent(AverageAdded, TalentRateRec#talent_rate.liliang),
	{UpLiliang, UpYuansheng, UpTipo, UpMinjie}.

do_up_talent(AverageAddedTalent, Rate) ->
	N1 = Rate * (1 - 0.0017 * AverageAddedTalent) * 100,
	case util:rand(1, 10000) =< N1 of
		true ->  1;
		false -> 0
	end.

%% A传功给B
-spec power_a_to_b(player_id(), role_id(), role_id(), list()) ->
	{false, err_code()} | true.
power_a_to_b(PlayerId, ARoleId, BRoleId, PreservedSkillUidList) ->
	case power_a_to_b_check(PlayerId, ARoleId, BRoleId, PreservedSkillUidList) of
		{false, ErrCode} -> 
			{false, ErrCode};
		{true, ARoleRec, BRoleRec} ->
			%% 策划说要自动解雇传功者A，不做
			reset_role_power(PlayerId, ARoleRec),
			up_role_power(ARoleRec, BRoleRec, PreservedSkillUidList),
			true
	end.


power_a_to_b_check(PlayerId, ARoleId, BRoleId, PreservedSkillUidList) ->
	case role_base:get_employed_role_rec(PlayerId, ARoleId) of
		none -> 
			{false, ?ERR_MER_NOT_EXIST};
		ARoleRec ->
			case role_base:get_employed_role_rec(PlayerId, BRoleId) of
				none -> 
					{false, ?ERR_MER_NOT_EXIST};
				BRoleRec ->
					TB = get_total_talent(BRoleRec),
					TAdd = get_total_upped_talent(ARoleRec,BRoleRec),
					BTotalAttri = TB + TAdd,
					?INFO(role,"^^^^^^^^^^^^^^BT = ~w,TAdd = ~w",[TB,TAdd]),
					SkillHoles = role_skill:get_skill_hole_nums(BTotalAttri),
					case SkillHoles =:= length(PreservedSkillUidList) of
						true ->
							{true, ARoleRec, BRoleRec};
						false ->
							?INFO(role,"!!!!!!!!!!!!!!SkillHoles = ~w,SKillNum = ~w",[SkillHoles,length(PreservedSkillUidList)]),
							{false, ?ERR_SKILL_NUM_NOT_MATCH}
					end
			end
	end.

reset_role_power(PlayerId, RoleRec) ->
	SkillTuple = role_skill:find_role_special_skill(RoleRec),
	% RoleRec1   = RoleRec#role{
	% 	gd_roleLevel  = 1,
	% 	gd_exp        = 0,
	% 	gd_skill      = [SkillTuple],
	% 	gd_fliliang   = 0,
	% 	gd_fyuansheng = 0,
	% 	gd_ftipo      = 0,
	% 	gd_fminjie    = 0
	% },
	UpdateFields = [{#role.gd_roleLevel, 1}, 
				    {#role.gd_exp, 0}, 
				    {#role.gd_skill, [SkillTuple]},
					{#role.gd_fliliang, 0}, 
					{#role.gd_fyuansheng, 0}, 
					{#role.gd_ftipo, 0}, 
					{#role.gd_fminjie, 0},
					{#role.gd_tliliang, 0}, 
					{#role.gd_tyuansheng, 0}, 
					{#role.gd_ttipo, 0}, 
					{#role.gd_tminjie, 0}
					],
	role_db:update_role_elements(PlayerId, RoleRec#role.key, UpdateFields).

up_role_power(FromRoleRec, ToRoleRec, PreservedSkillUidList) ->
	role_base:add_exp(ToRoleRec, FromRoleRec#role.gd_exp),
	%% 上面的代码已更新gen_cache中的经验和等级了
	Fun = fun({SkillUid, _, _}) ->
		lists:member(SkillUid, PreservedSkillUidList)
	end,
	%% 获取要保留的普通被动技能列表
	SkillList0 = lists:filter(Fun, lists:append(FromRoleRec#role.gd_skill, ToRoleRec#role.gd_skill)),
	%% 受功者的无双技能是要保留的
	SkillList = [role_skill:find_role_special_skill(ToRoleRec) | SkillList0],

	%% 要保证受功者的天赋增加后的技能孔数要正确
	TB = get_total_talent(ToRoleRec),
	TAdd = get_total_upped_talent(ToRoleRec,FromRoleRec),
	BTotalAttri = TB + TAdd,
	?INFO(role,"ToRoleRec talent = ~w,AddedTalent = ~w",[TB,TAdd]),
	SkillHoles = role_skill:get_skill_hole_nums(BTotalAttri),
	case SkillHoles - length(SkillList0) of
		0 -> 
			SkillList1 = SkillList;
		ExtraHoles ->
			SkillList1 = lists:append(role_skill:gen_skill(ExtraHoles, false, SkillList, []), SkillList)
	end,
	Tliliang   = util:max(FromRoleRec#role.gd_tliliang , ToRoleRec#role.gd_tliliang),
	Tyuansheng = util:max(FromRoleRec#role.gd_tyuansheng , ToRoleRec#role.gd_tyuansheng),
	Ttipo      = util:max(FromRoleRec#role.gd_ttipo , ToRoleRec#role.gd_ttipo),
	Tminjie    = util:max(FromRoleRec#role.gd_tminjie , ToRoleRec#role.gd_tminjie),
	UpdateFields = [{#role.gd_skill, SkillList1},
					{#role.gd_fliliang, util:max(FromRoleRec#role.gd_fliliang,ToRoleRec#role.gd_fliliang)}, 
					{#role.gd_fyuansheng, util:max(FromRoleRec#role.gd_fyuansheng,ToRoleRec#role.gd_fyuansheng)}, 
					{#role.gd_ftipo, util:max(FromRoleRec#role.gd_ftipo,ToRoleRec#role.gd_ftipo)}, 
					{#role.gd_fminjie, util:max(FromRoleRec#role.gd_fminjie,ToRoleRec#role.gd_fminjie)},
					{#role.gd_tliliang, Tliliang},
					{#role.gd_tyuansheng, Tyuansheng},
					{#role.gd_ttipo, Ttipo},
					{#role.gd_tminjie, Tminjie}
				],
	{PlayerId, _RoleId} = ToRoleRec#role.key,
	role_db:update_role_elements(PlayerId, ToRoleRec#role.key, UpdateFields).

truncate_talent(UppedTalent) ->
	if
		UppedTalent > ?MAX_UP_TALENT -> ?MAX_UP_TALENT;
		true -> UppedTalent
	end.
truncate_talent({UpLiliang, UpYuansheng, UpTipo, UpMinjie}, RoleRec) ->
	{	
	 truncate_talent(UpLiliang + RoleRec#role.gd_tliliang),
	 truncate_talent(UpYuansheng + RoleRec#role.gd_tyuansheng),
	 truncate_talent(UpTipo + RoleRec#role.gd_ttipo),
	 truncate_talent(UpMinjie + RoleRec#role.gd_tminjie)}.

get_total_upped_talent(RoleRec) ->
	RoleRec#role.gd_tliliang+RoleRec#role.gd_tyuansheng+
	RoleRec#role.gd_ttipo+RoleRec#role.gd_tminjie.

get_total_upped_talent(RoleRec1,RoleRec2) ->
	util:max(RoleRec1#role.gd_tliliang,RoleRec2#role.gd_tliliang) + util:max(RoleRec1#role.gd_tyuansheng,RoleRec2#role.gd_tyuansheng)+ 
	util:max(RoleRec1#role.gd_ttipo,RoleRec2#role.gd_ttipo) + util:max(RoleRec1#role.gd_tminjie,RoleRec2#role.gd_tminjie).

get_total_talent(RoleRec1) ->
	{_PlayerId,RoleId} = RoleRec1#role.key,
	RoleRec = data_role:get(RoleId),
	RoleRec#role.gd_liliangTalent + RoleRec#role.gd_yuanshengTalent + 
	RoleRec#role.gd_tipoTalent + RoleRec#role.gd_minjieTalent.

