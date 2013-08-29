%%%----------------------------------------------------------------------
%%% File    : mgeerec_tcp_acceptor.erl
%%% Author  : Liangliang
%%% Created : 2010-03-10
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeerec_tcp_acceptor).

-include("mgeerec.hrl").

-behaviour(gen_server).

-export([start_link/2]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%%--------------------------------------------------------------------

start_link(Callback, LSock) ->
    gen_server:start_link(?MODULE, {Callback, LSock}, []).

%%--------------------------------------------------------------------

init({_Callback, LSock}) ->
    erlang:process_flag(trap_exit, true),
    {ok, LSock}.

handle_info({event, start}, LSock = State) ->
    ?INFO_MSG("~ts ~p", ["等待新连接", LSock]),
    case gen_tcp:accept(LSock) of
	{ok, ClientSock} -> 
            case supervisor:start_child(mgeerec_tcp_client_sup, [ClientSock]) of
                {ok, CPid} ->
                    CPid ! {event, run},
                    gen_tcp:controlling_process(ClientSock, CPid);
                {error, Error} ->
                    ?CRITICAL_MSG("cannt accept client:~p", [Error])
            end,
            self() ! {event, start},
            {noreply, State};
	{error, Reason} -> 
            {stop, Reason, State}
    end;


handle_info({'EXIT', _, _Reason}, State) ->
    
    {stop, normal, State};


handle_info(Info, State) ->
    ?INFO_MSG("get msg from handle_info/2 ~p ~p", [Info, State]),
    {noreply, State}.


handle_call(_Request, _From, State) ->
    {noreply, State}.


handle_cast(Msg, State) ->
    ?INFO_MSG("get msg from handle_case/2 ~p ~p", [Msg, State]),
    {noreply, State}.


terminate(Reason, _State) ->
    ?DEBUG("~ts:~p", ["acceptor进程结束", Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
