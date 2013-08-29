%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com(C) 2011, 
%%% @doc
%%% 玩家在线挂机模块处理
%%% @end
%%% Created : 18 Jan 2011 by  <caochuncheng>
%%%-------------------------------------------------------------------
-module(mod_role_on_zazen).

-include("mgeem.hrl").

-export([
    add_zazen_exp/2,
    init_zazen_total_exp/1,
    del_zazen_total_exp/1,
    hook_role_exit/1
]).

%%%===================================================================
%%% API
%%%===================================================================
   
add_zazen_exp(RoleID, #p_map_role{level = Level, state = ?ROLE_STATE_ZAZEN, pos = RolePos})->
    ZazenExp = cfg_zazen:exp(Level) / 2,
    MultiExp = common_tool:ceil(
        mod_team_exp:get_multi_exp(RoleID, ZazenExp, [?BUFF_TYPE_ADD_EXP_MULTIPLE])),
    case mod_role_buff:has_any_buff(RoleID, cfg_zazen:all_buff()) of
        {true, BuffID} ->
            
            CurMapId = mgeem_map:get_mapid(),
            PosX     = RolePos#p_pos.tx,
            PosY     = RolePos#p_pos.ty,
            {EffectMapId, EffectOrgX, EffectOrgY, EffectRadius} = cfg_zazen:effect_arean(),
            TxDiff = erlang:abs(PosX - EffectOrgX),
            TyDiff = erlang:abs(PosY - EffectOrgY),
            case EffectMapId == CurMapId andalso TxDiff =< EffectRadius andalso TyDiff =< EffectRadius of
                true ->
                   [PBuffRec] = common_config_dyn:find(buffs, BuffID),
                   MultiExp2 = MultiExp * (PBuffRec#p_buf.value div 10000);
                false ->
                    MultiExp2 = MultiExp
            end;
        _ -> MultiExp2 = MultiExp
    end,
	mod_map_role:do_add_exp(RoleID, MultiExp2),
    TotalExp = case get({zazen_total_exp, RoleID}) of
        undefined -> 0;
        Exp       -> Exp
    end,

    DataRecord = #m_role2_add_exp_toc{exp = MultiExp2, type = ?ROLE2_ADD_EXP_TYPE_ZAZEN},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ADD_EXP, DataRecord),
    
    put({zazen_total_exp, RoleID}, TotalExp+MultiExp2);
add_zazen_exp(_, _) -> ignore.

init_zazen_total_exp(RoleID)->
    put({zazen_total_exp, RoleID}, 0).

del_zazen_total_exp(RoleID)->
    case erase({zazen_total_exp, RoleID}) of
        undefined -> 0;
        Exp       -> Exp
    end.

hook_role_exit(RoleId) ->
    del_zazen_total_exp(RoleId).

%%%===================================================================
%%% Internal functions
%%%===================================================================
