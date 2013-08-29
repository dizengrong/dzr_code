-module(mod_vip).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").


%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%%export for other module
-export([get_vip_level/1, check_vip/2]).

%%export for vip module
-export([start_link/1
	]).


-record(vip_info,{id,
				gold_sum = 0,
				vip_card_time_end=0,
				vip_card_level = 0
				 }).

%%====================================================================   
%% API   
%%====================================================================   
%%--------------------------------------------------------------------   
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}   
%% Description: Starts the server   
%%--------------------------------------------------------------------   
start_link(PlayerId) ->   
    gen_server:start_link(?MODULE, {PlayerId}, []).

%% init_ets()->
%% 	ets:new(vip_info,[named_table,set,public,{keypos,#vip_info.id}]).

%%return the vip level,sync
-spec get_vip_level(player_id())-> integer().
get_vip_level(PlayerId)->
	3.

%% 检测当前的vip是否满足要求的vip，满足则返回true，否则返回false
-spec check_vip(player_id(), integer()) -> boolean().
check_vip(PlayerId, VipRequire) ->
	true.
%% 	(get_vip_level(PlayerId) >= VipRequire).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% --------------------------------------------------------------------
	
init({PlayerId}) ->
    process_flag(trap_exit, true),
    erlang:put(id, PlayerId),
	{ok, []}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% --------------------------------------------------------------------
handle_call({get_vip_level}, _From, Old_vip_info) ->
	{reply, 3, Old_vip_info}.
	


%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% --------------------------------------------------------------------
handle_cast(_Msg, []) ->
	{noreply, []}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({'EXIT', _, Reason}, State) ->
    {stop, Reason, State};

handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, _State) ->
	?INFO(vip,"vip terminating reason ~w",[Reason]),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
