%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  1 Jul 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(behavior).

%% API
-export([log/3]).

-include("mgeeb.hrl").

%%%===================================================================
%%% API
%%%===================================================================

log(Module, Method, DataRecord) ->
    %%检查行为日志缓存进程是否启动了
    case erlang:whereis(behavior_cache_server) of
        undefined ->
            %%根据是否开启behavior来决定日志的类型
            ?ERROR_MSG("~ts", ["行为日志缓存服务没有启动:behavior_cache_server"]);
        _ ->
            case catch encode(Module, Method, DataRecord) of
                {'EXIT', Error} ->
                    ?ERROR_MSG("~ts:~w, ~w, ~w -> ~w", ["编码日志结构体出错", Module, Method, DataRecord, Error]);
                DataBinary ->
                    behavior_cache_server ! {behavior, {Module, Method, DataBinary}}
            end        
    end.


encode(Module, Method, DataRecord) ->
    EncodeFunc =
        common_tool:list_to_atom(
          lists:concat(["encode_b_", 
                        erlang:binary_to_list(Module), 
                        "_", 
                        erlang:binary_to_list(Method), 
                        "_tos"])
         ),

    apply(behavior_pb, EncodeFunc, [DataRecord]).

