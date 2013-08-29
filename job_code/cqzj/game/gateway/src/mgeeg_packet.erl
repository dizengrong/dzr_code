%% Author: Liangliang
%% Modified: 2011-10-11
-module(mgeeg_packet).

%%
%% Include files
%%
-include("mgeeg.hrl").

%%
%% Exported Functions
%%
-export([
         recv/1, 
         send/2, 
         send/5,
         recv/2, 
         packet_encode_send/5,
         packet_encode/4
        ]).

-export([
         packet/4, 
         unpack/1
        ]).

%% here we don't care the cross domain file
recv(ClientSock) ->
    case gen_tcp:recv(ClientSock, 0) of
        {ok, RealData} ->
            {ok, mgeeg_packet:unpack(RealData)};
        {error, closed} ->
            ?INFO_MSG("~ts", ["socket连接断开了"]),
            {error, closed};
        {error, Reason} ->
            ?ERROR_MSG("read packet data failed: ~w on socket ~w", [Reason, ClientSock]),
            {error, Reason}
    end.

%% @desc sometime we need the Timeout option
recv(ClientSock, Timeout) ->
    case gen_tcp:recv(ClientSock, 0, Timeout) of
	{ok, RealData} ->
	    {ok, mgeeg_packet:unpack(RealData)};
        {error, closed} ->
            ?INFO_MSG("~ts", ["socket连接断开了"]),
            {error, closed};
	{error, Reason} ->
	    ?ERROR_MSG("read packet data failed: ~w on socket ~w", [Reason, ClientSock]),
	    {error, Reason}
    end.


packet_encode_send(ClientSock, Unique, Module, Method, DataRecord) ->
    case (catch packet_encode_send2(ClientSock, Unique, Module, Method, DataRecord) ) of
	{'EXIT', Info} -> 
            ?ERROR_MSG("error when packet_encode_send Module:~w, Method:~w, Info:~w", 
                       [Module, Method, Info]);
	_ -> 
            ok
    end. 								

packet_encode_send2(ClientSock, Unique, Module, Method, DataRecord) ->
    send(ClientSock, mgeeg_packet:packet(Unique, Module, Method, erlang:term_to_binary(DataRecord))).


send(ClientSock, Bin) ->
    catch erlang:port_command(ClientSock, Bin, [force]).


send(ClientSock, Unique, Module, Method, DataRecord) ->
	mm_parser:parse(Module,Method,DataRecord),
    Bin = mgeeg_packet:packet(Unique, Module, Method, erlang:term_to_binary(DataRecord)),
    send(ClientSock, Bin).


packet_encode(Unique, Module, Method, DataRecord) ->
	mm_parser:parse(-1,Method,DataRecord),
    mgeeg_packet:packet(Unique, Module, Method, erlang:term_to_binary(DataRecord)).


packet(Unique, Module, Method, Data) when is_integer(Module) andalso is_integer(Method) andalso erlang:is_integer(Unique) andalso erlang:is_binary(Data) ->
    case erlang:byte_size(Data) > 2048 of
        true ->
            C = zlib:compress(Data),
            <<1:1, Unique:15, Module:8, Method:16, C/binary>>;
        false ->
            <<Unique:16, Module:8, Method:16, Data/binary>>
    end;
packet(_, _, _, _) ->
    throw({error, args_type_wrong}).

unpack(<<0:1, Unique:15,  ModuleID:8, MethodID:16, Data/binary>>) ->
	DataRecord = erlang:binary_to_term(Data, [safe]),
	mm_parser:parse(ModuleID,MethodID,DataRecord),
    {Unique, ModuleID, MethodID, DataRecord};
unpack(<<1:1, Unique:15,  ModuleID:8, MethodID:16>>) ->
	mm_parser:parse(ModuleID,MethodID,undefined),
    {Unique, ModuleID, MethodID, undefined};
unpack(<<1:1, Unique:15,  ModuleID:8, MethodID:16, Data/binary>>) ->
	DataRecord = erlang:binary_to_term(zlib:uncompress(Data), [safe]),
	mm_parser:parse(ModuleID,MethodID,DataRecord),
    {Unique, ModuleID, MethodID, DataRecord}.
