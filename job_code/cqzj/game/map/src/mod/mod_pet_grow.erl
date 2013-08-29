%% Author: liuwei
%% Created: 2011-3-23
%% Description:  异兽异兽对练
-module(mod_pet_grow).

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([
		clear_role_pet_grow_info/1,
		init_map_role_pet_grow_info/2,
		get_role_pet_grow_info/1,
		do_pet_grow_info/5,
		do_pet_grow_begin/5,
		do_pet_grow_commit/5,
		do_pet_grow_give_up/5,
		do_pet_grow_auto/5,
		change_grow_level/2,
		hook_role_online/1,
		recalc/2
]).

-define(ROLE_PET_GROW_INFO,role_pet_grow_info).

-define(GROW_TYPE_PHY_ATTACK,1).    
-define(GROW_TYPE_MAGIC_ATTACK,2).         
-define(GROW_TYPE_PHY_DEFENCE,3).     
-define(GROW_TYPE_MAGIC_DEFENCE,4).  
-define(GROW_TYPE_CON,5).

-define(MAX_GROW_LEVEL,60).

-define(MIN_PET_GROW_BROADCAST_LEVEL, 16).

-define(PET_GROW_GAP_TIME , 30). %% 每多少秒涨一元宝

-record(r_pet_grow,{key,need_pet_level,need_silver,need_tick,add_value}). 

%%Error Code
-define(ERR_PET_GROW_AUTO_SILVER_NOT_ENOUGH, 100). %% 钱币不足，一键异兽对练中止
-define(ERR_PET_GROW_AUTO_GOLD_NOT_ENOUGH, 101). %% 元宝不足，一键异兽对练中止
-define(ERR_PET_GROW_AUTO_MAX_LEVEL, 102). %% 已达最高训练等级

%%
%% API Functions
%%
clear_role_pet_grow_info(RoleID) ->
    mod_role_tab:erase({?ROLE_PET_GROW_INFO,RoleID}).

get_role_pet_grow_info(RoleID) ->
	case mod_role_tab:get({?ROLE_PET_GROW_INFO,RoleID}) of
		undefined ->
			{undefined,undefined};
		GrowInfo ->
			case GrowInfo#p_role_pet_grow.state =:= ?PET_GROW_STATE of
				true ->
					{GrowInfo,GrowInfo#p_role_pet_grow.grow_over_tick};
				false ->
					{GrowInfo,undefined}
			end
	end.

init_map_role_pet_grow_info(RoleID,{GrowInfo,OverTick}) ->
	case OverTick of
		undefined ->
			mod_role_tab:put({?ROLE_PET_GROW_INFO,RoleID},GrowInfo);
		_ ->
			Now = common_tool:now(),
			case OverTick =< Now of
				true ->
					NewGrowInfo = get_update_grow_info(GrowInfo),
					mod_role_tab:put({?ROLE_PET_GROW_INFO,RoleID},NewGrowInfo),
					mgeem_persistent:pet_grow_persistent(NewGrowInfo);
				false ->
					mod_role_tab:put({?ROLE_PET_GROW_INFO,RoleID},GrowInfo)
			end
	end.

do_pet_grow_info(Unique, Module, Method, RoleID, PID) ->
	case mod_role_tab:get({?ROLE_PET_GROW_INFO,RoleID}) of
		undefined ->
			?UNICAST_TOC(#m_pet_grow_info_toc{succ=false,reason=?_LANG_SYSTEM_ERROR});
		GrowInfo ->
			{Configs,GrowInfo2} = get_grow_config_infos_to_client(GrowInfo),
			Record = #m_pet_grow_info_toc{succ=true,grow_info=GrowInfo2,info_configs=Configs},
			?UNICAST_TOC(Record)
	end.

do_pet_grow_begin(Unique, DataIn, RoleID, Line, _State) ->
	#m_pet_grow_begin_tos{grow_type=GrowType} = DataIn,
	case mod_role_tab:get({?ROLE_PET_GROW_INFO,RoleID}) of
		undefined ->
			do_pet_grow_begin_error(Unique, RoleID, Line, ?_LANG_SYSTEM_ERROR);
		GrowInfo ->
			case GrowInfo#p_role_pet_grow.state =:= ?PET_GROW_STATE of
				true ->
					do_pet_grow_begin_error(Unique, RoleID, Line, ?_LANG_PET_GROW_NOT_OVER);
				false ->
					case check_grow_level_full(GrowInfo,GrowType) of
						{true,_} ->
							hook_map_pet:on_grow_update(RoleID, ?MAX_GROW_LEVEL, 0, is_all_grow_level_full(GrowInfo)),
							do_pet_grow_begin_error(Unique, RoleID, Line, ?_LANG_PET_GROW_LEVEL_FULL);
						{false,GrowLevel} ->
							case check_grow_pre_skill_level(GrowInfo,GrowType) of
								true ->
									grow_begin(GrowType,GrowInfo,GrowLevel,Unique, RoleID, Line);
								false -> 
									do_pet_grow_begin_error(Unique, RoleID, Line, ?_LANG_PET_GROW_PRE_SKILL_NOT_LEARN)
							end
					end
			end
	end.


grow_begin(GrowType,GrowInfo,GrowLevel,Unique, RoleID, Line) ->
	Config = get_config_info(GrowLevel,GrowType),
	{ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
	case RoleAttr#p_role_attr.silver + RoleAttr#p_role_attr.silver_bind >= Config#p_grow_info.need_silver of
		false ->
			do_pet_grow_begin_error(Unique, RoleID, Line, ?_LANG_PET_GROW_SILVER_NOT_ENOUGH);
		true ->
			grow_begin_2(GrowType,GrowInfo,GrowLevel,Config,Unique,RoleID,Line)
	end.

grow_begin_2(GrowType,GrowInfo,_GrowLevel,Config,Unique,RoleID,Line)->
	Now = common_tool:now(),
	NeedTick = Config#p_grow_info.need_tick,
	NewGrowInfo = GrowInfo#p_role_pet_grow{state=?PET_GROW_STATE,
										   grow_type=GrowType,
										   grow_over_tick=Now + NeedTick,
										   grow_tick=NeedTick},
	Fun = fun() ->
				  {ok,NewRoleAttr} = t_deduct_money(silver_any,Config#p_grow_info.need_silver,RoleID,?CONSUME_TYPE_SILVER_PET_GROW,?_LANG_PET_GROW_SILVER_NOT_ENOUGH),
				  mod_role_tab:put({?ROLE_PET_GROW_INFO,RoleID},NewGrowInfo),
				  {ok,NewRoleAttr,NewGrowInfo}
		  end,
	case common_transaction:t(Fun) of
		{aborted,Reason} ->
			do_pet_grow_begin_error(Unique, RoleID, Line, Reason);
		{atomic, {ok,NewRoleAttr,NewGrowInfo2}} ->
			PetGrowTimer = erlang:start_timer(NeedTick*1000, self(), {pet_grow_timeout, NewGrowInfo2}),
			put(pet_grow_timer, PetGrowTimer),
			mgeem_persistent:pet_grow_persistent(NewGrowInfo2),
			ChangeList = [
							 #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value=NewRoleAttr#p_role_attr.silver},
							 #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.silver_bind}],
			common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
			
			{Configs,NewGrowInfo3} = get_grow_config_infos_to_client(NewGrowInfo2),
			Record = #m_pet_grow_begin_toc{succ=true,grow_info=NewGrowInfo3,info_configs=Configs},
			common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_GROW_BEGIN, Record)
	end.

do_pet_grow_begin_error(Unique, RoleID, Line, Reason) ->
	Record = #m_pet_grow_begin_toc{succ=false, reason=Reason},
	common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_GROW_BEGIN, Record).

do_pet_grow_commit(Unique, _DataIn, RoleID, Line, _State) ->
	case mod_role_tab:get({?ROLE_PET_GROW_INFO,RoleID}) of
		undefined ->
			do_pet_grow_commit_error(Unique, RoleID, Line, ?_LANG_SYSTEM_ERROR);
		GrowInfo ->
			case GrowInfo#p_role_pet_grow.state =:= ?PET_GROW_STATE of
				false ->
					do_pet_grow_begin_error(Unique, RoleID, Line, ?_LANG_PET_GROW_NOT_START);
				true ->
					OverTick = GrowInfo#p_role_pet_grow.grow_over_tick,
					Now =common_tool:now(),
					case Now >= OverTick of
						true ->
							NeedGold = 0;
						false ->
							NeedGold = common_tool:ceil((OverTick - Now)/ ?PET_GROW_GAP_TIME)
					end,
					grow_commit(RoleID,GrowInfo,NeedGold,Unique,Line)
			end
	end.

t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeLogType,_Reason) ->
	case common_bag2:t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeLogType) of
		{ok,RoleAttr2}->
			{ok,RoleAttr2};
		{error,Reason1} ->
			common_transaction:abort(Reason1)
	end. 

grow_commit(RoleID,GrowInfo,NeedGold,Unique,Line) ->
	Fun = fun() ->
				  NewGrowInfo = get_update_grow_info(GrowInfo),
				  common_bag2:check_money_enough_and_throw(gold_any,NeedGold,RoleID),
				  mod_role_tab:put({?ROLE_PET_GROW_INFO,RoleID},NewGrowInfo),
				  {ok,NewRoleAttr} = t_deduct_money(gold_any,NeedGold,RoleID,?CONSUME_TYPE_GOLD_PET_GROW_SPEED_UP,?_LANG_PET_GROW_GOLD_NOT_ENOUGH),
				  {ok,NewRoleAttr,NewGrowInfo}
		  end,
	case common_transaction:t(Fun) of
		{aborted, {error, ErrorCode, ErrorStr}} ->
			common_misc:send_common_error(RoleID, ErrorCode, ErrorStr);
		{aborted,Reason} ->
			do_pet_grow_commit_error(Unique, RoleID, Line, Reason);
		{atomic, {ok,NewRoleAttr2,NewGrowInfo2}} ->
			PetGrowTimer = erase(pet_grow_timer),
			is_reference(PetGrowTimer) andalso erlang:cancel_timer(PetGrowTimer),
			mgeem_persistent:pet_grow_persistent(NewGrowInfo2),
			common_misc:send_role_gold_change(RoleID, NewRoleAttr2),
			{Configs,NewGrowInfo3} = get_grow_config_infos_to_client(NewGrowInfo2),
			Record = #m_pet_grow_commit_toc{succ=true, use_gold=NeedGold, grow_info=NewGrowInfo3,info_configs=Configs},
			common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_GROW_COMMIT, Record),
			{GrowStr,Level} = get_grow_type_str_and_level(GrowInfo),
			hook_map_pet:on_grow_update(RoleID, Level, 0, is_all_grow_level_full(NewGrowInfo2)),
			case NeedGold > 5 andalso Level >= ?MIN_PET_GROW_BROADCAST_LEVEL of
				true -> 
					#p_role_attr{role_name=RoleName} = NewRoleAttr2, 
					Content = common_misc:format_lang(?_LANG_PET_GROW_BROADCAST,[RoleName,GrowStr,Level]),
					catch common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER],?BC_MSG_TYPE_CHAT_WORLD,Content);
				false ->
					ignore
			end,
			mod_role_event:notify(RoleID, {?ROLE_EVENT_PET_GROW, NewGrowInfo2}),             
			update_role_base(RoleID, GrowInfo, NewGrowInfo2)
	end.

do_pet_grow_commit_error(Unique, RoleID, Line, Reason) ->
	Record = #m_pet_grow_commit_toc{succ=false, reason=Reason},
	common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_GROW_COMMIT, Record).


do_pet_grow_give_up(Unique, _DataIn, RoleID, Line, _State) ->
	case mod_role_tab:get({?ROLE_PET_GROW_INFO,RoleID}) of
		undefined ->
			do_pet_grow_give_up_error(Unique, RoleID, Line, ?_LANG_SYSTEM_ERROR);
		GrowInfo ->
			case GrowInfo#p_role_pet_grow.state =:= ?PET_GROW_STATE of
				false ->
					do_pet_grow_begin_error(Unique, RoleID, Line, ?_LANG_SYSTEM_ERROR);
				true ->
					NewGrowInfo = GrowInfo#p_role_pet_grow{state=?PET_NORMAL_STATE},
					mod_role_tab:put({?ROLE_PET_GROW_INFO,RoleID},NewGrowInfo),
					mgeem_persistent:pet_grow_persistent(NewGrowInfo),
					{Configs,NewGrowInfo2} = get_grow_config_infos_to_client(NewGrowInfo),
					Record = #m_pet_grow_give_up_toc{succ=true,grow_info=NewGrowInfo2,info_configs=Configs},
					common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_GROW_GIVE_UP, Record)
			end
	end.

do_pet_grow_give_up_error(Unique, RoleID, Line, Reason) ->
	Record = #m_pet_grow_give_up_toc{succ=false, reason=Reason},
	common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_GROW_GIVE_UP, Record).

%% 一键异兽对练
do_pet_grow_auto(Unique, _DataIn, RoleID, Line, _State) ->
	case catch check_pet_grow_auto(RoleID) of
		{error, ErrCode, Reason} ->
			do_pet_grow_auto_error(Unique, RoleID, Line, ErrCode, Reason);
		{ok, GrowInfo, GoldUsed} ->
			do_pet_grow_auto_2(Unique, RoleID, Line, GrowInfo, GoldUsed)
	end.

check_pet_grow_auto(RoleID) ->
	case mod_role_tab:get({?ROLE_PET_GROW_INFO,RoleID}) of
		undefined ->
			?THROW_SYS_ERR();
		GrowInfo ->
			case is_all_grow_level_full(GrowInfo) of
				true ->
					hook_map_pet:on_grow_update(RoleID, ?MAX_GROW_LEVEL, 0, true),
					?THROW_ERR(?ERR_PET_GROW_AUTO_MAX_LEVEL);
				_ ->
					{NewGrowInfo, GoldUsed} = calc_finish_current_pet_grow(RoleID, GrowInfo),
					{ok, NewGrowInfo, GoldUsed}
			end
	end.

calc_finish_current_pet_grow(RoleID, GrowInfo) ->
	RoleAttr = 
		case mod_map_role:get_role_attr(RoleID) of
			{ok, RoleAttrT} ->
				RoleAttrT;
			_ ->
				?THROW_SYS_ERR()
		end,
	case GrowInfo#p_role_pet_grow.state =:= ?PET_GROW_STATE of
		true ->
			%% 先计算完成当前正在倒数的训练
			OverTick = GrowInfo#p_role_pet_grow.grow_over_tick,
			Now =common_tool:now(),
			case Now >= OverTick of
				true ->
					NeedGold = 0;
				false ->
					NeedGold = max(common_tool:ceil((OverTick - Now)/ ?PET_GROW_GAP_TIME) div 2, 2)
			end,
			#p_role_attr{gold=Gold, gold_bind=_GoldBind} = RoleAttr,
			if Gold >= NeedGold ->
				   {get_update_grow_info(GrowInfo), NeedGold};
			   true ->
				   ?THROW_ERR(?ERR_PET_GROW_AUTO_GOLD_NOT_ENOUGH)
			end;
		false ->
			{GrowInfo, 0}
	end.

do_pet_grow_auto_2(Unique, RoleID, Line, GrowInfo, GoldUsed) ->
	{ok, #p_role_attr{gold=Gold,gold_bind=GoldBind,silver=Silver, silver_bind=SilverBind} = RoleAttr} = mod_map_role:get_role_attr(RoleID),
	% {Gold2, GoldBind2} = mod_role2:calc_rest_money(Gold, GoldBind, GoldUsed),
	Gold2 = Gold - GoldUsed,
	GoldBind2 = GoldBind,
	% RoleAttr2 = RoleAttr#p_role_attr{gold=Gold2, gold_bind=GoldBind2},
	{Status, NewGrowInfo, {GoldLeft, _GoldBindLeft, SilverLeft, SilverBindLeft}} = calc_pet_grow_auto(GrowInfo, {Gold2, GoldBind2, Silver, SilverBind}, 0),
	UseSilver = Silver + SilverBind - SilverLeft - SilverBindLeft,
	% UseGold   = GoldBind - GoldBindLeft,
	UseGold   = Gold - GoldLeft,
	case common_transaction:t(
		   fun() ->
				   case Status of
					    over_max_loop_time ->
						   common_transaction:abort(over_max_loop_time);
					    _ ->
						   ok
				   end,
				   % {ok, _} = common_bag2:t_deduct_money(silver_any, UseSilver, RoleID, ?CONSUME_TYPE_SILVER_PET_GROW_AUTO),
				   {ok, NewRoleAttr} = common_bag2:t_deduct_money(gold_unbind, UseGold, RoleID, ?CONSUME_TYPE_GOLD_PET_GROW_AUTO),
				   mod_role_tab:put({?ROLE_PET_GROW_INFO,RoleID},NewGrowInfo),
				   {ok, NewGrowInfo, NewRoleAttr}
		   end
					   ) of
		{aborted, {error, ErrCode, Reason}} ->
			do_pet_grow_auto_error(Unique, RoleID, Line, ErrCode, Reason);
		{aborted,Reason} ->
			?ERROR_MSG("~ts,Reason=~w",["一键完成异兽对练系统错误",Reason]),
			do_pet_grow_auto_error(Unique, RoleID, Line, ?ERR_SYS_ERR, undefined);
		{atomic, {ok,NewGrowInfo, NewRoleAttr}} ->
			PetGrowTimer = erase(pet_grow_timer),
			is_reference(PetGrowTimer) andalso erlang:cancel_timer(PetGrowTimer),
			mgeem_persistent:pet_grow_persistent(NewGrowInfo),
			ChangeList = [
							 #p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value=NewRoleAttr#p_role_attr.gold},
							 #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.gold_bind},
							 #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value=NewRoleAttr#p_role_attr.silver},
							 #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value=NewRoleAttr#p_role_attr.silver_bind}],
			common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
			ErrCode = 
				case Status of
					not_enough_silver ->
						?ERR_PET_GROW_AUTO_SILVER_NOT_ENOUGH;
					not_enough_gold ->
						?ERR_PET_GROW_AUTO_GOLD_NOT_ENOUGH;
					ok ->
						?ERR_OK
				end,
			% UseGold = (RoleAttr#p_role_attr.gold + RoleAttr#p_role_attr.gold_bind) -
			% 			  (NewRoleAttr#p_role_attr.gold + NewRoleAttr#p_role_attr.gold_bind),     
			% UseSilver = (RoleAttr#p_role_attr.silver + RoleAttr#p_role_attr.silver_bind) -
			% 				(NewRoleAttr#p_role_attr.silver + NewRoleAttr#p_role_attr.silver_bind),
			{Configs,NewGrowInfo3} = get_grow_config_infos_to_client(NewGrowInfo),
			Record = #m_pet_grow_auto_toc{err_code=ErrCode,use_gold=UseGold, use_silver=UseSilver, grow_info=NewGrowInfo3,info_configs=Configs},
			common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_GROW_AUTO, Record),
			
			%% 暂时不处理
			Level = get_grow_max_level(NewGrowInfo),
			hook_map_pet:on_grow_update(RoleID, Level, 0, is_all_grow_level_full(NewGrowInfo)),
			
			case Status of
				ok -> 
					#p_role_attr{role_name=RoleName} = RoleAttr, 
					Content = common_misc:format_lang(?_LANG_PET_GROW_AUTO_BROADCAST,[RoleName]),
					catch common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER],?BC_MSG_TYPE_CHAT_WORLD,Content);
				_ ->
					ignore
			end,
			mod_role_event:notify(RoleID, {?ROLE_EVENT_PET_GROW, NewGrowInfo}),
			update_role_base(RoleID, GrowInfo, NewGrowInfo)      
	end.

calc_pet_grow_auto(GrowInfo, {GoldLefe, GoldBindLeft, SilverLeft, SilverBindLeft}, LoopTime) ->
	{Type, Level} = get_next_grow_type_and_level(GrowInfo),
	#p_grow_info{need_tick=NeedTick} = get_config_info(Level, Type),
	NeedSilver = 0,
	NeedGold = max(common_tool:ceil(NeedTick / ?PET_GROW_GAP_TIME) div 2, 2),
	case {SilverLeft + SilverBindLeft >= NeedSilver, GoldLefe >= NeedGold} of
		{false, _} ->
			{not_enough_silver, GrowInfo, {GoldLefe, GoldBindLeft, SilverLeft, SilverBindLeft}};
		{true, false} ->
			{not_enough_gold, GrowInfo, {GoldLefe, GoldBindLeft, SilverLeft, SilverBindLeft}};
		{true, true} ->
			NewGrowInfo = get_update_grow_info(GrowInfo#p_role_pet_grow{grow_type=Type}),
			{Silver2, SilverBind2} = mod_role2:calc_rest_money(SilverLeft, SilverBindLeft, NeedSilver),
			% {Gold2, GoldBind2} = mod_role2:calc_rest_money(GoldLefe, GoldBindLeft, NeedGold),
			Gold2 = GoldLefe - NeedGold,
			GoldBind2 = GoldBindLeft,
			% NewRoleAttr = RoleAttr#p_role_attr{silver=Silver2, silver_bind=SilverBind2, gold=Gold2, gold_bind=GoldBind2},
			case {is_all_grow_level_full(NewGrowInfo), LoopTime > ?MAX_GROW_LEVEL * 5} of %% 防止无限循环
				{true, false} ->
					{ok, NewGrowInfo, {Gold2, GoldBind2, Silver2, SilverBind2}};
				{_, true} ->
					{over_max_loop_time, undefined, undefined};
				{false, false} ->
					calc_pet_grow_auto(NewGrowInfo, {Gold2, GoldBind2, Silver2, SilverBind2}, LoopTime + 1)
			end
	end.

is_all_grow_level_full(GrowInfo) ->
	#p_role_pet_grow{con_level=ConLv,magic_attack_level=MagAtt, magic_defence_level=MagDef,
					 phy_attack_level=PhyAtt,phy_defence_level=PhyDef} = GrowInfo,
	
	ConLv >= ?MAX_GROW_LEVEL andalso MagAtt >= ?MAX_GROW_LEVEL andalso MagDef >= ?MAX_GROW_LEVEL
		andalso PhyAtt >= ?MAX_GROW_LEVEL andalso PhyDef >= ?MAX_GROW_LEVEL.

get_next_grow_type_and_level(GrowInfo) ->
	#p_role_pet_grow{con_level=ConLv, magic_defence_level=MagicDefLv, phy_defence_level=PhyDefLv, 
					 magic_attack_level=MagicAttLv, phy_attack_level=PhyAttLv} = GrowInfo,
	lists:foldl(
	  fun({Type, Level}, {AccType, AccLevel}) ->
			  if Level < AccLevel orelse AccLevel =:= -1 ->
					 {Type, Level};
				 true ->
					 {AccType, AccLevel}
			  end
	  end, {0,-1}, [{?GROW_TYPE_CON,ConLv}, {?GROW_TYPE_MAGIC_DEFENCE, MagicDefLv}, 
					{?GROW_TYPE_PHY_DEFENCE,PhyDefLv}, {?GROW_TYPE_MAGIC_ATTACK,MagicAttLv}, {?GROW_TYPE_PHY_ATTACK,PhyAttLv}]).

do_pet_grow_auto_error(Unique, RoleID, Line, ErrorCode, Reason) ->
	Record = #m_pet_grow_auto_toc{err_code=ErrorCode, reason=Reason},
	common_misc:unicast(Line, RoleID, Unique, ?PET, ?PET_GROW_AUTO, Record).

%%      
%%LOCAL FUNCTIONS
%%
get_grow_add_value(0,_Type) ->
	[#r_pet_grow{add_value=0}];
get_grow_add_value(Level,Type) ->
	common_config_dyn:find(pet_grow,{Level,Type}).


get_grow_config_infos_to_client(GrowInfo) ->
	case GrowInfo#p_role_pet_grow.state =:= ?PET_GROW_STATE of
		true ->
			Now=common_tool:now(),
			OverTick = GrowInfo#p_role_pet_grow.grow_over_tick,
			case Now >= OverTick of
				true ->
					GrowInfo2=GrowInfo#p_role_pet_grow{grow_over_tick=0};
				false ->
					GrowInfo2 = GrowInfo#p_role_pet_grow{grow_over_tick=OverTick-Now}
			end;
		false ->
			GrowInfo2=GrowInfo
	end,
	ConInfo = get_config_info(GrowInfo#p_role_pet_grow.con_level,?GROW_TYPE_CON),
	ConInfo2 = get_config_info(GrowInfo#p_role_pet_grow.phy_defence_level,?GROW_TYPE_PHY_DEFENCE),
	ConInfo3 = get_config_info(GrowInfo#p_role_pet_grow.magic_defence_level,?GROW_TYPE_MAGIC_DEFENCE),
	ConInfo4 = get_config_info(GrowInfo#p_role_pet_grow.phy_attack_level,?GROW_TYPE_PHY_ATTACK),
	ConInfo5 = get_config_info(GrowInfo#p_role_pet_grow.magic_attack_level,?GROW_TYPE_MAGIC_ATTACK),
	{[get_config_add_value(GrowInfo,ConfigInfo)||ConfigInfo<-[ConInfo,ConInfo2,ConInfo3,ConInfo4,ConInfo5]],GrowInfo2}.

get_config_add_value(GrowInfo,#p_grow_info{type=?GROW_TYPE_PHY_ATTACK}=ConfigInfo)->
	get_config_add_value1(GrowInfo#p_role_pet_grow.phy_attack_level,ConfigInfo);
get_config_add_value(GrowInfo,#p_grow_info{type=?GROW_TYPE_MAGIC_ATTACK}=ConfigInfo)->
	get_config_add_value1(GrowInfo#p_role_pet_grow.magic_attack_level,ConfigInfo);
get_config_add_value(GrowInfo,#p_grow_info{type=?GROW_TYPE_PHY_DEFENCE}=ConfigInfo)->
	get_config_add_value1(GrowInfo#p_role_pet_grow.phy_defence_level,ConfigInfo);
get_config_add_value(GrowInfo,#p_grow_info{type=?GROW_TYPE_MAGIC_DEFENCE}=ConfigInfo)->
	get_config_add_value1(GrowInfo#p_role_pet_grow.magic_defence_level,ConfigInfo);
get_config_add_value(GrowInfo,#p_grow_info{type=?GROW_TYPE_CON}=ConfigInfo)->
	get_config_add_value1(GrowInfo#p_role_pet_grow.con_level,ConfigInfo).

get_config_add_value1(Level,#p_grow_info{type=Type}=ConfigInfo)->
	case common_config_dyn:find(pet_grow,{Level,Type}) of
		[]->
			ConfigInfo;
		[#r_pet_grow{add_value=AddValue}]->
			ConfigInfo#p_grow_info{cur_add_value=AddValue}
	end.

get_config_info(Level,Type)->
	case common_config_dyn:find(pet_grow,{Level+1,Type}) of
		[] ->
			#p_grow_info{type=Type,level=Level+1};
		[#r_pet_grow{need_pet_level=NeedLevel,need_silver=NeedSilver,
					 need_tick=NeedTick,add_value=AddVaule}] ->
			#p_grow_info{type=Type,level=Level+1,need_level=NeedLevel,need_silver=NeedSilver,need_tick=NeedTick,add_value=AddVaule}
	end.

check_grow_level_full(GrowInfo,GrowType) ->
	case GrowType of 
		?GROW_TYPE_CON ->
			Level = GrowInfo#p_role_pet_grow.con_level;
		?GROW_TYPE_PHY_DEFENCE ->
			Level = GrowInfo#p_role_pet_grow.phy_defence_level;
		?GROW_TYPE_MAGIC_DEFENCE ->
			Level = GrowInfo#p_role_pet_grow.magic_defence_level;
		?GROW_TYPE_PHY_ATTACK ->
			Level = GrowInfo#p_role_pet_grow.phy_attack_level;
		?GROW_TYPE_MAGIC_ATTACK ->
			Level = GrowInfo#p_role_pet_grow.magic_attack_level;
		_ ->
			Level = ?MAX_GROW_LEVEL
	end,
	{Level >= ?MAX_GROW_LEVEL, Level}.

change_grow_level(GrowInfo, TimerRef) ->
	case erase(pet_grow_timer) == TimerRef andalso 
			GrowInfo#p_role_pet_grow.state =:= ?PET_GROW_STATE of
		true ->
			NewGrowInfo = get_update_grow_info(GrowInfo),
			Level = get_grow_max_level(NewGrowInfo),
			
			RoleID = GrowInfo#p_role_pet_grow.role_id,
			hook_map_pet:on_grow_update(RoleID, Level, 0, is_all_grow_level_full(NewGrowInfo)),
			mod_role_tab:put({?ROLE_PET_GROW_INFO,RoleID},NewGrowInfo),
			mgeem_persistent:pet_grow_persistent(NewGrowInfo),
			{Configs,NewGrowInfo2} = get_grow_config_infos_to_client(NewGrowInfo),
			Record = #m_pet_grow_over_toc{grow_type=GrowInfo#p_role_pet_grow.grow_type,grow_info=NewGrowInfo2,info_configs=Configs},
			common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?PET, ?PET_GROW_OVER, Record),
			mod_role_event:notify(RoleID, {?ROLE_EVENT_PET_GROW, NewGrowInfo}),
			update_role_base(RoleID, GrowInfo, NewGrowInfo);
		_ ->
			ingore
	end.

hook_role_online(RoleID) ->
	case mod_role_tab:get({?ROLE_PET_GROW_INFO,RoleID}) of
		GrowInfo = #p_role_pet_grow{state=?PET_GROW_STATE, grow_over_tick = OverTick} ->
			NeedTick = OverTick - common_tool:now(),
			if
				NeedTick > 0 ->
					PetGrowTimer = erlang:start_timer(NeedTick*1000, self(), {pet_grow_timeout, GrowInfo}),
					put(pet_grow_timer, PetGrowTimer);
				true ->
					ignore
			end;
		_ ->
			ignore
	end.

%%@return Level
get_grow_max_level(NewGrowInfo)->
	lists:max([NewGrowInfo#p_role_pet_grow.con_level, NewGrowInfo#p_role_pet_grow.phy_defence_level,
			   NewGrowInfo#p_role_pet_grow.magic_defence_level, NewGrowInfo#p_role_pet_grow.phy_attack_level,
			   NewGrowInfo#p_role_pet_grow.magic_attack_level]).


get_update_grow_info(GrowInfo) ->
	case GrowInfo#p_role_pet_grow.grow_type of
		?GROW_TYPE_CON ->
			OldLevel =  GrowInfo#p_role_pet_grow.con_level,
			NewGrowInfo = GrowInfo#p_role_pet_grow{con_level=OldLevel+1,state=?PET_NORMAL_STATE};
		?GROW_TYPE_PHY_DEFENCE ->
			OldLevel =  GrowInfo#p_role_pet_grow.phy_defence_level,
			NewGrowInfo = GrowInfo#p_role_pet_grow{phy_defence_level=OldLevel+1,state=?PET_NORMAL_STATE};
		?GROW_TYPE_MAGIC_DEFENCE ->
			OldLevel =  GrowInfo#p_role_pet_grow.magic_defence_level,
			NewGrowInfo = GrowInfo#p_role_pet_grow{magic_defence_level=OldLevel+1,state=?PET_NORMAL_STATE};
		?GROW_TYPE_PHY_ATTACK ->
			OldLevel =  GrowInfo#p_role_pet_grow.phy_attack_level,
			NewGrowInfo = GrowInfo#p_role_pet_grow{phy_attack_level=OldLevel+1,state=?PET_NORMAL_STATE};
		?GROW_TYPE_MAGIC_ATTACK ->
			OldLevel =  GrowInfo#p_role_pet_grow.magic_attack_level,
			NewGrowInfo = GrowInfo#p_role_pet_grow{magic_attack_level=OldLevel+1,state=?PET_NORMAL_STATE}
	end,
	NewGrowInfo.

get_grow_type_str_and_level(GrowInfo) ->
	case GrowInfo#p_role_pet_grow.grow_type of
		?GROW_TYPE_CON ->
			{"神功护体",GrowInfo#p_role_pet_grow.con_level+1};
		?GROW_TYPE_PHY_DEFENCE ->
			{"刀枪不入",GrowInfo#p_role_pet_grow.phy_defence_level+1};
		?GROW_TYPE_MAGIC_DEFENCE ->
			{"气运丹田",GrowInfo#p_role_pet_grow.magic_defence_level+1};
		?GROW_TYPE_PHY_ATTACK ->
			{"力敌千钧",GrowInfo#p_role_pet_grow.phy_attack_level+1};
		?GROW_TYPE_MAGIC_ATTACK ->
			{"以柔克刚",GrowInfo#p_role_pet_grow.magic_attack_level+1}
	end.

check_grow_pre_skill_level(GrowInfo,GrowType) ->
	case GrowType of
		?GROW_TYPE_CON ->
			GrowInfo#p_role_pet_grow.con_level =< GrowInfo#p_role_pet_grow.phy_attack_level
																			   orelse  GrowInfo#p_role_pet_grow.con_level =< GrowInfo#p_role_pet_grow.magic_attack_level;
		?GROW_TYPE_PHY_DEFENCE ->
			GrowInfo#p_role_pet_grow.phy_defence_level < GrowInfo#p_role_pet_grow.con_level;
		?GROW_TYPE_MAGIC_DEFENCE ->
			GrowInfo#p_role_pet_grow.magic_defence_level < GrowInfo#p_role_pet_grow.con_level;
		?GROW_TYPE_PHY_ATTACK ->
			GrowInfo#p_role_pet_grow.phy_attack_level < GrowInfo#p_role_pet_grow.phy_defence_level
																					 orelse GrowInfo#p_role_pet_grow.phy_attack_level < GrowInfo#p_role_pet_grow.magic_defence_level;
		?GROW_TYPE_MAGIC_ATTACK ->
			GrowInfo#p_role_pet_grow.magic_attack_level < GrowInfo#p_role_pet_grow.magic_defence_level
																					   orelse GrowInfo#p_role_pet_grow.magic_attack_level < GrowInfo#p_role_pet_grow.phy_defence_level
	end.

update_role_base(RoleID, OldGrow, NewGrow) ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	RoleBase2 = calc(RoleBase, '-', OldGrow, '+', NewGrow),
	mod_role_attr:reload_role_base(RoleBase2).

grow_attrs(GrowInfo) when is_record(GrowInfo, p_role_pet_grow) ->
	#p_role_pet_grow{
		con_level           = ConLevel,
		phy_attack_level    = PhyAttackLevel,
		magic_attack_level  = MagicAttackLevel,
		phy_defence_level   = PhyDefenceLevel,
		magic_defence_level = MagicDefenceLevel
	} = GrowInfo,
	[#r_pet_grow{add_value = MaxHp}]        = get_grow_add_value(ConLevel,          ?GROW_TYPE_CON),
	[#r_pet_grow{add_value = PhyAttack}]    = get_grow_add_value(PhyAttackLevel,    ?GROW_TYPE_PHY_ATTACK),
	[#r_pet_grow{add_value = MagicAttack}]  = get_grow_add_value(MagicAttackLevel,  ?GROW_TYPE_MAGIC_ATTACK),
	[#r_pet_grow{add_value = PhyDefence}]   = get_grow_add_value(PhyDefenceLevel,   ?GROW_TYPE_PHY_DEFENCE),
	[#r_pet_grow{add_value = MagicDefence}] = get_grow_add_value(MagicDefenceLevel, ?GROW_TYPE_MAGIC_DEFENCE),
	[
		{#p_role_base.max_hp,           MaxHp},
		{#p_role_base.max_phy_attack,   PhyAttack},
		{#p_role_base.min_phy_attack,   PhyAttack},
		{#p_role_base.max_magic_attack, MagicAttack},
		{#p_role_base.min_magic_attack, MagicAttack},
		{#p_role_base.phy_defence,      PhyDefence},
		{#p_role_base.magic_defence,    MagicDefence}
	];
grow_attrs(_) -> [].

calc(RoleBase, Op1, Grow1, Op2, Grow2) ->
	calc(calc(RoleBase, Op1, Grow1), Op2, Grow2).

calc(RoleBase, Op, Grow) ->
	mod_role_attr:calc(RoleBase, Op, grow_attrs(Grow)).

recalc(RoleBase, _RoleAttr) ->
	GrowInfo = mod_role_tab:get({?ROLE_PET_GROW_INFO, RoleBase#p_role_base.role_id}),
	mod_role_attr:calc(RoleBase, '+', grow_attrs(GrowInfo)).

