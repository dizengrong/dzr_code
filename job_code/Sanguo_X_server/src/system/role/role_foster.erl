-module (role_foster).

-include("common.hrl").

-compile(export_all).

-define(FOSTER_CARD, 	295).	%% 天赋卡的物品id

foster(PlayerId, RoleId, AutoUseCard) ->
	case role_base:get_employed_role_rec(PlayerId, RoleId) of
		none ->
			{false, ?ERR_MER_NOT_EXIST};
		RoleRec when (RoleRec#role.gd_roleRank == 0) ->
			foster_normal_role(PlayerId, RoleRec, AutoUseCard);
		_ ->
			{false, ?ERR_UNKNOWN}
	end.

foster_normal_role(PlayerId, RoleRec, AutoUseCard) ->
	CostGold = data_system:get(1),
	if 
		(AutoUseCard == 0) ->
			FosterCheck = mod_items:has_items(PlayerId, ?FOSTER_CARD, 1);
		true ->
			case mod_economy:check_bind_gold(PlayerId, CostGold) of
				true -> FosterCheck = true;
				false -> FosterCheck = {false, ?ERR_NOT_ENOUGH_GOLD}
			end
	end,
	CostSilver = data_role:get_foster_cost(trunc(get_total_added(RoleRec) / 4)),
	case FosterCheck of
		true -> 
			case mod_economy:check_silver(PlayerId, CostSilver) of
				false ->
					FosterCheck1 = {false, ?ERR_NOT_ENOUGH_SILVER};
				true ->
					FosterCheck1 = true
			end;
		_  ->
			FosterCheck1 = FosterCheck
	end,

	case FosterCheck1 of
		true ->
			case AutoUseCard == 0 of
				true ->
					mod_items:useNumByItemID(PlayerId, ?FOSTER_CARD, 1);
				false ->
					mod_economy:use_bind_gold(PlayerId, CostGold, ?GOLD_FOSTER_CARD_COST)
			end,
			mod_economy:use_silver(PlayerId, CostSilver, ?SILVER_FOSTER),
			{AddtionalVal, 
			 TotalFliliang, 
			 TotalFyuansheng, 
			 TotalFtipo, 
			 TotalFminjie} = add_addtional(PlayerId, truncate_foster(do_foster(RoleRec), RoleRec)),
			Updates = [{#role.gd_fliliang, TotalFliliang}, 
					   {#role.gd_fyuansheng, TotalFyuansheng}, 
					   {#role.gd_ftipo, TotalFtipo}, 
					   {#role.gd_fminjie, TotalFminjie}],
			role_db:update_role_elements(PlayerId, RoleRec#role.key, Updates),
			{AddtionalVal, TotalFliliang, 
						   TotalFyuansheng, 
						   TotalFtipo, 
						   TotalFminjie};
		_ ->
			FosterCheck1
	end.


add_addtional(PlayerId, {TotalFliliang, TotalFyuansheng, TotalFtipo, TotalFminjie}) ->
	Ave = (TotalFliliang + TotalFyuansheng + TotalFtipo + TotalFminjie) div 4,
	CurrentFlag = role_db:get_foster_flag(PlayerId),
	case data_role:foster_flag(CurrentFlag) of
		none -> 
			{0, TotalFliliang, TotalFyuansheng, TotalFtipo, TotalFminjie};
		{AveCfg, AddtionalCfg, NextFlag} ->
			case Ave > AveCfg of
				true ->
					role_db:set_foster_flag(PlayerId, NextFlag),
					{AddtionalCfg, TotalFliliang + AddtionalCfg, 
						   TotalFyuansheng + AddtionalCfg, 
						   TotalFtipo + AddtionalCfg, 
						   TotalFminjie + AddtionalCfg};
				false ->
					{0, TotalFliliang, TotalFyuansheng, TotalFtipo, TotalFminjie}
			end
	end.


truncate_foster({Fliliang, Fyuansheng, Ftipo, Fminjie}, RoleRec) ->
	{_PlayerId, RoleId} = RoleRec#role.key,
	RoleModeRec = data_role:get(RoleId),
	Fliliang1   = truncate_foster_help(Fliliang + RoleRec#role.gd_fliliang, RoleModeRec#role.gd_liliang),
	Fyuansheng1 = truncate_foster_help(Fyuansheng + RoleRec#role.gd_fyuansheng, RoleModeRec#role.gd_yuansheng),
	Ftipo1      = truncate_foster_help(Ftipo + RoleRec#role.gd_ftipo, RoleModeRec#role.gd_tipo),
	Fminjie1    = truncate_foster_help(Fminjie + RoleRec#role.gd_fminjie, RoleModeRec#role.gd_minjie),
	{Fliliang1, Fyuansheng1, Ftipo1, Fminjie1}.

truncate_foster_help(TotalFosterAttri, CfgAttri) ->
	if
		(TotalFosterAttri + CfgAttri > ?MAX_FOSTER) -> ?MAX_FOSTER - CfgAttri;
		true -> TotalFosterAttri
	end.

do_foster(RoleRec) ->
	Average = get_total_added(RoleRec) / 4,
	FosterRate = data_role:foster_rate(RoleRec#role.gd_careerID),
	Fliliang   = do_foster_help(Average, FosterRate#foster_rate.liliang),
	Fyuansheng = do_foster_help(Average, FosterRate#foster_rate.yuansheng),
	Ftipo      = do_foster_help(Average, FosterRate#foster_rate.tipo),
	Fminjie    = do_foster_help(Average, FosterRate#foster_rate.minjie),
	{Fliliang, Fyuansheng, Ftipo, Fminjie}.

do_foster_help(Average, N) ->
	N1 = N * (1 - 0.001 * Average) * 100,
	case util:rand(1, 10000) =< N1 of
		true ->  1;
		false -> 0
	end.

%% 获取4个基础属性总的加成的值
get_total_added(RoleRec) ->
	RoleRec#role.gd_fliliang + RoleRec#role.gd_fyuansheng + 
	RoleRec#role.gd_ftipo + RoleRec#role.gd_fminjie.
