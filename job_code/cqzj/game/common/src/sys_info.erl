%% Author: 
%% Created: 2012-3-15
%% Description: TODO: Add description to sys_info
-module(sys_info).

%%
%% Include files
%%
-include("common.hrl").

-compile(export_all).
%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%

%%获得节点里所有进程的消息队列
%%process_message_infos
message_infos() ->          
	{Year, Month, Day} = date(),
	{Hour, Minute, Second} = time(),
	File = lists:concat(["/data/logs/" , Year,"--" , Month, "--" ,Day ,"--" ,Hour,"--" , Minute, "--" ,Second, "--process_message_infos.log"]),
	{ok, Fd} = file:open(File, [write, raw, binary, append]), 
	Fun = fun(P,Pi) ->
				  {messages,Msg} = lists:keyfind(messages, 1, Pi),
				  {message_queue_len,MsgNum} = lists:keyfind(message_queue_len, 1, Pi),
				  {reductions, ReducationNumber} = lists:keyfind(reductions, 1, Pi),
				  case length(MsgNum) > 0 of
					  true ->
						  Name  = 
							  case lists:keyfind(registered_name, 1, Pi) of
								  {registered_name, Atom} ->
									  Atom;
								  false ->
									  P;
								  _ ->
									  P
							  end,				  
						  Info = io_lib:format("~p=~p=>reductions==~p,message_queue_len==~p,messages==~p \n\n",[P,Name,ReducationNumber,MsgNum,Msg]),
						  case  filelib:is_file(File) of
							  true   ->   file:write(Fd, Info);
							  false  ->
								  file:close(Fd),
								  {ok, NewFd} = file:open(File, [write, raw, binary, append]),
								  file:write(NewFd, Info)
						  end;
					  false ->
						  ignore
				  end,
				  timer:sleep(20)
		  end,
	[   Fun(P,erlang:process_info(P)) ||   P <- erlang:processes()]. 

%%获取进程的信息
process_infos(Pids) ->          
	{Year, Month, Day} = date(),
	{Hour, Minute, Second} = time(),
	File = lists:concat(["/data/logs/" , Year,"--" , Month, "--" ,Day ,"--" ,Hour,"--" , Minute, "--" ,Second, "--processes_infos.log"]),
    {ok, Fd} = file:open(File, [write, raw, binary, append]), 
    Fun = fun(Pi) ->
                   Info = io_lib:format("=>~p \n\n",[Pi]),
                  case  filelib:is_file(File) of
                        true   ->   file:write(Fd, Info);
                        false  ->
                            file:close(Fd),
                            {ok, NewFd} = file:open(File, [write, raw, binary, append]),
                            file:write(NewFd, Info)
                     end,
                     timer:sleep(20)
                 end,
    [   Fun(erlang:process_info(P)) ||   P <- Pids]. 


%%---------------
%% 关于fprof
%%---------------

%% @doc fprof开始
-define(FPROF_TRACE_FILE, "/data/logs/fprof.log").
fprof_start() ->
    fprof_start(self()).

%% @doc fprof指定的进程:
%% all | existing | new | pid()
fprof_start(Procs) ->
    fprof:trace([start, {file, ?FPROF_TRACE_FILE}, {procs, Procs}]).

%% @doc fprof完成
fprof_stop() ->
    ok = fprof:trace(stop),
    ok = fprof:profile({file, ?FPROF_TRACE_FILE}),
    Analyse = lists:concat(["/data/logs/analyse/fprof-", date_str(),".log"]),
    % {sort, own}
    %ok = fprof:analyse([{dest, Analyse}, {details, true}, {totals, true}, {sort, own}]),
    ok = fprof:analyse([{dest, Analyse}, {details, true}, {totals, true}, {sort, own}]),
    io:format("fprof分析完成，结果:~s\n", [Analyse]),
    ok.

%% 获取时间戳
date_str() ->
    date_str(erlang:localtime()).
date_str({{Year, Month, Day}, {Hour, Minute, _Second}}) ->
    lists:flatten(
        io_lib:format("~4..0B~2..0B~2..0B-~2..0B~2..0B",
                    [Year, Month, Day, Hour, Minute])).

fprof() ->
	spawn(fun() -> fprof_start(all), timer:sleep(10000), fprof_stop() end).
fprof(Pid,Time) ->
	spawn(fun() -> fprof_start(Pid), timer:sleep(Time*1000), fprof_stop() end).

%%
%% Local Functions
%%

