%%%----------------------------------------------------------------------
%%% @copyright 2010 mcs (Ming Chao Server)
%%%
%%% @author bisonwu, 2010-7-13
%%% @doc mgeebgp_worker
%%%		bgproxy is short for border gateway proxy
%%% @end
%%%----------------------------------------------------------------------

-module(mgeebgp_worker).

%%
%% Include files
%%
-include("common.hrl").
-include("mgeebgp_comm.hrl").

%%
%% Exported Functions
%%
-export([]).
-export([do_auth/2]).

%%
%% API Functions
%%

%% 保留最后一位做扩展
-define(HANDSHAKE_PACKET(X),       <<0,23,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,X>>).
-define(HANDSHAKE_PACKET_TOGAME(X),<<0,23,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,X>>).


%% @spec do_auth/1
do_auth(ClientSock,ProxyConf) ->
    #proxy_conf{security_key=SecurityKey} = ProxyConf,
    
    try
        case gen_tcp:recv(ClientSock, 23, ?RECV_TIMEOUT) of
            {ok, ?CROSS_DOMAIN_FLAG} ->  
                sendCrossDomainFile(ClientSock);
            {ok, ?HANDSHAKE_PACKET(X)}-> 
                case process_request(ClientSock,X) of
                    ok -> ignore;
                    _ -> close_sock(ClientSock)
                end;
            {ok, SecurityKey}-> 
                process_monitor(ClientSock);
            {ok, <<"How are you, cangqiong?">>} -> 
                ?ERROR_MSG("response for hostmonitor. ", []),
                ResponseData = <<"I am fine!">>,
                gen_tcp:send(ClientSock, ResponseData),			
                timer:sleep(100),
                close_sock(ClientSock);
            {ok, Other} -> 
                ?WARNING_MSG("receive bad data: ~p", [Other]),
                close_sock(ClientSock);
            {error, Reason} -> 
                ?ERROR_MSG("gen_tcp:recv error,Reason=~p", [Reason]),
                close_sock(ClientSock)
        end
    catch
        _:Why -> 
            ?ERROR_MSG("catch exception ,Why:~p, stacktrace:~p",[Why,erlang:get_stacktrace()]),
            close_sock(ClientSock)
    end.



%%
%% Local Functions
%%


%% @spec process_request(ClientSock::sock(),X::integer()) -> ok | {error,Reason}
process_request(ClientSock,X)->
    case parse_destination(ClientSock) of
        {ok, #m_bgp_login_tos{id=ID}=DestRec}->
            case inet:peername(ClientSock) of
                {ok, {ClientIP, _ }} ->
                    process_handshake(DestRec,ClientSock,ClientIP,X);
                {error, Reason2} ->
                    mgeebgp_packet:send_toc(ClientSock,ID,{error,Reason2}),
                    {error, Reason2}
            end;
        {error, Reason1} ->
            mgeebgp_packet:send_toc(ClientSock,0,{error,Reason1}),
            {error, Reason1}
    end.

%% @spec process_handshake/5 -> ok | {error,Reason}
process_handshake(DestRec,ClientSock,ClientIP,X)->
    #m_bgp_login_tos{id=ID,host=DestServer,port=DestPort} = DestRec,
    
    HandshakeResult = handshake_server00({DestServer,DestPort},X),
    
    case HandshakeResult of
        {ok,ServerSock}->
            
            ItemID = make_ref(),
            mgeebgp_monitor:add_item(ItemID,ClientIP,{DestServer,DestPort}),
            
            %% notify client sock
            mgeebgp_packet:send_toc(ClientSock,ID,{ok}),
            
            Pid1 = spawn(fun() -> do_tunnel(s_to_c,ServerSock,ClientSock,ItemID)end),
            gen_tcp:controlling_process(ServerSock, Pid1),
            
            Pid2 = spawn(fun() -> do_tunnel(c_to_s,ClientSock,ServerSock,ItemID)end),
            gen_tcp:controlling_process(ClientSock, Pid2),
            
            %% final normal result
            ok;
        {error, Reason2} -> 
            %% notify client sock
            mgeebgp_packet:send_toc(ClientSock,ID,{error,Reason2}),
            {error, Reason2}
    end.

%% @spec process_monitor(ClientSock::sock())
process_monitor(ClientSock)->
	case mgeebgp_monitor:parse_data(ClientSock) of
		{ok, heartbeat} ->
			process_monitor(ClientSock);
		{ok, <<"connections">>}->
			Bin2 = mgeebgp_monitor:get_connections(),
			mgeebgp_packet:send_admin(ClientSock,Bin2,"connections"),
			process_monitor(ClientSock);
		_ ->
			close_sock(ClientSock),			
			ignore
	end.

%% @spec do_tunnel(FromSock::sock(),ToSock::sock(),MonitorItem::tuple()) ->  {error, Reason}
do_tunnel(Type,FromSock,ToSock,MonitorItemID)->
	%% here may change the length option
	case gen_tcp:recv(FromSock, 0) of
		{ok,Data}->	
			gen_tcp:send(ToSock,Data),
			do_tunnel(Type,FromSock,ToSock,MonitorItemID);
		{error, Reason}->
            %%?ERROR_MSG("bison,do_tunnel3,close Type=~w,FromSock=~w",[Type,FromSock]),
			case Reason of 
				closed -> ignore;
				_ ->	?ERROR_MSG("recv error while do_tunnel,Reason=~p",[Reason])
			end,
			close_socks([FromSock,ToSock]),
			mgeebgp_monitor:remove_item(MonitorItemID),
			{error,Reason}
	end.

%% @spec handshake_server00(DestServer::string(),DestPort::integer(),X::integer())
%%		-> {ok,Sock} | {error,Reason} 
handshake_server00({DestServer,DestPort},X)->
    ?DEBUG("~p~p", [DestServer,DestPort]),
    case gen_tcp:connect(DestServer, DestPort, ?BGP_TCP_OPTS) of
        {ok,Sock}->
            %% handshake
            ok = gen_tcp:send(Sock,?HANDSHAKE_PACKET_TOGAME(X)),
            {ok,Sock};
        {error,Reason}->
            {error,Reason}
    end.


%% @spec close_socks(SockList::list())
close_socks(SockList) when is_list(SockList)->
	lists:foreach(fun(Socket)->
						  gen_tcp:close(Socket)
				  end, SockList).

%% @spec close_sock(Sock::socket())
close_sock(Sock)->
	gen_tcp:close(Sock).

%% @spec parse_destination(ClientSock::sock()) ->
%%		{ok, {DestServer,DestPort}} | {error, Reason}
parse_destination(ClientSock) ->
    gen_tcp:recv(ClientSock, 2, ?RECV_TIMEOUT),
    case gen_tcp:recv(ClientSock, 4, ?RECV_TIMEOUT) of
        {ok, PacketLenBin} -> 
            <<PacketLen:32>> = PacketLenBin,
            case gen_tcp:recv(ClientSock, PacketLen, ?RECV_TIMEOUT) of
                {ok, RealData} ->
                    {_Unique, _ModuleID, _MethodID, DataBin2}  = mgeebgp_packet:unpack(RealData),
                    Record = mgeebgp_packet:decode(DataBin2),
                    {ok,Record};
                {error, Reason} ->
                    ?WARNING_MSG("read packet data failed with reason: ~p on socket ~p", [Reason, ClientSock]),
                    {error, Reason}
            end;
        {error, Reason} -> 
            ?INFO_MSG("read packet length failed with reason: ~p on socket ~p", [Reason, ClientSock]),
            {error, Reason}
    end.
 
%%@doc 发送CROSS_DOMAIN的回复
sendCrossDomainFile(CSock)->
    Data = list_to_binary(?CROSS_FILE),
    case gen_tcp:send(CSock, Data) of
        ok ->
            ok;
        {error, Reason} ->
            ?ERROR_MSG("failed to send CROSS DOMAIN FILE ~p", [Reason])
    end,
    gen_tcp:close(CSock).


