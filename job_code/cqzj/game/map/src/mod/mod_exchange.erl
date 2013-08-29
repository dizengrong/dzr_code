%%%-------------------------------------------------------------------
%%% @author  Liangliang <Liangliang@gmail.com>
%%% @doc 交易
%%%
%%% @end
%%% Created : 27 May 2010 by  Liangliang <Liangliang@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_exchange).

-include("mgeem.hrl").

-export([
         handle/1,
         handle/2
        ]).

%% API
-export([
         init/0,
         role_offline/1,
         gen_json_goods_list/1
         ]).

-define(ETS_EXCHANGE_REQUEST, ets_exchange_request).
-define(ETS_EXCHANGE_FLOW, ets_exchange_flow).

%%目标方同意交易，交易开始
-define(EXCHANGE_STATE_AGREED, 2).
%%发起方提交了交易物品
-define(EXCHANGE_STATE_SRC_LOCK, 3).
%%目标方提交了交易物品
-define(EXCHANGE_STATE_TARGET_LOCK, 4).
%%双方都已经提交了交易物品
-define(EXCHANGE_STATE_BOTH_LOCK, 5).
%%发起方确认交易
-define(EXCHANGE_STATE_SRC_CONFIRM, 6).
%%目标方确认交易
-define(EXCHANGE_STATE_TARGET_CONFIRM, 7).

-define(CANCEL_TYPE_NORMAL, 1).
-define(CANCEL_TYPE_FIGHT, 2).
-define(CANCEL_TYPE_DISTANCE, 3).


%%%===================================================================
%%% API
%%%===================================================================

init() ->
    ets:new(?ETS_EXCHANGE_FLOW, [public, named_table, set]),
    ets:new(?ETS_EXCHANGE_REQUEST, [public, named_table, set]),
    ok.

%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).

role_offline(RoleID) ->
    do_role_offline(RoleID).

handle({Unique, Module, ?EXCHANGE_REQUEST, DataIn, RoleID, PID, Line}) ->
    do_request(Unique, Module, ?EXCHANGE_REQUEST, DataIn, RoleID, PID, Line);
handle({Unique, Module, ?EXCHANGE_AGREE, DataIn, RoleID, PID, Line}) ->
    do_accept(Unique, Module, ?EXCHANGE_AGREE, DataIn, RoleID, PID, Line);
handle({Unique, Module, ?EXCHANGE_REFUSE, DataIn, RoleID, PID, Line}) ->
    do_refuse(Unique, Module, ?EXCHANGE_REFUSE, DataIn, RoleID, PID, Line);
handle({Unique, Module, ?EXCHANGE_LOCK, DataIn, RoleID, PID, Line}) ->
    do_lock(Unique, Module, ?EXCHANGE_LOCK, DataIn, RoleID, PID, Line);
handle({Unique, Module, ?EXCHANGE_CONFIRM, DataIn, RoleID, PID, Line}) ->
    do_confirm(Unique, Module, ?EXCHANGE_CONFIRM, DataIn, RoleID, PID, Line);
handle({Unique, Module, ?EXCHANGE_CANCEL, DataIn, RoleID, PID, Line}) ->
    do_cancel(Unique, Module, ?EXCHANGE_CANCEL, DataIn, RoleID, PID, Line);
handle({Unique, Module, ?EXCHANGE_ACTIVE_DEAL, DataIn, RoleID, PID, Line}) ->
    mod_exchange_active_deal:handle({Unique, Module, ?EXCHANGE_ACTIVE_DEAL, DataIn, RoleID, PID, Line});

handle({Unique, Module, ?EXCHANGE_NPC_DEAL, DataIn, RoleID, PID, Line}) ->
    mod_exchange_npc_deal:handle({Unique, Module, ?EXCHANGE_NPC_DEAL, DataIn, RoleID, PID, Line});
handle({Unique, Module, ?EXCHANGE_EQUIP_INFO, DataIn, RoleID, PID, Line}) ->
    mod_exchange_npc_deal:handle({Unique, Module, ?EXCHANGE_EQUIP_INFO, DataIn, RoleID, PID, Line});
handle(Args) ->
    ?ERROR_MSG("~w, unknow args: ~w", [?MODULE,Args]),
    ok. 

-define(SEND_ERR_TOC_DEAL(RecName,Reason,Special),        
        R2 = #RecName{succ=false,reason=Reason,special_case=Special},common_misc:unicast(Line, RoleID, Unique, Module, Method, R2)
).
%% ====================================================================
%% Internal functions
%% ====================================================================

%%玩家下线则自动清理掉对应的记录
do_role_offline(RoleID) ->
    %%通知对应的玩家交易取消了
    case ets:lookup(?ETS_EXCHANGE_REQUEST, RoleID) of
        [{RoleID, OtherRoleID}] ->
            ets:delete(?ETS_EXCHANGE_REQUEST, RoleID),
            ets:delete(?ETS_EXCHANGE_REQUEST, OtherRoleID);
        _ ->
            ok
    end,
    case ets:lookup(?ETS_EXCHANGE_FLOW, RoleID) of
        [{RoleID, OID, _, _, _, _, _}] ->
            case db:transaction(
                   fun() ->
                           t_do_cancel(RoleID, OID)
                   end)
            of
                {atomic, _} ->
                    ets:delete(?ETS_EXCHANGE_FLOW, RoleID),
                    ets:delete(?ETS_EXCHANGE_FLOW, OID),
                    ROther = #m_exchange_cancel_toc{succ=true, return_self=false, reason=?_LANG_EXCHANGE_CANCEL},
                    common_misc:unicast({role, OID}, ?DEFAULT_UNIQUE, ?EXCHANGE, ?EXCHANGE_CANCEL, ROther);
                {aborted, R} ->
                    ?DEBUG("role_offline, r: ~w", [R]),
                    ok
            end;
        _ ->
            ignore
    end.

%%处理请求交易动作
do_request(Unique, Module, Method, DataIn, RoleID, PID, Line) ->
    #m_exchange_request_tos{target_roleid=TargetRoleIDTemp,special_case=Special} = DataIn,
    %%安全转化
    TargetRoleID = erlang:abs(TargetRoleIDTemp),
    %%判断本人能否交易，判断对方能否交易，判断双方是否在同一地图内，判断双方是否在可视范围内
    %%检查是否已经请求过了
    case RoleID =:= TargetRoleIDTemp of
        true ->
            ?SEND_ERR_TOC_DEAL(m_exchange_request_toc,?_LANG_EXCHANGE_REQUEST_SELF,Special);
        false ->
            case if_already_request(RoleID, TargetRoleID) of
                false ->
                    do_request2(Unique, Module, Method, TargetRoleID, Special,RoleID,PID, Line);
                true ->
                    ?SEND_ERR_TOC_DEAL(m_exchange_request_toc,?_LANG_EXCHANGE_ALREADY_REQUEST,Special)
            end
    end.
do_request2(Unique, Module, Method, TargetRoleID,Special, RoleID, PID, Line) ->
    case check_self_can_exchange(RoleID) of
        ok ->
            case check_other_can_exchange(TargetRoleID) of
                ok ->
                    do_request3(Unique, Module, Method, TargetRoleID, Special,RoleID, PID, Line);
                {error, Reason} ->
                    ?SEND_ERR_TOC_DEAL(m_exchange_request_toc,Reason,Special)
            end;
        {error, Reason} ->
            ?SEND_ERR_TOC_DEAL(m_exchange_request_toc,Reason,Special)
    end.
do_request3(Unique, Module, Method, TargetRoleID,Special, RoleID, PID, Line) ->
    case check_both_pos(RoleID, TargetRoleID) of
        {ok, RoleMapInfo, TargetRoleMap} ->
            do_request4(Unique, Module, Method, TargetRoleID, Special,RoleID, PID, Line, RoleMapInfo, TargetRoleMap);
        {error, Reason} ->
            ?SEND_ERR_TOC_DEAL(m_exchange_request_toc,Reason,Special)
    end.
do_request4(Unique, Module, Method, TargetRoleID,Special, RoleID, _PID, Line, RoleMapInfo, _TargetRoleMap) ->
    #p_map_role{role_name=SrcRoleName} = RoleMapInfo,
    %%插入一条记录
    ets:insert(?ETS_EXCHANGE_REQUEST, {RoleID, TargetRoleID}),
    %%通知双方结果
    RSelf = #m_exchange_request_toc{succ=true, return_self=true,special_case=Special},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, RSelf),
    ROther = #m_exchange_request_toc{succ=true, return_self=false, special_case=Special,
                                     src_role_id=RoleID, src_role_name=SrcRoleName},
    common_misc:unicast({role, TargetRoleID}, ?DEFAULT_UNIQUE, Module, Method, ROther).


%%接受交易请求
do_accept(Unique, Module, Method, DataIn, RoleID, PID, Line) ->
    #m_exchange_agree_tos{src_roleid=SrcRoleID,special_case=Special} = DataIn,
    %%检查是否真的有请求
    case if_has_request(RoleID, SrcRoleID) of
        true ->
            do_accept2(Unique, Module, Method, SrcRoleID, Special,RoleID, PID, Line);
        false ->
            Reason = ?_LANG_EXCHANGE_NO_REQUEST,
            do_accept_error(Unique, Module, Method, Reason, Special,RoleID, Line)
    end.
do_accept2(Unique, Module, Method, SrcRoleID, Special,RoleID, PID, Line) ->
    %%删除请求记录
    ets:delete(?ETS_EXCHANGE_REQUEST, SrcRoleID),
    case check_self_can_exchange(RoleID) of
        ok ->
            case check_other_can_exchange(SrcRoleID) of
                ok ->
                    do_accept3(Unique, Module, Method, SrcRoleID, Special,RoleID, PID, Line);
                {error, Reason} ->
                    do_accept_error(Unique, Module, Method, Reason,Special, RoleID, Line)
            end;
        {error, Reason} ->
            do_accept_error(Unique, Module, Method, Reason, Special,RoleID, Line)
    end.
do_accept3(Unique, Module, Method, SrcRoleID, Special,RoleID, PID, Line) ->
    case check_both_pos(RoleID, SrcRoleID) of
        {ok, RoleMapInfo, TargetRoleMap} ->
            do_accept4(Unique, Module, Method, SrcRoleID, Special,RoleID, PID, Line, RoleMapInfo, TargetRoleMap);
        {error, Reason} ->
            do_accept_error(Unique, Module, Method, Reason, Special,RoleID, Line)
    end.
do_accept4(Unique, Module, Method, SrcRoleID, Special,RoleID, _PID, Line, RoleMapInfo, _TargetRoleMap) ->
    case db:transaction(
           fun() ->
                   t_do_accept(SrcRoleID, RoleID)
           end)
    of
        {atomic, _} ->
            RequestList = ets:match(?ETS_EXCHANGE_REQUEST, {'$1', RoleID}),
            %%插入双方的信息记录，两条记录是为方便查找
            ets:insert(?ETS_EXCHANGE_FLOW, {RoleID, SrcRoleID, target, ?EXCHANGE_STATE_AGREED, 0, 0, []}),
            ets:insert(?ETS_EXCHANGE_FLOW, {SrcRoleID, RoleID, src, ?EXCHANGE_STATE_AGREED, 0, 0, []}),

            %%通知双方结果
            RSelf = #m_exchange_agree_toc{succ=true, return_self=true,special_case=Special},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, RSelf),
            #p_map_role{role_id=TRoleID, role_name=TRoleName} = RoleMapInfo,
            ROther = #m_exchange_agree_toc{succ=true, return_self=false,special_case=Special,
                                           target_role_id=TRoleID, target_role_name=TRoleName},
            common_misc:unicast({role, SrcRoleID}, ?DEFAULT_UNIQUE, Module, Method, ROther),

            %%通知其它邀请人，拒绝交易
            R = #m_exchange_refuse_toc{return_self=false, role_id=TRoleID, role_name=TRoleName,special_case=Special},
            lists:foreach(
              fun([RID]) ->
                      case RID =:= SrcRoleID of
                          true ->
                              ok;
                          _ ->
                              common_misc:unicast({role, RID}, ?DEFAULT_UNIQUE, Module, ?EXCHANGE_REFUSE, R)
                      end
              end, RequestList);
        {aborted, Reason} ->
            ?ERROR_MSG("~ts:[~w] -> ~w", ["脏读玩家信息失败", RoleID, Reason]),
            Reason2 = ?_LANG_SYSTEM_ERROR,
            do_accept_error(Unique, Module, Method, Reason2, Special,RoleID, Line)
    end.

do_accept_error(Unique, Module, Method, Reason,Special, RoleID, Line) ->
    R = #m_exchange_agree_toc{succ=false, reason=Reason,special_case=Special},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

t_do_accept(SrcRoleID, RoleID) ->
    [SrcRoleState] = db:read(?DB_ROLE_STATE, SrcRoleID, write),
    db:write(?DB_ROLE_STATE, SrcRoleState#r_role_state{exchange=true}, write),
    [RoleState] = db:read(?DB_ROLE_STATE, RoleID, write),
    db:write(?DB_ROLE_STATE, RoleState#r_role_state{exchange=true}, write).

%%拒绝交易请求
do_refuse(Unique, Module, Method, DataIn, RoleID, PID, Line) ->
    #m_exchange_refuse_tos{src_roleid=SrcRoleID,special_case=Special} = DataIn,
    case if_has_request(RoleID, SrcRoleID) of
        true ->
            do_refuse2(Unique, Module, Method, SrcRoleID,Special, RoleID, PID, Line);
        false ->
            ?DEBUG("~ts", ["对方没有请求，拒绝失败"]),
            Reason = ?_LANG_EXCHANGE_NO_REQUEST,
            do_refuse_error(Unique, Module, Method, Reason, Special,RoleID, Line)
    end.
do_refuse2(Unique, Module, Method, SrcRoleID, Special,RoleID, _PID, Line) ->
    ets:delete(?ETS_EXCHANGE_REQUEST, SrcRoleID),
    case mod_map_actor:get_actor_mapinfo(SrcRoleID, role) of
        undefined ->
            Reason2 = ?_LANG_SYSTEM_ERROR,
            do_refuse_error(Unique, Module, Method, Reason2, Special,RoleID, Line);
        #p_map_role{role_name=SrcRoleName} ->
            case mod_map_actor:get_actor_mapinfo(RoleID, role) of
                undefined ->
                    Reason2 = ?_LANG_SYSTEM_ERROR,
                    do_refuse_error(Unique, Module, Method, Reason2, Special,RoleID, Line);
                #p_map_role{role_name=RoleName} ->
                    RSelf = #m_exchange_refuse_toc{role_id=SrcRoleID, role_name=SrcRoleName,special_case=Special},
                    ROther = #m_exchange_refuse_toc{return_self=false, role_id=RoleID, role_name=RoleName,special_case=Special},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, RSelf),
                    common_misc:unicast({role, SrcRoleID}, Unique, Module, Method, ROther)
            end
    end.

do_refuse_error(Unique, Module, Method, Reason, Special,RoleID, Line) ->
    R = #m_exchange_refuse_toc{succ=false, reason=Reason,special_case=Special},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).

%%某方锁定交易物品
do_lock(Unique, Module, Method, DataIn, RoleID, PID, Line) ->
	#m_exchange_lock_tos{goods=Goods, silver=Silver, gold=Gold,special_case=Special} = DataIn,
	case check_can_exchange_silver(Silver) of
		true ->
			%%检查是否正在交易状态
			case if_in_exchange(RoleID) of
				true ->
					%%检查当前状态是否允许锁定
					case if_can_lock(RoleID) of
						true ->
							do_lock2(Unique, Module, Method, {Goods,Silver,Gold,Special}, RoleID, PID, Line);
						false ->
							Reason = ?_LANG_EXCHANGE_CANNT_LOCK,
							do_lock_error(Unique, Module, Method, Reason, Special,RoleID, Line)
					end;
				false ->
					Reason = ?_LANG_EXCHANGE_STATUS_ERROR,
					do_lock_error(Unique, Module, Method, Reason,Special, RoleID, Line)
			end;
		false ->
			Reason = ?_LANG_EXCHANGE_NOT_GOLD,
			do_lock_error(Unique, Module, Method, Reason,Special, RoleID, Line)
	end.

do_lock2(Unique, Module, Method, {Goods,Silver,Gold,Special}, RoleID, PID, Line) ->
    %%依次检查玩家是否有这些东西，且是否是不绑定的
    %%Goods如果包含物品，则是数字数组
    case Goods of
        undefined ->
            Goods2 = [];
        _ ->
            Goods2 = Goods
    end,
    case Gold >= 0 of
        true ->
            case Silver>=0 of
                true ->
                    case check_exchange_lock(RoleID, Goods2, Silver, Gold) of
                        ok ->
                            do_lock3(Unique, Module, Method, {Goods2, Silver, Gold},Special, RoleID, PID, Line);
                        {error, Reason} ->
                            do_lock_error(Unique, Module, Method, Reason, Special,RoleID, Line)
                    end;
                false ->
                    Reason = ?_LANG_EXCHANGE_MONEY_ERROR,
                    do_lock_error(Unique, Module, Method, Reason, Special,RoleID, Line)
            end;
        false ->
            Reason = ?_LANG_EXCHANGE_GOLD_MONEY_ERROR,
            do_lock_error(Unique, Module, Method, Reason, Special,RoleID, Line)
    end.

do_lock3(Unique, Module, Method, {Goods, Silver, Gold}, Special,RoleID, _PID, Line) ->
    %%更新ETS_EXCHANGE_FLOW表
    case ets:lookup(?ETS_EXCHANGE_FLOW, RoleID) of
        [{RoleID, OtherRoleID, Type, OldStatus, 0, 0, []}] ->
            case ets:lookup(?ETS_EXCHANGE_FLOW, OtherRoleID) of
                %%两条记录的status应该是一样的
                [{OtherRoleID, RoleID, OtherType, OldStatus, OtherSilver, OtherGold, OtherGoodsIdNumList}] ->
                    NewStatus = get_new_status_after_lock(Type, OldStatus),
                    %% 增加记录物品的交易数量，防止玩家通过一些途径修改交易物品来欺骗交易，
                    %% 真正交换时需检查数量跟背包中的数量是否一致
                    GoodsDetail = get_goods_detail(RoleID, Goods),
                    GoodsIdNumList = get_goods_id_num_list(GoodsDetail),
                    ets:insert(?ETS_EXCHANGE_FLOW, 
                               {RoleID, OtherRoleID, Type, NewStatus, Silver, Gold, GoodsIdNumList}),
                    ets:insert(?ETS_EXCHANGE_FLOW, 
                               {OtherRoleID, RoleID, OtherType, NewStatus, OtherSilver, OtherGold, OtherGoodsIdNumList}),
                    %%通知双方操作的结果
                    RSelf = #m_exchange_lock_toc{succ=true,special_case=Special},
                    ROther = #m_exchange_lock_toc{return_self=false, goods=GoodsDetail, silver=Silver, gold=Gold,special_case=Special},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, RSelf),
                    common_misc:unicast({role, OtherRoleID}, ?DEFAULT_UNIQUE, Module, Method, ROther);
                _ ->
                    Reason = ?_LANG_SYSTEM_ERROR,
                    do_lock_error(Unique, Module, Method, Reason, Special,RoleID, Line),
                    clear_exchange_flow(RoleID),
                    clear_exchange_flow(OtherRoleID)
            end;
        _ ->
            Reason = ?_LANG_SYSTEM_ERROR,
            do_lock_error(Unique, Module, Method, Reason, Special,RoleID, Line),
            clear_exchange_flow(RoleID)
    end.

%%处理锁定物品的错误信息
do_lock_error(Unique, Module, Method, Reason, Special,RoleID, Line) ->
    R = #m_exchange_lock_toc{succ=false, reason=Reason,special_case=Special},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


%%处理确认交易请求
do_confirm(Unique, Module, Method, DataIn, RoleID, PID, Line) ->
    #m_exchange_confirm_tos{special_case=Special} = DataIn,
    case catch check_exchange_can_confirm(RoleID) of
        true ->
            do_confirm2(Unique, Module, Method, Special,RoleID, PID, Line);
        {error, may_has_confirm} ->
            Reason = ?_LANG_EXCHANGE_STATUS_ERROR_MAY_HAS_CONFIRM,
            do_confirm_error(Unique, Module, Method, Reason, Special,RoleID, Line);
        {error, exchange_data_corrupted, {RoleID, OtherRoleID}} ->
            {ok, #p_role_base{role_name=RoleName}} = mod_map_role:get_role_base(RoleID),
            Reason = common_misc:format_lang(?_LANG_EXCHANGE_FAILED_WITH_CORRUPTED_DATA,[RoleName]),
            clear_exchange_flow(RoleID, Reason),
            clear_exchange_flow(OtherRoleID, Reason)
    end.
do_confirm2(Unique, Module, Method, Special,RoleID, PID, Line) ->
    case ets:lookup(?ETS_EXCHANGE_FLOW, RoleID) of
        [{RoleID, OtherRoleID, Type, State, Silver, Gold, Goods}] ->
            case (Type =:= src andalso State =:= ?EXCHANGE_STATE_TARGET_CONFIRM) orelse 
                (Type =:= target andalso State =:= ?EXCHANGE_STATE_SRC_CONFIRM) 
            of
                false ->
                    do_confirm3(Unique, Module, Method,Special,
                                {RoleID, OtherRoleID, Type, State, Silver, Gold, Goods}, PID, Line);
                %%本交易可以结束了
                true ->
                    do_confirm4(Unique, Module, Method,Special,
                                {RoleID, OtherRoleID, Type, State, Silver, Gold, Goods}, PID, Line)
            end;
        _ ->
            Reason = ?_LANG_EXCHANGE_STATUS_ERROR,
            do_confirm_error(Unique, Module, Method, Reason, Special,RoleID, Line)
    end.
do_confirm3(Unique, Module, Method, Special,{RoleID, OtherRoleID, Type, State, Silver, Gold, Goods}, _PID, Line) ->
    case ets:lookup(?ETS_EXCHANGE_FLOW, OtherRoleID) of
        [{OtherRoleID, RoleID, OtherType, State, OtherSilver, OtherGold, OtherGoods}] ->
            NewState = get_new_state_after_confirm(Type),
            ets:insert(?ETS_EXCHANGE_FLOW, {RoleID, OtherRoleID, Type, NewState, Silver, Gold, Goods}),
            ets:insert(?ETS_EXCHANGE_FLOW, {OtherRoleID, RoleID, OtherType, NewState, OtherSilver, OtherGold, OtherGoods}),
            %%通知双方本次操作的结果
            RSelf = #m_exchange_confirm_toc{special_case=Special},
            ROther = #m_exchange_confirm_toc{return_self=false,special_case=Special},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, RSelf),
            common_misc:unicast({role, OtherRoleID}, ?DEFAULT_UNIQUE, Module, Method, ROther);
        _ ->
            Reason = ?_LANG_EXCHANGE_STATUS_ERROR,
            do_confirm_error(Unique, Module, Method, Reason, Special,RoleID, Line),
            clear_exchange_flow(RoleID),
            clear_exchange_flow(OtherRoleID)
    end.
do_confirm4(Unique, Module, Method, Special,{RoleID, OtherRoleID, _Type, State, Silver, Gold, Goods}, _PID, Line) ->
    case ets:lookup(?ETS_EXCHANGE_FLOW, OtherRoleID) of
        [{OtherRoleID, RoleID, _OtherType, State, OtherSilver, OtherGold, OtherGoods}] ->
            case do_exchange(RoleID, OtherRoleID,{Silver, Gold, Goods}, 
                             {OtherSilver, OtherGold, OtherGoods}) of
                ok ->
                    ets:delete(?ETS_EXCHANGE_FLOW, RoleID),
                    ets:delete(?ETS_EXCHANGE_FLOW, OtherRoleID),
                    %%通知双方结果
                    RSelf = #m_exchange_confirm_toc{special_case=Special},
                    ROther = #m_exchange_confirm_toc{return_self=false,special_case=Special},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, RSelf),
                    common_misc:unicast({role, OtherRoleID}, ?DEFAULT_UNIQUE, Module, Method, ROther),
                    ok;
                {{error, Reason}, {error, Reason2}} ->
                    RSelf = #m_exchange_confirm_toc{succ=false, reason=Reason,special_case=Special},
                    common_misc:unicast(Line, RoleID, Unique, Module, Method, RSelf),
                    ets:delete(?ETS_EXCHANGE_FLOW, RoleID),
                    ets:delete(?ETS_EXCHANGE_FLOW, OtherRoleID),

                    R = #m_exchange_cancel_toc{special_case=Special},
                    common_misc:unicast(Line, RoleID, ?DEFAULT_UNIQUE, Module, ?EXCHANGE_CANCEL, R),
                    R2 = #m_exchange_cancel_toc{succ=true, return_self=false, reason=Reason2,special_case=Special},
                    common_misc:unicast({role, OtherRoleID}, ?DEFAULT_UNIQUE, ?EXCHANGE, ?EXCHANGE_CANCEL, R2)
            end;
        _ ->
            Reason = ?_LANG_EXCHANGE_STATUS_ERROR,
            do_confirm_error(Unique, Module, Method, Reason, Special,RoleID, Line)
    end.


do_confirm_error(Unique, Module, Method, Reason, Special,RoleID, Line) ->
    R = #m_exchange_confirm_toc{succ=false, reason=Reason,special_case=Special},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, R).


%%取消交易
do_cancel(Unique, Module, Method, DataIn, RoleID, _PID, Line) ->
    #m_exchange_cancel_tos{src_roleid=SrcRoleID, cancel_type=Type,special_case=Special} = DataIn,
    case db:transaction(
           fun() ->
                   t_do_cancel(SrcRoleID, RoleID)
           end)
    of
        {atomic, _} ->
            %%删除摆摊标记
            ets:delete(?ETS_EXCHANGE_FLOW, RoleID),
            ets:delete(?ETS_EXCHANGE_FLOW, SrcRoleID),

            %%通知客户端
            RSelf = #m_exchange_cancel_toc{special_case=Special},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, RSelf),

            %%不同的取消类型，提示不同
            case Type of
                ?CANCEL_TYPE_NORMAL ->
                    Reason = ?_LANG_EXCHANGE_CANCEL;
                ?CANCEL_TYPE_FIGHT ->
                    Reason = ?_LANG_EXCHANGE_CANCEL_FIGHT;
                ?CANCEL_TYPE_DISTANCE ->
                    Reason = ?_LANG_EXCHANGE_CANCEL_DISTANCE
            end,
            ROther = #m_exchange_cancel_toc{succ=true, return_self=false, reason=Reason,special_case=Special},
            common_misc:unicast({role, SrcRoleID}, ?DEFAULT_UNIQUE, ?EXCHANGE, ?EXCHANGE_CANCEL, ROther);
        {aborted, R} ->
            ?DEBUG("do_cancel, r: ~w", [R]),
            RSelf = #m_exchange_cancel_toc{succ=false, reason=?_LANG_SYSTEM_ERROR,special_case=Special},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, RSelf)
    end.

%%取消角色摆摊状态
t_do_cancel(SrcRoleID, RoleID) ->
    [SrcRoleState] = db:read(?DB_ROLE_STATE, SrcRoleID, write),
    db:write(?DB_ROLE_STATE, SrcRoleState#r_role_state{exchange=false}, write),
    [RoleState] = db:read(?DB_ROLE_STATE, RoleID, write),
    db:write(?DB_ROLE_STATE, RoleState#r_role_state{exchange=false}, write).

clear_role_exchange_state(RoleID, TargetID) ->
    case db:transaction(
           fun() ->
                   t_do_cancel(RoleID, TargetID)
           end)
    of
        {atomic, _} ->
            ignore;
        {aborted, Error} ->
            ?ERROR_MSG("clear_role_exchagne_state, error: ~w", [Error])
    end.
        
%%真正交易双方物品和金钱，事务检查！！
do_exchange(RoleID, OtherRoleID,{Silver, Gold, Goods}, {OtherSilver, OtherGold, OtherGoods}) ->
    ?DEBUG("~ts:~w, ~w", ["双方达成都已经确认，交易物品为", Silver, OtherSilver]),
    %%清除角色交易状态
    clear_role_exchange_state(RoleID, OtherRoleID),
    
    case db:transaction(
           fun() ->
                   t_exchange(RoleID, OtherRoleID,{Silver, Gold, Goods}, {OtherSilver, OtherGold, OtherGoods})
           end) 
        of
        {atomic, Result} ->
            ?DEBUG("~ts", ["交易成功"]),
            {RoleName, OtherRoleName, Goods2, OtherGoods2, Goods3, OtherGoods3} = Result,
            %%交易日志
            ExchangeLog = #r_exchange_log{from_role_id=RoleID, from_role_name=RoleName, 
                                          from_silver=Silver, from_goods= gen_json_goods_list(Goods2),
                                          from_gold=Gold,to_gold=OtherGold,
                                          to_role_id=OtherRoleID, to_role_name=OtherRoleName, 
                                          to_silver=OtherSilver, to_goods= gen_json_goods_list(OtherGoods2),
                                          time=common_tool:now()},
            common_general_log_server:log_exchange(ExchangeLog),
            %% 道具消费日志
            case OtherGoods3 of
                [] ->
                    ignore;
                _ ->
                    lists:foreach(
                      fun(GoodsInfo) ->
                              common_item_logger:log(RoleID,GoodsInfo,?LOG_ITEM_TYPE_JIAO_YI_SHI_QU),
                              common_item_logger:log(OtherRoleID,GoodsInfo,?LOG_ITEM_TYPE_JIAO_YI_HUO_DE)
                      end, Goods2)
            end,

            %% 通知客户端物品变化
            case Goods3 of
                [] ->
                    ignore;
                _ ->
                    lists:foreach(
                      fun(GoodsInfo) ->
                              common_item_logger:log(OtherRoleID,GoodsInfo,?LOG_ITEM_TYPE_JIAO_YI_SHI_QU),
                              common_item_logger:log(RoleID,GoodsInfo,?LOG_ITEM_TYPE_JIAO_YI_HUO_DE)
                      end, Goods3),
                              
                    hook_prop:hook(create, Goods3),
                    common_misc:new_goods_notify({role, RoleID}, Goods3)
            end,
            case OtherGoods3 of
                [] ->
                    ignore;
                _ ->
                    hook_prop:hook(create, OtherGoods3),
                    common_misc:new_goods_notify({role, OtherRoleID}, OtherGoods3)
            end,
            {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
            {ok, OtherRoleAttr} = mod_map_role:get_role_attr(OtherRoleID),
            ChangeList = [
                          #p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value=RoleAttr#p_role_attr.gold},
                          #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value=RoleAttr#p_role_attr.gold_bind},
                          #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value=RoleAttr#p_role_attr.silver},
                          #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value=RoleAttr#p_role_attr.silver_bind}],
            common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
            OtherChangeList = [
                               #p_role_attr_change{change_type=?ROLE_GOLD_CHANGE, new_value=OtherRoleAttr#p_role_attr.gold},
                               #p_role_attr_change{change_type=?ROLE_GOLD_BIND_CHANGE, new_value=OtherRoleAttr#p_role_attr.gold_bind},
                               #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value=OtherRoleAttr#p_role_attr.silver},
                               #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value=OtherRoleAttr#p_role_attr.silver_bind}],
            common_misc:role_attr_change_notify({role, OtherRoleID}, OtherRoleID, OtherChangeList),
            ok;
            
        {aborted, Detail} ->
            case Detail of
                {error, db_error} ->
                    {{error, ?_LANG_SYSTEM_ERROR}, {error, ?_LANG_SYSTEM_ERROR}};
                {throw, {error, bag_not_enough}} ->
                    {{error, ?_LANG_EXCHANGE_BAG_NOT_ENOUGH}, {error, ?_LANG_EXCHANGE_OTHER_BAG_NOT_ENOUGH}};
                {throw, {error, other_bag_not_enough}} ->
                    {{error, ?_LANG_EXCHANGE_OTHER_BAG_NOT_ENOUGH}, {error, ?_LANG_EXCHANGE_BAG_NOT_ENOUGH}};
                {error, good_bind} ->
                    {{error, ?_LANG_EXCHANGE_GOODS_ERROR}, {error, ?_LANG_EXCHANGE_GOODS_ERROR}};
                {error, good_not_found} ->
                    {{error, ?_LANG_EXCHANGE_GOODS_ERROR}, {error, ?_LANG_EXCHANGE_GOODS_ERROR}};
                {error, good_data_corrupt} ->
                    {{error, ?_LANG_EXCHANGE_GOODS_ERROR}, {error, ?_LANG_EXCHANGE_GOODS_ERROR}};
                {error, not_enough_money} ->
                    {{error, ?_LANG_EXCHANGE_MONEY_NOT_ENOUGH}, {error, ?_LANG_EXCHANGE_OTHER_MONEY_NOT_ENOUGH}};
                {error, other_not_enough_money} ->
                    {{error, ?_LANG_EXCHANGE_OTHER_MONEY_NOT_ENOUGH}, {error, ?_LANG_EXCHANGE_MONEY_NOT_ENOUGH}};
                Other ->
                    ?ERROR_MSG("~ts:~w", ["交易失败", Other]),
                    {{error, ?_LANG_SYSTEM_ERROR}, {error, ?_LANG_SYSTEM_ERROR}}
            end
    end.


t_exchange(RoleID, OtherRoleID, {Silver, Gold, Goods}, {OtherSilver, OtherGold, OtherGoods}) ->
    {RoleName, OtherRoleName} = t_exchange_money(RoleID, Silver, Gold, OtherRoleID, OtherSilver, OtherGold),
    t_exchange_goods(RoleID, OtherRoleID, Goods, OtherGoods, RoleName, OtherRoleName).

%%交易物品
t_exchange_goods(RoleID, OtherRoleID, GoodsIdNumList, OtherGoodsIdNumList, RoleName, OtherRoleName) ->
    %% 检测是否有绑定物品
    Goods = get_goods_idlist(GoodsIdNumList),
    OtherGoods =  get_goods_idlist(OtherGoodsIdNumList),
    Goods2 = t_has_not_bind_goods(RoleID, GoodsIdNumList),
    OtherGoods2 = t_has_not_bind_goods(OtherRoleID, OtherGoodsIdNumList),

    {ok, _} = mod_bag:delete_goods(RoleID, Goods),
    {ok, _} = mod_bag:delete_goods(OtherRoleID, OtherGoods),
    {ok, Goods3} = 
        try
            mod_bag:create_goods_by_p_goods(RoleID, OtherGoods2)
        catch
            _:{bag_error, {not_enough_pos,_BagID}} ->
                throw({error, bag_not_enough})
        end,
    {ok, OtherGoods3} = 
        try
            mod_bag:create_goods_by_p_goods(OtherRoleID, Goods2)
        catch
            _:Error->
                case Error of
                    {bag_error, {not_enough_pos,_}} ->
                        throw({error, other_bag_not_enough});
                    _ ->
                        throw({error, other_bag_not_enough})
                end
        end,

    {RoleName, OtherRoleName, Goods2, OtherGoods2, Goods3, OtherGoods3}.

get_goods_idlist(GoodIdNumList) ->
    lists:map(fun({GoodId, _}) -> GoodId end, GoodIdNumList).

%%根据物品的id列表获得物品的详细信息列表
get_goods_detail(RoleID, Goods) ->
    lists:foldl(
      fun(GoodsID, Acc0) ->
              case mod_bag:check_inbag(RoleID, GoodsID) of
                  {ok, GoodsDetail} ->
                      [GoodsDetail | Acc0];
                  {error, _} ->
                      Acc0
              end
      end, [], Goods).

get_goods_id_num_list(GoodsDetails) ->
    lists:map(
      fun(Goods) ->
              {Goods#p_goods.id, Goods#p_goods.current_num}
      end, GoodsDetails).

%% 判断是否有绑定的物品
t_has_not_bind_goods(RoleID, GoodIdNumList) ->
    lists:foldl(
      fun({GoodsID, ExpectNum}, Acc) ->
              case mod_bag:check_inbag(RoleID, GoodsID) of
                  {ok, GoodsInfo} ->
                      case GoodsInfo#p_goods.bind of
                          true ->
                              db:abort({error, good_bind});
                          _ ->
                              case GoodsInfo#p_goods.current_num =:= ExpectNum of
                                  true ->
                                      [GoodsInfo|Acc];
                                  false ->
                                      db:abort({error, good_data_corrupt})
                              end
                      end;
                  {error, _} ->
                      db:abort({error, good_not_found})
              end
      end, [], GoodIdNumList). 

%%交易钱财
t_exchange_money(RoleID, Silver, Gold, OtherRoleID, OtherSilver, OtherGold) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    {ok, OtherRoleAttr} = mod_map_role:get_role_attr(OtherRoleID),
    %%只要有金钱交易，则需要读取双方玩家的信息
    case (Silver > 0 orelse OtherSilver > 0 orelse Gold > 0 orelse OtherGold > 0) of
        true ->
            t_exchange_money2(RoleAttr, OtherRoleAttr, Silver, OtherSilver, Gold, OtherGold);
        false ->
            {RoleAttr#p_role_attr.role_name, OtherRoleAttr#p_role_attr.role_name}
    end.
t_exchange_money2(RoleAttr, OtherRoleAttr, Silver, OtherSilver, Gold, OtherGold) ->
    %%检查双方是不是都有足够的钱，钱的数量必须是非负数，这个在锁定时就已经检查了！
    #p_role_attr{silver=S, gold=G} = RoleAttr,
    #p_role_attr{silver=OS, gold=OG} = OtherRoleAttr,
    case (S>=Silver andalso OS>=OtherSilver andalso G >=Gold andalso OG>=OtherGold) of
        true ->
            ?DEBUG("~ts", ["交易需要的货币够了"]),
            NewS = S - Silver + OtherSilver,
            NewOS = OS - OtherSilver + Silver,

            NewG = G - Gold + OtherGold,
            NewOG = OG - OtherGold + Gold,

            RoleID = RoleAttr#p_role_attr.role_id,
            OtherRoleID = OtherRoleAttr#p_role_attr.role_id,
            case NewS > S of
                true ->
                    common_consume_logger:gain_silver({RoleID, 0, NewS-S, ?GAIN_TYPE_SILVER_FROM_EXCHANGE,
                                                       ""}),
                    common_consume_logger:use_silver({OtherRoleID, 0, OS-NewOS, ?CONSUME_TYPE_SILVER_FROM_EXCHANGE,
                                                      ""});
                _ ->
                    common_consume_logger:gain_silver({OtherRoleID, 0, NewOS-OS, ?GAIN_TYPE_SILVER_FROM_EXCHANGE,
                                                       ""}),
                    common_consume_logger:use_silver({RoleID, 0, S-NewS, ?CONSUME_TYPE_SILVER_FROM_EXCHANGE,
                                                      ""})
            end,
            case NewG > G of
                true ->
                    common_consume_logger:gain_gold({RoleID, 0, NewG-G, ?GAIN_TYPE_GOLD_FROM_EXCHANGE,
                                                       ""},OtherRoleID),
                    common_consume_logger:use_gold({OtherRoleID, 0, OG-NewOG, ?CONSUME_TYPE_GOLD_FROM_EXCHANGE,
                                                      ""},RoleID);
                _ ->
                    common_consume_logger:gain_gold({OtherRoleID, 0, NewOG-OG, ?GAIN_TYPE_GOLD_FROM_EXCHANGE,
                                                       ""},RoleID),
                    common_consume_logger:use_gold({RoleID, 0, G-NewG, ?CONSUME_TYPE_GOLD_FROM_EXCHANGE,
                                                      ""},OtherRoleID)
            end,
            %%应该要检查是否超出了携带上限
            NewRoleAttr = RoleAttr#p_role_attr{silver=NewS, gold=NewG},
            NewOtherRoleAttr = OtherRoleAttr#p_role_attr{silver=NewOS, gold=NewOG},
            mod_map_role:set_role_attr(RoleID, NewRoleAttr),
            mod_map_role:set_role_attr(OtherRoleID, NewOtherRoleAttr),
            
            {NewRoleAttr#p_role_attr.role_name, NewOtherRoleAttr#p_role_attr.role_name};
        false ->
            %%判断是谁的钱不够
            case (S<Silver orelse G < Gold) of
                true->
                    db:abort({error, not_enough_money});
                false ->
                    db:abort({error, other_not_enough_money})
            end
    end.

%%检查交易是否存在，是否能够确认
check_exchange_can_confirm(RoleID) ->
    case ets:lookup(?ETS_EXCHANGE_FLOW, RoleID) of
        [{RoleID, OtherRoleID, Type, State, Silver, Gold, GoodsIdNumList}] ->
            HaveEnoughGoods = lists:all(fun({GoodsID, ExpectNum}) ->
                                                check_goods_exist_bind_num(RoleID, GoodsID, ExpectNum) end, GoodsIdNumList),
            HaveEnoughMoney = check_role_has_money(RoleID, Silver, Gold),
            case {HaveEnoughGoods, HaveEnoughMoney} of
                {true, true} ->
                    (State =:= ?EXCHANGE_STATE_BOTH_LOCK) 
                        orelse (Type =:= src andalso State =:= ?EXCHANGE_STATE_TARGET_CONFIRM) 
                        orelse (Type =:= target andalso State =:= ?EXCHANGE_STATE_SRC_CONFIRM);
                _ -> 
                    erlang:throw({error, exchange_data_corrupted, {RoleID, OtherRoleID}})
            end;
        _ ->
            erlang:throw({error, may_has_confirm})
    end.


%%出错之后直接从ets中清理掉该玩家的交易信息，并通知玩家交易被取消了
clear_exchange_flow(RoleID) ->
    ets:delete(?ETS_EXCHANGE_FLOW, RoleID),
    R = #m_exchange_cancel_toc{succ=true, return_self=false, reason=?_LANG_SYSTEM_ERROR},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXCHANGE, ?EXCHANGE_CANCEL, R).

clear_exchange_flow(RoleID, Reason) ->
    ets:delete(?ETS_EXCHANGE_FLOW, RoleID),
    R = #m_exchange_cancel_toc{succ=true, return_self=false, reason=Reason},
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?EXCHANGE, ?EXCHANGE_CANCEL, R).

%%获得某一方确认后的新状态
get_new_state_after_confirm(Type) ->
    case Type of
        src ->
            ?EXCHANGE_STATE_SRC_CONFIRM;
        target ->
            ?EXCHANGE_STATE_TARGET_CONFIRM
    end.


%%获得锁定之后的新状态
get_new_status_after_lock(Type, OldStatus) ->
    case Type of
        src ->
            case OldStatus of
                ?EXCHANGE_STATE_AGREED ->
                    ?EXCHANGE_STATE_SRC_LOCK;
                ?EXCHANGE_STATE_TARGET_LOCK ->
                    ?EXCHANGE_STATE_BOTH_LOCK
            end;
        target ->
            case OldStatus of
                ?EXCHANGE_STATE_AGREED ->
                    ?EXCHANGE_STATE_TARGET_LOCK;
                ?EXCHANGE_STATE_SRC_LOCK ->
                    ?EXCHANGE_STATE_BOTH_LOCK
            end
    end.


%%检查玩家是否能够锁定交易，锁定操作只能进行一次
if_can_lock(RoleID) ->
    case ets:lookup(?ETS_EXCHANGE_FLOW, RoleID) of
        [{RoleID, _, Type, CurStatus, _, _, _}] ->
            case (CurStatus =:= ?EXCHANGE_STATE_AGREED) orelse 
                (Type =:= src andalso CurStatus =:= ?EXCHANGE_STATE_TARGET_LOCK) orelse
                (Type =:= target andalso CurStatus =:= ?EXCHANGE_STATE_SRC_LOCK)
            of
                true ->
                    true;
                false ->
                    false
            end;
        _ ->
            false
    end.


%%检查玩家是否处于交易状态中
if_in_exchange(RoleID) ->
    case ets:lookup(?ETS_EXCHANGE_FLOW, RoleID) of
        [{RoleID, _, _, _, _, _, _}] ->
            true;
        _ ->
            false
    end.


%%检查玩家提交的锁定物品是不是真的都有，这里检查一次，真正进行交易的时候必须再事务检查一次！！
check_exchange_lock(RoleID, Goods, Silver, Gold) ->
    GoodsRight = lists:foldl(
                   fun(GoodID, Acc0) ->
                           case check_goods_exist_bind(GoodID, RoleID) of
                               true ->
                                   Acc0;
                               false ->
                                   false
                           end
                   end, true, Goods),
    case GoodsRight of
        true ->
            case check_role_has_money(RoleID, Silver, Gold) of
                true ->
                    ok;
                false ->
                    {error, ?_LANG_EXCHANGE_NOT_HAS_ENOUGH_MONEY}
            end;
        false ->
            {error, ?_LANG_EXCHANGE_NO_GOODS}
    end.


%%检查玩家是否有足够的钱
check_role_has_money(RoleID, Silver, Gold) ->
    case mod_map_role:get_role_attr(RoleID) of
        {ok, #p_role_attr{silver=S, gold=G}} ->
            S>=Silver andalso G >= Gold;
        _ ->
            false
    end.


%%检查交易物品是否存在，是否是不绑定的
check_goods_exist_bind(GoodsID, RoleID) ->
    case mod_bag:check_inbag(RoleID, GoodsID) of
        {ok, GoodsDetail} ->
            %%检查是否绑定了
            case GoodsDetail#p_goods.bind of
                true ->
                    false;
                false ->
                    %%检查是不是该玩家拥有
                    case GoodsDetail#p_goods.roleid =:= RoleID of
                        true ->
                            true;
                        false ->
                            false
                    end
            end;
        {error, _} ->
            false
    end.

check_goods_exist_bind_num(RoleID, GoodsID, ExpectNum) ->
    case mod_bag:check_inbag(RoleID, GoodsID) of
        {ok, GoodsDetail} ->
            #p_goods{bind=Bind,roleid=GoodsRoleID,current_num=ActualNum} = GoodsDetail,
            case {Bind, GoodsRoleID =:= RoleID, ActualNum =:= ExpectNum} of
                {false, true, true} ->
                    true;
                _ ->
                    false
            end;
        {error, _} ->
            false
    end.

if_has_request(RoleID, SrcRoleID) ->
    case ets:lookup(?ETS_EXCHANGE_REQUEST, SrcRoleID) of
        [{SrcRoleID, RoleID}] ->
            true;
        _ ->
            false
    end.


if_already_request(RoleID, TargetRoleID) ->
    case ets:lookup(?ETS_EXCHANGE_REQUEST, RoleID) of
        [{RoleID, TargetRoleID}] ->
            true;
        _ ->
            false
    end.

%%检查某个玩家自己能不能进行交易
check_self_can_exchange(RoleID) ->
    case ets:lookup(?ETS_EXCHANGE_FLOW, RoleID) of
        [_] ->
            {error, ?_LANG_EXCHANGE_ROLE_EXCHANGING};
        _ ->
            case mod_map_role:get_role_base(RoleID) of
                {ok, #p_role_base{status=?ROLE_STATE_FIGHT}} ->
                    {error, ?_LANG_EXCHANGE_ROLE_FIGHTING};
                {ok, #p_role_base{status=?ROLE_STATE_DEAD}} ->
                    {error, ?_LANG_EXCHANGE_ROLE_DEAD};
                _ ->
                    check_self_can_exchange2(RoleID)
            end
    end.
check_self_can_exchange2(RoleID) ->
    case common_misc:get_dirty_role_state(RoleID) of
        {error, Reason} ->
            {error, Reason};
        {ok, RoleState} ->
            case RoleState#r_role_state.stall_self of
                true ->
                    {error, ?_LANG_EXCHANGE_ROLE_STALL};
                _ ->
                    ok
            end
    end.


%%检查对方是否能够交易，和上面函数的主要区别是提示不同 
check_other_can_exchange(RoleID) ->
    case ets:lookup(?ETS_EXCHANGE_FLOW, RoleID) of
        [_] ->
            {error, ?_LANG_EXCHANGE_ROLE_EXCHANGING_TARGET};
        _ ->
            case mod_map_role:get_role_base(RoleID) of
                {ok, #p_role_base{status=?ROLE_STATE_FIGHT}} ->
                    {error, ?_LANG_EXCHANGE_ROLE_FIGHTING_TARGET};
                {ok, #p_role_base{status=?ROLE_STATE_DEAD}} ->
                    {error, ?_LANG_EXCHANGE_ROLE_DEAD_TARGET};
                _ ->
                    check_other_can_exchange2(RoleID)
            end
    end.
check_other_can_exchange2(RoleID) ->
    case common_misc:get_dirty_role_state(RoleID) of
        {error, Reason} ->
            {error, Reason};
        {ok, RoleState} ->
            case RoleState#r_role_state.stall_self of
                true ->
                    {error, ?_LANG_EXCHANGE_TARGET_STALL};
                _ ->
                    ok
            end
    end.


%%检查交易双方的位置信息是否合法
check_both_pos(RoleID, TargetRoleID) ->
    case mod_map_actor:get_actor_mapinfo(RoleID, role) of
        undefined ->
            {error, ?_LANG_EXCHANGE_OVER_DISTANCE};
        RoleMapInfo ->
            case mod_map_actor:get_actor_mapinfo(TargetRoleID, role) of
                undefined ->
                    {error, ?_LANG_EXCHANGE_OVER_DISTANCE};
                TargetRoleMapInfo ->
                    check_both_pos2(RoleMapInfo, TargetRoleMapInfo)
            end
    end.
check_both_pos2(RoleMapInfo, TargetRoleMapInfo) ->
    #p_map_role{pos=#p_pos{tx=TX, ty=TY}} = RoleMapInfo,
    #p_map_role{pos=#p_pos{tx=TX2, ty=TY2}} = TargetRoleMapInfo,

    {PX, PY} = common_misc:get_iso_index_mid_vertex(TX, 0, TY),
    {PX2, PY2} = common_misc:get_iso_index_mid_vertex(TX2, 0, TY2),
    case  not (erlang:abs(PX-PX2) > 500 orelse erlang:abs(PY-PY2) > 280) of
        true ->
            {ok, RoleMapInfo, TargetRoleMapInfo};
        _ ->
            {error, ?_LANG_EXCHANGE_OVER_DISTANCE}
    end.

%% empty_role_bag_pos(RoleID, Goods) ->
%%     lists:foreach(
%%       fun(Good) ->
%%               #p_goods{bagid=BagID, bagposition=Pos} = Good,
%%               common_bag:bag_position_empty({RoleID, BagID, Pos})
%%       end, Goods).

%% use_role_bag_pos(RoleID, Goods) ->
%%     lists:foreach(
%%       fun(Good) ->
%%               #p_goods{bagid=BagID, bagposition=Pos} = Good,
%%               common_bag:bag_position_used({RoleID, BagID, Pos})
%%       end, Goods).

%%@doc 交易/信件交易的时候，将物品的信息转换为Json
gen_json_goods_list(GoodsList) ->
    GoodsExchange = lists:map(fun(Goods)->
                                      case Goods#p_goods.type of
                                          ?TYPE_EQUIP ->
                                              StonesIdList = case is_list(Goods#p_goods.stones) of
                                                                 true-> [common_tool:to_list(Ele#p_goods.typeid) || Ele <- Goods#p_goods.stones];
                                                                 _ -> []
                                                             end,
                                              ConcatStoneIds = string:join(StonesIdList,","),
                                              [{id,Goods#p_goods.typeid},{num,Goods#p_goods.current_num},
                                               {punch_num,Goods#p_goods.punch_num},{stones,ConcatStoneIds},
                                               {rein_id,Goods#p_goods.reinforce_result},
                                               {color,Goods#p_goods.current_colour},{fineness,Goods#p_goods.quality}];
                                          _ ->
                                              [{id,Goods#p_goods.typeid},{num,Goods#p_goods.current_num}]
                                      end
                              end, GoodsList),
    common_json2:to_json( GoodsExchange ).

check_can_exchange_silver(Silver) ->
	case Silver > 0 of
		true ->
			[CanExchange] = common_config_dyn:find(etc, silver),
			case CanExchange of
				true ->
					true;
				_ ->
					false
			end;
		_ ->
			true
	end.
