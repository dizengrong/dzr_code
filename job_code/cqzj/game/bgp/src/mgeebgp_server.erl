%%%----------------------------------------------------------------------
%%% @copyright 2010 mcs (Ming Chao Server)
%%%
%%% @author bisonwu, 2010-7-13
%%% @doc mgeebgp_server
%%%		bgproxy is short for border gateway proxy
%%% @end
%%%----------------------------------------------------------------------

-module(mgeebgp_server).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include("common.hrl").
-include("mgeebgp_comm.hrl").


-export([get_proxy_config/0]).
-export([
		 start/0,
		 start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% External functions
%% ====================================================================

start() ->
	ProxyConf = get_proxy_config(),
	
	supervisor:start_child(mgeebgp_sup, 
						   {mgeebgp_acceptor_sup,	
							{mgeebgp_acceptor_sup, start_link,[]},
							transient, infinity, supervisor, [mgeebgp_acceptor_sup]}),
	supervisor:start_child(mgeebgp_sup, 
						   {mgeebgp_server,	
							{?MODULE, start_link,[ProxyConf]},
						   	transient, brutal_kill, worker, [?MODULE]}),
	
	ok.
	

start_link(ProxyConf) ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, ProxyConf,[]).

%% @spec init(ProxyConf::#proxy_conf)
init(ProxyConf) ->
	start_server(ProxyConf),
	{ok, []}.


%% @spec get_proxy_config() -> #proxy_conf
get_proxy_config()->
    [EnvProxyConfig] = common_config_dyn:find(bgp,mgeebgp),
%%     {ok, EnvProxyConfig} = application:get_env( ?APP_MGEE_BGPRROXY ),
    case EnvProxyConfig of
        [{port,Port},{acceptor_num,AcceptNum},{security_key,SecKey}]->
            #proxy_conf{port=Port,acceptor_num=AcceptNum,security_key=SecKey};
        _ ->
            throw(proxy_config_error)
    end.



%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%% @spec start_server(ProxyConf::#proxy_conf)
start_server( ProxyConf )->
	#proxy_conf{port=Port,acceptor_num=ConcurrentAcceptorCount} = ProxyConf,
	SocketOpts = ?BGP_TCP_OPTS,
	?INFO_MSG("mgeebgp_server start to listen on tcp_port=~p,acceptor_num=~p",[Port,ConcurrentAcceptorCount]),
	
	case gen_tcp:listen(Port, SocketOpts) of   
		{ok, ListenSocket} -> 
			?INFO_MSG("mgeebgp_server has listened on tcp_port=~p",[Port]),
			%% if listen successful ,we start several acceptor to accept it
			lists:foreach(fun (X) ->
								   AcceptorName = common_tool:to_atom(lists:concat(["mgeebgp_acceptor_",X])),
								   case supervisor:start_child(mgeebgp_acceptor_sup, [AcceptorName,ListenSocket,ProxyConf]) of
									   {ok, APid} ->
										   erlang:send(APid, {start_do_acceptor});
									   R ->
										   ?ERROR_MSG("create new php_tcp_acceptor fail, ~p\n", [R]),
										   {false, fail_satrt_child}
								   end
						  end,
						  lists:seq(1, ConcurrentAcceptorCount, 1)
						 ),
			?INFO_MSG("Start mgeebgp_server tcp_port=~w OK.~n",[Port]);
		{error, Reason} ->
			?ERROR_MSG("Start mgeebgp_server tcp_port=~w fail,reason=~p!~n",[Port,Reason]),
			erlang:send_after(1000, self(), {exitOfListen,Port,Reason})
			
	end.
 
%% ====================================================================
%% Server functions
%% 		gen_server callbacks
%% ====================================================================

handle_call({w,Msg}, _From, State) ->
    ?ERROR_MSG("test write log,Msg=~w",[Msg]),
    {reply, ok, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info({exitOfListen,Port,Reason}, State) ->
	?ERROR_MSG("Start mgeebgp_server will exit!tcp_port=~w,reason=~p!~n",[Port,Reason]),
	mgeebgp_ctl:process(["stop"]),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


