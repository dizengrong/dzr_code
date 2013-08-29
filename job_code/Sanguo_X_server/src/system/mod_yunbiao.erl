-module(mod_yunbiao).
-behaviour(gen_server).

-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

-export([init_yunbiao/1,
		 start_link/1,
		 request_yunbiao_message/1,
		 get_biaoche_data/1,
		 request_jixing_message/1,
		 refresh_biaoche_type/1,
		 get_random_gem/1,
		 onekey_refresh_biaoche_type/1,
		 zhuan_yun/1,
		 get_random_gem_1/4,
		 start_yunbiao_task/2,
		 commit_yunbiao_task/2,
		 rob_yun_biao/2,
		 do_rob_yunbiao/2,
		 rob_yunbiao_battle/3,
		 send_to_client/2,
		 client_request_yun_biao_state/1,
		 get_biaoche_record/1,
		 client_request_continue_to_yun_biao/2
		 ]).

-include("common.hrl").
-define(FACTOR_RECORD, {1.3,1.2,1}).


init_yunbiao(Id)->
	?INFO(yunbiao,"init yunbiao ,id:~w",[Id]),
	Yunbiao = #yun_biao{
					id       = Id,
					state 	 = 0,
%% 					yun_biao_times = 0,
					gem_type       = 1,
					last_yb_time   = 0
%% 					rob_times      = 0,   %%打劫次数
%% 					robed_times    = 0   %%被劫次数
					},
	gen_cache:insert(?CACHE_YUN_BIAO, Yunbiao),
	ok.


start_link(AccountID)->
	gen_server:start_link(?MODULE, [AccountID], []).

init([AccountID])->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, AccountID),
	mod_player:update_module_pid(AccountID, ?MODULE, self()),
	{ok, null}.


%%%=======================================================================
%%%=========================export functions==============================

request_yunbiao_message(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.yunbiao_pid, {request_yunbiao_message, Id}).

request_jixing_message(Id)->
	?INFO(yunbiao, "request_jixing_message:Id:~w",[Id]),
	PS = mod_player:get_player_status(Id),
	Pid = PS#player_status.yunbiao_pid,
	?INFO(yunbiao, "Pid :~w",[Pid]),
	gen_server:cast(PS#player_status.yunbiao_pid, {request_jixing_message, Id}),
	?INFO(yunbiao, "self pid :~w",[self()]).

refresh_biaoche_type(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.yunbiao_pid, {refresh_biaoche_type, Id}).

onekey_refresh_biaoche_type(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.yunbiao_pid, {onekey_refresh_biaoche_type, Id}).

zhuan_yun(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.yunbiao_pid, {zhuan_yun, Id}).

start_yunbiao_task(Id, NpcId)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.yunbiao_pid, {start_yunbiao_task, Id, NpcId}).

commit_yunbiao_task(Id, NpcId)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.yunbiao_pid, {commit_yunbiao_task, Id, NpcId}).

rob_yun_biao(RobId, RobedId)->
	?INFO(yunbiao,"RobId:~w,RobedId:~w",[RobId,RobedId]),
	PS = mod_player:get_player_status(RobId),
	gen_server:cast(PS#player_status.yunbiao_pid, {rob_yun_biao, RobId, RobedId}).

client_request_yun_biao_state(Id)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.yunbiao_pid, {client_request_yun_biao_state, Id}).

client_request_continue_to_yun_biao(Id, NpcId)->
	PS = mod_player:get_player_status(Id),
	gen_server:cast(PS#player_status.yunbiao_pid, {client_request_continue_to_yun_biao, Id, NpcId}).

rob_yunbiao_battle(RobPs, BattleResultRec, [RobedId])->
%% 	PS = mod_player:get_player_status(Id),
	gen_server:cast(RobPs#player_status.yunbiao_pid, {rob_yunbiao_battle, RobPs, BattleResultRec, RobedId}).

handle_cast({request_yunbiao_message, Id}, State)->
	%%返回剩余运镖次数
	%%随机一个镖车品质
	?INFO(yunbiao,"request_yunbiao_message,Id:~w",[Id]),
	Result = get_biaoche_record(Id),
	?INFO(yunbiao,"biaoche record:~w",[Result]),
	case Result#yun_biao.state =:= 0 of
		true ->
			Rand = random:uniform(100),
			Probaility = data_yun_biao:get_refresh_probility(Result#yun_biao.gem_type),
			?INFO(yunbiao,"before player accept ya biao, his biao che type:~w",[Result#yun_biao.gem_type]),
			
			case Rand =< Probaility of
				true ->
					?INFO(yunbiao,"player refresh a new biao che type"),
					NewGemType = Result#yun_biao.gem_type + 1;
				false ->
					NewGemType = Result#yun_biao.gem_type
			end,
			
%%    		NewGemType = get_random_gem(?GEM_PROBABILITY),
			?INFO(yunbiao,"NewGemType:~w",[NewGemType]),
			NewRec = Result#yun_biao{gem_type = NewGemType,state = 3},
			gen_cache:update_record(?CACHE_YUN_BIAO, NewRec),
			?INFO(yunbiao,"NewRec:~w",[NewRec]),
			send_to_client(Id, NewRec);
		false ->
			send_to_client(Id, Result)
	end,
	{noreply, State};

handle_cast({request_jixing_message, Id}, State)->
	?INFO(yunbiao,"request_jixing_message,Id:~w",[Id]),
	%%获取吉星record
	JixingRec = gen_server:call(g_yunbiao, {get_jixing_rec, Id}),
	?INFO(yubiao,"jixing_rec :~w",[JixingRec]),
	ZhuanYunNum = mod_counter:get_counter(Id, ?COUNTER_YUNBIAO_ZHUANYUN_TIMES),
	Goldcount = data_yun_biao:get_goldcount_cost(ZhuanYunNum),
	{ok, Bin} = pt_26:write(26001, {JixingRec, Goldcount}),
	lib_send:send(Id, Bin),

	{noreply, State};

handle_cast({refresh_biaoche_type, Id}, State)->
	?INFO(yunbiao,"client request refresh biaoche"),
	Result = get_biaoche_record(Id),
	%%check gold 
	case mod_economy:check_and_use_gold(Id, ?REFREH_COST, ?GOlD_REFRESH_BIAOCHE_COST) of
		false ->
			?INFO(yunbiao,"not enough gold"),
			mod_err:send_err_by_id(Id,  ?ERR_NOT_ENOUGH_GOLD);
		true ->
			case Result#yun_biao.gem_type < 5 of
				false ->
					?INFO(yunbiao,"aready the high biao che type"),
					mod_err:send_err_by_id(Id,  ?ERR_AREADY_HIGH_TYPE),
					NewGemType = Result#yun_biao.gem_type;
				true ->
					Rand = random:uniform(100),
					Probaility = data_yun_biao:get_refresh_probility(Result#yun_biao.gem_type),
					?INFO(yunbiao,"before player refresh ya biao type, his biao che type:~w",[Result#yun_biao.gem_type]),
					case Rand =< Probaility of
						true ->
							?INFO(yunbiao,"player refresh a new biao che type"),
							NewGemType = Result#yun_biao.gem_type + 1;
						false ->
							?INFO(yunbiao,"player refresh lose"),
							case Result#yun_biao.gem_type =:= 1 of
								true ->
									?INFO(yunbiao,"player refresh lose,but his type is 1,so type no change"),
									NewGemType = Result#yun_biao.gem_type ;
								false ->
									NewGemType = Result#yun_biao.gem_type - 1
							end
					end
			end,
%% 			NewGemType = get_random_gem(?GEM_PROBABILITY),
			NewRec = Result#yun_biao{gem_type = NewGemType,state = 3},
			gen_cache:update_record(?CACHE_YUN_BIAO, NewRec),
			{ok, Bin} = pt_26:write(26003, NewGemType),
			lib_send:send(Id, Bin)
	end,
	{noreply, State};

handle_cast({onekey_refresh_biaoche_type, Id}, State)->
	%%check 是不是高级vip
	%%check gold
	
	?INFO(yunbiao,"client request onekey refresh biaoche"),
	Result = get_biaoche_record(Id),

	Ret = case mod_vip:check_vip(Id, ?Onekey_refresh_VipRequire) of 
				false ->
					?INFO(yunbiao,"vip level not enough"),
					{false, ?ERR_NOT_ENOUGH_VIP_LEVEL};
				true ->
					case mod_economy:check_and_use_gold(Id, ?ONEKEY_REFRESH_COST, ?GOlD_REFRESH_BIAOCHE_COST) of
						false ->
							?INFO(yunbiao,"not enough gold for one key refresh"),
							{false, ?ERR_NOT_ENOUGH_GOLD};
						true ->
							NewGemType =data_yun_biao:get_the_high_biaoche_type(),%%锁定最高品质镖车
							
							NewRec = Result#yun_biao{gem_type = NewGemType,state = 3},
							gen_cache:update_record(?CACHE_YUN_BIAO, NewRec),

							{ok, Bin} = pt_26:write(26003, NewGemType),
							lib_send:send(Id, Bin),
							{true,ok}
					end
		end,
	case Ret of
		{false, ErrorCode}->
			mod_err:send_err_by_id(Id,  ErrorCode);
		{true, _} ->
			skip
	end,
	{noreply, State};

handle_cast({zhuan_yun, Id}, State)->
	%%check 该玩家是否已经点击过转运
	%%check gold
	Rec = 
		case gen_cache:lookup(?CACHE_ZHUANYUN_REF, Id) of
			[] ->
				Ret = #zhuanyun{id = Id },
				gen_cache:insert(?CACHE_ZHUANYUN_REF, Ret),
				Ret;
			[Res] ->
				Res
			end,		
	?INFO(yunbiao,"zhuanyun_rec:~w",[Rec]),	
	case mod_counter:get_counter(Id, ?COUNTER_YUNBIAO_ZHUANYUN_TIMES) =:= 0 of 
		true ->
			%%该玩家今天木有点击过转运
			Amount = data_yun_biao:get_goldcount_cost(0),
			case mod_economy:check_and_use_gold(Id, Amount, ?GOlD_ZHUANYUN_COST) of
				false ->
					?INFO(yunbiao,"not enough gold for zhuanyun"),
					mod_err:send_err_by_id(Id,  ?ERR_NOT_ENOUGH_GOLD);
				true ->
					%%添加转运点击
%% 					Now = util:unixtime(),
					RecordUpdate = Rec#zhuanyun{zhuanyun_times = 1},	%%不用带时间了，因为counter里边有
					gen_cache:update_record(?CACHE_ZHUANYUN_REF, RecordUpdate),
					mod_counter:add_counter(Id, ?COUNTER_YUNBIAO_ZHUANYUN_TIMES),
					%%update 全服吉星运势点
					Reply = gen_server:call(g_yunbiao, {update_jixing, Id}),
					?INFO(yunbiao,"zhuanyun,Reply:~w",[Reply]),
					ZhuanYunNum = mod_counter:get_counter(Id, ?COUNTER_YUNBIAO_ZHUANYUN_TIMES),
					Goldcount = data_yun_biao:get_goldcount_cost(ZhuanYunNum),
					{ok, Bin} = pt_26:write(26001, {Reply, Goldcount}),
					lib_send:send(Id, Bin)
					%%anything todo
			end;
		false ->
			?INFO(yunbiao,"another times to zhuanyun"),
			Num = mod_counter:get_counter(Id, ?COUNTER_YUNBIAO_ZHUANYUN_TIMES),
			Amount = data_yun_biao:get_goldcount_cost(Num),
			case mod_economy:check_and_use_gold(Id, Amount, ?GOlD_ZHUANYUN_COST) of
				false ->
					?INFO(yunbiao,"not enough gold for zhuanyun"),
					mod_err:send_err_by_id(Id,  ?ERR_NOT_ENOUGH_GOLD);
				true ->
					%%添加转运点击
%% 					Now = util:unixtime(),
					?INFO(yunbiao,"zhuanyun_times:~w",[Rec#zhuanyun.zhuanyun_times]),
					RecordUpdate = Rec#zhuanyun{zhuanyun_times = Rec#zhuanyun.zhuanyun_times+1},
					gen_cache:update_record(?CACHE_ZHUANYUN_REF, RecordUpdate),
					mod_counter:add_counter(Id, ?COUNTER_YUNBIAO_ZHUANYUN_TIMES),
					%%update 全服吉星运势点
					Reply = gen_server:call(g_yunbiao, {update_jixing, Id}),
					ZhuanYunNum = mod_counter:get_counter(Id, ?COUNTER_YUNBIAO_ZHUANYUN_TIMES),
					Goldcount = data_yun_biao:get_goldcount_cost(ZhuanYunNum),
					{ok, Bin} = pt_26:write(26001, {Reply, Goldcount}),
					lib_send:send(Id, Bin)
					%%anything todo
			end
	end,
		
	{noreply, State};


handle_cast({start_yunbiao_task, Id, NpcId}, State)->
	%%check npcid 是否正确
	%%check running_times 是否大于5
	%%更新数据
	?INFO(yunbiao,"start_yunbiao,npc:~w",[NpcId]),
	{Scene_id, X, Y}= scene:get_position(Id),
	?INFO(yunbiao,"Scene_id, X, Y:~w",[[Scene_id, X, Y]]),
	[Rec] = gen_cache:lookup(?CACHE_YUN_BIAO, Id),
	?INFO(yunbiao,"before accept biao ,Rec:~w",[Rec]),
	case lib_scene:check_npc(NpcId, Scene_id, X, Y) of
		false ->
			?INFO(running_business,"not near the npc"),
			mod_err:send_err_by_id(Id, ?ERR_SCENE_RESTRICT);
		true ->
			case  mod_counter:get_counter(Id, ?COUNTER_YUNBIAO_TIMES) < 5 of
				false ->
					?INFO(yunbiao,"yubiao times over"),
					%%返回前端次数用完
					mod_err:send_err_by_id(Id, ?ERR_YUNBIAO_TIMES_ZERO);
%% 					?ERR(todo,"no free times");
				true ->
					mod_counter:add_counter(Id, ?COUNTER_YUNBIAO_TIMES),
					%%记录总人数
					mod_counter:add_counter(0, ?COUNTER_YUNBIAO_NUM),
%% 					Rb_times = Rec#yun_biao.yun_biao_times+1,
					Update_rb_time = util:unixtime(),
					NewRec = Rec#yun_biao{last_yb_time = Update_rb_time,state = 1,robed_times = 0},
%% 					UpdateFied =[
%% 								{#yun_biao.last_yb_time, Update_rb_time},
%% 								{#yun_biao.state,1}],
					{ok, Packet} = pt_26:write(26006, Rec#yun_biao.gem_type),
					lib_send:send_by_id(Id, Packet),
%% 					?INFO(yunbiao,"updatefied:~w",[UpdateFied]),
%% 					gen_cache:update_element(?CACHE_YUN_BIAO, Id, UpdateFied),
					gen_cache:update_record(?CACHE_YUN_BIAO, NewRec),
					?INFO(yunbiao,"after accept biao ,NewRec:~w",[NewRec]),
					scene:set_scene_state(Id, ?SCENE_STATE_RB, Rec#yun_biao.gem_type)%%2 场景状态为运镖标志
%% 					mod_scene:场景广播 别的玩家看见自己处于运镖状态
			end
	end,

	{noreply, State};

handle_cast({commit_yunbiao_task, Id, NpcId}, State)->
	?INFO(yunbiao,"commit yunbiao task, Id:~w",[Id]),
	%%获取奴隶记录
	SlaveRec = fengdi_db:get_slave_rec(Id),

	{Scene_id, X, Y}= scene:get_position(Id),
	?INFO(yunbiao,"Scene_id, X, Y:~w",[[Scene_id, X, Y]]),

	[Rec] = gen_cache:lookup(?CACHE_YUN_BIAO, Id),
	case lib_scene:check_npc(NpcId, Scene_id, X, Y) of
		false ->
			?INFO(running_business,"not near the npc"),
			mod_err:send_err_by_id(Id, ?ERR_SCENE_RESTRICT);
		true ->
			case  Rec#yun_biao.state =:= 1 of
				false ->
					?INFO(yunbiao,"not yunbiao state,can not commit task"),
					%%返回前端次数用完
					?ERR(todo,"no free times");
				true ->
					%% 成就通知
					mod_achieve:yunbiaoNotify(Id,1),
					%%判断有木有奴隶主，扣税？给奴隶主交税    ---减去被打劫的 
					%%按照type 取钱和军功
					%%随机一个数看是否大卖或一枪而空
					Type = get_random_gem(?GOODSHELL_PROBABILITY),
					?INFO(yunbiao,"Type:~w",[Type]),
					
					%%获取玩家对应等级镖车数据
					Level = mod_role:get_main_level(Id),
					BiaoCheDataList = data_yun_biao:get_biaoche_data(Level),
					
					%%取出玩家当前正在押运的镖车类型
					{SilverAmount1, JungongAmount1}= lists:nth(Rec#yun_biao.gem_type, BiaoCheDataList),
					?INFO(yunbiao, "curson biaoche data,SilverAmount1:~w,JungongAmount1:~w",[SilverAmount1,JungongAmount1]),
					
					%%镖车出卖系数
					XiShu = erlang:element(Type, ?FACTOR_RECORD),
					?INFO(yunbiao,"biaoche sell factor:~w",[XiShu]),

					%%吉星系数
					JiXingRec = gen_server:call(g_yunbiao, {get_jixing_rec, Id}),
					JiXingFactor = JiXingRec#jixing.addfactor,
					?INFO(yunbiao,"jixing factor:~w",[JiXingFactor]),

					SilverAmount2 = round(SilverAmount1*XiShu*JiXingFactor/100),
					JungongAmount2 = round(JungongAmount1*XiShu*JiXingFactor/100),
					?INFO(yunbiao, "jiacheng hou biaoche data,SilverAmount2:~w,JungongAmount2:~w",[SilverAmount2,JungongAmount2]),
					
					case Rec#yun_biao.success_robed_times =/= 0 of
						true ->
							%%被成功打劫过
							?INFO(yunbiao,"bei cheng gong da jie guo"),
							SilverAmount3  = round(SilverAmount1*(Rec#yun_biao.success_robed_times/5)),
							JungongAmount3 = round(JungongAmount1*(Rec#yun_biao.success_robed_times/5)),
							{SilverAmount3,JungongAmount3};
						false ->
							?INFO(yunbiao,"rober have not rob out my money, his lose"),
							{SilverAmount3,JungongAmount3} = {0,0}
					end,
					SilverAmount4 = SilverAmount2 - SilverAmount3,
					JungongAmount4 = JungongAmount2 - JungongAmount3,

					%%押镖加成时间内，收成增加50%
					{H, M, S} = erlang:time(),
					NowTime = H*3600+ M*60 + S ,
					case 18*3600 =< NowTime andalso NowTime =< 20*3600 of
						true ->
							?INFO(yunbiao, "yunbiao gold time, more award "),
							SilverAmount  = round(SilverAmount4*1.5),
							JungongAmount = round(JungongAmount4*1.5);
						false ->
							SilverAmount  = SilverAmount4,
							JungongAmount =JungongAmount4
					end,
					?INFO(yunbiao, "jiao biao suo de data,SilverAmount:~w,JungongAmount:~w",[SilverAmount,JungongAmount]),
					%%加军功
					case SlaveRec#slave.slave_owner == 0 of
						false ->
							mod_economy:add_silver(Id, SilverAmount, ?SILVER_FROM_YUNBIAO),%%0:运镖类型
							mod_economy:add_popularity(Id, JungongAmount, ?POPULARITY_FROM_YUNBIAO);
						true ->
							Silver = mod_fengdi:gain_taxes(Id, SilverAmount),%%交税给奴隶主
							mod_economy:add_silver(Id, Silver, ?SILVER_FROM_YUNBIAO),%%奴隶自己加钱
							mod_economy:add_popularity(Id, JungongAmount, ?POPULARITY_FROM_YUNBIAO)
					end,
					{ok, Packet} = pt_26:write(26007, {Type, SilverAmount, JungongAmount}),
					lib_send:send_by_id(Id, Packet)
					%%提醒奴隶主收到税
			end
	end,
	
	%%update yunbiao state
	NewRec =Rec#yun_biao{state = 0,success_robed_times = 0, gem_type = 1},
	gen_cache:update_record(?CACHE_YUN_BIAO, NewRec),
	?INFO(yunbiao,"jiao biao hou,NewRec:~w",[NewRec]),

	scene:clear_scene_state(Id, ?SCENE_STATE_RB),%% 场景状态行走标志
	{noreply, State};

handle_cast({rob_yun_biao, RobId, RobedId}, State)->
	?INFO(yunbiao,"RobId:~w,RobedId:~w",[RobId, RobedId]),
	%%check 是不是正在运镖
	[RobRec] = gen_cache:lookup(?CACHE_YUN_BIAO, RobId),%% 劫镖人
	?INFO(yunbiao,"RobRec:~w",[RobRec]),

	[RobedRec] = gen_cache:lookup(?CACHE_YUN_BIAO, RobedId), %%被劫镖人
	?INFO(yunbiao,"RobedRec:~w",[RobedRec]),

	%%获取劫镖人与被劫镖人的等级，不能打劫比自己等级低20级的玩家
	
	RobLevel   = mod_role:get_main_level(RobId),
	RobedLevel = mod_role:get_main_level(RobedId),
	?INFO(yunbiao,"RobedLevel:~w,RobLevel:~w",[RobedLevel,RobLevel]),

	Result = case RobedRec#yun_biao.state =:=1 of
				false ->
					?INFO(yunbiao,"player is not yunbiao"),
					{false, ?ERR_NOT_YUNBIAO_STATE};
				true ->
					case RobedRec#yun_biao.state =:= 2 of 
						true ->
							?INFO(yunbiao,"other player is robing now "),
							{false, ?ERR_BEING_ROBED};
						false ->
							case RobRec#yun_biao.state =:= 1 of
								true ->
									?INFO(yunbiao,"rober is also yunbiao -ing"),
									{false, ?ERR_ROBER_IS_YUNBIAOING};
								false ->
									case (RobLevel - RobedLevel) >= 20 of
										true ->
											?INFO(yunbiao,"rober level is higher too much to the robed level"),
											{false, ?ERR_ROBER_IS_SO_SMALL};
										false ->
											%%check 能不能被劫劫（次数2），是不是正在被劫
											case RobedRec#yun_biao.robed_times >= ?ROBED_TIMES of
												true ->
													?INFO(yunbiao, "can not be robed ,reach the max robed times"),
													{false, ?ERR_ROBED_TIMES_ZERO};
												false ->
													case mod_counter:get_counter(RobId, ?COUNTER_YUNBIAO_ROB_TIMES) >= ?ROB_TIMES of
														true ->
															?INFO(yunbiao,"can not rob ,reach the max rob times"),
															{false, ?ERR_ROB_TIMES_ZERO};
														false ->
															gen_cache:update_element(?CACHE_YUN_BIAO, RobedId, [{#yun_biao.state,2},
																{#yun_biao.robed_times, RobedRec#yun_biao.robed_times+1}]),
															mod_counter:add_counter(RobId, ?COUNTER_YUNBIAO_ROB_TIMES),
%% 															mod_counter:add_counter(RobedId, ?COUNTER_YUNBIAO_ROBED_TIMES),
															do_rob_yunbiao(RobId, RobedId),
															{true, ok}
													end
											end
									end
							end
					end
			end,
    case Result of
		{false, ErrorCode}->
			%%通知劫镖人
			mod_err:send_err_by_id(RobId, ErrorCode);
			%%通知被劫人
		{true, ok}->
			skip
	end,

	{noreply, State};

handle_cast({client_request_yun_biao_state, Id}, State)->
	case gen_cache:lookup(?CACHE_YUN_BIAO, Id) of
		[]->
			Rec = #yun_biao{id = Id},
			gen_cache:insert(?CACHE_YUN_BIAO, Rec),
			Rec;
		[Rec] ->
			Rec
	end,
	?INFO(yunbiao, "client request yunbiao data ,rec:~w",[Rec]),
	GemType = Rec#yun_biao.gem_type,
	YunBiaoState = Rec#yun_biao.state,
	%%check 是否是different day
	case util:check_other_day(Rec#yun_biao.last_yb_time) of
		false -> 
			?INFO(yunbiao,"login in the same day"),
			skip;
		true ->
			?INFO(yunbiao,"login in the other day"),
			CounterRec1 = Rec#yun_biao{
%% 				yun_biao_times = 0,
				last_yb_time  = util:unixtime()
			},
			gen_cache:update_record(?CACHE_YUN_BIAO, CounterRec1)
	end,		
	YbTimes1 = mod_counter:get_counter(Id, ?COUNTER_YUNBIAO_TIMES),
	YbTimes  = ?MAX_YUN_BIAO_TIMES - YbTimes1,
	?INFO(yunbiao,"client request yunbiao data,YunBiaoState:~w,YbTimes:~w,GemType:~w",[YunBiaoState,YbTimes,GemType]),
	{ok, Packet} = pt_26:write(26010, {YunBiaoState, GemType,YbTimes}),
	lib_send:send_by_id(Id, Packet),
	{noreply, State};


handle_cast({rob_yunbiao_battle, RobPs, BattleResultRec, RobedId}, State)->
	%%处理战斗后结果

%% 	[RobRec] = gen_cache:lookup(?CACHE_YUN_BIAO, RobId),
	RobId = RobPs#player_status.id,
	Res = case BattleResultRec#battle_result.is_win of
		true ->
			%%通知劫镖人
			?INFO(yunbiao,"rob biaoche win"),
			[RobedRec] = gen_cache:lookup(?CACHE_YUN_BIAO, RobedId),

			%%获取押镖玩家对应等级镖车数据
			Level = mod_role:get_main_level(RobedId),
			BiaoCheDataList = data_yun_biao:get_biaoche_data(Level),
					
			%%取出押镖玩家当前正在押运的镖车类型
			{SilverAmount1, JungongAmount1}= lists:nth(RobedRec#yun_biao.gem_type, BiaoCheDataList),
			
			?INFO(yunbiao,"SilverAmount1, JungongAmount1:~w",[[SilverAmount1, JungongAmount1]]),
			SilverAmount = round(SilverAmount1/5),
			JungongAmount = round(JungongAmount1/5),
			{ok, Packet} = pt_26:write(26008, {SilverAmount, JungongAmount}),
			lib_send:send_by_id(RobId, Packet),
			mod_economy:add_silver(RobId, SilverAmount, ?SILVER_FROM_ROB_YUNBIAO),
			mod_economy:add_popularity(RobId, JungongAmount, ?POPULARITY_FROM_ROB_YUNBIAO),
			%% 更新---被劫成功次数--
			
			gen_cache:update_element(?CACHE_YUN_BIAO, RobedId, [{#yun_biao.success_robed_times,
									RobedRec#yun_biao.success_robed_times+1}]),
			Wintype = 1,
			Wintype;	
		false ->
			?INFO(yunbiao,"rob biaoche lose"),
			Wintype = 0,
			Wintype
			%% 输的处理	
	end,
	%%通知被劫人   劫镖人账号id,昵称，战况
	AccountRec = mod_role:get_main_role_rec(RobId),
	Name = AccountRec#role.gd_name,
	{ok, Bin} = pt_26:write(26009, {RobId, Name, Res}),
	lib_send:send_by_id(RobedId, Bin),
	%%更新状态为state=1
	[RobedRec1] = gen_cache:lookup(?CACHE_YUN_BIAO, RobedId),
	?INFO(yunbiao, "RobedRec:~w",[RobedRec1]),

	NewRobedRec = RobedRec1#yun_biao{state = 1},
	gen_cache:update_record(?CACHE_YUN_BIAO, NewRobedRec),

	{noreply, State};


handle_cast({client_request_continue_to_yun_biao, Id, NpcId}, State)->
	?INFO(yunbiao,"player request continue to yun biao, NpcId:~w",[NpcId]),
	{SceneID, X, Y} = data_npc:get_location(NpcId),
	?INFO(yunbiao, "player back to npc sceneId:~w,X:~w,Y:~w",[SceneID, X, Y]),
	scene:fly(Id, SceneID, X, Y),
	{noreply, State};

handle_cast({request,  _Args}, State)->
	{noreply, State}.

handle_call({request, Action, Args}, _From, State)->
	{NewState, Reply} = ?MODULE:Action(State, Args),
	{reply, Reply, NewState}.

handle_info(_Info, State)->
	{noreply, State}.

terminate(_Reason, _State)->
	ok.

code_change(_OldVsn, State, _Extra)->
	{ok, State}.

%%%====================================internal functions=========================
%%%===============================================================================

get_random_gem(Probability) ->
	Rand = random:uniform(100),
	get_random_gem_1(Probability, Rand, 1, 0).

get_random_gem_1([_], _Rand, Type, _Count) ->
	Type;

get_random_gem_1([H | T], Rand, Type, Count) ->
	if	Rand =< (H + Count) ->
			Type;
		true ->
			get_random_gem_1(T, Rand, Type + 1, H + Count)
	end.

send_to_client(Id, Rec)->
	%%更新数据
	?INFO(yubiao,"send_to_client ,Id:~w,Rec:~w",[Id,Rec]),
	case mod_counter:get_counter(Id, ?COUNTER_YUNBIAO_TIMES) > ?MAX_YUN_BIAO_TIMES of 
		true ->
			?INFO(yunbiao,"reach the max times of yunbiao"),
			mod_err:send_err_by_id(Id, ?ERR_YUNBIAO_TIMES_ZERO);
		false ->
			Yb_Times = ?MAX_YUN_BIAO_TIMES - mod_counter:get_counter(Id, ?COUNTER_YUNBIAO_TIMES),
%% 			NewRec = Rec#yun_biao{yun_biao_times = Yb_Times},
%% 			gen_cache:update_record(?CACHE_YUN_BIAO, NewRec),
%% 			Times = NewRec#yun_biao.yun_biao_times, 
			Type  = Rec#yun_biao.gem_type,
			BiaocheData = get_biaoche_data(Id),
			?INFO(yunbiao,"biaoche_data:~w",[BiaocheData]),
			{ok, Bin} = pt_26:write(26000, Type, Yb_Times, BiaocheData),
			lib_send:send(Id, Bin)
	end,
	ok.

get_biaoche_data(Id)->
	?INFO(yunbiao,"client request biaoche data"),
	%%获取玩家等级
	Level = mod_role:get_main_level(Id),
	BiaoCheDataList = data_yun_biao:get_biaoche_data(Level),
	SeqList = lists:seq(1, 5),
	%%将类型和相应的镖车数据组合起来
	DataList = commer(SeqList, BiaoCheDataList, []),
	%%把列表翻转回来
	lists:reverse(DataList).

commer([], [], MerList)->
	MerList;
commer([H1 | T1],[H2 | T2], MerList)->
	?INFO(yunbiao,"Type and its data:~w,:~w",[H1,H2]),
	MerList0 = [[H1,H2] | MerList],
	commer(T1, T2, MerList0).



do_rob_yunbiao(RobId, RobedId)->
%%开始战斗
	StartupInfo = 
				#battle_start {
					mod = pvp,					  
%% 					type = standard,
					att_id = RobId,
%% 					att_mer = mod_role:get_on_battle_list(RobId),
%% 					def_id  = Id,
					def_mer = mod_role:get_on_battle_list(RobedId),
					callback = {mod_yunbiao, rob_yunbiao_battle, [RobedId]} 
				},	
	battle:start(StartupInfo),
ok.

get_biaoche_record(Id)->
	Result = case gen_cache:lookup(?CACHE_YUN_BIAO, Id) of
				[] ->
					?INFO(yunbiao,"not this user"),
					Ret = #yun_biao{id = Id},
					gen_cache:insert(?CACHE_YUN_BIAO, Ret),
					Ret;
				[Rec]->
					Ret = Rec,
					Ret
		  end,
	Result.
