%% Author: dizengrong
%% Created: 2012-11-12
%% @doc: 这里实现的是t6项目中宠物砸蛋功能

-module (mod_pet_da_dan).

-include("mgeem.hrl").

-export([handle/3]).

%% export for role_misc callback
-export([init/2, delete/1,refresh_daily_counter_times/2]).

-define(DA_DAN_DATA, da_dan_data).
-define(MOD_UNICAST(RoleID, Method, Msg), 
		common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?PET, Method, Msg)).

refresh_daily_counter_times(RoleID,RemainTimes1) when erlang:is_integer(RemainTimes1) ->
	case get({?DA_DAN_DATA, RoleID}) of
		#r_pet_da_dan{update_time = UpdateTime,left_free_times = LeftFreeTimes} = PetDaDanRec ->
			
			if
				RemainTimes1 > 0 ->
					set_da_dan_info(RoleID, PetDaDanRec#r_pet_da_dan{left_free_times=RemainTimes1}),
					IsNotyfy = true,
					RemainTimes = RemainTimes1;
				true ->
					Now = common_tool:now(),
					case common_tool:check_if_same_day(UpdateTime, Now) of
						true -> 
							RemainTimes = LeftFreeTimes;
						false -> 
							RemainTimes = cfg_pet_da_dan:get_misc(white_free_times)
					
					end,
					IsNotyfy = false
			end,
			mod_daily_counter:set_mission_remain_times(RoleID, 1015, erlang:max(0, RemainTimes),IsNotyfy);
		_ ->
			ignore
	end.

init(RoleID, PetDaDanRec) ->
	case PetDaDanRec of
		false ->
			PetDaDanRec1 = #r_pet_da_dan{
				left_free_times = cfg_pet_da_dan:get_misc(white_free_times),
				total_times     = 0,
				update_time     = common_tool:now(), 
				silver_times 	= cfg_pet_da_dan:get_misc(silver_times)
			};
		_ ->
			PetDaDanRec1 = PetDaDanRec
	end,
	set_da_dan_info(RoleID, PetDaDanRec1).

delete(RoleID) ->
	erlang:erase({?DA_DAN_DATA, RoleID}).

%% =========================== 进程字典操作接口 ==========================	
set_da_dan_info(RoleID, PetDaDanRec) ->
	erlang:put({?DA_DAN_DATA, RoleID}, PetDaDanRec).

get_da_dan_info(RoleID)	->
	PetDaDanRec = erlang:get({?DA_DAN_DATA, RoleID}),
	Now = common_tool:now(),
	case common_tool:check_if_same_day(PetDaDanRec#r_pet_da_dan.update_time, Now) of
		true -> 
			PetDaDanRec;
		false -> %% 砸蛋次数隔天重置
			PetDaDanRec1 = PetDaDanRec#r_pet_da_dan{
				total_times     = 0,
				update_time     = Now,
				left_free_times = cfg_pet_da_dan:get_misc(white_free_times), 
				silver_times 	= cfg_pet_da_dan:get_misc(silver_times)
			},
			set_da_dan_info(RoleID, PetDaDanRec1),
			PetDaDanRec1
	end.
%% =========================== 进程字典操作接口 ==========================	

handle(Method, RoleID, DataIn) ->
	case Method of
		?PET_DA_DAN_INFO ->
			do_get_info(RoleID);
		?PET_DA_DAN ->
			do_da_dan(RoleID, DataIn)
	end.

do_get_info(RoleID) ->
	PetDaDanRec = get_da_dan_info(RoleID),
	send_da_dan_info_to_client(RoleID, PetDaDanRec).

send_da_dan_info_to_client(RoleID, PetDaDanRec) ->
	TotalDaDanTimes = PetDaDanRec#r_pet_da_dan.total_times,
	Msg = #m_pet_da_dan_info_toc{
		left_free_times = PetDaDanRec#r_pet_da_dan.left_free_times,
		next_cost       = cfg_pet_da_dan:get_da_white_dan_cost(erlang:min(cfg_pet_da_dan:get_misc(silver_times), TotalDaDanTimes + 1)),
		silver_dan_cost = cfg_pet_da_dan:get_misc(silver_dan_cost),
		gold_dan_cost   = cfg_pet_da_dan:get_misc(golden_dan_cost), 
		silver_times 	= PetDaDanRec#r_pet_da_dan.silver_times
	},
	?MOD_UNICAST(RoleID, ?PET_DA_DAN_INFO, Msg).

do_da_dan(RoleID, DataIn) ->
	DanType     = DataIn#m_pet_da_dan_tos.egg_type,
	PetDaDanRec = get_da_dan_info(RoleID),
	
	ItemTypeIds = do_da_dan_random(DanType),
	Fun = fun() -> t_do_da_dan(RoleID, DanType, ItemTypeIds, PetDaDanRec) end,
	case common_transaction:t(Fun) of
		{atomic, {ok, MoneyType, RoleAttr, GoodsList}} ->
			update_da_dan_data(RoleID, PetDaDanRec, DanType),
			case GoodsList of
				[] -> ignore;
				_ ->
					%% 记录物品日志和通知客户端
					common_misc:update_goods_notify({role, RoleID}, GoodsList),
		    		LogType1 = ?LOG_ITEM_TYPE_DA_DAN_GAIN,
		    		common_item_logger:log(RoleID, GoodsList, LogType1)
		    end,
    		%% 通知客户端money的改变
    		if
    			MoneyType == no_cost -> 
    				ignore;
            	((MoneyType == gold_unbind) orelse (MoneyType == gold_any)) ->
                	common_misc:send_role_gold_change(RoleID, RoleAttr);
                true ->
                	common_misc:send_role_silver_change(RoleID, RoleAttr)
            end,
            check_and_do_broadcast(RoleID, ItemTypeIds, cfg_pet_da_dan:get_card(orange)),
            [common_misc:common_broadcast_item_get(RoleID, ItemTypeId, ?MODULE) || ItemTypeId <- ItemTypeIds],
            case DanType of
            	?PET_DAN_GOLDEN -> 
            		%% 完成成就
           			mod_achievement2:achievement_update_event(RoleID, 43006, 1);
           		_ -> ignore
           	end,
                            
            mod_score:gain_score_notify(RoleID, cfg_score:get_da_dan_score(DanType), ?SCORE_TYPE_DADAN,{?SCORE_TYPE_DADAN,"天赐灵宠获得积分"}),
			mod_random_mission:handle_event(RoleID, ?RAMDOM_MISSION_EVENT_16),
			%% 完成活动
			hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_DA_DAN),
			% hook_mission_event:hook_special_event(RoleID,?MISSION_EVENT_DADAN),
			mgeer_role:send(RoleID, {apply, hook_mission_event, hook_special_event, [RoleID, ?MISSION_EVENT_DADAN]}),
			mod_role_event:notify(RoleID, {?ROLE_EVENT_PET_ZD, 1}),
            ItemTypeIds1 = ItemTypeIds;
		{aborted, {common_error, Reason}} ->
			ItemTypeIds1 = [],
			common_misc:send_common_error(RoleID, 0, Reason);
		{aborted, {bag_error, _Reason}} ->
			ItemTypeIds1 = [],
			common_misc:send_common_error(RoleID, 0, ?_LANG_GOODS_BAG_NOT_ENOUGH)
	end,
	Msg = #m_pet_da_dan_toc{
		egg_type = DanType,
		cards    = ItemTypeIds1
	},
	?MOD_UNICAST(RoleID, ?PET_DA_DAN, Msg).

check_and_do_broadcast(_RoleID, [], _AllOrangeCards) -> ok;
check_and_do_broadcast(RoleID, [ItemTypeId | Rest], AllOrangeCards) ->
	case lists:member(ItemTypeId, AllOrangeCards) of
		true ->
			{ok,#p_role_base{role_name=RoleName}} = mod_map_role:get_role_base(RoleID),
			[#p_item_base_info{itemname = GoodsName}] = common_config_dyn:find(item, ItemTypeId),
    		Text = common_misc:format_lang(?_LANG_PET_DA_DAN, [RoleName,GoodsName]),
    		?WORLD_CENTER_BROADCAST(Text),
    		?WORLD_CHAT_BROADCAST(Text);
    	false -> 
    		check_and_do_broadcast(RoleID, Rest, AllOrangeCards)
    end.


t_do_da_dan(RoleID, DanType, [], PetDaDanRec) ->
	{ok, MoneyType, RoleAttr} = t_do_da_dan2(RoleID, DanType, PetDaDanRec),
	{ok, MoneyType, RoleAttr, []};
t_do_da_dan(RoleID, DanType, ItemTypeIds, PetDaDanRec) ->
	Items = [{Id, 1, ?TYPE_ITEM, true} || Id <- ItemTypeIds],
	CreateInfoList  = common_misc:get_items_create_info(RoleID, Items),
	{ok, GoodsList} = mod_bag:create_goods(RoleID, CreateInfoList),
	{ok, MoneyType, RoleAttr} = t_do_da_dan2(RoleID, DanType, PetDaDanRec),
	{ok, MoneyType, RoleAttr, GoodsList}.

t_do_da_dan2(RoleID, DanType, PetDaDanRec) ->
	case get_da_dan_cost(DanType, PetDaDanRec) of
		no_cost ->
			MoneyType = no_cost, RoleAttr = undefined;
		{MoneyType, Cost} ->
			case MoneyType == silver_any orelse MoneyType == silver_unbind of
				true ->  Log = ?CONSUME_TYPE_SILVER_PET_DA_DAN;
				false -> Log = ?CONSUME_TYPE_GOLD_PET_DA_DAN
			end,
			case common_bag2:t_deduct_money(MoneyType, Cost, RoleID, Log) of
				{error, Reason} ->
					RoleAttr = undefined,
					throw({common_error, Reason});
				{ok, RoleAttr} ->
					mod_map_role:set_role_attr(RoleID, RoleAttr)
			end
	end,
	{ok, MoneyType, RoleAttr}.

get_da_dan_cost(DanType, PetDaDanRec) ->
	case DanType of
		?PET_DAN_WHITE ->
			case PetDaDanRec#r_pet_da_dan.left_free_times > 0 of
				true -> no_cost;
				false ->
					case PetDaDanRec#r_pet_da_dan.silver_times > 0 of
						true ->
							DaDanTimes = PetDaDanRec#r_pet_da_dan.total_times,
							{silver_any, cfg_pet_da_dan:get_da_white_dan_cost(DaDanTimes + 1)};
						false ->
							throw({common_error, <<"今天砸铜蛋的次数用完了, 请明天继续!">>})
					end
			end;
		?PET_DAN_SILVER ->
			{gold_any, cfg_pet_da_dan:get_misc(silver_dan_cost)};
		?PET_DAN_GOLDEN ->
			{gold_unbind, cfg_pet_da_dan:get_misc(golden_dan_cost)}
	end.

update_da_dan_data(RoleID, PetDaDanRec, DanType) ->
	case DanType of
		?PET_DAN_WHITE ->
			case PetDaDanRec#r_pet_da_dan.left_free_times > 0 of 
				true ->
					PetDaDanRec1 = PetDaDanRec#r_pet_da_dan{
						total_times     = PetDaDanRec#r_pet_da_dan.total_times + 1,
						left_free_times = PetDaDanRec#r_pet_da_dan.left_free_times - 1
					};
				false ->
					PetDaDanRec1 = PetDaDanRec#r_pet_da_dan{
						total_times     = PetDaDanRec#r_pet_da_dan.total_times + 1,
						silver_times 	= PetDaDanRec#r_pet_da_dan.silver_times - 1
					}
			end,

			mod_daily_counter:set_mission_remain_times(RoleID, 1015, erlang:max(0, PetDaDanRec#r_pet_da_dan.left_free_times - 1),true),
			set_da_dan_info(RoleID, PetDaDanRec1),
			send_da_dan_info_to_client(RoleID, PetDaDanRec1);
		_ ->
			ignore
	end.

do_da_dan_random(DanType) ->
	{ItemTypeId, _} = common_tool:random_from_tuple_weights(cfg_pet_da_dan:get_items(DanType), 2),
	case is_atom(ItemTypeId) of
		true -> %% 表示出的是宠物卡
			[get_one_card(ItemTypeId)];
		false ->
			[ItemTypeId]
	end.

get_one_card(CardItemType) ->
	ItemTypeIdList = cfg_pet_da_dan:get_card(CardItemType),
	Nth = common_tool:random(1, length(ItemTypeIdList)),
	lists:nth(Nth, ItemTypeIdList).

