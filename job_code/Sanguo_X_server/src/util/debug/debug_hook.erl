%% Author: dzr
%% Created: 2011-10-8
%% Description: TODO: Add description to debug_hook
-module(debug_hook).

%%=============================================================================
%% Include files
%%=============================================================================
-include("common.hrl").
%% -include("role.hrl").
%%=============================================================================
%% Exported Functions
%%=============================================================================
% -export([player/1,
% 		 mercenary/2,
% 		 get_on_battle_mer/1,
% 		 get_socket/1,
% 		 get_player_status/1,
% 		 get_fired_list/1,
% 		 get_mod_mer_dic/2]).

% -compile(export_all).
% %%=============================================================================
% %% API Functions
% %%=============================================================================
% player(NickName) ->
% 	case get_player_status(NickName) of
% 		none -> ok;
% 		PlayerStatus ->
% 			print_player_status(PlayerStatus)
% 	end.
% player(by_account, Account) ->
% 	case get_player_status(by_account, Account) of
% 		none -> ok;
% 		PS ->
% 			print_player_status(PS)
% 	end.

% mercenary(NickName, MerId) ->
% 	case get_player_status(NickName) of
% 		none -> ok;
% 		PlayerStatus ->
% 			MerPid = PlayerStatus#player_status.mer_pid,
% 			Mer = mod_mercenary:get(MerId, MerPid),
% 			case Mer of
% 				none ->
% 					io:format("~s has no this mercenary", [NickName]);
% 				_ ->
% 					io:format("~s's mercenary ~p attribute:~n", [NickName, MerId]),
% 					print_mer(Mer)
% 			end
% 	end.
% mercenary(by_account, Account, MerId) ->
% 	case get_player_status(by_account, Account) of
% 		none -> ok;
% 		PS ->
% 			MerPid = PS#player_status.mer_pid,
% 			Mer = mod_mercenary:get(MerId, MerPid),
% 			case Mer of
% 				none ->
% 					io:format("~s has no this mercenary", [Account]);
% 				_ ->
% 					io:format("~s's mercenary ~p attribute:~n", [Account, MerId]),
% 					print_mer(Mer)
% 			end
% 	end.

% get_fired_list(NickName) ->
% 	case get_player_status(NickName) of
% 		none -> ok;
% 		PlayerStatus ->
% 			MerPid = PlayerStatus#player_status.mer_pid,
% 			Mers = mod_mercenary:get_fired_list(MerPid),
% 			io:format("fired list: ~p~n", [Mers])
% 	end.

% get_on_battle_mer(NickName) ->
% 	case get_player_status(NickName) of
% 		none -> ok;
% 		PlayerStatus ->
% 			MerPid = PlayerStatus#player_status.mer_pid,
% 			MerList = mod_mercenary:get_on_battle_mer_list({online, MerPid}),
% 			io:format("~s's on battle mercenary :~n", [NickName]),
% 			[print_mer(Mer) || Mer <- MerList]
% 	end.

% get_socket(NickName) ->
% 	case get_player_status(NickName) of
% 		none -> ok;
% 		PlayerStatus ->
% 			PlayerStatus#player_status.socket
% 	end.

% get_mod_mer_dic(by_account, Account) ->
% 	case get_player_status(by_account, Account) of
% 		none -> ok;
% 		PS ->
% 			mod_mercenary:get_mod_process_dic(PS#player_status.mer_pid)
% 	end;
% get_mod_mer_dic(by_nickname, NickName) ->
% 	case get_player_status(NickName) of
% 		none -> ok;
% 		PS ->
% 			mod_mercenary:get_mod_process_dic(PS#player_status.mer_pid)
% 	end.
  
% %%=============================================================================
% %% Local Functions
% %%=============================================================================
% get_player_status(NickName) ->
% 	case ets:lookup(?ETS_NAME_ID_MAP, NickName) of
% 		[] ->
% 			io:format("~p not online~n", [NickName]),
% 			none;
% 		[Entry] ->
% 			PlayerId = Entry#ets_name_id_map.id,
% 			[OnlineEntry] = ets:lookup(?ETS_ONLINE, PlayerId),
% 			Pid = OnlineEntry#ets_online.pid,
% 			mod_player:get_player_status(Pid)
% 	end.
% get_player_status(by_account, Account) ->
% 	case mod_global:is_acc_exist(Account) of
% 		{true, PlayerId} 	-> 
% 			[OnlineEntry] = ets:lookup(?ETS_ONLINE, PlayerId),
% 			Pid = OnlineEntry#ets_online.pid,
% 			mod_player:get_player_status(Pid);
% 		false		-> 
% 			io:format("Accont: ~p isn't exist~n", [Account]),
% 			none
% 	end.
	

% print_player_status(PlayerStatus) ->
% 	Vip = mod_vip:get_vip_level(PlayerStatus#player_status.vip_pid),
% 	io:format("status is:~n"
% 					  "id = ~p, account name = ~p, nickname = ~p, vip = ~p~n"
% 					  "logout_time = ~w, login_time = ~w, online_time = ~p, total_online_time = ~p,~n"
% 					  "bag= ~p, bank= ~p, bind_gold= ~p, gold= ~p, bind_silver= ~p, silver= ~p~n"
% 					  "x = ~p, y = ~p, scene = ~p, scene_pid = ~p, access_scene = ~w~n"
% 					  "holy_level = ~p, energy = ~p, energy_buy_times = ~p, energy_update_time = ~w~n" 
% 					  "practice = ~p, popularity = ~p, popular = ~p~n"
% 			 		  "fcm = ~p, fcm_online_time = ~p, fcm_offline_time = ~p, level = ~p, reborn_times = ~p~n",
% 					  [PlayerStatus#player_status.id,
% 					   PlayerStatus#player_status.accname,
% 					   PlayerStatus#player_status.nickname,
%  					   Vip,
% 					   calendar:seconds_to_daystime(PlayerStatus#player_status.loginout_time),
% 					   calendar:seconds_to_daystime(PlayerStatus#player_status.login_time),
% 					   PlayerStatus#player_status.online_time,
% 					   PlayerStatus#player_status.total_online_time,
% 					   PlayerStatus#player_status.bag, 
% 					   PlayerStatus#player_status.bank,
% 					   PlayerStatus#player_status.bind_gold,
% 					   PlayerStatus#player_status.gold,
% 					   PlayerStatus#player_status.bind_silver,
% 					   PlayerStatus#player_status.silver,
% 					   PlayerStatus#player_status.x,
% 					   PlayerStatus#player_status.y,
% 					   PlayerStatus#player_status.scene,
% 					   PlayerStatus#player_status.scene_pid,
% 					   sets:to_list(PlayerStatus#player_status.access_scene),
% 					   PlayerStatus#player_status.holy_level,
% 					   PlayerStatus#player_status.energy,
% 					   PlayerStatus#player_status.energy_buy_times,
% 					   calendar:seconds_to_daystime(PlayerStatus#player_status.energy_update_time),
% 					   PlayerStatus#player_status.practice,
% 					   PlayerStatus#player_status.popularity,
% 					   PlayerStatus#player_status.popular,
% 					   PlayerStatus#player_status.fcm,
% 					   PlayerStatus#player_status.fcm_online_time,
% 					   PlayerStatus#player_status.fcm_offline_time,
% 					   PlayerStatus#player_status.level,
% 					   PlayerStatus#player_status.reborn_times
% 				]).
  
% print_mer(Mer) ->
% 	io:format(
% 					  "mer_key = ~p, type = ~p, is_fired = ~p, is_battle = ~p~n"
% 					  "career = ~p, level = ~p, star_lv = ~p, reincarnation = ~p~n"
% 					  "strong = ~p, intelligence = ~p, constitution = ~p, accurate = ~p~n"
% 					  "att_speed = ~p, crit = ~p, evade = ~p, block = ~p, hit = ~p~n"
% 					  "hp = ~p, exp = ~p~n"
% 					  "p_def = ~p, m_def = ~p, att = ~p, m_att = ~p, skill = ~p~n"
% 					  "foster_attr = ~p~n", 
% 					  [
% 					   Mer#mercenary.mer_key, Mer#mercenary.gd_roleRank,
% 					   Mer#mercenary.gd_isFired, Mer#mercenary.gd_isBattle, 
% 					   Mer#mercenary.gd_careerID,
% 					   Mer#mercenary.gd_roleLevel, Mer#mercenary.gd_roleStarLevel,
% 					   Mer#mercenary.gd_resurrectionCount, Mer#mercenary.gd_strong,
% 					   Mer#mercenary.gd_intelligence, Mer#mercenary.gd_constitution,
% 					   Mer#mercenary.gd_accurate, Mer#mercenary.gd_speed,
% 					   Mer#mercenary.gd_critical, Mer#mercenary.gd_evade,
% 					   Mer#mercenary.gd_block, Mer#mercenary.gd_hitRate,
% 					   Mer#mercenary.gd_currentHp,
% 					   Mer#mercenary.gd_exp,
% 					   Mer#mercenary.p_def,
% 					   Mer#mercenary.m_def, Mer#mercenary.p_att,
% 					   Mer#mercenary.m_att, Mer#mercenary.gd_skill,
% 					   [Mer#mercenary.gd_fstrong, Mer#mercenary.gd_fintelligence, 
% 					   	Mer#mercenary.gd_fconstitution, Mer#mercenary.gd_faccurate]
% 					  ]).
			
			