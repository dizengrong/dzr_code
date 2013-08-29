%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 30 Jun 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mgeerec_auth).

%% API
-export([auth/4,auth/3]).

auth(ClientSock,AgentName, GameID, _Ticket)->
    case catch inet:peername(ClientSock) of
        {ok,{IP,_Port}}->auth1(IP,AgentName, GameID);
        _ ->{error,"socket连接错误，无法获取ip"}
    end.

auth1(IP,AgentName, GameID)->
    case  common_config_dyn:find(receiver_server,{server_host,AgentName,GameID}) of
        [IPList]->
            case lists:any(fun(TmpIP)->TmpIP=:=IP end, IPList) of
                true->
                    [AgentID]=common_config_dyn:find(receiver_server,{agent_config,AgentName}),
                    {ok,AgentID};
                false->
                    {error,IP}
            end;
        []->case common_config_dyn:find(receiver_server,{agent_config,AgentName}) of
                [AgentID]->{ok,AgentID};
                []->{error,{AgentName,GameID}}
            end
    end.

auth("4399", _, _) ->
    {ok, 1};
auth("2918", _, _) ->
    {ok, 2};
auth("unalis", _, _) ->
    {ok, 3};
auth("91wan", _, _) ->
    {ok, 4};
auth("kuwo", _, _) ->
    {ok, 5};
auth("360", _, _) ->
    {ok, 6};
auth("baidu", _, _) ->
    {ok, 7};
auth("pps", _, _) ->
    {ok, 8};
auth("mc", _, _)->
    {ok,1000}.
