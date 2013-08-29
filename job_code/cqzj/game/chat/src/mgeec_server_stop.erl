%%% -------------------------------------------------------------------
%%% Author  : Chixiaosheng
%%% Description :
%%%
%%% Created : 2010-11-25
%%% -------------------------------------------------------------------
-module(mgeec_server_stop).
-include("mgeec.hrl").


-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([start/0, start_link/0, stop_server_clear/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
stop_server_clear() ->
    gen_server:call(global:whereis_name(?MODULE), stop_server_clear).

start() ->
    supervisor:start_child(mgeec_sup,
        {?MODULE, {?MODULE, start_link, []},
                  transient, infinity, supervisor, [?MODULE]}).
start_link() ->
    {ok, _Pid} =
        gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).
    

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    {ok, #state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call(stop_server_clear, _From, State) ->
    
    %%悲剧啊~要清理在线信息~
    ChannelList = db:dirty_match_object(?DB_CHAT_CHANNELS, #p_channel_info{_='_'}),
    lists:foreach(
      fun(ChannelInfo)->
        NewChannelInfo = ChannelInfo#p_channel_info{online_num=0},
        db:dirty_write(?DB_CHAT_CHANNELS, NewChannelInfo)
      end, ChannelList),
    
    
    RoleList = db:dirty_match_object(?DB_CHAT_CHANNEL_ROLES, #p_chat_channel_role_info{is_online=true,_='_'}),
    lists:foreach(
      fun(RoleChannelInfo)->
        NewRoleChannelInfo = RoleChannelInfo#p_chat_channel_role_info{is_online=false},
        db:dirty_delete_object(?DB_CHAT_CHANNEL_ROLES, RoleChannelInfo),
        db:dirty_write(?DB_CHAT_CHANNEL_ROLES, NewRoleChannelInfo)
      end, RoleList),
    
    Reply = ok,
    {reply, Reply, State};
    
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

