-module(common_shell).
-compile(export_all).

-export([
         update_rank/0,
         update_pet_bag/0,
         send_gift/0,
         send_gift/2,
         send_level_prize/2,
         send_exp_goods/1,
         fix_role_goods/1,
         fix_role_goods_offline/1,
         modify_all_role_goods/2,
         judge_role_bag_thing_error/1,
         check_error_bag_role/1,
         update_stone_config_handle/1,
         update_role_equips/2,
         map_exec_up_role_equip/0,
         update_p_goods_structure/0,
         update_p_goods_data_for_special/0,
         judge_role_bag_thing_error/2,
         send_gold_taozhuang/0,
		 delete_equip_whole_attr/0,
		 search_roles_by_typelist/2,
		 search_pet_by_typeid/1,
		 repair_pet_training_data/0,
		 check_dirty_account/0,
		 clean_dirty_account/0,
         t_pay_get_date/5]).

-export([get_liushi_family/0,
         set_all_fuli/0,
         get_liushi/0]).

-include("common.hrl").
-include("common_server.hrl").

%%@doc GM执行累计元宝消费的奖励
gm_stat_accgold_rewards()->
    case global:whereis_name( mgeew_accgold_server ) of
        undefined->
            {error,undefined};
        PID ->
            PID ! {gm_stat_rewards}
    end.


%%@doc 更新系统公告的内容
update_system_notice()->
    SQL = mod_mysql:get_esql_select(t_system_notice,[content],"where id=1 "), 
    case mod_mysql:select(SQL) of
        {ok,[[Content]]} ->
            db:dirty_write(?DB_SYSTEM_NOTICE_P, #r_system_notice{id=1, notice=Content}),
            lists:foreach(
              fun(PName) ->
                      global:send(PName,  {mod_system_notice, {update_notice, Content}})
              end, common_debugger:get_all_map_pid()),
            ok;
        Err ->
            Err
    end.


clear_badjingjie_roles()->
    AllRoles = db:dirty_match_object(?DB_ROLE_JINGJIE_RANK_P,#p_jingjie_rank{_ = '_'}),
    [ clear_badjingjie_roles_2(E) ||E<- AllRoles], 
    ok.

clear_badjingjie_roles_2(JingjieRank)->
    #p_jingjie_rank{role_id=RoleID,jingjie=Jingjie} = JingjieRank,
    case common_title:get_jingjie(Jingjie) of
        false->
            db:dirty_delete(?DB_ROLE_JINGJIE_RANK, RoleID),
            db:dirty_delete(?DB_ROLE_JINGJIE_RANK_P, RoleID);
        _ ->
            ignore
    end.


%%@doc 获取符合级别以及离线时间的人数
get_role_count(DLevel,DDays)->
    Now = common_tool:now(),
    RoleExtList = db:dirty_match_object(?DB_ROLE_EXT_P, #p_role_ext{_='_'}),
    RoleCount =
        lists:foldl(
          fun(#p_role_ext{role_id=RoleID, last_offline_time=LastOfflineTime}, Acc) ->
                  case Now-LastOfflineTime > DDays*24*3600  of
                      true->
                          case db:dirty_read(?DB_ROLE_ATTR_P, RoleID) of
                              [#p_role_attr{level=Level}] when Level =< DLevel->
                                  Acc+1;
                              _ ->
                                  Acc
                          end;
                      _ ->
                          Acc
                  end
          end, 0, RoleExtList),
    {ok, RoleCount}. 

%%赠送愚人节礼包
send_fools_gift()->
    Now = common_tool:now(),
    RoleExtList = db:dirty_match_object(?DB_ROLE_EXT, #p_role_ext{_='_'}),
    RoleIdList =
        lists:foldl(
          fun(#p_role_ext{role_id=RoleID, last_offline_time=LastOfflineTime}, Acc) ->
                  case LastOfflineTime >= Now orelse Now - LastOfflineTime =< 7*24*3600 of
                      true ->
                          case db:dirty_read(?DB_ROLE_ATTR, RoleID) of
                              [#p_role_attr{level=Level}] when Level>= 30->
                                  [RoleID|Acc];
                              _ ->
                                  Acc
                          end;
                      _ ->
                          Acc
                  end
          end, [], RoleExtList),
    ?ERROR_MSG("send_fools_gift, role_num=~w",[length(RoleIdList)]),
    
    Title = "愚人节，送礼啦！",
    Text = "亲爱的玩家：\n      4月1日愚人节快乐 o(∩_∩)o，在此佳节之际，希望大家不要整的太狠 (*^__^*) 。在今天更新后，玩家们第一时间就发现了“善意的玩笑”，希望各位玩家没有惊喜过度。\n      最后，当然是国际惯例，玩家们会发现，上午的惊喜刚刚平复。但下午的愚人节惊喜礼包又来了O(∩_∩)O~，请各位注意查收附件哦~\n\n<p align=\"right\">《苍穹战纪》运营团队</p><p align=\"right\">2012年04月01日</p>",
    send_fools_gift_2(RoleIdList,Title,Text),
    ok.

send_fools_gift_2(RoleIdList,Title,Text)->
    lists:foreach(
      fun(RoleID) ->
              TransFun = fun() ->
                                 CreateItem = #r_item_create_info{role_id=RoleID,num=1,typeid=11400055,bind=true,bag_id=1,bagposition=1},
                                 {ok,[GiftGoods]} = common_bag2:create_item(CreateItem),
                                 GiftGoods2 = GiftGoods#p_goods{id=1},
                                 common_letter:sys2p(RoleID,common_tool:to_binary(Text),Title,[GiftGoods2],14)
                         end,
              case db:transaction( TransFun ) of
                  {aborted, _} ->
                      error;
                  {atomic, ignore} ->
                      ignore;
                  {atomic, ok} ->
                      ok
              end         
      end,RoleIdList),
    ?ERROR_MSG("send_fools_gift, finished",[]),
    ok.

%%@doc 给所有三天内有登陆的玩家赠送所有福利
set_all_fuli()->
    Now = common_tool:now(),
    Last3Days = Now - 3*24*3600,
    MatchHead = #p_role_ext{role_id='$1', _='_',last_login_time='$2'},
    Guard = [{'>','$2',Last3Days}],
    AllRoleIDList = db:dirty_select(db_role_ext, [{MatchHead, Guard, ['$1']}]),
    Today = date(),
    BnftList =  [{10001,Today},{10003,Today},
                 {10004,Today},{10006,Today},{10007,Today},{10008,Today},
                 {20001,Today},{20002,Today},{20003,Today}],
    lists:foreach(fun(RoleID)-> 
                      R2 = #r_role_activity_benefit{role_id=RoleID,reward_date=undefined,
                                                    buy_date=Today,buy_count=9,act_bnft_list=BnftList},
                      db:dirty_write(db_role_activity_benefit,R2)
                  end, AllRoleIDList),
    {length(AllRoleIDList),AllRoleIDList}.


update_rank()->
    global:send(mgeew_ranking,update_all_rank).
                   


%%@doc 获取属于宗族地图流失的玩家列表
get_liushi_family()->
    Now = common_tool:now(),
    Last3Days = Now - 3*24*3600,
    
    MatchHead = #p_role_ext{role_id='$1', _='_',last_offline_time='$2'},
    Guard = [{'<','$2',Last3Days}],
    AllRoleIDList = db:dirty_select(db_role_ext, [{MatchHead, Guard, ['$1']}]),
    List2 = lists:filter(fun(RoleID)-> 
                     case db:dirty_read(db_role_pos,RoleID) of
                         [#p_role_pos{old_map_process_name=Name}]->
                             case string:str(Name, "map_family_") of
                                 1->
                                     case db:dirty_read(db_role_pos,RoleID) of
                                         [#p_role_pos{pos=#p_pos{tx=Tx,ty=Ty}}]->
                                             Tx<187+5 andalso Tx>187-5
                                     andalso Ty<177+5 andalso Ty>177-5;
                                         _ ->
                                             false
                                     end;
                                 _ ->
                                     false
                             end;
                         _ ->
                             false
                     end
                     end, AllRoleIDList),
    Count = length(List2),
    GroupByList = group_by_role_level(List2,[]),
    GroupByList2 = lists:sort(fun({_L1,N1},{_L2,N2})-> N2>N1 end, GroupByList),
    {Count,GroupByList2}.

get_liushi()->
    Now = common_tool:now(),
    Last3Days = Now - 3*24*3600,
    
    MatchHead = #p_role_ext{role_id='$1', _='_',last_offline_time='$2'},
    Guard = [{'<','$2',Last3Days}],
    AllRoleIDList = db:dirty_select(db_role_ext, [{MatchHead, Guard, ['$1']}]),
    List2 = lists:foldl(
              fun(RoleID, Acc)-> 
                      case db:dirty_read(db_role_pos,RoleID) of
                          [#p_role_pos{map_process_name=Name1,old_map_process_name=Name2}]->
                              case string:str(Name2, "map_family_") of
                                  1->
                                      case db:dirty_read(db_role_pos,RoleID) of
                                          [#p_role_pos{pos=#p_pos{tx=Tx,ty=Ty}}]->
                                              [{RoleID,Name2,Tx,Ty}|Acc];
                                          _ ->
                                              Acc
                                      end;
                                  _ ->
                                      case db:dirty_read(db_role_pos,RoleID) of
                                          [#p_role_pos{pos=#p_pos{tx=Tx,ty=Ty}}]->
                                              [{RoleID,Name1,Tx,Ty}|Acc];
                                          _ ->
                                              Acc
                                      end
                              end;
                          _ ->
                              Acc
                      end
              end,[], AllRoleIDList),
    Count = length(List2),
    GroupByList = group_by_role_level([RoleID || {RoleID,_,_,_} <- List2],[]),
    GroupByList2 = lists:sort(fun({_L1,N1},{_L2,N2})-> N2>N1 end, GroupByList),

    lists:foreach(fun({R,N,X,Y}) -> file:write_file("/data/liushi1.txt", io_lib:format("{~w ~w ~w ~w}.~n", [R,N,X,Y]), [append]) end, List2),  

    lists:foreach(fun(D) -> file:write_file("/data/liushi2.txt", io_lib:format("~w.~n", [D]), [append]) end, GroupByList2),  

    {Count,GroupByList2}.


group_by_role_level([],ResultList)->
    ResultList;
group_by_role_level([RoleID|T],ResultList)->
    [#p_role_attr{level=RoleLevel}] = db:dirty_read(db_role_attr,RoleID),
    case lists:keyfind(RoleLevel, 1, ResultList) of
        false->
            List2 = [{RoleLevel,1}|ResultList],
            group_by_role_level(T,List2);
        {RoleLevel,N}->
            List2 = lists:keystore(RoleLevel, 1, ResultList, {RoleLevel,N+1}),
            group_by_role_level(T,List2)
    end.


%% 20级以上，3天内有登陆的玩家发放补偿 2011-02-15
send_gift() ->
    {ok, LogHandle} = file:open("/root/log_2011_02_15.log", write),
    
    Now = common_tool:now(),
    RoleList =
        lists:foldl(
          fun(#p_role_ext{role_id=RoleID, last_offline_time=LastOfflineTime}, Acc) ->
                  case LastOfflineTime >= Now orelse Now - LastOfflineTime =< 3*24*3600 of
                      true ->
                          [#p_role_attr{level=Level}] = db:dirty_read(?DB_ROLE_ATTR, RoleID),

                          case Level >= 20 of
                              true ->
                                  [RoleID|Acc];
                              _ ->
                                  Acc
                          end;
                      _ ->
                          Acc
                  end
          end, [], db:dirty_match_object(?DB_ROLE_EXT, #p_role_ext{_='_'})),

    send_gift(LogHandle, RoleList),
    file:close(LogHandle).

%%发明1服17号以后注册账号，25日前40级以上玩家20锭银票
send_level_prize(MinLevel,MaxLevel) ->
      {ok,SSS} = file:open("/log2.txt",write),
    lists:foreach(
      fun(Level) ->
              List = db:dirty_match_object(db_role_attr,#p_role_attr{level=Level,_='_'}),
              List2 = lists:foldr(
                        fun(RoleAttr,Acc) ->
                                RoleID = RoleAttr#p_role_attr.role_id,
                                case RoleID < 35343 of
                                    true ->
                                        [RoleID|Acc];
                                    false ->
                                        Acc
                                end
                        end, [], List),
               io:format(SSS,"$$$$$$$$$ ~w    ~w~n",[List, List2]),
              send_gift(SSS,List2)
      end, lists:seq(MinLevel,MaxLevel)).


send_gold_taozhuang()->
    RoleList = [
{2,5300},
{16,160343},
{41,43246},
{143,26920},
{150,14969},
{155,11250},
{170,9625},
{172,1270},
{194,19140},
{210,2045},
{268,83866},
{273,2100},
{282,10},
{286,735},
{313,143565},
{339,70},
{345,6560},
{352,1388},
{355,0},
{356,7282},
{357,5288},
{358,0},
{359,100},
{360,3000},
{364,10000},
{366,5115},
{368,17158},
{369,60}
],
   send_gold(RoleList).

send_gold(RoleList)->
    lists:foreach(
      fun({RoleID,AddGold}) ->
              case db:transaction(
                     fun() ->
                             case db:dirty_read(db_role_attr_p,RoleID) of
                                 [#p_role_attr{gold=Gold1}=RoleAttr1] ->
                                     Gold2 = Gold1 + AddGold,
                                     RoleAttr2 = RoleAttr1#p_role_attr{gold=Gold2},
                                     db:dirty_write(db_role_attr,RoleAttr2),
                                     db:dirty_write(db_role_attr_p,RoleAttr2),
                                     Title = "系统信件",
                                     Text = "亲爱的玩家:\n      您好！您获得系统赠送的",
                                     Text2 = "元宝，请注意查收！祝您游戏愉快，万事如意！\n\n<p align=\"right\">《苍穹战纪》运营团队</p><p align=\"right\">2012年02月20日</p>",
                                     Text3 = lists:concat([Text,AddGold,Text2]),
                                     common_letter:sys2p(RoleID,erlang:list_to_binary( Text3 ),Title,[],14),
                                     ok;
                                 _ ->
                                     ignore
                             end
                     end)
              of
                  {aborted, Reason} ->
                      ?DBG("send error,RoleID1=~w,Reason=~p",[RoleID,Reason]);
                  {atomic, ignore} ->
                      ?DBG("send ignore,RoleID=~w",[RoleID]);
                  {atomic, ok} ->
                      ?DBG("ok,RoleID=~w,AddGold=~w",[RoleID,AddGold]),
                      ok
              end         
      end,RoleList).

send_gift(SSS,RoleIDList) ->
    lists:foreach(
      fun(RoleID) ->
              case db:transaction(
                     fun() ->
                             [AttrInfo] = db:dirty_read(db_role_attr,RoleID),
                             CItem = #r_item_create_info{role_id=RoleID,num=2,typeid=10100004,bind=true,bag_id=1,bagposition=1},
                             {ok,[TGoods]} = common_bag2:create_item(CItem),
                             Title = "系统信件",
                             Text = "亲爱的玩家:\n      您好！对于本次临时维护给您正常游戏带来不便，我们深感抱歉。为表示歉意，对此我们决定给予20级以上、最近三天内有登陆过游戏的玩家，每人两张高级经验符作为补偿，请注意查收！祝您游戏愉快，万事如意！\n\n<p align=\"right\">4399《苍穹战纪》运营团队</p><p align=\"right\">2011年02月15日</p>",
                             receive_letter(RoleID,AttrInfo#p_role_attr.role_name,Title,Text,[TGoods#p_goods{id=1}])
                     end)
              of
                  {aborted, _} ->
                      io:format(SSS," ~w~n",[RoleID]);
                  {atomic, ignore} ->
                      io:format(SSS," ~w~n",[RoleID]);
                  {atomic, ok} ->
                      ok
              end         
      end,RoleIDList).

receive_letter(RoleID,RoleName,Title,Text,GoodsList) ->
    Now = common_tool:now(),
    Letter = #r_letter_info{sender = "系统", 
                            receiver = RoleName, 
                            title = Title,
                            send_time = Now,
                            out_time = 14*86400+Now,
                            type = 2,
                            goods_list = GoodsList, 
                            text = Text},
    case db:read(letter_receiver, RoleID) of
        [] ->
            NewBox = #r_letter_receiver{role_id = RoleID,letter = [Letter#r_letter_info{id=1}],count=1},
            db:write(letter_receiver, NewBox, write),
            toc_letter(RoleID,Letter#r_letter_info{id=1}),
            ok;
        [ReceBox] -> 
            #r_letter_receiver{letter = OldLetter,count=Count} = ReceBox,
            NewBox = ReceBox#r_letter_receiver{letter = [Letter#r_letter_info{id=Count+1}|OldLetter],count=Count+1},
            db:write(letter_receiver, NewBox, write),
            toc_letter(RoleID,Letter#r_letter_info{id=Count+1}),
            ok;
        _ ->
            ignore
    end.

toc_letter(RoleID,RLetter) ->
    IHG = (not (RLetter#r_letter_info.goods_list =:= [])),
    Letter = #p_letter_simple_info{id   = RLetter#r_letter_info.id,
                                   sender   = RLetter#r_letter_info.sender,
                                   title    = RLetter#r_letter_info.title,       
                                   send_time  = RLetter#r_letter_info.send_time,   
                                   type       = RLetter#r_letter_info.type,     
                                   state      = RLetter#r_letter_info.state,     
                                   is_have_goods = IHG},
    Toc = #m_letter_send_toc{succ = true, letter = Letter},
    common_misc:unicast({role,RoleID}, 0, 21, 2111,Toc).

%% 统计玩家充值总元宝数
stat_role_total_pay_gold(RoleID) ->
	MatchHead = #r_pay_log{_='_',role_id = RoleID,pay_gold='$1'},
	PayGoldList=
		case db:dirty_select(?DB_PAY_LOG,[{MatchHead, [], ['$1']}]) of
			GoldList when is_list(GoldList) ->
				GoldList;
			_ -> []
		end,
	lists:sum(PayGoldList).

role_total_pay_gold(RoleID) ->
	MatchHead = #r_pay_log{_='_',role_id = RoleID,pay_gold='$1'},
	PayGoldList=
		case db:dirty_select(?DB_PAY_LOG_P,[{MatchHead, [], ['$1']}]) of
			GoldList when is_list(GoldList) ->
				GoldList;
			_ -> []
		end,
	lists:sum(PayGoldList).


send_exp_goods(List) ->
    {ok,SSS} = file:open("/log_exp_goods.txt",write),
    lists:foreach(
      fun({RoleID,A,B,C}) ->
              case db:transaction(
                     fun() ->
                             [AttrInfo] = db:dirty_read(db_role_attr,RoleID),
                             case A > 0 of
                                 true ->
                                     CItem = #r_item_create_info{role_id=RoleID,num=A,typeid=10100002,bind=true,bag_id=1,bagposition=1},
                                     {ok,[TGoods]} = common_bag2:create_item(CItem),
                                     Title = "经验符补偿",
                                     Text = io_lib:format("亲爱的玩家:\n         您好，由于经验符的持续时间和价格调整，根据您原有的经验符数量，现给您补偿等量的\"初级经验符\”~w张，请您查收附件。祝您游戏愉快！\n                                     4399《苍穹战纪》 ",[A]),
                                     receive_letter(RoleID,AttrInfo#p_role_attr.role_name,Title,Text,[TGoods#p_goods{id=1}]);
                                 false ->
                                     ignore
                             end,
                             case B > 0 of
                                 true ->
                                     CItem2 = #r_item_create_info{role_id=RoleID,num=B,typeid=10100003,bind=true,bag_id=1,bagposition=1},
                                     {ok,[TGoods2]} = common_bag2:create_item(CItem2),
                                     Title2 = "经验符补偿",
                                     Text2 = io_lib:format("亲爱的玩家:\n         您好，由于经验符的持续时间和价格调整，根据您原有的经验符数量，现给您补偿等量的\"中级经验符\”~w张，请您查收附件。祝您游戏愉快！\n                                     4399《苍穹战纪》 ",[B]),
                                     receive_letter(RoleID,AttrInfo#p_role_attr.role_name,Title2,Text2,[TGoods2#p_goods{id=1}]);
                                 false ->
                                     ignore
                             end,
                              case C > 0 of
                                 true ->
                                     CItem3 = #r_item_create_info{role_id=RoleID,num=C,typeid=10100004,bind=true,bag_id=1,bagposition=1},
                                     {ok,[TGoods3]} = common_bag2:create_item(CItem3),
                                     Title3 = "经验符补偿",
                                     Text3 = io_lib:format("亲爱的玩家:\n         您好，由于经验符的持续时间和价格调整，根据您原有的经验符数量，现给您补偿等量的\"高级经验符\”~w张，请您查收附件。祝您游戏愉快！\n                                     4399《苍穹战纪》 ",[C]),
                                     receive_letter(RoleID,AttrInfo#p_role_attr.role_name,Title3,Text3,[TGoods3#p_goods{id=1}]);
                                 false ->
                                     ignore
                             end
                     end)
                  of
                  {aborted, _} ->
                      io:format(SSS," ~w~n",[RoleID]);
                  {atomic, _} ->
                      ok
              end
      end,List).

%%离线整理
fix_role_goods_offline(RoleID) ->
    %%身上装备
    [Attr] = db:dirty_read(?DB_ROLE_ATTR_P,RoleID),
    case Attr#p_role_attr.equips of
        undefined ->
            ID1 = 1;
        EquipList ->
            {NewEquipList,ID1} = get_new_goods_list_and_id(EquipList,1),
            db:dirty_write(?DB_ROLE_ATTR_P,Attr#p_role_attr{equips=NewEquipList})
    end,
    %%背包、仓库、法宝空间
    ID3 = lists:foldl(
            fun(BagID,Acc) ->
                    case db:dirty_read(?DB_ROLE_BAG_P,{RoleID,BagID}) of
                        [] ->
                            Acc;
                        [Info] ->
                            OldGoodsList = Info#r_role_bag.bag_goods,
                            {NewGoodsList,Acc3} = get_new_goods_list_and_id(OldGoodsList,Acc),
                            db:dirty_write(?DB_ROLE_BAG_P,Info#r_role_bag{bag_goods=NewGoodsList}),
                            Acc3
                    end
            end,ID1,[1,2,3,5,6,7,8,9]),
    
    %%摆摊
    StallList = db:dirty_match_object(?DB_STALL_GOODS,#r_stall_goods{_='_', role_id=RoleID}),
    {NewStallList,_} = lists:foldl(
                         fun(Stall,{AccList,AccId4})->
                                 #r_stall_goods{goods_detail=GoodInfo} = Stall,
                                 NewGoodInfo = GoodInfo#p_goods{id=AccId4},
                                 NewStall = Stall#r_stall_goods{id={RoleID,AccId4},goods_detail=NewGoodInfo},
                                 
                                 db:dirty_delete(?DB_STALL_GOODS,Stall#r_stall_goods.id),
                                 {[NewStall|AccList],AccId4+1}
                         end, {[],ID3}, StallList),
    [ db:dirty_write(?DB_STALL_GOODS,Stall2) ||Stall2<-NewStallList ],
    ok.

get_new_goods_list_and_id(OldGoodsList,AccId) when is_integer(AccId)->
    lists:foldl(
      fun(GoodsInfo,{AccGoodsList,Acc2}) ->
              {[GoodsInfo#p_goods{id=Acc2}|AccGoodsList],Acc2+1}
      end, {[],AccId}, OldGoodsList).


%%@doc 整理玩家背包异常数据
fix_role_goods(RoleID) ->
    ?ERROR_MSG("fix_role_goods,RoleID=~w",[RoleID]),
    case db:transaction( fun()->  t_fix_role_goods(RoleID) end ) of
        {atomic,_} ->
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("fix_role_goods err,Err=~w",[Error]),
            {error,Error}
    end.

t_fix_role_goods(RoleID) ->
    %%身上装备
    [Attr] = db:read(?DB_ROLE_ATTR,RoleID,write),
    case Attr#p_role_attr.equips of
        undefined ->
            ID1 = 1;
        EquipList ->
            {NewEquipList,ID1} = get_new_goods_list_and_id(EquipList,1),
            db:write(?DB_ROLE_ATTR,Attr#p_role_attr{equips=NewEquipList},write)
    end,
    
    %%背包、仓库、法宝空间
    ID3 = lists:foldl(
            fun(BagID,Acc) ->
                    case db:read(?DB_ROLE_BAG_P,{RoleID,BagID},write) of
                        [] ->
                            Acc;
                        [Info] ->
                            OldGoodsList = Info#r_role_bag.bag_goods,
                            {NewGoodsList,Acc3} = get_new_goods_list_and_id(OldGoodsList,Acc),
                            db:write(?DB_ROLE_BAG_P,Info#r_role_bag{bag_goods=NewGoodsList},write),
                            Acc3
                    end
            end,ID1,[1,2,3,5,6,7,8,9]),
    %%摆摊
    StallList = db:match_object(?DB_STALL_GOODS,#r_stall_goods{_='_', role_id=RoleID},write),
    {NewStallList,_} = lists:foldl(
                         fun(Stall,{AccList,AccId4})->
                                 #r_stall_goods{goods_detail=GoodInfo} = Stall,
                                 NewGoodInfo = GoodInfo#p_goods{id=AccId4},
                                 NewStall = Stall#r_stall_goods{id={RoleID,AccId4},goods_detail=NewGoodInfo},
                                 
                                 db:delete(?DB_STALL_GOODS,Stall#r_stall_goods.id,write),
                                 {[NewStall|AccList],AccId4+1}
                         end, {[],ID3}, StallList),
    [ db:write(?DB_STALL_GOODS,Stall2,write) ||Stall2<-NewStallList ],
    ok.


modify_all_role_goods(MinLevel,MaxLevel) ->
    lists:foreach(
      fun(Level) ->
              RoleList = db:dirty_match_object(db_role_attr,#p_role_attr{_='_',level=Level}),
              lists:foreach(
                fun(RoleAttr) ->
                        RoleID = RoleAttr#p_role_attr.role_id,
                        RoleLineName = common_misc:get_role_line_process_name(RoleID),
                        case global:whereis_name(RoleLineName) of
                            undefined ->
                                common_shell:fix_role_goods(RoleID);
                            _Pid ->
                               ignore
                        end,
                        timer:sleep(1)
                end, RoleList)
      end,lists:seq(MinLevel,MaxLevel)).



judge_role_bag_thing_error(RoleID) ->
    erlang:erase(),
    [Attr] = db:dirty_read(db_role_attr,RoleID),
    case Attr#p_role_attr.equips of
        undefined ->
            ignore;
        EquipList ->
            lists:foreach(
              fun(Equip) ->
                      case get(Equip#p_goods.id) of
                          undefined ->
                              put(Equip#p_goods.id,true);
                          _ ->
                              throw(error)
                      end
              end,EquipList)
    end,
    lists:foreach(
      fun(BagID) ->
              case db:dirty_read(db_role_bag,{RoleID,BagID}) of
                  [] ->
                      ignore;
                  [Info] ->
                      lists:foreach(
                        fun(GoodsInfo) ->
                                case get(GoodsInfo#p_goods.id) of
                                    undefined ->
                                        put(GoodsInfo#p_goods.id,true);
                                    _ ->
                                        throw(error)
                                end
                        end, Info#r_role_bag.bag_goods)
              end
      end,[1,2,3,5,6,7,8,9]),
    StallList = db:dirty_match_object(?DB_STALL_GOODS,#r_stall_goods{_='_', role_id=RoleID}),
    lists:foreach(
      fun(Stall) ->
              StallInfo = Stall#r_stall_goods.goods_detail,
              case get(StallInfo#p_goods.id) of
                  undefined ->
                      put(StallInfo#p_goods.id,true);
                  _ ->
                      throw(error)
              end
      end,StallList),
    ok.

judge_role_bag_thing_error(RoleID,Attr) ->
    erlang:erase(),
    case Attr#p_role_attr.equips of
        undefined ->
            ignore;
        EquipList ->
            lists:foreach(
              fun(Equip) ->
                      case get(Equip#p_goods.id) of
                          undefined ->
                              put(Equip#p_goods.id,true);
                          _ ->
                              throw(error)
                      end
              end,EquipList)
    end,
    lists:foreach(
      fun(BagID) ->
              case db:dirty_read(db_role_bag,{RoleID,BagID}) of
                  [] ->
                      ignore;
                  [Info] ->
                      lists:foreach(
                        fun(GoodsInfo) ->
                                case get(GoodsInfo#p_goods.id) of
                                    undefined ->
                                        put(GoodsInfo#p_goods.id,true);
                                    _ ->
                                        throw(error)
                                end
                        end, Info#r_role_bag.bag_goods)
              end
      end,[1,2,3,5,6,7,8,9]),
    StallList = db:dirty_match_object(?DB_STALL_GOODS,#r_stall_goods{_='_', role_id=RoleID}),
    lists:foreach(
      fun(Stall) ->
              StallInfo = Stall#r_stall_goods.goods_detail,
              case get(StallInfo#p_goods.id) of
                  undefined ->
                      put(StallInfo#p_goods.id,true);
                  _ ->
                      throw(error)
              end
      end,StallList),
    ok.


check_error_bag_role(CheckList) ->
    Fun = fun(RoleID) ->
                  erase(),
                  BagList = [1,2,3,5,6,7,8,9],
                  lists:foreach(
                    fun(BagID) ->
                            case db:dirty_read(db_role_bag,{RoleID,BagID}) of
                                [] ->
                                    ignore;
                                [BagInfo] ->
                                    GoodsList = BagInfo#r_role_bag.bag_goods,
                                    lists:foreach(
                                      fun(GoodsInfo) ->
                                              TypeID = GoodsInfo#p_goods.typeid,
                                              case lists:keyfind(TypeID, 1, CheckList) of
                                                  false ->
                                                      ignore;
                                                  {TypeID,MaxNum} ->
                                                      Num = GoodsInfo#p_goods.current_num,
                                                      case get(TypeID) of
                                                          undefined ->
                                                              NewNum = Num;
                                                          OldNum ->
                                                              NewNum = OldNum + Num
                                                      end,
                                                      case NewNum >= MaxNum of
                                                          true ->
                                                              throw(role_bag_error);
                                                          false ->
                                                              put(TypeID,NewNum)
                                                      end
                                              end
                                      end,GoodsList)
                            end
                    end,BagList)
          end,
    RoleList = db:dirty_match_object(db_role_ext,#p_role_ext{_='_'}),
    lists:foldl(
      fun(RoleExt,Acc) ->
              timer:sleep(1),
              RoleID = RoleExt#p_role_ext.role_id,
              OffTime = RoleExt#p_role_ext.last_offline_time,
              case OffTime > 1292486400 of
                  true ->
                      case catch Fun(RoleID) of
                          role_bag_error ->
                              [RoleID|Acc];
                          _ ->
                              Acc
                      end;
                  false ->
                      Acc
              end
      end,[],RoleList).
              
                  
update_pet_bag() ->
    List = db:dirty_match_object(?DB_ROLE_PET_BAG_P,#p_role_pet_bag{_='_'}),
    lists:foreach(
      fun(BagInfo) ->
              #p_role_pet_bag{pets=Pets} = BagInfo,
              NewPets = lists:foldr(
                fun({p_pet_id_name,PetID,PetName},Acc) ->
                        case db:dirty_read(?DB_PET_P,PetID) of
                            [] ->
                                Acc;
                            [#p_pet{color=Color}] ->
                                [#p_pet_id_name{pet_id=PetID,name=PetName,color=Color}|Acc]
                        end
                end,[],Pets),
              db:dirty_write(?DB_ROLE_PET_BAG_P,BagInfo#p_role_pet_bag{pets=NewPets})
      end,List).
                                
update_stone_config_handle(OldStoneConfigPath) ->              
    {ok, TmpStoneConfig} = file:consult(OldStoneConfigPath),
    TmpKeyValues = [{erlang:element(2, Config),Config} || Config <- TmpStoneConfig],
    common_config_dyn:load_gen_src(tmp_stone, TmpKeyValues),
    %%背包
    List1 = db:dirty_match_object(db_role_bag_p, #r_role_bag{_='_'}),
    lists:foreach(
      fun(#r_role_bag{bag_goods=GL}=R) ->
              NGL=lists:map(fun(Goods) -> up_has_stone_equip(Goods) end, GL),
              db:dirty_write(db_role_bag_p, R#r_role_bag{bag_goods=NGL})
      end,List1),
    %%种族背包
    List2 = db:dirty_match_object(db_family_depot, #r_family_depot{_='_'}),
    lists:foreach(
      fun(#r_family_depot{bag_goods=GL}=R) ->
              NGL=lists:map(fun(Goods) -> up_has_stone_equip(Goods) end, GL),
              db:dirty_write(db_family_depot, R#r_family_depot{bag_goods=NGL})
      end,List2),
    %%摆摊
    List3 = db:dirty_match_object(db_stall_goods, #r_stall_goods{_='_'}),
    lists:foreach(
      fun(#r_stall_goods{goods_detail=Goods}=R) ->
              NewGoods = up_has_stone_equip(Goods),
              db:dirty_write(db_stall_goods, R#r_stall_goods{goods_detail=NewGoods})
      end,List3),
    List4 = db:dirty_match_object(db_stall_goods_tmp, #r_stall_goods{_='_'}),
    lists:foreach(
      fun(#r_stall_goods{goods_detail=Goods}=R) ->
              NewGoods = up_has_stone_equip(Goods),
              db:dirty_write(db_stall_goods_tmp, R#r_stall_goods{goods_detail=NewGoods})
      end,List4),
    %%收件箱
    List5 = db:dirty_match_object(letter_receiver, #r_letter_receiver{_='_'}),
    lists:foreach(
      fun(#r_letter_receiver{letter=LS}=R) ->
              NLS = lists:map(
                      fun(#r_letter_info{goods_list=GL}=Ler) ->
                              NGL = lists:map(fun(Goods) -> up_has_stone_equip(Goods) end, GL),
                              Ler#r_letter_info{goods_list=NGL}
                      end,LS),
              db:dirty_write(letter_receiver, R#r_letter_receiver{letter=NLS})
      end,List5),
    %%角色身上的装备
    List6 = db:dirty_match_object(db_role_attr, #p_role_attr{_='_'}),
    lists:foreach(
      fun(#p_role_attr{equips=GL}=R) ->
              NGL=lists:map(fun(Goods) -> up_has_stone_equip(Goods) end, GL),
              db:dirty_write(db_role_attr, R#p_role_attr{equips=NGL})
      end,List6),
    %%
    %%
    %%
    code:purge(tmp_stone_config_codegen).
    
up_has_stone_equip(#p_goods{type=?TYPE_EQUIP,stones=[_|_]}=Goods) ->
    Goods1 = 
        lists:foldl(
          fun(Stone, Equip) ->
                  case common_config_dyn:find(tmp_stone, Stone#p_goods.typeid) of
                      [] ->
                          io:format(user,"bad old stone type id:~w~n",[Stone#p_goods.typeid]),
                          Equip;
                      [BaseInfo] ->
                          BasePro = BaseInfo#p_stone_base_info.level_prop,
                          Pro = Equip#p_goods.add_property,
                          SeatList =
                              case get_main_property_seat(BasePro#p_property_add.main_property) of
                                  SeatR when is_integer(SeatR) andalso SeatR > 1 ->
                                      [SeatR];
                                  SeatR when is_list(SeatR) ->
                                      SeatR;
                                  _ ->
                                      []
                              end,
                          NewPro = lists:foldl(
                                     fun(Seat,AccPro) ->
                                             R = erlang:element(Seat, AccPro)-erlang:element(Seat,BasePro),
                                             erlang:setelement(Seat, AccPro, R)
                                     end,Pro,SeatList),
                          Equip#p_goods{add_property = NewPro}
                  end
          end,Goods,Goods#p_goods.stones),
    Goods2 = 
         lists:foldl(
          fun(Stone, Equip) ->
                  case common_config_dyn:find(stone, Stone#p_goods.typeid) of
                      [] ->
                          io:format(user,"bad new stone type id:~w~n",[Stone#p_goods.typeid]),
                          Equip;
                      [BaseInfo] ->
                          BasePro = BaseInfo#p_stone_base_info.level_prop,
                          Pro = Equip#p_goods.add_property,
                          SeatList =
                              case get_main_property_seat(BasePro#p_property_add.main_property) of
                                  SeatR when is_integer(SeatR) andalso SeatR > 1 ->
                                      [SeatR];
                                  SeatR when is_list(SeatR) ->
                                      SeatR;
                                  _ ->
                                      []
                              end,
                          NewPro = lists:foldl(
                                     fun(Seat,AccPro) ->
                                             R = erlang:element(Seat, AccPro)+erlang:element(Seat,BasePro),
                                             erlang:setelement(Seat, AccPro, R)
                                     end,Pro,SeatList),
                          Equip#p_goods{add_property = NewPro}
                  end
          end,Goods1,Goods#p_goods.stones),
    Goods2;
up_has_stone_equip(Goods) ->
    Goods.


get_main_property_seat(Main) ->
    [List]= common_config_dyn:find(refining,main_property),
    proplists:get_value(Main, List).

update_role_equips(OldConfigPath, RoleIDs) ->
    {ok, TmpStoneConfig} = file:consult(OldConfigPath),
    TmpKeyValues = [{erlang:element(2, Config),Config} || Config <- TmpStoneConfig],
    common_config_dyn:load_gen_src(tmp_stone, TmpKeyValues),
    L1 = lists:foldl(
           fun(RoleID, Acc) ->
                   case db:dirty_read(db_role_attr,RoleID) of
                       [RoleAttr] ->
                           [RoleAttr|Acc];
                       _ ->
                           Acc
                   end
           end,[], RoleIDs),
    lists:foreach(
      fun(#p_role_attr{equips=GL}=R) ->
              NGL=lists:map(fun(Goods) -> up_has_stone_equip(Goods) end, GL),
              db:dirty_write(db_role_attr, R#p_role_attr{equips=NGL})
      end,L1),
    code:purge(tmp_stone_config_codegen).

map_exec_up_role_equip() ->
    %%背包
    List1 = db:dirty_match_object(db_role_bag_p, #r_role_bag{_='_'}),
    lists:foreach(
      fun(#r_role_bag{bag_goods=GL}=R) ->
              NGL=lists:map(fun(Goods) -> up_equip(Goods) end, GL),
              db:dirty_write(db_role_bag_p, R#r_role_bag{bag_goods=NGL})
      end,List1),
    %%宗族仓库
    List2 = db:dirty_match_object(db_family_depot, #r_family_depot{_='_'}),
    lists:foreach(
      fun(#r_family_depot{bag_goods=GL}=R) ->
              NGL=lists:map(fun(Goods) -> up_equip(Goods) end, GL),
              db:dirty_write(db_family_depot, R#r_family_depot{bag_goods=NGL})
      end,List2),
    %%摆摊
    List3 = db:dirty_match_object(db_stall_goods, #r_stall_goods{_='_'}),
    lists:foreach(
      fun(#r_stall_goods{goods_detail=Goods}=R) ->
              NewGoods = up_equip(Goods),
              ?DEBUG("Stall:~w ~w ~n",[NewGoods,Goods]),
              db:dirty_write(db_stall_goods, R#r_stall_goods{goods_detail=NewGoods})
      end,List3),
    List4 = db:dirty_match_object(db_stall_goods_tmp, #r_stall_goods{_='_'}),
    lists:foreach(
      fun(#r_stall_goods{goods_detail=Goods}=R) ->
              NewGoods = up_equip(Goods),
              db:dirty_write(db_stall_goods_tmp, R#r_stall_goods{goods_detail=NewGoods})
      end,List4),
    %%信件
    List5 = db:dirty_match_object(db_personal_letter_p, #r_personal_letter{_='_'}),
    lists:foreach(
      fun(#r_personal_letter{goods_list=GL}=R) ->
              NGL = lists:map(fun(Goods) -> up_equip(Goods) end, GL),
              db:dirty_write(db_personal_letter_p, R#r_personal_letter{goods_list=NGL})
      end,List5),
    List6 = db:dirty_match_object(db_public_letter_p, #r_letter_detail{_='_'}),
    lists:foreach(
      fun(#r_letter_detail{goods_list=GL}=R) ->
              NGL = lists:map(fun(Goods) -> up_equip(Goods) end, GL),
              db:dirty_write(db_public_letter_p, R#r_letter_detail{goods_list=NGL})
      end,List6),
    %%角色身上的装备
    List7 = db:dirty_match_object(db_role_attr, #p_role_attr{_='_'}),
    lists:foreach(
      fun(#p_role_attr{equips=GL}=R) ->
              NGL=lists:map(fun(Goods) -> up_equip(Goods) end, GL),
              db:dirty_write(db_role_attr, R#p_role_attr{equips=NGL})
      end,List7),
    %%
    %%
    %%
    code:purge(tmp_stone_config_codegen).

up_equip(#p_goods{type=?TYPE_EQUIP, typeid=TypeID}=Goods) ->
    [#p_equip_base_info{property=Pro}=NewEquipInfo] = common_config_dyn:find_equip(TypeID),
    SubQuality = 
        if Goods#p_goods.quality > 1 ->
                2;
           true ->
                0
        end,
    NewEquipGoods = Goods#p_goods{add_property=Pro,sub_quality = SubQuality},
    %% 新装备处理
    %% 颜色品质处理
    NewGoods = mod_refining:equip_colour_quality_add(new,NewEquipGoods,1,1,1),
    %% 强化处理
    NewGoods2 = equip_reinforce_property_add(NewGoods,NewEquipInfo),
    %% 宝石处理
    NewGoods3 = 
        if NewGoods2#p_goods.stones =/= undefined ->
                equip_stone_property_add(NewGoods2);
           true ->
                NewGoods2
        end,
    %% 绑定处理
    NewGoods4 = mod_refining_bind:do_equip_bind_for_equip_upgrade(NewGoods3,NewEquipInfo),
    ?DEBUG("~ts,EquipOld=~w,EquipNew=~w",["装备升级前后绑定属性处理结果",NewGoods3,NewGoods4]),
    %% 装备五行属性
    %% 材料绑定处理
    NewGoods5 =
        if NewGoods4#p_goods.bind ->
                case mod_refining_bind:do_equip_bind_for_upgrade(NewGoods4) of 
                    {error,BindErrorCode} ->
                        ?INFO_MSG("~ts,BindErrorCode",["装备升级时，当材料是绑定的，装备是不绑定时，处理绑定出错，只是做绑定处理，没有附加属性",BindErrorCode]),
                        NewGoods4#p_goods{bind=true};
                    {ok,BindGoods} ->
                        BindGoods
                end;
           true ->
                NewGoods4
        end,
    %% 精炼系数处理
    NewGoods6 = case common_misc:do_calculate_equip_refining_index(NewGoods5) of
                    {error,ErrorCode} ->
                        ?DEBUG("~ts,ErrorCode=~w",["计算装备精炼系数出错",ErrorCode]),
                        NewGoods5;
                    {ok,RefiningIndexGoods} ->
                        RefiningIndexGoods
                end,
    NewGoods6;
up_equip(Goods) ->
    Goods.

%% 装备强化属性处理
equip_reinforce_property_add(EquipGoods,EquipBaseInfo) ->
    EquipPro = EquipGoods#p_goods.add_property,
    BasePro = EquipBaseInfo#p_equip_base_info.property,
    MainProperty = BasePro#p_property_add.main_property,
    ReinforceRate = EquipGoods#p_goods.reinforce_rate,
    NewEquipPro=mod_refining:change_main_property(MainProperty,EquipPro,BasePro,0,ReinforceRate),
    EquipGoods#p_goods{add_property = NewEquipPro}.
%% 宝石加成处理
equip_stone_property_add(EquipGoods) ->
    Stones = EquipGoods#p_goods.stones,
    equip_stone_property_add2(Stones,EquipGoods).
equip_stone_property_add2([],EquipGoods) ->
    EquipGoods;
equip_stone_property_add2([H|T],EquipGoods) ->
    StoneTypeId = H#p_goods.typeid,
    {ok,StoneBaseInfo} = mod_stone:get_stone_baseinfo(StoneTypeId),
    NewEquipGoods = equip_stone_property_add3(StoneBaseInfo,EquipGoods),
    equip_stone_property_add2(T,NewEquipGoods).

equip_stone_property_add3(StoneBaseInfo,EquipGoods) ->
    EquipPro = EquipGoods#p_goods.add_property,
    StoneBasePro = StoneBaseInfo#p_stone_base_info.level_prop,
    SeatList =
        case equip_stone_property_add4(StoneBasePro#p_property_add.main_property) of
            SeatR when is_integer(SeatR) andalso SeatR > 1 ->
                [SeatR];
            SeatR when is_list(SeatR) ->
                SeatR;
            _ ->
                ?INFO_MSG("~ts,EquipGoods=~w,StoneBaseInfo=~w",["装备升级时，处理宝石数据遇到不可处理的宝石数据",EquipGoods,StoneBaseInfo]),
                []
        end,
    NewEquipPro = lists:foldl(
                    fun(Seat,AccPro) ->
                            Value = erlang:element(Seat, AccPro) + erlang:element(Seat,StoneBasePro),
                            erlang:setelement(Seat, AccPro, Value)
                    end,EquipPro,SeatList),
    EquipGoods#p_goods{add_property = NewEquipPro}.
equip_stone_property_add4(Main) ->
    [List] = common_config_dyn:find(refining,main_property),
    proplists:get_value(Main, List).

%% p_goods结构变化，需要处理的数据
%% 执行此函数时，必须确认游戏没有玩家的情况下执行
%% 此脚本可以运行多次
update_p_goods_structure() ->
    %%背包
    List1 = db:dirty_match_object(db_role_bag_p, #r_role_bag{_='_'}),
    lists:foreach(
      fun(#r_role_bag{bag_goods=GL}=R) ->
              NGL=lists:map(fun(Goods) -> up_p_goods_structure(Goods) end, GL),
              db:dirty_write(db_role_bag_p, R#r_role_bag{bag_goods=NGL})
      end,List1),
    %%宗族仓库
    List2 = db:dirty_match_object(db_family_depot, #r_family_depot{_='_'}),
    lists:foreach(
      fun(#r_family_depot{bag_goods=GL}=R) ->
              NGL=lists:map(fun(Goods) -> up_p_goods_structure(Goods) end, GL),
              db:dirty_write(db_family_depot, R#r_family_depot{bag_goods=NGL})
      end,List2),
    %%摆摊
    List3 = db:dirty_match_object(db_stall_goods, #r_stall_goods{_='_'}),
    lists:foreach(
      fun(#r_stall_goods{goods_detail=Goods}=R) ->
              NewGoods = up_p_goods_structure(Goods),
              db:dirty_write(db_stall_goods, R#r_stall_goods{goods_detail=NewGoods})
      end,List3),
    List4 = db:dirty_match_object(db_stall_goods_tmp, #r_stall_goods{_='_'}),
    lists:foreach(
      fun(#r_stall_goods{goods_detail=Goods}=R) ->
              NewGoods = up_p_goods_structure(Goods),
              db:dirty_write(db_stall_goods_tmp, R#r_stall_goods{goods_detail=NewGoods})
      end,List4),
    %%信件
    List5 = db:dirty_match_object(db_personal_letter_p, #r_personal_letter{_='_'}),
    lists:foreach(
      fun(#r_personal_letter{goods_list=GL}=R) ->
              NGL = lists:map(fun(Goods) -> up_p_goods_structure(Goods) end, GL),
              db:dirty_write(db_personal_letter_p, R#r_personal_letter{goods_list=NGL})
      end,List5),
    List6 = db:dirty_match_object(db_public_letter_p, #r_public_letter{_='_'}),
    lists:foreach(
      fun(#r_public_letter{letterbox=GL}=R) ->
              NGL = 
                  lists:map(
                    fun(#r_letter_detail{goods_list = GoodsList} = RR) -> 
                            GoodsList2 = lists:map(fun(Goods) -> up_p_goods_structure(Goods) end, GoodsList),
                            RR#r_letter_detail{goods_list = GoodsList2}
                    end,GL),
              db:dirty_write(db_public_letter_p, R#r_public_letter{letterbox=NGL})
      end,List6),
    %%角色身上的装备
    List7 = db:dirty_match_object(db_role_attr_p, #p_role_attr{_='_'}),
    lists:foreach(
      fun(#p_role_attr{equips=GL}=R) ->
              NGL=lists:map(fun(Goods) -> up_p_goods_structure(Goods) end, GL),
              db:dirty_write(db_role_attr, R#p_role_attr{equips=NGL})
      end,List7),
    %% 玩家奖励道具
    List8 = db:dirty_match_object(db_role_gift, #r_role_gift{_='_'}),
    lists:foreach(
      fun(#r_role_gift{gifts = Gifts}=R) ->
              case lists:keyfind(1,#r_role_gift_info.gift_type,Gifts) of
                  false ->
                      ignore;
                  #r_role_gift_info{cur_gift = GiftGoodsList} = GiftInfo ->
                      GiftGoodsList2 = lists:map(fun(Goods) -> up_p_goods_structure(Goods) end, GiftGoodsList),
                      GiftInfo2=GiftInfo#r_role_gift_info{cur_gift = GiftGoodsList2},
                      Gifts2 = lists:keydelete(1,#r_role_gift_info.gift_type,Gifts),
                      db:dirty_write(db_role_gift, R#r_role_gift{gifts = [GiftInfo2|Gifts2]})
              end
      end,List8),
    ok.
up_p_goods_structure(Goods) ->
    case  erlang:is_record(Goods,p_goods) of 
        true ->
            if Goods#p_goods.type =:= 3 ->
                    QualityRate = get_p_goods_quality_rate(Goods#p_goods.quality),
                    Goods#p_goods{sub_quality = 2,quality_rate = QualityRate};
               true ->
                    Goods
            end;
        false ->
            {p_goods,Id,Type,Roleid,Bagposition,Current_num,Bagid,Sell_type,Sell_price,Typeid,Bind,Start_time,End_time,Current_colour,
             State,Name,Level,Embe_pos,Embe_equipid,Loadposition,Quality,Current_endurance,Forge_num,Reinforce_result,Punch_num,
             Stone_num,Add_property,Stones,Reinforce_rate,Endurance,Signature,Equip_bind_attr,Refining_index,Sign_role_id,Five_ele_attr,
             Whole_attr,Reinforce_result_list,Use_bind} = Goods,
            if Type =:= 3 -> %% 装备镶嵌的宝石处理
                    Stones2 = 
                        case Stones of
                            undefined ->
                                [];
                            [] ->
                                [];
                            _ ->
                                lists:map(fun(StoneGoods) -> up_p_goods_structure2(StoneGoods) end,Stones)
                        end,
                    QualityRate2 = get_p_goods_quality_rate(Quality),
                    SubQuality2 = 2,
                    ok;
               true ->
                    SubQuality2 = 0,
                    QualityRate2 = 0,
                    Stones2 = Stones
            end,
            {p_goods,Id,Type,Roleid,Bagposition,Current_num,Bagid,Sell_type,Sell_price,Typeid,Bind,Start_time,End_time,Current_colour,
             State,Name,Level,Embe_pos,Embe_equipid,Loadposition,Quality,Current_endurance,Forge_num,Reinforce_result,Punch_num,
             Stone_num,Add_property,Stones2,Reinforce_rate,Endurance,Signature,Equip_bind_attr,Refining_index,Sign_role_id,Five_ele_attr,
             Whole_attr,Reinforce_result_list,Use_bind,SubQuality2,QualityRate2}
    end.
up_p_goods_structure2(Goods) ->
    case  erlang:is_record(Goods,p_goods) of 
        true ->
            Goods;
        false ->
            {p_goods,Id,Type,Roleid,Bagposition,Current_num,Bagid,Sell_type,Sell_price,Typeid,Bind,Start_time,End_time,Current_colour,
             State,Name,Level,Embe_pos,Embe_equipid,Loadposition,Quality,Current_endurance,Forge_num,Reinforce_result,Punch_num,
             Stone_num,Add_property,Stones,Reinforce_rate,Endurance,Signature,Equip_bind_attr,Refining_index,Sign_role_id,Five_ele_attr,
             Whole_attr,Reinforce_result_list,Use_bind} = Goods,
            {p_goods,Id,Type,Roleid,Bagposition,Current_num,Bagid,Sell_type,Sell_price,Typeid,Bind,Start_time,End_time,Current_colour,
             State,Name,Level,Embe_pos,Embe_equipid,Loadposition,Quality,Current_endurance,Forge_num,Reinforce_result,Punch_num,
             Stone_num,Add_property,Stones,Reinforce_rate,Endurance,Signature,Equip_bind_attr,Refining_index,Sign_role_id,Five_ele_attr,
             Whole_attr,Reinforce_result_list,Use_bind,0,0}
    end.
get_p_goods_quality_rate(Quality) ->
    case Quality of 
        1 ->
            0;
        2 ->
            10;
        3 ->
            20;
        4 ->
            30;
        5 ->
            40;
        _ ->
            0
    end.
%% 处理坐骑，时装的品质数据问题
update_p_goods_data_for_special() ->
    %%背包
    List1 = db:dirty_match_object(db_role_bag_p, #r_role_bag{_='_'}),
    lists:foreach(
      fun(#r_role_bag{bag_goods=GL}=R) ->
              NGL=lists:map(fun(Goods) -> up_p_goods_data_special(Goods) end, GL),
              db:dirty_write(db_role_bag_p, R#r_role_bag{bag_goods=NGL})
      end,List1),
    %%宗族仓库
    List2 = db:dirty_match_object(db_family_depot, #r_family_depot{_='_'}),
    lists:foreach(
      fun(#r_family_depot{bag_goods=GL}=R) ->
              NGL=lists:map(fun(Goods) -> up_p_goods_data_special(Goods) end, GL),
              db:dirty_write(db_family_depot, R#r_family_depot{bag_goods=NGL})
      end,List2),
    %%摆摊
    List3 = db:dirty_match_object(db_stall_goods, #r_stall_goods{_='_'}),
    lists:foreach(
      fun(#r_stall_goods{goods_detail=Goods}=R) ->
              NewGoods = up_p_goods_data_special(Goods),
              db:dirty_write(db_stall_goods, R#r_stall_goods{goods_detail=NewGoods})
      end,List3),
    List4 = db:dirty_match_object(db_stall_goods_tmp, #r_stall_goods{_='_'}),
    lists:foreach(
      fun(#r_stall_goods{goods_detail=Goods}=R) ->
              NewGoods = up_p_goods_data_special(Goods),
              db:dirty_write(db_stall_goods_tmp, R#r_stall_goods{goods_detail=NewGoods})
      end,List4),
    %%信件
    List5 = db:dirty_match_object(db_personal_letter_p, #r_personal_letter{_='_'}),
    lists:foreach(
      fun(#r_personal_letter{goods_list=GL}=R) ->
              NGL = lists:map(fun(Goods) -> up_p_goods_data_special(Goods) end, GL),
              db:dirty_write(db_personal_letter_p, R#r_personal_letter{goods_list=NGL})
      end,List5),
    List6 = db:dirty_match_object(db_public_letter_p, #r_public_letter{_='_'}),
    lists:foreach(
      fun(#r_public_letter{letterbox=GL}=R) ->
              NGL = 
                  lists:map(
                    fun(#r_letter_detail{goods_list = GoodsList} = RR) -> 
                            GoodsList2 = lists:map(fun(Goods) -> up_p_goods_data_special(Goods) end, GoodsList),
                            RR#r_letter_detail{goods_list = GoodsList2}
                    end,GL),
              db:dirty_write(db_public_letter_p, R#r_public_letter{letterbox=NGL})
      end,List6),
    %%角色身上的装备
    List7 = db:dirty_match_object(db_role_attr_p, #p_role_attr{_='_'}),
    lists:foreach(
      fun(#p_role_attr{equips=GL}=R) ->
              NGL=lists:map(fun(Goods) -> up_p_goods_data_special(Goods) end, GL),
              db:dirty_write(db_role_attr, R#p_role_attr{equips=NGL})
      end,List7),
    %% 玩家奖励道具
    List8 = db:dirty_match_object(db_role_gift, #r_role_gift{_='_'}),
    lists:foreach(
      fun(#r_role_gift{gifts = Gifts}=R) ->
              case lists:keyfind(1,#r_role_gift_info.gift_type,Gifts) of
                  false ->
                      ignore;
                  #r_role_gift_info{cur_gift = GiftGoodsList} = GiftInfo ->
                      GiftGoodsList2 = lists:map(fun(Goods) -> up_p_goods_data_special(Goods) end, GiftGoodsList),
                      GiftInfo2=GiftInfo#r_role_gift_info{cur_gift = GiftGoodsList2},
                      Gifts2 = lists:keydelete(1,#r_role_gift_info.gift_type,Gifts),
                      db:dirty_write(db_role_gift, R#r_role_gift{gifts = [GiftInfo2|Gifts2]})
              end
      end,List8),
    ok.
up_p_goods_data_special(Goods) ->
    case Goods#p_goods.type =:= ?TYPE_EQUIP of
        true ->
            [GoodsBaseInfo] = common_config_dyn:find_equip(Goods#p_goods.typeid),
            case (GoodsBaseInfo#p_equip_base_info.slot_num =:= 11 
                  orelse GoodsBaseInfo#p_equip_base_info.slot_num =:= 12) of
                true ->
                    Goods#p_goods{quality = 0,sub_quality = 0,quality_rate = 0};
                _ ->
                    Goods
            end;
        _ ->
            Goods
    end.



t_pay_get_date(OrderID, AccountName, PayTime, PayGold, PayMoney)->
     {{Y,M,D},{H,_,_}} = common_tool:seconds_to_datetime(PayTime),
      t_do_pay(OrderID, AccountName, PayTime, PayGold, PayMoney, {Y, M, D, H}, false).


t_do_pay(OrderID, AccountName, PayTime, PayGold, PayMoney, {Year, Month, Day, Hour},IsFirst) ->
    %%判断是否该订单已经处理过
    case mnesia:match_object(db_pay_log, #r_pay_log{order_id=OrderID, _='_'}, write) of
        [] ->
            case mnesia:match_object(db_role_base_p, #p_role_base{account_name=AccountName, _='_'}, write) of
                [] ->
                    mnesia:abort("error,no role");
                [RoleBase] ->                    
                    t_do_pay2(OrderID, AccountName, RoleBase, PayTime, PayGold, PayMoney, {Year, Month, Day, Hour},IsFirst)
            end;
        _ ->
            mnesia:abort("this order is done")
    end.
t_do_pay2(OrderID, AccountName, RoleBase, PayTime, PayGold, PayMoney, {Year, Month, Day, Hour},IsFirst) ->
    #p_role_base{role_id=RoleID, role_name=RoleName} = RoleBase,
    [#p_role_attr{level=RoleLevel}] = db:read(db_role_attr_p, RoleID),
    [#r_pay_log_index{value=ID}] = db:read(db_pay_log_index, 1),
    %%记录日志
    %%给对应的玩家添加元宝，发信件通知玩家
    RLog = #r_pay_log{id=ID+1,order_id=OrderID, role_id=RoleID, role_name=RoleName,
                      account_name=AccountName, pay_time=PayTime, pay_gold=PayGold,
                      pay_money=PayMoney, year=Year, month=Month, day=Day, hour=Hour, is_first=IsFirst,role_level=RoleLevel},
    t_do_pay_not_first(RLog, 1 + ID).
        
%% 不满足首充
t_do_pay_not_first(RLog, NewID) ->
    mnesia:write(db_pay_log, RLog, write),
    mnesia:write(db_pay_log_index, #r_pay_log_index{id=1, value=NewID}, write),
    ok.

%% 删除套装属性(已经不需要)
delete_equip_whole_attr() ->
	common_up_db_goods:delete_equip_whole_attr(),
	DelBuffList = [20014,20015,20016,20017,20018],
	AllRole = db:dirty_match_object(db_role_base_p,#p_role_base{_ = '_'}),
	lists:foreach(fun(#p_role_base{buffs=Buffs}=RoleBase) ->
						  case Buffs of
							  [] ->
								  nil;
							  _ ->
								  NewBuffs =
									  lists:filter(fun(#p_actor_buf{buff_id=BuffID}) ->
														   not lists:member(BuffID, DelBuffList)
												   end, Buffs),
								  db:dirty_write(db_role_base,RoleBase#p_role_base{buffs=NewBuffs}),
								  db:dirty_write(db_role_base_p,RoleBase#p_role_base{buffs=NewBuffs})
						  end
				  end,AllRole).

%% 查询拥有某类异兽 的所有玩家
search_pet_by_typeid(TypeID) ->
	MatchHead = #p_pet{type_id='$1', _='_', pet_id='$2'},
	Guard = [{'=:=','$1',TypeID}],
	AllPetList = db:dirty_select(db_pet, [{MatchHead, Guard, ['$2']}]),
	?ERROR_MSG("~w",[AllPetList]).

%% 修复异兽训练数据
repair_pet_training_data() ->
    AllPetTraining = db:dirty_match_object(?DB_PET_TRAINING_P,#r_pet_training{_='_'}),
	lists:foreach(fun(#r_pet_training{role_id=RoleID,pet_training_list=PetTrainingList}=PetTraining)->
						  case erlang:is_list(PetTrainingList) =:= true andalso erlang:length(PetTrainingList)>0 of
							  true ->
								  NewPetTrainingList = 
									  lists:filter(fun(#r_pet_training_detail{pet_id=CheckPetID})->
														is_role_pet(RoleID,CheckPetID)
												end,PetTrainingList),
								  case NewPetTrainingList =/= PetTrainingList of
									  true ->
										  db:dirty_write(?DB_PET_TRAINING_P,PetTraining#r_pet_training{pet_training_list=NewPetTrainingList});
									  false ->
										  ignore
								  end;
							  false ->
								  ignore
						  end
				  end, AllPetTraining).
is_role_pet(RoleID,PetID) ->
	case db:dirty_read(?DB_PET_P,PetID) of
		[] ->
			false;
		[#p_pet{role_id=PetRoleID}] ->
			PetRoleID =:= RoleID
	end.
	
%% 根据异兽资质重新计算异兽颜色
%% 修复异兽下一等级经验错误问题
recalc_pet_color_and_next_exp() ->
	List = db:dirty_match_object(?DB_PET_P,#p_pet{_='_'}),
	lists:foreach(fun(#p_pet{level=Level,next_level_exp=NextLevelExp} = PetInfo)->
                            LevelExpInfo = cfg_pet_level:level_info(Level),
						  NextLevelExpCnf = LevelExpInfo#pet_level.next_level_exp,
						  NewPetInfo = 
							  case NextLevelExpCnf =:= NextLevelExp of
								  true ->
									  PetInfo;
								  false ->
									  PetInfo#p_pet{next_level_exp=NextLevelExpCnf}
							  end,
						  NewPetInfo2 = NewPetInfo,
						  case NewPetInfo2 =:= PetInfo of
							  true ->
								  ignore;
							  false ->
								  db:dirty_write(?DB_PET_P,NewPetInfo2)
						  end
				  end,List).

%% 检查冗余账号数据
check_dirty_account() ->
    AllAccount = db:dirty_match_object(?DB_ACCOUNT_P,#r_account{_='_'}),
    lists:foreach(fun(#r_account{account_name=AccountName}) ->
                          StrAccountName = binary_to_list(AccountName),
                          LOWER_ACCOUNT_NAME = list_to_binary( string:to_lower( StrAccountName ) ),
                          case db:dirty_match_object(?DB_ROLE_BASE_P,#p_role_base{_='_',account_name=LOWER_ACCOUNT_NAME}) of
                              [] ->
                                  ?ERROR_MSG("dirty_account:~p",[AccountName]);
                              _ ->
                                  nil
                          end
                  end, AllAccount).

%% 清理冗余账号数据
clean_dirty_account() ->
	AllAccount = db:dirty_match_object(?DB_ACCOUNT_P,#r_account{_='_'}),
	lists:foreach(fun(#r_account{account_name=AccountName}) ->
						  case db:dirty_match_object(?DB_ROLE_BASE_P,#p_role_base{_='_',account_name=common_tool:to_binary(AccountName)}) of
							  [] ->
								  ?ERROR_MSG("delete dirty_account:~w",[AccountName]),
								  db:dirty_delete(?DB_ACCOUNT,AccountName),
								  db:dirty_delete(?DB_ACCOUNT_P,AccountName);
							  _ ->
								  nil
						  end
				  end, AllAccount).

%% 查找拥有某类道具/装备的玩家
search_roles_by_typelist(SearchFunc,Args) ->
	List1 = db:dirty_match_object(db_role_bag_p, #r_role_bag{_='_'}),
	HitRoles1 = 
		lists:foldl(
		  fun(#r_role_bag{role_bag_key={RoleID,_},bag_goods=GoodList},Acc1) ->
				  case SearchFunc(GoodList,Args) of
					  true ->
						  [RoleID|Acc1];
					  false ->
						  Acc1
				  end
		  end,[],List1),
	List2 = db:dirty_match_object(db_stall_goods_p, #r_stall_goods{_='_'}),
	List3 = db:dirty_match_object(db_stall_goods_tmp_p, #r_stall_goods{_='_'}),
	HitRoles2 = 
		lists:foldl(
		  fun(#r_stall_goods{role_id=RoleID,goods_detail=Goods},Acc1) ->
				  case SearchFunc(Goods,Args) of
					  true ->
						  [RoleID|Acc1];
					  false ->
						  Acc1
				  end
		  end,[],lists:append(List2,List3)),
	List4 = db:dirty_match_object(db_role_attr_p, #p_role_attr{_='_'}),
	HitRoles3 = 
		lists:foldl(
		  fun(#p_role_attr{role_id=RoleID,equips=GoodList},Acc1) ->
				  case SearchFunc(GoodList,Args) of
					  true ->
						  [RoleID|Acc1];
					  false ->
						  Acc1
				  end
		  end,[],List4),
	List5 = db:dirty_match_object(db_role_box_p, #r_role_box{_='_'}),
	HitRoles4 = 
		lists:foldl(
		  fun(#r_role_box{role_id=RoleID,all_list=GoodList},Acc1) ->
				  case SearchFunc(GoodList,Args) of
					  true ->
						  [RoleID|Acc1];
					  false ->
						  Acc1
				  end
		  end,[],List5),
	AllHitRoles = lists:usort(lists:flatten([HitRoles1++HitRoles2++HitRoles3++HitRoles4])),
	%%?ERROR_MSG("args:~w,roles:~w",[Args,AllHitRoles]),
	AllHitRoles.

%% 重算百强榜(目前只合服的时候用)
reset_role_jingjie_rank(IsMerge) ->
	List1 = db:dirty_match_object(db_role_attr_p,#p_role_attr{_ = '_'}),
	List2 = lists:sort(fun(E1,E2) -> common_tool:cmp([{E2#p_role_attr.jingjie,E1#p_role_attr.jingjie}]) end,List1),
	List3 = lists:sublist(List2,100),
	List4 = lists:map(fun(E) ->
							  #p_role_attr{role_id=RoleID,role_name=RoleName,level=Level,jingjie=Jingjie} = E,  
							  [#p_role_base{faction_id=FactionID}] = db:dirty_read(db_role_base_p,RoleID),
							  ArenaScore = get_role_arena_score(RoleID),
							  #p_jingjie_rank{role_id=RoleID,jingjie=Jingjie,role_name=RoleName,level=Level,
											  faction_id=FactionID,arena_score=ArenaScore}
					  end,List3),
	List5 = 
		lists:sort(fun(E1,E2) ->
						   #p_jingjie_rank{role_id=RoleID1,jingjie=Jingjie1,level=Level1,arena_score=ArenaScore1} = E1,
						   #p_jingjie_rank{role_id=RoleID2,jingjie=Jingjie2,level=Level2,arena_score=ArenaScore2} = E2,
						   common_tool:cmp([{Jingjie1,Jingjie2},{ArenaScore1,ArenaScore2},{Level2,Level1},{RoleID2,RoleID1}])
				   end, List4),
	{_,List6} = lists:foldl(
				  fun(RoleRank,{Rank,Acc})->
						  {Rank-1,[RoleRank#p_jingjie_rank{ranking = Rank}|Acc]}
				  end,{length(List5),[]},List5),
	lists:foreach(fun(RoleRank) ->
						  case IsMerge of
							  false ->
								  db:dirty_write(db_role_jingjie_rank,RoleRank);
							  true ->
								  nil
						  end,
						  db:dirty_write(db_role_jingjie_rank_p,RoleRank)
				  end,List6).
get_role_arena_score(RoleID) ->
	case db:dirty_read(db_role_arena_p,RoleID) of
		[] ->
			100;
		[RoleArena] ->
			RoleArena#r_role_arena.total_score
	end.

reward_5_6() ->
	Pid = global:whereis_name(mgeew_special_activity),
	Pid ! reward_5_6,
	ok.
reward_date() ->
	Pid = global:whereis_name(mgeew_special_activity),
	Pid ! reward_date,
	ok.
end_crown_arena_activity() ->
	common_activity:notfiy_activity_end({10013, 1}),
	common_activity:notfiy_activity_end({10013, 2}),
	common_activity:notfiy_activity_end({10013, 3}).

load_login_table() ->
	db_loader:init_login_tables(),
    db_loader:load_login_whole_tables().

%% 查看合服几个主要表的数据长度
check_merge_data() ->
	?ERROR_MSG("table db_role_base_p count:~w",[erlang:length(mt_mnesia:show_table(db_role_base_p))]),
	?ERROR_MSG("table db_role_attr_p count:~w",[erlang:length(mt_mnesia:show_table(db_role_attr_p))]),
	?ERROR_MSG("table db_role_bag_p  count:~w",[erlang:length(mt_mnesia:show_table(db_role_bag_p))]).
	
test() ->
	lists:foreach(fun(Num) ->
						ChannelInfo = #p_channel_info{channel_sign=Num,channel_type=Num,channel_name=Num,online_num=1,total_num=1},
						supervisor:start_child(mgeec_channel_sup, [ChannelInfo])
						  end, lists:seq(1000, 2000000)).
	