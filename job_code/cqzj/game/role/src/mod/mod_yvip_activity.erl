%% Author: dizengrong
%% Created: 2013-1-21
%% @doc: 这里实现的是t6中于qq相关的黄钻活动

-module (mod_yvip_activity).
-include("mgeer.hrl").

-export([handle/1, open_yvip_callback/4, set_yvip_open_cb/3, notice_activity/1]).

%% export for role_misc callback
-export([init/2, delete/1]).
-compile(export_all).

-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?QQ, Method, Msg)).

-define(TYPE_YVIP_ACTIVITY_ICO_ID,20002).
init(RoleID, QQYvipRec) ->
	case QQYvipRec of
		false ->
			QQYvipRec1 = #r_qq_yvip{};
		_ ->
			QQYvipRec1 = QQYvipRec
	end,
	set_role_yvip_data(RoleID, QQYvipRec1).

delete(RoleID) ->
	mod_role_tab:erase({?QQ_YVIP, RoleID}).

%% ========================数据操作接口========================
set_role_yvip_data(RoleID, QQYvipRec) ->
	mod_role_tab:put({?QQ_YVIP, RoleID}, QQYvipRec).

get_role_yvip_data(RoleID) ->
	QQYvipRec = mod_role_tab:get({?QQ_YVIP, RoleID}),
	Now = common_tool:now(),
	case common_tool:check_if_same_day(QQYvipRec#r_qq_yvip.update_time, Now) of
		false -> 
			QQYvipRec1 = QQYvipRec#r_qq_yvip{
				zhi_zun_gift    = 0,
				has_daily_gift  = true,
				has_yearly_gift = true,
				update_time     = Now
			},
			set_role_yvip_data(RoleID, QQYvipRec1),
			QQYvipRec1;
		true ->
			QQYvipRec
	end.

notice_activity(RoleID) ->
	Now = calendar:local_time(),
	Fun = fun(Data) ->
		case Data of
			{ActId, YActId} ->
				{BeginTime, EndTime} = cfg_qq:get_time_limit(YActId),
				case Now >= BeginTime andalso Now =< EndTime of
					true -> 
						send_notice_activity(RoleID, ActId);
					false ->
						ignore
				end;
			ActId ->
				send_notice_activity(RoleID, ActId)
		end
	end,
	[Fun(Data0) || Data0 <- cfg_qq:get_open_activity()].

send_notice_activity(RoleID, ActId) ->
	case check_is_notice(RoleID,ActId) of
		true ->
			Msg = #m_activity_notice_start_toc{activity_id=ActId},
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ACTIVITY, ?ACTIVITY_NOTICE_START, Msg);
		_ ->
			ignore
	end.

check_is_notice(RoleID,ActId) when ActId =:= ?TYPE_YVIP_ACTIVITY_ICO_ID ->
	QQYvipRec = get_role_yvip_data(RoleID),
	QQYvipRec#r_qq_yvip.has_daily_gift 
	or QQYvipRec#r_qq_yvip.has_yearly_gift 
	or QQYvipRec#r_qq_yvip.has_newer_gift 
	or QQYvipRec#r_qq_yvip.has_pet_gift;
check_is_notice(_RoleID,_ActId) ->
	true.
	
		
		
%% ========================数据操作接口========================

handle({_Unique, _Module, ?QQ_YVIP_XUFEI, _DataIn, RoleID, _PID, _Line}) ->
	QQYvipRec = get_role_yvip_data(RoleID),
	send_xufei_data_to_client(RoleID, QQYvipRec);

handle({_Unique, _Module, ?QQ_YVIP_PRIVILEGE, _DataIn, RoleID, _PID, _Line}) ->
	QQYvipRec = get_role_yvip_data(RoleID),
	send_privilege_data_to_client(RoleID, QQYvipRec);

handle({_Unique, _Module, ?QQ_YVIP_ACTIVITY, _DataIn, RoleID, _PID, _Line}) ->
	QQYvipRec = get_role_yvip_data(RoleID),
	send_activity_data_to_client(RoleID, QQYvipRec);

handle({_Unique, _Module, ?QQ_YVIP_LOTTERY, _DataIn, RoleID, _PID, _Line}) ->
	QQYvipRec = get_role_yvip_data(RoleID),
	send_lottery_data_to_client(RoleID, QQYvipRec);

handle({_Unique, _Module, ?QQ_YVIP_OPERAT, DataIn, RoleID, _PID, _Line}) ->
	{ok, IsYvip, IsYearYvip, YvipLevel} = mod_qq_cache:get_vip(RoleID),
	case IsYvip of
		false ->
			common_misc:send_common_error(RoleID, 0, <<"您还不是黄钻用户，请先开通黄钻">>);
		true ->
			QQYvipRec = get_role_yvip_data(RoleID),
			Ret = case DataIn#m_qq_yvip_operat_tos.type of
				2 -> %% 领取黄钻每日奖励
					do_get_daily_gift(RoleID, QQYvipRec, YvipLevel);
				3 -> %% 领取黄钻年费每日礼包
					do_get_yearly_gift(RoleID, QQYvipRec, IsYearYvip);
				4 -> %% 领取黄钻新手礼包
					do_get_newer_gift(RoleID, QQYvipRec);
				5 -> %% 领取黄钻灵宠
					do_get_pet(RoleID, QQYvipRec);
				6 -> %% 领取黄钻豪华大礼包
					do_get_big_gift(RoleID, QQYvipRec, DataIn#m_qq_yvip_operat_tos.data1);
				7 -> %% 黄钻大转盘
					do_chou_jiang(RoleID, QQYvipRec)
			end,
			case Ret of
				{error, Reason} ->
					common_misc:send_common_error(RoleID, 0, Reason);
				{true, NewQQYvipRec} ->
					set_role_yvip_data(RoleID, NewQQYvipRec);
				ignore -> ignore
			end
	end,
	ok;

handle({qq_activity_callback, From, RoleID, _Discountid, Token, ItemType, ItemNum}) ->
	Ret = open_yvip_callback(RoleID, Token, ItemType, ItemNum),
	From ! Ret.

set_yvip_open_cb(_RoleID, ActId, Token) ->
	erlang:put({yvip_open, Token}, {ActId, Token}).

get_yvip_open_cb(Token) ->
	erlang:get({yvip_open, Token}).

erase_yvip_open_cb(Token) ->
	erlang:erase({yvip_open, Token}).

open_yvip_callback(RoleID, Token, ItemType, ItemNum) ->
	mod_qq:send_yvip_to_client(RoleID, false),
	mod_map_role:update_map_role_info(RoleID, [{#p_map_role.qq_yvip, mod_map_actor:get_map_qq_yvip(RoleID)}]),
	QQYvipRec = get_role_yvip_data(RoleID),
	Ret = case get_yvip_open_cb(Token) of
		undefined -> not_found;
		{ActId, Token} ->
			case ActId of
				1 -> %% 这个是与qq交互，获取活动token，然后发放奖励, todo:加上次数的限制
					case QQYvipRec#r_qq_yvip.zhi_zun_gift >= 5 of
						true -> ignore;
						false ->
							send_zhi_zun_gift(RoleID, ItemType, ItemNum, ?LOG_ITEM_TYPE_YVIP_XUFEI_GIFT),
							QQYvipRec1 = QQYvipRec#r_qq_yvip{
								zhi_zun_gift = QQYvipRec#r_qq_yvip.zhi_zun_gift + 1
							},
							send_xufei_data_to_client(RoleID, QQYvipRec1),
							{true, QQYvipRec1}
					end;
				2 -> %% 这个才记录豪华大礼包的续费次数
					QQYvipRec1 = QQYvipRec#r_qq_yvip{
						xufei_times = QQYvipRec#r_qq_yvip.xufei_times + 1
					},
					send_activity_data_to_client(RoleID, QQYvipRec1),
					{true, QQYvipRec1};
				7 -> %% 这里才能产生黄金钥匙 
					QQYvipRec1 = QQYvipRec#r_qq_yvip{
						keys = QQYvipRec#r_qq_yvip.keys + 1
					},
					send_lottery_data_to_client(RoleID, QQYvipRec1),
					{true, QQYvipRec1};
				_ -> %% 其他的ActId没有数据可更新的
					erase_yvip_open_cb(Token),
					ignore
			end;
		Data ->
			?ERROR_MSG("Data: ~w", [Data]),
			not_found
	end,
	case Ret of
		{true, NewQQYvipRec} ->
			erase_yvip_open_cb(Token),
			set_role_yvip_data(RoleID, NewQQYvipRec),
			ok;
		_ -> Ret
	end.

%% 发放黄钻至尊礼包
send_zhi_zun_gift(RoleId, _ItemType, _ItemNum, LogType) ->
	AwardItem = cfg_qq:get_award(1),
	Items = [{AwardItem, 1, ?TYPE_ITEM, true}],
	case mod_bag:add_items(RoleId, Items, LogType) of
		{true, _} -> ok;
		_ ->
			CreateInfoList = common_misc:get_items_create_info(RoleId, Items),
			GoodsList      = common_misc:get_mail_items_create_info(RoleId, CreateInfoList),
			Text           = "",
			Title          = "黄钻至尊礼包",
			common_letter:sys2p(RoleId, Text, Title, GoodsList, 14)
	end.

do_get_daily_gift(RoleID, QQYvipRec, YvipLevel) ->
	Awards = cfg_qq:get_daily_gift(YvipLevel),
	Ret = case QQYvipRec#r_qq_yvip.has_daily_gift of
		true ->
			{ok, FreeBagNum} = mod_bag:get_empty_bag_pos_num(RoleID, 1),
			case FreeBagNum >= length(Awards) of
				true  -> true;
				false -> {error, ?_LANG_SHOP_BAG_NOT_ENOUGH}
			end;
		false -> {error, <<"您今天的礼包已领取完了">>}
	end,
	case Ret of
		{error, _} -> Ret;
		true ->
			LogType  = ?LOG_ITEM_TYPE_YVIP_DAILY_GIFT,
			mod_bag:add_items(RoleID, Awards, LogType),
			QQYvipRec1 = QQYvipRec#r_qq_yvip{
				has_daily_gift = false
			},
			send_privilege_data_to_client(RoleID, QQYvipRec1),
			{true, QQYvipRec1}
	end.

do_get_yearly_gift(RoleID, QQYvipRec, IsYearYvip) ->
	Awards = cfg_qq:get_award(4),
	Ret = if
		IsYearYvip == false ->
			{error, <<"您不是黄钻年费用户，不能领取该奖励">>};
		QQYvipRec#r_qq_yvip.has_yearly_gift == false ->
			{error, <<"您今天的礼包已领取完了">>};
		true ->
			{ok, FreeBagNum} = mod_bag:get_empty_bag_pos_num(RoleID, 1),
			case FreeBagNum >= length(Awards) of
				true  -> true;
				false -> {error, ?_LANG_SHOP_BAG_NOT_ENOUGH}
			end
	end,
	case Ret of
		{error, _} -> Ret;
		true ->
			LogType  = ?LOG_ITEM_TYPE_YVIP_YEARLY_GIFT,
			mod_bag:add_items(RoleID, Awards, LogType),
			QQYvipRec1 = QQYvipRec#r_qq_yvip{
				has_yearly_gift = false
			},
			send_privilege_data_to_client(RoleID, QQYvipRec1),
			{true, QQYvipRec1}
	end.

do_get_newer_gift(RoleID, QQYvipRec) ->
	Awards = cfg_qq:get_award(5),
	Ret = if
		QQYvipRec#r_qq_yvip.has_newer_gift == false ->
			{error, <<"您的礼包已领取过了">>};
		true ->
			{ok, FreeBagNum} = mod_bag:get_empty_bag_pos_num(RoleID, 1),
			case FreeBagNum >= length(Awards) of
				true  -> true;
				false -> {error, ?_LANG_SHOP_BAG_NOT_ENOUGH}
			end
	end,
	case Ret of
		{error, _} -> Ret;
		true ->
			LogType  = ?LOG_ITEM_TYPE_YVIP_NEWER_GIFT,
			mod_bag:add_items(RoleID, Awards, LogType),
			QQYvipRec1 = QQYvipRec#r_qq_yvip{
				has_newer_gift = false
			},
			send_privilege_data_to_client(RoleID, QQYvipRec1),
			{true, QQYvipRec1}
	end.

do_get_pet(RoleID, QQYvipRec) ->
 	ItemTypeId = cfg_qq:get_award(6),
	Ret = if
		QQYvipRec#r_qq_yvip.has_pet_gift == false ->
			{error, <<"您的灵宠已领取过了">>};
		true ->
			{ok, FreeBagNum} = mod_bag:get_empty_bag_pos_num(RoleID, 1),
			case FreeBagNum >= 1 of
				true  -> true;
				false -> {error, ?_LANG_SHOP_BAG_NOT_ENOUGH}
			end
	end,
	case Ret of
		{error, _} -> Ret;
		true ->
			LogType  = ?LOG_ITEM_TYPE_YVIP_PET_GIFT,
			mod_bag:add_items(RoleID, [{ItemTypeId, 1, 1, true}], LogType),
			QQYvipRec1 = QQYvipRec#r_qq_yvip{
				has_pet_gift = false
			},
			send_privilege_data_to_client(RoleID, QQYvipRec1),
			{true, QQYvipRec1}
	end.

do_get_big_gift(RoleID, QQYvipRec, GiftId) ->
	ItemTypeId = cfg_qq:get_big_gift(GiftId),
	Now = calendar:local_time(),
	{BeginTime, EndTime} = cfg_qq:get_time_limit(2),
	NeedXufeiTimes = cfg_qq:big_gift_xufei_times(GiftId),
	Ret = if
		QQYvipRec#r_qq_yvip.xufei_times < NeedXufeiTimes ->
			{error, <<"续费次数不够，不能领取">>};
		QQYvipRec#r_qq_yvip.xufei_big_gift + 1 /= GiftId ->
			{error, <<"请先领取前面的豪华大礼包">>};
		ItemTypeId == [] ->
			{error, <<"已经没有大礼包可以领取了">>};
		Now < BeginTime orelse Now > EndTime ->
			{error, <<"活动已过期">>};
		true ->
			{ok, FreeBagNum} = mod_bag:get_empty_bag_pos_num(RoleID, 1),
			case FreeBagNum >= 1 of
				true  -> true;
				false -> {error, ?_LANG_SHOP_BAG_NOT_ENOUGH}
			end
	end,
	case Ret of
		{error, _} -> Ret;
		true ->
			LogType  = ?LOG_ITEM_TYPE_YVIP_BIG_GIFT,
			mod_bag:add_items(RoleID, [{ItemTypeId, 1, 1, true}], LogType),
			QQYvipRec1 = QQYvipRec#r_qq_yvip{
				xufei_big_gift = QQYvipRec#r_qq_yvip.xufei_big_gift + 1
			},
			send_activity_data_to_client(RoleID, QQYvipRec1),
			{true, QQYvipRec1}
	end.

do_chou_jiang(RoleID, QQYvipRec) ->
	Now = calendar:local_time(),
	{BeginTime, EndTime} = cfg_qq:get_time_limit(7),
	Ret = if
		QQYvipRec#r_qq_yvip.keys =< 0  ->
			{error, <<"您已无黄钻钥匙了">>};
		QQYvipRec#r_qq_yvip.do_times >= 10  ->
			{error, <<"您今天的抽奖次数已满，请明天再来">>};
		Now < BeginTime orelse Now > EndTime ->
			{error, <<"活动已过期">>};
		true ->
			{ok, FreeBagNum} = mod_bag:get_empty_bag_pos_num(RoleID, 1),
			case FreeBagNum >= 1 of
				true  -> true;
				false -> {error, ?_LANG_SHOP_BAG_NOT_ENOUGH}
			end
	end,
	case Ret of
		{error, _} -> Ret;
		true ->
			{ItemTypeId, Selected} = random_chou_jiang(),
			LogType    = ?LOG_ITEM_TYPE_YVIP_CHOU_JIANG,
			mod_bag:add_items(RoleID, [{ItemTypeId, 1, 1, true}], LogType),
			QQYvipRec1 = QQYvipRec#r_qq_yvip{
				keys     = QQYvipRec#r_qq_yvip.keys - 1,
				do_times = QQYvipRec#r_qq_yvip.do_times + 1
			},
			Msg = #m_qq_yvip_lottery_result_toc{selected = Selected, item = ItemTypeId},
			?MOD_UNICAST(RoleID, ?QQ_YVIP_LOTTERY_RESULT, Msg),
			send_lottery_data_to_client(RoleID, QQYvipRec1),
			{true, QQYvipRec1}
	end.

random_chou_jiang() ->
	{ItemTypeId, _} = common_tool:random_from_tuple_weights(cfg_qq:get_chou_jiang_weights(), 2),
	{ItemTypeId, common_tool:random(1, 10)}.

send_xufei_data_to_client(RoleID, QQYvipRec)	->
	Now = calendar:local_time(),
	{BeginTime, EndTime} = cfg_qq:get_time_limit(1),
	case Now >= BeginTime andalso Now =< EndTime of
		false -> 
			Msg = #m_qq_yvip_xufei_toc{show_xufei_activity = false};
		true ->
			Msg = #m_qq_yvip_xufei_toc{
				show_xufei_activity  = true, 
				zhi_zun_gift         = QQYvipRec#r_qq_yvip.zhi_zun_gift,
				xufei_activity_begin = common_tool:time_format(BeginTime),
				xufei_activity_end   = common_tool:time_format(EndTime)
			}
	end,
	?MOD_UNICAST(RoleID, ?QQ_YVIP_XUFEI, Msg).

send_privilege_data_to_client(RoleID, QQYvipRec) ->	
	Msg = #m_qq_yvip_privilege_toc{
		has_daily_gift  = QQYvipRec#r_qq_yvip.has_daily_gift, 
		has_newer_gift  = QQYvipRec#r_qq_yvip.has_newer_gift,
		has_yearly_gift = QQYvipRec#r_qq_yvip.has_yearly_gift,
		has_pet_gift    = QQYvipRec#r_qq_yvip.has_pet_gift
	},
	?MOD_UNICAST(RoleID, ?QQ_YVIP_PRIVILEGE, Msg).

send_activity_data_to_client(RoleID, QQYvipRec) ->
	{BeginTime, EndTime} = cfg_qq:get_time_limit(2),
	%% 设置奖励状态(0:无奖励,1:有但未领取,2:已领取)
	Fun = fun(GiftId, Acc) ->
		case QQYvipRec#r_qq_yvip.xufei_times >= cfg_qq:big_gift_xufei_times(GiftId) of
			true -> 
				case QQYvipRec#r_qq_yvip.xufei_big_gift >= GiftId of
					true ->  S = 2;
					false -> S = 1
				end;
			false -> S = 0
		end,
		[{GiftId, S} | Acc]
	end,

	Msg = #m_qq_yvip_activity_toc{
		xufei_times    = QQYvipRec#r_qq_yvip.xufei_times, 
		xufei_big_gift = lists:foldl(Fun, [], [1,2,3,4,5]),
		activity_begin = common_tool:time_format(BeginTime),
		activity_end   = common_tool:time_format(EndTime)
	},
	?MOD_UNICAST(RoleID, ?QQ_YVIP_ACTIVITY, Msg).

send_lottery_data_to_client(RoleID, QQYvipRec) ->
	{BeginTime, EndTime} = cfg_qq:get_time_limit(7),
	Msg = #m_qq_yvip_lottery_toc{
		keys           = QQYvipRec#r_qq_yvip.keys, 
		do_times       = QQYvipRec#r_qq_yvip.do_times,
		activity_begin = common_tool:time_format(BeginTime),
		activity_end   = common_tool:time_format(EndTime)
	},
	?MOD_UNICAST(RoleID, ?QQ_YVIP_LOTTERY, Msg).

