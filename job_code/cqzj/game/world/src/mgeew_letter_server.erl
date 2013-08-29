%%% -------------------------------------------------------------------
%%% @Author  : markycai <caisiqiang@gmail.com>
%%% @doc   信件模块
%%% @end
%%% Created : 2011-3-23
%%% -------------------------------------------------------------------
-module(mgeew_letter_server).
 
-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("mgeew.hrl"). 
-include("letter_template.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start/0,start_link/0]). 

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([broadcast_sys_letter/1]).

%% ====================================================================
%% Macro
%% ====================================================================
-define(ACCEPT_GOODS_REQ_KEY(),{accept_goods_request_queue,RoleID,LetterID}).
-define(ACCEPT_REQ_OVER_TIME,30). %%30秒才延迟


%% ==================================================================== 
%% External functions
%% ====================================================================

start()->
    {ok,_} = supervisor:start_child(mgeew_sup,{?MODULE,
                                               {?MODULE,start_link,[]},
                                               permanent,infinity,supervisor,
                                               [?MODULE]}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

 
%%@doc 广播系统信件  
%% text 一般是信件原始内容
broadcast_sys_letter({Title,RoleIDList,Text,GoodsList}) ->
    case global:whereis_name(mgeew_letter_server) of
        undefined -> 
            {error,?_LANG_SYSTEM_ERROR};
        Pid ->
            erlang:send(Pid,{send,Title,RoleIDList,Text,GoodsList})
    end.

%% ====================================================================
%% Server functions
%% ====================================================================

init([]) ->
    erlang:process_flag(trap_exit,true),
    {ok,[]}.


handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Request, State) ->
    {noreply,  State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info,State),
    {noreply, State}.

terminate(Reason, State) ->
    {stop,Reason, State}.

code_change(_Request,_Code,_State)->
    ok.


%% ====================================================================
%%% Internal functions
%% ====================================================================
%% ================玩家信件=========================
%%发送私人信件到地图处理数据 
do_handle_info({_, _, ?LETTER_P2P_SEND, _, RoleID, _, _}=Msg) ->
   ?SEND_TO_MAP_LETTER(RoleID,send_p2p,Msg);

%%发送宗族信件 地图去处理
do_handle_info({_, _, ?LETTER_FAMILY_SEND, _, RoleID, _, _}=Msg)->
    ?SEND_TO_MAP_LETTER(RoleID,send_family_letter,Msg);

%% 获取全部信件，登录时推送
do_handle_info({_, _, ?LETTER_GET, _, _, _, _}=Msg) ->
    do_get_all_letter(Msg);

%%打开信件 
do_handle_info({_, _, ?LETTER_OPEN, _, _, _, _}=Msg) ->
    do_open_letter(Msg);

%%获取物品
do_handle_info({_, _, ?LETTER_ACCEPT_GOODS, _, _, _, _}=Msg) ->
    do_letter_accept_goods(Msg);

%%删除信件
do_handle_info({_, _, ?LETTER_DELETE, _, _, _, _}=Msg) ->
    do_delete_letter(Msg);

%% ====================从地图处理后返回 =================================
%%宗族信件在这边写入
do_handle_info({map_send_family_letter,Text,RoleID,RoleName,FamilyName,MembersList})->
    do_send_family_letter(Text,RoleID,RoleName,FamilyName,MembersList);

%%返回私人信件数据在这边写入
do_handle_info({map_send_p2p,SendID,RecvID,Text,GoodsList})->
    do_send_p2p(SendID,RecvID,Text,GoodsList);

%%返回获取物品
%%数据库数据字段修改
%%清楚进程字典
do_handle_info({map_accept_goods,Info})->
    do_map_accept_goods(Info);

%% =========================系统信件=================================
%%发送系统信件
do_handle_info({send_sys2p,RoleID,Title,Text,GoodsList,Days, StartTime}) -> 
    do_send_sys2p_letter(RoleID, Title, Text, GoodsList, Days, StartTime);
%%
do_handle_info({send_sys2single,RoleID,Title,Text,GoodsList})->
    do_send_sys2single_letter(RoleID,Title,Text,GoodsList);

%% 这里的Text是原始信件
do_handle_info({send,Title,RoleIDList,Text,GoodsList})->
    do_sys2common_letter(RoleIDList,Title,Text,GoodsList);

%% gm发送群体信件 是createinfo不是pgoods
%% 注意！这里虽然叫gmxxx 但是是以系统信件的类型发送出去 

do_handle_info({gm_send_goods_batch,RoleIDList,Title,Content,CreateInfo}) ->
    do_sys2common_letter(RoleIDList,Title,Content,CreateInfo);

%% gm返回发送群体信件结果
do_handle_info({return_gm_send_goods_batch,FailList2,AllCount,LetterDetail})->
    do_return_gm_send_goods_batch(FailList2,AllCount,LetterDetail);

%% gm回复信件  区别在于一个是replyid需要记录， 一个是replypid 结果要返回给进程replypid
do_handle_info({gm_reply_letter,ReplyID,RoleID,Text,GoodsList}) ->
    do_gm_reply_letter(ReplyID,RoleID,Text,GoodsList);

%% gm发送物品
do_handle_info({gm_send_goods,ReplyPID,RoleID,Text,GoodsList}) ->
    do_gm_send_goods(ReplyPID,RoleID,Text,GoodsList);

%% GM发送信件
do_handle_info({gm_personal_letter,Title,Text,RoleID}) ->
    do_gm_send_personal_letter(Title,Text,RoleID);

%% 专门用来分段群发    
do_handle_info({split,FailList,RoleIDList,LetterDetail,Goods,AllCount})->
    do_sys2common_letter_split(split,FailList,RoleIDList,LetterDetail,Goods,AllCount);

%% 玩家每次登陆都请除一遍数据表中的数据    done
do_handle_info({clean_role_letter,RoleID})->
    do_clean_role_letter(RoleID).
%%=========================================================================== 


%%=======================================================================
%%---------------- manager ----------------------------------------------
%%=======================================================================


%% 玩家获取全部信件------------------
do_get_all_letter({Unique, Module, Method, DataIn, RoleID, _Pid, Line})->
    #m_letter_get_tos{}=DataIn,
    LetterList1 = get_letter_list_from_personal(RoleID),
    LetterList2 = get_letter_list_from_public(RoleID),
    LetterListToc = #m_letter_get_toc{letters =LetterList1 ++ LetterList2,
                                  request_mark = 1},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, LetterListToc).


%% 玩家打开一封信件-------------------
do_open_letter({Unique, Module, Method, DataIn, RoleID, _Pid, Line})->
    #m_letter_open_tos{letter_id=ID,table = Table,is_self_send=IsSelf} = DataIn,
    TocRecord =
    case Table of
        ?LETTER_PERSONAL->get_from_personal_letter(ID,IsSelf,RoleID);
        ?LETTER_PUBLIC->get_from_public_letter(ID,RoleID)
    end,
    common_misc:unicast(Line, RoleID, Unique, Module, Method, TocRecord).
    
        
%% 发送宗族信件-------------------
do_send_family_letter(Text,RoleID,RoleName,FamilyName,MembersList)->
    {SendTime,OutTime} = common_letter:get_effective_time(),
    SendTitle = lists:flatten(io_lib:format(?LETTER_SEND_TO_FAMILY_TITLE,[FamilyName])), 
    RecvTitle = lists:flatten(io_lib:format(?LETTER_FROM_FAMILY_TITLE,[FamilyName])),
    Type = ?TYPE_LETTER_FAMILY,
    State = ?LETTER_NOT_OPEN,
    %%写公共信件
    CommonLetterID = common_tool:new_world_counter_id(?COMMON_LETTER_COUNTER_KEY),
    CommonLetter = #r_common_letter{id = CommonLetterID,
                                    send_time = SendTime,
                                    out_time = OutTime,
                                    type = Type,
                                    title = "来自族长的信件",
                                    text= Text},
    db:dirty_write(?DB_COMMON_LETTER,CommonLetter),
    CommonText = {{?DATABASE_LETTER,CommonLetterID},[]},    
    %%写私人信件 
    PersonalLetter = #r_personal_letter{id = common_tool:new_world_counter_id(?PERSONAL_LETTER_COUNTER_KEY),
                                        send_id = RoleID,
                                        %%recv_id = "宗族信件",
                                        del_type = ?LETTER_NOBODY_DELETE,
                                        send_name = RoleName,
                                        recv_name = "家族成员",
                                        send_time = SendTime,
                                        out_time = OutTime,
                                        goods_list=[],
                                        type = Type,
                                        send_state=State,
                                        recv_state=State,
                                        title = SendTitle,
                                        text=CommonText},
    db:dirty_write(?DB_PERSONAL_LETTER,PersonalLetter),
        PersonalMsg=get_personal_toc_msg(send,PersonalLetter),
    common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?LETTER, ?LETTER_SEND,PersonalMsg),
    %%写群体信件
    LetterDetail = #r_letter_detail{%%id,
                                    send_time = SendTime,
                                    out_time = OutTime,
                                    send_id = RoleID,
                                    send_name = RoleName,
                                    goods_list=[],
                                    type = Type,
                                    state = State,
                                    title = RecvTitle,
                                    text = CommonText},
    lists:foreach(fun({MemberID,MemberName})->
                          %%PublicLetterID = common_tool:new_world_counter_id(?PUBLIC_LETTER_COUNTER_KEY),
                          NewDetailLetter = insert_receiver_letterbox(MemberID,MemberName,LetterDetail),
                          PublicMsg = get_detail_toc_msg(NewDetailLetter),
                          common_misc:unicast({role,MemberID}, ?DEFAULT_UNIQUE, ?LETTER, ?LETTER_SEND,PublicMsg)
                  end,MembersList).


%% 发送gm回复信件  ---------------------------------
do_gm_reply_letter(ReplyID,RoleID,Text,GoodsList)->
    Title = "GM发给你的信件",
    Type = ?TYPE_LETTER_GM,
    {ok,ID}=do_send_personal_letter(RoleID,Title,Type,Text,GoodsList),
    global:send(mgeel_s2s_client,{gm_notify_reply,ReplyID,true,"",ID}).

%% gm发送物品？-----------------
do_gm_send_goods(ReplyPID,RoleID,Text,GoodsList)->
    Title = "GM发给你的信件",
    Type = ?TYPE_LETTER_GM,
    {ok,_ID}=do_send_personal_letter(RoleID,Title,Type,Text,GoodsList),
    ReplyPID ! ok.

%%@doc （后台赠送元宝后）发送的系统信件-----------------------------
do_gm_send_personal_letter(Title,Text,RoleID)->
    Type = ?TYPE_LETTER_GM,
    do_send_personal_letter(RoleID,Title,Type,Text,[]).

do_send_personal_letter(RoleID,Title,Type,Text,GoodsList)->
    ID =common_tool:new_world_counter_id(?PERSONAL_LETTER_COUNTER_KEY), 
    RecvName = common_misc:get_dirty_rolename(RoleID),
    {SendTime,OutTime} = common_letter:get_effective_time(),
    GoodsList1 = if is_list(GoodsList) ->GoodsList;
                    true ->[] 
                 end,
    PersonalLetter = 
    #r_personal_letter{id = ID,
                       %%send_id = ,
                       recv_id = RoleID,
                       del_type= ?LETTER_NOBODY_DELETE,
                       send_name = "",
                       recv_name = RecvName,
                       send_time = SendTime,
                       out_time = OutTime,
                       goods_list= GoodsList1,
                       type = Type,
                       send_state=?LETTER_REPLY,
                       recv_state=?LETTER_NOT_OPEN,
                       title = Title,
                       text=Text},
     %%发送信件
    db:dirty_write(?DB_PERSONAL_LETTER,PersonalLetter),
    TocMsg = get_personal_toc_msg(recv,PersonalLetter),
    common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?LETTER, ?LETTER_SEND,TocMsg),
    [ insert_item_log(RoleID,G)||G<-GoodsList ],
    {ok,ID}.

%% 玩家向玩家发送信件------------------
do_send_p2p(SendID,RecvID,Text,GoodsList)->
    SendName = common_misc:get_dirty_rolename(SendID),
    RecvName = common_misc:get_dirty_rolename(RecvID),
    {SendTime,OutTime} = common_letter:get_effective_time(),
    PersonalLetter = #r_personal_letter{id = common_tool:new_world_counter_id(?PERSONAL_LETTER_COUNTER_KEY),
                                     send_id = SendID,
                                     recv_id = RecvID,
                                     del_type=0,
                                     send_name = SendName,
                                     recv_name = RecvName,
                                     send_time = SendTime,
                                     out_time = OutTime,
                                     goods_list = GoodsList,
                                     type = ?TYPE_LETTER_PRIVATE,
                                     send_state = ?LETTER_NOT_OPEN,
                                     recv_state = ?LETTER_NOT_OPEN,
                                     title ="",
                                     text=Text},
    db:dirty_write(?DB_PERSONAL_LETTER,PersonalLetter),
    TocSendMsg = get_personal_toc_msg(send,PersonalLetter),
    TocRecvMsg = get_personal_toc_msg(recv,PersonalLetter),
    SendID = PersonalLetter#r_personal_letter.send_id,
    RecvID = PersonalLetter#r_personal_letter.recv_id,
    common_misc:unicast({role,SendID}, ?DEFAULT_UNIQUE, ?LETTER, ?LETTER_SEND,TocSendMsg),
    common_misc:unicast({role,RecvID}, ?DEFAULT_UNIQUE, ?LETTER, ?LETTER_SEND,TocRecvMsg).
 
%% 玩家检查获取物品-------------------------
do_letter_accept_goods({Unique, Module, Method, DataIn, RoleID, PID, _Line}) ->      
    #m_letter_accept_goods_tos{letter_id=ID,table = Table}=DataIn,
    %% 写入队列
    case catch check_letter_accept_goods(RoleID,ID,Table) of
        {ok,Queue}->
            do_check_accept_goods2(RoleID,Queue);
        {error,BinReason} when is_binary(BinReason)->
            ?UNICAST_TOC( #m_letter_accept_goods_toc{succ = false, reason = BinReason} );
        {error,Reason}->
            ?ERROR_MSG("reason:~w~n",[Reason])
    end.
do_check_accept_goods2(RoleID,Queue)->
    #r_accept_goods_request{letter_id = ID,table = Table} = Queue,
    {Req,Result} = 
        case Table of
            ?LETTER_PERSONAL->catch get_personal_goods_letter(ID,RoleID);
            ?LETTER_PUBLIC->catch get_public_goods_letter(ID,RoleID)
        end,
    case Req of
        ok->
            ?SEND_TO_MAP_LETTER(RoleID,accept_goods,Result);
        error->
            TocMsg =#m_letter_accept_goods_toc{succ = false, reason = Result}, 
            common_misc:unicast({role,RoleID}, ?DEFAULT_UNIQUE, ?LETTER, ?LETTER_ACCEPT_GOODS,TocMsg)
    end.

%% 玩家已获取物品成功 -------------------
do_map_accept_goods({public,LetterID,RoleID})->
    %%数据库数据字段修改 外加清除进程字典
    case db:dirty_read(?DB_PUBLIC_LETTER,RoleID) of
        [PublicLetter] when is_record(PublicLetter,r_public_letter) ->
            LetterBox = PublicLetter#r_public_letter.letterbox,
            case lists:keyfind(LetterID, #r_letter_detail.id, LetterBox) of
                DetailLetter when is_record(DetailLetter,r_letter_detail) ->
                    NewDetailLetter = DetailLetter#r_letter_detail{state = ?LETTER_HAS_ACCEPT_GOODS},
                    NewLetterBox = [NewDetailLetter|lists:delete(DetailLetter, LetterBox)],
                    db:dirty_write(?DB_PUBLIC_LETTER,PublicLetter#r_public_letter{letterbox = NewLetterBox}),
                    del_accept_goods_req(RoleID,LetterID);
                false ->
                    ignore
            end;
        _->
            ignore
    end;
do_map_accept_goods({personal,LetterID,RoleID})->
    case db:dirty_read(?DB_PERSONAL_LETTER,LetterID) of
        [PersonalLetter] when is_record(PersonalLetter,r_personal_letter)->
            NewPersonalLetter = PersonalLetter#r_personal_letter{recv_state = ?LETTER_HAS_ACCEPT_GOODS},
            db:dirty_write(?DB_PERSONAL_LETTER,NewPersonalLetter),
            del_accept_goods_req(RoleID,LetterID);
        _->
            ignore
    end.


%% 返回群体信件结果
do_return_gm_send_goods_batch(FailList,AllCount,LetterDetail)->
    FailCount = length(FailList),
%%     IsAllSucc = FailCount =:= 0,
%%     IsAllFail = AllCount =:= FailCount,
    LetterType = 
    case LetterDetail#r_letter_detail.goods_list of
        []->0;
        _->1
    end,
    TimeSpend = AllCount div ?ONE_TIME_SEND_MAX *?SEND_SPLIT_TIME div 1000,
    SQL = mod_mysql:get_esql_insert(t_send_batch_result,
                                    [all_count,fail_count,fail_list,log_time,title,letter_type,time_spend],
                                    [AllCount,FailCount,FailList,common_tool:now(),LetterDetail#r_letter_detail.title,LetterType,TimeSpend]
                                   ), 
    {ok,_} = mod_mysql:insert(SQL).


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

%% 系统向单个玩家发送信件  ------------------
%% system to person
do_send_sys2p_letter(RoleID,Title,Text,GoodsList,Days, SendTime)->
    {_,OutTime} = common_letter:get_effective_time(Days),
    %% 获取公共信件内容索引
    Text1 = 
    case Text of
        {{_,_},_} ->Text;
        _-> common_letter:create_db_common_letter(SendTime,OutTime,Title,Text)
    end, 
    LetterDetail = 
        #r_letter_detail{%%id,
                         send_time = SendTime,
                         out_time = OutTime,
                         %%send_id,
                         send_name = "系统",
                         goods_list=GoodsList,
                         type = ?TYPE_LETTER_SYSTEM,
                         state = ?LETTER_NOT_OPEN,
                         title = Title,
                         text = Text1},
    do_sys2common_letter_single(RoleID,LetterDetail,GoodsList).

%%system to single person 信件不做公共信件保存
do_send_sys2single_letter(RoleID,Title,Text,GoodsList)->
     Type = ?TYPE_LETTER_GM,
    do_send_personal_letter(RoleID,Title,Type,Text,GoodsList).
    
%% 清除信件
do_clean_role_letter(RoleID)->
    %% 清除信箱信件,信箱里的 删了也就删了..
    case db:dirty_read(?DB_PUBLIC_LETTER,RoleID) of
        [PublicLetter] when is_record(PublicLetter,r_public_letter) ->
            NewLetterBox = 
            lists:foldr(fun(LetterDetail,Acc)->
                                    case LetterDetail#r_letter_detail.out_time>common_tool:now() of
                                        true->[LetterDetail|Acc];
                                        false->Acc
                                    end
                                end,[],PublicLetter#r_public_letter.letterbox),
            case NewLetterBox =:= PublicLetter#r_public_letter.letterbox of
                true-> ignore;
                false -> db:dirty_write(?DB_PUBLIC_LETTER,PublicLetter#r_public_letter{letterbox = NewLetterBox})
            end;
        _->
            ignore
    end,
    
    %% 清除私人信件
    %% 先match_object找出全部
    %% 过滤
    %% 删除
    PatternSend = #r_personal_letter{send_id = RoleID, _='_'},
    PersonalSendList = get_personal_out_time_list(PatternSend),
    ?DEBUG("PersonalSendList:~w~n",[PersonalSendList]),
    lists:foreach(fun(PersonalSend)->
                         catch delete_from_personal_letter(send,PersonalSend)
                          end,PersonalSendList),
    
    PatternRecv = #r_personal_letter{recv_id = RoleID, _='_'},
    PersonalRecvList = get_personal_out_time_list(PatternRecv),
    ?DEBUG("PersonalRecvList:~w~n",[PersonalRecvList]),
    lists:foreach(fun(PersonalRecv)->
                          catch delete_from_personal_letter(recv,PersonalRecv)
                          end,PersonalRecvList).
                                           
    
%%删除信件 ------------------------------
%%如果要删除公共信件，先把信箱拿出来，把全部信件处理完再写回去
do_delete_letter({Unique, Module, Method, DataIn, RoleID, _Pid, Line})->
    #m_letter_delete_tos{letters = DelList} = DataIn,
    PublicLetter1 = 
    case db:dirty_read(?DB_PUBLIC_LETTER,RoleID) of
        [PublicLetter] when is_record(PublicLetter,r_public_letter) ->
            PublicLetter;
        _->common_letter:create_new_public_letter(RoleID)
    end,
    LetterBox = PublicLetter1#r_public_letter.letterbox,
    %% 返回没被删除的信件和新的信箱
    {NoDelList,NewLetterBox} = 
    lists:foldr(fun(LetterDel,{TmpNoDelList,TmpLetterBox}) ->
                        #p_letter_delete{table = Table}=LetterDel,
                        case Table of
                            ?LETTER_PERSONAL->
                               case catch delete_from_personal_letter(LetterDel) of
                                   {ok,_}->{TmpNoDelList,TmpLetterBox};
                                   {error,_R}->
                                       ?ERROR_MSG("ERROR ~w~n",[_R]),
                                       {[LetterDel|TmpNoDelList],TmpLetterBox}
                               end;
                            ?LETTER_PUBLIC->
                                case delete_from_public_letter(LetterDel,TmpLetterBox) of
                                    {ok,LetterBox1}->{TmpNoDelList,LetterBox1};
                                    {error,_R}->
                                        ?ERROR_MSG("ERROR ~w~n",[_R]),
                                        {[LetterDel|TmpNoDelList],TmpLetterBox}
                                end
                        end
                end,{[],LetterBox},DelList),
    case NewLetterBox =:= LetterBox of
        true->ignore;
        false->
            NewPublicLetter = PublicLetter1#r_public_letter{letterbox = NewLetterBox},
            db:dirty_write(?DB_PUBLIC_LETTER,NewPublicLetter)
    end,
    %%联系用户
    DelTocMsg = #m_letter_delete_toc{succ=true, no_del=NoDelList},
    common_misc:unicast(Line, RoleID, Unique, Module, Method, DelTocMsg).


%% ---------------------删除群邮
delete_from_public_letter(LetterDel,LetterBox)->
    #p_letter_delete{letter_id = LetterID} =LetterDel,
    case lists:keyfind(LetterID,#r_letter_detail.id,LetterBox) of
        LetterDetail when is_record(LetterDetail,r_letter_detail) ->
            {ok,lists:delete(LetterDetail, LetterBox)};
        false ->
            {error,"删除失败"}
    end.

%% --------------------begin 删除私人信件
delete_from_personal_letter(LetterDel) when is_record(LetterDel,p_letter_delete)->
    #p_letter_delete{letter_id = LetterID,is_self_send =IsSelf} =LetterDel,
    case db:dirty_read(?DB_PERSONAL_LETTER,LetterID) of
        [PersonalLetter] when is_record(PersonalLetter,r_personal_letter)->
            case IsSelf of
                true->
                    delete_from_personal_letter(send,PersonalLetter);  
                false ->
                    delete_from_personal_letter(recv,PersonalLetter)
            end;
        _->
            {error,"删除失败"}
    end.
     
delete_from_personal_letter(recv,PersonalLetter)->
    %% 先判断是否已删除
    case PersonalLetter#r_personal_letter.del_type of
        ?LETTER_DELETE_BY_RECEIVER->
            throw({error,"已经删除"});
        _->     
            next
    end,
    %% 判断是否有发件人
    case PersonalLetter#r_personal_letter.send_id of
        undefined->
            db:dirty_delete(?DB_PERSONAL_LETTER,PersonalLetter#r_personal_letter.id),
            throw({ok,"删除成功"});
        _->
            next
    end,
    %%系统退信 条件：1.有物品 ，2.没收取
    case PersonalLetter#r_personal_letter.goods_list of
        []->ignore;
        _ when PersonalLetter#r_personal_letter.recv_state=/=?LETTER_HAS_ACCEPT_GOODS ->
            send_back_letter(PersonalLetter);
        _->ignore
    end,
    %%　退信之后对信件的不同处理方式
    case PersonalLetter#r_personal_letter.del_type of
        ?LETTER_DELETE_BY_SENDER->
            db:dirty_delete(?DB_PERSONAL_LETTER,PersonalLetter#r_personal_letter.id),
            throw({ok,"删除成功"});
        ?LETTER_NOBODY_DELETE->
            db:dirty_write(?DB_PERSONAL_LETTER,PersonalLetter#r_personal_letter{del_type = ?LETTER_DELETE_BY_RECEIVER}),
            throw({ok,"删除成功"})
    end;

delete_from_personal_letter(send,PersonalLetter)->
    case PersonalLetter#r_personal_letter.del_type of
        ?LETTER_DELETE_BY_SENDER->
            throw({error,"已经删除"});
        ?LETTER_DELETE_BY_RECEIVER->
            db:dirty_delete(?DB_PERSONAL_LETTER,PersonalLetter#r_personal_letter.id),
            throw({ok,"删除成功"});
        ?LETTER_NOBODY_DELETE->     
            db:dirty_write(?DB_PERSONAL_LETTER,PersonalLetter#r_personal_letter{del_type =?LETTER_DELETE_BY_SENDER}),
            throw({ok,"删除成功"})
    end.
%% --------------------end 删除私人信件

%% --------------------begin 退信
%% 只有删除  私人发送给你的  且带物品的  且物品为收的信件才会退信
%% 退回信件会将类型改为 ?TYPE_LETTER_RETURN 

send_back_letter(PersonalLetter)->
    if is_integer(PersonalLetter#r_personal_letter.send_id) ->
           NewRecvID = PersonalLetter#r_personal_letter.send_id,
           {SendTime,OutTime} = common_letter:get_effective_time(),
           NewPersonalLetter = 
               #r_personal_letter{id = common_tool:new_world_counter_id(?PERSONAL_LETTER_COUNTER_KEY),
                                  %%send_id, 退信不设id
                                  recv_id = NewRecvID,
                                  del_type=?LETTER_DELETE_BY_SENDER,
                                  send_name = PersonalLetter#r_personal_letter.recv_name,
                                  recv_name = PersonalLetter#r_personal_letter.send_name,
                                  send_time = SendTime,
                                  out_time = OutTime,
                                  goods_list = PersonalLetter#r_personal_letter.goods_list,
                                  type = ?TYPE_LETTER_RETURN,
                                  send_state=?LETTER_NOT_OPEN,
                                  recv_state=?LETTER_NOT_OPEN,
                                  title = "退信",
                                  text = "退信，物品被退回"},
           
           db:dirty_write(?DB_PERSONAL_LETTER,NewPersonalLetter),
           TocMsg = get_personal_toc_msg(recv,NewPersonalLetter),
           common_misc:unicast({role,NewRecvID}, ?DEFAULT_UNIQUE, ?LETTER, ?LETTER_SEND,TocMsg);
       true->ignore
    end.
%% ------------------end 退信

%% ===================================================================
%% -------------------- tool function --------------------------------
%% ===================================================================

%% 分段发送 ----------------------------------
do_sys2common_letter_split(split,FailList,RoleIDList,LetterDetail,Goods,AllCount)->
    {RoleIDList1,RoleIDList2} =
                  case length(RoleIDList) < ?ONE_TIME_SEND_MAX of
                      true ->
                          {RoleIDList,[]};
                      false ->
                          lists:split(?ONE_TIME_SEND_MAX,RoleIDList)
                  end,
    FailList1 =
        lists:foldr(fun(RoleID,Acc)->
                        case do_sys2common_letter_single(RoleID,LetterDetail,Goods) of
                            {error,_ID,_Reason} -> 
                                [RoleID|Acc];
                            {error,_Reason}->
                                [RoleID|Acc];
                            _->Acc
                        end
                        end, [], RoleIDList1),
    FailList2 = FailList ++ FailList1,
    ?DEBUG("FailList2:~w~n",[FailList2]),
    case RoleIDList2 =:= [] of
        true->
            erlang:send(self(),{return_gm_send_goods_batch,FailList2,AllCount,LetterDetail});
        false->
            erlang:send_after(?SEND_SPLIT_TIME,self(),{split,FailList2,RoleIDList2,LetterDetail,Goods,AllCount})
    end.


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
    [?TRY_CATCH( insert_item_log(RoleID,G) ) || G<-GoodsList].



%%@doc 创建作为赠送用途的默认物品
create_goods(RoleID,Info)->
    #r_goods_create_info{bind=Bind, bag_id=BagID, type=Type, type_id=TypeID, start_time=StartTime, end_time=EndTime,
                        num=Num, color=Color, quality=Quality, punch_num=PunchNum, property=Property, rate=Rate, result=Result,
                        result_list=ResultList, interface_type=InterfaceType,use_pos=UsePosList,sub_quality=SubQuality} = Info,
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
            Info2 = #r_equip_create_info{role_id=RoleID, bag_id=BagID,  num=Num, typeid=TypeID, bind=Bind,sub_quality=SubQuality, 
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

%% -----获取personal信件toc格式
get_personal_toc_msg(IsSend,Letter)->
    SimpleLetter = change_personal_to_simple(IsSend,Letter),
    #m_letter_send_toc{
       succ = true,
       letter = SimpleLetter                 
    }.
change_personal_to_simple(IsSend,Letter)->
    State = 
    case IsSend of
        send ->Letter#r_personal_letter.send_state;
        recv ->Letter#r_personal_letter.recv_state
    end,
    IHG = if Letter#r_personal_letter.goods_list =:= [] ->
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
               id   = Letter#r_personal_letter.id,
               sender = Letter#r_personal_letter.send_name,
               receiver = Letter#r_personal_letter.recv_name,
               title    = Letter#r_personal_letter.title,       
               send_time  = Letter#r_personal_letter.send_time,   
               type       = Letter#r_personal_letter.type,     
               state      = State,     
               is_have_goods = IHG,
               table = ?LETTER_PERSONAL   
            }.

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


%% -------从私人信件中获取信件内容
get_from_personal_letter(ID,IsSelf,RoleID)->
    case catch get_from_personal_letter2(ID,IsSelf,RoleID) of
        {ok,LetterInfo}->
            #m_letter_open_toc{succ=true,result=LetterInfo};
        {error,Reason}->
            #m_letter_open_toc{succ=false,reason=Reason}
    end.
get_from_personal_letter2(ID,IsSelf,RoleID)->  
    PersonalLetter =
        case db:dirty_read(?DB_PERSONAL_LETTER,ID) of
            [PersonalLetter1] when is_record(PersonalLetter1,r_personal_letter) ->
                PersonalLetter1;
            _->
                throw({error,"找不到信件"})
        end,
    State =
        case IsSelf of
            true->
                State1 = PersonalLetter#r_personal_letter.send_state,
                case State1 =:= ?LETTER_NOT_OPEN of
                    true -> db:dirty_write(?DB_PERSONAL_LETTER,PersonalLetter#r_personal_letter{send_state = ?LETTER_HAS_OPEN});
                    false->ignore
                end,
                State1;
            false ->
                State1 = PersonalLetter#r_personal_letter.recv_state,
                case State1 =:= ?LETTER_NOT_OPEN of
                    true -> db:dirty_write(?DB_PERSONAL_LETTER,PersonalLetter#r_personal_letter{recv_state = ?LETTER_HAS_OPEN});
                    false->ignore
                end,
                State1
        end,
    
    {ok,RoleBase} = common_misc:get_dirty_role_base(RoleID),
    FactionID = RoleBase#p_role_base.faction_id,
    Text = case PersonalLetter#r_personal_letter.text of 
               {{RecordType,LetterKey},List}->
                   get_letter_content({{RecordType,LetterKey},List},FactionID);
               Text1->Text1
           end,
    LetterInfo = 
    #p_letter_info{id   = PersonalLetter#r_personal_letter.id,
                   sender   = PersonalLetter#r_personal_letter.send_name,
                   receiver = PersonalLetter#r_personal_letter.recv_name,
                   title    = PersonalLetter#r_personal_letter.title,       
                   send_time  = PersonalLetter#r_personal_letter.send_time,   
                   type       = PersonalLetter#r_personal_letter.type,     
                   state      = State,     
                   goods_list = PersonalLetter#r_personal_letter.goods_list,
                   letter_content = Text,
                   table = ?LETTER_PERSONAL},
    {ok,LetterInfo}.

%% ------------公共信件信箱
get_from_public_letter(ID,RoleID)->
    case catch get_from_public_letter2(ID,RoleID) of
        {ok,LetterInfo}->
            #m_letter_open_toc{succ=true,result=LetterInfo};
        {error,Reason}->
            #m_letter_open_toc{succ=false,reason=Reason}
    end.
get_from_public_letter2(ID,RoleID)->
    PublicLetter1 = 
        case db:dirty_read(?DB_PUBLIC_LETTER,RoleID) of
            [PublicLetter] when is_record(PublicLetter,r_public_letter) ->
                PublicLetter;
            _->
                throw({error,"找不到信件"})
        end,
    LetterDetail = 
        case lists:keyfind(ID, #r_letter_detail.id, PublicLetter1#r_public_letter.letterbox) of
            false->
                throw({error,"找不到信件"});
            _Letter->_Letter
        end,
    case LetterDetail#r_letter_detail.state =:=?LETTER_NOT_OPEN of
        true->
            LetterBox = PublicLetter1#r_public_letter.letterbox,
            NewLetterBox = [LetterDetail#r_letter_detail{state = ?LETTER_HAS_OPEN}|lists:delete(LetterDetail,LetterBox)],
            db:dirty_write(?DB_PUBLIC_LETTER,PublicLetter1#r_public_letter{letterbox = NewLetterBox});
        false->
            ignore
    end,
    
    {ok,RoleBase} = common_misc:get_dirty_role_base(RoleID),
    FactionID = RoleBase#p_role_base.faction_id,
    Text = case LetterDetail#r_letter_detail.text of 
               {{RecordType,LetterKey},List}->
                   get_letter_content({{RecordType,LetterKey},List},FactionID);
               Text1->Text1
           end,
    LetterInfo = 
    #p_letter_info{id   = LetterDetail#r_letter_detail.id,
                   sender   = LetterDetail#r_letter_detail.send_name,
                   receiver = "",
                   title    = LetterDetail#r_letter_detail.title,       
                   send_time  = LetterDetail#r_letter_detail.send_time,   
                   type       = LetterDetail#r_letter_detail.type,     
                   state      = LetterDetail#r_letter_detail.state,     
                   goods_list = LetterDetail#r_letter_detail.goods_list,
                   goods_take = [],
                   letter_content = Text,
                   table = ?LETTER_PUBLIC},
    {ok,LetterInfo}.
   
%% ========= 获取公共信件的内容 ==============================    
get_letter_content({{RecordType,Key},List},FactionID)->
	case RecordType of
		?DATABASE_LETTER->
			case db:dirty_read(?DB_COMMON_LETTER,Key) of
				[CommonLetter] when is_record(CommonLetter,r_common_letter) ->
					CommonLetter#r_common_letter.text;
				_->""
			end;
		?TEMPLATE_LETTER->
			case lists:keyfind(Key, #r_letter_template.key, ?LETTER_TEMPLATE) of
				false->"";
				LetterTemplate when is_record(LetterTemplate,r_letter_template)->
					common_letter:get_text_with_npc(LetterTemplate#r_letter_template.content,FactionID,List)
			end
	end.

%% ==============================================================        
%%从personal表中获取玩家信件列表
get_letter_list_from_personal(RoleID)->
    ?DEBUG("personal_letter ~w~n",[RoleID]),
    SendPattern = #r_personal_letter{send_id = RoleID, _='_'},
    SendLetterList = get_letter_list_by_pattern(send,SendPattern),
    RecvPattern = #r_personal_letter{recv_id = RoleID, _ = '_'},
    RecvLetterList = get_letter_list_by_pattern(recv,RecvPattern),
    SendLetterList ++RecvLetterList.

get_letter_list_by_pattern(IsSend,Pattern)->
    LetterList1= 
        case db:dirty_match_object(?DB_PERSONAL_LETTER,Pattern) of
            [LetterList|T] when is_record(LetterList,r_personal_letter) ->
                [LetterList|T];
            _->
                []
        end,
    %% 去掉被标记信件
    LetterList2 = 
        case IsSend of
            send-> 
                lists:foldr(fun(Letter,Acc)-> 
                                    case Letter#r_personal_letter.del_type=:=?LETTER_DELETE_BY_SENDER of
                                        true->Acc;
                                        false -> [Letter|Acc]
                                    end
                            end, [], LetterList1);
            recv->
                lists:foldr(fun(Letter,Acc)-> 
                                    case Letter#r_personal_letter.del_type=:=?LETTER_DELETE_BY_RECEIVER of
                                        true->Acc;
                                        false -> [Letter|Acc]
                                    end
                            end, [], LetterList1)
        end,
    lists:map(fun(Letter)->
                      change_personal_to_simple(IsSend,Letter)
              end,LetterList2).

%%从public表中获取玩家信件列表
get_letter_list_from_public(RoleID)->
    LetterBox = 
    case db:dirty_read(?DB_PUBLIC_LETTER,RoleID) of
        [PublicLetter] when is_record(PublicLetter,r_public_letter) ->
            PublicLetter#r_public_letter.letterbox;
        _->[]
    end,
    lists:map(fun(DetailLetter)->
                      change_detail_to_simple(DetailLetter)
                      end, LetterBox).


del_accept_goods_req(RoleID,LetterID)->
    case get( ?ACCEPT_GOODS_REQ_KEY() ) of
        undefined->
            ?ERROR_MSG("坑爹了，这家伙领取了多次的信件附件,RoleID=~w,LetterID=~w",[RoleID,LetterID]);
        _ ->
            erase( ?ACCEPT_GOODS_REQ_KEY() )
    end.

%% 检查队列中是否有附件需要领取
check_letter_accept_goods(RoleID,LetterID,Table)->
    Now = common_tool:now(),
    NewReq = #r_accept_goods_request{time = Now,letter_id = LetterID, table = Table},
    
    case get( ?ACCEPT_GOODS_REQ_KEY() ) of
        undefined->
            put( ?ACCEPT_GOODS_REQ_KEY(),NewReq ),
            {ok,NewReq};
        #r_accept_goods_request{time = LastReqTime} ->
            case Now-LastReqTime>?ACCEPT_REQ_OVER_TIME of
                true->
                    put( ?ACCEPT_GOODS_REQ_KEY(),NewReq ),
                    {ok,NewReq};
                false->
                    {error,<<"系统繁忙，请稍后再点击领取附件">>}
            end
    end.

%% 获取私人信件物品
get_personal_goods_letter(ID,RoleID)->
    PersonalLetter1 = 
    case db:dirty_read(?DB_PERSONAL_LETTER,ID) of
        [PersonalLetter] when is_record(PersonalLetter,r_personal_letter) ->
            PersonalLetter;
        _->throw({error,"找不到信件"})
    end,
    case PersonalLetter1#r_personal_letter.recv_id =:= RoleID of
        true -> next;
        false -> throw({error,"找不到信件"})
    end,
    case PersonalLetter1#r_personal_letter.goods_list=:=[] of
        true -> throw({error,"此信件没有物品"});
        false -> next
    end, 
    case PersonalLetter1#r_personal_letter.recv_state =:= ?LETTER_HAS_ACCEPT_GOODS of
        true -> throw({error,"物品已收取"});
        false ->next
    end,
    case PersonalLetter1#r_personal_letter.del_type =:= 1 of
        true-> throw({error,"该信件已经删除"});
        false-> next
    end,
    %%NewPersonalLetter = PersonalLetter1#r_personal_letter{type=?LETTER_HAS_ACCEPT_GOODS},
    %%db:dirty_write(?DB_PERSONAL_LETTER,NewPersonalLetter),
    LetterLog = 
        #r_letter_log{target_role_id = PersonalLetter1#r_personal_letter.recv_id,
                      target_role_name = PersonalLetter1#r_personal_letter.recv_name,
                      role_name =PersonalLetter1#r_personal_letter.send_name,
                      goods = PersonalLetter1#r_personal_letter.goods_list},
    {ok,{personal,ID,LetterLog}}.
    
%% 获取公共信件物品
get_public_goods_letter(ID,RoleID)->
    PublicLetter1 = 
        case db:dirty_read(?DB_PUBLIC_LETTER,RoleID) of
            [PublicLetter] when is_record(PublicLetter,r_public_letter) ->
                PublicLetter;
            _->throw({error,"找不到信息"})
        end,
    DetailLetters1 = 
        case PublicLetter1#r_public_letter.letterbox of
            [DetailLetters|T] when is_record(DetailLetters,r_letter_detail) ->
                [DetailLetters|T];
            _->throw({error,"找不到信息"})
        end,
    DetailLetter1 =
        case lists:keyfind(ID, #r_letter_detail.id, DetailLetters1) of
            DetailLetter when is_record(DetailLetter,r_letter_detail)->
                DetailLetter;
            _->throw({error,"找不到信息"})
        end,
    case DetailLetter1#r_letter_detail.goods_list =:=[] of
        true->throw({error,"该信件没有物品"});
        false -> next
    end,
    case DetailLetter1#r_letter_detail.state=:=?LETTER_HAS_ACCEPT_GOODS of
        true -> throw({error,"物品已收取"});
        false ->next
    end,
    %%NewDetailLetter = DetailLetter1#r_letter_detail{state=?LETTER_HAS_ACCEPT_GOODS},
    %%NewDetailLetters = [NewDetailLetter|lists:delete(DetailLetter1, DetailLetters1)],
    %%db:dirty_write(?DB_PUBLIC_LETTER,PublicLetter1#r_public_letter{letterbox=NewDetailLetters}),
    LetterLog = 
        #r_letter_log{target_role_id = PublicLetter1#r_public_letter.role_id,
                      target_role_name = PublicLetter1#r_public_letter.role_name,
                      role_name =DetailLetter1#r_letter_detail.send_name,
                      goods = DetailLetter1#r_letter_detail.goods_list},
    {ok,{public,ID,LetterLog}}.

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


get_personal_out_time_list(PatternLetter)->
    PersonalLetterList1 =
        case db:dirty_match_object(?DB_PERSONAL_LETTER, PatternLetter) of
            PersonalLetterList when is_list(PersonalLetterList)->PersonalLetterList;
            _->[]
        end,
    lists:foldr(fun(PersonalLetter,Acc)->
                        case PersonalLetter#r_personal_letter.out_time<common_tool:now() of
                            true->[PersonalLetter|Acc];
                            false->Acc
                        end
                end,[],PersonalLetterList1).
