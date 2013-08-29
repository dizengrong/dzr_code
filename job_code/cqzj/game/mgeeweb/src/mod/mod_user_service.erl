%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     mod_user_service
%%% @end
%%% Created : 2010-11-17
%%%-------------------------------------------------------------------
-module(mod_user_service).

-include("mgeeweb.hrl").

%% API
-export([
         get/1,
         getUserEquips/1,
         getUserSkin/1,
         getBagGoods/1,
         getStallGoods/1,
         getRolePos/1,
         get_all_roleids/0
        ]).
-export([transfer_to_json/2 ]).

get_all_roleids()->
    MatchHead = #p_role_base{role_id='$1', _='_'},
    Guard = [],
    db:dirty_select(db_role_base, [{MatchHead, Guard, ['$1']}]).

get(Req)->
    QueryString = Req:parse_qs(),
    try
        case handle(QueryString,Req) of
            not_supperted ->
                mgeeweb_tool:return_json_error(Req);
            {ok,Rtn}->
                mgeeweb_tool:return_json(Rtn, Req);
            {error,Error}->
                ?ERROR_MSG("~w error,QueryString=~w,Error=~w,stacktrace=~w",[?MODULE, QueryString, Error,erlang:get_stacktrace()]),
                mgeeweb_tool:return_json_error(Req)
            
        end
    catch
        _:Reason->
            ?ERROR_MSG("~w error,Reason=~w,stacktrace=~w",[?MODULE, Reason,erlang:get_stacktrace()]),
            mgeeweb_tool:return_json_error(Req)
    end.

handle(QueryString,Req)->
    Fun = proplists:get_value("fun", QueryString),
    Arg = proplists:get_value("arg", QueryString),
    
    case Fun of
        "getUserEquips"->
            getUserEquips(Arg);
        "getUserSkin"->
            getUserSkin(Arg);
        "getBagGoods"->
            getBagGoods(Arg);
        "getStallGoods"->
            getStallGoods(Arg);
		"getRolePos"->
			getRolePos(Arg);
		"getRoleFight"->
			getRoleFight(Arg);
		"getRoleBase"->
			getRoleBase(Arg);
        "getRolePetBag"->
            getRolePetBag(Arg);
        "getPetInfo" ->
            getPetInfo(Arg);
        "kickReturnHome"->
            kickReturnHome(Arg,Req);
        "updateRoleMission"->
            updateRoleMission(Arg,Req);
        "tidyRoleGoods"->
            tidyRoleGoods(Arg,Req);
        _ ->
            not_supperted
    end.

%% @doc 根据玩家ID获取对应的装备
getUserEquips(RoleID2)->
	RoleID = common_tool:to_integer(RoleID2),
    {ok, RoleAttr} = common_misc:get_dirty_role_attr(RoleID),
    #p_role_attr{equips=Equips} = RoleAttr,
    
    Res = [ transfer_to_json(p_goods,G) ||G<- Equips],
    {ok,Res}.

%% @doc 根据玩家ID获取对应的服饰
getUserSkin(RoleID2)->
	RoleID = common_tool:to_integer(RoleID2),
    {ok, RoleAttr} = common_misc:get_dirty_role_attr(RoleID),
    #p_role_attr{skin=Skin} = RoleAttr,
    
    %%Skin = {p_skin,2,1,1,30401201,0,0,0},
    Res = transfer_to_json(p_skin,Skin),
    {ok,Res}.

%% @doc 根据玩家ID获取对应的背包物品，包括在仓库里的物品
getBagGoods(RoleIDArg)->
    RoleID = common_tool:to_integer(RoleIDArg),
    case common_misc:is_role_online(RoleID) of
        true->
            common_bag2:get_bag_goods_list(RoleID,get_bag_goods_list),
            do_receive_bag_goods(get_bag_goods_list);
        false->
            case common_misc:get_dirty_bag_goods(RoleID) of
                {ok,BagGoods} ->
                    Res = [ transfer_to_json(p_goods,G) ||G<- BagGoods],
                    {ok,Res};
                {error,Reason}->
                    ?WARNING_MSG("get_dirty_bag_goods err,Reason=~w",[Reason]),
                    {ok,[]}
            end
    end.

do_receive_bag_goods(ReplyTag)->
    receive 
        {ReplyTag,{ok,AllGoodsList}} ->
            Res = [ transfer_to_json(p_goods,G) ||G<- AllGoodsList],
            {ok,Res};
        {ReplyTag,{error,Reason}} ->
            {error,Reason}
        after 5000 ->
            ?ERROR_MSG("time out  %%%%%%%%%",[]),
            {error,timeout}
    end.

%% @doc 根据玩家ID获取对应的摆摊物品
getStallGoods(RoleID2)->
    RoleID = common_tool:to_integer(RoleID2),
    {ok, StallGoods} = common_misc:get_dirty_stall_goods(RoleID),
    
    Res = [ transfer_to_json(p_goods,G) ||G<- StallGoods],
    {ok,Res}.

%% @doc 根据玩家ID获取玩家的位置信息
getRolePos(RoleID2)->
    RoleID = common_tool:to_integer(RoleID2),
    {ok, RolePos} = common_misc:get_dirty_role_pos(RoleID),
    ?DEBUG("getRolePos====================~w",[RolePos]),
    Res = transfer_to_json(p_role_pos,RolePos),
    {ok,Res}.

%% @doc 根据玩家ID获取玩家的战斗信息
getRoleFight(RoleID2)->
    RoleID = common_tool:to_integer(RoleID2),
    {ok, RoleFight} = common_misc:get_dirty_role_fight(RoleID),
    ?DEBUG("getRoleFight====================~w",[RoleFight]),
    Res = transfer_to_json(p_role_fight,RoleFight),
    {ok,Res}.

%% @doc 根据玩家ID获取玩家的基本信息
getRoleBase(RoleID2)->
    RoleID = common_tool:to_integer(RoleID2),
    {ok, RoleBase} = common_misc:get_dirty_role_base(RoleID),
    ?DEBUG("getRoleBase ==================== RoleBase=~w",[RoleBase]),
	Res = transfer_to_json(p_role_base,RoleBase),
    {ok,Res}.

%% @doc 根据玩家ID获取玩家的异兽背包信息
getRolePetBag(RoleID2)->
    RoleID = common_tool:to_integer(RoleID2),
    case db:dirty_read(?DB_ROLE_PET_BAG_P,RoleID) of
        [] ->
            Res = transfer_to_json(p_role_pet_bag,#p_role_pet_bag{role_id=RoleID,content=3,pets=[]});
        [RolePetBag] ->
            Res = transfer_to_json(p_role_pet_bag,RolePetBag)
    end,
    {ok,Res}.

%% @doc 根据异兽ID获取异兽详细信息
getPetInfo(PetID2)->
    PetID = common_tool:to_integer(PetID2),
    case db:dirty_read(?DB_PET_P,PetID) of
        [] ->
            Res = transfer_to_json(p_pet,#p_pet{});
        [PetInfo] ->
            Res = transfer_to_json(p_pet,PetInfo)
    end,
    {ok,Res}.


%% @doc 将玩家踢回主城，异步实现
kickReturnHome(StrRoleID,_Req)->
    RoleID = common_tool:to_integer(StrRoleID),
    mgeer_role:absend(RoleID, {mod_map_role,{return_peace_village, RoleID}}),
    ?DEBUG("kickReturnHome====================~",[]),
    {ok,[{result, ok}]}.

%% @doc 更新在线玩家的数据
updateRoleMission(StrRoleID,_Req)->
    RoleID = common_tool:to_integer(StrRoleID),
    Msg = {unicast,RoleID,?MISSION,?MISSION_UPDATE,{m_mission_update_toc,[],[]}},
    mgeer_role:absend(RoleID, Msg),
    {ok,[{result, ok}]}.

%% @doc 整理玩家背包数据
tidyRoleGoods(StrRoleID,_Req)->
    RoleID = common_tool:to_integer(StrRoleID),
    common_shell:fix_role_goods(RoleID),
    ?ERROR_MSG("运营在后台执行了整理玩家背包数据,RoleID=~w",[RoleID]),
    {ok,[{result, ok}]}.    


transfer_to_json(RecName,Rec)->
    mgeeweb_tool:transfer_to_json(RecName,Rec).
  

