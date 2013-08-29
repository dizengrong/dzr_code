%%%----------------------------------------------------------------------
%%%
%%% @copyright 2010 mgee (Ming Game Engine Erlang)
%%%
%%% @author odinxu, 2010-01-11
%%% @doc the mgee ctl module
%%% @end
%%%
%%%----------------------------------------------------------------------
-module(mgeeg_ctl).
-author('odinxu@gmail.com').

-export([start/0,
	 init/0,
	 process/1
	 ]).

-include("mgeeg_ctl.hrl").

-spec start() -> no_return(). 
start() ->
    case init:get_plain_arguments() of
	[SNode | Args]->
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
	    Node = list_to_atom(SNode1),
	    Status = case rpc:call(Node, ?MODULE, process, [Args]) of
			 {badrpc, Reason} ->
			     ?PRINT("~ts ~w: ~w~n",
				       ["RPC调用失败", Node, Reason]),
			     ?STATUS_BADRPC;
			 S ->
			     S
		     end,
	    halt(Status);
	_ ->
	    print_usage(),
	    halt(?STATUS_USAGE)
    end.

-spec init() -> 'ok'.
init() ->
    ets:new(mgeeg_ctl_cmds, [named_table, set, public]),
    ets:new(mgeeg_ctl_host_cmds, [named_table, set, public]),
    ok.


-spec process([string()]) -> integer().
process(["status"]) ->
    {InternalStatus, ProvidedStatus} = init:get_status(),
    ?PRINT("Node ~w is ~w. Status: ~w~n",
              [node(), InternalStatus, ProvidedStatus]),
    io:format("~w~n", [application:which_applications()]),
    case lists:keysearch(mgeeg, 1, application:which_applications()) of
        false ->
            ?PRINT("node is not running~n", []),
            ?STATUS_ERROR;
        {value,_Version} ->
            ?PRINT("node is running~n", []),
            ?STATUS_SUCCESS
    end;

process(["stop"]) ->
    %%先保证所有玩家的进程都已经退出
    catch gen_server:call(mgeeg_role_sock_map, shutdown, infinity),
    init:stop(),
    ?STATUS_SUCCESS;

process(["stop_all"]) ->
    common_reloader:stop_all_line(),
    ?STATUS_SUCCESS;

process(["restart"]) ->
     %%先保证所有玩家的进程都已经退出
    catch gen_server:call(mgeeg_role_sock_map, shutdown, infinity),
    init:restart(),
    ?STATUS_SUCCESS.


print_usage() ->
    CmdDescs =
	[{"status", "get node status"},
	 {"stop", "stop node"},
	 {"restart", "restart node"}
	 ] ++
	ets:tab2list(mgeeg_ctl_cmds),
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
      "Usage: mgeectl [--node nodename] command [options]~n"
      "~n"
      "Available commands in this node node:~n"
      ++ FmtCmdDescs ++
      "~n"
      "Examples:~n"
      "  mgeectl restart~n"
      "  mgeectl --node node@host restart~n"
      "  mgeectl vhost www.example.org ...~n",
     []).
