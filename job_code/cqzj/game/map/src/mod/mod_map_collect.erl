-module(mod_map_collect).

-include("mgeem.hrl").

-record(p_collect_info, {
    collect_type = 0, %% 0:为采集的道具, 1:为怒气球（加怒气的值为collect_item字段）
	collect_item = 0, %% collect_type为1时，为怒气的权重列表[{权重, 怒气值}]
	collect_skin = 0,
	collect_name = "",
	collect_limi = 0, %% 数量限制
	collect_time = 2,
	refresh_time = 2, %% 0:不消失；-1:不刷新
	mission_hook = true
}).

-export([
	init/1,
	new_collect/4, 
	handle/1,
	stop_collect/2, 
	after_collect/2,
	unset_collect_busy/2,
	refresh_collect/2,
	refresh_collect/3,
	update_grafts/2, 
	update_grafts/5,
	remove_grafts/2,
	get_collect_by_slice_list/1
]).

-define(_get_grafts, 		?DEFAULT_UNIQUE, ?COLLECT, ?COLLECT_GET_GRAFTS_INFO,	#m_collect_get_grafts_info_toc).%}
-define(_collect_grafts,	?DEFAULT_UNIQUE, ?COLLECT, ?COLLECT_GRAFTS,				#m_collect_grafts_toc).%}
-define(_update_grafts,		?DEFAULT_UNIQUE, ?COLLECT, ?COLLECT_UPDATA_GRAFTS,		#m_collect_updata_grafts_toc).%}
-define(_remove_grafts,		?DEFAULT_UNIQUE, ?COLLECT, ?COLLECT_REMOVE_GRAFTS,		#m_collect_remove_grafts_toc).%}

%%
%% API Functions
%%

%%开始采集
handle({_Unique, _Module, ?COLLECT_GET_GRAFTS_INFO, DataIn, RoleID, PID, _Line, State}) ->
	#m_collect_get_grafts_info_tos{id=PointID} = DataIn,
	case check_collect(RoleID, PointID, State) of
		{ok, CollMapInfo} ->
        	mod_role_mount:do_mount_down(RoleID),
			#p_collect_info{collect_time = CollectTime}  = cfg_collect:point(PointID),
			MapPID = self(),
			ColPID = spawn(fun() ->
				receive
					stop -> 
						MapPID ! {apply, ?MODULE, stop_collect, [RoleID, PointID]}
				after 
					CollectTime*1000 -> 
						mgeer_role:send(RoleID, {apply, ?MODULE, after_collect, [RoleID, PointID]})
				end
			end),
			set_collect_busy(RoleID, PointID, ColPID),
			common_misc:unicast2(PID, ?_get_grafts{succ = true, info = CollMapInfo});
		{error, Reason} ->
			common_misc:unicast2(PID, ?_get_grafts{succ = false, reason = Reason})
	end;

%%停止采集
handle({_Unique, _Module, ?COLLECT_STOP, _DataIn, RoleID, _PID, _Line, _State}) ->
	mod_role_busy:stop(RoleID);    

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).

init(MapID) ->
	cfg_collect:cant_collect(MapID) orelse
	lists:foreach(fun({PointID, TX, TY}) ->
		new_collect(MapID, PointID, TX, TY)  
	end, mcm:collection_tiles(MapID)).

new_collect(MapID, PointID, X, Y) ->
	case cfg_collect:point(PointID) of
		#p_collect_info{collect_skin = SkinID,
						collect_name = Name, collect_time = Times} ->
			put({collect, PointID}, #p_map_collect{
		  	    id     = PointID,
		  	    typeid = SkinID,
		  	    name   = Name,
		  	    times  = Times,
		  	    pos    = #p_pos{tx=X, ty=Y}
		   	}),
		    OffsetX = mcm:offset_x(MapID),
		    OffsetY = mcm:offset_y(MapID),
		    Slice   = mgeem_map:get_slice_by_txty(X, Y, OffsetX, OffsetY),
		    case get({collection,Slice}) of
		        undefined ->
		            put({collection,Slice}, [PointID]);
		        Others ->
		            put({collection,Slice}, [PointID|Others])
		    end;
		_ ->
			ignore
	end.
              
get_collect_by_slice_list(AllSlice) ->
    lists:foldl(fun(SliceName, Acc1) ->
        case get({collection,SliceName}) of 
            PointIDs when is_list(PointIDs) ->
				lists:foldl(fun(PointID, Acc2) ->
                    case get({collect, PointID}) of
                        CollMapInfo when is_record(CollMapInfo, p_map_collect) ->
                            [CollMapInfo|Acc2];
                        undefined ->
                            Acc2
                    end
                end, Acc1, PointIDs); 
            undefined ->
                Acc1
        end
    end, [], AllSlice).

set_collect_busy(RoleID, PointID, PID) ->
	#p_collect_info{
		refresh_time = RefreshTime
	} = cfg_collect:point(PointID),
	mod_role_busy:set(RoleID, PID),
	if
		RefreshTime =/= 0 ->
			put({collect_busy, PointID}, true);
		true ->
			ignore
	end.

unset_collect_busy(RoleID, PointID) ->
	mod_role_busy:unset(RoleID),
	erase({collect_busy, PointID}).

stop_collect(RoleID, PointID) ->
    unset_collect_busy(RoleID, PointID),
	common_misc:unicast({role, RoleID}, ?_collect_grafts{succ = false, reason = ?_LANG_COLLECT_BREAK}).

after_collect(RoleID, PointID) ->
	case creat_goods(RoleID, PointID) of
		{add_nuqi, AddNuqi} ->
			mgeem_map:send({apply, ?MODULE, refresh_collect, 
				[RoleID, PointID, [{add_nuqi, AddNuqi}, {cast_goods, []}]]});
		{ok, GoodsList} ->
			common_misc:update_goods_notify({role,RoleID}, GoodsList),
			
			mgeem_map:send({apply, ?MODULE, refresh_collect, 
				[RoleID, PointID, [{cast_goods, GoodsList}]]});
		{error, Reason} ->
			common_misc:unicast({role, RoleID}, ?_collect_grafts{succ=false, reason=Reason}),
			mgeem_map:send({apply, ?MODULE, unset_collect_busy, [RoleID, PointID]})
	end.

refresh_collect(RoleID, PointID, Funs) ->
	refresh_collect(RoleID, PointID),
	lists:foreach(fun
		({add_nuqi, AddNuqi}) ->
			mod_map_role:add_nuqi(RoleID, AddNuqi);
		({cast_goods, GoodsList}) ->
			hook_collect_succ(RoleID, PointID),
			common_misc:unicast({role, RoleID}, ?_collect_grafts{goods_list=GoodsList})
	end, Funs).
			
refresh_collect(RoleID, PointID) ->
	unset_collect_busy(RoleID, PointID),
	MapID = mgeem_map:get_mapid(),
	#p_collect_info{refresh_time = RefreshTime} = cfg_collect:point(PointID),
	if
		RefreshTime > 0 ->
			remove_grafts(MapID, PointID),
			erlang:send_after(RefreshTime*1000, self(), 
				{apply, ?MODULE, update_grafts, [MapID, PointID]});
		RefreshTime < 0 ->
			remove_grafts(MapID, PointID);
		RefreshTime == 0 ->
			ignore
	end.

update_grafts(MapID, PointID) when is_integer(PointID) ->
	{PointID, X, Y} = lists:keyfind(PointID, 1, mcm:collection_tiles(MapID)),
	#p_collect_info{
		collect_skin = SkinID,
		collect_name = Name, 
		collect_time = Times
	} = cfg_collect:point(PointID),
	Collect = #p_map_collect{
  	    id     = PointID,
  	    typeid = SkinID,
  	    name   = Name,
  	    times  = Times,
  	    pos    = #p_pos{tx=X, ty=Y}
	},
	update_grafts(MapID, PointID, X, Y, Collect);

update_grafts(MapID, Collect) when is_record(Collect, p_map_collect) ->
	#p_map_collect{
  	    id  = PointID,
  	    pos = #p_pos{tx=X, ty=Y}
	} = Collect,
	update_grafts(MapID, PointID, X, Y, Collect).

update_grafts(MapID, PointID, X, Y, Collect) ->
	OffsetX = mcm:offset_x(MapID),
	OffsetY = mcm:offset_y(MapID),
	put({collect, PointID}, Collect),
	SliceList = mgeem_map:get_9_slice_by_txty(X, Y, OffsetX, OffsetY),
	RoleList  = mgeem_map:get_all_in_sence_user_by_slice_list(SliceList),
	mgeem_map:broadcast(RoleList, ?_update_grafts{grafts=[Collect]}),
	Slice = mgeem_map:get_slice_by_txty(X, Y, OffsetX, OffsetY),
	case get({collection,Slice}) of
        undefined ->
            put({collection,Slice}, [PointID]);
        Others ->
            put({collection,Slice}, [PointID|Others])
    end.

remove_grafts(MapID, PointID) ->
	case erase({collect, PointID}) of
		Graft = #p_map_collect{pos=#p_pos{tx=X, ty=Y}} ->
			OffsetX   = mcm:offset_x(MapID),
			OffsetY   = mcm:offset_y(MapID),
			SliceList = mgeem_map:get_9_slice_by_txty(X, Y, OffsetX, OffsetY),
			RoleList  = mgeem_map:get_all_in_sence_user_by_slice_list(SliceList),
			mgeem_map:broadcast(RoleList, ?_remove_grafts{grafts=[Graft]}),
			Slice = mgeem_map:get_slice_by_txty(X, Y, OffsetX, OffsetY),
		    put({collection,Slice}, lists:delete(PointID, get({collection,Slice})));
		_ ->
			ignore
	end.

hook_collect_succ(RoleID, PointID) ->
	case mgeem_map:get_mapid() == mod_country_treasure:get_country_treasure_fb_map_id() of
		true ->
			#p_collect_info{collect_item = CollectItem} = cfg_collect:point(PointID),
			{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
			{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
			[ItemBaseInfo] = common_config_dyn:find(item, CollectItem),
			FactionId = RoleBase#p_role_base.faction_id,
			Msg = mod_country_treasure:get_collect_broadcast_msg(RoleAttr#p_role_attr.role_name, 
				FactionId, common_misc:get_faction_name(FactionId),
				<<"符文争夺战">>, ItemBaseInfo#p_item_base_info.itemname),
			common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CENTER], ?BC_MSG_TYPE_CHAT_WORLD, Msg);
		false -> ignore
	end.

%%
%% Local Functions
%%
creat_goods(RoleID, PointID) ->
	#p_collect_info{
		collect_type = Type,
		collect_item = CollectItem,
		collect_limi = CollectLimi,
		mission_hook = MissionHook
	} = cfg_collect:point(PointID),
    case common_transaction:t(fun
      () ->
      	case Type of
      		0 ->
		      	  check_collect_limit(RoleID, CollectItem, CollectLimi), 
		          mod_bag:create_goods(RoleID, #r_goods_create_info{
		              type    = ?TYPE_ITEM,
		              type_id = CollectItem,
		              num     = 1,
		              bind    = true
		          });
		    1 ->
				{_, AddNuqi} = common_tool:random_from_tuple_weights(CollectItem, 1),
		    	{add_nuqi, AddNuqi}
		end
    end) of 
        {aborted, Reason} when is_binary(Reason) ->
			{error, Reason};
        {aborted, {bag_error,{not_enough_pos,_BagID}}} ->
			{error, ?_LANG_COLLECT_BAG_NOT_ENOUGH};
        {aborted, Reason} ->
            ?ERROR_MSG("~ts:~w~n",["采集生成物品时错误",Reason]),
			{error, ?_LANG_SYSTEM_ERROR};
        {atomic, {ok, GoodsList}} ->
			if
				MissionHook ->
					hook_prop:hook(create, GoodsList);
				true ->
					ignore
			end,
			{ok, GoodsList};
		{atomic, {add_nuqi, AddNuqi}} ->
			{add_nuqi, AddNuqi}
    end.

check_collect_limit(RoleID, CollectItem, CollectLimit) when CollectLimit > 0 ->
	{ok, GoodsNums} = mod_bag:get_goods_num_by_typeid([1,2,3], RoleID, CollectItem),
	GoodsNums < CollectLimit orelse throw(<<"你不能再获得该类物品了">>);
check_collect_limit(_RoleID, _CollectItem, _CollectLimit) ->
	ok.

check_collect(RoleID, PointID, #map_state{mapid=MapID}) ->
	case cfg_collect:cant_collect(MapID) of
		false ->
			case get({collect, PointID}) of
				CollMapInfo when is_record(CollMapInfo, p_map_collect) ->
					check(RoleID, CollMapInfo, [
						fun check_collect_busy/2,
						fun check_role_state/2,
						fun check_horse_racing/2
					]);
				_ ->
					{error, ?_LANG_GOLLECT_HAS_COLLECT}
			end;
		_ ->
			{error, <<"不能进行该操作">>}
	end.

check(_RoleID, CollMapInfo, []) ->
	{ok, CollMapInfo};
check(RoleID, CollMapInfo, [Fun|T]) ->
	case Fun(RoleID, CollMapInfo) of
		{error, Reason} ->
			{error, Reason};
		_ ->
			check(RoleID, CollMapInfo, T)
	end.

check_collect_busy(RoleID, CollMapInfo) ->
	case mod_role_busy:check(RoleID) of
		{error, Reason} ->
			{error, Reason};
		_ ->
			case get({collect_busy, CollMapInfo#p_map_collect.id}) of
				true ->
					{error, <<"该物品正在被使用">>};
				_ ->
					{ok, CollMapInfo}
			end
	end.

check_role_state(RoleID, CollMapInfo) ->
	RoleMapInfo = mod_map_actor:get_actor_mapinfo(RoleID, role),
    case RoleMapInfo#p_map_role.state of
        ?ROLE_STATE_DEAD ->
            {error, ?_LANG_COLLECT_ROLE_STATE_DEAD};
        ?ROLE_STATE_FIGHT ->
            {error, ?_LANG_COLLECT_ROLE_STATE_FIGHT};
        ?ROLE_STATE_EXCHANGE ->
            {error, ?_LANG_COLLECT_ROLE_STATE_EXCHANGE};
        ?ROLE_STATE_ZAZEN ->
            {error, ?_LANG_COLLECT_ROLE_STATE_ZAZEN};
        ?ROLE_STATE_STALL ->
            {error, ?_LANG_COLLECT_ROLE_STATE_STALL};
        _ ->
			check_role_pos(RoleMapInfo, CollMapInfo)
    end.

check_role_pos(RoleMapInfo, CollMapInfo) ->
	#p_pos{tx=Tx1, ty=Ty1} = RoleMapInfo#p_map_role.pos,
	#p_pos{tx=Tx2, ty=Ty2} = CollMapInfo#p_map_collect.pos,
	if 
		abs(Tx1-Tx2) > 1 orelse abs(Ty1-Ty2) > 1 ->
            {error, ?_LANG_COLLECT_FAR_FROM};
        true ->
            {ok, CollMapInfo}
    end.

check_horse_racing(RoleID, CollMapInfo) ->
	case mod_horse_racing:is_role_in_horse_racing(RoleID) of
        true ->
            {error, ?_LANG_COLLECT_ROLE_STATE_HORSE_RACING};
        _ ->
            {ok, CollMapInfo}
    end.