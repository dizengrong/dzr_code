%% Author: xierongfeng
%% Created: 2013-2-17
%% Description: 任务相关读条道具的实现
-module(mod_special_item).

%%
%% Include files
%%
-include("mgeer.hrl").

-record(mission_status_data_use_item, {
	item_id        = 0, %% 道具id
	map_id         = 0, %% 地图id
	tx             = 0, %% 位置
	ty             = 0, %% 位置
	total_progress = 0, %% 进度
	new_type_id    = 0, %% 新的道具id
	new_number     = 0, %% 道具数据
	show_name,			%% 显示名称
	progress_desc		%% 读条操作显示
}).

-define(_item_use_special, ?DEFAULT_UNIQUE, ?ITEM, ?ITEM_USE_SPECIAL, #m_item_use_special_toc).

%%
%% Exported Functions
%%
-export([
	handle/1,
	after_use_item/2,
	start_use_item/3,
	stop_use_item/2,
	set_use_item_busy/2,
	unset_use_item_busy/1
]).

%%
%% API Functions
%%
handle({_Unique, _Module, ?ITEM_USE_SPECIAL, DataIn, RoleID, PID}) ->
	#m_item_use_special_tos{item_id = UseID} = DataIn,
	{ok, UseInfo} = mod_mission_data:get_mission_item_use_point(RoleID, UseID),
	MapPID = get(map_pid),
	erlang:spawn(fun() ->
		case gen_server:call(MapPID, {apply, ?MODULE, start_use_item, [RoleID, UseInfo, self()]}) of
			ok ->
				#mission_status_data_use_item{
					total_progress = UseTime,
					progress_desc  = UseDesc
				} = UseInfo,
				[#p_item_base_info{effects = Effects}] = common_config_dyn:find_item(UseID),
				common_misc:unicast2(PID, ?_item_use_special{
					item_id        = UseID,
					succ           = true,
					use_status     = 1,
					total_progress = UseTime,
					use_effect     = if UseTime > 0 -> 2; true -> 1 end,
					effects        = Effects,
					progress_desc  = UseDesc
			    }),
				receive
					stop -> 
						MapPID ! {apply, ?MODULE, stop_use_item, [RoleID, UseID]}
				after
					UseTime*1000 -> 
						mgeer_role:send(RoleID, 
							{apply, ?MODULE, after_use_item, [RoleID, UseInfo]})
				end;
			{error, Reason} ->
				common_misc:unicast({role, RoleID}, ?_item_use_special{
					item_id        = UseID,
					succ           = false,
					reason 		   = Reason,
					use_status     = 0
			    })
		end
	end).

after_use_item(RoleID, UseInfo) ->
	#mission_status_data_use_item{
		item_id        = UseID,
		total_progress = UseTime,
		progress_desc  = UseDesc
	} = UseInfo,
	case delete_goods(RoleID, UseID) of
		{ok, UseGoods} ->
			common_item_logger:log(RoleID, UseGoods, 1, ?LOG_ITEM_TYPE_SPECIAL_USE_SHI_QU),
    		mod_mission_handler:handle({listener_dispatch, give_use_prop, RoleID, UseID}),
			common_misc:del_goods_notify({role, RoleID}, [UseGoods]),
			[#p_item_base_info{effects = Effects}] = common_config_dyn:find_item(UseID),
			common_misc:unicast({role, RoleID}, ?_item_use_special{
				item_id        = UseID,
				succ           = true,
				use_status     = 2,
				total_progress = UseTime,
                use_effect     = if UseTime > 0 -> 2; true -> 1 end,
                effects        = Effects,
                progress_desc  = UseDesc
		    });
		{error, Reason} ->
			common_misc:unicast({role, RoleID}, ?_item_use_special{
				item_id        = UseID,
				succ           = false,
				reason 		   = Reason,
				use_status     = 0
		    })
	end,
	mgeem_map:send({apply, ?MODULE, unset_use_item_busy, [RoleID]}).

start_use_item(RoleID, UseInfo, UseItemPID) ->
	case check_use_item(RoleID, UseInfo) of
		ok ->
			set_use_item_busy(RoleID, UseItemPID),
			ok;
		{error, Reason} ->
			{error, Reason}
	end.

stop_use_item(RoleID, UseID) ->
	mod_role_busy:unset(RoleID),
	common_misc:unicast({role, RoleID}, ?_item_use_special{
		item_id    = UseID,
		succ       = false,
		reason     = <<"使用道具被打断">>,
		use_status = 3,
		use_effect = 2
    }).

set_use_item_busy(RoleID, UseItemPID) ->
	mod_role_busy:set(RoleID, UseItemPID).

unset_use_item_busy(RoleID) ->
	mod_role_busy:unset(RoleID).

%%
%% Local Functions
%%
delete_goods(RoleID, UseID) ->
	case mod_bag:check_inbag_by_typeid(RoleID, UseID) of
		{ok, [UseGoods|_]} ->
			case common_transaction:t(fun
		      () ->
		          mod_bag:delete_goods(RoleID, [UseGoods#p_goods.id])
		    end) of 
		        {aborted, Reason} when is_binary(Reason) ->
					{error, Reason};
		        {aborted, Reason} ->
		            ?ERROR_MSG("~ts:~w~n",["使用特殊物品时错误",Reason]),
					{error, ?_LANG_SYSTEM_ERROR};
		        {atomic, {ok, _}} ->
					{ok, UseGoods}
		    end;
		_ ->
			{error,?_LANG_ITEM_SPECIAL_NOT_FIND}
	end.

check_use_item(RoleID, UseInfo) ->
	check(RoleID, UseInfo, [
		fun check_use_item_busy/2,
		fun check_role_state/2,
		fun check_horse_racing/2
	]).

check(_RoleID, _UseInfo, []) ->
	ok;
check(RoleID, UseInfo, [Fun|T]) ->
	case Fun(RoleID, UseInfo) of
		ok ->
			check(RoleID, UseInfo, T);
		{error, Reason} ->
			{error, Reason}
	end.

check_use_item_busy(RoleID, _UseInfo) ->
	case mod_role_busy:check(RoleID) of
		{error, Reason} ->
			{error, Reason};
		_ ->
			ok
	end.

check_role_state(RoleID, UseInfo) ->
	RoleMapInfo = mod_map_actor:get_actor_mapinfo(RoleID, role),
    case RoleMapInfo#p_map_role.state of
        ?ROLE_STATE_DEAD ->
            {error, ?_LANG_ITEM_SPECIAL_ROLE_STATE_DEAD};
        ?ROLE_STATE_FIGHT ->
            {error, ?_LANG_ITEM_SPECIAL_ROLE_STATE_FIGHT};
        ?ROLE_STATE_EXCHANGE ->
            {error, ?_LANG_ITEM_SPECIAL_ROLE_STATE_EXCHANGE};
        ?ROLE_STATE_ZAZEN ->
            {error, ?_LANG_ITEM_SPECIAL_ROLE_STATE_ZAZEN};
        ?ROLE_STATE_STALL ->
            {error, ?_LANG_ITEM_SPECIAL_ROLE_STATE_STALL};
        _ ->
			check_role_pos(RoleMapInfo#p_map_role.pos, UseInfo)
    end.

check_role_pos(#p_pos{tx=Tx1, ty=Ty1}, UseInfo) ->
	MapID1 = mgeem_map:get_mapid(),
	#mission_status_data_use_item{
		map_id = MapID2,
		tx 	   = Tx2,
		ty     = Ty2
	} = UseInfo,
	if 
		MapID1 =/= MapID2 orelse abs(Tx1-Tx2) > 1 orelse abs(Ty1-Ty2) > 1 ->
			[MapName2] = common_config_dyn:find(map_info, MapID2),
            {error, common_tool:get_format_lang_resources(
			   ?_LANG_ITEM_SPECIAL_USE_POS, [MapName2, Tx2, Ty2])};
        true ->
            ok
    end.

check_horse_racing(RoleID, _UseInfo) ->
	case mod_horse_racing:is_role_in_horse_racing(RoleID) of
        true ->
            {error, ?_LANG_ITEM_SPECIAL_ROLE_STATE_HORSE_RACING};
        _ ->
            ok
    end.