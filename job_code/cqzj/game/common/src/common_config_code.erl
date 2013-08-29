%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     common_config_code,用于动态生成代码
%%% @end
%%% Created : 2010-12-2
%%%-------------------------------------------------------------------
-module(common_config_code).


%% API
-export([gen_src/4]). 

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl").
-include("common_server.hrl").

%% ====================================================================
%% API Functions
%% ====================================================================

%%@spec gen_src/2
%%@param    ConfModuleName::string()
%%@param    KeyValues::list(),  [{Par,Val}]
gen_src(ConfModuleName,Type,KeyValues,ValList) ->
    KeyValues2 =
        if Type =:= bag ->
                lists:foldl(fun({K, V}, Acc) ->
                                    case lists:keyfind(K, 1, Acc) of
                                        false ->
                                            [{K, [V]}|Acc];
                                        {K, VO} ->
                                            [{K, [V|VO]}|lists:keydelete(K, 1, Acc)]
                                    end
                            end, [], KeyValues);
           true ->
                KeyValues
        end,
    Cases = lists:foldl(fun({Key, Value}, C) ->
                                lists:concat([C,lists:flatten(io_lib:format("     ~w -> ~w;\n", [Key, Value]))])
                        end,
                        "",
                        KeyValues2),
    StrList = lists:flatten(io_lib:format("     ~w\n", [ValList])),
    
"
-module(" ++ common_tool:to_list(ConfModuleName) ++ ").
-export([list/0,find_by_key/1]).

list()->"++ StrList ++".

find_by_key(Key) ->
    case Key of 
" ++ Cases ++ "
        _ -> undefined
    end.
".

