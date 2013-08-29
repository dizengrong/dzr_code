%%%-------------------------------------------------------------------
%%% @author  <caochuncheng@gmail.com>
%%% @copyright www.gmail.com (C) 2011, 
%%% @doc
%%% 天工炉模块功能
%%% @end
%%% Created : 29 Apr 2011 by  <caochuncheng2002@gmail.com>
%%%-------------------------------------------------------------------
-module(mod_refining_firing).

%% INCLUDE
-include("mgeem.hrl").
-include("refining.hrl").

%% API
-export([
		 do_handle_info/1
		]).

-export([
		 get_reinforce_stuff_config/2,
		 calc_new_reinforce_result/2,
		 do_t_refining_firing_reinforce2/5,
		 hook_refining_firing_reinforce/3,
		 
		 get_upprop_min_bind_attr_level/1,
		 get_upprop_max_possible_level/1,
		 get_upprop_stuff_config/1,
		 calc_new_upprop_result/3,
		 check_equip_upprop_has_duplicate/1,
		 
		 get_punch_stuff_config/1,
		 calc_new_punch_result/1
		]).

-compile(export_all).

-define(NEED_AUTO_BUY, need_auto_buy).
-define(NOT_NEED_AUTO_BUY, not_need_auto_buy).
%%%===================================================================
%%% API
%%%===================================================================

%% 天工炉功能处理
do_handle_info({Unique, ?REFINING, ?REFINING_FIRING, DataRecord, RoleId, PId, Line}) ->
    do_refining_firing({Unique, ?REFINING, ?REFINING_FIRING, DataRecord, RoleId, PId, Line});

do_handle_info(Info) ->
    ?ERROR_MSG("~ts,Info=~w",["天工炉模块无法处理此消息",Info]),
    error.

%% DataRecord 结构为 m_refining_firing_tos
do_refining_firing({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch check_can_refining_firing(RoleId) of
        ok ->
            #m_refining_firing_tos{op_type = OpType} = DataRecord,
            case OpType of
                % ?FIRING_OP_TYPE_PUNCH -> %% 打孔
                %     do_refining_firing_punch({Unique, Module, Method, DataRecord, RoleId, PId, Line});
                % ?FIRING_OP_TYPE_INLAY -> %% 镶嵌
                %     do_refining_firing_inlay({Unique, Module, Method, DataRecord, RoleId, PId, Line});
                % ?FIRING_OP_TYPE_UNLOAD -> %% 折卸
                %     do_refining_firing_unload({Unique, Module, Method, DataRecord, RoleId, PId, Line});
                % ?FIRING_OP_TYPE_REINFORCE -> %% 强化
                %     do_refining_firing_reinforce({Unique, Module, Method, DataRecord, RoleId, PId, Line});
                ?FIRING_OP_TYPE_COMPOSE -> %% 合成 
                    do_refining_firing_compose({Unique, Module, Method, DataRecord, RoleId, PId, Line});
                ?FIRING_OP_TYPE_FORGING -> %% 炼制
                    do_refining_firing_forging({Unique, Module, Method, DataRecord, RoleId, PId, Line});
                % ?FIRING_OP_TYPE_ADDPROP -> %% 附加，洗炼
                %     do_refining_firing_addprop({Unique, Module, Method, DataRecord, RoleId, PId, Line});
                % ?FIRING_OP_TYPE_UPPROP -> %% 提升
                %     do_refining_firing_upprop({Unique, Module, Method, DataRecord, RoleId, PId, Line});
                ?FIRING_OP_TYPE_UPCOLOR -> %% 提升装备颜色
                    mod_equip_color:do_up_equip_color({Unique, Module, Method, DataRecord, RoleId, PId, Line});
                ?FIRING_OP_TYPE_RETAKE -> %% 取回天工炉物品接口
                    do_refining_firing_retake({Unique, Module, Method, DataRecord, RoleId, PId, Line});
                ?FIRING_OP_TYPE_UPEQUIP -> %% 装备升级
                    mod_equip_upgrade:do_equip_upgrade({Unique, Module, Method, DataRecord, RoleId, PId, Line});
                ?FIRING_OP_TYPE_UPQUALITY -> %% 装备品质改造
                    mod_equip_quality:do_up_equip_quality({Unique, Module, Method, DataRecord, RoleId, PId, Line});
                _ ->
                    Reason = ?_LANG_REFINING_OP_TYPE_ERROR,
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,0)
            end;
        {error, Reason2} ->
            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2,0)
    end.

check_can_refining_firing(RoleID) ->
    [RoleState2] = db:dirty_read(?DB_ROLE_STATE, RoleID),
    #r_role_state{exchange=Exchange} = RoleState2,
    if
        Exchange ->
            erlang:throw({error, ?_LANG_REFINING_NOT_ALLOWED_IN_EXCHANGE_STATE});
        true ->
            ok
    end.

do_refining_firing_error({Unique, Module, Method, DataRecord, _RoleId, PId, _Line},Reason,ReasonCode) ->
    SendSelf = #m_refining_firing_toc{
      succ = false,
      reason = Reason,
      reason_code = ReasonCode,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list},
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf).
%% 打孔 (自动购买有问题TODO)
do_refining_firing_punch({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_refining_firing_punch2(RoleId,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
        {IsNeedAutoBuy,EquipGoods,PunchGoods,PunchLevel,PunchFee} ->
            do_refining_firing_punch3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                      IsNeedAutoBuy,EquipGoods,PunchGoods,PunchLevel,PunchFee)
    end.
do_refining_firing_punch2(RoleId,DataRecord) ->
    #m_refining_firing_tos{auto_buy_firing_stuff=IsAutoBuy} = DataRecord,
	if IsAutoBuy =:= false->
		   check_refining_firing_punch_normal(RoleId, DataRecord);
	   true ->
		   check_refining_firing_punch_with_autobuy(RoleId, DataRecord)
	end.

check_refining_firing_punch_normal(RoleId, DataRecord) ->
    #m_refining_firing_tos{firing_list = FiringList} = DataRecord,
    %% 材料是否足够合法
    case (erlang:length(FiringList) =:= 2) of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_PUNCH_NOT_ENOUGH_GOODS,0})
    end,
	
    %% 检查是否有要打孔的装备
    EquipGoods = check_punch_equip(RoleId, FiringList),
	
    %% 检查是否有有打孔符
    PunchGoods = get_punch_stuff_goods(RoleId, FiringList),
    %% 检查打孔符是否合法
	PunchLevel = get_punch_stuff_level(PunchGoods),
    check_punch_stuff(EquipGoods, PunchLevel),
	
    PunchFee = mod_refining:get_refining_fee(equip_punch_fee, EquipGoods, PunchGoods),
    {?NOT_NEED_AUTO_BUY,EquipGoods,PunchGoods,PunchLevel,PunchFee}.

check_refining_firing_punch_with_autobuy(RoleId, DataRecord) ->
	#m_refining_firing_tos{firing_list = FiringList} = DataRecord,
	case is_equip_in_firing_list(FiringList) of
		true ->
			next;
		false ->
			erlang:throw({error, ?_LANG_PUNCH_NO_EQUIP, 0})
	end,
	
	%% 检查是否有要打孔的装备
    EquipGoods = check_punch_equip(RoleId, FiringList),
	{TypeId, PunchLevel} = get_punch_stuff_config(EquipGoods#p_goods.punch_num),
	PunchGoods = 
		case catch get_punch_stuff_goods(RoleId, FiringList) of
			{error, _, 0} ->
				undefined;
			TGoods ->
				TGoods
		end,
	IsNeedAutoBuy = 
		case PunchGoods =/= undefined of
			true ->
				case PunchGoods#p_goods.type =:= TypeId of
					true ->
						?NOT_NEED_AUTO_BUY;
					false ->
						?NEED_AUTO_BUY
				end;
			false ->
				?NEED_AUTO_BUY
		end,
	PunchFee = mod_refining:get_refining_fee(equip_punch_fee, EquipGoods, PunchLevel),
    {IsNeedAutoBuy,EquipGoods,PunchGoods,PunchLevel,PunchFee}.

%% 检查是否有要打孔的装备
check_punch_equip(RoleId, FiringList) ->
	EquipGoods = 
        case lists:foldl(
               fun(EquipPRefiningT,AccEquipPRefiningT) ->
                       case ( AccEquipPRefiningT =:= undefined
                              andalso EquipPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_TARGET
                              andalso EquipPRefiningT#p_refining.goods_type =:= ?TYPE_EQUIP) of
                           true ->
                               EquipPRefiningT;
                           false ->
                               AccEquipPRefiningT
                       end 
               end,undefined,FiringList) of
            undefined ->
                erlang:throw({error,?_LANG_PUNCH_NO_EQUIP,0});
            EquipPRefiningTT ->
                case mod_bag:check_inbag(RoleId,EquipPRefiningTT#p_refining.goods_id) of
                    {ok,EquipGoodsT} ->
                        EquipGoodsT;
                    _  ->
                        erlang:throw({error,?_LANG_PUNCH_NO_EQUIP,0})
                end
        end,
    [EquipBaseInfo] = common_config_dyn:find_equip(EquipGoods#p_goods.typeid),
    if EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
            erlang:throw({error,?_LANG_PUNCH_MOUNT_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
            erlang:throw({error,?_LANG_PUNCH_FASHION_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
            erlang:throw({error,?_LANG_PUNCH_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_JINGJIE ->
            erlang:throw({error,?_LANG_PUNCH_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_SHENQI ->
            erlang:throw({error,?_LANG_PUNCH_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MARRY ->
            erlang:throw({error,?_LANG_PUNCH_ADORN_ERROR,0});
       true ->
            next
    end,
    [SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
    case lists:member(EquipGoods#p_goods.typeid,SpecialEquipList) of
        true ->
            erlang:throw({error,?_LANG_PUNCH_ADORN_ERROR,0});
        _ ->
            next
    end,
    if EquipGoods#p_goods.punch_num >= ?MAX_PUNCH_NUM ->
            erlang:throw({error,?_LANG_PUNCH_MAX_HOLE,0});
       true ->
            next
    end,
	[PunchKindList] = common_config_dyn:find(refining,punch_kind_list),
    case lists:member(EquipBaseInfo#p_equip_base_info.kind,PunchKindList) of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_PUNCH_CANT_PUNCH,0})
    end,
	EquipGoods.

get_punch_stuff_goods(RoleId, FiringList) ->
	case lists:foldl(
		   fun(PunchPRefiningT,AccPunchPRefiningT) ->
				   case ( AccPunchPRefiningT =:= undefined
							  andalso PunchPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_MATERIAL
																	 andalso PunchPRefiningT#p_refining.goods_type =:= ?TYPE_ITEM) of
					   true ->
						   PunchPRefiningT;
					   false ->
						   AccPunchPRefiningT
				   end
		   end,undefined,FiringList) of
		undefined ->
			erlang:throw({error,?_LANG_PUNCH_NOT_ENOUGH_GOODS,0});
		PunchPRefiningTT ->
			case mod_bag:check_inbag(RoleId,PunchPRefiningTT#p_refining.goods_id) of
				{ok,PunchGoodsT} ->
					PunchGoodsT;
				_  ->
					erlang:throw({error,?_LANG_PUNCH_NOT_ENOUGH_GOODS,0})
			end
	end.

get_punch_stuff_level(PunchGoods) ->
	[RuneSymlolList] = common_config_dyn:find(refining,rune_symbol),
	PunchLevel = 
		case lists:keyfind(PunchGoods#p_goods.typeid,1,RuneSymlolList) of
			false ->
				erlang:throw({error,?_LANG_PUNCH_CANT_PUNCH,0});
			{_,PunchLevelT} ->
				PunchLevelT
		end,
	PunchLevel.

check_punch_stuff(EquipGoods, PunchLevel) ->
	case PunchLevel < (EquipGoods#p_goods.punch_num + 1) of
		true ->
			erlang:throw({error,?_LANG_PUNCH_CANT_PUNCH,0});
		_ ->
			ok
	end.

get_punch_stuff_config(EquipPunchNum) ->
	[RuneSymlolList] = common_config_dyn:find(refining,rune_symbol),
	MatchConfig = 
		lists:foldl(
		  fun({TypeId, PunchLevel}, Acc) -> 
				  if Acc =:= false andalso EquipPunchNum + 1 =< PunchLevel ->
						 {TypeId, PunchLevel};
					 true ->
						 Acc
				  end
		  end, false, RuneSymlolList),
	if MatchConfig =:= false ->
		   erlang:throw({error,?_LANG_SYSTEM_ERROR,0});
	   true ->
		   MatchConfig
	end.

do_refining_firing_punch3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                          IsNeedAutoBuy,EquipGoods,PunchGoods,PunchLevel,PunchFee) ->
    case common_transaction:transaction(
           fun() ->
                   do_t_refining_firing_punch(IsNeedAutoBuy,RoleId,EquipGoods,PunchGoods,PunchLevel,PunchFee)
           end) of
        {atomic,{ok,IsPunchSucc,EquipGoods2,DelList,UpdateList}} ->
            do_refining_firing_punch4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                      IsNeedAutoBuy,IsPunchSucc,EquipGoods2,PunchGoods,PunchLevel,PunchFee,DelList,UpdateList);
        {aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},?_LANG_REFINING_NOT_BAG_POS_ERROR,0);
                {Reason, ReasonCode} ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
                _ ->
                    Reason2 = ?_LANG_PUNCH_ERROR,
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2,0)
            end
    end.

do_refining_firing_punch4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                          IsNeedAutoBuy,IsPunchSucc,EquipGoods,PunchGoods,_PunchLevel,_PunchFee,DelList,UpdateList) ->
    case IsPunchSucc =:= true of
        true ->
            Reason = common_tool:get_format_lang_resources(?_LANG_PUNCH_SUCC,[EquipGoods#p_goods.punch_num]),
            ReasonCode = 0;
        _ ->
            Reason = ?_LANG_PUNCH_FAIL,
            ReasonCode = 1
    end,
    SendSelf = #m_refining_firing_toc{
      succ = true,
      reason = Reason,
      reason_code = ReasonCode,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list,
      update_list = [EquipGoods | UpdateList],
      del_list = DelList,
      new_list = []},
    %% 道具变化通知
    if UpdateList =/= [] ->
            catch common_misc:update_goods_notify({line, Line, RoleId},[EquipGoods | UpdateList]);
       true ->
            catch common_misc:update_goods_notify({line, Line, RoleId},[EquipGoods])
    end,
    if DelList =/= [] ->
            catch common_misc:del_goods_notify({line, Line, RoleId},DelList);
       true ->
            next
    end,
    %% 钱币变化通知
    catch mod_refining:do_refining_deduct_fee_notify(RoleId,{line, Line, RoleId}),
	%% 元宝变化通知
	case IsNeedAutoBuy of 
		?NEED_AUTO_BUY ->
			catch mod_refining:do_refining_deduct_gold_notify(RoleId,{line, Line, RoleId});
		_ ->
			ignore
	end,
    %% 道具消费日志
	case IsNeedAutoBuy of
		?NOT_NEED_AUTO_BUY ->
			catch common_item_logger:log(RoleId,PunchGoods,1,?LOG_ITEM_TYPE_KAI_KONG_SHI_QU);
		_ ->
			ignore
	end,
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    ok.

do_t_refining_firing_punch(IsNeedAutoBuy,RoleId,EquipGoods,PunchGoods,_PunchLevel,PunchFee) ->
	{PunchStuffTypeId, _} = get_punch_stuff_config(EquipGoods#p_goods.punch_num),
	{EquipNeedBind, DelList,UpdateList} = 
		case IsNeedAutoBuy of 
			?NOT_NEED_AUTO_BUY ->
				deduct_punch_fee_and_stuff(RoleId, PunchFee, [PunchGoods]);
			?NEED_AUTO_BUY ->
				deduct_punch_auto_buy_stuff(RoleId, PunchFee, PunchStuffTypeId)
		end,
    %% 打孔概率配置
	{IsPunchSucc, NewPunchNum} = calc_new_punch_result(EquipGoods),
    %% 材料是否洗炼，装备是否已经洗炼
    EquipGoods2 = EquipGoods#p_goods{punch_num = NewPunchNum},
    EquipGoods3 = 
        case (EquipGoods#p_goods.bind =:= false andalso EquipNeedBind =:= false andalso PunchGoods =/= undefined andalso PunchGoods#p_goods.bind =:= true) 
			orelse (EquipGoods#p_goods.bind =/= true andalso EquipNeedBind =:= true)of
            true ->
                case mod_refining_bind:do_equip_bind_for_punch(EquipGoods2) of
                    {error,_ErrorBindCode} ->
                        EquipGoods2#p_goods{bind = true};
                    {ok,BindGoods} ->
                        BindGoods
                end;
            false ->
                EquipGoods2
        end,
    %% 计算装备精炼系数
    EquipGoods4 = 
        case common_misc:do_calculate_equip_refining_index(EquipGoods3) of
            {error,_ErrorIndexCode} ->
                EquipGoods3;
            {ok, EquipGoods4T} ->
                EquipGoods4T
        end,
    mod_bag:update_goods(RoleId,EquipGoods4),
    {ok,IsPunchSucc,EquipGoods4,DelList,UpdateList}.

calc_new_punch_result(EquipGoods) ->
	[RuneSymbolProbabilityList] = common_config_dyn:find(refining,rune_symbol_probability),
	{_,RuneSymbolProbability} = lists:keyfind(EquipGoods#p_goods.punch_num + 1, 1,RuneSymbolProbabilityList),
	case RuneSymbolProbability =:= 100 of
		true ->
			{true, EquipGoods#p_goods.punch_num  + 1};
		_ ->
			case RuneSymbolProbability >= common_tool:random(1,100) of
				true ->
					{true, EquipGoods#p_goods.punch_num  + 1};
				_ ->
					{false, EquipGoods#p_goods.punch_num}
			end
	end.

deduct_punch_fee_and_stuff(RoleId, PunchFee, PunchGoods) ->
	%% 扣费
    EquipConsume = #r_equip_consume{
      type = punch,consume_type = ?CONSUME_TYPE_SILVER_EQUIP_PUNCH,consume_desc = ""},
    case catch mod_refining:do_refining_deduct_fee(RoleId,PunchFee,EquipConsume) of
        {error,Error} ->
            common_transaction:abort({Error,0});
        _ ->
            next
    end,
	{DelList,UpdateList} = deduct_refining_stuff(RoleId, PunchGoods, 1),
	{false, DelList,UpdateList}.

deduct_punch_auto_buy_stuff(RoleId, PunchFee, PunchStuffTypeId) ->
	%% 扣自动购买强化材料的费用
	EquipNeedBind = deduct_auto_buy_stuff_fee(punch, RoleId, PunchStuffTypeId, 1, PunchFee),
	
	%% 扣费
    EquipConsume = #r_equip_consume{type = punch,consume_type = ?CONSUME_TYPE_SILVER_EQUIP_PUNCH,consume_desc = ""},
    case catch mod_refining:do_refining_deduct_fee(RoleId,PunchFee,EquipConsume) of
        {error,Error} ->
            common_transaction:abort({Error,0});
        _ ->
            next
    end,
	{EquipNeedBind, [], []}.

%% 镶嵌
do_refining_firing_inlay({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_refining_firing_inlay2(RoleId,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
        {ok,EquipGoods,StoneGoods,SymbolGoods,SymbolLevel} ->
            do_refining_firing_inlay3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                      EquipGoods,StoneGoods,SymbolGoods,SymbolLevel)
    end.

do_refining_firing_inlay2(RoleId,DataRecord) ->
    #m_refining_firing_tos{firing_list = FiringList} = DataRecord,
    %% 材料是否足够合法
    case (erlang:length(FiringList) =:= 3) of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_INLAY_ERROR,0})
    end,
    %% 检查是否有要镶嵌的装备
    EquipGoods = 
        case lists:foldl(
               fun(EquipPRefiningT,AccEquipPRefiningT) ->
                       case ( AccEquipPRefiningT =:= undefined
                              andalso EquipPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_TARGET
                              andalso EquipPRefiningT#p_refining.goods_type =:= ?TYPE_EQUIP) of
                           true ->
                               EquipPRefiningT;
                           false ->
                               AccEquipPRefiningT
                       end 
               end,undefined,FiringList) of
            undefined ->
                erlang:throw({error,?_LANG_INLAY_NO_EQUIP,0});
            EquipPRefiningTT ->
                case mod_bag:check_inbag(RoleId,EquipPRefiningTT#p_refining.goods_id) of
                    {ok,EquipGoodsT} ->
                        case EquipGoodsT#p_goods.stone_num =:= undefined of
                            true ->
                                EquipGoodsT#p_goods{stone_num = 0};
                            false ->
                                EquipGoodsT
                        end;
                    _  ->
                        erlang:throw({error,?_LANG_INLAY_NO_EQUIP,0})
                end
        end,
	#p_goods{typeid=TypeID,punch_num=PunchNum} = EquipGoods,
    [EquipBaseInfo] = common_config_dyn:find_equip(TypeID),
    if EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
            erlang:throw({error,?_LANG_INLAY_MOUNT_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
            erlang:throw({error,?_LANG_INLAY_FASHION_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
            erlang:throw({error,?_LANG_INLAY_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_SHENQI ->
            erlang:throw({error,?_LANG_INLAY_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MARRY ->
            erlang:throw({error,?_LANG_INLAY_ADORN_ERROR,0});
       true ->
            next
    end,
    [SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
    case lists:member(EquipGoods#p_goods.typeid,SpecialEquipList) of
        true ->
            erlang:throw({error,?_LANG_INLAY_ADORN_ERROR,0});
        _ ->
            next
    end,
	%% 装备孔数检查
	case mod_refining_jingjie:is_jingjie_ling(TypeID) of
		false ->
			if PunchNum =:= undefined ->
				   erlang:throw({error,?_LANG_INLAY_HOLE_FULL,0});
			   EquipGoods#p_goods.stone_num >= ?MAX_PUNCH_NUM ->
				   erlang:throw({error,?_LANG_INLAY_MAX_STONE,0});
			   PunchNum =< EquipGoods#p_goods.stone_num ->
				   erlang:throw({error,?_LANG_INLAY_HOLE_FULL,0});
			   true ->
				   next
			end;
		true ->
			if
				EquipGoods#p_goods.stone_num >= ?MAX_JINGJIE_PUNCH_NUM ->
					erlang:throw({error,?_LANG_INLAY_MAX_STONE,0});
				true ->
					next
			end
	end,
    %% 镶嵌材料，宝石
    StoneGoods = 
        case lists:foldl(
               fun(StonePRefiningT,AccStonePRefiningT) ->
                       case ( AccStonePRefiningT =:= undefined
                              andalso StonePRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_MATERIAL
                              andalso StonePRefiningT#p_refining.goods_type =:= ?TYPE_STONE) of
                           true ->
                               StonePRefiningT;
                           false ->
                               AccStonePRefiningT
                       end 
               end,undefined,FiringList) of
            undefined ->
                erlang:throw({error,?_LANG_INLAY_NO_STONE,0});
            StonePRefiningTT ->
                case mod_bag:check_inbag(RoleId,StonePRefiningTT#p_refining.goods_id) of
                    {ok,StoneGoodsT} ->
                        StoneGoodsT;
                    _  ->
                        erlang:throw({error,?_LANG_INLAY_NO_STONE,0})
                end
        end,
	%% 检查当前此装备是否可以镶嵌此宝石
	[StoneBaseInfo] = common_config_dyn:find_stone(StoneGoods#p_goods.typeid),
	case lists:member(EquipBaseInfo#p_equip_base_info.slot_num,StoneBaseInfo#p_stone_base_info.embe_equip_list) =:= false
			 andalso mod_refining_jingjie:is_jingjie_ling(TypeID) =:= false of
		true ->
			erlang:throw({error,?_LANG_INLAY_STONE_NOT_CAN_INLAY,0});
		false -> 
			next
	end,  
	EquipStoneList = 
		case EquipGoods#p_goods.stones =:= undefined of
			true ->
				[];
			false ->
				EquipGoods#p_goods.stones
		end,
	case mod_refining_jingjie:is_jingjie_ling(TypeID) of
		false ->
			case has_inlay_same_stone_type(EquipStoneList,StoneGoods) of
				true ->
					erlang:throw({error,?_LANG_INLAY_WITH_TYPE,0});
				false ->
					next
			end;
		true ->
			next
	end,
    %% 镶嵌材料 镶嵌符
    SymbolGoods = 
        case lists:foldl(
               fun(SymbolPRefiningT,AccSymbolPRefiningT) ->
                       case ( AccSymbolPRefiningT =:= undefined
                              andalso SymbolPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_MATERIAL
                              andalso SymbolPRefiningT#p_refining.goods_type =:= ?TYPE_ITEM) of
                           true ->
                               SymbolPRefiningT;
                           false ->
                               AccSymbolPRefiningT
                       end 
               end,undefined,FiringList) of
            undefined ->
                erlang:throw({error,?_LANG_INLAY_NOT_SYMBOL,0});
            SymbolPRefiningTT ->
                case mod_bag:check_inbag(RoleId,SymbolPRefiningTT#p_refining.goods_id) of
                    {ok,SymbolGoodsT} ->
                        SymbolGoodsT;
                    _  ->
                        erlang:throw({error,?_LANG_INLAY_NOT_SYMBOL,0})
                end
        end,
    %%　检查镶嵌符是否合法
    [SymbolLevelList] = common_config_dyn:find(refining,inlay_symbol),
	SymbolLevel = 
		case lists:keyfind(SymbolGoods#p_goods.typeid,1,SymbolLevelList) of
			false ->
				erlang:throw({error,?_LANG_INLAY_NOT_SYMBOL,0});
			{_,SymbolLevelT} ->
				SymbolLevelT
		end,
	case mod_refining_jingjie:is_jingjie_ling(TypeID) of
		false ->
			case EquipGoods#p_goods.stone_num + 1 > SymbolLevel of
				false ->
					next;
				true ->
					erlang:throw({error,?_LANG_INLAY_HAS_OTHER_SYMBOL,0})
			end;
		true ->
			next
	end,
    {ok,EquipGoods,StoneGoods,SymbolGoods,SymbolLevel}.
do_refining_firing_inlay3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                          EquipGoods,StoneGoods,SymbolGoods,SymbolLevel) ->
    case common_transaction:transaction(
           fun() ->
                   do_t_refining_firing_inlay(RoleId,EquipGoods,StoneGoods,SymbolGoods,SymbolLevel)
           end) of
        {atomic,{ok,EquipGoods2,DelList,UpdateList,DelStoneList,UpdateStoneList}} ->
            do_refining_firing_inlay4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                      EquipGoods2,StoneGoods,SymbolGoods,DelList,UpdateList,DelStoneList,UpdateStoneList);
        {aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},?_LANG_REFINING_NOT_BAG_POS_ERROR,0);
                {Reason, ReasonCode} ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
                Reason ->
					?ERROR_MSG("do_refining_firing_inlay3 error:~w",[Reason]),
                    Reason2 = ?_LANG_INLAY_ERROR,
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2,0)
            end
    end.
do_refining_firing_inlay4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                          EquipGoods,StoneGoods,SymbolGoods,DelList,UpdateList,DelStoneList,UpdateStoneList) ->
    SendUpdateList = lists:append([[EquipGoods],UpdateList,UpdateStoneList]),
    SendDelList = lists:append([DelList,DelStoneList]),
    SendSelf = #m_refining_firing_toc{
      succ = true,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list,
      update_list = SendUpdateList,
      del_list = SendDelList,
      new_list = []},
    %% 道具变化通知
    catch common_misc:update_goods_notify({line, Line, RoleId},SendUpdateList),
    if SendDelList =/= [] ->
            catch common_misc:del_goods_notify({line, Line, RoleId},SendDelList);
       true ->
            next
    end,
    
    %% 特殊任务事件
    hook_mission_event:hook_special_event(RoleId,?MISSON_EVENT_REFINING_PUNCH),
    
    %% 道具消费日志
    catch common_item_logger:log(RoleId,StoneGoods,1,?LOG_ITEM_TYPE_XIANG_QIAN_SHI_QU),
    catch common_item_logger:log(RoleId,SymbolGoods,1,?LOG_ITEM_TYPE_XIANG_QIAN_SHI_QU),
    catch common_item_logger:log(RoleId,EquipGoods,1,?LOG_ITEM_TYPE_XIANG_QIAN_HUO_DE),
    %% 钱币变化通知
    catch mod_refining:do_refining_deduct_fee_notify(RoleId,{line, Line, RoleId}),
    ?DEBUG("~ts,SendSelf=~w",["天工炉模块返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    ok.
do_t_refining_firing_inlay(RoleId,EquipGoods,StoneGoods,SymbolGoods,SymbolLevel) ->
	#p_goods{typeid=TypeID,stone_num=StoneNum}=EquipGoods,
    %% 扣物品 镶嵌符
    {DelList,UpdateList} = 
        case catch mod_equip_build:do_transaction_dedcut_goods(RoleId,[SymbolGoods],1) of
            {error,GoodsError} ->
                common_transaction:abort({GoodsError,0});
            {ok,DelListT,UpdateListT} ->
                DelListT2  = 
                    lists:foldl(
                      fun(DelGoods,AccDelListT2) -> 
                              case lists:keyfind(DelGoods#p_goods.id,#p_goods.id,UpdateListT) of
                                  false ->
                                      [DelGoods | AccDelListT2];
                                  _ ->
                                      AccDelListT2
                              end
                      end,[],DelListT),
                {DelListT2,UpdateListT}
        end,
    %% 删除宝石
    {DelStoneList,UpdateStoneList} = 
        case catch mod_equip_build:do_transaction_dedcut_goods(RoleId,[StoneGoods],1) of
            {error,StoneGoodsError} ->
                common_transaction:abort({StoneGoodsError,0});
            {ok,DelStoneListT,UpdateStoneListT} ->
                DelStoneListT2  = 
                    lists:foldl(
                      fun(DelStoneGoods,AccDelStoneListT2) -> 
                              case lists:keyfind(DelStoneGoods#p_goods.id,#p_goods.id,UpdateStoneListT) of
                                  false ->
                                      [DelStoneGoods | AccDelStoneListT2];
                                  _ ->
                                      AccDelStoneListT2
                              end
                      end,[],DelStoneListT),
                {DelStoneListT2,UpdateStoneListT}
        end,
    EquipStonesList = 
        case erlang:is_list(EquipGoods#p_goods.stones)  of
            true ->
                EquipGoods#p_goods.stones;
            _ ->
                []
        end,

	%% 装备属性计算
	NewEquipStonesList = 
		case mod_refining_jingjie:is_jingjie_ling(TypeID) of
			false ->
				%% 镶嵌费用
				InlayFee = mod_refining:get_refining_fee(equip_inlay_fee, EquipGoods),
				NewStoneGoods = StoneGoods#p_goods{
												   current_num = 1,
												   roleid = EquipGoods#p_goods.roleid,
												   embe_pos = StoneNum + 1,
												   embe_equipid = EquipGoods#p_goods.id},
				lists:reverse([NewStoneGoods|lists:reverse(EquipStonesList)]);
			true ->
				%%境界令同类同级宝石镶嵌在同个孔，镶嵌宝石个数算一个
				case lists:keyfind(StoneGoods#p_goods.typeid,#p_goods.typeid,EquipStonesList) of
					false ->
						%%检测镶嵌符
						case EquipGoods#p_goods.stone_num + 1 > SymbolLevel of
							false ->
								next;
							true ->
								common_transaction:abort({?_LANG_INLAY_HAS_OTHER_SYMBOL,0})
						end,
						case has_inlay_same_stone_type(EquipStonesList,StoneGoods) of
							true ->
								common_transaction:abort({?_LANG_INLAY_WITH_TYPE,0});
							false ->
								next
						end,
						%% 镶嵌费用，跟普通镶嵌一样的算法
						InlayFee = mod_refining:get_refining_fee(equip_inlay_fee, EquipGoods),
						NewStoneGoods = StoneGoods#p_goods{
														   current_num = 1,
														   roleid = EquipGoods#p_goods.roleid,
														   embe_pos = erlang:length(mod_refining_jingjie:merge_repeat_jingjie_ling_stones(EquipStonesList,EquipStonesList)) + 1,
														   embe_equipid = EquipGoods#p_goods.id},
						[NewStoneGoods|EquipStonesList];
					OldStoneGoods ->
						%%检测镶嵌符
						case OldStoneGoods#p_goods.embe_pos > SymbolLevel of
							false ->
								next;
							true ->
								common_transaction:abort({?_LANG_INLAY_HAS_OTHER_SYMBOL,0})
						end,
						%%绑定和非绑定分开两个stone存储，可能存在两个同类同级石头
						OldSameStoneGoodsList = 
							lists:filter(fun(Stones) ->
												 Stones#p_goods.typeid =:= StoneGoods#p_goods.typeid
										 end, EquipStonesList),
						CurrentNum = 
							lists:foldl(fun(Stones,AccStoneNum) ->
												Stones#p_goods.current_num + AccStoneNum
										end, 0, OldSameStoneGoodsList),
						case CurrentNum >= mod_refining_jingjie:max_inlay_stone_num(TypeID) of
							true ->
								InlayFee = 0,
								common_transaction:abort({?_LANG_INLAY_MAX_INLAY_STONE_NUM,0});
							false ->
								%%计算费用，按镶嵌到的孔数embe_pos位置计算价格
								FeeEquipStoneNum = erlang:max(OldStoneGoods#p_goods.embe_pos-1,1),
								InlayFee = mod_refining:get_refining_fee(equip_inlay_fee, EquipGoods#p_goods{stone_num=FeeEquipStoneNum}),
								EquipStonesList1 = 
									lists:filter(fun(Stones) ->
														 Stones#p_goods.typeid =/= StoneGoods#p_goods.typeid
														 end, EquipStonesList),
								SameStoneGoodsList =
									case lists:keyfind(StoneGoods#p_goods.bind,#p_goods.bind,OldSameStoneGoodsList) of
										false ->
											[StoneGoods#p_goods{
																current_num = 1,
																roleid = EquipGoods#p_goods.roleid,
																embe_pos = OldStoneGoods#p_goods.embe_pos,
																embe_equipid = EquipGoods#p_goods.id} | OldSameStoneGoodsList];
										OldSameStone ->
											[OldSameStone#p_goods{current_num = OldSameStone#p_goods.current_num + 1} |
																	 lists:keydelete(StoneGoods#p_goods.bind,#p_goods.bind,OldSameStoneGoodsList)]
									end,
								SameStoneGoodsList ++ EquipStonesList1
						end
				end
		end,
	%% 扣费用
	EquipConsume = #r_equip_consume{type = inlay,consume_type = ?CONSUME_TYPE_SILVER_EQUIP_INLAY,consume_desc = ""},
	case catch mod_refining:do_refining_deduct_fee(RoleId,InlayFee,EquipConsume) of
		{error,InlayFeeError} ->
			common_transaction:abort({InlayFeeError,0});
		_ ->
			next
	end,
	NewStoneNum = erlang:length(mod_refining_jingjie:merge_repeat_jingjie_ling_stones(NewEquipStonesList,NewEquipStonesList)),
	EquipGoods2 = EquipGoods#p_goods{stone_num = NewStoneNum,
									 stones = NewEquipStonesList},
    [StoneBaseInfo] = common_config_dyn:find_stone(StoneGoods#p_goods.typeid),
    [MainPropertyList] = common_config_dyn:find(refining,main_property),
    EquipMainProperty = (StoneBaseInfo#p_stone_base_info.level_prop)#p_property_add.main_property,
    MainPropertySeatList = 
        case lists:keyfind(EquipMainProperty,1,MainPropertyList) of
            false ->
                common_transaction:abort({?_LANG_INLAY_ERROR,0});
            {_,SeatList} ->
                case erlang:is_list(SeatList) of
                    true ->
                        SeatList;
                    false ->
                        [SeatList]
                end
        end,
    EquipPro = 
        lists:foldl(
          fun(MainPropertySeat,AccEquipPro) ->
                  NewPropertyValue = erlang:element(MainPropertySeat, AccEquipPro) 
                      + erlang:element(MainPropertySeat,StoneBaseInfo#p_stone_base_info.level_prop),
                  erlang:setelement(MainPropertySeat, AccEquipPro, NewPropertyValue)
          end,EquipGoods2#p_goods.add_property,MainPropertySeatList),
    EquipGoods3 = EquipGoods2#p_goods{add_property = EquipPro},
    %% 洗炼处理，重算精炼系数
    EquipGoods4 = 
        case (EquipGoods3#p_goods.bind =:= false 
              andalso (StoneGoods#p_goods.bind =:= true orelse SymbolGoods#p_goods.bind =:= true)) of
            true ->
                case mod_refining_bind:do_equip_bind_for_inlay(EquipGoods3) of
                    {error,_BindErrorCode} ->
                        EquipGoods3#p_goods{bind = true};
                    {ok,BindGoodsT} ->
                        BindGoodsT
                end;
            false ->
                EquipGoods3
        end,
    EquipGoods5 = 
        case common_misc:do_calculate_equip_refining_index(EquipGoods4) of
            {error,_ErrorIndexCode} ->
                EquipGoods4;
            {ok, EquipGoods4T} ->
                EquipGoods4T
        end,
    mod_bag:update_goods(RoleId,[EquipGoods5]),
    {ok,EquipGoods5,DelList,UpdateList,DelStoneList,UpdateStoneList}.

has_inlay_same_stone_type(EquipStoneList,StoneGoods) ->
	lists:foldl(
	  fun(EquipStone,AccEquipStoneFlag) ->
			  [EquipStoneBaseInfo] = common_config_dyn:find_stone(EquipStone#p_goods.typeid),
			  [StoneBaseInfo] = common_config_dyn:find_stone(StoneGoods#p_goods.typeid),
			  case (AccEquipStoneFlag =:= false 
						andalso StoneBaseInfo#p_stone_base_info.kind =:= EquipStoneBaseInfo#p_stone_base_info.kind) of
				  true ->
					  true;
				  false ->
					  AccEquipStoneFlag
			  end
	  end,false,EquipStoneList).

%% 折卸
do_refining_firing_unload({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_refining_firing_unload2(RoleId,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
        {ok,EquipGoods,SymbolGoodsList,SymbolNumber,IsUnloadRate,UnloadStoneTypeID} ->
            do_refining_firing_unload3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                       EquipGoods,SymbolGoodsList,SymbolNumber,IsUnloadRate,UnloadStoneTypeID)
    end.
do_refining_firing_unload2(RoleId,DataRecord) ->
    #m_refining_firing_tos{firing_list = FiringList, sub_op_type = UnloadStoneTypeID} = DataRecord,
    %% 材料是否足够合法
    case (erlang:length(FiringList) >= 1) of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_UNLOAD_ERROR,0})
    end,
    %% 检查是否有要折卸宝石的装备
    EquipGoods = 
        case lists:foldl(
               fun(EquipPRefiningT,AccEquipPRefiningT) ->
                       case ( AccEquipPRefiningT =:= undefined
                              andalso EquipPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_TARGET
                              andalso EquipPRefiningT#p_refining.goods_type =:= ?TYPE_EQUIP) of
                           true ->
                               EquipPRefiningT;
                           false ->
                               AccEquipPRefiningT
                       end 
               end,undefined,FiringList) of
            undefined ->
                erlang:throw({error,?_LANG_UNLOAD_NO_EQUIP,0});
            EquipPRefiningTT ->
                case mod_bag:check_inbag(RoleId,EquipPRefiningTT#p_refining.goods_id) of
                    {ok,EquipGoodsT} ->
                        case EquipGoodsT#p_goods.stone_num =:= undefined of
                            true ->
                                EquipGoodsT#p_goods{stone_num = 0};
                            false ->
                                EquipGoodsT
                        end;
                    _  ->
                        erlang:throw({error,?_LANG_UNLOAD_NO_EQUIP,0})
                end
        end,
    [EquipBaseInfo] = common_config_dyn:find_equip(EquipGoods#p_goods.typeid),
    if EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
            erlang:throw({error,?_LANG_UNLOAD_MOUNT_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
            erlang:throw({error,?_LANG_UNLOAD_FASHION_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
            erlang:throw({error,?_LANG_UNLOAD_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_SHENQI ->
            erlang:throw({error,?_LANG_UNLOAD_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MARRY ->
            erlang:throw({error,?_LANG_UNLOAD_ADORN_ERROR,0});
       true ->
            next
    end,
    [SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
    case lists:member(EquipGoods#p_goods.typeid,SpecialEquipList) of
        true ->
            erlang:throw({error,?_LANG_UNLOAD_ADORN_ERROR,0});
        _ ->
            next
    end,
    %% 装备是否有宝石
	#p_goods{stones = Stones,typeid = TypeID} = EquipGoods,
    case (Stones =:= undefined orelse Stones =:= []) of
        true ->
            erlang:throw({error,?_LANG_UNLOAD_DO_NOT_UNLOAD,0});
        false ->
            next
    end,
	%% 检查拆卸的宝石是否存在
	case lists:keyfind(UnloadStoneTypeID, #p_goods.typeid, Stones) =:= false
			 andalso mod_refining_jingjie:is_jingjie_ling(TypeID) =:= true of
		true ->
            erlang:throw({error,?_LANG_UNLOAD_DO_NOT_UNLOAD,0});
		false ->
			next
	end,
    SymbolPRefiningTList = 
        lists:foldl(
          fun(SymbolPRefiningT,AccSymbolPRefiningTList) ->
                  case (SymbolPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_MATERIAL
                        andalso SymbolPRefiningT#p_refining.goods_type =:= ?TYPE_ITEM
                        andalso SymbolPRefiningT#p_refining.goods_type_id =:= ?REFINING_UNLOAD_SYMBOL ) of
                      true ->
                          [SymbolPRefiningT|AccSymbolPRefiningTList];
                      false ->
                          AccSymbolPRefiningTList
                  end
          end,[],FiringList),
    case (erlang:length(SymbolPRefiningTList) + 1) =:= erlang:length(FiringList) of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_UNLOAD_HAS_OTHER,0})
    end,
    {SymbolGoodsList,SymbolNumber} = 
        lists:foldl(
          fun(SymbolPRefiningTT,{AccSymbolGoodsList,AccSymbolNumber}) ->
                  case mod_bag:check_inbag(RoleId,SymbolPRefiningTT#p_refining.goods_id) of
                      {ok,SymbolGoodsT} ->
                          {[SymbolGoodsT|AccSymbolGoodsList],AccSymbolNumber + SymbolPRefiningTT#p_refining.goods_number};
                      _  ->
                          erlang:throw({error,?_LANG_UNLOAD_ERROR,0})
                  end
          end,{[],0},SymbolPRefiningTList),
    %% 折卸概率
    IsUnloadRate = 
        if SymbolNumber =:= 4 ->
                true;
           SymbolNumber > 4 ->
                erlang:throw({error,?_LANG_UNLOAD_MAX_SYMBOL,0});
           true ->
                [RandomRateSymbolList] = common_config_dyn:find(refining,random_rate_symbol),
                {_,UnloadRandomRate} = lists:keyfind(SymbolNumber,1,RandomRateSymbolList),
                common_tool:random(1,100) < UnloadRandomRate
        end,
    {ok,EquipGoods,SymbolGoodsList,SymbolNumber,IsUnloadRate,UnloadStoneTypeID}.
do_refining_firing_unload3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                           EquipGoods,SymbolGoodsList,SymbolNumber,IsUnloadRate,UnloadStoneTypeID) ->
    case common_transaction:transaction(
           fun() ->
                   do_t_refining_firing_unload(RoleId,EquipGoods,SymbolGoodsList,SymbolNumber,IsUnloadRate,UnloadStoneTypeID)
           end) of
        {atomic,{ok,EquipGoods2,DelList,UpdateList,StoneGoodsList,DelStoneGoodsList}} ->
	do_refining_firing_unload4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                       EquipGoods2,SymbolGoodsList,SymbolNumber,IsUnloadRate,
                                       DelList,UpdateList,StoneGoodsList,DelStoneGoodsList);
        {aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},?_LANG_REFINING_NOT_BAG_POS_ERROR,0);
                {Reason, ReasonCode} ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
                Reason ->
					?ERROR_MSG("do_refining_firing_unload3 error:~w",[Reason]),
                    Reason2 = ?_LANG_UNLOAD_ERROR,
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2,0)
            end
    end.
do_refining_firing_unload4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                           EquipGoods,SymbolGoodsList,SymbolNumber,IsUnloadRate,
                           DelList,UpdateList,StoneGoodsList,DelStoneGoodsList) ->
    ReasonCode = case IsUnloadRate =:= true of true -> 0; _ -> 1 end,
    SendUpdateList = lists:append([StoneGoodsList,[EquipGoods], UpdateList]),
    SendSelf = #m_refining_firing_toc{
      succ = true,
      reason_code = ReasonCode, %% 折卸成功但宝石降级
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list,
      update_list = [EquipGoods|UpdateList],
      del_list = DelList,
      new_list = StoneGoodsList},
    %% 道具变化通知
    catch common_misc:update_goods_notify({line, Line, RoleId},SendUpdateList),
    if DelList =/= [] ->
            catch common_misc:del_goods_notify({line, Line, RoleId},DelList);
       true ->
            next
    end,
    %% 道具消费日志
    if SymbolNumber > 0 ->
            [HSymbolGoods|_TSymbolGoods] = SymbolGoodsList,
            catch common_item_logger:log(RoleId,HSymbolGoods,SymbolNumber,?LOG_ITEM_TYPE_CHAI_XIE_SHI_QU);
       true ->
            next
    end,

    %% 特殊任务事件
    hook_mission_event:hook_special_event(RoleId,?MISSON_EVENT_REFINING_UNLOAD),

    
    lists:foreach(
      fun(DelStoneGoods) ->
              catch common_item_logger:log(RoleId,DelStoneGoods,1,?LOG_ITEM_TYPE_CHAI_XIE_SHI_QU)
      end,DelStoneGoodsList),
    catch common_item_logger:log(RoleId,EquipGoods,1,?LOG_ITEM_TYPE_CHAI_XIE_HUO_DE),
    lists:foreach(
      fun(AddStoneGoods) ->
              catch common_item_logger:log(RoleId,AddStoneGoods,1,?LOG_ITEM_TYPE_CHAI_XIE_HUO_DE)
      end,StoneGoodsList),
    %% 钱币变化通知
    catch mod_refining:do_refining_deduct_fee_notify(RoleId,{line, Line, RoleId}),
    ?DEBUG("~ts,SendSelf=~w",["天工炉模块返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    ok.
do_t_refining_firing_unload(RoleId,EquipGoods,SymbolGoodsList,SymbolNumber,IsUnloadRate,UnloadStoneTypeID) ->
    %% 扣折卸符
    {DelList,UpdateList} = 
        if SymbolNumber > 0 ->
                case catch mod_equip_build:do_transaction_dedcut_goods(RoleId,SymbolGoodsList,SymbolNumber) of
                    {error,GoodsError} ->
                        common_transaction:abort({GoodsError,0});
                    {ok,DelListT,UpdateListT} ->
                        DelListT2  = 
                            lists:foldl(
                              fun(DelGoods,AccDelListT2) -> 
                                      case lists:keyfind(DelGoods#p_goods.id,#p_goods.id,UpdateListT) of
                                          false ->
                                              [DelGoods | AccDelListT2];
                                          _ ->
                                              AccDelListT2
                                      end
                              end,[],DelListT),
                        {DelListT2,UpdateListT}
                end;
           true ->
                {[],[]}
        end,
	#p_goods{stones=Stones,typeid=TypeID} = EquipGoods,
	{EquipStoneList,RemainStoneList} = 
		case mod_refining_jingjie:is_jingjie_ling(TypeID) of
			true ->
				Stones2 = 
					lists:filter(fun(Stone) ->
										 Stone#p_goods.typeid =:= UnloadStoneTypeID
								 end, Stones),
				UnloadStone = lists:nth(1,Stones2),
				UnloadStones =
					[REquipStone#p_goods{
										 embe_pos = 0,
										 embe_equipid = 0,
										 stone_num = 0} || REquipStone <- Stones2],
				%%计算费用
				FeeEquipStoneNum = erlang:max(UnloadStone#p_goods.embe_pos-1,1),
				UnloadFee = mod_refining:get_refining_fee(equip_unload_fee, EquipGoods#p_goods{stone_num=FeeEquipStoneNum}),
				RemainStones = 
					lists:filter(fun(Stone) ->
										 Stone#p_goods.typeid =/= UnloadStoneTypeID
								 end, Stones),
				%%排序embe_pos
				{UnloadStones,sort_jingjie_unload_remain_stones(RemainStones)};
			false ->
				%%计算费用
				UnloadFee = mod_refining:get_refining_fee(equip_unload_fee, EquipGoods),
				%% 装备宝石处理，装备属性处理
				{[REquipStone#p_goods{
									 embe_pos = 0,
									 embe_equipid = 0,
									 stone_num = 0} || REquipStone <- Stones],[]}
		end,
	%% 扣费
	EquipConsume = #r_equip_consume{type = unload,consume_type = ?CONSUME_TYPE_SILVER_EQUIP_UNLOAD,consume_desc = ""},
	case catch mod_refining:do_refining_deduct_fee(RoleId,UnloadFee,EquipConsume) of
		{error,UnloadFeeError} ->
			common_transaction:abort({UnloadFeeError,0});
		_ ->
			next
	end,
    [MainPropertyList] = common_config_dyn:find(refining,main_property),
    EquipGoods2 = 
        lists:foldl(
          fun(EquipStoneGoods,AccEquipGoods) ->
                  [EquipStoneBaseInfo] = common_config_dyn:find_stone(EquipStoneGoods#p_goods.typeid),
                  EquipMainProperty = (EquipStoneBaseInfo#p_stone_base_info.level_prop)#p_property_add.main_property,
                  MainPropertySeatList = 
                      case lists:keyfind(EquipMainProperty,1,MainPropertyList) of
                          false ->
                              common_transaction:abort({?_LANG_UNLOAD_ERROR,0});
                          {_,SeatList} ->
                              case erlang:is_list(SeatList) of
                                  true ->
                                      SeatList;
                                  false ->
                                      [SeatList]
                              end
					  end,
				  CurNum = 
					  case mod_refining_jingjie:is_jingjie_ling(TypeID) of
						  true ->
							  mod_refining:format_value(EquipStoneGoods#p_goods.current_num,1);
						  false ->
							  1
					  end,
                  EquipPro = 
                      lists:foldl(
                        fun(MainPropertySeat,AccEquipPro) ->
                                NewPropertyValue = erlang:element(MainPropertySeat, AccEquipPro) 
                                    - erlang:element(MainPropertySeat,EquipStoneBaseInfo#p_stone_base_info.level_prop)*CurNum,
                                erlang:setelement(MainPropertySeat, AccEquipPro, NewPropertyValue)
                        end,AccEquipGoods#p_goods.add_property,MainPropertySeatList),
                  AccEquipGoods#p_goods{add_property = EquipPro}
          end,EquipGoods#p_goods{stone_num=erlang:length(mod_refining_jingjie:merge_repeat_jingjie_ling_stones(RemainStoneList,RemainStoneList)),stones=RemainStoneList},EquipStoneList),
    mod_bag:update_goods(RoleId,EquipGoods2),
	%% 生成宝石处理
    StoneGoodsList = 
        case IsUnloadRate of
            true -> %% 正常折卸宝石
                {ok,StoneGoodsListT} = mod_bag:create_goods_by_p_goods(RoleId,EquipStoneList),
                DelStoneGoodsList = [],
                StoneGoodsListT;
            false -> %% 降级折卸宝石
                [StoneLevelLinkList] = common_config_dyn:find(refining,stone_level_link),
                PreStoneCreateInfoList = 
                    lists:foldl(
                      fun(EquipStoneGoods,AccPreStoneCreateInfoList) ->
                              PreStoneTypeId = get_pre_stone_type_id(
                                                 EquipStoneGoods#p_goods.typeid,EquipStoneGoods#p_goods.level,StoneLevelLinkList),
                              case common_config_dyn:find_stone(PreStoneTypeId) of
                                  [PreEquipStoneBaseInfo] ->
                                      [#r_goods_create_info{
                                          type = ?TYPE_STONE,
                                          num=EquipStoneGoods#p_goods.current_num,type_id = PreEquipStoneBaseInfo#p_stone_base_info.typeid,
                                          bind=EquipStoneGoods#p_goods.bind,
                                          start_time = EquipStoneGoods#p_goods.start_time,
                                          end_time = EquipStoneGoods#p_goods.end_time} | AccPreStoneCreateInfoList];
                                  _ ->
                                      AccPreStoneCreateInfoList
                              end
                      end,[],EquipStoneList),
               StoneGoodsListT = 
                    case PreStoneCreateInfoList =:= [] of
                        true ->
                            [];
                        _ ->
                            {ok,StoneGoodsListTT} = mod_bag:create_goods(RoleId,PreStoneCreateInfoList),
                            StoneGoodsListTT
                    end,
                DelStoneGoodsList = EquipStoneList,
                StoneGoodsListT
        end,
    {ok,EquipGoods2,DelList,UpdateList,StoneGoodsList,DelStoneGoodsList}.

%% 境界令拆卸后，重新排序宝石位置
sort_jingjie_unload_remain_stones(RemainStones) ->
	SortRemainStones = 
		lists:sort(fun(#p_goods{embe_pos=Pos1},#p_goods{embe_pos=Pos2}) ->
						   Pos1 > Pos2
				   end,RemainStones),
	{_,NewRemainStones} = 
		lists:foldr(fun(Stone,{Pos,Acc})->
							case lists:keyfind(Stone#p_goods.typeid, #p_goods.typeid, Acc) of
								false ->
									{Pos+1,[Stone#p_goods{embe_pos=Pos+1}|Acc]};
								_ ->
									{Pos,[Stone#p_goods{embe_pos=Pos}|Acc]}
							end
					end,{0,[]},SortRemainStones),
	NewRemainStones.

%% 根据当前灵石的typeid查找基本上一级灵石的typeid
%% 查找不到返回 0
get_pre_stone_type_id(TypeId,Level,StoneLevelLinkList) ->
    lists:foldl(
      fun(SubStoneLevelLinkList,AccPreTypeId) ->
              case ( AccPreTypeId =:= -1
                     andalso lists:member(TypeId,SubStoneLevelLinkList) ) of
                  true ->
                      case Level - 1 > 0 of
                          true ->
                              lists:nth(Level - 1,SubStoneLevelLinkList);
                          false ->
                              0
                      end;
                  false->
                      AccPreTypeId
              end
      end,-1,StoneLevelLinkList).
%% 强化
do_refining_firing_reinforce({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_refining_firing_reinforce2(RoleId,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
        {IsNeedAutoBuy,EquipGoods,ReinforceStuffTypeId,ReinforceStuffGoodsList,
		 ReinforceStuffLevel,ReinforceFee,NewReinforceResult,ReinforceStuffNeedNum} ->
            do_refining_firing_reinforce3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                          IsNeedAutoBuy,EquipGoods,ReinforceStuffTypeId,ReinforceStuffGoodsList,ReinforceStuffLevel,
                                          ReinforceFee,NewReinforceResult,ReinforceStuffNeedNum)
    end.

do_refining_firing_reinforce2(RoleId,DataRecord) ->
	#m_refining_firing_tos{auto_buy_firing_stuff=IsAutoBuy} = DataRecord,
	if IsAutoBuy =:= false->
		   check_refining_firing_reinforce_normal(RoleId, DataRecord);
	   true ->
		   check_refining_firing_reinforce_with_autobuy(RoleId, DataRecord)
	end.

check_refining_firing_reinforce_normal(RoleId,DataRecord) ->
    #m_refining_firing_tos{firing_list = FiringList} = DataRecord,
	%% 材料是否足够合法
	case (erlang:length(FiringList) >= 2) of
		true ->
			next;
		false ->
			erlang:throw({error,?_LANG_REINFORCE_PLACED,0})
	end,
    %% 检查是否有要强化的装备
    {EquipGoods, EquipReinforceLevel, EquipReinforceGrade} = check_reinforce_equip(RoleId, FiringList),
    
    %% 查找出当前强化装备需要的材料配置
    {ReinforceStuffTypeId,ReinforceStuffLevel,ReinforceStuffNeedNum} = get_reinforce_stuff_config(EquipReinforceLevel, EquipReinforceGrade),
	
    %% 检查是否有强化材料
    {ReinforceStuffGoodsList,ReinforceStuffGoodsNumber} = get_reinforce_stuff_goods(RoleId, ReinforceStuffTypeId, FiringList),
    case ReinforceStuffGoodsList =:= [] 
        orelse (erlang:length(ReinforceStuffGoodsList) =/= erlang:length(FiringList) - 1)
        orelse ReinforceStuffNeedNum =/= ReinforceStuffGoodsNumber of
        true ->
			[ReinforceStuffBaseInfo] = common_config_dyn:find_item(ReinforceStuffTypeId),
            erlang:throw({error,
                          common_tool:get_format_lang_resources(
                            ?_LANG_REINFORCE_STUFF_ERROR,[ReinforceStuffNeedNum,ReinforceStuffBaseInfo#p_item_base_info.itemname]),
                          0});
        _ ->
            next
    end,
    %% 计算本次强化可获得的效果
    NewReinforceResult = calc_new_reinforce_result(EquipGoods,ReinforceStuffLevel),
    ReinforceFee = mod_refining:get_refining_fee(equip_reinforce_fee,EquipGoods, ReinforceStuffLevel),
    {?NOT_NEED_AUTO_BUY,EquipGoods,ReinforceStuffTypeId,ReinforceStuffGoodsList,
	 ReinforceStuffLevel,ReinforceFee,NewReinforceResult,ReinforceStuffNeedNum}.

check_refining_firing_reinforce_with_autobuy(RoleId, DataRecord) ->
	#m_refining_firing_tos{firing_list = FiringList} = DataRecord,
	case is_equip_in_firing_list(FiringList) of
		true ->
			next;
		false ->
			erlang:throw({error, ?_LANG_REINFORCE_NO_EQUIP, 0})
	end,
	
	%% 检查是否有要强化的装备
    {EquipGoods, EquipReinforceLevel, EquipReinforceGrade} = check_reinforce_equip(RoleId, FiringList),
	%% 查找出当前强化装备需要的材料配置
    {ReinforceStuffTypeId,ReinforceStuffLevel,ReinforceStuffNeedNum} = get_reinforce_stuff_config(EquipReinforceLevel, EquipReinforceGrade),
	
    {ReinforceStuffGoodsList,ReinforceStuffGoodsNumber} = get_reinforce_stuff_goods(RoleId, ReinforceStuffTypeId, FiringList),
	IsNeedAutoBuy = 
		case (ReinforceStuffGoodsNumber < ReinforceStuffNeedNum) of
			true ->
				?NEED_AUTO_BUY;
			false ->
				case ReinforceStuffGoodsList =:= [] 
						 orelse (erlang:length(ReinforceStuffGoodsList) =/= erlang:length(FiringList) - 1)
						 orelse ReinforceStuffNeedNum =/= ReinforceStuffGoodsNumber of
					true ->
						erlang:throw({error, ?_LANG_SYSTEM_ERROR, 0});
					_->
						?NOT_NEED_AUTO_BUY
				end
		end,
	%% 计算本次强化可获得的效果
	NewReinforceResult = calc_new_reinforce_result(EquipGoods,ReinforceStuffLevel),
	ReinforceFee = mod_refining:get_refining_fee(equip_reinforce_fee, EquipGoods, ReinforceStuffLevel),
	{IsNeedAutoBuy,EquipGoods,ReinforceStuffTypeId,ReinforceStuffGoodsList,
	 ReinforceStuffLevel,ReinforceFee,NewReinforceResult,ReinforceStuffNeedNum}.

%% 检查是否有要强化的装备
check_reinforce_equip(RoleId, FiringList) ->
	EquipGoods = 
		case lists:foldl(
			   fun(EquipPRefiningT,AccEquipPRefiningT) ->
					   case ( AccEquipPRefiningT =:= undefined
								  andalso EquipPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_TARGET
																		 andalso EquipPRefiningT#p_refining.goods_type =:= ?TYPE_EQUIP) of
						   true ->
							   EquipPRefiningT;
						   false ->
							   AccEquipPRefiningT
					   end 
			   end,undefined,FiringList) of
			undefined ->
				erlang:throw({error,?_LANG_REINFORCE_CAN_NOT_MANY_EQUIP,0});
			EquipPRefiningTT ->
				case mod_bag:check_inbag(RoleId,EquipPRefiningTT#p_refining.goods_id) of
					{ok,EquipGoodsT} ->
						EquipGoodsT;
					_  ->
						erlang:throw({error,?_LANG_REINFORCE_CAN_NOT_MANY_EQUIP,0})
				end
		end,
	[EquipBaseInfo] = common_config_dyn:find_equip(EquipGoods#p_goods.typeid),
    if EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
            erlang:throw({error,?_LANG_REINFORCE_MOUNT_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
            erlang:throw({error,?_LANG_REINFORCE_FASHION_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
            erlang:throw({error,?_LANG_REINFORCE_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_JINGJIE ->
            erlang:throw({error,?_LANG_REINFORCE_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_SHENQI ->
            erlang:throw({error,?_LANG_REINFORCE_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MARRY ->
            erlang:throw({error,?_LANG_REINFORCE_ADORN_ERROR,0});
       true ->
            next
    end,
    [SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
    case lists:member(EquipGoods#p_goods.typeid,SpecialEquipList) of
        true ->
            erlang:throw({error,?_LANG_REINFORCE_ADORN_ERROR,0});
        _ ->
            next
    end,
    EquipReinforceLevel = EquipGoods#p_goods.reinforce_result div 10,
    EquipReinforceGrade = EquipGoods#p_goods.reinforce_result rem 10,
    case (EquipReinforceLevel =:= ?REINFORCE_MAX_LEVEL andalso EquipReinforceGrade =:= ?REINFORCE_MAX_GRADE) of
        true ->
            erlang:throw({error,?_LANG_REINFORCE_NO_UPGRADE,0});
        _ ->
            next
    end,
	{EquipGoods, EquipReinforceLevel, EquipReinforceGrade}.

%% 查找出当前强化装备需要的材料配置
get_reinforce_stuff_config(EquipReinforceLevel, EquipReinforceGrade) ->
    [ReinforceStuffLevelList] = common_config_dyn:find(refining,reinforce_stuff),
    case EquipReinforceLevel =:= 0 of
        true ->
            ParamEquipReinforceLevel = 1;
        _ ->
            ParamEquipReinforceLevel = EquipReinforceLevel
    end,
	{ReinforceStuffTypeId,ReinforceStuffLevel,ReinforceStuffNeedNum} = 
    case EquipReinforceGrade =:= ?REINFORCE_MAX_GRADE of
        true ->
            lists:keyfind(ParamEquipReinforceLevel + 1,2,ReinforceStuffLevelList);
        _ ->
            lists:keyfind(ParamEquipReinforceLevel,2,ReinforceStuffLevelList)
    end,
	{ReinforceStuffTypeId,ReinforceStuffLevel,ReinforceStuffNeedNum}.

%% 获取强化材料
get_reinforce_stuff_goods(RoleId, ReinforceStuffTypeId, FiringList) ->
	lists:foldl(
	  fun(ReinforceStuffPRefiningT,{AccReinforceStuffGoodsList,AccReinforceStuffGoodsNumber}) ->
			  case ReinforceStuffPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_MATERIAL
														   andalso ReinforceStuffPRefiningT#p_refining.goods_type =:= ?TYPE_ITEM
														andalso ReinforceStuffPRefiningT#p_refining.goods_type_id =:= ReinforceStuffTypeId of
				  true ->
					  case mod_bag:check_inbag(RoleId,ReinforceStuffPRefiningT#p_refining.goods_id) of
						  {ok,ReinforceStuffGoodsT} ->
							  {[ReinforceStuffGoodsT|AccReinforceStuffGoodsList],
							   AccReinforceStuffGoodsNumber + ReinforceStuffPRefiningT#p_refining.goods_number};
						  _ ->
							  erlang:throw({error,?_LANG_REINFORCE_CAN_NOT_STUFF,0})
					  end;                           
				  false ->
					  {AccReinforceStuffGoodsList,AccReinforceStuffGoodsNumber}
			  end
	  end,{[],0},FiringList).

%% 计算本次强化可获得的效果
calc_new_reinforce_result(EquipGoods,ReinforceStuffLevel) ->
    ReinforceStuffLevel * 10 + mod_refining:get_equip_reinforce_new_grade(EquipGoods,ReinforceStuffLevel).

do_refining_firing_reinforce3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                              IsNeedAutoBuy,EquipGoods,ReinforceStuffTypeId,ReinforceStuffGoodsList,ReinforceStuffLevel,
                              ReinforceFee,NewReinforceResult,ReinforceStuffNeedNum) ->
    case common_transaction:transaction(
           fun() ->
                   do_t_refining_firing_reinforce(IsNeedAutoBuy,RoleId,EquipGoods,ReinforceStuffTypeId,ReinforceStuffGoodsList,
												  ReinforceStuffLevel,ReinforceFee,NewReinforceResult,ReinforceStuffNeedNum)
           end) of
        {atomic,{ok,EquipGoods2,DelList,UpdateList}} ->
            do_refining_firing_reinforce4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                          IsNeedAutoBuy,EquipGoods,EquipGoods2,DelList,UpdateList,
                                          ReinforceStuffGoodsList,ReinforceStuffNeedNum);
        {aborted, Error} ->
            ?DEBUG("Error=~w",[Error]),
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},?_LANG_REFINING_NOT_BAG_POS_ERROR,0);
                {error, Reason, ReasonCode} ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
                {Reason, ReasonCode} ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
                _ ->
                    Reason2 = ?_LANG_REINFORCE_ERROR,
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2,0)
            end
    end.
do_refining_firing_reinforce4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                              IsNeedAutoBuy,OldEquipGoods,NewEquipGoods,DelList,UpdateList,
                              ReinforceStuffGoodsList,_ReinforceStuffNeedNum) ->
    SendSelf = 
        case OldEquipGoods#p_goods.reinforce_result >= NewEquipGoods#p_goods.reinforce_result of
            true ->
                #m_refining_firing_toc{
              succ = true,
              reason = ?_LANG_REINFORCE_USED_PROTECT, %% 星级不变
              reason_code = 1,
              op_type = DataRecord#m_refining_firing_tos.op_type,
              sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
              firing_list = DataRecord#m_refining_firing_tos.firing_list,
              update_list = [NewEquipGoods| UpdateList],
              del_list = DelList,
              new_list = []};
            false ->
                ReinforceLevel = NewEquipGoods#p_goods.reinforce_result div 10,
                ReinforceGrade = NewEquipGoods#p_goods.reinforce_result rem 10,
                SuccReason = common_tool:get_format_lang_resources(?_LANG_REINFORCE_SUCC,[NewEquipGoods#p_goods.name,ReinforceLevel,ReinforceGrade]),
                #m_refining_firing_toc{ succ = true, %% 星级提升
                                        reason = SuccReason,
                                        reason_code = 0,
                                        op_type = DataRecord#m_refining_firing_tos.op_type,
                                        sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
                                        firing_list = DataRecord#m_refining_firing_tos.firing_list,
                                        update_list = [NewEquipGoods| UpdateList],
                                        del_list = DelList,
                                        new_list = []}
        end,
    %% 道具变化通知
    catch common_misc:update_goods_notify({line, Line, RoleId},[NewEquipGoods| UpdateList]),
    if DelList =/= [] ->
            catch common_misc:del_goods_notify({line, Line, RoleId},DelList);
       true ->
            next
    end,
    %% 钱币变化通知
    catch mod_refining:do_refining_deduct_fee_notify(RoleId,{line, Line, RoleId}),
	%% 元宝变化通知
	case IsNeedAutoBuy of 
		?NEED_AUTO_BUY ->
			catch mod_refining:do_refining_deduct_gold_notify(RoleId,{line, Line, RoleId});
		_ ->
			ignore
	end,
    %% 道具消费日志
	if ReinforceStuffGoodsList =/= [] ->
		   [ReinforceStuffGoods|_TReinforceStuffGoods] = ReinforceStuffGoodsList,
		   catch common_item_logger:log(RoleId,ReinforceStuffGoods,erlang:length(ReinforceStuffGoodsList),?LOG_ITEM_TYPE_QIANG_HUA_SHI_QU);
	   true ->
		   ignore
	end,
    catch common_item_logger:log(RoleId,NewEquipGoods,1,?LOG_ITEM_TYPE_QIANG_HUA_HUO_DE),
    hook_refining_firing_reinforce(RoleId,OldEquipGoods,NewEquipGoods),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    ok.

hook_refining_firing_reinforce(RoleId,_OldEquipGoods,NewEquipGoods) ->
	%% 成就 add by caochuncheng 2011-03-07
    [#p_equip_base_info{slot_num = SlotNum}]=common_config_dyn:find_equip(NewEquipGoods#p_goods.typeid),
    _AchEventIdList = 
        if NewEquipGoods#p_goods.reinforce_result >= 66 ->
                if SlotNum =:= 1 ->
                        [304002,304004,304003];
                   true ->
                        [304002,304004]
                end;
           NewEquipGoods#p_goods.reinforce_result >= 40 ->
                if SlotNum =:= 1 ->
                        [304002,304003];
                   true ->
                        [304002]
                end;
           true ->
                [304002]
        end,
    %% 特殊任务事件
    hook_mission_event:hook_special_event(RoleId,?MISSON_EVENT_REINFORCE).

do_t_refining_firing_reinforce(IsNeedAutoBuy, RoleId,EquipGoods,ReinforceStuffTypeId,ReinforceStuffGoodsList,
							   _ReinforceStuffLevel,ReinforceFee,NewReinforceResult,ReinforceStuffNeedNum) ->
	{EquipNeedBind, DelList,UpdateList} = 
		case IsNeedAutoBuy of 
			?NOT_NEED_AUTO_BUY ->
				deduct_reinforce_fee_and_stuff(RoleId, ReinforceFee, ReinforceStuffGoodsList, ReinforceStuffNeedNum);
			?NEED_AUTO_BUY ->
				deduct_reinforce_auto_buy_stuff(RoleId, ReinforceFee, ReinforceStuffTypeId, ReinforceStuffGoodsList, ReinforceStuffNeedNum)
		end,
    %% 要所获得的新的强化结果处理装备属性
    EquipGoods2 = 
        case (EquipGoods#p_goods.bind =/= true 
            andalso lists:member(true,[ReinforceStuffGoods#p_goods.bind || ReinforceStuffGoods <- ReinforceStuffGoodsList]))
			orelse (EquipGoods#p_goods.bind =/= true andalso EquipNeedBind =:= true) of
            true ->
                case mod_refining_bind:do_equip_bind_for_reinforce(EquipGoods) of
                    {error,_IndexErrorCode} ->
                        EquipGoods#p_goods{bind=true};
                    {ok,BindGoods} ->
                        BindGoods
                end;
            _ ->
                EquipGoods
        end, 
    case EquipGoods2#p_goods.reinforce_result >= NewReinforceResult of
        true ->
            mod_bag:update_goods(RoleId,EquipGoods2),
            {ok,EquipGoods2,DelList,UpdateList};
        false ->
            do_t_refining_firing_reinforce2(RoleId,EquipGoods2,NewReinforceResult,DelList,UpdateList)
    end.

deduct_reinforce_fee_and_stuff(RoleId, ReinforceFee, ReinforceStuffGoodsList, ReinforceStuffNeedNum) ->
%% 扣费
    EquipConsume = #r_equip_consume{
      type = reinforce,consume_type = ?CONSUME_TYPE_SILVER_EQUIP_REINFORCE,consume_desc = ""},
    case catch mod_refining:do_refining_deduct_fee(RoleId,ReinforceFee,EquipConsume) of
        {error,ReinforceFeeError} ->
            common_transaction:abort({ReinforceFeeError,0});
        _ ->
            next
    end,
    {DelList,UpdateList} = deduct_refining_stuff(RoleId,ReinforceStuffGoodsList,ReinforceStuffNeedNum),
	{false, DelList,UpdateList}.

deduct_reinforce_auto_buy_stuff(RoleId, ReinforceFee, ReinforceStuffTypeId, ReinforceStuffGoodsList, ReinforceStuffNeedNum) ->
	AutoBuyNum = ReinforceStuffNeedNum - erlang:length(ReinforceStuffGoodsList),
	%% 扣自动购买强化材料的费用
	EquipNeedBind = deduct_auto_buy_stuff_fee(reinforce, RoleId, ReinforceStuffTypeId, AutoBuyNum, ReinforceFee),
	
	%% 扣费
    EquipConsume = #r_equip_consume{type = reinforce,consume_type = ?CONSUME_TYPE_SILVER_EQUIP_REINFORCE,consume_desc = ""},
    case catch mod_refining:do_refining_deduct_fee(RoleId,ReinforceFee,EquipConsume) of
        {error,ReinforceFeeError} ->
            common_transaction:abort({ReinforceFeeError,0});
        _ ->
            next
    end,
	
    %% 扣强化材料
	if AutoBuyNum > 0 ->
		   {DelList,UpdateList} = deduct_refining_stuff(RoleId,ReinforceStuffGoodsList,erlang:length(ReinforceStuffGoodsList));
	   true ->
		   DelList = [],
		   UpdateList = []
	end,
	{EquipNeedBind, DelList, UpdateList}.

get_stuff_price(StuffTypeId, AutoBuyNum) ->
    %% 按照快速购买-锻造价格
	case mod_shop:get_goods_price_ex(70023,StuffTypeId) of
		{ok, {PriceBind, gold, Price}} ->
			{PriceBind, gold, Price * AutoBuyNum};
		{ok, {PriceBind, silver, Price}} ->
			{PriceBind, silver, Price * AutoBuyNum};
		Error ->
			common_transaction:abort({Error,0})
	end.

do_t_refining_firing_reinforce2(RoleId,EquipGoods,NewReinforceResult,DelList,UpdateList) ->
    OldReinforceResult = EquipGoods#p_goods.reinforce_result,
    EquipGoods2 = 
        if erlang:is_list(EquipGoods#p_goods.reinforce_result_list) 
           andalso erlang:is_integer(OldReinforceResult) ->
                EquipGoods#p_goods{reinforce_result = NewReinforceResult,
                                  reinforce_result_list = [OldReinforceResult|EquipGoods#p_goods.reinforce_result_list]};
           erlang:is_integer(OldReinforceResult) ->
                EquipGoods#p_goods{reinforce_result = NewReinforceResult,
                                   reinforce_result_list = [OldReinforceResult]};
           true ->
                EquipGoods#p_goods{reinforce_result = NewReinforceResult,
                                   reinforce_result_list = []}
        end,
    [ReinforceRateList]=common_config_dyn:find(refining,reinforce_rate),
    OldReinforceLevel = OldReinforceResult div 10,
    OldReinforceGrade = OldReinforceResult rem 10,
    OldReinforceRate = EquipGoods#p_goods.reinforce_rate,
    {_,OldReinforceGradeRate} = lists:keyfind({OldReinforceLevel,OldReinforceGrade},1,ReinforceRateList),
    NewReinforceLevel = NewReinforceResult div 10,
    NewReinforceGrade = NewReinforceResult rem 10,
    {_,NewReinforceGradeRate} = lists:keyfind({NewReinforceLevel,NewReinforceGrade},1,ReinforceRateList),
    [EquipBaseInfo] = common_config_dyn:find_equip(EquipGoods2#p_goods.typeid),
    EquipMainProperty = (EquipBaseInfo#p_equip_base_info.property)#p_property_add.main_property,
    EquipGoods3 = 
        case (OldReinforceRate =:= 0 orelse OldReinforceRate =:= undefined) of
            true ->
                NewEquipPro=mod_refining:change_main_property(
                              EquipMainProperty,EquipGoods2#p_goods.add_property,
                              EquipBaseInfo#p_equip_base_info.property,0,NewReinforceGradeRate),
                EquipGoods2#p_goods{reinforce_rate = NewReinforceGradeRate,add_property = NewEquipPro};
            _ ->
                NewEquipPro=mod_refining:change_main_property(
                              EquipMainProperty,EquipGoods2#p_goods.add_property,
                              EquipBaseInfo#p_equip_base_info.property,OldReinforceGradeRate,NewReinforceGradeRate),
                EquipGoods2#p_goods{reinforce_rate = NewReinforceGradeRate,add_property = NewEquipPro}
        end,
    EquipGoods4 = 
        case common_misc:do_calculate_equip_refining_index(EquipGoods3) of
            {error,_IndexError} ->
                EquipGoods3;
            {ok,IndexGoods} ->
                IndexGoods
        end,
    mod_bag:update_goods(RoleId,EquipGoods4),
    {ok,EquipGoods4,DelList,UpdateList}.


%% 合成 
do_refining_firing_compose({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_refining_firing_compose2(RoleId,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
        {ok,GoodsList,NextGoodsTypeId,NextGoodsType,PRefiningNumber,GoodsSumNumber,GoodsNotBindNumber,GoodsBindNumber} ->
            do_refining_firing_compose3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                        GoodsList,NextGoodsTypeId,NextGoodsType,PRefiningNumber,
                                        GoodsSumNumber,GoodsNotBindNumber,GoodsBindNumber)
    end.
do_refining_firing_compose2(RoleId,DataRecord) ->
    #m_refining_firing_tos{firing_list = FiringList1,sub_op_type = SubOpType} = DataRecord,
    case (SubOpType =:= ?FIRING_OP_TYPE_COMPOSE_3 
          orelse SubOpType =:= ?FIRING_OP_TYPE_COMPOSE_2
          orelse SubOpType =:= ?FIRING_OP_TYPE_COMPOSE_4
          orelse SubOpType =:= ?FIRING_OP_TYPE_COMPOSE_5) of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_COMPOSE_ERROR_TYPE,0})
    end,
    case erlang:length(FiringList1) > 0 of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_COMPOSE_NO_GOODS,0})
    end,
    FiringList2 = lists:sublist(FiringList1, 1),
    %% 检查参数是否是同一材料
    {GoodsPRefiningTList,PRefiningNumber} = 
        case 
            lists:foldl(
              fun(GoodsPRefiningT,{AccPRefiningTypeId,AccPRefiningNumber,AccGoodsPRefiningTList}) ->
                      case AccPRefiningTypeId =:= 0 of
                          true ->
                              AccPRefiningTypeId2 = GoodsPRefiningT#p_refining.goods_type_id;
                          false ->
                              AccPRefiningTypeId2 = AccPRefiningTypeId
                      end,
                      case common_config_dyn:find(compose,AccPRefiningTypeId2) of
                          [NextGoodsTypeIdT] ->
                              NextGoodsTypeIdT;
                          _ ->
                              erlang:throw({error, ?_LANG_COMPOSE_CANT_COMPOSE,0})
                      end,
                      case (GoodsPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_MATERIAL
                            andalso AccPRefiningTypeId2 =:= GoodsPRefiningT#p_refining.goods_type_id) of
                          true ->
                              AccPRefiningNumber2 = AccPRefiningNumber + GoodsPRefiningT#p_refining.goods_number,
                              {AccPRefiningTypeId2,AccPRefiningNumber2,[GoodsPRefiningT|AccGoodsPRefiningTList]};
                          false ->
                              {AccPRefiningTypeId2,AccPRefiningNumber,AccGoodsPRefiningTList}
                      end
              end,{0,0,[]},FiringList2) of
            {_AccPRefiningTypeId,PRefiningNumberT,GoodsPRefiningTListT} ->
                {GoodsPRefiningTListT,PRefiningNumberT};
            _ ->
                erlang:throw({error,?_LANG_COMPOSE_MORE_THAN_ONE_KIND,0})
        end,
    case (erlang:length(GoodsPRefiningTList) =:= erlang:length(FiringList2)) of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_COMPOSE_MORE_THAN_ONE_KIND,0})
    end,
    case (SubOpType =:= ?FIRING_OP_TYPE_COMPOSE_3  andalso PRefiningNumber >= ?FIRING_OP_TYPE_COMPOSE_3)
        orelse (SubOpType =:= ?FIRING_OP_TYPE_COMPOSE_2  andalso PRefiningNumber >= ?FIRING_OP_TYPE_COMPOSE_2)
        orelse (SubOpType =:= ?FIRING_OP_TYPE_COMPOSE_4  andalso PRefiningNumber >= ?FIRING_OP_TYPE_COMPOSE_4)
        orelse (SubOpType =:= ?FIRING_OP_TYPE_COMPOSE_5  andalso PRefiningNumber >= ?FIRING_OP_TYPE_COMPOSE_5) of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_COMPOSE_NOT_ENOUGH_NUM,0})
    end,
	[GoodsPRefiningTT] = GoodsPRefiningTList,
	case mod_bag:check_inbag_by_typeid(RoleId,GoodsPRefiningTT#p_refining.goods_type_id) of
      {ok,GoodsPRefiningTList2} ->
          GoodsPRefiningTList2;
      _ ->
		  GoodsPRefiningTList2 = [],
          erlang:throw({error,?_LANG_COMPOSE_GOODS_NUMBER_DIFF,0})
    end,
	{GoodsList,GoodsBindNumber,GoodsNotBindNumber,_} = lists:foldl(fun
		(GoodsT,{AccGoodsList,AccGoodsBindNumber,AccGoodsNotBindNumber,PRefiningNumber2}) when PRefiningNumber2 > 0  ->
			 AddNum = min(GoodsT#p_goods.current_num, PRefiningNumber2),
             case GoodsT#p_goods.bind of
				 true ->
					 AccGoodsBindNumber2 = AccGoodsBindNumber + AddNum,
					 AccGoodsNotBindNumber2 = AccGoodsNotBindNumber;
				 false ->
					 AccGoodsBindNumber2 = AccGoodsBindNumber,
					 AccGoodsNotBindNumber2 = AccGoodsNotBindNumber + AddNum
			 end,
			 {[GoodsT|AccGoodsList],AccGoodsBindNumber2,AccGoodsNotBindNumber2,PRefiningNumber2-AddNum};
        (_GoodsT,{AccGoodsList,AccGoodsBindNumber,AccGoodsNotBindNumber,PRefiningNumber2}) ->
            {AccGoodsList,AccGoodsBindNumber,AccGoodsNotBindNumber,PRefiningNumber2}
	 end,{[],0,0,PRefiningNumber},GoodsPRefiningTList2),
    GoodsSumNumber = lists:sum([GoodsRecord#p_goods.current_num  || GoodsRecord <-  GoodsList]),
	case GoodsSumNumber >= PRefiningNumber of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_COMPOSE_GOODS_NUMBER_DIFF,0})
    end,
    [HGoods|_TGoods] = GoodsList,
    %% 生成材料的类型
    [NextGoodsTypeId] = common_config_dyn:find(compose,HGoods#p_goods.typeid),
    NextGoodsType = NextGoodsTypeId div 10000000,

    % NextGoodsType = 
        % case common_config_dyn:find_item(NextGoodsTypeId) of
        %     [_NextGoodsItemBaseInfo] ->
        %         ?TYPE_ITEM;
        %     _ ->
        %         case common_config_dyn:find_stone(NextGoodsTypeId) of
        %             [_NextGoodsStoneBaseInfo] ->
        %                 ?TYPE_STONE;
        %             _ ->
        %                 erlang:throw({error,?_LANG_COMPOSE_CANT_COMPOSE,0})
        %         end
        % end,
    {ok,GoodsList,NextGoodsTypeId,NextGoodsType,PRefiningNumber,GoodsSumNumber,GoodsNotBindNumber,GoodsBindNumber}.
%% 根据合成的的类型计算生成的新的物品
get_goods_compose(RoleId,TotalNumber,NotBindNumber,BindNumber,ComposeType, Increase) ->
    %% 根据合成的的类型计算生成的新的物品
    %% 剩下的物品数量 不绑定和绑定 RestNotBindNumber,RestBindNumber
    %% 实际使用的物品数量 不绑定和绑定 DelNotBindNumber,DelBindNumber
    {RestNotBindNumber, RestBindNumber, DelNotBindNumber, DelBindNumber} = 
        case TotalNumber rem ComposeType of
            0 ->
                {0, 0, NotBindNumber, BindNumber};
            Mod ->
                case BindNumber > TotalNumber  - Mod of
                    false ->
                        {Mod, 0, TotalNumber - BindNumber - Mod, BindNumber};
                    true ->
                        {TotalNumber - BindNumber, BindNumber - (TotalNumber - Mod),0,TotalNumber - Mod}
                end
        end,
    %% 实际合成的物品的不绑定和绑定 GoodsNotBindNumber2,GoodsBindNumber2
    GoodsNotBindNumber = DelNotBindNumber div ComposeType,
    GoodsBindNumber = ((DelNotBindNumber rem ComposeType)  + DelBindNumber) div ComposeType,
	%%检查元宝和玄天石是否足够支付合成
	% {ok,RoleAttr} = mod_map_role:get_role_attr(RoleId),
	case ComposeType of
		?FIRING_OP_TYPE_COMPOSE_5 ->
            GoldCost = 0,
			UpdateList = DeleteList = [];
		_ ->
			{ok,UpdateList,DeleteList, GoldCost} = refining_del_gold(RoleId, Increase, GoodsNotBindNumber + GoodsBindNumber)
	end,
    GoodsNotBindNumber2 = 
        lists:foldl(
          fun(_NotBindIndex,AccGoodsNotBindNumber2) -> 
                  case is_goods_compose_success(ComposeType, Increase) of
                      true ->
                          AccGoodsNotBindNumber2 + 1;
                      _ ->
                          AccGoodsNotBindNumber2
                  end
          end,0,lists:seq(1,GoodsNotBindNumber,1)),
    GoodsBindNumber2 = 
        lists:foldl(
          fun(_BindIndex,AccGoodsBindNumber2) ->
                  case is_goods_compose_success(ComposeType, Increase) of
                      true ->
                          AccGoodsBindNumber2 + 1;
                      _ ->
                          AccGoodsBindNumber2
                  end
          end,0,lists:seq(1,GoodsBindNumber,1)),
    ?DEV("RestNotBindNumber=~w,RestBindNumber=~w,DelNotBindNumber=~w,DelBindNumber=~w,GoodsNotBindNumber=~w,GoodsBindNumber=~w",
           [RestNotBindNumber, RestBindNumber, DelNotBindNumber, DelBindNumber,GoodsNotBindNumber2,GoodsBindNumber2]),
    {ok,RestNotBindNumber, RestBindNumber, DelNotBindNumber, DelBindNumber,GoodsNotBindNumber2,GoodsBindNumber2,UpdateList,DeleteList,GoldCost}.

%%使用元宝或者玄天石增加概率的情况下，减少玩家对应的玄天石或者元宝
refining_del_gold(_RoleId, Increase, _Num) when Increase == false ->
	{ok,[],[],0};
refining_del_gold(RoleId, _Increase, Num) ->
	%%查找玄天石对应的物品id
	ConsumeItemTypeID = 11600066,
	%%从玩家背包中查找对应物品id的数量
	{ok, GoodsNums} = mod_bag:get_goods_num_by_typeid([1,2,3], RoleId, ConsumeItemTypeID),
	case Num - GoodsNums of
		GoldNum when GoldNum == Num ->   %%如果没有玄天石
            GoldCost = GoldNum * 2,
            {ok,[],[],GoldCost};
			% case common_bag2:t_deduct_money(gold_unbind, GoldNum * 2, RoleId, ?CONSUME_TYPE_GOLD_EQUIP_COMPOSE) of
			% 	{ok, NewRoleAttr} ->
			% 		{ok,NewRoleAttr,[],[]};
			% 	{error, Reason} ->
			% 		?THROW_ERR(?ERR_OTHER_ERR, Reason)
			% end;
		GoldNum when GoldNum =< 0 ->       %%如果玄天石的数量足够支付合成，直接扣除玄天石
            GoldCost = 0,
			{ok,UpList,DelList} = mod_bag:decrease_goods_by_typeid(RoleId, ConsumeItemTypeID, Num),
			{ok,UpList,DelList,GoldCost};
		_ ->	  %%如果玄天石数量不足支付合成，扣除所有玄天石后扣除元宝
			%%先扣除玄天石
            GoldCost = 2 * (Num - GoodsNums),
			{ok,UpList,DelList} = mod_bag:decrease_goods_by_typeid(RoleId, ConsumeItemTypeID, GoodsNums),
			{ok, UpList, DelList, GoldCost}
            % case common_bag2:t_deduct_money(gold_unbind, 2 * (Num - GoodsNums), RoleId, ?CONSUME_TYPE_GOLD_EQUIP_COMPOSE) of
			% 	{ok, NewRoleAttr} ->
			% 		{ok, NewRoleAttr, UpList, DelList};
			% 	{error, Reason} ->
			% 		?THROW_ERR(?ERR_OTHER_ERR, Reason)
			% end
	end.

%% 根据合成的类型计算单次合成的概率
%% 返回 true or false
is_goods_compose_success(ComposeType, Increase) when Increase =:= false ->
    case ComposeType of
        ?FIRING_OP_TYPE_COMPOSE_5 ->
            true;
        ?FIRING_OP_TYPE_COMPOSE_4 ->
            true;
        ?FIRING_OP_TYPE_COMPOSE_3 ->
            random:uniform(100) =< 70;
        ?FIRING_OP_TYPE_COMPOSE_2 -> %% 装备只能2合一，且一定成功
            true;
        _ ->
            false
    end;

is_goods_compose_success(ComposeType, _Increase) ->
    case ComposeType of
        ?FIRING_OP_TYPE_COMPOSE_5 ->
            true;
        ?FIRING_OP_TYPE_COMPOSE_4 ->
            true;
        ?FIRING_OP_TYPE_COMPOSE_3 ->
            true;
        ?FIRING_OP_TYPE_COMPOSE_2 -> %% 装备只能2合一，且一定成功
            true;
        _ ->
            false
    end.

do_refining_firing_compose3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                            GoodsList,NextGoodsTypeId,NextGoodsType,PRefiningNumber,
                            GoodsSumNumber,GoodsNotBindNumber,GoodsBindNumber) ->
    case common_transaction:transaction(
           fun() ->
                   do_t_refining_firing_compose(RoleId,DataRecord,GoodsList,NextGoodsTypeId,NextGoodsType,
                                                PRefiningNumber,GoodsSumNumber,GoodsNotBindNumber,GoodsBindNumber)
           end) of
        {atomic,{ok,OldNotBindGoodsList,OldBindGoodsList,NewNotBindGoodsList,NewBindGoodsList,
                 OldNotBindNumber,OldBindNumber,NewNotBindNumber,NewBindNumber,DelGoodsNumber,NewRoleAttr,UpdateList,DeleteList}} ->
            do_refining_firing_compose4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                        GoodsList,NextGoodsTypeId,PRefiningNumber,
                                        OldNotBindGoodsList,OldBindGoodsList,NewNotBindGoodsList,NewBindGoodsList,
                                        OldNotBindNumber,OldBindNumber,NewNotBindNumber,NewBindNumber,DelGoodsNumber,NewRoleAttr,UpdateList,DeleteList);
        {aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},?_LANG_REFINING_NOT_BAG_POS_ERROR,0);
                {Reason, ReasonCode} ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
				{error,ErrCode,Reason} ->
					do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ErrCode);
                _ ->
                    Reason2 = ?_LANG_COMPOSE_ERROR,
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2,0)
            end
    end.
do_refining_firing_compose4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                            GoodsList, NextGoodsTypeId,PRefiningNumber,
                            OldNotBindGoodsList,OldBindGoodsList,NewNotBindGoodsList,NewBindGoodsList,
                            OldNotBindNumber,OldBindNumber,NewNotBindNumber,NewBindNumber,DelGoodsNumber,NewRoleAttr,UpdateList,DeleteList) ->
    case NewNotBindGoodsList=:= [] andalso NewBindGoodsList =:= [] of
        true ->
            Reason = ?_LANG_COMPOSE_COMPOSE_ERROR,
            ReasonCode = 2,
            NewCreateList = [];
        _ ->
            NewNextGoods = lists:keyfind(NextGoodsTypeId,#p_goods.typeid,lists:append([NewNotBindGoodsList,NewBindGoodsList])),
            NewNextGoodsName = common_goods:get_notify_goods_name(NewNextGoods#p_goods{current_num = NewNotBindNumber + NewBindNumber}),
            Reason = common_tool:get_format_lang_resources(?_LANG_COMPOSE_COMPOSE_SUCC,[NewNextGoodsName]), 
            ReasonCode = 0,
            NewCreateList = [NewNextGoods#p_goods{current_num = NewNotBindNumber + NewBindNumber}]
    end,
    case (OldNotBindGoodsList =/= [] orelse OldBindGoodsList =/= []) andalso (PRefiningNumber - DelGoodsNumber) > 0 of
        true ->
            [OldCreateGoods|_TOldCreateGoods] = lists:append([OldNotBindGoodsList,OldBindGoodsList]),
            OldCreateList = [OldCreateGoods#p_goods{current_num = PRefiningNumber - DelGoodsNumber}];
        _ ->
            OldCreateList = []
    end,
            
    NewList = lists:append([OldNotBindGoodsList,OldBindGoodsList,NewNotBindGoodsList,NewBindGoodsList]),
    SendSelf = #m_refining_firing_toc{
      succ = true,
      reason = Reason,
      reason_code = ReasonCode,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list,
      update_list = [],
      del_list = GoodsList,
      new_list = lists:append([OldCreateList,NewCreateList])},
    %% 道具变化通知
    common_misc:update_goods_notify({line, Line, RoleId},lists:append([NewList,UpdateList])),
    common_misc:del_goods_notify({line, Line, RoleId},lists:append([GoodsList,DeleteList])),
	common_misc:send_role_gold_change(RoleId, NewRoleAttr),
    
    %% 特殊任务事件
    hook_mission_event:hook_special_event(RoleId,?MISSON_EVENT_REFINING_COMPOSE),
    
    %% 道具消费日志
    lists:foreach(
      fun(OldGoods) ->
              catch common_item_logger:log(RoleId,OldGoods,?LOG_ITEM_TYPE_HE_CHENG_SHI_QU)
      end,GoodsList),
    case NewNotBindGoodsList=:= [] andalso NewBindGoodsList =:= [] of
        true ->
            ignore;
        _ ->
            [NewNextGoodsLog|_TNewNextGoodsLog] = lists:append([NewNotBindGoodsList,NewBindGoodsList]),
            catch common_item_logger:log(RoleId,NewNextGoodsLog,NewNotBindNumber + NewBindNumber,?LOG_ITEM_TYPE_HE_CHENG_HUO_DE)
    end,
    case OldNotBindGoodsList =:= [] andalso OldBindGoodsList =:= [] of
        true ->
            ignore;
        _ ->
            [OldGoodsLog|_TOldGoodsLog] = lists:append([OldNotBindGoodsList,OldBindGoodsList]),
            catch common_item_logger:log(RoleId,OldGoodsLog,OldNotBindNumber + OldBindNumber,?LOG_ITEM_TYPE_HE_CHENG_HUO_DE)
    end,
    ?DEBUG("~ts,SendSelf=~w",["天工炉模块返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    ok.
do_t_refining_firing_compose(RoleId,DataRecord,GoodsList,NextGoodsTypeId,NextGoodsType,
                             PRefiningNumber, _GoodsSumNumber,GoodsNotBindNumber,GoodsBindNumber) ->
    #m_refining_firing_tos{sub_op_type = SubOpType, increase = Increase} = DataRecord,
    %% 计算本居合成想关的材料数量
    %% 剩余的不绑定和绑定，删除的不绑定和绑定，合成的不绑定和绑定
    {ok,_RestNotBindNumber,_RestBindNumber,DelNotBindNumber,DelBindNumber,NewNotBindNumber,NewBindNumber,UpdateList,DeleteList,GoldCost} = 
        get_goods_compose(RoleId,PRefiningNumber,GoodsNotBindNumber,GoodsBindNumber,SubOpType, Increase),
    %% 删除材料
    [HGoods|_TGoods] = GoodsList,
    {DelGoodsNotBindNumber,DelGoodsBindNumber} = 
        lists:foldl(
          fun(OldGoods,{AccDelGoodsNotBindNumber,AccDelGoodsBindNumber}) ->
                  case OldGoods#p_goods.bind of
                      true ->
                          {AccDelGoodsNotBindNumber,AccDelGoodsBindNumber + OldGoods#p_goods.current_num};
                      _ ->
                          {AccDelGoodsNotBindNumber + OldGoods#p_goods.current_num,AccDelGoodsBindNumber}
                  end
          end,{0,0},GoodsList),
    mod_bag:delete_goods(RoleId,[OldGoodsId || #p_goods{id = OldGoodsId} <- GoodsList]),
    {OldNotBindGoodsList,OldNotBindNumber} = 
        case  DelGoodsNotBindNumber - DelNotBindNumber > 0 of
            true ->
                OldNotBindCreateInfo = #r_goods_create_info{
                  type = HGoods#p_goods.type,type_id = HGoods#p_goods.typeid,num = DelGoodsNotBindNumber - DelNotBindNumber,
                  bind = false},
                {ok,OldNotBindGoodsListT} = mod_bag:create_goods(RoleId,OldNotBindCreateInfo),
                {OldNotBindGoodsListT,DelGoodsNotBindNumber - DelNotBindNumber};
            false ->
                {[],0}
        end,
    {OldBindGoodsList,OldBindNumber} = 
        case  DelGoodsBindNumber - DelBindNumber > 0 of
            true ->
                OldBindCreateInfo = #r_goods_create_info{
                  type = HGoods#p_goods.type,type_id = HGoods#p_goods.typeid,num = DelGoodsBindNumber - DelBindNumber,
                  bind = true},
                {ok,OldBindGoodsListT} = mod_bag:create_goods(RoleId,OldBindCreateInfo),
                {OldBindGoodsListT,DelGoodsBindNumber - DelBindNumber};
            false ->
                {[],0}
        end,
    %% 生成合成材料
    NewNotBindGoodsList = 
        case NewNotBindNumber > 0 of
            true ->
                NewNotBindCreateInfo = #r_goods_create_info{
                  type = NextGoodsType,type_id = NextGoodsTypeId,num = NewNotBindNumber,bind = false},
                {ok,NewNotBindGoodsListT} = mod_bag:create_goods(RoleId,NewNotBindCreateInfo),
                NewNotBindGoodsListT;
            false ->
                []
        end,
    NewBindGoodsList = 
        case NewBindNumber > 0 of
            true ->
                NewBindGreateInfo = #r_goods_create_info{
                  type = NextGoodsType,type_id = NextGoodsTypeId,num = NewBindNumber,bind = true},
                {ok,NewBindGoodsListT} = mod_bag:create_goods(RoleId,NewBindGreateInfo),
                NewBindGoodsListT;
            false ->
                []
        end,
        case GoldCost == 0 of
            true ->
            %% 最后来扣钱
                {ok,NewRoleAttr} = mod_map_role:get_role_attr(RoleId),
                ok;
            _ ->
                case common_bag2:t_deduct_money(gold_unbind, GoldCost, RoleId, ?CONSUME_TYPE_GOLD_EQUIP_COMPOSE) of
                  {ok, NewRoleAttr} ->
                      ok;
                  {error, Reason} ->
                      NewRoleAttr = null,
                      ?THROW_ERR(?ERR_OTHER_ERR, Reason)
                end
        end, 
    {ok,OldNotBindGoodsList,OldBindGoodsList,NewNotBindGoodsList,NewBindGoodsList,
     OldNotBindNumber,OldBindNumber,NewNotBindNumber,NewBindNumber,DelNotBindNumber + DelBindNumber,NewRoleAttr,UpdateList,DeleteList}.
%% 附加
do_refining_firing_addprop({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_refining_firing_addprop2(RoleId,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
        {ok,EquipGoods,BindGoods,BindItemRecord,AddPropFee} ->
            do_refining_firing_addprop3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                        EquipGoods,BindGoods,BindItemRecord,AddPropFee)
    end.
do_refining_firing_addprop2(RoleId,DataRecord) ->
    #m_refining_firing_tos{firing_list = FiringList,sub_op_type = SubOpType } = DataRecord,
    case SubOpType =:= ?EQUIP_BIND_TYPE_FIRST
        orelse SubOpType =:= ?EQUIP_BIND_TYPE_REBIND of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_EQUIP_BIND_TYPE_ERROR,0})
    end,
    %% 材料是否足够合法
    case (erlang:length(FiringList) =:= 2) of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_EQUIP_BIND_GOODS_ERROR,0})
    end,
    %% 检查是否有要打孔的装备
    EquipGoods = 
        case lists:foldl(
               fun(EquipPRefiningT,AccEquipPRefiningT) ->
                       case ( AccEquipPRefiningT =:= undefined
                              andalso EquipPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_TARGET
                              andalso EquipPRefiningT#p_refining.goods_type =:= ?TYPE_EQUIP) of
                           true ->
                               EquipPRefiningT;
                           false ->
                               AccEquipPRefiningT
                       end 
               end,undefined,FiringList) of
            undefined ->
                erlang:throw({error,?_LANG_EQUIP_BIND_EQUIP_ID_ERROR,0});
            EquipPRefiningTT ->
                case mod_bag:check_inbag(RoleId,EquipPRefiningTT#p_refining.goods_id) of
                    {ok,EquipGoodsT} ->
                        EquipGoodsT;
                    _  ->
                        erlang:throw({error,?_LANG_EQUIP_BIND_EQUIP_ID_ERROR,0})
                end
        end,
    [EquipBaseInfo] = common_config_dyn:find_equip(EquipGoods#p_goods.typeid),
    if EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
            erlang:throw({error,?_LANG_EQUIP_BIND_MOUNT_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
            erlang:throw({error,?_LANG_EQUIP_BIND_FASHION_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
            erlang:throw({error,?_LANG_EQUIP_BIND_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_JINGJIE ->
            erlang:throw({error,?_LANG_EQUIP_BIND_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_SHENQI ->
            erlang:throw({error,?_LANG_EQUIP_BIND_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MARRY ->
            erlang:throw({error,?_LANG_EQUIP_BIND_ADORN_ERROR,0});
       true ->
            next
    end,
    [SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
    case lists:member(EquipGoods#p_goods.typeid,SpecialEquipList) of
        true ->
            erlang:throw({error,?_LANG_EQUIP_BIND_ADORN_ERROR,0});
        _ ->
            next
    end,
    %% 检查是否有绑定材料
    BindGoods = 
        case lists:foldl(
               fun(BindPRefiningT,AccBindPRefiningT) ->
                       case ( AccBindPRefiningT =:= undefined
                              andalso BindPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_MATERIAL) of
                           true ->
                               BindPRefiningT;
                           false ->
                               AccBindPRefiningT
                       end
               end,undefined,FiringList) of
            undefined ->
                erlang:throw({error,?_LANG_EQUIP_BIND_GOODS_ERROR,0});
            BindPRefiningTT ->
                case mod_bag:check_inbag(RoleId,BindPRefiningTT#p_refining.goods_id) of
                    {ok,BindGoodsT} ->
                        BindGoodsT;
                    _  ->
                        erlang:throw({error,?_LANG_EQUIP_BIND_GOODS_ERROR,0})
                end
        end,
    [BindEquipList] = common_config_dyn:find(equip_bind,equip_bind_equip),
    _BindEquipRecord = 
        case [BindEquipRecordT || 
                 BindEquipRecordT <- BindEquipList, 
                 BindEquipRecordT#r_equip_bind_equip.equip_code =:= EquipBaseInfo#p_equip_base_info.slot_num,
                 BindEquipRecordT#r_equip_bind_equip.protype =:= EquipBaseInfo#p_equip_base_info.protype ] of
            [BindEquipRecordTT] ->
                BindEquipRecordTT;
            _ ->
                erlang:throw({error,?_LANG_EQUIP_BIND_EQUIP_CODE_ERROR,0})
        end,
    [BindItemList] = common_config_dyn:find(equip_bind,equip_bind_item),
    BindItemRecord = 
        case [BindItemRecordT ||
                 BindItemRecordT <- BindItemList, 
                 BindItemRecordT#r_equip_bind_item.item_id =:= BindGoods#p_goods.typeid] of
            [BindItmeRecordTT] ->
                BindItmeRecordTT;
            _ ->
                erlang:throw({error,?_LANG_EQUIP_BIND_GOODS_ID_ERROR,0})
        end,
    if BindItemRecord#r_equip_bind_item.type =/= 1->
            erlang:throw({error,?_LANG_EQUIP_BIND_GOODS_ID_ERROR,0});
       BindGoods#p_goods.current_num < BindItemRecord#r_equip_bind_item.item_num ->
            erlang:throw({error,?_LANG_EQUIP_BIND_GOODS_NUM_ERROR,0});
       true ->
            next
    end,
    %% 第一次绑定
    case SubOpType =:= ?EQUIP_BIND_TYPE_FIRST of
        true ->
            case EquipGoods#p_goods.bind =:= false of
                true ->
                    next;
                _ ->
                    erlang:throw({error,?_LANG_EQUIP_BIND_FIRST_EQUIP_BIND,0})
            end,
            ok;
        _ ->
            next
    end,
    %% 重新绑定
    case  SubOpType =:= ?EQUIP_BIND_TYPE_REBIND of
        true ->
            case EquipGoods#p_goods.bind =:= true of
                true ->
                    next;
                _ ->
                    erlang:throw({error,?_LANG_EQUIP_BIND_REBIND_EQUIP_BIND,0})
            end,
            ok;
        _ ->
            next
    end,
	AddPropFee = mod_refining:get_refining_fee(equip_bind_fee, EquipGoods),
    {ok,EquipGoods,BindGoods,BindItemRecord,AddPropFee}.
do_refining_firing_addprop3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                            EquipGoods,BindGoods,BindItemRecord,AddPropFee) ->
    case common_transaction:transaction(
           fun() ->
                   do_t_refining_firing_addprop(RoleId,EquipGoods,BindGoods,BindItemRecord,AddPropFee)
           end) of
        {atomic,{ok,EquipGoods2,DelList,UpdateList}} ->
            do_refining_firing_addprop4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                        EquipGoods2,BindGoods,BindItemRecord,AddPropFee,DelList,UpdateList);
        {aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},?_LANG_REFINING_NOT_BAG_POS_ERROR,0);
                {Reason, ReasonCode} ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
                _ ->
                    Reason2 = ?_LANG_EQUIP_BIND_ERROR,
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2,0)
            end
    end.
do_refining_firing_addprop4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                            EquipGoods,BindGoods,BindItemRecord,_AddPropFee,DelList,UpdateList) ->
    SendSelf = #m_refining_firing_toc{
      succ = true,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list,
      update_list = [EquipGoods|UpdateList],
      del_list = DelList,
      new_list = []},
    %% 道具变化通知
    if UpdateList =/= [] ->
            catch common_misc:update_goods_notify({line, Line, RoleId},[EquipGoods | UpdateList]);
       true ->
            catch common_misc:update_goods_notify({line, Line, RoleId},[EquipGoods])
    end,
    if DelList =/= [] ->
            catch common_misc:del_goods_notify({line, Line, RoleId},DelList);
       true ->
            next
    end,
    %% 钱币变化通知
    catch mod_refining:do_refining_deduct_fee_notify(RoleId,{line, Line, RoleId}),
    %% 道具消费日志
    catch common_item_logger:log(RoleId,BindGoods,BindItemRecord#r_equip_bind_item.item_num,
                                 ?LOG_ITEM_TYPE_ZHONG_XIN_BANG_DING_SHI_QU),
    ?DEBUG("~ts,SendSelf=~w",["天工炉模块返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    ok.
do_t_refining_firing_addprop(RoleId,EquipGoods,BindGoods,BindItemRecord,AddPropFee) ->
    %% 扣费
    EquipConsume = #r_equip_consume{
      type = bind,consume_type = ?CONSUME_TYPE_SILVER_EQUIP_BIND,consume_desc = ""},
    case catch mod_refining:do_refining_deduct_fee(RoleId,AddPropFee,EquipConsume) of
        {error,AddPropFeeError} ->
            common_transaction:abort({AddPropFeeError,0});
        _ ->
            next
    end,
    %% 扣绑定材料
    {DelList,UpdateList} = 
        case catch mod_equip_build:do_transaction_dedcut_goods(RoleId,[BindGoods],BindItemRecord#r_equip_bind_item.item_num) of
            {error,GoodsError} ->
                common_transaction:abort({GoodsError,0});
            {ok,DelListT,UpdateListT} ->
                DelListT2  = 
                    lists:foldl(
                      fun(DelGoods,AccDelListT2) -> 
                              case lists:keyfind(DelGoods#p_goods.id,#p_goods.id,UpdateListT) of
                                  false ->
                                      [DelGoods | AccDelListT2];
                                  _ ->
                                      AccDelListT2
                              end
                      end,[],DelListT),
                {DelListT2,UpdateListT}
        end,
    %% 绑定属性
    EquipGoods2 = 
        case mod_refining_bind:do_equip_bind_for_equip_bind(EquipGoods) of
            {error,_BindErrorCode} ->
                EquipGoods#p_goods{bind=true};
            {ok,EquipGoods2T} ->
                EquipGoods2T
        end,
    %% 计算装备精炼系数
    EquipGoods3 = 
        case common_misc:do_calculate_equip_refining_index(EquipGoods2) of
            {error,_ErrorIndexCode} ->
                EquipGoods2;
            {ok, EquipGoods3T} ->
                EquipGoods3T
        end,
    mod_bag:update_goods(RoleId,EquipGoods3),
    {ok,EquipGoods3,DelList,UpdateList}.

%% 精炼
do_refining_firing_upprop({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_refining_firing_upprop2(RoleId,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
        {IsNeedAutoBuy,EquipGoods,BindGoodsList,BindItemRecord,MaxPossibleLevel,UpPropFee} ->
            do_refining_firing_upprop3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                       IsNeedAutoBuy,EquipGoods,BindGoodsList,BindItemRecord,MaxPossibleLevel,UpPropFee)
    end.

do_refining_firing_upprop2(RoleId,DataRecord) ->
	#m_refining_firing_tos{auto_buy_firing_stuff=IsAutoBuy, sub_op_type = SubOpType} = DataRecord,
	case SubOpType =:= ?EQUIP_BIND_TYPE_UPGRADE of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_EQUIP_BIND_TYPE_ERROR,0})
    end,
	
	if IsAutoBuy =:= false->
		   check_refining_firing_upprop_normal(RoleId, DataRecord);
	   true ->
		   check_refining_firing_upprop_with_autobuy(RoleId, DataRecord)
	end.

check_refining_firing_upprop_normal(RoleId,DataRecord) ->
    #m_refining_firing_tos{firing_list = FiringList} = DataRecord,
    %% 材料是否足够合法
    case (erlang:length(FiringList) >= 2) of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_EQUIP_BIND_GOODS_ERROR,0})
    end,
	
	EquipGoods = check_upprop_equip(RoleId, FiringList),
    
	%% 必须一级一级的提升，当前装备的最低
	MinBindAttrLevel = get_upprop_min_bind_attr_level(EquipGoods#p_goods.equip_bind_attr),
	
	BindItemRecord = 
		case get_upprop_stuff_config(MinBindAttrLevel) of
			{error, equip_bind_goods_id_error} ->
				erlang:throw({error,?_LANG_EQUIP_BIND_GOODS_ID_ERROR,0});
			Config ->
				Config
		end,
    
    {BindGoodsList,BindGoodsNeedNumber} = get_upprop_stuff_goods(RoleId, BindItemRecord#r_equip_bind_item.item_id, FiringList),
    %% 检查是否有足够精炼石    
    case BindGoodsList =:= []
        orelse (erlang:length(BindGoodsList) =/= erlang:length(FiringList) - 1)
        orelse BindItemRecord#r_equip_bind_item.item_num =/= BindGoodsNeedNumber of
        true ->
			[BindGoodsBaseInfo] = common_config_dyn:find_item(BindItemRecord#r_equip_bind_item.item_id),
            erlang:throw({error,
                          common_tool:get_format_lang_resources(?_LANG_EQUIP_BIND_GOODS_VALID_ERROR,
                                                                [BindItemRecord#r_equip_bind_item.item_num,
                                                                 BindGoodsBaseInfo#p_item_base_info.itemname]),
                          0});
        _ ->
            next
    end,
	
    %% 提升属性材料最高可能达到的级别
    MaxPossibleLevel = get_upprop_max_possible_level(BindItemRecord),
    case MinBindAttrLevel >= MaxPossibleLevel of
        true ->
            erlang:throw({error,?_LANG_EQUIP_BIND_UPGRADE_ITEM_LEVEL,0});
        _ ->
            next
    end,
    
    UpPropFee = mod_refining:get_refining_fee(equip_bind_upgrade_fee,EquipGoods, BindItemRecord#r_equip_bind_item.item_level),
    {?NOT_NEED_AUTO_BUY,EquipGoods,BindGoodsList,BindItemRecord,MaxPossibleLevel,UpPropFee}.

check_refining_firing_upprop_with_autobuy(RoleId, DataRecord) ->
	#m_refining_firing_tos{firing_list = FiringList} = DataRecord,
	case is_equip_in_firing_list(FiringList) of
		true ->
			next;
		false ->
			erlang:throw({error, ?_LANG_EQUIP_UPPROP_NO_EQUIP, 0})
	end,
	
	EquipGoods = check_upprop_equip(RoleId, FiringList),
	
	%% 必须一级一级的提升，当前装备的最低
	MinBindAttrLevel = get_upprop_min_bind_attr_level(EquipGoods#p_goods.equip_bind_attr),
	BindItemRecord = 
		case get_upprop_stuff_config(MinBindAttrLevel) of
			{error, equip_bind_goods_id_error} ->
				erlang:throw({error,?_LANG_EQUIP_BIND_GOODS_ID_ERROR,0});
			Config ->
				Config
		end,
	
	{BindGoodsList,BindGoodsNumber} = get_upprop_stuff_goods(RoleId, BindItemRecord#r_equip_bind_item.item_id, FiringList),
	
	IsNeedAutoBuy = 
		case (BindGoodsNumber < BindItemRecord#r_equip_bind_item.item_num) of
			true ->
				?NEED_AUTO_BUY;
			false ->
				case BindGoodsList =:= []
						 orelse (erlang:length(BindGoodsList) =/= erlang:length(FiringList) - 1)
						 orelse BindItemRecord#r_equip_bind_item.item_num =/= BindGoodsNumber of
					true ->
						erlang:throw({error, ?_LANG_SYSTEM_ERROR, 0});
					_->
						?NOT_NEED_AUTO_BUY
				end
		end,
	
	%% 提升属性材料最高可能达到的级别
    [BindAddLevelList] = common_config_dyn:find(equip_bind,equip_bind_add_level),
    MaxPossibleLevel = 
        lists:max([R3#r_equip_bind_add_level.attr_level || 
                      R3 <- BindAddLevelList, 
                      R3#r_equip_bind_add_level.material_level =:= BindItemRecord#r_equip_bind_item.item_level]),
    case MinBindAttrLevel >= MaxPossibleLevel of
        true ->
            erlang:throw({error,?_LANG_EQUIP_BIND_UPGRADE_ITEM_LEVEL,0});
        _ ->
            next
    end,
    
    UpPropFee = mod_refining:get_refining_fee(equip_bind_upgrade_fee,EquipGoods, BindItemRecord#r_equip_bind_item.item_level),
    {IsNeedAutoBuy,EquipGoods,BindGoodsList,BindItemRecord,MaxPossibleLevel,UpPropFee}.

%% 检查精炼装备
check_upprop_equip(RoleId, FiringList) ->
%% 检查是否是要提升绑定属性的装备
    EquipGoods = 
        case lists:foldl(
               fun(EquipPRefiningT,AccEquipPRefiningT) ->
                       case ( AccEquipPRefiningT =:= undefined
                              andalso EquipPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_TARGET
                              andalso EquipPRefiningT#p_refining.goods_type =:= ?TYPE_EQUIP) of
                           true ->
                               EquipPRefiningT;
                           false ->
                               AccEquipPRefiningT
                       end 
               end,undefined,FiringList) of
            undefined ->
                erlang:throw({error,?_LANG_EQUIP_BIND_EQUIP_ID_ERROR,0});
            EquipPRefiningTT ->
                case mod_bag:check_inbag(RoleId,EquipPRefiningTT#p_refining.goods_id) of
                    {ok,EquipGoodsT} ->
                        EquipGoodsT;
                    _  ->
                        erlang:throw({error,?_LANG_EQUIP_BIND_EQUIP_ID_ERROR,0})
                end
        end,
    [EquipBaseInfo] = common_config_dyn:find_equip(EquipGoods#p_goods.typeid),
    if EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MOUNT ->
            erlang:throw({error,?_LANG_EQUIP_BIND_UPGRADE_MOUNT_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_FASHION ->
            erlang:throw({error,?_LANG_EQUIP_BIND_UPGRADE_FASHION_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_ADORN ->
            erlang:throw({error,?_LANG_EQUIP_BIND_UPGRADE_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_JINGJIE ->
            erlang:throw({error,?_LANG_EQUIP_BIND_UPGRADE_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_SHENQI ->
            erlang:throw({error,?_LANG_EQUIP_BIND_UPGRADE_ADORN_ERROR,0});
       EquipBaseInfo#p_equip_base_info.slot_num =:= ?PUT_MARRY ->
            erlang:throw({error,?_LANG_EQUIP_BIND_UPGRADE_ADORN_ERROR,0});
       true ->
            next
    end,
    [SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
    case lists:member(EquipGoods#p_goods.typeid,SpecialEquipList) of
        true ->
            erlang:throw({error,?_LANG_EQUIP_BIND_UPGRADE_ADORN_ERROR,0});
        _ ->
            next
    end,
    case EquipGoods#p_goods.bind =:= true of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_EQUIP_BIND_UPGRADE_EQUIP_BIND,0})
    end,
    case EquipGoods#p_goods.equip_bind_attr =/= undefined
        andalso EquipGoods#p_goods.equip_bind_attr =/= [] of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_EQUIP_BIND_UPGRADE_EQUIP_BIND_ATTR,0})
    end,
    %% 检查装备绑定属性是不是满级
    [EquipBindAttrList] =  common_config_dyn:find(equip_bind,equip_bind_attr),
    CheckEquipBindAttrList = 
        lists:map(
          fun(AttrRecord) ->
                  MaxBindAttrLevel = lists:max(
                                       [R2#r_equip_bind_attr.level || 
                                           R2 <- EquipBindAttrList, 
                                           R2#r_equip_bind_attr.attr_code =:= AttrRecord#p_equip_bind_attr.attr_code]),
                  case MaxBindAttrLevel =:= AttrRecord#p_equip_bind_attr.attr_level of
                      true ->
                          1;
                      _ ->
                          2
                  end
          end,EquipGoods#p_goods.equip_bind_attr),
    case lists:member(2,CheckEquipBindAttrList) of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_EQUIP_BIND_UPGRADE_FULL,0})
    end,
    [BindEquipList] = common_config_dyn:find(equip_bind,equip_bind_equip),
    _BindEquipRecord = 
        case [BindEquipRecordT || 
                 BindEquipRecordT <- BindEquipList, 
                 BindEquipRecordT#r_equip_bind_equip.equip_code =:= EquipBaseInfo#p_equip_base_info.slot_num,
                 BindEquipRecordT#r_equip_bind_equip.protype =:= EquipBaseInfo#p_equip_base_info.protype ] of
            [BindEquipRecordTT] ->
                BindEquipRecordTT;
            _ ->
                erlang:throw({error,?_LANG_EQUIP_BIND_EQUIP_CODE_ERROR,0})
        end,
	
	case check_equip_upprop_has_duplicate(EquipGoods#p_goods.equip_bind_attr) of
		true ->
			erlang:throw({error,?_LANG_EQUIP_BIND_EQUIP_DUPLICATE_ERROR,0});
		false ->
			next
	end,
	EquipGoods.

check_equip_upprop_has_duplicate(AttrList) ->
	AttrCodeList = lists:sort([Attr#p_equip_bind_attr.attr_code || Attr <- AttrList]),
	{Result, _} = lists:foldl(
			   fun(Code, {Status, Acc}) -> 
					   case Status of
						   true ->
							   {Status, Acc};
						   false ->
							   if Acc =:= Code ->
									  {true, Code};
								  true ->
									  {false, Code}
							   end
					   end
			   end, {false, -1}, AttrCodeList),
	Result.

get_upprop_min_bind_attr_level(CurrentEquipBindAttr) ->
	lists:min([MinBindAttrLevelT || #p_equip_bind_attr{attr_level = MinBindAttrLevelT} <- CurrentEquipBindAttr]).

get_upprop_max_possible_level(BindItemRecord) ->
	[BindAddLevelList] = common_config_dyn:find(equip_bind,equip_bind_add_level),
	lists:max([R3#r_equip_bind_add_level.attr_level || 
										 R3 <- BindAddLevelList, 
										 R3#r_equip_bind_add_level.material_level =:= BindItemRecord#r_equip_bind_item.item_level]).

%% 查找出当前精炼所需的材料配置
get_upprop_stuff_config(MinBindAttrLevel) ->
	[BindItemList] = common_config_dyn:find(equip_bind,equip_bind_item),
	%% 当前必须使用的提升材料配置记录
	BindItemRecord = 
		case [BindItemRecordT ||
			  BindItemRecordT <- BindItemList, 
			  BindItemRecordT#r_equip_bind_item.item_level =:= MinBindAttrLevel] of
			[BindItmeRecordTT] ->
				BindItmeRecordTT;
			_ ->
				erlang:throw({error, equip_bind_goods_id_error})
		end,
	case BindItemRecord#r_equip_bind_item.type =/= 2 of
        true ->
			erlang:throw({error, equip_bind_goods_id_error});
        _ ->
            next
    end,
	BindItemRecord.

%% 检查是否有精炼材料
get_upprop_stuff_goods(RoleId, UppropStuffTypeId, FiringList) ->
	lists:foldl(
	  fun(BindPRefiningT,{AccBindGoodsList,AccBindGoodsNeedNumber}) ->
			  case BindPRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_MATERIAL andalso 
				   BindPRefiningT#p_refining.goods_type =:= ?TYPE_ITEM andalso 
				   BindPRefiningT#p_refining.goods_type_id =:= UppropStuffTypeId of
				  true ->
					  case mod_bag:check_inbag(RoleId,BindPRefiningT#p_refining.goods_id) of
						  {ok,BindGoodsT} ->
							  {[BindGoodsT|AccBindGoodsList],
							   AccBindGoodsNeedNumber + BindPRefiningT#p_refining.goods_number};
						  _  ->
							  erlang:throw({error,?_LANG_EQUIP_BIND_GOODS_ERROR,0})
					  end;
				  _ ->
					  {AccBindGoodsList,AccBindGoodsNeedNumber}
			  end
	  end,{[],0},FiringList).

do_refining_firing_upprop3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                           IsNeedAutoBuy,EquipGoods,BindGoodsList,BindItemRecord,MaxPossibleLevel,UpPropFee) ->
    case common_transaction:transaction(
           fun() ->
                   do_t_refining_firing_upprop(IsNeedAutoBuy,RoleId,EquipGoods,BindGoodsList,BindItemRecord,MaxPossibleLevel,UpPropFee)
           end) of
        {atomic,{ok,NewEquipGoods,DelList,UpdateList,IsUpProp}} ->
            do_refining_firing_upprop4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                       IsNeedAutoBuy,NewEquipGoods,BindGoodsList,BindItemRecord,DelList,UpdateList,IsUpProp);
        {aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},?_LANG_REFINING_NOT_BAG_POS_ERROR,0);
                {error, Reason, ReasonCode} ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
                {Reason, ReasonCode} ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
                _ ->
                    Reason2 = ?_LANG_EQUIP_BIND_ERROR,
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2,0)
            end
    end.
do_refining_firing_upprop4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                           IsNeedAutoBuy,EquipGoods,BindGoodsList,_BindItemRecord,DelList,UpdateList,IsUpProp) ->
    case IsUpProp =:= 1 of
        true ->
            Reason = ?_LANG_EQUIP_BIND_UPGRADE_SUCC,ReasonCode = 0;
        _ ->
            Reason =?_LANG_EQUIP_BIND_UPGRADE_ERROR,ReasonCode = 1
    end,
    SendSelf = #m_refining_firing_toc{
      succ = true,
      reason = Reason,reason_code = ReasonCode,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list,
      update_list = [EquipGoods|UpdateList],
      del_list = DelList,
      new_list = []},
    %% 道具变化通知
    catch common_misc:update_goods_notify({line, Line, RoleId},[EquipGoods | UpdateList]),
	catch common_misc:del_goods_notify({line, Line, RoleId},DelList),
    %% 钱币变化通知
    catch mod_refining:do_refining_deduct_fee_notify(RoleId,{line, Line, RoleId}),
	case IsNeedAutoBuy of 
		?NEED_AUTO_BUY ->
			catch mod_refining:do_refining_deduct_gold_notify(RoleId,{line, Line, RoleId});
		_ ->
			ignore
	end,
    %% 道具消费日志
	if BindGoodsList =/= [] ->
		   [BindGoods | _TBindGoods] = BindGoodsList,
		   catch common_item_logger:log(RoleId,BindGoods,erlang:length(BindGoodsList),?LOG_ITEM_TYPE_ZHONG_XIN_BANG_DING_SHI_QU);
	   true ->
		   ignore
	end,
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    ok.
do_t_refining_firing_upprop(IsNeedAutoBuy,RoleId,EquipGoods,BindGoodsList,BindItemRecord,MaxPossibleLevel,UpPropFee) ->
	{DelList,UpdateList} = 
		case IsNeedAutoBuy of
			?NOT_NEED_AUTO_BUY ->
				deduct_upprop_fee_and_stuff(RoleId, UpPropFee,BindGoodsList, BindItemRecord);
			?NEED_AUTO_BUY ->
				deduct_upprop_auto_buy_stuff(RoleId, UpPropFee, BindGoodsList, BindItemRecord)
		end,
    
	do_t_refining_firing_upprop2(RoleId,EquipGoods,BindItemRecord,MaxPossibleLevel,DelList,UpdateList).

deduct_upprop_fee_and_stuff(RoleId, UpPropFee,BindGoodsList,BindItemRecord) ->
	%% 扣费
    EquipConsume = #r_equip_consume{type = bind,consume_type = ?CONSUME_TYPE_SILVER_EQUIP_BIND,consume_desc = ""},
    case catch mod_refining:do_refining_deduct_fee(RoleId,UpPropFee,EquipConsume) of
        {error,UpPropFeeError} ->
            common_transaction:abort({UpPropFeeError,0});
        _ ->
            next
    end,
	{DelList,UpdateList} = deduct_refining_stuff(RoleId,BindGoodsList,BindItemRecord#r_equip_bind_item.item_num),
	{DelList,UpdateList}.

deduct_upprop_auto_buy_stuff(RoleId, UpPropFee, BindGoodsList, BindItemRecord) ->
	AutoBuyNum = BindItemRecord#r_equip_bind_item.item_num - erlang:length(BindGoodsList),
	%% 扣除自动购买精炼石的费用
	deduct_auto_buy_stuff_fee(upprop, RoleId, BindItemRecord#r_equip_bind_item.item_id, AutoBuyNum, UpPropFee),
	%% 扣费
    EquipConsume = #r_equip_consume{type = bind,consume_type = ?CONSUME_TYPE_SILVER_EQUIP_BIND,consume_desc = ""},
    case catch mod_refining:do_refining_deduct_fee(RoleId,UpPropFee,EquipConsume) of
        {error,UpPropFeeError} ->
            common_transaction:abort({UpPropFeeError,0});
        _ ->
            next
    end,
	
    %% 扣材料
	if AutoBuyNum > 0 ->
		   {DelList,UpdateList} = deduct_refining_stuff(RoleId,BindGoodsList,erlang:length(BindGoodsList));
	   true ->
		   DelList = [],
		   UpdateList = []
	end,
	{DelList, UpdateList}.

do_t_refining_firing_upprop2(RoleId,EquipGoods,BindItemRecord,MaxPossibleLevel,DelList,UpdateList) ->
    NewEquipGoods = 
        case calc_new_upprop_result(EquipGoods#p_goods.equip_bind_attr, BindItemRecord, MaxPossibleLevel) of
            {succ, NewEquipBindAttrList} ->%% 属性提升
				IsUpProp = 1,
                EquipGoods2 = 
                    case mod_refining_bind:do_equip_bind_for_equip_bind_up_attr(EquipGoods,NewEquipBindAttrList) of
                        {error,_BindErrorCode} ->
                            EquipGoods;
                        {ok,EquipGoods2T} ->
                            EquipGoods2T
                    end,
                %% 计算装备精炼系数
                case common_misc:do_calculate_equip_refining_index(EquipGoods2) of
                    {error,_ErrorIndexCode} ->
                        EquipGoods2;
                    {ok, EquipGoods3} ->
                        EquipGoods3
                end;
            _ -> %% 属性提升失败没有变化
                IsUpProp = 2,
                EquipGoods
        end,
    mod_bag:update_goods(RoleId,NewEquipGoods),
    {ok,NewEquipGoods,DelList,UpdateList,IsUpProp}.

%% 提升概率处理
%% 将附加的绑定的属性级别为最高级的去掉，只随机没有达到满级的附加属性
calc_new_upprop_result(OriginEquipBindAttrList, BindItemRecord, MaxPossibleLevel) ->
	EquipBindAttrList = 
		lists:filter(
		  fun(R1) -> 
				  case R1#p_equip_bind_attr.attr_level >= MaxPossibleLevel of
					  true ->
						  false;
					  _ ->
						  true
				  end
		  end,OriginEquipBindAttrList),
	Len = erlang:length(EquipBindAttrList),
	RandomNumber = random:uniform(Len),
	AttrRecord = lists:nth(RandomNumber,EquipBindAttrList),
	
	[AddLevelList] = common_config_dyn:find(equip_bind,equip_bind_add_level),
	AddLevelList2 = [R2 || 
					 R2 <- AddLevelList, 
					 R2#r_equip_bind_add_level.material_level =:= BindItemRecord#r_equip_bind_item.item_level],
	AddLevelList3 = lists:sort(
					  fun(RA,RB) -> 
							  RA#r_equip_bind_add_level.attr_level =< RB#r_equip_bind_add_level.attr_level
					  end,AddLevelList2),
	ProbabilityList = [R3#r_equip_bind_add_level.probability || R3 <- AddLevelList3],
	ProbabilityIndex = mod_refining:get_random_number(ProbabilityList,0,?DEFAULT_EQUIP_BIND_UPGRADE_ATTR_LEVEL),
	NewLevelRecord = lists:nth(ProbabilityIndex,AddLevelList3),
	NewLevel = NewLevelRecord#r_equip_bind_add_level.attr_level,
	if NewLevel > AttrRecord#p_equip_bind_attr.attr_level ->
		   [ConfigEquipBindAttrList] = common_config_dyn:find(equip_bind,equip_bind_attr),
		   [ConfigAttrRecord] = [ConfigAttrRecordT || 
								 ConfigAttrRecordT <- ConfigEquipBindAttrList,
								 ConfigAttrRecordT#r_equip_bind_attr.attr_code =:= AttrRecord#p_equip_bind_attr.attr_code,
								 ConfigAttrRecordT#r_equip_bind_attr.level =:= NewLevel],
		   
		   NewEquipBindAttrListT = lists:keydelete(AttrRecord#p_equip_bind_attr.attr_code,
												   #p_equip_bind_attr.attr_code,
												   OriginEquipBindAttrList),
		   NewEquipBindAttrList = [AttrRecord#p_equip_bind_attr{
																attr_level = NewLevel,
																type =  ConfigAttrRecord#r_equip_bind_attr.add_type,
																value = ConfigAttrRecord#r_equip_bind_attr.value}|NewEquipBindAttrListT],
		   {succ, NewEquipBindAttrList};
	   true ->
		   fail
	end.

%% 炼制
do_refining_firing_forging({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_refining_firing_forging2(RoleId,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
        {ok,GoodsList,ForgingGoodsList,FFRecord} ->
            do_refining_firing_forging3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                        GoodsList,ForgingGoodsList,FFRecord)
    end.
do_refining_firing_forging2(RoleId,DataRecord) ->
    #m_refining_firing_tos{firing_list = FiringList} = DataRecord,
    [IsOpenForging] = common_config_dyn:find(etc,open_refining_forging),
    case IsOpenForging of
        true ->
            next;
        false ->
            erlang:throw({error,?_LANG_REINFORCE_FORGING_NOT_OPEN,0})
    end,
    MapRoleInfo = 
        case mod_map_actor:get_actor_mapinfo(RoleId,role) of
            undefined ->
                erlang:throw({error,?_LANG_REINFORCE_FORGING_ERROR,0});
            MapRoleInfoT ->
                MapRoleInfoT
        end,
    %% 炼制的所有物品
    {GoodsList,GoodsSunNumber,PRefiningNumber} = 
        case lists:foldl(
               fun(PRefiningT,{AccPRefiningT,AccPRefiningNumber}) ->
                       case PRefiningT#p_refining.firing_type =:= ?FIRING_TYPE_MATERIAL of
                           true ->
                               {[PRefiningT|AccPRefiningT],AccPRefiningNumber + PRefiningT#p_refining.goods_number};
                           false ->
                               {AccPRefiningT,AccPRefiningNumber}
                       end 
               end,{[],0},FiringList) of
            {[],_AccPRefiningNumber} ->
                erlang:throw({error,?_LANG_REINFORCE_FORGING_EMPTY,0});
            {PRefiningList,PRefiningNumberT} ->
                case lists:foldl(
                       fun(PRefiningTT,{AccGoodsList,AccGoodsSunNumber}) ->
                               case mod_bag:check_inbag(RoleId,PRefiningTT#p_refining.goods_id) of
                                   {ok,GoodsT} ->
                                       {[GoodsT|AccGoodsList],AccGoodsSunNumber + GoodsT#p_goods.current_num};
                                   _  ->
                                       {AccGoodsList,AccGoodsSunNumber}
                               end
                       end,{[],0},PRefiningList) of
                    {[],_AccGoodsSunNumber} ->
                        erlang:throw({error,?_LANG_REINFORCE_FORGING_EMPTY,0});
                    {GoodsListT,GoodsSunNumberT} ->
                        {GoodsListT,GoodsSunNumberT,PRefiningNumberT}
                end
        end,
    %% 特殊装备不可以当材料
    [SpecialEquipList] = common_config_dyn:find(refining,special_equip_list),
    lists:foreach(
      fun(SpecialColorGoods) ->
              case lists:member(SpecialColorGoods#p_goods.typeid,SpecialEquipList) of
                  true ->
                      erlang:throw({error,common_tool:get_format_lang_resources(?_LANG_REINFORCE_FORGING_ADORN_ERROR,[SpecialColorGoods#p_goods.name]),0});
                  _ ->
                      next
              end
      end,GoodsList),
    case GoodsSunNumber >= PRefiningNumber andalso GoodsList =/= [] of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_REINFORCE_FORGING_ERROR,0})
    end,
    ForgingGoodsList = 
        case GoodsSunNumber =:= PRefiningNumber of
            true ->
                GoodsList;
            _ ->
                lists:foldl(
                  fun(ForgingGoods,AccForgingGoodsList) ->
                          #p_refining{goods_number = ForgingGoodsNumber} = 
                              lists:keyfind(ForgingGoods#p_goods.id,#p_refining.goods_id,FiringList),
                          [ForgingGoods#p_goods{current_num = ForgingGoodsNumber}|AccForgingGoodsList]
                  end,[],GoodsList)
        end,
    FFRecord = 
        case mod_refining_forging:get_refining_forging_by_goods(MapRoleInfo,ForgingGoodsList) of
            {ok,FFRecordT} ->
                FFRecordT;
            {error,Reason} ->
                ?DEBUG("~ts,Reason=~w",["此物品无法获取合法的炼制方案",Reason]),
                erlang:throw({error,?_LANG_REINFORCE_FORGING_ERROR,0})
        end,
    {ok,GoodsList,ForgingGoodsList,FFRecord}.

do_refining_firing_forging3({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                            GoodsList,ForgingGoodsList,FFRecord) ->
    case common_transaction:transaction(
           fun() ->
                   do_t_refining_firing_forging(RoleId,GoodsList,ForgingGoodsList,FFRecord)
           end) of
        {atomic,{ok,NewGoodsList,FFProduct,DelList,UpdateList}} ->
            do_refining_firing_forging4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                                        GoodsList,ForgingGoodsList,FFRecord,NewGoodsList,FFProduct,
                                        DelList,UpdateList);
        {aborted, Error} ->
            case Error of
                {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},?_LANG_REFINING_NOT_BAG_POS_ERROR,0);
                {Reason, ReasonCode} ->
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
                _ ->
                    Reason2 = ?_LANG_REINFORCE_FORGING_ERROR,
                    do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2,0)
            end
    end.
do_refining_firing_forging4({Unique, Module, Method, DataRecord, RoleId, PId, Line},
                            GoodsList,ForgingGoodsList,_FFRecord,NewGoodsList,FFProduct,
                            DelList,UpdateList) ->
    case NewGoodsList =:= [] andalso FFProduct =:= undefined of
        true -> %% 炮制操作成功，但没有生成物品
            Reason = ?_LANG_REINFORCE_FORGING_FAIL,
            ReasonCode = 1,
            NewList = [];
        _ ->
            Reason ="",
            ReasonCode = 0,
            [HNewGoods|_TTNewGoods] = NewGoodsList,
            NewList = [HNewGoods#p_goods{current_num = FFProduct#r_forging_formula_item.item_num}]
            
    end,
    SendSelf = #m_refining_firing_toc{
      succ = true,
      reason = Reason,reason_code = ReasonCode,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list,
      update_list = UpdateList,
      del_list = DelList,
      new_list = NewList},
    %% 道具变化通知
    catch common_misc:update_goods_notify({line, Line, RoleId},lists:append([NewGoodsList,UpdateList])),
    if DelList =/= [] ->
            catch common_misc:del_goods_notify({line, Line, RoleId},DelList);
       true->
            next
    end,
    %% 道具消费日志
    lists:foreach(
      fun(DelGoods) ->
              catch common_item_logger:log(RoleId,DelGoods,?LOG_ITEM_TYPE_LIAN_ZHI_SHI_QU)
      end,ForgingGoodsList),
    if NewGoodsList =/= [] ->
            [NewGoods|_TNewGoods] = NewGoodsList,
            catch common_item_logger:log(RoleId,NewGoods,FFProduct#r_forging_formula_item.item_num,?LOG_ITEM_TYPE_LIAN_ZHI_HUO_DE);
       true ->
            next
    end,
    %% 炼制消息广播
    catch mod_refining_forging:do_refining_forging_notify(RoleId,FFProduct,GoodsList,NewList),
    ?DEBUG("~ts,SendSelf=~w",["天工炉模块返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    ok.
do_t_refining_firing_forging(RoleId,GoodsList,ForgingGoodsList,FFRecord) ->
    %% mod_bag:delete_goods(RoleId,[DelGoodsId || #p_goods{id = DelGoodsId} <- GoodsList]),
    %% 扣绑定材料
    {DelList,UpdateList} = 
        lists:foldl(
          fun(DelGoods,{AccDelList,AccUpdateList}) ->
                  #p_goods{current_num = ForgingGoodsNumber} = 
                      lists:keyfind(DelGoods#p_goods.id,#p_goods.id,ForgingGoodsList),
                  case ForgingGoodsNumber =:= DelGoods#p_goods.current_num of
                      true ->
                          mod_bag:delete_goods(RoleId,[DelGoods#p_goods.id]),
                          {[DelGoods|AccDelList],AccUpdateList};
                      _ ->
                          case catch mod_equip_build:do_transaction_dedcut_goods(RoleId,[DelGoods],ForgingGoodsNumber) of
                              {error,DelGoodsError} ->
                                  common_transaction:abort({DelGoodsError,0});
                              {ok,DelListT,UpdateListT} ->
                                  DelListT2  = 
                                      lists:foldl(
                                        fun(DelGoodsT,AccDelListT2) -> 
                                                case lists:keyfind(DelGoodsT#p_goods.id,#p_goods.id,UpdateListT) of
                                                    false ->
                                                        [DelGoodsT | AccDelListT2];
                                                    _ ->
                                                        AccDelListT2
                                                end
                                        end,[],DelListT),
                                  {lists:append([DelListT2,AccDelList]),lists:append([UpdateListT,AccUpdateList])}
                          end

                  end
          end,{[],[]},GoodsList),
    FFProductList = FFRecord#r_forging_formula.products,
    if FFProductList =:= [] ->
            {ok,[],undefined};
       erlang:length(FFProductList) =:= 1 ->
            [FFProduct] = FFProductList,
            do_t_refining_firing_forging2(RoleId,GoodsList,FFRecord,FFProduct,DelList,UpdateList);
       true ->
            do_t_refining_firing_forging2(RoleId,GoodsList,FFRecord,FFProductList,DelList,UpdateList)
    end.
do_t_refining_firing_forging2(RoleId,GoodsList,FFRecord,FFProductList,DelList,UpdateList) 
  when erlang:is_list(FFProductList) ->
    %% 炼制方案炼制获得的物品配置有多个处理
    PDataList = [FFR#r_forging_formula_item.succ_probability || FFR <- FFProductList],
    [HFFProduct|_T] = FFProductList,
    ResultWeight = HFFProduct#r_forging_formula_item.result_weight,
    Index = mod_refining:get_random_number(PDataList,ResultWeight,-1),
    if Index > 0 andalso Index =< erlang:length(PDataList) ->
            FFProduct = lists:nth(Index,FFProductList),
            do_t_refining_firing_forging3(RoleId,GoodsList,FFRecord,FFProduct,DelList,UpdateList);
       true ->
            ?DEBUG("~ts",["炼制创建物品时，根据多个物品生成配置结果计算不需要创建物品，即炼制失败，扣除物品"]),
            {ok, [], undefined,DelList,UpdateList}
    end;
do_t_refining_firing_forging2(RoleId,GoodsList,FFRecord,FFProduct,DelList,UpdateList) 
  when erlang:is_record(FFProduct,r_forging_formula_item)->
    Type = FFProduct#r_forging_formula_item.type,
    if Type =:= ?REFINING_FORGING_MATERIAL_TYPE_ITEM ->
            ResultWeight = FFProduct#r_forging_formula_item.result_weight,
            SuccProbability = FFProduct#r_forging_formula_item.succ_probability,
            RandomNumber = random:uniform(ResultWeight),
            case RandomNumber =< SuccProbability of
                true ->
                    do_t_refining_firing_forging3(RoleId,GoodsList,FFRecord,FFProduct,DelList,UpdateList);
                _ ->
                    ?DEBUG("~ts",["炼制创建物品时，根据结果计算不需要创建物品，即炼制失败，扣除物品"]),
                    {ok, [],undefined,DelList,UpdateList}
            end;
       true ->
            ?DEBUG("~ts,RoleId=~w,FFProduct=~w",["炼制创建物品失败，物品配置方案中类型出错",RoleId,FFProduct]),
            common_transaction:abort({?_LANG_REINFORCE_FORGING_ERROR,0})
    end;
do_t_refining_firing_forging2(RoleId,_GoodsList,FFRecord,_FFProducts,_DelList,_UpdateList) ->
    ?DEBUG("~ts,RoleId=~w,FFRecord=~w",["炼制创建物品参数错误，炼制失败",RoleId,FFRecord]),
    common_transaction:abort({?_LANG_REINFORCE_FORGING_ERROR,0}).

%% 创建物品
do_t_refining_firing_forging3(RoleId,GoodsList,_FFRecord,FFProduct,DelList,UpdateList) ->
    TypeValue = FFProduct#r_forging_formula_item.type_value,
    ItemType = 
        case common_config_dyn:find_item(TypeValue) of
            [_ItemBaseInfo] ->
                ?TYPE_ITEM;
            _ ->
                case common_config_dyn:find_stone(TypeValue) of
                    [_StoneBaseInfo] ->
                        ?TYPE_STONE;
                    _ ->
                        case common_config_dyn:find_equip(TypeValue) of
                            [_EquipBaseInfo] ->
                                ?TYPE_EQUIP;
                            _ ->
                                common_transaction:abort({?_LANG_REINFORCE_FORGING_ERROR,0})
                        end
                end
        end,
    Bind = 
        if FFProduct#r_forging_formula_item.bind =:= 1 ->
                true;
           FFProduct#r_forging_formula_item.bind =:= 2 ->
                false;
           true ->
                lists:foldl(
                  fun(Goods,AccBind) ->
                          case AccBind of
                              true ->
                                  AccBind;
                              false ->
                                  Goods#p_goods.bind
                          end
                  end,false,GoodsList)
        end,
    CreateInfo = 
        if ItemType =:= ?TYPE_EQUIP ->
                Color = mod_refining:get_random_number(FFProduct#r_forging_formula_item.color,0,1),
                Quality = mod_refining:get_random_number(FFProduct#r_forging_formula_item.quality,0,1),
                #r_goods_create_info{
                           type = ItemType,
                           type_id = FFProduct#r_forging_formula_item.type_value,
                           num = FFProduct#r_forging_formula_item.item_num,
                           bind = Bind,
                           color = Color,
                           quality = Quality,
                           interface_type = refining_forging};
           true ->
                #r_goods_create_info{
             type = ItemType,
             type_id = FFProduct#r_forging_formula_item.type_value,
             num = FFProduct #r_forging_formula_item.item_num,
             bind = Bind}
        end,
    {ok, NewGoodsList} = mod_bag:create_goods(RoleId,CreateInfo),
    {ok, NewGoodsList, FFProduct, DelList, UpdateList}.

%% 取回天工炉物品接口
do_refining_firing_retake({Unique, Module, Method, DataRecord, RoleId, PId, Line}) ->
    case catch do_refining_firing_retake2(RoleId,DataRecord) of
        {error,Reason,ReasonCode} ->
            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
        {ok,GoodsList} ->
            do_refining_firing_retake3({Unique, Module, Method, DataRecord, RoleId, PId, Line},GoodsList)
    end.
do_refining_firing_retake2(RoleId,DataRecord) ->
    #m_refining_firing_tos{sub_op_type = SubOpType} = DataRecord,
    case SubOpType =:= ?FIRING_OP_TYPE_RETAKE_1 orelse SubOpType =:= ?FIRING_OP_TYPE_RETAKE_2 of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_RETAKE_ERROR,0})
    end,
    GoodsList = mod_refining_bag:get_goods_by_bag_id(RoleId,?REFINING_BAGID),
    case GoodsList =/= [] of
        true ->
            next;
        _ ->
            erlang:throw({error,?_LANG_RETAKE_NO_GOODS,0})
    end,
    {ok,GoodsList}.
do_refining_firing_retake3({Unique, Module, Method, DataRecord, RoleId, PId, Line},GoodsList) ->
    case DataRecord#m_refining_firing_tos.sub_op_type =:= ?FIRING_OP_TYPE_RETAKE_1 of
        true ->
            SendSelf = #m_refining_firing_toc{
              succ = true,
              op_type = DataRecord#m_refining_firing_tos.op_type,
              sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
              firing_list = DataRecord#m_refining_firing_tos.firing_list,
              new_list=GoodsList,del_list=[],update_list=[]},
            ?DEBUG("~ts,SendSelf=~w",["天工炉模块返回结果",SendSelf]),
            common_misc:unicast2(PId, Unique, Module, Method, SendSelf);
        _ ->
            case common_transaction:transaction(
                   fun() ->
                           do_t_refining_firing_retake(RoleId,GoodsList)
                   end) of
                {atomic,{ok,NewGoodsList}} ->
                    do_refining_firing_retake4({Unique, Module, Method, DataRecord, RoleId, PId, Line},GoodsList,NewGoodsList);
                {aborted, Error} ->
                    case Error of
                        {bag_error,{not_enough_pos,_BagID}} -> %% 背包够空间,将物品发到玩家的信箱中
                            NotBagPosMessage = common_tool:get_format_lang_resources(?_LANG_RETAKE_NOT_BAG_POS,[erlang:length(GoodsList)]),
                            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},NotBagPosMessage,1);
                        {Reason, ReasonCode} ->
                            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason,ReasonCode);
                        _ ->
                            Reason2 = ?_LANG_RETAKE_ERROR,
                            do_refining_firing_error({Unique, Module, Method, DataRecord, RoleId, PId, Line},Reason2,0)
                    end
            end
    end.
do_refining_firing_retake4({Unique, Module, Method, DataRecord, RoleId, PId, Line},GoodsList,NewGoodsList) ->
    SendSelf = #m_refining_firing_toc{
      succ = true,
      op_type = DataRecord#m_refining_firing_tos.op_type,
      sub_op_type = DataRecord#m_refining_firing_tos.sub_op_type,
      firing_list = DataRecord#m_refining_firing_tos.firing_list,
      new_list = NewGoodsList,
      del_list = [],
      update_list = []},
    %% 道具变化通知
    catch common_misc:update_goods_notify({line, Line, RoleId},NewGoodsList),
    catch common_misc:del_goods_notify({line, Line, RoleId},GoodsList),
    %% 道具消费日志
    lists:foreach(
      fun(DelGoods) ->
              catch common_item_logger:log(RoleId,DelGoods,?LOG_ITEM_TYPE_RETAKE_SHI_QU)
      end,GoodsList),
    lists:foreach(
      fun(NewGoods) ->
              catch common_item_logger:log(RoleId,NewGoods,?LOG_ITEM_TYPE_RETAKE_HUO_DE)
      end,NewGoodsList),
    ?DEBUG("~ts,SendSelf=~w",["天工炉模块返回结果",SendSelf]),
    common_misc:unicast2(PId, Unique, Module, Method, SendSelf),
    ok.

do_t_refining_firing_retake(RoleId,GoodsList) ->
    mod_bag:delete_goods(RoleId,[DelGoods#p_goods.id || DelGoods <- GoodsList]),
    NewGoodsListT = [NewGoods#p_goods{id = 0,bagposition = 0,bagid = 0}|| NewGoods <- GoodsList],
    {ok,NewGoodsList} = mod_bag:create_goods_by_p_goods(RoleId,NewGoodsListT),
    {ok,NewGoodsList}.

%%%===================================================================
%%% Common Function
%%%===================================================================
is_equip_in_firing_list(FiringList) ->
	lists:any(fun(Elem) -> 
					  Elem#p_refining.firing_type =:= ?FIRING_TYPE_TARGET
										  andalso Elem#p_refining.goods_type =:= ?TYPE_EQUIP
			  end, FiringList).

%% 扣除自动购买的Item 费用, 并返回是否使用了礼券或钱币来购买
deduct_auto_buy_stuff_fee(reinforce, RoleId, StuffTypeId, AutoBuyNum, RefiningFee) ->
	EquipConsumeGold = #r_equip_consume{type = reinforce,consume_type = ?CONSUME_TYPE_GOLD_AUTO_BUY_REINFORCE_STUFF,consume_desc = ""},
	EquipConsumeSilver = #r_equip_consume{type = reinforce,consume_type = ?CONSUME_TYPE_SILVER_AUTO_BUY_REINFORCE_STUFF,consume_desc = ""},
	deduct_auto_buy_stuff_fee2(RoleId, StuffTypeId, AutoBuyNum, RefiningFee, EquipConsumeGold, EquipConsumeSilver);

deduct_auto_buy_stuff_fee(upprop, RoleId, StuffTypeId, AutoBuyNum, RefiningFee) ->
	EquipConsumeGold = #r_equip_consume{type = upprop,consume_type = ?CONSUME_TYPE_GOLD_AUTO_BUY_UPPROP_STUFF,consume_desc = ""},
	EquipConsumeSilver = #r_equip_consume{type = upprop,consume_type = ?CONSUME_TYPE_SILVER_AUTO_BUY_UPPROP_STUFF,consume_desc = ""},
	deduct_auto_buy_stuff_fee2(RoleId, StuffTypeId, AutoBuyNum, RefiningFee, EquipConsumeGold, EquipConsumeSilver);

deduct_auto_buy_stuff_fee(punch, RoleId, StuffTypeId, AutoBuyNum, RefiningFee) ->
	EquipConsumeGold = #r_equip_consume{type = punch,consume_type = ?CONSUME_TYPE_GOLD_AUTO_BUY_PUNCH_STUFF,consume_desc = ""},
	EquipConsumeSilver = #r_equip_consume{type = punch,consume_type = ?CONSUME_TYPE_SILVER_AUTO_BUY_PUNCH_STUFF,consume_desc = ""},
	deduct_auto_buy_stuff_fee2(RoleId, StuffTypeId, AutoBuyNum, RefiningFee, EquipConsumeGold, EquipConsumeSilver).

deduct_auto_buy_stuff_fee2(RoleId, StuffTypeId, AutoBuyNum, RefiningFee, EquipConsumeGold, EquipConsumeSilver) ->
	BuyEquipWithBindMoney = 
		case get_stuff_price(StuffTypeId, AutoBuyNum) of
			{PriceBind, gold, AutoBuyGold} ->
				case catch mod_refining:do_refining_deduct_gold(RoleId, PriceBind, AutoBuyGold, EquipConsumeGold) of
					{error,AutoBuyGoldError} ->
						common_transaction:abort({AutoBuyGoldError,0});
					NeedBind ->
						NeedBind
				end;
			{_PriceBind, silver, AutoBuySilver} ->
				case mod_map_role:get_role_attr(RoleId) of
					{ok,RoleAttr} ->
						SilverBind = RoleAttr#p_role_attr.silver_bind,
						Silver = RoleAttr#p_role_attr.silver,
						if (SilverBind + Silver) < (RefiningFee + AutoBuySilver) ->
							   erlang:throw({?_LANG_REFINING_ENOUGH_MONEY, 0});
						   true ->
							   next
						end;
					{error,_Error} ->
						erlang:throw({?_LANG_REFINING_DEDUCT_FEE_ERROR, 0})
				end,
				
				case catch mod_refining:do_refining_deduct_fee(RoleId, AutoBuySilver, EquipConsumeSilver) of
					{error,AutoBuySilverError} ->
						common_transaction:abort({AutoBuySilverError,0});
					NeedBind ->
						NeedBind
				end
		end,
	BuyEquipWithBindMoney.

%% 扣除锻造材料
deduct_refining_stuff(RoleId, RefiningStuffGoodsList, DeductNum) ->
	{DelList,UpdateList} = 
		case catch mod_equip_build:do_transaction_dedcut_goods(RoleId,RefiningStuffGoodsList,DeductNum) of
			{error,GoodsError} ->
				common_transaction:abort({GoodsError,0});
			{ok,DelListT,UpdateListT} ->
				DelListT2  = 
					lists:foldl(
					  fun(DelGoods,AccDelListT2) -> 
							  case lists:keyfind(DelGoods#p_goods.id,#p_goods.id,UpdateListT) of
								  false ->
									  [DelGoods | AccDelListT2];
								  _ ->
									  AccDelListT2
							  end
					  end,[],DelListT),
				{DelListT2,UpdateListT}
		end,
	{DelList,UpdateList}.
