%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     运维瑞士军刀，for role
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mt_role).

%%
%% Include files
%%
-include("common.hrl").

-compile(export_all).
-define( DEBUG(F,D),io:format(F, D) ).

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%
role_base(RoleName) when is_list(RoleName)->
    role_base( get_roleid(RoleName) );
role_base(RoleID)->
    mt_process:role_d(RoleID,{role_base, RoleID}).

role_attr(RoleName) when is_list(RoleName)->
    role_attr( get_roleid(RoleName) );
role_attr(RoleID)->
    mt_process:role_d(RoleID,{role_attr, RoleID}).

role_team(RoleName) when is_list(RoleName)->
    role_team( get_roleid(RoleName) );
role_team(RoleID)->
    mt_process:role_d(RoleID,{role_team, RoleID}).

role_skill(RoleName) when is_list(RoleName)->
    role_skill( get_roleid(RoleName) );
role_skill(RoleID)->
    mt_process:role_d(RoleID,{role_skill, RoleID}).

role_bag(RoleName)->
    role_bag(RoleName,1).

role_bag(RoleName,BagId) when is_list(RoleName)->
    role_bag( get_roleid(RoleName),BagId );
role_bag(RoleID,BagId)->
    mt_process:bag_d(RoleID,BagId).


%%神游三界/月光宝盒的数据
role_box(RoleName) when is_list(RoleName)->
    role_box( get_roleid(RoleName) );
role_box(RoleID)->
    mt_process:role_d(RoleID,{role_treasbox, RoleID}).

role_map_ext(RoleName) when is_list(RoleName)->
    role_map_ext( get_roleid(RoleName) );
role_map_ext(RoleID)->
    mt_process:role_d(RoleID,{role_map_ext, RoleID}).

role_jingjie(RoleName) when is_list(RoleName)->
    role_jingjie( get_roleid(RoleName) );
role_jingjie(RoleID)->
    mt_process:role_d(RoleID,{role_jingjie, RoleID}).

role_gateway(RoleName) when is_list(RoleName)->
    role_gateway( get_roleid(RoleName) );
role_gateway(RoleID)->
    mt_process:d( common_misc:get_role_line_process_name(RoleID) ).


%%@doc 从mnesia中读取脏数据
dirty(RoleName) when is_list(RoleName)->
    dirty( get_roleid(RoleName) );
dirty(RoleID) when is_integer(RoleID)->
    case common_misc:get_dirty_role_base(RoleID) of
    {ok, RoleBase} -> 
        {ok, RoleBase};
    Other-> 
        Other
    end.


get_roleid(RoleName) when is_list(RoleName)->
    common_misc:get_roleid_by_accountname(RoleName).

show_fcm(RoleName) when is_list(RoleName)->
    show_fcm( get_roleid(RoleName) );
show_fcm(RoleID)->
    R2 = #m_system_need_fcm_toc{remain_time=3600},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?SYSTEM, ?SYSTEM_NEED_FCM, R2),
    ok.

