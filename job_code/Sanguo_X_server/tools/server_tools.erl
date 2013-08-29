-module (server_tools).

-include_lib("kernel/include/file.hrl").

-compile(export_all).

-define(TMP_FILE, "/tmp/result_tmp_file").

stop_srv([ConfigFile]) ->
	{ok, Fd} = file:open(?TMP_FILE, [write]),
	{ServerNode, LogNode, Cookie} = get_nodes_info(atom_to_list(ConfigFile)),

	ThisNode = list_to_atom("stop_" ++ atom_to_list(ServerNode)),

	case net_kernel:start([ThisNode]) of
		{error, Reason} ->
			file:write(Fd, io_lib:format("Init node failed, reason: ~p~n", [Reason])),
			% io:format("Init node failed, reason: ~p", [Reason]),
			false;
		{ok, _Pid} ->
			erlang:set_cookie(ThisNode, Cookie),
			case net_adm:ping(ServerNode) of
				pang ->
					file:write(Fd, io_lib:format("ping server node: ~w failed!!!~n", [ServerNode]));
					% io:format("ping server node: ~w failed!!!~n", [ServerNode]);
				pong ->
					file:write(Fd, io_lib:format("ping server node: ~w success!!!~n", [ServerNode])),
					file:write(Fd, io_lib:format("~n*********** start stop server node: ~w ***********~n~n", [ServerNode])),
					% io:format("ping server node: ~w success!!!~n", [ServerNode]),
					% io:format("~n*********** start stop server node: ~w ***********~n~n", [ServerNode]),
					Result = rpc:call(ServerNode, main, stop, []),
					file:write(Fd, io_lib:format("~n*********** stop server node return: ~p ***********~n~n", [Result])),
					% io:format("~n*********** stop server node return: ~p ***********~n~n", [Result]),
					timer:sleep(1500)
			end,
			case net_adm:ping(LogNode) of
				pang ->
					file:write(Fd, io_lib:format("ping log node: ~w failed!!!~n", [LogNode]));
					% io:format("ping log node: ~w failed!!!~n", [LogNode]);
				pong ->
					file:write(Fd, io_lib:format("*********** start stop log node: ~w ***********~n", [LogNode])),
					% io:format("*********** start stop log node: ~w ***********~n", [LogNode]),
					rpc:call(LogNode, log, stop, []),
					timer:sleep(1500)
			end,
			true
	end,
	file:write(Fd, "=========== end of stop server ===========~n"),
	file:sync(Fd),
	file:close(Fd),
	init:stop().

srv_status([ConfigFile]) ->
	{ok, Fd} = file:open(?TMP_FILE, [write]),
	{ServerNode, LogNode, Cookie} = get_nodes_info(atom_to_list(ConfigFile)),

	ThisNode = list_to_atom("status_" ++ atom_to_list(ServerNode)),

	case net_kernel:start([ThisNode]) of
		{error, Reason} ->
			file:write(Fd, io_lib:format("Init node failed, reason: ~p~n", [Reason])),
			% io:format("Init node failed, reason: ~p", [Reason]),
			false;
		{ok, _Pid} ->
			erlang:set_cookie(ThisNode, Cookie),
			case net_adm:ping(ServerNode) of
				pong ->
					file:write(Fd, io_lib:format("server node: ~w is [alive]~n~n", [ServerNode]));
					% io:format("server node: ~w is [alive]~n~n", [ServerNode]);
				pang ->
					file:write(Fd, io_lib:format("server node: ~w is [die]~n~n", [ServerNode]))
					% io:format("server node: ~w is [die]~n~n", [ServerNode])
			end,
			case net_adm:ping(LogNode) of
				pong ->
					file:write(Fd, io_lib:format("log node: ~w is [alive]~n~n", [LogNode]));
					% io:format("log node: ~w is [alive]~n~n", [LogNode]);
				pang ->
					file:write(Fd, io_lib:format("log node: ~w is [die]~n~n", [LogNode]))
					% io:format("log node: ~w is [die]~n~n", [LogNode])
			end
	end,
	file:write(Fd, "=========== end of get servre status ===========~n"),
	file:sync(Fd),
	file:close(Fd),
	init:stop().

hot_reload([ConfigFile]) ->
	{ok, #file_info{mtime = LastTime}} = file:read_file_info("temp"),

	% {ok, Fd} = file:open(?TMP_FILE, [write]),
	{ServerNode, _LogNode, Cookie} = get_nodes_info(atom_to_list(ConfigFile)),

	ThisNode = list_to_atom("reload_" ++ atom_to_list(ServerNode)),

	case net_kernel:start([ThisNode]) of
		{error, Reason} ->
			% file:write(Fd, io_lib:format("Init node failed, reason: ~p", [Reason])),
			io:format("Init node failed, reason: ~p", [Reason]),
			false;
		{ok, _Pid} ->
			erlang:set_cookie(ThisNode, Cookie),
			case net_adm:ping(ServerNode) of
				pong ->
					%% do reload
					ALLCode = rpc:call(ServerNode, code, all_loaded, []),
					[do_reload(ServerNode, Module, Filename, LastTime) || 
					 {Module, Filename} <- ALLCode, is_list(Filename)];
				pang ->
					% file:write(Fd, io_lib:format("server node: ~w is [die]~n~n", [ServerNode]))
					io:format("server node: ~w is [die]~n~n", [ServerNode])
			end
	end,
	% file:write(Fd, "=========== end of hot reload ===========~n"),
	% file:sync(Fd),
	% file:close(Fd),
	init:stop().

do_reload(_ServerNode, dragon_logger, _Filename, _LastTime) -> ok;
do_reload(ServerNode, Module, Filename, LastTime) ->
	case file:read_file_info(Filename) of
		{ok, #file_info{mtime = Mtime}} when Mtime > LastTime ->
			rpc:call(ServerNode, code, purge, [Module]), 
			rpc:call(ServerNode, code, load_file, [Module]),
			% file:write(Fd, io_lib:format("reloading: [~w]~n", [Module]));
			io:format("reloading: [~w]~n", [Module]);
		{error, enoent} ->
			% file:write(Fd, io_lib:format("~s has compile error???~n", [Filename]));
        	io:format("~s has compile error???Module = ~p~n", [Filename, Module]);
		{error, Reason} ->	
			% file:write(Fd, io_lib:format("Error reading ~s's file info: ~p~n", [Filename, Reason]));
            io:format("Error reading ~s's file info: ~p~n", [Filename, Reason]);
        _ ->
        	not_reload
    end.

get_nodes_info(ConfigFile) -> 
	{ok, [Terms]} = file:consult(ConfigFile),
	{server, KeyValueList} = lists:keyfind(server, 1, Terms),
	{node_name, ServerNode} = lists:keyfind(node_name, 1, KeyValueList),
	{log_node, LogNode} = lists:keyfind(log_node, 1, KeyValueList),
	{node_cookie, Cookie} = lists:keyfind(node_cookie, 1, KeyValueList),
	{ServerNode, LogNode, Cookie}.


