%% Author: xierongfeng
%% Created: 2012-11-16
%% Description: 坐骑系统(新)
-module(mod_role_mount).

-define(_common_error,  ?DEFAULT_UNIQUE, ?COMMON,   ?COMMON_ERROR,  #m_common_error_toc).%}
-define(_mount_up,      ?DEFAULT_UNIQUE, ?MOUNT,    ?MOUNT_UP,      #m_mount_up_toc).%}
-define(_mount_down,    ?DEFAULT_UNIQUE, ?MOUNT,    ?MOUNT_DOWN,    #m_mount_down_toc).%}
-define(_last_mount,    ?DEFAULT_UNIQUE, ?MOUNT,    ?MOUNT_LAST,    #m_mount_last_toc).%}

%%
%% Include files
%%
-include("mgeem.hrl").

%%
%% Exported Functions
%%
-export([init/2, delete/1, handle/1, do_mount_down/1, 
    get_last_mount/1, update_last_mount/2, notice_last_mount/1, calc/5, recalc/2]).

%%
%% API Functions
%%
init(RoleID, Rec) when is_record(Rec, r_role_mount) ->
    mod_role_tab:put({r_role_mount, RoleID}, Rec);
init(_RoleID, _) ->
    ignore.

delete(RoleID) ->
    mod_role_tab:erase({r_role_mount, RoleID}).

update_last_mount(RoleID, LastMount) ->
    mod_role_tab:put({role_mount, RoleID}, #r_role_mount{last_mount = LastMount }),
    common_misc:unicast({role, RoleID}, ?_last_mount{last_mount = LastMount}).

get_last_mount(RoleID) ->
    #r_role_mount{last_mount = LastMount} = get_role_mount(RoleID),
    LastMount.

notice_last_mount(RoleID) ->
    #r_role_mount{last_mount = LastMount} = get_role_mount(RoleID),
    common_misc:unicast({role, RoleID}, ?_last_mount{last_mount = LastMount}).

handle({_Unique, ?MOUNT, ?MOUNT_UP, DataIn, RoleID, PID, _Line}) ->
    #m_mount_up_tos{type = MountType} = DataIn,
    case get_role_mount(RoleID) of
        #r_role_mount{last_mount = MountType} ->
            case mod_map_actor:get_actor_mapinfo(RoleID, role) of
                #p_map_role{state = ?ROLE_STATE_ZAZEN} ->
                    common_misc:unicast2(PID, ?_common_error{error_str = <<"打坐中，无法驾驭法宝，请先按“D”结束">>});
                _ ->
                    case mod_spring:is_in_spring_map() of
                        true ->
                            common_misc:unicast2(PID, ?_common_error{error_str = <<"温泉中，无法驾驭法宝">>});
                        _ ->
                            do_change_mount(RoleID, MountType)
                    end
            end;
        _ ->
            common_misc:unicast2(PID, ?_common_error{error_str = <<"该法宝不存在">>})
    end;

handle({_Unique, ?MOUNT, ?MOUNT_DOWN, _DataIn, RoleID, _PID, _Line}) ->
    do_mount_down(RoleID).

calc(RoleBase, Op1, MountType1, Op2, MountType2) ->
    calc(calc(RoleBase, Op1, MountType1), Op2, MountType2).

calc(RoleBase, Op, MountType) ->
    mod_role_attr:calc(RoleBase, Op, speed_attrs(MountType)).

recalc(RoleBase, RoleAttr) ->
    MountType = RoleAttr#p_role_attr.skin#p_skin.mounts,
    mod_role_attr:calc(RoleBase, '+', speed_attrs(MountType)).

%%
%% Local Functions
%%
update_role_base(RoleID, OldMountType, NewMountType) ->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    NewRoleBase    = calc(RoleBase, '-', OldMountType, '+', NewMountType),
    mod_role_attr:reload_role_base(NewRoleBase).

speed_attrs(MountType) ->
    [{#p_role_base.move_speed, cfg_fashion:move_speed(MountType)}].

do_mount_down(RoleID) ->
    do_change_mount(RoleID, 0).

do_change_mount(RoleID, NewMountType) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    RoleSkin       = RoleAttr#p_role_attr.skin,
    OldMountType   = RoleSkin#p_skin.mounts,
    NewMountType =/= OldMountType andalso begin
        mod_role_tab:put({?role_attr, RoleID}, 
            RoleAttr#p_role_attr{skin = RoleSkin#p_skin{mounts = NewMountType}}),
        update_role_base(RoleID, OldMountType, NewMountType)
    end.

get_role_mount(RoleID) ->
    case mod_role_tab:get({r_role_mount, RoleID}) of
        undefined ->
            #r_role_mount{};
        Mount ->
            Mount
    end.
