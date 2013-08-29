%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     mgeew_broadcast_loop_server 循环广播服务
%%% @end
%%% Created : 2010-12-15
%%%-------------------------------------------------------------------
-module(mgeew_broadcast_loop_server).
-behaviour(gen_server).
-record(state,{}).


-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(MSG_BC_LOOP, msg_bc_loop).
-define(LOOP_INTERVAL,1000).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").


%% ====================================================================
%% External functions
%% ====================================================================

start_link()  ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [],[]).

init([]) ->
    erlang:send_after(?LOOP_INTERVAL, self(), ?MSG_BC_LOOP),
    State = #state{},
    {ok, State}.
 
 
%% ====================================================================
%% Server functions
%%      gen_server callbacks
%% ====================================================================
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
 

do_handle_info(?MSG_BC_LOOP)->
    erlang:send_after(?LOOP_INTERVAL, self(), ?MSG_BC_LOOP),

    do_bc_msg_loop();

do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.

%%执行消息的广播
do_bc_msg_loop()->
    Time = erlang:time(),
    BcList = common_config_dyn:list(broadcast_loop),
    lists:foreach(fun(E)-> 
                          do_bc_msg_loop_2(Time,E)
                  end, BcList),
    ok.

do_bc_msg_loop_2(Time,E) when is_record(E,r_bc_msg)->
    #r_bc_msg{id=ID,circle_type=CirclType,msg_type=MsgType,start_time=StartTime,msg=Msg}=E,
    
    case CirclType of
        1-> %%每天固定时间
            if Time =:= StartTime->
                   case MsgType of
                       1-> %%世界广播
                           ?ERROR_MSG("do_bc_msg_loop,ID=~w,Time=~w",[ID,Time]),
                           common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT, ?BC_MSG_TYPE_CHAT_WORLD, Msg);
                       _ ->
                           ignore
                   end;
               true->
                   ignore
            end;
        _ ->
            ignore
    end;
do_bc_msg_loop_2(_, _) ->
    ignore.
