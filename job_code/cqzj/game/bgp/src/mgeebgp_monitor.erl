%%%----------------------------------------------------------------------
%%% @copyright 2010 mcs (Ming Chao Server)
%%%
%%% @author bisonwu, 2010-7-13
%%% @doc mgeebgp_monitor
%%%		bgproxy is short for border gateway proxy
%%% @end
%%%----------------------------------------------------------------------

-module(mgeebgp_monitor).
-behaviour(gen_server).

%%
%% Include files
%%
-include("common.hrl").
-include("mgeebgp_comm.hrl").


%%
%% Exported Functions
%%
-export([should_monitor/0]).
-export([start/0,start_link/0,parse_data/1]).
-export([add_item/3,remove_item/1,get_connections/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% External functions
%% ====================================================================
start()->
    {ok, _} = supervisor:start_child(
                mgeebgp_sup, 
                {?MODULE,
                 {?MODULE, start_link, []},
                 transient, brutal_kill, worker, [?MODULE]}),
    mgeebgp_monitor_log:start(),
    ok.


start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [],[]).

init([]) ->
    ets:new(?ETS_BGP_CONNS, [set, public, named_table]),
    
    {ok, []}.

%%
%% API Functions
%%

%% @spec parse_data(ClientSock:: sock()) -> {ok,Data} | {error,Reason}
parse_data(ClientSock)->
	case gen_tcp:recv(ClientSock, 2) of
		{ok, <<PacketLen:16>>} -> 
			case gen_tcp:recv(ClientSock, PacketLen) of
				{ok, <<"00">>} ->
					{ok, heartbeat};
				{ok, RealData} ->
					{ok, RealData};
				{error, Reason} ->
					?ERROR_MSG("read packet data failed with reason: ~p on socket ~p", [Reason, ClientSock]),
					{error, Reason}
			end;
		{error, Reason} -> 
			?ERROR_MSG("read packet length failed with reason: ~p on socket ~p", [Reason, ClientSock]),
			{error, Reason}
	end.


%% @spec get_connections() -> string()
get_connections()->
    List = ets:tab2list(?ETS_BGP_CONNS),
    {Result,Count} = lists:mapfoldl(fun(E,Sum)-> 
                                            {_,ClientAddress,{DestHost,DestPort},Now1} = E,
                                            R = concat(["client:",
                                                        mgeebgp_misc:ip_to_binary(ClientAddress),",server:",DestHost,"[",DestPort,"],",Now1,"\n"]),
                                            {R,Sum+1}
                                    end, 0, List),
    erlang:list_to_binary( concat(["all connections:",Count,"\n",concat(Result)]) ).

%% @spec add_item(MonitorItemID::tuple(),ClientSock::sock(),DestAddress::tuple()) -> boolean()
add_item(MonitorItemID,ClientIP,DestAddress)->
    case should_monitor() of
        true->
            Now = common_tool:now(),
            ets:insert(?ETS_BGP_CONNS, {MonitorItemID,ClientIP,DestAddress,Now});
        _ -> false
    end.

%% @spec remove_item(UID::tuple()) -> boolean()
remove_item(MonitorItemID)->
    case should_monitor() of
        true->
            ets:delete(?ETS_BGP_CONNS, MonitorItemID);
        _ -> false
    end.


should_monitor()->
    case common_config_dyn:find(bgp,should_monitor) of
        [true]-> 
            true;
        _ ->
            false
    end.

%%
%% Local Functions
%%

concat(Things)->
	lists:concat(Things).


%% ====================================================================
%% Server functions
%% 		gen_server callbacks
%% ====================================================================

handle_call({get_state}, _From, State) ->
    {reply, State, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
	

