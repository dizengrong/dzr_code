%%% -------------------------------------------------------------------
%%% Author  : Luo.JCheng
%%% Description :
%%%
%%% Created : 2010-9-3
%%% -------------------------------------------------------------------
-module(mod_system).

-include("mgeem.hrl").

-export([handle/1, sys_config_init/2]).

handle({Unique, Module, ?SYSTEM_CONFIG_CHANGE, DataIn, RoleID, _PID, Line}) ->
    do_config_change(Unique, Module, ?SYSTEM_CONFIG_CHANGE, DataIn, RoleID, Line);
handle({Unique, Module, ?SYSTEM_PK_NOT_AGREE, _DataIn, RoleID, _PID, Line}) ->
    do_pk_not_agree(Unique, Module, ?SYSTEM_PK_NOT_AGREE, RoleID, Line);

handle(Msg) ->
    ?ERROR_MSG("mod_system, unknow msg: ~w", [Msg]).

%% 玩家不同意PK
do_pk_not_agree(_Unique, _Module, _Method, RoleID, _Line) ->
	MapID = 10260,
    {MapID, TX, TY} = common_misc:get_born_info_by_map(MapID),
    mod_map_role:diff_map_change_pos(RoleID, MapID, TX, TY).

sys_config_init(RoleID, Client) ->
    case catch db:dirty_read(?DB_SYSTEM_CONFIG, RoleID) of
        [Info] ->
            SysConfig2 = Info#r_sys_config.sys_config;
        _ ->
            SysConfig = #p_sys_config{},
            SysConfig2 = SysConfig#p_sys_config{pick_equip_color=[true, true, true, true, true],
                                                pick_other_color=[true, true, true, true, true],
                                                skill_list=[]},
            Data = #r_sys_config{roleid=RoleID, sys_config=SysConfig2},
            db:dirty_write(?DB_SYSTEM_CONFIG, Data)
    end,

	R = #m_system_config_toc{sys_config=SysConfig2},
    common_misc:unicast2(Client, ?DEFAULT_UNIQUE, ?SYSTEM, ?SYSTEM_CONFIG, R),
    ok.

do_config_change(Unique, Module, Method, DataIn, RoleID, Line) ->
    R =
        try
            SysConfig = DataIn#m_system_config_change_tos.sys_config,

            %%直接写进数据库，并返回结果
            Data = #r_sys_config{roleid=RoleID, sys_config=SysConfig},
            db:dirty_write(?DB_SYSTEM_CONFIG, Data),
            %%通知相应的角色聊天进程设置更改
            #p_sys_config{private_chat=PrivateChat, nation_chat=NationChat, family_chat=FamilyChat,
                          world_chat=WorldChat, team_chat=TeamChat, center_broadcast=CenterBroadcast} = SysConfig,
            PName = common_misc:chat_get_role_pname(RoleID),
            global:send(PName, {channel_config_change, [WorldChat, NationChat, FamilyChat, TeamChat, PrivateChat, CenterBroadcast]}),

            #m_system_config_change_toc{}
        catch
            _:Reason ->
                ?ERROR_MSG("do_config_change, reason: ~w", [Reason]),

                #m_system_config_change_toc{succ=false, reason=?_LANG_SYSTEM_ERROR}
        end,

    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).
