-module(mod_role).

-include("common.hrl").

-export ([start_link/1]).

-export([client_get_employed_list/1, client_get_fired_list/1,
		 client_employ/2, client_fire/2, client_up_talent/5, client_A_to_B/4,
		 client_foster/3, client_refresh_skill/3, client_get_junwei/1,
		 client_get_zhaoshu_flag/1, client_get_free_zhaoshu/1,client_up_skill/5,
		 client_buy_zhaoshu/2, client_change_battle_state/2,client_get_weiwang/1,add_hp/4
	]).

-export ([get_role_rec/2, get_employed_id_list/1, get_main_role_rec/1,
		  update_attri_notify/2, update_attri_all_notify/1, 
		  main_role_update_attri_notify/1, add_employable/2,
		  get_on_battle_list/1, add_exp/3, add_exp/4, add_exp_to_main_role/3,
		  add_exp_to_on_battle_roles/3, calc_combat_point/1,
		  get_all_fight_ability/1, gm_change_attri/4, add_skill_exp/4,
		  main_role_gain_skill/2,get_main_level/1,get_weiwang/1,client_get_weiwang2/2,
          get_main_role_employed_id/1
		  ]).

%% gen_server callbacks 
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% internal export
-export ([client_get_employed_list2/2, get_role_rec2/2, client_get_fired_list2/2,
		  get_employed_id_list2/2, get_main_role_rec2/2, update_attri_notify2/2,
		  update_attri_all_notify2/2, add_employable2/2, add_exp2/2,
		  add_exp_to_on_battle_roles2/2, get_all_fight_ability2/2,
		  client_employ2/2, client_fire2/2, gm_change_attri2/2, client_up_talent2/2,
		  add_skill_exp2/2, client_A_to_B2/2, main_role_gain_skill2/2,
		  client_foster2/2, client_refresh_skill2/2, client_get_junwei2/2,
		  client_get_zhaoshu_flag2/2, client_get_free_zhaoshu2/2,
		  client_buy_zhaoshu2/2, client_change_battle_state2/2,
		  gm_replace_role_skill/3, gm_replace_role_skill2/2, delete_role_skill/3, 
		  delete_role_skill2/2,add_hp2/2]).

start_link({PlayerId})->
	gen_server:start_link(?MODULE, [PlayerId], []).

client_get_employed_list(PlayerId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_get_employed_list2, PlayerId, []}).

client_get_fired_list(PlayerId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_get_fired_list2, PlayerId, []}).

client_employ(PlayerId, RoleId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_employ2, PlayerId, [RoleId]}).

client_up_talent(PlayerId, RoleId, AttriId, IsProtected, AutoUseCard) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_up_talent2, PlayerId, 
					 [RoleId, AttriId, IsProtected, AutoUseCard]}).	

client_fire(PlayerId, RoleId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_fire2, PlayerId, [RoleId]}).

%% 客户端请求由A传功给B
client_A_to_B(PlayerId, ARoleId, BRoleId, PreservedSkillList) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_A_to_B2, PlayerId, [ARoleId, BRoleId, PreservedSkillList]}).

%% 客户端请求培养，AutoUseCard为0表示不自动使用培养卡，1为自动使用
client_foster(PlayerId, RoleId, AutoUseCard) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_foster2, PlayerId, [RoleId, AutoUseCard]}).

%% 客户端请求刷新技能
client_refresh_skill(PlayerId, RoleId, ReservedList) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_refresh_skill2, PlayerId, [RoleId, ReservedList]}).

%% 客户端获取君威信息
client_get_junwei(PlayerId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_get_junwei2, PlayerId, []}).

%% 客户端获取威望动态更新
client_get_weiwang(PlayerId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_get_weiwang2, PlayerId, []}).

%% 客户端获取普通诏书领取信息
client_get_zhaoshu_flag(PlayerId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_get_zhaoshu_flag2, PlayerId, []}).

%% 客户端获取免费的诏书君威
client_get_free_zhaoshu(PlayerId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_get_free_zhaoshu2, PlayerId, []}).

client_buy_zhaoshu(PlayerId, ZhaoshuType) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_buy_zhaoshu2, PlayerId, [ZhaoshuType]}).

%% 客户端请求佣兵出战/休息
client_change_battle_state(PlayerId, {RoleId, IsBattle}) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, client_change_battle_state2, PlayerId, [RoleId, IsBattle]}).
%% 升级技能 mod_role:client_up_skill(6003732,5,116001,263,2).
client_up_skill(PlayerId,RoleId,SkillID,ItemID,Num) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{up_skill, {PlayerId,RoleId,SkillID,ItemID,Num}}).

%% 获取已雇佣的角色记录，若不存在则返回none
-spec get_role_rec(player_id(), role_id()) -> role() | none.
get_role_rec(PlayerId, RoleId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:call(ThisPid, 
					{module_req, get_role_rec2, PlayerId, [RoleId]}).

%% 获取玩家已雇佣的佣兵ID的列表
-spec get_employed_id_list(player_id()) -> list().
get_employed_id_list(PlayerId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:call(ThisPid, 
					{module_req, get_employed_id_list2, PlayerId, []}).

%% 获取主角色记录
-spec get_main_role_rec(player_id()) -> role().
get_main_role_rec(PlayerId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:call(ThisPid, 
					{module_req, get_main_role_rec2, PlayerId, []}).

%% 角色更新属性数据的通知
-spec update_attri_notify(player_id(), role_id()) -> any().
update_attri_notify(PlayerId, RoleId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{module_req, update_attri_notify2, PlayerId, [RoleId]}).

main_role_update_attri_notify(PlayerId) ->
	MainRoleId = mod_player:get_main_role_id(PlayerId),
	update_attri_notify(PlayerId, MainRoleId).

%% 所有已雇佣的角色更新属性数据的通知
-spec update_attri_all_notify(player_id()) -> any().
update_attri_all_notify(PlayerId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{module_req, update_attri_all_notify2, PlayerId, []}).

%% 增加玩家可佣兵的佣兵
%% 参数：EmployableList为增加的可雇佣的佣兵列表
-spec add_employable(player_id(), list()) -> any().
add_employable(PlayerId, RoleIdList) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{module_req, add_employable2, PlayerId, [RoleIdList]}).

%% 获取出战的佣兵记录的列表
-spec get_on_battle_list(player_id()) -> [role()].
get_on_battle_list(PlayerId) ->
	role_base:get_on_battle_list(PlayerId).

%% 为佣兵增加经验
%% 参数ExpTuple为{角色id, 要增加的经验值}，
%% LogType为增加经验的类型,具体的类别请参见log_type.h中的EXP_FROM_XXX宏定义
-spec add_exp(player_id(), {role_id(), integer()}, integer()) -> any().
add_exp(PlayerId, ExpTuple, LogType) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{module_req, add_exp2, PlayerId, [ExpTuple, LogType, true]}).

%% 与 add_exp/3 类似，参数SendFlag指示是否发包通知客户端
add_exp(PlayerId, ExpTuple, LogType, SendFlag) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{module_req, add_exp2, PlayerId, [ExpTuple, LogType, SendFlag]}).

add_exp_to_main_role(PlayerId, Exp, LogType) ->
	MainRoleId = mod_account:get_main_role_id(PlayerId),
	add_exp(PlayerId, {MainRoleId, Exp}, LogType).

%% 为所有出战的佣兵加经验
-spec add_exp_to_on_battle_roles(player_id(), integer(), integer()) -> any().
add_exp_to_on_battle_roles(PlayerId, Exp, LogType) ->
	case Exp =< 0 of
		true -> ok;
		_ ->
			ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
			gen_server:cast(ThisPid, 
					{module_req, add_exp_to_on_battle_roles2, PlayerId, [Exp, LogType]})
	end.

%% 增加血量()
add_hp(PlayerId,RoleId, HpAdd, LogType)->
	case HpAdd =< 0 of
		true -> ok;
		_ ->
			ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
			gen_server:cast(ThisPid, 
					{module_req, add_hp2, PlayerId, [RoleId, HpAdd, LogType]})
	end.

%% 计算一个角色的战斗力
-spec calc_combat_point(role()) -> integer().
calc_combat_point(RoleRec) ->
	role_base:calc_combat_point(RoleRec).	

%% 计算所有上场角色的战斗力总和
-spec get_all_fight_ability(player_id()) -> integer().
get_all_fight_ability(PlayerId)	->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{module_req, get_all_fight_ability2, PlayerId, []}).

  
add_skill_exp(PlayerId, RoleId, SkillUid, AddedExp) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{module_req, add_skill_exp2, PlayerId, [RoleId, SkillUid, AddedExp]}).

main_role_gain_skill(PlayerId, SkillModeId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{module_req, main_role_gain_skill2, PlayerId, [SkillModeId]}).

%% 返回主角等级
-spec get_main_level(player_id()) -> integer().
get_main_level(PlayerId)->
	Role_rec = role_base:get_main_role_rec(PlayerId),
	Role_rec#role.gd_roleLevel.

%% 返回主角佣兵id
get_main_role_employed_id(PlayerId) ->
    RoleRec = role_base:get_main_role_rec(PlayerId),
    {PlayerId,EmployedId} = RoleRec#role.key,
    EmployedId.

%% 返回主角威望（1,2,3,4,5；1是没有）
-spec get_weiwang(player_id()) -> integer().
get_weiwang(PlayerId) ->
	role_base:get_weiwang(PlayerId).

%% ====================================================================
%% =========================== gm =====================================
gm_change_attri(PlayerId, RoleId, Att, Hp) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:cast(ThisPid, 
					{client_req, gm_change_attri2, PlayerId, [RoleId, Att, Hp]}).

gm_replace_role_skill(PlayerId, RoleId, SkillModeId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:call(ThisPid, 
					{client_req, gm_replace_role_skill2, PlayerId, [RoleId, SkillModeId]}).

delete_role_skill(PlayerId, RoleId, SkillModeId) ->
	ThisPid = mod_player:get_pid(PlayerId, ?MODULE), 
	gen_server:call(ThisPid, 
					{client_req, delete_role_skill2, PlayerId, [RoleId, SkillModeId]}).
%% --------------------------------------------------------------------
%% Function: init/1
%% --------------------------------------------------------------------
init([PlayerId]) ->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, PlayerId),
	mod_player:update_module_pid(PlayerId, ?MODULE, self()),
    {ok, #role_state{player_id = PlayerId}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% --------------------------------------------------------------------
handle_call({client_req, Action, PlayerId, Args}, _From, State) ->
	Reply = ?MODULE:Action(PlayerId, Args),
    {reply, Reply, State};

handle_call({module_req, Action, PlayerId, Args}, _From, State) ->
	Reply = ?MODULE:Action(PlayerId, Args),
    {reply, Reply, State}.
%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% --------------------------------------------------------------------
handle_cast({module_req, Action, PlayerId, Args}, State) ->
	?MODULE:Action(PlayerId, Args),
	{noreply, State};

handle_cast({client_req, Action, PlayerId, Args}, State) ->
	?MODULE:Action(PlayerId, Args),
	{noreply, State};

handle_cast({up_skill, {PlayerId,RoleId,SkillID,ItemID,Num}},State) ->
	RoleRec = role_base:get_employed_role_rec(PlayerId, RoleId),
	case lists:keyfind(SkillID,2,RoleRec#role.gd_skill) of
		false ->
			mod_err:send_err_by_id(PlayerId,?ERR_SKILL_NOT_EXIST);
		SkillTuple ->
			SkillInfo = data_skill:skill_info(SkillID),
			{SkillUid, _SkillModeId, _SkillExp} = SkillTuple,
			case SkillInfo#skill_info.next_skill_id == 0 of
				true ->
					mod_err:send_err_by_id(PlayerId,?ERR_SKILL_LEVEL_MAX);
				false ->
					SilverCostOne = data_skill:get_use_skillbook_cost(ItemID),
					Balance = mod_economy:get(PlayerId),
					SilverOwn = Balance#economy.gd_silver,
					ItemCanUse = SilverOwn div SilverCostOne,
					ItemNumHas = mod_items:getNumByItemID(PlayerId, ItemID),
					case ItemNumHas >= 1 of
						false ->
							mod_err:send_err_by_id(PlayerId,?ERR_ITEM_NOT_ENOUGH);
						true ->
							case ItemCanUse >= 1 of
								false ->
									mod_err:send_err_by_id(PlayerId,?ERR_NOT_ENOUGH_SILVER);
								true ->
									MaxExpNeed = get_max_skillexp_can_receive(SkillTuple,0),
									ItemExp = data_skill:get_skill_book_exp(ItemID),
									case MaxExpNeed rem ItemExp =:= 0 of
										true ->
											ItemMaxNeed = MaxExpNeed div ItemExp;
										false ->
											ItemMaxNeed = MaxExpNeed div ItemExp + 1
									end,
									ItemUseNum = lists:min([Num,ItemMaxNeed,ItemCanUse,ItemNumHas]),
									AddedExp = ItemExp*ItemUseNum,
									mod_items:deleteSomeItemsByItemID(PlayerId,[{ItemID,ItemUseNum}]),
									role_skill:add_skill_exp(PlayerId, RoleId, SkillUid, AddedExp)
							end
					end
			end
	end,
	{noreply,State}.
%% --------------------------------------------------------------------
%% Function: handle_info/2
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% --------------------------------------------------------------------
terminate(Reason, State) ->
	?INFO(role, "~w gen_server terminate, reason: ~w, state: ~w", 
		  [?MODULE, Reason, State]),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
%% ====================================================================  	
%% ====================================================================  	
send_employ_roles_to_client(PlayerId) ->
	RoleRecList = role_base:get_employed_roles(PlayerId),
	send_employ_roles_to_client(PlayerId, RoleRecList, length(RoleRecList)).
	
send_employ_roles_to_client(PlayerId, RoleRecList) ->
	EmployedNum = role_base:get_employed_role_num(PlayerId),
	send_employ_roles_to_client(PlayerId, RoleRecList, EmployedNum).

send_employ_roles_to_client(PlayerId, RoleRecList, EmployedNum) ->
	%% TO-DO: add vip code
	Vip = 0,
	CanEmployNum = data_vip:get_extra_employable(Vip),
	IsInGuild = guild:is_in_guild(PlayerId),

	{ok, Packet} = pt_15:write(15000, [CanEmployNum, IsInGuild, EmployedNum, RoleRecList]),
	lib_send:send_by_id(PlayerId, Packet).

client_get_employed_list2(PlayerId, []) ->
	send_employ_roles_to_client(PlayerId).

client_get_fired_list2(PlayerId, []) ->
	FiredRoleRecList = role_base:get_fired_list(PlayerId),
	{ok, Packet2} = pt_15:write(15101, FiredRoleRecList),

	lib_send:send_by_id(PlayerId, Packet2).

get_role_rec2(PlayerId, [RoleId]) ->
	role_base:get_employed_role_rec(PlayerId, RoleId).

get_employed_id_list2(PlayerId, []) ->
	role_base:get_employed_id_list(PlayerId).

get_main_role_rec2(PlayerId, []) ->
	role_base:get_main_role_rec(PlayerId).

update_attri_notify2(PlayerId, [RoleId]) ->
	?INFO(role,"Update attri notify!"),
	RoleRec = role_base:get_employed_role_rec(PlayerId, RoleId),
	client_get_weiwang(PlayerId),
	%% 成就通知
	FightAbility = mod_role:calc_combat_point(RoleRec),
	mod_achieve:fightabilityNotify(PlayerId,FightAbility),
	{ok, Packet} = pt_15:write(15001, RoleRec),
	lib_send:send_by_id(PlayerId, Packet).

update_attri_all_notify2(PlayerId, []) ->
	RoleRecList = role_base:get_employed_roles(PlayerId),

	Fun = fun(RoleRec, P) ->
		{ok, P1} = pt_15:write(15001, RoleRec),
		<<P/binary, P1/binary>>
	end,
	Packet = lists:foldl(Fun, <<>>, RoleRecList),
	lib_send:send_by_id(PlayerId, Packet).

add_employable2(PlayerId, [RoleIdList]) ->
	_NewAddedEmployableIdList = role_data_base:add_employable(PlayerId, RoleIdList),

	%% TO-DO: to notify client
	ok.


add_exp2(PlayerId, [{RoleId, AddedExp}, _LogType, SendFlag]) ->
	case role_base:get_employed_role_rec(PlayerId, RoleId) of
		none -> 
			?ERR(role, "there is no this role: ~w", [RoleId]),
			false;
		RoleRec -> 
			case role_base:add_exp(RoleRec, AddedExp) of
				false -> ok;
				{true, NewRoleRec} ->
					case SendFlag of 
						true -> 
							client_get_weiwang(PlayerId),
							{ok, Packet} = pt_15:write(15001, NewRoleRec),
							lib_send:send_by_id(PlayerId, Packet);
						false -> ok
					end,
 
					%% TO-DO: mod_user_log
					ok
			end
	end.	
add_exp_to_on_battle_roles2(PlayerId, [Exp, LogType]) ->
	OnBattleList = role_base:get_on_battle_list(PlayerId),
	Fun = fun(RoleRec) ->
		{_PlayerId, RoleId} = RoleRec#role.key,
		add_exp2(PlayerId, [{RoleId, Exp}, LogType, true])
	end,
	[Fun(Rec) || Rec <- OnBattleList].


add_hp2(PlayerId,[RoleId, HpAdd, _LogType]) ->
	case role_base:get_employed_role_rec(PlayerId, RoleId) of
		none -> 
			?ERR(role, "there is no this role: ~w", [RoleId]),
			false;
		RoleRec -> 
			case role_base:add_hp(RoleRec, HpAdd) of
				false -> ok;
				{true, NewRoleRec} ->
					{ok, Packet} = pt_15:write(15001, NewRoleRec),
					lib_send:send_by_id(PlayerId, Packet),
					%% TO-DO: mod_user_log
					ok
			end
	end.


get_all_fight_ability2(PlayerId, []) -> 
	role_base:get_all_fight_ability(PlayerId).

client_employ2(PlayerId, [RoleId]) ->
	case lists:member(RoleId, data_role:get_all_id()) of
		true ->
			Vip = mod_vip:get_vip_level(PlayerId),
			CanEmployNum = data_vip:get_extra_employable(Vip),
			case CanEmployNum > length(role_base:get_employed_roles(PlayerId)) of
				true ->
					case role_base:employ(PlayerId, RoleId) of
						{false, ErrCode} -> 
							?INFO(role, "role_base:employ failed, RoleId: ~w, ErrCode: ~w", 
								  [RoleId, ErrCode]),
							mod_err:send_err_by_id(PlayerId, ErrCode);
						true ->
							%% role_data_base:remove_a_employable_role(PlayerId, RoleId),
							%% TO-DO: mod_user_log
							%% 添加任务模块接口：
							mod_task:update_employ_task(PlayerId,RoleId,1),
							?INFO(task,"FINISH EMPLOY TASK:PlayerId = ~w,RoleId =~w,Times =1",[PlayerId,RoleId]),
							RoleRec = role_base:get_employed_role_rec(PlayerId, RoleId),
							{ok, Packet1} = pt_15:write(15102, {RoleId, 1}),
							{ok, Packet3} = pt_15:write(15010, []),
							Packet = <<Packet1/binary, Packet3/binary>>,
							send_employ_roles_to_client(PlayerId, [RoleRec]),
							lib_send:send_by_id(PlayerId, Packet),
							ok
					end;
				false ->
					mod_err:send_err_by_id(PlayerId, ?ERR_TOO_MANY_MER)
			end;
		false ->
			ok
	end.

client_fire2(PlayerId, [RoleId]) ->
	%% TO-DO: 1.maybe check if can do fire  2. add user log
	case role_base:fire(PlayerId, RoleId) of
		false -> 
			ok;
		{fail,ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode);
		true ->
			FiredRoleRec = role_base:get_fired_role_rec(PlayerId, RoleId),
			{ok, Packet1} = pt_15:write(15101, [FiredRoleRec]),
			{ok, Packet2} = pt_15:write(15102, {RoleId, 0}),
			lib_send:send_by_id(PlayerId, <<Packet2/binary, Packet1/binary>>)
	end.

client_up_talent2(PlayerId, [RoleId, AttriId, IsProtected, AutoUseCard]) ->
	case role_talent:up_talent(PlayerId, RoleId, AttriId, IsProtected, AutoUseCard) of
		{false, ErrCode} ->
			mod_err:send_err_by_id(PlayerId, ErrCode);
		true ->
			?INFO(role, "role ~w after up talant: AttriId = ~w, IsProtected = ~w, ",
				  [RoleId, AttriId, IsProtected]),
			%% TO-DO: add use log
			NewRoleRec = role_base:get_employed_role_rec(PlayerId, RoleId),
			{ok, Packet1} = pt_15:write(15001, NewRoleRec),
			lib_send:send_by_id(PlayerId, Packet1),

			case role_skill:talent_changed_notify(PlayerId, RoleId) of
				no_change ->
					?INFO(role, "skill hole not changed");
				{false, ErrCode} ->
					?INFO(role, "talent_changed_notify return error code: ~w", [ErrCode]);
				{true, NewSkills} ->
					?INFO(role, "talent_changed_notify return new skills: ~w", [NewSkills]),
					send_skill_update_to_client(PlayerId, RoleId, NewSkills)
			end,
			ok
	end.

send_skill_update_to_client(PlayerId, RoleId, Skills) ->
	IsInGuild = guild:is_in_guild(PlayerId),
	{ok, Packet} = pt_15:write(15002, {RoleId, Skills, IsInGuild}),
	lib_send:send_by_id(PlayerId, Packet).

client_A_to_B2(PlayerId, [ARoleId, BRoleId, PreservedSkillList]) ->
	case role_talent:power_a_to_b(PlayerId, ARoleId, BRoleId, PreservedSkillList) of
		true -> 
			ARoleRec = role_base:get_employed_role_rec(PlayerId, ARoleId),
			BRoleRec = role_base:get_employed_role_rec(PlayerId, BRoleId),
			{ok, Packet1} = pt_15:write(15001, ARoleRec),
			{ok, Packet2} = pt_15:write(15001, BRoleRec),
			lib_send:send_by_id(PlayerId, <<Packet1/binary, Packet2/binary>>);
		{false, ErrCode} ->
			?INFO(role, "role_talent:power_a_to_b return ErrCode: ~w", [ErrCode]),
			mod_err:send_err_by_id(PlayerId, ErrCode)
	end.

client_refresh_skill2(PlayerId, [RoleId, ReservedList]) ->
	case role_skill:refresh_skill(PlayerId, RoleId, ReservedList) of
		{false, ErrCode} ->
			?INFO(role, "role_skill:refresh_skill return ErrCode: ~w", [ErrCode]),
			mod_err:send_err_by_id(PlayerId, ErrCode);
		{true, NewSkills} ->
			?INFO(role, "role_skill:refresh_skill return success: NewSkills: ~w", [NewSkills]),
			send_skill_update_to_client(PlayerId, RoleId, NewSkills),

			RoleRec = role_base:get_employed_role_rec(PlayerId, RoleId),
			{ok, Packet2} = pt_15:write(15001, RoleRec),
			lib_send:send_by_id(PlayerId, <<Packet2/binary>>)
	end.

client_foster2(PlayerId, [RoleId, AutoUseCard]) ->
	case role_foster:foster(PlayerId, RoleId, AutoUseCard) of
		{false, ErrCode} ->
			?INFO(role, "role_foster:foster return ErrCode: ~w", [ErrCode]),
			mod_err:send_err_by_id(PlayerId, ErrCode);
		{AddtionalVal, TotalFliliang, TotalFyuansheng, TotalFtipo, TotalFminjie} ->
			?INFO(role, "role_foster:foster return success, "
						"AddtionalVal: ~w, TotalFliliang: ~w, TotalFyuansheng: ~w, "
						"TotalFtipo: ~w, TotalFminjie: ~w", 
				  [AddtionalVal, TotalFliliang, TotalFyuansheng, TotalFtipo, TotalFminjie]),
			% {ok, Packet} = pt_15:write(15210, {RoleId, AddtionalVal, TotalFliliang, TotalFyuansheng, TotalFtipo, TotalFminjie}),
			NewRoleRec = role_base:get_employed_role_rec(PlayerId, RoleId),
			{ok, Packet} = pt_15:write(15001, NewRoleRec),
			lib_send:send_by_id(PlayerId, Packet)
	end.

client_get_junwei2(PlayerId, []) ->
	Junwei = role_db:get_junwei(PlayerId),
	{ok, Packet} = pt_15:write(15300, Junwei),
	lib_send:send_by_id(PlayerId, Packet).

client_get_weiwang2(PlayerId,[]) ->
	Weiwang = role_base:get_weiwang(PlayerId),
	{ok, Packet} = pt_25:write(25003, Weiwang),
	lib_send:send_by_id(PlayerId, Packet).

client_get_zhaoshu_flag2(PlayerId, []) ->
	ZhaoshuCounter = mod_counter:get_counter(PlayerId, ?COUNTER_ZHAOSHU),

	{ok, Packet} = pt_15:write(15301, ?FREE_NORMAL_ZHAOSHU - ZhaoshuCounter),
	lib_send:send_by_id(PlayerId, Packet).

client_get_free_zhaoshu2(PlayerId, []) ->
	case mod_counter:get_counter(PlayerId, ?COUNTER_ZHAOSHU) of
		N when (N < ?FREE_NORMAL_ZHAOSHU) ->
			mod_counter:add_counter(PlayerId, ?COUNTER_ZHAOSHU),
			{true, TotalJunwei} = role_data_base:open_zhaoshu(PlayerId, ?NORMAL_ZHAOSHU, true),
			{ok, Packet1} = pt_15:write(15300, TotalJunwei),
			{ok, Packet2} = pt_15:write(15301, ?FREE_NORMAL_ZHAOSHU - N - 1),
			lib_send:send_by_id(PlayerId, <<Packet2/binary, Packet1/binary>>);
		_ ->
			?ERR(role, "free zhaoshu is already got!!!"),
			mod_err:send_err_by_id(PlayerId, ?ERR_UNKNOWN)
	end.

client_buy_zhaoshu2(PlayerId, [ZhaoshuType]) ->
	case role_data_base:open_zhaoshu(PlayerId, ZhaoshuType, false) of
		{false, ErrCode} ->
			?INFO(role, "role_data_base:open_zhaoshu return ErrCode: ~w", [ErrCode]),
			mod_err:send_err_by_id(PlayerId, ErrCode);
		{true, TotalJunwei} ->
			{ok, Packet} = pt_15:write(15300, TotalJunwei),
			lib_send:send_by_id(PlayerId, Packet)
	end.

client_change_battle_state2(PlayerId, [RoleId, IsBattle]) ->
	case role_base:change_battle_state(PlayerId, RoleId, IsBattle) of
		{false, ErrCode} ->
			?INFO(role, "role_base:change_battle_state return ErrCode: ~w", [ErrCode]),
			mod_err:send_err_by_id(PlayerId, ErrCode);
		{true, RoleRec} ->
			{ok, Packet} = pt_15:write(15001, RoleRec),
			lib_send:send_by_id(PlayerId, Packet)
	end.

add_skill_exp2(PlayerId, [RoleId, SkillUid, AddedExp]) ->
	case role_skill:add_skill_exp(PlayerId, RoleId, SkillUid, AddedExp) of
		{false, ErrCode} ->
			?INFO(role, "add_skill_exp return error code: ~w", [ErrCode]);
		{true, reach_max_level, SkillTuple} ->
			?INFO(role, "role ~w skill: ~w reach_max_level, cannot add exp again", 
				  [RoleId, SkillTuple]);
		{true, NotifyType, NewSkillTuple} ->
			?INFO(role, "add_skill_exp return success, NotifyType: ~w, NewSkillTuple: ~w", 
				  [NotifyType, NewSkillTuple]),
			client_get_weiwang(PlayerId),
			send_skill_update_to_client(PlayerId, RoleId, NewSkillTuple)
	end.

main_role_gain_skill2(_PlayerId, [_SkillModeId]) ->
	ok.
	%% TO-DO: 主角可能会从公会中学习得到技能
	% {true, MainRoleId, SkillTuple} = role_skill:add_main_role_skill(PlayerId, SkillModeId),
	% ?INFO(role, "player ~w main role gain skill: ~w", [PlayerId, SkillTuple]),
	% send_skill_update_to_client(PlayerId, RoleId, NewSkillTuple).



%% ==========================================================
%% ======================= gm ===============================
gm_replace_role_skill2(PlayerId, [RoleId, SkillModeIdList]) ->
	RoleRec = role_base:get_employed_role_rec(PlayerId, RoleId),
	Fun2 = fun(SkillModeId, SkillList) ->
		SkillUid = uid_server:get_seq_num(?UID_SKILL),
		SkillTuple = {SkillUid, SkillModeId, 0},
		[SkillTuple | SkillList]
	end,
	NewSkills = lists:foldl(Fun2, [], SkillModeIdList),
	role_db:update_role_elements(PlayerId, RoleRec#role.key, [{#role.gd_skill, NewSkills}]),
	RoleRec1 = role_base:get_employed_role_rec(PlayerId, RoleId),
	send_skill_update_to_client(PlayerId, RoleId, RoleRec1#role.gd_skill).

delete_role_skill2(PlayerId, [RoleId, SkillModeId]) ->
	RoleRec = role_base:get_employed_role_rec(PlayerId, RoleId),
	Ret = case lists:keyfind(SkillModeId, 2, RoleRec#role.gd_skill) of
		false ->
			{false, "Role has no this skill"};
		_ ->
			Skills = lists:keydelete(SkillModeId, 2, RoleRec#role.gd_skill),
			role_db:update_role_elements(PlayerId, RoleRec#role.key, [{#role.gd_skill, Skills}]),
			true
	end,
	case Ret of
		true ->
			RoleRec1 = role_base:get_employed_role_rec(PlayerId, RoleId),
			send_skill_update_to_client(PlayerId, RoleId, RoleRec1#role.gd_skill);
		_ ->
			ok
	end,
	Ret.


gm_change_attri2(PlayerId, [RoleId, Att, Hp]) -> 
	% 由于角色的数据都是动态来计算的，所以修改那些不持久化的字段是没用的。
	case role_base:get_employed_role_rec(PlayerId, RoleId) of
		none -> 
			?ERR(role, "there is no this role: ~w", [RoleId]),
			false;
		RoleRec ->
			UpdateFields = [{#role.p_att, Att}, {#role.m_att, Att}, 
							{#role.gd_currentHp, Hp}, {#role.gd_maxHp, Hp}],
			role_db:update_role_elements(PlayerId, RoleRec#role.key, UpdateFields),
			% NewRoleRec = role_base:get_employed_role_rec(PlayerId, RoleId),
			update_attri_notify(PlayerId,RoleId)
	end.

get_max_skillexp_can_receive({_ID,0,_Exp},TotalExp) ->
	TotalExp;
get_max_skillexp_can_receive({ID,SKillID,Exp},TotalExp) ->
	SkillInfo = data_skill:skill_info(SKillID),
	ExpAdd = SkillInfo#skill_info.level_up_exp - Exp,
	get_max_skillexp_can_receive({ID,SkillInfo#skill_info.next_skill_id,0},TotalExp+ExpAdd).