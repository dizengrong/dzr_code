%%%----------------------------------------------------------------------
%%% File    : mgeerec_logger_h.erl
%%% Author  : Liangliang
%%% Purpose : Manage Erlang logging.
%%% Created : 2010-01-01
%%% Description: Ming game engine erlang
%%%----------------------------------------------------------------------

-module(mgeerec_logger_h).

-behaviour(gen_event).

%% gen_event callbacks
-export([init/1, handle_event/2, handle_call/2, handle_info/2, terminate/2,
	 code_change/3, reopen_log/0, rotate_log/1]).

-record(state, {fd, file}).

%%----------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok, State}          |
%%          Other
%%----------------------------------------------------------------------
init(File) ->
    case file:open(File, [append, binary]) of
	{ok, Fd} ->
	    {ok, #state{fd = Fd, file = File}};
	Error ->
	    Error
    end.

%%----------------------------------------------------------------------
%% Func: handle_event/2
%% Returns: {ok, State}                                |
%%          {swap_handler, Args1, State1, Mod2, Args2} |
%%          remove_handler                              
%%----------------------------------------------------------------------
handle_event(Event, State) ->
    write_event(State#state.fd, {erlang:localtime(), Event}),
    {ok, State}.

%%----------------------------------------------------------------------
%% Func: handle_call/2
%% Returns: {ok, Reply, State}                                |
%%          {swap_handler, Reply, Args1, State1, Mod2, Args2} |
%%          {remove_handler, Reply}                            
%%----------------------------------------------------------------------
handle_call(_Request, State) ->
    Reply = ok,
    {ok, Reply, State}.

%%----------------------------------------------------------------------
%% Func: handle_info/2
%% Returns: {ok, State}                                |
%%          {swap_handler, Args1, State1, Mod2, Args2} |
%%          remove_handler                              
%%----------------------------------------------------------------------
handle_info({'EXIT', _Fd, _Reason}, _State) ->
    remove_handler;
handle_info({emulator, _GL, reopen}, State) ->
    file:close(State#state.fd),
    rotate_log(State#state.file),
    case file:open(State#state.file, [append, raw]) of
	{ok, Fd} ->
	    {ok, State#state{fd = Fd}};
	Error ->
	    Error
    end;
handle_info({emulator, GL, Chars}, State) ->
    write_event(State#state.fd, {erlang:localtime(), {emulator, GL, Chars}}),
    {ok, State};
handle_info(_Info, State) ->
    {ok, State}.

%%----------------------------------------------------------------------
%% Func: terminate/2
%% Purpose: Shutdown the server
%% Returns: any
%%----------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

reopen_log() ->
    error_logger ! {emulator, noproc, reopen}.

%%%----------------------------------------------------------------------
%%% Internal functions
%%%----------------------------------------------------------------------

% Copied from erlang_logger_file_h.erl
write_event(Fd, {Time, {error, _GL, {_Pid, Format, Args}}}) ->
    {{Y,Mo,D},{H,Mi,S}} = Time, 
    [L] = io_lib:format("~ts", ["错误报告"]),
    LBin = erlang:iolist_to_binary(L),
    InfoMsg = unicode:characters_to_list(LBin),
    Time2 = io_lib:format("==== ~w-~.2.0w-~.2.0w ~.2.0w:~.2.0w:~.2.0w ===",
		  [Y, Mo, D, H, Mi, S]),
    L2 = lists:concat([InfoMsg, Time2]),
    B = unicode:characters_to_binary(L2),
    file:write(Fd, B),
    M = io_lib:format(Format, Args),
    lists:foreach(
      fun(MS) ->
              case is_list(MS) of
                  true ->
                      TempBin = erlang:iolist_to_binary(MS),
                      FBin = unicode:characters_to_binary(TempBin),
                      file:write(Fd, FBin);
                  false ->
                      TempBin = erlang:iolist_to_binary([MS]),
                      FBin = unicode:characters_to_binary(TempBin),
                      file:write(Fd, FBin)
              end
      end, M);


write_event(Fd, {Time, {emulator, _GL, Chars}}) ->
    T = write_time(Time),
    case catch io_lib:format(Chars, []) of
	S when is_list(S) ->
	    file:write(Fd, to_unicode(io_lib:format(T ++ S, [])));
	_ ->
	    file:write(Fd, to_unicode(io_lib:format(T ++ "ERROR: ~p ~n", [Chars])))
    end;


write_event(Fd, {Time, {info, _GL, {Pid, Info, _}}}) ->
    T = write_time(Time),
    Rtn = file:write(Fd, to_unicode(io_lib:format(T ++ add_node("~p~n",Pid), [Info]))),
    io:format("~p", [Rtn]);


write_event(Fd, {Time, {error_report, _GL, {Pid, std_error, Rep}}}) ->
    T = write_time(Time),
    S = format_report(Rep),
    file:write(Fd, to_unicode(io_lib:format(T ++ S ++ add_node("", Pid), [])));


write_event(Fd, {Time, {info_report, _GL, {Pid, std_info, Rep}}}) ->
    T = write_time(Time, "INFO REPORT"),
    S = format_report(Rep),
    Rtn = file:write(Fd, to_unicode(io_lib:format(T ++ S ++ add_node("", Pid), []))),
    io:format("~p", [Rtn]);


write_event(Fd, {Time, {info_msg, _GL, {_Pid, Format, Args}}}) ->
    {{Y,Mo,D},{H,Mi,S}} = Time, 
    [L] = io_lib:format("~ts", ["信息报告"]),
    LBin = erlang:iolist_to_binary(L),
    InfoMsg = unicode:characters_to_list(LBin),
    Time2 = io_lib:format("==== ~w-~.2.0w-~.2.0w ~.2.0w:~.2.0w:~.2.0w ===",
		  [Y, Mo, D, H, Mi, S]),
    L2 = lists:concat([InfoMsg, Time2]),
    B = unicode:characters_to_binary(L2),
    file:write(Fd, B),
    M = io_lib:format(Format, Args),
    lists:foreach(
      fun(MS) ->
              case is_list(MS) of
                  true ->
                      TempBin = erlang:iolist_to_binary(MS),
                      FBin = unicode:characters_to_binary(TempBin),
                      file:write(Fd, FBin);
                  false ->
                      TempBin = erlang:iolist_to_binary([MS]),
                      FBin = unicode:characters_to_binary(TempBin),
                      file:write(Fd, FBin)
              end
      end, M);
                    

write_event(_, _) ->
    ok.

to_unicode(L) ->
    B = erlang:iolist_to_binary(L),
    io:format("~p~n", [B]),
    unicode:characters_to_binary(B).


format_report(Rep) when is_list(Rep) ->
    case string_p(Rep) of
	true ->
	    io_lib:format("~s~n",[Rep]);
	_ ->
	    format_rep(Rep)
    end;
format_report(Rep) ->
    io_lib:format("~p~n",[Rep]).

format_rep([{Tag,Data}|Rep]) ->
    io_lib:format("    ~p: ~p~n",[Tag,Data]) ++ format_rep(Rep);


format_rep([Other|Rep]) ->
    io_lib:format("    ~p~n",[Other]) ++ format_rep(Rep);


format_rep(_) ->
    [].

add_node(X, Pid) when node(Pid) /= node() ->
    lists:concat([X,"** at node ",node(Pid)," **~n"]);
add_node(X, _) ->
    X.

string_p([]) ->
    false;
string_p(Term) ->
    string_p1(Term).

string_p1([H|T]) when is_integer(H), H >= $\s, H < 255 ->
    string_p1(T);
string_p1([$\n|T]) -> string_p1(T);
string_p1([$\r|T]) -> string_p1(T);
string_p1([$\t|T]) -> string_p1(T);
string_p1([$\v|T]) -> string_p1(T);
string_p1([$\b|T]) -> string_p1(T);
string_p1([$\f|T]) -> string_p1(T);
string_p1([$\e|T]) -> string_p1(T);
string_p1([H|T]) when is_list(H) ->
    case string_p1(H) of
	true -> string_p1(T);
	_    -> false
    end;
string_p1([]) -> true;
string_p1(_) ->  false.

write_time(Time) -> write_time(Time, "ERROR REPORT").

write_time({{Y,Mo,D},{H,Mi,S}}, Type) ->
    io_lib:format("~n=~s==== ~w-~.2.0w-~.2.0w ~.2.0w:~.2.0w:~.2.0w ===",
		  [Type, Y, Mo, D, H, Mi, S]).

%% @doc Rename the log file if exists, to "*-old.log".
%% This is needed in systems when the file must be closed before rotation (Windows).
%% On most Unix-like system, the file can be renamed from the command line and
%% the log can directly be reopened.
%% @spec (Filename::string()) -> ok
rotate_log(Filename) ->
    case file:read_file_info(Filename) of
	{ok, _FileInfo} ->
	    RotationName = filename:rootname(Filename),
	    file:rename(Filename, [RotationName, "-old.log"]),
	    ok;
	{error, _Reason} ->
	    ok
    end.
	    
