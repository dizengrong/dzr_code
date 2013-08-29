%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created :  3 Nov 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_office).

-include("common.hrl").

-include("office.hrl").
-include("common_server.hrl").

%% API
-export([
         get_king_roleid/1,
         get_king_name/1,
         set_king/3,
         get_general_roleid/1,
         role_online/1,
         retrieve_all_office_equip/0,
         retrieve_office_equip/3,
		 delete_illegal_office_item/0
        ]).

get_king_roleid(FactionID) ->
    [#p_faction{office_info=OfficeInfo}] = db:dirty_read(?DB_FACTION, FactionID),
    OfficeInfo#p_office.king_role_id.

get_king_name(FactionID) ->
    proplists:get_value(FactionID, ?FACTION_KING_NAME).

set_king(KingRoleID, _KingRoleName, _FactionID) ->
    global:send(mgeew_office, {set_king, KingRoleID}).

get_general_roleid([]) -> 
    undefined;
get_general_roleid(undefined) -> 
    undefined;
get_general_roleid([Office|OfficeList]) ->
    case Office#p_office_position.office_id =:= ?OFFICE_ID_GENERAL of
        true ->
            Office#p_office_position.role_id;
        false ->
            get_general_roleid(OfficeList)
    end.

role_online(RoleID) ->
    global:send(mgeew_office, {send_appoint_offline_msg, RoleID}).

retrieve_office_equip(RoleID,OfficeID,BroadcastMsg) ->
    if
        RoleID > 0 ->
            case common_misc:is_role_online(RoleID) of
                true ->
                    mgeer_role:send(RoleID, {mod_map_office,{retrieve_office_equip, RoleID, OfficeID}}),
                    common_broadcast:bc_send_msg_role(RoleID, ?BC_MSG_TYPE_CENTER, BroadcastMsg);
                false ->
                    %%不在线则直接删除Mneisa表数据
                    delete_offline_role_bag_good(RoleID,OfficeID)
            end;
        true ->
            ignore
    end.

retrieve_all_office_equip() ->
    Fun = fun() -> 
                  FactionOfficeList = db:match_object(?DB_FACTION, #p_faction{_='_'}, read),
                  lists:foreach(fun(FactionInfo) ->
                                        OfficeInfo = FactionInfo#p_faction.office_info,
                                        KingRoleID = OfficeInfo#p_office.king_role_id,
                                        retrieve_office_equip(KingRoleID,?OFFICE_ID_KING,?_LANG_OFFICE_RETAKE_OFFICE_EQUIP),
                                        Offices = OfficeInfo#p_office.offices,                            
                                        lists:foreach(fun(#p_office_position{office_id=OfficeID,role_id=RoleID}) ->
                                                              retrieve_office_equip(RoleID,OfficeID,?_LANG_OFFICE_RETAKE_OFFICE_EQUIP)
                                                      end, Offices)
                                end, FactionOfficeList)
          end,
    case db:transaction(Fun) of
        {atomic,_Info} ->
            ok;
        {aborted,Reason} ->
            ?ERROR_MSG("retrieve_all_office_equip error,reason=~w",[Reason]),
            error
    end.

delete_offline_role_bag_good(RoleID,OfficeID) ->
	%%得到玩家拥有的背包ID
	BagList = case db:dirty_read(?DB_ROLE_BAG_BASIC_P, RoleID) of
				  {'EXIT', Reason} ->
					  ?ERROR_MSG("~ts,Reason=~w", ["登录时脏读玩家背包信息出错",Reason]),
					  [];
				  [] ->
					  ?INFO_MSG("~ts,RoleId=~w", ["登录时脏读玩家背包信息为空",RoleID]),
					  [];
				  [BagInfoRecord] ->
					  #r_role_bag_basic{bag_basic_list = BagInfoListT} = BagInfoRecord,
					  [erlang:element(1,BagInfo)||BagInfo<-BagInfoListT]
			  end,
	%%删除背包官职装备
	ItemTypeID = ?OFFICE_EQUIP(OfficeID),
	lists:foreach(fun(BagId) ->
						  RoleBagKey = {RoleID,BagId},
						  case db:dirty_read(?DB_ROLE_BAG_P, RoleBagKey) of
							  {'EXIT', Reason2} ->
								  ?ERROR_MSG("~ts,RoleId=~w,BagId=~w,Reason=~w", 
											 ["登录时脏读玩家背包物品信息出错",RoleID,BagId,Reason2]),
								  ignore;
							  [] ->
								  ignore;
							  [RoleBagRecord] ->
								  #r_role_bag{bag_goods = GoodsList} = RoleBagRecord,
								  NewGoodsList = lists:keydelete(ItemTypeID,#p_goods.typeid,GoodsList),
								  case GoodsList =/= NewGoodsList of
									  true ->
										  NewRoleBagRecord = RoleBagRecord#r_role_bag{bag_goods = NewGoodsList},
										  db:dirty_write(?DB_ROLE_BAG_P, NewRoleBagRecord);
									  false ->
										  ignore
								  end
						  end
				  end,BagList),
	%%删除身上官职装备
	[RoleAttr] = db:dirty_read(?DB_ROLE_ATTR, RoleID),
	#p_role_attr{equips=Equips} = RoleAttr,
	Equips2 = lists:keydelete(ItemTypeID, #p_goods.typeid, Equips),
	case Equips2 =/= Equips of
		true ->
			RoleAttr2 = RoleAttr#p_role_attr{equips=Equips2},
			db:dirty_write(?DB_ROLE_ATTR, RoleAttr2);
		false ->
			ignore
	end,
	common_item_logger:log(RoleID, ItemTypeID, 1, undefined,?LOG_ITEM_TYPE_RETRIEVE_OFFICE_EQUIP).

%% 收回没有官职而拥有官印的玩家的官印装备(慎重)
delete_illegal_office_item() ->
	Fun = fun() ->
				  AllRoleList = db:match_object(?DB_ROLE_ATTR, #p_role_attr{_='_'}, read),
				  lists:foreach(fun(RoleAttr) ->
										#p_role_attr{role_id=RoleID,office_id=RoleOfficeID} = RoleAttr,
										case RoleOfficeID =:= 0 of
											true ->
												lists:foreach(fun(OfficeID) ->
																	  retrieve_office_equip(RoleID,OfficeID,"")
															  end, [1,2,3,4]);
											false ->
												ignore
										end
								end, AllRoleList)
		  end,
	case db:transaction(Fun) of
		{atomic,_Info} ->
			ok;
		{aborted,Reason} ->
			?ERROR_MSG("delete_illegal_office_item error,reason=~w",[Reason]),
			error
	end.