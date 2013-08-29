%%% -------------------------------------------------------------------
%%% Author  : pyf
%%% Description :
%%%
%%% Created : 2012-12-20
%%% -------------------------------------------------------------------
-module(mod_tower_fb_manager).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").

%% --------------------------------------------------------------------
%% External exports
-export([]).

-export([start/0,
		 start_link/0
		]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {role_id, role_name, best_time, best_level, best_level_time}).

start() ->
    {ok,_} = supervisor:start_child(mgeew_sup, 
                           {?MODULE, 
                            {?MODULE, start_link,[]},
                            permanent, 30000, worker, [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [],[]).

init([]) ->
	erlang:process_flag(trap_exit, true),
	case mnesia:dirty_read(?DB_BEST_TOWER_P, ?DB_BEST_TOWER_P) of
		[#r_best_tower_fb{role_id = RoleID, role_name = RoleName, best_time = BestTime, best_level = BestLevel, best_level_time = BLT}] ->
    		State = #state{role_id = RoleID, role_name = RoleName, best_time = BestTime, best_level = BestLevel, best_level_time = BLT};
		_ ->
			State = #state{role_id = 0, role_name = [], best_time = 0, best_level = 0, best_level_time = []}
	end,
	%%十分钟持久化一次，防止意外情况发送
	erlang:send_after(600 * 1000, self(), {persistent}),
	{ok, State}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
	%%仿照地图进程写扑捉代码
	try
		NewState = do_handle_info(Info, State),
		{noreply, NewState}
	catch
        T:R ->
            case Info of
                {_Unique, _Module, _Method, DataRecord, RoleID, _Pid, _Line}->
                    ?ERROR_MSG("module: ~w, line: ~w, Info:~w, type: ~w, reason: ~w,DataRecord=~w,RoleID=~w,stactraceo: ~w",
                               [?MODULE, ?LINE, Info, T, R,DataRecord,RoleID,erlang:get_stacktrace()]);
                _ ->
                    ?ERROR_MSG("module: ~w, line: ~w, Info:~w, type: ~w, reason: ~w,stactraceo: ~w",
                               [?MODULE, ?LINE, Info, T, R,erlang:get_stacktrace()])
            end
    end.

terminate(_Reason, State) ->
	do_terminate(State),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_handle_info({replace, BestLevel, BestTime, RoleID}, State) ->
	#state{best_level = BL, best_time = BT} = State,
	[#p_role_attr{role_name = RoleName}] = mnesia:dirty_read(?DB_ROLE_ATTR, RoleID),
	%%最好关卡替换规则，如果BestLevel比最高关卡还高，替换最好关卡和挑战时间，如果BestLevel是最高关卡BL,则判断挑战时间是否更短，如果是，替换挑战时间
	case BL < BestLevel of
		true ->
			NewState = State#state{role_id = RoleID, best_level = BestLevel, best_time = BestTime, role_name = RoleName};
		false ->
			case BL =:= BestLevel of
				true ->
					case BT > BestTime of
						true ->
							NewState = State#state{role_id = RoleID, best_level = BestLevel, best_time = BestTime, role_name = RoleName};
						false ->
							NewState = State
					end;
				false ->
					NewState = State
			end
	end,
	NewState;

do_handle_info({replace, {Level, Time, RoleID}}, State) ->
	#state{best_level_time = BLT} = State,
	case lists:keyfind(Level, 1, BLT) of
		false ->
			NewBLT = [{Level, Time, RoleID} | BLT];
		{Level, BestTime, _RoleID1} ->
			case Time >= BestTime of
				true ->
					NewBLT = BLT;
				false ->
					NewBLT = lists:keyreplace(Level, 1, BLT, {Level, Time, RoleID})
			end
	end,
	State#state{best_level_time = NewBLT};

do_handle_info({level_best, BarrierID, RoleID}, State) ->
	#state{best_level_time = BLT} = State,
	case lists:keyfind(BarrierID, 1, BLT) of
		false ->
			DataRecord = #m_best_tower_fb_level_toc{challenge_time = 0};
		{BarrierID, BestTime, RoleID1} ->
			[RoleAttr] = mnesia:dirty_read(?DB_ROLE_ATTR_P, RoleID1),
			DataRecord = #m_best_tower_fb_level_toc{challenge_time = BestTime, role_name = RoleAttr#p_role_attr.role_name}
	end,
	common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?TOWER_FB_MANAGER, ?BEST_TOWER_FB_LEVEL, DataRecord),
	State;

do_handle_info({Unique, Module, Method, _Record, _RoleID, PID, _Line}, State) ->
	#state{role_id = RoleID, role_name = RoleName, best_time = BestTime, best_level = BestLevel} = State,
	ResultRec = #m_best_tower_fb_toc{role_id = RoleID, role_name = RoleName, best_time = BestTime, best_level = BestLevel},
	?UNICAST_TOC(ResultRec),
	State;

do_handle_info({persistent}, State) ->
	#state{role_id = RoleID, role_name = RoleName, best_time = BestTime, best_level = BestLevel, best_level_time = BLT} = State,
	Rec = #r_best_tower_fb{role_id = RoleID, role_name = RoleName, best_time = BestTime, best_level = BestLevel, best_level_time = BLT},
	mnesia:dirty_write(?DB_BEST_TOWER_P, Rec),
	erlang:send_after(600 * 1000, self(), {persistent}),
	State;

do_handle_info({reset_best_tower}, _State) ->
    State1 = #state{role_id = 0, role_name = [], best_time = 0, best_level = 0, best_level_time = []},
    #state{role_id = RoleID, role_name = RoleName, best_time = BestTime, best_level = BestLevel, best_level_time = BLT} = State1,
    Rec = #r_best_tower_fb{role_id = RoleID, role_name = RoleName, best_time = BestTime, best_level = BestLevel, best_level_time = BLT},
    mnesia:dirty_write(?DB_BEST_TOWER_P, Rec),
    State1;

do_handle_info(Info, _State) ->
	?ERROR_MSG("receive unknown message,Info=~w", [Info]),
    ignore.

do_terminate(State) ->
	#state{role_id = RoleID, role_name = RoleName, best_time = BestTime, best_level = BestLevel, best_level_time = BLT} = State,
	Record = #r_best_tower_fb{role_id = RoleID, role_name = RoleName, best_time = BestTime, best_level = BestLevel, best_level_time = BLT},
	mnesia:dirty_write(?DB_BEST_TOWER_P, Record).