%%%-----------------------------------
%%% @Module  : sd_tcp_acceptor_sup
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.06.01
%%% @Description: tcp acceptor 监控树
%%%-----------------------------------
-module(sg_tcp_acceptor_sup).
-behaviour(supervisor).
-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local,?MODULE}, ?MODULE, []).

init([]) ->
    {ok, {{simple_one_for_one, 10, 10},
          [{sg_tcp_acceptor, {sg_tcp_acceptor, start_link, []},
            transient, brutal_kill, worker, [sg_tcp_acceptor]}]}}.
