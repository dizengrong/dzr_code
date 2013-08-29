%%%-------------------------------------------------------------------
%%% @author Liangliang <>
%%% @copyright (C) 2010, Liangliang
%%% @doc
%%%
%%% @end
%%% Created : 13 Oct 2010 by Liangliang <>
%%%-------------------------------------------------------------------
-module(common_letter).

-include("common.hrl").
-include("common_server.hrl").
-include("letter.hrl").
-include("letter_template.hrl").

%%---------------------------------------------------------

%%------------------------------------------------------
-define(LETTER_TYPE_P2P, 0).
-define(LETTER_TYPE_CLAN, 1).
-define(LETTER_TYPE_SYSTEM,2).
-define(LETTER_TYPE_ALSO, 3).

%%每封邮件支持最多的道具数
-define(MAX_GOODS_PER_LETTER, 4).

%%----------------------------------------------------

%% API
-export([
         send/2,
         init_role_letter/1,
         t_cut_money/2,
         t_return_money/2,
         sys2p/3,
         sys2p/4,  %%发送系统信件接口
         sys2p/5,
         sys2p/6,
         sys2single/4,
         send_letter_package/1,
         get_text_with_npc/3,
         get_change_money_toc/3,
         get_letter_attr/1,
         get_letter_attr/2,
         get_effective_time/0,
         get_effective_time/1,
         create_new_public_letter/1,
         create_new_public_letter/2,
         create_db_common_letter/3,
         create_db_common_letter/4,
         create_temp/2,
         update_letter_data/0,
         update_next_letter/1,
         update_send_letter/2,
         update_recv_letter/1
        ]).

send(_RoleID, _Content) ->
    ok.

init_role_letter(RoleID) ->  
   case global:whereis_name(mgeew_letter_server) of
        undefined->
            %%==================写日志
            ?DEBUG("mgeew_letter_server server down ,RoleID :~n", []),
            error;
        _->
            ?DEBUG("CLEAN LETTER ~n",[]),
            global:send(mgeew_letter_server,{clean_role_letter,RoleID}),
            ok
    end.


%% ==================================================================================
%% ----------------------------- common tool ----------------------------------------
%% ==================================================================================
%% 扣钱顺便写日志
t_cut_money(Price,RoleID)->
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    OldSilverBind = RoleAttr#p_role_attr.silver_bind,
    OldSilver = RoleAttr#p_role_attr.silver,
    
    SilverBindCut = if Price > OldSilverBind ->
                           OldSilverBind;
                       true->
                           1000
                    end,
    SilverCut = Price - SilverBindCut,
    
    NewSilverBind = OldSilverBind -SilverBindCut,
    NewSilver = OldSilver - SilverCut,
    if NewSilver < 0 ->
            db:abort({error,"钱币不够"});
        true->
            NewRoleAttr = RoleAttr#p_role_attr{silver_bind = NewSilverBind,silver = NewSilver},
            mod_map_role:set_role_attr(RoleID, NewRoleAttr),
            common_consume_logger:use_silver({RoleID, SilverBindCut, SilverCut,
                                      ?CONSUME_TYPE_SILVER_MAIL,
                                      ""}),
            {ok,{NewSilverBind,NewSilver}}
    end.
    
%% 没用到
%% 发信失败返还信件写日志
t_return_money({SilverBindCut,SilverCut},RoleID)->
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    NewSilverBind = RoleAttr#p_role_attr.silver_bind + SilverBindCut,
    NewSilver = RoleAttr#p_role_attr.silver + SilverCut,
    NewRoleAttr = RoleAttr#p_role_attr{silver_bind = NewSilverBind,silver = NewSilver},
    mod_map_role:set_role_attr(RoleID,NewRoleAttr),
    common_consume_logger:gain_silver({RoleID, SilverBindCut, SilverCut,
                                      ?GAIN_TYPE_SILVER_LETTER_RETURN,
                                      ""}).

      
%% 发送系统信件用此接口
sys2p(RoleID, Text, Title) ->
    sys2p(RoleID,Text,Title,[], 14, common_tool:now()). 
sys2p(RoleID,Text,Title,Day)->
    sys2p(RoleID,Text,Title,[],Day,common_tool:now()). 
sys2p(RoleID,Text,Title,GoodsList,Day)->
    sys2p(RoleID,Text,Title,GoodsList,Day,common_tool:now()).

% sys2p(RoleID,Text,Title,GoodsList,Day,StartTime,GLL) when GLL > 4 ->
%     lists:foreach(fun(H) ->
%         GoodsList1 = lists:sublist(GoodsList, 1 + (H - 1) * ?MAX_GOODS_PER_LETTER, H * ?MAX_GOODS_PER_LETTER),
%         sys2p(RoleID,Text,Title,GoodsList1,Day,StartTime)
%     end, lists:seq(1, round(GLL / ?MAX_GOODS_PER_LETTER + 0.5)));
% sys2p(RoleID,Text,Title,GoodsList,Day,StartTime,GLL) when GLL =< 4 ->
%     sys2p(RoleID,Text,Title,GoodsList,Day,StartTime).
    % ?MAX_GOODS_PER_LETTER
sys2p(RoleID,Text,Title,GoodsList,Day,StartTime) ->
    GLL = length(GoodsList),
    Rem = GLL rem ?MAX_GOODS_PER_LETTER, 
    Div = GLL div ?MAX_GOODS_PER_LETTER, 
    Count1 = if
        Rem == 0 -> Div;
        true -> Div + 1
    end,
    Count = if
      Count1 == 0 -> Count1 + 1;
      true -> Count1
    end,

    lists:foreach(fun(H) ->
        GoodsList1 = lists:sublist(GoodsList, 1 + (H - 1) * ?MAX_GOODS_PER_LETTER, ?MAX_GOODS_PER_LETTER),
        Info ={send_sys2p, RoleID, Title, Text, GoodsList1, Day, StartTime},
        send_letter_package(Info)
    end, lists:seq(1, Count)).

%% gm发送私人信件
sys2single(RoleID,Title,Text,GoodsList)->
    GLL = length(GoodsList),
    Rem = GLL rem ?MAX_GOODS_PER_LETTER, 
    Div = GLL div ?MAX_GOODS_PER_LETTER, 
    Count1 = if
        Rem == 0 -> Div;
        true -> Div + 1
    end,
    Count = if
      Count1 == 0 -> Count1 + 1;
      true -> Count1
    end,

    lists:foreach(fun(H) ->
        GoodsList1 = lists:sublist(GoodsList, 1 + (H - 1) * ?MAX_GOODS_PER_LETTER, H * ?MAX_GOODS_PER_LETTER),
        Info={send_sys2single,RoleID,Title,Text,GoodsList1},
        send_letter_package(Info)
    end, lists:seq(1, Count)).

%% 个别信件接口
send_letter_package(Info)->
    case global:whereis_name(mgeew_letter_server) of
        undefined->
            %%==================写日志
            ?ERROR_MSG("mgeew_letter_server server down Info:~w ~n", [Info]),
            {error,?_LANG_SYSTEM_ERROR};
        Pid->
            erlang:send(Pid,Info),
            ok
    end.

get_text_with_npc(TextContent,FactionID,List)->
    lists:flatten(
      io_lib:format(
        TextContent,lists:map(
          fun(Element)->
                  case Element of
                      {HWnpc,YLnpc,WLnpc} ->  
                          case FactionID of
                              1->HWnpc;
                              2->YLnpc;
                              3->WLnpc
                          end;
                      Tmp->
                          Tmp
                  end
          end,List))).




%% 好像有点废
get_change_money_toc(RoleID,SilverBind,Silver)->
      P1 = #p_role_attr_change{change_type=?ROLE_SILVER_CHANGE,new_value=Silver},
      P2 = #p_role_attr_change{change_type=?ROLE_SILVER_BIND_CHANGE,new_value=SilverBind},
      #m_role2_attr_change_toc{roleid=RoleID,changes=[P1,P2]}.


%% 获取信件属性
%% Type:int() 信件类型 0|1|2|3|4
%% IsSelf:bool() 是否是收件信件
%% return attr:atom() public|personal
get_letter_attr(Type)->
    get_letter_attr(Type,false).
get_letter_attr(Type,IsSelf)->
     case Type of
        ?TYPE_LETTER_PRIVATE-> 
            ?LETTER_PERSONAL;
        ?TYPE_LETTER_FAMILY ->
            if IsSelf ->
                   ?LETTER_PERSONAL;
               true->
                   ?LETTER_PUBLIC
            end;
        ?TYPE_LETTER_SYSTEM ->
            ?LETTER_PUBLIC;
        ?TYPE_LETTER_RETURN ->
            ?LETTER_PERSONAL;
        ?TYPE_LETTER_GM ->
            ?LETTER_PERSONAL;
        _->
            ?LETTER_PERSONAL
    end.

%% 获取信件有效时间

get_effective_time()->
    Day = ?LETTER_DEFAULT_SAVE_DAYS,
    get_effective_time(Day).
get_effective_time(Day)->
    SendTime = common_tool:now(),
    OutTime =SendTime + Day * 24 * 60 * 60,
    {SendTime,OutTime}.

%% 创建新的公共信箱

create_new_public_letter(RoleID)->
    RoleName = common_misc:get_dirty_rolename(RoleID),
    create_new_public_letter(RoleID,RoleName).
create_new_public_letter(RoleID,RoleName)->
    #r_public_letter{role_id = RoleID,
                     role_name = RoleName,
                     letterbox = [],
                     count = 0}.

%% 创建公共信件
create_db_common_letter(SendTime,OutTime,Text)->
    Title = "系统发给你的信件",
    create_db_common_letter(SendTime,OutTime,Title,Text).
create_db_common_letter(SendTime,OutTime,Title,Text)->
    CommonLetterID = common_tool:new_world_counter_id(?COMMON_LETTER_COUNTER_KEY),
    CommonLetter = #r_common_letter{id = CommonLetterID,
                                    send_time = SendTime,
                                    out_time = OutTime,
                                    type = ?TYPE_LETTER_SYSTEM,
                                    title = Title,
                                    text=Text},
    db:dirty_write(?DB_COMMON_LETTER,CommonLetter),
    {{?DATABASE_LETTER,CommonLetterID},[]}.


%% 生成common信件格式
create_temp(Template,List)->
    {{?TEMPLATE_LETTER,Template},List}. 

update_letter_data()->
    try
        (fun()->
                 db:clear_table(db_personal_letter_p),
                 db:clear_table(db_public_letter_p),
                 ?ERROR_MSG("CLEAN SUCC ~n",[]),
                 LetterSenderList = db:dirty_match_object(letter_sender_p, #r_letter_sender{_='_'}),
                 ?ERROR_MSG("LETTERSENDERLIST LENGTH ~w~n",[length(LetterSenderList)]),
                 lists:foreach(
                   fun(LetterSender)->
                           Single = LetterSender#r_letter_sender.single,
                           Many = LetterSender#r_letter_sender.many,
                           RoleID = LetterSender#r_letter_sender.role_id,
                           common_letter:update_send_letter(RoleID,Single),
                           common_letter:update_send_letter(RoleID,Many)
                   end,LetterSenderList),
                 ?ERROR_MSG("SENDER END ~n",[]),
                 
                 T1=common_tool:now(),
                 case db:dirty_first(letter_receiver_p) of
                     '$end_of_table'->ignore;
                     Key->
                        [LetterReceiver] = db:dirty_read(letter_receiver_p,Key),
                        common_letter:update_recv_letter(LetterReceiver),
                        common_letter:update_next_letter(Key)
                 end,
                 T2=common_tool:now()-T1,
                 ?ERROR_MSG("FINISH time ~w ~n",[T2])
         end)()
    catch _:Why -> 
              ?ERROR_MSG("catch exception ,Why:~p, stacktrace:~p",[Why,erlang:get_stacktrace()])
    end.

update_next_letter(Key)->
    case db:dirty_next(letter_receiver_p,Key) of
        '$end_of_table'-> ?ERROR_MSG("FINISH~n",[]);
        NextKey->
             [LetterReceiver] = db:dirty_read(letter_receiver_p,NextKey),
             update_recv_letter(LetterReceiver),
             update_next_letter(NextKey)
    end.
        
update_recv_letter(LetterReceiver)->
    Letter = LetterReceiver#r_letter_receiver.letter,
    RoleID = LetterReceiver#r_letter_receiver.role_id,
    lists:foreach(
      fun(LetterInfo)->
              #r_letter_info{id = _ID,
                             sender = SendName,
                             receiver = RecvName,
                             title =Title,
                             send_time = SendTime,
                             out_time = OutTime,
                             goods_list = GoodsList,
                             type = Type,
                             state= State,
                             text=Text,
                             goods_take=_GoodsTake} = LetterInfo,
              
              %%1.有物品的一定保存，不在这里做退信
              %%2.没物品的过期的，删除
              
              case Type =/=0 of
                  true->
                      case OutTime<common_tool:now() of
                          true->ignore;
                          false->%%写
                              PersonalLetter = 
                                  #r_personal_letter{id = common_tool:new_world_counter_id(personal_letter_counter_key),
                                                     %send_id = common_misc:get_roleid(SendName),
                                                     recv_id = RoleID,
                                                     del_type = -1,
                                                     send_name = SendName,
                                                     recv_name = RecvName,
                                                     send_time = SendTime,
                                                     out_time = OutTime,
                                                     goods_list = GoodsList,
                                                     type = Type,
                                                     send_state = 1,
                                                     recv_state = State,
                                                     title = Title,
                                                     text= Text},
                              db:dirty_write(db_personal_letter_p,PersonalLetter)
                      end;
                  false->
                      case GoodsList=:=[] andalso OutTime < common_tool:now() of
                          true-> ignore;
                          false->%%写
                              PersonalLetter = 
                                  #r_personal_letter{id = common_tool:new_world_counter_id(personal_letter_counter_key),
                                                     %send_id = common_misc:get_roleid(SendName),
                                                     recv_id = RoleID,
                                                     del_type = -1,
                                                     send_name = SendName,
                                                     recv_name = RecvName,
                                                     send_time = SendTime,
                                                     out_time = OutTime,
                                                     goods_list = GoodsList,
                                                     type = Type,
                                                     send_state = 1,
                                                     recv_state = State,
                                                     title = Title,
                                                     text= Text},
                              db:dirty_write(db_personal_letter_p,PersonalLetter)
                      end
              end
      end,Letter).

update_send_letter(RoleID,Letter)->
    lists:foreach(
      fun(LetterInfo)->
              #r_letter_info{id = _ID,
                             sender = SendName,
                             receiver = RecvName,
                             title =Title,
                             send_time = SendTime,
                             out_time = OutTime,
                             goods_list = GoodsList,
                             type = Type,
                             state= State,
                             text=Text,
                             goods_take=_GoodsTake} = LetterInfo,
              case OutTime > common_tool:now() of
                  true->%%写数据
                      %%发件箱数据  肯定是私人信件
                      PersonalLetter = 
                          #r_personal_letter{id = common_tool:new_world_counter_id(personal_letter_counter_key),
                                             send_id = RoleID,
                                             %recv_id = 
                                             del_type = 1,
                                             send_name = SendName,
                                             recv_name = RecvName,
                                             send_time = SendTime,
                                             out_time = OutTime,
                                             goods_list = GoodsList,
                                             type = Type,
                                             send_state = State,
                                             recv_state = 1,
                                             title = Title,
                                             text= Text},
                      db:dirty_write(db_personal_letter_p,PersonalLetter);
                  false->
                      ignore
              end
      end,Letter).
