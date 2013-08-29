%%%----------------------------------------------------------------------
%%%
%%% @copyright 2010 mgee (Ming Game Engine Erlang)
%%%
%%% @author odinxu, 2010-01-11
%%% @doc the mgee ctl module
%%% @end
%%%
%%%----------------------------------------------------------------------
-module(manager_ctl).
-author('odinxu@gmail.com').

-export([start/0,
		 init/0,
		 process/1,
		 hot_update/1,
		 reload_config/1,
		 func/1
		]).

-include("manager_ctl.hrl").
-include("manager.hrl").


start() ->
    case init:get_plain_arguments() of
	[SNode | Args]->
	    %io:format("plain arguments is:~n~p", [AArgs]),
	    SNode1 = case string:tokens(SNode, "@") of
		[_Node, _Server] ->
		    SNode;
		_ ->
		    case net_kernel:longnames() of
			 true ->
			     SNode ++ "@" ++ inet_db:gethostname() ++
				      "." ++ inet_db:res_option(domain);
			 false ->
			     SNode ++ "@" ++ inet_db:gethostname();
			 _ ->
			     SNode
		     end
	    end,
	    Node = erlang:list_to_atom(SNode1),
            case erlang:length(Args) > 1 of
                true ->
                    [Command | Args2] = Args,
                    case Command of
                        %% 目前只能支持热更新的单独命令
                        "hot_update" ->
                            Status = case rpc:call(Node, ?MODULE, hot_update, [Args2]) of
                                         {badrpc, Reason} ->
                                             ?PRINT("RPC failed on the node ~w: ~w~n",
                                                    [Node, Reason]),
                                             ?STATUS_BADRPC;
                                         S ->
                                             S
                                     end;
                        "reload_config" ->
                            Status = case rpc:call(Node, ?MODULE, reload_config, [Args2]) of
                                         {badrpc, Reason} ->
                                             ?PRINT("RPC failed on the node ~w: ~w~n",
                                                    [Node, Reason]),
                                             ?STATUS_BADRPC;
                                         S ->
                                             S
                                     end;
                        "func" ->
                            Status = case rpc:call(Node, ?MODULE, func, [Args2]) of
                                         {badrpc, Reason} ->
                                             ?PRINT("RPC failed on the node ~w: ~w~n",
                                                    [Node, Reason]),
                                             ?STATUS_BADRPC;
                                         S ->
                                             S
                                     end;
                        "func_all" ->
                            Status = case rpc:call(Node, ?MODULE, func_all, [Args2]) of
                                         {badrpc, Reason} ->
                                             ?PRINT("RPC failed on the node ~w: ~w~n",
                                                    [Node, Reason]),
                                             ?STATUS_BADRPC;
                                         S ->
                                             S
                                     end;
                        _ ->
                            ?PRINT("RPC failed on the node ~w: ~s~n",
                                                    [Node, "not support"]),
                            Status = ?STATUS_BADRPC
                    end;
                false ->
                    Status = case rpc:call(Node, ?MODULE, process, [Args]) of
                                 {badrpc, Reason} ->
                                     ?PRINT("RPC failed on the node ~w: ~w~n",
                                            [Node, Reason]),
                                     ?STATUS_BADRPC;
                                 S ->
                                     S
                             end
            end,
	    halt(Status);
	_ ->
	    print_usage(),
	    halt(?STATUS_USAGE)
    end.

init() ->
    ets:new(manager_ctl_cmds, [named_table, set, public]),
    ets:new(manager_ctl_host_cmds, [named_table, set, public]),
    ok.

process(["status"]) ->
    {InternalStatus, ProvidedStatus} = init:get_status(),
    ?PRINT("Node ~w is ~w. Status: ~w~n",
              [node(), InternalStatus, ProvidedStatus]),
    case lists:keysearch(manager, 1, application:which_applications()) of
        false ->
            ?PRINT("node is not running~n", []),
            ?STATUS_ERROR;
        {value,_Version} ->
            ?PRINT("node is running~n", []),
            ?STATUS_SUCCESS
    end;

process(["stop"]) ->
	mgeeg:stop(),
	wait_for_stop(),	
    init:stop(),
    ?STATUS_SUCCESS;

process(["stop_app"]) ->
    manager_clear:stop(),
    ?STATUS_SUCCESS;

process(["restart"]) ->
    init:restart(),
    ?STATUS_SUCCESS.

hot_update(ModuleList) ->
    lists:foreach(
      fun(Module) ->
              common_reloader:reload_module(erlang:list_to_atom(Module))
      end, ModuleList),
    ?STATUS_SUCCESS.

reload_config([ConfigFile]) ->
    common_reloader:reload_config(erlang:list_to_atom(ConfigFile)),
    ?STATUS_SUCCESS.

func([Module, Method | Args]) ->
    Module2 = common_tool:list_to_atom(Module),
    Method2 = common_tool:list_to_atom(Method),
    ?ERROR_MSG("~ts:~s ~s", ["准备执行外部方法", Module2, Method2]),
    try
        erlang:apply(Module2, Method2, []),
        ?ERROR_MSG("~ts:~s ~s", ["执行外部方法完成", Module2, Method2]),
        ?STATUS_SUCCESS
    catch E:E2 ->
            ?ERROR_MSG("~ts:~w ~w, args:~w", ["执行外部函数报错", E, E2, Args]),
            ?STATUS_ERROR
    end.

print_usage() ->
    CmdDescs =
	[{"status", "get node status"},
	 {"stop", "stop node"},
	 {"restart", "restart node"}
	 ] ++
	ets:tab2list(manager_ctl_cmds),
    MaxCmdLen =
	lists:max(lists:map(
		    fun({Cmd, _Desc}) ->
			    length(Cmd)
		    end, CmdDescs)),
    NewLine = io_lib:format("~n", []),
    FmtCmdDescs =
	lists:map(
	  fun({Cmd, Desc}) ->
		  ["  ", Cmd, string:chars($\s, MaxCmdLen - length(Cmd) + 2),
		   Desc, NewLine]
	  end, CmdDescs),
    ?PRINT(
      "Usage: managerctl [--node nodename] command [options]~n"
      "~n"
      "Available commands in this node node:~n"
      ++ FmtCmdDescs ++
      "~n"
      "Examples:~n"
      "  mgeectl restart~n"
      "  mgeectl --node node@host restart~n"
      "  mgeectl vhost www.example.org ...~n",
     []).

%%do_hot_update(_ModuleList) ->
%%    ok.

wait_for_stop() ->
	case catch supervisor:which_children(mgeer_sup) of
		L when is_list(L), L =/= []  ->
			timer:sleep(3000),
			wait_for_stop();
		_ -> 
			ok
	end.
