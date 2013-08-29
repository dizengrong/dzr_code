%%%-------------------------------------------------------------------
%%% @author chenrong
%%% @doc
%%%     产出告知系统
%%% @end
%%% Created : 2012-09-07
%%%-------------------------------------------------------------------
-module(mod_access_guide).

-include("mgeem.hrl").

-export([handle/1,
         handle/2,
         hook/1,
         send_hook_info/2,
         cast_access_guide_info/1]).

handle(Info, _State) ->
    handle(Info).

handle({_, ?ACCESS_GUIDE, ?ACCESS_GUIDE_INFO, _, _, _, _} = Info) ->
    do_access_guide_info(Info);

handle({hook,Info}) ->
    hook(Info);

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

do_access_guide_info({_Unique, _Module, _Method, _DataIn, RoleID, _PID, _Line}) ->
    cast_access_guide_info(RoleID).

cast_access_guide_info(RoleID) ->
    FinishGuideList = get_access_guide_finish_list(RoleID),
    {ok, #p_role_attr{level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
    Viplevel = mod_vip:get_role_vip_level(RoleID),
    _IDlist = get_current_access_guide_list(RoleLevel, Viplevel, FinishGuideList).
%%     common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACCESS_GUIDE, ?ACCESS_GUIDE_INFO, #m_access_guide_info_toc{guide_ids=IDlist}).

get_access_guide_finish_list(RoleID) ->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,ExtInfo} ->
            AccessGuide = ExtInfo#r_role_map_ext.access_guide,
            AccessGuide#r_access_guide.finish_guide_list;
        _ ->
            []
    end.

get_current_access_guide_list(RoleLevel, VipLevel, FinishGuideList) ->
    TotalAccessGuideList = common_config_dyn:list(access_guide),
    GuideListConf = get_guide_list_config(RoleLevel, VipLevel, TotalAccessGuideList),
    get_guide_id_list(GuideListConf, FinishGuideList, []).

get_guide_id_list([], _, AccIDList) ->
    lists:reverse(lists:filter(fun(E) -> E =/= 0 end, AccIDList));
get_guide_id_list([{_Type, IDList}|T], FinishGuideList, AccIDList) ->
    NewAccIDList = [get_avaliable_guide_id(IDList, FinishGuideList) | AccIDList],
    get_guide_id_list(T, FinishGuideList, NewAccIDList).

get_avaliable_guide_id([], _) ->
    0;
get_avaliable_guide_id([ID|T], FinishGuideList) ->
    ToDate = erlang:date(),
    case lists:keyfind(ID, 1, FinishGuideList) of
        {ID, LastFinishDate} when LastFinishDate =/= ToDate ->
            ID;
        false ->
            ID;
        _ ->
            get_avaliable_guide_id(T, FinishGuideList)
    end.
    

get_guide_list_config(_,_,[]) ->
    [];
get_guide_list_config(RoleLevel, VipLevel, [{{MinRoleLevel, MaxRoleLevel}, SubConfList}|T]) ->
    if RoleLevel >= MinRoleLevel andalso MaxRoleLevel >= RoleLevel ->
           get_guide_list_config_1(VipLevel,SubConfList);
       true ->
           get_guide_list_config(RoleLevel,VipLevel,T)
    end.

get_guide_list_config_1(_, []) ->
    [];
get_guide_list_config_1(VipLevel, [{{MinVipLevel, MaxVipLevel},ConfigList}|T]) ->
    if VipLevel >= MinVipLevel andalso MaxVipLevel >= VipLevel ->
           ConfigList;
       true ->
           get_guide_list_config_1(VipLevel, T)
    end.
    
%% 处理非地图进程的hook
send_hook_info(RoleID, Info) ->
    mgeer_role:send(RoleID, {mod, mod_access_guide, {hook,Info}}).

hook({finish_horse_racing, RoleID}) ->
    update_role_access_guide(RoleID, 1001);
hook({activity, RoleID, 10011}) ->
    update_role_access_guide(RoleID, 5001);
hook({activity, RoleID, 10005}) ->
    update_role_access_guide(RoleID, 3001);
hook({activity, RoleID, 10001}) ->
    update_role_access_guide(RoleID, 2001);
hook({mine_fb,RoleID}) ->
    update_role_access_guide(RoleID, 2003);
hook({rnkm, RoleID}) ->
    update_role_access_guide(RoleID, 2002);
hook({exp_back,RoleID}) ->
    update_role_access_guide(RoleID, 3003);
hook(Info) ->
    ?ERROR_MSG("~w, unrecognize access guide hook: ~w", [?MODULE,Info]).
    

update_role_access_guide(RoleID, GuideID) ->
    case mod_map_role:get_role_map_ext_info(RoleID) of
        {ok,ExtInfo} ->
            AccessGuide = ExtInfo#r_role_map_ext.access_guide,
            GuideList = AccessGuide#r_access_guide.finish_guide_list,
            NewGuideList = lists:keystore(GuideID, 1, GuideList, {GuideID, erlang:date()}),
            mod_map_role:set_role_map_ext_info(RoleID, ExtInfo#r_role_map_ext{access_guide=AccessGuide#r_access_guide{finish_guide_list=NewGuideList}}),
            cast_access_guide_info(RoleID);
        _ ->
            ignore
    end.
