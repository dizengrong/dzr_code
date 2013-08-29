%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 29 Mar 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(manager_node).

-include("manager.hrl").

%% API
-export([
         start_all/0
        ]).

%% 启动所有的其他节点，不包括manager自身和security节点
start_all() ->
    yes = global:register_name(manager_node, erlang:self()),
    case catch do_common_config_check() of
        ok ->
            [MasterHost] = common_config_dyn:find_common(master_host),
            AddressList = common_tool:get_all_bind_address(),
            case lists:member(MasterHost, AddressList) of
                true ->
                    ok;
                false ->
                    ?SYSTEM_LOG("~ts", ["Master Host配置错误，请检查IP地址是否正确"]),
                    timer:sleep(1000),
                    erlang:halt()
            end,
			inets:start(),
		    mgeeb:start(),
		    mgeed:start(),
		    mgeew:start(),
			mgeem:start(),
			mgeer:start(),
		    mgeeweb:start(),
		    mgeel:start(),
		    mgeec:start(),
			mgeeg:start(),
			common_monitor_agent:start_link(),
            common_monitor_agent:set_monitor_sys(true),
            common_monitor_agent:set_monitor_db(true),
            common_monitor_agent:set_monitor_map_msg(true),
			os_mon_tool:start(),
            ?SYSTEM_LOG("~ts~n", ["游戏启动成功"]),
			notify_app_start_complete(),
            ?SYSTEM_LOG("~ts ~n", ["按ctl-c退出"]),
            [AgentName] = common_config_dyn:find_common(agent_name),
            [ServerName] = common_config_dyn:find_common(server_name),
            CmdStr = lists:concat(["ps awux | grep 'tail -f /data/logs/",AgentName,"_",ServerName,"/cqzj_manager.log' | grep -v 'grep' | awk '{print $2}' | xargs kill -9"]),
            os:cmd(CmdStr),
            ok;
        {error, Error} ->
            ?SYSTEM_LOG("~ts:~w", ["读取common.config配置出错", Error]),
            error
    end.

do_common_config_check() ->
    case common_config_dyn:find_common(agent_id) of
        [_AgentId] ->
            ok;
        _ ->
            erlang:throw({error, "common.config缺少agent_id配置项"})
    end,
    case common_config_dyn:find_common(agent_name) of
        [_AgentName] ->
            ok;
        _ ->
            erlang:throw({error, "common.config缺少agent_name配置项"})
    end,
    case common_config_dyn:find_common(server_id) of
        [_ServerId] ->
            ok;
        _ ->
            erlang:throw({error, "common.config缺少server_id配置项"})
    end,
    case common_config_dyn:find_common(server_name) of
        [_ServerName] ->
            ok;
        _ ->
            erlang:throw({error, "common.config缺少server_name配置项"})
    end,
    
    case common_config_dyn:find_common(erlang_web_port) of
        [_ErlangWebPort] ->
            ok;
        _ ->
            erlang:throw({error, "common.config缺少erlang_web_port配置项"})
    end,
    case common_config_dyn:find_common(manager_port) of
        [_ManagerPort] ->
            ok;
        _ ->
            erlang:throw({error, "common.config缺少manager_port配置项"})
    end,
    case common_config_dyn:find(common, master_host) of
        [_MasterHost] ->
            ok;
        _ ->
            erlang:throw({error, "common.config缺少master_host配置项"})
    end,
    case common_config_dyn:find(common, gateway) of
        [] ->
            erlang:throw({error, "common.config缺少gateway配置"});
        _ ->
            ok
    end,
    case common_config_dyn:find(common, map) of
        [] ->
            erlang:throw({error, "common.config缺少map配置"});
        _ ->
            ok
    end,
    ok.

notify_app_start_complete() ->
    global:send(mgeew_activity_schedule, application_start_complete).

