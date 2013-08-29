%%%-------------------------------------------------------------------
%%% @author bisonwu <wuzesen@gmail.com>
%%% @copyright (C) 2010, gmail.com
%%% @doc
%%%     人物培养的子模块
%%% @end
%%% Created : 2010-12-17
%%%-------------------------------------------------------------------
-module(mod_role_grow).


-include("mgeem.hrl").

%% API
-export([
         handle/1, update_role_base/3, recalc/2
         ]).


%% ====================================================================
%% Macro
%% ====================================================================
-define(MAX_GROW_SUPER_VAL,6707).        %%培养最高最高也不可能超过6707值

-define(GROW_OP_SAVE,1).
-define(GROW_OP_CANCEL,2).

-define(cur_role_grow_result,cur_role_grow_result).

%%错误码
-define(ERR_GROW_NO_CUR_RESULT,1001).
-define(ERR_GROW_SILVER_ANY_NOT_ENOUGH,1002).
-define(ERR_GROW_GOLD_ANY_NOT_ENOUGH,1003).
-define(ERR_GROW_SILVER_UNBIND_NOT_ENOUGH,1004).
-define(ERR_GROW_GOLD_UNBIND_NOT_ENOUGH,1005).
-define(ERR_GROW_ALL_PROPERTY_FULL,1006).
-define(ERR_GROW_MIN_LEVEL_LIMIT,1007).%%等级限制
-define(ERR_GROW_ROLE_NOT_VIP,1008).  %% VIP等级不够，不能培养这种类型

%%1:力量,2:智力,3:体质,4:筋骨,5:意志
-define(STR,1).
-define(INT,2).
-define(CON,3).
-define(DEX,4).
-define(MEN,5).

%%1 普通; 2 加强; 3 高级；4 超级；5至尊
-define(GROW1,1).
-define(GROW2,2).
-define(GROW3,3).
-define(GROW4,4).
% -define(GROW5,5).
-define(ALL_GROW,[1,2,3,4]).

-define(FULL,full).
%%%===================================================================
%%% API
%%%===================================================================

%% 人物培养
handle({_, ?ROLE2, ?ROLE2_GROW_REFRESH, _, _, _PID, _Line, _MapState}=Info) ->
    do_role2_grow_refresh(Info);
handle({_, ?ROLE2, ?ROLE2_GROW_SAVE, _, _, _PID, _Line, _MapState}=Info) ->
    do_role2_grow_save(Info);
handle({_, ?ROLE2, ?ROLE2_GROW_SHOW, _, _, _PID, _Line, _MapState}=Info) ->
    do_role2_grow_show(Info);

handle(Args) ->
    ?ERROR_MSG("~w, unknow args: ~w", [?MODULE,Args]),
    ok. 

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%% @interface 人物培养的刷新
do_role2_grow_refresh({Unique, Module, Method, DataIn, RoleID, PID, Line, MapState})->
	#m_role2_grow_refresh_tos{grow_type=GrowType}= DataIn,
	case catch check_role2_grow_refresh(RoleID,DataIn) of
		{ok,{MoneyType,Cost}}->
			TransFun = fun()-> t_role_grow_refresh(GrowType,RoleID,{MoneyType,Cost}) end,
			case common_transaction:t( TransFun ) of
				{atomic,{ok,Category,VipLevel,RoleLevel,SumGrowVal,RGrowResult,RoleAttr2} } ->
					%%                     {_MinPhyAtk,_MaxPhyAtk,_MinMgcAtk,_MaxMgcAtk,_PhyDfc,_MgcDfc} =
					%%                             get_role_new_grow_property(RoleID,RGrowResult),
					case MoneyType of
						silver_any->
							common_misc:send_role_silver_change(RoleID,RoleAttr2);
						gold_any->
							common_misc:send_role_gold_change(RoleID,RoleAttr2)
					end,
					case lists:member(GrowType, ?ALL_GROW -- [1]) of
						true->
							%% 特殊任务事件
							% hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_ROLE_GOLD_GROW);
							mgeer_role:send(RoleID, {apply, hook_mission_event, hook_special_event, [RoleID, ?MISSON_EVENT_ROLE_GOLD_GROW]});
						_ ->
							% hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_ROLE_SILVER_GROW)
							mgeer_role:send(RoleID, {apply, hook_mission_event, hook_special_event, [RoleID, ?MISSON_EVENT_ROLE_SILVER_GROW]})
					end,
					%% 完成成就
					case GrowType of
						?GROW2 ->
							mod_achievement2:achievement_update_event(RoleID, 11004, 1),
							mod_achievement2:achievement_update_event(RoleID, 12005, 1),
							mod_achievement2:achievement_update_event(RoleID, 21006, 1);
						?GROW3 ->
							mod_achievement2:achievement_update_event(RoleID, 13004, 1),
							mod_achievement2:achievement_update_event(RoleID, 22006, 1);
						?GROW4 ->
							mod_achievement2:achievement_update_event(RoleID, 14005, 1),
							mod_achievement2:achievement_update_event(RoleID, 23003, 1),
							mod_achievement2:achievement_update_event(RoleID, 24005, 1);
						_ -> ok
					end,
					R2 = get_refresh_toc(GrowType,Category,VipLevel,RoleLevel,SumGrowVal,RGrowResult),
					?UNICAST_TOC(R2),
					Save = #m_role2_grow_save_tos{op_type = ?GROW_OP_SAVE},
					do_role2_grow_save({Unique, Module, ?ROLE2_GROW_SAVE, Save, RoleID, PID, Line, MapState});
				{aborted, AbortErr} ->
					{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
					case lists:member(GrowType, ?ALL_GROW -- [1]) of
						true->
							if
								ErrCode =:= ?ERR_GROW_ALL_PROPERTY_FULL->
									mgeer_role:send(RoleID, {apply, hook_mission_event, hook_special_event, [RoleID, ?MISSON_EVENT_ROLE_GOLD_GROW]});
									% hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_ROLE_GOLD_GROW);
								true-> 
									mgeer_role:send(RoleID, {apply, hook_mission_event, hook_special_event, [RoleID, ?MISSON_EVENT_ROLE_SILVER_GROW]})
									% hook_mission_event:hook_special_event(RoleID,?MISSON_EVENT_ROLE_SILVER_GROW)
							end;
						_ ->
							next
					end,
					R2 = #m_role2_grow_refresh_toc{grow_type=GrowType,err_code=ErrCode,reason=Reason},
					?UNICAST_TOC(R2)
			end;
		{error,ErrCode,ErrReason}->
			R2 = #m_role2_grow_refresh_toc{err_code=ErrCode,reason=ErrReason},
			?UNICAST_TOC(R2)
	end.

get_refresh_toc(GrowType,Category,VipLevel,RoleLevel,undefined,RGrowResult) ->
	{_BaseVal,MaxVal} = common_role:get_grow_level_limit(VipLevel, RoleLevel),
	RoleGrowsCategory = 
		case Category =:= 1 orelse Category =:= 2 of
			true ->
				[{?STR,RGrowResult#r_grow_add_val.str},
				 {?CON,RGrowResult#r_grow_add_val.con},
				 {?DEX,RGrowResult#r_grow_add_val.dex},
				 {?MEN,RGrowResult#r_grow_add_val.men}];
			false ->
				[
				 {?INT,RGrowResult#r_grow_add_val.int},
				 {?CON,RGrowResult#r_grow_add_val.con},
				 {?DEX,RGrowResult#r_grow_add_val.dex},
				 {?MEN,RGrowResult#r_grow_add_val.men}]
		end,
	RoleGrows = 
		lists:map(fun({Type,Value}) ->
						  #p_role_grow{type=Type,cur_value=Value,max_value=MaxVal}
				  end, RoleGrowsCategory),
	[GrowCostList1] = common_config_dyn:find(role_grow,{grow_cost,?GROW1}),
	{_,GrowCost1} = lists:keyfind(RoleLevel, 1, GrowCostList1),
	GrowCostList =
	lists:foldl(fun(CostGrowType,Acc) ->
						[NeedVipLevel] = common_config_dyn:find(role_grow,{grow_type,CostGrowType}),
						[GrowCost] = common_config_dyn:find(role_grow,{grow_cost,CostGrowType}),
						case VipLevel >= NeedVipLevel of
							true ->
								lists:append(Acc, [{CostGrowType,GrowCost}]);
							_ ->
								Acc
						end
						end, [{?GROW1,GrowCost1}], [?GROW2,?GROW3,?GROW4]),
	RoleMoney = 
		lists:map(fun({Type,Value}) ->
						  #p_grow_money{type=Type,value=Value}
				  end, GrowCostList),
	#m_role2_grow_refresh_toc{grow_type=GrowType,role_grows=RoleGrows,role_money=RoleMoney};
get_refresh_toc(GrowType,Category,VipLevel,RoleLevel,_SumGrowVal,RGrowResult) ->
	{_BaseVal,MaxVal} = common_role:get_grow_level_limit(VipLevel, RoleLevel),
	RoleGrowsCategory = 
		case Category =:= 1 orelse Category =:= 2 of
			true ->
				[{?STR,RGrowResult#r_grow_add_val.str},
				 {?CON,RGrowResult#r_grow_add_val.con},
				 {?DEX,RGrowResult#r_grow_add_val.dex},
				 {?MEN,RGrowResult#r_grow_add_val.men}];
			false ->
				[
				 {?INT,RGrowResult#r_grow_add_val.int},
				 {?CON,RGrowResult#r_grow_add_val.con},
				 {?DEX,RGrowResult#r_grow_add_val.dex},
				 {?MEN,RGrowResult#r_grow_add_val.men}]
		end,
	RoleGrows = 
		lists:map(fun({Type,Value}) ->
						  #p_role_grow{type=Type,cur_value=Value,max_value=MaxVal}
				  end, RoleGrowsCategory),
	[GrowCostList1] = common_config_dyn:find(role_grow,{grow_cost,?GROW1}),
	{_,GrowCost1} = lists:keyfind(RoleLevel, 1, GrowCostList1),
	GrowCostList =
	lists:foldl(fun(CostGrowType,Acc) ->
						[NeedVipLevel] = common_config_dyn:find(role_grow,{grow_type,CostGrowType}),
						[GrowCost] = common_config_dyn:find(role_grow,{grow_cost,CostGrowType}),
						case VipLevel >= NeedVipLevel of
							true ->
								lists:append(Acc, [{CostGrowType,GrowCost}]);
							_ ->
								Acc
						end
						end, [{?GROW1,GrowCost1}], [?GROW2,?GROW3,?GROW4]),
	RoleMoney = 
		lists:map(fun({Type,Value}) ->
						  #p_grow_money{type=Type,value=Value}
				  end, GrowCostList),
	#m_role2_grow_refresh_toc{grow_type=GrowType,role_grows=RoleGrows,role_money=RoleMoney}.

check_role2_grow_refresh(RoleID,DataIn)->
    #m_role2_grow_refresh_tos{grow_type=GrowType}= DataIn,
	VipLevel = mod_vip:get_role_vip_level(RoleID),
    case mod_map_role:get_role_attr(RoleID) of
        {ok,#p_role_attr{level=RoleLv}} when RoleLv>=5->
            next;
        _ ->
			RoleLv = 0,
            ?THROW_ERR(?ERR_GROW_MIN_LEVEL_LIMIT)
    end,
	case lists:member(GrowType, ?ALL_GROW) of
		true ->
			next;
		_ ->
			?THROW_ERR(?ERR_INTERFACE_ERR)
	end,		
	case GrowType of
		?GROW1 ->
				[GrowCostList] = common_config_dyn:find(role_grow,{grow_cost,GrowType}),
				MoneyType = silver_any,
				{_,Cost} = lists:keyfind(RoleLv, 1, GrowCostList);
		_ ->
			[NeedVipLevel] = common_config_dyn:find(role_grow,{grow_type,GrowType}),
			case VipLevel >= NeedVipLevel of
				true ->
					MoneyType = gold_any,
					[Cost] = common_config_dyn:find(role_grow,{grow_cost,GrowType});
				_ ->
					MoneyType = gold_any,
					Cost = 99,
					#r_vip_level_info{title_name=TitleName} = mod_vip:get_vip_level_info(NeedVipLevel),
					ErrReason = common_tool:get_format_lang_resources(<<"亲，只有~s以上才能培养" >>,[TitleName]),
					?THROW_ERR(?ERR_GROW_ROLE_NOT_VIP,ErrReason)
			end
	end,
    {ok,{MoneyType,Cost}}.

check_role2_grow_save(RoleID,_DataIn)->
	case mod_map_role:get_role_base(RoleID) of
		{ok,_}->
			next;
		_ ->
			?THROW_SYS_ERR()
	end,
	assert_role_level(RoleID),
	case get_cur_grow_result(RoleID) of
		undefined->
			GrowResult = undefined,
			?THROW_ERR(?ERR_GROW_NO_CUR_RESULT);
		GrowResult ->
			next
	end,
	{ok,GrowResult}.

t_role_grow_refresh(GrowType,RoleID,{MoneyType,DeductMoney})->
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	{ok,#p_role_attr{category=Category,level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	{Val1,Val2,Val3,Val4,Val5} = get_all_grow_add_val(RoleID,Category,VipLevel,RoleLevel,GrowType,{false,undefined}),
    %%获取改变后的值
    GrowResult = #r_grow_add_val{
                                 str= get_add_val(RoleID,VipLevel, RoleLevel,#r_grow_add_val.str,Val1),
                                 int=get_add_val(RoleID,VipLevel, RoleLevel,#r_grow_add_val.int,Val2),
                                 con=get_add_val(RoleID,VipLevel, RoleLevel,#r_grow_add_val.con,Val3),
                                 dex=get_add_val(RoleID,VipLevel, RoleLevel,#r_grow_add_val.dex,Val4),
								 men=get_add_val(RoleID,VipLevel, RoleLevel,#r_grow_add_val.men,Val5)},
    if
        Val1=:=?FULL andalso Val2=:=?FULL andalso Val3=:=?FULL andalso Val4=:=?FULL andalso Val5=:=?FULL ->
            ?THROW_ERR(?ERR_GROW_ALL_PROPERTY_FULL);
        true->
            next
    end,
    %%存储将当前的临时增值
    {ok,RoleMapExt1} = mod_map_role:get_role_map_ext_info(RoleID),
    #r_role_map_ext{role_grow=RoleGrow1} = RoleMapExt1,
	#r_role_grow{sum_grow_val=SumGrowVal} = RoleGrow1,
    RoleMapExt2=RoleMapExt1#r_role_map_ext{role_grow=
                                    RoleGrow1#r_role_grow{tmp_grow_val=GrowResult}},

    common_bag2:check_money_enough_and_throw(MoneyType, DeductMoney, RoleID),
    mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt2),
    {ok,RoleAttr2} = t_deduct_grow_money(MoneyType,DeductMoney,RoleID),
    mod_map_role:set_role_attr(RoleID,RoleAttr2),
    
    {ok,Category,VipLevel,RoleLevel,SumGrowVal,GrowResult,RoleAttr2}.


get_add_val(RoleID,_VipLevel, _RoleLevel,GrowIndex,Value) ->
%% 	{BaseVal,_MaxVal} = common_role:get_grow_level_limit(VipLevel, RoleLevel),
	SumVal = get_role_sum_grow_val(RoleID,GrowIndex),
	if 
		Value =:= ?FULL -> 
			0; 
		SumVal =:= 0 andalso Value=<0 -> 
			0;
		(Value+SumVal)<0->
			0;
		true -> 
			Value 
	end.

%%扣除钱币/元宝
t_deduct_grow_money(MoneyType,DeductMoney,RoleID) when is_integer(RoleID)->
    ConsumeLogType = case MoneyType of
                         silver_any->
                             ?CONSUME_TYPE_SILVER_ROLE_GROW;
                         gold_any ->
                             ?CONSUME_TYPE_GOLD_ROLE_GROW
                     end,
    case common_bag2:t_deduct_money(MoneyType,DeductMoney,RoleID,ConsumeLogType) of
        {ok,RoleAttr2}->
            {ok,RoleAttr2};
        {error,silver_any}->
			ErrReason = common_tool:get_format_lang_resources(<<"铜币不足，需要~s铜币">>,[DeductMoney]),
            ?THROW_ERR( ?ERR_GROW_SILVER_ANY_NOT_ENOUGH,ErrReason );
        {error,gold_any}->
            ErrReason = common_tool:get_format_lang_resources(<<"礼券不足，需要~s元宝">>,[DeductMoney]),
            ?THROW_ERR( ?ERR_GROW_GOLD_ANY_NOT_ENOUGH,ErrReason );
        {error, ErrReason} ->
        	?THROW_ERR(?ERR_OTHER_ERR, ErrReason);
        _ ->
            ?THROW_SYS_ERR()
    end. 



get_all_grow_add_val(_RoleID,_Category,_VipLevel,_RoleLevel,_GrowType,{true,Val}) ->
	Val;
get_all_grow_add_val(RoleID,Category,VipLevel,RoleLevel,GrowType,{false,undefined}) ->
	case Category =:= 1 orelse Category =:= 2 of
		true ->
			Val2 = ?FULL,
			Val1=get_grow_add_val(RoleID,VipLevel,RoleLevel,GrowType,#r_grow_add_val.str);
		false ->
			Val1 = ?FULL,
			Val2=get_grow_add_val(RoleID,VipLevel,RoleLevel,GrowType,#r_grow_add_val.int)
	end,
	Val3=get_grow_add_val(RoleID,VipLevel,RoleLevel,GrowType,#r_grow_add_val.con),
	Val4=get_grow_add_val(RoleID,VipLevel,RoleLevel,GrowType,#r_grow_add_val.dex),
	Val5=get_grow_add_val(RoleID,VipLevel,RoleLevel,GrowType,#r_grow_add_val.men),
	[GrowNumList] = common_config_dyn:find(role_grow,grow_num),
	{_,MaxGrowNum} = lists:keyfind(GrowType, 1, GrowNumList),
	{GrowNum,GrowTypeList} = 
		lists:foldl(fun({Type,Val},Acc) ->
							{AddNum,AddList} = Acc,
							case Val of
								?FULL ->
									Acc;
								_ ->
									case Val > 0 of
										true ->
											{AddNum+1,[{Type,Val}|AddList]};
										false ->
											Acc
									end
							end
					end, {0,[]}, [{?STR,Val1},{?INT,Val2},{?CON,Val3},{?DEX,Val4},{?MEN,Val5}]),
	case GrowNum > MaxGrowNum of
		true ->
			DeNum = GrowNum - MaxGrowNum,
			DeList = get_de_list(DeNum,GrowTypeList,[]),
			[NewVal1,NewVal2,NewVal3,NewVal4,NewVal5] = get_all_add_val_ext([{?STR,Val1},{?INT,Val2},{?CON,Val3},{?DEX,Val4},{?MEN,Val5}],DeList,GrowType),
			get_all_grow_add_val(RoleID,Category,VipLevel,RoleLevel,GrowType,{true,{NewVal1,NewVal2,NewVal3,NewVal4,NewVal5}});
		false ->
			get_all_grow_add_val(RoleID,Category,VipLevel,RoleLevel,GrowType,{true,{Val1,Val2,Val3,Val4,Val5}})
	end.

get_all_add_val_ext(GrowList,DeList,GrowType) ->
	lists:map(fun({Type,Val}) ->
					  case lists:keyfind(Type, 1, DeList) of
						  false ->
							  Val;
						  _ ->
							  [GrowRateList] = common_config_dyn:find(role_grow,grow_data),
							  {_,_,MinusRateList} = lists:keyfind(GrowType,1,GrowRateList),
							  get_add_val_by_config(MinusRateList)
					  end
			  end, GrowList).

%% get_grow_index(Type) ->
%% 	case Type of
%% 		?STR ->
%% 			#r_grow_add_val.str;
%% 		?CON ->
%% 			#r_grow_add_val.con;
%% 		?INT ->
%% 			#r_grow_add_val.int;
%% 		?DEX ->
%% 			#r_grow_add_val.dex;
%% 		?MEN ->
%% 			#r_grow_add_val.men
%% 	end.

get_de_list(DeNum,_GrowTypeList,DeList) when DeNum =:= 0 ->
	DeList;
get_de_list(DeNum,GrowTypeList,DeList) ->
	Random = common_tool:random(1,length(GrowTypeList)),
	Elem = lists:nth(Random, GrowTypeList),
	get_de_list(DeNum-1,lists:delete(Elem, GrowTypeList),[Elem|DeList]).

%%从配置中获取对应的成长值，随机
%%@return integer()
get_grow_add_val(RoleID,VipLevel,RoleLevel,GrowType,GrowIndex)->
    {BaseVal,MaxVal} = common_role:get_grow_level_limit(VipLevel, RoleLevel),
    SumVal = get_role_sum_grow_val(RoleID,GrowIndex),
    
    IsMaxProtect = true,   %%不保护表示属性点可能会减少
    get_grow_add_val_2(IsMaxProtect,GrowType,SumVal,BaseVal,MaxVal).

get_grow_add_val_2(true,GrowType,SumVal,BaseVal,MaxVal)->
    case SumVal>=MaxVal of
        true->
            ?FULL;
        _ ->
            get_grow_add_val_2(false,GrowType,SumVal,BaseVal,MaxVal)
    end;
get_grow_add_val_2(false,GrowType,SumVal,_BaseVal,MaxVal)->
    [GrowRateList] = common_config_dyn:find(role_grow,grow_data),
	AddRandomVal = get_add_random(GrowType,MaxVal,SumVal),
    {GrowType,AddRateList,MinusRateList} = lists:keyfind(GrowType,1,GrowRateList),
    Random = common_tool:random(1,100),
    case AddRandomVal>=Random of
        true->
            %%增加
            AddVal = get_add_val_by_config(AddRateList);
        _->
            %%减少
            AddVal = get_add_val_by_config(MinusRateList)
    end,
    if
        SumVal =:= 0 andalso AddVal=<0 -> 
            0;
        (AddVal+SumVal)<0->
            0;
        (AddVal+SumVal)>MaxVal->
            (MaxVal-SumVal);
        true->
            (AddVal)
    end.

get_add_random(GrowType,MaxVal,SumVal) ->
	[GrowRateList] = common_config_dyn:find(role_grow,{grow_rate,GrowType}),
	catch lists:foldl(fun({Min,Max,Rate},Acc) ->
							  case SumVal >= common_tool:ceil((Min/100)*MaxVal) andalso SumVal =< common_tool:ceil((Max/100)*MaxVal) of
								  true ->
									  throw(Rate);
								  _ ->
									  Acc
							  end
					  end, 1, GrowRateList).
	

%%获取玩家历史的培养值总值，因为不能超过这个总值
get_role_sum_grow_val(RoleID,GrowIndex)->
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{role_grow=RoleGrow}} ->
			#r_role_grow{sum_grow_val=SumGrowVal}=RoleGrow,
			if
				is_record(SumGrowVal,r_grow_add_val)->
					erlang:element(GrowIndex, SumGrowVal);
				true->
					0
			end;
		_ ->
			0
	end.

get_add_val_by_config(RandomValList)->
    {_,AddVal} = common_tool:random_from_tuple_weights(RandomValList, 1),
    AddVal.


%% @interface 保存/取消人物培养的值
do_role2_grow_show({Unique, Module, Method, _DataIn, RoleID, PID, _Line, _MapState})->
	{ok,#p_role_attr{category=Category,level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{role_grow=#r_role_grow{sum_grow_val=SumGrowVal}}} ->
			case SumGrowVal of
				#r_grow_add_val{str=Power,con=Vitaility,int=Brain,dex=Agile,men=Spirit}->
					R2 = get_grow_show_toc(RoleID,Category,RoleLevel,{Power,Vitaility,Brain,Agile,Spirit});
				_ ->
					R2 = get_grow_show_toc(RoleID,Category,RoleLevel,undefined)
			end;
		_ ->
			R2 = get_grow_show_toc(RoleID,Category,RoleLevel,undefined)
	end,
	?UNICAST_TOC(R2).

set_base_grow(RoleID,BaseValue) ->
	TransFun = fun()-> t_set_base_grow(RoleID,BaseValue) end,
	common_transaction:t( TransFun ).

t_set_base_grow(RoleID,BaseValue) ->
    {ok,RoleMapExt1} = mod_map_role:get_role_map_ext_info(RoleID),
    #r_role_map_ext{role_grow=RoleGrow1} = RoleMapExt1,
    RoleMapExt2=RoleMapExt1#r_role_map_ext{role_grow=
                                    RoleGrow1#r_role_grow{sum_grow_val=#r_grow_add_val{str=BaseValue,
										con=BaseValue,int=BaseValue,dex=BaseValue,men=BaseValue}}},
    mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt2).

send_show_grow(RoleID) ->
	{ok,#p_role_attr{category=Category,level=RoleLevel}} = mod_map_role:get_role_attr(RoleID),
	case mod_map_role:get_role_map_ext_info(RoleID) of
		{ok,#r_role_map_ext{role_grow=#r_role_grow{sum_grow_val=SumGrowVal}}} ->
			#r_grow_add_val{str=Power,con=Vitaility,int=Brain,dex=Md,men=Spirit} = SumGrowVal,
			R2 = get_grow_show_toc(RoleID,Category,RoleLevel,{Power,Vitaility,Brain,Md,Spirit}),
			common_misc:unicast({role, RoleID}, ?DEFAULT_UNIQUE, ?ROLE2, ?ROLE2_GROW_SHOW, R2);
		_ ->
			ignore
	end.

get_grow_show_toc(RoleID,Category,RoleLevel,undefined) ->
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	{BaseVal,MaxVal} = common_role:get_grow_level_limit(VipLevel, RoleLevel),
	RoleGrowsCategory = 
		case Category =:= 1 orelse Category =:= 2 of
			true ->
				set_base_grow(RoleID,BaseVal),
				[{?STR,BaseVal},{?CON,BaseVal},{?DEX,BaseVal},{?MEN,BaseVal}];
			false ->
				set_base_grow(RoleID,BaseVal),
				[{?INT,BaseVal},{?CON,BaseVal},{?DEX,BaseVal},{?MEN,BaseVal}]
		end,
	RoleGrows = 
		lists:map(fun({Type,Value}) ->
						  #p_role_grow{type=Type,cur_value=Value,max_value=MaxVal}
				  end, RoleGrowsCategory),
	[GrowCostList1] = common_config_dyn:find(role_grow,{grow_cost,?GROW1}),
	{_,GrowCost1} = lists:keyfind(RoleLevel, 1, GrowCostList1),
	GrowCostList =
	lists:foldl(fun(GrowType,Acc) ->
						[NeedVipLevel] = common_config_dyn:find(role_grow,{grow_type,GrowType}),
						[GrowCost] = common_config_dyn:find(role_grow,{grow_cost,GrowType}),
						case VipLevel >= NeedVipLevel of
							true ->
								lists:append(Acc, [{GrowType,GrowCost}]);
							_ ->
								Acc
						end
						end, [{?GROW1,GrowCost1}], [?GROW2,?GROW3,?GROW4]),
	RoleMoney = 
		lists:map(fun({Type,Value}) ->
						  #p_grow_money{type=Type,value=Value}
				  end, GrowCostList),
	#m_role2_grow_show_toc{role_grows=RoleGrows,role_money=RoleMoney};
	
get_grow_show_toc(RoleID,Category,RoleLevel,{Power,Vitaility,Brain,Md,Spirit}) ->
	VipLevel = mod_vip:get_role_vip_level(RoleID),
	{_BaseVal,MaxVal} = common_role:get_grow_level_limit(VipLevel, RoleLevel),
	RoleGrowsCategory = 
		case Category =:= 1 orelse Category =:= 2 of
			true ->
				[{?STR,Power},{?CON,Vitaility},{?DEX,Md},{?MEN,Spirit}];
			false ->
				[{?INT,Brain},{?CON,Vitaility},{?DEX,Md},{?MEN,Spirit}]
		end,
	RoleGrows = 
		lists:map(fun({Type,Value}) ->
						  #p_role_grow{type=Type,cur_value=Value,max_value=MaxVal}
				  end, RoleGrowsCategory),
	[GrowCostList1] = common_config_dyn:find(role_grow,{grow_cost,?GROW1}),
	{_,GrowCost1} = lists:keyfind(RoleLevel, 1, GrowCostList1),
	GrowCostList =
	lists:foldl(fun(GrowType,Acc) ->
						[NeedVipLevel] = common_config_dyn:find(role_grow,{grow_type,GrowType}),
						[GrowCost] = common_config_dyn:find(role_grow,{grow_cost,GrowType}),
						case VipLevel >= NeedVipLevel of
							true ->
								lists:append(Acc, [{GrowType,GrowCost}]);
							_ ->
								Acc
						end
						end, [{?GROW1,GrowCost1}], [?GROW2,?GROW3,?GROW4]),
	RoleMoney = 
		lists:map(fun({Type,Value}) ->
						  #p_grow_money{type=Type,value=Value}
				  end, GrowCostList),
	#m_role2_grow_show_toc{role_grows=RoleGrows,role_money=RoleMoney}.

    
%% @interface 保存/取消人物培养的值
do_role2_grow_save({Unique, Module, Method, DataIn, RoleID, PID, _Line, _MapState})->
	#m_role2_grow_save_tos{op_type=OpType}= DataIn,
	case catch check_role2_grow_save(RoleID,DataIn) of
		{ok,GrowResult}->
			case OpType of
				?GROW_OP_SAVE->
					TransFun = fun()-> t_role_grow_save(GrowResult,RoleID) end,
					case common_transaction:t( TransFun ) of
						{atomic, {OldRoleGrow, NewRoleGrow}} ->
							{ok,Log} = get_role_grow_log(RoleID,GrowResult),
							catch common_general_log_server:log_role_grow(Log),
							remove_cur_grow_result(RoleID),
							
							R2 = #m_role2_grow_save_toc{op_type=OpType},
							?UNICAST_TOC(R2),
							send_show_grow(RoleID),
							update_role_base(RoleID, OldRoleGrow, NewRoleGrow);
						{aborted, AbortErr} ->
							{error,ErrCode,Reason} = parse_aborted_err(AbortErr),
							R2 = #m_role2_grow_save_toc{op_type=OpType,err_code=ErrCode,reason=Reason},
							?UNICAST_TOC(R2)
					end;
				?GROW_OP_CANCEL->
					remove_cur_grow_result(RoleID),
					R2 = #m_role2_grow_save_toc{op_type=OpType},
					?UNICAST_TOC(R2)
			end;
		{error,ErrCode,ErrReason}->
			R2 = #m_role2_grow_save_toc{op_type=OpType,err_code=ErrCode,reason=ErrReason},
			?UNICAST_TOC(R2)
	end.

update_role_base(RoleID, OldRoleGrow, NewRoleGrow) ->
	{ok, RoleBase} = mod_map_role:get_role_base(RoleID),
	NewRoleBase    = mod_role_attr:calc(RoleBase, 
		'-', grow_attrs(OldRoleGrow), '+', grow_attrs(NewRoleGrow)),
	mod_role_attr:reload_role_base(NewRoleBase).

grow_attrs(#r_role_grow{sum_grow_val = SumGrowVal}) when is_record(SumGrowVal, r_grow_add_val) ->
	[{#p_role_base.str,  SumGrowVal#r_grow_add_val.str},
	 {#p_role_base.int2, SumGrowVal#r_grow_add_val.int},
	 {#p_role_base.con,  SumGrowVal#r_grow_add_val.con},
	 {#p_role_base.dex,  SumGrowVal#r_grow_add_val.dex},
	 {#p_role_base.men,  SumGrowVal#r_grow_add_val.men}];
grow_attrs(_) -> [].

recalc(RoleBase = #p_role_base{role_id = RoleID}, _RoleAttr) ->
	{ok,#r_role_map_ext{role_grow = RoleGrow}} =mod_map_role:get_role_map_ext_info(RoleID),
    mod_role_attr:calc(RoleBase, '+', grow_attrs(RoleGrow)).

get_role_grow_log(RoleID,CurGrowResult)->
	#r_grow_add_val{str=TmpPa,con=TmpPd,
					int=TmpMa,dex=TmpMd,men=MaxHp}=CurGrowResult,
	case mod_map_role:get_role_attr(RoleID) of
		{ok,#p_role_attr{level=RoleLevel}}->
			next;
		_ ->
			RoleLevel = 0
	end,
	Now = common_tool:now(),
	Log = #r_role_grow_log{role_id=RoleID,level=RoleLevel,log_time=Now,str=TmpPa,
						   int=TmpMa,con=TmpPd,dex=TmpMd,men=MaxHp},
	{ok,Log}.

t_role_grow_save(CurGrowResult,RoleID)->
    {ok,#r_role_map_ext{role_grow=RoleGrow}=RoleMapExt} =mod_map_role:get_role_map_ext_info(RoleID),
    #r_role_grow{sum_grow_val=OldGrowResult} = RoleGrow,
    RoleGrow2 = RoleGrow#r_role_grow{sum_grow_val=add_sum_grow_val(OldGrowResult,CurGrowResult),
                                     last_save_time=common_tool:now()},
    RoleMapExt2 = RoleMapExt#r_role_map_ext{role_grow=RoleGrow2},
    mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt2),
    {RoleGrow, RoleGrow2}.

add_sum_grow_val(undefined,CurGrowResult)->
    CurGrowResult;
add_sum_grow_val(OldGrowResult,CurGrowResult)->
    #r_grow_add_val{str=OldPa,con=OldPd,int=OldMa,dex=OldMd,men=OldMh}=OldGrowResult,
    #r_grow_add_val{str=TmpPa,con=TmpPd,int=TmpMa,dex=TmpMd,men=TmpMh}=CurGrowResult,
    #r_grow_add_val{str= filter_err_val(OldPa+TmpPa),con= filter_err_val(OldPd+TmpPd),
                    int= filter_err_val(OldMa+TmpMa),dex= filter_err_val(OldMd+TmpMd),
					men=OldMh+TmpMh}.


filter_err_val(Val) when Val=<?MAX_GROW_SUPER_VAL->
    Val;
filter_err_val(_)->
    0.
    

%%获取当前的临时培养值
get_cur_grow_result(RoleID)->
    {ok,#r_role_map_ext{role_grow=RoleGrow}} = mod_map_role:get_role_map_ext_info(RoleID),
    #r_role_grow{tmp_grow_val=GrowResult} = RoleGrow,
    GrowResult.

%%保存后，删除当前的临时培养值
remove_cur_grow_result(RoleID)->
	TransFun = fun()->  
					   {ok,#r_role_map_ext{role_grow=RoleGrow}=RoleMapExt} =mod_map_role:get_role_map_ext_info(RoleID),
					   RoleGrow2 = RoleGrow#r_role_grow{tmp_grow_val=undefined},
					   RoleMapExt2 = RoleMapExt#r_role_map_ext{role_grow=RoleGrow2},
					   mod_map_role:t_set_role_map_ext_info(RoleID, RoleMapExt2)
			   end,
	case common_transaction:t( TransFun ) of
		{atomic,_ } ->
			ok;
		{aborted, AbortErr} ->
			?ERROR_MSG("error,AbortErr=~w",[AbortErr])
	end.

%%解析错误码
parse_aborted_err(AbortErr)->
	case AbortErr of
		{error,?ERR_GROW_SILVER_ANY_NOT_ENOUGH,Reason} ->
			{error,?ERR_GROW_SILVER_ANY_NOT_ENOUGH,Reason};
		{error,ErrCode,_Reason} when is_integer(ErrCode) ->
			AbortErr;
		{error,AbortReason} when is_binary(AbortReason) ->
			{error,?ERR_OTHER_ERR,AbortReason};
		AbortReason when is_binary(AbortReason) ->
			{error,?ERR_OTHER_ERR,AbortReason};
		_ ->
			?ERROR_MSG(" aborted,AbortErr=~w,stack=~w",[AbortErr,erlang:get_stacktrace()]),
			{error,?ERR_SYS_ERR,undefined}
	end.
 assert_role_level(RoleID) ->
	 case mod_map_role:get_role_attr(RoleID) of
		 {ok,#p_role_attr{level=RoleLv}} when RoleLv>=5->
			 next;
		 _ ->
			 ?THROW_ERR(?ERR_GROW_MIN_LEVEL_LIMIT)
	 end.