%%%----------------------------------------------------------------------
%%% @copyright 2010 mcs (Ming Chao Server)
%%%
%%% @author bisonwu, 2010-7-13
%%% @doc mgeebgp_monitor_log
%%%		bgproxy is short for border gateway proxy
%%% @end
%%%----------------------------------------------------------------------

-module(mgeebgp_monitor_log).
-behaviour(gen_server).

%%
%% Include files
%%
-include("common.hrl").
-include("mgeebgp_comm.hrl").


%%
%% Exported Functions
%%
-export([]).
-export([start_link/0,start/0]).

-define(DEFAULT_WRITE_INTERVAL,15).

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
    ok.

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [],[]).


init([]) ->
    
    WriteInterval = ?DEFAULT_WRITE_INTERVAL*1000,
    erlang:send_after(WriteInterval, self(), {write_log}),
    {ok, []}.

%%
%% API Functions
%%
 

%% @spec get_log_status() -> string()
get_log_status()->
  
	ProcCount    = erlang:system_info(process_count),  
	ProcLimit    = erlang:system_info(process_limit),  
	PortsCount   = length( erlang:ports() ),
	
	ProcMemUsed  = erlang:memory(processes_used),  
	ProcMemAlloc = erlang:memory(processes),  
	MemTot       = erlang:memory(total),
	
	W_ProcMemUsed = get_printable_num(ProcMemUsed),
	W_ProcMemAlloc = get_printable_num(ProcMemAlloc),
	W_MemTot = get_printable_num(MemTot), 
	
	LogTime = mgeebgp_misc:time_format( erlang:localtime() ),
	Result = ["\n------------------------------------\n",LogTime,"\t"
			"system info: ",
			concat(["\n\tPort count:     "  ,PortsCount]),
			concat(["\tProcess count:    "  ,ProcCount]),
			concat(["\tProcess limit:    "  ,ProcLimit]),
			concat(["\tMemory used:    "  ,W_ProcMemUsed]),
			concat(["\tMemory allocated: "  ,W_ProcMemAlloc]),
			concat(["\tMemory total: "  ,W_MemTot]),"\n" ],
	erlang:list_to_binary( concat(Result) ).

-define(BGP_DICT_KEY(H,P),{bgpdest,H,P}).

%% @spec get_log_connections() -> string()
get_log_connections()->
    List = ets:tab2list(?ETS_BGP_CONNS),
    LogTime = mgeebgp_misc:time_format( erlang:localtime() ),
    Count = erlang:length(List),
    
    lists:foreach(fun(E)->
                          {_,_,{DestHost,DestPort},_} = E,
                          Key = ?BGP_DICT_KEY(DestHost,DestPort),
                          erlang:put(Key, caculateSum(Key))
                  end, List),
    
    StatList = lists:foldl(fun(E,AccIn)-> 
                                   case E of
                                       {?BGP_DICT_KEY(Host,Port)=K,V}->
                                           erlang:erase(K),
                                           concat(["\tserver: ",Host,"[",Port,"],count: ",V,"\n",AccIn]);
                                       _ ->
                                           AccIn
                                   end
                           end, [], erlang:get()),
    erlang:list_to_binary( concat([LogTime,"\tall connections: ",Count,"\n",StatList]) ).
 
%%
%% Local Functions
%%

caculateSum(Key)->
	case erlang:get(Key) of
		undefined -> 1;
		Val -> Val+1
	end.

write_log(MonitorLogConf)->
    #monitor_log_conf{dir=LogDir, suffix=Suffix} = MonitorLogConf,
    
    case createLogDir(LogDir) of
        ok ->
            case mgeebgp_monitor:should_monitor() of
                true->
                    LogFileName = getLogFileName(LogDir,Suffix),
                    
                    Log1 = get_log_status(),
                    Log2 = get_log_connections(),
                    lists:foreach(fun(LogData)->
                                          case file:write_file(LogFileName, LogData, [append]) of
                                              ok -> ok;
                                              {error,Reason} ->
                                                  ?WARNING_MSG("write the log data for the bgp monitor is fail, ~p\n",[Reason]),
                                                  ignore
                                          end
                                  end, [Log1,Log2]);
                _ ->
                    ignore
            end;
        Any ->
            ?ERROR_MSG("MGEE Application Monitor Log Directory error ~p\n ",[Any]),
            eror
    end.


concat(Things) when is_list(Things)->
    lists:concat(Things);
concat(OnThing)->
    lists:concat([OnThing]).

get_printable_num(NumValue)->
	if 
        is_number(NumValue) andalso NumValue>1024*1024 ->
            lists:concat([(NumValue div 1024 div 1024),"M"]);
        is_number(NumValue) andalso NumValue>1024 ->
            lists:concat([(NumValue div 1024),"K"]);
		true -> NumValue
	end.

%% @spec createLogDir(LogDir)-> bool()  
createLogDir(LogDir)->
	case filelib:is_dir(LogDir) of
		false ->
			file:make_dir(LogDir);
		true -> 
			ok
	end.

%% @spec getLogFileName(LogDir,Suffix)-> string()
%%	Return -> LogFileName
getLogFileName(LogDir,Suffix)->
    Now = erlang:now(),	
    FileName = mgeebgp_misc:date_format(Now),
    lists:concat([LogDir, "/bgp_monitor_", FileName, ".", Suffix]).

%% ====================================================================
%% Server functions
%% 		gen_server callbacks
%% ====================================================================

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info({write_log}, State) ->
    [MonitorLogConf] = common_config_dyn:find(bgp,monitor_log),
    try
        write_log(MonitorLogConf)
    catch
        _:Error->
            ?ERROR_MSG_STACK("write_log error",[Error])
    end,
    
    WriteInterval = MonitorLogConf#monitor_log_conf.frequency*1000,
    erlang:send_after(WriteInterval, self(), {write_log}),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
	