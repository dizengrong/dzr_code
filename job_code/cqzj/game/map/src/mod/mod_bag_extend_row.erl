%%% @author fsk 
%%% @doc
%%%     背包行扩展
%%% @end
%%% Created : 2012-6-12
%%%-------------------------------------------------------------------
-module(mod_bag_extend_row).

-include("mgeem.hrl").
-define(ERR_BAG_EXTEND_NOT_ENOUGH_GOLD,11001).%%元宝不足

-define(MAIN_BAG_ID,1).

-export([
		 bag_extend_row/1,
		 fix_all_bag_extend/0,
		 fix_role_bag_extend/1
        ]).

bag_extend_row({Unique,Module,Method,DataIn,RoleID,PID}) ->
	#m_item_extend_bag_row_tos{row=ExtendRow} = DataIn,
	case catch check_bag_extend_row(RoleID,ExtendRow) of
		{error,ErrCode,_ErrReason} ->
			?UNICAST_TOC(#m_item_extend_bag_row_toc{succ=false,reason_code=ErrCode});
		{ok,MoneyType,TotalDeductMoney,ExtendRow} ->
			TransFun = fun()-> 
							   t_bag_extend_row(RoleID,MoneyType,TotalDeductMoney,ExtendRow)
					   end,
			case db:transaction( TransFun ) of
				{atomic, {ok,RoleAttr,ExtendRow,Columns,NewGridNumber}} ->
					common_misc:send_role_gold_change(RoleID,RoleAttr),
					%% 完成成就
            		mod_achievement2:achievement_update_event(RoleID, 33003, 1),
            		mod_achievement2:achievement_update_event(RoleID, 34005, 1),
            		mod_achievement2:achievement_update_event(RoleID, 42001, 1),
            		mod_achievement2:achievement_update_event(RoleID, 41001, 1),
					%% 背包成就
					% ?TRY_CATCH(common_hook_achievement:hook({extend_bag_row,RoleID,ExtendRow})),
					?UNICAST_TOC(#m_item_extend_bag_row_toc{bagid=?MAIN_BAG_ID,rows=ExtendRow,columns=Columns,grid_number=NewGridNumber});
				{aborted, {throw,{error,ErrCode,_}}} when is_integer(ErrCode) ->
					?UNICAST_TOC(#m_item_extend_bag_row_toc{succ=false,reason_code=ErrCode});
				{aborted, {throw,{error,{common_error, Errstr},_}}} ->
					common_misc:send_common_error(RoleID, 0, Errstr);
				{aborted, Reason} ->
					?ERROR_MSG("bag_extend_row error:~w",[Reason]),
					?UNICAST_TOC(#m_item_extend_bag_row_toc{succ=false,reason_code=?ERR_SYS_ERR})
			end
	end.

check_bag_extend_row(RoleID,ExtendRow) ->
	{_,_,_,Rows,_Columns,_GridNumber} = mod_bag:get_bag_info_by_id(RoleID,?MAIN_BAG_ID),
	case Rows >= ExtendRow of
		true ->
			?ERROR_MSG("非法操作:RoleID:~w,Rows:~w,ExtendRow:~w",[RoleID,Rows,ExtendRow]),
			?THROW_ERR(?ERR_SYS_ERR);
		false ->
			[CostList] = common_config_dyn:find(extend_bag_row,extend_bag_row_cost),
			case lists:keyfind(ExtendRow, 1, CostList) of
				false ->
					?ERROR_MSG("非法操作:RoleID:~w,ExtendRow:~w",[RoleID,ExtendRow]),
					?THROW_ERR(?ERR_SYS_ERR);
				{ExtendRow,_} ->
					{MoneyType2,TotalDeductMoney} =
						lists:foldl(fun(Row,{_,Acc})->
											{_,{MoneyType,DeductMoney}} = lists:keyfind(Row, 1, CostList),
											{MoneyType,DeductMoney+Acc}
									end, {gold_unbind,0}, lists:seq(Rows+1, ExtendRow)),
					{ok,MoneyType2,TotalDeductMoney,ExtendRow}
			end
	end.

t_bag_extend_row(RoleID,MoneyType,DeductMoney,ExtendRow) ->
	{ok,RoleAttr} = t_deduct_money(MoneyType,DeductMoney,RoleID,?CONSUME_TYPE_GOLD_BAG_ROW_EXTEND),
	[RoleBagBasicInfo]= db:read(?DB_ROLE_BAG_BASIC_P,RoleID),
    #r_role_bag_basic{bag_basic_list=BagBasicList} = RoleBagBasicInfo,
    NewMainBagBasicInfo = 
        case lists:keyfind(?MAIN_BAG_ID,1,BagBasicList) of
            false ->
				NewGridNumber=ExtendRow=Columns=0,
				?ERROR_MSG("t_bag_extend_row error:~w",[{RoleID,MoneyType,DeductMoney,ExtendRow}]),
				?THROW_ERR(?ERR_SYS_ERR);
            {BagID,BagTypeID,OutUseTime,_Rows,Columns,_GridNumber} ->
				NewGridNumber = ExtendRow*Columns,
                {BagID,BagTypeID,OutUseTime,ExtendRow,Columns,NewGridNumber}
        end,
	NewBagBasicList = lists:keyreplace(?MAIN_BAG_ID, 1, BagBasicList, NewMainBagBasicInfo),
    NewRoleBagBasicInfo = RoleBagBasicInfo#r_role_bag_basic{bag_basic_list=NewBagBasicList},
    db:write(?DB_ROLE_BAG_BASIC_P,NewRoleBagBasicInfo,write),
	mod_bag:bag_extend_row(RoleID,NewMainBagBasicInfo,NewGridNumber),
	{ok,RoleAttr,ExtendRow,Columns,NewGridNumber}.



t_deduct_money(_MoneyType,DeductMoney,RoleID,_LogType) when DeductMoney == 0 ->
	mod_map_role:get_role_attr(RoleID);

t_deduct_money(MoneyType,DeductMoney,RoleID,LogType) ->
	case common_bag2:t_deduct_money(MoneyType,DeductMoney,RoleID,LogType) of
		{ok,RoleAttr}->
			{ok,RoleAttr};
		{error, Reason} ->
			?THROW_ERR({common_error, Reason})
	end.

%% 转换扩展背包成背包格子
fix_all_bag_extend() ->
	case db:dirty_match_object(?DB_ROLE_BAG_BASIC_P, #r_role_bag_basic{_='_'}) of
		[] -> nil;
		List ->
			lists:foreach(fun(RoleBagBasicInfo) ->
								  fix_role_bag_extend(RoleBagBasicInfo)  
						  end, List)
	end.
fix_role_bag_extend(RoleID) when erlang:is_integer(RoleID) ->
	case db:dirty_read(?DB_ROLE_BAG_BASIC_P, RoleID) of
		[] ->
			?ERROR_MSG("role not_found:~w",[RoleID]);
		[RoleBagBasicInfo] ->
			fix_role_bag_extend(RoleBagBasicInfo)
	end;
fix_role_bag_extend(RoleBagBasicInfo) ->
	[MappingList] = common_config_dyn:find(extend_bag_row,extend_bag_mapping_rows),
	#r_role_bag_basic{bag_basic_list=BagBasicList} = RoleBagBasicInfo,
	{MainBagID,MainBagTypeID,MainOutUseTime,MainRows,MainColumns,_MainGridNumber} =
		lists:keyfind(?MAIN_BAG_ID,1,BagBasicList),
	{DelGridNumber,AddRows,NewBagBasicList} = 	
		lists:foldl(fun({_BagID,BagTypeID,_OutUseTime,_Rows,_Columns,GridNumber}=BagBasic,{AccDelGridNumber,AccAddRows,AccBagBasic}) ->
							case lists:keyfind(BagTypeID, 1, MappingList) of
								false -> {AccDelGridNumber,AccAddRows,[BagBasic|AccBagBasic]};
								{BagTypeID,MappingRow} ->
									{GridNumber+AccDelGridNumber,MappingRow+AccAddRows,AccBagBasic}
							end
					end, {0,0,[]}, BagBasicList),
	DelRows = common_tool:ceil(DelGridNumber/MainColumns),
	NewMainRows = MainRows-DelRows+AddRows,
	NewMainBagBasic = {MainBagID,MainBagTypeID,MainOutUseTime,NewMainRows,MainColumns,NewMainRows*MainColumns},
	NewBagBasicList2 = lists:keyreplace(?MAIN_BAG_ID,1,NewBagBasicList,NewMainBagBasic),
	NewRoleBagBasicInfo = RoleBagBasicInfo#r_role_bag_basic{bag_basic_list=NewBagBasicList2},
	db:dirty_write(?DB_ROLE_BAG_BASIC_P,NewRoleBagBasicInfo).
