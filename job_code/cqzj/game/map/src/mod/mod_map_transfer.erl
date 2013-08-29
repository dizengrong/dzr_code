%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     传送卷模块
%%% @end
%%% Created : 2011-01-10
%%%-------------------------------------------------------------------
-module(mod_map_transfer).
-include("mgeem.hrl").

%% API
-export([handle/2]).

-define(TRANSFER_SCROLL_TYPEID, 10100001).

%% 跳转类型：0普通、1快速任务、2返回门派(扣钱币) 3新手任务无障碍传送
-define(map_transfer_type_normal, 0).
-define(map_transfer_type_fast_mission, 1).
-define(map_transfer_type_return_family, 2).
-define(map_transfer_type_guide_free, 3).

%% ====================================================================
%% API functions
%% ====================================================================

handle({map_transfer, RoleID, DestMapID, TX, TY}, State) ->
	case DestMapID =:= State#map_state.mapid of
        true ->
            mod_map_actor:same_map_change_pos(RoleID, role, TX, TY, ?CHANGE_POS_TYPE_NORMAL, State);
        _ ->
            mod_map_role:diff_map_change_pos(RoleID, DestMapID, TX, TY)
    end;
handle({Unique, ?MAP, ?MAP_TRANSFER, DataIn, RoleID, _PID, Line}, State)->
    do_map_transfer(Unique, ?MAP, ?MAP_TRANSFER, DataIn, RoleID, Line, State).


do_map_transfer(Unique, Module, Method, DataIn, RoleID, Line, MapState) ->
    try
        %% 监狱不能使用传送卷
        #map_state{mapid=MapID} = MapState,
        case mod_jail:check_in_jail(MapID) of
            true ->
                throw(?_LANG_MAP_TRANSFER_IN_JAIL);
            _ ->
                ok
        end,
        {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
        {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
        %% 战斗状态不能传送
        case mod_map_role:is_role_fighting(RoleID) andalso RoleAttr#p_role_attr.level >= 40 of
            true ->
                throw(?_LANG_MAP_TRANSFER_ROLE_FIGHTING);
            _ ->
                ignore
        end,
        %% 死亡等一些特殊状态不能使用传送
        case RoleBase#p_role_base.status of
            ?ROLE_STATE_DEAD ->
                throw(?_LANG_MAP_TRANSFER_DEAD_STATE);
            _ ->
                ok
        end,
        case mod_horse_racing:is_role_in_horse_racing(RoleID) of
            true ->
                throw(?_LANG_MAP_TRANSFER_HORSE_RACING_STATE);
            _ ->
                ignore
        end,
        [RoleState2] = db:dirty_read(?DB_ROLE_STATE, RoleID),
        #r_role_state{exchange=Exchange, stall_self=StallSelf} = RoleState2,
        case Exchange of
            true ->
                throw(?_LANG_MAP_TRANSFER_EXCHANGE_STATE);
            _ ->
                ok
        end,
        case mod_mission_change_skin:is_doing_change_skin_mission(RoleID) of
            true -> 
                throw(?_LANG_XIANNVSONGTAO_MSG);
            false -> ignore
        end,
        case StallSelf of
            true ->
                throw(?_LANG_MAP_TRANSFER_STALL_STATE);
            _ ->
                ok
        end,
		
		case mod_trading:get_role_trading_state(RoleID) of
			{ok,1} ->
				throw(?_LANG_MAP_TRANSFER_TRADING_STATE);
			 _ ->
				 ignore
		end,
				
        #m_map_transfer_tos{mapid=DestMapID, tx=TX, ty=TY, change_type=ChangeType} = DataIn,
        case ChangeType =:= ?map_transfer_type_return_family of
            true ->
                case MapID =:= 10300 of
                    true ->
                        erlang:throw(?_LANG_MAP_TRANSFER_RETURN_FAMILY_IN_FAMILY_MAP);
                    _ ->
                        next
                end,
                case RoleBase#p_role_base.family_id =/= 0 of
                    true ->
                        next;
                    _ ->
                        erlang:throw(?_LANG_MAP_TRANSFER_NOT_FAMILY)
                end;
            _ ->
                next
        end, 
        MapID = MapState#map_state.mapid,
        if DestMapID =/= MapID ->
                %% 检查等级限制
                case common_config_dyn:find(map_level_limit, DestMapID) of
                    [Level]->
                        case RoleAttr#p_role_attr.level >= Level of
                            true ->
                                ok;
                            _ ->
                                throw(list_to_binary(io_lib:format(?_LANG_MAP_TRANSFER_LEVEL_LIMIT, [Level])))
                        end;
                    _ ->
                        throw(?_LANG_SYSTEM_ERROR)
                end;
           true ->
                ok
        end,
        %% 国外不能使用传送功能
        if MapID =:= ?COUNTRY_TREASURE_MAP_ID ->
                erlang:throw(?_LANG_MAP_TRANSFER_IN_10500_MAP);
           true ->
                ok
        end,
		case common_config_dyn:find(fb_map,MapID) of
			[]->
				IsFbMap = false;
			[#r_fb_map{can_use_item_transfer=CanTransfer}] ->
				IsFbMap = true,
				case CanTransfer of
					false ->
						throw(?_LANG_MAP_TRANSFER_OTHER_COUNTRY);
					true ->
						ok
				end
		end,
		%% 在敌国不能使用传送卷
		case common_misc:if_in_self_country(RoleBase#p_role_base.faction_id, MapID) orelse common_misc:if_in_neutral_area(MapID) of
			false ->
				%% 副本上面已经判断
				case IsFbMap of
					false ->
						throw(?_LANG_MAP_TRANSFER_OTHER_COUNTRY);
					true ->
						ok
				end;
			_ ->
				ok
		end,
		%%安全挂机地图10201不能使用该传送方法
		case MapID =/= DestMapID andalso DestMapID =:= 10201 of
			true ->
				throw(<<"非法操作">>);
			false ->
				ok
		end,
        %% 寻找最近的一个可走点
        case MapID =:= DestMapID of
            true ->
                case mod_spiral_search:get_walkable_pos(MapID, TX, TY, 10) of
                    {error, _} ->
                        throw(?_LANG_MAP_TRANSFER_ILLEGAL_POS);
                    {TX2, TY2} ->
                        do_map_transfer2(Unique, Module, Method, RoleID, Line, MapID, DestMapID, TX2, TY2, TX, TY, MapState, ChangeType)
                end;
            _ ->
                do_map_transfer2(Unique, Module, Method, RoleID, Line, MapID, DestMapID, TX, TY, TX, TY, MapState, ChangeType)
        end
    catch
        _:R when is_binary(R) ->
            do_map_transfer_error(Unique, Module, Method, RoleID, R, Line);
        _:R ->
            ?ERROR_MSG("do_map_transfer, error: ~w, trace: ~w", [R, erlang:get_stacktrace()]),
            do_map_transfer_error(Unique, Module, Method, RoleID, ?_LANG_SYSTEM_ERROR, Line)
    end.
do_map_transfer2(Unique, Module, Method, RoleID, Line, MapID, DestMapID, DTX, DTY, _TX, _TY, State, ?map_transfer_type_guide_free) ->
    %% 新手村无障碍传送
    #p_map_role{level = RoleLevel} = mod_map_actor:get_actor_mapinfo(RoleID, role),
    CanTransferList = [11000,12000,13000,11001,12001,13001],
    case lists:member(MapID,CanTransferList) =:= true
        andalso lists:member(DestMapID,CanTransferList) =:= true
        andalso RoleLevel < 35 of
        true ->
            Record = #m_map_transfer_toc{succ = true},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, Record),
            do_map_transfer4(RoleID, MapID, DestMapID, DTX, DTY, State);
        _ ->
            throw(?_LANG_MAP_TRANSFER_GUIDE_FREE_ERROR)
    end;

do_map_transfer2(Unique, Module, Method, RoleID, Line, MapID, _DestMapID, _DTX, _DTY, _TX, _TY, State, ?map_transfer_type_return_family) ->
    %% 返回门派地图处理
    [ReturnFamilyFee] = common_config_dyn:find(etc,return_family_silver_fee),
	[{RFTX, RFTY}|_]  = mcm:born_tiles(10300),
    case common_transaction:transaction(
           fun() ->
                   {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
                   case (RoleAttr#p_role_attr.silver_bind + RoleAttr#p_role_attr.silver) >= ReturnFamilyFee of
                       true ->
                           case RoleAttr#p_role_attr.silver_bind < ReturnFamilyFee of
                               true ->
                                   NewSilver = RoleAttr#p_role_attr.silver - (ReturnFamilyFee - RoleAttr#p_role_attr.silver_bind),
                                   NewRoleAttr = RoleAttr#p_role_attr{silver_bind=0,silver=NewSilver },
                                   mod_map_role:set_role_attr(RoleID,NewRoleAttr),
                                   common_consume_logger:use_silver({RoleID, RoleAttr#p_role_attr.silver_bind, 
                                                                     (ReturnFamilyFee - RoleAttr#p_role_attr.silver_bind),
                                                                     ?CONSUME_TYPE_SILVER_RETURN_FAMILY,""});
                               _ ->
                                   NewSilver = RoleAttr#p_role_attr.silver_bind - ReturnFamilyFee,
                                   NewRoleAttr = RoleAttr#p_role_attr{silver_bind= NewSilver},
                                   mod_map_role:set_role_attr(RoleID,NewRoleAttr),
                                   common_consume_logger:use_silver({RoleID, ReturnFamilyFee, 0,?CONSUME_TYPE_SILVER_RETURN_FAMILY,""})
                           end;
                       _ ->
                           NewRoleAttr = RoleAttr,
                           common_transaction:abort(?_LANG_MAP_TRANSFER_ENOUGH_MONEY)
                   end,
                   {ok,NewRoleAttr}
           end)
    of
        {atomic, {ok,RoleAttr2}} ->
            %% 通知钱币变化
            AttrChangeList = [#p_role_attr_change{change_type=?ROLE_SILVER_CHANGE, new_value = RoleAttr2#p_role_attr.silver},
                              #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE, new_value = RoleAttr2#p_role_attr.silver_bind}],
            common_misc:role_attr_change_notify({line,Line,RoleID},RoleID,AttrChangeList),
            Record = #m_map_transfer_toc{succ = true},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, Record),
            do_map_transfer4(RoleID, MapID, 10300, RFTX, RFTY, State);
        {aborted, Reason} when is_binary(Reason) ->
            throw(Reason);
        {aborted, Reason} ->
            ?ERROR_MSG("do_map_transfer, reason: ~w", [Reason]),
            throw(?_LANG_SYSTEM_ERROR)
    end;
do_map_transfer2(Unique, Module, Method, RoleID, Line, MapID, DestMapID, DTX, DTY, TX, TY, State, ?map_transfer_type_normal) ->
    %% 判断是否是救援传送，暂时这样处理。官员救援不扣传送卷
    case get({killed_by_foreigner, DestMapID, TX, TY}) of
        undefined ->
            do_map_transfer3(Unique, Module, Method, RoleID, Line, MapID, DestMapID, DTX, DTY, State);

        {_, KilledFID} ->
            {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
            #p_role_base{faction_id=FactionID} = RoleBase,
            
            case KilledFID =:= FactionID of
                true ->
                    {ok, RoleAttr} = common_misc:get_dirty_role_attr(RoleID),
                    #p_role_attr{office_id=OfficeID} = RoleAttr,
                    case OfficeID > 0 of
                        true ->
                            Record = #m_map_transfer_toc{succ = true},
                            common_misc:unicast(Line, RoleID, Unique, Module, Method, Record),
                            do_map_transfer4(RoleID, MapID, DestMapID, DTX, DTY, State);
                        _ ->
                            do_map_transfer3(Unique, Module, Method, RoleID, Line, MapID, DestMapID, DTX, DTY, State)
                    end;
                _ ->
                    do_map_transfer3(Unique, Module, Method, RoleID, Line, MapID, DestMapID, DTX, DTY, State)
            end
    end;
do_map_transfer2(Unique, Module, Method, RoleID, Line, MapID, DestMapID, DTX, DTY, _TX, _TY, State, _MapTransferType) ->
    case mod_vip:is_map_transfer_free(RoleID) of
        true ->
            Record = #m_map_transfer_toc{succ = true},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, Record),
            do_map_transfer4(RoleID, MapID, DestMapID, DTX, DTY, State);
        false ->
            do_map_transfer3(Unique, Module, Method, RoleID, Line, MapID, DestMapID, DTX, DTY, State)
    end.
            
do_map_transfer3(Unique, Module, Method, RoleID, Line, MapID, DestMapID, TX, TY, State) ->
    case common_transaction:transaction(
           fun() ->
                   t_do_map_transfer(RoleID)
           end)
    of
        {atomic, {ok,ChangeList,DeleteList}} ->
            %%传送卷使用个数为一个,当传送卷个数为1时成功使用后就是删除，当是多个时成功使用后就是改变数量
            case ChangeList of
                []->
                    [#p_goods{id=ScrollID}=Goods|_] = DeleteList,
                    used_transfer_log([Goods#p_goods{current_num=1}]),
                    common_misc:del_goods_notify({role, RoleID}, DeleteList);
                _->
                    [#p_goods{id=ScrollID}=Goods] = ChangeList,
                    used_transfer_log([Goods#p_goods{current_num=1}]),
                    common_misc:update_goods_notify({role, RoleID}, Goods)
            end,
            Record = #m_map_transfer_toc{scroll_id=ScrollID},
            common_misc:unicast(Line, RoleID, Unique, Module, Method, Record),
            do_map_transfer4(RoleID, MapID, DestMapID, TX, TY, State);
        {aborted, Reason} when is_binary(Reason) ->
            throw(Reason);
        {aborted, Reason} ->
            ?ERROR_MSG("do_map_transfer, reason: ~w", [Reason]),
            throw(?_LANG_SYSTEM_ERROR)
    end.

do_map_transfer4(RoleID, _MapID, DestMapID, TX, TY, _State) ->
	mgeem_map:send({mod, ?MODULE, {map_transfer, RoleID, DestMapID, TX, TY}}).

do_map_transfer_error(Unique, Module, Method, RoleID,  Reason, Line) ->
    Record = #m_map_transfer_toc{succ=false, scroll_id=0, reason=Reason},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, Record).

used_transfer_log(GoodsList) ->
    lists:foreach(
      fun(Goods) ->
          #p_goods{roleid=RoleID}=Goods,
          common_item_logger:log(RoleID,Goods,?LOG_ITEM_TYPE_SHI_YONG_SHI_QU)
      end,GoodsList).

t_do_map_transfer(RoleID) ->
    BagIDs = [1,2,3],   %%默认的背包ID
    case catch mod_bag:decrease_goods_by_typeid(RoleID,BagIDs,?TRANSFER_SCROLL_TYPEID,1) of
        {bag_error,num_not_enough} ->
            common_transaction:abort(?_LANG_MAP_TRANSFER_NO_SCROLL);
        Other ->
            Other
    end.
