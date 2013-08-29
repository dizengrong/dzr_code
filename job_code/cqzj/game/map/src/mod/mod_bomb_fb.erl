%%%-------------------------------------------------------------------
%%% @author  xierongfeng
%%% @doc
%%% 	炸宝
%%% @end
%%% Created : 2013-4-12
%%%-------------------------------------------------------------------
-module (mod_bomb_fb).

-include("mgeem.hrl").

-export([assert_valid_map_id/1, clear_map_enter_tag/1, get_map_name_to_enter/1]).
-export([handle/1, loop/2]).
-export([open_by_gm/0, close_by_gm/0, open/3, close/0]).
-export([new_stone/2, plant_bomb/2, bomb_explode/2]).

-define(_bomb_plant,    ?DEFAULT_UNIQUE, ?BOMB_FB, ?BOMB_FB_PLANT, 		   #m_bomb_fb_plant_toc).
-define(_update_grafts, ?DEFAULT_UNIQUE, ?COLLECT, ?COLLECT_UPDATA_GRAFTS, #m_collect_updata_grafts_toc).
-define(_remove_grafts, ?DEFAULT_UNIQUE, ?COLLECT, ?COLLECT_REMOVE_GRAFTS, #m_collect_remove_grafts_toc).
-define(_update_hp,     ?DEFAULT_UNIQUE, ?MAP,     ?MAP_UPDATE_HP,         #m_map_update_hp_toc).
-define(_attr_change,	?DEFAULT_UNIQUE, ?ROLE2,   ?ROLE2_ATTR_CHANGE,	   #m_role2_attr_change_toc).
-define(_common_error,  ?DEFAULT_UNIQUE, ?COMMON,  ?COMMON_ERROR, 		   #m_common_error_toc).
-define(_bomb_enter,    ?DEFAULT_UNIQUE, ?BOMB_FB, ?BOMB_FB_ENTER,         #m_bomb_fb_enter_toc).

-define(ACTIVITY_STATUS_OPEN,   1).
-define(ACTIVITY_STATUS_CLOSE,  0).

-define(ACTIVITY_ID, 10035).
-define(UNBEATABLE , 43).

assert_valid_map_id(_MapID)    -> ok.
clear_map_enter_tag(_RoleID)   -> ok.
get_map_name_to_enter(_RoleID) -> common_misc:get_map_name(cfg_bomb_fb:map_id()).

handle({init, MapID, MapName}) ->
	ets:new(?MODULE, [named_table]),
	lists:foreach(fun
		(_) -> new_stone(MapID, MapName)
	end, lists:seq(1, cfg_bomb_fb:max_stones()));

handle({role_enter, RoleID, MapID}) ->
    case MapID =:= cfg_bomb_fb:map_id() of
        false ->
            ignore;
        _ ->
            case is_open() of
                true ->
                    do_enter(RoleID);
                false ->
                    do_quit(RoleID)
            end
    end;

handle({before_role_quit, RoleID}) ->
    case is_in_bomb_fb_map() of
        true ->
        	mod_role_buff:del_buff(RoleID, cfg_bomb_fb:buffs(after_enter)),
        	summon_pet(RoleID);
        _ ->
            ignore
    end;

handle({role_offline, RoleID})->
    case is_in_bomb_fb_map() of
        false ->
            ignore;
        true ->
            mod_role_buff:del_buff(RoleID, cfg_bomb_fb:buffs(after_enter))
    end;

handle({_Unique, ?BOMB_FB, ?BOMB_FB_ENTER, _DataIn, RoleID, PID, _Line}) ->
	case is_open() of
		true ->
			{ok, #p_role_attr{level = Level}} = mod_map_role:get_role_attr(RoleID),
			case Level >= cfg_bomb_fb:enter_level() of
				true ->
	   				case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
	   					true -> common_misc:unicast2(PID, ?_common_error{error_str = ?_LANG_XIANNVSONGTAO_MSG});
	   					false -> 
							MapID = cfg_bomb_fb:map_id(),
							{Tx, Ty} = cfg_bomb_fb:born_tiles(),
							mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, MapID, Tx, Ty)
					end;
				_ ->
					common_misc:unicast2(PID, ?_common_error{error_str = <<"你的等级不足以进入该地图">>})
			end;
		_ ->
			common_misc:unicast2(PID, ?_common_error{error_str = <<"该活动暂未开启">>})
	end;

handle({_Unique, ?BOMB_FB, ?BOMB_FB_QUIT, _DataIn, RoleID, _PID, _Line}) ->
	do_quit(RoleID);

handle({_Unique, ?BOMB_FB, ?BOMB_FB_PLANT, DataIn, RoleID, PID, _Line}) ->
	#m_bomb_fb_plant_tos{bomb_type = BombType, tx = Tx, ty = Ty } = DataIn,
	Now = common_tool:now(),
	case is_open() andalso is_in_bomb_fb_map() andalso check_plant_bomb_cd(Now, BombType)
                andalso check_plant_place(RoleID, Tx, Ty) of 
        true ->
            case pay_bomb(RoleID, BombType) of
        		{ok, _} ->
                    set_plant_bomb_cd(common_tool:now(), BombType),
        			BombCD = cfg_bomb_fb:bomb_cd(BombType),
        			common_misc:unicast2(PID, ?_bomb_plant{bomb_type = BombType, bomb_cd = BombCD}),
        			mgeem_map:absend({apply, ?MODULE, plant_bomb, [RoleID, BombType]});
        		{error, Msg} ->
        			common_misc:unicast2(PID, ?_common_error{error_str = Msg})
            end;
        {error, Msg} ->
            common_misc:unicast2(PID, ?_common_error{error_str = Msg});
		false ->
			common_misc:unicast2(PID, ?_common_error{error_str = <<"你还不能放置炸弹">>})
	end;

handle({recover_role_pet, {RoleID, Msg}}) ->
    common_misc:send_to_rolemap(RoleID, {mod, mod_map_pet, Msg});

handle(_Msg) ->
	ignore.

loop(_MapID, Now) ->
	cfg_bomb_fb:is_off() orelse is_open() orelse 
	case is_time_to_open(time()) of
		{true, StartTime, EndTime} ->
            ets:insert(?MODULE, {status, ?ACTIVITY_STATUS_OPEN, EndTime}),
			open(Now, StartTime, EndTime);
		_ ->
			ignore
	end.

open_by_gm() ->
    Date = date(),
    NowTime = common_tool:now(),
    Time = lists:foldl(fun
        ({OpenTime, CloseTime}, _) ->
                OpenSecs  = common_tool:datetime_to_seconds({Date, OpenTime}),
                CloseSecs = common_tool:datetime_to_seconds({Date, CloseTime}),
                CloseSecs - OpenSecs
	   end, 0, cfg_bomb_fb:open_time()),
    EndTime = NowTime + Time,
    ets:insert(?MODULE, {status, ?ACTIVITY_STATUS_OPEN, EndTime}),
	open(NowTime, NowTime, EndTime).

close_by_gm() ->
	case erase(close_timer) of
		Timer when is_reference(Timer) ->
			erlang:cancel_timer(Timer);
		_ ->
			ignore
	end,
	close().

open(NowTime, StartTime, EndTime) ->
	common_activity:notfiy_activity_start({?ACTIVITY_ID, NowTime, StartTime, EndTime}),
	Timer = erlang:send_after((EndTime - NowTime)*1000, self(), {apply, ?MODULE, close, []}),
	put(close_timer, Timer).

close() ->
	erase(close_timer),
	ets:insert(?MODULE, {status, ?ACTIVITY_STATUS_CLOSE}),
	common_activity:notfiy_activity_end(?ACTIVITY_ID),
    Msg = cfg_bomb_fb:bc_lang_closed(),
    ?WORLD_CHAT_BROADCAST(Msg),
    ?WORLD_CENTER_BROADCAST(Msg),
	lists:foreach(fun(RoleID) -> do_quit(RoleID) end, mgeem_map:get_all_roleid()).

%%%========================================================================
%%% Internal functions
%%%========================================================================

is_in_bomb_fb_map() ->
    mgeem_map:get_mapid() =:= cfg_bomb_fb:map_id().

do_enter(RoleID) -> 
    mod_role_mount:do_mount_down(RoleID),
    Buffs = [begin 
        {ok, Buff} = mod_skill_manager:get_buf_detail(BuffID),
        case common_config_dyn:find(buff_type, Buff#p_buf.buff_type) of
            [change_skin] ->
                Skins = cfg_bomb_fb:skins(after_enter),
                Buff#p_buf{value = lists:nth(random:uniform(length(Skins)), Skins)};
            _ ->
                Buff
        end
    end||BuffID <- cfg_bomb_fb:buffs(after_enter)],
    mod_role_buff:add_buff(RoleID, Buffs),
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{max_hp=MaxHp}->
            mod_map_role:do_role_add_hp(RoleID, MaxHp, RoleID);
        _ ->
            ignore
    end,
    callback_pet(RoleID),
    PID    = get({roleid_to_pid, RoleID}),
    EndTime = get_endtime(),
    common_misc:unicast2(PID, ?_bomb_enter{end_time = EndTime}).

do_quit(RoleID) ->
    case mod_map_actor:get_actor_mapinfo(RoleID,role) of
        #p_map_role{state=?ROLE_STATE_DEAD}->
            mod_role2:do_relive(?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_RELIVE, 
                RoleID, ?RELIVE_TYPE_ORIGINAL_FREE, mgeem_map:get_state());
        _ ->
            ignore
    end,
	{ok, #p_role_base{faction_id=FactionID}} = mod_map_role:get_role_base(RoleID),
	HomeMapID   = common_misc:get_home_mapid(FactionID, mgeem_map:get_mapid()),
	{_, TX, TY} = common_misc:get_born_info_by_map(HomeMapID),
	mod_map_role:diff_map_change_pos(?CHANGE_MAP_TYPE_NORMAL, RoleID, HomeMapID, TX, TY).

plant_bomb(RoleID, BombType) ->
    case mod_map_actor:get_actor_pos(RoleID, role) of
        undefined ->
            ignore;
        RolePos ->
        	BombID  = new_bomb_id(),
        	Bomb    = get_bomb_info(BombID, BombType, RolePos),
            broadcast_plant_bomb(RoleID, BombType, Bomb),
        	mod_map_collect:update_grafts(mgeem_map:get_mapid(), Bomb),
        	ExplodeTime = Bomb#p_map_collect.times*1000,
        	erlang:send_after(ExplodeTime, self(), {apply, ?MODULE, bomb_explode, [RoleID, BombID]})
    end.

bomb_explode(RoleID, BombID) ->
	MapID = mgeem_map:get_mapid(),
	#p_map_collect{typeid=TypeID, pos=#p_pos{tx=TX, ty=TY}} = get({collect, BombID}),
	BombType = get_bomb_type(TypeID),
	bomb_explode(RoleID, BombType, MapID, TX, TY),
	mod_map_collect:remove_grafts(MapID, BombID).

new_stone(MapID, MapName) ->
	{StoneID, {StoneType, TX, TY}} = random(mcm:monster_tiles(MapID)),
	StoneInfo = #p_monster{
		reborn_pos = #p_pos{tx=TX, ty=TY, dir=1},
		monsterid  = StoneID,
		typeid     = StoneType,
		mapid      = MapID
	},
	mod_map_monster:init([StoneInfo, ?MONSTER_CREATE_TYPE_MANUAL_CALL, 
						  MapID, MapName, undefined, ?FIRST_BORN_STATE, null]).

random(StoneTiles) ->
	StoneTiles2 = lists:foldl(fun
		(Tile, []) ->
			 [{1, Tile}];
		(Tile1, [{StoneID, Tile2}|Acc]) ->
			 [{StoneID + 1, Tile1}, {StoneID, Tile2}|Acc]
	end, [], StoneTiles),
	{T1, T2} = lists:split(random:uniform(length(StoneTiles)), StoneTiles2),
	filter(T2 ++ T1).
	
filter([Stone|T]) ->
	{StoneID, _StoneTile} = Stone,
	case mod_map_monster:get_monster_state(StoneID) of
		undefined ->
			Stone;
		_ ->
			filter(T)
	end.

new_bomb_id() ->
	NewBombID = case get(bomb_id) of
		OldBombID when OldBombID >= 10000 ->
			1;
		OldBombID ->
			OldBombID + 1
	end,
	put(bomb_id, NewBombID),
	NewBombID.

get_bomb_info(BombID, BombType, Pos) ->
	Bomb = cfg_bomb_fb:bomb_info(BombType),
	Bomb#p_map_collect{id=BombID, pos=Pos}.

bomb_explode(RoleID, BombType, MapID, TX, TY) ->
	MapState   = mgeem_map:get_state(),
	BombPos    = #p_pos{tx=TX, ty=TY},
	BombArea   = cfg_bomb_fb:bomb_area(BombType),
	DamagePerc = cfg_bomb_fb:bomb_damage(BombType),
	CheckActor = check_actor_fun(RoleID),
	AllTargets = mof_common:get_around_targets(BombPos, BombArea, CheckActor),
	UpdateList = lists:foldl(fun
   		(#p_map_role{role_id=TargetID, hp=HP, max_hp=MaxHP,pos = Pos}, Acc) when HP > 0 ->
            case mod_map_actor:get_actor_mapinfo(RoleID, role) of
                #p_map_role{role_name = RoleName} ->
                    case mof_common:is_pos_safe(cfg_bomb_fb:map_id(), Pos) of
                        true ->
                            Acc;
                        _ ->
                   			Damage = common_tool:ceil(MaxHP*DamagePerc/100),
                			mod_map_role:do_role_reduce_hp(TargetID, Damage, RoleName, RoleID, role, MapState),
                			[#p_actor_hp{actor_type=?TYPE_ROLE, actor_id=TargetID, actor_hp=max(0, HP - Damage)}|Acc]
                    end;
                _ ->
                    Acc
            end;
		(#p_map_monster{monsterid=StoneID, hp=HP, typeid = TypeID}, Acc) when HP > 0->
			Damage = DamagePerc,
			mod_map_monster:reduce_hp(StoneID, Damage, RoleID, role, true, 0),
            case HP =< Damage of
                true ->
                    stone_dead(RoleID, TypeID),
                    erlang:send_after(10000, self(), 
				        {apply, ?MODULE, new_stone, [MapID, MapState#map_state.map_name]});
                _ ->
                    ignore
            end,
			[#p_actor_hp{actor_type=?TYPE_MONSTER, actor_id=StoneID, actor_hp=max(0, HP - Damage)}|Acc];
		(_, Acc) ->
			Acc
	end, [], AllTargets),
	SliceList = mgeem_map:get_9_slice_by_txty(TX, TY, mcm:offset_x(MapID), mcm:offset_y(MapID)),
	RoleList  = mgeem_map:get_all_in_sence_user_by_slice_list(SliceList),
	mgeem_map:broadcast(RoleList, ?_update_hp{list = UpdateList}),
	mof_fight_handler:handle_already_dead(erase(already_dead), MapState).
	
check_actor_fun(BomberID) ->
	fun({role, ActorID}) ->
			ActorID =/= BomberID andalso begin
				RoleMapInfo = mod_map_actor:get_actor_mapinfo(ActorID, role),
				RoleBuffs   = RoleMapInfo#p_map_role.state_buffs,
				mof_common:is_alive(RoleMapInfo) andalso not lists:any(fun
					(#p_actor_buf{buff_type = ?UNBEATABLE}) -> 
						true;
					(_) ->
						false
				end, RoleBuffs) andalso {continue, RoleMapInfo}
			end;
		({ActorType, ActorID}) ->
			ActorMapInfo = mod_map_actor:get_actor_mapinfo(ActorID, ActorType),
			mof_common:is_alive(ActorMapInfo) andalso {continue, ActorMapInfo}
 	end.

is_time_to_open(Time) ->
	lists:foldl(fun
		({OpenTime, CloseTime}, false) ->
			Time == OpenTime andalso begin
				Date = date(), 
				OpenSecs  = common_tool:datetime_to_seconds({Date, OpenTime}),
				CloseSecs = common_tool:datetime_to_seconds({Date, CloseTime}),
				{true, OpenSecs, CloseSecs}
			end;
		(_, Result) ->
			Result
	end, false, cfg_bomb_fb:open_time()).

is_open() ->
	case ets:lookup(?MODULE, status) of
		[{_, ?ACTIVITY_STATUS_OPEN, _}] ->
			true;
		_ ->
			false
	end.

get_endtime() ->
    case ets:lookup(?MODULE, status) of
        [{_, ?ACTIVITY_STATUS_OPEN, EndTime}] ->
            EndTime;
        _ ->
            0
    end.
pay_bomb(RoleID, BombType) ->
	pay_cost(RoleID, BombType).


pay_cost(RoleID,BombType) ->
	case cfg_bomb_fb:bomb_cost(BombType) of
		{_,0} ->
			{ok,undefined};
		{CostType, Money}  ->
			Log = case CostType of
					  T when T == gold_unbind orelse T == gold_any -> 
						  if
							  BombType =:= 3 ->
								  ?CONSUME_TYPE_GOLD_BOMB_FB_REDUCE_COST_3;
							  BombType =:= 4 ->
								  ?CONSUME_TYPE_GOLD_BOMB_FB_REDUCE_COST_4;
							  BombType =:= 5 ->
								  ?CONSUME_TYPE_GOLD_BOMB_FB_REDUCE_COST_5;
							  true ->
								  ?CONSUME_TYPE_GOLD_BOMB_FB_REDUCE_COST
						  end;
					  
					  silver_any -> ?CONSUME_TYPE_SILVER_BOMB_FB
				  end,
			{_, Result} = common_transaction:transaction(fun
															() -> 
																 common_bag2:t_deduct_money(CostType, Money, RoleID, Log)
														 end),
			case Result of
				{ok, RoleAttr} ->
					case CostType of
						silver_any  -> common_misc:send_role_silver_change(RoleID, RoleAttr);
						_ -> common_misc:send_role_gold_change(RoleID, RoleAttr)
					end;
				_ ->
					ignore
			end,
			Result
	end.

get_bomb_type(TypeID) ->
	lists:foldl(fun
		(Index, false) ->
			get_bomb_type(Index, TypeID);
		(_Index, R) ->
			R 
	end, false, lists:seq(1, 5)).

get_bomb_type(Index, TypeID) ->
	case cfg_bomb_fb:bomb_info(Index) of
		#p_map_collect{typeid=TypeID} ->
			Index;
		_ ->
			false
	end.

check_plant_bomb_cd(NowTime, BombType) ->
	case get({last_plant_bomb_time, BombType}) of
		LastTime when is_integer(LastTime) ->
			NowTime - LastTime >= cfg_bomb_fb:bomb_cd(BombType);
		_ ->
			true
	end.

check_plant_place(RoleID, Tx, Ty) ->
    case mod_map_role:get_role_base(RoleID) of
        {ok, #p_role_base{status=?ROLE_STATE_DEAD}} ->
            {error, <<"死亡状态，不能放置炸弹">> };
        _ ->
            case mof_common:is_pos_safe(cfg_bomb_fb:map_id(), #p_pos{tx=Tx,ty=Ty}) of
                true ->
                    {error, <<"在安全区，不能放置炸弹">> };
                _ ->
                    true
            end
    end.
    
set_plant_bomb_cd(NowTime, BombType) ->
	put({last_plant_bomb_time, BombType}, NowTime).

callback_pet(RoleID) ->
	#p_map_role{summoned_pet_id = PetID} = mod_map_actor:get_actor_mapinfo(RoleID, role),
	is_integer(PetID) andalso PetID > 0 andalso begin
		put({callback_pet_id, RoleID}, PetID),
		DataIn = #m_pet_call_back_tos{pet_id = PetID, is_hidden = false},
		Line   = common_misc:get_role_line_by_id(RoleID),
		mod_map_pet:do_call_back(undefined, DataIn, RoleID, Line, mgeem_map:get_state())
	end.

summon_pet(RoleID) ->
	case erase({callback_pet_id, RoleID}) of
		PetID when is_integer(PetID) andalso PetID > 0 ->
			Line   = common_misc:get_role_line_by_id(RoleID),
			PID    = get({roleid_to_pid, RoleID}),
			DataIn = #m_pet_summon_tos{pet_id = PetID},
			Msg    = {?DEFAULT_UNIQUE, ?PET, ?PET_SUMMON, DataIn, RoleID, PID, Line},
            erlang:send_after(100, self(), {?MODULE, {recover_role_pet, {RoleID, Msg}}});
		_ ->
			ignore
	end.

stone_dead(RoleID, TypeID) ->
    case is_open() andalso lists:member(TypeID, cfg_bomb_fb:monster_stone()) of
        true ->
            {ok,#p_role_base{role_name=RoleName}} = mod_map_role:get_role_base(RoleID),
            [#p_monster_base_info{monstername = MonsterName}] =  cfg_monster:find(TypeID),
            %% 炸宝副本里场景广播矿物被炸的配置广播消息
            broadcast_monster_dead(RoleName, MonsterName),
            %% 广播紫晶矿被炸
            case lists:member(TypeID, cfg_bomb_fb:broadcast_stones()) of
                true ->
                    BroadcastMsg = cfg_bomb_fb:bc_lang_bomb_stone(erlang:binary_to_list(RoleName)),
                    ?WORLD_CHAT_BROADCAST(BroadcastMsg),
                    ?WORLD_CENTER_BROADCAST(BroadcastMsg);
                _ -> 
                    ignore
            end;
        _ ->
            ignore
    end.

broadcast_monster_dead(RoleName, MonsterName) ->
	[MapName]    = common_config_dyn:find(map_info, mgeem_map:get_mapid()),
	BroadcastMsg = cfg_bomb_fb:bc_lang_monster_dead_in_scene(erlang:binary_to_list(RoleName), MapName, MonsterName),
    broadcast_in_scene(BroadcastMsg).

broadcast_plant_bomb(RoleID, BombType, Bomb) ->
    case lists:member(BombType, cfg_bomb_fb:broadcast_bombs()) of
        true ->
            {ok,#p_role_base{role_name=RoleName}} = mod_map_role:get_role_base(RoleID),
            BroadcastMsg = cfg_bomb_fb:bc_lang_plant_bomb(erlang:binary_to_list(RoleName), Bomb#p_map_collect.name),
            broadcast_in_scene(BroadcastMsg);
        _ ->
            ignore
    end.

broadcast_in_scene(BroadcastMsg)->
    Msg = #m_broadcast_general_toc{type=[?BC_MSG_TYPE_CHAT], sub_type=?BC_MSG_TYPE_CHAT_WORLD, content=BroadcastMsg },
    lists:foreach(fun(MapRoleID) -> 
            common_misc:chat_broadcast_to_role(MapRoleID, ?BROADCAST, ?BROADCAST_GENERAL, Msg),
            ?ROLE_CENTER_BROADCAST(MapRoleID, BroadcastMsg)
        end, mgeem_map:get_all_roleid()).
