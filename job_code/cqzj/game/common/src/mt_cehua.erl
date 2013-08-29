%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     用于应付策划的一些临时需求
%%% @end
%%% Created : 2010-10-25
%%%-------------------------------------------------------------------
-module(mt_cehua).

%%
%% Include files
%%
%%
%% Include files
%%
 
-define( PRINTME(F,D),io:format(F, D) ).
-compile(export_all).
-include("common.hrl").
-include("common_server.hrl").
-include("letter.hrl").
%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%

reset_lv(RoleIdList) when is_list(RoleIdList)->
    lists:foreach(
      fun(RoleId)->
              case db:dirty_read(?DB_ROLE_ATTR,RoleId) of
                  [#p_role_attr{role_id=RoleId}=RoleAttr]->
                      RoleAttr2 = RoleAttr#p_role_attr{level=30},
                      db:dirty_write(?DB_ROLE_ATTR,RoleAttr2);
                  _ ->
                      ignore
              end
      end, RoleIdList).

%%统计4个小时没登陆的玩家的最后地图点的数据
gen_newer_map()->
    MapIdList = [11000],
    TimeGap = 4*3600,
    MaxLevel = 3,
    gen_goaway_map(MapIdList,TimeGap,MaxLevel).

%%统计地图流失率的数据
%%采用默认的地图点
gen_goaway_map()->
    MapIdList = [11000,11001,10260,11101,11102,11103,11105],
    TimeGap = 3*24*3600,
    MaxLevel = 26,
    gen_goaway_map(MapIdList,TimeGap,MaxLevel).

gen_goaway_map(MapIdList)->
    TimeGap = 3*24*3600,
    MaxLevel = 26,
    gen_goaway_map(MapIdList,TimeGap,MaxLevel).

gen_goaway_map(MapIdList,TimeGap,MaxLevel)->
    Now = common_tool:now(),
    LastGapTime = Now - TimeGap,
    
    MatchHead = #p_role_ext{role_id='$1', _='_',last_offline_time='$2'},
    Guard = [{'<','$2',LastGapTime}],
    AllRoleIDList = db:dirty_select(db_role_ext, [{MatchHead, Guard, ['$1']}]),
    ?ERROR_MSG("AllRoleIDList length=~w",[length(AllRoleIDList)] ),
    RoleIDList2 = lists:filter(fun(RoleID)->
                                   case db:dirty_read(db_role_attr,RoleID) of
                                       [#p_role_attr{level=RoleLevel}]->
                                           RoleLevel=<MaxLevel;
                                       _ ->
                                           false
                                   end
                               end, AllRoleIDList),
    ?ERROR_MSG("match length=~w",[length(RoleIDList2)] ),
    List2 = lists:foldl(fun(RoleID,AccIn)->
                            gen_goaway_map_2(RoleID,MapIdList,AccIn)
                        end, [], RoleIDList2),
    Tab = t_map_liushi,
    try
      case List2 of
          []->
              no_data;
          _ ->
              SQL = mod_mysql:get_esql_delete(Tab, [] ),
              {ok,_} = mod_mysql:delete(SQL),
              
              QueuesInsert = [[Level,MapID,Tx,Ty,N]||{{Level,MapID,Tx,Ty},N}<-List2],
              FieldNames = [level,map_id,tx,ty,num],
              mod_mysql:batch_insert(Tab, FieldNames, QueuesInsert, 3000)
      end
    catch
        _:Reason->
          ?ERROR_MSG("gen_goaway_map error,reason:~w  stack:~w",[Reason,erlang:get_stacktrace()])
    end.

gen_goaway_map_2(RoleID,MapIDList,AccIn)->
    case db:dirty_read(db_role_pos,RoleID) of
        [#p_role_pos{map_process_name=Name}]->
            case string:str(Name, "mgee_map_") of
                1->
                    MapID = erlang:list_to_integer( string:substr(Name, length("mgee_map_")+1) ),
                    gen_goaway_map_3(RoleID,MapID,MapIDList,AccIn);
                _ ->
                    AccIn
            end;
        _ ->
            AccIn
    end.
gen_goaway_map_3(RoleID,MapID,MapIDList,AccIn)->
    case lists:member(MapID, MapIDList) of
        true->
            case db:dirty_read(db_role_pos,RoleID) of
                [#p_role_pos{pos=#p_pos{tx=Tx,ty=Ty}}]-> 
                    [#p_role_attr{level=RoleLevel}] = db:dirty_read(db_role_attr,RoleID),
                    Key = {RoleLevel,MapID,Tx,Ty},
                    case lists:keyfind(Key, 1, AccIn) of
                        {Key,N}->
                            lists:keystore(Key, 1, AccIn, {Key,N+1});
                        _ ->
                            [{Key,1}|AccIn]
                    end;
                _ ->
                    AccIn
            end;
        _ ->
            AccIn
    end.

check_people_num()->
    MatchHead = #p_role_attr{role_id='$1', _='_',level='$2'},
    Guard = [{'>','$2',18}],
    RoleIDList = db:dirty_select(db_role_attr_p, [{MatchHead, Guard, ['$1']}]),
    RoleIDList1 = lists:filter(fun(RoleID)-> if_can_accept_system_letter(RoleID, common_tool:now()) end, RoleIDList),
%%     MatchHead1 = #p_role_ext{role_id='$1', _='_',last_login_time='$2'},
%%     Guard1 = [{'>','$2',common_tool:now()-30*24*60*60}],
%%     RoleIDList1 = db:dirty_select(db_role_ext, [{MatchHead1, Guard1, ['$1']}]),
%%      
%%     RoleIDList2 = lists:filter(fun(A)->lists:any(fun(B)->A=:=B end,RoleIDList) end,RoleIDList1),
    Length = length(RoleIDList1),
    ?ERROR_MSG("ssLength:~w~n",[Length]).

gen_send_horse()->
 MatchHead = #p_role_attr{role_id='$1', _='_',level='$2'},
    Guard = [{'>','$2',18}],
    RoleIDList = db:dirty_select(db_role_attr_p, [{MatchHead, Guard, ['$1']}]),
 
%%     MatchHead1 = #p_role_ext{role_id='$1', _='_',last_login_time='$2'},
%%     Guard1 = [{'>','$2',common_tool:now()-30*24*60*60}],
%%     RoleIDList1 = db:dirty_select(db_role_ext, [{MatchHead1, Guard1, ['$1']}]),
     
%%     RoleIDList2 = lists:filter(fun(A)->lists:any(fun(B)->A=:=B end,RoleIDList) end,RoleIDList1),
     
    Title="领取“西风瘦马”，体验不一样的风采",
    Content = "亲爱的玩家:\n      为让大家体验新坐骑的风采，特赠送18级以上的玩家每人一匹“西风瘦马”的奖励，请点击附件查收。\n      你的传奇，我的传奇，共铸我们的传奇！\n<p align=\"right\">《苍穹战纪》运营团队</p>",
    CreateInfo = #r_goods_create_info{bind=true, bag_id=0, position=undefined,type=3, type_id=30112157, start_time=0, end_time=0, num=1, color=1,quality=1,punch_num=0,
property=undefined,rate=0,result=0,result_list=[],interface_type=present,sub_quality = 1},  
    do_sys2common_letter(RoleIDList,Title,Content,CreateInfo).


%% 群发信件  不需要返回-------------------------
do_sys2common_letter(RoleIDList,Title,Text,Goods)->
    ?DEBUG("RoleIDList ~w~n",[RoleIDList]),
    Now = common_tool:now(),
    RoleIDList1 = lists:filter(fun(RoleID)-> if_can_accept_system_letter(RoleID, Now) end, RoleIDList),
    ?DEBUG("ROLEIDLIST1 ~w~n",[RoleIDList1]),
    %% 修改为分段发送
    %% 截取roleidlist 
    {SendTime,OutTime} = common_letter:get_effective_time(),
    %% 获取公共信件内容索引
    Text1 = case Text of
        {{_,_},_} ->Text;
        _-> common_letter:create_db_common_letter(SendTime,OutTime,Title,common_tool:to_binary(Text))
    end,  
    LetterDetail = #r_letter_detail{%%id,
                         send_time = SendTime,
                         out_time = OutTime,
                         %%send_id,
                         send_name = "系统",
                         goods_list=Goods,
                         type = ?TYPE_LETTER_SYSTEM,
                         state = ?LETTER_NOT_OPEN,
                         title = Title,
                         text = Text1},
    AllCount = length(RoleIDList1),
    %% 分段发送
    do_sys2common_letter_split(split,[],RoleIDList1,LetterDetail,Goods,AllCount).

%% 分段发送 ----------------------------------
do_sys2common_letter_split(split,[],RoleIDList,LetterDetail,Goods,AllCount)->
    FailList =
        lists:foldr(fun(RoleID,Acc)->
                        case do_sys2common_letter_single(RoleID,LetterDetail,Goods) of
                            {error,_ID,_Reason} -> 
                                [RoleID|Acc];
                            _->Acc
                        end
                        end, [], RoleIDList),
    ?ERROR_MSG("AllCount:~w~n",[AllCount]),
    ?ERROR_MSG("FailList2:~w~n",[FailList]).




%% 系统发送公共信件--------------------------
%% system to single in common
do_sys2common_letter_single(RoleID,LetterDetail,Goods) when is_record(Goods,r_goods_create_info)->
    case create_goods(RoleID,Goods) of
        {ok,GoodsListOld}->
            %%设置bagid为9999，表示后台赠送
            GoodsList = [ G#p_goods{id=1,bagposition=1,bagid=9999}||G<-GoodsListOld ],
            do_sys2common_letter_single(RoleID,LetterDetail,GoodsList);
        {error,Reason}->
            {error,Reason}
    end;
do_sys2common_letter_single(RoleID,LetterDetail,GoodsList) when is_list(GoodsList)->
    LetterDetail1 = LetterDetail#r_letter_detail{goods_list=GoodsList},
    RoleName = "",
    NewLetterDetail = insert_receiver_letterbox(RoleID,RoleName,LetterDetail1),
    PublicMsg = get_detail_toc_msg(NewLetterDetail),
    common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?LETTER, ?LETTER_SEND,PublicMsg),
    [ insert_item_log(RoleID,G)||G<-GoodsList ].

%% ---------写入公共信箱收件人信箱    
insert_receiver_letterbox(RoleID,RoleName,LetterDetail)->
    RolePublicLetter1 = case db:dirty_read(?DB_PUBLIC_LETTER,RoleID) of
        [RolePublicLetter] when is_record(RolePublicLetter,r_public_letter)->
            RolePublicLetter;
        _->common_letter:create_new_public_letter(RoleID,RoleName)
    end,
    Count = RolePublicLetter1#r_public_letter.count+1,
    NewLetterDetail = LetterDetail#r_letter_detail{id = Count},
    OldLetterDetailList = RolePublicLetter1#r_public_letter.letterbox,
    RolePublicLetter2 = RolePublicLetter1#r_public_letter{letterbox=[NewLetterDetail|OldLetterDetailList],
                                                          count = Count},
    db:dirty_write(?DB_PUBLIC_LETTER,RolePublicLetter2),
    NewLetterDetail.
%% -------获取detail信件toc格式
get_detail_toc_msg(LetterDetail)->
    SimpleLetter = change_detail_to_simple(LetterDetail),
    #m_letter_send_toc{
        succ = true,
        letter = SimpleLetter}.
change_detail_to_simple(LetterDetail)->
    State = LetterDetail#r_letter_detail.state,
    IHG = if LetterDetail#r_letter_detail.goods_list =:= [] ->
                 false;
             true ->
                 case State of 
                     ?LETTER_NOT_OPEN-> true;
                     ?LETTER_HAS_OPEN-> true;
                     ?LETTER_HAS_ACCEPT_GOODS-> false;
                     ?LETTER_REPLY-> false
                 end
          end,
    #p_letter_simple_info{
                          id   = LetterDetail#r_letter_detail.id,
                          sender = LetterDetail#r_letter_detail.send_name,
                          receiver = "",
                          title    = LetterDetail#r_letter_detail.title,       
                          send_time  = LetterDetail#r_letter_detail.send_time,   
                          type       = LetterDetail#r_letter_detail.type,     
                          state      = State,     
                          is_have_goods = IHG,
                          table = ?LETTER_PUBLIC  
                         }.

%% 写道具日志 log_with_level.
insert_item_log(RoleID,Goods)->
    case common_misc:get_dirty_role_attr(RoleID) of
        {ok, #p_role_attr{level=RoleLevel}} ->
            ok;
        {error,Reason}->
            ?ERROR_MSG("写道具日志时获取玩家级别失败!RoleID=~wReason=~w,Stack=~w",[RoleID,Reason,erlang:get_stacktrace()]),
            RoleLevel = 0
    end,
    common_item_logger:log_with_level(RoleID,RoleLevel,Goods,?LOG_ITEM_TYPE_GET_ADMIN).

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

%% @doc 检察是否可以接收系统信件
if_can_accept_system_letter(RoleID, Now) ->
    %% 超过14天不登陆，不接收系统信件
    case common_misc:get_dirty_role_ext(RoleID) of
        {ok, #p_role_ext{last_login_time=LastLoginTime}} ->
            case LastLoginTime of
                undefined->
                    false;
                _->
                    Now - LastLoginTime =< 14*24*3600
            end;
        _ ->
            false
    end.

%% 清零玩家副本的进入次数
clear_role_scene_war_fb_enter_times(RoleID) ->
    case db:transaction(
           fun() -> 
                   case db:read(?DB_SCENE_WAR_FB,RoleID) of
                       [] ->
                           {error, not_found_this_user};
                       [SceneFbRecord] ->
                           #r_scene_war_fb{fb_info = FbInfoList} = SceneFbRecord,
                           NewFbInfoList = lists:map(fun(Elem) -> Elem#r_scene_war_fb_info{times = 0} end, FbInfoList),
                           NewSceneFbRecord = SceneFbRecord#r_scene_war_fb{fb_info = NewFbInfoList},
                           db:write(?DB_SCENE_WAR_FB,NewSceneFbRecord,write)
                    end
           end) of
        {atomic, _} ->
            ok;
        {aborted, _Error} ->
            error
    end.

%% 重置昨日经验状态，清除某个玩家昨日经验记录标记
clear_exp_back_flag(RoleID) -> 
    Yesterday = common_time:add_days(date(), -1),
    case db:dirty_read(?DB_ROLE_ACTIVITY_TASK,RoleID) of
        [] ->
            ignore;
        [#r_role_activity_task{task_history=TaskHistory}=R1_Task] ->
            case lists:keyfind(Yesterday, #r_role_exp_back_info.finish_date, TaskHistory) of
                false ->
                    ignore;
                YesterdayTaskInfo -> 
                    if YesterdayTaskInfo#r_role_exp_back_info.flag =:= 1 ->
                           NewTaskList = lists:map(fun({ActivityId, DoneTime, _}) -> {ActivityId, DoneTime, 0} end, YesterdayTaskInfo#r_role_exp_back_info.task_list),
                           NewYesterdayTaskInfo = YesterdayTaskInfo#r_role_exp_back_info{flag=0, task_list=NewTaskList},
                           NewTaskHistory = lists:keystore(Yesterday, #r_role_exp_back_info.finish_date, TaskHistory, NewYesterdayTaskInfo),
                           R2_Task = R1_Task#r_role_activity_task{task_history=NewTaskHistory},
                           db:dirty_write(?DB_ROLE_ACTIVITY_TASK,R2_Task),
                           ok;
                       true ->
                           ignore
                    end
            end
    end.

%% 清除历史数据
clear_exp_back_history() ->
    TransFormer = 
        fun(R) ->
                case R of
                    {r_role_activity_task,ROLE_ID,ACT_TASK_LIST,_TASK_HISTORY} ->
                        {r_role_activity_task,ROLE_ID,ACT_TASK_LIST,[]};
                    _ ->
                        R
                end
        end,
    Fields = [role_id,act_task_list,task_history],
    {atomic, ok} = mnesia:transform_table(db_role_activity_task, TransFormer, Fields, r_role_activity_task),
    {atomic, ok} = mnesia:transform_table(db_role_activity_task_p, TransFormer, Fields, r_role_activity_task).

%%@doc 获取有重复物品ID的玩家列表（指定等级以上）
get_duplicated_goods_role(Level)->
    MatchHead = #p_role_attr{role_id='$1', level='$2', _='_'},
    Guard = [{'>','$2',Level}],
    AllRoleIDList = db:dirty_select(db_role_attr_p, [{MatchHead, Guard, ['$1']}]),
    [ RoleID||RoleID<-AllRoleIDList, check_duplicated_goods(RoleID) =:= true ].

%%@doc 检查改玩家是否有重复物品
check_duplicated_goods(RoleID)->
    case catch check_duplicated_goods_2(RoleID) of
        {error,RoleID,_}->
            true;
        _ ->
            false
    end.

check_duplicated_goods_2(RoleID)->
    GoodsIdList1 = lists:foldl(
                     fun(BagID,AccIn)->
                             case db:dirty_read(?DB_ROLE_BAG_P,{RoleID,BagID})of
                                 []->
                                     AccIn;
                                 [#r_role_bag{bag_goods=GoodsList}]->
                                     GoodsIdList= [Id||#p_goods{id=Id}<-GoodsList],
                                     case verify_goods_list(GoodsIdList,AccIn)of
                                         {ok,AccIn2}-> AccIn2;
                                         {error,BadGoodsId}-> throw({error,RoleID,BadGoodsId})
                                     end
                             end
                     end, [], [1,5,6,7,8,9]),
    case db:dirty_read(?DB_ROLE_ATTR_P,RoleID) of
        [#p_role_attr{equips=Equips}]->
            GoodsIdListE1= [Id||#p_goods{id=Id}<-Equips],
            case verify_goods_list(GoodsIdListE1, GoodsIdList1)of
                {ok,_GoodsIdList3}-> next;
                {error,BadGoodsId}-> 
                    throw({error,RoleID,BadGoodsId})
            end;
        []->
            next
    end,
    ok.

verify_goods_list([],AccIn)->
    {ok,AccIn};
verify_goods_list([H|T],AccIn)->
    case lists:member(H, AccIn) of
        true->
            {error,H};
        _ ->
            verify_goods_list(T,[H|AccIn])
    end.

is_goods_id_duplicated([],_)->
    false;
is_goods_id_duplicated([H|T],IdList)->
    case lists:member(H, IdList) of
        true-> true;
        _ ->
            is_goods_id_duplicated(T,[H|IdList])
    end.

