-module (gen_timer).

-behaviour(gen_server).

-export([behaviour_info/1]).

-export([init/1, handle_call/3, handle_cast/2, 
         handle_info/2, terminate/2, code_change/3]).

-export([start_link/2, stop/1, add_timer/4, cancle_timer/2]). 

%% internal export 
-export([timeout_action/2, add_timer2/2, timeout_action2/2, cancle_timer2/2 ]).

-record(timer_state, {
		timer_ref,
		module,
		timer_tab				%% ets table of #user_timer{}
	}).

-record(user_timer, {
		user_key,
		user_data,
		timer_ref 
	}).

behaviour_info(callbacks) ->
    [{timeout_action, 1}].



start_link(GenTimerRef, Module) ->
	gen_server:start({local, GenTimerRef}, ?MODULE, [GenTimerRef, Module], []).

stop(GenTimerRef) ->
	gen_server:cast(GenTimerRef, stop).

%% 这是添加一个timer，如果你用同样的UserKey调用2次add_timer，将会产生2个timer！
add_timer(GenTimerRef, Timeout, UserKey, UserData) ->
	gen_server:cast(GenTimerRef, {request, add_timer2, [Timeout, UserKey, UserData]}).

cancle_timer(GenTimerRef, UserKey) ->
	gen_server:cast(GenTimerRef, {request, cancle_timer2, [UserKey]}).

timeout_action(GenTimerRef, UserKey) ->
	gen_server:cast(GenTimerRef, {request, timeout_action2, [UserKey]}).
%% ==================================================================
%% ==================================================================
init([GenTimerRef, Module]) ->
    process_flag(trap_exit, true),

	TimerTabName  = list_to_atom(atom_to_list(GenTimerRef) ++ "_timer_tab"),
	TimerTab      = ets:new(TimerTabName, [named_table, public, set, {keypos, #user_timer.user_key}]),

    {ok, #timer_state{
			timer_ref      = GenTimerRef,
			module         = Module,
			timer_tab      = TimerTab
    }}.

terminate(Reason, State) ->
	io:format("gen_timer ~w terminate with reason: ~w", 
			  [State#timer_state.timer_ref, Reason]),
    ok.

handle_cast(stop, State) ->
    {stop, normal, State};

handle_cast({request, Action, Args}, State) ->
	NewState = ?MODULE:Action(State, Args),
	{noreply, NewState}.

handle_call({request, Action, Args}, _From, State) ->
	{NewState, Reply} = ?MODULE:Action(State, Args),
	{reply, Reply, NewState}.

handle_info(_Info, State) ->
    {noreply, State}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


add_timer2(State, [Timeout, UserKey, UserData]) ->
	{ok, TRef} = timer:apply_after(Timeout, ?MODULE, timeout_action, 
								   [State#timer_state.timer_ref, UserKey]),

	UserTimerRec = #user_timer{
						user_key  = UserKey, 
						user_data = UserData,
						timer_ref = TRef},
	ets:insert(State#timer_state.timer_tab, UserTimerRec),

	State.

timeout_action2(State, [UserKey]) ->
	case ets:lookup(State#timer_state.timer_tab, UserKey) of
		[] ->
			error_logger:error_msg("timeout_action called with user key: ~w,"
								   " but user timer record not exist!", [UserKey]);
		[UserTimerRec | _] ->
			ets:delete(State#timer_state.timer_tab, UserKey),
			CbModule = State#timer_state.module,
			CbModule:timeout_action(UserTimerRec#user_timer.user_data)
	end,

	State.	

cancle_timer2(State, [UserKey]) ->
	case ets:lookup(State#timer_state.timer_tab, UserKey) of
		[] ->
			error_logger:error_msg("Cancle timer with user key: ~w,"
								   " but user timer record not exist!", [UserKey]);
		[UserTimerRec | _] ->
			ets:delete(State#timer_state.timer_tab, UserKey),
			Ret = timer:cancle(UserTimerRec#user_timer.timer_ref),
			case Ret of
				{ok, cancle} -> ok;
				{error, Reason} ->
					error_logger:error_msg("Cancle timer with user key: ~w,"
								   " return error: ~w", [UserKey, Reason])
			end
	end,

	State.

