%%%-------------------------------------------------------------------
%%% @author wuzesen
%%% @doc
%%%     PVE副本的通用接口和逻辑
%%% @end
%%% Created : 2011-6-16
%%%-------------------------------------------------------------------
-module(mod_pve_fb).

-include("mgeem.hrl").

-export([
         handle/1,
         handle/2
        ]).

-export([
         remove_pve_fb_buffs/2,
         init/2,
         hook_role_quit/1,
         hook_role_before_quit/1,
         hook_role_enter/2
        ]).


%% ====================================================================
%% Macro
%% ====================================================================
-define(BUY_BUFF_TYPE_SILVER,1).
-define(BUY_BUFF_TYPE_GOLD,2).
-define(BUY_BUFF_TYPE_GOLD_UNBIND,3).
-define(PVE_FB_MAP_INFO,pve_fb_map_info).
-define(PVE_FB_ROLE_ADD_BUFFS,pve_fb_role_add_buffs).

-record(r_pve_fb_map_info,{is_buy_buff_fb_map=false, map_id}).


%% ====================================================================
%% Error Code
%% ====================================================================

-define(ERR_PVE_FB_NOT_IN_FB_MAP,10101).
-define(ERR_PVE_FB_ROLE_NOT_IN_MAP,10102).
-define(ERR_PVE_FB_ROLE_VIP_NOT_AVARIABLE,10103).
-define(ERR_PVE_FB_ROLE_FB_NOT_AVARIABLE,10104).
-define(ERR_PVE_FB_ROLE_FB_BUFF_DUPLICATE,10105).
-define(ERR_PVE_FB_BUY_SILVER_ANY_NOT_ENOUGH,10110).
-define(ERR_PVE_FB_BUY_GOLD_ANY_NOT_ENOUGH,10111).



%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).

handle({_, ?PVE_FB, ?PVE_FB_BUY_BUFF,_,_,_,_}=Info) ->
    %% 购买PVE的副本BUFF
    do_pve_fb_buy_buff(Info);

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

init(MapId, _MapName) ->
    case is_buy_buff_fb_map(MapId) of
        true->
            FbMapInfo = #r_pve_fb_map_info{is_buy_buff_fb_map=true,map_id = MapId},
            put(?PVE_FB_MAP_INFO,FbMapInfo),
            ok;
        _ ->
            ignore
    end.



%% 玩家进入地图
hook_role_enter(RoleID,MapId) ->
    case is_in_buy_buff_fb() of
        true->
            %%弹出购买BUFF的接口
            case mod_map_actor:get_actor_mapinfo(RoleID, role) of
                #p_map_role{vip_level=VipLevel}->
                    case get_pve_fb_buff_list(VipLevel,MapId) of
                        []->
                            ignore;
                        FbBuffList ->
                            R2C = #m_pve_fb_buff_list_toc{buff_list=FbBuffList},
                            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PVE_FB, ?PVE_FB_BUFF_LIST,R2C)
                    end;
                _ ->
                    ignore
            end;
        _ ->
            ignore
    end.

%%@doc 判断是否是可以购买PVE副本的BUFF的地图
is_in_buy_buff_fb()->
    case get(?PVE_FB_MAP_INFO) of
        #r_pve_fb_map_info{is_buy_buff_fb_map=true}->
            true;
        _ ->
            false
    end.

%%@doc 判断是否是可以购买PVE副本的BUFF的地图
is_buy_buff_fb_map(MapId)->
    case common_config_dyn:find(pve_fb,{fb_buy_buff,MapId}) of
        [BuffList] when is_list(BuffList)->
            true;
        _ ->
            false
    end.

hook_role_quit(RoleID)->
    case is_in_buy_buff_fb() of
        true->
            #r_pve_fb_map_info{map_id=MapId} = erase(?PVE_FB_MAP_INFO),
            remove_pve_fb_buffs(RoleID,MapId);
        _ ->
            ignore
    end.

hook_role_before_quit(RoleID)->
    case is_in_buy_buff_fb() of
        true->
            #r_pve_fb_map_info{map_id=MapId} = erase(?PVE_FB_MAP_INFO),
            remove_pve_fb_buffs(RoleID,MapId),
            ok;
        _ ->
            ignore
    end.



%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

do_pve_fb_buy_buff({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_pve_fb_buy_buff_tos{type=Type} = DataIn,
    
    case catch check_pve_fb_buy_buff(DataIn,RoleID) of
        {ok,MoneyType,CostMoney,BuffIdList}->
            TransFun = fun()-> 
                               t_deduct_buy_buff_money(MoneyType,CostMoney,RoleID)
                       end,
            case common_transaction:t( TransFun ) of
                {atomic, {ok,RoleAttr2}} ->
                    case MoneyType of
                        ?BUY_BUFF_TYPE_SILVER->
                            common_misc:send_role_silver_change(RoleID,RoleAttr2);
                        _ ->
                            common_misc:send_role_gold_change(RoleID,RoleAttr2)
                    end,
                    lists:foreach(
                      fun(BuffId)-> 
                              mod_role_buff:add_buff(RoleID,BuffId)
                      end, BuffIdList),
                    
                    R2 = #m_pve_fb_buy_buff_toc{type=Type},
                    ?UNICAST_TOC(R2);
                {aborted, {error,ErrCode,Reason}} ->
                    R2C = #m_pve_fb_buy_buff_toc{type=Type,err_code=ErrCode,reason=Reason},
                    ?UNICAST_TOC(R2C)
            end;
        {error,ErrCode,Reason}->
            R2 = #m_pve_fb_buy_buff_toc{type=Type,err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

%%@return {ok,MoneyType,CostMoney,BuffIdList}
check_pve_fb_buy_buff(DataRecord,RoleID)->
    #m_pve_fb_buy_buff_tos{type=Type} = DataRecord,
    CurMapId = mgeem_map:get_mapid(),
    
    % case mod_map_actor:get_actor_mapinfo(RoleID,role) of
    %     #p_map_role{vip_level=VipLevel1}->
    %         ok;
    %     _ ->
    %         VipLevel1 = 0,
    %         ?THROW_ERR( ?ERR_PVE_FB_ROLE_NOT_IN_MAP )
    % end,
    
    case common_config_dyn:find(pve_fb,{fb_buy_buff,CurMapId}) of
        [ConfBuffList] ->
            next;
        _ ->
            ConfBuffList = [],
            ?THROW_ERR( ?ERR_PVE_FB_ROLE_FB_NOT_AVARIABLE )
    end,
    case lists:keyfind(Type, #r_pve_fb_buff_info.type, ConfBuffList) of
        #r_pve_fb_buff_info{money_type=MoneyType,cost_money=CostMoney,
                           buff_id_list=BuffIdList}->
            ok;
        _ ->
            MoneyType = CostMoney = BuffIdList = null,
            ?THROW_ERR( ?ERR_PVE_FB_ROLE_VIP_NOT_AVARIABLE )
    end,
    
    % if
    %     VipLevel1=:=0->
    %         VipLevel = 1;
    %     true->
    %         VipLevel = VipLevel1
    % end,
    % TypeIdx = get_pve_buff_type_idx(Type,ConfBuffList),
           
    % if
    %     TypeIdx>(VipLevel+1)->
    %         ?THROW_ERR( ?ERR_PVE_FB_ROLE_VIP_NOT_AVARIABLE );
    %     true->
    %         ignore
    % end,
    
    case mod_map_role:get_role_base(RoleID) of
        {ok,#p_role_base{buffs=RoleBuffs}}->
            RoleFbBuffCount = 
                lists:foldl(
                  fun(E,AccIn)->
                          #p_actor_buf{buff_id=BuffId} = E,
                          case lists:member(BuffId, BuffIdList) of
                              true-> AccIn+1;
                              _ ->
                                  AccIn
                          end     
                  end, 0, RoleBuffs),
            case RoleFbBuffCount =:= length(BuffIdList) of
                true->
                    ?THROW_ERR( ?ERR_PVE_FB_ROLE_FB_BUFF_DUPLICATE );
                _ ->
                    next
            end;
        _ ->
            ?THROW_ERR( ?ERR_PVE_FB_ROLE_FB_NOT_AVARIABLE ),
            ignore
    end,
    {ok,MoneyType,CostMoney,BuffIdList}.

%%获取购买的BUFF对应的Idx，只有相应的VIP等级才能购买
% get_pve_buff_type_idx(Type,ConfBuffList) when is_list(ConfBuffList)->
%     TypeIdList = [ ETypeId||#r_pve_fb_buff_info{type=ETypeId}<-ConfBuffList],
%     get_pve_buff_type_idx(0,Type,TypeIdList).

% get_pve_buff_type_idx(Idx,_Type,[])->
%     Idx;
% get_pve_buff_type_idx(Idx,Type,[H|T])->
%     if
%         Type=:=H->
%             Idx;
%         true->
%             get_pve_buff_type_idx(Idx,Type,T)
%     end.

%%扣除钱币/元宝
t_deduct_buy_buff_money(BuyBuffType,DeductMoney,RoleID)->
    case BuyBuffType of
        ?BUY_BUFF_TYPE_SILVER->
            MoneyType      = silver_any,
            ConsumeLogType = ?CONSUME_TYPE_SILVER_PVE_FB_BUY_BUFF;
        ?BUY_BUFF_TYPE_GOLD ->
            MoneyType      = gold_any,
            ConsumeLogType = ?CONSUME_TYPE_GOLD_PVE_FB_BUY_BUFF;
        ?BUY_BUFF_TYPE_GOLD_UNBIND ->
            MoneyType      = gold_unbind,
            ConsumeLogType = ?CONSUME_TYPE_GOLD_PVE_FB_BUY_BUFF
    end,
    case common_bag2:t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeLogType) of
        {ok,RoleAttr2}->
            {ok,RoleAttr2};
        {error,silver_any}->
            ?THROW_ERR( ?ERR_PVE_FB_BUY_SILVER_ANY_NOT_ENOUGH );
        {error,gold_any}->
            ?THROW_ERR( ?ERR_PVE_FB_BUY_GOLD_ANY_NOT_ENOUGH );
        {error, Reason} ->
            ?THROW_ERR(?ERR_OTHER_ERR, Reason);
        _ ->
            ?THROW_SYS_ERR()
    end. 


%%@doc 根据VIP等级、副本地图来获取对应的副本BUFF列表
get_pve_fb_buff_list(0,MapId)->
    get_pve_fb_buff_list(1,MapId);  %%非VIP的话，当VIP1来处理
get_pve_fb_buff_list(VipLevel,MapId)->
     VipLevel2 = erlang:min(VipLevel, 3),
    BuffListNum = VipLevel2+1,       %%不同的VIP等级可以购买的BUFF数量不一样
    case common_config_dyn:find(pve_fb,{fb_buy_buff,MapId}) of
        [ConfBuffList1]->
            ConfBuffList2 = lists:sublist(ConfBuffList1, BuffListNum),
            [ #p_pve_fb_buff_info{type=TypeId,money_type=MoneyType,cost_money=CostMoney} 
                                 ||#r_pve_fb_buff_info{type=TypeId,money_type=MoneyType,cost_money=CostMoney}<- ConfBuffList2];
        _ ->
            []
    end.

remove_pve_fb_buffs(RoleID, MapId) when is_integer(MapId) ->
    case common_config_dyn:find(pve_fb,{fb_buy_buff, MapId}) of
        [] -> ignore;
        [BuffList] ->
            Fun = fun(FbBuff, Acc) ->
                FbBuff#r_pve_fb_buff_info.buff_id_list ++ Acc
            end,
            BuffIdList = lists:foldl(Fun, [], BuffList),
            mod_role_buff:del_buff(RoleID, BuffIdList)
    end;


remove_pve_fb_buffs(RoleID,ConfBuffIdList) when is_list(ConfBuffIdList)->
    case mod_map_role:get_role_base(RoleID) of
        {ok, #p_role_base{buffs=RoleBuffs}}->
            DelRoleBuffIdList = 
                lists:foldl(
                  fun(E,AccIn)->
                          #p_actor_buf{buff_id=Id} = E,
                          case lists:member(Id,ConfBuffIdList) of
                              true-> [Id|AccIn];
                              _ ->
                                  AccIn
                          end
                  end, [], RoleBuffs),
            case DelRoleBuffIdList of
                []->    ignore;
                _ -> 
                    remove_pve_fb_buffs_2(RoleID,DelRoleBuffIdList),
                    refresh_role_buffs(RoleID)
            end;
        _ ->
            ignore
    end.

remove_pve_fb_buffs_2(RoleID,BuffIdList)->
    mod_role_buff:del_buff(RoleID,BuffIdList).

refresh_role_buffs(RoleID)->
    case mod_map_role:get_role_base(RoleID) of
        {ok, RoleBase}->
            R2C = #m_role2_base_reload_toc{role_base=RoleBase},
            common_misc:unicast2_direct(
              {role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_BASE_RELOAD, R2C),
            ok;
        _ ->
            ignore
    end.  