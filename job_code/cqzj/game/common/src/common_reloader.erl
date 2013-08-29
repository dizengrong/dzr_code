%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2011, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 23 Jan 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_reloader).

-include("common.hrl").
-define(ERROR_MSG(Format, Args),
        common_logger:error_msg( node(), ?MODULE,?LINE,Format, Args)).

%% API
-export([
         do_all_node/0,
         reload_all/0,
         reload_module/1,
         reload_config/1,
         get_map_master_node/0,
         reload_shop/0,
         reload_bag_shop/0
        ]).

get_map_master_node() ->
    [MasterMapHost] = common_config_dyn:find_common(master_host),
    common_tool:list_to_atom(lists:concat(["mgeem@", MasterMapHost])).

reload_shop() ->
	common_config_dyn:init(shop_shops),
	mod_shop:init().

reload_bag_shop() ->
	common_config_dyn:init(shop_shops),
	common_misc:send_to_map_mod(10260,mod_shop,force_reload_bag_shop).

reload_config(File) ->
	common_config_dyn:init(File),
	?ERROR_MSG("reload_config file:~w success",[File]).

reload_module(Module) ->
	c:l(Module),
	?ERROR_MSG("reload_module module:~w success",[Module]).

do_all_node() ->
	common_reloader:reload_all().

reload_all() ->
    lists:foreach(
      fun({Module, FileName}) ->
             case erlang:is_list(FileName) andalso Module =/= common_reloader of
                 true ->
                     code:soft_purge(Module),
                     code:load_file(Module);
                 false ->
                     ignore
             end
      end, code:all_loaded()).
