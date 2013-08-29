%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     神游三界/月光宝盒
%%% @end
%%% Created : 2012-5-18
%%%-------------------------------------------------------------------
-module(mod_treasbox).

-include("mgeem.hrl").
-include("refining.hrl").

-export([
         handle/1,
         handle/2
        ]).
 
-export([
         init_role_treasbox_info/2,
         get_role_treasbox_info/1,
         erase_role_treasbox_info/1,
		 treasbox_can_upgrade/3,
         add_silver_open_times/2
        ]).

 
%% ====================================================================
%% Macro
%% ====================================================================
-define(find_config(Key),common_config_dyn:find(get_config_name(),Key)).

%%错误码
-define(ERR_TREASBOX_ERR,118001). %%神游三界/月光宝盒系统错误
-define(ERR_TREASBOX_ROLE_NOT_ONLINE,118002). %%亲，必须在线才能进行猎宝操作

-define(ERR_TREASBOX_GET_NO_GOODS,118010). %%_LANG_BOX_GET_NO_GOODS_ERROR,临时仓库没有此物品，无法提取
-define(ERR_TREASBOX_GOLD_NOT_OPEN,118011). %%_LANG_BOX_GOLD_NOT_OPEN,该功能未开放
-define(ERR_TREASBOX_SYS_NOT_OPEN,118012). %%_LANG_BOX_GOLD_NOT_OPEN,该功能未开放
-define(ERR_TREASBOX_MAX_SILVER_BOX_TIMES,118013). %%_LANG_BOX_MAX_SILVER_BOX_TIMES,使用钱币打老虎次数已满
-define(ERR_TREASBOX_OPEN_NOT_ENOUGH_MONEY,118014). %%_LANG_BOX_OPEN_NOT_ENOUGH_MONEY,你元宝或钱币不足，神游三界/月光宝盒已经中断
-define(ERR_TREASBOX_OPEN_NOT_GOLD,118015). %%_LANG_BOX_OPEN_NOT_GOLD,你元宝不足，神游三界/月光宝盒已经中断
-define(ERR_TREASBOX_OPEN_NOT_SILVER,118016). %%_LANG_BOX_OPEN_NOT_SILVER,你钱币不足，神游三界/月光宝盒已经中断
-define(ERR_TREASBOX_NO_BOX_POS,118017). %%_LANG_BOX_OPEN_NO_BOX_POS,你临时仓库没有足够的空间，无法攻击，请整理或提取物品
-define(ERR_TREASBOX_GET_NOT_GOODS_ID,118018). %%_LANG_BOX_GET_NOT_GOODS_ID_ERROR,请选择临时仓库物品再提取
-define(ERR_TREASBOX_GET_NO_GOODS_EXISTS,118019). %%_LANG_BOX_GET_NOT_GOODS_ERROR,临时仓库没有物品可提取
-define(ERR_TREASBOX_GET_BAG_FULL,118020). %%抱歉，背包空间不足，拾取失败
-define(ERR_TREASBOX_NO_NEED_MERGE,118021). %% 临时仓库为空，无需再整理
-define(ERR_TREASBOX_LEVEL_UPGRADE_FULL_LEVEL,118022). %%已经满级，不需要再升级
-define(ERR_TREASBOX_OPEN_NO_KEY, 118023). %%月光钥匙不足

%% ====================================================================
%% API functions
%% ====================================================================
handle(Info,_State) ->
    handle(Info).

handle({_, ?TREASBOX, ?TREASBOX_SHOW,_,_,_,_}=Info) ->
    do_treasbox_show(Info);
handle({_, ?TREASBOX, ?TREASBOX_OPEN,_,_,_,_}=Info) ->
    do_treasbox_open(Info);
handle({_, ?TREASBOX, ?TREASBOX_GET,_,_,_,_}=Info) ->
    do_treasbox_get(Info);
handle({_, ?TREASBOX, ?TREASBOX_UPGRADE,_,_,_,_}=Info) ->
    do_treasbox_upgrade(Info);

%% 神游三界/月光宝盒功能配置变化，需要通知当前在线玩家
handle({box_fun_config_change}) ->
    do_box_fun_config_change();

handle({erase_role_treasbox_info,RoleID}) ->
    erase_role_treasbox_info(RoleID);

%% GM清理钱币开箱子次数
handle({clear_remain_silver_times,RoleID}) ->
    case get_role_treasbox_info(RoleID) of
        {ok, RefiningBoxInfo} ->
            set_role_treasbox_info(RoleID,RefiningBoxInfo#r_role_box{fee_times=0});
        _ ->
            ignore
    end;

handle(Info) ->
    ?ERROR_MSG("~w, unrecognize msg: ~w", [?MODULE,Info]).


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%% @doc 初始化角色refining box信息
init_role_treasbox_info(RoleID, RefiningBoxInfo) ->
    case RefiningBoxInfo of
        undefined ->
            ignore;
        _ ->
            erlang:put({?role_treasbox, RoleID}, RefiningBoxInfo)
    end.
%% @doc 获取角色refining box信息
get_role_treasbox_info(RoleID) ->
    case erlang:get({?role_treasbox, RoleID}) of
        undefined ->
            {error, not_found};
        RefiningBoxInfo ->
            {ok,RefiningBoxInfo}
    end.
%% @doc 清除角色refining box信息
erase_role_treasbox_info(RoleID) ->
    erlang:erase({?role_treasbox, RoleID}).

%% @doc 设置角色refining box信息
t_set_role_treasbox_info(RoleID, RefiningBoxInfo) ->
    common_role:update_role_id_list_in_transaction(RoleID, ?role_treasbox, ?role_treasbox_copy),
    erlang:put({?role_treasbox, RoleID}, RefiningBoxInfo).

%% @doc 设置角色refining box信息
set_role_treasbox_info(RoleID, RefiningBoxInfo) ->
    TransFun = fun() ->
                   t_set_role_treasbox_info(RoleID,RefiningBoxInfo)
           end,
    case common_transaction:t( TransFun ) of
        {atomic, _} ->
            ok;
        {aborted, Error} ->
            ?ERROR_MSG("set_role_treasbox_info, error: ~w", [Error]),
            error
    end.



do_treasbox_show({Unique, Module, Method, DataIn, RoleID, PID, _Line}=InterfaceInfo)->
    #m_treasbox_show_tos{op_type=OpType} = DataIn,
    case catch check_do_treasbox_show(RoleID,DataIn) of
        {ok,?BOX_OP_TYPE_SUB_FUN,IsBoxOpen}-> %%查询功能是否开放
            R2 = #m_treasbox_show_toc{op_type=OpType,is_open=IsBoxOpen},
            ?UNICAST_TOC(R2);
        
        {ok,?BOX_OP_TYPE_SHOW_LOG,IsBoxOpen}-> %%查询日志
            do_treasbox_show_log(RoleID,InterfaceInfo,IsBoxOpen);
        
        {ok,?BOX_OP_TYPE_FUN,IsBoxOpen}-> %%查看神游三界/月光宝盒物品列表
            do_treasbox_show_list(RoleID,InterfaceInfo,IsBoxOpen);
        
        {ok,?BOX_OP_TYPE_QUERY,BoxGoodsList}-> %%查看临时仓库
            R2 = #m_treasbox_show_toc{op_type=OpType,is_open=true,box_list=BoxGoodsList},
            ?UNICAST_TOC(R2);
        {ok,?BOX_OP_TYPE_MERGE,RoleBox}-> %%整理临时仓库
            do_treasbox_merge(InterfaceInfo,RoleBox);
        {error,ErrCode,Reason}->
            R2 = #m_treasbox_show_toc{op_type=OpType,err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

assert_goodsid_list_valid([],_RoleBox)->
    ok;
assert_goodsid_list_valid(GoodsIdList,RoleBox)->
    lists:foreach( 
      fun(GoodsId)-> 
              case lists:keyfind(GoodsId,#p_goods.id,RoleBox#r_role_box.all_list) of
                  false ->
                      ?THROW_ERR( ?ERR_TREASBOX_GET_NO_GOODS );
                  _ ->
                      next
              end
      end , GoodsIdList).

assert_get_role_box_info(RoleBase)->
    #p_role_base{role_id=RoleID,faction_id=FactionID} = RoleBase,
    case get_role_treasbox_info(RoleID) of
        {ok,RoleBoxInfo} ->
            RoleBoxInfo;
        _ ->
            %% 以当前时间开始创建箱子记录
            RoleBoxInfo=#r_role_box{
                                    role_id = RoleID,
                                    faction_id = FactionID,
                                    start_time = common_tool:now(),
                                    end_time = 0,
                                    all_list = [],
                                    log_list = [],fee_times = 0},
            set_role_treasbox_info(RoleID, RoleBoxInfo)
    end,
    {ok,RoleBoxInfo}.

do_treasbox_show_log(RoleID,InterfaceInfo,IsBoxOpen)->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    {ok,RoleBoxInfo} = assert_get_role_box_info(RoleBase),
    RemainSilverTimes = remain_silver_box_times(RoleBoxInfo#r_role_box.remain_times,RoleBoxInfo#r_role_box.end_time),
    
    Msg = {do_treasbox_show_log,InterfaceInfo,RemainSilverTimes,IsBoxOpen},
    send_fb_manager(Msg).


do_treasbox_show_list(RoleID,InterfaceInfo,IsBoxOpen)->
    {ok, #p_role_attr{category=Category, level=Level}} = mod_map_role:get_role_attr(RoleID),
    {ok, RoleBase = #p_role_base{sex=Sex}} = mod_map_role:get_role_base(RoleID),
    {ok,#r_role_box{remain_times = RemainOpenTimes,end_time=EndTime,box_level=BoxLevel,box_score=BoxScore}} = assert_get_role_box_info(RoleBase),
    RemainSilverTimes = remain_silver_box_times(RemainOpenTimes,EndTime),
    Msg = {do_treasbox_show_list,InterfaceInfo,RemainSilverTimes,IsBoxOpen,Category,Level,Sex,BoxLevel,BoxScore},
    send_fb_manager(Msg).

do_treasbox_merge(InterfaceInfo,RoleBox)->
    {Unique, Module, Method, DataIn, RoleID, PID, _Line}=InterfaceInfo,
    #m_treasbox_show_tos{op_type=OpType} = DataIn,
    TransFun = fun() ->
                       t_treasbox_merge(RoleID,RoleBox)
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,NewRoleBox}} ->
            R2 = do_treasbox_merge_2(OpType,NewRoleBox),
            ?UNICAST_TOC(R2);
        {aborted, AbortErr} ->
            {error,ErrCode,Reason} = parse_aborted_err(AbortErr),
            R2 = #m_treasbox_show_toc{op_type=OpType,err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

do_treasbox_merge_2(OpType,NewRoleBox) ->
    SortBoxGoodsList = 
        lists:sort(
          fun(#p_goods{id = GoodsIdA},#p_goods{id = GoodsIdB}) ->
                  GoodsIdA < GoodsIdB
          end,NewRoleBox#r_role_box.all_list),
    #m_treasbox_show_toc{
                         op_type = OpType,
                         page_type = 0,
                         is_open = true,
                         box_list = SortBoxGoodsList}.

check_do_treasbox_show(RoleID,DataIn)->
    #m_treasbox_show_tos{op_type=OpType} = DataIn,
    [IsBoxOpen] = ?find_config(is_box_open),
    if
        OpType=:=?BOX_OP_TYPE_SUB_FUN orelse OpType=:=?BOX_OP_TYPE_SHOW_LOG->
            {ok,OpType,IsBoxOpen};
        true->
            assert_box_open(),
            case OpType of
                ?BOX_OP_TYPE_FUN->
                    {ok,OpType,IsBoxOpen};
                ?BOX_OP_TYPE_QUERY->
                    check_do_treasbox_show_2(OpType,RoleID,DataIn);
                ?BOX_OP_TYPE_MERGE->
                    check_do_treasbox_show_3(OpType,RoleID)
            end
    end.
    

%%检查查询临时仓库
check_do_treasbox_show_2(OpType,RoleID,DataIn)->
    case get_role_treasbox_info(RoleID) of
        {ok,RoleBox} ->
            next;
        _ ->
            RoleBox = null,
            erlang:throw({ok,OpType,[]})
    end,
    
    #m_treasbox_show_tos{page_type=PageType} = DataIn,
    
    case lists:member(PageType,[?BOX_PAGE_TYPE_0,?BOX_PAGE_TYPE_1,?BOX_PAGE_TYPE_2,?BOX_PAGE_TYPE_3,?BOX_PAGE_TYPE_4]) of
        true ->
            next;
        _ ->
            ?THROW_ERR( ?ERR_INTERFACE_ERR )
    end,
    case erlang:is_list(RoleBox#r_role_box.all_list) of
        true ->
            next;
        _ ->
            erlang:throw({ok,OpType,[]})
    end,
    BoxGoodsList =  
        lists:foldl(
          fun(BoxGoods,AccBoxGoodsList) ->
                  if PageType =:= ?BOX_PAGE_TYPE_1 andalso BoxGoods#p_goods.type =:= ?BOX_PAGE_TYPE_1 ->
                         [BoxGoodsBaseItemInfoT] = common_config_dyn:find_item(BoxGoods#p_goods.typeid),
                         if BoxGoodsBaseItemInfoT#p_item_base_info.kind =:= 4 ->
                                AccBoxGoodsList;
                            true ->
                                [BoxGoods|AccBoxGoodsList]
                         end;
                     PageType =:= ?BOX_PAGE_TYPE_2 andalso BoxGoods#p_goods.type =:= ?BOX_PAGE_TYPE_2 ->
                         [BoxGoods|AccBoxGoodsList];
                     PageType =:= ?BOX_PAGE_TYPE_3 andalso BoxGoods#p_goods.type =:= ?BOX_PAGE_TYPE_3 ->
                         [BoxGoods|AccBoxGoodsList];
                     PageType =:= ?BOX_PAGE_TYPE_0 ->
                         [BoxGoods|AccBoxGoodsList];
                     true ->
                         case PageType =:= ?BOX_PAGE_TYPE_4 andalso BoxGoods#p_goods.type =:= ?BOX_PAGE_TYPE_1 of
                             true ->
                                 [BoxGoodsBaseItemInfo] = common_config_dyn:find_item(BoxGoods#p_goods.typeid),
                                 if BoxGoodsBaseItemInfo#p_item_base_info.kind =:= 4 ->
                                        [BoxGoods|AccBoxGoodsList];
                                    true ->
                                        AccBoxGoodsList
                                 end;
                             _ ->
                                 AccBoxGoodsList
                         end
                  end 
          end,[],RoleBox#r_role_box.all_list), 
    
    SortBoxGoodsList = 
        lists:sort(
          fun(#p_goods{id = GoodsIdA},#p_goods{id = GoodsIdB}) ->
                  GoodsIdA < GoodsIdB
          end,BoxGoodsList),
    {ok,OpType,SortBoxGoodsList}.

%%整理背包的检查
check_do_treasbox_show_3(OpType,RoleID)->
    case get_role_treasbox_info(RoleID) of
        {ok,RoleBox} ->
            next;
        _ ->
            RoleBox = null,
            ?THROW_ERR( ?ERR_TREASBOX_ROLE_NOT_ONLINE )
    end,
    
    case erlang:is_list(RoleBox#r_role_box.all_list) andalso RoleBox#r_role_box.all_list =/= [] of
        true ->
            next;
        _ ->
            ?THROW_ERR( ?ERR_TREASBOX_NO_NEED_MERGE )
    end,
    {ok,OpType,RoleBox}.


do_treasbox_open({Unique, Module, Method, DataIn, RoleID, PID, _Line}=InterfaceInfo)->
    #m_treasbox_open_tos{op_fee_type=OpFeeType,num_type=NumType} = DataIn,
    case catch check_do_treasbox_open(RoleID,DataIn) of
        {ok,RoleBox,BoxOpenFee} ->
            Times = get_times_by_num_type(NumType),
            do_treasbox_open_2(InterfaceInfo,RoleBox,BoxOpenFee,Times);
        {error,ErrCode,Reason}->
            R2 = #m_treasbox_open_toc{op_fee_type=OpFeeType,num_type=NumType,err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

%% 正常的立即开箱子
do_treasbox_open_2(InterfaceInfo,RoleBox,BoxOpenFee,Times) ->
    {Unique, Module, Method, DataIn, RoleID, PID, _Line} = InterfaceInfo,
    #m_treasbox_open_tos{op_fee_type=OpFeeType,num_type=NumType} = DataIn,
    TransFun = fun() ->
                       t_treasbox_open(RoleID,DataIn,RoleBox,BoxOpenFee,Times)
               end,
    case common_transaction:t( TransFun ) of
        {atomic,{ok,RoleAttr2,RoleBox2,AwardList2,BcTypeIdList,OpenTimes,TotalAddScore,MulitScore}} ->
            do_treasbox_open_3(InterfaceInfo,RoleAttr2,RoleBox2,AwardList2,BcTypeIdList,BoxOpenFee,Times,OpenTimes,TotalAddScore,MulitScore);
        {aborted, AbortErr} -> 
            {error,ErrCode,Reason} = parse_aborted_err(AbortErr),
            R2 = #m_treasbox_open_toc{op_fee_type=OpFeeType,num_type=NumType,err_code=ErrCode,reason=Reason},
            ?UNICAST_TOC(R2)
    end.

check_do_treasbox_open(RoleID,DataIn)->
    assert_box_open(),
    #m_treasbox_open_tos{op_fee_type=OpFeeType} = DataIn,
    case get_role_treasbox_info(RoleID) of
        {ok,RoleBox} ->
            next;
        _ ->
            RoleBox = null,
            ?THROW_ERR( ?ERR_TREASBOX_ROLE_NOT_ONLINE )
    end,
    BoxOpenFee = get_box_fee(OpFeeType),
    {ok,RoleBox,BoxOpenFee}.

do_treasbox_get({Unique, Module, Method, DataIn, RoleID, PID, _Line})->
    #m_treasbox_get_tos{is_get_all=IsGetAll,goods_ids=GoodsIds} = DataIn,
    case catch check_do_treasbox_get(RoleID,DataIn) of
        {ok,RoleBox} ->
            %% 提取物品放入背包
            TransFun = fun() ->
                               t_treasbox_get(RoleID,DataIn,RoleBox)
                       end,
            case common_transaction:t( TransFun ) of
                {atomic,{ok,RtnGoodsIdList,TmpDeptGoodsList,AwardGoodsList}} ->
                    do_treasbox_get3(RoleID,TmpDeptGoodsList,AwardGoodsList),
                    R2 = #m_treasbox_get_toc{is_get_all=IsGetAll,goods_ids = RtnGoodsIdList,award_list = TmpDeptGoodsList};
                {aborted, AbortErr} ->
                    {error,ErrCode,Reason} = parse_aborted_err(AbortErr),
                    R2 = #m_treasbox_get_toc{err_code=ErrCode,reason=Reason}
            end;
        {error,ErrCode,Reason}->
            R2 = #m_treasbox_get_toc{is_get_all=IsGetAll,goods_ids=GoodsIds,err_code=ErrCode,reason=Reason}
    end,
    ?UNICAST_TOC( R2 ).

check_do_treasbox_get(RoleID,DataIn)->
    #m_treasbox_get_tos{is_get_all=IsGetAll,goods_ids=GoodsIdList} = DataIn,
    assert_box_open(),
    case get_role_treasbox_info(RoleID) of
        {ok,RoleBox} ->
            RoleBox;
        _ ->
            RoleBox = null,
            ?THROW_ERR(?ERR_TREASBOX_GET_NO_GOODS_EXISTS)
    end,
    if
        IsGetAll=:=true->
            next;
        true->
            case erlang:is_list(GoodsIdList) andalso  erlang:length(GoodsIdList) > 0  of
                true ->
                    next;
                _ ->
                    ?THROW_ERR( ?ERR_TREASBOX_GET_NOT_GOODS_ID )
            end
    end,
    assert_goodsid_list_valid(GoodsIdList,RoleBox),
    
    {ok,RoleBox}.

t_treasbox_get(RoleID,DataIn,RoleBox) ->
    #m_treasbox_get_tos{is_get_all=IsGetAll,goods_ids=GoodsIdList} = DataIn,
    assert_goodsid_list_valid(GoodsIdList,RoleBox),
    #r_role_box{all_list=BoxAllList} = RoleBox,
    
    {TmpDeptGoodsList,AllList2} = 
        case IsGetAll of
            true->
                {BoxAllList,[]};
            _ ->
                lists:foldl(
                  fun(GoodsId,{AccPGoodsList,AccAllList}) ->
                          AccPGoods = lists:keyfind(GoodsId,#p_goods.id,AccAllList),
                          {[AccPGoods|AccPGoodsList],
                           lists:keydelete(GoodsId,#p_goods.id,AccAllList)}
                  end,{[],BoxAllList},GoodsIdList)
        end,
    {ok,AwardGoodsList} = mod_bag:create_goods_by_p_goods(RoleID,TmpDeptGoodsList),
    t_set_role_treasbox_info(RoleID,RoleBox#r_role_box{all_list = AllList2}),
    
    
    case IsGetAll of
        true->
            RtnGoodsIdList = [Id||#p_goods{id=Id}<-TmpDeptGoodsList];
        _ ->
            RtnGoodsIdList = GoodsIdList
    end,
    
    {ok,RtnGoodsIdList,TmpDeptGoodsList,AwardGoodsList}.
 
    
do_treasbox_get3(RoleID,TmpDeptGoodsList,AwardGoodsList)->
    ?TRY_CATCH( common_misc:update_goods_notify({role, RoleID}, AwardGoodsList) ),
    
    [ common_item_logger:log(RoleID,PGoods,?LOG_ITEM_TYPE_BOX_RESTORE_P_CHU_SHOU) ||PGoods<-TmpDeptGoodsList ],
    [ common_item_logger:log(RoleID,PGoods,?LOG_ITEM_TYPE_OPEN_BOX_HUO_DE) ||PGoods<-TmpDeptGoodsList ],
    ok.

do_treasbox_upgrade({Unique, Module, Method, _DataIn, RoleID, PID, _Line})->
	TransFun = fun()-> t_treasbox_upgrade(RoleID) end,
	case common_transaction:t( TransFun ) of
		{atomic, {ok,RemainBoxScore,NewBoxLevel}} ->
			R2 = #m_treasbox_upgrade_toc{box_level=NewBoxLevel,box_score=RemainBoxScore},
			?UNICAST_TOC(R2);
		{aborted, AbortErr} ->
			{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
			?UNICAST_TOC(#m_treasbox_upgrade_toc{err_code=ErrCode,reason=Reason})
	end.

t_treasbox_upgrade(RoleID) ->
	{ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	{ok,RoleBoxInfo} = assert_get_role_box_info(RoleBase),
	#r_role_box{box_level=BoxLevel,box_score=BoxScore} = RoleBoxInfo,
	[FullLevel] = ?find_config(full_level),
	case BoxLevel >= FullLevel of
		true ->
			?THROW_ERR(?ERR_TREASBOX_LEVEL_UPGRADE_FULL_LEVEL);
		false ->
			next
	end,
	[LevelScoreConf] = ?find_config(level_score),
	case lists:keyfind(BoxLevel, 1, LevelScoreConf) of
		false ->
			?THROW_SYS_ERR();
		{_,NeedRoleLevel,NeedBoxScore} ->
			NewBoxLevel = BoxLevel+1,
			ErrorMsg = lists:concat(["升级失败，飞云探龙手提升到",NewBoxLevel,"级需要人物等级",NeedRoleLevel,"级，神游积分",NeedBoxScore]), 
			case RoleAttr#p_role_attr.level >= NeedRoleLevel of
				true ->
					next;
				false ->
					?THROW_ERR_REASON(ErrorMsg)
			end,
			RemainBoxScore = BoxScore - NeedBoxScore,
			case RemainBoxScore < 0 of
				true ->
					?THROW_ERR_REASON(ErrorMsg);
				false ->
					next
			end,
			NewRoleBoxInfo = RoleBoxInfo#r_role_box{box_level=NewBoxLevel,box_score=RemainBoxScore},
			t_set_role_treasbox_info(RoleID,NewRoleBoxInfo),
			{ok,RemainBoxScore,NewBoxLevel}
	end.

%% 神游三界/月光宝盒功能配置变化，需要通知当前在线玩家
do_box_fun_config_change() ->
    [IsBoxOpen] = ?find_config(is_box_open),
    R2 = #m_treasbox_show_toc{op_type = ?BOX_OP_TYPE_SUB_FUN,is_open = IsBoxOpen},
    ?TRY_CATCH(common_misc:chat_broadcast_to_world(?TREASBOX,?TREASBOX_SHOW,R2)),
    ok.

get_config_name() ->
    treasbox.
%% get_config_name() ->
%%     case common_config:get_opened_days() > 3 of
%%         true ->
%%             treasbox;
%%         false ->
%%             treasbox_3day
%%     end.



%%将消息发送到mod_treasbox_manager
send_fb_manager(Info)->
    case global:whereis_name( mod_treasbox_manager ) of
        undefined->
            ?ERROR_MSG("send_fb_manager error",[]);
        PID->
            PID ! Info
    end.

%%解析错误码
parse_aborted_err(AbortErr)->
    case AbortErr of
        {error,ErrCode,_Reason} when is_integer(ErrCode) ->
            AbortErr;
        {bag_error,{not_enough_pos,_BagID}}->
            {error,?ERR_TREASBOX_GET_BAG_FULL,undefined};
        {bag_error,num_not_enough}->
            {error,?ERR_TREASBOX_GET_BAG_FULL,undefined};
        {error,AbortReason} when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        AbortReason when is_binary(AbortReason) ->
            {error,?ERR_OTHER_ERR,AbortReason};
        _ ->
            ?ERROR_MSG(" aborted,AbortErr=~w,stack=~w",[AbortErr,erlang:get_stacktrace()]),
            {error,?ERR_SYS_ERR,undefined}
    end.

t_treasbox_merge(RoleID,RoleBox) ->
    {[],AllList} = 
        lists:foldl(
          fun(BoxGoods,{AccOldAllList,AccNewAllList}) ->
                  case lists:keyfind(BoxGoods#p_goods.id,#p_goods.id,AccOldAllList) of
                      false ->
                          {AccOldAllList,AccNewAllList};
                      _ ->
                          AccOldAllList2 = lists:keydelete(BoxGoods#p_goods.id,#p_goods.id,AccOldAllList),
                          %% 是否可合并
                          IsMergeFlag = 
                              if BoxGoods#p_goods.type =:= ?TYPE_EQUIP ->
                                     false;
                                 BoxGoods#p_goods.type =:= ?TYPE_ITEM ->
                                     [BoxGoodsBaseInfo] = common_config_dyn:find_item(BoxGoods#p_goods.typeid),
                                     case BoxGoodsBaseInfo#p_item_base_info.is_overlap =:= 1 
                                                                                andalso BoxGoodsBaseInfo#p_item_base_info.usenum =:= 1 of
                                         true ->
                                             true;
                                         _ ->
                                             false
                                     end;
                                 true ->
                                     true
                              end,
                          case IsMergeFlag =:= true andalso BoxGoods#p_goods.current_num < ?MAX_OVER_LAP of
                              true -> %% 物品可以合并
                                  case lists:keyfind(BoxGoods#p_goods.typeid,#p_goods.typeid,AccOldAllList2) of
                                      false ->
                                          {AccOldAllList2,[BoxGoods|AccNewAllList]};
                                      _ ->
                                          {AccOldAllList3,MergeBoxGoodsList}= 
                                              lists:foldl(
                                                fun(BoxGoodsT,{AccAccOldAllList,AccMergeBoxGoodsList}) ->
                                                        if BoxGoodsT#p_goods.typeid =:= BoxGoods#p_goods.typeid ->
                                                               AccAccOldAllList2 = lists:keydelete(BoxGoodsT#p_goods.id,#p_goods.id,AccAccOldAllList),
                                                               {AccAccOldAllList2,[BoxGoodsT|AccMergeBoxGoodsList]};
                                                           true ->
                                                               {AccAccOldAllList,AccMergeBoxGoodsList}
                                                        end
                                                end,{AccOldAllList2,[BoxGoods]},AccOldAllList2),
                                          {AccOldAllList3,lists:append([get_merge_p_goods(MergeBoxGoodsList),AccNewAllList])}
                                  end;
                              _ ->
                                  {AccOldAllList2,[BoxGoods|AccNewAllList]}
                          end
                  end
          end,{RoleBox#r_role_box.all_list,[]},RoleBox#r_role_box.all_list),
    NewRoleBox=RoleBox#r_role_box{all_list = AllList},
	t_set_role_treasbox_info(RoleID,NewRoleBox),
    {ok,NewRoleBox}.


%% 根据物品列表合并物品 typeid相关的物品列表
%% 此参数必须是同类型的物品列表，不区分绑定和不绑定
get_merge_p_goods([]) ->
    [];
get_merge_p_goods(BoxGoodsList) ->
    {BindGoodsList,BindGoodsNumber,NotBindGoodsList,NotBindGoodsNumber}=
        lists:foldl(
          fun(Goods,{AccBindGoodsList,AccBindGoodsNumber,AccNotBindGoodsList,AccNotBindGoodsNumber}) ->
                  case Goods#p_goods.bind =:= true of
                      true ->
                          {[Goods|AccBindGoodsList],AccBindGoodsNumber + Goods#p_goods.current_num,
                           AccNotBindGoodsList,AccNotBindGoodsNumber};
                      _ ->
                          {AccBindGoodsList,AccBindGoodsNumber,
                           [Goods|AccNotBindGoodsList],AccNotBindGoodsNumber + Goods#p_goods.current_num}
                  end
          end,{[],0,[],0},BoxGoodsList),
    BindList = 
        if BindGoodsList =/= [] ->
               [BindGoods | _TBindGoods] = BindGoodsList,
               case BindGoodsNumber rem ?MAX_OVER_LAP of
                   0 -> 
                       lists:duplicate(BindGoodsNumber div ?MAX_OVER_LAP, BindGoods#p_goods{current_num=?MAX_OVER_LAP});
                   RemBindNumber -> 
                       [BindGoods#p_goods{current_num=RemBindNumber}|
                                             lists:duplicate(BindGoodsNumber div ?MAX_OVER_LAP,BindGoods#p_goods{current_num=?MAX_OVER_LAP})]
               end;
           true ->
               []
        end,
    BindList2 =
        case BindList =/= [] of
            true ->
                {_,BindListT} = 
                    lists:foldl(
                      fun(BindGoodsT,{AccBindIndex,AccBindList}) ->
                              OldBindGoods = lists:nth(AccBindIndex,BindGoodsList),
                              {AccBindIndex + 1,[BindGoodsT#p_goods{id = OldBindGoods#p_goods.id}|AccBindList]}
                      end,{1,[]},BindList),
                BindListT;
            _ ->
                BindList
        end, 
    NotBindList = 
        if NotBindGoodsList =/= [] ->
               [NotBindGoods | _TNotBindGoods] = NotBindGoodsList,
               case NotBindGoodsNumber rem ?MAX_OVER_LAP of
                   0 -> 
                       lists:duplicate(NotBindGoodsNumber div ?MAX_OVER_LAP, NotBindGoods#p_goods{current_num=?MAX_OVER_LAP});
                   RemNotBindNumber -> 
                       [NotBindGoods#p_goods{current_num=RemNotBindNumber}|
                                                lists:duplicate(NotBindGoodsNumber div ?MAX_OVER_LAP,NotBindGoods#p_goods{current_num=?MAX_OVER_LAP})]
               end;
           true ->
               []
        end,
    NotBindList2 = 
        case NotBindList =/= [] of
            true ->
                {_,NotBindListT} = 
                    lists:foldl(
                      fun(NotBindGoodsT,{AccNotBindIndex,AccNotBindList}) ->
                              OldNotBindGoods = lists:nth(AccNotBindIndex,NotBindGoodsList),
                              {AccNotBindIndex + 1,[NotBindGoodsT#p_goods{id = OldNotBindGoods#p_goods.id}|AccNotBindList]}
                      end,{1,[]},NotBindList),
                NotBindListT;
            _ ->
                NotBindList
        end,
    lists:append([BindList2,NotBindList2]).


%% 检查开箱子类型，并返回该类型的详细消耗信息
%% @return BoxOpenFee = {MoneyType,CostMoney}
get_box_fee(OpFeeType) ->
    [BoxFeeList] = ?find_config(box_fee),
    {OpFeeType,BoxOpenFee} = lists:keyfind(OpFeeType,1,BoxFeeList),
    BoxOpenFee.


assert_box_open() ->
    case ?find_config(is_box_open) of
        [IsBoxOpen] when IsBoxOpen =:= true ->
            next;
        _ ->
            ?THROW_ERR( ?ERR_TREASBOX_SYS_NOT_OPEN )
    end.

get_times_by_num_type(1) -> 1;
get_times_by_num_type(2) -> 10;
get_times_by_num_type(3) -> 50;
get_times_by_num_type(_) -> 1.



t_treasbox_open(RoleID, DataIn, RoleBox, BoxOpenFee,Times) ->
    #m_treasbox_open_tos{op_fee_type=OpFeeType} = DataIn,
    [MaxBoxGoodsNumber] = ?find_config(max_box_goods_number),
    %% 允许一次溢出
    case MaxBoxGoodsNumber >= (erlang:length(RoleBox#r_role_box.all_list) + erlang:length(RoleBox#r_role_box.cur_list)) of
        true ->
            {ok, RoleAttr} = mod_map_role:get_role_attr(RoleID),
			#r_role_box{
                fee_times=UseSilverOpenTimes,
                end_time=LastBoxingTime,
                box_level=BoxLevel,
                remain_times = RemainOpenTimes}=RoleBox,
            %% end_time只记录钱币开箱子时间
            BoxingTime =
                case BoxOpenFee of
                    {silver_any,_NeedMoney} ->
                        common_tool:now();
                    _ ->
                        RoleBox#r_role_box.end_time
                end,
            {ok,RoleAttr2,OpenTimes,BindNum,NewUseSilverOpenTimes} = t_treasbox_open_fee(RoleID,RoleAttr,BoxOpenFee,Times,UseSilverOpenTimes,RemainOpenTimes,LastBoxingTime, OpFeeType),
            {ok,CurBoxGoodsList,BcTypeIdList} = generate_box_goods(RoleID,OpFeeType,OpenTimes,BindNum,BoxLevel),
            NewRemainOpenTimes = RemainOpenTimes - (NewUseSilverOpenTimes - UseSilverOpenTimes),
            {ok,RoleBox3,AwardList2} = get_restore_new_role_box(RoleBox,NewUseSilverOpenTimes,CurBoxGoodsList,BoxingTime, NewRemainOpenTimes),
			{ok,RoleBox4,TotalAddScore,MulitScore} = t_cacl_open_score(OpFeeType,RoleBox3,OpenTimes),
            {ok,RoleBox5} = t_treasbox_merge(RoleID,RoleBox4),
            {ok,RoleAttr2,RoleBox5,AwardList2,BcTypeIdList,OpenTimes,TotalAddScore,MulitScore};
        _ ->
            ?THROW_ERR( ?ERR_TREASBOX_NO_BOX_POS )
    end.

%% 是否可升级
treasbox_can_upgrade(RoleLevel,BoxLevel,BoxScore) ->
	[FullLevel] = ?find_config(full_level),
	case BoxLevel >= FullLevel of
		true ->
			false;
		false ->
			[LevelScoreConf] = ?find_config(level_score),
			case lists:keyfind(BoxLevel, 1, LevelScoreConf) of
				false ->
					false;
				{_,NeedRoleLevel,NeedBoxScore} ->
					RoleLevel >= NeedRoleLevel andalso BoxScore >= NeedBoxScore
			end
	end.

%% 计算开箱子获得的积分
t_cacl_open_score(OpFeeType,RoleBox,OpenTimes) ->
	[OpenScoreConf] = ?find_config(treasbox_open_score),
	case lists:keyfind(OpFeeType, 1, OpenScoreConf) of
		false ->
			WeightList = null,
			?THROW_SYS_ERR();
		{_,WeightList} ->
			next
	end,
	AddScore = lists:foldl(fun(_,Acc)->
								   Acc+common_tool:random_element(WeightList)
						   end,0,lists:seq(1,OpenTimes)),
	[{Weight,OpenScoreMulti}] = ?find_config(treasbox_open_score_multi),
	TotalAddScore = 
		case common_tool:random(1,10000) =< Weight of
			true ->
				MulitScore = OpenScoreMulti,
				OpenScoreMulti * AddScore;
			false ->
				MulitScore = 1,
				AddScore
		end,
	{ok,RoleBox#r_role_box{box_score=RoleBox#r_role_box.box_score+TotalAddScore},TotalAddScore,MulitScore}.

t_treasbox_open_fee(RoleID,RoleAttr,{MoneyType,NeedMoney},Times,UseSilverOpenTimes,_RemainOpenTimes,_LastBoxingTime, _OpFeeType) when MoneyType=:=gold_unbind->
    #p_role_attr{gold = RoleGold} = RoleAttr,
    case can_use_gold() of
        true ->
            next;
        false ->
            ?THROW_ERR( ?ERR_TREASBOX_GOLD_NOT_OPEN )
    end,
    {DeductMoney,OpenTimes} = calc_deduct_money(MoneyType,RoleGold,NeedMoney,Times),
    {ok,RoleAttr2} = t_deduct_open_money(MoneyType,DeductMoney,RoleID,?CONSUME_TYPE_GOLD_OPEN_BOX),
    {ok,RoleAttr2, OpenTimes,0,UseSilverOpenTimes};

t_treasbox_open_fee(RoleID,RoleAttr,{MoneyType,NeedMoney},Times,UseSilverOpenTimes,RemainOpenTimes,LastBoxingTime, _OpFeeType) when MoneyType=:=silver_any->
    #p_role_attr{silver = RoleSivler, silver_bind = RoleSilverBind} = RoleAttr,
    {NewTimes,NewUseSilverOpenTimes} = 
        case common_time:time_to_date(LastBoxingTime) =:= common_time:time_to_date(common_tool:now()) of
            true ->
                case RemainOpenTimes > 0 of
                    true ->
                        AddUseSilverOpenTimes = erlang:min(Times,RemainOpenTimes),
                        {AddUseSilverOpenTimes,UseSilverOpenTimes+AddUseSilverOpenTimes};
                    false ->
                        ?THROW_ERR( ?ERR_TREASBOX_MAX_SILVER_BOX_TIMES )
                end;
            false ->
                [MaxSilverBoxTimes] = ?find_config(max_silver_box_times),
                AddUseSilverOpenTimes = erlang:min(MaxSilverBoxTimes,Times),
                {AddUseSilverOpenTimes,AddUseSilverOpenTimes}
        end,
    {DeductMoney,OpenTimes} = calc_deduct_money(MoneyType,RoleSivler+RoleSilverBind,NeedMoney,NewTimes),
    {ok,RoleAttr2} = t_deduct_open_money(MoneyType,DeductMoney,RoleID,?CONSUME_TYPE_SILVER_OPEN_BOX),
    {ok,RoleAttr2,OpenTimes,OpenTimes,UseSilverOpenTimes+erlang:min((NewUseSilverOpenTimes-UseSilverOpenTimes),OpenTimes)};

%%根据需求优化, 当月光宝盒使用50次打开钥匙时,先扣除钥匙,再扣除元宝.........
t_treasbox_open_fee(RoleID,RoleAttr,{ItemType,ItemId},Times,UseSilverOpenTimes,_RemainOpenTimes,_LastBoxingTime, OpFeeType) when ItemType==key->
    % {ok, ItemNum} = mod_bag:get_goods_num_by_typeid(RoleID, ItemId),
    {ok, GoodsList} = mod_bag:get_goods_by_typeid(RoleID, ItemId, [1,2,3]),
    BindNum = mod_bag:get_bind_goods_num(GoodsList), 
    ItemNum = mod_bag:get_goods_num(GoodsList),

    GoldOpFeeType = OpFeeType - 6,
    {gold_unbind,NeedMoney} = get_box_fee(GoldOpFeeType),

    if
        ItemNum >= Times ->
            RoleAttr2 = RoleAttr,
            ok = mod_bag:use_item(RoleID, ItemId, Times, ?LOG_ITEM_TYPE_LOST_TREASURE_USE_KEY);
        true ->
            case Times == 50 of
                true -> 
                    GoldTimes = Times - ItemNum,
                    #p_role_attr{gold = RoleGold} = RoleAttr,
                    case can_use_gold() of
                        true -> next;
                        false -> ?THROW_ERR( ?ERR_TREASBOX_GOLD_NOT_OPEN )
                    end,
                    {DeductMoney,OpenTimes} = calc_deduct_money(gold_unbind,RoleGold,NeedMoney,GoldTimes),
                    case GoldTimes == OpenTimes of
                        true -> [];
                        false -> ?THROW_ERR( ?ERR_TREASBOX_OPEN_NOT_GOLD )
                    end,
                    ok = mod_bag:use_item(RoleID, ItemId, ItemNum, ?LOG_ITEM_TYPE_LOST_TREASURE_USE_KEY),
                    {ok,RoleAttr2} = t_deduct_open_money(gold_unbind,DeductMoney,RoleID,?CONSUME_TYPE_GOLD_OPEN_BOX);
                false -> 
                    RoleAttr2 = RoleAttr,
                    ?THROW_ERR( ?ERR_TREASBOX_OPEN_NO_KEY)
            end
    end,
    {ok, RoleAttr2, Times, BindNum, UseSilverOpenTimes};

t_treasbox_open_fee(_, _, _, _, _,_,_,_) ->
    ?ERROR_MSG("do_t_treasbox_open_fee error",[]),
    ?THROW_ERR( ?ERR_INTERFACE_ERR ).

%% return {DeductMoney,OpenTimes}
calc_deduct_money(MoneyType,RoleMoney,NeedMoney,Times) ->
    Fee = NeedMoney * Times,
    if RoleMoney < Fee ->
           OpenTimes = RoleMoney div NeedMoney,
           DeductGold = 
               case OpenTimes > 0 of
                   true ->
                       NeedMoney * OpenTimes;
                   false ->
                       case MoneyType of
                           silver_any->
                               ?THROW_ERR( ?ERR_TREASBOX_OPEN_NOT_SILVER );
                           _->
                               ?THROW_ERR( ?ERR_TREASBOX_OPEN_NOT_GOLD )
                       end
               end,
           {DeductGold,OpenTimes};
       true ->
           {Fee,Times}
    end.
    
%%扣除钱币/元宝
t_deduct_open_money(MoneyType,DeductMoney,RoleID,ConsumeType)->
    common_bag2:check_money_enough_and_throw(MoneyType,DeductMoney,RoleID),
    case common_bag2:t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeType) of
        {ok,RoleAttr2}->
            {ok,RoleAttr2};
        {error,gold_unbind}->
            ?THROW_ERR( ?ERR_TREASBOX_OPEN_NOT_GOLD );
        {error,gold_any}->
            ?THROW_ERR( ?ERR_TREASBOX_OPEN_NOT_GOLD );
        {error,silver_any}->
            ?THROW_ERR( ?ERR_TREASBOX_OPEN_NOT_SILVER );
        {error, Reason} ->
            ?THROW_ERR(?ERR_OTHER_ERR, Reason);
        _ ->
            ?THROW_ERR( ?ERR_TREASBOX_OPEN_NOT_ENOUGH_MONEY )
    end. 

%% 根据玩家的当前的箱子物品，放置到宝物空间记录操作
%% 返回放置好的玩家箱子记录
get_restore_new_role_box(RoleBox,NewUseSilverOpenTimes,CurGoodsList,BoxingTime, NewRemainOpenTimes)->
    #r_role_box{all_list = AllList,box_gid_index = BoxGIDIndex} = RoleBox,
    {NewCurList,NewBoxGIDIndex} =
        lists:foldl(
          fun(CurGoods,{AccNewCurList,AccIndex}) ->
                  {[CurGoods#p_goods{id = AccIndex} | AccNewCurList],AccIndex + 1}
          end,{[],BoxGIDIndex},CurGoodsList),
    NewAllList = lists:append(AllList,NewCurList),
    
    NewRoleBox= RoleBox#r_role_box{fee_flag = ?BOX_FEE_GOLD,
                                   fee_times = NewUseSilverOpenTimes,
                                   remain_times = NewRemainOpenTimes,
                                   all_list = NewAllList,
                                   end_time = BoxingTime,
                                   box_gid_index = NewBoxGIDIndex,
                                   cur_list = []},
    {ok,NewRoleBox,NewCurList}.


get_notify_goods_list(GoodsList, BcTypeIdList) ->
    lists:foldl(
      fun(AwardGoods, AccBcGoodsList) ->
              #p_goods{typeid=TypeId, current_num=Num} = AwardGoods,
              case lists:member(TypeId, BcTypeIdList) of
                  true ->
                      if AwardGoods#p_goods.type =:= ?TYPE_EQUIP ->
                              [AwardGoods|AccBcGoodsList];
                         true ->
                              case lists:keyfind(TypeId, #p_goods.typeid, AccBcGoodsList) of
                                  #p_goods{current_num=OldNum} ->
                                      lists:keyreplace(TypeId, #p_goods.typeid, AccBcGoodsList, AwardGoods#p_goods{current_num=Num+OldNum});
                                  false ->
                                      [AwardGoods|AccBcGoodsList]
                              end
                      end;
                  _ ->
                      AccBcGoodsList
              end
      end, [], GoodsList).

%% 箱子获得物品消息通知处理
do_treasbox_goods_notify(RoleID, AwardGoodsList, BcTypeIdList, NumType) ->
    {ok, #p_role_base{role_name=RoleName, faction_id=FactionId}=RoleBase} = mod_map_role:get_role_base(RoleID),
    Times = get_times_by_num_type(NumType),
    
    if Times > 1 ->
            Msg = common_misc:format_lang(?_LANG_BOX_BROADCAST_MSG, [common_misc:get_faction_color_name(FactionId),
                                                                     common_misc:get_role_name_color(RoleName, FactionId)]),
            common_broadcast:bc_send_msg_world([?BC_MSG_TYPE_CHAT], ?BC_MSG_TYPE_CHAT_WORLD, Msg);
       true ->
            ok
    end,
    %% 提取物品广播
    if BcTypeIdList =/= [] andalso BcTypeIdList =/= undefined ->
           AwardGoodsList2 = get_notify_goods_list(AwardGoodsList, BcTypeIdList),
           BCLeftMessage = common_tool:get_format_lang_resources(?_LANG_BOX_IN_BAG_SUCC_BC_LEFT,
                                                                 [common_misc:get_role_name_color(RoleName,FactionId)]),
           lists:foreach(
             fun(AwardGoods) ->
                     common_broadcast:bc_send_msg_world_include_goods([?BC_MSG_TYPE_CHAT],?BC_MSG_TYPE_CHAT_WORLD,BCLeftMessage,
                                                                      RoleID,common_tool:to_list(RoleBase#p_role_base.role_name),
                                                                      RoleBase#p_role_base.sex, [AwardGoods])
             end, AwardGoodsList2),
           ok;
       true ->
           ignore
    end.

is_box_pay_limit() ->
    case common_config_dyn:find_common(box_pay_limit) of
        [true]->
            true;
        _ ->
            false
    end.


%% 根据概率生成箱子物品
%% 返回 {ok,GoodsList,BcGoodsList}
%% GoodsList [p_goods,...]
%% BcGoodsList [typeId,...]
%% UnbindNum为不绑定的钥匙的个数
generate_box_goods(RoleID,OpFeeType,OpenTimes,BindNum,BoxLevel) ->
    %%ItemType = 1, 并且每次只生成一个物品
    {ok,#p_role_base{sex=Sex}} = mod_map_role:get_role_base(RoleID),
    {ok,#p_role_attr{category=Category,level=Level}} = mod_map_role:get_role_attr(RoleID),
    %%不同玩家的过滤标识
    RoleFilterAttr = {Sex,Category,Level},
    generate_box_goods2(RoleID,RoleFilterAttr,OpFeeType,OpenTimes,BindNum,BoxLevel).


%%@return {ok,GoodsList2,BcGoodsList}
generate_box_goods2(RoleID,RoleFilterAttr,OpFeeType,OpenTimes,BindNum,BoxLevel) -> 
    [BoxGoodsProbabilityListBaseTmp] = ?find_config({box_goods_probability,OpFeeType}),
    ?DBG(OpFeeType),
	case lists:keyfind(BoxLevel, 1, BoxGoodsProbabilityListBaseTmp) of
		false -> 
			BoxGoodsProbabilityListBase=null,
			?THROW_SYS_ERR();
		{_,BoxGoodsProbabilityListBase} ->
			next
	end,
    [MinBoxEquipColor] = ?find_config(min_box_equip_color), %% 装备最小广播颜色
    case filter_box_goods_probability(RoleID,RoleFilterAttr,BoxGoodsProbabilityListBase) of
        [] ->
            {ok,[],[]};
        BoxGoodsProbabilityList->
            {GoodsList,BcGoodsList,_} = 
                lists:foldl(
                  fun(_Index,{AccGoodsList,AccBcList,CurNum}) ->
                          BoxGoodsWeightList = [BoxGoodsWeight || #r_box_goods_probability{weight = BoxGoodsWeight} <- BoxGoodsProbabilityList],
                          BoxGoodsWeightIndex = mod_refining:get_random_number(BoxGoodsWeightList,0,0),
                          BoxGoodsProbability = lists:nth(BoxGoodsWeightIndex,BoxGoodsProbabilityList),
                          Isbind = (CurNum =< BindNum),
                          case mod_treasbox_manager:create_p_goods(OpFeeType,BoxGoodsProbability,Isbind) of
                              {ok,GoodsListT} ->
                                  %%判断是否进行广播
                                  #r_box_goods_probability{is_broadcast=GIsBroadcast,item_type=GItemType,item_id=GItemId} = BoxGoodsProbability,
                                  if
                                      GItemType =:= ?TYPE_EQUIP-> %%装备要判断颜色
                                          [HEquipBCBoxGoods|_T] = GoodsListT,
                                          if HEquipBCBoxGoods#p_goods.current_colour >= MinBoxEquipColor ->
                                                 AccBcList2 = [GItemId|AccBcList];
                                             true ->
                                                 AccBcList2 = AccBcList
                                          end;
                                      GIsBroadcast=:=1 ->         %%其他判断标志
                                          AccBcList2 = [GItemId|AccBcList];
                                      true->
                                          AccBcList2 = AccBcList
                                  end,
                                  {lists:append([GoodsListT,AccGoodsList]),AccBcList2,CurNum+1};
                              _ ->
                                  {AccGoodsList,AccBcList,CurNum+1}
                          end
                  end,{[],[],1},lists:seq(1,OpenTimes)),
            GoodsList2 = [Goods#p_goods{id = ?DEFAULT_BOX_GOODS_ID,roleid = RoleID,bagid = 0,bagposition = 0} || Goods <- GoodsList],
            {ok,GoodsList2,BcGoodsList}
    end.

check_miss_status(RoleID,MissionID) ->
	case mod_mission_data:get_pinfo(RoleID, MissionID) of
		#p_mission_info{current_status=2}->
			true;
		#p_mission_info{current_status=3}->
			false;
		#p_mission_info{current_status=1}->
			false;
		_Reason ->
			false
	end.

get_mission_goods(RoleID)->
	[BoxMissGoodsList] = ?find_config( box_mission_goods),
	GoodsProbList = lists:filter(fun({MissionID,_}) -> 
						 check_miss_status(RoleID,MissionID) end, BoxMissGoodsList),
	lists:foldl(fun({_,[H|_T]},AccIn) -> [H|AccIn] end, [], GoodsProbList).

%% 过滤符合玩家条件的概率物品
%%@return BoxGoodsProbabilityList
filter_box_goods_probability(RoleID,RoleFilterAttr,BoxGoodsProbabilityListBase)->
	case get_mission_goods(RoleID) of
		[] -> filter_box_goods_probability_2(RoleID,RoleFilterAttr,BoxGoodsProbabilityListBase,[]);
		MissionGoods -> MissionGoods
	end.

			

filter_box_goods_probability_2(_RoleID,_RoleFilterAttr,[],Acc)->
    Acc;
filter_box_goods_probability_2(RoleID,RoleFilterAttr,[H|T],Acc)->
    #r_box_goods_probability{role_category=RoleCategory,role_sex=RoleSex,role_level=RoleLevel} = H,
    case is_role_match(RoleFilterAttr,RoleCategory,RoleSex,RoleLevel) of
        true->
            filter_box_goods_probability_2(RoleID,RoleFilterAttr,T,[H|Acc]);
        _ ->
            filter_box_goods_probability_2(RoleID,RoleFilterAttr,T,Acc)
    end.

is_role_match(RoleFilterAttr,RoleCategory,RoleSex,RoleLevel)->
    {Sex,Category,Level} = RoleFilterAttr,
    case RoleSex =:= [] orelse lists:member(Sex, RoleSex) of 
        true->
            case RoleCategory =:=[] orelse lists:member(Category, RoleCategory) of
                true->
                    is_role_level_match(RoleLevel,Level);
                _ ->
                    false
            end;
        _ ->
            false
    end.

do_treasbox_open_3(InterfaceInfo,RoleAttr2,RoleBox2,AwardList2,BcTypeIdList,BoxOpenFee,Times,OpenTimes,TotalAddScore,MulitScore)->
    %% 处理所有玩家开箱子记录
    {Unique, Module, Method, DataIn, RoleID, PID, _Line} = InterfaceInfo,
    #m_treasbox_open_tos{op_fee_type=OpFeeType,num_type=NumType} = DataIn,
    #r_role_box{remain_times = RemainOpenTimes,end_time=EndTime,all_list=BoxAllList,box_score=BoxScore,box_level=BoxLevel} = RoleBox2,
    R2C = #m_treasbox_open_toc{op_fee_type = OpFeeType,
                               award_list = AwardList2,
                               box_list = BoxAllList,
                               remain_silver_times = remain_silver_box_times(RemainOpenTimes,EndTime),                               
                               open_times = Times,
                               real_open_times = OpenTimes,
							   box_score=BoxScore,
							   open_score=TotalAddScore,
							   mulit_score=MulitScore,
							   can_upgrade=treasbox_can_upgrade(RoleAttr2#p_role_attr.level,BoxLevel,BoxScore)},
    ?UNICAST_TOC( R2C ),
    case BoxOpenFee of
        {silver_any,_NeedMoney} ->
            common_misc:send_role_silver_change(RoleID, RoleAttr2);
        _ ->
            common_misc:send_role_gold_change(RoleID, RoleAttr2)
    end,
    
    %% 记录道具日志
    lists:foreach(
      fun(BoxGoodsLog) ->
              ?TRY_CATCH(common_item_logger:log(RoleID,BoxGoodsLog,?LOG_ITEM_TYPE_BOX_RESTORE_HUO_DE))
      end,AwardList2),
    
    %%记录猎宝日志
    case mod_map_role:get_role_base(RoleID) of
        {ok,RoleBase}->
            add_role_box_log(RoleID,RoleBase,AwardList2,BcTypeIdList);
        _ ->
            ignore
    end,
    
    %% 特殊任务事件
    hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_REFINING_BOX),
    mod_score:gain_score_notify(RoleID, OpenTimes, ?SCORE_TYPE_YUEGUANG,{?SCORE_TYPE_YUEGUANG,"月关宝盒获得积分"}),
    mod_random_mission:handle_event(RoleID, ?RAMDOM_MISSION_EVENT_3),
    mod_role_event:notify(RoleID, {?ROLE_EVENT_OPEN_BOX, OpenTimes}),
    %% 完成成就
    mod_achievement2:achievement_update_event(RoleID, 21001, OpenTimes),
    mod_achievement2:achievement_update_event(RoleID, 22001, OpenTimes),
    %% 完成活动
    hook_activity_task:done_task(RoleID,?ACTIVITY_TASK_TREASBOX),
    %%广播
    case is_box_pay_limit() of
        true->
            ignore;
        _ ->
            do_treasbox_goods_notify(RoleID, AwardList2, BcTypeIdList, NumType)
    end,
    ok.

add_role_box_log(_RoleID,_RoleBase,_AwardList,[])->
    ignore;
add_role_box_log(RoleID,RoleBase,AwardList,BcTypeIdList)->
    AwardGoodsBcList = lists:filter( fun(#p_goods{typeid=TypeId})-> lists:member(TypeId, BcTypeIdList) end , AwardList),
    AwardLogBcList = [ #p_reward_prop{prop_id=TypeID,prop_type=Type,prop_num=Num,bind=Bind,color=Color} 
                     ||#p_goods{bind=Bind,type=Type,typeid=TypeID,current_num=Num,current_colour=Color}<-AwardGoodsBcList ],
    
    case AwardLogBcList of
        []-> ignore;
        _ ->
            BoxLog = #p_treasbox_log{role_id = RoleID,
                                     role_sex = RoleBase#p_role_base.sex,
                                     role_name = RoleBase#p_role_base.role_name,
                                     faction_id = RoleBase#p_role_base.faction_id,
                                     award_time = common_tool:now(),box_list = AwardLogBcList},
            Msg = {add_role_box_log,RoleID,BoxLog},
            send_fb_manager(Msg)
    end.



%% 可使用钱币开箱子剩余次数
remain_silver_box_times(RemainOpenTimes,LastBoxingTime) ->
    [MaxSilverBoxTimes] = ?find_config(max_silver_box_times),
    case common_time:time_to_date(LastBoxingTime) =:= common_time:time_to_date(common_tool:now()) of
        true ->
            erlang:max(RemainOpenTimes,0);
        false ->
            MaxSilverBoxTimes
    end.

get_and_reset_role_box(RoleID) ->
    {ok, RoleBase} = mod_map_role:get_role_base(RoleID),
    {ok, RoleBox} = assert_get_role_box_info(RoleBase),
    #r_role_box{end_time = LastBoxingTime} = RoleBox,
    Now = common_tool:now(),
    case common_time:time_to_date(LastBoxingTime) =:= common_time:time_to_date(Now) of
        true ->
            RoleBox1 = RoleBox;
        false ->
            RemainOpenTimes1 = hd(?find_config(max_silver_box_times)),
            UseSilverOpenTimes1 = 0,
            RoleBox1 = RoleBox#r_role_box{
                end_time = Now,
                fee_times = UseSilverOpenTimes1,
                remain_times = RemainOpenTimes1
            },
            set_role_treasbox_info(RoleID, RoleBox1)
    end,
    RoleBox1.

%% 增加银币神游的次数
add_silver_open_times(RoleID, Times) ->
    RoleBox         = get_and_reset_role_box(RoleID),
    RemainOpenTimes = RoleBox#r_role_box.remain_times,
    OpType          = ?BOX_OP_TYPE_SILVER_TIME_CHANGE_NOTIFY,
    Msg = #m_treasbox_show_toc{
        op_type             = OpType,
        remain_silver_times = RemainOpenTimes + Times
    },
    RoleBox1 = RoleBox#r_role_box{
        remain_times = RemainOpenTimes + Times
    },
    set_role_treasbox_info(RoleID, RoleBox1),
    common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?TREASBOX, ?TREASBOX_SHOW, Msg).


%%判断境界是否匹配
is_role_level_match([],_)->
    true;
is_role_level_match([Min,Max],Level)->
    Min =< Level andalso Max >= Level.


%%判断能否元宝猎宝
can_use_gold() ->
    case common_config_dyn:find_common(gold_box_close) of
        [true]->
            false;
        _ ->
            true
    end.

