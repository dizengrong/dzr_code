%%打坐系统
%%e-mail:laojiajie@4399.net
-module(mod_dazuo).

-behaviour(gen_server).

-include("common.hrl").

-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

-export([start_link/1]).

-export([beginDazuo/2,
		 endDazuo/1,
		 joinDazuo/2,
		 getDazuoState/1,
		 add/1
		]).

-record(state,
		{
		account_id,
		dazuo_state,
		timer_ref
		}).

%% 发放奖励的时间间隔
-define(REWARD_INTERVAL, (10 * 3000)). 	%%30秒

start_link(AccountID) ->
	gen_server:start_link(?MODULE, [AccountID], []).

%% 用户登录时初始化数据
init([AccountID]) ->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, AccountID),
	mod_player:update_module_pid(AccountID, ?MODULE, self()),
	NewState = #state{
				account_id = AccountID,
				dazuo_state = none, 	%% 打坐状态
				timer_ref = none 		%% 事件定时器
				},
    {ok, NewState}.

%% 获得打坐状态信息
-spec getDazuoState(integer()) ->any().
getDazuoState(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.dazuo_pid,getDazuoState).

%% 开始打坐(自己单修或者选一个单修者进行双修)
-spec beginDazuo(integer(),integer()) -> any().
beginDazuo(AccountID,OtherID) ->
	?INFO(dazuo,"AccountID = ~w,OtherID = ~w",[AccountID,OtherID]),
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.dazuo_pid, {beginDazuo, OtherID}).

%% 结束打坐
-spec endDazuo(integer()) ->any().
endDazuo(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.dazuo_pid, endDazuo).

%% 奖励
-spec add(integer()) ->any().
add(AccountID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:cast(PS#player_status.dazuo_pid, add).

%% 被动加入打坐
-spec joinDazuo(integer(),integer()) -> any().
joinDazuo(AccountID,OtherID) ->
	PS = mod_player:get_player_status(AccountID),
	gen_server:call(PS#player_status.dazuo_pid, {joinDazuo, OtherID}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 开始打坐 mod_dazuo:beginDazuo(6000614,6000615).
handle_cast({beginDazuo,OtherID},State) ->
	case State#state.dazuo_state of
		none ->
			case OtherID =:= 0 of
				true ->
					NewState = State#state{dazuo_state = alone},
					scene:set_scene_state(State#state.account_id, ?SCENE_STATE_DAZUO, 0),
					gen_server:cast(self(),add_after_time),
					notify_client_dazuo_start(State#state.account_id,1);
				false ->
					case joinOther(State#state.account_id,OtherID) of
						{fail,Errcode} ->
							?INFO(dazuo,"cannot join other,Errcode is:~w ",[Errcode]),
							NewState = State;
						ok ->
							NewState = State#state{dazuo_state = {double,OtherID}},
							scene:set_scene_state(State#state.account_id, ?SCENE_STATE_DAZUO, OtherID),
							gen_server:cast(self(),add_after_time),
							notify_client_dazuo_start(State#state.account_id,2)
					end
			end;
		alone ->
			case OtherID =:= 0 of
				true ->
					NewState = State;
				false ->
					case joinOther(State#state.account_id,OtherID) of
						{fail,Errcode} ->
							?INFO(dazuo,"cannot join other,Errcode is: ",[Errcode]),
							NewState = State;
						ok ->
							NewState = State#state{dazuo_state = {double,OtherID}},
							scene:set_scene_state(State#state.account_id, ?SCENE_STATE_DAZUO, OtherID),
							gen_server:cast(self(),add_after_time),
							notify_client_dazuo_start(State#state.account_id,2)
					end
			end;
		{double,Old_OtherID} ->
			?INFO(dazuo,"Player ~w have been dazuo with ~w",[State#state.account_id,Old_OtherID]),
			NewState = State
	end,
	{noreply,NewState};
	

%% 结束打坐
handle_cast(endDazuo,State) ->
	case State#state.timer_ref of
        none     -> void;
        TimerRef ->
            timer:cancel(TimerRef)
    end,
    NewState = State#state{timer_ref = none,dazuo_state = none},
    scene:clear_scene_state(State#state.account_id, ?SCENE_STATE_DAZUO),
    case State#state.dazuo_state of
    	{double,OtherID} ->
    		joinOther(0,OtherID);
    	_Else ->
    		void
    end,
    {noreply,NewState};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%								   循环计时器(一定时间发放一次奖励)											   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 启动计时器，一定时间后调用add方法
handle_cast(add_after_time,State) ->
	case State#state.timer_ref of
        none     -> void;
        TimerRef ->
            timer:cancel(TimerRef)
    end,
    NewState = 
    case State#state.dazuo_state of
        none       ->
            State#state{timer_ref = none};
        _Else ->
            {ok, TRef} = timer:apply_after(?REWARD_INTERVAL, ?MODULE, add, [State#state.account_id]),
            State#state{timer_ref = TRef}
    end,
    {noreply,NewState};

%% 给玩家增加经验，同时回调add_affter_time
handle_cast(add,State) ->
	%%TODO 获得VIP接口,通过VIP获得系数
	VipRate = data_dazuo:get_vip_rate(1),
	{_Year,NowTime} = calendar:local_time(),
	DaliyRate = data_dazuo:get_daily_rate(NowTime),
	gen_server:cast(self(),add_after_time),
	AccountID = State#state.account_id,
	RoleRec = mod_role:get_main_role_rec(AccountID),
	RoleLevel = RoleRec#role.gd_roleLevel,
	Experience = data_dazuo:get_experience_by_level(RoleLevel),
	case State#state.dazuo_state of
		alone ->
			BaseRate = 1;
		{double,_OtherID} ->
			BaseRate = 1.2;
		_Else ->
			BaseRate = 0
	end,
	AddExperience = erlang:trunc(Experience*VipRate*DaliyRate*BaseRate),
	RoleList = mod_role:get_employed_id_list(AccountID),
	lists:foreach(fun(RoleID)-> mod_role:add_exp(AccountID,{RoleID,AddExperience},?EXP_FROM_DAZUO) end,RoleList),
	?INFO(dazuo,"Dazuo Add AddExperience = ~w",[AddExperience]),
	{ok,BinData} = pt_49:write(49003,{AddExperience}),
	lib_send:send(AccountID,BinData),
	{noreply,State};

handle_cast(_Request, State) ->
    {noreply,State}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 被加入双修或者打断双修(被动)
handle_call({joinDazuo, OtherID},_From,State) ->
	case State#state.dazuo_state =:= alone andalso OtherID /=0 of
		true ->
			case reset_xy(State#state.account_id,OtherID) of
				true ->
					NewState = State#state{dazuo_state = {double,OtherID}},
					scene:set_scene_state(State#state.account_id, ?SCENE_STATE_DAZUO, OtherID),
					Reply = {ok, double};
				{false,Reason} ->
					?INFO(dazuo,"reset_xy Err Happen,Reason is:~w",[Reason]),
					NewState = State,
					Reply = {fail,set_xy_error}
			end;
		false ->
			case OtherID =:= 0  of
				true ->
					case State#state.dazuo_state of
						{double,_OldID} ->
							NewState = State#state{dazuo_state = alone},
							scene:set_scene_state(State#state.account_id, ?SCENE_STATE_DAZUO, 0),
							Reply = {ok, alone};
						_Else ->
							NewState = State,
							Reply = {fail,notdouble}
						end;
				false ->
					NewState = State,
					Reply = {fail,cannot_join}
			end
	end,
	{reply,Reply,NewState};


%% 获得打坐状态信息
handle_call(getDazuoState, _From, State) ->
	Reply = {ok,State#state.dazuo_state},
	{reply,Reply,State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%											Local Function													   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 加入双修
joinOther(AccountID,OtherID) ->
	case mod_player:is_online(OtherID) of
		{true,_PS} ->
			case joinDazuo(OtherID,AccountID) of
				{ok,Message} ->
					?INFO(dazuo,"joinOther Success! OtherID:~w,State:~w.",[OtherID,Message]),
					ok;
				{fail,Message} ->
					?INFO(dazuo,"joinOther fail! Message is:~w",[Message]),
					{fail,?ERR_NOT_IN_DAZUO}	
			end;
		false ->
			{fail,?ERR_OFFLINE}
	end.

%% 通知前端打坐成功开始
notify_client_dazuo_start(PlayerId,Type) ->
	{ok,BinData} = pt_49:write(49001,Type),
	lib_send:send(PlayerId,BinData).

%% 双修坐标点重置
% scene:can_move
% scene:get_position
% scene:go_to
reset_xy(PlayerId1,PlayerId2) ->
	{SceneID1, X1, Y1} = scene:get_position(PlayerId1),
	{SceneID2, X2, Y2} = scene:get_position(PlayerId2),
	case SceneID1 =:= SceneID2 of
		true ->
			X = (X1+X2) div 2,
			Y = (Y1+Y2) div 2,
			case scene:can_move(SceneID1,X,Y) of
				true ->
					case X1 > X2 of
						true ->
							scene:go_to(PlayerId1,SceneID1,X+1,Y),
							scene:go_to(PlayerId2,SceneID1,X-1,Y);
						false ->
							scene:go_to(PlayerId1,SceneID1,X-1,Y),
							scene:go_to(PlayerId2,SceneID1,X+1,Y)
					end,
					true;
				false ->
					{false,cannot_move}
			end;
		false ->
			{false,scene_not_same}
	end.