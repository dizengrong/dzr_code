-module (common_title_srv).
-behaviour(gen_server).
-export([
			start/0,
			start_link/0,
			add_title/3,
			remove_by_typeid/2,
			remove_by_titleid/2
		]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").


start() ->
    {ok,_} = supervisor:start_child(mgeew_sup, 
                           {?MODULE, 
                            {?MODULE, start_link,[]},
                            permanent, 30000, worker, [?MODULE]}).
    
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [],[]).

init([]) ->
    erlang:process_flag(trap_exit, true),
    {ok, []}.

add_title(TitleType, DestID, Info) ->
	 global:send(?MODULE, {add_title, TitleType, DestID, Info}).

remove_by_typeid(TitleType, DestID) ->
	 global:send(?MODULE, {remove_by_typeid, TitleType, DestID}).

remove_by_titleid(TitleID, DestID) ->
	 global:send(?MODULE, {remove_by_titleid, TitleID, DestID}).



handle_call(_Msg, _From, State) ->
    {reply, unhandle_msg, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Msg, State) ->	
	try 
		do_handle_info(Msg)
	catch
		T:R ->
			?ERROR_MSG("Msg:~w, type:~w, reason:~w, stactraceo:~w", [Msg, T, R, erlang:get_stacktrace()])
	end,
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

do_handle_info({add_title, TitleType, DestID, Info}) ->
	common_title:add_title(TitleType, DestID, Info);
do_handle_info({remove_by_typeid, TitleType, DestID}) ->
	common_title:remove_by_typeid(TitleType, DestID);
do_handle_info({remove_by_titleid, TitleID, DestID}) ->
	common_title:remove_by_titleid(TitleID, DestID).
