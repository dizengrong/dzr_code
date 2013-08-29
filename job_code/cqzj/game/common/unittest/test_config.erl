%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     test for config
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(test_config).

%%
%% Include files
%%
%%
%% Include files
%%
 
-define( INFO(F,D),io:format(F, D) ).
-compile(export_all).
-include("common.hrl").

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%


t_item()->
	ItemFile = common_config:get_world_config_file_path(item),
    {ok,_ItemList} = file:consult(ItemFile),

    ExtendBagFile = common_config:get_world_config_file_path(extend_bag),
    {ok, _ExtendList} = file:consult(ExtendBagFile),
	
    GiftFile = common_config:get_world_config_file_path(gift),
    {ok, _GiftList} = file:consult(GiftFile),
    BigHpMpFile = common_config:get_world_config_file_path(bighpmp),
    {ok, _BigHpMpList} = file:consult(BigHpMpFile),

    ItemCDFile = common_config:get_world_config_file_path(item_cd),

    {ok, [_ItemCD]} = file:consult(ItemCDFile),

    MoneyFile = common_config:get_map_config_file_path(money),
    {ok, _MoneyList} = file:consult(MoneyFile),
	
	ok.
