%% 该模块使用了ttb来进行在分布式环境下跟踪函数调用的情况，
%% 包括何时调用了哪个模块的哪个函数，以及何时哪个模块的哪个函数又返回了啥
%% 使用方法：
%%		1.调用start/0方法，启动该模块
%%		2.调用trc函数来确定你要跟踪哪些模块，或是哪些模块的哪些函数
%%		3.调用stop/0方法，将使日志信息写入文件<Node>-debug_log，该文件会位于项目的ebin目录
%%		4.调用format/1,2来在终端或是文件中显示日志文件中的log信息



-module(mydebug).
-export([start/0,trc/1,stop/0,format/1, format/2]).
-export([print/4]).
%% Include ms_transform.hrl so that I can use dbg:fun2ms/2 to
%% generate match specifications.
-include_lib("stdlib/include/ms_transform.hrl").

-define(TAB_SPACE, 6).

%%% -------------Tool API-------------
%%% ----------------------------------
%%% Star the "mydebug" tool
start() ->
    %% The options specify that the binary log shall be named
    %% <Node>-debug_log and that the print/4 function in this
    %% module shall be used as format handler  
	%% 跟踪所有的节点，生成的日志将命名为<Node>-debug_log，
	%%　并且将利用本模块中的print/4函数来作为日志的处理函数
    ttb:tracer(all,[{file,"debug_log"},{handler,{{?MODULE,print},0}}]),
    %% All processes (existing and new) shall trace function calls
    %% and include a timestamp in each trace message
	%% 为每一个跟踪消息添加捕获函数调用和调用的时间的信息
    ttb:p(all,[call,timestamp]).

%%% Set trace pattern on function(s)
trc(M) when is_atom(M) ->
    trc({M,'_','_'});
trc({M,F}) when is_atom(M), is_atom(F) ->
    trc({M,F,'_'});
trc({M,F,_A}=MFA) when is_atom(M), is_atom(F) ->
    %% This match spec specifies that return values shall 
    %% be traced. NOTE that ms_transform.hrl must be included
    %% if dbg:fun2ms/1 shall be used!
    MatchSpec = dbg:fun2ms(fun(_) -> return_trace() end),
    ttb:tpl(MFA,MatchSpec).

%%% Format a binary trace log
%% 在终端中显示log
format(LogFile) ->
    ttb:format(LogFile).
%% 在文件中显示log，ToFile为要写入的文件名
format(LogFile, ToFile) ->
    ttb:format(LogFile, [{out, ToFile}]).

%%% Stop the "mydebug" tool
stop() ->
    ttb:stop().


%%% --------Internal functions--------
%%% ----------------------------------
%%% Format handler
print(_Out,end_of_trace,_TI,N) ->
    N;
print(Out,Trace,_TI,N) ->
    case do_print(Out,Trace,N) of
		call 		-> N + 1;
		return_from -> N - 1
	end.
do_print(Out,{trace_ts,P,call,{M,F,A},Ts},N) when Out == standard_io ->
	{{Year, Month, Day}, {Hour, Minute, Second}} = calendar:universal_time_to_local_time(calendar:now_to_datetime(Ts)),
    print_space(N * ?TAB_SPACE),
	io:format(Out, "~w: ~p-~p-~p ~p:~p:~p, ~w:~n", [N,Year, Month, Day,Hour, Minute, Second,P]),
	print_space(N * ?TAB_SPACE),
	io:format(Out, "Call:     ~w:~w/~w~n", [M, F, length(A)]),
	print_space(N * ?TAB_SPACE),
	io:format(Out, "Arguments:~p~n~n", [A]),
	call;
do_print(Out,{trace_ts,P,call,{M,F,A},Ts},N) ->
	{{Year, Month, Day}, {Hour, Minute, Second}} = calendar:universal_time_to_local_time(calendar:now_to_datetime(Ts)),
	io:format(Out, "~w: ~p-~p-~p ~p:~p:~p, ~w:~n", [N,Year, Month, Day,Hour, Minute, Second,P]),
	io:format(Out, "Call:     ~w:~w/~w~n", [M, F, length(A)]),
	io:format(Out, "Arguments:~p~n~n", [A]),
	call;

do_print(Out,{trace_ts,P,return_from,{M,F,A},R,Ts},N) when Out == standard_io ->
	{{Year, Month, Day}, {Hour, Minute, Second}} = calendar:universal_time_to_local_time(calendar:now_to_datetime(Ts)),
    print_space(N * ?TAB_SPACE),
	io:format(Out, "~w: ~p-~p-~p ~p:~p:~p, ~w:~n", [N,Year, Month, Day,Hour, Minute, Second,P]),
	print_space(N * ?TAB_SPACE),
	io:format(Out, "Return from:  ~w:~w/~w~n", [M, F, A]),
	print_space(N * ?TAB_SPACE),
	io:format(Out, "Return value: ~p~n~n", [R]),
	return_from;
do_print(Out,{trace_ts,P,return_from,{M,F,A},R,Ts},N) ->
	{{Year, Month, Day}, {Hour, Minute, Second}} = calendar:universal_time_to_local_time(calendar:now_to_datetime(Ts)),
	io:format(Out, "~w: ~p-~p-~p ~p:~p:~p, ~w:~n", [N,Year, Month, Day,Hour, Minute, Second,P]),
	io:format(Out, "Return from:  ~w:~w/~w~n", [M, F, A]),
	io:format(Out, "Return value: ~p~n~n", [R]),
	return_from.


print_space(Num) ->
	case Num > 0 of
		true -> 
			io:format(" "),
			print_space(Num - 1);
		false -> ok
	end.