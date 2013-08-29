%% 符录系统

-module (mod_fulu).
-include("mgeer.hrl").

-export ([init_fulu/2, delete_fulu/1, handle/1, recalc/2, hook_fight/3, send_fulu_to_client/1]).

-define (FULU_STATUS_NOT_ACTIVATE, 	0).  %% 未激活
-define (FULU_STATUS_ACTIVATED, 	1).  %% 已激活

-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?SKILL, Method, Msg)).

-record(fulu_conf, {
	id    = 0,	%% 符录id
	type  = none,%%符录效果类型
	value = none %% 符录效果具体数据
	}).


init_fulu(RoleID, FuluRec) ->
	case FuluRec of 
		false -> ignore;
		_ 	  -> set_fulu_rec(RoleID, FuluRec)
	end.

delete_fulu(RoleID) ->
	mod_role_tab:erase(RoleID, r_fulu).

set_fulu_rec(RoleID, FuluRec) ->
	mod_role_tab:put(RoleID, r_fulu, FuluRec).	

get_fulu_rec(RoleID) ->
	FuluRec1 = case mod_role_tab:get(RoleID, r_fulu) of
		undefined -> 
			FuluRec = #r_fulu{},
			set_fulu_rec(RoleID, FuluRec),
			FuluRec;
		FuluRec   -> FuluRec
	end,
	FuluRec1.

set_fulu_rec(RoleID, FuluRec, NewFuluDetailRec) ->
	NewFuluList = lists:keystore(NewFuluDetailRec#fulu_detail.id, #fulu_detail.id, FuluRec#r_fulu.fulu_list, NewFuluDetailRec),
	NewFulu = FuluRec#r_fulu{fulu_list = NewFuluList},
	set_fulu_rec(RoleID, NewFulu).

get_fulu_detail_rec(RoleID, FuluId) when is_integer(RoleID) ->
	FuluRec       = get_fulu_rec(RoleID),
	get_fulu_detail_rec(FuluRec, FuluId);
get_fulu_detail_rec(FuluRec, FuluId) ->
	case lists:keyfind(FuluId, #fulu_detail.id, FuluRec#r_fulu.fulu_list) of
		false -> 
			#fulu_detail{
				id        = FuluId, 
				status    = ?FULU_STATUS_NOT_ACTIVATE, 
				cur_level = cfg_fulu:default_level(),
				max_level = cfg_fulu:default_max_level()};
		FuluDetailRec -> FuluDetailRec
	end.

handle({_, ?SKILL_FULU_OP, DataIn, RoleID}) ->
	case DataIn#m_skill_fulu_op_tos.option of
		1 ->
			activate_fulu(RoleID, DataIn#m_skill_fulu_op_tos.id);
		2 -> 
			upgrade_fulu(RoleID, DataIn#m_skill_fulu_op_tos.id);
		3 ->
			add_fulu_max_level(RoleID, DataIn#m_skill_fulu_op_tos.id)
	end;

handle({?SKILL, ?SKILL_FULU_INFO, _DataIn, RoleID}) ->
	send_fulu_to_client(RoleID).

send_fulu_to_client(RoleID) ->
	{ok, #p_role_attr{category= Category}} = mod_map_role:get_role_attr(RoleID),
	FuluRec = get_fulu_rec(RoleID),
	Fun = fun(FuluDetailRec) ->
		#p_role_fulu{
			id        = FuluDetailRec#fulu_detail.id,
			status    = FuluDetailRec#fulu_detail.status,
			cur_level = FuluDetailRec#fulu_detail.cur_level,
			max_level = FuluDetailRec#fulu_detail.max_level,
			skill_id  = cfg_fulu:fulu_to_skill(Category, FuluDetailRec#fulu_detail.id)
		}
	end,
	Msg = #m_skill_fulu_info_toc{
		list = [Fun(R) || R <- FuluRec#r_fulu.fulu_list]
	},
	?MOD_UNICAST(RoleID, ?SKILL_FULU_INFO, Msg).
	

activate_fulu(RoleID, FuluId) ->
	FuluRec       = get_fulu_rec(RoleID),
	FuluDetailRec = get_fulu_detail_rec(FuluRec, FuluId),
	{OpenLv, CostSilver, CostItem, CostItemNum} = cfg_fulu:activate_require(FuluId),
	IsMoneyEnough = common_bag2:check_money_enough(silver_any, CostSilver, RoleID),
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
	Ret = if
		RoleAttr#p_role_attr.level < OpenLv ->
			{error, <<"您的等级不足，暂时无法激活">>};
	 	FuluDetailRec#fulu_detail.status == ?FULU_STATUS_ACTIVATED -> 
	 		{error, <<"已激活，无需再次激活">>};
	 	IsMoneyEnough == false -> 
	 		{error, ?_LANG_NOT_ENOUGH_SILVER};
	 	true -> true
	end,
	case Ret of
		{error, Reason} -> common_misc:send_common_error(RoleID, 0, Reason);
		true ->
			case mod_bag:use_item(RoleID, CostItem, CostItemNum, ?LOG_ITEM_TYPE_LOST_UPGRADE_FULU) of
				{error, _} ->
					common_misc:send_common_error(RoleID, 0, <<"材料不足">>);
				ok ->
					true=common_bag2:use_money(RoleID, silver_any, CostSilver, ?CONSUME_TYPE_SILVER_UPGRAGE_FULU),
					NewFuluDetailRec = FuluDetailRec#fulu_detail{status = ?FULU_STATUS_ACTIVATED},
					set_fulu_rec(RoleID, FuluRec, NewFuluDetailRec),
					send_fulu_to_client(RoleID),
					hook_fulu_lv_up(RoleID, FuluId, 0, NewFuluDetailRec#fulu_detail.cur_level)
			end
	end.

upgrade_fulu(RoleID, FuluId) ->
	FuluRec       = get_fulu_rec(RoleID),
	FuluDetailRec = get_fulu_detail_rec(FuluRec, FuluId),
	{CostSilver, CostItem, CostItemNum} = cfg_fulu:upgrade_require(FuluId, FuluDetailRec#fulu_detail.cur_level),
	IsMoneyEnough = common_bag2:check_money_enough(silver_any, CostSilver, RoleID),
	MaxLevel      = cfg_fulu:max_level(),
	Ret = if
	 	FuluDetailRec#fulu_detail.status =/= ?FULU_STATUS_ACTIVATED -> 
	 		{error, <<"该符录还没有激活">>};
	 	FuluDetailRec#fulu_detail.cur_level >= MaxLevel ->
	 		{error, <<"符录等级已满">>};
	 	FuluDetailRec#fulu_detail.cur_level >= FuluDetailRec#fulu_detail.max_level ->
	 		{error, <<"已达上限了，请提升符录等级上限">>};
	 	IsMoneyEnough == false -> 
	 		{error, ?_LANG_NOT_ENOUGH_SILVER};
	 	true -> true
	end,
	case Ret of
		{error, Reason} -> common_misc:send_common_error(RoleID, 0, Reason);
		true ->
			{ok, Num} = mod_bag:get_goods_num_by_typeid([1,2,3], RoleID, CostItem),
			case Num >= CostItemNum of
				false ->
			% case mod_bag:use_item(RoleID, CostItem, CostItemNum, ?LOG_ITEM_TYPE_LOST_UPGRADE_FULU) of
				% {error, _} ->
					common_misc:send_common_error(RoleID, 0, <<"材料不足">>);
				true ->
					ok=mod_bag:use_item(RoleID, CostItem, CostItemNum, ?LOG_ITEM_TYPE_LOST_UPGRADE_FULU),
					true=common_bag2:use_money(RoleID, silver_any, CostSilver, ?CONSUME_TYPE_SILVER_UPGRAGE_FULU),
					NewLevel = FuluDetailRec#fulu_detail.cur_level + 1,
					NewFuluDetailRec = FuluDetailRec#fulu_detail{cur_level = NewLevel},
					set_fulu_rec(RoleID, FuluRec, NewFuluDetailRec),
					send_fulu_to_client(RoleID),
					hook_fulu_lv_up(RoleID, FuluId, FuluDetailRec#fulu_detail.cur_level, NewFuluDetailRec#fulu_detail.cur_level)
			end
	end.

add_fulu_max_level(RoleID, FuluId) ->
	FuluRec       = get_fulu_rec(RoleID),
	FuluDetailRec = get_fulu_detail_rec(FuluRec, FuluId),
	MaxLevel      = cfg_fulu:max_level(),
	UsedItem      = cfg_fulu:up_max_level_item(FuluDetailRec#fulu_detail.max_level),
	Ret = if
	 	FuluDetailRec#fulu_detail.status =/= ?FULU_STATUS_ACTIVATED -> 
	 		{error, <<"该符录还没有激活">>};
	 	FuluDetailRec#fulu_detail.cur_level >= MaxLevel ->
	 		{error, <<"符录等级已满">>};
	 	true -> true
	end,
	case Ret of
		{error, Reason} -> common_misc:send_common_error(RoleID, 0, Reason);
		true ->
			case mod_bag:use_item(RoleID, UsedItem, 1, ?LOG_ITEM_TYPE_LOST_UPGRADE_FULU) of
				{error, _} ->
					common_misc:send_common_error(RoleID, 0, <<"材料不足">>);
				ok ->
					NewLevel1 = FuluDetailRec#fulu_detail.max_level + cfg_fulu:add_max_level(UsedItem),
					NewLevel2 = erlang:min(NewLevel1, cfg_fulu:max_level()),
					NewFuluDetailRec = FuluDetailRec#fulu_detail{max_level = NewLevel2},
					set_fulu_rec(RoleID, FuluRec, NewFuluDetailRec),
					send_fulu_to_client(RoleID)
			end
	end.


hook_fulu_lv_up(_RoleID, _FuluId, _OldLv, NewLv) when NewLv =< 0 -> ignore;
hook_fulu_lv_up(RoleID, FuluId, OldLv, NewLv) ->
	FuluConfRec   = cfg_fulu:fulu_conf(FuluId, NewLv),
	case FuluConfRec#fulu_conf.type of
		add_effect ->
			{ok, #p_role_attr{category= Category}} = mod_map_role:get_role_attr(RoleID),
			SkillID = cfg_fulu:fulu_to_skill(Category, FuluId),
			mod_skill_ext:store(RoleID, SkillID, [{{add_effect, fulu}, FuluConfRec#fulu_conf.value}]);
		add_effect_buf ->
			{ok, #p_role_attr{category= Category}} = mod_map_role:get_role_attr(RoleID),
			SkillID = cfg_fulu:fulu_to_skill(Category, FuluId),
			mod_skill_ext:store(RoleID, SkillID, [{{add_buff, fulu}, FuluConfRec#fulu_conf.value}]);
		add_attr ->
			{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
			case OldLv =< 0 of
				true -> 
					NewRoleBase    = mod_role_attr:calc(RoleBase, '+', FuluConfRec#fulu_conf.value);
				false ->
					OldFuluConfRec = cfg_fulu:fulu_conf(FuluId, OldLv),
					NewRoleBase    = mod_role_attr:calc(RoleBase, '-', OldFuluConfRec#fulu_conf.value, '+', FuluConfRec#fulu_conf.value)
			end,
			mod_role_attr:reload_role_base(NewRoleBase);
		_ -> ignore
	end.
%% ================================================================================
%% ================================================================================
hook_fight(CasterAttr, TargetAttr, SkillId) ->
	FuluIdList = cfg_fulu:skill_to_fulu(SkillId),
	[hook_fight2(CasterAttr, TargetAttr, SkillId, FuluId) || FuluId <- FuluIdList].

hook_fight2(CasterAttr, _TargetAttr, _SkillId, FuluId) ->
	RoleID = CasterAttr#actor_fight_attr.actor_id,
	FuluDetailRec = get_fulu_detail_rec(RoleID, FuluId),
	FuluConfRec   = cfg_fulu:fulu_conf(FuluId, FuluDetailRec#fulu_detail.cur_level),
	case FuluConfRec#fulu_conf.type of
		add_nuqi ->
			{Rate, AddNuqi} = FuluConfRec#fulu_conf.value,
			case common_tool:random(1, 100) =< Rate of
				true ->
					mgeem_map:run(fun() -> mod_map_role:add_nuqi(RoleID, AddNuqi) end);
				false ->
					ignore
			end;
		_ ->
			ignore
	end.
	

%% ================================================================================
%% ================================================================================
recalc(RoleBase = #p_role_base{role_id = RoleID}, _RoleAttr) ->
	FuluRec = get_fulu_rec(RoleID),
	Fun = fun(FuluDetailRec, Acc) ->
		FuluConfRec = cfg_fulu:fulu_conf(FuluDetailRec#fulu_detail.id, FuluDetailRec#fulu_detail.cur_level),
		case FuluConfRec#fulu_conf.type of
			add_attr ->
				FuluConfRec#fulu_conf.value ++ Acc;
			_ -> Acc
		end
	end,
	AddAttrList = lists:foldl(Fun, [], FuluRec#r_fulu.fulu_list), 
	RoleBase2 = mod_role_attr:calc(RoleBase, '+', AddAttrList),
	RoleBase2.