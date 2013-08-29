%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     神游三界/月光宝盒的Manager-Server
%%% @end
%%%-------------------------------------------------------------------
-module(mod_treasbox_manager).
-behaviour(gen_server).


-export([
         start/0,
         start_link/0
        ]).
-export([
         reload/0,
         create_p_goods/3,
         create_box_equip_p_goods/2
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl").

%% ====================================================================
%% Macro
%% ====================================================================
%%每分钟更新在线时长,单位为分钟
-define(PERSISTENT_LOG_INTERVAL, 200 * 1000).
-define(MSG_PERSISTENT_BOX_LOG, msg_persistent_box_log).

-record(r_box_goods_cache,{role_category = [],role_sex = [],role_level=[], goods}).
-define(TREASBOX_PRODUCTIONS_CACHE,treasbox_productions_cache).
-define(DEFAULT_BOX_GOODS_ID,999998).
-define(ALL_BOX_LOG_LIST,all_box_log_list).
-define(LAST_BOX_LOG_LIST,last_box_log_list).
-define(max_box_log_num,16).

-define(find_config(Key),common_config_dyn:find(get_config_name(),Key)).



%% ====================================================================
%% API functions
%% ====================================================================



%% ====================================================================
%% External functions
%% ====================================================================

start() ->
    {ok,_} = supervisor:start_child(mgeew_sup, 
                           {?MODULE, 
                            {?MODULE, start_link,[]},
                            permanent, 30000, worker, [?MODULE]}).
    

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [],[]).

init([]) ->
    erlang:process_flag(trap_exit, true),
    init_box_logs(),
    
    erlang:send_after(?PERSISTENT_LOG_INTERVAL, self(), ?MSG_PERSISTENT_BOX_LOG),
    
    {ok, []}.

reload()->
    global:send(?MODULE, {clear_reload}),
    ok.
 
 
%% ====================================================================
%% Server functions
%%      gen_server callbacks
%% ====================================================================
handle_call(Call, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Call, State),
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
 

do_handle_call(_) ->
    error.


do_handle_info({do_treasbox_show_list,InterfaceInfo,RemainSilverTimes,IsBoxOpen,Category,Level,Sex,BoxLevel,BoxScore}) ->
    do_treasbox_show_list(InterfaceInfo,RemainSilverTimes,IsBoxOpen,Category,Level,Sex,BoxLevel,BoxScore);
do_handle_info({do_treasbox_show_log,InterfaceInfo,RemainSilverTimes,IsBoxOpen}) ->
    do_treasbox_show_log(InterfaceInfo,RemainSilverTimes,IsBoxOpen);

do_handle_info({add_role_box_log,_RoleID,BoxLog}) ->
    add_role_box_log(BoxLog);
do_handle_info({clear_reload}) ->
    do_clear_reload();
do_handle_info(?MSG_PERSISTENT_BOX_LOG) ->
    do_persistent_box_log();
do_handle_info(Info)->
    ?ERROR_MSG("receive unknown message,Info=~w",[Info]),
    ignore.

do_clear_reload()->
	[FullLevel] = ?find_config(full_level),
	lists:foreach(fun(Level) ->
						  erlang:erase( {?TREASBOX_PRODUCTIONS_CACHE,1,Level} ),
						  erlang:erase( {?TREASBOX_PRODUCTIONS_CACHE,2,Level} ),
						  erlang:erase( {?TREASBOX_PRODUCTIONS_CACHE,3,Level} ),
						  erlang:erase( {?TREASBOX_PRODUCTIONS_CACHE,4,Level} ),
						  erlang:erase( {?TREASBOX_PRODUCTIONS_CACHE,5,Level} ),
						  erlang:erase( {?TREASBOX_PRODUCTIONS_CACHE,6,Level} )
				  end, lists:seq(1, FullLevel)),
	ok.

do_persistent_box_log()->
    erlang:send_after(?PERSISTENT_LOG_INTERVAL, self(), ?MSG_PERSISTENT_BOX_LOG),
    
    case get_all_box_log_list() of
        undefined-> ignore;
        []-> ignore;
        LogList->
            case get(?LAST_BOX_LOG_LIST) =:= LogList of
                true-> ignore;
                _ ->
                    put(?LAST_BOX_LOG_LIST,LogList),
                    db:clear_table(?DB_TREASBOX_LOG_P),
                    ?TRY_CATCH( [ db:dirty_write(?DB_TREASBOX_LOG_P, Log)  ||Log<-LogList ] )
            end
    end.

init_box_logs()->
    Pattern = #p_treasbox_log{_='_'},
    List = db:dirty_match_object(?DB_TREASBOX_LOG_P,Pattern),
    put(?ALL_BOX_LOG_LIST,List),
    ok.

add_role_box_log(BoxLog)->
    case get(?ALL_BOX_LOG_LIST) of
        undefined->
            put(?ALL_BOX_LOG_LIST,[BoxLog]);
        LogList->
            NewLogList3 = lists:sublist([BoxLog|LogList], ?max_box_log_num),
            put(?ALL_BOX_LOG_LIST,NewLogList3)
    end.

get_all_box_log_list()->
    case get(?ALL_BOX_LOG_LIST) of
        undefined-> [];
        LogList-> LogList
    end.

do_treasbox_show_log(InterfaceInfo,RemainSilverTimes,IsBoxOpen)->
    {Unique, Module, Method, DataIn, _RoleID, PID, _Line} = InterfaceInfo,
    #m_treasbox_show_tos{op_type=OpType,op_fee_type=OpFeeType} = DataIn,
    
    CanUseGold = can_use_gold(),
    OtherLogList = get_all_box_log_list(),
    R2 = #m_treasbox_show_toc{op_type=OpType,op_fee_type=OpFeeType,is_open=IsBoxOpen,can_use_gold=CanUseGold,
                              remain_silver_times=RemainSilverTimes,
                              other_log_list=OtherLogList},
    ?UNICAST_TOC(R2).
 
do_treasbox_show_list(InterfaceInfo,RemainSilverTimes,IsBoxOpen,Category,Level,Sex,BoxLevel,BoxScore)->
    {Unique, Module, Method, DataIn, _RoleID, PID, _Line} = InterfaceInfo,
    #m_treasbox_show_tos{op_type=OpType,op_fee_type=OpFeeType} = DataIn,
    CanUseGold = can_use_gold(),
    Productions = get_productions_by_op_fee_type(OpFeeType,Category,Level,Sex,BoxLevel),
    OtherLogList = get_all_box_log_list(),
    % equip_productions
    EquipProductions = get_equip_productions(OpFeeType,Category,Level,Sex,BoxLevel),
    R2 = #m_treasbox_show_toc{op_type=OpType,op_fee_type=OpFeeType,is_open=IsBoxOpen,can_use_gold=CanUseGold,
                              remain_silver_times=RemainSilverTimes,productions=Productions,
                              other_log_list=OtherLogList,box_level=BoxLevel,box_score=BoxScore,
							  can_upgrade=mod_treasbox:treasbox_can_upgrade(Level,BoxLevel,BoxScore),
                equip_productions = EquipProductions},
    ?UNICAST_TOC(R2).

get_equip_productions(OpFeeType,_Category,_RoleLevel,_Sex,_BoxLevel) ->
    [GoodList1] = ?find_config({equip_goods_probability,OpFeeType}),
    lists:foldl(fun(H, Acc) ->
        case create_p_goods(OpFeeType,H,true) of
            {error, _} -> Acc;
            {ok, [NewGoods]} ->
                % #r_box_goods_probability{role_category=RoleCategory,role_sex=RoleSex,role_level=RoleLevel} = H,
                NewGoods2 = NewGoods#p_goods{id = ?DEFAULT_BOX_GOODS_ID,roleid = 1,bagid = 0,bagposition = 0},
                [NewGoods2|Acc]
                % GoodsCache = #r_box_goods_cache{role_category=RoleCategory,role_sex=RoleSex,role_level=RoleLevel,goods=NewGoods2},
                % make_productions_cache_2(OpFeeType,T,[GoodsCache|Acc])
        end
    end, [], GoodList1).


%%根据类型判断宝箱产出列表
get_productions_by_op_fee_type(OpFeeType,Category,Level,Sex,BoxLevel)->
    {ok,CacheList} = get_productions_cache(OpFeeType,BoxLevel),
    get_productions_by_op_fee_type_2(CacheList,Category,Level,Sex,[]).

get_productions_by_op_fee_type_2([],_Category,_Level,_Sex,Acc)->
    Acc;
get_productions_by_op_fee_type_2([H|T],Category,Level,Sex,Acc)->
    #r_box_goods_cache{role_category=RoleCategory,role_sex=RoleSex,role_level=RoleLevel,goods=Goods} = H,
    case RoleSex =:= [] orelse lists:member(Sex, RoleSex) of 
        true->
            case RoleCategory =:=[] orelse lists:member(Category, RoleCategory) of
                true->
                    case is_role_level_match(RoleLevel,Level) of
                        true->
                            get_productions_by_op_fee_type_2(T,Category,Level,Sex,[Goods|Acc]);
                        _ ->
                            get_productions_by_op_fee_type_2(T,Category,Level,Sex,Acc)
                    end;
                _ ->
                    get_productions_by_op_fee_type_2(T,Category,Level,Sex,Acc)
            end;
        _ ->
            get_productions_by_op_fee_type_2(T,Category,Level,Sex,Acc)
    end.

%%判断境界是否匹配
is_role_level_match([],_)->
    true;
is_role_level_match([Min,Max],Level)->
    Min =< Level andalso Max >= Level.

get_productions_cache(OpFeeType,BoxLevel)->
    case get({?TREASBOX_PRODUCTIONS_CACHE,OpFeeType,BoxLevel}) of
        undefined->
            List = make_productions_cache(OpFeeType,BoxLevel),
            put({?TREASBOX_PRODUCTIONS_CACHE,OpFeeType,BoxLevel},List);
        List->
            List
    end,
    {ok,List}.
make_productions_cache(OpFeeType,BoxLevel)->
	case ?find_config({box_goods_probability,OpFeeType}) of
		[BoxGoodsProbListTmp] ->
			case lists:keyfind(BoxLevel, 1, BoxGoodsProbListTmp) of
				false -> [];
				{BoxLevel,BoxGoodsProbList} ->
					make_productions_cache_2(OpFeeType,BoxGoodsProbList,[])
			end;
		_ ->
			[]
	end.
make_productions_cache_2(_OpFeeType,[],Acc)->
    Acc;
make_productions_cache_2(OpFeeType,[H|T],Acc)->
    case create_p_goods(OpFeeType,H,true) of
        {error, _} ->
            make_productions_cache_2(OpFeeType,T,Acc);
        {ok, [NewGoods]} ->
            #r_box_goods_probability{role_category=RoleCategory,role_sex=RoleSex,role_level=RoleLevel} = H,
            NewGoods2 = NewGoods#p_goods{id = ?DEFAULT_BOX_GOODS_ID,roleid = 1,bagid = 0,bagposition = 0},
            GoodsCache = #r_box_goods_cache{role_category=RoleCategory,role_sex=RoleSex,role_level=RoleLevel,goods=NewGoods2},
            make_productions_cache_2(OpFeeType,T,[GoodsCache|Acc])
    end.
     
can_use_gold() ->
    case common_config_dyn:find_common(gold_box_close) of
        [true]->
            false;
        _ ->
            true
    end.
  
get_config_name() ->
    treasbox.
%% get_config_name() ->
%%     case common_config:get_opened_days() > 3 of
%%         true ->
%%             treasbox;
%%         false ->
%%             treasbox_3day
%%     end.


%% 根据r_box_goods_probability创建p_goods
%% 返回 {ok,p_goods} or {error,Reason}
create_p_goods(_OpFeeType,BoxGoodsProbability,Bind) ->
    #r_box_goods_probability{item_id = ItemId,item_type = ItemType,item_number = ItemNumber, item_bind = _ItemBind,
                             start_time = PStartTime,end_time = PEndTime,days = PDays} = BoxGoodsProbability,
    % Bind = 
    %     if ItemBind =:= 1 ->
    %             true;
    %        ItemBind =:= 2 ->
    %             false;
    %        true ->
    %            {MoneyType,_} = get_box_fee(OpFeeType),
    %            MoneyType =/= gold_unbind
    %     end,
    NowSeconds = common_tool:now(),
    {StartTime,EndTime} = 
        if PStartTime =:= 0 andalso PEndTime =:= 0 andalso PDays =/= 0 ->
                {NowSeconds - 5, NowSeconds + 24*60*60 * PDays};
           PStartTime =/= 0 andalso PEndTime =/= 0 andalso PDays =:= 0 ->
                {PStartTime,PEndTime};
           PStartTime =:= 0 andalso PEndTime =/= 0 andalso PDays =:= 0 ->
                {NowSeconds - 5,PEndTime};
           true ->
                {0,0}
        end,
    if ItemType =:= ?TYPE_EQUIP ->
           %% 需要根据装备概率计算装备的属性
           EquipCreateInfo = #r_equip_create_info{num=ItemNumber,typeid = ItemId,bind=Bind,start_time = StartTime,end_time = EndTime},
           mod_equip:creat_equip(EquipCreateInfo);
           % create_box_equip_p_goods(EquipCreateInfo,BoxGoodsProbability);
       ItemType =:= ?TYPE_STONE ->
           CreateInfo = #r_stone_create_info{num=ItemNumber,typeid = ItemId,bind=Bind,start_time = StartTime,end_time = EndTime},
           common_bag2:creat_stone(CreateInfo);
       ItemType =:= ?TYPE_ITEM ->
           CreateInfo = #r_item_create_info{num = ItemNumber,typeid = ItemId,bind=Bind,start_time = StartTime,end_time = EndTime},
           common_bag2:create_item(CreateInfo);
       true ->
           {error,item_type_error}
    end.
%% 创建箱子装备物品
create_box_equip_p_goods(EquipCreateInfo,BoxGoodsProbability) ->
	#r_box_goods_probability{use_bind = PUseBind,equip_probability_id = EquipProbabilityId} = BoxGoodsProbability,
	#r_equip_create_info{bind=Bind} = EquipCreateInfo,
	EquipBind = 
		case Bind =:= true of
			true ->
				UseBind = 0,
				Bind;
			_ ->
				if PUseBind =:= 1 ->
					   UseBind = 1,
					   false;
				   true ->
					   UseBind = 0,
					   Bind
				end
		end,
	[BoxEquipProbabilityList] = ?find_config(box_equip_probability),
	BoxEquipProbabilityRecord = 
		case lists:keyfind(EquipProbabilityId,#r_box_equip_probability.id,BoxEquipProbabilityList) of
			false ->
				lists:keyfind(0,#r_box_equip_probability.id,BoxEquipProbabilityList);
			BoxEquipProbabilityTT ->
				BoxEquipProbabilityTT
		end,
	EquipCreateInfo2 = EquipCreateInfo#r_equip_create_info{bind = EquipBind},
	CreateInfo = get_equip_create_info(BoxEquipProbabilityRecord,EquipCreateInfo2),
	case common_bag2:creat_equip_without_expand(CreateInfo) of
		{ok,EquipGoodsList} ->
			EquipGoodsList2 = 
				lists:foldl(
				  fun(EquipGoods,AccEquipGoodsList) ->
						  NewEquipGoods = EquipGoods#p_goods{bind = EquipBind,use_bind = UseBind},
						  [NewEquipGoods#p_goods{stones = []}|AccEquipGoodsList]
				  end,[],EquipGoodsList),
			{ok,EquipGoodsList2};
		{error,EquipError} ->
			{error,EquipError}
	end.

%% 箱子物品是装备，即需要计算装备的概率属性
%% 返回 r_equip_create_info
get_equip_create_info(BoxEquipProbabilityRecord,EquipCreateInfo) ->
    #r_equip_create_info{typeid = TypeId} = EquipCreateInfo,
    #r_box_equip_probability{
          color = _ColorList,
          quality = QualityList,
          sub_quality = SubQualityList,
          reinforce = ReinforceList,
          punch_num = PunchNumList} = BoxEquipProbabilityRecord,
    [EquipBaseInfo] = common_config_dyn:find_equip(TypeId),
    case EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT
        orelse EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION of
        true ->
            Color = 1,Quality = 1,SubQuality = 1;
        _ ->
            Quality = mod_refining:get_random_number(QualityList,0,1),
            SubQuality = mod_refining:get_random_number(SubQualityList,0,1),
            Color = mod_refining_tool:get_equip_color_by_quality(Quality,SubQuality)
    end,
    if ReinforceList =:= [] ->
            ReinforceResultList = [],
            ReinforceResult = 0,
            ReinforceRate = 0;
       true ->
            ReinforceWeightList = [Weight || {Weight,_ReinforceResultListT} <- ReinforceList],
            ReinforceWeightIndex = mod_refining:get_random_number(ReinforceWeightList,0,0),
            if ReinforceWeightIndex =< 0 ->
                    ReinforceResultList = [],
                    ReinforceResult = 0,
                    ReinforceRate = 0;
               true ->
                   {_Weight,ReinforceResultList} = lists:nth(ReinforceWeightIndex,ReinforceList),
                   case erlang:is_list(ReinforceResultList) andalso  ReinforceResultList =/= [] andalso erlang:length(ReinforceResultList) > 0 of
                       true ->
                           ReinforceResult = lists:max(ReinforceResultList),
                           ReinforceLevel = ReinforceResult div 10,
                           ReinforceGrade = ReinforceResult rem 10,
                           [ReinforceRateList] = common_config_dyn:find(refining,reinforce_rate),
                           {_,ReinforceRate} = lists:keyfind({ReinforceLevel,ReinforceGrade},1,ReinforceRateList);
                       _ ->
                           ReinforceResult = 0,
                           ReinforceRate = 0
                   end
            end
    end,
    PunchNum =  mod_refining:get_random_number(PunchNumList,0,0),
    EquipCreateInfo#r_equip_create_info{color=Color,quality=Quality,sub_quality = SubQuality,
                                        punch_num=PunchNum,rate=ReinforceRate,
                                        result=ReinforceResult,result_list=ReinforceResultList}.

%% 检查开箱子类型，并返回该类型的详细消耗信息
% get_box_fee(OpFeeType) ->
%     [BoxFeeList] = ?find_config(box_fee),
%     {OpFeeType,BoxOpenFee} = lists:keyfind(OpFeeType,1,BoxFeeList),
%     BoxOpenFee.
