%% Author: Administrator
%% Created: 2012-9-17
%% Description: 技能冷却时间公共提供模块
-module(mod_cool_down).

%%
%% Include files
%%
-include("common.hrl").
%%
%% Exported Functions
%%

%% api export
-export([getCoolDownLeftTime/2, addCoolDownLeftTime/3, clearCoolDownLeftTime/2, start_link/1,
		 getCoolDownLeftTimeDayDown/2, addCoolDownLeftTimeDayDown/3, clearCoolDownLeftTimeDayDown/2]).

%% gen_server callbacks export
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%%
%% API Functions
%%

%% 起进程
start_link(PlayerId) ->
    gen_server:start_link(?MODULE, PlayerId, []).
    

%% 查询cd剩余时间
getCoolDownLeftTime(PlayerId,CdType)->
    PlayerStatus = mod_player:get_player_status(PlayerId),
    Pid = PlayerStatus#player_status.cool_down_pid,
    gen_server:call(Pid, {get,CdType}).

%% 增加cd时间，CdTime为相对时间
addCoolDownLeftTime(PlayerId,CdType,CdTime)->
    PlayerStatus = mod_player:get_player_status(PlayerId),
    Pid = PlayerStatus#player_status.cool_down_pid,
    gen_server:cast(Pid, {CdType,CdTime}).

%% 清零cd剩余时间
clearCoolDownLeftTime(PlayerId,CdType)->
    PlayerStatus = mod_player:get_player_status(PlayerId),
    Pid = PlayerStatus#player_status.cool_down_pid,
    gen_server:call(Pid, {clear, CdType}).

%% 查询cd剩余时间,隔天清零
getCoolDownLeftTimeDayDown(PlayerId,CdType)->
    PlayerStatus = mod_player:get_player_status(PlayerId),
    Pid = PlayerStatus#player_status.cool_down_pid,
    gen_server:call(Pid, {getDayDown,CdType}).

%% 增加cd时间，CdTime为相对时间，隔天清零
addCoolDownLeftTimeDayDown(PlayerId,CdType,CdTime)->
    PlayerStatus = mod_player:get_player_status(PlayerId),
    Pid = PlayerStatus#player_status.cool_down_pid,
    gen_server:cast(Pid, {dayDown,CdType,CdTime}).

%% 清零cd剩余时间，隔天清零
clearCoolDownLeftTimeDayDown(PlayerId,CdType)->
    PlayerStatus = mod_player:get_player_status(PlayerId),
    Pid = PlayerStatus#player_status.cool_down_pid,
    gen_server:call(Pid, {clearDayDown, CdType}).

%%
%% gen_server call back funtion
%%

%% 初始化
init(PlayerId) ->
    ?INFO(coolDown,"~w's cool_down process init",[PlayerId]),
    erlang:process_flag(trap_exit, true),
    mod_player:update_module_pid(PlayerId,?MODULE,self()),
    {ok, PlayerId}.

handle_call({getDayDown, CdType}, _From, PlayerId) ->
    TimeLeft = getCoolDownLeftTimeLocalDayDown(PlayerId,CdType),
    {reply, TimeLeft, PlayerId};

handle_call({clearDayDown, CdType}, _From, PlayerId) ->
    TimeLeft = clearCoolDownLeftTimeLocalDayDown(CdType, PlayerId),
    {reply, TimeLeft, PlayerId};

%% 查询cd剩余时间
handle_call({get, CdType}, _From, PlayerId) ->
    TimeLeft = getCoolDownLeftTimeLocal(PlayerId,CdType),
    {reply, TimeLeft, PlayerId};

%% 清零cd时间
handle_call({clear, CdType}, _From, PlayerId) ->
	TimeLeft = getCoolDownLeftTimeLocal(PlayerId,CdType),
    clearCoolDownLeftTimeLocal(CdType, PlayerId),
    {reply, TimeLeft, PlayerId}.

%% 增加cd时间
handle_cast({CdType,CdTime}, PlayerId) ->
    addCoolDownLeftTimeLocal(PlayerId, CdType, CdTime),
    {noreply, PlayerId};

handle_cast({dayDown, CdType,CdTime}, PlayerId) ->
    addCoolDownLeftTimeLocalDayDown(PlayerId, CdType, CdTime),
    {noreply, PlayerId}.






handle_info(_Info, CDStatus) ->
    {noreply, CDStatus}.

terminate(_Reason, _CDStatus) ->
    ok.

code_change(_OldVsn, CDStatus, _Extra) ->
    {ok, CDStatus}.

%%
%% Local Functions
%%

getCoolDownLeftTimeLocalDayDown(PlayerId,CdType)->
	case getIsAnotherDate(PlayerId,CdType) of
		true->
			clearCoolDownLeftTimeLocal(CdType, PlayerId),
			0;
		false->
			getCoolDownLeftTimeLocal(PlayerId,CdType)
	end.

addCoolDownLeftTimeLocalDayDown(PlayerId,CdType,CdTimeAdded)->
	case getIsAnotherDate(PlayerId,CdType) of
		true->
			clearCoolDownLeftTimeLocal(CdType, PlayerId),
			addCoolDownLeftTimeLocal(PlayerId,CdType,CdTimeAdded);
		false->
			addCoolDownLeftTimeLocal(PlayerId,CdType,CdTimeAdded)
	end.

clearCoolDownLeftTimeLocalDayDown(CdType,PlayerId)->
	LeftTime = getCoolDownLeftTimeLocalDayDown(PlayerId,CdType),
	clearCoolDownLeftTimeLocal(PlayerId,CdType),
	LeftTime.

%% 得到剩余cd时间的进程内函数
getCoolDownLeftTimeLocal(PlayerId,CdType)->
    CdRecord = getCoolDownRecord(PlayerId,CdType),
    CdEndTime = CdRecord#ets_cool_down.cdEndTime,
    max(CdEndTime - util:unixtime(),0).

%% 增加cd时间的进程内函数
%% 新cd结束时间 = max(当前时间,上次cd结束时间)+cdTimeAdded
addCoolDownLeftTimeLocal(PlayerId, CdType, CdTimeAdded)->
    %% 查询下,如果这个玩家没有这种类型的cd则新建一个
    #ets_cool_down{cdEndTime = OldCdEndTime} = getCoolDownRecord(PlayerId,CdType),
    NewCdEndTime = max(OldCdEndTime, util:unixtime()) + CdTimeAdded,
    gen_cache:update_element(?ETS_COOL_DOWN,{PlayerId,CdType},[{#ets_cool_down.cdEndTime,NewCdEndTime},
		{#ets_cool_down.updateTime, util:unixtime()}]).
    
%%　清零cd时间
clearCoolDownLeftTimeLocal(CdType, PlayerId)->
    %% 查询下,目的是如果这个玩家没有这种类型的cd则新建一个
    getCoolDownRecord(PlayerId,CdType),
    gen_cache:update_element(?ETS_COOL_DOWN,{PlayerId,CdType},[{#ets_cool_down.cdEndTime,0},
		{#ets_cool_down.updateTime, util:unixtime()}]).

%% 得到cd记录，如果查询不到则创建一个新的
getCoolDownRecord(PlayerId,CdType)->
    case gen_cache:lookup(?ETS_COOL_DOWN, {PlayerId,CdType}) of 
        [] ->   
            NewCdRecord = #ets_cool_down{cdEndTime = util:unixtime(),key = {PlayerId,CdType}},
            gen_cache:insert(?ETS_COOL_DOWN,NewCdRecord);
        [NewCdRecord]->
            ok    
    end,
    NewCdRecord.

getIsAnotherDate(PlayerId,CdType)->
	case gen_cache:lookup(?ETS_COOL_DOWN, {PlayerId,CdType}) of 
		[] -> false;
		[NewCdRecord] ->
			util:check_other_day(NewCdRecord#ets_cool_down.updateTime)
	end.

            
%% 调试命令
%% mod_cool_down:getCoolDownLeftTime(4000562,1)  
%% mod_cool_down:setCoolDownLeftTime(4000555,1,100)
%% mod_cool_down:clearCoolDownLeftTime(4000298,1)