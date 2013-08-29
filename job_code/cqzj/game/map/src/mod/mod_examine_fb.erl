%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     检验副本（策划称为封神战纪）,现在改为封神战纪(t6中的战役副本)
%%% @end
%%% Created : 2012-5-18
%%%-------------------------------------------------------------------
-module(mod_examine_fb).

-include("mgeem.hrl").
-export([
         handle/1,
         handle/2
        ]).
-export([
			get_role_examine_fb_info/1,
			check_is_open/2,
			hook_role_online/2,
            hook_role_offline/1,
			hook_role_enter/2,
            hook_role_before_quit/1,
			hook_role_quit/1,
			hook_role_dead/1,
			hook_monster_dead/2,
			role_level_up/2
		]).
-export([
			is_in_examine_fb/1,
			get_finish_barrier/1,
			is_examine_fb_map_id/1,
			assert_valid_map_id/1,
			get_map_name_to_enter/1,
			clear_map_enter_tag/1]
	   ).
-export([
			hook_equip_qianghua/3,
			hook_pet_aptitude_upgrade/3,
			hook_pet_period_upgrade/3,
			hook_skill_upgrade/3,
			hook_skill_life_star_upgrade/2,
			hook_equip_upgrade/2,
			do_examine_fb_enter_2/7,
            open_and_reset_barrier_times/2, 
            commit_mission/2
		]).

-export([gm_reset_barrier_fight_times/1,
         gm_reset_reset_times/1]).

%% mod_role_misc的回调方法
-export([init/2, delete/1]).

%% internal export
-export([get_role_hidden_ex_fb_info/1,
		set_role_hidden_ex_fb_info/2]).
 
%% ====================================================================
%% Macro
%% ====================================================================
%% 封神战纪地图信息
-record(r_examine_fb_map_info, {barrier_id, map_role_id, first_enter,start_time, end_time, 
                                mapid %% init表示在初始化，
    }).
-define(examine_fb_map_info, examine_fb_map_info).

-define(fb_quit_status_finish, 0).      %% 副本完成
-define(fb_quit_status_fail, 1).        %% 副本失败

-define(EXAMINE_FB_STATE_FAIL,0).
-define(EXAMINE_FB_STATE_SUCC,1).

-define(BARRIER_STATUS_NONE, 0).
-define(BARRIER_STATUS_PASS, 1).

-define(INIT_SELECT_TIMES,   4).        %% 初始可以翻牌次数

%% 封神战纪死亡退出
-define(examine_fb_quit_type_normal,  0).
-define(examine_fb_quit_type_relive,  1).
-define(examine_fb_quit_type_timeout, 2).
-define(CONFIG_NAME,examine_fb).
-define(big_barrier_id(BarrierID),BarrierID div 100).

%% 副本入口通知的方式
-define(FB_NOTIFY_TYPE_NORMAL, 1).
-define(FB_NOTIFY_TYPE_UPGRADE, 2).

-define(EXAMINE_FB_MAP_NAME_TO_ENTER(RoleID),{examine_fb_map_name_to_enter,RoleID}).
-define(EXAMINE_FB_FINISH_STATE,examine_fb_finish_state).
-define(EXAMINE_FB_TIMEOUT_REF, examine_fb_timeout_ref).


%%错误码
-define(ERR_EXAMINE_FB_ENTER_TIMES_LIMITED,105001).  %%今天的挑战次数已到最大限制
-define(ERR_EXAMINE_FB_ENTER_MIN_LV_LIMITED,105002).  %%等级限制
-define(ERR_EXAMINE_FB_NOT_IN_SELF_COUNTRY,105003).  %%在外国地图不允许进入封神战纪
-define(ERR_EXAMINE_FB_ILLEGAL_ENTER_MAP,105004).  %%当前所在地图不允许进入封神战纪
-define(ERR_EXAMINE_FB_ENTER_BARRIER_LOCK,105005).  %%该关卡还没开通，不能进行挑战
-define(ERR_EXAMINE_FB_ENTER_ROLE_DEAD,105006).  %%死亡状态下不能进入封神战纪
-define(ERR_EXAMINE_FB_ENTER_ROLE_STALL,105007).  %%摆摊状态下不能进入封神战纪
-define(ERR_EXAMINE_FB_ENTER_ROLE_TRAINING,105008).  %%离线训练状态下不能进入封神战纪
-define(ERR_EXAMINE_FB_ENTER_ROLE_FIGHT,105009).  %%战斗状态下不能进入封神战纪
-define(ERR_EXAMINE_FB_RESET_TIMES_GOLD_ANY_NOT_ENOUGH,105011).  %%重置元宝不足.
-define(ERR_EXAMINE_FB_RESE_TIMES_MAX_LIMIT,105012).  %%今天的重置次数已达限制.
-define(ERR_EXAMINE_FB_ENTER_ROLE_HORSE_RACING,105014).  %%在玩钦点美人不能进入封神战纪
-define(ERR_EXAMINE_FB_ENTER_NO_ENOUGH_TILI,105015).  %%体力值不够，不能进入副本
-define(ERR_EXAMINE_FB_BOX_BAG_FULL,105019).  %%背包已满，无法继续扫荡


-define(UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXAMINE_FB, Method, Msg)).

check_is_open(RoleID,BarrierID) ->
	{ok, #r_role_examine_fb{open_barriers=OpenBarriers}} = get_role_examine_fb_info(RoleID),
	lists:member(BarrierID, OpenBarriers).


%% ====================================================================
%% API functions
%% ====================================================================
init(RoleID, HiddenExFbRec) ->
	case HiddenExFbRec of
		false ->
			HiddenExFbRec1 = #r_role_hidden_examine_fb{};
		_ ->
			HiddenExFbRec1 = HiddenExFbRec
	end,
	set_role_hidden_ex_fb_info(RoleID, HiddenExFbRec1).

delete(RoleID) ->
	mod_role_tab:erase({?HIDDEN_EXAMINE_FB_INFO, RoleID}).

set_role_hidden_ex_fb_info(RoleID, HiddenExFbRec) ->
	mod_role_tab:put({?HIDDEN_EXAMINE_FB_INFO, RoleID}, HiddenExFbRec).

get_role_hidden_ex_fb_info(RoleID) ->
	case mod_role_tab:get({?HIDDEN_EXAMINE_FB_INFO, RoleID}) of
		undefined ->
			#r_role_hidden_examine_fb{};
		HiddenExFbRec ->
            mod_hidden_examine_fb:check_and_do_reset(RoleID, HiddenExFbRec)
	end.



handle(Info,_State) ->
    handle(Info).


handle({_, ?EXAMINE_FB, ?EXAMINE_FB_ENTER,_,_,_,_}=Info) ->
    do_examine_fb_enter(Info);
handle({_, ?EXAMINE_FB, ?EXAMINE_FB_QUIT,_,_,_,_}=Info) ->
    do_examine_fb_quit(Info);
handle({_, ?EXAMINE_FB, ?EXAMINE_FB_PANEL,_,_,_,_}=Info) ->
    do_examine_fb_panel(Info);
handle({_, ?EXAMINE_FB, ?EXAMINE_FB_RESET,_,_,_,_}=Info) ->
    do_examine_fb_reset(Info);
handle({_, ?EXAMINE_FB, ?EXAMINE_FB_SWEEP,_,_,_,_}=Info) ->
    do_examine_fb_sweep(Info);
handle({_, ?EXAMINE_FB, ?EXAMINE_FB_SELECT_REWARD,_,_,_,_}=Info) ->
    do_select_reward(Info);
handle({_, ?EXAMINE_FB, ?EXAMINE_FB_HIDDEN_ENTER,_,_,_,_}=Info) ->
    mod_hidden_examine_fb:do_enter(Info);
handle({_, ?EXAMINE_FB, ?EXAMINE_FB_ONE_KEY_SWEEP,_,_,_,_}=Info) ->
    do_one_key_sweep(Info);    

handle({init_examine_fb_map_info, MapInfo}) ->
    #map_state{mapid=MapID} = mgeem_map:get_state(),
    set_examine_fb_map_info(MapInfo#r_examine_fb_map_info{mapid=MapID});
handle({RoleID, offline_terminate}) ->
    do_offline_terminate(RoleID);
handle({RoleID, fb_timeout_kick}) ->
    do_fb_timeout_kick(RoleID);
handle({create_map_succ,RoleID}) ->
    do_async_create_map(RoleID);
handle({gm_open, RoleID, BarrierID}) ->
    {ok, RoleExamineFbInfo} = open_barrier(RoleID,BarrierID),
    send_fb_panel_to_client(RoleID, RoleExamineFbInfo);

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

gm_reset_barrier_fight_times(RoleID)->
    {ok,OldExamineFbInfo} = get_role_examine_fb_info(RoleID),
    NewExamineFbInfo = OldExamineFbInfo#r_role_examine_fb{
                                                          barrier_records=[],                                                          
                                                          last_enter_time=common_tool:now()
                                                         },
    set_role_examine_fb_info(RoleID,NewExamineFbInfo),
    ok.
gm_reset_reset_times(RoleID) -> 
    {ok,OldExamineFbInfo} = get_role_examine_fb_info(RoleID),
    NewExamineFbInfo = OldExamineFbInfo#r_role_examine_fb{reset_times=0},
    set_role_examine_fb_info(RoleID,NewExamineFbInfo),
    ok.
 
get_map_name_to_enter(RoleID)->
    {DestMapID, _TX, _TY} = get({enter, RoleID}),
    get_examine_fb_map_name(DestMapID, RoleID).

clear_map_enter_tag(_RoleID)->
    ignore.

clear_timeout_ref() ->
    case erlang:get(?EXAMINE_FB_TIMEOUT_REF) of
        undefined ->ignore;
        Ref -> erlang:cancel_timer(Ref),erlang:erase(?EXAMINE_FB_TIMEOUT_REF)
    end.

%% @doc 获取副本地图进程名
get_examine_fb_map_name(MapID, RoleID) ->
    lists:concat(["examine_fb_map_", MapID, "_", RoleID]).

%% 副本的时间限制已到，将角色提出副本
%% 这里的一个可能的问题是玩家进程不在了，而该副本进程还在
%% 那从玩家ets表中获取数据会失败的
do_fb_timeout_kick(RoleID)->
    case is_in_examine_fb(RoleID) of
        true->
            erlang:put(examine_fb_timeout_flag, true),
            do_examine_fb_quit_2(RoleID,?examine_fb_quit_type_timeout);
        _ ->
            ignore
    end,
    erlang:erase(?EXAMINE_FB_TIMEOUT_REF).

%% @doc 下线保护时间到，如果角色不在副本中杀掉副本地图进程
do_offline_terminate(RoleID) ->
    case catch get_examine_fb_map_info(RoleID) of
        {ok, MapInfo} ->
            mod_role_tab:erase(RoleID, ?examine_fb_map_info),
            case mod_map_actor:get_in_map_role() of
                [] ->
                    common_map:exit( examine_fb_role_quit1 ),
                    catch do_examine_fb_log(MapInfo);
                _ ->
                    ignore
            end;
        _ ->
            common_map:exit( examine_fb_role_quit2 )
    end.

do_async_create_map(RoleID) ->
    case erase_async_create_map_info(RoleID) of
        undefined ->
            ignore;
         {Unique, Module, Method, RoleID, PID, RoleExamineFbInfo, BarrierID, BarrierMapID, BarrierMapName} ->
             do_examine_fb_enter_3(Unique, Module, Method, RoleID, PID, RoleExamineFbInfo, BarrierID, BarrierMapID, BarrierMapName)
    end.

assert_valid_map_id(DestMapID)->
    case is_examine_fb_map_id(DestMapID) of
        true->
            ok;
        _ ->
            ?ERROR_MSG("严重，试图进入错误的地图,DestMapID=~w",[DestMapID]),
            throw({error,error_map_id,DestMapID})
    end.

%% @doc 是否在封神战纪中
is_in_examine_fb(RoleID) ->
    case get_examine_fb_map_info(RoleID) of
        {ok, _} ->
            true;
        _ ->
            false
    end.

role_level_up(RoleID, NewLevel) ->
	{ok, RoleExamineFbInfo} = get_role_examine_fb_info(RoleID),
    case cfg_examine_fb:get_open_barriers(NewLevel) of 
        [] -> ignore;
        OpenBarriers ->
            RoleExamineFbInfo1 = RoleExamineFbInfo#r_role_examine_fb{
        		open_barriers = OpenBarriers
        	},
        	set_role_examine_fb_info(RoleID, RoleExamineFbInfo1),
            send_fb_panel_to_client(RoleID, RoleExamineFbInfo1)
    end.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_select_reward({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
	SelectId = DataIn#m_examine_fb_select_reward_tos.select_id,
	Ret = case check_select_reward(RoleID, SelectId) of
        {true, _MapInfo}->
            {LeftFreeSelectTimes, GoldSelectedTimes} = mod_role_tab:get(RoleID, select_data),
            case LeftFreeSelectTimes > 0 of
            	true -> 
					LeftFreeSelectTimes1 = LeftFreeSelectTimes - 1, 
					GoldSelectedTimes1   = GoldSelectedTimes,
					MoneyType            = free, 
					Cost                 = 0;
            	false -> 
					MoneyType            = gold_unbind, 
					LeftFreeSelectTimes1 = 0,
					GoldSelectedTimes1   = GoldSelectedTimes + 1,
            		Cost = cfg_examine_fb:get_selected_gold(GoldSelectedTimes1)
            end,
            Index = random_reward_index(RoleID),
            Reward = cfg_examine_fb:get_reward(Index),
            case check_money_enough(RoleID, MoneyType, Cost) of
            	true ->
            		LogType = ?LOG_ITEM_TYPE_FAN_PAI_GAIN,
            		case mod_bag:add_items(RoleID, [Reward], LogType) of
            			{true, [RewardPGoods]} ->	
            				do_select_reward_cost(RoleID, MoneyType, Cost),
            				%% 修改次数和剩余的奖励权重
            				mod_role_tab:put(RoleID, select_data, {LeftFreeSelectTimes1, GoldSelectedTimes1}),
            				{LeftTimes, RemainRewardWeightList} = mod_role_tab:get(RoleID, remain_reward_weights),
            				RemainRewardWeightList1 = lists:keydelete(Index, 1, RemainRewardWeightList),
            				mod_role_tab:put(RoleID, remain_reward_weights, {LeftTimes - 1, RemainRewardWeightList1}),
            				NextCost = cfg_examine_fb:get_selected_gold(min(4, GoldSelectedTimes1 + 1)),
            				{true, RewardPGoods, LeftFreeSelectTimes1, NextCost};
            			{error, Reason} ->
            				{error, Reason}
            		end;
            	{error, ErrStr} ->
            		{error, ErrStr}
            end;
        {error, ErrCode} when is_integer(ErrCode) ->
            %% 该错误是玩家先发了退出副本的请求，然后再发了翻牌请求造成的，直接忽略算了
            ?ERROR_MSG("Client cheat, ErrCode is line: ~w", [ErrCode]),
            {error, ignore};
		{error, ErrStr} ->
			{error, ErrStr}
    end,
    case Ret of
        {error, ignore} -> ignore;
    	{error, ErrorStr} ->
            Msg = #m_examine_fb_select_reward_toc{
                err_code = 1,
                reason   = ErrorStr
            },
            ?UNICAST_TOC(Msg);
			% common_misc:send_common_error(RoleID, 0, ErrorStr);
		{true, RewardPGoods2, LeftFreeSelectTimes2, NextCost1} ->
			Msg = #m_examine_fb_select_reward_toc{
				err_code     = 0,
				select_id    = SelectId,
				reward_prop  = RewardPGoods2,
				remain_times = LeftFreeSelectTimes2,
				deduct_gold  = NextCost1
			},
    		?UNICAST_TOC(Msg)
    end.

check_select_reward(RoleID, SelectId) ->
	case get_examine_fb_map_info(RoleID) of
		{error, not_found} ->
			{error, ?LINE};
		{ok, MapInfo} ->
			case mod_role_tab:get(RoleID, ?EXAMINE_FB_FINISH_STATE) of
                true-> %% 副本完成了
                	case SelectId >=1 andalso SelectId =< 5 of
                		true ->
                			case mod_role_tab:get(RoleID, remain_reward_weights) of
                				{0, _} -> %% 没有牌可翻了
                					{error, <<"已经没有牌可翻了">>};
                				_ ->
                    				{true, MapInfo}
                    		end;
                    	false ->
                    		{error, ?_LANG_PARAM_ERROR}
                    end;
                _ ->
                    {error, ?LINE}
            end
	end.

%% {剩余可免费翻牌的次数, 使用元宝翻牌的次数}
set_select_data(RoleID, LeftFreeSelectTimes, GoldSelectedTimes, CanFetch) ->
    case CanFetch of
        true ->
	       mod_role_tab:put(RoleID, select_data, {LeftFreeSelectTimes, GoldSelectedTimes});
        false ->
            mod_role_tab:put(RoleID, select_data, {0, 0})
    end.

%% 按权重获取一个奖励索引id
random_reward_index(RoleID) ->
	{_, RemainRewardWeightList} = mod_role_tab:get(RoleID, remain_reward_weights),
	{Index, _} = common_tool:random_from_tuple_weights(RemainRewardWeightList, 2),
	Index.

%% 设置剩余的权重列表
set_remain_reward_weights(RoleID, {LeftTimes, RemainRewardWeightList}, CanFetch) ->
    case CanFetch of
        true ->
           mod_role_tab:put(RoleID, remain_reward_weights, {LeftTimes, RemainRewardWeightList});
        false ->
            mod_role_tab:put(RoleID, remain_reward_weights, {0, []})
    end.
	

%% MoneyType: free | gold_any
check_money_enough(RoleID, MoneyType, Cost) ->
	case MoneyType of
		free -> true;
		_ ->
			case common_bag2:check_money_enough(MoneyType, Cost, RoleID) of
				true ->	true;
				false -> {error, ?_LANG_NOT_ENOUGH_GOLD}
			end
	end.
%% 一定可以扣除钱的
do_select_reward_cost(RoleID, MoneyType, Cost) ->
	case MoneyType of
		free -> true;
		_  ->
			LogType = ?CONSUME_TYPE_GOLD_FAN_PAI_COST,
			true = common_bag2:use_money(RoleID, MoneyType, Cost, LogType),
			true
	end.

%% 一键扫荡
do_one_key_sweep({Unique, Module, _Method, DataIn, RoleID, PID, Line}) ->
    BarrierIdList = DataIn#m_examine_fb_one_key_sweep_tos.id_list,
    AutoDeductTili = DataIn#m_examine_fb_one_key_sweep_tos.auto_deduct_tili,
    DataIn1 = #m_examine_fb_sweep_tos{auto_deduct_tili=AutoDeductTili},
    do_one_key_sweep_help(BarrierIdList, Unique, Module, DataIn1, RoleID, PID, Line).
do_one_key_sweep_help([], _Unique, _Module, _DataIn, _RoleID, _PID, _Line) -> ok;
do_one_key_sweep_help([BarrierID | Rest], Unique, Module, DataIn, RoleID, PID, Line) ->
    DataIn1 = DataIn#m_examine_fb_sweep_tos{barrier_id = BarrierID},
    case do_examine_fb_sweep({Unique, Module, ?EXAMINE_FB_SWEEP, DataIn1, RoleID, PID, Line}) of
        true ->
            do_one_key_sweep_help(Rest, Unique, Module, DataIn, RoleID, PID, Line);
        false ->
            ok
    end.

do_examine_fb_sweep({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
	#m_examine_fb_sweep_tos{barrier_id=BarrierId,auto_deduct_tili=AutoDeductTili} = DataIn,
	{SweepSucc, Msg1} = case catch check_do_sweep(RoleID,DataIn) of
        {ok,RewardProps, CostTiliData}->
            do_sweep_2(DataIn,RoleID,RewardProps, CostTiliData);
        {'EXIT', Reason} ->
            ?ERROR_MSG("sweep exception, Reason: ~w, trace stack: ~w", [Reason, erlang:get_stacktrace()]),
            Msg = #m_examine_fb_sweep_toc{err_code=?ERR_SYS_ERR,barrier_id=BarrierId,auto_deduct_tili=AutoDeductTili},
            {false, Msg};
        {error,ErrCode,Reason}->
            Msg = #m_examine_fb_sweep_toc{err_code=ErrCode,reason=Reason,barrier_id=BarrierId,auto_deduct_tili=AutoDeductTili},
    		{false, Msg}
	end,
    ?UNICAST_TOC(Msg1),
    SweepSucc.

check_do_sweep(RoleID,DataIn)->
	#m_examine_fb_sweep_tos{barrier_id=BarrierId,auto_deduct_tili=AutoDeductTili} = DataIn,
	{ok, CostTiliData, _, _} = check_do_examine_fb_enter(RoleID,BarrierId,AutoDeductTili),
	assert_role_bag(RoleID),
	%% 检查是否副本地图 除英雄副本    
    #map_state{map_type=MapType,mapid=MapID} = mgeem_map:get_state(),
    case MapType of
        ?MAP_TYPE_NORMAL->
			next;
        _ ->
            case is_examine_fb_map_id(MapID) of
                true->
                    next;
                false->
                    ?THROW_ERR( ?ERR_EXAMINE_FB_ILLEGAL_ENTER_MAP )
            end
    end,
    FbBarrierConf = cfg_examine_fb:get_examine_conf(BarrierId),
	#r_examine_fb_barrier_conf{monster_list=MonsterList} = FbBarrierConf,
	RewardProps = lists:foldl(
					fun(E,AccIn)->
							{ok,DropPropList} = mod_map_drop:get_monster_drop_prop_list(E),
							lists:merge(AccIn, DropPropList)
					end, [], MonsterList),
	{ok,RewardProps, CostTiliData}.
assert_role_bag(RoleID)->
	case mod_bag:get_empty_bag_pos_num(RoleID, 1) of
        {ok,Num} when Num>0->
            next;
        _ ->
            ?THROW_ERR( ?ERR_EXAMINE_FB_BOX_BAG_FULL )
    end.

do_sweep_2(DataIn,RoleID,RewardProps, CostTiliData)->
	#m_examine_fb_sweep_tos{barrier_id=BarrierId,auto_deduct_tili=AutoDeductTili} = DataIn,
	TransFun = fun() -> 
					   t_do_sweep_2(RoleID,RewardProps,AutoDeductTili, CostTiliData)
			   end,
	case common_transaction:t( TransFun ) of
		{atomic,{ok,NeedTili,NewGoodsList,NewRoleAttr,DeleteList}}->
			%% 增加本关攻击次数
			{ok,NewBarrierRecs,_} = add_barrier_fight_times(RoleID,BarrierId),

            %% 获取一次翻牌的奖励
            {Index, _}   = common_tool:random_from_tuple_weights(cfg_examine_fb:get_weights(BarrierId), 2),
            SelectReward = cfg_examine_fb:get_reward(Index),

            %% 发送通关的固定奖励
            BarrierInfoRec = cfg_examine_fb:get_barrier_conf(BarrierId),

            TotalItemReward = [SelectReward | BarrierInfoRec#r_barrier_conf.reward_items],
            
            Fun = fun() -> common_barrier:send_reward(RoleID, 
                    BarrierInfoRec#r_barrier_conf.reward_exp, 
                    BarrierInfoRec#r_barrier_conf.reward_prestige, 
                    BarrierInfoRec#r_barrier_conf.reward_silver, 
                    TotalItemReward) end,
			mgeer_role:run(RoleID, Fun),
			%%增加日常副本的福利
%% 			hook_activity_schedule:hook_examine_fb_sweep(RoleID),
			
			common_misc:update_goods_notify({role,RoleID}, NewGoodsList),
            case DeleteList of
                undefined -> ignore;
                _ ->
                    common_item_logger:log(RoleID, DeleteList, ?LOG_ITEM_TYPE_SHI_YONG_SHI_QU),
                    common_misc:del_goods_notify({role, RoleID}, DeleteList)
            end,
			%%扣除体力
			mod_tili:reduce_role_tili(RoleID,NeedTili,true),
			case NewRoleAttr of
				undefined-> ignore;
				_ -> common_misc:send_role_gold_change(RoleID, NewRoleAttr)
			end,
			Fun2 = fun({Id,Num,Type,IsBind}) ->
                [ItemBaseInfo] = common_config_dyn:find(item, Id),
                #p_reward_prop{
                    prop_id   = Id,
                    prop_type = Type,
                    prop_num  = Num,
                    bind      = IsBind,
                    color     = ItemBaseInfo#p_item_base_info.colour
                }
            end,
			Msg = #m_examine_fb_sweep_toc{
					reward_props     = RewardProps ++ [Fun2(ItemConfig) || ItemConfig <- TotalItemReward],
					reward_exp       = BarrierInfoRec#r_barrier_conf.reward_exp,
					reward_prestige  = BarrierInfoRec#r_barrier_conf.reward_prestige,
					reward_silver    = BarrierInfoRec#r_barrier_conf.reward_silver,
					reward_items     = [],
					barrier_id       = BarrierId,
					auto_deduct_tili = AutoDeductTili,
					barrier_records  = NewBarrierRecs,
					fight_times      = 1},
			{true, Msg};
		{aborted,AbortErr}->
 			{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
 			Msg = #m_examine_fb_sweep_toc{err_code=ErrCode,reason=Reason,barrier_id=BarrierId,auto_deduct_tili=AutoDeductTili},
 			{false, Msg}
	end.

t_do_sweep_2(RoleID,RewardProps,_AutoDeductTili, CostTiliData) when is_list(RewardProps)->
	case RewardProps of
		[] -> NewGoodsList = [];
		[RewardProp|_T] -> 
			if
				is_record(RewardProp,p_goods)->
					{ok,NewGoodsList} = mod_bag:create_goods_by_p_goods(RoleID, RewardProps);
				is_record(RewardProp,p_reward_prop)->
					{ok,NewGoodsList} = common_bag2:t_reward_prop(RoleID, RewardProps);
				true->
					NewGoodsList = []
			end
	end,
	NeedTili=need_cost_tili(), 
    case CostTiliData of
        {tili, 0} ->
            DeleteList = undefined,
            NewRoleAttr = undefined;
        {tili, 1} ->
            NewRoleAttr = undefined,
            mod_tili:use_tili_card(RoleID, mod_tili:tili_from_card()),
            {0,DeleteList,_UpdateList} = mod_bag:decrease_goods_by_typeid(RoleID, [1], 10100092, 1);
        {tili, 2} ->
            DeleteList = undefined,
            %%先买后扣
            {ok,_,NewRoleAttr} = mod_tili:t_buy_tili(RoleID)
    end,
	{ok,NeedTili,NewGoodsList,NewRoleAttr, DeleteList}.


do_examine_fb_reset({Unique, Module, Method, DataIn, RoleID, PID, _Line}=Info)->
	case catch check_can_reset(RoleID,DataIn) of
		{ok,NewRoleExamineFbInfo}->
			do_examine_fb_reset2(Info,NewRoleExamineFbInfo);
		{error,ErrCode,Reason} ->
			R2 = #m_examine_fb_reset_toc{err_code=ErrCode,reason=Reason},
			?UNICAST_TOC(R2)
	end.

do_examine_fb_reset2({Unique, Module, Method, DataIn, RoleID, PID, _Line},RoleExamineFbInfo) ->
	#m_examine_fb_reset_tos{barrier_id=BarrierID} = DataIn,
	#r_role_examine_fb{reset_times=ResetTimes} = RoleExamineFbInfo,
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	{_MaxResetTimes,ResetGold} = get_reset_times(VipLevel,BarrierID,ResetTimes),
    LogType = ?CONSUME_TYPE_GOLD_BUY_EXAMINE_FB_TIMES,
    case common_bag2:use_money(RoleID, gold_unbind, ResetGold, LogType) of
        {error, Reason} ->
            Msg = #m_examine_fb_reset_toc{err_code=?ERR_OTHER_ERR,reason=Reason},
            ?UNICAST_TOC(Msg);
        true ->
            NewResetTimes = ResetTimes + 1,
            set_role_examine_fb_info(RoleID,RoleExamineFbInfo#r_role_examine_fb{reset_times=NewResetTimes}),
            ResetGolds = get_reset_gold(RoleID,NewResetTimes),
            R2 = #m_examine_fb_reset_toc{reset_gold=ResetGolds,barrier_records=RoleExamineFbInfo#r_role_examine_fb.barrier_records,reset_times=NewResetTimes},
            ?UNICAST_TOC(R2)
    end.

check_can_reset(RoleID,DataIn) ->
	#m_examine_fb_reset_tos{barrier_id=BarrierID} = DataIn,
	case get_role_examine_fb_info(RoleID) of
		{ok,RoleExamineFbInfo}->
			next;
		_ ->
			RoleExamineFbInfo = null,
			?THROW_SYS_ERR()
	end,
	#r_role_examine_fb{barrier_records=BarrierRecords,reset_times=ResetTimes} = RoleExamineFbInfo,
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	{MaxResetTimes,_} = get_reset_times(VipLevel,BarrierID,ResetTimes),
	case MaxResetTimes =< 0 orelse ResetTimes >= MaxResetTimes of
		true ->
			?THROW_ERR( ?ERR_EXAMINE_FB_RESE_TIMES_MAX_LIMIT );
		_ ->
			next
	end,
	NewOpenBarriers = 
		lists:foldl(fun(OpenBarrier,Acc) ->
							#p_examine_fb_barrier{barrier_id=BarrierID1} = OpenBarrier,
							case ?big_barrier_id(BarrierID1) =:= BarrierID of
								true ->
									[OpenBarrier#p_examine_fb_barrier{fight_times=0}|Acc];
								_ ->
									[OpenBarrier|Acc]
							end
					end, [], BarrierRecords),
	{ok,RoleExamineFbInfo#r_role_examine_fb{barrier_records=NewOpenBarriers}}.

get_reset_times(VipLevel,BigBarrierID,BarrResetTimes) ->
    MaxResetTimes = cfg_examine_fb:get_reset_max_times(VipLevel),
	{_,MaxResetTime,NeedGold,FreeTimes} = lists:keyfind(BigBarrierID, 1, MaxResetTimes),
    case BarrResetTimes < FreeTimes of
        true  -> {MaxResetTime, 0};
        false -> {MaxResetTime,NeedGold}
    end.


%% @doc 设置封神战纪地图信息
set_examine_fb_map_info(MapInfo) ->
    #r_examine_fb_map_info{map_role_id=RoleID} = MapInfo,
    mod_role_tab:put(RoleID, ?examine_fb_map_info, MapInfo).

%% @doc 获取封神战纪地图信息
get_examine_fb_map_info(RoleID) ->
    case mod_role_tab:get(RoleID, ?examine_fb_map_info) of
        undefined ->
            {error, not_found};
        MapInfo ->
            {ok, MapInfo}
    end.    
    
%% @interface 进入检验副本
do_examine_fb_enter({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_examine_fb_enter_tos{barrier_id=BarrierID} = DataIn,
    case catch check_do_examine_fb_enter(RoleID,BarrierID,0) of
        {ok,_,RoleExamineFbInfo,FbBarrierConf}->
            do_examine_fb_enter_2(Unique, Module, Method, RoleID, PID,RoleExamineFbInfo,FbBarrierConf);
        {error,ErrCode,Reason}->
            R2 = #m_examine_fb_enter_toc{barrier_id=BarrierID,err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

do_examine_fb_enter_2(Unique, Module, Method, RoleID, PID,RoleExamineFbInfo,FbBarrierConf)->
    #r_examine_fb_barrier_conf{barrier_id=BarrierID,map_id=BarrierMapID} = FbBarrierConf,
    #map_state{mapid=CurrentMapID, map_name=CurrentMapName} = mgeem_map:get_state(),
    %% 如果当前已经在该地图
    case CurrentMapID =:= BarrierMapID of
        true ->
            do_examine_fb_enter_3(Unique, Module, Method, RoleID, PID, RoleExamineFbInfo, BarrierID, CurrentMapID, CurrentMapName);
        _ ->
            BarrierMapName = get_examine_fb_map_name(BarrierMapID, RoleID),
            case global:whereis_name(BarrierMapName) of
                undefined ->
                    mod_map_copy:async_create_copy(BarrierMapID, BarrierMapName, ?MODULE, RoleID),
                    log_async_create_map(RoleID, {Unique, Module, Method, RoleID, PID, RoleExamineFbInfo, BarrierID, BarrierMapID, BarrierMapName});
                _PID ->
                    do_examine_fb_enter_3(Unique, Module, Method, RoleID, PID, RoleExamineFbInfo, BarrierID, BarrierMapID, BarrierMapName)
            end
    end.

do_examine_fb_enter_3(Unique, Module, Method, RoleID, PID, RoleExamineFBInfo, BarrierID, BarrierMapID, BarrierMapName)->
	R2 = #m_examine_fb_enter_toc{barrier_id=BarrierID},
	?UNICAST_TOC(R2), 
	CurMapID = mgeem_map:get_mapid(),
	case is_examine_fb_map_id(CurMapID) of
		true->
			#r_role_examine_fb{enter_times=EnterTimes} = RoleExamineFBInfo,
			case lists:keyfind(BarrierID, 1, EnterTimes) of
				false ->
					EnterTimes2 = [{BarrierID,1}|EnterTimes];
				{_,OldEnterTimes} ->
					EnterTimes2 = [{BarrierID,OldEnterTimes+1}|lists:keydelete(BarrierID, 1, EnterTimes)]
			end,
			NewExamineFbInfo=RoleExamineFBInfo#r_role_examine_fb{enter_times=EnterTimes2},
			set_role_examine_fb_info(RoleID,NewExamineFbInfo);
		false->
			%%第一次进入该副本需要记录位置
			case mod_map_actor:get_actor_pos(RoleID, role) of
				undefined->
					ignore;
				Pos->
					NewExamineFbInfo=RoleExamineFBInfo#r_role_examine_fb{enter_pos = Pos ,enter_mapid = CurMapID},
					set_role_examine_fb_info(RoleID,NewExamineFbInfo)
			end
	end,
	%% 初始化封神战纪地图信息
	MapInfo = #r_examine_fb_map_info{barrier_id=BarrierID, map_role_id=RoleID, start_time=common_tool:now(), first_enter=true},
	global:send(BarrierMapName, {?MODULE, {init_examine_fb_map_info, MapInfo}}),
	%% 传送到新地图
	{_, TX, TY} = common_misc:get_born_info_by_map(BarrierMapID),
	mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, BarrierMapID, TX, TY).

log_async_create_map(RoleID, {Unique, Module, Method, RoleID, PID, RoleExamineFbInfo, BarrierID, BarrierMapID, BarrierMapName}) ->
    erlang:put({examine_fb_roleid, RoleID}, {Unique, Module, Method, RoleID, PID, RoleExamineFbInfo, BarrierID, BarrierMapID, BarrierMapName}).
% get_async_create_map_info(RoleID) ->
%     erlang:get({examine_fb_roleid, RoleID}).
erase_async_create_map_info(RoleID) ->
    erlang:erase({examine_fb_roleid, RoleID}).

%% @doc 检查是否可以进入封神战纪
check_do_examine_fb_enter(RoleID, BarrierID,AutoDeductTili) ->
    % case mod_map_actor:get_actor_mapinfo(RoleID, role) of
    %     undefined ->
    %         RoleMapInfo = undefined,
    %         ?THROW_SYS_ERR();
    %     RoleMapInfo ->
    %         ok
    % end,
    % #p_map_role{state=RoleState} = RoleMapInfo,
    case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
        true ->
            ?THROW_ERR(?ERR_OTHER_ERR, ?_LANG_XIANNVSONGTAO_MSG);
        false -> ignore
    end,
    %% 检查是否副本地图 除封神战纪    
    #map_state{map_type=MapType,mapid=MapID} = mgeem_map:get_state(),
    case MapType of
        ?MAP_TYPE_NORMAL->
            next;
            % %% 是否在外国
            % case common_misc:if_in_enemy_country(FactionID, MapID) of
            %     true->
            %         ?THROW_ERR( ?ERR_EXAMINE_FB_NOT_IN_SELF_COUNTRY );
            %     _ ->
            %         next
            % end;
        _ ->
            case is_examine_fb_map_id(MapID) of
                true->
                    next;
                false->
                    ?THROW_ERR( ?ERR_EXAMINE_FB_ILLEGAL_ENTER_MAP )
            end
    end,
    %% 角色状态检测
    % case RoleState of
    %     ?ROLE_STATE_DEAD ->
    %         ?THROW_ERR( ?ERR_EXAMINE_FB_ENTER_ROLE_DEAD );
    %     ?ROLE_STATE_STALL ->
    %         ?THROW_ERR( ?ERR_EXAMINE_FB_ENTER_ROLE_STALL );
    %     ?ROLE_STATE_FIGHT->
    %         ?THROW_ERR( ?ERR_EXAMINE_FB_ENTER_ROLE_FIGHT );
    %     _ ->
    %         ok
    % end,
    case mod_horse_racing:is_role_in_horse_racing(RoleID) of
        true ->
            ?THROW_ERR( ?ERR_EXAMINE_FB_ENTER_ROLE_HORSE_RACING );
        _ ->
            ignore
    end,
    case get_role_examine_fb_info(RoleID) of
        {ok, RoleExamineFbInfo} ->
            ok;
        _ ->
            RoleExamineFbInfo = undefined,
            ?THROW_SYS_ERR()
    end,
    FbBarrierConf = cfg_examine_fb:get_examine_conf(BarrierID),
    MaxTimes      = FbBarrierConf#r_examine_fb_barrier_conf.enter_max_time,

    %% 关卡是否开启
    #r_role_examine_fb{open_barriers=OpenBarriers,enter_times=EnterTimes,
					   last_enter_time=LastEnterTime,reset_times=OldResetTimes} = RoleExamineFbInfo,
    case  lists:member(BarrierID, OpenBarriers) of
        true->
            next;
        _ ->
            ?THROW_ERR( ?ERR_EXAMINE_FB_ENTER_BARRIER_LOCK )
    end,
    RoleTili = mod_tili:get_role_tili(RoleID),
    case AutoDeductTili of
        0 -> CanUsedTili = RoleTili;
        1 -> CanUsedTili = RoleTili + mod_tili:get_total_tili_card_tili(RoleID);
        2 -> CanUsedTili = RoleTili + mod_tili:get_total_tili_card_tili(RoleID) + mod_tili:get_total_tili_role_can_buy(RoleID)
    end,
	%%检测体力值是否足够
    NeedTili = need_cost_tili(),
    Ret = case CanUsedTili >= NeedTili of
        true ->
            case RoleTili >= NeedTili of
                true -> {tili, 0};
                false ->   
                    case RoleTili + mod_tili:get_total_tili_card_tili(RoleID) >= NeedTili of
                        true -> {tili, 1};
                        false ->
                            {tili, 2}
                    end
            end; 
        false ->
            ?THROW_ERR(?ERR_EXAMINE_FB_ENTER_NO_ENOUGH_TILI)
    end,
	LastEnterDate = common_time:time_to_date(LastEnterTime),
    case date() > LastEnterDate of
		true ->
			ResetTimes=0,
			EnterTimes2=[];
		_ ->
			ResetTimes=OldResetTimes,
			EnterTimes2=EnterTimes
	end,
	assert_barrier_fight_times(RoleID,RoleExamineFbInfo,BarrierID,MaxTimes),
    {ok,Ret,RoleExamineFbInfo#r_role_examine_fb{enter_times=EnterTimes2,reset_times=ResetTimes},FbBarrierConf}.

assert_barrier_fight_times(_RoleID,RoleExamineFbInfo,BarrierID,MaxTimes) ->
	FightTimes = get_fight_times(BarrierID,RoleExamineFbInfo#r_role_examine_fb.barrier_records),
	case FightTimes < MaxTimes of
		true ->
			next;
		false ->
			?THROW_ERR(?ERR_EXAMINE_FB_ENTER_TIMES_LIMITED)
	end,
    ok.
do_reset_barrier_fight_times(RoleID,RoleExamineFbInfo,NewLastEnterTime)->
    NewExFBInfoList = 
        [ExFBBarrierInfo#p_examine_fb_barrier{fight_times=0}|| ExFBBarrierInfo <-RoleExamineFbInfo#r_role_examine_fb.barrier_records],
    NewExFBInfo = RoleExamineFbInfo#r_role_examine_fb{
        barrier_records = NewExFBInfoList,
        reset_times     = 0,
        enter_times     = [],
        last_enter_time = NewLastEnterTime
    },
   set_role_examine_fb_info(RoleID,NewExFBInfo),
    {ok,NewExFBInfo}.

get_fight_times(CheckBarrierID,ExamineFBInfo) ->
	case lists:keyfind(CheckBarrierID, #p_examine_fb_barrier.barrier_id, ExamineFBInfo) of
		#p_examine_fb_barrier{fight_times=FightTimes} ->
			FightTimes;
		_ ->
			0
	end.

%% @interface 退出检验副本
do_examine_fb_quit({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_examine_fb_quit_tos{quit_type=QuitType} = DataIn,
    case catch check_do_examine_fb_quit(RoleID) of
        ok->
            do_examine_fb_quit_2(RoleID, QuitType);
        {error,ErrCode,Reason}->
            R2 = #m_examine_fb_quit_toc{quit_type=QuitType,err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

%% @doc 是否可以退出副本
check_do_examine_fb_quit(_RoleID) ->
    ok.

do_examine_fb_quit_2(RoleID, QuitType) ->
    case QuitType of
        ?examine_fb_quit_type_normal -> %% 主动退出
            ignore;
        ?examine_fb_quit_type_relive -> %% 在副本死亡退出
            mod_role2:relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, RoleID, ?RELIVE_TYPE_HOME_FREE_HALF);
        ?examine_fb_quit_type_timeout -> %%在副本超时退出
            case get_examine_fb_map_info(RoleID) of   
                {ok, #r_examine_fb_map_info{barrier_id=BarrierID}}->
                    R2C = #m_examine_fb_report_toc{barrier_id=BarrierID,fb_state=?EXAMINE_FB_STATE_FAIL},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXAMINE_FB, ?EXAMINE_FB_REPORT, R2C);
                _ ->
                    ignore
            end
    end,
    common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?EXAMINE_FB,?EXAMINE_FB_QUIT,#m_examine_fb_quit_toc{quit_type=QuitType}),
    case QuitType == ?examine_fb_quit_type_normal orelse
         QuitType == ?examine_fb_quit_type_timeout of
        true ->
            {ok,#r_role_examine_fb{enter_pos=EnterPos,enter_mapid=EnterMapID}} = get_role_examine_fb_info(RoleID),
            case is_record(EnterPos,p_pos) 
                     andalso erlang:is_integer(EnterMapID) 
                     andalso EnterMapID>0 of
                true->
                    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, EnterMapID, EnterPos#p_pos.tx, EnterPos#p_pos.ty);
                false->
                    {DestMapId,TX,TY} = get_examine_fb_return_pos(RoleID),
                    mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapId, TX, TY)
            end;
        false -> ignore
    end.
    

%%返回京城出生点
get_examine_fb_return_pos(RoleID)->
    common_map:get_map_return_pos_of_jingcheng(RoleID).
 
%% @interface 打开检验副本面板
do_examine_fb_panel({Unique, Module, Method, _DataIn, RoleID, PID, _Line})->
    case catch check_do_examine_fb_panel(RoleID) of
        {ok,RoleExamineFbInfo}->
            send_fb_panel_to_client(RoleID, RoleExamineFbInfo);
        {error,ErrCode,Reason}->
            R2 = #m_examine_fb_panel_toc{err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

send_fb_panel_to_client(RoleID, RoleExamineFbInfo) ->
     #r_role_examine_fb{barrier_records=RoleRecs,open_barriers=OpenBarriers,
                       finish_barriers=FinishBarriers,reset_times=ResetTimes,
                       last_enter_time=LastEnterTime} = RoleExamineFbInfo,
    Fun1 = fun(BarrierID) ->
        case cfg_examine_fb:examine_to_hidden_barriers(BarrierID) of
            [] -> true;
            _  -> false
        end 
    end,
    Fun2 = fun(#p_examine_fb_barrier{barrier_id = BarrierID}) ->
        case cfg_examine_fb:examine_to_hidden_barriers(BarrierID) of
            [] -> true;
            _  -> false
        end 
    end,
    FbPanel = #p_examine_fb_panel_info{
        open_barriers   = OpenBarriers,
        finish_barriers = lists:filter(Fun1, FinishBarriers),
        barrier_records = lists:filter(Fun2, RoleRecs),
        last_enter_time = LastEnterTime
    },
    ResetGolds = get_reset_gold(RoleID,ResetTimes),
    HiddenBarriersRec = get_role_hidden_ex_fb_info(RoleID),
    Msg = #m_examine_fb_panel_toc{
        reset_times            = ResetTimes,
        fb_panel               = FbPanel,
        reset_gold             = ResetGolds,
        open_hidden_barriers   = HiddenBarriersRec#r_role_hidden_examine_fb.open_barriers,
        finish_hidden_barriers = HiddenBarriersRec#r_role_hidden_examine_fb.finish_barriers
    },
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXAMINE_FB, ?EXAMINE_FB_PANEL, Msg).


check_do_examine_fb_panel(RoleID)->
    case get_role_examine_fb_info(RoleID) of
        {ok, RoleExamineFbInfo} ->
            {ok, RoleExamineFbInfo};
        _ ->
            ?THROW_SYS_ERR()
    end.

get_reset_gold(RoleID,ResetTimes) ->
	VipLevel = mod_vip:get_role_vip_level(RoleID),
    BigBarrierList = cfg_examine_fb:get_misc(big_barrier_list),
	lists:map(fun(BarrierID) -> 
					  {_MaxResetTimes,ResetGold} = get_reset_times(VipLevel,BarrierID,ResetTimes),
					  #p_reset_gold{barrier_id=BarrierID,gold=ResetGold}  end, BigBarrierList).


hook_role_before_quit(RoleID) ->
    case get_examine_fb_map_info(RoleID) of
        {ok, ExamineFBMapInfo}  ->
            #map_state{mapid=MapID} = mgeem_map:get_state(),
            case MapID == ExamineFBMapInfo#r_examine_fb_map_info.mapid of
                true ->
                    #r_examine_fb_map_info{barrier_id = BarrierID} = ExamineFBMapInfo,
                    mgeer_role:send(RoleID, {apply, hook_examine_fb, hook_fb_quit, [RoleID, BarrierID]});
                false -> ignore
            end;
        _ ->
            ignore
    end.

%% @doc 角色退出地图hook
hook_role_quit(RoleID) ->
    case get_examine_fb_map_info(RoleID) of
        {ok, ExamineFBMapInfo}  ->
            hook_role_quit2(RoleID, ExamineFBMapInfo);
        _ ->
            ignore
    end.

hook_role_quit2(RoleID, ExamineFBMapInfo) ->
    #map_state{mapid=MapID, map_name=MapName} = mgeem_map:get_state(),
    case MapID == ExamineFBMapInfo#r_examine_fb_map_info.mapid of
        true ->
            % #r_examine_fb_map_info{barrier_id = BarrierID} = ExamineFBMapInfo,
            % mgeer_role:send(RoleID, {apply, hook_examine_fb, hook_fb_quit, [RoleID, BarrierID]}),
            case mod_map_actor:is_change_map_quit(RoleID) of
                {true, MapID} ->
                    %% 重新打这一章
                    catch do_examine_fb_log(ExamineFBMapInfo),
                    %% 删除所有怪物
                    mod_map_monster:delete_all_monster(),
                    %% 重新出生怪物
                    mod_map_monster:init_monster_id_list(),
                    mod_map_monster:init_map_monster(MapName, MapID);
                _ ->
                    hook_role_quit3(RoleID, ExamineFBMapInfo)
            end;
        false ->
            ignore
    end.

hook_role_quit3(RoleID, ExamineFBMapInfo) ->
    #r_examine_fb_map_info{barrier_id = BarrierID} = ExamineFBMapInfo,
    case cfg_examine_fb:examine_to_hidden_barriers(BarrierID) =/= [] of
        true ->
            %% 因为隐藏关卡可能是一个普通关卡的副本，
            %% 因此该副本完成时，其对应的隐藏关卡也就完成了
            mod_hidden_examine_fb:check_and_do_finish_hidden_barrier(RoleID, BarrierID),
            close_barrier(RoleID, ExamineFBMapInfo);
        false ->
            case mod_map_role:is_role_exit_game(RoleID) of
                true ->
                    %%第几关之后，玩家退出地图则怪物自动满血
                    RecoverHpWhenQuitMap = cfg_examine_fb:get_misc(recover_hp_when_quit_map),
                    case BarrierID>=RecoverHpWhenQuitMap of 
                        true ->
                            MonsterIdList = mod_map_monster:get_monster_id_list(),
                            ?TRY_CATCH( [ mod_map_monster:do_monster_recover_max(MonsterID)  ||MonsterID<-MonsterIdList ] );
                        _ ->
                            next
                    end,
                    %% 玩家在副本中退出地图，地图进程会保持一段时间
                    ProtectTime = cfg_examine_fb:get_misc(offline_protect_time),
                    erlang:send_after(ProtectTime*1000, self(), {?MODULE, {RoleID, offline_terminate}});
                _ ->
                    close_barrier(RoleID, ExamineFBMapInfo)
            end
    end.

%% 关闭该关卡进程
close_barrier(RoleID, ExamineFBMapInfo) ->
    mod_role_tab:erase(RoleID, ?examine_fb_map_info),
    common_map:exit( examine_fb_role_quit3 ),
    catch do_examine_fb_log(ExamineFBMapInfo).

%%@doc 玩家上线时，根据技能列表来初始化检验副本的关卡数量，并且发送入口显示的接口
hook_role_online(_RoleID, _Level)->
    ok.

hook_role_offline(RoleID) ->
    mod_skill:change_skill_level_temp(RoleID).

hook_role_enter(RoleID,_MapID)->
    % 首先删除玩家的变身符添加的buff
    case is_in_examine_fb(RoleID) of
        true ->
            [RemoveBuffTypeList] = common_config_dyn:find(item_change_skin, buff_type_list),
            mod_role_buff:del_buff_by_type(RoleID, RemoveBuffTypeList),
                        %%进入任意战役副本的任务..
            mgeer_role:run(RoleID, fun() -> hook_mission_event:hook_special_event(RoleID,?MISSION_EVENT_EXAMINE_ENTER) end),
            
            case get_examine_fb_map_info(RoleID) of
                %% 第一次进入，进入后扣次数
                {ok, #r_examine_fb_map_info{barrier_id=BarrierID,map_role_id=RoleID,first_enter=true}=MapInfo} ->
                    %%初始化修改副本的开始/结束时间
                    FbOpenLastTime = cfg_examine_fb:get_misc(fb_open_max_last_time),
                    StartTime = common_tool:now(),
                    EndTime = StartTime + FbOpenLastTime,
                    MapInfo2 = MapInfo#r_examine_fb_map_info{start_time=StartTime,end_time=EndTime, first_enter=false},
                    set_examine_fb_map_info(MapInfo2),
                    
                    hook_role_enter_2(RoleID,BarrierID),
                    
                    %% 删除结束标志
                    mod_role_tab:erase(RoleID, ?EXAMINE_FB_FINISH_STATE),
                    clear_timeout_ref(),
                    TimerRef = erlang:send_after(FbOpenLastTime*1000, self(), {?MODULE, {RoleID, fb_timeout_kick}}),
                    erlang:put(?EXAMINE_FB_TIMEOUT_REF, TimerRef),
                    
                    %% 发送副本状态
                    R2C = #m_examine_fb_state_toc{start_time=StartTime,end_time=EndTime},
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXAMINE_FB, ?EXAMINE_FB_STATE, R2C),
                    case is_bonus_barrier(BarrierID) of
                        true ->
                            common_misc:send_common_error(RoleID, 0, <<"该关卡为奖励关卡，怪物将一波波出现，多杀多得经验，直到副本关闭为止！">>);
                        false -> ignore
                    end,
                    case cfg_examine_fb:examine_to_hidden_barriers(BarrierID) =/= [] of
                        true ->
                            common_misc:send_common_error(RoleID, 0, <<"无论退出或死亡，都将消耗进入副本的次数">>);
                        false -> ignore
                    end,
                    mgeer_role:send(RoleID, {apply, hook_examine_fb, hook_fb_enter, [RoleID, BarrierID]}),
                    ok;
                %% 下线后再进入，不扣次数
                {ok, #r_examine_fb_map_info{barrier_id=BarrierID,start_time=StartTime,end_time=EndTime}} ->
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXAMINE_FB, ?EXAMINE_FB_ENTER, #m_examine_fb_enter_toc{barrier_id=BarrierID}),
                    R2C = #m_examine_fb_state_toc{start_time=StartTime,end_time=EndTime},
                    % mgeer_role:send(RoleID, {apply, hook_examine_fb, hook_fb_enter, [RoleID, BarrierID]}),
                    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXAMINE_FB, ?EXAMINE_FB_STATE, R2C)
            end;
        false ->
            %% 这里只所以再次判断，是因为副本超时通知玩家退出时，但客户端却没有响应之后
            %% 该副本进程也不会死掉的，因此在副本超时时设置这个标识然后在玩家进入将其踢出副本
            case erlang:erase(examine_fb_timeout_flag) of
                true ->
                    do_examine_fb_quit_2(RoleID, ?examine_fb_quit_type_timeout);
                _ -> ignore
            end
    end.
hook_role_enter_2(RoleID,_BarrierID)->
	%%扣除体力
	mod_tili:reduce_role_tili(RoleID, need_cost_tili(),true),
	%%     %% 增加本关攻击次数
	%%     {ok,_NewRoleRecs,NewRoleExamineFbInfo} = add_barrier_fight_times(RoleID,BarrierID),
	%%     notify_fb_panel_info(RoleID,NewRoleExamineFbInfo),
	ok.

add_barrier_fight_times(RoleID,BarrierID) ->
	{ok,RoleExamineFbInfo} = get_role_examine_fb_info(RoleID),
    #r_role_examine_fb{barrier_records=RoleRecs} = RoleExamineFbInfo,
    NewBarrierRec = case lists:keyfind(BarrierID, #p_examine_fb_barrier.barrier_id, RoleRecs) of
        #p_examine_fb_barrier{fight_times=OldFightTImes} = OldBarrierRec ->
            OldBarrierRec#p_examine_fb_barrier{fight_times=OldFightTImes + 1};
        _ ->
            #p_examine_fb_barrier{barrier_id=BarrierID,status=?BARRIER_STATUS_PASS,fight_times=1}
    end,
    NewRoleRecs = lists:keystore(BarrierID, #p_examine_fb_barrier.barrier_id, RoleRecs, NewBarrierRec),
    LastEnterTime = common_tool:now(),
    NewRoleExamineFbInfo = RoleExamineFbInfo#r_role_examine_fb{barrier_records=NewRoleRecs,
                                                               last_enter_time=LastEnterTime},
    set_role_examine_fb_info(RoleID,NewRoleExamineFbInfo),
	{ok,NewRoleRecs,NewRoleExamineFbInfo}.
	

%%通知更新面板数据
% notify_fb_panel_info(RoleID,RoleExamineFbInfo) when is_integer(RoleID)->
% 	#r_role_examine_fb{open_barriers=OpenBarriers,barrier_records=RoleRecs,finish_barriers=FinishBarriers,
% 					   last_enter_time=LastEnterTime,reset_times=ResetTimes} = RoleExamineFbInfo,
% 	FbPanel = #p_examine_fb_panel_info{open_barriers=OpenBarriers,finish_barriers=FinishBarriers,
% 									   barrier_records=RoleRecs,last_enter_time=LastEnterTime},
% 	ResetGolds = get_reset_gold(RoleID,ResetTimes),
% 	R2C = #m_examine_fb_panel_toc{fb_panel=FbPanel,reset_gold=ResetGolds,reset_times=ResetTimes},
% 	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXAMINE_FB, ?EXAMINE_FB_PANEL, R2C),
% 	ok.

hook_role_dead(RoleID)->
    case get_examine_fb_map_info(RoleID) of
        {ok,#r_examine_fb_map_info{barrier_id=BarrierID,map_role_id=RoleID}}->
            R2C = #m_examine_fb_report_toc{barrier_id=BarrierID,fb_state=?EXAMINE_FB_STATE_FAIL},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXAMINE_FB, ?EXAMINE_FB_REPORT, R2C);
        _ ->
            ignore
    end.

%%时装、座骑强化到XXX级 或者XX阶即可进入该关卡（装备系统）；
hook_equip_qianghua(_RoleID, _SlotNum, _ReinforceResult) ->
	ignore.


%%拥有某个装备
hook_equip_upgrade(_RoleID, _EquipInfo) ->
	ignore.


%%异兽的资质 达到某个值（ 例如50）即可进入某个副本
hook_pet_aptitude_upgrade(_RoleID, _PetID, _PetTotalAptitude) ->
	ignore.


%%异兽的阶位 达到XX阶（例如2阶）即可进入某个副本
hook_pet_period_upgrade(_RoleID, _PetID, _PetPeriod) ->
	ignore.


%%7个小星宿，任何一个星宿强化到XX级（例如3级 ）即可进入副本；
hook_skill_upgrade(_RoleID, _SkillID, _Level) ->
	ignore.


%%星宿系统达到本命星XX级（例如2级）即可进入副本
hook_skill_life_star_upgrade(_RoleID, _Level) ->
	ignore.

%% @doc 怪物死亡
hook_monster_dead(RoleID, MonsterBaseInfo) ->
    case get_examine_fb_map_info(RoleID) of
        {ok, MapInfo} ->
            RoleID = MapInfo#r_examine_fb_map_info.map_role_id,
            case mod_role_tab:get(RoleID, ?EXAMINE_FB_FINISH_STATE) of
                true->
                    ignore;
                _ ->
                    hook_monster_dead_2(MonsterBaseInfo,MapInfo)
            end;    
        {error, _} ->
            ignore
    end.

hook_monster_dead_2(MonsterBaseInfo,MapInfo)->
	#r_examine_fb_map_info{
        start_time  = EnterTime, 
        barrier_id  = BarrierID, 
        mapid       = MapID,
        map_role_id = RoleID} = MapInfo,
	case cfg_examine_fb:called_monster(BarrierID, MonsterBaseInfo#p_monster_base_info.typeid) of
        [] -> ignore;
        CalledMosters ->
            {ok, RolePos} = mod_map_role:get_role_pos_detail(RoleID),
            #p_role_pos{pos=#p_pos{tx=TX, ty=TY}} = RolePos,
            {X, Y} = mod_spiral_search:get_walkable_pos(MapID, TX + 4, TY + 4, 5),
            CalledMosters1 = [{MonsterID, X, Y} || MonsterID <- CalledMosters],
            mod_map_monster:handle({dynamic_create_monster2, CalledMosters1}, mgeem_map:get_state())
    end,
	%% 清完所有怪，计时
	RemainMonsterNum = erlang:length(mod_map_monster:get_monster_id_list()) - 1,
	case RemainMonsterNum =< 0 of
		true ->
            case is_bonus_barrier(BarrierID) of
                false ->
    			    hook_all_monster_dead(MapInfo, get_time_used(EnterTime));
                true ->
                    %% 召唤新的一波怪
                    case call_bonus_monster(RoleID, BarrierID) of
                        false -> hook_all_monster_dead(MapInfo, get_time_used(EnterTime));
                        true -> ignore
                    end
            end,
    		ok;   
		_ ->
			ignore
	end.

commit_mission(RoleID, BarrierID) ->
    %% 完成任务(这里之所以调用这个是因为进入战力副本完成任务的那个任务配置数据使用的就是这个mode)
    mgeer_role:run(RoleID, fun() -> hook_mission_event:hook_enter_hero_fb(RoleID, BarrierID) end).

%% 是否是隐藏关卡奖励的普通关卡
is_bonus_barrier(BarrierID) ->
    (cfg_examine_fb:call_bonus_monster(BarrierID) =/= []).

call_bonus_monster(RoleID, BarrierID) ->
    case cfg_examine_fb:call_bonus_monster(BarrierID) of
        [] -> false;
        CalledMosters ->
            mod_map_monster:handle({dynamic_create_monster2, CalledMosters}, mgeem_map:get_state()),
            common_misc:send_common_error(RoleID, 0, <<"又一波怪物来袭，赶紧去剿灭吧！">>),
            true
    end.

hook_all_monster_dead(MapInfo, TimeUsed) ->
    #r_examine_fb_map_info{map_role_id=RoleID, barrier_id=BarrierID} = MapInfo,

    mod_random_mission:handle_event(RoleID,?RAMDOM_MISSION_EVENT_1),
    clear_assist_monster(BarrierID),
    %% 完成并增加本关攻击次数
    {ok,_NewRoleRecs,_NewRoleExamineFbInfo} = add_barrier_fight_times(RoleID,BarrierID),
    % notify_fb_panel_info(RoleID,NewRoleExamineFbInfo),
    open_examin_fb_barrier(RoleID,BarrierID),
    add_enter_times(RoleID,BarrierID),
    mod_hidden_examine_fb:do_open_hidden_barrier(RoleID, BarrierID),
    %% 因为隐藏关卡可能是一个普通关卡的副本，
    %% 因此该副本完成时，其对应的隐藏关卡也就完成了
    mod_hidden_examine_fb:check_and_do_finish_hidden_barrier(RoleID, BarrierID),

    %% 蛋疼的暂时修改策划的配置错误
    case cfg_examine_fb:examine_to_hidden_barriers(BarrierID) of
        [] -> commit_mission(RoleID, BarrierID);
        HiddenId ->
            commit_mission(RoleID, HiddenId)
    end,
    {ok,RoleExamineFBInfo} = get_role_examine_fb_info(RoleID),
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    %%基础分
    {BaseScore,_,_} = cfg_hero_fb:get_misc(fb_star_level),
    {ok,FbScore,StarLevel} = get_barrier_score(RoleID,RoleAttr,BaseScore,BarrierID,TimeUsed),

    
    #r_role_examine_fb{barrier_records=FBRecordList} = RoleExamineFBInfo,
    %% 一定会有记录 没有就是错的
    Record = lists:keyfind(BarrierID, #p_examine_fb_barrier.barrier_id, FBRecordList),
    case FbScore >= Record#p_examine_fb_barrier.score of
        true->
            Record2 = Record#p_examine_fb_barrier{
                time_used  = TimeUsed,
                star_level = StarLevel,
                score      = FbScore
            };
        false->
            Record2 = Record
    end,
    FbRecordList2 = lists:keystore(BarrierID, #p_examine_fb_barrier.barrier_id, FBRecordList, Record2),
    NewRoleExamineFBInfo = RoleExamineFBInfo#r_role_examine_fb{barrier_records = FbRecordList2},
    set_role_examine_fb_info(RoleID, NewRoleExamineFBInfo),
    BarrierConfRec = cfg_examine_fb:get_barrier_conf(BarrierID),
    %% 设置初始翻牌数据（目前改为只给一次免费的翻牌次数）
    SelectTimes = 1,
    set_select_data(RoleID, SelectTimes, 0, BarrierConfRec#r_barrier_conf.can_fetch),
    %% 设置初始奖励权重 
    set_remain_reward_weights(RoleID, {?INIT_SELECT_TIMES, cfg_examine_fb:get_weights(BarrierID)}, BarrierConfRec#r_barrier_conf.can_fetch),

    mod_role_tab:put(RoleID, ?EXAMINE_FB_FINISH_STATE, true),    %%标记副本已经结束
    clear_timeout_ref(), 

    Result = #p_examine_fb_barrier{
        barrier_id  = BarrierID,
        status      = ?EXAMINE_FB_STATE_SUCC,
        fight_times = Record#p_examine_fb_barrier.fight_times,
        time_used   = TimeUsed,
        star_level  = StarLevel,
        score       = FbScore
    },
    % %% 第一次三星通过时加满怒气
    % case Record#p_examine_fb_barrier.star_level < 3 andalso StarLevel >= 3 of
    %     true  -> 
    %         Notice = 1,
    %         mod_map_role:add_max_nuqi(RoleID);
    %     false -> 
    %         Notice = 0
    % end,
    Notice = 0,
    R2C = #m_examine_fb_report_toc{
        barrier_id     = BarrierID,
        fb_state       = ?EXAMINE_FB_STATE_SUCC,
        result         = Result,
        can_fetch      = BarrierConfRec#r_barrier_conf.can_fetch,
        can_gold_fetch = BarrierConfRec#r_barrier_conf.can_gold_fetch,
        exp            = BarrierConfRec#r_barrier_conf.reward_exp,
        prestige       = BarrierConfRec#r_barrier_conf.reward_prestige,
        silver         = BarrierConfRec#r_barrier_conf.reward_silver,
        yueli          = BarrierConfRec#r_barrier_conf.reward_yueli,
        remain_times   = SelectTimes,
        items          = [Id || {Id,_,_,_} <- BarrierConfRec#r_barrier_conf.reward_items],
        notice         = Notice
    },
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXAMINE_FB, ?EXAMINE_FB_REPORT, R2C),
    Fun = fun() -> common_barrier:send_reward(RoleID, 
                               R2C#m_examine_fb_report_toc.exp,
                               R2C#m_examine_fb_report_toc.prestige,
                               R2C#m_examine_fb_report_toc.silver,
                               R2C#m_examine_fb_report_toc.yueli,
                               BarrierConfRec#r_barrier_conf.reward_items) end,
    mgeer_role:run(RoleID, Fun),
    case is_bonus_barrier(BarrierID) of
        true -> ignore;
        _  -> send_fb_panel_to_client(RoleID, NewRoleExamineFBInfo)
    end, 
    ok.


%% @doc 计算闯关时间(ms)
get_time_used(EnterTime) ->
	(common_tool:now() - EnterTime) * 1000.


add_enter_times(RoleID,BarrierID) ->
	case get_role_examine_fb_info(RoleID) of
		{ok,#r_role_examine_fb{enter_times=EnterTimes,finish_barriers=FinishBarriers}=RoleExamineFbInfo}->
			case lists:keyfind(BarrierID, 1, EnterTimes) of
				false ->
					EnterTimes2 = [{BarrierID,1}|EnterTimes]; 
				{_,TodayCount} ->
					EnterTimes2 = [{BarrierID,TodayCount+1}|lists:keydelete(BarrierID, 1, EnterTimes)]
			end,
			set_role_examine_fb_info(RoleID,RoleExamineFbInfo#r_role_examine_fb{enter_times=EnterTimes2,finish_barriers=[BarrierID|lists:delete(BarrierID, FinishBarriers)]});
		_ ->
			ignore
	end.
		
%%这里开启要检测开不开
open_examin_fb_barrier(_RoleID, _BarrierID) ->
    %% 现在副本的开启都是根据人物等级来的，这里不需要开启的
    ok.
					
	
%%这里不需要检测
open_barrier(RoleID,BarrierID) ->
	case get_role_examine_fb_info(RoleID) of
		{ok,#r_role_examine_fb{open_barriers=OpenBarriers,own_condition=OwnCondition}=RoleExamineFbInfo}->
			RoleExamineFbInfo2 = RoleExamineFbInfo#r_role_examine_fb{open_barriers=[BarrierID|OpenBarriers],own_condition=lists:keydelete(BarrierID, 1, OwnCondition)},
			set_role_examine_fb_info(RoleID,RoleExamineFbInfo2),
            {ok, RoleExamineFbInfo2};
		_ ->
			ignore
	end.

%% 开启并重置关卡的次数
open_and_reset_barrier_times(RoleID, BarrierID) ->
    case get_role_examine_fb_info(RoleID) of
        {ok,#r_role_examine_fb{open_barriers=OpenBarriers}=RoleExamineFbInfo}->
            case lists:member(BarrierID, OpenBarriers) of
                false ->
                    RoleExamineFbInfo2 = RoleExamineFbInfo#r_role_examine_fb{open_barriers = [BarrierID|OpenBarriers]};
                true ->
                    RoleExamineFbInfo2 = RoleExamineFbInfo#r_role_examine_fb{
                        enter_times = lists:keydelete(BarrierID, 1, RoleExamineFbInfo#r_role_examine_fb.enter_times),
                        barrier_records = lists:keydelete(BarrierID, #p_examine_fb_barrier.barrier_id, RoleExamineFbInfo#r_role_examine_fb.barrier_records),
                        finish_barriers = lists:delete(BarrierID, RoleExamineFbInfo#r_role_examine_fb.finish_barriers)
                    }
            end,
            set_role_examine_fb_info(RoleID,RoleExamineFbInfo2),
            send_fb_panel_to_client(RoleID, RoleExamineFbInfo2);
        _ ->
            ignore
    end.

get_finish_barrier(RoleID) ->
	case get_role_examine_fb_info(RoleID) of
		{ok,#r_role_examine_fb{finish_barriers=FinishBarriers}}->
			FinishBarriers;
		_ ->
			ignore
	end.
%%@doc 获取玩家的检验副本数据
get_role_examine_fb_info(RoleID)->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,#r_role_map_ext{role_examine_fb=RoleExamineFb1}} when is_record(RoleExamineFb1,r_role_examine_fb)->
            #r_role_examine_fb{role_id=RoleID, last_enter_time=LastEnterTime1} = RoleExamineFb1,
            Now = common_tool:now(),
            case common_tool:check_if_same_day(LastEnterTime1, Now) of
                true -> {ok, RoleExamineFb1};
                false ->
                    {ok, RoleExamineFb2} = do_reset_barrier_fight_times(RoleID,RoleExamineFb1,Now),
                    {ok, RoleExamineFb2}
            end;
        _ ->
            {error,not_found}
    end.

%%@doc 事务外设置玩家的检验副本数据
set_role_examine_fb_info(RoleID,NewExamineFbInfo) when is_integer(RoleID)->
    TransFun = fun()-> t_set_role_examine_fb_info(RoleID, NewExamineFbInfo) end,
    case common_transaction:t( TransFun ) of
        {atomic, _} ->
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("set_role_examine_fb_info, error: ~w", [Error]),
            error
    end.

t_set_role_examine_fb_info(RoleID, NewExamineFbInfo) when is_record(NewExamineFbInfo,r_role_examine_fb) ->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,#r_role_map_ext{}=RoleMapExt}->
            mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt#r_role_map_ext{role_examine_fb=NewExamineFbInfo});
        _ ->
            ?THROW_SYS_ERR()
    end.

%% --------------------------------------------------------------------
%%% 内部二级函数
%% --------------------------------------------------------------------
is_examine_fb_map_id(DestMapID)->
    cfg_examine_fb:is_examine_fb_map_id(DestMapID).

%% @doc 封神战纪日志
do_examine_fb_log(ExamineFBMapInfo) ->
    #r_examine_fb_map_info{map_role_id=RoleID, barrier_id=BarrierID, start_time=StartTime} = ExamineFBMapInfo,
    RemainMonster = erlang:length(mod_map_monster:get_monster_id_list()),
    case RemainMonster =:= 0 of
        true ->
            Status = ?fb_quit_status_finish;
        _ ->
            Status = ?fb_quit_status_fail
    end,
    
    EndTime = common_tool:now(),
    ExamineFbLog = #r_examine_fb_log{role_id=RoleID,
                                      barrier_id=BarrierID,
                                      start_time=StartTime,
                                      end_time=EndTime,
                                      status=Status},
    common_general_log_server:log_examine_fb(ExamineFbLog).

%%将辅助怪物都一一杀掉
clear_assist_monster(_BarrierID)->
    ok.

%% 成功过关后扣取的体力值
need_cost_tili() ->
    cfg_examine_fb:get_misc(need_cost_tili).

%%解析错误码
parse_aborted_err(AbortErr)->
    case AbortErr of
        {error,ErrCode,_Reason} when is_integer(ErrCode) ->
            AbortErr;
        {error,AbortReason} when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
		{bag_error,{not_enough_pos,_BagID}}->
            {error,?ERR_EXAMINE_FB_BOX_BAG_FULL,undefined};
		{bag_error,BagError}->
            ?ERROR_MSG_STACK( "RoleID=~w,BagError=~w",[BagError] ),
            {error,?ERR_EXAMINE_FB_BOX_BAG_FULL,undefined};
        AbortReason when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        _ ->
            ?ERROR_MSG(" aborted,AbortErr=~w,stack=~w",[AbortErr,erlang:get_stacktrace()]),
            {error,?ERR_SYS_ERR,undefined}
    end.

-define(MIN_BARRIER_ONE_STAR,105). %%前五关都是九等

%%@return {ok,Score,Star}
get_barrier_score(_,_,_BaseScore,BarrierID,_) when BarrierID=<?MIN_BARRIER_ONE_STAR->
    {_BaseScore,_MidScore,HighScore} = cfg_hero_fb:get_misc(fb_star_level),
    {ok,HighScore,3};
get_barrier_score(RoleID,RoleAttr,_BaseScore,BarrierID,TimeUsed)->
    get_barrier_score_2(RoleID,RoleAttr,BarrierID,TimeUsed).

get_barrier_score_2(_RoleID,_RoleAttr,BarrierID,TimeUsed)->
    %%公式：装备分+战力分+时间分
    % #p_role_attr{equips=Equips}=RoleAttr,
    
    % EquipColorScore = get_fb_equip_color_score(Equips),
    % FightPowerScore = get_fb_fightpower_score(RoleID,BarrierID,RoleAttr),
    FightPowerScore = 0,
    EquipColorScore = 0,
    TimeScore = get_fb_time_score(BarrierID,TimeUsed),
    
    AllScore = erlang:trunc( EquipColorScore+FightPowerScore+TimeScore ),
    {_,SndStar,TrdStar} = cfg_hero_fb:get_misc(fb_star_level),
    if
        AllScore>=TrdStar->
            {ok,AllScore,3};
        AllScore>=SndStar->
            {ok,AllScore,2};
        true->
            {ok,AllScore,1}
    end.

-define(CHECK_FIX_SCORE(Score,FixScore),
        if
            Score>=FixScore-> FixScore;
            Score>0-> Score;
            true-> 1
        end).

%%装备品质分数
% get_fb_equip_color_score(Equips)->
%     Score = lists:foldl(
%       fun(Goods,Acc)->
%               case Goods#p_goods.type of 
%                   ?TYPE_EQUIP->
%                       [EquipBaseInfo] = common_config_dyn:find_equip(Goods#p_goods.typeid),
%                       #p_equip_base_info{slot_num=SlotNum} = EquipBaseInfo,
%                       #p_goods{current_colour=Colour} = Goods,
%                       if
%                           SlotNum=:=?PUT_MOUNT orelse SlotNum=:=?PUT_FASHION orelse SlotNum=:=?PUT_ADORN
%                               orelse SlotNum=:=?PUT_JINGJIE orelse SlotNum=:=?PUT_SHENQI orelse SlotNum=:=?PUT_LEITAI ->
%                               Acc;
%                           true->
%                               if
%                                   Colour<1-> Acc;
%                                   true-> 
%                                       Acc+(Colour-1)*2 %%%%紫色:6,橙色:8
%                               end
%                       end;
%                   _->Acc
%               end     
%       end, 0, Equips),
%     ?CHECK_FIX_SCORE(Score,100).

%%战斗力
% get_fb_fightpower_score(RoleID,BarrierID,RoleAttr)->
%     {ok,RoleBase} = mod_map_role:get_role_base(RoleID),
%     #r_barrier_conf{score_power_param=ExpectPower} = cfg_examine_fb:get_barrier_conf(BarrierID),
%     FightPower = common_role:get_fighting_power(RoleBase, RoleAttr),
%     Score =500*FightPower div ExpectPower,
%     ?CHECK_FIX_SCORE(Score,500).

 %%时间分数
get_fb_time_score(BarrierID,TimeUsed)->
    %% TimeUsed 是毫秒 
    TimeUsedSecs = TimeUsed div 1000,
    #r_barrier_conf{score_time_param=ExpectTimes} = cfg_examine_fb:get_barrier_conf(BarrierID),
    Score =ExpectTimes-TimeUsedSecs*100 div 15,
    ?CHECK_FIX_SCORE(Score,800).   