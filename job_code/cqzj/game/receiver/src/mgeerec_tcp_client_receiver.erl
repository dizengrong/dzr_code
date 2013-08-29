%% Author: Liangliang
%% Created: 2010-3-12
%% Description: TODO: Add description to mgeerec_tcp_client_receiver
-module(mgeerec_tcp_client_receiver).

-include("mgeerec.hrl").

-export([start/2]).


%%开始握手
start(ClientSock, Parent) ->
    case gen_tcp:recv(ClientSock, 0) of
        {ok, Handshaking} when erlang:byte_size(Handshaking) =:= 23 ->
            ?DEBUG("~ts", ["握手成功"]),
            do_auth(ClientSock, Parent);
        O ->
            ?DEBUG("~ts:~p ~p", ["没有发握手包", ClientSock, O]),
            exit(not_valid_client)
    end.


do_auth(ClientSock, ParentPID) ->
    %%握手之后的包必须为认证包
    case gen_tcp:recv(ClientSock, 0) of
        {ok, Binary} ->
            {?B_SERVER, ?B_SERVER_AUTH, AuthRecord} = erlang:binary_to_term(Binary),
            #b_server_auth_tos{agent_name=AgentName, game_id=GameID, ticket=Ticket} = AuthRecord,
            case mgeerec_auth:auth(ClientSock,AgentName, GameID, Ticket) of
                {ok, AgentID} ->
                    ?DEBUG("~ts", ["游戏服认证成功"]),
                    R = #b_server_auth_toc{succ=true},
                    mgeerec_packet:send(ClientSock, ?B_SERVER, ?B_SERVER_AUTH, R),
                    mgeerec_tcp_client:notify_auth_passed(ParentPID, AgentName, GameID),
                    %%?DEBUG("~ts", ["记录连接状况"]),
                    %%connect_status_server:log_conn(ClientSock,AgentName,GameID),
                    ?DEBUG("~ts", ["开始循环"]),
                    loop(ClientSock, ParentPID, AgentID, GameID);
                {error, Reason} ->
                    ?ERROR_MSG("~ts: [~p]  ~p ~p ~w", ["游戏服认证失败", AgentName, GameID, Ticket,Reason]),
                    case inet:peername(ClientSock) of
                        {ok, {IP, _}} ->
                            ?ERROR_MSG("游戏服认证失败,ClienIP=~w", [IP]);
                        {error, _} ->
                            next
                    end,
                    R = #b_server_auth_toc{succ=false, reason=Reason},
                    mgeerec_packet:send(ClientSock, ?B_SERVER, ?B_SERVER_AUTH, R),
                    gen_tcp:close(ClientSock),
                    exit(not_valid_client)
            end;
        {error, closed} ->
            %%connect_status_server:del_conn(ClientSock),
            ?ERROR_MSG("~ts", ["游戏服发送握手包之后就断开了"]);
        {error, Reason} ->
            ?ERROR_MSG("~ts:~w", ["读取游戏服认证包出错", Reason]),
            %%connect_status_server:del_conn(ClientSock),
            gen_tcp:close(ClientSock),
            exit(not_valid_client)
    end.


%%循环收包
loop(ClientSock, ParentPID, AgentID, GameID) ->
    case mgeerec_packet:recv(ClientSock) of
        {ok, heartbeat} ->
            mgeerec_tcp_client:notify_heartbeat(ParentPID),
            loop(ClientSock, ParentPID, AgentID, GameID);
        {ok, BehaviorList} ->
            mgeerec_router:router({ParentPID, BehaviorList, AgentID, GameID}),
            loop(ClientSock, ParentPID, AgentID, GameID);
        {error, _Reason} ->
            exit(catch_normal)
    end.
