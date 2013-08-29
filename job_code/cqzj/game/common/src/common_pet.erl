%%%-------------------------------------------------------------------
%%% @author liuwei
%%% @doc
%%% 异兽相关接口
%%% @end
%%% Created : 2011-10-22
%%%-------------------------------------------------------------------
-module(common_pet).

%% API
-export([
         on_transaction_begin/0,
         on_transaction_commit/0,
         on_transaction_rollback/0,
         role_pet_bag_backup/1,
         role_pet_backup/2
        ]).
-export([
		 get_pet_max_aptitude/1,
		 get_pet_max_aptitude/3,
		 get_pet_max_understanding/1,
		 % get_pet_default_trick_list/1,
		 get_pet_title/1,
		 get_understanding_add_rate/1
		]).

-include("common.hrl").

-define(ROLE_PET_TRANSACTION,role_pet_transaction).

-define(ROLE_PET_BAG_INFO_BK,role_pet_bag_info_bk).

-define(ROLE_PET_INFO_BK,role_pet_info_bk).
-define(ROLE_PET_INFO_LOCKED_LIST,role_pet_info_bk).

-define(UNDEFINED,undefined).


%% ====================================================================
%% API Functions
%% ====================================================================

on_transaction_begin() ->
    case get(?ROLE_PET_TRANSACTION) of
        ?UNDEFINED ->
            put(?ROLE_PET_TRANSACTION,true);
        _ ->
		    erase(?ROLE_PET_TRANSACTION),
			do_clear_pet_bag_backup_info(),
			do_delete_pet_transaction_info(),
            throw(nesting_transaction)
    end.


on_transaction_commit() ->
    erase(?ROLE_PET_TRANSACTION),
	do_clear_pet_bag_backup_info(),
	do_delete_pet_transaction_info().


on_transaction_rollback() ->
    erase(?ROLE_PET_TRANSACTION),
	do_rollback_role_pet_bag_info(),
	do_clear_pet_bag_backup_info(),
	erase(?ROLE_PET_INFO_LOCKED_LIST).


%% ====================================================================
%% LOCAL Functions
%% ====================================================================
%%宠物背包
do_rollback_role_pet_bag_info() ->
    case get(?ROLE_PET_BAG_INFO_BK) of
        Info when is_record(Info, p_role_pet_bag) ->
			#p_role_pet_bag{role_id = RoleID} = Info,
            mod_role_tab:put({?ROLE_PET_BAG_INFO, RoleID}, Info);
		_ ->
			ignore
    end.

do_clear_pet_bag_backup_info() ->
	erase(?ROLE_PET_BAG_INFO_BK).

role_pet_bag_backup(RoleID) -> 
	case get(?ROLE_PET_TRANSACTION) of
		?UNDEFINED ->
			throw(no_transaction);
		true ->
			case mod_role_tab:get({?ROLE_PET_BAG_INFO,RoleID}) of
				?UNDEFINED ->
					throw(no_pet_bag_data);
				Info ->
					case get(?ROLE_PET_BAG_INFO_BK) of
						?UNDEFINED ->
							put(?ROLE_PET_BAG_INFO_BK,Info),
							Info;
						_ ->
							throw(pet_bag_transaction_error)
					end
			end
	end.

%%宠物信息
do_delete_pet_transaction_info() ->
	erase(?ROLE_PET_INFO_LOCKED_LIST).

role_pet_backup(RoleID, PetID) -> 
    case get(?ROLE_PET_TRANSACTION) of
        ?UNDEFINED ->
            throw(no_transaction);
        true ->
            case get(?ROLE_PET_INFO_LOCKED_LIST) of
                undefined ->
                    put(?ROLE_PET_INFO_LOCKED_LIST,[PetID]),
                    role_pet_backup2(RoleID, PetID);
                PetIDList ->
                    case lists:member(PetID,PetIDList) of
                        false ->
                            put(?ROLE_PET_INFO_LOCKED_LIST,[PetID|PetIDList]),
                            role_pet_backup2(RoleID, PetID);
                        _ ->
                            mod_role_tab:get(RoleID, {?ROLE_PET_INFO,PetID})
                    end
            end
    end.

role_pet_backup2(RoleID, PetID) ->
    case mod_role_tab:get(RoleID, {?ROLE_PET_INFO,PetID}) of
        ?UNDEFINED ->
            throw(no_pet_info);
        Info ->
            put({?ROLE_PET_INFO_BK,PetID}, Info),
			Info
    end.

get_pet_title(PetColor) ->
	case PetColor of
		?COLOUR_GREEN 	-> "";
		?COLOUR_BLUE 	-> "优良";
		?COLOUR_PURPLE 	-> "上乘";
		?COLOUR_ORANGE 	-> "杰出";
		?COLOUR_GOLD 	-> "卓越";
		?COLOUR_RED 	-> "极品"
	end.

%%根据异兽的悟性返回对资质的加成
get_understanding_add_rate(UnderStanding) ->
	cfg_pet_understanding:understanding_add_aptitude(UnderStanding).

%% 获取异兽的最大的资质
get_pet_max_aptitude(PetInfo) ->
	get_pet_max_aptitude(PetInfo#p_pet.level, PetInfo#p_pet.color, PetInfo#p_pet.understanding).
get_pet_max_aptitude(PetLevel, PetColor, UnderStanding) ->
	cfg_pet_aptitude:init_max_aptitude(PetColor) 
	+  cfg_pet_aptitude:max_aptitude_add(PetColor) * PetLevel 
	+ get_understanding_add_rate(UnderStanding).


%% 获取异兽的最高悟性
get_pet_max_understanding(PetLevel) ->
	cfg_pet_understanding:max_understanding(PetLevel).

