%% Author: xierongfeng
%% Created: 2012-12-30
%% Description: 时间礼包
-module(mod_time_gift).

-include("mgeem.hrl").
%%
%% Exported Functions
%%
-export([init/2, delete/1]).

-export([send_time_gift/1, timeout/0, handle/1]).

-define(_time_gift_list, ?DEFAULT_UNIQUE, ?LEVEL_GIFT, ?TIME_GIFT_LIST, #m_time_gift_list_toc).
-define(_time_gift_accept, Unique, ?LEVEL_GIFT, ?TIME_GIFT_ACCEPT, #m_time_gift_accept_toc).

%%
%% =====================API Functions=====================================
%%
init(RoleID, TimeGift) ->
	TimeGift2 = case is_record(TimeGift, r_role_time_gift) of
		true ->
			get_new_gift(RoleID, TimeGift);
		_ ->
			get_time_gift(RoleID, 100)
	end,
	put(r_role_time_gift, TimeGift2).

delete(_RoleID) ->
	case erase(r_role_time_gift) of
		TimeGift when is_record(TimeGift, r_role_time_gift) ->
			RemSecs = case erase(time_gift_timer) of
				Timer when is_reference(Timer) ->
					case erlang:read_timer(Timer) of
						false -> 0;
						Secs  -> Secs div 1000
					end;
				_ ->
					0
			end,
			TimeGift#r_role_time_gift{secs = RemSecs};
		_ ->
			undefined
	end.

send_time_gift(RoleID)->
	case common_config:chk_module_method_open(?LEVEL_GIFT, ?TIME_GIFT_LIST) of
		true->
			case get(r_role_time_gift) of
				#r_role_time_gift{id=ID, gift_id=GiftID, secs=Secs} ->
					case common_config_dyn:find(gift, GiftID) of
						[#r_gift{}] ->
							Secs2 = case get(time_gift_timer) of
								Timer when is_reference(Timer) ->
									case erlang:read_timer(Timer) of
										false ->
											0;
										Secs1 ->
											Secs1 div 1000
									end;
								_ ->
									Timer2 = erlang:send_after(Secs*1000, self(), {apply, ?MODULE, timeout, []}),
									put(time_gift_timer, Timer2),
									Secs
							end,

							CanFlag = Secs2 == 0,
							TimeGift = #p_time_gift_info{
								id         = cfg_gift:get_circle_id(ID), 
								time 	   = common_tool:now() + Secs2, 
								can_geted = CanFlag
								% time       = Secs2
							},
							common_misc:unicast({role, RoleID}, ?_time_gift_list{gift=TimeGift});
						_ ->
							TimeGift = #p_time_gift_info{
								id         = cfg_gift:get_circle_id(ID), 
								time 	   = 0, 
								can_geted = false
								% time       = Secs2
							},
							common_misc:unicast({role, RoleID}, ?_time_gift_list{gift=TimeGift})
					end;
				_ ->
					ignore
			end;
		{false,_Reason}->
			ignore
	end.

timeout() ->
	erase(time_gift_timer),
	TimeGift = get(r_role_time_gift),
	put(r_role_time_gift, TimeGift#r_role_time_gift{secs = 0}).

handle({clear_timegift, _PID, RoleID}) ->
	TimeGift = get_new_gift(RoleID, #r_role_time_gift{}),
	put(r_role_time_gift, TimeGift),
	send_time_gift(RoleID);

handle({time_gift, PID, RoleID}) ->
	TimeGift = get(r_role_time_gift),

	#r_role_time_gift{gift_id=GiftID} = TimeGift, 
	DataIn = #m_time_gift_accept_tos{id =GiftID},
	Unique = 0, 
	case get_gift(RoleID, GiftID) of
		{ok, GoodsList} ->
			time_gift_acept(RoleID, GoodsList, DataIn, PID, Unique, TimeGift);
		{error, Error} ->
			common_misc:unicast({role, RoleID}, ?_time_gift_accept{reason=Error})
	end;

handle({Unique, ?LEVEL_GIFT, ?TIME_GIFT_ACCEPT, DataIn, RoleID, PID, _Line, _State}) ->
	%%要获取的时间礼包id
	TimeGift = get(r_role_time_gift),
    case check_accept(RoleID, TimeGift) of
        {error, Error} ->
			common_misc:unicast({role, RoleID}, ?_time_gift_accept{reason=Error});
        {ok, GoodsList} ->
        	time_gift_acept(RoleID, GoodsList, DataIn, PID, Unique, TimeGift)
    end.

%%
%% ==========================Local Functions======================================
%%`

time_gift_acept(RoleID, GoodsList, DataIn, PID, Unique, TimeGift) ->
	case common_transaction:transaction(fun() ->
				% mod_bag:create_goods_by_p_goods(RoleID,GoodsList)
				mod_bag:create_goods(RoleID,GoodsList)
		end) of
        {atomic,{ok,NewGoodsList}} ->
            log_gift_goods(RoleID, [GoodsList]),
			common_misc:update_goods_notify({role,RoleID}, NewGoodsList),                   
			common_misc:unicast2(PID, ?_time_gift_accept{
				succ=true, gift_id=DataIn#m_time_gift_accept_tos.id}),

			TimeGift1 = get_time_gift(RoleID, TimeGift#r_role_time_gift.id, TimeGift),
			TimeGift2 = get_new_gift(
				RoleID, TimeGift1#r_role_time_gift{id = TimeGift1#r_role_time_gift.id}
			),
			put(r_role_time_gift, TimeGift2),
            send_time_gift(RoleID);
        {aborted,{bag_error,{not_enough_pos,_BagID}}} ->
			common_misc:unicast2(PID, ?_time_gift_accept{reason=?_LANG_TIME_GIFT_ENOUGH_POS});
        {aborted, Reason} ->
            ?ERROR_MSG("Accept time gift error:~w~n", [Reason]),
			common_misc:unicast2(PID, ?_time_gift_accept{reason=?_LANG_TIME_GIFT_SYSTEM_ERROR})
    end.

get_new_gift(RoleID, TimeGift) ->
	Date = date(),
	case TimeGift#r_role_time_gift.date == Date of
		true ->
			TimeGift#r_role_time_gift{date=Date};
		_ ->
			TimeGift2 = get_time_gift(RoleID, 100),
			TimeGift2#r_role_time_gift{date=Date}
	end.

get_time_gift(RoleID, ID) ->
	TimeGift = get(r_role_time_gift),
	get_time_gift(RoleID, ID, TimeGift).

get_time_gift(RoleID, ID, TimeGift) ->
	{ok, #p_role_attr{level = RoleLv}} = mod_map_role:get_role_attr(RoleID),
	TimeGift1 = cfg_gift:time_gift(ID + 1, RoleLv),

	Date = case TimeGift of
		undefined ->
			erlang:date();
		_ ->
			TimeGift#r_role_time_gift.date
	end, 
	TimeGift1#r_role_time_gift {
		date = Date
	}.

% create_gift_goods_list(RoleID,GiftBaseList)->
% 	GoodsList = lists:foldl(fun
% 	 	(GiftBase,Acc) ->
% 			{ok, TempGoodsList} = mod_bag:create_p_goods(RoleID, #r_goods_create_info{
% 				bind       = GiftBase#p_gift_goods.bind, 
% 				type       = GiftBase#p_gift_goods.type, 
% 				start_time = GiftBase#p_gift_goods.start_time,
% 				end_time   = GiftBase#p_gift_goods.end_time,
% 				type_id    = GiftBase#p_gift_goods.typeid,
% 				num        = GiftBase#p_gift_goods.num,
% 				color      = GiftBase#p_gift_goods.color
%             }),
% 			lists:append(TempGoodsList, Acc)
%     end,[],GiftBaseList),
%     [Goods#p_goods{id=1,bagposition=0,bagid=0}||Goods<-GoodsList].

%%检查请求合法性
check_accept(RoleID, #r_role_time_gift{gift_id=GiftID, secs=Secs}) ->
	case Secs =< 0 of
		true ->
			get_gift(RoleID, GiftID);
		false ->
			{error, <<"领取礼包时间未到">>}
	end;

check_accept(_RoleID, _TimeGift) ->
	{error, ?_LANG_TIME_GIFT_NOT_GIFT}.

get_gift(_RoleID, GiftID) ->
	case common_config_dyn:find(gift, GiftID) of
		[_] ->
			CreateInfo = #r_goods_create_info{bind=true,type=1,start_time=0,end_time=0,
										  type_id=GiftID, num=1},
			{ok, CreateInfo};
		% [#r_gift{gift_list = GiftBaseList}] ->
		% 	{ok, create_gift_goods_list(RoleID, GiftBaseList)};
		_ ->
			{error, ?_LANG_TIME_GIFT_NOT_GIFT}
	end. 
	
%%写入日志
log_gift_goods(RoleID, GoodsList) ->
	lists:foreach(fun
		(Goods) ->
			common_item_logger:log(RoleID,Goods,?LOG_ITEM_TYPE_LI_BAO_HUO_DE)
	end, GoodsList).
