%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     负责读取receiver的配置文件
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mgeerec_config).
-export([get_mysql_config/0]).

get_mysql_config() ->
    [Config]=common_config_dyn:find(receiver_server,mysql_config),
    Config.
    

