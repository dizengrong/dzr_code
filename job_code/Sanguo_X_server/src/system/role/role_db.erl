%% Author: dzr
%% Created: 2012-3-30
%% Description: role module's db access 
-module(role_db).

%%
%% Include files
%%
-include ("common.hrl").

-define(ROLE_CACHE_REF, cache_util:get_register_name(role)).
-define(ROLE_DATA_CACHE_REF, cache_util:get_register_name(role_data)).
%%
%% Exported Functions
%%
-export([get_roles/1, get_role/2, update_role_elements/3, insert_role_rec/2,
		 get_role_data/1, insert_role_data_rec/2, update_role_data_fields/3]).

-compile(export_all).

%% ============================= for role base ===============================
%% ===========================================================================
get_roles(PlayerId) ->
	gen_cache:lookup(?ROLE_CACHE_REF, PlayerId).

get_role(PlayerId, RoleId) ->
	gen_cache:lookup(?ROLE_CACHE_REF, {PlayerId, RoleId}).

update_role_elements(_PlayerId, Key, UpdateFields) ->
	gen_cache:update_element(?ROLE_CACHE_REF, Key, UpdateFields).

insert_role_rec(_PlayerId, RoleRec) ->
	gen_cache:insert(?ROLE_CACHE_REF, RoleRec). 

%% ============================= for role data ===============================
%% ===========================================================================
insert_role_data_rec(_PlayerId, RoleDataRec) ->
	gen_cache:insert(?ROLE_DATA_CACHE_REF, RoleDataRec).

-spec get_role_data(player_id()) -> #role_data{}.
get_role_data(PlayerId) ->
	[R | _] = gen_cache:lookup(?ROLE_DATA_CACHE_REF, PlayerId),
	R.

update_role_data_fields(_PlayerId, Key, UpdateFields) ->
	gen_cache:update_element(?ROLE_DATA_CACHE_REF, Key, UpdateFields).

get_foster_flag(PlayerId) ->
	R = get_role_data(PlayerId),
	R#role_data.gd_fosterFlag.

set_foster_flag(PlayerId, FosterFlag) ->
	update_role_data_fields(PlayerId, PlayerId, [{#role_data.gd_fosterFlag, FosterFlag}]).

get_junwei(PlayerId) ->
	R = get_role_data(PlayerId),
	R#role_data.gd_junwei.

set_junwei(PlayerId, Junwei) ->
	update_role_data_fields(PlayerId, PlayerId, [{#role_data.gd_junwei, Junwei}]).