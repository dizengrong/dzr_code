%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     副本NPC的逻辑处理
%%% @end
%%% Created : 2011-6-16
%%%-------------------------------------------------------------------
-module(mod_fb_npc).

-include("mgeem.hrl").

-export([
         handle/1,
         handle/2
        ]).

%% ====================================================================
%% Macro
%% ====================================================================
-define(FB_NPC_ITEM_FETCH(PropId),{fb_npc_item_fetch,PropId}).
-define(NPC_TYPE_NORMAL,1).
-define(NPC_TYPE_FETCH_ITEM,2).



%% ====================================================================
%% Error Code
%% ====================================================================
-define(ERR_FB_NPC_NPC_ID_INVALID,10001).
-define(ERR_FB_NPC_MAP_ID_INVALID,10002).
-define(ERR_FB_NPC_FETCH_DUPLICATE,10003).
-define(ERR_FB_NPC_HAS_SAME_PROP,10004).
-define(ERR_FB_NPC_BAG_NOT_ENOUGH,10005).



%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).

handle({_, ?FB_NPC, ?FB_NPC_FETCH_ITEM,_,_,_,_}=Info) ->
    %% 进入国家战场
    do_fb_npc_fetch_item(Info);

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).


do_fb_npc_fetch_item({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_fb_npc_fetch_item_tos{npc_id=NpcId} = DataIn,
    case catch check_fb_npc_fetch_item(RoleID,DataIn) of
        {ok,RewardProp}->
            #p_reward_prop{prop_id=PropId} = RewardProp,
            TransFun = fun()->
                               common_bag2:t_reward_prop(RoleID, RewardProp, mission)
                       end,
            case common_transaction:t( TransFun ) of
                {atomic,{ok,NewGoodsList}}->
                    set_item_fetched(PropId),
                    %% 道具日志
                    lists:foreach(
                      fun(E)->
                              common_item_logger:log(RoleID,E,?LOG_ITEM_TYPE_HEROFB_NPC_FETCH)
                      end, NewGoodsList),
                    %% 通知背包变动
                    common_misc:new_goods_notify(PID, NewGoodsList),
                    R2 = #m_fb_npc_fetch_item_toc{npc_id=NpcId,prop=RewardProp},
                    ?UNICAST_TOC(R2);
				{aborted,{bag_error,{not_enough_pos,_BagID}}} ->
                    R2 = #m_fb_npc_fetch_item_toc{error_code=?ERR_FB_NPC_BAG_NOT_ENOUGH},
                    ?UNICAST_TOC(R2);
                {aborted,{error,ErrCode,Reason}}-> 
                    R2 = #m_fb_npc_fetch_item_toc{error_code=ErrCode,reason=Reason},
                    ?UNICAST_TOC(R2)
            end;
        {error,ErrCode,Reason}->
            R2 = #m_fb_npc_fetch_item_toc{error_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.
    

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
check_fb_npc_fetch_item(RoleID,DataIn)->
    #m_fb_npc_fetch_item_tos{npc_id=NpcId} = DataIn,
    [NpcList] = common_config_dyn:find(fb_npc,npc_list),
    case lists:keyfind(NpcId, #r_fb_npc.npc_id, NpcList) of
        #r_fb_npc{prop_id=PropId,map_id=MapId,npc_type=?NPC_TYPE_FETCH_ITEM,
                  num=Num,bind=Bind,color=Color}->
            case MapId =:= mgeem_map:get_mapid() of
                true->
                    assert_item_fetched(PropId),
                    case mod_bag:check_inbag_by_typeid(RoleID,PropId) of
                        {ok,_GoodsInfo}->
                            ?THROW_ERR(?ERR_FB_NPC_HAS_SAME_PROP);
                        _ ->
                            next
                    end;
                _ ->
                    ?THROW_ERR(?ERR_FB_NPC_MAP_ID_INVALID)
            end,
            PropType = common_misc:get_prop_type(PropId),
            RewardProp = #p_reward_prop{prop_id=PropId,prop_type=PropType,prop_num=Num,bind=Bind,color=Color},
            {ok,RewardProp};
        _ ->
            ?THROW_ERR(?ERR_FB_NPC_NPC_ID_INVALID),
            error
    end.
    
assert_item_fetched(PropId)->
    case get(?FB_NPC_ITEM_FETCH(PropId)) of
        undefined->
            next;
        _ ->
            ?THROW_ERR(?ERR_FB_NPC_FETCH_DUPLICATE)
    end.

set_item_fetched(PropId)->
    put(?FB_NPC_ITEM_FETCH(PropId),true),
    ok.

