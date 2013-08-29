-module (common_debug).

-include("common.hrl").
-include("common_server.hrl"). 

-compile(export_all).

get_position(AccountName) ->
	RoleId = get_role_id(AccountName),
	case db:dirty_read(db_role_pos, RoleId) of
		[] -> erlang:throw("player not online");
		[RolePosRec] ->
			RolePosRec
	end.

%% AccountName为帐号名的二进制格式
get_role_id(AccountName) ->
	case db:dirty_read(db_role_name, AccountName) of
		[#r_role_name{role_id = RoleID}] ->
			RoleID;
		_ ->
			io:format("account_name_unexit")
	end.

%% AccountName为帐号名的二进制格式
%% 获取角色的某一进程字典数据
get_role_map_process(AccountName) when is_binary(AccountName) ->
	RolePosRec = get_position(AccountName),
	MapProcess = RolePosRec#p_role_pos.map_process_name,
	global:whereis_name(MapProcess);

get_role_map_process(RoleId) when is_integer(RoleId) ->
	case db:dirty_read(db_role_pos, RoleId) of
		[] ->
			RolePosRec = null,
			erlang:throw("player not online");
		[RolePosRec] ->
			RolePosRec
	end,
	MapProcess = RolePosRec#p_role_pos.map_process_name,
	global:whereis_name(MapProcess).

get_role_process_data(AccountName, Key) when is_binary(AccountName) ->
	Pid    = get_role_map_process(AccountName),
	gen_server:call(Pid, {get, Key});

get_role_process_data(RoleId, Key) when is_integer(RoleId) ->
	Pid    = get_role_map_process(RoleId),
	gen_server:call(Pid, {get, Key}).

%% 这个方法向地图进程发消息，并执行一个函数
call_function(AccountName, Mod, Func, Args) when is_binary(AccountName) ->
	Pid = get_role_map_process(AccountName),
	gen_server:call(Pid, {debug_call_function, Mod, Func, Args});
call_function(RoleId, Mod, Func, Args) when is_integer(RoleId) ->
	Pid = get_role_map_process(RoleId),
	gen_server:call(Pid, {debug_call_function, Mod, Func, Args}).


send_to_map(AccountName, Msg) when is_binary(AccountName) ->
	Pid = get_role_map_process(AccountName),
	io:format("the msg   ~p ~p ~n", [Pid, AccountName]),
	Pid ! Msg.

send_to_gateway(AccountName, Unique, Module, Method, Record) when is_binary(AccountName) ->
	RoleId = get_role_id(AccountName),
	GatewayPid = global:whereis_name(common_misc:get_role_line_process_name(RoleId)),
	GatewayPid ! {debug, Unique, Module, Method, Record}.


add_items(Id, Num, Items) ->
    case lists:keyfind(Id, 1, Items) of
        false -> lists:keystore(Id, 1, Items, {Id, Num});
        {Id, Num0} -> lists:keystore(Id, 1, Items, {Id, Num0 + Num})
    end.

find_score_deal_items() ->
	Items = [12011103, 12011091, 12011079, 12011067, 12011055, 12011043, 12011031, 12011019, 12011007],
	AllRoleBagList = db:dirty_match_object(db_role_bag, #r_role_bag{_ = '_'}),

	Fun1 = fun(Goods, Acc1) ->
	    case lists:member(Goods#p_goods.typeid, Items) of
	        true -> add_items(Goods#p_goods.typeid, Goods#p_goods.current_num, Acc1);
	        false -> Acc1
	    end
	end,

	Fun2 = fun(RoleBag, Acc2) ->
	    case RoleBag#r_role_bag.role_bag_key of
	        {RoleID, 1} ->
	            GoodsList = RoleBag#r_role_bag.bag_goods,
	            case lists:foldl(Fun1, [], GoodsList) of
	                [] -> Acc2;
	                HaveItems ->
	                    [{RoleID, HaveItems} | Acc2]
	            end;
	        _ -> Acc2
	    end
	end,
 
	Fun3 = fun({RoleID, HaveItems}) ->
	    [RoleBase]=db:dirty_match_object(db_role_base, #p_role_base{role_id = RoleID, _='_'}),
	    ?ERROR_MSG("RoleId: ~p, role_name: ~ts, account_name: ~ts, Items: ~w", 
	    	[RoleID, RoleBase#p_role_base.role_name, RoleBase#p_role_base.account_name, HaveItems])
	end,
	[Fun3(D) || D <- lists:foldl(Fun2, [], AllRoleBagList)].


pet_back_to_card() ->
	{ok, ItemLists} = file:consult("/data/mcqzj/config/map/item.config"),
	lists:usort(pet_back_to_card(ItemLists, [])).

pet_back_to_card([], BetterCards) -> BetterCards;
pet_back_to_card([Item | Rest], BetterCards) ->
	case Item#p_item_base_info.effects of
		undefined -> BetterCards1 = BetterCards;
		[Effect] ->
			case Effect#p_item_effect.funid == 29 andalso Item#p_item_base_info.colour >= 4 of
				true ->
					BetterCards1 = [{list_to_integer(Effect#p_item_effect.parameter), Item#p_item_base_info.typeid} | BetterCards];
				false ->
					BetterCards1 = BetterCards
			end
	end,
	pet_back_to_card(Rest, BetterCards1).


print_tili_time() ->
        Fun = fun(RoleId) ->
        {ok,#r_role_map_ext{role_tili=TiliInfo}} = mod_map_role:get_role_map_ext_info(RoleId),
        Time = calendar:seconds_to_daystime(TiliInfo#r_role_tili.last_auto_increase_time),
        ?ERROR_MSG("~p~n", [Time])
end,
[Fun(R) || R <- mod_map_actor:get_in_map_role()].

%%@doc 任务基础数据
-record(mission_base_info, {
    id,%% 任务ID
    name,%% 任务名
    type=0,%% 类型-1主-2支-3循 4-境界
    model,%% 模型处理模块
    big_group=0,%% 大组
    small_group=0,%% 小组
    time_limit_type=0,%% 时间限制类型--0无限制--1每天--2每周--3每月
    time_limit=[],%% #mission_time_limit
    pre_mission_id=0, %%前置任务ID
    next_mission_list=[], %%后置任务ID列表
    pre_prop_list=[], %%前置任务道具列表 #pre_mission_prop{}
    gender=0,%% 性别
    faction=0,%国家
    team=0,%% 是否需要组队
    family=0,%% 需要家族
    min_level=0,%% 最低等级限制
    max_level=0,%% 最高等级限制
    vip_level=0,%% 最低VIP级别
    max_do_times=1,%% 最多可以做的次数
    listener_list=[],%% #mission_listener_data 侦听器数据
    max_model_status=0,%% 最大状态的模型值从0开始算
    model_status_data=[],%% #mission_status_data 状态数据
    reward_data%% #mission_reward_data 奖励数据
}).
check_mission([]) -> ok;
check_mission([Id | Rest]) ->
	M = mission_data_detail:get(Id),
	case M#mission_base_info.id == M#mission_base_info.pre_mission_id of
		true -> 
			exit(M#mission_base_info.id);
		false ->
			ignore
	end,
	check_mission(Rest).
	