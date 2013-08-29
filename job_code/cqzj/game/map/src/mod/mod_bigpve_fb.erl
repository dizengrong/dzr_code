%%% @author fsk 
%%% @doc
%%%     封魔殿副本模块
%%% @end
%%% Created : 2012-5-24
%%%-------------------------------------------------------------------
-module(mod_bigpve_fb).

-include("mgeem.hrl").

-export([
			handle/1,
			handle/2
		]).

-export([
			init/2,
			loop/2,
			is_fb_map_id/1,
			is_in_bigpve_map/0,
			is_role_in_map/0,
			assert_valid_map_id/1,
			get_map_name_to_enter/1,set_map_enter_tag/2,
			clear_map_enter_tag/1,
			relive_deduct_gold/0,
			get_monster_role_born_points/1,
			monster_dead_reward_conf/3,
			get_material_num_in_bag/1,
			look_monsterInfo/1
		]).
-export([
			hook_monster_dead/6,
			hook_role_quit/1,
			hook_role_before_quit/1,
			hook_role_enter/2,
			hook_role_dead/3,
			hook_monster_reduce_hp/5,
			hook_use_bomb/1
		]).

-export([
			gm_open_battle/1,
			gm_close_battle/0,
			gm_reset_open_times/0
		]).

%% ====================================================================
%% Macro
%% ====================================================================
-define(BUY_BUFF_TYPE_SILVER,1).
-define(BUY_BUFF_TYPE_GOLD,2).
-define(BIGPVE_MAP_ID,10503).
-define(BATTLE_RANK_LEN,5).
-define(BIGPVE_MAP_NAME_TO_ENTER,bigpve_map_name_to_enter).
-define(BIGPVE_ENTRANCE_INFO,bigpve_entrance_info).

%% 加经验间隔
-define(INTERVAL_EXP_LIST, interval_exp_list).

-define(BIGPVE_MAP_INFO,bigpve_map_info).
-define(BIGPVE_TIME_DATA,bigpve_time_data).
-define(ENTER_TYPE_VIP, 2).
-define(T_BIGPVE_INFO, t_bigpve_info).
-define(MONSTER_HP_BROADCAST_FLAG,broadcast_flag).

-record(r_bigpve_entrance_info,{is_opening=false,map_role_num=0}).

%% score_list=[{monster_id,[{role_id,total_reduce_hp}]}]
%% rank_data=[{role_id,total_score}]
%% bomb_list=[{role_id,use_num}]
%% exp_reward_list=[{role_id,total_reward_exp}]
%% prestige_reward_list=[{role_id,total_reward_prestige}]
%% killer_list=[{role_id,kill_num}]
-record(r_bigpve_map_info,{is_opening=false,role_born_list=[],cur_role_list=[],max_role_num=0,score_list=[],rank_data=[],
						   bomb_list=[],exp_reward_list=[],prestige_reward_list=[],killer_list=[]}).

-record(r_bigpve_time,{date = 0,start_time = 0,end_time = 0,
                                 next_bc_start_time = 0,next_bc_end_time = 0,next_bc_process_time = 0,
                                 before_interval = 0,close_interval = 0,process_interval = 0}).
-define(CONFIG_NAME,bigpve).
-define(find_config(Key),common_config_dyn:find(?CONFIG_NAME,Key)).

%% 对应的活动ID, 与activity_notice.config里的一致
-define(BIGPVE_ACTIVITY_ID,10024).


%% ====================================================================
%% Error Code
%% ====================================================================

-define(ERR_BIGPVE_DISABLE,106999).
-define(ERR_BIGPVE_ENTER_CLOSING,106001).
-define(ERR_BIGPVE_ENTER_LV_LIMIT,106002).
-define(ERR_BIGPVE_ENTER_FB_LIMIT,106003).
-define(ERR_BIGPVE_ENTER_FAMILY_LIMIT,106004).
-define(ERR_BIGPVE_ENTER_FACTION_LIMIT,106005).
-define(ERR_BIGPVE_ENTER_IN_BATTLE,106006).
-define(ERR_BIGPVE_ENTER_MAX_ROLE_NUM,106007).
-define(ERR_BIGPVE_QUIT_NOT_IN_MAP,106010).
-define(ERR_BIGPVE_BUY_BUFF_CD_TIME,106011).
-define(ERR_BIGPVE_BUY_BUFF_EXISTS,106012).
-define(ERR_BIGPVE_BUY_BUFF_NOT_IN_MAP,106013).
-define(ERR_BIGPVE_BUY_BUFF_INVALID_BUFF,106014).
-define(ERR_BIGPVE_BUY_BUFF_SILVER_NOT_ENOUGH,106015).
-define(ERR_BIGPVE_BUY_BUFF_GOLD_NOT_ENOUGH,106016).
-define(ERR_BIGPVE_ENTER_VIP_LIMIT,11007).


%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).

handle({_, ?BIGPVE, ?BIGPVE_ENTER,_,_,_,_}=Info) ->
    %% 进入国家战场
    do_bigpve_enter(Info);
handle({_, ?BIGPVE, ?BIGPVE_QUIT,_,_,_,_}=Info) ->
    %% 退出国家战场
    do_bigpve_quit(Info);
handle({_, ?BIGPVE, ?BIGPVE_BUY_BUFF,_,_,_,_}=Info) ->
    %% 退出国家战场
    do_bigpve_buy_buff(Info);

handle({req_bigpve_entrance_info}) ->
    do_req_bigpve_entrance_info();
handle({init_bigpve_entrance_info,EntranceInfo}) ->
    do_init_bigpve_entrance_info(EntranceInfo);
handle({update_bigpve_entrance_info,ValList}) ->
    do_update_bigpve_entrance_info(ValList);
handle({init_bigpve_monster}) ->
    do_init_bigpve_monster();
handle({check_init_bigpve_monster}) ->
    check_init_bigpve_monster();
handle({reborn_bigpve_monster,MonsterID,MonsterTypeID,Pos}) ->
    do_reborn_bigpve_monster(MonsterID,MonsterTypeID,Pos);
handle({kick_all_roles}) ->
    do_kick_all_roles();
handle({remove_buff,RoleID}) ->
	remove_pve_buff(RoleID);
handle({add_role_score,MonsterID,RoleID,ReduceHP}) ->
    do_add_role_score(MonsterID,RoleID,ReduceHP);
handle({rank_data}) ->
	case is_opening_battle() of
		true->
			case get_bigpve_map_info() of
				#r_bigpve_map_info{cur_role_list=CurRoleList,score_list=ScoreList}=BattleMapInfo ->
					RankData = do_rank_data(CurRoleList,ScoreList),
					set_bigpve_map_info(BattleMapInfo#r_bigpve_map_info{rank_data=RankData}),
					erlang:send_after(10000, self(), {mod,?MODULE,{rank_data}});
				_ ->
					nil
			end;
		false ->
			nil
	end;
%% 结束后60秒更新战力排行榜
handle({update_fighting_power_rank}) ->
	?TRY_CATCH(global:send(mgeew_ranking,{rank,ranking_fighting_power}));

handle({gm_reset_open_times}) ->
    reset_battle_open_times();
handle({gm_open_battle, Second}) ->
    case is_opening_battle() of
        true->
            ignore;
        _ ->
            gm_open_bigpve(Second)
    end;
handle({gm_close_battle}) ->
    case is_opening_battle() of
        true->
            TimeData = get_bigpve_time_data(),
            TimeData2 = TimeData#r_bigpve_time{end_time=common_tool:now()},
            put(?BIGPVE_TIME_DATA,TimeData2),
            
            ok;
        _ ->
            ignore
    end;

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).


init(MapId, _MapName) ->
    case is_fb_map_id(MapId) of
        true->
			ets:new(?MODULE, [named_table,public]),
			ets:new(?T_BIGPVE_INFO, [named_table,public]),
            BattleMapInfo = #r_bigpve_map_info{is_opening=false,max_role_num=0,cur_role_list=[],rank_data=[],bomb_list=[],
											   exp_reward_list=[],prestige_reward_list=[],killer_list=[]},
            set_bigpve_map_info(BattleMapInfo),
			clear_broadcast_flag(),
            reset_battle_open_times(),
            ok;
        _ ->
            ignore
    end.

get_bigpve_entrance_info()->
    get(?BIGPVE_ENTRANCE_INFO).

get_bigpve_time_data()->
    get(?BIGPVE_TIME_DATA).
set_bigpve_time_data(TimeData2)->
    put(?BIGPVE_TIME_DATA,TimeData2).

get_bigpve_map_info()->
	case ets:lookup(?T_BIGPVE_INFO, ?BIGPVE_MAP_INFO) of
		[{_,Value}] ->
			Value;
		_ ->
			undefined
	end.
set_bigpve_map_info(BattleMapInfo)->
	ets:insert(?T_BIGPVE_INFO, {?BIGPVE_MAP_INFO,BattleMapInfo}).

loop(_MapId,NowSeconds) ->
    case get_bigpve_time_data() of
        #r_bigpve_time{date=Date} = NationBattleTimeData ->
            case Date =:= erlang:date() of
                true->
                    loop_2(NowSeconds,NationBattleTimeData);
                _->
                    ignore
            end;
        _ ->
            ignore
    end.
loop_2(NowSeconds,NationBattleTimeData)->
    case ?find_config(enable_bigpve) of
        [true]->
            case is_opening_battle() of
                true->
                    loop_opening(NowSeconds,NationBattleTimeData);
                _ ->
                    loop_closing(NowSeconds,NationBattleTimeData)
            end;
        _ ->
            ignore
    end.


loop_opening(NowSeconds,NationBattleTimeData)->
    #r_bigpve_time{end_time=EndTime} = NationBattleTimeData,
    %% 副本开启过程中广播处理
    do_fb_open_process_broadcast(NowSeconds,NationBattleTimeData),
    if
        EndTime>0 andalso NowSeconds>=EndTime->
            %% 关闭副本
            close_bigpve(),
			
            %% 活动关闭消息的提示
            common_activity:notfiy_activity_end(?BIGPVE_ACTIVITY_ID),
            ok;
        true->
            %% 加经验循环
            case ?find_config(fb_add_exp) of
                [{true,_}]->
                    do_add_exp_interval(NowSeconds);
                _ ->
                    ignore
            end,
            
            %%提前关闭广播
            ignre
    end.

loop_closing(NowSeconds,NationBattleTimeData)->
    #r_bigpve_time{start_time=StartTime, end_time=EndTime} = NationBattleTimeData,
    if
        StartTime>0 andalso NowSeconds>=StartTime->
            open_bigpve();
        true->
            %% 活动开始消息通知
            common_activity:notfiy_activity_start({?BIGPVE_ACTIVITY_ID, NowSeconds, StartTime, EndTime}),
            %%提前开始广播
            do_fb_open_before_broadcast(NowSeconds,NationBattleTimeData)
    end.

assert_valid_map_id(DestMapID)->
    case is_fb_map_id(DestMapID) of
        true->
            ok;
        _ ->
            ?ERROR_MSG("严重，试图进入错误的地图,DestMapID=~w",[DestMapID]),
            throw({error,error_map_id,DestMapID})
    end.

is_fb_map_id(DestMapId)->
	DestMapId =:= ?BIGPVE_MAP_ID.

is_role_in_map()->
	case mgeem_map:get_mapid() of
		?BIGPVE_MAP_ID ->
			true;
		_ ->
			false
	end.
is_in_bigpve_map() ->
	case get_bigpve_map_info() of
        #r_bigpve_map_info{is_opening=true}->
            true;
        _ ->
            false
    end.

%% 玩家跳转进入战场地图进程
get_map_name_to_enter(RoleID)->
    case get({?BIGPVE_MAP_NAME_TO_ENTER,RoleID}) of
        {_RoleID,FbMapProcessName}->
            FbMapProcessName;
        _ ->
            undefined
    end.

clear_map_enter_tag(RoleID)->
    erlang:erase({?BIGPVE_MAP_NAME_TO_ENTER,RoleID}).

set_map_enter_tag(RoleID,BattleMapName)->
    Val = {RoleID,BattleMapName},
    put({?BIGPVE_MAP_NAME_TO_ENTER,RoleID},Val).

clear_broadcast_flag() ->
	erlang:put(?MONSTER_HP_BROADCAST_FLAG, []).

clear_broadcast_flag(MonsterID) ->
	case get_broadcast_flag() of
		undefined ->
			ignore;
		MonsterList ->
			NewList = lists:delete(MonsterID, MonsterList),
			erlang:put(?MONSTER_HP_BROADCAST_FLAG, NewList)
	end.
set_broadcast_flag(MonsterID) ->
	erlang:put(?MONSTER_HP_BROADCAST_FLAG, [MonsterID|lists:delete(MonsterID, get_broadcast_flag())]).
get_broadcast_flag() ->
	erlang:get(?MONSTER_HP_BROADCAST_FLAG).
	

monster_lower_hp_notify(RoleID,MonsterID,CurHP,MaxHP) ->
	[Pre] = ?find_config(fb_monster_lower_hp_notify),
	case CurHP =< (MaxHP * Pre div 100) andalso CurHP > 0 andalso lists:member(MonsterID, get_broadcast_flag()) of
		true ->
			set_broadcast_flag(MonsterID),
			mgeem_map:do_broadcast_insence_include([{role,RoleID}],?BIGPVE,?BIGPVE_LOWER_HP_NOTIFY,
												   #m_bigpve_lower_hp_notify_toc{monster_id=MonsterID},mgeem_map:get_state());
		false ->
			nil
	end.

do_add_role_score(MonsterID,RoleID,ReduceHP) when ReduceHP >0 ->
	case get_bigpve_map_info() of
		#r_bigpve_map_info{is_opening=true,score_list=ScoreList}=BattleMapInfo->
			NewScoreList = 
				case lists:keyfind(MonsterID,1,ScoreList) of
					false ->
						[{MonsterID,[{RoleID,ReduceHP}]}|ScoreList];
					{MonsterID,MonsterScoreList} ->
						NewMonsterScoreList = lists_add_key_value(RoleID,MonsterScoreList,ReduceHP),
						lists:keyreplace(MonsterID, 1, ScoreList,{MonsterID,NewMonsterScoreList})
				end,
			set_bigpve_map_info(BattleMapInfo#r_bigpve_map_info{score_list=NewScoreList});
		_ ->
			ignore
	end;
do_add_role_score(_MonsterID,_RoleID,_ReduceHP) ->
	ignore.

%% @doc 怪物死亡
hook_monster_dead(KillerRoleID,MonsterID,MonsterTypeID,MaxHP,MonsterName,Pos)->
	case mgeem_map:get_mapid() of
		?BIGPVE_MAP_ID ->
			case get_bigpve_map_info() of
		        #r_bigpve_map_info{is_opening=true}=BattleMapInfo->
		    		[BornInterval] = ?find_config(fb_monster_born_interval),
		            [FbMonsterList] = ?find_config(fb_monster_list),
		            NewMonsterTypeID = common_tool:random_element( FbMonsterList ),
		            erlang:send_after(BornInterval*1000, self(), {mod,?MODULE,{reborn_bigpve_monster,MonsterID,NewMonsterTypeID,Pos}}),
					delete_monster(MonsterID),
					clear_broadcast_flag(MonsterID),
		            monster_dead_reward(KillerRoleID,MonsterID,MonsterTypeID,MaxHP,MonsterName,BattleMapInfo);
		        _ ->
		            ignore
		    end;
		_ ->
			ignore
	end.

hook_role_enter(RoleID,MapID) when MapID == ?BIGPVE_MAP_ID->
   case get_bigpve_map_info() of
       #r_bigpve_map_info{is_opening=true}=BattleMapInfo->
           hook_role_enter_2(RoleID,BattleMapInfo);
       _ ->
		   {NewMapID, TX, TY} = common_map:get_map_return_pos_of_jingcheng(RoleID),
		   mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, NewMapID, TX, TY)
   end;
hook_role_enter(RoleID,_) ->
	mgeer_role:absend(RoleID, {?MODULE,{remove_buff,RoleID}}),
	ignore.

hook_role_enter_2(RoleID,BattleMapInfo)->
    case BattleMapInfo of
        #r_bigpve_map_info{is_opening=true,score_list=ScoreList,cur_role_list=CurRoleList,max_role_num=MaxRoleNum,
						   rank_data=RankData}->
            mod_role2:modify_pk_mode_for_role(RoleID,?PK_PEACE),

			NewCurRoleList = [RoleID|lists:delete(RoleID,CurRoleList)],
            NewRoleNum = length(NewCurRoleList),
            NewMaxRoleNum = erlang:max(MaxRoleNum,NewRoleNum),
            
			NewBattleMapInfo = BattleMapInfo#r_bigpve_map_info{cur_role_list=NewCurRoleList,max_role_num=NewMaxRoleNum},
            %%同步入口信息
			set_bigpve_map_info(NewBattleMapInfo),
            
			req_bigpve_entrance_info(),
			
            %%发送副本的信息
            case get_bigpve_time_data() of
                #r_bigpve_time{start_time = StartTime,end_time = EndTime} ->
                    next;
                _ ->
                    StartTime = 0,EndTime = 0
            end,
            %% 插入加经验列表
            insert_interval_exp_list(RoleID),

			{NextSilverBuffID,NeedCostSilver} = next_can_buy_buff(RoleID,?BUY_BUFF_TYPE_SILVER),
			{NextGoldBuffID,NeedCostGold} = next_can_buy_buff(RoleID,?BUY_BUFF_TYPE_GOLD),
			common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?BIGPVE,?BIGPVE_ENTER,#m_bigpve_enter_toc{}),
            R1 = #m_bigpve_info_toc{fb_start_time=StartTime,fb_end_time=EndTime,
									next_silver_buff_id=NextSilverBuffID,need_cost_silver=NeedCostSilver,
									next_gold_buff_id=NextGoldBuffID,need_cost_gold=NeedCostGold},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?BIGPVE, ?BIGPVE_INFO, R1),
			send_role_rank(RoleID,ScoreList,RankData),
            ok;
        _ ->
            do_bigpve_quit_2(RoleID),
            ?ERROR_MSG("副本关闭了，还有人进来！RoleID=~w",[RoleID])
    end.

hook_role_quit(RoleID)->
    case get_bigpve_map_info() of
        #r_bigpve_map_info{is_opening=true,cur_role_list=CurRoleList}=MapInfo->
            NewCurRoleList = lists:delete(RoleID,CurRoleList),
            set_bigpve_map_info(MapInfo#r_bigpve_map_info{cur_role_list=NewCurRoleList}),
			req_bigpve_entrance_info(),
            %% 移出加经验列表
            delete_interval_exp_list(RoleID),
            ok;
        _ ->
            ignore
    end.

hook_role_before_quit(RoleID)->
	case get_bigpve_map_info() of
	#r_bigpve_map_info{is_opening=true} ->
		mgeer_role:absend(RoleID, {?MODULE,{remove_buff,RoleID}});
	_ ->
		ignore
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

hook_monster_reduce_hp(MonsterID,RoleID,ReduceHP,CurHP,MaxHP) ->
	MapID = mgeem_map:get_mapid(),
	case is_fb_map_id(MapID) of
		true ->
		    do_add_role_score(MonsterID,RoleID,ReduceHP),
			monster_lower_hp_notify(RoleID,MonsterID,CurHP,MaxHP);
		false ->
			nil
	end.

hook_use_bomb(RoleID) ->
	case get_bigpve_map_info() of
		#r_bigpve_map_info{bomb_list=BombList}=BattleMapInfo->
			NewBombList = lists_add_key_value(RoleID,BombList,1),
			set_bigpve_map_info(BattleMapInfo#r_bigpve_map_info{bomb_list=NewBombList});
		_ ->
			nil
	end.

hook_role_dead(_DeadRoleID, _SActorID, _SActorType)->
    ok.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_bigpve_enter({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_bigpve_enter_tos{enter_type=EnterType} = DataIn,
    case catch check_bigpve_enter(RoleID,DataIn) of
        {ok,MapID} ->
            do_bigpve_enter_2(RoleID,MapID);
        {error,ErrCode,Reason}->
            R2 = #m_bigpve_enter_toc{enter_type=EnterType,err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.
    
do_bigpve_enter_2(RoleID,MapID)->
	{ok,_MonsterList,RoleBornList} = get_monster_role_born_points(MapID),
	%%地图跳转
	FBMapId = ?BIGPVE_MAP_ID,
	FBMapName = common_map:get_common_map_name(FBMapId),
	{Tx,Ty} = common_tool:random_element(RoleBornList),
	set_map_enter_tag(RoleID,FBMapName),
	mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL,RoleID, FBMapId, Tx, Ty).

do_bigpve_quit({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
	case catch check_bigpve_quit(RoleID,DataIn) of
		ok->
			do_bigpve_quit_2(RoleID);
		{error,ErrCode,Reason}->
			R2 = #m_bigpve_quit_toc{err_code=ErrCode,reason=Reason},
			?UNICAST_TOC(R2)
	end.

do_bigpve_quit_2(RoleID)->
	case mod_map_actor:get_actor_mapinfo(RoleID,role) of
		#p_map_role{state=?ROLE_STATE_DEAD}->%%死亡状态
			mod_role2:relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, RoleID, ?RELIVE_TYPE_ORIGINAL_FREE);
		_ ->
			ignore
	end,
	mgeer_role:absend(RoleID, {?MODULE,{remove_buff,RoleID}}),
	common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?BIGPVE,?BIGPVE_QUIT,#m_bigpve_quit_toc{}),
	{DestMapId,TX,TY} = common_map:get_map_return_pos_of_jingcheng(RoleID),
	mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapId, TX, TY),
	ok.


do_bigpve_buy_buff({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    case catch check_bigpve_buy_buff(RoleID,DataIn) of
        {ok,MoneyType,BuyBuffID,CostMoney}->
			TransFun = fun()-> 
							   %%优先扣除抵用卷
							   {NewCostMoney,UpList,DelList,VoucherNum,VoucherTypeID} = t_deduct_buy_buff_item(MoneyType,CostMoney,RoleID),
							   case NewCostMoney > 0 of
								   true ->
									   {ok,RoleAttr} = t_deduct_buy_buff_money(MoneyType,NewCostMoney,RoleID);
								   false ->
									   RoleAttr = undefined
							   end,
							   {ok,NewCostMoney,UpList,DelList,RoleAttr,VoucherNum,VoucherTypeID}
					   end,
            case common_transaction:t( TransFun ) of
                {atomic, {ok,NewCostMoney,UpList,DelList,RoleAttr2,VoucherNum,VoucherTypeID}} ->
					case NewCostMoney > 0 andalso RoleAttr2 =/= undefined of
						true ->
							case MoneyType of
								?BUY_BUFF_TYPE_SILVER->
									common_misc:send_role_silver_change(RoleID,RoleAttr2);
								?BUY_BUFF_TYPE_GOLD->
									common_misc:send_role_gold_change(RoleID,RoleAttr2)
							end;
						false ->
							nil
					end,
					common_misc:del_goods_notify(PID,DelList),
					common_misc:update_goods_notify(PID,UpList),
					remove_pve_buff(MoneyType,RoleID),
					RealAddBuffList = fb_buff_mapping(MoneyType,BuyBuffID),
					mod_role_buff:add_buff(RoleID,RealAddBuffList),
					{NextBuffID,_NextCostMoney} = next_can_buy_buff(RoleID,MoneyType),
					case VoucherNum > 0 of
						true ->
							?TRY_CATCH( common_item_logger:log(RoleID,VoucherTypeID,VoucherNum,undefined,?LOG_ITEM_TYPE_BIGPVE_VOUCHER_LOST) );
						false ->
							nil
					end,
                    R2 = #m_bigpve_buy_buff_toc{type=MoneyType,next_buff_id=NextBuffID,
												cost_money=NewCostMoney,voucher_num=VoucherNum};
                {aborted, AbortErr} ->
                    {error,ErrCode,Reason} = common_misc:parse_aborted_err(AbortErr),
                    R2 = #m_bigpve_buy_buff_toc{type=MoneyType,err_code=ErrCode,reason=Reason}
            end;
        {error,ErrCode,Reason}->
            R2 = #m_bigpve_buy_buff_toc{err_code=ErrCode,reason=Reason}
    end,
	
    ?UNICAST_TOC(R2).

check_bigpve_buy_buff(RoleID,DataIn)->
    #m_bigpve_buy_buff_tos{type=MoneyType} = DataIn,
    case is_role_in_map() of
        true->
            next;
        _ ->
            ?THROW_ERR( ?ERR_BIGPVE_BUY_BUFF_NOT_IN_MAP )
    end,
%%    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
%%        #p_map_role{}->
%%            next;
%%        _ ->
%%            ?THROW_ERR( ?ERR_BIGPVE_BUY_BUFF_NOT_IN_MAP )
%%    end,
	case next_can_buy_buff(RoleID,MoneyType) of
		{0,0} -> %%不能再购买buff
            CostMoney = NextBuffID = null,
            ?THROW_ERR( ?ERR_BIGPVE_BUY_BUFF_NOT_IN_MAP );
		{NextBuffID,CostMoney} ->
			next
	end,
    {ok,MoneyType,NextBuffID,CostMoney}.

remove_pve_buff(MoneyType,RoleID) ->
	BuffIDList = pve_buff_mapping_list(MoneyType),
	mod_pve_fb:remove_pve_fb_buffs(RoleID, BuffIDList).

remove_pve_buff(RoleID) ->
	SilverBuffIDList = pve_buff_mapping_list(?BUY_BUFF_TYPE_SILVER),
	GoldBuffIDList = pve_buff_mapping_list(?BUY_BUFF_TYPE_GOLD),
	mod_pve_fb:remove_pve_fb_buffs(RoleID, SilverBuffIDList++GoldBuffIDList).

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
	[FbBuffList] = ?find_config(fb_buff_list),
	case lists:keyfind(MoneyType,1,FbBuffList) of
		{MoneyType,BuffIDList,CostList} ->
			{BuffIDList,CostList};
		_ ->
			undefined
	end.

relive_deduct_gold() ->
	[Gold] = ?find_config(relive_deduct_gold),
	Gold.

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

%% 玩家已经购买的buffID
%% return HasBuyBuffID | false
has_buy_buff(RoleID,MoneyType) ->
	case pve_buff_list(MoneyType) of
		{BuffIDList,_CostList} ->
			case mod_map_role:get_role_base(RoleID) of
				{ok, #p_role_base{buffs=RoleBuffs}}->
					has_buy_buff_in_role(RoleBuffs,BuffIDList,MoneyType);
				_ ->
					false
			end;
		_ ->
			false
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
					?THROW_ERR( ?ERR_BIGPVE_BUY_BUFF_NOT_IN_MAP )
			end;
		_ ->
			?THROW_ERR( ?ERR_BIGPVE_BUY_BUFF_INVALID_BUFF )
	end.

%%对所有的人发送战报，并踢出地图
reward_and_kick_all_roles()->
	#r_bigpve_map_info{cur_role_list=CurRoleList,score_list=ScoreList,exp_reward_list=ExpRewardList,prestige_reward_list=_PrestigeRewardList,bomb_list=BombList,
					   killer_list=KillerList} = get_bigpve_map_info(),
	RankData = do_rank_data(CurRoleList,ScoreList),
	lists:foldl(fun({RoleID,TotalScore},Rank)->
						case mod_map_role:get_role_base(RoleID) of
							{ok,#p_role_base{role_name=RoleName,faction_id=FactionID}} ->
								TotalExpReward = lists_key_value(RoleID,ExpRewardList),
								TotalPrestigeReward = 0, %% lists_key_value(RoleID,PrestigeRewardList),
								BombUseNum = lists_key_value(RoleID,BombList),
								KillNum = lists_key_value(RoleID,KillerList),
								?TRY_CATCH(fb_finish_reduce_hp_reward(RoleID,RoleName,FactionID,TotalScore),Err1),
								?TRY_CATCH(fb_finish_ranking_reward(RoleID,RoleName,FactionID,Rank),Err2),
								R = #m_bigpve_result_toc{rank=Rank,total_add_exp=TotalExpReward,total_add_prestige=TotalPrestigeReward,total_score=TotalScore,
														 bomb_use_num=BombUseNum,kill_num=KillNum},
								common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?BIGPVE, ?BIGPVE_RESULT, R),
								Rank + 1;
							_ -> 
								Rank
						end
				end, 1, RankData),
	?TRY_CATCH(do_battle_fb_log()),

	erlang:send_after(3000, self(), {mod,?MODULE,{kick_all_roles}}),
	ok.

fb_finish_reduce_hp_reward(RoleID,RoleName,FactionID,TotalScore) ->
	[{ReduceHp,{RewardItemID,RewardNum}}] = ?find_config(fb_finish_reduce_hp_reward),
	case TotalScore >= ReduceHp of
		true ->
			send_battle_reward_letter(RoleID,RoleName,FactionID,_Rank=undefined,RewardItemID,RewardNum);
		false ->
			nil
	end.

fb_finish_ranking_reward(RoleID,RoleName,FactionID,Rank) ->
	[RankingReward] = ?find_config(fb_finish_ranking_reward),
	case lists:keyfind(Rank, 1, RankingReward) of
		false ->
			nil;
		{Rank,{RewardItemID,RewardNum}} ->
			send_battle_reward_letter(RoleID,RoleName,FactionID,Rank,RewardItemID,RewardNum)
	end.

send_battle_reward_letter(RoleID,RoleName,FactionID,Rank,RewardItemID,RewardNum) when is_integer(RoleID),is_integer(RewardNum)->
    GoodsCreateInfo = #r_goods_create_info{
                                           bag_id=1, 
                                           position=1,
                                           bind=true,
                                           type= ?TYPE_ITEM, 
                                           type_id= RewardItemID, 
                                           start_time=0, 
                                           end_time=0,
                                           num= RewardNum},
    case mod_bag:create_p_goods(RoleID,GoodsCreateInfo) of
        {ok,GoodsList} ->
            GoodsList2 = [R#p_goods{id = 1} || R <- GoodsList],
            send_battle_reward_letter_2(RoleID,RoleName,FactionID,Rank,GoodsList2);
        {error,Reason}->
            ?ERROR_MSG("send_battle_reward_letter,Reason=~w,RoleID=~w,RewardItemID=~w,RewardItemID=~w",[Reason,RoleID,RewardItemID,RewardNum])
	end.
send_battle_reward_letter_2(RoleID,RoleName,FactionID,Rank,[Goods|_T]) ->
	GoodsNames = [common_goods:get_notify_goods_name(Goods)],
	Title = ?_LANG_BIGPVE_LETTER_TITLE,
	Text =
		case Rank of
			undefined ->
				common_letter:create_temp(?BIGPVE_REDUCE_HP_REWARD_LETTER,[GoodsNames]);
			_ ->
				RoleNameStr = common_misc:get_role_name_color(RoleName,FactionID),
				?WORLD_CHAT_BROADCAST(common_misc:format_lang("封魔殿结束，~s威力十足，荣获此次战役第~w名，获得了~s",
																	  [RoleNameStr,Rank,GoodsNames])),
				common_letter:create_temp(?BIGPVE_RANKING_REWARD_LETTER,[Rank,GoodsNames])
		end,
	common_letter:sys2p(RoleID,Text,Title,[Goods],14),
	ok.
	
do_kick_all_roles()->
    RoleIDList = mod_map_actor:get_in_map_role(),
    lists:foreach(
      fun(RoleID) ->
              do_bigpve_quit_2(RoleID)
      end, RoleIDList).

monster_dead_reward(KillerRoleID,MonsterID,MonsterTypeID,MaxHP,MonsterName,BattleMapInfo) ->
	#r_bigpve_map_info{score_list=ScoreList,cur_role_list=CurRoleList,exp_reward_list=ExpRewardList,prestige_reward_list=PrestigeRewardList,
					   killer_list=KillerList} = BattleMapInfo,
	case lists:keyfind(MonsterID,1,ScoreList) of
		false ->
			nil;
		{MonsterID,ReduceHPList} ->
			RankData = do_rank_data(CurRoleList,ScoreList),
			SortedReduceHPList = lists:sort(fun({_,ReduceHP1},{_,ReduceHP2}) -> common_tool:cmp([{ReduceHP1,ReduceHP2}]) end,ReduceHPList),
			{_,NewExpRewardList,NewPrestigeRewardList} = 
				lists:foldl(fun({RoleID,TotalReduceHP},{Rank,AccExpRewardList,AccPrestigeRewardList}) ->
									%%同时立即更新排行榜数据
									send_role_rank(RoleID,ScoreList,RankData),
									{ok,AddExp,AddPrestige} = monster_dead_reward_role(KillerRoleID,RoleID,Rank,TotalReduceHP,MonsterTypeID,MaxHP,MonsterName),
									NewAccExpRewardList = lists_add_key_value(RoleID,AccExpRewardList,AddExp),
									NewAccPrestigeRewardList = lists_add_key_value(RoleID,AccPrestigeRewardList,AddPrestige),
									{(Rank - 1),NewAccExpRewardList,NewAccPrestigeRewardList}
							end, {erlang:length(SortedReduceHPList),ExpRewardList,PrestigeRewardList}, SortedReduceHPList),
			NewKillerList = lists_add_key_value(KillerRoleID,KillerList,1),
			set_bigpve_map_info(BattleMapInfo#r_bigpve_map_info{exp_reward_list=NewExpRewardList,prestige_reward_list=NewPrestigeRewardList,
																killer_list=NewKillerList})
	end.

monster_dead_reward_role(KillerRoleID,RoleID,Rank,TotalReduceHP,MonsterTypeID,MaxHP,MonsterName) ->
	case mod_map_role:get_role_attr(RoleID) of
		{ok,#p_role_attr{level=Level,role_name=RoleName}} ->
			BuyedSilverBuffID = has_buy_buff(RoleID,?BUY_BUFF_TYPE_SILVER),
			BuyedGoldBuffID = has_buy_buff(RoleID,?BUY_BUFF_TYPE_GOLD),
			{BaseExpAdd,BasePrestigeAdd,SilverExtraExpAdd,SilverExtraPrestigeAdd} = monster_dead_reward_conf(role,MonsterTypeID,BuyedSilverBuffID),
			{BaseExpAdd,BasePrestigeAdd,GoldExtraExpAdd,GoldExtraPrestigeAdd} = monster_dead_reward_conf(role,MonsterTypeID,BuyedGoldBuffID),
			ReduceHPPre = TotalReduceHP / MaxHP,
			case mod_map_role:get_role_attr(KillerRoleID) of
				{ok,#p_role_attr{role_name=KillerRoleName}} ->
					next;
				_ ->
					KillerRoleName = undefined
			end,
			{Exp,Prestige} = get_add_exp_prestige(Level),
			ExtraExpAdd = SilverExtraExpAdd + GoldExtraExpAdd,
			ExtraPrestigeAdd = SilverExtraPrestigeAdd + GoldExtraPrestigeAdd,
			AddExp = common_tool:ceil(Exp * ReduceHPPre * BaseExpAdd * ExtraExpAdd),
			AddPrestige = common_tool:ceil(Prestige * ReduceHPPre * BasePrestigeAdd * ExtraPrestigeAdd),
			case KillerRoleID =:= RoleID of
				true ->
					{KillBaseExpAdd,KillBasePrestigeAdd,KillSilverExtraExpAdd,KillSilverExtraPrestigeAdd} = monster_dead_reward_conf(kill,MonsterTypeID,BuyedSilverBuffID),
					{KillBaseExpAdd,KillBasePrestigeAdd,KillGoldExtraExpAdd,KillGoldExtraPrestigeAdd} = monster_dead_reward_conf(kill,MonsterTypeID,BuyedGoldBuffID),
					KillExtraExpAdd = KillSilverExtraExpAdd + KillGoldExtraExpAdd,
					KillExtraPrestigeAdd = KillSilverExtraPrestigeAdd + KillGoldExtraPrestigeAdd,
					KillAddExp = common_tool:ceil(10 * Exp * KillBaseExpAdd * KillExtraExpAdd),
					_KillAddPrestige = common_tool:ceil(Prestige * KillBasePrestigeAdd * KillExtraPrestigeAdd),
					Msg = common_misc:format_lang("【~s】威力爆发，终结了【~s】，最后一击获得经验：~w。",
												  [common_tool:to_list(RoleName),common_tool:to_list(MonsterName),KillAddExp]),
					?WORLD_CENTER_BROADCAST(Msg),
					?WORLD_CHAT_BROADCAST(Msg);
				false ->
					KillAddExp = _KillAddPrestige = 0
			end,
			AddExp2 = AddExp + KillAddExp,
			AddPrestige2 = 0, %% AddPrestige + KillAddPrestige,
            KillAddPrestige1 = 0,
			% ?TRY_CATCH(mod_prestige:do_add_prestige(RoleID, AddPrestige2,?GAIN_TYPE_PRESTIGE_BIGPVE_FB),Err1),
			?TRY_CATCH(mod_map_role:do_add_exp(RoleID,AddExp2),Err2),
			R = #m_bigpve_boss_dead_toc{boss_name=MonsterName,score=TotalReduceHP,rank=Rank,add_exp=AddExp,add_prestige=AddPrestige,
										killer_add_exp=KillAddExp,killer_add_prestige=KillAddPrestige1,
										killer_name=KillerRoleName},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?BIGPVE, ?BIGPVE_BOSS_DEAD, R),
			{ok,AddExp2,AddPrestige2};
		_ ->
			{ok,0,0}
	end.
	

%% return {BaseExpAdd,BasePrestigeAdd,ExtraExpAdd,ExtraPrestigeAdd}
monster_dead_reward_conf(Type,MonsterTypeID,BuffID) ->
	[RewardList] = 
		case Type of
			kill ->
				?find_config(fb_monster_dead_killer_reward);
			role ->
				?find_config(fb_monster_dead_reward)
		end,
	case lists:filter(fun({MonsterTypeIDList,_BaseExpAdd,_BasePrestigeAdd,_BuffList}) -> 
							  lists:member(MonsterTypeID, MonsterTypeIDList)
					  end, RewardList) of
		[] ->
			?ERROR_MSG("配置错误：~w",[{Type,MonsterTypeID,BuffID}]),
			{0,0,0,0};
		[{_MonsterTypeList,BaseExpAdd,BasePrestigeAdd,BuffList}|_] ->
			case lists:keyfind(BuffID, 1, BuffList) of
				false ->
					{BaseExpAdd,BasePrestigeAdd,1,1};
				{BuffID,ExtraExpAdd,ExtraPrestigeAdd} ->
					{BaseExpAdd,BasePrestigeAdd,ExtraExpAdd,ExtraPrestigeAdd}
			end
	end.

send_role_rank(RoleID,ScoreList,RankData) ->
	MyScore = role_total_reduce_hp(RoleID,ScoreList),
	RankList = p_bigpve_rank(RankData),
	MyRank = 
		case lists:keyfind(RoleID, #p_bigpve_rank.role_id, RankList) of
			false ->
				case lists:keyfind(RoleID,1,RankData) of
					false ->
						erlang:length(RankData) + 1;
					Rank ->
						common_tool:index_of_lists(Rank, RankData)
				end;
			PRank ->
				PRank#p_bigpve_rank.rank
		end,
	R = #m_bigpve_rank_toc{my_score=MyScore,ranks=RankList,my_rank=MyRank},
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?BIGPVE, ?BIGPVE_RANK, R).

%% 玩家对所有怪物的总伤害值
role_total_reduce_hp(RoleID,ScoreList) ->
	lists:foldl(fun({_MonsterID,ReduceHPList},Acc) ->
						case lists:keyfind(RoleID,1,ReduceHPList) of
							false ->
								Acc;
							{RoleID,TotalReduceHP} ->
								Acc + TotalReduceHP
						end
				end, 0, ScoreList).

do_rank_data(CurRoleList,ScoreList) ->
	RoleScoreList = 
		lists:foldl(fun(RoleID,Acc) ->
							Score = role_total_reduce_hp(RoleID,ScoreList),
							[{RoleID,Score}|Acc]
					end,[],CurRoleList),
	lists:sort(fun({_,Score1},{_,Score2}) -> 
					   common_tool:cmp([{Score2,Score1}]) 
			   end,RoleScoreList).

p_bigpve_rank(RankData) ->
	RankData2 = lists:sublist(RankData, ?BATTLE_RANK_LEN),
	{_,PBigpveRank} = 
		lists:foldl(fun({RoleID,Score},{Rank,Acc})->
							case mod_map_role:get_role_base(RoleID) of
								{ok,#p_role_base{role_name=RoleName,faction_id=FactionID}} ->
									{Rank + 1,[#p_bigpve_rank{rank=Rank,faction_id=FactionID,role_name=RoleName,role_id=RoleID,score=Score}|Acc]};
								_ -> 
									{Rank,Acc}
							end
					end, {1,[]}, RankData2),
	PBigpveRank.

lists_key_value(RoleID,List) ->
	case lists:keyfind(RoleID,1,List) of
		false -> 0;
		{RoleID,Value} ->
			Value
	end.

lists_add_key_value(RoleID,List,AddKeyValue) ->
	case lists:keyfind(RoleID,1,List) of
		false ->
			[{RoleID,AddKeyValue}|List];
		{RoleID,Value} ->
			lists:keyreplace(RoleID, 1, List,{RoleID,Value+AddKeyValue})
	end.
			
%% --------------------------------------------------------------------
%%  内部的二级API
%% --------------------------------------------------------------------
assert_role_level(RoleAttr)->
    #p_role_attr{level=RoleLevel} = RoleAttr,
    [MinRoleLevel] = ?find_config(fb_min_role_level),
    if
        MinRoleLevel>RoleLevel->
            ?THROW_ERR( ?ERR_BIGPVE_ENTER_LV_LIMIT );
        true->
            next
    end,
    ok.


assert_role_enter_mapid()->
    [EntranceMapId] = ?find_config(entrance_map_id),
    CurMapId = mgeem_map:get_mapid(),
    if
        CurMapId=:=EntranceMapId->
            next;
        true->
            ?THROW_ERR( ?ERR_BIGPVE_ENTER_FACTION_LIMIT )
    end,
    ok.

get_fb_min_role_jingjie_str()->
    [MinLevel] = ?find_config(fb_min_role_level),
    common_tool:to_list(MinLevel).

check_bigpve_enter(RoleID,DataIn)->
    #m_bigpve_enter_tos{enter_type=EnterType} = DataIn,
    [EnableNationBattle] = ?find_config(enable_bigpve),
    if
        EnableNationBattle=:=true->
            next;
        true->
            ?THROW_ERR( ?ERR_BIGPVE_DISABLE )
    end,
    case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
        true ->
            ?THROW_ERR(?ERR_OTHER_ERR, ?_LANG_XIANNVSONGTAO_MSG);
        false -> ignore
    end,
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    assert_role_level(RoleAttr),
    assert_role_enter_mapid(),
    
    case is_role_in_map() of
        true->
            ?THROW_ERR( ?ERR_BIGPVE_ENTER_IN_BATTLE );
        _ ->
            next
    end,
    #map_state{mapid=MapID,map_type=MapType} = mgeem_map:get_state(),
    IsInBigPveFb = mod_bigpve_fb:is_fb_map_id(MapID),
    
    if
        MapType=:=?MAP_TYPE_COPY->
            ?THROW_ERR( ?ERR_BIGPVE_ENTER_FB_LIMIT );
        IsInBigPveFb->
            ?THROW_ERR( ?ERR_BIGPVE_ENTER_FB_LIMIT );
        true->
            next
    end,
    %%检查入口信息
    case get_bigpve_entrance_info() of
        undefined->
            req_bigpve_entrance_info(),
            ?THROW_ERR( ?ERR_BIGPVE_ENTER_CLOSING );
        #r_bigpve_entrance_info{is_opening=true,map_role_num=CurRoleNum}->
			[{NormalMaxRoleNum,AllMaxRoleNum}] = ?find_config(limit_fb_role_num),
			case check_direct_enter_vip(EnterType,RoleID) of
                true->
                    if
                        CurRoleNum>=AllMaxRoleNum->
                            req_bigpve_entrance_info(),
                            ?THROW_ERR( ?ERR_BIGPVE_ENTER_MAX_ROLE_NUM );
                        true->
                            next
                    end;
                {false,ErrorCode}->
                    ?THROW_ERR( ErrorCode );
                _ ->
                    if
                        CurRoleNum>=NormalMaxRoleNum->
                            req_bigpve_entrance_info(),
                            ?THROW_ERR( ?ERR_BIGPVE_ENTER_MAX_ROLE_NUM );
                        true->
                            next
                    end
            end;
        _ ->
            req_bigpve_entrance_info(),
            ?THROW_ERR( ?ERR_BIGPVE_ENTER_CLOSING )
    end,
    {ok,MapID}.

%%判断是否为VIP直接进入
check_direct_enter_vip(?ENTER_TYPE_VIP,RoleID)->
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	case ?find_config( direct_enter_vip_level) of
		[EnterVip] when VipLevel>= EnterVip->
			true;
		_ ->
			{false,?ERR_BIGPVE_ENTER_VIP_LIMIT}
	end;
check_direct_enter_vip(_,_)->
    false.

check_bigpve_quit(RoleID,_DataIn)->
    case is_role_in_map() of
        true->
            next;
        _->
			do_bigpve_quit_2(RoleID),
            ?THROW_ERR( ?ERR_BIGPVE_QUIT_NOT_IN_MAP )
    end,
    ok.


%%--------------------------------  战场入口消息的代码，可复用  [start]--------------------------------
%%请求更新入口信息
req_bigpve_entrance_info()->
    send_map_msg({req_bigpve_entrance_info}).

do_req_bigpve_entrance_info()->
    case get_bigpve_map_info() of
        #r_bigpve_map_info{is_opening=IsOpening,cur_role_list=CurRoleList}->
			EntranceInfo = #r_bigpve_entrance_info{is_opening=IsOpening,map_role_num=erlang:length(CurRoleList)},
			
            init_bigpve_entrance_info(EntranceInfo),
            ok;
        _ ->
            ignore
    end.

%%同步更新入口信息
init_bigpve_entrance_info(EntranceInfo) when is_record(EntranceInfo,r_bigpve_entrance_info)->
	[EntranceMapId] = ?find_config(entrance_map_id),
	SendInfo = {mod,?MODULE,{init_bigpve_entrance_info,EntranceInfo}},
	case global:whereis_name( common_map:get_common_map_name(EntranceMapId) ) of
		undefined->
			ignore;
		MapPID->
			MapPID ! SendInfo
	end.

do_init_bigpve_entrance_info(EntranceInfo) when is_record(EntranceInfo,r_bigpve_entrance_info)->
    put(?BIGPVE_ENTRANCE_INFO,EntranceInfo),
    ok.

do_update_bigpve_entrance_info(ValList) when is_list(ValList)->
    case get(?BIGPVE_ENTRANCE_INFO) of
        #r_bigpve_entrance_info{}= OldInfo->
            EntranceInfo =
                lists:foldl(
                  fun(E,AccIn)-> 
                          {EType,EVal} = E,
                          case EType of
                              is_opening->
                                  AccIn#r_bigpve_entrance_info{is_opening=EVal}
                          end
                  end, OldInfo, ValList),
            put(?BIGPVE_ENTRANCE_INFO,EntranceInfo),
            ok;
        _ ->
            ignore
    end,
    ok.

%%--------------------------------  战场入口消息的代码，可复用  [end]--------------------------------

%%--------------------------------  定时战场的代码，可复用  [start]--------------------------------

is_opening_battle()->
    case get_bigpve_map_info() of
        #r_bigpve_map_info{is_opening=IsOpening}->
            IsOpening;
        _ ->
            false
    end.

%%@doc 重新设置下一次战场时间
%%@return {ok,NextStartTimeSeconds}
reset_battle_open_times()->
    case common_fb:get_next_fb_open_time(?CONFIG_NAME) of
        {ok,Date,StartTimeSeconds,EndTimeSeconds,NextBcStartTime,NextBcEndTime,NextBcProcessTime,
         BeforeInterval,CloseInterval,ProcessInterval}->
            R1 = #r_bigpve_time{date = Date,
                                start_time = StartTimeSeconds,end_time = EndTimeSeconds,
                                next_bc_start_time = NextBcStartTime,
                                next_bc_end_time = NextBcEndTime,
                                next_bc_process_time = NextBcProcessTime,
                                before_interval = BeforeInterval,
                                close_interval = CloseInterval,
                                process_interval = ProcessInterval},
            put(?BIGPVE_TIME_DATA,R1),
            {ok,StartTimeSeconds};
        {error,Reason}->
            {error,Reason}
    end.

%%--------------------------------  定时战场的代码，可复用  [end]--------------------------------

%%--------------------------------  战场广播的代码，可复用  [start]--------------------------------
%% 副本开起提前广播开始消息
%% Record 结构为 r_bigpve_time
%% 返回 new r_bigpve_time
do_fb_open_before_broadcast(NowSeconds,Record) ->
    #r_bigpve_time{
                             start_time = StartTime,
                             end_time = EndTime,
                             next_bc_start_time = NextBCStartTime,
                             before_interval = BeforeInterval} = Record,
    if StartTime =/= 0 
       andalso EndTime =/= 0 
       andalso NextBCStartTime =/= 0
       andalso NowSeconds >= NextBCStartTime 
       andalso NowSeconds < StartTime->
            %% 副本开起提前广播开始消息
           MinJingjieStr = get_fb_min_role_jingjie_str(),
           BeforeMessage = 
               case StartTime>NowSeconds of
                   true->
                       {_Date,Time} = common_tool:seconds_to_datetime(StartTime),
                       StartTimeStr = common_time:time_string(Time),
                       common_misc:format_lang(?_LANG_BIGPVE_PRESTART,[StartTimeStr,MinJingjieStr]);
                   _ ->
                       common_misc:format_lang(?_LANG_BIGPVE_STARTED,[MinJingjieStr])
               end,
		   ?WORLD_CHAT_BROADCAST(BeforeMessage),
           set_bigpve_time_data( Record#r_bigpve_time{next_bc_start_time = NowSeconds + BeforeInterval} );
       true ->
           Record
    end.
%% 副本开启过程中广播处理
%% Record 结构为 r_bigpve_time
%% 返回
do_fb_open_process_broadcast(NowSeconds,Record) ->
    #r_bigpve_time{
                              start_time = StartTime,
                              end_time = EndTime,
                              next_bc_process_time = NextBCProcessTime,
                              process_interval = ProcessInterval} = Record,
    if 
        StartTime =/= 0 andalso EndTime =/= 0 
       andalso NowSeconds >= StartTime andalso EndTime >= NowSeconds 
       andalso NextBCProcessTime =/= 0
       andalso NowSeconds >= NextBCProcessTime ->
            %% 副本开起过程中广播时间到
            MinJingjieStr = get_fb_min_role_jingjie_str(),
            ProcessMessage = common_misc:format_lang(?_LANG_BIGPVE_STARTED,[MinJingjieStr]),
			?WORLD_CHAT_BROADCAST(ProcessMessage),
            set_bigpve_time_data( Record#r_bigpve_time{next_bc_process_time = NowSeconds + ProcessInterval} );
       true ->
            ignore
    end.


%%副本关闭的广播
do_fb_close_broadcast(NextStartTime)->
    EndMessageF = 
        if NextStartTime > 0 ->
               NextDateTime = common_tool:seconds_to_datetime(NextStartTime), 
               NextStartTimeStr = common_time:datetime_to_string( NextDateTime ),
               common_misc:format_lang(?_LANG_BIGPVE_CLOSED_TIME,[NextStartTimeStr]);
           true ->
               ?_LANG_BIGPVE_CLOSED_FINAL
        end,
	?WORLD_CHAT_BROADCAST(EndMessageF).

%%--------------------------------  战场广播的代码，可复用  [end]--------------------------------

%%--------------------------------  加经验的代码，可复用  [start]--------------------------------
%% @doc 获取每次间隔加的经验
get_add_exp_prestige(Level) ->
	case ?find_config({fb_add_exp_prestige, Level}) of
		[] -> {100,1};
		[{Exp,Prestige}] -> {Exp,Prestige}
	end.

do_add_exp_interval(Now) ->
	RoleIDList = get_interval_exp_list(Now),
	case get_bigpve_map_info() of
		#r_bigpve_map_info{score_list=ScoreList,rank_data=RankData} ->
			lists:foreach(
			  fun(RoleID) ->
					  case mod_map_actor:get_actor_mapinfo(RoleID, role) of
						  undefined ->
							  delete_interval_exp_list(RoleID);
						  #p_map_role{level=Level} ->
							  {ExpAdd,_Prestige} = get_add_exp_prestige(Level),
							  mod_map_role:do_add_exp(RoleID,common_tool:ceil(ExpAdd*interval_exp_addition(RoleID))),
							  send_role_rank(RoleID,ScoreList,RankData)
					  end
			  end, RoleIDList);
		_ ->
			nil
	end.

%% @doc 插入加经验列表
insert_interval_exp_list(RoleID) ->
    List = get_interval_exp_list(RoleID),
    set_interval_exp_list(RoleID, [RoleID|lists:delete(RoleID, List)]).

delete_interval_exp_list(RoleID) ->
    List = get_interval_exp_list(RoleID),
    set_interval_exp_list(RoleID, lists:delete(RoleID, List)).

get_interval_exp_list(RoleID) ->
    [{_,ExpAddInterval}] = ?find_config(fb_add_exp),
    Key = RoleID rem ExpAddInterval,
    case get({?INTERVAL_EXP_LIST, Key}) of
        undefined ->
            put({?INTERVAL_EXP_LIST, Key}, []),
            [];
        List ->
            List
    end.

set_interval_exp_list(RoleID, List) ->
    [{_,ExpAddInterval}] = ?find_config(fb_add_exp),
    Key = RoleID rem ExpAddInterval,
    put({?INTERVAL_EXP_LIST, Key}, List).

erase_interval_exp_list() ->
	[{_,ExpAddInterval}] = ?find_config(fb_add_exp),
	lists:foreach(fun(Key) ->
						  put({?INTERVAL_EXP_LIST, Key}, [])
				  end, lists:seq(0, ExpAddInterval-1)).

interval_exp_addition(RoleID) ->
	BuyedSilverBuffID = has_buy_buff(RoleID,?BUY_BUFF_TYPE_SILVER),
	BuyedGoldBuffID = has_buy_buff(RoleID,?BUY_BUFF_TYPE_GOLD),
    [{BaseExpAdd,BuffList}] = ?find_config(fb_exp_addition),
	SilverAdd = lists_key_value(BuyedSilverBuffID,BuffList),
	GoldAdd = lists_key_value(BuyedGoldBuffID,BuffList),
	BaseExpAdd * erlang:max(1,(SilverAdd+GoldAdd)).
		

%%--------------------------------  加经验的代码，可复用 [end] --------------------------------

%%--------------------------------  战场开/关的代码，可复用 [start] --------------------------------
%%GM的方便命令
gm_open_battle(SecTime)->
    send_map_msg( {gm_open_battle, SecTime} ).
gm_close_battle()->
    send_map_msg( {gm_close_battle} ).
gm_reset_open_times()->
    send_map_msg( {gm_reset_open_times} ).

send_map_msg(Msg)->
	case global:whereis_name( common_map:get_common_map_name(?BIGPVE_MAP_ID) ) of
		undefined->
			ignore;
		MapPID->
			erlang:send(MapPID,{mod,?MODULE,Msg})
	end.

%%GM开启副本
gm_open_bigpve(Second)->
	%%GM命令，手动开启
	TimeData = get_bigpve_time_data(),
	StartTime2 = common_tool:now(),
	[FbGmOpenLastTime] = ?find_config(fb_gm_open_last_time),
	EndTime2 = StartTime2 + FbGmOpenLastTime,
	TimeData2 = TimeData#r_bigpve_time{date=date(),start_time=StartTime2 + Second,end_time=EndTime2,next_bc_process_time=StartTime2},
	set_bigpve_time_data(TimeData2).

%%开启副本
open_bigpve()->
    set_bigpve_map_info(#r_bigpve_map_info{is_opening=true}),
    %%清除怪物
    delete_monster(),
    
    EntranceInfo = #r_bigpve_entrance_info{is_opening=true},
    init_bigpve_entrance_info(EntranceInfo),
	
	init_bigpve_monster_info(),
	
	erlang:send_after(60000, self(), {mod,?MODULE,{check_init_bigpve_monster}}),
	
	%%定时统计数据
	erlang:send_after(10000, self(), {mod,?MODULE,{rank_data}}),
	
    ok.


%%关闭副本
close_bigpve()->
    %%清除怪物，计算氏族积分
    delete_monster(),
    clear_broadcast_flag(),
    BattleMapInfo = get_bigpve_map_info(),
    set_bigpve_map_info(BattleMapInfo#r_bigpve_map_info{is_opening=false}),
    
    EntranceInfo = #r_bigpve_entrance_info{is_opening=false},
    init_bigpve_entrance_info(EntranceInfo),
    
    reward_and_kick_all_roles(),
    
    {ok,NextStartTimeSeconds} = reset_battle_open_times(),
    do_fb_close_broadcast(NextStartTimeSeconds),
	%%副本关闭,经验列表清空
	erase_interval_exp_list(),
    erlang:send_after(300000, self(), {mod,?MODULE,{update_fighting_power_rank}}),
    
    ok.


%%--------------------------------  战场开/关的代码，可复用 [end] --------------------------------

init_bigpve_monster_info()->
    erlang:send(self(), {mod,?MODULE,{init_bigpve_monster}}),
    ok.

do_reborn_bigpve_monster(_MonsterID,MonsterTypeID,Pos) ->
	case get_bigpve_map_info() of
		#r_bigpve_map_info{}->
			#map_state{mapid=MapID, map_name=MapProcessName} = mgeem_map:get_state(),
			MonsterList = [#p_monster{reborn_pos=Pos,
									  monsterid=mod_map_monster:get_max_monster_id_form_process_dict(),
									  typeid=MonsterTypeID,
									  mapid=MapID}],
			mod_map_monster:init_call_fb_monster(MapProcessName,MapID,MonsterList),
			insert_monster_ets(MapID,MonsterList);
		_ ->
			ignore
	end.

init_bigpve_monster_ets(MapID,MonsterList) ->
	MonsterIDList = 
		lists:foldr(fun(Monster,AccIn) ->
							#p_monster{monsterid=MonsterID,typeid=MonsterTypeID} = Monster,
							case mod_map_monster:get_monster_state(MonsterID) of
								undefined ->
									AccIn;
								_ ->
									[{MonsterID,MonsterTypeID}|AccIn]
							end
					end,[], MonsterList),
	ets:insert(?MODULE, {MapID, MonsterIDList}).

insert_monster_ets(MapID,MonsterList) ->
	[#p_monster{monsterid=MonsterID,typeid=MonsterTypeID}|_] = MonsterList,
	case ets:lookup(?MODULE, MapID) of
		[{_, List}] ->
			NewList = [{MonsterID,MonsterTypeID}|lists:keydelete(MonsterID,1,List)],
			ets:insert(?MODULE, {MapID, NewList});
		_ ->
			ignore
	end.

look_monsterInfo(MonsterID) ->
	case ets:lookup(?MODULE, ?BIGPVE_MAP_ID) of
		[{_, List}] ->
			case lists:keyfind(MonsterID, 1, List) of
				false ->
					{0,0};
				Tuple ->
					Tuple
			end;
		_ ->
			{0,0}
	end.

delete_monster(MonsterID) ->
	case ets:lookup(?MODULE, ?BIGPVE_MAP_ID) of
		[{_, MonsterIDList}] ->
			List = lists:keydelete(MonsterID, 1, MonsterIDList),
			ets:insert(?MODULE, {?BIGPVE_MAP_ID, List});
		_ ->
			ignore
	end.
delete_monster() ->
	mod_map_monster:delete_all_monster(),
	ets:insert(?MODULE, {?BIGPVE_MAP_ID, []}).
	

	

%% 检查boss是否初始化
check_init_bigpve_monster() ->
	case is_opening_battle() of
		true->
			MonsterList = mod_map_monster:get_monster_id_list(),
			case MonsterList =:= undefined orelse erlang:length(MonsterList) =:= 0 of
				true ->
					?ERROR_MSG("1分钟后竟然还没创建怪物，重新创建吧",[]),
					do_init_bigpve_monster();
				false ->
					ignore
			end;
		_ ->
			ignore
	end.

do_init_bigpve_monster()->
    case get_bigpve_map_info() of
        #r_bigpve_map_info{}=OldMapInfo->
            #map_state{mapid=MapID, map_name=MapProcessName} = mgeem_map:get_state(),
            {ok,MonsterList,RoleBornList} = get_monster_role_born_points(MapID),
            mod_map_monster:init_call_fb_monster(MapProcessName,MapID,MonsterList),
            NewMapInfo = OldMapInfo#r_bigpve_map_info{role_born_list=RoleBornList},
			init_bigpve_monster_ets(MapID,MonsterList),
            set_bigpve_map_info(NewMapInfo);
        _ ->
            ignore
    end.

%% @return {ok,MonsterList,RoleBornList}
get_monster_role_born_points(MapID)->
	OnlineNum = common_map:get_online_num(),
	[FbBornPointsList] = ?find_config(fb_monster_role_born_points),
	[FbMonsterList] = ?find_config(fb_monster_list),
	{MonsterList,RoleBornList} = 
		lists:foldl(fun({{OnlineNum1,OnlineNum2},MonsterBornPos,RoleBornPos},{Acc1,Acc2}) ->
							case OnlineNum >= OnlineNum1 andalso OnlineNum =< OnlineNum2 of
								true ->
									{lists:map(fun({TX,TY}) ->
													   MonsterTypeID = common_tool:random_element( FbMonsterList ),
													   Pos = #p_pos{tx=TX, ty=TY, dir=1},
													   #p_monster{reborn_pos=Pos,
																  monsterid=mod_map_monster:get_max_monster_id_form_process_dict(),
																  typeid=MonsterTypeID,
																  mapid=MapID}
											   end, MonsterBornPos),
									 RoleBornPos};
								false ->
									{Acc1,Acc2}
							end
					end, {[],[]}, FbBornPointsList),
	{ok,MonsterList,RoleBornList}.

%%记录战场的日志
do_battle_fb_log()->
    case get_bigpve_time_data() of
        #r_bigpve_time{start_time = StartTime,end_time = EndTime} ->
            case get_bigpve_map_info() of
				#r_bigpve_map_info{max_role_num=MaxRoleNum,killer_list=KillerList,bomb_list=BombList}->
					UseBombNum = lists:foldl(fun({_,Num},Acc) -> Num + Acc end, 0, BombList),
					MonsterDeadNum = lists:foldl(fun({_,Num},Acc) -> Num + Acc end, 0, KillerList),
                    BattleFbLog = #r_bigpve_fb_log{start_time=StartTime, end_time=EndTime, 
												   use_bomb_num=UseBombNum,monster_dead_num=MonsterDeadNum,max_role_num=MaxRoleNum},
                    common_general_log_server:log_bigpve_fb(BattleFbLog);
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.

%%扣除抵用卷
%% {返回还需要扣除的钱币/元宝,UpList,DelList}
t_deduct_buy_buff_item(MoneyType,CostMoney,RoleID) ->
	[Voucher] = ?find_config(voucher),
	case lists:keyfind(MoneyType,1,Voucher) of
		false ->
			?ERROR_MSG("t_deduct_buy_buff_item error:~w",[{MoneyType,CostMoney,RoleID}]),
			{CostMoney,[],[],0,0};
		{MoneyType,TypeID,Price} ->
			case mod_bag:check_inbag_by_typeid(RoleID,TypeID) of
				{ok,FoundGoodsList} ->
					BagNum = get_material_num_in_bag(FoundGoodsList),
					NeedNum = CostMoney div Price,
					DeductNum = erlang:min(NeedNum,BagNum),
					{ok,UpList,DelList} = mod_bag:decrease_goods_by_typeid(RoleID,TypeID,DeductNum),
					{CostMoney - (DeductNum * Price),UpList,DelList,DeductNum,TypeID};
				_  ->
					{CostMoney,[],[],0,TypeID}
			end
	end.

%%扣除钱币/元宝
t_deduct_buy_buff_money(BuyBuffType,DeductMoney,RoleID)->
    case BuyBuffType of
        ?BUY_BUFF_TYPE_SILVER->
            MoneyType = silver_any,
            ConsumeLogType = ?CONSUME_TYPE_SILVER_BIG_PVE_FB_BUY_BUFF;
        ?BUY_BUFF_TYPE_GOLD ->
            MoneyType = gold_unbind,
            ConsumeLogType = ?CONSUME_TYPE_GOLD_BIG_PVE_FB_BUY_BUFF
    end,
    case common_bag2:t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeLogType) of
        {ok,RoleAttr2}->
            {ok,RoleAttr2};
        {error,silver_any}->
            ?THROW_ERR( ?ERR_SILVER_NOT_ENOUGH );
        {error,gold_any}->
            ?THROW_ERR( ?ERR_GOLD_NOT_ENOUGH );
        {error, Reason} -> 
            throw({error,Reason});
        _ ->
            ?THROW_SYS_ERR()
    end. 

get_material_num_in_bag(Goods) when is_record(Goods,p_goods)->
	Goods#p_goods.current_num;
get_material_num_in_bag(FoundGoodsList) when is_list(FoundGoodsList)->
	lists:foldl(fun(E,AccIn)-> 
						#p_goods{current_num=Num}=E,
						AccIn + Num
				end, 0, FoundGoodsList).

