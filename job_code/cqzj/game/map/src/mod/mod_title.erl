%% Author: dizengrong
%% Created: 2013-2-4
-module(mod_title).

-include("mgeem.hrl").

-export([
    handle/1,
    do_change_cur_title/5
]).

%%==================API  function================================================
handle({Unique, ?TITLE, ?TITLE_CHANGE_CUR_TITLE, DataRecord, RoleID, _PID, Line}) ->
    do_change_cur_title(Unique, DataRecord, RoleID, Line).

%%================First Level Local Function=====================================
do_change_cur_title(Unique, DataRecord, RoleID, Line) -> 
    TitleID = DataRecord#m_title_change_cur_title_tos.id,
    Type    = DataRecord#m_title_change_cur_title_tos.type,
    do_change_cur_title(Unique, TitleID, Type, RoleID, Line).

do_change_cur_title(Unique, TitleID, Type, RoleID, Line) ->
    Ret = if 
        TitleID == 0 -> 
            {undefined, undefined};
        Type == ?TITLE_ACHIEVEMENT ->
            case mod_achievement2:is_title_open(RoleID, TitleID) of
                false -> false;
                true -> cfg_title:achieve_title(TitleID)
            end;
        true ->
            SenceTitles = common_title:get_role_sence_titles(RoleID),
            case lists:keyfind(TitleID,#p_title.id,SenceTitles) of
                false -> false;
                TitleInfo ->
                    {TitleInfo#p_title.name,TitleInfo#p_title.color}
            end
    end,
    case Ret of
        false -> common_misc:send_common_error(RoleID, 0, <<"该称号没有开启">>);
        {TitleName, TitleColor} ->
            common_title:change_nation_title(RoleID, TitleID),
            mod_role_tab:update_element(RoleID, p_role_base, 
                [{#p_role_base.cur_title, TitleName}, {#p_role_base.cur_title_color, TitleColor}]),

            Data = #m_title_change_cur_title_toc{succ = true,id = TitleID,color = TitleColor},
            common_misc:unicast(Line, RoleID, Unique, ?TITLE, ?TITLE_CHANGE_CUR_TITLE, Data),
            case Type of
                ?TITLE_ACHIEVEMENT ->
                    mod_achievement2:change_title(RoleID, TitleID);
                _ ->
                    mod_achievement2:change_title(RoleID, 0)
            end,

            mod_map_role:update_map_role_info(RoleID, 
                [
                    {#p_map_role.cur_title, TitleName},
                    {#p_map_role.cur_title_color, TitleColor}
                ]
            )
    end.
