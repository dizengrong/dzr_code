%% Author: 刘哲
%% Created: 2012-9-14
%% mod_temp_bag:push(4000330,{1,1,1,1}).
%% mod_temp_bag:pop(669,1).
%% Description: 临时背包模块，只能零存整取。。。
-module(mod_temp_bag).
-behaviour(gen_server).
%%
%% Include files
%%
-include("common.hrl").
%%
%% Exported Functions
%%

%% API
-export([start_link/1,push/2,pop/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

%%
%% API Functions
%%

start_link(AccountID)->
	gen_server:start_link(?MODULE, AccountID, []).

%% 零存，
push(PlayerId,{BagType,Item_id, Num_of_item, Is_bind})->
    Ps = mod_player:get_player_status(PlayerId),
    ServerRef = Ps#player_status.temp_bag_pid,
	gen_server:cast(ServerRef, {BagType,Item_id, Num_of_item, Is_bind}).

%% 整取
pop(PlayerId,BagType)->
    Ps = mod_player:get_player_status(PlayerId),
    ServerRef = Ps#player_status.temp_bag_pid,
	gen_server:call(ServerRef, BagType).


%%
%% gen_server callbacks
%%

%% 初始化进程回调函数
init(PlayerID) ->
    erlang:process_flag(trap_exit, true),
    ?INFO(temp_bag,"Player ~w's temp_bag process is start",[PlayerID]),
    mod_player:update_module_pid(PlayerID,?MODULE,self()),
    {ok, PlayerID}.

handle_call(Bag_type, _From, PlayerId) ->
    case gen_cache:lookup(?TEMP_BAG_ETS, {PlayerId,Bag_type}) of
        []-> 
            ItemList = [];
        [TempRec]->
            ItemList = TempRec#temp_bag.item_list
    end,
    {reply, ItemList, PlayerId}.

%% 异步回调函数，只处理push
handle_cast({Bag_type,Item_id, Num_of_item, Is_bind}, PlayerId) ->
    Add_item_list = {Item_id, Num_of_item, Is_bind},
    case gen_cache:lookup(?TEMP_BAG_ETS, {PlayerId,Bag_type}) of
        [] ->
            %% 为空则插入新的记录
            New_tem_Rec = #temp_bag{bag_key={PlayerId,Bag_type},item_list =[Add_item_list]},
            gen_cache:insert(?TEMP_BAG_ETS, New_tem_Rec);
        [TempRec] ->
            %% 不为空则更新这条记录
            Old_item_list = TempRec#temp_bag.item_list,
            New_item_list = [Add_item_list|Old_item_list],
            gen_cache:update_element(?TEMP_BAG_ETS,{PlayerId,Bag_type},[{#temp_bag.item_list,New_item_list}]) 
    end,
    {noreply, PlayerId}.	

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%
%% Local Functions
%%
