%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @doc 删除死号模块
%%%
%%% @end
%%% Created : 14 Jul 2011 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_del_role_info).

-include("common_server.hrl").

-include("common.hrl").
-include("role_tables.hrl").


-compile(export_all).

%% API
-export([
         do/0,
         do_guest/0,
         do_soft_clear/0,
         del_role_info/1
        ]).

%%%===================================================================
%%% API
%%%===================================================================


do()->
    case common_config:get_agent_id()=:=1 
             andalso common_config:get_server_id()=:=0 of
        true-> ignore;
        false->
            case common_config:is_debug() of
                true-> ignore;
                _ ->
                    do_2()
            end
    end,
    %%clear_bad_bags(),
    ?ERROR_MSG("=============del dead roles finished================",[]).


%%删除多余的背包数据
clear_bad_bags()->
    Guard = [],
    
    MatchHead1 = #r_role_bag_basic{role_id='$1', _='_'},
    RoleIDList = db:dirty_select(?DB_ROLE_BAG_BASIC_P, [{MatchHead1, Guard, ['$1']}]),
    
    MatchHead2 = #r_role_bag{role_bag_key='$1', _='_'},
    AllRoleBagKeyList = db:dirty_select(?DB_ROLE_BAG_P, [{MatchHead2, Guard, ['$1']}]),
    BadRoleBagKeyList = lists:filter( fun({RoleID,_})-> not lists:member(RoleID, RoleIDList) end, AllRoleBagKeyList),
    
    ?ERROR_MSG("length of badkey=~w",[length(BadRoleBagKeyList)]),
    [ db:dirty_delete(?DB_ROLE_BAG_P, RoleBagKey)  ||RoleBagKey<-BadRoleBagKeyList ],
    ok.

do_2()->
	%% 已经合服的服务器当做开服20天以上处理
	case common_config:is_merge() of
		true ->
			do_twenty_day();
		_ ->
			{OpenDate,_} = common_config:get_open_day(),
			OpenTime = common_tool:datetime_to_seconds({OpenDate,{0,0,0}}),
			Now = common_tool:now(),
			if Now - OpenTime =< 86400*3 ->
				   ignore;
			   Now - OpenTime =< 86400*10 -> 
				   do_three_day();
               Now - OpenTime =< 86400*20 -> 
                   do_ten_day();
			   true->
				   do_twenty_day()
			end
	end.

%%开服20天以上
do_twenty_day()->
    RoleIDList = get_del_role_list_20_day(),
    ?ERROR_MSG("~ts:~p", ["roles count to delete", erlang:length(RoleIDList)]),
    del_role_info(RoleIDList),
    
    disable_role_list(RoleIDList),
    clear_family_request_and_invite(),
    
    ok.

%%开服10天以上
do_ten_day() ->
    RoleIDList = get_del_role_list_10_day(),
    ?ERROR_MSG("~ts:~p", ["roles count to delete", erlang:length(RoleIDList)]),
    del_role_info(RoleIDList),
    
    disable_role_list(RoleIDList),
    clear_family_request_and_invite(),
    ok.


%%开服3天以上
do_three_day()->
    RoleIDList = get_role_del_list_3_day(),
    ?ERROR_MSG("~ts:~p", ["roles count to delete", erlang:length(RoleIDList)]),
    del_role_info(RoleIDList),
    
    disable_role_list(RoleIDList),
    clear_family_request_and_invite(),
    ok.

%% 删除游客帐号
do_guest() ->
    RoleIDList = get_guest_role_list(),
    ?ERROR_MSG("~ts:~p", ["guests count to delete", erlang:length(RoleIDList)]),
    del_role_info(RoleIDList),
    clear_family_request_and_invite(),
    ok.

%% 软清档操作
do_soft_clear() ->
    RoleIDList = get_soft_clear_role_list(),
    ?ERROR_MSG("~ts:~p", ["do_soft_clear roles count", erlang:length(RoleIDList)]),
    del_role_info(RoleIDList),
    clear_family_request_and_invite(),
    ok.

if_role_info_whole(RoleID) ->
    case db:dirty_read(?DB_ROLE_BASE_P, RoleID) of
        [] ->
            erlang:throw(false);
        _ ->
            ok
    end,
    case db:dirty_read(?DB_ROLE_ATTR_P, RoleID) of
        [] ->
            erlang:throw(false);
        _ ->
            ok
    end,
    case db:dirty_read(?DB_ROLE_POS_P, RoleID) of
        [] ->
            erlang:throw(false);
        _ ->
            ok
    end,
    case db:dirty_read(?DB_ROLE_EXT_P, RoleID) of
        [] ->
            erlang:throw(false);          
        _ ->
            ok
    end,
    case db:dirty_read(?DB_ROLE_STATE_P, RoleID) of
        [] ->
            erlang:throw(false);          
        _ ->
            ok
    end,
    true.


get_del_role_list(MatchRoleLv,MatchLoginDays,ShouldCheckBagUnbindGoods) ->
    [#r_roleid_counter{last_role_id=MaxRoleID}] = db:dirty_read(?DB_ROLEID_COUNTER_P, 1),
    lists:foldl(
        fun(RoleID, Acc) ->
                %% 首先检查角色信息是否完成，在一些意外宕机的情况下，某些玩家的部分数据可能会意外丢失
                case catch if_role_info_whole(RoleID) of
                    true ->
                        [#p_role_attr{level=Level, is_payed=IsPayed, gold=Gold,equips=Equips}] = db:dirty_read(?DB_ROLE_ATTR_P, RoleID),
                        [#p_role_ext{last_login_time=LastLoginTime}] = db:dirty_read(?DB_ROLE_EXT_P, RoleID),
                        [#p_role_base{family_id=FamilyID}] = db:dirty_read(?DB_ROLE_BASE_P, RoleID),     
                        %% 背包是否不绑
                        case ShouldCheckBagUnbindGoods of
                            true->
                                IsBagUnbindGoods = 
                                    case db:dirty_read(?DB_ROLE_BAG_BASIC_P, RoleID) of
                                        [] ->
                                            false;
                                        [#r_role_bag_basic{bag_basic_list=BagBasicList}] ->
                                            lists:any(
                                              fun(BagBasic)-> 
                                                      BagID = element(1,BagBasic),
                                                      case db:dirty_read(?DB_ROLE_BAG_P,{RoleID,BagID}) of
                                                          [#r_role_bag{bag_goods=BagGoodsList}]->
                                                              lists:any(fun(#p_goods{bind=Bind,type=Type})->
                                                                                Bind=:=false andalso (Type=:=3 orelse Type=:=2)
                                                                        end, BagGoodsList);
                                                          _->
                                                              false
                                                      end
                                              end, BagBasicList)
                                    end;
                            _ ->
                                IsBagUnbindGoods = false
                        end,
                        %% 临时仓库是否不绑
                        case ShouldCheckBagUnbindGoods of
                            true->
                                IsBoxUnbindGoods=
                                    case db:dirty_read(?DB_ROLE_BOX_P, RoleID) of
                                        [#r_role_box{all_list=AllList}]->
                                            lists:any(fun(#p_goods{bind=Bind,type=Type})->
                                                              Bind=:=false andalso (Type=:=3 orelse Type=:=2)
                                                      end, AllList);
                                        _->
                                            false
                                    end;
                            _ ->
                                IsBoxUnbindGoods = false
                        end,
                        case ShouldCheckBagUnbindGoods of
                            true->
                                IsEquipUnbindGoods=
                                    lists:any(fun(#p_goods{bind=Bind})-> Bind=:=false end, Equips);
                            _ ->
                                IsEquipUnbindGoods = false
                        end,
                        
                        %% 是否有不绑物品
                        BBagGoods = check_unbind_bag_goods(IsBagUnbindGoods),
                        %% 是否临时仓库有不邦
                        BBoxGoods = check_unbind_box_goods(IsBoxUnbindGoods),
                        %% 装备是否绑定
                        BEquipGoods = check_unbind_equips_goods(IsEquipUnbindGoods),
                        
                        %% 检查玩家等级
                        BLevel = Level =< MatchRoleLv,
                        %% 检查玩家充值情况
                        BPayed = check_role_payed(IsPayed),
                        %% 检查玩家是否有元宝
                        BGold = check_role_gold(Gold),
                        %% 检查玩家是否是族长，且宗族人数大于2
                        BFamily = check_role_family(RoleID, FamilyID),
                        %% 检查玩家最近10天是否登录过
                        BLastLoginTime = check_role_last_login_time(LastLoginTime,MatchLoginDays),
                        case BLevel 
                            andalso BPayed 
                            andalso BGold 
                            andalso BFamily 
                            andalso BLastLoginTime 
                            %%andalso BBank 
                            andalso BBagGoods
                            andalso BBoxGoods
                            andalso BEquipGoods of
                            true ->
                                %% 全部都不符合则加入删除列表
                                [RoleID | Acc];
                            false ->
                                Acc
                        end;
                    false ->
                        Acc
                end
        end, [], lists:seq(1, MaxRoleID)).

get_del_role_list_20_day() ->
    get_del_role_list(35, 10 * 86400 ,false).

get_del_role_list_10_day() ->
    get_del_role_list(35, 10 * 86400 ,true).

get_role_del_list_3_day()->
    get_del_role_list(15, 3 * 86400 ,true).

%% 删除游客帐号
get_guest_role_list() ->
    [#r_roleid_counter{last_role_id=MaxRoleID}] = db:dirty_read(?DB_ROLEID_COUNTER_P, 1),
    lists:foldl(
      fun(RoleID, Acc) ->
              case catch if_role_info_whole(RoleID) of
                  true ->
                      [#p_role_base{account_type=AccountType}] = db:dirty_read(?DB_ROLE_BASE_P, RoleID),
                      case AccountType =:= 3 of
                          true ->
                              [RoleID | Acc];
                          _ ->
                              Acc
                      end;
                  _ ->
                      Acc
              end
      end, [], lists:seq(1, MaxRoleID)).

%% 软清档操作
get_soft_clear_role_list() ->
    [#r_roleid_counter{last_role_id=MaxRoleID}] = db:dirty_read(?DB_ROLEID_COUNTER_P, 1),
    lists:foldl(
      fun(RoleID, Acc) ->
              case catch if_role_info_whole(RoleID) of
                  true ->
                      [RoleID | Acc];
                  _ ->
                      Acc
              end
      end, [], lists:seq(1, MaxRoleID)).

%% 检查玩家等级条件
check_role_level(Level) ->
    Level =< 10.

%% 检查玩家是否已充值
check_role_payed(IsPayed) ->
    not IsPayed.

%% 检查玩家元宝
check_role_gold(Gold) ->
    Gold =< 0.
%% 
%% 检查bag是否有不绑物品
check_unbind_bag_goods(IsUnbind)->
    not IsUnbind.

%% 检查bag是否有不绑物品
check_unbind_box_goods(IsUnbind)->
    not IsUnbind.

%% 检查身上是否有不绑定物品
check_unbind_equips_goods(IsUnbind)->
    not IsUnbind.

%% 检查玩家宗族
check_role_family(RoleID, FamilyID) ->
    case db:dirty_read(?DB_FAMILY_P, FamilyID) of
        [] ->
            case db:dirty_match_object(?DB_FAMILY_P, #p_family_info{create_role_id=RoleID, _='_'}) of
                [] ->
                    true;
                _ ->
                    false
            end;
        [#p_family_info{owner_role_id=OwnerRoleID, create_role_id=CreateRoleID, members=Members}] ->
            case RoleID =:= OwnerRoleID orelse RoleID =:= CreateRoleID of
                false ->
                    case db:dirty_match_object(?DB_FAMILY_P, #p_family_info{create_role_id=RoleID, _='_'}) of
                        [] ->
                            true;
                        _ ->
                            false
                    end;
                true ->
                    %% 宗族只有一个人，符合删除条件
                    erlang:length(Members) =:= 1
            end
    end.

check_role_last_login_time(LastLoginTime,MatchLoginDays) when is_integer(MatchLoginDays) ->
    common_tool:now() - LastLoginTime > MatchLoginDays.


del_role_info(RoleIDList) ->
    SetTables = ?ROLE_TABLES_COMMON ++ ?ROLE_TABLES_DEL,
  
    SetTabs2 = lists:filter(fun(E)-> db:table_info(E, size)>0 end, SetTables),
    [ begin
          catch remove_role_account(RoleID),
          catch remove_role_family_info(RoleID),
          
          del_role_set_tables(RoleID,SetTabs2),
          
          remove_role_friend_info(RoleID),
          remove_role_stall_info(RoleID),
          remove_role_bag_info(RoleID),
          
          remove_role_chat_info(RoleID),
          catch remove_role_fcm_info(RoleID),
          remove_role_title_info(RoleID),
          remove_role_achievement_rank_info(RoleID),
          remove_role_ybc_info(RoleID),
          
          remove_role_user_event_info(RoleID),
          
          remove_role_hero_fb_info(RoleID),
          remove_role_mission_fb_info(RoleID),
          
          remove_role_pet_info(RoleID),
          
          catch del_role_letter(RoleID),
          catch del_role_name(RoleID)
      end||RoleID<-RoleIDList ], 
    ok.

%% 清理掉宗族申请列表信息和邀请记录
clear_family_request_and_invite() ->   
    db:clear_table(?DB_FAMILY_REQUEST_P),
    db:clear_table(?DB_FAMILY_INVITE_P),
    lists:foreach(
      fun(FamilyInfo) ->
              db:dirty_write(?DB_FAMILY, FamilyInfo#p_family_info{request_list=[], invite_list=[]}),
              db:dirty_write(?DB_FAMILY_P, FamilyInfo#p_family_info{request_list=[], invite_list=[]})
      end, db:dirty_match_object(?DB_FAMILY_P, #p_family_info{_='_'})),
    ok.

remove_role_mission_fb_info(RoleID) ->
    db:dirty_delete(?DB_ROLE_MISSION_FB_P, {RoleID, 101}),
    db:dirty_delete(?DB_ROLE_MISSION_FB_P, {RoleID, 102}),
    db:dirty_delete(?DB_ROLE_MISSION_FB_P, {RoleID, 103}),
    db:dirty_delete(?DB_ROLE_MISSION_FB_P, {RoleID, 104}),
    ok.


%%删除大多数的SET表记录
del_role_set_tables(RoleID,SetTabs2)->
    [ db:dirty_delete(Tab, RoleID) ||Tab<-SetTabs2 ],
    ok.

del_role_name(RoleID) ->
    [#p_role_base{role_name=RoleName}] = db:dirty_read(?DB_ROLE_BASE_P, RoleID),
    db:dirty_delete(?DB_ROLE_NAME_P, RoleName).


del_role_letter(RoleID) ->
    [db:dirty_delete_object(?DB_PERSONAL_LETTER_P, R) || 
        R <- db:dirty_match_object(?DB_PERSONAL_LETTER_P, #r_personal_letter{send_id=RoleID, _='_'})],
    [db:dirty_delete_object(?DB_PERSONAL_LETTER_P, R) || 
        R <- db:dirty_match_object(?DB_PERSONAL_LETTER_P, #r_personal_letter{recv_id=RoleID, _='_'})],
    db:dirty_delete(?DB_PUBLIC_LETTER_P, RoleID),
    ok.

remove_role_pet_info(RoleID) ->    
    case db:dirty_read(?DB_ROLE_PET_BAG_P, RoleID) of
        [] ->
            ignore;
        [#p_role_pet_bag{pets=Pets}] ->
            lists:foreach(
              fun(Pet) ->
                      db:dirty_delete(?DB_PET_P, Pet#p_pet_id_name.pet_id)
              end, Pets)
    end,
    db:dirty_delete(?DB_ROLE_PET_BAG_P, RoleID),
    ok.

remove_role_hero_fb_info(RoleID) ->
    [begin
     List=lists:keydelete(RoleID, #p_hero_fb_record.role_id, R#r_hero_fb_record.best_record),
         db:dirty_write(?DB_HERO_FB_RECORD_P, R#r_hero_fb_record{best_record=List})
     end
     ||R<-db:dirty_match_object(?DB_HERO_FB_RECORD_P,#r_hero_fb_record{_='_'})].



%% 删除角色相关事件
remove_role_user_event_info(RoleID) ->
    [db:dirty_delete_object(?DB_USER_EVENT_P, R) || R <- db:dirty_match_object(?DB_USER_EVENT_P, #r_user_event{role_id=RoleID, _='_'})],
    ok.



%% 删除镖车信息
remove_role_ybc_info(RoleID) ->
    db:dirty_delete(?DB_YBC_PERSON_P, RoleID),
    case db:dirty_read(?DB_YBC_UNIQUE_P, {0,1,RoleID}) of
        [#r_ybc_unique{id=ID}]->
            db:dirty_delete(?DB_YBC_P,ID);
        _->
            ignore
    end,
    db:dirty_delete(?DB_YBC_UNIQUE_P, {0, 1, RoleID}).


%% 删除成就榜信息
remove_role_achievement_rank_info(RoleID) ->
    [db:dirty_delete_object(?DB_ACHIEVEMENT_RANK_P, R) || 
       R <- db:dirty_match_object(?DB_ACHIEVEMENT_RANK_P, #r_achievement_rank{role_id = RoleID, _='_' })],
    ok.
%% 删除角色称号信息
remove_role_title_info(RoleID) ->
    [db:dirty_delete_object(?DB_NORMAL_TITLE_P, R) || R <- db:dirty_match_object(?DB_NORMAL_TITLE_P, #p_title{role_id=RoleID,_='_'})],
    [db:dirty_delete_object(?DB_SPEC_TITLE_P, R) || R <- db:dirty_match_object(?DB_SPEC_TITLE_P, #p_title{role_id=RoleID,_='_'})].


%% 删除聊天信息
remove_role_chat_info(RoleID) ->
    [db:dirty_delete_object(?DB_CHAT_CHANNEL_ROLES_P, R) || 
        R <- db:dirty_match_object(?DB_CHAT_CHANNEL_ROLES_P, #p_chat_channel_role_info{role_id=RoleID, _='_'})],
    db:dirty_delete(?DB_CHAT_ROLE_CHANNELS_P, RoleID),
    ok.


%% 删除角色背包信息
remove_role_bag_info(RoleID) ->
    case db:dirty_read(?DB_ROLE_BAG_BASIC_P, RoleID) of
        [] ->
            ignore;
        [ #r_role_bag_basic{bag_basic_list=BagBasicList} ] ->
            [ begin 
                  BagID = element(1,BagBasic), db:dirty_delete(?DB_ROLE_BAG_P, {RoleID, BagID}) 
              end || BagBasic<-BagBasicList ],
            db:dirty_delete(?DB_ROLE_BAG_BASIC_P,RoleID)
    end.


%% 删除玩家摆摊信息
remove_role_stall_info(RoleID) ->
    [db:dirty_delete_object(?DB_STALL_GOODS_P, R) || R <- db:dirty_match_object(?DB_STALL_GOODS_P, #r_stall_goods{role_id=RoleID, _='_'})],
    [db:dirty_delete_object(?DB_STALL_GOODS_TMP_P, R) || R <- db:dirty_match_object(?DB_STALL_GOODS_TMP_P, #r_stall_goods{role_id=RoleID, _='_'})],
    ok.
    

%% 这次暂时使用旧的FRIEND的表结构。
%% 删除角色好友信息
remove_role_friend_info(RoleID) ->
    [db:dirty_delete_object(?DB_FRIEND_P, R) || R <- db:dirty_match_object(?DB_FRIEND_P, #r_friend{roleid=RoleID, _='_'})],
    [db:dirty_delete_object(?DB_FRIEND_P, R) || R <- db:dirty_match_object(?DB_FRIEND_P, #r_friend{friendid=RoleID, _='_'})],
    ok.

remove_role_fcm_info(RoleID) ->
    [#p_role_base{account_name=AccountName}] = db:dirty_read(?DB_ROLE_BASE_P, RoleID),
    db:dirty_delete(?DB_FCM_DATA_P, AccountName).

%% 删除玩家账号
remove_role_account(RoleID) ->
    [#p_role_base{account_name=AccountName}] = db:dirty_read(?DB_ROLE_BASE_P, RoleID),
    db:dirty_delete(?DB_ACCOUNT_P, AccountName).

%% 删除角色宗族的相关信息
remove_role_family_info(RoleID) ->
    [#p_role_base{family_id=FamilyID}] = db:dirty_read(?DB_ROLE_BASE_P, RoleID),
    case FamilyID > 0 of
        true ->
            %% 如果是族长，则是解散宗族，前提是宗族只有一个人
            case db:dirty_read(?DB_FAMILY_P, FamilyID) of
                [] ->
                    ok;
                [#p_family_info{members=Members, owner_role_id=OwnerRoleID, second_owners=SecondOwners} = FamilyInfo] ->
                    case RoleID =:= OwnerRoleID of
                        true ->
                            case erlang:length(Members) =:= 1 of
                                true ->
                                    db:dirty_delete(?DB_FAMILY_EXT_P, FamilyID),
                                    db:dirty_delete(?DB_FAMILY_P, FamilyID);
                                false ->
                                    ?ERROR_MSG("~ts:~p", ["严重错误，一个要被删除的族长的宗族成员数量大于1，RoleID：", RoleID]),
                                    erlang:throw(error)
                            end;
                        false ->
                            %% 从宗族成员列表中删除对应的成员，如果是副族长也要删除
                            NewMembers = lists:keydelete(RoleID, #p_family_member_info.role_id, Members),
                            NewSecondOwners = lists:keydelete(RoleID, #p_family_second_owner.role_id, SecondOwners),
                            NewFamilyInfo = FamilyInfo#p_family_info{second_owners=NewSecondOwners,
                                                                                  members=NewMembers,
                                                                                  cur_members=erlang:length(NewMembers)},
                            db:dirty_write(?DB_FAMILY, NewFamilyInfo),
                            db:dirty_write(?DB_FAMILY_P, NewFamilyInfo)
                    end
            end,
            %% 玩家宗族捐献记录
            case db:dirty_read(?DB_FAMILY_DONATE_P,FamilyID) of
                [] ->
                    ok;
                [FamilyDonate] ->
                    GoldDonateList = lists:keydelete(RoleID, #p_role_family_donate_info.role_id, FamilyDonate#r_family_donate.gold_donate_record),
                    SilverDonateList = lists:keydelete(RoleID, #p_role_family_donate_info.role_id, FamilyDonate#r_family_donate.silver_donate_record),
                    db:dirty_write(?DB_FAMILY_DONATE,FamilyDonate#r_family_donate{gold_donate_record=GoldDonateList,silver_donate_record=SilverDonateList})
            end,
            ok;
        false ->
            ignore
    end.


%%@doc 在mysql中将删号的玩家设置为屏蔽
disable_role_list([])->
    ignore;
disable_role_list(RoleIDList)->
    ?ERROR_MSG("start to disable_role_list",[]),
    
    StrRoleList = get_role_comma_list(RoleIDList),
    SqlUpdate = "update db_role_base_p set is_disabled=1 where role_id in("++ StrRoleList ++")",
    ?TRY_CATCH( mod_mysql:update(SqlUpdate,120*1000) ), %%2分钟
    ok.

%%@return RoleID和逗号间隔组成的字符串
get_role_comma_list(RoleIDList) when is_list(RoleIDList)->
    RoleIDCommaList1 = 
        lists:foldl(
          fun(E,AccIn)->
                  [",",E|AccIn]
          end, [], RoleIDList),
    [_H|RoleIDCommaList2] = RoleIDCommaList1,
    
    lists:concat( RoleIDCommaList2 ).
