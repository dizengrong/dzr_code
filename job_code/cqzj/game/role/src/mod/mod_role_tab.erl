%% Author: xierongfeng
%% Created: 2012-12-4
%% Description: TODO: Add description to mod_role_tab
-module(mod_role_tab).

%%
%% Include files
%%
-include("mgeer.hrl").

%%
%% Exported Functions
%%
-export([
		 init/1, 
		 get/1, 
		 get/2, 
		 put/2, 
		 put/3, 
		 erase/1, 
		 erase/2, 
		 list/1, 
		 is_exist/1,
		 name/1,
		 update_element/3,
		 update_counter/3,
		 backup/1,
		 rollback/2
		]).

%%
%% API Functions
%%
init(RoleID) ->
	ets:new(name(RoleID), [named_table, public]).

get(RoleID, Key) ->
	case catch ets:lookup(name(RoleID), Key) of
		[{Key, Rec}] ->
			Rec;
		_ ->
			undefined
	end.

get({?ROLE_SUMMONED_PET_ID,RoleID}) ->
	catch ets:lookup_element(name(RoleID), 
		p_role_pet_bag, #p_role_pet_bag.summoned_pet_id);
get({Type, RoleID}) ->
	case catch ets:lookup(name(RoleID), record_tag(Type)) of
		[Rec] ->
			Rec;
		_ ->
			undefined
	end.

put({_Type, RoleID}, Rec) ->
	catch ets:insert(name(RoleID), Rec).

put(RoleID, Key, Rec) ->
	catch ets:insert(name(RoleID), {Key, Rec}).

erase(RoleID, Key) ->
	Tab = name(RoleID),
	case catch ets:lookup(Tab, Key) of
		[{Key, Rec}] ->
			ets:delete(Tab, Key),
			Rec;
		_ ->
			undefined
	end.

erase({Type, RoleID}) ->
	Tab = name(RoleID),
	Tag = record_tag(Type),
	case catch ets:lookup(Tab, Tag) of
		[Rec] ->
			ets:delete(Tab, Tag),
			Rec;
		_ ->
			undefined
	end.

list(RoleID) ->
	catch ets:tab2list(name(RoleID)).

is_exist(RoleID) ->
	ets:info(name(RoleID)) =/= undefined.

name(RoleID) when RoleID > 0 ->
	common_tool:list_to_atom(integer_to_list(RoleID));
name(RoleID) ->
	erlang:get({t_mirror, RoleID}).

update_element(RoleID, Key, List) ->
	catch ets:update_element(name(RoleID), Key, List).

update_counter(RoleID, Key, List) ->
	catch ets:update_counter(name(RoleID), Key, List).

backup({?role_hero_fb, RoleID}) ->
	mod_role_tab:get({?role_hero_fb, RoleID});
backup({?role_pos, RoleID}) ->
	mod_role_tab:get({?role_pos, RoleID});
backup({?role_base, RoleID}) ->
	mod_role_tab:get({?role_base, RoleID});
backup({?role_attr, RoleID}) ->
	mod_role_tab:get({?role_attr, RoleID});
backup({?role_fight, RoleID}) ->
	mod_role_tab:get({?role_fight, RoleID});
backup({?role_map_ext, RoleID}) ->
	mod_role_tab:get({?role_map_ext, RoleID});
backup({?role_team, RoleID}) ->
	mod_role_tab:get({?role_team, RoleID});
backup({?role_skill, RoleID}) ->
	mod_role_tab:get(RoleID, {?role_skill, RoleID});
backup(_) ->
	undefined.

rollback({?role_hero_fb, RoleID}, Data) when is_record(Data, p_role_hero_fb_info) ->
	mod_role_tab:put({?role_hero_fb, RoleID}, Data),
	true;
rollback({?role_pos, RoleID}, Data)  when is_record(Data, p_role_pos) ->
	mod_role_tab:put({?role_pos, RoleID}, Data),
	true;
rollback({?role_base, RoleID}, Data)  when is_record(Data, p_role_base) ->
	mod_role_tab:put({?role_base, RoleID}, Data),
	true;
rollback({?role_attr, RoleID}, Data)  when is_record(Data, p_role_attr) ->
	mod_role_tab:put({?role_attr, RoleID}, Data),
	true;
rollback({?role_fight, RoleID}, Data)  when is_record(Data, p_role_fight) ->
	mod_role_tab:put({?role_fight, RoleID}, Data),
	true;
rollback({?role_map_ext, RoleID}, Data)  when is_record(Data, r_role_map_ext) ->
	mod_role_tab:put({?role_map_ext, RoleID}, Data),
	true;
rollback({?role_team, RoleID}, Data)  when is_record(Data, r_role_team) ->
	mod_role_tab:put({?role_team, RoleID}, Data),
	true;
rollback({?role_skill, RoleID}, Data)  when is_list(Data) ->
	mod_role_tab:put(RoleID, {?role_skill, RoleID}, Data),
	true;
rollback(_, _) ->
	false.


%%
%% Local Functions
%%
record_tag(?role_attr)              -> p_role_attr;
record_tag(?role_base)              -> p_role_base;
record_tag(?role_pos)               -> p_role_pos;
record_tag(?role_fight)             -> p_role_fight;
record_tag(role_ext)                -> p_role_ext;
record_tag(?role_map_ext)           -> r_role_map_ext;
record_tag(?role_state)             -> r_role_state2;
record_tag(?ROLE_PET_BAG_INFO)      -> p_role_pet_bag;
record_tag(?role_hero_fb)           -> p_role_hero_fb_info;
record_tag(?role_team)           	-> r_role_team;
record_tag(random_mission)          -> r_random_mission;
record_tag(role_pet_grow_info)      -> p_role_pet_grow;
record_tag(r_role_mount)            -> r_role_mount;
record_tag(role_gems)               -> p_role_gems;
record_tag(?role_goal_info)         -> r_goal;
record_tag(?ROLE_ACHIEVEMENTS)      -> r_achievements;
record_tag(?HIDDEN_EXAMINE_FB_INFO) -> r_role_hidden_examine_fb;
record_tag(?QQ_YVIP)                -> r_qq_yvip;
record_tag(?daily_counter)          -> r_daily_counter;
record_tag(?open_server_activity)   -> r_open_server_activity;
record_tag(?role_kill_ybc)   		-> r_role_kill_ybc;
record_tag(?role_rune_altar)   		-> r_role_rune_altar;
record_tag(Tag)						-> Tag.
