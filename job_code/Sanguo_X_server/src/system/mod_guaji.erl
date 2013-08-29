%%挂机系统
%%e-mail:laojiajie@4399.net
%%2012-8-23
-module(mod_guaji).

-behaviour(gen_server).

-include("common.hrl").

-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).

-define(CACHE_GUAJI_REF, cache_util:get_register_name(guaji)).

-export([start_link/1]).

-export([initGuaji/1,
		 getInfo/1,        %% 获取初始化信息请求
         setInfo/6,        %% 更改某些用户设置
         startGuaji/1,     %% 开始挂机
         stopGuaji/2,      %% 停止挂机
		 useGuaji/1,       %% 使用一次挂机次数
         buyGuaji/2        %% 购买挂机
		]).

-record(state,
        {
        account_id,
        guaji_state       
        }).


start_link(AccountID) ->
	gen_server:start_link(?MODULE, [AccountID], []).

%% 用户登录初始化数据
init([AccountID]) ->
	erlang:process_flag(trap_exit, true),
	erlang:put(id, AccountID),
	mod_player:update_module_pid(AccountID, ?MODULE, self()),
    NewState = #state{
                    account_id = AccountID,
                    guaji_state = none
                    },
    {ok, NewState}.


initGuaji(AccountID) ->
	cache_init(AccountID),
	ok.





%% 取得挂机相关信息
-spec getInfo(integer()) ->any().
getInfo(AccountID) ->
    PS = mod_player:get_player_status(AccountID),
    gen_server:cast(PS#player_status.guaji_pid,getInfo).

%% 更改挂机信息(百分比，自动使用药品，自动使用血气包，自动停止，自动购买次数)
-spec setInfo(integer(),integer(),integer(),integer(),integer(),integer()) ->any().
setInfo(AccountID,Percent,IsUseDrug,IsUseBlood,IsAutoStop,IsAutoBuy) ->
    PS = mod_player:get_player_status(AccountID),
    gen_server:cast(PS#player_status.guaji_pid,{setInfo,{Percent,IsUseDrug,IsUseBlood,IsAutoStop,IsAutoBuy}}).

%% 开始挂机
-spec startGuaji(integer()) ->any().
startGuaji(AccountID) ->
    PS = mod_player:get_player_status(AccountID),
    gen_server:cast(PS#player_status.guaji_pid,startGuaji).

%% 停止挂机（客户端主动停止，或者服务器其他判断停止）
-spec stopGuaji(integer(),integer()) ->any().
stopGuaji(AccountID,Type) ->
    PS = mod_player:get_player_status(AccountID),
    gen_server:cast(PS#player_status.guaji_pid,{stopGuaji,Type}).

%% 使用一次挂机(由打怪事件钩子调用)
-spec useGuaji(integer()) ->any().
useGuaji(AccountID) ->
    PS = mod_player:get_player_status(AccountID),
    gen_server:cast(PS#player_status.guaji_pid,useGuaji).

%% 购买挂机次数
-spec buyGuaji(integer(),integer()) ->any().
buyGuaji(AccountID,AddTimes) ->    
    PS = mod_player:get_player_status(AccountID),
    gen_server:cast(PS#player_status.guaji_pid,{buyGuaji,AddTimes}).





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 获取初始信息
handle_cast(getInfo,State) ->
    Rec = cache_getRec(State#state.account_id),
    case util:check_other_day(Rec#guaji.gd_LastTime) of
        true ->
            %% ?TODO 通过VIP接口取得VIP类型，获取每天免费次数
            ?ERR(todo,"Insert Vip"),
            %% Times<免费次数 ->重置，else ->Times
            NewRec = Rec#guaji{gd_Times = ?DailyGuajiTimes},
            cache_update(NewRec),
            Times = NewRec#guaji.gd_Times;
        false ->
            Times = Rec#guaji.gd_Times,
            NewRec = Rec
    end,
    ?INFO(guaji, "Guaji Times = ~w", [Times]),
    {ok, BinData} = pt_61:write(61000, NewRec),
    ?INFO(guaji, "send_data:[~w]", [BinData]),
    lib_send:send(State#state.account_id,BinData),
    {noreply,State};

%% 用户参数设置
handle_cast({setInfo,{Percent,IsUseDrug,IsUseBlood,IsAutoStop,IsAutoBuy}},State) ->
    Rec = cache_getRec(State#state.account_id),
    NewRec = Rec#guaji{
                        gd_Percent = Percent,
                        gd_IsUseDrug = IsUseDrug,
                        gd_IsUseBlood = IsUseBlood,
                        gd_IsAutoStop = IsAutoStop,
                        gd_IsAutoBuy = IsAutoBuy
                    },
    cache_update(NewRec),
    {ok, BinData} = pt_61:write(61000, NewRec),
    ?INFO(guaji, "send_data:[~w]", [BinData]),
    lib_send:send(State#state.account_id,BinData),
    {noreply,State};

%% 开始挂机
handle_cast(startGuaji,State) ->
    Rec = cache_getRec(State#state.account_id),
    case Rec#guaji.gd_Times > 0 of
        false ->
            ?INFO(guaji, "no guaji Times,please buy some!,ErrCode = ~w",[?ERR_GUAJI_TIMES_ZERO]),
            {ok,BinData} = pt_10:write(10999,{0,?ERR_GUAJI_TIMES_ZERO}),
            NewState = State;
        true ->
            case check_first(State#state.account_id) of
                ok ->
                    NewState = State#state{guaji_state = guaji},
                    ?INFO(guaji,"Start Guaji Successful!"),
                    {ok, BinData} = pt_61:write(61002, {Rec#guaji.gd_Times,1});
                {false,ErrCode} ->
                    {ok,BinData} = pt_10:write(10999,{0,ErrCode}),
                    NewState =State
            end
    end,
    ?INFO(guaji, "send_data:[~w]", [BinData]),
    lib_send:send(State#state.account_id,BinData),
    {noreply,NewState};

%% 停止挂机(停止类型：1.用户停止，2.药品不够，3.背包不足 4.挂机次数不住 5.金币不足自动购买次数 6.被怪打死了)
handle_cast({stopGuaji,Type},State) ->
    case State#state.guaji_state == guaji of
        false ->
            NewState = State;
        true ->
            NewState = State#state{guaji_state = none},
            ?INFO(guaji,"Stop Guaji Successful!"),
            {ok, BinData} = pt_61:write(61003,Type),
            ?INFO(guaji, "send_data:[~w]", [BinData]),
            lib_send:send(State#state.account_id,BinData)
    end,
    {noreply,NewState};

%% 使用一次挂机
handle_cast(useGuaji,State) ->
    case State#state.guaji_state == guaji of
        true ->
            Rec = cache_getRec(State#state.account_id),
            Times = Rec#guaji.gd_Times,
            NewRec = Rec#guaji{gd_Times = Times-1,gd_LastTime = util:unixtime()},
            cache_update(NewRec),
            ?INFO(guaji, "Guaji Times = ~w", [Times-1]),
            {ok, BinData} = pt_61:write(61002, {NewRec#guaji.gd_Times,0}),
            %% 检查是否可以继续打怪
            case check_next(State#state.account_id,NewRec) of
                ok ->
                    %% 战斗后的处理，吃药，吃血气包等
                    do_after_battle(State#state.account_id,NewRec);
                {false,Type} ->
                    gen_server:cast(self(),{stopGuaji,Type})
            end,
            ?INFO(guaji, "send_id:~w,send_data:[~w]", [State#state.account_id,BinData]),
            lib_send:send(State#state.account_id,BinData);
        false ->
            void
    end,
    {noreply,State};

%% 购买挂机
handle_cast({buyGuaji, AddTimes},State) ->
    Rec = cache_getRec(State#state.account_id),
    OldTimes = Rec#guaji.gd_Times,
    NewTimes = OldTimes + AddTimes,
    % GoldCost = data_guaji:get_buy_cost(),
    GoldCost = round(0.1*AddTimes),
    case mod_economy:check_and_use_bind_gold(State#state.account_id, GoldCost, ?GOlD_BUY_GUAJI_COST) of
        true ->
            NewRec = Rec#guaji{gd_Times = NewTimes,gd_LastTime = util:unixtime()},
            cache_update(NewRec),
            ?INFO(guaji, "Guaji Times = ~w", [NewTimes]),
            {ok, BinData} = pt_61:write(61000, NewRec);
        false ->
            {ok, BinData} = pt_10:write(10999,{0, ?ERR_NOT_ENOUGH_GOLD})
    end,
    ?INFO(guaji, "send_data:[~w]", [BinData]),
    lib_send:send(State#state.account_id,BinData),
    {noreply,State};

handle_cast(_Request, State) ->
    {noreply,State}.

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
%%												catch														   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cache_init(AccountID) ->
    GuajiRec = #guaji {
                gd_AccountID = AccountID,
                gd_Times = ?DailyGuajiTimes,
                gd_Percent = 70,        %% 血量指标，低于某百分比自动加血
                gd_IsUseDrug = 1,       %% 低于血量指标，使用药品
                gd_IsUseBlood = 0,      %% 气血用尽，使用气血包
                gd_IsAutoStop = 0,      %% 药品不足，自动停止打怪
                gd_IsAutoBuy = 0        %% 是否自动购买挂机次数
                },
    gen_cache:insert(?CACHE_GUAJI_REF,GuajiRec).

cache_getRec(AccountID) ->
    case gen_cache:lookup(?CACHE_GUAJI_REF,AccountID) of
        [] ->
            [];
        [Rec] ->
            Rec
    end.

cache_update(Rec) ->
    gen_cache:update_record(?CACHE_GUAJI_REF,Rec).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%											Local Function													   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 检查是否可以启动挂机
check_first(AccountID) ->
    case mod_items:getBagNullNum(AccountID) >0 of
        true ->
            ok;
        false ->
            ?INFO(guaji, "no enough bagPos!"),
            {false,?ERR_ITEM_BAG_NOT_ENOUGH}
    end.

%% 一次挂机后检查是否可以继续挂机
check_next(AccountID,NewRec) ->
    case mod_items:getBagNullNum(AccountID) >0 of
        true ->
            case NewRec#guaji.gd_Times > 0 of
                true ->
                    ?INFO(guaji,"Guaji go on!"),
                    ok;
                false ->
                    case NewRec#guaji.gd_IsAutoBuy == 1 of
                        true->
                            %% 自动购买次数也得够银两才行
                            % GoldCost = data_guaji:get_buy_cost(),
                            AddTimes = ?AutoBuyTimes,
                            GoldCost = 2*AddTimes,
                            case mod_economy:check_bind_gold(AccountID, GoldCost) of
                                true ->
                                    ?INFO(guaji,"Guaji go on!"),
                                    ok;
                                false ->
                                    ?INFO(guaji,"no enough gold!"),
                                    {false,5} %% 自动购买次数金币不够
                            end;
                        false ->
                            ?INFO(guaji,"no enough times!"),
                            {false,4} %% 挂机次数不足
                    end
            end;
        false ->
            ?INFO(guaji, "no enough bagPos!"),
            {false,3} %% 背包不足，类型为3
    end.

%% 战斗后处理
do_after_battle(AccountID,NewRec) ->
    %% TODO 自动购买次数
    case NewRec#guaji.gd_Times =< 0 andalso NewRec#guaji.gd_IsAutoBuy =/= 0 of
        true ->
            AddTimes = ?AutoBuyTimes,
            buyGuaji(AccountID,AddTimes);
        false ->
            void
    end,
    %% TODO，检查气血，吃药
    ok.
