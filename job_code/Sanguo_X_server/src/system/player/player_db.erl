%% Author: dzr
%% Created: 2012-3-30
%% Description: player module's db access 
-module(player_db).

%%
%% Include files
%%
%% -include ("player_record.hrl").
-include("common.hrl").
-define(ACCOUNT_CACHE_REF, cache_util:get_register_name(account)).
-define(PLAYER_DATA_CACHE_REF, cache_util:get_register_name(player_data)).
%%
%% Exported Functions
%%
-export([insert_account_rec/2, get_account_rec/1, update_account_elements/3,
		 save_logout_time/2, save_login_time/2, get_last_login_time/1,
		 get_online_time/1, get_player_data/1, save_online_time/3,
		 insert_player_data/2,update_player_data_elements/3]).


%% ============================= for player =================================
%% ===========================================================================

insert_account_rec(_PlayerId, AccountRec) ->
	gen_cache:insert(?ACCOUNT_CACHE_REF, AccountRec).

get_account_rec(PlayerId) ->
	[AccountRec] = gen_cache:lookup(?ACCOUNT_CACHE_REF, PlayerId),
	AccountRec.

update_account_elements(_PlayerId, Key, UpdateFields) ->
	gen_cache:update_element(?ACCOUNT_CACHE_REF, Key, UpdateFields).

save_logout_time(PlayerId, Time) ->
	update_account_elements(PlayerId, PlayerId, [{#account.gd_LastLoginoutTime, Time}]).

save_login_time(PlayerId, Time) ->
	update_account_elements(PlayerId, PlayerId, [{#account.gd_LastLoginTime, Time}]).

get_last_login_time(PlayerId) ->
	AccountRec = get_account_rec(PlayerId),
	AccountRec#account.gd_LastLoginTime.


%% =========================== for player data ================================
%% ============================================================================
insert_player_data(_PlayerId, PlayerDataRec) ->
	gen_cache:insert(?PLAYER_DATA_CACHE_REF, PlayerDataRec).

get_player_data(PlayerId) ->
	[PlayerDataRec] = gen_cache:lookup(?PLAYER_DATA_CACHE_REF, PlayerId),
	PlayerDataRec.

%% return {dayOnlineTime, totalOnlineTime}
get_online_time(PlayerId) ->
	PlayerDataRec = get_player_data(PlayerId),
	{PlayerDataRec#player_data.gd_dayOnlineTime, PlayerDataRec#player_data.gd_totalOnlineTime}.
	
save_online_time(PlayerId, DayOnlineTime, TotalOnlineTime) ->
	update_player_data_elements(PlayerId, PlayerId, 
			[{#player_data.gd_dayOnlineTime, DayOnlineTime}, 
			 {#player_data.gd_totalOnlineTime, TotalOnlineTime}]).


update_player_data_elements(_PlayerId, Key, UpdateFields) ->
	gen_cache:update_element(?PLAYER_DATA_CACHE_REF, Key, UpdateFields).