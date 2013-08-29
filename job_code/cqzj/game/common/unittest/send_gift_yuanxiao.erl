%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%         元宵赠送调料包的准备脚本
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(send_gift_yuanxiao).

%%
%% Include files
%%
%%
%% Include files
%%
 
-define( INFO(F,D),io:format(F, D) ).
-include("common.hrl").
-include("common_server.hrl").
-include("letter.hrl").


%%
%% Exported Functions
%%
-export([send/0]).

%%
%% API Functions
%%

send()->
    RoleIDList1 = get_all_roleids(),
    do_gm_send_goods_batch(RoleIDList1).

%%获取所有的玩家列表
get_all_roleids()->
    MatchHead = #p_role_base{role_id='$1', _='_'},
    Guard = [],
    db:dirty_select(db_role_base, [{MatchHead, Guard, ['$1']}]).

do_gm_send_goods_batch(RoleIDList1)->
    
    CreateInfo = #r_goods_create_info{bind=true, type=?TYPE_ITEM, bag_id=0, type_id=10100016, start_time=0,
                                      end_time=0, num=1, color=1, quality=1, punch_num=0, rate=0, result=0,
                                      interface_type=present },
    
    
    Now = common_tool:now(),
    RoleIDList2 = lists:filter(fun(RoleID)-> if_can_accept_system_letter(RoleID, Now) end, RoleIDList1),
    
    Content = common_letter:create_temp(?YUANXIAO_GIFT_LETTER,[]),
    
    ResultList = [do_send_goods_only(RoleID,Content,CreateInfo) || RoleID<-RoleIDList2 ],
    
    FailList = lists:filter(fun(E)->
                                    case E of
                                        {error,_ID,_Reason} -> true;
                                        _ -> false
                                    end
                            end, ResultList),
    AllCount = length(RoleIDList2),
    FailCount = length(FailList),
    
    IsAllSucc = FailCount =:= 0,
    IsAllFail = AllCount =:= FailCount,
    
    if
        IsAllSucc =:= true->
            ?ERROR_MSG("系统批量赠送道具全部成功,AllCount=~w,FailCount=~w",[AllCount,FailCount]),
            {ok,AllCount,FailCount};
        IsAllFail =:= true->
            ?ERROR_MSG("系统批量赠送道具全部失败,AllCount=~w,RoleIDList1=~w,CreateInfo=~w",[AllCount,RoleIDList1,CreateInfo]),
            {error,AllCount,FailCount};
        true ->
            ?ERROR_MSG("gm_send_goods_batch error,AllCount=~w,FailCount=~w,FailList=~w",[AllCount,FailCount,FailList]),
            {ok_part,AllCount,FailCount}
    end.

%%@doc 创建作为赠送用途的默认物品
create_goods(RoleID,Info)->
    #r_goods_create_info{bind=Bind, bag_id=BagID, type=Type, type_id=TypeID, start_time=StartTime, end_time=EndTime,
                        num=Num, color=Color, quality=Quality, punch_num=PunchNum, property=Property, rate=Rate, result=Result,
                        result_list=ResultList, interface_type=InterfaceType,use_pos=UsePosList} = Info,
    case Type of
        ?TYPE_ITEM ->
            Info2 = #r_item_create_info{role_id=RoleID, bag_id=BagID,  num=Num, typeid=TypeID, bind=Bind,
                                        start_time=StartTime, end_time=EndTime, color=Color,use_pos=UsePosList},
            common_bag2:create_item(Info2);
        ?TYPE_STONE ->
            Info2 = #r_stone_create_info{role_id=RoleID, bag_id=BagID,  num=Num, typeid=TypeID, bind=Bind,
                                          start_time=StartTime, end_time=EndTime},
            common_bag2:creat_stone(Info2);
        ?TYPE_EQUIP ->
            Info2 = #r_equip_create_info{role_id=RoleID, bag_id=BagID,  num=Num, typeid=TypeID, bind=Bind,
                                         start_time=StartTime, end_time=EndTime, color=Color, quality=Quality, punch_num=PunchNum,
                                         property=Property, rate=Rate, result=Result, result_list=ResultList, interface_type=InterfaceType},
            common_bag2:creat_equip_without_expand(Info2)
    end.


do_send_goods_only(RoleID,Text,CreateInfo)->
    case create_goods(RoleID,CreateInfo) of
        {ok,GoodsListOld}->
            %%设置bagid为9999，表示后台赠送
            GoodsList = [ G#p_goods{id=1,bagposition=1,bagid=9999}||G<-GoodsListOld ],
            common_letter:sys2p(RoleID,Text,"元宵礼物",GoodsList,14),
            ok;
        {error,Reason}->
            ?ERROR_MSG("create_goods error,Reason=~w",[Reason]),
            {error,RoleID,Reason}
    end.

insert_receive_letter(RoleID, RoleName, SysLetter) ->
    db:transaction(
      fun() ->
              NewLetter =  SysLetter#r_letter_info{receiver = RoleName},
              case db:read(?DB_LETTER_RECEIVER, RoleID) of
                  [] ->
                      NewBox = #r_letter_receiver{role_id = RoleID,letter = [NewLetter],count=1};
                  [ReceBox] -> 
                      #r_letter_receiver{letter = OldLetter} = ReceBox,
                      NewBox = ReceBox#r_letter_receiver{letter = [NewLetter|OldLetter]}
              end,
              db:write(?DB_LETTER_RECEIVER, NewBox, write)  
      end 
    ).


%% @doc 检察是否可以接收系统信件
if_can_accept_system_letter(RoleID, Now) ->
    %% 超过14天不登陆，不接收系统信件
    case common_misc:get_dirty_role_ext(RoleID) of
        {ok, #p_role_ext{last_offline_time=LastOfflineTime}} ->
            Now - LastOfflineTime =< 14*24*3600;
        _ ->
            false
    end.






insert_item_log(RoleID,Goods)->
    common_item_logger:log(RoleID,Goods,?LOG_ITEM_TYPE_GET_ADMIN).

get_time_day(NowTime, Days) 
   when is_integer(Days),is_integer(NowTime) ->
  NowTime+(Days*86400).
