%%%----------------------------------------------------------------------
%%% File    : mgeeg_networking.erl
%%% Author  : Liangliang
%%% Created : 2010-01-02
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeeg_networking).

-define(TCP_OPTS, [
                   binary, 
                   {packet, 0},
                   {reuseaddr, true}, 
                   {nodelay, true},   
                   {delay_send, true}, 
                   {active, false},
                   {backlog, 1024},
                   {exit_on_close, false},
                   {send_timeout, 15000}
                  ]).

-include("mgeeg.hrl").
-include_lib("kernel/include/inet.hrl").

-export([start/0, start_tcp_listener/3]).
-export([
         tcp_listener_started/2, 
         tcp_listener_stopped/2, 
         tcp_host/1
        ]).

%% API Functions

start() ->
    {ok, _} = supervisor:start_child(mgeeg_sup, {mgeeg_tcp_client_sup,
                                                     {mgeeg_tcp_client_sup, start_link, []},
                                                     permanent, infinity, supervisor, 
                                                     [mgeeg_tcp_client_sup]}).


start_tcp_listener(Port, Line, AcceptorNum) ->
	ID = common_tool:to_atom(lists:concat(["mgeeg_tcp_listener_sup_",Line])),
    {ok,_} = supervisor:start_child(
               mgeeg_sup,
               {ID,
                {mgeeg_tcp_listener_sup, start_link,
                 [Port, Line, ?TCP_OPTS ,
                  {?MODULE, tcp_listener_started, [localhost]},
                  {?MODULE, tcp_listener_stopped, [localhost]}, AcceptorNum]},
                transient, infinity, supervisor, [mgeeg_tcp_listener_sup]}),
    ok.


tcp_listener_started(Host, Port) ->
    ?INFO_MSG("~ts ~w:~w", ["端口开始监听", Host, Port]),
    ok.

tcp_listener_stopped(Host, Port) ->
    ?INFO_MSG("~ts ~w:~w", ["端口停止监听", Host, Port]),
    ok.


tcp_host({0,0,0,0}) ->
    {ok, Hostname} = inet:gethostname(),
    case inet:gethostbyname(Hostname) of
        {ok, #hostent{h_name = Name}} -> Name;
        {error, _Reason} -> Hostname
    end;
tcp_host(IPAddress) ->
    case inet:gethostbyaddr(IPAddress) of
        {ok, #hostent{h_name = Name}} -> Name;
        {error, _Reason} -> inet_parse:ntoa(IPAddress)
    end.
