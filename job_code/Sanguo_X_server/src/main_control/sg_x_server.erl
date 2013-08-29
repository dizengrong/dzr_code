-module(sg_x_server).

-export([stop/0, start/0, info/0]).

-include("common.hrl").

-define(SERVER_APPS,[sasl,server]).

%% start game server
start() ->
    try
		start_applications(?SERVER_APPS) of
	ok->ok
    catch 
	E:T->
	?ERR(init,"crash because ~w, ~w",[E,T])
    after
        timer:sleep(100)
    end.
 
%% stop game server
stop() ->
	?INFO(init,"===== stop sd ====="),
    ok = stop_applications(?SERVER_APPS),
    erlang:halt().

%% use this function to see runtime information
info() ->
    SchedId      = erlang:system_info(scheduler_id),
    SchedNum     = erlang:system_info(schedulers),
    ProcCount    = erlang:system_info(process_count),
    ProcLimit    = erlang:system_info(process_limit),
    ProcMemUsed  = erlang:memory(processes_used),
    ProcMemAlloc = erlang:memory(processes),
    MemTot       = erlang:memory(total),
    ?INFO(print, "runtime information:
                       ~n   Scheduler id:                         ~w
                       ~n   Num scheduler:                        ~w
                       ~n   Process count:                        ~w
                       ~n   Process limit:                        ~w
                       ~n   Memory used by erlang processes:      ~w
                       ~n   Memory allocated by erlang processes: ~w
                       ~n   The total amount of memory allocated: ~w
                       ",
                            [SchedId, SchedNum, ProcCount, ProcLimit,
                             ProcMemUsed, ProcMemAlloc, MemTot]),
      ok.

%%############ helper functions ##############
start_applications(Apps) ->
    manage_applications(fun lists:foldl/3,
                        fun application:start/1,
                        fun application:stop/1,
                        already_started,
                        cannot_start_application,
                        Apps).

stop_applications(Apps) ->
    manage_applications(fun lists:foldr/3,
                        fun application:stop/1,
                        fun application:start/1,
                        not_started,
                        cannot_stop_application,
                        Apps).


manage_applications(Iterate, Do, Undo, SkipError, ErrorTag, Apps) ->
    Iterate(fun (App, Acc) ->
                    case Do(App) of
                        ok -> [App | Acc];
                        {error, {SkipError, _}} -> Acc;
                        {error, Reason} ->
                            lists:foreach(Undo, Acc),
                            throw({error, {ErrorTag, App, Reason}})
                    end
            end, [], Apps),
    ok.
	