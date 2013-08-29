%%兑换模块依附的子模块
-module(mod_exchange_depend).

-include("mgeem.hrl").

-export([do_handle/1]).

-define(FAMILYCOLLECT,1).%%采集积分
-define(FAMILY_CONTRIBUTE,2).%%贡献度
-define(GONGXUN,3).%%战功
-define(PET_ARAN,4).%%斗兽场积分

do_handle({Unique,?FAMILY_COLLECT,?FAMILY_COLLECT_GET_ROLE_INFO,DataIn, RoleID, Line}) ->
    do_get_score(Unique,?FAMILY_COLLECT,?FAMILY_COLLECT_GET_ROLE_INFO,DataIn, RoleID, Line),
    ok;
do_handle(Info) ->
    ?ERROR_MSG("未知消息: ~w", [Info]).



do_get_score(Unique, Module, Method,DataIn, RoleID,Line) ->
    #m_family_collect_get_role_info_tos{type_id=TypeID} = DataIn,
    case TypeID of
       ?FAMILY_CONTRIBUTE ->
           {ok, #p_role_attr{family_contribute=Value}} = mod_map_role:get_role_attr(RoleID);
       ?GONGXUN ->
           Value = get_zgong_value(RoleID);
       GoodID->           
           Value = query_num_bygoods(RoleID,GoodID) 
    end,
    Rec = #m_family_collect_get_role_info_toc{value=Value,type_id=TypeID},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, Rec). 

%%取得物品数量
query_num_bygoods(RoleID,GoodsId) ->
    mod_exchange_npc_deal:get_role_deal_num(RoleID,GoodsId).
%%取得战功值
get_zgong_value(RoleID) ->
    try mod_map_role:get_role_attr(RoleID) of
        {ok, #p_role_attr{gongxun=GongXun}} ->
            GongXun
    catch
        _:Error ->
            ?DEBUG("gx:~w",[Error]),
            0
    end.
