%% Author: liuwei
%% Created: 2010-9-15
%% Description: TODO: Add description to mod_map_drop
-module(mod_map_family).

-include("mgeem.hrl").

-export([
		 init_role_family_misc/2,
		 delete_role_family_misc/1,
		 get_role_family_misc/1,
         handle/2,
		 hook_monster_dead/3
        ]).

-define(WELFARE_ERROR(Msg),	?DEFAULT_UNIQUE, ?FAMILY_WELFARE, ?FAMILY_WELFARE_ERROR, #m_family_welfare_error_toc{mesg = Msg}).

%%
%% API Functions
%%

%%NOTE:r_role_family_misc在role和idol进程有双份数据, 操作需注意
init_role_family_misc(RoleID, Rec) when is_record(Rec, r_role_family_misc) ->
	%%global:send(mod_map_fml_idol, {init, RoleID, Rec}),
	mod_role_tab:put({r_role_family_misc, RoleID}, Rec);
init_role_family_misc(_RoleID, _Rec) ->
	ignore.

delete_role_family_misc(RoleID) ->
    mod_role_tab:erase({r_role_family_misc, RoleID}).
	% case of
	% #r_role_family_misc{} ->
	% 	global:send(mod_map_fml_idol, {delete, RoleID});
	% _ ->
	% 	ignore
	% end.

get_role_family_misc(RoleID) ->
	case mod_role_tab:get({r_role_family_misc, RoleID}) of
	undefined ->
		#r_role_family_misc{};
	Misc ->
		Misc
	end.

handle({Unique, ?FAMILY, ?FAMILY_DONATE, Record, RoleID, PID, _Line},_State)->
    do_family_donate(Unique,Record,RoleID,PID);

handle({reborn_family_uplevel_boss, FamilyID, MonsterType}, _State) ->
    Fun = fun() -> ?DEBUG("~ts", ["重生家族升级boss成功"]) end,
    mod_map_monster:create_family_boss(uplevel, FamilyID, MonsterType, Fun);

handle({reborn_family_common_boss, FamilyID, MonsterType}, _State) ->
    Fun = fun() -> ?DEBUG("~ts", ["重生家族boss成功"]) end,
    mod_map_monster:create_family_boss(common, FamilyID, MonsterType, Fun);

handle({call_family_common_boss, Unique, Module, Method, {FamilyID, MonsterType}, RoleID, Line}, _State) ->
    Fun = fun() ->
                  ?DEBUG("~ts", ["召唤家族boss成功"]),
                  R = #m_family_call_commonboss_toc{},
                  common_misc:unicast(Line, RoleID, Unique, Module, Method, R)
          end,
    mod_map_monster:create_family_boss(common, FamilyID, MonsterType, Fun);

handle({call_family_uplevel_boss, Unique, Module, Method, {FamilyID, MonsterType}, RoleID, Line}, _State) ->
    Fun = fun() ->
                  ?DEBUG("~ts", ["召唤家族升级boss成功"]),
                  R = #m_family_call_uplevelboss_toc{},
                  common_misc:unicast(Line, RoleID, Unique, Module, Method, R)
          end,
    mod_map_monster:create_family_boss(uplevel, FamilyID, MonsterType, Fun);

handle({cancel_role_family_info, RoleID}, State) ->
    do_cancel_role_family_info(RoleID, State);

handle({update_role_family_info, RoleID, FamilyInfo}, State) ->
    do_update_role_family_info(RoleID, FamilyInfo, State);
handle({clear_role_family_skill, RoleID}, _State) ->
    do_clear_role_family_skill(RoleID);
handle({fetch_family_buff,From,RoleID,FmlBuffID,BuffLevel}, _State) ->
    do_fetch_family_buff(From,RoleID,FmlBuffID,BuffLevel);

handle({update_role_family_info, RoleID, family_contribute,NewFC}, State) ->
    do_update_role_family_contribute(RoleID, NewFC, State);

handle({family_map_roles,From,CombineTerm}, _State) ->
   	MapRoles = mod_map_actor:get_in_map_role(),
	From ! {family_map_roles,MapRoles,CombineTerm};

%%关闭宗族地图
handle(kill_family_map,_State)->
    erlang:send_after(60000,self(),maintain_family_fail);

handle({broadcast_to_all_inmap_member, Module, Method, Record}, _State) ->
    do_broadcast_to_all_inmap_member(Module, Method, Record);

handle({broadcast_to_all_inmap_member_except, Module, Method, Record, RoleID}, _State) ->
    do_broadcast_to_all_inmap_member_except(Module, Method, Record, RoleID);

handle({kick_role, RoleID}, _State) ->
    do_kick_role(RoleID);

handle(kick_all_role, _State) ->
    do_kick_all_role();

handle(maintain_family_fail, _State)->
    common_map:exit(kill_family_map_exit);

handle({get_welfare, RoleID, _FamilyPID, FamilyLv}, _State) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    #p_role_attr{ level=RoleLv } = RoleAttr, 

    RewardExp = cfg_family:get_welfare_exp(RoleLv, FamilyLv), 
    RewardMoney = cfg_family:get_welfare_money(RoleLv, FamilyLv), 

    NewRoleExp = RoleAttr#p_role_attr.exp + RewardExp,
    ChangeList = [#p_role_attr_change{change_type=?ROLE_EXP_CHANGE, new_value=NewRoleExp}],
    common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),

    common_bag2:add_money(RoleID, silver_bind, RewardMoney, ?GAIN_TYPE_SILVER_FAMILY_WELFARE),
    mod_role_tab:put({?role_attr, RoleID}, RoleAttr#p_role_attr{exp=NewRoleExp});

	% [Welfare] = common_config_dyn:find(family_welfare, FamilyLevel),
	% CreateInfo = #r_goods_create_info{bind=true, type=?TYPE_ITEM},
	% CreateInfos = [CreateInfo#r_goods_create_info{type_id=TypeID, num=Num}||{TypeID, Num}<-Welfare],
	% case common_transaction:t(fun() -> mod_bag:create_goods(RoleID, CreateInfos) end) of
	% {atomic,{ok, UpdateList}} ->
	% 	common_misc:new_goods_notify({role, RoleID}, UpdateList),
	% 	common_item_logger:log(RoleID, CreateInfos, ?LOG_ITEM_TYPE_RADMON_MISSION_REWARD);
	% _ ->
	% 	FamilyPID ! {mod_family_welfare, {get_welfare_error, RoleID}},
	% 	common_misc:unicast({role, RoleID}, ?WELFARE_ERROR(<<"背包已满">>))
	% end;

handle(Msg,_State) ->
    ?ERROR_MSG("uexcept msg = ~w",[Msg]).

%% 家族boss死亡
hook_monster_dead(KillerRoleID, TypeID, MonsterName) ->
	case mgeem_map:get_mapid() of
		?DEFAULT_FAMILY_MAP_ID ->
			[ConfigList] = common_config_dyn:find(family_boss,family_boss),
			IsFamilyBoss = 
				lists:any(fun(#r_family_boss_config{common_boss_type=BossType}) ->
								  BossType =:= TypeID
						  end, ConfigList),
			case IsFamilyBoss of
				true ->
					family_boss_dead(KillerRoleID,MonsterName);
				false ->
					nil
			end;
		_ ->
			nil
	end.
%%
%% Local Functions
%%
%% 踢掉当前地图的所有玩家
do_kick_all_role() ->    
    [begin
         do_kick_role(RoleID)
     end || RoleID <- mgeem_map:get_all_roleid()],
    ok.

do_kick_role(RoleID) ->
    AllRoleID = mgeem_map:get_all_roleid(),
    case lists:member(RoleID, AllRoleID) of
        true ->
            case mod_map_actor:get_actor_mapinfo(RoleID, role) of
                #p_map_role{faction_id=FactionID} ->
                    MapID = common_misc:get_home_map_id(FactionID),
                    {MapID, TX, TY} = common_misc:get_born_info_by_map(MapID),
                    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, MapID, TX, TY);
                _ ->
                    ignore
            end;
        false ->
            ignore
    end.

%% 广播通知地图内的所有玩家
do_broadcast_to_all_inmap_member(Module, Method, Record) ->
    Binary = mgeeg_packet:packet_encode(?DEFAULT_UNIQUE, Module, Method, Record),
    [begin
         common_misc:unicast(RoleID, Binary)
     end || RoleID <- mgeem_map:get_all_roleid()],
    ok.

do_broadcast_to_all_inmap_member_except(Module, Method, Record, RoleID) ->
    Binary = mgeeg_packet:packet_encode(?DEFAULT_UNIQUE, Module, Method, Record),
    [begin
         common_misc:unicast(RID, Binary)
     end || RID <- lists:delete(RoleID, mgeem_map:get_all_roleid())],
    ok.
do_fetch_family_buff(From,RoleID,FmlBuffID,BuffLevel)->
    [FmlBuffList] = common_config_dyn:find(family_buff,FmlBuffID),
    #r_family_buff{buff_id=BuffID} = lists:keyfind(BuffLevel,#r_family_buff.buff_level,FmlBuffList),
    
    %%设置BUFF
    try
        {ok, BuffDetail} = mod_skill_manager:get_buf_detail(BuffID),
        mod_role_buff:add_buff(RoleID, BuffDetail),
        From ! {fetch_family_buff_result,true,{RoleID,FmlBuffID}}
    catch
        _:Reason->
            From ! {fetch_family_buff_result,false,{RoleID,Reason,FmlBuffID,BuffLevel}}
    end.
    

%%@doc 清空玩家的宗族技能（在离开宗族之后）
do_clear_role_family_skill(RoleID)->
    mod_skill:clear_family_skill(RoleID).

%%@doc 清除个人的宗族信息，包括清空宗族技能
do_cancel_role_family_info(RoleID, _State) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            nil;
        MapRoleInfo ->
            mod_skill:clear_family_skill(RoleID),
            NewMapRoleInfo = MapRoleInfo#p_map_role{family_id=0, family_name=[]},
            mod_map_actor:set_actor_mapinfo(RoleID, role, NewMapRoleInfo),
            {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
            RoleBase2 = RoleBase#p_role_base{family_id=0, family_name=[]},
            common_transaction:transaction(fun() -> mod_map_role:set_role_base(RoleID, RoleBase2) end),
            %%广播通知
            Record = #m_map_update_actor_mapinfo_toc{actor_id = RoleID,actor_type = ?TYPE_ROLE,role_info = NewMapRoleInfo},
            mgeem_map:send({broadcast_in_sence_include,[RoleID],?MAP,?MAP_UPDATE_ACTOR_MAPINFO,Record})
    end. 

%% 同步更新地图进程字典中，玩家的宗族ID、宗族名称
do_update_role_family_info(RoleID, FamilyInfo, _State) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            nil;
        MapRoleInfo ->            
            #p_family_info{family_id=FamilyID, family_name=FamilyName} = FamilyInfo,
            case FamilyID =:= 0 of
                true ->
                    mod_accumulate_exp:role_exit_family(RoleID);
                false ->
                    ignore
            end,
            NewMapRoleInfo = MapRoleInfo#p_map_role{family_id=FamilyID, family_name=FamilyName},
            mod_map_actor:set_actor_mapinfo(RoleID, role, NewMapRoleInfo),
            {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
            RoleBase2 = RoleBase#p_role_base{family_id=FamilyID, family_name=FamilyName},
            common_transaction:transaction(fun() -> mod_map_role:set_role_base(RoleID, RoleBase2) end),
            Record = #m_map_update_actor_mapinfo_toc{actor_id = RoleID,actor_type = ?TYPE_ROLE,role_info = NewMapRoleInfo},
            mgeem_map:send({broadcast_in_sence_include,[RoleID],?MAP,?MAP_UPDATE_ACTOR_MAPINFO,Record})
    end.

%% 同步更新地图进程字典中，玩家的宗族贡献度
do_update_role_family_contribute(RoleID, NewFC, _State) ->
	NewFC2 = if NewFC < 0 -> 0; true -> NewFC end,
	case mod_map_role:get_role_attr(RoleID) of
		{ok, RoleAttr} ->
			RoleAttr2 = RoleAttr#p_role_attr{family_contribute = NewFC2},
			common_transaction:transaction(
			  fun() ->
					  mod_map_role:set_role_attr(RoleID, RoleAttr2) 
			  end);
		_Error ->
			?DEBUG("玩家:~w已经下线",[RoleID]),
			ignore
	end.

do_family_donate(Unique,DataIn,RoleID,PID)->
    case catch check_can_donate(DataIn,RoleID) of
        {ok,FamilyID}->
            do_family_donate2(Unique,DataIn,RoleID,PID,FamilyID);
        {error,Reason,ReasonCode}->
            do_donate_error({Unique,DataIn,RoleID,PID},Reason,ReasonCode)
    end.

-define(donate_gold,1).
-define(donate_silver,2).
-define(donate_token,3).%%家族令


%%-define(family_token_id, 10200017).%%家族令id  , 测试物品.....
-define(family_token_id, 14000007).%%家族令id

do_family_donate2(Unique,DataIn1,RoleID,PID,FamilyID)->
    #m_family_donate_tos{donate_type=DonateType1,
                         donate_value=DonateValue1}=DataIn1,

    MaxTokenTimes = cfg_family:get_daily_max_token_donate_times(),
    TokenTimes = mod_map_fml_idol:get_token_times(RoleID),
    DataIn = case DonateType1 of
        ?donate_token ->
            RecordType = ?DONATE_TOKEN,
            if
                TokenTimes >= MaxTokenTimes -> %%家族令大于上限不在这里处理, 下面会统一处理
                    DataIn1;
                TokenTimes + DonateValue1 > MaxTokenTimes ->
                    DataIn1#m_family_donate_tos{
                        donate_value = MaxTokenTimes - TokenTimes
                    };
                true ->
                    DataIn1
            end;
            
        _ ->
        %%暂时木有捐献家族金币功能...
            RecordType = ?DONATE_GOLD,
            DataIn1
    end,
    #m_family_donate_tos{
        donate_type=DonateType,
        donate_value=DonateValue
    } = DataIn,

    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    case common_transaction:transaction(
           fun()->
               case DonateType of
                   ?donate_gold->
                       case common_bag2:t_deduct_money(gold_unbind, DonateValue, RoleID, {?CONSUME_TYPE_GOLD_FAMILY_DONATE, common_tool:to_list(RoleAttr#p_role_attr.family_contribute)}) of
                            {ok, NewRoleAttr} -> ok;
                            {error, Reason0} ->
                                NewRoleAttr = RoleAttr,
                                common_transaction:abort({Reason0,0})
                       end;
                    %%尼玛这个bug给别人利用了, 刷家族
                   % ?donate_silver->
                   %      case common_bag2:t_deduct_money(silver_any, DonateValue, RoleID, {?CONSUME_TYPE_SIVLER_FAMILY_DONATE, common_tool:to_list(RoleAttr#p_role_attr.family_contribute)}) of
                   %          {ok, NewRoleAttr} -> ok;
                   %          {error, Reason0} ->
                   %              NewRoleAttr = RoleAttr,
                   %              common_transaction:abort({Reason0,0})
                   %     end;
                    ?donate_token ->
                        % TokenTimes = mod_map_fml_idil:get_token_times(RoleID),
                        case TokenTimes >= MaxTokenTimes of
                            true ->
                                common_transaction:abort({?_LANG_FAMILY_DONATE_MAX_TOKEN_TIMES,0});
                            _ ->
                                case mod_bag:use_item(RoleID, ?family_token_id, DonateValue, ?LOG_ITEM_TYPE_LOST_FAMILY_DONATE) of
                                    ok ->
                                        [];
                                    _ ->
                                        common_transaction:abort({?_LANG_FAMILY_DONATE_NO_ENOUGH_TOKEN,0})
                                end
                        end,
                        NewRoleAttr = RoleAttr
               end,
               NewRoleAttr
           end) of
        {aborted,{Reason,ReasonCode}}->
            do_donate_error({Unique,DataIn,RoleID,PID},Reason,ReasonCode);
        {atomic,NewRoleAttr}->
            {PrayItem, TTS1} = case DonateType of
                ?donate_gold->
                    common_misc:send_role_gold_change(RoleID, NewRoleAttr), 
                    {0, 0};
                ?donate_silver->
                    common_misc:send_role_silver_change(RoleID,NewRoleAttr),
                    {0, 0};
                _ ->
                    TTS = mod_map_fml_idol:add_token_times(RoleID, DonateValue),
                    {?family_token_id, TTS}
            end,
 
            {ok, #p_role_attr{
                role_name = RoleName
            }} = mod_map_role:get_role_attr(RoleID),
            %%增加捐献的数据到列表
            DonateRecord = #p_family_pray_rec{
                role_id        = RoleID, 
                role_name      = RoleName, 
                pray_item      = PrayItem, 
                pray_cost      = DonateValue, 
                pray_time      = common_tool:now(),
                add_family_exp = 0,
                active_type    = RecordType
            },
            case global:whereis_name(mod_family_manager) of
                undefined ->
                    ignore;
                GPID ->
                    GPID ! {family_donate,DonateRecord, TTS1, FamilyID,RoleAttr#p_role_attr.role_name,{Unique,DataIn,RoleID,PID}}
            end
    end.


check_can_donate(DataIn,RoleID)->
    {ok,#p_role_base{family_id=FamilyID}} = mod_map_role:get_role_base(RoleID),
    case FamilyID>0 of
        true->
            next;
        false->
            erlang:throw({error,?_LANG_FAMILY_NO_FAMILY,0})
    end,
    case DataIn#m_family_donate_tos.donate_type=:=?donate_gold 
        orelse DataIn#m_family_donate_tos.donate_type=:=?donate_silver 
        orelse DataIn#m_family_donate_tos.donate_type == ?donate_token
    of
        true->
            next;
        false->
            erlang:throw({error,?_LANG_FAMILY_DOANTE_TYPE_ERROR,0})
    end,
    case DataIn#m_family_donate_tos.donate_value>0 of
        true->
            {ok,FamilyID};
        false->
            {error,?_LANG_FAMILY_DOANTE_MONEY_ERROR,0}
    end. 
    
-define(_common_error, ?DEFAULT_UNIQUE, ?COMMON, ?COMMON_ERROR, #m_common_error_toc).
do_donate_error({_Unique,_Record,_RoleID,PID},Reason,_ReasonCode)->
    common_misc:unicast2(PID, ?_common_error{error_str = Reason}).

    % R=#m_family_donate_toc{succ=false,
    %                        reason=Reason,
    %                        reason_code=ReasonCode},
    % common_misc:unicast2(PID, Unique, ?FAMILY, ?FAMILY_DONATE, R).

%% 家族boss死亡给玩家加经验和广播
family_boss_dead(KillerRoleID,MonsterName) ->
	{ok,#p_role_base{family_id=FamilyID,role_name=RoleName}} = mod_map_role:get_role_base(KillerRoleID),
	{ok,#p_role_attr{level=Level}} = mod_map_role:get_role_attr(KillerRoleID),
	[BossExpArg] = common_config_dyn:find(family_boss, kill_family_boss_exp),
	AddExp = common_family:get_family_boss_base_exp(Level) * BossExpArg,
	mod_map_role:add_exp(KillerRoleID, AddExp),
	Msg = common_misc:format_lang(?_LANG_FAMILY_BOSS_DEAD_BROADCAST, [common_tool:to_list(RoleName),MonsterName]),
	common_broadcast:bc_send_msg_family(FamilyID,?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_FAMILY,Msg).
