%%%----------------------------------------------------------------------
%%% @copyright 2010 mcs (Ming Chao Server)
%%%
%%% @author bisonwu, 2010-7-13
%%% @doc mgeebgp_acceptor
%%%		bgproxy is short for border gateway proxy
%%% @end
%%%----------------------------------------------------------------------

-module(mgeebgp_acceptor).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include("common.hrl").
-include("mgeebgp_comm.hrl").


-export([start_link/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).



%% ====================================================================
%% External functions
%% ====================================================================

start_link(AcceptorName,ListenSocket,ProxyConf) ->
	gen_server:start_link({local, AcceptorName}, ?MODULE, {AcceptorName,ListenSocket,ProxyConf},[]).

init({AcceptorName,ListenSocket,ProxyConf}) ->
	?INFO_MSG("~p init,AcceptorName=~p",[?MODULE,AcceptorName]),
	{ok, {AcceptorName,ListenSocket,ProxyConf}}.

%% ====================================================================
%% Server functions
%% 		gen_server callbacks
%% ====================================================================
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info({start_do_acceptor}, {_AcceptorName,ListenSocket,ProxyConf} = State) ->
	do_acceptor(ListenSocket,ProxyConf), 
	{noreply, State};

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% @spec do_acceptor/2
do_acceptor(ListenSocket,ProxyConf) ->
	case gen_tcp:accept(ListenSocket) of   
		{ok, Socket} ->   
			spawn(fun() -> mgeebgp_worker:do_auth(Socket,ProxyConf) end),
			do_acceptor(ListenSocket,ProxyConf);   
		{error, Reason} ->   
			?ERROR_MSG(" do_acceptor error: ~p", [Reason]),
			exit({do_acceptor_error,Reason})   
	end.   
