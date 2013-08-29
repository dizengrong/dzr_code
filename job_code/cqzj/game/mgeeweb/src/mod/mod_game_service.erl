%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 20 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(mod_game_service).

-include("common.hrl").

%% API
-export([
         get_baseinfo/0,
         get_nodes/0
        ]).

get_baseinfo() ->
    AccountNumber = rpc:call(erlang:hd(mnesia:table_info(db_account, ram_copies)), mnesia, table_info, [db_account, size]),
    RoleNumber = rpc:call(erlang:hd(mnesia:table_info(db_role_base, ram_copies)), mnesia, table_info, [db_role_base, size]),
    timer:sleep(300),
    RoleNumOfHongwu = erlang:length(mnesia:dirty_match_object(?DB_ROLE_BASE, #p_role_base{faction_id=1, _='_'})),
    RoleNumOfYongle = erlang:length(mnesia:dirty_match_object(?DB_ROLE_BASE, #p_role_base{faction_id=2, _='_'})),
    RoleNumOfWanli = erlang:length(mnesia:dirty_match_object(?DB_ROLE_BASE, #p_role_base{faction_id=3, _='_'})),
    {MaxOnline, QueueOnline, Online} = gen_server:call({global, mgeel_account_server}, get_online_info),
    Rtn = [{account_number, AccountNumber}, {role_number, RoleNumber}, 
           {role_num_of_hongwu, RoleNumOfHongwu}, 
           {role_num_of_yongle, RoleNumOfYongle},
           {role_num_of_wanli, RoleNumOfWanli},
           {max_online, MaxOnline},
           {queue_online, QueueOnline},
           {online, Online}
           ],
    Rtn.


%%获取当前运行的所有结点
get_nodes() ->
    Node = nodes(),
    case erlang:length(Node) of
        0 ->
            [];
        Len ->
            lists:foldl(
              fun(Index, Acc) ->                     
                      [{common_tool:to_list(Index),lists:nth(Index, Node)} | Acc]
              end, [], lists:seq(1, Len))
    end.

