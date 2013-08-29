%%% @author fsk 
%%% @doc
%%%     车夫
%%% @end
%%% Created : 2012-9-15
%%%-------------------------------------------------------------------
-module(mod_driver).

-include("mgeem.hrl").

-export([handle/1]).
-export([hook_role_enter/2]).

-record(driver_rule,{min_lv,max_lv,cost_silver,cost_gold,enable}).
-record(driver_config,{id,tx,ty,map_id,min_jingjie,rule_list}).


%% 进入安全挂机地图自动切换成和平模式
hook_role_enter(RoleID,MapID) ->
	case MapID of
		10201 ->
			mod_role2:modify_pk_mode_for_role(RoleID,?PK_PEACE);
		_ ->
			ignore
	end.

handle({Unique,Module,?DRIVER_GO=Method,DataIn,RoleID,PID})->
	#m_driver_go_tos{id=ID} = DataIn,
	case catch check_driver(RoleID,ID) of
		{error,_ErrCode,Reason} ->
			?UNICAST_TOC(#m_driver_go_toc{succ=false,reason=Reason,id=ID});
		{ok,Rule,RoleAttr,Config} ->
			TransFun = fun()-> 
							   t_driver(RoleID,Rule,RoleAttr)
					   end,
			case common_transaction:t( TransFun ) of
				{atomic, {ok,NewRoleAttr2}} ->
					mod_map_event:notify({role, RoleID}, change_map),
					common_misc:send_role_gold_silver_change(RoleID,NewRoleAttr2),
					#driver_config{id=ID,tx=TX,ty=TY,map_id=MapID}=Config,
					common_misc:send_to_rolemap(RoleID,{mod_map_role,{change_map,RoleID,MapID,TX,TY,?CHANGE_MAP_TYPE_DRIVER}}),
					R2 = #m_map_change_map_toc{succ=true,mapid=MapID,tx=TX,ty=TY},
					common_misc:unicast2(PID,?DEFAULT_UNIQUE,?MAP,?MAP_CHANGE_MAP,R2),
					?UNICAST_TOC(#m_driver_go_toc{succ=true,id=ID});
				{aborted,{error,_ErrCode,Reason}} ->
					?UNICAST_TOC(#m_driver_go_toc{succ=false,reason=Reason,id=ID})
			end
	end;
handle(Info) ->
	?ERROR_MSG("receive unknown message,Info=~w",[Info]),
	ignore.

check_driver(RoleID,ID) ->
	[Config] = common_config_dyn:find(driver,ID),
	#driver_config{rule_list=RuleList}=Config,
	{ok, #p_role_base{pk_points=PkPoints,faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
	{ok, #p_role_attr{level=RoleLevel}=RoleAttr} = mod_map_role:get_role_attr(RoleID),
	assert_red_name(PkPoints),
	Rule = assert_level(RoleLevel,RuleList),
	assert_faction_ybc(RoleID,FactionID),
	assert_transfer(RoleID),
	{ok,Rule,RoleAttr,Config}.

t_driver(RoleID,Rule,RoleAttr) ->
	#driver_rule{cost_silver=CostSilver,cost_gold=CostGold} = Rule,
	case CostSilver > 0 of
		true ->
			case catch common_bag2:t_deduct_money(silver_any,CostSilver,RoleAttr,?CONSUME_TYPE_SILVER_CHEFU) of
				{ok,NewRoleAttr}->
					next;
				_ ->
					NewRoleAttr = null,
					?THROW_ERR_REASON("钱币不足")
			end;
		false ->
			NewRoleAttr = RoleAttr
	end,
	case CostGold > 0 of
		true ->
			case catch common_bag2:t_deduct_money(gold_unbind,CostGold,NewRoleAttr,?CONSUME_TYPE_GOLD_CHEFU) of
				{ok,NewRoleAttr2}->
					next;
				{error, Reason} ->
					NewRoleAttr2 = null,
					?THROW_ERR_REASON(Reason)
			end;
		false ->
			NewRoleAttr2 = NewRoleAttr
	end,
	mod_map_role:set_role_attr(RoleID,NewRoleAttr2),
	{ok,NewRoleAttr2}.
		
%%判断红名
assert_red_name(PkPoints) ->
	case PkPoints >= ?RED_NAME_PKPOINT of
		true ->
			?THROW_ERR_REASON(?_LANG_DRIVER_RED_NAME);
		false ->
			next
	end.
%%判断等级
assert_level(RoleLevel,RuleList) ->
    case match_level(RuleList, RoleLevel) of
		false ->
			?THROW_ERR_REASON(?_LANG_DRIVER_LEVEL_NOT_MATCH);
		Rule ->
			Rule
	end.
assert_faction_ybc(MapID,FactionID) ->
	case mod_map_role:get_map_faction_id(MapID) of
		{ok, MapFactionID} ->
			case mod_ybc_person:faction_ybc_status(MapFactionID) of
				{activing,{ContinueTime,_}}->
					if
						ContinueTime < 600 andalso MapFactionID =/= FactionID ->
							?THROW_ERR_REASON(?_LANG_DRIVER_MAP_FACTION_DOING_PERSONYBC_FACTION);
						true ->
							next    
					end;
				_ ->
					next
			end;
		_ ->
			next
	end.

assert_transfer(RoleID) ->
	RoleMapInfo =
		case mod_map_actor:get_actor_mapinfo(RoleID, role) of
			undefined ->
				?THROW_ERR_REASON(?_LANG_SYSTEM_ERROR);
			MapInfo ->
				MapInfo
		end,
	#p_map_role{state=RoleState} = RoleMapInfo,
	%% 监狱不能使用传送卷
	#map_state{mapid=MapID} = mgeem_map:get_state(),
	case mod_jail:check_in_jail(MapID) of
		true ->
			?THROW_ERR_REASON(?_LANG_MAP_TRANSFER_IN_JAIL);
		_ ->
			ok
	end,
	case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
	    true ->
	        ?THROW_ERR(?ERR_OTHER_ERR, ?_LANG_XIANNVSONGTAO_MSG);
	    false -> ignore
	end,
	%% 死亡等一些特殊状态不能使用传送
	case RoleState of
		?ROLE_STATE_DEAD ->
			?THROW_ERR_REASON(?_LANG_MAP_TRANSFER_DEAD_STATE);
		_ ->
			ok
	end,
	case mod_horse_racing:is_role_in_horse_racing(RoleID) of
		true ->
			?THROW_ERR_REASON(?_LANG_MAP_TRANSFER_HORSE_RACING_STATE);
		_ ->
			ok
	end,
	case mod_trading_common:get_role_trading(RoleID) of
        undefined->
            next;
        _ ->
            ?THROW_ERR_REASON(?_LANG_MAP_CHANGE_MAP_IN_TRADING_STATE)
    end,
	case common_config_dyn:find(fb_map,MapID) of
		[]->
			ok;
		[#r_fb_map{can_use_item_transfer=CanTransfer}] ->
			case CanTransfer of
				false ->
					?THROW_ERR_REASON(?_LANG_MAP_TRANSFER_OTHER_COUNTRY);
				true ->
					ok
			end
	end.

match_level([], _RoleLevel) ->
	false;
match_level([Rule|RuleList], RoleLevel) ->
	#driver_rule{min_lv=MinLv,max_lv=MaxLv,enable=Enable}=Rule,
	if
		(MinLv =:= 0 orelse RoleLevel >= MinLv) 
			andalso 
			(MaxLv =:= 0 orelse RoleLevel =< MaxLv) -> 
			if
				Enable =:= false ->
					false;
				true ->
					Rule
			end;
		true ->
			match_level(RuleList, RoleLevel)
	end.
