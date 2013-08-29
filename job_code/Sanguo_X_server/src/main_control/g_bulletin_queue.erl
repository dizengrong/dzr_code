%% Author: zqq
%% Created: 2012-02-20
%% Description: 处理公告信息队列
-module(g_bulletin_queue).

-behaviour(gen_server).

%%
%% Include files
%%
-include("common.hrl").

-define(TIMEOUT, (10*1000)).

-record(state, {timer_sched=none, msg_queue=[]}).

%%
%% Exported Functions
%%
-export([
		 start_link/0
		]).

-export([timer_call/1]).

-export([
		 init/1,
		 handle_cast/2,
		 handle_call/3,
		 handle_info/2,
		 code_change/3,
		 terminate/2
		]).

%%
%% API Functions
%%
start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%
%% timer callback
%%
timer_call(Pid) ->
	gen_server:cast(Pid, do_broadcast).

%%
%% gen_server 接口
%%
init([]) ->
	erlang:process_flag(trap_exit, true),
	NewState = #state{timer_sched=none, msg_queue=[]},
	{ok, NewState}.
	
handle_cast(do_broadcast, State) ->
	#state{msg_queue=MsgQueue} = State,
	NewState = 
		case MsgQueue of
			[] ->
				?INFO(g_bulletin_queue, "MsgQueue is empty"),
				case State#state.timer_sched of
					none -> void;
					TRef -> timer:cancel(TRef) 
				end,
				%% 返回新状态
				State#state{timer_sched=none};

			[FirstMsg | Other] ->
				?INFO(g_bulletin_queue, "Broadcasting message: ~w", [FirstMsg]),
				%% 向所有server node广播

				lib_send:send_to_all(FirstMsg),
				
				{ok, TimerRef} = timer:apply_after(?TIMEOUT, ?MODULE, timer_call, [self()]),

				%% 返回新状态
				State#state{timer_sched=TimerRef, msg_queue=Other}
		end,
	{noreply, NewState};

handle_cast({add_to_send_queue, MsgBin}, State) ->
	#state{timer_sched=TimerSched, msg_queue=MsgQueue} = State,
	?INFO(g_bulletin_queue,"add_to_send_queue"),
	%% 如果没有设置timer，马上尝试发包
	case TimerSched of
		none ->
			gen_server:cast(self(), do_broadcast);
		_ ->
			void
	end,
	
	NewMsgQueue = MsgQueue ++ [MsgBin],
	{noreply, State#state{msg_queue=NewMsgQueue}};

handle_cast(_Msg, State) ->
	?DEBUG(g_bulletin_queue, "Got unknown message: ~w", [_Msg]),
	{noreply, State}.

handle_call(_Msg, _From, State) ->
	?DEBUG(g_bulletin_queue, "Got unknown message from ~w: ~w", [_From, _Msg]),
	{noreply, State}.

handle_info(_Info, State) ->
	?DEBUG(g_bulletin_queue, "handle_info called: ~w", [_Info]),
	{noreply, State}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

terminate(_Reason, State) ->
	?INFO(g_bulletin_queue, "terminate called, Reason: ~w, State: ~w", [_Reason, State]),
	case State#state.timer_sched of
		none -> void;
		TRef -> timer:cancel(TRef)
	end,
    ok.

%%
%% Local Functions
%%

