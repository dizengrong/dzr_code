%%%----------------------------------------------------------------------
%%%
%%% @copyright 2010 mcs (Ming Chao Server)
%%%
%%% @author odinxu, 2010-04-08
%%% @doc the mcs misc module
%%% @end
%%%
%%%----------------------------------------------------------------------

-module(mgeebgp_misc).

%%
%% Include files
%%
-include("common.hrl").

%%
%% Exported Functions
%%

-export([
         time_format/1,
         date_format/1,
         ip_to_binary/1,
         ip_list_to_binary/1
		]).
-export([manage_applications/6, start_applications/1, stop_applications/1]).
  

%%
%% API Functions
%%
time_format( {_MegaSecs, _Secs, _MicroSecs}=Now ) -> 
    time_format( calendar:now_to_local_time(Now) );
time_format( {{Y,M,D},{H,MM,S}} ) -> 
    lists:concat([Y, "-", zeroFill(M), "-", zeroFill(D), " ", 
                        zeroFill(H) , ":", zeroFill(MM), ":", zeroFill(S)]).

date_format(Now) ->
    {{Y,M,D},{_H,_MM,_S}} = calendar:now_to_local_time(Now),
    lists:concat([Y, "-", zeroFill(M), "-", zeroFill(D)]).

ip_to_binary(Ip) ->
    case Ip of 
        {A1,A2,A3,A4} -> 
            [ integer_to_list(A1), "." , integer_to_list(A2), "." , integer_to_list(A3), "." , integer_to_list(A4) ];
        _ -> 
            "-"
    end.

ip_list_to_binary(Data) ->
    case Data of
        []        -> "";
        undefined -> "-";
        {IP,_PORT} -> ip_to_binary(IP);
        _ when is_list(Data) -> 
            [H|T]=Data,
            [ip_list_to_binary(H), "," , ip_list_to_binary(T) ];
        _ -> "-"
    end. 

zeroFill(N) ->
    if N<10 -> lists:concat(["0",N]); true -> N end.

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




