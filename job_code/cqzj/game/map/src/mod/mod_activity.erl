%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     处理活动子模块（包括今日活动、活动福利、经验找回、首冲和累计充值的礼包奖励等）
%%% @end
%%% Created : 2010-12-17
%%%-------------------------------------------------------------------
-module(mod_activity).

-include("mgeem.hrl").
-include("dynamic_monster.hrl").
-include("activity.hrl").

%% API
-export([
         handle/1,
		 handle/2,
         loop/2,
         get_act_task_donetimes/3,
         hook_role_online/1,
         hook_role_title_change/3,
         is_in_drunk_time/1,
         add_to_acc_pay/2,
         send_dingzi_info_to_client/1,
         hook_use_gold/1,send_first_use_letter/1
         ]).

%% export for role_misc callback
-export([init/2, delete/1, init_dingzi/2, delete_dingzi/1]).

-export([do_today/1, do_get_pay_single_gift/6]).

-define(DEFAULT_ACTIVITY_TYPE,1).

-define(ACTPOINT_REWARD_LIMIT_TIME_START,{0,0,0}).
-define(ACTPOINT_REWARD_LIMIT_TIME_END,{0,10,0}).

-define(ACTIVITY_NOTICE_FLAG, activity_notice).

%%每日福利新规则添加，每日活动最大次数
-define(ACTIVITY_MAX_TiME, 10).

-define(CAST_ERROR(Reason, DataIn),
		common_misc:unicast2(PID, Unique, Module, Method, #m_activity_getgift_toc{succ=false, reason=Reason,
                                                                                  id=DataIn#m_activity_getgift_tos.id,
                                                                                  type=DataIn#m_activity_getgift_tos.type})).

-define(CAN_FETCH_EXP_BACK, 0).
-define(ALREADY_FETCH_EXP_BACK, 1).

-define(ROLE_NOT_CONFIRM_EXP_BACK_FLAG, 0).
-define(ROLE_CONFIRM_EXP_BACK_FLAG, 1).

-define(GIFT_FIRST_PAY, 1).
-define(GIFT_ACCUMULATE_PAY, 2).
-define(GIFT_COLLECT_PURPLE, 3).
-define(GIFT_NEWCOMER, 4).

-record(dingzi_conf, {
    id        = 0,      %% 唯一序号
    next_id   = 0,      %% 下一个唯一序号
    need_gold = 0,      %% 需要元宝
    items     = []      %% [{物品id, 数量, 物品类型(1,2,3), 是否绑定(true|false)}]
    }).

%%%===================================================================
%%% API
%%%===================================================================

init(RoleID, PayDataRec) ->
    case PayDataRec of
        false -> 
            PayDataRec1 = #r_pay_data{};
        _ -> 
            PayDataRec1 = PayDataRec
    end,
    mod_role_tab:put({r_pay_data, RoleID}, PayDataRec1).

delete(RoleID) ->
    mod_role_tab:erase({r_pay_data, RoleID}).

init_dingzi(RoleID, DingziRec) ->
    case DingziRec of
        false -> 
            DingziRec1 = #r_dingzi{};
        _ -> 
            DingziRec1 = DingziRec
    end,
    mod_role_tab:put({r_dingzi, RoleID}, DingziRec1).

delete_dingzi(RoleID) ->
    mod_role_tab:erase({r_dingzi, RoleID}).

add_to_acc_pay(RoleID, PayGold) ->
    case PayGold > 0 of
        true ->
            PayDataRec  = mod_role_tab:get({r_pay_data, RoleID}),
            PayDataRec1 = PayDataRec#r_pay_data{acc_payed = PayDataRec#r_pay_data.acc_payed + PayGold},
            mod_role_tab:put({r_pay_data, RoleID}, PayDataRec1);
        false ->
            ?ERROR_MSG("玩家~w充值数据异常，PayGold: ~w", [RoleID, PayGold])
    end.

hook_use_gold([]) -> ok;
hook_use_gold([#r_consume_log{type=gold,role_id=RoleID,use_unbind=UseUnbind,mtype=MType} | Rest]) ->
	case lists:member(MType, ?CIRCULATE_LOG_TYPE) == false andalso UseUnbind > 0 of
		true ->
			case mod_map_role:get_role_attr(RoleID) of
				{ok,#p_role_attr{is_payed=IsPayed}} when IsPayed =:= false ->
					mod_role_tab:update_element(RoleID, p_role_attr, [{#p_role_attr.is_payed, true}]),
					ChangeList = [#p_role_attr_change{change_type=?ROLE_PAYED_CHANGE, new_value=true}],
					common_misc:role_attr_change_notify({role, RoleID}, RoleID, ChangeList),
					send_first_use_letter(RoleID);
				_ ->
					ignore
			end,
			PayDataRec  = mod_role_tab:get({r_pay_data, RoleID}),
			PayDataRec1 = PayDataRec#r_pay_data{acc_payed = PayDataRec#r_pay_data.acc_payed + UseUnbind},
			mod_role_tab:put({r_pay_data, RoleID}, PayDataRec1);
		
		false -> 
			hook_use_gold(Rest)
	end;
hook_use_gold([_Rec | Rest]) -> 
    hook_use_gold(Rest).
    
send_first_use_letter(RoleID) ->
    {ok, RoleAttr}    = mod_map_role:get_role_attr(RoleID),
    RoleName          = RoleAttr#p_role_attr.role_name,
    {{YY, MM, DD}, _} = calendar:local_time(),
    Text              = common_letter:create_temp(?PAY_FIRST_LETTER, [RoleName, YY, MM, DD]),
    common_letter:sys2p(RoleID, Text, ?_LANG_PAY_FIRST_TITLE, 14).

handle(Info,_State)->
handle(Info).

handle({_Unique, _Module, ?ACTIVITY_TODAY, DataIn, RoleID, _PID,_Line})->
    mod_daily_activity:handle({?ACTIVITY_TODAY, DataIn, RoleID});
handle({_Unique, _Module, ?ACTIVITY_BENEFIT_LIST, DataIn, RoleID, _PID,_Line})->
    mod_daily_activity:handle({?ACTIVITY_BENEFIT_LIST, DataIn, RoleID});
handle({_Unique, _Module, ?ACTIVITY_BENEFIT_REWARD, DataIn, RoleID, _PID,_Line})->
    mod_daily_activity:handle({?ACTIVITY_BENEFIT_REWARD, DataIn, RoleID});
handle({_Unique, _Module, ?ACTIVITY_BENEFIT_BUY, DataIn, RoleID, _PID, _Line})->
    mod_daily_activity:handle({?ACTIVITY_BENEFIT_BUY, DataIn, RoleID});
handle({Unique, Module, ?ACTIVITY_GETGIFT, DataIn, RoleID, PID, _Line}) ->
    do_getgift(Unique, Module, ?ACTIVITY_GETGIFT, DataIn, RoleID, PID);
handle({Unique, Module, ?ACTIVITY_PAY_GIFT_INFO, _DataIn, RoleID, PID, _Line}) ->
    do_pay_gift_info(Unique, Module, ?ACTIVITY_PAY_GIFT_INFO, RoleID, PID);
handle({Unique, Module, ?ACTIVITY_BOSS_GROUP, DataIn, RoleID, PID, Line}) ->
    mod_activity_boss:handle({Unique, Module, ?ACTIVITY_BOSS_GROUP, DataIn, RoleID, PID, Line});
handle({Unique, Module, ?ACTIVITY_NOTICE_TRANSFER, DataIn, RoleID, PID, _Line}) ->
    do_handle_notice_transfer(Unique,Module,?ACTIVITY_NOTICE_TRANSFER,DataIn,RoleID,PID);
handle({_Unique, _Module, ?ACTIVITY_EXP_BACK_INFO, DataIn, RoleID, _PID, _Line}) ->
    mod_daily_activity:handle({?ACTIVITY_EXP_BACK_INFO, DataIn, RoleID});
handle({_Unique, _Module, ?ACTIVITY_EXP_BACK_FETCH, DataIn, RoleID, _PID, _Line}) ->
    mod_daily_activity:handle({?ACTIVITY_EXP_BACK_FETCH, DataIn, RoleID});
handle({_Unique, _Module, ?ACTIVITY_EXP_BACK_AUTO_FETCH, DataIn, RoleID, _PID, _Line}) ->
    mod_daily_activity:handle({?ACTIVITY_EXP_BACK_AUTO_FETCH, DataIn, RoleID});
handle({Unique, Module, ?ACTIVITY_SCHEDULE_INFO, DataIn, RoleID, PID, _Line}) ->
    do_schedule_info(Unique,Module,?ACTIVITY_SCHEDULE_INFO,DataIn,RoleID,PID);
handle({Unique, Module, ?ACTIVITY_SCHEDULE_FETCH, DataIn, RoleID, PID, _Line}) ->
    do_schedule_fetch(Unique,Module,?ACTIVITY_SCHEDULE_FETCH,DataIn,RoleID,PID);
handle({Unique, Module, ?ACTIVITY_DAILY_PAY_REWARD, DataIn, RoleID, PID, _Line}) ->
    mod_daily_pay:handle({Unique,Module,?ACTIVITY_DAILY_PAY_REWARD,DataIn,RoleID,PID});
handle({Unique, Module, ?ACTIVITY_DAILY_PAY_NOTIFY, DataIn, RoleID, PID, _Line}) ->
    mod_daily_pay:handle({Unique,Module,?ACTIVITY_DAILY_PAY_NOTIFY,DataIn,RoleID,PID});

handle({Unique, Module, ?ACTIVITY_OPEN_ACTIVITY_INFO, DataIn, RoleID, PID, _Line}) ->
	do_open_activity_info(Unique,Module,?ACTIVITY_OPEN_ACTIVITY_INFO,DataIn,RoleID,PID);
handle({Unique, Module, ?ACTIVITY_OPEN_ACTIVITY_REWARD, DataIn, RoleID, PID, _Line}) ->
	do_open_activity_reward(Unique,Module,?ACTIVITY_OPEN_ACTIVITY_REWARD,DataIn,RoleID,PID);
%% 消费钉子购买物品
handle({_Unique, _Module, ?ACTIVITY_DINGZI_BUY, DataIn, RoleID, _PID, _Line}) ->
    dingzi_buy_goods(RoleID, DataIn);
handle({_Unique, _Module, ?ACTIVITY_DINGZI_INFO, _DataIn, RoleID, _PID, _Line}) ->
    send_dingzi_info_to_client(RoleID);
%% 等级优惠抢购
handle({_Unique, _Module, Method, DataIn, RoleID, _PID, _Line}) 
    when Method == ?ACTIVITY_LV_SALE_INFO; Method == ?ACTIVITY_LV_SALE_BUY ->
    mod_level_sale:handle(RoleID, Method, DataIn);
handle({activity_schedule_reward_fetch, Info}) ->
    do_handle_activity_schedule_reward_fetch(Info);

handle({open_activity_reward,RoleID,Type,RewardList}) ->
    open_activity_reward(RoleID,Type,RewardList);

handle(Args) ->
    ?ERROR_MSG("~w, unknow args: ~w", [?MODULE,Args]),
    ok. 

loop(MapID, Now) when MapID =:= 10260 ->
    check_drunk_time(1, Now);
loop(_, _) ->
    ignore.

check_drunk_time(FactionID, Now) ->
    case erlang:get({drunk_time, FactionID}) of
        {_, EndDateTime} ->
            if Now > EndDateTime ->
                   erlang:erase({drunk_time, FactionID});
               true ->
                   ignore
            end;
        _ ->
            [{StartTime, EndTime}] = common_config_dyn:find(etc, drunk_time),
            StartTimeSecond = common_tool:datetime_to_seconds({date(), StartTime}),
            EndTimeSecond = common_tool:datetime_to_seconds({date(), EndTime}),
            if Now >= StartTimeSecond andalso EndTimeSecond >= Now ->
                   erlang:put({drunk_time, FactionID}, {StartTimeSecond, EndTimeSecond}),
                   common_misc:chat_broadcast_to_faction(FactionID, ?ACTIVITY, ?ACTIVITY_DRUNK_TIME, 
                                                         #m_activity_drunk_time_toc{start_time=StartTimeSecond, end_time=EndTimeSecond});
               true ->
                   ignore
            end
    end.

is_in_drunk_time(FactionID) ->
    case erlang:get({drunk_time, FactionID}) of
        {_, _} ->
            true;
        _ ->
            false
    end.

send_dingzi_info_to_client(RoleID) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    send_dingzi_info_to_client(RoleID, RoleAttr#p_role_attr.level, RoleAttr#p_role_attr.category).
send_dingzi_info_to_client(_RoleID, RoleLevel, _Category) when RoleLevel < 10 -> ok;
send_dingzi_info_to_client(RoleID, RoleLevel, Category) ->
    DingziRec      = mod_role_tab:get({r_dingzi, RoleID}),
    DingziConf     = cfg_activity:dingzi_goods(RoleLevel, Category),
    CanBuy = if
        DingziConf#dingzi_conf.id == 0 -> false;
        DingziConf#dingzi_conf.id == DingziRec#r_dingzi.last_buy -> false;
        true -> true
    end,
    case CanBuy of
        true  -> DingziId = DingziConf#dingzi_conf.id;
        false -> DingziId = DingziConf#dingzi_conf.next_id
    end,
    Msg = #m_activity_dingzi_info_toc{
        id      = DingziId,
        can_buy = CanBuy
    },
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_DINGZI_INFO, Msg).

%% 消费钉子购买物品
dingzi_buy_goods(RoleID, _DataIn) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    DingziRec      = mod_role_tab:get({r_dingzi, RoleID}),
    LastBuy        = DingziRec#r_dingzi.last_buy,
    DingziConf     = cfg_activity:dingzi_goods(RoleAttr#p_role_attr.level, RoleAttr#p_role_attr.category),
    case DingziConf#dingzi_conf.id of
        0 -> 
            common_misc:send_common_error(RoleID, 0, <<"没有可购买的物品">>);
        LastBuy ->
            common_misc:send_common_error(RoleID, 0, <<"您只有一次机会购买，您不可能发出此请求">>);
        DingziId ->
            {ok, Num} = mod_bag:get_empty_bag_pos_num(RoleID, 1),
            case Num >= length(DingziConf#dingzi_conf.items) of
                false ->
                    common_misc:send_common_error(RoleID, 0, <<"背包空间不足">>);
                true ->
                    case common_bag2:use_money(RoleID, gold_unbind, DingziConf#dingzi_conf.need_gold, ?CONSUME_TYPE_DINGZI_BUY) of
                        true ->
                            {true, _ } = mod_bag:add_items(RoleID, DingziConf#dingzi_conf.items, ?LOG_ITEM_TYPE_DINGZI_BUY),
                            mod_role_tab:put({r_dingzi, RoleID}, DingziRec#r_dingzi{last_buy = DingziId}),
                            Msg = #m_activity_dingzi_buy_toc{id = DingziId},
                            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_DINGZI_BUY, Msg),
                            send_dingzi_info_to_client(RoleID, RoleAttr#p_role_attr.level, RoleAttr#p_role_attr.category);
                        {error, Reason} ->
                            common_misc:send_common_error(RoleID, 0, Reason)
                    end
            end
    end.

% %% 发送下一个钉子给客户端
% send_next_dingzi_to_client(RoleID, NextDingziId) ->
%     Msg = #m_activity_dingzi_info_toc{
%         id      = NextDingziId,
%         can_buy = false
%     },
%     common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_DINGZI_INFO, Msg).




%% 获取充值礼包的相关信息
do_pay_gift_info(Unique, Module, Method, RoleID, PID) ->
    PayDataRec = mod_role_tab:get({r_pay_data, RoleID}),
    FirstGiftInfo = #p_activity_pay_gift_info{
        id       = cfg_activity:first_acc_pay_activity(),
        type     = ?GIFT_FIRST_PAY, 
        is_fetch = PayDataRec#r_pay_data.has_get_first_pay_gift
    },
    AccGiftInfos = [#p_activity_pay_gift_info{
                        type     = ?GIFT_ACCUMULATE_PAY, 
                        id       = Id, 
                        is_fetch = lists:member(Id, PayDataRec#r_pay_data.acc_payed_gifts)}
                     || Id <- cfg_activity:all_acc_pay_activity()],
    NewComerId = cfg_activity:newcomer_activity(),
    NewComerGiftInfo =  #p_activity_pay_gift_info{
        id       = NewComerId,
        type     = ?GIFT_NEWCOMER, 
        is_fetch = lists:member(NewComerId, PayDataRec#r_pay_data.acc_payed_gifts)
    },
    PayGiftInfos = [FirstGiftInfo | AccGiftInfos],
    Msg = #m_activity_pay_gift_info_toc{gift_infos = [NewComerGiftInfo | PayGiftInfos]},
    common_misc:unicast2(PID, Unique, Module, Method, Msg).      

% get_collect_purple_info(GiftConfig, ExtendList) ->
%     {?GIFT_COLLECT_PURPLE, AccPayID, _} = GiftConfig,
%     IsFetch = lists:keymember(collect_purple_equip, 1, ExtendList),
%     #p_activity_pay_gift_info{type=?GIFT_COLLECT_PURPLE,id=AccPayID, is_fetch=IsFetch}.

%% 领取活动礼包
do_getgift(Unique, Module, Method, DataIn, RoleID, PID) ->
    case DataIn#m_activity_getgift_tos.type of 
        1 -> do_get_pay_first_gift(Unique, Module, Method, RoleID, PID, DataIn);
        % 2 -> do_get_pay_single_gift(Unique, Module, Method, RoleID, PID, DataIn);
        3 -> do_get_collect_purple_equip_gift(Unique, Module, Method, RoleID, PID, DataIn);
        4 -> do_get_newcomer_gift(Unique, Module, Method, RoleID, PID, DataIn);
        Type -> ?ERROR_MSG("do_getgift client error:~w,~w,~w",[RoleID,DataIn,Type])
    end.

%% 领取首充礼包(2013-4-26：目前改为首次消费)
do_get_pay_first_gift(Unique, Module, Method, RoleID, PID, DataIn) ->
    #m_activity_getgift_tos{type=Type, id=ActGiftID} = DataIn,
    PayDataRec = mod_role_tab:get({r_pay_data, RoleID}),
    if
        PayDataRec#r_pay_data.acc_payed =< 0 ->
            common_misc:send_common_error(RoleID, 0, <<"您还没有消费过，不能领取该礼包">>);
        PayDataRec#r_pay_data.has_get_first_pay_gift ->
            common_misc:send_common_error(RoleID, 0, <<"您的首次消费礼包已领取过了">>);
        true ->
            TypeID = cfg_activity:first_pay_gift(),
            case mod_bag:add_items(RoleID, [{TypeID, 1, 1, true}], ?LOG_ITEM_TYPE_PAY_FIRST_GIFT_HUO_DE) of
                {error, Reason} ->
                    common_misc:send_common_error(RoleID, 0, Reason);
                {true, _} ->
                    common_misc:common_broadcast_other(RoleID, TypeID, ?MODULE),
                    PayDataRec1 = PayDataRec#r_pay_data{has_get_first_pay_gift = true},
                    mod_role_tab:put({r_pay_data, RoleID}, PayDataRec1),
                    Msg = #m_activity_getgift_toc{id=ActGiftID, type=Type},
                    common_misc:unicast2(PID, Unique, Module, Method, Msg)
            end
    end.

%% 领取累计充值礼包
do_get_pay_single_gift(Unique, Module, Method, RoleID, PID, DataIn) ->
    #m_activity_getgift_tos{type=Type, id=ActGiftID} = DataIn,
    PayDataRec = mod_role_tab:get({r_pay_data, RoleID}),
    HasAlreadyGot = lists:member(ActGiftID, PayDataRec#r_pay_data.acc_payed_gifts),
    {NeedPayGold, GiftId} = cfg_activity:acc_pay_gift(ActGiftID),
    if
        HasAlreadyGot -> 
            common_misc:send_common_error(RoleID, 0, <<"礼包已领取了">>);
        PayDataRec#r_pay_data.acc_payed < NeedPayGold ->
            Reason = common_tool:to_binary(
                io_lib:format("你的累计充值尚未达到~p元宝，还需充值~p元宝", 
                    [NeedPayGold, NeedPayGold - PayDataRec#r_pay_data.acc_payed])),
            common_misc:send_common_error(RoleID, 0, Reason);
        true ->
            case mod_bag:add_items(RoleID, [{GiftId, 1, 1, true}], ?LOG_ITEM_TYPE_PAY_GIFT_HUO_DE) of
                {error, Reason} ->
                    common_misc:send_common_error(RoleID, 0, Reason);
                {true, _} ->
                    PayDataRec1 = PayDataRec#r_pay_data{
                        acc_payed_gifts = [ActGiftID | PayDataRec#r_pay_data.acc_payed_gifts]},
                    mod_role_tab:put({r_pay_data, RoleID}, PayDataRec1),
                    Msg = #m_activity_getgift_toc{id=ActGiftID, type=Type},
                    common_misc:unicast2(PID, Unique, Module, Method, Msg)
            end
    end.

check_get_collect_purple_equip_gift(RoleID)->
    {ok,#p_role_attr{category=Category}} = mod_map_role:get_role_attr(RoleID),
    [PurpleEquipList] = common_config_dyn:find(collect_activity, collect_purple_equip),
    {Category,{{TypeID,Color,Level,Bind},RewardConfig}} = lists:keyfind(Category, 1, PurpleEquipList),
    case mod_goods:get_equip_by_typeid(RoleID, TypeID) of
        {ok, #p_goods{bind=PBind,current_colour=PColor,level=PLevel}}->
            if
                Bind =:= PBind->
                    ok;
                true->
                    case Bind of
                        true->
                            throw({error,<<"您需要装备上\"绑定\"的武器才能领取该礼包哦">>});
                        _ ->
                            throw({error,<<"您需要装备上\"不绑定\"的武器才能领取该礼包哦">>})
                    end
            end,
            if
                Color=:=0->
                    next;
                Color>0 andalso Color =:= PColor->
                    next;
                true->
                    throw( {error,?_LANG_ACTIVITY_NOT_EQUIP} )
            end,
            if
                Level=:=0->
                    next;
                Level>0 andalso Level =:= PLevel->
                    next;
                true->
                    throw( {error,?_LANG_ACTIVITY_NOT_EQUIP} )
            end,
            {ok,RewardConfig};
        {error, _Reason}->
            error
    end.

%% 领取收集紫装礼包
do_get_collect_purple_equip_gift(Unique, Module, Method, RoleID, PID, DataIn) ->
    #m_activity_getgift_tos{type=Type, id=ActGiftID} = DataIn,
    case catch check_get_collect_purple_equip_gift(RoleID) of
        {ok,{RewardTypeID,RewardNum,RewardBind}}->
            CItem = #r_item_create_info{role_id=RoleID,num=RewardNum,typeid=RewardTypeID,bind=RewardBind,bag_id=1,bagposition=1},
            {ok,[TGoods]} = common_bag2:create_item(CItem),
            TransFun = fun() -> 
                               t_get_collect_purple_equip_gift(collect_purple_equip,RoleID,TGoods) 
                       end,
            case db:transaction( TransFun ) of
                {atomic, {ok, GoodsList}} ->
                    common_misc:update_goods_notify({role,RoleID}, GoodsList),
                    common_misc:unicast2(PID, Unique, Module, Method, #m_activity_getgift_toc{type=Type, id=ActGiftID}),
                    %% 道具消费日志
                    lists:foreach(
                      fun(LogGoods) ->
                              catch common_item_logger:log(RoleID,LogGoods,TGoods#p_goods.current_num,?LOG_ITEM_TYPE_GAIN_COLLECT_PURPLE_EQUIP_GIFT)
                      end,GoodsList),
                    ok;
                {aborted, Error} ->
                    case erlang:is_binary(Error) of
                        true ->
                            ?CAST_ERROR(Error, DataIn);
                        false ->                    
                            case Error of
                                {throw, {bag_error, {not_enough_pos,_BagID}}} ->
                                    ?CAST_ERROR(?_LANG_ACTIVITY_BAG_ENOUGH_WHEN_GET_PAY_FIRST_GIFT, DataIn);
                                _ ->
                                    ?ERROR_MSG("~w,~ts:~w", [RoleID,"领取收集紫色装备礼包时发生系统错误", Error]),
                                    ?CAST_ERROR(?_LANG_ACTIVITY_SYSTEM_ERROR_WHEN_GET_PAY_FIRST_GIFT, DataIn)
                            end
                    end
            end;
        {error,Reason}->
            ?CAST_ERROR( Reason, DataIn);
        error->
            ?CAST_ERROR(?_LANG_ACTIVITY_NOT_EQUIP, DataIn)
    end.

%% 领取新手大礼包
do_get_newcomer_gift(Unique, Module, Method, RoleID, PID, DataIn) ->
    #m_activity_getgift_tos{type=Type, id=ActGiftID} = DataIn,
    PayDataRec = mod_role_tab:get({r_pay_data, RoleID}),
    HasAlreadyGot = lists:member(ActGiftID, PayDataRec#r_pay_data.acc_payed_gifts),
    GiftId = cfg_activity:newcomer_gift(ActGiftID),
    if
        HasAlreadyGot -> 
            common_misc:send_common_error(RoleID, 0, <<"新手大礼包已领取了">>);
        true ->
            case mod_bag:add_items(RoleID, [{GiftId, 1, 1, true}], ?LOG_ITEM_TYPE_NEWCOMER_GIFT) of
                {error, Reason} ->
                    common_misc:send_common_error(RoleID, 0, Reason);
                {true, _} ->
                    PayDataRec1 = PayDataRec#r_pay_data{
                        acc_payed_gifts = [ActGiftID | PayDataRec#r_pay_data.acc_payed_gifts]},
                    mod_role_tab:put({r_pay_data, RoleID}, PayDataRec1),
                    Msg = #m_activity_getgift_toc{id=ActGiftID, type=Type},
                    common_misc:unicast2(PID, Unique, Module, Method, Msg)
            end
    end.
     

t_get_collect_purple_equip_gift(ExtendKey,RoleID,GoodsInfo) ->
	[#r_pay_activity{extend_list=ExtendList} = PayActivity] = db:read(?DB_PAY_ACTIVITY_P, RoleID, write),  
	case lists:keymember(ExtendKey, 1, ExtendList) of
		true ->
			db:abort(?_LANG_ACTIVITY_HAS_GET_WHEN_FETCH);
		false ->
			db:write(?DB_PAY_ACTIVITY_P, PayActivity#r_pay_activity{extend_list=[{ExtendKey,true}|ExtendList]}, write),
			mod_bag:create_goods_by_p_goods(RoleID, GoodsInfo)
	end.

%% ====================================================================
%% Internal functions
%% ====================================================================

%%@interface 显示日常活动
do_today({Unique, Module, Method, DataIn, RoleID, _PID, Line})->
    {ok, #p_role_attr{level=Level}}  = mod_map_role:get_role_attr(RoleID),
    {ok, #p_role_base{family_id=FamilyID}} = mod_map_role:get_role_base(RoleID),
    
    %%所有级别都开放显示
    do_today_2({Unique, Module, Method, DataIn, RoleID, _PID, Line},Level,FamilyID).

do_today_2({Unique, Module, Method, DataIn, RoleID, _PID, Line},Level,FamilyID)->
    #m_activity_today_tos{type=TypeIn} = DataIn,
    %%获取玩家的符合条件的活动列表
    ActivityTodayList = cfg_activity:all_activity(),
    
    {ServerOpenDay,_} = common_config:get_open_day(),
    OpenDateTime = {ServerOpenDay,{0,0,0}},
    NowDateTime = {date(),{0,0,0}},
    
    {DiffDays, _Time} = calendar:time_difference( OpenDateTime,NowDateTime),
    MatchedList = lists:filter(
                    fun(ActivityID)->
                            #r_activity_today{need_level=NeedLevel,delay_days=DelayDays,types=Types} = cfg_activity:activity(ActivityID),
                            if
                                (TypeIn =:= 0) orelse (TypeIn=:=Types)->
                                    IsMatchType=true;
                                true->
                                    IsMatchType = is_list(Types) andalso lists:member(TypeIn, Types)
                            end,
                            
                            IsMatchType andalso  Level>=NeedLevel andalso (DelayDays=:=0 orelse DiffDays>=DelayDays)
                    end, ActivityTodayList),
    case db:dirty_read(?DB_ROLE_ACTIVITY_TASK,RoleID) of
        []->
            ActTaskList = [];
        [#r_role_activity_task{act_task_list=ActTaskList}] ->
            next
    end,
    ResList = [ update_activity_status(RoleID,ActivityID,Level,FamilyID,ActTaskList)||ActivityID<-MatchedList ],
    
    Rec2 = #m_activity_today_toc{succ=true, activity_list=ResList},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, Rec2).

%%更新活动的对应任务状态
update_activity_status(RoleID,ActivityID,_Level,FamilyID,ActTaskList)
  when is_list(ActTaskList)->
    #r_activity_today{id=ID,order_id=OrderID,need_level=_NeedLevel,need_family=IsNeedFamily,
                      total_times=TotalTimes} = cfg_activity:activity(ActivityID),
    CheckFamiliy = ( IsNeedFamily=/=true orelse FamilyID>0 ),
    if
        CheckFamiliy->
            Status=1,
            DoneTimes = get_act_task_donetimes(ID,RoleID,ActTaskList);
        true->
            Status=0,
            DoneTimes = 0
    end,
    
    #p_activity_info{id=ID,order_id=OrderID,type=?DEFAULT_ACTIVITY_TYPE,status=Status,done_times=DoneTimes,total_times=TotalTimes}.

%%@param ActTaskList是玩家今日已完成的任务列表
%% 个人副本、师徒副本要特殊处理，进去副本地图，就算参加过一次！
get_act_task_donetimes(?ACTIVITY_TASK_PERSON_FB,_RoleID,ActTaskList)->
    case lists:keyfind(?ACTIVITY_TASK_PERSON_FB, 1, ActTaskList) of
        {_,FinishDate,FinishTimes}->
            case FinishDate =:= date() of
                true-> 
                    HeroFbActConfig = cfg_activity:activity(?ACTIVITY_TASK_PERSON_FB),
                    erlang:min(HeroFbActConfig#r_activity_today.total_times, FinishTimes);
                _ -> 
                    0
            end;
        _ ->
            0
    end;
get_act_task_donetimes(_ID,_RoleID,[])->
    0;
get_act_task_donetimes(ID,_RoleID,ActTaskList) when is_list(ActTaskList)->
    case lists:keyfind(ID, 1, ActTaskList) of
        {_,FinishDate,FinishTimes}->
            case FinishDate =:= date() of
                true-> FinishTimes;
                _ -> 0
            end;
        _ ->
            0
    end.


%%给玩家增加经验后的处理
do_after_exp_add(RoleID,ExpAdd,ExpAddResult) when is_integer(ExpAdd)->
    case ExpAddResult of
        {max_level_exp}->
            common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_SYSTEM, <<"您已经达到最高等级的最高经验，不能再增加经验">>),
            ignore;
        {exp_change, Exp} ->
            
            ExpChange = #p_role_attr_change{change_type=?ROLE_EXP_CHANGE, new_value=Exp},
            DataRecord = #m_role2_attr_change_toc{roleid=RoleID, changes=[ExpChange]},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_ATTR_CHANGE, DataRecord),
            hook_activity_schedule:hook_exp_change(RoleID, ExpAdd);
        
        {level_up, Level, RoleAttr, RoleBase} ->
            mod_map_role:do_after_level_up(Level, RoleAttr, RoleBase, ExpAdd, ?DEFAULT_UNIQUE, true),
            hook_activity_schedule:hook_exp_change(RoleID, ExpAdd);
        _ ->
            ignore
    end.

is_max_level_exp(RoleID)->
    {ok,#p_role_attr{exp=CurExp,level=RoleLevel,next_level_exp=NextLevelExp}} = mod_map_role:get_role_attr(RoleID),
    MaxNextLevelExp = 3*to_integer(NextLevelExp),
    [MaxLevel] = common_config_dyn:find(etc,max_level),
    (RoleLevel>=MaxLevel) andalso (CurExp >= MaxNextLevelExp).


to_integer(Num) when is_integer(Num)->
    Num;
to_integer(_Num)->
    0.


do_handle_notice_transfer(Unique,Module,Method,DataIn,RoleID,PID) ->
    #m_activity_notice_transfer_tos{activity_id=ActivityId} = DataIn,
    case catch check_notice_transfer(RoleID, ActivityId) of
            {error, ErrCode, Reason} ->
                R2 = #m_activity_notice_transfer_toc{error_code=ErrCode,reason=Reason},
                common_misc:unicast2(PID, Unique, Module, Method, R2);
            ok ->
                #r_activity_notice_config{px=TX,py=TY} = common_activity:check_activity_notice_config(ActivityId),
                {ok,#p_role_base{faction_id=FactionId}} = mod_map_role:get_role_base(RoleID),
                case mod_map_role:get_role_base(RoleID) of
                    {ok, #p_role_base{faction_id=FactionId}} ->
                        #r_activity_notice_config{npc_id=NpcId} = common_activity:check_activity_notice_config(ActivityId),
                        R2 = #m_activity_notice_transfer_toc{npc_id=NpcId + 1000000 * FactionId},
                        common_misc:unicast2(PID, Unique, Module, Method, R2);
                    _ ->
                        ignore
                end,
                DestMapID = common_misc:get_home_map_id(FactionId),
                MapState = mgeem_map:get_state(),
                #map_state{mapid=MapID} = MapState,
                case MapID =:= DestMapID of
                    true ->
                        mod_map_actor:same_map_change_pos(RoleID, role, TX, TY, ?CHANGE_POS_TYPE_NORMAL, MapState);
                    _ ->
                        mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, DestMapID, TX, TY)
                end
    end.

check_notice_transfer(RoleID, ActivityId) ->
    case mgeem_map:get_map_type(mgeem_map:get_mapid()) of
        ?MAP_TYPE_COPY ->
            ?THROW_ERR(?ERR_ACTIVITY_NOTICE_TRANSFER_NOT_ALLOWED_IN_FB_MAP );
        _ ->
            case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
                true ->
                    % ?THROW_ERR( ?ERR_EXAMINE_FB_ILLEGAL_ENTER_MAP ) 
                    ?THROW_ERR(?ERR_OTHER_ERR, ?_LANG_XIANNVSONGTAO_MSG);
                false -> ignore
            end,
            case mod_warofking:is_in_fb_map() of
                true->
                    %%王座争霸战副本中
                    ?THROW_ERR(?ERR_ACTIVITY_NOTICE_TRANSFER_NOT_ALLOWED_IN_FB_MAP );
                _ ->
                    check_notice_transfer_1(RoleID, ActivityId)
            end
    end.

check_notice_transfer_1(RoleID, ActivityId) ->
    case common_activity:check_activity_notice_config(ActivityId) of
        {error, not_found_config} ->
            ?THROW_ERR(?ERR_ACTIVITY_NOTICE_NOT_FOUND );
        #r_activity_notice_config{ahead_time=AheadTime} ->
            case mod_map_role:get_role_base(RoleID) of 
                {ok, _} ->
                    next;
                _ ->
                    ?THROW_SYS_ERR()
            end, 
            {ok, #p_role_base{faction_id=FactionId}} = mod_map_role:get_role_base(RoleID),
            case common_misc:get_event_state({ActivityId, FactionId}) of
                {ok, #r_event_state{data={StartTime, EndTime}}} ->
                    NowSeconds = common_tool:now(),
                    {ok, #p_role_attr{level=Level}} = mod_map_role:get_role_attr(RoleID),
                    if NowSeconds > EndTime orelse NowSeconds < StartTime - AheadTime ->
                           ?THROW_ERR(?ERR_ACTIVITY_NOTICE_NOT_START );
                       Level < 20 ->
                           ?THROW_ERR(?ERR_ACTIVITY_NOTICE_LEVEL_LESS_THAN_20);
                       true ->
                           check_notice_transfer_2(RoleID)
                    end;
                _ ->
                    ?THROW_ERR(?ERR_ACTIVITY_NOTICE_NOT_FOUND )
            end
    end. 

check_notice_transfer_2(RoleID) ->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        undefined->
            next;
        RoleMapInfo when is_record(RoleMapInfo,p_map_role)->
            case RoleMapInfo#p_map_role.state of
                ?ROLE_STATE_NORMAL ->%%正常状态
                    ok;
                ?ROLE_STATE_STALL_SELF ->
                    ?THROW_ERR(?ERR_ACTIVITY_NOTICE_STATE_IN_STALL);
                ?ROLE_STATE_STALL ->
                    ?THROW_ERR(?ERR_ACTIVITY_NOTICE_STATE_IN_STALL);
                ?ROLE_STATE_YBC_FAMILY ->
                    ?THROW_ERR(?ERR_ACTIVITY_NOTICE_STATE_IN_YBC_FAMILY);
                ?ROLE_STATE_COLLECT ->
                    ?THROW_ERR(?ERR_ACTIVITY_NOTICE_STATE_IN_COLLECT);
                _S->
                    ok
            end
    end,
    case mod_horse_racing:is_role_in_horse_racing(RoleID) of
        true ->
            ?THROW_ERR(?ERR_ACTIVITY_NOTICE_STATE_IN_HORSE_RACING);
        _ ->
            ignore
    end,
    ok.

%% 玩家上线, 通知其当前正在或将要开启的活动
hook_role_online(RoleID) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    update_role_activity_exp_history(RoleID, RoleAttr),
    notify_role_activity_notice(RoleID, 0, RoleAttr#p_role_attr.level),
    notify_drunk_time(RoleID).

notify_drunk_time(RoleID) ->
    [{StartTime, EndTime}] = common_config_dyn:find(etc, drunk_time),
    StartTimeSecond = common_tool:datetime_to_seconds({date(), StartTime}),
    EndTimeSecond = common_tool:datetime_to_seconds({date(), EndTime}),
    Now = common_tool:now(),
    if Now >= StartTimeSecond andalso EndTimeSecond >= Now ->
           common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_DRUNK_TIME, 
                               #m_activity_drunk_time_toc{start_time=StartTimeSecond, end_time=EndTimeSecond});
       true ->
           ignore
    end.

hook_role_title_change(RoleID, OldTitle, NewTitle) ->
    notify_role_activity_notice(RoleID, OldTitle, NewTitle).

notify_role_activity_notice(RoleID, OldTitle, NewTitle) ->
    case common_config_dyn:find(activity_notice, open_activity) of 
        [] ->
            ignore;
        [Activities] ->
            lists:foreach(
              fun(ActivityId) ->
                      case common_activity:check_activity_notice_config(ActivityId) of
                          {error, not_found_config} ->
                              ignore;
                          #r_activity_notice_config{min_level=MinLevel} ->
                              {ok, #p_role_base{faction_id=RoleFactionId}} = mod_map_role:get_role_base(RoleID),
                              case common_misc:get_event_state({ActivityId, RoleFactionId}) of
                                  {ok, #r_event_state{data={StartTime, EndTime}}} ->
                                      if NewTitle >= MinLevel andalso (OldTitle < MinLevel orelse OldTitle =:= 0) ->
                                             DataRecord = #m_activity_notice_start_toc{activity_id=ActivityId,
                                                                                       start_time=StartTime,
                                                                                       end_time=EndTime},
                                             common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_NOTICE_START, DataRecord);
                                         true ->
                                             ignore
                                      end;
                                  _ ->
                                      ignore
                              end
                      end
              end, Activities)
    end.

%%==============经验找回=========================
%% 玩家当天第一次上线时更新昨天的数据， 删除3天以前的历史数据.
%% 更新规则：昨日的等级，境界取值于玩家今天第一次上线时的数据
%% 玩家连续玩跨天的情况，不做处理，玩家需重新登录才会更新昨日数据。
update_role_activity_exp_history(RoleID, RoleAttr) ->
    Today = date(),
    {ok, #p_role_base{create_time=CreateTime}} = mod_map_role:get_role_base(RoleID),
    {CreateDate, _} = common_tool:seconds_to_datetime(CreateTime),
    IsFirstTimeInGame = (Today =:= CreateDate), %% 是否是创建帐号的第一天
    case IsFirstTimeInGame of
        true ->
            ignore;
        false ->
            case get_new_activity_exp_history(RoleID, RoleAttr) of
                {ok, ActTask} ->
                    %% 过滤3天以前的历史记录
                    NewFilterTaskHistory = 
                        lists:filter(
                          fun(ExpTask) ->
                                  common_time:diff_date(Today, ExpTask#r_role_exp_back_info.finish_date) =< 3
                          end, ActTask#r_role_activity_task.task_history),
                    db:dirty_write(?DB_ROLE_ACTIVITY_TASK,ActTask#r_role_activity_task{task_history=NewFilterTaskHistory});
                _->
                    ignore
            end
    end.

yesterday() ->
    common_time:add_days(date(), -1).

get_new_activity_exp_history(RoleID, RoleAttr) ->
    Yesterday = yesterday(),
    CanJoinActivityList = get_can_join_exp_activity_list(RoleID),
    case db:dirty_read(?DB_ROLE_ACTIVITY_TASK,RoleID) of
        [] ->
            R2_Task = #r_role_activity_task{role_id=RoleID, 
                                            task_history=[build_default_exp_task_info(RoleAttr, CanJoinActivityList, Yesterday)]},
            {ok, R2_Task};
        [#r_role_activity_task{task_history=TaskHistory}=R1_Task] ->
            #p_role_attr{jingjie=Jingjie, level=Level} = RoleAttr,
            case lists:keyfind(Yesterday, #r_role_exp_back_info.finish_date, TaskHistory) of
                false ->
                    NewExpTaskInfo = build_default_exp_task_info(RoleAttr, CanJoinActivityList, Yesterday),
                    {ok, R1_Task#r_role_activity_task{task_history=[NewExpTaskInfo|TaskHistory]}};
                YesterdayTaskInfo -> 
                    if YesterdayTaskInfo#r_role_exp_back_info.flag =:= ?ROLE_NOT_CONFIRM_EXP_BACK_FLAG ->
                           %% 更新并补全昨日可做的所有经验活动数据
                           TaskList = YesterdayTaskInfo#r_role_exp_back_info.task_list,
                           NewYesterdayTaskInfo = YesterdayTaskInfo#r_role_exp_back_info{jingjie=Jingjie, 
                                                                                         level=Level, 
                                                                                         flag=?ROLE_CONFIRM_EXP_BACK_FLAG,
                                                                                         task_list=complete_exp_task_info(TaskList,CanJoinActivityList)},
                           NewTaskHistory = lists:keystore(Yesterday, #r_role_exp_back_info.finish_date, TaskHistory, NewYesterdayTaskInfo),
                           R2_Task = R1_Task#r_role_activity_task{task_history=NewTaskHistory},
                           {ok, R2_Task};                            
                       true ->
                           {ignore, R1_Task}
                    end
            end
    end.

%% 获取玩家当前可以参与的经验活动
get_can_join_exp_activity_list(RoleID) ->
    {ok, #p_role_attr{jingjie=Jingjie,level=Level}} = mod_map_role:get_role_attr(RoleID),
    lists:foldl(
      fun({ActivityId, MinJingjie, MinLevel}, Acc) ->
              case {Jingjie >= MinJingjie, Level >= MinLevel} of
                  {true , true} ->
                      [ActivityId | Acc];
                  _ ->
                      Acc
              end
      end, [], cfg_activity:exp_activity()).

%% 构建默认的昨日经验活动列表
build_default_exp_task_info(RoleAttr, CanJoinActivityList, FinishDate) ->
    #p_role_attr{level=Level, jingjie=Jingjie} = RoleAttr,
    TaskList = lists:map(
                 fun(ActivityID) -> 
                         {ActivityID, 0, ?CAN_FETCH_EXP_BACK}
                 end,CanJoinActivityList),
    #r_role_exp_back_info{finish_date=FinishDate,level=Level,jingjie=Jingjie, flag=?ROLE_CONFIRM_EXP_BACK_FLAG, task_list=TaskList}.

%% 补全经验记录
complete_exp_task_info(TaskList,CanJoinActivityList) ->
    lists:map(
      fun(ActivityID) -> 
              case lists:keyfind(ActivityID, 1, TaskList) of
                  false ->
                      {ActivityID, 0, ?CAN_FETCH_EXP_BACK};
                  TaskInfo ->
                      TaskInfo
              end
      end, CanJoinActivityList).

do_schedule_info(_Unique,_Module,_Method,DataIn,RoleID,_PID) ->
    global:send(mgeew_activity_schedule, {info, {DataIn#m_activity_schedule_info_tos.id, RoleID}}).

do_schedule_fetch(_Unique,_Module,_Method,DataIn,RoleID,_PID) ->
    global:send(mgeew_activity_schedule, {fetch_reward, {DataIn#m_activity_schedule_fetch_tos.id, RoleID}}),
    ok.

do_open_activity_info(Unique,Module,Method,DataIn,RoleID,PID) ->
	global:send(mgeew_open_activity,{info,Unique,Module,Method,DataIn#m_activity_open_activity_info_tos.type,RoleID,PID}).

do_open_activity_reward(Unique,Module,Method,DataIn,RoleID,PID) ->
	global:send(mgeew_open_activity,{reward,Unique,Module,Method,DataIn#m_activity_open_activity_reward_tos.type,RoleID,PID}),
    ok.

do_handle_activity_schedule_reward_fetch({RoleID, ActivityID, RoleRankInfo, StartTime, EndTime}) ->
    case catch check_activity_reward_fetch(ActivityID, RoleID, StartTime, EndTime) of
        ok ->
            do_activity_schedule_reward_fetch(RoleID, ActivityID, RoleRankInfo);
        {error, ErrCode, Reason} ->
            ErrorRecord = #m_activity_schedule_fetch_toc{error_code=ErrCode, reason=Reason,id=ActivityID},
            common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_SCHEDULE_FETCH, ErrorRecord)
    end.

check_activity_reward_fetch(ActivityID, RoleID, StartTime, EndTime) ->
    case db:dirty_read(?DB_ACTIVITY_RANK_REWARD_P, {ActivityID, RoleID}) of
        [] ->
            ok;
        [#r_activity_rank_reward{last_fetch_time=LastFetchTime}] ->
            case check_can_fetch_reward(LastFetchTime, {StartTime, EndTime}) of
                ok ->
                    ok;
                already_fetch ->
                    ?THROW_ERR(?ERR_ACTIVITY_SCHEDULE_FETCH_ALREADY_FETCH);
                over_time ->
                    ?THROW_ERR(?ERR_ACTIVITY_SCHEDULE_FETCH_OVER_TIME)
            end
    end.

do_activity_schedule_reward_fetch(RoleID, ActivityID, RoleRankInfo) ->
    {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    RewardExp = get_reward_exp(ActivityID, RoleAttr, RoleRankInfo), 
    RewardSilver = get_reward_silver(ActivityID, RoleAttr, RoleRankInfo), 
    RewardItems = get_reward_items(ActivityID, RoleAttr, RoleRankInfo),
    case db:transaction(
           fun() ->
                  case RewardSilver > 0 of
                      true ->
                          common_bag2:t_gain_money(silver_bind, RewardSilver, RoleID, ?GAIN_TYPE_SILVER_ACTIVITY_SCHEDULE);
                      false ->
                          ignore
                  end,
                  
                  GoodsList = 
                      case RewardItems =/= undefined andalso RewardItems =/= [] of
                          true ->
                              {ok, GoodListT} = t_schedule_reward_item(RoleID, [], RewardItems),
                              GoodListT;
                          false ->
                              []
                      end,
                  ExpAddResult =
                      case {is_max_level_exp(RoleID), RewardExp > 0} of
                          {true, true}->
                              {max_level_exp};
                          {false, true} ->
                              mod_map_role:t_add_exp(RoleID, RewardExp);
                          _ ->
                              ignore
                      end,
                  db:write(?DB_ACTIVITY_RANK_REWARD_P, 
                           #r_activity_rank_reward{reward_key={ActivityID, RoleID}, last_fetch_time=common_tool:now()}, write),
                  {ok, GoodsList,ExpAddResult}
                  end) of
        {aborted, Error} ->
            ErrorCode = 
                case Error of
                    {bag_error,{not_enough_pos,_BagID}} ->
                        ?ERR_ACTIVITY_SCHEDULE_NOT_ENOUGH_BAG_POS;
                    {throw, {bag_error, {not_enough_pos,_BagID}}} ->
                        ?ERR_ACTIVITY_SCHEDULE_NOT_ENOUGH_BAG_POS;
                    {throw, ?_LANG_ROLE2_ADD_EXP_EXP_FULL} ->
                        DataRecord = #m_role2_exp_full_toc{text=?_LANG_ROLE2_ADD_EXP_EXP_FULL},
                        common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_EXP_FULL, DataRecord),
                        ?ERR_ACTIVITY_SCHEDULE_EXP_FULL;
                    _ ->
                        ?ERROR_MSG("~ts: role_id: ~w, error : ~w", ["领取定时活动奖励是发生系统错误", RoleID, Error]),
                        ?ERR_SYS_ERR
                end,
            common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_SCHEDULE_FETCH, 
                                #m_activity_schedule_fetch_toc{error_code=ErrorCode, id=ActivityID});
        {atomic, {ok, AddGoodsList, ExpAddResult}} ->
            RewardExpStr = 
                if RewardExp > 0 ->
                       %% 增加经验后的处理
                       do_after_exp_add(RoleID,RewardExp,ExpAddResult),
                       common_misc:format_lang(?_LANG_ACTIVITY_REWARD_EXP,[RewardExp]);
                   true ->
                       ""
                end,
            {ok, NewRoleAttr} = mod_map_role:get_role_attr(RoleID), 
            RewardSilvrStr =
                if RewardSilver > 0 ->
                       common_misc:send_role_silver_change(RoleID, NewRoleAttr),
                       common_misc:format_lang(?_LANG_ACTIVITY_REWARD_SILVER,[RewardSilver]);
                   true ->
                       ""
                end,
            
            lists:foreach(fun(RewardItem)-> 
                                  #r_item_reward{item_type_id=ItemTypeID,item_num=ItemNum,is_bind=IsBind} = RewardItem,
                                  common_item_logger:log(RoleID, ItemTypeID,ItemNum,IsBind,?LOG_ITEM_TYPE_ACTIVITY_SCHEDULE_REWARD)
                          end,RewardItems),
            common_misc:update_goods_notify({role, RoleID}, AddGoodsList),
            RewardItemStr = 
                lists:foldl(fun(E, AccStr) ->
                                    #r_item_reward{item_type_id=TypeID, item_num=Num} = E,
                                    case E#r_item_reward.type of
                                        ?TYPE_ITEM ->
                                            {ok, #p_item_base_info{itemname=Name}} = mod_item:get_item_baseinfo(TypeID),
                                            lists:concat([AccStr, common_misc:format_lang(?_LANG_ACTIVITY_REWARD_ITEM,[Name, Num])]);
                                        ?TYPE_EQUIP ->
                                            {ok, #p_equip_base_info{equipname=Name}} = mod_equip:get_equip_baseinfo(TypeID),
                                            lists:concat([AccStr, common_misc:format_lang(?_LANG_ACTIVITY_REWARD_ITEM,[Name, Num])]);
                                        ?TYPE_STONE ->
                                            {ok, #p_stone_base_info{stonename=Name}} = mod_stone:get_stone_baseinfo(TypeID),
                                            lists:concat([AccStr, common_misc:format_lang(?_LANG_ACTIVITY_REWARD_ITEM,[Name, Num])]);
                                        _ ->
                                            AccStr
                                    end
                            end, "", RewardItems),
            common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_SCHEDULE_FETCH,  
                                #m_activity_schedule_fetch_toc{reason=lists:concat([RewardExpStr,RewardSilvrStr, RewardItemStr]),
                                                               id=ActivityID})
    end.

t_schedule_reward_item(_RoleID, GoodsList, []) ->
    {ok,GoodsList};
t_schedule_reward_item(RoleID, GoodsList, [RewardItem|T])->
    #r_item_reward{type=Type,item_type_id=ItemTypeID,item_num=Num,is_bind=IsBind} = RewardItem,
    CreateInfo = #r_goods_create_info{bind=IsBind,type=Type, type_id=ItemTypeID, num=Num},
    {ok,NewGoodsList} = mod_bag:create_goods(RoleID,CreateInfo),
    t_schedule_reward_item(RoleID, lists:concat([NewGoodsList,GoodsList]) ,T).

get_reward_exp(ActivityID, RoleAttr, RoleRankInfo) when RoleRankInfo#r_activity_rank.is_qualified=:=true ->
    #r_activity_rank{ranking=Ranking} = RoleRankInfo,
    [ExpList] = common_config_dyn:find(activity_schedule, {reward_exp, ActivityID}),
    lists:foldl(
        fun({Key, ExpConfig}, AccExp) ->
                case {AccExp =:= 0, Key} of
                    {true, {MinRanking, MaxRanking}} ->
                        case Ranking >= MinRanking andalso MaxRanking >= Ranking of
                            true ->
                                calc_reward_exp(RoleAttr, Ranking, ExpConfig);
                            _ ->
                                AccExp
                        end;
                    {true, qualified} ->
                        calc_reward_exp(RoleAttr, Ranking, ExpConfig);
                    {false, _} ->
                        AccExp
                end
      end, 0, ExpList);
get_reward_exp(_,_,_) ->
    0.

calc_reward_exp(RoleAttr, Ranking, {BaseMulti, _LianqiType, LianqiMulti}) ->
    #p_role_attr{level=Level, jingjie=Jingjie} = RoleAttr,
    LianqiExp = 
        case Jingjie > 0 of
            true ->
                [Exp] = common_config_dyn:find(lianqi, {exp, Jingjie}),
                ExpMulti = 1,
%%                     case LianqiType of
%%                         1 ->
%%                             1;
%%                         2 ->
%%                             [MultiT] = common_config_dyn:find(lianqi, exp_force_fetch_multi),
%%                             MultiT
%%                     end,
                (Exp * ExpMulti * LianqiMulti) ;
            _ ->
                0
        end,
    RankExp = 
        if Ranking > 0 ->
               (10000000-Ranking*10000+10000);
           true ->
               0
        end,
    (Level*Level*BaseMulti) + LianqiExp + RankExp.
    
get_reward_silver(ActivityID, RoleAttr, RoleRankInfo) when RoleRankInfo#r_activity_rank.is_qualified=:=true ->
    #r_activity_rank{ranking=Ranking} = RoleRankInfo,
    [SilverList] = common_config_dyn:find(activity_schedule, {reward_silver, ActivityID}),
    lists:foldl(
        fun({Key, SilverConfig}, AccSilver) ->
                case {AccSilver =:= 0, Key} of
                    {true, {MinRanking, MaxRanking}} ->
                        case Ranking >= MinRanking andalso MaxRanking >= Ranking of
                            true ->
                                calc_reward_silver(RoleAttr, Ranking, SilverConfig);
                            _ ->
                                AccSilver
                        end;
                    {true, qualified} ->
                        calc_reward_silver(RoleAttr, Ranking, SilverConfig);
                    {false, _} ->
                        AccSilver
                end
      end, 0, SilverList);
get_reward_silver(_,_,_) ->
    0.

calc_reward_silver(RoleAttr, Ranking, {SilverBase, DivBase}) ->
    #p_role_attr{level=Level, jingjie=Jingjie} = RoleAttr,
    LevelReward =
        case DivBase of
            0 ->
                0;
            _ ->
                Level div DivBase * 10000
        end,
    RankSilver = 
        if Ranking > 0 ->
               (100000-Ranking*1000+1000);
           true ->
               0
        end,
    SilverBase + LevelReward + Jingjie*100 + RankSilver. 

get_reward_items(ActivityID, RoleAttr, RoleRankInfo) when RoleRankInfo#r_activity_rank.is_qualified=:=true ->
    #r_activity_rank{ranking=Ranking} = RoleRankInfo,
    [RewardItemList] = common_config_dyn:find(activity_schedule, {reward_item, ActivityID}),
    MatchRewardItemList = 
        lists:foldl(
          fun({MinJingjie,MaxJingjie,RewardItem}, Acc) -> 
                  case RoleAttr#p_role_attr.level >= MinJingjie andalso MaxJingjie >= RoleAttr#p_role_attr.level of
                      true ->
                          RewardItem;
                      _ ->
                          Acc
                  end
          end, [], RewardItemList),
    lists:foldl(
        fun({Key, ItemList}, AccItemList) ->
                case {AccItemList =:= [], Key} of
                    {true, {MinRanking, MaxRanking}} ->
                        case Ranking >= MinRanking andalso MaxRanking >= Ranking of
                            true ->
                                ItemList;
                            _ ->
                                AccItemList
                        end;
                    {true, qualified} ->
                        ItemList;
                    {false, _} ->
                        AccItemList
                end
      end, [], MatchRewardItemList);
get_reward_items(_,_,_) ->
    [].

check_can_fetch_reward(LastFetchTime, {StartTime, EndTime}) ->
    EndTimeTmp = erlang:min(StartTime + 86400, EndTime),
    Now = common_tool:now(),
    if LastFetchTime > Now ->
           over_time;
       LastFetchTime >= StartTime andalso EndTimeTmp >= LastFetchTime andalso EndTimeTmp =< EndTime
           andalso Now >= StartTime andalso EndTimeTmp >= Now ->
           already_fetch;
       LastFetchTime >= EndTimeTmp andalso LastFetchTime =< EndTime ->
           check_can_fetch_reward(LastFetchTime, {EndTimeTmp, EndTime});
       LastFetchTime > EndTime ->
           over_time;
       true ->
           ok
    end.

%% 领取开服活动奖励
open_activity_reward(RoleID,Type,RewardList) ->
	TransFun = fun()-> 
					   common_bag2:t_reward_prop(RoleID, RewardList)
			   end,
	{NewErrCode,NewReason} = 
		case db:transaction( TransFun ) of
			{atomic, {ok,RewardGoodsList}} ->
				common_misc:update_goods_notify({role,RoleID},RewardGoodsList),
				lists:foreach(
				  fun(#p_reward_prop{prop_id=TypeID,prop_num=Num}) ->
						  ?TRY_CATCH(common_item_logger:log(RoleID,TypeID,Num,undefined,?LOG_ITEM_TYPE_GET_OPEN_ACTIVITY_REWARD))
				  end,RewardList),
				{?ERR_OK,undefined};
			{aborted, {throw,{bag_error,{not_enough_pos,_}}}} ->
				{?ERR_POS_NOT_ENOUGH,undefined};
			{aborted, {throw,{error,ErrCode,undefined}}} ->
				{ErrCode,undefined};
			{aborted, Reason} ->
				{?ERR_OTHER_ERR,Reason}
		end,
	global:send(mgeew_open_activity,{open_activity_reward_result,RoleID,Type,NewErrCode,NewReason}).
	

