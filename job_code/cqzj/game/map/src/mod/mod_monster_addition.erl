%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2011, 
%%% @doc
%%%
%%% @end
%%% Created :  1 Jul 2011 by  <>
%%%-------------------------------------------------------------------
-module(mod_monster_addition).

-include("mgeem.hrl").

-export([
         hook_monster_born/2,
         hook_monster_dead/2]).

-export([
         monster_type_list_insert/2,
         monster_type_list_delete/2]).

-define(MONSTER_TYPE_LIST, monster_type_list).

%% @doc 怪物出生hook
hook_monster_born(MonsterID, MonsterTypeID) ->
    BeCaredMonsterList = get_be_cared_monster_list(MonsterTypeID),
    case BeCaredMonsterList of
        [] ->
            ignore;
        _ ->
            hook_monster_born_be_cared(MonsterID, MonsterTypeID, BeCaredMonsterList)
    end,
    CareMonsterList = get_care_monster_list(MonsterTypeID),
    case CareMonsterList of
        [] ->
            ignore;
        _ ->
            hook_monster_born_care(MonsterID, MonsterTypeID, CareMonsterList)
    end.

%% @doc 怪物出生，发现其被某些怪物关注了
hook_monster_born_be_cared(MonsterID, MonsterTypeID, BeCaredMonsterList) ->
    monster_type_list_insert(MonsterTypeID, MonsterID),
    do_monster_addition_be_cared(MonsterTypeID, BeCaredMonsterList).

%% @doc 怪物出生，发现其关注某些怪物
hook_monster_born_care(MonsterID, MonsterTypeID, CareMonsterList) ->
    monster_type_list_insert(MonsterTypeID, MonsterID),
    do_monster_addition_care(MonsterID, MonsterTypeID, CareMonsterList).

%% @doc 怪物死亡hook
hook_monster_dead(MonsterID, MonsterTypeID) ->
    BeCaredMonsterList = get_be_cared_monster_list(MonsterTypeID),
    case BeCaredMonsterList of
        [] ->
            ignore;
        _ ->
            hook_monster_dead_be_cared(MonsterID, MonsterTypeID, BeCaredMonsterList)
    end.

%% @doc 怪物死亡，发现其被某些怪物关注了
hook_monster_dead_be_cared(MonsterID, MonsterTypeID, BeCaredMonsterList) ->
    monster_type_list_delete(MonsterTypeID, MonsterID),
    do_monster_addition_be_cared(MonsterTypeID, BeCaredMonsterList).

%% =====================================================
%% interval func
%% =====================================================

%% @doc 怪物关注某怪物
do_monster_addition_care(MonsterID, _MonsterTypeID, CareMonsterList) ->
    case get_monster_buff_addition_care(CareMonsterList) of
        [] ->
            ignore;
        AddBuffs ->
            self() ! {mod_map_monster, {add_buff, MonsterID, monster, AddBuffs, MonsterID}}
    end.

%% @doc 怪物被关注
do_monster_addition_be_cared(MonsterTypeID, BeCaredMonsterList) ->
    lists:foreach(
      fun(BeCaredMonsterTypeID) ->
              lists:foreach(
                fun(BeCaredMonsterID) ->
                        do_monster_addition_be_cared2(BeCaredMonsterID, BeCaredMonsterTypeID, MonsterTypeID)
                end, get_monster_type_list(BeCaredMonsterTypeID))
      end, BeCaredMonsterList).

do_monster_addition_be_cared2(BeCaredMonsterID, BeCaredMonsterTypeID, MonsterTypeID) ->
    case get_monster_buff_addition_be_cared(BeCaredMonsterID, BeCaredMonsterTypeID, MonsterTypeID) of
        {OpType, Buff} ->
            self() ! {mod_map_monster, {OpType, BeCaredMonsterID, monster, Buff, BeCaredMonsterID}};
        _ ->
            ignore
    end.

%% @doc 获取怪物BUFF加成加注
get_monster_buff_addition_care(CareMonsterList) ->
    lists:foldl(
      fun({MonsterTypeID, Num, BuffID, Value}, AddBuffs) ->
              CareMonsterNum = erlang:length(get_monster_type_list(MonsterTypeID)),
              Value2 = (CareMonsterNum div Num) * Value,
              case Value2 =:= 0 of
                  true ->
                      AddBuffs;
                  _ ->
                      case lists:keyfind(BuffID, #p_buf.buff_id, AddBuffs) of
                          false ->
                              {ok, BuffDetail} = mod_skill_manager:get_buf_detail(BuffID),
                              [BuffDetail#p_buf{value=Value2, last_type=?BUFF_LAST_TYPE_FOREVER_TIME}|AddBuffs];
                          #p_buf{value=LV} = BuffDetail ->
                              [BuffDetail#p_buf{value=LV+Value2, last_type=?BUFF_LAST_TYPE_FOREVER_TIME}|AddBuffs]
                      end
              end
      end, [], CareMonsterList).

%% @doc 获取怪物BUFF加成被关注
get_monster_buff_addition_be_cared(MonsterID, MonsterTypeID, CareMonsterType) ->
    case mod_map_actor:get_actor_mapinfo(MonsterID, monster) of
        undefined ->
            monster_type_list_delete(MonsterTypeID, MonsterID),
            ignore;
        _ ->
            case get_care_monster_list(MonsterTypeID) of
                [] ->
                    ignore;
                CareMonsterList ->
                    get_monster_buff_addition_be_cared2(MonsterTypeID, CareMonsterList, CareMonsterType)
            end
    end.

get_monster_buff_addition_be_cared2(_MonsterTypeID, CareMonsterList, CareMonsterTypeID) ->
    case lists:keyfind(CareMonsterTypeID, 1, CareMonsterList) of
        false ->
            ignore;
        {_, _, BuffID, _} ->
            {ok, #p_buf{buff_type=BuffType}=Buff} = mod_skill_manager:get_buf_detail(BuffID),
            Value2 =
                lists:foldl(
                  fun({MTypeID, Num, BID, V}, Acc) ->
                          case BuffID =:= BID of
                              true ->
                                  Acc + erlang:length(get_monster_type_list(MTypeID)) div Num * V;
                              _ ->
                                  Acc
                          end
                  end, 0, CareMonsterList),
            case Value2 =:= 0 of
                true ->
                    {remove_buff, BuffType};
                _ ->
                    {add_buff, Buff#p_buf{value=Value2, last_type=?BUFF_LAST_TYPE_FOREVER_TIME}}
            end
    end.

%% @doc 获取该怪物的关注列表
get_care_monster_list(MonsterTypeID) ->
    case common_config_dyn:find(monster_addition, {care, MonsterTypeID}) of
        [] ->
            [];
        [L] ->
            L
    end.

%% @doc 获取该怪物被哪些怪物关注的列表
get_be_cared_monster_list(MonsterTypeID) ->
    case common_config_dyn:find(monster_addition, {be_cared, MonsterTypeID}) of
        [] ->
            [];
        [L] ->
            L
    end.

%% ======================================================
%% 怪物列表相关操作
%% =====================================================

get_monster_type_list(MonsterTypeID) ->
    case get({?MONSTER_TYPE_LIST, MonsterTypeID}) of
        undefined ->
            [];
        L ->
            L
    end.

set_monster_type_list(MonsterTypeID, List) ->
    erlang:put({?MONSTER_TYPE_LIST, MonsterTypeID}, List).

monster_type_list_insert(MonsterTypeID, MonsterID) ->
    L = get_monster_type_list(MonsterTypeID),
    case lists:member(MonsterID, L) of
        true ->
            ignore;
        _ ->
            set_monster_type_list(MonsterTypeID, [MonsterID|L])
    end.

monster_type_list_delete(MonsterTypeID, MonsterID) ->
    L = get_monster_type_list(MonsterTypeID),
    set_monster_type_list(MonsterTypeID, lists:delete(MonsterID, L)).
