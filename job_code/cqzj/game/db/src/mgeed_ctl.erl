%%%----------------------------------------------------------------------
%%%
%%% @copyright 2010 mgee (Ming Game Engine Erlang)
%%%
%%% @author odinxu, 2010-01-11
%%% @doc the mgee ctl module
%%% @end
%%%
%%%----------------------------------------------------------------------
-module(mgeed_ctl).
-author('odinxu@gmail.com').

-export([start/0,
	 init/0,
	 process/1,
         mnesia_update/2
	 ]).

-include("mgeed.hrl").
-include("mgeed_ctl.hrl").

-spec start() -> no_return(). 
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
	    Node = list_to_atom(SNode1),
            case erlang:length(Args) > 1 of
                true ->
                    [Command | Args2] = Args,
                    case Command of
                        %% 目前只能支持热更新的单独命令
                        "mnesia_update" ->
                            [Module ,Method] = Args2,
                            Status = case rpc:call(Node, ?MODULE, mnesia_update, [Module, Method]) of
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
                                     ?PRINT("RPC failed on the node ~p: ~p~n",
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

-spec init() -> 'ok'.
init() ->
    ets:new(mgeed_ctl_cmds, [named_table, set, public]),
    ets:new(mgeed_ctl_host_cmds, [named_table, set, public]),
    ok.


-spec process([string()]) -> integer().
process(["status"]) ->
    {InternalStatus, ProvidedStatus} = init:get_status(),
    ?PRINT("Node ~p is ~p. Status: ~p~n",
              [node(), InternalStatus, ProvidedStatus]),
    case lists:keysearch(mgeed, 1, application:which_applications()) of
        false ->
            ?PRINT("node is not running~n", []),
            ?STATUS_ERROR;
        {value,_Version} ->
            ?PRINT("node is running~n", []),
            ?STATUS_SUCCESS
    end;

process(["stop"]) ->
    init:stop(),
    ?STATUS_SUCCESS;

process(["restart"]) ->
    init:restart(),
    ?STATUS_SUCCESS;

process(["backup"]) ->
    {{Y, M, D}, {H, _, _}} = erlang:localtime(),
    [AgentName] = common_config_dyn:find(common, agent_name),
    [ServerName] = common_config_dyn:find(common, server_name),
    BackFileName = lists:concat([Y, M, D, ".", H]),
    File = lists:concat(["/data/database/backup/cqzj_", AgentName, "_", ServerName,"/", BackFileName]),
    ?ERROR_MSG("mnesia backup File=~w",[File]),
    ok = mnesia:backup(File),
    TarFileName = lists:concat([AgentName, "_", ServerName,"_",Y, M, D, ".", H]),
    os:cmd(lists:concat(["cd /data/database/backup/cqzj_", AgentName, "_", ServerName,"/; tar cfz ", TarFileName, ".tar.gz ", BackFileName, "; rm -f ", BackFileName])),
    ?STATUS_SUCCESS.


openUpdateMnesiaFile(AgentName,ServerName)->
    FileName = lists:concat(["/data/logs/",AgentName,"_",ServerName,"/update_mnesia.log"]),
    file:open(FileName, [write,raw, append]).

%% 升级数据库
mnesia_update(Module, UpdateFunc) ->
    ModuleName = common_tool:list_to_atom(Module),
    FuncName = common_tool:list_to_atom(UpdateFunc),
    common_reloader:reload_module(ModuleName),
    
    [AgentName] = common_config_dyn:find(common, agent_name),
    [ServerName] = common_config_dyn:find(common, server_name),
    {ok, UpdateMnFileDevice} = openUpdateMnesiaFile(AgentName,ServerName),
    
    {{Y, M, D}, {H, I, _}} = erlang:localtime(),
    {ok, ServerVersion} = file:read_file(lists:concat(["/data/cqzj_",AgentName,"_",ServerName,"/server/version_server.txt"])),
    
    MatainKey = {mnesia_db_version_prepare, ModuleName},
    case db:dirty_read(?DB_CONFIG_MATAIN, MatainKey) of
        [#r_config_matain{value=FuncName}]->
            Content = lists:concat([Y, "/", M, "/", D, "_", H, ":", I, " -- ", AgentName, "_", ServerName, " -- " ,ModuleName,":",FuncName, " ==== Updating\n", common_tool:to_list(ServerVersion) ]),
            file:write(UpdateMnFileDevice, Content),
            ?STATUS_MNESIA_UPDATING;
        _ ->
            case FuncName=:=update andalso not erlang:function_exported(ModuleName, FuncName, 0) of
                true->
                    %%调用 b_update_mnesia:update()
                    case mnesia:dirty_read(?DB_CONFIG_SYSTEM_P,{ModuleName,FuncName}) of
                        []-> 
                            mnesia_update_2(MatainKey,ModuleName,update,ServerVersion,UpdateMnFileDevice,true);
                        _ ->
                            mnesia_update_2(MatainKey,ModuleName,update_normal,ServerVersion,UpdateMnFileDevice,true)
                    end;
                false-> 
                    %%正常调用
                    mnesia_update_2(MatainKey,ModuleName,FuncName,ServerVersion,UpdateMnFileDevice,false)
            end 
    end.

mnesia_update_2(MatainKey,ModuleName,FuncName,ServerVersion,UpdateMnFileDevice,IsUsingBehavior)->
    [AgentName] = common_config_dyn:find(common, agent_name),
    [ServerName] = common_config_dyn:find(common, server_name),
    {{Y, M, D}, {H, I, _}} = erlang:localtime(),
    try
        ?ERROR_MSG("~w:~w [start]",[ModuleName,FuncName]),
        mnesia:dirty_write(?DB_CONFIG_MATAIN, #r_config_matain{key=MatainKey,value=FuncName}),
        case IsUsingBehavior of
            true->
                erlang:apply(b_update_mnesia, FuncName, [ModuleName]);
            _ ->
                erlang:apply(ModuleName, FuncName, [])
        end,
        mnesia:dirty_write(?DB_CONFIG_SYSTEM_P, {r_config_system, mnesia_db_version, ModuleName}),
        if 
            FuncName=:=update->
               mnesia:dirty_write(?DB_CONFIG_SYSTEM_P, {r_config_system, {ModuleName,FuncName}, {date(),time()}});
            true-> ignore
        end,
        mnesia:dirty_delete(?DB_CONFIG_MATAIN, MatainKey),
        Content = lists:concat([Y, "/", M, "/", D, "_", H, ":", I, " -- ", AgentName, "_", ServerName, " -- " ,ModuleName,":",FuncName, " ==== DONE\n", common_tool:to_list(ServerVersion) ]),
        file:write(UpdateMnFileDevice, Content),
        ?ERROR_MSG("~w:~w [end]",[ModuleName,FuncName]),
        ?STATUS_MNESIA_UPDATE_DONE
     catch 
        ErrType:ErrReason ->
                ?ERROR_MSG("mnesia_update Error=~w,Reason=~w,Stacktrace=~w", [ErrType,ErrReason,erlang:get_stacktrace()]), 
                mnesia:dirty_delete(?DB_CONFIG_MATAIN, MatainKey),                    
                File = lists:concat(["/data/logs/",AgentName,"_",ServerName,"/update_mnesia_", AgentName, "_", ServerName, "_", FuncName, "_", Y, M, D, ".", H, I]),
                ErrContent = io_lib:format("mnesia_update Error\n~p", [{ErrType, ErrReason, erlang:get_stacktrace()}]),
                file:write_file(File, list_to_binary(ErrContent)),
                ?STATUS_MNESIA_UPDATE_ERROR 
    end.

print_usage() ->
    CmdDescs =
	[{"status", "get node status"},
	 {"stop", "stop node"},
	 {"restart", "restart node"}
	 ] ++
	ets:tab2list(mgeed_ctl_cmds),
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
