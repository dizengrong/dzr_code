%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc 专门用于和receiver.server通讯的解包、封包、发送、接受模块
%%% Created :  1 Jul 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeeb_packet).

%% API
-export([
         send/3,
         unpack/1
        ]).

-include("mgeeb.hrl").


send(ClientSock, Bin) ->
    ?DEBUG("~ts: ~w", ["准备发送数据", Bin]),
    case gen_tcp:send(ClientSock, Bin) of
	ok -> 
            ok;
	{error, closed} -> 
            {error, closed};
	{error, Reason} -> 
            {error, Reason}
    end.


%%receiver发给behavior的包的格式为 {module, method, binary_data}
send(ClientSock, Unique, BehaviorList) when is_list(BehaviorList) ->
    send(ClientSock, packet(Unique, BehaviorList)).


%%封包
packet(Unique, BehaviorList) ->
    B = erlang:term_to_binary(BehaviorList),
    <<Unique:32, B/binary>>.


%%解包
unpack(Data) ->
    erlang:binary_to_term(Data).
