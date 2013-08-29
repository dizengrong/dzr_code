%% Author: Administrator
%% Created: 2011-11-11
%% Description: TODO: Add description to pp_guild
-module(pp_guild).

%%
%% Include files
%%
-include ("common.hrl").
%%
%% Exported Functions
%%
-export([handle/3]).

%%
%% API Functions
%%

handle(19000, ID, {GuildName, Manifesto, Type}) ->
	guild:create_guild(ID, GuildName, Manifesto, Type);

handle(19001, ID, {SortType, Page, GuildID}) ->
	?INFO(pp_guild, "GuildID = ~w", [GuildID]),
	guild:apply_join_guild(ID, SortType, Page, GuildID);

handle(19002, ID, _) ->
	guild:quit_guild(ID);

handle(19003, ID, IsCancel) ->
	guild:dismiss_guild(ID, IsCancel);

handle(19005, IDFrom, {IDTo, Rank}) ->
	NRank = 
		if (Rank > 5) -> 5;
		   (Rank < 1) -> 1;
		true -> Rank
		end,
	guild:designate_rank(IDFrom, IDTo, NRank);

handle(19007, ID, {SortType, Page, GuildList}) ->
	guild:batch_apply_join_guild(ID, SortType, Page, GuildList);

handle(19009, ID, GuildID) ->
	guild:get_guild_event(ID, GuildID);
	
%% get information of the specified guild 
handle(19010, ID, GuildID) ->
	guild:get_guild_info(ID, GuildID);

%% get player's information in the guild 
handle(19011, ID, _) ->
	?INFO(guild, "get_guild_player_info"),
	guild:get_guild_player_info(ID);

handle(19012, ID, Page) ->
	guild:get_guild_apply_list(ID, Page);

%% change guild manifeso
handle(19014, ID, Manifesto) ->
	?INFO(guild, "change manifesto"),
	guild:change_manifesto(ID, Manifesto);

%% fire member
handle(19018, IDHigh, IDLow) ->
	guild:fire_member(IDHigh, IDLow);
	
handle(19019, ID, {AppID, IsApprove}) ->
	guild:approve_join_guild(ID, AppID, IsApprove);

%% get guild list
handle(19013, ID, {Name, SearchType, Page}) ->
	guild:get_guild_list(ID, Name, SearchType, Page);

%% donate
handle(19015, ID, {Silver, Gold}) ->
	guild:donate(ID, Silver, Gold);

handle(19017, ID, _) ->
	guild:get_welfare(ID);

%% get guild member list
handle(19028, ID, {SortType, Page}) ->
	guild:get_guild_member_list(ID, SortType, Page);

handle(19029, ID, _) ->
	guild:get_donate_info(ID);

handle(19040, ID, {ItemID, Count}) ->
	guild:buy_items(ID, ItemID, Count);
	
handle(19041, ID, {SkillID, Level}) ->
	guild:learn_skill(ID, SkillID, Level);

handle(19100, ID, _) ->
	guild:get_guild_basic_info(ID);
	
handle(_, _, _) ->
	ok.


