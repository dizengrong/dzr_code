%%%----------------------------------------------------------------------
%%% File    : mgeeg_tcp_acceptor.erl
%%% Author  : Liangliang
%%% Created : 2010-03-10
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeeg_tcp_acceptor).

-include("mgeeg.hrl").

-behaviour(gen_server).

-export([start_link/2]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).


-define(CROSS_DOMAIN_FLAG, <<60,112,111,108,105,99,121,45,102,105,108,101,45,114,101,113,117,101,115,116,47,62,0>>).


-define(CROSS_FILE, "<?xml version=\"1.0\"?>\n<!DOCTYPE cross-domain-policy SYSTEM "
        ++"\"http://www.adobe.com/xml/dtds/cross-domain-policy.dtd\">\n"
        ++"<cross-domain-policy>\n"
        ++"<allow-access-from domain=\"*\" to-ports=\"*\"/>\n"
        ++"</cross-domain-policy>\n\0").

-record(state, {listen_socket, ref, line}).

%%--------------------------------------------------------------------

start_link(Line, LSock) ->
    gen_server:start_link(?MODULE, {Line, LSock}, []).

%%--------------------------------------------------------------------

init({Line, LSock}) ->
    erlang:process_flag(trap_exit, true),
    {ok, #state{listen_socket=LSock, line=Line}}.

handle_info({event, start}, State) ->
    accept(State);

handle_info({inet_async, LSock, Ref, {ok, Sock}}, State = #state{listen_socket=LSock, ref=Ref, line=Line}) ->
	%% patch up the socket so it looks like one we got from
    %% gen_tcp:accept/1
    {ok, Mod} = inet_db:lookup_socket(LSock),
    inet_db:register_socket(Sock, Mod),
    try        
        %% report
        {ok, {Address, Port}} = inet:sockname(LSock),
        {ok, {PeerAddress, PeerPort}} = inet:peername(Sock),
        ?DEBUG("accepted TCP connection on ~s:~p from ~s:~p~n",
                    [inet_parse:ntoa(Address), Port,
                     inet_parse:ntoa(PeerAddress), PeerPort]),
        spawn_socket_controller(Sock, Line, common_config:get_agent_name())
    catch Error:Reason ->
            gen_tcp:close(Sock),
            ?ERROR_MSG("unable to accept TCP connection: ~p ~p~n", [Error, Reason])
    end,
    accept(State);
handle_info({inet_async, LSock, Ref, {error, closed}}, State=#state{listen_socket=LSock, ref=Ref}) ->
    %% It would be wrong to attempt to restart the acceptor when we
    %% know this will fail.
    {stop, normal, State};

handle_info({'EXIT', _, shutdown}, State) ->    
    {stop, normal, State};
handle_info({'EXIT', _, _Reason}, State) ->
    {stop, normal, State};


handle_info(Info, State) ->
    ?ERROR_MSG("~ts:~w", ["收到未知消息", Info]),
    {noreply, State}.


handle_call(_Request, _From, State) ->
    {noreply, State}.


handle_cast(Msg, State) ->
    ?INFO_MSG("get msg from handle_case/2 ~w ~w", [Msg, State]),
    {noreply, State}.


terminate(Reason, _State) ->
    ?DEBUG("~ts:~w", ["acceptor进程结束", Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


spawn_socket_controller(ClientSock, Line, Agent) when Agent == "qq";
													  Agent == "pengyou" ->
	?DEV("~ts", ["新的socket连接"]),
    case gen_tcp:recv(ClientSock, 0) of
        {ok, _TgwPacket} ->
            case supervisor:start_child(mgeeg_tcp_client_sup, [ClientSock, Line]) of
                {ok, CPid} ->
                    inet:setopts(ClientSock, [{packet, 4}, binary, {active, false}, {nodelay, true}, {delay_send, true}]),
                    gen_tcp:controlling_process(ClientSock, CPid),
                    CPid ! start;
                {error, Error} ->
                    ?CRITICAL_MSG("cannt accept client:~w", [Error]),
                    catch erlang:port_close(ClientSock)
            end;
        Other ->
            ?ERROR_MSG("recv packet error:~w", [Other]),
            catch erlang:port_close(ClientSock)
    end;

spawn_socket_controller(ClientSock, Line, _)  ->

    ?DEV("~ts", ["新的socket连接"]),
    case gen_tcp:recv(ClientSock, 23, 30000) of
        {ok, ?CROSS_DOMAIN_FLAG} ->
            gen_tcp:send(ClientSock, list_to_binary(?CROSS_FILE)),
    		gen_tcp:close(ClientSock);
        {ok, _Bin} ->
            gen_tcp:recv(ClientSock, 2),
            case supervisor:start_child(mgeeg_tcp_client_sup, [ClientSock, Line]) of
                {ok, CPid} ->
                    inet:setopts(ClientSock, [{packet, 4}, binary, {active, false}, {nodelay, true}, {delay_send, true}]),
                    gen_tcp:controlling_process(ClientSock, CPid),
                    CPid ! start;
                {error, Error} ->
                    ?CRITICAL_MSG("cannt accept client:~w", [Error]),
                    catch erlang:port_close(ClientSock)
            end;
        Other ->
            ?ERROR_MSG("recv packet error:~w", [Other]),
            catch erlang:port_close(ClientSock)
    end.

accept(State = #state{listen_socket=LSock}) ->
    case prim_inet:async_accept(LSock, -1) of
        {ok, Ref} -> 
            {noreply, State#state{ref=Ref}};
        Error -> 
            {stop, {cannot_accept, Error}, State}
    end.
