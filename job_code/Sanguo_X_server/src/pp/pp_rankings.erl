%% Author: zqq
%% Created: 2012-1-21
%% Description: 处理排行榜协议
-module(pp_rankings).

%%
%% Include files
%%
-include("common.hrl").

%%
%% Exported Functions
%%
-export([handle/3]).

%%
%% API Functions
%%

%% 我的排行
handle(33000, PlayerId, {_AccountID}) ->
	mod_rank:client_get_my_rankings(PlayerId);

%% 个人排行榜
handle(33001, PlayerId, {Range, Page}) ->
	mod_rank:client_get_person_rankings(PlayerId, Range, Page);

%% 爬塔排行
handle(33002, PlayerId, {Page}) ->
	mod_rank:client_get_tower_rankings(PlayerId, Page);

%% 副本排行
handle(33003, PlayerId, {Range, Page}) ->
	mod_rank:client_get_dungeon_rankings(PlayerId, Range, Page);

handle(33004, PlayerId, ID) ->
	{ok,BinData} = pt_33:write(33004,ID),
	lib_send:send(PlayerId,BinData);

handle(33005,PlayerId,{ID,RoleId}) ->
	RoleRec = role_base:get_employed_role_rec(ID,RoleId),
	ItemList = cache_items:getItemsByRole(ID, RoleId),
	{ok,BinData} = pt_33:write(33005,{RoleRec,ItemList}),
	lib_send:send(PlayerId,BinData);

%% 装备
handle(33006, PlayerId, {Range, Page}) ->
	mod_rankings:client_get_equipment_rankings(PlayerId, Range, Page);

%% 人气
handle(33007, PlayerId, {Range, Page}) ->
	mod_rankings:client_get_popular_point_rankings(PlayerId, Range, Page);

%% 公会
handle(33009, PlayerId, {Page}) ->
	mod_rank:client_get_guild_rankings(PlayerId, Page);

%% 下水道
handle(33010, PlayerId, {Range, Page}) ->
	mod_rankings:client_get_tower_rankings(PlayerId, Range, Page);

%% 魂石
handle(33011, PlayerId, {Range, Page}) ->
	mod_rankings:client_get_stone_rankings(PlayerId, Range, Page);

%% 坐骑
handle(33012, PlayerId, {Range, Page}) ->
	mod_rankings:client_get_ride_rankings(PlayerId, Range, Page);

%% 送花
handle(33013, PlayerId, {Range, Page}) ->
	mod_rankings:client_get_sent_flower_rankings(PlayerId, Range, Page);

%% 收花
handle(33014, PlayerId, {Range, Page}) ->
	mod_rankings:client_get_recv_flower_rankings(PlayerId, Range, Page).

%%
%% Local Functions
%%

