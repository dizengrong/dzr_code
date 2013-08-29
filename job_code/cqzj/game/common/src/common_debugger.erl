%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc 调试开关模块
%%%
%%% @end
%%% Created : 30 Jun 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_debugger).

%% API
-export([
         dbg_start/1,
         eprof_start/0, 
         fprof_start/0,
         stop/0,
         start_concurrency_profile/0,
         stop_concurrency_profile/0,
         get_receiver_fun/0,
         spawn_trace/1,
         stop_trace/1,
         get_all_map_pid/0
        ]).

-export([pids/0]).

stop_trace(PID) ->
    erlang:trace(PID, false, [all]).

spawn_trace(PID) -> 
    [AgentName] = common_config_dyn:find_common(agent_name),
    [ServerName] = common_config_dyn:find_common(server_name),
    {{Year, Month, Day}, {H, I, _}} = erlang:localtime(),
    File = lists:concat(["/data/logs/",AgentName,"_",ServerName,"/tracer.", erlang:pid_to_list(PID), Year, Month, Day, H, I, ".log"]),
    io:format("begin trace to file:~p~n", [File]),
    erlang:trace(PID, true, [all]),    
    trace_to_file(File).

trace_to_file(File) ->
    receive 
        Any ->
            file:write_file(File, Any, [append])
    end,
    trace_to_file(File).

%% 获取一个尾递归无限接受消息的函数
get_receiver_fun() ->
    fun() -> do_receive() end.

do_receive() ->
    receive 
        Any -> io:format("~p~n", [Any])
    end,
    do_receive().
             
             

dbg_start(Module) ->
    dbg:tracer(),
    dbg:p(all, [call]),
    dbg:tpl(Module, [{'_', [], [{return_trace}]}]).



eprof_start() ->
    eprof:start(),
    eprof:profile(pids()).

fprof_start() ->
    fprof:trace([start, {file, "/tmp/fprof"}, {procs, pids()}]).


stop() ->
    catch eprof:stop(),
    catch fprof:stop(),
    catch dbg:stop_clear(),
    ok.


start_concurrency_profile() ->
    {{Year, Month, Day}, {Hour, Min, Sec}} = erlang:localtime(),
    [AgentName] = common_config_dyn:find_common(agent_name),
    [ServerName] = common_config_dyn:find_common(server_name),
    File = io_lib:format("/data/logs/~s_~s/cqzj_concurrency_~w~w~w_~w~w~w", [AgentName,ServerName,Year, Month, Day, Hour, Min, Sec]),
    percept:profile(File, [procs, ports, exclusive]).

stop_concurrency_profile() ->
    percept:stop_profile().


pids() ->
    lists:zf(
      fun(Pid) ->
	      case process_info(Pid) of
		  ProcessInfo when is_list(ProcessInfo) ->
		      CurrentFunction = current_function(ProcessInfo),
		      InitialCall = initial_call(ProcessInfo),
		      RegisteredName = registered_name(ProcessInfo),
                      Ancestor = ancestor(ProcessInfo),
		      filter_pid(Pid, CurrentFunction, InitialCall, RegisteredName, Ancestor);
		  _ ->
		      false
	      end
      end,
      processes()).

current_function(ProcessInfo) ->
    {value, {_, {CurrentFunction, _,_}}} =
	lists:keysearch(current_function, 1, ProcessInfo),
    atom_to_list(CurrentFunction).

initial_call(ProcessInfo) ->
    {value, {_, {InitialCall, _,_}}} =
	lists:keysearch(initial_call, 1, ProcessInfo),
    atom_to_list(InitialCall).

registered_name(ProcessInfo) ->
    case lists:keysearch(registered_name, 1, ProcessInfo) of
	{value, {_, Name}} when is_atom(Name) -> atom_to_list(Name);
	_ -> ""
    end.

ancestor(ProcessInfo) ->
    {value, {_, Dictionary}} = lists:keysearch(dictionary, 1, ProcessInfo),
    case lists:keysearch('$ancestors', 1, Dictionary) of
	{value, {_, [Ancestor|_T]}} when is_atom(Ancestor) ->
	    atom_to_list(Ancestor);
	_ ->
	    ""
    end.

filter_pid(Pid, "mgeem" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, "mgeed" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, "mgeel" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, "mgeeg" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, "mgeew" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, "mgeec" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, "mgeeb" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, "mgeea" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, "common_" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, "mod_" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, "hook_" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, "mnesia" ++ _, _InitialCall, _RegisteredName, _Ancestor) ->
    {true, Pid};

filter_pid(Pid, _CurrentFunction, "mgeem" ++ _, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, "mgeea" ++ _, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, "mgeeb" ++ _, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, "mgeec" ++ _, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, "mgeed" ++ _, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, "mgeel" ++ _, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, "mgeew" ++ _, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, "mgeeg" ++ _, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, "common_" ++ _, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, "mod_" ++ _, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, "hook_" ++ _, _RegisteredName, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, "mnesia" ++ _, _RegisteredName, _Ancestor) ->
    {true, Pid};


filter_pid(Pid, _CurrentFunction, _InitialCall, "mgeem"++_, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, "mgeea"++_, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, "mgeeb"++_, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, "mgeec"++_, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, "mgeed"++_, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, "mgeel"++_, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, "mgeew"++_, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, "mgeeg"++_, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, "common_"++_, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, "mod_"++_, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, "hook_"++_, _Ancestor) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, "mnesia"++_, _Ancestor) ->
    {true, Pid};


filter_pid(Pid, _CurrentFunction, _InitialCall, _RegisteredName, "mgeem"++_) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, _RegisteredName, "mgeea"++_) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, _RegisteredName, "mgeeb"++_) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, _RegisteredName, "mgeec"++_) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, _RegisteredName, "mgeed"++_) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, _RegisteredName, "mgeel"++_) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, _RegisteredName, "mgeew"++_) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, _RegisteredName, "mgeeg"++_) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, _RegisteredName, "mod_"++_) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, _RegisteredName, "hook_"++_) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, _RegisteredName, "common_"++_) ->
    {true, Pid};
filter_pid(Pid, _CurrentFunction, _InitialCall, _RegisteredName, "mnesia"++_) ->
    {true, Pid};


filter_pid(_Pid, _CurrentFunction, _InitialCall, _RegisteredName, _Ancestor) ->
    false.

get_all_map_pid() ->
    lists:foldl(
      fun("mgee_map" ++ _ = Name, AL) -> 
              [Name|AL]; 
         ("map_" ++ _ = Name, AL) ->
              [Name|AL];
         ("mgee_mission_fb_map_" ++ _ = Name, AL) ->
              [Name, AL];
         (_, AL) -> 
              AL 
      end,[], global:registered_names()).

