%%%-------------------------------------------------------------------
%%% @author Liangliang <Liangliang@gmail.com>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  9 Jun 2010 by Liangliang <Liangliang@gmail.com>
%%%-------------------------------------------------------------------
-module(common_db).

-export([
         join_group/0,
         leave_group/0,
         status/0
        ]).

status() ->
    [{nodes, mnesia:system_info(db_nodes)},
     {running_nodes, mnesia:system_info(running_db_nodes)}].


%%加入mnesia集群
join_group() ->
%%     DbNodeName = common_config:get_db_node_name(),
%% 
%%     %%首先要保证能够ping通mnesia主节点
%%     pong = net_adm:ping(DbNodeName),
%%     %%先停止mnesia，删除本地的mnesia数据（从设计上，本地不允许有任何持久化数据），启动mnesia
%%     case mnesia:system_info(is_running) of
%%         yes ->
%%             ignore;
%%         _ ->
%%             mnesia:stop(),
%%             mnesia:delete_schema([node()]),
%%             mnesia:start()
%%     end,
%%     mnesia:change_config(extra_db_nodes, [DbNodeName]),
    ok.
    

%%退出mnesia集群
leave_group() ->
    ok = gen_server:call({global, db_group}, {leave, node()}).
