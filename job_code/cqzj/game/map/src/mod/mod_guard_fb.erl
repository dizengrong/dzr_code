%%% @author fsk 
%%% @doc
%%%     圣女魔尊洞窟
%%% @end
%%% Created : 2012-9-24
%%%-------------------------------------------------------------------
-module(mod_guard_fb).

-include("mgeem.hrl").
-export([
		 handle/1,
		 handle/2
		]).
-export([
		 get_role_guard_fb_info/1,
		 hook_role_enter/2,
		 hook_role_before_quit/1,
		 hook_monster_dead/1,
		 hook_server_npc_dead/2,
		 hook_role_level_change/2,
		 hook_server_npc_attr_change/1,
		 hook_role_quit/1
		]).
-export([
		 assert_valid_map_id/1,
		 is_in_fb_map/0,
		 is_guard_fb_map_id/1,
		 get_map_name_to_enter/1,
		 clear_map_enter_tag/1
		]).
-compile(export_all).
%% ====================================================================
%% Macro
%% ====================================================================
%% 圣女魔尊洞窟地图信息
-record(r_guard_fb_map_info,{map_role_id,role_level=1,first_enter=false,start_time=0,end_time=0,next_refresh_time=0,
							 total_score=0,kill_monster_num=0,kill_boss_num=0,cur_monster_wave=0}).
-define(GUARD_FB_MAP_INFO, guard_fb_map_info).

-define(BUY_BUFF_TYPE_SILVER,1).
-define(BUY_BUFF_TYPE_GOLD,2).

%%更新类型:1=积分;2=下次刷新时间;3=当前波数;4=击杀小怪数量;5=击杀boss数量
-define(CHANGE_TYPE_TOTAL_SCORE,1).
-define(CHANGE_TYPE_NEXT_REFRESH_TIME,2).
-define(CHANGE_TYPE_CUR_MONSTER_WAVE,3).
-define(CHANGE_TYPE_KILL_MONSTER_NUM,4).
-define(CHANGE_TYPE_KILL_BOSS_NUM,5).

%% 圣女魔尊洞窟地图ID
-define(GUARD_FB_MAP_ID,10511).

%% 圣女魔尊洞窟退出
-define(guard_fb_quit_type_normal,  0).
-define(guard_fb_quit_type_timeout, 1).
-define(guard_fb_quit_type_lost, 2).
-define(guard_fb_quit_type_win, 3).

-define(CONFIG_NAME,guard_fb).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

-define(GUARD_FB_TIMEOUT_REF, guard_fb_timeout_ref).

-define(GUARD_FB_TOTAL_MONSTER_NUM, guard_fb_total_monster_num).

-define(SERVER_NPC_GODDESS,goddess).
-define(SERVER_NPC_GUARD,guard).
-define(SERVER_NPC_TOWERS,towers).

-define(GODDESS_ID,0).
-define(GUARD_ID,-1).

-define(OP_TYPE_GODDESS,0).
-define(OP_TYPE_GUARD,1).
-define(OP_TYPE_TOWER,2).

%%错误码
-define(ERR_GUARD_FB_ENTER_TIMES_LIMITED,120001).  %%今天的挑战次数已到最大限制
-define(ERR_GUARD_FB_ENTER_MIN_LV_LIMITED,120002).  %%等级限制
-define(ERR_GUARD_FB_ENTER_MIN_JINGJIE_LIMITED,120003).  %%境界限制
-define(ERR_GUARD_FB_BUY_TIMES_MAX_LIMIT,120004).  %%今天的VIP购买次数已达限制.
-define(ERR_GUARD_FB_ENTER_ROLE_HORSE_RACING,120005).  %%在玩钦点美人不能进入圣女魔尊洞窟
-define(ERR_GUARD_FB_ENTER_ROLE_DEAD,120006).  %%死亡状态下不能进入圣女魔尊洞窟
-define(ERR_GUARD_FB_ENTER_ROLE_STALL,120007).  %%摆摊状态下不能进入圣女魔尊洞窟
-define(ERR_GUARD_FB_NOT_IN_MAP,120008). %%你不在圣女魔尊洞窟中
-define(ERR_GUARD_FB_ENTER_ROLE_FIGHT,120009).  %%战斗状态下不能进入圣女魔尊洞窟
-define(ERR_GUARD_FB_BUY_BUFF_INVALID_BUFF,120010). %%非法buff
-define(ERR_GUARD_FB_SUMMON_GUARD_NUM_LIMIT,120011). %%购买箭塔数量已经满
-define(ERR_GUARD_FB_UPGRADE_SERVER_NPC_FULL_LEVEL,120012). %%已经满级，不需要再升级
-define(ERR_GUARD_FB_HAS_SUMMON_GUARD,120013). %%该箭塔已经购买，不需要再购买
-define(ERR_GUARD_FB_UPGRADE_NOT_ENOUGH_MATERIAL_ITEM,120014). %%升级失败，材料不足
-define(ERR_GUARD_FB_BAG_POS_NOT_ENOUGH,120015). %%背包空间不足
-define(ERR_GUARD_FB_BAG_NUM_NOT_ENOUGH,120016). %%道具不足
-define(ERR_GUARD_FB_CAN_NOT_REWARD,120017). %%今天没有进行圣女魔尊洞窟，不能领取奖励
-define(ERR_GUARD_FB_ALREADY_REWARD,120018). %%今天的奖励已经领取

%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
	handle(Info).

handle({_, ?GUARD_FB, ?GUARD_FB_ENTER,_,_,_,_}=Info) ->
	do_guard_fb_enter(Info);
handle({_, ?GUARD_FB, ?GUARD_FB_QUIT,_,_,_,_}=Info) ->
	do_guard_fb_quit(Info);
handle({_, ?GUARD_FB, ?GUARD_FB_INFO,_,_,_,_}=Info) ->
	do_guard_fb_info(Info);
handle({_, ?GUARD_FB, ?GUARD_FB_BUFF_ITEM,_,_,_,_}=Info) ->
	do_guard_fb_buff_item(Info);
handle({_, ?GUARD_FB, ?GUARD_FB_BUY_BUFF,_,_,_,_}=Info) ->
	do_guard_fb_buy_buff(Info);
handle({_, ?GUARD_FB, ?GUARD_FB_SUMMON_TOWER,_,_,_,_}=Info) ->
	do_guard_fb_summon_tower(Info);
handle({_, ?GUARD_FB, ?GUARD_FB_UPGRADE_SERVER_NPC,_,_,_,_}=Info) ->
	do_guard_fb_upgrade_server_npc(Info);
handle({_, ?GUARD_FB, ?GUARD_FB_BUY_TIMES,_,_,_,_}=Info) ->
	do_guard_fb_buy_times(Info);
handle({_, ?GUARD_FB, ?GUARD_FB_BUFF_ITEM_COMBINE,_,_,_,_}=Info) ->
	do_guard_fb_buff_item_combine(Info);
handle({_, ?GUARD_FB, ?GUARD_FB_REWARD,_,_,_,_}=Info) ->
	do_guard_fb_reward(Info);

handle({init_guard_fb_map_info, GuardFbMapInfo}) ->
	init_guard_fb_map_info(GuardFbMapInfo);
handle({born_guard_fb_monster,MonsterList,NextIntervalTime}) ->
	do_born_guard_fb_monster(MonsterList,NextIntervalTime);
handle({loop_ms}) ->
	loop_ms(common_tool:now2()) ;
handle({offline_terminate}) ->
	do_offline_terminate();
handle({fb_timeout_kick}) ->
	do_fb_timeout_kick();
handle({gm_reset_enter_times,RoleID}) ->
	gm_reset_enter_times(RoleID);
handle({exit_guard_fb,RoleID}) ->
	exit_guard_fb(RoleID);

handle({add_buff_item_buff,RoleID,ItemTypeID,RoleLevel}) ->
	add_buff_item_buff(RoleID,ItemTypeID,RoleLevel);

handle(Info) ->
	?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).
loop_ms(NowMsec) ->
	mod_server_npc:loop_ms(NowMsec),
	erlang:send_after(200, self(), {mod,?MODULE,{loop_ms}}).
gm_reset_enter_times(RoleID)->
	case get_role_guard_fb_info(RoleID) of
		{ok,OldGuardFbInfo} ->
			NewGuardFbInfo = OldGuardFbInfo#r_role_guard_fb{enter_times=0,last_enter_time=0},
			set_role_guard_fb_info(RoleID,NewGuardFbInfo);
		_ ->
			ignore
	end.

get_map_name_to_enter(RoleID)->
	get_guard_fb_map_name(RoleID).

clear_map_enter_tag(_RoleID)->
	ignore.

clear_timeout_ref() ->
	case erlang:get(?GUARD_FB_TIMEOUT_REF) of
		undefined ->ignore;
		Ref -> erlang:cancel_timer(Ref),erlang:erase(?GUARD_FB_TIMEOUT_REF)
	end.

assert_valid_map_id(DestMapID)->
	case is_guard_fb_map_id(DestMapID) of
		true->
			ok;
		_ ->
			?ERROR_MSG("严重，试图进入错误的地图,DestMapID=~w",[DestMapID]),
			throw({error,error_map_id,DestMapID})
	end.

%% @doc 获取副本地图进程名
get_guard_fb_map_name(RoleID) ->
	common_tool:int_to_atom(RoleID).

%% 副本的时间限制已到，将角色提出副本
do_fb_timeout_kick()->
	case is_in_fb_map() of
		true->
			RoleIDList = mod_map_actor:get_in_map_role(),
			lists:foreach(
			  fun(RoleID) -> 
					  do_guard_fb_quit_2(RoleID,?guard_fb_quit_type_timeout)
			  end, RoleIDList);
		_ ->
			ignore
	end,
	erlang:erase(?GUARD_FB_TIMEOUT_REF).

%% @doc 下线保护时间到，如果角色不在副本中杀掉副本地图进程
do_offline_terminate() ->
	case get_guard_fb_map_info() of
		{ok, GuardFbMapInfo} ->
			#r_guard_fb_map_info{map_role_id=RoleID} = GuardFbMapInfo,
			do_return_city(RoleID,10260);
			%%common_map:exit( guard_fb_role_quit );
		_ ->
			%%common_map:exit( guard_fb_role_quit )
			ignore
	end.

do_return_city(RoleID,CityID) ->
	{_, TX, TY} = common_misc:get_born_info_by_map(CityID),
	common_transaction:t(
	  fun() ->
			  {ok, RolePos} = mod_map_role:get_role_pos_detail(RoleID),
			  mod_map_role:set_role_pos_detail(RoleID, RolePos#p_role_pos{map_id=CityID,pos=#p_pos{tx=TX, ty=TY, dir=4}})
	  end).
%% @doc 是否在圣女魔尊洞窟中
is_in_fb_map() ->
	case get_guard_fb_map_info() of
		{ok, _} ->
			true;
		_ ->
			false
	end.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
init_guard_fb_map_info(GuardFbMapInfo) ->
	set_guard_fb_map_info(GuardFbMapInfo),
	?TRY_CATCH(mod_score:gain_score_notify(GuardFbMapInfo#r_guard_fb_map_info.map_role_id,GuardFbMapInfo#r_guard_fb_map_info.total_score,?SCORE_TYPE_GUARD,{?SCORE_TYPE_GUARD,"圣殿守护获得积分"})),
	mod_map_monster:delete_all_monster(),
	ServerNpcIdList = mod_server_npc:get_server_npc_id_list(),
	mod_server_npc:delete_server_npc(ServerNpcIdList),
	init_guard_fb_server_npc(),
	case get_guard_fb_map_info() of
		{ok,#r_guard_fb_map_info{role_level=RoleLevel}=OldGuardFbMapInfo}->
			FbBornMonsterList = fb_born_monster(RoleLevel),
			put(?GUARD_FB_TOTAL_MONSTER_NUM,fb_total_monster_num(FbBornMonsterList)),
			Now = common_tool:now(),
			[{FirstBornTime,_,_}|_T] = FbBornMonsterList, 
			set_guard_fb_map_info( OldGuardFbMapInfo#r_guard_fb_map_info{next_refresh_time=Now+FirstBornTime} ),
			[ do_refresh_guard_fb_monster_2(BornTime,NextIntervalTime,MonsterList) ||{BornTime,NextIntervalTime,MonsterList}<-FbBornMonsterList ],
			[FbBornServerNpcListConf] = ?find_config(fb_born_server_npc),
			{_,FbBornServerNpcList} = common_tool:find_tuple_section(RoleLevel,FbBornServerNpcListConf),
			[ do_refresh_fb_server_npc_2(BornServerNpc,NpcType) ||{BornServerNpc,NpcType,_UpgradeCost}<-FbBornServerNpcList ],
			ok;
		_ ->
			ignore
	end.

do_refresh_guard_fb_monster_2(BornTime,NextIntervalTime,MonsterList) when BornTime>0->
	erlang:send_after(BornTime*1000, self(), {mod,?MODULE,{born_guard_fb_monster,MonsterList,NextIntervalTime}}),
	ok.

do_refresh_fb_server_npc_2(BornServerNpc,NpcType)->
	#r_born_server_npc{npc_type_Id=NpcTypeID,pos_list=PosList,dir=Dir} = BornServerNpc,
	lists:foreach(fun({Tx,Ty}) ->
						  ServerNpcID = do_refresh_fb_server_npc_3(NpcTypeID,Tx,Ty,Dir),
						  case NpcType of
							  ?SERVER_NPC_GODDESS ->
								  set_guard_fb_server_npc(NpcType,{?GODDESS_ID,ServerNpcID});
							  ?SERVER_NPC_GUARD ->
								  set_guard_fb_server_npc(NpcType,{?GUARD_ID,ServerNpcID});
							  _ ->
								  ingore
						  end
				  end, PosList).

do_refresh_fb_server_npc_3(NpcTypeID,Tx,Ty,Dir)->    
	Pos = #p_pos{tx = Tx,ty = Ty,dir = Dir},
	do_refresh_fb_server_npc_3(NpcTypeID,Pos).
do_refresh_fb_server_npc_3(NpcTypeID,Pos)->    
	#map_state{mapid=MapID,map_name=MapName} = mgeem_map:get_state(),
	{ok,ServerNpcInfo} = get_server_npc_info(NpcTypeID,MapID,Pos),
	[ServerNpcID] = mod_server_npc:init_map_server_npc(MapName, MapID, [ServerNpcInfo]),
	erlang:send_after(200, self(), {mod,?MODULE,{loop_ms}}),
	ServerNpcID.

get_server_npc_info(GuarderTypeID,MapID,Pos)->
	get_server_npc_info(GuarderTypeID,MapID,Pos,undefined).
get_server_npc_info(GuardTypeID,MapID,Pos,CallerName)->    
	[NpcBaseInfo] = common_config_dyn:find(server_npc, GuardTypeID),
	case CallerName of
		undefined->
			GuarderName = NpcBaseInfo#p_server_npc_base_info.npc_name;
		_ ->
			GuarderName = common_misc:format_lang(<<"~s的守卫">>, [CallerName])
	end,
	ServerNpcInfo = #p_server_npc{
								  %% 使用怪物的id
								  npc_id = mod_map_monster:get_max_monster_id_form_process_dict(),
								  type_id = NpcBaseInfo#p_server_npc_base_info.type_id,
								  npc_name = GuarderName,
								  npc_type = NpcBaseInfo#p_server_npc_base_info.npc_type,
								  npc_kind_id = NpcBaseInfo#p_server_npc_base_info.npc_kind_id,
								  max_mp= NpcBaseInfo#p_server_npc_base_info.max_mp,
								  state = ?FIRST_BORN_STATE,
								  max_hp = NpcBaseInfo#p_server_npc_base_info.max_hp,
								  map_id = MapID,
								  reborn_pos = Pos,
								  level= NpcBaseInfo#p_server_npc_base_info.level,
								  npc_country = NpcBaseInfo#p_server_npc_base_info.npc_country,
								  is_undead = NpcBaseInfo#p_server_npc_base_info.is_undead,
								  move_speed = NpcBaseInfo#p_server_npc_base_info.move_speed
								 },
	{ok,ServerNpcInfo}.

del_guard_fb_server_npc(Key,Value)->
	case get(Key) of
		undefined -> ignore;
		ServerNpcInfoList ->
			put(Key,lists:delete(Value,ServerNpcInfoList))
	end.
set_guard_fb_server_npc(Key,Value)->
	common_misc:update_dict_set(Key,Value).

init_guard_fb_server_npc() ->
	put(?SERVER_NPC_GODDESS,[]),
	put(?SERVER_NPC_GUARD,[]),
	put(?SERVER_NPC_TOWERS,[]).

upgrade_server_npc(ServerNpcID,NextLevelServerNpcTypeID) ->
	case mod_map_actor:get_actor_mapinfo(ServerNpcID, server_npc) of
		undefined ->
			ignore;
		ServerNpcMapInfo ->
			case mod_server_npc:get_server_npc_state(ServerNpcID) of
				undefined ->
					ignore;
				ServerNpcState ->
					#server_npc_state{server_npc_info=ServerNpcInfo} = ServerNpcState,
					[ServerNpcBaseInfo] = common_config_dyn:find(server_npc, NextLevelServerNpcTypeID),
					#p_server_npc_base_info{max_hp=NextMaxHP,max_mp=NextMaxMP,npc_name=NextNpcName,level=NextLevel,
											min_attack=NextMinAttack,max_attack=NextMaxAttack} = ServerNpcBaseInfo,
					ServerNpcMapInfo2 = ServerNpcMapInfo#p_map_server_npc{hp=NextMaxHP,mp=NextMaxMP,
																		  max_hp=NextMaxHP,max_mp=NextMaxMP,
																		  type_id=NextLevelServerNpcTypeID,npc_name=NextNpcName},
					ServerNpcInfo2 = ServerNpcInfo#p_server_npc{hp=NextMaxHP,mp=NextMaxMP,
																level=NextLevel,
																max_hp=NextMaxHP,max_mp=NextMaxMP,
																type_id=NextLevelServerNpcTypeID,npc_name=NextNpcName,
																min_attack=NextMinAttack,max_attack=NextMaxAttack},
					ServerNpcState2 = ServerNpcState#server_npc_state{server_npc_info=ServerNpcInfo2},
					mod_server_npc:set_server_npc_state(ServerNpcID, ServerNpcState2),
					mod_map_actor:set_actor_mapinfo(ServerNpcID, server_npc, ServerNpcMapInfo2)
			end
	end.

%% @doc 设置圣女魔尊洞窟地图信息
set_guard_fb_map_info(GuardFbMapInfo) ->
	erlang:put(?GUARD_FB_MAP_INFO, GuardFbMapInfo).

%% @doc 获取圣女魔尊洞窟地图信息
get_guard_fb_map_info() ->
	case erlang:get(?GUARD_FB_MAP_INFO) of
		undefined ->
			{error, not_found};
		GuardFbMapInfo ->
			{ok, GuardFbMapInfo}
	end.    

%% @interface 进入圣女魔尊洞窟
do_guard_fb_enter({Unique, Module, Method, _DataIn, RoleID, PID, _Line})->
	case catch check_do_guard_fb_enter(RoleID) of
		{ok,RoleGuardFbInfo}->
			do_guard_fb_enter_2(Unique,Module,Method,RoleID,PID,RoleGuardFbInfo);
		{error,ErrCode,Reason}->
			R2 = #m_guard_fb_enter_toc{err_code=ErrCode,reason=Reason},
			?UNICAST_TOC(R2)
	end.

do_guard_fb_enter_2(Unique,Module,Method,RoleID,PID,RoleGuardFbInfo)->
	GuardMapName = get_guard_fb_map_name(RoleID),
	mgeer_role:absend(RoleID, {apply, mod_solo_fb, init, [?GUARD_FB_MAP_ID, GuardMapName]}),
	do_guard_fb_enter_3(Unique, Module, Method, RoleID, PID, RoleGuardFbInfo, GuardMapName).

do_guard_fb_enter_3(_Unique, _Module, _Method, RoleID, _PID, RoleGuardFBInfo, GuardMapName)->
	CurMapID = mgeem_map:get_mapid(),
	case is_guard_fb_map_id(CurMapID) of
		true->
			next;
		false->
			%%第一次进入该副本需要记录位置
			case mod_map_role:get_role_pos_detail(RoleID) of
				{ok,#p_role_pos{pos=Pos}} ->
					NewGuardFbInfo=RoleGuardFBInfo#r_role_guard_fb{last_enter_time=common_tool:now(),
																   enter_pos=Pos,enter_mapid=CurMapID},
					set_role_guard_fb_info(RoleID,NewGuardFbInfo);
				_ ->
					NewGuardFbInfo = RoleGuardFBInfo,
					ignore
			end,
			hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_GUARD_FB),
			mgeer_role:send(RoleID, {apply, hook_mission_event, hook_special_event, [RoleID, ?MISSON_EVENT_GUARD_FB]}),
			%% 初始化圣女魔尊洞窟地图信息
			{ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
			GuardFbMapInfo = #r_guard_fb_map_info{map_role_id=RoleID,role_level=RoleLevel,start_time=common_tool:now(),first_enter=true},
			global:send(GuardMapName, {?MODULE, {init_guard_fb_map_info, GuardFbMapInfo}}),
			%% 传送到新地图
			add_enter_times(RoleID,NewGuardFbInfo,1),
			{_, TX, TY} = common_misc:get_born_info_by_map(?GUARD_FB_MAP_ID),
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, ?GUARD_FB_MAP_ID, TX, TY)
	end.

%% @doc 检查是否可以进入圣女魔尊洞窟
check_do_guard_fb_enter(RoleID) ->
	{ok,RoleMapInfo} = assert_role_mapinfo(RoleID),
	%% 角色状态检测
	#p_map_role{state=RoleState} = RoleMapInfo,
	case RoleState of
		?ROLE_STATE_DEAD ->
			?THROW_ERR( ?ERR_GUARD_FB_ENTER_ROLE_DEAD );
		?ROLE_STATE_STALL ->
			?THROW_ERR( ?ERR_GUARD_FB_ENTER_ROLE_STALL );
		?ROLE_STATE_FIGHT->
			?THROW_ERR( ?ERR_GUARD_FB_ENTER_ROLE_FIGHT );
		_ ->
			ok
	end,
    case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
        true -> 
            ?THROW_ERR(?ERR_OTHER_ERR, ?_LANG_XIANNVSONGTAO_MSG);
        false -> ignore
    end,
	{ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
	assert_role_level(RoleAttr),
	assert_role_jingjie(RoleAttr),
	case mod_horse_racing:is_role_in_horse_racing(RoleID) of
		true ->
			?THROW_ERR( ?ERR_GUARD_FB_ENTER_ROLE_HORSE_RACING );
		_ ->
			ignore
	end,
	{ok,RoleGuardFbInfo} = assert_role_guard_fb(RoleID),
	#r_role_guard_fb{enter_times=EnterTimes,last_enter_time=LastEnterTime,buy_times=BuyTimes,
					 last_buy_time=LastBuyTime} = RoleGuardFbInfo,
	case common_time:is_today(LastEnterTime) of
		true ->
			[MaxEnterTimes] = ?find_config(fb_max_enter_times),
			AddEnterTimes = 
				case common_time:is_today(LastBuyTime) of
					true -> BuyTimes;
					false -> 0
				end,
			case EnterTimes >= (MaxEnterTimes+AddEnterTimes) of
				true ->
					?THROW_ERR(?ERR_GUARD_FB_ENTER_TIMES_LIMITED);
				false ->
					next
			end,
			NewRoleGuardFbInfo = RoleGuardFbInfo;
		_ ->
			NewRoleGuardFbInfo = RoleGuardFbInfo#r_role_guard_fb{enter_times = 0},
			set_role_guard_fb_info(RoleID, NewRoleGuardFbInfo)
	end,
	{ok,NewRoleGuardFbInfo}.

do_guard_fb_info({_Unique, _Module, _Method, _DataIn, RoleID, _PID, _Line})->
	case get_guard_fb_map_info() of
		{ok, GuardFbMapInfo} ->
			cast_guard_fb_info(RoleID,GuardFbMapInfo);
		_ ->
			ingore
	end.

do_guard_fb_buff_item({_Unique, _Module, _Method, _DataIn, RoleID, _PID, _Line})->
	cast_guard_fb_buff_item(RoleID).

do_guard_fb_buy_buff({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
	case catch check_guard_fb_buy_buff(RoleID,DataIn) of
		{ok,MoneyType,BuyBuffID,CostMoney}->
			TransFun = fun()-> 
							   t_deduct_buy_buff_money(MoneyType,CostMoney,RoleID)
					   end,
			case common_transaction:t( TransFun ) of
				{atomic, {ok,RoleAttr2}} ->
					case MoneyType of
						?BUY_BUFF_TYPE_SILVER->
							common_misc:send_role_silver_change(RoleID,RoleAttr2);
						?BUY_BUFF_TYPE_GOLD->
							common_misc:send_role_gold_change(RoleID,RoleAttr2)
					end,
					remove_pve_buff(MoneyType,RoleID),
					RealAddBuffList = fb_buff_mapping(MoneyType,BuyBuffID),
					mod_role_buff:add_buff(RoleID,RealAddBuffList),
					{NextBuffID,_NextCostMoney} = next_can_buy_buff(RoleID,MoneyType),
					R2 = #m_guard_fb_buy_buff_toc{type=MoneyType,next_buff_id=NextBuffID,
												  cost_money=CostMoney};
				{aborted, AbortErr} ->
					{error,ErrCode,Reason} = common_misc:parse_aborted_err(AbortErr),
					R2 = #m_guard_fb_buy_buff_toc{type=MoneyType,err_code=ErrCode,reason=Reason}
			end;
		{error,ErrCode,Reason}->
			R2 = #m_guard_fb_buy_buff_toc{err_code=ErrCode,reason=Reason}
	end,
	?UNICAST_TOC(R2).

check_guard_fb_buy_buff(RoleID,DataIn)->
	#m_guard_fb_buy_buff_tos{type=MoneyType} = DataIn,
	assert_role_mapinfo(RoleID),
	assert_role_in_fb_map(),
	case next_can_buy_buff(RoleID,MoneyType) of
		{0,0} -> %%不能再购买buff
			CostMoney = NextBuffID = null,
			?THROW_ERR( ?ERR_GUARD_FB_NOT_IN_MAP );
		{NextBuffID,CostMoney} ->
			next
	end,
    case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
        true ->
            % ?THROW_ERR( ?ERR_EXAMINE_FB_ILLEGAL_ENTER_MAP )
            ?THROW_ERR(?ERR_OTHER_ERR, ?_LANG_XIANNVSONGTAO_MSG);
        false -> ignore
    end,
	{ok,MoneyType,NextBuffID,CostMoney}.

remove_pve_buff(MoneyType,RoleID) ->
	BuffIDList = pve_buff_mapping_list(MoneyType),
	mod_pve_fb:remove_pve_fb_buffs(RoleID, BuffIDList).

remove_all_pve_buff(RoleID) ->
	GoldBuffIDList = pve_buff_mapping_list(?BUY_BUFF_TYPE_GOLD),
	mod_pve_fb:remove_pve_fb_buffs(RoleID, lists:append([GoldBuffIDList,fb_buff_item_buff_list()])).

pve_buff_mapping_list(MoneyType) ->
	[BuffMapping] = 
		case MoneyType of
			?BUY_BUFF_TYPE_SILVER ->
				?find_config(fb_silver_buff_mapping);
			?BUY_BUFF_TYPE_GOLD ->
				?find_config(fb_gold_buff_mapping)
		end,
	lists:flatten(BuffMapping).

pve_buff_list(MoneyType) ->
	{ok,#r_guard_fb_map_info{role_level=RoleLevel}} = get_guard_fb_map_info(),
	[FbBuffList] = ?find_config(fb_buff_list),
	case lists:keyfind(MoneyType,1,FbBuffList) of
		{MoneyType,LevelBuffList} ->
			case common_tool:find_tuple_section(RoleLevel,LevelBuffList) of
				undefined -> undefined;
				{_,BuffIDList,CostList} ->
					{BuffIDList,CostList}
			end;
		_ ->
			undefined
	end.

%% 副本购买的BUFF实际上添加和删除的buff列表
fb_buff_mapping(MoneyType,BuffID) ->
	[BuffMapping] = 
		case MoneyType of
			?BUY_BUFF_TYPE_SILVER ->
				?find_config(fb_silver_buff_mapping);
			?BUY_BUFF_TYPE_GOLD ->
				?find_config(fb_gold_buff_mapping)
		end,
	case lists:filter(fun(BuffIDList) ->
							  lists:member(BuffID, BuffIDList)
					  end, BuffMapping) of
		[] ->
			?ERROR_MSG("fb_buff_mapping error:~w",[{MoneyType,BuffID}]),
			[BuffID];
		[AddBuffIDList|_] ->
			AddBuffIDList
	end.

%% 玩家可以购买的buffID
%% return {NextBuffID,Cost}
next_can_buy_buff(RoleID,MoneyType) ->
	case pve_buff_list(MoneyType) of
		{BuffIDList,CostList} ->
			case mod_map_role:get_role_base(RoleID) of
				{ok, #p_role_base{buffs=RoleBuffs}}->
					case has_buy_buff_in_role(RoleBuffs,BuffIDList,MoneyType) of
						false->
							{erlang:hd(BuffIDList),erlang:hd(CostList)};
						HasBuyBuffID ->
							case HasBuyBuffID =:= lists:last(BuffIDList) of
								true ->
									{0,0};
								false ->
									Nth = common_tool:index_of_lists(HasBuyBuffID,BuffIDList) + 1,
									{lists:nth(Nth,BuffIDList),lists:nth(Nth,CostList)}
							end
					end;
				_ ->
					?THROW_ERR( ?ERR_GUARD_FB_NOT_IN_MAP )
			end;
		_ ->
			?THROW_ERR( ?ERR_GUARD_FB_BUY_BUFF_INVALID_BUFF )
	end.

%%检查玩家身上是否有指定BuffID列表
%% return false | BuffID
has_buy_buff_in_role(_RoleBuffs,[],_MoneyType)->
	false;
has_buy_buff_in_role(RoleBuffs,[H|T],MoneyType)->
	case lists:keyfind(H, #p_actor_buf.buff_id, RoleBuffs) of
		false->
			has_buy_buff_in_role(RoleBuffs,T,MoneyType);
		_ ->
			case pve_buff_list(MoneyType) of
				undefined ->
					?ERROR_MSG("has_buy_buff_in_role error:~w",[MoneyType]),
					false;
				{BuffIDList,_CostList} ->
					case lists:member(H, BuffIDList) of
						true ->
							H;
						false ->
							has_buy_buff_in_role(RoleBuffs,T,MoneyType)
					end
			end
	end.   

%%扣除钱币/元宝
t_deduct_buy_buff_money(BuyBuffType,DeductMoney,RoleID)->
	case BuyBuffType of
		?BUY_BUFF_TYPE_SILVER->
			MoneyType = silver_any,
			ConsumeLogType = ?CONSUME_TYPE_SILVER_PVE_FB_BUY_BUFF;
		?BUY_BUFF_TYPE_GOLD ->
			MoneyType = gold_any,
			ConsumeLogType = ?CONSUME_TYPE_GOLD_PVE_FB_BUY_BUFF
	end,
	case common_bag2:t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeLogType) of
		{ok,RoleAttr2}->
			{ok,RoleAttr2};
		{error, Reason} ->
			?THROW_ERR(?ERR_OTHER_ERR, Reason);
		_ ->
			?THROW_SYS_ERR()
	end. 

add_buff_item_buff(RoleID,ItemTypeID,RoleLevel) ->
	[BuffItemList] = ?find_config(fb_buff_item),
	case lists:member(ItemTypeID, BuffItemList) of
		true ->
			mod_pve_fb:remove_pve_fb_buffs(RoleID, fb_buff_item_buff_list(ItemTypeID)),
			mod_role_buff:add_buff(RoleID,fb_buff_item_buff_list(ItemTypeID,RoleLevel));
		false ->
			ignore
	end.

fb_buff_item_buff_list() ->
	[BuffItemList] = ?find_config(fb_buff_item),
	lists:foldl(fun(ItemTypeID,Acc) ->
						lists:append([fb_buff_item_buff_list(ItemTypeID),Acc])
				end, [], BuffItemList).
fb_buff_item_buff_list(ItemTypeID) ->
	[BuffItemBuffList] = ?find_config(fb_buff_item_buff_list),
	lists:foldl(fun({TypeID,LevelBuffList},Acc) when ItemTypeID =:= TypeID ->
						lists:append(lists:foldl(fun({_,BuffList},Acc2) ->
														 lists:append([BuffList,Acc2])
												 end, [], LevelBuffList),Acc);
				   (_,Acc) ->
						Acc
				end, [], BuffItemBuffList).
fb_buff_item_buff_list(ItemTypeID,RoleLevel) ->
	[BuffItemBuffList] = ?find_config(fb_buff_item_buff_list),
	lists:foldl(fun({TypeID,LevelBuffList},Acc) when ItemTypeID =:= TypeID ->
						lists:append(lists:foldl(fun({{MinLevel,MaxLevel},BuffList},Acc2) ->
														 case RoleLevel >= MinLevel andalso RoleLevel =< MaxLevel of
															 true ->
																 lists:append([BuffList,Acc2]);
															 false ->
																 Acc2
														 end
												 end, [], LevelBuffList),Acc);
				   (_,Acc) ->
						Acc
				end, [], BuffItemBuffList).

%% 删除所有在副本掉落的buff道具
clear_upgrade_server_npc_item(RoleID) ->
	case ?find_config(fb_delete_server_npc_item) of
		[TypeList] ->
			F = fun(TypeID) ->
						TransFun = fun()-> 
										   mod_bag:delete_goods_by_typeid(RoleID,TypeID)
								   end,
						case common_transaction:t( TransFun ) of
							{atomic, {ok,DeleteList}} ->
								?TRY_CATCH( common_misc:del_goods_notify({direct,RoleID},DeleteList), Err1);
							{aborted, Reason} ->
								?ERROR_MSG("clear_upgrade_server_npc_item error:~w",[Reason])
						end
				end,
			lists:foreach(F, TypeList);
		_ ->
			ignore
	end.

do_guard_fb_summon_tower({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
	#m_guard_fb_summon_tower_tos{id=ID} = DataIn,
	case catch check_guard_fb_summon_tower(RoleID,ID) of
		ok ->
			TransFun = fun()-> 
							   t_guard_fb_summon_tower(RoleID)
					   end,
			case common_transaction:t( TransFun ) of
				{atomic, {ok,RoleAttr2}} ->
					%%召唤无敌箭塔
					[BornTowerNpcConfig] = ?find_config(fb_born_tower_npc),
					{ok,#r_guard_fb_map_info{role_level=RoleLevel}} = get_guard_fb_map_info(),
					{_,GuardTypeID,_NpcType,_UpgradeCost} = common_tool:find_tuple_section(RoleLevel,BornTowerNpcConfig),
					case mod_map_role:get_role_pos(RoleID) of
						{ok, #p_pos{tx=TX, ty=TY, dir=Dir}} ->
							NewTX = TX + common_tool:random(-2,2),
							NewTY = TY + common_tool:random(-2,2);
						_ ->
							NewTX = NewTY = Dir = null,
							?THROW_SYS_ERR()
					end,
					ServerNpcID = do_refresh_fb_server_npc_3(GuardTypeID,NewTX,NewTY,Dir),
					set_guard_fb_server_npc(?SERVER_NPC_TOWERS,{ID,ServerNpcID}),
					common_misc:send_role_gold_change(RoleID,RoleAttr2),
					R2 = #m_guard_fb_summon_tower_toc{npc=p_guard_fb_server_npc({ID,ServerNpcID})},
					ok;
				{aborted, AbortErr} ->
					{error,ErrCode,Reason} = common_misc:parse_aborted_err(AbortErr),
					R2 = #m_guard_fb_summon_tower_toc{err_code=ErrCode,reason=Reason}
			end;
		{error,ErrCode,Reason}->
			R2 = #m_guard_fb_summon_tower_toc{err_code=ErrCode,reason=Reason}
	end,
	?UNICAST_TOC(R2).

check_guard_fb_summon_tower(RoleID,ID)->
	assert_role_mapinfo(RoleID),
	assert_role_in_fb_map(),
	%% 序号规定1-8
	[MaxSummonGuardNum] = ?find_config(fb_max_summon_guard_num),
	case is_integer(ID) andalso ID >= 1 andalso ID =< MaxSummonGuardNum of
		true ->
			next;
		false ->
			?THROW_SYS_ERR()
	end,
	Towers = get(?SERVER_NPC_TOWERS),
	case lists:keyfind(ID, 1, Towers) of
		false ->
			next;
		_ ->
			?THROW_ERR(?ERR_GUARD_FB_HAS_SUMMON_GUARD)
	end,
	case erlang:length(Towers) >= MaxSummonGuardNum of
		true ->
			?THROW_ERR(?ERR_GUARD_FB_SUMMON_GUARD_NUM_LIMIT);
		false ->
			ok
	end.

t_guard_fb_summon_tower(RoleID)->
	[{DeductType,DeductGold}] = ?find_config(fb_call_guard_cost),
	case common_bag2:t_deduct_money(DeductType,DeductGold,RoleID,?CONSUME_TYPE_GOLD_GUARD_FB_SUMMON_GUARD) of
		{ok,RoleAttr2}->
			{ok,RoleAttr2};
		{error, Reason} ->
			?THROW_ERR( ?ERR_OTHER_ERR, Reason )
	end.


do_guard_fb_buy_times({Unique, Module, Method, _DataIn, RoleID, PID, _Line})->
	case catch check_guard_fb_buy_times(RoleID) of
		{ok,RoleGuardFbInfo,MoneyType,CostMoney,BuyTimes} ->
			TransFun = fun()-> 
							   t_guard_fb_buy_times(RoleID,RoleGuardFbInfo,MoneyType,CostMoney,BuyTimes)
					   end,
			case common_transaction:t( TransFun ) of
				{atomic, {ok,RoleAttr2}} ->
					common_misc:send_role_gold_change(RoleID,RoleAttr2),
					R2 = #m_guard_fb_buy_times_toc{},
					ok;
				{aborted, AbortErr} ->
					{error,ErrCode,Reason} = common_misc:parse_aborted_err(AbortErr),
					R2 = #m_guard_fb_buy_times_toc{err_code=ErrCode,reason=Reason}
			end;
		{error,ErrCode,Reason}->
			R2 = #m_guard_fb_buy_times_toc{err_code=ErrCode,reason=Reason}
	end,
	?UNICAST_TOC(R2).

check_guard_fb_buy_times(RoleID)->
	{ok,#p_map_role{vip_level=VipLevel}} = assert_role_mapinfo(RoleID),
	{ok,#r_role_guard_fb{buy_times=BuyTimes,last_buy_time=LastBuyTime}=RoleGuardFbInfo} = assert_role_guard_fb(RoleID),
	[{VipLevelLimit,CanBuyTimes,{MoneyType,CostMoney}}] = ?find_config(fb_buy_times),
	case VipLevel >= VipLevelLimit of
		true ->
			next;
		false ->
			?THROW_ERR_REASON(lists:concat(["VIP",VipLevelLimit,"以上才能购买进入次数"]))
	end,
	case common_time:is_today(LastBuyTime) andalso BuyTimes >= CanBuyTimes of
		true ->
			?THROW_ERR(?ERR_GUARD_FB_BUY_TIMES_MAX_LIMIT);
		false ->
			next
	end,
	{ok,RoleGuardFbInfo,MoneyType,CostMoney,BuyTimes}.

t_guard_fb_buy_times(RoleID,RoleGuardFbInfo,MoneyType,CostMoney,BuyTimes)->
	case common_bag2:t_deduct_money(MoneyType,CostMoney,RoleID,?CONSUME_TYPE_GOLD_GUARD_FB_BUY_TIMES) of
		{ok,RoleAttr2}->
			t_set_role_guard_fb_info(RoleID,RoleGuardFbInfo#r_role_guard_fb{buy_times=BuyTimes+1,last_buy_time=common_tool:now()}),
			{ok,RoleAttr2};
		{error, Reason} ->
			?THROW_ERR( ?ERR_OTHER_ERR, Reason )
	end.

do_guard_fb_buff_item_combine({Unique, Module, Method, _DataIn, RoleID, PID, _Line})->
	case catch check_guard_fb_buff_item_combine(RoleID) of
		ok ->
			TransFun = fun()-> 
							   t_guard_fb_buff_item_combine(RoleID)
					   end,
			case common_transaction:t( TransFun ) of
				{atomic, {ok,DeductGoodsDetail,UpdateList,DeleteList,RewardProp}} ->
					lists:foreach(
					  fun({TypeID,NeedNum}) ->
							  ?TRY_CATCH( common_item_logger:log(RoleID,TypeID,NeedNum,undefined,?LOG_ITEM_TYPE_GUARD_FB_BUFF_ITEM_COMBINE_LOST), Err1)
					  end,DeductGoodsDetail),
					?TRY_CATCH( common_misc:del_goods_notify({role,RoleID},DeleteList), Err2),
					?TRY_CATCH( common_misc:update_goods_notify({role,RoleID},UpdateList), Err3),
					#p_reward_prop{prop_id=TypeID,prop_num=Num} = RewardProp,
					?TRY_CATCH(common_item_logger:log(RoleID,TypeID,Num,undefined,?LOG_ITEM_TYPE_GUARD_FB_BUFF_ITEM_COMBINE)),
					R2 = #m_guard_fb_buff_item_combine_toc{};
				{aborted, AbortErr} ->
					{error,ErrCode,Reason} = common_misc:parse_aborted_err(AbortErr),
					R2 = #m_guard_fb_buff_item_combine_toc{err_code=ErrCode,reason=Reason}
			end;
		{error,ErrCode,Reason}->
			R2 = #m_guard_fb_buff_item_combine_toc{err_code=ErrCode,reason=Reason}
	end,
	?UNICAST_TOC(R2).

check_guard_fb_buff_item_combine(RoleID)->
	assert_role_mapinfo(RoleID),
	assert_role_in_fb_map(),
	ok.

t_guard_fb_buff_item_combine(RoleID)->
	[{DeductGoodsDetail,RewardProp}] = ?find_config(fb_buff_item_combine),
	{ok,UpdateList,DeleteList} = mod_qianghua:t_deduct_material_goods(RoleID,DeductGoodsDetail),
	{ok,RewardGoodsList} = common_bag2:t_reward_prop(RoleID, [RewardProp]),
	{ok,DeductGoodsDetail,lists:append([UpdateList,RewardGoodsList]),DeleteList,RewardProp}.

do_guard_fb_upgrade_server_npc({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
	#m_guard_fb_upgrade_server_npc_tos{op_type=OpType,id=ID,auto_buy=AutoBuy} = DataIn,
	case catch check_guard_fb_upgrade_server_npc(RoleID,OpType,ID,AutoBuy) of
		{ok,CurServerNpcTypeID,NextLevelServerNpcTypeID,ServerNpcID} ->
			TransFun = fun()-> 
							   t_guard_fb_upgrade_server_npc(RoleID,CurServerNpcTypeID,AutoBuy)
					   end,
			case common_transaction:t( TransFun ) of
				{atomic,{ok,NewRoleAttr,DeleteList,UpdateList,DeductGoodsDetail,CostGold}} ->
					lists:foreach(
					  fun({TypeID,NeedNum}) ->
							  ?TRY_CATCH( common_item_logger:log(RoleID,TypeID,NeedNum,undefined,?LOG_ITEM_TYPE_GUARD_FB_UPGRADE_SERVER_NPC_AUTO_BUY_LOST), Err1)
					  end,DeductGoodsDetail),
					?TRY_CATCH( common_misc:del_goods_notify({role,RoleID},DeleteList), Err2),
					?TRY_CATCH( common_misc:update_goods_notify({role,RoleID},UpdateList), Err3),
					case CostGold > 0 of
						true ->
							common_misc:send_role_gold_change(RoleID, NewRoleAttr);
						false -> nil
					end,
					upgrade_server_npc(ServerNpcID,NextLevelServerNpcTypeID),
					R2 = #m_guard_fb_upgrade_server_npc_toc{npc=p_guard_fb_server_npc({ID,ServerNpcID})},
					common_misc:send_role_gold_change(RoleID,NewRoleAttr),
					ok;
				{aborted, AbortErr} ->
					{error,ErrCode,Reason} = common_misc:parse_aborted_err(AbortErr),
					R2 = #m_guard_fb_upgrade_server_npc_toc{err_code=ErrCode,reason=Reason}
			end;
		{error,ErrCode,Reason}->
			R2 = #m_guard_fb_upgrade_server_npc_toc{err_code=ErrCode,reason=Reason}
	end,
	?UNICAST_TOC(R2).



check_guard_fb_upgrade_server_npc(RoleID,OpType,ID,AutoBuy)->
	assert_role_mapinfo(RoleID),
	assert_role_in_fb_map(),
	case OpType of
		?OP_TYPE_GODDESS ->
			NpcType = ?SERVER_NPC_GODDESS,
			case get(?SERVER_NPC_GODDESS) of
				[] ->
					?ERROR_MSG("check_guard_fb_upgrade_server_npc error:~w",[{RoleID,OpType,ID,AutoBuy}]),
					ServerNpcID = null,
					?THROW_SYS_ERR();
				[{_,ServerNpcID}] ->
					next
			end;
		?OP_TYPE_GUARD ->
			NpcType = ?SERVER_NPC_GUARD,
			case get(?SERVER_NPC_GUARD) of
				[] ->
					ServerNpcID = null,
					?THROW_ERR_REASON(<<"圣女护卫已经死亡">>);
				[{_,ServerNpcID}] ->
					next
			end;
		?OP_TYPE_TOWER ->
			NpcType = ?SERVER_NPC_TOWERS,
			CurServerNpcIDList = get(?SERVER_NPC_TOWERS),
			case lists:keyfind(ID, 1, CurServerNpcIDList) of
				false ->
					?ERROR_MSG("check_guard_fb_upgrade_server_npc error:~w",[{RoleID,OpType,ID,AutoBuy}]),
					ServerNpcID = null,
					?THROW_SYS_ERR();
				{_,ServerNpcID} ->
					next
			end;
		_ ->
			ServerNpcID = NpcType = null,
			?ERROR_MSG("check_guard_fb_upgrade_server_npc error:~w",[{RoleID,OpType,ID,AutoBuy}]),
			?THROW_SYS_ERR()
	end,
	case mod_server_npc:get_server_npc_state(ServerNpcID) of
		#server_npc_state{server_npc_info=ServerNpcInfo} ->
			#p_server_npc{type_id=TypeID} = ServerNpcInfo,
			[LevelServerNpcConf] = ?find_config(fb_level_server_npc),
			{ok,#r_guard_fb_map_info{role_level=RoleLevel}} = get_guard_fb_map_info(),
			{_,LevelServerNpcListTmp} = lists:keyfind(NpcType,1,LevelServerNpcConf),
			{_,LevelServerNpcList} = common_tool:find_tuple_section(RoleLevel,LevelServerNpcListTmp),
			Index = common_tool:index_of_lists(TypeID,LevelServerNpcList),
			case Index >= erlang:length(LevelServerNpcList) of
				true ->
					?THROW_ERR(?ERR_GUARD_FB_UPGRADE_SERVER_NPC_FULL_LEVEL);
				false ->
					{ok,lists:nth(Index,LevelServerNpcList),lists:nth(Index+1,LevelServerNpcList),ServerNpcID}
			end;
		_ ->
			?THROW_ERR_REASON(<<"圣女护卫已经死亡">>)
	end.

t_guard_fb_upgrade_server_npc(RoleID,CurServerNpcTypeID,AutoBuy)->
	MaterialList = upgrade_server_npc_material_list(CurServerNpcTypeID),
	{DeductGoodsDetail,NeedCostGoldUnbind,NeedCostGoldAny} = mod_qianghua:get_deduct_goods_detail(RoleID,MaterialList),
	case (NeedCostGoldUnbind > 0 orelse NeedCostGoldAny > 0) andalso AutoBuy =:= false of
		true ->
			?THROW_ERR(?ERR_GUARD_FB_UPGRADE_NOT_ENOUGH_MATERIAL_ITEM);
		false ->
			{ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
			case NeedCostGoldUnbind > 0 of
				true ->
					case common_bag2:t_deduct_money(gold_unbind,NeedCostGoldUnbind,RoleAttr,?CONSUME_TYPE_GOLD_GUARD_FB_UPGRADE_SERVER_NPC_AUTO_BUY) of
						{ok,NewRoleAttr}->
							next;
						{error, Reason1} ->
							NewRoleAttr = RoleAttr,
							?THROW_ERR(?ERR_OTHER_ERR, Reason1)
					end;
				false ->
					NewRoleAttr = RoleAttr
			end,
			case NeedCostGoldAny > 0 of
				true ->
					case common_bag2:t_deduct_money(gold_any,NeedCostGoldAny,NewRoleAttr,?CONSUME_TYPE_GOLD_GUARD_FB_UPGRADE_SERVER_NPC_AUTO_BUY) of
						{ok,NewRoleAttr2}->
							next;
						{error,Reason2}->
							NewRoleAttr2 = NewRoleAttr,
							?THROW_ERR(?ERR_OTHER_ERR, Reason2)
					end;
				false ->
					NewRoleAttr2 = NewRoleAttr
			end,
			mod_map_role:set_role_attr(RoleID, NewRoleAttr2),
			{ok,UpdateList,DeleteList} = mod_qianghua:t_deduct_material_goods(RoleID,DeductGoodsDetail),
			{ok,NewRoleAttr2,DeleteList,UpdateList,DeductGoodsDetail,NeedCostGoldUnbind+NeedCostGoldAny}
	end.

upgrade_server_npc_material_list(ServerNpcTypeID) ->
	[UpgradeServerNpcConf] = ?find_config(fb_upgrade_server_npc),
	case lists:keyfind(ServerNpcTypeID,1,UpgradeServerNpcConf) of
		false ->
			?ERROR_MSG("upgrade_server_npc_material_list ERROR=~w",[ServerNpcTypeID]),
			?THROW_SYS_ERR();
		{_,MaterialList} ->
			MaterialList
	end.

%% @interface 退出圣女魔尊洞窟
do_guard_fb_quit({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
	#m_guard_fb_quit_tos{} = DataIn,
	case catch check_do_guard_fb_quit(RoleID) of
		ok->
			do_guard_fb_quit_2(RoleID, ?guard_fb_quit_type_normal);
		{error,ErrCode,Reason}->
			R2 = #m_guard_fb_quit_toc{err_code=ErrCode,reason=Reason},
			?UNICAST_TOC(R2)
	end.

%% @doc 是否可以退出副本
check_do_guard_fb_quit(_RoleID) ->
	ok.

do_guard_fb_quit_2(RoleID, QuitType) ->
	case QuitType of
		?guard_fb_quit_type_normal -> %% 主动退出
			reward_and_cast_report(false);
		?guard_fb_quit_type_lost -> %% 失败退出
			reward_and_cast_report(false);
		?guard_fb_quit_type_timeout -> %% 在副本超时退出
			reward_and_cast_report(true);
		?guard_fb_quit_type_win -> %% 成功退出
			reward_and_cast_report(true)
	end,
	common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?GUARD_FB,?GUARD_FB_QUIT,#m_guard_fb_quit_toc{}),
	%%得到玩家状态，如果死亡，则在退出副本时候先复活
	case mod_map_actor:get_actor_mapinfo(RoleID,role) of
		#p_map_role{state=?ROLE_STATE_DEAD} ->
			{ok, #p_role_fight{} = RoleFight} = mod_map_role:get_role_fight(RoleID),
			{ok, #p_role_pos{} = RolePos} = mod_map_role:get_role_pos_detail(RoleID),
			mod_role2:relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, RoleID, ?RELIVE_TYPE_ORIGINAL_FREE),
			common_misc:unicast2_direct({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE,
										#m_role2_relive_toc{map_changed = true, role_pos = RolePos, role_fight = RoleFight});
		_ ->
			next
	end,
	%%延时退出
	erlang:send_after(500, self(), {?MODULE, {exit_guard_fb,RoleID}}).

exit_guard_fb(RoleID) ->
	{ok,#r_role_guard_fb{enter_pos=EnterPos,enter_mapid=EnterMapID}} = get_role_guard_fb_info(RoleID),
	do_guard_fb_reward2(RoleID,1),
	case is_record(EnterPos,p_pos) 
			 andalso erlang:is_integer(EnterMapID) 
			 andalso EnterMapID>0 of
		true->
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, EnterMapID, EnterPos#p_pos.tx, EnterPos#p_pos.ty);
		false->
			DestMapId = 10260,
			{_, TX, TY} = common_misc:get_born_info_by_map(DestMapId),
			mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapId, TX, TY)
	end.

hook_role_before_quit(RoleID)->
	case is_in_fb_map() of
		true ->
			clear_upgrade_server_npc_item(RoleID),
			remove_all_pve_buff(RoleID),
			erase(?GUARD_FB_MAP_INFO);
		_ ->
			ignore
	end.

hook_role_level_change(RoleID,RoleLevel) ->
	cast_guard_fb_buff_item(RoleID,RoleLevel).

hook_server_npc_attr_change(Data) ->
	case is_in_fb_map() of
		true ->
			lists:foreach(fun(RoleID) ->
								  common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?SERVER_NPC, ?SERVER_NPC_ATTR_CHANGE, Data)
						  end, mgeem_map:get_all_roleid());
		false ->
			ignore
	end.

hook_role_quit(_RoleID) ->
	do_offline_terminate().
	
hook_role_enter(RoleID,_MapID)->
	case is_in_fb_map() of
		true ->
			mod_role2:modify_pk_mode_for_role(RoleID,?PK_PEACE),
			case get_guard_fb_map_info() of
				%% 第一次进入，进入后扣次数
				{ok, #r_guard_fb_map_info{map_role_id=RoleID,first_enter=true}=GuardFbMapInfo} ->
					%%初始化修改副本的开始/结束时间
					[FbOpenLastTime] = ?find_config(fb_open_max_last_time),
					StartTime =common_tool:now(),
					EndTime = StartTime + FbOpenLastTime,
					NewGuardFbMapInfo = GuardFbMapInfo#r_guard_fb_map_info{start_time=StartTime,end_time=EndTime, first_enter=false},
					set_guard_fb_map_info(NewGuardFbMapInfo),
					clear_timeout_ref(),
					TimerRef = erlang:send_after(FbOpenLastTime*1000, self(), {?MODULE, {fb_timeout_kick}}),
					erlang:put(?GUARD_FB_TIMEOUT_REF, TimerRef);
				%% 下线后再进入，不扣次数
				{ok, _NewGuardFbMapInfo} ->
					common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?GUARD_FB, ?GUARD_FB_ENTER, #m_guard_fb_enter_toc{})
			end,
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?GUARD_FB, ?GUARD_FB_ENTER, #m_guard_fb_enter_toc{});
		false ->
			remove_all_pve_buff(RoleID)
	end.

cast_guard_fb_info(RoleID,GuardFbMapInfo) when is_integer(RoleID)->
	#r_guard_fb_map_info{map_role_id=RoleID,cur_monster_wave=CurMonsterWave,end_time=EndTime,
						 start_time=StartTime,kill_boss_num=KillBossNum,kill_monster_num=KillMonsterNum,
						 next_refresh_time=NextRefreshTime,total_score=TotalScore} = GuardFbMapInfo,
	{NextGoldBuffID,NeedCostGold} = next_can_buy_buff(RoleID,?BUY_BUFF_TYPE_GOLD),
	case get(?SERVER_NPC_GODDESS) of
		[] -> ServerNpcGoddess = undefined;
		[ServerNpcGoddess] -> next
	end,
	case get(?SERVER_NPC_GUARD) of
		[] -> ServerNpcGuard = undefined;
		[ServerNpcGuard] -> next
	end,
	ServerNpcTowers = get(?SERVER_NPC_TOWERS),
	[{_DeductType,DeductGold}] = ?find_config(fb_call_guard_cost),
	[TypeID] = ?find_config(fb_upgrade_server_npc_item),
	{_,ItemCost} = mod_shop:get_goods_price(TypeID),
	case get_role_guard_fb_info(RoleID) of
		{ok,#r_role_guard_fb{enter_times=EnterTimes}} ->
			[MaxEnterTimes] = common_config_dyn:find(guard_fb,fb_max_enter_times),
			RemEnterTimes = MaxEnterTimes - EnterTimes;
		_ ->
			RemEnterTimes = 0
	end,
	
	R2 = #m_guard_fb_info_toc{cur_monster_wave=CurMonsterWave,end_time=EndTime,
							  start_time=StartTime,kill_boss_num=KillBossNum,kill_monster_num=KillMonsterNum,
							  next_refresh_time=NextRefreshTime,total_score=TotalScore,
							  next_gold_buff_id=NextGoldBuffID,need_cost_gold=NeedCostGold,
							  goddess=p_guard_fb_server_npc(ServerNpcGoddess),
							  guard=p_guard_fb_server_npc(ServerNpcGuard),
							  towers=p_guard_fb_server_npc(ServerNpcTowers),
							  buy_tower_cost=DeductGold,
							  item_cost=ItemCost,
							  rem_enter_times= RemEnterTimes
							 },
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?GUARD_FB, ?GUARD_FB_INFO, R2),
	ok.

cast_guard_fb_buff_item(RoleID) ->
	{ok,#p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	cast_guard_fb_buff_item(RoleID,RoleLevel).
cast_guard_fb_buff_item(RoleID,RoleLevel) ->
	case is_in_fb_map() of
		true ->
			[BuffItemList] = ?find_config(fb_buff_item),
			BuffItems = [#p_guard_fb_buff_item{buff_item=ItemTypeID,buffs=fb_buff_item_buff_list(ItemTypeID,RoleLevel)}||ItemTypeID<-BuffItemList],
			R2 = #m_guard_fb_buff_item_toc{buff_items=BuffItems},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?GUARD_FB, ?GUARD_FB_BUFF_ITEM, R2);
		false ->
			ignore
	end.

p_guard_fb_server_npc(undefined) ->
	undefined;
p_guard_fb_server_npc([]) ->
	[];
p_guard_fb_server_npc(ServerNpcList) when is_list(ServerNpcList) ->
	[p_guard_fb_server_npc(ServerNpc)||ServerNpc<-ServerNpcList];
p_guard_fb_server_npc({ID,ServerNpcID}) ->
	#server_npc_state{server_npc_info=ServerNpcInfo} = mod_server_npc:get_server_npc_state(ServerNpcID),
	#p_server_npc{type_id=ServerNpcTypeID,level=Level,npc_name=NpcName,hp=CurHP,max_hp=MaxHP} = ServerNpcInfo,
	NewCurHP =
		case CurHP of
			undefined -> MaxHP;
			_ -> CurHP
		end,
	[{_,LevelUpCostNum,_}|_] = upgrade_server_npc_material_list(ServerNpcTypeID),
	#p_guard_fb_server_npc{id=ID,server_npc_id=ServerNpcID,level=Level,name=NpcName,hp=NewCurHP,max_hp=MaxHP,level_up_cost_num=LevelUpCostNum}.

%% @doc ServerNpc死亡
hook_server_npc_dead(ServerNpcID, ServerNpcTypeID)->
	case is_in_fb_map() of
		true->
			[LevelServerNpcConf] = ?find_config(fb_level_server_npc),
			{_,GoddessConf} = lists:keyfind(goddess,1,LevelServerNpcConf),
			del_guard_fb_server_npc(?SERVER_NPC_GODDESS,{?GODDESS_ID,ServerNpcID}),
			del_guard_fb_server_npc(?SERVER_NPC_GUARD,{?GUARD_ID,ServerNpcID}),
			{ok,#r_guard_fb_map_info{role_level=RoleLevel}} = get_guard_fb_map_info(),
			{_,GoddessList} = common_tool:find_tuple_section(RoleLevel,GoddessConf),
			case lists:member(ServerNpcTypeID, GoddessList) of
				true ->
					guard_lost();
				false ->
					ignore
			end;
		_ ->
			ignore
	end.

%% @doc 怪物死亡
hook_monster_dead(MonsterBaseInfo) ->
	case get_guard_fb_map_info() of
		{ok, GuardFbMapInfo} ->
			#r_guard_fb_map_info{kill_boss_num=KillBossNum,kill_monster_num=KillMonsterNum,
								 total_score=TotalScore} = GuardFbMapInfo,
			#p_monster_base_info{rarity=Rarity,typeid=MonsterTypeID} = MonsterBaseInfo,
			[MonsterScoreConf] = ?find_config(fb_monster_score),
			AddScore = get_monster_score(MonsterTypeID,MonsterScoreConf),
			NewTotalScore=TotalScore+AddScore,
			case Rarity of
				?BOSS ->
					NewKillBossNum = KillBossNum + 1,
					NewKillMonsterNum = KillMonsterNum,
					set_guard_fb_map_info(GuardFbMapInfo#r_guard_fb_map_info{kill_boss_num=NewKillBossNum,total_score=NewTotalScore}),
					?TRY_CATCH(mod_score:gain_score_notify(GuardFbMapInfo#r_guard_fb_map_info.map_role_id,AddScore,?SCORE_TYPE_GUARD,{?SCORE_TYPE_GUARD,"圣殿守护获得积分"})),
					notify_guard_fb_change([?CHANGE_TYPE_KILL_BOSS_NUM,?CHANGE_TYPE_TOTAL_SCORE],[NewKillBossNum,NewTotalScore]);
				_ ->
					NewKillBossNum = KillBossNum,
					NewKillMonsterNum = KillMonsterNum + 1,
					set_guard_fb_map_info(GuardFbMapInfo#r_guard_fb_map_info{kill_monster_num=NewKillMonsterNum,total_score=NewTotalScore}),
					?TRY_CATCH(mod_score:gain_score_notify(GuardFbMapInfo#r_guard_fb_map_info.map_role_id,AddScore,?SCORE_TYPE_GUARD,{?SCORE_TYPE_GUARD,"圣殿守护获得积分"})),
					notify_guard_fb_change([?CHANGE_TYPE_KILL_MONSTER_NUM,?CHANGE_TYPE_TOTAL_SCORE],[NewKillMonsterNum,NewTotalScore])
			end,
			TotalMonsterNum = get(?GUARD_FB_TOTAL_MONSTER_NUM),
			case (NewKillBossNum + NewKillMonsterNum) >= TotalMonsterNum of
				true ->
					guard_win(),
					clear_timeout_ref();
				false ->
					ignore
			end;  
		{error, _} ->
			ignore
	end.

%% 守护失败
guard_lost() ->
	case get_guard_fb_map_info() of
		{ok, #r_guard_fb_map_info{map_role_id=RoleID}} ->
			do_guard_fb_quit_2(RoleID, ?guard_fb_quit_type_lost);
		_ ->
			ignore
	end.
%% 守护成功
guard_win() ->
	case get_guard_fb_map_info() of
		{ok, #r_guard_fb_map_info{map_role_id=RoleID}} ->
			do_guard_fb_quit_2(RoleID, ?guard_fb_quit_type_win);
		_ ->
			ignore
	end.

reward_and_cast_report(IsWin) ->
	case get_guard_fb_map_info() of
		{ok, GuardFbMapInfo} ->
			#r_guard_fb_map_info{map_role_id=RoleID,cur_monster_wave=CurMonsterWave,
								 role_level=Level,
								 start_time=StartTime,kill_boss_num=KillBossNum,kill_monster_num=KillMonsterNum,
								 total_score=TotalScore} = GuardFbMapInfo,
			[ScoreRewardsConf] = ?find_config(fb_score_rewards),
			case score_reward(TotalScore,Level,ScoreRewardsConf) of
				[] ->
					RewardExp=RewardSilver=0,
					RewardItems=[];
				{ok,RewardExp,RewardSilver,RewardItems} ->
					{ok, #r_role_map_ext{role_guard_fb=GuardFbInfo} = ExpInfo} = mod_map_role:get_role_map_ext_info(RoleID),
					NewGuardFbInfo = GuardFbInfo#r_role_guard_fb{reward_score_level = {TotalScore, Level, IsWin}},
					mod_map_role:set_role_map_ext_info(RoleID, ExpInfo#r_role_map_ext{role_guard_fb = NewGuardFbInfo})
			%% 					?TRY_CATCH(mod_map_role:do_add_exp(RoleID,RewardExp),Err1),
			%% 					?TRY_CATCH(reward_money(RoleID,RewardSilver),Err2),
			%% 					?TRY_CATCH(reward_items(RoleID,IsWin,RewardExp,RewardSilver,RewardItems),Err3)
			end,
			case IsWin of
				true ->
					{ok,#p_role_base{role_name=RoleName,faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
					Msg = common_misc:format_lang(<<"~s大显神威，在<a href='event:gotoNpc#~s'><font color=\"#3be450\"><u>圣殿守护</u></font>中成功的守护了圣女！</a>">>, 
												  [common_misc:get_role_name_color(RoleName,FactionID),"10260129"]),
					common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CENTER,?BC_MSG_SUB_TYPE,Msg),
					?WORLD_CHAT_BROADCAST(Msg);
				false ->
					ignore
			end,
			R2 = #m_guard_fb_report_toc{cur_monster_wave=CurMonsterWave,last_time=common_tool:now()-StartTime,
										kill_boss_num=KillBossNum,kill_monster_num=KillMonsterNum,
										total_score=TotalScore,reward_exp=RewardExp,reward_silver=RewardSilver,
										reward_items=RewardItems,is_win=IsWin},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?GUARD_FB, ?GUARD_FB_REPORT, R2);
		_ ->
			ingore
	end.

do_guard_fb_reward({_Unique, _Module, _Method, DataIn, RoleID, _PID, _Line}) ->
	#m_guard_fb_reward_tos{option = Option} = DataIn,
	do_guard_fb_reward2(RoleID,Option).
do_guard_fb_reward2(RoleID,Option) ->	
	{ok, #r_role_map_ext{role_guard_fb = GuardFbInfo}} = mod_map_role:get_role_map_ext_info(RoleID),
	#r_role_guard_fb{reward_score_level = {TotalScore, Level, IsWin}, last_enter_time = LastEnterTime} = GuardFbInfo,
	[ScoreRewardsConf] = ?find_config(fb_score_rewards),
	case score_reward(TotalScore,Level,ScoreRewardsConf) of
		[] ->
			RewardExp = RewardSilver = 0,
			RewardItems = [];
		{ok, RewardExp, _, RewardItems} ->
			RewardSilver = 0,
			[]
	end,
	case common_time:is_today(LastEnterTime) of
		true ->
			case Option of
				0 ->
					ReturnRec = #m_guard_fb_reward_toc{
													   succ = true,
													   option = Option,
													   is_win = IsWin,
													   reward_exp = RewardExp,
													   reward_silver = RewardSilver,
													   reward_item = RewardItems
													  };
				1 ->
					?TRY_CATCH(mod_map_role:do_add_exp(RoleID, RewardExp), Err1),
					?TRY_CATCH(reward_items(RoleID, IsWin, RewardExp, RewardSilver, RewardItems), Err3),
					ReturnRec = #m_guard_fb_reward_toc{
													   succ = true,
													   option = Option,
													   is_win = IsWin,
													   reward_exp = RewardExp,
													   reward_silver = RewardSilver,
													   reward_item = RewardItems
													  }
			end;
		false ->
			ReturnRec = #m_guard_fb_reward_toc{
											   succ = false,
											   err_code = ?ERR_GUARD_FB_CAN_NOT_REWARD
											  }
	end,
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?GUARD_FB, ?GUARD_FB_REWARD, ReturnRec).

add_enter_times(RoleID,GuardFbInfo,AddEnterTimes) ->
	#r_role_guard_fb{enter_times = EnterTimes} = GuardFbInfo,
	NewGuardFbInfo = GuardFbInfo#r_role_guard_fb{enter_times = EnterTimes + AddEnterTimes},
	set_role_guard_fb_info(RoleID,NewGuardFbInfo).

reward_items(_RoleID,_IsWin,_RewardExp,_RewardSilver,RewardItems) when RewardItems =:= [] ->
	ignore;
reward_items(RoleID,IsWin,RewardExp,RewardSilver,RewardItems) ->
	[#p_reward_prop{bind=Bind,prop_id=RewardItemID,prop_num=RewardNum}|_] = RewardItems,
	GoodsCreateInfo = #r_goods_create_info{
										   bag_id=1, 
										   position=1,
										   bind=Bind,
										   type= ?TYPE_ITEM, 
										   type_id= RewardItemID, 
										   start_time=0, 
										   end_time=0,
										   num= RewardNum},
	case mod_bag:create_p_goods(RoleID,GoodsCreateInfo) of
		{ok,GoodsList} ->
			GoodsList2 = [R#p_goods{id = 1} || R <- GoodsList],
			reward_items2(RoleID,IsWin,RewardExp,RewardSilver,GoodsList2);
		{error,Reason}->
			?ERROR_MSG("reward_items,Reason=~w,RoleID=~w,RewardItemID=~w,RewardItemID=~w",[Reason,RoleID,RewardItemID,RewardNum])
	end.
reward_items2(RoleID,IsWin,RewardExp,RewardSilver,[Goods|_]) ->
	Title = <<"守护女神奖励发放">>,
	WinStr = 
		case IsWin of
			true -> "胜利";
			false -> "失败"
		end,
	Text =	common_letter:create_temp(?GUARD_FB_REWARD_LETTER,[WinStr,common_misc:format_silver(RewardSilver),RewardExp]),
	common_letter:sys2p(RoleID,Text,Title,[Goods],14),
	ok.

score_reward(_,_,[]) ->
	[];
score_reward(TotalScore,Level,[{{MinScore,MaxScore},ScoreRewardList}|T]) ->
	if TotalScore >= MinScore andalso MaxScore >= TotalScore ->
		   score_reward2(Level,ScoreRewardList);
	   true ->
		   score_reward(TotalScore,Level,T)
	end.
score_reward2(_,[]) ->
	[];
score_reward2(Level,[{{MinLevel,MaxLevel},RewardExp,RewardSilver,RewardItems}|T]) ->
	if Level >= MinLevel andalso MaxLevel >= Level ->
		   {ok,RewardExp,RewardSilver,RewardItems};
	   true ->
		   score_reward2(Level,T)
	end.

%%达到时间条件，出生怪物
do_born_guard_fb_monster(MonsterList,NextIntervalTime)->
	case get_guard_fb_map_info() of
		{ok,#r_guard_fb_map_info{map_role_id=RoleID,cur_monster_wave=CurMonsterWave,total_score=TotalScore}=GuardFbMapInfo}->
			Now = common_tool:now(),
			[ do_born_guard_fb_monster_2(MonsterParam) ||MonsterParam<-MonsterList ],
			%%更新下次的刷新时间
			NewCurMonsterWave = CurMonsterWave + 1,
			[WaveScoreConf] = ?find_config(fb_wave_score),
			case lists:keyfind(NewCurMonsterWave,1,WaveScoreConf) of
				false -> AddScore = 0;
				{_,AddScore} ->
					next
			end,
			NewTotalScore = TotalScore + AddScore,
			set_guard_fb_map_info(GuardFbMapInfo#r_guard_fb_map_info{next_refresh_time=Now+NextIntervalTime,
																	 cur_monster_wave=NewCurMonsterWave,
																	 total_score=NewTotalScore}),
			?TRY_CATCH(mod_score:gain_score_notify(GuardFbMapInfo#r_guard_fb_map_info.map_role_id,AddScore,?SCORE_TYPE_GUARD,{?SCORE_TYPE_GUARD,"圣殿守护获得积分"})),
			broadcast_monster_wave_num(RoleID,NewCurMonsterWave),
			notify_guard_fb_change([?CHANGE_TYPE_NEXT_REFRESH_TIME,?CHANGE_TYPE_CUR_MONSTER_WAVE,?CHANGE_TYPE_TOTAL_SCORE],
								   [Now+NextIntervalTime,NewCurMonsterWave,NewTotalScore]);
		_ ->
			ignore
	end.

do_born_guard_fb_monster_2( {MonsterTypeId,BornNum,IsBroadcast,PosList} )->
	#map_state{mapid=MapID, map_name=MapProcessName} = mgeem_map:get_state(),
	{ok,MonsterList} = get_born_monster_list(MapID,MonsterTypeId,BornNum,PosList),
	[#p_monster_base_info{monstername = MonsterName}] = cfg_monster:find(MonsterTypeId),
	case IsBroadcast of
		true ->
			lists:foreach(fun(RoleID) ->
								  ?ROLE_OPERATE_BROADCAST(RoleID,lists:concat(["失控的四象·",MonsterName,"，亲自带领精兵前来进攻，请务必小心！"]))
						  end, mod_map_actor:get_in_map_role());
		false ->
			ignore
	end,
	mod_map_monster:init_call_fb_monster(MapProcessName,MapID,MonsterList).

%% 坚持多少波广播
broadcast_monster_wave_num(RoleID,MonsterWave) ->
	[WaveNumList] = ?find_config(fb_broadcast_monster_wave_num),
	case lists:member(MonsterWave, WaveNumList) of
		true ->
			?ROLE_OPERATE_BROADCAST(RoleID,lists:concat(["你已经在圣女守护中坚持了",MonsterWave,"波，接下来的怪物将会更加强大"])),
			case mod_map_role:get_role_base(RoleID) of
				{ok,#p_role_base{role_name=RoleName,faction_id=FactionID}} ->
					Msg = common_misc:format_lang(<<"~s大显神威，在<a href='event:gotoNpc#~s'><font color=\"#3be450\"><u>圣殿守护</u></font></a>中坚持了~w波！">>, 
												  [common_misc:get_role_name_color(RoleName,FactionID),"10260129",MonsterWave]),
					?WORLD_CHAT_BROADCAST(Msg);
				_ ->
					ignore
			end;
		false ->
			ignore
	end.

%%@return {ok,MonsterList}
get_born_monster_list(MapID,MonsterTypeId,BornNum,PosList)->
	BornNumList = lists:seq(1, BornNum),
	MonsterList = 
		lists:foldl(
		  fun({Tx,Ty},AccIn)->
				  Pos = #p_pos{tx=Tx, ty=Ty, dir=1},
				  lists:foldl(
					fun(_Seq,AccInMonster)->
							Monster = #p_monster{reborn_pos=Pos,
												 monsterid=mod_map_monster:get_max_monster_id_form_process_dict(),
												 typeid=MonsterTypeId,
												 mapid=MapID},
							[Monster|AccInMonster]
					end, AccIn, BornNumList)
		  end, [], PosList),
	{ok,MonsterList}.

%%@doc 副本的个人信息更改
notify_guard_fb_change(ChangeTypeList,ValueList)->
	RoleIDList = mod_map_actor:get_in_map_role(),
	lists:foreach(
	  fun(RoleID) ->
			  R2 = #m_guard_fb_change_toc{change_type=ChangeTypeList,value=ValueList},
			  common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?GUARD_FB, ?GUARD_FB_CHANGE, R2)
	  end, RoleIDList).

%%@doc 获取玩家的圣女魔尊洞窟数据
get_role_guard_fb_info(RoleID)->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{role_guard_fb=GuardFbInfo}} when is_record(GuardFbInfo,r_role_guard_fb)->
			{ok,GuardFbInfo};
		_ ->
			{error,not_found}
	end.

%%@doc 事务外设置玩家的圣女魔尊洞窟数据
set_role_guard_fb_info(RoleID, NewGuardFbInfo) when is_record(NewGuardFbInfo,r_role_guard_fb) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{}=RoleMapExt}->
			mod_map_role:set_role_map_ext_info(RoleID, RoleMapExt#r_role_map_ext{role_guard_fb=NewGuardFbInfo});
		_ ->
			?THROW_SYS_ERR()
	end.

t_set_role_guard_fb_info(RoleID, NewGuardFbInfo) when is_record(NewGuardFbInfo,r_role_guard_fb) ->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{}=RoleMapExt}->
			mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt#r_role_map_ext{role_guard_fb=NewGuardFbInfo});
		_ ->
			?THROW_SYS_ERR()
	end.

%% --------------------------------------------------------------------
%%% 内部二级函数
%% --------------------------------------------------------------------
is_guard_fb_map_id(DestMapID)->
	?GUARD_FB_MAP_ID =:= DestMapID.

assert_role_mapinfo(RoleID) ->
	case mod_map_actor:get_actor_mapinfo(RoleID, role) of
		undefined ->
			?THROW_SYS_ERR();
		RoleMapInfo ->
			{ok,RoleMapInfo}
	end.

assert_role_in_fb_map() ->
	case is_in_fb_map() of
		true->
			next;
		_ ->
			?THROW_ERR( ?ERR_GUARD_FB_NOT_IN_MAP )
	end.

assert_role_level(RoleAttr)->
	#p_role_attr{level=RoleLevel} = RoleAttr,
	[MinRoleLevel] = ?find_config(fb_min_role_level),
	if
		MinRoleLevel>RoleLevel->
			?THROW_ERR( ?ERR_GUARD_FB_ENTER_MIN_LV_LIMITED );
		true->
			next
	end,
	ok.

assert_role_jingjie(RoleAttr)->
	#p_role_attr{jingjie=Jingjie} = RoleAttr,
	[MinRoleTitle] = ?find_config(fb_min_role_jingjie),
	if
		MinRoleTitle>Jingjie->
			?THROW_ERR( ?ERR_GUARD_FB_ENTER_MIN_JINGJIE_LIMITED );
		true->
			next
	end,
	ok.

assert_role_guard_fb(RoleID) ->
	case get_role_guard_fb_info(RoleID) of
		{ok, RoleGuardFbInfo} ->
			{ok,RoleGuardFbInfo};
		_ ->
			?THROW_SYS_ERR()
	end.


get_monster_score(_MonsterTypeID,[]) ->
	0;
get_monster_score(MonsterTypeID,[H|T]) ->
	{MonsterTypeIDList,Score} = H,
	case lists:member(MonsterTypeID,MonsterTypeIDList) of
		true -> Score;
		false ->
			get_monster_score(MonsterTypeID,T)
	end.

fb_total_monster_num(FbBornMonsterList) ->
	lists:foldl(fun({_,_,BornMonsterList},Acc0) ->
						lists:foldl(fun({_,BornNum,_,PosList},Acc1) ->
											BornNum*length(PosList)+Acc1
									end, 0, BornMonsterList)+Acc0
				end, 0, FbBornMonsterList).

fb_born_monster(RoleLevel) ->
	[FbBornMonsterList] = ?find_config(fb_born_monster),
	fb_born_monster2(RoleLevel,FbBornMonsterList).
fb_born_monster2(_,[]) ->
	[];
fb_born_monster2(RoleLevel,[{{MinLevel,MaxLevel},MonsterList}|T]) ->
	if RoleLevel >= MinLevel andalso MaxLevel >= RoleLevel ->
		   MonsterList;
	   true ->
		   fb_born_monster2(RoleLevel,T)
	end.

