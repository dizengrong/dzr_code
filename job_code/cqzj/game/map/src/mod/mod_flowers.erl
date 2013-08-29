%% Author: liurisheng
%% Created: 2010-12-27
%% Description: 
-module(mod_flowers).

-include("mgeem.hrl").

-define(CONTACE,1). %%联系
-define(THANKS,2).  %%谢谢
-define(KISS,3).    %%回吻

-define(MALE,1).   %%男性
-define(FEMALE,2). %%女性

-export([init_role_data/1,handle/1,get_give_score/1, free_broadcast_flower/1]).

-record(r_flower,{type_id,name,broadcast_type,charm,score,broadcasting}). 

init_role_data(RoleID) ->
    case db:dirty_read(?DB_ROLE_RECEIVE_FLOWERS,RoleID) of
        [#r_receive_flowers{flowers=Flowers}]when Flowers =/= [] ->
            Data = #m_flowers_get_accept_list_toc{list=Flowers},
            common_misc:unicast({role,RoleID},?DEFAULT_UNIQUE,?FLOWERS,?FLOWERS_GET_ACCEPT_LIST,Data);
        _ ->
            ignore
    end.

handle({Unique,?FLOWERS,?FLOWERS_ACCEPT,DataIn,RoleID,PID,_Line,_State}) ->
    #m_flowers_accept_tos{id=ID}=DataIn,
    Data = case db:dirty_read(?DB_ROLE_RECEIVE_FLOWERS,RoleID) of
               [#r_receive_flowers{flowers=Flowers}=Box]when Flowers =/= [] ->
                   NewFlowers = lists:keydelete(ID,2,Flowers),
                   NewBox = Box#r_receive_flowers{flowers=NewFlowers},
                   db:dirty_write(?DB_ROLE_RECEIVE_FLOWERS,NewBox),
                   #m_flowers_accept_toc{succ=true,id=ID};
               _ ->
                   #m_flowers_accept_toc{succ=false,id=ID}
           end,
    common_misc:unicast2(PID,Unique,?FLOWERS,?FLOWERS_ACCEPT,Data);

handle({Unique,?FLOWERS,?FLOWERS_GET_RECEVER_INFO,DataIn,_RoleID,PID,_Line,_State}) ->    
    #m_flowers_get_recever_info_tos{role_name=RoleName} = DataIn,
    ?DEBUG("~ts,~w",["开始",common_misc:get_roleid(RoleName)]),
    Data = case common_misc:get_roleid(RoleName) of
               0 ->
                   #m_flowers_get_recever_info_toc{succ=false,reason=?_LANG_FLOWERS_NOT_ROLE};  
               RRoleID ->
                   {ok,RoleBase} =  common_misc:get_dirty_role_base(RRoleID),
                   #m_flowers_get_recever_info_toc{succ=true,
                                                   role_id = RoleBase#p_role_base.role_id,
                                                   role_name = RoleBase#p_role_base.role_name,
                                                   sex = RoleBase#p_role_base.sex}
           end,
    common_misc:unicast2(PID,Unique,?FLOWERS,?FLOWERS_GET_RECEVER_INFO,Data);
    
handle({Unique,?FLOWERS,?FLOWERS_GIVE,DataIn,RoleID,PID,_Line,_State}) ->
    #m_flowers_give_tos{rece_role_id=ToRoleID,is_anonymous=IsAnonymous,
                        goods_id=GoodsID,flowers_type=TypeID}=DataIn,
    Data = try  
               {ok,ReceRoleBase} = common_misc:get_dirty_role_base(ToRoleID),
               {ok,SelfRoleBase} = mod_map_role:get_role_base(RoleID),
               case check_anonymous(ReceRoleBase,SelfRoleBase,IsAnonymous) of
                   ok ->
                       next;
                   {error,Error} ->
                       throw(Error)
               end,
               case get_giver_bag_flower(RoleID,GoodsID,TypeID) of
                   {error,Reason1} ->
                       throw(Reason1);
                   {ok,Goods} ->
                       [FlowersInfo] = common_config_dyn:find(flowers,Goods#p_goods.typeid),
											 catch global:send(mgeew_special_activity, {1,RoleID, FlowersInfo#r_flower.score}),
                       %%判断被赠送者是否在线(在线的话，魅力值和鲜花列表发到他所在的进程去处理)
                       case common_misc:is_role_online(ToRoleID) of
                           true->
                               recever_online_handle(RoleID,Goods,FlowersInfo,SelfRoleBase,ReceRoleBase,IsAnonymous);                              
                           _ ->
                               recever_offline_handle(RoleID,Goods,FlowersInfo,SelfRoleBase,ReceRoleBase,IsAnonymous)
                       end
               end
							 
           catch
               _:Reason when is_binary(Reason) ->
                   ?ERROR_MSG("Flowers:~w stacktrace:~w~n",[Reason,erlang:get_stacktrace()]),
                   #m_flowers_give_toc{succ=false,tips=Reason};
               _:Reason ->
                   ?ERROR_MSG("Flowers:~w stacktrace:~w~n",[Reason,erlang:get_stacktrace()]),
                   #m_flowers_give_toc{succ=false,tips=?_LANG_FLOWERS_SYSTEM_ERROR}
           end,
    common_misc:unicast2(PID,Unique,?FLOWERS,?FLOWERS_GIVE, Data);
handle({{give_flowers,FlowersInfo,GiveBase,ReceBase,IsAnonymous},_State}) ->
    {ok,#p_role_attr{charm=Charm} = ReceAttr} = mod_map_role:get_role_attr(ReceBase#p_role_base.role_id),
    NewReceAttr = ReceAttr#p_role_attr{charm=Charm+FlowersInfo#r_flower.charm},
    case common_transaction:transaction(
           fun() -> 
                   mod_map_role:set_role_attr(ReceBase#p_role_base.role_id,NewReceAttr),
                   [ReceInfo] = db:dirty_read(?DB_ROLE_RECEIVE_FLOWERS,ReceBase#p_role_base.role_id),
                   db:dirty_write(?DB_ROLE_RECEIVE_FLOWERS,ReceInfo#r_receive_flowers{charm = Charm+FlowersInfo#r_flower.charm}),
                   dirty_write_receive_flowers(ReceBase#p_role_base.role_id,GiveBase,FlowersInfo#r_flower.type_id)
           end)
    of
        {aborted, Abort} ->
            ?ERROR_MSG("Abort:~w~n",[Abort]);
        {atomic, RoleFlowerInfo} ->   
            RC = #m_role2_attr_change_toc{roleid=ReceBase#p_role_base.role_id,
                                          changes=[#p_role_attr_change{change_type=?ROLE_CHARM_CHANGE,new_value=NewReceAttr#p_role_attr.charm}]},
            common_misc:unicast({role,ReceBase#p_role_base.role_id}, ?DEFAULT_UNIQUE,?ROLE2,?ROLE2_ATTR_CHANGE,RC),
            ?DEBUG("RoleAttr:~w, NewRoleAttr:~w~n",[ReceAttr,NewReceAttr]),
            common_rank:update_element(ranking_rece_flowers,{ReceBase,NewReceAttr}),
            common_rank:update_element(ranking_rece_flowers_today,{ReceBase,NewReceAttr,FlowersInfo#r_flower.charm}),
            
            
            case get_broadcasting(IsAnonymous,FlowersInfo,GiveBase#p_role_base.role_name,ReceBase#p_role_base.role_name) of
                {ok, none, ""} -> 
                    ignore;
                {ok,BroadcastType,Str1,Str2} ->
                    BroadcastInfo = #p_flowers_give_broadcast_info{broadcasting = Str1,
                                                                   receiver = ReceBase#p_role_base.role_name,
                                                                   giver = GiveBase#p_role_base.role_name,
                                                                   flowers_type = FlowersInfo#r_flower.type_id},
                    common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,"<font color=\"#FFC000\">"++Str2++"</font>"),
                    broadcast(BroadcastType,BroadcastInfo,GiveBase,ReceBase)
            end,
            TocUpdate = #m_flowers_update_accept_toc{info=RoleFlowerInfo},
            RegName = common_misc:get_role_line_process_name( ReceBase#p_role_base.role_id),
            Pid = global:whereis_name(RegName),
            common_misc:unicast2(Pid,?DEFAULT_UNIQUE,?FLOWERS,?FLOWERS_UPDATE_ACCEPT,TocUpdate)
    end.

get_giver_bag_flower(RoleID,GoodsID,_TypeID) ->
    case is_integer(GoodsID) andalso GoodsID > 0 of
        true ->
            case mod_bag:get_goods_by_id(RoleID,GoodsID) of
                {error,goods_not_found} ->
                    {error,?_LANG_FLOWERS_NOT_FLOWER};
                {error,_} ->
                    {error,?_LANG_FLOWERS_SYSTEM_ERROR};
                {ok,GoodsInfo} ->
                    {ok,GoodsInfo}
            end;
        false ->
            case mod_bag:get_goods_by_typeid(RoleID,_TypeID,[1,2,3]) of
                {ok, []} ->
                    {error,?_LANG_FLOWERS_NOT_FLOWER};
                {ok, [Goods|_]} ->
                    {ok,Goods}
            end
    end.

%%鲜花接收者在线的处理
recever_online_handle(RoleID,Goods,FlowersInfo,SelfRoleBase,ReceRoleBase,IsAnonymous) ->
    case common_transaction:transaction(
           fun() ->
                   [#r_give_flowers{score=Score}=RoleGiveInfo] = 
                       db:dirty_read(?DB_ROLE_GIVE_FLOWERS,RoleID),
                   NewRoleGiveInfo = RoleGiveInfo#r_give_flowers{score=Score+FlowersInfo#r_flower.score},
                   db:dirty_write(?DB_ROLE_GIVE_FLOWERS,NewRoleGiveInfo),
                   {ok,SelfRoleAttr} = mod_map_role:get_role_attr(RoleID),
                     
                   case Goods#p_goods.current_num-1 of
                       0 -> 
                           mod_bag:delete_goods(RoleID,Goods#p_goods.id),
                           {ok,[Goods#p_goods{current_num=0}],SelfRoleAttr,Score+FlowersInfo#r_flower.score,FlowersInfo#r_flower.score};
                       R ->
                           mod_bag:update_goods(RoleID, Goods#p_goods{current_num=R}),
                           {ok,[Goods#p_goods{current_num=R}],SelfRoleAttr,Score+FlowersInfo#r_flower.score,FlowersInfo#r_flower.score}
                   end
           end)
    of
        {aborted, Abort} ->
            ?ERROR_MSG("Abort:~w~n",[Abort]),
            #m_flowers_give_toc{succ=false,tips=?_LANG_FLOWERS_SYSTEM_ERROR};
        {atomic, {ok,UpdateGoodsList,SelfRoleAttr,NewScore,AddScore}} ->
            give_flowers_log(RoleID, UpdateGoodsList),
            catch global:send(mod_friend_server,{give_flower,RoleID,ReceRoleBase#p_role_base.role_id,Goods#p_goods.typeid}),
            common_rank:update_element(ranking_give_flowers,{SelfRoleBase,SelfRoleAttr,NewScore}),
            common_rank:update_element(ranking_give_flowers_today,{SelfRoleBase,SelfRoleAttr,AddScore}),
            common_misc:update_goods_notify({role,RoleID},UpdateGoodsList),
            mgeer_role:send(ReceRoleBase#p_role_base.role_id, {mod_flowers,
            	{give_flowers,FlowersInfo,SelfRoleBase,ReceRoleBase,IsAnonymous}
			}),
            Tips = "已经成功向[" ++ binary_to_list(ReceRoleBase#p_role_base.role_name) ++ "]赠送" ++ FlowersInfo#r_flower.name,
            #m_flowers_give_toc{succ=true,tips=Tips}
    end.

%%鲜花接收者不在线的处理          
recever_offline_handle(RoleID,Goods,FlowersInfo,SelfRoleBase,ReceRoleBase,IsAnonymous) ->
    case common_transaction:transaction(
           fun() ->
                   #r_flower{charm=AddCharm,score=AddScore} = FlowersInfo,
                   [#p_role_attr{charm=Charm} = ReceRoleAttr] = 
                       db:dirty_read(?DB_ROLE_ATTR,ReceRoleBase#p_role_base.role_id),
                   NewReceRoleAttr = ReceRoleAttr#p_role_attr{charm=Charm+AddCharm},
                   db:dirty_write(?DB_ROLE_ATTR,NewReceRoleAttr),
                   [ReceInfo] = db:dirty_read(?DB_ROLE_RECEIVE_FLOWERS,ReceRoleBase#p_role_base.role_id),
                   db:dirty_write(?DB_ROLE_RECEIVE_FLOWERS,ReceInfo#r_receive_flowers{charm = Charm+AddCharm}),
                   [#r_give_flowers{score=Score}=RoleGiveInfo] = 
                       db:dirty_read(?DB_ROLE_GIVE_FLOWERS,RoleID),
                   db:dirty_write(?DB_ROLE_GIVE_FLOWERS,
                                  RoleGiveInfo#r_give_flowers{score=Score+AddScore}),
                   {ok,SelfAttr} = mod_map_role:get_role_attr(RoleID),
                   case Goods#p_goods.current_num-1 of
                       0 -> 
                           mod_bag:delete_goods(RoleID,Goods#p_goods.id),
                           {ok,[Goods#p_goods{current_num=0}],SelfAttr,NewReceRoleAttr,Score+AddScore,AddScore,AddCharm};
                       R ->
                           mod_bag:update_goods(RoleID, Goods#p_goods{current_num=R}),
                           {ok,[Goods#p_goods{current_num=R}],SelfAttr,NewReceRoleAttr,Score+AddScore,AddScore,AddCharm}
                   end
           end)
    of
        {aborted, Abort} ->
            ?ERROR_MSG("Abort:~w~n",[Abort]),
            #m_flowers_give_toc{succ=false,tips=?_LANG_FLOWERS_SYSTEM_ERROR};
        {atomic,{ok,UpdateGoodsList,SelfRoleAttr,ReceRoleAttr,NewScore,AddScore,AddCharm}} ->
            give_flowers_log(RoleID, UpdateGoodsList),
            catch global:send(mod_friend_server,{give_flower,RoleID,ReceRoleBase#p_role_base.role_id,Goods#p_goods.typeid}),
            common_rank:update_element(ranking_give_flowers,{SelfRoleBase,SelfRoleAttr,NewScore}),
            common_rank:update_element(ranking_give_flowers_today,{SelfRoleBase,SelfRoleAttr,AddScore}),
            common_rank:update_element(ranking_rece_flowers,{ReceRoleBase,ReceRoleAttr}),
            common_rank:update_element(ranking_rece_flowers_today,{ReceRoleBase,ReceRoleAttr,AddCharm}),
            common_misc:update_goods_notify({role,RoleID},UpdateGoodsList),        
            dirty_write_receive_flowers(ReceRoleBase#p_role_base.role_id,SelfRoleBase,FlowersInfo#r_flower.type_id),
            case get_broadcasting(IsAnonymous,FlowersInfo,SelfRoleBase#p_role_base.role_name,ReceRoleBase#p_role_base.role_name) of
                {ok, none, ""} ->
                    ignore;
                {ok,BroadcastType,Str1,Str2} ->
                    BroadcastInfo = #p_flowers_give_broadcast_info{broadcasting = Str1,
                                                                   receiver = ReceRoleBase#p_role_base.role_name,
                                                                   giver = SelfRoleBase#p_role_base.role_name,
                                                                   flowers_type = FlowersInfo#r_flower.type_id},
                    common_broadcast:bc_send_msg_world(?BC_MSG_TYPE_CHAT,?BC_MSG_TYPE_CHAT_WORLD,"<font color=\"#FFC000\">"++Str2++"</font>"),
                    broadcast(BroadcastType,BroadcastInfo,SelfRoleBase,ReceRoleBase)
            end,
            Tips = "已经成功向[" ++ binary_to_list(ReceRoleBase#p_role_base.role_name) ++ "]赠送" ++ FlowersInfo#r_flower.name,
            #m_flowers_give_toc{succ=true,tips=Tips}
    end.      

give_flowers_log(RoleID, GoodsList) ->
    lists:foreach(
      fun(#p_goods{typeid=TypeID,bind=Bind}=_Goods) ->
              common_item_logger:log(RoleID, TypeID,1,Bind,?LOG_ITEM_TYPE_FLOWERS_GIVE_SHI_QU)
      end,GoodsList).
    
dirty_write_receive_flowers(ReceRoleID,GiveBase,FlowersType)->
    [RoleFlowerBox] = db:dirty_read(?DB_ROLE_RECEIVE_FLOWERS,ReceRoleID),
    #r_receive_flowers{flowers=OldFlowers,count=OldCount} = RoleFlowerBox,
    RoleFlowerInfo = #p_flowers_give_info{id = OldCount+1,
                                          give_role_id = GiveBase#p_role_base.role_id,
                                          giver = GiveBase#p_role_base.role_name, 
                                          giver_sex = GiveBase#p_role_base.sex,
                                          giver_faction = GiveBase#p_role_base.faction_id,
                                          flowers_type = FlowersType},
    NewRoleFlowerBox = RoleFlowerBox#r_receive_flowers{flowers=[RoleFlowerInfo|OldFlowers],
                                                       count=OldCount+1},
    db:dirty_write(?DB_ROLE_RECEIVE_FLOWERS,NewRoleFlowerBox),
    RoleFlowerInfo.

check_anonymous(SelfRoleBase,ReceRoleBase,IsAnonymous) ->
    if IsAnonymous =:= true ->
            ok;
       ReceRoleBase#p_role_base.sex =:= 
       SelfRoleBase#p_role_base.sex -> 
            {error,?_LANG_FLOWERS_SAME_SEX};
       %% ReceRoleBase#p_role_base.sex =:= ?FEMALE andalso
       %% SelfRoleBase#p_role_base.sex =:= ?MALE   ->
       %%      {error,?_LANG_FLOWERS_FEMALE_TO_MALE};
       true ->
            ok
    end.

get_broadcasting(true,FlowersInfo,_GiveName,_ReceName) ->
    case FlowersInfo#r_flower.broadcast_type of
        none ->
            {ok, none, ""};
        BroadCastType ->
            Str1 = format_broadcasting(?_LANG_FLOWERS_DEFAULT_BROADCASTING, 
                                       [common_tool:to_list(_ReceName),FlowersInfo#r_flower.name,common_tool:to_list(_ReceName)]),
            Str2 = format_broadcasting(?_LANG_FLOWERS_DEFAULT_BROADCASTING,
                                       ["<font color=\"#FFC000\">"++common_tool:to_list(_ReceName)++"</font>",
                                        FlowersInfo#r_flower.name,
                                        "<font color=\"#FFC000\">"++common_tool:to_list(_ReceName)++"</font>"
                                       ]),
            {ok,BroadCastType,Str1,Str2}
    end;
get_broadcasting(false,FlowersInfo,_GiveName,_ReceName) ->
    random:seed(erlang:now()),
    case FlowersInfo#r_flower.broadcast_type of
        none ->
            {ok, none, ""};
        BroadCastType ->
            Nth = random:uniform(length(FlowersInfo#r_flower.broadcasting)),
            Broadcasting = lists:nth(Nth,FlowersInfo#r_flower.broadcasting),
            Str1 = format_broadcasting(Broadcasting,[common_tool:to_list(_GiveName),common_tool:to_list(_ReceName)]), 
            Str2 = format_broadcasting(Broadcasting,["<font color=\"#FFC000\">"++common_tool:to_list(_GiveName)++"</font>",
                                                     "<font color=\"#FFC000\">"++common_tool:to_list(_ReceName)++"</font>"]), 
            {ok,BroadCastType,Str1,Str2}
    end.


% broadcast(BroadcastType,BroadcastInfo,SelfRoleBase,ReceRoleBase)
free_broadcast_flower(RoleBase) ->
    RoleName = RoleBase#p_role_base.role_name,
    [FlowersInfo] = common_config_dyn:find(flowers,1),
    [Str|_] = FlowersInfo#r_flower.broadcasting,
    Str1 = format_broadcasting(
        Str,
        [common_tool:to_list(RoleName)]
    ),
    BroadcastInfo = #p_flowers_give_broadcast_info{
        giver = RoleName,
        receiver = RoleName,
        flowers_type = FlowersInfo#r_flower.type_id,
        broadcasting = Str1
    },
    broadcast(world,BroadcastInfo,RoleBase,RoleBase).

broadcast(world,BroadcastInfo,_GiveBase,_ReceBase) ->
    Data = #m_flowers_give_world_broadcast_toc{broadcast=BroadcastInfo},
    common_misc:chat_broadcast_to_world(?FLOWERS, ?FLOWERS_GIVE_WORLD_BROADCAST, Data);
broadcast(faction,BroadcastInfo,GiveBase,ReceBase) ->
    Data = #m_flowers_give_faction_broadcast_toc{broadcast=BroadcastInfo},
    common_misc:chat_broadcast_to_faction(ReceBase#p_role_base.faction_id,
                                          ?FLOWERS,?FLOWERS_GIVE_FACTION_BROADCAST, Data),
    case 
        GiveBase#p_role_base.faction_id =:= 
        ReceBase#p_role_base.faction_id 
    of
        true ->
            ignore;
        false ->
            RegName = common_misc:get_role_line_process_name( GiveBase#p_role_base.role_id ),
            Pid = global:whereis_name(RegName),
            common_misc:unicast2(Pid, ?DEFAULT_UNIQUE,?FLOWERS,?FLOWERS_GIVE_FACTION_BROADCAST, Data)
    end;
broadcast(map,BroadcastInfo,GiveBase,_ReceBase) ->
    Data = #m_flowers_give_map_broadcast_toc{broadcast=BroadcastInfo},
    RoleIDList = mod_map_actor:get_in_map_role(),
    NewRoleIDList = 
        case lists:member(GiveBase#p_role_base.role_id,RoleIDList) of
            false ->
                [GiveBase#p_role_base.role_id|RoleIDList];
            true ->
                RoleIDList
        end,
    mgeem_map:broadcast(NewRoleIDList,?DEFAULT_UNIQUE,?FLOWERS,?FLOWERS_GIVE_MAP_BROADCAST, Data).

format_broadcasting(Format,Data) ->
    lists:flatten(io_lib:format(Format,Data)).
        
get_give_score(RoleID) ->   
    case db:dirty_read(?DB_ROLE_GIVE_FLOWERS,RoleID) of
       [#r_give_flowers{score=Score}] ->
            {ok,Score};
        _ ->
            {ok,0}
    end.
                                                
    






