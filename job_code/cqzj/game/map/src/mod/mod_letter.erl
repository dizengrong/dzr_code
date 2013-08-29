%% Author: Administrator
%% Created: 2011-3-31
%% Description: TODO: Add description to mod_family_letter
-module(mod_letter).
%%
%% Include files
%%
-include("mgeem.hrl").
-define(ALL_FAMILY_MEMBERS,0).
-define(ONLINE_FAMILY_MEMBERS,1).
-define(OFFLINE_FAMILY_MEMBERS,2).
-define(ROLE_SEND_COUNT,role_send_count).

%%
%% Exported Functions
%%
-export([
         get_send_count_data/1,
         set_send_count_data/2,
         handle/1
        ]).



%%
%% API Functions
%% 

%%---------------------------------角色模块调用的借口-------------------------------
handle({send_family_letter,Msg})->
    send_family_letter(Msg);
handle({send_p2p,Msg})->
    send_p2p_letter(Msg);
handle({accept_goods,Msg})->
    accept_goods(Msg).


%% ==================== start 玩家发送家族信件 =============================
send_family_letter({Unique, _Module, _Method, DataIn, RoleID, _Pid, Line})->
	#m_letter_family_send_tos{text = Text ,range = Range} =DataIn,
	case catch check_send_family_letter(RoleID,Range) of
		{ok,RoleName,FamilyName,MembersList}->
			case db:transaction(fun() ->
										case common_bag2:t_deduct_money(silver_any, ?LETTER_SEND_COST, RoleID, ?CONSUME_TYPE_SILVER_MAIL) of
											{ok,RoleAttr} -> next;
                                            {error, Reason} ->
                                                RoleAttr = null,
                                                db:abort({error,Reason});
											_ -> 
												RoleAttr = null,
												db:abort({error,"钱币不够"})
										end,
										{ok,RoleAttr}
								end) of
				{atomic,{ok,RoleAttr}}->
					common_misc:send_role_silver_change(RoleID, RoleAttr),
					Info = {map_send_family_letter,Text,RoleID,RoleName,FamilyName,MembersList},
					common_letter:send_letter_package(Info);
				{aborted, Error}->
					ErrorMsg = case Error of
								   {_,Reason1}->Reason1;
								   _->"扣钱失败了"
							   end,
					R2 = #m_letter_send_toc{succ=false,reason=ErrorMsg},
					common_misc:unicast(Line, RoleID, Unique, ?LETTER, ?LETTER_SEND, R2)
			end;        
        {error,Reason}->
            R2 = #m_letter_send_toc{succ=false,reason=Reason},
            common_misc:unicast(Line, RoleID, Unique, ?LETTER, ?LETTER_SEND, R2)
    end.            

%%检查是否可以发送并获取发送的信息
check_send_family_letter(RoleID,Range)->
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    case RoleAttr#p_role_attr.silver +RoleAttr#p_role_attr.silver_bind >=10 of
        true ->
            next;
        false->
            throw({error,"钱币不够"})
    end,
    {ok,RoleBase} = mod_map_role:get_role_base(RoleID),
    RoleID = RoleBase#p_role_base.role_id,
    FamilyInfo = 
        case db:dirty_read(?DB_FAMILY,RoleBase#p_role_base.family_id) of
            [TmpFamilyInfo] when erlang:is_record(TmpFamilyInfo,p_family_info)->
                TmpFamilyInfo;
            _->
                throw({error,"找不到家族"})
        end,
    
    case check_right_send_family_letter(FamilyInfo,RoleID) of
        true->
            next;
        false->
            throw({error,"没有权限"})
    end,
    %%获取全家族成员
    Members1= FamilyInfo#p_family_info.members,
    %%剔除发信人
    Members2 =lists:delete(lists:keyfind(RoleID, #p_family_member_info.role_id, Members1) ,Members1),

    %%筛选发信范围
    Members3 = 
        lists:foldl(
          fun(Member,Acc)->
                  %% 玩家在线bool
                  %% 收信范围(0:全部,1:在线,-1:离线)
                  %% 族员在线状态 (0:离线,1:在线)
                  case Range of
                      0->[Member|Acc];
                      1->if Member#p_family_member_info.online ->
                                [Member|Acc];
                            true->Acc
                         end;
                      -1->if Member#p_family_member_info.online ->
                                 Acc;
                             true->[Member|Acc]
                          end
                  end
          end,[],Members2),
    
    case Members3 of
        []->
            throw({error,"没有收信对象"});
        _->
            next
    end,
    MembersList = [{Member#p_family_member_info.role_id,Member#p_family_member_info.role_name}||Member <-Members3],
    FamilyName = FamilyInfo#p_family_info.family_name,
    RoleName = RoleBase#p_role_base.role_name,
    {ok,RoleName,FamilyName,MembersList}.
             
check_right_send_family_letter(FamilyInfo,RoleID)->
    %%是否族长
    (RoleID=:=FamilyInfo#p_family_info.owner_role_id)  
        orelse
        %%是否副族长
        lists:any(fun(SecondOwner)-> 
                          SecondOwner#p_family_second_owner.role_id =:=RoleID
                  end,
                  FamilyInfo#p_family_info.second_owners).

%% ==================== end 玩家发送家族信件 ====================

%% ====================start 玩家发送个人信件 ===================
send_p2p_letter({Unique, _Module, _Method, DataIn, RoleID, _Pid, Line})->
    #m_letter_p2p_send_tos{receiver = RecvName, 
                           text = Text, 
                           goods_list = LetterGoodsList} = DataIn,
    case catch check_can_send_p2p_letter(RoleID,RecvName,Text,LetterGoodsList) of
        {ok,IfHaveGoods,RecvID}-> 
            case IfHaveGoods of 
                true-> %% 扣钱,扣物,
                    GoodsIDList = [GoodsID || #p_letter_goods{goods_id=GoodsID} <- LetterGoodsList],
                    case db:transaction(fun()->t_cut_goods_and_money(RoleID,GoodsIDList) end) of
                        {atomic,{ok,GoodsList,RoleAttr}}->
							[ common_item_logger:log(RoleID,Goods,?LOG_ITEM_TYPE_XIN_JIAN_FU_JIAN_SHI_QU) ||Goods<-GoodsList ],
							common_misc:send_role_silver_change(RoleID, RoleAttr),
                            add_send_p2p_count(RoleID),
                            common_letter:send_letter_package({map_send_p2p,RoleID,RecvID,Text,GoodsList});
                        {aborted,{error,Error}}->
                            R1 = #m_letter_send_toc{succ=false,reason=Error},
                            common_misc:unicast(Line, RoleID, Unique, ?LETTER, ?LETTER_SEND, R1)
                    end;
                false->
                    common_letter:send_letter_package({map_send_p2p,RoleID,RecvID,Text,[]})
            end;
        
        {error,Reason}->
            R2 = #m_letter_send_toc{succ=false,reason=Reason},
            common_misc:unicast(Line, RoleID, Unique, ?LETTER, ?LETTER_SEND, R2)
    end.

%% 扣钱扣物
t_cut_goods_and_money(RoleID,LetterGoodsList)->
	{ok,GoodsList} = mod_bag:delete_goods(RoleID,LetterGoodsList),
	case common_bag2:t_deduct_money(silver_any, ?LETTER_SEND_COST, RoleID, ?CONSUME_TYPE_SILVER_MAIL) of
		{ok,RoleAttr} -> next;
        {error, Reason} ->
            RoleAttr = null,
            db:abort({error,Reason});
		_ -> 
			RoleAttr = null,
			db:abort({error,"钱币不够"})
	end,
	{ok,GoodsList,RoleAttr}.


check_can_send_p2p_letter(RoleID,RecvName,Text,LetterGoodsList)->
	GoodsIdList = [GoodsID || #p_letter_goods{goods_id=GoodsID} <- LetterGoodsList],
	check_attach_goods_list(RoleID,GoodsIdList),
    %%  检查发送次数    
    case check_send_p2p_count(RoleID) of
        false->throw({error,"今天发送信件已达上限"});
        true->next
    end,
    %%  检查对方是否存在    
    RecvID =
        case common_misc:get_roleid(RecvName) of
            0->throw({error,"该玩家不存在"});
            RecvID1->RecvID1
        end,
    %%  检查信件长度
    case length(Text) of
        Length when Length>?LIMIT_LETTER_LENGTH->
            throw({error,"信件内容太长"});
        0->
            throw({error,"信件内容不能为空"});
        _->
            next
    end,
    %%  检查是否有物品
    case LetterGoodsList=:=[] of
        true->
            throw({ok,false,RecvID});
        false->
            next
    end,
    %%   检查是否够钱        
    {ok,RoleAttr} = mod_map_role:get_role_attr(RoleID),
    TotalSilver = RoleAttr#p_role_attr.silver + RoleAttr#p_role_attr.silver_bind,
    case TotalSilver<10 of
        true->
            throw({error, ?_LANG_LETTER_SILVER_NOT_ENOUGH_WHEN_SEND_LETTER_WHEN_ACH});
        false->
            {ok,true,RecvID}
    end.

add_send_p2p_count(RoleID)->
    {NewDate,NewCount} = 
    case get({?ROLE_SEND_COUNT,RoleID}) of
        {Date,Count}->
            case Date =:=common_tool:date_format() of
                true->
                    {Date,Count+1};
                false ->
                    {common_tool:date_format(),1}
            end;
        _->{common_tool:date_format(),1}
    end,
    put({?ROLE_SEND_COUNT,RoleID},{NewDate,NewCount}).

%% 检查发信次数
check_send_p2p_count(RoleID)->
    case get({?ROLE_SEND_COUNT,RoleID}) of
        {Date,Count}->
            common_tool:date_format()=/=Date orelse Count<?LIMIT_SEND_LETTER_COUNT ;
        _->true
    end.


%% ====================end 玩家发送个人信件 ===================

%% ====================start 玩家获取物品 ========================
%% LetterAttr:atom() public|personal
%% LetterID:int() 
%% LetterLog:tuple() r_letter_log
accept_goods({LetterAttr,LetterID,LetterLog})->
    if is_record(LetterLog,r_letter_log) ->
           accept_goods2(LetterAttr,LetterID,LetterLog);
       true->
           ?ERROR_MSG("获取信件失败~n",[])
    end.
accept_goods2(LetterAttr,LetterID,LetterLog)-> 
    GoodsList = LetterLog#r_letter_log.goods,
    RecvID= LetterLog#r_letter_log.target_role_id,
    case db:transaction(
           fun() ->
                   {ok,GoodsList1} = mod_bag:create_goods_by_p_goods(RecvID,GoodsList),
                   LetterLog1 = 
                       LetterLog#r_letter_log{goods=mod_exchange:gen_json_goods_list(GoodsList1),
                                              time=common_tool:now()},
                   
                   {GoodsList1,LetterLog1}
           end) 
        of
        {atomic,{NewGoodsList,NewLetterLog}}->
            %% 写道具流向日志
            common_general_log_server:log_letter(NewLetterLog),
            %% 写道具使用记录
            [ common_item_logger:log(RecvID,Goods,?LOG_ITEM_TYPE_XIN_JIAN_FU_JIAN_HUO_DE) ||Goods<-GoodsList],
            %% 通知前端
            R = #m_letter_accept_goods_toc{succ=true,
                                           goods_list=[],
                                           goods_take=NewGoodsList},
            common_misc:unicast({role,RecvID}, ?DEFAULT_UNIQUE, ?LETTER, ?LETTER_ACCEPT_GOODS, R),
            %% 通知世界节点
            common_letter:send_letter_package({map_accept_goods,{LetterAttr,LetterID,RecvID}});
		{aborted,{_,{bag_error,_}}} ->
            R = #m_letter_accept_goods_toc{succ = false, reason = "背包空间不足"},
            common_misc:unicast({role,RecvID}, ?DEFAULT_UNIQUE, ?LETTER, ?LETTER_ACCEPT_GOODS, R);
        {aborted,Error}->
            ?ERROR_MSG("提取物品错误：~w~n",[Error]),
            R = #m_letter_accept_goods_toc{succ = false, reason = "提取物品错误"},
            common_misc:unicast({role,RecvID}, ?DEFAULT_UNIQUE, ?LETTER, ?LETTER_ACCEPT_GOODS, R)
    end.

%% =========================end 玩家获取物品 ========================
get_send_count_data(RoleID) ->
    get({?ROLE_SEND_COUNT,RoleID}).

set_send_count_data(RoleID,Data) ->
    case Data of
        {_,_} ->
            erlang:put({?ROLE_SEND_COUNT,RoleID},Data);
        _ ->
            Date = common_tool:date_format(),
            erlang:put({?ROLE_SEND_COUNT,RoleID},{Date,0})
    end.

%%检查附件道具是否绑定
check_attach_goods_list(_RoleID,[])->
	ok;
check_attach_goods_list(RoleID,[H|T])->
	case mod_bag:get_goods_by_id(RoleID, H) of
		{ok,#p_goods{bind=IsBind}}->
			case IsBind  of
				true ->
					throw({error, ?_LANG_LETTER_CANT_ATTACK_BIND});
				_ ->
					check_attach_goods_list(RoleID,T)
			end;
		{error,_Reason}->
			throw({error,?_LANG_SYSTEM_ERROR})
	end.
