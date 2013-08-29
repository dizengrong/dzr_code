%% Author: chixiaosheng
%% Created: 2011-3-22
%% Description: TODO: Add description to mod_admin_api
-module(mod_admin_api).

%%
%% Include files
%%
-include("mgeem.hrl").
%%
%% Exported Functions
%%
-export([do/1]).

%%
%% API Functions
%%clear_ybc_state
do(clear_ybc_state) ->
    spawn(fun() ->
        do_clear_state_1(),
        do_clear_state_2()
    end);

do({syn_ybc_pos, RoleID}) ->
    spawn(fun() ->
        do_syn_pos(RoleID)
    end);
    

do(Other) -> 
    ?ERROR_MSG("~ts:~w", ["处理后台消息失败了", Other]).


%%
%% Local Functions
%%
do_clear_state_1() ->
    List = db:dirty_match_object(db_ybc_unique, #r_ybc_unique{_='_'}),
    lists:foreach(fun(Unique) ->
        YBCID = Unique#r_ybc_unique.id,
        {GroupID, TypeID, RoleID} = Unique#r_ybc_unique.unique,
        case db:dirty_read(db_ybc, YBCID) of
            [] ->
                db:dirty_delete(db_ybc_unique, {GroupID, TypeID, RoleID});
            [_] ->
                ignore
        end
    end, List).

do_clear_state_2() ->
    RoleList1 = db:dirty_match_object(db_role_state, #r_role_state{ybc=1, _='_'}),
    RoleList2 = db:dirty_match_object(db_role_state, #r_role_state{ybc=2, _='_'}),
    RoleList3 = db:dirty_match_object(db_role_state, #r_role_state{ybc=3, _='_'}),
    RoleList4 = db:dirty_match_object(db_role_state, #r_role_state{ybc=4, _='_'}),
    RoleList5 = db:dirty_match_object(db_role_state, #r_role_state{ybc=8, _='_'}),

    RoleList = RoleList1++RoleList2++RoleList3++RoleList4++RoleList5,
    lists:foreach(
        fun(RoleState) ->
            RoleID = RoleState#r_role_state.role_id,
            Ybc = RoleState#r_role_state.ybc,
            [RoleBase] = db:dirty_read(db_role_base_p, RoleID),
            if
                Ybc =:= 1 orelse Ybc =:= 3 orelse Ybc =:= 4 ->
                    case db:dirty_read(db_ybc_unique, {0, 1, RoleID}) of
                        [] ->
                            db:dirty_write(db_role_state, RoleState#r_role_state{ybc=0});
                        [_] ->
                            ignore
                    end;
                Ybc =:= 8 ->
                    case db:dirty_read(db_ybc_unique, {RoleBase#p_role_base.family_id, 2, RoleID}) of
                        [] ->
                            db:dirty_write(db_role_state, RoleState#r_role_state{ybc=0});
                        [_] ->
                            ignore
                    end;
                true ->
                    ignore
            end
        end, RoleList).

do_syn_pos(RoleID) ->
    case mod_map_ybc:get_person_ybc_id(RoleID) of
        0 ->
            ignore;
        YbcID ->
            case db:dirty_read(?DB_YBC, YbcID) of
                [] ->
                    ignore;
                [#r_ybc{map_id=YbcMapID}] ->
                    F = fun() ->
                                {ok, Pos} = mod_map_role:get_role_pos(RoleID),
                                ChangeMapType = ?CHANGE_MAP_TYPE_NORMAL,
                                MapName = mgeem_map:get_mapname(),
                                MapID = mgeem_map:get_mapid(),
                                F2 = fun() -> mod_map_ybc:ybc_change_map(ChangeMapType, RoleID, MapName, MapID, Pos) end,
                                global:send(common_map:get_common_map_name(YbcMapID), {func, F2, []})
                        end,
                    common_misc:send_to_rolemap(RoleID, {func, F, []})
            end
    end.
